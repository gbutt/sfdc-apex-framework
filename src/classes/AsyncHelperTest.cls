@IsTest
public class AsyncHelperTest {
	@IsTest
	static void it_should_enqueue_job() {
		TestQueueable queueable = new TestQueueable();

		// when
		Test.startTest();
		AsyncHelper.enqueueJob(queueable, TestQueueable.class.getName());

		// then
		System.assertEquals(1, Limits.getQueueableJobs());
		Test.stopTest();

		System.assertEquals(1, executionCount);
	}

	@IsTest
	static void it_should_schedule_job_when_queueables_are_depleted() {
		TestQueueable queueable = new TestQueueable();

		Integer queueableLimit = Limits.getLimitQueueableJobs();

		Test.startTest();
		for (Integer i = 0; i < queueableLimit; i++) {
			AsyncHelper.enqueueJob(new TestQueueable(), TestQueueable.class.getName());
		}
		System.assertEquals(queueableLimit, Limits.getQueueableJobs());

		// when
		AsyncHelper.enqueueJob(queueable, TestQueueable.class.getName());

		// then
		System.assertEquals(queueableLimit, Limits.getQueueableJobs());
		List<CronTrigger> jobs = [
			SELECT Id, CronJobDetail.Name, State, NextFireTime 
			FROM CronTrigger
			WHERE CronJobDetail.Name LIKE '%AsyncHelperTest.TestQueueable'
			AND State NOT IN ('COMPLETED', 'ERROR', 'DELETED')
		];
		System.assertEquals(1, jobs.size(), JSON.serialize(jobs));
		Test.stopTest();

		System.assertEquals(queueableLimit + 1, executionCount);
	}

	@IsTest
	static void it_should_enqueue_a_job_chain() {
		Queueable[] jobChain = new Queueable[]{
			new TestQueueable()
		};

		// when
		Test.startTest();
		AsyncHelper.enqueueJobChain(jobChain, 'jobChain', false);

		// then
		System.assertEquals(1, Limits.getQueueableJobs());
		Test.stopTest();

		System.assertEquals(1, executionCount);
	}

	@IsTest
	static void ChainedQueueable_should_continue_on_error() {
		TestQueueable errorThrowingJob = new TestQueueable();
		errorThrowingJob.throwError = true;
		Queueable[] jobChain = new Queueable[]{
			errorThrowingJob,
			new TestQueueable()
		};

		AsyncHelper.ChainedQueueable chainJob = new AsyncHelper.ChainedQueueable(jobChain, 'testJob');
		chainJob.continueOnError = true;
		Boolean exceptionThrown = false;

		// when
		Test.startTest();
		try {
			chainJob.execute(null);
		} catch (TestException ex) {
			exceptionThrown = true;
		}

		System.assertEquals(1, Limits.getQueueableJobs());
		Test.stopTest();

		// then
		System.assertEquals(false, exceptionThrown);
		System.assertEquals(2, executionCount);
	}

	@IsTest
	static void ChainedQueueable_should_not_continue_on_error() {
		TestQueueable errorThrowingJob = new TestQueueable();
		errorThrowingJob.throwError = true;
		Queueable[] jobChain = new Queueable[]{
			errorThrowingJob,
			new TestQueueable()
		};

		AsyncHelper.ChainedQueueable chainJob = new AsyncHelper.ChainedQueueable(jobChain, 'testJob');
		chainJob.continueOnError = false;
		Boolean exceptionThrown = false;

		// when
		Test.startTest();
		try {
			chainJob.execute(null);
		} catch (TestException ex) {
			exceptionThrown = true;
		}

		System.assertEquals(0, Limits.getQueueableJobs());
		Test.stopTest();

		// then
		System.assertEquals(true, exceptionThrown);
		System.assertEquals(1, executionCount);
	}

	@IsTest
	static void it_should_not_enqueue_a_job_chain_if_the_list_is_empty() {
		// when
		AsyncHelper.enqueueJobChain(new Queueable[]{}, 'jobChain', false);

		// then
		System.assertEquals(0, Limits.getQueueableJobs());
	}

	private static Integer executionCount = 0;

	public class TestQueueable implements Queueable {

		public Boolean throwError = false;

		public void execute(QueueableContext context) {
			executionCount += 1;
			if (throwError) {
				throw new TestException('it throws the error');
			}
		}
	}

	public class TestException extends Exception {}
}