@isTest
global class LimitsMonitor_WebServiceMock implements HttpCalloutMock {
   global HttpResponse respond(HTTPRequest req){
    LimitsMonitor_Controller.ObjectLimitResponse resp = new LimitsMonitor_Controller.ObjectLimitResponse();
    LimitsMonitor_Controller.ObjectLimitData data = new LimitsMonitor_Controller.ObjectLimitData();
    data.Type = 'CustomFields';
    data.Label = 'Custom Fields';
    data.Remaining = 500;
    data.Max = 1000;
    resp.records = new List<LimitsMonitor_Controller.ObjectLimitData>{data};
    HttpResponse res = new HttpResponse();
    res.setStatus('OK');
    res.setStatusCode(200);
    res.setBody(JSON.serialize(resp));
    return res;
  }
}