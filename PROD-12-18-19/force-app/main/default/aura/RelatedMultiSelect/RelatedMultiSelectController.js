({
    doInit : function(cmp,event,helper) {
        cmp.set("v.options",[]);
        cmp.set("v.showSearch",false);
        cmp.set("v.showSpinner", true);
        helper.doInit(cmp);
    },
    handleKeyUp : function (cmp, evt, helper) {
        helper.handleKeyUp(cmp, evt);
    },
    selectRecord : function (cmp, evt, helper) {
        helper.selectRecord(cmp, evt);
    },
    selectSearchRecord : function (cmp, evt, helper) {
        helper.selectSearchRecord(cmp, evt);
    }
})