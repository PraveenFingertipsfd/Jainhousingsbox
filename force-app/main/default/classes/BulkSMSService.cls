public class BulkSMSService {
    
    private static final String API_KEY = System.Label.Promptbulksms_API_Key;
    private static final String BASE_URL = System.Label.Promptbulksms_Base_URL;
    private static final String DEFAULT_SENDER = System.Label.Promptbulksms_Sender_ID;
    private static final String DEFAULT_ROUTE = '1';
    
    private static final Map<String, String> ERROR_CODES = new Map<String, String>{
        '101' => 'Invalid user',
        '102' => 'Invalid sender ID',
        '103' => 'Invalid contact(s)',
        '104' => 'Invalid route',
        '105' => 'Invalid message',
        '106' => 'Spam blocked',
        '107' => 'Promotional block',
        '108' => 'Low credits in the specified route',
        '109' => 'Promotional route will be working from 9am to 8:45pm only',
        '110' => 'Invalid DLT Template ID'
    };
                
    public static String sendSMS(String phoneNumber, String message, String templateId) {
        return sendSMS(phoneNumber, message, templateId, DEFAULT_SENDER, DEFAULT_ROUTE);
    }
    
    public static String sendSMS(String phoneNumber, String message, String templateId, 
                                  String senderId, String route) {
        if (String.isBlank(phoneNumber) || String.isBlank(message) || String.isBlank(templateId)) {
            return null;
        }
        phoneNumber = cleanPhoneNumber(phoneNumber);
        
        String endpoint = BASE_URL +
            '?key=' + API_KEY +
            '&route=' + route +
            '&sender=' + senderId +
            '&number=' + phoneNumber +
            '&sms=' + EncodingUtil.urlEncode(message, 'UTF-8') +
            '&templateid=' + templateId;
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setTimeout(30000);
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        String responseBody = res.getBody();
        System.debug('BulkSMSService Response: ' + responseBody);
        
        if (ERROR_CODES.containsKey(responseBody.trim())) {
            System.debug('BulkSMSService Error: ' + ERROR_CODES.get(responseBody.trim()));
            return null;
        }
        return responseBody.trim();
    }
    
    private static String cleanPhoneNumber(String phone) {
        if (String.isBlank(phone)) return '';
        phone = phone.replaceAll('[^0-9]', '');
        if (phone.startsWith('91') && phone.length() == 12) {
            phone = phone.substring(2);
        }
        return phone;
    }

    
    
    /*
// Send SMS to multiple numbers (comma-separated)
public static String sendBulkSMS(List<String> phoneNumbers, String message, String templateId) {
if (phoneNumbers == null || phoneNumbers.isEmpty()) {
return null;
}
List<String> cleanedNumbers = new List<String>();
for (String num : phoneNumbers) {
String cleaned = cleanPhoneNumber(num);
if (String.isNotBlank(cleaned)) {
cleanedNumbers.add(cleaned);
}
}
String commaSeparated = String.join(cleanedNumbers, ',');
return sendSMS(commaSeparated, message, templateId);
}

// @future method to send SMS from triggers
@future(callout=true)
public static void sendSMSAsync(String phoneNumber, String message, String templateId) {
String messageId = sendSMS(phoneNumber, message, templateId);
if (messageId != null) {
System.debug('BulkSMSService: SMS sent successfully. Message ID: ' + messageId);
}
}

// @future method for bulk SMS from triggers
@future(callout=true)
public static void sendBulkSMSAsync(String phoneNumbersJson, String message, String templateId) {
List<String> phoneNumbers = (List<String>) JSON.deserialize(phoneNumbersJson, List<String>.class);
String messageId = sendBulkSMS(phoneNumbers, message, templateId);
if (messageId != null) {
System.debug('BulkSMSService: Bulk SMS sent successfully. Message ID: ' + messageId);
}
}

// Check delivery report
public static String getDeliveryReport(String messageId) {
if (String.isBlank(messageId)) {
return null;
}

String endpoint = DLR_URL +
'?key=' + EncodingUtil.urlEncode(API_KEY, 'UTF-8') +
'&messageid=' + EncodingUtil.urlEncode(messageId, 'UTF-8');

HttpRequest req = new HttpRequest();
req.setEndpoint(endpoint);
req.setMethod('GET');
req.setTimeout(30000);

Http http = new Http();
HttpResponse res = http.send(req);

return res.getBody();
}


// Check available credits for a route
public static String checkCredits(String route) {
if (String.isBlank(route)) {
route = DEFAULT_ROUTE;
}

String endpoint = CREDIT_URL +
'?key=' + EncodingUtil.urlEncode(API_KEY, 'UTF-8') +
'&route=' + EncodingUtil.urlEncode(route, 'UTF-8');

HttpRequest req = new HttpRequest();
req.setEndpoint(endpoint);
req.setMethod('GET');
req.setTimeout(30000);

Http http = new Http();
HttpResponse res = http.send(req);

return res.getBody();
}

// AuraEnabled method to check SMS credits from Lightning components
@AuraEnabled
public static String getSMSCredits() {
return checkCredits(DEFAULT_ROUTE);
}



// Get error description for a code
public static String getErrorDescription(String code) {
return ERROR_CODES.containsKey(code) ? ERROR_CODES.get(code) : 'Unknown error: ' + code;
}
*/
}