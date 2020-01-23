({
    initializeComponent : function(cmp) {
        cmp.set("v.showSpinner", true);
        cmp.set("v.disableSaveButton", true);
        var pageRef = cmp.get("v.pageReference");
        if(!$A.util.isEmpty(pageRef)){
            if($A.util.isEmpty(cmp.get("v.recordName"))) {
                cmp.set("v.recordName", pageRef.state.c__recordName);
            }
            if ($A.util.isEmpty(cmp.get("v.recordId"))){
                cmp.set("v.recordId", pageRef.state.c__recordId);
            }
            if($A.util.isEmpty(cmp.get("v.permissionConfigName"))) {
                cmp.set("v.permissionConfigName", pageRef.state.c__permissionConfigName);
            }
            if ($A.util.isEmpty(cmp.get("v.defaultedPermissionTypes"))) {
                cmp.set("v.defaultedPermissionTypes", pageRef.state.c__defaultedPermissionTypes);
            }
        }
        //cmp.set("v.mode", pageRef.state.c__mode);
        // cmp.set("v.defaultPermissionColumns",pageRef.state.c__defaultPermissionColumns);

        var self = this;

        self.initializePermissionManager(cmp).then(
            $A.getCallback(
                function(returnValue){
                    try {
                        self.initTable(cmp, returnValue);
                        cmp.set("v.iconName",JSON.parse(returnValue.recordIcon));
                        cmp.set("v.permissionLabel",JSON.parse(returnValue.permissionLabel));
                    } catch (e) {
                        console.log(e);
                    }
                }
            ),
            $A.getCallback(
                function(error){
                    console.log(error);
                    self.displayErrorToast(cmp, error);
                    cmp.set("v.showSpinner", false);
                    cmp.set("v.disableSaveButton", false);
                }
            )
        ).finally(
            function() {
                jQuery(document).ready(function() {
                    var $window = $(window),
                        $pageHeader = $('#header'),
                        $tableHeader = $('#table'),
                        $headerBuffer = $('#headerBuffer'),
                        $tableBuffer = $('#tableBuffer'),
                        pageHeaderTop = $pageHeader.position().top,
                        tableHeaderTop = $tableHeader.position().top,
                        isSandbox = cmp.get("v.isSandbox"),
                        $pageHeaderOffset = cmp.get("v.pageHeaderOffset"),
                        $tableHeaderOffset = cmp.get("v.tableHeaderOffset"),
                        multiSelectPanelHeight = $('.multiSelectPanel').outerHeight();

                    $window.scroll(function() {
                        if (multiSelectPanelHeight == 0) {
                            multiSelectPanelHeight = $('.multiSelectPanel').outerHeight();
                            tableHeaderTop = $tableHeader.position().top;
                        }

                        var windowScrollTop = $window.scrollTop();
                        var pageHeaderRelPos = 24; //somewhat janky, using this as a constant for the padding around the page (outer page frame + component frame)
                        var tableHeaderRelPos = 24 + multiSelectPanelHeight +14; //2 px for border top/bottom, 12 px for top padding.
                        var pageHeaderIsStuck = $pageHeader.hasClass('sticky');
                        var tableHeaderIsStuck = $tableHeader.hasClass('sticky');

                        if (!pageHeaderIsStuck && windowScrollTop >= pageHeaderRelPos - $pageHeaderOffset) {
                            $headerBuffer.css('height', $pageHeader.outerHeight());
                            $pageHeader.css('top',pageHeaderTop + $pageHeaderOffset);
                        } else if(pageHeaderIsStuck && windowScrollTop < pageHeaderRelPos - $pageHeaderOffset){
                            $headerBuffer.css('height', 0);
                            $pageHeader.css('top',0);
                        }

                        if (!tableHeaderIsStuck && windowScrollTop >= tableHeaderRelPos - $tableHeaderOffset) {
                            $tableBuffer.css('height', $tableHeader.outerHeight());
                            $tableHeader.css('top',tableHeaderTop - multiSelectPanelHeight - 14 + $tableHeaderOffset); //2 px for border top/bottom, 12 px for top padding.
                        } else if(tableHeaderIsStuck && windowScrollTop < tableHeaderRelPos - $tableHeaderOffset) {
                            $tableBuffer.css('height', 0);
                            $tableHeader.css('top', 0);
                        }

                        $pageHeader.toggleClass('sticky', windowScrollTop >= pageHeaderRelPos - $pageHeaderOffset);
                        $tableHeader.toggleClass('sticky', windowScrollTop >= tableHeaderRelPos - $tableHeaderOffset);
                    })
                });
            }
        )
    },

    initializePermissionManager : function(cmp) {
        const initAction = cmp.get("c.initializeComponent_EditMode");
        initAction.setParam("params",{
            "configurationName":cmp.get("v.permissionConfigName"),
            "recordId":cmp.get("v.recordId"),
            "defaultedPermissionTypes":cmp.get("v.defaultedPermissionTypes")
        });

        return this.serverSideCall(cmp, initAction);
    },

    serverSideCall : function(cmp, action){
        console.log('Making server call to: ');
        console.log(action);
        return new Promise(
            $A.getCallback(
                function(resolve, reject){
                    action.setCallback(this,
                        function(response){
                            const state = response.getState();
                            if(state === "SUCCESS"){
                                resolve(response.getReturnValue());
                            } else if(state === "ERROR"){
                                reject(response.getError()[0].message);
                            }
                        });
                    $A.enqueueAction(action);
                }
            )
        );
    },

    initTable: function(cmp, returnValue){
        var self = this;
        const NAMESPACE = cmp.get("v.packageNamespace");
        self.logReturnValues(returnValue);

        const permissionConfig = JSON.parse(returnValue.config);
        cmp.set("v.componentId", "PermissionEdit_" + permissionConfig.Id);
        cmp.set("v.permissionConfig", permissionConfig);
        cmp.set("v.widgets",JSON.parse(returnValue.widgets));
        cmp.set("v.incompleteRelatedMultiSelect", cmp.get("v.widgets").length);
        cmp.set("v.parentId",returnValue.parentRecordId);
        cmp.set("v.existingPermissions", JSON.parse(returnValue.existingData));
        if ($A.util.isEmpty(cmp.get("v.existingPermissions"))) {
            const noRecordWarning = $A.get("e.force:showToast");
            noRecordWarning.setParams({
                "type":"warning",
                "title": "Warning!",
                "message" : "No permissions found."
            });
            noRecordWarning.fire();
        }
        cmp.set("v.isSandbox", returnValue.isSandbox == "true" ? true : false);
        cmp.set("v.enableAlerts", permissionConfig[NAMESPACE + 'Display_Alert_Icons__c']);
        cmp.set("v.readOnly", returnValue.readOnly == "true"? true:false);

        if (!$A.util.isEmpty(returnValue.userIsAdminJSON)) {
            cmp.set("v.userIsAdmin", JSON.parse(returnValue.userIsAdminJSON));
        }
        if (!$A.util.isEmpty(returnValue.securityGroupsJSON)) {
            cmp.set("v.securityGroups", JSON.parse(returnValue.securityGroupsJSON));
        }
        if (!$A.util.isEmpty(returnValue.enableRowSecurityJSON)) {
            cmp.set("v.enableRowSecurity", JSON.parse(returnValue.enableRowSecurityJSON));
        }

        if (!$A.util.isEmpty(returnValue.permissionTypesJSON)) {
            const permissionTypes = JSON.parse(returnValue.permissionTypesJSON);
            cmp.set("v.permissionTypes", permissionTypes);
            cmp.set("v.permissionTypeWidth", (Math.floor(100 / permissionTypes.length) + "%"));

            let headerAngle = permissionConfig[NAMESPACE + 'Header_Angle__c'];
            if (!$A.util.isEmpty(headerAngle) && headerAngle > 0) {
                let longestLength = 1;
                permissionTypes.forEach(function(pt) {
                    if (pt.Name.length > longestLength) {
                        longestLength = pt.Name.length;
                    }
                });
                let tableHeight = (Math.abs(longestLength * 6.5 * Math.sin(Math.PI * headerAngle / 180.0)) + 32);
                cmp.set("v.tableHeaderHeight", Math.floor(tableHeight) + "px");
                cmp.set("v.pmsTypeLabelTranslate", "transform:translate(40%," + Math.floor(tableHeight/2 - 10) + "px);");
                cmp.set("v.pmsTypeLabelWidth", Math.floor(longestLength * 8) + "px");
            }
        }
        if (!$A.util.isEmpty(returnValue.sObjectNamesJSON)) {
            cmp.set("v.sObjectNames", JSON.parse(returnValue.sObjectNamesJSON));
            cmp.set("v.sObjectLabels", JSON.parse(returnValue.sObjectLabelsJSON));
            cmp.set("v.pmsFieldNames", JSON.parse(returnValue.pmsFieldNamesJSON));

            const selectedObjectMap = {};
            cmp.get("v.sObjectNames").forEach(function(objName) {
                selectedObjectMap[objName] = [];
            });
            cmp.set("v.selectedObjectMap", selectedObjectMap);
            console.log("---------- selectedObjectMap");
            console.log(JSON.parse(JSON.stringify(selectedObjectMap)));
        }
        if (!$A.util.isEmpty(returnValue.pmsCtrlWrappersJSON)) {
            cmp.set("v.masterPmsList", JSON.parse(returnValue.pmsCtrlWrappersJSON));
        }

        const rowHeaders = [];
        if (!$A.util.isEmpty(permissionConfig[NAMESPACE + 'Headers__c'])) {
            permissionConfig[NAMESPACE + 'Headers__c'].split(";").forEach(function(headerLabel) {
                rowHeaders.push(headerLabel.trim());
            });
            rowHeaders.splice(0, 1);
        } else {
            const sObjectLabels = cmp.get("v.sObjectLabels");
            for (let i = 1; i < sObjectLabels.length; i++) {
                rowHeaders.push(sObjectLabels[i]);
            }
        }
        cmp.set("v.rowHeaders", rowHeaders);
        console.log("---------- rowHeaders");
        console.log(rowHeaders);

        if (!$A.util.isEmpty(permissionConfig[NAMESPACE + 'Columns__c'])) {
            const rowHeaderFields = [];
            permissionConfig[NAMESPACE + 'Columns__c'].split(";").forEach(function(col) {
                if (col.includes(".")) {
                    rowHeaderFields.push(col.trim().split("."));
                } else {
                    rowHeaderFields.push(col.trim());
                }
            });
            rowHeaderFields.splice(0, 1);

            cmp.set("v.rowHeaderFields", rowHeaderFields);
            console.log("---------- rowHeaderFields");
            console.log(cmp.get("v.rowHeaderFields"));
        }
        if (!$A.util.isEmpty(permissionConfig[NAMESPACE + 'Related_Data_Field_Mapping__c'])) {
            const relatedDataFields = [];
            permissionConfig[NAMESPACE + 'Related_Data_Field_Mapping__c'].split(";").forEach(function(col) {
                if (col.includes(".")) {
                    relatedDataFields.push(col.trim().split("."));
                } else {
                    relatedDataFields.push(col.trim());
                }
            });
            relatedDataFields.splice(0, 1);

            cmp.set("v.relatedDataFields", relatedDataFields);
            console.log("---------- relatedDataFields");
            console.log(cmp.get("v.relatedDataFields"));
        }

        if (!$A.util.isEmpty(permissionConfig[NAMESPACE + 'Permission_Security_Field__c'])) {
            const securityFields = [];
            let psfIndex = 0;
            permissionConfig[NAMESPACE + 'Permission_Security_Field__c'].split(";").forEach(function(fieldName) {
                if (!$A.util.isEmpty(fieldName) && fieldName.includes(".")) {
                    securityFields.push(fieldName.trim().split("."));
                    if (psfIndex < cmp.get("v.sObjectNames").length) {
                        securityFields[psfIndex].splice(0, 1);
                    }
                } else {
                    securityFields.push(fieldName.trim());
                }
                psfIndex++;
            });
            cmp.set("v.securityFields", securityFields);
        }

        self.setTableSize(cmp);

        console.log("--------- SECURITY");
        console.log({
            "userIsAdmin" : cmp.get("v.userIsAdmin"),
            "enableRowSecurity" : cmp.get("v.enableRowSecurity"),
            "securityGroups" : cmp.get("v.securityGroups"),
            "securityFields" : cmp.get("v.securityFields")
        });
        console.log("------------------");


        if (!$A.util.isEmpty(returnValue.customPmsAPINamesJSON)) {
            cmp.set("v.customPmsAPINames", JSON.parse(returnValue.customPmsAPINamesJSON));
        }

        cmp.set("v.keyObjectJSON", returnValue.keyObjectJSON);
        cmp.set("v.rowLabelWidth", JSON.parse(returnValue.keyObjectJSON).rowLabelWidth);
        cmp.set("v.rowObjectJSON", returnValue.rowObjectJSON);

        // LOAD PERMISSIONS
        cmp.set("v.pageIndex", 0);
        cmp.set("v.pageList", []);
        if ($A.util.isEmpty(JSON.parse(returnValue.pmsQueryOrderValues))) {
            cmp.set("v.disableNextBtn", true);
        } else {
            self.setupPagination(cmp, JSON.parse(returnValue.pmsQueryOrderValues));
        }
        cmp.set("v.disablePreviousBtn", true);

        self.loadExistingPermissionsIntoTable(cmp);


        var loadRelatedEvent = $A.get("e.c:SmartEvent");
        loadRelatedEvent.setParams({
            "typeOfOperation" : "INITIALIZE_COMPONENT_LOAD_RELATED_RECORDS",
            "sender" : cmp.get("v.permissionConfig.Id"),
            "receiver" : cmp.get("v.permissionConfig.Id")
        });
        setTimeout(function() {
            loadRelatedEvent.fire();
        });
    },

    initRelatedSelect : function(cmp) {
        var self = this;
        const initAction = cmp.get("c.initializeComponent_RelatedRecords");
        initAction.setParam("params",{
            "parentRecordId" : cmp.get("v.parentId"),
            "recordId" : cmp.get("v.recordId"),
            "config" : JSON.stringify(cmp.get("v.permissionConfig")),
            "widgets" : JSON.stringify(cmp.get("v.widgets"))
        });
        initAction.setCallback(this,function(response){
            const state = response.getState();
            console.log("PermissionEdit_Controller.initializeComponent_RelatedRecords() " + state);
            if (state == "SUCCESS") {
                const returnValue =  response.getReturnValue();
                self.logReturnValues(returnValue);

                const relatedRecordsMap = JSON.parse(returnValue.relatedRecordsMap);
                const widgets = cmp.get("v.widgets");
                const widgetWrappers = [];
                for (let i = 0; i < widgets.length;i++) {
                    const ww = {};
                    ww.widget = widgets[i];
                    ww.defaults = relatedRecordsMap[widgets[i].Id];
                    widgetWrappers.push(ww);
                }
                console.log(widgetWrappers);
                cmp.set("v.widgetWrappers", widgetWrappers);
                cmp.set("v.relatedWidgetsAreReady", true);
                cmp.set("v.disableSaveButton", false);
            } else {
                this.throwError(response);
            }
        });
        $A.enqueueAction(initAction);
    },

    /* Save */
    savePermissionsAction : function(cmp) {
        console.log("---------- savePermissionsAction()");
        var self = this;
        const NAMESPACE = cmp.get("v.packageNamespace");
        const saveAction = cmp.get("c.savePermissionTable");
        const updatePmsList = [];
        const insertPmsList = [];
        const saveMode = cmp.get("v.permissionConfig.Save_Mode__c");
        const rowHeaderFields = cmp.get("v.rowHeaderFields");

        const keyObjects = cmp.get("v.keyObjects");
        for (let keyIndex = 0; keyIndex < keyObjects.length; keyIndex++) {
            for (let rowIndex = 0; rowIndex < keyObjects[keyIndex].rows.length; rowIndex++) {
                let row = keyObjects[keyIndex].rows[rowIndex];
                if (!row.changed) continue;

                for (let pmsIndex = 0; pmsIndex < row.pmsList.length; pmsIndex++) {
                    let pms = row.pmsList[pmsIndex];
                    for (let subIndex = 0; subIndex < row.subRecords.length; subIndex++) {
                        if (rowHeaderFields[subIndex].length <= 2 && $A.util.isEmpty(pms.permission[rowHeaderFields[subIndex][0].replace('__r','__c')])) {
                            pms.permission[rowHeaderFields[subIndex][0].replace('__r','__c')] = row.subRecords[subIndex].recordId;
                        }
                    }

                    if (pms.disableStatus) {
                        if (!pms.disableAlert) {
                            if ($A.util.isEmpty(pms.permission.Id)) {
                                if (pms.permission.Alert_Status__c === "Active") {
                                    insertPmsList.push(pms.permission);
                                }
                            } else {
                                updatePmsList.push(pms.permission);
                            }
                        }
                    } else {
                        if ($A.util.isEmpty(pms.permission.Id)) {
                            if (pms.permission.Status__c === "Active" || pms.permission.Alert_Status__c === "Active") {
                                insertPmsList.push(pms.permission);
                            }
                        } else {
                            updatePmsList.push(pms.permission);
                        }
                    }

                }
            }
        }

        if (!cmp.get("v.enableAlerts")) {
            insertPmsList.forEach(function(permission) {
                delete permission.Alert_Status__c;
            });
            updatePmsList.forEach(function(permission) {
                delete permission.Alert_Status__c;
            });
        }

        console.log("Update permissions:");
        console.log(updatePmsList);
        console.log("Insert permissions:");
        console.log(insertPmsList);

        if ($A.util.isEmpty(cmp.get("v.selectedIdMap"))) {
            self.setSelectedIdMap(cmp);
        }

        const lowerBound = (cmp.get("v.pageIndex") > 0) ? cmp.get("v.pageList")[cmp.get("v.pageIndex") - 1].pmsQueryOrderValues : []
        const params = {
            "updatePmsList" : JSON.stringify(updatePmsList),
            "insertPmsList" : JSON.stringify(insertPmsList),
            "parentRecordId" : cmp.get("v.parentId"),
            "childId" : cmp.get("v.recordId"),
            "widgets" : JSON.stringify(cmp.get("v.widgets")),
            "config" : JSON.stringify(cmp.get("v.permissionConfig")),
            "selectedIdMap" : JSON.stringify(cmp.get("v.selectedIdMap")),
            "lowerBound" : JSON.stringify(lowerBound)
        };
        console.log(params);
        saveAction.setParam("params", params);
        saveAction.setCallback(this, function(response) {
            const state = response.getState();
            console.log(response.getState());
            if (state === "SUCCESS") {
                const returnValue = response.getReturnValue();
                self.logReturnValues(returnValue);

                const toastEvent = $A.get("e.force:showToast");
                if (!$A.util.isEmpty(returnValue.errorMsg)) {
                    let errorRecords = JSON.parse(returnValue.errorRecords);
                    let errorMessages = JSON.parse(returnValue.errorMsg);
                    const keyObjects = cmp.get("v.keyObjects");
                    keyObjects.forEach(function(keyObj) {
                        keyObj.rows.forEach(function(row) {
                            let found = false;
                            let errorMessage = '';
                            row.pmsList.forEach(function(pms) {
                                let i = 0;
                                errorRecords.forEach(function(error) {
                                    let same = true;
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

                if (!$A.util.isEmpty(returnValue.existingData)) {
                    const config = cmp.get("v.permissionConfig");
                    const NAMESPACE = cmp.get("v.packageNamespace");
                    let partialSaveMessage;
                    if (!$A.util.isEmpty(config[NAMESPACE+'Partial_Save_Message__c'])){
                        partialSaveMessage = config[NAMESPACE+'Partial_Save_Message__c'];
                    } else {
                        partialSaveMessage = "Your permissions were saved successfully. However, we were unable to map all saved permissions into the table. Please refresh the page to view the updated table.";
                    }

                    try {
                        const selectedObjectMap = cmp.get("v.selectedObjectMap");
                        for (let objName in selectedObjectMap) {
                            selectedObjectMap[objName] = [];
                        }
                        cmp.set("v.selectedObjectMap", selectedObjectMap);
                        cmp.set("v.existingPermissions", JSON.parse(returnValue.existingData));
                        self.loadExistingPermissionsIntoTable(cmp);

                        toastEvent.setParams({
                            "type":"success",
                            "title": "Success!",
                            "message": returnValue.successMsg
                        });
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
                const unsaved = cmp.find("unsaved");
                unsaved.setUnsavedChanges(false);
                toastEvent.fire();
            } else {
                console.log(response.getError());
                const unsaved = cmp.find("unsaved");
                unsaved.setUnsavedChanges(true);
            }

            setTimeout(function() {
                cmp.set("v.showSpinner", false);
            });
        });
        if ($A.util.isEmpty(updatePmsList) && $A.util.isEmpty(insertPmsList)) {
            const toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type":"warning",
                "title": "No changes were detected",
                "mode":"sticky",
                "message": "Please make changes to the permissions first prior to saving."
            });
            toastEvent.fire();
            setTimeout(function() {
                cmp.set("v.showSpinner", false);
            });
        } else {
            if (confirm('Saving will update all changed permissions. Are you sure you want to save?')) {
                $A.enqueueAction(saveAction);
            } else {
                setTimeout(function() {
                    cmp.set("v.showSpinner", false);
                });
            }
        }
    },

    /* Pre-pop table */
    queryAdditionalPermissions : function(cmp, lowerBound) {
        cmp.set("v.showSpinner", true);
        console.log("----------------- queryAdditionalPermissions()");
        var self = this;
        var NAMESPACE = cmp.get("v.packageNamespace");
        var queryAction = cmp.get("c.loadAdditionalPermissions");
        var params = {
            "parentRecordId" : cmp.get("v.parentId"),
            "childId" : cmp.get("v.recordId"),
            "widgets" : JSON.stringify(cmp.get("v.widgets")),
            "config" : JSON.stringify(cmp.get("v.permissionConfig")),
            "lowerBound" : JSON.stringify(lowerBound),
            "selectedIdMap" : JSON.stringify(cmp.get("v.selectedIdMap"))
        };
        console.log(params);
        queryAction.setParam("params", params);
        queryAction.setCallback(this, function(response) {
            console.log("PermissionEdit_Controller.loadAdditionalPermissions() " + response.getState());
            if (response.getState() === "SUCCESS") {
                var returnValue = response.getReturnValue();
                self.logReturnValues(returnValue);

                cmp.set("v.existingPermissions", JSON.parse(returnValue.existingData));
                self.loadExistingPermissionsIntoTable(cmp);

                if ($A.util.isEmpty(returnValue.pmsQueryOrderValues)) {
                    cmp.set("v.disableNextBtn", true);
                } else {
                    cmp.set("v.disableNextBtn", false);
                    self.setupPagination(cmp, JSON.parse(returnValue.pmsQueryOrderValues));
                }
            } else {
                console.log(response.error);
            }

            setTimeout(function() {
                cmp.set("v.showSpinner", false);
            });
        });
        $A.enqueueAction(queryAction);
    },

    loadExistingPermissionsIntoTable : function(cmp) {
        console.log("----------------- loadExistingPermissionsIntoTable()");
        var self = this;
        let existingPermissions = cmp.get("v.existingPermissions");
        console.log(existingPermissions.length);

        if (!$A.util.isEmpty(existingPermissions)) {
            //var cellCounter = 0;
            //var preloadLimit = cmp.get("v.cellLimit") * 2;
            const sObjectNames = cmp.get("v.sObjectNames");
            const pmsFieldNames = cmp.get("v.pmsFieldNames");
            const rowHeaderFields = cmp.get("v.rowHeaderFields");
            const selectedObjectMap = cmp.get("v.selectedObjectMap");
            const securityFields = cmp.get("v.securityFields");
            for (let key in selectedObjectMap) {
                selectedObjectMap[key] = [];
            }

            let newRowMap = {};
            let existingRowMap = {};

            existingPermissions.forEach(function(permission) {
                let keyId = permission[pmsFieldNames[0]];
                if ($A.util.isEmpty(newRowMap[keyId])) {
                    console.log("New Key Object: ");
                    newRowMap[keyId] = {};
                }
                let subRecords = JSON.parse(cmp.get("v.rowObjectJSON")).subRecords;
                for (let i = 0; i < pmsFieldNames.length; i++) {
                    let newItem;
                    if ($A.util.isEmpty(permission[pmsFieldNames[i]])) {
                        newItem = self.generateSelectItem(sObjectNames[i], "", "");
                    } else {
                        newItem = self.generateSelectItem(sObjectNames[i], pmsFieldNames[i], permission);
                    }
                    newItem.source = "Permission";
                    newItem.selected = true;
                    if (i > 0) {
                        self.populateRelatedItems(subRecords, rowHeaderFields, permission, null, cmp.get("v.relatedDataFields"));
                        const subIndex = rowHeaderFields.indexOf(pmsFieldNames[i]);
                        if (subIndex >= 0) {
                            subRecords[subIndex] = self.generateNewObjectWrapper(newItem);
                        }
                    }
                    if (!self.itemAlreadyExist(selectedObjectMap, newItem)) {
                        selectedObjectMap[newItem.objName].push(newItem);
                    }
                }

                //Set security value for subRecords
                for (let i = 0; i < subRecords.length; i++) {
                    if (!$A.util.isEmpty(securityFields[i+1])) {
                        self.populateSecurityValues(subRecords[i], permission, securityFields[i+1]);
                    }
                }

                const rowId = self.generateRowId(subRecords, keyId);
                //console.log($A.util.isEmpty(newRowMap[keyId][rowId]) + " " + rowId);
                if ($A.util.isEmpty(newRowMap[keyId][rowId])) {
                    newRowMap[keyId][rowId] = JSON.parse(cmp.get("v.rowObjectJSON"));
                    newRowMap[keyId][rowId].rowId = rowId;
                    newRowMap[keyId][rowId].subRecords = subRecords;
                }
                newRowMap[keyId][rowId].pmsList.forEach(function(pms) {
                    if (pms.permission.Permission_Type__c == permission.Permission_Type__c) {
                        pms.permission = permission;
                    } else if ($A.util.isEmpty(pms.permission.Id)) {
                        let clonedPermission = JSON.parse(JSON.stringify(permission));
                        clonedPermission.Status__c = pms.permission.Status__c;
                        clonedPermission.Alert_Status__c = pms.permission.Alert_Status__c;
                        clonedPermission.Permission_Type__c = pms.permission.Permission_Type__c;
                        delete clonedPermission.Id;
                        pms.permission = clonedPermission;
                    }
                });
                if (rowId.split(/\s+/).length > 1) {
                    newRowMap[keyId][rowId].loadedState = "";
                    newRowMap[keyId][rowId].changed = false;
                    newRowMap[keyId][rowId].pmsList.forEach(function(pms) {
                        newRowMap[keyId][rowId].loadedState += pms.permission.Status__c;
                        newRowMap[keyId][rowId].loadedState += pms.permission.Alert_Status__c;
                    });

                    self.setDisableFlagsOnPms(cmp, newRowMap[keyId][rowId]);
                }
            });

            console.log(JSON.parse(JSON.stringify(selectedObjectMap)));
            let keyObjects = [];
            let i = 0;
            for (i = 0; i < selectedObjectMap[sObjectNames[0]].length; i++) {
                self.generatePermissionTable(cmp, keyObjects, selectedObjectMap[sObjectNames[0]][i], newRowMap);
            }
            self.setPermissionControls(cmp, keyObjects);
            cmp.set("v.keyObjects", keyObjects);

            console.log('Setup complete.');
            console.log("----------------- Key Objects:");
            console.log(JSON.parse(JSON.stringify(keyObjects)));
            console.log("-----------------");
        } else {
            cmp.set("v.keyObjects", []);
        }
    },

    loadSavedPermissionsIntoTable : function(cmp) {
        console.log("---------- loadSavedPermissionsIntoTable()");
        var savedPermissions = cmp.get("v.existingPermissions");
        console.log(savedPermissions.length);
        var self = this;

        var existingRowMap = cmp.get("v.existingRowMap");

        var sObjectNames = cmp.get("v.sObjectNames");
        var pmsFieldNames = cmp.get("v.pmsFieldNames");
        var rowHeaderFields = cmp.get("v.rowHeaderFields");

        savedPermissions.forEach(function(permission) {
            //var permission = savedPermissions[pIndex++];
            var keyId = permission[pmsFieldNames[0]];
            var subRecords = JSON.parse(cmp.get("v.rowObjectJSON")).subRecords;
            for (var i = 0; i < pmsFieldNames.length; i++) {
                var newItem;
                if ($A.util.isEmpty(permission[pmsFieldNames[i]])) {
                    newItem = self.generateSelectItem(sObjectNames[i], "", "");
                } else {
                    newItem = self.generateSelectItem(sObjectNames[i], pmsFieldNames[i], permission);
                }
                newItem.source = "Permission";
                newItem.selected = true;
                if (i > 0) {
                    self.populateRelatedItems(subRecords, rowHeaderFields, permission, null, cmp.get("v.relatedDataFields"));
                    var subIndex = rowHeaderFields.indexOf(pmsFieldNames[i]);
                    if (subIndex >= 0) {
                        subRecords[subIndex] = self.generateNewObjectWrapper(newItem);
                    }
                }
            }
            var rowId = self.generateRowId(subRecords, keyId);

            if (!$A.util.isEmpty(existingRowMap[rowId])) {
                existingRowMap[rowId].pmsList.forEach(function(pms) {
                    if (pms.permission.Permission_Type__c === permission.Permission_Type__c) {
                        pms.permission = permission;
                    }
                });
                existingRowMap[rowId].changed = false;
            }
        });
        cmp.set("v.existingRowMap", existingRowMap);

        var keyObjects = cmp.get("v.keyObjects");
        keyObjects.forEach(function(keyObj) {
            keyObj.rows.forEach(function(row) {
                if (!$A.util.isEmpty(existingRowMap[row.rowId])) {
                    row = existingRowMap[row.rowId];
                }
            });
        });
        self.setPermissionControls(cmp, keyObjects);
        cmp.set("v.keyObjects", keyObjects);
    },

    /* Add new row to table */
    generatePermissionTable : function(cmp, keyObjects, selectedItem, newRowMap) {
        console.log('---------- generatePermissionTable()');
        var self = this;
        const sObjectNames = cmp.get("v.sObjectNames");

        if (selectedItem.selected) { //insert new keyObj
            const keyObj = JSON.parse(cmp.get("v.keyObjectJSON"));
            keyObj.record = self.generateNewObjectWrapper(selectedItem);
            keyObj.added = selectedItem.added;
            if (!$A.util.isEmpty(cmp.get("v.securityFields")) && cmp.get("v.securityFields").length > 0) {
                self.populateSecurityValues(keyObj.record, selectedItem.record, cmp.get("v.securityFields")[0]);
            }

            keyObj.rows = [];
            for (let rowId in newRowMap[keyObj.record.recordId]) {
                keyObj.rows.push(newRowMap[keyObj.record.recordId][rowId]);
            }
            keyObjects.push(keyObj);
        }
    },

    refreshTableWithNewSelectedItems : function(cmp) {
        var self = this;
        var NAMESPACE = cmp.get("v.packageNamespace");
        var queryAction = cmp.get("c.loadAdditionalPermissions");
        var params = {
            "parentRecordId" : cmp.get("v.parentId"),
            "childId" : cmp.get("v.recordId"),
            "widgets" : JSON.stringify(cmp.get("v.widgets")),
            "config" : JSON.stringify(cmp.get("v.permissionConfig")),
            "selectedIdMap" : JSON.stringify(cmp.get("v.selectedIdMap"))
        };
        console.log(params);
        queryAction.setParam("params", params);
        queryAction.setCallback(this, function(response) {
            console.log("PermissionEdit_Controller.loadAdditionalPermissions() " + response.getState());
            if (response.getState() === "SUCCESS") {
                var returnValue = response.getReturnValue();
                self.logReturnValues(returnValue);

                cmp.set("v.existingPermissions", JSON.parse(returnValue.existingData));
                self.loadExistingPermissionsIntoTable(cmp);

                cmp.set("v.pageIndex", 0);
                cmp.set("v.disablePreviousBtn", true);
                if ($A.util.isEmpty(returnValue.pmsQueryOrderValues)) {
                    cmp.set("v.disableNextBtn", true);
                } else {
                    cmp.set("v.disableNextBtn", false);
                    self.setupPagination(cmp, JSON.parse(returnValue.pmsQueryOrderValues));
                }
            } else {
                console.log(response.error);
            }

            setTimeout(function() {
                cmp.set("v.showSpinner", false);
            });
        });
        $A.enqueueAction(queryAction);
    },

    /* Set permission switches */
    setPermissionFieldValues : function(pms, fieldName, fieldValue, forceInactive) {
        if (forceInactive) {
            pms.permission[fieldName] = "Inactive";
        } else if (!(pms.disableStatus && fieldName === "Status__c") && !(pms.disableAlert && fieldName === "Alert_Status__c")) {
            pms.permission[fieldName] = fieldValue;
            if (fieldName === "Alert_Status__c" && fieldValue === "Active") {
                if (pms.disableStatus) {
                    if (pms.permission.Status__c === "Inactive") {
                        pms.permission[fieldName] = "Inactive";
                    }
                } else {
                    pms.permission.Status__c = "Active";
                }
            } else if (fieldName === "Status__c" && fieldValue === "Inactive") {
                pms.permission.Alert_Status__c = "Inactive";
            }
        }
    },

    setRowLevelOptions : function(row, optionKey, optionValue, optionIndex, forceInactive) {
        if (!row.disabled) {
            var self = this;
            if (optionIndex < 0) { //Row Option Control
                self.setPermissionFieldValues(row.pmsRowCtrl, optionKey, optionValue, forceInactive);
                row.pmsList.forEach(function (pms) {
                    self.setPermissionFieldValues(pms, optionKey, optionValue, forceInactive);
                });
            } else { //Column Option Control
                self.setPermissionFieldValues(row.pmsList[optionIndex], optionKey, optionValue, forceInactive);
            }
            
            var newState = "";
            row.pmsList.forEach(function(pms) {
                newState += pms.permission.Status__c;
                newState += pms.permission.Alert_Status__c;
            });
            
            row.changed = (newState !== row.loadedState);
            row.error = false;
            row.saved = false;
        }
    },

    setKeyLevelOptions : function(keyObj, optionKey, optionValue, optionIndex, forceInactive) {
        var self = this;
        if (optionIndex < 0) { //Row Option Control
            self.setPermissionFieldValues(keyObj.pmsRowCtrl, optionKey, optionValue, forceInactive);
            keyObj.pmsList.forEach(function(pms) {
                self.setPermissionFieldValues(pms, optionKey, optionValue, forceInactive);
            });
            keyObj.rows.forEach(function(row) {
                self.setRowLevelOptions(row, optionKey, optionValue, optionIndex, forceInactive);
            });
        } else { //Column Option Control
            self.setPermissionFieldValues(keyObj.pmsList[optionIndex], optionKey, optionValue, forceInactive);
            keyObj.rows.forEach(function(row) {
                self.setRowLevelOptions(row, optionKey, optionValue, optionIndex, forceInactive);
            });
        }
    },

    setPermissionControls : function(cmp, keyObjects) {
        const self = this;
        console.log('setting permision controls');
        //var initialOption = keyObjects.length > 0 ? "Active" : "Inactive";
        let masterPmsList = cmp.get("v.masterPmsList");
        for (let i = 0; i < masterPmsList.length; i++) {
            masterPmsList[i].disableStatus = true;
            masterPmsList[i].disableAlert = true;
            masterPmsList[i].countActiveStatus = 0;
            masterPmsList[i].countActiveAlert = 0;
            masterPmsList[i].totalStatus = 0;
            masterPmsList[i].totalAlert = 0;
        }

        for (let i = 0; i < keyObjects.length; i++) {
            let keyObj = keyObjects[i];
            keyObj.pmsRowCtrl.disableStatus = true;
            keyObj.pmsRowCtrl.disableAlert = true;

            keyObj.pmsRowCtrl.countActiveStatus = 0;
            keyObj.pmsRowCtrl.countActiveAlert = 0;
            keyObj.pmsRowCtrl.totalStatus = keyObj.rows.length * keyObj.pmsList.length;
            keyObj.pmsRowCtrl.totalAlert = keyObj.rows.length * keyObj.pmsList.length;

            for (let j = 0; j < keyObj.pmsList.length; j++) {
                keyObj.pmsList[j].disableStatus = true;
                keyObj.pmsList[j].disableAlert = true;

                keyObj.pmsList[j].countActiveStatus = 0;
                keyObj.pmsList[j].countActiveAlert = 0;
                keyObj.pmsList[j].totalStatus = keyObj.rows.length;
                keyObj.pmsList[j].totalAlert = keyObj.rows.length;
            }

            for (let j = 0; j < masterPmsList.length; j++) {
                masterPmsList[j].totalStatus += keyObj.rows.length;
                masterPmsList[j].totalAlert += keyObj.rows.length;
            }

            for (let j = 0; j < keyObj.rows.length; j++) {
                let row = keyObj.rows[j];
                row.pmsRowCtrl.countActiveStatus = 0;
                row.pmsRowCtrl.countActiveAlert = 0;
                row.pmsRowCtrl.totalStatus = row.pmsList.length;
                row.pmsRowCtrl.totalAlert = row.pmsList.length;
                row.pmsRowCtrl.disableStatus = true;
                row.pmsRowCtrl.disableAlert = true;
                for (let k = 0; k < row.pmsList.length; k++) {
                    if (row.pmsList[k].disableAlert) {
                        keyObj.pmsList[k].totalAlert -= 1;
                        row.pmsRowCtrl.totalAlert -= 1;
                        keyObj.pmsRowCtrl.totalAlert -= 1;
                        masterPmsList[k].totalAlert -= 1;
                    } else {
                        if (row.pmsList[k].permission.Alert_Status__c === "Active") {
                            keyObj.pmsList[k].countActiveAlert += 1;
                            keyObj.pmsRowCtrl.countActiveAlert += 1;
                            row.pmsRowCtrl.countActiveAlert += 1;
                            masterPmsList[k].countActiveAlert += 1;
                        }

                        row.pmsRowCtrl.disableAlert = false;
                        keyObj.pmsList[k].disableAlert = false;
                        keyObj.pmsRowCtrl.disableAlert = false;
                        masterPmsList[k].disableAlert = false;
                    }

                    if (row.pmsList[k].disableStatus) {
                        keyObj.pmsList[k].totalStatus -= 1;
                        row.pmsRowCtrl.totalStatus -= 1;
                        keyObj.pmsRowCtrl.totalStatus -= 1;
                        masterPmsList[k].totalStatus -= 1;
                    } else {
                        if (row.pmsList[k].permission.Status__c === "Active") {
                            keyObj.pmsList[k].countActiveStatus += 1;
                            keyObj.pmsRowCtrl.countActiveStatus += 1;
                            row.pmsRowCtrl.countActiveStatus += 1;
                            masterPmsList[k].countActiveStatus += 1;
                        }

                        row.pmsRowCtrl.disableStatus = false;
                        keyObj.pmsList[k].disableStatus = false;
                        keyObj.pmsRowCtrl.disableStatus = false;
                        masterPmsList[k].disableStatus = false;
                    }
                }
                self.setPermissionStatusButtonValue(row.pmsRowCtrl);
            }
            self.setPermissionStatusButtonValue(keyObj.pmsRowCtrl);

            for (let j = 0; j < keyObj.pmsList.length; j++) {
                self.setPermissionStatusButtonValue(keyObj.pmsList[j]);
                if (!keyObj.pmsList[j].disableStatus) {
                    masterPmsList[j].disableStatus = false;
                }
                if (!keyObj.pmsList[j].disableAlert) {
                    masterPmsList[j].disableAlert = false;
                }
            }
        }

        for (let i = 0; i < masterPmsList.length; i++) {
            self.setPermissionStatusButtonValue(masterPmsList[i]);
        }
        cmp.set("v.masterPmsList", masterPmsList);
    },

    /* Utilities */
    confirmDiscardChanges : function(keyObjects) {
        var hasChanges = false;
        for (var keyIndex = 0; keyIndex < keyObjects.length; keyIndex++) {
            for (var rowIndex = 0; rowIndex < keyObjects[keyIndex].rows.length; rowIndex++) {
                if (keyObjects[keyIndex].rows[rowIndex].changed) {
                    hasChanges = true;
                    break;
                }
            }
            if (hasChanges) break;
        }
        if (!hasChanges || confirm("All unsaved changes on this page will be lost. Do you want to proceed?")) {
            return true;
        } else {
            return false;
        }
    },

    displayErrorToast: function(cmp, errors){
        var toastParams = {
            title: "Error",
            message: "An unknown error has occurred.", //default message is errors is empty
            type: "error"
        };

        if (errors && Array.isArray(errors) && errors.length > 0) {
            toastParams.message = errors[0].message;
        }else if(errors && errors.startsWith('Invalid access:')){
            toastParams.message = errors;
        }

        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams(toastParams);
        toastEvent.fire();
    },

    generateNewObjectWrapper : function(item) {
        var objWrapper = {
            "recordId" : item.itemValue,
            "label" : item.itemLabel
        };
        return objWrapper;
    },

    generateRowId : function(subRecords, keyRecordId) {
        var rowId = keyRecordId;
        subRecords.forEach(function(subRec) {
            if (!$A.util.isEmpty(subRec.recordId)) {
                rowId += " " + subRec.parentId + " " + subRec.recordId;
            }
        });
        return rowId.trim();
    },

    generateSelectItem : function(objName, pmsFieldName, record) {
        var newItem = {
            "selected" : false,
            "objName" : objName
        };
        if ($A.util.isEmpty(pmsFieldName) || $A.util.isEmpty(record)) {
            newItem.itemLabel = "";
            newItem.itemValue = "";
            newItem.record = {};
            newItem.parentRecord = {};
        } else {
            if (!$A.util.isEmpty(record[pmsFieldName.replace("__c", "__r")])) {
                var subRecord = JSON.parse(JSON.stringify(record[pmsFieldName.replace("__c", "__r")]));
                newItem.itemLabel = subRecord.Name;
                newItem.record = subRecord;
            }

            newItem.parentRecord = record;
            newItem.itemValue = record[pmsFieldName];
        }

        return newItem;
    },

    getSObjectValue: function(record, field){
        if(field.indexOf('.') != -1){
            var childRecordKey = field.substring(0, field.indexOf('.'));
            if(typeof record[childRecordKey] != 'undefined'){
                return this.getSObjectValue(record[childRecordKey], field.substring(field.indexOf('.')+1));
            } else {
                return '';
            }
        } else {
            return record[field];
        }
    },

    itemAlreadyExist : function(selectedObjectMap, item) {
        //console.log("**************************************************");
        //console.log(item);
        var hasItem = false;
        if (!$A.util.isEmpty(selectedObjectMap[item.objName])) {
            selectedObjectMap[item.objName].forEach(function(selectedObj) {
                if (item.itemValue === selectedObj.itemValue) {
                    hasItem = true;
                }
            });
        }
        //console.log(hasItem);
        return hasItem;
    },

    logReturnValues : function(returnValue) {
        console.log("===================== RETURN VALUE");
        for (var returnKey in returnValue) {
            console.log("---------- " + returnKey);
            try {
                console.log(JSON.parse(returnValue[returnKey]));
            } catch (e) {
                console.log(returnValue[returnKey]);
            }
        }
        console.log("==================================");
    },

    populateRelatedItems : function(subRecords, fieldList, record, smartWidgetIndex, parentFieldList) {
        //console.log("******************************************************");
        //console.log(record);
        if (!$A.util.isEmpty(record)) {
            for (var j = 0; j < fieldList.length; j++) {
                if ($A.util.isEmpty(subRecords[j].label) || (smartWidgetIndex != null && (smartWidgetIndex-1) === j)) {
                    try {
                        var newObjWrapper = {};
                        if (typeof fieldList[j] === "string") {
                            newObjWrapper.recordId = record[fieldList[j]];
                            newObjWrapper.label = record[fieldList[j]];
                            newObjWrapper.parentId = record["Id"];
                        } else {
                            var relatedRecord = JSON.parse(JSON.stringify(record));

                            for (var k = 0; k < fieldList[j].length - 1; k++) {
                                if (!$A.util.isEmpty(relatedRecord)) {
                                    relatedRecord = relatedRecord[fieldList[j][k]];
                                }
                            }
                            newObjWrapper.recordId = $A.util.isEmpty(relatedRecord) ? '' : relatedRecord.Id;
                            newObjWrapper.label = $A.util.isEmpty(relatedRecord) ? '' : relatedRecord[fieldList[j][k]];

                            if ($A.util.isEmpty(parentFieldList)) {
                                newObjWrapper.parentId = record[fieldList[j][0]]["Id"];
                            } else {
                                newObjWrapper.parentId = record[parentFieldList[j][0].replace("__r","__c")];
                            }
                            if ($A.util.isEmpty(newObjWrapper.parentId)) {
                                newObjWrapper.parentId = '';
                            }
                        }

                        if (!$A.util.isEmpty(newObjWrapper.label) && !$A.util.isEmpty(newObjWrapper.recordId)) {
                            subRecords[j] = newObjWrapper;
                        }
                    } catch (e) {
                        console.log("Ignoring related data field mapping index: " + fieldList[j]);
                    }
                }
            }
        }
        //console.log(subRecords);
    },

    populateRelatedSecurityValues : function(subRecords, nestedFieldList, record) {
        if (!$A.util.isEmpty(record)) {
            for (var i = 0; i < subRecords.length; i++) {
                if (nestedFieldList.length > (i+1)) {
                    try {
                        var value = JSON.parse(JSON.stringify(record));
                        nestedFieldList[i+1].forEach(function(fieldName) {
                            value = value[fieldName];
                        });
                        subRecords[i].securityValue = value;
                    } catch (e) {
                        subRecords[i].securityValue = "";
                    }
                }
            }
        }
    },

    populateSecurityValues : function(objWrapper, record, nestedFieldList) {
        if (!$A.util.isEmpty(record) && !$A.util.isEmpty(nestedFieldList)) {
            if (!$A.util.isEmpty(record[nestedFieldList[0]])) {
                let value = JSON.parse(JSON.stringify(record));
                nestedFieldList.forEach(function(fieldName) {
                    value = value[fieldName];
                });
                objWrapper.securityValue = value;
            }
        }
    },

    setDisableFlagsOnPms : function(cmp, row) {
        var readOnly = cmp.get('v.readOnly');
        var rowDisabled = false;
        if (cmp.get("v.enableRowSecurity")) {
            row.subRecords.forEach(function(subRec) {
                if (!$A.util.isEmpty(subRec.securityValue)) {
                    rowDisabled = rowDisabled || !cmp.get("v.securityGroups").includes(subRec.securityValue) || readOnly;
                }
            });
            row.disabled = rowDisabled;
        }

        //Column security
        row.pmsList.forEach(function(pms) {
            pms.disableAlert = rowDisabled;
            pms.disableStatus = rowDisabled;
            if (!rowDisabled) {
                if (pms.enableSecurityDocument) {
                    pms.disableStatus = true;
                    cmp.get("v.customPmsAPINames").forEach(function(customPms) {
                        pms.disableStatus = pms.disableStatus && !pms.documentEditPermissions.includes(customPms+';') || readOnly;
                    });
                } else {
                    pms.disableStatus = false;
                }
                if (pms.enableSecurityNotification) {
                    pms.disableAlert = true;
                    cmp.get("v.customPmsAPINames").forEach(function(customPms) {
                        pms.disableAlert = pms.disableAlert && !pms.notificationEditPermissions.includes(customPms+';') || readOnly;
                    });
                } else {
                    pms.disableAlert = false;
                }
            }

            if (pms.disableStatus && pms.permission[cmp.get("v.packageNamespace") + 'Status__c'] === 'Inactive'
                && pms.permission[cmp.get("v.packageNamespace") + 'Alert_Status__c'] === 'Inactive') {
                pms.disableAlert = true;
            }
        });
    },

    setPermissionStatusButtonValue : function(pms) {
        pms.permission.Status__c = pms.countActiveStatus === pms.totalStatus ? "Active" : "Inactive";
        pms.permission.Alert_Status__c = pms.countActiveAlert === pms.totalAlert ? "Active" : "Inactive";
    },

    setSelectedIdMap : function(cmp) {
        const relatedCmps = cmp.find("related-multi-select");
        if (!$A.util.isEmpty(relatedCmps)) {
            let selectedIdMap = {};
            for (let i = 0; i < relatedCmps.length; i++) {
                const options = relatedCmps[i].get("v.options");
                let selectedIds = [];
                for (let o = 0; o < options.length; o++) {
                    if (options[o].selected) {
                        selectedIds.push(options[o].id);
                    }
                }
                selectedIdMap[relatedCmps[i].get("v.widget.Id")] = selectedIds;
            }
            console.log(selectedIdMap);
            cmp.set("v.selectedIdMap", selectedIdMap);
        }
    },

    setTableSize : function(cmp) {
        var cellPerRow = (cmp.get("v.enableAlerts") ? 2 : 1) * cmp.get("v.permissionTypes").length;
        if (cellPerRow > 20) {
            cmp.set("v.colSizeLeft", "slds-size_1-of-3");
            cmp.set("v.colSizeRight", "slds-size_2-of-3");
        } else if (cellPerRow > 16) {
            cmp.set("v.colSizeLeft", "slds-size_5-of-12");
            cmp.set("v.colSizeRight", "slds-size_7-of-12");
        }
    },

    setupPagination : function(cmp, pmsQueryOrderValues) {
        console.log("---------- setupPagination()");
        console.log(pmsQueryOrderValues);

        var pageList = cmp.get("v.pageList");
        var pageIndex = cmp.get("v.pageIndex");

        if (pageIndex >= pageList.length) {
            pageList.push({
                "pmsQueryOrderValues" : pmsQueryOrderValues
            });
        }

        cmp.set("v.pageList", pageList);
    }
})