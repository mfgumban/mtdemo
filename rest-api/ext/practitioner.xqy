xquery version "1.0-ml";

module namespace app = "http://marklogic.com/rest-api/resource/practitioner";

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

  let $practitioner-id := map:get($params, "practitionerId")

  let $response := 
  if ($practitioner-id) then
    (: get by ID :)
    prac:get-by-id($practitioner-id)
  else 
    ()

  return (
    document { $response },
    xdmp:set-response-code(200, "OK"),
    xdmp:set-response-content-type("application/fhir+json")
  )
(:
  let $url := "http://marklogic.com/test/Practitioner"
  
  let $response :=
  object-node {
    "resourceType": "ddd",
    "id": text {sem:uuid-string()},
    "meta": object-node {
        "lastUpdated": fn:current-dateTime()
    },
    "type": "searchset",
    "total": number-node{4},
    "link": array-node {
        object-node {
          "relation": "self",
          "url": $url
        }
    }


  }
:)
(:
  "resourceType": "Bundle",
  "id": "87ed571e-6b2c-4a37-ab0f-fd7983be3aba",
  "meta": {
    "lastUpdated": "2017-06-23T04:02:52.472+00:00"
  },
  "type": "searchset",
  "total": 5,
  "link": [
    {
      "relation": "self",
      "url": "https://sb-fhir-dstu2.smarthealthit.org/smartdstu2/open/Practitioner"
    }
  ],:)
};

(:
 :)
declare 
%roxy:params("")
function app:put(
    $context as map:map,
    $params  as map:map,
    $input   as document-node()*
) as document-node()?
{
  map:put($context, "output-types", "application/xml"),
  map:put($context, "output-status", (201, "Created")),
  document { "PUT called on the ext service extension" }
};

(:
 :)
declare 
%roxy:params("")
%rapi:transaction-mode("update")
function app:post(
    $context as map:map,
    $params  as map:map,
    $input   as document-node()*
) as document-node()*
{
  map:put($context, "output-types", "application/xml"),
  map:put($context, "output-status", (201, "Created")),
  document { "POST called on the ext service extension" }
};

(:
 :)
declare 
%roxy:params("")
function app:delete(
    $context as map:map,
    $params  as map:map
) as document-node()?
{
  map:put($context, "output-types", "application/xml"),
  map:put($context, "output-status", (200, "OK")),
  document { "DELETE called on the ext service extension" }
};
