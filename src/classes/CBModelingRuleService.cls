/**
Created by Alex JR on 10/23/2021.
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

Service class for Modeling rules controllers
 */
public with sharing class CBModelingRuleService {

	private static final String NO_PERIOD = 'No required period line in the modeling rule';
	private static final String NO_TYPE = 'Object type is not specified for the modeling rule line: ';

	public CBModelingRuleService(CBModelingRule__c modelingRule) {
		this.modelingRule = modelingRule;
	}

	@TestVisible
	private CBModelingRule__c modelingRule;
	@TestVisible
	private List<CBModelingLine__c> modelingLines {
		get {
			if (modelingLines == null) {
				modelingLines = modelingRule.getSObjects('cblight__CBModelingLines__r');
				List<CBModelingLine__c> tmp = new List<CBModelingLine__c>();
				CBModelingLine__c p;
				for (CBModelingLine__c line : modelingLines) {
					if (CBModelingRuleMappingService.isSpecialLineFor(line, 'cblight__CBPeriod__c')) {
						p = line;
					} else {
						tmp.add(line);
					}
				}
				modelingLines.clear();
				if (p != null) modelingLines.add(p);
				modelingLines.addAll(tmp);
			}
			return modelingLines;
		}
		set;
	}


	/**
	 * Name of child records in SOQL request
	 * Example: Parent is cblight__CBBudgetLine__c and child is cblight__CBAmount__c.
	 * sourceRelationName should return "cblight__CBAmounts__r"
	 */
	@TestVisible
	private String sourceRelationName {
		get {
			if (!modelingRule.MultilevelSource__c) return null;
			if (sourceRelationName == null) {
				sourceRelationName = CBUtils.getRelationName(modelingRule.SourceRecordParentType__c, modelingRule.SourceRecordChildType__c);
			}
			return sourceRelationName;
		}
		set;
	}
	/**
	 * The same as sourceRelationName but for result records
	 */
	@TestVisible
	private String resultRelationName {
		get {
			if (!modelingRule.MultilevelResult__c) return null;
			if (resultRelationName == null) {
				resultRelationName = CBUtils.getRelationName(modelingRule.ResultRecordParentType__c, modelingRule.ResultRecordChildType__c);
			}
			return resultRelationName;
		}
		set;
	}

	/**
	 * @param sObjectType type of sObject like 'cblight__CBBudgetLine__c'
	 * @param filter some soql filter like ' Id = 'xxxxxxxx' '
	 *
	 * @return number of records in the database
	 */
	public static Integer getNumberOfRecords(String sObjectType, String filter) {
		String s = 'SELECT COUNT() FROM ' + sObjectType;
		String w = filter == null || filter.equals('') ? '' : ' WHERE ' + filter;
		return Database.countQuery(s + w);
	}

	public static String getSubQuery(String parentRecordType, String childRecordType) {
		String childQ = '';
		if (childRecordType != null) { // request children if needed
			String relationName = CBUtils.getRelationName(parentRecordType, childRecordType); // cblight__CBAmount__r
			childQ = CBUtils.getAllSObjectFields(childRecordType, null);
			childQ = '( SELECT ' + childQ.replace(childRecordType, relationName) + ')';
		}
		return childQ;
	}

	/////////// SOURCE SO RESULT CONVERTER //////////
	/**
	 * MAIN METHOD
	 * Method runs one of 4 cases to convert source data to result data records:
	 * - Single to Single
	 * - Single to Multi
	 * - Multi to Multi
	 * - Multi to Single
	 *
	 * @param sourceObjectsWrapper
	 * @param resultRecordsWrapper
	 */
	public void convertSourceToResultRecords(CBModelingWrapper sourceObjectsWrapper, CBModelingWrapper resultRecordsWrapper) {
		CBModelingRuleMappingService.modelingRule = modelingRule;
		for (CBModelingWrapper.RecordCell sourceCell : sourceObjectsWrapper.getAllRecordCells()) {
			if (modelingRule.MultilevelSource__c) { // Multi source
				if (modelingRule.MultilevelResult__c) { // to Multi result
					processMultilevelSourceAndMultilevelResult(sourceObjectsWrapper, resultRecordsWrapper, sourceCell);  // Multi source and multi result
				} else { // to Single result
					processMultilevelSourceAndSingleResult(sourceObjectsWrapper, resultRecordsWrapper, sourceCell);      // Multi source and single result
				}
			} else { // Single source
				if (modelingRule.MultilevelResult__c) { // to Multi result
					processSingleLevelSourceAndMultilevelResult(sourceObjectsWrapper, resultRecordsWrapper, sourceCell); // Single source and multi result
				} else { // to Single result
					processSingleLevelSourceAndSingleResult(sourceObjectsWrapper, resultRecordsWrapper, sourceCell);     // Single source and single result
				}
			}
		}
	}

	/**
	 * @return value from the CBKey__c field
	 */
	public static String getKeyFieldValue(SObject record) {
		return (String) record.get('CBKey__c');
	}
	public static void setKeyFieldValue(SObject record, String key) {
		record.put('CBKey__c', key);
	}

	/**
	 * MULTI TO MULTI
	 * Manage one source record per method
	 * @param sourceObjectsWrapper
	 * @param resultRecordsWrapper
	 * @param sourceRecord
	 */
	private void processMultilevelSourceAndMultilevelResult(CBModelingWrapper sourceObjectsWrapper, CBModelingWrapper resultRecordsWrapper, CBModelingWrapper.RecordCell sourceCell) {
		String sField, rField, fieldType, key = CBModelingRuleService.getKeyFieldValue(sourceCell.record); // source field, result field
		Object sourceValue, sourcePeriodValue;
		CBModelingWrapper.RecordCell resultCell;

		// found result record
		List<CBModelingWrapper.RecordCell> resultCells = resultRecordsWrapper.getRecordCellsByKey(key);
		if (resultCells != null && resultCells.size() > 0) {
			resultCell = resultCells[0];
		} else {
			Type type = Type.forName(modelingRule.ResultRecordParentType__c);
			SObject resultParentRecord = (SObject) type.newInstance();
			setKeyFieldValue(resultParentRecord, key);
			resultCell = new CBModelingWrapper.RecordCell(resultParentRecord);
			resultRecordsWrapper.addNewCell(resultCell);
		}
		if (modelingRule.StoreDrillDown__c) {
			storeDrillDown(sourceCell.record.Id, resultCell.record);
		}
		// update parent records
		for (CBModelingLine__c ml : modelingLines) {
			if (ml.SourceFieldFrom__c.equals('Child')) continue;
			sourceValue = CBUtils.getField(sourceCell.record, ml.SourceField__c); // source value
			sourceValue = mapCrossPackageFields(ml, sourceValue);
			if (!String.isEmpty(ml.Default__c)) {
				if (ml.SpecifyDefault__c) {
					sourceValue = sourceValue == null ?  ml.Default__c : sourceValue;
				} else {
					sourceValue = ml.Default__c;
				}
			}
			if (sourceValue != null) {
				CBUtils.putField(resultCell.record, ml.ResultField__c, sourceValue);
			}
		}

		// update child records
		CBModelingLine__c periodModelingLine = CBModelingRuleMappingService.periodModelingLine;
		String sourceRecordType = periodModelingLine.cblight__SourceFieldFrom__c == 'Parent' ? modelingRule.cblight__SourceRecordParentType__c : modelingRule.cblight__SourceRecordChildType__c;
		String resultRecordType = periodModelingLine.cblight__ResultFieldFrom__c == 'Parent' ? modelingRule.cblight__ResultRecordParentType__c : modelingRule.cblight__ResultRecordChildType__c;
		String periodSourceFieldType = CBModelingRuleMappingService.returnObjectFiledType(sourceRecordType, periodModelingLine.SourceField__c);
		String periodResultFieldType = CBModelingRuleMappingService.returnObjectFiledType(resultRecordType, periodModelingLine.ResultField__c);

		if (sourceCell.childRecords != null) {
			for (SObject sourceChild : sourceCell.childRecords) {
				sourcePeriodValue = CBUtils.getField(sourceChild, periodModelingLine.SourceField__c); // period Id or Date of child record
				String sourcePeriodId = CBModelingRuleMappingService.getPeriodOrDateFromSource(periodSourceFieldType, periodResultFieldType, sourcePeriodValue);
				SObject resultChild = findSobjectByPeriodId(resultCell.childRecords, periodModelingLine.ResultField__c, sourcePeriodId);
				if (resultChild == null) {
					Type type = Type.forName(modelingRule.ResultRecordChildType__c);
					resultChild = (SObject) type.newInstance();
					resultCell.childRecords.add(resultChild);
				}
				for (CBModelingLine__c ml : modelingLines) {
					if (ml.SourceFieldFrom__c.equals('Parent')) continue;  // child to child only
					sField = ml.SourceField__c; // child field name from source
					rField = ml.ResultField__c;// child field name from result
					sourceValue = CBUtils.getField(sourceChild, sField); // source value
					sourceValue = getSourceValueByMLType(periodSourceFieldType, periodResultFieldType, sourcePeriodId, ml, periodModelingLine, sourceValue);
					if (!String.isEmpty(ml.Default__c)) {
						if (ml.SpecifyDefault__c) {
							sourceValue = sourceValue == null ?  ml.Default__c : sourceValue;
						} else {
							sourceValue = ml.Default__c;
						}
					}
					if (typeIsNumber(ml)) {
						sourceValue = sumDecimals(resultChild, sField, rField, sourceValue);
					}
					if (sourceValue != null) {
						CBUtils.putField(resultChild, rField, sourceValue); // put source value to result
					}
				}
			}
		}

	}

	/**
	 * MULTI TO SINGLE
	 * Manage one source record per method 
	 * @param sourceObjectsWrapper
	 * @param resultRecordsWrapper
	 * @param sourceRecord
	 */
	private void processMultilevelSourceAndSingleResult(CBModelingWrapper sourceObjectsWrapper, CBModelingWrapper resultRecordsWrapper, CBModelingWrapper.RecordCell sourceCell) {
		String sField, rField, fieldType, sourcePeriodId, key = CBModelingRuleService.getKeyFieldValue(sourceCell.record); // source field, result field
		SObject sourceSobject;
		Object sourceValue, sourcePeriodValue;
		CBModelingWrapper.RecordCell resultCell;
		CBModelingLine__c periodModelingLine = CBModelingRuleMappingService.periodModelingLine;
		if (periodModelingLine == null) throw new CBException(null, NO_PERIOD);
		String sourceRecordType = periodModelingLine.cblight__SourceFieldFrom__c == 'Parent' ? modelingRule.cblight__SourceRecordParentType__c : modelingRule.cblight__SourceRecordChildType__c;
		String periodSourceFieldType = CBModelingRuleMappingService.returnObjectFiledType(sourceRecordType, periodModelingLine.SourceField__c);
		String periodResultFieldType = CBModelingRuleMappingService.returnObjectFiledType(modelingRule.cblight__ResultRecordParentType__c, periodModelingLine.ResultField__c);

		// update result records
		List<CBModelingWrapper.RecordCell> resultCells = resultRecordsWrapper.getRecordCellsByKey(key); // list of result cells if exist
		if (resultCells == null) {
			resultCells = new List<CBModelingWrapper.RecordCell>();
		}
		if (sourceCell.childRecords == null) {
			sourcePeriodValue = CBUtils.getField(sourceCell.record, periodModelingLine.SourceField__c);
			if (sourcePeriodValue == null) throw new CBException(null, NO_PERIOD);
			sourcePeriodId = CBModelingRuleMappingService.getPeriodOrDateFromSource(periodSourceFieldType, periodResultFieldType, sourcePeriodValue);
			List<SObject> resultSobjects = resultRecordsWrapper.getOnlyParentSobjects(resultCells);
			SObject resultSobject = findSobjectByPeriodId(resultSobjects, periodModelingLine.ResultField__c, sourcePeriodId);
			if (resultSobject == null) {
				Type type = Type.forName(modelingRule.ResultRecordParentType__c);
				SObject resultRecord = (SObject) type.newInstance();
				setKeyFieldValue(resultRecord, key);
				resultCell = new CBModelingWrapper.RecordCell(resultRecord);
				resultRecordsWrapper.addNewCell(resultCell);
				resultSobject = resultCell.record;
			}

			if (modelingRule.StoreDrillDown__c) {
				storeDrillDown(sourceCell.record.Id, resultSobject);
			}
			for (CBModelingLine__c ml : modelingLines) {
				sourceValue = CBUtils.getField(sourceCell.record, ml.SourceField__c); // source value
				sourceValue = getSourceValueByMLType(periodSourceFieldType, periodResultFieldType, sourcePeriodId, ml, periodModelingLine, sourceValue);			
				if (!String.isEmpty(ml.Default__c)) {
					if (ml.SpecifyDefault__c) {
						sourceValue = sourceValue == null ?  ml.Default__c : sourceValue;
					} else {
						sourceValue = ml.Default__c;
					}
				}
				rField = ml.ResultField__c;
				if (typeIsNumber(ml)) {
					sourceValue = sumDecimals(resultSobject, sField, rField, sourceValue);
				}
				if (sourceValue != null) {
					CBUtils.putField(resultSobject, rField, sourceValue); // put source value to result
				}
			}
		}
		if (sourceCell.childRecords != null) {
			for (SObject sourceChild : sourceCell.childRecords) { //Each source child record creates or updates a separate result record
				sourcePeriodValue = CBUtils.getField(sourceChild, periodModelingLine.SourceField__c); // period Id or Date of child record
				sourcePeriodId = CBModelingRuleMappingService.getPeriodOrDateFromSource(periodSourceFieldType, periodResultFieldType, sourcePeriodValue);
				List<SObject> resultSobjects = resultRecordsWrapper.getOnlyParentSobjects(resultCells);
				SObject resultSobject = findSobjectByPeriodId(resultSobjects, periodModelingLine.ResultField__c, sourcePeriodId);
				if (resultSobject == null) {
					Type type = Type.forName(modelingRule.ResultRecordParentType__c);
					SObject resultRecord = (SObject) type.newInstance();
					setKeyFieldValue(resultRecord, key);
					resultCell = new CBModelingWrapper.RecordCell(resultRecord);
					resultRecordsWrapper.addNewCell(resultCell);
					resultSobject = resultCell.record;
				}
				if (modelingRule.StoreDrillDown__c) {
					storeDrillDown(sourceChild.Id, resultSobject);
				}
				for (CBModelingLine__c ml : modelingLines) {
					sourceSobject = ml.cblight__SourceFieldFrom__c == 'Parent' ? sourceCell.record : sourceChild;
					sourceValue = CBUtils.getField(sourceSobject, ml.SourceField__c); // source value
					sourceValue = getSourceValueByMLType(periodSourceFieldType, periodResultFieldType, sourcePeriodId, ml, periodModelingLine, sourceValue);
					if (!String.isEmpty(ml.Default__c)) {
						if (ml.SpecifyDefault__c) {
							sourceValue = sourceValue == null ?  ml.Default__c : sourceValue;
						} else {
							sourceValue = ml.Default__c;
						}
					}
					rField = ml.ResultField__c;
					if (typeIsNumber(ml)) {
						sourceValue = sumDecimals(resultSobject, sField, rField, sourceValue);
					}
					if (sourceValue != null) {
						CBUtils.putField(resultSobject, rField, sourceValue); // put source value to result
					}
				}
			}
		}
	}

		/**
	 * SINGLE TO SINGLE
	 * Manage one source record per method
	 * @param sourceObjectsWrapper
	 * @param resultRecordsWrapper
	 * @param sourceRecord
	 */
	private void processSingleLevelSourceAndSingleResult(CBModelingWrapper sourceObjectsWrapper, CBModelingWrapper resultRecordsWrapper, CBModelingWrapper.RecordCell sourceCell) {
		try {
			////**********************************************************************************************************************////////
			String sField, rField, fieldType, sourcePeriodId, key = CBModelingRuleService.getKeyFieldValue(sourceCell.record); // source field, result field
			SObject sourceSobject = sourceCell.record;
			Object sourceValue, sourcePeriodValue;
			CBModelingWrapper.RecordCell resultCell;
			CBModelingLine__c periodModelingLine = CBModelingRuleMappingService.periodModelingLine;
			if (periodModelingLine == null) {
				throw new CBException(null, NO_PERIOD); // Period mapping is required
			}
			String periodSourceFieldType = CBModelingRuleMappingService.returnObjectFiledType(modelingRule.cblight__SourceRecordParentType__c, periodModelingLine.SourceField__c);
			String periodResultFieldType = CBModelingRuleMappingService.returnObjectFiledType(modelingRule.cblight__ResultRecordParentType__c, periodModelingLine.ResultField__c);

			////**********************************************************************************************************************////////

			// update result records
			List<CBModelingWrapper.RecordCell> resultCells = resultRecordsWrapper.getRecordCellsByKey(key); // list of result cells if exist
			if (resultCells == null) {
				resultCells = new List<CBModelingWrapper.RecordCell>();
			}
			////**********************************************************************************************************************////////

			sourcePeriodValue = CBUtils.getField(sourceSobject, periodModelingLine.SourceField__c); // period Id or Date of child record
			sourcePeriodId = CBModelingRuleMappingService.getPeriodOrDateFromSource(periodSourceFieldType, periodResultFieldType, sourcePeriodValue);
			List<SObject> resultSobjects = resultRecordsWrapper.getOnlyParentSobjects(resultCells);
			SObject resultSobject = findSobjectByPeriodId(resultSobjects, periodModelingLine.ResultField__c, sourcePeriodId); // attempt to find existing record object

			if (resultSobject == null) { // if record was not found, create a new one
				Type type = Type.forName(modelingRule.ResultRecordParentType__c);
				SObject resultRecord = (SObject) type.newInstance();
				setKeyFieldValue(resultRecord, key);
				resultCell = new CBModelingWrapper.RecordCell(resultRecord);
				resultRecordsWrapper.addNewCell(resultCell);
				resultSobject = resultCell.record;
			}
			if (modelingRule.StoreDrillDown__c) {
				storeDrillDown(sourceSobject.Id, resultSobject);
			}
			////**********************************************************************************************************************////////
			for (CBModelingLine__c ml : modelingLines) { // iteration over modeling rule mapping lines
				sourceValue = CBUtils.getField(sourceSobject, ml.SourceField__c); // source value
					sourceValue = getSourceValueByMLType(periodSourceFieldType, periodResultFieldType, sourcePeriodId, ml, periodModelingLine, sourceValue);
				if (!String.isEmpty(ml.Default__c)) {
					if (ml.SpecifyDefault__c) {
						sourceValue = sourceValue == null ?  ml.Default__c : sourceValue;
					} else {
						sourceValue = ml.Default__c;
					}
				}
				rField = ml.ResultField__c;

				////**********************************************************************************************************************////////
				if (typeIsNumber(ml)) {
					sourceValue = sumDecimals(resultSobject, sField, rField, sourceValue);
				}
				if (sourceValue != null) {
					CBUtils.putField(resultSobject, rField, sourceValue); // put source value to result
				}
			}
			////**********************************************************************************************************************////////
		} catch (Exception e) {
			throw new CBException(e, 'MRS->STS');
		}
	}

	/**
	 * SINGLE TO MULTI
	 *
	 * @param sourceObjectsWrapper
	 * @param resultRecordsWrapper
	 * @param sourceCell
	 */
	private void processSingleLevelSourceAndMultilevelResult(CBModelingWrapper sourceObjectsWrapper, CBModelingWrapper resultRecordsWrapper, CBModelingWrapper.RecordCell sourceCell) {
		String sField, rField, sourcePeriodId, key = CBModelingRuleService.getKeyFieldValue(sourceCell.record); // source field, result field
		Object sourceValue, sourcePeriodValue;
		CBModelingWrapper.RecordCell resultCell;
		CBModelingLine__c periodModelingLine = CBModelingRuleMappingService.periodModelingLine;
		if (periodModelingLine == null) throw new CBException(null, NO_PERIOD);
		String periodSourceFieldType = CBModelingRuleMappingService.returnObjectFiledType(modelingRule.cblight__SourceRecordParentType__c, periodModelingLine.SourceField__c);
		String resultRecordType = periodModelingLine.cblight__ResultFieldFrom__c == 'Parent' ? modelingRule.cblight__ResultRecordParentType__c : modelingRule.cblight__ResultRecordChildType__c;
		String periodResultFieldType = CBModelingRuleMappingService.returnObjectFiledType(resultRecordType, periodModelingLine.ResultField__c);
		sourcePeriodValue = CBUtils.getField(sourceCell.record, periodModelingLine.SourceField__c); // period Id of child record
		sourcePeriodId = CBModelingRuleMappingService.getPeriodOrDateFromSource(periodSourceFieldType, periodResultFieldType, sourcePeriodValue);

		// attempt to find result records
		List<CBModelingWrapper.RecordCell> resultCells = resultRecordsWrapper.getRecordCellsByKey(key); // list of result cells if existing. In case of multi level result - one key for one record
		if (resultCells != null && resultCells.size() > 0) {
			resultCell = resultCells[0];
			if (resultCell.childRecords == null) {
				resultCell.childRecords = new List<SObject>();
			}
		} else {
			Type type = Type.forName(modelingRule.ResultRecordParentType__c);
			SObject resultParentRecord = (SObject) type.newInstance(); // create a new sObject of result record
			setKeyFieldValue(resultParentRecord, key); // populate CBKey__c
			resultCell = new CBModelingWrapper.RecordCell(resultParentRecord); // create and set a new place in CBModelingWrapper for the result record
			resultRecordsWrapper.addNewCell(resultCell);
		}

		if (modelingRule.StoreDrillDown__c) {
			storeDrillDown(sourceCell.record.Id, resultCell.record);
		}

		// update result records
		for (CBModelingLine__c ml : modelingLines) { // iterate over the modeling rule lines with mapping
			sField = ml.SourceField__c; // child field name from source
			rField = ml.ResultField__c;// child field name from result
			sourceValue = CBUtils.getField(sourceCell.record, sField); // source value
			sourceValue = getSourceValueByMLType(periodSourceFieldType, periodResultFieldType, sourcePeriodId, ml, periodModelingLine, sourceValue);
			if (!String.isEmpty(ml.Default__c)) {
				if (ml.SpecifyDefault__c) {
					sourceValue = sourceValue == null ?  ml.Default__c : sourceValue;
				} else {
					sourceValue = ml.Default__c;
				}
			}
			if (ml.ResultFieldFrom__c.equals('Parent')) { // update parent
				if (sourceValue != null) {
					CBUtils.putField(resultCell.record, rField, sourceValue);
				}
			} else { // update child
				SObject resultChild = findSobjectByPeriodId(resultCell.childRecords, periodModelingLine.ResultField__c, sourcePeriodId);
				if (resultChild == null) {
					Type type = Type.forName(modelingRule.ResultRecordChildType__c);
					resultChild = (SObject) type.newInstance();
					resultCell.childRecords.add(resultChild);
				}

				if (typeIsNumber(ml)) {
					sourceValue = sumDecimals(resultChild, sField, rField, sourceValue);
				}
				if (sourceValue != null) {
					CBUtils.putField(resultChild, rField, sourceValue); // put source value to result
				}
			}
		}
	}


	/**
	 * Method changes type of value depends of modeling line
	 *
	 * @param periodSourceFieldType, periodResultFieldType source period field type
	 * @param periodResultFieldType, periodResultFieldType source period field type
	 * @param ml,periodModelingLine - current and period modeling lines
	 * @param sourceValue - initial source value
	 */
	private Object getSourceValueByMLType(String periodSourceFieldType, String periodResultFieldType, String sourcePeriodId, CBModelingLine__c ml, CBModelingLine__c periodModelingLine, Object sourceValue) {
		if (ml == periodModelingLine) {
			if (periodSourceFieldType == 'DATE') return sourcePeriodId;
			if (periodResultFieldType == 'DATE') return Date.valueof(sourcePeriodId);
		}
		return mapCrossPackageFields(ml, sourceValue);
	}

	/**
	 * Method shifts periods in each record for specified number of months
	 *
	 * @param resultRecordList newly generated records
	 * @param shiftedPeriodsMap map where key is old period, and result is new shifted period
	 */
	public void shiftResultPeriods(List<SObject> resultRecordList, Map<String, String> shiftedPeriodsMap) {
		System.debug(resultRecordList);
		System.debug(shiftedPeriodsMap);
		for (SObject obj : resultRecordList) {
			String periodId = (String) obj.get('cblight__CBPeriod__c');
			String shiftedPeriodId = shiftedPeriodsMap.get(periodId);
			if (shiftedPeriodId == null) continue;
			try {
				obj.put('cblight__CBPeriod__c', shiftedPeriodId);
			} catch (Exception e) {
				throw new CBException(e, 'Shift Period ID : ' + periodId + ' Shifted period ID: ' + shiftedPeriodId);
			}
		}

	}

	/////////// SOURCE SO RESULT CONVERTER //////////

	/////////// PRIVATE METHODS ////////////////
	/**
	 * The method returns updated sourceValue after mapping
	 *
	 * @param mrLineName modeling rule line name can be magic like Account or Division
	 * @param sourceValue base lookup value
	 *
	 * @return
	 */
	private Object mapCrossPackageFields(CBModelingLine__c mrLine, Object sourceValue) {
		try {
			if (!String.isBlank(mrLine.Type__c) && mrLine.Type__c.equals('REFERENCE')) {
				String specialType = getMRLSpecialType(mrLine);
				if (specialType == null) return sourceValue;
				Map<String, String> analyticMap = CBModelingRuleMappingService.specialCrossPackageFieldsMap.get(specialType);
				if (analyticMap != null && analyticMap.size() > 0) {
					return analyticMap.get((String) sourceValue);
				}
			}
			return sourceValue;
		} catch (Exception e) {
			throw new CBException(e, 'MRS->MCPF');
		}
	}

	/**
	 * @param mrl modeling rule line
	 *
	 * @return Example: method returns "cblight__CBAccount__c" if source or result field is special type like cblight__CBAccount__c
	 */
	public static String getMRLSpecialType(CBModelingLine__c mrl) {
		if (CBModelingRuleMappingService.SPECIAL_TYPES.contains(mrl.SourceField__c)) return mrl.SourceField__c;
		if (CBModelingRuleMappingService.SPECIAL_TYPES.contains(mrl.ResultField__c)) return mrl.ResultField__c;
		return null;
	}
	/**
	 * The method sum up existing values with a new value
	 *
	 * @param resultChild existing SObject with some value
	 * @param sField field with the value in the source SObject
	 * @param rField field with the value in the source SObject
	 * @param newValue new value
	 *
	 * @return summed value
	 */
	@TestVisible
	private static Object sumDecimals(sObject resultChild, String sField, String rField, Object newValue) {
		Object oldValue = CBUtils.getField(resultChild, rField);
		if (oldValue != null && newValue != null) {
			return (Decimal) oldValue + (Decimal) newValue;
		}
		return newValue;
	}
	/**
	 * The method finds the record with needed period in specified field
	 *
	 * @param sObjects the base SObject
	 * @param periodFieldName the field where period stored
	 * @param periodValue period Id
	 *
	 * @return searched sObject with desired period or NULL if nothing has been found
	 */
	private static SObject findSobjectByPeriodId(List<SObject> sObjects, String periodFieldName, String periodValue) {
		try {
			for (SObject obj : sObjects) {
				if (CBUtils.getField(obj, periodFieldName) == periodValue) {
					return obj;
				}
			}
			return null;
		} catch (Exception e) {
			throw new CBException(e, 'MRS->SBP');
		}
	}

	private static final String DD_FIELD = 'cblight__DrillDownIds__c';
	/**
	 * Method collects Ids in a result record
	 *
	 * @param sourceId
	 * @param resultObject
	 */
	private static void storeDrillDown(String sourceId, SObject resultObject) {
		try {
			String ddIdsString = (String) resultObject.get(DD_FIELD);
			Set<String> ddIdsSet = String.isEmpty(ddIdsString) ? new Set<String>() : new Set<String>(ddIdsString.split(','));
			ddIdsSet.add(sourceId);
			resultObject.put(DD_FIELD, String.join(new List<String>(ddIdsSet), ','));
		} catch (Exception e) {

		}
	}

	/**
	 * @param type of modeling rule data
	 * @return true if type is number
	 */
	private Boolean typeIsNumber(cblight__CBModelingLine__c ml) {
		String type = ml.Type__c;
		if (type == null) throw new CBException(null, NO_TYPE + ml.Name);
		return type.equals('DOUBLE') || type.equals('CURRENCY') || type.equals('INTEGER');
	}

	/*
	ADDRESS,
    ANYTYPE,
    BASE64,
    BOOLEAN,
    COMBOBOX,
    COMPLEXVALUE,
    CURRENCY,
    DATACATEGORYGROUPREFERENCE,
    DATE,
    DATETIME,
    DOUBLE,
    EMAIL,
    ENCRYPTEDSTRING,
    ID,
    INTEGER,
    JSON,
    LOCATION,
    LONG,
    MULTIPICKLIST,
    PERCENT,
    PHONE,
    PICKLIST,
    REFERENCE,
    SOBJECT,
    STRING,
    TEXTAREA,
    TIME,
    URL
	 */
	/////////// PRIVATE METHODS ////////////////

}