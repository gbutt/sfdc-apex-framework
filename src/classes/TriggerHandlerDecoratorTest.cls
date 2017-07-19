@IsTest
public class TriggerHandlerDecoratorTest {
	@IsTest
	static void it_should_chain_multiple_decorators() {
		TriggerPhase phase = TriggerPhase.BEFORE_INSERT;
		TriggerHandler.I mockHandler = buildHandler(phase);

		Test.startTest();
		mockHandler.execute();
		System.assertEquals(1, Limits.getQueueableJobs());
		mockHandler.finalize();
		Test.stopTest();

		System.assertEquals(1, [SELECT Id FROM Contact].size());
	}

	private static TriggerHandler.I buildHandler(TriggerPhase phase) {
		TriggerHandler.I mockHandler = new MockTriggerHandler()
			.decorate(new TriggerHandlerAsync())
			.decorate(new TriggerHandlerExecuteOnce());
		mockHandler.init(null);
		mockHandler.getTriggerContext().currentPhase = phase;
		return mockHandler;
	}

	public class MockTriggerHandler extends TriggerHandler {
		public override void beforeInsert() {
			//insert TestSObjectFactory.buildContact();
			insert new Contact(LastName = 'Test');
		}
	}
}