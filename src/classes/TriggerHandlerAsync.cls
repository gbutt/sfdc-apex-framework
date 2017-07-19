/*
* A decorator that executes this trigger handler in a queueable
* It will execute the registered execution phases asynchronously
* It will use queueable if the queueable limits have not been reached for this context, otherwise it will use schedulable
*/
public class TriggerHandlerAsync extends TriggerHandlerDecorator {

	@TestVisible
	private Set<TriggerPhase> asyncPhases;

	public TriggerHandlerAsync() {
		this.asyncPhases = new Set<TriggerPhase>(TriggerPhase.values());
	}
	public TriggerHandlerAsync(TriggerPhase asyncPhase) {
		this.asyncPhases = new Set<TriggerPhase>();
		this.asyncPhases.add(asyncPhase);
	}
	public TriggerHandlerAsync(Set<TriggerPhase> asyncPhases) {
		this.asyncPhases = asyncPhases;
	}

	public override void init(TriggerHandler.TriggerContext triggerContext) {
		super.init(triggerContext);
	}

	public override void execute() {
		if (!isAsyncPhase()) {
			super.execute();
		} else {
			primeTriggerContext();
			AsyncHelper.enqueueJob(new AsyncHandler(decoratedHandler), getHandlerName());
		}
	}

	public override void finalize() {
		if (!isAsyncPhase()) { 
			super.finalize();
		}
	}

	private Boolean isAsyncPhase() {
		return asyncPhases.contains(getTriggerContext().currentPhase);
	}

	private void primeTriggerContext() {
		TriggerHandler.TriggerContext context = getTriggerContext();
		TriggerPhase phase = context.currentPhase;
		SObject[] newRecords = context.newRecords;
		SObject[] oldRecords = context.oldRecords;
		Map<Id, SObject> newRecordsMap = context.newRecordsMap;
		Map<Id, SObject> oldRecordsMap = context.oldRecordsMap;
	}

	public class AsyncHandler implements Queueable {
		TriggerHandler.I handler;
		public AsyncHandler(TriggerHandler.I handler) {
			this.handler = handler;
		}

		public void execute(QueueableContext context) {
			handler.execute();
			handler.finalize();
		}
	}

	public static TriggerHandlerAsync newInstance() {
		return new TriggerHandlerAsync();
	}

	public static TriggerHandlerAsync newInstance(TriggerPhase asyncPhase) {
		return new TriggerHandlerAsync(asyncPhase);
	}

	public static TriggerHandlerAsync newInstance(Set<TriggerPhase> asyncPhases) {
		return new TriggerHandlerAsync(asyncPhases);
	}
}