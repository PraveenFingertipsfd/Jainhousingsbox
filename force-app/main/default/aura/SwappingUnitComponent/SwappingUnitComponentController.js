({
    doInit: function(component, event, helper) {
        var action = component.get("c.getBooking");  
        action.setParams({'recId': component.get('v.recordId') });
        
        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") { 
                var booking = response.getReturnValue();
                if (booking.Plot__c) {
                    component.set('v.currentUnit', booking.Plot__r.Name);
                } else {
                    helper.showErrorToast(component,'Selected booking has no Unit selected');
                    helper.closeAndRefresh();
                    return;
                }
                
                component.set('v.Booking', booking);
                
                if (booking.Project1__c) {
                    var unitQuery = `Project__c = '${booking.Project1__c}' AND Status__c = 'Available'`;
                    component.set('v.unitQuery', unitQuery);
                } else {
                    helper.showErrorToast(component,'Selected booking has no Project selected.');
                    helper.closeAndRefresh();
                    return;
                }
            } else {
                console.error('Failed to retrieve booking:', response.getError());
            }
        }); 
        
        $A.enqueueAction(action);
    },
    
    handleSelectUnit: function(component, event, helper) {
        
        var newSelectedUnitId = event.getParam("value");
        var action=component.get("c.getUnit");  
        action.setParams({'unitId': newSelectedUnitId });
        action.setCallback(this,function(response){
            if(response.getState()=="SUCCESS"){ 
                console.log('here');
                var unit = response.getReturnValue();
                var unitDetails = component.get('v.Booking');
                unitDetails.Swap_Tower__c = unit.Tower__c;
                unitDetails.Swap_Block__c = unit.Block__c;
                unitDetails.Swap_Floor__c = unit.Floor__c;
                unitDetails.Swap_Price_Per_Sq_Ft__c = unit.Price_Per_Sq_Ft__c ;
                unitDetails.Swap_Floor_Rise__c = unit.Floor_Rise__c;
                unitDetails.Swap_Premium_charges__c = unit.Premium_Charge__c;
                unitDetails.Swap_Other_Charges__c = unit.Other_Charges__c;
                unitDetails.Swap_Covered_Park_Parking__c = unit.Covered_Park_Parking__c;
                unitDetails.Swap_GST__c = unit.GST1__c;
                unitDetails.Swap_Unit__c = unit.Id;
                component.set('v.Booking',unitDetails);
            }else{
                console.log('error');
            }
        }); 
        $A.enqueueAction(action);
    },
    /* doInit: function(component, event, helper) {
        helper.addProductRecord(component, event,helper);
        var action=component.get("c.getPlots");  
        action.setParams({'recId':  component.get('v.recordId') });
        action.setCallback(this,function(response){
            if(response.getState()=="SUCCESS"){ 
                var plots = response.getReturnValue();
                console.log('plots:'+plots);
                component.set("v.plots",plots);
                 component.set("v.showNextCmp", false);
                
            }
        });
        $A.enqueueAction(action);
               
         var action1 = component.get("c.getPaymentTypePicklistValues");
    action1.setCallback(this, function(response) {
        if (response.getState() === "SUCCESS") {
            var paymentTypePicklist = response.getReturnValue();
            component.set("v.paymentTypePicklist", paymentTypePicklist);
        }
    });
    $A.enqueueAction(action1);
       
    },
    handleInputChange: function(component, event, helper) {
        
        helper.handleCalculations(component, event, helper);
        
    },*/
    searchText1 : function(component, event, helper) {
        var plot= component.get('v.plots');
        component.set('v.showCostSheet',false);
        var searchText1= component.get('v.searchText1');
        console.log(searchText1.length)
        if(searchText1.length < 1){
            console.log(searchText1)
        }
        var matchplots=[];
        if(searchText1 !=''){
            for(var i=0;i<plot.length; i++){ 
                // console.log(plot[i].Name)
                if(plot[i].Name.toLowerCase().indexOf(searchText1.toLowerCase())  != -1  ){
                    
                    if(matchplots.length <50){
                        matchplots.push( plot[i] );
                        
                    }else{
                        break;
                    }
                } 
            } 
            if(matchplots.length >0){
                component.set('v.matchplots',matchplots);
            }
        }else{
            component.set('v.matchplots',[]);
        }
    },
    
    update1: function(component, event, helper) {
        component.set('v.Showfields', false);
        var edi =  event.currentTarget.dataset.id;
        console.log('edi'+edi);
        var plt= component.get('v.matchplots');
        console.log('plt '+JSON.stringify(plt));
        var selPlot= component.get('v.plots');
        console.log('selPlot '+JSON.stringify(selPlot));
        var oppPlot = component.get('v.oppPlot');
        console.log('oppPlot '+JSON.stringify(oppPlot));
        
        console.log('opp '+JSON.stringify(opp));
        
        for(var i=0;i<plt.length; i++){  
            
            if(plt[i].Id ===  edi ){
                if(plt[i].Name!=null)
                {
                    
                    component.set('v.Showfields', true);
                    
                    component.set('v.searchText1', plt[i].Name);
                    component.set('v.projectName', plt[i].Project__r.Project__c);
                    component.set('v.flatNumber', plt[i].Name);
                }
                
                
                
                selPlot = plt[i];
                
                //oppPlot.Lead__c=component.get('v.recordId');
                //oppPlot.Swap_Unit__c = plt[i].Id;
                oppPlot.Project__c = plt[i].Project__c;
                oppPlot.Price_Per_Sq_Ft__c = plt[i].Price_Per_Sq_Ft__c;
                oppPlot.Floor_Rise__c = plt[i].Floor_Rise__c;
                oppPlot.Premium_Charge__c = plt[i].Premium_Charge__c;
                
                oppPlot.Covered_Park_Parking__c = plt[i].Covered_Park_Parking__c;
                oppPlot.Basic_Price1__c = plt[i].Basic_Price1__c;
                
                //oppPlot.Corpus_Fundswap__c = plt[i].Corpus_Fund__c;
                //oppPlot.GSTswap__c = plt[i].GST1__c;
                //oppPlot.Water_Electricity_ChargesSwap__c = plt[i].Water_Electricity_Charges__c;
                //oppPlot.Legal_Documentation_Chargesswap__c = plt[i].Legal_Documentation_Charges__c;
                //oppPlot.Maintenance_Chargeswap__c = plt[i].Maintenance_Charge__c;
                //oppPlot.Generator_STPSwap__c = plt[i].Generator_STP__c;
                //oppPlot.PLC_ChargesSwap__c = plt[i].PLC_Charges__c;
                //oppPlot.Sale_Area__c = plt[i].Sale_Area__c;
                //oppPlot.Payment_Type__c = plt[i].Payment_Type__c;
                //oppPlot.BHK_Type__c = plt[i].BHK_Type__c;
                oppPlot.Unit_Facing_Directionswap__c = plt[i].Unit_Facing_Direction__c;
                oppPlot.Rate_per_sqftswap__c = plt[i].Rate_per_sqft__c;
                //oppPlot.Type_Duplex__c = plt[i].Type_Duplex__c;
                //oppPlot.Plot_Type__c = plt[i].Plot_Type__c;
                //oppPlot.Carpet_Area__c = plt[i].Carpet_Area__c;
                //oppPlot.Built_up_area__c = plt[i].Built_up_area__c;
                //oppPlot.Undivided_Share_of_Land__c = plt[i].Undivided_Share_of_Land__c;
                oppPlot.Total_Cost_Ex_Leg_MainSwap__c = plt[i].Total_Cost_Ex_Leg_Main__c;
                //oppPlot.Block__c = plt[i].Block__c;
                //oppPlot.Corner__c = plt[i].Corner__c;
                //oppPlot.Premium_Location_Charge__c = plt[i].Premium_Location_Charge__c;
                
                
                
                
                
                
                
                
                
                var today = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
                component.set('v.today', today);
                component.set('v.RecTypeId',plt[i].Name);
                helper.handleCalculations(component, event, helper);    
                break;
            } 
        } 
        component.set('v.showCostSheet',true);
        component.set('v.plots', selPlot);
        //alert('Update 3');
        component.set('v.oppPlot',oppPlot);
        component.set('v.matchplots',[]);
    },
    
    
    navigateToPaymentSchedule: function (component, event, helper) {
        //     alert('paymentType 1 :'+  component.get("v.oppPlot.Payment_Type__c"));
        //alert('calling the payment');
        //alert(component.get("v.GrandTotal"));
        var payType = component.get("v.oppPlot.Payment_Type__c");
        if(payType != 'None'){
            helper.getFilteredLead(component,event,helper);
            helper.handleCalculations(component,event,helper);
            component.set("v.showNextCmp", true);
        }
        else{
            helper.showToast('Error','Mandate Error','Please Select The Payment Type');
        }
        
        
        
    },
    doSave: function(component,event,helper) {
        //component.set('v.spinner', true);  // Show spinner
        var booking = component.get("v.Booking");
        var ExtraCarparkingSlots = component.get("v.Swap_Extra_Covered_Parking_Slots") || 0;
        var ExtraCarparkingCharges = component.get("v.Swap_Extra_Covered_Parking_Charges") || 0;
        var solarCharges = component.get("v.Swap_Solar_Charges") || 0;
        
        var swapBooking = {
            'Id': booking.Id,
            'Swap_Floor__c': booking.Swap_Floor__c,
            'Swap_Floor_Rise__c': booking.Swap_Floor_Rise__c,
            'Swap_Funding_Type__c': booking.Swap_Funding_Type__c,
            'Swap_GST__c': booking.Swap_GST__c,
            'Swap_Other_Charges__c': booking.Swap_Other_Charges__c,
            'Swap_Price_Per_Sq_Ft__c': booking.Swap_Price_Per_Sq_Ft__c,
            'Swap_Super_Built_Up_Area__c': booking.Swap_Super_Built_Up_Area__c,
            'Swap_TAXES__c': booking.Swap_TAXES__c,
            'Swap_Block__c': booking.Swap_Block__c,
            'Swap_Covered_Park_Parking__c': booking.Swap_Covered_Park_Parking__c,
            'Swap_Mode_of_Payment__c': booking.Swap_Mode_of_Payment__c,
            'Swap_Tower__c': booking.Swap_Tower__c,
            'Swap_Unit__c': booking.Swap_Unit__c,
            'Swap_Unit_Status__c': booking.Swap_Unit_Status__c,
            'Swap_Solar_Charges__c': solarCharges,
            'Swap_Extra_Covered_Parking_Slots__c': ExtraCarparkingSlots,
            'Swap_Extra_Covered_Parking_Charges__c': ExtraCarparkingCharges
        };
        // Set the swapBooking attribute
        component.set("v.swapBooking", swapBooking);
        
        if (helper.validate(component, event)) {
            helper.save(component,event,helper);
        }else {
            component.set('v.spinner', false); 
            helper.showToast('Error','Error','Please Select a unit');
        }
        
    },
    
    handleChange: function (component, event, helper) {
        
        var selectedOptionValue = component.find("select").get('v.value');  
        component.set('v.paymentType',selectedOptionValue);
        //alert(selectedOptionValue);
        if(selectedOptionValue=='None')
        {
            helper.showToast('Error','Mandate Error','Please Select The Payment Type');
            $A.get("e.force:closeQuickAction").fire();
        } 
        
        var paymentType = component.find("select").get("v.value");
        if (paymentType === "Custom") {
            component.set("v.showNextCmp", false);
        }
        else if (paymentType === "Standard") {
            component.set("v.showNextCmp", false);
        }
    },
    closeModel: function(component, event, helper) {
        
        $A.get("e.force:closeQuickAction").fire();
        /*
         var homeEvt = $A.get("e.force:navigateToObjectHome");
        homeEvt.setParams({
            "scope": "Booking__c"
        });
        homeEvt.fire();*/
        $A.get('e.force:closeQuickAction').fire();
        $A.get('e.force:refreshView').fire();
        
        
    },
    
    handlePrevious: function (component, event, helper) {
        component.set("v.showNextCmp", false);
        component.set('v.paymentSchedules',[]);
    },
    addRow: function(component, event, helper) {
        //alert('hello ocean');
        helper.addProductRecord(component, event,helper);
    },
    
    removeRow: function(component, event, helper) {
        //alert('hello remove');
        //var quoteList = component.get("v.QuoteItemList");
        var selectedItem = event.currentTarget;
        var index = selectedItem.dataset.record;
        console.log(index);
        var oitems= component.get('v.CustompaymentSchedules');
        console.log(oitems);
        console.log(oitems[index].Id);
        if(oitems[index].Id !='undefined' && oitems[index].Id !='' && oitems[index].Id !=undefined){
            console.log('in');
            
            if( oitems[index].Payment_percent__c !='' && oitems[index].Payment_percent__c !=undefined){
                var grandtotal = (component.get('v.GrandTotal')-oitems[index].Amount__c);
                var recivedamount = (component.get('v.RecivedAmountTotal')-oitems[index].Received_Amount__c);
                var perct = (component.get('v.totalPercent')-oitems[index].Payment_percent__c);
                component.set('v.GrandTotal',grandtotal.toFixed(2));
                component.set('v.RecivedAmountTotal',recivedamount.toFixed(2));
                component.set('v.totalPercent',perct);
            }
            oitems.splice(index, 1);
            for (var i = 0; i < oitems.length; i++) {
                oitems[i].S_No__c = i+1;
            }        
            component.set("v.CustompaymentSchedules", oitems);
            
            if(oitems.length < 1){
                helper.addProductRecord(component, event,helper);
            }
            
        }else{
            console.log(oitems[index].Payment_percent__c);
            if( oitems[index].Payment_percent__c !='' && oitems[index].Payment_percent__c !=undefined){
                var grandtotal = (component.get('v.GrandTotal')-oitems[index].Amount__c);
                var recivedamount = (component.get('v.RecivedAmountTotal')-oitems[index].Received_Amount__c);
                console.log(grandtotal);
                var perct = (component.get('v.totalPercent')-oitems[index].Payment_percent__c);
                console.log(perct);
                component.set('v.GrandTotal',grandtotal.toFixed(2));
                component.set('v.RecivedAmountTotal',recivedamount.toFixed(2));
                component.set('v.totalPercent',perct);
                console.log('d');
            }
            oitems.splice(index, 1);
            for (var i = 0; i < oitems.length; i++) {
                oitems[i].S_No__c = i+1;
            }  
            console.log('s');
            component.set("v.CustompaymentSchedules", oitems);
            
            if(oitems.length < 1){
                helper.addProductRecord(component, event);
            } 
            
        }
    },
    fillDueDate : function(component, event, helper) {
        //alert('changedDueDate');
        var paymentSchedules = component.get("v.paymentSchedules");
        //alert('paymentSchedules');
        var changedDueDate = event.getSource().get("v.value");
        //alert(changedDueDate);
        // Iterate through the paymentSchedules and update due dates for completed items
        paymentSchedules.forEach(function(item) {
            if (item.status__c === 'Completed') {
                item.Payment_Due_Date__c = changedDueDate;
            }
        });
        
        // Update the attribute to reflect the changes
        component.set("v.paymentSchedules", paymentSchedules);
    },
    
})