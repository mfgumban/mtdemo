xquery version "1.0-ml";

module namespace geo = "http://marklogic.com/mtdemo/lib/geocode-google";

import module namespace json = "http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";


declare function geo:geocode($address as xs:string)
as node()* {
  try {
    let $api-key := "AIzaSyBWRmSM4TU_dCdkW5ZyPcd_A9ipJCKM0Dk"
    let $request := fn:concat(
      "https://maps.googleapis.com/maps/api/geocode/xml?address=",
      xdmp:url-encode($address),
      "&amp;key=",
      $api-key
    )
    return xdmp:http-get($request, 
      <options xmlns="xdmp:http">
        <timeout>120</timeout>
      </options>
    )[2]
  }
  catch * {
    ()
  }
};