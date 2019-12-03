trigger NewOpportunityName on Opportunity (before insert, before update) {
    List<Opportunity> toProcess = new List<Opportunity>();
    Set<id> accountIds = new Set<id>();
    Set<id> ivIds = new Set<id>();
   
    System.debug('In NewOpportunityName trigger');
   
    for (Opportunity opp : Trigger.New)
    {
       
        // Joe edited to switch Starts with to Equals to specify PFG only record type vs all PFG record types
        if (Schema.SObjectType.Opportunity.getRecordTypeInfosById().get(opp.recordtypeid).getname().equals('PFG'))
        {
            toProcess.add(opp);
            accountIds.add(opp.AccountId);
            ivIds.add(opp.Investment_Vehicle__c);
        }
    }
   
    if (toProcess.Size() > 0)
    {
        Map<id, Investment_Vehicle__c> ivs = new Map<id, Investment_Vehicle__c>([SELECT Id, Name, Vehicle_Type__c, Fund_Series__c FROM Investment_Vehicle__c WHERE Id in:ivIds]);
        Map<id, Investment_Vehicle__c> accountIvs = new Map<id, Investment_Vehicle__c>([SELECT Id, Name, Vehicle_Type__c, Fund_Series__c FROM Investment_Vehicle__c WHERE Id in (select Investment_Vehicle__c FROM Opportunity where AccountId in:accountIds)]);
        //careful, this map contains all opportunities across investment vehicles for an account
        Map<id, Account> accountOpps = new Map<id, Account>([SELECT Id,Name,(SELECT Id, Name, Investment_Vehicle__c, IsWon FROM Opportunities where recordtype.name = 'PFG') FROM Account WHERE Id in:accountIds]);
        System.Debug('ivs count ' + ivs.size());
        
        for (Opportunity opp : toProcess)
        {
            Account a = accountOpps.get(opp.AccountId);
            Investment_Vehicle__c iv = ivs.get(opp.Investment_Vehicle__c);
            //Unique check
            opp.Unique_Opportunity_Name__c = iv.Name + ' - ' + a.Name;
           
            if (opp.Duplicate__c)
               opp.Unique_Opportunity_Name__c += String.valueof(DateTime.now().getTime());
           
            boolean isReUp = false;
            boolean hasCrossover = false;
            List<Opportunity> opps = new List<Opportunity>();
            for (Opportunity curOpp : a.Opportunities)
            {
                System.debug('CurOpp IV ' + curOpp.Investment_Vehicle__c);
                Investment_Vehicle__c curIv = accountIvs.get(curOpp.Investment_Vehicle__c);
                System.debug('contains key ' + accountIvs.containskey(curOpp.Investment_Vehicle__c) + ' ' + curIv);
                system.debug('for account ' + a.name + ' IV ' + iv.Name + ' curOp ' + curOpp.Name + ' IsWon ' + curOpp.IsWon );
                system.debug('iv fund series ' + iv.Fund_Series__c);
                system.debug('curIv fund series ' + curIv.Name);
                system.debug('curIv fund series ' + curIv.Fund_Series__c);
                if (curOpp.Investment_Vehicle__c == opp.Investment_Vehicle__c)
                {
                    system.debug('kept ' + curOpp.Name);
                    opps.add(curOpp);
                    if (curOpp.IsWon)
                    {
                        isReUp = true;
                    }
                }
                else if (iv.Fund_Series__c == curIv.Fund_Series__c && curOpp.IsWon)
                {
                    isReUp = true;
                }
                else if (curOpp.IsWon)
                {
                    hasCrossover = true;
                }
            }
           
            boolean isUpdateForSameAccountInvVeh = false;
            if (Trigger.IsUpdate)
            {
                Opportunity oldOpp = Trigger.oldMap.get(opp.Id);
                isUpdateForSameAccountInvVeh = opp.AccountId == oldOpp.AccountId && opp.Investment_Vehicle__c == oldOpp.Investment_Vehicle__c;
            }
           
            if (isUpdateForSameAccountInvVeh)
            {
                Integer ndx = -1;
                Integer spaceNdx = opp.Name.lastIndexOf(' ');
                if (spaceNdx != -1 && spaceNdx != opp.Name.length()-1)
                {
                    String potentialNumber = opp.Name.substring(spaceNdx+1);
                    System.debug('Update Opp ' + opp.Name + ' has number ' + potentialNumber);
                    if (potentialNumber.isNumeric())
                    {
                        ndx = Integer.valueOf(potentialNumber);
                    }
                }
                
                if (ndx != -1)
                {
                    string suffix = ' - ' + ndx;
                    opp.Name = (iv.Name +  ' - ' + a.Name).Left(80-suffix.Length()) + suffix;
                }
                else
                {
                    opp.Name = (iv.Name +  ' - ' + a.Name).Left(80);
                }
            }
            else if (opps.size() == 0)
            {
                opp.Name = (iv.Name +  ' - ' + a.Name).Left(80);
            }
            else
            {
                Integer ndx = 2;
                for (Integer i = 0; i < opps.size(); i++)
                {
                    Opportunity curOpp = opps[i];
                    Integer spaceNdx = curOpp.Name.lastIndexOf(' ');
                    if (spaceNdx != -1 && spaceNdx != curOpp.Name.length()-1)
                    {
                        String potentialNumber = curOpp.Name.substring(spaceNdx+1);
                        System.debug('Opp ' + curOpp.Name + ' has number ' + potentialNumber);
                        if (potentialNumber.isNumeric())
                        {
                            Integer val = Integer.valueOf(potentialNumber);
                            System.debug('val ' + val + ' ndx ' + ndx);
                            if (ndx <= val+1)
                            {
                                ndx = val+1;
                                System.debug('Ndx is now' + ndx);
                            }
                        }
                    }
                }
                string suffix = ' - ' + ndx;
                opp.Name = (iv.Name +  ' - ' + a.Name).Left(80-suffix.Length()) + suffix;
            }
           
            System.debug('new Opp name ' + opp.Name);
			if (!Trigger.IsUpdate)
            {
				if (iv.Vehicle_Type__c == 'Co-Invest')
				{
					opp.Classification__c = 'Co-Invest';
				}
				else if (iv.Vehicle_Type__c ==  'General Overview')
				{
					opp.Classification__c = 'General Overview';
				}
				else if (iv.Vehicle_Type__c ==  'Joint Venture')
				{
					opp.Classification__c = 'Joint Venture';
				}
				else if (iv.Vehicle_Type__c == 'Sale of Asset')
				{
					opp.Classification__c = 'Sale of Asset';
				}
				else if (iv.Vehicle_Type__c ==  'Separate Accounts' || iv.Vehicle_Type__c == 'Separately Managed Account')
				{
					opp.Classification__c = 'Separate Accounts';
				}
				else if (isReUp)
				{
					opp.Classification__c = 'Re-Up Series';
				}
				else if (hasCrossover)
				{
					opp.Classification__c = 'Crossover';
				}
				else if (opps.size() == 0)
				{
					opp.Classification__c = 'First';   
				}
			}
        }
    }
}