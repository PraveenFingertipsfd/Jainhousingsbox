public class AadhyaBookingFormController {
    // The main booking record
    public Booking__c booking { get; set; }

    // ID parameter from Visualforce page
    public Id bookingId { get; set; }

    // URL for the signature image
    public String signatureUrl { get; set; }
    
    public String applicantPhotoUrl { get; set; }
    
     // List of co-applicants (max 4)
    public List<CoApplicantWrapper> coApplicants { get; set; }
    
    // Wrapper class for co-applicant data
    public class CoApplicantWrapper {
        public String fullName { get; set; }
        public String age { get; set; }
        public String relation { get; set; }
        public String aadhar { get; set; }
        public String pan { get; set; }
    }

    // Constructor
    public AadhyaBookingFormController() {
        // Get the booking ID from page parameters
        bookingId = ApexPages.currentPage().getParameters().get('id');

        // Initialize the booking record
        booking = new Booking__c();
        coApplicants = new List<CoApplicantWrapper>();

        // Load data if ID is provided
        if (bookingId != null) {
            loadBookingDetails();
            fetchSignatureUrl();
            loadCoApplicants();
        }
    }
    
    // Method to fetch co-applicants (max 4)
    private void loadCoApplicants() {
        List<Co_Applicant__c> coApplicantList = [
            SELECT Name, Co_Age__c, Relalation_Details__c, Aadhar_Number__c, PAN_Number__c
            FROM Co_Applicant__c
            WHERE Booking__c = :bookingId
            ORDER BY CreatedDate
            LIMIT 4
        ];
        
        // Create wrapper objects for each co-applicant
        for (Co_Applicant__c ca : coApplicantList) {
            CoApplicantWrapper wrapper = new CoApplicantWrapper();
            wrapper.fullName = ca.Name;
            wrapper.age = String.valueOf(ca.Co_Age__c);
            wrapper.relation = ca.Relalation_Details__c;
            wrapper.aadhar = ca.Aadhar_Number__c;
            wrapper.pan = ca.PAN_Number__c;
            coApplicants.add(wrapper);
        }
        
        // Ensure we always have 4 rows (empty if needed)
        while (coApplicants.size() < 4) {
            coApplicants.add(new CoApplicantWrapper());
        }
    }

    // Method to fetch Booking details
    private void loadBookingDetails() {
        booking = [
            SELECT Id, Name, First_Applicant_Name__c, Super_Built_up_area_NE__c, Booking_Date__c,Bank__c,
                   Plot__r.Name,Marital_Status__c,Applied_to_any_Bank__c,Address_for_Registration__c,Profession1__c,Gender__c,Name_of_Company1__c,Designation1__c,Company_Address__c,Communication_address1__c,Permanent_Address1__c,Mobile_Primary1__c,Email1__c,Alternate_Email1__c,Mobile_Alternate1__c,Date_of_Birth1__c,Age__c,Anniverssary_Date__c,Flat_Actual_Number__c, FloorNo__c, Carpet_Area__c,Cost_Sheet__r.Car_Parking_Type__c,Total__c,salutation_Applicant1__c
            FROM Booking__c
            WHERE Id = :bookingId
            LIMIT 1
        ];
        
        List<ContentDocumentLink> fileLinks = [
            SELECT ContentDocumentId, 
            ContentDocument.Title, 
            ContentDocument.LatestPublishedVersionId 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :booking.Id
        ];
        
        for (ContentDocumentLink link : fileLinks) {
            if (link.ContentDocument.Title != null && 
                link.ContentDocument.Title.contains('[ Applicant Photo ]')) {
                    
                    // Use renditionDownload instead of download
                    applicantPhotoUrl = '/sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB720BY480&versionId=' + 
                        link.ContentDocument.LatestPublishedVersionId;
                    break;
                }
        }
        
        
    }
    
/*
    // Method to fetch the signature image URL
    private void fetchSignatureUrl() {
        // Get ContentDocumentLinks related to the Booking__c record
        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :bookingId
        ];

        // Extract ContentDocumentIds from the links
        List<Id> documentIds = new List<Id>();
        for (ContentDocumentLink link : links) {
            documentIds.add(link.ContentDocumentId);
        }

        if (!documentIds.isEmpty()) {
            // Get the ContentVersion with the title 'signature.png'
            List<ContentVersion> versions = [
                SELECT Id, Title
                FROM ContentVersion
                WHERE ContentDocumentId IN :documentIds
                AND Title = 'Signature.png'
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];

            if (!versions.isEmpty()) {
                signatureUrl = '/sfc/servlet.shepherd/version/download/' + versions[0].Id;
            }
        }
    }*/
/*
    private void fetchSignatureUrl() {
        Attachment att = [
            SELECT Id, Name
            FROM Attachment
            WHERE ParentId = :bookingId AND Name = 'signature.png'
            ORDER BY LastModifiedDate DESC
            LIMIT 1
        ];
        
        if (att != null) {
            signatureUrl = '/servlet/servlet.FileDownload?file=' + att.Id;
        }
    }*/
    
    private void fetchSignatureUrl() {
        List<Attachment> attachments = [
            SELECT Id, Name
            FROM Attachment
            WHERE ParentId = :bookingId AND Name = 'signature.png'
            ORDER BY LastModifiedDate DESC
            LIMIT 1
        ];
        
        if (!attachments.isEmpty()) {
            signatureUrl = '/servlet/servlet.FileDownload?file=' + attachments[0].Id;
        } else {
            signatureUrl = null; // or set a default value, or leave blank
        }
    }

}