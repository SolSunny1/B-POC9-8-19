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
            cmp.set("v.pageList", []);
            cmp.set("v.recordName","");
            cmp.set("v.recordId","");
            cmp.set("v.permissionConfigName","");
            cmp.set("v.defaultedPermissionTypes","");
            cmp.set("v.savePageIndex", 0);
            cmp.set("v.showSaveProgressModal", false);
            cmp.set("v.saveProgressValue", 0);
            cmp.set("v.numberOfProcessedRecords", 0);
            cmp.set("v.numberOfRecordsCreated", 0);
            cmp.set("v.saveProcessErrorMsg", "");
            cmp.set("v.selectedTab", "select");

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

        console.log('Event received: ' +typeOfOperation);

        if (typeOfOperation === "TOGGLE_SPINNER") {
            cmp.set("v.showSpinner", event.getParam("value"));
        }

        if (sender === cmp.get("v.permissionConfig.Id") && receiver === cmp.get("v.permissionConfig.Id")) {
            if (typeOfOperation === "GENERATE_PERMISSIONS_FOR_PREVIEW") {
                helper.generatePermissionsForPreview(cmp);
            } else if (typeOfOperation === "PAGINATION_CHANGE_PAGE") {
                helper.paginationChangePage(cmp);
            } else if (typeOfOperation === "INSERT_NEW_PERMISSIONS") {
                helper.savePermissionsAction(cmp);
            } else if (typeOfOperation === "GENERATE_THEN_INSERT_NEW_PERMISSIONS") {
                if (helper.generatePermissionsForPreview(cmp)) {
                    cmp.set("v.showSaveProgressModal", true);
                    var smartEvent = $A.get("e.c:SmartEvent");
                    smartEvent.setParams({
                        "typeOfOperation" : "INSERT_NEW_PERMISSIONS",
                        "sender" : cmp.get("v.permissionConfig.Id"),
                        "receiver" : cmp.get("v.permissionConfig.Id")
                    });
                    setTimeout(function() {
                        smartEvent.fire();
                    });
                }
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
        var dataset = event.currentTarget.dataset;
        if (!$A.util.isEmpty(dataset)) {
            var keyIndex = $A.util.isEmpty(dataset.keyIndex) ? -1 : parseInt(dataset.keyIndex);
            var rowIndex = $A.util.isEmpty(dataset.rowIndex) ? -1 : parseInt(dataset.rowIndex);
            console.log("Clear Permissions: keyIndex: " + keyIndex + " | rowIndex: " + rowIndex);

            var keyObjects = cmp.get("v.keyObjects");
            var optionValue = "Inactive";
            if (keyIndex < 0) {
                if (confirm("Are you sure you want to clear all Permissions on this page?")) {
                    for (var i = 0; i < keyObjects.length; i++) {
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
        const dataset = event.currentTarget.dataset;
        if (!$A.util.isEmpty(dataset)) {
            const keyIndex = $A.util.isEmpty(dataset.keyIndex) ? -1 : parseInt(dataset.keyIndex);
            const rowIndex = $A.util.isEmpty(dataset.rowIndex) ? -1 : parseInt(dataset.rowIndex);
            const optionIndex = $A.util.isEmpty(dataset.optionIndex) ? -1 : parseInt(dataset.optionIndex);
            const optionKey = dataset.optionKey;
            console.log("keyIndex: " + keyIndex + " | rowIndex: " + rowIndex + " | optionIndex: " + optionIndex + " | optionKey: " + optionKey);

            let keyObjects = cmp.get("v.keyObjects");
            let optionValue = "Inactive";
            if (keyIndex < 0) { //Master level
                let masterPmsList = cmp.get("v.masterPmsList");
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
        var totalRecords = cmp.get("v.permissionTypes").length;
        var relatedCmps = cmp.find("related-multi-select");
        if (!$A.util.isEmpty(relatedCmps)) {
            for (var i = 0; i < relatedCmps.length; i++) {
                totalRecords = totalRecords * relatedCmps[i].get("v.selectedCount");
            }
        }
        var confirmMessage = 'Your selections resulted in ' + totalRecords + ' permissions to be processed. This could take up to ';
        if (totalRecords >= 100000) {
            confirmMessage += '20 minutes to complete. Do you want to proceed?';
        } else if (totalRecords >= 50000) {
            confirmMessage += '10 minutes to complete. Do you want to proceed?';
        } else if (totalRecords >= 30000) {
            confirmMessage += '5 minutes to complete. Do you want to proceed?';
        } else if (totalRecords >= 10000) {
            confirmMessage += '2 minutes to complete. Do you want to proceed?';
        } else {
            confirmMessage = null;
        }
        if ($A.util.isEmpty(confirmMessage) || confirm(confirmMessage)) {
            var smartEvent = $A.get("e.c:SmartEvent");
            if ($A.util.isEmpty(cmp.get("v.pageList")) || cmp.get("v.pageList").length < 1) {
                cmp.set("v.showSpinner", true);
                smartEvent.setParams({
                    "typeOfOperation" : "GENERATE_THEN_INSERT_NEW_PERMISSIONS",
                    "sender" : cmp.get("v.permissionConfig.Id"),
                    "receiver" : cmp.get("v.permissionConfig.Id")
                });
            } else {
                cmp.set("v.showSaveProgressModal", true);
                smartEvent.setParams({
                    "typeOfOperation" : "INSERT_NEW_PERMISSIONS",
                    "sender" : cmp.get("v.permissionConfig.Id"),
                    "receiver" : cmp.get("v.permissionConfig.Id")
                });
            }
            setTimeout(function() {
                smartEvent.fire();
            });
        }
    },

    onactiveSelectTab : function(cmp, event, helper) {
        cmp.set("v.pageList", []);
        cmp.set("v.pageIndex", 0);
        cmp.set("v.showSaveProgressModal", false);
        cmp.set("v.saveProgressValue", 0);
        cmp.set("v.numberOfProcessedRecords", 0);
        cmp.set("v.numberOfRecordsCreated", 0);
        const unsaved = cmp.find("unsaved");
        if (!$A.util.isEmpty(unsaved)) {
            unsaved.setUnsavedChanges(false);
        }
    },

    onactivePreviewTab : function(cmp, event, helper) {
        cmp.set("v.showSpinner", true);
        var smartEvent = $A.get("e.c:SmartEvent");
        smartEvent.setParams({
            "typeOfOperation" : "GENERATE_PERMISSIONS_FOR_PREVIEW",
            "sender" : cmp.get("v.permissionConfig.Id"),
            "receiver" : cmp.get("v.permissionConfig.Id")
        });
        setTimeout(function() {
            smartEvent.fire();
        });

        jQuery(document).ready(function() {
            var $window = $(window),
                $pageHeader = $('#header'),
                $tableHeader = $('#table'),
                $headerBuffer = $('#headerBuffer'),
                $tableBuffer = $('#tableBuffer'),
                pageHeaderTop = $pageHeader.position().top,
                tableHeaderTop = $tableHeader.position().top,
                isSandbox = cmp.get("v.isSandbox");

            $window.scroll(function() {
                var windowScrollTop = $window.scrollTop();
                var pageHeaderRelPos = 24; //somewhat janky, using this as a constant for the padding around the page (outer page frame + component frame)
                var tableHeaderRelPos = $pageHeader.outerHeight(); //2 px for border top/bottom, 12 px for top padding.
                var pageHeaderIsStuck = $pageHeader.hasClass('sticky');
                var tableHeaderIsStuck = $tableHeader.hasClass('sticky');

                if (!pageHeaderIsStuck && windowScrollTop >= pageHeaderRelPos) {
                    $headerBuffer.css('height', $pageHeader.outerHeight());
                    $pageHeader.css('top',pageHeaderTop);
                } else if(pageHeaderIsStuck && windowScrollTop < pageHeaderRelPos){
                    $headerBuffer.css('height', 0);
                    $pageHeader.css('top',0);
                }

                if (!tableHeaderIsStuck && windowScrollTop >= tableHeaderRelPos) {
                    $tableBuffer.css('height', $tableHeader.outerHeight()-14);
                    $tableHeader.css('top', tableHeaderTop-tableHeaderRelPos+10); //2 px for border top/bottom, 12 px for top padding.
                } else if(tableHeaderIsStuck && windowScrollTop < tableHeaderRelPos) {
                    $tableBuffer.css('height', 0);
                    $tableHeader.css('top', 0);
                }

                $pageHeader.toggleClass('sticky', windowScrollTop >= pageHeaderRelPos);
                $tableHeader.toggleClass('sticky', windowScrollTop >= tableHeaderRelPos);
            });
        });
    },

    onclickPagination : function(cmp, event, helper) {
        cmp.set("v.showSpinner", true);
        var index = event.getSource().get("v.value");
        cmp.set("v.pageIndex", index);
        var smartEvent = $A.get("e.c:SmartEvent");
        smartEvent.setParams({
            "typeOfOperation" : "PAGINATION_CHANGE_PAGE",
            "sender" : cmp.get("v.permissionConfig.Id"),
            "receiver" : cmp.get("v.permissionConfig.Id")
        });
        setTimeout(function() {
            smartEvent.fire();
        });
    },

    setSelectedTabValue : function(cmp, event, helper) {
        cmp.set("v.selectedTab", event.getSource().get("v.value"));
    }
})