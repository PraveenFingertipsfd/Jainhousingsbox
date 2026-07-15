public without sharing class LightningFileUploadHandler1 {
    
    /*
    @AuraEnabled
    public static List<ContentDocument> getFiles(String recordId) {
        Set<Id> docIds = new Set<Id>();

        for (ContentDocumentLink link : [
            SELECT ContentDocumentId 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :recordId
        ]) {
            docIds.add(link.ContentDocumentId);
        }

        return [
            SELECT Id, Title, FileType 
            FROM ContentDocument 
            WHERE Id IN :docIds
        ];
    }

    @AuraEnabled
    public static void deleteFile(String contentDocumentId) {
        delete [SELECT Id FROM ContentDocument WHERE Id = :contentDocumentId];
    }
*/
    
    @AuraEnabled
    public static void updateGuestRecordField(Id contentDocumentId, Id parentRecordId) {
        List<ContentVersion> versionsToUpdate = [
            SELECT Id 
            FROM ContentVersion 
            WHERE ContentDocumentId = :contentDocumentId
            ORDER BY CreatedDate DESC 
            LIMIT 1
        ];
        if (!versionsToUpdate.isEmpty()) {
            versionsToUpdate[0].Guest_Record_fileupload__c = parentRecordId;
            update versionsToUpdate;
        }
    }
}