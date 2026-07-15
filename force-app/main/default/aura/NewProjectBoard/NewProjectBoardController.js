({
    doInit: function(component, event, helper) {
        var action = component.get("c.getProjects");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var db = response.getReturnValue();
                console.log('Projects'+JSON.stringify(db));
                component.set('v.projects', db);
                // Calculate totals after projects are set
                helper.calculateTotals(component);
            } else {
                console.error('Failed to retrieve projects with state: ' + state);
            }
        });
        
        $A.enqueueAction(action);
    },
    loadPlots: function(component, event, helper) {
        var target = event.currentTarget;
        var dataIndex = target.dataset.index;
        var record = target.dataset.id;
        var projectName = target.dataset.name;
        component.set("v.projectName",projectName||'');
        var action = component.get("c.getPlots");
        action.setParams({'Project':  record });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state == "SUCCESS") { 
                var db = response.getReturnValue();
                
                var bookedPlots = [];
                var notReleasedPlots = [];
                var soldPlots = [];
                var handedOverPlots = [];
                var blockedPlots = [];
                var availablePlots = [];
                
                db.forEach(function(plot) {
                    switch(plot.Status__c) {
                        case 'Booked':
                            bookedPlots.push(plot);
                            break;
                        case 'NOT RELEASE FOR SALE':
                            notReleasedPlots.push(plot);
                            break;
                        case 'Sold':
                            soldPlots.push(plot);
                            break;
                        case 'BLOCKED':
                            blockedPlots.push(plot);
                            break;
                        case 'Handed Over':
                            handedOverPlots.push(plot);
                            break;
                        case 'Available':
                            availablePlots.push(plot);
                            break;
                    }
                });
                
                component.set('v.BookedPlots', bookedPlots);
                component.set('v.NotReleasedPlots', notReleasedPlots);
                component.set('v.SoldPlots', soldPlots);
                component.set('v.BlockedPlots', blockedPlots);
                component.set('v.AvailablePlots', availablePlots);
                component.set('v.HandedOverPlots', handedOverPlots);
                component.set('v.showPlots', true);
                component.set('v.showProjects', false);
                component.set('v.Plots',db);
            }
        });
        $A.enqueueAction(action);
    },
    navigatePlots: function(component, event, helper) {
        var plotId = event.currentTarget.dataset.id;
        console.log('plotId'+plotId);
        var navService = component.find("navService");
        var pageReference = {
            type: "standard__recordPage",
            attributes: {
                recordId: plotId,
                objectApiName: "Plot__c",
                actionName: "view"
            }
        };
        navService.navigate(pageReference);
    },
    
    handleCreateBooking:function(component, event, helper){
        var target = event.currentTarget;
        var record = target.dataset.id;
        component.set("v.unitId",record);
        component.set("v.showCreateBooking",true);
    }
    
})