import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getPiProjectCounts from '@salesforce/apex/CoeHomeSectionController.getPiProjectCounts';

export default class CoePiProjectSetup extends NavigationMixin(LightningElement) {

    piCount = 0;
    projectCount = 0;

    @wire(getPiProjectCounts)
    wiredCounts({ data }) {
        if (data) {
            this.piCount = data.piCount;
            this.projectCount = data.projectCount;
        }
    }

    navigateToPI() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/coe/s/pi-form'
            }
        });
    }

    navigateToProjects() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/coe/s/project-proposals'
            }
        });
    }
}