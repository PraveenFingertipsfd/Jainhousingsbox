({
    refreshAllLists1: function(component) {
        this.getBookingWelcomeCallDetails(component);
        this.getTodays90PercentBookings(component);
        this.getPendingBookingWelcomeCallDetails(component);
        this.getPending90PercentBookings(component);
    },
    
    refreshAllLists: function(component) {
        this.getBookingWelcomeCallDetails(component);
        //this.getTodays90PercentBookings(component);
        this.getPendingBookingWelcomeCallDetails(component);
        //this.getPending90PercentBookings(component);
        this.getTodaysJointInspections(component);
        this.getPendingJointInspections(component);
    },

/* 07-08
    getBookingWelcomeCallDetails: function(c) {
        var a = c.get("c.getWelcomeCallInformation");
        a.setParams({ 
            pageNumber: c.get("v.FollwupcurrentPage"), 
            pageSize: c.get("v.FollwuppageSize") 
        });
        a.setCallback(this, r => {
            if (r.getState() === "SUCCESS") {
                let fullList = r.getReturnValue();
                
                // Format dates (existing logic)
                fullList.forEach(item => {
                    if (item.Welcome_Mail_Sent_Time__c) {
                        item.Welcome_Mail_Sent_Time__c = new Date(item.Welcome_Mail_Sent_Time__c).toLocaleString('en-GB', {
                            day: 'numeric', month: 'short', year: 'numeric',
                            hour: 'numeric', minute: 'numeric', hour12: true
                        });
                    }
                });

                // Store the FULL list for pagination
                c.set("v.fullFollowUpDetails", fullList);
                
                // Slice the list into pages of 3 items
                var pageSize = 3; // 3 items per row = 1 page
                var startIdx = (c.get("v.FollwupcurrentPage") - 1) * pageSize;
                var paginatedList = fullList.slice(startIdx, startIdx + pageSize);
                
                c.set("v.followUpDetails", paginatedList);
                
                // Update pagination buttons
                c.set("v.isFollwupPreviousDisabled", c.get("v.FollwupcurrentPage") === 1);
                c.set("v.isFollwupNextDisabled", startIdx + pageSize >= fullList.length);
            }
        });
        $A.enqueueAction(a);
    },
*/

    /*
    getBookingWelcomeCallDetails: function(c) {
        var action = c.get("c.getWelcomeCallInformation");
        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                var fullList = response.getReturnValue();
                
                // Format dates (existing logic)
                fullList.forEach(function(item) {
                    if (item.Welcome_Mail_Sent_Time__c) {
                        item.Welcome_Mail_Sent_Time__c = new Date(item.Welcome_Mail_Sent_Time__c).toLocaleString('en-GB', {
                            day: 'numeric', month: 'short', year: 'numeric',
                            hour: 'numeric', minute: 'numeric', hour12: true
                        });
                    }
                });
                
                // Store full list for pagination
                c.set("v.fullFollowUpDetails", fullList);
                
                // Paginate: 3 items per page
                var itemsPerPage = 3;
                var currentPage = c.get("v.FollwupcurrentPage");
                var startIdx = (currentPage - 1) * itemsPerPage;
                var paginatedList = fullList.slice(startIdx, startIdx + itemsPerPage);
                
                c.set("v.followUpDetails", paginatedList);
                
                // Update button states
                c.set("v.isFollwupPreviousDisabled", currentPage === 1);
                c.set("v.isFollwupNextDisabled", startIdx + itemsPerPage >= fullList.length);
                
                // Update tab label count
                c.set("v.WelcomeCallChecklistCount", fullList.length);
            }
        });
        $A.enqueueAction(action);
    }, 	
   */
    getBookingWelcomeCallDetails1: function(component) {
        var action = component.get("c.getWelcomeCallInformation");
        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                var fullList = response.getReturnValue();
                
                // Format dates (your existing code)
                fullList.forEach(function(item) {
                    if (item.Welcome_Mail_Sent_Time__c) {
                        item.Welcome_Mail_Sent_Time__c = new Date(item.Welcome_Mail_Sent_Time__c).toLocaleString('en-GB', {
                            day: 'numeric', month: 'short', year: 'numeric',
                            hour: 'numeric', minute: 'numeric', hour12: true
                        });
                    }
                });
                
                // Set both the display list and total count
                component.set("v.followUpDetails", fullList);
                component.set("v.totalWelcomeCallCount", fullList.length); // Set the total count
            }
        });
        $A.enqueueAction(action);
    },
    getPendingBookingWelcomeCallDetails1: function(c){
    var a = c.get("c.getPendingFollowUpInformation");
    a.setCallback(this, r => {
        if(r.getState() === "SUCCESS"){
            let list = r.getReturnValue();

            list.forEach(item => {
                if(item.Welcome_Mail_Sent_Time__c){
                    item.Welcome_Mail_Sent_Time__c = new Date(item.Welcome_Mail_Sent_Time__c).toLocaleString('en-GB', {
                        day: 'numeric',
                        month: 'short',
                        year: 'numeric',
                        hour: 'numeric',
                        minute: 'numeric',
                        hour12: true
                    });
                }
            });

            c.set("v.pendingFollowUpDetails", list);
        }
    });
    $A.enqueueAction(a);
	},
        
        getBookingWelcomeCallDetails: function(component) {
    var action = component.get("c.getWelcomeCallInformation");
    action.setCallback(this, function(response) {
        if (response.getState() === "SUCCESS") {
            var fullList = response.getReturnValue();

            fullList.forEach(function(item) {
                if (item.Welcome_Mail_Sent_Time__c) {
                    item.Welcome_Mail_Sent_Time__c = new Date(item.Welcome_Mail_Sent_Time__c).toLocaleString('en-GB', {
                        day: 'numeric', month: 'short', year: 'numeric',
                        hour: 'numeric', minute: 'numeric', hour12: true
                    });
                }
            });

            component.set("v.followUpDetails", fullList);
            component.set("v.totalWelcomeCallCount", fullList.length);
  
            // 🔹 Update agenda count
            this.updateAgendaCount(component);
        }
    }.bind(this));
    $A.enqueueAction(action);
},

    getPendingBookingWelcomeCallDetails: function(c){
    var a = c.get("c.getPendingFollowUpInformation");
    a.setCallback(this, r => {
        if(r.getState() === "SUCCESS"){
            let list = r.getReturnValue();

            list.forEach(item => {
                if(item.Welcome_Mail_Sent_Time__c){
                    item.Welcome_Mail_Sent_Time__c = new Date(item.Welcome_Mail_Sent_Time__c).toLocaleString('en-GB', {
                        day: 'numeric', month: 'short', year: 'numeric',
                        hour: 'numeric', minute: 'numeric', hour12: true
                    });
                }
            });

            c.set("v.pendingFollowUpDetails", list);

            // 🔹 Update pending count
            this.updatePendingCount(c);
        }
    });
    $A.enqueueAction(a);
},



    
    
    getTodays90PercentBookings: function(c){
        var a = c.get("c.getNinetyPercentCollectedBookings");
        a.setParams({ pageNumber: c.get("v.RegCurrentPage"), pageSize: c.get("v.RegPageSize") });
        a.setCallback(this, r=>{
            if(r.getState()==="SUCCESS"){
                let list = r.getReturnValue();
                c.set("v.todays90List", list);
                c.set("v.isRegPrevDisabled", c.get("v.RegCurrentPage")===1);
                c.set("v.isRegNextDisabled", list.length < c.get("v.RegPageSize"));
            }
        });
        $A.enqueueAction(a);
    },
    getPending90PercentBookings: function(c){
        var a = c.get("c.getPendingNinetyPercentBookings");
        a.setParams({ pageNumber: c.get("v.PendingRegCurrentPage"), pageSize: c.get("v.PendingRegPageSize") });
        a.setCallback(this, r=>{
            if(r.getState()==="SUCCESS"){
                let list = r.getReturnValue();
                c.set("v.pending90List", list);
                c.set("v.isPendingRegPrevDisabled", c.get("v.PendingRegCurrentPage")===1);
                c.set("v.isPendingRegNextDisabled", list.length < c.get("v.PendingRegPageSize"));
            }
        });
        $A.enqueueAction(a);
    },

    /* 08-08
    getPendingBookingWelcomeCallDetails: function(c){
        var a = c.get("c.getPendingFollowUpInformation");
        a.setParams({ pageNumber: c.get("v.PendingWelcomeCurrentPage"), pageSize: c.get("v.PendingWelcomePageSize") });
        a.setCallback(this, r=>{
            if(r.getState()==="SUCCESS"){
                let list = r.getReturnValue();

                list.forEach(item=>{
                    if(item.Welcome_Mail_Sent_Time__c){
                        item.Welcome_Mail_Sent_Time__c = new Date(item.Welcome_Mail_Sent_Time__c).toLocaleString('en-GB', {
                            day: 'numeric',
                            month: 'short',
                            year: 'numeric',
                            hour: 'numeric',
                            minute: 'numeric',
                            hour12: true
                        });
                    }
                });

                c.set("v.pendingFollowUpDetails", list);
                c.set("v.isPendingWelcomePrevDisabled", c.get("v.PendingWelcomeCurrentPage")===1);
                c.set("v.isPendingWelcomeNextDisabled", list.length < c.get("v.PendingWelcomePageSize"));
            }
        });
        $A.enqueueAction(a);
    },
    */
    
    getTodaysJointInspections1: function(c) {
            var a = c.get("c.getTodaysJointInspections");
            a.setCallback(this, r => {
                if(r.getState() === "SUCCESS"){
                let list = r.getReturnValue();
                c.set("v.todaysJointInspectionList", list);
                c.set("v.todaysJointInspectionCount", list.length);
            }
                          });
            $A.enqueueAction(a);
        }, 
    getPendingJointInspections1: function(c) {
                var a = c.get("c.getPendingJointInspections");
                a.setCallback(this, r => {
                    if(r.getState() === "SUCCESS"){
                    let list = r.getReturnValue();
                    c.set("v.pendingJointInspectionList", list);
                    c.set("v.pendingJointInspectionCount", list.length);
                }
                              });
                $A.enqueueAction(a);
            },
                
getTodaysJointInspections: function(c) {
    var a = c.get("c.getTodaysJointInspections");
    a.setCallback(this, r => {
        if(r.getState() === "SUCCESS"){
            let list = r.getReturnValue();
            c.set("v.todaysJointInspectionList", list);
            c.set("v.todaysJointInspectionCount", list.length);

            // 🔹 Update agenda count
            this.updateAgendaCount(c);
        }
    });
    $A.enqueueAction(a);
},

getPendingJointInspections: function(c) {
    var a = c.get("c.getPendingJointInspections");
    a.setCallback(this, r => {
        if(r.getState() === "SUCCESS"){
            let list = r.getReturnValue();
            c.set("v.pendingJointInspectionList", list);
            c.set("v.pendingJointInspectionCount", list.length);
			
            // 🔹 Update pending count
            this.updatePendingCount(c);
        }
    });
    $A.enqueueAction(a);
},


    updateAgendaCount: function(c) {
        let welcome = c.get("v.totalWelcomeCallCount") || 0;
    let joint = c.get("v.todaysJointInspectionCount") || 0;
        let testingCount= 'Testing update '+ (welcome + joint);  
    c.set("v.agendaCount", (welcome + joint));
    
            var tabLabel = c.find("Agenda").get("v.label");
     
            var miss = "Today\'s Agenda ("+(welcome + joint)+")";
            tabLabel[0].set("v.value", miss);
        
     
},

updatePendingCount: function(c) {
   
    let pendingWelcome = c.get("v.pendingFollowUpDetails") ? c.get("v.pendingFollowUpDetails").length : 0;
    let pendingJoint = c.get("v.pendingJointInspectionCount") || 0;
   
     var tabLabel = c.find("Pending").get("v.label");
            var miss = "Pending Items ("+(pendingWelcome + pendingJoint)+")";
            tabLabel[0].set("v.value", miss);
    
    
},

      
})