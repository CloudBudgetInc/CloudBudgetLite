/**
 * Copyright (c) 2021, CloudBudget, Inc.
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
 **/
public with sharing class CBModelingLineService {
	private static final List<String> MAPPING_TYPES = new List<String>{
		'accounts',
		'divisions',
		'periods',
		'variables1',
		'variables2',
		'variables3',
		'variables4',
		'variables5'
	};
	/**
	 * returns map of maps of reference field names by sobject name of selected in MR sobject and from sobject this field is related
	 * @param mr - modeling rule with selected fields
	 */
	private static Map<String, Map<String, CBSO>> getFullFieldMap(CBModelingRule__c mr) {
		Map<String, Map<String, CBSO>> fullFieldMap = new Map<String, Map<String, CBSO>>();
		Map<String, List<CBSO>> fieldMap = CBModelingRulePageController.getSourceParentAndChildSObjectFieldsServer(mr.Id);
		Map<String, String> mrSobjectNameMap = new Map<String, String>();
		mrSobjectNameMap.put('sourceParentFieldSO', mr.SourceRecordParentType__c);
		mrSobjectNameMap.put('sourceChildFieldSO', mr.SourceRecordChildType__c);
		mrSobjectNameMap.put('resultParentFieldSO', mr.ResultRecordParentType__c);
		mrSobjectNameMap.put('resultChildFieldSO', mr.ResultRecordChildType__c);
		for (String mapKey : mrSobjectNameMap.keySet()) {
			processSOToMap(mapKey, mrSobjectNameMap.get(mapKey), fieldMap, fullFieldMap);
		}
		return fullFieldMap;
	}
	/**
	 * fills map with the details of field options
	 * @param srpcDetail - source/result/parent/child details
	 * @param sobjectName - name of the sobject from related field
	 * @param fullFieldMap - map of references to fill
	 */
	private static void processSOToMap(String srpcDetail, String sobjectName, Map<String, List<CBSO>> fieldMap, Map<String, Map<String, CBSO>> fullFieldMap) {
		if (sobjectName != null) {
			List<CBSO> fieldSOList = fieldMap.get(srpcDetail);
			Map<String, CBSO> soMap = new Map<String, CBSO>();
			for (CBSO f : fieldSOList) {
				if (f.detail != null) {
					soMap.put(f.detail, f);
				}
			}
			fullFieldMap.put(srpcDetail, soMap);
		}
	}
	/**
	 * creates lines for objects  that are looking up for the same sobjects
	 * 
	 */
	private static void createDirectlyRelatedLines(List<CBModelingLine__c> mlList, CBModelingRule__c mr, Map<String, Map<String, CBSO>> fullFieldMap) {
		Map<String, CBSO> sourceParentSoMap = fullFieldMap.get('sourceParentFieldSO');
		Map<String, CBSO> sourceChildSoMap = fullFieldMap.get('sourceChildFieldSO');
		Map<String, CBSO> resultParentSoMap = fullFieldMap.get('resultParentFieldSO');
		Map<String, CBSO> resultChildSoMap = fullFieldMap.get('resultChildFieldSO');
		if (sourceParentSoMap != null) {
			for (String key : sourceParentSoMap.keySet()) {
				CBSO sourceSO = sourceParentSoMap.get(key);
				if (resultParentSoMap != null) {
					CBSO resultSO = resultParentSoMap.get(key);
					if (resultSO != null) {
						mlList.add(addNewReferenceModelingLine(sourceSO.label, mr.Id, sourceSO.value, resultSO.value, true, true, 'REFERENCE'));
					}
					resultParentSoMap.put(key, null);//To avoid duplicating lines for parent and child source
				}
				if (resultChildSoMap != null) {
					CBSO resultSO = resultChildSoMap.get(key);
					if (resultSO != null) {
						mlList.add(addNewReferenceModelingLine(sourceSO.label, mr.Id, sourceSO.value, resultSO.value, true, false, 'REFERENCE'));
					}
					resultChildSoMap.put(key, null);//To avoid duplicating lines for parent and child source
				}
			}
		}
		if (sourceChildSoMap != null) {
			for (String key : sourceChildSoMap.keySet()) {
				CBSO sourceSO = sourceChildSoMap.get(key);
				if (resultParentSoMap != null) {
					CBSO resultSO = resultParentSoMap.get(key);
					if (resultSO != null) {
						mlList.add(addNewReferenceModelingLine(sourceSO.label, mr.Id, sourceSO.value, resultSO.value, false, true, 'REFERENCE'));
					}
				}
				if (resultChildSoMap != null) {
					CBSO resultSO = resultChildSoMap.get(key);
					if (resultSO != null) {
						mlList.add(addNewReferenceModelingLine(sourceSO.label, mr.Id, sourceSO.value, resultSO.value, false, false, 'REFERENCE'));
					}
				}
			}
		}
	}
	/**
	 * this method processes mapping into modeling lines
	 * @param mlList - list of modeling lines to fill
	 * @param mapping - mapping record to process
	 */
	private static void processMappingToModelingLines(
		Map<String, Map<String, CBSO>> fullFieldMap,
		List<CBModelingLine__c> mlList,
		CBMapping__c mapping,
		CBModelingRule__c mr
	) {
		if (mapping != null) {
			String sourceObj = mapping.SourceSObject__c;
			String resultObj = mapping.ResultSObject__c;
			Map<String, CBSO> sourceParentSoMap = fullFieldMap.get('sourceParentFieldSO');
			Map<String, CBSO> sourceChildSoMap = fullFieldMap.get('sourceChildFieldSO');
			Map<String, CBSO> resultParentSoMap = fullFieldMap.get('resultParentFieldSO');
			Map<String, CBSO> resultChildSoMap = fullFieldMap.get('resultChildFieldSO');
			CBSO sourceParentFieldSO;
			CBSO sourceChildFieldSO;
			CBSO resultParentFieldSO;
			CBSO resultChildFieldSO;
			if (sourceObj != null) {
				if (sourceParentSoMap != null) {
					sourceParentFieldSO = sourceParentSoMap.get(sourceObj);
				}
				if (sourceChildSoMap != null) {
					sourceChildFieldSO = sourceChildSoMap.get(sourceObj);
				}
			}
			if (resultObj != null) {
				if (resultParentSoMap != null) {
					resultParentFieldSO = resultParentSoMap.get(resultObj);
				}
				if (resultChildSoMap != null) {
					resultChildFieldSO = resultChildSoMap.get(resultObj);
				}
			}
			if (sourceParentFieldSO != null) {
				if (resultParentFieldSO != null) {
					mlList.add(addNewReferenceModelingLine(sourceParentFieldSO.label, mr.Id, sourceParentFieldSO.value, resultParentFieldSO.value, true, true, 'REFERENCE'));
				} else if (resultChildFieldSO != null) {
					mlList.add(addNewReferenceModelingLine(sourceParentFieldSO.label, mr.Id, sourceParentFieldSO.value, resultChildFieldSO.value, true, false, 'REFERENCE'));
				}
			} else if (sourceChildFieldSO != null) {
				if (resultParentFieldSO != null) {
					mlList.add(addNewReferenceModelingLine(sourceChildFieldSO.label, mr.Id, sourceChildFieldSO.value, resultParentFieldSO.value, false, true, 'REFERENCE'));
				} else if (resultChildFieldSO != null) {
					mlList.add(addNewReferenceModelingLine(sourceChildFieldSO.label, mr.Id, sourceChildFieldSO.value, resultChildFieldSO.value, false, false, 'REFERENCE'));
				}
			}
		}
	}
	/**
	 * adds new modeling line
	 * @param name - name
	 * @param mrId - mr Id
	 * @param sourceField - Source Field value
	 * @param resultField - Result Field value
	 * @param parentSourceFrom - Parent Source From if true - Parent, else - Child
	 * @param parentResultFrom - Parent Result From if true - Parent, else - Child
	 */
	private static CBModelingLine__c addNewReferenceModelingLine(
		String name,
		String mrId,
		String sourceField,
		String resultField,
		Boolean parentSourceFrom,
		Boolean parentResultFrom,
		String type
	) {
		return new CBModelingLine__c(
			Name = name,
			CBModelingRule__c = mrId,
			SourceField__c = sourceField,
			ResultField__c = resultField,
			SourceFieldFrom__c = parentSourceFrom ? 'Parent' : 'Child',
			ResultFieldFrom__c = parentResultFrom ? 'Parent' : 'Child',
			Type__c = type
		);
	}
	/**
	 * creates pre-defined modeling lines of specific modeling rule based on the mapping
	 * @param modelingRuleId - modeling rule id
	 */
	public static void createPredefinedModelingLines(String modelingRuleId) {
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{ CBModelingLine__c.SObjectType });
		List<CBModelingLine__c> mlList = new List<CBModelingLine__c>();
		CBModelingRule__c mr = new CBModelingRuleSelector().getModelingRuleById(modelingRuleId);
		Map<String, Map<String, CBSO>> fullFieldMap = getFullFieldMap(mr);
		createDirectlyRelatedLines(mlList, mr, fullFieldMap);
		List<CBMapping__c> mappingList = new CBMappingSelector().getMappingRecords(null);
		Map<String, CBMapping__c> mappingMap = new Map<String, CBMapping__c>();
		for (CBMapping__c m : mappingList) {
			mappingMap.put(m.Type__c, m);
		}
		for (String mappingType : MAPPING_TYPES) {
			CBMapping__c mapping = mappingMap.get(mappingType);
			processMappingToModelingLines(fullFieldMap, mlList, mapping, mr);
		}
		mlList = validateNewLines(mr, mlList);
		uow.registerNew(mlList);
		uow.commitWork();
	}
	/**
	 * validates new lines
	 * @param mr - modeling rule with old lines to check
	 * @param mlList - list of new modeling lines
	 */
	private static List<CBModelingLine__c> validateNewLines(CBModelingRule__c mr, List<CBModelingLine__c> mlList) {
		List<CBModelingLine__c> resultList = new List<CBModelingLine__c>();
		List<CBModelingLine__c> existingLines = mr.cblight__CBModelingLines__r;
		Map<String, CBModelingLine__c> existingLinesMap = new Map<String, CBModelingLine__c>();
		for (CBModelingLine__c existingLine : existingLines) {
			String sourceKey = existingLine.SourceFieldFrom__c + existingLine.SourceField__c;
			existingLinesMap.put(sourceKey, existingLine);
		}
		for (CBModelingLine__c newLine : mlList) {
			String sourceKey = newLine.SourceFieldFrom__c + newLine.SourceField__c;
			if (existingLinesMap.get(sourceKey) == null) {
				resultList.add(newLine);
			}
		}
		return resultList;
	}


}