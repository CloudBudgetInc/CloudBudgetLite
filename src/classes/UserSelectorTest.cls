/** 
Created by Aleksei Volkov on 08/01/2022.
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

This test class covers the UserSelector class
 */

@isTest
public with sharing class UserSelectorTest {

    @isTest
    public static void testGetUserRecordsbyNull() {
        List<User> cbUsers = [SELECT Id FROM User];
        List<User> actualList = new UserSelector().getUserRecords(null);
        System.assertEquals(cbUsers.size(), actualList.size(), 'user list size is not correct');
    }
    
    @isTest
    public static void testGetUser() {
        List<User> cbUsers = [SELECT Id FROM User];
        User actualUser = new UserSelector().getUserRecordById(cbUsers[0].Id);
        System.assertEquals(cbUsers[0].Id, actualUser.Id, 'user ids are not equal');
    }

    @isTest
    public static void testGetUserRecordsById() {
        List<User> users = [SELECT Id FROM User];
        Set<String> rIds = new Set<String>();
        for(User item: users){
            rIds.add(item.Id);
        }
        List<User> actualList = new UserSelector().getUserRecordsById(rIds);
        System.assertEquals(users.size(), actualList.size(), 'user list size is not correct');
    }
}