# FSL Data Model Gotchas & Best Practices

---

## 1. Polymorphic Lookups — SOQL Handling

**Affected fields:**
- `ServiceAppointment.ParentRecordId` -> WorkOrder | WorkOrderLineItem
- `SkillRequirement.RelatedRecordId` -> WorkOrder | WorkOrderLineItem | ServiceAppointment
- `ProductRequired.ParentRecordId` -> WorkOrder | WorkOrderLineItem
- `ResourcePreference.RelatedRecordId` -> Account | WorkOrder | WorkOrderLineItem | ServiceAppointment

**Rules:**
- Cannot traverse polymorphic lookups with dot notation (e.g., `ParentRecord.Subject` fails).
- Use `TYPEOF` (API v46.0+) to branch field selection by type.
- Use `ParentRecordType` (on ServiceAppointment) as a simple string filter.
- In Apex, cast after checking the type: `if (sa.ParentRecordId.getSObjectType() == WorkOrder.SObjectType)`.
- `TYPEOF` is not supported in `WHERE` clauses — filter by `ParentRecordType` instead.

```sql
-- Correct
SELECT Id, TYPEOF ParentRecord
  WHEN WorkOrder THEN WorkOrderNumber, Subject
  WHEN WorkOrderLineItem THEN LineItemNumber, Subject
END
FROM ServiceAppointment

-- Also correct (simpler)
SELECT Id, ParentRecordId
FROM ServiceAppointment
WHERE ParentRecordType = 'WorkOrder'
```

---

## 2. Auto-Created Service Appointments

**When it happens:**
- WorkType has `ShouldAutoCreateSvcAppt = true` AND the Work Order's `WorkTypeId` is set.
- Triggered on WO insert, not on update (changing WorkTypeId after creation does NOT auto-create).

**What inherits from the parent Work Order:**
- Duration / DurationType (from WorkType)
- Address fields (Street, City, State, PostalCode, Country, Lat, Lng)
- AccountId, ContactId
- ServiceTerritoryId
- EarliestStartDate (from WO StartDate or WorkType TimeframeStart)
- DueDate (from WO EndDate or WorkType TimeframeEnd)
- Skill Requirements are NOT auto-copied — they must be added to the SA separately or via WorkType skill assignments.

**Common mistake:** Assuming skills on the WO automatically appear on the auto-created SA. They do not. Build automation to copy them if needed.

---

## 3. StatusCategory vs Status — Always Filter by StatusCategory

`Status` is a customizable picklist — orgs add custom values (e.g., "Awaiting Parts", "Customer Confirmed"). `StatusCategory` is the system-controlled grouping that maps every Status value.

| StatusCategory | Meaning |
|----------------|---------|
| None | Not yet scheduled |
| Scheduled | Has scheduled times |
| Dispatched | Sent to resource |
| InProgress | Work started |
| Completed | Work done |
| CannotComplete | Failed |
| Canceled | Canceled |

**Rule:** In all automation, triggers, flows, and reports — filter on `StatusCategory`, not `Status`. This ensures your code works across orgs with custom status values.

```apex
// BAD - breaks in orgs with custom statuses
if (sa.Status == 'Completed') { ... }

// GOOD - works everywhere
if (sa.StatusCategory == 'Completed') { ... }
```

---

## 4. Territory Type Precedence (P -> S -> R)

| Type | Code | Meaning | Scheduling Priority |
|------|------|---------|-------------------|
| Primary | P | Home territory | Highest — scheduled first |
| Secondary | S | Overflow territory | Scheduled if Primary resources unavailable |
| Relocation | R | Temporary assignment | Temporary override for specific date ranges |

**Key behaviors:**
- A resource MUST have exactly one Primary STM to be schedulable.
- Relocation overrides Primary for the `EffectiveStartDate` to `EffectiveEndDate` window.
- The scheduler checks STMs with `EffectiveStartDate <= SA.SchedStartTime` and `EffectiveEndDate >= SA.SchedEndTime` (or null).
- If a resource has an expired Primary STM and no active one, they become unschedulable.

---

## 5. Operating Hours Inheritance

Resolution order (first non-null wins):

1. **ServiceTerritoryMember.OperatingHoursId** — resource-specific override in a territory
2. **ServiceTerritory.OperatingHoursId** — territory default
3. **No operating hours** — resource is considered available 24/7 (dangerous)

**Best practice:** Always set OperatingHours on the Territory. Use STM override only for individual exceptions (e.g., part-time technician).

**WorkType.OperatingHoursId** is separate — it defines when the *appointment* can be scheduled (customer-facing hours), not when the *resource* works.

---

## 6. SA Address Inheritance from Parent WO

When a ServiceAppointment is created with a `ParentRecordId` pointing to a WorkOrder:
- Address fields (Street, City, State, PostalCode, Country, Lat, Lng) are copied from the WO at creation time.
- **Updates to the WO address do NOT propagate** to existing SAs.
- If you need address sync, build a trigger or flow on WorkOrder update to push changes to child SAs.

The same applies when the parent is a WorkOrderLineItem — the WOLI address is used, falling back to the WO address if WOLI address is blank.

---

## 7. FSL Managed Package Fields (FSL__ Prefix)

The Field Service managed package installs fields prefixed with `FSL__` on standard objects. These are critical for scheduling but easy to miss.

### Critical Managed Fields

| Object | Field | Purpose |
|--------|-------|---------|
| ServiceAppointment | `FSL__Scheduling_Policy_Used__c` | Policy used to schedule |
| ServiceAppointment | `FSL__GanttColor__c` | Gantt chart color |
| ServiceAppointment | `FSL__Auto_Schedule__c` | Include in auto-scheduling |
| ServiceAppointment | `FSL__Pinned__c` | Prevent optimizer from moving |
| ServiceAppointment | `FSL__IsMultiDay__c` | Multi-day appointment |
| ServiceAppointment | `FSL__InJeopardy__c` | In-jeopardy flag |
| ServiceAppointment | `FSL__InternalSLRGeolocation__Latitude__s` | Geocoded latitude |
| ServiceAppointment | `FSL__InternalSLRGeolocation__Longitude__s` | Geocoded longitude |
| ServiceResource | `FSL__Efficiency__c` | Efficiency multiplier |
| ServiceResource | `FSL__GanttLabel__c` | Label on Gantt |
| ResourceAbsence | `FSL__Approved__c` | Absence approved flag |

**Rules:**
- `FSL__Approved__c` on ResourceAbsence defaults to `false`. Unapproved absences do NOT block scheduling.
- `FSL__Pinned__c` on SA prevents the optimizer from rescheduling — use for locked appointments.
- These fields are NOT available in orgs without the FSL managed package installed.
- Always check for package installation before referencing these in code intended for distribution.

---

## 8. Governor Limit Awareness with Deep Relationship Chains

The full chain (WO -> WOLI -> SA -> AR -> SR -> STM -> Territory) is 6 levels deep. SOQL only supports 5 levels of parent traversal and 1 level of child subquery.

**Strategies:**
- Break queries into multiple hops. Query WO -> SA, then SA -> AR -> SR separately.
- Use `Map<Id, SObject>` to correlate records in Apex.
- Avoid querying the full chain in a single trigger — use async processing for complex rollups.
- Parent relationship traversal (dot notation) is limited to 5 levels: `AssignedResource.ServiceAppointment.ParentRecord...` will hit limits.

**Bulk patterns to watch:**
- A single WO can have many WOLIs, each with many SAs, each with many ARs. A trigger on WO updating all downstream records can easily hit DML limits.
- Use `Database.executeBatch` or Queueable for cascading updates.

---

## 9. Scheduling Policy — Managed Package Object

The scheduling policy is stored as `FSL__Scheduling_Policy__c` — a custom object in the FSL managed package, not a standard object.

- Referenced on SA via `FSL__Scheduling_Policy_Used__c` (Lookup).
- Cannot be queried or manipulated without the FSL package.
- Policies are configured in the FSL Admin app (Scheduling Policies tab).
- The policy ID is needed when calling the scheduling API: `FSL.ScheduleService.schedule()`.

```apex
// Schedule an appointment programmatically
FSL.ScheduleResult result = FSL.ScheduleService.schedule(
    schedulingPolicyId,
    serviceAppointmentId
);
```

---

## 10. ServiceResource Must Have Active STM to Be Schedulable

A ServiceResource record alone is NOT schedulable. Requirements:

1. `ServiceResource.IsActive = true`
2. At least one `ServiceTerritoryMember` with `TerritoryType = 'P'` (Primary)
3. The STM must be currently effective: `EffectiveStartDate <= NOW` and (`EffectiveEndDate >= NOW` or `EffectiveEndDate = null`)
4. The linked `ServiceTerritory.IsActive = true`

**Common issues:**
- Creating a ServiceResource without an STM — resource appears in lists but never gets scheduled.
- STM with `EffectiveEndDate` in the past — resource silently drops off the schedule.
- Territory marked inactive — all resources in that territory become unschedulable.

---

## 11. Skill Expiration via EffectiveEndDate

`ServiceResourceSkill.EffectiveEndDate` controls when a skill expires.

- If `EffectiveEndDate` is null, the skill never expires.
- If `EffectiveEndDate < TODAY`, the skill is expired and the scheduler treats the resource as NOT having that skill.
- There is no built-in notification for expiring skills. Build a scheduled job or report to flag upcoming expirations.

```sql
-- Skills expiring in the next 30 days
SELECT Id, ServiceResource.Name, Skill.MasterLabel,
       SkillLevel, EffectiveEndDate
FROM ServiceResourceSkill
WHERE EffectiveEndDate >= TODAY
  AND EffectiveEndDate <= NEXT_N_DAYS:30
ORDER BY EffectiveEndDate ASC
```

**Best practice:** Create a scheduled Apex job or Flow that alerts managers when certifications are about to expire.

---

## 12. ResourcePreference on Account Applies to All SAs

When a `ResourcePreference` is set on an **Account**:
- It applies to ALL Service Appointments linked to that Account — not just one WO.
- This includes future SAs that don't exist yet.
- `PreferenceType = 'Excluded'` on an Account permanently blocks that resource from all of the account's appointments.

**Hierarchy of preference evaluation:**
1. SA-level ResourcePreference (most specific)
2. WO-level ResourcePreference
3. Account-level ResourcePreference (broadest)

If conflicting preferences exist, the **most specific** wins. An SA-level `Preferred` overrides an Account-level `Excluded`.

**Common mistake:** Setting `Excluded` on an Account for a temporary issue, then forgetting to remove it. The resource silently stops being scheduled for that customer.
