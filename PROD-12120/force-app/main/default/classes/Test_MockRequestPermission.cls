@isTest
global class Test_MockRequestPermission implements HttpCalloutMock{
    
	global HTTPResponse respond(HTTPRequest req) {   	
        // Create a fake response
        HttpResponse res = new HttpResponse();        
        res.setHeader('Content-Type', 'application/json; charset=UTF-8');
        res.setBody('{"status":"success"}');
        res.setStatusCode(200);
        return res; 
    }

}