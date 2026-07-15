import { LightningElement, api } from 'lwc';
import updateGuestRecordField from '@salesforce/apex/LightningFileUploadHandler1.updateGuestRecordField';

export default class FileUploader extends LightningElement {
    @api parentRecordId; // Cost_Sheet__c Id from Aura
    @api label = 'Upload File';


    // This can be any record guest user can access — usually a dummy record ID or leave blank if org allows
    //@api dummyRecordId;

    async handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        for (let file of uploadedFiles) {
            await updateGuestRecordField({ 
                contentDocumentId: file.documentId, 
                parentRecordId: this.parentRecordId 
            });
        }
    }
}