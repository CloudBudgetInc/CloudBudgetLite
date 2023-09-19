/** 
Copyright (c) 2022, CloudBudget, Inc.
Alex JR  9/6/2022
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


 public with sharing class CBBudgetLineHistorySelector extends fflib_SObjectSelector {
	public List<Schema.SObjectField> getSObjectFieldList() {
		return new List<Schema.SObjectField>{
            cblight__CBBudgetLine__History.Id,
            cblight__CBBudgetLine__History.ParentId,
            cblight__CBBudgetLine__History.CreatedById,
            cblight__CBBudgetLine__History.CreatedDate,
            cblight__CBBudgetLine__History.Field,
            cblight__CBBudgetLine__History.DataType,
			cblight__CBBudgetLine__History.OldValue,
			cblight__CBBudgetLine__History.NewValue
		};
	}

	public Schema.SObjectType getSObjectType() {
		return cblight__CBBudgetLine__History.sObjectType;
	}

	/**
	 * The main method to get list of budget lines history
	 *
	 * @param filter - BL Id
	 *
	 * @return list of BL History records
	 */
	public List<cblight__CBBudgetLine__History> getCBBudgetLineHistoryByFilter(String filter) {
		fflib_QueryFactory query = newQueryFactory();
		query.setOrdering('CreatedDate', fflib_QueryFactory.SortOrder.DESCENDING);
		if (!String.isBlank(filter)) {
			query.setCondition(filter);
		}
		System.debug(query.toSOQL());
		return Database.query(query.toSOQL());
	}

}