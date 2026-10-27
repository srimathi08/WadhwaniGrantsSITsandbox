import { LightningElement, track, wire } from 'lwc';
import getAccountRegistrationStatus from '@salesforce/apex/WcfCoeSiteHome.getAccountRegistrationStatus';
import getCOEProposalStatus from '@salesforce/apex/WcfCoeSiteHome.getCOEProposalStatus';
import getProjectProposalSummary from '@salesforce/apex/WcfCoeSiteHome.getProjectProposalSummary';
import { refreshApex } from '@salesforce/apex';

export default class Coepath extends LightningElement {
    // STEP 1
    @track registrationCompleted = false;
    @track registrationStatusText = 'Yet to Start';
    @track registrationStatusIcon = '🕒';
    @track showStep1Link = false;

    // STEP 2
    @track coeProposalStatus = 'Yet to Start';
    @track showStep2Link = false;

    // STEP 3
    @track showStep3Links = false;

    // URLs
    //coeProposalLink = 'https://wadhwanifoundation--wfdev.sandbox.my.site.com/WadhwaniOrg/s/proposal-submission-page';
    coeProposalLink = '/coe/s/proposal-submission-page';
    
    //projectProposalListUrl = 'https://wadhwanifoundation--wfdev.sandbox.my.site.com/WadhwaniOrg/s/individualapplication/IndividualApplication/Default';
    projectProposalListUrl = '/coe/s/individualapplication/IndividualApplication/Default';

    // STEP 1: COE Registration
    @wire(getAccountRegistrationStatus)
    wiredRegistration({ data, error }) {
        if (data !== undefined) {
            this.registrationCompleted = data;
            this.registrationStatusText = data ? 'Completed' : 'Yet to Start';
            this.registrationStatusIcon = data ? '✅' : '🕒';

            // Show link only when status = Yet to Start
            this.showStep1Link = !data;
        } else if (error) {
            console.error('Error fetching registration status:', error);
        }
    }

    // STEP 2: COE Proposal
  /*  @wire(getCOEProposalStatus)
    wiredProposal({ data, error }) {
        if (data !== undefined) {
            this.coeProposalStatus = data || 'Yet to Start';

            // Show link only when status = Yet to Start
            this.showStep2Link = this.coeProposalStatus === 'Yet to Start';

            // Show Step 3 only when Step 2 = Approved
            this.showStep3Links = this.coeProposalStatus === 'Approved';
        } else if (error) {
            console.error('Error fetching COE Proposal status:', error);
        }
    }*/
   // STEP 2: COE Proposal
@wire(getCOEProposalStatus)
wiredProposal({ data, error }) {
    if (data !== undefined) {
        this.coeProposalStatus = data || 'Yet to Start';

        // ✅ Step 2 link should appear ONLY when Step 1 is completed
        // and Step 2 is not yet completed/approved
        this.showStep2Link =
            this.registrationCompleted &&
            (this.coeProposalStatus === 'Yet to Start' ||
             this.coeProposalStatus === 'In Progress');

        // ✅ Step 3 links appear only when Step 2 is approved
        this.showStep3Links = this.coeProposalStatus === 'Approved';
    } else if (error) {
        console.error('Error fetching COE Proposal status:', error);
    }
}


    // Optional (if you need project stats refresh logic)
    @wire(getProjectProposalSummary)
    wiredProjectProposals;
}