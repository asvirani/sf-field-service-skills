# Offline-First Development Patterns

## Wire Adapter Offline Support Matrix

| Wire Adapter / Function | Works Offline | Notes |
|---|---|---|
| `getRecord` / `getRecords` | YES | Records must be in Briefcase |
| `createRecord` | YES | Creates draft records with temp IDs |
| `updateRecord` | YES | Creates draft updates |
| `deleteRecord` | YES | Creates draft deletes |
| `getFieldValue` / `getFieldDisplayValue` | YES | Operates on cached records |
| `getRecordCreateDefaults` | YES | Cached after first online load |
| `GraphQL wire adapter` | YES | Primed data only (Spring '24+) |
| `getListUi` | NO | Requires server |
| `getPicklistValues` | NO | Briefly cached; unreliable offline |
| `getPicklistValuesByRecordType` | NO | Briefly cached; unreliable offline |
| `getObjectInfo` | Partial | Cached after first online load |
| Imperative Apex | NO | Always requires server roundtrip |
| `getRelatedListRecords` | NO | Requires server |

**Rule of thumb:** If it's in `lightning/uiRecordApi`, it likely works offline. If it requires Apex or list-based adapters, it does not.

---

## Briefcase Builder

### Configuration

**Setup > Field Service > Briefcase Builder**

Briefcase defines which records are downloaded to the mobile device for offline access.

### Briefcase Rules

Each rule specifies:
- **Object** — The SObject to prime
- **Filters** — Field-based criteria (e.g., `Status != 'Completed'`)
- **Related Records** — Child/parent records to include

### Key Objects to Prime

| Object | Why |
|---|---|
| `ServiceAppointment` | Primary work unit for technicians |
| `WorkOrder` | Parent record with job details |
| `WorkOrderLineItem` | Individual tasks within a Work Order |
| `Asset` | Equipment being serviced |
| `ServiceResource` | The technician's own record |
| `Product2` | Parts catalog for consumption |
| `ProductItem` | Inventory at locations |
| `Contact` | Customer contact info |
| `Account` | Customer account details |
| `ContentVersion` | Attachments, photos, documents |

### Sync Triggers

| Trigger | Description |
|---|---|
| Foreground (pull-to-refresh) | User manually triggers sync |
| Background (periodic) | App syncs periodically when connected |
| Navigation-based | Sync on record open when online |

### Briefcase Best Practices

- Keep record counts manageable — large briefcases slow sync
- Filter aggressively (e.g., only today's + tomorrow's appointments)
- Include all lookup/parent records referenced by primed children
- Test sync time on real devices with production-scale data

---

## Draft Records

### How Drafts Work

When a user creates or updates a record offline, the Field Service mobile app creates a **draft record**.

| Behavior | Detail |
|---|---|
| Temporary IDs | Offline-created records get a temporary client-side ID |
| Draft indicator | UI shows a draft badge on unsaved records |
| Sync on reconnect | Drafts auto-sync when connectivity is restored |
| Conflict resolution | Default: last-write-wins |
| Failure handling | Failed syncs surface errors to the user |

### Conflict Detection

```javascript
import { getRecordNotifyChange } from 'lightning/uiRecordApi';

// After detecting a potential conflict, force LDS cache refresh
getRecordNotifyChange([{ recordId: this.recordId }]);
```

### Draft-Aware Code Patterns

```javascript
// Temporary IDs start with a specific prefix when offline
// Do NOT hardcode checks against ID format — use LDS status instead

// Safe pattern: always use LDS functions
import { createRecord, updateRecord } from 'lightning/uiRecordApi';

// These automatically create drafts when offline
// and sync when back online — no special handling needed
```

---

## GraphQL Wire Adapter for Offline

The GraphQL wire adapter works offline against primed (Briefcase) data starting Spring '24.

### Complete Example — Query Service Appointments Offline

```javascript
import { LightningElement, wire } from 'lwc';
import { gql, graphql } from 'lightning/uiGraphQLApi';

export default class OfflineAppointmentList extends LightningElement {
    appointments;
    errors;

    @wire(graphql, {
        query: gql`
            query GetMyAppointments {
                uiapi {
                    query {
                        ServiceAppointment(
                            where: {
                                Status: { in: ["Dispatched", "In Progress"] }
                            }
                            orderBy: { SchedStartTime: { order: ASC } }
                            first: 50
                        ) {
                            edges {
                                node {
                                    Id
                                    AppointmentNumber { value }
                                    Status { value }
                                    SchedStartTime { value }
                                    SchedEndTime { value }
                                    Street { value }
                                    City { value }
                                    State { value }
                                    PostalCode { value }
                                    ParentRecord {
                                        ... on WorkOrder {
                                            Subject { value }
                                            Priority { value }
                                            WorkOrderNumber { value }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        `,
        variables: {}
    })
    wiredAppointments({ data, errors }) {
        if (data) {
            this.appointments = data.uiapi.query.ServiceAppointment.edges.map(
                (edge) => edge.node
            );
            this.errors = undefined;
        }
        if (errors) {
            this.errors = errors;
            this.appointments = undefined;
        }
    }
}
```

### GraphQL Offline Rules

| Feature | Offline Support |
|---|---|
| Basic queries | YES (primed data) |
| `where` filters | YES (client-side filtering) |
| `orderBy` | YES (client-side sorting) |
| `first` / pagination | YES |
| Relationships (parent) | YES (if parent is primed) |
| Aggregate queries | NO |
| Mutations | NO (use `createRecord`/`updateRecord`) |

---

## Offline Design Principles

### 1. Use LDS, Not Apex

```javascript
// CORRECT — works offline
import { getRecord, updateRecord } from 'lightning/uiRecordApi';

// WRONG — fails offline
import getAppointment from '@salesforce/apex/AppointmentController.getAppointment';
```

### 2. Configure Briefcase Thoroughly

Every record your LWC might access offline must be in the Briefcase. Missing records = blank screens offline.

### 3. Handle Network State Changes

```javascript
// Check online status
const isOnline = navigator.onLine;

// Listen for changes
window.addEventListener('online', () => {
    // Refresh data, trigger sync
});

window.addEventListener('offline', () => {
    // Disable server-dependent features
    // Show offline indicator
});
```

### 4. Test on Physical Devices

| Test Scenario | Method |
|---|---|
| Full offline | Enable airplane mode after sync |
| Spotty connectivity | Walk through low-signal areas |
| Sync conflicts | Edit same record on two devices |
| Large data volumes | Load production-scale briefcase |
| Cold start offline | Kill app, reopen in airplane mode |

### 5. Degrade Gracefully

```javascript
// Pattern: feature detection with fallback
async handleAction() {
    try {
        // Try server-dependent operation
        const result = await someApexCall();
        this.processResult(result);
    } catch (error) {
        if (!navigator.onLine) {
            // Queue for later or use cached data
            this.showOfflineMessage();
        } else {
            this.handleError(error);
        }
    }
}
```

### 6. Minimize Payload Size

- Compress images before storing (`quality: 50-70`)
- Limit file attachments to what's necessary
- Use field lists in `getRecord` — don't pull all fields
- Keep Briefcase filters tight

---

## Offline-Capable LWC Template

```javascript
import { LightningElement, api, wire } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import SA_STATUS from '@salesforce/schema/ServiceAppointment.Status';
import SA_SUBJECT from '@salesforce/schema/ServiceAppointment.Subject';

const FIELDS = [SA_STATUS, SA_SUBJECT];

export default class OfflineCapableComponent extends LightningElement {
    @api recordId;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    appointment;

    get status() {
        return getFieldValue(this.appointment.data, SA_STATUS);
    }

    get subject() {
        return getFieldValue(this.appointment.data, SA_SUBJECT);
    }

    async handleUpdate() {
        const fields = {
            Id: this.recordId,
            [SA_STATUS.fieldApiName]: 'Completed'
        };

        try {
            // Works online AND offline (creates draft when offline)
            await updateRecord({ fields });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Record updated.',
                    variant: 'success'
                })
            );
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error.body?.message || 'Update failed.',
                    variant: 'error'
                })
            );
        }
    }
}
```
