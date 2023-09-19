@isTest
global class CBModelingLineServiceTest {
	@isTest
	public static void crPredModLinesWithoutMappingInternalTest() {
		//Given
		List<CBModelingRule__c> modelingRules = CBDataFactoryTest.createModelingRules(1);
		String mrId = modelingRules[0].Id;

		//When
		CBModelingLineService.createPredefinedModelingLines(mrId);

		//Then
		CBModelingRule__c mr = new CBModelingRuleSelector().getModelingRuleById(mrId);
		List<CBModelingLine__c> existingLines = mr.cblight__CBModelingLines__r;
		System.assertEquals(11, existingLines.size(), 'modeling line list size is not correct');
	}
	
	@isTest
	public static void crPredModLinesWithMappingExternalTest() {
		//Given
		CBMapping__c mapping = CBDataFactoryTest.createDivisionCBMapping();
		mapping = CBDataFactoryTest.createPeriodCBMapping();
		mapping = CBDataFactoryTest.createAcntCBMapping();
		List<CBModelingRule__c> modelingRules = CBDataFactoryTest.createModelingRules(1);
		String mrId = modelingRules[0].Id;

		//When
		CBModelingLineService.createPredefinedModelingLines(mrId);

		//Then
		CBModelingRule__c mr = new CBModelingRuleSelector().getModelingRuleById(mrId);
		List<CBModelingLine__c> existingLines = mr.cblight__CBModelingLines__r;
		System.assertEquals(11, existingLines.size(), 'modeling line list size is not correct');
	}
}