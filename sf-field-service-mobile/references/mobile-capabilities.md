# Mobile Device Capabilities Reference

## Import Summary

| Capability | Import | Method | Returns |
|---|---|---|---|
| BarcodeScanner | `lightning/mobileCapabilities` | `beginCapture(options)` | `{value, type}` |
| DeviceCamera | `lightning/mobileCapabilities` | `captureImage(options)` | `{base64, mimeType}` |
| LocationService | `lightning/mobileCapabilities` | `getCurrentPosition()` | `{coords, timestamp}` |
| NFC | `lightning/mobileCapabilities` | `readTag()` | `{records[]}` |

All capabilities follow the same availability-check pattern before use.

---

## BarcodeScanner

```javascript
import { LightningElement, api } from 'lwc';
import { getBarcodeScanner } from 'lightning/mobileCapabilities';

export default class BarcodeScannerExample extends LightningElement {
    @api recordId;
    scannedValue;
    scannedType;
    scanError;

    scanner;

    connectedCallback() {
        this.scanner = getBarcodeScanner();
    }

    get scannerAvailable() {
        return this.scanner != null && this.scanner.isAvailable();
    }

    handleScan() {
        if (!this.scannerAvailable) {
            this.scanError = 'BarcodeScanner is not available on this device.';
            return;
        }

        const scannerOptions = {
            barcodeTypes: [
                this.scanner.barcodeTypes.QR,
                this.scanner.barcodeTypes.CODE_128,
                this.scanner.barcodeTypes.CODE_39,
                this.scanner.barcodeTypes.EAN_13,
                this.scanner.barcodeTypes.EAN_8,
                this.scanner.barcodeTypes.UPC_A,
                this.scanner.barcodeTypes.UPC_E,
                this.scanner.barcodeTypes.DATA_MATRIX,
                this.scanner.barcodeTypes.PDF_417,
                this.scanner.barcodeTypes.CODE_93,
                this.scanner.barcodeTypes.ITF,
                this.scanner.barcodeTypes.AZTEC
            ],
            instructionText: 'Position barcode in the scanner window',
            successText: 'Barcode captured successfully'
        };

        this.scanner
            .beginCapture(scannerOptions)
            .then((result) => {
                this.scannedValue = result.value;
                this.scannedType = result.type;
                this.scanError = undefined;
            })
            .catch((error) => {
                if (error.code === 'USER_DISMISSED') {
                    // User cancelled — no action needed
                    this.scanError = 'Scan cancelled.';
                } else {
                    // UNKNOWN_REASON or other
                    this.scanError = `Scan error: ${error.message}`;
                }
            })
            .finally(() => {
                this.scanner.endCapture();
            });
    }
}
```

### Scanner Options

| Property | Type | Description |
|---|---|---|
| `barcodeTypes` | `String[]` | Array of barcode type constants from `scanner.barcodeTypes` |
| `instructionText` | `String` | Text shown in scanner UI |
| `successText` | `String` | Text shown on successful scan |

### Barcode Types

| Constant | Format |
|---|---|
| `QR` | QR Code |
| `CODE_128` | Code 128 |
| `CODE_39` | Code 39 |
| `EAN_13` | EAN-13 |
| `EAN_8` | EAN-8 |
| `UPC_A` | UPC-A |
| `UPC_E` | UPC-E |
| `DATA_MATRIX` | Data Matrix |
| `PDF_417` | PDF 417 |
| `CODE_93` | Code 93 |
| `ITF` | Interleaved 2 of 5 |
| `AZTEC` | Aztec |

### Error Codes

| Code | Description |
|---|---|
| `USER_DISMISSED` | User cancelled the scanner |
| `UNKNOWN_REASON` | Unexpected failure |

### Key Rules

- Always call `endCapture()` in a `finally` block to release the camera
- Always check `isAvailable()` before calling `beginCapture()`
- `beginCapture()` returns a Promise — use async/await or `.then()`

---

## DeviceCamera

```javascript
import { LightningElement, api } from 'lwc';
import { getDeviceCamera } from 'lightning/mobileCapabilities';
import { createRecord } from 'lightning/uiRecordApi';

export default class PhotoCaptureExample extends LightningElement {
    @api recordId;
    capturedImage;
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
            this.error = 'Camera is not available on this device.';
            return;
        }

        const captureOptions = {
            imageSource: 'camera',       // 'camera' | 'photoLibrary'
            cameraDirection: 'back',     // 'back' | 'front'
            allowsEditing: false,
            quality: 70                  // 0-100
        };

        try {
            const result = await this.camera.captureImage(captureOptions);
            this.capturedImage = `data:${result.mimeType};base64,${result.base64}`;
            await this.saveAsContentVersion(result);
        } catch (error) {
            if (error.code === 'USER_DISMISSED') {
                this.error = 'Photo capture cancelled.';
            } else if (error.code === 'CAMERA_NOT_AVAILABLE') {
                this.error = 'Camera hardware not available.';
            } else {
                this.error = `Capture error: ${error.message}`;
            }
        }
    }

    async saveAsContentVersion(imageResult) {
        const fields = {
            Title: `Photo_${Date.now()}`,
            PathOnClient: `photo_${Date.now()}.jpg`,
            VersionData: imageResult.base64,
            FirstPublishLocationId: this.recordId
        };

        try {
            await createRecord({ apiName: 'ContentVersion', fields });
        } catch (error) {
            this.error = `Save error: ${error.message}`;
        }
    }
}
```

### Capture Options

| Property | Type | Values | Default |
|---|---|---|---|
| `imageSource` | `String` | `'camera'`, `'photoLibrary'` | `'camera'` |
| `cameraDirection` | `String` | `'back'`, `'front'` | `'back'` |
| `allowsEditing` | `Boolean` | `true`, `false` | `false` |
| `quality` | `Number` | `0` - `100` | `100` |

### Return Value

| Property | Type | Description |
|---|---|---|
| `base64` | `String` | Base64-encoded image data |
| `mimeType` | `String` | MIME type (e.g., `image/jpeg`) |

### Error Codes

| Code | Description |
|---|---|
| `USER_DISMISSED` | User cancelled capture |
| `CAMERA_NOT_AVAILABLE` | No camera hardware accessible |

---

## LocationService

```javascript
import { LightningElement, api } from 'lwc';
import { getLocationService } from 'lightning/mobileCapabilities';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import SA_ID from '@salesforce/schema/ServiceAppointment.Id';
import SA_STATUS from '@salesforce/schema/ServiceAppointment.Status';
import SA_START from '@salesforce/schema/ServiceAppointment.ActualStartTime';
import SA_LAT from '@salesforce/schema/ServiceAppointment.Latitude';
import SA_LONG from '@salesforce/schema/ServiceAppointment.Longitude';

export default class GpsCheckInExample extends LightningElement {
    @api recordId; // ServiceAppointment Id
    locationData;
    error;

    locationService;

    connectedCallback() {
        this.locationService = getLocationService();
    }

    get locationAvailable() {
        return this.locationService != null && this.locationService.isAvailable();
    }

    async handleCheckIn() {
        if (!this.locationAvailable) {
            this.error = 'Location services not available.';
            return;
        }

        try {
            const location = await this.locationService.getCurrentPosition();
            this.locationData = location;

            const fields = {};
            fields[SA_ID.fieldApiName] = this.recordId;
            fields[SA_STATUS.fieldApiName] = 'In Progress';
            fields[SA_START.fieldApiName] = new Date().toISOString();
            fields[SA_LAT.fieldApiName] = location.coords.latitude;
            fields[SA_LONG.fieldApiName] = location.coords.longitude;

            await updateRecord({ fields });

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Checked In',
                    message: `Location: ${location.coords.latitude.toFixed(5)}, ${location.coords.longitude.toFixed(5)}`,
                    variant: 'success'
                })
            );
        } catch (error) {
            if (error.code === 'PERMISSION_DENIED') {
                this.error = 'Location permission denied. Enable in device settings.';
            } else if (error.code === 'POSITION_UNAVAILABLE') {
                this.error = 'Unable to determine position. Check GPS signal.';
            } else if (error.code === 'TIMEOUT') {
                this.error = 'Location request timed out. Try again.';
            } else {
                this.error = `Location error: ${error.message}`;
            }
        }
    }
}
```

### Return Value — `getCurrentPosition()`

```javascript
{
    coords: {
        latitude: 37.7749,         // Number — degrees
        longitude: -122.4194,      // Number — degrees
        accuracy: 10.0,            // Number — meters
        altitude: 15.0,            // Number — meters (may be null)
        altitudeAccuracy: 5.0      // Number — meters (may be null)
    },
    timestamp: 1700000000000       // Number — milliseconds since epoch
}
```

### Error Codes

| Code | Description |
|---|---|
| `PERMISSION_DENIED` | User denied location permission |
| `POSITION_UNAVAILABLE` | Device cannot determine position |
| `TIMEOUT` | Location request timed out |

---

## NFC (Near Field Communication)

```javascript
import { LightningElement, api } from 'lwc';
import { getNfcService } from 'lightning/mobileCapabilities';

export default class NfcReaderExample extends LightningElement {
    @api recordId;
    nfcData;
    error;

    nfcService;

    connectedCallback() {
        this.nfcService = getNfcService();
    }

    get nfcAvailable() {
        return this.nfcService != null && this.nfcService.isAvailable();
    }

    async handleReadTag() {
        if (!this.nfcAvailable) {
            this.error = 'NFC is not available on this device.';
            return;
        }

        try {
            const tag = await this.nfcService.readTag();
            // tag.records is an array of NDEF records
            if (tag.records && tag.records.length > 0) {
                const record = tag.records[0];
                this.nfcData = {
                    tnf: record.tnf,       // Type Name Format
                    type: record.type,      // Record type
                    id: record.id,          // Record ID
                    payload: record.payload // Record payload (Uint8Array)
                };

                // Decode text payload
                const decoder = new TextDecoder();
                const payloadText = decoder.decode(record.payload);
                this.nfcData.text = payloadText;
            }
        } catch (error) {
            this.error = `NFC error: ${error.message}`;
        }
    }
}
```

### Return Value — `readTag()`

```javascript
{
    records: [
        {
            tnf: 1,                    // Number — Type Name Format
            type: "T",                 // String — Record type
            id: "",                    // String — Record identifier
            payload: Uint8Array([...]) // Uint8Array — Raw payload bytes
        }
    ]
}
```

### Platform Notes

| Platform | Reading | Writing |
|---|---|---|
| iOS | Supported (iPhone 7+) | Limited |
| Android | Supported | Varies by device/OS |

### Use Cases

- Asset identification via NFC tags
- Equipment check-in/check-out
- Tool tracking and inventory
- Facility access logging

---

## Availability Check Pattern (Universal)

All mobile capabilities follow the same pattern:

```javascript
import { getXxxCapability } from 'lightning/mobileCapabilities';

// In connectedCallback
this.capability = getXxxCapability();

// Before use
if (this.capability != null && this.capability.isAvailable()) {
    // Safe to use
}
```

`isAvailable()` returns `false` in:
- Desktop browsers
- Lightning Experience (non-mobile)
- Devices without the required hardware
- When permissions are not granted (varies by capability)
