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

Tasks serves to run jobs using needed consequence.
For example to run Modeling rule batches you need to create a task queue with needed consequence
and run the runQueue method

 */
public with sharing class CBTaskDispatcherService {

	private static final String IDLE = 'Idle';
	private static final String ACTIVE = 'Active';

	/**
	 * The method runs task queue one after one
	 *
	 * @param queueId - task queue Id
	 */
	public static String runQueue(String queueId) {
		cblight__CBTaskQueue__c queue = new CBTaskQueueSelector().getTaskQueueRecordById(queueId);
		if (queue == null) {
			return 'The Task Queue does not exist, please refresh the page and try again.';
		}
		if (queue.Status__c.equals(ACTIVE)) {
			return 'The active process is still ongoing.';
		}

		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
				new List<SObjectType>{
						CBLog__c.SObjectType
				}
		);
		uow.registerNew(new CBLog__c(Description__c = queue.Name + ' task queue started', Type__c = 'TASK QUEUE', Title__c = 'Running', Source__c = queue.Id, Status__c = 'PROGRESS'));
		uow.commitWork();
		Savepoint sp = Database.setSavepoint();
		try {
			queue.Status__c = ACTIVE;
			fflib_SObjectUnitOfWork uow1 = new fflib_SObjectUnitOfWork(
					new List<SObjectType>{
							CBTaskQueue__c.SObjectType
					}
			);
			uow1.registerDirty(queue);
			uow1.commitWork();
			runNextTask();
		} catch (Exception e) {
			Database.rollback(sp);
			CBLogService.setLog(e, 'Run Task Error');
			resetTaskQueue(queueId);
		}
		return 'success';
	}

	/**
	 * The method try to find IDLE task run it and change status to Active
	 * Also Active task will converted to Done
	 */
	public static void runNextTask() {
		if (activeQueue == null) {
			return;
		}
		List<CBTask__c> listToUpdate = new List<CBTask__c>();
		Boolean needToFinalize = true;
		for (CBTask__c task : activeQueue.CB_Tasks__r) {
			if (task.Status__c.equals(ACTIVE)) {
				task.Status__c = 'Done';
				listToUpdate.add(task);
			}
			if (task.Status__c.equals(IDLE)) {
				task.Status__c = ACTIVE;
				listToUpdate.add(task);
				runTask(task);
				needToFinalize = false;
				break;
			}
		}
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
				new List<SObjectType>{
						CBTask__c.SObjectType
				}
		);
		uow.registerDirty(listToUpdate);
		uow.commitWork();
		if (needToFinalize) {
			finalizeQueue();
		}
	}

	/**
	 * @param task current task need to be started
	 *
	 */
	public static void runTask(CBTask__c task) {
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
				new List<SObjectType>{
						CBLog__c.SObjectType
				}
		);
		uow.registerNew(new CBLog__c(Description__c = task.Name, Status__c = 'PROGRESS', Type__c = 'TASK QUEUE', Title__c = 'Running', Source__c = task.CBTaskQueue__c));
		uow.commitWork();
		Savepoint sp = Database.setSavepoint();
		try {
			Type t = Type.forName(task.ClassName__c);
			CBProcessInterface obj = (CBProcessInterface) t.newInstance();
			obj.runProcess(task.Parameter1__c, task.Parameter2__c);
		} catch (Exception e) {
			Database.rollback(sp);
			CBLogService.setLog(e, 'Run Task Error');
			resetTaskQueue(task.CBTaskQueue__c);
		}
	}

	/**
	 * The method set active Queue in start position
	 */
	public static void finalizeQueue() {
		activeQueue.Status__c = IDLE;
		List<CBTask__c> tasks = activeQueue.CB_Tasks__r;
		for (CBTask__c t : tasks) {
			t.Status__c = IDLE;
		}
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
				new List<SObjectType>{
						CBTaskQueue__c.SObjectType, CBTask__c.SObjectType, CBLog__c.SObjectType
				}
		);
		uow.registerDirty(activeQueue);
		uow.registerDirty(tasks);
		CBLogService.setLog(activeQueue.Name + ' Done', 'DONE', activeQueue.Name + ' Done');
		CBLogService.insertLog();
		//uow.registerNew(new CBLog__c(Description__c = activeQueue.Name + ' Done', Status__c = 'DONE', Type__c = 'TASK QUEUE', Title__c = 'Done', Source__c = activeQueue.Id));
		uow.commitWork();
	}

	/**
	 * // TODO Task Selector
	 *
	 * @return selected queue
	 */
	public static cblight__CBTaskQueue__c activeQueue {
		get {
			if (activeQueue == null) {
				activeQueue = new CBTaskQueueSelector().getTaskQueueWithTaskChildren('cblight__Status__c = \'Active\'');
			}
			return activeQueue;
		}
		set;
	}

	/**
	 * The method resets statuses of Task Queue and Tasks to "IDLE"
	 */
	public static void resetTaskQueue(String queueId) {
		CBTaskQueue__c tq = new CBTaskQueueSelector().getTaskQueueWithTaskChildren('Id =  \'' + queueId + '\'');
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
				new List<SObjectType>{
						CBTaskQueue__c.SObjectType, CBTask__c.SObjectType
				}
		);
		for (CBTask__c t : tq.CB_Tasks__r) {
			t.Status__c = IDLE;
		}
		tq.Status__c = IDLE;
		uow.registerDirty(tq);
		uow.registerDirty(tq.CB_Tasks__r);
		uow.commitWork();
	}
}