xquery version "3.1";

(:~
 : Configuration options for the application and a set of helper functions to access 
 : the application context.
 :)

module namespace config="http://exist-db.org/xquery/apps/config";

declare namespace system="http://exist-db.org/xquery/system";

declare namespace expath="http://expath.org/ns/pkg";
declare namespace repo="http://exist-db.org/xquery/repo";

declare variable $config:login-domain := "org.joewiz.airlock.login";

(: Determine the application root collection from the current module load path :)
declare variable $config:app-root := 
    let $rawPath := system:get-module-load-path()
    let $modulePath :=
        (: strip the xmldb: part :)
        if (starts-with($rawPath, "xmldb:exist://")) then
            if (starts-with($rawPath, "xmldb:exist://embedded-eXist-server")) then
                substring($rawPath, 36)
            else if (starts-with($rawPath, "xmldb:exist://null")) then
                substring($rawPath, 19)
            else
                substring($rawPath, 15)
        else
            $rawPath
    return
        substring-before($modulePath, "/modules")
;

(: Default collection and resource names for binary assets and extracted package metadata :)

declare variable $config:app-data-parent-col := "/db/apps";
declare variable $config:app-data-col-name := "airlock-data";
declare variable $config:bases-col-name := "bases";
declare variable $config:snapshots-col-name := "snapshots";
declare variable $config:tables-json-col-name := "tables-json";
declare variable $config:tables-xml-col-name := "tables-xml";

declare variable $config:app-data-col := $config:app-data-parent-col || "/" || $config:bases-col-name;
declare variable $config:bases-col := $config:app-data-col || "/" || $config:bases-col-name;

declare variable $config:bases-doc-name := "bases.xml";
declare variable $config:base-metadata-doc-name := "base-metadata.json";

declare variable $config:bases-doc := $config:bases-col || "/" || $config:bases-doc-name;



(:~
 : Returns the repo.xml descriptor for the current application.
 :)
declare function config:repo-descriptor() as element(repo:meta) {
    doc(concat($config:app-root, "/repo.xml"))/repo:meta
};

(:~
 : Returns the permissions information from the repo.xml descriptor.
 :)
declare function config:repo-permissions() as map(*) { 
    config:repo-descriptor()/repo:permissions ! 
        map { 
            "user": ./@user/string(), 
            "group": ./@group/string(),
            "mode": ./@mode/string()
        }
};

(:~
 : Returns the expath-pkg.xml descriptor for the current application.
 :)
declare function config:expath-descriptor() as element(expath:package) {
    doc(concat($config:app-root, "/expath-pkg.xml"))/expath:package
};

(:~
 : For debugging: generates a table showing all properties defined
 : in the application descriptors.
 :)
declare function config:app-info($node as node(), $params as element(parameters)?, $modes as item()*) {
    let $expath := config:expath-descriptor()
    let $repo := config:repo-descriptor()
    return
        <table class="app-info">
            <tr>
                <td>app collection:</td>
                <td>{$config:app-root}</td>
            </tr>
            {
                for $attr in ($expath/@*, $expath/*, $repo/*)
                return
                    <tr>
                        <td>{node-name($attr)}:</td>
                        <td>{$attr/string()}</td>
                    </tr>
            }
        </table>
};