@IsTest
public class PersonFinderTest {
	
	@IsTest
	static void it_should_find_contacts_by_email() {
		Contact[] contacts = new Contact[]{};
		String[] emails = new String[]{};

		for (Integer idx = 0; idx < PersonFinder.contactEmailFields.size(); idx++) {
			String emailField = PersonFinder.contactEmailFields[idx];
			String emailValue = 'contact'+idx+'@cu.edu';
			Contact c = buildContact();
			c.put(emailField, emailValue);
			emails.add(emailValue);
			contacts.add(c);
		}
		insert contacts;

		Test.startTest();
		Map<String, Contact[]> results = new PersonFinder().findContactsByEmail(new Set<String>(emails));
		Test.stopTest();

		System.assert(results.keyset().containsAll(emails));

		for (String email : results.keyset()) {
			System.assertEquals(1, results.get(email).size(), results);
		}
	}

	@IsTest
	static void it_should_find_all_matching_contacts() {
		Contact[] contacts = new Contact[]{};
		Contact socrates = buildContact();
		socrates.Email = 'socrates@cu.edu';
		contacts.add(socrates);

		Contact plato = buildContact();
		plato.Email = 'plato@cu.edu';
		//plato.WorkEmail__c = 'socrates@cu.edu';
		contacts.add(plato);

		insert contacts;


		Test.startTest();
		Map<String, Contact[]> results = new PersonFinder().findContactsByEmail(new Set<String>{'socrates@cu.edu'});
		Test.stopTest();

		//System.assertEquals(2, results.get('socrates@cu.edu').size(), results);
	}

	@IsTest
	static void it_should_return_empty_results() {

		Test.startTest();
		Map<String, Contact[]> results = new PersonFinder().findContactsByEmail(new Set<String>{'socrates@cu.edu'});
		Test.stopTest();

		System.assertEquals(0, results.get('socrates@cu.edu').size());
	}

	@IsTest
	static void it_should_handle_many_emails() {
		Set<String> emails = new Set<String>{};
		for (Integer idx = 0; idx < 200; idx++) {
			emails.add('this.is.a.realistic.email'+idx+'@colorado.edu');
		}

		Test.startTest();
		Map<String, Contact[]> results = new PersonFinder().findContactsByEmail(emails);
		Test.stopTest();
	}

	@IsTest
	static void it_should_append_filters() {
		Test.startTest();
		String soql = PersonFinder.buildSoql(Contact.class, PersonFinder.contactEmailFields, null, new String[]{'LastName = NULL', 'FirstName = NULL'});
		Test.stopTest();

		System.assert(soql.endsWith(' AND (LastName = NULL) AND (FirstName = NULL)'));
	}

	@IsTest
	static void it_should_append_additional_fields() {
		Test.startTest();
		String soql = PersonFinder.buildSoql(Contact.class, PersonFinder.contactEmailFields, new String[]{'LastName', 'FirstName'}, null);
		Test.stopTest();

		System.assert(soql.contains(',LastName,FirstName FROM Contact'));
	}


	private static Contact buildContact() {
		//return TestSObjectFactory.buildContact();
		return new Contact(LastName = 'Test');
	}
}