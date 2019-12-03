public with sharing class ManageKeywordExtension {
  
  public Keyword__c keywordObj {get;set;}
  public Contact_Keyword__c contactKeyword  {get;set;}
  //public string Value {get;set;}
  //public string Comments {get;set;}
  public string SelectedRec {get;set;}
  public string ContactName {get;set;}
  //public List<Contact_Keyword__c> contactKeywords {get;set;}
  public string ContactID {get;set;}
  public boolean isEditMode  {get;set;}
  
    
  public ManageKeywordExtension ()
  {
    
  }
  public PageReference Init ()
  {
    //Get the Contact ID
    ContactID = ApexPages.currentPage().getParameters().get('Id');
    if (ContactID == null)
      return new PageReference('/');
    
    isEditMode = false ;  
    ContactName = [select id, name from contact where id = :ContactID].Name;
    if (isEditMode == false)
    {
      keywordObj = new Keyword__c();
      //keywordObj.Type__c = 'Text';
      contactKeyword = new Contact_Keyword__c() ;
    }
    return null;
    
  }
  public Pagereference Cancel ()
  {
    return new PageReference('/' + ContactID);
  }
  public void OverrideSave ()
  {
    if (keywordObj.type__c == null)
    {
      ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.Error, 'The type needs to be selected' );
          ApexPages.addMessage(myMsg);
          return;
    }
      
    List<Keyword__c> kw = [select name, type__c from Keyword__c where name = :keywordObj.Name and type__c = :keywordObj.Type__c ];
    if (kw.isEmpty())
    {
      if (isEditMode)
        keywordObj.id = null;
      insert keywordObj;
    }
    else
      keywordObj = kw[0];
    
    if (!isEditMode)
    {
      Contact_Keyword__c ck = contactKeyword;
      //ck.Comments__c = this.Comments;
      ck.Contact__c = ContactID;
      ck.Keyword__c = keywordObj.id ;
      ck.RecordTypeId = [select id , name from RecordType where sObjectType = 'Contact_Keyword__c' and Name = :keywordObj.Type__c].id;
      /*
      if (kw[0].Type__c == 'Currency')
        ck.Value_Currency__c  = this.Value;
      if (kw[0].Type__c == 'Date')
        ck.Value_Date__c  = this.Value;
      if (kw[0].Type__c == 'Number')
        ck.Value_Number__c = this.Value ;
      if (kw[0].Type__c == 'Text')
        ck.Value_Text__c = this.value;
      */
      insert ck;
    }
    else
      update contactKeyword;
      
    
    keywordObj = new Keyword__c();
    keywordObj.Type__c = null;
    contactKeyword = new Contact_Keyword__c() ;
    isEditMode = false;
    
  }
  public void ClearValues ()
  {
    
    contactKeyword.Value_Currency__c = null;
    contactKeyword.Value_Date__c = null;
    contactKeyword.Value_Text__c = null;
    contactKeyword.Value_Number__c = null;
  }
  
  public void ClearData ()
  {
    keywordObj = new Keyword__c();
    //keywordObj.Type__c = 'Text';
    contactKeyword = new Contact_Keyword__c() ;
    isEditMode = false;
  }
  public void EditContactKeyWord ()
  {
    List<Contact_Keyword__c>  ck = [select id, Comments__c, Contact__c, Keyword__r.Name , Value_Text__c , Value_Date__c , Value_Number__c , Value_Currency__c  from Contact_Keyword__c where id = :this.SelectedRec ] ;
    if (ck.size() > 0 )
    {
      isEditMode = true;
      //keywordObj = new Keyword__c();
      keywordObj = [select id,name, Type__c from Keyword__c where id = :ck[0].keyword__c] ;
      contactKeyword = ck[0];
      System.Debug(contactKeyword);
    }
  }
  public void DeleteContactKeyWord ()
  {
    System.debug(this.SelectedRec );
    List<Contact_Keyword__c> ck = [select id from Contact_Keyword__c where id = :this.SelectedRec ];
    if (ck.size() > 0 )
      delete ck;
  }
  public List<Contact_Keyword__c > getContactKeywords ()
  {
    List<Contact_Keyword__c > results=  [select id, Keyword__r.Name, Value__c ,Comments__c , Contact__c, CreatedBy.Name, CreatedDate  from Contact_Keyword__c where Contact__c  = :ContactID Order By CreatedDate desc  ];
    return results;
  }
  //Need to be the related list object 
  
}