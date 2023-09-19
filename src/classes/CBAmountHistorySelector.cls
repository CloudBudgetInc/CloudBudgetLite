/** 
Copyright (c) 2023, CloudBudget, Inc.
Max Pipich  5/1/2023
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


 public with sharing class CBAmountHistorySelector extends fflib_SObjectSelector {
	public List<Schema.SObjectField> getSObjectFieldList() {
		return new List<Schema.SObjectField>{
            cblight__CBAmount__History.Id,
            cblight__CBAmount__History.ParentId,
            cblight__CBAmount__History.CreatedById,
            cblight__CBAmount__History.CreatedDate,
            cblight__CBAmount__History.Field,
            cblight__CBAmount__History.DataType,
            cblight__CBAmount__History.OldValue,
            cblight__CBAmount__History.NewValue
		};
	}

	public Schema.SObjectType getSObjectType() {
		return cblight__CBAmount__History.sObjectType;
	}

		/**
	 * The main method to get list of amounts history
	 *
	 * @param filter - 
	 *
	 * @return list of Amount History records
	 */
	public List<cblight__CBAmount__History> getAmountHistoryByFilter(String filter) {
		fflib_QueryFactory query = newQueryFactory();
		query.setOrdering('CreatedDate', fflib_QueryFactory.SortOrder.DESCENDING);
		if (!String.isBlank(filter)) {
			query.setCondition(filter);
		}
		System.debug(query.toSOQL());
		return Database.query(query.toSOQL());
	}

}