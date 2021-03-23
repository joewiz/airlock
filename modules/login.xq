xquery version "3.1";

declare namespace api="http://e-editiones.org/roasted/test-api";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace app="http://joewiz.org/ns/xquery/airlock/app" at "app.xqm";
import module namespace bases="http://joewiz.org/ns/xquery/airlock/bases" at "bases.xqm";
import module namespace config="http://joewiz.org/ns/xquery/airlock/config" at "config.xqm";
import module namespace keys="http://joewiz.org/ns/xquery/airlock/keys" at "keys.xqm";
import module namespace snapshot="http://joewiz.org/ns/xquery/airlock/snapshot" at "snapshot.xqm";
import module namespace update="http://joewiz.org/ns/xquery/airlock/update" at "update.xqm";

import module namespace errors="http://e-editiones.org/roaster/errors";
import module namespace roaster="http://e-editiones.org/roaster";
import module namespace rutil="http://e-editiones.org/roaster/util";


(:~
 : list of definition files to use
 :)
declare variable $api:definitions := "modules/login.json";


(:~
 : You can add application specific route handlers here.
 : Having them in imported modules is preferred.
 :)


(: end of route handlers :)

(:~
 : This function "knows" all modules and their functions
 : that are imported here 
 : You can leave it as it is, but it has to be here
 :)
declare function api:lookup($name as xs:string) {
    function-lookup(xs:QName($name), 1)
};

roaster:route($api:definitions, api:lookup#1)
