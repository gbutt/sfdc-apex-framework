@isTest
private class utilScheduledDispatcherTest {
	
	public without sharing class ScheduledRenewalsHandler 
		implements utilScheduledDispatcher.IScheduleDispatched {
		public Map<String, Object> state {get;set;}
		public void setState(Map<String, Object> state) {
			this.state = state;
		}
		public void execute(SchedulableContext sc) {
			utilScheduledDispatcherTest.testFlag = true;
		}
	}
	
	public static Boolean testFlag;
	
	static testMethod void can_create_new_instance_of_scheduled_dispatcher() {
		utilScheduledDispatcher dispatcher = new utilScheduledDispatcher(ScheduledRenewalsHandler.class, null);
		system.assert(dispatcher != null); 
		
		testFlag = false;
		dispatcher.execute(null);
		System.assert(testFlag == true);
	}
	
	static testMethod void can_schedule_new_job() {
		DateTime fireTime = DateTime.Now().addSeconds(10);
		String nextFireCron = utilScheduledHelper.createCronExpressionFromDateTime(fireTime);
		
		Test.startTest();
		utilScheduledHelper.scheduleJob(ScheduledRenewalsHandler.class, null, nextFireCron);
		Test.stopTest();
		
		String jobName = ScheduledRenewalsHandler.class.getName();
		List<CronTrigger> jobs = [
			SELECT Id, CronJobDetail.Name, State, NextFireTime 
			FROM CronTrigger 
			WHERE CronJobDetail.Name = :jobName
		];
		
		system.assert(jobs.size() == 1);
		system.debug('Job State: ' + jobs[0].State);
		system.assert(jobs[0].State == 'WAITING');
	}
	
	static testMethod void can_abort_scheduled_job() {
		DateTime fireTime = DateTime.Now().addSeconds(10);
		String nextFireCron = utilScheduledHelper.createCronExpressionFromDateTime(fireTime);
		utilScheduledHelper.scheduleJob(ScheduledRenewalsHandler.class, null, nextFireCron);
		
		String jobName = ScheduledRenewalsHandler.class.getName();
		List<CronTrigger> jobs = [
			SELECT Id, CronJobDetail.Name, State, NextFireTime 
			FROM CronTrigger 
			WHERE CronJobDetail.Name = :jobName
		];
		
		system.assert(jobs.size() == 1);
		
		Test.startTest();
		utilScheduledHelper.abortJob(jobName);
		Test.stopTest();
		
		jobs = [
			SELECT Id, CronJobDetail.Name, State, NextFireTime 
			FROM CronTrigger 
			WHERE CronJobDetail.Name = :jobName
		];
		
		system.assert(jobs.size() == 0);
	}
}