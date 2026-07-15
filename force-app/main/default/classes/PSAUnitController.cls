public class PSAUnitController {
    
     public class DataWrapper{
        @AuraEnabled 
        public List<Plot__c> PlotLst {get; set;}
        @AuraEnabled 
        public decimal BlockedPrice {get; set;}
     }
    
    @AuraEnabled
    public static DataWrapper fetchRecords(String BookingReqId) {
        DataWrapper dtwrp = new DataWrapper();
        
        system.debug('In Apex');
        Booking_Request__c BkRec = [select id,name,Unit__c,Unit__r.Project__c,Blocked_Price__c from Booking_Request__c where Id=:BookingReqId limit 1];
        string PrjId = BkRec.Unit__r.Project__c;
        dtwrp.BlockedPrice = BkRec.Blocked_Price__c;
        
        List<Plot__c> ptLst = [select id,name,Block1__c,Project__c,	Is_PSA_Unit__c from Plot__c where Project__c =: PrjId and Status__c ='Available' and Is_PSA_Unit__c = false];
        dtwrp.PlotLst = ptLst;
        
        return dtwrp;
    }
}