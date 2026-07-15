({
    showToast: function(component, title, message, type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type
        });
        toastEvent.fire();
    },
    
    getUploadedFiles: function(component, event, filterName) {
        var action = component.get("c.getDocumentFiles"); 
        action.setParams({  
            "recordId": component.get("v.recordId"),
            "filterName": filterName
        });      
        
        action.setCallback(this, function(response) {  
            var state = response.getState();  
            if(state == 'SUCCESS') { 
                var result = response.getReturnValue(); 
                
                if (filterName === 'Sale Agreement') {
                    result.forEach(element => 
                                   element.SystemModstamp = new Date(element.SystemModstamp).toLocaleDateString('en-GB'));
                    component.set("v.SaleAgreement", result);   
                } else if (filterName === 'Sale Deed') {
                    result.forEach(element => 
                                   element.SystemModstamp = new Date(element.SystemModstamp).toLocaleDateString('en-GB'));
                    component.set("v.SaleDeed", result);
                }
                
                this.checkFileUploadStatus(component);
            }
        });  
        
        $A.enqueueAction(action);  
    },
    
    checkFileUploadStatus: function(component) {
        var currentStage = component.get("v.currentStage");
        var saleAgreement = component.get("v.SaleAgreement") || [];
        var saleDeed = component.get("v.SaleDeed") || [];
        
        if (currentStage === 'Sale Agreement Execution Completed') {
            component.set("v.fileUploaded", saleAgreement.length > 0);
        } else if (currentStage === 'Registration Completed') {
            component.set("v.fileUploaded", saleDeed.length > 0);
        } else {
            component.set("v.fileUploaded", false);
        }
    },
    
    checkPaymentAndSubmit: function(component, fields, approvalType, percent) {
        var actionName = percent === 10 ? "c.checkTenPercentCollected" : "c.checkNinetyPercentCollected";
        var action = component.get(actionName);
        action.setParams({ recordId: component.get("v.recordId") });
        
        action.setCallback(this, function(res) {
            if (res.getState() === "SUCCESS") {
                if (res.getReturnValue()) {
                    // Payment collected - submit directly
                    fields.Stage__c = approvalType;
                    if (approvalType === 'Agreement') {
                        fields.Sale_Agreement_Status__c = "Approved";
                    } else if (approvalType === 'Registration') {
                        fields.Registration_Approval_Status__c = "Approved";
                    }
                    component.find("editForm").submit(fields);
                } else {
                    // Payment not collected - show approval modal
                    component.set("v.isProcessing", false);
                    component.set("v.showApprovalModal", true);
                    component.set("v.approvalType", approvalType);
                }
            } else {
                component.set("v.isProcessing", false);
                this.showToast("Error", "Failed to check payment status", "error");
            }
        });
        $A.enqueueAction(action);
    },
    
   UpdateDocument:function(component, event,helper,docIdList,prefix){
        var action = component.get("c.updateDocument");   
        action.setParams({
            "prefixName":  prefix,
            "idList":docIdList
        }); 
        $A.enqueueAction(action);  
    }
     /*
    getUploadedFiles : function(component, event,i){
        console.log('==>'+i);
        
        var action = component.get("c.getSaleAgreementFiles"); 
        action.setParams({  
            "recordId": component.get("v.recordId"),
            "filterName": 'Sale Agreement'
        });      
        action.setCallback(this,function(response){  
            var state = response.getState();  
            if(state=='SUCCESS'){ 
                var result = response.getReturnValue(); 
                console.log(result);
                result.forEach(element => console.log(element.SystemModstamp=new Date(element.SystemModstamp).toLocaleDateString('en-GB')));
                    component.set("v.SaleAgreement",result);   
                
                if (result && result.length > 0) {
                    component.set("v.fileUploaded", true);
                } else {
                    component.set("v.fileUploaded", false);
                }
            }
        });  
        
        $A.enqueueAction(action);  
    }*/
});