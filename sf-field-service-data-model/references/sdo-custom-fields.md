# SDO Custom Fields Reference

Custom fields found in the Salesforce Field Service SDO (Sales Demo Org). These extend the standard FSL objects with demo-specific, managed package, and business logic fields.

Fields are categorized as:
- **FSL Managed** (`FSL__*`) — Installed by the Field Service managed package. Present in all FSL orgs.
- **FSSK** (`FSSK__*`) — Field Service Starter Kit fields. Common in SDO and demo orgs.
- **SDO Demo** (`SDO_*`, `FSLDemoTools_*`, `SDO_Tool_*`) — SDO demo tooling fields for demo data management.
- **Business** — Custom fields representing real-world business scenarios for demos.

---

## WorkOrder Custom Fields (42)

### Business / Demo Scenario Fields

| API Name | Type | Label | Description |
|----------|------|-------|-------------|
| `Accept_Reject__c` | Picklist | Accept/Reject | Values: Accept, Reject. Work order acceptance workflow. |
| `Amount_Collected__c` | Text | Amount Collected | Payment amount collected on-site. |
| `Amount__c` | Currency | Amount (Payment) | Payment amount for the work order. |
| `Comments_on_service_appointment__c` | TextArea | Comments on service appointment | Free-text comments from SA. |
| `Customer_Remarks__c` | TextArea | Customer Remarks | Customer feedback/comments. |
| `Date_Of_Purchase__c` | Date | Date Of Purchase | Original purchase date of serviced product. |
| `Depot_Repair_Status__c` | Picklist | Depot Repair Status | Values: Received, In Repair, Repaired, Shipped. For depot repair demos. |
| `Engineer_Remarks__c` | TextArea | Engineer Remarks | Technician notes/remarks. |
| `Expected_Completion_Date__c` | Date | Expected Completion Date | Expected depot repair completion. |
| `External_ID__c` | Text | External ID | External system integration key. |
| `Inventory_Check__c` | Text | Inventory Check | Inventory verification field. |
| `Model_Number__c` | Text | Model Number | Product model number. |
| `Operation_Code__c` | Text | Operation Code | Service operation code. |
| `Opportunity__c` | Lookup(Opportunity) | Opportunity | Links WO to a sales opportunity (upsell demos). |
| `Order__c` | Lookup(Order) | Order | Links WO to an order record. |
| `PO_Number__c` | Text | PO Number | Purchase order number. |
| `Payme__c` | Picklist | Payment Mode | Values: Cash, Card, Online, Check. Payment method. |
| `Payment_received__c` | Boolean | Payment received | Whether payment has been collected. |
| `Product_Code__c` | Text | Product Code | Product identifier. |
| `Satisfied__c` | Boolean | Satisfied | Customer satisfaction indicator. |
| `Send_Payment__c` | Boolean | Send Payment | Trigger to send payment request. |
| `Serial_Number__c` | Text | Serial Number | Equipment serial number. |
| `Serviced__c` | Boolean | Serviced | Whether the equipment has been serviced. |
| `Total_Price_Consumed_Products__c` | Currency | Total Price (Consumed Products) | Roll-up of consumed product costs. |
| `Transaction_Id__c` | Text | Transaction Id | Payment transaction reference. |
| `UCC_Code__c` | Text | UCC Code | Universal Commercial Code. |
| `Work_Order_Type__c` | Picklist | Work Order Type | Values: Standard, Emergency, Preventive, etc. |
| `Work_Start__c` | DateTime | Work Start | Actual work start timestamp. |
| `Work_End__c` | DateTime | Work End | Actual work end timestamp. |

### Checklist / Inspection Booleans

| API Name | Type | Label | Description |
|----------|------|-------|-------------|
| `Coolant__c` | Boolean | Coolant | Coolant check completed. |
| `Cooling__c` | Boolean | Cooling | Cooling system check completed. |
| `FW__c` | Boolean | FW | Firmware check completed. |

### Context / Formula Fields

| API Name | Type | Label | Description |
|----------|------|-------|-------------|
| `Current_Users_Work_Order__c` | Boolean | Current User's Work Order | Formula: true if running user owns this WO. |
| `DB_Days__c` | Number | DB Days | Calculated days for demo data aging. |
| `Entitlement_Is_Active__c` | Boolean | Entitlement Is Active | Formula: checks entitlement status. |
| `FSL_Is_Linked_To_Maintenance_Plan__c` | Boolean | Is Linked To Maintenance Plan | Formula: true if WO has a MaintenancePlan. |
| `FSL_Is_Linked_To_Service_Contract__c` | Boolean | Is Linked To Service Contract | Formula: true if WO has a ServiceContract. |
| `temp_work_time__c` | DateTime | temp work time | Temporary calculation field. |

### FSL Managed Package Fields

| API Name | Type | Label | Description |
|----------|------|-------|-------------|
| `FSL__IsFillInCandidate__c` | Boolean | Is Fill In Candidate | SA is eligible for fill-in scheduling. |
| `FSL__Prevent_Geocoding_For_Chatter_Actions__c` | Boolean | Prevent Geocoding For Chatter Actions | Internal optimization flag. |
| `FSL__Scheduling_Priority__c` | Number | Scheduling Priority | Priority value for scheduling engine (lower = higher priority). |
| `FSL__VisitingHours__c` | Lookup(OperatingHours) | Visiting Hours | Customer visiting hours constraint for scheduling. |

---

## ServiceAppointment Custom Fields (89)

### FSL Managed Package Fields (Critical for Scheduling)

| API Name | Type | Label | Description |
|----------|------|-------|-------------|
| `FSL__Auto_Schedule__c` | Boolean | Auto Schedule | Enable automatic scheduling for this SA. |
| `FSL__Emergency__c` | Boolean | Emergency | Marks SA as emergency — bypasses normal rules. |
| `FSL__Pinned__c` | Boolean | Pinned | Pinned SAs are NOT moved by Optimize/RSO. |
| `FSL__InJeopardy__c` | Boolean | In Jeopardy | SA is at risk of missing SLA. |
| `FSL__InJeopardyReason__c` | Picklist | In Jeopardy Reason | Values: Delayed Start, Technician Running Late, Parts Unavailable. |
| `FSL__IsMultiDay__c` | Boolean | Is MultiDay | SA spans multiple calendar days. |
| `FSL__Same_Day__c` | Boolean | Same Day | Must be completed same day as started. |
| `FSL__Same_Resource__c` | Boolean | Same Resource | Same resource must handle all related SAs. |
| `FSL__Schedule_Mode__c` | Picklist | Schedule Mode | Values: Manual, Automatic. Controls scheduling behavior. |
| `FSL__Schedule_over_lower_priority_appointment__c` | Boolean | Schedule Over Lower Priority | Can bump lower priority appointments. |
| `FSL__Scheduling_Policy_Used__c` | Lookup | Scheduling Policy Used | Which policy scheduled this SA. |
| `FSL__Time_Dependency__c` | Picklist | Time Dependency | Values: Same Start, Same End, Start After End. For linked SAs. |
| `FSL__Appointment_Grade__c` | Number | Appointment Grade | Scheduling quality score (0-100). |
| `FSL__Duration_In_Minutes__c` | Number | Scheduled Duration | Calculated duration in minutes. |
| `FSL__UpdatedByOptimization__c` | Boolean | UpdatedByOptimization | Set when RSO/Optimize modifies this SA. |
| `FSL__Related_Service__c` | Lookup(ServiceAppointment) | Related Service | Links dependent SAs. |
| `FSL__Use_Async_Logic__c` | Boolean | Use Async Logic | Enable async processing for this SA. |
| `FSL__IsFillInCandidate__c` | Boolean | Is Fill In Candidate | Eligible for fill-in scheduling. |
| `FSL__MDS_Calculated_length__c` | Number | Multiday Work Calculated length | Multi-day span in days. |
| `FSL__MDT_Operational_Time__c` | TextArea | Multiday Work Operational Time | Operational time JSON for multi-day. |
| `FSL__Last_Updated_Epoch__c` | Number | Last Updated Epoch | Internal timestamp for sync. |

### Gantt Display Fields

| API Name | Type | Label | Description |
|----------|------|-------|-------------|
| `FSL__GanttColor__c` | Text | Gantt Color | Hex color code for Gantt display. |
| `FSL__GanttIcon__c` | TextArea | Gantt Icon | SVG icon for Gantt display. |
| `FSL__GanttLabel__c` | Text | Gantt Label | Label text on Gantt chart. |
| `FSL__Gantt_Display_Date__c` | DateTime | Gantt Display Date | Date used for Gantt positioning. |
| `FSL__Gantt_Label_Details__c` | Text | Gantt Label Details | Extended label details. |

### Geolocation Fields

| API Name | Type | Label |
|----------|------|-------|
| `FSL__InternalSLRGeolocation__c` | Location | Internal SLR Geolocation |
| `FSL__InternalSLRGeolocation__Latitude__s` | Number | Latitude component |
| `FSL__InternalSLRGeolocation__Longitude__s` | Number | Longitude component |
| `sfsdg__latitude__c` | Number | latitude (custom package) |
| `sfsdg__longitude__c` | Number | longitude (custom package) |

### FSSK (Field Service Starter Kit) Fields

| API Name | Type | Label | Description |
|----------|------|-------|-------------|
| `FSSK__FSK_Add_Asset_to_Maintenance_Plan__c` | Boolean | Add Asset to Account Maintenance Plan | Demo action trigger. |
| `FSSK__FSK_Assigned_Service_Resource__c` | Lookup(ServiceResource) | Assigned Service Resource | Quick reference to assigned resource. |
| `FSSK__FSK_Mobile_Start_Time__c` | DateTime | Mobile Start Time | Mobile app start timestamp. |
| `FSSK__FSK_Mobile_End_Time__c` | DateTime | Mobile End Time | Mobile app end timestamp. |
| `FSSK__FSK_Planned_Scheduled_Start__c` | DateTime | Planned Scheduled Start | Original planned start before rescheduling. |
| `FSSK__FSK_Planned_Scheduled_End__c` | DateTime | Planned Scheduled End | Original planned end before rescheduling. |
| `FSSK__FSK_Reject_Service_Appointment__c` | Boolean | Reject Service Appointment | Mobile rejection workflow trigger. |
| `FSSK__FSK_Work_Order__c` | Lookup(WorkOrder) | Work Order | Direct WO lookup (shortcut). |

### SDO Demo / Tooling Fields

| API Name | Type | Label | Description |
|----------|------|-------|-------------|
| `SDO_SFS_AA_type__c` | Picklist | SDO SFS AA type | Values: None, In-Person, Virtual. Appointment type for AA demos. |
| `SDO_SFS_Tracker_Resource_Contact__c` | Lookup(Contact) | Tracker Assigned Resource Contact | Contact for real-time tracking demos. |
| `SDO_SFS_Tracker_StartTime__c` | Text | Tracker StartTime | Formatted start for tracker UI. |
| `SDO_Tool_FSLDemoTools_Master_Data__c` | Boolean | FSLDemoTools Master Data | Marks records as demo master data. |
| `SDO_Tool_Service_Crew__c` | Boolean | Service Crew | Marks crew scheduling demo data. |
| `FSLDemoTools_AR_Actual_Travel_Time__c` | Number | FSLDemoTools AR Actual Travel Time | Simulated actual travel time. |
| `FSLDemoTools_Service_Resource__c` | Lookup(ServiceResource) | Service Resource | Demo tools resource reference. |
| `FSLDemoTools_Wave_Data__c` | Boolean | FSLDemoTools Wave Data | Analytics wave data flag. |
| `FSLDemoTools_Wave_Week__c` | Picklist | FSLDemoTools Wave Week | Values: 1-5. Week number for wave analytics. |
| `LSDemoTools_Master_Data__c` | Boolean | LSDemoTools Master Data | Life Sciences demo master data flag. |

### Business / Demo Scenario Fields

| API Name | Type | Label | Description |
|----------|------|-------|-------------|
| `Case__c` | Lookup(Case) | Case | Direct case reference (shortcut). |
| `Customer_NPS__c` | Number | Customer NPS | Net Promoter Score (0-10). |
| `Running_Late_in_mins__c` | Picklist | Running Late (in mins) | Values: 15, 30, 45, 60+. For real-time tracking demos. |
| `Work_Acceptance_Status__c` | Picklist | Work Acceptance Status | Values: Accept, Reject. Mobile acceptance workflow. |
| `Requires_Contractor__c` | Boolean | Requires Contractor | Flags SA for contractor assignment. |
| `Related_Contractor_Appointment__c` | Lookup(ServiceAppointment) | Related Contractor Appointment | Links to contractor's SA. |
| `Site_Inspection__c` | Boolean | Site Inspection | Pre-work site inspection required. |
| `Open_Opportunity_Value__c` | Currency | Open Opportunity Value | Upsell opportunity value. |
| `Parent_Work_Order__c` | Lookup(WorkOrder) | Parent Work Order | Quick reference to parent WO. |
| `Tech_Color__c` | Picklist | Tech Color | Values: 1-6. Color coding for demo visualization. |
| `Service_Territory_Name__c` | Text | Service Territory Name | Formula: territory name for display. |

### Why Not Analysis Fields

Used for scheduling analysis — understanding why resources were not selected.

| API Name | Type | Label |
|----------|------|-------|
| `Why_Not_Main_Count__c` | Number | Why Not Main Count |
| `Why_Not_Main_Candidates__c` | Number | Why Not Main Candidates |
| `Why_Not_Alt1_Count__c` / `Alt1_Candidates__c` | Number | Alt1 analysis |
| `Why_Not_Alt2_Count__c` / `Alt2_Candidates__c` | Number | Alt2 analysis |
| `Why_Not_Alt3_Count__c` / `Alt3_Candidates__c` | Number | Alt3 analysis |
| `Why_Not_Alt4_Count__c` / `Alt4_Candidates__c` | Number | Alt4 analysis |
| `Why_Not_NoAvail_Count__c` / `NoAvail_Candidates__c` | Number | No availability analysis |
| `Why_Not_Last_Run__c` | DateTime | Last analysis run timestamp |

### Formatted Display Fields

| API Name | Type | Label | Description |
|----------|------|-------|-------------|
| `SchStartDateFormatted__c` | Text | SchStartDateFormatted | Formula: formatted scheduled start date. |
| `SchStartTimeFormatted__c` | Text | SchStartTimeFormatted | Formula: formatted scheduled start time. |
| `SchEndDateFormatted__c` | Text | SchEndDateFormatted | Formula: formatted scheduled end date. |
| `SchEndTimeFormatted__c` | Text | SchEndTimeFormatted | Formula: formatted scheduled end time. |
| `AppointmentUrlFormula__c` | Text | AppointmentUrlFormula | Formula: URL to appointment record. |
| `First_Name__c` | Text | First Name | Customer first name for display. |
| `Rider_ContactFirstName__c` | Text | Rider Contact FirstName | Contact name for rider tracking. |
| `Rider_ServiceReport_URL__c` | Text | Rider Service Report URL | URL for service report in rider view. |
| `Rider_StartTime__c` | Text | Rider StartTime | Formatted time for rider view. |
| `Work_Type_Group_Name__c` | Text | Chronos Bot Work Type Group Name | Work type group name for Chronos bot. |
| `Work_Type_Group__c` | Lookup(WorkTypeGroup) | Chronos Bot Work Type Group | Links to WTG for appointment booking bot. |

### Compliance / KPI Fields

| API Name | Type | Label | Description |
|----------|------|-------|-------------|
| `FSL_Compliance__c` | Number | Compliance | SLA compliance score. |
| `FSL_FTFR_Count__c` | Number | FTFR Count | First Time Fix Rate counter. |

---

## ServiceResource Custom Fields (31)

### Contractor Management

| API Name | Type | Label | Description |
|----------|------|-------|-------------|
| `Is_Contractor__c` | Boolean | Is Contractor | Identifies third-party contractor resources. |
| `Contractor_s_Service_Territory__c` | Lookup(ServiceTerritory) | Contractor's Service Territory | Contractor's assigned territory. |
| `User_Type__c` | Picklist | User Type | Values: Field Service Lightning (FSL), Contractor. |

### Optimization KPIs

| API Name | Type | Label | Description |
|----------|------|-------|-------------|
| `Additional_Job_Revenue__c` | Currency | Additional Job Revenue | Revenue from fill-in/additional jobs. |
| `Additional_Jobs_Scheduled__c` | Number | Additional Jobs Scheduled | Count of additional jobs picked up. |
| `Number_of_Jobs_Optimized__c` | Number | Number of Jobs Optimized | Jobs affected by optimization. |
| `Number_of_Jobs_Scheduled__c` | Number | Number of Jobs Scheduled | Total scheduled jobs. |
| `Optimization_Revenue__c` | Currency | Optimization Revenue | Revenue impact from optimization. |
| `Optimization_KPI__c` | Boolean | Optimization KPI | Flag for optimization KPI tracking. |
| `Opt_KPI_Reset__c` | Boolean | Opt KPI Reset | Resets optimization KPI counters. |

### Travel Tracking

| API Name | Type | Label | Description |
|----------|------|-------|-------------|
| `Cost_Per_Mile__c` | Currency | Cost Per Mile | Per-mile cost for travel calculations. |
| `Original_Travel_Time__c` | Number | Original Travel Time | Travel time before optimization. |
| `Updated_Travel_Time__c` | Number | Updated Travel Time | Travel time after optimization. |
| `Travel_Delta__c` | Number | Travel Delta | Difference (original - updated). |
| `Travel_Savings__c` | Currency | Travel Savings | Dollar savings from travel optimization. |

### Location Tracking

| API Name | Type | Label | Description |
|----------|------|-------|-------------|
| `En_Route_Location__c` | Location | En Route Location | Real-time location while traveling. |
| `Last_Mile_Location__c` | Location | Last Mile Location | Location for last-mile tracking demos. |

### FSL Managed Package Fields

| API Name | Type | Label | Description |
|----------|------|-------|-------------|
| `FSL__Efficiency__c` | Number | Efficiency | Resource efficiency rating (affects duration calc). |
| `FSL__GanttLabel__c` | Text | Gantt Label | Display label on Gantt chart. |
| `FSL__Priority__c` | Number | Priority | Scheduling priority ranking. |
| `FSL__Travel_Speed__c` | Number | Travel Speed | Custom travel speed override. |
| `FSL__Picture_Link__c` | URL | Picture Link | Resource photo URL for Gantt display. |
| `FSL__Online_Offset__c` | Number | Online Offset | Online status offset. |
| `Role__c` | Text | Role | Resource role description. |

### SDO Demo Fields

| API Name | Type | Label |
|----------|------|-------|
| `Gantt_Color__c` | Picklist | Gantt Color (values: 1-6) |
| `SDO_SFS_Tracker_Contact__c` | Lookup(Contact) | Tracker Contact |
| `External_ID__c` | Text | External ID |

---

## Asset Custom Fields (33)

### Equipment Performance / IoT

| API Name | Type | Label | Description |
|----------|------|-------|-------------|
| `Asset_Availability__c` | Percent | Asset Availability | Uptime percentage. |
| `Asset_Reliability__c` | Percent | Asset Reliability | Reliability score. |
| `Asset_Downtime__c` | Number | Asset Downtime | Total downtime hours. |
| `Asset_Unplanned_Downtime__c` | Number | Asset Unplanned Downtime | Unplanned downtime hours. |
| `Average_Repair_Time__c` | Number | Average Repair Time | MTTR (Mean Time To Repair). |
| `Average_Time_Between_Failures__c` | Number | Average Time Between Failures | MTBF metric. |
| `TotalUsage__c` | Number | TotalUsage | Usage counter reading. |
| `TotalUsageUOM__c` | Text | TotalUsageUOM | Usage unit of measure. |
| `SDO_Service_Perform_Status__c` | Picklist | Performance Status | Asset performance classification. |

### Warranty / Entitlement

| API Name | Type | Label | Description |
|----------|------|-------|-------------|
| `Entitlement_Status__c` | Picklist | Warranty Status | Warranty state. |
| `Warranty_Indicator__c` | Text | Warranty | Formula: warranty status indicator. |
| `SDO_Service_Warranty_Services__c` | TextArea | Warranty Services | Warranty coverage details. |
| `Service_Contract__c` | Lookup(ServiceContract) | Service Contract | Direct service contract link. |

### Maintenance

| API Name | Type | Label | Description |
|----------|------|-------|-------------|
| `Scheduled_Servicing__c` | Boolean | Scheduled Servicing | Under a maintenance plan. |
| `Service_Frequency_Weeks__c` | Picklist | Service Frequency (Weeks) | How often asset needs service. |

### Display / Integration

| API Name | Type | Label | Description |
|----------|------|-------|-------------|
| `Asset_Combo__c` | Text | Asset Combo | Composite key field. |
| `Image__c` | Text | Image | Product image reference. |
| `B2B_Product_Image_URI__c` | URL | B2B Product Image URI | B2B Commerce image URL. |
| `Latitude__c` / `Longitude__c` | Number | Lat/Long | Asset location coordinates. |
| `Email__c` | Email | Customer Email | Customer email for the asset. |
| `Current_Users_Asset__c` | Boolean | Current User's Asset | Formula: current user's asset. |
| `Current_Users_Companys_Asset__c` | Boolean | Current User's Company's Asset | Formula: current user's company asset. |
| `Suggested_Products__c` | Multi-Select Picklist | Suggested Products | Upsell product suggestions. |

---

## Other Objects

### ServiceTerritory Custom Fields (16)

| API Name | Type | Label | Description |
|----------|------|-------|-------------|
| `FSL__O2_Enabled__c` | Boolean | Use enhanced scheduling and optimization | Enables O2 optimizer. |
| `FSL__NumberOfServicesToDripFeed__c` | Number | Number Of Services To Drip Feed | Drip feed limit per territory. |
| `FSL__TerritoryLevel__c` | Number | Territory Level | Hierarchy level. |
| `FSL__Hide_Emergency_Map__c` | Boolean | Hide Emergency Map | Hides emergency map overlay. |
| `FSL__System_Jobs__c` | Multi-Select Picklist | System Jobs | Enabled system jobs for territory. |

### ServiceTerritoryMember Custom Fields (12)

| API Name | Type | Label | Description |
|----------|------|-------|-------------|
| `SDO_SFS_Capacity_Based_Resource__c` | Boolean | Capacity Based Resource | Marks resource for capacity scheduling demo. |
| `SDO_SFS_Non_Capacity_Based_Resource__c` | Boolean | Non Capacity Based Resource | Opposite flag for demo filtering. |
| `Service_Resource_Name__c` | Text | Service Resource Name | Formula: resource name for display. |
| `FSL_Mobile_Data__c` | Boolean | FSL Mobile Data | Mobile data flag. |

### ResourceAbsence Custom Fields (19)

| API Name | Type | Label | Description |
|----------|------|-------|-------------|
| `FSL__Approved__c` | Boolean | Approved | Whether absence is approved (blocks scheduling). |
| `FSL__EstTravelTime__c` | Number | Estimated Travel Time | Travel time to absence location. |
| `FSL__EstTravelTimeFrom__c` | Number | Estimated Travel Time From | Travel time from absence location. |
| `FSL__GanttLabel__c` | Text | Gantt Label | Display label on Gantt. |
| `FSL__Gantt_Color__c` | Text | Gantt Color | Color on Gantt display. |
| `FSL__Scheduling_Policy_Used__c` | Lookup | Scheduling Policy Used | Policy context. |
| `SDO_Service_WEM_Assigned_to_me__c` | Boolean | Assigned to me? | WEM demo filter. |
| `SDO_Service_WEM_In_the_Past__c` | Boolean | In the past? | WEM demo filter. |

### WorkOrderLineItem Custom Fields (4)

| API Name | Type | Label |
|----------|------|-------|
| `FSL__IsFillInCandidate__c` | Boolean | Is Fill In Candidate |
| `FSL__VisitingHours__c` | Lookup(OperatingHours) | Visiting Hours |
| `External_ID__c` | Text | External ID |
| `DB_Days__c` | Number | DB Days |

### MaintenancePlan Custom Fields (4)

| API Name | Type | Label |
|----------|------|-------|
| `FSL_Is_Active__c` | Boolean | Is Active |
| `FSL_Is_Linked_To_Service_Contract__c` | Boolean | Is Linked To Service Contract |
| `FSL_Same_Date_As_Service_Contract__c` | Boolean | Same Date As Service Contract |
| `External_Id__c` | Text | External Id |

---

## Common SDO SOQL Patterns

### Work Orders with payment and depot status
```sql
SELECT Id, WorkOrderNumber, Subject, Status, Work_Order_Type__c,
       Amount__c, Payme__c, Payment_received__c,
       Depot_Repair_Status__c, Expected_Completion_Date__c,
       Serial_Number__c, Model_Number__c,
       Opportunity__c, Opportunity__r.Name
FROM WorkOrder
WHERE Work_Order_Type__c = 'Emergency'
  AND Status NOT IN ('Completed', 'Closed', 'Canceled')
```

### Appointments with scheduling analysis (Why Not)
```sql
SELECT Id, AppointmentNumber, Status, FSL__Emergency__c,
       FSL__Pinned__c, FSL__InJeopardy__c, FSL__InJeopardyReason__c,
       FSL__Appointment_Grade__c, FSL__Schedule_Mode__c,
       Why_Not_Main_Count__c, Why_Not_Main_Candidates__c,
       Why_Not_Last_Run__c, Running_Late_in_mins__c,
       Customer_NPS__c, Work_Acceptance_Status__c
FROM ServiceAppointment
WHERE SchedStartTime >= TODAY
  AND FSL__InJeopardy__c = true
```

### Resources with optimization KPIs
```sql
SELECT Id, Name, Is_Contractor__c, User_Type__c,
       FSL__Efficiency__c, FSL__Priority__c,
       Number_of_Jobs_Scheduled__c, Number_of_Jobs_Optimized__c,
       Additional_Job_Revenue__c, Optimization_Revenue__c,
       Original_Travel_Time__c, Updated_Travel_Time__c,
       Travel_Delta__c, Travel_Savings__c, Cost_Per_Mile__c
FROM ServiceResource
WHERE IsActive = true
ORDER BY Travel_Savings__c DESC
```

### Assets with performance metrics
```sql
SELECT Id, Name, SerialNumber, Status,
       Asset_Availability__c, Asset_Reliability__c,
       Asset_Downtime__c, Asset_Unplanned_Downtime__c,
       Average_Repair_Time__c, Average_Time_Between_Failures__c,
       Entitlement_Status__c, Service_Contract__c,
       Scheduled_Servicing__c, Service_Frequency_Weeks__c,
       TotalUsage__c, TotalUsageUOM__c
FROM Asset
WHERE Asset_Availability__c < 90
ORDER BY Asset_Reliability__c ASC
```

### Contractor appointments
```sql
SELECT Id, AppointmentNumber, Status, SchedStartTime,
       Requires_Contractor__c, Related_Contractor_Appointment__c,
       FSSK__FSK_Assigned_Service_Resource__c,
       FSSK__FSK_Assigned_Service_Resource__r.Name,
       FSL__Appointment_Grade__c
FROM ServiceAppointment
WHERE Requires_Contractor__c = true
  AND Status IN ('Scheduled', 'Dispatched')
```

---

## Demo Scenario Quick Reference

| Scenario | Key Fields |
|----------|-----------|
| **Depot Repair** | WO: `Depot_Repair_Status__c`, `Expected_Completion_Date__c` |
| **Payment Collection** | WO: `Amount__c`, `Payme__c`, `Payment_received__c`, `Transaction_Id__c` |
| **Emergency Dispatch** | SA: `FSL__Emergency__c`, `FSL__Schedule_over_lower_priority_appointment__c` |
| **Contractor Management** | SA: `Requires_Contractor__c`, `Related_Contractor_Appointment__c`; SR: `Is_Contractor__c` |
| **Real-Time Tracking** | SA: `Running_Late_in_mins__c`, `SDO_SFS_Tracker_*`; SR: `En_Route_Location__c` |
| **Optimization ROI** | SR: `Travel_Savings__c`, `Travel_Delta__c`, `Optimization_Revenue__c` |
| **Customer Satisfaction** | SA: `Customer_NPS__c`, `Work_Acceptance_Status__c`; WO: `Satisfied__c`, `Customer_Remarks__c` |
| **Asset Performance** | Asset: `Asset_Availability__c`, `Asset_Reliability__c`, MTTR/MTBF fields |
| **Preventive Maintenance** | Asset: `Scheduled_Servicing__c`, `Service_Frequency_Weeks__c`; MP: `FSL_Is_Active__c` |
| **Scheduling Analysis** | SA: `Why_Not_*` fields, `FSL__Appointment_Grade__c` |
| **Multi-Day Work** | SA: `FSL__IsMultiDay__c`, `FSL__MDS_Calculated_length__c`, `FSL__Same_Resource__c` |
| **Mobile Workflow** | SA: `FSSK__FSK_Mobile_Start_Time__c`, `FSSK__FSK_Mobile_End_Time__c`, `FSSK__FSK_Reject_Service_Appointment__c` |
