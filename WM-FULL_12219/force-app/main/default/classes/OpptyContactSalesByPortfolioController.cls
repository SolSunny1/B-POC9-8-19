public class OpptyContactSalesByPortfolioController {
    public list<SalesConnect__Contact_Portfolio_Breakdown__c> lstContactSalesPortfolio{get;set;}
    private ApexPages.StandardController controller;
    public OpptyContactSalesByPortfolioController(ApexPages.StandardController controller){
        lstContactSalesPortfolio=new list<SalesConnect__Contact_Portfolio_Breakdown__c>();
        if(controller != null){
            this.controller=controller;
            list<Opportunity> lstOppty=[select id,Contact__c from Opportunity where Id=:controller.getId()];
            if(lstOppty != null && !lstOppty.isEmpty() && lstOppty[0].Contact__c != null){
                String query = 'SELECT ';
                for(Schema.FieldSetMember f : SObjectType.SalesConnect__Contact_Portfolio_Breakdown__c.FieldSets.Contact_Sales_By_Portfolio_Table_mapping.getFields()) {
                    query += f.getFieldPath() + ', ';
                }
                query += 'Id FROM SalesConnect__Contact_Portfolio_Breakdown__c WHERE SalesConnect__Contact__c = \''+lstOppty[0].Contact__c+'\'';
                lstContactSalesPortfolio=Database.query(query);
            }
        }
    }
    public pagereference submit(){
        try{
            string contactSalesId=apexpages.currentpage().getparameters().get('selected');
            if(contactSalesId != null && contactSalesId != ''){
                opportunity objOpportunity=(Opportunity)controller.getRecord();
                objOpportunity.Contact_Sales_by_Portfolio__c=contactSalesId;
                update objOpportunity;
            }
            else{
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.Warning,'Please select Contact Sales By Portfolio to update.');
                ApexPages.addMessage(myMsg);
                return null;                
            }
        }
        catch(exception ex ){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,ex.getMessage());
            ApexPages.addMessage(myMsg);
            return null;
        }
        return controller.view();
    }
    public pagereference cancel(){
        return controller.view();
    }
}