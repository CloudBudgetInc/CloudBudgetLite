/**
 * Copyright (c) 2022, CloudBudget, Inc.
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
 * The method for creating initial data
 * #INITIAL DATA
 * <p/>
 * To generate data make 2 steps:
 * -run setupData()
 * -run generateData()
 */
public with sharing class CBInitialTestDataService {
	private static List<CBBudgetYear__c> mockBYs = new List<CBBudgetYear__c>();
	private static List<CBPeriod__c> mockPeriods = new List<CBPeriod__c>();
	private static List<CBDivision__c> mockDivisions = new List<CBDivision__c>();
	private static List<CBSubAccount__c> mockSubAccountsExpense = new List<CBSubAccount__c>();
	private static List<CBSubAccount__c> mockSubAccountsIncome = new List<CBSubAccount__c>();
	private static CBAccountType__c mockAccountTypeIncome;
	private static CBAccountType__c mockAccountTypeExpense;
	private static List<CBAccount__c> mockAccounts = new List<CBAccount__c>();
	private static List<CBBudgetLine__c> mockBudgetLines = new List<CBBudgetLine__c>();
	private static List<CBAmount__c> mockAmounts = new List<CBAmount__c>();
	private static List<CBInvoice__c> mockInvoices = new List<CBInvoice__c>();
	private static List<CBInvoiceLine__c> mockInvoiceLines = new List<CBInvoiceLine__c>();
	private static List<CBCube__c> mockCubes = new List<CBCube__c>();
	private static List<CBReport__c> mockReports = new List<CBReport__c>();
	private static List<CBReportConfiguration__c> mockReportConfigurations = new List<CBReportConfiguration__c>();
	private static List<CBReportColumn__c> mockColumns = new List<CBReportColumn__c>();
	private static List<CBVariable1__c> mockVariables1 = new List<CBVariable1__c>();
	private static List<CBVariable2__c> mockVariables2 = new List<CBVariable2__c>();
	private static final List<String> MONTHS = new List<String>{
			'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEPT', 'OCT', 'NOV', 'DEC'
	};
	private static final Map<String, List<String>> ACCOUNT_SUBTYPE_AND_ACCOUNTS_EXPENSE = new Map<String, List<String>>{
			'Operational' => new List<String>{
					'Rent', 'Advertising', 'Insurance', 'Inventory', 'Equipment', 'Entertainment', 'Bank', 'Property Tax'
			},
			'Other' => new List<String>{
					'Repairs & Maintenance', 'Conveyance', 'Printing', 'Other'
			},
			'Travel' => new List<String>{
					'Meal', 'Airfare', 'Hotel', 'Taxi', 'Car rent'
			},
			'Wage' => new List<String>{
					'Salary', 'Bonus', 'Overhead', 'Compensation'
			},
			'COGS' => new List<String>{
					'Freight in', 'Freight out', 'Product Cost', 'Others Costs'
			}
	};

	private static final Map<String, List<String>> ACCOUNT_SUBTYPE_AND_ACCOUNTS_INCOME = new Map<String, List<String>>{
			'Sales' => new List<String>{
					'Licenses', 'Franchise', 'Main Product', 'Sub Product', 'Equipment'
			},
			'Support' => new List<String>{
					'Implementation', 'Service', 'Consultation', 'Support'
			}
	};

	private static fflib_SObjectUnitOfWork uow {
		get {
			if (uow == null) {
				uow = new fflib_SObjectUnitOfWork(
						new List<SObjectType>{
								PermissionSetAssignment.SObjectType,
								CBWelcome__c.SObjectType,
								CBTransaction__c.SObjectType,
								CBModelingLine__c.SObjectType,
								CBModelingRule__c.SObjectType,
								CBModelingRuleGroup__c.SObjectType,
								CBNonFinancialLibrary__c.SObjectType,
								CBLayer__c.SObjectType,
								CBStyle__c.SObjectType,
								CBClusterRule__c.SObjectType,
								CBBudgetYear__c.SObjectType,
								CBPeriod__c.SObjectType,
								CBDivision__c.SObjectType,
								CBSubAccount__c.SObjectType,
								CBAccountType__c.SObjectType,
								CBAccount__c.SObjectType,
								CBBudgetLine__c.SObjectType,
								CBAmount__c.SObjectType,
								CBInvoice__c.SObjectType,
								CBInvoiceLine__c.SObjectType,
								CBCube__c.SObjectType,
								CBReport__c.SObjectType,
								CBReportConfiguration__c.SObjectType,
								CBReportColumn__c.SObjectType,
								CBVariable1__c.SObjectType,
								CBVariable2__c.SObjectType,
								CBOrgVariable__c.SObjectType
						}
				);
			}
			return uow;
		}
		set;
	}

	/**
	 * Step 1 Assign permissions and another setup data
	 * DML operation on setup object is not permitted after you have updated a non-setup object (or vice versa)
	 */
	public static void setupData() {
		if (stopDuplication())
			return;
		assignPermissionSet();
	}
	/**
	 * STEP 2
	 * Set Data
	 */
	public static void generateData() {
		if (stopDuplication()) {
			return;
		}
		generateOrgVariable();
		generateDivisions();
		uow.commitWork();
		uow = null;
		generateBYAndPeriods();
		uow.commitWork();
		uow = null;
		generateAccountTypes();
		generateSubAccount();
		generateAccounts();
		generateCBVariable1();
		generateCBVariable2();
		uow.commitWork();
		uow = null;

		generateBudgetLines();
		generateInvoices();
		generateClusterRule();
		generateCBReportingSystem();
		CBStyleService.insertDefaultStyleServer(new List<CBAccountType__c>{
				mockAccountTypeIncome, mockAccountTypeExpense
		});
		generateWelcomeMats();
		uow.commitWork();
		uow = null;
	}

	/**
	 * The method prevent doubling of data
	 *
	 * @return true if BY existing
	 */
	private static Boolean stopDuplication() {
		return [
				SELECT Id
				FROM CBBudgetYear__c
		].size() > 0;
	}

	public static Map<String, List<CBPeriod__c>> periodMap {
		get {
			if (periodMap == null) {
				periodMap = new Map<String, List<CBPeriod__c>>();
				for (CBPeriod__c per : mockPeriods) {
					List<CBPeriod__c> periods = periodMap.get(per.CBBudgetYear__c);
					if (periods == null) {
						periods = new List<CBPeriod__c>();
						periodMap.put(per.CBBudgetYear__c, periods);
					}
					periods.add(per);
				}
			}
			return periodMap;
		}
		set;
	}

	/**
	 * Creates period and budget years
	 */
	public static void generateBYAndPeriods() {
		mockBYs.add(new CBBudgetYear__c(Name = '2023', Start__c = Date.newInstance(2023, 1, 1)));
		mockBYs.add(new CBBudgetYear__c(Name = '2024', Start__c = Date.newInstance(2024, 1, 1)));
		uow.registerNew(mockBYs);
		for (CBBudgetYear__c bfy : mockBYs) {
			Integer year = bfy.Start__c.year();
			for (Integer i = 0; i < 12; i++) {
				CBPeriod__c newPeriod = new CBPeriod__c(Name = MONTHS[i] + ' ' + year, Start__c = Date.newInstance(year, i + 1, 1), End__c = Date.newInstance(year, i + 2, 1).addDays(-1));
				uow.registerNew(newPeriod, CBPeriod__c.CBBudgetYear__c, bfy);
				mockPeriods.add(newPeriod);
			}
		}
	}

	/**
	 * Method generates an org variable
	 */
	public static void generateOrgVariable() {
		if ([SELECT Id FROM CBOrgVariable__c WITH SECURITY_ENFORCED].size() > 0) {
			return;
		}
		uow.registerNew(new CBOrgVariable__c(Name = 'Default', CBVariable1Label__c = 'Vendor', CBVariable2Label__c = 'Product'));
	}

	/**
	 * Method generates a list of divisions
	 */
	public static void generateDivisions() {
		for (String str : new String[]{
				'Marketing', 'Operations'
		}) {
			mockDivisions.add(new CBDivision__c(Name = str + ' Dpt'));
		}
		uow.registerNew(mockDivisions);
	}

	/**
	 * account type is a parent of Account
	 */
	public static void generateAccountTypes() {
		mockAccountTypeIncome = new CBAccountType__c(Name = 'Income', Sign__c = '-');
		mockAccountTypeExpense = new CBAccountType__c(Name = 'Expense', Sign__c = '+');
		List<CBAccountType__c> types = new List<CBAccountType__c>();
		types.add(mockAccountTypeIncome);
		types.add(mockAccountTypeExpense);
		uow.registerNew(types);
	}

	/**
	 * Generates subAccounts
	 */
	public static void generateSubAccount() {
		for (String str : ACCOUNT_SUBTYPE_AND_ACCOUNTS_EXPENSE.keySet()) {
			mockSubAccountsExpense.add(new CBSubAccount__c(Name = str));
		}
		for (String str : ACCOUNT_SUBTYPE_AND_ACCOUNTS_INCOME.keySet()) {
			mockSubAccountsIncome.add(new CBSubAccount__c(Name = str));
		}
		uow.registerNew(mockSubAccountsExpense);
		uow.registerNew(mockSubAccountsIncome);
	}

	/**
	 * Generate 5 accounts for each subAccount
	 */
	public static void generateAccounts() {
		for (CBSubAccount__c subAccount : mockSubAccountsExpense) {
			for (String accountName : ACCOUNT_SUBTYPE_AND_ACCOUNTS_EXPENSE.get(subAccount.Name)) {
				CBAccount__c acc = new CBAccount__c(Name = accountName);
				uow.registerNew(acc, CBAccount__c.CBAccountType__c, mockAccountTypeExpense);
				uow.registerRelationship(acc, CBAccount__c.CBSubAccount__c, subAccount);
				mockAccounts.add(acc);
			}
		}
		for (CBSubAccount__c subAccount : mockSubAccountsIncome) {
			for (String accountName : ACCOUNT_SUBTYPE_AND_ACCOUNTS_INCOME.get(subAccount.Name)) {
				CBAccount__c acc = new CBAccount__c(Name = accountName);
				uow.registerNew(acc, CBAccount__c.CBAccountType__c, mockAccountTypeIncome);
				uow.registerRelationship(acc, CBAccount__c.CBSubAccount__c, subAccount);
				mockAccounts.add(acc);
			}
		}
	}

	/**
	 * Generates list of budget lines
	 */
	private static void generateBudgetLines() {
		for (CBBudgetYear__c bfy : mockBYs) { // iteration over BY
			for (CBDivision__c div : mockDivisions) { // iteration over division
				for (Integer i = 0; i < 11; i++) {
					CBBudgetLine__c bl = new CBBudgetLine__c(
							CBBudgetYear__c = bfy.Id,
							CBDivision__c = div.Id,
							CBAccount__c = mockAccounts[i].Id,
							Code__c = '1' + i,
							CBVariable1__c = getRandomRecord(mockVariables1),
							CBVariable2__c = getRandomRecord(mockVariables2),
							Name = mockAccounts[i].Name + ' #' + i);
					uow.registerNew(bl, CBBudgetLine__c.CBBudgetYear__c, bfy);
					uow.registerRelationship(bl, CBBudgetLine__c.CBDivision__c, div);
					uow.registerRelationship(bl, CBBudgetLine__c.CBAccount__c, mockAccounts[i]);
					mockBudgetLines.add(bl);
				}
			}
		}
		for (CBBudgetLine__c bLine : mockBudgetLines) {
			List<CBPeriod__c> periods = periodMap.get(bLine.CBBudgetYear__c);
			for (CBPeriod__c period : periods) {
				CBAmount__c amount = new CBAmount__c(Value__c = getRealisticAmount());
				uow.registerNew(amount, CBAmount__c.CBPeriod__c, period);
				uow.registerRelationship(amount, CBAmount__c.CBBudgetLine__c, bLine);
				mockAmounts.add(amount);
			}
		}
	}

	private static void generateInvoices() {
		for (CBBudgetYear__c bfy : mockBYs) { // iteration over BY
			List<CBPeriod__c> periods = periodMap.get(bfy.Id);
			for (CBDivision__c div : mockDivisions) { // iteration over division
				for (Integer i = 0; i < 5; i++) {
					CBInvoice__c invoice = new CBInvoice__c(
							CBDivision__c = div.Id,
							CBAccount__c = mockAccounts[i].Id,
							CBVariable1__c = getRandomRecord(mockVariables1),
							CBVariable2__c = getRandomRecord(mockVariables2),
							CBPeriod__c = getRandomRecord(periods),
							Name = mockAccounts[i].Name + ' #' + i);
					uow.registerNew(invoice);
					mockInvoices.add(invoice);
				}
			}
		}
		for (CBInvoice__c invoice : mockInvoices) {
			for (Integer i = 0; i < 3; i++) {
				CBInvoiceLine__c invoiceLine = new CBInvoiceLine__c(Amount__c = getRealisticAmount(), Name = '-');
				uow.registerNew(invoiceLine);
				uow.registerRelationship(invoiceLine, CBInvoiceLine__c.CBInvoice__c, invoice);
				mockInvoiceLines.add(invoiceLine);
			}
		}
	}

	public static void multiplyBudgetLines() {
		List<CBBudgetLine__c> blList = new CBBudgetLineSelector().getBudgetLines(null);
		Map<CBBudgetLine__c, List<CBAmount__c>> newBLMap = new Map<CBBudgetLine__c, List<CBAmount__c>>();
		for (CBBudgetLine__c bl : blList) {
			List<CBAmount__c> amounts = bl.CBAmounts__r;
			List<CBAmount__c> newAmounts = new List<CBAmount__c>();
			for (CBAmount__c a : amounts) {
				newAmounts.add(a.clone(false, true, false, false));
			}
			CBBudgetLine__c newBL = bl.clone(false, true, false, false);
			newBLMap.put(newBL, newAmounts);
		}
		uow.registerNew(new List<CBBudgetLine__c> (newBLMap.keySet()));
		List<CBAmount__c> updatedAmounts = new List<CBAmount__c>();

		List<CBBudgetLine__c> keys = new List<CBBudgetLine__c> (newBLMap.keySet());
		List<List<CBAmount__c>> amounts = newBLMap.values();

		for (Integer i = 0; i < keys.size(); i++) {
			CBBudgetLine__c bl = keys[i];
			List<CBAmount__c> newAmounts = amounts[i];

			for (CBAmount__c a : newAmounts) {
				uow.registerNew(a, CBAmount__c.CBBudgetLine__c, bl);
			}
			updatedAmounts.addAll(newAmounts);
		}
	}

	public static void generateClusterRule() {
		List<CBClusterRule__c> mockClusterRules = new List<CBClusterRule__c>();
		mockClusterRules.add(new CBClusterRule__c(Name = 'Division', Level1__c = 'cblight__CBDivision__c'));
		mockClusterRules.add(new CBClusterRule__c(Name = 'Division/SubAccount', Level1__c = 'cblight__CBDivision__c', Level2__c = 'cblight__CBSubAccountName__c'));
		mockClusterRules.add(new CBClusterRule__c(Name = 'Division/Status', Level1__c = 'cblight__CBDivision__c', Level2__c = 'cblight__Status__c'));
		mockClusterRules.add(new CBClusterRule__c(Name = 'SubAccount/Division', Level1__c = 'cblight__CBSubAccountName__c', Level2__c = 'cblight__CBDivision__c'));
		mockClusterRules.add(new CBClusterRule__c(Name = 'Division/Vendor', Level1__c = 'cblight__CBDivision__c', Level2__c = 'cblight__CBVariable1__c'));
		mockClusterRules.add(new CBClusterRule__c(Name = 'Division/Product', Level1__c = 'cblight__CBDivision__c', Level2__c = 'cblight__CBVariable2__c'));
		uow.registerNew(mockClusterRules);
	}

	public static void generateModelingRules() {
		cblight__CBModelingRuleGroup__c budgetToCube = new cblight__CBModelingRuleGroup__c(Name = 'Budget Lines To Cubes', DeleteOldResults__c = true);
		cblight__CBModelingRuleGroup__c budgetToForecast = new cblight__CBModelingRuleGroup__c(Name = 'Budget Lines Base to Forecast', DeleteOldResults__c = true);
		cblight__CBModelingRuleGroup__c rollingForecast = new cblight__CBModelingRuleGroup__c(Name = 'Rolling Forecast', DeleteOldResults__c = false);
		List<cblight__CBModelingRuleGroup__c> modelingGroups = new List<CBModelingRuleGroup__c>();
		modelingGroups.add(budgetToCube);
		modelingGroups.add(budgetToForecast);
		modelingGroups.add(rollingForecast);
		uow.registerNew(modelingGroups);
		uow.commitWork();
		uow = null;
		List<cblight__CBModelingRule__c> modelingRules = new List<CBModelingRule__c>();
		// Budget lints to Cube
		cblight__CBModelingRule__c BTCModRule = new cblight__CBModelingRule__c(Name = 'Budget Lines to Cubes', cblight__CBModelingRuleGroup__c = budgetToCube.Id,
				cblight__Description__c = 'Budget Lines to Cubes', cblight__SourceRecordParentType__c = 'cblight__CBBudgetLine__c', cblight__SourceRecordChildType__c = 'cblight__CBAmount__c',
				cblight__KeyFields__c = 'cblight__CBAccount__c,cblight__CBDivision__c,cblight__CBVariable1__c,cblight__CBVariable2__c',
				cblight__ResultRecordParentType__c = 'cblight__CBCube__c');
		// Budget Lines to Forecast
		cblight__CBModelingRule__c BTFModRule = new cblight__CBModelingRule__c(Name = 'CB Budget Lines Base to Forecast', cblight__CBModelingRuleGroup__c = budgetToForecast.Id,
				cblight__Description__c = 'CB Budget Lines Base to Forecast', cblight__SourceRecordParentType__c = 'cblight__CBBudgetLine__c', cblight__SourceRecordChildType__c = 'cblight__CBAmount__c',
				cblight__KeyFields__c = 'cblight__CBAccount__c,cblight__CBDivision__c,cblight__CBVariable1__c,cblight__CBVariable2__c',
				cblight__ResultRecordParentType__c = 'cblight__CBBudgetLine__c', ResultRecordChildType__c = 'cblight__CBAmount__c');
		// Budget Lines Delete first month
		cblight__CBModelingRule__c RFDModRule = new cblight__CBModelingRule__c(Name = 'Deleting first quarter', cblight__CBModelingRuleGroup__c = rollingForecast.Id,
				cblight__Description__c = 'Deleting first quarter', cblight__SourceRecordParentType__c = 'cblight__CBAmount__c',
				cblight__ResultRecordParentType__c = 'cblight__CBBudgetLine__c', cblight__KeyFields__c = 'cblight__CBAccount__c,cblight__CBDivision__c,cblight__CBVariable1__c,cblight__CBVariable2__c',
				SourceParentFilter__c = 'cblight__CBPeriod__c = \'' + mockPeriods[0].Id + '\'');
		// Budget Line - update first line
		cblight__CBModelingRule__c GNRModRule = new cblight__CBModelingRule__c(Name = 'Generating new amounts', cblight__CBModelingRuleGroup__c = rollingForecast.Id,
				cblight__Description__c = 'Generating new amounts', cblight__SourceRecordParentType__c = 'cblight__CBTransaction__c',
				SourceParentFilter__c = 'cblight__CBPeriod__c = \'' + mockPeriods[0].Id + '\'',
				cblight__KeyFields__c = 'cblight__CBAccount__c,cblight__CBDivision__c,cblight__CBVariable1__c,cblight__CBVariable2__c',
				cblight__ResultRecordParentType__c = 'cblight__CBBudgetLine__c', ResultRecordChildType__c = 'cblight__CBAmount__c');

		modelingRules.add(BTCModRule);
		modelingRules.add(BTFModRule);
		modelingRules.add(RFDModRule);
		modelingRules.add(GNRModRule);
		uow.registerNew(modelingRules);
		uow.commitWork();
		uow = null;
		List<cblight__CBModelingLine__c> modelingLines = new List<CBModelingLine__c>();
		List<cblight__CBModelingLine__c> mrLinesBaseList = getBasicModelingLines();

		modelingLines.addAll(updateAndGroupModelingLines(mrLinesBaseList, BTCModRule.Id, true));
		modelingLines.addAll(updateAndGroupModelingLines(mrLinesBaseList, BTFModRule.Id, false));
		modelingLines.addAll(updateAndGroupModelingLines(mrLinesBaseList, GNRModRule.Id, false));
		uow.registerNew(modelingLines);
	}

	private static List<cblight__CBModelingLine__c> updateAndGroupModelingLines(List<cblight__CBModelingLine__c> mls, Id mrId, Boolean resultIsCube) {
		List<cblight__CBModelingLine__c> r = new List<CBModelingLine__c>();
		for (cblight__CBModelingLine__c ml : mls) {
			cblight__CBModelingLine__c tmlMl = ml.clone(false, false, false, false);
			if (resultIsCube) {
				tmlMl.cblight__ResultFieldFrom__c = 'Parent';
				if (tmlMl.Name == 'Value') {
					tmlMl.cblight__ResultField__c = 'cblight__Budget__c';
				}
			}
			tmlMl.CBModelingRule__c = mrId;
			r.add(tmlMl);
		}
		return r;
	}

	private static List<cblight__CBModelingLine__c> getBasicModelingLines() {
		cblight__CBModelingLine__c nameLine = new cblight__CBModelingLine__c(cblight__SourceField__c = 'Name', Name = 'Name', cblight__SourceFieldFrom__c = 'Parent',
				Type__c = 'STRING', cblight__ResultField__c = 'Name', cblight__ResultFieldFrom__c = 'Parent');
		cblight__CBModelingLine__c divisionLine = new cblight__CBModelingLine__c(cblight__SourceField__c = 'cblight__CBDivision__c', Name = 'Division', cblight__SourceFieldFrom__c = 'Parent',
				Type__c = 'REFERENCE', cblight__ResultField__c = 'cblight__CBDivision__c', cblight__ResultFieldFrom__c = 'Parent');
		cblight__CBModelingLine__c accountLine = new cblight__CBModelingLine__c(cblight__SourceField__c = 'cblight__CBAccount__c', Name = 'Account', cblight__SourceFieldFrom__c = 'Parent',
				Type__c = 'REFERENCE', cblight__ResultField__c = 'cblight__CBAccount__c', cblight__ResultFieldFrom__c = 'Parent');
		cblight__CBModelingLine__c periodLine = new cblight__CBModelingLine__c(cblight__SourceField__c = 'cblight__CBPeriod__c', Name = 'Period', cblight__SourceFieldFrom__c = 'Child',
				Type__c = 'REFERENCE', cblight__ResultField__c = 'cblight__CBPeriod__c', cblight__ResultFieldFrom__c = 'Child');
		cblight__CBModelingLine__c variable1Line = new cblight__CBModelingLine__c(cblight__SourceField__c = 'cblight__CBVariable1__c', Name = 'Variable 1', cblight__SourceFieldFrom__c = 'Parent',
				Type__c = 'REFERENCE', cblight__ResultField__c = 'cblight__CBVariable1__c', cblight__ResultFieldFrom__c = 'Parent');
		cblight__CBModelingLine__c variable2Line = new cblight__CBModelingLine__c(cblight__SourceField__c = 'cblight__CBVariable2__c', Name = 'Variable 2', cblight__SourceFieldFrom__c = 'Parent',
				Type__c = 'REFERENCE', cblight__ResultField__c = 'cblight__CBVariable2__c', cblight__ResultFieldFrom__c = 'Parent');
		cblight__CBModelingLine__c valueLine = new cblight__CBModelingLine__c(cblight__SourceField__c = 'cblight__Value__c', Name = 'Value', cblight__SourceFieldFrom__c = 'Child',
				Type__c = 'DOUBLE', cblight__ResultField__c = 'cblight__Value__c', cblight__ResultFieldFrom__c = 'Child');
		return new List<cblight__CBModelingLine__c>{
				nameLine, divisionLine, accountLine, periodLine, valueLine, variable1Line, variable2Line
		};
	}

	/**
	 * Creates all combinations of Division, Account, BY and Periods
	 */
	public static void generateCBCubes() {
		for (CBDivision__c division : mockDivisions) {
			for (CBAccount__c account : mockAccounts) {
				for (CBBudgetYear__c bfy : mockBYs) {
					List<CBPeriod__c> periods = periodMap.get(bfy.Id);
					for (CBPeriod__c period : periods) {
						addNewCBCube(division, account, bfy, period);
					}
				}
			}
		}
		uow.registerNew(mockCubes);
	}

	public static void generateCBReportingSystem() {
		CBStyleSelector ds = new CBStyleSelector();
		Map<String, String> styleMap = ds.getStylesMap();
		String generalColumnStyleId = styleMap.get('GeneralColumn');
		String unit = '$';
		mockReports.add(new CBReport__c(Name = 'Profit and Loss (auto)', Mode__c = 'Auto', needQuarterTotals__c = true));
		mockReports.add(new CBReport__c(Name = 'Profit and Loss (manual)', Mode__c = 'Manual'));
		uow.registerNew(mockReports);
		CBReportConfiguration__c rep1 = new CBReportConfiguration__c(Name = 'General Auto', Grouping__c = '["cblight__CBDivision__c","cblight__CBAccount__c"]',
				SubtotalNumber__c = 1, Filter__c = 'cblight__CBBudgetYear__c = \'' + mockBYs[0].Id + '\' ');
		uow.registerNew(rep1, CBReportConfiguration__c.CBReport__c, mockReports[0]);
		CBReportConfiguration__c rep2 = new CBReportConfiguration__c(Name = 'General Manual', Grouping__c = '["cblight__CBDivision__c","cblight__CBAccount__c"]',
				SubtotalNumber__c = 1, Filter__c = 'cblight__CBBudgetYear__c = \'' + mockBYs[0].Id + '\' ');
		uow.registerNew(rep2, CBReportConfiguration__c.CBReport__c, mockReports[1]);
		mockReportConfigurations.add(rep1);
		mockReportConfigurations.add(rep2);

		CBReportColumn__c repCol1 = new CBReportColumn__c(Name = 'Budget', CBStyle__c = generalColumnStyleId, ValueField__c = 'cblight__Budget__c', OrderNumber__c = 1, Type__c = 'Master', Unit__c = unit);
		uow.registerNew(repCol1, CBReportColumn__c.CBReport__c, mockReports[0]);
		CBReportColumn__c repCol2 = new CBReportColumn__c(Name = 'Actual', CBStyle__c = generalColumnStyleId, ValueField__c = 'cblight__Actual__c', OrderNumber__c = 2, Type__c = 'Master', Unit__c = unit);
		uow.registerNew(repCol2, CBReportColumn__c.CBReport__c, mockReports[0]);
		mockColumns.add(repCol1);
		mockColumns.add(repCol2);

		List<CBPeriod__c> periods = periodMap.get(mockBYs[0].Id);
		for (Integer i = 0; i < periods.size(); i++) {
			String type = i < 2 ? 'Master' : 'Simple';
			CBReportColumn__c repCol11 = new CBReportColumn__c(Name = 'Budget', CBStyle__c = generalColumnStyleId, ValueField__c = 'cblight__Budget__c', OrderNumber__c = i + 1, Type__c = type, Unit__c = unit);
			uow.registerNew(repCol11, CBReportColumn__c.CBReport__c, mockReports[1]);
			uow.registerRelationship(repCol11, CBReportColumn__c.CBReport__c, mockReports[1]);
			uow.registerRelationship(repCol11, CBReportColumn__c.CBPeriod__c, periods[i]);
			CBReportColumn__c repCol22 = new CBReportColumn__c(Name = 'Actual', CBStyle__c = generalColumnStyleId, ValueField__c = 'cblight__Actual__c', OrderNumber__c = i + 1, Type__c = type, Unit__c = unit);
			uow.registerNew(repCol22, CBReportColumn__c.CBReport__c, mockReports[1]);
			uow.registerRelationship(repCol22, CBReportColumn__c.CBPeriod__c, periods[i]);
			mockColumns.add(repCol11);
			mockColumns.add(repCol22);
		}
	}

	public static void generateCBVariable1() {
		for (String r : new String []{
				'KFT Fund', 'GPF Fund', 'OTP Fund', 'FlightRadar Fund', 'Store Fund', 'Reserve', 'RestSolution Fund', 'SlipFrog Fund', 'Base Fund', 'Other Funds'
		}) {
			mockVariables1.add(new cblight__CBVariable1__c(Name = r));
		}
		uow.registerNew(mockVariables1);
	}

	public static void generateCBVariable2() {
		for (String r : new String []{
				'Research', 'Registration', 'Marketing', 'Other', 'License', 'Commission', 'Compensation', 'Educational Support', 'Computer Services', 'Overtime', 'Rent Payments', 'Travel'
		}) {
			mockVariables2.add(new cblight__CBVariable2__c(Name = r));
		}
		uow.registerNew(mockVariables2);
	}

	private static Id getRandomRecord(List<SObject> arr) {
		return arr[Integer.valueOf((Math.random() / 2 * 10).round())].Id;
	}

	@AuraEnabled
	public static void generateWelcomeMats() {

		CBWelcome__c modelingRule = new CBWelcome__c(Name = 'Modeling Rule', cblight__Header__c = 'Modeling Rule', cblight__Type__c = 'Lead', cblight__Description__c = 'Modeling rules serve to transform one data type into another data type. Allows you to set up forecasting, copying budgets, creating reports and much more');
		uow.registerNew(modelingRule);
		List<CBWelcome__c> mrWelcomes = new List<CBWelcome__c>();
		CBWelcome__c w1 = new CBWelcome__c(
				Name = 'General Info',
				Header__c = 'General Info',
				Description__c = 'Description',
				Content__c = '<div style="color: red">Modeling rules</div><div>Modeling rules serve to transform one data type into another data type. Allows you to set up forecasting, copying budgets, creating reports and much more</div>'
		);
		uow.registerNew(w1, CBWelcome__c.Parent__c, modelingRule);
		mrWelcomes.add(w1);
		CBWelcome__c w2 = new CBWelcome__c(
				Name = 'Create MR',
				Header__c = 'Creating',
				Description__c = 'There are several ways to create a modeling rule',
				Content__c = '<div style="text-align: left;"><div style="color: red, font-weight: bold">There are several ways to create a modeling rule</div><ul><li>Use create button</li><li>Clone existing</li><li>Generate from the pattern</li></ul></div>'
		);
		uow.registerNew(w2, CBWelcome__c.Parent__c, modelingRule);
		mrWelcomes.add(w2);


		CBWelcome__c period = new CBWelcome__c(Name = 'periods', cblight__Header__c = 'Period', cblight__Type__c = 'Lead', cblight__Description__c = 'Periods serve to create financial periods(months or quaters) for each budget year');
		uow.registerNew(period);
		List<CBWelcome__c> pWelcomes = new List<CBWelcome__c>();
		CBWelcome__c w3 = new CBWelcome__c(
				Name = 'General Info',
				cblight__Header__c = 'General Info',
				cblight__Description__c = 'Description',
				cblight__Content__c = '<div style="color: red">Periods</div><div>Periods serve are basic financial periods(Months or Quarters) for each budget year. You can set name and start/end date.(if no crossing with other period dates)</div>'
		);
		uow.registerNew(w3, CBWelcome__c.cblight__Parent__c, period);
		pWelcomes.add(w3);
		CBWelcome__c w4 = new CBWelcome__c(
				Name = 'Create Periods',
				cblight__Header__c = 'Creating',
				cblight__Description__c = 'Periods are created automaticaly',
				cblight__Content__c = '<div style="text-align: left;"><div style="color: red, font-weight: bold">Periods are created automaticaly when you are creating budget year.There are two types of periods </div><ul><li>Quarter</li><li>Month</li></ul></div>'
		);
		uow.registerNew(w4, CBWelcome__c.cblight__Parent__c, period);
		pWelcomes.add(w4);


		CBWelcome__c budgetYear = new CBWelcome__c(Name = 'Budget Year', cblight__Header__c = 'Budget Year', cblight__Type__c = 'Lead', cblight__Description__c = 'Budget Years are financial(fiscal) years');
		uow.registerNew(budgetYear);
		List<CBWelcome__c> bYWelcomes = new List<CBWelcome__c>();
		CBWelcome__c w5 = new CBWelcome__c(
				Name = 'General Info',
				cblight__Header__c = 'General Info',
				cblight__Description__c = 'Description',
				cblight__Content__c = '<div style="color: red">Budget Year</div><div>Budget Years serve to as basic financial budget year. You can set name and start date.(if no crossing with other BY dates)</div>'
		);
		uow.registerNew(w5, CBWelcome__c.cblight__Parent__c, budgetYear);
		bYWelcomes.add(w5);
		CBWelcome__c w6 = new CBWelcome__c(
				Name = 'Create BY',
				cblight__Header__c = 'Creating',
				cblight__Description__c = 'BY are created manually',
				cblight__Content__c = '<ul><li><div style="color: red">Budget Year</div></li><li><div>BY are created in menu Period Setup.</div></li><ul>'
		);
		uow.registerNew(w6, CBWelcome__c.cblight__Parent__c, budgetYear);
		bYWelcomes.add(w6);
	}

	private static void addNewCBCube(CBDivision__c division, CBAccount__c account, CBBudgetYear__c bfy, CBPeriod__c period) {
		CBCube__c newCube = new CBCube__c(CBDivision__c = division.Id, CBAccount__c = account.Id, CBBudgetYear__c = bfy.Id, CBPeriod__c = period.Id);
		newCube.Budget__c = getRealisticAmount();
		newCube.Actual__c = getRealisticAmount();
		mockCubes.add(newCube);
	}

	private static Decimal getRealisticAmount() {
		return Math.random() > 0.8 ? 0 : (Math.random() * 1000).round() * 10;
	}

	public static void assignPermissionSet() {
		try {
			PermissionSet cbSet = [SELECT Id FROM PermissionSet WHERE Name = 'CBDeveloper' WITH SECURITY_ENFORCED LIMIT 1];
			User cbUser = [SELECT Id FROM User WHERE Name = 'User User' WITH SECURITY_ENFORCED LIMIT 1];
			for (PermissionSetAssignment psa : [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :cbUser.Id AND PermissionSetId = :cbSet.Id WITH SECURITY_ENFORCED LIMIT 1]) {
				return;
			}
			PermissionSetAssignment assign = new PermissionSetAssignment(AssigneeId = cbUser.Id, PermissionSetId = cbSet.Id);
			uow.registerNew(assign);
			uow.commitWork();
			uow = null;
		} catch (Exception e) {
			System.debug('It is not a scratch org');
		}
	}

	public static void regenerateData() {
		deleteAllData();
		generateData();
	}

	/**
	 * Delete all the Data (for the class debugging)
	 */
	public static void deleteAllData() {
		uow = null;
		uow.registerDeleted([SELECT Id FROM CBAmount__c]);
		uow.registerDeleted([SELECT Id FROM CBBudgetLine__c]);
		uow.registerDeleted([SELECT Id FROM CBInvoiceLine__c]);
		uow.registerDeleted([SELECT Id FROM CBInvoice__c]);
		uow.commitWork();
		uow = null;
		uow.registerDeleted([SELECT Id FROM CBTransaction__c]);
		//uow.registerDeleted([SELECT Id FROM CBModelingLine__c]);
		//uow.registerDeleted([SELECT Id FROM CBModelingRule__c]);
		uow.registerDeleted([SELECT Id FROM CBModelingRuleGroup__c]);
		uow.registerDeleted([SELECT Id FROM CBVariable1__c]);
		uow.registerDeleted([SELECT Id FROM CBVariable2__c]);
		uow.registerDeleted([SELECT Id FROM CBCube__c]);
		uow.registerDeleted([SELECT Id FROM CBNonFinancialLibrary__c]);
		uow.registerDeleted([SELECT Id FROM CBLayer__c]);
		uow.registerDeleted([SELECT Id FROM CBWelcome__c]);
		uow.registerDeleted([SELECT Id FROM CBAccount__c]);
		uow.registerDeleted([SELECT Id FROM CBSubAccount__c]);
		uow.registerDeleted([SELECT Id FROM CBAccountType__c]);
		uow.registerDeleted([SELECT Id FROM CBDivision__c]);
		uow.registerDeleted([SELECT Id FROM CBClusterRule__c]);
		uow.registerDeleted([SELECT Id FROM CBReportColumn__c]);
		uow.registerDeleted([SELECT Id FROM CBReportConfiguration__c]);
		uow.registerDeleted([SELECT Id FROM CBReport__c]);
		uow.registerDeleted([SELECT Id FROM CBPeriod__c]);
		uow.registerDeleted([SELECT Id FROM CBBudgetYear__c]);
		uow.registerDeleted([SELECT Id FROM CBStyle__c]);
		// uow.registerDeleted([SELECT Id FROM CBTaskQueue__c]);
		uow.commitWork();
		uow = null;
	}

	public static void checkListOfRecords(String type) {
		List<SObject> sobjects = new CBSobjectSelector(type).getSobjects('');
		System.debug('Records Number: ' + sobjects.size());
		for (SObject o : sobjects) {
			System.debug(o);
		}
	}
}