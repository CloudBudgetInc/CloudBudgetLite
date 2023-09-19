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
public with sharing class CBModelingRuleMappingService {

	public static CBModelingRule__c modelingRule;

	/**
	 * Special field names that allows to make mapping
	 */
	public static final List<String> SPECIAL_TYPES = new List<String>{
			'cblight__CBAccount__c', 'cblight__CBPeriod__c', 'cblight__CBBudgetYear__c', 'cblight__CBDivision__c',
			'cblight__CBVariable1__c', 'cblight__CBVariable2__c', 'cblight__CBVariable3__c', 'cblight__CBVariable4__c', 'cblight__CBVariable5__c'
	};

	/**
	 * Full map of periods in CB Base
	 */
	public static Map <Id, cblight__CBPeriod__c> periodMap {
		get {
			if (periodMap == null) {

				Map<Id, cblight__CBPeriod__c> periods = new Map<Id, cblight__CBPeriod__c>([SELECT Id,cblight__Start__c,cblight__End__c From cblight__CBPeriod__c WITH SECURITY_ENFORCED LIMIT 10000]);
				periodMap = periods;
			}
			return periodMap;
		}
		set;
	}


	/**
	 * Special modeling line for moving period lines.
	 * In order to do not search this each iteration we should have quick access to this record
	 * Searching over all modeling rule lines regardless parent or child
	 */
	public static CBModelingLine__c periodModelingLine {
		get {
			if (periodModelingLine == null) {
				for (CBModelingLine__c line : modelingRule.CBModelingLines__r) {
					if (isSpecialLineFor(line, 'cblight__CBPeriod__c')) {
						periodModelingLine = line;
						break;
					}
				}
			}
			return periodModelingLine;
		}
		set;
	}

	public static CBModelingLine__c accountModelingLine {
		get {
			if (accountModelingLine == null) {
				for (CBModelingLine__c line : modelingRule.CBModelingLines__r) {
					if (isSpecialLineFor(line, 'cblight__CBAccount__c')) {
						accountModelingLine = line;
						break;
					}
				}
			}
			return accountModelingLine;
		}
		set;
	}

	public static CBModelingLine__c divisionModelingLine {
		get {
			if (divisionModelingLine == null) {
				for (CBModelingLine__c line : modelingRule.CBModelingLines__r) {
					if (isSpecialLineFor(line, 'cblight__CBDivision__c')) {
						divisionModelingLine = line;
						break;
					}
				}
			}
			return divisionModelingLine;
		}
		set;
	}

	public static CBModelingLine__c variable1ModelingLine {
		get {
			if (variable1ModelingLine == null) {
				for (CBModelingLine__c line : modelingRule.CBModelingLines__r) {
					if (isSpecialLineFor(line, 'cblight__CBVariable1__c')) {
						variable1ModelingLine = line;
						break;
					}
				}
			}
			return variable1ModelingLine;
		}
		set;
	}

	public static CBModelingLine__c variable2ModelingLine {
		get {
			if (variable2ModelingLine == null) {
				for (CBModelingLine__c line : modelingRule.CBModelingLines__r) {
					if (isSpecialLineFor(line, 'cblight__CBVariable2__c')) {
						variable2ModelingLine = line;
						break;
					}
				}
			}
			return variable2ModelingLine;
		}
		set;
	}

	public static CBModelingLine__c variable3ModelingLine {
		get {
			if (variable3ModelingLine == null) {
				for (CBModelingLine__c line : modelingRule.CBModelingLines__r) {
					if (isSpecialLineFor(line, 'cblight__CBVariable3__c')) {
						variable3ModelingLine = line;
						break;
					}
				}
			}
			return variable3ModelingLine;
		}
		set;
	}

	public static CBModelingLine__c variable4ModelingLine {
		get {
			if (variable4ModelingLine == null) {
				for (CBModelingLine__c line : modelingRule.CBModelingLines__r) {
					if (isSpecialLineFor(line, 'cblight__CBVariable4__c')) {
						variable4ModelingLine = line;
						break;
					}
				}
			}
			return variable4ModelingLine;
		}
		set;
	}

	public static CBModelingLine__c variable5ModelingLine {
		get {
			if (variable5ModelingLine == null) {
				for (CBModelingLine__c line : modelingRule.CBModelingLines__r) {
					if (isSpecialLineFor(line, 'cblight__CBVariable5__c')) {
						variable5ModelingLine = line;
						break;
					}
				}
			}
			return variable5ModelingLine;
		}
		set;
	}

	public static Map<String, String> accountMapping {
		get {
			if (accountMapping == null) {
				accountMapping = getStandardAnalyticsMapping(accountModelingLine);
			}
			return accountMapping;
		}
		set;
	}

	public static Map<String, String> divisionMapping {
		get {
			if (divisionMapping == null) {
				divisionMapping = getStandardAnalyticsMapping(divisionModelingLine);
			}
			return divisionMapping;
		}
		set;
	}

	public static Map<String, String> variable1Mapping {
		get {
			if (variable1Mapping == null) {
				variable1Mapping = variable1ModelingLine == null ? new Map<String, String>() : getStandardAnalyticsMapping(variable1ModelingLine);
			}
			return variable1Mapping;
		}
		set;
	}

	public static Map<String, String> variable2Mapping {
		get {
			if (variable2Mapping == null) {
				variable2Mapping = variable2ModelingLine == null ? new Map<String, String>() : getStandardAnalyticsMapping(variable2ModelingLine);
			}
			return variable2Mapping;
		}
		set;
	}

	public static Map<String, String> variable3Mapping {
		get {
			if (variable3Mapping == null) {
				variable3Mapping = variable3ModelingLine == null ? new Map<String, String>() : getStandardAnalyticsMapping(variable3ModelingLine);
			}
			return variable3Mapping;
		}
		set;
	}

	public static Map<String, String> variable4Mapping {
		get {
			if (variable4Mapping == null) {
				variable4Mapping = variable4ModelingLine == null ? new Map<String, String>() : getStandardAnalyticsMapping(variable4ModelingLine);
			}
			return variable4Mapping;
		}
		set;
	}

	public static Map<String, String> variable5Mapping {
		get {
			if (variable5Mapping == null) {
				variable5Mapping = variable5ModelingLine == null ? new Map<String, String>() : getStandardAnalyticsMapping(variable5ModelingLine);
			}
			return variable5Mapping;
		}
		set;
	}

	public static Map<String, String> periodMapping {
		get {
			if (periodMapping == null) {
				periodMapping = getStandardAnalyticsMapping(periodModelingLine);
			}
			return periodMapping;
		}
		set;
	}

	/**
	 * Find Object Field type
	 */
	public static String returnObjectFiledType(String sObjectType, String fieldName) {
		CBUtils.fillInFieldNameToTypeMap(sObjectType);
		return CBUtils.getFieldType(sObjectType, fieldName);
	}

	/**
 *
 * @param sourceDate any Date from source
 * @return periods id
 */
	public static String getPeriodIdforSourceDate(Date sourceDate) {
		for (Id pId : periodMap.keyset()) {
			cblight__CBPeriod__c period = periodMap.get(pId);
			if (sourceDate >= period.cblight__Start__c && sourceDate <= period.cblight__End__c) return String.valueof(period.Id);
		}
		return null;
	}


	/**
*
* @param sourceDate any periodId from source
* @return string date
*/
	public static String getSourceDateforSourcePeriod(String periodId) {
		cblight__CBPeriod__c p = periodMap.get(periodId);
		return p == null ? null : '' + p.cblight__Start__c;
	}


	/**
	 * 
	 * @param  periodSourceFieldType,periodResultFieldType,sourcePeriodValue,  periodModeling line fields and source value
	 * @return periods Id or Date value, or inital record if fields are not "DATE"
	 */
	public static String getPeriodOrDateFromSource(String periodSourceFieldType, String periodResultFieldType, Object sourcePeriodValue) {
		if (periodSourceFieldType == 'DATE') {
			return CBModelingRuleMappingService.getPeriodIdforSourceDate(Date.valueof(sourcePeriodValue));
		}
		if (periodResultFieldType == 'DATE') {
			return CBModelingRuleMappingService.getSourceDateforSourcePeriod(String.valueof(sourcePeriodValue));
		}
		return CBModelingRuleMappingService.mapPeriodId(String.valueof(sourcePeriodValue));
	}


	/**
	 * Set of modeling rule line names that may need use cross package mapping
	 */
	public static Map<String, Map<String, String>> specialCrossPackageFieldsMap {
		get {
			if (specialCrossPackageFieldsMap == null) {
				specialCrossPackageFieldsMap = new Map<String, Map<String, String>>{
						'cblight__CBAccount__c' => accountMapping, 'cblight__CBDivision__c' => divisionMapping, 'cblight__CBPeriod__c' => periodMapping,
						'cblight__CBVariable1__c' => variable1Mapping, 'cblight__CBVariable2__c' => variable2Mapping, 'cblight__CBVariable3__c' => variable3Mapping,
						'cblight__CBVariable4__c' => variable4Mapping, 'cblight__CBVariable5__c' => variable5Mapping
				};
			}
			return specialCrossPackageFieldsMap;
		}
		set;
	}

	/**
	 * Mapping source period to result period
	 *
	 * @param sourcePeriodId
	 *
	 * @return result period
	 */
	public static String mapPeriodId(String sourcePeriodId) {
		if (CBModelingRuleMappingService.periodMapping.size() > 1) {
			// mapping size is 0 if mapping not needed
			sourcePeriodId = periodMapping.get(sourcePeriodId);
		}
		return sourcePeriodId;
	}

	public static String mapAccountId(String sourceAccountId) {
		if (CBModelingRuleMappingService.accountMapping.size() > 1) {
			// mapping size is 0 if mapping not needed
			sourceAccountId = accountMapping.get(sourceAccountId);
		}
		return sourceAccountId;
	}

	public static String mapDivisionId(String sourceDivisionId) {
		if (CBModelingRuleMappingService.divisionMapping.size() > 1) {
			// mapping size is 0 if mapping not needed
			sourceDivisionId = divisionMapping.get(sourceDivisionId);
		}
		return sourceDivisionId;
	}

	/**
	 * Mapping CB ID to External Id
	 */
	public static Map<String, String> extPeriodMap {
		get {
			if (extPeriodMap == null) {
				extPeriodMap = new Map<String, String>();
				for (CBPeriod__c p : new CBPeriodSelector().getPeriods('cblight__ExtId__c != null')) {
					extPeriodMap.put(p.Id, p.cblight__ExtId__c);
					extPeriodMap.put(p.cblight__ExtId__c, p.Id);
				}
			}
			return extPeriodMap;
		}
		set;
	}

	/**
	 * Mapping CB ID to External Id
	 */
	public static Map<String, String> extDivisionMap {
		get {
			if (extDivisionMap == null) {
				extDivisionMap = new Map<String, String>();
				for (CBDivision__c p : new CBDivisionSelector().getDivisionRecords('cblight__ExtId__c != null')) {
					extDivisionMap.put(p.Id, p.cblight__ExtId__c);
					extDivisionMap.put(p.cblight__ExtId__c, p.Id);
				}
			}
			return extDivisionMap;
		}
		set;
	}

	/**
	 * Mapping CB ID to External Id
	 */
	public static Map<String, String> extBudgetYearMap {
		get {
			if (extBudgetYearMap == null) {
				extBudgetYearMap = new Map<String, String>();
				for (CBBudgetYear__c p : new CBBudgetYearSelector().getBudgetYears('cblight__ExtId__c != null')) {
					extBudgetYearMap.put(p.Id, p.cblight__ExtId__c);
					extBudgetYearMap.put(p.cblight__ExtId__c, p.Id);
				}
			}
			return extBudgetYearMap;
		}
		set;
	}

	/**
	 * Mapping CB ID to External Id
	 */
	public static Map<String, String> extAccountMap {
		get {
			if (extAccountMap == null) {
				extAccountMap = new Map<String, String>();
				for (CBAccount__c p : new CBAccountSelector().getAccountRecords('cblight__ExtId__c != null')) {
					extAccountMap.put(p.Id, p.cblight__ExtId__c);
					extAccountMap.put(p.cblight__ExtId__c, p.Id);
				}
			}
			return extAccountMap;
		}
		set;
	}
	/**
	 * Mapping CB ID to External Id
	 */
	public static Map<String, String> extVariable1Map {
		get {
			if (extVariable1Map == null) {
				extVariable1Map = new Map<String, String>();
				for (CBVariableSelector.VariableWrapper p : new CBVariableSelector().setIndex(1).getVariablesByFilter('cblight__ExtId__c != null')) {
					extVariable1Map.put(p.recordId, p.ExtId);
					extVariable1Map.put(p.ExtId, p.recordId);
				}
			}
			return extVariable1Map;
		}
		set;
	}
	/**
	 * Mapping CB ID to External Id
	 */
	public static Map<String, String> extVariable2Map {
		get {
			if (extVariable2Map == null) {
				extVariable2Map = new Map<String, String>();
				for (CBVariableSelector.VariableWrapper p : new CBVariableSelector().setIndex(2).getVariablesByFilter('cblight__ExtId__c != null')) {
					extVariable2Map.put(p.recordId, p.ExtId);
					extVariable2Map.put(p.ExtId, p.recordId);
				}
			}
			return extVariable2Map;
		}
		set;
	}
	/**
	 * Mapping CB ID to External Id
	 */
	public static Map<String, String> extVariable3Map {
		get {
			if (extVariable3Map == null) {
				extVariable3Map = new Map<String, String>();
				for (CBVariableSelector.VariableWrapper p : new CBVariableSelector().setIndex(3).getVariablesByFilter('cblight__ExtId__c != null')) {
					extVariable3Map.put(p.recordId, p.ExtId);
					extVariable3Map.put(p.ExtId, p.recordId);
				}
			}
			return extVariable3Map;
		}
		set;
	}
	/**
	 * Mapping CB ID to External Id
	 */
	public static Map<String, String> extVariable4Map {
		get {
			if (extVariable4Map == null) {
				extVariable4Map = new Map<String, String>();
				for (CBVariableSelector.VariableWrapper p : new CBVariableSelector().setIndex(4).getVariablesByFilter('cblight__ExtId__c != null')) {
					extVariable4Map.put(p.recordId, p.ExtId);
					extVariable4Map.put(p.ExtId, p.recordId);
				}
			}
			return extVariable4Map;
		}
		set;
	}
	/**
	 * Mapping CB ID to External Id
	 */
	public static Map<String, String> extVariable5Map {
		get {
			if (extVariable5Map == null) {
				extVariable5Map = new Map<String, String>();
				for (CBVariableSelector.VariableWrapper p : new CBVariableSelector().setIndex(5).getVariablesByFilter('cblight__ExtId__c != null')) {
					extVariable5Map.put(p.recordId, p.ExtId);
					extVariable5Map.put(p.ExtId, p.recordId);
				}
			}
			return extVariable5Map;
		}
		set;
	}

	/**
	 * Period shift mapping where key = source period Id, and result = shifted period Id
	 */
	public static Map<String, String> shiftedPeriodsMap {
		get {
			if (shiftedPeriodsMap == null) {

				shiftedPeriodsMap = new Map<String, String>();
				List<cblight__CBPeriod__c> periods = [SELECT Id FROM cblight__CBPeriod__c ORDER BY Start__c LIMIT 10000];
				Integer periodShift = modelingRule.cblight__PeriodShift__c == null ? 0 : (Integer) modelingRule.cblight__PeriodShift__c, periodSize = periods.size(), resultIdx;
				for (Integer sourceIdx = 0; sourceIdx < periodSize; sourceIdx++) {
					try {
						resultIdx = sourceIdx + periodShift;
						if (resultIdx < 0 || resultIdx > periodSize - 1) continue;
						shiftedPeriodsMap.put(periods[sourceIdx].Id, periods[resultIdx].Id);
					} catch (Exception e) {
						throw new CBException(e, 'SP: periodShift=' + periodShift + ' sourceIdx=' + sourceIdx + ' resultIdx=' + resultIdx + ' periodSize=' + periodSize);
					}
				}
			}
			return shiftedPeriodsMap;
		}
		set;
	}

	/**
	 * The method returns External Id for each lookup because Modeling rules is trying use Ext Id for all keys
	 *
	 * @param sourceId source analytic Id
	 * @param type - lookup field
	 *
	 * @return external id of the record
	 */
	public static String getExtId(String sourceId, String type) {

		switch on type {
			when 'cblight__CBPeriod__c' {

				return extPeriodMap.size() == 0 ? sourceId : extPeriodMap.get(sourceId);
			}
			when 'cblight__CBAccount__c' {
				return extAccountMap.size() == 0 ? sourceId : extAccountMap.get(sourceId);
			}
			when 'cblight__CBBudgetYear__c' {
				return extBudgetYearMap.size() == 0 ? sourceId : extBudgetYearMap.get(sourceId);
			}
			when 'cblight__CBDivision__c' {
				return extDivisionMap.size() == 0 ? sourceId : extDivisionMap.get(sourceId);
			}
			when 'cblight__CBVariable1__c' {
				return extVariable1Map.size() == 0 ? sourceId : extVariable1Map.get(sourceId);
			}
			when 'cblight__CBVariable2__c' {
				return extVariable2Map.size() == 0 ? sourceId : extVariable2Map.get(sourceId);
			}
			when 'cblight__CBVariable3__c' {
				return extVariable3Map.size() == 0 ? sourceId : extVariable3Map.get(sourceId);
			}
			when 'cblight__CBVariable4__c' {
				return extVariable4Map.size() == 0 ? sourceId : extVariable4Map.get(sourceId);
			}
			when 'cblight__CBVariable5__c' {
				return extVariable5Map.size() == 0 ? sourceId : extVariable5Map.get(sourceId);
			}
			when else {
				return String.valueof(sourceId);
			}
		}
	}

	///////// PRIVATE METHODS ////////////
	/**
	 * Method serves to map our records with external records
	 * If result is CB record than we should use CB Ids
	 * If source is CB and result is CB no mapping needed
	 * If source is CB and result is NOT CB mapping reruns extra Id
	 * If source is NOT CB and result is CB mapping reruns CB Id
	 * If source is NOT CB and result NOT CB no mapping needed
	 *
	 * In rear cases we may use our analytics in NOT CB cObjects. To do this just name the field as it names in the CB side
	 *
	 * @param line - one of modeling rule lines
	 * @return map where the key may be CB object Id or external object Id
	 * empty map if mapping not needed
	 */
	private static Map<String, String> getStandardAnalyticsMapping(CBModelingLine__c line) {
		try {
			Map<String, String> r = new Map<String, String>();
			if (line == null) return r;
			if (line.SourceField__c.replace(CBConstantsService.CB_PREFIX, '') == line.ResultField__c.replace(CBConstantsService.CB_PREFIX, '')) return r;
			Boolean isCBSourceObject = line.SourceField__c.startsWith(CBConstantsService.CB_PREFIX);
			Boolean isCBResultObject = line.ResultField__c.startsWith(CBConstantsService.CB_PREFIX);
			if (isCBSourceObject != isCBResultObject) { // if source and result from the package of if source and record are external - no mapping needed
				Object extId;
				String type = CBModelingRuleService.getMRLSpecialType(line); // for example "cblight__CBAccount__c"
				for (SObject obj : new CBSobjectSelector(type, false).selectFieldsByNames(new List<String>{
						'Id', 'cblight__ExtId__c'
				}).getSobjects()) {  // TODO reasonable limit using source data set of analytics
					extId = obj.get('cblight__ExtId__c');
					if (isCBResultObject) {    // result record is CB object
						r.put(extId == null ? obj.Id : (String) extId, obj.Id);
					} else {                    // result record is external object
						r.put(obj.Id, extId == null ? obj.Id : (String) extId);
					}
				}
			}
			return r;
		} catch (Exception e) {
			throw new CBException(e, 'MRM->SAM');
		}
	}

	public static Boolean isSpecialLineFor(CBModelingLine__c line, String sObjectType) {
		return line.SourceField__c.equals(sObjectType) || line.ResultField__c.equals(sObjectType);
	}

	///////// PRIVATE METHODS ////////////
}