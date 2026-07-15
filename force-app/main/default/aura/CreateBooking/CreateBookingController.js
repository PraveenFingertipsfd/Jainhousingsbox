({
    doInit : function(component, event, helper) {
        //alert(component.get('v.recordId'));
        helper.addApplicantRecord(component, event, helper);        
        var action=component.get("c.getUnitData");
        action.setParams({'recId':  component.get('v.recordId'),
                          'PSAunitId': component.get('v.PSAunitId')});
        action.setCallback(this,function(response){
            var state = response.getState();
            if(state == "SUCCESS" ){ 
                var db = response.getReturnValue();
                if(db.PlotLst == null || db.PlotLst == undefined){
                    helper.showToast('Error','Unit is not Available, you can not create booking','Error!');
                    $A.get("e.force:closeQuickAction").fire();
                }
                else{
                    component.set("v.paymentTypePicklist", db.ModeOfPay);
                    component.set("v.fundingTypePicklist", db.FundingTyp);
                    component.set("v.IsFromPSABooking", db.IsFromPSABooking);
                    var blockPrice = component.get('v.BlockedPrice');
                    if(db.IsFromPSABooking){
                        component.set("v.plot.Final_Price__c", blockPrice);
                    }
                    var bk = component.get('v.plot');
                    if(db.PlotLst !='' && db.PlotLst !=null){
                        var today = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
                        for(var i=0;i<db.PlotLst.length; i++){
                            var qt = db.PlotLst[i];
                            if (qt.Project__c) component.set('v.unitName',qt.Name);
                            if (qt.Block1__r && qt.Block1__r.Name) {
                                component.set('v.towerName', qt.Block1__r.Name);
                            }
                            if (qt.BHK_Type__c) component.set('v.bhktype',qt.BHK_Type__c);
                            if (qt.Floor__c) component.set('v.floorName',qt.Floor__c);
                            if (qt.Id) bk.Plot__c = qt.Id;
                            if (qt.Project__c) bk.Project1__c = qt.Project__c;
                            if (qt.Super_built_up_area__c) bk.Built_up_area__c = qt.Super_built_up_area__c;
                            if (qt.Price_Per_Sq_Ft__c) bk.Price_per_sqft__c = qt.Price_Per_Sq_Ft__c;
                            if (qt.Floor_Rise__c) bk.Floor_Rise_Charges_Rate__c = qt.Floor_Rise__c;
                            if (qt.Premium_Charge__c) bk.Premium_Charge__c = qt.Premium_Charge__c;
                            if (qt.Other_Charges__c) bk.Other_Charges__c = qt.Other_Charges__c;
                            if (qt.Covered_Park_Parking__c) bk.Covered_Park_Parking__c = qt.Covered_Park_Parking__c;
                            if (qt.TAXES__c) bk.TAXES__c = qt.TAXES__c;
                            if (qt.Block1__c) bk.Block__c = qt.Block1__c;
                            if (qt.Block__c) bk.Block1__c = qt.Block__c;
                            if (qt.GST1__c) bk.GST__c = qt.GST1__c;
                            if (qt.Solar_Charges__c) bk.Solar_Charges__c = qt.Solar_Charges__c;
                            if (qt.Project__r && qt.Project__r.Booking_Advance_Amount__c) {
                                bk.Booking_Amount1__c = qt.Project__r.Booking_Advance_Amount__c;
                                component.set('v.bookingAmount', qt.Project__r.Booking_Advance_Amount__c);
                            }
                            bk.Agreement_Percentage__c=10;
                            bk.Date_of_Booking__c	=today;
                            
                            if(!db.IsFromPSABooking){
                                if (qt.Price_Per_Sq_Ft__c) bk.Final_Price__c = qt.Price_Per_Sq_Ft__c;
                            }
                        }
                        /* var navEvt = $A.get("e.force:navigateToSObject");
                        navEvt.setParams({
                            "recordId": db,
                            "slideDevName": "detail"
                        });
                        navEvt.fire();
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "type":'Success',
                            "title": 'Success!',
                            "message":'Booking creating successfully',
                            "duration":10000
                        });
                        toastEvent.fire();*/
                    }
                    component.set('v.plot',bk);
                }
            }
        });
        $A.enqueueAction(action); 
    },
    onDiscountChange : function(component, event, helper){
        var disamt = component.get('v.plot.Discount__c');
        var rate = component.get('v.plot.Price_per_sqft__c');
        var FinalPrc;
        if(disamt != '' && disamt != null && disamt != undefined){
            FinalPrc = rate-disamt;
        }
        else{
            FinalPrc = rate;
        }
        component.set('v.plot.Final_Price__c',FinalPrc);
    },

    closeModel: function(component, event, helper) {
        $A.get('e.force:closeQuickAction').fire();
        $A.get('e.force:refreshView').fire();
    },
    saveBooking : function(component, event, helper) {
        var unt = component.get("v.plot");
        console.log('Test1');
        
        let isAllValid = component.find('field').reduce(function(isValidSoFar, inputCmp){
            inputCmp.showHelpMessageIfInvalid();
            return isValidSoFar && inputCmp.checkValidity();
        }, true);
        console.log('Test2');
        console.log(isAllValid);
        if(isAllValid) {
            var book = component.get("v.plot");
            var action = component.get("c.createBook");
            action.setParams({
                'bk': book,
                'recId': component.get('v.recordId'),
                'applicantList': component.get('v.applicantList')
            });
            console.log('Test3');
            
            action.setCallback(this, function(response) {
                var state = response.getState();
                console.log('state'+state);
                if(state === 'SUCCESS') {
                    console.log('Test4');
                    var db = response.getReturnValue();
                    component.set('v.recordId', db);
                    
                    var navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                        "recordId": db,
                        "slideDevName": "detail"
                    });
                    navEvt.fire();
                    
                    component.set('v.showNext', true);
                    
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": 'Success',
                        "title": 'Success!',
                        "message": 'Booking and Co-Applicants processed successfully.',
                        "duration": 5000
                    });
                    toastEvent.fire();
                } 
                else if(state === 'ERROR') {
                    const errors = response.getError();
                    if (errors && errors[0] && errors[0].message) {
                        const fullErrorMessage = errors[0].message;
                        
                        // Extract relevant error message from full error message
                        const regex = /(?:first error:\s)(.*)/;
                        const match = fullErrorMessage.match(regex);
                        const errorMessage = match ? match[1] : "An unexpected error occurred.";
                        
                        // Show toast with formatted error message
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "type": 'Error',
                            "title": 'Error!',
                            "message": errorMessage,
                            "duration": 5000
                        });
                        toastEvent.fire();
                        
                        console.log('Error: ' + errorMessage);
                    }
                }
            });
            
            $A.enqueueAction(action);
        }
        
    },
    /* gotoReceipt : function (component, event, helper) {
         var action=component.get("c.getPhotosNumber");
          action.setParams({
                'storeId' :component.get('v.bookingRecordId')
            });
        action.setCallback(this,function(response){
            if(response.getState() == "SUCCESS"){
                var acc = response.getReturnValue();
                if(acc >= 2){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type":'Success',
                        "title": 'Success!',
                        "message":'Booking Files Submitted Successfully',
                        "duration":5000
                    });
                    toastEvent.fire();
                    //var navEvt = $A.get("e.force:navigateToSObject");
                    //navEvt.setParams({
                       // "recordId": component.get('v.bookingRecordId'),
                        //"slideDevName": "detail"
                    //});
                    //navEvt.fire(); 
                    component.set('v.showNext',false);
                    component.set('v.goToreceipt',true);
                }
                else{
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type":'Error',
                        "title": 'Error!',
                        "message":'Please Upload Booking Form and Scanned Quotation',
                        "duration":5000
                    });
                    toastEvent.fire();
                }
               
            }
        });
        $A.enqueueAction(action);		
    }*/
    addRow: function(component, event, helper) { 
        helper.addApplicantRecord(component, event, helper);
    },
    removeRow : function(component, event, helper) {
        var selectedItem = event.currentTarget;
        var index = selectedItem.dataset.record;
        var aitems= component.get('v.applicantList');
        aitems.splice(index, 3);
        component.set("v.applicantList", aitems);
        
    },
    handleSelectedProjectIdChange: function(component, event, helper){
        var newSelectedId = event.getParam("value");
        console.log('Value changed to: ' + newSelectedId);
        var plot = component.get('v.plot');
        plot.Associated_Project__c = newSelectedId;
        component.set('v.plot',plot);
    },
    handleSelectedUnitIdChange: function(component, event, helper){
        var newSelectedId = event.getParam("value");
        console.log('unit Value changed to: ' + newSelectedId);
        var plot = component.get('v.plot');
        plot.Associated_Unit__c = newSelectedId;
        component.set('v.plot',plot);
    },
    handleSelectExisting: function(component, event, helper) {
        var selectedValue = component.get("v.plot.Existing_customer__c");
        var plot = component.get("v.plot");
        if (selectedValue !== "Yes") {
            plot.Associated_Unit__c = null;
            plot.Associated_Project__c = null;
            component.set("v.plot", plot);
        }
    }
})