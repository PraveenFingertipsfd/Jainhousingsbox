({
    
    doInit: function(component, event, helper) {
        helper.getUploadedFiles(component);
    },

    previewFile: function(component, event) {
        $A.get('e.lightning:openFiles').fire({ 
            recordIds: [event.currentTarget.id]
        });  
    },

    
    uploadFinished: function(component, event, helper) {
        helper.getUploadedFiles(component);
        
        var files = event.getParam("files");
        var latestFile = files[0];
        component.set("v.selectedFileId", latestFile.documentId);
        
        // Notify parent
        try {
            var compEvent = component.getEvent("fileUploadComplete");
            compEvent.setParams({
                "files": [ { Id: latestFile.documentId } ]
            });
            compEvent.fire();
        }catch (e) {
            console.error("Failed to fire upload event:", e);
        }
    }, 
    
    

    handleFileSelection: function(component, event) {
        const selectedId = event.getSource().get("v.value");
        component.set("v.selectedFileId", selectedId);

        // Notify parent about selection
        var compEvent = component.getEvent("fileUploadComplete");
        compEvent.setParams({
            "files": [ { Id: selectedId } ]
        });
        compEvent.fire();
    },
    
    onRenderComplete: function(component, event, helper) {
        // Helps catch initialization errors
        console.log("Component fully rendered");
    }
})