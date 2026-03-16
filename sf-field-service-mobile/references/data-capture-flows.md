# Data Capture Flows Reference

## What They Are

Data Capture Flows are a Field Service-specific flow type designed for mobile technicians to collect structured data in the field. They are offline-capable and support voice-to-form input via Einstein.

### DC Flow vs Screen Flow

| Feature | Data Capture Flow | Screen Flow |
|---|---|---|
| `processType` | `DataCaptureFlow` | `Flow` |
| Offline support | Yes (built-in) | No |
| Voice-to-form (LLM) | Yes | No |
| Platform | Field Service Mobile only | Any Salesforce surface |
| Components | DC-specific (`dcText`, `dcImage`, etc.) | Standard flow screen components |
| Assignment | Via Work Type | Via record page, button, etc. |
| Use case | Field data collection | General-purpose automation |
| Builder | Flow Builder (DC type) | Flow Builder (Screen type) |

---

## XML Structure

### Complete Template

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Flow xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>62.0</apiVersion>
    <label>Equipment Inspection</label>
    <processType>DataCaptureFlow</processType>
    <status>Active</status>
    <interviewLabel>Equipment Inspection {!$Flow.CurrentDateTime}</interviewLabel>

    <!-- Variables -->
    <variables>
        <name>recordId</name>
        <dataType>String</dataType>
        <isInput>true</isInput>
        <isOutput>false</isOutput>
    </variables>

    <variables>
        <name>workOrderRecord</name>
        <dataType>SObject</dataType>
        <isInput>false</isInput>
        <isOutput>false</isOutput>
        <objectType>WorkOrder</objectType>
    </variables>

    <!-- Start Element -->
    <start>
        <locationX>50</locationX>
        <locationY>0</locationY>
        <connector>
            <targetReference>InspectionScreen</targetReference>
        </connector>
    </start>

    <!-- Data Capture Screen -->
    <screens>
        <name>InspectionScreen</name>
        <label>Inspection</label>
        <locationX>176</locationX>
        <locationY>158</locationY>
        <connector>
            <targetReference>SaveResults</targetReference>
        </connector>
        <fields>
            <fieldType>ComponentInstance</fieldType>
            <name>dcSection_Equipment</name>
            <extensionName>dcSection</extensionName>
            <inputParameters>
                <name>label</name>
                <value><stringValue>Equipment Details</stringValue></value>
            </inputParameters>
        </fields>
        <fields>
            <fieldType>ComponentInstance</fieldType>
            <name>equipmentCondition</name>
            <extensionName>dcPicklist</extensionName>
            <inputParameters>
                <name>label</name>
                <value><stringValue>Equipment Condition</stringValue></value>
            </inputParameters>
            <inputParameters>
                <name>required</name>
                <value><booleanValue>true</booleanValue></value>
            </inputParameters>
            <inputParameters>
                <name>options</name>
                <value><stringValue>Good,Fair,Poor,Non-Functional</stringValue></value>
            </inputParameters>
            <isLlmTargetable>true</isLlmTargetable>
        </fields>
        <fields>
            <fieldType>ComponentInstance</fieldType>
            <name>temperatureReading</name>
            <extensionName>dcNumber</extensionName>
            <inputParameters>
                <name>label</name>
                <value><stringValue>Temperature (F)</stringValue></value>
            </inputParameters>
            <inputParameters>
                <name>min</name>
                <value><numberValue>-40</numberValue></value>
            </inputParameters>
            <inputParameters>
                <name>max</name>
                <value><numberValue>300</numberValue></value>
            </inputParameters>
            <isLlmTargetable>true</isLlmTargetable>
        </fields>
        <fields>
            <fieldType>ComponentInstance</fieldType>
            <name>notes</name>
            <extensionName>dcTextArea</extensionName>
            <inputParameters>
                <name>label</name>
                <value><stringValue>Technician Notes</stringValue></value>
            </inputParameters>
            <isLlmTargetable>true</isLlmTargetable>
        </fields>
        <fields>
            <fieldType>ComponentInstance</fieldType>
            <name>safetyPassed</name>
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
        <fields>
            <fieldType>ComponentInstance</fieldType>
            <name>sitePhotos</name>
            <extensionName>dcImage</extensionName>
            <inputParameters>
                <name>label</name>
                <value><stringValue>Site Photos</stringValue></value>
            </inputParameters>
            <inputParameters>
                <name>maxCount</name>
                <value><numberValue>3</numberValue></value>
            </inputParameters>
            <isLlmTargetable>false</isLlmTargetable>
        </fields>
        <fields>
            <fieldType>ComponentInstance</fieldType>
            <name>customerSignature</name>
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
    </screens>

    <!-- Assignment Element — Map DC field values to record -->
    <assignments>
        <name>SaveResults</name>
        <label>Map to Work Order</label>
        <locationX>176</locationX>
        <locationY>350</locationY>
        <connector>
            <targetReference>UpdateWorkOrder</targetReference>
        </connector>
        <assignmentItems>
            <assignToReference>workOrderRecord.Id</assignToReference>
            <operator>Assign</operator>
            <value><elementReference>recordId</elementReference></value>
        </assignmentItems>
        <assignmentItems>
            <assignToReference>workOrderRecord.Description</assignToReference>
            <operator>Assign</operator>
            <value><elementReference>InspectionScreen.notes</elementReference></value>
        </assignmentItems>
    </assignments>

    <!-- Update Record Element -->
    <recordUpdates>
        <name>UpdateWorkOrder</name>
        <label>Update Work Order</label>
        <locationX>176</locationX>
        <locationY>500</locationY>
        <inputReference>workOrderRecord</inputReference>
    </recordUpdates>
</Flow>
```

### Key XML Patterns

| Pattern | Element |
|---|---|
| DC component field | `<fieldType>ComponentInstance</fieldType>` |
| Component type | `<extensionName>dcText</extensionName>` |
| Parameters | `<inputParameters><name>...</name><value>...</value></inputParameters>` |
| Voice-to-form flag | `<isLlmTargetable>true</isLlmTargetable>` |
| Field reference | `{!ScreenName.fieldName}` |

---

## Voice-to-Form (IsLlmTargetable)

### How It Works

1. Technician taps the microphone icon on the DC flow screen
2. Speech is captured and sent to the server
3. Einstein LLM parses the speech and maps content to fields marked `isLlmTargetable="true"`
4. Fields auto-populate; technician reviews and confirms

### Supported Components

| Component | LLM Targetable | Reason |
|---|---|---|
| `dcText` | Yes | Text can be transcribed |
| `dcTextArea` | Yes | Text can be transcribed |
| `dcNumber` | Yes | Numbers can be parsed from speech |
| `dcPicklist` | Yes | Options can be matched from speech |
| `dcToggle` | Yes | Yes/no can be parsed |
| `dcDateTime` | Yes | Dates/times can be parsed |
| `dcSignature` | No | Requires physical touch |
| `dcImage` | No | Requires camera interaction |
| `dcBarcode` | No | Requires physical scanning |
| `dcSection` | N/A | Layout only |
| `dcRepeater` | N/A | Container only |

### Requirements

- **Einstein for Field Service** license
- **Connectivity** at time of voice capture (LLM processing is server-side)
- Fields must have `<isLlmTargetable>true</isLlmTargetable>` in flow XML

### Voice Input Tips

- Clear, descriptive labels help the LLM map speech to fields
- Picklist option values should be natural language (not codes)
- Avoid ambiguous field labels that could confuse the parser

---

## Record Mapping

### Pattern: DC Fields to SObject Records

```
DC Screen Fields → Assignment Element → Record Variable → Create/Update Record
```

### Step-by-Step

1. **DC screen collects data** via `dcText`, `dcNumber`, etc.
2. **Assignment element** maps screen field outputs to record variable fields
3. **Create Record** or **Update Record** element persists the data

### Field References

Access DC field output values using: `{!ScreenName.fieldName}`

```xml
<!-- In Assignment element -->
<assignmentItems>
    <assignToReference>myWorkOrder.Subject</assignToReference>
    <operator>Assign</operator>
    <value><elementReference>InspectionScreen.equipmentCondition</elementReference></value>
</assignmentItems>
```

### ContentVersion for Images & Signatures

`dcImage` and `dcSignature` automatically create `ContentVersion` records. They are linked to the parent record via `FirstPublishLocationId`. No additional flow logic is required to persist them.

### Child Records for Repeater Data

`dcRepeater` outputs an array. Use a **Loop** element to iterate and a **Create Records** element inside the loop to persist each entry as a child record.

---

## Deployment & Assignment

### Step 1: Create the Flow

- Flow Builder > New Flow > **Data Capture Flow**
- Or deploy via metadata (`processType: DataCaptureFlow`)

### Step 2: Activate

- Flow must be active to appear on mobile

### Step 3: Assign to Work Types

**Setup > Field Service > Work Types > [Work Type] > Data Capture Flows**

| Setting | Description |
|---|---|
| Flow selection | Pick from active Data Capture Flows |
| Order | Display order on mobile (drag to reorder) |
| Multiple flows | Multiple DC flows per Work Type allowed |

### Step 4: Work Type Assignment Chain

```
Work Type → Work Order → Service Appointment → Mobile App
```

- Work Type on the Work Order determines which DC flows are available
- Technician sees DC flows on the Service Appointment in the Field Service Mobile app

### Step 5: Deploy as Metadata

```
force-app/main/default/flows/Equipment_Inspection.flow-meta.xml
```

Standard flow metadata deployment:

```bash
sf project deploy start --source-dir force-app/main/default/flows --target-org myOrg
```

### Assignment Summary

| Level | What Happens |
|---|---|
| Flow metadata | Created/deployed like any flow |
| Work Type | DC flows assigned and ordered |
| Work Order | Inherits DC flows from its Work Type |
| Service Appointment | Technician accesses DC flows on mobile |

---

## Custom DC Components

You can build custom LWC components for use within Data Capture Flows.

### Requirements

- Target: `lightning__FlowScreen` in `.js-meta.xml`
- Must handle offline patterns (use LDS, not Apex)
- Keep lightweight and mobile-optimized
- Expose `@api` properties for flow input/output

### Meta XML

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
            <property name="label" type="String" label="Label" />
            <property name="value" type="String" label="Value" role="outputOnly" />
        </targetConfig>
    </targetConfigs>
</LightningComponentBundle>
```

### Best Practices

- Test on physical devices in airplane mode
- Minimize JavaScript bundle size
- Avoid imperative Apex calls
- Use `lightning-record-edit-form` where possible for offline support
