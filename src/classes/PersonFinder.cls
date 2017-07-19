/*
	Person Finder - find a lead or contact by email or phone
	Person finder accepts a list of Emails and it will return a list of matched persons grouped by email.
	It will look across all Email fields to find matches.
	
	Example: 
		Say we have a couple email address: 'teddy@prez.com' and 'franklin@prez.com'
		and say we have a couple contacts for teddy, but none for franklin.
		We can pass a list of the emails to person finder and it will return a map with all matches, keyed by email.
		input: new String[]{'teddy@prez.com', 'franklin@prez.com'}
		output: new Map<String, Contact[]> { 
			'teddy@prez.com' => list of matched contacts
			'franklin@prez.com' => empty list of contacts
		}


*/
public with sharing class PersonFinder {

	public static final List<String> contactEmailFields {get;private set;}
	public static final List<String> leadEmailFields {get;private set;}
	public static final List<String> contactPhoneFields {get;private set;}
	public static final List<String> leadPhoneFields {get;private set;}

	static {
		contactEmailFields = new List<String> {};
		contactPhoneFields = new List<String> {};
		for(Schema.SObjectField field : Contact.getSobjectType().getDescribe().fields.getMap().values()){
			Schema.DescribeFieldResult dField = field.getDescribe();
		    if(dField.getType() == Schema.DisplayType.EMAIL) {
		        contactEmailFields.add(dField.getName());
		    } else if (dField.getType() == Schema.DisplayType.PHONE) {
		    	contactPhoneFields.add(dField.getName());
		    }
		}
		leadEmailFields = new List<String> {};
		leadPhoneFields = new List<String> {};
		for(Schema.SObjectField field : Lead.getSobjectType().getDescribe().fields.getMap().values()){
			Schema.DescribeFieldResult dField = field.getDescribe();
		    if(dField.getType() == Schema.DisplayType.EMAIL) {
		        leadEmailFields.add(dField.getName());
		    } else if (dField.getType() == Schema.DisplayType.PHONE) {
		    	leadPhoneFields.add(dField.getName());
		    }
		}
	}

	private SoqlExecutor soqlExecutor {get;set;}

	public PersonFinder() {
		this(true);
	}

	public PersonFinder(Boolean withSharing) {
		if (withSharing) {
			this.soqlExecutor = new WithSharingSoqlExecutor();
		} else {
			this.soqlExecutor = new WithoutSharingSoqlExecutor();
		}
	}

	public Map<String, Contact[]> findContactsByEmail(Set<String> emails) {
		return (Map<String, Contact[]>)findContactsByEmail(emails, null, null);
	}
	public Map<String, Contact[]> findContactsByEmail(Set<String> emails, String[] additionalFields, String[] filters) {
		return (Map<String, Contact[]>)findBySet(emails, Contact.class, contactEmailFields, additionalFields, filters);
	}

	public Map<String, Contact[]> findContactsByPhone(Set<String> phones) {
		return (Map<String, Contact[]>)findContactsByPhone(phones, null, null);
	}
	public Map<String, Contact[]> findContactsByPhone(Set<String> phones, String[] additionalFields, String[] filters) {
		return (Map<String, Contact[]>)findBySet(phones, Contact.class, contactPhoneFields, additionalFields, filters);
	}
	
	public Map<String, Lead[]> findLeadsByEmail(Set<String> emails) {
		return (Map<String, Lead[]>)findLeadsByEmail(emails, null, null);
	}
	public Map<String, Lead[]> findLeadsByEmail(Set<String> emails, String[] additionalFields, String[] filters) {
		return (Map<String, Lead[]>)findBySet(emails, Lead.class, leadEmailFields, additionalFields, filters);
	}
	
	public Map<String, Lead[]> findLeadsByPhone(Set<String> phones) {
		return (Map<String, Lead[]>)findLeadsByPhone(phones, null, null);
	}
	public Map<String, Lead[]> findLeadsByPhone(Set<String> phones, String[] additionalFields, String[] filters) {
		return (Map<String, Lead[]>)findBySet(phones, Lead.class, leadPhoneFields, additionalFields, filters);
	}

	public Map<String, SObject[]> findBySet(Set<String> setToMatch, Type entityType, List<String> fieldsToSearch, List<String> additionalFields, List<String> filters) {
		Map<String, Set<SObject>> foundPersonsByEmail = new Map<String, Set<SObject>>{};
		for (String key : new List<String>(setToMatch)) {
			foundPersonsByEmail.put(key, new Set<SObject>());
		}

		String soql = buildSoql(entityType, fieldsToSearch, additionalFields, filters);
		SObject[] found = soqlExecutor.query(soql, setToMatch);

		for (SObject c : found) {
			for (String field : fieldsToSearch) {
				String testMatch = (String)c.get(field);
				if (foundPersonsByEmail.keyset().contains(testMatch)) {
					foundPersonsByEmail.get(testMatch).add(c);
				}
			}
		}

		log.info(foundPersonsByEmail);

		// convert to lists for easy casting
		Map<String, SObject[]> results = new Map<String, SObject[]>{};
		for (String key : foundPersonsByEmail.keyset()) {
			results.put(key, new List<SObject>(foundPersonsByEmail.get(key)));
		}

		return results;
	}

	@TestVisible
	private static String buildSoql(Type entityType, List<String> searchFields, List<String> additionalFields, List<String> filters) {
		String emailSoql = 'SELECT Id,' + String.join(searchFields, ',');
		if (additionalFields != null) {
			emailSoql += ',' + String.join(additionalFields, ',');
		}
		emailSoql += ' FROM ' + entityType.getName() + ' WHERE (' + String.join(searchFields, ' IN :setToMatch OR ') + ' IN :setToMatch)';
		if (filters != null) {
			emailSoql += ' AND (' + String.join(filters, ') AND (') + ')';
		}
		return emailSoql;
	}

	private with sharing class WithSharingSoqlExecutor implements SoqlExecutor {
		public SObject[] query(String soql, Set<String> setToMatch) {
			return Database.query(soql);
		}
	}	

	private without sharing class WithoutSharingSoqlExecutor implements SoqlExecutor {
		public SObject[] query(String soql, Set<String> setToMatch) {
			return Database.query(soql);
		}
	}

	private interface SoqlExecutor {
		SObject[] query(String soql, Set<String> setToMatch);
	}
}