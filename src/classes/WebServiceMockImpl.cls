@isTest
public class WebServiceMockImpl implements WebServiceMock {

    public Integer called {get;set;}
    public Object stub {get; set;}
    public Object request {get; set;}
    public Map<String, Object> response {get; set;}
    public String endpoint {get; set;}
    public String soapAction {get; set;}
    public String requestName {get; set;}
    public String responseNS {get; set;}
    public String responseName {get; set;}
    public String responseType {get; set;}

    public Object responseElement {get;set;}

    public WebServiceMockImpl(Object responseElement) {
        this.responseElement = responseElement;
        this.called = 0;
    }

    public void doInvoke(Object stub,Object request,Map<String, Object> response,String endpoint,String soapAction,String requestName,String responseNS,String responseName,String responseType) {
        this.called++;

        this.stub = stub;
        this.request = request;
        this.response = response;
        this.endpoint = endpoint;
        this.soapAction = soapAction;
        this.requestName = requestName;
        this.responseNS = responseNS;
        this.responseName = responseName;
        this.responseType = responseType;

        response.put('response_x', this.responseElement);
   }
}