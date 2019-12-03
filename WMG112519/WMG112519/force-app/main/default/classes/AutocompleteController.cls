global with sharing class AutocompleteController 
{
   @RemoteAction
    global static list<sObject> searchObject(string objectName, string query, String numberOfResults, String wildCardOption, String FilterField , String FilterValue) {

        // check if the object is a valid object to search
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        Schema.SObjectType sot = gd.get(objectName);
        if (sot == null) {
            // Object name not valid
            return null;
        }
        // cretae the where-clause
        String WhereClause = ' like \'';
        if (wildCardOption=='true') { Whereclause += '%'; }
        Whereclause += String.escapeSingleQuotes(query) + '%\'';
    if (FilterValue != null && FilterValue.length() > 0)
    {
      Whereclause += ' and ' + FilterField + ' = \'' +  String.escapeSingleQuotes(FilterValue) + '\'';
    }
        
        //build the dynamic soql query
        String soqlQuery= 'select id, Name from ' + objectName + ' where name' + Whereclause + ' order by Name limit ' + numberOfResults;
    System.debug('****: ' + soqlQuery);
    
        List<sObject> Results = new List<sObject>();
        try {
            Results = Database.query(soqlQuery);
        }
        catch (QueryException e) { return null; }
        
        return Results;
    }
}