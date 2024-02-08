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

One selector for any type of Variables

 */


public with sharing class CBVariableSelector extends fflib_SObjectSelector {

	private Integer index = -1;

	public CBVariableSelector() {

	}

	public CBVariableSelector(Integer i) {
		index = i;
	}

	/**
	 * @param i index of Variable (form 1 to 5)
	 *
	 * @return this object to proceed the process
	 */
	public CBVariableSelector setIndex(Integer i) {
		index = i;
		return this;
	}

	public List<Schema.SObjectField> getSObjectFieldList() {
		return new List<Schema.SObjectField>{
		};
	}

	public Schema.SObjectType getSObjectType() {
		switch on index {
			when 1 {
				return CBVariable1__c.sObjectType;
			}
			when 2 {
				return CBVariable2__c.sObjectType;
			}
			when 3 {
				return CBVariable3__c.sObjectType;
			}
			when 4 {
				return CBVariable4__c.sObjectType;
			}
			when 5 {
				return CBVariable5__c.sObjectType;
			}
			when else {
				throw new CBException('WTF???');
			}
		}

	}

	/**
	 * Do not forget to specify variable index via the setIndex() method
	 *
	 * @return full list of existing Variables of specified type
	 */
	public List<CBVariableSelector.VariableWrapper> getAllVariables() {
		return getVariablesByFilter(null);
	}

	/**
	 * Do not forget to specify variable index via the setIndex() method
	 *
	 * @return full list of existing Variables of specified type
	 */
	public List<CBVariableSelector.VariableWrapper> getVariablesByFilter(String filter) {
		List<CBVariableSelector.VariableWrapper> r = new List<CBVariableSelector.VariableWrapper>();
		fflib_QueryFactory query = newQueryFactory();
		query.selectField('Name').selectField('Id').selectField('cblight__Code__c').selectField('cblight__Index__c').selectField('cblight__ExtId__c');
		if (String.isNotBlank(filter)) {
			query.setCondition(filter);
		}
		for (sObject variable : Database.query(query.toSOQL())) {
			r.add(new CBVariableSelector.VariableWrapper(variable));
		}
		return r;
	}

	/**
	 * Special wrapper to replace cblight__CBVariableX__c
	 */
	public class VariableWrapper {
		sObject record;
		public VariableWrapper(sObject r) {
			this.record = r;
		}
		public VariableWrapper(Integer idx) {
			this.record = Schema.getGlobalDescribe().get('cblight__CBVariable' + idx + '__c').newSObject();
		}

		public sObject getRecord() {
			return record;
		}

		@auraEnabled public Id recordId {
			get {
				return record.Id;
			}
			set {
				record.Id = value;
			}
		}
		@auraEnabled public String Name {
			get {
				return (String) record.get('Name');
			}
			set {
				record.put('Name', value);
			}
		}
		@auraEnabled public String Code {
			get {
				return (String) record.get('cblight__Code__c');
			}
			set {
				record.put('cblight__Code__c', value);
			}
		}
		@auraEnabled public String Index {
			get {
				return (String) record.get('cblight__Index__c');
			}
			set {
				record.put('cblight__Index__c', value);
			}
		}
		@auraEnabled public String ExtId {
			get {
				return (String) record.get('cblight__ExtId__c');
			}
			set {
				record.put('cblight__ExtId__c', value);
			}
		}

	}

}