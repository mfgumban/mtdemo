xquery version "1.0-ml";

module namespace app = "http://marklogic.com/rest-api/resource/practitioner-search";

declare namespace roxy = "http://marklogic.com/roxy";
declare namespace rapi = "http://marklogic.com/rest-api";
import module namespace prac = "http://marklogic.com/mtdemo/lib/practitioner" at "/lib/practitioner.xqy";


(:
 : To add parameters to the functions, specify them in the params annotations.
 : Example
 :   declare %roxy:params("uri=xs:string", "priority=xs:int") app:get(...)
 : This means that the get function will take two parameters, a string and an int.
 :
 : To report errors in your extension, use fn:error(). For details, see
 : http://docs.marklogic.com/guide/rest-dev/extensions#id_33892, but here's
 : an example from the docs:
 : fn:error(
 :   (),
 :   "RESTAPI-SRVEXERR",
 :   ("415","Raven","nevermore"))
 :)

(:
 :)
declare 
%roxy:params("")
function app:get(
  $context as map:map,
  $params  as map:map
) as document-node()*
{
  map:put($context, "output-types", "application/json"),
  map:put($context, "output-status", (200, "OK")),

  let $response := prac:search($params)

  return (
    document { $response },
    xdmp:set-response-code(200, "OK"),
    xdmp:set-response-content-type("application/fhir+json")
  )
};