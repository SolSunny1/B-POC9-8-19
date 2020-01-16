({
    doInit : function(cmp, event, helper) {
        console.log('starting init');
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
            cmp.set("v.paginationList",[]);
            cmp.set("v.recordName","");
            cmp.set("v.recordId","");
            cmp.set("v.permissionConfigName","");
            cmp.set("v.defaultedPermissionTypes","");

            var selectedObjectMap = {};
            cmp.get("v.sObjectNames").forEach(function(objName) {
                selectedObjectMap[objName] = [];
            });
            cmp.set("v.selectedObjectMap", selectedObjectMap);

            helper.initializeComponent(cmp);
        }
    },

    handleSmartEvent : function(cmp, event, helper){
        var sender = event.getParam("sender");
        var receiver = event.getParam("receiver");
        var typeOfOperation = event.getParam("typeOfOperation");
        var paramMap = event.getParam("paramMap");

        console.log('Event received:' +typeOfOperation);
        if(receiver == cmp.get("v.permissionConfigName")){
            if (typeOfOperation === "relatedRowSelect") {
                cmp.set("v.showSpinner", true);
                var indexOfObj = cmp.get("v.sObjectNames").indexOf(paramMap.objName);
                var rowData = JSON.parse(JSON.stringify(paramMap));
                rowData.parentRecord = {};
                if (indexOfObj >= 0) {
                    var pmsFieldName = cmp.get("v.pmsFieldNames")[indexOfObj].replace("__c","__r");
                    rowData.parentRecord[pmsFieldName] = JSON.parse(JSON.stringify(paramMap.record));
                    console.log(rowData);
                }
                //helper.addTableRow(cmp, rowData);

                var smartEvent = $A.get("e.c:SmartEvent");
                smartEvent.setParams({
                    "typeOfOperation" : "CALL_ADD_TABLE_ROW",
                    "value" : JSON.stringify(rowData),
                    "receiver" : cmp.get("v.permissionConfigName")
                });
                setTimeout(function() {
                    smartEvent.fire();
                });
            }

            if (typeOfOperation === "CALL_ADD_TABLE_ROW") {
                helper.addTableRow(cmp, JSON.parse(event.getParam("value")));
                var unsaved = cmp.find("unsaved");
                unsaved.setUnsavedChanges(true);

                setTimeout(function() {
                    cmp.set("v.showSpinner", false);
                });
            }

            if (typeOfOperation === "RELOAD_KEYOBJECTS_WITH_PAGEINDEX") {
                helper.reloadKeyObjectsWithPageIndex(cmp, parseInt(event.getParam("value")+""));
                setTimeout(function() {
                    cmp.set("v.showSpinner", false);
                });
            }

            if (typeOfOperation === "TOGGLE_SPINNER") {
                cmp.set("v.showSpinner", event.getParam("value"));
            }

            if (typeOfOperation === "LOAD_REMAINING_PERMISSIONS") {
                try {
                    helper.queryAdditionalPermissions(cmp, paramMap);
                } catch (e) {
                    console.log(e);
                }
            }

            if (typeOfOperation === "LOAD_NEW_ITEM") {
                helper.loadNewItemIntoExistingRowMap(cmp, event.getParam("value"));
            }
        }
    },

    toggleSectionDisplay : function(cmp, event, helper) {
        var index = event.currentTarget.dataset.index;
        var keyObjects = cmp.get("v.keyObjects");
        keyObjects[index].selected = !keyObjects[index].selected;
        cmp.set("v.keyObjects", keyObjects);
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
                helper.setPermissionFieldValues(masterPmsList[optionIndex], optionKey, optionValue);
                keyObjects.forEach(function(keyObj) {
                    helper.setKeyLevelOptions(keyObj, optionKey, optionValue, optionIndex);
                });
                cmp.set("v.masterPmsList", masterPmsList);
            } else if (rowIndex < 0) { //Key object level
                if (optionIndex < 0) {
                    optionValue = (keyObjects[keyIndex].pmsRowCtrl.permission[optionKey] === "Active") ? "Inactive" : "Active";
                } else {
                    optionValue = (keyObjects[keyIndex].pmsList[optionIndex].permission[optionKey] === "Active") ? "Inactive" : "Active";
                }
                helper.setKeyLevelOptions(keyObjects[keyIndex], optionKey, optionValue, optionIndex);
            } else { //Row level
                if (optionIndex < 0) {
                    optionValue = (keyObjects[keyIndex].rows[rowIndex].pmsRowCtrl.permission[optionKey] === "Active") ? "Inactive" : "Active";
                } else {
                    optionValue = (keyObjects[keyIndex].rows[rowIndex].pmsList[optionIndex].permission[optionKey] === "Active") ? "Inactive" : "Active";
                }
                helper.setRowLevelOptions(keyObjects[keyIndex].rows[rowIndex], optionKey, optionValue, optionIndex);
            }

            helper.setPermissionControls(cmp, keyObjects);

            if(document.getElementsByClassName('changed').length>0){
                var unsaved = cmp.find("unsaved");
                unsaved.setUnsavedChanges(true);
            } else {
                var unsaved = cmp.find("unsaved");
                unsaved.setUnsavedChanges(false);
            }

            cmp.set("v.keyObjects", keyObjects);
        }
    },

    onclickSavePermission : function(cmp, event, helper) {
        cmp.set("v.showSpinner", true);
        var NAMESPACE = cmp.get("v.packageNamespace");
        var saveAction = cmp.get("c.savePermissionTable");
        var permissionList = [];
        var saveMode = cmp.get("v.permissionConfig.Save_Mode__c");
        var rowHeaderFields = cmp.get("v.rowHeaderFields");

        var existingRowMap = cmp.get("v.existingRowMap");
        for (var key in existingRowMap) {
            var nothingChanged = true;
            existingRowMap[key].pmsList.forEach(function(pms) {
                for (var i = 0; i < existingRowMap[key].subRecords.length; i++) {
                    if (rowHeaderFields[i].length <= 2 && $A.util.isEmpty(pms.permission[rowHeaderFields[i][0].replace('__r','__c')])) {
                        pms.permission[rowHeaderFields[i][0].replace('__r','__c')] = existingRowMap[key].subRecords[i].recordId;
                    }
                }

                if (existingRowMap[key].changed) {
                    if (pms.disableStatus) {
                        if (pms.disableAlert) {
                            //skip
                        } else {
                            if (cmp.get("v.permissionConfig")[NAMESPACE + "Save_Mode__c"] === "All") {
                                permissionList.push(pms.permission);
                                nothingChanged = false;
                            } else if (cmp.get("v.permissionConfig")[NAMESPACE + "Save_Mode__c"] === "Active Only") {
                                if ($A.util.isEmpty(pms.permission.Id)) {
                                    if (pms.permission.Alert_Status__c === "Active") {
                                        permissionList.push(pms.permission);
                                        nothingChanged = false;
                                    }
                                } else {
                                    permissionList.push(pms.permission);
                                    nothingChanged = false;
                                }
                            }
                        }
                    } else {
                        if (cmp.get("v.permissionConfig")[NAMESPACE + "Save_Mode__c"] === "All") {
                            permissionList.push(pms.permission);
                            nothingChanged = false;
                        } else if (cmp.get("v.permissionConfig")[NAMESPACE + "Save_Mode__c"] === "Active Only") {
                            if ($A.util.isEmpty(pms.permission.Id)) {
                                if (pms.permission.Status__c === "Active" || pms.permission.Alert_Status__c === "Active") {
                                    permissionList.push(pms.permission);
                                    nothingChanged = false;
                                }
                            } else {
                                permissionList.push(pms.permission);
                                nothingChanged = false;
                            }
                        }
                    }
                }
            });
            if (nothingChanged) {
                existingRowMap[key].changed = false;
            }
        }
        cmp.set("v.existingRowMap", existingRowMap);
        if (!cmp.get("v.enableAlerts")) {
            permissionList.forEach(function(permission) {
                delete permission.Alert_Status__c;
            });
        }

        console.log("PERMISSION LIST");
        console.log(permissionList);
        var params = {
            "pmsListJSON" : JSON.stringify(permissionList),
            "configJSON" : JSON.stringify(cmp.get("v.permissionConfig")),
            "widgetsJSON" : JSON.stringify(cmp.get("v.widgets"))
        };
        saveAction.setParam("params", params);
        saveAction.setCallback(this, function(response) {
            var state = response.getState();
            console.log(response.getState());
            if(state === "SUCCESS") {
                var returnValue = response.getReturnValue();
                console.log(returnValue);

                var toastEvent = $A.get("e.force:showToast");
                if (!$A.util.isEmpty(returnValue.errorMsg)) {
                    var errorRecords = JSON.parse(returnValue.errorRecords);
                    var errorMessages = JSON.parse(returnValue.errorMsg);
                    var keyObjects = cmp.get("v.keyObjects");
                    keyObjects.forEach(function(keyObj) {
                        keyObj.rows.forEach(function(row) {
                            var found = false;
                            var errorMessage = '';
                            row.pmsList.forEach(function(pms) {
                                var i = 0;
                                errorRecords.forEach(function(error) {
                                    var same = true;
                                    cmp.get("v.pmsFieldNames").forEach(function(field) {
                                        if(error[field] !== pms.permission[field]) {
                                            same = false;
                                        }
                                    });
                                    if(same) {
                                        found = true;
                                        errorMessage = errorMessages[i];
                                    }
                                    i++;
                                });
                            });
                            if (found) {
                                row.error = true;
                                //row.changed = false;
                                row.saved = false;
                                row.errorMessage = errorMessage == 'Insufficient Access Rights on Cross Reference Id' ? 'You lack access to one or more of the records related to this Permission. Contact an administrator if you believe this to be incorrect.' : errorMessage;
                                console.log("ERROR");
                            } else {
                                row.saved = true;
                                row.error = false;
                                row.changed = false;
                                row.errorMessage = null;
                                console.log("SAVED");
                            }
                        });
                    });
                    cmp.set('v.keyObjects', keyObjects);
                    toastEvent.setParams({
                        "type":"error",
                        "title": "Error!",
                        "mode":"sticky",
                        "message": "There were errors in your submissions, please check table for details."
                    });
                }

                if (!$A.util.isEmpty(returnValue.savedPermissionsJSON)) {
                    var config = cmp.get("v.permissionConfig");
                    var NAMESPACE = cmp.get("v.packageNamespace");
                    var partialSaveMessage;
                    if(!$A.util.isEmpty(config[NAMESPACE+'Partial_Save_Message__c'])){
                        partialSaveMessage = config[NAMESPACE+'Partial_Save_Message__c'];
                    } else {
                        partialSaveMessage = "Your permissions were saved successfully. However, we were unable to map all saved permissions into the table. Please refresh the page to view the updated table.";
                    }

                    try {
                        cmp.set("v.existingPermissions", JSON.parse(returnValue.savedPermissionsJSON));
                        helper.loadSavedPermissionsIntoTable(cmp);
                        var successfulMapping = true;
                        cmp.get("v.keyObjects").forEach(function(keyObj) {
                            keyObj.rows.forEach(function(row) {
                                if (row.changed) {
                                    successfulMapping = false;
                                }
                            });
                        });

                        if (successfulMapping) {
                            toastEvent.setParams({
                                "type":"success",
                                "title": "Success!",
                                "message": returnValue.successMsg
                            });
                        } else {
                            toastEvent.setParams({
                                "type":"warning",
                                "title": "Incomplete re-mapping of saved permissions!",
                                "mode":"sticky",
                                "message": partialSaveMessage
                            });
                            cmp.set("v.disableSaveButton", true);
                        }
                    } catch (e) {
                        console.log(e);
                        toastEvent.setParams({
                            "type":"warning",
                            "title": "Incomplete remapping of saved permissions!",
                            "mode":"sticky",
                            "message": partialSaveMessage
                        });
                        cmp.set("v.disableSaveButton", true);
                    }
                }
                var unsaved = cmp.find("unsaved");
                unsaved.setUnsavedChanges(false);
                toastEvent.fire();
            } else {
                console.log(response.getError());
                var unsaved = cmp.find("unsaved");
                unsaved.setUnsavedChanges(true);
            }
            cmp.set("v.showSpinner", false);
        });
        if ($A.util.isEmpty(permissionList) || permissionList.length === 0) {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type":"warning",
                "title": "No changes were detected",
                "mode":"sticky",
                "message": "Please make changes to the permissions first prior to saving."
            });
            toastEvent.fire();
            cmp.set("v.showSpinner", false);
        } else {
            if(confirm('Saving will update all changed permissions. Are you sure you want to save?')){
                $A.enqueueAction(saveAction);
            } else {
                cmp.set("v.showSpinner", false);
            }
        }
    },

    onclickResizeColumns : function(cmp, event, helper) {
        var buttonCmp = event.getSource();
        if (!$A.util.isEmpty(buttonCmp)) {
            var value = buttonCmp.get("v.value");
            var colSizeCounter = cmp.get("v.colSizeCounter");
            if (value === "Left") {
                if (colSizeCounter > 3) {
                    colSizeCounter -= 1;
                }
            } else if (value === "Right") {
                if (colSizeCounter < 8) {
                    colSizeCounter += 1;
                }
            }
            cmp.set("v.colSizeCounter", colSizeCounter);
            cmp.set("v.colSizeLeft", "slds-size_" + colSizeCounter + "-of-12");
            cmp.set("v.colSizeRight", "slds-size_" + (12-colSizeCounter) + "-of-12");
        }
    },

    switchTableMode : function(cmp, event, helper) {
        cmp.set("v.enableAlerts", !cmp.get("v.enableAlerts"));
    },

    onchangeSelectedObjectMap : function(cmp, event, helper) {
        cmp.set("v.showSpinner", cmp.get("v.pageIsFullyLoaded"));
        event.stopPropagation();
        console.log("---------- onchangeSelectedObjectMap()");
        helper.setupPagination(cmp);
        var paginationLength = cmp.get("v.paginationList").length;

        if (paginationLength > 0) {
            if (cmp.get("v.pageIndex") >= paginationLength) {
                cmp.set("v.pageIndex", cmp.get("v.paginationList").length - 1);
            } else {
                var smartEvent = $A.get("e.c:SmartEvent");
                smartEvent.setParams({
                    "typeOfOperation" : "RELOAD_KEYOBJECTS_WITH_PAGEINDEX",
                    "value" : cmp.get("v.pageIndex"),
                    "receiver":cmp.get("v.permissionConfigName")
                });
                setTimeout(function() {
                    smartEvent.fire();
                });
                //helper.reloadKeyObjectsWithPageIndex(cmp, cmp.get("v.pageIndex"));
            }
        }

    },

    onchangePaginationIndex : function(cmp, event, helper) {
        cmp.set("v.showSpinner", cmp.get("v.pageIsFullyLoaded"));
        event.stopPropagation();
        var smartEvent = $A.get("e.c:SmartEvent");
        smartEvent.setParams({
            "typeOfOperation" : "RELOAD_KEYOBJECTS_WITH_PAGEINDEX",
            "value" : event.getParam("value"),
            "receiver":cmp.get("v.permissionConfigName")
        });
        setTimeout(function() {
            smartEvent.fire();
        });
        //helper.reloadKeyObjectsWithPageIndex(cmp, event.getParam("value"));
    },

    onclickPagination : function(cmp, event, helper) {
        window.scrollTo({top: 0});
        var button = event.getSource();
        cmp.set("v.newKeyObjAdded", false);
        cmp.set("v.pageIndex", button.get("v.value"));
    },

    handleDiscard : function(cmp, event, helper){
        var unSavedChange = cmp.find('unsaved');
        unSavedChange.setUnsavedChanges(false);
    }
})