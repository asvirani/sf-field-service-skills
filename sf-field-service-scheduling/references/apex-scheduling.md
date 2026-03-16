# Apex Scheduling Reference

Programmatic scheduling patterns using FSL managed package classes.

---

## 1. Schedule a Single Appointment

```apex
/**
 * Schedules a single ServiceAppointment using the FSL scheduling engine.
 * The engine evaluates work rules, scores candidates via objectives,
 * and assigns the best resource + time slot.
 */
public class ScheduleAppointmentService {

    public static FSL.ScheduleResult scheduleAppointment(Id policyId, Id saId) {
        // Validate inputs
        if (policyId == null || saId == null) {
            throw new AuraHandledException('Policy Id and Service Appointment Id are required.');
        }

        // Validate SA state
        ServiceAppointment sa = [
            SELECT Id, Status, EarliestStartTime, DueDate, Duration,
                   ServiceTerritoryId, SchedStartTime
            FROM ServiceAppointment
            WHERE Id = :saId
            LIMIT 1
        ];

        if (sa.SchedStartTime != null) {
            throw new AuraHandledException('Appointment is already scheduled.');
        }

        if (sa.EarliestStartTime == null || sa.DueDate == null) {
            throw new AuraHandledException(
                'EarliestStartTime and DueDate must be set on the Service Appointment.'
            );
        }

        if (sa.ServiceTerritoryId == null) {
            throw new AuraHandledException('Service Appointment must have a Service Territory.');
        }

        if (sa.Duration == null || sa.Duration <= 0) {
            throw new AuraHandledException('Service Appointment must have a positive Duration.');
        }

        FSL.ScheduleResult result;
        try {
            result = FSL.ScheduleService.schedule(policyId, saId);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'FSL.ScheduleService.schedule failed: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Scheduling failed: ' + e.getMessage());
        }

        if (result == null) {
            throw new AuraHandledException(
                'No valid schedule found. Verify work rules, resource availability, and scheduling window.'
            );
        }

        System.debug('Scheduled SA ' + saId +
            ' | Start: ' + result.Service.SchedStartTime +
            ' | End: ' + result.Service.SchedEndTime);

        return result;
    }
}
```

---

## 2. Get Appointment Candidates

```apex
/**
 * Returns ranked resource candidates for a ServiceAppointment.
 * Useful for dispatcher-assisted scheduling or custom UIs.
 */
public class CandidateService {

    @AuraEnabled(cacheable=false)
    public static List<CandidateWrapper> getCandidates(Id saId, Id policyId) {
        if (saId == null || policyId == null) {
            throw new AuraHandledException('SA Id and Policy Id are required.');
        }

        // Validate SA
        ServiceAppointment sa = [
            SELECT Id, EarliestStartTime, DueDate, Duration, ServiceTerritoryId
            FROM ServiceAppointment
            WHERE Id = :saId
            LIMIT 1
        ];

        if (sa.EarliestStartTime == null || sa.DueDate == null) {
            throw new AuraHandledException('SA must have EarliestStartTime and DueDate.');
        }

        List<FSL.AppointmentBookingCandidate> candidates;
        try {
            candidates = FSL.AppointmentBookingService.GetCandidates(saId, policyId);
        } catch (Exception e) {
            throw new AuraHandledException('Failed to get candidates: ' + e.getMessage());
        }

        if (candidates == null || candidates.isEmpty()) {
            return new List<CandidateWrapper>();
        }

        List<CandidateWrapper> wrappers = new List<CandidateWrapper>();
        for (FSL.AppointmentBookingCandidate c : candidates) {
            CandidateWrapper w = new CandidateWrapper();
            w.resourceId = c.ServiceResourceId;
            w.startTime = c.Start;
            w.endTime = c.End;
            w.grade = c.Grade;
            w.travelTime = c.TravelTime;
            wrappers.add(w);
        }

        return wrappers;
    }

    public class CandidateWrapper {
        @AuraEnabled public Id resourceId;
        @AuraEnabled public DateTime startTime;
        @AuraEnabled public DateTime endTime;
        @AuraEnabled public Decimal grade;
        @AuraEnabled public Decimal travelTime;
    }
}
```

---

## 3. Get Time Slots for Booking

```apex
/**
 * Returns available time slots for customer-facing or internal booking UIs.
 * Slots represent arrival windows, not exact scheduled times.
 */
public class SlotService {

    @AuraEnabled(cacheable=true)
    public static List<SlotWrapper> getSlots(
        Id workOrderId,
        Id policyId,
        Id operatingHoursId,
        Integer daysAhead
    ) {
        if (workOrderId == null || policyId == null || operatingHoursId == null) {
            throw new AuraHandledException('WorkOrder, Policy, and Operating Hours Ids are required.');
        }

        if (daysAhead == null || daysAhead <= 0) {
            daysAhead = 14; // Default: 2 weeks
        }

        OperatingHours oh = [
            SELECT Id, TimeZone
            FROM OperatingHours
            WHERE Id = :operatingHoursId
            LIMIT 1
        ];

        TimeZone tz = TimeZone.getTimeZone(oh.TimeZone);

        List<FSL.AppointmentBookingSlot> rawSlots;
        try {
            rawSlots = FSL.AppointmentBookingService.GetSlots(
                workOrderId,
                policyId,
                oh,
                tz,
                false  // exactAppointments — false returns rounded slots
            );
        } catch (Exception e) {
            throw new AuraHandledException('Failed to retrieve slots: ' + e.getMessage());
        }

        if (rawSlots == null || rawSlots.isEmpty()) {
            return new List<SlotWrapper>();
        }

        List<SlotWrapper> slots = new List<SlotWrapper>();
        for (FSL.AppointmentBookingSlot s : rawSlots) {
            SlotWrapper sw = new SlotWrapper();
            sw.startTime = s.Interval.Start;
            sw.endTime = s.Interval.End;
            sw.grade = s.Grade;
            slots.add(sw);
        }

        // Sort by grade descending (best slots first)
        slots.sort();
        return slots;
    }

    public class SlotWrapper implements Comparable {
        @AuraEnabled public DateTime startTime;
        @AuraEnabled public DateTime endTime;
        @AuraEnabled public Decimal grade;

        public Integer compareTo(Object other) {
            SlotWrapper otherSlot = (SlotWrapper) other;
            // Higher grade first
            if (this.grade > otherSlot.grade) return -1;
            if (this.grade < otherSlot.grade) return 1;
            // Same grade — earlier slot first
            if (this.startTime < otherSlot.startTime) return -1;
            if (this.startTime > otherSlot.startTime) return 1;
            return 0;
        }
    }
}
```

---

## 4. Emergency Scheduling Pattern

```apex
/**
 * Emergency scheduling: creates an SA with tight window and schedules immediately.
 * The engine will reshuffle non-pinned SAs to fit the emergency.
 */
public class EmergencyScheduler {

    public static ServiceAppointment scheduleEmergency(
        Id workOrderId,
        Id policyId,
        Double durationInHours
    ) {
        if (workOrderId == null || policyId == null) {
            throw new AuraHandledException('WorkOrder Id and Policy Id are required.');
        }

        // Create emergency SA
        ServiceAppointment sa = new ServiceAppointment();
        sa.ParentRecordId = workOrderId;
        sa.EarliestStartTime = DateTime.now();
        sa.DueDate = DateTime.now().addHours(4); // 4-hour emergency window
        sa.Duration = durationInHours;
        sa.DurationType = 'Hours';
        sa.FSL__IsEmergency__c = true;
        sa.Status = 'None';

        // Inherit territory from WO
        WorkOrder wo = [
            SELECT Id, ServiceTerritoryId
            FROM WorkOrder
            WHERE Id = :workOrderId
            LIMIT 1
        ];
        sa.ServiceTerritoryId = wo.ServiceTerritoryId;

        insert sa;

        // Schedule immediately
        FSL.ScheduleResult result;
        try {
            result = FSL.ScheduleService.schedule(policyId, sa.Id);
        } catch (Exception e) {
            // Clean up on failure
            System.debug(LoggingLevel.ERROR, 'Emergency scheduling failed: ' + e.getMessage());
            throw new AuraHandledException('Emergency scheduling failed: ' + e.getMessage());
        }

        if (result == null || result.Service == null) {
            throw new AuraHandledException(
                'No resources available for emergency. All resources may be pinned or in locked statuses.'
            );
        }

        System.debug('Emergency scheduled: SA=' + sa.Id +
            ' Resource=' + result.Resource.Id +
            ' Start=' + result.Service.SchedStartTime);

        return result.Service;
    }
}
```

---

## 5. Bulk Scheduling Pattern

```apex
/**
 * Schedules multiple SAs in sequence. Handles partial failures gracefully.
 * For large volumes, consider using Queueable chaining.
 */
public class BulkScheduler {

    /**
     * Synchronous bulk schedule — suitable for up to ~20 SAs per transaction.
     */
    public static List<ScheduleResultWrapper> scheduleBulk(
        Id policyId,
        List<Id> saIds
    ) {
        if (policyId == null || saIds == null || saIds.isEmpty()) {
            throw new AuraHandledException('Policy Id and SA Ids are required.');
        }

        List<ScheduleResultWrapper> results = new List<ScheduleResultWrapper>();

        for (Id saId : saIds) {
            ScheduleResultWrapper wrapper = new ScheduleResultWrapper();
            wrapper.serviceAppointmentId = saId;

            try {
                FSL.ScheduleResult result = FSL.ScheduleService.schedule(policyId, saId);
                if (result != null && result.Service != null) {
                    wrapper.success = true;
                    wrapper.scheduledStart = result.Service.SchedStartTime;
                    wrapper.resourceId = result.Resource?.Id;
                } else {
                    wrapper.success = false;
                    wrapper.errorMessage = 'No valid schedule found.';
                }
            } catch (Exception e) {
                wrapper.success = false;
                wrapper.errorMessage = e.getMessage();
                System.debug(LoggingLevel.WARN, 'Failed to schedule SA ' + saId + ': ' + e.getMessage());
            }

            results.add(wrapper);
        }

        // Log summary
        Integer successCount = 0;
        for (ScheduleResultWrapper r : results) {
            if (r.success) successCount++;
        }
        System.debug('Bulk schedule complete: ' + successCount + '/' + saIds.size() + ' succeeded.');

        return results;
    }

    /**
     * Async bulk schedule — use for large volumes (50+ SAs).
     * Chains Queueable jobs, processing a batch at a time.
     */
    public static Id scheduleAsync(Id policyId, List<Id> saIds) {
        BulkScheduleQueueable job = new BulkScheduleQueueable(policyId, saIds, 0);
        return System.enqueueJob(job);
    }

    public class ScheduleResultWrapper {
        @AuraEnabled public Id serviceAppointmentId;
        @AuraEnabled public Boolean success;
        @AuraEnabled public DateTime scheduledStart;
        @AuraEnabled public Id resourceId;
        @AuraEnabled public String errorMessage;
    }

    /**
     * Queueable for async bulk scheduling.
     * Processes BATCH_SIZE SAs per execution, then chains to the next batch.
     */
    public class BulkScheduleQueueable implements Queueable {
        private static final Integer BATCH_SIZE = 10;
        private Id policyId;
        private List<Id> saIds;
        private Integer startIndex;

        public BulkScheduleQueueable(Id policyId, List<Id> saIds, Integer startIndex) {
            this.policyId = policyId;
            this.saIds = saIds;
            this.startIndex = startIndex;
        }

        public void execute(QueueableContext ctx) {
            Integer endIndex = Math.min(startIndex + BATCH_SIZE, saIds.size());

            for (Integer i = startIndex; i < endIndex; i++) {
                try {
                    FSL.ScheduleService.schedule(policyId, saIds[i]);
                } catch (Exception e) {
                    System.debug(LoggingLevel.WARN,
                        'Async schedule failed for SA ' + saIds[i] + ': ' + e.getMessage());
                }
            }

            // Chain next batch
            if (endIndex < saIds.size()) {
                System.enqueueJob(
                    new BulkScheduleQueueable(policyId, saIds, endIndex)
                );
            }
        }
    }
}
```

---

## 6. Custom Scheduling Objective

```apex
/**
 * Custom objective: prefer resources closer to a warehouse location.
 * Implements FSL.SchedulingObjective interface.
 *
 * Setup:
 * 1. Create FSL__Service_Objective__c record with RecordType = Custom
 * 2. Set FSL__Apex_Class__c = 'WarehouseProximityObjective'
 * 3. Set weight (1-10) on the scheduling policy junction
 */
global class WarehouseProximityObjective implements FSL.SchedulingObjective {

    // Warehouse coordinates — in production, read from Custom Metadata
    private static final Double WAREHOUSE_LAT = 37.7749;
    private static final Double WAREHOUSE_LNG = -122.4194;
    private static final Double MAX_DISTANCE_MILES = 50.0;

    global Decimal getScore(
        ServiceAppointment sa,
        ServiceResource sr,
        Datetime startTime,
        Datetime endTime
    ) {
        // Get resource home location
        if (sr.Latitude == null || sr.Longitude == null) {
            return 0.5; // Neutral score for resources without location
        }

        Location resourceLoc = Location.newInstance(sr.Latitude, sr.Longitude);
        Location warehouseLoc = Location.newInstance(WAREHOUSE_LAT, WAREHOUSE_LNG);
        Double distance = Location.getDistance(resourceLoc, warehouseLoc, 'mi');

        // Score: closer = higher (1.0 at warehouse, 0.0 at MAX_DISTANCE+)
        Decimal score = Math.max(0, 1 - (Decimal.valueOf(distance) / MAX_DISTANCE_MILES));
        return score;
    }
}
```

### Custom Objective: Customer Tier Priority

```apex
/**
 * Boosts score for high-tier customers.
 * Reads Account.Tier__c and assigns higher scores for premium tiers.
 */
global class CustomerTierObjective implements FSL.SchedulingObjective {

    // Cache account tiers to avoid repeated queries
    private static Map<Id, String> accountTierCache = new Map<Id, String>();

    global Decimal getScore(
        ServiceAppointment sa,
        ServiceResource sr,
        Datetime startTime,
        Datetime endTime
    ) {
        if (sa.AccountId == null) {
            return 0.5;
        }

        String tier = getAccountTier(sa.AccountId);

        switch on tier {
            when 'Platinum' { return 1.0; }
            when 'Gold'     { return 0.8; }
            when 'Silver'   { return 0.6; }
            when 'Bronze'   { return 0.4; }
            when else       { return 0.3; }
        }
    }

    private static String getAccountTier(Id accountId) {
        if (!accountTierCache.containsKey(accountId)) {
            Account acct = [
                SELECT Tier__c
                FROM Account
                WHERE Id = :accountId
                LIMIT 1
            ];
            accountTierCache.put(accountId, acct.Tier__c);
        }
        return accountTierCache.get(accountId);
    }
}
```

---

## Common Gotchas

### No Default Scheduling Policy

**Symptom:** `FSL.ScheduleService.schedule()` throws exception or returns null.

**Cause:** No active scheduling policy exists, or the provided Policy Id is invalid.

**Fix:**
```apex
// Always verify the policy exists
List<FSL__Scheduling_Policy__c> policies = [
    SELECT Id, Name
    FROM FSL__Scheduling_Policy__c
    WHERE Id = :policyId
    AND FSL__Active__c = true
    LIMIT 1
];
if (policies.isEmpty()) {
    throw new AuraHandledException('No active scheduling policy found with Id: ' + policyId);
}
```

---

### Operating Hours Gaps Returning Zero Slots

**Symptom:** `GetSlots()` returns empty list.

**Cause:** Operating Hours `TimeSlot` records don't cover the requested days, or the timezone offset creates gaps.

**Fix:**
- Verify `TimeSlot` records exist for each day of the week under the `OperatingHours`.
- Confirm the timezone on `OperatingHours.TimeZone` matches expectations.
- Check that the SA's `EarliestStartTime`/`DueDate` window overlaps with operating hours.

```apex
// Debug: check operating hours coverage
List<TimeSlot> slots = [
    SELECT DayOfWeek, StartTime, EndTime, Type
    FROM TimeSlot
    WHERE OperatingHoursId = :operatingHoursId
    ORDER BY DayOfWeek, StartTime
];
System.debug('TimeSlots for OH ' + operatingHoursId + ': ' + JSON.serializePretty(slots));
```

---

### EarliestStartDate / DueDate Too Narrow

**Symptom:** Zero candidates or zero slots returned.

**Cause:** The window between `EarliestStartTime` and `DueDate` is too small to fit the appointment duration plus travel time.

**Fix:**
- Ensure `DueDate - EarliestStartTime >= Duration + expected travel time`.
- For a 2-hour SA with 30 min expected travel, the window must be at least 2.5 hours.
- Add buffer: `DueDate = EarliestStartTime.addDays(7)` for routine work.

---

### Missing ServiceTerritoryMember Records

**Symptom:** No candidates returned despite active resources existing.

**Cause:** Resources are not members of the SA's `ServiceTerritory`, and the **Match Territory** work rule filters them out.

**Fix:**
```apex
// Debug: check territory membership
List<ServiceTerritoryMember> members = [
    SELECT Id, ServiceResourceId, ServiceResource.Name,
           ServiceTerritoryId, TerritoryType,
           EffectiveStartDate, EffectiveEndDate
    FROM ServiceTerritoryMember
    WHERE ServiceTerritoryId = :sa.ServiceTerritoryId
    AND EffectiveStartDate <= :sa.DueDate
    AND (EffectiveEndDate = null OR EffectiveEndDate >= :sa.EarliestStartTime)
];
System.debug('Active territory members: ' + members.size());
```

---

### Travel Time Without Routing Provider

**Symptom:** Travel time is zero or unrealistically short/long.

**Cause:** No routing provider (Google Maps, HERE) is configured. FSL falls back to straight-line distance with a default speed.

**Impact:**
- Straight-line underestimates travel in urban areas with indirect routes.
- Overestimates travel in areas with direct highways.
- Slot availability may be inaccurate.

**Fix:**
- Configure a routing provider in **Field Service Settings > Scheduling > Routing**.
- Or accept straight-line estimates and adjust scheduling expectations accordingly.
- The straight-line default speed is approximately 30 mph / 48 kph.

---

### Pinned Appointments Blocking Optimization

**Symptom:** Optimization produces poor results or fails to improve scores.

**Cause:** Too many SAs have `FSL__Pinned__c = true`, leaving the optimizer with insufficient flexibility.

**Fix:**
```apex
// Audit pinned appointments
Integer pinnedCount = [
    SELECT COUNT()
    FROM ServiceAppointment
    WHERE FSL__Pinned__c = true
    AND ServiceTerritoryId = :territoryId
    AND SchedStartTime >= :windowStart
    AND SchedEndTime <= :windowEnd
];
System.debug('Pinned SAs in territory: ' + pinnedCount);
// Rule of thumb: keep pinned < 30% of total for effective optimization
```

- Only pin customer-confirmed appointments.
- Unpin SAs that are merely "preferred" times — use objectives instead.
- SAs in locked statuses (Dispatched, In Progress) are also immovable.

---

### Count Rules and Timezone Issues

**Symptom:** Resource hits daily count limit earlier than expected, or count resets at unexpected times.

**Cause:** Count Rule's "daily" boundary uses the territory's Operating Hours timezone. If the resource works across timezones or the OH timezone is wrong, counts split across day boundaries incorrectly.

**Fix:**
- Verify the `OperatingHours.TimeZone` on the `ServiceTerritory`.
- Ensure it matches the resource's actual working timezone.
- For resources spanning timezones, consider territory-level count rules rather than global ones.

```apex
// Check territory timezone
ServiceTerritory st = [
    SELECT Id, Name, OperatingHoursId, OperatingHours.TimeZone
    FROM ServiceTerritory
    WHERE Id = :territoryId
    LIMIT 1
];
System.debug('Territory timezone: ' + st.OperatingHours.TimeZone);
```

---

## Quick Reference: FSL Managed Package Classes

| Class | Method | Purpose |
|-------|--------|---------|
| `FSL.ScheduleService` | `schedule(policyId, saId)` | Schedule one SA |
| `FSL.AppointmentBookingService` | `GetSlots(woId, policyId, oh, tz, exact)` | Get available time slots |
| `FSL.AppointmentBookingService` | `GetCandidates(saId, policyId)` | Get ranked resource candidates |
| `FSL.SchedulingObjective` | `getScore(sa, sr, start, end)` | Interface for custom objectives |
| `FSL.CustomGanttAction` | `execute(params)` | Interface for custom Gantt actions |

## Quick Reference: Key SA Fields for Scheduling

| Field | API Name | Required For |
|-------|----------|-------------|
| Earliest Start | `EarliestStartTime` | All scheduling |
| Due Date | `DueDate` | All scheduling |
| Duration | `Duration` | All scheduling |
| Duration Type | `DurationType` | Duration interpretation (`Hours`/`Minutes`) |
| Territory | `ServiceTerritoryId` | Territory-based scheduling |
| Scheduled Start | `SchedStartTime` | Set by scheduler |
| Scheduled End | `SchedEndTime` | Set by scheduler |
| Arrival Window Start | `ArrivalWindowStartTime` | Customer booking |
| Arrival Window End | `ArrivalWindowEndTime` | Customer booking |
| Pinned | `FSL__Pinned__c` | Optimization exclusion |
| Emergency | `FSL__IsEmergency__c` | Emergency dispatch |
| Same Resource | (on WorkOrder) `FSL__Same_Resource__c` | Multi-day work |
| Predecessor | `FSL__Predecessor__c` | Dependent appointments |
