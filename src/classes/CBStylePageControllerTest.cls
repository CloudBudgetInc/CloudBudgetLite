/**
 * Created by Aleksei Volkov on 06/24/2022.
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
 * This test class covers the CBStylePageController, CBStyleSelector, CBStyleService classes
 */
@IsTest
public class CBStylePageControllerTest {

	@IsTest
	public static void testGetStylesServer() {
		List<CBStyle__c> styleList = CBDataFactoryTest.createStyles(2, 'testGetStylesServer');
		List<CBStyle__c> actualList = CBStylePageController.getStylesServer();
		System.assertEquals(styleList.size(), actualList.size(), 'styles are not equals');
	}

	@IsTest
	public static void testGetSelectedStyleServer() {
		List<CBStyle__c> styleList = CBDataFactoryTest.createStyles(1, 'testGetSelectedStyleServer');
		String rId = styleList[0].Id;
		CBStyle__c actuaStyle = CBStylePageController.getSelectedStyleServer(rId);
		System.assertEquals(styleList[0].Id, actuaStyle.Id, 'styles are not equals');
	}

	@IsTest
	public static void testGetSelectedStyleServerByNullId() {
		CBStyle__c actuaStyle = CBStylePageController.getSelectedStyleServer(null);
		System.assertEquals(null, actuaStyle, 'not null');
	}

	@IsTest
	public static void testGetStylesMap() {
		Map<String, String> expectedMap = new Map<String, String>();
		List<CBStyle__c> styleList = CBDataFactoryTest.createStyles(1, 'testGetStylesMap');
		for (CBStyle__c item : styleList) {
			expectedMap.put(item.Name, item.Id);
		}
		CBStyleSelector stSel = new CBStyleSelector();
		Map<String, String> actualMap = stSel.getStylesMap();
		System.assertEquals(expectedMap, actualMap, 'maps are not equals');
	}

	@IsTest
	public static void testGetStylesRecordsByFilter() {
		List<CBStyle__c> expectedList = CBDataFactoryTest.createStyles(5, 'testGetStylesRecordsByFilter');
		CBStyleSelector stSel = new CBStyleSelector();
		List<CBStyle__c> actualList = stSel.getStylesRecordsByFilter('Name LIKE \'%' + 'Test' + '%\'');
		System.assertEquals(expectedList.size(), actualList.size(), 'styles are not equals');
	}

	@IsTest
	public static void testGetStylesForAccountTypes() {
		List<CBStyle__c> expectedList = CBDataFactoryTest.createStyles(5, 'testGetStylesForAccountTypes');
		CBDataFactoryTest.createAccountTypes(5);
		CBStyleSelector stSel = new CBStyleSelector();
		List<CBStyle__c> actualList = stSel.getStylesForAccountTypes();
		System.assertEquals(expectedList.size(), actualList.size(), 'styles are not equals');
	}

	@IsTest
	public static void testGetStylesForAmounts() {

		CBDataFactoryTest.createAmounts(5);
		CBStyleSelector stSel = new CBStyleSelector();
		List<CBStyle__c> actualList = stSel.getStylesForAmounts();

		Assert.isTrue(actualList.size() > 0, 'styles for amounts created');
	}

	@IsTest
	public static void testInsertDefaultStyleServer() {
		User adminUser = CBTestService.createAdminUser();
		System.runAs(adminUser) {
			List<CBAccountType__c> accTypes = CBDataFactoryTest.createAccountTypes(2);
			CBOrgVariable__c orgVar = CBDataFactoryTest.createOrgVariable();
			CBStyleService.insertDefaultStyleServer(accTypes);
			List<CBAccountType__c> accountTypesList = [SELECT Name FROM CBAccountType__c WHERE CBStyle__r.Name = 'Expense Style'];
			List<CBStyle__c> styleList = [SELECT Id FROM CBStyle__c];
			System.assert(accountTypesList.size() > 0, 'style not applied');
			System.assert(styleList.size() > 0, 'not all styles created');
		}
	}

	@IsTest
	public static void testSaveStyleServer() {
		String uniqueStyleName = 'Test Style ' + DateTime.now().getTime();
		
		CBStyle__c style = new CBStyle__c();
		style.Name = uniqueStyleName;
		
		String actualId = CBStyleService.saveStyleServer(style);
		
		System.assertNotEquals(null, actualId, 'Style was not saved');
		
		System.assertEquals(style.Id, actualId, 'Style Id does not match');
		
		System.assertEquals(uniqueStyleName, style.Name, 'Style Name does not match');
	}

	@IsTest
	public static void testDeleteStyleServer() {
		List<CBStyle__c> styles = CBDataFactoryTest.createStyles(1, 'testDeleteStyleServer');
		CBStyleService.deleteStyleServer(styles[0].Id);
		List<CBStyle__c> actualStyles = [SELECT Id FROM cblight__CBStyle__c WHERE Name = :styles[0].Name];
		System.assert(actualStyles.size() == 0, 'style was not deleted');
	}
}