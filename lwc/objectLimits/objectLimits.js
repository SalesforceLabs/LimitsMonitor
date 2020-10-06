import { LightningElement, track } from 'lwc';
import getObjectLimit from '@salesforce/apex/LimitsMonitor_Controller.getObjectLimit';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const columns = [
    { label: 'Label', fieldName: 'Label' },
    { label: 'Remaining', fieldName: 'Remaining' , type: 'number', initialWidth: 150},
    { label: 'Max', fieldName: 'Max', type : 'number', initialWidth: 70}
];

export default class ObjectLimits extends LightningElement {

    @track value = 'Account';
    @track columns = columns;
    @track objectLimits;
    

    get options() {
        return [
            { label: 'Account', value: 'Account' },
            { label: 'Contact', value: 'Contact' },
            { label: 'Case', value: 'Case' },
            { label: 'Lead', value: 'Lead' },
            { label: 'Order', value: 'Order' },
            { label: 'Campaign', value: 'Campaign' }
        ];
    }

    handleChange(event) {
        this.value = event.detail.value;
    }

    handleBtnClick(event){
        getObjectLimit({ apiName: this.value })
            .then(result => {
                this.objectLimits = result;
                if(this.objectLimits.length === 0){
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error fetching Data',
                            message: 'No Limits data could be retrieved for this object.',
                            variant: 'error',
                        }),
                    );
                }
            })
            .catch(error => {
                this.error = error;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error fetching Data',
                        message: 'No Limits data could be retrieved for this object. Please complete all installation steps.',
                        variant: 'error',
                    }),
                );
            });
    }
}