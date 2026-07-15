import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import insertQuote from '@salesforce/apex/CostSheetController.insertQuote';
import getUnitFromBooking from '@salesforce/apex/CostSheetController.getUnitFromBooking';
import getPaymentSchedules from '@salesforce/apex/CostSheetController.getPaymentSchedules';
import insertSchedules from '@salesforce/apex/CostSheetController.insertSchedules';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CreateCostSheetFromBRLWC extends NavigationMixin(LightningElement) {
    @track oppPlot = {};
    @track quote = {};
    showSpinner = true;
    isDetailsStep = true;
    isPaymentStep = false;

    @track carParkingOption = '';
    @track carParkingValue = null;
    @track showCarParkingValue = false;

    @track discountAmount;
    @track blockedPrice = 0;
    

    @track paymentType = 'Standard';
    @track paymentScheduleList = [];         // for Standard
    @track customPaymentScheduleList = [];   // for Custom
    originalPaymentScheduleList = [];        // NEW: frozen baseline for diffing
    @track totalScheduleAmount = 0;

    @track additionalParkingRequired = 'No';

    gstAggrementOption = '';
    error;

    get isDiscountDisabled() {
        return this.blockedPrice !== 0;
    }

    get carParkingOptions() {
        return [
            { label: 'None', value: '' },
            { label: 'Stilt', value: 'Stilt' },
            { label: 'Basement', value: 'Basement' },
            { label: '1st Level', value: '1st Level' },
            { label: '2nd Level', value: '2nd Level' }
        ];
    }

    get paymentTypeOptions() {
        return [
            { label: 'Standard', value: 'Standard' },
            { label: 'Custom', value: 'Custom' }
        ];
    }

    get isStandardPayment() {
        return this.paymentType === 'Standard';
    }

    get isCustomPayment() {
        return this.paymentType === 'Custom';
    }

    get additionalParkingOptions() {
        return [
            { label: 'Yes', value: 'Yes' },
            { label: 'No', value: 'No' }
        ];
    }

    get statusOptions() {
        return [
            { label: 'Scheduled', value: 'Scheduled' },
            { label: 'Demanded', value: 'Demanded' },
            { label: 'Paid', value: 'Paid' }
        ];
    }

    

    _recordId;
    @api currentRecId;
    @api preferredUnitId;

    @api set recordId(value) {
        this._recordId = value;
        if (value) {
            this.fetchUnitData(value);
        }
    }

    get recordId() {
        return this._recordId;
    }

    connectedCallback() {
        if (this.currentRecId) {
            this.recordId = this.currentRecId;
            this.fetchUnitData(this.currentRecId);
        }
    }

    /*fetchUnitData(value) {
        getUnitFromBooking({ bookingId: value, unitId: this.preferredUnitId })
            .then(data => {
                this.oppPlot = {
                    Booking_Request__c: this.recordId,
                    Name: data.Name,
                    Project__c: data.Project__c,
                    Project__r: data.Project__r || {},
                    Carpet_Area__c: data.Carpet_Area_in_Sq_ft__c ?? 0,
                    Super_Built_Up_Area__c: data.Super_Built_Up_Area_in_Sq_ft__c ?? 0,
                    Balcony_Area__c: data.Balcony_Area__c ?? 0,
                    Price_Per_Sq_Ft__c: data.Price_Per_Sq_Ft__c ?? 0,
                    BHK_Type__c: data.BHK_Type__c ?? 0,
                    Floor__c: data.Floor__c ?? 0,
                    Corpus_Fund__c: data.Corpus_Fund__c ?? 0,
                    Maintenance_Charge__c: data.Total_Maintenance_Charge__c ?? 0,
                    GST_For_Other_Charges__c: data.GST_For_Other_Charges__c ?? 0,
                    GST__c: data.GST1__c ?? 0,
                    Open_Terrace_Area__c: data.Terrace_Area__c ?? 0,
                    Unit__c: data.Id
                };

                this.quote = {
                    ...this.oppPlot,
                    Booking_Request__c: this.recordId
                };

                this.showSpinner = false;
            })
            .catch(error => {
                console.error(error);
                this.error = error;
                this.showSpinner = false;
            });
    }*/

    fetchUnitData(value) {
        getUnitFromBooking({ bookingId: value, unitId: this.preferredUnitId })
            .then(data => {
                const plot = data.plot;
                this.blockedPrice = data.blockedPrice ?? 0;

                // Store all project parking charges dynamically
            this.projectCharges = {
                Stilt: plot.Project__r?.Stilt_Parking_Charges__c || 0,
                Basement: plot.Project__r?.Basement_Parking_Charges__c || 0,
                '1st Level': plot.Project__r?.First_Level_Parking_Charges__c || 0,
                '2nd Level': plot.Project__r?.Second_Level_Parking_Charges__c || 0
            };

            console.log('Project Parking Charges:', this.projectCharges);

                this.oppPlot = {
                    Booking_Request__c: this.recordId,
                    Name: plot.Name,
                    Project__c: plot.Project__c,
                    Project__r: plot.Project__r || {},
                    Carpet_Area__c: plot.Carpet_Area__c ?? 0,
                    Super_Built_Up_Area__c: plot.Super_built_up_area__c ?? 0,
                    Balcony_Area__c: plot.Balcony_Area__c ?? 0,
                    Price_Per_Sq_Ft__c: plot.Price_Per_Sq_Ft__c ?? 0,
                    BHK_Type__c: plot.BHK_Type__c ?? 0,
                    Floor__c: plot.Floor__c ?? 0,
                    Corpus_Fund__c: plot.Corpus_Fund__c ?? 0,
                    Maintenance_Charge__c: plot.Maintenance_Charge__c ?? 0,
                    GST_For_Other_Charges__c: plot.GST_For_Other_Charges__c ?? 0,
                    GST__c: plot.GST1__c ?? 0,
                    Open_Terrace_Area__c: plot.Terrace_Area__c ?? 0,
                    Unit__c: plot.Id,
                    Additional_Parking_Required__c: 'No'
                };

                if (this.blockedPrice !== 0) {
                    this.discountAmount = 0;
                }

                this.quote = {
                    ...this.oppPlot,
                    Booking_Request__c: this.recordId,
                    Discount_Price__c: this.discountAmount,
                    Final_Price_Per_Sq_ft__c: this.getFinalPricePerSqft()
                };

                // If a parking type was already selected, auto-update its value
            if (this.carParkingOption) {
                this.carParkingValue = this.projectCharges[this.carParkingOption] || 0;
                this.showCarParkingValue = this.carParkingValue > 0;
            }

                this.showSpinner = false;
            })
            .catch(error => {
                console.error(error);
                this.error = error;
                this.showSpinner = false;
            });
    }
    get finalPricePerSqft() {
        return this.getFinalPricePerSqft();
    }

   getFinalPricePerSqft() {
        const basePrice = this.oppPlot?.Price_Per_Sq_Ft__c || 0;
        const discount = typeof this.discountAmount === 'number' ? this.discountAmount : 0;

        if (this.blockedPrice && this.blockedPrice !== 0) {
            return this.blockedPrice;
        }

        return basePrice - discount;
    }


    get projectName() {
        return this.oppPlot?.Project__r?.Name || '';
    }

    handleNext() {
        this.showSpinner = true;
        this.isDetailsStep = false;
        this.isPaymentStep = true;
        this.quote.Payment_Type__c = this.paymentType;

        if (this.paymentType === 'Standard' && this.oppPlot.Project__c) {
            getPaymentSchedules({ Pay: this.paymentType, Project: this.oppPlot.Project__c })
                .then(result => {
                    this.paymentScheduleList = result?.payList || [];
                    this.totalScheduleAmount = result?.paymentSum || 0;
                })
                .catch(error => {
                    console.error('Error fetching standard payment schedules:', error);
                })
                .finally(() => {
                    this.showSpinner = false;
                });
        } /*else if (this.paymentType === 'Custom') {
            this.initCustomSchedule(); // Load empty custom template
            this.showSpinner = false;
        } */
        /*
        else if (this.paymentType === 'Custom' && this.oppPlot.Project__c) {
    getPaymentSchedules({ Pay: 'Custom', Project: this.oppPlot.Project__c })
        .then(result => {
            // Pre-fill editable rows
            this.customPaymentScheduleList = (result?.payList || []).map(item => ({
                id: item.Id || Math.random().toString(36).substring(2, 9),
                Name: item.Name,
                Payment_percent__c: item.Payment_percent__c,
                status__c: item.Status__c || 'Scheduled',
                Payment_Due_Date__c: item.Payment_Due_Date__c || '',
                Completed_Date__c: item.Completed_Date__c || '',
                showDueDate: true,
                showCompletedDate: false
            }));
        })
        .catch(error => {
            console.error('Error fetching custom schedule:', error);
            this.customPaymentScheduleList = [];
        })
        .finally(() => {
            this.showSpinner = false;
        });
}
*/

        else if (this.paymentType === 'Custom' && this.oppPlot.Project__c) {
    getPaymentSchedules({ Pay: 'Custom', Project: this.oppPlot.Project__c })
        .then(result => {
            const rows = (result?.payList || []).map(item => ({
                id: item.Id || Math.random().toString(36).substring(2, 9),
                Name: item.Name,
                Payment_percent__c: item.Payment_percent__c,
                status__c: item.Status__c || 'Scheduled',
                Payment_Due_Date__c: item.Payment_Due_Date__c || '',
                Completed_Date__c: item.Completed_Date__c || '',
                Master_Payment_Schedule__c: item.Master_Payment_Schedule__c, // keep tag
                Include_Interest__c: item.Include_Interest__c,
                S_No__c: item.S_No__c,                  // preserve sequence
                showDueDate: true,
                showCompletedDate: false,
                isCustom: false,                        // UI flag
                Is_Custom__c: false                     // backend flag
            }));

            this.originalPaymentScheduleList = JSON.parse(JSON.stringify(rows)); // freeze baseline
            this.customPaymentScheduleList = rows; // editable copy
        })
        .catch(error => {
            console.error('Error fetching custom schedule:', error);
            this.customPaymentScheduleList = [];
        })
        .finally(() => {
            this.showSpinner = false;
        });
}


        else {
            this.showSpinner = false;
        }
    }

    handlePrevious() {
        this.isDetailsStep = true;
        this.isPaymentStep = false;
    }

    initCustomSchedule() {
        this.customPaymentScheduleList = [
            {
                Name: '',
                Payment_percent__c: null,
                status__c: 'Scheduled',
                Payment_Due_Date__c: '',
                Completed_Date__c: '',
                showDueDate:true,
                showCompletedDate:false
            }
        ];
    }

    /*
    handlestatusChange(event) {
        const { name, value } = event.target;
        const index = event.target.dataset.index;
        const item = this.customPaymentScheduleList[index];
        item.status__c = value;
        item.showDueDate = value === 'Scheduled' || value === 'Demanded';
        item.showCompletedDate = value === 'Paid';
    
        this.customPaymentScheduleList = [...this.customPaymentScheduleList];
    }
    */

    handlestatusChange(event) {
    const index = event.target.dataset.index;
    const value = event.target.value;

    const item = this.customPaymentScheduleList[index];
    item.status__c = value;
    item.showDueDate = value === 'Scheduled' || value === 'Demanded';
    item.showCompletedDate = value === 'Paid';

    // 🔹 Compare against original to detect customization
    const original = this.originalPaymentScheduleList[index];

    const changed =
        (item.Name ?? '') !== (original.Name ?? '') ||
        Number(item.Payment_percent__c ?? 0) !== Number(original.Payment_percent__c ?? 0);
        //(item.status__c ?? '') !== (original.status__c ?? '') ||
        //(item.Payment_Due_Date__c ?? '') !== (original.Payment_Due_Date__c ?? '') ||
        //(item.Completed_Date__c ?? '') !== (original.Completed_Date__c ?? '');

    item.isCustom = changed;       // for UI highlight (Sl. No)
    item.Is_Custom__c = changed;   // for backend save

    this.customPaymentScheduleList = [...this.customPaymentScheduleList];
}


    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());

        this.dispatchEvent(new CustomEvent('close'));
    }

    handleDiscountChange(event) {
        //this.discountAmount = parseFloat(event.target.value);
        //this.quote.Discount_Price__c = this.discountAmount;

        const input = parseFloat(event.target.value) || 0;
        const basePrice = this.oppPlot?.Price_Per_Sq_Ft__c || 0;

        if (input > basePrice) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Invalid Discount',
                    message: 'Discount cannot exceed Price Per Sqft.',
                    variant: 'error'
                })
            );
            this.discountAmount = 0;
        } else {
            this.discountAmount = input;
        }

        // Also set on quote if needed
        this.quote.Discount_Price__c = this.discountAmount;
        this.quote.Final_Price_Per_Sq_ft__c = this.getFinalPricePerSqft();
    }

    handleSave() {
        if (!this.validateCustomPaymentSchedule()) {
            return;
        }

        this.showSpinner = true;
        //this.quote.Discount_Price__c = this.discountAmount;

        insertQuote({ quoteRecord: this.quote })
            .then((quoteId) => {
                const schedulesToInsert = this.paymentType === 'Standard'
                    ? this.paymentScheduleList
                    : this.customPaymentScheduleList;

                     console.log('Schedules being saved: ', JSON.stringify(schedulesToInsert));

                return insertSchedules({
                    payList: schedulesToInsert,
                    gt: this.totalScheduleAmount,
                    quoteid: quoteId
                }).then(() => {
                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: quoteId,
                            objectApiName: 'Quote__c',
                            actionName: 'view'
                        }
                    });
                });
            })
            .catch(error => {
                console.error('Error during quote or schedule save:', error);
                this.showToast('Error', 'Something went wrong during save.', 'error');
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }

    validateCustomPaymentSchedule() {
    if (this.paymentType !== 'Custom') {
        return true;
    }

    let totalPercent = 0;
    const today = new Date().toISOString().split('T')[0];

    for (let i = 0; i < this.customPaymentScheduleList.length; i++) {
        const item = this.customPaymentScheduleList[i];
        const index = i + 1;
        if (!item.Name || item.Name.trim() === '') {
            this.showToast('Validation Error', `Description is required in row ${index}.`, 'error');
            return false;
        }

        if (item.Payment_percent__c == null || item.Payment_percent__c < 0 || item.Payment_percent__c == 0) {
            this.showToast('Validation Error', `Percent must be a non-negative number in row ${index}.`, 'error');
            return false;
        }

        totalPercent += Number(item.Payment_percent__c);

        if (!item.status__c) {
            this.showToast('Validation Error', `Status is required in row ${index}.`, 'error');
            return false;
        }

        if ((item.status__c === 'Scheduled' || item.status__c === 'Demanded')) {
            if (!item.Payment_Due_Date__c) {
                this.showToast('Validation Error', `Due Date is required in row ${index}.`, 'error');
                return false;
            }
            if (item.Payment_Due_Date__c < today) {
                this.showToast('Validation Error', `Due Date cannot be in the past in row ${index}.`, 'error');
                return false;
            }
        }

        if (item.status__c === 'Paid') {
            if (!item.Completed_Date__c) {
                this.showToast('Validation Error', `Completed Date is required in row ${index}.`, 'error');
                return false;
            }
            if (item.Completed_Date__c > today) {
                this.showToast('Validation Error', `Completed Date cannot be in the future in row ${index}.`, 'error');
                return false;
            }
        }
    }

    if (totalPercent !== 100) {
        this.showToast('Validation Error', `Total percent must equal 100%. Currently: ${totalPercent}%`, 'error');
        return false;
    }

    return true;
}

showToast(title, message, variant) {
    this.dispatchEvent(
        new ShowToastEvent({
            title,
            message,
            variant,
            mode: 'dismissable'
        })
    );
}

/*
handleInputChange(event) {
    const index = event.target.dataset.index;
    const field = event.target.dataset.field;
    const value = event.target.value;

    this.customPaymentScheduleList[index][field] = value;
}
*/

handleInputChange(event) {
    const index = event.target.dataset.index;
    const field = event.target.dataset.field;
    const value = event.target.value;

    this.customPaymentScheduleList[index][field] = value;

    // Compare against original to decide if this row is custom
    const current  = this.customPaymentScheduleList[index];
    const original = this.originalPaymentScheduleList[index];

    const changed =
        (current.Name ?? '') !== (original.Name ?? '') ||
        Number(current.Payment_percent__c ?? 0) !== Number(original.Payment_percent__c ?? 0);

    current.isCustom = changed;         // UI highlight
    current.Is_Custom__c = changed;     // persist to Apex

    this.customPaymentScheduleList = [...this.customPaymentScheduleList];
}

/*
    handleAddRow() {
        this.customPaymentScheduleList = [
            ...this.customPaymentScheduleList,
            {
                Name: '',
                Payment_percent__c: null,
                status__c: 'Scheduled',
                Payment_Due_Date__c: '',
                Completed_Date__c: '',
                showDueDate:true,
                showCompletedDate:false
            }
        ];
    }
*/

handleAddRow() {
    const nextSeq =
        (this.customPaymentScheduleList
            .map(r => r.S_No__c || 0)
            .reduce((a, b) => Math.max(a, b), 0)) + 1;

    this.customPaymentScheduleList = [
        ...this.customPaymentScheduleList,
        {
            id: Math.random().toString(36).substring(2, 9),
            Name: '',
            Payment_percent__c: null,
            status__c: 'Scheduled',
            Payment_Due_Date__c: '',
            Completed_Date__c: '',
            Master_Payment_Schedule__c: null, // brand-new, no master
            Include_Interest__c: false,
            S_No__c: nextSeq,                 // next number
            showDueDate: true,
            showCompletedDate: false,
            isCustom: true,                   // highlight immediately
            Is_Custom__c: true                // and save as custom
        }
    ];
}


    handleRemoveRow(event) {
        const index = parseInt(event.currentTarget.dataset.index, 10);
        if (this.customPaymentScheduleList.length > 1) {
            this.customPaymentScheduleList.splice(index, 1);
            this.customPaymentScheduleList = [...this.customPaymentScheduleList];
        }
    }
/*
    get customPaymentScheduleListWithIndex() {
        return this.customPaymentScheduleList.map((item, index) => ({
            ...item,
            displayIndex: index + 1
        }));
    }
*/

get customPaymentScheduleListWithIndex() {
    return this.customPaymentScheduleList.map((item, index) => ({
        ...item,
        displayIndex: index + 1,
        serialClass: item.isCustom ? 'highlight-serial' : ''   // add class
    }));
}


    handleCustomFieldChange(event) {
        const index = parseInt(event.currentTarget.dataset.index, 10);
        const field = event.target.name;
        const value = event.target.value;

        this.customPaymentScheduleList[index][field] = value;
    }

    get errorMessage() {
        return this.error?.body?.message || 'An error occurred.';
    }


    handleCarParkingChange(event) {
    this.carParkingOption = event.detail.value;

    if (!this.carParkingOption || this.carParkingOption === '') {
        // If "None" selected, hide the field & reset values
        this.carParkingValue = 0;
        this.showCarParkingValue = false;
    } else {
        // Get the charge from project data; fallback to 0 if undefined or null
        const charge = this.projectCharges?.[this.carParkingOption];
        this.carParkingValue = charge ?? 0;

        // Always show the field when any parking type is selected
        this.showCarParkingValue = true;
    }

    // Update quote values
    this.quote.Car_Parking_Charges__c = this.carParkingValue;
    this.quote.Car_Parking_Type__c = this.carParkingOption;
}



    handleCarParkingValueChange(event) {
        this.carParkingValue = event.detail.value;
        this.quote.Car_Parking_Charges__c = this.carParkingValue;
    }

    handlePaymentTypeChange(event) {
        this.paymentType = event.detail.value;
        this.quote.Payment_Type__c = this.paymentType;
    }

    handleAdditionalParkingChange(event) {
        this.additionalParkingRequired = event.detail.value;
        this.quote.Additional_Parking_Required__c = this.additionalParkingRequired;
    }

    loadPaymentSchedule() {
        if (!this.oppPlot.Project__c) {
            console.error('Project is not available');
            return;
        }

        getPaymentSchedules({ Pay: this.paymentType, Project: this.oppPlot.Project__c })
            .then(result => {
                this.paymentScheduleList = result?.payList || [];
                this.totalScheduleAmount = result?.paymentSum || 0;
            })
            .catch(error => {
                console.error('Error fetching payment schedules', error);
            });
    }
}