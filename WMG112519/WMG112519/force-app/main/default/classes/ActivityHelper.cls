public class ActivityHelper {
    public static list<ObjectFieldMapping__c> getObjectFieldMappingInfo(string sFunctionalityType,string sObjectName){
        list<ObjectFieldMapping__c> lstObjectFieldMapping=new list<ObjectFieldMapping__c>();
        list<ObjectFieldMapping__c> lstObjectFieldMappingInfo= ObjectFieldMapping__c.getAll().values();
        System.debug('+++ lstObjectFieldMappingInfo +++' + lstObjectFieldMappingInfo.size());
        if(lstObjectFieldMappingInfo != null && !lstObjectFieldMappingInfo.isEmpty()){
            for(ObjectFieldMapping__c objFieldMapping : lstObjectFieldMappingInfo){
                if(objFieldMapping.Functionality_Type__c != null && objFieldMapping.Functionality_Type__c.equals(sFunctionalityType) && objFieldMapping.Object_API_Name__c.equals(sObjectName)){
                    lstObjectFieldMapping.add(objFieldMapping);
                }
            }
        }
        return lstObjectFieldMapping;
    }
}