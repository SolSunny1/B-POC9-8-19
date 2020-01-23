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

        var self = this;

        self.initializePermissionManager(cmp).then(
            $A.getCallback(
                function(returnValue){
                    self.initTable(cmp, returnValue);
                    self.initRelatedSelect(cmp);
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
        ).finally(function() {
            setTimeout(function() {
                cmp.set("v.showSpinner", false);
            });
        })
    },

    initTable: function(cmp, returnValue) {
        var self = this;
        const NAMESPACE = cmp.get("v.packageNamespace");
        self.logReturnValues(returnValue);

        const permissionConfig = JSON.parse(returnValue.config);
        cmp.set("v.componentId", "PermissionEdit_" + permissionConfig.Id);
        cmp.set("v.permissionConfig", permissionConfig);
        cmp.set("v.widgets",JSON.parse(returnValue.widgets));
        cmp.set("v.incompleteRelatedMultiSelect", cmp.get("v.widgets").length);
        cmp.set("v.parentId",returnValue.parentRecordId);
        cmp.set("v.isSandbox", returnValue.isSandbox == "true" ? true : false);
        cmp.set("v.enableAlerts", permissionConfig[NAMESPACE + 'Display_Alert_Icons__c']);
        cmp.set("v.readOnly", returnValue.readOnly == "true"? true:false);
        cmp.set("v.permissionLabel",JSON.parse(returnValue.permissionLabel));
        cmp.set("v.iconName",JSON.parse(returnValue.recordIcon));

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
            var permissionTypes = JSON.parse(returnValue.permissionTypesJSON);
            cmp.set("v.permissionTypes", permissionTypes);
            if (permissionTypes.length > 8) {
                cmp.set("v.colSizeRight", "permission-button-section");
            }
            cmp.set("v.permissionTypeWidth", (Math.floor(100 / permissionTypes.length) + "%"));

            var headerAngle = permissionConfig[NAMESPACE + 'Header_Angle__c'];
            if (!$A.util.isEmpty(headerAngle) && headerAngle > 0) {
                var longestLength = 1;
                permissionTypes.forEach(function(pt) {
                    if (pt.Name.length > longestLength) {
                        longestLength = pt.Name.length;
                    }
                });
                var tableHeight = (Math.abs(longestLength * 6.5 * Math.sin(Math.PI * headerAngle / 180.0)) + 32);
                cmp.set("v.tableHeaderHeight", Math.floor(tableHeight) + "px");
                cmp.set("v.pmsTypeLabelTranslate", "transform:translate(40%," + Math.floor(tableHeight/2 - 10) + "px);");
                cmp.set("v.pmsTypeLabelWidth", Math.floor(longestLength * 8) + "px");
            }
        }
        if (!$A.util.isEmpty(returnValue.sObjectNamesJSON)) {
            cmp.set("v.sObjectNames", JSON.parse(returnValue.sObjectNamesJSON));
            cmp.set("v.sObjectLabels", JSON.parse(returnValue.sObjectLabelsJSON));
            cmp.set("v.pmsFieldNames", JSON.parse(returnValue.pmsFieldNamesJSON));

            var selectedObjectMap = {};
            cmp.get("v.sObjectNames").forEach(function(objName) {
                selectedObjectMap[objName] = [];
            });
            cmp.set("v.selectedObjectMap", selectedObjectMap);
            console.log("---------- selectedObjectMap");
            console.log(selectedObjectMap);
        }
        if (!$A.util.isEmpty(returnValue.pmsCtrlWrappersJSON)) {
            cmp.set("v.masterPmsList", JSON.parse(returnValue.pmsCtrlWrappersJSON));
        }

        var rowHeaders = [];
        if (!$A.util.isEmpty(permissionConfig[NAMESPACE + 'Headers__c'])) {
            permissionConfig[NAMESPACE + 'Headers__c'].split(";").forEach(function(headerLabel) {
                rowHeaders.push(headerLabel.trim());
            });
            rowHeaders.splice(0, 1);
        } else {
            var sObjectLabels = cmp.get("v.sObjectLabels");
            for (var i = 1; i < sObjectLabels.length; i++) {
                rowHeaders.push(sObjectLabels[i]);
            }
        }
        cmp.set("v.rowHeaders", rowHeaders);
        console.log("---------- rowHeaders");
        console.log(rowHeaders);

        if (!$A.util.isEmpty(permissionConfig[NAMESPACE + 'Columns__c'])) {
            var rowHeaderFields = [];
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
            var relatedDataFields = [];
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
            var securityFields = [];
            var psfIndex = 0;
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

        cmp.set("v.showSpinner", false);
        cmp.set("v.pageIndex", 0);
        cmp.set("v.pageList", []);
        self.setTableSize(cmp);
        console.log("END initTable()");
    },

    initializePermissionManager : function(cmp) {
        var initAction = cmp.get("c.initializeComponent_AddMode");
        initAction.setParam("params",{
            "configurationName":cmp.get("v.permissionConfigName"),
            "recordId":cmp.get("v.recordId"),
            // "defaultPermissionColumns":cmp.get("v.defaultPermissionColumns"),
            "defaultedPermissionTypes":cmp.get("v.defaultedPermissionTypes")
        });

        return this.serverSideCall(cmp, initAction);
    },

    initRelatedSelect: function(cmp) {
        var widgets = cmp.get("v.widgets");
        var relatedRecordDefaults = cmp.get("v.relatedRecordDefaults");
        var widgetWrapper = [];
        for(var i=0;i<widgets.length;i++){
            var ww = {};
            ww.widget = widgets[i];
            //ww.defaults = relatedRecordDefaults[widgets[i].Id];
            widgetWrapper.push(ww);
        }
        cmp.set("v.relatedSelectionData", widgetWrapper);
        //cmp.set("v.readOnly", false);
        cmp.set("v.disableSaveButton", false);
    },

    serverSideCall: function(cmp, action){
        console.log('Making server call to: ');
        console.log(action);
        return new Promise(
            $A.getCallback(
                function(resolve, reject){
                    action.setCallback(this,
                        function(response){
                            var state = response.getState();
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

    /* Save Permissions */
    savePermissionsAction : function(cmp) {
        console.log("---------- savePermissionsAction()");
        var self = this;
        const NAMESPACE = cmp.get("v.packageNamespace");
        const saveAction = cmp.get("c.insertNewPermissions");
        const permissionList = [];
        const saveMode = cmp.get("v.permissionConfig.Save_Mode__c");
        const rowHeaderFields = cmp.get("v.rowHeaderFields");
        const oldSavePageIndex = cmp.get("v.savePageIndex");
        const relatedDataFields = cmp.get("v.relatedDataFields");

        for (let pIndex = cmp.get("v.savePageIndex"); pIndex < cmp.get("v.pageList").length; pIndex++) {
            const keyObjects = cmp.get("v.pageList")[pIndex].keyObjects;
            for (let keyIndex = 0; keyIndex < keyObjects.length; keyIndex++) {
                for (let rowIndex = 0; rowIndex < keyObjects[keyIndex].rows.length; rowIndex++) {
                    const row = keyObjects[keyIndex].rows[rowIndex];

                    for (let pmsIndex = 0; pmsIndex < row.pmsList.length; pmsIndex++) {
                        const pms = row.pmsList[pmsIndex];
                        for (let subIndex = 0; subIndex < row.subRecords.length; subIndex++) {
                            if (rowHeaderFields[subIndex].length <= 2 && $A.util.isEmpty(pms.permission[rowHeaderFields[subIndex][0].replace('__r', '__c')])) {
                                pms.permission[rowHeaderFields[subIndex][0].replace('__r', '__c')] = row.subRecords[subIndex].recordId;
                            }
                            if (!$A.util.isEmpty(row.subRecords[subIndex].parentId) && !$A.util.isEmpty(relatedDataFields[subIndex]) && relatedDataFields[subIndex].length > 1) {
                                pms.permission[relatedDataFields[subIndex][0].replace('__r', '__c')] = row.subRecords[subIndex].parentId;
                            }
                        }

                        if (!(pms.disableStatus && pms.disableAlert)) {
                            if (pms.permission.Status__c === "Active" || pms.permission.Alert_Status__c === "Active") {
                                permissionList.push(pms.permission);
                            }
                        }
                    }
                }
            }
            if (permissionList.length >= cmp.get("v.insertLimit")) {
                cmp.set("v.savePageIndex", pIndex + 1);
                pIndex = cmp.get("v.pageList").length;
            }
        }
        if (permissionList.length < cmp.get("v.insertLimit")) {
            cmp.set("v.savePageIndex", 0);
        }

        console.log("Page Index: " + cmp.get("v.savePageIndex"));
        console.log(permissionList);

        if (!cmp.get("v.enableAlerts")) {
            permissionList.forEach(function(permission) {
                delete permission.Alert_Status__c;
            });
        }

        const params = {
            "pmsListJSON" : JSON.stringify(permissionList),
            "pmsFieldNamesJSON" : JSON.stringify(cmp.get("v.pmsFieldNames"))
        };
        saveAction.setParam("params", params);
        saveAction.setCallback(this, function(response) {
            const state = response.getState();
            console.log("PermissionEdit_Controller.insertNewPermissions(): " + response.getState());

            let callAdditionalInsertion = false;
            let returnValue = {};
            if (state === "SUCCESS") {
                returnValue = response.getReturnValue();
                self.logReturnValues(returnValue);
                cmp.set("v.saveProcessErrorMsg", "");
                cmp.set("v.numberOfProcessedRecords", cmp.get("v.numberOfProcessedRecords") + permissionList.length);
                cmp.set("v.numberOfRecordsCreated", cmp.get("v.numberOfRecordsCreated") + parseInt(returnValue.successCountJSON));
                callAdditionalInsertion = cmp.get("v.savePageIndex") > 0;
            } else {
                const error = response.getError()[0];
                console.log(error);
                if (error.exceptionType == "System.LimitException") {
                    callAdditionalInsertion = true;
                    cmp.set("v.insertLimit", Math.floor(cmp.get("v.insertLimit") / 2));
                    cmp.set("v.savePageIndex", oldSavePageIndex);
                    cmp.set("v.saveProcessErrorMsg", "A Limit Exception has occurred due to high amount of permissions being created. System will try to save again with new limit: " + cmp.get("v.insertLimit"));
                }
            }

            console.log("Call More Insert: " + callAdditionalInsertion);
            if (callAdditionalInsertion) {
                cmp.set("v.saveProgressValue", Math.ceil(cmp.get("v.savePageIndex") * 100 / cmp.get("v.pageList").length));
                var smartEvent = $A.get("e.c:SmartEvent");
                smartEvent.setParams({
                    "typeOfOperation" : "INSERT_NEW_PERMISSIONS",
                    "sender" : cmp.get("v.permissionConfig.Id"),
                    "receiver" : cmp.get("v.permissionConfig.Id")
                });
                setTimeout(function() {
                    smartEvent.fire();
                });
            } else {
                const toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type":"success",
                    "title": "Success!",
                    "message": returnValue.successMsg
                });
                toastEvent.fire();

                cmp.set("v.saveProgressValue", 100);
                cmp.set("v.savePageIndex", 0);

                const unsaved = cmp.find("unsaved");
                if (!$A.util.isEmpty(unsaved)) {
                    unsaved.setUnsavedChanges(false);
                }
                setTimeout(function() {
                    /*cmp.set("v.showSaveProgressModal", false);
                    cmp.set("v.saveProgressValue", 0);
                    cmp.set("v.numberOfProcessedRecords", 0);
                    cmp.set("v.numberOfRecordsCreated", 0);
                    cmp.set("v.selectedTab", "select");
                    cmp.set("v.keyObjects", []);*/
                    const navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({"recordId" : cmp.get("v.recordId")});
                    navEvt.fire();
                }, 2000);
            }
        });
        $A.enqueueAction(saveAction);
    },

    /* Add new row to table */
    generatePermissionsForPreview : function(cmp) {
        var self = this;
        if (self.selectedObjectMapHasEmptyList(cmp, "Please select at least one ")) {
            cmp.set("v.keyObjects", []);
            cmp.set("v.selectedTab", "select");
            setTimeout(function() {
                cmp.set("v.showSpinner", false);
            });
            return false;
        } else {
            self.setupPagination(cmp);
            self.generatePermissionTable(cmp);
            cmp.set("v.keyObjects", cmp.get("v.pageList")[0].keyObjects);
        }

        setTimeout(function() {
            cmp.set("v.showSpinner", false);
        });
        return true;
    },

    generatePermissionTable : function(cmp) {
        console.log('---------- generatePermissionTable()');
        var self = this;
        const sObjectNames = cmp.get("v.sObjectNames");
        const selectedObjectMap = cmp.get("v.selectedObjectMap")

        let pageList = cmp.get("v.pageList");
        for (let pIndex = 0; pIndex < pageList.length; pIndex++) {
            let keyObjects = [];
            for (let kIndex = pageList[pIndex][sObjectNames[0]].start; kIndex < pageList[pIndex][sObjectNames[0]].end; kIndex++) {
                let keyObj = JSON.parse(cmp.get("v.keyObjectJSON"));
                let keyItem = selectedObjectMap[sObjectNames[0]][kIndex];
                keyObj.record = self.generateNewObjectWrapper(keyItem);
                if (!$A.util.isEmpty(cmp.get("v.securityFields")) && cmp.get("v.securityFields").length > 0) {
                    self.populateSecurityValues(keyObj.record, keyItem.record, cmp.get("v.securityFields")[0]);
                }
                self.processKeyObject(cmp, keyObj, selectedObjectMap, sObjectNames, pageList[pIndex]);
                keyObjects.push(keyObj);
            }
            pageList[pIndex].keyObjects = keyObjects;
        }
        if (pageList.length > 0) {
            self.setPermissionControls(cmp, pageList[0].keyObjects);
        }
        //console.log(pageList);
        cmp.set("v.pageList", pageList);
    },

    processKeyObject : function(cmp, keyObj, selectedObjectMap, sObjectNames, page) {
        console.log('---------- processKeyObject()');
        var self = this;
        const NAMESPACE = cmp.get("v.packageNamespace");
        const pmsFieldNames = cmp.get("v.pmsFieldNames");
        const masterPmsList = cmp.get("v.masterPmsList");
        const userSecurityKeys = cmp.get("v.securityGroups");
        const securityFields = cmp.get("v.securityFields");
        const relatedDataFields = cmp.get("v.relatedDataFields");

        keyObj.rows = [];
        let rows = [cmp.get("v.rowObjectJSON")];

        for (let oIndex = 1; oIndex < sObjectNames.length; oIndex++) {
            let tempRows = [];
            for (let rIndex = 0; rIndex < rows.length; rIndex++) {
                for (let objIndex = page[sObjectNames[oIndex]].start; objIndex < page[sObjectNames[oIndex]].end; objIndex++) {
                    let selectedObj = selectedObjectMap[sObjectNames[oIndex]][objIndex];
                    //console.log(JSON.parse(JSON.stringify(selectedObj)));
                    let clonedRow = JSON.parse(rows[rIndex]);

                    self.populateRelatedItems(clonedRow.subRecords, relatedDataFields, selectedObj.record, oIndex);
                    self.populateRelatedSecurityValues(clonedRow.subRecords, securityFields, selectedObj.record);

                    if (securityFields.length > oIndex) {
                        self.populateSecurityValues(clonedRow.subRecords[oIndex - 1], selectedObj.record, securityFields[oIndex]);
                    }
                    //const rowId = self.generateRowId(clonedRow.subRecords, keyObj.record.recordId);

                    clonedRow.pmsList.forEach(function (pms) {
                        pms.permission[pmsFieldNames[oIndex]] = selectedObj.itemValue;
                        pms.permission[pmsFieldNames[0]] = keyObj.record.recordId;
                    });

                    tempRows.push(JSON.stringify(clonedRow));
                }
            }

            if (tempRows.length > 0) {
                rows = tempRows;
            }
        }

        for (let rIndex = 0; rIndex < rows.length; rIndex++) {
            let parsedRow = JSON.parse(rows[rIndex]);
            //Generate rowId
            const rowId = self.generateRowId(parsedRow.subRecords, keyObj.record.recordId);
            //console.log(rowId);
            if (rowId.split(/\s+/).length >= cmp.get("v.sObjectNames").length-1) {
                parsedRow.rowId = rowId;
                if (!cmp.get("v.userIsAdmin")) {
                    self.setDisableFlagsOnPms(cmp, parsedRow);
                }
                keyObj.rows.push(parsedRow);
            }
        }
        console.log(JSON.parse(JSON.stringify(keyObj)));
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
            if (forceInactive) {
                //row.loadedState = newState + "";
            }
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
            "recordId" : item.id,
            "label" : item.label
        };
        return objWrapper;
    },

    generateRowId : function(subRecords, keyRecordId) {
        var rowId = keyRecordId;
        subRecords.forEach(function(subRec) {
            if (!$A.util.isEmpty(subRec.recordId)) {
                rowId += " " + subRec.recordId;
            }
        });
        return $A.util.isEmpty(rowId) ? "" : rowId.trim();
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
        try {
            selectedObjectMap[item.objName].forEach(function(selectedObj) {
                if (item.itemValue === selectedObj.itemValue) {
                    hasItem = true;
                }
            });
        } catch (e) {
            console.log(e);
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

    paginationChangePage : function(cmp) {
        this.setPermissionControls(cmp, cmp.get("v.pageList")[cmp.get("v.pageIndex")].keyObjects);
        cmp.set("v.keyObjects", cmp.get("v.pageList")[cmp.get("v.pageIndex")].keyObjects);
        window.scrollTo({top: 0});
        setTimeout(function() {
            cmp.set("v.showSpinner", false);
        });
    },

    populateRelatedItems : function(subRecords, fieldList, record, smartWidgetIndex) {
        //console.log("******************************************************");
        //console.log(record);
        if (!$A.util.isEmpty(record)) {
            for (let j = 0; j < fieldList.length; j++) {
                if ($A.util.isEmpty(subRecords[j].label) || (smartWidgetIndex != null && (smartWidgetIndex-1) === j)) {
                    try {
                        let newObjWrapper = {"parentId" : record.Id};
                        if (typeof fieldList[j] === "string") {
                            newObjWrapper.recordId = record[fieldList[j]];
                            newObjWrapper.label = record[fieldList[j]];
                        } else {
                            let relatedRecord = JSON.parse(JSON.stringify(record));
                            let k = 1;
                            for (k = 1; k < fieldList[j].length - 1; k++) {
                                if (!$A.util.isEmpty(relatedRecord)) {
                                    relatedRecord = relatedRecord[fieldList[j][k]];
                                }
                            }
                            newObjWrapper.recordId = $A.util.isEmpty(relatedRecord) ? '' : relatedRecord.Id;
                            newObjWrapper.label = $A.util.isEmpty(relatedRecord) ? '' : relatedRecord[fieldList[j][k]];
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
                var value = JSON.parse(JSON.stringify(record));
                nestedFieldList.forEach(function(fieldName) {
                    value = value[fieldName];
                });
                objWrapper.securityValue = value;
            }
        }
    },

    selectedObjectMapHasEmptyList : function(cmp, errorMsg) {
        var relatedCmps = cmp.find("related-multi-select");
        if (!$A.util.isEmpty(relatedCmps)) {
            var errors = [];
            var selectedObjectMap = {};
            for (var i = 0; i < relatedCmps.length; i++) {
                var objName = relatedCmps[i].get("v.widget.AutoComplete_Search_Object__c");
                selectedObjectMap[objName] = [];
                var options = relatedCmps[i].get("v.options");
                for (var o = 0; o < options.length; o++) {
                    if (options[o].selected) {
                        selectedObjectMap[objName].push(options[o]);
                    }
                }
                if (selectedObjectMap[objName].length <= 0) {
                    errors.push(relatedCmps[i].get("v.widget.Label__c"));
                }
            }

            if (errors.length > 0) {
                //var errorMsg = "Please use the SELECT tab to select at least one ";
                if (errors.length == 2) {
                    errorMsg += errors.join(" and ") + ".";
                } else if (errors.length > 2) {
                    errors[errors.length - 1] = "and " + errors[errors.length - 1];
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
                return true;
            } else {
                console.log(selectedObjectMap);
                cmp.set("v.selectedObjectMap", selectedObjectMap);
                return false;
            }
        }
        return true;
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

    setLoadedPermissionState : function(keyObjects) {
        keyObjects.forEach(function(keyObj) {
            keyObj.rows.forEach(function(row) {
                row.loadedState = "";
                row.changed = false;
                row.pmsList.forEach(function(pms) {
                    row.loadedState += pms.permission.Status__c;
                    row.loadedState += pms.permission.Alert_Status__c;
                });
            });
        });
    },

    setPermissionStatusButtonValue : function(pms) {
        pms.permission.Status__c = pms.countActiveStatus === pms.totalStatus ? "Active" : "Inactive";
        pms.permission.Alert_Status__c = pms.countActiveAlert === pms.totalAlert ? "Active" : "Inactive";
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

    setupPagination : function(cmp) {
        console.log("---------- setupPagination()");
        var rowLimit = Math.floor(cmp.get("v.cellLimit") / cmp.get("v.permissionTypes").length);
        var selectedObjectMap = cmp.get("v.selectedObjectMap");
        var sObjectNames = cmp.get("v.sObjectNames");
        var totalCell = cmp.get("v.permissionTypes").length;

        var pageJSON = {};
        for (var i = 0; i < sObjectNames.length; i++) {
            totalCell = totalCell * selectedObjectMap[sObjectNames[i]].length;
            pageJSON[sObjectNames[i]] = {"start":0, "end":selectedObjectMap[sObjectNames[i]].length};
        }

        var pageList = [];
        if (totalCell <= cmp.get("v.cellLimit")) {
            pageList.push(pageJSON);
        } else {
            pageJSON = JSON.stringify(pageJSON);
            var selectedObjSizeMap = {};
            var denominatorMap = {};
            var denominator = 1;
            var listSize = 1;
            var sObjIndex = sObjectNames.length - 1;
            while (sObjIndex >= 0) {
                if (rowLimit <= 1) {
                    selectedObjSizeMap[sObjectNames[sObjIndex]] = 1;
                    denominatorMap[sObjectNames[sObjIndex]] = selectedObjectMap[sObjectNames[sObjIndex]].length;
                    listSize  = listSize * denominatorMap[sObjectNames[sObjIndex]];
                    sObjIndex -= 1;
                } else {
                    if ((selectedObjectMap[sObjectNames[sObjIndex]].length / denominator) > rowLimit) {
                        denominator += 1;
                    } else {
                        denominatorMap[sObjectNames[sObjIndex]] = denominator;
                        listSize  = listSize * denominatorMap[sObjectNames[sObjIndex]];
                        selectedObjSizeMap[sObjectNames[sObjIndex]] = Math.ceil(selectedObjectMap[sObjectNames[sObjIndex]].length / denominator);
                        rowLimit = Math.floor(rowLimit / selectedObjSizeMap[sObjectNames[sObjIndex]]);
                        sObjIndex -= 1;
                        if (sObjIndex >= 0) {
                            denominator = Math.floor(selectedObjectMap[sObjectNames[sObjIndex]].length / rowLimit);
                        } else {
                            denominator = 1;
                        }
                    }
                }

                if (denominator < 1) {
                    denominator = 1;
                }
            }

            console.log("----- selectedObjSizeMap() ----- number of records per page");
            console.log(selectedObjSizeMap);
            console.log("----- denominatorMap()");
            console.log(denominatorMap);

            pageList = new Array(listSize).fill(0);
            var labelLength = listSize.toString().length;

            for (var i = 0; i < sObjectNames.length; i++) {
                var jumpSize = 1;
                for (var j = i+1; j < sObjectNames.length; j++) {
                    jumpSize = jumpSize * denominatorMap[sObjectNames[j]];
                }
                var selectedObjIndex = 0;
                for (var pIndex = 0; pIndex < listSize; pIndex++) {
                    if (pageList[pIndex] === 0) {
                        pageList[pIndex] = JSON.parse(pageJSON);
                        pageList[pIndex].label = "0000" + (pIndex+1);
                        pageList[pIndex].label = pageList[pIndex].label.substr(pageList[pIndex].label.length - labelLength);
                    }
                    pageList[pIndex][sObjectNames[i]].start = selectedObjIndex;
                    pageList[pIndex][sObjectNames[i]].end = selectedObjIndex + selectedObjSizeMap[sObjectNames[i]];

                    if ((pIndex+1) % jumpSize === 0) {
                        selectedObjIndex += selectedObjSizeMap[sObjectNames[i]];
                    }
                    if (selectedObjIndex >= selectedObjectMap[sObjectNames[i]].length) {
                        selectedObjIndex = 0;
                    }
                    if (pageList[pIndex][sObjectNames[i]].end > selectedObjectMap[sObjectNames[i]].length) {
                        pageList[pIndex][sObjectNames[i]].end = selectedObjectMap[sObjectNames[i]].length;
                    }
                }
            }
        }
        console.log(pageList);
        cmp.set("v.pageList", pageList);
    }
})