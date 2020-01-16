/**************************************************************
Apex Class Name     : Core_DataTypes

Version             : 27.0

Date Created        : 7-JAN-2014

Function            : <Class for Carrier Types and CONSTANTS> 
***************************************************************/

global with sharing class Core_DataTypes {
    global Core_DataTypes(){}
   /*
    public with sharing class StringCarrier {
    	//An object wrapper, passes object from component to page
    	public String value{get; set;}
    }
  Removed, refactored as top level class	
    public with sharing class BoolCarrier {
        //An object wrapper, passes object from component to page
        public Boolean value {get; set;}
    }
    public with sharing class sObjectWrapper {
       public String id {get; set;}
       public String name {get; set;}
    
        public sObjectWrapper(String i, String n){
            id = i;
            name = n;
        }
    }*/
    global static final string NAMESPACE_PREFIX = '';
    global static final string COVERAGE = 'Coverage';
    global static final string CONTACT = 'Contact';
    global static final string ID = 'id';
    global static final string NAME = 'name';
    global static final string CAMPAIGN = 'Campaign';
    global static final string SUBJECT = 'Subject';
    global static final string REMOVE = 'remove';
    global static final string UTF = 'UTF-8';
    global static final string ASCS = 'ASC';
    global static final string DESCS = 'DESC';
    global static final string SMARTLISTID = 'smartListId';
    global static final string SOBJ = 'Sobject';
    global static final string NEW_BUTTON = 'New';
    global static final string EDIT_BUTTON = 'Edit';
    global static final string DELETE_BUTTON = 'Delete';
    global static final string Resolve_BUTTON = 'Resolve';
    global static final string TABID = 'TabId';
    global static final string DUMMY = 'dummy';
    global static final string NULL_CONSTANT = 'Null';
    global static final string BOOLEAN_CONSTANT = 'boolean';
    global static final string MULTI_PICKLIST = 'multipicklist';
    global static final string DATE_CONSTANT = 'date';
    global static final string DATE_FILTER = 'Date';
    global static final string REFERENCE = 'Reference';
    global static final string DATE_TIME = 'dateTime';
    global static final string OWNERID = 'OwnerId';
    global static final string CHECKBOX = 'checkbox';
    global static final string TEXT = 'text';
    global static final string TEXT_AREA = 'textarea';
    global static final string AUTO_COMPLETE_TEXT = 'AutoCompleteText';
    global static final string SEARCH = 'search';
    global static final string QUERY = 'query'; 
    global static final string NONE = 'None';
    global static final string PARENTID = 'parentId';
    global static final string MASTER_RECORD_ID = 'Master Record ID';
    global static final string PICKLIST = 'Picklist';
    global static final string CONSTANT_003 = '003';
    global static final string CONSTANT_001 = '001';
    global static final string STRING_CONSTANT = 'string';
    global static final string EMAIL = 'email';
    global static final string URL = 'URL';
    global static final string PHONE = 'phone';
    global static final string ADDRESS = 'address';
    global static final string CURRENCY_CONSTANT = 'currency';
    global static final string NUMBER_CONSTANT = 'number';
    global static final string PERCENT = 'percent';
    global static final string DISPLAY_ALL_RECORDS = 'Display All Records';
    global static final string SETUP = '/apex/Setup';
    global static final string SETUP_SMARTLIST_COLUMNS = '/apex/Setup_SmartList_Columns';
    global static final string SETUP_SMARTLIST_NEW = '/apex/Setup_SmartList?sfdc.tabName=';
    global static final string SETUP_SMARTLIST = '/apex/Setup_SmartList_List?sfdc.tabName=';
    global static final string SETUP_SMARTADDER = '/apex/Setup_SmartAdder_List';
    global static final string SMARTLIST = '/apex/SmartList';
    global static final string SMARTADDERTAB = '/apex/Z_SmartAdderTab';
    global static final string SETUP_SMARTWIDGET_NEW = '/apex/Setup_SmartWidget';
    global static final string SETUP_SMARTADDER_NEW = '/apex/Setup_SmartAdder';
    global static final string SMARTLISTIDFORCOM = 'smartlistId';

}