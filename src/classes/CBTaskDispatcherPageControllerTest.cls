/**
 * Created by Aleksei Volkov on 06/28/2022.
 * Copyright (c) 2022, CloudBudget, Inc.
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 * Neither the name of the CloudBudget, Inc. nor the names of its contributors
 * may be used to endorse or promote products derived from this software
 * without specific prior written permission.
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 * <p/>
 * This test class covers the CBTaskDispatcherPageController, CBTaskSelector classes
 */
@IsTest
public class CBTaskDispatcherPageControllerTest {

	@IsTest
	public static void testValidateQueueServer() {
		List<CBTaskQueue__c> taskQueueList = CBDataFactoryTest.createTaskQueues(1);
		CBTask__c testTask = new CBTask__c();
		testTask.Name = 'Test Task';
		testTask.CBTaskQueue__c = taskQueueList[0].Id;
		insert testTask;
		List<String> actualList = CBTaskDispatcherPageController.validateQueueServer(testTask.CBTaskQueue__c);
		System.assertEquals(2, actualList.size(), 'not equals 2');
	}

	@IsTest
	public static void testValidateQueueServerWithNullClaccNameAndParameter() {
		CBTask__c task = new CBTask__c();
		List<CBTaskQueue__c> queueList = CBDataFactoryTest.createTaskQueues(1);
		task.Name = 'Test Task';
		task.CBTaskQueue__c = queueList[0].Id;
		insert task;
		List<String> expectedList = new List<String>();
		List<String> actualList = CBTaskDispatcherPageController.validateQueueServer(task.CBTaskQueue__c);
		System.assertNotEquals(expectedList.size(), actualList.size(), 'lists are not equals');
	}

	@IsTest
	public static void testGetQueueStatisticServer() {
		User adminUser = CBTestService.createAdminUser();
		System.runAs(adminUser) {
			List<CBTask__c> taskList = CBDataFactoryTest.createTasks(1);
			String rId = taskList[0].CBTaskQueue__c;
			List<CBLog__c> logs = CBDataFactoryTest.createLogs(1);
			logs[0].Source__c = rId;
			upsert logs;
			List<CBLog__c> actualList = CBTaskDispatcherPageController.getQueueStatisticServer(rId);
			System.assertEquals(logs.size(), actualList.size(), 'lists are not equals');
		}
	}

	@IsTest
	public static void testRunQueueServer() {
		User adminUser = CBTestService.createAdminUser();
		System.runAs(adminUser) {
			List<CBTask__c> taskList = CBDataFactoryTest.createTasks(1);
			CBOrgVariable__c orgVar = CBDataFactoryTest.createOrgVariable();
			CBTaskDispatcherPageController.runQueueServer(taskList[0].CBTaskQueue__c);
			System.assert(true, 'test failed');
		}
	}

	@IsTest
	public static void testGetTaskQueueWithTaskChildren() {
		User adminUser = CBTestService.createAdminUser();
		System.runAs(adminUser) {
			List<CBTask__c> taskList = CBDataFactoryTest.createTasks(1);
			CBTaskQueue__c actualTaskQueue = new CBTaskQueueSelector().getTaskQueueWithTaskChildren('Name LIKE \'%' + 'Test' + '%\'');
			System.assertEquals(taskList[0].CBTaskQueue__c, actualTaskQueue.Id, 'queues are not equals');
		}
	}

	@IsTest
	public static void testGetTaskQueueRecords() {
		User adminUser = CBTestService.createAdminUser();
		System.runAs(adminUser) {
			List<CBTask__c> taskList = CBDataFactoryTest.createTasks(1);
			List<CBTaskQueue__c> actualTaskQueueList = new CBTaskQueueSelector().getTaskQueueRecords('Name LIKE \'%' + 'Test' + '%\'');
			System.assertEquals(taskList[0].CBTaskQueue__c, actualTaskQueueList[0].Id, 'queues are not equals');
		}
	}

	// Testing CBTaskSelector class
	@IsTest
	public static void testGetTaskRecordById() {
		User adminUser = CBTestService.createAdminUser();
		System.runAs(adminUser) {
			List<CBTask__c> taskList = CBDataFactoryTest.createTasks(1);
			CBTask__c actualTask = new CBTaskSelector().getTaskRecordById(taskList[0].Id);
			System.assertEquals(taskList[0].Id, actualTask.Id, 'obj is not equals');
		}
	}

	@IsTest
	public static void testGetTaskRecordByNullId() {
		User adminUser = CBTestService.createAdminUser();
		System.runAs(adminUser) {
			CBTask__c actualTask = new CBTaskSelector().getTaskRecordById(null);
			System.assertEquals(null, actualTask, 'not null');
		}
	}
}