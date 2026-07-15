public class BookingApprovalCtrl {
    public Booking__c booking { get; set; }
    public String approvalComments { get; set; }
    public Boolean showCancellation { get; set; }

    public BookingApprovalCtrl(ApexPages.StandardController std) {
        this.booking = (Booking__c)std.getRecord();

        // Fetch latest Booking record
        Booking__c latest = [SELECT Id, Stage__c FROM Booking__c WHERE Id = :booking.Id LIMIT 1];
        booking.Stage__c = latest.Stage__c;

        // Determine whether to show Cancellation Charges
        showCancellation = shouldShowCancellation(latest.Id, latest.Stage__c);
    }

    private Boolean shouldShowCancellation(Id bookingId, String stage) {
        // Check if stage is valid
        List<String> validStages = new List<String>{ 
            'Sale Agreement Execution Completed', 
            'Registration' 
        };
        Boolean validStage = validStages.contains(stage);

        if (!validStage) return false;

        // Fetch approved steps of approval process
        List<ProcessInstanceStep> steps = [
            SELECT StepStatus
            FROM ProcessInstanceStep
            WHERE ProcessInstance.TargetObjectId = :bookingId
            ORDER BY CreatedDate ASC
        ];

        Integer approvedCount = 0;
        for (ProcessInstanceStep step : steps) {
            if (step.StepStatus == 'Approved') {
                approvedCount++;
            }
        }

        // Show cancellation only if exactly 1 step is approved (i.e., in 2nd step)
        return approvedCount == 1;
    }

    public PageReference save() {
        Booking__c b = [SELECT Id, Stage__c, Cancellation_Charges__c FROM Booking__c WHERE Id = :booking.Id];

        Boolean validStage = shouldShowCancellation(b.Id, b.Stage__c);

        if (validStage && booking.Cancellation_Charges__c == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                'Cancellation Charges must be entered during second approval step.'));
            return null;
        }

        if (!validStage) {
            booking.Cancellation_Charges__c = null; // Clear if not applicable
        }

        try {
            update booking;

            // Update plot status if MD
            if (isMDUser()) {
                booking.Plot__r.Status__c = 'Available';
                update booking;
            }

            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Booking updated successfully.'));
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }

        return null;
    }

    public PageReference cancel() {
        return new ApexPages.StandardController(booking).cancel();
    }

    private Boolean isMDUser() {
        Profile currentProfile = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()];
        return currentProfile.Name == 'System Administrator'; // Fix typo if needed
    }
}