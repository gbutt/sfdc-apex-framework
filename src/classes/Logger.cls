public virtual class Logger implements I {
	public interface I {
		Boolean isDebugEnabled();
		void debug(Object message);
		void info(Object message);
		void warn(Object message);
		void error(Object message);
		void flush();
	}

	// default implementation
	public Logger() {
		this.logThreshold = LoggingLevel.DEBUG;
	}

	public LoggingLevel logThreshold {get; set;}
	public String category {get; set;}

	public Boolean isDebugEnabled() {
		return this.logThreshold.ordinal() <= LoggingLevel.DEBUG.ordinal();
	}
	public void debug(Object message) {
		log(LoggingLevel.DEBUG, message);
	}
	public void info(Object message) {
		log(LoggingLevel.INFO, message);
	}
	public void warn(Object message) {
		log(LoggingLevel.WARN, message);
	}
	public void error(Object message) {
		log(LoggingLevel.ERROR, message);
	}
	private void log(LoggingLevel logLevel, Object message) {
		System.debug(logLevel, message);
		if (this.logThreshold.ordinal() <= logLevel.ordinal()) {
			doLog(logLevel, message);
		}
	}
	protected virtual void doLog(LoggingLevel logLevel, Object message) {}
	public virtual void flush() {}

}