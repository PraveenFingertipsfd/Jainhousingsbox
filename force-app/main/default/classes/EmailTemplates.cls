public class EmailTemplates {

    public static void sendBookingRequisitionEmail(Id unitId) {
        // Getting booking records
        List<Booking_Request__c> bookings = [
            SELECT Id, Customer_Name__c, Email__c
            FROM Booking_Request__c 
            WHERE Unit__c = :unitId 
            LIMIT 1
        ];

        if (bookings.isEmpty()) {
            System.debug('No booking request found for Unit Id: ' + unitId);
            return;
        }

        Booking_Request__c booking = bookings[0];
        
        string urlval = label.Org_url;
            system.debug(urlval);
            Site mySite = [SELECT Id, Name, Subdomain, UrlPathPrefix FROM Site WHERE Name = 'Booking_Request_Site' LIMIT 1];
            system.debug(mySite.UrlPathPrefix);


        String subject = 'Welcome to Jain Housing – Let\'s Get Started on Your Dream Home!';
        
        String body = 'Dear ' + booking.Customer_Name__c + ',<br/><br/>' +
            'Thank you for choosing <strong>Jain Housing</strong> to purchase your dream home. ' +
            'We are truly delighted to be part of this important milestone in your life.<br/><br/>' +
            'With over three decades of trusted experience in South India, Jain Housing is committed to delivering quality homes and exceptional service. ' +
            'It is our privilege to assist you on this exciting journey.<br/><br/>' +
            'To continue with the booking, please click the link below to fill in your basic details and make the booking advance:<br/>' +
            '<a href="'+urlval+'/'+ mySite.UrlPathPrefix +'?Id='+unitId+'&BkReqId='+booking.Id+'">Click here to request for Booking</a><br/>'+
            'If you have any questions or need assistance, feel free to reach out to our Sales Team.<br/><br/>' +
            'Warm regards,<br/>' +
            '<strong>Sales Team</strong><br/>' +
            '<strong>Jain Housing</strong>';

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[] { booking.Email__c });
        email.setSubject(subject);
        email.setHtmlBody(body); 
        email.setSenderDisplayName('Jain Housing');

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }

    public static void ReceiptEmail(Id receiptId) {
        
 // Getting booking records
        List<Receipt__c> receipts = [
            SELECT Id, Booking__c,Booking__r.First_Applicant_Name__c,Booking__r.Email1__c, Booking__r.Alternate_Email1__c
            FROM Receipt__c 
            WHERE Id = :receiptId 
            LIMIT 1
        ];  
         if (receipts.isEmpty()) {
            System.debug('No booking request found for Unit Id: ' + receiptId);
            return;
        }
        Receipt__c receipt = receipts[0];
        
        String subject = 'Payment Receipt – Thank You';
        string body = 'Dear ' + receipt.Booking__r.First_Applicant_Name__c + ',<br/><br/>' +
            'Thank you for your payment. Please find the attached receipt for your reference and records. <br/>'+
            'We truly appreciate your continued cooperation. Every step forward brings us closer to handing over a home that meets your expectations and brings lasting satisfaction. <br/>'+
            'If you have any questions regarding this payment or require further assistance, please don’t hesitate to reach out. Our team is always here to support you. <br/>'+
            'Team Jain Housing ';
        
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
       // email.setToAddresses(new String[] { receipt.Booking__r.Email1__c, receipt.Booking__r.Alternate_Email1__c});
       // 
       
       List<String> recipients = new List<String>();
        if(receipt.Booking__r.Email1__c != null){
            recipients.add(receipt.Booking__r.Email1__c);
        }
        if(receipt.Booking__r.Alternate_Email1__c != null){
            recipients.add(receipt.Booking__r.Alternate_Email1__c);
        }
        if(!recipients.isEmpty()){
           email.setToAddresses(recipients);  
        }
        else{
            system.debug('No valid email address found');
        }
       
         //Creating a list to hold email attachments
        List<Messaging.EmailFileAttachment> attachments =  new List<Messaging.EmailFileAttachment>();
        
         //Setting email attacehments
        PageReference bookingPage = Page.RECEIPT;
        bookingPage.getParameters().put('id', receiptId);
        Blob bookingPDF = bookingPage.getContent();
        
         
        Messaging.EmailFileAttachment bookingAttachment = new Messaging.EmailFileAttachment();
        bookingAttachment.setFileName('Receipt.pdf');
        bookingAttachment.setBody(bookingPDF);
        bookingAttachment.setContentType('application/pdf');
        attachments.add(bookingAttachment);
         email.setFileAttachments(attachments);

        
        email.setSubject(subject);
        email.setHtmlBody(body); 
        email.setSenderDisplayName('Jain Housing');

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        
    }
    
    public static void BookingFormAndScheduleOfPayments(Id BookingId){
         List<Booking__c> bookings = [
            SELECT Id, First_Applicant_Name__c, Email1__c, Alternate_Email1__c
            FROM Booking__c 
            WHERE Id = :BookingId 
            LIMIT 1
        ]; 
        if(bookings.isEmpty()){
          System.debug('No booking request found for booking Id: ' + BookingId);
            return;   
        }
        Booking__c booking = bookings[0];
        
         String subject = 'Booking Allotment Form & Cash Flow Details – Jain Housing ';
        string body = 'Dear ' + booking.First_Applicant_Name__c + ',<br/><br/>' +
            'Greetings from Jain Housing!  <br/>'+
            'Thank you for choosing Jain Housing as your trusted partner in finding your dream home. We are pleased to share with you the <strong>Booking Allotment Form</strong> and the <strong>Payment Schedule form</strong> related to your flat booking.  <br/>'+
            'Please find the attached documents for your reference:  <br/>'+
            '<ul>' +
        '<li>Booking Allotment Form</li>' +
        '<li>Payment Schedule / Cashflow Form</li>' +
    '</ul>' +
            '<br/>'+
            'These documents contain important details regarding your flat allotment and the associated payment structure. We kindly request you to review them thoroughly and adhere. Get in touch with us in case you have any queries or require further clarification. <br/>'+
            'We look forward to assisting you throughout your home-buying journey. <br/>'+
            'Warm regards,<br/>'+
            'Customer Relations Team<br/>'+
            '<strong>Jain Housing LLP. </strong>';
       
        
        
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSubject(subject);
        email.setHtmlBody(body);
        email.setSenderDisplayName('Jain Housing');
         List<String> recipients = new List<String> ();
        if(booking.Email1__c !=null){
            recipients.add(booking.Email1__c);
        }
        if(booking.First_Applicant_Name__c !=null){
            recipients.add(booking.First_Applicant_Name__c);
        }
        if(!recipients.isEmpty()){
         email.setToAddresses(recipients);  
        }
        else{
            system.debug('no valid email id exists');
            return;
            
        }
        
       //Creating a list to hold email attachments
        List<Messaging.EmailFileAttachment> attachments =  new List<Messaging.EmailFileAttachment>();
        
         //Setting email attacehments
        PageReference bookingPage = Page.AadhyaBookingForm;
        bookingPage.getParameters().put('id', BookingId);
        Blob bookingPDF = bookingPage.getContent();
        
        Messaging.EmailFileAttachment bookingAttachment = new Messaging.EmailFileAttachment();
        bookingAttachment.setFileName('Booking_Allotment_Form.pdf');
        bookingAttachment.setBody(bookingPDF);
        bookingAttachment.setContentType('application/pdf');
        attachments.add(bookingAttachment);
         email.setFileAttachments(attachments);

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });  
        
    }
    
    public static void WelcomeEmail(Id bookingId){
         List<Booking__c> bookings = [
            SELECT Id, First_Applicant_Name__c, Email1__c, Alternate_Email1__c
            FROM Booking__c 
            WHERE Id = :BookingId 
            LIMIT 1
        ]; 
        if(bookings.isEmpty()){
          System.debug('No booking request found for booking Id: ' + BookingId);
            return;   
        }
        Booking__c booking = bookings[0];
        
        
        String subject = 'Welcome to Jain Housing – Your Journey to a New Home Begins! ';
        String body = 'Dear Customer,<br/><br/> '+
           'Greetings from Jain Housing!<br/> '+
            'We are delighted to guide you through the exciting journey of owning your new home with us. It is both an honor and a privilege to welcome you to the Jains family. <br/>'+
            'Since our inception in 1987, Jain Housing has prioritized customer satisfaction, which has become our greatest strength. Over the years, we have had the privilege of housing over 21,000+ families across South India, a testament to our unwavering commitment to our customers. We fully understand the joy and importance of owning a beautiful home, and at Jain Housing, we strive to make this process as seamless and effortless as possible. From the moment you book your apartment until the final handover, our team is dedicated to providing service of the highest quality, on par with global standards. <br/>'+
            'This commitment to exceeding the expectations of our growing customer base has contributed to our success. To date, we have completed over 200 prestigious projects, spanning over 20 million square feet of excellence. <br/>'+
            '<strong>Next Steps in Your Journey: </strong><br/>'+
            '<ul>'+
            '<li><strong>Welcome Call:</strong> We will reconfirm all details mentioned in your booking application during a welcome call. If you require financial assistance through a home loan, our customer relationship management team will assist you with providing relevant banker contacts. Please note, while we will support you in the loan process, the responsibility for loan repayments and timely payments to us lies with you.</li>'+
            '<li><strong>Sale Agreement:</strong> Once the 10% booking advance is completed, we will initiate the Sale Agreement. Please confirm and sign the draft agreement within 3-4 business days. </li>'+
            '<li><strong>Project Updates: </strong> To ensure smooth progress, we will periodically update you about the status of your project via email. You can also reach out to your Customer Relationship Executive for site progress updates. </li>'+
            '<li><strong>Registration: </strong> Once you have completed 100% of the payment for your flat, we will proceed with the registration. If the total cost of the flat exceeds INR 50 Lakhs, 1% TDS will be deducted by you from the total cost, and proof of remittance must be provided before the registration. Our Customer Relationship Executive will guide you through the process. </li>'+
            '<li><strong>Hand over:</strong> Once 100% payment is completed and along with all other charges, we shall issue No Due Certificate, Possession letter, Car Parking letter and Keys. </li><br/>'+
            '<strong>Key Contact Information: </strong><br/>'+
            'For any assistance, feel free to contact your Customer Relationship Executives at: <br/>'+
            '<ul>'+
            '<li>044-49494510 </li>'+
            '<li>044-49494512 </li>'+
            '<li>044-49494514</li>'+
            '</ul>'+
            '(Available from 11 AM to 5 PM on all working days) <br/>'+
            '<strong>Our Core Values: </strong>'+
            '<ul>'+
            '<li><strong>Integrity: </strong> Commitment to honesty, transparency, and ethical business practices in all dealings.</li>'+
            '<li><strong>Innovation: </strong> Continuously seeking new and creative solutions for design, development, and technology.</li> '+
            '<li><strong>Excellence:</strong> Striving for the highest standards in every project, from design and construction to customer service. </li>'+
            '<li><strong>Accountability: </strong> Ensuring projects are completed on time and to the highest standards.</li>'+
            '<li><strong>Community Focus:<strong> Developing properties that improve communities and positively impact local economies. </li>'+
            '<li> <strong>Transparency: </strong>Open and clear communication with all stakeholders, providing regular updates.</li> '+
            '</ul>'+

'Homeownership is a significant milestone, and we are honored to be part of this special journey with you. Thank you for choosing Jain Housing, and we look forward to delivering the home of your dreams. <br/>'+
            'Best Regards<<br/>'+
            'CRM Team<br/>'+
            'Jain Housing ';
         Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSubject(subject);
        email.setHtmlBody(body);
        email.setSenderDisplayName('Jain Housing');
         List<String> recipients = new List<String> ();
        if(booking.Email1__c !=null){
            recipients.add(booking.Email1__c);
        }
        if(booking.First_Applicant_Name__c !=null){
            recipients.add(booking.First_Applicant_Name__c);
        }
        if(!recipients.isEmpty()){
         email.setToAddresses(recipients);  
        }
        else{
            system.debug('no valid email id exists');
            return;
            
        } 
            
            
    }
    
    public static void saleAgreementDraftCopySharing( Id bookingId)
    {
         List<Booking__c> bookings = [
            SELECT Id, First_Applicant_Name__c, Email1__c, Alternate_Email1__c
            FROM Booking__c 
            WHERE Id = :BookingId 
            LIMIT 1
        ]; 
        if(bookings.isEmpty()){
          System.debug('No booking request found for booking Id: ' + BookingId);
            return;   
        }
        Booking__c booking = bookings[0];
        
        String subject = 'Draft Sale Agreement – Jain Housing';
        String body = 'Dear Customer,<br/>'+
            'Good day to you! <br/>'+
            'Please find attached the draft of the Agreement for Sale for your review. We kindly request you to go through the document carefully and verify the accuracy of the name, age, PAN, Aadhaar, and other personal KYC details of both the applicant and co-applicant, as mentioned. <br/>'+
            'We request you to sign the agreement within 3 days from the date of this email. You may choose one of the following options: <br/>'+
            '<ul>'+
            '<li> <strong>Visit our office </strong> and sign the agreement in person, by coordinating with your Customer Relationship Executive </li>'+
            '<li> <strong>Alternatively,</strong> we will be happy to arrange for one of our representatives to visit you and get the agreement signed at your preferred location (Based on the proximity and availability of the representative)</li>'+
            '</ul>'+
            'We look forward to your prompt response and continued cooperation. <br/>'+
            'Warm regards,<br/>'+
            'Customer Relations Team<br/>'+
            '<strong>Jain Housing </strong>';
        
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSubject(subject);
        email.setHtmlBody(body);
        email.setSenderDisplayName('Jain Housing');
         List<String> recipients = new List<String> ();
        if(booking.Email1__c !=null){
            recipients.add(booking.Email1__c);
        }
        if(booking.First_Applicant_Name__c !=null){
            recipients.add(booking.First_Applicant_Name__c);
        }
        if(!recipients.isEmpty()){
         email.setToAddresses(recipients);  
        }
        else{
            system.debug('no valid email id exists');
            return;
            
        } 
        
        
         //Creating a list to hold email attachments
        List<Messaging.EmailFileAttachment> attachments =  new List<Messaging.EmailFileAttachment>();
        
         //Setting email attacehments
        PageReference bookingPage = Page.SALE_AGREEMENT_AARYA;
        bookingPage.getParameters().put('id', bookingId);
        Blob bookingPDF = bookingPage.getContent();
        
         
        Messaging.EmailFileAttachment bookingAttachment = new Messaging.EmailFileAttachment();
        bookingAttachment.setFileName('Sale_Agreement.pdf');
        bookingAttachment.setBody(bookingPDF);
        bookingAttachment.setContentType('application/pdf');
        attachments.add(bookingAttachment);
         email.setFileAttachments(attachments);

    }
    
    
    public static void getReadyForRegistration(Id bookingId ){
         List<Booking__c> bookings = [
            SELECT Id, First_Applicant_Name__c, Email1__c, Alternate_Email1__c
            FROM Booking__c 
            WHERE Id = :BookingId 
            LIMIT 1
        ]; 
        if(bookings.isEmpty()){
          System.debug('No booking request found for booking Id: ' + BookingId);
            return;   
        }
        Booking__c booking = bookings[0];
        
        String subject = '';
        String body = 'Dear Customer,'+
            'Greetings from Jain Housing! <br/>'+
            'We are delighted to inform you that all formalities and payments for your flat have been successfully completed. As part of the final handover process, please find the following documents attached for your records: <br/>'+
            '<0l>'+
            '<li><strong>No Due Certificate  </strong></li>'+
            '<li><strong>Possession Letter  </strong></li>'+
            '</ol><br/>'+
            'On behalf of the entire team at Jain Housing, I would like to thank you sincerely for placing your trust in us. It has been our privilege to serve you throughout this journey, and we are proud to welcome you as a valued member of the Jain Housing family. <br/>'+
            
            'We wish you and your loved ones a joyful, peaceful, and prosperous life in your new home. May it bring you happiness and wonderful memories for years to come. <br/>'+
            
            'Should you need any further assistance, please feel free to reach out to us at any time—we’re always here to help. <br/>'+
            'Warm regards,<br/>'+
            'Customer Relationship Manager<br/>'+
            'Jain Housing <br/>';
         
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSubject(subject);
        email.setHtmlBody(body);
        email.setSenderDisplayName('Jain Housing');
         List<String> recipients = new List<String> ();
        if(booking.Email1__c !=null){
            recipients.add(booking.Email1__c);
        }
        if(booking.Alternate_Email1__c !=null){
            recipients.add(booking.Alternate_Email1__c);
        }
        if(!recipients.isEmpty()){
         email.setToAddresses(recipients);  
        }
        else{
            system.debug('no valid email id exists');
            return;
            
        } 
        
        
         //Creating a list to hold email attachments
        List<Messaging.EmailFileAttachment> attachments =  new List<Messaging.EmailFileAttachment>();
        
         //Setting email attacehments
         //attaching NDC
        PageReference bookingPage = Page.NDC;
        bookingPage.getParameters().put('id', BookingId);
        Blob bookingPDF = bookingPage.getContent();
        
        Messaging.EmailFileAttachment bookingAttachment = new Messaging.EmailFileAttachment();
        bookingAttachment.setFileName('No_Due_Certificate.pdf');
        bookingAttachment.setBody(bookingPDF);
        bookingAttachment.setContentType('application/pdf');
        attachments.add(bookingAttachment);
         email.setFileAttachments(attachments);
        
        
        //attaching possesion letter
         PageReference possessionPage = Page.PossessionLetter;
        possessionPage.getParameters().put('id', BookingId);
        Blob bookingPDF2 = possessionPage.getContent();
        
         Messaging.EmailFileAttachment possssionAttachment = new Messaging.EmailFileAttachment();
        possssionAttachment.setFileName('Possession_Letter.pdf');
        possssionAttachment.setBody(bookingPDF2);
        possssionAttachment.setContentType('application/pdf');
        attachments.add(possssionAttachment);
         email.setFileAttachments(attachments);
        
        email.setFileAttachments(attachments);
        
        //Sending emails
         Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
      
        
        
    }
    public static void jointInspectionCustomerInvite(Id bookingId, Id jointId){
         List<Booking__c> bookings = [
            SELECT Id, First_Applicant_Name__c, Email1__c, Alternate_Email1__c
            FROM Booking__c 
            WHERE Id = :BookingId 
            LIMIT 1
        ]; 
        if(bookings.isEmpty()){
          System.debug('No booking request found for booking Id: ' + BookingId);
            return;   
        }
        Booking__c booking = bookings[0];
        String subject = 'Your Flat is Ready for Handover – Invitation for Joint Inspection ';
        String body = 'Dear [Customer\'s Name], <br/><br/>'+
            'Greetings from Jain Housing! <br/>'+
            'We are delighted to inform you that your flat is now ready for handover. As part of our customer handover process, we request you to kindly schedule a joint inspection of your flat along with our site engineer. This step ensures that everything meets your expectations before you take possession. <br/>'+
            'Once you are satisfied with the condition of your home, you will be asked to sign the <strong>Customer Satisfaction Report (CSR)</strong> as a confirmation of satisfactory handover. <br/>'+
            'If you observe any snags during the inspection, we request you to share the snag points with us. Our team will address them within <strong> 15 working days</strong>, depending on the nature and complexity of the work. <br/>'+
            '<strong>We also request you to kindly be prepared to release the final handover payments</strong> as part of the possession formalities. This will allow us to process your<strong> No Due Certificate</strong> and complete the final documentation smoothly.<br/> '+
            'Please note that the <strong>CP and sanitary fittings, as well as the final coat of paint</strong>, will be carried out <strong>only after 100% payment is received and the No Due Certificate is issued</strong>. We appreciate your understanding and cooperation in this regard.<br/>'+
            'To proceed, please schedule your joint inspection appointment through the <strong>Customer Portal/Mobile app</strong>, where you can choose a convenient date and time from the options given.<br/><br/>'+
            'If you need any assistance in accessing the portal or booking your appointment, our CRM Executive will be happy to help. <br/>'+
            'Thank you once again for choosing Jain Housing. We truly value your trust in us and look forward to welcoming you to your new home. Wishing you and your family a happy and prosperous life ahead! <br/>'+
            'Warm regards, <br/>'+
            'Team Jain Housing <br/>';
 Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSubject(subject);
        email.setHtmlBody(body);
        email.setSenderDisplayName('Jain Housing');
         List<String> recipients = new List<String> ();
        if(booking.Email1__c !=null){
            recipients.add(booking.Email1__c);
        }
        if(booking.Alternate_Email1__c !=null){
            recipients.add(booking.Alternate_Email1__c);
        }
        if(!recipients.isEmpty()){
         email.setToAddresses(recipients);  
        }
        else{
            system.debug('no valid email id exists');
            return;
            
        } 
            
            
    }
    
    public static void demandRaiseEmail(Id bookingId, Id paymentscheduleId){
         List<Booking__c> bookings = [
            SELECT Id, First_Applicant_Name__c, Email1__c, Alternate_Email1__c
            FROM Booking__c 
            WHERE Id = :BookingId 
            LIMIT 1
        ]; 
        if(bookings.isEmpty()){
          System.debug('No booking request found for booking Id: ' + BookingId);
            return;   
        }
        Booking__c booking = bookings[0];
        
        String subject = 'Jain Housing - Payment Due – Demand Letter Attached';
        String body = 'Dear bookings.First_Applicant_Name__c, <br/><br/>'+
            'Greetings from Jain Housing! <br/>'+
            'Please find attached the <strong>demand letter</strong> for the payment due, as per the payment schedule agreed upon during the booking of your flat. We kindly request you to make the payment as per the specified due date to ensure a smooth progression of work. <br/>'+
            'All relevant details, including the payment amount and bank information, are provided in the attachment for your reference. <br/>'+
            'We appreciate your continued cooperation and timely support. <br/>'+
            'Should you have any questions or require assistance, please feel free to reach out to your assigned <strong>CRM Executive</strong>—we’re here to help. <br/>'+
            'Thank you once again for choosing Jain Housing. <br/>'+
            'Warm regards,<br/>'+
            'CRM team<br/>'+
            'Jain Housing ';
         Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSubject(subject);
        email.setHtmlBody(body);
        email.setSenderDisplayName('Jain Housing');
         List<String> recipients = new List<String> ();
        if(booking.Email1__c !=null){
            recipients.add(booking.Email1__c);
        }
        if(booking.First_Applicant_Name__c !=null){
            recipients.add(booking.First_Applicant_Name__c);
        }
        if(!recipients.isEmpty()){
         email.setToAddresses(recipients);  
        }
        else{
            system.debug('no valid email id exists');
            return;
        }
            
           List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
            //attaching docs
            PageReference bookingPage = Page.DEMAND_LETTER_SEND_AARYA;
        bookingPage.getParameters().put('id', BookingId);
        Blob bookingPDF = bookingPage.getContent();
        
        Messaging.EmailFileAttachment bookingAttachment = new Messaging.EmailFileAttachment();
        bookingAttachment.setFileName('No_Due_Certificate.pdf');
        bookingAttachment.setBody(bookingPDF);
        bookingAttachment.setContentType('application/pdf');
        attachments.add(bookingAttachment);
         email.setFileAttachments(attachments);
            
            
        
        
    }
    
    
}