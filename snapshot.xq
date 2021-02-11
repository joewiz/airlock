xquery version "3.1";

import module namespace airtable="http://joewiz.org/ns/xquery/airtable";
import module namespace app="http://joewiz.org/ns/xquery/airvac/app" at "app.xqm";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "html";
declare option output:media-type "text/html";

declare function local:get-table($api-key as xs:string, $base-id as xs:string, $base-metadata as map(*)) {
    let $table := airtable:list-records($api-key, $base-id, $base-metadata?name, true(), (), (), (), (), (), (), ())
    return
        (: pass error messages back through :)
        if ($table instance of element()) then
            $table
        else
            map { 
                "name": $base-metadata?name, 
                "id": $base-metadata?id,
                "primaryColumnName": $base-metadata?primaryColumnName,
                "columns": $base-metadata?columns?*,
                "records": array:join($table?records)
            }
};

(: ensure columns entry contains an array :)
declare function local:fix-columns-entry($table as map(*)*) {
    map:merge((
        for $key in map:keys($table)
        return
            if ($key eq "columns" and map:get($table, $key) instance of map(*)) then
                map:entry("columns", array { $table?columns } )
            else
                map:entry($key, $table($key))
    ))
};

let $base-id := request:get-parameter("base-id", ())
let $base := doc("/db/apps/airvac-data/bases/bases.xml")//base[id eq $base-id]
let $base-id := $base/id/string()
let $base-name := $base/name/string()
let $api-key := $base/api-key/string()
let $snapshots := doc("/db/apps/airvac-data/bases/" || $base-id || "/snapshots.xml")/snapshots
let $next-id := ($snapshots/snapshot[last()]/id, "0")[1] cast as xs:integer + 1
let $prepare :=
    (
        xmldb:create-collection("/db/apps/airvac-data/bases/" || $base-id, "snapshots"),
        xmldb:create-collection("/db/apps/airvac-data/bases/" || $base-id || "/snapshots", $next-id),
        xmldb:create-collection("/db/apps/airvac-data/bases/" || $base-id || "/snapshots/" || $next-id, "tables"),
        xmldb:copy-resource(
            "/db/apps/airvac-data/bases/" || $base-id,
            "base-metadata.json",
            "/db/apps/airvac-data/bases/" || $base-id || "/snapshots/" || $next-id,
            "base-metadata.json"
        ),
        update insert element snapshot { element id { $next-id }, element created-dateTime { current-dateTime() } } into $snapshots
    )

(: https://github.com/Airtable/airtable.js/issues/12#issuecomment-349987627
 :
 : for exporting table metadata, start from https://airtable.com/appe0AfkruafOCgrw/api/docs :)

let $tables := json-doc("/db/apps/airvac-data/bases/" || $base-id || "/snapshots/" || $next-id || "/base-metadata.json")?*
let $store :=
    for $base-metadata in $tables
    let $contents := local:get-table($api-key, $base-id, $base-metadata)
    (:
    if ($contents instance of element()) then
        app:wrap(
            element div {
                element h1 { error },
                element pre { $contents => serialize() }
            },
            "Error"
        )
    else
    :)
    return
        xmldb:store(
            "/db/apps/airvac-data/bases/" || $base-id || "/snapshots/" || $next-id || "/tables",
            ($base-metadata?name || ".json")
                (: space, nbsp, plus, colon, slash, bullet point :)
                => replace("[ &#160;+:/&#x2022;]", "-")
                (: parentheses :)
                => replace("[\(\)]", "")
                => replace("-+", "-")
                => replace("^-", "_")
                => lower-case(),
            $contents => serialize(map{"method": "json", "indent": true()})
        )
let $summarize := 
    let $resources := xmldb:get-child-resources("/db/apps/airvac-data/bases/" || $base-id || "/snapshots/" || $next-id || "/tables")
    let $tables := $resources ! json-doc("/db/apps/airvac-data/bases/" || $base-id || "/snapshots/" || $next-id || "/tables/" || .)
    let $records-count := 
        sum(
            for $table in $tables
            return
                array:size($table?records)
        )
    let $fields-count := 
        sum(
            for $table in $tables 
            return
                if ($table?columns instance of array(*)) then 
                    array:size($table?columns) 
                else 
                    1
        )
    let $cells-count := 
        sum(
            for $record in $tables?records?* 
            return 
                map:size($record?fields)
        )
    return
        update insert (
            element tables-count { count($tables) },
            element records-count { $records-count }, 
            element fields-count { $fields-count },
            element cells-count { $cells-count }
        )
        into $snapshots//snapshot[id eq $next-id cast as xs:string]
let $content :=
    element div {
        element p { "Stored " || count($store) || " resources:" },
        element ul { $store ! element li { . } },
        element p {
            element a {
                attribute href { "browse.xq?base-id=" || $base-id || "&amp;snapshot-id=" || $next-id },
                "View snapshot " || $next-id
            }
        }
    }
return
    app:wrap($content, "Created snapshot " || $next-id)
