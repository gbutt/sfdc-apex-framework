public class TriggerHelper {

	public static Boolean isDisabled(String className) {
    	Trigger_Settings__c ts = Trigger_Settings__c.getInstance(className);
    	return (ts == null ? false : ts.Disabled__c);
	}
}