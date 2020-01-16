/*
Developed By: CH 
Functionality:
1>  Match field MailingState on contact to field state__c on Assignment.

2>  If Use_ZipCode on returned record is False, change owner of contact to match field Owner__c on Assignment record

3> If Use_ZipCode is true, match first 5 digiits  of MailingPostalCode on Contact to PostalCode__c on Assignment and set Contact Owner to Owner__c, if no match then return record where state is a match and PostalCode__c is blank and use that owner.

4> If triggered by AutoUpdateOwner__c, set that field value to false.
SS: 1/13/2020 Appended code to include ZipCode based assignment logic. 

History: 
*/
trigger Contact_OwnerAssignment on Contact (after insert, after update) {
    set<String> setStates = new set<String>();
     set<String> setZips = new set<String>();
    if(Trigger.isInsert){
        //Prepare list of all states of contacts getting inserted/updated
        for(contact c: Trigger.new){
            //if(c.Do_Not_Auto_Update_Owner__c == false ){ 
            if(c.Do_Not_Auto_Update_Owner__c == false && c.SalesConnect__Category_1__c == 'Wealth Management'  && 
                (c.SalesConnect__Territory_Description_1__c == 'Central' ||
                c.SalesConnect__Territory_Description_1__c == 'Mid-Atlantic' ||
                c.SalesConnect__Territory_Description_1__c == 'Mid-West' ||
                c.SalesConnect__Territory_Description_1__c == 'Northeast' ||
                c.SalesConnect__Territory_Description_1__c == 'Southeast' ||
                c.SalesConnect__Territory_Description_1__c == 'West'  ){
                if((c.MailingState != null && c.MailingState != '') ||
                  (c.MailingPostalCode != null && c.MailingPostalCode != '')){
                    setStates.add(c.MailingState );
                    setZips.add(c.MailingPostalCode);
                }else if((c.SalesConnect__State__c != null && c.SalesConnect__State__c != '') || 
                          (c.SalesConnect__Zip__c != null && c.SalesConnect__Zip__c != '')){
                    setStates.add(c.SalesConnect__State__c );
                    setZips.add(c.SalesConnect__Zip__c);
                }
            }
        }
    }
    if(Trigger.isUpdate){
        for(contact new_c: Trigger.new){
            //if(new_c.Do_Not_Auto_Update_Owner__c == false ){  //SS: 6-27-19 moved this if statement before below old_c line. 
            if(new_c.Do_Not_Auto_Update_Owner__c == false && new_c.SalesConnect__Category_1__c == 'Wealth Management'  && 
            (new_c.SalesConnect__Territory_Description_1__c == 'Central' ||
            new_c.SalesConnect__Territory_Description_1__c == 'Mid-Atlantic' ||
            new_c.SalesConnect__Territory_Description_1__c == 'Mid-West' ||
            new_c.SalesConnect__Territory_Description_1__c == 'Northeast' ||
            new_c.SalesConnect__Territory_Description_1__c == 'Southeast' ||
            new_c.SalesConnect__Territory_Description_1__c == 'West' )

              // ((new_c.SalesConnect__Category_2__c != null || new_c.SalesConnect__Category_2__c != '') && new_c.SalesConnect__Category_2__c != 'Institutional') //&& 
             /* ( (new_c.SalesConnect__Category_2__c == null || new_c.SalesConnect__Category_2__c == '' )//) && 
                 //((new_c.SalesConnect__Category_1__c != null || new_c.SalesConnect__Category_1__c != '')
                 &&  new_c.SalesConnect__Category_1__c == 'Wealth Management'  && 
                  (new_c.SalesConnect__Territory_Description_1__c != '' &&
                    new_c.SalesConnect__Territory_Description_1__c != null && 
                    new_c.SalesConnect__Territory_Description_1__c != 'Unknown' && 
                    new_c.SalesConnect__Territory_Description_1__c != 'House - WMG' && 
                    new_c.SalesConnect__Territory_Description_1__c != 'Prorata' && 
                    new_c.SalesConnect__Territory_Description_1__c != 'National Accounts')) */
               ){  //SS: 6-27-19 moved this if statement before below old_c line. 
                Contact old_c = Trigger.oldmap.get(new_c.ID);  //If state is updated/ Zipcode/ AutoUpdateOwner field is updated on trigger the add that contact to be updated with appropriate user.
                if( new_c.MailingState != old_c.MailingState && new_c.MailingState != null && new_c.MailingState != '' ||
                    new_c.MailingPostalCode != old_c.MailingPostalCode ||
                    new_c.AutoUpdateOwner__c != old_c.AutoUpdateOwner__c && new_c.AutoUpdateOwner__c == true){
                        setStates.add(new_c.MailingState );
                        setZips.add(new_c.MailingPostalCode);
                }else if(new_c.SalesConnect__State__c != old_c.SalesConnect__State__c && new_c.SalesConnect__State__c != null && new_c.SalesConnect__State__c != '' ||
                    new_c.SalesConnect__Zip__c!= old_c.SalesConnect__Zip__c||
                   new_c.AutoUpdateOwner__c != old_c.AutoUpdateOwner__c && new_c.AutoUpdateOwner__c == true){
                    setStates.add(new_c.SalesConnect__State__c );
                    setZips.add(new_c.SalesConnect__Zip__c);
                }
            }
        }
    }
    System.debug('states size ==== ' + setStates.size());
    System.debug('list of states ' + setStates);
    System.debug('setZips size ==== ' + setZips.size());
    System.debug('list of setZips ' + setZips);
    if(setStates.size() > 0 || setZips.size() >0 ){    
        List<Assignments__c> lstAssignments = [select id,State__c,  Use_Zip_Code__c, Zip_Code__c, Owner__c from Assignments__c where State__c in: setStates or Zip_Code__c in:setZips]; //List of assignment records where state is matching to contact's state.
        List<Contact> updateContact = new List<Contact>();
        Boolean isOwnerAssigned = false;
        system.debug('lstAssignments' + lstAssignments);
        for(contact c: Trigger.new){
            //if(c.Do_Not_Auto_Update_Owner__c == false ){   //SS: 6-27-19 appended this if statement before collection statement below to bypass contacts with do not auto update flag. 
            if(c.Do_Not_Auto_Update_Owner__c == false && c.SalesConnect__Category_1__c == 'Wealth Management'  && 
            (c.SalesConnect__Territory_Description_1__c == 'Central' ||
            c.SalesConnect__Territory_Description_1__c == 'Mid-Atlantic' ||
            c.SalesConnect__Territory_Description_1__c == 'Mid-West' ||
            c.SalesConnect__Territory_Description_1__c == 'Northeast' ||
            c.SalesConnect__Territory_Description_1__c == 'Southeast' ||
            c.SalesConnect__Territory_Description_1__c == 'West' )/* && 
            //   ((c.SalesConnect__Category_2__c != null || c.SalesConnect__Category_2__c != '') && c.SalesConnect__Category_2__c != 'Institutional') //&& 
               ( (c.SalesConnect__Category_2__c == null || c.SalesConnect__Category_2__c == '') && c.SalesConnect__Category_1__c == 'Wealth Management'  && 
                (c.SalesConnect__Territory_Description_1__c != '' && 
                c.SalesConnect__Territory_Description_1__c != null && 
                c.SalesConnect__Territory_Description_1__c != 'Unknown' && 
                c.SalesConnect__Territory_Description_1__c != 'House - WMG' && 
                c.SalesConnect__Territory_Description_1__c != 'Prorata' && 
                c.SalesConnect__Territory_Description_1__c != 'National Accounts')) */
             ){   //SS: 6-27-19 appended this if statement before collection statement below to bypass contacts with do not auto update flag. 
                Contact tempContact = new Contact(ID = c.ID);
                for(Assignments__c objAssignment: lstAssignments){
                    if( c.MailingState == objAssignment.State__c || c.MailingPostalCode == objAssignment.Zip_Code__c ) { 
                        if (objAssignment.Use_Zip_Code__c == false && c.MailingState.toUpperCase() != 'MO'){ // Condition 3 of functinality i.e If Use_ZipCode is true, match first 5 digiits  of MailingPostalCode on Contact to PostalCode__c on Assignment and set Contact Owner to Owner__c,...
                            tempContact.OwnerID = objAssignment.Owner__c;
                            isOwnerAssigned = true;  
                        }else if(objAssignment.Use_Zip_Code__c == true && (objAssignment.State__c == '' || objAssignment.State__c == null) ) {//Condition 2 of functionality. i.e If Use_ZipCode on returned record is False, change owner of contact to match field Owner__c on Assignment record
                                tempContact.OwnerID = objAssignment.Owner__c;
                                isOwnerAssigned = true;
                        }
                    }
                    else if(c.SalesConnect__State__c == objAssignment.State__c || c.SalesConnect__Zip__c== objAssignment.Zip_Code__c){
                        if(objAssignment.Use_Zip_Code__c == false && c.SalesConnect__State__c.toUpperCase() != 'MO'){ //Condition 2 of functionality. i.e If Use_ZipCode on returned record is False, change owner of contact to match field Owner__c on Assignment record
                            tempContact.OwnerID = objAssignment.Owner__c;
                            isOwnerAssigned = true;
                        }else if(objAssignment.Use_Zip_Code__c == true && (objAssignment.State__c == '' || objAssignment.State__c == null) ){ // Condition 3 of functinality i.e If Use_ZipCode is true, match first 5 digiits  of MailingPostalCode on Contact to PostalCode__c on Assignment and set Contact Owner to Owner__c,...
                            //if(c.SalesConnect__Zip__c== objAssignment.Zip_Code__c){
                                 tempContact.OwnerID = objAssignment.Owner__c;
                                 isOwnerAssigned = true;
                            //}
                        }
                    }
                   
                }
                
                if(isOwnerAssigned == false){ 
                    for(Assignments__c objAssignment: lstAssignments){ //Condition 4 of functinality i.e If triggered by AutoUpdateOwner__c, set that field value to false.
                        if(c.MailingState == objAssignment.State__c && objAssignment.Use_Zip_Code__c == true && (objAssignment.Zip_Code__c == '' || objAssignment.Zip_Code__c == null)){
                            tempContact.OwnerID = objAssignment.Owner__c;
                        }else if(c.SalesConnect__State__c == objAssignment.State__c && objAssignment.Use_Zip_Code__c == true && (objAssignment.Zip_Code__c == '' || objAssignment.Zip_Code__c == null)){
                            tempContact.OwnerID = objAssignment.Owner__c;
                        }
                    }
                }
                tempContact.AutoUpdateOwner__c = false;
                updateContact.add(tempContact);
            }
        }
        if(updateContact.size() > 0){
            update updateContact;
        }
            
    }
}