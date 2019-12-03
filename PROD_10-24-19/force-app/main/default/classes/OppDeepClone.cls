public with sharing class OppDeepClone {

    /* private properties */
    private Opportunity opp;

    /* contructor */
    public OppDeepClone(ApexPages.StandardController stdController) {
        this.opp = (Opportunity)stdController.getRecord();
        // get opportunity ID from URL - no need we get it from standard controller 
        //oppId = ApexPages.currentPage().getParameters().get('varOppID');
    }

    /* private methods */
    
    /* public methods */

    public String getactID() {
        String strTemp = '';

        if(myFlow != null) {
            strTemp = string.valueOf(myFlow.getVariableValue('varChildOppId'));
        }

        return strTemp;        
    }
    
    /* public properties */
    public Flow.Interview.OppDeepClone myFlow {get; set;}
    
    public PageReference FinishPage{
        get {
            PageReference p = new PageReference('/' + getactID() );
            p.setRedirect(true);
            return p;
        }
        //set {FinishPage = value;}
    }
    
    public ID OppId { get {return opp.Id;} }
}