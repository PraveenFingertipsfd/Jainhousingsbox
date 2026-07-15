public with sharing class ParkingController {
    
    public class BookingWrapper {
        @AuraEnabled
        public Booking__c booking { get; set; }
        @AuraEnabled
        public List<Parking__c> ExistingParking { get; set; }
        @AuraEnabled
        public List<Parking__c> AllParking { get; set; }
    }
    @AuraEnabled(cacheable=true)
    public static BookingWrapper getAllDetails(Id bookingId) {
        BookingWrapper BkWrp = new BookingWrapper();
        
        Booking__c bk = [ SELECT Id, Name, Project__c,Project1__c, Block__c, Cost_Sheet__r.Car_Parking_Type__c,Plot__c,
                         (SELECT Id, Slot_Number__c, Parking_Type__c,Unit__c, Level__c,Booking__c,Status__c,Is_Swapped__c,Swapped_Slot_Number__c,Swapped_Slot__c FROM Parkings__r) FROM Booking__c WHERE Id = :bookingId LIMIT 1];
        
        if(bk != null){
            BkWrp.booking = bk;
            List<Parking__c> pkLst = [SELECT Id, Slot_Number__c, Parking_Type__c,Unit__c,Booking__c, Status__c,Project__c,Level__c,Tower__c,Is_Swapped__c,Swapped_Slot_Number__c,Swapped_Slot__c FROM Parking__c WHERE Project__c = :bk.Project1__c
                                      AND Tower__c = :bk.Block__c AND Level__c =: bk.Cost_Sheet__r.Car_Parking_Type__c  ORDER BY Slot_Number__c];
            
            if(!pkLst.isEmpty()){
                BkWrp.AllParking = pkLst;
            }
        }
        if(!bk.Parkings__r.isEmpty()){
            BkWrp.ExistingParking = bk.Parkings__r;
        }
        
        return BkWrp;
    }
    
    @AuraEnabled
    public static void saveParkings(Id bookingId, List<Parking__c> newSlots, List<Parking__c> swappedSlots) {
        system.debug( 'bookingId >> '+bookingId);
        system.debug( 'newSlots >> '+newSlots);
        system.debug( 'swappedSlots >> '+swappedSlots);
        
        List<Parking__c> SwappedLst = new List<Parking__c>();
        
        if (!newSlots.isEmpty()) {
            upsert newSlots;
        }
        
        if (!swappedSlots.isEmpty()) {
            for(Parking__c pk : swappedSlots){
                Parking__c newpk = new Parking__c();
                newpk.Id = pk.Swapped_Slot__c;
                newpk.Swapped_Slot__c = pk.Id;
                newpk.Is_Swapped__c = true;
                newpk.Booking__c = pk.Booking__c;
                newpk.Unit__c = pk.Unit__c;
                //newpk.Swapped_Slot_Number__c = pk.Swapped_Slot_Number__c;
                newpk.Swapped_Slot_Number__c = null;
                newpk.Status__c = 'Sold';
                SwappedLst.add(newpk);
                
                Parking__c oldpk = new Parking__c();
                oldpk.Id = pk.Id;
                oldpk.Swapped_Slot__c = null;
                oldpk.Is_Swapped__c = false;
                oldpk.Booking__c = null;
                oldpk.Unit__c = null;
                oldpk.Swapped_Slot_Number__c = null;
                oldpk.Status__c = 'Available';
                SwappedLst.add(oldpk);
            }
            update SwappedLst;
        }
    }
}