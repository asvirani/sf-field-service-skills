# Mobile LWC Patterns

Copy-paste-ready patterns for Field Service Mobile development.

---

## 1. Photo Capture + Attach to Work Order

### photoCaptureWorkOrder.js

```javascript
import { LightningElement, api } from 'lwc';
import { getDeviceCamera } from 'lightning/mobileCapabilities';
import { createRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class PhotoCaptureWorkOrder extends LightningElement {
    @api recordId; // WorkOrder Id
    capturedImageUrl;
    isProcessing = false;
    error;

    camera;

    connectedCallback() {
        this.camera = getDeviceCamera();
    }

    get cameraAvailable() {
        return this.camera != null && this.camera.isAvailable();
    }

    async handleCapture() {
        if (!this.cameraAvailable) {
            this.error = 'Camera not available on this device.';
            return;
        }

        this.isProcessing = true;
        this.error = undefined;

        try {
            const result = await this.camera.captureImage({
                imageSource: 'camera',
                cameraDirection: 'back',
                allowsEditing: false,
                quality: 60
            });

            this.capturedImageUrl = `data:${result.mimeType};base64,${result.base64}`;

            const contentVersion = await createRecord({
                apiName: 'ContentVersion',
                fields: {
                    Title: `WO_Photo_${new Date().toISOString()}`,
                    PathOnClient: `wo_photo_${Date.now()}.jpg`,
                    VersionData: result.base64,
                    FirstPublishLocationId: this.recordId
                }
            });

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Photo Saved',
                    message: `Attached to Work Order`,
                    variant: 'success'
                })
            );
        } catch (err) {
            if (err.code !== 'USER_DISMISSED') {
                this.error = `Error: ${err.message || err.body?.message}`;
            }
        } finally {
            this.isProcessing = false;
        }
    }
}
```

### photoCaptureWorkOrder.html

```html
<template>
    <lightning-card title="Photo Capture" icon-name="utility:photo">
        <div class="slds-p-around_medium">
            <template lwc:if={error}>
                <div class="slds-text-color_error slds-m-bottom_small">{error}</div>
            </template>

            <template lwc:if={cameraAvailable}>
                <lightning-button
                    label="Take Photo"
                    variant="brand"
                    onclick={handleCapture}
                    disabled={isProcessing}
                    icon-name="utility:photo"
                ></lightning-button>
            </template>
            <template lwc:else>
                <p>Camera not available on this device.</p>
            </template>

            <template lwc:if={capturedImageUrl}>
                <div class="slds-m-top_medium">
                    <img src={capturedImageUrl} alt="Captured photo" style="max-width:100%; border-radius:8px;" />
                </div>
            </template>
        </div>
    </lightning-card>
</template>
```

---

## 2. Barcode Scan for Asset Lookup

### barcodeScanAsset.js

```javascript
import { LightningElement, api, wire } from 'lwc';
import { getBarcodeScanner } from 'lightning/mobileCapabilities';
import { gql, graphql } from 'lightning/uiGraphQLApi';

export default class BarcodeScanAsset extends LightningElement {
    @api recordId;
    scannedValue;
    assetData;
    error;

    scanner;

    connectedCallback() {
        this.scanner = getBarcodeScanner();
    }

    get scannerAvailable() {
        return this.scanner != null && this.scanner.isAvailable();
    }

    get graphqlVariables() {
        return this.scannedValue
            ? { serialNumber: this.scannedValue }
            : undefined;
    }

    @wire(graphql, {
        query: gql`
            query FindAsset($serialNumber: String) {
                uiapi {
                    query {
                        Asset(
                            where: { SerialNumber: { eq: $serialNumber } }
                            first: 1
                        ) {
                            edges {
                                node {
                                    Id
                                    Name { value }
                                    SerialNumber { value }
                                    Status { value }
                                    Product2 {
                                        Name { value }
                                    }
                                    Account {
                                        Name { value }
                                    }
                                    InstallDate { value }
                                }
                            }
                        }
                    }
                }
            }
        `,
        variables: '$graphqlVariables'
    })
    wiredAsset({ data, errors }) {
        if (data) {
            const edges = data.uiapi.query.Asset.edges;
            this.assetData = edges.length > 0 ? edges[0].node : null;
            if (!this.assetData) {
                this.error = `No asset found for serial: ${this.scannedValue}`;
            } else {
                this.error = undefined;
            }
        }
        if (errors) {
            this.error = errors.map((e) => e.message).join(', ');
            this.assetData = undefined;
        }
    }

    handleScan() {
        if (!this.scannerAvailable) return;

        const options = {
            barcodeTypes: [
                this.scanner.barcodeTypes.CODE_128,
                this.scanner.barcodeTypes.CODE_39,
                this.scanner.barcodeTypes.QR
            ],
            instructionText: 'Scan asset barcode or QR code'
        };

        this.scanner
            .beginCapture(options)
            .then((result) => {
                this.scannedValue = result.value;
                this.error = undefined;
            })
            .catch((err) => {
                if (err.code !== 'USER_DISMISSED') {
                    this.error = `Scan error: ${err.message}`;
                }
            })
            .finally(() => {
                this.scanner.endCapture();
            });
    }
}
```

### barcodeScanAsset.html

```html
<template>
    <lightning-card title="Asset Lookup" icon-name="utility:scan">
        <div class="slds-p-around_medium">
            <template lwc:if={error}>
                <div class="slds-text-color_error slds-m-bottom_small">{error}</div>
            </template>

            <template lwc:if={scannerAvailable}>
                <lightning-button
                    label="Scan Asset Barcode"
                    variant="brand"
                    onclick={handleScan}
                    icon-name="utility:scan"
                ></lightning-button>
            </template>

            <template lwc:if={scannedValue}>
                <p class="slds-m-top_small">
                    <strong>Scanned:</strong> {scannedValue}
                </p>
            </template>

            <template lwc:if={assetData}>
                <div class="slds-m-top_medium slds-box slds-theme_shade">
                    <p><strong>Asset:</strong> {assetData.Name.value}</p>
                    <p><strong>Serial:</strong> {assetData.SerialNumber.value}</p>
                    <p><strong>Status:</strong> {assetData.Status.value}</p>
                    <p><strong>Product:</strong> {assetData.Product2.Name.value}</p>
                    <p><strong>Account:</strong> {assetData.Account.Name.value}</p>
                    <p><strong>Install Date:</strong> {assetData.InstallDate.value}</p>
                </div>
            </template>
        </div>
    </lightning-card>
</template>
```

**Offline-capable** — uses GraphQL wire adapter against Briefcase-primed Asset records.

---

## 3. GPS Check-In / Check-Out

### gpsCheckInOut.js

```javascript
import { LightningElement, api, wire } from 'lwc';
import { getLocationService } from 'lightning/mobileCapabilities';
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import SA_ID from '@salesforce/schema/ServiceAppointment.Id';
import SA_STATUS from '@salesforce/schema/ServiceAppointment.Status';
import SA_ACTUAL_START from '@salesforce/schema/ServiceAppointment.ActualStartTime';
import SA_ACTUAL_END from '@salesforce/schema/ServiceAppointment.ActualEndTime';
import SA_LATITUDE from '@salesforce/schema/ServiceAppointment.Latitude';
import SA_LONGITUDE from '@salesforce/schema/ServiceAppointment.Longitude';

const FIELDS = [SA_STATUS, SA_ACTUAL_START, SA_ACTUAL_END];

export default class GpsCheckInOut extends LightningElement {
    @api recordId;
    isProcessing = false;
    error;

    locationService;

    connectedCallback() {
        this.locationService = getLocationService();
    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    appointment;

    get currentStatus() {
        return getFieldValue(this.appointment.data, SA_STATUS);
    }

    get canCheckIn() {
        return this.currentStatus === 'Dispatched' || this.currentStatus === 'Scheduled';
    }

    get canCheckOut() {
        return this.currentStatus === 'In Progress';
    }

    get locationAvailable() {
        return this.locationService != null && this.locationService.isAvailable();
    }

    async handleCheckIn() {
        await this.updateWithLocation('In Progress', SA_ACTUAL_START, 'Checked In');
    }

    async handleCheckOut() {
        await this.updateWithLocation('Completed', SA_ACTUAL_END, 'Checked Out');
    }

    async updateWithLocation(newStatus, timeField, toastTitle) {
        if (!this.locationAvailable) {
            this.error = 'Location services not available.';
            return;
        }

        this.isProcessing = true;
        this.error = undefined;

        try {
            const location = await this.locationService.getCurrentPosition();

            const fields = {};
            fields[SA_ID.fieldApiName] = this.recordId;
            fields[SA_STATUS.fieldApiName] = newStatus;
            fields[timeField.fieldApiName] = new Date().toISOString();
            fields[SA_LATITUDE.fieldApiName] = location.coords.latitude;
            fields[SA_LONGITUDE.fieldApiName] = location.coords.longitude;

            await updateRecord({ fields });

            this.dispatchEvent(
                new ShowToastEvent({
                    title: toastTitle,
                    message: `${location.coords.latitude.toFixed(4)}, ${location.coords.longitude.toFixed(4)}`,
                    variant: 'success'
                })
            );
        } catch (err) {
            this.error = `Error: ${err.message || err.body?.message}`;
        } finally {
            this.isProcessing = false;
        }
    }
}
```

### gpsCheckInOut.html

```html
<template>
    <lightning-card title="Check-In / Check-Out" icon-name="utility:location">
        <div class="slds-p-around_medium">
            <template lwc:if={error}>
                <div class="slds-text-color_error slds-m-bottom_small">{error}</div>
            </template>

            <p class="slds-m-bottom_small">
                <strong>Status:</strong> {currentStatus}
            </p>

            <template lwc:if={canCheckIn}>
                <lightning-button
                    label="Check In"
                    variant="brand"
                    onclick={handleCheckIn}
                    disabled={isProcessing}
                    icon-name="utility:checkin"
                ></lightning-button>
            </template>

            <template lwc:if={canCheckOut}>
                <lightning-button
                    label="Check Out"
                    variant="success"
                    onclick={handleCheckOut}
                    disabled={isProcessing}
                    icon-name="utility:checkout"
                ></lightning-button>
            </template>
        </div>
    </lightning-card>
</template>
```

**Offline-capable** — uses `getRecord` and `updateRecord` from LDS.

---

## 4. Offline Data Collection

### offlineDataCollection.js

```javascript
import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import WO_SUBJECT from '@salesforce/schema/WorkOrder.Subject';
import WO_DESCRIPTION from '@salesforce/schema/WorkOrder.Description';
import WO_PRIORITY from '@salesforce/schema/WorkOrder.Priority';
import WO_STATUS from '@salesforce/schema/WorkOrder.Status';

const FIELDS = [WO_SUBJECT, WO_DESCRIPTION, WO_PRIORITY, WO_STATUS];

export default class OfflineDataCollection extends LightningElement {
    @api recordId;
    isProcessing = false;
    error;

    description = '';
    priority = '';

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredWorkOrder({ data, error }) {
        if (data) {
            this.description = getFieldValue(data, WO_DESCRIPTION) || '';
            this.priority = getFieldValue(data, WO_PRIORITY) || '';
        }
        if (error) {
            this.error = error.body?.message;
        }
    }

    get priorityOptions() {
        return [
            { label: 'Critical', value: 'Critical' },
            { label: 'High', value: 'High' },
            { label: 'Medium', value: 'Medium' },
            { label: 'Low', value: 'Low' }
        ];
    }

    handleDescriptionChange(event) {
        this.description = event.target.value;
    }

    handlePriorityChange(event) {
        this.priority = event.detail.value;
    }

    async handleSave() {
        this.isProcessing = true;
        this.error = undefined;

        try {
            await updateRecord({
                fields: {
                    Id: this.recordId,
                    [WO_DESCRIPTION.fieldApiName]: this.description,
                    [WO_PRIORITY.fieldApiName]: this.priority
                }
            });

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Saved',
                    message: 'Work Order updated.',
                    variant: 'success'
                })
            );
        } catch (err) {
            this.error = `Save failed: ${err.message || err.body?.message}`;
        } finally {
            this.isProcessing = false;
        }
    }
}
```

### offlineDataCollection.html

```html
<template>
    <lightning-card title="Work Order Details" icon-name="standard:work_order">
        <div class="slds-p-around_medium">
            <template lwc:if={error}>
                <div class="slds-text-color_error slds-m-bottom_small">{error}</div>
            </template>

            <lightning-textarea
                label="Description"
                value={description}
                onchange={handleDescriptionChange}
                max-length="5000"
            ></lightning-textarea>

            <lightning-combobox
                label="Priority"
                value={priority}
                options={priorityOptions}
                onchange={handlePriorityChange}
                class="slds-m-top_small"
            ></lightning-combobox>

            <lightning-button
                label="Save"
                variant="brand"
                onclick={handleSave}
                disabled={isProcessing}
                class="slds-m-top_medium"
            ></lightning-button>
        </div>
    </lightning-card>
</template>
```

**Fully offline-capable** — uses only LDS wire adapters and `updateRecord`.

---

## 5. Parts Consumption

### partsConsumption.js

```javascript
import { LightningElement, api } from 'lwc';
import { createRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import PRODUCT_CONSUMED_OBJECT from '@salesforce/schema/ProductConsumed';
import PC_WORK_ORDER from '@salesforce/schema/ProductConsumed.WorkOrderId';
import PC_PRODUCT_ITEM from '@salesforce/schema/ProductConsumed.ProductItemId';
import PC_QUANTITY from '@salesforce/schema/ProductConsumed.QuantityConsumed';

export default class PartsConsumption extends LightningElement {
    @api recordId; // WorkOrder Id

    productItemId = '';
    quantity = 1;
    isProcessing = false;
    error;
    consumedParts = [];

    handleProductItemChange(event) {
        this.productItemId = event.detail.value;
    }

    handleQuantityChange(event) {
        this.quantity = event.detail.value;
    }

    async handleAddPart() {
        if (!this.productItemId) {
            this.error = 'Select a product item.';
            return;
        }
        if (!this.quantity || this.quantity <= 0) {
            this.error = 'Quantity must be greater than 0.';
            return;
        }

        this.isProcessing = true;
        this.error = undefined;

        try {
            const fields = {};
            fields[PC_WORK_ORDER.fieldApiName] = this.recordId;
            fields[PC_PRODUCT_ITEM.fieldApiName] = this.productItemId;
            fields[PC_QUANTITY.fieldApiName] = this.quantity;

            const result = await createRecord({
                apiName: PRODUCT_CONSUMED_OBJECT.objectApiName,
                fields
            });

            this.consumedParts = [
                ...this.consumedParts,
                {
                    id: result.id,
                    productItemId: this.productItemId,
                    quantity: this.quantity
                }
            ];

            this.productItemId = '';
            this.quantity = 1;

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Part Added',
                    message: 'Product consumed recorded.',
                    variant: 'success'
                })
            );
        } catch (err) {
            this.error = `Error: ${err.message || err.body?.message}`;
        } finally {
            this.isProcessing = false;
        }
    }
}
```

### partsConsumption.html

```html
<template>
    <lightning-card title="Parts Consumption" icon-name="standard:product_consumed">
        <div class="slds-p-around_medium">
            <template lwc:if={error}>
                <div class="slds-text-color_error slds-m-bottom_small">{error}</div>
            </template>

            <lightning-input-field
                field-name="ProductItemId"
                value={productItemId}
                onchange={handleProductItemChange}
            ></lightning-input-field>

            <lightning-input
                type="number"
                label="Quantity"
                value={quantity}
                min="1"
                step="1"
                onchange={handleQuantityChange}
                class="slds-m-top_small"
            ></lightning-input>

            <lightning-button
                label="Add Part"
                variant="brand"
                onclick={handleAddPart}
                disabled={isProcessing}
                class="slds-m-top_medium"
                icon-name="utility:add"
            ></lightning-button>

            <template lwc:if={consumedParts.length}>
                <div class="slds-m-top_medium">
                    <h3 class="slds-text-heading_small">Consumed Parts</h3>
                    <ul class="slds-list_dotted">
                        <template for:each={consumedParts} for:item="part">
                            <li key={part.id}>
                                {part.productItemId} - Qty: {part.quantity}
                            </li>
                        </template>
                    </ul>
                </div>
            </template>
        </div>
    </lightning-card>
</template>
```

**Offline-capable** — `createRecord` creates draft records when offline.

---

## 6. Customer Signature Capture (Non-DC)

### signatureCapture.js

```javascript
import { LightningElement, api } from 'lwc';
import { createRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SignatureCapture extends LightningElement {
    @api recordId;
    isDrawing = false;
    hasSigned = false;
    isProcessing = false;
    error;

    canvas;
    ctx;
    lastX;
    lastY;

    renderedCallback() {
        if (!this.canvas) {
            this.canvas = this.template.querySelector('canvas');
            if (this.canvas) {
                this.ctx = this.canvas.getContext('2d');
                this.ctx.strokeStyle = '#000000';
                this.ctx.lineWidth = 2;
                this.ctx.lineCap = 'round';
                this.setupEvents();
            }
        }
    }

    setupEvents() {
        // Touch events
        this.canvas.addEventListener('touchstart', (e) => {
            e.preventDefault();
            this.startDraw(e.touches[0]);
        });
        this.canvas.addEventListener('touchmove', (e) => {
            e.preventDefault();
            this.draw(e.touches[0]);
        });
        this.canvas.addEventListener('touchend', () => this.stopDraw());

        // Mouse events (for testing in desktop browser)
        this.canvas.addEventListener('mousedown', (e) => this.startDraw(e));
        this.canvas.addEventListener('mousemove', (e) => {
            if (this.isDrawing) this.draw(e);
        });
        this.canvas.addEventListener('mouseup', () => this.stopDraw());
    }

    startDraw(event) {
        this.isDrawing = true;
        const rect = this.canvas.getBoundingClientRect();
        this.lastX = (event.clientX || event.pageX) - rect.left;
        this.lastY = (event.clientY || event.pageY) - rect.top;
    }

    draw(event) {
        if (!this.isDrawing) return;
        const rect = this.canvas.getBoundingClientRect();
        const x = (event.clientX || event.pageX) - rect.left;
        const y = (event.clientY || event.pageY) - rect.top;

        this.ctx.beginPath();
        this.ctx.moveTo(this.lastX, this.lastY);
        this.ctx.lineTo(x, y);
        this.ctx.stroke();

        this.lastX = x;
        this.lastY = y;
        this.hasSigned = true;
    }

    stopDraw() {
        this.isDrawing = false;
    }

    handleClear() {
        this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
        this.hasSigned = false;
    }

    async handleSave() {
        if (!this.hasSigned) {
            this.error = 'Please provide a signature.';
            return;
        }

        this.isProcessing = true;
        this.error = undefined;

        try {
            const dataUrl = this.canvas.toDataURL('image/png');
            const base64 = dataUrl.split(',')[1];

            await createRecord({
                apiName: 'ContentVersion',
                fields: {
                    Title: `Signature_${new Date().toISOString()}`,
                    PathOnClient: `signature_${Date.now()}.png`,
                    VersionData: base64,
                    FirstPublishLocationId: this.recordId
                }
            });

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Signature Saved',
                    message: 'Signature attached to record.',
                    variant: 'success'
                })
            );
            this.handleClear();
        } catch (err) {
            this.error = `Save failed: ${err.message || err.body?.message}`;
        } finally {
            this.isProcessing = false;
        }
    }
}
```

### signatureCapture.html

```html
<template>
    <lightning-card title="Customer Signature" icon-name="utility:edit">
        <div class="slds-p-around_medium">
            <template lwc:if={error}>
                <div class="slds-text-color_error slds-m-bottom_small">{error}</div>
            </template>

            <div class="signature-pad" style="border: 1px solid #d8dde6; border-radius: 4px; background: #fff;">
                <canvas width="350" height="150"></canvas>
            </div>

            <div class="slds-m-top_small">
                <lightning-button
                    label="Clear"
                    variant="neutral"
                    onclick={handleClear}
                    class="slds-m-right_small"
                ></lightning-button>
                <lightning-button
                    label="Save Signature"
                    variant="brand"
                    onclick={handleSave}
                    disabled={isProcessing}
                ></lightning-button>
            </div>
        </div>
    </lightning-card>
</template>
```

---

## Quick Action Meta XML

Use this for record-context LWCs deployed as Quick Actions on mobile.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>62.0</apiVersion>
    <isExposed>true</isExposed>
    <targets>
        <target>lightning__RecordAction</target>
    </targets>
    <targetConfigs>
        <targetConfig targets="lightning__RecordAction">
            <actionType>Action</actionType>
        </targetConfig>
    </targetConfigs>
</LightningComponentBundle>
```

After deploying, create the Quick Action:
**Setup > Object Manager > [Object] > Buttons, Links, and Actions > New Action**

| Setting | Value |
|---|---|
| Action Type | Lightning Web Component |
| Lightning Web Component | Your component |
| Height | 250px (adjust as needed) |

---

## Flow Screen Component Meta XML

Use this for LWCs embedded in Flows (including Data Capture Flows).

```xml
<?xml version="1.0" encoding="UTF-8"?>
<LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>62.0</apiVersion>
    <isExposed>true</isExposed>
    <targets>
        <target>lightning__FlowScreen</target>
    </targets>
    <targetConfigs>
        <targetConfig targets="lightning__FlowScreen">
            <property name="inputValue" type="String" label="Input Value" />
            <property name="outputValue" type="String" label="Output Value" role="outputOnly" />
        </targetConfig>
    </targetConfigs>
</LightningComponentBundle>
```

### Flow Navigation

```javascript
import { FlowNavigationNextEvent } from 'lightning/flowSupport';

// Navigate to next screen
handleNext() {
    const nextEvent = new FlowNavigationNextEvent();
    this.dispatchEvent(nextEvent);
}
```

---

## Performance Tips

| # | Tip | Detail |
|---|---|---|
| 1 | Keep bundles small | Avoid large libraries; minimize imports |
| 2 | Use `lwc:if` for lazy rendering | Conditionally render sections to reduce initial DOM |
| 3 | Debounce inputs | Use 300ms+ debounce on search/filter inputs |
| 4 | Compress images | Set `quality: 50-70` in camera capture options |
| 5 | Avoid setInterval/setTimeout loops | Use event-driven patterns instead |
| 6 | Use `lightning-record-*-form` | Prefer over imperative Apex for offline + performance |
| 7 | Minimize DOM depth | Flat component hierarchies render faster on mobile |

### Debounce Utility

```javascript
_debounceTimer;

handleSearchInput(event) {
    clearTimeout(this._debounceTimer);
    this._debounceTimer = setTimeout(() => {
        this.searchTerm = event.target.value;
    }, 300);
}
```

---

## Testing & Debugging

### iOS Debugging

1. Enable **Web Inspector** on device: Settings > Safari > Advanced > Web Inspector
2. Connect device via USB
3. Open Safari on Mac > Develop menu > [Device Name] > [Page]
4. Full Safari Web Inspector available (console, elements, network, etc.)

### Android Debugging

1. Enable **USB Debugging** on device: Settings > Developer Options > USB Debugging
2. Connect device via USB
3. Open Chrome on desktop > `chrome://inspect`
4. Select the WebView to inspect
5. Full Chrome DevTools available

### What Requires a Physical Device

| Capability | Simulator/Emulator | Physical Device |
|---|---|---|
| Camera | No | Required |
| NFC | No | Required |
| Barcode Scanner | No | Required |
| Real offline testing | Partial | Required |
| Performance profiling | Inaccurate | Required |
| GPS (real) | Simulated only | Required |
| Push notifications | Varies | Required |

### Salesforce Mobile vs Field Service Mobile

| Feature | Salesforce Mobile | Field Service Mobile |
|---|---|---|
| App name | Salesforce | Field Service |
| Primary users | All Salesforce users | Field technicians |
| Offline support | Limited | Full (Briefcase-based) |
| Data Capture Flows | No | Yes |
| Scheduling/Dispatch | No | Yes |
| Work Order management | Basic | Full |
| Service Appointments | View only | Full lifecycle |
| Inventory management | No | Yes |
| LWC support | Yes | Yes |
| Quick Actions | Yes | Yes |
| Custom tabs | Yes | Limited |
| Platform | iOS, Android | iOS, Android |
| Offline Apex | No | No |
| LDS offline | No | Yes (with Briefcase) |
