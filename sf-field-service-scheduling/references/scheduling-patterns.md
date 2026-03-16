# Scheduling Patterns Reference

Common scheduling scenarios with implementation details.

---

## 1. Multi-Day Work Orders

**When to use:** Work requires multiple visits (e.g., 3-day installation, phased inspections).

### Objects Involved

| Object | Role |
|--------|------|
| `WorkOrder` | Parent record for the entire job |
| `ServiceAppointment` (multiple) | One SA per visit/day |
| `FSL__Same_Resource__c` | Field on WO — enforces same resource across SAs |

### Configuration

1. Create one WorkOrder.
2. Create multiple ServiceAppointments under the WO, each with its own `EarliestStartTime`, `DueDate`, and `Duration`.
3. Set `WorkOrder.FSL__Same_Resource__c = true` to enforce the same resource for all SAs.
4. Optionally use `FSL__Predecessor__c` to enforce sequencing (see Pattern 2).

### Gotchas

- `FSL__Same_Resource__c` is a hard constraint. If the resource is unavailable for any SA, none get scheduled.
- Each SA can have independent scheduling windows. Ensure windows don't conflict.
- The scheduler evaluates all SAs together when Same Resource is enabled — this increases computation time.

---

## 2. Dependent Appointments

**When to use:** SA B cannot start until SA A is completed (e.g., inspection before repair, foundation before framing).

### Objects Involved

| Object | Field | Description |
|--------|-------|-------------|
| `ServiceAppointment` | `FSL__Predecessor__c` | Lookup to another SA that must complete first |

### Configuration

1. Create SA-A (predecessor).
2. Create SA-B and set `FSL__Predecessor__c = SA-A.Id`.
3. SA-B's `EarliestStartTime` is automatically constrained to after SA-A's `SchedEndTime`.
4. Chain multiple: SA-C depends on SA-B, which depends on SA-A.

### Gotchas

- Circular dependencies cause scheduling failures. A -> B -> C -> A is invalid.
- If the predecessor is unscheduled, the dependent SA cannot be scheduled.
- Rescheduling a predecessor does NOT auto-reschedule dependents. You must reschedule the chain.
- Long chains (5+) increase scheduling complexity significantly.

---

## 3. Crew Scheduling

**When to use:** Job requires multiple resources simultaneously (e.g., heavy equipment, two-person safety requirement).

### Objects Involved

| Object | Role |
|--------|------|
| `ServiceCrew` | Named crew (e.g., "Install Team Alpha") |
| `ServiceCrewMember` | Junction: links ServiceResource to ServiceCrew |
| `ServiceAppointment.MinimumCrewSize` | Minimum members needed |
| Match Crew Size work rule | Enforces the minimum |

### Configuration

1. Create `ServiceCrew` records.
2. Add `ServiceCrewMember` records linking resources to crews. Set `StartDate`/`EndDate` for membership periods.
3. On the SA, set `MinimumCrewSize` (e.g., 3).
4. Add the **Match Crew Size** work rule to the scheduling policy.
5. Assign the SA to a territory where crew members are based.

### Gotchas

- All crew members must individually pass work rules (skills, territory, etc.).
- If even one member is unavailable, the slot fails the crew size check.
- Crew scheduling does not automatically assign specific crew members — it validates that enough are available.
- `ServiceCrewMember.StartDate` and `EndDate` must cover the SA's scheduled time.

---

## 4. Geographic Bundling

**When to use:** Group nearby appointments to minimize travel (e.g., meter readings, door-to-door inspections).

### Objects Involved

| Object | Role |
|--------|------|
| `FSL__Appointment_Bundle__c` | Bundle container record |
| `FSL__Appointment_Bundle_Member__c` | Junction linking SAs to a bundle |
| SA Bundling work rule | Controls bundling parameters |

### Configuration

1. Enable the **SA Bundling** work rule on the scheduling policy.
2. Configure:
   - `FSL__Bundle_Radius__c`: Max distance between bundled SAs (km or mi).
   - `FSL__Minimum_Bundle_Size__c`: Min SAs to form a bundle.
   - `FSL__Maximum_Bundle_Size__c`: Max SAs per bundle.
   - `FSL__Bundle_Field_Name__c`: Optional field to restrict bundling (e.g., only bundle same WorkType).
3. SAs must have valid `Latitude`/`Longitude`.
4. Run scheduling or optimization — bundles are created automatically.

### Gotchas

- SAs without geolocation are excluded from bundling.
- Bundling happens during scheduling/optimization, not on-demand.
- Modifying one SA in a bundle may affect the others. Unbundling requires rescheduling.
- Test radius carefully — too tight means few bundles, too loose means travel within bundles is high.
- Bundling works best with the **Minimize Travel** objective weighted high.

---

## 5. Emergency / Same-Day Dispatch

**When to use:** Urgent, unplanned work that must be done immediately (e.g., gas leak, system outage).

### Objects Involved

| Object/Field | Role |
|-------------|------|
| `ServiceAppointment.FSL__IsEmergency__c` | Boolean flag |
| `ServiceAppointment.EarliestStartTime` | Set to now |
| `ServiceAppointment.DueDate` | Set to end of today |

### Configuration

1. Set `FSL__IsEmergency__c = true` on the SA.
2. Set `EarliestStartTime = DateTime.now()`.
3. Set `DueDate` to a very near deadline (e.g., 2-4 hours from now).
4. Schedule using a policy with **ASAP** weighted 9-10.
5. The scheduler will reshuffle existing (non-pinned) appointments to fit the emergency.

### Emergency Scheduling Behavior

- Emergency SAs are prioritized above all non-pinned SAs.
- The scheduler may move existing appointments to later slots or to other resources.
- Pinned SAs and locked statuses are never moved.
- Dispatchers can right-click > Emergency in the Gantt for a one-click workflow.

### Gotchas

- If all resources are pinned or in locked statuses, emergency scheduling fails.
- Very narrow DueDate windows may result in no available slots.
- Emergency scheduling does not notify affected customers whose appointments were moved — build notification logic separately.

---

## 6. Preventive Maintenance

**When to use:** Recurring scheduled maintenance (e.g., HVAC filter changes every 90 days, quarterly inspections).

### Objects Involved

| Object | Role |
|--------|------|
| `MaintenancePlan` | Defines the maintenance schedule |
| `MaintenanceWorkRule` | Links plan to assets/work types |
| `WorkOrder` | Generated per maintenance cycle |
| `ServiceAppointment` | Generated under each WO |

### Configuration

1. Create a `MaintenancePlan` on the Asset or Account.
   - Set `Frequency`, `FrequencyType` (Months, Days, Weeks).
   - Set `StartDate`, `EndDate` (optional).
   - Set `GenerationTimeframe` — how far ahead to generate WOs.
   - Set `WorkType` — template for generated WOs.
2. Add `MaintenanceWorkRule` records for specific assets.
3. **Generation:** WOs and SAs are generated by a batch job or flow based on the plan's schedule.
4. **Auto-scheduling:** Use a flow or Apex trigger to auto-schedule generated SAs.

### Generation Flow

```
MaintenancePlan (recurring schedule)
    → Generates WorkOrder (one per cycle)
        → Generates ServiceAppointment (one per WO)
            → Auto-schedule via FSL.ScheduleService.schedule()
```

### Gotchas

- `GenerationTimeframe` controls how far ahead WOs are created. Too short = SAs aren't available for scheduling. Too long = clutter.
- Generated WOs inherit the `WorkType`, which sets Duration, Skills, etc.
- If the Asset is decommissioned, deactivate the MaintenancePlan to stop generation.
- Maintenance generation runs as a batch. Monitor `MaintenancePlan.NextSuggestedMaintenanceDate`.

---

## 7. Capacity-Based Scheduling

**When to use:** Limit work by resource capacity rather than fixed appointment counts (e.g., max 8 hours/day, max 5 jobs/day).

### Objects Involved

| Object | Role |
|--------|------|
| `ServiceResourceCapacity` | Defines capacity limits per resource per time period |

### Configuration

| Field | Description |
|-------|-------------|
| `ServiceResourceId` | The resource |
| `StartDate` | Capacity period start |
| `EndDate` | Capacity period end |
| `CapacityNumber` | Max number of SAs (count model) |
| `CapacityInHours` | Max hours of work (hours model) |
| `TimePeriod` | `Day`, `Week`, `Month` |

### Models

| Model | Field | Behavior |
|-------|-------|----------|
| Count | `CapacityNumber` | Max N appointments per period |
| Hours | `CapacityInHours` | Max H hours of work per period (sum of SA Duration) |

### Gotchas

- Capacity is separate from Count Rules (work rule). Capacity is evaluated differently in optimization.
- If both `CapacityNumber` and `CapacityInHours` are set, both are enforced (AND logic).
- Travel time does NOT count toward `CapacityInHours` — only SA Duration.
- Capacity records must cover the scheduling window. Missing records = unlimited capacity assumed.

---

## 8. Shift-Based Scheduling

**When to use:** Resources work defined shifts rather than standard operating hours (e.g., healthcare, manufacturing, 24/7 operations).

### Objects Involved

| Object | Role |
|--------|------|
| `Shift` | Defines a specific work shift (start time, end time, resource) |
| `ShiftPattern` | Template for recurring shifts |
| `ShiftPatternEntry` | Individual entries within a pattern |

### Configuration

1. Create `Shift` records for each resource:
   - `StartTime`, `EndTime` — exact shift window.
   - `ServiceResourceId` — assigned resource.
   - `ServiceTerritoryId` — territory for the shift.
   - `Status` — Tentative, Published, Confirmed.
2. Optionally use `ShiftPattern` + `ShiftPatternEntry` for recurring shift generation.
3. Enable shift-based scheduling in **Field Service Settings**.

### Interaction with Operating Hours

| Scenario | Behavior |
|----------|----------|
| Shifts enabled, no Operating Hours | SAs only scheduled within Shift windows |
| Shifts enabled + Operating Hours | Intersection: SA must fall within both Shift and Operating Hours |
| No Shifts, Operating Hours only | Standard behavior: SAs scheduled within Operating Hours |

### Gotchas

- Shift records must be created before scheduling. If no Shift exists for a resource on a given day, that day has zero capacity.
- Shifts are more granular than Operating Hours — useful for rotating schedules (day/night, 12-hour shifts).
- `ShiftPattern` generates `Shift` records via a batch process. Monitor generation.
- Break time within shifts must be managed separately (ResourceAbsence or built into shift gap).

---

## 9. Customer Self-Service Booking

**When to use:** Customers book their own appointments via Experience Cloud portal or public-facing site.

### Objects Involved

| Object/Component | Role |
|-----------------|------|
| Experience Cloud site | Customer-facing portal |
| LWC / Flow | Booking UI |
| `FSL.AppointmentBookingService.GetSlots()` | Returns available slots |
| `FSL.ScheduleService.schedule()` | Schedules the selected slot |
| Scheduling Policy | "Customer Booking" policy with ASAP-heavy weights |
| Operating Hours | "Customer Booking Hours" — defines bookable windows |

### Implementation Steps

1. **Create a dedicated Scheduling Policy** for customer booking (typically ASAP:9, Travel:5, Preferred:6).
2. **Create dedicated Operating Hours** that reflect customer-facing availability (e.g., 8 AM - 6 PM, no weekends).
3. **Build the booking UI:**
   - Customer selects service type (creates WorkOrder + SA).
   - Call `GetSlots()` to display available windows.
   - Customer picks a slot.
   - Set `ArrivalWindowStartTime`/`ArrivalWindowEndTime` to the selected slot.
   - Call `ScheduleService.schedule()` to assign a resource.
4. **Assign FSL Community permission set** to community users.
5. **Configure sharing rules** so community users can access SA and WO records.

### Architecture

```
Customer Portal (Experience Cloud)
    → LWC Booking Component
        → Apex Controller (with sharing)
            → FSL.AppointmentBookingService.GetSlots()
            → FSL.ScheduleService.schedule()
        → Confirmation + Calendar Invite
```

### Gotchas

- Community users need the **FSL Customer Community Plus** or equivalent permission set.
- `GetSlots()` is CPU-intensive. Cache results or limit the search window (7-14 days).
- Slots can become stale — another customer may book the same slot. Implement optimistic locking or re-validate before confirming.
- Operating Hours for customer booking should be separate from internal dispatcher hours.
- Display arrival windows to customers, not exact scheduled times.
- Rate-limit slot requests to prevent API abuse.
