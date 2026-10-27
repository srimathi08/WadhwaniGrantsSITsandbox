import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getFundSummary from '@salesforce/apex/CoeHomeFundController.getFundSummary';

export default class CoeFundSummaryHome extends NavigationMixin(LightningElement) {

    // =========================
    // EXISTING
    // =========================
    totalReceived = 0;
    disbursed = 0;
    available = 0;

    // =========================
    // EXISTING (NEW CARDS)
    // =========================
    projectGrantReceived = 0;
    operationalGrantReceived = 0;

    // =========================
    // ✅ AVAILABLE (FROM APEX)
    // =========================
    availableProjectGrant = 0;
    availableOperationalGrant = 0;

    @wire(getFundSummary)
    wiredFundSummary({ data, error }) {
        console.log('getFundSummary DATA => ', JSON.stringify(data));
        console.log('getFundSummary ERROR => ', JSON.stringify(error));

        if (data) {

            // =========================
            // BASE SUMMARY
            // =========================
            this.totalReceived = data.totalReceived || 0;
            this.disbursed = data.disbursed || 0;
            this.available = data.available || 0;

            // =========================
            // RECEIVED SPLIT
            // =========================
            this.projectGrantReceived = data.projectGrantReceived || 0;
            this.operationalGrantReceived = data.operationalGrantReceived || 0;

            // =========================
            // ✅ AVAILABLE SPLIT (DO NOT RE-CALCULATE)
            // =========================
            this.availableProjectGrant = data.availableProjectGrant || 0;
            this.availableOperationalGrant = data.availableOperationalGrant || 0;

        } else if (error) {
            console.error('Apex Error => ', error);
        }
    }

    navigateToFund() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/coe/s/fund-management'
            }
        });
    }
}