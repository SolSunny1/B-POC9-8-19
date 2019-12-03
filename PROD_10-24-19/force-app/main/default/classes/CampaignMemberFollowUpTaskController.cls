public class CampaignMemberFollowUpTaskController {
  
    
    public String SelectedCampaign {get; set;}
    public boolean showCampaignSelection {get; set;}
    //pageMessage
    public String pageMessageTitle {get; set;}
    public String pageMessageDetail {get; set;}
    //Get member Status from page
    public String memberStatus {get; set;}
    //Campaign id
    public string stringcid {get;set;}
    String[] filters ;
    private set<Id> idsCampaignmember{get;set;}
    public Integer pageMessageStrength {get; set;}
    public boolean showPageMessage {get; set;}
    //public boolean showCMTable {get; set;}
    public boolean showtask {get; set;}
    public boolean CMOwner {get; set;}
     set<Id> idschecked =null;
    public boolean allCMselected {get; set;}
    public CampaignMember objCampaignMember{get;set;}
    public boolean showSelectButton {get; set;}
    // error message status if 'Create Follow Up' Button was pushed without selected CMembers
    public boolean showFollowUpButtonMessage {get; set;}
    //whole query CM list
    List<MyCampaignMember> CMemberList = new List<MyCampaignMember>();
    //all CM list with no valid user for task creation
    List<MyCampaignMember> BadCMemberList = new List<MyCampaignMember>();
    // CM list for the current page
    List<MyCampaignMember> CMemberListNext = new List<MyCampaignMember>();
    //list of all Tasks to be created
    List<Task> OwnerTodoList = new List<Task>();
    //prefilled Value to display in Follow Up Section
    Task OwnerTodo = new Task();
    Map<String,String> CampaignOwner = new Map<String,String>{};
    public Map<String, boolean> SelectedCM = new Map<String, boolean>{};
    //for Paging: set 'next' and 'count' to the number of your paging size,    
    //both should have the same value
    Integer next = 10, count = 10;
    boolean shownext, showprev = false;
    //helper for coping CMemberListNext.checkedMember status back to CMemberList.checkedMember 
    Integer copydownlimit;
    public boolean getshownext(){return shownext;}
    public boolean getshowprev(){return showprev;} 
    //checkbox per page
    private boolean allCheckboxes = false;
    
    
    public List<MyCampaignMember> getBadCMemberList(){
        return BadCMemberList;
    }
    
    
    //get and set for allCheckboxes only used from message
    public boolean getallCheckboxes(){
        return allCheckboxes;
    }
    public void setallCheckboxes(boolean allCheckboxes){}
    
    public void changeCheckbox(){
        if(allCheckboxes){
            allCheckboxes = false;
        }else{
            allCheckboxes = true;
        }
        CheckboxValue(allCheckboxes);
        copyList();
    }
    
    public void changeSingleCheckbox(){copyList();}
    
    public Integer getSelectedCM() { if(SelectedCM.size()>0)return SelectedCM.size(); else return idschecked.size(); }
    
    //Multiselect checkbox
    public void CheckboxValue(boolean cb){
        Integer j;
        if(CMemberListNext.size()<count){
            j = CMemberListNext.size();
        }else{
            j=count;
        }
        for(Integer i=0; i<j; i++) {
            if(cb == true){
                CMemberListNext[i].checkedMember = true;
            } else {
                CMemberListNext[i].checkedMember = false;
            }
        }
    }
    
    public void selectAllCMembers(){
        if( allCMselected){
            allCMselected = false;
        }else{
            allCMselected = true;
        }
        for(Integer i=0;i<CMemberList.size();i++){
            CMemberList[i].checkedMember = allCMselected;
            if( allCMselected){
                SelectedCM.put(CMemberList.get(i).Id, CMemberList.get(i).checkedMember);
                }else{
                SelectedCM.remove(CMemberList.get(i).Id);   
            }   
            CheckboxValue(allCMselected);
        }   
    }
        
    public List<MyCampaignMember> getCMemberListNext(){
        return CMemberListNext;
    }
    public void setCMemberListNext(List<MyCampaignMember> CMemberListNext){
        this.CMemberListNext = CMemberListNext;
    }
    
    //Controller Constructor checks for campagin id query parameter and shows 
    public CampaignMemberFollowUpTaskController(){
    	
    	 filters = new String[]{};
    	 this.memberStatus = '';
    	 this.idschecked = new set<Id>();
    	 objCampaignMember = new CampaignMember();
    	 idsCampaignmember = new set<Id>();
      if(System_Setting__c.getall().values()!=null && System_Setting__c.getall().values()[0].Mass_Update_Campaign_Member_List__c!=null)
      {
        count  = integer.valueof(System_Setting__c.getall().values()[0].Mass_Task_Follow_Up_Size__c);
        next = count;
      }
          filterTitle ='';
          stringcid = ApexPages.currentPage().getParameters().get('Id');
         Schema.DescribeSObjectResult cr = Campaign.sObjectType.getDescribe();
        if(stringcid != null && stringcid != ''){
            if((stringcid.substring(0,3)== cr.getKeyPrefix()) && (stringcid.length()==18 ||stringcid.length()==15)){    
                    try{
                        Campaign camp = [SELECT ownerId, Id FROM Campaign WHERE Id =:stringcid];
                        if(camp != null){
                            System.debug('campaign : '+camp);
                            CampaignOwner.put(camp.Id, camp.ownerId);
                            SelectedCampaign = camp.Id;
                            showCampaignSelection = false;
                            renderFollowUpTrue();
                        }
                    }catch (Exception e){
                    System.debug('no campaign found or no valid format');
                    showCampaignSelection = true;
                    }
            }else{
            System.debug('query param is not a valid campagin id');
            showCampaignSelection = true;   
            }
        }else{
         System.debug('no query parameter for id');
         showTask = false;
         showCampaignSelection = true;
        }
        
        showFollowUpButtonMessage = false;
        
        allCMselected = false;
        CMOwner = true;
        
    }
       //Show Status picklist on page through Custom setting
       public  List<SelectOption> getCampaignMemberStatus() {
        List<SelectOption> status = new List<SelectOption>();
         status.add(new SelectOption('','All'));
		for(CampaignStatus__c obj: [select id , name from CampaignStatus__c order by SortOrder__c])       
		{
		  status.add(new SelectOption(obj.Name,obj.Name));
		}
        return status;
    }
    // campaign member wrapper class
    public class MyCampaignMember {
        public String Id {get; set;}
        public String FirstName {get; set;}
        public String LastName {get; set;}
        public date DateCIMSent {get;set;}
        public String bidProbility {get; set;}
        public date DateCASigned {get; set;}
        public String Status {get; set;}
        public String OwnerId {get; set;}
        public boolean checkedMember{get; set;}
        public String WhoId {get; set;}
        public string company {get;set;}
        public boolean OwnerIsActive {get; set;}
        public MyCampaignMember() {
            checkedMember = false;
        }
    }
    
    //helpers for FollowUp Page Block
    public void renderFollowUpTrue() {
        showtask = true;
        OwnerTodo.clear();
        
        loadCampaignMemberList(true);
    }
    public void renderFollowUpFalse() {
        showtask = false;
        OwnerTodo.clear();
        renderCMresultsFalse();
    }
    //helper for CMresults Page Block
    public void renderCMresultsFalse(){
        SelectedCM.clear();
        cMemberList.clear();
        CMemberListNext.clear();
    }
    
    public Task getOwnerTodo() {
        OwnerTodo.OwnerId = CampaignOwner.get(SelectedCampaign);
        OwnerTodo.whatId = SelectedCampaign;
        OwnerTodo.priority = 'Normal';
        OwnerTodo.Status = 'Not Started';
        ownertodo.Type ='';
        return OwnerTodo;
    }
    public void setOwnerTodo(Task OwnerTodo) {
        this.OwnerTodo = OwnerTodo;
    }
    
    //Populate Task information
    public void generateTodos(){
    	 this.idschecked = new set<Id>();
    	OwnerTodoList = new list<Task>();
        copyList();
        //PageReference apexRef = new PageReference('/'+stringcid);
        if(CMemberList.size() >0){
        for(integer i=0;i<CMemberList.size();i++){
            if(SelectedCM.size() > 0){
                if(CMemberList.get(i).checkedMember == true && SelectedCM.get(CMemberList.get(i).Id) == true ){
                    Task t = new task();
                       idsCampaignmember.add(CMemberList.get(i).id);                  
                        t.OwnerId = OwnerTodo.OwnerId;                        
                        t.whatId = OwnerTodo.whatId;                        
                        t.priority = OwnerTodo.priority;
                        t.Status = OwnerTodo.Status;
                        t.ActivityDate = ownertodo.activitydate;
                        t.subject = ownertodo.subject;
                        t.description = ownertodo.description;
                        t.WhoId = CMemberList.get(i).WhoId;
                        t.type  = ownertodo.type;
                        t.isReminderSet = OwnerTodo.isReminderSet;
                        t.ReminderDateTime = OwnerTodo.ReminderDateTime;
                        OwnerTodoList.add(t);   
                    
                }else{
                    if(CMemberList.get(i).checkedMember == true &&  SelectedCM.get(CMemberList.get(i).Id) != true){
                        System.debug(logginglevel.WARN, 'Warning: Integraty Problem between CMemberList State and SelectedCM State!');
                    }
                    if(CMemberList.get(i).checkedMember != true && SelectedCM.get(CMemberList.get(i).Id) == true){
                        System.debug(logginglevel.WARN, 'Warning: Integraty Problem between CMemberList State and SelectedCM State!');
                    }
                }
                
            }else {
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO, label.No_Campaign_Selected);
               // apexRef = null;
                showFollowUpButtonMessage = true;   
            }
        }
        if(OwnerTodoList.size()>0)
        {
        insert OwnerTodoList;
          ApexPages.addmessage(new ApexPages.message(ApexPages.Severity.confirm, label.Mass_Task_Creation_for_Contacts)); 
        }else
        {
           ApexPages.addmessage(new ApexPages.message(ApexPages.Severity.Warning, 'Please select a contact to create task.')); 
        	
        }
        loadCampaignMemberList(false);
          // ApexPages.message(ApexPages.severity.confirm,label.Mass_Task_Creation_for_Contacts); 
        
        
        if(BadCMemberList.size() > 0){
            //call bad CM box
            
            pageMessageTitle = label.Campaign_Title_Error;
            pageMessageDetail ='For '+BadCMemberList.size()+ label.Campaign_Member_detail_Error_on_Creation;
           
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.info,pageMessageTitle+' '+pageMessageDetail)); 
            
        }   
        }else{
           
            showFollowUpButtonMessage = true;
        }
        
    }
            
 
    
    //get List MyCampaignMembers
    public void loadCampaignMemberList(boolean isCallFromSearchOrConstr) {
        showFollowUpButtonMessage = false;
        allCheckboxes = false;
        SelectedCM.clear();
        cMemberList.clear();
        CMemberListNext.clear();
       // this.idschecked = new set<Id>();
         
        if(countCMresults()<=5000){
            for (CampaignMember CM: queryCM()) {
                MyCampaignMember MyCM = new MyCampaignMember();
                if (CM != null) {
                    try {
                        if(CM.ContactId != null){
                            
                            MyCM.WhoId = CM.ContactId;
                            MyCM.FirstName = CM.Contact.FirstName;
                            MyCM.LastName = CM.Contact.LastName;
                            myCM.company = CM.Contact.Account.Name;
                            MyCM.bidProbility = CM.Bid_Probability__c;
                            MyCM.DateCASigned = CM.Date_CA_Signed__c;
                            MyCM.Status = CM.Status;
                            
                            MyCM.OwnerId = CM.Contact.OwnerId;
                            MyCM.DateCIMSent = CM.Date_CIM_Sent__c;
                            MyCM.OwnerIsActive = CM.Contact.Owner.IsActive;
                           
                        }
                        system.debug(idschecked+'----idschecked---'+idschecked.Contains(CM.Id));
                        if(idschecked.Contains(CM.Id))
                        {
                          MyCM.checkedMember = true;
                        }
                        MyCM.Id = CM.Id;
                        CMemberList.add(MyCM);
                    } catch (exception e) {
                        System.debug('CML Error Message: '+ e);
                        }
                }
            }
        
        if(CMemberList != null && CMemberList.size()>count){
            for(Integer i=0; i<count; i++) {
                CMemberListNext.add(CMemberList.get(i));
            }
            shownext = true;
            PageUntil = count;
        }else{
            for(integer i=0;i<CMemberList.size();i++)
            CMemberListNext.add(CMemberList.get(i));
            shownext = false;
            showprev = false;
            PageUntil = CMemberList.size();
            }
            if(CMemberList.size() >0){
                PageNext = 1;
                showPageMessage = false;
            }else{
                PageNext = 0;
                if(isCallFromSearchOrConstr)
                {
                 pageMessageTitle = label.No_Campaign_Members_found;
                 ApexPages.addmessage(new ApexPages.message(ApexPages.severity.info,pageMessageTitle)); 
                }
             
                }
            copydownlimit = 0;
        }else{
            pageMessageTitle = label.Too_many_campaign_members;
            pageMessageDetail ='There are more than 5000 campaign members!'+
                                ' Please use the filter panel to reduce the results for the table below!';
            
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.info, pageMessageTitle+' '+pageMessageDetail);
            
        }
    }
    
 
    public String getCampaign() {
        return SelectedCampaign;
    }
    public void setCampaign(String SelectedCampaign) {
        this.SelectedCampaign = SelectedCampaign;  
    }
     
     //Paging methods Next() and Prev() 
     public void Next(){
        try{
            copydownlimit += count;
            showprev = true;
            CMemberListNext.clear();
            Integer limit1 = 0;
    
            if(next+count < CMemberList.size())
                limit1 = next+count;
            else
            {
                limit1 = CMemberList.size();
                shownext = false;
            }
            PageNext = next;
            PageUntil = limit1;
            for(Integer i=next; i<limit1; i++)
            CMemberListNext.add(CMemberList[i]);
    
            Next+=count;
            allCheckboxes = false;
        }catch(Exception e){system.debug('Exception :'+e);}
        showFollowUpButtonMessage = false;
    }
    
    //Pagination for previous button
    public void Prev(){
        try{
            shownext = true;
            copydownlimit -=count;
            CMemberListNext.clear();
            Integer limit1 = 0;        
            if(next-(count+count) > 0)
                limit1 = next-count;
            else{
                limit1 = next-count; 
                showprev = false;
            }
            PageNext = next-(count+count);
            if (PageNext == 0){PageNext = 1;}
            PageUntil = limit1;
            for(Integer i=next-(count+count); i<limit1; i++)    
                CMemberListNext.add(CMemberList.get(i));
                Next-=count; 
                allCheckboxes = false;
        }catch(Exception e){system.debug('Exception :'+e);}
        showFollowUpButtonMessage = false;            
    }
    
    private void copyList(){
        for(Integer i=0;i<CMemberListNext.size();i++){
            CMemberList.set(copydownlimit+i, CMemberListNext.get(i));
            if(CMemberListNext.get(i).checkedMember == true){
                SelectedCM.put(CMemberListNext.get(i).Id,CMemberListNext.get(i).checkedMember);
            }
            if(CMemberListNext.get(i).checkedMember == false){
                SelectedCM.remove(CMemberListNext.get(i).Id);
            }
        }       
    }
    
    public Integer getCMemberList_size(){
        return  CMemberList.size();
    }
    public Integer PageNext {get; set;}
    public Integer PageUntil {get; set;}  


    public String selectedFilterType{get; set;}
    
    // Filter Title, No.Employees and zip code fields
     public String Title {get; set;}
      
     //part strings for query
     private String filterTitle;
   
    
    public void gofilter(){
    	 idschecked = new set<Id>();
     	if(cmemberlistnext.size()>0)
           {
             for(MyCampaignMember objCampaignMember : cmemberlistnext)
             {
               if(objCampaignMember.checkedMember)
               {
               	idschecked.add(objCampaignMember.Id);
               }
             }
           }
           system.debug(idschecked+'---2------idschecked---'+idschecked.size());
    	this.filterTitle = '';
        //build Title filter string
		filters = new string[]{};
        if(Title != null){
 
              
	           if(Title.contains(','))
	           {
		           for(string str :Title.split(','))
		           {
		              filters.add('%'+str.trim() +'%');
		           }
	           }
	           else
	           {
	              filters.add('%'+Title.trim() +'%');
	           }
	          
	           IF(objCampaignMember.Covering_Professional__c!=NULL)
	           filterTitle = filterTitle+ ' AND Covering_Professional__c = \'' +objCampaignMember.Covering_Professional__c+'\' ';
	           if(memberStatus!='' && memberStatus!=null)	           
	           filterTitle = filterTitle + ' AND (Contact.Name LIKE : filters or Contact.Account.Name like: filters ) and Status =\''+memberStatus +'\' ';
	           else
	             filterTitle =filterTitle+ ' AND ((Contact.Name LIKE : filters) or (Contact.Account.Name like: filters) )';
	           system.debug(filterTitle+'-----filterTitle---'+filters +'---'+objCampaignMember.Covering_Professional__c);
            
        }else{
            filterTitle =' ';
        }
        loadCampaignMemberList(true);
       }
    // dynamic queries
    public List<CampaignMember> queryCM(){
        //default List
        List<CampaignMember> CMList = new List<CampaignMember>();
        String query;
        if(idsCampaignmember.size()>0)
        {
          String idString = '(\'';
			for (Id thisId : idsCampaignmember) {
				//if(idschecked.Contains(thisId))
				 //idschecked.remove(thisId);
			    idString += thisId + '\',\'';
			}
			 if(idschecked.size()>0)
	           filterTitle = ' Or ';
			idString = idString.substring(0,idString.length()-2); 
			idString += ')';
            query = 'Select Id,Contact.Account.Name,Contact.Account.Id, ContactId,Bid_Probability__c,Date_CA_Signed__c,Date_CIM_Sent__c,Covering_Professional__c,  Contact.Name,   Contact.FirstName, Contact.LastName, Contact.OwnerId, Contact.Owner.IsActive,  Status from CampaignMember WHERE (Id In : idschecked ) Or( CampaignId = \''+SelectedCampaign+'\''+filterTitle+ ' and Id Not In '+idString + ' ) ORDER BY Contact.Name limit 5000';
    }
    else
    {
                query = 'Select Id,Contact.Account.Name,Contact.Account.Id, ContactId,Bid_Probability__c,Date_CA_Signed__c,Date_CIM_Sent__c, Covering_Professional__c, Contact.Name,  Contact.FirstName, Contact.LastName, Contact.OwnerId, Contact.Owner.IsActive,  Status from CampaignMember WHERE (Id In : idschecked ) Or (CampaignId = \''+SelectedCampaign+'\''+filterTitle+ ' ) ORDER BY Contact.Name limit 5000';
    
    }
    system.debug(idschecked +'----idschecked---1--'+idschecked.size());
        CMList = Database.query(query);
        return CMList;
    }
    public Integer countCMresults(){
        Integer queryCount = 0;
        String query;
        
            query = 'Select count() from CampaignMember WHERE CampaignId = \''+stringcid+'\''+filterTitle+ ' limit 5000';
        
        queryCount = Database.countQuery(query);
        return queryCount;
    }
}