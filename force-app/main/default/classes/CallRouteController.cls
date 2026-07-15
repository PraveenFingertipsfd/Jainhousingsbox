global without sharing class CallRouteController {
    public static String calloutResponse { get; set; }
    
    public static void callConnecting() {
        String fromnumber = ApexPages.currentPage().getParameters().get('fromnumber');
        fromnumber = (fromnumber != null) ? fromnumber.replace('\'', '') : '';
        String landingNumber = ApexPages.currentPage().getParameters().get('landingNumber');
        
        try {
            System.debug('Incoming call from: ' + fromnumber);

            // Step 1: Find Booking record
            List<Booking__c> checkList = [SELECT Id, OwnerId, Mobile_Primary1__c, Mobile_Alternate1__c FROM Booking__c WHERE Mobile_Primary1__c =: fromnumber OR Mobile_Alternate1__c =: fromnumber LIMIT 1 ];
            
            String phoneNumber;
            String bookingUrl;
            String ownerId = '';
            
            if (!checkList.isEmpty()) {
                Booking__c booking = checkList[0];
                ownerId = (String) booking.OwnerId;
                
                // ✅ Use getOrgDomainUrl
                String baseUrl = URL.getOrgDomainUrl().toExternalForm();
                bookingUrl = baseUrl + '/' + booking.Id;
                
                System.debug('Booking found: ' + booking.Id);
            } else {
                System.debug('⚠️ No Booking found for number: ' + fromnumber);
                bookingUrl = 'NO_BOOKING';
            }
            
            // Step 2: Resolve User phone number
            if (String.isNotBlank(ownerId)) {
                List<User> uList = [SELECT Id, Phone FROM User WHERE Id =: ownerId LIMIT 1];
                if (!uList.isEmpty() && String.isNotBlank(uList[0].Phone)) {
                    phoneNumber = uList[0].Phone;
                } else {
                    System.debug('⚠️ User phone is blank or User not found, using fallback');
                    phoneNumber = Label.NewCallRouteNumber;
                }
            } else {
                System.debug('⚠️ No OwnerId, using fallback');
                phoneNumber = Label.NewCallRouteNumber;
            }
            
            // Step 3: Ensure fallback safety
            if (String.isBlank(phoneNumber)) {
                System.debug('⚠️ PhoneNumber is still blank, setting hardcoded default');
                phoneNumber = Label.NewCallRouteNumber;
            }
            
            // Step 4: Prepare JSON response
            calloutResponse = JSON.serialize(
                new Map<String, String>{
                    'phone' => phoneNumber,
                    'bookingUrl' => bookingUrl
                }
            );
            
            System.debug('✅ Final CalloutResponse: ' + calloutResponse);
        }
        catch (Exception e) {
            calloutResponse = JSON.serialize(
                new Map<String, String>{
                    'error' => e.getMessage()
                }
            );
            System.debug('❌ Exception: ' + e.getMessage());
        }
    }
}