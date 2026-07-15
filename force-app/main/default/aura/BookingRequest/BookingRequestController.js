({
    doInit : function(component, event, helper) {
        //component.set("v.showPaymentSection",true);
        const queryString = window.location.search;
        const urlParams = new URLSearchParams(queryString); 
        const recId = urlParams.get('Id');
        component.set("v.recordId",recId);
        helper.getunitdetail(component,event,helper);   
        
        // Get picklist values
        helper.getPicklistValues(component);
        
        //helper.getunitdetail(component,event,helper);   
        
        var bookingReq = component.get("v.BookingReq");
        if (!bookingReq) {
            component.set("v.BookingReq", {
                'sobjectType': 'Booking_Request__c',
                'Customer_Name__c': '',
                'Aadhaar_Number__c': '',
                'PAN_Number__c': '',
                'Mobile__c': '',
                'Unit__c':recId,
                'Id':component.get('v.BkReqId'),
                'IsResponded__c':true
            });
        }
        
         var paydet = component.get("v.PaymentDetails");
        if (!paydet) {
            component.set("v.PaymentDetails", {
                'sobjectType': 'Advance_Payment__c',
                'Mode_of_Payment__c': '',
                'Bank__c': '',
                'Cheque_no_Transaction_Number__c': '',
                'Amount__c': null,
                'Booking_Request__c':'',
                'Cheque_Date__c':''
            });
        }
        
    },
    
    proceedToPayment: function(component, event, helper) {
        var BookingReq = component.get('v.BookingReq');
        
        if(BookingReq.Customer_Name__c ==''  || BookingReq.Customer_Name__c ==null || BookingReq.Customer_Name__c.trim() =='' || BookingReq.Customer_Name__c == undefined ){
            alert('Please Enter Customer Name');
        }
        else if(BookingReq.Aadhaar_Number__c ==''  || BookingReq.Aadhaar_Number__c ==null || BookingReq.Aadhaar_Number__c.trim() =='' || BookingReq.Aadhaar_Number__c == undefined){
            alert('Please Enter Aadhaar Number');
        }
        else if(!/^\d{12}$/.test(BookingReq.Aadhaar_Number__c.trim()) ){
            alert('Please Enter 12 digit Aadhaar Number');
        }
        else if(BookingReq.PAN_Number__c ==''  || BookingReq.PAN_Number__c ==null || BookingReq.PAN_Number__c.trim() =='' || BookingReq.PAN_Number__c == undefined ){
            alert('Please Enter PAN Number');
        }
        else if (!/^[A-Z]{5}[0-9]{4}[A-Z]{1}$/.test(BookingReq.PAN_Number__c.trim().toUpperCase())) {
            alert('PAN Number must be in format: 5 letters, 4 digits, 1 letter (e.g., ABCDE1234F)');
        }        
        else if(!/^\d+$/.test(BookingReq.Mobile__c.trim()) || BookingReq.Mobile__c ==''  || BookingReq.Mobile__c ==null || BookingReq.Mobile__c.trim() =='' || BookingReq.Mobile__c == undefined ){
            alert('Please Enter 10 digit Mobile Number');
        }
        /* commented  by karthik 08-08
        else if(BookingReq.Customer_Comments__c ==''  || BookingReq.Customer_Comments__c ==null || BookingReq.Customer_Comments__c.trim() =='' || BookingReq.Customer_Comments__c == undefined ){
            alert('Please Enter Comments');
        }
        */
        else {
            component.set('v.showPaymentSection', true);
            component.set("v.currentStep", 2); 
        }
    },
    
    handleAccept :function(component, event, helper){
        component.set('v.IsSaveDisabled',true);
        helper.saveData(component, event, helper);
    },
    
    showSpinner: function(component, event, helper) {
        component.set("v.spinner", true); 
    },
    
    hideSpinner : function(component,event,helper){      // function automatic called by aura:doneWaiting event 
        component.set("v.spinner", false);
    },
    
    handlePaymentModeChange: function(component, event, helper) {
        var selectedValue = event.getSource().get("v.value");
        var paymentDetails = component.get("v.PaymentDetails");
        
        // Clear bank and cheque details when switching to Cash
        if (selectedValue === 'Cash') {
            paymentDetails.Bank__c = '';
            paymentDetails.Cheque_no_Transaction_Number__c = '';
        }
        
        paymentDetails.Mode_of_Payment__c = selectedValue;
        component.set("v.PaymentDetails", paymentDetails);
        
        // Force a re-render of the component
        component.set("v.reRender", Math.random());
    },
    
    handleBack: function(component, event, helper) {
        component.set('v.showPaymentSection', false);
    },
    
    handleBankChange: function(component, event, helper) {
        var selectedValue = event.getSource().get("v.value");
        var paymentDetails = component.get("v.PaymentDetails");
        paymentDetails.Bank__c = selectedValue;
        component.set("v.PaymentDetails", paymentDetails);
    },
    
    restrictToNumbers: function(component, event, helper) {
        var inputField = event.getSource();
        var inputValue = inputField.get("v.value");
        
        // Remove any non-numeric characters
        var numericValue = inputValue.replace(/\D/g, '');
        
        // Update the field value (truncate to 12 digits)
        inputField.set("v.value", numericValue.substring(0, 12));
    },
    
    validateAadhaar: function(component, event, helper) {
        var aadhaarField = event.getSource();
        var aadhaarValue = aadhaarField.get("v.value");
        var bookingReq = component.get("v.BookingReq");
        
        // Update the model value
        bookingReq.Aadhaar_Number__c = aadhaarValue;
        component.set("v.BookingReq", bookingReq);
        
        // Set custom validity
        if (!/^\d{12}$/.test(aadhaarValue)) {
            aadhaarField.setCustomValidity("Please enter exactly 12 digits");
        } else {
            aadhaarField.setCustomValidity(""); // Clear any error
        }
        aadhaarField.reportValidity();
    },
    
    copyUPIId: function(component, event, helper) {
        // Get UPI ID from custom label
        $A.get("$Label.c.UPI_ID", function(upiId) {
            // Create temporary input element
            var hiddenInput = document.createElement("input");
            hiddenInput.setAttribute("value", upiId);
            document.body.appendChild(hiddenInput);
            
            // Select and copy
            hiddenInput.select();
            document.execCommand("copy");
            document.body.removeChild(hiddenInput);
            
        });
    },
    
    
})