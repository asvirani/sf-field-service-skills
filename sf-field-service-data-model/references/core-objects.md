# Core FSL Objects — Field Reference

---

## WorkOrder

**API Name:** `WorkOrder`
**Description:** Represents a job or task to be performed, typically at a customer site. The primary record driving field service work.

### Key Fields

| API Name | Type | Description |
|----------|------|-------------|
| `Id` | ID | Record ID |
| `WorkOrderNumber` | AutoNumber | System-generated unique number |
| `Subject` | Text(255) | Brief summary of the work |
| `Description` | LongTextArea | Detailed description of the work |
| `Status` | Picklist | Current status (New, In Progress, Completed, Closed, Canceled, Cannot Complete) |
| `Priority` | Picklist | Priority level (Low, Medium, High, Critical) |
| `AccountId` | Lookup(Account) | Customer account |
| `ContactId` | Lookup(Contact) | Customer contact |
| `AssetId` | Lookup(Asset) | Asset being serviced |
| `CaseId` | Lookup(Case) | Originating case |
| `ParentWorkOrderId` | Lookup(WorkOrder) | Parent WO for hierarchy |
| `RootWorkOrderId` | Lookup(WorkOrder) | Top-level WO in hierarchy (system-maintained) |
| `WorkTypeId` | Lookup(WorkType) | Work type template |
| `ServiceTerritoryId` | Lookup(ServiceTerritory) | Territory where work is performed |
| `LocationId` | Lookup(Location) | Location record |
| `Street` | TextArea | Street address |
| `City` | Text | City |
| `State` | Text | State/Province |
| `PostalCode` | Text | Postal/Zip code |
| `Country` | Text | Country |
| `StateCode` | Picklist | State code (if state/country picklists enabled) |
| `CountryCode` | Picklist | Country code (if state/country picklists enabled) |
| `Latitude` | Double | Geo latitude |
| `Longitude` | Double | Geo longitude |
| `StartDate` | DateTime | Planned start date |
| `EndDate` | DateTime | Planned end date |
| `Duration` | Double | Estimated duration value |
| `DurationType` | Picklist | Duration unit: `Hours`, `Minutes` |
| `MinimumCrewSize` | Integer | Minimum crew members required |
| `RecommendedCrewSize` | Integer | Recommended crew members |
| `IsClosed` | Boolean | True when Status is terminal (system-maintained) |
| `MaintenancePlanId` | Lookup(MaintenancePlan) | Generating maintenance plan |
| `SuggestedMaintenanceDate` | Date | Suggested date from maintenance plan |

### Status Picklist Values

| Value | IsClosed |
|-------|----------|
| New | false |
| In Progress | false |
| On Hold | false |
| Completed | true |
| Closed | true |
| Canceled | true |
| Cannot Complete | true |

### Child Relationships

| Child Object | Relationship Name | Field |
|-------------|-------------------|-------|
| WorkOrderLineItem | WorkOrderLineItems | `WorkOrderId` |
| ServiceAppointment | ServiceAppointments | `ParentRecordId` |
| SkillRequirement | SkillRequirements | `RelatedRecordId` |
| ProductRequired | ProductsRequired | `ParentRecordId` |
| ProductConsumed | ProductsConsumed | `WorkOrderId` |
| WorkOrder | ChildWorkOrders | `ParentWorkOrderId` |
| ResourcePreference | ResourcePreferences | `RelatedRecordId` |

---

## WorkOrderLineItem

**API Name:** `WorkOrderLineItem`
**Description:** Subtask within a Work Order. Supports its own hierarchy and can parent Service Appointments.

### Key Fields

| API Name | Type | Description |
|----------|------|-------------|
| `Id` | ID | Record ID |
| `LineItemNumber` | AutoNumber | System-generated number |
| `WorkOrderId` | Master-Detail(WorkOrder) | Parent Work Order |
| `ParentWorkOrderLineItemId` | Lookup(WorkOrderLineItem) | Parent line item for hierarchy |
| `RootWorkOrderLineItemId` | Lookup(WorkOrderLineItem) | Top-level line item (system-maintained) |
| `WorkTypeId` | Lookup(WorkType) | Work type template |
| `AssetId` | Lookup(Asset) | Asset being serviced |
| `Status` | Picklist | Current status |
| `Subject` | Text(255) | Brief summary |
| `Description` | LongTextArea | Detailed description |
| `Duration` | Double | Estimated duration value |
| `DurationType` | Picklist | Duration unit: `Hours`, `Minutes` |
| `Street` | TextArea | Street address |
| `City` | Text | City |
| `State` | Text | State/Province |
| `PostalCode` | Text | Postal/Zip code |
| `Country` | Text | Country |
| `Latitude` | Double | Geo latitude |
| `Longitude` | Double | Geo longitude |
| `StartDate` | DateTime | Planned start |
| `EndDate` | DateTime | Planned end |
| `Order` | Integer | Sort order within WO |

### Child Relationships

| Child Object | Relationship Name | Field |
|-------------|-------------------|-------|
| ServiceAppointment | ServiceAppointments | `ParentRecordId` |
| SkillRequirement | SkillRequirements | `RelatedRecordId` |
| ProductRequired | ProductsRequired | `ParentRecordId` |
| ProductConsumed | ProductsConsumed | `WorkOrderLineItemId` |

---

## ServiceAppointment

**API Name:** `ServiceAppointment`
**Description:** A scheduled time block for field service work. The core schedulable unit in FSL.

### Key Fields

| API Name | Type | Description |
|----------|------|-------------|
| `Id` | ID | Record ID |
| `AppointmentNumber` | AutoNumber | System-generated number |
| `ParentRecordId` | Lookup (Polymorphic) | Parent record — WorkOrder, WorkOrderLineItem, or custom object |
| `ParentRecordType` | Text | API name of the parent object type (read-only) |
| `Status` | Picklist | Current status value |
| `StatusCategory` | Picklist | Status category grouping (system-mapped) |
| `EarliestStartDate` | DateTime | Earliest the appointment can start |
| `DueDate` | DateTime | Latest the appointment must finish |
| `SchedStartTime` | DateTime | Scheduler-assigned start time |
| `SchedEndTime` | DateTime | Scheduler-assigned end time |
| `ArrivalWindowStartTime` | DateTime | Customer-facing arrival window start |
| `ArrivalWindowEndTime` | DateTime | Customer-facing arrival window end |
| `ActualStartTime` | DateTime | Actual start (set by mobile worker) |
| `ActualEndTime` | DateTime | Actual end (set by mobile worker) |
| `Duration` | Double | Estimated duration value |
| `DurationType` | Picklist | Duration unit: `Hours`, `Minutes` |
| `ServiceTerritoryId` | Lookup(ServiceTerritory) | Territory for this appointment |
| `AccountId` | Lookup(Account) | Customer account |
| `ContactId` | Lookup(Contact) | Customer contact |
| `Street` | TextArea | Street address |
| `City` | Text | City |
| `State` | Text | State/Province |
| `PostalCode` | Text | Postal/Zip code |
| `Country` | Text | Country |
| `Latitude` | Double | Geo latitude |
| `Longitude` | Double | Geo longitude |
| `WorkTypeId` | Lookup(WorkType) | Work type template |
| `FSL__Scheduling_Policy_Used__c` | Lookup(FSL__Scheduling_Policy__c) | Scheduling policy applied (managed) |
| `FSL__GanttColor__c` | Text | Hex color on the Gantt chart (managed) |
| `FSL__Auto_Schedule__c` | Checkbox | Whether to auto-schedule via optimization (managed) |
| `FSL__IsMultiDay__c` | Checkbox | Multi-day appointment flag (managed) |
| `FSL__Pinned__c` | Checkbox | Pinned on the Gantt (managed) |
| `FSL__InJeopardy__c` | Checkbox | In-jeopardy flag (managed) |
| `FSL__InternalSLRGeolocation__Latitude__s` | Double | Geocoded latitude (managed) |
| `FSL__InternalSLRGeolocation__Longitude__s` | Double | Geocoded longitude (managed) |
| `AdditionalInformation` | LongTextArea | Notes or additional info |
| `IsOffsiteAppointment` | Boolean | True if no travel required |

### Status Picklist Values

| Status Value | StatusCategory | Description |
|-------------|----------------|-------------|
| None | None | Default / unscheduled |
| Scheduled | Scheduled | Appointment is scheduled |
| Dispatched | Dispatched | Dispatched to resource |
| In Progress | InProgress | Work underway |
| Completed | Completed | Work finished |
| Cannot Complete | CannotComplete | Unable to finish |
| Canceled | Canceled | Appointment canceled |

### StatusCategory Values

`None`, `Scheduled`, `Dispatched`, `InProgress`, `Completed`, `CannotComplete`, `Canceled`

> **Note:** Custom Status values map to a StatusCategory. Always filter by `StatusCategory` in automation for forward-compatible logic.

### Child Relationships

| Child Object | Relationship Name | Field |
|-------------|-------------------|-------|
| AssignedResource | ServiceResources | `ServiceAppointmentId` |
| SkillRequirement | SkillRequirements | `RelatedRecordId` |
| ResourcePreference | ResourcePreferences | `RelatedRecordId` |

---

## AssignedResource

**API Name:** `AssignedResource`
**Description:** Junction between ServiceAppointment and ServiceResource. Represents who is assigned to perform the work.

### Key Fields

| API Name | Type | Description |
|----------|------|-------------|
| `Id` | ID | Record ID |
| `ServiceAppointmentId` | Master-Detail(ServiceAppointment) | The appointment |
| `ServiceResourceId` | Lookup(ServiceResource) | The assigned resource |
| `IsRequiredResource` | Boolean | Whether this resource is required (vs optional crew member) |
| `EstimatedTravelTime` | Double | Estimated travel time in minutes |
| `ActualTravelTime` | Double | Actual travel time in minutes |

### Notes

- Deleting the SA cascades deletes to AssignedResource (MD).
- One SA can have multiple AssignedResources (crew scheduling).

---

## ServiceResource

**API Name:** `ServiceResource`
**Description:** A person, crew, or asset that can be assigned to Service Appointments.

### Key Fields

| API Name | Type | Description |
|----------|------|-------------|
| `Id` | ID | Record ID |
| `Name` | Text | Resource display name |
| `RelatedRecordId` | Lookup(User) | The Salesforce User record |
| `ResourceType` | Picklist | `T` (Technician), `A` (Agent), `C` (Crew) |
| `IsActive` | Boolean | Whether the resource is active |
| `IsCapacityBased` | Boolean | Uses capacity-based scheduling |
| `IsOptimizationCapable` | Boolean | Included in optimization runs |
| `FSL__Efficiency__c` | Percent | Resource efficiency factor (managed) |
| `FSL__GanttLabel__c` | Text | Display label on Gantt (managed) |
| `AccountId` | Lookup(Account) | Contractor account (for contractor resources) |
| `LocationId` | Lookup(Location) | Home location |
| `Description` | LongTextArea | Description |

### ResourceType Values

| Value | Label |
|-------|-------|
| T | Technician |
| A | Agent |
| C | Crew |

### Child Relationships

| Child Object | Relationship Name | Field |
|-------------|-------------------|-------|
| ServiceTerritoryMember | ServiceTerritoryMembers | `ServiceResourceId` |
| ServiceResourceSkill | ServiceResourceSkills | `ServiceResourceId` |
| AssignedResource | AssignedResources | `ServiceResourceId` |
| ResourceAbsence | ResourceAbsences | `ResourceId` |
| ServiceCrewMember | ServiceCrewMembers | `ServiceResourceId` |
| Shift | Shifts | `ServiceResourceId` |

---

## ServiceTerritory

**API Name:** `ServiceTerritory`
**Description:** A geographic region where service is delivered. Supports hierarchy.

### Key Fields

| API Name | Type | Description |
|----------|------|-------------|
| `Id` | ID | Record ID |
| `Name` | Text | Territory name |
| `ParentTerritoryId` | Lookup(ServiceTerritory) | Parent territory for hierarchy |
| `TopLevelTerritoryId` | Lookup(ServiceTerritory) | Root territory (system-maintained) |
| `OperatingHoursId` | Lookup(OperatingHours) | Default operating hours |
| `IsActive` | Boolean | Whether the territory is active |
| `Street` | TextArea | Street address |
| `City` | Text | City |
| `State` | Text | State/Province |
| `PostalCode` | Text | Postal/Zip code |
| `Country` | Text | Country |
| `Latitude` | Double | Geo latitude |
| `Longitude` | Double | Geo longitude |
| `TypicalInTerritoryTravelTime` | Double | Typical travel time within territory (minutes) |

### Child Relationships

| Child Object | Relationship Name | Field |
|-------------|-------------------|-------|
| ServiceTerritoryMember | ServiceTerritoryMembers | `ServiceTerritoryId` |
| ServiceTerritory | ChildServiceTerritories | `ParentTerritoryId` |
| ServiceAppointment | ServiceAppointments | `ServiceTerritoryId` |
| WorkOrder | WorkOrders | `ServiceTerritoryId` |
| Shift | Shifts | `ServiceTerritoryId` |

---

## ServiceTerritoryMember

**API Name:** `ServiceTerritoryMember`
**Description:** Junction between ServiceResource and ServiceTerritory. Defines where a resource operates and their home base.

### Key Fields

| API Name | Type | Description |
|----------|------|-------------|
| `Id` | ID | Record ID |
| `ServiceResourceId` | Master-Detail(ServiceResource) | The resource |
| `ServiceTerritoryId` | Master-Detail(ServiceTerritory) | The territory |
| `TerritoryType` | Picklist | Membership type |
| `EffectiveStartDate` | DateTime | When membership begins |
| `EffectiveEndDate` | DateTime | When membership ends (null = indefinite) |
| `OperatingHoursId` | Lookup(OperatingHours) | Override operating hours for this member |
| `Street` | TextArea | Home base street address |
| `City` | Text | Home base city |
| `State` | Text | Home base state |
| `PostalCode` | Text | Home base postal code |
| `Country` | Text | Home base country |
| `Latitude` | Double | Home base latitude |
| `Longitude` | Double | Home base longitude |

### TerritoryType Values

| Value | Label | Description |
|-------|-------|-------------|
| P | Primary | Main territory. Resource must have exactly one. |
| S | Secondary | Additional territory. Resource can serve here. |
| R | Relocation | Temporary territory assignment. |

---

## OperatingHours

**API Name:** `OperatingHours`
**Description:** Named set of business hours. Referenced by Territories, STMs, and WorkTypes.

### Key Fields

| API Name | Type | Description |
|----------|------|-------------|
| `Id` | ID | Record ID |
| `Name` | Text | Operating hours name |
| `Description` | LongTextArea | Description |
| `TimeZone` | Picklist | IANA timezone identifier |

### Child Relationships

| Child Object | Field |
|-------------|-------|
| TimeSlot | `OperatingHoursId` |
| ServiceTerritory | `OperatingHoursId` |
| ServiceTerritoryMember | `OperatingHoursId` |
| WorkType | `OperatingHoursId` |

---

## TimeSlot

**API Name:** `TimeSlot`
**Description:** A time window within OperatingHours defining when work can be scheduled.

### Key Fields

| API Name | Type | Description |
|----------|------|-------------|
| `Id` | ID | Record ID |
| `OperatingHoursId` | Master-Detail(OperatingHours) | Parent operating hours |
| `DayOfWeek` | Picklist | Day: `Monday`–`Sunday` |
| `StartTime` | Time | Slot start time |
| `EndTime` | Time | Slot end time |
| `Type` | Picklist | `Normal` or `Extended` |
| `MaxAppointments` | Integer | Max appointments in this slot (capacity-based) |

---

## Skill

**API Name:** `Skill`
**Description:** A competency or certification (standard Salesforce object, shared with Omni-Channel).

### Key Fields

| API Name | Type | Description |
|----------|------|-------------|
| `Id` | ID | Record ID |
| `MasterLabel` | Text | Skill name |
| `DeveloperName` | Text | Unique API name |
| `Description` | LongTextArea | Description |

---

## SkillRequirement

**API Name:** `SkillRequirement`
**Description:** Defines a skill needed on a WorkOrder, WorkOrderLineItem, or ServiceAppointment.

### Key Fields

| API Name | Type | Description |
|----------|------|-------------|
| `Id` | ID | Record ID |
| `RelatedRecordId` | Lookup (Polymorphic) | Parent: WorkOrder, WorkOrderLineItem, or ServiceAppointment |
| `SkillId` | Lookup(Skill) | Required skill |
| `SkillLevel` | Double | Minimum skill level (0–99.99) |

---

## ServiceResourceSkill

**API Name:** `ServiceResourceSkill`
**Description:** A skill possessed by a Service Resource, with optional expiration.

### Key Fields

| API Name | Type | Description |
|----------|------|-------------|
| `Id` | ID | Record ID |
| `ServiceResourceId` | Master-Detail(ServiceResource) | The resource |
| `SkillId` | Lookup(Skill) | The skill |
| `SkillLevel` | Double | Proficiency level (0–99.99) |
| `EffectiveStartDate` | Date | When the skill becomes active |
| `EffectiveEndDate` | Date | When the skill expires (null = no expiry) |

---

## ServiceCrew

**API Name:** `ServiceCrew`
**Description:** A named group of Service Resources that work together.

### Key Fields

| API Name | Type | Description |
|----------|------|-------------|
| `Id` | ID | Record ID |
| `Name` | Text | Crew name |
| `CrewSize` | Integer | Number of members (system-calculated) |

### Child Relationships

| Child Object | Field |
|-------------|-------|
| ServiceCrewMember | `ServiceCrewId` |

---

## ServiceCrewMember

**API Name:** `ServiceCrewMember`
**Description:** Junction between ServiceCrew and ServiceResource.

### Key Fields

| API Name | Type | Description |
|----------|------|-------------|
| `Id` | ID | Record ID |
| `ServiceCrewId` | Master-Detail(ServiceCrew) | The crew |
| `ServiceResourceId` | Lookup(ServiceResource) | The resource |
| `StartDate` | DateTime | Membership start |
| `EndDate` | DateTime | Membership end |
| `IsLeader` | Boolean | Whether this member is the crew leader |

---

## ResourceAbsence

**API Name:** `ResourceAbsence`
**Description:** A period when a Service Resource is unavailable (vacation, training, break, etc.).

### Key Fields

| API Name | Type | Description |
|----------|------|-------------|
| `Id` | ID | Record ID |
| `ResourceId` | Lookup(ServiceResource) | The absent resource |
| `Start` | DateTime | Absence start |
| `End` | DateTime | Absence end |
| `Type` | Picklist | Absence type |
| `Description` | LongTextArea | Description |
| `FSL__Approved__c` | Checkbox | Whether the absence is approved (managed) |

### Type Picklist Values

`Vacation`, `Sick`, `Training`, `Meeting`, `Break`, `Other`

> Only approved absences (`FSL__Approved__c = true`) block scheduling in the optimizer.

---

## Asset

**API Name:** `Asset`
**Description:** A product or item owned/used by a customer. Central to maintenance and service history tracking.

### Key Fields

| API Name | Type | Description |
|----------|------|-------------|
| `Id` | ID | Record ID |
| `Name` | Text | Asset name |
| `AccountId` | Lookup(Account) | Owning account |
| `ContactId` | Lookup(Contact) | Owning contact |
| `ParentId` | Lookup(Asset) | Parent asset for hierarchy |
| `RootAssetId` | Lookup(Asset) | Top-level asset (system-maintained) |
| `Product2Id` | Lookup(Product2) | Product definition |
| `LocationId` | Lookup(Location) | Physical location |
| `Status` | Picklist | Asset status |
| `InstallDate` | Date | Installation date |
| `SerialNumber` | Text | Serial number |
| `Quantity` | Double | Quantity |
| `Price` | Currency | Price |
| `Description` | LongTextArea | Description |

### Status Picklist Values

`Shipped`, `Installed`, `Registered`, `Obsolete`, `Purchased`

### Child Relationships

| Child Object | Field |
|-------------|-------|
| Asset | `ParentId` |
| WorkOrder | `AssetId` |
| WorkOrderLineItem | `AssetId` |
| MaintenanceAsset | `AssetId` |

---

## MaintenancePlan

**API Name:** `MaintenancePlan`
**Description:** Defines a recurring maintenance schedule that auto-generates Work Orders.

### Key Fields

| API Name | Type | Description |
|----------|------|-------------|
| `Id` | ID | Record ID |
| `Title` | Text | Plan title |
| `StartDate` | Date | Plan start date |
| `EndDate` | Date | Plan end date (null = indefinite) |
| `NextSuggestedMaintenanceDate` | Date | Next date WOs will be generated |
| `Frequency` | Integer | Frequency value |
| `FrequencyType` | Picklist | `Days`, `Weeks`, `Months`, `Years` |
| `GenerationTimeframe` | Integer | How far in advance to generate WOs |
| `GenerationTimeframeType` | Picklist | `Days`, `Weeks`, `Months`, `Years` |
| `WorkTypeId` | Lookup(WorkType) | Default work type for generated WOs |
| `AccountId` | Lookup(Account) | Account |
| `DoesAutoGenerateWorkOrders` | Boolean | Auto-generate WOs on batch run |
| `DoesGenerateUponCompletion` | Boolean | Generate next WO when current completes |
| `SvcApptGenerationMethod` | Picklist | SA generation: `None`, `SvcApptPerWO`, `SvcApptPerAsset` |
| `MaintenanceWindowStartDays` | Integer | Days before suggested date for SA window |
| `MaintenanceWindowEndDays` | Integer | Days after suggested date for SA window |

### Child Relationships

| Child Object | Field |
|-------------|-------|
| MaintenanceAsset | `MaintenancePlanId` |
| WorkOrder | `MaintenancePlanId` |

---

## MaintenanceAsset

**API Name:** `MaintenanceAsset`
**Description:** Junction between MaintenancePlan and Asset. Defines which assets are covered.

### Key Fields

| API Name | Type | Description |
|----------|------|-------------|
| `Id` | ID | Record ID |
| `MaintenancePlanId` | Master-Detail(MaintenancePlan) | Parent plan |
| `AssetId` | Lookup(Asset) | Covered asset |
| `WorkTypeId` | Lookup(WorkType) | Override work type for this asset |
| `NextSuggestedMaintenanceDate` | Date | Asset-specific next date |

---

## ProductRequired

**API Name:** `ProductRequired`
**Description:** Parts or products needed to complete a Work Order or line item.

### Key Fields

| API Name | Type | Description |
|----------|------|-------------|
| `Id` | ID | Record ID |
| `ParentRecordId` | Lookup (Polymorphic) | Parent: WorkOrder or WorkOrderLineItem |
| `Product2Id` | Lookup(Product2) | Required product |
| `QuantityRequired` | Double | Quantity needed |
| `IsGroupMember` | Boolean | Part of a product group |

---

## ProductConsumed

**API Name:** `ProductConsumed`
**Description:** Products actually used when completing work.

### Key Fields

| API Name | Type | Description |
|----------|------|-------------|
| `Id` | ID | Record ID |
| `WorkOrderId` | Lookup(WorkOrder) | Parent Work Order |
| `WorkOrderLineItemId` | Lookup(WorkOrderLineItem) | Parent line item |
| `Product2Id` | Lookup(Product2) | Consumed product |
| `QuantityConsumed` | Double | Quantity used |
| `UnitPrice` | Currency | Price per unit |
| `Description` | LongTextArea | Description |

---

## ResourcePreference

**API Name:** `ResourcePreference`
**Description:** Defines preferred, required, or excluded resources for an Account, Work Order, or Service Appointment.

### Key Fields

| API Name | Type | Description |
|----------|------|-------------|
| `Id` | ID | Record ID |
| `RelatedRecordId` | Lookup (Polymorphic) | Parent: Account, WorkOrder, WorkOrderLineItem, or ServiceAppointment |
| `ServiceResourceId` | Lookup(ServiceResource) | The resource |
| `PreferenceType` | Picklist | `Preferred`, `Required`, `Excluded` |

### PreferenceType Behavior

| Value | Scheduling Effect |
|-------|-------------------|
| Preferred | Scheduler favors this resource (soft constraint) |
| Required | Only this resource can be assigned (hard constraint) |
| Excluded | This resource is never assigned (hard constraint) |

---

## WorkType

**API Name:** `WorkType`
**Description:** Template defining default values for Work Orders and Service Appointments.

### Key Fields

| API Name | Type | Description |
|----------|------|-------------|
| `Id` | ID | Record ID |
| `Name` | Text | Work type name |
| `EstimatedDuration` | Double | Default duration value |
| `DurationType` | Picklist | `Hours` or `Minutes` |
| `MinimumCrewSize` | Integer | Default minimum crew |
| `RecommendedCrewSize` | Integer | Default recommended crew |
| `BlockTimeBeforeAppointment` | Integer | Buffer time before SA (minutes) |
| `BlockTimeAfterAppointment` | Integer | Buffer time after SA (minutes) |
| `TimeframeStart` | Double | Default SA window start (hours from creation) |
| `TimeframeEnd` | Double | Default SA window end (hours from creation) |
| `OperatingHoursId` | Lookup(OperatingHours) | Operating hours for this work type |
| `ShouldAutoCreateSvcAppt` | Boolean | Auto-create SA when WO uses this type |
| `Description` | LongTextArea | Description |

### Child Relationships

| Child Object | Field |
|-------------|-------|
| WorkOrder | `WorkTypeId` |
| WorkOrderLineItem | `WorkTypeId` |
| ServiceAppointment | `WorkTypeId` |
| WorkTypeGroupMember | `WorkTypeId` |
| SkillRequirement | via WorkType skill assignment |

---

## WorkTypeGroup

**API Name:** `WorkTypeGroup`
**Description:** Groups WorkTypes for scheduling scenarios (e.g., appointment booking).

### Key Fields

| API Name | Type | Description |
|----------|------|-------------|
| `Id` | ID | Record ID |
| `Name` | Text | Group name |
| `GroupType` | Picklist | `Default`, `Capacity` |
| `Description` | LongTextArea | Description |
| `IsActive` | Boolean | Whether the group is active |
| `AdditionalInformation` | LongTextArea | Additional info |

---

## WorkTypeGroupMember

**API Name:** `WorkTypeGroupMember`
**Description:** Junction between WorkTypeGroup and WorkType.

### Key Fields

| API Name | Type | Description |
|----------|------|-------------|
| `Id` | ID | Record ID |
| `WorkTypeGroupId` | Master-Detail(WorkTypeGroup) | Parent group |
| `WorkTypeId` | Lookup(WorkType) | Member work type |

---

## Shift

**API Name:** `Shift`
**Description:** A defined work period for a resource in a territory.

### Key Fields

| API Name | Type | Description |
|----------|------|-------------|
| `Id` | ID | Record ID |
| `ServiceResourceId` | Lookup(ServiceResource) | Assigned resource |
| `ServiceTerritoryId` | Lookup(ServiceTerritory) | Territory for the shift |
| `StartTime` | DateTime | Shift start |
| `EndTime` | DateTime | Shift end |
| `Status` | Picklist | Shift status |
| `Label` | Text | Display label |
| `TimeSlotType` | Picklist | `Normal`, `Extended` |
| `RecurrencePattern` | Text | Recurrence definition |
