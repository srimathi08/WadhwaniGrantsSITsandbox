public with sharing class WCFPortalUserController {

    @AuraEnabled(cacheable=true)
    public static Id getCurrentAccountId() {
        User u = [
            SELECT ContactId, Contact.AccountId
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];

        return (u.Contact != null) ? u.Contact.AccountId : null;
    }
}