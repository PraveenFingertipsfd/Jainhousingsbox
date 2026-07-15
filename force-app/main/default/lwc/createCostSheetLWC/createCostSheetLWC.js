import { LightningElement, api,track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import getUnitDetailsFromBookingRequest from '@salesforce/apex/CostSheetController.getUnitDetailsFromBookingRequest';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CreateCostSheetLWC extends LightningElement {

    @api recordId; // This will automatically get the record ID when placed on a record page
    
    @track showSpinner = false;
    @track oppPlot = {};
    // Booking Request ID passed automatically
    @api objectApiName; // Object API name passed automatically
    
    currentStep = 'details';
    
    // Options
    parkingOption = '';
    isSingleCheckboxChecked = false;
    gstAggrementOption = '';
    isGSTChecked = false;
    gstOtherOption = '';
    isgstonOtherChecked = false;
    ismultiplequotes = false;
    // Payment schedule
    paymentType = 'Standard';
    paymentSchedules = [];
     
    rendered = false;

renderedCallback() {
    if (this.rendered) return;
    this.rendered = true;
    alert(this.recordId);
    console.log('RecordId in renderedCallback:', this.recordId);
    if (this.recordId) {
        this.loadUnitDetails();
    } else {
        this.showToast('Error', 'No booking request ID found', 'error');
    }
}
    get isDetailsStep() {
        return this.currentStep === 'details';
    }
    loadUnitDetails() {
        this.showSpinner = true;
        getUnitDetailsFromBookingRequest({ 
            bookingRequestId: this.recordId 
        })
        .then(result => {
            if (result) {
                this.oppPlot = {
                    ...this.oppPlot,
                    Unit__c: result.Id,
                    BHK_Type__c: result.BHK_Type__c,
                    Project__c: result.Project__c,
                    Carpet_Area__c: result.Carpet_Area__c,
                    Balcony_Area__c: result.Balcony_Area__c,
                    Price_Per_Sq_Ft__c: result.Price_Per_Sq_Ft__c,
                    // Add other fields as needed
                };
                this.showSpinner = false;
                this.checkMultipleQuotes();
            } else {
                throw new Error('No unit details found');
            }
        })
        .catch(error => {
            this.showSpinner = false;
            this.showError(error);
        });
    }

    showError(error) {
        console.error('Error:', error);
        this.showToast('Error', error.body?.message || error.message || 'An error occurred', 'error');
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant
        }));
    }
}