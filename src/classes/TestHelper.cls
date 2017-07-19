@IsTest
public class TestHelper {

	public static Id ID(Integer i, Schema.SObjectType sobType){
		String num = String.valueOf(i);
		return sobType.getDescribe().getKeyPrefix() + '0'.repeat(12-num.length()) + num;
	}

	static Integer idCount = 1;
	public static Id ID(Schema.SObjectType sobType) {
		return ID(idCount++, sobType);
	}
}