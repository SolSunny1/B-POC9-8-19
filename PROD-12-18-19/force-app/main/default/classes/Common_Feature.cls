public with sharing class Common_Feature {
    private static Map<string, Feature__c> mapFeatures = null;


    public static boolean isEnabled(string sFeatureName) {
        return isEnabled(sFeatureName, true);
    }

    public static boolean isEnabled(string sFeatureName, boolean bDefault) {
        if (mapFeatures == null)
            loadFeatures();

        Feature__c feature = mapFeatures.get(sFeatureName);
        if (feature == null) {
            // if a feature record cannot be found, return default
            if (bDefault == null)
                return true;
            return bDefault;
        }
        else {
            // otherwise return isEnabled value
            system.debug('Feature found: ' + feature.Enabled__c);
            return feature.Enabled__c;
        }
    }

    private static void loadFeatures() {

        mapFeatures = new Map<string, Feature__c>();
        for (Feature__c feature : Feature__c.getAll().values()) {
            mapFeatures.put(feature.Name, feature);

        }
        system.debug('Features loaded: ' + mapFeatures.size());

    }
}