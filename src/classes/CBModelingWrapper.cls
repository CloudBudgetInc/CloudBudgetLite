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

The wrapper for storing source and result data
 */
public with sharing class CBModelingWrapper {

	/**
	 * @param modelingRule current modeling rule
	 * @param parentRecords parent records with children inside
	 * @param type  type of data (source or result)
	 */
	public CBModelingWrapper(CBModelingRule__c modelingRule, List<SObject> parentRecords, String type) {
		this.modelingRule = modelingRule;
		this.parentRecords = parentRecords;
		this.type = type;
		initBaseCollections();
		updateInternalMapping();
	}

	private String type; // type of data ('source' or 'result')
	private CBModelingRule__c modelingRule;
	private String relationChildParentName; // cblight__CBAmounts__r
	private String boundChildToParentFieldName; // cblight__CBAmount__c
	private List<SObject> parentRecords;
	public List<RecordCell> mainListOfRecords = new List<RecordCell>(); // source or result records in Cell Wrappers
	private Map<String, RecordCell> cellMapById = new Map<String, RecordCell>();
	public Map<String, List<RecordCell>> cellMapByKey = new Map<String, List<RecordCell>>(); // key is record key, value is list of parent records
	/**
	 * List of a record fields that form the record key
	 * KeyFields Example: "cblight__CBAccount__c,cblight__CBDivision__c,cblight__CBVariable1__c"
	 */
	private List<String> resultKeyFields {
		get {
			if (resultKeyFields == null) {
				resultKeyFields = modelingRule.KeyFields__c.split(',');
			}
			return resultKeyFields;
		}
		set;
	}
	/**
	 * Converts result keys to source key fields
	 */
	private List<String> sourceKeyFields {
		get {
			if (sourceKeyFields == null) {
				sourceKeyFields = new List<String>();
				for (String rField : resultKeyFields) { // iterate over fields for key
					for (CBModelingLine__c ml : modelingRule.CBModelingLines__r) { // iterate over modeling rule lines
						if (ml.ResultField__c.equals(rField)) { // find the result key is equal field for the key
							sourceKeyFields.add(ml.SourceField__c);
							break;
						}
					}
				}
			}
			return sourceKeyFields;
		}
		set;
	}

	/////////// PUBLIC METHODS  ////////////
	public RecordCell getRecordCellById(String recordId) {
		return cellMapById.get(recordId);
	}
	public List<RecordCell> getRecordCellsByKey(String key) {
		return cellMapByKey.get(key);
	}
	public List<RecordCell> getAllRecordCells() {
		return mainListOfRecords;
	}
	public List<SObject> getOnlyParentSobjects(List<CBModelingWrapper.RecordCell> cells) {
		List<SObject> r = new List<SObject>();
		for (CBModelingWrapper.RecordCell rc : cells) {
			r.add(rc.record);
		}
		return r;
	}
	public String getRelationChildParentName() {
		return relationChildParentName;
	}
	/**
	 * The method adds a new record to the cells of the wrapper
	 *
	 * @param newCell
	 */
	public void addNewCell(RecordCell newCell) {
		mainListOfRecords.add(newCell);
		updateInternalMapping();
	}

	/**
	 * Methods takes a record and generates an unique code from its fields
	 * @param record any sObject
	 * @return unique code from modeling rule Id in the beginning
	 */
	public String generateRecordKey(SObject record) {
		List<String> keys = new List<String>{
				modelingRule.CBModelingRuleGroup__c // in any case the first Id in the record key is the Modeling Rule Group Id
		};
		String val;
		List<String> keyFields = type.equals('source') ? sourceKeyFields : resultKeyFields; // to generate source record key we should use source key fields
		for (String field : keyFields) {
			val = CBModelingRuleMappingService.getExtId((String) record.get(field), field); // get Ext Id from the analytic Id if exist
			keys.add(val);
		}
		return String.join(keys, '');
	}
	/**
	 * Update record keys if it is source
	 */
	public void recalculateKeys() {
		for (RecordCell rc : mainListOfRecords) {
			String key = generateRecordKey(rc.record);
			CBModelingRuleService.setKeyFieldValue(rc.record, key);
		}
	}
	/**
	 * @param objects list of any type sobjects
	 * @return set of these object keys
	 */
	public Set<String> getKeySet() {
		Set<String> r = new Set<String>();
		for (SObject record : parentRecords) {
			r.add(CBModelingRuleService.getKeyFieldValue(record));
		}
		return r;
	}
	/**
	 * Upsert generated results
	 */
	public void upsertWrapperData() {
		try {
			Set<Schema.SObjectType> sTypeSet = new Set<Schema.SObjectType>();
			for (RecordCell rc : mainListOfRecords) {
				SObject s = rc.record;
				Schema.SObjectType recordSobjType = s.getSObjectType();
				sTypeSet.add(recordSobjType);
				if (rc.childRecords != null) {
					for (Sobject childSobj : rc.childRecords) {
						sTypeSet.add(childSobj.getSObjectType());
					}
				}
			}
			fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<Schema.SObjectType>(sTypeSet));
			Integer parentObjectsCount = 0;
			Integer childObjectsCount = 0;
			for (RecordCell rc : mainListOfRecords) {
				rc.boundChildRecordsWithParent(boundChildToParentFieldName, uow, parentObjectsCount, childObjectsCount);
			}
			uow.commitWork();

			CBLogService.setLog('OTHER', 'Modeling Rule Generator for ' + modelingRule.Name, null, null);
			CBLogService.addLogDetail('Parent records', 'Number of new parent records: ' + parentObjectsCount, null);
			CBLogService.addLogDetail('Child records', 'Number of new child records: ' + childObjectsCount, null);
			CBLogService.insertLog();
		} catch(Exception e) {
			CBLogService.setLog(e, 'MW:UWD');
			CBLogService.insertLog();
			throw new CBException(e, 'MW:UWD');
		}

	}
	/////////// PUBLIC METHODS  ////////////


	/////////// PRIVATE METHODS ////////
	/**
	 * Method fills in collections of data needed to work with the wrapper
	 */
	private void initBaseCollections() {
		Boolean needChildRecords =
				(modelingRule.MultilevelSource__c && modelingRule.MultilevelResult__c) ||
						(modelingRule.MultilevelSource__c && type.equals('source')) ||
						(modelingRule.MultilevelResult__c && type.equals('result'));

		String parentSObjectType = type.equals('source') ? modelingRule.SourceRecordParentType__c : modelingRule.ResultRecordParentType__c;
		if (needChildRecords) {
			String childSObjectType = type.equals('source') ? modelingRule.SourceRecordChildType__c : modelingRule.ResultRecordChildType__c;
			relationChildParentName = CBUtils.getRelationName(parentSObjectType, childSObjectType); // 'cblight__CBAmounts__r'
			boundChildToParentFieldName = CBUtils.getLookupFieldName(parentSObjectType, childSObjectType); // 'cblight__CBAmount__c'
		}
		for (SObject parentRecord : parentRecords) {
			RecordCell newCell = new RecordCell();
			newCell.record = parentRecord;
			if (needChildRecords) {
				newCell.childRecords = parentRecord.getSObjects(relationChildParentName);
			}
			mainListOfRecords.add(newCell);
		}
	}

	/**
	 * The method allocates records to cellMapByKey (one key and several records)
	 */
	private void updateInternalMapping() {
		String key;
		for (RecordCell rc : mainListOfRecords) {
			cellMapById.put(rc.record.Id, rc);
			key = CBModelingRuleService.getKeyFieldValue(rc.record);
			List<RecordCell> tmp = cellMapByKey.get(key);
			if (tmp == null) {
				tmp = new List<RecordCell>();
				cellMapByKey.put(key, tmp);
			}
			tmp.add(rc);
		}
	}
	/////////// PRIVATE METHODS ////////

	public class RecordCell {
		public RecordCell() {
		}
		public RecordCell(SObject r) {
			this.record = r;
			this.childRecords = new List<SObject>();
		}
		public SObject record;
		public List<SObject> childRecords;
		public void boundChildRecordsWithParent(String boundChildToParentFieldName, fflib_SObjectUnitOfWork uow, Integer parentObjectsCount, Integer childObjectsCount) {
			parentObjectsCount++;
			uow.registerUpsert(this.record);
			if (this.childRecords == null) {
				this.childRecords = new List<SObject>();
			}
			for (SObject child : this.childRecords) {
				childObjectsCount++;
				Schema.SObjectType recordSobjType = child.getSObjectType();
				Schema.SObjectField sField = recordSobjType.getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap().get(boundChildToParentFieldName);
				if (child.Id == null) {
					uow.registerNew(child, sField, this.record);
				} else {
					uow.registerDirty(child, sField, this.record);
				}
			}
		}
	}


	public String getDebugInfo() {
		return parentRecords.toString();
	}


}