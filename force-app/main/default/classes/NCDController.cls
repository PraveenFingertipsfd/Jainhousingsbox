public class NCDController {
    public Id bookingId {get; set;}
    public String floor {get; set;}
    public Booking__c booking {get; set;}
    public Integer flatNo {get; set;}
    public String slots {get; set;}
    public String ptypes {get; set;}
    public String levels {get; set;}
    
    
    
    
    
    public NCDController(ApexPages.StandardController stdcontroller){
        bookingId = stdcontroller.getId();
        
        booking =[select Id, FloorNo__c, Flat_Number__c from Booking__c where Id =: bookingId ];
        floor = getFloorWithSuffix(booking.FloorNo__c);
        
        // Getting car parking informations from Parking object
        List<Parking__c> parking= [Select Id, Name,	Parking_Type__c,Level__c, Slot_Number__c From Parking__c Where Booking__c = : bookingId];
        Set<String> slot = new Set<String>();
        Set<String> pType = new Set<String>();
        Set<String> level = new Set<String>();
        
        
        for(Parking__c p:parking){
            if(p.Slot_Number__c !=null){
                slot.add(String.valueOf(p.Slot_Number__c));
            }
            if(p.Parking_Type__c !=null){
                pType.add(String.valueOf(p.Parking_Type__c));
            }
            if(p.Parking_Type__c !=null){
                level.add(String.valueOf(p.Level__c));
            }
            
            
        }
        // Converting to comma seperated values
        slots = String.join(new List<String>(slot), ', ');
        pTypes = String.join(new List<String>(pType), ', '); 
        levels = String.join(new List<String>(level), ', ');
        
        
        if(booking.Flat_Number__c != null){
            flatNo = Integer.valueOf(String.valueOf(booking.Flat_Number__c));
        }
        
    }
    
    /////// Formatting Floor Number
    public static String getFloorWithSuffix(String floorNumber) {
        if (floorNumber == null) {
            return null;
        }
        
        String floorStr = String.valueOf(floorNumber); // Convert the floor number to a string
        String suffix = 'th'; // Default suffix is "th"
        
        // Handle the special case for numbers 11-13 (e.g., 11th, 12th, 13th)
        if (floorStr.endsWith('11') || floorStr.endsWith('12') || floorStr.endsWith('13')) {
            suffix = 'th';
        } else {
            // Get the last character of the string and determine the suffix
            String lastChar = floorStr.substring(floorStr.length() - 1);
            if (lastChar == '1') {
                suffix = 'st';
            } else if (lastChar == '2') {
                suffix = 'nd';
            } else if (lastChar == '3') {
                suffix = 'rd';
            }
        }
        
        return floorNumber + suffix;
    }
    
    
}