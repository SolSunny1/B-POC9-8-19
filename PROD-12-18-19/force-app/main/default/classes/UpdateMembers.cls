/*
This class is used to update mass campaign members fields associated with a campaign
It takes following parameters:
 * bfin1 - admin space (grid: Status, Company, Name, Covering Professionals, Date CA Signed, Date CIM Sent, Data Room Access Granted, Presentation, Site Tour)
 * bfin2 - marketing space (grid: Status, Company, Name, Covering Professionals, Status Highlights, Bid Probability)

*/

public with sharing class UpdateMembers {
    //Variables define
    public integer pageNo {get;set;}
    public integer lastPageNo {get;set;}
    public integer pageSize {get;set;}
    public integer totalCount{get;set;}
    public string strName{get;set;}
    public string strSearchStatus{get;set;}
    public id ids {get;set;}
    public boolean contextItem{get;set;}
    public set<string> idMembers{get;set;}
    //Object created to get data from page 
    public CampaignMember objCampMember{get;set;}
    public CampaignMember objSearchCampMember{get;set;}
    public boolean isStatusUpdate{get;set;}
    public boolean isBidProbabilityUpdate{get;set;}
    public boolean isDateCASignedUpdate{get;set;}
    public boolean isDateCIMSentUpdate{get;set;}
    public boolean isCoveringProfessional{get;set;}
    public boolean isDatePresentationCompleted{get;set;}
    public boolean isSiteTour{get;set;}
    public boolean isDateFlyerSent{get;set;}
    public boolean isDataRoomAccessGranted {get;set;}
    public boolean nextDisable{get;set;}
    public boolean firstDisable{get;set;}
    public boolean allCheckboxes{get;set;}
    public boolean previousDisable{get;set;}
    public boolean lastDisable{get;set;}
    public string recordDetails {get;set;}
    //Collection define
    private map<integer,list<CampaignMemberWrapper>> mapKeyCampignmember{get;set;}
    public list<CampaignMemberWrapper> lstCampaignMembers {get;set;}
    public list<CampaignMemberWrapper> listCampaignMemberWrapper{get;set;}
    
    public String state {get;set;}
    
    //Constructor for class
    public UpdateMembers(ApexPages.StandardController controller) 
    {
        mapKeyCampignmember = new  map<integer,list<CampaignMemberWrapper>>();
        lstCampaignMembers = new list<CampaignMemberWrapper>();
        integer counter = 1;
        this.allCheckboxes = false;
        this.idMembers = new set<string>();
        this.objSearchCampMember = new CampaignMember();
        this.objCampMember = new CampaignMember();
        //Get page size from custom setting if value is null pagesize will be 5
        if(System_Setting__c.getall().values()!=null && System_Setting__c.getall().values()[0].Mass_Update_Campaign_Member_List__c!=null)
            pageSize = integer.valueof(System_Setting__c.getall().values()[0].Mass_Update_Campaign_Member_List__c);
        else
            pageSize = 5;
        this.strName = '';
        totalCount = 0;
        pageNo = 1;
        integer pageCounter = 0;
        //set state
        if (ApexPages.currentPage().getParameters().containsKey('st')){
            this.state = ApexPages.currentPage().getParameters().get('st');
            if (this.state != 'bfin1' && this.state != 'bfin2') {
                this.state = 'bfin1';
            }
        } else {
            this.state = 'bfin1';
        }
        //Campaign sfdc id
        ids = ApexPages.currentPage().getParameters().get('Id');
        //Get all campaign members associated with campaign
        //bfin1
        if (this.state == 'bfin1') {
            for (CampaignMember objCamMember : [Select Id, Status,Covering_Professional__c , Date_Presentation_Completed__c,Site_Tour__c,Data_Room_Access_Granted__c,Contact.Account.Name,Contact.Account.Id, contact.name,  Date_CA_Signed__c,Date_CA_Executed__c,Date_CIM_Sent__c, Date_Flyer_Sent__c, Contact.FirstName,Contact.lastname FROM CampaignMember where campaignId =:ids Order By Contact.Account.Name, Contact.FirstName])
            {
              totalCount++;
              list<CampaignMemberWrapper> listTemp = new list<CampaignMemberWrapper>();
              if(pageCounter == pageSize)
              {
                pageCounter = 0;
                counter++;
                
              }
              CampaignMemberWrapper objCampaignMemberWrapper = new CampaignMemberWrapper(objCamMember,false);
              if(mapKeyCampignmember.containskey(counter))
               listTemp = mapKeyCampignmember.get(counter);
              
              listTemp.add(objCampaignMemberWrapper);
              pageCounter++;
              mapKeyCampignmember.put(counter,listTemp);
            }
        } else if (this.state == 'bfin2') {
        //bifin2 - Status, Company, Name, Covering Professionals, Status Highlights, Bid Probability
            for (CampaignMember objCamMember : [Select Id, Status,Bid_Probability__c,Covering_Professional__c, Status_Highlights__c, Primary_Contact_for_Offering__c, Contact.Account.Name,Contact.Account.Id, contact.name, Contact.FirstName,Contact.LastName FROM CampaignMember where campaignId =:ids Order By Contact.Account.Name, Contact.FirstName])
            {
              totalCount++;
              list<CampaignMemberWrapper> listTemp = new list<CampaignMemberWrapper>();
              if(pageCounter == pageSize)
              {
                pageCounter = 0;
                counter++;
                
              }
              CampaignMemberWrapper objCampaignMemberWrapper = new CampaignMemberWrapper(objCamMember,false);
              if(mapKeyCampignmember.containskey(counter))
               listTemp = mapKeyCampignmember.get(counter);
              
              listTemp.add(objCampaignMemberWrapper);
              pageCounter++;
              mapKeyCampignmember.put(counter,listTemp);
            }
        }    
        lastPageNo = mapKeyCampignmember.size();
       
       //Decide if total page is 1 disbale next and previous button
        if(lastPageNo<2)
        {
         nextDisable = true;
         previousDisable = true;
        }
        //Show by default page 1
        lstCampaignMembers =  mapKeyCampignmember.get(pageNo); 
        buttonDisable();      
    }
    
    public void doDeselectItem(){       
       for(list<CampaignMemberWrapper> lstCampTemp : mapKeyCampignmember.values())
       {
        for(CampaignMemberWrapper obj : lstCampTemp)
         {
            if(contextItem)
            obj.isCheck = true;
            else
            obj.isCheck = false;
         }
       }
    }
    
   public List<SelectOption> getCampaignMemberStatus() 
   {
        List<SelectOption> status = new List<SelectOption>();
        status.add(new SelectOption('--None--','--None--'));
        //Start code change 06/28/2015 
/*
        for(CampaignStatus__c obj: [select id , name from CampaignStatus__c order by SortOrder__c])
        {
          status.add(new SelectOption(obj.Name,obj.Name));
        }
*/
		String strQuery;
		//Query for the Campaign record types

		List<RecordType> rtypes = [Select Name, Id From RecordType
					  where sObjectType='Campaign' and isActive=true];

		//Create a map between the Record Type Name and Id for easy retrieval
		Map<String,String> campaignRecordTypes = new Map<String,String>{};

		for(RecordType rt: rtypes)
			campaignRecordTypes.put(rt.Name,rt.Id);
		//Get appropriate Campaign Status list based on Campaign Record Type. 
		Campaign campaign = [select recordtypeId from campaign where Id=:ids];
		  if(campaign.recordtypeId == campaignRecordTypes.get('PFG'))
		  {
			for(CampaignStatus__c obj: [Select Name from CampaignStatus__c where Campaign_Record_Type__c like '%;PFG;%' order by SortOrder__C])
			{
			  status.add(new SelectOption(obj.Name,obj.Name));
			}
		  }
		  else if (campaign.recordtypeId == campaignRecordTypes.get('BFIN') || campaign.recordtypeId == campaignRecordTypes.get('BFIN_Traditional')){
			for(CampaignStatus__c obj: [Select Name from CampaignStatus__c where (Campaign_Record_Type__c like '%BFIN%' or Campaign_Record_Type__c like '%BFIN_Traditional%') order by SortOrder__C])
			{
			  status.add(new SelectOption(obj.Name,obj.Name));
			}
		  }
    
   //End of Code change
   
        return status;
    }
    //Display members after search on name 
     public void searchbyName() 
     {
         set<Id> idschecked = new set<Id>();
        map<Id,CampaignMember> updatedList = new map<Id,CampaignMember>();
        if(lstCampaignMembers!=null && lstCampaignMembers.size()>0)
           {
             for(CampaignMemberWrapper objCampaignMemberWrapper : lstCampaignMembers)
             {
               if(objCampaignMemberWrapper.IsCheck)
               {
                idschecked.add(objCampaignMemberWrapper.objCampaignMember.Id);
                updatedList.put(objCampaignMemberWrapper.objCampaignMember.Id,objCampaignMemberWrapper.objCampaignMember);
               }
             }
           }
           system.debug(idschecked+'----idschecked----');
       //Intilize values again  
        mapKeyCampignmember = new  map<integer,list<CampaignMemberWrapper>>();
        lstCampaignMembers = new list<CampaignMemberWrapper>();
        integer counter = 1;
        totalCount = 0;               
        pageNo = 1;
        integer pageCounter = 0;
         String[] filters = new String[]{};
           if(strName.contains(','))
           {
               for(string str :strName.split(','))
               {
                 filters.add('%'+str.trim() +'%');
               }
           }else
           {
              filters.add('%'+strName.trim() +'%');
           }
          string filterCoverPro = '';
           IF(objSearchCampMember.Covering_Professional__c!=NULL)
           {
               filterCoverPro =  ' AND Covering_Professional__c = \'' +objSearchCampMember.Covering_Professional__c+'\' ';
               
           }
           IF(objSearchCampMember.Status!=NULL && objSearchCampMember.Status!='--None--')
           {
               filterCoverPro +=  ' AND Status = \'' +objSearchCampMember.Status+'\' ';
               
           }
        //Search on name is wild character search
       // string conName = '%'+strName+'%';
        //get all campaign member based on name and Campaign Id
        String qString = 'Select Id, Status,Covering_Professional__c , Date_Presentation_Completed__c,Site_Tour__c,Data_Room_Access_Granted__c,Contact.Account.Name,Contact.Account.Id, contact.name,  Date_CA_Signed__c,Date_CA_Executed__c,Date_CIM_Sent__c, Date_Flyer_Sent__c, Contact.FirstName,Contact.lastname FROM CampaignMember';
        if (this.state == 'bfin2') {
            qString = 'Select Id, Status,Bid_Probability__c,Covering_Professional__c, Status_Highlights__c, Primary_Contact_for_Offering__c, Contact.Account.Name,Contact.Account.Id, contact.name, Contact.FirstName,Contact.LastName FROM CampaignMember';
        }
        for (CampaignMember objCamMember : Database.Query(qString + ' where  (Id in: idschecked) or ( (contact.name like :filters or Contact.Account.Name like :filters) and campaignId =:ids  '+filterCoverPro+' ) Order By Contact.Account.Name, Contact.FirstName'))
        {
          totalCount++;
          list<CampaignMemberWrapper> listTemp = new list<CampaignMemberWrapper>();
          if(pageCounter == pageSize)
          {
            pageCounter = 0;
            counter++;
            
          }
          //Creating a map of integer which is page no and value as list of campaign member
          if(mapKeyCampignmember.containskey(counter))
           listTemp = mapKeyCampignmember.get(counter);
           CampaignMemberWrapper objCampaignMemberWrapper = null;
           if(idschecked.contains(objCamMember.Id))
           {
                objCampaignMemberWrapper = new CampaignMemberWrapper(updatedList.get(objCamMember.Id),true);
           }
           else
               objCampaignMemberWrapper = new CampaignMemberWrapper(objCamMember,false);
           
          
          listTemp.add(objCampaignMemberWrapper);
          pageCounter++;
          //Each page will have some records
          mapKeyCampignmember.put(counter,listTemp);
        }
        //total no of pages
        lastPageNo = mapKeyCampignmember.size();
        //Hide and show button Next and previous based on no of pages
        if(lastPageNo<2)
        {
         nextDisable = true;
         previousDisable = true;
        }
        //Show first page by default pageNo = 1
        lstCampaignMembers =  mapKeyCampignmember.get(pageNo); 
        buttonDisable();  
     }
    //Temporary data save 
   public void  updateTable()
   {
    try{
          mapKeyCampignmember.put(pageNo,lstCampaignMembers);
          list<CampaignMember> lstTempCampaignMembers = new list<CampaignMember>();
          //Get all the records from map to a list and the update them
           boolean isAnyRecordSelected = true;
            for(list<CampaignMemberWrapper> lstCampTemp :  mapKeyCampignmember.values())
            {
                 for(CampaignMemberWrapper obj : lstCampTemp)
                 {
                      if(obj.isCheck)
                      {
                         isAnyRecordSelected = false;
                          if(isStatusUpdate)
                          {
                           obj.objCampaignMember.Status = objCampMember.Status;
                          }
    
                          if(isBidProbabilityUpdate)
                          {
                          
                             obj.objCampaignMember.Bid_Probability__c = objCampMember.Bid_Probability__c;
                          }
                           if(isCoveringProfessional)
                          {
                          
                             obj.objCampaignMember.Covering_Professional__c = objCampMember.Covering_Professional__c;
                          }
                           if(isDatePresentationCompleted)
                          {
                          
                             obj.objCampaignMember.Date_Presentation_Completed__c = objCampMember.Date_Presentation_Completed__c;
                          }
                           if(isSiteTour)
                          {
                          
                             obj.objCampaignMember.Site_Tour__c = objCampMember.Site_Tour__c;
                          }
                           if(isDataRoomAccessGranted)
                          {
                          
                             obj.objCampaignMember.Data_Room_Access_Granted__c = objCampMember.Data_Room_Access_Granted__c;
                          }
                          if(isDateCASignedUpdate)
                          {
                             obj.objCampaignMember.Date_CA_Signed__c = objCampMember.Date_CA_Signed__c;
                          }
                          if(isDateCIMSentUpdate)
                          {
                          
                             obj.objCampaignMember.Date_CIM_Sent__c = objCampMember.Date_CIM_Sent__c;
                          }
                          if(isDateFlyerSent)
                          {
                              obj.objCampaignMember.Date_Flyer_Sent__c = objCampMember.Date_Flyer_Sent__c;
                          }
                          lstTempCampaignMembers.add(obj.objCampaignMember);
                      }
                 }
            
            }
            system.debug(isAnyRecordSelected+'----isAnyRecordSelected---');
           if(isAnyRecordSelected)
           {
             ApexPages.addmessage(new ApexPages.message(ApexPages.severity.info,label.No_record_Selected)); 
            }
    }
    catch(exception ex)
    {
        //If fail show exception error on page
      ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, ex.getMessage()));
      
    }
   }
   //Update campaign members records
   public PageReference  updateMassCampaignMembers()
   {
    try{
         mapKeyCampignmember.put(pageNo,lstCampaignMembers);
        list<CampaignMember> lstTempCampaignMembers = new list<CampaignMember>();
        //Get all the records from map to a list and the update them
         
        
            for(list<CampaignMemberWrapper> lstCampTemp :  mapKeyCampignmember.values())
            {
                 for(CampaignMemberWrapper obj : lstCampTemp)
                 {
                   lstTempCampaignMembers.add(obj.objCampaignMember);
                 }
            
            }
        
        update lstTempCampaignMembers;
        //Is success redirect to campaign page
        //pagereference pge = new pagereference('/'+ids);
        return null;
       }
       catch(exception ex)
      {
            //If fail show exception error on page
          ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.Error, ex.getMessage()); 
          return null;
       }
    }
   
    // returns the first page of records
     public void first() 
     {
       mapKeyCampignmember.put(pageNo,lstCampaignMembers);
       pageNo = 1;
       lstCampaignMembers =  mapKeyCampignmember.get(pageNo); 
       if(allCheckboxes)
       {
          for(CampaignMemberWrapper obj :lstCampaignMembers)
          {
            obj.isCheck = true;
          }      
      }
      buttonDisable();     
      }

     // returns the last page of records
     public void last() 
     {
         mapKeyCampignmember.put(pageNo,lstCampaignMembers);
         lstCampaignMembers =  mapKeyCampignmember.get(lastPageNo);
         pageNo = lastPageNo; 
          if(allCheckboxes)
          {
            for(CampaignMemberWrapper obj :lstCampaignMembers)
            {
             obj.isCheck = true;
            }      
          }
         buttonDisable();    
     }
     //This method decide which button need to be shown and which need to be disabled
      public void buttonDisable()
      {
        if(lastPageNo == 1 && pageNo == 1)
        {
          recordDetails =1+' to '+lstCampaignMembers.size();
          lastDisable = true;
          nextDisable = true;
          previousDisable = true;
          firstDisable = true;
        }
        else if(pageNo == 1 && lastPageNo > pageNo)
        {         
           previousDisable = true;
           firstDisable = true;
           lastDisable = false;
           nextDisable = false;
            recordDetails = 1 +' to '+lstCampaignMembers.size();
        }
        else if(pageNo > 1 && lastPageNo > pageNo)
        {
          lastDisable = false;
          nextDisable = false;
          previousDisable = false;
          firstDisable = false;
          recordDetails =string.valueof((pageNo-1) * pageSize)+' to '+string.valueof(((pageNo-1) * pageSize)+lstCampaignMembers.size());
        }
        else if(pageNo == lastPageNo && lastPageNo >1)
        {
          lastDisable = true;
          nextDisable = true;
          previousDisable = false;
          firstDisable = false;
          recordDetails =string.valueof((pageNo-1) * pageSize)+' to '+string.valueof(((pageNo-1) * pageSize)+lstCampaignMembers.size());
        }
        
      
      }
     // returns the previous page of records
     public void previous() 
     {
        mapKeyCampignmember.put(pageNo,lstCampaignMembers);
        pageNo = pageNo -1;         
        //Save any previous page changes to map
        lstCampaignMembers =  mapKeyCampignmember.get(pageNo);
          if(allCheckboxes)
          {
           for(CampaignMemberWrapper obj :lstCampaignMembers)
           {
            obj.isCheck = true;
           }      
          }
        buttonDisable(); 
     }

     // returns the next page of records
     public void next() 
     {
         mapKeyCampignmember.put(pageNo,lstCampaignMembers);
         pageNo = pageNo + 1;
         //Save any previous page changes to map
         lstCampaignMembers =  mapKeyCampignmember.get(pageNo);
         if(allCheckboxes)
          {
           for(CampaignMemberWrapper obj :lstCampaignMembers)
           {
             obj.isCheck = true;
           }      
          }
        buttonDisable(); 
     }

    // returns the PageReference of the original page, if known, or the home page.
     public pagereference cancel() {
         pagereference pge = new pagereference('/'+ids);
         return pge;     
      }
  //Wrapper class used for checkbox on each campaign member
  public class CampaignMemberWrapper
  {
    public CampaignMember objCampaignMember{get;set;}
    public boolean isCheck{get;set;}
    public CampaignMemberWrapper(CampaignMember objCamMember, boolean isCheck)
    {
      this.objCampaignMember = objCamMember;
      this.isCheck = isCheck;
    }
  
  }
}