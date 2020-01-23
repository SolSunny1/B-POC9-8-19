({
    doInit : function(cmp,event,helper) {
        cmp.set("v.options",[]);
        cmp.set("v.showSearch", false);
        cmp.set("v.showSpinner", true);
        if (cmp.get("v.loadMode") === "edit") {
            helper.initializeOptionList(cmp);
            
            const cmpId = "#" + cmp.get("v.componentId");
            jQuery(document).ready(function() {
                $(cmpId + "-related-multiselect").click(function() {
                    $(cmpId + "-options-listener").focus();
                });
            });
        } else {
            helper.doInit(cmp);
        }
    },
    
    scrollToOption : function(cmp, event, helper) {
        const keyCode = event.which || event.keyCode
        const shortcutKey = String.fromCharCode(keyCode);
        if (/[a-z0-9]/i.test(shortcutKey)) {
            let shortcutIndex = (cmp.get("v.shortcutKey") == shortcutKey) ? cmp.get("v.shortcutIndex") + 1 : 0;
            const offsetList = cmp.get("v.scrollOffsetMap")[shortcutKey];
            if (!$A.util.isEmpty(offsetList)) {
                if (shortcutIndex >= offsetList.length) {
                    shortcutIndex = 0;
                }
                const cmpId = "#" + cmp.get("v.componentId");
                $(cmpId + "-options-container").animate({
                    scrollTop : offsetList[shortcutIndex]
                });
                
                cmp.set("v.shortcutIndex", shortcutIndex);
            	cmp.set("v.shortcutKey", shortcutKey);
            }
        }
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