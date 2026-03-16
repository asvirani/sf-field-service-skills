---
name: sf-field-service-data-model
description: Use when working with Salesforce Field Service objects, relationships, or queries — WorkOrder, ServiceAppointment, ServiceResource, ServiceTerritory, AssignedResource, Asset, MaintenancePlan, or any FSL-related data model questions
---

# Field Service Data Model

Comprehensive reference for the Salesforce Field Service (SFS/FSL) data model — objects, relationships, fields, status lifecycles, and SOQL patterns.

## Overview

Field Service centers on a **scheduling chain**: Work Type → Work Order → Service Appointment → Assigned Resource → Service Resource. Everything else connects to this chain.

## When to Use

- Writing SOQL queries against FSL objects
- Creating/modifying FSL-related Apex, Flows, or LWC
- Building Work Order or Service Appointment automation
- Setting up Maintenance Plans or Asset hierarchies
- Debugging scheduling issues caused by missing data relationships
- Creating test data for FSL demos

## The Scheduling Chain

```
Account ← WorkOrder
              ├── WorkOrderLineItem (MD)
              ├── SkillRequirement (polymorphic)
              └── ServiceAppointment (polymorphic ParentRecordId → WO or WOLI)
                    ├── SkillRequirement (polymorphic)
                    └── AssignedResource (MD)
                          └── ServiceResource (LK)
                                ├── ServiceResourceSkill (MD) → Skill
                                ├── ServiceTerritoryMember (MD) → ServiceTerritory
                                │     └── OperatingHours → TimeSlot (MD)
                                ├── ResourceAbsence
                                └── ServiceCrewMember (MD) → ServiceCrew
```

**Supplementary:**
```
WorkType → WorkOrder / ServiceAppointment
MaintenancePlan → MaintenanceAsset → Asset → WorkOrder
ResourcePreference → WorkOrder / SA / Account
ProductRequired / ProductConsumed → WorkOrder / WOLI
```

## Quick Reference — Core Objects

| Object | API Name | Key Relationship | Notes |
|--------|----------|-----------------|-------|
| Work Order | `WorkOrder` | Parent to SA, WOLI | Central job object. Supports parent-child hierarchy. |
| Work Order Line Item | `WorkOrderLineItem` | MD to WorkOrder | Sub-tasks. Can also parent SAs. |
| Service Appointment | `ServiceAppointment` | Polymorphic `ParentRecordId` | The schedulable unit. Status drives scheduling engine. |
| Assigned Resource | `AssignedResource` | MD to SA, LK to SR | Junction. Created by scheduling engine. |
| Service Resource | `ServiceResource` | LK to User via `RelatedRecordId` | Technicians, crews, agents. Must have STM to be schedulable. |
| Service Territory | `ServiceTerritory` | Hierarchy via `ParentTerritoryId` | Geographic/logical grouping. Filtered on Gantt. |
| Territory Member | `ServiceTerritoryMember` | Double MD (SR + ST) | P/S/R types. Home base for travel calc. |
| Operating Hours | `OperatingHours` | Parent to TimeSlot | Defines availability windows. Referenced by ST and STM. |
| Skill | `Skill` | Via SkillRequirement + ServiceResourceSkill | Standard platform object. Level 0-100. |
| Resource Absence | `ResourceAbsence` | LK to ServiceResource | Blocks scheduling. Shows on Gantt. |
| Work Type | `WorkType` | LK from WO/SA | Template: duration, crew size, skills, buffer time. |
| Maintenance Plan | `MaintenancePlan` | Via MaintenanceAsset to Asset | Generates WOs on schedule. |
| Resource Preference | `ResourcePreference` | Polymorphic `RelatedRecordId` | Preferred/Required/Excluded resource. |

## Key Patterns

**Polymorphic Lookups:** SA's `ParentRecordId`, SkillRequirement's `RelatedRecordId`, ProductRequired's `ParentRecordId`, and ResourcePreference's `RelatedRecordId` are all polymorphic. Use `TYPEOF` or check `ParentRecordType` in SOQL.

**Auto-Created SAs:** When Field Service Settings "Auto-Create Service Appointment" is enabled (or `WorkType.ShouldAutoCreateSvcAppt = true`), creating a WO auto-creates an SA inheriting duration, skills, territory, and address.

**StatusCategory vs Status:** Custom statuses must map to a `StatusCategory` (None, Scheduled, Dispatched, InProgress, Completed, CannotComplete, Canceled). The scheduling engine keys off StatusCategory, not Status. Always filter by StatusCategory in automation.

**Territory Types:** P (Primary) = main territory, S (Secondary) = overflow, R (Relocation) = temporary. Resources need at least one active P membership to be schedulable.

## Detailed References

- @references/core-objects.md — Full field tables for all FSL objects
- @references/relationship-map.md — Complete relationship map with field names
- @references/soql-patterns.md — Common SOQL query patterns
- @references/gotchas.md — Data model gotchas and best practices
