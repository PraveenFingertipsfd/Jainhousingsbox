public with sharing class BulkApprovalComponent {

    public class ApprovalWrapper {
        @AuraEnabled public List<ApprovalRecord> records;
        @AuraEnabled public Integer totalPending;
    }

    public class ApprovalRecord {
        @AuraEnabled public String Id;
        @AuraEnabled public String Name;
        @AuraEnabled public String ObjectType; // Will now show Label instead of API Name
        @AuraEnabled public String Status;
        @AuraEnabled public String OwnerName;
        @AuraEnabled public DateTime SubmittedDate;
        @AuraEnabled public Boolean selected;
        @AuraEnabled public String ApprovalProcessName;
    }

    @AuraEnabled
    public static ApprovalWrapper getPendingApprovals() {
        ApprovalWrapper wrapper = new ApprovalWrapper();
        List<ApprovalRecord> approvalRecords = new List<ApprovalRecord>();

        try {
            // Fetch pending approval records
            List<ProcessInstanceWorkitem> workItems = [
                SELECT Id, ProcessInstance.TargetObjectId,
                       ProcessInstance.TargetObject.Type,
                       ProcessInstance.SubmittedBy.Name,
                       ProcessInstance.CreatedDate,
                       ProcessInstance.TargetObject.Name,
                	   ProcessInstance.ProcessDefinition.Name
                FROM ProcessInstanceWorkitem
                WHERE ProcessInstance.Status = 'Pending'
                ORDER BY ProcessInstance.CreatedDate DESC
                LIMIT 200
            ];

            // Cache for object labels to avoid repeated describe calls
            Map<String, String> objectLabelMap = new Map<String, String>();

            for (ProcessInstanceWorkitem workItem : workItems) {
                ApprovalRecord record = new ApprovalRecord();
                record.Id = workItem.ProcessInstance.TargetObjectId;
                record.Name = workItem.ProcessInstance.TargetObject.Name;

                String objectAPI = workItem.ProcessInstance.TargetObject.Type;

                // Fetch label using describe only once per object type
                if (!objectLabelMap.containsKey(objectAPI)) {
                    try {
                        Schema.DescribeSObjectResult objDesc = Schema.getGlobalDescribe().get(objectAPI).getDescribe();
                        objectLabelMap.put(objectAPI, objDesc.getLabel());
                    } catch (Exception e) {
                        objectLabelMap.put(objectAPI, objectAPI); // fallback to API name if describe fails
                    }
                }

                record.ObjectType = objectLabelMap.get(objectAPI);
                record.Status = 'Pending';
                record.OwnerName = workItem.ProcessInstance.SubmittedBy.Name;
                record.SubmittedDate = workItem.ProcessInstance.CreatedDate;
                
                record.ApprovalProcessName = workItem.ProcessInstance.ProcessDefinition.Name;
                
                record.selected = false;

                approvalRecords.add(record);
            }

            wrapper.records = approvalRecords;
            wrapper.totalPending = approvalRecords.size();
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving approvals: ' + e.getMessage());
        }

        return wrapper;
    }

    @AuraEnabled
    public static String getCurrentUserProfile() {
        return [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
    }
    
    //method to fetch modal information for Cancellation Approval
    @AuraEnabled
    public static Map<String, String> getApprovalModalInfo(String recordId) {
        Map<String, String> result = new Map<String, String>();
        try {
            // Get the work item to find the process name
            List<ProcessInstanceWorkitem> workItems = [
                SELECT Id, ProcessInstance.ProcessDefinition.Name
                FROM ProcessInstanceWorkitem 
                WHERE ProcessInstance.TargetObjectId = :recordId 
                LIMIT 1
            ];
            
            if (!workItems.isEmpty()) {
                String processName = workItems[0].ProcessInstance.ProcessDefinition.Name;
                result.put('approvalProcessName', processName);
                
                // If it's a Cancellation Approval, get the Booking's Cancellation Type
                if ('Cancellation Approval'.equals(processName)) {
                    // Query the Booking record for Cancellation Type
                    Booking__c booking = [SELECT Id, Cancellation_Type__c FROM Booking__c WHERE Id = :recordId LIMIT 1];
                    result.put('cancellationType', booking.Cancellation_Type__c);
                }
            }
        } catch (Exception e) {
            // Silent fail - if there's an error, modal will just show default view
            System.debug('Error fetching modal info: ' + e.getMessage());
        }
        return result;
    }
    
    @AuraEnabled
    public static void updateCancellationCharges(String recordId, Decimal cancellationCharges) {
        try {
            if (recordId != null && cancellationCharges != null) {
                Booking__c booking = new Booking__c(
                    Id = recordId,
                    Cancellation_Charges__c = cancellationCharges
                );
                update booking;
            }
        } catch (Exception e) {
            System.debug('Error updating cancellation charges: ' + e.getMessage());
            // Silent fail - don't throw exception as approval already succeeded
        }
    }

    @AuraEnabled
    public static void processBulkApproval(List<String> recordIds, String action, String comments) {
        try {
            List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();

            List<ProcessInstanceWorkitem> workItems = [
                SELECT Id, ProcessInstanceId, ProcessInstance.TargetObjectId
                FROM ProcessInstanceWorkitem
                WHERE ProcessInstance.TargetObjectId IN :recordIds
            ];

            Map<Id, ProcessInstanceWorkitem> workItemMap = new Map<Id, ProcessInstanceWorkitem>();
            for (ProcessInstanceWorkitem workItem : workItems) {
                workItemMap.put(workItem.ProcessInstance.TargetObjectId, workItem);
            }

            for (String recordId : recordIds) {
                if (workItemMap.containsKey(recordId)) {
                    ProcessInstanceWorkitem workItem = workItemMap.get(recordId);

                    Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                    req.setWorkitemId(workItem.Id);
                    req.setAction(action);
                    req.setComments(comments);

                    requests.add(req);
                }
            }

            if (!requests.isEmpty()) {
                List<Approval.ProcessResult> results = Approval.process(requests);

                for (Approval.ProcessResult result : results) {
                    if (!result.isSuccess()) {
                        throw new AuraHandledException('Approval process failed for some records');
                    }
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error processing approvals: ' + e.getMessage());
        }
    }
    
    // NEW: Method to get Cost Sheet details
    @AuraEnabled
    public static Quote__c getCostSheetDetails1(String recordId) {
        try {
            return [SELECT 
                    Name, Floor__c, BHK_Type__c, Balcony_Area__c, Super_Built_Up_Area__c,
                    Basic_Price__c, Floor_Rise_Charges__c, Premium_Charges__c, 
                    GST_Charges_On_Total_Cost__c, Corpus_Fund__c, Maintenance_Charges__c,
                    EB_Debris__c, Project__r.Name, Unit__r.Name,Unit__r.Block1__r.Name, Carpet_Area__c,
                    Open_Terrace_Area__c, Final_Price_Per_Sq_ft__c, Car_Parking_Charges__c,
                    Other_Charges__c, Total_Cost__c, Total_Cost_Including_GST__c,
                    GST_for_Corpus_Fund__c, GST_for_Maintenance_Charge__c, Grand_Total__c,
                    
                    Booking_Request__r.Name,Booking_Request__r.Customer_Name__c,
                	Booking_Request__r.Email__c,Booking_Request__r.Mobile__c  
                    FROM Quote__c 
                    WHERE Id = :recordId];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving cost sheet details: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static CostSheetWrapper getCostSheetDetails(String recordId) {
        CostSheetWrapper result = new CostSheetWrapper();
        try {
            // Fetch Quote details
            result.quoteDetails = [SELECT 
                    Name, Floor__c, BHK_Type__c, Balcony_Area__c, Super_Built_Up_Area__c,
                    Basic_Price__c, Floor_Rise_Charges__c, Premium_Charges__c, 
                    GST_Charges_On_Total_Cost__c, Corpus_Fund__c, Maintenance_Charges__c,
                    EB_Debris__c, Project__r.Name, Unit__r.Name,Unit__r.Block1__r.Name, Carpet_Area__c,
                    Open_Terrace_Area__c, Final_Price_Per_Sq_ft__c, Car_Parking_Charges__c,
                    Other_Charges__c, Total_Cost__c, Total_Cost_Including_GST__c,
                    GST_for_Corpus_Fund__c, GST_for_Maintenance_Charge__c, Grand_Total__c,
                    
                    Booking_Request__r.Name,Booking_Request__r.Customer_Name__c,
                	Booking_Request__r.Email__c,Booking_Request__r.Mobile__c  
                    FROM Quote__c 
                    WHERE Id = :recordId
            		];
            
            		// Fetch related Payment Schedule
            		result.paymentSchedules = [SELECT Id, Name,S_No__c,Received_Amount1__c,AmountB__c,Payment_percent__c FROM Payment_Schedule__c
                                       WHERE Cost_Sheet__c = :recordId ORDER BY S_No__c ASC ];

        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving cost sheet details: ' + e.getMessage());
        }
        return result;
    }
    
    public class CostSheetWrapper {
        @AuraEnabled public Quote__c quoteDetails;
        @AuraEnabled public List<Payment_Schedule__c> paymentSchedules;
    }
    
    @AuraEnabled
    public static BookingWrapper getBookingDetails(String recordId) {
        BookingWrapper result = new BookingWrapper();
        try {
            // Fetch booking details
            result.bookingInfo = [
                SELECT Name, Stage__c, Booking_Date__c, Project1__r.Name, Owner.Name,
                Plot__r.Name, FloorNo__c, Unit_BHK_Type__c,
                Flat_Actual_Number__c, Tower_Name__c,
                First_Applicant_Name__c, Profession1__c, Mobile_Primary1__c, Email1__c,
                Total__c, Total_received_Amount__c, Pending_Amount__c
                FROM Booking__c
                WHERE Id = :recordId
            ];
            
            //cost sheet
            result.costSheetDetails = [SELECT 
                    Name, Floor__c, BHK_Type__c, Balcony_Area__c, Super_Built_Up_Area__c,
                    Basic_Price__c, Floor_Rise_Charges__c, Premium_Charges__c, 
                    GST_Charges_On_Total_Cost__c, Corpus_Fund__c, Maintenance_Charges__c,
                    EB_Debris__c, Project__r.Name, Unit__r.Name,Unit__r.Block1__r.Name, Carpet_Area__c,
                    Open_Terrace_Area__c, Final_Price_Per_Sq_ft__c, Car_Parking_Charges__c,
                    Other_Charges__c, Total_Cost__c, Total_Cost_Including_GST__c,
                    GST_for_Corpus_Fund__c, GST_for_Maintenance_Charge__c, Grand_Total__c from Quote__c where Booking__c = :recordId]; 
            
            // Fetch payment schedules linked to booking
            result.paymentSchedules = [
                SELECT Id, Name, Payment_percent__c, AmountB__c,
                status__c, Pending_Amount__c
                FROM Payment_Schedule__c
                WHERE Booking__c = :recordId
                ORDER BY S_No__c ASC
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving booking details: ' + e.getMessage());
        }
        return result;
    }
    
    public class BookingWrapper {
        @AuraEnabled public Booking__c bookingInfo;
        @AuraEnabled public List<Payment_Schedule__c> paymentSchedules;
        @AuraEnabled public Quote__c costSheetDetails;
    }


}