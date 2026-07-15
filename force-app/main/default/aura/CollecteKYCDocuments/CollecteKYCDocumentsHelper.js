({
	showToast : function(title, message, type) {
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type,
            "duration": 8000  // duration in milliseconds (8000 = 8 seconds)
        });
        toastEvent.fire();
    }
})