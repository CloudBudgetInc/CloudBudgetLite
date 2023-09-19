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

The class serves to update reporting data on the fly (Modeling rules are not in use)
 */


public with sharing class CBLightCubeRefreshTriggerService {

	private static Map<String, CBCube__c> cubeMap = new Map<String, CBCube__c>();// key is period+Division+Account+Var1+Var2

	public static void refreshAllCBCubes() {
		deleteAllOldCBCubes();
		generateCubesFromCBBudgetLines();
		generateCubesFromCBInvoices();
		insert(cubeMap.values());
	}

	private static void deleteAllOldCBCubes() {
		delete [SELECT Id FROM CBCube__c];
	}

	public static void generateCubesFromCBBudgetLines() {
		List<CBBudgetLine__c> allBudgetLines = new CBBudgetLineSelector().getBudgetLines('');
		for (CBBudgetLine__c bl : allBudgetLines) {
			for (CBAmount__c amount : bl.CBAmounts__r) {
				String key = getCubeKeyFromBL(bl, amount);
				CBCube__c cbCube = cubeMap.get(key);
				if (cbCube == null) {
					cbCube = getNewCBCubeFromBL(bl, amount);
					cubeMap.put(key, cbCube);
				}
				cbCube.Budget__c += amount.Value__c;
			}
		}
	}

	public static void generateCubesFromCBInvoices() {
		for (CBInvoice__c invoice : [SELECT Id, CBPeriod__c, CBDivision__c, CBAccount__c, CBVariable1__c, CBVariable2__c, Total__c FROM CBInvoice__c]) {
			String key = getCubeKeyFromInvoice(invoice);
			CBCube__c cbCube = cubeMap.get(key);
			if (cbCube == null) {
				cbCube = getNewCBCubeFromInvoice(invoice);
				cubeMap.put(key, cbCube);
			}
			cbCube.Actual__c += invoice.Total__c;
		}
	}

	private static String getCubeKeyFromBL(CBBudgetLine__c bl, CBAmount__c amount) {
		return amount.CBPeriod__c + '' + bl.CBDivision__c + bl.CBAccount__c + bl.CBVariable1__c + bl.CBVariable2__c;
	}
	private static String getCubeKeyFromInvoice(CBInvoice__c invoice) {
		return invoice.CBPeriod__c + '' + invoice.CBDivision__c + invoice.CBAccount__c + invoice.CBVariable1__c + invoice.CBVariable2__c;
	}
	private static CBCube__c getNewCBCubeFromBL(CBBudgetLine__c bl, CBAmount__c amount) {
		return new CBCube__c(Name = 'CBLight Cube', CBPeriod__c = amount.CBPeriod__c, CBDivision__c = bl.CBDivision__c, Budget__c = 0, Actual__c = 0,
				CBVariable1__c = bl.CBVariable1__c, CBVariable2__c = bl.CBVariable2__c, CBAccount__c = bl.CBAccount__c);
	}
	private static CBCube__c getNewCBCubeFromInvoice(CBInvoice__c invoice) {
		return new CBCube__c(Name = 'CBLight Cube', CBPeriod__c = invoice.CBPeriod__c, CBDivision__c = invoice.CBDivision__c, Budget__c = 0, Actual__c = 0,
				CBVariable1__c = invoice.CBVariable1__c, CBVariable2__c = invoice.CBVariable2__c, CBAccount__c = invoice.CBAccount__c);
	}
}