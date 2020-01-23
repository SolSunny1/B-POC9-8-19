public with sharing class SendNote {
   private Task objTask {get;set;}
   public boolean sendAttachment{get;set;}
   public boolean IsAddSubordinate{get;set;}
   public boolean selctDeselect{get;set;}
   public string roleId{get;set;}
   public string searchTypeContainsOrInclude {get;set;}
   public integer totalCount{get;set;}
   private string ids{get;set;}
   public string usersName{get;set;}
   public string strSubject {get;set;}
   public string emailBody {get;set;}
   public boolean allCheckboxes {get;set;}
    public List<UsersRowItem> listUsers;
   public SendNote(ApexPages.StandardController controller) {
   //init variable
        this.totalCount = 0;
        this.usersName ='';
        this.strUseFullName ='';
        this.IsAddSubordinate = false;
        mapIdUser = new  map<Id,string>();
        this.selectedUserIds= new Set<Id>();
        this.sendattachment = true;
        //By default no records will be selected on grid
        this.selctDeselect = false;
        ids = ApexPages.currentPage().getParameters().get('Id');
        this.searchTypeContainsOrInclude = 'Contains';
        //Get task info to show on editable mode
        objTask = [select id,   whoid,Who.name, whatId,what.name,owner.name,Type, Subject,Status,ActivityDate,Description from Task where id =:  ids];
        this.emailBody = objTask.Description;
        this.strSubject = objTask.Subject;
        this.listUsers = new List<UsersRowItem>();
        this.allCheckboxes = false;
       //Method to get the list of users
        searchUser();
    }
 
   public string strUseFullName {get;set;}
    /*
    *   item in context from the page
    */
    public String contextItem{get;set;}
     map<Id,string> mapIdUser = new  map<Id,string>();
 
 
    /*
    *   set controller
    */
    private ApexPages.StandardSetController setCon;
    
    
    /*
    *   the User ids selected by the user
    */
    public Set<Id> selectedUserIds;
    private Set<Id> selectedContactsIds;
    
      public void doDeselectAllItem(){       
        usersName = '';
         this.selectedUserIds.clear();
    }
 
    //This method is used to get user data based on bydefault and on condition
    public void searchUser()
    {
       // 
      if(strUseFullName == '' &&  roleId ==null)
      {
         //gather data set
        this.setCon= new ApexPages.StandardSetController( [SELECT Id, Name,Email FROM User order by Name] );
        
      }
      else
      { 
      	string whereCondition = '';
      	//if no role is selected on page
      	 if(roleId!=null)
      	 {
      	   //If Add Subordinate is checked on page then show all role 
      	    if(IsAddSubordinate)
      	    {
      	    	CommonUtility objC = new CommonUtility();
      	    	Set<Id> setIds = objC.getSubordinateRoles(roleId);
      	    	setIds.add(roleId);
      	    	whereCondition = whereCondition +' and UserRoleId In '+objC.quoteKeySet(setIds);
	      	   
      	   }
      	   else
      	   {
      	     whereCondition = whereCondition +' and UserRoleId =\''+roleId+'\'';
      	   }
      	 } 
      	 //if role is not selected and Subordinate checkbox is checked
      	 if(IsAddSubordinate && roleId==null)
      	 {
      	   ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Warning,label.Please_Select_a_Role));
      	        	  
      	 }
      	  system.debug(whereCondition+'-----');
      	  string objName = '';
      
         	system.debug(strUseFullName.split(',')+'-----------'+strUseFullName);
           //if user has enter multiple names seperated by comma the create a set to be used in query
           String[] filters = new String[]{};
           if(strUseFullName.contains(','))
           {
	           for(string str :strUseFullName.split(','))
	           {
	             filters.add('%'+str.trim() +'%');
	           }
           }
           else
           {
              filters.add('%'+strUseFullName.trim() +'%');
           }
            this.setCon= new ApexPages.StandardSetController( database.query('SELECT Id, Name, Email FROM User where (Name like: filters '+whereCondition+' ) or Id In: selectedUserIds order by name')  );
           System.debug(filters+'-----objName----');
                 
      }
      //Get total no of records
       totalCount = this.setCon.getResultSize();
       this.setCon.setpageNumber(1);
       //by defalut page size is 10 if custom setting size not given
        this.setCon.setPageSize(10);
        //Get page size from custom setting
       if(System_Setting__c.getall().values()!=null && System_Setting__c.getall().values()[0].Mass_Email_User_List_Size__c!=null)
       {
         integer count  = integer.valueof(System_Setting__c.getall().values()[0].Mass_Email_User_List_Size__c);
         this.setCon.setPageSize(count);
       }
    }
    
    //Role Picklist
     public List<SelectOption> getRoles() 
     {
        return CommonUtility.Roles();
     }
    /*
    *   handle item selected
    */
    public void doSelectItem(){
    
	    if(this.contextItem!=null && this.allCheckboxes)
	    {
	      for(sObject r : this.setCon.getRecords()){
	            User c = (user)r;
	            this.selectedUserIds.add(c.Id);
	       
	      }
	    }else
	    {
	    	if(usersName.trim() =='')
	            usersName = mapIdUser.get(this.contextItem);
	    	else 
	    	{
	    	  usersName = usersName +', '+ mapIdUser.get(this.contextItem);
	    	}
	    	  
	        this.selectedUserIds.add(this.contextItem);
	    }  
    }
    
    
    /*
    *   handle item deselected
    */
    public void doDeselectItem(){
         system.debug(selectedUserIds+'---1---selectedUserIds--'+selectedUserIds.size());
      
          if(usersName.contains(mapIdUser.get(this.contextItem)+','))
            usersName = usersName.remove(mapIdUser.get(this.contextItem)+',');
           else  if(usersName.contains(', '+mapIdUser.get(this.contextItem)))
            usersName = usersName.remove(', '+mapIdUser.get(this.contextItem));
         else
           usersName = usersName.remove(mapIdUser.get(this.contextItem));
        this.selectedUserIds.remove(this.contextItem);
        this.allCheckboxes = false;
        system.debug(selectedUserIds+'--2----selectedUserIds--'+selectedUserIds.size());
    }
    
    
    /*
    *   return count of selected items
    */
    public Integer getSelectedCount(){
        
        return this.selectedUserIds.size();
        
    }
    

    /*
    *   advance to next page
    */
    public void doNext(){
        
        if(this.setCon.getHasNext())
            this.setCon.next();
 
    }
    
    
    /*
    *   advance to previous page
    */
    public void doPrevious(){
        
        if(this.setCon.getHasPrevious())
            this.setCon.previous();
                
    }
   
    
    /*
    *   return current page of groups
    */
    public List<UsersRowItem> getlistUsers(){
        
        List<UsersRowItem> rows = new List<UsersRowItem>();
        mapIdUser = new  map<Id,string>();
        system.debug(allCheckboxes+'----main allCheckboxes----');
        
        for(sObject r : this.setCon.getRecords()){
            User c = (user)r;
            mapIdUser.put(c.Id,c.name);
            UsersRowItem row = new UsersRowItem(c,false);
            system.debug(allCheckboxes+'----allCheckboxes----'+c.name);
            if(allCheckboxes)
            {
              row.IsSelected= true;
              selectedUserIds.add(c.id);
              
              if(!usersName.contains(c.Name))
              {
	               if(usersName.trim() =='')
		              usersName = mapIdUser.get(c.id);
			    	else 
			    	{
			    	  usersName = usersName +', '+ mapIdUser.get(c.Id);
			    	}
              }
            }else
            {
            system.debug(selectedUserIds+'---3---selectedUserIds--'+selectedUserIds.size());
            	
	            if(this.selectedUserIds.contains(c.Id)){
	                row.IsSelected=true;
	            }
	            else{
	                row.IsSelected=false;
	            }
            }
            
            rows.add(row);            
        }
        return rows;
        
    }
    
    
    /*
    *   return whether previous page exists
    */
    public Boolean getHasPrevious(){
        
        return this.setCon.getHasPrevious();
        
    }
    
    
    /*
    *   return whether next page exists
    */
    public Boolean getHasNext(){
        
        return this.setCon.getHasNext();
    
    }
    
    
    /*
    *   return page number
    */
    public Integer getPageNumber(){
        
        return this.setCon.getPageNumber();
        
    }
    
    /*
    
    Send Email
    
    */
    public pagereference doSendEmail() {
      try
      {
           //SinglemailMessage list used to send mail to multiple users
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        list<Messaging.EmailFileAttachment> lstAttachment = new list<Messaging.EmailFileAttachment>();
        
        
        if(selectedUserIds.size()>0)
        {
         
        //If ttachment checkbox is checked attachment will be added to email
           if(sendAttachment)
            {
                //Get all the attachment from attachment object which is realted to task
                for(Attachment objAttachment: [Select a.ParentId, a.ContentType,a.Id,a.Name, a.Body From Attachment a where a.ParentId =:objTask.id])
                {
                
                  Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                  Blob b = objAttachment.Body;
                   efa.setFileName(objAttachment.Name);
                   efa.setBody(b);  
                   lstAttachment.add(efa);
                }
              }
              	Datetime yourDate = objTask.ActivityDate;
              	String dateOutput = '';
              	if(yourDate!=null)
				 dateOutput = yourDate.format('dd/MM/yyyy');
				//Task Details
                string  BodyText = '<h2>Salesforce Task Notes</h2><br/> <b> Assigned To: </b>'+ objTask.owner.Name+'<br/> <b> Due Date: </b>'+ dateOutput +'<br/> <b> Status: </b>'+ objTask.Status ;
                if(objTask.Type != null)
                 BodyText = BodyText +'<br/><b> Type: </b>'+ objTask.Type ;
                if(objTask.whatid!=null)
                 BodyText = BodyText +'<br/><br/> <b>Related To: </b>'+ objTask.what.Name ;
                 if(objTask.whoId!=null)
                 BodyText = BodyText +'<br/><b>Contact Name: </b>'+objTask.who.Name;
                
                 BodyText = BodyText +'<br/><br/> <b>Subject:</b> '+ strSubject +'<br/>  <b>Comments: </b>' +emailBody;
         
               //Email instance is created for each user
                for(Id usr :selectedUserIds)
                {  
                   Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();                   
                   mail.setTargetObjectId(usr);
                  // mail.setwhatid(objTask.id);
                   mail.setSubject(label.Salesforce_Task_Details);
                   mail.setHtmlBody(BodyText + '<br /><br/> <b>Link to original Task Details in Salesforce: </b>' + '<a href=https://' +System.URL.getSalesforceBaseUrl().getHost().remove('-api' )+'/'+ objTask.Id + '>Click Here</a>');
                   mail.setPlainTextBody(emailBody);
                   mail.setSaveAsActivity(false);
                 //  mail.setTemplateId(et.id);
                  if(sendAttachment && lstAttachment.size() >0)
                    mail.setFileAttachments(lstAttachment);               
                   mails.add(mail);
                 
                }
                //Send email
                Messaging.sendEmail(mails);
                
                //Success message use of custom label
                pagereference pge = new pagereference('/'+ids);
                return pge;
        }else
        {
        // warning message if no user selected
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Warning,label.Select_User_for_Email));
        return null;
        }
      }catch(exception ex)
      {
        //Exception message
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,ex.getmessage()));
        return null;
      }
   
   
}
    
    /*
    *    return total pages
    */
    Public Integer getTotalPages(){
    
        Decimal totalSize = this.setCon.getResultSize();
        Decimal pageSize = this.setCon.getPageSize();
        
        Decimal pages = totalSize/pageSize;
        
        return (Integer)pages.round(System.RoundingMode.CEILING);
    }
    
    
    
    /*
    *   helper class that represents a row
    */
    public with sharing class UsersRowItem{
        
        public User objUser{get;set;}
       
        public Boolean IsSelected{get;set;}
        
        public UsersRowItem(User c, Boolean s){
            this.objUser=c;
          
            this.IsSelected=s;
        }
        
    } 
}