@isTest
public class RoundRobinUsersViewTest {

    @TestSetup
    static void setupTestData() {
        // Grab two active users for lookups
        List<User> users = [SELECT Id FROM User WHERE IsActive = true LIMIT 2];
        Id testUser1Id = users[0].Id;
        Id testUser2Id = (users.size() > 1) ? users[1].Id : users[0].Id;

        // Insert a Round_Robin__c
        Round_Robin__c roundRobin = new Round_Robin__c();
        insert roundRobin;

        // Insert Round_Robin_Member__c records WITH User_Type__c set
        Round_Robin_Member__c member1 = new Round_Robin_Member__c(
            Round_Robin__c = roundRobin.Id,
            User__c = testUser1Id,
            Active__c = true,
            User_Type__c = 'Post Sales'
        );
        insert member1;

        Round_Robin_Member__c member2 = new Round_Robin_Member__c(
            Round_Robin__c = roundRobin.Id,
            User__c = testUser2Id,
            Active__c = false,
            User_Type__c = 'Post Sales'
        );
        insert member2;
    }

    @isTest
    static void testFetchRoundRobinMembers_WithMembers() {
        Round_Robin__c rr = [SELECT Id FROM Round_Robin__c LIMIT 1];

        Test.startTest();
        List<Round_Robin_Member__c> fetched = RoundRobinUsersView.fetchRoundRobinMembers(rr.Id);
        Test.stopTest();

        System.assertEquals(2, fetched.size(), 'Should fetch 2 members');
        for (Round_Robin_Member__c member : fetched) {
            System.assertNotEquals(null, member.User_Type__c, 'User_Type__c should be populated');
            System.assertNotEquals(null, member.User__r.Name, 'User name should be populated via relationship');
        }
    }

    @isTest
    static void testFetchRoundRobinMembers_NoMembers() {
        Round_Robin__c emptyRR = new Round_Robin__c();
        insert emptyRR;

        Test.startTest();
        List<Round_Robin_Member__c> fetched = RoundRobinUsersView.fetchRoundRobinMembers(emptyRR.Id);
        Test.stopTest();

        System.assertEquals(0, fetched.size(), 'Should fetch 0 members for empty Round Robin');
    }

    @isTest
    static void testToggleMemberStatus_FromTrueToFalse() {
        Round_Robin__c rr = [SELECT Id FROM Round_Robin__c LIMIT 1];
        Round_Robin_Member__c activeMember = [SELECT Id, Active__c FROM Round_Robin_Member__c WHERE Active__c = true AND Round_Robin__c = :rr.Id LIMIT 1];
        System.assertEquals(true, activeMember.Active__c, 'Member should start as active');

        Test.startTest();
        List<Round_Robin_Member__c> updatedMembers = RoundRobinUsersView.toggleMemberStatus(activeMember.Id, rr.Id);
        Test.stopTest();

        Round_Robin_Member__c after = [SELECT Active__c FROM Round_Robin_Member__c WHERE Id = :activeMember.Id];
        System.assertEquals(false, after.Active__c, 'Active member should be toggled to inactive');
        System.assertEquals(2, updatedMembers.size(), 'Should return all members for the round robin');
    }

    @isTest
    static void testToggleMemberStatus_FromFalseToTrue() {
        Round_Robin__c rr = [SELECT Id FROM Round_Robin__c LIMIT 1];
        Round_Robin_Member__c inactiveMember = [SELECT Id, Active__c FROM Round_Robin_Member__c WHERE Active__c = false AND Round_Robin__c = :rr.Id LIMIT 1];
        System.assertEquals(false, inactiveMember.Active__c, 'Member should start as inactive');

        Test.startTest();
        List<Round_Robin_Member__c> updatedMembers = RoundRobinUsersView.toggleMemberStatus(inactiveMember.Id, rr.Id);
        Test.stopTest();

        Round_Robin_Member__c after = [SELECT Active__c FROM Round_Robin_Member__c WHERE Id = :inactiveMember.Id];
        System.assertEquals(true, after.Active__c, 'Inactive member should be toggled to active');
        System.assertEquals(2, updatedMembers.size(), 'Should return all members for the round robin');
    }

    @isTest
    static void testToggleMemberStatus_VerifyOtherMembersUnchanged() {
        Round_Robin__c rr = [SELECT Id FROM Round_Robin__c LIMIT 1];
        Round_Robin_Member__c activeMember = [SELECT Id, Active__c FROM Round_Robin_Member__c WHERE Active__c = true AND Round_Robin__c = :rr.Id LIMIT 1];
        Round_Robin_Member__c inactiveMember = [SELECT Id, Active__c FROM Round_Robin_Member__c WHERE Active__c = false AND Round_Robin__c = :rr.Id LIMIT 1];

        Test.startTest();
        RoundRobinUsersView.toggleMemberStatus(activeMember.Id, rr.Id);
        Test.stopTest();

        Round_Robin_Member__c otherMember = [SELECT Active__c FROM Round_Robin_Member__c WHERE Id = :inactiveMember.Id];
        System.assertEquals(false, otherMember.Active__c, 'Other member status should remain unchanged after toggling a different member');
    }

    @isTest
    static void testToggleMemberStatus_DoubleToggleRestoresOriginal() {
        Round_Robin__c rr = [SELECT Id FROM Round_Robin__c LIMIT 1];
        Round_Robin_Member__c member = [SELECT Id, Active__c FROM Round_Robin_Member__c WHERE Active__c = true AND Round_Robin__c = :rr.Id LIMIT 1];
        Boolean originalStatus = member.Active__c;

        Test.startTest();
        RoundRobinUsersView.toggleMemberStatus(member.Id, rr.Id);
        RoundRobinUsersView.toggleMemberStatus(member.Id, rr.Id);
        Test.stopTest();

        Round_Robin_Member__c afterDoubleToggle = [SELECT Active__c FROM Round_Robin_Member__c WHERE Id = :member.Id];
        System.assertEquals(originalStatus, afterDoubleToggle.Active__c, 'Double toggle should restore original status');
    }
}