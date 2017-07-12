xquery version "1.0-ml";
module namespace prac = "http://marklogic.com/mtdemo/lib/practitioner";

import module namespace geo = "http://marklogic.com/mtdemo/lib/geocode-google" at "/lib/geocode-google.xqy";
import module namespace json = "http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";


declare function prac:envelope($content as map:map, $context as map:map)
as map:map*
{
  let $orig-uri := map:get($content, "uri")
  let $orig-content := map:get($content, "value")

  let $uri := $orig-uri
  let $provider := $orig-content/*:Provider
  let $practitioner := prac:create($provider)
  let $content := 
  <envelope>
    <meta>
      <id>{ $provider/@ProviderID/fn:string() }</id>
      <name>{ fn:string-join(($provider/*:FirstName/fn:string(), $provider/*:LastName/fn:string()), " ") }</name>
      <addresses>
      {
        for $address in $practitioner/address
        let $line := fn:string-join((
          $address/line/fn:string(), 
          $address/city/fn:string(),
          $address/county/fn:string(),
          $address/state/fn:string(),
          $address/postalCode/fn:string()), " ")
        let $geocode := geo:geocode($line)
        return
        <address>
          <line>{ $line }</line>
          <formatted>{ $geocode//formatted_address/fn:string() }</formatted>
          <location>
            <lat>{ $geocode//geometry/location/lat/fn:string() }</lat>
            <long>{ $geocode//geometry/location/lng/fn:string() }</long>
          </location>
        </address>
      }
      </addresses>
    </meta>
    { $practitioner }
    <core>{ $orig-content }</core>
  </envelope>

  return map:new((
    map:entry("uri", $uri),
    map:entry("value", document { $content })
  ))
};

declare function prac:create($provider as node())
as node()
{
  let $id := $provider/@ProviderID/fn:string()
  let $addresses := $provider/*:Practice/*:PracticeAddress

  return
  <practitioner>
    <resourceType>Practitioner</resourceType>
    <id>{ $id }</id>
    {
      prac:create-identifier($id)
    }
    {
      prac:create-practitioner-narrative($provider)
    }
    <active>true</active>
    <name>
      <family>{ $provider/*:LastName/fn:string() }</family>
      <given>{ $provider/*:FirstName/fn:string() }</given>
    </name>
    {
      let $home-points := $provider/*:ProviderAddress[fn:contains(./*:AddressType/*:AddressTypeDescription/fn:string(), "home")]
      return (
        prac:create-contact-points("work", "phone", (
          $provider/*:Practice/*:PhoneNumber
        )),
        prac:create-contact-points("home", "phone", (
          $provider/*:Practice/*:AfterHoursPhoneNumber,
          $home-points/*:PhoneNumber
        )),
        prac:create-contact-points("work", "email", (
          $provider/*:Practice/*:EmailAddress
        ))
      )
    }
    {
      for $address in $addresses
      let $lines := ($address/*:Address/fn:string(), $address/*:Address2/fn:string())
      return
      <address>
        <use>work</use>
        { for $line in $lines return <line>{ $line }</line> }
        <city>{ $address/*:City/fn:string() }</city>
        <county>{ $address/*:County/fn:string() }</county>
        <state>{ $address/*:State/fn:string() }</state>
        <postalCode>{ $address/*:PostalCode/fn:string() }</postalCode>
      </address>
    }
    <gender>{ fn:lower-case($provider/*:Gender/*:GenderDescription/fn:string()) }</gender>
    <birthDate>{ $provider/*:BirthDate/fn:string() }</birthDate>
    {
      for $license in $provider/*:ProviderLicense
      return
      <qualification>
        { 
          prac:create-identifier($license/@ID/fn:string()) 
        }
        <code>{ $license/*:LicenseType/fn:string() }</code>
        <period>
          <start>{ $license/*:IssueDate/fn:string() }</start>
          <end>{ $license/*:ExpirationDate/fn:string() }</end>
        </period>
      </qualification>
    }
  </practitioner>
};

declare function prac:create-identifier($value as xs:string) 
as node() 
{
  <identifier>
    <system>https://proview.caqh.org</system>
    <value>{ $value }</value>
  </identifier>
};

declare function prac:create-practitioner-narrative($provider as node())
as node()
{
  let $text :=
  <div xmlns="http://www.w3.org/1999/xhtml">
    <p><b>Generated Narrative with Details</b></p>
    <p><b>id</b>: { $provider/@ProviderID/fn:string() }</p>
    <p><b>name</b>: { fn:string-join(($provider/*:FirstName/fn:string(), $provider/*:LastName/fn:string()), " ") }</p>
  </div>
  (: TODO: maybe use xslt against practitioner? :)
  return 
  <text>
    <status>generated</status>
    <div>{ xdmp:quote($text) }</div>
  </text>
};

(:
  $use (required): home | work | temp | old | mobile
  $system: phone | fax | email | pager | url | sms | other
:)
declare function prac:create-contact-points($use as xs:string, $system as xs:string, $nodes as node()*)
as node()*
{
  for $contact-point in fn:distinct-values($nodes/fn:string()) return
  <telecom>
    <use>{ $use }</use>
    <value>{ $contact-point }</value>
    <system>{ $system }</system>
  </telecom>
};

(:
  $use: home | work | temp | old
  $type: postal | physical | both
:)
declare function prac:create-address($use as xs:string, $type as xs:string, $nodes as node()*)
as node()*
{
  () (: TODO - distinct addresses :)
};

declare function prac:json-config()
as map:map
{
  let $config := json:config("custom")
  let $_ := (
    map:put($config, "array-element-names", ("identifier", "name", "given", "telecom", "address", "qualification"))
  )
  return $config
};

(: $node is assumed to be /envelope/practitioner :)
declare function prac:to-json($node as node())
as node()
{
  json:transform-to-json($node, prac:json-config())/practitioner
};

declare function prac:create-bundle($items as node()*)
as node()* {
  let $bundle := json:object()
  let $_ := (
    map:put($bundle, "resourceType", "Bundle"),
    map:put($bundle, "id", sem:uuid-string()),
    map:put($bundle, "meta", object-node { "lastUpdated": fn:current-dateTime() }),
    map:put($bundle, "type", "searchset"),
    map:put($bundle, "total", fn:count($items)),
    map:put($bundle, "docs", json:to-array($items))
  )

  return xdmp:to-json($bundle)
};

declare function prac:get-by-id($practitioner-id as xs:string)
as node()*
{
  let $practitioners := cts:search(
    fn:collection("providers")/envelope/practitioner,
    cts:and-query((
      cts:path-range-query("/envelope/meta/id", "=", $practitioner-id, ("collation=http://marklogic.com/collation/codepoint"))
    )),
    ("unfiltered")
  )
  return prac:to-json($practitioners[1])
};

declare function prac:get-by-name($names as xs:string*)
as node()*
{
  let $practitioners := cts:search(
    fn:collection("providers")/envelope/meta/name,
    cts:and-query((
      cts:word-query($names, ("case-insensitive"))
    )),
    ("filtered")
  )/../../practitioner
  return prac:to-json($practitioners)
};

(: TODO: search parameters :)
declare function prac:search($limit as xs:integer)
as node()*
{
  let $practitioners := cts:search(
    fn:collection("providers")/envelope/practitioner,
    (),
    ()
  )
  return prac:create-bundle(prac:to-json($practitioners[1 to $limit]))
};

