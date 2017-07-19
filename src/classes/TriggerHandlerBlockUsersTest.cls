@IsTest
public class TriggerHandlerBlockUsersTest {
	@IsTest
	static void it_should_prevent_execution_if_current_user_is_blocked() {
		Set<String> blockedUsers = new Set<String>{ UserInfo.getUserName() };
		TriggerHandlerBlockUsers decorator = new TriggerHandlerBlockUsers(TriggerHandlerBlockUsers.Rule.ALLOW_ALL_EXCEPT, blockedUsers);
		TriggerHandlerBlockUsers mockHandler = buildHandler(decorator);

		// when
		mockHandler.execute();

		// then
		System.assertEquals(0, ((MockTriggerHandler)mockHandler.decoratedHandler).executionCount);
	}

	@IsTest
	static void it_should_allow_execution_if_current_user_is_not_blocked() {
		Set<String> blockedUsers = new Set<String>();
		TriggerHandlerBlockUsers decorator = new TriggerHandlerBlockUsers(TriggerHandlerBlockUsers.Rule.ALLOW_ALL_EXCEPT, blockedUsers);
		TriggerHandlerBlockUsers mockHandler = buildHandler(decorator);

		// when
		mockHandler.execute();

		// then
		System.assertEquals(1, ((MockTriggerHandler)mockHandler.decoratedHandler).executionCount);
	}

	@IsTest
	static void it_should_prevent_execution_if_current_user_is_not_allowed() {
		Set<String> allowedUsers = new Set<String>();
		TriggerHandlerBlockUsers decorator = new TriggerHandlerBlockUsers(TriggerHandlerBlockUsers.Rule.ALLOW_NONE_EXCEPT, allowedUsers);
		TriggerHandlerBlockUsers mockHandler = buildHandler(decorator);

		// when
		mockHandler.execute();

		// then
		System.assertEquals(0, ((MockTriggerHandler)mockHandler.decoratedHandler).executionCount);
	}

	@IsTest
	static void it_should_allow_execution_if_current_user_is_allowed() {
		Set<String> allowedUsers = new Set<String>{ UserInfo.getUserName() };
		TriggerHandlerBlockUsers decorator = new TriggerHandlerBlockUsers(TriggerHandlerBlockUsers.Rule.ALLOW_NONE_EXCEPT, allowedUsers);
		TriggerHandlerBlockUsers mockHandler = buildHandler(decorator);

		// when
		mockHandler.execute();

		// then
		System.assertEquals(1, ((MockTriggerHandler)mockHandler.decoratedHandler).executionCount);
	}

	private static TriggerHandlerBlockUsers buildHandler(TriggerHandlerBlockUsers decorator) {
		TriggerHandlerBlockUsers mockHandler = (TriggerHandlerBlockUsers)new MockTriggerHandler().decorate(decorator);
		mockHandler.init(null);
		mockHandler.getTriggerContext().currentPhase = TriggerPhase.BEFORE_INSERT;
		return mockHandler;
	}

	public class MockTriggerHandler extends TriggerHandler {
		public Integer executionCount = 0;

		public override void beforeInsert() {
			executionCount += 1;
		}
	}
}