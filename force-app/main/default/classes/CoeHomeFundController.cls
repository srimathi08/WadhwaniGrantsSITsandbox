public without sharing class CoeHomeFundController {

    @AuraEnabled(cacheable=true)
    public static Map<String, Decimal> getFundSummary() {

        Map<String, Decimal> result = new Map<String, Decimal>{
            // =========================
            // EXISTING KEYS (UNCHANGED)
            // =========================
            'total' => 0,
            'disbursed' => 0,
            'available' => 0,

            // =========================
            // EXISTING NEW KEYS
            // =========================
            'projectGrantReceived' => 0,
            'operationalGrantReceived' => 0,
            'totalReceived' => 0,

            // =========================
            // 🔹 ADD-ONLY (NEW)
            // =========================
            'availableProjectGrant' => 0,
            'availableOperationalGrant' => 0
        };

        /* ---------------- Logged-in User ---------------- */
        User u = [
            SELECT ContactId, Contact.AccountId
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];

        // Portal safe
        if (u.ContactId == null || u.Contact == null || u.Contact.AccountId == null) {
            return result;
        }

        Id accId = u.Contact.AccountId;

        /* =========================================================
           TOTAL RECEIVED (EXISTING LOGIC – UNCHANGED)
        ========================================================= */
        AggregateResult arTotal = [
            SELECT SUM(Amount) total
            FROM FundingAward
            WHERE AwardeeId = :accId
        ];

        Decimal total = (Decimal) arTotal.get('total');
        if (total == null) total = 0;

        /* =========================================================
           FUND TYPE WISE RECEIVED (EXISTING – ADD ONLY)
        ========================================================= */
        Decimal projectGrantReceived = 0;
        Decimal operationalGrantReceived = 0;

        for (AggregateResult ar : [
            SELECT Type_of_Fund__c fundType, SUM(Amount) total
            FROM FundingAward
            WHERE AwardeeId = :accId
            GROUP BY Type_of_Fund__c
        ]) {
            Decimal amt = (Decimal) ar.get('total');
            if (amt == null) amt = 0;

            String fundType = (String) ar.get('fundType');

            if (fundType == 'COE Project Grant') {
                projectGrantReceived += amt;
            } else if (fundType == 'COE Operational Grant') {
                operationalGrantReceived += amt;
            }
        }

        /* =========================================================
           DISBURSED (EXISTING LOGIC – UNCHANGED)
           NOTE: ALL disbursements are from PROJECT GRANT ONLY
        ========================================================= */
        Decimal disbursed = 0;

        List<IndividualApplication> apps = [
            SELECT Id
            FROM IndividualApplication
            WHERE Status = 'Approved for Funding'
            AND AccountId = :accId
        ];

        if (!apps.isEmpty()) {
            Set<Id> appIds = new Set<Id>();
            for (IndividualApplication ia : apps) {
                appIds.add(ia.Id);
            }

            AggregateResult arDisb = [
                SELECT SUM(Amount) total
                FROM FundingDisbursement
                WHERE Proposal__c IN :appIds
            ];

            disbursed = (Decimal) arDisb.get('total');
            if (disbursed == null) disbursed = 0;
        }

        /* =========================================================
           EXISTING RESPONSE VALUES (UNCHANGED)
        ========================================================= */
        result.put('total', total);
        result.put('disbursed', disbursed);
        result.put('available', total - disbursed);

        /* =========================================================
           NEW RESPONSE VALUES (ALIGNED WITH CoeFundController)
        ========================================================= */
        result.put('projectGrantReceived', projectGrantReceived);
        result.put('operationalGrantReceived', operationalGrantReceived);
        result.put('totalReceived', projectGrantReceived + operationalGrantReceived);

        // ✅ Correct availability split
        Decimal availableProjectGrant = projectGrantReceived - disbursed;
        if (availableProjectGrant < 0) {
            availableProjectGrant = 0;
        }

        result.put('availableProjectGrant', availableProjectGrant);
        result.put('availableOperationalGrant', operationalGrantReceived);

        return result;
    }
}