public without sharing class CoeHomeSectionController {

    @AuraEnabled(cacheable=true)
    public static Map<String, Integer> getPiProjectCounts() {

        Map<String, Integer> result = new Map<String, Integer>();

        User u = [
            SELECT Contact.AccountId, Contact.COE_Admin__c
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ];

        if (u.Contact == null || !u.Contact.COE_Admin__c) {
            result.put('piCount', 0);
            result.put('projectCount', 0);
            return result;
        }

        Id accId = u.Contact.AccountId;

        result.put(
            'piCount',
            [SELECT COUNT() FROM Contact WHERE AccountId = :accId AND COE_PI__c = true]
        );

        result.put(
            'projectCount',
            [SELECT COUNT() FROM IndividualApplication WHERE AccountId = :accId]
        );

        return result;
    }
}