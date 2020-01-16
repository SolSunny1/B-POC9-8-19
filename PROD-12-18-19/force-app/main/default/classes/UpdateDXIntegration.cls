global class UpdateDXIntegration {    
    
    @future(callout=true)
    public static void futureExecute()
    {
        //TODO only process what has been started over 15 minutes ago
        // where ProcessingCompletedTime__c = null
        Map<id, PermissionUpdate__c> permissions = new Map<id, PermissionUpdate__c>([select ContactActive__c, ContactFirstName__c, ContactLastName__c, ContactEmail__c, ContactExternalId__c, FundName__c, FundAssetClass__c, FundExternalId__c, InvestorName__c, InvestorExternalId__c, Community__c, GroupName__c, GroupAccess__c, GroupNotification__c, GroupStartDate__c, GroupEndDate__c,SendInvitationEmail__c  from PermissionUpdate__c where ProcessingCompletedTime__c = null]);

        List<PermissionUpdate__c> toUpdate = new List<PermissionUpdate__c>();
        
        if (permissions.size() > 0)
        {
        
            for (PermissionUpdate__c perm : permissions.values())
            {
                System.debug('PUP Contact first name ' + perm.ContactFirstName__c);
                perm.ProcessingCompletedTime__c = Datetime.now();
                
                toUpdate.add(perm);
            }
            
            UpdatePermissions(toUpdate);
        }
        
        //TODO only process what has been started over 15 minutes ago
        // where ProcessingCompletedTime__c = null
        Map<id, DxFundUpdate__c> funds = new Map<id, DxFundUpdate__c>([select id, name, FundName__c, FundExternalId__c, FundAssetClass__c,Community__c from DxFundUpdate__c where ProcessingCompletedTime__c = null]);

        List<DxFundUpdate__c> fundsToUpdate = new List<DxFundUpdate__c>();
        
        if (funds.size() > 0)
        {
        
            for (DxFundUpdate__c fund : funds.values())
            {
                System.debug('DX Fund Update fund name ' + fund.FundName__c);
                fund.ProcessingCompletedTime__c = Datetime.now();
                
                fundsToUpdate.add(fund);
                UpdateFunds(fund);
            }            
        }       
        //Changes for investor and Commitent update
        Map<id,DxInvestorUpdate__c> investorUpdateMap= new Map<id,DxInvestorUpdate__c>([Select id,InvestorName__c,InvestorExternalId__c,Fund_Id__c,Fund_Name__c,Commitment__c,Community__c from DxInvestorUpdate__c where ProcessingCompletedTime__c = null]);
        List<DxInvestorUpdate__c> investorLst = new List<DxInvestorUpdate__c>();
       // Map<String,String> investorFundMap = new Map<String,String>();
        if(investorUpdateMap.Size() > 0){
            for(DxInvestorUpdate__c investor : investorUpdateMap.values()){
                System.debug('DX Investor Commitment Update fund name ' + investor.Fund_Name__c);
                investor.ProcessingCompletedTime__c = Datetime.now();
                investorLst.add(investor);               
            }
            UpdateInvestorCommitment(investorUpdateMap);            
        }
        if (toUpdate.size() > 0)
        	update toUpdate;
        
        if (fundsToUpdate.size() > 0)
        	update fundsToUpdate;
        
        if(investorLst.size() >0)
            update investorLst;
    }
    public static void UpdatePermissions(List<PermissionUpdate__c> permissions)
    {
        //Calling to get data from MetaData Setup -SOQL does not count under Governance Limit
        final string INTEGRATIONREQUESTNAME =  'DXSetup';
        IntegrationRequestSetup__mdt dxRequest = [Select Username__c,SecurityToken__c,EndpointServer__c from IntegrationRequestSetup__mdt where MasterLabel =: INTEGRATIONREQUESTNAME];
        try
        {
            Http h = new Http();
            string endPoint =  'https://'+dxRequest.EndpointServer__c+'.azurewebsites.net/FisDx/UpdatePermissions';
            // Instantiate a new HTTP request, specify the method (GET) as well as the endpoint
            HttpRequest req = new HttpRequest();
            //TODO remove this
            req.setTimeout(60000);
            req.setEndpoint(endPoint);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json; charset=UTF-8');
            req.setHeader('SecurityToken', dxRequest.SecurityToken__c);
            req.setHeader('Username', dxRequest.Username__c);
            boolean first = true; 
            string jsonS = '[';
            for (PermissionUpdate__c perm : permissions)
            {
                if (!first)
                    jsonS += ',';
                string assetClass = perm.FundAssetClass__c;
                if (perm.FundAssetClass__c == 'Property')
                    assetClass = 'Real Estate';
                
                jsonS += '{';
                jsonS += '"Investor":{ "Name": "' + perm.InvestorName__c + '", "ExternalId":"'+ perm.InvestorExternalId__c +'"},';
                jsonS += '"Contact": {"Email":"' + perm.ContactEmail__c + '", "FirstName":"' + perm.ContactFirstName__c + '", "LastName":"' + perm.ContactLastName__c + '","IsActive":"' + perm.ContactActive__c + '","SendInvitationEmail":"' + perm.SendInvitationEmail__c+'", "ExternalId":"' + perm.ContactExternalId__c + '"},';
                jsonS += '"Fund": {"Name":"' + perm.FundName__c + '", "Community":"' + perm.Community__c +'", "ExternalId": "' + perm.FundExternalId__c +'", "AssetClass": "' + assetClass + '"},';
                jsonS += '"GroupEntitlement": {"Name":"' + perm.GroupName__c +'", "Access":"'+ perm.GroupAccess__c +'", "Notification":"' + perm.GroupNotification__c + '"';
                if (perm.GroupStartDate__c != null && perm.GroupEndDate__c != null)
                {
                    jsonS += ', "DateRange": {"From": "' + perm.GroupStartDate__c +'", "To":"' + perm.GroupEndDate__c + '"}';
                }
                else
                    System.debug('skipped daterange as start or end was null');
                
                jsonS +='}';
                jsonS += '}';
                first = false;
                
                System.debug(', "DateRange": {"From": "' + perm.GroupStartDate__c +'", "To":"' + perm.GroupEndDate__c + '"}');
            }
            
            jsonS += ']';           
            
            req.setBody(jsonS);
            // Send the request, and return a response
            
            HttpResponse res = h.send(req);
            string ret = res.getBody();
            
            System.debug('return ' + ret);
        }
         catch (exception e) {
                
                system.debug('#### Exception caught: ' + e.getMessage());                
            }
    }
    
    public static void UpdateFunds(DxFundUpdate__c fundUpdate)
    {
        final string COMMUNITYNAME = 'FundraisingCommunityName';
        final string INTEGRATIONREQUESTNAME =  'DXSetup';
        Http h = new Http();
        try
        {
            //Calling to get data from MetaData Setup -SOQL does not count under Governance Limit 
            CommunityName__mdt commNameMapping = [Select Name__c from CommunityName__mdt where MasterLabel =: COMMUNITYNAME];
            IntegrationRequestSetup__mdt dxRequest = [Select Username__c,SecurityToken__c,EndpointServer__c from IntegrationRequestSetup__mdt where MasterLabel =: INTEGRATIONREQUESTNAME];
            string endPoint =  'https://'+dxRequest.EndpointServer__c+'.azurewebsites.net/FisDx/CreateFund';
            system.debug(endPoint);
            // Instantiate a new HTTP request, specify the method (GET) as well as the endpoint
            HttpRequest req = new HttpRequest();
            //TODO remove this
            req.setTimeout(60000);           
            req.setEndpoint(endPoint);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json; charset=UTF-8');
            req.setHeader('SecurityToken', dxRequest.SecurityToken__c);
            req.setHeader('Username', dxRequest.Username__c);            
            boolean first = true; 
            string jsonS = '{';
            //Check for data coming from Fund Creation or Campaign Creation
            if(fundUpdate.Community__c != Null){
                jsonS += '"Community":"'+fundUpdate.Community__c+'",'; }
            else{
                jsonS += '"Community":"'+commNameMapping.Name__c+'",'; }  
            jsonS += '"Name":"'+fundUpdate.FundName__c +'",';
            jsonS += '"ExternalId":"'+fundUpdate.FundExternalId__c +'",';
            jsonS += '"AssetClass":"'+fundUpdate.FundAssetClass__c +'",';
            jsonS += '}';
            System.debug(jsonS);
            
            req.setBody(jsonS);
            // Send the request, and return a response
            
            HttpResponse res = h.send(req);
            string ret = res.getBody();
            
            System.debug('return ' + ret);
        }
        catch (exception e) {
                
                system.debug('#### Exception caught: ' + e.getMessage());                
            }
    }
    
    public static void UpdateInvestorCommitment(Map<Id,DxInvestorUpdate__c> investorUpdateMap)
    {
        final string INTEGRATIONREQUESTNAME =  'DXSetup';
        IntegrationRequestSetup__mdt dxRequest = [Select Username__c,SecurityToken__c,EndpointServer__c from IntegrationRequestSetup__mdt where MasterLabel =: INTEGRATIONREQUESTNAME];
        string COMMUNITY ;      
        Map<string,string> fundName = new Map<String,String>();
        Map<string,string> InvestorName = new Map<String,String>();
        Map<string,string> fundInvestorMap = new Map<String,String>();
		Set<String> investorSet = new Set<String>();		        
      
        for(DxInvestorUpdate__c commitment  : investorUpdateMap.values()) {
            fundInvestorMap.put(commitment.Fund_Id__c,commitment.InvestorExternalId__c);
            fundName.put(commitment.Fund_Id__c,commitment.Fund_Name__c);
            InvestorName.put(commitment.InvestorExternalId__c,commitment.InvestorName__c);
            COMMUNITY = commitment.Community__c;
			investorSet.add(commitment.InvestorExternalId__c);
        }
		system.debug('fundName----' + fundName);
		system.debug('InvestorName----' + InvestorName);
		system.debug('investorSet----' + investorSet);
        Http h = new Http();        
        HttpRequest req = new HttpRequest();
        string endPoint =  'https://'+dxRequest.EndpointServer__c+'.azurewebsites.net/FisDx/UpdateInvestor';
        req.setTimeout(60000);
        req.setEndpoint(endPoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json; charset=UTF-8');
        req.setHeader('SecurityToken', dxRequest.SecurityToken__c);
        req.setHeader('Username', dxRequest.Username__c);         
        string jsonS = '[';
		boolean firstInvestor = true; 
		for(string investor : investorSet) { 
            boolean firstFund = true; 
            if(!firstInvestor)
                jsonS += ',';                    
            jsonS += '{';
            if(COMMUNITY != Null){
                jsonS += '"Community":"'+COMMUNITY+'",'; }
            
            jsonS += '"InvestorName":"'+InvestorName.get(investor) +'",';
            jsonS += '"InvestorExternalId":"'+investor +'",';
            jsonS += '"Funds":[';           
            for(DxInvestorUpdate__c commitment  : investorUpdateMap.values()){
                system.debug('investor-------'+ investor +'   commitment.InvestorExternalId__c --' + commitment.InvestorExternalId__c);
                if(commitment.InvestorExternalId__c == investor )
                {                
                    if (!firstFund)
                        jsonS += ',';
                    jsonS += '{';
                    
                    jsonS += '"ExternalId": "' + commitment.Fund_Id__c + '", "Name":"'+ commitment.Fund_Name__c +'"}';
                    firstFund = false;
                }              
            }
            jsonS += ']';
            jsonS += '';
            jsonS += '}'; 
            firstInvestor = false;
        }								
        jsonS += ']';
        System.debug(jsonS);                
        req.setBody(jsonS);
        
        // Send the request, and return a response
        try {
            HttpResponse res = h.send(req);
            string ret = res.getBody();
            
            System.debug('return ' + ret);
        }
        catch (exception e) {
            
            system.debug('#### Exception caught: ' + e.getMessage());                
        }     
    }
 }