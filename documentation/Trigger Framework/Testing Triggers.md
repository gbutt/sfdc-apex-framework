# Testing Triggers

We write tests using the testing philosophy from Behavior-Driven Development. For more info see [BDD Testing](BDD+Testing.md).

## Test Features

The trigger framework offers several features that simplify building tests. These features makes tests easier to write and more consistent.

### Trigger Context

The trigger context is a helper class that encapsulates the Trigger class. By encapsulating this class we can inject it with our own data.

* newRecords - this property encapsulates the Trigger.new. You can inject it with a list of SObject (i.e. Task[]).
* oldRecords - this property encapsulates the Trigger.old. You can inject it with a list of SObject.
* newRecordsMap - this property encapsulates the Trigger.newMap. You can inject it with a map of Map<Id, SObject>.
* oldRecordsMap - this property encapsulates the Trigger.oldMap. You can inject it with a map of Map<Id, SObject>.
* currentPhase - this property encapsulates the Trigger phase (i.e. Trigger.isInsert, Trigger.isBefore, etc). The phase is captured as one of the enumerables in TriggerPhase (i.e. BEFORE_INSERT, AFTER_UPDATE, etc).

#### Example of injecting trigger context properties

The trigger context is passed to the handler during initialization, so if you want to inject properties you must call first call `youHandler.init(null)`.

```java
MyHandler handler = new MyHandler();
// call init to create the trigger context
handler.init(null);
// inject newRecords
handler.getTriggerContext().newRecords = new Task[]{ fakeTask };
// inject newRecordsMap
handler.getTriggerContext().newRecordsMap = new Map<Id, Task>(handler.getTriggerContext().newRecords);
// inject currentPhase
handler.getTriggerContext().currentPhase = TriggerPhase.AFTER_INSERT;
```

### preExecute and postExecute Methods

The `preExecute()` and `postExecute()` methods are called immediately before and after an execute phase method, i.e. `insetAfter()`. This makes them good places to create a unit of work and commit a unit of work, respectively. It also allows us to test the phase execution method without having to worry about creating or committing the unit of work.

Let's take a simple example that uses a list of Task as our unit of work

```java
public class MyHandler extends TaskTriggerHandler {
	@TestVisible
	private Task[] unitOfWork {get; set;}
	public override void preExecute() {
		unitOfWork = new Task[]{};
	}
	public override afterInsert() {
		for (Task record : newRecords) {
			if (record.someField__c == true) {
				unitOfWork.add(new Task(Id = record.Id, anotherField__c = false));
			}
		}
	}
	public override postExecute() {
		update unitOfWork;
	}
}
```

We can test the above trigger handler without having to actually insert or update any of our Task objects

```java
@IsTest
static void _it_should_update_tasks() {
	MyHandler handler = buildHandler();
	handler.getTriggerContext().newRecords = new Task[]{ 
		new Task( Id = fakeTaskId, someField__c = true) 
	};

	// when
	handler.insertAfter();

	// then
	System.assertEquals(1, handler.unitOfWork.size());
}
```

For more complex DML operations you'll probably want to use a proper [Unit of Work](https://andyinthecloud.com/2013/06/09/managing-your-dml-and-transactions-with-a-unit-of-work/), such as the one provided by Finanial Force.

## Types of Tests

There are two basic types of tests: Unit Tests and Integration Tests. Each type of test should be grouped under a comment describing the types of tests. For example all unit tests should follow the /* UNIT TESTS */ comment.

### Unit Tests

* A unit test proves the behavior of a unit of code. 
* It should be short, simple and it should only assert one concept. 
* It makes use of mocks to limit the scope of the code under test.

The following code is an example of a unit test:

```java
/* UNIT TESTS */
@IsTest
static void it_should_register_mass_mailer_tasks_for_deletion() {
	// Given: a mass mailer task
	// create a fake ID so we don't have to insert a task
	Id fakeTaskId = IdUtils.ID(1, Task.getSObjectType());
	Task massMailerTask = new Task(Id = fakeTaskId, sendgrid4sf__Mass_Email_Name__c = 'test');

	TasksDeleteMassMailerActivities handler = buildHandler();

	// inject our mass mailer tasks into newRecords
	handler.getTriggerContext().newRecords = new Task[]{ massMailerTask };

	// When: the adterInsert handler is called
	handler.afterInsert();

	// Then: the mass mailer task should be registered for deletion in the unit of work
	Map<Id, SObject> deleteTaskMap = handler.unitOfWork.m_deletedMapByType.get('Task');
	System.assert(deleteTaskMap.containsKey(massMailerTask.Id), 'Task was not registered for deletion.');
}
```

The above code does not insert any data into the database. The code unit under test is the `afterInsert()` method, which should register a mass mailer task for deletion. We inject the data we need to test our code by setting our task in the trigger context. We assert the actions by inspecting the unit of work.

Within this test we create a fake task and inject it into the trigger context. This allows our code to use this task as though it were actually inserted into the database.

The handler is created using the `buildHandler()` test helper method. This allows us to abstract away the boilerplate of creating the handler, and it helps keep the test simple, short and easy to read.

Within the code, a Unit of Work is used to capture DML changes registered in the `afterInsert()` method. The Unit of Work is committed in the `postExecute()` method, which we do not call in this test. This allows us to inspect the Unit of Work without actually committing our task to the database.

If we did not use the unit of work then the `afterInsert()` method would attempt to delete our fake task and fail (because a task with this fake ID does not exist in the database).

Here is another example of a unit test. This is the negative test that proves we do not delete tasks that are unrelated to mass mailer.

```java
@IsTest
static void it_should_not_delete_other_tasks() {
	// Given: a task that is not related to mass mailer
	Id fakeTaskId = IdUtils.ID(1, Task.getSObjectType());
	Task otherTask = new Task(Id = fakeTaskId, sendgrid4sf__Mass_Email_Name__c = null);
	TasksDeleteMassMailerActivities handler = buildHandler();

	// inject newRecords
	handler.getTriggerContext().newRecords = new Task[]{ otherTask };

	// When: the task is inserted
	handler.afterInsert();

	// Then: the task is not registered for deletion
	Map<Id, SObject> deleteTaskMap = handler.unitOfWork.m_deletedMapByType.get('Task');
	System.assertEquals(0, deleteTaskMap.size());
}
```

We use the same concepts in this test. We create a fake task, inject it in the trigger context, execute our code unit and assert the unit of work.

### Integration Tests

Trigger integration tests will test the trigger by actually performing DML operations. Their purpose is to prove the trigger works as expected within the normal trigger context. This is useful for several reasons:

* It proves the trigger handler is actually executed
* It proves there are no integration errors when actual DML operations are performed
* It proves the trigger handler plays nicely with other triggers handlers

Every trigger test class should have at least one integration test to prove these three points.

The following is a code example of an integration test:

```java
/* INTEGRATION TESTS */
@IsTest
static void it_should_delete_mass_mailer_tasks() {
	// Given: a mass mailer task
	Task mmTask = new Task(sendgrid4sf__Mass_Email_Name__c = 'Test');

	// When: the task is inserted
	Test.startTest();
	insert mmTask;
	Test.stopTest();

	// Then: it should be promptly deleted
	Task[] allTasks = [SELECT Id FROM Task];
	System.assertEquals(0, allTasks.size(), allTasks);
}
```

There are some clear differences between the integration test and the unit test.

* The integration test performs actual DML operations.
* The integration test does not create an instance of the trigger handler.
* The integration test queries the database for its assertions.

Some integration tests may need to setup an HTTP Mock. This is OK because Salesforce does not allow making callouts from within a test. All other mocks should be avoided if possible.