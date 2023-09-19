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

@description This test class covers the CBNonFinancialLibrarySelector
 */
@isTest
public class CBNonFinancialLibrarySelectorTest {

	@isTest
	public static void testConstructor() {
		CBLayer__c l = new CBLayer__c(Name = 'test');
		insert l;
		List<CBNonFinancialLibrary__c> nflList = new List<CBNonFinancialLibrary__c>();
		CBNonFinancialLibrary__c nfl1 = new CBNonFinancialLibrary__c(Name = 'test1', Layer__c = l.Id);
		CBNonFinancialLibrary__c nfl2 = new CBNonFinancialLibrary__c(Name = 'test2', Layer__c = l.Id);
		nflList.add(nfl1);
		nflList.add(nfl2);
		insert nflList;
		CBNonFinancialLibrarySelector sel = new CBNonFinancialLibrarySelector();
		List<CBNonFinancialLibrary__c> nflList2 = sel.getNonFinancialLibrariesByFilter('', '');
		System.assertEquals(nflList.size(), nflList2.size(), 'size not equals');
		System.assertEquals(l.Id, nflList2[0].Layer__c, 'layers dont match');
	}

	@isTest
	public static void testSetLimit() {
		CBLayer__c l = new CBLayer__c(Name = 'test');
		insert l;
		List<CBNonFinancialLibrary__c> nflList = new List<CBNonFinancialLibrary__c>();
		CBNonFinancialLibrary__c nfl1 = new CBNonFinancialLibrary__c(Name = 'test1', Layer__c = l.Id);
		CBNonFinancialLibrary__c nfl2 = new CBNonFinancialLibrary__c(Name = 'test2', Layer__c = l.Id);
		nflList.add(nfl1);
		nflList.add(nfl2);
		insert nflList;
		CBNonFinancialLibrarySelector sel = new CBNonFinancialLibrarySelector();
		sel.setLimit(1);
		List<CBNonFinancialLibrary__c> nflList2 = sel.getNonFinancialLibrariesByFilter('', '');
		System.assertEquals(1, nflList2.size(), 'size not equals');
	}
	@isTest
	public static void testSetOrder() {
		CBLayer__c l = new CBLayer__c(Name = 'test');
		insert l;
		List<CBNonFinancialLibrary__c> nflList = new List<CBNonFinancialLibrary__c>();
		CBNonFinancialLibrary__c nfl1 = new CBNonFinancialLibrary__c(Name = 'test1', Layer__c = l.Id);
		CBNonFinancialLibrary__c nfl2 = new CBNonFinancialLibrary__c(Name = 'test2', Layer__c = l.Id);
		nflList.add(nfl1);
		nflList.add(nfl2);
		insert nflList;
		CBNonFinancialLibrarySelector sel = new CBNonFinancialLibrarySelector();
		sel.setOrder('Name', false);
		List<CBNonFinancialLibrary__c> nflList2 = sel.getNonFinancialLibrariesByFilter('', '');
		System.assertEquals(nfl2.Name, nflList2[0].Name, 'Names dont match');
	}
	@isTest
	public static void testGetNonFinancialLibrariesByFilter() {
		CBLayer__c l = new CBLayer__c(Name = 'test');
		insert l;
		List<CBNonFinancialLibrary__c> nflList = new List<CBNonFinancialLibrary__c>();
		CBNonFinancialLibrary__c nfl1 = new CBNonFinancialLibrary__c(Name = 'test1', Layer__c = l.Id);
		CBNonFinancialLibrary__c nfl2 = new CBNonFinancialLibrary__c(Name = 'test2', Layer__c = l.Id);
		nflList.add(nfl1);
		nflList.add(nfl2);
		insert nflList;
		CBNonFinancialLibrarySelector sel = new CBNonFinancialLibrarySelector();
		List<CBNonFinancialLibrary__c> nflList2 = sel.getNonFinancialLibrariesByFilter('', '');
		System.assertEquals(nflList.size(), nflList2.size(), 'size not equals');
	}

}