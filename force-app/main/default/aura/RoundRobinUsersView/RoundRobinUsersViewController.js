({
    doInit: function(component, event, helper) {
        var action = component.get("c.fetchRoundRobinMembers");
        action.setParams({ 'recordId': component.get("v.recordId") });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var PostSalesUsers=[];
                var result = response.getReturnValue();
                
                for (var i = 0; i < result.length; i++) {
                    if (result[i].User_Type__c === 'Post Sales') {
                      	PostSalesUsers.push(result[i]);
                    }
                }
                component.set("v.roundRobinMemberspostsale", PostSalesUsers);
                console.log(response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },

    toggleActiveStatus: function(component, event, helper) {
        var userId = event.getSource().get("v.value");
        console.log(userId);
        var action = component.get("c.toggleMemberStatus");
        action.setParams({ 'memId': userId,
                         'recId' :  component.get('v.recordId')});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                $A.get('e.force:refreshView').fire();
                var PostSalesUsers=[];
                var result = response.getReturnValue();
                
                for (var i = 0; i < result.length; i++) {
                    if (result[i].User_Type__c === 'Post Sales') {
                      	PostSalesUsers.push(result[i]);
                    }
                }
                component.set("v.roundRobinMemberspostsale", PostSalesUsers);
                console.log('yes got it',response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    }
})