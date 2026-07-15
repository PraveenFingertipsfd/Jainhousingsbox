trigger UnitTrigger on Plot__c (before insert, before update, after update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {

            Set<Id> projectIds = new Set<Id>();
            for (Plot__c plot : Trigger.new) {
                if (plot.Project__c != null) {
                    projectIds.add(plot.Project__c);
                }
            }

            Map<Id, Project__c> projectMap = new Map<Id, Project__c>(
                [SELECT Id, Name, Corpus_Fund__c, GST_on_Corpus_Fund__c, Maintenance_Charge__c, GST_on_Maintenance_Charge__c, No_of_Maintenance_Years__c, Premium_Charge_Per_Sq_ft__c, EB_Debris_Charges__c
                 FROM Project__c WHERE Id IN :projectIds]
            );

            for (Plot__c plot : Trigger.new) {
                if (String.isBlank(plot.Name)) {
                    if (plot.Project__c != null && projectMap.containsKey(plot.Project__c)) {
                        Project__c proj = projectMap.get(plot.Project__c);
                        if (proj != null && proj.Name != null) {
                            // Use default '0' if Floor__c or Plot_Number__c are null
                            String floor = plot.Floor__c != null ? String.valueOf(plot.Floor__c) : '0';
                            String flatNumberRaw = plot.Plot_Number__c != null ? String.valueOf(plot.Plot_Number__c) : '00';
                            String flat = flatNumberRaw.length() == 1 ? '0' + flatNumberRaw : flatNumberRaw;
                            plot.Name = floor + flat;
                        }
                    }
                }

                if (plot.Project__c != null && projectMap.containsKey(plot.Project__c)) {
                    Project__c proj = projectMap.get(plot.Project__c);
                    if (proj != null) {
                        if (plot.Corpus_Fund__c == null) {
                            plot.Corpus_Fund__c = proj.Corpus_Fund__c;
                        }
                        if (plot.GST_on_Corpus_Fund__c == null) {
                            plot.GST_on_Corpus_Fund__c = proj.GST_on_Corpus_Fund__c;
                        }
                        if (plot.Is_Premium_Unit__c && plot.Premium_Charge__c == null && plot.Super_built_up_area__c != null) {
                            plot.Premium_Charge__c = proj.Premium_Charge_Per_Sq_ft__c != null ? proj.Premium_Charge_Per_Sq_ft__c * plot.Super_built_up_area__c : 0;
                        }
                        if (plot.Maintenance_Charge__c == null && plot.Super_built_up_area__c != null) {
                            Decimal maintenanceCharge = (proj.Maintenance_Charge__c != null ? proj.Maintenance_Charge__c : 0) * 
                                                       (proj.No_of_Maintenance_Years__c != null ? proj.No_of_Maintenance_Years__c : 0) * 
                                                       plot.Super_built_up_area__c;
                            plot.Maintenance_Charge__c = maintenanceCharge;
                        }
                        if (plot.GST_on_Maintenance_Charge__c == null) {
                            plot.GST_on_Maintenance_Charge__c = proj.GST_on_Maintenance_Charge__c;
                        }
                    }
                }
            }
        }

        if (Trigger.isUpdate) {
            List<Rate_Revision_History__c> RRHisLst = new List<Rate_Revision_History__c>();

            Set<Id> projectIds = new Set<Id>();
            for (Plot__c plot : Trigger.new) {
                if (plot.Project__c != null)
                    projectIds.add(plot.Project__c);
            }
            Map<Id, Project__c> projectMap = new Map<Id, Project__c>([
                SELECT Id, Name, Corpus_Fund__c, GST_on_Corpus_Fund__c, Maintenance_Charge__c, GST_on_Maintenance_Charge__c, No_of_Maintenance_Years__c, Premium_Charge_Per_Sq_ft__c, EB_Debris_Charges__c 
                FROM Project__c WHERE Id IN :projectIds
            ]);

            for (Plot__c newPT : Trigger.new) {
                Plot__c oldPT = Trigger.oldMap.get(newPT.Id);

                Map<String, String> changedFields = new Map<String, String>();

                if (newPT.Name != oldPT.Name) {
                    changedFields.put('Name', 'Name has changed from "' + oldPT.Name + '" to "' + newPT.Name + '"');
                }
                if (newPT.Price_Per_Sq_Ft__c != oldPT.Price_Per_Sq_Ft__c) {
                    changedFields.put('Price Per Sq Ft', 'Price Per Sq Ft changed from "' + oldPT.Price_Per_Sq_Ft__c + '" to "' + newPT.Price_Per_Sq_Ft__c + '"');
                }
                // ... [similarly for other fields as in your original code] ...

                if (!changedFields.isEmpty()) {
                    Rate_Revision_History__c RRHistory = new Rate_Revision_History__c();
                    RRHistory.Unit__c = newPT.Id;
                    RRHistory.Changed_Fields__c = String.join(changedFields.keySet(), ';\n');
                    RRHistory.Changed_Values__c = String.join(changedFields.values(), ';\n');
                    RRHisLst.add(RRHistory);
                }

                if ((newPT.Super_built_up_area__c != oldPT.Super_built_up_area__c || newPT.Is_Premium_Unit__c != oldPT.Is_Premium_Unit__c)
                    && projectMap.containsKey(newPT.Project__c)) {
                    Decimal builtuparea = newPT.Super_built_up_area__c != null ? newPT.Super_built_up_area__c : 0;
                    Project__c proj = projectMap.get(newPT.Project__c);

                    if (proj != null) {
                        if (newPT.Is_Premium_Unit__c) {
                            newPT.Premium_Charge__c = proj.Premium_Charge_Per_Sq_ft__c != null ? proj.Premium_Charge_Per_Sq_ft__c * builtuparea : 0;
                        } else {
                            newPT.Premium_Charge__c = 0;
                        }
                        newPT.Maintenance_Charge__c = (proj.Maintenance_Charge__c != null ? proj.Maintenance_Charge__c : 0) *
                                                     (proj.No_of_Maintenance_Years__c != null ? proj.No_of_Maintenance_Years__c : 0) *
                                                     builtuparea;
                    }
                }
            }
            if (!RRHisLst.isEmpty())
                insert RRHisLst;
        }
    }

    if (Trigger.isAfter) {
        if (Trigger.isUpdate) {
            List<Plot__c> qaGivenPlots = new List<Plot__c>();
            for (Plot__c plot : Trigger.new) {
                Plot__c oldPlot = Trigger.oldMap.get(plot.Id);
                if (plot.QA_Given__c == true && (oldPlot == null || oldPlot.QA_Given__c == false)) {
                    qaGivenPlots.add(plot);
                }
            }

            if (!qaGivenPlots.isEmpty()) {
                CustomNotificationType notificationType;
                try {
                    notificationType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'QA_Notification' LIMIT 1];
                } catch (Exception e) {
                    System.debug('Notification type not found: ' + e.getMessage());
                    return;
                }

                Map<Id, Plot__c> plotsWithRelations = new Map<Id, Plot__c>([SELECT Id, Name, Project__r.CRM_Manager__c, Booking__r.OwnerId FROM Plot__c WHERE Id IN :qaGivenPlots]);

                for (Plot__c plot : plotsWithRelations.values()) {
                    if (plot.Project__r != null && plot.Project__r.CRM_Manager__c != null) {
                        try {
                            Messaging.CustomNotification notification = new Messaging.CustomNotification();
                            notification.setNotificationTypeId(notificationType.Id);
                            notification.setTargetId(plot.Id);
                            notification.setTitle('Quality Assurance Completed');
                            notification.setBody('Quality Assurance has been completed for Unit ' + plot.Name);
                            notification.send(new Set<String>{plot.Project__r.CRM_Manager__c});
                        } catch (Exception e) {
                            System.debug('Failed to send CRM Manager notification: ' + e.getMessage());
                        }
                    }

                    if (plot.Booking__r != null && plot.Booking__r.OwnerId != null) {
                        try {
                            Messaging.CustomNotification notification = new Messaging.CustomNotification();
                            notification.setNotificationTypeId(notificationType.Id);
                            notification.setTargetId(plot.Id);
                            notification.setTitle('Quality Assurance Completed');
                            notification.setBody('Quality Assurance has been completed for Unit ' + plot.Name);
                            notification.send(new Set<String>{plot.Booking__r.OwnerId});
                        } catch (Exception e) {
                            System.debug('Failed to send Booking Owner notification: ' + e.getMessage());
                        }
                    }
                }
            }
        }
    }
}