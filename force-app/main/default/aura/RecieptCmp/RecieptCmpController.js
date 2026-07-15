({
    doInit : function(component,event,helper){
        var id=component.get('v.recordId');
        var today = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
        
        var rcpt = component.get("v.rcpt");        
        rcpt.Receipt_date__c = today;
        component.set("v.rcpt", rcpt);
        
        helper.addProductRecord(component, event,id);
        
        var action=component.get("c.getpaymentsc");
        action.setParams({'recid':  component.get('v.recordId') })
        action.setCallback(this,function(response){
            if(response.getState() == "SUCCESS"){
                var datas=response.getReturnValue();
                component.set('v.paymentschdl',  datas.pysch);
                component.set("v.paymentTypePicklist", datas.payType);
                component.set('v.interestAmount',datas.Intamt);
                
                component.set("v.projectName", datas.bkrec.Project__c);
                component.set("v.flatNumber", datas.bkrec.Unit_NumberFor__c);
                component.set("v.floorNumber", datas.bkrec.FloorNo__c);
                component.set("v.BHKType", datas.bkrec.Unit_BHK_Type__c);
                component.set("v.FlatCost", datas.bkrec.Total__c);
                component.set("v.bookingReceivedAmount", datas.bkrec.Total_received_Amount__c);
                component.set("v.bookingPendingAmount",datas.bkrec.Pending_Amount__c);
                component.set("v.totalPending",datas.bkrec.Pending_Amount__c);
                
                // Initialize filtered payment types with full list - added by karthik 29-07
                component.set("v.filteredPaymentTypes", datas.payType);
            }
        });
        $A.enqueueAction(action); 
        
        
        /*var action1 = component.get("c.getPaymentTypePicklistValues");
        action1.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                var paymentTypePicklist = response.getReturnValue();
                component.set("v.paymentTypePicklist", paymentTypePicklist);
            }
        });
        $A.enqueueAction(action1);
        
        
        var action2 = component.get("c.getBookingDetails");
        action2.setParams({'recid':  component.get('v.recordId') })
        action2.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                var db = response.getReturnValue();
                component.set("v.projectName", db.Project__c);
                component.set("v.flatNumber", db.Unit_NumberFor__c);
                component.set("v.FlatCost", db.Total__c);
                component.set("v.bookingPendingAmount",db.Pending_Amount__c);
            }
        });
        $A.enqueueAction(action2);
        
        
        var action3 = component.get("c.getInterestAmount");
        action3.setParams({ 'recId' : component.get('v.recordId')})
        action3.setCallback(this,function(response){
            if(response.getState() === 'SUCCESS'){
                var result = response.getReturnValue();
                component.set('v.interestAmount',result);
            }
        });
        $A.enqueueAction(action3);
        */
    },
    
    // When Payment_From is changed - added by karthik 29-07
    handlePaymentFromChange: function(component, event, helper) {
        var paymentFrom = component.get("v.Payment_From");
        var allOptions = component.get("v.paymentTypePicklist");
        var filteredOptions = [];

        if (paymentFrom === 'Bank') {
            // Show only specific values for Bank
            var allowedForBank = ['RTGS', 'Cheque', 'NEFT', 'Bank Transfer', 'IMPS'];
            filteredOptions = allOptions.filter(function(opt) {
                return allowedForBank.includes(opt);
            });
        } else {
            // Customer -> show all options
            filteredOptions = allOptions;
        }

        component.set("v.filteredPaymentTypes", filteredOptions);
    },
    
    searchText : function(component, event, helper){
        var pymntsc= component.get('v.paymentschdl');
        var searchText= component.get('v.searchText');
        
        var matchprds=[];
        if(searchText !=''){
            for(var i=0;i<pymntsc.length; i++){ 
                if(pymntsc[i].Name.toLowerCase().indexOf(searchText.toLowerCase())  != -1  ){
                    matchprds.push( pymntsc[i] );
                } 
            } 
            if(matchprds.length >0){
                component.set('v.matchpaymentschdl',matchprds);
            }
        }else{
            component.set('v.matchpaymentschdl',[]);
        }
        
    },
    update : function(component, event, helper){
        component.set("v.savebuttonhide",true);
        component.set('v.spinner', true);
        
        var index = event.currentTarget.dataset.record;
        var pid =event.currentTarget.dataset.id;
        var prds= component.get('v.matchpaymentschdl');
        var oitems= component.get('v.recptItemList');
        //  alert(index+'--'+pid+'---'+prds+'----'+oitems)
        for(var i=0;i<prds.length; i++){ 
            if(prds[i].Id === pid ){
                oitems[index].Payment_schedule__c = prds[i].Id;
                oitems[index].Name = prds[i].Name;
                
                oitems[index].Amount__c = prds[i].Pending_Amount__c;
                
                component.set('v.searchText', '');
                break;
            }
            
        } 
        component.set('v.recptItemList',oitems);
        component.set('v.matchpaymentschdl',[]);
        component.set('v.spinner', false);
        
    },
    ChangeName : function(component, event, helper){
        component.set("v.savebuttonhide",true);
    },
    addRow: function(component, event, helper){
        component.set("v.savebuttonhide",true);
        helper.addProductRecord(component, event);
    },
    removeRow: function(component, event, helper){
        component.set("v.savebuttonhide",false);
        
        var selectedItem = event.currentTarget;
        var index = selectedItem.dataset.record;
        
        var oitems= component.get('v.recptItemList');
        if(oitems[index].Id !='undefined' && oitems[index].Id !=''){
            var action=component.get("c.deleteProduct");
            action.setParams({'prId':  oitems[index].Id  })
            action.setCallback(this,function(response){
                
                if(response.getState() == "SUCCESS"){ 
                    
                    oitems.splice(index, 1);
                    component.set("v.recptItemList", oitems);
                    
                    if(oitems.length < 1){
                        helper.addProductRecord(component, event);
                    }
                }
            });
            $A.enqueueAction(action);
        }
        
        
    },
    quoteSave: function(component,event,helper){
        let isAllValid = component.find('field').reduce(function(isValidSoFar, inputCmp){
            inputCmp.showHelpMessageIfInvalid();
            return isValidSoFar && inputCmp.checkValidity();
        },true);
        if(isAllValid == true){
            var oit= component.get('v.recptItemList');
            if(oit[0].Bank_Name__c == undefined || oit[0].Bank_Name__c == null || oit[0].Bank_Name__c == ''){
                helper.showToast("Please fill Bank Name","Error");
                isAllValid = false;
            }
        }
        else{
            helper.showToast("Please fill all mandatory fields","Error");
        }
        if(isAllValid == true){
            component.set("v.savebuttonhide",true);
            var ponum=component.get("v.rcpt.Receipt_Name__c"); 
            var reark = component.get("v.rcpt.Remarks__c"); 
            var oit= component.get('v.recptItemList');
            //alert('Inside Save Method');
            
            var tarik=component.get("v.rcpt.Receipt_date__c");
            
            var action = component.get("c.insertReceiptLineItems");
            //   alert('Hello');
            action.setParams({
                'polist' : component.get('v.recptItemList'),
                'pon' : ponum,
                'remark':reark,
                'poc' : tarik,
                'PaymentFrom': component.get('v.Payment_From'),
                'recid':  component.get('v.recordId'),
                'paidAmount' : component.get('v.receivedAmount'),
                'interestAmount' : component.get('v.receivedInterestAmount')
            });
            action.setCallback(this, function(response) {
                var state = response.getState();      
                //alert(state);
                console.log('state '+state);
                if (state === "SUCCESS") {
                    
                    var ttu=response.getReturnValue();
                    if(ttu == 'Duplicate Cheque/Transaction Number Entered'){
                        helper.showToast("Duplicate Cheque/Transaction Number Entered","Error");
                    }
                    else{
                        helper.showToast("Receipt has been created succesfully","Success");
                        $A.get('e.force:refreshView').fire();
                        var urlEvent = $A.get("e.force:navigateToURL");
                        urlEvent.setParams({
                            "url": "/"+ttu
                        });
                        urlEvent.fire();
                        $A.get('e.force:refreshView').fire();
                    }
                    
                }
                else{
                    var errors = response.getError();
                    console.log('state '+ JSON.stringify(errors));
                    helper.showToast( errors[0].message, "Error");
                }
            });
            $A.enqueueAction(action);
        }
        
        
        
        // $A.get('e.force:refreshView').fire();
    },
    quoteCancel:function(component, event, helper){
        component.set("v.savebuttonhide",false);
        component.set("v.recptItemList", []);
        
        component.set("v.matchpaymentschdl", []);
        component.set("v.paymentschdl", []);
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": component.get('v.recordId'),
            "slideDevName": "detail"
        });
        navEvt.fire();
        
    },
    getGrandTotal : function(component, event, helper){
        component.set("v.savebuttonhide",true);
        var index = event.currentTarget.dataset.record;
        var oitems= component.get('v.recptItemList');
        var paymententered = component.get('v.receivedAmount');
        var bookPendingAmount = component.get('v.bookingPendingAmount');

        if(paymententered > bookPendingAmount){
            paymententered = String(paymententered).substring(0, String(paymententered).length - 1);
            component.set('v.receivedAmount',paymententered);
            helper.showToast("Amount Received cannot exceed the pending amount", "error");
        }
        
        component.set('v.newPendingAmount',(parseFloat(bookPendingAmount) - parseFloat(component.get('v.receivedAmount'))));            
        /*component.set('v.recptItemList',oitems);
        
        var grandtotal = 0;
        var pendingtotal = 0;
        var oit= component.get('v.recptItemList');
        for(var i=0;i<oit.length; i++){ 
            grandtotal = (parseFloat(grandtotal)+parseFloat(oit[i].Received_Amount__c));
        }
        for(var i=0;i<oit.length; i++){ 
            pendingtotal = (parseFloat(pendingtotal)+parseFloat(oit[i].Pending_Amount__c));
        }
        */
        if(component.get('v.receivedAmount') == '' || component.get('v.receivedAmount') == null){
            component.set('v.totalrcvdAmount',0);
            component.set('v.totalPending',component.get('v.bookingPendingAmount'));
        }
        else{
            component.set('v.totalrcvdAmount',component.get('v.receivedAmount'));
            component.set('v.totalPending',component.get('v.newPendingAmount'));
        }
        
        
        
    }
})