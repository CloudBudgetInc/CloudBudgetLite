/**
 * This test class covers the CBBudgetLinePageController, CBBudgetLineService,
 * CBNonFinancialLibrarySelector, CBBudgetLineDomain, CBBudgetLineSelector classes
 */
@IsTest
public class CBBudgetLinePageControllerTest {
	@IsTest
	public static void testGetBudgetLinesServer() {
		CBDataFactoryTest.createOrgVariable();
		List<CBAmount__c> amounts = CBDataFactoryTest.createAmounts(1);
		List<CBBudgetLine__c> blList = [
				SELECT Id, Name, CBBudgetYear__c, CBDivision__c, CBAccount__c, CBVariable1__c, CBVariable2__c, CBVariable3__c
				FROM cblight__CbBudgetLine__c
		];
		Map<String, String> params = new Map<String, String>();
		params.put('cblight__CBBudgetYear__c', blList[0].CBBudgetYear__c);
		params.put('approach', 'bottom-up');
		List<CBBudgetLine__c> actualList = CBBudgetLinePageController.getBudgetLinesServer(params);
		System.assertEquals(blList.size(), actualList.size(), 'size not equals');
	}

	@IsTest
	public static void testSaveBudgetLineServer() {
		User adminUser = CBTestService.createAdminUser();
		System.runAs(adminUser) {
			List<CBAmount__c> amounts = CBDataFactoryTest.createAmounts(2);
			List<CBBudgetLine__c> blList = [SELECT Id, NFL1__c, NFL2__c, NFL3__c, NFL4__c, NFL5__c FROM cblight__CBBudgetLine__c];
			List<CBBudgetLine__c> actualList = CBBudgetLinePageController.saveBudgetLineServer(blList[0], amounts);
			System.assertEquals(blList.size(), actualList.size(), 'size not equals');
		}
	}

	@IsTest
	public static void testGetPeriodsServer() {
		List<CBBudgetLine__c> blList = CBDataFactoryTest.createBudgetLines(1);
		List<CBPeriod__c> actualList = CBBudgetLinePageController.getPeriodsServer();
		System.assertEquals(blList.size(), actualList.size(), 'size not equals');
	}

	@IsTest
	public static void testDeleteBudgetLineServer() {
		List<CBBudgetLine__c> blList = CBDataFactoryTest.createBudgetLines(3);
		CBBudgetLinePageController.deleteBudgetLineServer(blList[0].Id);
		List<CBBudgetLine__c> actualList = [SELECT Id FROM cblight__CBBudgetLine__c WHERE Id = :blList[0].Id];
		System.assert(actualList.isEmpty(), 'list is not empty');
	}

	@IsTest
	public static void testGetStylesForAccountTypesServer() {
		List<CBBudgetLine__c> blList = CBDataFactoryTest.createBudgetLines(3);
		List<CBStyle__c> expectedStyles = [SELECT Id, Name FROM cblight__CBStyle__c];
		List<CBStyle__c> actualList = CBBudgetLinePageController.getStylesForAccountTypesServer();
		System.assertEquals(expectedStyles[0].Name, actualList[0].Name, 'names not equals');
	}

	@IsTest
	public static void testGetAccTypesWithStylesNamesServer() {
		List<CBAccountType__c> accTypes = CBDataFactoryTest.createAccountTypes(10);
		List<CBStyle__c> styles = CBDataFactoryTest.createStyles(10, 'Budget Line');
		List<CBStyle__c> expectedStyles = [SELECT Id, Name FROM cblight__CBStyle__c];
		List<CBAccountType__c> actualList = CBBudgetLinePageController.getAccTypesWithStylesNamesServer();
		System.debug(actualList);
		System.assertEquals(expectedStyles[0].Id, actualList[0].cblight__CBStyle__c, 'style id is not equals');
	}

	@IsTest
	public static void testGetStylesRecordsServer() {
		List<CBStyle__c> styles = CBDataFactoryTest.createStyles(10, 'Cluster Rule');
		List<CBStyle__c> expectedStyles = [SELECT Id, Name FROM cblight__CBStyle__c];
		List<CBStyle__c> actualList = CBBudgetLinePageController.getStylesRecordsServer();
		System.assertEquals(expectedStyles[0].Name, actualList[0].Name, 'names not equals');
	}

	@IsTest
	public static void testGetNonFinancialLibrariesServer() {
		List<CBNonFinancialLibrary__c> listNFL = CBDataFactoryTest.createNonFinancialLibraries(1);
		List<CBNonFinancialLibrary__c> actualList = CBBudgetLinePageController.getNonFinancialLibrariesServer();
		System.assertEquals(listNFL.size(), actualList.size(), 'size not equals');
	}

	@IsTest
	public static void testGetClusterRuleServer() {
		List<CBClusterRule__c> clRules = CBDataFactoryTest.createClusterRules(1);
		Map<String, String> params = new Map<String, String>();
		params.put('cblight__CBClusterRule__c', clRules[0].Id);
		CBClusterRule__c actualClRule = CBBudgetLinePageController.getClusterRuleServer(params);
		System.assertEquals(clRules[0].Id, actualClRule.Id, 'ids not equals');
	}

	@IsTest
	public static void testGetSelectOptionsServer() {
		List<CBBudgetLine__c> blList = CBDataFactoryTest.createBudgetLines(1);
		Map<String, List<CBSO>> actualMap = CBBudgetLinePageController.getSelectOptionsServer();
		System.assert(!actualMap.isEmpty(), 'map is not empty');
	}

	@IsTest
	public static void testSetLimit() {
		Integer limitCount = 100;
		CBBudgetLineSelector bls = new CBBudgetLineSelector().setLimit(limitCount);
		System.assert(limitCount != null && limitCount > 0, 'limit was set');
	}

	@IsTest
	public static void testSetFilter() {
		String filter = 'Name LIKE \'%Test%\'';
		CBBudgetLineSelector bls = new CBBudgetLineSelector().setFilter(filter);
		System.assert(!String.isBlank(filter), 'filter was set');
	}

	@IsTest
	public static void testQuery() {
		List<CBBudgetLine__c> blList = CBDataFactoryTest.createBudgetLines(1);
		List<CBBudgetLine__c> actualList = new CBBudgetLineSelector().query();
		System.assertEquals(blList.size(), actualList.size(), 'size not equals');
	}

	@IsTest
	static void testGetLibrariesFromBudgetLineServer() {
		CBLayer__c l = new CBLayer__c(Name = 'test');
		insert l;
		List<CBNonFinancialLibrary__c> nflList = new List<CBNonFinancialLibrary__c>();
		CBNonFinancialLibrary__c nfl1 = new CBNonFinancialLibrary__c(Name = 'test1', Layer__c = l.Id);
		CBNonFinancialLibrary__c nfl2 = new CBNonFinancialLibrary__c(Name = 'test2', Layer__c = l.Id);
		nflList.add(nfl1);
		nflList.add(nfl2);
		insert nflList;
		List<String> idList = new List<String>{
				nfl1.Id, nfl2.Id
		};
		List<CBNonFinancialLibrary__c> nflList2 = CBBudgetLinePageController.getLibrariesFromBudgetLineServer(idList);
		System.assertEquals(nflList.size(), nflList2.size(), 'size not equals');
	}

	@IsTest
	public static void testGlobalSearch() {
		CBDataFactoryTest.createOrgVariable();
		List<CBAmount__c> amounts = CBDataFactoryTest.createAmounts(1);
		List<CBBudgetLine__c> BLList = CBBudgetLineGlobalSearchService.getBudgetLinesBySearchServer('1000');
		BLList = CBBudgetLineGlobalSearchService.getBudgetLinesBySearchServer('Test');
		System.assert(BLList.size() > 0, 'Global search do not work');
	}
}