public class WhatsAppService {

    private static final String API_KEY = System.Label.WhatsApp_API_Key;
    private static final String BASE_URL = System.Label.WhatsApp_Base_URL;
    private static final String FROM_NUMBER = System.Label.WhatsApp_From_Number;

    private static final Map<String, String> ERROR_CODES = new Map<String, String>{
        'WA001' => 'User is inactive',
        'WA002' => 'Authentication failed',
        'WA003' => 'Mobile number (from or to) is required',
        'WA004' => 'Valid mobile number with country code required',
        'WA005' => 'Message type is required',
        'WA006' => 'Message is required',
        'WA027' => 'Template ID is required',
        'WA028' => 'Template ID is invalid',
        'WA036' => 'Insufficient balance',
        'WA100' => 'Generic Error',
        'WA101' => 'Invalid payload'
    };

    // Send a WhatsApp template message
    // Usage: WhatsAppService.sendTemplateMessage('8220547859', 'all_project', null)
    public static String sendTemplateMessage(String toNumber, String templateName,
                                              List<String> placeholders) {
        if (String.isBlank(toNumber) || String.isBlank(templateName)) {
            System.debug('WhatsAppService: Missing required parameters');
            return null;
        }

        toNumber = formatPhoneNumber(toNumber);

        // Build Pinnacle/Adz API request body
        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('from', FROM_NUMBER);
        requestBody.put('to', toNumber);
        requestBody.put('type', 'template');

        Map<String, Object> message = new Map<String, Object>();
        message.put('templateid', templateName);

        if (placeholders != null && !placeholders.isEmpty()) {
            message.put('placeholders', placeholders);
        }

        requestBody.put('message', message);

        return sendRequest(JSON.serialize(requestBody));
    }

    // Send a plain text WhatsApp message (within 24hr session window)
    public static String sendTextMessage(String toNumber, String textMsg) {
        if (String.isBlank(toNumber) || String.isBlank(textMsg)) {
            return null;
        }

        toNumber = formatPhoneNumber(toNumber);

        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('from', FROM_NUMBER);
        requestBody.put('to', toNumber);
        requestBody.put('type', 'text');

        Map<String, Object> message = new Map<String, Object>();
        message.put('text', textMsg);
        requestBody.put('message', message);

        return sendRequest(JSON.serialize(requestBody));
    }

    // Core HTTP request method - Pinnacle/Adz Network Media API format
    private static String sendRequest(String jsonBody) {
        String endpoint = BASE_URL + '/api/v1/sendmessage';

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('apikey', API_KEY);
        req.setHeader('wabaNumber', '+' + FROM_NUMBER);
        req.setBody(jsonBody);
        req.setTimeout(30000);

        Http http = new Http();
        HttpResponse res = http.send(req);

        String responseBody = res.getBody();
        Integer statusCode = res.getStatusCode();
        System.debug('WhatsAppService Response [' + statusCode + ']: ' + responseBody);

        if (statusCode != 200 && statusCode != 201) {
            System.debug('WhatsAppService HTTP Error: ' + statusCode);
            return null;
        }

        // Parse response for error codes
        try {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            String code = String.valueOf(responseMap.get('code'));
            if (code != '200') {
                String errorMsg = (String) responseMap.get('message');
                System.debug('WhatsAppService Error: ' + code + ' - ' + errorMsg);
                return null;
            }
        } catch (Exception e) {
            System.debug('WhatsAppService: Response parse info: ' + e.getMessage());
        }

        return responseBody;
    }

    // Format phone number with country code (91XXXXXXXXXX)
    private static String formatPhoneNumber(String phone) {
        if (String.isBlank(phone)) return '';
        phone = phone.replaceAll('[^0-9]', '');
        if (phone.length() == 10) {
            phone = '91' + phone;
        }
        return phone;
    }

    // Get error description
    public static String getErrorDescription(String code) {
        return ERROR_CODES.containsKey(code) ? ERROR_CODES.get(code) : 'Unknown error: ' + code;
    }
}