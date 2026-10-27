public without sharing class ProposalReviewController {

    /* =====================================================
       WRAPPERS
    ===================================================== */
    public class ProposalWrapper {
        @AuraEnabled public Id proposalId;
        @AuraEnabled public String proposalName;
        @AuraEnabled public String projectTitle;
        @AuraEnabled public String primaryFocusArea;
        @AuraEnabled public List<ReviewWrapper> reviews;
        @AuraEnabled public Boolean disableApprove;
        @AuraEnabled public Boolean decisionTaken;
        @AuraEnabled public String finalDecision;
    }

    public class ReviewWrapper {
        @AuraEnabled public String reviewerName;
        @AuraEnabled public String reviewStatus;
        @AuraEnabled public String reviewStatusClass;
    }

    /* =====================================================
       FETCH COE ACCOUNTS (Dropdown)
    ===================================================== */
    @AuraEnabled(cacheable=true)
    public static List<Account> getCOEAccounts() {

        Id coeRtId = Schema.SObjectType.Account
            .getRecordTypeInfosByName()
            .get('COE')
            .getRecordTypeId();

        return [
            SELECT Id, Name
            FROM Account
            WHERE RecordTypeId = :coeRtId
            AND IsDeleted = false
            ORDER BY Name ASC
        ];
    }

    /* =====================================================
       FETCH PROJECT PROPOSALS
    ===================================================== */
    @AuraEnabled(cacheable=true)
    public static List<ProposalWrapper> getSubmittedProposals(Id coeId) {

        Id rtId = Schema.SObjectType.IndividualApplication
            .getRecordTypeInfosByName()
            .get('Project Proposal')
            .getRecordTypeId();

        /* -------------------------------------------
           Get Shares (Project Proposal only)
        ------------------------------------------- */
        List<IndividualApplicationShare> shares = [
            SELECT ParentId, UserOrGroupId
            FROM IndividualApplicationShare
            WHERE Parent.RecordTypeId = :rtId
        ];

        if (shares.isEmpty()) return new List<ProposalWrapper>();

        Set<Id> proposalIds   = new Set<Id>();
        Set<Id> sharedUserIds = new Set<Id>();

        for (IndividualApplicationShare s : shares) {
            if (String.valueOf(s.UserOrGroupId).startsWith('005')) {
                proposalIds.add(s.ParentId);
                sharedUserIds.add(s.UserOrGroupId);
            }
        }

        if (proposalIds.isEmpty()) return new List<ProposalWrapper>();

        /* -------------------------------------------
           Only Valid Reviewers (Profile Based)
        ------------------------------------------- */
        Map<Id, User> reviewerMap = new Map<Id, User>([
            SELECT Id, Name, ContactId, Contact.Name
            FROM User
            WHERE Id IN :sharedUserIds
            AND Profile.Name = 'Reviewer'
            AND IsActive = true
        ]);

        if (reviewerMap.isEmpty()) return new List<ProposalWrapper>();

        /* -------------------------------------------
           Fetch Proposals (with optional COE filter)
        ------------------------------------------- */
        List<IndividualApplication> proposalList;

        if (coeId != null) {
            proposalList = [
                SELECT Id,
                       Name,
                       Status,
                       Project_Title__c,
                       Primary_Focus_Area__c
                FROM IndividualApplication
                WHERE Id IN :proposalIds
                AND RecordTypeId = :rtId
                AND AccountId = :coeId
            ];
        } else {
            proposalList = [
                SELECT Id,
                       Name,
                       Status,
                       Project_Title__c,
                       Primary_Focus_Area__c
                FROM IndividualApplication
                WHERE Id IN :proposalIds
                AND RecordTypeId = :rtId
            ];
        }

        Map<Id, IndividualApplication> proposalMap =
            new Map<Id, IndividualApplication>(proposalList);

        if (proposalMap.isEmpty()) return new List<ProposalWrapper>();

        /* -------------------------------------------
           Latest Review per Reviewer per Proposal
        ------------------------------------------- */
        Map<String, ApplicationReview> reviewMap =
            new Map<String, ApplicationReview>();

        for (ApplicationReview ar : [
            SELECT ApplicationId,
                   ReviewedById,
                   Final_recommendation_ExternalReviewer__c,
                   CreatedDate
            FROM ApplicationReview
            WHERE ApplicationId IN :proposalMap.keySet()
            ORDER BY CreatedDate DESC
        ]) {
            String key = ar.ReviewedById + '-' + ar.ApplicationId;
            if (!reviewMap.containsKey(key)) {
                reviewMap.put(key, ar);
            }
        }

        /* -------------------------------------------
           Build Result
        ------------------------------------------- */
        Map<Id, ProposalWrapper> resultMap = new Map<Id, ProposalWrapper>();

        for (IndividualApplicationShare s : shares) {

            Id proposalId = s.ParentId;
            Id reviewerId = s.UserOrGroupId;

            if (!proposalMap.containsKey(proposalId)) continue;
            if (!reviewerMap.containsKey(reviewerId)) continue;

            if (!resultMap.containsKey(proposalId)) {

                IndividualApplication app = proposalMap.get(proposalId);

                ProposalWrapper pw      = new ProposalWrapper();
                pw.proposalId           = app.Id;
                pw.proposalName         = app.Name;
                pw.projectTitle         = app.Project_Title__c;
                pw.primaryFocusArea     = app.Primary_Focus_Area__c;
                pw.reviews              = new List<ReviewWrapper>();
                pw.disableApprove       = false;

                pw.decisionTaken =
                    app.Status == 'Approved - Level 1' ||
                    app.Status == 'Rejected - Level 1';

                pw.finalDecision = app.Status;

                resultMap.put(proposalId, pw);
            }

            ProposalWrapper pw = resultMap.get(proposalId);
            ReviewWrapper rw   = new ReviewWrapper();

            User u          = reviewerMap.get(reviewerId);
            rw.reviewerName = u.ContactId != null ? u.Contact.Name : u.Name;

            String key = reviewerId + '-' + proposalId;

            String recommendation = reviewMap.containsKey(key)
                ? reviewMap.get(key).Final_recommendation_ExternalReviewer__c
                : null;

            rw.reviewStatus = recommendation;

            if (recommendation == 'Recommended for Funding') {
                rw.reviewStatusClass = 'status-recommended';
            } else if (recommendation == 'Not Recommended for Funding') {
                rw.reviewStatusClass = 'status-rejected';
            } else {
                rw.reviewStatusClass = '';
                pw.disableApprove    = true;
            }

            pw.reviews.add(rw);
        }

        return resultMap.values();
    }

    /* =====================================================
       UPDATE STATUS (WIN ADMIN ACTION)
    ===================================================== */
    @AuraEnabled
    public static void updateProposalStatus(
        Id     proposalId,
        String actionType,
        String comments
    ) {

        IndividualApplication app = [
            SELECT Id, Status, Coe_Approver__c
            FROM IndividualApplication
            WHERE Id = :proposalId
            LIMIT 1
        ];

        if (app.Status == 'Approved - Level 1' ||
            app.Status == 'Rejected - Level 1') {
            return; // prevent double action
        }

        String historyStatus;
        String historyNamePrefix;

        if (actionType == 'approve') {
            app.Status        = 'Approved - Level 1';
            historyStatus     = 'Approved';
            historyNamePrefix = 'Approved by ';
        } else if (actionType == 'reject') {
            app.Status        = 'Rejected - Level 1';
            historyStatus     = 'Rejected';
            historyNamePrefix = 'Rejected by ';
        }

        update app;

        /* -------------------------------------------
           Insert Approval History (with Comments)
        ------------------------------------------- */
        Approval_History__c history = new Approval_History__c(
            Name           = historyNamePrefix + UserInfo.getName(),
            Status__c      = historyStatus,
            Assigned_To__c = UserInfo.getUserId(),
            Proposal__c    = proposalId,
            Comments__c    = comments
        );
        insert history;

        /* -------------------------------------------
           Share Approval History with COE Approver
        ------------------------------------------- */
        if (app.Coe_Approver__c != null) {
            try {
                Approval_History__Share sh = new Approval_History__Share();
                sh.ParentId       = history.Id;
                sh.UserOrGroupId  = app.Coe_Approver__c;
                sh.AccessLevel    = 'Read';
                sh.RowCause       = Schema.Approval_History__Share.RowCause.Manual;
                insert sh;
            } catch (Exception e) {
                System.debug('Sharing error: ' + e.getMessage());
            }
        }
    }
}