# Trigger Framework

See [Examples](Examples.md) here.

We use the following conventions for creating triggers in Salesforce:

## One Object, One Trigger. 

- For every object there will be at most one trigger to handle all custom logic. 
- The trigger will be called SObjectTrigger.trigger (ex: TaskTrigger.trigger for the Task SObject).
- It will only call the execute method on the Object Trigger Handler. Nothing more.

## Trigger Executor

- There will be one trigger executor per object and it will use the SObjectTriggerHandler naming convention (i.e. TaskTriggerHandler).
- It will be an abstract class that will be extended by all trigger handlers for this object type (ex: TasksDeleteMassMailerActivities extends TaskTriggerHandler)
- It will extend the TriggerHandler class
- It will provide object-spcific types for the lists/maps (i.e. Task[] newRecords instead of SObject[] newRecords)
- It will have a static execute() method that will execute all trigger logic (ex: TaskTriggerHandler.execute()).
  - The execute method will build a TriggerHandlerExecutor that defines which handlers will execute for a given phase. Handlers will execute in the same order as they are registered. 
- See [Trigger Executor](Trigger+Executor.md) for more info.

## Trigger Handlers

- Each trigger handler will inherit from the trigger executor, which will give it access to the object-specific types for lists/maps. For example the TasksDeleteMassMailerActivities handler can access newRecords as a list of Task instead of a list of SObject.
- It will override one or more execution phase methods to perform custom logic for that phase. Note that the Trigger Handler must be registered to execute during this phase in a TriggerHandlerExecutor.
- See [Trigger Handler](Trigger+Handler.md) for more info.

## Trigger Settings

- Trigger Settings is a custom setting that provides configuration data to a trigger handler.
- You can disable any trigger handler by adding a new Trigger Setting and marking it as Disabled.
- See [Trigger Settings](Trigger+Settings.md) for more info.

## Testing Triggers

- Each trigger handler should have its own test class that uses the TriggerHandlerTest naming convention (i.e. TasksDeleteMassMailerActivitiesTest)
- All tests will be writtin in the BDD style.
- It will always provide integration tests to ensure the trigger handler executes during a DML action.
- It will provide unit tests as needed to prove the functionality of specific operations.
- See [Testing Triggers](Testing+Triggers.md) for more info.