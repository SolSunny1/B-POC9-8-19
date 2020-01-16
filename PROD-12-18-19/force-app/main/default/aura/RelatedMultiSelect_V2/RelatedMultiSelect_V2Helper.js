({
    doInit : function(cmp) {
        console.log("---------- doInit() " + cmp.get("v.widget.Name"));
        const widget = cmp.get("v.widget");
        const initAction = cmp.get("c.queryRecordsFromWidget");
        var self = this;
        const params = {
            "widget" : JSON.stringify(widget),
            "parentId" : cmp.get("v.parentRecordId"),
            "childId": cmp.get("v.childRecordId"),
            "securityEnabled" : cmp.get("v.securityEnabled"),
            "securityGroups" : cmp.get("v.securityGroups"),
            "selectedRecords" : cmp.get("v.selectedRecords"),
            "loadMode" : cmp.get("v.loadMode")
        };
        initAction.setParams(params);
        console.log(params);
        initAction.setCallback(this,function(response){
            const state = response.getState();
            console.log("RelatedMultiSelect.doInit() " + cmp.get("v.widget.Name") + ": " + state);
            if (state == "SUCCESS") {
                const returnValue =  response.getReturnValue();
                const options = [];
                const displayFields = widget.AutoComplete_Target_Field__c.split(',');
                let selectedRecords = cmp.get('v.selectedRecords');
                for (let i = 0; i < returnValue.length; i++) {
                    let wrapper = returnValue[i];
                    const option = {label: '', id: wrapper.record.Id, selected: false, objectName: wrapper.objectName, name: wrapper.Name, record: wrapper.record};
                    let optionLabels = [];
                    for (let dIndex = 0; dIndex < displayFields.length; dIndex++) {
                        optionLabels.push(self.getSObjectValue(wrapper.record, displayFields[dIndex].trim()));
                    }
                    option.label = optionLabels.join(', ');
                    if (!$A.util.isEmpty(selectedRecords) && selectedRecords.includes(option.id)) {
                        option.selected = true;
                    }
                    options.push(option);
                }
                console.log(JSON.parse(JSON.stringify(options)));
                cmp.set("v.options", options);
                cmp.set("v.disableSearch", cmp.get("v.readOnly") || (cmp.get("v.loadMode") == "edit"));
            } else {
                this.throwError(response);
            }
            const spinnerEvent = $A.get("e.c:SmartEvent");
            spinnerEvent.setParams({
                "value" : false,
                "typeOfOperation" : "TOGGLE_SPINNER"
            });
            spinnerEvent.fire();
            cmp.set("v.showSpinner", false);
        });
        $A.enqueueAction(initAction);
    },

    runRecordSearch : function(cmp) {
        const queryTerm = cmp.find('enter-search').get('v.value');
        if ($A.util.isEmpty(queryTerm)) return;

        cmp.set('v.issearching', true);
        const action = cmp.get("c.search");
        const widget = cmp.get("v.widget");
        var self = this;

        action.setParams({
            "widget" : JSON.stringify(widget),
            "searchText" : queryTerm,
            "securityEnabled" : cmp.get("v.securityEnabled"),
            "securityGroups" : cmp.get("v.securityGroups")
        });

        action.setCallback(this,function(response) {
            const queryTerm = cmp.find('enter-search').get('v.value');
            if ($A.util.isEmpty(queryTerm) || queryTerm.length < 3) {
                cmp.set('v.searchOptions', []);
                cmp.set('v.showSearch', false);
                cmp.set('v.issearching', false);
            } else {
                const state = response.getState();
                console.log('RelatedMultiSelect_V2_Controller.search(): ' + state);
                if (state == "SUCCESS") {
                    const returnValue =  response.getReturnValue();
                    let options = cmp.get("v.options");
                    let displayFields = widget.AutoComplete_Target_Field__c.split(',');
                    let searchOptions = [];
                    for (let i = 0; i < returnValue.length; i++) {
                        let wrapper = returnValue[i];
                        let j = 0;
                        for (j = 0; j < options.length; j++) {
                            if (options[j].id === wrapper.record.Id) {
                                searchOptions.push(options[j]);
                                j = options.length + 10;
                            }
                        }
                        if (j < options.length + 10) {
                            let option = {label: '', id: wrapper.record.Id, selected: false, objectName: wrapper.objectName, name: wrapper.Name, record: wrapper.record};
                            let optionLabels = [];
                            for (let dIndex = 0; dIndex < displayFields.length; dIndex++) {
                                optionLabels.push(self.getSObjectValue(wrapper.record, displayFields[dIndex].trim()));
                            }
                            option.label = optionLabels.join(', ');
                            searchOptions.push(option);
                        }
                    }
                    console.log(JSON.parse(JSON.stringify(searchOptions)));
                    cmp.set('v.searchOptions', searchOptions);
                    cmp.set('v.showSearch', true);
                } else {
                    this.throwError(response);
                }
                cmp.set('v.issearching', false);
            }
        });
        $A.enqueueAction(action);
    },

    handleKeyUp: function (cmp) {
        const queryTerm = cmp.find('enter-search').get('v.value');
        var self = this;

        if (queryTerm.length >= 3) {
            if (!$A.util.isEmpty(cmp.get("v.searchTimer"))) {
                clearTimeout(cmp.get("v.searchTimer"));
            }
            //console.log('scheduling query in 500ms');
            const timeout = setTimeout($A.getCallback(
                function(){
                    self.runRecordSearch(cmp);
                }),500);

            cmp.set("v.searchTimer", timeout);
        } else if ($A.util.isEmpty(queryTerm) || queryTerm.length == 0) {
            if (!$A.util.isEmpty(cmp.get("v.searchTimer"))) {
                clearTimeout(cmp.get("v.searchTimer"));
            }
            cmp.set('v.showSearch', false);
        }
    },

    processSelectAndUnselectAll : function(cmp, selected) {
        var options = cmp.get("v.options");
        for (var i = 0; i < options.length; i++) {
            options[i].selected = selected;
        }
        cmp.set("v.options", options);
    },

    selectSearchRecord : function(cmp, selectedIndex) {
        var self = this;
        const searchOptions = cmp.get("v.searchOptions");
        searchOptions[selectedIndex].selected = !searchOptions[selectedIndex].selected;
        if (searchOptions[selectedIndex].selected) {
            let options = cmp.get("v.options");
            let j = 0;
            //let spliceIndex = -1;
            for (j = 0; j < options.length; j++) {
                if (options[j].id == searchOptions[selectedIndex].id) {
                    j = options.length + 10;
                }
            }
            if (j < options.length + 10) {
                //options.splice(spliceIndex, 0, searchOptions[selectedIndex]);
                options.unshift(searchOptions[selectedIndex]);
            }
            cmp.set("v.options", options);
            cmp.set("v.selectedCount", cmp.get("v.selectedCount") + 1);
        } else {
            cmp.set("v.selectedCount", cmp.get("v.selectedCount") - 1);
        }
        cmp.set("v.searchOptions", searchOptions);
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

    throwError : function(response) {
        var errors = response.getError();
        var message = 'Unknown error'; // Default error message
        // Retrieve the error message sent by the server
        if (errors && Array.isArray(errors) && errors.length > 0) {
            if (errors[0].message != null) {
                message = errors[0].message;
            } else if (errors[0].pageErrors != null) {
                message = errors[0].pageErrors[0].message;
            }
        }
        // Display the message
        console.error(errors);
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Error",
            "message": message,
            "type": "error"
        });
        toastEvent.fire();
    }
})