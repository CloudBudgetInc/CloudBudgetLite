@isTest
public class CBModelingWrapperTest {
    @TestSetup
    static void makeData(){
        User adminUser = CBTestService.createAdminUser();
    }

    @isTest
    public static void testGetRecordCellById() {
        User adminUser = CBTestService.getAdminUser();
        System.runAs(adminUser) {
            List<CBModelingRule__c> modRules = CBDataFactoryTest.createModelingRules(1);
            List<CBBudgetLine__c> budgetLines = CBDataFactoryTest.createBudgetLines(1);
            List<SObject> parentRecords = new List<SObject>();
            parentRecords.add(budgetLines[0]);
            CBModelingWrapper.RecordCell rc = new CBModelingWrapper(modRules[0], parentRecords, 'source').getRecordCellById(modRules[0].Id);
            System.assert(rc == null, 'record opened');
        }
    }

    @isTest
    public static void testGetRecordCellsByKey() {
        User adminUser = CBTestService.getAdminUser();
        System.runAs(adminUser) {
            List<CBModelingRule__c> modRules = CBDataFactoryTest.createModelingRules(1);
            List<CBBudgetLine__c> budgetLines = CBDataFactoryTest.createBudgetLines(1);
            List<SObject> parentRecords = new List<SObject>();
            parentRecords.add(budgetLines[0]);
            List<CBModelingWrapper.RecordCell> rcList = new CBModelingWrapper(modRules[0], parentRecords, 'source').getRecordCellsByKey('cblight__CBBudgetLine__c');
            System.assert(rcList == null, 'records are generated');
        }
    }

    @isTest
    public static void testGetAllRecordCells() {
        User adminUser = CBTestService.getAdminUser();
        System.runAs(adminUser) {
            List<CBModelingRule__c> modRules = CBDataFactoryTest.createModelingRules(1);
            List<CBAmount__c> amounts = CBDataFactoryTest.createAmounts(1);
            List<SObject> parentRecords = new List<SObject>();
            parentRecords.add(amounts[0]);
            CBModelingWrapper modWrap = new CBModelingWrapper(modRules[0], parentRecords, 'source');
            List<CBModelingWrapper.RecordCell> rcList = modWrap.getAllRecordCells();
            List<SObject> sobjList = modWrap.getOnlyParentSobjects(rcList);
            System.assert(!sobjList.isEmpty(), 'sObjects does not exist');
        }
    }

    @isTest
    public static void testGetRelationChildParentName() {
        User adminUser = CBTestService.getAdminUser();
        System.runAs(adminUser) {
            List<CBModelingRule__c> modRules = CBDataFactoryTest.createModelingRules(1);
            CBCube__c cube = CBDataFactoryTest.createCBCube();
            List<SObject> parentRecords = new List<SObject>();
            parentRecords.add(cube);
            String name = new CBModelingWrapper(modRules[0], parentRecords, 'source').getRelationChildParentName();
            System.assertEquals(cube.Name, name, 'names are not equals');
        }
    }

    @isTest
    public static void testGenerateRecordKey() {
        User adminUser = CBTestService.getAdminUser();
        System.runAs(adminUser) {
            List<CBModelingRule__c> modRules = CBDataFactoryTest.createModelingRules(1);
            CBCube__c cube = CBDataFactoryTest.createCBCube();
            List<SObject> parentRecords = new List<SObject>();
            parentRecords.add(cube);
            String keys = new CBModelingWrapper(modRules[0], parentRecords, 'source').generateRecordKey(cube);
            System.assertNotEquals(cube.Id, keys, 'keys are equals');
        }
    }

    @isTest
    public static void testRecalculateKeys() {
        User adminUser = CBTestService.getAdminUser();
        System.runAs(adminUser) {
            List<CBModelingRule__c> modRules = CBDataFactoryTest.createModelingRules(1);
            List<CBAmount__c> amounts = CBDataFactoryTest.createAmounts(1);
            List<SObject> parentRecords = new List<SObject>();
            parentRecords.add(amounts[0]);
            new CBModelingWrapper(modRules[0], parentRecords, 'source').recalculateKeys();
            String key = [SELECT Id, cblight__KeyFields__c FROM cblight__CBModelingRule__c].cblight__KeyFields__c;
            System.assert(key != null, 'key is empty');
        }
    }

    @isTest
    public static void testGetKeySet() {
        User adminUser = CBTestService.getAdminUser();
        System.runAs(adminUser) {
            List<CBModelingRule__c> modRules = CBDataFactoryTest.createModelingRules(1);
            List<CBAmount__c> amounts = CBDataFactoryTest.createAmounts(1);
            List<SObject> parentRecords = new List<SObject>();
            parentRecords.add(amounts[0]);
            Set<String> keySet = new CBModelingWrapper(modRules[0], parentRecords, 'source').getKeySet();
            System.assert(!keySet.isEmpty(), 'set is empty');
        }
    }

    @isTest
    public static void testupsertWrapperData() {
        User adminUser = CBTestService.getAdminUser();
        System.runAs(adminUser) {
            List<CBModelingRule__c> modRules = CBDataFactoryTest.createModelingRules(1);
            List<CBAmount__c> amounts = CBDataFactoryTest.createAmounts(1);
            List<SObject> parentRecords = new List<SObject>();
            parentRecords.add(amounts[0]);
            new CBModelingWrapper(modRules[0], parentRecords, 'source').upsertWrapperData();
            String name = 'Modeling Rule Generator for ' + modRules[0].Name;
            CBLog__c log = [SELECT Id, Name FROM cblight__CBLog__c WHERE Name = :name];
            System.assertEquals(name, log.Name, 'data does not upsert');
        }
    }
}