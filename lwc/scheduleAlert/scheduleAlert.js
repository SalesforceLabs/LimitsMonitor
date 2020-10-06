import { LightningElement } from 'lwc';
import scheduleAlert from '@salesforce/apex/LimitsMonitor_Controller.scheduleAlert';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ScheduleAlert extends LightningElement {

    handleSchedule(event){
        var timeVal = this.template.querySelector(".timeVal");
        var percentVal = this.template.querySelector(".percentVal");

        if(!timeVal.value){
            timeVal.setCustomValidity("Value is required");
            timeVal.reportValidity();
            return;
        }
        if(!percentVal.value){
            percentVal.setCustomValidity("Value is required");
            percentVal.reportValidity();
            return;
        }
        
        scheduleAlert({ percent: percentVal.value, schedTime: timeVal.value})
            .then(result => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Scheduled Job Successfully Created',
                        variant: 'success',
                    }),
                );
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please remove the existing Scheduled Job before Scheduling',
                        variant: 'error',
                    }),
                );
            });
          
    }

}