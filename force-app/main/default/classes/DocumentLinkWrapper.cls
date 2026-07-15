public class DocumentLinkWrapper {
    @AuraEnabled public String name;
    @AuraEnabled public String url;

    public DocumentLinkWrapper(String name, String url) {
        this.name = name;
        this.url = url;
    }
}