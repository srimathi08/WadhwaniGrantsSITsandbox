public with sharing class ProposalPathController {

    @AuraEnabled(cacheable=true)
    public static String getProposalStatus(Id recordId) {

        // Defensive default
        if (recordId == null) {
            return 'Draft';
        }

        /* =====================================================
           1️⃣ Reviewer check (unchanged business logic)
        ===================================================== */
        Set<Id> userIds = new Set<Id>();

        for (IndividualApplicationShare s : [
            SELECT UserOrGroupId
            FROM IndividualApplicationShare
            WHERE ParentId = :recordId
        ]) {
            // Only USER shares
            if (String.valueOf(s.UserOrGroupId).startsWith('005')) {
                userIds.add(s.UserOrGroupId);
            }
        }

        if (!userIds.isEmpty()) {
            Integer reviewerCount = [
                SELECT COUNT()
                FROM User
                WHERE Id IN :userIds
                AND Profile.Name = 'Reviewer'
                AND IsActive = true
            ];

            if (reviewerCount > 0) {
                // Business rule: reviewer assigned → under review
                return 'Under Review';
            }
        }

        /* =====================================================
           2️⃣ Status normalization (ALIGNED WITH ORG FLOW)
        ===================================================== */
        IndividualApplication app = [
            SELECT Status
            FROM IndividualApplication
            WHERE Id = :recordId
            LIMIT 1
        ];

        String s = app.Status;

        // Draft states
        if (s == 'Draft' || s == 'Revision Requested') {
            return 'Draft';
        }

        // COE submission & resubmission
        if (
            s == 'Submitted'
            || s == 'Proposal Submitted to COE Admin'
            || s == 'Proposal Resubmitted to COE Admin'
        ) {
            return 'Submitted to COE Admin';
        }

        /*
         * IMPORTANT:
         * COE approval/rejection states are transient in this org
         * and immediately auto-forwarded to WIN submission.
         * Hence they are intentionally NOT handled separately.
         */

        // WIN submission
        if (
            s == 'Proposal Submitted to WIN Admin'
            || s == 'Proposal Resubmitted to WIN Admin'
        ) {
            return 'Submitted to WIN Admin';
        }

        // WIN admin actions
        if (s.contains('WIN Admin')) {
            return 'WIN Admin Actions';
        }

        // Final decision states
        if (
            s == 'Recommended'
            || s == 'Not Recommended'
            || s == 'Recommended for Resubmission'
            || s == 'Approved for Funding'
            || s == 'Not Recommended for Funding'
            || s == 'Approved with Resubmission'
            || s == 'Submitted Back - Approved for Funding Resubmission'
        ) {
            return 'Decision';
        }

        // Absolute fallback (defensive)
        return 'Draft';
    }
}