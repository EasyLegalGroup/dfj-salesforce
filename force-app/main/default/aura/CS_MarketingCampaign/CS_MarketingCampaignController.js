({
    doInit: function(c, e, h) {
        h.doInit_helper(c, e, h);
    },

    editMarketingCampaign: function(c, e, h) {
        h.editMarketingCampaign_helper(c, e, h);
    },
    openNewCampaignModel: function(c, e, h) {
        c.set('v.campaignInstance', {});
        c.set('v.createCampaign', true);
        c.set('v.isEditing', true);
        c.set('v.filteredSpendPeriodList', []);
    },
    closeCreateModal: function(c, e, h) {
        c.set('v.createCampaign', false);
        c.set('v.isEditing', false);
    },
    saveCampaign: function(c, e, h) {
        h.checkValidation_helper(c, e, h);
    },
    enableDeleteModal: function(c, e, h) {
        h.enableDeleteModal_helper(c, e, h);
    },
    deleteCampaign: function(c, e, h) {
        h.deleteCampaign_helper(c, e, h);
    },
    closeDeleteModal: function(c, e, h) {
        c.set('v.openDeleteModal', false);
    },

    ReprocessLeads: function(c, e, h) {
        h.reprocessLeads_helper(c, e, h);
    },

    openCloseUnprocessedModal: function(c, e, h) {
        try {
            let tabIndex = e.getSource().get('v.tabindex');
            let openUnprocessedModal = c.get('v.openUnprocessedModal');
            if (!openUnprocessedModal) {
                let today = new Date();
                c.set('v.toDate', today.toISOString());
                c.set('v.selectedIndex', tabIndex);
            }
            c.set('v.openUnprocessedModal', !openUnprocessedModal);
        } catch (err) {
            console.error(err);
        }

    },
})