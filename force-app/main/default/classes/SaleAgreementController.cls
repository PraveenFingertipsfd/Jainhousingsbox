public class SaleAgreementController {
    public String Date_of_Booking { get; set; }
    public String Date_of_SaleAgreement { get; set; }
    public String BookingAmountInWords { get; set; }
    public String BookingTotalInWords { get; set; }
    public String totalAmountRecInWords { get; set; }
    public String totalCorpusFundWords { get; set; }
    public String FloorNumber { get; set; }
    public String Maintenance_Charge { get; set; }
    public list<Payment_schedule__c> paymentSchedule { get; set; }
    public Id bookingId;
    
    public SaleAgreementController(ApexPages.StandardController stdController) {
        bookingId = (Id)stdController.getId();
        NumberTOWordConvertion convert = new NumberTOWordConvertion();
        Booking__c booking = [SELECT Date_of_Booking__c,Net_Receipt_Amount__c,Total_received_Amount__c,Total_Corpus_fund__c,Total_Maintenance_charges__c,Sale_Agreement_Date__c,FloorNo__c,Total__c,Booking_Amount1__c,Maintenance_Charge__c FROM Booking__c WHERE Id = :bookingId LIMIT 1];
        paymentSchedule = [SELECT S_No__c,name,Payment_percent__c,AmountB__c FROM Payment_schedule__c WHERE Booking__c = :bookingId order by S_No__c]; 
        if (booking.Total_Maintenance_charges__c != null) {
            Maintenance_Charge = convert.getNumberTOWordConvertion(booking.Total_Maintenance_charges__c);
        }
        if (booking.Booking_Amount1__c != null) {
            BookingAmountInWords = convert.getNumberTOWordConvertion(booking.Booking_Amount1__c);
        }
         if (booking.Total_Corpus_fund__c != null) {
            totalCorpusFundWords = convert.getNumberTOWordConvertion(booking.Total_Corpus_fund__c);
        }
        if (booking.Total__c != null) {
           BookingTotalInWords = convert.getNumberTOWordConvertion(Math.round(booking.Total__c));
        }
        if (booking.Net_Receipt_Amount__c != null) {
            totalAmountRecInWords = convert.getNumberTOWordConvertion(booking.Net_Receipt_Amount__c);
        }
        if (booking.Date_of_Booking__c != null) {
            Date_of_Booking = getFormattedDate(booking.Date_of_Booking__c);
        }
        if (booking.Sale_Agreement_Date__c != null) {
            Date_of_SaleAgreement = getFormattedDate(booking.Sale_Agreement_Date__c);
        }
        if (booking.FloorNo__c != null) {
            if(booking.FloorNo__c.isNumeric()){
                FloorNumber = convertToWords(Integer.valueof(booking.FloorNo__c));
            }else{
                if(booking.FloorNo__c == 'G'){
                    FloorNumber = 'Ground ';
                }else{
                    FloorNumber = booking.FloorNo__c + ' th';
                }
            }
            
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
        String formattedDate = day + daySuffix + ' Day of  ' + monthMap.get(month) + ', ' + yearInWords;
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
    private String convertToWords(Integer fNumber) {
        if (fNumber == null) {
            return '';
        }
        
        list<String> units = new List<String>{ '', 'First', 'Second', 'Third', 'Fourth', 'Fifth', 'Sixth', 'Seventh', 'Eighth', 'Ninth' };
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
    }
}