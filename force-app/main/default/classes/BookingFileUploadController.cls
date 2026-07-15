public class BookingFileUploadController {
	
    @AuraEnabled  
    public static List<ContentDocument> getFiles(String recordId, String filterName) {
        // Convert filter name to spaced format for matching
        String spacedName = filterName.replace('-', ' ');
        String suffix = ' - [ ' + spacedName + ' ]';
        
        List<ContentDocumentLink> links = [SELECT ContentDocumentId 
                                           FROM ContentDocumentLink 
                                           WHERE LinkedEntityId = :recordId];
        
        Set<Id> docIds = new Set<Id>();
        for(ContentDocumentLink link : links) {
            docIds.add(link.ContentDocumentId);
        }
        
        return [SELECT Id, Title, SystemModStamp 
                FROM ContentDocument 
                WHERE Id IN :docIds 
                AND Title LIKE :('%' + suffix)];
    }
    
    /* working code
    @AuraEnabled  
    public static List<ContentDocument> getFiles(String recordId,String filterName){ 
       System.debug('here==>toload'+filterName+'recordId'+recordId);
             ID filter = recordId;
        	 //filterName='%'+filterName+'%';
        	 filterName='%'+filterName+'%';
        List<ContentDocumentLink> cdlList = [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId=:filter];                         
        Set<Id> documentIds = new Set<Id>(); 
       
        for(ContentDocumentLink cdl:cdlList){  
            documentIds.add(cdl.ContentDocumentId);  
        }   
        system.debug('documentIds'+documentIds);
        return [SELECT Id, Title, SystemModStamp FROM ContentDocument WHERE Id IN :documentIds and Title like :filterName];        
    } */
    
    @AuraEnabled  
    public static void deleteFile(String contentDocumentId){ 
        delete [SELECT Id from ContentDocument WHERE Id = :contentDocumentId];       
    }  
    
    
    @AuraEnabled
    public static void updateDocument(String prefixName, List<String> idList) {
        // Modified suffix with proper spacing
        String suffix = ' - [ ' + prefixName.replace('-', ' ') + ' ]';
        
        List<ContentDocument> docs = [SELECT Id, Title FROM ContentDocument WHERE Id IN :idList];
        
        for(ContentDocument doc : docs) {
            // Remove any existing suffix first (with both old and new patterns)
            String baseName = doc.Title.replaceAll('( - \\[ .* \\]|\\[.*\\])$', '');
            // Apply new properly spaced suffix
            doc.Title = baseName + suffix;
        }
        
        update docs;
    }

}