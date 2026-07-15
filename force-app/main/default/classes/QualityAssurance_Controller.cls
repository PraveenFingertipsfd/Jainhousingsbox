public class QualityAssurance_Controller {
    @AuraEnabled
    public static void confirmQualityAssurance(String recordId) {
        try {
            
            // Update the Plot record
            Plot__c plot = new Plot__c(
                Id = recordId,
                QA_Given__c = true,
                QA_Given_Date__c = System.now()
            );
            
            update plot;
        } catch (Exception e) {
            throw new AuraHandledException('Error updating Quality Assurance: ' + e.getMessage());
        }
    }
}