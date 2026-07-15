public class GenerateSaleDeed {
    public static Blob generateSaleDeed(Id recId) {
        Booking__c booking = [SELECT Id, Name, Project__c FROM Booking__c WHERE Id = :recId LIMIT 1];
        PageReference pref = Page.Sale_Deed_Araya;
        pref.getParameters().put('id', recId);
        pref.setRedirect(false);
        Blob pdfBlob = !Test.isRunningTest() ? pref.getContentAsPDF() : Blob.valueOf('testblob');
        return pdfBlob;
    }
}