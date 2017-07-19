@IsTest
public class TriggerHandlerExecutorTest {

	@IsTest
	static void it_should_add_handler() {
		MockTriggerHandler mockHandler = buildHandler();
		TriggerHandlerExecutor composite = buildExecutor(mockHandler);
		System.assertEquals(mockHandler, composite.handlersByPhase.get(TriggerPhase.BEFORE_INSERT)[0]);
	}

	@IsTest
	static void it_should_init_handler() {
		MockTriggerHandler mockHandler = buildHandler();
		TriggerHandlerExecutor composite = buildExecutor(mockHandler);
		System.assertEquals(true, mockHandler.didInit);
	}

	@IsTest
	static void it_should_execute_handler() {
		MockTriggerHandler mockHandler = buildHandler();
		TriggerHandlerExecutor composite = buildExecutor(mockHandler);

		// when
		composite.execute();

		// then
		System.assertEquals(1, mockHandler.getExecutionCount(TriggerPhase.BEFORE_INSERT));
	}

	@IsTest
	static void it_should_only_execute_the_registered_phase() {
		MockTriggerHandler mockHandler = buildHandler();
		TriggerHandlerExecutor composite = buildExecutor(mockHandler);

		// when
		composite.execute();

		// then
		System.assertEquals(1, mockHandler.getExecutionCount(TriggerPhase.BEFORE_INSERT));
		System.assertEquals(null, mockHandler.getExecutionCount(TriggerPhase.BEFORE_UPDATE));
		System.assertEquals(null, mockHandler.getExecutionCount(TriggerPhase.BEFORE_DELETE));
		System.assertEquals(null, mockHandler.getExecutionCount(TriggerPhase.AFTER_INSERT));
		System.assertEquals(null, mockHandler.getExecutionCount(TriggerPhase.AFTER_UPDATE));
		System.assertEquals(null, mockHandler.getExecutionCount(TriggerPhase.AFTER_DELETE));
		System.assertEquals(null, mockHandler.getExecutionCount(TriggerPhase.AFTER_UNDELETE));
	}

	@IsTest
	static void it_should_finalize_handler() {
		MockTriggerHandler mockHandler = buildHandler();
		TriggerHandlerExecutor composite = buildExecutor(mockHandler);

		// when
		composite.execute();

		// then
		System.assertEquals(true, mockHandler.didFinalize);
	}

	@IsTest
	static void TriggerHandlerExecutorBuilder_should_init_handler() {
		MockTriggerHandler mockHandler = buildHandler();
		TriggerHandlerExecutor.Builder executorBuilder = TriggerHandlerExecutor.builder();
		executorBuilder.executor.triggerContext.currentPhase = TriggerPhase.BEFORE_INSERT;
		executorBuilder
			.addHandler(TriggerPhase.BEFORE_INSERT, mockHandler)
			.build();
		System.assertEquals(true, mockHandler.didInit);
	}

	private static MockTriggerHandler buildHandler() {
		return new MockTriggerHandler();
	}

	private static TriggerHandlerExecutor buildExecutor(MockTriggerHandler mockHandler) {
		TriggerPhase phase = TriggerPhase.BEFORE_INSERT;
		TriggerHandlerExecutor composite = new TriggerHandlerExecutor();
		composite.addHandler(phase, mockHandler);
		composite.triggerContext.currentPhase = phase;
		composite.init();
		return composite;
	}
	
	public class MockTriggerHandler extends TriggerHandler {
		public Map<TriggerPhase, Integer> executedCount = new Map<TriggerPhase, Integer>();

		public Boolean didInit = false;
		public Boolean didFinalize = false;

		public Integer getExecutionCount(TriggerPhase phase) {
			return executedCount.get(phase);
		}

		public override void postInit() {
			didInit = true;
		}

		public override void postFinalize() {
			didFinalize = true;
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

		private void incrementExecutedCount() {
			if (!executedCount.containsKey(getTriggerContext().currentPhase)) {
				executedCount.put(getTriggerContext().currentPhase, 0);
			}
			executedCount.put(getTriggerContext().currentPhase, executedCount.get(getTriggerContext().currentPhase) + 1);
		}
	}
}