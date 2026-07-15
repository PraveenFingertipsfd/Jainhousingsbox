({
    doInit : function(component, event, helper) {
        let baseUrl = window.location.origin;
        var action = component.get("c.getBookingDetailsform"); // Apex method for Booking
        action.setParams({ bookingId: component.get("v.recordId") });  
        
        action.setCallback(this, function(response){  
            var bookingval = response.getReturnValue();
            component.set("v.bookingRecord", bookingval);
            
            let url;
            if(bookingval && bookingval.Project__c === 'Jains Anushree'){
                url = baseUrl+'/apex/AnushreeBookingForm?Id='+component.get("v.recordId");
            } else {
                url = baseUrl+'/apex/DefaultBookingForm?Id='+component.get("v.recordId");
            }
            
            component.set("v.vfPageUrl", url);
        });
        $A.enqueueAction(action);
    },


    
    close: function(component, event, helper) {
        // Close the modal or quick action
        $A.get("e.force:closeQuickAction").fire();
    }
})