public class TriggerHandlerBlockUsers extends TriggerHandlerDecorator {

	private static Boolean isSandbox = false;

	static {
		isSandbox = [SELECT isSandbox FROM Organization LIMIT 1].isSandbox;
	}

	public enum Rule {
		ALLOW_NONE_EXCEPT,
		ALLOW_ALL_EXCEPT
	}

	Set<String> usernames;
	Rule blockType;

	public TriggerHandlerBlockUsers(Rule blockType, Set<String> usernames) {
		this.blockType = blockType;
		this.usernames = usernames;
	}

	public TriggerHandlerBlockUsers(Rule blockType, String username) {
		this.blockType = blockType;
		this.usernames = new Set<String>{username};
	}
	
	public override Boolean shouldExecute() {
		Boolean isBlocked = false;
		String currentUsername = UserInfo.getUserName();
		if (blockType == Rule.ALLOW_ALL_EXCEPT && hasUsername(currentUsername)) {
			isBlocked = true;
		}
		else if (blockType == Rule.ALLOW_NONE_EXCEPT && !hasUsername(currentUsername)) {
			isBlocked = true;
		}

		if (isBlocked) {
			log.info(currentUsername + ' is not allowed to execute ' + getHandlerName());
			return false;
		}

		return super.shouldExecute();
	}

	private Boolean hasUsername(String currentUsername) {
		if (usernames.contains(currentUsername)) {
			return true;
		}
		if (isSandbox){
			String subUsername = currentUsername.substring(0, currentUsername.lastIndexOf('.'));
			return usernames.contains(subUsername);
		}
		return false;
	}

	public static Builder builder() {
		return new Builder();
	}

	public class Builder {

		Rule blockRule;
		Set<String> usernames;

		public Builder() {
			this.usernames = new Set<String>();
		}

		public Builder allowAll() {
			this.blockRule = Rule.ALLOW_ALL_EXCEPT;
			return this;
		}

		public Builder allowNone() {
			this.blockRule = Rule.ALLOW_NONE_EXCEPT;
			return this;
		}

		public Builder except(String username) {
			this.usernames.add(username);
			return this;
		}

		public TriggerHandlerBlockUsers build() {
			return new TriggerHandlerBlockUsers(blockRule, usernames);
		}
	}
}