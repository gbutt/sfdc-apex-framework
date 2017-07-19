@IsTest
public class TriggerHandlerTest {
	
	@IsTest
	static void it_should_initialize_the_concrete_type() {
		MockTriggerHandler handler = new MockTriggerHandler();

		// when
		handler.init(null);

		// then
		System.assertNotEquals(null, handler.getTriggerContext());
		System.assertNotEquals(null, handler.getLogger());
	}

	@IsTest
	static void it_should_execute_before_insert() {
		assertExecutionOfPhase(TriggerPhase.BEFORE_INSERT);
	}

	@IsTest
	static void it_should_execute_before_update() {
		assertExecutionOfPhase(TriggerPhase.BEFORE_UPDATE);
	}

	@IsTest
	static void it_should_execute_before_delete() {
		assertExecutionOfPhase(TriggerPhase.BEFORE_DELETE);
	}

	@IsTest
	static void it_should_execute_after_insert() {
		assertExecutionOfPhase(TriggerPhase.AFTER_INSERT);
	}

	@IsTest
	static void it_should_execute_after_update() {
		assertExecutionOfPhase(TriggerPhase.AFTER_UPDATE);
	}

	@IsTest
	static void it_should_execute_after_delete() {
		assertExecutionOfPhase(TriggerPhase.AFTER_DELETE);
	}

	@IsTest
	static void it_should_execute_after_undelete() {
		assertExecutionOfPhase(TriggerPhase.AFTER_UNDELETE);
	}

	@IsTest
	static void it_should_not_execute_when_should_execute_is_false() {
		TriggerPhase phase = TriggerPhase.BEFORE_INSERT;
		MockTriggerHandler handler = buildTriggerHandler(phase);
		handler.shouldExecute = false;
		System.assert(handler.isDisabled());
		assertExecutionOfPhase(handler, 0);
	}

	@IsTest
	static void it_should_not_execute_when_handler_is_disabled_by_trigger_settings() {
		TriggerPhase phase = TriggerPhase.BEFORE_INSERT;
		MockTriggerHandler handler = buildTriggerHandler(phase);
		handler.shouldExecute = true;
		insert new Trigger_Settings__c(Name = handler.getHandlerName(), Disabled__c = true);
		System.assert(handler.isDisabled());
		assertExecutionOfPhase(handler, 0);
	}

	// requires a real trigger implementation to get full coverage
	@IsTest
	static void TriggerContext_should_get_decent_coverage() {
		MockTriggerHandler handler = new MockTriggerHandler();
		handler.init(null);
		System.assertEquals(null, handler.getTriggerContext().newRecords);
		System.assertEquals(null, handler.getTriggerContext().oldRecords);
		System.assertEquals(null, handler.getTriggerContext().newRecordsMap);
		System.assertEquals(null, handler.getTriggerContext().oldRecordsMap);
		System.assertEquals(TriggerPhase.UNKNOWN, handler.getTriggerContext().currentPhase);
	}

	@IsTest
	static void TriggerHandler_should_execute_methods_not_overridden() {
		TriggerHandler handler = new DefTriggerHandler();
		handler.init(null);
		handler.getTriggerContext().currentPhase = TriggerPhase.BEFORE_INSERT;
		handler.execute();
		handler.getTriggerContext().currentPhase = TriggerPhase.BEFORE_UPDATE;
		handler.execute();
		handler.getTriggerContext().currentPhase = TriggerPhase.BEFORE_DELETE;
		handler.execute();
		handler.getTriggerContext().currentPhase = TriggerPhase.AFTER_INSERT;
		handler.execute();
		handler.getTriggerContext().currentPhase = TriggerPhase.AFTER_UPDATE;
		handler.execute();
		handler.getTriggerContext().currentPhase = TriggerPhase.AFTER_DELETE;
		handler.execute();
		handler.getTriggerContext().currentPhase = TriggerPhase.AFTER_UNDELETE;
		handler.execute();
	}

	private static void assertExecutionOfPhase(TriggerPhase phase) {
		MockTriggerHandler handler = buildTriggerHandler(phase);
		assertExecutionOfPhase(handler, 1);
	}
	private static void assertExecutionOfPhase(MockTriggerHandler handler, Integer count) {
		TriggerPhase phase = handler.getTriggerContext().currentPhase;
		// when
		handler.execute();

		// then
		System.assertEquals(count == 0 ? null : count, handler.executedCount.get(phase));
	}

	private static MockTriggerHandler buildTriggerHandler(TriggerPhase currentPhase) {
		MockTriggerHandler handler = new MockTriggerHandler();
		handler.init(null);
		handler.getTriggerContext().currentPhase = currentPhase;
		return handler;
	}

	public class MockTriggerHandler extends TriggerHandler {
		public Boolean shouldExecute = true;
		public Map<TriggerPhase, Integer> executedCount = new Map<TriggerPhase, Integer>();

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

		private void incrementExecutedCount() {
			if (!executedCount.containsKey(getTriggerContext().currentPhase)) {
				executedCount.put(getTriggerContext().currentPhase, 0);
			}
			executedCount.put(getTriggerContext().currentPhase, executedCount.get(getTriggerContext().currentPhase) + 1);
		}
	}

	public class DefTriggerHandler extends TriggerHandler {}
}