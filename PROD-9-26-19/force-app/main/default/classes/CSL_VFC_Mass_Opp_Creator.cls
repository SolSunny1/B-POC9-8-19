public class CSL_VFC_Mass_Opp_Creator {

	public static final String NONE_PICKLIST_VALUE = '--None--';
	
	// Input objects to populate lookups
	public Account inputAccount {get; set;}
	public Opportunity inputOpportunity {get; set;}
	public Opportunity inputCreateOpportunity {get; set;}
	public Contact inputContact {get; set;}
	
	public boolean hasOpportunities {get; set;}
	public boolean hideOpportunitiesCreated {get; set;}
	public boolean hasActivePSGCampaigns {get; set;}
	private boolean isPSG;
	private boolean isPFG;
	
	public Id loggedInUserId {get; set;}
	public Mass_Opp_Creation__c settings {get; set;}
	public Investment_Vehicle__c selectedInvestmentVehicle {get; set;}
	public Integer probabilityFrom {get; set;}
	public Integer probabilityTo {get; set;}
	public Integer numberResults {get; set;}
	public Integer newOppsCreated {get; set;}
	public Integer newContactRolesAdded {get; set;}
	public String selectedInvestVehicleName {get; set;}
	public String selectedInvestmentInterests {get; set;}
	
	public List<ContactWrapper> contactWrapperList {get; set;}
	public Map<Id, Opportunity> closedOppByAcctMap {get; set;}
	public Map<Id, String> contactActiveCampaigns {get; set;}
	public List<SelectOption> investingInterests {get; set;}
	
	public CSL_VFC_Mass_Opp_Creator() {
		// Initialize variables
		hasActivePSGCampaigns = false;
		isPFG = false;
		isPSG = false;
		hideOpportunitiesCreated = false;

		// Determine which custom settings to use based on the page name, default to PFG
		String pageName = ApexPages.currentPage().getUrl();
		system.debug('CSL_VFC_Mass_Opp_Creator :: pageName = ' + pageName);
		if(!String.isEmpty(pageName) && (pageName.contains('PSG') || pageName.contains('psg'))) {
			settings = Mass_Opp_Creation__c.getValues('PSG');
			isPSG = true;	
		}	else {
			settings = Mass_Opp_Creation__c.getValues('PFG');
			isPFG = true;
		}

		numberResults = 0;
		
		// BF-5: Use the logged in user if it is part of a CRM Profile
		String profileList = settings.Profile_Ids__c;
		system.debug('CSL_VFC_Mass_Opp_Creator :: profileList = ' + profileList);
		system.debug('CSL_VFC_Mass_Opp_Creator :: UserInfo.getProfileId() = ' + UserInfo.getProfileId());
		if((null != settings) && !String.isEmpty(profileList) && profileList.contains(UserInfo.getProfileId())) {
			loggedInUserId = UserInfo.getUserId();	
		}

		// Setup Account Filters
		inputAccount = new Account();
		if(isPSG) {
			inputAccount.BIM_Primary_Mktg_Rep__c = loggedInUserId;
		}	else if (isPFG) {
			inputAccount.PFG_CRM_Primary_Lead__c = loggedInUserId;

			// BF-22: Setup picklist options
			investingInterests = new List<SelectOption>();
			Schema.DescribeFieldResult fieldResult = Account.PFG_General_Investing_Interest__c.getDescribe();
			List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
			investingInterests.add(new SelectOption('', NONE_PICKLIST_VALUE));
			for(Schema.PicklistEntry f : ple) {
				investingInterests.add(new SelectOption(f.getValue(), f.getLabel()));
			}
		}

		// Setup Opp Filters
		if(inputOpportunity == null) {
			inputOpportunity = new Opportunity(OwnerId = loggedInUserId);
			if(settings != null) {
				// Set default stage
				if(!String.isEmpty(settings.Default_Filter_Stage__c)) {
					//inputOpportunity.StageName = settings.Default_Filter_Stage__c;
				}
				// Set default record type id
				if(!String.isEmpty(settings.Opp_Record_Type_ID__c)) {
					inputOpportunity.RecordTypeId = settings.Opp_Record_Type_ID__c;
				}
			}
		}
		
		inputContact = new Contact(PFG_Key_Contact__c = settings.Default_Filter_Key_Contact__c);
		hasOpportunities = settings.Default_Filter_Has_Opportunities__c;

		if(inputCreateOpportunity == null) {
			inputCreateOpportunity = new Opportunity(StageName = settings.Default_New_Opp_Stage__c);
			if(loggedInUserId != null) {
				inputCreateOpportunity.OwnerId = loggedInUserId;
			}
			// Set default record type id
			if(!String.isEmpty(settings.Opp_Record_Type_ID__c)) {
				inputCreateOpportunity.RecordTypeId = settings.Opp_Record_Type_ID__c;
			}
			system.debug('CSL_VFC_Mass_Opp_Creator :: inputCreateOpportunity=' + inputCreateOpportunity);
		}
	}

	public PageReference search() {

		try {
			// Validate Search Criteria
			if(hasOpportunities && (null == inputOpportunity.Investment_Vehicle__c)) {
				ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.Mass_Opp_Select_Investment_Vehicle);
	            ApexPages.addMessage(myMsg);
	        }

			// BF-10: If both probablities are 0, set to null
			system.debug(probabilityFrom);
			system.debug(probabilityTo);
			system.debug(inputOpportunity.StageName);
			if(0 == probabilityFrom && 0 == probabilityTo) {
				probabilityFrom = null;
				probabilityTo = null;
			}	else if(String.isEmpty(inputOpportunity.StageName)) {
				inputOpportunity.StageName = null;
			}

			// BF-10: Validate Opp. Stage or Probability Search Criteria
			if(hasOpportunities &&
			   (!(!String.isEmpty(inputOpportunity.StageName) && (null == probabilityFrom && null == probabilityTo)) &&
			    !(String.isEmpty(inputOpportunity.StageName) && (null != probabilityFrom && null != probabilityTo))) )  {
				ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.Mass_Opp_Specify_Opp_Stage_or);
	            ApexPages.addMessage(myMsg);
	        }

			// BF-10: Validate Opp. Probability Range
			if(hasOpportunities && 
			   (null != probabilityFrom && null != probabilityTo) && 
			   (probabilityTo < probabilityFrom)) {
				ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.Mass_Opp_Probability_Range);
	            ApexPages.addMessage(myMsg);
			}

			// Return at the end to show all error messages
			if(ApexPages.hasMessages()) {
				contactWrapperList = null;
				return null;
			}

			List<String> excludeContactStatus = new List<String>();
			if(settings != null && !String.isEmpty(settings.Exclude_Contact_Status__c)) {
				excludeContactStatus = (settings.Exclude_Contact_Status__c).split(',');
			}
			
			// Create a dynamic query for contacts and filter on the specified filters
			String contactQuery = '';
			contactQuery  = '	SELECT 	Id, FirstName, LastName, Name, AccountId,';
			contactQuery += ' 			Account.Name, Account.PFG_Relationship_Importance__c, Account.PFG_CRM_Primary_Lead__r.Name,';
			contactQuery += ' 			Account.PFG_CRM_Real_Asset_Lead__r.Name, Account.PFG_CRM_Secondary_Lead__r.Name, PFG_Key_Contact__c';
			contactQuery += '	FROM Contact';
			// Add Filter Conditions

			// Key Contact Filter
			contactQuery += ' WHERE PFG_Key_Contact__c = ' + inputContact.PFG_Key_Contact__c;
			
			// BF-7: Update to exclude specific contact status values
			if(!excludeContactStatus.isEmpty()) {
				for(String status : excludeContactStatus) {
					contactQuery += ' AND Contact_Status__c != \'' + status + '\'';
				}
			}

			// Relationship Importance Filter
			if(!String.isEmpty(inputAccount.PFG_Relationship_Importance__c)) {
				contactQuery += ' AND Account.PFG_Relationship_Importance__c = \'' + inputAccount.PFG_Relationship_Importance__c + '\'';
			}

			// BF-22: Investing Interest Filter
			if(!String.isEmpty(selectedInvestmentInterests)) {
				contactQuery += ' AND Account.PFG_General_Investing_Interest__c INCLUDES (\'' + selectedInvestmentInterests + '\')';
				contactQuery += ' AND PFG_Asset_Mix_Coverage__c INCLUDES (\'' + selectedInvestmentInterests + '\')';
			}

			// PFG CRM Primary Lead Filter
			if(null != inputAccount.PFG_CRM_Primary_Lead__c) {
				contactQuery += ' AND (';
				contactQuery += ' 		(Account.PFG_CRM_Primary_Lead__c = \'' + inputAccount.PFG_CRM_Primary_Lead__c + '\') OR';
				contactQuery += ' 		(Account.PFG_CRM_Secondary_Lead__c = \'' + inputAccount.PFG_CRM_Primary_Lead__c + '\') OR';
				contactQuery += ' 		(Account.PFG_CRM_Real_Asset_Lead__c = \'' + inputAccount.PFG_CRM_Primary_Lead__c + '\')';
				contactQuery += ' ) ';
				contactQuery += ' ORDER By Account.Name, Contact.Name ';
			}	else if(null != inputAccount.BIM_Primary_Mktg_Rep__c) {
				// BF-20: PSG Account Rep Filter
				contactQuery += ' AND (';
				contactQuery += ' 		(Account.BIM_Primary_Mktg_Rep__c = \'' + inputAccount.BIM_Primary_Mktg_Rep__c + '\') OR';
				contactQuery += ' 		(Account.BIM_Secondary_Mktg_Rep__c = \'' + inputAccount.BIM_Primary_Mktg_Rep__c + '\')';
				contactQuery += ' ) ';
				contactQuery += ' ORDER By Account.Name, Contact.Name ';
			}

			system.debug('CSL_VFC_Mass_Opp_Creator :: search :: contactQuery=' + contactQuery);
			List<Contact> contactList = Database.query(contactQuery);
			system.debug('CSL_VFC_Mass_Opp_Creator :: search :: contactList=' + contactList);
			system.debug('CSL_VFC_Mass_Opp_Creator :: search :: contactList.size()=' + contactList.size());

			// BF-7: Find Related Opportunity by Accounts associated to the contacts
			contactWrapperList = new List<ContactWrapper>();

			// BF-20: Determine which of the returned contacts are members of active PSG Campaigns
			if(hasActivePSGCampaigns != null && hasActivePSGCampaigns) {
				// Query PSG Campaign members on active campigns
				List<CampaignMember> cmList = [SELECT Id, ContactId, Campaign.Name
											   FROM CampaignMember
											   WHERE ContactId IN :contactList
											   AND Campaign.IsActive = TRUE
											   AND (Campaign.Name LIKE '%PSG%' OR 
											    	Campaign.Name LIKE '%BIM%' OR
													Campaign.Record_Type_Developer_Name__c LIKE '%PSG%')];
				system.debug('CSL_VFC_Mass_Opp_Creator :: search :: cmList.size()=' + cmList.size());
				system.debug('CSL_VFC_Mass_Opp_Creator :: search :: cmList=' + cmList);

				// Build a unique set of contact ids based on campain member query
				if(cmList != null) {
					contactActiveCampaigns = new Map<Id, String>();
					for(CampaignMember cm : cmList) {
						if(contactActiveCampaigns.containsKey(cm.ContactId)) {
							String contactCampaigns = contactActiveCampaigns.get(cm.ContactId) + '<br/>' + cm.Campaign.Name;
							contactActiveCampaigns.put(cm.ContactId, contactCampaigns);
						}	else {
							contactActiveCampaigns.put(cm.ContactId, cm.Campaign.Name);
						}	
					}

					// Filter the contact list based on the active campaign members
					List<Contact> filteredContactList = new List<Contact>();
					for(Contact c : contactList) {
						if(contactActiveCampaigns.containsKey(c.Id)) {
							filteredContactList.add(c);
						}
					}

					// Update the contact list based on the filtered contact list
					contactList = filteredContactList;
				}
			}

			// Create a map of contact id to contact
			// Create a map of account id to a list of contacts
			Map<Id, Contact> contactMap = new Map<Id, Contact>();
			Map<Id, List<Contact>> accountContactMap = new Map<Id, List<Contact>>();
			for(Contact c : contactList) {
				contactMap.put(c.Id, c);
				if(null != c.AccountId) {
					if(accountContactMap != null && accountContactMap.containsKey(c.AccountId)) {
						accountContactMap.get(c.AccountId).add(c);
					}	else {
						accountContactMap.put(c.AccountId, new List<Contact>{c});
					}
				}

				// BF-20: Add Filtering for Campaign Members
			}

			// Check for existing opportunities with the new investment vehicle
			system.debug('CSL_VFC_Mass_Opp_Creator :: search :: inputCreateOpportunity =' + inputCreateOpportunity);
			system.debug('CSL_VFC_Mass_Opp_Creator :: search :: inputCreateOpportunity.Investment_Vehicle__c =' + inputCreateOpportunity.Investment_Vehicle__c);
			List<Opportunity> existNewOppList = [SELECT Id, StageName, RecordTypeId, OwnerId, AccountId, Amount, Investment_Vehicle__r.Name, IsClosed, Description
											  	 FROM Opportunity
											  	 WHERE AccountId IN :accountContactMap.keySet()
											  	 AND Investment_Vehicle__c = :inputCreateOpportunity.Investment_Vehicle__c];
			system.debug('CSL_VFC_Mass_Opp_Creator :: search :: existNewOppList =' + existNewOppList);
			system.debug('CSL_VFC_Mass_Opp_Creator :: search :: existNewOppList.size() =' + existNewOppList.size());

			// BF-19: Duplicate Check for closed oppty's
			closedOppByAcctMap = new Map<Id, Opportunity>();
			
			// Create a map of new opportunities based on the input create opp investment vehicle
			Map<Id, Opportunity> newOppByAcctMap = new Map<Id, Opportunity>();
			Set<Id> existNewOppIds = new Set<Id>();
			for(Opportunity o : existNewOppList) {
				if(!o.IsClosed) {
					newOppByAcctMap.put(o.AccountId, o);
					existNewOppIds.add(o.Id);
				}	else {
					//BF-19: Introduce Duplicate logic/flag based on Brookfield Updates
					closedOppByAcctMap.put(o.AccountId, o);
				}
				
			}

			// Check for existing contact roles on any oppty's with the new investment vehicle
			List<OpportunityContactRole> existOcrList = [SELECT Id, ContactId, OpportunityId
														 FROM OpportunityContactRole
														 WHERE OpportunityId IN :existNewOppIds];
			Map<Id, Set<Id>> oppOCRMap = new Map<Id, Set<Id>>();
			for(OpportunityContactRole ocr : existOcrList) {
				if(!oppOCRMap.containsKey(ocr.OpportunityId)) {
					oppOCRMap.put(ocr.OpportunityId, new Set<Id>{ocr.ContactId});
				}	else {
					(oppOCRMap.get(ocr.OpportunityId)).add(ocr.ContactId);
				}
			}


			if(!hasOpportunities) {
				for(Contact c : contactList) {
					Opportunity newVehicleOpp = (null != newOppByAcctMap) ? newOppByAcctMap.get(c.AccountId) : null;
					// Add new row without an existing opportunity and a new opp (if applicable)					
					boolean existOCR = ((null != oppOCRMap) && (null != newVehicleOpp) && (oppOCRMap.containsKey(newVehicleOpp.Id))) ? oppOCRMap.get(newVehicleOpp.Id).contains(c.Id) : false;
					// BF-21: Added Filter to hide existing opportunities, check for existing closed oppty
					boolean existCloseOppty = (null != closedOppByAcctMap) ? closedOppByAcctMap.containsKey(c.AccountId) : false;
					// BF-20: Active Campaigns for PSG
					String activeCampaigns = (null != contactActiveCampaigns) ? contactActiveCampaigns.get(c.Id) : null;
					
					if(!hideOpportunitiesCreated || (hideOpportunitiesCreated && (newVehicleOpp == null))) {
						contactWrapperList.add(new ContactWrapper(c, null, newVehicleOpp, existOCR, existCloseOppty, activeCampaigns));
					}
				}
			}	else if(hasOpportunities) {
				// Query opportunites based on the account associated to the contacts

				// Query opportunitis based on Investor Contact Lookup
				system.debug('CSL_VFC_Mass_Opp_Creator :: search :: inputOpportunity.Investment_Vehicle__c =' + inputOpportunity.Investment_Vehicle__c);
				
				// Check for opportunities using the 1a filter criteria
				system.debug('CSL_VFC_Mass_Opp_Creator :: search :: inputCreateOpportunity =' + inputCreateOpportunity);
				system.debug('CSL_VFC_Mass_Opp_Creator :: search :: inputCreateOpportunity.Investment_Vehicle__c =' + inputCreateOpportunity.Investment_Vehicle__c);
				List<Opportunity> existOppList = [SELECT Id, StageName, RecordTypeId, OwnerId, AccountId, Amount, Investment_Vehicle__r.Name, Probability, Description
												  FROM Opportunity
												  WHERE AccountId IN :accountContactMap.keySet()
												  AND Investment_Vehicle__c = :inputOpportunity.Investment_Vehicle__c];
				system.debug('CSL_VFC_Mass_Opp_Creator :: search :: existOppList =' + existOppList);
				system.debug('CSL_VFC_Mass_Opp_Creator :: search :: existOppList.size() =' + existOppList.size());
				
				// Map contacts to existing opportunites (if applicable)
				Map<Id, Opportunity> contactExistOppMap = new Map<Id, Opportunity>();
				Set<Id> existOppIds = new Set<Id>();
				if(existOppList != null && !existOppList.isEmpty()) {
					for(Opportunity o : existOppList) {
						// Check opportunity against filter criteria specified
						if(null != inputOpportunity.StageName &&
					   	   !(o.StageName.equalsIgnoreCase(inputOpportunity.StageName))) {
					   		continue;
					   	}/* BF-22: Removed RT Filter since each group has their own funds
						   	else if(null != inputOpportunity.RecordTypeId && isPFG &&
					   		 		o.RecordTypeId != inputOpportunity.RecordTypeId) {
					   		continue;
					   	}*/	else if(null != inputOpportunity.OwnerId &&
					   				o.OwnerId != inputOpportunity.OwnerId) {
					   		continue;
					   	}	else if(null != probabilityFrom && null != probabilityTo &&
					   				(o.Probability < probabilityFrom || o.Probability > probabilityTo)) {
					   		continue;
					   	}

					   	existOppIds.add(o.Id);
					  	// If the opp criteria is met find the related contacts and add to map
						if(accountContactMap.containsKey(o.AccountId)) {
							List<Contact> relContacts = accountContactMap.get(o.AccountId);
							for(Contact c : relContacts) {
								contactExistOppMap.put(c.Id, o);	
							}
						}
					}
				}
				system.debug('CSL_VFC_Mass_Opp_Creator :: search :: contactExistOppMap =' + contactExistOppMap);
				system.debug('CSL_VFC_Mass_Opp_Creator :: search :: existOppIds =' + existOppIds);
				system.debug('CSL_VFC_Mass_Opp_Creator :: search :: oppOCRMap =' + oppOCRMap);

				for(Id contactId : contactExistOppMap.keySet()) {
					Contact c = contactMap.get(contactId);
				   	Opportunity existVehicleOpp = contactExistOppMap.get(contactId);
				   	Opportunity newVehicleOpp = (null != newOppByAcctMap) ? newOppByAcctMap.get(c.AccountId) : null;
					// Add new row with the existing opportunity and new opportunity (if applicable)
				   	boolean existOCR = ((null != oppOCRMap) && (null != newVehicleOpp) && (oppOCRMap.containsKey(newVehicleOpp.Id))) ? oppOCRMap.get(newVehicleOpp.Id).contains(contactId) : false;
				   	// BF-21 : Added Filter to hide existing opportunities, check for existing closed oppty
					boolean existCloseOppty = (null != closedOppByAcctMap) ? closedOppByAcctMap.containsKey(c.AccountId) : false;
					// BF-20: Active Campaigns for PSG
					String activeCampaigns = (null != contactActiveCampaigns) ? contactActiveCampaigns.get(c.Id) : null;

					if(!hideOpportunitiesCreated || (hideOpportunitiesCreated && (newVehicleOpp == null))) {
				   		contactWrapperList.add(new ContactWrapper(c, existVehicleOpp, newVehicleOpp, existOCR, existCloseOppty, activeCampaigns));
					}
				}	
			}
			system.debug('CSL_VFC_Mass_Opp_Creator :: search :: contactWrapperList (post filtering) =' + contactWrapperList);

			if(!contactWrapperList.isEmpty()) {
				contactWrapperList.sort();
				selectedInvestmentVehicle = [SELECT Id, Name
											 FROM Investment_Vehicle__c
											 WHERE Id = :inputCreateOpportunity.Investment_Vehicle__c];
			}
		}	catch (Exception ex) {
			system.debug('CSL_VFC_Mass_Opp_Creator :: search :: ex= ' + ex.getMessage());
			system.debug('CSL_VFC_Mass_Opp_Creator :: search :: ex= ' + ex.getStackTraceString());
			system.debug('CSL_VFC_Mass_Opp_Creator :: search :: ex.getLineNumber= ' + ex.getLineNumber());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'System Error: ' + ex.getMessage()));
		}	finally {
			if(contactWrapperList != null && !contactWrapperList.isEmpty()) {
				numberResults = contactWrapperList.size();
				if(numberResults > 1000) {
					// Create a list with the first value, show an error message on the results page
					contactWrapperList = new List<ContactWrapper>{contactWrapperList.get(0)};
				}
			}	else {
				numberResults = 0;
			}

			// BF-11: Show confirm message if search after creating oppty's
			if((newOppsCreated != null || newContactRolesAdded != null) && 
			   (newOppsCreated != 0 || newContactRolesAdded != 0)) {
				ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM, newOppsCreated + ' New Opportunities Created ' + '\n' + newContactRolesAdded + ' New Contact Roles Added');
        		ApexPages.addMessage(myMsg);
			}
			newOppsCreated = 0;
        	newContactRolesAdded = 0;
		}

		// Return the results to the page
		return null;
	}

	/**
	  * BF-20: PSG Mass Opportunity Opp. Refresh based on investment vehicle
	  */
	public PageReference updateOpptyRecordType() {
		system.debug('CSL_VFC_Mass_Opp_Creator :: updateOpptyRecordType :: inputOpportunity=' + inputOpportunity);
		system.debug('CSL_VFC_Mass_Opp_Creator :: updateOpptyRecordType :: selectedInvestVehicleName=' + selectedInvestVehicleName);
		if(!String.isEmpty(selectedInvestVehicleName)) {
			try {
				Investment_Vehicle__c iv = [SELECT Id, PSG_Opportunity_Record_Type__c
											FROM Investment_Vehicle__c
											WHERE Name = :selectedInvestVehicleName];
				system.debug('CSL_VFC_Mass_Opp_Creator :: updateOpptyRecordType :: iv=' + iv);
				if(iv != null && !String.isEmpty(iv.PSG_Opportunity_Record_Type__c)) {
					inputOpportunity = new Opportunity(OwnerId = inputOpportunity.OwnerId,
													RecordTypeId = iv.PSG_Opportunity_Record_Type__c,
													StageName = inputOpportunity.StageName,
													Investment_Vehicle__c = iv.Id); 
				}
			}	catch (Exception ex) {
				system.debug(LoggingLevel.ERROR, 'CSL_VFC_Mass_Opp_Creator :: Investment Vehicle Query Error =' + ex);
			}
		}
		system.debug('CSL_VFC_Mass_Opp_Creator :: updateOpptyRecordType :: inputOpportunity=' + inputOpportunity);
		
		return null;
	}

	public PageReference createOpportunities() {
		// Create or add contact to existing opportunities on the account based on the stage/size/close date details?
		List<ContactWrapper> selectedRecords = new List<ContactWrapper>();
		// Use the new Opp By Account Map to only insert 1 opp. per account (no dupes)
		Map<Id, ContactWrapper> newOppByAccount = new Map<Id, ContactWrapper>();
		if(contactWrapperList == null || contactWrapperList.isEmpty()) {
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.Mass_Opp_Search_Contacts);
            ApexPages.addMessage(myMsg);
            return null;
		}	else {
			for(ContactWrapper cw : contactWrapperList) {
				if(cw.isSelected) {
					selectedRecords.add(cw);
					if((null == cw.newOpptyExists) && !newOppByAccount.containsKey(cw.contactSelected.Account.Id)) {
						newOppByAccount.put(cw.contactSelected.Account.Id, cw);
					}
				}
				
			}
		}

		if(selectedRecords == null || selectedRecords.isEmpty()) {
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.Mass_Opp_Select_Contacts);
            ApexPages.addMessage(myMsg);
            return null;
		}

		if(String.isEmpty(inputCreateOpportunity.Investment_Vehicle__c) ||
		   String.isEmpty(inputCreateOpportunity.StageName) ||
		   String.isEmpty(inputCreateOpportunity.RecordTypeId) ||
		   String.isEmpty(inputCreateOpportunity.OwnerId) ||
		   null == inputCreateOpportunity.CloseDate) {
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.Mass_Opp_Populate_Create_Fields);
            ApexPages.addMessage(myMsg);
            return null;
		}

		try {
			Map<Id, Opportunity> newOppByAcctInsertMap = new Map<Id, Opportunity>();
			for(ContactWrapper cw : newOppByAccount.values()) {
				Opportunity newOpp = new Opportunity();
				newOpp.Name = inputCreateOpportunity.Investment_Vehicle__c + ' - ' + cw.contactSelected.Account.Name;
				newOpp.Amount = cw.oppSize;
				// BF-21: Added Description Field
				newOpp.Description = cw.oppDescription;
				newOpp.AccountId = cw.contactSelected.Account.Id;
				newOpp.Investment_Vehicle__c = inputCreateOpportunity.Investment_Vehicle__c;
				newOpp.StageName = inputCreateOpportunity.StageName;
				newOpp.CloseDate = inputCreateOpportunity.CloseDate;
				newOpp.OwnerId = inputCreateOpportunity.OwnerId;
				newOpp.CurrencyIsoCode = settings.Default_New_Opp_Currency__c;
				newOpp.Mass_Created_Opportunity__c = true;

				// BF-20: Updated to dynamically set RT based on Investment Vehicle for PSG
				if(isPSG) {
					if(inputCreateOpportunity.Investment_Vehicle__c != null) {
						Investment_Vehicle__c iv = [SELECT Id, PSG_Opportunity_Record_Type__c
													FROM Investment_Vehicle__c
													WHERE Id = :inputCreateOpportunity.Investment_Vehicle__c];
						if(iv != null && !String.isEmpty(iv.PSG_Opportunity_Record_Type__c)) {
							newOpp.RecordTypeId = iv.PSG_Opportunity_Record_Type__c;
						}
					}	else {
						newOpp.RecordTypeId = inputCreateOpportunity.RecordTypeId;
					}
				}	else {
					newOpp.RecordTypeId = inputCreateOpportunity.RecordTypeId;
				}
				
				if(closedOppByAcctMap != null && closedOppByAcctMap.containsKey(cw.contactSelected.Account.Id)) {
					newOpp.Duplicate__c = true;
					newOpp.Name += ' - ' + Date.today();
				}

				cw.newOppty = newOpp;
				newOppByAcctInsertMap.put(cw.contactSelected.Account.Id, newOpp);
			}

			system.debug('CSL_VFC_Mass_Opp_Creator :: createOpportunities :: newOppByAcctInsertMap=' + newOppByAcctInsertMap);
			insert newOppByAcctInsertMap.values();

			// Create the corresponding contact roles
			// Add unique contact roles for all contacts selected, either to the newly created opp or an existing opp
			List<OpportunityContactRole> newOCRList = new List<OpportunityContactRole>();
			for(ContactWrapper cw : selectedRecords) {
				OpportunityContactRole ocr = new OpportunityContactRole(ContactId = cw.contactSelected.Id,
														  				Role = settings.Default_Opp_Contact_Role__c);
				if(newOppByAcctInsertMap.containsKey(cw.contactSelected.Account.Id)) {
					ocr.OpportunityId = newOppByAcctInsertMap.get(cw.contactSelected.Account.Id).Id;
				}	else if(null != cw.newOpptyExists) {
					ocr.OpportunityId = cw.newOpptyExists.Id;
				}
				system.debug('CSL_VFC_Mass_Opp_Creator :: createOpportunities :: ocr=' + ocr);

				if(null != ocr.OpportunityId) {
					newOCRList.add(ocr);
				}
			}
			system.debug('CSL_VFC_Mass_Opp_Creator :: createOpportunities :: newOCRList=' + newOCRList);
			insert newOCRList;

			// BF-11: Store results to show after search
        	newOppsCreated = newOppByAcctInsertMap.size();
			newContactRolesAdded = newOCRList.size();

        	return search();

		}	catch (Exception ex) {
			system.debug('CSL_VFC_Mass_Opp_Creator :: createOpportunities :: ex=' + ex.getMessage());
			system.debug('CSL_VFC_Mass_Opp_Creator :: createOpportunities :: ex=' + ex.getStackTraceString());
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage());
	        ApexPages.addMessage(myMsg);
		}

		return null;
	}

	/**
	  * BF-11: Added Cancel Button to return to home page
	  */
	public PageReference cancel() {
		PageReference homePage = new PageReference('/');
		return homePage;
	}

	public class ContactWrapper implements Comparable {
        public boolean isSelected {get;set;}
        public boolean newOpptyExistContactRole {get; set;}
		public boolean existingClosedOppty {get; set;}
        public Contact contactSelected  {get;set;}
        public Opportunity existingOppty {get;set;}
        public Opportunity newOppty {get;set;}
        public Opportunity newOpptyExists {get; set;}
        public Decimal previousOppSize {get; set;}
        public Decimal oppSize {get; set;}
		public String oppDescription {get; set;}
		public String activeCampaigns {get; set;}
        
        public ContactWrapper(Contact c, Opportunity existOpp, Opportunity newOpp, boolean newOpptyExistContactRole, boolean existingClosedOppty, String activeCampaigns) {
        	Mass_Opp_Creation__c settings = Mass_Opp_Creation__c.getValues('PFG');
        	
            this.isSelected = false;
            this.contactSelected = c;
            this.existingOppty = existOpp;
            // Only set previous Opp Size if not equal to 0
            if(this.existingOppty != null) {
            	this.previousOppSize = (Decimal)this.existingOppty.Amount;
            }

            // Default the opp size to the previous opp size or based on the settings
            if(null == this.previousOppSize || (this.previousOppSize == 0)) {
            	this.oppSize = (settings.Default_Opp_Size__c).intValue();
            }	else {
            	this.oppSize = this.previousOppSize;
            }
            
            this.newOppty = null;
            this.newOpptyExists = newOpp;
            this.newOpptyExistContactRole = newOpptyExistContactRole;
			this.existingClosedOppty = existingClosedOppty;
			this.activeCampaigns = activeCampaigns;
			this.oppDescription = (newOpp != null && newOpp.Description != null) ? newOpp.Description : null;
		}

        // BF-7: Custom sort by account name, then contact name
        public Integer compareTo(Object compareTo) {
        	ContactWrapper cwCompareTo = (ContactWrapper)compareTo;

        	if((contactSelected.Account.Name).compareto(cwCompareTo.contactSelected.Account.Name) != 0) {
    			return (contactSelected.Account.Name).compareto(cwCompareTo.contactSelected.Account.Name);
    		}	else {
    			return (contactSelected.Name).compareto(cwCompareTo.contactSelected.Name);
    		}
        }
    }
}