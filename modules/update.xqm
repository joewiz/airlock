xquery version "3.1";

module namespace update="http://joewiz.org/ns/xquery/airlock/update";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "html";
declare option output:media-type "text/html";

declare function update:base-metadata($request as map(*)) {
    let $base-url := $request?parameters?base-url
    let $base-id := $request?parameters?base-id
    let $file := request:get-uploaded-file-data("files[]")
    let $base-col := 
        if (xmldb:collection-available("/db/apps/airlock-data/bases/" || $base-id)) then
            "/db/apps/airlock-data/bases/" || $base-id
        else
            xmldb:create-collection("/db/apps/airlock-data/bases", $base-id)
    let $store := xmldb:store("/db/apps/airlock-data/bases/" || $base-id, "base-metadata.json", $fil)
    return
        <div>
            <h1>Success</h1>
            <p>Successfully stored {$store}</p>
            <p><a href="{$base-url}/bases/{$base-id}">Return to browsing base {$base-id}</a></p>
        </div>
};