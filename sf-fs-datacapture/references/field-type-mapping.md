# Field Type Mapping Reference — DC Components

Data capture flows use **Field Service DC components** (`runtime_service_fieldservice:dc*`), NOT standard flow field types. This reference shows every component pattern.

## DC Text Input

Replaces `InputField` and `LargeTextArea`. Handles both short and long text.

```xml
<fields>
    <name>{{Field_Name}}</name>
    <extensionName>runtime_service_fieldservice:dcTextInput</extensionName>
    <fieldType>ComponentInstance</fieldType>
    <inputParameters>
        <name>label</name>
        <value>
            <stringValue>{{Label}}</stringValue>
        </value>
    </inputParameters>
    <inputsOnNextNavToAssocScrn>UseStoredValues</inputsOnNextNavToAssocScrn>
    <isRequired>{{true|false}}</isRequired>
    <storeOutputAutomatically>true</storeOutputAutomatically>
    <styleProperties>
        <verticalAlignment><stringValue>top</stringValue></verticalAlignment>
        <width><stringValue>12</stringValue></width>
    </styleProperties>
</fields>
```

For required fields, add the `required` input parameter alongside `isRequired`:
```xml
<inputParameters>
    <name>required</name>
    <value><booleanValue>true</booleanValue></value>
</inputParameters>
<isRequired>true</isRequired>
```

### Half-width (side-by-side layout)

Set `width` to `6` for two fields on one row:
```xml
<styleProperties>
    <verticalAlignment><stringValue>top</stringValue></verticalAlignment>
    <width><stringValue>6</stringValue></width>
</styleProperties>
```

## DC Picklist (Single-Select Dropdown)

Replaces `DropdownBox`.

```xml
<fields>
    <name>{{Field_Name}}</name>
    <choiceReferences>{{Choice_1}}</choiceReferences>
    <choiceReferences>{{Choice_2}}</choiceReferences>
    <extensionName>runtime_service_fieldservice:dcPicklist</extensionName>
    <fieldText>{{Label}}</fieldText>
    <fieldType>ComponentChoice</fieldType>
    <inputsOnNextNavToAssocScrn>UseStoredValues</inputsOnNextNavToAssocScrn>
    <isRequired>{{true|false}}</isRequired>
    <storeOutputAutomatically>true</storeOutputAutomatically>
    <styleProperties>
        <verticalAlignment><stringValue>top</stringValue></verticalAlignment>
        <width><stringValue>12</stringValue></width>
    </styleProperties>
</fields>
```

## DC Checkbox Group (Multi-Select)

Replaces `MultiSelectCheckboxes`.

```xml
<fields>
    <name>{{Field_Name}}</name>
    <choiceReferences>{{Choice_1}}</choiceReferences>
    <choiceReferences>{{Choice_2}}</choiceReferences>
    <extensionName>runtime_service_fieldservice:dcCbGroup</extensionName>
    <fieldText>{{Label}} (Select All That Apply)</fieldText>
    <fieldType>ComponentMultiChoice</fieldType>
    <inputsOnNextNavToAssocScrn>UseStoredValues</inputsOnNextNavToAssocScrn>
    <isRequired>false</isRequired>
    <storeOutputAutomatically>true</storeOutputAutomatically>
    <styleProperties>
        <verticalAlignment><stringValue>top</stringValue></verticalAlignment>
        <width><stringValue>12</stringValue></width>
    </styleProperties>
</fields>
```

## DC Toggle (Boolean)

Replaces `InputField` with `dataType: Boolean`.

```xml
<fields>
    <name>{{Toggle_Name}}</name>
    <extensionName>runtime_service_fieldservice:dcToggle</extensionName>
    <fieldType>ComponentInstance</fieldType>
    <inputParameters>
        <name>label</name>
        <value><stringValue>{{Question}}</stringValue></value>
    </inputParameters>
    <inputsOnNextNavToAssocScrn>UseStoredValues</inputsOnNextNavToAssocScrn>
    <isRequired>{{true|false}}</isRequired>
    <storeOutputAutomatically>true</storeOutputAutomatically>
    <styleProperties>
        <verticalAlignment><stringValue>top</stringValue></verticalAlignment>
        <width><stringValue>12</stringValue></width>
    </styleProperties>
</fields>
```

Reference toggle state: `{{Toggle_Name}}.isActive` (returns Boolean).

## DC Image Upload (Camera)

```xml
<fields>
    <name>{{Upload_Name}}</name>
    <extensionName>runtime_service_fieldservice:dcUpImage</extensionName>
    <fieldType>ComponentInstance</fieldType>
    <inputParameters>
        <name>label</name>
        <value><stringValue>Upload Photos</stringValue></value>
    </inputParameters>
    <inputParameters>
        <name>useCameraOnly</name>
        <value><booleanValue>true</booleanValue></value>
    </inputParameters>
    <inputsOnNextNavToAssocScrn>UseStoredValues</inputsOnNextNavToAssocScrn>
    <isRequired>{{true|false}}</isRequired>
    <storeOutputAutomatically>true</storeOutputAutomatically>
    <styleProperties>
        <verticalAlignment><stringValue>top</stringValue></verticalAlignment>
        <width><stringValue>12</stringValue></width>
    </styleProperties>
</fields>
```

## DC Signature

```xml
<fields>
    <name>{{Signature_Name}}</name>
    <extensionName>runtime_service_fieldservice:dcSignature</extensionName>
    <fieldType>ComponentInstance</fieldType>
    <inputParameters>
        <name>label</name>
        <value><stringValue>Customer Signature</stringValue></value>
    </inputParameters>
    <inputParameters>
        <name>parentRecordId</name>
        <value><elementReference>parentRecordId</elementReference></value>
    </inputParameters>
    <inputsOnNextNavToAssocScrn>UseStoredValues</inputsOnNextNavToAssocScrn>
    <isRequired>false</isRequired>
    <storeOutputAutomatically>true</storeOutputAutomatically>
    <styleProperties>
        <verticalAlignment><stringValue>top</stringValue></verticalAlignment>
        <width><stringValue>12</stringValue></width>
    </styleProperties>
</fields>
```

## Display Text (Headers, Instructions, Context)

Standard flow `DisplayText` — no DC extension needed.

### Section Header
```xml
<fields>
    <name>Section_{{Name}}</name>
    <fieldText>&lt;p&gt;&lt;b style=&quot;font-size: 14px;&quot;&gt;{{Section Title}}&lt;/b&gt;&lt;/p&gt;</fieldText>
    <fieldType>DisplayText</fieldType>
    <styleProperties>
        <verticalAlignment><stringValue>top</stringValue></verticalAlignment>
        <width><stringValue>12</stringValue></width>
    </styleProperties>
</fields>
```

### Work Order Context
```xml
<fields>
    <name>Display_WO_Context</name>
    <fieldText>&lt;p&gt;&lt;b&gt;Work Order:&lt;/b&gt; {!Get_Work_Order.WorkOrderNumber}&lt;/p&gt;&lt;p&gt;&lt;b&gt;Subject:&lt;/b&gt; {!Get_Work_Order.Subject}&lt;/p&gt;</fieldText>
    <fieldType>DisplayText</fieldType>
    <styleProperties>
        <verticalAlignment><stringValue>top</stringValue></verticalAlignment>
        <width><stringValue>12</stringValue></width>
    </styleProperties>
</fields>
```

### Instructions / Reminder
```xml
<fields>
    <name>{{Purpose}}_Instructions</name>
    <fieldText>&lt;p&gt;&lt;b&gt;Reminder:&lt;/b&gt; {{Instruction text}}&lt;/p&gt;</fieldText>
    <fieldType>DisplayText</fieldType>
    <styleProperties>
        <verticalAlignment><stringValue>top</stringValue></verticalAlignment>
        <width><stringValue>12</stringValue></width>
    </styleProperties>
</fields>
```

## Conditional Visibility (visibilityRule)

Show a field only when a toggle is active:
```xml
<visibilityRule>
    <conditionLogic>and</conditionLogic>
    <conditions>
        <leftValueReference>{{Toggle_Name}}.isActive</leftValueReference>
        <operator>EqualTo</operator>
        <rightValue>
            <booleanValue>true</booleanValue>
        </rightValue>
    </conditions>
</visibilityRule>
```

Show when toggle is OFF (e.g., "Describe why not"):
```xml
<rightValue>
    <booleanValue>false</booleanValue>
</rightValue>
```

## Choice Definition Pattern

```xml
<choices>
    <name>{{Choice_Name}}</name>
    <choiceText>{{Display Label}}</choiceText>
    <dataType>String</dataType>
    <value>
        <stringValue>{{Stored Value}}</stringValue>
    </value>
</choices>
```

## Component Summary Table

| Document Field | DC Component | fieldType | extensionName |
|---------------|-------------|-----------|---------------|
| Any text | dcTextInput | `ComponentInstance` | `runtime_service_fieldservice:dcTextInput` |
| Single-select | dcPicklist | `ComponentChoice` | `runtime_service_fieldservice:dcPicklist` |
| Multi-select | dcCbGroup | `ComponentMultiChoice` | `runtime_service_fieldservice:dcCbGroup` |
| Yes/No toggle | dcToggle | `ComponentInstance` | `runtime_service_fieldservice:dcToggle` |
| Photo capture | dcUpImage | `ComponentInstance` | `runtime_service_fieldservice:dcUpImage` |
| Signature | dcSignature | `ComponentInstance` | `runtime_service_fieldservice:dcSignature` |
| Header/text | _(none)_ | `DisplayText` | _(none)_ |
