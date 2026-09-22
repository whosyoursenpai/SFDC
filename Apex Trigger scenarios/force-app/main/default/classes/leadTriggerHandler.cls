public with sharing class leadTriggerHandler {
    public static void createTaskOnLeadConversion(List<Lead> newList, Map<Id, Lead> oldMap) {
        List<Lead> convertedLeads = new List<Lead>();
        Set<Id> accIds = new Set<Id>();
        Set<Id> conIds = new Set<Id>();
        Set<Id> oppIds = new Set<Id>();
        
        // -------------------------------------------------------------
        // STEP 1: Filter Leads converted during THIS transaction
        // -------------------------------------------------------------
        for (Lead newLead : newList) {
            Lead oldLead = oldMap.get(newLead.Id);
            
            // Execute ONLY when isConverted flips from false -> true
            if (newLead.isConverted && !oldLead.isConverted) {
                convertedLeads.add(newLead);
                
                if (newLead.ConvertedAccountId != null) accIds.add(newLead.ConvertedAccountId);
                if (newLead.ConvertedContactId != null) conIds.add(newLead.ConvertedContactId);
                if (newLead.ConvertedOpportunityId != null) oppIds.add(newLead.ConvertedOpportunityId);
            }
        }
        
        // Guard Clause: Early return if no leads were converted
        if (convertedLeads.isEmpty()) {
            return;
        }

        // -------------------------------------------------------------
        // STEP 2: Query Related Target Data in Bulk
        // -------------------------------------------------------------
        Map<Id, Account> accMap = new Map<Id, Account>();
        if (!accIds.isEmpty()) {
            accMap = new Map<Id, Account>([SELECT Id, Name FROM Account WHERE Id IN :accIds]);
        }

        Map<Id, Contact> conMap = new Map<Id, Contact>();
        if (!conIds.isEmpty()) {
            conMap = new Map<Id, Contact>([SELECT Id, Name, Phone, Email FROM Contact WHERE Id IN :conIds]);
        }

        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        if (!oppIds.isEmpty()) {
            oppMap = new Map<Id, Opportunity>([SELECT Id, Name, CloseDate FROM Opportunity WHERE Id IN :oppIds]);
        }

        // -------------------------------------------------------------
        // STEP 3: Construct Tasks and Aggregate Descriptions
        // -------------------------------------------------------------
        List<Task> tasksToInsert = new List<Task>();

        for (Lead l : convertedLeads) {
            Task newTask = new Task();
            newTask.Subject = 'Follow Up with Converted Lead';
            newTask.Priority = 'Normal';
            newTask.Status = 'Not Started';
            newTask.ActivityDate = Date.today().addDays(7); // Due 7 days from today
            
            // Assign Polymorphic Lookups
            newTask.WhoId = l.ConvertedContactId;
            newTask.WhatId = l.ConvertedOpportunityId;

            // Build Description String
            String descStr = '--- LEAD DETAILS ---\n';
            descStr += 'Name: ' + l.FirstName + ' ' + l.LastName + '\n';
            descStr += 'Email: ' + l.Email + '\n\n';

            if (accMap.containsKey(l.ConvertedAccountId)) {
                Account acc = accMap.get(l.ConvertedAccountId);
                descStr += '--- ACCOUNT DETAILS ---\nAccount Name: ' + acc.Name + '\n\n';
            }

            if (conMap.containsKey(l.ConvertedContactId)) {
                Contact con = conMap.get(l.ConvertedContactId);
                descStr += '--- CONTACT DETAILS ---\nContact Name: ' + con.Name + '\nPhone: ' + con.Phone + '\n\n';
            }

            if (oppMap.containsKey(l.ConvertedOpportunityId)) {
                Opportunity opp = oppMap.get(l.ConvertedOpportunityId);
                descStr += '--- OPPORTUNITY DETAILS ---\nOpp Name: ' + opp.Name + '\nClose Date: ' + opp.CloseDate + '\n';
            }

            newTask.Description = descStr;
            tasksToInsert.add(newTask);
        }

        // -------------------------------------------------------------
        // STEP 4: Perform Bulk DML Insert
        // -------------------------------------------------------------
        if (!tasksToInsert.isEmpty()) {
            insert tasksToInsert;
        }
    }
}