import { LightningElement, api, wire, track } from 'lwc';
import getProposalStatus from '@salesforce/apex/ProposalPathController.getProposalStatus';

export default class ProposalPathWinComponent extends LightningElement {
    @api recordId;
    @track currentStatus;
    @track pathItems = [];

    @wire(getProposalStatus, { recordId: '$recordId' })
    wiredStatus({ data, error }) {
        if (data) {
            this.currentStatus = data;
            this.initializePath();
        } else if (error) {
            console.error(error);
        }
    }

    initializePath() {
    const status = this.currentStatus;
    let coeLabel = 'COE Admin Actions'; //Approved/Rej/Resub by 
    let winLabel = 'WIN Admin Actions'; //Approved/Rej/Resub by WIN Admin
    let recLabel = 'Decision'; //Recommended/Not Rec/Rec with Resub

    // --- COE label updates ---
    if (status === 'Proposal Approved by COE Admin') coeLabel = 'Approved by COE Admin';
    else if (status === 'Proposal Rejected by COE Admin') coeLabel = 'Not Shortlisted by COE Admin';
    else if (status === 'Asked for Resubmission by COE Admin') coeLabel = 'Ask for Revision by COE Admin';

    // --- WIN label updates ---
    if (status === 'Proposal Approved by WIN Admin' || status === 'Proposal Approved by Win Admin')
        winLabel = 'Approved by WIN Admin';
    else if (status === 'Proposal Rejected by WIN Admin' || status === 'Proposal Rejected by Win Admin')
        winLabel = 'Not Shortlisted by WIN Admin';
    else if (status === 'Asked for Resubmission by WIN Admin' || status === 'Asked for Resubmission by Win Admin')
        winLabel = 'Ask for Revision by WIN Admin';

    // --- Recommendation labels ---
    if (status === 'Recommended') recLabel = 'Recommended';
    else if (status === 'Not Recommended') recLabel = 'Not Recommended';
    else if (status === 'Recommended for Resubmission') recLabel = 'Recommended for Resubmission';

    // --- Dynamic label consistency ---
    // When submitted to WIN → COE already approved
    if (['Submitted to WIN Admin', 'Proposal Submitted to WIN Admin'].includes(status)) {
        coeLabel = 'Approved';
    }

    // When Under Review → both approved
    if (status === 'Under Review') {
        coeLabel = 'Approved';
        winLabel = 'Approved';
    }

    // ✅ When final stage (Recommended / Not Recommended / Recommended with Resubmission)
    // → COE and WIN both Approved
   // if (['Recommended', 'Not Recommended', 'Recommended with Resubmission'].includes(status)) {
    if (['Recommended', 'Not Recommended', 'Recommended with Resubmission', 'Recommended for Resubmission'].includes(status)) {

        coeLabel = 'Approved by COE Admin';
        winLabel = 'Approved by WIN Admin';
    }

    // --- Build Path ---
    this.pathItems = [
        { label: 'Draft' },
        { label: 'Submitted to COE Admin' },
        { label: coeLabel },
        { label: 'Submitted to WIN Admin' },
        { label: winLabel },
        { label: 'Under Review' },
        { label: recLabel }
    ].map((item, idx, arr) => ({
        ...item,
        isLast: idx === arr.length - 1
    }));
}


    // Determine index
    getPathStageIndex() {
        const s = this.currentStatus;
        if (!s) return 0;
        if (s === 'Draft') return 0;
        if (['Submitted to COE Admin', 'Proposal Submitted to COE Admin'].includes(s)) return 1;
        if (s.includes('COE Admin')) return 2;
        if (['Submitted to WIN Admin', 'Proposal Submitted to WIN Admin'].includes(s)) return 3;
        if (s.includes('WIN Admin')) return 4;
        if (s === 'Under Review') return 5;
        if (s.includes('Recommended')) return 6;
        return 0;
    }

    // ✅ Color logic + outline for current stage
    get computedPath() {
        const activeIndex = this.getPathStageIndex();
        const status = this.currentStatus?.toLowerCase() || '';

        return this.pathItems.map((item, index) => {
            let colorClass = 'upcoming';
            let connectorClass = 'connector-default';
            let isCompleted = false;

           /* if (index < activeIndex) {
                colorClass = 'completed';
                connectorClass = 'connector-green';
                isCompleted = true;
            } else if (index === activeIndex) {
                if (status.includes('rejected') || status === 'not recommended') {
                    colorClass = 'rejected-outline'; // red box + red outline
                } else if (status.includes('resubmission') || status.includes('resubmit')) {
                    colorClass = 'resubmit-outline'; // yellow box + yellow outline
                } else if (status.includes('approved') || status.includes('recommended')) {
                    colorClass = 'approved-outline'; // blue box + white outline
                } else {
                    colorClass = 'active'; // blue default
                }
            }*/
           if (index < activeIndex) {
    colorClass = 'completed';
    connectorClass = 'connector-green';
    isCompleted = true;
} else if (index === activeIndex) {
    if (status.includes('rejected') || status === 'not recommended') {
        colorClass = 'rejected-outline';
        connectorClass = 'connector-red';
    } else if (status.includes('resubmission') || status.includes('resubmit')) {
        colorClass = 'resubmit-outline';
        connectorClass = 'connector-yellow';
    } else if (status.includes('approved') || status.includes('recommended')) {
        colorClass = 'approved-outline';
        connectorClass = 'connector-blue';
    } else {
        colorClass = 'active';
        connectorClass = 'connector-blue';
    }
}


            return {
                ...item,
                isCompleted,
                combinedClass: `path-item ${colorClass}`,
                connectorClass
            };
        });
    }
}