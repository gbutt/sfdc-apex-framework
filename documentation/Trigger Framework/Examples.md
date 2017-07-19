# Trigger Framework - Examples

## Simple Example: AccountTrigger

The below code illustrates a simple example by creating an imaginary account trigger.

### AccountTrigger.trigger
```java
trigger AccountTrigger on Account (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	AccountTriggerHandler.execute();
}
```

### AccountTriggerHandler.cls
```java
public abstract class AccountTriggerHandler extends TriggerHandler {

	// marshal trigger lists/maps into Account lists/maps
	protected List<Account> newRecords { get { return (List<Account>)getTriggerContext().newRecords; } }
	protected List<Account> oldRecords { get { return (List<Account>)getTriggerContext().oldRecords; } }
	protected Map<Id, Account> newRecordsMap { get { return (Map<Id, Account>)getTriggerContext().newRecordsMap; } }
	protected Map<Id, Account> oldRecordsMap { get { return (Map<Id, Account>)getTriggerContext().oldRecordsMap; } }

	// static execute method for the AccountTrigger
	public static void execute() {

		AccountHandler1 handler1 = new AccountHandler1();
		AccountHandler2 handler2 = new AccountHandler2();
		AccountHandler3 handler3 = new AccountHandler3();

		// build and execute a trigger handler executor.
		// handlers are executed in the order listed.
		TriggerHandlerExecutor.builder()
			.addHandler(TriggerPhase.BEFORE_INSERT, handler1)
			.addHandler(TriggerPhase.BEFORE_INSERT, handler2)
			.addHandler(TriggerPhase.BEFORE_INSERT, handler3)

			.addHandler(TriggerPhase.AFTER_INSERT,  handler1)
			.addHandler(TriggerPhase.AFTER_UPDATE,  handler1)
			.build()
			.execute();
	}
}
```

### AccountHandler1.cls
```java
public with sharing class AccountLogic1 extends AccountTriggerHandler {


	// required: override one or more of the execution phase methods to perform custom logic
	// beforeInsert, beforeUpdate, beforeDelete, afterInsert, afterUpdate, afterDelete, afterUndelete
	protected override void beforeInsert() {
		// do logic here
		for (Account acct : newRecords) {
			log.debug(acct);
		}
	}

	protected override void afterInsert() {
		// do logic here
	}

	protected override void afterUpdate() {
		// do logic here
		for (Account newAcct : newRecords) {
			Account oldAcct = oldRecordsMap.get(newAcct.Id);
			log.debug(oldAcct);
			log.debug(newAcct)
		}
	}
}
```

## Real Example: TaskTrigger

The below code illustrates a real example used for the Task Trigger.

### TaskTrigger.trigger
The TaskTrigger handles all trigger events and calls the TaskTriggerHandler.execute() method. Nothing more.
```java
trigger TaskTrigger on Task (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	TaskTriggerHandler.execute();
}
```

### TaskTriggerHandler.cls
The TaskTriggerHandler is an abstract class that serves the following purposes:

- It marshals the trigger lists/maps into an sobject-specific types
- It provides a static execute method for building and executing the trigger handlers. 
- It provides any decorators that should be used by this trigger handler i.e. TriggerHandlerAsync and TriggerHandlerExecuteOnce.
- It registers trigger handlers for their execution phase i.e. addHandler(TriggerPhase.AFTER_INSERT, deleteMassMailerActivities).

```java
public abstract class TaskTriggerHandler extends TriggerHandler {
	protected List<Task> newRecords { get { return (List<Task>)getTriggerContext().newRecords; } }
	protected List<Task> oldRecords { get { return (List<Task>)getTriggerContext().oldRecords; } }
	protected Map<Id, Task> newRecordsMap { get { return (Map<Id, Task>)getTriggerContext().newRecordsMap; } }
	protected Map<Id, Task> oldRecordsMap { get { return (Map<Id, Task>)getTriggerContext().oldRecordsMap; } }

	public static void execute() {
		buildExecutor().execute();
	}

	private static TriggerHandlerExecutor buildExecutor() {
		TriggerHandler.I deleteMassMailerActivities = new TasksDeleteMassMailerActivities()
			.decorate(new TriggerHandlerAsync())
			.decorate(new TriggerHandlerExecuteOnce());

		return TriggerHandlerExecutor.builder()
			.addHandler(TriggerPhase.AFTER_INSERT, deleteMassMailerActivities)
			.build();
	}
}
```

### TasksDeleteMassMailerActivities.cls
TasksDeleteMassMailerActivities is a concrete trigger handler that performs the custom logic. It will override one or more methods for the phases that require custom logic. In this example we override the afterInsert method to execute logic in the after insert phase.

- It extends the TaskTriggerHandler, so it has access to the sobject-sepcific types (i.e. newRecords -> Task[] instead of SObject[])
- It provides an implementation method for the custom logic (i.e. it overrides the afterInsert method)

```java
public with sharing class TasksDeleteMassMailerActivities extends TaskTriggerHandler {

	@TestVisible
	private UnitOfWork unitOfWork { get; set; }

	public override void preExecute() {
		unitOfWork = new UnitOfWork(new SObjectType[]{ 
			Task.getSObjectType() 
		});
	}

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

	public override void postExecute() {
		unitOfWork.commitWork();
	}
}
```

### TasksDeleteMassMailerActivitiesTest.cls

Unit tests can override the trigger context by injecting their own records. 

Example: handler.getTriggerContext().newRecords = new Task[]{ task1, task2, ... };

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

	private static TasksDeleteMassMailerActivities buildHandler() {
		TasksDeleteMassMailerActivities handler = new TasksDeleteMassMailerActivities();
		handler.init(null);
		return handler;
	}

	/* INTEGRATION TESTS */
	@IsTest
	static void it_should_delete_mass_mailer_tasks() {
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