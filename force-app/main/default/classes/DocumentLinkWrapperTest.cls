@isTest
public class DocumentLinkWrapperTest {

    @isTest
    static void testConstructorWithValues() {
        Test.startTest();
        DocumentLinkWrapper wrapper = new DocumentLinkWrapper('Test Document', 'https://example.com/doc');
        Test.stopTest();

        System.assertEquals('Test Document', wrapper.name, 'Name should match');
        System.assertEquals('https://example.com/doc', wrapper.url, 'URL should match');
    }

    @isTest
    static void testConstructorWithNullValues() {
        Test.startTest();
        DocumentLinkWrapper wrapper = new DocumentLinkWrapper(null, null);
        Test.stopTest();

        System.assertEquals(null, wrapper.name, 'Name should be null');
        System.assertEquals(null, wrapper.url, 'URL should be null');
    }

    @isTest
    static void testConstructorWithSpecialCharacters() {
        Test.startTest();
        DocumentLinkWrapper wrapper = new DocumentLinkWrapper('Doc & File <Test>', 'https://example.com/doc?id=1&type=pdf');
        Test.stopTest();

        System.assertEquals('Doc & File <Test>', wrapper.name);
        System.assertEquals('https://example.com/doc?id=1&type=pdf', wrapper.url);
    }
}