# FSL Relationship Map

---

## Full Scheduling Chain

```
                        ┌─────────────┐
                        │   Account   │
                        └──────┬──────┘
                               │ LK
                        ┌──────▼──────┐
                        │  WorkOrder  │◄──── Case (LK: CaseId)
                        │             │◄──── Asset (LK: AssetId)
                        │             │◄──── MaintenancePlan (LK: MaintenancePlanId)
                        │             │◄──── WorkType (LK: WorkTypeId)
                        │             │◄──── ServiceTerritory (LK: ServiceTerritoryId)
                        └──────┬──────┘
                               │
              ┌────────────────┼────────────────┐
              │ MD             │ LK (poly)       │ LK
   ┌──────────▼──────────┐    │         ┌───────▼────────┐
   │ WorkOrderLineItem   │    │         │ SkillRequirement│
   │                     │    │         └────────────────┘
   └──────────┬──────────┘    │
              │ LK (poly)     │
              ▼               ▼
        ┌─────────────────────────┐
        │   ServiceAppointment    │◄──── WorkType (LK)
        │                         │◄──── ServiceTerritory (LK)
        │   ParentRecordId (poly) │◄──── SkillRequirement (poly)
        └────────────┬────────────┘
                     │ MD
              ┌──────▼──────┐
              │ Assigned    │
              │ Resource    │
              └──────┬──────┘
                     │ LK
              ┌──────▼──────────┐
              │ ServiceResource │◄──── User (LK: RelatedRecordId)
              │                 │
              └───────┬─────────┘
                      │ MD
         ┌────────────┼────────────┐
         │            │            │
  ┌──────▼──────┐ ┌──▼────────┐ ┌─▼──────────────┐
  │  STMember   │ │ SRSkill   │ │ResourceAbsence  │
  │             │ │           │ │                 │
  └──────┬──────┘ └───────────┘ └─────────────────┘
         │ MD
  ┌──────▼──────────┐
  │ServiceTerritory │◄──── OperatingHours (LK)
  └─────────────────┘
```

## Territory & Resource Structure

```
  ┌──────────────────┐
  │ OperatingHours   │
  └────────┬─────────┘
           │ MD
     ┌─────▼─────┐
     │ TimeSlot  │  (DayOfWeek, StartTime, EndTime)
     └───────────┘

  ┌──────────────────┐         ┌──────────────────┐
  │ ServiceTerritory │◄──MD────│   STMember       │────MD──►│ ServiceResource │
  │                  │         │ TerritoryType:P/S/R│        │                 │
  │ OperatingHoursId │         │ OperatingHoursId  │        │ RelatedRecordId │──LK──► User
  └──────────────────┘         │ Home base address │        └────────┬────────┘
                               └───────────────────┘                 │
                                                              ┌──────┴──────┐
                                                              │             │
                                                     ┌────────▼───┐  ┌─────▼──────────┐
                                                     │  SRSkill   │  │ResourceAbsence │
                                                     │ SkillId    │  │ Start, End     │
                                                     │ SkillLevel │  │ FSL__Approved  │
                                                     └────────────┘  └────────────────┘
```

## Maintenance Plan Structure

```
  ┌──────────────────┐
  │ MaintenancePlan  │
  │ Frequency        │
  │ WorkTypeId       │
  └────────┬─────────┘
           │ MD
  ┌────────▼──────────┐          ┌─────────┐
  │ MaintenanceAsset  │───LK────►│  Asset  │
  │ WorkTypeId (ovr)  │          └─────────┘
  └───────────────────┘
           │
           │ generates
           ▼
  ┌──────────────────┐
  │    WorkOrder     │
  │ MaintenancePlanId│
  └──────────────────┘
```

## Crew Structure

```
  ┌──────────────┐
  │ ServiceCrew  │
  └──────┬───────┘
         │ MD
  ┌──────▼────────────┐         ┌─────────────────┐
  │ ServiceCrewMember │───LK───►│ ServiceResource  │
  │ IsLeader          │         └──────────────────┘
  │ StartDate/EndDate │
  └───────────────────┘
```

---

## Key Relationship Table

| Parent | Child | Type | Field on Child | Cascade Delete |
|--------|-------|------|----------------|----------------|
| Account | WorkOrder | Lookup | `AccountId` | No |
| Account | ServiceAppointment | Lookup | `AccountId` | No |
| Account | Asset | Lookup | `AccountId` | No |
| Account | ServiceResource | Lookup | `AccountId` | No |
| Account | MaintenancePlan | Lookup | `AccountId` | No |
| Account | ResourcePreference | Polymorphic LK | `RelatedRecordId` | No |
| Asset | WorkOrder | Lookup | `AssetId` | No |
| Asset | WorkOrderLineItem | Lookup | `AssetId` | No |
| Asset | Asset | Lookup (self) | `ParentId` | No |
| Case | WorkOrder | Lookup | `CaseId` | No |
| Contact | WorkOrder | Lookup | `ContactId` | No |
| MaintenancePlan | MaintenanceAsset | **Master-Detail** | `MaintenancePlanId` | **Yes** |
| MaintenancePlan | WorkOrder | Lookup | `MaintenancePlanId` | No |
| MaintenanceAsset | — (junction) | LK to Asset | `AssetId` | No |
| OperatingHours | TimeSlot | **Master-Detail** | `OperatingHoursId` | **Yes** |
| OperatingHours | ServiceTerritory | Lookup | `OperatingHoursId` | No |
| OperatingHours | ServiceTerritoryMember | Lookup | `OperatingHoursId` | No |
| OperatingHours | WorkType | Lookup | `OperatingHoursId` | No |
| ServiceAppointment | AssignedResource | **Master-Detail** | `ServiceAppointmentId` | **Yes** |
| ServiceCrew | ServiceCrewMember | **Master-Detail** | `ServiceCrewId` | **Yes** |
| ServiceResource | ServiceTerritoryMember | **Master-Detail** | `ServiceResourceId` | **Yes** |
| ServiceResource | ServiceResourceSkill | **Master-Detail** | `ServiceResourceId` | **Yes** |
| ServiceResource | AssignedResource | Lookup | `ServiceResourceId` | No |
| ServiceResource | ResourceAbsence | Lookup | `ResourceId` | No |
| ServiceResource | ServiceCrewMember | Lookup | `ServiceResourceId` | No |
| ServiceResource | Shift | Lookup | `ServiceResourceId` | No |
| ServiceTerritory | ServiceTerritoryMember | **Master-Detail** | `ServiceTerritoryId` | **Yes** |
| ServiceTerritory | ServiceTerritory | Lookup (self) | `ParentTerritoryId` | No |
| ServiceTerritory | ServiceAppointment | Lookup | `ServiceTerritoryId` | No |
| ServiceTerritory | WorkOrder | Lookup | `ServiceTerritoryId` | No |
| ServiceTerritory | Shift | Lookup | `ServiceTerritoryId` | No |
| Skill | SkillRequirement | Lookup | `SkillId` | No |
| Skill | ServiceResourceSkill | Lookup | `SkillId` | No |
| User | ServiceResource | Lookup | `RelatedRecordId` | No |
| WorkOrder | WorkOrderLineItem | **Master-Detail** | `WorkOrderId` | **Yes** |
| WorkOrder | ServiceAppointment | Polymorphic LK | `ParentRecordId` | No |
| WorkOrder | ProductConsumed | Lookup | `WorkOrderId` | No |
| WorkOrder | WorkOrder | Lookup (self) | `ParentWorkOrderId` | No |
| WorkOrder | SkillRequirement | Polymorphic LK | `RelatedRecordId` | No |
| WorkOrder | ProductRequired | Polymorphic LK | `ParentRecordId` | No |
| WorkOrder | ResourcePreference | Polymorphic LK | `RelatedRecordId` | No |
| WorkOrderLineItem | ServiceAppointment | Polymorphic LK | `ParentRecordId` | No |
| WorkOrderLineItem | SkillRequirement | Polymorphic LK | `RelatedRecordId` | No |
| WorkOrderLineItem | ProductRequired | Polymorphic LK | `ParentRecordId` | No |
| WorkOrderLineItem | ProductConsumed | Lookup | `WorkOrderLineItemId` | No |
| WorkType | WorkOrder | Lookup | `WorkTypeId` | No |
| WorkType | ServiceAppointment | Lookup | `WorkTypeId` | No |
| WorkType | WorkTypeGroupMember | Lookup | `WorkTypeId` | No |
| WorkTypeGroup | WorkTypeGroupMember | **Master-Detail** | `WorkTypeGroupId` | **Yes** |

---

## Polymorphic Lookup Summary

| Field | Object | Resolves To |
|-------|--------|-------------|
| `ServiceAppointment.ParentRecordId` | ServiceAppointment | WorkOrder, WorkOrderLineItem |
| `SkillRequirement.RelatedRecordId` | SkillRequirement | WorkOrder, WorkOrderLineItem, ServiceAppointment |
| `ProductRequired.ParentRecordId` | ProductRequired | WorkOrder, WorkOrderLineItem |
| `ResourcePreference.RelatedRecordId` | ResourcePreference | Account, WorkOrder, WorkOrderLineItem, ServiceAppointment |

> Use `ParentRecordType` (on SA) or `TYPEOF` in SOQL to distinguish polymorphic targets.
