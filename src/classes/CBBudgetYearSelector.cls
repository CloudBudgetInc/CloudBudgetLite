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

The selector for CBBudgetYear__c
*/
public with sharing class CBBudgetYearSelector extends fflib_SObjectSelector {
	public List<Schema.SObjectField> getSObjectFieldList() {
		return new List<Schema.SObjectField>{
				CBBudgetYear__c.Id,
				CBBudgetYear__c.Name,
				CBBudgetYear__c.CreatedById,
				CBBudgetYear__c.cblight__End__c,
				CBBudgetYear__c.cblight__ExtId__c,
				CBBudgetYear__c.LastModifiedById,
				CBBudgetYear__c.OwnerId,
				CBBudgetYear__c.cblight__Start__c
		};
	}

	public Schema.SObjectType getSObjectType() {
		return CBBudgetYear__c.sObjectType;
	}

	public override String getOrderBy() {
		return 'cblight__Start__c';
	}

	/**
	 * @param filter (String): filter value
	 *
	 * @return List<CBBudgetYear__c>: List of the records order by selected filter
	 */
	public List<CBBudgetYear__c> getBudgetYears(String filter) {
		fflib_QueryFactory query = newQueryFactory();
		if (!String.isBlank(filter)) {
			query.setCondition(filter);
		}
		return Database.query(query.toSOQL());
	}

	public Map<String, String> budgetYear2SideMap {
		get {
			if (budgetYear2SideMap == null) {
				budgetYear2SideMap = new Map<String, String>();
				for (CBBudgetYear__c b : getBudgetYears(null)) {
					budgetYear2SideMap.put(b.Name, b.Id);
					budgetYear2SideMap.put(b.Id, b.Name);
				}
			}
			return budgetYear2SideMap;
		}
		set;
	}

}