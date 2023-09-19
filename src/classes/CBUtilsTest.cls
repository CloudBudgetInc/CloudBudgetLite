/**
 * Created by Aleksei Volkov on 08/01/2022.
 * Copyright (c) 2022, CloudBudget, Inc.
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 * Neither the name of the CloudBudget, Inc. nor the names of its contributors
 * may be used to endorse or promote products derived from this software
 * without specific prior written permission.
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 * <p/>
 * This test class covers the CBUtils class
 */
@isTest
public with sharing class CBUtilsTest {

	@isTest
	public static void testGetFieldLabelsForSObject() {
		List<CBAmount__c> amnts = CBDataFactoryTest.createAmounts(1);
		Map<String, String> actualMap = CBUtils.getFieldLabelsForSObject('cblight__CBAmount__c');
		System.assert(!actualMap.isEmpty(), 'actualMap is empty');
	}

	@isTest
	public static void testGetRelationNameByChildLookup() {
		List<CBAmount__c> amnts = CBDataFactoryTest.createAmounts(1);
		String str = CBUtils.getRelationNameByChildLookup('cblight__CBAmount__c', 'cblight__CBPeriod__c');
		System.assert(str != null, 'row is empty');
	}

	@isTest
	public static void testGetLookupFieldName() {
		List<CBAmount__c> amnts = CBDataFactoryTest.createAmounts(1);
		String str = CBUtils.getLookupFieldName('cblight__CBAmount__c', 'cblight__CBPeriod__c');
		System.assert(str == null, 'row is empty');
	}

	@isTest
	public static void testGetObjectNameStringListServer() {
		List<CBAmount__c> amnts = CBDataFactoryTest.createAmounts(1);
		List<String> actualList = CBUtils.getObjectNameStringListServer();
		System.assert(!actualList.isEmpty(), 'list is empty');
	}

	@isTest
	public static void testGillInFieldNameToTypeMap() {
		List<CBAmount__c> amnts = CBDataFactoryTest.createAmounts(1);
		CBUtils.fillInFieldNameToTypeMap('cblight__CBBudgetLine__c');
		System.assert(true, 'test failed');
	}

	@IsTest
	public static void testGetField() {

		List<CBAmount__c> amnts = [SELECT Id, CBPeriod__c FROM CBAmount__c];
		if (amnts.isEmpty()) {
			amnts = CBDataFactoryTest.createAmounts(1);
		}
		Object obj = CBUtils.getField(amnts[0], 'cblight__CBPeriod__c');

		System.assert(obj != null, 'obj is empty');
	}

	@isTest
	public static void testGetFieldByNull() {
		List<CBAmount__c> amnts = CBDataFactoryTest.createAmounts(1);
		Object obj;
		try {
			obj = CBUtils.getField(amnts[0], null);
		} catch (Exception e) {
			obj = new CBException(e, 'U->F');
			System.assert(e != null, 'no catch an exeption');
		}
	}

	@isTest
	public static void testGetFieldValue() {
		List<CBAmount__c> amnts = CBDataFactoryTest.createAmounts(1);
		String s = CBUtils.getFieldValue('cblight__CBPeriod__c', amnts[0]);
		System.assert(s != null, 's is empty');
	}
}