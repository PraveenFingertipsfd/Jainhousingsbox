public with sharing class HomeNotificationController{
    /*@auraEnabled
    public static datawrapperfl getWelcomeCallInformation(Integer pageNumber,Integer pageSize){
        datawrapperfl dwfl = new datawrapperfl();
        Integer offset = (pageNumber - 1) * pageSize;
        
        List<Booking__c> allCount = [Select Id,Name,Owner.Name,Welcome_Call_Done__c,Welcome_Call_Date__c,Welcome_Email_Sent_to_Customer__c,Welcome_Mail_Sent_Time__c from Booking__c where Welcome_Email_Sent_to_Customer__c = true and Welcome_Mail_Sent_Time__c = today and Welcome_Call_Done__c = false];
        List<Booking__c> BookingWelCallDetails = [Select Id,Name,Owner.Name,Welcome_Call_Done__c,Welcome_Call_Date__c,Welcome_Email_Sent_to_Customer__c,Welcome_Mail_Sent_Time__c from Booking__c 
                                                  where Welcome_Email_Sent_to_Customer__c = true and Welcome_Mail_Sent_Time__c = today  and Welcome_Call_Done__c = false order by Welcome_Mail_Sent_Time__c LIMIT :pageSize OFFSET :offset];
        dwfl.FollowupldList = BookingWelCallDetails;
        dwfl.FollowupCount = allCount.size();
        return dwfl;
    }*/
    
    /* 07-08
     @auraEnabled
    public static List<Booking__c> getWelcomeCallInformation(Integer pageNumber,Integer pageSize){
        datawrapperfl dwfl = new datawrapperfl();
        Integer offset = (pageNumber - 1) * pageSize;
        
        List<Booking__c> BookingWelCallDetails = [Select Id,Name,Owner.Name,Welcome_Call_Done__c,Welcome_Call_Date__c,Welcome_Email_Sent_to_Customer__c,Welcome_Mail_Sent_Time__c from Booking__c 
                                                  where Welcome_Email_Sent_to_Customer__c = true and Welcome_Mail_Sent_Time__c = today  and Welcome_Call_Done__c = false order by Welcome_Mail_Sent_Time__c LIMIT :pageSize OFFSET :offset];
        return BookingWelCallDetails;
    }
*/
    
    @AuraEnabled
    public static List<Booking__c> getWelcomeCallInformation() { // No pageNumber/pageSize
        return [SELECT Id, Name, Owner.Name, Welcome_Call_Done__c, 
                Welcome_Call_Date__c, Welcome_Email_Sent_to_Customer__c, 
                Welcome_Mail_Sent_Time__c 
                FROM Booking__c 
                WHERE Welcome_Email_Sent_to_Customer__c = true 
                AND Welcome_Mail_Sent_Time__c = today 
                AND Welcome_Call_Done__c = false 
                ORDER BY Welcome_Mail_Sent_Time__c];
    }
    
    public class datawrapperfl{
        @AuraEnabled
        public Decimal FollowupCount {get; set;}
        @AuraEnabled
        public List<Booking__c> FollowupldList {get; set;}
    }
    
    @auraEnabled
    public static list<Booking__c> getPendingFollowUpInformation(){
        //List<Booking__c> followUpDetails = [Select Id,Name,Welcome_Call_Done__c,Owner.Name,Welcome_Call_Date__c,Welcome_Email_Sent_to_Customer__c,Welcome_Mail_Sent_Time__c from Booking__c where Welcome_Email_Sent_to_Customer__c = true  and Welcome_Call_Done__c = false order by Welcome_Mail_Sent_Time__c];
        List<Booking__c> followUpDetails = [Select Id,Name,Welcome_Call_Done__c,Owner.Name,Welcome_Call_Date__c,Welcome_Email_Sent_to_Customer__c,Welcome_Mail_Sent_Time__c from Booking__c where Welcome_Email_Sent_to_Customer__c = true  and Welcome_Call_Done__c = false AND DAY_ONLY(Welcome_Mail_Sent_Time__c) < :Date.today() order by Welcome_Mail_Sent_Time__c];
        return followUpDetails;
    }
    
    @auraEnabled
    public static String updateFollowupDetails(String recID, String FLStatus, String comments){
        /*List<Follow_Up__c> svData = [SELECT Id, Status__c,Description__c,Comments__c FROM Follow_Up__c WHERE Id = :recID LIMIT 1];
if(!svData.isEmpty()){
svData[0].Status__c = FLStatus;
svData[0].Is_System_Cancelled__c = false;
if(FLStatus=='Cancelled'){
svData[0].Description__c = comments;
}
else if(FLStatus=='Completed'){
svData[0].Comments__c = comments;
}
update svData[0];
return 'Updated';
}
else{
return 'Record not found';
}*/
        return 'updated';
    }
    
   
        
    @auraEnabled
    public static String getUserName(){
        String userId = UserInfo.getUserId();
        User currentUser = [SELECT Name FROM User WHERE Id = :userId];
        return currentUser.Name;
    }
    
    @auraEnabled
    public static datawrapper4 todaysBookings(Integer pageSize, Integer pageNumber){
        datawrapper4 dw4 = new datawrapper4();
        Integer offset = (pageNumber - 1) * pageSize;
        Id currentUserId = UserInfo.getUserId();
        List<Booking__c> lstbook;
        Boolean isAdmin = [SELECT Profile.Name FROM User WHERE Id = :currentUserId].Profile.Name == 'System Administrator';
        lstbook = [SELECT id,Name,Project__c,Unit_NumberFor__c,Stage__c,Contact_Telephone_Number__c,Contact_Telephone_Number1__c,Mobile__c,Mobile_Primary1__c,Mobile_Primary2__c,createddate 
                   FROM Booking__c WHERE createddate = TODAY ORDER BY CreatedDate DESC LIMIT :pageSize OFFSET :offset];  //Block_Number__c
        dw4.ldListbooking = lstbook;
        dw4.Noofbooking = lstbook.size();
        return dw4;
    }
    
    public class datawrapper4{
        @AuraEnabled
        public List<Booking__c> ldListbooking {get; set;}
        @AuraEnabled
        public integer Noofbooking {get; set;}
    }
    
    @AuraEnabled
    public static List<Booking__c> getNinetyPercentCollectedBookings() {
        Date today = Date.today();
        return [
            SELECT Id, Name, Stage__c, Is_90_Collected__c, Is_90_Collected_Date__c
            FROM Booking__c
            WHERE Is_90_Collected__c = true
            AND Stage__c NOT IN ('Registration', 'Registration Completed')
            AND DAY_ONLY(Is_90_Collected_Date__c) = :today
        ];
    }

    
    @AuraEnabled
    public static List<Booking__c> getPendingNinetyPercentBookings() {
        Date today = Date.today();
        return [
            SELECT Id, Name, Stage__c, Is_90_Collected__c, Is_90_Collected_Date__c
            FROM Booking__c
            WHERE Is_90_Collected__c = true
            AND Stage__c NOT IN ('Registration', 'Registration Completed')
            AND Is_90_Collected_Date__c < :today
        ];
    }
    
    //added by karthik 16-09
    @AuraEnabled
    public static List<Booking__c> getTodaysJointInspections() {
        return [
            SELECT Id, Name, Owner.Name, Project1__r.Name, Tower_Name__c, Plot__r.Name, Plot__r.QA_Given__c, Plot__r.QA_Given_Date__c, Joint_Inspection_Count__c
            FROM Booking__c
            WHERE Plot__r.QA_Given__c = true
            AND DAY_ONLY(Plot__r.QA_Given_Date__c) = :Date.today()
            AND (Joint_Inspection_Count__c = null OR Joint_Inspection_Count__c = 0)
            AND Stage__c != 'Cancellation'
        ];
    }
    
    @AuraEnabled
    public static List<Booking__c> getPendingJointInspections() {
        return [
            SELECT Id, Name, Owner.Name, Project1__r.Name, Tower_Name__c, Plot__r.Name, Plot__r.QA_Given__c, Plot__r.QA_Given_Date__c, Joint_Inspection_Count__c
            FROM Booking__c
            WHERE Plot__r.QA_Given__c = true
            AND DAY_ONLY(Plot__r.QA_Given_Date__c) < :Date.today()
            AND (Joint_Inspection_Count__c = null OR Joint_Inspection_Count__c = 0)
            AND Stage__c != 'Cancellation'
        ];
    }

}