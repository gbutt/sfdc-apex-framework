@IsTest
public class LoggerTest {
	@IsTest
	static void it_should_log() {
		Logger log = new Logger();
		log.isDebugEnabled();
		log.debug('test');
		log.info('test');
		log.warn('test');
		log.error('test');
		log.flush();
	}
}