public  with sharing class manageServiceLevelDefaultsExtension 
{
    //public Service_Level_Defaults__c defaults {get;set;}
    private boolean isUserConfing = false;
    private string retUrl = '';
    public decimal Tier_A_Relationship_Calls_Year {get;set;}
    public decimal Tier_B_Relationship_Calls_Year {get;set;}
    public decimal Tier_C_Relationship_Calls_Year {get;set;}
    public decimal Tier_D_Relationship_Calls_Year {get;set;}
    public decimal Tier_E_Relationship_Calls_Year {get;set;}
    
    public decimal Tier_A_In_Person_Meetings_Year {get;set;}
    public decimal Tier_B_In_Person_Meetings_Year {get;set;}
    public decimal Tier_C_In_Person_Meetings_Year {get;set;}
    public decimal Tier_D_In_Person_Meetings_Year {get;set;}
    public decimal Tier_E_In_Person_Meetings_Year {get;set;}
    
    public decimal Tier_A_Portfolio_Review_Year {get;set;}
    public decimal Tier_B_Portfolio_Review_Year {get;set;}
    public decimal Tier_C_Portfolio_Review_Year {get;set;}
    public decimal Tier_D_Portfolio_Review_Year {get;set;}
    public decimal Tier_E_Portfolio_Review_Year {get;set;}
    
    public decimal Num_Days_Ahead_On_Target {get;set;}
    public decimal Num_Days_Ahead_Overdue {get;set;}
    
    private string recordId ;
    
    //public manageServiceLevelDefaultsExtension(ApexPages.StandardController stdController)
    public manageServiceLevelDefaultsExtension()
    {
        retUrl =  ApexPages.currentPage().getParameters().get('retUrl');
        Service_Level_Defaults__c userDefaults = Service_Level_Defaults__c.getInstance (Userinfo.getUserId());
        Service_Level_Defaults__c Defaults  ;   
        if (userDefaults.id == null)
        {
            defaults = Service_Level_Defaults__c.getInstance();
            isUserConfing = false;
        }
        else
        {
            defaults = userDefaults;
            isUserConfing = true;
        }
        recordId = defaults.id;
        
        Tier_A_Relationship_Calls_Year = defaults.Tier_A_Relationship_Calls_Year__c;
        Tier_B_Relationship_Calls_Year = defaults.Tier_B_Relationship_Calls_Year__c;
        Tier_C_Relationship_Calls_Year = defaults.Tier_C_Relationship_Calls_Year__c;
        Tier_D_Relationship_Calls_Year = defaults.Tier_D_Relationship_Calls_Year__c;
        Tier_E_Relationship_Calls_Year = defaults.Tier_E_Relationship_Calls_Year__c;
        
        Tier_A_In_Person_Meetings_Year = defaults.Tier_A_In_Person_Meetings_Year__c;
        Tier_B_In_Person_Meetings_Year = defaults.Tier_B_In_Person_Meetings_Year__c;
        Tier_C_In_Person_Meetings_Year = defaults.Tier_C_In_Person_Meetings_Year__c;
        Tier_D_In_Person_Meetings_Year = defaults.Tier_D_In_Person_Meetings_Year__c;
        Tier_E_In_Person_Meetings_Year = defaults.Tier_E_In_Person_Meetings_Year__c;
        
            
        Num_Days_Ahead_On_Target = defaults.Num_Days_Ahead_On_Target__c;
        Num_Days_Ahead_Overdue = defaults.Num_Days_Ahead_Overdue__c;
        
        
    }
    public PageReference OverrideSave()
    {
        //upsert defaults;
        //Add the Data to to the queue objects and send email to trigger.
        Service_Level_Defaults__c Defaults =  new   Service_Level_Defaults__c ();
        defaults.id = recordId;
        
        defaults.Tier_A_Relationship_Calls_Year__c = Tier_A_Relationship_Calls_Year ;
        defaults.Tier_B_Relationship_Calls_Year__c = Tier_B_Relationship_Calls_Year ;
        defaults.Tier_C_Relationship_Calls_Year__c = Tier_C_Relationship_Calls_Year ;
        defaults.Tier_D_Relationship_Calls_Year__c = Tier_D_Relationship_Calls_Year ;
        defaults.Tier_E_Relationship_Calls_Year__c = Tier_E_Relationship_Calls_Year ;
        
        defaults.Tier_A_In_Person_Meetings_Year__c = Tier_A_In_Person_Meetings_Year ;
        defaults.Tier_B_In_Person_Meetings_Year__c = Tier_B_In_Person_Meetings_Year ;
        defaults.Tier_C_In_Person_Meetings_Year__c = Tier_C_In_Person_Meetings_Year ;
        defaults.Tier_D_In_Person_Meetings_Year__c = Tier_D_In_Person_Meetings_Year ;
        defaults.Tier_E_In_Person_Meetings_Year__c = Tier_E_In_Person_Meetings_Year ;
        
              
        defaults.Num_Days_Ahead_On_Target__c = Num_Days_Ahead_On_Target ;
        defaults.Num_Days_Ahead_Overdue__c = Num_Days_Ahead_Overdue;
        
        SecurityDefaultQueue__c q = new SecurityDefaultQueue__c();
    //  if (defaults.SetupOwnerId != UserInfo.getUserId())
        defaults.SetupOwnerId = UserInfo.getUserId() ;
        q.UserData__c = JSON.serialize(defaults)  ;
        insert q ;
        
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        List<string> theToAddess = new List<string>();
        theToAddess.add( ConfigSettings__c.getValues('DefaultSvcConfigEmail').Value__c );
        email.setToAddresses(theToAddess);
        email.setPlainTextBody('');
        Messaging.SendEmailResult [] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});  
        return new PageReference('/' + retUrl);
    }
    public Pagereference Cancel ()
    {
        if (returl != null)
            return new PageReference('/' + retUrl);
        else
            return new PageReference('/');
    }
}