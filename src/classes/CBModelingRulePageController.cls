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
public with sharing class CBModelingRulePageController {

	private static final Integer FILTER_STRING_SIZE = 3;
	/**
	 * @return full list of clusters
	 */
	@AuraEnabled
	public static List<cblight__CBModelingRuleGroup__c> getAllModelingRuleGroupsServer() {
		return new CBModelingRuleGroupSelector().getAllModelingRuleGroups(null);
	}
	@AuraEnabled
	public static List<cblight__CBModelingRuleGroup__c> getModelingRuleGroupsByFolderIdServer(String folderId) {
		folderId = CBUtils.refineStr(folderId);
		String filter = '';
		if (folderId != null && folderId != 'null') {
			filter = 'CBFolder__c = \'' + folderId + '\'';
		} else {
			filter = 'CBFolder__c = null';
		}
		return new CBModelingRuleGroupSelector().getAllModelingRuleGroups(filter);
	}

	/**
	 * @param modelingRuleId id of selected modeling rule
	 *
	 * @return selected modeling rule with lines
	 */
	@AuraEnabled
	public static cblight__CBModelingRule__c getSelectedModelingRuleServer(String modelingRuleId) {
		return new CBModelingRuleSelector().getModelingRuleById(modelingRuleId);
	}

	/**
	 * @return list of available on the org SObjects
	 */
	@AuraEnabled
	public static List<CBSO> getListOfAvailableSObjectsServer() {
		List<CBSO> result = new List<CBSO>();
		List<String> neededCRMObjects = new List<String>{
				'Account', 'Product', 'Contact', 'Campaign', 'Opportunity'
		};
		Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
		for (Schema.SObjectType st : gd.values()) {
			Schema.DescribeSObjectResult dsr = st.getDescribe();
			if (dsr.isCreateable() && dsr.isCustom() == true) {
				result.add(new CBSO(dsr.getName(), dsr.getLabel()));
			} else if (neededCRMObjects.contains(dsr.getLabel())) {
				result.add(new CBSO(dsr.getName(), dsr.getLabel() + ' (CRM)'));
			}
		}
		result.sort();
		return result;
	}

	/**
	 * @param parentSObjectType name of parent sObject
	 *
	 * @return list of sObject names that may be the child of the parent sObject
	 */
	@AuraEnabled
	public static List<CBSO> getListOfAvailableChildSObjectsServer(String parentSObjectType) {
		List<CBSO> result = new List<CBSO>();
		Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
		if (globalDescribe.size() > 500) { // huge amount of date run into the CPU limit
			return getListOfAvailableSObjectsServer();
		}
		Schema.DescribeSObjectResult dsr;
		Map<String, Schema.SObjectField> descResultFields;
		for (Schema.SObjectType st : globalDescribe.values()) {
			dsr = st.getDescribe();
			if (dsr.isCreateable() && dsr.isCustom() == true) {
				descResultFields = dsr.fields.getMap();
				for (Schema.SObjectField field : descResultFields.values()) {
					if (field.getDescribe().getType() == DisplayType.REFERENCE && // if field type is reference
							parentSObjectType == field.getDescribe().getReferenceTo()[0].getDescribe().getName()) {
						// and lookup to parent sObject
						result.add(new CBSO(dsr.getName(), dsr.getLabel()));
						break;
					}
				}
			}
		}
		return result;
	}
	/**
	* @param filterString string containing part of the name of the sobject
	*
	* @return list of sobjects filtered by part of the name
	 */
	@AuraEnabled
	public static List<CBSO> getFilteredListOfSobjectsServer(String filterString) {
		List<CBSO> result = new List<CBSO>();
		if (filterString != null && filterString.length() >= FILTER_STRING_SIZE) {
			filterString = filterString.toLowerCase();
			for (CBSO so : getListOfAvailableSObjectsServer()) {
				if (so.label.toLowerCase().contains(filterString)) {
					result.add(so);
				}
			}
		}
		return result;
	}
	/**
	 * @param objectName name of the object which field we need to get related object name
	 * @param fieldName field from which we need to get related object name
	 */
	@AuraEnabled
	public static String getSobjectLabelByReferenceServer(String objectName) {
		Schema.SObjectType objectDescribe = Schema.getGlobalDescribe().get(objectName);
		String result;
		if (objectDescribe != null) {
			result = objectDescribe.getDescribe().getLabel();
		} else {
			result = 'SObject was not found';
		}
		return result;
	}

	/**
	 * @param modelingRuleId selected modeling rule Id
	 *
	 * @return
	 */
	@AuraEnabled
	public static Map<String, List<CBSO>> getSourceParentAndChildSObjectFieldsServer(String modelingRuleId) {
		CBModelingRule__c mr = new CBModelingRuleSelector().getModelingRuleById(modelingRuleId);
		Map<String, List<CBSO>> r = new Map<String, List<CBSO>>();
		r.put(
				'sourceParentFieldSO',
				CBUtils.getObjectFieldsSO(mr.SourceRecordParentType__c)
		);
		if (mr.ResultRecordParentType__c != null) {
			r.put(
				'resultParentFieldSO',
				CBUtils.getObjectFieldsSO(mr.ResultRecordParentType__c)
				);
		}
		if (mr.SourceRecordChildType__c != null) {
			r.put(
					'sourceChildFieldSO',
					CBUtils.getObjectFieldsSO(mr.SourceRecordChildType__c)
			);
		}
		if (mr.ResultRecordChildType__c != null) {
			r.put(
					'resultChildFieldSO',
					CBUtils.getObjectFieldsSO(mr.ResultRecordChildType__c)
			);
		}
		return r;
	}

	@AuraEnabled
	public static List<CBSO> getUsersAndQueuesServer() {
		List<CBSO> result = new List<CBSO>();
		for (User u : new UserSelector().getUserRecords('IsActive = TRUE')) {
			result.add(new CBSO(u.Id, 'User: ' + u.Name));
		}
		for (Group u : [
				SELECT Id, Name
				FROM Group
				WHERE Type = 'Queue'
				WITH SECURITY_ENFORCED
				ORDER BY Name
		]) {
			result.add(new CBSO(u.Id, 'Queue: ' + u.Name));
		}
		return result;
	}

	/**
	 * Method counts a number of source records for current modeling rule
	 * @param mrId modeling rule Id
	 * @return 0 - google
	 */
	@AuraEnabled
	public static Integer getRecordNumberServer(String mrId) {
		try {
			cblight__CBModelingRule__c mr = new CBModelingRuleSelector().getModelingRuleById(mrId);
			CBSobjectSelector sel = new CBSobjectSelector(mr.cblight__SourceRecordParentType__c);
			return sel.countSobjects(mr.cblight__SourceParentFilter__c);
		} catch (Exception e) {
			return -1;
		}
	}

	/**
	 * Method checks if all parent sObject of Modeling rule have the CBKey__c field
	 *
	 * @param parentNames ['cblight__CBBudgetLine__c', 'Opportunity']
	 * @return null if all is ok or the warning
	 */
	@AuraEnabled
	public static String checkCBKeyFieldOfParentRecordsServer(List<String> parentNames) {
		for (String pName : parentNames) {
			if (String.isEmpty(pName)) continue;
			SObjectType objType = Schema.getGlobalDescribe().get(pName);
			if (objType.getDescribe().fields.getMap().containsKey('CBKey__c') || objType.getDescribe().fields.getMap().containsKey('cblight__CBKey__c')) continue;
			return 'The sObject "' + pName + '" does not have the required "CBKey__c" field.' +
					' Please go to Setup and add text field named CBKey to continue working with current Modeling Rule';
		}
		return null;
	}

	@AuraEnabled
	public static String saveModelingRuleGroupServer(CBModelingRuleGroup__c modelingRuleGroup) {
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
				new List<SObjectType>{
						CBModelingRuleGroup__c.SObjectType
				}
		);
		uow.registerUpsert(modelingRuleGroup);
		uow.commitWork();
		updateTaskQueue(modelingRuleGroup.Id);
		return modelingRuleGroup.Id;
	}

	@AuraEnabled
	public static String deleteModelingRuleGroupServer(String mrgId) {
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<Schema.SObjectType>{
			CBModelingRule__c.SObjectType,
			CBModelingRuleGroup__c.SObjectType,
			CBTask__c.SObjectType,
			CBTaskQueue__c.SObjectType
		});
		uow.registerDeleted(new CBModelingRuleGroupSelector().getModelingRuleGroupById(mrgId));
		uow.registerDeleted(new CBTaskQueueSelector().getTaskQueueRecords(' cblight__RelatedTo__c = \'' + mrgId + '\' '));
		uow.commitWork();
		return 'Deleted';
	}

	@AuraEnabled
	public static String saveModelingRuleServer(CBModelingRule__c modelingRule, List<CBModelingLine__c> modelingLines) {
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
				new List<SObjectType>{
						CBModelingRule__c.SObjectType, CBModelingLine__c.SObjectType
				}
		);
		uow.registerUpsert(modelingRule);// CBModelingRuleTrigger will update Task Queue
		if (modelingLines != null) {
			for (CBModelingLine__c line : modelingLines) {
				if (line.Id == null) {
					uow.registerNew(line, CBModelingLine__c.CBModelingRule__c, modelingRule);
				} else {
					uow.registerDirty(line, CBModelingLine__c.CBModelingRule__c, modelingRule);
				}
			}
		}
		uow.commitWork();
		return modelingRule.Id;
	}

	@AuraEnabled
	public static String deleteModelingRuleLineServer(String mrLineId) {
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
				new List<SObjectType>{
						CBModelingLine__c.SObjectType
				}
		);
		uow.registerDeleted(new CBSobjectSelector(CBModelingLine__c.SObjectType, false).selectFieldsByNames(new List<String>{
				'Id'
		}).getSobjects('Id = \'' + mrLineId + '\''));
		uow.commitWork();
		return 'Deleted';
	}

	@AuraEnabled
	public static String deleteModelingRuleServer(String mrId) {
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
				new List<SObjectType>{
						CBModelingRule__c.SObjectType
				}
		);
		CBModelingRule__c mr = new CBModelingRuleSelector().getModelingRuleById(mrId);
		uow.registerDeleted(mr);// CBModelingRuleTrigger will update Task Queue
		uow.commitWork();
		return 'Deleted';
	}

	///////////// TASK QUEUE //////////////////
	/**
	 * The method updates modeling rules Task Queue after saving (by 1 mrgId)
	 *
	 * @param mrgId
	 */
	public static void updateTaskQueue(String mrgId) {
		List<CBModelingRuleGroup__c> mrgList = new CBModelingRuleGroupSelector().getAllModelingRuleGroups(' Id = \'' + mrgId + '\'');
		updateTaskQueueInBulk(mrgList);
	}
	/**
	 * The method updates modeling rules Task Queue after saving
	 *
	 * @param mrgId
	 */
	public static void updateTaskQueueInBulk(List<CBModelingRuleGroup__c> mrgList) {
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
				new List<SObjectType>{
						CBTaskQueue__c.SObjectType, CBTask__c.SObjectType
				}
		);
		Set<Id> mrgIdSet = new Set<Id>();
		for (CBModelingRuleGroup__c mrg : mrgList) {
			String mrgId = mrg.Id;
			mrgIdSet.add(mrgId);
			CBTaskQueue__c newQueue = new CBTaskQueue__c(Name = mrg.Name, Status__c = 'Idle', RelatedTo__c = mrgId);
			uow.registerNew(newQueue);
			Integer orderNumber = 0;
			if (mrg.DeleteOldResults__c) {
				CBTask__c newDelTask = new CBTask__c(
						Name = 'Deleting',
						Parameter1__c = mrgId,
						OrderNumber__c = 1,
						ClassName__c = 'CBModelingRuleJobDeletingProcess'
				);
				uow.registerNew(newDelTask, CBTask__c.CBTaskQueue__c, newQueue);
				orderNumber++;
			}
			for (CBModelingRule__c mr : new CBModelingRuleSelector().getModelingRulesByGroupId(mrgId)) {
				orderNumber++;
				if (mr.Mode__c == 'General' || mr.Mode__c == 'Replacing') {
					addTaskToUOW('CBModelingRuleJobProcess', uow, newQueue, mr, orderNumber, null);
				}
				if (mr.Mode__c == 'Deleting') {
					addTaskToUOW('CBModelingRuleJobFilteredDeletingProcess', uow, newQueue, mr, orderNumber, null);
				}
				if (mr.Mode__c == 'Zeroing amounts') {
					addTaskToUOW('CBModelingRuleZeroingAmountsProcess', uow, newQueue, mr, orderNumber, null);
				}
				if (mr.Mode__c == 'Mass Update') {
					addTaskToUOW('CBModelingRuleMassUpdateProcess', uow, newQueue, mr, orderNumber, null);
				}
				if (mr.PeriodShift__c != null && mr.PeriodShift__c != 0) {
					orderNumber++;
					addTaskToUOW('CBModelingRulePeriodShiftProcess', uow, newQueue, mr, orderNumber, 'Period Shift');
				}
			}
		}
		String taskQueueFilter = 'cblight__RelatedTo__c IN ' + CBUtils.getFormattedINQuery(mrgIdSet);
		uow.registerDeleted(new CBTaskQueueSelector().getTaskQueueRecords(taskQueueFilter));
		uow.commitWork();
	}

	/**
	 * @param className - name of the class
	 * @param uow - unit of work to register new task
	 * @param newQueue - task queue
	 * @param mr - modeling rule
	 * @param orderNumber - order number
	 * @param newTasks - task list
	 * @param customName - custom name
	 *
	 */
	private static void addTaskToUOW(String className, fflib_SObjectUnitOfWork uow, CBTaskQueue__c newQueue, CBModelingRule__c mr, Integer orderNumber, String customName) {
		CBTask__c newTask = new CBTask__c(
				Name = customName == null ? mr.Name : customName,
				ClassName__c = className,
				OrderNumber__c = orderNumber
		);
		uow.registerNew(newTask, CBTask__c.CBTaskQueue__c, newQueue);
		uow.registerRelationship(newTask, CBTask__c.Parameter1__c, mr);
	}

	///////////// TASK QUEUE //////////////////

	///////////// GLOBAL LINES ////////////////
	@AuraEnabled
	public static List<CBModelingLine__c> getGlobalModelingLinesServer(String mrId) {
		List<CBModelingLine__c> r = new CBModelingLineSelector().getGlobalModelingLinesByModelingRule(mrId);
		return r;
	}
	///////////// GLOBAL LINES ////////////////

	///////////// PROCESSES //////////////////
	@AuraEnabled
	public static String deleteOldDataServer(String mrgId) {
		new CBModelingRuleJobDeletingProcess().runProcess(mrgId, null);
		return 'Deleted';
	}
	@AuraEnabled
	public static String recalculateDataServer(String mrgId) {
		if (mrgId == null) {
			return null;
		}
		List<CBTaskQueue__c> listOfTaskQueue = new CBTaskQueueSelector().getTaskQueueRecords('cblight__RelatedTo__c = \'' + mrgId + '\'');
		if (listOfTaskQueue == null || listOfTaskQueue.size() == 0) {
			return null;
		}
		CBTaskQueue__c tq = listOfTaskQueue.get(0);
		CBTaskDispatcherService.runQueue(tq.Id);
		return 'In progress';
	}
	///////////// PROCESSES //////////////////

	///////////// JSON ////////////////////////
	@AuraEnabled
	public static Map<String, Object> getFullMRGStructureServer(String mrgId) {
		Map<String, Object> result = new Map<String, Object>();
		CBModelingRuleGroup__c mrg = new CBModelingRuleGroupSelector()
				.getModelingRuleGroupById(mrgId);
		List<CBModelingRule__c> mrList = new CBModelingRuleSelector()
				.getModelingRulesByGroupId(mrgId);
		Map<String, List<CBModelingLine__c>> mlMap = new Map<String, List<CBModelingLine__c>>();
		for (CBModelingRule__c mr : mrList) {
			mlMap.put(mr.Id, mr.CBModelingLines__r);
		}
		result.put('mrg', mrg);
		result.put('mrList', mrList);
		result.put('mlMap', mlMap);
		return result;
	}

	@AuraEnabled
	public static String applyMRGStructureServer(
			CBModelingRuleGroup__c mrg,
			List<CBModelingRule__c> mrList,
			Map<String, List<CBModelingLine__c>> mlMap
	) {
		fflib_ISObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
				new List<Schema.SObjectType>{
						CBModelingRuleGroup__c.sObjectType,
						CBModelingRule__c.sObjectType,
						CBModelingLine__c.sObjectType
				}
		);

		mrg.Name = 'Cloned ' + mrg.Name.left(70);
		if (mrg.Id != null) {
			deleteModelingRuleGroupServer(mrg.Id);
			mrg.Id = null;
		}
		uow.registerNew(mrg);
		for (CBModelingRule__c mr : mrList) { 
			String mrId = mr.Id;
			mr.Id = null;
			uow.registerNew(mr, CBModelingRule__c.CBModelingRuleGroup__c, mrg);
			for (CBModelingLine__c ml : mlMap.get(mrId)) {
				ml.Id = null;
				uow.registerNew(ml, CBModelingLine__c.CBModelingRule__c, mr);
			}
		}
		uow.commitWork();
		return mrg.Id;
	}
	///////////// JSON ////////////////////////
	/**
	 * creates (all of a sudden) predefined modeling lines
	 * @param modelingRuleId - id of modeling rule (who would have thought)
	 */
	@AuraEnabled
	public static void createPredefinedModelingLinesServer(String modelingRuleId) {
		CBModelingLineService.createPredefinedModelingLines(modelingRuleId);
	}
}