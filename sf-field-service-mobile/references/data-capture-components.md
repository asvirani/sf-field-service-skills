# Data Capture Flow Components Reference

## Component Summary

| Component | Description | LLM Targetable | Output Type |
|---|---|---|---|
| `dcText` | Single-line text input | Yes | String |
| `dcTextArea` | Multi-line text input | Yes | String |
| `dcNumber` | Numeric input | Yes | Number |
| `dcPicklist` | Single/multi-select dropdown | Yes | String / String[] |
| `dcToggle` | Boolean toggle switch | Yes | Boolean |
| `dcDateTime` | Date, datetime, or time picker | Yes | DateTime / Date / Time |
| `dcSignature` | Signature capture pad | No | Base64 (ContentVersion) |
| `dcImage` | Photo capture / library select | No | ContentVersion references |
| `dcBarcode` | Barcode/QR scanner | No | String |
| `dcSection` | Collapsible section header | N/A | — (layout only) |
| `dcRepeater` | Repeating field group | N/A | Array of objects |

**LLM Targetable** = Voice-to-form capable. Technician speaks, LLM fills the field automatically.

---

## dcText

Single-line text input field.

### Parameters

| Parameter | Type | Required | Description |
|---|---|---|---|
| `label` | String | Yes | Field label |
| `required` | Boolean | No | Whether input is mandatory |
| `maxLength` | Number | No | Maximum character count |
| `placeholder` | String | No | Placeholder hint text |

### XML Example

```xml
<fields>
    <fieldType>ComponentInstance</fieldType>
    <name>dcText</name>
    <extensionName>dcText</extensionName>
    <inputParameters>
        <name>label</name>
        <value><stringValue>Equipment Name</stringValue></value>
    </inputParameters>
    <inputParameters>
        <name>required</name>
        <value><booleanValue>true</booleanValue></value>
    </inputParameters>
    <inputParameters>
        <name>maxLength</name>
        <value><numberValue>255</numberValue></value>
    </inputParameters>
    <inputParameters>
        <name>placeholder</name>
        <value><stringValue>Enter equipment name</stringValue></value>
    </inputParameters>
    <isLlmTargetable>true</isLlmTargetable>
</fields>
```

---

## dcTextArea

Multi-line text input field.

### Parameters

| Parameter | Type | Required | Description |
|---|---|---|---|
| `label` | String | Yes | Field label |
| `required` | Boolean | No | Whether input is mandatory |
| `maxLength` | Number | No | Maximum character count |

### XML Example

```xml
<fields>
    <fieldType>ComponentInstance</fieldType>
    <name>dcTextArea</name>
    <extensionName>dcTextArea</extensionName>
    <inputParameters>
        <name>label</name>
        <value><stringValue>Work Summary</stringValue></value>
    </inputParameters>
    <inputParameters>
        <name>required</name>
        <value><booleanValue>true</booleanValue></value>
    </inputParameters>
    <inputParameters>
        <name>maxLength</name>
        <value><numberValue>5000</numberValue></value>
    </inputParameters>
    <isLlmTargetable>true</isLlmTargetable>
</fields>
```

---

## dcNumber

Numeric input field with optional min/max/step constraints.

### Parameters

| Parameter | Type | Required | Description |
|---|---|---|---|
| `label` | String | Yes | Field label |
| `required` | Boolean | No | Whether input is mandatory |
| `min` | Number | No | Minimum value |
| `max` | Number | No | Maximum value |
| `step` | Number | No | Increment step (e.g., 0.5) |
| `placeholder` | String | No | Placeholder hint text |

### XML Example

```xml
<fields>
    <fieldType>ComponentInstance</fieldType>
    <name>dcNumber</name>
    <extensionName>dcNumber</extensionName>
    <inputParameters>
        <name>label</name>
        <value><stringValue>Temperature Reading (F)</stringValue></value>
    </inputParameters>
    <inputParameters>
        <name>required</name>
        <value><booleanValue>true</booleanValue></value>
    </inputParameters>
    <inputParameters>
        <name>min</name>
        <value><numberValue>-40</numberValue></value>
    </inputParameters>
    <inputParameters>
        <name>max</name>
        <value><numberValue>300</numberValue></value>
    </inputParameters>
    <inputParameters>
        <name>step</name>
        <value><numberValue>0.1</numberValue></value>
    </inputParameters>
    <isLlmTargetable>true</isLlmTargetable>
</fields>
```

---

## dcPicklist

Single-select or multi-select dropdown.

### Parameters

| Parameter | Type | Required | Description |
|---|---|---|---|
| `label` | String | Yes | Field label |
| `required` | Boolean | No | Whether input is mandatory |
| `options` | String | Yes | Comma-separated option values |
| `multiSelect` | Boolean | No | Enable multi-select (default: false) |

### XML Example

```xml
<fields>
    <fieldType>ComponentInstance</fieldType>
    <name>dcPicklist</name>
    <extensionName>dcPicklist</extensionName>
    <inputParameters>
        <name>label</name>
        <value><stringValue>Issue Type</stringValue></value>
    </inputParameters>
    <inputParameters>
        <name>required</name>
        <value><booleanValue>true</booleanValue></value>
    </inputParameters>
    <inputParameters>
        <name>options</name>
        <value><stringValue>Electrical,Plumbing,HVAC,Structural,Other</stringValue></value>
    </inputParameters>
    <inputParameters>
        <name>multiSelect</name>
        <value><booleanValue>false</booleanValue></value>
    </inputParameters>
    <isLlmTargetable>true</isLlmTargetable>
</fields>
```

---

## dcToggle

Boolean toggle switch.

### Parameters

| Parameter | Type | Required | Description |
|---|---|---|---|
| `label` | String | Yes | Field label |
| `defaultValue` | Boolean | No | Initial toggle state |

### XML Example

```xml
<fields>
    <fieldType>ComponentInstance</fieldType>
    <name>dcToggle</name>
    <extensionName>dcToggle</extensionName>
    <inputParameters>
        <name>label</name>
        <value><stringValue>Safety Check Passed</stringValue></value>
    </inputParameters>
    <inputParameters>
        <name>defaultValue</name>
        <value><booleanValue>false</booleanValue></value>
    </inputParameters>
    <isLlmTargetable>true</isLlmTargetable>
</fields>
```

---

## dcDateTime

Date, datetime, or time picker.

### Parameters

| Parameter | Type | Required | Description |
|---|---|---|---|
| `label` | String | Yes | Field label |
| `required` | Boolean | No | Whether input is mandatory |
| `type` | String | No | `'date'`, `'datetime'`, or `'time'` (default: `'datetime'`) |

### XML Example

```xml
<fields>
    <fieldType>ComponentInstance</fieldType>
    <name>dcDateTime</name>
    <extensionName>dcDateTime</extensionName>
    <inputParameters>
        <name>label</name>
        <value><stringValue>Service Completed At</stringValue></value>
    </inputParameters>
    <inputParameters>
        <name>required</name>
        <value><booleanValue>true</booleanValue></value>
    </inputParameters>
    <inputParameters>
        <name>type</name>
        <value><stringValue>datetime</stringValue></value>
    </inputParameters>
    <isLlmTargetable>true</isLlmTargetable>
</fields>
```

---

## dcSignature

Signature capture pad. Renders a touch-input canvas for handwritten signatures.

### Parameters

| Parameter | Type | Required | Description |
|---|---|---|---|
| `label` | String | Yes | Field label |
| `required` | Boolean | No | Whether signature is mandatory |

### Output

- Base64-encoded PNG image
- Stored as a `ContentVersion` record attached to the parent record

### XML Example

```xml
<fields>
    <fieldType>ComponentInstance</fieldType>
    <name>dcSignature</name>
    <extensionName>dcSignature</extensionName>
    <inputParameters>
        <name>label</name>
        <value><stringValue>Customer Signature</stringValue></value>
    </inputParameters>
    <inputParameters>
        <name>required</name>
        <value><booleanValue>true</booleanValue></value>
    </inputParameters>
    <isLlmTargetable>false</isLlmTargetable>
</fields>
```

**Not LLM Targetable** — requires physical touch interaction.

---

## dcImage

Photo capture from camera or photo library.

### Parameters

| Parameter | Type | Required | Description |
|---|---|---|---|
| `label` | String | Yes | Field label |
| `required` | Boolean | No | Whether at least one image is required |
| `maxCount` | Number | No | Maximum number of images allowed |

### Output

- Image files stored as `ContentVersion` records
- Supports both camera capture and photo library selection

### XML Example

```xml
<fields>
    <fieldType>ComponentInstance</fieldType>
    <name>dcImage</name>
    <extensionName>dcImage</extensionName>
    <inputParameters>
        <name>label</name>
        <value><stringValue>Before Photos</stringValue></value>
    </inputParameters>
    <inputParameters>
        <name>required</name>
        <value><booleanValue>true</booleanValue></value>
    </inputParameters>
    <inputParameters>
        <name>maxCount</name>
        <value><numberValue>5</numberValue></value>
    </inputParameters>
    <isLlmTargetable>false</isLlmTargetable>
</fields>
```

**Not LLM Targetable** — requires camera/photo library interaction.

---

## dcBarcode

Barcode and QR code scanner.

### Parameters

| Parameter | Type | Required | Description |
|---|---|---|---|
| `label` | String | Yes | Field label |

### Output

- String value of the scanned barcode

### Supported Formats

QR, Code 128, Code 39, EAN-13, EAN-8, UPC-A, UPC-E

### XML Example

```xml
<fields>
    <fieldType>ComponentInstance</fieldType>
    <name>dcBarcode</name>
    <extensionName>dcBarcode</extensionName>
    <inputParameters>
        <name>label</name>
        <value><stringValue>Scan Asset Barcode</stringValue></value>
    </inputParameters>
    <isLlmTargetable>false</isLlmTargetable>
</fields>
```

**Not LLM Targetable** — requires physical barcode scanning.

---

## dcSection

Collapsible section header for grouping related fields.

### Parameters

| Parameter | Type | Required | Description |
|---|---|---|---|
| `label` | String | Yes | Section header text |
| `collapsed` | Boolean | No | Start collapsed (default: false) |

### XML Example

```xml
<fields>
    <fieldType>ComponentInstance</fieldType>
    <name>dcSection</name>
    <extensionName>dcSection</extensionName>
    <inputParameters>
        <name>label</name>
        <value><stringValue>Equipment Details</stringValue></value>
    </inputParameters>
    <inputParameters>
        <name>collapsed</name>
        <value><booleanValue>false</booleanValue></value>
    </inputParameters>
</fields>
```

**LLM Targetable: N/A** — layout component, no data input.

---

## dcRepeater

Repeating field group for collecting multiple sets of the same data (e.g., multiple parts, multiple readings).

### Parameters

| Parameter | Type | Required | Description |
|---|---|---|---|
| `label` | String | Yes | Repeater group label |
| `minItems` | Number | No | Minimum number of entries |
| `maxItems` | Number | No | Maximum number of entries |

### Output

- Array of objects, each containing the values from child component fields
- Child components define the repeating field set

### XML Example

```xml
<fields>
    <fieldType>ComponentInstance</fieldType>
    <name>dcRepeater</name>
    <extensionName>dcRepeater</extensionName>
    <inputParameters>
        <name>label</name>
        <value><stringValue>Parts Used</stringValue></value>
    </inputParameters>
    <inputParameters>
        <name>minItems</name>
        <value><numberValue>1</numberValue></value>
    </inputParameters>
    <inputParameters>
        <name>maxItems</name>
        <value><numberValue>10</numberValue></value>
    </inputParameters>
    <!-- Child fields go here -->
    <fields>
        <fieldType>ComponentInstance</fieldType>
        <name>dcText</name>
        <extensionName>dcText</extensionName>
        <inputParameters>
            <name>label</name>
            <value><stringValue>Part Number</stringValue></value>
        </inputParameters>
        <isLlmTargetable>true</isLlmTargetable>
    </fields>
    <fields>
        <fieldType>ComponentInstance</fieldType>
        <name>dcNumber</name>
        <extensionName>dcNumber</extensionName>
        <inputParameters>
            <name>label</name>
            <value><stringValue>Quantity</stringValue></value>
        </inputParameters>
        <inputParameters>
            <name>min</name>
            <value><numberValue>1</numberValue></value>
        </inputParameters>
        <isLlmTargetable>true</isLlmTargetable>
    </fields>
</fields>
```

**LLM Targetable: N/A** — container component. Child fields may individually be LLM targetable.
