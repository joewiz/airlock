xquery version "3.1";

declare namespace api="http://e-editiones.org/roasted/test-api";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace login="http://exist-db.org/xquery/login" at "resource:org/exist/xquery/modules/persistentlogin/login.xql";

import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";

import module namespace bases="http://joewiz.org/ns/xquery/airlock/bases" at "bases.xqm";
import module namespace snapshot="http://joewiz.org/ns/xquery/airlock/snapshot" at "snapshot.xqm";
import module namespace update="http://joewiz.org/ns/xquery/airlock/update" at "update.xqm";

import module namespace errors="http://e-editiones.org/roaster/errors";
import module namespace roaster="http://e-editiones.org/roaster";
import module namespace rutil="http://e-editiones.org/roaster/util";


(:~
 : list of definition files to use
 :)
declare variable $api:definitions := ("api.json");


(:~
 : You can add application specific route handlers here.
 : Having them in imported modules is preferred.
 :)

(:~
 : Either login a user (if parameter `user` is specified) or check if the current user is logged in.
 : Setting parameter `logout` to any value will log out the current user.
 :)
declare function api:login($request as map(*)) {
    let $loginDomain := 
(:        $request?loginDomain:)
        $config:login-domain
    return
    (
        if ($request?parameters?user) then
            login:set-user($loginDomain, (), false())
        else
            (),
        let $user := request:get-attribute($loginDomain || ".user")
        return
            if (exists($user)) then
                map {
                    "user": $user,
                    "groups": array { sm:get-user-groups($user) },
                    "dba": sm:is-dba($user)
                }
            else
                error($errors:UNAUTHORIZED, "Wrong user or password", map {
                    "user": $user,
                    "domain": $request?loginDomain
                })
    )
};


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
