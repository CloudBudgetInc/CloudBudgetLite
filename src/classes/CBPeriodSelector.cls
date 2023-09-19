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

The selector for CBPeriod__c
*/
public with sharing class CBPeriodSelector extends fflib_SObjectSelector {
	public List<Schema.SObjectField> getSObjectFieldList() {
		return new List<Schema.SObjectField>{
				CBPeriod__c.Id,
				CBPeriod__c.Start__c,
				CBPeriod__c.End__c,
				CBPeriod__c.ExtId__c,
				CBPeriod__c.CBBudgetYear__c,
				CBPeriod__c.CBBudgetYearSet__c,
				CBPeriod__c.Name
		};
	}

	private fflib_QueryFactory qFactory = newQueryFactory();

	public Schema.SObjectType getSObjectType() {
		return CBPeriod__c.sObjectType;
	}

	public override String getOrderBy() {
		return 'cblight__Start__c';
	}

	/**
	 * @param limitCount if not null and > 0 causes a LIMIT clause to be added to the resulting query.
	 *
	 * @return instance of CBPeriodSelector
	 */
	public CBPeriodSelector setLimit(Integer limitCount) {
		if (limitCount != null && limitCount > 0) {
			qFactory.setLimit(limitCount);
		}
		return this;
	}

	/**
	 * @param filter Sets the WHERE clause to the string provided. Do not include the "WHERE"
	 *
	 * @return instance of CBPeriodSelector
	 */
	public CBPeriodSelector setFilter(String filter) {
		if (!String.isBlank(filter)) {
			qFactory.setCondition(filter);
		}
		return this;
	}

	/**
	 * @return List<CBPeriod__c>: List of the records
	 */
	public List<CBPeriod__c> query() {
		return Database.query(qFactory.toSOQL());
	}

	/**
	 * @param filter (String): filter value
	 *
	 * @return List<CBPeriod__c>: List of the records order by selected filter
	 */
	public List<CBPeriod__c> getPeriods(String filter) {
		fflib_QueryFactory query = newQueryFactory();
		if (!String.isBlank(filter)) {
			query.setCondition(filter);
		}
		query.selectField('cblight__CBBudgetYear__r.Name');
		return Database.query(query.toSOQL());
	}

	/**
	 * @param rId (Id): record Id
	 *
	 * @return CBPeriod__c: Record selected by Id
	 */
	public CBPeriod__c getPeriodRecordById(Id rId) {
		if (rId == null) {
			return null;
		}
		fflib_QueryFactory query = newQueryFactory();
		query.setCondition(' Id = \'' + rId + '\'');
		query.selectField('cblight__CBBudgetYear__r.Name');
		return Database.query(query.toSOQL());
	}

	/**
	 * @param externalIds (Set<String>): Set of external Id
	 *
	 * @return List<CBPeriod__c: List of the records ordered by external Ids
	 */
	public List<CBPeriod__c> getPeriodRecordsByExtId(Set<String> externalIds) {
		if (externalIds == null || externalIds.size() == 0) {
			return null;
		}
		fflib_QueryFactory query = newQueryFactory();
		query.setCondition('cblight__ExtId__c IN ' + CBUtils.getFormattedINQuery(externalIds) + ' ');
		return Database.query(query.toSOQL());
	}

	public static List<CBPeriod__c> allPeriods {
		get {
			if (allPeriods == null) {
				allPeriods = new CBPeriodSelector().getPeriods(null);
			}
			return allPeriods;
		}
		set;
	}

	public static Map<Integer, String> idxPeriodIdMap {
		get {
			if (idxPeriodIdMap == null) {
				idxPeriodIdMap = new Map<Integer, String>();
				for (Integer i = 0; i < allPeriods.size(); i++) idxPeriodIdMap.put(i, allPeriods[i].Id);
			}
			return idxPeriodIdMap;
		}
		set;
	}

	public static Map<String, Integer> periodIdIdxMap {
		get {
			if (periodIdIdxMap == null) {
				periodIdIdxMap = new Map<String, Integer>();
				for (Integer i = 0; i < allPeriods.size(); i++) periodIdIdxMap.put(allPeriods[i].Id, i);
			}
			return periodIdIdxMap;
		}
		set;
	}

	public static Map<String, String> periodIdBudgetYearIdMap {
		get {
			if (periodIdBudgetYearIdMap == null) {
				periodIdBudgetYearIdMap = new Map<String, String>();
				for (CBPeriod__c p : allPeriods) periodIdBudgetYearIdMap.put(p.Id, p.CBBudgetYear__c);
			}
			return periodIdBudgetYearIdMap;
		}
		set;
	}

}