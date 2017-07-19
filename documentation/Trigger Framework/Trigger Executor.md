# Trigger Executor

The executor is a class that controls how trigger handlers are called.
It is used to execute all trigger handlers related to a specific SObject.

## Example: ContactTriggerHandler

```java

public static void execute() {
	buildExecutor().execute();
}

private static TriggerHandlerExecutor buildExecutor() {

	// create trigger handler for MDM
	TriggerHandler.I updateMDMHandler = new ContactUpdateMDM();
	// create trigger handler for PhET
	TriggerHandler.I phetHandler = new ContactPhetHandler();

	// create executor using the builder API
	TriggerHandlerExecutor.Builder executorBuilder = TriggerHandlerExecutor.builder();

	// register handlers with their execution phases
	executorBuilder
		.addHandler(TriggerPhase.BEFORE_INSERT, phetHandler)
		.addHandler(TriggerPhase.BEFORE_UPDATE, phetHandler)
		.addHandler(TriggerPhase.AFTER_INSERT, updateMDMHandler)
		.addHandler(TriggerPhase.AFTER_UPDATE, updateMDMHandler)
		.addHandler(TriggerPhase.AFTER_DELETE, updateMDMHandler)

	// build and return the executor
	return executorBuilder.build();
}

```

## Handler Execution Order

Handlers will be called in the same order in which they are registered. For example if both the phetHandler and the mdmHandler need to execute in the before insert phase, and the phetHandler should execute before the mdmHandler, then we will need to add the phetHandler before the mdmHandler.

```java
builder.addHandler(TriggerPhase.BEFORE_INSERT, phetHandler);
builder.addHandler(TriggerPhase.BEFORE_INSERT, mdmHandler);
```

## Handler Decorators

Handlers can be decorated to alter their behavior. Some example decorators include
- TriggerHandlerExecuteOnce - ensures the handler only executes once for each phase. This is used to guard against trigger re-entrance.
- TriggerHandlerAsync - executes the handler asynchronously, similar to a future method.
- TriggerHandlerBlockUsers - prevents certain users from executing this handler

```java

// decorate this handler with two decorators: TriggerHandlerAsync and TriggerHandlerExecuteOnce.
TriggerHandler.I deleteMassMailerActivities = new TasksDeleteMassMailerActivities()
	.decorate(new TriggerHandlerAsync())
	.decorate(new TriggerHandlerExecuteOnce());

// decorate this handler with TriggerHandlerBlockUsers decorator. 
// The decorator will prevent the UIS Integration user from executing this handler
TriggerHandler.I updateMDMHandler = new ContactUpdateMDM()
	.decorate(TriggerHandlerBlockUsers.builder()
		.allowAll()
		.except(UsersExt.uisIntegrationUser.Username)
		.build());

// decorate this handler with TriggerHandlerBlockUsers decorator. 
// The decorator will only allow the PhET Integration user to execute this handler
TriggerHandler.I phetHandler = new ContactPhetHandler()
	.decorate(TriggerHandlerBlockUsers.builder()
		.allowNone()
		.except(UsersExt.phetIntegrationUser.Username)
		.build());

```

## Example

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