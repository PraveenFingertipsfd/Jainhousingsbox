({
    doInit : function(component, event, helper) {
        var recdId = component.get('v.recordId');
        var action = component.get("c.fetchRecords");
        action.setParams({'BookingReqId' : recdId});
        action.setCallback(this,function(response){
            if(response.getState() == "SUCCESS"){
                var retValue = response.getReturnValue();
                component.set("v.AllAvbUnits",retValue.PlotLst); 
                component.set("v.BlockedPrice",retValue.BlockedPrice);
            }
        });
        $A.enqueueAction(action); 
    },

    UnitSearchHandler: function(component, event,helper){
        var dataSrch = component.get('v.AllAvbUnits');
        var matchingCus = [];
        
        var searchText = component.get('v.textSearch');
        if (searchText == '' || searchText == null) {
            component.set('v.SearchedUnits',matchingCus);
        }
        else{
            for (var i = 0; i < dataSrch.length; i++) {
                if (dataSrch[i].Name.toLowerCase().indexOf(searchText.toLowerCase()) != -1) {
                    if(matchingCus.length <50){
                        matchingCus.push({
                            Id: dataSrch[i].Id, 
                            Name: dataSrch[i].Name,                            
                            Icon: 'standard:default',
                            size:'small'
                        });
                    }else{
                        break;
                    }
                }
            }
            component.set('v.SearchedUnits',matchingCus);
        }
    },
    
    UnitUpdateHandler: function(component, event,helper){
        component.set('v.textSearch',event.currentTarget.dataset.name);
        component.set('v.selectedUnitId',event.currentTarget.dataset.id);
        component.set('v.SearchedUnits',[]);
    },
    
    doCancel : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },

    handleClose : function(component, event, helper) {
        component.set("v.isOpen", false);
        
        var modal = component.find("overlayLibModal");
        if (modal) modal.close();
        
        $A.get("e.force:closeQuickAction").fire();
    },
    
    dosave : function(component, event, helper) {
        component.set("v.IsButtondisable", true);
        var unitId = component.get('v.selectedUnitId');
        var recId = component.get("v.recordId");
        if(unitId == ''){
            component.set("v.IsButtondisable", false);
            helper.showToast('Please Select Preferred Unit','Error','Error!!');
        }
        else{
            component.set("v.showModal",false);
            component.set("v.showNextComponent", true);
            /*$A.createComponent(
                "c:CreateBooking",
                {
                    recordId: recId
                },
                function(newCmp, status, errorMessage) {
                    console.log("Component creation status:", status);
                    
                    if (status === "SUCCESS") {
                        var body = component.get("v.body") || [];
                        body.push(newCmp);
                        component.set("v.body", body);
                        console.log("Component created successfully");
                    } else if (status === "INCOMPLETE") {
                        console.warn("Server call incomplete. Maybe the user is offline or Lightning is disconnected.");
                    } else if (status === "ERROR") {
                        console.error("Error creating component:", errorMessage);
                        alert("Component creation failed: " + errorMessage); // temp alert for visibility
                    }
                }
            );*/
        }
    },
    
    clearselectedUnit :function(component, event, helper) {
        component.set('v.selectedUnitId','');
        component.set('v.textSearch','');
    }
})