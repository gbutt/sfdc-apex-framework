public with sharing class utilScheduledHelper {
	
	public static final String CRON_MIDNIGHT_FIRST_OF_THE_MONTH = '0 0 0 1 * ?';
	
	/*
	The bootstrap can be called by anonymous apex to schedule jobs.
	*/
	public static void scheduledBootstrap() {
		//scheduleJob(ScheduledRenewalsHandler.class, CRON_MIDNIGHT_FIRST_OF_THE_MONTH);
	}

	public static void scheduleJobImmediate(Type targetType, Map<String, Object> state) {
		scheduleJobImmediate(targetType, state, null);
	}

	public static void scheduleJobImmediate(Type targetType, Map<String, Object> state, String jobName) {
		Datetime soon = Datetime.now().addSeconds(2);
		String cronExpression = createCronExpressionFromDateTime(soon);
		scheduleJob(targetType, state, jobName, cronExpression, false);
	}
	
	public static void scheduleJob(Type targetType, Map<String, Object> state, String cronExpression) {
		scheduleJob(targetType, state, null, cronExpression, false);
	}
	
	public static void scheduleJob(Type targetType, Map<String, Object> state, String jobName, String cronExpression, Boolean abortJob) {
		if (jobName == null) {
			jobName = targetType.getName();
		}
		if (abortJob) {
			abortJob(jobName);
		}
		utilScheduledDispatcher scheduledDispatcher = new utilScheduledDispatcher(targetType, state);
		System.schedule(jobName, cronExpression, scheduledDispatcher);
	}

	public static void abortJob(String jobName) {
		Set<String> stateList = new Set<String>{'COMPLETED', 'ERROR', 'DELETED'};
		List<CronTrigger> jobs = [
			SELECT Id, CronJobDetail.Name, State, NextFireTime 
			FROM CronTrigger 
			WHERE CronJobDetail.Name = :jobName
			AND State NOT IN :stateList
		];
		
		if (jobs.size()>0) {
			System.abortJob(jobs[0].Id);
		}
	}
	
	public static String createCronExpressionFromDateTime(DateTime fireTime) {
		List<String> timeParts = new List<String>();
		timeParts.add(String.valueof(fireTime.second()));
		timeParts.add(String.valueof(fireTime.minute()));
		timeParts.add(String.valueof(fireTime.hour()));
		timeParts.add(String.valueof(fireTime.day()));
		timeParts.add(String.valueof(fireTime.month()));
		timeParts.add('?');
		timeParts.add(String.valueof(fireTime.year()));
		
		return String.join(timeParts, ' ');
	}
}