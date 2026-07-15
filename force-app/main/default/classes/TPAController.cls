public class TPAController {
    
    public Id bookingId;
    public string grandTotal{get;set;}
    public string loanAmout{get;set;}
    public string customerAmount{get;set;}
    public string pendingAmount{get;set;}
    public string totalReceivedAmount{get;set;}
    public string TPA_Agreement_Date {get;set;}
    public date duedate {get;set;}
    
    public TPAController(ApexPages.StandardController stdController) {
        duedate = Date.today().addDays(15);
        bookingId = (Id)stdController.getId();
        NumberTOWordConvertion convert = new NumberTOWordConvertion();
        Booking__c booking = [SELECT Id,Total__c,Loan_Sanctioned_Amount__c,TPA_Agreement_Date__c,Amount_By_Customer__c,Total_received_Amount__c,Pending_Amount__c FROM Booking__c WHERE Id = :bookingId LIMIT 1];
        grandTotal = convert.getNumberTOWordConvertion(booking.Total__c);
        if(booking.Loan_Sanctioned_Amount__c!=null){
            loanAmout = convert.getNumberTOWordConvertion(booking.Loan_Sanctioned_Amount__c);
        }if(booking.Amount_By_Customer__c!=null){
            customerAmount = convert.getNumberTOWordConvertion(booking.Amount_By_Customer__c);
        }
        if (booking.TPA_Agreement_Date__c != null) {
            TPA_Agreement_Date = getFormattedDate(booking.TPA_Agreement_Date__c);
        }
        pendingAmount = convert.getNumberTOWordConvertion(booking.Pending_Amount__c);
        totalReceivedAmount = convert.getNumberTOWordConvertion(booking.Total_received_Amount__c);
    }
    
     public String getFormattedDate(date conversionDate) {
        String fdate = formatDate(conversionDate);
        system.debug(fdate);
        return fdate;
    }
    
    public String formatDate(Date inputDate) {
        Map<Integer, String> monthMap = new Map<Integer, String>{
            1 => 'January', 2 => 'February', 3 => 'March', 4 => 'April',
                5 => 'May', 6 => 'June', 7 => 'July', 8 => 'August',
                9 => 'September', 10 => 'October', 11 => 'November', 12 => 'December'
                };
                    
                    Map<Integer, String> daySuffixMap = new Map<Integer, String>{
                        1 => 'st', 2 => 'nd', 3 => 'rd', 21 => 'st', 22 => 'nd', 23 => 'rd', 31 => 'st'
                            };
                                
                                Integer day = inputDate.day();
        Integer month = inputDate.month();
        Integer year = inputDate.year();
        
        
        String daySuffix = 'th';
        if (daySuffixMap.containsKey(day)) {
            daySuffix = daySuffixMap.get(day);
        }
        
        String yearInWords = convertYearToWords(year);
        String formattedDate = day + daySuffix + ' Day of ' + monthMap.get(month) + ' ' + yearInWords;
        String shortDate = '(' + inputDate.format() + ')';
        system.debug(formattedDate + ' ' + shortDate);
        return formattedDate + ' ' + shortDate;
    }
    
    public String convertYearToWords(Integer year) {
        if (year == null) {
            return '';
        }
        
        list<String> units = new List<String>{ '', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine' };
            list<String> teens = new List<String>{ 'ten', 'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen', 'sixteen', 'seventeen', 'eighteen', 'nineteen' };
                list<String> tens = new List<String>{ '', '', 'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy', 'eighty', 'ninety' };
                    list<String> thousands = new List<String> { '', 'thousand' };
                        
                        String yearStr = String.valueOf(year);
        Integer length = yearStr.length();
        
        String result = '';
        
        if (length == 4) {
            Integer firstPart = Integer.valueOf(yearStr.substring(0, 2));
            if (firstPart == 20) {
                result += 'Two ';
            } if (firstPart == 21) {
                result += 'Twenty one ';            
            }if (firstPart == 22){
                result += 'Twenty two ';  
            }
            result += thousands[1] + ' ';
            
            String lastPart = yearStr.substring(2, 4);
            Integer lastPartInt = Integer.valueOf(yearStr.substring(2, 4));
            if (lastPartInt >= 10 && lastPartInt < 20) {
                result += teens[lastPartInt - 10];
            } else {
                Integer lastFIrst = Integer.valueOf(lastPart.substring(0, 1));
                Integer lastLast = Integer.valueOf(lastPart.substring(1, 2));
                result += tens[lastFIrst] + ' ' + units[lastLast];
            }
        }
        return result.trim().replaceAll(' +', ' ');
    }
}