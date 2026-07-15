({
    onValueChange1 : function(component, event, helper) {
        var value = component.get("v.value");
        if (value != null && !isNaN(value)) {
            var formatted = helper.formatINR(value);
            component.set("v.formattedValue", formatted);
        } else {
            component.set("v.formattedValue", "0");
        }
    },
    
    onValueChange : function(component, event, helper) {
        var value = component.get("v.value");
        console.log('CurrencyFormatter received value:', value);
        if (value != null) {
            var numValue = Number(value);
            if (!isNaN(numValue)) {
                var formatted = helper.formatINR(numValue);
                component.set("v.formattedValue", formatted);
                return;
            }
        }
        component.set("v.formattedValue", "0");
    }

})