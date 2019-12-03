public without sharing  Class SicCodeTree
{
       public string id{get;set;}
       public map<string,boolean> mapToBoolean {get;set;}   
       public map<string,list<wrapperSic>> maplastChildSicCode {get;set;}
       //Tree will be created from custom setting object SIC_Tree values on page load
       public SicCodeTree()
       {
             set<string> siccodes = new set<string>();
             mapToBoolean = new map<string,boolean> ();
             id = ApexPages.currentPage().getParameters().get('id');
             //All Sic code save on SIC Code field of account 
             list<account> lst = [select id, SICCode__c from account where id = :id];
             if(lst.size()>0 && lst[0].SICCode__c !=null)
             {
                 siccodes.addall(lst[0].SICCode__c.split('\n'));
             }     
            //All data will be used to load tree 
            maplastChildSicCode = new map<string,list<wrapperSic>>();
            for(SIC_Tree__c obj : [select Sic_Code_Selected__c,name,Level_1__c,Level_2__c from SIC_Tree__c ])
            {
              wrapperSic objWrapper = new wrapperSic();
              objWrapper.objSic = obj;
              list<wrapperSic> lstSIC = new list<wrapperSic>();
              if(maplastChildSicCode.containskey(obj.Level_1__c))
              {
                lstSIC = maplastChildSicCode.get(obj.Level_1__c);
              }
             //Checkbox field of custom setting is used to show check box on VF page
             if(siccodes.contains(obj.Level_2__c))
             {
               objWrapper.objCheck = true; 
                    
             }
             lstSIC.add(objWrapper);
             maplastChildSicCode.put(obj.Level_1__c,lstSIC);
            }        
      }
      
      //Cancel method
      public pagereference cancel()
      {
        pagereference  pge = new pagereference('/'+id);
        return pge;
      }
      //Method to update IC code on Account
      public pagereference UpdateSicCode()
      {   
      	try
      	{  	
        string sicCodeString = '';
       for(list<wrapperSic> lst: maplastChildSicCode.values())
        {    
              for(wrapperSic objWrapperSic : lst)
              {
                if(objWrapperSic.objCheck && !sicCodeString.contains(objWrapperSic.objSic.Level_2__c))
                {
                  sicCodeString = sicCodeString  + objWrapperSic.objSic.Level_2__c+'\n';
                }
              }    
         }
         //Update account with selected or deselected Sic code value
         Account objAcc = new account(Id=id);
         objAcc.SICCode__c = sicCodeString;
         update objAcc;
         pagereference  pge = new pagereference('/'+id);
         return pge;
      	} 
         catch(exception ex)
	     {
	       ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.Error, ex.getMessage()); 
	       return null;
	     }
      }
      //Wrapper class Sic Tree is custom setting values and objcheck will track checkbox value
      public class wrapperSic
      {
       public SIC_Tree__c objSic {get;set;}
       public boolean  objCheck{get;set;}
       public wrapperSic()
       {
         objSic = new SIC_Tree__c();
         objCheck = false;
       
       }
      
      }
  }