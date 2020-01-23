({
    doInit : function(cmp, event, helper) {
        console.log('PermissionEdit.doInit()');
        helper.initializeComponent(cmp);
    },

    resetPageState: function(cmp, event, helper){
        console.log("old value: " + event.getParam("oldValue"));
        console.log("current value: " + event.getParam("value"));

        var oldPageState = event.getParam("oldValue");
        var newPageState = event.getParam("value");

        if (!$A.util.isEmpty(oldPageState)) {
            console.log("reset cache");
            cmp.set("v.existingRowMap", {});
            cmp.set("v.permissionConfig", {});
            cmp.set("v.parentId", '');
            cmp.set("v.relatedSelectionData", []);
            cmp.set("v.keyObjects",[]);
            cmp.set("v.masterPmsList",[]);
            cmp.set("v.rowObjectJSON",'');
            cmp.set("v.keyObjectJSON",'');
            cmp.set("v.existingPermissions",[]);
            cmp.set("v.pageIndex",0);
            cmp.set("v.recordName","");
            cmp.set("v.recordId","");
            cmp.set("v.permissionConfigName","");
            cmp.set("v.defaultedPermissionTypes","");
            cmp.set("v.selectedIdMap", {});

            var selectedObjectMap = {};
            cmp.get("v.sObjectNames").forEach(function(objName) {
                selectedObjectMap[objName] = [];
            });
            cmp.set("v.selectedObjectMap", selectedObjectMap);

            helper.initializeComponent(cmp);
        }
    },

    handleSmartEvent : function(cmp, event, helper){
        const sender = event.getParam("sender");
        const receiver = event.getParam("receiver");
        const typeOfOperation = event.getParam("typeOfOperation");
        let paramMap = event.getParam("paramMap");

        console.log('Event received: ' +typeOfOperation);

        if (receiver === cmp.get("v.componentId")) {
            if (typeOfOperation === "RELATED_MULTI_SELECT_DO_INIT_COMPLETION") {
                cmp.set("v.incompleteRelatedMultiSelect", cmp.get("v.incompleteRelatedMultiSelect")-1);
                if (cmp.get("v.incompleteRelatedMultiSelect") == 0) {
                    setTimeout(function() {cmp.set("v.showSpinner", false);});
                }
            }
        }

        if (sender === cmp.get("v.permissionConfig.Id") && receiver === cmp.get("v.permissionConfig.Id")) {
            if (typeOfOperation === "REFRESH_TABLE_WITH_NEW_SELECTED_ITEMS") {
                helper.refreshTableWithNewSelectedItems(cmp);
            } else if (typeOfOperation === "SAVE_PERMISSIONS") {
                helper.savePermissionsAction(cmp);
            } else if (typeOfOperation === "INITIALIZE_COMPONENT_LOAD_RELATED_RECORDS") {
                helper.initRelatedSelect(cmp);
            }
        }
    },

    toggleSectionDisplay : function(cmp, event, helper) {
        var index = event.currentTarget.dataset.index;
        var keyObjects = cmp.get("v.keyObjects");
        keyObjects[index].selected = !keyObjects[index].selected;
        cmp.set("v.keyObjects", keyObjects);
    },

    onclickClearPermissions : function(cmp, event, helper) {
        const dataset = event.currentTarget.dataset;
        if (!$A.util.isEmpty(dataset)) {
            const keyIndex = $A.util.isEmpty(dataset.keyIndex) ? -1 : parseInt(dataset.keyIndex);
            const rowIndex = $A.util.isEmpty(dataset.rowIndex) ? -1 : parseInt(dataset.rowIndex);
            console.log("Clear Permissions: keyIndex: " + keyIndex + " | rowIndex: " + rowIndex);

            const keyObjects = cmp.get("v.keyObjects");
            const optionValue = "Inactive";
            if (keyIndex < 0) {
                if (confirm("Are you sure you want to clear all Permissions on this page?")) {
                    for (let i = 0; i < keyObjects.length; i++) {
                        helper.setKeyLevelOptions(keyObjects[i], "Status__c", optionValue, -1, true);
                        if (cmp.get("v.enableAlerts")) {
                            helper.setKeyLevelOptions(keyObjects[i], "Alert_Status__c", optionValue, -1, true);
                        }
                    }
                }
            } else if (rowIndex < 0) {
                helper.setKeyLevelOptions(keyObjects[keyIndex], "Status__c", optionValue, -1, true);
                if (cmp.get("v.enableAlerts")) {
                    helper.setKeyLevelOptions(keyObjects[keyIndex], "Alert_Status__c", optionValue, -1, true);
                }
            } else {
                helper.setRowLevelOptions(keyObjects[keyIndex].rows[rowIndex], "Status__c", optionValue, -1, true);
                if (cmp.get("v.enableAlerts")) {
                    helper.setRowLevelOptions(keyObjects[keyIndex].rows[rowIndex], "Alert_Status__c", optionValue, -1, true);
                }
            }

            helper.setPermissionControls(cmp, keyObjects);
            cmp.set("v.keyObjects", keyObjects);
        }
    },
    
    onclickToggleOption : function(cmp, event, helper) {
        var dataset = event.currentTarget.dataset;
        if (!$A.util.isEmpty(dataset)) {
            var keyIndex = $A.util.isEmpty(dataset.keyIndex) ? -1 : parseInt(dataset.keyIndex);
            var rowIndex = $A.util.isEmpty(dataset.rowIndex) ? -1 : parseInt(dataset.rowIndex);
            var optionIndex = $A.util.isEmpty(dataset.optionIndex) ? -1 : parseInt(dataset.optionIndex);
            var optionKey = dataset.optionKey;
            console.log("keyIndex: " + keyIndex + " | rowIndex: " + rowIndex + " | optionIndex: " + optionIndex + " | optionKey: " + optionKey);

            var keyObjects = cmp.get("v.keyObjects");
            var optionValue = "Inactive";
            if (keyIndex < 0) { //Master level
                var masterPmsList = cmp.get("v.masterPmsList");
                optionValue = (masterPmsList[optionIndex].permission[optionKey] === "Active") ? "Inactive" : "Active";
                helper.setPermissionFieldValues(masterPmsList[optionIndex], optionKey, optionValue, false);
                keyObjects.forEach(function(keyObj) {
                    helper.setKeyLevelOptions(keyObj, optionKey, optionValue, optionIndex, false);
                });
                cmp.set("v.masterPmsList", masterPmsList);
            } else if (rowIndex < 0) { //Key object level
                if (optionIndex < 0) {
                    optionValue = (keyObjects[keyIndex].pmsRowCtrl.permission[optionKey] === "Active") ? "Inactive" : "Active";
                } else {
                    optionValue = (keyObjects[keyIndex].pmsList[optionIndex].permission[optionKey] === "Active") ? "Inactive" : "Active";
                }
                helper.setKeyLevelOptions(keyObjects[keyIndex], optionKey, optionValue, optionIndex, false);
            } else { //Row level
                if (optionIndex < 0) {
                    optionValue = (keyObjects[keyIndex].rows[rowIndex].pmsRowCtrl.permission[optionKey] === "Active") ? "Inactive" : "Active";
                } else {
                    optionValue = (keyObjects[keyIndex].rows[rowIndex].pmsList[optionIndex].permission[optionKey] === "Active") ? "Inactive" : "Active";
                }
                helper.setRowLevelOptions(keyObjects[keyIndex].rows[rowIndex], optionKey, optionValue, optionIndex, false);
            }

            helper.setPermissionControls(cmp, keyObjects);

            const unsaved = cmp.find("unsaved");
            if (!$A.util.isEmpty(unsaved)) {
                let rowChanged = false;
                for (let k = 0; k < keyObjects.length; k++) {
                    for (let r = 0; r < keyObjects[k].rows.length; r++) {
                        if (keyObjects[k].rows[r].changed) {
                            rowChanged = true;
                            break;
                        }
                    }
                    if (rowChanged) break;
                }
                unsaved.setUnsavedChanges(rowChanged);
            }

            cmp.set("v.keyObjects", keyObjects);
        }
    },

    onclickSavePermission : function(cmp, event, helper) {
        console.log("---------- onclickSavePermission()");
        cmp.set("v.showSpinner", true);
        var smartEvent = $A.get("e.c:SmartEvent");
        smartEvent.setParams({
            "typeOfOperation" : "SAVE_PERMISSIONS",
            "sender" : cmp.get("v.permissionConfig.Id"),
            "receiver" : cmp.get("v.permissionConfig.Id")
        });
        setTimeout(function() {
            smartEvent.fire();
        });
    },

    loadPreviousPermissions : function(cmp, event, helper) {
        console.log("---------- loadPreviousPermissions");
        if (helper.confirmDiscardChanges(cmp.get("v.keyObjects"))) {
            if ($A.util.isEmpty(cmp.get("v.selectedIdMap"))) {
                helper.setSelectedIdMap(cmp);
            }

            var pageIndex = cmp.get("v.pageIndex");
            var pageList = cmp.get("v.pageList");

            if (pageIndex > 0) {
                pageIndex -= 1;
                cmp.set("v.pageIndex", pageIndex);

                if (pageIndex > 0) {
                    helper.queryAdditionalPermissions(cmp, pageList[pageIndex - 1].pmsQueryOrderValues);
                } else {
                    helper.queryAdditionalPermissions(cmp, []);
                    cmp.set("v.disablePreviousBtn", true);
                }
            }

            cmp.set("v.disableNextBtn", false);
        }
    },

    loadNextPermissions : function(cmp, event, helper) {
        console.log("---------- loadNextPermissions");
        if (helper.confirmDiscardChanges(cmp.get("v.keyObjects"))) {
            if ($A.util.isEmpty(cmp.get("v.selectedIdMap"))) {
                helper.setSelectedIdMap(cmp);
            }

            var pageIndex = cmp.get("v.pageIndex");
            var pageList = cmp.get("v.pageList");

            pageIndex += 1;
            cmp.set("v.pageIndex", pageIndex);

            helper.queryAdditionalPermissions(cmp, pageList[pageIndex - 1].pmsQueryOrderValues);

            cmp.set("v.disablePreviousBtn", false);
        }
    },

    onclickRelatedMultiSelectGo : function(cmp, event, helper) {
        console.log("---------- onclickRelatedMultiSelectGo()");
        var relatedCmps = cmp.find("related-multi-select");
        if (!$A.util.isEmpty(relatedCmps)) {
            var selectedIdMap = {};
            var errors = [];
            for (var i = 0; i < relatedCmps.length; i++) {
                var options = relatedCmps[i].get("v.options");
                var selectedIds = [];
                for (var o = 0; o < options.length; o++) {
                    if (options[o].selected) {
                        selectedIds.push(options[o].id);
                    }
                }
                selectedIdMap[relatedCmps[i].get("v.widget.Id")] = selectedIds;
                if (selectedIds.length == 0) {
                    errors.push(relatedCmps[i].get("v.widget.Label__c"));
                }
            }
            console.log(selectedIdMap);
            if (errors.length > 0) {
                var errorMsg = "Please select at least one ";
                if (errors.length == 2) {
                    errorMsg += errors.join(" and ") + ".";
                } else if (errors.length > 2) {
                    errors[errors.length-1] = "and " + errors[errors.length-1];
                    errorMsg += errors.join(", ") + ".";
                } else {
                    errorMsg += errors[0] + ".";
                }

                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title: "Error",
                    message: errorMsg,
                    type: "error",
                    duration: 10000
                });
                toastEvent.fire();
            } else {
                if (helper.confirmDiscardChanges(cmp.get("v.keyObjects"))) {
                    cmp.set("v.selectedIdMap", selectedIdMap);
                    cmp.set("v.showSpinner", true);
                    var smartEvent = $A.get("e.c:SmartEvent");
                    smartEvent.setParams({
                        "typeOfOperation" : "REFRESH_TABLE_WITH_NEW_SELECTED_ITEMS",
                        "sender" : cmp.get("v.permissionConfig.Id"),
                        "receiver" : cmp.get("v.permissionConfig.Id")
                    });
                    setTimeout(function() {
                        smartEvent.fire();
                    });
                }
            }
        }
    }
})