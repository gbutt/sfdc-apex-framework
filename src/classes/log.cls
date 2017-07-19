public class log {

	@TestVisible
	public static Logger.I logger { 
		get {
			if (logger == null) {
				logger = LoggerFactory.buildLogger();
			}
			return logger;
		}
		private set;
	}

	public static Boolean isDebugEnabled() {
		return logger.isDebugEnabled();
	}
	public static void debug(Object message) {
		logger.debug(message);
	}
	public static void info(Object message) {
		logger.info(message);
	}
	public static void warn(Object message) {
		logger.warn(message);
	}
	public static void error(Object message) {
		logger.error(message);
	}
	public static void flush() {
		logger.flush();
	}

}