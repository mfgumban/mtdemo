xquery version "1.0-ml";

module namespace geo = "http://marklogic.com/ns/geo";

declare namespace nc = "http://release.niem.gov/niem/niem-core/3.0/";
declare namespace m = "http://release.niem.gov/niem/domains/maritime/3.2/";
declare namespace j = "http://marklogic.com/xdmp/json/basic";
declare namespace envelope = "http://marklogic.com/data-hub/envelope";

import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace json="http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";

declare option xdmp:mapping "false";

declare function geo:geoCodeFullAddress($address as xs:string) {
  try {
    let $p := "https://geocoding.geo.census.gov/geocoder/geographies/onelineaddress?vintage=Current_Current&amp;address=" || xdmp:url-encode($address) || "&amp;benchmark=Public_AR_Current&amp;format=json"
    let $response := xdmp:http-get($p, <options xmlns="xdmp:http">
      <timeout>120</timeout>
      </options>)[2]
      let $geoResponse := json:transform-from-json($response)
      let $coordinates := $geoResponse//j:coordinates
      let $lat := $coordinates/j:y/string()
      let $lon := $coordinates/j:x/string()
      let $county := $geoResponse//j:Counties/j:json/j:NAME/string()
      let $matchedAddress := fn:distinct-values($geoResponse//j:matchedAddress[1]/string())[1]
    let $r := 
      if ($response) then 
      object-node {
        "address": text {$matchedAddress},
        "county": text {$county},
        "lat": number-node {$lat},
        "lon": number-node {$lon}
    } else ()
    return $r
    } catch * {()}
};