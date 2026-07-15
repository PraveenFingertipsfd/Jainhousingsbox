({
    addProductRecord: function(component, event) {
        var productList = component.get("v.recptItemList");
        productList.push({
            'sobjectType': 'Receipt_Line_Item__c',
            'Name': '',
            'Payment_schedule__c': '',
            'Mode_of_Payment__c': '',
            'Bank_Name__c':'',
            'Payment_Type__c':'',
            'Cheque_no_Transaction_Number__c':'',
            'Received_Amount__c': '',
            'Payment_From__c':''
        });
        component.set("v.recptItemList", productList);
    },
    
    showToast : function(message,type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type":type,
            "message":  message
        });
        toastEvent.fire();
    },
})