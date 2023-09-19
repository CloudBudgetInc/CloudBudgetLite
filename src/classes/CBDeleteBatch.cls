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

Map<String, String> fPMap = new Map<String, String>{
                 'c2g__Type__c' => 'Budget',
                 'c2g__Period__r.c2g__StartDate__c ' => 'n_q>=' + String.valueOf(date.newinstance(startDate.year(), startDate.month(), startDate.day())),
                 'c2g__Period__r.c2g__EndDate__c' => 'n_q<=' + String.valueOf(date.newinstance(endDate.year(), endDate.month(), endDate.day()))
         };
CBDeleteBatch dj = new CBDeleteBatch('c2g__ReportingBalance__c', fPMap, FFBackwardIntegrationJob, 2000);
Id batchId = Database.executeBatch(dj, 2000);
 */
global with sharing class CBDeleteBatch implements Database.Batchable<sObject> {

	/**
	* The API name of sObject. For example - "cblight__CBBudgetLine__c"<br/>
	*/
	private String sObjectNameString;
	private String sObjectName {
		get{
			return this.sObjectNameString;
		}
		set {
			this.sObjectNameString = value;
			this.sObjectType = Schema.getGlobalDescribe().get(value);
		}
	}
	private Schema.SObjectType sObjectType;
	private fflib_SObjectUnitOfWork uow {
		get {
			if (uow == null) {
				uow = new fflib_SObjectUnitOfWork(
					new List<SObjectType> { this.sObjectType }
				);
			}
			return uow;
		}
		set;
	}
	/**
	 *  Filter for some fields. For example: key=> "cblight__Text2__c" value=> "Cr" <br/>
	 *  Also you can specify peculiar key for custom difficult condition: <br/>
	 *  Special key is 'custom'. It has higher priority <br/>
	 *  example: key = 'custom' , value = ' (dim__c = 'xxx' OR dim__c ='xxx') AND dim__C = 'xxx' <br/>
	 */
	private Map<String, String> filterParameterMap;

	private Database.Batchable<SObject> afterCompleteJob;

	private Integer batchSize;

	/**
	 * @param sOName
	 * @param fPMap key=> "cblight__DimensionName__c" value=> ""
	 */
	global CBDeleteBatch(String sOName, Map<String, String> fPMap) {
		this.sObjectName = sOName;
		this.sObjectType = Schema.getGlobalDescribe().get(sOName);
		this.filterParameterMap = fPMap;
	}

	global Database.QueryLocator start(Database.BatchableContext BC) {
		String q = getQueryString();
		try {
			return Database.getQueryLocator(q);
		} catch (Exception e) {
			// STUB PURPOSE ONLY - DO NOT DELETE
			return Database.getQueryLocator('SELECT ID FROM cblight__CBLog__c WHERE Id = null');
		}
	}
	/**
	 * Safety tested ✔ 22/11/2019
	 *
	 * @param BC
	 * @param scope
	 */
	global void execute(Database.BatchableContext BC, List<sObject> scope) {
		uow.registerDeleted(scope);
		uow.commitWork();
		uow = null;
	}
	global void finish(Database.BatchableContext BC) {
		CBTaskDispatcherService.runNextTask();
	}
	/**
	 * The method composes a request string. <br/>
	 * sObjectName - the name of the target sObject, and filterParameterMap is the filter by some fields<br/>
	 * @return a request string
	 */
	private String getQueryString() {
		String selectString = 'SELECT Id FROM ' + sObjectName;
		String whereString;
		if (filterParameterMap != null && filterParameterMap.containsKey('custom')) {
			whereString = ' WHERE ' + filterParameterMap.get('custom');
		} else if (filterParameterMap != null && filterParameterMap.size() > 0) {
			for (String s : filterParameterMap.keySet()) {
				String sign = ' = ';
				Boolean quotes = true;
				String value = filterParameterMap.get(s);
				if (value.contains('n_q')) {
					quotes = false;
					value = value.replace('n_q', '');
				}// no quotes

				if (value.contains('>=')) {
					value = value.replace('>=', '');
					sign = ' >= ';
				}
				if (value.contains('<=')) {
					value = value.replace('<=', '');
					sign = ' <= ';
				}
				if (value.contains('<')) {
					value = value.replace('<', '');
					sign = ' < ';
				}
				if (value.contains('>')) {
					value = value.replace('>', '');
					sign = ' > ';
				}
				if (value.contains('!=')) {
					value = value.replace('!=', '');
					sign = ' != ';
				}
				if (whereString == null) {
					whereString = ' WHERE ';
				} else {
					whereString += ' AND ';
				}
				whereString += quotes ? s + sign + ' \'' + value + '\'' : s + sign + value;
			}
		}
		String result = selectString;
		if (whereString != null) {
			result += whereString;
		}
		return result;
	}

}