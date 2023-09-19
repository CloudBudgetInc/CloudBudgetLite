/** 
Copyright (c) 2022, CloudBudget, Inc.
Alex JR  9/6/2022
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


public with sharing class CBNonFinancialLibraryService {

	public static final List<String> LAYER_NAMES = new List<String>{
			'Quantity', 'Price', 'Rate', 'Tax', 'Seasonality', 'Hour', 'Base', 'Var'
	};
	public static final List<String> QUANTITY_NAMES = new List<String>{
			'General', 'Licenses', 'Sales'
	};
	public static final List<String> RATE_NAMES = new List<String>{
			'Manager', 'Consultant', 'Developer', 'Dev Junior', 'HR Specialist'
	};
	public static final List<String> TAX_NAMES = new List<String>{
			'FICA', 'CIT', 'Government'
	};
	public static final List<String> PRICE_NAMES = new List<String>{
			'Implementation', 'Implementation with discount', 'Service', 'Support'
	};
	public static final List<String> SEASONALITY_NAMES = new List<String>{
			'Summer rest', 'Canada specific conditions'
	};
	public static final List<String> HOUR_NAMES = new List<String>{
			'Full time work', 'Consultation', 'Training'
	};
	public static List<CBLayer__c> layersToInsert = new List<CBLayer__c>();
	public static List<CBNonFinancialLibrary__c> libsToInsert = new List<CBNonFinancialLibrary__c>();
	public static Map<String, List<CBNonFinancialItem__c>> nonFinLibsMap = new Map<String, List<CBNonFinancialItem__c>>();
	private static List<Id> periodIds {
		get {
			if (periodIds == null) {
				periodIds = new List<Id>();
				for (CBPeriod__c p : [SELECT Id FROM CBPeriod__c LIMIT 10000]) {
					periodIds.add(p.Id);
				}
			}
			return periodIds;
		}
		set;
	}

	/**
	 * Method generates list of layers, NFLs and items
	 */
	public static void generateLayersAndNonFinancialLibraries() {
		if ([SELECT Id FROM CBNonFinancialLibrary__c LIMIT 1].size() == 1) {
			return;
		}
		generateLayers();
		generateNonFinancialLibraries();
	}

	/**
	 * The method generates a list of basic layers
	 */
	public static void generateLayers() {
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
				new List<SObjectType>{
						CBLayer__c.SObjectType
				}
		);
		if (new CBSobjectSelector(CBLayer__c.SObjectType, false).countSobjects(null) > 0) {
			return;
		}
		for (String name : LAYER_NAMES) {
			layersToInsert.add(new CBLayer__c(Name = name));
		}
		uow.registerNew(layersToInsert);
		uow.commitWork();
	}

	/**
	 * The method generates NFLs with Items
	 */
	public static void generateNonFinancialLibraries() {
		for (CBLayer__c layer : layersToInsert) {
			switch on layer.Name {
				when 'Quantity' {
					generateLibs(layer.Id, QUANTITY_NAMES, 0.99, 10, 10, 0, -1);
				}
				when 'Price' {
					generateLibs(layer.Id, PRICE_NAMES, 0.99, 100, 10, 0, -1);
				}
				when 'Rate' {
					generateLibs(layer.Id, RATE_NAMES, 1, 100, 1, 0, 95);
				}
				when 'Tax' {
					generateLibs(layer.Id, TAX_NAMES, 1, 1, 1, 2, 0.4);
				}
				when 'Seasonality' {
					generateLibs(layer.Id, SEASONALITY_NAMES, 0.7, 1, 1, 1, 1);
				}
				when 'Hour' {
					generateLibs(layer.Id, HOUR_NAMES, 0.9, 1000, 1, 0, 168);
				}
			}
		}
		insertNonFinLibs();
		updateExistedNFLItems();
	}

	/**
	 * The method generates NFLs with Synthetic Items
	 *
	 * @param layerId - layer Id
	 * @param names - names of NFLs
	 * @param nullProbability - probability of null for Items values
	 * @param scale - scale for random amount
	 * @param zero - number of zero amount
	 * @param round - round
	 * @param lim - limit
	 */

	private static void generateLibs(String layerId, List<String> names, Decimal nullProbability, Decimal scale, Decimal zero, Integer round, Decimal lim) {
		for (String name : names) {
			CBNonFinancialLibrary__c lib = new CBNonFinancialLibrary__c(Name = name, Layer__c = layerId);
			libsToInsert.add(lib);
			List<CBNonFinancialItem__c> items = new List<CBNonFinancialItem__c>();
			for (String periodId : periodIds) {
				Decimal value = getRealisticAmount(nullProbability, scale, zero, round);
				if (lim > 0 && value > lim) {
					value = lim;
				}
				items.add(new CBNonFinancialItem__c(CBPeriod__c = periodId, Value__c = value));
			}
			nonFinLibsMap.put(name, items);
		}
	}

	/**
	 * The method inserts NFLs
	 */
	private static void insertNonFinLibs() {

		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
				new List<SObjectType>{
						CBNonFinancialLibrary__c.SObjectType
				}
		);
		uow.registerNew(libsToInsert);
		uow.commitWork();
	}


	/**
	 * The method gets existed NFL Items from server, mapping values from synthetic NFLs Items and updates to server.
	 */
	private static void updateExistedNFLItems() {
		Map<String, CBNonFinancialItem__c> keyToServerItemMap = new Map<String, CBNonFinancialItem__c>();
		Set<Id>nFLIds = new Set<Id>();
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
				new List<SObjectType>{
						CBNonFinancialItem__c.SObjectType
				}
		);

		for (CBNonFinancialLibrary__c lib : libsToInsert) {
			nFLIds.add(lib.Id);
		}

		String filter = 'NonFinancialLibrary__c IN ' + CBUtils.getFormattedINQuery(nFLIds);

		for (CBNonFinancialItem__c item : new CBNonFinancialItemSelector().getNonFinancialItemsByFilter(filter)) {
			keyToServerItemMap.put((String) item.NonFinancialLibrary__c + (String) item.CBPeriod__c, item);
		}

		for (CBNonFinancialLibrary__c lib : libsToInsert) {
			List<CBNonFinancialItem__c> syntheticItems = nonFinLibsMap.get(lib.Name);

			for (CBNonFinancialItem__c syntheticItem : syntheticItems) {
				String keyFromSyntheticItem = lib.Id + (String) syntheticItem.CBPeriod__c;
				CBNonFinancialItem__c itemFromServer = keyToServerItemMap.get(keyFromSyntheticItem);
				itemFromServer.Value__c = syntheticItem.Value__c;
				uow.registerDirty(itemFromServer);
			}
		}
		uow.commitWork();
	}

	private static Decimal getRealisticAmount(Decimal nullProbability, Decimal scale, Decimal zero, Integer round) {
		return Math.random() > nullProbability ? 0 : ((Math.random() * scale) * zero).setScale(round);
	}

	public static void deleteAllLibsAndLayers() {
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
				new List<SObjectType>{
						CBNonFinancialLibrary__c.SObjectType,
						CBNonFinancialItem__c.SObjectType
				}
		);
		uow.registerDeleted([SELECT Id FROM CBNonFinancialItem__c WITH SECURITY_ENFORCED]); // Items deletion have already implemented in trigger
		uow.registerDeleted([SELECT Id FROM CBNonFinancialLibrary__c WITH SECURITY_ENFORCED]);
		uow.commitWork();
		uow = new fflib_SObjectUnitOfWork(
				new List<SObjectType>{
						CBLayer__c.SObjectType
				}
		);
		uow.registerDeleted([SELECT Id FROM CBLayer__c WITH SECURITY_ENFORCED]);
		uow.commitWork();
	}


}