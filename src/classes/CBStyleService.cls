/** 
Created by Valerii Krykun on 04/14/2022.
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

public with sharing class CBStyleService {
	/**
	 * Method generating default styles
	 */
	public static void insertDefaultStyleServer(List<CBAccountType__c> types) {
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
			new List<SObjectType> { 
				CBStyle__c.SObjectType, 
				CBAccountType__c.SObjectType
			}
		);

		List<CBStyle__c> styles = new List<CBStyle__c>();
		CBStyle__c incomeStyle = new CBStyle__c(Name = 'Income Style', BackgroundColor__c = '#E6FFEE', Color__c = '#000000', Font__c = 'sans-serif', FontWeight__c = 'normal', State__c = 'auto');
		CBStyle__c expenseStyle = new CBStyle__c(Name = 'Expense Style', BackgroundColor__c = '#FFF5E2', Color__c = '#000000', Font__c = 'sans-serif', FontWeight__c = 'normal', State__c = 'auto');

		styles.add(incomeStyle);
		styles.add(expenseStyle);
		styles.add(new CBStyle__c(Name = 'General Column', BackgroundColor__c = '#FFFFFF', Color__c = '#000000', Font__c = 'sans-serif', FontWeight__c = 'normal', State__c = 'auto'));
		styles.add(new CBStyle__c(Name = 'Quarter Column', BackgroundColor__c = '#E0FDFB', Color__c = '#000000', Font__c = 'sans-serif', FontWeight__c = 'bold', State__c = 'auto'));
		styles.add(new CBStyle__c(Name = 'Total Column', BackgroundColor__c = '#CBDEFA', Color__c = '#000000', Font__c = 'sans-serif', FontWeight__c = 'bold', State__c = 'auto'));
		styles.add(new CBStyle__c(Name = 'Total Line Lvl Global', BackgroundColor__c = '#80EAE2', Color__c = '#000000', Font__c = 'sans-serif', FontWeight__c = 'bold', State__c = 'auto'));
		styles.add(new CBStyle__c(Name = 'Total Line Lvl 0', BackgroundColor__c = '#BAFDF9', Color__c = '#000000', Font__c = 'sans-serif', FontWeight__c = 'bold', State__c = 'auto'));
		styles.add(new CBStyle__c(Name = 'Total Line Lvl 1', BackgroundColor__c = '#E0FDFB', Color__c = '#000000', Font__c = 'sans-serif', FontWeight__c = 'bold', State__c = 'auto'));
		styles.add(new CBStyle__c(Name = 'Total Line Lvl 2', BackgroundColor__c = '#FFFFFF', Color__c = '#000000', Font__c = 'sans-serif', FontWeight__c = 'bold', State__c = 'auto'));
		styles.add(new CBStyle__c(Name = 'Total Line Lvl 3', BackgroundColor__c = '#FFFFFF', Color__c = '#000000', Font__c = 'sans-serif', FontWeight__c = 'bold', State__c = 'auto'));
		styles.add(new CBStyle__c(Name = 'Total Line Lvl 4', BackgroundColor__c = '#FFFFFF', Color__c = '#000000', Font__c = 'sans-serif', FontWeight__c = 'bold', State__c = 'auto'));
		styles.add(new CBStyle__c(Name = 'Budget Line Lvl1', BackgroundColor__c = '#ebeaea', Color__c = '#000000', Font__c = 'sans-serif', FontWeight__c = 'bold', State__c = 'auto'));
		styles.add(new CBStyle__c(Name = 'Budget Line Lvl2', BackgroundColor__c = '#ebdfdf', Color__c = '#000000', Font__c = 'sans-serif', FontWeight__c = 'bold', State__c = 'auto'));
		styles.add(new CBStyle__c(Name = 'Budget Line Lvl3', BackgroundColor__c = '#cfc4c4', Color__c = '#000000', Font__c = 'sans-serif', FontWeight__c = 'bold', State__c = 'auto'));
		styles.add(new CBStyle__c(Name = 'Budget Line Lvl4', BackgroundColor__c = '#ccc8c8', Color__c = '#000000', Font__c = 'sans-serif', FontWeight__c = 'bold', State__c = 'auto'));
		styles.add(new CBStyle__c(Name = 'Budget Line Lvl5', BackgroundColor__c = '#dbd9d9', Color__c = '#000000', Font__c = 'sans-serif', FontWeight__c = 'bold', State__c = 'auto'));
		styles.add(new CBStyle__c(Name = 'Cluster Split Line', BackgroundColor__c = '#C3C3C3', Color__c = '#000000', Font__c = 'sans-serif', FontWeight__c = 'bold', State__c = 'auto'));
		styles.add(new CBStyle__c(Name = 'Report Frozen Columns', BackgroundColor__c = '#e6eeff', Color__c = '#000000', Font__c = 'sans-serif', FontWeight__c = 'bold', State__c = 'auto'));
		uow.registerNew(styles);

		uow.registerRelationship(types[0], CBAccountType__c.CBStyle__c, incomeStyle);
		uow.registerRelationship(types[1], CBAccountType__c.CBStyle__c, expenseStyle);
		uow.registerUpsert(types);
		uow.commitWork();
		CBStyleSelector ds = new CBStyleSelector();
		Map<String, String> styleMap = ds.getStylesMap();
		String budgetLineLvl1StyleId = styleMap.get('Budget Line Lvl1');
		String budgetLineLvl2StyleId = styleMap.get('Budget Line Lvl2');
		String budgetLineLvl3StyleId = styleMap.get('Budget Line Lvl3');
		String budgetLineLvl4StyleId = styleMap.get('Budget Line Lvl4');
		String budgetLineLvl5StyleId = styleMap.get('Budget Line Lvl5');

		CBOrgVariable__c orgVariable = CBOrgVariableSelector.getOrgVariableServer(); // current org variable
		orgVariable.BudgetLineLvl1Style__c = budgetLineLvl1StyleId;
		orgVariable.BudgetLineLvl2Style__c = budgetLineLvl2StyleId; 
		orgVariable.BudgetLineLvl3Style__c = budgetLineLvl3StyleId;
		orgVariable.BudgetLineLvl4Style__c = budgetLineLvl4StyleId; 
		orgVariable.BudgetLineLvl5Style__c = budgetLineLvl5StyleId;
		fflib_SObjectUnitOfWork uow1 = new fflib_SObjectUnitOfWork(
			new List<SObjectType> { CBOrgVariable__c.SObjectType }
		);
		uow1.registerUpsert(orgVariable);
		uow1.commitWork();
	}

	/**
	 * Method add new Style
	 */
	@AuraEnabled
	public static String saveStyleServer(CBStyle__c style) {
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
			new List<SObjectType> { CBStyle__c.SObjectType }
		);
		uow.registerUpsert(style);
		uow.commitWork();
		return style.Id;
	}

	/**
	 * Method delete Style
	 */
	@AuraEnabled
	public static void deleteStyleServer(String styleId) {
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
			new List<SObjectType> { CBStyle__c.SObjectType }
		);
		uow.registerDeleted(new CBStyleSelector().getStyleById(styleId));
		uow.commitWork();
	}
}