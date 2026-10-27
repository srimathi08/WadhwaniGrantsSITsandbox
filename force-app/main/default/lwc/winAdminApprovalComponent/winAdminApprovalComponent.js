import { LightningElement, api, track } from 'lwc';
import updateProposal from '@salesforce/apex/WinProposalApprovalController.updateProposal';
import getProposalStatus from '@salesforce/apex/WinProposalApprovalController.getProposalStatus';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class WinAdminApprovalComponent extends LightningElement {
    @api recordId;
    @track showModal = false;
    @track comments = '';
    @track actionType = '';
    @track dueDate = '';
    @track status; // 👈 fetched dynamically from Apex

    connectedCallback() {
        this.fetchStatus();
    }

    fetchStatus() {
        getProposalStatus({ recordId: this.recordId })
            .then((result) => {
                this.status = result;
                console.log('Fetched Status:', this.status);
            })
            .catch((error) => {
                console.error('Error fetching status:', error);
            });
    }

    // ✅ Enable buttons only for these statuses
    get isActionEnabled() {
        return (
            this.status === 'Proposal Submitted to WIN Admin' ||
            this.status === 'Proposal Resubmitted to WIN Admin'
        );
    }

    // ✅ Getter for disabled attribute
    get isButtonDisabled() {
        return !this.isActionEnabled;
    }

    get isResubmit() {
        return this.actionType === 'Resubmit';
    }

    handleAction(event) {
        if (this.isButtonDisabled) return;

        this.actionType = event.currentTarget.dataset.action;
        this.showModal = true; //Always show Comment Box

      /*  if (this.actionType === 'Approve') {
            this.updateStatus();
        } else {
            this.showModal = true;
        }*/
    }

    handleCommentsChange(event) {
        this.comments = event.target.value;
    }

    handleDueDateChange(event) {
        this.dueDate = event.target.value;
    }

    updateStatus() {
        let dateToSend = null;
        if (this.actionType === 'Resubmit' && this.dueDate) {
            dateToSend = this.dueDate;
        }

        updateProposal({
            recordId: this.recordId,
            actionType: this.actionType,
            comments: this.comments,
            dueDate: dateToSend
        })
            .then(() => {
                this.showModal = false;
                this.comments = '';
                this.dueDate = '';
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: `Proposal ${this.actionType}d successfully`,
                        variant: 'success'
                    })
                );
                this.fetchStatus(); // 🔁 Refresh button enable state
            })
            .catch((error) => {
                const message =
                    (error && error.body && error.body.message) ||
                    (error && error.message) ||
                    'Unknown error occurred';
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message,
                        variant: 'error'
                    })
                );
            });
    }

    closeModal() {
        this.showModal = false;
        this.comments = '';
        this.dueDate = '';
    }
}