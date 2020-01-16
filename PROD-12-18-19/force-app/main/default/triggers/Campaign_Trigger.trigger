trigger Campaign_Trigger on Campaign (after insert, after update,before insert,before update) {
    
    Campaign_Handler campaignHandler = new Campaign_Handler();
    
     if (Trigger.isInsert) {
        if (Trigger.isAfter) { 
            System.debug('Ininsert ');
                campaignHandler.CreateFundraisingCampaignEvents(Trigger.new);            
        }
        /* else{            
            campaignHandler.checkDuplicateCampaignForFund(Trigger.new);
         }*/
    }   
    
    if (Trigger.isUpdate) {
        if (Trigger.isAfter) {   
            System.debug('InUpdate');            	
                campaignHandler.CreateFundraisingCampaignMemberEvents(Trigger.new);           
        }
       /* else {           
            campaignHandler.checkDuplicateCampaignForFund(Trigger.new);
        }*/
    }
    
}