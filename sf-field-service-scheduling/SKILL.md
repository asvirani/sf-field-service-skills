---
name: sf-field-service-scheduling
description: Use when working with Field Service scheduling — scheduling policies, work rules, service objectives, appointment booking, GetAppointmentSlots API, Gantt chart, RSO, timeslots, or programmatic scheduling via Apex
---

# Field Service Scheduling

Comprehensive reference for the Salesforce Field Service scheduling engine — scheduling policies, work rules, service objectives, appointment booking APIs, the Gantt chart, and Resource Schedule Optimization.

## Overview

The FSL scheduling engine is a **constraint-satisfaction and optimization engine**:
1. **Work Rules** (hard constraints) filter out ineligible resources/times
2. **Service Objectives** (soft constraints) score and rank remaining candidates
3. The engine selects the highest-scoring resource + time combination

## When to Use

- Configuring scheduling policies, work rules, or service objectives
- Building appointment booking flows (Experience Cloud, LWC, custom)
- Working with GetAppointmentSlots or GetAppointmentCandidates APIs
- Debugging "no slots available" or incorrect scheduling results
- Customizing the Dispatcher Console / Gantt chart
- Setting up RSO (Resource Schedule Optimization)
- Writing Apex for programmatic scheduling

## Scheduling Actions

| Action | Scope | Use Case |
|--------|-------|----------|
| **Book Appointment** | Single SA | Customer-facing. Returns time slots via API. |
| **Schedule** | Single SA | Dispatcher/automated. Finds best resource + time. |
| **Candidates** | Single SA | Returns ranked list without auto-assigning. |
| **Optimize** | Bulk | Re-shuffles scheduled SAs for efficiency. Respects pinned. |
| **RSO** | Bulk | Automated background optimization (separate license). |
| **Fill-in Schedule** | Single Resource | Fills gaps in one resource's schedule. |

## SA Status Lifecycle

```
None → Scheduled → Dispatched → In Progress → Completed
                                              → Cannot Complete
```

Key fields: `EarliestStartDate` / `DueDate` (scheduling window), `SchedStartTime` / `SchedEndTime` (actual scheduled), `ArrivalWindowStart` / `ArrivalWindowEnd` (customer-facing).

## Quick Reference — Work Rules (Hard Constraints)

| Rule Type | What It Does |
|-----------|-------------|
| Match Boolean | Checks a Boolean field on Service Resource |
| Match Fields | Compares a field on SA to a field on SR |
| Match Skills | Matches SkillRequirements against ServiceResourceSkills |
| Match Territory | Resource must be member of SA's territory |
| Match Crew Size | Ensures enough crew members available |
| Count Rule | Limits SAs per resource per time period |
| Working Territories | Restricts to resource's working territories by day/time |
| Excluded Resources | Explicitly excluded resources |
| Required Resources | Only these resources are candidates |
| SA Bundling | Controls geographic bundling of appointments |

## Quick Reference — Service Objectives (Soft Constraints)

| Objective | Scoring Behavior | Common Weight |
|-----------|-----------------|---------------|
| ASAP | Earlier slots score higher | High (7-10) for customer booking |
| Minimize Travel | Less travel = higher score | Medium-High (5-8) |
| Minimize Overtime | Penalizes overtime scheduling | Medium (4-6) |
| Preferred Resource | Boosts preferred resources | Medium (4-6) |
| Skill Level | Prefers skill level match | Low-Medium (3-5) |
| Resource Priority | Higher priority STM = higher score | Medium (4-6) |
| Custom Objective | Apex class implementing `FSL.SchedulingObjective` | Varies |

Weights are 1-10. Formula: `objective_contribution = (score × weight) / sum_of_all_weights`

## Detailed References

- @references/work-rules.md — All work rule types with configuration details
- @references/service-objectives.md — All objective types with scoring logic
- @references/appointment-booking-api.md — GetAppointmentSlots/Candidates API reference
- @references/gantt-reference.md — Dispatcher Console / Gantt chart reference
- @references/scheduling-patterns.md — Common scenarios (emergency, multi-day, crew, bundling)
- @references/apex-scheduling.md — Programmatic scheduling Apex patterns
