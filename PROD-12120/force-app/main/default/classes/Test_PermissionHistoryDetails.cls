@isTest (SeeAllData=false)
public class Test_PermissionHistoryDetails { 
 
  static testMethod void test_getpermissionHis_UseCase1(){
      PermissionHistoryController testC = new PermissionHistoryController();
      test.startTest();
      testC.getpermissionHis();
      testC.SaveAsCSV();
      List<Permission__History> permissionHis;     
      test.stopTest();
  }
    static testMethod void test_getpermissionHis_Weekly(){
      PermissionHistoryWeeklyController testCW = new PermissionHistoryWeeklyController();
      test.startTest();
      testCW.getpermissionHis();
        testCW.getpermissionHisExcel();
        testCW.getTotalCount();
        testCW.SaveAsCSV();
      List<Permission__History> permissionHis;     
      test.stopTest();
  }
    public testmethod static void RunScheduleDaily() {
       Test.StartTest();
      	SchedulePermissionHistoryEmail schPerH = new SchedulePermissionHistoryEmail();
		String sch = '20 30 8 10 2 ?';
		String jobID = system.schedule('Test schPerH', sch, schPerH);
       Test.StopTest();      
      
  }
    
    public testmethod static void RunScheduleWeekly() {
       Test.StartTest();
      	SchedulePermissionHistoryWeekly schPerH = new SchedulePermissionHistoryWeekly();
		String sch = '20 30 8 10 2 ?';
		String jobID = system.schedule('Test schPerH', sch, schPerH);
       Test.StopTest();      
      
  }
}