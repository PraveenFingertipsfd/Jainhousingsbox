public class ReceiptVFPController {
    public String FloorNumber { get; set; }
    public String Total_Received_Amount_In_Words { get; set; }
    public Id ReceiptId { get; set; }
    public String transactionId { get; set; }
    
    public ReceiptVFPController(ApexPages.StandardController stdController) {
        ReceiptId = (Id)stdController.getId();
        NumberTOWordConvertion convert = new NumberTOWordConvertion();
        Receipt__c receipt = [SELECT Booking__r.FloorNo__c,Check_Transaction_Nmber__c, Total_Received_Amount__c FROM Receipt__c WHERE Id = :ReceiptId LIMIT 1];
        transactionId = '';
        // Validate FloorNo__c is a numeric value
        String floorNo = (String)receipt.Booking__r.FloorNo__c;
        if(receipt.Check_Transaction_Nmber__c != null){
            transactionId = (String)receipt.Check_Transaction_Nmber__c;
        }
        if (floorNo != null) {
            if(floorNo.isNumeric()){
                FloorNumber = convertToWords(Integer.valueof(floorNo));
            }else{
               if(FloorNumber == 'G'){
                    FloorNumber = 'Ground';
                }else{
                    FloorNumber = floorNo + ' th';
                }
            }
        }else {
            FloorNumber = 'Invalid Floor Number';  
        }
        
        if (receipt.Total_Received_Amount__c != null) {
            Total_Received_Amount_In_Words = convert.getNumberTOWordConvertion(receipt.Total_Received_Amount__c);
        }
    }
    
    private String convertToWords(Integer fNumber) {
        if (fNumber == null) {
            return '';
        }
        
        List<String> units = new List<String>{ '', 'First', 'Second', 'Third', 'Fourth', 'Fifth', 'Sixth', 'Seventh', 'Eighth', 'Nineth' };
            List<String> teens = new List<String>{ 'ten', 'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen', 'sixteen', 'seventeen', 'eighteen', 'nineteen' };
                List<String> tens = new List<String>{ '', '', 'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy', 'eighty', 'ninety' };
                    List<String> hundred = new List<String> { '', 'hundred' };
                        
                        String numberStr = String.valueOf(fNumber);
        Integer length = numberStr.length();
        String result = '';
        
        if (length == 2) {
            Integer secondPart = Integer.valueOf(numberStr.substring(0, 2));
            if (secondPart >= 10 && secondPart < 20) {
                result += teens[secondPart - 10];            
            } else if (secondPart >= 20) {
                Integer secondFirst = Integer.valueOf(numberStr.substring(0, 1));
                Integer secondLast = Integer.valueOf(numberStr.substring(1, 2));
                result += tens[secondFirst];
                if (secondLast > 0) {
                    result += units[secondLast];
                }
            }
            result += 'th';
        } else {
            Integer firstPart = Integer.valueOf(numberStr.substring(0, 1));
            if (firstPart > 0) {
                result += units[firstPart];
            } 
        }
        
        return result.trim().replaceAll(' +', ' ');
    }
}