public with sharing class Opportunity_Handler {
    private Map<String, Id> mapRecordType;
    public void createConsultantRelationship(List<Opportunity> records) {
        populateRecordTypeMap();
        Set<Id> psgRecordTypes = new Set<Id>();
        for (String recordTypeDeveloperName : mapRecordType.keySet()) {
            if (recordTypeDeveloperName.contains('PSG')) {
                psgRecordTypes.add(mapRecordType.get(recordTypeDeveloperName));
            }
        }

        Set<Id> setConsultantIds = new Set<Id>();
        Set<Id> setAccountIds = new Set<Id>();
        Set<Id> setInvestmentVehicleIds = new Set<Id>();
        List<Opportunity> lstReleventRecords = new List<Opportunity>();
        system.debug('psgRecordTypes: ' + psgRecordTypes);
        for (Opportunity o : records) {
            if (psgRecordTypes.contains(o.RecordTypeId) && String.isNotBlank(o.Consultant__c)) {
                setConsultantIds.add(o.Consultant__c);
                setAccountIds.add(o.AccountId);
                setInvestmentVehicleIds.add(o.Investment_Vehicle__c);
                lstReleventRecords.add(o);
            }
        }

        if (setConsultantIds.size() > 0) {
            Map<Id, Investment_Vehicle__c> mapRelatedInvestmentVehicles = new Map<Id, Investment_Vehicle__c>([select Id, Platform__c from Investment_Vehicle__c where Id in :setInvestmentVehicleIds]);

            Set<String> setConsultantKey = new Set<String>();
            for (Consultant__c c : [select Id, Client__c, Consultant__c, Asset_Class__c from Consultant__c where Client__c in :setAccountIds and Consultant__c in :setConsultantIds]) {
                setConsultantKey.add(c.Client__c + '_' + c.Consultant__c + '_' + c.Asset_Class__c);
            }

            List<Consultant__c> lstConsultantForInsert = new List<Consultant__c>();
            for (Opportunity o : lstReleventRecords) {
                if (!setConsultantKey.contains(o.AccountId + '_' + o.Consultant__c + '_' + mapRelatedInvestmentVehicles.get(o.Investment_Vehicle__c).Platform__c)) {
                    lstConsultantForInsert.add(new Consultant__c(Client__c=o.AccountId, Consultant__c=o.Consultant__c, Status__c='Active', Asset_Class__c=mapRelatedInvestmentVehicles.get(o.Investment_Vehicle__c).Platform__c));
                    setConsultantKey.add(o.AccountId + '_' + o.Consultant__c + '_' + mapRelatedInvestmentVehicles.get(o.Investment_Vehicle__c).Platform__c);
                }
            }

            insert lstConsultantForInsert;
        }
    }

    public void createFieldConsultantRelationship(List<Opportunity> records) {
        populateRecordTypeMap();
        Set<Id> setFieldConsultantIds = new Set<Id>();
        Set<Id> setAccountIds = new Set<Id>();
        Set<Id> setInvestmentVehicleIds = new Set<Id>();
        List<Opportunity> lstReleventRecords = new List<Opportunity>();
        for (Opportunity o : records) {
            if (String.isNotBlank(o.Field_Consultant__c)) {
                setFieldConsultantIds.add(o.Field_Consultant__c);
                setAccountIds.add(o.AccountId);
                setInvestmentVehicleIds.add(o.Investment_Vehicle__c);
                lstReleventRecords.add(o);
            }
        }

        if (setFieldConsultantIds.size() > 0) {
            Map<Id, Contact> mapRelatedFieldConsultants = new Map<Id, Contact>([select Id, AccountId, Office__c from Contact where Id in :setFieldConsultantIds]);
            Map<Id, Investment_Vehicle__c> mapRelatedInvestmentVehicles = new Map<Id, Investment_Vehicle__c>([select Id, Platform__c from Investment_Vehicle__c where Id in :setInvestmentVehicleIds]);

            Map<String, Relationship__c> mapRelationship = new Map<String, Relationship__c>();
            for (Relationship__c r : [select Id, Account__c, Contact__c, Related_To_Account__c, Office__c, Asset_Class__c, Status__c, Field_Consultant__c from Relationship__c where Account__c in :setAccountIds and Contact__c in :setFieldConsultantIds]) {
                mapRelationship.put(r.Account__c + '_' + r.Contact__c + '_' + r.Asset_Class__c + '_' + r.Field_Consultant__c, r);
            }

            List<Relationship__c> lstRelationshipForInsert = new List<Relationship__c>();
            List<OpportunityContactRole> lstContactRolesForInsert = new List<OpportunityContactRole>();
            Set<Id> updatedIds = new Set<Id>();
            for (Opportunity o : lstReleventRecords) {
                if (mapRelationship.get(o.AccountId + '_' + o.Field_Consultant__c + '_' + mapRelatedInvestmentVehicles.get(o.Investment_Vehicle__c).Platform__c + '_' + true) == null) {
                    lstRelationshipForInsert.add(
                            new Relationship__c(
                                    Account__c=o.AccountId,
                                    Contact__c=o.Field_Consultant__c,
                                    Related_To_Account__c=mapRelatedFieldConsultants.get(o.Field_Consultant__c).AccountId,
                                    Office__c=mapRelatedFieldConsultants.get(o.Field_Consultant__c).Office__c,
                                    Asset_Class__c=mapRelatedInvestmentVehicles.get(o.Investment_Vehicle__c).Platform__c,
                                    Status__c='Active',
                                    Field_Consultant__c=true
                            )
                    );
                    lstContactRolesForInsert.add(new OpportunityContactRole(OpportunityId=o.Id, ContactId=o.Field_Consultant__c, Role='Field Consultant'));
                    mapRelationship.put(o.AccountId + '_' + o.Field_Consultant__c + '_' + mapRelatedInvestmentVehicles.get(o.Investment_Vehicle__c).Platform__c + '_' + true, new Relationship__c());
                } else {
                    Id relationshipId = mapRelationship.get(o.AccountId + '_' + o.Field_Consultant__c + '_' + mapRelatedInvestmentVehicles.get(o.Investment_Vehicle__c).Platform__c + '_' + true).Id;
                    if (!updatedIds.contains(relationshipId)) {
                        lstRelationshipForInsert.add(new Relationship__c(Id=relationshipId, Status__c='Active'));
                        updatedIds.add(relationshipId);
                    }
                }
            }

            upsert lstRelationshipForInsert;
            insert lstContactRolesForInsert;
        }
    }

    public void createResearchConsultantRelationship(List<Opportunity> records) {
        populateRecordTypeMap();
        Set<Id> pfgRecordTypes = new Set<Id>();
        Set<Id> psgRecordTypes = new Set<Id>();
        for (String recordTypeDeveloperName : mapRecordType.keySet()) {
            if (recordTypeDeveloperName.contains('PFG')) {
                pfgRecordTypes.add(mapRecordType.get(recordTypeDeveloperName));
            }
            if (recordTypeDeveloperName.contains('PSG')) {
                psgRecordTypes.add(mapRecordType.get(recordTypeDeveloperName));
            }
        }
        Set<Id> setResearchConsultantIds = new Set<Id>();
        Set<Id> setAccountIds = new Set<Id>();
        Set<Id> setInvestmentVehicleIds = new Set<Id>();
        List<Opportunity> lstReleventRecords = new List<Opportunity>();
        for (Opportunity o : records) {
            if (String.isNotBlank(o.Research_Consultant__c)) {
                setResearchConsultantIds.add(o.Research_Consultant__c);
                setAccountIds.add(o.AccountId);
                setInvestmentVehicleIds.add(o.Investment_Vehicle__c);
                lstReleventRecords.add(o);
            }
        }

        if (setResearchConsultantIds.size() > 0) {
            Map<Id, Contact> mapRelatedResearchConsultants = new Map<Id, Contact>([select Id, AccountId, Office__c from Contact where Id in :setResearchConsultantIds]);
            Map<Id, Investment_Vehicle__c> mapRelatedInvestmentVehicles = new Map<Id, Investment_Vehicle__c>([select Id, Platform__c from Investment_Vehicle__c where Id in :setInvestmentVehicleIds]);

            Map<String, Relationship__c> mapRelationship = new Map<String, Relationship__c>();
            for (Relationship__c r : [select Id, Account__c, Contact__c, Related_To_Account__c, Office__c, Asset_Class__c, Status__c, Researcher__c from Relationship__c where Account__c in :setAccountIds and Contact__c in :setResearchConsultantIds]) {
                mapRelationship.put(r.Account__c + '_' + r.Contact__c + '_' + r.Asset_Class__c + '_' + r.Researcher__c, r);
            }

            List<Relationship__c> lstRelationshipForInsert = new List<Relationship__c>();
            List<OpportunityContactRole> lstContactRolesForInsert = new List<OpportunityContactRole>();
            Set<Id> updatedIds = new Set<Id>();
            for (Opportunity o : lstReleventRecords) {
                if (mapRelationship.get(o.AccountId + '_' + o.Research_Consultant__c + '_' + mapRelatedInvestmentVehicles.get(o.Investment_Vehicle__c).Platform__c + '_' + true) == null) {
                    Relationship__c newRelationship = new Relationship__c(
                            Account__c=o.AccountId,
                            Contact__c=o.Research_Consultant__c,
                            Related_To_Account__c=mapRelatedResearchConsultants.get(o.Research_Consultant__c).AccountId,
                            Office__c=mapRelatedResearchConsultants.get(o.Research_Consultant__c).Office__c,
                            Asset_Class__c=mapRelatedInvestmentVehicles.get(o.Investment_Vehicle__c).Platform__c,
                            Status__c='Active',
                            Researcher__c=true
                    );
                    if (psgRecordTypes.contains(o.RecordTypeId)) {
                        newRelationship.PSG__c = true;
                    }
                    if (pfgRecordTypes.contains(o.RecordTypeId)) {
                        newRelationship.PFG__c = true;
                    }
                    lstRelationshipForInsert.add(newRelationship);
                    lstContactRolesForInsert.add(new OpportunityContactRole(OpportunityId=o.Id, ContactId=o.Research_Consultant__c, Role='Primary Research Consultant'));
                    mapRelationship.put(o.AccountId + '_' + o.Research_Consultant__c + '_' + mapRelatedInvestmentVehicles.get(o.Investment_Vehicle__c).Platform__c + '_' + true, new Relationship__c());
                } else {
                    Id relationshipId = mapRelationship.get(o.AccountId + '_' + o.Research_Consultant__c + '_' + mapRelatedInvestmentVehicles.get(o.Investment_Vehicle__c).Platform__c + '_' + true).Id;
                    if (!updatedIds.contains(relationshipId)) {
                        lstRelationshipForInsert.add(new Relationship__c(Id=relationshipId, Status__c='Active'));
                        updatedIds.add(relationshipId);
                    }
                }
            }

            upsert lstRelationshipForInsert;
            insert lstContactRolesForInsert;
        }
    }

    private void populateRecordTypeMap() {
        if (mapRecordType == null) {
            mapRecordType = new Map<String, Id>();
            for (RecordType rt : [select Id, Name, DeveloperName from RecordType where SobjectType='Opportunity']) {
                mapRecordType.put(rt.DeveloperName, rt.Id);
                mapRecordType.put(rt.Name, rt.Id);
            }
        }
    }
}