---
name: sf-field-service-mobile
description: Use when building LWC for Field Service Mobile app, working with mobile capabilities (camera, barcode, GPS, NFC), creating Data Capture Flows, or handling offline-first patterns for field technicians
---

# Field Service Mobile & Data Capture

Comprehensive reference for building Lightning Web Components for the Field Service Mobile app, using mobile device capabilities, creating Data Capture Flows, and implementing offline-first patterns.

## Overview

The Field Service Mobile app is an **offline-first hybrid container** for field technicians. LWC components render inside this container with specific constraints. Data Capture Flows provide structured, mobile-optimized form collection with voice-to-form AI.

## When to Use

- Building LWC components for the Field Service Mobile app
- Using device capabilities (camera, barcode scanner, GPS, NFC)
- Creating Data Capture Flows for field data collection
- Implementing offline-capable data patterns
- Configuring Briefcase Builder for data priming
- Debugging mobile-specific rendering or sync issues

## Key Constraints

| Feature | Mobile Support |
|---------|---------------|
| `lightning-empApi` | Not supported (no WebSocket) |
| `lightning-modal` | Limited — use quick action panels |
| `NavigationMixin` | Only `standard__recordPage` + `standard__webPage` reliable |
| Imperative Apex | Online only — use LDS for offline |
| `lwc:dynamic` | Not supported |
| `lightning-file-upload` | Online only |
| `lightning-map` | Online only |

## Mobile Capabilities Quick Reference

```javascript
// All from 'lightning/mobileCapabilities'
import { getBarcodeScanner } from 'lightning/mobileCapabilities';
import { getDeviceCamera } from 'lightning/mobileCapabilities';
import { getLocationService } from 'lightning/mobileCapabilities';
import { getNfcService } from 'lightning/mobileCapabilities';

// Always check availability first
const scanner = getBarcodeScanner();
if (scanner != null && scanner.isAvailable()) { /* use it */ }
```

| Capability | Method | Returns |
|-----------|--------|---------|
| Barcode | `scanner.beginCapture(options)` | `{ value, type }` |
| Camera | `camera.captureImage(options)` | `{ base64, mimeType }` |
| GPS | `locationService.getCurrentPosition()` | `{ coords: { latitude, longitude, accuracy } }` |
| NFC | `nfc.readTag()` | `{ records: [{ tnf, type, id, payload }] }` |

## Offline-First Patterns

**Works Offline (with Briefcase priming):**
- `getRecord` / `getRecords` (LDS)
- `createRecord` / `updateRecord` / `deleteRecord` (creates drafts)
- GraphQL wire adapter (`lightning/uiGraphQLApi`)
- `getFieldValue` / `getFieldDisplayValue`

**Requires Connectivity:**
- Imperative Apex (`@wire` with Apex methods)
- `getListUi`, `getPicklistValues`
- `lightning-file-upload`, `lightning-map`
- Voice-to-form (LLM processing is server-side)

## Data Capture Flow Components

| Component | Purpose | `isLlmTargetable` |
|-----------|---------|-------------------|
| `dcText` | Single-line text | Yes |
| `dcTextArea` | Multi-line text | Yes |
| `dcNumber` | Numeric input (min/max/step) | Yes |
| `dcPicklist` | Picklist selection (single/multi) | Yes |
| `dcToggle` | Boolean toggle | Yes |
| `dcDateTime` | Date, time, or datetime | Yes |
| `dcSignature` | Signature capture | No |
| `dcImage` | Photo capture (maxCount) | No |
| `dcBarcode` | Barcode/QR scanning | No |
| `dcSection` | Collapsible group header | N/A |
| `dcRepeater` | Repeating field groups | N/A |

`isLlmTargetable="true"` enables **voice-to-form**: technician speaks, AI fills fields. Requires Einstein for Field Service license + connectivity.

## DC Flow XML Structure

```xml
<Flow xmlns="http://soap.sforce.com/2006/04/metadata">
    <processType>DataCaptureFlow</processType>
    <screens>
        <name>Screen_Name</name>
        <fields>
            <name>Field_Name</name>
            <fieldType>ComponentInstance</fieldType>
            <componentName>dcPicklist</componentName>
            <inputParameters>
                <name>label</name>
                <value><stringValue>Label</stringValue></value>
            </inputParameters>
            <isLlmTargetable>true</isLlmTargetable>
        </fields>
    </screens>
</Flow>
```

DC Flows are assigned to **Work Types** (Setup > Field Service > Work Types > Data Capture Flows). Mobile-only — cannot run on desktop.

## Detailed References

- @references/mobile-capabilities.md — Camera, barcode, GPS, NFC APIs with full code examples
- @references/offline-patterns.md — Wire adapters, GraphQL, draft records, Briefcase Builder
- @references/data-capture-components.md — All DC components with XML and properties
- @references/data-capture-flows.md — DC flow structure, deployment, voice-to-form, record mapping
- @references/mobile-lwc-patterns.md — Common mobile dev patterns (photo capture, check-in, parts consumption)
