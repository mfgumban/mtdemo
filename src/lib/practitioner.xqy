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
      <name>{ fn:string-join(($provider/*:FirstName/fn:string(), $provider/*:MiddleName/fn:string(), $provider/*:LastName/fn:string()), " ") }</name>
      <addresses>
      {
        for $address in $practitioner/address
        let $line := fn:normalize-space(fn:string-join((
          $address/line/fn:string(), 
          $address/city/fn:string(),
          $address/county/fn:string(),
          $address/state/fn:string(),
          $address/postalCode/fn:string()), " "))
        return
        <address>
          <line>{ $line }</line>
          <postal-code>{ $address/postalCode/fn:string() }</postal-code>
          <state>{ $address/state/fn:string() }</state>
          <location>
            <lat>{ $address/extension/extension[1]/valueDecimal/fn:string() }</lat>
            <long>{ $address/extension/extension[2]/valueDecimal/fn:string() }</long>
          </location>
        </address>
      }
      </addresses>
      {
        prac:get-provider-taxonomy($provider/*:ProviderType/*:ProviderTypeAbbreviation/fn:string())
      }
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
  let $taxonomy := prac:get-provider-taxonomy($provider/*:ProviderType/*:ProviderTypeAbbreviation/fn:string())

  return
  <practitioner>
    <resourceType>Practitioner</resourceType>
    <id>{ $id }</id>
    {
      prac:create-identifier($id)
    }
    <extension>
      <url>http://hl7.org/fhir/StructureDefinition/practitioner-classification</url>
      <valueCodeableConcept>
        <code>{ $taxonomy/code/fn:string() }</code>
        <display>{ $taxonomy/description/fn:string() }</display>
      </valueCodeableConcept>
    </extension>
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
      let $one-line := fn:normalize-space(fn:string-join((
          $lines,
          $address/*:City/fn:string(),
          $address/*:County/fn:string(),
          $address/*:State/fn:string(),
          $address/*:PostalCode/fn:string()), " "))

      let $geocode := geo:geocode($one-line)
      return
      <address>
        <use>work</use>
        { for $line in $lines return <line>{ $line }</line> }
        <city>{ $address/*:City/fn:string() }</city>
        <county>{ $address/*:County/fn:string() }</county>
        <state>{ $address/*:State/fn:string() }</state>
        <postalCode>{ $address/*:PostalCode/fn:string() }</postalCode>
        <extension>
          <url>http://hl7.org/fhir/StructureDefinition/geolocation</url>
          <extension>
            <url>latitude</url>
            <valueDecimal>{ $geocode/GeocodeResponse/result[1]/geometry/location/lat/fn:string() }</valueDecimal>
          </extension>
          <extension>
            <url>longitude</url>
            <valueDecimal>{ $geocode/GeocodeResponse/result[1]/geometry/location/lng/fn:string() }</valueDecimal>
          </extension>
        </extension>
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
    {
      for $language in $provider/*:Language/*:Language/*:LanguageName/fn:string()
      return
      <communication>
        <coding>{ prac:get-lang-code($language) }</coding>
        <text>{ $language }</text>
      </communication>
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

declare function prac:get-lang-code($language as xs:string)
as xs:string*
{
  if ($language eq "French") then "fr"
  else if ($language eq "Dutch") then "nl"
  else ()
};

declare function prac:json-config()
as map:map
{
  let $config := json:config("custom")
  let $_ := (
    map:put($config, "array-element-names", ("identifier", "name", "given", "telecom", "address", "qualification", "communication", "extension"))
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

declare function prac:search($params as map:map)
as node()*
{
  let $_ := xdmp:log("---PRAC-SEARCH---")
  let $_ := xdmp:log($params)
  let $limit := (xs:integer(map:get($params, "_count")), 50)[1]
  let $id := map:get($params, "_id")
  (:let $name := map:get($params, "name"):)
  let $postal-code := map:get($params, "address-postalcode")
  let $state := map:get($params, "address-state")
  let $prac-type := map:get($params, "practitioner-type")

  let $query := cts:and-query((
    if ($id) then cts:path-range-query("/envelope/meta/id", "=", $id, ("collation=http://marklogic.com/collation/codepoint")) else (),
    if ($postal-code) then prac:get-postal-code-query($postal-code) else (),
    if ($state) then cts:path-range-query("/envelope/meta/addresses/address/state", "=", $state, ("collation=http://marklogic.com/collation/codepoint")) else (),
    if ($prac-type) then
      cts:or-query((
        cts:element-word-query(xs:QName("code"), $prac-type, ("case-insensitive")),
        cts:element-word-query(xs:QName("description"), $prac-type, ("case-insensitive"))
      ))
    else ()
  ))
  let $_ := xdmp:log($query)

  let $practitioners := cts:search(
    fn:collection("providers")/envelope/practitioner,
    $query,
    ("unfiltered")
  )
  return prac:create-bundle(prac:to-json($practitioners[1 to $limit]))
};

declare function prac:get-postal-code-query($input as xs:string)
as cts:query*
{
  let $comps := fn:tokenize($input, "\$")
  let $postal-code := $comps[1]
  let $distance-miles := $comps[2]
  let $_ := xdmp:log("---PRAC-GET-POSTAL-CODE-QUERY---")
  let $_ := xdmp:log(($input, $postal-code, $distance-miles))
  return if (fn:empty($distance-miles)) then
    cts:path-range-query("/envelope/meta/addresses/address/postal-code", "=", $postal-code, ("collation=http://marklogic.com/collation/codepoint"))
  else
    (: get approx. coords of the zip code area :)
    let $location := prac:get-zip-coords($postal-code)
    let $_ := xdmp:log($location)
    return cts:element-pair-geospatial-query(
      xs:QName("location"), xs:QName("lat"), xs:QName("long"),
      cts:circle(xs:double($distance-miles), cts:point($location/LAT, $location/LNG)),
      ("coordinate-system=wgs84")
    )
};

declare function prac:get-zip-coords($zipcode as xs:string)
{
  cts:search(
    fn:collection("zipcodes"),
    cts:path-range-query("/ZIP", "=", $zipcode, ("collation=http://marklogic.com/collation/codepoint")),
    ("unfiltered")
  )[1]
};

(: TODO: make this use matching+triples perhaps? :)
(: using http://www.wpc-edi.com/reference/codelists/healthcare/health-care-provider-taxonomy-code-set/ :)
declare function prac:get-provider-taxonomy($provider-type-abbr as xs:string)
as node()*
{
  if ($provider-type-abbr eq "DO") then
    <providerTaxonomy>
      <code>207K00000X</code>
      <description>Allopathic &amp; Osteopathic Physicians &#8722; Allergy &amp; Immunology</description>
    </providerTaxonomy>
  else if ($provider-type-abbr eq "NP") then
    <providerTaxonomy>
      <code>363LA2200X</code>
      <description>Nurse Practitioner &#8722; Adulth Health</description>
    </providerTaxonomy>
  else if ($provider-type-abbr eq "MD") then
    <providerTaxonomy>
      <code>208D00000X</code>
      <description>General Practice</description>
    </providerTaxonomy>
  else ()
};

