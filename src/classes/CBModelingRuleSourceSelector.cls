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
public with sharing class CBModelingRuleSourceSelector {

	public CBModelingRuleSourceSelector(CBModelingRule__c modelingRule, String customSourceRecordsFilter) {
		this.modelingRule = modelingRule;
		if (!String.isBlank(customSourceRecordsFilter)) {
			this.sourceRecordsFilter = customSourceRecordsFilter;
		}
		if (!String.isBlank(modelingRule.SourceParentFilter__c)) {
			if(!String.isBlank(sourceRecordsFilter)) {
				sourceRecordsFilter += ' AND ';
			}
			this.sourceRecordsFilter += ' ( ' + modelingRule.SourceParentFilter__c + ' ) ';
		}
		this.parentRecordType = modelingRule.SourceRecordParentType__c;
		this.childRecordType = modelingRule.SourceRecordChildType__c;
	}

	private String parentRecordType;
	private String childRecordType;
	private String sourceRecordsFilter = '';
	private CBModelingRule__c modelingRule;

	public String getSourceDataQuery() {
		String childQ = CBModelingRuleService.getSubQuery(parentRecordType, childRecordType);
		String q = 'SELECT ' + CBUtils.getAllSObjectFields(parentRecordType, childQ);
		String w = String.isBlank(sourceRecordsFilter) ? '' : ' WHERE ' + sourceRecordsFilter;
		return q + w;
	}

	/**
	 * @return list of source records with all fields
	 */
	public List<sObject> getSourceRecords() {
		String query = getSourceDataQuery();
		List<sObject> sourceRecords = Database.query(query);
		CBLogService.setLog('OTHER', 'Source records for ' + modelingRule.Name, 'Query: ' + query, null);
		CBLogService.addLogDetail('Source records', 'Number of source records: ' + sourceRecords.size(), null);
		CBLogService.insertLog();
		return sourceRecords;
	}
}