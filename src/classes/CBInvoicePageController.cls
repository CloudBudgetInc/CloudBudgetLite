/** 
Copyright (c) 2023, AJR CloudBudget, Inc.
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


public with sharing class CBInvoicePageController {

	/**
	 * @param filter for future
	 *
	 * @return all invoices
	 */
	@AuraEnabled
	public static List<CBInvoice__c> getInvoicesServer(String filter) {
		return new CBInvoiceSelector().getInvoicesByFilter(filter);
	}

	/**
	 * @return analytics to convert namet to Id and Id to names
	 */
	@AuraEnabled
	public static Map<String, String> getAnalyticsMapServer() {
		Map<String, String> r = new Map<String, String>();
		for (CBDivision__c s : new CBDivisionSelector().getDivisionRecords(null)) addToMap(r, s);
		for (CBAccount__c s : new CBAccountSelector().getAccountRecords(null)) addToMap(r, s);
		for (CBBudgetYear__c s : new CBBudgetYearSelector().getBudgetYears(null)) addToMap(r, s);
		for (CBPeriod__c s : new CBPeriodSelector().getPeriods(null)) addToMap(r, s);
		for (CBVariableSelector.VariableWrapper s : new CBVariableSelector(1).getAllVariables()) addToMap(r, s.getRecord());
		for (CBVariableSelector.VariableWrapper s : new CBVariableSelector(2).getAllVariables()) addToMap(r, s.getRecord());
		for (CBVariableSelector.VariableWrapper s : new CBVariableSelector(3).getAllVariables()) addToMap(r, s.getRecord());
		for (CBVariableSelector.VariableWrapper s : new CBVariableSelector(4).getAllVariables()) addToMap(r, s.getRecord());
		for (CBVariableSelector.VariableWrapper s : new CBVariableSelector(5).getAllVariables()) addToMap(r, s.getRecord());
		return r;
	}

	/**
	 * Method gets a list of invoice wrappers and save them to the database
	 *
	 * @param invoiceWrappers
	 */
	@AuraEnabled
	public static void saveInvoiceWrappersServer(List<InvoiceWrapper> invoiceWrappers) {
		new InvoiceWrapper().saveInvoices(invoiceWrappers);
	}

	/**
	 * Method deletes all invoices
	 *
	 * @param filter for future
	 */
	@AuraEnabled
	public static void deleteInvoicesServer(String filter) {
		delete [SELECT Id FROM CBInvoice__c];
	}

	private static void addToMap(Map<String, String> r, sObject s) {
		String name = (String) s.get('Name');
		String rId = (String) s.get('Id');
		r.put(name, rId);
		r.put(rId, name);
	}

	public class InvoiceWrapper {
		@AuraEnabled
		public CBInvoice__c invoice { get; set; }
		@AuraEnabled
		public List<CBInvoiceLine__c> lines { get; set; }

		public void saveInvoices(List<InvoiceWrapper> invoiceWrappers) {
			List<CBInvoice__c> invoicesToInsert = new List<CBInvoice__c>();
			for (InvoiceWrapper i : invoiceWrappers) invoicesToInsert.add(i.invoice);
			insert invoicesToInsert;

			List<CBInvoiceLine__c> linesToInsert = new List<CBInvoiceLine__c>();
			for (InvoiceWrapper i : invoiceWrappers) for (CBInvoiceLine__c il : i.lines) {
				il.CBInvoice__c = i.invoice.Id;
				linesToInsert.add(il);
			}
			insert linesToInsert;
		}
	}

}