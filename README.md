# Salesforce Field Service Skills for Claude Code

Developer reference skills for [Claude Code](https://docs.anthropic.com/en/docs/build-with-claude/claude-code/overview) that provide comprehensive Salesforce Field Service (SFS/FSL) knowledge — data model, scheduling engine, and mobile development.

> **Includes SDO custom field mappings** — These skills ship with custom field references pulled from a live SFS Sales Demo Org, covering 195+ custom fields across WorkOrder, ServiceAppointment, ServiceResource, Asset, and more. SEs get out-of-the-box awareness of demo-specific fields like depot repair status, optimization KPIs, contractor management, and Why Not scheduling analysis.

## What Are Skills?

Skills are structured reference documents that Claude Code loads into context when relevant to your task. They give Claude deep domain knowledge so it can write better code, debug faster, and provide accurate guidance without you needing to look up documentation.

When you're writing a SOQL query against `ServiceAppointment`, building a scheduling policy, or creating a Data Capture Flow, Claude automatically loads the relevant skill and has the full reference at hand.

## Skills Included

### sf-field-service-data-model

The complete FSL data model — objects, relationships, fields, status lifecycles, and SOQL patterns.

**Triggers when you:**
- Write SOQL queries against FSL objects (WorkOrder, ServiceAppointment, ServiceResource, etc.)
- Create Apex, Flows, or LWC that interact with FSL objects
- Build Work Order or Service Appointment automation
- Set up Maintenance Plans or Asset hierarchies
- Create test data for FSL demos

**Reference files:**
| File | Contents |
|------|----------|
| `core-objects.md` | Full field tables for 20+ FSL objects |
| `relationship-map.md` | Complete relationship map with field names and cascade behavior |
| `soql-patterns.md` | 10 common SOQL query patterns, copy-paste ready |
| `gotchas.md` | 12 data model gotchas and best practices |
| `sdo-custom-fields.md` | 195+ SDO custom fields across all FSL objects with demo scenario mapping |

---

### sf-field-service-scheduling

The FSL scheduling engine — policies, work rules, service objectives, appointment booking APIs, Gantt chart, and RSO.

**Triggers when you:**
- Configure scheduling policies, work rules, or service objectives
- Build appointment booking flows (Experience Cloud, LWC, custom)
- Work with GetAppointmentSlots or GetAppointmentCandidates APIs
- Debug scheduling issues ("no slots available", incorrect results)
- Customize the Dispatcher Console / Gantt chart
- Write Apex for programmatic scheduling

**Reference files:**
| File | Contents |
|------|----------|
| `work-rules.md` | All 10 work rule types with configuration details |
| `service-objectives.md` | All objective types with scoring logic and weight strategies |
| `appointment-booking-api.md` | GetAppointmentSlots/Candidates REST + Apex API reference |
| `gantt-reference.md` | Dispatcher Console architecture, actions, customization |
| `scheduling-patterns.md` | 9 common scenarios (emergency, multi-day, crew, bundling, etc.) |
| `apex-scheduling.md` | Programmatic scheduling Apex patterns with code examples |

---

### sf-field-service-mobile

Field Service Mobile LWC development, device capabilities, Data Capture Flows, and offline-first patterns.

**Triggers when you:**
- Build LWC components for the Field Service Mobile app
- Use device capabilities (camera, barcode scanner, GPS, NFC)
- Create Data Capture Flows for field data collection
- Implement offline-capable data patterns
- Configure Briefcase Builder for data priming

**Reference files:**
| File | Contents |
|------|----------|
| `mobile-capabilities.md` | Camera, barcode, GPS, NFC APIs with complete code examples |
| `offline-patterns.md` | Wire adapter offline support matrix, Briefcase Builder, draft records |
| `data-capture-components.md` | All DC components (dcSignature, dcImage, dcBarcode, etc.) with XML |
| `data-capture-flows.md` | DC flow structure, deployment, voice-to-form, record mapping |
| `mobile-lwc-patterns.md` | Common mobile patterns (photo capture, check-in, parts consumption) |

---

### sf-fs-datacapture

Converts images or PDFs of existing paper/digital forms into deployable Data Capture Flow XML. Share a picture of a form, get a mobile-optimized flow.

*Originally from [tgmielke/sfs-skills](https://github.com/tgmielke/sfs-skills) — credit to Tyler Mielke.*

**Triggers when you:**
- Share an image or PDF of a paper form, inspection checklist, or safety form
- Ask to convert a form into a Data Capture Flow
- Build DC flows for field technicians
- Need mobile-optimized form XML with voice-to-form support

**Reference files:**
| File | Contents |
|------|----------|
| `data-capture-flow-template.xml` | Base XML template for DataCaptureFlow |
| `field-type-mapping.md` | Document field → DC component mapping reference |
| `mobile-ux-guide.md` | Field Service mobile UX best practices |
| `example-safety-hazard-check.xml` | Multi-select checklists, photo patterns |
| `example-customer-interaction.xml` | Signature capture, satisfaction survey |
| `example-nas-demarc-validation.xml` | Multi-screen, conditional visibility |

**Key features:**
- Auto-population from Work Order context (Account, Contact, Asset)
- Voice-to-form via `IsLlmTargetable`
- Known limitation handling (no inline photo upload in DC flows)
- Offline-ready (`environments: Offline`)

## Installation

### One-Line Install (Recommended)

```bash
curl -sSL https://raw.githubusercontent.com/asvirani/sf-field-service-skills/main/install.sh | bash
```

Or with wget:

```bash
wget -qO- https://raw.githubusercontent.com/asvirani/sf-field-service-skills/main/install.sh | bash
```

Auto-detects Claude Code, Cursor, and Windsurf — installs to all detected IDEs.

### Manual Install

```bash
git clone https://github.com/asvirani/sf-field-service-skills.git
cp -r sf-field-service-skills/sf-field-service-data-model ~/.claude/skills/
cp -r sf-field-service-skills/sf-field-service-scheduling ~/.claude/skills/
cp -r sf-field-service-skills/sf-field-service-mobile ~/.claude/skills/
cp -r sf-field-service-skills/sf-fs-datacapture ~/.claude/skills/
```

### Verify Installation

After installing, start a new Claude Code session and ask:

> "What objects are in the Field Service data model?"

Claude should reference the skill and provide detailed information from the reference files.

## Usage Examples

### Data Model

Ask Claude to write SOQL queries:
> "Write a SOQL query to get all scheduled appointments this week with their assigned resources and travel times."

### Scheduling

Ask about scheduling configuration:
> "Set up a scheduling policy for customer-facing appointment booking that prioritizes ASAP scheduling and minimizes travel."

Ask for Apex scheduling code:
> "Write an Apex class that programmatically schedules a Service Appointment using the Customer First policy."

### Mobile

Ask for mobile LWC code:
> "Build an LWC quick action that scans a barcode and looks up the matching Asset, works offline."

Ask about Data Capture Flows:
> "Create a Data Capture Flow XML for an equipment inspection with photo capture, condition picklist, meter reading, and customer signature."

## SDO (Sales Demo Org) Support

These skills include **SDO-specific custom field references** pulled from a live SFS demo org. This gives Claude awareness of:

- **42 custom WorkOrder fields** — payment collection, depot repair, inspection checklists, opportunity linking
- **89 custom ServiceAppointment fields** — FSL managed package scheduling fields, FSSK starter kit fields, Why Not analysis, contractor management, real-time tracking
- **31 custom ServiceResource fields** — contractor management, optimization KPIs, travel tracking, en-route location
- **33 custom Asset fields** — performance metrics (MTTR/MTBF), warranty status, IoT usage data
- Plus custom fields on ServiceTerritory, ServiceTerritoryMember, ResourceAbsence, and MaintenancePlan

Each skill's SKILL.md includes a quick reference table of the most relevant SDO fields for that domain, with full details in `sf-field-service-data-model/references/sdo-custom-fields.md`.

### Demo Scenario Quick Reference

| Scenario | Key SDO Fields |
|----------|---------------|
| Depot Repair | `Depot_Repair_Status__c`, `Expected_Completion_Date__c` |
| Payment Collection | `Amount__c`, `Payme__c`, `Payment_received__c` |
| Emergency Dispatch | `FSL__Emergency__c`, `FSL__Schedule_over_lower_priority_appointment__c` |
| Contractor Management | `Requires_Contractor__c`, `Is_Contractor__c` |
| Real-Time Tracking | `Running_Late_in_mins__c`, `En_Route_Location__c` |
| Optimization ROI | `Travel_Savings__c`, `Travel_Delta__c`, `Optimization_Revenue__c` |
| Asset Performance | `Asset_Availability__c`, `Average_Time_Between_Failures__c` |

## Compatibility

- **Claude Code**: Full support (primary target)
- **Salesforce Field Service**: Based on API v59.0+ (Winter '24 through Spring '26)
- **FSL Managed Package**: Compatible with current versions
- **Data Capture Flows**: Spring '24+ feature

## Contributing

Contributions are welcome. If you find inaccuracies or want to add coverage for new FSL features:

1. Fork the repo
2. Create a feature branch
3. Update the relevant reference files
4. Submit a PR with a description of what changed and why

### Guidelines

- Keep SKILL.md files concise (loaded into context on every trigger)
- Put detailed content in `references/` files
- Use tables and code blocks — no narrative prose
- Include copy-paste-ready code examples
- Note any Salesforce release version dependencies

## License

MIT License. See [LICENSE](LICENSE) for details.

## Author

**Armaan Virani** — Lead Solutions Engineer, Salesforce Healthcare & Life Sciences

Built with [Claude Code](https://docs.anthropic.com/en/docs/build-with-claude/claude-code/overview) and the [Superpowers](https://github.com/Shopify/superpower-prompts) skill framework.
