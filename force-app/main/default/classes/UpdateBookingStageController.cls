public with sharing class UpdateBookingStageController {
    
    @AuraEnabled
    public static String getStage(Id recordId) {
        Booking__c booking = [SELECT Stage__c FROM Booking__c WHERE Id = :recordId LIMIT 1];
        return booking.Stage__c;
    }

    @AuraEnabled
    public static Boolean checkTenPercentCollected(Id recordId) {
        Booking__c booking = [SELECT Is_10_Collected__c FROM Booking__c WHERE Id = :recordId LIMIT 1];
        return booking.Is_10_Collected__c;
    }
       
    @AuraEnabled
    public static void submitForApproval(Id recordId, String dateField) {
        // Update the record first
        Booking__c booking = new Booking__c(
            Id = recordId,
            Stage__c = 'Agreement'
            //Sale_Agreement_Date__c = Date.valueOf(dateField)
            //Sale_Agreement_Status__c = 'Pending Approval'
        );
        update booking;
        
        // Submit for approval
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setComments('Submitted for approval. 10% amount not collected.');
        req.setObjectId(recordId);
        req.setProcessDefinitionNameOrId('Sale_Agreement_Approval');
        req.setSkipEntryCriteria(true);
        Approval.ProcessResult result = Approval.process(req);
    }
    
    @AuraEnabled
    public static Boolean checkNinetyPercentCollected(Id recordId) {
        // Implement logic to check if 90% payment is collected
        Booking__c booking = [SELECT Is_90_Collected__c FROM Booking__c WHERE Id = :recordId];
        return booking.Is_90_Collected__c;
    }
    
    @AuraEnabled
    public static void submitRegistrationForApproval(Id recordId, String dateField) {
        // Update the record
        try{Booking__c booking = new Booking__c(
            Id = recordId,
            Stage__c = 'Registration'
            //Registration_Date__c = Date.valueOf(dateField)
            //Registration_Approval_Status__c = 'Submitted for Approval'
        );
            
            update booking;
           }catch(Exception e){
               
               system.debug('in catch' + e.getMessage());
           }
        
        // Submit for approval
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(recordId);
        req.setComments('Submitted for approval. 90% amount not collected.');
        req.setProcessDefinitionNameOrId('Registration_Approval_Process');
        Approval.ProcessResult result = Approval.process(req);
    }
    
    @AuraEnabled
    public static List<ContentDocument> getFiles(Id recordId) {
        List<ContentDocumentLink> links = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :recordId];
        
        Set<Id> docIds = new Set<Id>();
        for (ContentDocumentLink l : links) {
            docIds.add(l.ContentDocumentId);
        }
        
        return [SELECT Id, Title FROM ContentDocument WHERE Id IN :docIds];  
    }

    @AuraEnabled
    public static void updateDocument(String prefixName, List<String> idList) {
        String suffix = ' - [ ' + prefixName.replace('-', ' ') + ' ]';
        
        List<ContentDocument> docs = [SELECT Id, Title FROM ContentDocument WHERE Id IN :idList];
        for(ContentDocument doc : docs) {
            String baseName = doc.Title.replaceAll('( - \\[ .* \\]|\\[.*\\])$', '');
            doc.Title = baseName + suffix;
        }
        update docs;
    }
    
    public class initWrapper{
        @AuraEnabled
        public String StageName {get;set;}
        @AuraEnabled  
        public List<ContentDocument> SaleAgreementFiles {get;set;}
        @AuraEnabled 
        public List<ContentDocument> SaleDeedFiles {get; set;}
    }
    
    @AuraEnabled
    public static initWrapper getupdatedStage(Id recordId) {
        initWrapper inWrp = new initWrapper();
        
        inWrp.StageName = [SELECT Stage__c FROM Booking__c WHERE Id = :recordId LIMIT 1].Stage__c;
        inWrp.SaleAgreementFiles = UpdateBookingStageController.getDocumentFiles(recordId,'Sale Agreement');
        inWrp.SaleDeedFiles = UpdateBookingStageController.getDocumentFiles(recordId, 'Sale Deed');
        
        return inWrp;
    }
    
    @AuraEnabled  
    public static List<ContentDocument> getDocumentFiles(String recordId, String filterName) {
        // Convert filter name to spaced format for matching
        String spacedName = filterName.replace('-', ' ');
        String suffix = ' - [ ' + spacedName + ' ]';
        
        // Get all document links for this record
        List<ContentDocumentLink> links = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :recordId];
        
        // Collect document IDs
        Set<Id> docIds = new Set<Id>();
        for(ContentDocumentLink link : links) {
            docIds.add(link.ContentDocumentId);
        }
        
        // Return matching documents
        return [SELECT Id, Title, SystemModStamp FROM ContentDocument WHERE Id IN :docIds AND Title LIKE :('%' + suffix)];
                
                
                
               
    }
    
    /*
    @AuraEnabled  
    public static List<ContentDocument> getSaleAgreementFiles(String recordId, String filterName) {
        // Convert filter name to spaced format for matching
        String spacedName = filterName.replace('-', ' ');
        String suffix = ' - [ ' + spacedName + ' ]';
        
        List<ContentDocumentLink> links = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :recordId];

        Set<Id> docIds = new Set<Id>();
        for(ContentDocumentLink link : links) {
            docIds.add(link.ContentDocumentId);
        }
        
        return [SELECT Id, Title, SystemModStamp 
                FROM ContentDocument 
                WHERE Id IN :docIds 
                AND Title LIKE :('%' + suffix)];
    }
*/
    
}