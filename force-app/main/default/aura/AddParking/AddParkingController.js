({
    doInit: function(component, event, helper) {
        const recordId = component.get("v.recordId");
        const action = component.get("c.getAllDetails");
        action.setParams({ bookingId: recordId });
        
        action.setCallback(this, function(response) {
            const state = response.getState();
            if (state === "SUCCESS") {
                const result = response.getReturnValue();
                component.set("v.bookingRecord", result.booking);
                component.set("v.UnitId", result.booking.Plot__c);
                component.set("v.existingParkings", result.ExistingParking);
                component.set("v.availableSlots", result.AllParking);
            } else {
                console.error('Error fetching Booking record:', response.getError());
            }
        });
        
        $A.enqueueAction(action);
    },
    
    closeModal: function(component) {
        component.set("v.showModal", false);
    },
    
    handlesave: function(component, event, helper) {
        const newlyAdded = component.get("v.newlyAddedParkings") || [];
        const existing = component.get("v.existingParkings") || [];
        const bookingId = component.get("v.recordId");
        const UnitId = component.get("v.UnitId");
        
        console.log('newlyAddedParkings > ', newlyAdded);
        console.log('existingParkings > ', existing);
        console.log('UnitId > ', UnitId);
        
        let toInsert = [];
        let toUpdate = [];
        
        if ((!newlyAdded || newlyAdded.length === 0) && (!existing || existing.length === 0)) {
            $A.get("e.force:showToast").setParams({
                "title": "Error",
                "type": "error",
                "message": "Please select parking slots"
            }).fire();
        }
        else{
            if (newlyAdded.length > 0) {
                toInsert = newlyAdded.map(slot => ({
                    Id: slot.Id,
                    Booking__c: bookingId,
                    Unit__c: UnitId,
                    Status__c: 'Sold',
                    Swapped_Slot_Number__c: null,
                    Swapped_Slot__c: null,
                    Is_Swapped__c: false,
                }));
            }
            if (existing.length > 0) {
                toUpdate = existing
                .filter(p => p.Swapped_Slot_Number__c)
                .map(p => ({
                    Id: p.Id,
                    Booking__c: bookingId,
                    Unit__c: UnitId,
                    Status__c: 'Sold',
                    Swapped_Slot_Number__c: p.Slot_Number__c,
                    Swapped_Slot__c: p.Swapped_Slot__c,
                    Is_Swapped__c: true,
                }));
            }
            
            console.log('bookingId > ', bookingId);
            console.log('newSlots > ', toInsert);
            console.log('swappedSlots > ', toUpdate);
            
            const action = component.get("c.saveParkings");
            action.setParams({
                bookingId: bookingId,
                newSlots: toInsert,
                swappedSlots: toUpdate
            });
            action.setCallback(this, function(response) {
                const state = response.getState();
                if (state === "SUCCESS") {
                    $A.get("e.force:showToast").setParams({
                        "title": "Success",
                        "type": "success",
                        "message": "Parking slots saved successfully!"
                    }).fire();
                    component.set("v.showModal", false);
                    $A.get("e.force:refreshView").fire();
                } else {
                    const errors = response.getError();
                    console.error("Save failed:", errors);
                    $A.get("e.force:showToast").setParams({
                        "title": "Error",
                        "type": "error",
                        "message": "Failed to save parking slots"
                    }).fire();
                }
            });
            
            $A.enqueueAction(action);
            $A.get('e.force:refreshView').fire();
        }
    },
    
    
    handleTypeChange: function(component, event, helper) {
        const parkingType = event.getSource().get("v.value");
        component.set("v.parkingType", parkingType);
        
        if (!parkingType) {
            component.set("v.filteredSlots", []);
            return;
        }
        
        let allSlots = component.get("v.availableSlots");
        let filteredSlots = allSlots.filter(slot => slot.Parking_Type__c === parkingType);
        component.set("v.filteredSlots", filteredSlots);
    },
    
    selectSlot: function(component, event) {
        const selectedId = event.currentTarget.dataset.id;
        const currentSelected = component.get("v.selectedSlot");
        
        // If the clicked slot is already selected, unselect it
        if (currentSelected && currentSelected.Id === selectedId) {
            component.set("v.selectedSlot", null);
        } else {
            const slots = component.get("v.availableSlots");
            const selected = slots.find(slot => slot.Id === selectedId);
            component.set("v.selectedSlot", selected);
        }
    },
    
    removeNewSlot: function(component, event, helper) {
        const removeId = event.getSource().get("v.value");
        let newList = component.get("v.newlyAddedParkings");
        
        const filtered = newList.filter(slot => slot.Id !== removeId);
        component.set("v.newlyAddedParkings", filtered);
        
        // Also remove highlight from filteredSlots
        helper.removeHilights(component,removeId);
    },
    
    chooseSlot: function(component) {
        const selected = component.get("v.selectedSlot");
        const swapIndex = component.get("v.swapIndex");
        
        if(selected && swapIndex != null){
            let existingParkings = component.get("v.existingParkings");
            if (existingParkings[swapIndex]){
                existingParkings[swapIndex].Swapped_Slot_Number__c = selected.Slot_Number__c;
                existingParkings[swapIndex].Swapped_Slot__c = selected.Id;
                component.set("v.existingParkings", existingParkings);
            }
            
            // Also update filteredSlots so that UI highlights the pellet
            let filtered = component.get("v.filteredSlots");
            filtered = filtered.map(slot => {
                if (slot.Id === selected.Id) {
                slot.isNewlyAdded = true;
            }
                                    return slot;
                                    });
            component.set("v.filteredSlots", filtered);
            
            component.set("v.swapIndex", null);
            component.set("v.selectedSlot", null);
            
        }
        else if (selected) {
            let newList = component.get("v.newlyAddedParkings") || [];
            
            // Prevent duplicate slot addition
            const exists = newList.find(item => item.Id === selected.Id);
            if (!exists) {
                // Clone and mark as new
                let newSlot = Object.assign({}, selected);
                newSlot.isNewlyAdded = true;
                newList.push(newSlot);
            }
            
            component.set("v.newlyAddedParkings", newList);
            
            // Also update filteredSlots so that UI highlights the pellet
            let filtered = component.get("v.filteredSlots");
            filtered = filtered.map(slot => {
                if (slot.Id === selected.Id) {
                slot.isNewlyAdded = true;
            }
                                    return slot;
                                    });
            component.set("v.filteredSlots", filtered);
            component.set("v.selectedSlot", null);
        }
    },
    
    swapSlot: function(component, event) {
        const index = parseInt(event.getSource().get("v.value"), 10);
        component.set("v.swapIndex", index);
        component.set("v.selectedSlot", null);
        
        const existingParkings = component.get("v.existingParkings");
        if (existingParkings[index]) {
            const selectedType = existingParkings[index].Parking_Type__c;
            component.set("v.parkingType", selectedType);
            
            const allSlots = component.get("v.availableSlots");
            const filtered = allSlots.filter(slot => slot.Parking_Type__c === selectedType);
            component.set("v.filteredSlots", filtered);
        }
    },
    
    clearSwap: function(component, event, helper) {
        let removedSlotNumber = null;     
        let parkingType = '';
        const index = parseInt(event.getSource().get("v.value"), 10);
        let existingParkings = component.get("v.existingParkings");
        if (existingParkings[index]) {
            removedSlotNumber = existingParkings[index].Swapped_Slot_Number__c;
            parkingType = existingParkings[index].Parking_Type__c;
            existingParkings[index].Swapped_Slot_Number__c = '';
            component.set("v.existingParkings", existingParkings);
        }
        component.set("v.swapIndex", null);
        
        if (removedSlotNumber) {
            let availableSlots = component.get("v.availableSlots");
            const removedSlot = availableSlots.find(slot => slot.Slot_Number__c === removedSlotNumber && slot.Parking_Type__c === parkingType);
            const removedSlotId = removedSlot ? removedSlot.Id : null;
            
            if (removedSlotId) {
                helper.removeHilights(component,removedSlotId);
            }
        }
    },
})