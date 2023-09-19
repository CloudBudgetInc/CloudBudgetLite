/** 
Created by Valerii Krykun on 03/21/2022.
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

public with sharing class CBLogPageController {
	/**
	 * @param filter filter value
	 *
	 * @param limitCount (integer): limit records
	 * 
	 * @return List of the records order by selected filter
	 */
	@AuraEnabled
	public static List<CBLog__c> getLogsServer(String filter, integer limitCount) {
		return new CBLogSelector().getLogFilteredBy(filter, 200);
	}

	/**
	 *
	 * @param logId selected log Id
	 *
	 * @return log with its columns
	 */
	@AuraEnabled
	public static CBLog__c getSelectedLogServer(String logId) {
		return new CBLogSelector().getLogById(logId);
	}
	/**
	 *
	 * @param filter selected filter
	 *
	 * @return CBLog__c: List of the records with CBLogDetail childs
	 */
	@AuraEnabled
	public static CBLog__c getLogDetailsServer(String filter) {
		return new CBLogSelector().getLogWithLogDetail(filter);
	}

	/**
	 * @return list of CBLog fields
	 */
	@AuraEnabled
	public static List<CBSO> getListOfLogFieldsSOServer() {
		return CBUtils.getObjectFieldsSO('cblight__CBLog__c');
	}
}