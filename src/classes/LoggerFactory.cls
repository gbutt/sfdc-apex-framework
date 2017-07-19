// TODO: implement custom setting for logger configuration
public class LoggerFactory {
	public static Logger.I buildLogger() {
		return new Logger();
	}
	public static Logger.I buildLogger(Type classType) {
		return new Logger();
	}
	public static Logger.I buildLogger(String className) {
		return new Logger();
	}
	//public static Logger.I fromConfig(String loggerConfigJSON) {
	//	LoggingConfig loggerConfig = (LoggingConfig)JSON.deserializeStrict(loggerConfigJSON, LoggingConfig.class);
	//	return loggerConfig.build();
	//}

	//public class LoggingConfig {
	//    public LoggingLevel logThreshold {get;set;}
	//    public String loggerImpl {get;set;}

	//    public Logger.I build() {
	//    	Logger logger = (Logger)Type.forName(loggerImpl).newInstance();
	//    	logger.logThreshold = logThreshold;
	//    	return logger;
	//    }
	//}
}