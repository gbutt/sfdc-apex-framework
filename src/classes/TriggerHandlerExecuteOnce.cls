public class TriggerHandlerExecuteOnce extends TriggerHandlerDecorator {

	// a map of types and the phases in which they've already been executed. used to disable multiple executions in a single transaction.
	// this guards against the phenomenon known as trigger re-entrance
	@TestVisible
	private static final Map<String, Set<TriggerPhase>> executionMap;

	static {
		executionMap = new Map<String, Set<TriggerPhase>>();
	}

	public override void init(TriggerHandler.TriggerContext triggerContext) {
		super.init(triggerContext);
		executionMap.put(getHandlerName(), new Set<TriggerPhase>());
	}

	public override Boolean shouldExecute() {
		if (hasExecuted()) {
			return false;
		}
		return super.shouldExecute();
	}

	public override void execute() {
		super.execute();
		registerExecution();
	}

	private Boolean hasExecuted() {
		return executionMap.get(getHandlerName()).contains(getTriggerContext().currentPhase);
	}

	private void registerExecution() {
		executionMap.get(getHandlerName()).add(getTriggerContext().currentPhase);
	}

	public static TriggerHandlerExecuteOnce newInstance() {
		return new TriggerHandlerExecuteOnce();
	}
}