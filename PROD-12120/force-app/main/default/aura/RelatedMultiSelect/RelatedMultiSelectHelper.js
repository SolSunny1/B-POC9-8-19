({
    doInit : function(cmp) {
        var widget = cmp.get("v.widget");
        var initAction = cmp.get("c.queryRecordsFromWidget");
        var self = this;
        var params = {
            "widget" : JSON.stringify(widget),
            "parentId" : cmp.get("v.parentRecordId"),
            "childId": cmp.get("v.childRecordId"),
            "securityEnabled" : cmp.get("v.securityEnabled"),
            "securityGroups" : cmp.get("v.securityGroups")
        };
        initAction.setParams(params);
        console.log("RelatedMultiSelect.doInit() " + cmp.get("v.widget.Name"));
        console.log(params);
        initAction.setCallback(this,function(response){
            var state = response.getState();
            if(state == "SUCCESS"){
                var returnValue =  response.getReturnValue();

                var options = cmp.get('v.options');
                var selectedRecords = cmp.get('v.selectedRecords');
                returnValue.forEach(function (wrapper) {
                    console.log(wrapper);
                    var option = {label: '', id: wrapper.record.Id, selected: false, objectName: wrapper.objectName, name: wrapper.Name, record: wrapper.record};
                    var displayFields = widget.AutoComplete_Target_Field__c.split(',');
                    var optionLabels = [];
                    displayFields.forEach(function (fieldString) {
                        optionLabels.push(self.getSObjectValue(wrapper.record,fieldString.trim()));
                    });
                    option.label = optionLabels.join(', ');
                    if (selectedRecords.includes(option.id)) {
                        option.selected = true;
                        option.preSelected = true;
                    } else {
                        option.preSelected = false;
                    }
                    options.push(option);

                    cmp.set("v.options",options);
                });
            } else {
                this.throwError(response);
            }
            var spinnerEvent = $A.get("e.c:SmartEvent");
            spinnerEvent.setParams({
                "value" : false,
                "typeOfOperation" : "TOGGLE_SPINNER",
                "receiver" : cmp.get("v.parentComponent")
            });
            spinnerEvent.fire();
            cmp.set("v.showSpinner", false);
        });
        $A.enqueueAction(initAction);
    },
    search : function(cmp, evt) {
        var queryTerm = cmp.find('enter-search').get('v.value');
        cmp.set('v.issearching', true);

        var options = cmp.get('v.options');
        var newOptions = [];
        options.forEach(function(option){
            var str = String(option.label);
            if (str.toLowerCase().indexOf(String(queryTerm).toLowerCase()) !== -1) {
                newOptions.push(option);
            }
        });
        cmp.set('v.searchOptions', JSON.parse(JSON.stringify(newOptions)));
        cmp.set('v.issearching', false);

    },
    runRecordSearch : function(cmp){
        cmp.set('v.issearching', true);
        var action = cmp.get("c.search");
        var queryTerm = cmp.find('enter-search').get('v.value');
        var widget = cmp.get("v.widget");
        var self = this;

        action.setParams(
            {
                "widget" : JSON.stringify(widget),
                "searchText" : queryTerm,
                "securityEnabled" : cmp.get("v.securityEnabled"),
                "securityGroups" : cmp.get("v.securityGroups")
            }
        );

        action.setCallback(this,function(response){
            var state = response.getState();
            console.log('query returned:'+state);
            if(state == "SUCCESS"){
                var returnValue =  response.getReturnValue();

                var options = [];
                returnValue.forEach(function (wrapper) {
                    var option = {label: '', id: wrapper.record.Id, selected: false, objectName: wrapper.objectName, name: wrapper.Name, record: wrapper.record};
                    var displayFields = widget.AutoComplete_Target_Field__c.split(',');
                    var optionLabels = [];
                    displayFields.forEach(function (fieldString) {
                        optionLabels.push(self.getSObjectValue(wrapper.record,fieldString.trim()));
                    });
                    option.label = optionLabels.join(', ');
                    options.push(option);

                    cmp.set('v.searchOptions', JSON.parse(JSON.stringify(options)));
                });
                var queryTerm = cmp.find('enter-search').get('v.value');

                if(queryTerm.length >= 3){
                    cmp.set('v.showSearch', true);
                }
            } else {
                this.throwError(response);
            }
            cmp.set('v.issearching', false);
        });

        console.log('Query request ready. Adding to queue.');
        $A.enqueueAction(action);
    },

    handleKeyUp: function (cmp, evt) {
        var isEnterKey = evt.keyCode === 13;
        var queryTerm = cmp.find('enter-search').get('v.value');
        var self = this;

        if(queryTerm.length >= 3){
            if (!$A.util.isEmpty(cmp.get("v.searchTimer"))) {
                clearTimeout(cmp.get("v.searchTimer"));
            }
            //console.log('scheduling query in 500ms');
            var timeout = setTimeout($A.getCallback(
                            function(){
                                    self.runRecordSearch(cmp);
                            }),500);

            cmp.set("v.searchTimer",timeout);
        } else if(queryTerm.length == 0){
            cmp.set('v.showSearch', false);
        }
    },

    selectRecord : function(cmp, evt) {
        var selectedRecord = evt.currentTarget.id;
        var options = cmp.get("v.options");
        var searchOptions = cmp.get("v.searchOptions");
        var smartEvent = $A.get("e.c:SmartEvent");
        var self = this;

        options.forEach(function(option) {
           if (option.id == selectedRecord) {
               if (option.selected)
                   option.selected = false;
               else
                   option.selected = true;

               var paramMap = {
                   "selected" : option.selected,
                   "objName" : cmp.get("v.widget").Object__c,
                   "itemLabel" : option.name,
                   "itemValue" : option.id,
                   "added" : true
               };

               paramMap.record = option.record;
               console.log(paramMap);
               smartEvent.setParams({
                   "paramMap" : paramMap,
                   "typeOfOperation" : "relatedRowSelect",
                   "receiver": cmp.get("v.parentComponent")
               });
           }
        });
        cmp.set("v.options", options);
        cmp.set("v.searchOptions", searchOptions);
        smartEvent.fire();
    },
    selectSearchRecord : function(cmp, evt) {
        var selectedRecord = evt.currentTarget.id;
        var options = cmp.get("v.options");
        var searchOptions = cmp.get("v.searchOptions");
        var smartEvent = $A.get("e.c:SmartEvent");
        var self = this;

        searchOptions.forEach(function(option) {
            if (option.id == selectedRecord) {
                console.log('found selected record: '+ option.id);
                option.selected = true;

                var optionFound = false;
                options.forEach(function(existingOption) {
                   if (existingOption.id == option.id) {
                       optionFound = true;
                       existingOption.selected = true;
                   }
                });

                if (!optionFound)
                    options.push(option);

                console.log('pushed selected to options');

                var paramMap = {
                    "selected" : option.selected,
                    "objName" : cmp.get("v.widget").Object__c,
                    "itemLabel" : option.name,
                    "itemValue" : option.id,
                    "added" : true
                };

                console.log('built event parameters');

                paramMap.record = option.record;

                console.log('payload ready');
                console.log(paramMap);
                smartEvent.setParams({
                    "paramMap" : paramMap,
                    "typeOfOperation" : "relatedRowSelect",
                    "receiver":cmp.get("v.parentComponent")
                });
                console.log('event ready to fire');

                cmp.find('enter-search').set('v.value','');
            }
        });
        cmp.set("v.options", options);
        cmp.set('v.showSearch', false);
        console.log('search panel hidden');
        smartEvent.fire();

        // setTimeout(function(){
        //     var optionItems = document.getElementsByClassName("optionItem");
        //     for (var i=0; i < optionItems.length; i++) {
        //         if (optionItems[i].id == selectedRecord) {
        //             optionItems[i].scrollIntoView();
        //         }
        //     }
        //     }, 500
        // );
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