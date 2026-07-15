({
    getunitdetail : function(component, event, helper) {
        var action = component.get("c.GetUnitDetails");
        action.setParams({  recordId : component.get("v.recordId"),
                          BkreqId : component.get("v.BkReqId")});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                var records =response.getReturnValue();
                component.set('v.Unit',records.UnitRec);
                component.set('v.IsResponded',records.IsFormResponded);
                component.set('v.BkReqStatus',records.BkrqStatus);
            }
        });
        $A.enqueueAction(action);
    },
    
    saveData : function(component, event, helper) {
        component.set("v.spinner", true); 
        
        var BookingReq= component.get('v.BookingReq');
        var PaymentDetails = component.get('v.PaymentDetails');
        
        // Validate payment details if payment section was shown
        if(component.get('v.showPaymentSection')) {
            if(PaymentDetails.Mode_of_Payment__c == '' || PaymentDetails.Mode_of_Payment__c == null) {
                alert('Please select Payment Mode');
                component.set("v.spinner", false);
                component.set('v.IsSaveDisabled',false);
                return;
            }
            if(PaymentDetails.Amount__c == '' || PaymentDetails.Amount__c == null || PaymentDetails.Amount__c <= 0) {
                alert('Please enter valid Amount');
                component.set("v.spinner", false);
                component.set('v.IsSaveDisabled',false);
                return;
            }
            if(PaymentDetails.Mode_of_Payment__c != 'Cash') {
                if(PaymentDetails.Bank__c == '' || PaymentDetails.Bank__c == null) {
                    alert('Please select Bank');
                    component.set("v.spinner", false);
                    component.set('v.IsSaveDisabled',false);
                    return;
                }
                if(PaymentDetails.Cheque_no_Transaction_Number__c == '' || PaymentDetails.Cheque_no_Transaction_Number__c == null) {
                    alert('Please enter Cheque/Transaction Number');
                    component.set("v.spinner", false);
                    component.set('v.IsSaveDisabled',false);
                    return;
                }
                if(PaymentDetails.Mode_of_Payment__c == 'Cheque') {
                    if(PaymentDetails.Cheque_Date__c == '' || PaymentDetails.Cheque_Date__c == null) {
                        alert('Please fill cheque date');
                        component.set("v.spinner", false);
                        component.set('v.IsSaveDisabled',false);
                        return;
                    }
                }
            }
            
        }
        
        BookingReq.PAN_Number__c = BookingReq.PAN_Number__c.toUpperCase();
        BookingReq.Stage__c = 'Cost Sheet Preparation';
        
        PaymentDetails.Booking_Request__c = component.get("v.BkReqId");
        
       // alert(PaymentDetails);
        
        var action = component.get("c.InsertBookingReq");
        action.setParams({ BookingReqt : BookingReq,
                          payment : PaymentDetails});
        action.setCallback(this, function(response) {
            var state = response.getState();  
            if (state === "SUCCESS") {
                /*var bookingReqId = response.getReturnValue();
                
                // If payment section was shown, create payment record
                if(component.get('v.showPaymentSection')) {
                    PaymentDetails.Booking_Request__c = bookingReqId;
                    var paymentAction = component.get("c.createAdvancePayment");
                    paymentAction.setParams({ payment: PaymentDetails });
                    paymentAction.setCallback(this, function(response) {
                        component.set('v.IsResponded',true);
                        component.set("v.spinner", false);
                        component.set('v.IsSaveDisabled',false);
                    });
                    $A.enqueueAction(paymentAction);
                } else {
                    component.set('v.IsResponded',true);
                    component.set("v.spinner", false);
                    component.set('v.IsSaveDisabled',false);
                }*/
                
                component.set('v.IsResponded',true);
                // ✅ Move to Confirmation Step
                component.set("v.currentStep", 3);

                component.set("v.spinner", false);
                component.set('v.IsSaveDisabled',false);
            }
        });
        $A.enqueueAction(action);
    },
    
    showToast : function(message,type){
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type":type,
            "message":  message
        });
        toastEvent.fire();
    },
    
    getPicklistValues: function(component) {
        var action = component.get("c.getPicklistValues");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var picklistValues = response.getReturnValue();
                component.set("v.paymentModes", picklistValues.paymentModes);
                component.set("v.banks", picklistValues.banks);
            }
        });
        $A.enqueueAction(action);
    },


})