const ORGS_CONFIGS_MAP = {
	'Accounting Seed': [
		{
			cblight__Type__c: 'accounts',
			cblight__SpecialFilter__c: 'AcctSeed__Type__c = \'Expense\'',
			cblight__SourceType__c: 'AcctSeed__Type__c',
			cblight__SourceSubtype__c: 'AcctSeed__Sub_Type_1__c',
			cblight__SourceSObject__c: 'AcctSeed__GL_Account__c',
			cblight__SourceFilter__c: 'AcctSeed__Type__c = \'Revenue\' OR AcctSeed__Type__c = \'Expense\'',
			cblight__ResultSObject__c: 'cblight__CBAccount__c'
		},
		{
			cblight__Type__c: 'divisions',
			cblight__SourceSObject__c: 'AcctSeed__Accounting_Variable__c',
			cblight__SourceFilter__c: 'AcctSeed__Type__c = \'GL Account Variable 1\'',
			cblight__ResultSObject__c: 'cblight__CBDivision__c'
		},
		{
			cblight__Type__c: 'periods',
			cblight__SourceType__c: 'AcctSeed__Start_Date__c',
			cblight__SourceSObject__c: 'AcctSeed__Accounting_Period__c',
			cblight__ResultSObject__c: 'cblight__CBPeriod__c'
		}
	],
	'FinancialForce': null, // TODO Add configs for the other orgs
	'Sage Intact': null

}

const SOBJECTS_PREFIXES_BY_ORG_TYPE_MAP = {
	'AcctSeed': 'Accounting Seed',
	'c2g': 'FinancialForce',
	's2cor': 'Sage Intact'
}

export {
	ORGS_CONFIGS_MAP,
	SOBJECTS_PREFIXES_BY_ORG_TYPE_MAP
}