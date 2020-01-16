public with sharing class ConfigurableRollup {
	
	/*public static void test(){
		rollUp([Select Id, Order__c, Opportunity_Property__c From OpportunityLineItem Where Order__c != null limit 10]);
	}*/
	
	public static Map<String, Map<String, List<RollupFieldWrapper>>> ROLLUP_CONFIGURATION {
		get{
			if(ROLLUP_CONFIGURATION == null){
				ROLLUP_CONFIGURATION = initRollupConfiguration();
			}
			return ROLLUP_CONFIGURATION;
		} private set;
	}
	
	
	public static void rollup(List<sObject> newRecords){
		
		if(!newRecords.isEmpty()){
			Map<String, List<RollupFieldWrapper>> rollupFieldsByTargetObject = ROLLUP_CONFIGURATION.get(String.valueOf(newRecords.get(0).getSObjectType()));
			if(rollupFieldsByTargetObject != null && !rollupFieldsByTargetObject.isEmpty()){
				rollUp(newRecords, null, rollupFieldsByTargetObject);
			}
		}
	}
	
	public static void rollup(List<sObject> newRecords, Map<Id, sObject> oldRecords){
		system.debug('newRecords----->'+newRecords);
		if(!newRecords.isEmpty()){
			Map<String, List<RollupFieldWrapper>> rollupFieldsByTargetObject = ROLLUP_CONFIGURATION.get(String.valueOf(newRecords.get(0).getSObjectType()));
			system.debug('rollupFieldsByTargetObject----->'+rollupFieldsByTargetObject);
			if(rollupFieldsByTargetObject != null && !rollupFieldsByTargetObject.isEmpty()){
				rollUp(newRecords, oldRecords, rollupFieldsByTargetObject);
			}
		}
	}
	
	public static void rollup(List<sObject> newRecords, Map<Id, sObject> oldRecords, Map<String, List<RollupFieldWrapper>> rollupFieldsByTargetObject){
		System.debug('--->rollupFieldsByTargetObject:'+rollupFieldsByTargetObject);
		String sourceObjectName = String.valueOf(newRecords.get(0).getSObjectType());
		for(String targetObjectName : rollupFieldsByTargetObject.keySet()){
			
			List<RollupFieldWrapper> rollupWrapperList = rollupFieldsByTargetObject.get(targetObjectName);
			String relationshipFieldName = rollupWrapperList.get(0).relationshipField;
			
			Set<Id> relatedTargetObjectIds = new Set<Id>();
			for(Sobject record:newRecords){

				/**** Added by Bits In Glass on July 19, 2017 to address CPU time limit *****/
				if(record instanceof Investor_Position__c) {
					
					Investor_Position__c investorPositionObj = (Investor_Position__c) record;
					if(investorPositionObj.Bypass_Rollup__c == true){
						System.debug('\n Inside if condition to check if bypass flag is set to true');
						continue;
					}
				}

				System.debug('\n After continue is executed');
				Object newRelatedTargetObjectId = record.get(relationshipFieldName);
				Object oldRelatedTargetObjectId = oldRecords != null ? oldRecords.get((Id)record.get('Id')).get(relationshipFieldName) : null;
				
				if(newRelatedTargetObjectId != null){
					relatedTargetObjectIds.add((Id)newRelatedTargetObjectId);
				}
				
				if(oldRelatedTargetObjectId != null){
					relatedTargetObjectIds.add((Id)oldRelatedTargetObjectId);
				}
			}
			
			//Get all fields
			String sourceRecordQuery = 'SELECT ID, ' + relationshipFieldName + '';
			String targetRecordQuery = 'SELECT ID '; 
			
			Set<String> sourceRecordFields = new Set<String>();
			Set<String> targetRecordFields = new Set<String>();
			
			for(RollupFieldWrapper wrapper:rollupWrapperList){
				if(!sourceRecordFields.contains(wrapper.sourceField.name)){
					sourceRecordFields.add(wrapper.sourceField.name);
					sourceRecordQuery = sourceRecordQuery + ',' + wrapper.sourceField.name;
					
					if(wrapper.isFilter && !sourceRecordFields.contains(wrapper.filterField)){
						sourceRecordFields.add(wrapper.filterField);
						sourceRecordQuery = sourceRecordQuery + ',' + wrapper.filterField;
					}
					
				}
				
				if(!targetRecordFields.contains(wrapper.targetField.name)){
					targetRecordFields.add(wrapper.targetField.name);
					targetRecordQuery = targetRecordQuery + ',' + wrapper.targetField.name;
				}
			}
			
			if(!relatedTargetObjectIds.isEmpty()){
				
				sourceRecordQuery = sourceRecordQuery + ' FROM  '+ sourceObjectName +' WHERE '+ relationshipFieldName + ' IN :relatedTargetObjectIds';
				targetRecordQuery = targetRecordQuery + ' FROM  '+ targetObjectName +' WHERE ID IN :relatedTargetObjectIds';
					
				System.debug('--->sourceRecordQuery:'+sourceRecordQuery);
				System.debug('--->targetRecordQuery:'+targetRecordQuery);
				
				
					
				List<Sobject> sourceObjects = Database.query(sourceRecordQuery);
				List<Sobject> relatedTargetObjects = Database.query(targetRecordQuery);
				
				System.debug('--->sourceObjects size:'+sourceObjects.size());
				System.debug('--->targetRecord size:'+relatedTargetObjects.size());
				rollup(sourceObjects, relatedTargetObjects, rollupWrapperList, relationshipFieldName);
			}
			
		}
	}
	
	private static void rollup(List<Sobject> sourceObjects, List<Sobject> relatedTargetObjects, List<RollupFieldWrapper> rollupWrapperList, String relationshipField){
		
		List<SObject> recordsToUpdate = new List<SObject>();
		
		Map<Id, List<SObject>> sourceRecordByTargetRecordId = new Map<Id, List<SObject>>();
		Map<Id, SObject> targetRecordById = new Map<Id, SObject>(); 
		
		for(SObject sourceObject:sourceObjects){
			Id targetObjectID = (ID)sourceObject.get(relationshipField);
			List<SObject> sourceRecords = sourceRecordByTargetRecordId.get(targetObjectID);
			
			System.debug('--->sourceObject:'+sourceObject);
			System.debug('--->targetObjectID:'+targetObjectID);
			System.debug('--->relationshipField:'+relationshipField);
			
			if(sourceRecords == null){
				sourceRecords = new List<SObject>();
				sourceRecordByTargetRecordId.put(targetObjectID, sourceRecords);
			}
			sourceRecords.add(sourceObject);
		}
		
		for(SObject record:relatedTargetObjects){
			targetRecordById.put((ID)record.get('Id'), record);
		}
		
		for(ID targetRecordId:sourceRecordByTargetRecordId.keySet()){
			SObject targetRecord = targetRecordById.get(targetRecordId);
			List<SObject> sourceRecords = sourceRecordByTargetRecordId.get(targetRecordId);
			if(targetRecord != null && sourceRecords != null){ //@todo should not happen
				
				
				System.debug('--->targetObjectID:'+targetRecordId);
				System.debug('--->sourceRecords:'+sourceRecords);
				System.debug('--->targetRecord:'+targetRecord);
				
				Boolean isChanged = false;
				for(RollupFieldWrapper wrapper:rollupWrapperList){
					if(rollupSingleField(sourceRecords, targetRecord, wrapper)){
						isChanged = true;
					}
				}
				
				if(isChanged){
					recordsToUpdate.add(targetRecord);
				}
			}
		}
		if(!recordsToUpdate.isEmpty()){
			System.debug('--->recordsToUpdate:'+recordsToUpdate);
			update recordsToUpdate;
		}
	}
	
	private static Boolean rollupSingleField(List<SObject> records, SObject targetRecord, RollupFieldWrapper rollupDetail){
		System.debug('--->rollupDetail:'+rollupDetail);
		System.debug('--->targetRecord:'+targetRecord);
		Object existingTargetValue = targetRecord.get(rollupDetail.targetField.name);
		
		List<Object> sourceValues = new List<Object>();
		
		System.debug('--->existingTargetValue:'+existingTargetValue);
		
		Integer booleanValueCount = 0;
		
		for(SObject record:records){
			System.debug('--->records:'+records.size());
			Boolean isFilterValueMatched = rollupDetail.isFilter ? (rollupDetail.filterFieldValue ? (Boolean)record.get(rollupDetail.filterField) : !(Boolean)record.get(rollupDetail.filterField) ) : true;
			Object sourceFieldValue = record.get(rollupDetail.sourceField.name);
			if(sourceFieldValue != null && isFilterValueMatched){
				if(rollupDetail.sourceField.isBoolean && (Boolean) sourceFieldValue){
					booleanValueCount++;
				}else{
					sourceValues.add(sourceFieldValue);
				}
			}
		}
		
		if(!sourceValues.isEmpty()){
			sourceValues.sort();
		}
		
		if(rollupDetail.sourceField.isBoolean){
			System.debug('--->booleanValueCount:'+booleanValueCount);
			if(existingTargetValue == null || (Double) existingTargetValue != booleanValueCount){
				targetRecord.put(rollupDetail.targetField.name, booleanValueCount);
				return true;
			}
		} else if(!sourceValues.isEmpty()){
			if(rollupDetail.sourceField.isNumber){
				Double result = 0;
				if(rollupDetail.isSum){
					for(Object value:sourceValues){
						result = result + (Double)value;
					}
				}else if(rollupDetail.isMax){
					result = (Double)sourceValues.get(sourceValues.size()-1);
				}else if(rollupDetail.isMin){
					result = (Double)sourceValues.get(0);
				}
				System.debug('--->number result:'+result);
				if(existingTargetValue == null || (Double) existingTargetValue != result){
					targetRecord.put(rollupDetail.targetField.name, result);
					return true;
				}
					
			} else if(rollupDetail.sourceField.isDate){
				Date result ;
				if(rollupDetail.isMax){
					result = (Date)sourceValues.get(sourceValues.size()-1);
				}else if(rollupDetail.isMin){
					result = (Date)sourceValues.get(0);
				}
				System.debug('--->date result:'+result);
				if(existingTargetValue == null || (Date) existingTargetValue != result){
					targetRecord.put(rollupDetail.targetField.name, result);
					return true;
				}
			} else if(rollupDetail.sourceField.isDateTime){
				DateTime result ;
				if(rollupDetail.isMax){
					result = (DateTime)sourceValues.get(sourceValues.size()-1);
				}else if(rollupDetail.isMin){
					result = (DateTime)sourceValues.get(0);
				}
				System.debug('--->datetime result:'+result);
				if(existingTargetValue == null || (DateTime) existingTargetValue != result){
					if(rollupDetail.targetField.isDate){
						targetRecord.put(rollupDetail.targetField.name, result != null ? result.date() : null);
					}else{
						targetRecord.put(rollupDetail.targetField.name, result);
					}
					
					return true;
				}
			}
		}
		
		System.debug('--->sourceValues:'+sourceValues);
		return false;
	}
	
	private static Map<String, Map<String, List<RollupFieldWrapper>>> initRollupConfiguration(){
		
		Map<String, Map<String, List<RollupFieldWrapper>>> result = new Map<String, Map<String, List<RollupFieldWrapper>>>();
		
		Map<String, Map<String, List<Configurable_RollUp_Setting__c>>> settingsByObjectType = new Map<String, Map<String, List<Configurable_RollUp_Setting__c>>>();
		 
		for(Configurable_RollUp_Setting__c setting:Configurable_RollUp_Setting__c.getAll().values()){
			Map<String, List<Configurable_RollUp_Setting__c>> settingsForThisObjectByTargetObject = settingsByObjectType.get(setting.Source_Object_Name__c);
			
			if(settingsForThisObjectByTargetObject == null){
				settingsForThisObjectByTargetObject = new Map<String, List<Configurable_RollUp_Setting__c>>();
				settingsByObjectType.put(setting.Source_Object_Name__c, settingsForThisObjectByTargetObject);
			}
			
			List<Configurable_RollUp_Setting__c> settingsForThisObject = settingsForThisObjectByTargetObject.get(setting.Relationship_Field_API_Name__c);
			
			if(settingsForThisObject == null){
				settingsForThisObject = new List<Configurable_RollUp_Setting__c>();
				settingsForThisObjectByTargetObject.put(setting.Relationship_Field_API_Name__c, settingsForThisObject);
			}
			settingsForThisObject.add(setting);
		}
		system.debug(':::settingsByObjectType:::'+settingsByObjectType);
		
		Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
		
		for(String sourceObjectName : settingsByObjectType.keySet()){
			
			Schema.SObjectType sourceSObjectType = globalDescribe.get(sourceObjectName);
			system.debug(':::sourceSObjectType:::'+sourceSObjectType);
			Map<String, List<Configurable_RollUp_Setting__c>> settingsForThisObjectByTargetObjectType = settingsByObjectType.get(sourceObjectName);
			
			system.debug(':::settingsForThisObjectByTargetObjectType:::'+settingsForThisObjectByTargetObjectType);
			if(sourceSObjectType != null && settingsForThisObjectByTargetObjectType != null && !settingsForThisObjectByTargetObjectType.isEmpty()){
				
				Map<String, Schema.SObjectField> sourceSObjectSObjectFields = sourceSObjectType.getDescribe().fields.getMap();
				for(String st: sourceSObjectSObjectFields.keyset()){
					if(st.Startswith('i')){
						system.debug(st+'   :::sourceSObjectSObjectFields:::'+sourceSObjectSObjectFields.get(st));
					}
				}
				
				
					for(String targetObjectRelationshipFieldName:settingsForThisObjectByTargetObjectType.keySet()){
						system.debug(':::settingsForThisObjectByTargetObjectType:::'+settingsForThisObjectByTargetObjectType);
						List<Configurable_RollUp_Setting__c> settingsForThisObject = settingsForThisObjectByTargetObjectType.get(targetObjectRelationshipFieldName);
						system.debug(':::settingsForThisObject:::'+settingsForThisObject);
						
						Schema.SObjectField targetObjectRelationshipSObjectField = sourceSObjectSObjectFields.get(targetObjectRelationshipFieldName.tolowercase());
						Schema.SObjectType targetSObjectType = targetObjectRelationshipSObjectField != null ? globalDescribe.get(targetObjectRelationshipSObjectField.getDescribe().getReferenceTo().get(0).getDescribe().getName()) : null;
						
						system.debug(':::targetObjectRelationshipSObjectField:::'+targetObjectRelationshipSObjectField);
						system.debug(':::targetSObjectType:::'+targetSObjectType);
						
						Map<String, Schema.SObjectField> targetSObjectSObjectFields = targetSObjectType != null ? targetSObjectType.getDescribe().fields.getMap() : null;
						
						system.debug(':::targetSObjectSObjectFields:::'+targetSObjectSObjectFields);
						if(targetSObjectType != null && settingsForThisObject != null && targetSObjectSObjectFields != null){
								
							for(Configurable_RollUp_Setting__c setting:settingsForThisObject){
								Schema.SObjectField sourceObjectSObjectField = sourceSObjectSObjectFields.get(setting.Source_Field__c);
								Schema.SObjectField targetObjectSObjectField = targetSObjectSObjectFields.get(setting.Target_Field__c);
								if(sourceObjectSObjectField != null && targetObjectSObjectField != null){
									RollupFieldWrapper rollupFieldWrapper = new RollupFieldWrapper(setting);
									rollupFieldWrapper.sourceObject = sourceSObjectType.getDescribe().getName();
									rollupFieldWrapper.targetObject = targetSObjectType.getDescribe().getName();
									rollupFieldWrapper.sourceField = new RollupField(sourceObjectSObjectField);
									rollupFieldWrapper.targetField = new RollupField(targetObjectSObjectField);
									rollupFieldWrapper.relationshipField = setting.Relationship_Field_API_Name__c;
									addToRollupFieldWrapper(result, RollupFieldWrapper);
								}
							}
						}
					}
				
				
			}
		}
		
		return result;
	}
	
	private static void addToRollupFieldWrapper(Map<String, Map<String, List<RollupFieldWrapper>>> result, RollupFieldWrapper field){
		if(field.isValid()){
			Map<String, List<RollupFieldWrapper>> settingsByTargetObject = result.get(field.sourceObject);
			if(settingsByTargetObject == null){
				settingsByTargetObject = new Map<String, List<RollupFieldWrapper>>();
				result.put(field.sourceObject, settingsByTargetObject);
			}
			List<RollupFieldWrapper> RollupFieldWrappers = settingsByTargetObject.get(field.targetObject);
			
			if(RollupFieldWrappers == null){
				RollupFieldWrappers = new List<RollupFieldWrapper>();
				settingsByTargetObject.put(field.targetObject, RollupFieldWrappers);
			}
			RollupFieldWrappers.add(field);
		}
	}
	
	//@TODO
	public class RollupFieldWrapper{
		
		public String sourceObject {get; set;}
		public String targetObject {get; set;}
		
		public String relationshipField {get; set;}
		
		public RollupField sourceField {get; set;}
		public RollupField targetField {get; set;}
		
		//Filter 
		public Boolean isFilter {get; set;}
		public String filterField {get; set;}
		public Boolean filterFieldValue {get; set;} 
		
		
		
		//Operation type
		public Boolean isSum {get; set;}
		public Boolean isMax {get; set;}
		public Boolean isMin {get; set;}
		
		public Boolean isValid(){
			return String.isNotBlank(this.sourceObject) && String.isNotBlank(this.targetObject) && String.isNotBlank(this.relationshipField) && this.sourceField != null && this.targetField != null; 
		}
		
		public RollupFieldWrapper(){
			this.filterFieldValue = true;
			this.isFilter = false;
		}
		
		public RollupFieldWrapper(Configurable_RollUp_Setting__c setting){
			this();
			this.isMax = setting.Maximum__c;
			this.isMin = setting.Minimum__c;
			this.isSum = setting.Sum__c;
			this.isFilter = String.isNotBlank(setting.Filter__c);
			if(this.isFilter){
				this.filterFieldValue = !setting.Filter__c.startsWith('!') ;
				this.filterField = setting.Filter__c.startsWith('!') ? setting.Filter__c.subString(1) : setting.Filter__c;
			}
		}
		
	}
	
	public class RollupField{
		public String name {get; set;}
		
		public Boolean isBoolean {get; set;}
		
		public Boolean isDate {get; set;}
		public Boolean isDateTime {get; set;}
		
		public Boolean isNumber {get; set;}
		
		public Object fieldValue {get; set;}
		
		public RollupField(Schema.SObjectField field){
			Schema.DescribeFieldResult dfr = field.getDescribe();
			String fieldType = String.valueOf(dfr.getType());
			this.name =  field.getDescribe().getName();
			this.isBoolean = fieldType  == 'Boolean';
			this.isDate =  fieldType == 'Date';
			this.isDateTime =  fieldType == 'DateTime';
			this.isNumber =  fieldType == 'Double' || fieldType == 'Integer' || fieldType == 'Currency';
		}
	}
	
}