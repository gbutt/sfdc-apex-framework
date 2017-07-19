@IsTest
public class TriggerHandlerExecuteOnceTest {

	@IsTest
	static void it_should_run_once_for_each_phase() {

		for (TriggerPhase phase : TriggerPhase.values()) {
			if (phase == TriggerPhase.UNKNOWN) {
				continue;
			}
			TriggerHandlerExecuteOnce mockHandler = buildHandler(phase);
			System.assertEquals(0, ((MockTriggerHandler)mockHandler.decoratedHandler).getExecutedCount(phase));
			// when
			mockHandler.execute();
			mockHandler.finalize();
			// then
			System.assertEquals(1, ((MockTriggerHandler)mockHandler.decoratedHandler).getExecutedCount(phase));
			// when
			mockHandler.execute();
			mockHandler.finalize();
			// then
			System.assertEquals(1, ((MockTriggerHandler)mockHandler.decoratedHandler).getExecutedCount(phase));
		}
	}

	private static TriggerHandlerExecuteOnce buildHandler(TriggerPhase phase) {
		TriggerHandlerExecuteOnce mockHandler = (TriggerHandlerExecuteOnce)new MockTriggerHandler().decorate(new TriggerHandlerExecuteOnce());
		mockHandler.init(null);
		mockHandler.getTriggerContext().currentPhase = phase;
		return mockHandler;
	}

	public class MockTriggerHandler extends TriggerHandler {
		public Boolean shouldExecute = true;
		public Map<TriggerPhase, Integer> executedCount = new Map<TriggerPhase, Integer>();

		//public override Type getHandlerType() { return TriggerHandler.class; }

		public override Boolean shouldExecute() { 
			return shouldExecute; 
		}
		public override void beforeInsert() {
			incrementExecutedCount();
		}
		public override void beforeUpdate() {
			incrementExecutedCount();
		}
		public override void beforeDelete() {
			incrementExecutedCount();
		}
		public override void afterInsert() {
			incrementExecutedCount();
		}
		public override void afterUpdate() {
			incrementExecutedCount();
		}
		public override void afterDelete() {
			incrementExecutedCount();
		}
		public override void afterUndelete() {
			incrementExecutedCount();
		}

		public Integer getExecutedCount(TriggerPhase phase) {
			if (!executedCount.containsKey(getTriggerContext().currentPhase)) {
				executedCount.put(getTriggerContext().currentPhase, 0);
			}
			return executedCount.get(phase);
		}

		private void incrementExecutedCount() {
			if (!executedCount.containsKey(getTriggerContext().currentPhase)) {
				executedCount.put(getTriggerContext().currentPhase, 0);
			}
			executedCount.put(getTriggerContext().currentPhase, executedCount.get(getTriggerContext().currentPhase) + 1);
		}
	}
}