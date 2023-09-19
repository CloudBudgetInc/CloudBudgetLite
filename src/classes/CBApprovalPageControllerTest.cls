/** 
Created by Aleksei Volkov on 06/23/2022.
Copyright (c) 2022, CloudBudget, Inc.
All rights reserved.
Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:
* Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.
* Neither the name of the CloudBudget, Inc. nor the names of its contributors
may be used to endorse or promote products derived from this software
without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
OF THE POSSIBILITY OF SUCH DAMAGE.

This test class covers the CBApprovalPageController class
 */
@isTest
public class CBApprovalPageControllerTest {

    @TestSetup
    static void setData(){
        User adminUser = CBTestService.createAdminUser();
         //Create Users and Perm Set
         String orgId=UserInfo.getOrganizationId(); 
         String dateString=String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');  
         Integer randomId = Integer.valueOf(Math.rint(Math.random()*1000000)); 
         String uniqueName=orgId+dateString+randomId; 
         Profile pf= [Select Id from profile where Name='System Administrator'];
         
         
 
         User uu=new User(firstname = 'ABC', 
         lastName = 'XYZ', 
         email = uniqueName + '@test' + orgId + '.org', 
         Username = uniqueName + '@test' + orgId + '.org', 
         EmailEncodingKey = 'ISO-8859-1', 
         Alias = uniqueName.substring(18, 23), 
         TimeZoneSidKey = 'America/Los_Angeles', 
         LocaleSidKey = 'en_US', 
         LanguageLocaleKey = 'en_US', 
         ProfileId = pf.Id);
         //UserRoleId = role.Id); 
 
         insert uu;
         System.runAs(uu) {
           UserRole role=new UserRole(Name= 'ABC'); 
           insert role;
           uu.UserRoleId = role.Id;
           update uu;
           PermissionSet ps = new PermissionSet(Label = 'CB2', Name = 'CloudBudget2');
         insert ps;
         insert new PermissionSetAssignment(AssigneeId = uu.id, PermissionSetId = ps.Id);
         }
        
    }
    
    @isTest
    public static void testGetBudgetLinesForApproveServer() {
        List<CBBudgetLine__c> listBL = CBDataFactoryTest.createBudgetLines(5);
        List<String> ids = new List<String>();
        for(CBBudgetLine__c item: listBL){
            ids.add(item.Id);
        }
        List<CBBudgetLine__c> actualList = CBApprovalPageController.getBudgetLinesForApproveServer(ids);
        System.assertEquals(listBL.size(), actualList.size(), 'size not equals');
    }

    @isTest
    public static void testGetBudgetLinesForApproveServerWithNullIds() {
        List<CBBudgetLine__c> actualList = CBApprovalPageController.getBudgetLinesForApproveServer(null);
        System.assertEquals(null, actualList, 'current list is not null');
    }

    @isTest
    public static void testTriggerStatusServerForwardTrue() {
        List<CBBudgetLine__c> listBL = CBDataFactoryTest.createBudgetLines(5);
        List<String> ids = new List<String>();
        for(CBBudgetLine__c item: listBL){
            ids.add(item.Id);
        }
        User adminUser = CBTestService.getAdminUser();
        System.runAs(adminUser) {
            CBApprovalPageController.triggerStatusServer(ids, true);
        }
        List<cblight__CBBudgetLine__c> actualBLs = [SELECT Id, cblight__APAheadTrigger__c FROM cblight__CBBudgetLine__c];
        System.assertEquals(true, actualBLs[0].cblight__APAheadTrigger__c, 'current field not true');
    }

    @isTest
    public static void testTriggerStatusServerForwardFalse() {
        List<CBBudgetLine__c> listBL = CBDataFactoryTest.createBudgetLines(5);
        List<String> ids = new List<String>();
        for(CBBudgetLine__c item: listBL){
            ids.add(item.Id);
        }
        User adminUser = CBTestService.getAdminUser();
        System.runAs(adminUser) {
            CBApprovalPageController.triggerStatusServer(ids, false);
        }
        List<cblight__CBBudgetLine__c> actualBLs = [SELECT Id, cblight__APBackTrigger__c FROM cblight__CBBudgetLine__c];
        System.assertEquals(true, actualBLs[0].cblight__APBackTrigger__c, 'current field not true');
    }

    @isTest
    public static void checkIfUserNotAdminServer () {
        User uu = [SELECT Name, Id FROM User WHERE firstname = 'ABC' AND
        lastName = 'XYZ'];
        String userProfileName = [SELECT Name FROM profile WHERE id = :userinfo.getProfileId() WITH SECURITY_ENFORCED].Name;
        Boolean isAdmin = userProfileName != 'System Administrator'? true : false;

        System.runAs(uu) {
            Boolean userIsNotAdmin = CBApprovalPageController.checkIfUserNotAdminServer();
            System.assertEquals(isAdmin, userIsNotAdmin, 'method is correct');
        }
    }

    @isTest
    public static void getUserServer() {
        List <User> userListActual = CBApprovalPageController.getUserServer();
        Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1][0].IsSandbox;
        List<User> userListExpected = new List<User>();
        if (isSandbox) {
            userListExpected = [SELECT Id, Name FROM User WHERE IsActive = TRUE WITH SECURITY_ENFORCED ORDER BY Name];
        } else {
            List<Id> userListId = new List<Id>();
            for (UserPackageLicense userPackageLicense : [
                SELECT UserId
                FROM UserPackageLicense
                WHERE PackageLicense.NamespacePrefix = 'cblight'
                WITH SECURITY_ENFORCED
                ]) {
                    userListId.add(userPackageLicense.UserId);
                }
            userListExpected = [SELECT Id, Name FROM User WHERE Id IN :userListId WITH SECURITY_ENFORCED ORDER BY Name];
        }
        System.assertEquals(userListExpected.size(), userListActual.size(), 'list sizes not equal');
    }

    @isTest
    public static void sendEmailToController () {
        User uu = [SELECT Id FROM User WHERE firstname = 'ABC' AND
        lastName = 'XYZ'];
        List <String> userIdList = new List <String> ();
        userIdList.add(String.valueOf(uu.Id));
        String body = 'Test email body';
        String subject = 'Test email subject';
        CBApprovalPageController.sendEmailToController(body, userIdList, subject);
        System.assertEquals(1, Limits.getEmailInvocations(), 'Emails should be sent');
    }

    @isTest
    public static void saveBLtoServer () {
        List<CBBudgetLine__c> blList = [SELECT Id, NFL1__c, NFL2__c, NFL3__c, NFL4__c, NFL5__c FROM cblight__CBBudgetLine__c];
        CBApprovalPageController.saveBLtoServer(blList);
        List<CBBudgetLine__c> actualList = [SELECT Id, NFL1__c, NFL2__c, NFL3__c, NFL4__c, NFL5__c FROM cblight__CBBudgetLine__c];
        System.assertEquals(blList.size(), actualList.size(), 'size is equals');
    }    

}