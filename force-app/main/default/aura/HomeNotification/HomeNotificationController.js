({
    doInit : function(component, event, helper) {
        helper.refreshAllLists(component);
    },

    // Pagination handlers
    FollwuppreviousPage: function(c, e, h){ 
        c.set("v.FollwupcurrentPage", c.get("v.FollwupcurrentPage") - 1); 
        h.getBookingWelcomeCallDetails(c); 
    },
    FollwupnextPage: function(c, e, h){ 
        c.set("v.FollwupcurrentPage", c.get("v.FollwupcurrentPage") + 1); 
        h.getBookingWelcomeCallDetails(c); 
    },

    RegPreviousPage: function(c, e, h){ 
        c.set("v.RegCurrentPage", c.get("v.RegCurrentPage") - 1); 
        h.getTodays90PercentBookings(c); 
    },
    RegNextPage: function(c, e, h){ 
        c.set("v.RegCurrentPage", c.get("v.RegCurrentPage") + 1); 
        h.getTodays90PercentBookings(c); 
    },

    PendingWelcomePrevious: function(c, e, h){ 
        c.set("v.PendingWelcomeCurrentPage", c.get("v.PendingWelcomeCurrentPage") - 1); 
        h.getPendingBookingWelcomeCallDetails(c); 
    },
    PendingWelcomeNext: function(c, e, h){ 
        c.set("v.PendingWelcomeCurrentPage", c.get("v.PendingWelcomeCurrentPage") + 1); 
        h.getPendingBookingWelcomeCallDetails(c); 
    },

    PendingRegPrevious: function(c, e, h){ 
        c.set("v.PendingRegCurrentPage", c.get("v.PendingRegCurrentPage") - 1); 
        h.getPending90PercentBookings(c); 
    },
    PendingRegNext: function(c, e, h){ 
        c.set("v.PendingRegCurrentPage", c.get("v.PendingRegCurrentPage") + 1); 
        h.getPending90PercentBookings(c); 
    },

    // Redirect to record detail
    navigateToRecord: function(component, event){
        var recordId = event.currentTarget.dataset.id;
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({ "recordId": recordId });
        navEvt.fire();
    }
})