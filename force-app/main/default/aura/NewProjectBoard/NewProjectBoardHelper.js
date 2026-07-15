({
	  showToast : function(type,title,message) {
        console.log(message)
      //  alert('h')
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type":type,
            "title":title,
            "message":message
        });
        toastEvent.fire();
    },
    calculateTotals: function(component, event, helper) {
        console.log('calculateTotals');
        var projects = component.get("v.projects");
        var totalSoldUnits = 0;
        var totalBookedUnits = 0;
        var totalAvailableUnits = 0;

        projects.forEach(function(prj) {
            totalSoldUnits += prj.Total_Sold__c || 0;
            totalBookedUnits += prj.Booked_Units__c || 0;
            totalAvailableUnits += prj.Available_Units__c || 0;
            
        });
        
        component.set("v.totalBookedUnits", totalSoldUnits + totalBookedUnits);
        component.set("v.totalAvailableUnits", totalAvailableUnits);
        this.calculateProgress(component,helper);
    },

    calculateProgress: function(component,helper) {
        console.log('here');
        var projects = component.get("v.projects");
        projects.forEach(function(prj) {
            var totalUnits = prj.Total_Units__c;
            var bookedUnits = prj.Booked_Units__c;
            var handOverUnits = prj.HandedOver_Units__c;
            var soldUnits = prj.Total_Sold__c;
            

            if (totalUnits === 0) {
                prj.progressWidth = "0";
                prj.progressPercentage = "0";
            } else {
                var percentage = Math.min(100, ((bookedUnits + handOverUnits + soldUnits) / totalUnits) * 100);
                prj.progressWidth = percentage;
                prj.progressPercentage = percentage.toFixed(2) + "%";
            }
        });
        
        component.set("v.projects", projects);
    },
        roundToTwoDecimals: function(value) {
            console.log(value);
        // Check if the value is not empty
        if (value != null && value !== '') {
            // Convert the value to a number
            let numericValue = Number(value);
            // Check if the conversion was successful (i.e., it's a valid number)
            if (!isNaN(numericValue)) {
                return numericValue.toFixed(2);  // Round to two decimal places
            }
        }
        // Return "0.00" or handle invalid cases
        return "0.00";
    }
  
})