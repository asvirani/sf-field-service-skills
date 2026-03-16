# Service Objectives Reference

Service objectives are scoring functions that rank valid candidates (resources + time slots) after work rules have filtered out invalid options. Each objective produces a score from 0 to 1, multiplied by its weight. The candidate with the highest total weighted score wins.

**Scoring Formula:**
```
Total Score = SUM(Objective_Score_i * Weight_i) / SUM(Weight_i)
```

## Summary Table

| Objective | API RecordType | Scores By | Default Weight |
|-----------|---------------|-----------|----------------|
| ASAP | `FSL__Objective_Asap__c` | Time slot earliness | 7 |
| Minimize Travel | `FSL__Objective_Minimize_Travel__c` | Travel time/distance | 5 |
| Minimize Overtime | `FSL__Objective_Minimize_Overtime__c` | Hours within operating hours | 3 |
| Preferred Resource | `FSL__Objective_Preferred_Resource__c` | ResourcePreference match | 5 |
| Resource Priority | `FSL__Objective_Resource_Priority__c` | STM priority ranking | 4 |
| Skill Level | `FSL__Objective_Skill_Level__c` | Skill level match quality | 3 |
| Custom Objective | `FSL__Objective_Custom__c` | Custom Apex logic | Varies |

---

## 1. ASAP

**RecordType:** `FSL__Objective_Asap__c`

**Scoring Logic:** Earlier time slots receive higher scores. The earliest available slot scores 1.0. Later slots score progressively lower based on their distance from the earliest option.

```
Score = 1 - ((SlotStart - EarliestSlotStart) / (LatestSlotEnd - EarliestSlotStart))
```

### Configuration

| Field | Description |
|-------|-------------|
| Weight | 1-10 scale. Higher = stronger preference for earliest slots |

### Recommended Weight: 6-9

### When to Use

- **High weight (8-9):** Customer-facing booking (urgent SLAs, same-day service), emergency dispatch.
- **Medium weight (5-7):** Standard scheduling where earliness matters but isn't the only factor.
- **Low weight (1-3):** Optimization scenarios where travel efficiency matters more than speed.

### Interactions

- **Conflicts with Minimize Travel**: ASAP pushes toward the earliest slot even if it means more travel. Balance carefully.
- **Complements Preferred Resource**: Schedule ASAP with the customer's preferred tech.
- In customer self-service booking, ASAP is typically the dominant objective — customers want the first available slot.

---

## 2. Minimize Travel

**RecordType:** `FSL__Objective_Minimize_Travel__c`

**Scoring Logic:** Candidates with less travel time to the appointment location score higher. Travel is calculated from the resource's previous appointment (or home base if it's the first of the day).

```
Score = 1 - (TravelTime / MaxTravelTimeAcrossCandidates)
```

### Configuration

| Field | Description |
|-------|-------------|
| Weight | 1-10 scale |

### Travel Calculation Methods

| Method | Description |
|--------|-------------|
| Straight-line (default) | Euclidean distance with speed assumption. No routing provider needed. |
| Route-based | Uses configured routing provider (e.g., Google Maps, HERE). More accurate but requires API setup. |

### Recommended Weight: 4-7

### When to Use

- **High weight (7-9):** Field service with large territories, high fuel costs, rural areas.
- **Medium weight (4-6):** Urban environments where travel differences are small but still relevant.
- **Low weight (1-3):** When SLA compliance (ASAP) outweighs travel efficiency.

### Interactions

- **Conflicts with ASAP**: The nearest resource may not have the earliest slot.
- **Complements SA Bundling work rule**: Bundled appointments already cluster geographically; Minimize Travel optimizes the route between clusters.
- Travel time affects slot availability — a 2-hour travel time eliminates slots that are too close together.

---

## 3. Minimize Overtime

**RecordType:** `FSL__Objective_Minimize_Overtime__c`

**Scoring Logic:** Penalizes scheduling beyond the resource's operating hours. Appointments fully within operating hours score 1.0. Appointments extending into overtime score lower based on the overtime proportion.

```
Score = 1 - (OvertimeMinutes / TotalAppointmentDuration)
```

### Configuration

| Field | Description |
|-------|-------------|
| Weight | 1-10 scale |

### Recommended Weight: 3-6

### When to Use

- **High weight (6-8):** Union environments, strict labor regulations, overtime cost management.
- **Medium weight (3-5):** General preference to stay within hours but flexibility when needed.
- **Low weight (1-2):** Overtime is acceptable and not a primary concern.

### Interactions

- **Depends on Operating Hours**: Resource must have Operating Hours assigned via ServiceTerritory.
- **Conflicts with ASAP**: The earliest slot might extend into overtime.
- Overtime is calculated against the `OperatingHours` on the resource's `ServiceTerritory`.

---

## 4. Preferred Resource

**RecordType:** `FSL__Objective_Preferred_Resource__c`

**Scoring Logic:** Resources with a `ResourcePreference` record of `PreferenceType = 'Preferred'` for the SA's Account or WorkOrder receive a boost. Preferred resources score 1.0; non-preferred score 0.0.

```
Score = ResourcePreference exists with PreferenceType='Preferred' ? 1.0 : 0.0
```

### Configuration

| Field | Description |
|-------|-------------|
| Weight | 1-10 scale |

### Recommended Weight: 4-7

### When to Use

- **High weight (7-9):** VIP customers, relationship-driven service, continuity of care (healthcare).
- **Medium weight (4-6):** General preference tracking, nice-to-have but not mandatory.
- **Low weight (1-3):** Preference is a tiebreaker only.

### Interactions

- **Distinct from Required Resources work rule**: Preferred is a soft preference (objective), Required is a hard filter (work rule).
- A resource can be Preferred without being Required — they get a scoring boost but others are still candidates.
- Works with `ResourcePreference` object. `PreferenceType` values: `Required`, `Preferred`, `Excluded`.

---

## 5. Resource Priority

**RecordType:** `FSL__Objective_Resource_Priority__c`

**Scoring Logic:** Uses the `FSL__Priority__c` field on `ServiceTerritoryMember` to rank resources. Lower priority number = higher score.

```
Score = 1 - ((ResourcePriority - MinPriority) / (MaxPriority - MinPriority))
```

### Configuration

| Field | Description |
|-------|-------------|
| Weight | 1-10 scale |

### Recommended Weight: 3-5

### When to Use

- **High weight (6-8):** Tiered workforce — senior techs first, junior as backup.
- **Medium weight (3-5):** General ranking to prefer experienced resources.
- **Low weight (1-2):** Priority is informational, not a strong scheduling factor.

### Interactions

- Priority is set per territory membership, not globally. A resource can be priority 1 in their primary territory and priority 5 in a secondary territory.
- **Complements Match Territory work rule**: Filter to territory first, then rank by priority within territory.

---

## 6. Skill Level

**RecordType:** `FSL__Objective_Skill_Level__c`

**Scoring Logic:** Prefers resources whose `ServiceResourceSkill.SkillLevel` most closely matches (or exceeds) the `SkillRequirement.SkillLevel`. Exact match or highest skill level scores highest.

```
Score = ResourceSkillLevel / MaxSkillLevelAcrossCandidates
```

### Configuration

| Field | Description |
|-------|-------------|
| Weight | 1-10 scale |

### Recommended Weight: 2-5

### When to Use

- **High weight (5-7):** Quality-critical work, specialized repairs, regulatory requirements.
- **Medium weight (3-4):** General preference for skilled resources.
- **Low weight (1-2):** Skill presence matters (via work rule) but level is a tiebreaker.

### Interactions

- **Requires Match Skills work rule**: The work rule filters out unqualified resources; this objective ranks the qualified ones.
- Without the Match Skills work rule, this objective has no effect — it only scores candidates who have skills to compare.
- Consider whether you want the MOST skilled resource or an ADEQUATE resource. High Skill Level weight + low ASAP weight sends your best tech every time, which may not be efficient.

---

## 7. Custom Objective

**RecordType:** `FSL__Objective_Custom__c`

**Scoring Logic:** Executes a custom Apex class implementing the `FSL.SchedulingObjective` interface. Returns a score between 0 and 1.

### Interface

```apex
global interface SchedulingObjective {
    Decimal getScore(
        ServiceAppointment sa,
        ServiceResource sr,
        Datetime startTime,
        Datetime endTime
    );
}
```

### Implementation Example

```apex
global class ProximityToWarehouseObjective implements FSL.SchedulingObjective {
    global Decimal getScore(
        ServiceAppointment sa,
        ServiceResource sr,
        Datetime startTime,
        Datetime endTime
    ) {
        // Custom logic — return 0.0 to 1.0
        Location saLoc = Location.newInstance(sa.Latitude, sa.Longitude);
        Location warehouseLoc = Location.newInstance(37.7749, -122.4194);
        Double distance = Location.getDistance(saLoc, warehouseLoc, 'mi');

        Double maxDistance = 50.0;
        Decimal score = Math.max(0, 1 - (distance / maxDistance));
        return score;
    }
}
```

### Configuration

| Field | Description |
|-------|-------------|
| `FSL__Apex_Class__c` | Fully qualified class name |
| Weight | 1-10 scale |

### When to Use

- Business-specific scoring logic not covered by standard objectives.
- Proximity to inventory warehouses, customer tier scoring, time-of-day preferences.
- Integration with external systems for dynamic scoring.

### Gotchas

- Custom objectives execute for every candidate evaluation. Keep logic fast — no callouts, no heavy queries.
- Governor limits apply across all evaluations in the transaction.
- Return value must be between 0.0 and 1.0. Values outside this range cause errors.

---

## Weighting Best Practices

### Weight Scale

| Weight | Meaning |
|--------|---------|
| 1-2 | Tiebreaker only |
| 3-4 | Moderate influence |
| 5-6 | Strong influence |
| 7-8 | Dominant factor |
| 9-10 | Override — this objective drives the decision |

### Strategy Profiles

#### Customer First (SLA-driven, customer satisfaction priority)

| Objective | Weight | Rationale |
|-----------|--------|-----------|
| ASAP | 9 | Earliest possible appointment |
| Preferred Resource | 6 | Customer continuity |
| Minimize Travel | 5 | Reasonable routes |
| Skill Level | 3 | Adequate skill |
| Resource Priority | 2 | Tiebreaker |
| Minimize Overtime | 2 | Acceptable if needed |

#### Efficiency First (cost optimization, fleet management)

| Objective | Weight | Rationale |
|-----------|--------|-----------|
| Minimize Travel | 9 | Route efficiency |
| Minimize Overtime | 7 | Labor cost control |
| Resource Priority | 5 | Use junior resources when possible |
| ASAP | 4 | Within SLA but not urgently |
| Skill Level | 3 | Adequate skill |
| Preferred Resource | 2 | Nice to have |

#### Quality First (specialized work, compliance)

| Objective | Weight | Rationale |
|-----------|--------|-----------|
| Skill Level | 8 | Best qualified resource |
| Preferred Resource | 7 | Known expert for the customer |
| ASAP | 5 | Timely but quality over speed |
| Resource Priority | 5 | Senior resources preferred |
| Minimize Travel | 3 | Willing to travel for quality |
| Minimize Overtime | 3 | Flexible hours for the right tech |

#### Balanced (general field service)

| Objective | Weight | Rationale |
|-----------|--------|-----------|
| ASAP | 7 | Timely service |
| Minimize Travel | 6 | Efficient routing |
| Skill Level | 4 | Right skills |
| Preferred Resource | 4 | Customer preference |
| Minimize Overtime | 4 | Cost awareness |
| Resource Priority | 3 | Resource ranking |

### Key Principles

1. **Don't set everything to 10.** If all objectives have the same weight, none of them matter differentially. Create contrast.
2. **Pick 1-2 dominant objectives** (weight 7+) and let the rest be modifiers.
3. **Test with real data.** Theoretical weights often need adjustment after seeing scheduling results.
4. **Different policies for different scenarios.** Don't force one policy to handle emergency dispatch and routine maintenance.
5. **ASAP + Minimize Travel is the most common tension.** Decide which matters more for each use case and weight accordingly.
