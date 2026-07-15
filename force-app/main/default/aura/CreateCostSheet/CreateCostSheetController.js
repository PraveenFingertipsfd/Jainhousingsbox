({
    doInit: function(component, event, helper) {
        helper.addProductRecord(component, event,helper);
        var action=component.get("c.getBlock");  
        action.setParams({'recId':  component.get('v.recordId') });
        action.setCallback(this,function(response){
            if(response.getState()=="SUCCESS"){ 
                var blocks = response.getReturnValue();
                component.set("v.blocks",blocks);
                component.set("v.showBlockLookup", true);
                
            }
        });
        $A.enqueueAction(action);
        
        /*   var actionT=component.get("c.quotationqquery");  
        actionT.setParams({'Leadid':  component.get('v.recordId') });
        actionT.setCallback(this,function(response){
            if(response.getState()=="SUCCESS"){ 
                var plots = response.getReturnValue();
                component.set("v.ismultiplequotes", plots);
                console.log('plots:'+plots);
              
                
            }
        });
        $A.enqueueAction(actionT);
        */
        
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
    },
    searchText1 : function(component, event, helper) {
        //alert('Enetr 1');
        var plot= component.get('v.plots');
        //alert(plot);
        component.set('v.+',false);
        var searchText1= component.get('v.searchText1');
        console.log(searchText1.length)
        if(searchText1.length < 1){
            console.log(searchText1)
        }
        var matchplots=[];
        if(searchText1 !=''){
            for(var i=0;i<plot.length; i++){ 
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
    searchText2 : function(component, event, helper){
        
        var block= component.get('v.blocks');
        
        component.set('v.showCostSheet',false);
        var searchText1= component.get('v.searchText2');
        //alert(searchText1+ '--'+ JSON.stringify(block))
        if(searchText1.length < 1){
            console.log(searchText1)
        }
        var matchblocks=[];
        if(searchText1 !=''){
            for(var i=0;i<block.length; i++){ 
                if(block[i].Name.toLowerCase().indexOf(searchText1.toLowerCase())  != -1  ){
                    if(matchblocks.length <70){
                        matchblocks.push( block[i] );
                    }else{
                        break;
                    }
                } 
            } 
            if(matchblocks.length >0){
                component.set('v.matchblocks',matchblocks);
            }
        }else{
             component.set('v.showUnits',false);
            component.set('v.matchblocks',[]);
        }
    },
    update2 : function(component, event, helper){
        var edi =  event.currentTarget.dataset.id;
        var plt= component.get('v.matchblocks');
        var selPlot= component.get('v.blocks');
        var oppPlot = component.get('v.oppPlot');
        
        // var selectedValue = component.find("projectSelect").get("v.value");
        //  alert(selectedValue)
        for(var i=0;i<plt.length; i++){  
            if(plt[i].Id ===  edi ){
                if(plt[i].Name!=null)
                {
                    component.set('v.searchText2', plt[i].Name);
                    var block = component.get('v.searchText2');
                    var action=component.get("c.getPlots");  
                    action.setParams({'block':  block});
                    action.setCallback(this,function(response){
                        if(response.getState()=="SUCCESS"){ 
                            
                            var result = response.getReturnValue();
                            component.set("v.plots",result);
                            component.set("v.showNextCmp", false);
                            component.set('v.showUnits',true);
                            component.set('v.blockId',edi);
                            component.set('v.matchblocks',[]);
                        }
                    });
                    $A.enqueueAction(action);
                }
                oppPlot.Block_Lookup__c = plt[i].Id;
                selPlot = plt[i];
               // component.set('v.blocks', selPlot);
                component.set('v.oppPlot',oppPlot);
            }
        }
        
    },
    
    update1: function(component, event, helper) {
        component.set('v.Showfields', false);
        var edi =  event.currentTarget.dataset.id;
        var plt= component.get('v.matchplots');
        var selPlot= component.get('v.plots');
        var selPlot= component.get('v.plots');
        var oppPlot = component.get('v.oppPlot');
        var opp = component.get("v.OppRecord");
        var today = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
        for(var i=0;i<plt.length; i++){  
            if(plt[i].Id ===  edi ){
                if(plt[i].Name!=null)
                {
                    component.set('v.Showfields', true);
                    component.set('v.searchText1', plt[i].Name);
                    component.set('v.projectName', plt[i].Project__r.Name);
                    component.set('v.flatNumber', plt[i].Name);
                    //alert(plt[i].Block1__c);
                    component.set('v.blockName', plt[i].Block1__c);
                }
                selPlot = plt[i];
                
                oppPlot.SLead__c=component.get('v.recordId');
                oppPlot.Unit__c = plt[i].Id;
                oppPlot.Block_Lookup__c = plt[i].Block_Lookup__c;
                oppPlot.Project__c = plt[i].Project__r.Project__c;
                oppPlot.Block__c = plt[i].Block__c;
                oppPlot.Wing__c = plt[i].Wing__c;
                oppPlot.BHK_Type__c = plt[i].BHK_Type__c;
                oppPlot.Carpet_Area__c = plt[i].Carpet_Area__c;
                oppPlot.Balcony_Area_Sq_ft__c = plt[i].Balcony_Area_Sq_ft__c;
                oppPlot.Rate_per_sqft__c = plt[i].Rate_per_sqft__c;
                //  oppPlot.Car_Parking__c = plt[i].Car_Parking__c;
                oppPlot.Water_Electricity_Rate__c = plt[i].Water_Electricity_Charges__c;
                oppPlot.Clubhouse_Charges__c = plt[i].Clubhouse_Charges__c;
                oppPlot.Generator_Charges__c = plt[i].Generator_Charges__c;
                oppPlot.Piped_Gas_Charges__c = plt[i].Piped_Gas__c;
                oppPlot.Legal_Fees__c = plt[i].Legal_Charges__c;
                oppPlot.Super_Built_UpArea__c = plt[i].Super_Built_up_Area__c;
                oppPlot.Scheme__c = plt[i].Scheme__c;
                oppPlot.W_E_Charges__c = plt[i].W_E_Charges__c;
                oppPlot.Sit_Out_Area_Sq_ft__c = plt[i].SitOut_Area_Sq_ft__c;
                oppPlot.Terrace_Area_Sq_ft__c = plt[i].Terrace_Area_Sq_ft__c;
                oppPlot.Garden_Area_Sq_ft__c = plt[i].Garden_Area_Sq_ft__c;
                oppPlot.Unit_Facing_Direction__c = plt[i].Unit_Facing_Direction__c;
                oppPlot.Maintenance_Charge__c = plt[i].Maintenance_Charge__c;
                oppPlot.Floor_Rise_Charges_Rate__c = plt[i].Floor_Rise_Charge__c;
                oppPlot.Guideline_Value__c = plt[i].Project__r.Guideline_Value_Charges__c;
                oppPlot.Home_Automation_Rate__c = plt[i].Project__r.Home_Automation__c;
                
                component.set('v.GrandTotal',plt[i].Sale_Consideration__c);
                component.set('v.GrandTotalwithGST',plt[i].Total_Payable_Charges__c);
                
                oppPlot.Quote_date__c = today;
                
                
                component.set('v.today', today);
                component.set('v.RecTypeId',plt[i].Name);
                helper.handleCalculations(component, event, helper);    
                break;
            } 
        } 
        component.set('v.showCostSheet',true);
       // component.set('v.plots', selPlot);
        //alert('Update 3');
        component.set('v.oppPlot',oppPlot);
        component.set('v.matchplots',[]);
        
    },
    
    
    navigateToPaymentSchedule: function (component, event, helper) {
        //alert('paymentType 1 :'+  component.get("v.oppPlot.Payment_Type__c"));
        //alert('calling the payment');
        //alert(component.get("v.GrandTotal"));
        var payType = component.get("v.oppPlot.Payment_Type__c");
        if(payType != 'None'){
            //helper.getFilteredLead(component,event,helper);
            helper.getmasterpaymentschedule(component,event,helper);
            
            //  helper.handleCalculations(component,event,helper);
            component.set("v.showNextCmp", true);
        }
        else{
            helper.showToast('Error','Mandate Error','Please Select The Payment Type');
        }
        
        
        
    },
    doSave: function(component,event,helper) {
        
        
        if (helper.validate(component, event)) {
            helper.save(component,event,helper);
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
        
        
        //   var homeEvt = $A.get("e.force:navigateToObjectHome");
        //  homeEvt.setParams({
        //      "scope": "Lead"
        //  });
        // homeEvt.fire();
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
    }
    ,
    
    handleParkingOptionChange : function(component, event, helper) {
        var selPlot= component.get('v.plots');
        var oppPlot = component.get('v.oppPlot');
        var selectedValue = component.find("parkingSelect").get("v.value");
        if (selectedValue === "Yes") {
            
            component.set('v.isSingleCheckboxChecked', true);
            oppPlot.Car_Parking__c=selPlot[0].Car_Parking__c;
            oppPlot.Type_of_Car_Parking__c='Single Covered';
            
        }
        else {
            oppPlot.Car_Parking__c=0;
            
        }
        component.set('v.oppPlot',oppPlot);
        
        
        
    },
    
    handleGSTAggrementOptionChange : function(component, event, helper) {
        var selPlot= component.get('v.plots');
        var oppPlot = component.get('v.oppPlot');
        var selectedValue = component.find("gstAggremSelect").get("v.value");
        if (selectedValue === "Yes") {
            
            component.set('v.isGSTChecked', true);
            oppPlot.GST_for_Aggrement_Value__c=selPlot[0].Project__r.GST_on_Aggrement__c;
        }
        else {
            oppPlot.GST_for_Aggrement_Value__c=0;
            
        }
        component.set('v.oppPlot',oppPlot);
        
        
        
    },
    handleGSTOtherOptionChange : function(component, event, helper) {
        var selPlot= component.get('v.plots');
        var oppPlot = component.get('v.oppPlot');
      //  alert(JSON.stringify(oppPlot))
        var selectedValue = component.find("gstOthSelect").get("v.value");
        if (selectedValue === "Yes") {
            
            component.set('v.isgstonOtherChecked', true);
            oppPlot.GST_For_Other_Charges__c=selPlot[0].Project__r.GST_on_Other__c;
        }
        else {
            oppPlot.GST_For_Other_Charges__c=0;
            
        }
        component.set('v.oppPlot',oppPlot);
        
        
        
    }
})