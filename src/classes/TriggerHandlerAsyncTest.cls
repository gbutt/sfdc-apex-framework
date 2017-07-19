@IsTest
public class TriggerHandlerAsyncTest {
	
	@IsTest
	static void it_should_execute_trigger_async() {
		TriggerHandlerAsync asyncDecorator = new TriggerHandlerAsync(TriggerPhase.BEFORE_INSERT);
		TriggerHandler.I mockHandler = buildHandler(asyncDecorator);
		mockHandler.getTriggerContext().currentPhase = TriggerPhase.BEFORE_INSERT;

		// when
		Test.startTest();
		mockHandler.execute();
		System.assertEquals(1, Limits.getQueueableJobs());
		mockHandler.finalize();
		Test.stopTest();

		// then
		//System.assertEquals(1, [SELECT Id FROM Contact].size());
		System.assertEquals(1, executionCount);
	}

	@IsTest
	static void it_should_execute_trigger_sync() {
		TriggerHandlerAsync asyncDecorator = new TriggerHandlerAsync(TriggerPhase.BEFORE_INSERT);
		TriggerHandler.I mockHandler = buildHandler(asyncDecorator);
		mockHandler.getTriggerContext().currentPhase = TriggerPhase.BEFORE_UPDATE;

		// when
		Test.startTest();
		mockHandler.execute();
		System.assertEquals(0, Limits.getQueueableJobs());
		mockHandler.finalize();
		Test.stopTest();

		// then
		//System.assertEquals(1, [SELECT Id FROM Contact].size());
		System.assertEquals(1, executionCount);
	}

	@IsTest
	static void it_should_build_decorator_for_phase() {
		// when
		TriggerHandlerAsync decorator = new TriggerHandlerAsync(TriggerPhase.BEFORE_INSERT);

		// then
		System.assertEquals(1, decorator.asyncPhases.size());
		System.assert(decorator.asyncPhases.contains(TriggerPhase.BEFORE_INSERT));
	}

	@IsTest
	static void it_should_build_decorator_for_phases() {
		Set<TriggerPhase> phases = new Set<TriggerPhase>{
			TriggerPhase.BEFORE_INSERT,
			TriggerPhase.BEFORE_UPDATE
		};

		// when
		TriggerHandlerAsync decorator = new TriggerHandlerAsync(phases);

		// then
		System.assertEquals(phases, decorator.asyncPhases);
	}

	@IsTest
	static void it_should_inherit_all_phases() {
		TriggerHandlerAsync asyncDecorator = new TriggerHandlerAsync();

		// when
		TriggerHandler.I mockHandler = buildHandler(asyncDecorator);

		// then
		System.assert(asyncDecorator.asyncPhases.containsAll(TriggerPhase.values()));
	}

	private static TriggerHandler.I buildHandler(TriggerHandlerAsync asyncDecorator) {
		TriggerHandler.I mockHandler = new MockTriggerHandler().decorate(asyncDecorator);
		mockHandler.init(null);
		return mockHandler;
	}

	private static Integer executionCount = 0;

	public class MockTriggerHandler extends TriggerHandler {

		public override void beforeInsert() {
			//insert TestSObjectFactory.buildContact();
			executionCount += 1;
		}

		public override void beforeUpdate() {
			//insert TestSObjectFactory.buildContact();
			executionCount += 1;
		}
	}
}