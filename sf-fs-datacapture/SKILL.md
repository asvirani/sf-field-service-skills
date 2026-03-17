---
name: sf-fs-datacapture
description: >
  Creates Field Service data capture form flows from images or PDFs of existing
  paper/digital forms. Generates mobile-optimized DataCaptureFlow XML with
  Field Service DC components, voice-to-form (IsLlmTargetable), offline support,
  and deploys to Salesforce orgs. Use when building Field Service data capture
  forms, inspection checklists, safety forms, or converting paper forms to
  digital flows for field technicians.
---

# sf-fs-datacapture: Field Service Data Capture Form Builder

Build mobile-optimized data capture flows for Salesforce Field Service from images, PDFs, or descriptions of existing forms. Generates deployable Flow metadata XML with voice-to-form support.

## Quick Reference

| Setting | Value |
|---------|-------|
| processType | `DataCaptureFlow` |
| environments | `Offline` |
| Voice-to-Form | `customProperties > IsLlmTargetable > {"value":"true"}` |
| API Version | 65.0+ |
| Naming | `DCF_[Context]_[FormName]` |
| Input vars | `parentRecordId`, `parentObjectType`, `recordId` |
| Deploy path | `force-app/main/default/flows/` |

---

## Phase 1: Form Analysis (Image/PDF Intake)

When the user provides an image or PDF of a form:

1. **Examine every field** — labels, input types, groupings, sections
2. **Classify each field** using the DC component mapping below
3. **Identify sections** — group related fields into logical screens (5-7 fields max)
4. **Note conditional logic** — fields that depend on toggle/answer states
6. **Map fields to standard related data** — see Standard Field Mapping below; flag any form field that naturally fits data we already have from the Work Order

### Standard Field Mapping (Auto-population Candidates)

**Goal:** Reduce technician data entry. If a form field maps to standard Salesforce or Field Service data related to the Work Order, auto-populate it from a prior Get Records step and set the field’s **default value** to that variable. The technician can still view and edit.

After classifying fields, identify which map to the table below. Then **prompt the user**:

> "The following **N** fields appear to map to standard data related to the Work Order: **[list labels, e.g. Customer Name, Contact First Name, Contact Last Name, Asset Name]**. Should we auto-populate these from the Work Order context (technician can still edit)? **Yes / No**"

If **Yes**, add the corresponding Get Records step(s) and set each of those screen fields’ default value to the appropriate element reference (e.g. `Get_Account.Name`, `Get_Contact.FirstName`).

| Form label (examples) | Standard object | Field(s) | Get step | Filter |
|------------------------|-----------------|----------|----------|--------|
| Customer Name, Account Name, Account, Organization (account) | Account | Name | Get_Account | Id = Get_Work_Order.AccountId |
| Contact Name, Contact First Name, Contact Last Name, Customer Contact | Contact | FirstName, LastName | Get_Contact | Id = Get_Work_Order.ContactId |
| Asset Name, Equipment, Asset, Serial Number (asset) | Asset | Name, SerialNumber | Get_Asset | Id = Get_Work_Order.AssetId |
| Work Order #, WO Number, Reference # (from WO) | WorkOrder | WorkOrderNumber, Description | Get_Work_Order | Already have (parentRecordId) |
| Service Appointment, Appointment Time | ServiceAppointment | AppointmentNumber, SchedStartTime | Get_SA (optional) | ParentRecordId or WO Id |
| Address, Street, City, State, Postal Code (location) | Account / WorkOrder | BillingStreet, etc. or WorkOrder.Address | Get_Account or Get_Work_Order | — |

- **Get_Work_Order** is always first (by `parentRecordId`). Add **Get_Account** and **Get_Contact** when the form has account/contact-like fields. Add **Get_Asset** only when the form has asset/equipment fields.
- Chain: Start → Get_Work_Order → Get_Account → Get_Contact → (Get_Asset if needed) → first screen. Each Get uses the previous step’s output (e.g. Get_Account filters on `Get_Work_Order.AccountId`).
- For each auto-populated field, add an **inputParameter** `value` with `<elementReference>Get_Account.Name</elementReference>` (or the correct reference). Technician sees the value pre-filled and can change it.

### Field Type Mapping (Document → DC Component)

Data capture flows use **Field Service DC components**, NOT standard flow field types.

| Document Field | extensionName | fieldType | Notes |
|----------------|---------------|-----------|-------|
| Text box (any length) | `runtime_service_fieldservice:dcTextInput` | `ComponentInstance` | Handles both short and long text |
| Dropdown / picklist | `runtime_service_fieldservice:dcPicklist` | `ComponentChoice` | Uses `choiceReferences` |
| Checkbox group (multi) | `runtime_service_fieldservice:dcCbGroup` | `ComponentMultiChoice` | Uses `choiceReferences` |
| Toggle / Yes-No | `runtime_service_fieldservice:dcToggle` | `ComponentInstance` | Boolean toggle, ref via `.isActive` |
| Photo / file upload | _(use DisplayText reminder)_ | `DisplayText` | **No inline upload in DataCaptureFlow** — neither `dcUpImage` nor `forceContent:fileUpload` are supported. Use DisplayText to remind tech to attach photos via WO after form completion |
| Signature | `runtime_service_fieldservice:dcSignature` | `ComponentInstance` | Pass `parentRecordId` input param. **Unverified on mobile — test before relying on this** |
| Section header | _(none)_ | `DisplayText` | HTML-formatted `fieldText` |
| Instructions / read-only | _(none)_ | `DisplayText` | Informational text |

> **Known Limitation — No file/photo upload in DataCaptureFlow.**
> - `runtime_service_fieldservice:dcUpImage` — NOT a real component. Causes: `"screen field type undefined used for field undefined not yet supported"`.
> - `forceContent:fileUpload` — Rejected at deploy time: `"doesn't implement any marker interface that's supported for flows of type DataCaptureFlow"`.
> - **Workaround:** Use a `DisplayText` field to instruct technicians to attach photos to the Work Order after form completion (see Photo Capture pattern below). This is the pattern used by all working deployed DC flows.

### DC Text Input Pattern (most common field)

```xml
<fields>
    <name>{{Field_Name}}</name>
    <extensionName>runtime_service_fieldservice:dcTextInput</extensionName>
    <fieldType>ComponentInstance</fieldType>
    <inputParameters>
        <name>label</name>
        <value>
            <stringValue>{{Field Label}}</stringValue>
        </value>
    </inputParameters>
    <inputsOnNextNavToAssocScrn>UseStoredValues</inputsOnNextNavToAssocScrn>
    <isRequired>{{true|false}}</isRequired>
    <storeOutputAutomatically>true</storeOutputAutomatically>
    <styleProperties>
        <verticalAlignment>
            <stringValue>top</stringValue>
        </verticalAlignment>
        <width>
            <stringValue>12</stringValue>
        </width>
    </styleProperties>
</fields>
```

For required fields, also add the `required` input parameter:
```xml
<inputParameters>
    <name>required</name>
    <value>
        <booleanValue>true</booleanValue>
    </value>
</inputParameters>
```

**Default value (auto-population from standard related data):** When the field maps to standard data and the user confirmed auto-population, add a `value` inputParameter so the technician sees it pre-filled and can edit:

```xml
<inputParameters>
    <name>value</name>
    <value>
        <elementReference>Get_Account.Name</elementReference>
    </value>
</inputParameters>
```

Use the appropriate reference: `Get_Account.Name`, `Get_Contact.FirstName`, `Get_Contact.LastName`, `Get_Asset.Name`, `Get_Asset.SerialNumber`, `Get_Work_Order.WorkOrderNumber`, etc. If the runtime in a given org does not accept `value` and shows an error, fall back to showing that data only in the DisplayText context block and leave the input without a default.

### DC Picklist Pattern (single-select dropdown)

```xml
<fields>
    <name>{{Field_Name}}</name>
    <choiceReferences>{{Choice_1}}</choiceReferences>
    <choiceReferences>{{Choice_2}}</choiceReferences>
    <extensionName>runtime_service_fieldservice:dcPicklist</extensionName>
    <fieldText>{{Field Label}}</fieldText>
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

### DC Checkbox Group Pattern (multi-select)

```xml
<fields>
    <name>{{Field_Name}}</name>
    <choiceReferences>{{Choice_1}}</choiceReferences>
    <choiceReferences>{{Choice_2}}</choiceReferences>
    <extensionName>runtime_service_fieldservice:dcCbGroup</extensionName>
    <fieldText>{{Field Label}} (Select All That Apply)</fieldText>
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

### DC Toggle Pattern (boolean with conditional visibility)

```xml
<fields>
    <name>{{Toggle_Name}}</name>
    <extensionName>runtime_service_fieldservice:dcToggle</extensionName>
    <fieldType>ComponentInstance</fieldType>
    <inputParameters>
        <name>label</name>
        <value><stringValue>{{Toggle Question}}</stringValue></value>
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

Show/hide a field based on toggle state:
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

### Photo Capture (DisplayText Reminder Pattern)

> **No inline photo/file upload in DataCaptureFlow.**
> - `dcUpImage` — not a real component, causes "screen field type undefined" error at runtime.
> - `forceContent:fileUpload` — rejected at deploy: "doesn't implement marker interface for DataCaptureFlow".
> - Use this DisplayText pattern instead (matches all working deployed DC flows):

```xml
<fields>
    <name>Photo_Instructions</name>
    <fieldText>&lt;p&gt;&lt;b&gt;Reminder:&lt;/b&gt; Please use the device camera to attach photos to the work order after completing this form.&lt;/p&gt;</fieldText>
    <fieldType>DisplayText</fieldType>
    <styleProperties>
        <verticalAlignment><stringValue>top</stringValue></verticalAlignment>
        <width><stringValue>12</stringValue></width>
    </styleProperties>
</fields>
```

### DC Signature Pattern

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

---

## Phase 2: Flow Design

1. **Confirm auto-population** — If Phase 1 identified standard-field mappings, you should have already prompted the user and added Get_Account / Get_Contact / Get_Asset as needed. Ensure recordLookups are chained before the first screen and that each auto-populated field has its `value` inputParameter set.
2. **Screen layout** — Apply the rules below.

### Screen Organization for Mobile

1. **Max 5-7 fields per screen** — avoid scrolling on phones
2. **Group by section** — one section of the form = one screen
3. **Required fields at top** of each screen
4. **Short, clear labels** — technicians glance quickly
5. **Use `width: 6`** for side-by-side fields (e.g., Floor + Room Number)
6. **Use `width: 12`** for full-width fields (default)

### Screen Navigation

| Screen Position | allowBack | allowFinish | allowPause |
|-----------------|-----------|-------------|------------|
| First screen | `true` | `true` | `true` |
| Middle screens | `true` | `true` | `true` |
| Final screen | `true` | `true` | `true` |

### Naming Conventions

| Element | Pattern | Example |
|---------|---------|---------|
| Flow API name | `DCF_[Context]_[Name]` | `DCF_Safety_Hazard_Check` |
| Screen | `[Section]_Screen` | `Demarc_Location_Screen` |
| Text input | `[FieldName]` | `Circuit_ID`, `Building_Name` |
| Toggle | `[Toggle_Name]` | `Has_Blockers`, `Tests_Performed` |
| Choice | `[Category]_[Value]` or `Choice_[Value]` | `Cond_Good`, `Choice_High` |
| Display text | `[Purpose]` | `Display_WO_Context`, `Section_PPE` |

---

## Phase 3: XML Generation

### Required Flow Structure

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Flow xmlns="http://soap.sforce.com/2006/04/metadata">
    <areMetricsLoggedToDataCloud>false</areMetricsLoggedToDataCloud>

    <!-- choices (alphabetical) -->

    <customProperties>
        <name>IsLlmTargetable</name>
        <value>
            <stringValue>{"value":"true"}</stringValue>
        </value>
    </customProperties>

    <description>{{DESCRIPTION}}</description>
    <environments>Offline</environments>
    <interviewLabel>{{LABEL}} {!$Flow.CurrentDateTime}</interviewLabel>
    <label>{{LABEL}}</label>

    <processMetadataValues>
        <name>BuilderType</name>
        <value><stringValue>LightningFlowBuilder</stringValue></value>
    </processMetadataValues>
    <processMetadataValues>
        <name>CanvasMode</name>
        <value><stringValue>AUTO_LAYOUT_CANVAS</stringValue></value>
    </processMetadataValues>
    <processMetadataValues>
        <name>OriginBuilderType</name>
        <value><stringValue>LightningFlowBuilder</stringValue></value>
    </processMetadataValues>

    <processType>DataCaptureFlow</processType>

    <recordLookups>
        <name>Get_Work_Order</name>
        <label>Get Work Order</label>
        <locationX>0</locationX>
        <locationY>0</locationY>
        <assignNullValuesIfNoRecordsFound>false</assignNullValuesIfNoRecordsFound>
        <connector>
            <targetReference>{{FIRST_SCREEN}}</targetReference>
        </connector>
        <filterLogic>and</filterLogic>
        <filters>
            <field>Id</field>
            <operator>EqualTo</operator>
            <value>
                <elementReference>parentRecordId</elementReference>
            </value>
        </filters>
        <getFirstRecordOnly>true</getFirstRecordOnly>
        <object>WorkOrder</object>
        <storeOutputAutomatically>true</storeOutputAutomatically>
    </recordLookups>

    <!-- When auto-populating standard fields: add Get_Account, Get_Contact, (Get_Asset). Set Get_Work_Order.connector to Get_Account; Get_Account.connector to Get_Contact; Get_Contact.connector (and Get_Asset if used) to {{FIRST_SCREEN}}. -->

    <!-- screens -->

    <start>
        <locationX>0</locationX>
        <locationY>0</locationY>
        <connector>
            <targetReference>Get_Work_Order</targetReference>
        </connector>
    </start>

    <status>Draft</status>

    <variables>
        <name>parentObjectType</name>
        <dataType>String</dataType>
        <isCollection>false</isCollection>
        <isInput>true</isInput>
        <isOutput>false</isOutput>
    </variables>
    <variables>
        <name>parentRecordId</name>
        <dataType>String</dataType>
        <isCollection>false</isCollection>
        <isInput>true</isInput>
        <isOutput>false</isOutput>
    </variables>
    <variables>
        <name>recordId</name>
        <dataType>String</dataType>
        <isCollection>false</isCollection>
        <isInput>true</isInput>
        <isOutput>false</isOutput>
    </variables>
</Flow>
```

### Work Order Context Display (first field on first screen)

Always show Work Order context. When Get_Account and/or Get_Contact are used (auto-population), include them so the technician sees the related context even if they don’t edit those fields:

```xml
<fields>
    <name>Display_WO_Context</name>
    <fieldText>&lt;p&gt;&lt;b&gt;Work Order:&lt;/b&gt; {!Get_Work_Order.WorkOrderNumber}&lt;/p&gt;&lt;p&gt;&lt;b&gt;Subject:&lt;/b&gt; {!Get_Work_Order.Subject}&lt;/p&gt;&lt;p&gt;&lt;b&gt;Account:&lt;/b&gt; {!Get_Account.Name}&lt;/p&gt;&lt;p&gt;&lt;b&gt;Contact:&lt;/b&gt; {!Get_Contact.FirstName} {!Get_Contact.LastName}&lt;/p&gt;</fieldText>
    <fieldType>DisplayText</fieldType>
    <styleProperties>
        <verticalAlignment><stringValue>top</stringValue></verticalAlignment>
        <width><stringValue>12</stringValue></width>
    </styleProperties>
</fields>
```

If Get_Asset is used, add: `&lt;p&gt;&lt;b&gt;Asset:&lt;/b&gt; {!Get_Asset.Name}&lt;/p&gt;`. Omit Account/Contact/Asset lines when that Get step is not present.

### XML Element Ordering (Alphabetical — MANDATORY)

```
areMetricsLoggedToDataCloud → choices → customProperties → description →
environments → interviewLabel → label → processMetadataValues →
processType → recordLookups → screens → start → status → variables
```

See [assets/data-capture-flow-template.xml](assets/data-capture-flow-template.xml) for the full base template.

---

## Phase 4: Deployment

```bash
mkdir -p force-app/main/default/flows
# Write: force-app/main/default/flows/DCF_[Name].flow-meta.xml
```

Use the **sf-deploy** skill:
1. `"Deploy flow with --dry-run"` — validate first
2. `"Proceed with actual deployment"` — deploys as Draft
3. Change `<status>Draft</status>` → `<status>Active</status>`, redeploy to activate

---

## Phase 5: Verification

- [ ] All screens render on Field Service mobile app (no "screen field type undefined" errors)
- [ ] Voice-to-form works (mic icon appears, dictation maps to fields)
- [ ] Toggle-based conditional fields show/hide correctly
- [ ] Field values persist when navigating between screens
- [ ] Photo reminder DisplayText renders (no inline upload in DataCaptureFlow — neither `dcUpImage` nor `forceContent:fileUpload` work)
- [ ] Signature pad accepts input (`dcSignature` — test on actual mobile before relying on this)
- [ ] Flow works offline (airplane mode test)
- [ ] Work Order context displays correctly on first screen
- [ ] Auto-populated standard fields (when used) show default values; technician can edit
- [ ] Only verified DC components used: `dcTextInput`, `dcPicklist`, `dcCbGroup`, `dcToggle`, `DisplayText`

---

## Cross-Skill Integration

| From | To | When |
|------|-----|------|
| sf-metadata → here | Create custom objects/fields the form writes to |
| sf-flow → here | General flow patterns, subflow reuse |
| here → sf-deploy | Deploy form flow to target org |
| here → sf-data | Create test Work Orders / Service Appointments |

---

## Additional Resources

- [Data Capture Flow Template](assets/data-capture-flow-template.xml) — Base XML template
- [Field Type Mapping Reference](references/field-type-mapping.md) — All DC component patterns
- [Mobile UX Guide](references/mobile-ux-guide.md) — Field Service mobile best practices
- [Example: Safety Hazard Check](references/example-safety-hazard-check.xml) — Multi-select checklists, photo upload
- [Example: Customer Interaction](references/example-customer-interaction.xml) — Signature capture, satisfaction survey
- [Example: NAS Demarc Validation](references/example-nas-demarc-validation.xml) — Multi-screen, conditional visibility
