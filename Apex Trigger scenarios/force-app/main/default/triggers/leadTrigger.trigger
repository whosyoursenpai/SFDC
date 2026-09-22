trigger leadTrigger on Lead (after update) {
        if (Trigger.isAfter && Trigger.isUpdate) {
                 leadTriggerHandler.createTaskOnLeadConversion(Trigger.new, Trigger.oldMap);
         }
}