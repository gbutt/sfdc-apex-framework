# Testing with Behavior-Driven Design (BDD)

We write tests using the testing philosophy from Behavior-Driven Development. Each test is designed to fit the following pattern called a specification:

`Given ... When ... Then ...`

The specification pattern allows our tests to reflect the acual requirements our code satisfies. For example we have a requirement that when the Contact Email field changes we need to call out to our MDM system. We would organize this requirement into a test specification like so:

```
Given: an existing Contact record
When: the Email field changes
Then: we should notify MDM
```

Next we need tranform our specification into a test:

```java

@IsTest
static void it_should_update_mdm_when_email_changes() {
	// Given: an existing Contact record
	Contact c = new Contact(Email = 'old@email.com');
	insert c;

	// setup a callout mock
	HttpCalloutMockImpl httpMock = new HttpCalloutMockImpl();
	Test.setMock(httpMock);

	// When: the Email field changes
	Test.startTest();
	c.Email = 'new@email.com';
	update c;
	Test.stopTest();

	// Then: we should notify MDM
	System.assertEquals(1, httpMock.called);
}
```

Our test should fail because we haven't written any code yet. That's a good thing, because it tells us that our assertions are working. If you have a test that passes before you write any code then you should review your test code for mistakes.

Our test is short and simple. That's a good thing because it is hard for mistakes to hide in simple tests.

Next we need to write some code to make our test pass.

```java
public class ContactCallMdm extends ContactTaskTrigger {
	public override void afterUpdate() {
		mdmUtil.notifyMdm(newRecords);
	}
}
```

Obviously this code is not what we want in the end, but it should get the test to pass. We run the tests and they still fail. Why? Because we didn't register our handler in ContactTriggerHandler

```java
private static TriggerHandlerExecutor buildExecutor() {
	...
	TriggerHandler.I callMdm = new ContactCallMdm();

	return TriggerHandlerExecutor.builder()
		...
		.addHandler(TriggerPhase.AFTER_UPDATE, callMdm)
		...
		.build();
}
```

Our tests should be passing now. However we missed something in our specification that is called the negative case.
```
Given: an existing Contact record
When: the Email field DOES NOT change
Then: we SHOULD NOT notify MDM
```

```java

@IsTest
static void it_should_not_update_mdm_when_email_does_not_change() {
	// Given: an existing Contact record
	Contact c = new Contact(Email = 'old@email.com');
	insert c;

	// setup a callout mock
	HttpCalloutMockImpl httpMock = new HttpCalloutMockImpl();
	Test.setMock(httpMock);

	// When: the Email field DOES NOT change
	Test.startTest();
	update c;
	Test.stopTest();

	// Then: we SHOULD NOT notify MDM
	System.assertEquals(0, httpMock.called);
}
```

We write a test for the negative case and it fails. Now we change our trigger handler to look like this:


```java
public override void afterUpdate() {
	List<Contact> mdmContacts = new List<Contact>();
	for (Contact c : newRecords) {
		if (c.Email != oldRecordsMap.get(c.Id).Email) {
			mdmContacts.add(c);
		}
	}
	mdmUtil.notifyMdm(mdmContacts);
}
```

We run the tests again and they both pass. We could stop here, but our code is kind of confusing, and we want to make it easier for another developer to follow. So we refactor:

```java
// notify MDM then the contact email changes
public override void afterUpdate() {
	List<Contact> mdmNotifyContacts = new List<Contact>();
	for (Contact c : newRecords) {
		if (shouldNotifyMdm(c)) {
			mdmNotifyContacts.add(c);
		}
	}
	mdmUtil.notifyMdm(mdmNotifyContacts);
}
private Boolean shouldNotifyMdm(Contact c) {
	return c.Email != oldRecordsMap.get(c.Id).Email;
}
```

We rerun the tests and they pass, so we know we didn't break anything. 

Now it's time for us to work on the next specification:

```
Given: an existing Contact record
When: the one of the configurable fields changes
Then: we should notify MDM
```

We start by creating positive and negative tests for this specification:

```java
@IsTest
static void it_should_call_mdm_when_configurable_field_changes() {
	// Given: an existing Contact record
	Contact c = new Contact(FirstName = 'Old Name');
	insert c;

	// setup a callout mock
	HttpCalloutMockImpl httpMock = new HttpCalloutMockImpl();
	Test.setMock(httpMock);

	// setup configuable fields
	mdmUtil.contactFields.add('FirstName');

	// When: the any configurable field changes
	Test.startTest();
	c.FirstName = 'New Name';
	update c;
	Test.stopTest();

	// Then: we should notify MDM
	System.assertEquals(1, httpMock.called);
}

@IsTest
static void it_should_not_call_mdm_when_configurable_field_does_not_change() {
	// Given: an existing Contact record
	Contact c = new Contact(FirstName = 'Old Name');
	insert c;

	// setup a callout mock
	HttpCalloutMockImpl httpMock = new HttpCalloutMockImpl();
	Test.setMock(httpMock);

	// setup configuable fields
	mdmUtil.contactFields.add('LastName');

	// When: the any configurable field changes
	Test.startTest();
	c.FirstName = 'New Name';
	update c;
	Test.stopTest();

	// Then: we should notify MDM
	System.assertEquals(0, httpMock.called);
}
```

We run the tests and they fail, which is what we want. Remember we need to ensure our tests are capable of failing. Now let's make one more refactor to our handler:

```java
private Boolean shouldNotifyMdm(Contact newContact) {
	Contact oldContact = oldRecordsMap.get(newContact.Id);
	return hasChanged(newContact, oldContact,  'Email');
}
private Boolean hasChanged(Contact c1, Contact c2, String field) {
	return c1.get(field) != c2.get(field);
}
```

We rerun the tests. The new tests are still failing, but the first two are passing. So we didn't break anything.

Now let's get our two new tests to pass:

```java
private Boolean shouldNotifyMdm(Contact newContact) {
	Contact oldContact = oldRecordsMap.get(newContact.Id);
	for (String field : mdmUtil.contactFields) {
		if (hasChanged(newContact, oldContact, field)) {
			return true;
		}
	}
	return hasChanged(newContact, oldContact,  'Email');
}
private Boolean hasChanged(Contact c1, Contact c2, String field) {
	return c1.get(field) != c2.get(field);
}
```

Rerun the tests and they pass.