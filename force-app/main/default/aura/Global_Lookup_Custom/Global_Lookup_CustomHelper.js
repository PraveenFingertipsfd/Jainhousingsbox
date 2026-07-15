({
    searchRecordsHelper : function(component, event, helper, value) {
        var searchString = component.get('v.searchString') || ''; 
        var query = component.get('v.query');
        
        var action = component.get('c.fetchRecordsGB');
        action.setParams({
            'objectName' : component.get('v.objectName'),
            'filterField' : component.get('v.fieldName'),
            'query': query,
            'additionalFields':component.get('v.additionalFields'),
            'value':'',
            'searchString':searchString
        });
        
        action.setCallback(this, function(response) {
            var result = response.getReturnValue();
            if(response.getState() === 'SUCCESS') {
                if(result.length > 0) {
                    if($A.util.isEmpty(value)) {
                        component.set('v.recordsList', result);        
                    } else {
                        component.set('v.selectedRecord', result[0]);
                    }
                } else {
                    component.set('v.message', "No Records Found for '" + searchString + "'");
                }
            } else {
                var errors = response.getError();
                if (errors && errors[0] && errors[0].message) {
                    component.set('v.message', errors[0].message);
                }
            }
            if($A.util.isEmpty(value)) {
                $A.util.addClass(component.find('resultsDiv'),'slds-is-open');
            }
            $A.util.addClass(component.find("Spinner"), "slds-hide");
        });
        $A.enqueueAction(action);
    },
    removeItem: function (component, event, helper) {
        component.set('v.selectedRecord', '');
        component.set('v.value', '');
        component.set('v.searchString', '');
        setTimeout(function () {
            component.find('inputLookup').focus();
        }, 250);
        component.set('v.selectedId', '');
    }
    
})