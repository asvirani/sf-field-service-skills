# Work Rules Reference

Work rules are pass/fail filters that eliminate unqualified resources or invalid time slots during scheduling. They are evaluated before service objectives score the remaining candidates.

## Summary Table

| # | Work Rule Type | RecordType DeveloperName | Purpose | Scope |
|---|---------------|-------------------------|---------|-------|
| 1 | Match Boolean | `FSL__Match_Boolean__c` | Check Boolean field on ServiceResource | Resource |
| 2 | Match Fields | `FSL__Match_Fields__c` | Compare field on SA to field on SR | Resource |
| 3 | Match Skills | `FSL__Match_Skills__c` | Enforce SkillRequirement vs ServiceResourceSkill | Resource |
| 4 | Match Territory | `FSL__Match_Territory__c` | Resource must belong to SA's territory | Resource |
| 5 | Match Crew Size | `FSL__Match_Crew_Size__c` | Ensure minimum crew members available | Resource |
| 6 | Count Rule | `FSL__Count_Rule__c` | Limit SAs per resource per time period | Time Slot |
| 7 | Working Territories | `FSL__Working_Territories__c` | Restrict to resource's working territory by day/time | Time Slot |
| 8 | Excluded Resources | `FSL__Excluded_Resources__c` | Exclude resources via ResourcePreference | Resource |
| 9 | Required Resources | `FSL__Required_Resources__c` | Only allow preferred/required resources | Resource |
| 10 | SA Bundling | `FSL__Appointment_Bundling__c` | Geographic bundling constraints | Time Slot |

---

## 1. Match Boolean

**RecordType:** `FSL__Match_Boolean__c`

**Behavior:** Checks a Boolean (checkbox) field on `ServiceResource`. If the field value does not match the expected value, the resource is disqualified.

### Key Configuration Fields

| Field | API Name | Description |
|-------|----------|-------------|
| Field | `FSL__Field__c` | API name of the Boolean field on ServiceResource |
| Boolean Operator | `FSL__Boolean_Operator__c` | Expected value: `True` or `False` |

### Example Use Case

Filter out inactive resources. Set `FSL__Field__c` = `IsActive` and `FSL__Boolean_Operator__c` = `True`. Only active resources pass.

### Configuration Tips

- The field must exist on the `ServiceResource` object and be of type Boolean/Checkbox.
- Use for simple on/off filtering: certified, available, has vehicle, etc.
- Multiple Match Boolean rules are AND-ed together — resource must pass all of them.
- Custom checkbox fields work. Use `Namespace__Field_Name__c` format for managed fields.

---

## 2. Match Fields

**RecordType:** `FSL__Match_Fields__c`

**Behavior:** Compares a field value on `ServiceAppointment` (or its parent `WorkOrder`) to a field on `ServiceResource`. If the values don't match, the resource is disqualified.

### Key Configuration Fields

| Field | API Name | Description |
|-------|----------|-------------|
| Service Appointment Field | `FSL__Service_Appointment_Field__c` | Field API name on SA or WO |
| Service Resource Field | `FSL__Service_Resource_Field__c` | Field API name on ServiceResource |
| Object | `FSL__Object__c` | Source object: `ServiceAppointment` or `WorkOrder` |

### Example Use Case

Match work type by region. SA has `Region__c = "West"`, SR has `Region__c = "West"`. Only resources with matching region pass.

### Configuration Tips

- Field data types must be compatible (Text to Text, Picklist to Picklist).
- Null values on both sides are treated as a match.
- Null on one side and a value on the other is a mismatch (fails).
- For picklist fields, the string values are compared directly.
- You can reference fields on WorkOrder by setting Object to `WorkOrder` — the scheduler traverses from SA to its parent WO.

---

## 3. Match Skills

**RecordType:** `FSL__Match_Skills__c`

**Behavior:** Compares `SkillRequirement` records on the SA's parent `WorkOrder` (or `WorkType`) against `ServiceResourceSkill` records on the resource. Resource must have all required skills at or above the required skill level.

### Key Configuration Fields

| Field | API Name | Description |
|-------|----------|-------------|
| Enable Skill Level | `FSL__Enable_Skill_Level__c` | If true, enforces `SkillLevel` minimums |

### Example Use Case

Work Order requires "Electrical Certification" at Skill Level 5. Only resources with `ServiceResourceSkill` for that Skill where `SkillLevel >= 5` pass.

### Configuration Tips

- Skills are defined on the `Skill` object. Requirements live on `SkillRequirement` (linked to WO or WorkType).
- Resource skills are on `ServiceResourceSkill` with `EffectiveStartDate` and `EffectiveEndDate` — expired skills are ignored.
- Skill Level ranges from 0 to any positive number (typically 0-10 or 0-100).
- If `Enable_Skill_Level__c` is false, only skill presence is checked, not level.
- This is one of the most commonly used work rules. Almost every FSL implementation uses it.
- Skills can also come from `WorkType.SkillRequirement` if the SA inherits from WorkType.

---

## 4. Match Territory

**RecordType:** `FSL__Match_Territory__c`

**Behavior:** Resource must be a member (`ServiceTerritoryMember`) of the `ServiceTerritory` assigned to the SA. Configurable for which membership types qualify.

### Key Configuration Fields

| Field | API Name | Description |
|-------|----------|-------------|
| Include Primary | `FSL__Match_Territory_Primary__c` | Include Primary territory members |
| Include Secondary | `FSL__Match_Territory_Secondary__c` | Include Secondary territory members |
| Include Relocation | `FSL__Match_Territory_Relocation__c` | Include Relocation territory members |

### Example Use Case

SA is in "San Francisco" territory. Only resources who are Primary or Secondary members of "San Francisco" pass. Relocation members excluded to keep resources local.

### Configuration Tips

- If all three are unchecked, no resources pass — always enable at least one.
- **Primary**: Resource's home territory. Use for strong territory alignment.
- **Secondary**: Resource can work here but it's not their home. Good for overflow.
- **Relocation**: Resource is temporarily assigned. Use for seasonal or project-based work.
- `ServiceTerritoryMember` records have `EffectiveStartDate` and `EffectiveEndDate` — membership must be active at the time of the SA.
- This rule is almost always used. Without it, the scheduler considers all resources across all territories.

---

## 5. Match Crew Size

**RecordType:** `FSL__Match_Crew_Size__c`

**Behavior:** Ensures enough crew members are available to meet the `MinimumCrewSize` on the ServiceAppointment. Used in crew scheduling scenarios.

### Key Configuration Fields

No additional configuration fields beyond the standard work rule fields.

### Example Use Case

A heavy equipment installation requires 3 technicians. SA has `MinimumCrewSize = 3`. The scheduler only considers time slots where at least 3 members of the assigned `ServiceCrew` are available.

### Configuration Tips

- Requires `ServiceCrew` and `ServiceCrewMember` records to be set up.
- If `MinimumCrewSize` is null or 0, the rule is effectively ignored for that SA.
- Crew members must individually pass other work rules (skills, territory, etc.).
- This rule is only relevant when using crew scheduling — skip it for individual resource scheduling.

---

## 6. Count Rule

**RecordType:** `FSL__Count_Rule__c`

**Behavior:** Limits the number of Service Appointments a resource can be assigned within a defined time period. Filters out time slots that would exceed the limit.

### Key Configuration Fields

| Field | API Name | Description |
|-------|----------|-------------|
| Maximum Count | `FSL__Maximum__c` | Max number of SAs in the time period |
| Time Period | `FSL__Time_Period__c` | Period type: `Daily`, `Weekly`, `Monthly` |
| Count Object | `FSL__CountObject__c` | What to count (typically `ServiceAppointment`) |
| Count Type | `FSL__CountType__c` | `Resource` or `Territory` based counting |

### Example Use Case

Limit each technician to 6 appointments per day. Set `Maximum__c = 6`, `Time_Period__c = "Daily"`.

### Configuration Tips

- Daily period uses the resource's timezone (from their territory's Operating Hours timezone).
- **Timezone pitfall**: If operating hours timezone and resource timezone differ, counts may split unexpectedly across day boundaries.
- The count includes already-scheduled SAs plus the candidate SA. If 5 are scheduled and max is 6, one more slot is available.
- Useful for managing workload, especially for high-value or complex appointments.
- Count rules can interact poorly with optimization if set too tight — the optimizer may fail to find valid schedules.

---

## 7. Working Territories

**RecordType:** `FSL__Working_Territories__c`

**Behavior:** Restricts scheduling to time windows when the resource is actively working in a specific territory, based on `ServiceTerritoryMember` effective dates and the territory's Operating Hours.

### Key Configuration Fields

No additional configuration fields beyond the standard work rule fields.

### Example Use Case

Resource works in "Downtown" territory Mon-Fri and "Suburban" territory on weekends. This rule ensures SAs in "Downtown" are only scheduled Mon-Fri for this resource.

### Configuration Tips

- This rule adds time-based filtering on top of Match Territory's membership check.
- Relies on Operating Hours assigned to the `ServiceTerritory`.
- Without this rule, a resource who is a member of a territory can be scheduled there at any time.
- Critical for organizations where resources rotate between territories on different days.
- Works with the `OperatingHours` and `TimeSlot` objects on the territory.

---

## 8. Excluded Resources

**RecordType:** `FSL__Excluded_Resources__c`

**Behavior:** Disqualifies resources that have a `ResourcePreference` record with `PreferenceType = 'Excluded'` for the SA's Account or WorkOrder.

### Key Configuration Fields

No additional configuration fields beyond the standard work rule fields.

### Example Use Case

A customer had a bad experience with a specific technician. Create a `ResourcePreference` record linking that `ServiceResource` to the `Account` with `PreferenceType = 'Excluded'`. That technician is never scheduled for this customer.

### Configuration Tips

- `ResourcePreference` records are on the `ResourcePreference` object with fields: `ServiceResource`, `RelatedRecord` (Account or WO), `PreferenceType`.
- This rule reads `PreferenceType = 'Excluded'` records.
- Exclusion is absolute — no objective weighting can override it.
- Can be set at Account level (all WOs for that customer) or individual WO level.
- Commonly used alongside Required Resources and the Preferred Resource objective.

---

## 9. Required Resources

**RecordType:** `FSL__Required_Resources__c`

**Behavior:** Only resources with a `ResourcePreference` record where `PreferenceType = 'Required'` are candidates. All other resources are disqualified.

### Key Configuration Fields

No additional configuration fields beyond the standard work rule fields.

### Example Use Case

A high-value customer requires their dedicated account technician. Create a `ResourcePreference` with `PreferenceType = 'Required'` linking the technician to the Account. Only that technician can be scheduled.

### Configuration Tips

- If no Required preference exists for the SA's Account/WO, this rule passes all resources (no filtering).
- If Required preferences exist, ONLY those resources are candidates — this is very restrictive.
- Multiple Required preferences create a small candidate pool (any of the required resources can be chosen).
- Don't confuse with `PreferenceType = 'Preferred'` — that's handled by the Preferred Resource service objective (soft preference, not hard filter).
- Use sparingly. Over-constraining with Required Resources + other rules can result in zero candidates.

---

## 10. SA Bundling

**RecordType:** `FSL__Appointment_Bundling__c`

**Behavior:** Controls geographic bundling of Service Appointments. Groups nearby SAs together to minimize travel time and maximize route efficiency.

### Key Configuration Fields

| Field | API Name | Description |
|-------|----------|-------------|
| Bundle Radius | `FSL__Bundle_Radius__c` | Maximum distance between bundled appointments (in km or mi) |
| Minimum Bundle Size | `FSL__Minimum_Bundle_Size__c` | Minimum number of SAs to form a bundle |
| Maximum Bundle Size | `FSL__Maximum_Bundle_Size__c` | Maximum number of SAs in a bundle |
| Bundle Field | `FSL__Bundle_Field_Name__c` | Field to match for bundling eligibility |

### Example Use Case

A utility company wants to bundle meter reading appointments within a 5km radius, grouping 3-8 appointments per bundle. The scheduler groups geographically close SAs and assigns them sequentially to a single resource.

### Configuration Tips

- Bundling creates `FSL__Appointment_Bundle__c` records that link bundled SAs together.
- SAs must have valid geolocation (Latitude/Longitude) for distance calculations.
- Bundle Field allows logical grouping — only SAs with matching field values can be bundled (e.g., same WorkType).
- Bundling interacts with the Minimize Travel objective — use both for optimal routing.
- Bundled SAs are scheduled as a group; unbundling one may require rescheduling the others.
- Test bundle radius carefully. Too small = few bundles formed. Too large = excessive travel within bundles.

---

## Work Rule Assignment

Work rules are associated with scheduling policies via `FSL__Scheduling_Policy_Work_Rule__c` junction records:

| Field | Description |
|-------|-------------|
| `FSL__Scheduling_Policy__c` | The scheduling policy |
| `FSL__Work_Rule__c` | The work rule |
| `FSL__Enable__c` | Toggle rule on/off without deleting |

A single work rule can be reused across multiple scheduling policies. Rules within a policy are AND-ed: a resource/time slot must pass ALL enabled rules.

## Performance Considerations

- More work rules = more filtering = fewer candidates = faster objective scoring but risk of zero results.
- Match Skills and Match Territory are the most impactful filters — apply these first (they are evaluated early by the engine).
- Count Rules are expensive to evaluate — use judiciously.
- Test your rule combinations to ensure at least some resources pass. Use the Scheduling Recipe in the Gantt to diagnose "no candidates" issues.
