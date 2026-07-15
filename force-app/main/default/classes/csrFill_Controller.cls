public without sharing class csrFill_Controller {

    @AuraEnabled
    public static Map<String, List<String>> getPicklistValues() {
        Map<String, List<String>> picklistValues = new Map<String, List<String>>();
        
        // Get Bank picklist values
        List<String> problems = new List<String>();
        Schema.DescribeFieldResult probs = Snag__c.Problem_Type__c.getDescribe();
        for (Schema.PicklistEntry entry : probs.getPicklistValues()) {
            problems.add(entry.getValue());
        }
        picklistValues.put('problems', problems);
        
        return picklistValues;
    }
    
    @AuraEnabled
    public static Joint_Inspection__c getJointInspectionDetails(Id recId) {
        try {
            List<Joint_Inspection__c> jinsList = [
                SELECT Id, Name,Is_CSR_Responded__c,Booking__r.Project1__r.Name,Booking__r.Plot__r.Name,Joint_Inspection_Completed_Date__c
                FROM Joint_Inspection__c  
                WHERE Id = :recId 
                LIMIT 1
            ];
            
            if (!jinsList.isEmpty()) {
                return jinsList[0];
            }
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
        return null;
    }
    
    /*@AuraEnabled
    public static Joint_Inspection__c getJointInspectionDetails(Id recordId) {
        try {
            // First verify the ID is valid for Joint_Inspection__c
            if (recordId.getSObjectType() != Joint_Inspection__c.sObjectType) {
                throw new AuraHandledException('Invalid Joint Inspection ID');
            }
            
            List<Joint_Inspection__c> inspections = [
                SELECT Id, Name, Joint_Inspection_Completed_Date__c,
                Booking__r.Project1__r.Name, 
                Booking__r.Plot__r.Name             
                FROM Joint_Inspection__c 
                WHERE Id = :recordId
                LIMIT 1
            ];
            
            if (inspections.isEmpty()) {
                throw new AuraHandledException('Joint Inspection not found');
            }
            
            return inspections[0];
        } catch (Exception e) {
            throw new AuraHandledException('Error loading inspection: ' + e.getMessage());
        }
    }*/
    
    /* 07-08
    @AuraEnabled
    public static void saveInspectionWithSnags(Joint_Inspection__c inspection, List<Snag__c> snags, String signatureData) {
        Savepoint sp = Database.setSavepoint();
        try {
            // Update the inspection record
            update inspection;
            
            // Only create new snags if toggle was enabled and snags were added
            if (snags != null && !snags.isEmpty()) {
                // Set the Joint Inspection reference for all snags
                for (Snag__c snag : snags) {
                    snag.Joint_Inspection__c = inspection.Id;
                }
                insert snags;
            }
            
            // Save signature if provided
            if (String.isNotBlank(signatureData)) {
                Attachment signature = new Attachment(
                    ParentId = inspection.Id,
                    Name = 'CustomerSignature.png',
                    Body = EncodingUtil.base64Decode(signatureData.split(',')[1]),
                    ContentType = 'image/png'
                );
                insert signature;
            }
        } catch (Exception e) {
            Database.rollback(sp);
            throw new AuraHandledException('Error saving data: ' + e.getMessage());
        }
    }
    */
 
    
    @AuraEnabled
    public static void saveInspectionWithSnags(Joint_Inspection__c inspection,List<Snag__c> snags,String signatureData,List<Map<String, String>> responses,String encouragementFactors,String desiredImprovements){
        Savepoint sp = Database.setSavepoint();
        try {
            // 1. Update Joint Inspection
            update inspection;
            
            // 2. Insert Snags
            if (snags != null && !snags.isEmpty()) {
                for (Snag__c snag : snags) {
                    snag.Joint_Inspection__c = inspection.Id;
                }
                insert snags;
            }
            
            // 3. Reload Booking ID
            inspection = [SELECT Id, Booking__c FROM Joint_Inspection__c WHERE Id = :inspection.Id LIMIT 1];
                
            // 4. Create Feedback record
            if (responses != null && !responses.isEmpty()) {
                Feedback__c feedback = new Feedback__c();
                feedback.Booking__c = inspection.Booking__c;
                feedback.Joint_Inspection__c = inspection.Id;
                feedback.FBQ20__c = encouragementFactors;
                feedback.FBQ19__c = desiredImprovements;
                feedback.FeedBack_Responded_Date__c = DateTime.now();
                
                // Dynamically assign values
                for (Map<String, String> res : responses) {
                    String field = res.get('field');
                    String value = res.get('value');
                    if (String.isNotBlank(field) && String.isNotBlank(value)) {
                        feedback.put(field, value);
                    }
                }
                
                insert feedback;
                
                // 5. Attach signature to Feedback (if present)
                if (String.isNotBlank(signatureData)) {
                    String base64Data = signatureData.substringAfter(',');
                    Attachment signature = new Attachment();
                    signature.Name = 'CustomerSignature.png';
                    signature.Body = EncodingUtil.base64Decode(base64Data);
                    signature.ContentType = 'image/png';
                    signature.ParentId = feedback.Id;
                    insert signature;
                }
            }
            
        } catch (Exception e) {
            Database.rollback(sp);
            throw new AuraHandledException('Error saving data: ' + e.getMessage());
         }
    }  
}