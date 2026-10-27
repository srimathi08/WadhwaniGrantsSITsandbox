@isTest
public class WcfCoeSiteHomeTest {

    // Shared setup
    private static void createTestData(Boolean includeApps) {
        Account acc = new Account(Name = 'Test Account', Institution_Registered__c = true);
        insert acc;

        Contact c = new Contact(LastName = 'Test', AccountId = acc.Id);
        insert c;

        Profile p = [SELECT Id FROM Profile WHERE Name = 'COE User Profile' LIMIT 1];
        User u = new User(
            UserName = 'test_' + Math.random() + '@test.com',
            FirstName = 'Test-First',
            LastName = 'Test-Last',
            Alias = 'test',
            Email = 'test1wcf@test.com',
            CommunityNickName = String.valueOf(Math.random()).substring(0, 6),
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ContactId = c.Id
        );
        insert u;

        if (includeApps) {
            // Insert applications
            List<IndividualApplication> apps = new List<IndividualApplication>{
                new IndividualApplication(
                    AccountId = acc.Id,
                    ApplicationType = 'COE Proposal',
                    Status = 'Submitted',
                    Category = 'Grant Application'
                ),
                new IndividualApplication(
                    AccountId = acc.Id,
                    ApplicationType = 'WIN Project Proposal',
                    Status = 'Submitted',
                    Category = 'Grant Application'
                ),
                new IndividualApplication(
                    AccountId = acc.Id,
                    ApplicationType = 'WIN Project Proposal',
                    Status = 'Approved',
                    Category = 'Grant Application'
                )
            };
            insert apps;
        }
    }

    @isTest
    static void testGetAccountRegistrationStatus() {
        createTestData(true);
        User testUser = [SELECT Id FROM User WHERE Email = 'test1wcf@test.com' LIMIT 1];

        System.runAs(testUser) {
            Test.startTest();
            Boolean result = WcfCoeSiteHome.getAccountRegistrationStatus();
            Test.stopTest();

            System.assert(result != null, 'Expected a result from getAccountRegistrationStatus');
        }
    }

    @isTest
    static void testGetCOEProposalStatus() {
        createTestData(true);
        User testUser = [SELECT Id FROM User WHERE Email = 'test1wcf@test.com' LIMIT 1];

        System.runAs(testUser) {
            Test.startTest();
            String status = WcfCoeSiteHome.getCOEProposalStatus();
            Test.stopTest();

            System.assertEquals('Submitted', status, 'Expected COE Proposal Status to be Submitted');
        }
    }

    @isTest
    static void testGetProjectProposalSummary() {
        createTestData(true);
        User testUser = [SELECT Id FROM User WHERE Email = 'test1wcf@test.com' LIMIT 1];

        System.runAs(testUser) {
            Test.startTest();
            WcfCoeSiteHome.ProjectProposalSummary summary = WcfCoeSiteHome.getProjectProposalSummary();
            Test.stopTest();

            System.assertNotEquals(null, summary, 'Summary should not be null');
            System.assertEquals(2, summary.totalCount, 'Should be 2 WIN Project Proposals');
            System.assert(summary.statusCounts.containsKey('Submitted'), 'Should contain Submitted status');
            System.assert(summary.statusCounts.containsKey('Approved'), 'Should contain Approved status');
        }
    }

    // NEW: Test no COE Proposal present
    @isTest
    static void testGetCOEProposalStatusWhenNone() {
        createTestData(false); // no apps inserted
        User testUser = [SELECT Id FROM User WHERE Email = 'test1wcf@test.com' LIMIT 1];

        System.runAs(testUser) {
            Test.startTest();
            String status = WcfCoeSiteHome.getCOEProposalStatus();
            Test.stopTest();

            System.assertEquals(null, status, 'Expected COE Proposal Status to be null when no proposals');
        }
    }

    // NEW: Test summary when no WIN Project Proposals exist
    @isTest
    static void testGetProjectProposalSummaryNoApps() {
        createTestData(false); // no apps inserted
        User testUser = [SELECT Id FROM User WHERE Email = 'test1wcf@test.com' LIMIT 1];

        System.runAs(testUser) {
            Test.startTest();
            WcfCoeSiteHome.ProjectProposalSummary summary = WcfCoeSiteHome.getProjectProposalSummary();
            Test.stopTest();

            System.assertNotEquals(null, summary, 'Summary should not be null');
            System.assertEquals(0, summary.totalCount, 'Should be 0 WIN Project Proposals');
            System.assertEquals(0, summary.statusCounts.size(), 'No statuses should exist');
        }
    }

    // NEW: Test getAccountRegistrationStatus when Institution_Registered__c is false
    @isTest
    static void testGetAccountRegistrationStatusWhenUnregistered() {
        Account acc = new Account(Name = 'Unregistered Account', Institution_Registered__c = false);
        insert acc;

        Contact c = new Contact(LastName = 'Test', AccountId = acc.Id);
        insert c;

        Profile p = [SELECT Id FROM Profile WHERE Name = 'COE User Profile' LIMIT 1];
        User u = new User(
            UserName = 'test_' + Math.random() + '@test.com',
            FirstName = 'Test-First',
            LastName = 'Test-Last',
            Alias = 'test',
            Email = 'testUnregistered@test.com',
            CommunityNickName = String.valueOf(Math.random()).substring(0, 6),
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ContactId = c.Id
        );
        insert u;

        System.runAs(u) {
            Test.startTest();
            Boolean result = WcfCoeSiteHome.getAccountRegistrationStatus();
            Test.stopTest();

            System.assertEquals(false, result, 'Expected registration status to be false');
        }
    }
}