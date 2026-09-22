trigger accountTrigger on Account (after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        AccountTriggerHandler.handleInactiveAccounts(Trigger.new, Trigger.oldMap);
    }
}