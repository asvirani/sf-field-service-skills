# FSL SOQL Patterns

---

## 1. Scheduled Appointments with Assigned Resources

```sql
SELECT Id, AppointmentNumber, Status, SchedStartTime, SchedEndTime,
       ParentRecordId, ServiceTerritoryId,
       (SELECT Id, ServiceResourceId, ServiceResource.Name,
               EstimatedTravelTime, IsRequiredResource
        FROM ServiceResources)
FROM ServiceAppointment
WHERE StatusCategory = 'Scheduled'
  AND SchedStartTime >= :startDate
  AND SchedStartTime <= :endDate
ORDER BY SchedStartTime ASC
```

## 2. Resources in a Territory with Skills

```sql
SELECT Id, ServiceResource.Name, ServiceResource.ResourceType,
       ServiceResource.IsActive, TerritoryType,
       EffectiveStartDate, EffectiveEndDate,
       ServiceTerritory.Name,
       (SELECT SkillId, Skill.MasterLabel, SkillLevel,
               EffectiveStartDate, EffectiveEndDate
        FROM ServiceResource.ServiceResourceSkills
        WHERE EffectiveEndDate = NULL OR EffectiveEndDate > TODAY)
FROM ServiceTerritoryMember
WHERE ServiceTerritoryId = :territoryId
  AND ServiceResource.IsActive = TRUE
  AND (EffectiveEndDate = NULL OR EffectiveEndDate > TODAY)
ORDER BY TerritoryType ASC
```

## 3. Full Scheduling Chain: WO -> SA -> AR -> SR

```sql
SELECT Id, WorkOrderNumber, Subject, Status, AccountId, Account.Name,
       ServiceTerritoryId, ServiceTerritory.Name,
       (SELECT Id, AppointmentNumber, Status, StatusCategory,
               SchedStartTime, SchedEndTime, Duration,
               (SELECT Id, ServiceResourceId, ServiceResource.Name,
                       ServiceResource.RelatedRecord.Name,
                       EstimatedTravelTime
                FROM ServiceResources)
        FROM ServiceAppointments
        WHERE StatusCategory != 'Canceled')
FROM WorkOrder
WHERE Id = :workOrderId
```

## 4. Resource Availability (Absences + Existing Appointments)

```sql
-- Absences for a resource in a date range
SELECT Id, Start, End, Type, FSL__Approved__c
FROM ResourceAbsence
WHERE ResourceId = :serviceResourceId
  AND FSL__Approved__c = TRUE
  AND Start < :rangeEnd
  AND End > :rangeStart
ORDER BY Start ASC

-- Existing appointments for a resource in a date range
SELECT Id, ServiceAppointment.AppointmentNumber,
       ServiceAppointment.SchedStartTime,
       ServiceAppointment.SchedEndTime,
       ServiceAppointment.Status,
       EstimatedTravelTime
FROM AssignedResource
WHERE ServiceResourceId = :serviceResourceId
  AND ServiceAppointment.SchedStartTime < :rangeEnd
  AND ServiceAppointment.SchedEndTime > :rangeStart
  AND ServiceAppointment.StatusCategory NOT IN ('Canceled', 'CannotComplete')
ORDER BY ServiceAppointment.SchedStartTime ASC
```

## 5. Work Orders with Skill Requirements and Matching Resources

```sql
-- Skills required on a Work Order
SELECT Id, SkillId, Skill.MasterLabel, SkillLevel
FROM SkillRequirement
WHERE RelatedRecordId = :workOrderId

-- Resources matching specific skills
SELECT Id, ServiceResourceId, ServiceResource.Name,
       SkillId, Skill.MasterLabel, SkillLevel
FROM ServiceResourceSkill
WHERE SkillId IN :requiredSkillIds
  AND SkillLevel >= :minimumLevel
  AND ServiceResource.IsActive = TRUE
  AND (EffectiveEndDate = NULL OR EffectiveEndDate > TODAY)
```

## 6. Maintenance Plans with Assets and Generated Work Orders

```sql
SELECT Id, Title, Frequency, FrequencyType,
       NextSuggestedMaintenanceDate,
       DoesAutoGenerateWorkOrders,
       WorkType.Name,
       (SELECT Id, AssetId, Asset.Name, Asset.SerialNumber,
               WorkTypeId, WorkType.Name,
               NextSuggestedMaintenanceDate
        FROM MaintenanceAssets),
       (SELECT Id, WorkOrderNumber, Status, Subject,
               SuggestedMaintenanceDate, CreatedDate
        FROM WorkOrders
        ORDER BY CreatedDate DESC
        LIMIT 10)
FROM MaintenancePlan
WHERE AccountId = :accountId
  AND (EndDate = NULL OR EndDate > TODAY)
```

## 7. Unscheduled Appointments in a Territory

```sql
SELECT Id, AppointmentNumber, EarliestStartDate, DueDate,
       Duration, DurationType,
       ParentRecordId, ParentRecordType,
       Street, City, State, PostalCode,
       Latitude, Longitude,
       (SELECT SkillId, Skill.MasterLabel, SkillLevel
        FROM SkillRequirements)
FROM ServiceAppointment
WHERE ServiceTerritoryId = :territoryId
  AND StatusCategory = 'None'
  AND DueDate >= TODAY
ORDER BY EarliestStartDate ASC
```

## 8. Resource Utilization (Appointments per Day)

```sql
SELECT ServiceResourceId, ServiceResource.Name,
       COUNT(Id) appointmentCount,
       SUM(ServiceAppointment.Duration) totalDuration
FROM AssignedResource
WHERE ServiceAppointment.SchedStartTime >= :dayStart
  AND ServiceAppointment.SchedStartTime < :dayEnd
  AND ServiceAppointment.StatusCategory NOT IN ('Canceled', 'CannotComplete')
GROUP BY ServiceResourceId, ServiceResource.Name
ORDER BY COUNT(Id) DESC
```

Alternative — daily breakdown over a range:

```sql
SELECT ServiceResourceId, ServiceResource.Name,
       DAY_ONLY(ServiceAppointment.SchedStartTime) schedDate,
       COUNT(Id) appointmentCount
FROM AssignedResource
WHERE ServiceAppointment.SchedStartTime >= :rangeStart
  AND ServiceAppointment.SchedStartTime < :rangeEnd
  AND ServiceAppointment.StatusCategory NOT IN ('Canceled', 'CannotComplete')
GROUP BY ServiceResourceId, ServiceResource.Name,
         DAY_ONLY(ServiceAppointment.SchedStartTime)
ORDER BY DAY_ONLY(ServiceAppointment.SchedStartTime) ASC
```

## 9. Work Orders by Status with Service Appointment Counts

```sql
SELECT Status, COUNT(Id) woCount
FROM WorkOrder
WHERE ServiceTerritoryId = :territoryId
  AND CreatedDate = THIS_MONTH
GROUP BY Status
ORDER BY COUNT(Id) DESC

-- Detailed with SA counts per WO
SELECT Id, WorkOrderNumber, Subject, Status, Priority,
       Account.Name,
       (SELECT Id, StatusCategory
        FROM ServiceAppointments)
FROM WorkOrder
WHERE ServiceTerritoryId = :territoryId
  AND IsClosed = FALSE
ORDER BY Priority DESC, CreatedDate ASC
```

## 10. Assets with Related Work Order History

```sql
SELECT Id, Name, SerialNumber, Status, InstallDate,
       Account.Name, Product2.Name,
       (SELECT Id, WorkOrderNumber, Subject, Status,
               CreatedDate, CompletedDate, Priority
        FROM WorkOrders
        ORDER BY CreatedDate DESC),
       (SELECT Id, MaintenancePlan.Title, MaintenancePlan.Frequency,
               MaintenancePlan.FrequencyType
        FROM MaintenanceAssets)
FROM Asset
WHERE AccountId = :accountId
ORDER BY Name ASC
```

---

## Utility Patterns

### Resolve Polymorphic ParentRecordId on ServiceAppointment

```sql
SELECT Id, AppointmentNumber,
       TYPEOF ParentRecord
         WHEN WorkOrder THEN WorkOrderNumber, Subject, Status
         WHEN WorkOrderLineItem THEN LineItemNumber, Subject, Status
       END
FROM ServiceAppointment
WHERE Id = :saId
```

> **Note:** `TYPEOF` requires API v46.0+. Alternative: filter by `ParentRecordType`.

### Filter by ParentRecordType

```sql
SELECT Id, AppointmentNumber, ParentRecordId
FROM ServiceAppointment
WHERE ParentRecordType = 'WorkOrder'
  AND StatusCategory = 'None'
```

### Bulk Fetch Territory Hierarchy

```sql
SELECT Id, Name, ParentTerritoryId, TopLevelTerritoryId, IsActive
FROM ServiceTerritory
WHERE TopLevelTerritoryId = :rootTerritoryId
  AND IsActive = TRUE
ORDER BY ParentTerritoryId NULLS FIRST
```

### Shifts for a Resource

```sql
SELECT Id, Label, StartTime, EndTime, Status,
       ServiceTerritory.Name
FROM Shift
WHERE ServiceResourceId = :resourceId
  AND StartTime >= :rangeStart
  AND EndTime <= :rangeEnd
ORDER BY StartTime ASC
```
