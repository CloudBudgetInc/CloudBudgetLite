/**
Copyright (c) 2021, CloudBudget, Inc.
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

The controller for special component that displaying in Queue standard page "cbTaskDispatcher"
 */
public with sharing class CBTaskDispatcherPageController {

	@AuraEnabled
	public static List<CBTaskQueue__c> getTaskQueuesServer() { //List<CBTaskQueue__c> getTaskQueueRecords
		return new CBTaskQueueSelector().getTaskQueueRecords(null);
	}


	/**
	 * The method validates data completeness
	 * @param taskQueueId
	 * @return validation message if something wrong
	 */
	@AuraEnabled
	public static List<String> validateQueueServer(String taskQueueId) {
		List<String> r = new List<String>();
		for (CBTask__c t : new CBTaskSelector().getTaskRecords('cblight__CBTaskQueue__c = \'' + taskQueueId + '\'')) {
			if (t.ClassName__c == null)
				r.add('Task "' + t.Name + '" does not have Class Name');
			if (t.Parameter1__c == null)
				r.add('Task "' + t.Name + '" does not have the first parameter');
		}
		return r;
	}

	/**
	 * @param taskQueueId
	 * @return list of logs related to the queue
	 */
	@AuraEnabled
	public static List<CBLog__c> getQueueStatisticServer(String taskQueueId) {
		return new CBLogSelector().getLogFilteredBy('cblight__Source__c = \'' + taskQueueId + '\'');
	}

	/**
	 * The method runs current Queue tasks
	 * @param taskQueueId
	 */
	@AuraEnabled
	public static void runQueueServer(String taskQueueId) {
		CBTaskDispatcherService.runQueue(taskQueueId);
	}
	/**
	 * Method resets the task queue and its tasks
	 */
	@AuraEnabled
	public static void resetTaskQueueServer(String taskQueueId) {
		CBTaskDispatcherService.resetTaskQueue(taskQueueId);
	}

	@AuraEnabled
	public static void saveTaskQueueAndTasksServer(CBTaskQueue__c tq, List<CBTask__c> tasks) {
		upsert tq;
		for (CBTask__c t : tasks) {
			t.CBTaskQueue__c = tq.Id;
		}
		upsert tasks;
	}

	@AuraEnabled
	public static void deleteTaskQueueServer(String tqId) {
		Database.delete(tqId);
	}

	@AuraEnabled
	public static List<CBSO> getProcessClassesSOServer() {
		List<CBSO> r = new List<CBSO>();
		for (ApexClass ac : [SELECT Name, NamespacePrefix FROM ApexClass WHERE (NamespacePrefix = null OR NamespacePrefix = 'cblight')AND Name LIKE '%Process' WITH SECURITY_ENFORCED ORDER BY Name]) {
			r.add(new CBSO(ac.Name, ac.Name));
		}
		return r;
	}
}