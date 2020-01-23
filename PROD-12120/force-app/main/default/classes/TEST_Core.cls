/******************************************

Apex Class Name     : TEST_Core

Version             : 29.0

Date Created        : 8-NOV-2013

Function            : <Code Coverage for Core_DataTypes, Core_DataCarrier classes>

******************************************/

@isTest (SeeAllData=false)
private with sharing class TEST_Core {

    //=================================================================================================================
    // CORE DATATYPES
    //=================================================================================================================

    private static TestMethod void TestCoreDataTypes() {
        Core_DataTypes obj = new Core_DataTypes();
        //system.assertEquals('Test', 'Test');
        system.assert(obj != null, 'Can instantiate core datatypes');
    }
}