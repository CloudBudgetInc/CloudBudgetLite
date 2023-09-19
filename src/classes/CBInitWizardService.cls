/** 
Copyright (c) 2022, CloudBudget, Inc.
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
public with sharing abstract class CBInitWizardService implements CBMappingInterface {
	public String type;
	public CBMapping__c mapping {
		get {
			if (mapping == null) {
				mapping = new CBMappingSelector().getMappingRecordByType(type);
			}
			mapping.cblight__SourceName__c = mapping.cblight__SourceName__c == null ? 'Name' : mapping.cblight__SourceName__c;
			return mapping;
		}
		set;
	}

	/**
	 * The method counts a number of source records before the mapping
	 * @return true if process needs to use batch
	 */
	public Boolean recordNumberIsOutOfLimit() {
		CBOrgVariable__c ov = CBOrgVariableSelector.getOrgVariableServer();
		Integer jobThreshold = ov == null || ov.cblight__InitWizardJobThreshold__c == null ? 1000 : ov.cblight__InitWizardJobThreshold__c.intValue();
		CBSobjectSelector sobjectSelector = new CBSobjectSelector(mapping.SourceSObject__c, false);
		Integer numberOfRecords = sobjectSelector.countSobjects(mapping.SourceFilter__c);
		return numberOfRecords > jobThreshold;
	}

	/**
	 * @return the main query string for batch or for mapping process
	 */
	public String getSourceRequestString() {
		CBSobjectSelector sobjectSelector = new CBSobjectSelector(mapping.SourceSObject__c, false);
		Set<String> fieldSet = new Set<String>{
				'Id', 'Name'
		};
		for (String field : new List<String>{
				mapping.SourceName__c, mapping.SourceSubtype__c, mapping.SourceType__c
		}) {
			if (field != null) {
				fieldSet.add(field);
			}
		}
		sobjectSelector.selectFieldsByNames(new List<String>(fieldSet));
		return sobjectSelector.getStringQuery(mapping.SourceFilter__c);
	}

	/**
	 * Special class that can work as a job ar as a class
	 * Serves to map Accounts
	 */
	public with sharing class CBMapAccounts extends CBInitWizardService {
		public CBMapAccounts() {
			type = 'accounts';
		}
		// key = externalId or external Name
		private Map<String, CBAccountType__c> accTypeMap {
			get {
				if (accTypeMap == null) {
					accTypeMap = new Map<String, CBAccountType__c>();
					for (CBAccountType__c accT : [SELECT Id, Name, ExtId__c FROM CBAccountType__c WITH SECURITY_ENFORCED]) {
						accTypeMap.put(acct.ExtId__c, accT);
					}
				}
				return accTypeMap;
			}
			set;
		}

		// key = externalId or external Name
		private Map<String, CBSubAccount__c> accSubTypeMap {
			get {
				if (accSubTypeMap == null) {
					accSubTypeMap = new Map<String, CBSubAccount__c>();
					for (CBSubAccount__c accST : [SELECT Id, Name, ExtId__c FROM CBSubAccount__c WITH SECURITY_ENFORCED]) {
						accSubTypeMap.put(accST.ExtId__c, accST);
					}
				}
				return accSubTypeMap;
			}
			set;
		}

		/**
		 * if source data record does not have needed analytic we need specify default value
		 */
		private CBAccountType__c defaultAccountType {
			get {
				if (defaultAccountType == null) {
					List<CBAccountType__c> accTypes = [SELECT Id FROM CBAccountType__c WHERE Name = 'Other' WITH SECURITY_ENFORCED LIMIT 1];
					if (accTypes.size() > 0) {
						defaultAccountType = accTypes[0];
					} else {
						defaultAccountType = new CBAccountType__c(Name = 'Other', Sign__c = '+');
						fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{
								CBAccountType__c.SObjectType
						});
						uow.registerNew(defaultAccountType);
						uow.commitWork();
					}
				}
				return defaultAccountType;
			}
			set;
		}

		private CBSubAccount__c defaultAccountSubType {
			get {
				if (defaultAccountSubType == null) {
					List<CBSubAccount__c> accSubTypes = [SELECT Id FROM CBSubAccount__c WHERE Name = 'Other' WITH SECURITY_ENFORCED LIMIT 1];
					if (accSubTypes.size() > 0) {
						defaultAccountSubType = accSubTypes[0];
					} else {
						defaultAccountSubType = new CBSubAccount__c(Name = 'Other');
						fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{
								CBSubAccount__c.SObjectType
						});
						uow.registerNew(defaultAccountSubType);
						uow.commitWork();
					}
				}
				return defaultAccountSubType;
			}
			set;
		}

		public void doMapping(List<sObject> listOfSourceAccounts) {
			if (listOfSourceAccounts == null || listOfSourceAccounts.size() == 0) {
				return;
			}
			updateAccountParents(listOfSourceAccounts, true);
			updateAccountParents(listOfSourceAccounts, false);
			updateAccounts(listOfSourceAccounts);
		}

		private void updateAccounts(List<sObject> listOfSourceAccounts) {
			try {
				CBAccount__c respectiveAcc;
				Set<String> currentListExtIds = new Set<String>();
				for (sObject acc : listOfSourceAccounts) {
					currentListExtIds.add(acc.Id);
				}

				Map<String, CBAccount__c> accMap = new Map<String, CBAccount__c>();
				for (CBAccount__c acc : new CBAccountSelector().getAccountRecordsByExtId(currentListExtIds)) {
					accMap.put(acc.ExtId__c, acc);
				}

				for (sObject acc : listOfSourceAccounts) {
					String extId = acc.Id;
					if (extId != null) {
						respectiveAcc = accMap.get(extId);
					}
					if (respectiveAcc == null) {
						respectiveAcc = new CBAccount__c();
					}
					assignAccountParent(respectiveAcc, true, (String) acc.get(mapping.SourceType__c));
					assignAccountParent(respectiveAcc, false, (String) acc.get(mapping.SourceSubtype__c));
					respectiveAcc.ExtId__c = acc.Id;
					respectiveAcc.Name = (String) acc.get(mapping.cblight__SourceName__c);
					accMap.put(extId, respectiveAcc);
				}
				setDefaultTypeAndSubtypeIdMissed(accMap.values());
				fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{
						CBAccount__c.SObjectType
				});
				uow.registerUpsert(accMap.values());
				uow.commitWork();
			} catch (Exception e) {
				throw new CBException(e, 'Create Accounts Error: ' + e.getLineNumber() + ' -> ' + e.getMessage());
			}
		}

		/**
		 * Method assigns missed Types and Subtypes
		 *
		 * @param accounts list of accounts before upsert
		 */
		private void setDefaultTypeAndSubtypeIdMissed(List<CBAccount__c> accounts) {
			for (CBAccount__c a : accounts) {
				if (a.CBAccountType__c == null) {
					a.CBAccountType__c = defaultAccountType.Id;
				}
				if (a.CBSubAccount__c == null) {
					a.CBSubAccount__c = defaultAccountSubType.Id;
				}
			}
		}

		/**
		 * 
		 *
		 * @param account
		 * @param isType
		 * @param value
		 */
		private void assignAccountParent(CBAccount__c account, Boolean isType, String value) {
			if (value == null) {
				return;
			}
			if (isType) {
				sObject parent = accTypeMap.get(value);
				if (parent == null) {
					return;
				}
				account.CBAccountType__c = parent.Id;
			} else {
				sObject parent = accSubTypeMap.get(value);
				if (parent == null) {
					return;
				}
				account.CBSubAccount__c = parent.Id;
			}
		}

		/**
		 * The method creates missed account types and subtypes if the type/subtype is in String, Picklist or Lookup
		 *
		 * @param listOfSourceAccounts
		 * @param isType true if Type, false is Subtype
		 */
		private void updateAccountParents(List<sObject> listOfSourceAccounts, Boolean isType) {
			try {
				String sourceParentKey;
				String accType;
				for (sObject o : listOfSourceAccounts) {
					if (accType == null) {
						accType = (String) o.get(isType ? mapping.SourceType__c : mapping.SourceSubtype__c);
					}
				}
				if (accType == null) {
					throw new CBException(null, 'Create Account Types Error: At least one source account must have a ' + (isType ? ' type' : ' subtype'));
				}
				Boolean typeIsId = true;
				Id accTypeId;
				CBAccountType__c respectiveType;
				CBSubAccount__c respectiveSubType;
				try {
					accTypeId = accType; // throws "System.StringException: Invalid id:" if account type is not a lookup
				} catch (Exception e) {
					typeIsId = false;
				}
				Set<String> plusSignSet = getPlusSignSet(isType, listOfSourceAccounts); // set of account type that may be considered as Expense
				if (typeIsId) {
					Set<String> possibleParentSet = new Set<String>();
					String sObjName = accTypeId.getSObjectType().getDescribe().getName();
					for (SObject sourceAcc : listOfSourceAccounts) {
						String parentId = (String) sourceAcc.get(isType ? mapping.SourceType__c : mapping.SourceSubtype__c);
						if (parentId != null) {
							possibleParentSet.add(parentId);
						}
					}
					List<SObject> spol = new CBSobjectSelector(sObjName, false)
							.selectFieldsByNames(new List<String>{
									'Id', 'Name'
							})
							.setFilter(' Id IN ' + CBUtils.getFormattedINQuery(possibleParentSet))
							.getSobjects();
					for (sObject sourceParentObj : spol) {
						sourceParentKey = sourceParentObj.Id;
						if (isType) {
							respectiveType = accTypeMap.get(sourceParentKey);
							if (respectiveType == null) {
								respectiveType = new CBAccountType__c();
							}
							respectiveType.ExtId__c = sourceParentKey;
							respectiveType.Name = (String) sourceParentObj.get('Name');
							respectiveType.Sign__c = plusSignSet.contains(sourceParentKey) ? '+' : '-';
							accTypeMap.put(sourceParentKey, respectiveType);
						} else {
							respectiveSubType = accSubTypeMap.get(sourceParentKey);
							if (respectiveSubType == null) {
								respectiveSubType = new CBSubAccount__c();
							}
							respectiveSubType.ExtId__c = sourceParentKey;
							respectiveSubType.Name = (String) sourceParentObj.get('Name');
							accSubTypeMap.put(sourceParentKey, respectiveSubType);
						}
					}
				} else { // if account type is text 
					for (SObject sourceAcc : listOfSourceAccounts) {
						if (isType) {
							sourceParentKey = (String) sourceAcc.get(mapping.SourceType__c);
							respectiveType = accTypeMap.get(sourceParentKey);
							if (respectiveType == null) {
								respectiveType = new CBAccountType__c();
							}
							respectiveType.ExtId__c = sourceParentKey;
							respectiveType.Name = sourceParentKey;
							respectiveType.Sign__c = plusSignSet.contains(sourceParentKey) ? '+' : '-';
							accTypeMap.put(sourceParentKey, respectiveType);
						} else {
							sourceParentKey = (String) sourceAcc.get(mapping.SourceSubtype__c);
							respectiveSubType = accSubTypeMap.get(sourceParentKey);
							if (respectiveSubType == null) {
								respectiveSubType = new CBSubAccount__c();
							}
							respectiveSubType.ExtId__c = sourceParentKey;
							respectiveSubType.Name = sourceParentKey;
							accSubTypeMap.put(sourceParentKey, respectiveSubType);
						}
					}
				}
				upsertParents(isType);
			} catch (Exception e) {
				throw new CBException(e, 'Create Account Types Error: ' + e.getLineNumber() + ' -> ' + e.getMessage());
			}
		}

		private Set<String> getPlusSignSet(Boolean isType, List<sObject> listOfSourceAccounts) {
			Set<String> plusSignSet = new Set<String>(); // set of account type that may be considered as Expense
			if (isType) {
				Set<String> currentAccountIdSet = new Set<String>();
				for (SObject sourceAcc : listOfSourceAccounts) {
					currentAccountIdSet.add(sourceAcc.Id);
				}
				if (mapping.SpecialFilter__c != null) {
					CBSobjectSelector sobjSel = new CBSobjectSelector(mapping.SourceSObject__c, false)
							.selectFieldsByNames(new List<String>{
									'Id', mapping.SourceType__c
							})
							.setFilter(' Id IN ' + CBUtils.getFormattedINQuery(currentAccountIdSet) + ' AND ( ' + mapping.SpecialFilter__c + ' ) ');
					for (sObject acc : sobjSel.getSobjects()) {
						plusSignSet.add((String) acc.get(mapping.SourceType__c));
					}
				}
			}
			return plusSignSet;
		}

		/**
		 * Method upserts account parents
		 *
		 * @param isType true if type, false if subtype
		 */
		private void upsertParents(Boolean isType) {
			fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
					new List<SObjectType>{
							CBAccountType__c.SObjectType, CBSubAccount__c.SObjectType
					}
			);
			if (isType) {
				uow.registerUpsert(accTypeMap.values());
				accTypeMap = null;
			} else {
				uow.registerUpsert(accSubTypeMap.values());
				accSubTypeMap = null;
			}
			uow.commitWork();
		}

		public void finishMapping() {
			CBTaskDispatcherService.runNextTask();
		}
	}

	/**
	 * Special class that can work as a job ar as a class
	 * Serves to map Divisions
	 */
	public class CBMapDivisions extends CBInitWizardService {
		public CBMapDivisions() {
			type = 'divisions';
		}

		public void doMapping(List<sObject> listOfSourceDivisions) {
			if (listOfSourceDivisions == null || listOfSourceDivisions.size() == 0) {
				return;
			}
			updateDivisions(listOfSourceDivisions);
		}

		private void updateDivisions(List<sObject> listOfSourceDivisions) {
			try {
				Set<String> externalIds = new Set<String>();
				for (sObject obj : listOfSourceDivisions) {
					externalIds.add(obj.Id);
				}
				Map<String, CBDivision__c> divisionMap = getDivisionMap(externalIds);
				for (sObject obj : listOfSourceDivisions) {
					CBDivision__c respectiveDivision = divisionMap.get(obj.Id);
					if (respectiveDivision == null) {
						respectiveDivision = new CBDivision__c();
					}
					respectiveDivision.ExtId__c = obj.Id;
					respectiveDivision.Name = (String) obj.get(mapping.cblight__SourceName__c);
					divisionMap.put(obj.Id, respectiveDivision);
				}
				fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
						new List<SObjectType>{
								CBDivision__c.SObjectType
						}
				);
				uow.registerUpsert(divisionMap.values());
				uow.commitWork();
			} catch (Exception e) {
				throw new CBException(e, 'Create Divisions Error: ' + e.getLineNumber() + ' -> ' + e.getMessage());
			}
		}

		public void finishMapping() {
			CBTaskDispatcherService.runNextTask();
		}

		/**
		 * map of applicable in this operation CBDivisions
		 * key - is external id (id of source record) and value is respective CBDivision__c
		 * @param externalIds list of source record Ids
		 *
		 * @return
		 */
		private Map<String, CBDivision__c> getDivisionMap(Set<String> externalIds) {
			Map<String, CBDivision__c> r = new Map<String, CBDivision__c>();
			for (CBDivision__c d : new CBDivisionSelector().getDivisionRecordByExtId(externalIds)) {
				r.put(d.ExtId__c, d);
			}
			return r;
		}
	}

	/**
	 * Special class that can work as a job ar as a class
	 * Serves to map Accounts
	 */
	public with sharing class CBMapPeriods extends CBInitWizardService {
		public CBMapPeriods() {
			type = 'periods';
			BYIsDate = mapping.SourceSubtype__c == null;
		}

		private Map<String, CBBudgetYear__c> byMap; // existing BY records
		private Boolean BYIsDate;

		public void doMapping(List<sObject> listOfSourcePeriods) {
			if (listOfSourcePeriods == null || listOfSourcePeriods.size() == 0) {
				return;
			}
			updateBudgetYears(listOfSourcePeriods);
			updatePeriods(listOfSourcePeriods);
		}

		/**
		 * The method updates the CBPeriod__c records
		 *
		 * @param listOfSourcePeriods
		 */
		private void updatePeriods(List<sObject> listOfSourcePeriods) {
			try {
				// if period does not have a lookup to a budget year
				Map<String, CBPeriod__c> existingPeriods = getExistingPeriods(listOfSourcePeriods);
				CBPeriod__c respectivePeriod;
				String extKey, BYExtKey;
				for (sObject obj : listOfSourcePeriods) {
					extKey = String.valueOf(obj.Id);
					respectivePeriod = existingPeriods.get(extKey);
					byExtKey = getBYExtKey(obj, BYIsDate);
					if (respectivePeriod == null) {
						respectivePeriod = new CBPeriod__c();
					}
					respectivePeriod.Name = (String) obj.get(mapping.cblight__SourceName__c);
					respectivePeriod.ExtId__c = extKey;
					respectivePeriod.Start__c = (Date) obj.get(mapping.cblight__SourceType__c);
					respectivePeriod.End__c = respectivePeriod.Start__c.addMonths(1).addDays(-1);
					respectivePeriod.CBBudgetYear__c = byMap.get(BYExtKey).Id;
					existingPeriods.put(extKey, respectivePeriod);
				}
				fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
						new List<SObjectType>{
								CBPeriod__c.SObjectType
						}
				);
				uow.registerUpsert(existingPeriods.values());
				uow.commitWork();
			} catch (Exception e) {
				throw new CBException(e, 'Create Periods Error: ' + e.getLineNumber() + ' -> ' + e.getMessage());
			}
		}

		/**
		 * The method creates missed CBBudgetYear__c records and populate the byMap with the updated records
		 *
		 * @param listOfSourcePeriods
		 */
		private void updateBudgetYears(List<sObject> listOfSourcePeriods) {
			try {
				byMap = new Map<String, CBBudgetYear__c>();
				for (CBBudgetYear__c byr : new CBBudgetYearSelector().getBudgetYears(null)) {
					byMap.put(byr.ExtId__c, byr);
					byMap.put(byr.Name, byr);
				}
				String extKey;
				for (sObject obj : listOfSourcePeriods) {
					extKey = getBYExtKey(obj, BYIsDate);
					if (byMap.get(extKey) == null) {
						Date periodStartDate = (Date) obj.get(mapping.cblight__SourceType__c);
						Date yearStartDate = Date.newInstance(periodStartDate.year(), 1, 1);
						CBBudgetYear__c newBY = new CBBudgetYear__c(Name = extKey, ExtId__c = extKey, Start__c = yearStartDate);
						byMap.put(extKey, newBY);
					}
				}
				Set<CBBudgetYear__c> bySet = new Set<CBBudgetYear__c>(byMap.values());
				tryToUpdateBYNames(bySet);
				fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
						new List<SObjectType>{
								CBBudgetYear__c.SObjectType
						}
				);
				uow.registerUpsert(new List<CBBudgetYear__c>(bySet));
				uow.commitWork();
			} catch (Exception e) {
				throw new CBException(e, 'Update Budget Years Error: ' + e.getLineNumber() + ' -> ' + e.getMessage());
			}
		}

		private void tryToUpdateBYNames(Set<CBBudgetYear__c> bySet) {
			Set<Id> byIds = new Set<Id>();
			Map<String, String> idNameMap = new Map<String, String>();
			for (CBBudgetYear__c b : bySet) {
				if (b.Name instanceOf Id) {
					byIds.add(b.Name);
				}
			}
			if (byIds.size() > 0) {
				String sobjectTypeString = new List<Id>(byIds)[0].getSObjectType().getDescribe().getName();
				Schema.SObjectType sobjectType = new List<Id>(byIds)[0].getSObjectType();
				CBSobjectSelector sobSel = new CBSobjectSelector(sobjectType, false).selectFieldsByNames(new List<String>{
						'Id', 'Name'
				});
				for (sObject sobj : sobSel.getSobjects('Id IN ' + CBUtils.getFormattedINQuery(byIds))) {
					idNameMap.put(sobj.Id, (String) sobj.get('Name'));
				}
				for (CBBudgetYear__c b : bySet) {
					String name = idNameMap.get(b.Name);
					if (name == null) {
						continue;
					}
					b.Name = name;
				}
			}
		}

		/**
		 * @param obj external period object
		 * @param BYIsDate true if period has Date instead of Lookup
		 *
		 * @return the key of external record BY
		 */
		private String getBYExtKey(sObject obj, Boolean BYIsDate) {
			if (BYIsDate) {
				Date periodStartDate = (Date) obj.get(mapping.cblight__SourceType__c);
				return String.valueOf(periodStartDate.year());
			} else {
				return (String) obj.get(mapping.cblight__SourceSubtype__c);
			}
		}

		/**
		 * @param listOfSourcePeriods
		 *
		 * @return map where key is ID or Date if source periods do not have lookup to BY
		 */
		private Map<String, CBPeriod__c> getExistingPeriods(List<sObject> listOfSourcePeriods) {
			Map<String, CBPeriod__c> r = new Map<String, CBPeriod__c>();
			Set<String> extIds = new Set<String>();
			for (sObject obj : listOfSourcePeriods) {
				extIds.add(obj.Id);
			}
			for (CBPeriod__c p : new CBPeriodSelector().getPeriods(' cblight__ExtId__c IN ' + CBUtils.getFormattedINQuery(extIds))) {
				r.put(p.ExtId__c, p);
			}
			return r;
		}

		public void finishMapping() {
			CBTaskDispatcherService.runNextTask();
		}
	}

	/**
	 * Special class that can work as a job ar as a class
	 * Serves to map Variables
	 */
	public class CBMapVariables extends CBInitWizardService {
		public CBMapVariables(Integer i) {
			index = i;
			type = 'variables' + i;
		}

		private Integer index;

		public void doMapping(List<sObject> listOfSourceVariables) {
			if (listOfSourceVariables == null || listOfSourceVariables.size() == 0) {
				return;
			}
			updateVariables(listOfSourceVariables);
		}

		private void updateVariables(List<sObject> listOfSourceVariables) {
			try {
				Set<String> externalIds = new Set<String>();
				for (sObject obj : listOfSourceVariables) {
					externalIds.add(obj.Id);
				}
				Map<String, CBVariableSelector.VariableWrapper> variableMap = getVariableMap(externalIds);
				for (sObject obj : listOfSourceVariables) {
					CBVariableSelector.VariableWrapper respectiveVariable = variableMap.get(obj.Id);
					if (respectiveVariable == null) {
						respectiveVariable = new CBVariableSelector.VariableWrapper(index);
					}
					respectiveVariable.ExtId = obj.Id;
					respectiveVariable.Name = (String) obj.get(mapping.cblight__SourceName__c);
					variableMap.put(obj.Id, respectiveVariable);
				}
				List<sObject> variablesToUpsert = new List<sObject>();
				Set<Schema.SObjectType> typeSet = new Set<Schema.SObjectType>();
				for (CBVariableSelector.VariableWrapper var : variableMap.values()) {
					SObject record = var.getRecord();
					typeSet.add(record.getSObjectType());
					variablesToUpsert.add(record);
				}
				fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
						new List<Schema.SObjectType>(typeSet)
				);
				uow.registerUpsert(variablesToUpsert);
				uow.commitWork();
			} catch (Exception e) {
				throw e;
				//throw new CBException(e, 'Create VariableX Error: ' + e.getLineNumber() + ' -> ' + e.getMessage());
			}
		}

		public void finishMapping() {
			CBTaskDispatcherService.runNextTask();
		}

		/**
		 * map of applicable in this operation CBVariableX__c
		 * key - is external id (id of source record) and value is respective CBVariableX__c
		 * @param externalIds list of source record Ids
		 *
		 * @return
		 */
		private Map<String, CBVariableSelector.VariableWrapper> getVariableMap(Set<String> externalIds) {
			Map<String, CBVariableSelector.VariableWrapper> r = new Map<String, CBVariableSelector.VariableWrapper>();
			String filter = ' cblight__ExtId__c IN ' + CBUtils.getFormattedINQuery(externalIds) + ' ';
			for (CBVariableSelector.VariableWrapper wrapper : new CBVariableSelector().setIndex(index).getVariablesByFilter(filter)) {
				r.put(wrapper.ExtId, wrapper);
			}
			return r;
		}
	}

	/**
	 * Realization of the interface in general
	 */
	public class CBMapGeneral extends CBInitWizardService {
		public CBMapGeneral(String type) {
			this.type = type;
		}

		public void doMapping(List<sObject> listOfSourceRecords) {
		}

		public void finishMapping() {
			CBTaskDispatcherService.runNextTask();
		}
	}
}