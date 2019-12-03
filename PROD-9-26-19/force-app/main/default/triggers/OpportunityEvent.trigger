// Trigger to send an email to All Users in Public Group 'PFG Support Group' when an Event is created or updated with "Related to" set to a PFG Opportunity
    trigger OpportunityEvent on Event (after insert, after update) {

// Query for Event record types
    List<RecordType> rtypes = [Select Name, Id From RecordType where sObjectType='Event' and isActive=true];

// Create a map between the Event Record Type Name and Id for easy retrieval
    Map<String,String> eventRecordTypes = new Map<String,String>{};
    for(RecordType rt: rtypes)
    eventRecordTypes.put(rt.Name,rt.Id);
   
// Query for Opportunity record types
    List<RecordType> Opprtypes = [Select Name, Id From RecordType where sObjectType='Opportunity' and isActive=true];

//Create a map between the Opportunity Record Type Name and Id for easy retrieval
    Map<String,String> opportunityRecordTypes = new Map<String,String>{};
    for(RecordType rt: Opprtypes)
    opportunityRecordTypes.put(rt.Name,rt.Id);
    
//Set Opportunity Record ID 
    ID PFGOppRecordID = opportunityRecordTypes.get('PFG');

// Get email addresses of all members from the public group 'PFG Support Group'

    private List<String> getEmailAddresses() {
    List<String> idList = new List<String>();
    List<String> mailToAddresses = new List<String>();
    Group g = [SELECT (select userOrGroupId from groupMembers) FROM group WHERE name = 'PFG Support Group'];
    for (GroupMember gm : g.groupMembers) {
    idList.add(gm.userOrGroupId);
    }
    User[] usr = [SELECT email FROM user WHERE id IN :idList];
    for(User u : usr) {
    mailToAddresses.add(u.email);
    }
    return mailToAddresses;
    }  

// Trigger for New Events

    for (event e: Trigger.new)
    {
        if (e.RecordTypeId == eventRecordTypes.get('BIM_PFG') && e.WhatId != null)
        {
        List<Opportunity> listopportunity = [select Id from Opportunity where RecordTypeId = :PFGOppRecordID AND id =:e.WhatId]; 
            if(listopportunity.size() > 0)
            {
        
        // Get Related To Opportunity Name and set it to Variable OppName        
        String OppName = [SELECT Name FROM Opportunity where id = :e.WhatId LIMIT 1].Name;
                    
        
        // Get All contact names invited to the Event and set it to Variable AllContacts
        List<Id> ListContactId = new List<Id>();
        List <eventWhoRelation> Erelates =[select RelationId from eventWhoRelation where eventID=: e.id AND Type = 'Contact']; 
             
        for (eventWhoRelation ContactIDs:Erelates)
        {
            ListContactId.add(ContactIds.RelationId);
        }         
        List<Contact> AllContacts = ([Select Name from Contact where id =:ListContactId]);     
        List<String> AllContactNames = new List<String>();
        for(Contact Con:AllContacts)
        {
        AllContactNames.add(Con.Name);
        }
                 
        // Get the Event Owner's name
        String OwnerName = [SELECT Name from User where id = :e.ownerId LIMIT 1].Name;             
                    
        // Create a new email
        Messaging.reserveSingleEmailCapacity(3);
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        // set list of people who should get the email
        
        List<String> sendTo = new List<String>();
        mail.setToAddresses(getEmailAddresses());

        // set who the email is sent from

        mail.setReplyTo('Leigh-Anne.Nugent@brookfield.com');
        mail.setSenderDisplayName('Salesforce Notification');

        //set email subject and body

        mail.setSubject('Event has been created for ' + OppName);

        String body = '<br><br>A new event has been created for: ' + OppName + '<br><br>Event Type: ' + e.type + '<br><br>Contact(s): ' + AllContactNames +
        '<br><br>Subject: ' + e.subject + '<br><br>Description: ' + e.description + '<br><br>Start Date and Time: '
        + e.StartDateTime + '<br><br>Assigned To: ' + OwnerName;
        mail.setHtmlBody(body);
        
       
        //send the Opportunity Event Email Notifications

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        
            }
        }
    }
    }