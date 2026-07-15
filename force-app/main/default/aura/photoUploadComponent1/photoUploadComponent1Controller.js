({
    doInit: function(component, event, helper) {
        console.log("✅ simpleFileUpload initialized with recordId:", component.get("v.recordId"));
    },

    handleUploadFinished: function(component, event, helper) {
        console.log("📂 Upload triggered...");
        component.set("v.isUploading", true);

        const uploadedFiles = event.getParam("files");
        console.log("✅ Upload finished:", uploadedFiles);

        component.set("v.uploadedFiles", uploadedFiles);
        component.set("v.isUploading", false);
    },

    previewFile: function(component, event, helper) {
        const docId = event.currentTarget.dataset.id;
        $A.get('e.lightning:openFiles').fire({
            recordIds: [docId]
        });
    }
})