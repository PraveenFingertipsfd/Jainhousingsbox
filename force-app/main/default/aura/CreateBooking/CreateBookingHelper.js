({
	addApplicantRecord: function(component, event, helper){
        var appList = component.get("v.applicantList");
        appList.push({
            'sObjectType': 'Co_Applicant__c',
            'Salutation__c':'',
            'Name':'',
            'Relalation_Details__c':'Son',
            'W_o_S_o_C_o_c__c':'',
            'Contact_Number__c':'',
            'Country__c': '',
            'Date_of_Birth__c': '',
            'Email__c': '',
            'PAN_Number__c': '',
            'Booking__c':''        
        });
        component.set("v.applicantList", appList);
    },
    
    showToast : function(message,type,title){
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type":type,
            "message":  message,
            "title":title
        });
        toastEvent.fire();
    },
    
})