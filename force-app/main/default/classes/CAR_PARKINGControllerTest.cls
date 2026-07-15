@isTest
public class CAR_PARKINGControllerTest {

    @isTest
    static void testClassInstantiation() {
        Test.startTest();
        CAR_PARKINGController controller = new CAR_PARKINGController();
        Test.stopTest();

        System.assertNotEquals(null, controller, 'Controller should be instantiated');
    }
}