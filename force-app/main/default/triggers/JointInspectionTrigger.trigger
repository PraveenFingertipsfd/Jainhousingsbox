trigger JointInspectionTrigger on Joint_Inspection__c (after update) {
    
    List<id> jiIds = new List<Id>();
    for(Joint_Inspection__c ji:Trigger.new)
    {
        Joint_Inspection__c jiOld = Trigger.oldMap.get(ji.Id);
        
        if(ji.Joint_Inspection_Status__c =='Completed' && jiOld.Joint_Inspection_Status__c != 'Completed'){
            
            jiIds.add(ji.Id);        
        }
 
    }
    if(!jiIds.isEmpty()){
         JointInspectionController.sendCSRFuture(jiIds);
    }
    
}