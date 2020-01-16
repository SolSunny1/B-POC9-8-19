@isTest(SeeAllData=False)
private class testMethod_LocaleFormattedDatetime 
{
  static testMethod void LocaleFormattedDatetime_Test () 
  {
    test.startTest();
    locale_formatted_datetime_Controller myCon = new locale_formatted_datetime_Controller ();
    myCon.date_time = System.now();
    string str = myCon.getTimeZoneValue() ;
    System.assertNotEquals(0, str.length() );
    test.stopTest();
  }
}