({
    doInit : function(cmp,event,helper) {
        cmp.set("v.options",[]);
        cmp.set("v.showSearch", false);
        cmp.set("v.showSpinner", true);
        helper.doInit(cmp);
    },

    handleKeyUp : function (cmp, event, helper) {
        helper.handleKeyUp(cmp);
    },

    selectRecord : function (cmp, event, helper) {
        var selectedIndex = parseInt(event.currentTarget.dataset.index);
        var options = cmp.get("v.options");
        options[selectedIndex].selected = !options[selectedIndex].selected;
        cmp.set("v.options", options);

        if (options[selectedIndex].selected) {
            cmp.set("v.selectedCount", cmp.get("v.selectedCount") + 1);
        } else {
            cmp.set("v.selectedCount", cmp.get("v.selectedCount") - 1);
        }
    },
    selectSearchRecord : function (cmp, event, helper) {
        var selectedIndex = parseInt(event.currentTarget.dataset.index);
        helper.selectSearchRecord(cmp, selectedIndex);
    },

    onclickSelectAll : function(cmp, event, helper) {
        helper.processSelectAndUnselectAll(cmp, true);
        cmp.set("v.selectedCount", cmp.get("v.options").length);
    },
    onclickUnselectAll : function(cmp, event, helper) {
        helper.processSelectAndUnselectAll(cmp, false);
        cmp.set("v.selectedCount", 0);
    },

    onfocusEnterSearch : function(cmp, event, helper) {
        if (!$A.util.isEmpty(cmp.get("v.searchOptions"))) {
            cmp.set("v.showSearch", true);
        }
    },
    onblurEnterSearch : function(cmp, event, helper) {
        setTimeout(function() {
            cmp.set("v.showSearch", false);
        }, 500);
    }
})