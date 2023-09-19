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
ModelingRule Process Main Class
 */
public with sharing class CBModelingRuleProcessor {


	/**
	 * Constructor may have modeling rule to work with
	 *
	 * @param modelingRule
	 */
	public CBModelingRuleProcessor(CBModelingRule__c modelingRule) {
		this.modelingRule = modelingRule;
	}
	private CBModelingRule__c modelingRule;

	/**
	 * The main method of the class.
	 * Calculates new data using modeling rule from the constructor method
	 *
	 * @param customSourceObjectFilter if null - all source records will be recalculated
	 */
	public void generateResultObjects(String customSourceObjectFilter) {
		Savepoint sp = Database.setSavepoint();
		try {
			CBModelingRuleSourceSelector sourceSelector = new CBModelingRuleSourceSelector(modelingRule, customSourceObjectFilter); // source class object
			CBModelingRuleService service = new CBModelingRuleService(modelingRule); // service class object
			List<sObject> sourceObjects = sourceSelector.getSourceRecords(); // list of source objects with all fields
			CBModelingWrapper sourceWrapper = new CBModelingWrapper(modelingRule, sourceObjects, 'source');
			sourceWrapper.recalculateKeys();
			Set<String> sourceKeySet = sourceWrapper.getKeySet(); // set of keys form source objects

			if (sourceKeySet == null || sourceKeySet.isEmpty()) return;
			CBModelingRuleResultSelector resultSelector = new CBModelingRuleResultSelector(sourceKeySet, modelingRule);// result class object
			List<SObject> resultRecords = resultSelector.getResultRecords(); // list of result records

			CBModelingWrapper resultWrappers = new CBModelingWrapper(modelingRule, resultRecords, 'result');
			if (modelingRule.Mode__c == 'Replacing') {
				resultWrappers.recalculateKeys();
			}

			service.convertSourceToResultRecords(sourceWrapper, resultWrappers);
			resultWrappers.upsertWrapperData();
		} catch (Exception e) {
			Database.rollback(sp);
			CBLogService.setLog(e, 'MRP: Generate Result Objects Method Exception');
			CBLogService.insertLog();
		}
	}


}