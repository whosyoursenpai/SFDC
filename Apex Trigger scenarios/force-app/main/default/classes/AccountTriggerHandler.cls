public with sharing class AccountTriggerHandler {
    
    public static void handleInactiveAccounts(List<Account> newList, Map<Id, Account> oldMap) {
        Set<Id> inactiveAccIds = new Set<Id>();

        // -------------------------------------------------------------
        // STEP 1: Identify Accounts transitioning from Active -> Inactive
        // -------------------------------------------------------------
        for (Account newAcc : newList) {
            Account oldAcc = oldMap.get(newAcc.Id);

            if (newAcc.Status__c == 'Inactive' && oldAcc.Status__c == 'Active') {
                inactiveAccIds.add(newAcc.Id);
            }
        }

        // Guard Clause: Exit early if no Accounts transitioned to Inactive
        if (inactiveAccIds.isEmpty()) {
            return;
        }

        // -------------------------------------------------------------
        // STEP 2: Query Related Contacts and Non-Closed Won Opportunities
        // -------------------------------------------------------------
        List<Contact> contactsToUpdate = [
            SELECT Id, Do_Not_Contact__c 
            FROM Contact 
            WHERE AccountId IN :inactiveAccIds 
              AND Do_Not_Contact__c = false
        ];

        List<Opportunity> oppsToDelete = [
            SELECT Id 
            FROM Opportunity 
            WHERE AccountId IN :inactiveAccIds 
              AND StageName != 'Closed Won'
        ];

        // -------------------------------------------------------------
        // STEP 3: Update Related Contacts
        // -------------------------------------------------------------
        List<Contact> updatedContactsList = new List<Contact>();
        for (Contact con : contactsToUpdate) {
            con.Do_Not_Contact__c = true;
            updatedContactsList.add(con);
        }

        // -------------------------------------------------------------
        // STEP 4: Perform Bulk DML (Update Contacts & Delete Opportunities)
        // -------------------------------------------------------------
        try {
            if (!updatedContactsList.isEmpty()) {
                update updatedContactsList;
            }

            if (!oppsToDelete.isEmpty()) {
                delete oppsToDelete;
            }
        } catch (DmlException e) {
            System.debug('Error updating contacts or deleting opportunities: ' + e.getMessage());
        }
    }
}