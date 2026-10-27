import { LightningElement, wire } from 'lwc';
import getReviewSummary from '@salesforce/apex/ReviewSummaryController.getReviewSummary';
//import { NavigationMixin } from 'lightning/navigation';

export default class ReviewSummary extends LightningElement{
    totalAssigned = 0;
    submitted = 0;
    draftCount = 0;
    yetToStart = 0;
    error;

    @wire(getReviewSummary)
    wiredSummary({ error, data }) {
        if (data) {
            this.totalAssigned = data.totalAssigned;
            this.submitted = data.submitted;
            this.draftCount = data.draft;
            this.yetToStart = data.yetToStart;
        } else if (error) {
            this.error = error;
        }
    }

    handleTotalClick() {
        console.log('Inside totalclick before');
        
        window.location.href = '/reviewportal/s/individualapplication/IndividualApplication/Default';
    }

    handleReviewedClick() {
        console.log('Inside reviewclick before');
        
        window.location.href = '/reviewportal/s/applicationReview/ApplicationReview/Default?ApplicationReview-filterId=Submitted_Reviews';
    }
    handleDraftClick() {
        console.log('Inside draft click');
        window.location.href = '/reviewportal/s/individualapplication/IndividualApplication/Default';
   
    }

    handleYetToStartClick() {
        console.log('Inside yettostart before click');
        
        window.location.href = '/reviewportal/s/individualapplication/IndividualApplication/Default';

    }

    
}