@IsTest
public class logTest {
	@IsTest
	static void it_should_log() {
		log.isDebugEnabled();
		log.debug('test');
		log.info('test');
		log.warn('test');
		log.error('test');
		log.flush();
	}
}