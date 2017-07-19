/***
Adapted from the great Dan Appleman. 
For more on this and many other great patterns - buy his book - http://advancedapex.com/
This class can be used to schedule any scheduled job without risk of locking the class.
DO NOT CHANGE THIS CLASS! It is locked by the scheduler. Instead make changes to ScheduledHelper or your own IScheduleDispatched class
To use:
	1) Create a new class to handle your job. This class should implement utilScheduledDispatcher.IScheduleDispatched
	2) Create a new instance of utilScheduledDispatcher with the type of your new class.
	3) Schedule the utilScheduledDispatcher instead of directly scheduling your new class.
	See ScheduledRenewalsHandler for a working example.
***/
global class utilScheduledDispatcher implements Schedulable {
	private Type targetType;
	private Map<String, Object> state;
	
	public utilScheduledDispatcher(Type targetType, Map<String, Object> state) {
		System.debug('Creating new dispatcher for class: ' + targetType.getName());
		this.targetType = targetType;
		this.state = state;
	}
	
	global void execute(SchedulableContext sc) {
		IScheduleDispatched instance = ((IScheduleDispatched)targetType.newInstance());
		instance.setState(state);
		instance.execute(sc);
	}
	
	
	public interface IScheduleDispatched {
		void setState(Map<String, Object> state);
		void execute(SchedulableContext sc);
	}
}