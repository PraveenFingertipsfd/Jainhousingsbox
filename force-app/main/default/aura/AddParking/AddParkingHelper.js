({
    removeHilights : function(component,removeId) {
        // Remove highlight from filteredSlots
        let filteredSlots = component.get("v.filteredSlots");
        filteredSlots = filteredSlots.map(slot => {
            if (slot.Id === removeId) {
            delete slot.isNewlyAdded;
        }
                                          return slot;
                                          });
        component.set("v.filteredSlots", filteredSlots);
        
        // Remove highlight from availableSlots
        let availableSlots = component.get("v.availableSlots");
        availableSlots = availableSlots.map(slot => {
            if (slot.Id === removeId) {
            delete slot.isNewlyAdded;
        }
                                            return slot;
                                            });
        component.set("v.availableSlots", availableSlots);
    },
})