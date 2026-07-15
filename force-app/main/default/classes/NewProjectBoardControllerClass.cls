public class NewProjectBoardControllerClass {
    @auraEnabled
    Public static List<Project__c> getProjects(){
        return [SELECT Id,Name,Project__c,Project_Address__c,Total_Units__c,Available_Units__c,Booked_Units__c,Not_Released_Units__c,Blocked_Units__c,Total_Sold__c,HandedOver_Units__c FROM Project__c];
    }
    @auraEnabled
    Public static List<Plot__c> getPlots(string Project){
        return [SELECT Id,Project__c,Name,Price_Per_Sq_Ft__c,Block1__r.Name, BHK_Type__c, Basic_Cost_with_CP__c, Booked_Date__c, CMWSSB__c, Carpet_Area__c, Clubhouse_Charges__c, Flat_Type__c, Floor_Rise__c, Floor__c,
                Guideline_Value__c, Infrastructure_Charges_per_sqft__c, Infrastructure__c, Interior_Charges__c, LO_Dev_Details__c, Lead_ID__c, Legal_Charges__c, Legal_Documentation_Charges__c,
                Measurment_Type__c, Other_Charges__c, Phase_Detail__c, Piped_Gas__c, Plot_Number__c, Plot_Size__c, Rate_per_sqft__c, Status__c, Super_built_up_area__c, TNEB__c, Terrace_Area__c, Tower__c,
                UDS__c, Unit_Configuration_Name__c, Unit_Facing_Direction__c, amenities_charges__c, GST__c, Sub_total__c, Total_Cost__c, Property_Type__c, Plot_Land_Area__c, Basic_Price__c, Club_House__c, Corpus_Fund__c,
                EB_GST_18__c, GST1__c, Maintenance_Charge__c, Rs_100_Per_Sft_Infra_STP_EB__c, Sold_Details__c, Sale_Area__c, Basic_Cost__c, Basic_Cost_for_Plot_land_Area__c, Type_Duplex__c, Plot_Type__c, Corner__c,
                Built_up_area__c, Undivided_Share_of_Land__c,(SELECT Id, First_Applicant_Name__c FROM Bookings__r where Stage__c!= 'Cancellation' limit 1) FROM Plot__c WHERE Project__c=:project order by Name Asc];
    }    
}