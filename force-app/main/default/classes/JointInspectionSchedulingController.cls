public class JointInspectionSchedulingController {
    public String inspectionId { get; set; }
    public String projectName { get; set; }
    public String unitName { get; set; }
    public Date inspectionDate { get; set; }
    public Time inspectionTime { get; set; }
    public Boolean showForm { get; set; }
    public Boolean isExpired { get; set; }
    public Boolean alreadyResponded { get; set; }
    public String existingInspectionDate { get; set; }
    public Boolean isSuccess { get; set; }
    public Boolean isDateValid { get; set; }
    public Boolean isTimeValid { get; set; }
    public String dateValidationMessage { get; set; }
    
    // Getter for today's date
    public Date TODAY {
        get { return Date.today(); }
    }
    
    // Set of public holidays
    private Set<Date> publicHolidays {
        get {
            if (publicHolidays == null) {
                publicHolidays = new Set<Date>();
                String holidaysString = System.Label.Public_Holidays;
                if (String.isNotBlank(holidaysString)) {
                    for (String dateStr : holidaysString.split(',')) {
                        try {
                            publicHolidays.add(Date.valueOf(dateStr.trim()));
                        } catch (Exception e) {
                            System.debug('Error parsing holiday date: ' + dateStr);
                        }
                    }
                }
            }
            return publicHolidays;
        }
        set;
    }
    
    public JointInspectionSchedulingController() {
        inspectionId = ApexPages.currentPage().getParameters().get('id');
        showForm = false;
        isExpired = false;
        alreadyResponded = false;
        isSuccess = false;
        isDateValid = true;
        isTimeValid = true;
        dateValidationMessage = '';
        
        if (String.isNotBlank(inspectionId)) {
            verifyInspectionAccess();
        } else {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR, 
                'Invalid inspection reference'
            ));
        }
    }
    
    private void verifyInspectionAccess() {
        List<Joint_Inspection__c> inspections = [
            SELECT Id, Is_Responded__c, Joint_Inspection_Status__c, 
                   Invite_Sent_Date_Time__c, Joint_Inspection_Date__c, 
                   Booking__r.Project1__r.Name, Booking__r.Plot__r.Name, 
                   Booking__r.First_Applicant_Name__c      
            FROM Joint_Inspection__c 
            WHERE Id = :inspectionId 
            LIMIT 1];
      
        if (inspections.isEmpty()) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR, 
                'Inspection record not found'
            ));
            return;
        }
        
        Joint_Inspection__c inspection = inspections[0];
        
        // Check if status is not "Scheduled"
        if (inspection.Joint_Inspection_Status__c != 'Scheduled' && inspection.Joint_Inspection_Status__c != 'Initiated') {
            isExpired = true;
            return;
        }
        
        // Check if already responded
        if (inspection.Is_Responded__c) {
            alreadyResponded = true;
            if (inspection.Joint_Inspection_Date__c != null) {
                DateTime adjustedDateTime = inspection.Joint_Inspection_Date__c.addHours(5).addMinutes(30);
                existingInspectionDate = adjustedDateTime.format('yyyy-MM-dd hh:mm a');
            } else {
                existingInspectionDate = 'Date not specified';
            }
            return;
        }
        
        // 7-day expiry check
        if (inspection.Invite_Sent_Date_Time__c != null && 
            inspection.Invite_Sent_Date_Time__c.addDays(7) < DateTime.now()) {
            isExpired = true;
            return;
        }
        
        projectName = inspection.Booking__r.Project1__r.Name;
        unitName = inspection.Booking__r.Plot__r.Name;
        showForm = true;
    }
    
    public PageReference scheduleInspection() {
        // Reset validation flags
        isDateValid = true;
        isTimeValid = true;
        dateValidationMessage = '';
        
        // Validate date and time
        validateDateTime();
        
        if (!isDateValid || !isTimeValid) {
            return null;
        }
        
        try {
            // Combine date and time
            DateTime inspectionDateTime = DateTime.newInstance(
                inspectionDate, 
                inspectionTime
            );
             
            // Update inspection record
            Joint_Inspection__c inspection = new Joint_Inspection__c(
                Id = inspectionId,
                Joint_Inspection_Date__c = inspectionDateTime.addHours(-5).addMinutes(-30),
                Joint_Inspection_Status__c = 'Scheduled',
                Is_Responded__c = true
            );
            update inspection;
            
            // Show confirmation
            showForm = false;
            isSuccess = true;
            alreadyResponded = true;
            existingInspectionDate = inspectionDateTime.format('yyyy-MM-dd hh:mm a');
            
            return null;
        } catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR, 
                'Error: ' + e.getMessage()
            ));
            return null;
        }
    }
    
    private void validateDateTime() {
        // Validate date is not null
        if (inspectionDate == null) {
            isDateValid = false;
            dateValidationMessage = 'Please select a date';
            return;
        }
        
        // Validate date is not in the past
        if (inspectionDate < Date.today()) {
            isDateValid = false;
            dateValidationMessage = 'Please select today or a future date';
            return;
        }
        
        // Validate not Sunday
        Datetime dt = DateTime.newInstance(inspectionDate, Time.newInstance(0, 0, 0, 0));
        String dayOfWeek = dt.format('EEEE');
        if (dayOfWeek == 'Sunday') {
            isDateValid = false;
            dateValidationMessage = 'Sundays are not available for inspection';
            return;
        }
        
        // Validate not a public holiday
        if (publicHolidays.contains(inspectionDate)) {
            isDateValid = false;
            dateValidationMessage = 'Selected date is a public holiday';
            return;
        }
        
        // Validate time is not null
        if (inspectionTime == null) {
            isTimeValid = false;
            return;
        }
        
        // Validate time is between 10 AM and 4 PM
        Integer hour = inspectionTime.hour();
        if (hour < 10 || hour >= 16) {
            isTimeValid = false;
        }
    }
}