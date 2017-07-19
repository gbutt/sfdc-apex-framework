@IsTest
global class HttpCalloutMockImpl implements HttpCalloutMock {

	public Integer called {get;set;}
	public HttpResponse resp {get;set;}
	public HttpRequest req {get;set;}

	public HttpCalloutMockImpl(HttpResponse resp) {
		this.resp = resp;
		this.called = 0;
	}

    global HttpResponse respond(HttpRequest req) {
    	this.called++;
        this.req = req;
        return resp;
    }
}