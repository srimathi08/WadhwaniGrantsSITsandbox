public without sharing class WcfCoeSiteHome {
    @AuraEnabled(cacheable=true)
    public static Boolean getAccountRegistrationStatus() {
        System.debug('--- getAccountRegistrationStatus START ---');
        try {
            User currentUser = [SELECT Contact.AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            System.debug('Current User: ' + currentUser);
            System.debug('Current User Contact Account ID: ' + currentUser?.Contact?.AccountId);
            if (currentUser.Contact?.AccountId != null) {
                Account acc = [
                    SELECT Institution_Registered__c
                    FROM Account
                    WHERE Id = :currentUser.Contact.AccountId
                    LIMIT 1
                ];
                System.debug('Retrieved Account: ' + acc);
                System.debug('Account Institution_Registered__c: ' + acc.Institution_Registered__c);
                return acc.Institution_Registered__c;
            } else {
                System.debug('Current User does not have a Contact or Account ID.');
            }
        } catch (Exception e) {
            System.debug('Error fetching account registration status: ' + e.getMessage());
        }
        System.debug('--- getAccountRegistrationStatus END (returning false by default) ---');
        return false; // Default to false if anything fails
    }

    @AuraEnabled(cacheable=true)
    public static String getCOEProposalStatus() {
        System.debug('--- getCOEProposalStatus START ---');
        try {
            User currentUser = [SELECT Contact.AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            System.debug('Current User Account ID for COE Proposal Status: ' + currentUser?.Contact?.AccountId); // Debug
            if (currentUser.Contact?.AccountId != null) {
                List<IndividualApplication> proposals = [
                    SELECT Status
                    FROM IndividualApplication
                    WHERE AccountId = :currentUser.Contact.AccountId
                    AND ApplicationType = 'COE Proposal'
                    LIMIT 1
                ];
                System.debug('Number of COE Proposal records found: ' + proposals.size()); // Debug
                if (!proposals.isEmpty()) {
                    System.debug('COE Proposal Status from DB: ' + proposals[0].Status); // Debug
                    System.debug('--- getCOEProposalStatus END (returning status: ' + proposals[0].Status + ') ---');
                    return proposals[0].Status;
                } else {
                    System.debug('No COE Proposal found for Account ID: ' + currentUser.Contact.AccountId);
                }
            } else {
                System.debug('Current User does not have a Contact or Account ID for COE Proposal.');
            }
        } catch (Exception e) {
            System.debug('Error fetching COE Proposal status: ' + e.getMessage());
        }
        System.debug('--- getCOEProposalStatus END (returning null by default) ---');
        return null; // Returns null if no COE Proposal found or an error occurs
    }

    @AuraEnabled(cacheable=true)
    public static ProjectProposalSummary getProjectProposalSummary() {
        System.debug('--- getProjectProposalSummary START ---');
        ProjectProposalSummary summary = new ProjectProposalSummary();
        try {
            User currentUser = [SELECT Contact.AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            System.debug('Current User Account ID for Project Proposal Summary: ' + currentUser?.Contact?.AccountId);
            if (currentUser.Contact?.AccountId != null) {
                List<AggregateResult> results = [
                    SELECT Status, COUNT(Id)
                    FROM IndividualApplication
                    WHERE AccountId = :currentUser.Contact.AccountId
                    AND ApplicationType = 'WIN Project Proposal'
                    GROUP BY Status
                ];

                summary.totalCount = [SELECT COUNT() FROM IndividualApplication WHERE AccountId = :currentUser.Contact.AccountId AND ApplicationType = 'WIN Project Proposal'];
                summary.statusCounts = new Map<String, Integer>();
                System.debug('Total WIN Project Proposals: ' + summary.totalCount);
                for (AggregateResult ar : results) {
                    String status = (String) ar.get('Status');
                    Integer count = (Integer) ar.get('expr0');
                    summary.statusCounts.put(status, count);
                    System.debug('WIN Project Proposal status: ' + status + ' count: ' + count);
                }
            } else {
                summary.totalCount = 0;
                summary.statusCounts = new Map<String, Integer>();
                System.debug('Current User does not have a Contact or Account ID for Project Proposal Summary.');
            }
        } catch (Exception e) {
            System.debug('Error fetching Project Proposal summary: ' + e.getMessage());
            summary.totalCount = 0;
            summary.statusCounts = new Map<String, Integer>();
        }
        System.debug('--- getProjectProposalSummary END (returning summary) ---');
        return summary;
    }

    public class ProjectProposalSummary {
        @AuraEnabled
        public Integer totalCount { get; set; }
        @AuraEnabled
        public Map<String, Integer> statusCounts { get; set; }
    }
}