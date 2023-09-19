/** 
Created by Aleksei Volkov on 07/11/2022.
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

This test class covers the CBModelingRulePageController, CBModelingRuleGroupSelector,
CBModelingRuleGroupDomain, CBModelingRuleSelector classes
 */
@isTest
public class CBModelingRulePageControllerTest {
	@TestSetup
	static void makeData(){
		User adminUser = CBTestService.createAdminUser();
	}

	@isTest
	public static void testGetListOfAvailableChildSObjectsServer() {
		User adminUser = CBTestService.getAdminUser();
		System.runAs(adminUser) {
			String parentSObjectType = 'CBAmount__c';
			List<CBSO> actualList = CBModelingRulePageController.getListOfAvailableChildSObjectsServer(parentSObjectType);
			System.assert(!actualList.isEmpty(), 'list is empty');
		}
	}

	@isTest
	public static void testGetRecordNumberServer() {
		User adminUser = CBTestService.getAdminUser();
		System.runAs(adminUser) {
			CBDataFactoryTest.createBudgetLines(1);
			List<CBModelingRule__c> expectedModRuleList = CBDataFactoryTest.createModelingRules(1);
			Integer count = CBModelingRulePageController.getRecordNumberServer(expectedModRuleList[0].Id);
			System.assertEquals(1, count, 'size is not equals count');
		}
	}

	@isTest
	public static void testGetUsersAndQueuesServer() {
		User adminUser = CBTestService.getAdminUser();
		System.runAs(adminUser) {
			List<CBSO> actualList = CBModelingRulePageController.getUsersAndQueuesServer();
			System.assert(!actualList.isEmpty(), 'list is empty');
		}
	}

	@isTest
	public static void testGetAllModelingRuleGroupsServer() {
		User adminUser = CBTestService.getAdminUser();
		System.runAs(adminUser) {
			List<cblight__CBModelingRuleGroup__c> expectedModRuleGrList = CBDataFactoryTest.createModelingRuleGroups(2);
			List<cblight__CBModelingRuleGroup__c> actualList = CBModelingRulePageController.getAllModelingRuleGroupsServer();
			System.assertEquals(expectedModRuleGrList.size(), actualList.size(), 'lists are not equals');
		}
	}

	@isTest
	public static void testGetSelectedModelingRuleServer() {
		User adminUser = CBTestService.getAdminUser();
		System.runAs(adminUser) {
			List<CBModelingRule__c> expectedModRuleList = CBDataFactoryTest.createModelingRules(2);
			String id = expectedModRuleList[0].Id;
			CBModelingRule__c actualModRule = CBModelingRulePageController.getSelectedModelingRuleServer(id);
			System.assertEquals(id, actualModRule.Id, 'IDs are not equals');
		}
	}

	@isTest
	public static void testGetListOfAvailableSObjectsServer() {
		User adminUser = CBTestService.getAdminUser();
		System.runAs(adminUser) {
			List<CBSO> actualList = CBModelingRulePageController.getListOfAvailableSObjectsServer();
			System.assert(!actualList.isEmpty(), 'list is empty');
		}
	}

	@isTest
	public static void testSaveModelingRuleGroupServer() {
		User adminUser = CBTestService.getAdminUser();
		System.runAs(adminUser) {
			List<CBModelingRuleGroup__c> expectedModRuleGrList = CBDataFactoryTest.createModelingRuleGroups(1);
			String rId = CBModelingRulePageController.saveModelingRuleGroupServer(expectedModRuleGrList[0]);
			System.assertEquals(expectedModRuleGrList[0].Id, rId, 'IDs are not equals');
		}
	}

	@isTest
	public static void testDeleteModelingRuleGroupServer() {
		User adminUser = CBTestService.getAdminUser();
		System.runAs(adminUser) {
			List<CBModelingRule__c> expectedModRuleList = CBDataFactoryTest.createModelingRules(1);
			String message = CBModelingRulePageController.deleteModelingRuleGroupServer(expectedModRuleList[0].CBModelingRuleGroup__c);
			List<CBModelingRule__c> actualRules = [SELECT Id FROM cblight__CBModelingRule__c];
			System.assert(actualRules.isEmpty(), 'list is empty');
		}
	}

	@isTest
	public static void testSaveModelingRuleServer() {
		User adminUser = CBTestService.getAdminUser();
		System.runAs(adminUser) {
			List<CBModelingRule__c> modRuleList = CBDataFactoryTest.createModelingRules(1);
			List<CBModelingLine__c> modLines = CBDataFactoryTest.createModelingLines(2);
			String rId = CBModelingRulePageController.saveModelingRuleServer(modRuleList[0], modLines);
			System.assertEquals(modRuleList[0].Id, rId, 'IDs are not equals');
		}
	}

	@isTest
	public static void testDeleteModelingRuleLineServer() {
		User adminUser = CBTestService.getAdminUser();
		System.runAs(adminUser) {
			List<CBModelingLine__c> modLines = CBDataFactoryTest.createModelingLines(2);
			String message = CBModelingRulePageController.deleteModelingRuleLineServer(modLines[0].Id);
			List<CBModelingLine__c> actualLines = [SELECT Id FROM cblight__CBModelingLine__c WHERE Id = :modLines[0].Id];
			System.assert(actualLines.isEmpty(), 'MR line was not deleted');
		}
	}

	@isTest
	public static void testUpdateTaskQueue() {
		User adminUser = CBTestService.getAdminUser();
		System.runAs(adminUser) {
			List<CBModelingRuleGroup__c> expectedModRuleGrList = CBDataFactoryTest.createModelingRuleGroups(1);
			CBModelingRulePageController.updateTaskQueue(expectedModRuleGrList[0].Id);
			CBTaskQueue__c tq = [SELECT Id, Name, RelatedTo__c FROM cblight__CBTaskQueue__c WHERE RelatedTo__c = :expectedModRuleGrList[0].Id];
			System.assertEquals(expectedModRuleGrList[0].Id, tq.RelatedTo__c, 'task does not updated');
		}

	}

	@isTest
	public static void testGetGlobalModelingLinesServer() {
		User adminUser = CBTestService.getAdminUser();
		System.runAs(adminUser) {
			List<CBModelingLine__c> modLines = CBDataFactoryTest.createModelingLines(1);
			List<CBModelingLine__c> actualLIst = CBModelingRulePageController.getGlobalModelingLinesServer(modLines[0].CBModelingRule__c);
			System.assertEquals(modLines.size(), actualLIst.size(), 'lists are not equals');
		}
	}

	@isTest
	public static void testGetSourceParentAndChildSObjectFieldsServer() {
		User adminUser = CBTestService.getAdminUser();
		System.runAs(adminUser) {
			List<CBModelingRule__c> modRuleList = CBDataFactoryTest.createModelingRules(1);
			Map<String, List<CBSO>> actualMap = CBModelingRulePageController.getSourceParentAndChildSObjectFieldsServer(modRuleList[0].Id);
			System.assert(!actualMap.isEmpty(), 'map is empty');
		}
	}

	@isTest
	public static void testRecalculateDataServer() {
		User adminUser = CBTestService.getAdminUser();
		System.runAs(adminUser) {
			List<CBModelingRuleGroup__c> expectedModRuleGrList = CBDataFactoryTest.createModelingRuleGroups(1);
			List<CBTaskQueue__c> tq = CBDataFactoryTest.createTaskQueues(1);
			tq[0].RelatedTo__c = expectedModRuleGrList[0].Id;
			upsert tq;
			String message = CBModelingRulePageController.recalculateDataServer(expectedModRuleGrList[0].Id);
			System.assertEquals('In progress', message, 'mesages are not equals');
		}
	}

	@isTest
	public static void testGetFullMRGStructureServer() {
		User adminUser = CBTestService.getAdminUser();
		System.runAs(adminUser) {
			List<CBModelingRule__c> modRuleList = CBDataFactoryTest.createModelingRules(1);
			String mrgId = modRuleList[0].CBModelingRuleGroup__c;
			Map<String, Object> actualMap = CBModelingRulePageController.getFullMRGStructureServer(mrgId);
			System.assertEquals(3, actualMap.size(), 'size is not equals 3');
		}
	}

	@isTest
	public static void testApplyMRGStructureServer() {
		User adminUser = CBTestService.getAdminUser();
		System.runAs(adminUser) {
			List<CBModelingLine__c> modLines = CBDataFactoryTest.createModelingLines(2);
			List<CBModelingRule__c> modRuleList = [SELECT Id, Name, cblight__ResultRecordParentType__c, cblight__SourceRecordParentType__c FROM cblight__CBModelingRule__c];
			List<CBModelingRuleGroup__c> modRuleGrs = [SELECT Id, Name FROM cblight__CBModelingRuleGroup__c];
			Map<String, List<CBModelingLine__c>> mlMap = new Map<String, List<CBModelingLine__c>>();
			mlMap.put(modRuleList[0].Id, modLines);
			String actualId = CBModelingRulePageController.applyMRGStructureServer(modRuleGrs[0], modRuleList, mlMap);
			System.assertEquals(modRuleGrs[0].Id, actualId, 'IDs are not equals');
		}
	}

	@isTest
	public static void testDeleteModelingRuleServer() {
		User adminUser = CBTestService.getAdminUser();
		System.runAs(adminUser) {
			List<CBModelingRule__c> modRuleList = CBDataFactoryTest.createModelingRules(1);
			String message = CBModelingRulePageController.deleteModelingRuleServer(modRuleList[0].Id);
			System.assertEquals('Deleted', message, 'mesages are not equals');
		}
	}

	@isTest
	public static void testDeleteOldDataServer() {
		User adminUser = CBTestService.getAdminUser();
		System.runAs(adminUser) {
			List<CBModelingRule__c> modRuleList = CBDataFactoryTest.createModelingRules(1);
			CBCube__c cube = CBDataFactoryTest.createCBCube();
			cube.CBKey__c = modRuleList[0].CBModelingRuleGroup__c;
			upsert cube;
			CBTaskQueue__c testTaskQueue = new CBTaskQueue__c(Name = 'Test Task Queue');
			testTaskQueue.Status__c = 'Active';
			upsert testTaskQueue;
			String message = CBModelingRulePageController.deleteOldDataServer(modRuleList[0].CBModelingRuleGroup__c);
			System.assertEquals('Deleted', message, 'mesages are not equals');
		}
	}

	//Testing CBModelingRuleSourceSelector class
	@isTest
	public static void testGetSourceRecords() {
		User adminUser = CBTestService.getAdminUser();
		System.runAs(adminUser) {
			List<CBModelingRule__c> modRuleList = CBDataFactoryTest.createModelingRules(1);
			List<SObject> actualList = new CBModelingRuleSourceSelector(modRuleList[0], '').getSourceRecords();
			System.assert(actualList.isEmpty(), 'list not empty');
		}
	}
}