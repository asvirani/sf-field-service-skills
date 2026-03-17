# Mobile UX Guide for Field Service Data Capture Forms

Best practices for designing data capture flows that work well on the Field Service mobile app.

## Device Context

Field technicians use these flows on:
- **Phones** (5-7" screens) — most common
- **Tablets** (10-12" screens) — sometimes
- **Offline** — connectivity may be intermittent
- **One-handed** — often holding tools in the other hand
- **Outdoor** — bright sunlight, glare on screen
- **Gloves** — may use thick work gloves (larger tap targets)

## Screen Design Rules

### Fields Per Screen

| Screen Size | Max Fields | Guideline |
|-------------|------------|-----------|
| Phone | 5-7 | Minimize scrolling |
| Tablet | 8-10 | Still group logically |

**Why**: A technician standing on a ladder shouldn't have to scroll through 20 fields. Break the form into logical sections.

### Field Ordering

1. **Required fields first** — get critical data before optional
2. **Logical grouping** — equipment info together, safety checks together
3. **Most common answers first** in picklists — "Pass" before "Fail" if most items pass
4. **Pre-populate when possible** — use context from Work Order

### Labels

| Do | Don't |
|----|-------|
| "Serial #" | "Please enter the serial number of the equipment" |
| "Condition" | "What is the current condition of the unit?" |
| "PSI Reading" | "Pressure reading in pounds per square inch" |

Keep labels under 30 characters. Use help text for longer explanations.

## Navigation

### Button Behavior

| Screen Position | allowBack | Rationale |
|-----------------|-----------|-----------|
| First screen | `false` | Nothing to go back to |
| Middle screens | `true` | Let technicians review/correct |
| Final screen (pre-submit) | `true` | Review before finishing |

### Progress Awareness

For forms with 3+ screens, include a section header showing context:

```xml
<fields>
    <name>Display_Progress</name>
    <fieldType>DisplayText</fieldType>
    <fieldText>&lt;p&gt;&lt;span style="color: rgb(68, 68, 68);"&gt;Section 2 of 4: Equipment Details&lt;/span&gt;&lt;/p&gt;</fieldText>
</fields>
```

## Field Type Selection for Mobile

### Prefer Radio Buttons over Dropdowns (2-5 options)

Radio buttons show all options at once — fewer taps, faster completion. Use dropdowns only when options exceed 5.

### Prefer Checkboxes for Yes/No

Boolean checkboxes are a single tap. Avoid radio buttons with "Yes" / "No" options.

### Use Large Text Area Sparingly

Mobile keyboards are slow. Use long text only for genuinely free-form fields like "Additional Notes". For structured data, use selection fields.

### Date Pickers

`dataType: Date` and `dataType: DateTime` trigger native mobile date/time pickers. Don't use text fields for dates.

## Voice-to-Form (LLM Access)

When `isLlmAccessEnabled` is true, technicians can tap the microphone icon and dictate responses. The LLM maps speech to form fields.

### Optimizing for Voice

1. **Use distinct field labels** — "Equipment Serial Number" not just "Number" (avoids ambiguity)
2. **Avoid similar field names** on the same screen — the LLM needs to distinguish fields
3. **Use descriptive choice labels** — "Pass - Meets all requirements" helps LLM match
4. **Keep screens focused** — fewer fields per screen = better voice accuracy

## Offline Considerations

Data capture flows work offline in Field Service Mobile. Key constraints:

- **No record lookups** to server data while offline
- **No Apex actions** while offline
- Collected data is **queued and synced** when connectivity returns
- Keep the flow self-contained: don't depend on real-time server queries

## Accessibility

- Use sufficient color contrast in DisplayText HTML
- Don't rely solely on color to convey meaning (e.g., red for fail)
- Include text labels with any visual indicators
- Help text should clarify, not repeat the label

## Common Patterns

### Inspection Checklist Pattern

Each checklist item as Pass/Fail/NA radio buttons, followed by a conditional notes field:

```
Screen: Safety Checks
├── PPE Worn: [Pass] [Fail] [N/A]
├── Area Secured: [Pass] [Fail] [N/A]
├── Equipment Inspected: [Pass] [Fail] [N/A]
└── Notes: [____________]
```

### Readings / Measurements Pattern

Numeric inputs with units in the label:

```
Screen: Equipment Readings
├── Temperature (°F): [___]
├── Pressure (PSI): [___]
├── Voltage (V): [___]
└── Current (A): [___]
```

### Sign-Off Pattern

Confirmation at the end of the form:

```
Screen: Completion
├── Technician Name: [____________]
├── Date Completed: [📅]
├── ☑ I confirm this information is accurate
└── [Finish]
```
