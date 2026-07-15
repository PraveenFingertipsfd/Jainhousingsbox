({
    searchRecordsHelper : function(component, event, helper, value) {
        //$A.util.removeClass(component.find("Spinner"), "slds-hide");
        
        var searchString = component.get('v.searchString') || '';
        var queryValue = component.get('v.queryValue') || '';
        var queryValue1 = component.get('v.queryValue1') || '';
        component.set('v.message', '');
        var additionalField = component.get('v.additionalfield');
        console.log('additionalField: '+ additionalField);
        
        var action = component.get('c.fetchRecords');
        action.setParams({
            'objectName' : component.get('v.objectName'),
            'filterField' : component.get('v.fieldName'),
            'searchString' : searchString,
            'value' : value,
            'queryField': component.get('v.queryField'),
            'queryValue': queryValue,
            'queryField1': component.get('v.queryField1'),
            'queryValue1': queryValue1,
            'additionalfield': additionalField
        });
        action.setCallback(this,function(response){
            var result = response.getReturnValue();
            if(response.getState() === 'SUCCESS') {
                if(result.length > 0) {
                    // To check if value attribute is prepopulated or not
                    if( $A.util.isEmpty(value) ) {
                        component.set('v.recordsList',result);        
                    } else {
                        component.set('v.selectedRecord', result[0]);
                    }
                    //component.set('v.showDropdown',false);
                    //component.set('v.showDropdown',true);
                } else {
                    component.set('v.message', "No Records Found for '" + searchString + "'");
                }
            } else {
                // If server throws any error
                var errors = response.getError();
                if (errors && errors[0] && errors[0].message) {
                    component.set('v.message', errors[0].message);
                }
            }
            // To open the drop down list of records
            if( $A.util.isEmpty(value) )
                $A.util.addClass(component.find('resultsDiv'),'slds-is-open');
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