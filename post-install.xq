xquery version "3.1";

(:~
 : This post-install script sets permissions on the data collection hierarchy.
 : When pre-install creates the data collection, its permissions are admin/dba. 
 : This ensures the collections are owned by the default user and group for the app.
 :)
 
import module namespace config="http://joewiz.org/ns/xquery/airlock/config" at "modules/config.xqm";

declare namespace sm="http://exist-db.org/xquery/securitymanager";
declare namespace system="http://exist-db.org/xquery/system";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";

(: The following external variables are set by the repo:deploy function :)

(: file path pointing to the exist installation directory :)
declare variable $home external;
(: path to the directory containing the unpacked .xar package :)
declare variable $dir external;
(: the target collection into which the app is deployed :)
declare variable $target external;


(: Helper function to recursively create a collection hierarchy :)
declare function local:mkcol-recursive($collection as xs:string, $components as xs:string*) {
    if (exists($components)) then
        let $newColl := concat($collection, "/", $components[1])
        return (
            xmldb:create-collection($collection, $components[1]),
            local:mkcol-recursive($newColl, subsequence($components, 2))
        )
    else
        ()
};

(: Create a collection hierarchy :)
declare function local:mkcol($collection as xs:string, $path as xs:string) {
    local:mkcol-recursive($collection, tokenize($path, "/"))
};

(:~
 : Set user and group to be owner by values in repo.xml
 :)
declare function local:set-data-collection-permissions($resource as xs:string) {
    if (sm:get-permissions(xs:anyURI($resource))/sm:permission/@group = config:repo-permissions()?group) then
        ()
    else
        (
            sm:chown($resource, config:repo-permissions()?user),
            sm:chgrp($resource, config:repo-permissions()?group),
            sm:chmod(xs:anyURI($resource), config:repo-permissions()?mode)
        )
};

(: Create the data collection hierarchy :)

xmldb:create-collection($config:app-data-parent-col, $config:app-data-col-name),
let $col-names := 
    (
        $config:bases-col-name,
        $config:tokens-col-name
    )
for $col-name in $col-names
return
    xmldb:create-collection($config:app-data-col, $col-name),
    
(: Create the blank bases.xml and tokens.xml documents:)

if (doc-available($config:bases-doc)) then
    ()
else
    xmldb:store($config:bases-col, $config:bases-doc-name, <bases/>),
if (doc-available($config:tokens-doc)) then
    ()
else
    xmldb:store($config:tokens-col, $config:tokens-doc-name, <token-sets/>),

(: Set user and group ownership on the data collection hierarchy :)

for $resource in (
    $config:app-data-col, 
    $config:bases-col,
    $config:bases-doc,
    $config:tokens-col,
    $config:tokens-doc
    )
return
    local:set-data-collection-permissions($resource)
,

(: Set login.xq handler to admin/dba with sticky bit so that login can call dba functions to check group membership :)

xs:anyURI($target || "/modules/login.xq") !
    (
        sm:chown(., "admin"),
        sm:chgrp(., "dba"),
        sm:chmod(., "rwxrwsr-x")
    )