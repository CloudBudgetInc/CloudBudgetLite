/** 
Copyright (c) 2022, CloudBudget, Inc.
Alex JR 12/28/2022
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
public with sharing class CBCalculationRuleSelector extends fflib_SObjectSelector {

	public List<Schema.SObjectField> getSObjectFieldList() {
		return new List<Schema.SObjectField>{
				CBCalculationRule__c.Id,
				CBCalculationRule__c.Name,
				CBCalculationRule__c.cblight__Value__c,
				CBCalculationRule__c.cblight__Formula__c,
				CBCalculationRule__c.cblight__CBDivision__c,
				CBCalculationRule__c.cblight__CBAccount__c,
				CBCalculationRule__c.cblight__CBBudgetYear__c,
				CBCalculationRule__c.cblight__CBScenario__c,
				CBCalculationRule__c.cblight__CBVariable1__c,
				CBCalculationRule__c.cblight__CBVariable2__c,
				CBCalculationRule__c.cblight__CBVariable3__c,
				CBCalculationRule__c.cblight__CBVariable4__c,
				CBCalculationRule__c.cblight__CBVariable5__c,
				CBCalculationRule__c.cblight__copyAccount__c,
				CBCalculationRule__c.cblight__copyDivision__c,
				CBCalculationRule__c.cblight__copyBudgetYear__c,
				CBCalculationRule__c.cblight__copyScenario__c,
				CBCalculationRule__c.cblight__copyVariable1__c,
				CBCalculationRule__c.cblight__copyVariable2__c,
				CBCalculationRule__c.cblight__copyVariable3__c,
				CBCalculationRule__c.cblight__copyVariable4__c,
				CBCalculationRule__c.cblight__copyVariable5__c,
				CBCalculationRule__c.cblight__PeriodShift__c,
				CBCalculationRule__c.cblight__SourceParentFilter__c,
				CBCalculationRule__c.cblight__SourceChildFilter__c,
				CBCalculationRule__c.cblight__Description__c,
				CBCalculationRule__c.cblight__ResultName__c,
				CBCalculationRule__c.cblight__NFL1__c,
				CBCalculationRule__c.cblight__CBFolder__c,
				CBCalculationRule__c.cblight__Mode__c
		};
	}

	private fflib_QueryFactory qFactory = newQueryFactory();

	public Schema.SObjectType getSObjectType() {
		return CBCalculationRule__c.sObjectType;
	}

	public override String getOrderBy() {
		return 'Name';
	}

	/**
	 * @param filter soql filter for desired calculation rules. Null if all needed
	 *
	 * @return desired calculation rules
	 */
	public List<CBCalculationRule__c> getCalculationRules(String filter) {
		fflib_QueryFactory query = newQueryFactory();
		if (!String.isBlank(filter)) {
			query.setCondition(filter);
		}
		new CBAllocationTermSelector().addQueryFactorySubSelect(query, 'cblight__CBAllocationTerms__r'); // get budget line children
		return Database.query(query.toSOQL());
	}


}