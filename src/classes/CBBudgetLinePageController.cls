/**
 * Created by Alex JR on 10/23/2021.
 * Copyright (c) 2021, CloudBudget, Inc.
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
 * The page controller for BudgetLineManager Component
 */
public with sharing class CBBudgetLinePageController {
	public CBBudgetLinePageController() {
	}

	private static String BUDGET_LINE_SO_API_NAME = 'cblight__CBBudgetLine__c';
	private static String BUDGET_YEAR_KEY = 'cblight__CBBudgetYear__c';
	private static final Map<String, String> ALLOCATION_MODE_OPTIONS = new Map<String, String>{
			'onlyParents' => 'Source Only',
			'onlyChildren' => 'Sublines Only'
	};
	private static Integer BUDGET_LINES_LITE_LIMIT = 10;

	@AuraEnabled
	public static Boolean limitIsReachedServer() {
		return [SELECT COUNT() FROM CBBudgetLine__c WITH SECURITY_ENFORCED] > BUDGET_LINES_LITE_LIMIT;
	}

	/**
	 * @param params (Map<String, String>): Page filter parameters
	 *
	 * @return List<CBBudgetLine__c>: List of available budget lines
	 */
	@AuraEnabled
	public static List<CBBudgetLine__c> getBudgetLinesServer(Map<String, String> params) {
		if (params == null) {// some parameters are required
			return null;
		}
		String bYId = params.get(BUDGET_YEAR_KEY);
		CBOrgVariable__c orgVariable = CBOrgVariableSelector.getOrgVariableServer(); // current org variable

		if (orgVariable == null || bYId == null) {
			return null;
		}
		String BLFilter = new CBUtils(params).addFilterStr('cblight__CBBudgetYear__c').getResult();
		String additionalFilter = getAdditionalFilterFromParams(params);
		if (orgVariable.AllocationIsUsing__c) {
			additionalFilter = addAllocationModeFilter(additionalFilter, params);
		}
		if (orgVariable.TopdownModeIsUsing__c) {
			additionalFilter = addApproachFilter(additionalFilter, params);
		}
		BLFilter += String.isBlank(additionalFilter) ? '' : (String.isBlank(additionalFilter) ? additionalFilter : ' AND ( ' + additionalFilter + ' ) ');
		String textFilter = params.get('textFilter');
		if (textFilter != null) {
			String whereStr = CBBudgetLineGlobalSearchService.getTextFilterBudgetLineQuery(textFilter);
			BLFilter += whereStr == null ? ' AND ( Id = null ) ' : ' AND ( ' + whereStr + ' ) ';
		}
		List<CBBudgetLine__c> BLines = new CBBudgetLineSelector().getBudgetLines(BLFilter);
		if (CBMultiCurrencyService.multiCurrencyEnabled) {
			CBMultiCurrencyService.updateBudgetLinesWithProperlyCurrency(BLines, true);
		}
		return BLines;
	}

	private static String addAllocationModeFilter(String additionalFilter, Map<String, String> params) {
		String filter = params.get('allocationMode') == 'onlyParents'
				? ' (cblight__isAllocation__c = true OR cblight__ParentBudgetLine__c = null) '
				: ' (cblight__isAllocation__c = false) ';
		return String.isBlank(additionalFilter) ? filter : additionalFilter + ' AND ' + filter;
	}

	private static String addApproachFilter(String additionalFilter, Map<String, String> params) {
		String filter = params.get('approach') == 'bottom-up' ? ' (cblight__isTopdown__c = false) ' : ' (cblight__isTopdown__c = true) ';
		return String.isBlank(additionalFilter) ? filter : additionalFilter + ' AND ' + filter;
	}

	private static String getAdditionalFilterFromParams(Map<String, String> params) {
		try {
			String complexFilter = params.get('complexFilter'), additionalFilter;
			if (String.isBlank(complexFilter)) {
				return new CBUtils(params)
						.addFilterStr('cblight__CBDivision__c')
						.addFilterStr('cblight__CBAccount__c')
						.addFilterStr('cblight__CBScenario__c')
						.addFilterStr('cblight__CBVariable1__c')
						.addFilterStr('cblight__CBVariable2__c')
						.addFilterStr('cblight__CBVariable3__c')
						.addFilterStr('cblight__CBVariable4__c')
						.addFilterStr('cblight__CBVariable5__c')
						.addFilterStr('OwnerId')
						.getResult();
			} else {
				return complexFilter;
			}
		} catch (Exception e) {
			System.debug('getAdditionalFilterFromParams ERROR: ' + e);
			return '';
		}
	}

	@AuraEnabled
	public static List<CBBudgetLine__c> getSingleBudgetLineServer(String budgetLineId) {
		if (budgetLineId == null) {
			return null;
		}
		List<CBBudgetLine__c> BLines = new CBBudgetLineSelector().getBudgetLines(' Id = \'' + budgetLineId + '\' ');
		if (CBMultiCurrencyService.multiCurrencyEnabled) {
			CBMultiCurrencyService.updateBudgetLinesWithProperlyCurrency(BLines, true);
		}
		return BLines;
	}
	/**
	 * returns list of NFL by id list
	 *
	 * @param nflIdList
	 *
	 * @return
	 */
	@AuraEnabled
	public static List<CBNonFinancialLibrary__c> getLibrariesFromBudgetLineServer(List<String> nflIdList) {
		List<CBNonFinancialLibrary__c> result = new List<CBNonFinancialLibrary__c>();
		for (String s : nflIdList) {
			s = CBUtils.refineStr(s);
		}
		try {
			if (nflIdList.size() > 0) {
				Set<String> nflIdSet = new Set<String>(nflIdList);
				String filter = ' Id IN' + CBUtils.getFormattedINQuery(nflIdSet);
				result = new CBNonFinancialLibrarySelector().getNonFinancialLibrariesByFilter(filter, null);
			}
			return result;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static List<CBBudgetLine__c> getAllocatedBudgetLinesServer(String parentBudgetLineId) {
		if (parentBudgetLineId == null) {
			return null;
		}
		parentBudgetLineId = CBUtils.refineStr(parentBudgetLineId);
		List<CBBudgetLine__c> BLines = new CBBudgetLineSelector().getBudgetLines(' cblight__ParentBudgetLine__c = \'' + parentBudgetLineId + '\' ');
		if (CBMultiCurrencyService.multiCurrencyEnabled) {
			CBMultiCurrencyService.updateBudgetLinesWithProperlyCurrency(BLines, true);
		}
		return BLines;
	}

	/**
	 * @return Map<String, List<CBSO>>: List of available selectoptions for the page filters
	 */
	@AuraEnabled
	public static Map<String, List<CBSO>> getSelectOptionsServer() {
		Map<String, List<CBSO>> r = new CBSOService()
				.addSOList('budgetYearSO', 'cblight__CBBudgetYear__c', new List<String>{
						'Name'
				}, null, null, 'Name')
				.addSOList('scenarioSO', 'cblight__CBScenario__c', new List<String>{
						'Name'
				}, null, null, 'Name')
				.addSOList('clusterRuleSO', 'cblight__CBClusterRule__c', new List<String>{
						'Name'
				}, null, null, 'Name')
				.getResult();
		if (Database.query('SELECT Id FROM cblight__CBVariable1__c WITH SECURITY_ENFORCED LIMIT 1').size() > 0)
			r.put('variable1SO', new List<CBSO>());
		if (Database.query('SELECT Id FROM cblight__CBVariable2__c WITH SECURITY_ENFORCED LIMIT 1').size() > 0)
			r.put('variable2SO', new List<CBSO>());
		if (Database.query('SELECT Id FROM cblight__CBVariable3__c WITH SECURITY_ENFORCED LIMIT 1').size() > 0)
			r.put('variable3SO', new List<CBSO>());
		if (Database.query('SELECT Id FROM cblight__CBVariable4__c WITH SECURITY_ENFORCED LIMIT 1').size() > 0)
			r.put('variable4SO', new List<CBSO>());
		if (Database.query('SELECT Id FROM cblight__CBVariable5__c WITH SECURITY_ENFORCED LIMIT 1').size() > 0)
			r.put('variable5SO', new List<CBSO>());
		r.put('budgetLineFieldSO', CBUtils.getObjectFieldsSO('cblight__CBBudgetLine__c'));
		return r;
	}

	/**
	 * @param params (Map<String, String>): Write the parameter description
	 *
	 * @return CBClusterRule__c: Selected Rule or the first in the list
	 */
	@AuraEnabled(Cacheable=true)
	public static CBClusterRule__c getClusterRuleServer(Map<String, String> params) {
		try {
			String ruleId = params.get('cblight__CBClusterRule__c');
			return String.isBlank(ruleId) ? null : new CBClusterRuleSelector().getClusterRules(ruleId)[0];
		} catch (Exception e) {
			return null;
		}
	}

	/**
	 * @return List<CBPeriod__c>: List of the periods of the selected budget year
	 */
	@AuraEnabled(Cacheable=true)
	public static List<CBPeriod__c> getPeriodsServer() {
		return new CBPeriodSelector().getPeriods(null);
	}

	//////////////////////////////////////////////  BUDGET LINE ////////////////////
	/**
	 * Method saves single budget line with its amounts
	 *
	 * @param budgetLine
	 * @param amounts
	 *
	 * @return
	 */
	@AuraEnabled
	public static List<CBBudgetLine__c> saveBudgetLineServer(CBBudgetLine__c budgetLine, List<CBAmount__c> amounts) {
		if (CBMultiCurrencyService.multiCurrencyEnabled) {
			CBMultiCurrencyService.convertBLAmountValues(amounts, false);
		}
		new CBBudgetLineService().saveBudgetLine(budgetLine, amounts, null);
		return getSingleBudgetLineServer(budgetLine.Id);
	}

	/**
	 * The method saves allocated budget lines
	 *
	 * @param budgetLines - allocated budget lines
	 * @param amounts - amounts of allocated budget lines
	 */
	@AuraEnabled
	public static void saveAllocatedBudgetLinesServer(List<CBBudgetLine__c> budgetLines, List<List<CBAmount__c>> amounts) {
		CBBudgetLineService.saveBudgetLinesInScope(budgetLines, amounts);
	}

	/**
	 * The method saves budget lines
	 *
	 * @param budgetLines - budget lines
	 * @param amounts - amounts of budget lines
	 */
	@AuraEnabled
	public static void saveBudgetLinesServer(List<CBBudgetLine__c> budgetLines, List<List<CBAmount__c>> amounts) {
		CBBudgetLineService.saveBudgetLinesInScope(budgetLines, amounts);
	}

	@AuraEnabled
	public static void deleteBudgetLineServer(String budgetLineId) {
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{
				CBBudgetLine__c.SObjectType
		});
		List<CBBudgetLine__c> bll = new CBBudgetLineSelector().getBudgetLines(' Id = \'' + budgetLineId + '\'');
		uow.registerDeleted(bll);
		uow.commitWork();
	}

	/**
	 * @return List<CBStyle__c>: List of the Styles For Account Types
	 */
	@AuraEnabled
	public static List<CBStyle__c> getStylesForAccountTypesServer() {
		return new CBStyleSelector().getStylesForAccountTypes();
	}

	/**
	 * @return List<CBAccountType__c>: List of the CBAccountType With Styles
	 */
	@AuraEnabled
	public static List<CBAccountType__c> getAccTypesWithStylesNamesServer() {
		return new CBAccountTypeSelector().getAccountTypeRecordsByFilter(null);
	}

	/**
	 * @return List<CBStyle__c>: List of the Styles
	 */
	@AuraEnabled
	public static List<CBStyle__c> getStylesRecordsServer() {
		return new CBStyleSelector().getStylesRecordsByFilter(null);
	}
	//////////////////////////////////////////////  BUDGET LINE ////////////////////

	//////////////////////////////////////////////  DRILL DOWN ////////////////////
	/**
	 * @param objectIds list of ids of any type of records
	 * All ids must be the same type
	 *
	 * @return list of respective objects with currency and date fields
	 */
	@AuraEnabled
	public static List<Object> getDrillDownLinksServer(List<String> objectIds) {
		List<Object> objects = new List<Object>();
		Set<Schema.SObjectType> soTypesSet = new Set<SObjectType>();
		List<CBSobjectSelector> soSelectorsList = new List<CBSobjectSelector>();

		for (String soId : objectIds) {
			soId = CBUtils.refineStr(soId);
			soTypesSet.add (((Id) soId).getSobjectType());
		}

		for (Schema.SObjectType soType : soTypesSet) {
			List<String> fieldNames = new List<String>{
					'Id', 'Name'
			};
			CBSobjectSelector sObjectSelector = new CBSobjectSelector(soType, false);
			String soTypeString = String.valueOf(soType);
			CBUtils.fillInFieldNameToTypeMap(soTypeString);
			Map<String, String> soMap = CBUtils.fieldNameToFieldTypeMap.get(soTypeString);
			String q = 'SELECT Id, Name ';
			for (String field : soMap.keySet()) {
				String type = soMap.get(field);

				if (type == 'CURRENCY' || type == 'DOUBLE' || type == 'DATE' || (field.contains('Period') && type == 'STRING')) {
					fieldNames.add(field);
					q += ',' + field;
				}
			}
			soSelectorsList.add(sObjectSelector.selectFieldsByNames(fieldNames));
		}
		objects.addAll(soSelectorsList[0].getSobjects(' Id IN ' + CBUtils.getFormattedINQuery(new Set<String>(objectIds))));
		if (soTypesSet.size() > 1) {
			objects.addAll(soSelectorsList[1].getSobjects(' Id IN ' + CBUtils.getFormattedINQuery(new Set<String>(objectIds))));
		}
		return objects;
	}
	//////////////////////////////////////////////  DRILL DOWN ////////////////////

	//////////////////////////////////////////////  COMPLEX BUDGET LINE ////////////////////
	@AuraEnabled
	public static List<CBNonFinancialLibrary__c> getNonFinancialLibrariesServer() {
		return new CBNonFinancialLibrarySelector().getNonFinancialLibrariesByFilter(null, null);
	}
	//////////////////////////////////////////////  COMPLEX BUDGET LINE ////////////////////

	//////////////////////////////////////////////  RECENT LIST ////////////////////////////
	@AuraEnabled
	public static List<CBBudgetLine__c> getRecentBudgetLinesServer() {
		return new CBBudgetLineSelector().getRecentBudgetLines();
	}
	//////////////////////////////////////////////  RECENT LIST ////////////////////////////

	//////////////////////// PRIVATE METHODS /////////////////////
	@AuraEnabled
	public static List<CBSO> getSObjectFieldsDataServer() {
		return CBUtils.getObjectFieldsSO(BUDGET_LINE_SO_API_NAME);
	}
	//////////////////////// PRIVATE METHODS /////////////////////


	//////////////////////// PAGE INFO /////////////////////
	/**
	 * The method finds obj Name by Id
	 *
	 * @param obj
	 *
	 * @return Map<String, String>: Map with name of object by id
	 */
	@AuraEnabled
	public static Map<String, String> getIdToNamesMapServer(Map<String, String> obj) {
		try {
			if (obj == null) {// obj is required
				return null;
			}
			for (String key : obj.keySet()) {
				String value = obj.get(key);
				value = CBUtils.refineStr(value);
				if (key == 'OwnerId') {
					key = CBUtils.refineStr(key);

					SObject record = Database.query('SELECT Id, Name FROM User WHERE Id = \'' + value + '\' WITH SECURITY_ENFORCED');
					obj.put((String) key, (String) record.get('Name'));
				}
				if (String.isEmpty(value) || key == 'complexFilter' || key == 'approach' || key == 'textFilter') {
					obj.put((String) key, (String) value);
				} else if (key == 'allocationMode') {
					obj.put((String) key, ALLOCATION_MODE_OPTIONS.get((String) value));
				} else {
					SObject record = Database.query('SELECT Id, Name FROM ' + key + ' WHERE Id = \'' + value + '\' WITH SECURITY_ENFORCED');
					obj.put((String) key, (String) record.get('Name'));
				}
			}
			return obj;
		} catch (Exception e) {
			return obj;
		}
	}

	/**
	 * The method finds Scenario by Id
	 *
	 * @param rId
	 *
	 * @return CBScenario__c: Record
	 */
	@AuraEnabled
	public static CBScenario__c getSingleScenarioServer(String rId) {
		if (rId == null) {
			return null;
		}
		return new CBScenarioSelector().getScenarioRecordById(rId);
	}
	//////////////////////// PAGE INFO /////////////////////
}