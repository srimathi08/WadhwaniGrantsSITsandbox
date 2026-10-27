import { LightningElement } from 'lwc';
import getPICounts from '@salesforce/apex/PIDashboardController.getPICounts';

export default class PiProposalDashboard extends LightningElement {
    cards = [];

    connectedCallback() {
        this.loadCounts();
    }

    async loadCounts() {
        try {
            const data = await getPICounts();

            const make = (id, label, count, listViewApiName) => ({
                id,
                label,
                count: count ?? 0,
                combinedClass: 'card',
                listViewApiName
            });

            const row1 = [
                make('draft', 'Proposal in Draft', data?.Draft, 'Draft_Proposals'),
                make('submitted', 'Proposal Submitted to COE Admin', data?.SubmittedToCOE, 'Proposal_Submitted_COE_Admin'),
                make('approved', 'Proposal Approved by COE Admin', data?.ApprovedByCOE, 'Proposal_Approved_COE_Admin'),
                make('rejected', 'Proposal Not Shortlisted by COE Admin', data?.RejectedByCOE, 'Proposal_Rejected_COE_Admin')
            ];

            const row2 = [
                // ✅ FIXED
                make(
                    'revision',
                    'Proposal Asked for Resubmission by COE Admin',
                    data?.RevisionByCOE,
                    'Proposal_Resubmission_COE_Admin'
                ),

                // ✅ FIXED
                make(
                    'resubmitted',
                    'Proposal Resubmitted to COE Admin',
                    data?.ResubmittedToCOE,
                    'Proposal_Resubmitted_By_PI'
                ),

                make('subToWIN', 'Proposal Submitted to WIN Admin', data?.SubmittedToWIN, 'Proposal_Submitted_WIN_Admin'),
                make('approvedWIN', 'Proposal Approved by WIN Admin', data?.ApprovedByWIN, 'Proposal_Approved_WIN_Admin')
            ];

            const row3 = [
    make(
        'rejectedWIN',
        'Proposal Not Shortlisted by WIN Admin',
        data?.RejectedByWIN,
        'Proposal_Rejected_WIN_Admin'
    ),

    make(
        'revisionWIN',
        'Proposal Asked for Resubmission by WIN Admin',
        data?.RevisionByWIN,
        'Proposal_AskedResubmission_WIN_Admin'
    ),

    // ✅ NEW CARD ADDED
    make(
        'resubmittedWIN',
        'Proposal Resubmitted to WIN Admin',
        data?.ResubmittedToWIN,
        'Proposal_Resubmitted_WIN_Admin'
    )
];

            this.cards = [...row1, ...row2, ...row3];

        } catch (error) {
            console.error('❌ Error loading PI proposal counts:', error);
        }
    }

    handleNavigate(event) {
        const filterName = event.currentTarget.dataset.filter;
        const baseUrl = window.location.origin;

        if (filterName === 'Draft_Proposals') {
            window.open(
                '/coe/s/resumesavedraft',
                '_blank'
            );
            return;
        }

        if (baseUrl.includes('my.site.com')) {
            const sitePath = '/s/individualapplication/IndividualApplication/Default';
            window.open(
                `${baseUrl}${sitePath}?IndividualApplication-filterId=${filterName}`,
                '_blank'
            );
        } else {
            window.open(
                `/lightning/o/IndividualApplication/list?filterName=${filterName}`,
                '_blank'
            );
        }
    }
}