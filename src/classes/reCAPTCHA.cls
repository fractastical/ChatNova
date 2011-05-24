public class reCAPTCHA {

        private static string secret = 'your secret key';
    public string publicKey { get { return 'your public key' ; }} 

        private static string baseUrl = 'http://api-verify.recaptcha.net/verify'; 

    /*
    reCAPTCHA API Documentation
    
    reCAPTCHA is a freely available CAPTCHA implementation. It distinguishes humans from computers. This may be useful for:
    
        * A registration page for a forum or wiki.
        * A comment form.
        * Hiding information that could be useful to spammers (we recommend the reCAPTCHA Mailhide API for this).
    
    How the reCAPTCHA API Works
    
    API diagram
    
       1. The user loads the web page with the reCAPTCHA challenge JavaScript embedded.
       2. The users browser requests a challenge from reCAPTCHA. reCAPTCHA gives the user a challenge and a token that identifies the challenge.
       3. The user fills out the web page form, and submits the result to your application server, along with the challenge token.
       4. reCAPTCHA checks the users answer, and gives you back a response.
       5. If true, generally you will allow the user access to some service or information. E.g. allow them to comment on a forum, register for a wiki, or get access to an email address. If false, you can allow the user to try again.
    
    This document describes the validation steps in the process. Our Client API is used to embed the reCAPTCHA on your website.
    
    Signing up for a reCAPTCHA Key
    
    In order to use reCAPTCHA, you need a public/private API key pair. This key pair helps to prevent an attack where somebody hosts a reCAPTCHA on their website, collects answers from their visitors and submits the answers to your site. You can sign up for a key on the reCAPTCHA Administration Portal.
    Key Scope
    
    Your reCAPTCHA token is valid only at the domain you sign up for and any subdomains (due to the potential attack mentioned above). Some users require keys for multiple sites, for example, a development server and a production server or simply multiple sites hosted on the same server. Three techniques can be used to work around this:
    
        * If one of your servers is "localhost" or "127.0.0.1", reCAPTCHA will not enforce the same-domain rule. Just use the same key as for the production server.
        * Generate a key for a broader scope. For example, if your application is a.example.com and your test server is test.corp.example.com, generate a key for example.com.
        * Generate a different key for each domain.
    
    Getting a reCAPTCHA Challenge
    
    Your application will need to display a reCAPTCHA challenge on your web page. This can be done with the Client API, a piece of JavaScript code which lets you embed the CAPTCHA on your website.
    
    Verifying the reCAPTCHA Solution
    
    URL     http://api-verify.recaptcha.net/verify
    Parameters (sent via POST)  
    privatekey (required)   Your private key
    remoteip (required)     The IP address of the user who solved the CAPTCHA.
    challenge (required)    The value of "recaptcha_challenge_field" sent via the form
    response (required)     The value of "recaptcha_response_field" sent via the form
    Response    The response from verify is a series of strings separated by \n. To read the string, split the line and read each field. New lines may be added in the future. Implementations should ignore these lines
    Line 1  "true" or "false". True if the reCAPTCHA was successful
    Line 2  if Line 1 is false, then this string will be an error code. reCAPTCHA can display the error to the user (through the error parameter of api.recaptcha.net/challenge). Implementations should not depend on error code names, as they may change in the future.
    
    Example: If your response looks like this:
    
    false
    incorrect-captcha-sol
    
    ... you can add '&error=incorrect-captcha-sol' to the challenge request URL, and the user will get an error code.

    */
    public string challenge {get; set;} { challenge = null; } 
    public string response {get; set; }  { response = null; } 

    public Boolean correctResponse { get; private set; } { correctResponse = false; } 
    
    public PageReference verify() {
      system.debug( 'verify called ');
          // first time thru, this parameter is null, so no request to make yet
      if ( challenge == null || response == null ) { 
            system.debug( 'verify called null ');
            return null; 
          }
                    
      HttpResponse r = makeRequest(  baseUrl ,
           'privatekey='+ secret + 
           '&remoteip=' + remoteHost + 
           '&challenge=' + challenge +
               '&response=' + response +
               '&error=incorrect-captcha-sol'
      );
        
          if ( r != null ) {  // is null when test methods run
            correctResponse = ( r.getBody().contains('true') );
          } 
          return null;  
    }

    public PageReference reset() {
        challenge = null;
        response = null; 
        return null; 
    }   

    public static HttpResponse makeRequest(string url, string body)  {
          HttpRequest req = new HttpRequest();   
          HttpResponse response = null;
          req.setEndpoint( url );
          req.setMethod('POST');
          req.setBody ( body);
          try {
            Http http = new Http();
            response = http.send(req);
            System.debug('response: '+ response);
            System.debug('body: '+ response.getBody());
           
          } catch( System.Exception e) {
             System.debug('ERROR: '+ e);
          }
          return response;
        }   
        
    public string remoteHost { get { string ret = '127.0.0.1';
        // also could use x-original-remote-host 
        map<string , string> hdrs = ApexPages.currentPage().getHeaders();
        if ( hdrs.get('x-original-remote-addr') != null)
            ret =  hdrs.get('x-original-remote-addr');
        else if ( hdrs.get('X-Salesforce-SIP') != null)
            ret =  hdrs.get('X-Salesforce-SIP');
        return ret;
    } }
        
    public static  testmethod void test_1() {
        reCaptcha re = new reCaptcha();
        string href = baseUrl ;
        re.challenge = re.response = 'foo';
        string publick = re.publicKey; 
        string host = re.remoteHost; 
        re.verify();
    }
    public static  testmethod void test_2() {
        reCaptcha re = new reCaptcha();
        re.verify();
    }
    
}