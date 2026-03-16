# Appointment Booking API Reference

## REST API Endpoints

### GetAppointmentSlots

Returns available time slots for a Service Appointment based on scheduling policy evaluation.

**Endpoint:** `POST /services/data/vXX.0/scheduling/getAppointmentSlots`

#### Request Body

```json
{
  "startTime": "2026-03-16T00:00:00.000Z",
  "endTime": "2026-03-23T23:59:59.000Z",
  "workOrderId": "0WO000000000001",
  "schedulingPolicyId": "0Vr000000000001",
  "accountId": "001000000000001",
  "territoryIds": ["0Hh000000000001", "0Hh000000000002"],
  "allowConcurrentScheduling": false
}
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `startTime` | DateTime | Yes | Start of the search window (ISO 8601) |
| `endTime` | DateTime | Yes | End of the search window (ISO 8601) |
| `workOrderId` | Id | Yes | WorkOrder or ServiceAppointment Id |
| `schedulingPolicyId` | Id | Yes | FSL__Scheduling_Policy__c Id |
| `accountId` | Id | No | Account Id for resource preference filtering |
| `territoryIds` | Id[] | No | Limit search to specific territories. If omitted, all territories on the SA are considered. |
| `allowConcurrentScheduling` | Boolean | No | Allow overlapping appointments. Default: false. |

#### Response

```json
{
  "timeSlots": [
    {
      "startTime": "2026-03-17T09:00:00.000Z",
      "endTime": "2026-03-17T11:00:00.000Z",
      "territoryId": "0Hh000000000001",
      "grade": 0.85
    },
    {
      "startTime": "2026-03-17T13:00:00.000Z",
      "endTime": "2026-03-17T15:00:00.000Z",
      "territoryId": "0Hh000000000001",
      "grade": 0.72
    }
  ]
}
```

| Response Field | Type | Description |
|----------------|------|-------------|
| `timeSlots` | Array | Available appointment windows |
| `timeSlots[].startTime` | DateTime | Slot start (ISO 8601) |
| `timeSlots[].endTime` | DateTime | Slot end (ISO 8601) |
| `timeSlots[].territoryId` | Id | Territory where slot is available |
| `timeSlots[].grade` | Decimal | Score from 0-1 based on objective evaluation |

---

### GetAppointmentCandidates

Returns specific resource-level candidates for a Service Appointment, including which resource would be assigned for each slot.

**Endpoint:** `POST /services/data/vXX.0/scheduling/getAppointmentCandidates`

#### Request Body

```json
{
  "startTime": "2026-03-16T00:00:00.000Z",
  "endTime": "2026-03-23T23:59:59.000Z",
  "serviceAppointmentId": "08p000000000001",
  "schedulingPolicyId": "0Vr000000000001",
  "accountId": "001000000000001"
}
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `startTime` | DateTime | Yes | Search window start |
| `endTime` | DateTime | Yes | Search window end |
| `serviceAppointmentId` | Id | Yes | ServiceAppointment Id |
| `schedulingPolicyId` | Id | Yes | Scheduling Policy Id |
| `accountId` | Id | No | Account for preference filtering |

#### Response

```json
{
  "candidates": [
    {
      "startTime": "2026-03-17T09:00:00.000Z",
      "endTime": "2026-03-17T11:00:00.000Z",
      "resourceId": "0Hn000000000001",
      "resourceName": "Jane Smith",
      "territoryId": "0Hh000000000001",
      "travelTimeFrom": 15,
      "travelTimeTo": 20,
      "grade": 0.92
    }
  ]
}
```

---

## Apex Managed Package Classes

### FSL.AppointmentBookingService

#### GetSlots

```apex
public static List<FSL.AppointmentBookingSlot> GetSlots(
    Id workOrderId,
    Id schedulingPolicyId,
    OperatingHours operatingHours,
    TimeZone tz,
    Boolean exactAppointments
)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `workOrderId` | Id | WorkOrder Id (SA is looked up from WO) |
| `schedulingPolicyId` | Id | Scheduling Policy Id |
| `operatingHours` | OperatingHours | Operating hours defining slot boundaries |
| `tz` | TimeZone | Timezone for slot display |
| `exactAppointments` | Boolean | If true, slots match exact duration. If false, slots are rounded to granularity. |

**Returns:** `List<FSL.AppointmentBookingSlot>`

| Property | Type | Description |
|----------|------|-------------|
| `Interval.Start` | DateTime | Slot start time |
| `Interval.End` | DateTime | Slot end time |
| `Grade` | Decimal | Objective score (0-1) |

#### GetCandidates

```apex
public static List<FSL.AppointmentBookingCandidate> GetCandidates(
    Id serviceAppointmentId,
    Id schedulingPolicyId
)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `serviceAppointmentId` | Id | ServiceAppointment Id |
| `schedulingPolicyId` | Id | Scheduling Policy Id |

**Returns:** `List<FSL.AppointmentBookingCandidate>`

---

### FSL.ScheduleService

#### schedule

```apex
public static FSL.ScheduleResult schedule(
    Id schedulingPolicyId,
    Id serviceAppointmentId
)
```

Schedules a single Service Appointment using the specified policy. Assigns the highest-scoring resource and time slot.

| Parameter | Type | Description |
|-----------|------|-------------|
| `schedulingPolicyId` | Id | Scheduling Policy Id |
| `serviceAppointmentId` | Id | ServiceAppointment Id |

**Returns:** `FSL.ScheduleResult`

| Property | Type | Description |
|----------|------|-------------|
| `Service` | ServiceAppointment | The updated SA record |
| `Resource` | ServiceResource | The assigned resource |

---

## Key Concepts

### Arrival Window vs. Scheduled Time

| Field | Object | Description |
|-------|--------|-------------|
| `ArrivalWindowStartTime` | ServiceAppointment | Start of the window shown to the customer ("We'll arrive between 9-11 AM") |
| `ArrivalWindowEndTime` | ServiceAppointment | End of the customer-facing window |
| `SchedStartTime` | ServiceAppointment | Actual scheduled start time for the resource |
| `SchedEndTime` | ServiceAppointment | Actual scheduled end time |

- **Arrival Window** is customer-facing. It's broader and provides flexibility.
- **Scheduled Time** is the precise time the resource is expected to arrive and work.
- `SchedStartTime` always falls within the Arrival Window.
- The GetAppointmentSlots API returns arrival windows. The scheduler sets the precise scheduled time.

### Time Slot Configuration

Slot availability is determined by:

1. **Operating Hours** on the `ServiceTerritory` — defines when work can be scheduled.
2. **Slot Size** — derived from `ServiceAppointment.Duration` (or `WorkType.EstimatedDuration`).
3. **Granularity** — set via `FSL__Scheduling_Policy__c.FSL__Slot_Granularity__c`. Controls the interval between slot start times (e.g., every 15 min, every 30 min).
4. **EarliestStartDate / DueDate** on ServiceAppointment — constrains the search window.

### Travel Time Impact

- Travel time is subtracted from available slot time.
- A 2-hour appointment with 30 minutes of travel requires a 2.5-hour window.
- If no routing provider is configured, straight-line distance with a default speed is used.
- Travel time appears in GetAppointmentCandidates responses but not in GetAppointmentSlots.

---

## Complete Apex Examples

### Getting Slots Programmatically

```apex
public class AppointmentSlotService {

    public static List<FSL.AppointmentBookingSlot> getAvailableSlots(
        Id workOrderId,
        Id schedulingPolicyId,
        Id operatingHoursId
    ) {
        OperatingHours oh = [
            SELECT Id, TimeZone
            FROM OperatingHours
            WHERE Id = :operatingHoursId
            LIMIT 1
        ];

        TimeZone tz = TimeZone.getTimeZone(oh.TimeZone);

        List<FSL.AppointmentBookingSlot> slots;
        try {
            slots = FSL.AppointmentBookingService.GetSlots(
                workOrderId,
                schedulingPolicyId,
                oh,
                tz,
                false  // exactAppointments
            );
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'GetSlots failed: ' + e.getMessage());
            throw new AuraHandledException('Unable to retrieve appointment slots: ' + e.getMessage());
        }

        return slots;
    }
}
```

### Getting Candidates

```apex
public class AppointmentCandidateService {

    public static List<FSL.AppointmentBookingCandidate> getCandidates(
        Id serviceAppointmentId,
        Id schedulingPolicyId
    ) {
        // Validate SA exists and is in schedulable status
        ServiceAppointment sa = [
            SELECT Id, Status, EarliestStartTime, DueDate, Duration
            FROM ServiceAppointment
            WHERE Id = :serviceAppointmentId
            LIMIT 1
        ];

        if (sa.EarliestStartTime == null || sa.DueDate == null) {
            throw new AuraHandledException(
                'ServiceAppointment must have EarliestStartTime and DueDate set.'
            );
        }

        List<FSL.AppointmentBookingCandidate> candidates;
        try {
            candidates = FSL.AppointmentBookingService.GetCandidates(
                serviceAppointmentId,
                schedulingPolicyId
            );
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'GetCandidates failed: ' + e.getMessage());
            throw new AuraHandledException('Unable to retrieve candidates: ' + e.getMessage());
        }

        return candidates;
    }
}
```

### Scheduling a Single Appointment

```apex
public class SingleAppointmentScheduler {

    public static ServiceAppointment scheduleAppointment(
        Id serviceAppointmentId,
        Id schedulingPolicyId
    ) {
        // Validate inputs
        if (serviceAppointmentId == null || schedulingPolicyId == null) {
            throw new AuraHandledException('Both SA Id and Policy Id are required.');
        }

        ServiceAppointment sa = [
            SELECT Id, Status, EarliestStartTime, DueDate,
                   ServiceTerritoryId, Duration
            FROM ServiceAppointment
            WHERE Id = :serviceAppointmentId
            LIMIT 1
        ];

        // Verify SA is in a schedulable state
        if (sa.Status == 'Completed' || sa.Status == 'Canceled') {
            throw new AuraHandledException(
                'Cannot schedule a completed or canceled appointment.'
            );
        }

        if (sa.ServiceTerritoryId == null) {
            throw new AuraHandledException(
                'ServiceAppointment must have a ServiceTerritory assigned.'
            );
        }

        FSL.ScheduleResult result;
        try {
            result = FSL.ScheduleService.schedule(schedulingPolicyId, serviceAppointmentId);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Schedule failed: ' + e.getMessage());
            throw new AuraHandledException('Scheduling failed: ' + e.getMessage());
        }

        if (result == null || result.Service == null) {
            throw new AuraHandledException(
                'No valid schedule found. Check work rules and resource availability.'
            );
        }

        return result.Service;
    }
}
```

### Customer-Facing Booking Flow Pattern

```apex
/**
 * Controller for customer self-service booking.
 * Used with Experience Cloud (Community) or an LWC flow.
 *
 * Flow:
 * 1. Customer selects a service type (WorkType)
 * 2. System creates WorkOrder + ServiceAppointment
 * 3. GetSlots returns available windows
 * 4. Customer picks a slot
 * 5. System schedules the SA into the selected slot
 */
public with sharing class CustomerBookingController {

    // Configuration — store these in Custom Metadata or Custom Settings
    private static final String SCHEDULING_POLICY_NAME = 'Customer Booking';
    private static final String OPERATING_HOURS_NAME = 'Customer Booking Hours';

    @AuraEnabled(cacheable=true)
    public static List<SlotWrapper> getAvailableSlots(
        Id workOrderId,
        Integer daysAhead
    ) {
        // Look up policy and operating hours
        FSL__Scheduling_Policy__c policy = [
            SELECT Id
            FROM FSL__Scheduling_Policy__c
            WHERE Name = :SCHEDULING_POLICY_NAME
            LIMIT 1
        ];

        OperatingHours oh = [
            SELECT Id, TimeZone
            FROM OperatingHours
            WHERE Name = :OPERATING_HOURS_NAME
            LIMIT 1
        ];

        TimeZone tz = TimeZone.getTimeZone(oh.TimeZone);

        List<FSL.AppointmentBookingSlot> rawSlots =
            FSL.AppointmentBookingService.GetSlots(
                workOrderId,
                policy.Id,
                oh,
                tz,
                false
            );

        // Convert to serializable wrapper
        List<SlotWrapper> slots = new List<SlotWrapper>();
        for (FSL.AppointmentBookingSlot slot : rawSlots) {
            SlotWrapper sw = new SlotWrapper();
            sw.startTime = slot.Interval.Start;
            sw.endTime = slot.Interval.End;
            sw.grade = slot.Grade;
            slots.add(sw);
        }

        return slots;
    }

    @AuraEnabled
    public static Id bookAppointment(
        Id serviceAppointmentId,
        DateTime selectedStart,
        DateTime selectedEnd
    ) {
        ServiceAppointment sa = [
            SELECT Id, Status
            FROM ServiceAppointment
            WHERE Id = :serviceAppointmentId
            LIMIT 1
        ];

        // Set the arrival window to the customer's selected slot
        sa.ArrivalWindowStartTime = selectedStart;
        sa.ArrivalWindowEndTime = selectedEnd;
        update sa;

        // Schedule within the selected window
        FSL__Scheduling_Policy__c policy = [
            SELECT Id
            FROM FSL__Scheduling_Policy__c
            WHERE Name = :SCHEDULING_POLICY_NAME
            LIMIT 1
        ];

        FSL.ScheduleResult result = FSL.ScheduleService.schedule(
            policy.Id,
            serviceAppointmentId
        );

        if (result == null || result.Service == null) {
            throw new AuraHandledException(
                'The selected time slot is no longer available. Please choose another.'
            );
        }

        return result.Service.Id;
    }

    public class SlotWrapper {
        @AuraEnabled public DateTime startTime;
        @AuraEnabled public DateTime endTime;
        @AuraEnabled public Decimal grade;
    }
}
```

---

## Error Scenarios

| Error | Cause | Fix |
|-------|-------|-----|
| `No scheduling policy found` | Policy Id is invalid or policy is inactive | Verify the FSL__Scheduling_Policy__c record exists and is active |
| `No slots returned` (empty array) | No valid candidates pass work rules within the time window | Widen EarliestStartDate/DueDate, check work rules, verify resource availability |
| `FIELD_INTEGRITY_EXCEPTION` | SA missing required fields (Duration, Territory, etc.) | Set Duration, ServiceTerritoryId, EarliestStartTime, DueDate |
| `INSUFFICIENT_ACCESS` | User lacks FSL permissions | Assign FSL permission sets (FSL Admin, FSL Dispatcher, FSL Community) |
| `Travel time not calculated` | No routing provider configured | Configure SFS Routing or accept straight-line estimates |
