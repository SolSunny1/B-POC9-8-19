/*
Developed By: CH 
Functionality:
1>  Match field MailingState on contact to field state__c on Assignment.

2>  If Use_ZipCode on returned record is False, change owner of contact to match field Owner__c on Assignment record

3> If Use_ZipCode is true, match first 5 digiits  of MailingPostalCode on Contact to PostalCode__c on Assignment and set Contact Owner to Owner__c, if no match then return record where state is a match and PostalCode__c is blank and use that owner.

4> If triggered by AutoUpdateOwner__c, set that field value to false.

History: 
*/
trigger Account_OwnerAssignment on Account (after insert, after update) {
    set<String> setStates = new set<String>();
    if(Trigger.isInsert){
        //Prepare list of all states of contacts getting inserted/updated
        for(Account a: Trigger.new){
            if(a.Do_Not_Auto_Update_Owner__c == false){
                if(a.BillingState != null && a.BillingState != ''){
                    setStates.add(a.BillingState );
                }else if(a.SalesConnect__State__c != null && a.SalesConnect__State__c != ''){
                    setStates.add(a.SalesConnect__State__c );
                }
            }
        }
    }
    if(Trigger.isUpdate){
        for(Account new_a: Trigger.new){
            Account old_a = Trigger.oldmap.get(new_a.ID);
            if(new_a.Do_Not_Auto_Update_Owner__c ==false){
                //If state is updated/ Zipcode/ AutoUpdateOwner field is updated on trigger the add that contact to be updated with appropriate user.
                if(new_a.BillingState != old_a.BillingState && new_a.BillingState != null && new_a.BillingState != '' ||
                    new_a.BillingPostalCode != old_a.BillingPostalCode ||
                   new_a.AutoUpdateOwner__c != old_a.AutoUpdateOwner__c && new_a.AutoUpdateOwner__c == true){
                    setStates.add(new_a.BillingState );
                }else if(new_a.SalesConnect__State__c != old_a.SalesConnect__State__c && new_a.SalesConnect__State__c != null && new_a.SalesConnect__State__c != '' ||
                    new_a.SalesConnect__Zip_Code__c!= old_a.SalesConnect__Zip_Code__c||
                   new_a.AutoUpdateOwner__c != old_a.AutoUpdateOwner__c && new_a.AutoUpdateOwner__c == true){
                    setStates.add(new_a.SalesConnect__State__c );
                }
             }
        }
    }
    if(setStates.size() > 0){
        List<Assignments__c> lstAssignments = [select id,State__c,  Use_Zip_Code__c, Zip_Code__c, Owner__c from Assignments__c where State__c in: setStates]; //List of assignment records where state is matching to contact's state.
        List<Account> updateAccount = new List<Account>();
        Boolean isOwnerAssigned = false;
        for(Account a: Trigger.new){
            Account tempAccount= new Account(ID = a.ID);
            for(Assignments__c objAssignment: lstAssignments){
                if(a.BillingState == objAssignment.State__c){
                    if(objAssignment.Use_Zip_Code__c == false){ //Condition 2 of functionality. i.e If Use_ZipCode on returned record is False, change owner of contact to match field Owner__c on Assignment record
                        
                        tempAccount.OwnerID = objAssignment.Owner__c;
                        isOwnerAssigned = true;
                    }else if(objAssignment.Use_Zip_Code__c == true){ // Condition 3 of functinality i.e If Use_ZipCode is true, match first 5 digiits  of MailingPostalCode on Contact to PostalCode__c on Assignment and set Contact Owner to Owner__c,...
                        if(a.BillingPostalCode == objAssignment.Zip_Code__c){
                             tempAccount.OwnerID = objAssignment.Owner__c;
                             isOwnerAssigned = true;
                        }
                    }
                }else if(a.SalesConnect__State__c == objAssignment.State__c){
                    if(objAssignment.Use_Zip_Code__c == false){ //Condition 2 of functionality. i.e If Use_ZipCode on returned record is False, change owner of contact to match field Owner__c on Assignment record
                        
                        tempAccount.OwnerID = objAssignment.Owner__c;
                        isOwnerAssigned = true;
                    }else if(objAssignment.Use_Zip_Code__c == true){ // Condition 3 of functinality i.e If Use_ZipCode is true, match first 5 digiits  of MailingPostalCode on Contact to PostalCode__c on Assignment and set Contact Owner to Owner__c,...
                        if(a.SalesConnect__Zip_Code__c== objAssignment.Zip_Code__c){
                             tempAccount.OwnerID = objAssignment.Owner__c;
                             isOwnerAssigned = true;
                        }
                    }
                }
               
            }
            
            if(isOwnerAssigned == false){ 
                for(Assignments__c objAssignment: lstAssignments){ //Condition 4 of functinality i.e If triggered by AutoUpdateOwner__c, set that field value to false.
                    if(a.BillingState == objAssignment.State__c && objAssignment.Use_Zip_Code__c == true && (objAssignment.Zip_Code__c == '' || objAssignment.Zip_Code__c == null)){
                        tempAccount.OwnerID = objAssignment.Owner__c;
                    }else if(a.SalesConnect__State__c == objAssignment.State__c && objAssignment.Use_Zip_Code__c == true && (objAssignment.Zip_Code__c == '' || objAssignment.Zip_Code__c == null)){
                        tempAccount.OwnerID = objAssignment.Owner__c;
                    }
                }
            }
            tempAccount.AutoUpdateOwner__c = false;
            updateAccount.add(tempAccount);
        }
        if(updateAccount.size() > 0){
            update updateAccount;
        }
            
    }
}