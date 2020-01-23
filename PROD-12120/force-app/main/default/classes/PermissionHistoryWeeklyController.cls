public class PermissionHistoryWeeklyController { //This Class is used to create a Custom report for Permission History   
    List<Permission__History> permissionHis;
    List<Permission__History> permissionHisExcel;
    integer totalCount ;
    List<Contact> contactlst;    
    public String header { get; set; }    
    public List<Permission__History> getpermissionHis() {
        if(permissionHis == null) {
            permissionHis = [SELECT CreatedBy.Name,CreatedDate,Field,Id,NewValue,OldValue,Parent.id,Parent.Fund__r.name,Parent.Account__r.Name,
                             Parent.Account_Vehicle__r.Legal_Entity_Legal_Name__c,Parent.Name,Parent.Contact__r.Name,
                             Parent.Contact__r.PFG_CRM_Lead__r.Name,Parent.Contact__r.Email
                             FROM Permission__History WHERE CreatedDate = LAST_N_DAYS:7 and Field in ( 'Alert_Status__c' , 'Status__c') ORDER BY CreatedDate,NewValue ASC NULLS LAST limit 500 ];
                      
        }               
        return permissionHis;
    }
    public List<Permission__History> getpermissionHisExcel() {
        if(permissionHisExcel == null) {
            permissionHisExcel = [SELECT CreatedBy.Name,CreatedDate,Field,Id,NewValue,OldValue,Parent.id,Parent.Fund__r.name,Parent.Account__r.Name,
                             Parent.Account_Vehicle__r.Legal_Entity_Legal_Name__c,Parent.Name,Parent.Contact__r.Name,
                             Parent.Contact__r.PFG_CRM_Lead__r.Name,Parent.Contact__r.Email
                             FROM Permission__History WHERE CreatedDate = LAST_N_DAYS:7 and Field in ( 'Alert_Status__c' , 'Status__c') ORDER BY CreatedDate,NewValue ASC NULLS LAST ];
                      
        }		       
        header = 'Contact,Email,Fund,Legal Entity, Account,Change By, Field, Old Value, New Value, Created Date, Permission Link, Permission Number';
        return permissionHisExcel;
    }
    public Integer getTotalCount(){
            return totalCount =   [SELECT count() FROM Permission__History WHERE CreatedDate = LAST_N_DAYS:7 and Field in ( 'Alert_Status__c' , 'Status__c')];
       } 
    
         //Save as Excel
    public PageReference SaveAsCSV() {
       PageReference retURLExcel = new PageReference('/apex/PermissionHistory_ExcelWeekly');
       return retURLExcel ;
    
    }    
}