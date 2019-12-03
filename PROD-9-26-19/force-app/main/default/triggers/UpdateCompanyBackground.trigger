/* This trigger checks if the Company Background and QI Status Notes field has been updated in the Account record
     and updates all compliance records with the same Company Background values*/

trigger UpdateCompanyBackground on Account (after update) {
  
  // For loop to check if the Company Background field has been updated/changed from what it was before 
    
  Set<Id> ids = new Set<Id>();
  List<Compliance__c> cf = new List<Compliance__c>();
     
  for (Account a: Trigger.new)
    {   
      system.debug('>>>>>>>>>Trigger on Account is running');
      Account old = Trigger.oldmap.get(a.Id);            
        if (a.Company_Background__c != old.Company_Background__c || a.QI_Status_Notes__c != old.QI_Status_Notes__c)
          {
            ids.add(a.Id);
            system.debug('>>>>>>>>>Company Background OR QI Status Notes on Account has Changed');
          }            

   // If the Company Background field has been updated; run a query to get a list of child compliance records
        
        if (Ids.size() > 0 && Ids.size() <100)
        {
            Account acc = [SELECT id, Company_Background__c, QI_Status_Notes__c, (SELECT id, Company_Background__c, Description__c from KYC_Forms__r) 
                    From Account Where Id = :a.Id Limit 1];        
           
                system.debug('>>>>>>>>>Compliance records found for this Account' + acc.id);
            
   // Create a list of Compliance records that are childs of the Account         
                    cf.addAll(acc.KYC_Forms__r);                   

                        if(cf.size() >0)
                         {
                            System.debug('>>>>>>>>>Number of compliance records found: ' + cf.size());
   // Run a for loop for the compliance record list to update all the Company Background fields from the Account                          
                            for (Compliance__c cform : cf)
                                {
                                    system.debug('>>>>>>>>>Company background of the Query Account record is: ' + acc.Company_Background__c);
                                    cform.Company_Background__c = acc.Company_Background__c;
                                    cform.Description__c = acc.QI_Status_Notes__c;
                                } 
                          }                            
                    }
             }         
                         if(cf.size() >0)
                         {
                         try {
                                // Update the Compliance records         
                                update cf;   
                                } catch (Exception e) {System.debug('The following exception has occurred: ' + e.getMessage()); System.debug('Exception type caught: ' + e.getTypeName()); System.debug('Cause: ' + e.getCause()); System.debug('Line Number: ' + e.getLineNumber()); System.debug('Stack Trace: ' + e.getStackTraceString());}                      
                         }
        }