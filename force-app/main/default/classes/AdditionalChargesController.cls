public class AdditionalChargesController {
    public String totalcharge { get; set; }
    public Id additionChargeId;
    
    public AdditionalChargesController(ApexPages.StandardController stdController) {
        additionChargeId = (Id)stdController.getId();
        NumberTOWordConvertion convert = new NumberTOWordConvertion();
        Additional_Charges__c booking = [select id,Name,Total_Additional_Charge__c from Additional_Charges__c WHERE Id = :additionChargeId LIMIT 1];
         if (booking.Total_Additional_Charge__c != null) {
            totalcharge = convert.getNumberTOWordConvertion(booking.Total_Additional_Charge__c);
        }
    }
    
    public String getFormattedDate(date conversionDate) {
        String fdate = formatDate(conversionDate);
        system.debug(fdate);
        return fdate;
    }
    
    private String formatDate(Date inputDate) {
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
    
    private String convertYearToWords(Integer year) {
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
   /* private String convertToWords(Integer fNumber) {
        if (fNumber == null) {
            return '';
        }
        
        list<String> units = new List<String>{ '', 'First', 'Second', 'Third', 'Fourth', 'Fifth', 'Sixth', 'Seventh', 'Eighth', 'Nineth' };
            list<String> teens = new List<String>{ 'ten', 'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen', 'sixteen', 'seventeen', 'eighteen', 'nineteen' };
                list<String> tens = new List<String>{ '', '', 'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy', 'eighty', 'ninety' };
                    list<String> hundred = new List<String> { '', 'hundred' };
                        
                        String numberStr = String.valueOf(fNumber);
        Integer length = numberStr.length();
        
        String result = '';
        if(length == 2){
            Integer secondPart = Integer.valueOf(numberStr.substring(0, 2));
            if (secondPart >= 10 && secondPart < 20) {
                result += teens[secondPart - 10];            
            }else if (secondPart >= 20){
                Integer secondFirst = Integer.valueOf(numberStr.substring(0, 1));
                Integer secondLast = Integer.valueOf(numberStr.substring(1, 2));
                result += tens[secondFirst];
                if(secondLast > 0){
                    result += units[secondLast];
                }
            }
            result += 'th';
        }else{
            Integer firstPart = Integer.valueOf(numberStr.substring(0, 1));
            if (firstPart > 0) {
                result += units[firstPart];
            } 
        }
        return result.trim().replaceAll(' +', ' ');
}*/

}