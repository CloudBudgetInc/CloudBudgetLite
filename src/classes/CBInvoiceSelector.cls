/** 
Copyright (c) 2023, AJR, CloudBudget, Inc.
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


public with sharing class CBInvoiceSelector extends fflib_SObjectSelector {
	public List<Schema.SObjectField> getSObjectFieldList() {
		return new List<Schema.SObjectField>{
				CBInvoice__c.CreatedById,
				CBInvoice__c.LastModifiedById,
				CBInvoice__c.OwnerId,
				CBInvoice__c.Name,
				CBInvoice__c.Id,
				CBInvoice__c.Total__c,
				CBInvoice__c.Index__c,
				CBInvoice__c.InvoiceDate__c,
				CBInvoice__c.CBBudgetYear__c,
				CBInvoice__c.CBPeriod__c,
				CBInvoice__c.CBDivision__c,
				CBInvoice__c.CBAccount__c,
				CBInvoice__c.CBVariable1__c,
				CBInvoice__c.CBVariable2__c,
				CBInvoice__c.CBVariable3__c,
				CBInvoice__c.CBVariable4__c,
				CBInvoice__c.CBVariable5__c
		};
	}

	public Schema.SObjectType getSObjectType() {
		return CBInvoice__c.sObjectType;
	}

	public override String getOrderBy() {
		return 'Index__c';
	}

	/**
	 * @param filter (String): filter value
	 *
	 * @return List<CBInvoice__c>: List of the records order by selected filter
	 */
	public List<CBInvoice__c> getInvoicesByFilter(String filter) {
		fflib_QueryFactory query = newQueryFactory();
		if (!String.isBlank(filter)) {
			query.setCondition(filter);
		}
		new CBInvoiceLineSelector().addQueryFactorySubSelect(query, 'cblight__CBInvoiceLines__r');
		return Database.query(query.toSOQL());
	}

	/**
	 * @param rId (Id): record Id
	 *
	 * @return CBInvoice__c: Record selected by Id
	 */
	public CBInvoice__c getInvoiceById(Id rId) {
		if (rId == null) {
			return null;
		}
		fflib_QueryFactory query = newQueryFactory();
		query.setCondition(' Id = \'' + rId + '\'');
		new CBInvoiceLineSelector().addQueryFactorySubSelect(query, 'cblight__CBInvoiceLines__r');
		return Database.query(query.toSOQL());
	}
}