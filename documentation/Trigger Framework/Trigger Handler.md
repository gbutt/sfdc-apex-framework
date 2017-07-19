# Trigger Handler

All of the trigger logic will be contained in one of more trigger handlers. This is where we will do things such as querying and updating other records. 

When creating trigger handlers it is recommended to stick to the Single Responsibility Principle. Do not try to put all of your logic into a single handler, rather create a new handler for each distinct piece of logic. For example, let's say you need to update some values on the Contact object, and you also need to make a web service callout to another system if a specific field changes. There should be at least two trigger handlers for this logic, because updating the values on the Contact likely has no relation to making a web service callout.

## Trigger Handler Lifecycle

During each phase of the trigger lifecycle the handler will go through its own lifecycle as follows:

* Initializaton (all phases)
* Execution (handled phases only)
  * shouldExecute
  * preExecute
  * execute phase method
  * postExecute
* Finalization (all phases)

## Execution Phase Methods

In order to execute some logic for a given phase of the trigger lifecycle you will need to override the method related to that phase. The execution phase methods are:

* beforeInsert
* beforeUpdate
* beforeDelete
* afterInsert
* afterUpdate
* afterDelete
* afterUndelete

Note: The same handler can execute in multiple phases of the trigger lifecycle. 

## Lifecycle Extension Methods

A trigger handler can optionally override one or more of the following extension methods:
* shouldExecute - return false to prevent execution of this handler for the current phase.
* preExecute and postExecute - these methods are called immediately before and after execution of the current phase method.

**shouldExecute** is where you would add custom logic to prevent execution of your handler. Return true to continue execution and false to prevent execution. If execution is prevented, then the pre and post execute methods will not be called.

**preExecute** is where you would perform initialization of your handler. **postExecute** is where you would commit the work done in your trigger. These method is executed immedately before and after each execution phase method that is handled by your handler. For example, in a handler that handles both the before and after insert phases, the preExecute and postExecute methods are called twice when an object is inserted. They are called 0 times when an object is updated, because the handler does not handle the update phases.

## Helpers

The base trigger handler provides several helper objects for use in your trigger handler.

* newRecords - same as Trigger.new
* oldRecords - same as Trigger.old
* newRecordsMap - same as Trigger.newMap
* oldRecordsMap - same as Trigger.oldMap
* logger - a logger instance for use with your trigger. It provides the following methods:
  * debug(Object) - writes to the log at the debug level
  * info(Object) - writes to the log at the info level
  * warn(Object) - writes to the log at the warn level
  * error(Object) - writes to the log at the error level
* getTriggerContext() - returns a TriggerContext object that encapsulates the Apex Trigger class. It provides the following properties:
  * currentPhase - The TriggerPhase related to the current phase of the trigger (i.e. BEFORE_INSERT, AFTER_UPDATE, etc.)
* getHandlerName() - returns the stringified name of this handler.

## Example

The following example shows a simple trigger handler that will delete all tasks related to the Mass Mailer application. It uses the unit of work pattern and the pre/post execution phases to make it easier to test the logic in isolation without performing any DML operations.

```java
public with sharing class TasksDeleteMassMailerActivities extends TaskTriggerHandler {

  @TestVisible
  private UnitOfWork unitOfWork { get; set; }

  // skip execution of this trigger for system administrators
  public override Boolean shouldExecute() {
    if (UserUtils.currentUser.isSystemAdministrator) {
      return false;
    }
    return true;
  }

  // create a unit of work to encapsulate all DML
  public override void preExecute() {
    unitOfWork = new UnitOfWork(new SObjectType[]{ 
      Task.getSObjectType() 
    });
  }

  // register tasks to delete with our unit of work
  public override void afterInsert() {
    Task[] tasksToDelete = new Task[]{};
    for (Task t : newRecords) {
      if (t.sendgrid4sf__Mass_Email_Name__c != null) {
        logger.info('deleting task: ' + t.Id);
        logger.debug(t);
        tasksToDelete.add(new Task(Id = t.Id));
      }
    }
    unitOfWork.registerDeleted(tasksToDelete);
  }

  // commit unit of work (i.e. perform task deletions)
  public override void postExecute() {
    unitOfWork.commitWork();
  }
}
```

### Unit Tests

```java
@IsTest
public class TasksDeleteMassMailerActivitiesTest {
  
  /* UNIT TESTS */
  @IsTest
  static void it_should_register_mass_mailer_tasks_for_deletion() {
    Id fakeTaskId = IdUtils.ID(1, Task.getSObjectType());
    Task massMailerTask = new Task(Id = fakeTaskId, sendgrid4sf__Mass_Email_Name__c = 'test');
    TasksDeleteMassMailerActivities handler = buildHandler();

    // inject newRecords
    handler.getTriggerContext().newRecords = new Task[]{
      massMailerTask
    };
    handler.preExecute();

    // when
    handler.afterInsert();

    // then
    Map<Id, SObject> deleteTaskMap = handler.unitOfWork.m_deletedMapByType.get('Task');
    System.assert(deleteTaskMap.containsKey(massMailerTask.Id), 'Task was not registered for deletion.');
  }

  @IsTest
  static void it_should_not_delete_other_tasks() {
    Id fakeTaskId = IdUtils.ID(1, Task.getSObjectType());
    Task otherTask = new Task(Id = fakeTaskId, sendgrid4sf__Mass_Email_Name__c = null);
    TasksDeleteMassMailerActivities handler = buildHandler();

    // inject newRecords
    handler.getTriggerContext().newRecords = new Task[]{
      otherTask
    };
    handler.preExecute();

    // when
    handler.afterInsert();

    // then
    Map<Id, SObject> deleteTaskMap = handler.unitOfWork.m_deletedMapByType.get('Task');
    System.assertEquals(0, deleteTaskMap.size());
  }

  @IsTest
  static void it_should_not_execute_for_system_admins() {
    UserUtils.currentUser.isSystemAdministrator = true;
    TasksDeleteMassMailerActivities handler = buildHandler();

    // when
    Boolean shouldExecute = handler.shouldExecute();

    // then
    System.assertEquals(false, shouldExecute);
  }

  private static TasksDeleteMassMailerActivities buildHandler() {
    TasksDeleteMassMailerActivities handler = new TasksDeleteMassMailerActivities();
    handler.init(null); // initialize handler
    return handler;
  }

  /* INTEGRATION TESTS */
  @IsTest
  static void it_should_delete_mass_mailer_tasks() {
    UserUtils.currentUser.isSystemAdministrator = false;
    Task mmTask = new Task(sendgrid4sf__Mass_Email_Name__c = 'Test');

    // When
    Test.startTest();
    insert mmTask;
    Test.stopTest();

    // Then
    Task[] allTasks = [SELECT Id FROM Task];
    System.assertEquals(0, allTasks.size(), allTasks);
  }
}
```