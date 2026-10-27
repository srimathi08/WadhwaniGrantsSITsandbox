import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getTotalAssignedApplications
    from '@salesforce/apex/AssignedProposalsController.getTotalAssignedApplications';

import rejectProposal
    from '@salesforce/apex/AssignedProposalsController.rejectProposal';

export default class AssignedProposals extends LightningElement {

    @track applications = [];
    @track error;

    isLoading = true;

    // Reject modal state
    isRejectModalOpen = false;
    rejectComment = '';
    selectedApplicationId;

    /* =====================================================
       LOAD ASSIGNED APPLICATIONS
       ===================================================== */
    @wire(getTotalAssignedApplications)
    wiredApplications({ error, data }) {
        this.isLoading = false;

        if (data) {
            this.applications = data.map((row, index) => ({
                applicationId: row.applicationId,
                index: index + 1,

                applicationName: row.applicationName,
                projectTitle: row.projectTitle,
                primaryFocusArea: row.primaryFocusArea,
                coeName: row.coeName,

                reviewerAction: row.reviewerAction,
                isActionDisabled: row.isActionDisabled,

                reviewerActionClass:
                    row.reviewerAction === 'Rejected'
                        ? 'status-rejected'
                        : row.reviewerAction === 'Accepted'
                        ? 'status-accepted'
                        : 'status-pending',

                recordUrl: `/reviewportal/s/individualapplication/${row.applicationId}`
            }));

            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.applications = [];
        }
    }

    /* =====================================================
       ACCEPT (SAFE: redirect only)
       ===================================================== */
    handleAccept(event) {
        const applicationId = event.currentTarget.dataset.id;
        window.location.href =
            `/reviewportal/s/individualapplication/${applicationId}`;
    }

    /* =====================================================
       REJECT (OPEN MODAL)
       ===================================================== */
    handleReject(event) {
        this.selectedApplicationId = event.currentTarget.dataset.id;
        this.rejectComment = '';
        this.isRejectModalOpen = true;
    }

    handleCommentChange(event) {
        this.rejectComment = event.target.value;
    }

    closeRejectModal() {
        this.isRejectModalOpen = false;
        this.selectedApplicationId = null;
        this.rejectComment = '';
    }

    /* =====================================================
       CONFIRM REJECT
       ===================================================== */
    confirmReject() {

        if (!this.rejectComment || !this.rejectComment.trim()) {
            this.showToast(
                'Validation Error',
                'Please enter a rejection comment.',
                'error'
            );
            return;
        }

        this.isLoading = true;

        rejectProposal({
            applicationId: this.selectedApplicationId,
            reviewerComment: this.rejectComment
        })
        .then(() => {
            this.showToast(
                'Rejected',
                'Proposal has been rejected successfully.',
                'success'
            );

            // Close modal and refresh UI
            this.closeRejectModal();

            // Force refresh so buttons get disabled immediately
            return getTotalAssignedApplications();
        })
        .then(data => {
            this.applications = data.map((row, index) => ({
                applicationId: row.applicationId,
                index: index + 1,

                applicationName: row.applicationName,
                projectTitle: row.projectTitle,
                primaryFocusArea: row.primaryFocusArea,
                coeName: row.coeName,

                reviewerAction: row.reviewerAction,
                isActionDisabled: row.isActionDisabled,

                reviewerActionClass:
                    row.reviewerAction === 'Rejected'
                        ? 'status-rejected'
                        : row.reviewerAction === 'Accepted'
                        ? 'status-accepted'
                        : 'status-pending',

                recordUrl: `/reviewportal/s/individualapplication/${row.applicationId}`
            }));
        })
        .catch(error => {
            this.showToast(
                'Error',
                error?.body?.message || 'Error rejecting proposal',
                'error'
            );
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    /* =====================================================
       HELPERS
       ===================================================== */
    get hasData() {
        return this.applications && this.applications.length > 0;
    }

    get errorMessage() {
        return this.error?.body?.message || 'Unknown error occurred';
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}