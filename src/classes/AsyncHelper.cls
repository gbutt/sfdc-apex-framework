public class AsyncHelper {

	public static void enqueueJob(Queueable queueableJob, String jobName) {
		if (canQueueJob()) {
			System.enqueueJob(queueableJob);
		} else {
			utilScheduledHelper.scheduleJobImmediate(ScheduledHandler.class, new Map<String,Object>{'queueable' => queueableJob}, jobName);
		}
	}

	public static void enqueueJobChain(Queueable[] jobQueue, String jobName, Boolean continueOnError) {
		if (jobQueue.size() > 0) {
			enqueueJob(new ChainedQueueable(jobQueue, jobName, continueOnError), jobName);
		}
	}

	private static Boolean canQueueJob() {
		return Limits.getQueueableJobs() < Limits.getLimitQueueableJobs();
	}

	public class ScheduledHandler implements utilScheduledDispatcher.IScheduleDispatched {
		public Map<String, Object> state {get;set;}
		public void setState(Map<String, Object> state) {
			this.state = state;
		}
		public void execute(SchedulableContext sc) {
			((Queueable)state.get('queueable')).execute(null);
		}
	}

	public class ChainedQueueable implements Queueable, Database.AllowsCallouts {

		private Queueable[] jobQueue {get;set;}
		private String jobName {get;set;}
		public Boolean continueOnError {get;set;}

		public ChainedQueueable(Queueable[] jobQueue, String jobName){
			this.jobQueue = jobQueue;
			this.jobName = jobName;
			this.continueOnError = false;
		}
		public ChainedQueueable(Queueable[] jobQueue, String jobName, Boolean continueOnError) {
			this(jobQueue, jobName);
			this.continueOnError = continueOnError;
		}

		public void execute(QueueableContext context) {
			try {
				Queueable currentJob = jobQueue.remove(0);
				currentJob.execute(context);
			} catch (Exception ex) {
				log.error(ex);
				if (!continueOnError) {
					throw ex;
				}
			}
			enqueueJobChain(jobQueue, jobName, continueOnError);
		}
	}
}