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
global without sharing class CBPostInstallService implements InstallHandler {

	private static final String developer1Email = 'alugovoi@cloudbudget.com';
	private static final List<String> divisionNames = new List<String>{
			'01:Head Dpt', '02:Marketing Dpt'
	};
	private static List<CBDivision__c> divisions = new List<CBDivision__c>();
	private static final List<String> accountOperationNames = new List<String>{
			'5110:Rent', '5112:Advertising', '5114:Insurance', '5118:Inventory', '5121:Equipment', '5128:Entertainment', '5190:Other'
	};
	private static final List<String> accountTravelNames = new List<String>{
			'5210:Meal', '5211:Airfare', '5221:Hotel', '5225:Taxi', '5231:Car rent'
	};
	private static final List<String> accountWageNames = new List<String>{
			'6101:Salary', '6121:Bonus', '6111:Overhead', '6117:Compensation'
	};
	private static final List<String> accountTaxNames = new List<String>{
			'7101:FICA', '7105:Property Tax'
	};
	private static List<CBAccount__c> randomAccounts = new List<CBAccount__c>();
	private static List<CBAccount__c> evenAccounts = new List<CBAccount__c>();

	private static final List<String> vendorNames = new List<String>{
			'Salesforce', 'Oracle', 'New Bridge', 'Green Power', 'Oven'
	};
	private static final List<String> productNames = new List<String>{
			'Service Support', 'AK-06 1K5', 'AT-27', 'AT-24 Drive', 'UMKA'
	};
	private List<CBVariable1__c> vendors = new List<CBVariable1__c>();
	private List<CBVariable2__c> products = new List<CBVariable2__c>();
	private CBBudgetYear__c budgetYear;
	private List<CBPeriod__c> periods = new List<CBPeriod__c>();
	private Map<String, CBStyle__c> styleMap = new Map<String, CBStyle__c>();

	/**
	 * The method inserts org variable and send an email to developers
	 */
	global void onInstall(InstallContext context) {
		if (context.previousVersion() == null) {
			generateData();
			sendEmailToAdmin('CloudBudget Express was installed to ' + context.organizationId());
		}
	}

	public void generateData() {
		try {
			setStyles();
			setOrgVariable();
			setDivisions();
			setAccounts();
			setVariables();
			setPeriods();
			setClusterRules();
			setBudgetLines();
			setInvoices();
			setReport();
			setWelcomes();
		} catch (Exception e) {
			sendEmailToAdmin('CloudBudget Express installation failure ' + e.getMessage() + ' stack trace ' + e.getStackTraceString());
		}
	}

	private void setOrgVariable() {
		if ([SELECT Id FROM CBOrgVariable__c LIMIT 1].size() > 0) return;
		insert new CBOrgVariable__c(Name = 'Default', CBVariable1Label__c = 'Vendor', CBVariable2Label__c = 'Product', BudgetLineLvl1Style__c = styleMap.get('BL1').Id);
	}
	private void setStyles() {
		styleMap.put('BL1', new CBStyle__c(Name = 'BL1', BackgroundColor__c = '#DCDFE4', Color__c = '#000000', Font__c = 'sans-serif', FontWeight__c = 'normal', State__c = 'auto'));
		styleMap.put('BL2', new CBStyle__c(Name = 'BL2', BackgroundColor__c = '#BAC1CD', Color__c = '#000000', Font__c = 'sans-serif', FontWeight__c = 'normal', State__c = 'auto'));
		styleMap.put('Expense', new CBStyle__c(Name = 'Expense', BackgroundColor__c = '#AFD6F3', Color__c = '#000000', Font__c = 'sans-serif', FontWeight__c = 'normal', State__c = 'auto'));
		styleMap.put('Total Column', new CBStyle__c(Name = 'Total Column', BackgroundColor__c = '#f3f3f3', Color__c = '#000000', Font__c = 'sans-serif', FontWeight__c = 'bold', State__c = 'auto'));
		styleMap.put('Total Line Lvl Global', new CBStyle__c(Name = 'Total Line Lvl Global', BackgroundColor__c = '#f3f3f3', Color__c = '#000000', Font__c = 'sans-serif', FontWeight__c = 'bold', State__c = 'auto'));
		styleMap.put('Total Line Lv l0', new CBStyle__c(Name = 'Total Line Lv l0', BackgroundColor__c = '#f3f3f3', Color__c = '#000000', Font__c = 'sans-serif', FontWeight__c = 'bold', State__c = 'auto'));
		styleMap.put('Quarter Column', new CBStyle__c(Name = 'Quarter Column', BackgroundColor__c = '#f3f3f3', Color__c = '#000000', Font__c = 'sans-serif', FontWeight__c = 'bold', State__c = 'auto'));
		insert styleMap.values();
	}
	private void setDivisions() {
		for (String dn : divisionNames) divisions.add(new CBDivision__c(Name = dn));
		insert divisions;
	}
	private void setAccounts() {
		CBAccountType__c at = new CBAccountType__c(Name = 'Expense', Sign__c = '+', CBStyle__c = styleMap.get('Expense').Id);
		insert at;

		CBSubAccount__c operationalAST = new CBSubAccount__c(Name = '01:Operational');
		CBSubAccount__c travelAST = new CBSubAccount__c(Name = '02:Travel');
		CBSubAccount__c wageAST = new CBSubAccount__c(Name = '03:Wage');
		CBSubAccount__c taxAST = new CBSubAccount__c(Name = '04:Taxes');
		List<CBSubAccount__c> subTotalAccounts = new List<CBSubAccount__c>{
				operationalAST, travelAST, wageAST, taxAST
		};
		insert subTotalAccounts;

		for (String an : accountOperationNames) randomAccounts.add(new CBAccount__c(Name = an, CBSubAccount__c = operationalAST.Id, CBAccountType__c = at.Id));
		for (String an : accountTravelNames) randomAccounts.add(new CBAccount__c(Name = an, CBSubAccount__c = travelAST.Id, CBAccountType__c = at.Id));
		for (String an : accountWageNames) evenAccounts.add(new CBAccount__c(Name = an, CBSubAccount__c = wageAST.Id, CBAccountType__c = at.Id));
		for (String an : accountTaxNames) evenAccounts.add(new CBAccount__c(Name = an, CBSubAccount__c = taxAST.Id, CBAccountType__c = at.Id));
		insert randomAccounts;
		insert evenAccounts;
	}

	private void setVariables() {
		for (String vn : vendorNames) vendors.add(new CBVariable1__c(Name = vn));
		for (String pn : productNames) products.add(new CBVariable2__c(Name = pn));
		insert vendors;
		insert products;
	}
	private void setPeriods() {
		Date currentDate = Date.today();
		Integer currentYear = currentDate.year();
		budgetYear = new CBBudgetYear__c(Name = '' + currentYear, Start__c = Date.newInstance(currentYear, 1, 1));
		insert budgetYear;

		for (Integer idx = 1; idx <= 12; idx++) {
			periods.add(new CBPeriod__c(Name = idx + '/' + currentYear, CBBudgetYear__c = budgetYear.Id,
					Start__c = Date.newInstance(currentYear, idx, 1), End__c = Date.newInstance(currentYear, idx + 1, 1).addDays(-1)));
		}
		insert periods;
	}
	private void setClusterRules() {
		List<CBClusterRule__c> cRules = new List<CBClusterRule__c>();
		cRules.add(new CBClusterRule__c(Name = 'Division', Level1__c = 'cblight__CBDivision__c'));
		cRules.add(new CBClusterRule__c(Name = 'Division/Acc SubType', Level1__c = 'cblight__CBDivision__c', Level2__c = 'cblight__CBSubAccountName__c'));
		cRules.add(new CBClusterRule__c(Name = 'Division/Vendor', Level1__c = 'cblight__CBDivision__c', Level2__c = 'cblight__CBVariable1__c'));
		cRules.add(new CBClusterRule__c(Name = 'Division/Product', Level1__c = 'cblight__CBDivision__c', Level2__c = 'cblight__CBVariable2__c'));
		insert cRules;
	}
	private void setBudgetLines() {
		List<CBBudgetLine__c> randomBudgetLines = new List<CBBudgetLine__c>();
		List<CBBudgetLine__c> evenBudgetLines = new List<CBBudgetLine__c>();

		for (Integer divIdx = 0; divIdx < 2; divIdx++) {
			CBDivision__c div = divisions[divIdx];
			for (CBAccount__c acc : randomAccounts) {
				sObject vendor = getRandomId(vendors);
				sObject product = getRandomId(products);
				String name = acc.Name + (vendor == null ? '' : ' (' + vendor.get('Name') + ')');
				randomBudgetLines.add(new CBBudgetLine__c(Name = name, CBBudgetYear__c = budgetYear.Id, CBAccount__c = acc.Id, CBDivision__c = div.Id,
						CBVariable1__c = vendor == null ? null : vendor.Id, CBVariable2__c = product == null ? null : product.Id));
			}
			if (divIdx == 0) {
				for (CBAccount__c acc : evenAccounts) {
					evenBudgetLines.add(new CBBudgetLine__c(Name = acc.Name, CBBudgetYear__c = budgetYear.Id, CBAccount__c = acc.Id, CBDivision__c = div.Id));
				}
			}
		}
		insert randomBudgetLines;
		insert evenBudgetLines;

		List<CBAmount__c> amounts = new List<CBAmount__c>();
		for (CBBudgetLine__c bl : randomBudgetLines) {
			for (CBPeriod__c p : periods) amounts.add(new CBAmount__c(CBBudgetLine__c = bl.Id, Value__c = getRealisticAmount(), CBPeriod__c = p.Id));
		}
		for (CBBudgetLine__c bl : evenBudgetLines) {
			Decimal amount = getRealisticAmount();
			for (CBPeriod__c p : periods) amounts.add(new CBAmount__c(CBBudgetLine__c = bl.Id, Value__c = amount, CBPeriod__c = p.Id));
		}
		insert amounts;
	}
	private void setInvoices() {
		List<CBInvoice__c> invoices = new List<CBInvoice__c>();

		List<CBPeriod__c> updatedPeriods = new List<CBPeriod__c>{
				periods[0], periods[1], periods[3]
		};

		for (Integer divIdx = 0; divIdx < 2; divIdx++) {
			CBDivision__c div = divisions[divIdx];
			for (CBAccount__c acc : randomAccounts) {
				for (CBPeriod__c p : updatedPeriods) {
					sObject vendor = getRandomId(vendors);
					sObject product = getRandomId(products);
					invoices.add(new CBInvoice__c(Name = acc.Name, CBAccount__c = acc.Id, CBDivision__c = div.Id, CBPeriod__c = p.Id, InvoiceDate__c = p.Start__c,
							CBVariable1__c = vendor == null ? null : vendor.Id, CBVariable2__c = product == null ? null : product.Id));
				}
			}
			if (divIdx == 0) {
				for (CBAccount__c acc : evenAccounts) {
					for (CBPeriod__c p : updatedPeriods) {
						invoices.add(new CBInvoice__c(Name = acc.Name, CBAccount__c = acc.Id, CBDivision__c = div.Id, CBPeriod__c = p.Id, InvoiceDate__c = p.Start__c));
					}
				}
			}
		}
		insert invoices;

		List<CBInvoiceLine__c> invoiceLines = new List<CBInvoiceLine__c>();
		for (CBInvoice__c inv : invoices) {
			invoiceLines.add(new CBInvoiceLine__c(Name = 'Line 1', CBInvoice__c = inv.Id, Amount__c = getRealisticAmount()));
		}
		insert invoiceLines;
	}


	private void setReport() {
		CBReport__c report = new CBReport__c(Name = 'Profit and Loss ' + budgetYear.Name, Mode__c = 'Auto', needQuarterTotals__c = true);
		insert report;
		insert new CBReportConfiguration__c(Name = 'General Auto', Grouping__c = '["cblight__CBDivision__c","cblight__CBAccount__c"]', CBReport__c = report.Id,
				SubtotalNumber__c = 1, Filter__c = 'cblight__CBBudgetYear__c = \'' + budgetYear.Id + '\' ');

		List<CBReportColumn__c> columns = new List<CBReportColumn__c>();
		String unit = '$';
		columns.add(new CBReportColumn__c(Name = 'Budget', ValueField__c = 'cblight__Budget__c', OrderNumber__c = 1, Type__c = 'Master', Unit__c = unit, CBReport__c = report.Id));
		columns.add(new CBReportColumn__c(Name = 'Actual', ValueField__c = 'cblight__Actual__c', OrderNumber__c = 2, Type__c = 'Master', Unit__c = unit, CBReport__c = report.Id));
		insert columns;
	}

	public void setWelcomes() {
		CBWelcome__c mainWelcome = new CBWelcome__c(Name = 'main', cblight__Header__c = 'CloudBudget3.0', cblight__Type__c = 'Lead',
				cblight__Description__c = 'CloudBudget Lite serves as our complimentary offering, featuring a streamlined set of functions. ' +
						'To access the comprehensive, full-featured version showcased in the right-hand panel, kindly reach out to CloudBudget3.0 ',
				cblight__Content__c = '<div class="slds-m-top_large"><a href=\'https://cloudbudget.com/\'>CloudBudget, LLC.</a></div>' +
						'<div class="slds-m-top_small">600 Copperline Drive, #202</div>' +
						'<div class="slds-m-top_small">Chapel Hill, NC, 27516</div>' +
						'<div class="slds-m-top_small">📞 +1 917 940 9328</div>' +
						'<div class="slds-m-top_small">📧 info@cloudbudget.com</div>');
		insert mainWelcome;

		CBWelcome__c dataFlowWelcome = new CBWelcome__c(
				Name = 'dataFlow',
				Header__c = 'Data Flow',
				Icon__c = 'utility:macros',
				Parent__c = mainWelcome.Id,
				Description__c = 'Integrate your data into the CloudBudget system',
				Content__c = '<div style="color: black">Integrate your data into the CloudBudget system</div>' +
						'<div>Utilize your company\'s data for generating next year\'s plans and conducting immediate plan-to-reality comparisons. ' +
						'No coding required. Easily integrate any data into CloudBudget with a simple setup.</div>'
		);
		CBWelcome__c scenarioWelcome = new CBWelcome__c(
				Name = 'scenario',
				Header__c = 'Scenarios',
				Parent__c = mainWelcome.Id,
				Description__c = 'Enhance your forecasting',
				Content__c = '<div style="color: red">Scenarios</div>' +
						'<div>Empower users to effortlessly handle various plan versions, construct dynamic rolling forecasts merging planned and actual data, and conduct insightful scenario comparisons. ' +
						'Tailor your planning strategy to the unique needs of each company with our versatile settings</div>'
		);
		CBWelcome__c calcRulesWelcome = new CBWelcome__c(
				Name = 'calcRule',
				Header__c = 'Calculation Rules & Allocation',
				Icon__c = 'utility:formula',
				Parent__c = mainWelcome.Id,
				Description__c = 'Simplify your routine calculations',
				Content__c = '<div style="color: red">Calculation Rules</div>' +
						'<div>Unlock automation and precision with Calculation Rules, empowering users to automate calculations for bonuses, taxes, inflation, depreciation, growth rates, and beyond. ' +
						'Once you have configured your formulas, a single button press generates new budget lines seamlessly derived from the original budget.</div>'
		);
		CBWelcome__c approvalWelcome = new CBWelcome__c(
				Name = 'approval',
				Header__c = 'Approval Workflow',
				Parent__c = mainWelcome.Id,
				Description__c = 'Build your own approval system',
				Content__c = '<div style="color: red">Approval Workflow</div>' +
						'<div>Our flexible approval setup system enables users to implement complex approval schemes and sequences with ease.' +
						'The Budget Manager approval system seamlessly integrates the standard Salesforce Flow for a straightforward experience.</div>'
		);
		CBWelcome__c backupWelcome = new CBWelcome__c(
				Name = 'approval',
				Header__c = 'Backup and Logs',
				Parent__c = mainWelcome.Id,
				Description__c = 'Keep your data safe',
				Content__c = '<div style="color: red">Backup and Logs</div>' +
						'<div>Budget Manager allows you to store budget changes and restore data up to a certain point. ' +
						'Logging shows who made changes and when</div>'
		);
		CBWelcome__c formulaWelcome = new CBWelcome__c(
				Name = 'formula',
				Header__c = 'Formula Budget Lines',
				Parent__c = mainWelcome.Id,
				Icon__c = 'utility:formula',
				Description__c = 'Price/quantity or rate/hours approach',
				Content__c = '<div style="color: red">Formula Budget Lines</div>' +
						'<div>With Budget Manager, leverage non-financial libraries for budget calculations, whether it\'s computing wages using hours and rates, determining the cost of goods based on quantity and price, or handling various data types. ' +
						'Store formulas in patterns for swift setup of new budget lines.</div>'
		);
		List<CBWelcome__c> welcomes = new List<CBWelcome__c>{
				dataFlowWelcome, scenarioWelcome, calcRulesWelcome, approvalWelcome, backupWelcome, formulaWelcome
		};
		insert welcomes;
	}

	private static sObject getRandomId(List<sObject> inputList) {
		if (Math.random() < 0.15) { // in some % cases it should be null
			return null;
		} else {
			Integer randomIndex = (Integer) Math.floor(Math.random() * inputList.size());
			return inputList[randomIndex];
		}
	}


	/**
	 * The method sends email to developers
	 */
	public void sendEmailToAdmin(String message) {
		try {
			String[] toAddresses = new String[]{
					developer1Email
			};
			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			mail.setToAddresses(toAddresses);
			mail.setSenderDisplayName('CloudBudget');
			mail.setSubject('CloudBudget Lite Installation');
			mail.setPlainTextBody(message);
			Messaging.sendEmail(new Messaging.Email[]{
					mail
			});
		} catch (Exception e) {
			System.debug('ERROR : ' + e);
		}
	}

	private static Decimal getRealisticAmount() {
		return Math.random() > 0.8 ? 0 : (Math.random() * 1000).round() * 10;
	}

}