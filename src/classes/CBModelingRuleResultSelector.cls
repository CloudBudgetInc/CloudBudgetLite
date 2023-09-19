/**
Created by Alex JR on 10/23/2021.
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

ModelingRule Main Class
 */
public with sharing class CBModelingRuleResultSelector {

	public CBModelingRuleResultSelector(Set<String> keys, CBModelingRule__c modelingRule) {
		this.keys = keys;
		this.modelingRule = modelingRule;
		this.parentRecordType = modelingRule.ResultRecordParentType__c;
		this.childRecordType = modelingRule.ResultRecordChildType__c;
	}

	private String parentRecordType;
	private String childRecordType;
	private Set<String> keys;
	private CBModelingRule__c modelingRule;

	public String getResultDataQuery() {
		String childSubQuery = CBModelingRuleService.getSubQuery(parentRecordType, childRecordType);
		String selectClause = 'SELECT ' + CBUtils.getAllSObjectFields(modelingRule.ResultRecordParentType__c, childSubQuery);
		String whereClause = String.isBlank(modelingRule.cblight__ResultParentFilter__c)
				? ' WHERE CBKey__c IN ' + CBUtils.getFormattedINQuery(keys)
				: ' WHERE ' + modelingRule.cblight__ResultParentFilter__c;

		return selectClause + whereClause;
	}

	/**
	 * @return map of result records. Key - is record key. value is record
	 */
	public List<SObject> getResultRecords() {
		return (List<SObject>) Database.query(getResultDataQuery());
	}

}