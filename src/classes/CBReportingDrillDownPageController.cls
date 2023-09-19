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

Page controller for the cbReportingDrillDown component
 */


public with sharing class CBReportingDrillDownPageController {


	@AuraEnabled
	public static List<CBCube__c> getDrillDownDataServer(Map<String, Object> parameters) {
		String periodId = (String) parameters.get('periodId');
		String configId = (String) parameters.get('configId');
		List<String> keys = (List<String>) JSON.deserialize(JSON.serialize(parameters.get('keys')), List<String>.class);
		CBReportConfiguration__c config = new CBReportConfigurationSelector().getReportConfigurationById(configId);
		String rlAnalyticFilter = getRequestFromGrouping(config, keys);
		String filter = config.Filter__c != null && config.Filter__c.length() > 0 ? '(' + config.Filter__c + ') AND ' + rlAnalyticFilter : rlAnalyticFilter;
		filter += ' AND cblight__CBPeriod__c = \'' + periodId + '\' ';

		return new CBCubeSelector().setFilter(filter).query();
	}

	/**
	 * @param objectIds list of ids of any type of records
	 *
	 * @return list of respective objects
	 */
	@AuraEnabled
	public static List<Object> getLinksServer(List<String> objectIds) {
		Map<String, Set<Id>> objectTypeIdMap = new Map<String, Set<Id>>();
		List<Object> r = new List<Object>();
		for (Id sId : (List<Id>) objectIds) {
			String sobjectType = sId.getSObjectType().getDescribe().getName();
			Set<Id> idList = objectTypeIdMap.get(sobjectType);
			if (idList == null) {
				idList = new Set<Id>();
				objectTypeIdMap.put(sobjectType, idList);
			}
			idList.add(sId);
		}
		return r;
	}

	public static String getRequestFromGrouping(CBReportConfiguration__c config, List<String> keys) {
		List<String> r = new List<String>();
		String EQUAL = ' = ', QUOTE = '\'';
		List<String> fields = config.Grouping__c.replace('[', '').replace(']', '').split(',');
		for (Integer i = 0; i < fields.size(); i++) {
			if (r.size() > 0) {
				r.add(' AND ');
			}
			r.add(fields[i].substringBetween('"'));
			r.add(EQUAL);
			r.add(QUOTE);
			r.add(keys[i]);
			r.add(QUOTE);
		}
		return String.join(r, '');
	}


}