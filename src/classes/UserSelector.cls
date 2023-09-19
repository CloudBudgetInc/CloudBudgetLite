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

public with sharing class UserSelector extends fflib_SObjectSelector {
	public List<Schema.SObjectField> getSObjectFieldList() {
		return new List<Schema.SObjectField>{ User.Id, User.Name, User.IsActive };
	}

	public Schema.SObjectType getSObjectType() {
		return User.sObjectType;
	}

	public override String getOrderBy() {
		return 'Name';
	}

	/**
	 * @param filter (String): filter value
	 *
	 * @return List<User>: List of the records order by selected filter
	 */
	public List<User> getUserRecords(String filter) {
		if (filter == null) {
			filter = '';
		}
		fflib_QueryFactory query = newQueryFactory();
		if (!String.isBlank(filter)) {
			query.setCondition(filter);
		}
		return Database.query(query.toSOQL());
	}

	/**
	 * @param rId (Id): record Id
	 *
	 * @return User: Record selected by Id
	 */
	public User getUserRecordById(Id rId) {
		if (rId == null) {
			return null;
		}
		fflib_QueryFactory query = newQueryFactory();
		query.setCondition(' Id = \'' + rId + '\'');
		return Database.query(query.toSOQL());
	}

	/**
	 * @param Ids (Set<String>): Set of Ids
	 *
	 * @return List<User: List of Users filtered by the set of selected Id
	 */
	public List<User> getUserRecordsById(Set<String> Ids) {
		if (Ids == null || Ids.size() == 0) {
			return null;
		}
		fflib_QueryFactory query = newQueryFactory();
		query.setCondition('Id IN ' + CBUtils.getFormattedINQuery(Ids) + ' ');
		return Database.query(query.toSOQL());
	}
}