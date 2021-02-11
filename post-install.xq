xquery version "3.1";

import module namespace xmldb="http://exist-db.org/xquery/xmldb";

(: the target collection into which the app is deployed :)
declare variable $target external;

sm:chown(xs:anyURI($target || "/snapshot.xq"), "admin"),
sm:chmod(xs:anyURI($target || "/snapshot.xq"), "rwsr-xr-x")