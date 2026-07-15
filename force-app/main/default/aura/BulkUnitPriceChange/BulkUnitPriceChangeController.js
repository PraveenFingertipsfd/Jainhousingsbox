({
    doInit : function(component, event, helper){
        //helper.getPicklistValues1(component, event);
        //helper.getPicklistValues2(component, event);
        
        helper.getPicklistValues(component, event);
        helper.getTowerName(component,event);
        helper.getLeadSource(component, event);
        
        var actions3 = [{ label: 'Show details', 
                         name: 'show_details3' }];
        component.set('v.mycolumns3', [{label: 'Unit Name', fieldName: 'Name', type: 'text'},
                                       {label: 'Unit Type', fieldName: 'BHK_Type__c', type: 'text'},
                                       {label: 'Project', fieldName: 'Project_Name__c', type: 'text'},
                                       {label: 'Status', fieldName: 'Status__c', type: 'text'}]);
        
        var action = component.get("c.getuserdetails");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                component.set('v.users', result);
                
            }
        });
        $A.enqueueAction(action);
    },
    
    
    handleOnChange: function(component, event, helper) {
        if(component.get("v.FilterCreatedDate") == 'CUSTOM'){
            component.set("v.showFilterDate",true);
        }
        else{
            component.set("v.showFilterDate",false);
        }
        
        var leadstatus = component.find("leadstatusPicklist").get("v.value");
        var leadSource = component.find("leadSourcePicklist").get("v.value");
        //var blockValue = component.find("blockPicklist").get("v.value");
        var towerValue = component.find("towername").get("v.value");
        component.set("v.leadStatus",leadstatus);
        component.set("v.leadSource",leadSource);
        //component.set("v.blockValue",blockValue);
        component.set("v.towervalue",towerValue);
        
        helper.getFilteredLead(component, event, helper);
    },
    
    
    
    fetchbeats : function(component, event, helper) {
        component.set('v.showupcoming',false);
        if(component.get('v.SEId') != null && component.get('v.SEId') != ''){
            component.set('v.spinner',true);
            var action = component.get("c.getupcominbeats");
            action.setParams({'uId':  component.get('v.SEId') })
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var result = response.getReturnValue();
                    component.set("v.mydata3", response.getReturnValue());
                    component.set('v.showupcoming',true);
                    component.set('v.spinner',false);
                }
            });
            $A.enqueueAction(action);
        }
    },
    handleRowAction3: function (component, event, helper) {
        component.set('v.spinner',true);
        
        var row = event.getParam('row');
        component.set('v.beatId',row.Id);
        var action = component.get("c.getvisitList");
        action.setParams({'BeatId':  row.Id})
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                component.set('v.mydata4', response.getReturnValue());
                component.set('v.showrecent',true);
                component.set('v.spinner',false);
                
            }
        });
        $A.enqueueAction(action);
    },
    
    
    docancel2: function (component, event, helper) {
        helper.doCancel(component,event,helper);
    },
    
    
    updateSelectedText4: function (component, event) {
        var selectedRows = event.getParam('selectedRows');
        component.set('v.selectedRowsCount4', selectedRows.length);
        component.set('v.selectedUsers', selectedRows);
        
    },
    changeBeatOwner: function (component, event,helper) {
        var project = component.find("enter-search").get("v.value");
        component.set('v.searchText2', project);
        if(component.get('v.searchText2') != null && component.get('v.searchText2') !='' && component.get('v.searchText2') !=undefined && component.get('v.searchText2') >0){
            
            component.set('v.spinner',true);
            var action = component.get("c.updateOwner");
            action.setParams({'contacts': component.get('v.selectedUsers'),
                              //'currentUserId' : component.get("v.recordId"),
                              'price' : project
                             })
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    component.set('v.mydata3', response.getReturnValue());
                    var test = [];
                    var selRows = component.get('v.selectedUsers');
                    
                    component.set('v.selectedUsers',test);
                    
                    
                    component.set('v.spinner',false);
                    
                    helper.doCancel(component,event,helper);
                    helper.showToast("Unit Price changed succesfully","Success");
                    $A.get("e.force:closeQuickAction").fire();
                }
            });
            $A.enqueueAction(action);
            
        }else{
            
            helper.showToast("Please Enter The Unit Price","error");
        }
        
        
    },
    searchText : function(component, event, helper) {
        var routes= component.get('v.users');
        var searchText= component.get('v.searchText');
        
        var matchroutes=[];
        if(searchText !=''){
            for(var i=0;i<routes.length; i++){ 
                
                if(routes[i].Name.toLowerCase().indexOf(searchText.toLowerCase())  != -1  ){
                    matchroutes.push( routes[i] )
                } 
            } 
            if(matchroutes.length >0){
                component.set('v.matchUsers',matchroutes);
            }
        }else{
            component.set('v.matchUsers',[]);
        }
    },
    searchText2 : function(component, event, helper) {
        var routes= component.get('v.users');
        var searchText= component.get('v.searchText2');
        var matchroutes=[];
        if(searchText !=''){
            for(var i=0;i<routes.length; i++){ 
                if(routes[i].Name.toLowerCase().indexOf(searchText.toLowerCase())  != -1  ){
                    matchroutes.push( routes[i] )
                } 
            } 
            if(matchroutes.length >0){
                component.set('v.matchUsers2',matchroutes);
            }
        }else{
            component.set('v.matchUsers2',[]);
        }
    },
    update: function(component, event, helper) {
        
        component.set('v.userId', event.currentTarget.dataset.id);
        component.set('v.showUsers',true);
        var rdi = component.get('v.userId');
        var routes= component.get('v.matchUsers');
        for(var i=0;i<routes.length; i++){ 
            if(routes[i].Id ===  rdi ){
                component.set('v.searchText', routes[i].Name);
                break;
            } 
        } 
        component.set('v.matchUsers',[]);
        if(component.get('v.userId') != null && component.get('v.userId') != ''){
            component.set('v.spinner',true);
            component.set('v.showFilter',true);
            helper.getFilteredLead(component,event,helper);
        }
        
    },
    update2: function(component, event, helper) {
        component.set('v.NextUserId', event.currentTarget.dataset.id);
        
        var rdi = component.get('v.NextUserId');
        var routes= component.get('v.matchUsers2');
        for(var i=0;i<routes.length; i++){ 
            if(routes[i].Id ===  rdi ){
                component.set('v.searchText2', routes[i].Name);
                break;
            } 
        } 
        component.set('v.matchUsers2',[]);
        
        
    },
    
    
    
    
})