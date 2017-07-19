@IsTest
public class LoggerFactoryTest {
	@IsTest
	static void it_should_build_logger() {
		LoggerFactory.buildLogger();
		LoggerFactory.buildLogger(LoggerFactory.class);
	}
}