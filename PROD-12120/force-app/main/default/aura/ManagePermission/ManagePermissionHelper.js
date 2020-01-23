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
                        multiSelectPanelHeight = $('.multiSelectPanel').outerHeight();

                    $window.scroll(function() {
                        if(multiSelectPanelHeight <= 200){
                            multiSelectPanelHeight = $('.multiSelectPanel').outerHeight();
                            tableHeaderTop = $tableHeader.position().top;
                        }

                        var windowScrollTop = $window.scrollTop();
                        var pageHeaderRelPos = 24; //somewhat janky, using this as a constant for the padding around the page (outer page frame + component frame)
                        var tableHeaderRelPos = 24 + multiSelectPanelHeight +14; //2 px for border top/bottom, 12 px for top padding.
                        var pageHeaderIsStuck = $pageHeader.hasClass('sticky');
                        var tableHeaderIsStuck = $tableHeader.hasClass('sticky');

                        if(!pageHeaderIsStuck && windowScrollTop >= pageHeaderRelPos - $pageHeaderOffset) {
                            $headerBuffer.css('height', $pageHeader.outerHeight());
                            $pageHeader.css('top',pageHeaderTop+$pageHeaderOffset);
                        } else if(pageHeaderIsStuck && windowScrollTop < pageHeaderRelPos - $pageHeaderOffset){
                            $headerBuffer.css('height', 0);
                            $pageHeader.css('top',0);
                        }

                        if(!tableHeaderIsStuck && windowScrollTop >= tableHeaderRelPos - $pageHeaderOffset) {
                            console.log('Sticky Clause');
                            $tableBuffer.css('height', $tableHeader.outerHeight());
                            $tableHeader.css('top',tableHeaderTop-multiSelectPanelHeight-14+$pageHeaderOffset); //2 px for border top/bottom, 12 px for top padding.
                        } else if(tableHeaderIsStuck && windowScrollTop < tableHeaderRelPos - $pageHeaderOffset) {
                            console.log('Unsticky Clause');
                            $tableBuffer.css('height', 0);
                            $tableHeader.css('top', 0);
                        }
                        $pageHeader.toggleClass('sticky', windowScrollTop >= pageHeaderRelPos - $pageHeaderOffset);
                        $tableHeader.toggleClass('sticky', windowScrollTop >= tableHeaderRelPos - $pageHeaderOffset);
                    })
                });
            }
        )
    },

    initTable: function(cmp, returnValue){
        var self = this;
        var NAMESPACE = cmp.get("v.packageNamespace");
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

        var permissionConfig = JSON.parse(returnValue.config);
        if (!$A.util.isEmpty(permissionConfig[NAMESPACE + 'Limit_Query__c'])) {
            cmp.set("v.cellLimit", permissionConfig[NAMESPACE + 'Limit_Query__c']);
        }
        if (!$A.util.isEmpty(permissionConfig[NAMESPACE + 'Limit_Pagination__c'])) {
            cmp.set("v.paginationLimit", permissionConfig[NAMESPACE + 'Limit_Pagination__c']);
        }

        cmp.set("v.permissionConfig", permissionConfig);
        cmp.set("v.widgets",JSON.parse(returnValue.widgets));
        cmp.set("v.parentId",returnValue.parentRecordId);
        cmp.set("v.existingPermissions", JSON.parse(returnValue.existingData));
        cmp.set("v.isSandbox", returnValue.isSandbox == "true" ? true : false);
        cmp.set("v.enableAlerts", permissionConfig[NAMESPACE + 'Display_Alert_Icons__c']);
        cmp.set("v.readOnly", returnValue.readOnly == "true"? true:false);
        cmp.set("v.cutoffValues", returnValue.cutOffValues);

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
            //if (permissionTypes.length > 8) {
            //    cmp.set("v.colSizeRight", "permission-button-section");
            //}
            cmp.set("v.permissionTypeWidth", (Math.floor(100 / permissionTypes.length) + "%"));

            var headerAngle = permissionConfig[NAMESPACE + 'Header_Angle__c'];
            if (!$A.util.isEmpty(headerAngle) && headerAngle > 0) {
                var longestLength = 1;
                permissionTypes.forEach(function(pt) {
                    var split = pt.Name.split(' ');
                    var longest = 0;
                    for(var i = 0; i < split.length; i++) {
                        if(split[i].length > longest) {
                            longest = split[i].length;
                        }
                    }
                    if (longest > longestLength) {
                        longestLength = longest;
                    }
                });
                var tableHeight = (Math.abs(longestLength * 6.5 * Math.sin(Math.PI * headerAngle / 180.0)) + 65);
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

        cmp.set("v.pmsOverload", !$A.util.isEmpty(returnValue.pmsOverload));

        cmp.set("v.keyObjectJSON", returnValue.keyObjectJSON);
        cmp.set("v.rowLabelWidth", JSON.parse(returnValue.keyObjectJSON).rowLabelWidth);
        cmp.set("v.rowObjectJSON", returnValue.rowObjectJSON);

        try {
            //cmp.set("v.showSpinner", false);
            cmp.set("v.relatedRecordDefaults", JSON.parse(returnValue.relatedRecordDefaults));
            self.loadExistingPermissionsIntoTable(cmp);
            if (cmp.get("v.paginationList").length < cmp.get("v.paginationLimit") && !$A.util.isEmpty(returnValue.keyFieldName) && !$A.util.isEmpty(returnValue.keyFieldValue)) {
                setTimeout(function() {
                    var loadEvent = $A.get("e.c:SmartEvent");
                    loadEvent.setParams({
                        "value" : true,
                        "typeOfOperation" : "LOAD_REMAINING_PERMISSIONS",
                        "receiver": cmp.get("v.permissionConfigName"),
                        "paramMap" : {
                            "keyFieldName" : returnValue.keyFieldName,
                            "keyFieldValue" : returnValue.keyFieldValue,
                            "parentRecordId" : returnValue.parentRecordId,
                            "childId" : cmp.get("v.recordId"),
                            "widgets" : returnValue.widgets,
                            "config" : returnValue.config,
                            "permissionTypesJSON": returnValue.permissionTypesJSON,
                            "cutOffValues": returnValue.cutOffValues,
                        }
                    });
                    loadEvent.fire();
                }, 1000);
            } else {
                cmp.set("v.pageIsFullyLoaded", true);
                self.initRelatedSelect(cmp);
            }
        } catch (e) {
            console.log(e);
        }
    },

    initializePermissionManager : function(cmp) {
        var initAction = cmp.get("c.initializeComponent");
        initAction.setParam("params",{
            "configurationName":cmp.get("v.permissionConfigName"),
            "recordId":cmp.get("v.recordId"),
            // "defaultPermissionColumns":cmp.get("v.defaultPermissionColumns"),
            "defaultedPermissionTypes":cmp.get("v.defaultedPermissionTypes")
        });

        return this.serverSideCall(cmp, initAction);
    },

    initRelatedSelect: function(cmp){
        console.log("initRelatedSelect(): " + cmp.get("v.pageIsFullyLoaded"));
        if (cmp.get("v.pmsOverload") || cmp.get("v.paginationList").length >= cmp.get("v.paginationLimit")) {
            try {
                var config = cmp.get("v.permissionConfig");
                var NAMESPACE = cmp.get("v.packageNamespace");

                var warningMessage = "For faster loading, please launch the permission screen from the contact or the commitment.";

                if(!$A.util.isEmpty(config[NAMESPACE+'Data_Limit_Warning__c'])){
                    warningMessage = config[NAMESPACE+'Data_Limit_Warning__c'];
                }

                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type":"warning",
                    "title": "High Volume of Permissions Selected",
                    "mode":"sticky",
                    "message": warningMessage
                });
                toastEvent.fire();
            } catch(e) {
                console.log(e);
            }

        }
        var widgets = cmp.get("v.widgets");
        var relatedRecordDefaults = cmp.get("v.relatedRecordDefaults");
        var widgetWrapper = [];
        for(var i=0;i<widgets.length;i++){
            var ww = {};
            ww.widget = widgets[i];
            ww.defaults = relatedRecordDefaults[widgets[i].Id];
            widgetWrapper.push(ww);
        }

        console.log(widgetWrapper);
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

    /* Pre-pop table */
    queryAdditionalPermissions : function(cmp, params) {
        console.log("queryAdditionalPermissions");
        var self = this;
        var NAMESPACE = cmp.get("v.packageNamespace");
        var queryAction = cmp.get("c.loadAdditionalPermissions");
        console.log(params);
        queryAction.setParam("params", params);
        queryAction.setCallback(this, function(response) {
            console.log("ManagePermission_Controller.loadAdditionalPermissions() " + response.getState());
            if (response.getState() === "SUCCESS") {
                var returnValue = response.getReturnValue();
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
                /*var permissionConfig = JSON.parse(returnValue.config);
                if (!$A.util.isEmpty(permissionConfig[NAMESPACE + 'Limit_Query__c'])) {
                    cmp.set("v.cellLimit", permissionConfig[NAMESPACE + 'Limit_Query__c']);
                }
                cmp.set("v.permissionConfig", permissionConfig);*/

                var relatedRecordDefaults = cmp.get("v.relatedRecordDefaults");
                var tempDefaults = JSON.parse(returnValue.relatedRecordDefaults);
                for (var key in tempDefaults) {
                    if ($A.util.isEmpty(relatedRecordDefaults[key])) {
                        relatedRecordDefaults[key] = [];
                    }
                    tempDefaults[key].forEach(function(relatedId) {
                        relatedRecordDefaults[key].push(relatedId);
                    });
                }
                cmp.set("v.relatedRecordDefaults", relatedRecordDefaults);

                /*if (!$A.util.isEmpty(returnValue.overloadKeyObjsJSON)) {
                    var overloadKeyObjs = cmp.get("v.overloadKeyObjs");
                    JSON.parse(returnValue.overloadKeyObjsJSON).forEach(function(keyObjLabel) {
                        overloadKeyObjs.push(keyObjLabel);
                    });
                    cmp.set("v.overloadKeyObjs", overloadKeyObjs);
                }*/
                cmp.set("v.pmsOverload", cmp.get("v.pmsOverload") || !$A.util.isEmpty(returnValue.pmsOverload));

                //self.initRelatedSelect(cmp, JSON.parse(returnValue.widgets), JSON.parse(returnValue.relatedRecordDefaults));
                cmp.set("v.existingPermissions", JSON.parse(returnValue.existingData));
                self.loadRemainingPermissionsIntoTable(cmp);

                if (cmp.get("v.paginationList").length < cmp.get("v.paginationLimit") && !$A.util.isEmpty(returnValue.keyFieldName) && !$A.util.isEmpty(returnValue.keyFieldValue)) {
                    params.keyFieldValue = returnValue.keyFieldValue;
                    params.config = returnValue.config;
                    params.cutOffValues = returnValue.cutOffValues;
                    setTimeout(function() {
                        var loadEvent = $A.get("e.c:SmartEvent");
                        loadEvent.setParams({
                            "value" : true,
                            "typeOfOperation" : "LOAD_REMAINING_PERMISSIONS",
                            "receiver" : cmp.get("v.permissionConfigName"),
                            "paramMap" : params
                        });
                        loadEvent.fire();
                    }, 0);
                } else {
                    //var overloadKeyObjs = cmp.get("v.overloadKeyObjs");
                    cmp.set("v.pageIsFullyLoaded", true);
                    self.initRelatedSelect(cmp);
                }
            } else {
                console.log(response.error);
            }
        });
        $A.enqueueAction(queryAction);
    },

    loadExistingPermissionsIntoTable : function(cmp) {
        console.log("----------------- loadExistingPermissionsIntoTable()");
        var self = this;
        const existingPermissions = cmp.get("v.existingPermissions");
        console.log(existingPermissions.length);

        if (!$A.util.isEmpty(existingPermissions)) {
            let cellCounter = 0;
            //var preloadLimit = cmp.get("v.cellLimit") * 2;
            const sObjectNames = cmp.get("v.sObjectNames");
            const pmsFieldNames = cmp.get("v.pmsFieldNames");
            const rowHeaderFields = cmp.get("v.rowHeaderFields");
            let selectedObjectMap = cmp.get("v.selectedObjectMap");

            let newRowMap = {};
            let existingRowMap = {};
            /*var paginationList = [{
                "label" : "01",
                "keyIndexStart" : 0,
                "keyIndexEnd" : 0
            }];*/

            existingPermissions.forEach(function(permission) {
                const keyId = permission[pmsFieldNames[0]];
                if ($A.util.isEmpty(newRowMap[keyId])) {
                    console.log("New Key Object: ");
                    newRowMap[keyId] = {};
                    //paginationList[0]["keyIndexEnd"] += 1;
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
                    if (!$A.util.isEmpty(newItem.itemValue) && !self.itemAlreadyExist(selectedObjectMap, newItem)) {
                        selectedObjectMap[newItem.objName].push(newItem);
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
                    if (pms.permission.Permission_Type__c === permission.Permission_Type__c) {
                        pms.permission = permission;
                    } else if ($A.util.isEmpty(pms.permission.Id)) {
                        let clonedPermission = JSON.parse(JSON.stringify(permission));
                        //clonedPermission.Status__c = pms.permission.Status__c;
                        //clonedPermission.Alert_Status__c = pms.permission.Alert_Status__c;
                        clonedPermission.Status__c = "Inactive";
                        clonedPermission.Alert_Status__c = "Inactive";
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
                    existingRowMap[rowId] = newRowMap[keyId][rowId];
                    cellCounter = Object.keys(existingRowMap).length * newRowMap[keyId][rowId].pmsList.length;
                }
            });

            //cmp.set("v.paginationList", paginationList);
            cmp.set("v.existingRowMap", existingRowMap);
            console.log("----------------- Existing Row Map:");
            for (let key in existingRowMap) {
                console.log(existingRowMap[key]);
            }
            console.log("-----------------");

            //cmp.set("v.setupPagination", true);
            cmp.set("v.selectedObjectMap", selectedObjectMap);
            //onchange of selectedObjectMap will set up a new pagination list
            /*selectedObjectMap[sObjectNames[0]].forEach(function(name) {
                console.log(name.itemLabel);
            });*/

            self.reloadKeyObjectsWithPageIndex(cmp, 0);

            console.log('Setup complete.');
        }
    },

    loadRemainingPermissionsIntoTable : function(cmp) {
        console.log("----------------- loadRemainingPermissionsIntoTable()");
        var self = this;
        var existingPermissions = cmp.get("v.existingPermissions");
        var newRowMap = {};
        var sObjectNames = cmp.get("v.sObjectNames");
        var pmsFieldNames = cmp.get("v.pmsFieldNames");
        var rowHeaderFields = cmp.get("v.rowHeaderFields");
        var selectedObjectMap = cmp.get("v.selectedObjectMap");
        var existingRowMap = cmp.get("v.existingRowMap");
        /*var paginationList = cmp.get("v.paginationList");
        paginationList.push({
            "label" : (paginationList.length < 9 ? '0' : '') + (paginationList.length + 1),
            "keyIndexStart" : paginationList[paginationList.length - 1].keyIndexEnd,
            "keyIndexEnd" : paginationList[paginationList.length - 1].keyIndexEnd
        });*/

        existingPermissions.forEach(function(permission) {
            var keyId = permission[pmsFieldNames[0]];
            if ($A.util.isEmpty(newRowMap[keyId])) {
                console.log("New Key Object: ");
                newRowMap[keyId] = {};
                //paginationList[paginationList.length - 1].keyIndexEnd += 1;
            }

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
                if (!$A.util.isEmpty(newItem.itemValue) && !self.itemAlreadyExist(selectedObjectMap, newItem)) {
                    selectedObjectMap[newItem.objName].push(newItem);
                }
            }
            var rowId = self.generateRowId(subRecords, keyId);

            if ($A.util.isEmpty(newRowMap[keyId][rowId])) {
                newRowMap[keyId][rowId] = JSON.parse(cmp.get("v.rowObjectJSON"));
                newRowMap[keyId][rowId].rowId = rowId;
                newRowMap[keyId][rowId].subRecords = subRecords;
            }
            newRowMap[keyId][rowId].pmsList.forEach(function(pms) {
                if (pms.permission.Permission_Type__c === permission.Permission_Type__c) {
                    pms.permission = permission;
                } else if ($A.util.isEmpty(pms.permission.Id)) {
                    var clonedPermission = JSON.parse(JSON.stringify(permission));
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
                existingRowMap[rowId] = newRowMap[keyId][rowId];
            }
        });
        //cmp.set("v.paginationList", paginationList);
        cmp.set("v.existingRowMap", existingRowMap);
        cmp.set("v.selectedObjectMap", selectedObjectMap);
    },

    loadNewItemIntoExistingRowMap : function(cmp, pagIndex) {
        console.log("---------- loadNewItemIntoExistingRowMap(): " + pagIndex);
        var self = this;

        self.reloadKeyObjectsWithPageIndex(cmp, pagIndex);

        if (pagIndex + 1 < cmp.get("v.paginationList").length) {
            cmp.set("v.paginationTimeOut", setTimeout(function() {
                var loadEvent = $A.get("e.c:SmartEvent");
                loadEvent.setParams({
                    "value" : pagIndex + 1,
                    "typeOfOperation" : "LOAD_NEW_ITEM"
                });
                //loadEvent.fire();
            }, 0));
        } else {
            cmp.set("v.disableSaveButton", false);
        }
        cmp.set("v.disableSaveButton", false);
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
        var cellCounter = 0;
        var pIndex = 0;
        //var preloadLimit = cmp.get("v.cellLimit");

        //while (cellCounter < preloadLimit && pIndex < savedPermissions.length) {
        //}
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

                existingRowMap[rowId].loadedState = "";
                existingRowMap[rowId].pmsList.forEach(function(pms) {
                    existingRowMap[rowId].loadedState += pms.permission.Status__c;
                    existingRowMap[rowId].loadedState += pms.permission.Alert_Status__c;
                });
            }

            cellCounter++;
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
    addTableRow: function(cmp, selectedItem){
        var self = this;
        console.log('---------- addTableRow()');
        var selectedObjectMap = cmp.get("v.selectedObjectMap");
        var keyObjName = cmp.get("v.sObjectNames")[0];
        if (selectedItem.selected) {
            if (!self.itemAlreadyExist(selectedObjectMap, selectedItem)) {
                selectedObjectMap[selectedItem.objName].unshift(selectedItem);
                cmp.set("v.newKeyObjAdded", selectedItem.objName === keyObjName);
            }
        } else {
            for (var removeIndex = 0; removeIndex < selectedObjectMap[selectedItem.objName].length; removeIndex++) {
                if (selectedObjectMap[selectedItem.objName][removeIndex].itemValue === selectedItem.itemValue) {
                    selectedObjectMap[selectedItem.objName].splice(removeIndex, 1);
                    break;
                }
            }
        }
        cmp.set("v.selectedObjectMap", selectedObjectMap);
    },

    generatePermissionTable : function(cmp, keyObjects, selectedItem) {
        console.log('---------- generatePermissionTable()');
        var self = this;
        var sObjectNames = cmp.get("v.sObjectNames");

        if (selectedItem.objName === sObjectNames[0]) { //selected item is keyObj
            if (selectedItem.selected) { //insert new keyObj
                var keyObj = JSON.parse(cmp.get("v.keyObjectJSON"));
                keyObj.record = self.generateNewObjectWrapper(selectedItem);
                keyObj.added = selectedItem.added;
                if (!$A.util.isEmpty(cmp.get("v.securityFields")) && cmp.get("v.securityFields").length > 0) {
                    self.populateSecurityValues(keyObj.record, selectedItem.record, cmp.get("v.securityFields")[0]);
                }
                self.processKeyObject(cmp, keyObj);
                keyObjects.push(keyObj);
            } else { //remove keyObj
                for (var removeIndex = 0; removeIndex < keyObjects.length; removeIndex++) {
                    if (keyObjects[removeIndex].record.recordId === selectedItem.itemValue) {
                        keyObjects.splice(removeIndex, 1);
                        break;
                    }
                }
            }
        } else { //selected item is other objects
            keyObjects.forEach(function(keyObj) {
                self.processKeyObject(cmp, keyObj);
            });
        }
    },

    processKeyObject : function(cmp, keyObj) {
        console.log('---------- processKeyObject()');
        var self = this;
        const NAMESPACE = cmp.get("v.packageNamespace");
        const sObjectNames = cmp.get("v.sObjectNames");
        const pmsFieldNames = cmp.get("v.pmsFieldNames");
        const selectedObjectMap = cmp.get("v.selectedObjectMap");

        keyObj.rows = [];
        for (let objNameIndex = 1; objNameIndex < sObjectNames.length; objNameIndex++) {
            if (selectedObjectMap[sObjectNames[objNameIndex]].length <= 0) {
                return;
            }
        }

        let rows = [cmp.get("v.rowObjectJSON")];
        let existingRowMap = cmp.get("v.existingRowMap");
        const masterPmsList = cmp.get("v.masterPmsList");
        const userSecurityKeys = cmp.get("v.securityGroups");
        const securityFields = cmp.get("v.securityFields");
        const page = cmp.get("v.paginationList")[cmp.get("v.pageIndex")];
        console.log(JSON.parse(JSON.stringify(page)));

        for (let objNameIndex = 1; objNameIndex < sObjectNames.length; objNameIndex++) {
            let tempRows = [];
            for (let rIndex = 0; rIndex < rows.length; rIndex++) {
                for (let objectIndex = page[sObjectNames[objNameIndex]].start; objectIndex < page[sObjectNames[objNameIndex]].end; objectIndex++) {
                    let selectedObj = selectedObjectMap[sObjectNames[objNameIndex]][objectIndex];
                    //console.log(JSON.parse(JSON.stringify(selectedObj)));

                    let clonedRow = JSON.parse(rows[rIndex]);
                    if (selectedObj.added) {
                        clonedRow.added = true;
                    }
                    if (selectedObj.source === "Permission") {
                        self.populateRelatedItems(clonedRow.subRecords, cmp.get("v.rowHeaderFields"), selectedObj.parentRecord, objNameIndex, cmp.get("v.relatedDataFields"));
                    } else {
                        self.populateRelatedItems(clonedRow.subRecords, cmp.get("v.relatedDataFields"), selectedObj.parentRecord, objNameIndex, null);
                    }
                    self.populateRelatedSecurityValues(clonedRow.subRecords, securityFields, selectedObj.parentRecord);

                    if (securityFields.length > objNameIndex) {
                        self.populateSecurityValues(clonedRow.subRecords[objNameIndex - 1], selectedObj.record, securityFields[objNameIndex]);
                    }
                    const rowId = self.generateRowId(clonedRow.subRecords, keyObj.record.recordId);

                    if (!$A.util.isEmpty(existingRowMap[rowId])) {
                        //var existingPmsList = JSON.parse(JSON.stringify(existingRowMap[rowId].pmsList));
                        clonedRow.pmsList = JSON.parse(JSON.stringify(existingRowMap[rowId].pmsList));
                    } else {
                        clonedRow.pmsList.forEach(function (pms) {
                            pms.permission[pmsFieldNames[objNameIndex]] = selectedObj.itemValue;
                            pms.permission[pmsFieldNames[0]] = keyObj.record.recordId;
                            if (!selectedObj.added && !keyObj.added) {
                                pms.permission[NAMESPACE + "Alert_Status__c"] = "Inactive";
                                pms.permission[NAMESPACE + "Status__c"] = "Inactive";
                            }
                        });
                    }
                    //console.log(clonedRow.subRecords);
                    tempRows.push(JSON.stringify(clonedRow));
                }
            }
            if (tempRows.length > 0) {
                rows = tempRows;
            }
        }

        rows.forEach(function(rowJSON) {
            let parsedRow = JSON.parse(rowJSON);
            //Generate rowId
            const rowId = self.generateRowId(parsedRow.subRecords, keyObj.record.recordId);
            if (rowId.split(/\s+/).length >= cmp.get("v.sObjectNames").length) {
                parsedRow.rowId = rowId;
                //var skipThisRow = true;
                if ($A.util.isEmpty(existingRowMap[rowId])) {
                    if (parsedRow.added || keyObj.added) {
                        parsedRow.changed = true;
                    }
                    //skipThisRow = false;

                    existingRowMap[rowId] = parsedRow;
                    console.log("----- New Row Added");
                    console.log(JSON.parse(JSON.stringify(parsedRow)));
                    //}
                } else {
                    //skipThisRow = false;
                    const tempSubRecords = JSON.stringify(parsedRow.subRecords);
                    parsedRow = existingRowMap[rowId];
                    parsedRow.subRecords = JSON.parse(tempSubRecords);
                }
                //Disable buttons via security values
                if (!cmp.get("v.userIsAdmin")) {
                    self.setDisableFlagsOnPms(cmp, parsedRow);
                }
                keyObj.rows.push(parsedRow);
            }
        });

        console.log(JSON.parse(JSON.stringify(keyObj.rows)));
        cmp.set("v.existingRowMap", existingRowMap);
    },

    reloadKeyObjectsWithPageIndex : function(cmp, pageIndex) {
        var self = this;
        var page = cmp.get("v.paginationList")[pageIndex];
        var keyObjName = cmp.get("v.sObjectNames")[0];
        var keyObjects = [];
        if (cmp.get("v.selectedObjectMap")[keyObjName].length > 0) {
            for (var i = page[keyObjName].start; i < page[keyObjName].end; i++) {
                self.generatePermissionTable(cmp, keyObjects, cmp.get("v.selectedObjectMap")[keyObjName][i]);
            }
            self.setPermissionControls(cmp, keyObjects);
        }
        self.setLoadedPermissionState(keyObjects);
        cmp.set("v.keyObjects", keyObjects);
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
    setPermissionStatusButtonValue : function(pms) {
        pms.permission.Status__c = pms.countActiveStatus === pms.totalStatus ? "Active" : "Inactive";
        pms.permission.Alert_Status__c = pms.countActiveAlert === pms.totalAlert ? "Active" : "Inactive";
    },

    setLoadedPermissionState : function(keyObjects) {
        keyObjects.forEach(function(keyObj) {
            keyObj.rows.forEach(function(row) {
                if (!row.changed) {
                    row.loadedState = "";
                    //row.changed = false;
                    row.pmsList.forEach(function(pms) {
                        row.loadedState += pms.permission.Status__c;
                        row.loadedState += pms.permission.Alert_Status__c;
                    });
                }
            });
        });
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
                var value = JSON.parse(JSON.stringify(record));
                nestedFieldList.forEach(function(fieldName) {
                    value = value[fieldName];
                });
                objWrapper.securityValue = value;
            }
        }
    },

    setDisableFlagsOnPms : function(cmp, row) {
        const readOnly = cmp.get('v.readOnly');
        let rowDisabled = false;
        if (cmp.get("v.enableRowSecurity")) {
            row.subRecords.forEach(function(subRec) {
                if (!$A.util.isEmpty(subRec.securityValue)) {
                    rowDisabled = rowDisabled || !cmp.get("v.securityGroups").includes(subRec.securityValue) || readOnly;
                }
            });
            row.disabled = rowDisabled;
        }

        //Column security
        row.pmsRowCtrl.disableStatus = true;
        row.pmsRowCtrl.disableAlert = true;

        for (let pIndex = 0; pIndex < row.pmsList.length; pIndex++) {
            let pms = row.pmsList[pIndex];
            pms.disableAlert = rowDisabled;
            pms.disableStatus = rowDisabled;
            if (!rowDisabled) {
                if (pms.enableSecurityDocument) {
                    pms.disableStatus = true;
                    cmp.get("v.customPmsAPINames").forEach(function (customPms) {
                        pms.disableStatus = pms.disableStatus && !pms.documentEditPermissions.includes(customPms + ';') || readOnly;
                    });
                } else {
                    pms.disableStatus = false;
                }
                if (pms.enableSecurityNotification) {
                    pms.disableAlert = true;
                    cmp.get("v.customPmsAPINames").forEach(function (customPms) {
                        pms.disableAlert = pms.disableAlert && !pms.notificationEditPermissions.includes(customPms + ';') || readOnly;
                    });
                } else {
                    pms.disableAlert = false;
                }
            }

            if (pms.disableStatus && pms.permission[cmp.get("v.packageNamespace") + 'Status__c'] === 'Inactive'
                && pms.permission[cmp.get("v.packageNamespace") + 'Alert_Status__c'] === 'Inactive') {
                pms.disableAlert = true;
            }

            row.pmsRowCtrl.disableStatus = row.pmsRowCtrl.disableStatus && pms.disableStatus;
            row.pmsRowCtrl.disableAlert = row.pmsRowCtrl.disableAlert && pms.disableAlert;
        }
    },

    generateNewObjectWrapper : function(item) {
        var objWrapper = {
            "recordId" : item.itemValue,
            "label" : item.itemLabel
        };
        return objWrapper;
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

    setupPagination : function(cmp) {
        console.log("---------- setupPagination()");
        let rowLimit = Math.floor(cmp.get("v.cellLimit") / cmp.get("v.permissionTypes").length);
        const selectedObjectMap = cmp.get("v.selectedObjectMap");
        const sObjectNames = cmp.get("v.sObjectNames");
        let totalCell = cmp.get("v.permissionTypes").length;

        let pageJSON = {};
        for (let i = 0; i < sObjectNames.length; i++) {
            totalCell = totalCell * selectedObjectMap[sObjectNames[i]].length;
            pageJSON[sObjectNames[i]] = {"start":0, "end":selectedObjectMap[sObjectNames[i]].length};
        }

        let paginationList = [];
        if (totalCell <= cmp.get("v.cellLimit")) {
            pageJSON.label = "1";
            paginationList.push(pageJSON);
        } else {
            pageJSON = JSON.stringify(pageJSON);
            let selectedObjSizeMap = {};
            let denominatorMap = {};
            let denominator = 1;
            let listSize = 1;
            let sObjIndex = sObjectNames.length - 1;
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

            paginationList = new Array(listSize).fill(0);
            const labelLength = listSize.toString().length;

            for (let i = 0; i < sObjectNames.length; i++) {
                let jumpSize = 1;
                for (let j = i+1; j < sObjectNames.length; j++) {
                    jumpSize = jumpSize * denominatorMap[sObjectNames[j]];
                }
                let selectedObjIndex = 0;
                for (let pIndex = 0; pIndex < listSize; pIndex++) {
                    if (paginationList[pIndex] === 0) {
                        paginationList[pIndex] = JSON.parse(pageJSON);
                        paginationList[pIndex].label = "0000" + (pIndex+1);
                        paginationList[pIndex].label = paginationList[pIndex].label.substr(paginationList[pIndex].label.length - labelLength);
                    }
                    paginationList[pIndex][sObjectNames[i]].start = selectedObjIndex;
                    paginationList[pIndex][sObjectNames[i]].end = selectedObjIndex + selectedObjSizeMap[sObjectNames[i]];

                    if ((pIndex+1) % jumpSize === 0) {
                        selectedObjIndex += selectedObjSizeMap[sObjectNames[i]];
                    }
                    if (selectedObjIndex >= selectedObjectMap[sObjectNames[i]].length) {
                        selectedObjIndex = 0;
                    }
                    if (paginationList[pIndex][sObjectNames[i]].end > selectedObjectMap[sObjectNames[i]].length) {
                        paginationList[pIndex][sObjectNames[i]].end = selectedObjectMap[sObjectNames[i]].length;
                    }
                }
            }
        }
        console.log(paginationList);
        cmp.set("v.paginationList", paginationList);
    },

    setTableSize : function(cmp) {
        const cellPerRow = (cmp.get("v.enableAlerts") ? 2 : 1) * cmp.get("v.permissionTypes").length;
        if (cellPerRow > 20) {
            cmp.set("v.colSizeLeft", "slds-size_1-of-3");
            cmp.set("v.colSizeRight", "slds-size_2-of-3");
        } else if (cellPerRow > 16) {
            cmp.set("v.colSizeLeft", "slds-size_5-of-12");
            cmp.set("v.colSizeRight", "slds-size_7-of-12");
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
    }
})