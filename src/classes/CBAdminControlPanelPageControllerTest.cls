/**
 * This test class covers the CBAdminControlPanelPageController class
 */
@IsTest
public class CBAdminControlPanelPageControllerTest {
	@TestSetup
	static void makeData() {
		User adminUser = CBTestService.createAdminUser();
	}

	@IsTest
	public static void testGetTaskQueuesServer() {
		List<CBTaskQueue__c> expectedTaskQueueList = CBDataFactoryTest.createTaskQueues(1);
		List<CBTaskQueue__c> actualList = CBAdminControlPanelPageController.getTaskQueuesServer();
		System.assertEquals(expectedTaskQueueList.size(), actualList.size(), 'size not equals');
	}

	@IsTest
	public static void testGetOrgLimitsServer() {
		List<CBAdminControlPanelPageController.ReportRow> actualList = CBAdminControlPanelPageController.getOrgLimitsServer();
		System.assert(!actualList.isEmpty(), 'list is not empty');
	}

	@IsTest
	public static void testGetObjectStatisticServer() {
		List<CBDivision__c> divList = CBDataFactoryTest.createDivisions(1);
		CBDataFactoryTest.createOrgVariable();
		CBMapping__c mapDiv = CBDataFactoryTest.createDivisionCBMapping();
		CBAdminControlPanelPageController.ReportRow actualList = CBAdminControlPanelPageController.getObjectStatisticServer('divisions');
		System.assert(actualList != null, 'list is empty');
	}

	@IsTest
	public static void testsaveScheduledJobServer() {
		User adminUser = CBTestService.getAdminUser();
		System.runAs(adminUser) {
			Test.startTest();
			List<CBTaskQueue__c> expectedTaskQueueList = CBDataFactoryTest.createTaskQueues(1);
			String jobName = expectedTaskQueueList[0].Name;
			Integer hours = 10;
			Integer minutes = 20;
			CBAdminControlPanelPageController.saveScheduledJobServer(jobName, hours, minutes);

			CronTrigger cronTrigger1 = [
				SELECT Id, CronExpression, TimesTriggered, NextFireTime, CronJobDetail.Name
				FROM CronTrigger
				WHERE CronJobDetail.Name = :jobName
			];
			System.assertEquals(jobName, cronTrigger1.CronJobDetail.Name, 'names are not equals');
			Test.stopTest();
		}

	}

	@IsTest
	public static void testGetPublicGroupSOServer() {
		Group gr = new Group(Name = 'Test Group');
		gr.Type = 'Regular';
		insert gr;
		List<CBSO> actualList = CBAdminControlPanelPageController.getPublicGroupSOServer();
		System.assertEquals(1, actualList.size(), 'size not equals');
	}

	@IsTest
	public static void testRunTaskQueueServer() {
		User adminUser = CBTestService.getAdminUser();
		System.runAs(adminUser) {
			List<CBTaskQueue__c> testQ = CBDataFactoryTest.createTaskQueues(1);
			CBAdminControlPanelPageController.runTaskQueueServer(testQ[0].Id);
			CBLog__c actualLog = [SELECT Id, Description__c FROM cblight__CBLog__c WHERE Source__c = :testQ[0].Id AND Title__c = 'Running'];
			System.assertEquals(testQ[0].Name + ' task queue started', actualLog.Description__c, 'current task is not running');
		}

	}

	@IsTest
	public static void testGetAuditTrailsServer() {
		List<SObject> actualList = CBAdminControlPanelPageController.getAuditTrailsServer();
		System.assert(!actualList.isEmpty(), 'list not empty');
	}

	@IsTest
	public static void testGenerateTrialNonFinLibsDataServer() {
		String actualMessage = CBAdminControlPanelPageController.generateTrialNonFinLibsDataServer();
		System.assertEquals('Trial Non Financial Libs Generated', actualMessage, 'not expected message');
	}

	@IsTest
	public static void testGenerateTrialDataServer() {
		User adminUser = CBTestService.getAdminUser();
		System.runAs(adminUser) {
			CBDataFactoryTest.createOrgVariable();
			String actualMessage = CBAdminControlPanelPageController.generateTrialDataServer();
			System.assertEquals('Trial Data Generated', actualMessage, 'not expected message');
		}
	}
}