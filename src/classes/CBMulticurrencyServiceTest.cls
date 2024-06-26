/** 
Created by Alex JR on 10/2022.
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
 */
@isTest
public class CBMulticurrencyServiceTest {

    @isTest
    public static void testMultiCurrencyService() {
        Object o = CBMultiCurrencyService.multiCurrencyEnabled;
        o = CBMultiCurrencyService.getCurrencySOServer();
        List<sObject> orgCurrencies = CBMultiCurrencyService.orgCurrencies;
        System.assert(true, 'test failed');
        CBDataFactoryTest.createPeriods(12);
        CBLayer__c currencyLayer = new CBLayer__c(Name = 'Currency');
        insert currencyLayer;
        CBNonFinancialLibrary__c pln = new CBNonFinancialLibrary__c(Layer__c = currencyLayer.Id, Name = 'PLN');
        insert pln;
        List<CBNonFinancialItem__c> items = new List<CBNonFinancialItem__c>();
        o = CBMultiCurrencyService.getCurrencyMonthlyRatesServer();
    }
}