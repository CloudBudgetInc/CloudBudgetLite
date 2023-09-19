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

 */


public with sharing class CBInitWizardPageController {

	public static final Map<String, String> mappingTypeAndResultSObjectMap =
			new Map<String, String>{
					'accounts' => 'cblight__CBAccount__c',
					'divisions' => 'cblight__CBDivision__c',
					'periods' => 'cblight__CBPeriod__c',
					'variables1' => 'cblight__CBVariable1__c',
					'variables2' => 'cblight__CBVariable2__c',
					'variables3' => 'cblight__CBVariable3__c',
					'variables4' => 'cblight__CBVariable4__c',
					'variables5' => 'cblight__CBVariable5__c'
			};

	/**
	 * List of sObjects in the org
	 *
	 * @return
	 */
	@AuraEnabled
	public static List<CBSO> getListOfAvailableSObjectsServer() {
		return CBModelingRulePageController.getListOfAvailableSObjectsServer();
	}

	/**
	 * @param sobjectType name of the sObject (cblight__CBPeriod__c as example)
	 *
	 * @return list of sObject fields
	 */
	@AuraEnabled
	public static List<CBSO> getSobjectFieldsServer(String sobjectType) {
		return CBUtils.getObjectFieldsSO(sobjectType);
	}

	/**
	 * The method is for Accounts, Divisions, Periods, Variable X
	 *
	 * @param type
	 *
	 * @return
	 */
	@AuraEnabled
	public static CBMapping__c getRegularMappingServer(String type) {
		CBMapping__c mapping = new CBMappingSelector().getMappingRecordByType(type);
		if (mapping == null) {
			mapping = new CBMapping__c(SourceName__c = 'Name', Type__c = type, ResultSObject__c = mappingTypeAndResultSObjectMap.get(type));
			fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{
					CBMapping__c.SObjectType
			});
			uow.registerNew(mapping);
			uow.commitWork();
		}
		return mapping;
	}

	/**
	 * The method saves one step record
	 * @param mapping - one step = one mapping record.
	 * @return inserted record with Id
	 */
	@AuraEnabled
	public static CBMapping__c saveMappingServer(CBMapping__c mapping) {
		CBMapping__c r = CBMappingService.upsertMapping(mapping);
		createMappingTaskQueueServer();
		return r;
	}

	/**
	 * The method runs mapping process between CB analytics and another
	 *
	 * @param mapping
	 */
	@AuraEnabled
	public static void runMappingServer(CBMapping__c mapping) {
		CBMappingInterface mappingObject = CBMappingService.getMappingClass(mapping.Type__c);
		if (mappingObject.recordNumberIsOutOfLimit()) {
			CBMappingBatch mappingBatch = new CBMappingBatch(mapping.Type__c);
			Database.executeBatch(mappingBatch);
		} else {
			List<sObject> scope = Database.query(mappingObject.getSourceRequestString());
			mappingObject.doMapping(scope);
		}
	}

	/**
	 * The method set configurations to DB
	 * @param configsList : list of CBMapping__c with filled in data
	 */
	@AuraEnabled
	public static void saveConfigurationsServer(List<CBMapping__c> configsList) {
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
				new List<SObjectType>{
						CBMapping__c.SObjectType
				}
		);
		for (CBMapping__c m : new CBMappingSelector().getMappingRecords('')) {
			for (CBMapping__c newMap : configsList) {
				if (newMap.Type__c == m.Type__c) {
					newMap.Id = m.Id;
				}
			}
		}
		uow.registerUpsert(configsList);
		uow.commitWork();
	}

	public static final String MAPPING_TQ_NAME = 'Mapping Analytics';
	/**
	 * Method creates a task queue to run mapping task by task
	 */
	@AuraEnabled
	public static void createMappingTaskQueueServer() {
		deleteOldMappingTQ();

		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
				new List<SObjectType>{
						CBTaskQueue__c.SObjectType, CBTask__c.SObjectType
				}
		);

		CBTaskQueue__c mappingTQ = new CBTaskQueue__c(Name = MAPPING_TQ_NAME);
		uow.registerNew(mappingTQ);

		List<CBTask__c> tasks = new List<CBTask__c>();
		Integer orderNum = 1;
		for (CBMapping__c mapping : new CBMappingSelector().getMappingRecords('cblight__SourceSObject__c != null ')) {
			CBTask__c newTask = new CBTask__c(Name = 'Map ' + mapping.Type__c, OrderNumber__c = orderNum, ClassName__c = 'CBMappingJobProcess', Parameter1__c = mapping.Type__c);
			uow.registerNew(newTask, CBTask__c.CBTaskQueue__c, mappingTQ);
			orderNum++;
		}

		uow.commitWork();
	}
	/**
	 * Method deletes old task queue for mapping
	 */
	private static void deleteOldMappingTQ() {
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
				new List<SObjectType>{
						CBTaskQueue__c.SObjectType
				}
		);
		CBTaskQueue__c tq = new CBTaskQueueSelector().getTaskQueueWithTaskChildren('Name = \'' + MAPPING_TQ_NAME + '\' ');
		if (tq == null) return;
		uow.registerDeleted(tq);
		uow.commitWork();
	}

}