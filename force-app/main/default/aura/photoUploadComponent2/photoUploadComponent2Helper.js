({
    getUploadedFiles : function(component) {
        var action = component.get("c.getFiles");  
        action.setParams({  
            "recordId": component.get("v.recordId")
        });      
        action.setCallback(this, function(response) {  
            if(response.getState() === "SUCCESS") {  
                component.set("v.files", response.getReturnValue());
            }  
        });  
        $A.enqueueAction(action);  
    }
})