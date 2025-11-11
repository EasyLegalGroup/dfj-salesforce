({
    doInit: function(c, e, h) {
        h.doInit_helper(c, e, h, true);
    },
    hideEditCampaignPage: function(c, e, h) {
        c.set('v.isEditing', false);
    },
    editMarketingSpendPeriod: function(c, e, h) {
        h.editMarketingSpendPeriod(c, e, h);
    },
    closeSpendPeriodCreateModal: function(c, e, h) {
        c.set('v.isEditingSpendPeriod', false);
        c.set('v.createSpendPeriod', false);
    },
    openNewSpendPeriodModel: function(c, e, h) {
        c.set('v.createSpendPeriod', true);
        c.set('v.spendPeriodInstance', {});
    },
    saveSpendPeriod: function(c, e, h) {
        h.saveSpendPeriod_helper(c, e, h);
    },
    saveCampaignsAndSpendPeriods: function(c, e, h) {
        h.saveCampaignsAndSpendPeriods_helper(c, e, h);
    },
    openDeleteSpendPeriodModel: function(c, e, h) {
        let openDeleteConfirmationModel = c.get('v.openDeleteConfirmationModel');
        if (!openDeleteConfirmationModel) {
            let tabIndex = e.getSource().get('v.tabindex');
            c.set('v.selectedIndex', tabIndex);
        }
        c.set('v.openDeleteConfirmationModel', !openDeleteConfirmationModel);
    },
    saveSpendPeriodToList: function(c, e, h) {
        h.saveSpendPeriodToList_helper(c, e, h);
    },
    deleteSpendPeriodFromUI: function(c, e, h) {
        h.deleteSpendPeriodFromUI_helper(c, e, h);
    },
    openProcessScriptModel: function(c, e, h) {
        let openScriptProcessModel = c.get('v.openScriptProcessModel');
        if (!openScriptProcessModel) {
            let tabIndex = e.getSource().get('v.tabindex');
            c.set('v.selectedIndex', tabIndex);
        }
        c.set('v.openScriptProcessModel', !openScriptProcessModel);

    },
    closeSpendPeriodConfirmationModel: function(c, e, h) {
        c.set('v.openModelToSaveSpendPeriod', false);
        c.set('v.isOverlappingSpendPeriod', false);
        c.set('v.startAndEndMatchNotFound', false);
        c.set('v.createSpendPeriod', true);

    },
    runProcessScript: function(c, e, h) {
        h.runProcessScript_helper(c, e, h);

    },

    handleNext: function(c, e, h) {
        try {
            let pageNumber = c.get('v.pageNumber');
            let totalPage = c.get('v.totalPage');
            if ((pageNumber < totalPage) && pageNumber !== totalPage) {
                pageNumber = pageNumber + 1;
                c.set('v.pageNumber', pageNumber);
                h.displayRecordPerPage(c, e, h, pageNumber);
            }
        } catch (err) {
            console.error(err);
        }

    },
    handlePrev: function(c, e, h) {
        try {
            let pageNumber = c.get('v.pageNumber');
            if (pageNumber > 1) {
                pageNumber = pageNumber - 1;
                c.set('v.pageNumber', pageNumber);
                h.displayRecordPerPage(c, e, h, pageNumber);
            }
        } catch (err) {
            console.error(err);
        }

    }
})