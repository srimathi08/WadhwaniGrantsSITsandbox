public without sharing class ProposalDashboardController {
    @AuraEnabled
    public static Map<String, Integer> getProposalCounts() {
        Map<String, Integer> counts = new Map<String, Integer>{
            'SubmittedToCOE' => 0,
            'ApprovedByCOE' => 0,
            'RejectedByCOE' => 0,
            'ResubmissionByCOE' => 0,
            'ResubmittedByPI' => 0,
            'SubmittedToWIN' => 0,
            'ApprovedByWIN' => 0,
            'RejectedByWIN' => 0,
            'AskedResubmissionWIN' => 0,
            'ResubmittedToWIN' => 0,
            'ApprovedForFunding' => 0,
            'NotRecommendedFunding' => 0
        };

        try {
            User currentUser = [
                SELECT Contact.AccountId 
                FROM User 
                WHERE Id = :UserInfo.getUserId() 
                LIMIT 1
            ];
            Id accountId = currentUser?.Contact?.AccountId;

            if (accountId != null) {
                List<AggregateResult> results = [
                    SELECT Status, COUNT(Id) total
                    FROM IndividualApplication
                    WHERE AccountId = :accountId
                    AND ApplicationType = 'WIN Project Proposal'
                    AND Status IN (
                        'Proposal Submitted to COE Admin',
                        'Proposal Approved by COE Admin',
                        'Proposal Rejected by COE Admin',
                        'Asked for Resubmission by COE Admin',
                        'Proposal Resubmitted to COE Admin',
                        'Proposal Submitted to WIN Admin',
                        'Proposal Approved by WIN Admin',
                        'Proposal Rejected by WIN Admin',
                        'Asked for Resubmission by WIN Admin',
                        'Proposal Resubmitted to WIN Admin',
                        'Approved for Funding',
                        'Not Recommended for Funding'
                    )
                    GROUP BY Status
                ];

                for (AggregateResult ar : results) {
                    String status = (String) ar.get('Status');
                    Integer total = (Integer) ar.get('total');
                    if (status == 'Proposal Submitted to COE Admin')
                        counts.put('SubmittedToCOE', total);
                    else if (status == 'Proposal Approved by COE Admin')
                        counts.put('ApprovedByCOE', total);
                    else if (status == 'Proposal Rejected by COE Admin')
                        counts.put('RejectedByCOE', total);
                    else if (status == 'Asked for Resubmission by COE Admin')
                        counts.put('ResubmissionByCOE', total);
                    else if (status == 'Proposal Resubmitted to COE Admin')
                        counts.put('ResubmittedByPI', total);
                    else if (status == 'Proposal Submitted to WIN Admin')
                        counts.put('SubmittedToWIN', total);
                    else if (status == 'Proposal Approved by WIN Admin')
                        counts.put('ApprovedByWIN', total);
                    else if (status == 'Proposal Rejected by WIN Admin')
                        counts.put('RejectedByWIN', total);
                    else if (status == 'Asked for Resubmission by WIN Admin')
                        counts.put('AskedResubmissionWIN', total);
                    else if (status == 'Proposal Resubmitted to WIN Admin')
                        counts.put('ResubmittedToWIN', total);
                    else if (status == 'Approved for Funding')
                        counts.put('ApprovedForFunding', total);
                    else if (status == 'Not Recommended for Funding')
                        counts.put('NotRecommendedFunding', total);
                }
            }
        } catch (Exception e) {
            System.debug('Error in getProposalCounts: ' + e.getMessage());
        }
        return counts;
    }
}