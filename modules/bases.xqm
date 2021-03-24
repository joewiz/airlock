xquery version "3.1";

module namespace bases="http://joewiz.org/ns/xquery/airlock/bases";

import module namespace app="http://joewiz.org/ns/xquery/airlock/app" at "app.xqm";
import module namespace config="http://joewiz.org/ns/xquery/airlock/config" at "config.xqm";

import module namespace airtable="http://joewiz.org/ns/xquery/airtable";
import module namespace markdown="http://exist-db.org/xquery/markdown";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "html";
declare option output:media-type "text/html";

(: 
 : TODO
 : - implement remaining data types in bases:render-field
 : - implement remaining field typeOptions
 : - show field name instead of field ID when displaying formulaTextParsed
:)


(: I captured this list of class pairings from Airtable's multiselect color picker. I don't have a definitive list of color-to-css-class mappings, but any missing ones should be here:

    <ul>
        <span class="blueBright text-white"/>
        <span class="blueDark1 text-blue-light2"/>
        <span class="blueLight1 text-blue-dark1"/>
        <span class="blueLight2 text-blue-dark1"/>
        <span class="cyanBright text-white"/>
        <span class="cyanDark1 text-cyan-light2"/>
        <span class="cyanLight1 text-cyan-dark1"/>
        <span class="cyanLight2 text-cyan-dark1"/>
        <span class="grayBright text-white"/>
        <span class="grayDark1 text-gray-light2"/>
        <span class="grayLight1 text-gray-dark1"/>
        <span class="grayLight2 text-gray-dark1"/>
        <span class="greenBright text-white"/>
        <span class="greenDark1 text-green-light2"/>
        <span class="greenLight1 text-green-dark1"/>
        <span class="greenLight2 text-green-dark1"/>
        <span class="orangeBright text-white"/>
        <span class="orangeDark1 text-orange-light2"/>
        <span class="orangeLight1 text-orange-dark1"/>
        <span class="orangeLight2 text-orange-dark1"/>
        <span class="pinkBright text-white"/>
        <span class="pinkDark1 text-pink-light2"/>
        <span class="pinkLight1 text-pink-dark1"/>
        <span class="pinkLight2 text-pink-dark1"/>
        <span class="purpleBright text-white"/>
        <span class="purpleDark1 text-purple-light2"/>
        <span class="purpleLight1 text-purple-dark1"/>
        <span class="purpleLight2 text-purple-dark1"/>
        <span class="redBright text-white"/>
        <span class="redDark1 text-red-light2"/>
        <span class="redLight1 text-red-dark1"/>
        <span class="redLight2 text-red-dark1"/>
        <span class="tealBright text-white"/>
        <span class="tealDark1 text-teal-light2"/>
        <span class="tealLight1 text-teal-dark1"/>
        <span class="tealLight2 text-teal-dark1"/>
        <span class="yellowBright text-white"/>
        <span class="yellowDark1 text-yellow-light2"/>
        <span class="yellowLight1 text-yellow-dark1"/>
        <span class="yellowLight2 text-yellow-dark1"/>
    </ul>

The values used in Indexing Sandbox are: 

    blue,
    blueDarker,
    cyan,
    gray,
    green,
    orange,
    pink,
    pinkMedium,
    purple,
    purpleDark,
    purpleMedium,
    red,
    redDark,
    redDarker,
    teal,
    tealDarker,
    yellow

:)
declare variable $bases:color-to-css-class :=
    map {
        "blue": "blueBright text-white",
        "blueDarker": "blueDark1 text-blue-light2",
        "cyan": "cyanBright text-white",
        "gray": "grayBright text-white",
        "grayDark": "grayDark1 text-gray-light2",
        "green": "greenBright text-white",
        "greenDark": "greenDark1 text-green-light2",
        "orange": "orangeBright text-white",
        "pink": "pinkBright text-white",
        "pinkDark": "pinkDark1 text-pink-light2",
        "pinkMedium": "pinkLight1 text-pink-dark1",
        "purple": "purpleBright text-white",
        "purpleDark": "purpleDark1 text-purple-light2",
        "purpleMedium": "purpleLight1 text-purple-dark1",
        "red": "redBright text-white",
        "redDark": "redDark1 text-red-light2",
        "redDarker": "redDark1 text-red-light2",
        "teal": "tealBright text-white",
        "tealDarker": "tealDark1 text-teal-light2",
        "yellow": "yellowBright text-white",
        "yellowDark": "yellowDark1 text-yellow-light2"
    }
;

declare function bases:render-airtable-flavored-markdown($markdown) {
    $markdown
    => replace("\*\*", "")
    => replace("&#10;", "&#10;&#10;")
    => markdown:parse()
};

declare function bases:render-field($base-url, $base-id, $snapshot-id, $tables, $table, $record, $field-key) {
    let $fields := $record?fields
    let $field := $fields?($field-key)
    let $columns := $table?columns
    let $column := $columns?*[?name eq $field-key]
    let $type := $column?type
    let $type-options := $column?typeOptions
    return
        switch ($type)
            (: TODO: add handling for these types:
                - formula(text|date)
                - lookup(error|text|multilineText|foreignKey)
                - rollup
                - select
                - checkbox
                - date
                - number
                - collaborator
                - multipleAttachment
            :)
            case "text" return
                if ($type-options?validatorName eq "url") then
                    element a {
                        attribute href {
                            $field
                        },
                        $field
                    }
                else
                    $field
            case "multilineText"
            case "richText" return
                bases:render-airtable-flavored-markdown($field)
            case "foreignKey" return
                let $foreign-table-id := $column?foreignTableId
                let $foreign-table := $tables[?id eq $foreign-table-id]
                let $primary-column-name := $foreign-table?primaryColumnName
                return
                    if (array:size($field) gt 1) then
                        element ul {
                            for $foreign-record-id in $field?*
                            let $foreign-record := $foreign-table?records?*[?id eq $foreign-record-id]
                            let $foreign-record-label := $foreign-record?fields?($primary-column-name)
                            return
                                element li {
                                    element a {
                                        attribute href { $base-url || "/bases/" || $base-id || "/snapshots/" || $snapshot-id || "/" || $foreign-table-id || "/records/" || $foreign-record-id },
                                        $foreign-record-label
                                    }
                                }
                        }
                    else
                        let $foreign-record-id := $field
                        let $foreign-record := $foreign-table?records?*[?id eq $foreign-record-id]
                        let $foreign-record-label := $foreign-record?fields?($primary-column-name)
                        return
                            element a {
                                attribute href { $base-url || "/bases/" || $base-id || "/snapshots/" || $snapshot-id || "/" || $foreign-table-id || "/records/" || $foreign-record-id },
                                $foreign-record-label
                            }
            case "multiSelect" return
                let $values := $field?*
                let $choices := $type-options?choices
                return
                    if (count($values) gt 1) then
                        element ol {
                            let $ordered-values := sort($values, (), function($value) { index-of($type-options?choiceOrder?*, $value) })
                            for $value in $ordered-values
                            let $color := $choices?*[?name eq $value]?color
                            return
                                element li {
                                    element span {
                                        attribute class { "badge rounded-pill " || $bases:color-to-css-class?($color) },
                                        $value
                                    }
                                }
                        }
                    else
                        let $value := $values
                        let $color := $choices?*[?name eq $value]?color
                        return
                            element span {
                                attribute class { "badge rounded-pill " || $bases:color-to-css-class?($color) },
                                $value
                            }
            case "multipleAttachment" return
                let $attachments := $field?*
                for $attachment in $attachments
                let $filename := $attachment?filename
                let $type := $attachment?type
                let $url := $attachment?url
                let $size := $attachment?size
                return
                    switch ($type)
                        case "image/jpeg" case "application/pdf" return
                            let $thumbnails := $attachment?thumbnails
                            let $large := $thumbnails?large
                            return
                                element p {
                                    element a {
                                        attribute href { $url },
                                        element img {
                                            attribute src { 
                                                $large?url
                                            }
                                        }
                                    }
                                }
                        default return
                            "unknown image type " || $type
            default return
                if ($field instance of array(*)) then
                    if (array:size($field) gt 1) then
                        element ul {
                            $field?* ! element li { . } 
                        }
                    else
                        $field?*
                (: "Position Length" : { "specialValue" : "NaN" } :)
                else if ($field instance of map(*)) then
                    $field?*
                else
                    $field
};

declare function bases:view($request as map(*)) {
    let $base-url := $request?parameters?base-url
    let $base-id := $request?parameters?base-id
    let $snapshot-id := $request?parameters?snapshot-id
    let $table-id := $request?parameters?table-id
    let $field-id := $request?parameters?field-id
    let $record-id := $request?parameters?record-id
    let $bases := doc("/db/apps/airlock-data/bases/bases.xml")//base
    let $base := $bases[id eq $base-id]
    let $snapshots := doc("/db/apps/airlock-data/bases/" || $base-id || "/snapshots.xml")//snapshot
    let $snapshot := $snapshots[id eq $snapshot-id]
    let $tables := if ($base-id and $snapshot-id) then xmldb:get-child-resources("/db/apps/airlock-data/bases/" || $base-id || "/snapshots/" || $snapshot-id || "/tables") ! json-doc("/db/apps/airlock-data/bases/" || $base-id || "/snapshots/" || $snapshot-id || "/tables/" || .) else ()
    let $table := $tables[?id eq $table-id]
    let $columns := $table?columns?*
    let $records := $table?records?*
    let $column := $columns[?id eq $field-id]
    let $record := $records[?id eq $record-id]
    let $fields := $record?fields
    let $render-function := function($field-key) { bases:render-field($base-url, $base-id, $snapshot-id, $tables, $table, $record, $field-key) }
    let $base-name := $base/name/string()
    let $api-key := $base/api-key/string()
    let $custom-reports := $base//custom-report
    let $snapshot-dateTime := $snapshot/created-dateTime => format-dateTime("[MNn] [D], [Y] at [h]:[m01] [PN]")
    let $table-name := $table?name
    let $column-name := $column?name
    let $primary-column-name := $table?primaryColumnName
    let $adjusted-primary-column-name := 
        if ($primary-column-name eq "id") then
            "ID"
        else 
            $primary-column-name
    let $record-primary-field := $fields?($adjusted-primary-column-name)
    let $item :=
        if (empty($base-id)) then
            <div>
                <h2>Bases</h2>
                {
                    if ($bases) then
                        <table class="table table-bordered table-hover">
                            <thead class="thead-light">
                                <tr>
                                    <th>Name</th>
                                    <th>Base ID</th>
                                    <th>Notes</th>
                                    <th>Date Created</th>
                                    <th>Last Snapshot</th>
                                    {
                                        if (sm:id()//sm:real/sm:groups/sm:group = config:repo-permissions()?group) then 
                                            <th>Action</th>
                                        else
                                            ()
                                    }
                                </tr>
                            </thead>
                            <tbody>{
                                for $base in $bases
                                let $base-id := $base/id/string()
                                let $snapshots := doc("/db/apps/airlock-data/bases/" || $base-id || "/snapshots.xml")//snapshot
                                let $base-name := $base/name/string()
                                let $notes := $base/notes/string()
                                let $api-key := $base/api-key/string()
                                let $created-dateTime := $base/created-dateTime cast as xs:dateTime
                                let $last-snapshot := $snapshots[last()]/created-dateTime[. ne ""] ! (. cast as xs:dateTime)
                                order by $base-name
                                return
                                    <tr>
                                        <td><a href="{$base-url}/bases/{$base-id}">{$base-name}</a></td>
                                        <td>{$base-id}</td>
                                        <td>{$notes}</td>
                                        <td>{format-dateTime($created-dateTime, "[MNn] [D], [Y] [h]:[m01] [PN]")}</td>
                                        <td>{
                                            if (exists($last-snapshot)) then 
                                                format-dateTime($last-snapshot, "[MNn] [D], [Y] [h]:[m01] [PN]") 
                                            else 
                                                <em>No snapshots</em>
                                        }</td>
                                        {
                                            if (sm:id()//sm:real/sm:groups/sm:group = config:repo-permissions()?group) then 
                                                <td><a href="{$base-url}/bases/{$base-id}/edit">Edit</a></td>
                                            else
                                                ()
                                        }
                                    </tr>
                            }</tbody>
                        </table>
                   else
                       <p>No bases have been added.</p>
                ,
                if (sm:id()//sm:real/sm:groups/sm:group = config:repo-permissions()?group) then
                    if (empty(doc("/db/apps/airlock-data/keys/keys.xml")//key-set)) then
                        <div>
                            <h3>Add a base</h3>
                            <p>To add a base, first <a href="{$base-url}/keys">add your API key</a>.</p>
                        </div>
                    else
                       <div>
                           <h3>Add a base</h3>
                           <p> Use the Notes field as you wish.
   
   </p>
                           <form method="POST" action="{$base-url}/bases">
                               <div class="mb-3">
                                   <label for="base-id">Base ID:</label>
                                   <input type="text" id="base-id" name="base-id" class="form-control" required="required" autofocus="autofocus"/>
                                   <div class="form-text">To find your base's ID, go to <a href="https://airtable.com/api" target="_blank">https://airtable.com/api</a> and select your base to view its API documentation. Copy the ID from the “Introduction.”</div>
                               </div>
                               <div class="mb-3">
                                   <label for="base-name">Base name:</label>
                                   <input type="text" id="base-name" name="base-name" class="form-control" required="required"/>
                               </div>
                               <div class="mb-3">
                                   <label for="rest-api-key">REST API Key:</label>
                                   <select class="form-select" aria-label="Select an API key" id="rest-api-key" name="rest-api-key">
                                       <option selected="selected">Select an API key</option>
                                       {
                                           for $key-set at $n in doc("/db/apps/airlock-data/keys/keys.xml")//key-set
                                           return
                                               <option value="{$key-set/rest-api-key}">{$key-set/rest-api-key/string()} ({$key-set/username/string()})</option>
                                       }
                                   </select>
                               </div>
                               <div class="mb-3">
                                   <label for="permission-level">Permission level:</label>
                                   <select class="form-select" aria-label="Select your permission level" id="permission-level" name="permission-level">
                                       <option selected="selected">Select your permission level</option>
                                       {
                                           for $permission-level in ("read", "comment", "edit", "create")
                                           return
                                               <option value="{$permission-level}">{$permission-level}</option>
                                       }
                                   </select>
                               </div>
                               <div class="mb-3">
                                   <label for="notes">Notes:</label>
                                   <textarea type="text" id="notes" name="notes" class="form-control" rows="3"/>
                               </div>
                               <button class="btn btn-secondary" type="reset">Clear</button>
                               <button class="btn btn-primary" type="submit">Add Base</button>
                           </form>
                       </div>
                else 
                    ()
                }
            </div>
        else if (exists($base-id) and empty($snapshot-id)) then
            let $created-dateTime := $base/created-dateTime cast as xs:dateTime
            let $last-snapshot := $snapshots[last()]/created-dateTime[. ne ""] ! (. cast as xs:dateTime)
            return
                <div>
                    <h2>{$base-name}</h2>
                    <dl>
                        <dt>Base ID</dt>
                        <dd>{$base-id}</dd>
                    </dl>
                    <dl>
                        <dt>Status of <code>base-metadata.json</code> file</dt>
                        <dd>{
                            if (util:binary-doc-available("/db/apps/airlock-data/bases/" || $base-id || "/base-metadata.json")) then
                                "Last updated: " || xmldb:last-modified("/db/apps/airlock-data/bases/" || $base-id, "base-metadata.json") => format-dateTime("[MNn] [D], [Y] at [h]:[m01] [PN]")
                            else
                                "not yet uploaded"
                        }</dd>
                    </dl>
                    <ul>
                        {
                        if (sm:id()//sm:real/sm:groups/sm:group = config:repo-permissions()?group) then
                            (
                            if (util:binary-doc-available("/db/apps/airlock-data/bases/" || $base-id || "/base-metadata.json")) then
                                <li><a href="{$base-url}/bases/{$base-id}/snapshot">Take a new snapshot</a> (Note: This may take several minutes, depending on the size of the base.)</li>
                            else
                                (),
                            <li>Upload a new <code>base-metadata.json</code> file 
                                <ol>
                                    <li>Go to <a href="https://airtable.com/{$base-id}/api/docs">this base’s API documentation</a>.</li>
                                    <li>Use the <a href="https://chrome.google.com/webstore/detail/airtable-schema-extractor/cgcjgclmbhcibagnfhjlkigjjokeffia">Airtable Schema Extractor</a> (requires Google Chrome) to copy the complete JSON file and save it as a <code>.json</code> file on your computer.</li>
                                    <li>
                                        <form method="POST" action="{$base-url}/bases/{$base-id}/base-metadata" enctype="multipart/form-data">
                                            <label for="upload-base-metadata">Upload the file:</label>
                                            <br/> 
                                            <input type="file" id="upload-base-metadata" name="files[]" accept="application/json"/> 
                                            <button class="button btn-secondary">Submit</button>
                                        </form>
                                    </li>
                                </ol>
                            </li>
                            )
                        else
                            () 
                        }
                        {
                            for $report in $custom-reports
                            return
                                <li><a href="{$report/location}">{$report/label/string()}</a>: {$report/description/string()}</li>
                        }
                    </ul>
                    {
                        if (exists($snapshots)) then
                            <table class="table table-bordered table-hover">
                                <thead class="thead-light">
                                    <tr>
                                        <th>Snapshot</th>
                                        <th>Date Created</th>
                                        <th>Tables</th>
                                        <th>Records</th>
                                        <th>Fields</th>
                                        <th>Cells</th>
                                        {
                                            if (sm:id()//sm:real/sm:groups/sm:group = config:repo-permissions()?group) then 
                                                <th>Action</th>
                                            else
                                                ()
                                        }
                                    </tr>
                                </thead>
                                <tbody>{
                                    for $snapshot in $snapshots
                                    let $snapshot-id := $snapshot/id/string()
                                    let $created-dateTime := $snapshot/created-dateTime cast as xs:dateTime
                                    order by $created-dateTime
                                    return
                                        <tr>
                                            <td><a href="{$base-url}/bases/{$base-id}/snapshots/{$snapshot-id}">{$snapshot-id}</a></td>
                                            <td>{format-dateTime($created-dateTime, "[MNn] [D], [Y] [h]:[m01] [PN]")}</td>
                                            <td>{$snapshot/tables-count/string()}</td>
                                            <td>{$snapshot/records-count/string()}</td>
                                            <td>{$snapshot/fields-count/string()}</td>
                                            <td>{$snapshot/cells-count/string()}</td>
                                            {
                                                if (sm:id()//sm:real/sm:groups/sm:group = config:repo-permissions()?group) then 
                                                    <td><a href="{$base-url || "/bases/" || $base-id || "/snapshots/" || $snapshot-id || "/delete"}">Delete</a></td>
                                                else
                                                    ()
                                            }
                                        </tr>
                                }</tbody>
                            </table>
                        else if (sm:id()//sm:real/sm:groups/sm:group = config:repo-permissions()?group) then
                            ()
                        else
                            <p>No snapshots. Please <a href="{$base-url}">log in</a> to take a new snapshot.</p>
                    }
                </div>
        else if (exists($base-id) and exists($snapshot-id) and empty($table-id)) then
            element div {
                element h2 { "Tables" },
                element ul {
                    for $table in $tables
                    let $table-id := $table?id
                    let $table-name := $table?name
                    order by $table-name
                    return
                        element li {
                            element a {
                                attribute href { $base-url || "/bases/" || $base-id || "/snapshots/" || $snapshot-id  || "/" || $table-id },
                                $table-name
                            }
                        }
                }
        }
        else if (exists($base-id) and exists($snapshot-id) and exists($table-id) and (empty($record-id) and empty($field-id))) then
            element div {
                element h2 { "Fields" },
                element ul {
                    for $column in $columns
                    let $column-id := $column?id
                    let $column-name := $column?name
                    return
                        element li {
                            element a {
                                attribute href { $base-url || "/bases/" || $base-id || "/snapshots/" || $snapshot-id  || "/" || $table-id || "/fields/" || $column?id },
                                $column-name
                            }
                        }
                },
                element h2 { "Records" },
                element ul {
                    let $primary-column-name := $table?primaryColumnName
                    let $adjusted-primary-column-name := 
                        (:
                        if ($primary-column-name eq "id") then
                            "ID"
                        else 
                        :)
                            $primary-column-name
        (:            return element pre { serialize($table, map{"indent": true()}) }:)
                    let $records := $table?records
                    for $record in $records?*
                    let $record-id := $record?id
                    let $fields := $record?fields
                    let $record-name := $fields?($adjusted-primary-column-name)
                    order by $record-name collation "http://www.w3.org/2013/collation/UCA?numeric=yes"
                    return
                        element li {
                            element a {
                                attribute href { $base-url || "/bases/" || $base-id || "/snapshots/" || $snapshot-id  || "/" || $table-id || "/records/" || $record-id },
                                $record-name
                            }
                        }
                }
            }
        else if (exists($base-id) and exists($snapshot-id) and exists($table-id) and exists($field-id)) then
            element dl {
                element dt { "id" },
                element dd { $field-id },
                element dt { "name" },
                element dd { $column?name },
                element dt { "type" },
                element dd { $column?type },
                if (map:contains($column, "typeOptions")) then
                    (
                        element dt { "typeOptions" },
                        element dd {
                            let $entries := $column?typeOptions
                            let $choices := $entries?choices?*
                            let $choice-order := $entries?choiceOrder
                            let $foreign-table-id := $entries?foreignTableId
                            let $foreign-table := $tables[?id eq $foreign-table-id]
                            let $symmetric-column-id := $entries?symmetricColumnId
                            let $symmetric-column := $foreign-table?columns?*[?id eq $symmetric-column-id]
                            let $relation-column-id := $entries?relationColumnId
                            let $relation-column := $table?columns?*[?id eq $relation-column-id]
    (:                                "foreignTableRollupColumnId":)
                            return
                                if (exists($choices) and exists($choice-order)) then
                                    element dl {
                                        element dt { "choices" },
                                        element dd {
                                            let $ordered-choices := sort($choices, (), function($choice) { index-of($choice-order, $choice?id) })
                                            return
                                                element ol { 
                                                    for $choice in $ordered-choices
                                                    let $color := $choice?color
                                                    return
                                                        element li {
                                                            element span {
                                                                attribute class { "badge rounded-pill " || $bases:color-to-css-class?($color) },
                                                                $choice?name
                                                            } 
                                                        }
                                                }
                                        }
                                    }
                                else
                                    for $key in ($entries ! map:keys(.)[not(. = ("choices", "choice-order"))]) (: except ($choices, $choice-order) :)
                                    let $entry := $entries($key)
                                    return
                                        element dl {
                                            element dt { $key },
                                            element dd { 
                                                switch ($key)
                                                    case "foreignTableId" return
                                                        element a {
                                                            attribute href {
                                                                $base-url || "/bases/" || $base-id || "/snapshots/" || $snapshot-id  || "/" || $foreign-table-id
                                                            },
                                                            $foreign-table?name
                                                        }
                                                    case "symmetricColumnId" return
                                                        element a {
                                                            attribute href {
                                                                $base-url || "/bases/" || $base-id || "/snapshots/" || $snapshot-id  || "/" || $foreign-table-id || "/fields/" || $symmetric-column-id
                                                            },
                                                            $symmetric-column?name
                                                        }
                                                    case "relationColumnId" return
                                                        element a {
                                                            attribute href {
                                                                $base-url || "/bases/" || $base-id || "/snapshots/" || $snapshot-id  || "/" || $table-id || "/fields/" || $relation-column-id
                                                            },
                                                            $relation-column?name
                                                        }
                                                    case "dependencies" return
                                                        element ol {
                                                            for $referenced-column-id in $entry/?referencedColumnIdsForValue?*
                                                            let $referenced-column := $table?columns?*[?id eq $referenced-column-id]
                                                            return
                                                                element li { 
                                                                    element a {
                                                                        attribute href {
                                                                            $base-url || "/bases/" || $base-id || "/snapshots/" || $snapshot-id  || "/" || $table-id || "/fields/" || $referenced-column-id
                                                                        },
                                                                        $referenced-column?name
                                                        }
                                                                }
                                                        }
                                                    (: TODO parse field references :)
                                                    case "formulaTextParsed" return
                                                        element code { $entry } 
                                                    default return
                                                        $entry
                                            }
                                        }
                        }
                    )
                else
                    ()
            }
        else if (exists($base-id) and exists($snapshot-id) and exists($table-id) and exists($record-id)) then
            element dl {
                element dt { "id" },
                element dd { $record-id },
                for $field-key in ($adjusted-primary-column-name, map:keys($fields)[. ne $adjusted-primary-column-name])
                let $column-id := $columns[?name eq $field-key]?id
                return
                    (
                        element dt { 
                            element a {
                                attribute href { $base-url || "/bases/" || $base-id || "/snapshots/" || $snapshot-id  || "/" || $table-id || "/fields/" || $column-id },
                                $field-key
                            }
                        },
                        element dd { $render-function($field-key) }
                    )
            }
        else
            ()
    let $breadcrumb-entries :=
        (
            <a href="{$base-url}">Home</a>,
            <a href="{$base-url}/bases">Bases</a>,
            if ($base-id) then 
                <a href="{$base-url}/bases/{$base-id}">{$base-name}</a>
            else 
                (),
            if ($snapshot-id) then 
                <a href="{$base-url}/bases/{$base-id}/snapshots/{$snapshot-id}">Snapshot {$snapshot-id}</a>
            else 
                (),
            if ($table-id) then 
                <a href="{$base-url}/bases/{$base-id}/snapshots/{$snapshot-id}/{$table-id}">“{$table-name}” Table</a>
            else 
                (),
            if ($field-id) then 
                <a href="{$base-url}/bases/{$base-id}/snapshots/{$snapshot-id}/{$table-id}/fields/{$field-id}">“{$column-name}” Field</a>
            else 
                (),
            if ($record-id) then 
                <a href="{$base-url}/bases/{$base-id}/snapshots/{$snapshot-id}/{$table-id}/records/{$record-id}">“{$record-primary-field}” Record</a>
            else 
                ()
        )
    let $breadcrumbs-count := count($breadcrumb-entries)
    let $breadcrumbs := 
        <nav aria-label="breadcrumb">
            <ol class="breadcrumb">
                {
                    for $entry at $n in $breadcrumb-entries
                    return
                        if ($n eq $breadcrumbs-count) then
                            <li class="breadcrumb-item active" aria-current="page">{$entry/string()}</li>
                        else
                            <li class="breadcrumb-item">{$entry}</li>
                }
            </ol>
        </nav>
    let $title := "Airlock"
    let $content :=
        element div { 
            element h1 { $title },
            $breadcrumbs,
            $item
        }
    return
        app:wrap($content, $title)
};

declare function bases:delete-base-confirm($request as map(*)) {
    let $base-url := $request?parameters?base-url
    let $base-id := $request?parameters?base-id
    let $base := doc("/db/apps/airlock-data/bases/bases.xml")//base[id eq $base-id]
    let $title := "Delete this base?"
    let $content := 
        <div class="alert alert-danger" role="alert">
            <h4 class="alert-heading">{$title}</h4>
            <form method="POST" action="{$base-url}/bases/{$base-id}/delete">
                <button class="button btn-danger" type="submit">Delete {$base/name/string()}</button>
            </form>
            <a class="button btn-default" href="{$base-url}/bases">Cancel</a>
        </div>
    return
        app:wrap($content, $title)
};

declare function bases:delete-base($request as map(*)) {
    let $base-url := $request?parameters?base-url
    let $base-id := $request?parameters?base-id
    let $delete := 
        (
            update delete doc("/db/apps/airlock-data/bases/bases.xml")//base[id eq $base-id],
            if (xmldb:collection-available("/db/apps/airlock-data/bases/" || $base-id)) then
                xmldb:remove("/db/apps/airlock-data/bases/" || $base-id)
            else
                ()
        )
    let $title := "Success"
    let $content :=
        <div class="alert alert-success" role="alert">
            <h4 class="alert-heading">{$title}</h4>
            <p>Successfully deleted base {$base-id}</p>
            <p><a href="{$base-url}/bases">Return to bases</a></p>
        </div>
    return
        app:wrap($content, $title)
};

declare function bases:edit-base($request as map(*)) {
    let $base-url := $request?parameters?base-url
    let $base-id := $request?parameters?base-id
    let $base := doc("/db/apps/airlock-data/bases/bases.xml")//base[id eq $base-id]
    let $new-base-id := $request?parameters?new-base-id
    let $base-name := $request?parameters?base-name
    let $api-key := $request?parameters?rest-api-key
    let $permission-level := $request?parameters?permission-level
    let $notes := $request?parameters?notes
    let $new-base := bases:base-element($new-base-id, $base-name, $api-key, $permission-level, $notes, $base/custom-reports/custom-report, $base/created-dateTime cast as xs:dateTime, current-dateTime())
    let $update :=
        (
            update replace $base with $new-base,
            if ($new-base-id ne $base-id) then
                xmldb:rename("/db/apps/airlock-data/bases/" || $base-id, $new-base-id)
            else
                ()
        )
    let $title := "Success"
    let $content :=
        <div class="alert alert-success" role="alert">
            <h4 class="alert-heading">{$title}</h4>
            <p>Successfully updated base {$new-base-id}</p>
            <p><a href="{$base-url}/bases/{$new-base-id}">View base</a></p>
        </div>
    return
        app:wrap($content, $title)
};

declare function bases:edit-base-form($request as map(*)) {
    let $base-url := $request?parameters?base-url
    let $base-id := $request?parameters?base-id
    let $base := doc("/db/apps/airlock-data/bases/bases.xml")//base[id eq $base-id]
    let $base-name := $base/name
    let $base-api-key := $base/api-key
    let $base-permission-level := $base/permission-level
    let $base-notes := $base/notes
    let $custom-reports := $base/custom-reports/custom-report
    let $title := "Edit base"
    let $content :=
        <div>
            <h1>Airlock</h1>
            <nav aria-label="breadcrumb">
                <ol class="breadcrumb">
                    <li class="breadcrumb-item"><a href="{$base-url}">Home</a></li>
                    <li class="breadcrumb-item"><a href="{$base-url}/bases">Bases</a></li>
                    <li class="breadcrumb-item"><a href="{$base-url}/bases/{$base-id}">Base {$base-id}</a></li>
                    <li class="breadcrumb-item active" aria-current="page">{$title}</li>
                </ol>
            </nav>
            <h2>{$title}</h2>
            <form method="POST" action="{$base-url}/bases/{$base-id}/edit">
                <div class="form-group">
                    <label for="base-id">Base ID:</label>
                    <div>
                        <input type="text" id="new-base-id" name="new-base-id" class="form-control" required="required" value="{$base-id}"/>
                    </div>
                </div>
                <div class="form-group">
                    <label for="base-name">Base name:</label>
                    <div>
                        <input type="text" id="base-name" name="base-name" class="form-control" required="required" value="{$base-name}"/>
                    </div>
                </div>
                <div class="form-group">
                    <label for="rest-api-key">REST API Key:</label>
                    <div>
                        <select class="form-select" aria-label="Select an API key" id="rest-api-key" name="rest-api-key">
                            <option>Select an API key</option>
                            {
                                for $key-set at $n in doc("/db/apps/airlock-data/keys/keys.xml")//key-set
                                return
                                    <option value="{$key-set/rest-api-key}">{
                                        if ($key-set/rest-api-key eq $base-api-key) then
                                            attribute selected { "selected" }
                                        else
                                            (),
                                        $key-set/rest-api-key/string()
                                    } ({$key-set/username/string()})</option>
                            }
                        </select>
                    </div>
                </div>
                <div class="form-group">
                    <label for="permission-level">Permission level:</label>
                    <div>
                        <select class="form-select" aria-label="Select your permission level" id="permission-level" name="permission-level">
                            <option>Select your permission level</option>
                            {
                                for $permission-level in ("read", "create")
                                return
                                    <option value="{$permission-level}">{
                                        if ($permission-level eq $base-permission-level) then
                                            attribute selected { "selected" }
                                        else
                                            (),
                                        $permission-level
                                    }</option>
                            }
                        </select>
                    </div>
                </div>
                <div class="form-group">
                    <label for="notes">Notes:</label>
                    <div>
                        <textarea type="text" id="notes" name="notes" class="form-control" rows="3">{$base-notes/string()}</textarea>
                    </div>
                </div>
                <button class="btn btn-secondary" type="reset">Clear</button>
                <button class="btn btn-primary" type="submit">Update Base</button>
                <br/>
                <a href="{$base-url}/bases/{$base-id}/delete" class="btn btn-danger" type="submit">Delete</a>
            </form>
            <h3>Custom Reports</h3>
            {
                if ($custom-reports) then
                    <table class="table table-bordered">
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Label</th>
                                <th>Description</th>
                                <th>Location</th>
                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            {
                                for $report in $custom-reports
                                return
                                    <tr>
                                        <td>{$report/id/string()}</td>
                                        <td>{$report/label/string()}</td>
                                        <td>{$report/description/normalize-space()}</td>
                                        <td><a href="{$report/location}">{$report/location/string()}</a></td>
                                        <td>Edit</td>
                                    </tr>
                            }
                        </tbody>
                    </table>
                else
                    <p>No custom reports. <a href="{$base-url}/bases/{$base-id}/edit/custom-reports">Add a custom report</a>.</p>
            }
        </div>
    return
        app:wrap($content, $title)
};

declare function bases:custom-report-element($report-id as xs:string, $report-label as xs:string, $report-description as xs:string, $report-location as xs:string) as element(custom-report) {
    element custom-report {
        element id { $report-id },
        element label { $report-label },
        element description { $report-description },
        element location { $report-location }
    }
};

declare function bases:create-custom-report-form($request as map(*)) {
    let $base-url := $request?parameters?base-url
    let $base-id := $request?parameters?base-id
    let $base := doc("/db/apps/airlock-data/bases/bases.xml")//base[id eq $base-id]
    let $custom-reports := $base/custom-reports
    let $max-id := max(($custom-reports/custom-report/id ! (. cast as xs:integer), 0))
    let $next-id := $max-id + 1
    let $title := "Create custom report"
    let $content :=
        <div>
            <h1>Airlock</h1>
            <nav aria-label="breadcrumb">
                <ol class="breadcrumb">
                    <li class="breadcrumb-item"><a href="{$base-url}">Home</a></li>
                    <li class="breadcrumb-item"><a href="{$base-url}/bases">Bases</a></li>
                    <li class="breadcrumb-item"><a href="{$base-url}/bases/{$base-id}">Base {$base-id}</a></li>
                    <li class="breadcrumb-item active" aria-current="page">Add custom report</li>
                </ol>
            </nav>
            <h2>{$title}</h2>
            <form method="POST" action="{$base-url}/bases/{$base-id}/edit/custom-reports">
                <div class="form-group">
                    <label for="report-label">Label:</label>
                    <div>
                        <input type="text" id="report-label" name="report-label" class="form-control" required="required" autofocus="autofocus"/>
                    </div>
                </div>
                <div class="form-group">
                    <label for="report-description">Description:</label>
                    <div>
                        <input type="text" id="report-description" name="report-description" class="form-control" required="required"/>
                    </div>
                </div>
                <div class="form-group">
                    <label for="report-location">Location:</label>
                    <div>
                        <input type="text" id="report-location" name="report-location" class="form-control"/>
                    </div>
                </div>
                <button class="btn btn-secondary" type="reset">Clear</button>
                <button class="btn btn-primary" type="submit">Submit</button>
            </form>
        </div>
    return
        app:wrap($content, $title)
};

declare function bases:create-custom-report($request as map(*)) {
    let $base-url := $request?parameters?base-url
    let $base-id := $request?parameters?base-id
    let $base := doc("/db/apps/airlock-data/bases/bases.xml")//base[id eq $base-id]
    let $custom-reports := $base/custom-reports
    let $max-id := max(($custom-reports/custom-report/id ! (. cast as xs:integer), 0))
    let $next-id := $max-id + 1
    let $report-label := $request?parameters?report-label
    let $report-description := $request?parameters?report-description
    let $report-location := $request?parameters?report-location
    let $new-custom-report := bases:custom-report-element($next-id, $report-label, $report-description, $report-location)
    let $add := update insert $new-custom-report into $custom-reports
    let $title := "Success"
    let $content :=
        <div class="alert alert-success" role="alert">
            <h4 class="alert-heading">{$title}</h4>
            <p>Successfully added custom report {$next-id}</p>
            <p><a href="{$base-url}/bases/{$base-id}">Choose a snapshot to view the report</a></p>
        </div>
    return
        app:wrap($content, $title)
};

declare function bases:base-element($base-id as xs:string, $base-name as xs:string, $api-key as xs:string, $permission-level as xs:string, $notes as xs:string, $custom-reports as element(custom-report)*, $created-dateTime as xs:dateTime, $last-modified-dateTime as xs:dateTime?) {
    element base {
        element id { $base-id },
        element name { $base-name },
        element api-key { $api-key },
        element permission-level { $permission-level },
        element notes { $notes },
        element custom-reports { $custom-reports },
        element created-dateTime { $created-dateTime },
        element last-modified-dateTime { $last-modified-dateTime }
    }
};

declare function bases:create-base($request as map(*)) {
    let $base-url := $request?parameters?base-url
    let $base-id := $request?parameters?base-id
    let $base-name := $request?parameters?base-name
    let $rest-api-key := $request?parameters?rest-api-key
    let $permission-level := $request?parameters?permission-level
    let $notes := $request?parameters?notes
    let $new-base := bases:base-element($base-id, $base-name, $rest-api-key, $permission-level, $notes, (), current-dateTime(), ())
    let $add := 
        (
            update insert $new-base into doc("/db/apps/airlock-data/bases/bases.xml")/bases,
            bases:mkcol("/db/apps/airlock-data/bases", $base-id || "/snapshots"),
            bases:store("/db/apps/airlock-data/bases/" || $base-id, "snapshots.xml", <snapshots/>)
        )
    let $title := "Success"
    let $content :=
        <div class="alert alert-success" role="alert">
            <h4 class="alert-heading">{$title}</h4>
            <p>Successfully created base {$base-id}</p>
            <p><a href="{$base-url}/bases/{$base-id}">View base</a></p>
        </div>
    return
        app:wrap($content, $title)
};

declare function bases:update-base-metadata($request as map(*)) {
    let $base-url := $request?parameters?base-url
    let $base-id := $request?parameters?base-id
    let $file := request:get-uploaded-file-data("files[]")
    let $base-col := 
        if (xmldb:collection-available("/db/apps/airlock-data/bases/" || $base-id)) then
            "/db/apps/airlock-data/bases/" || $base-id
        else
            bases:mkcol("/db/apps/airlock-data/bases", $base-id)
    let $store := bases:store("/db/apps/airlock-data/bases/" || $base-id, "base-metadata.json", $file)
    let $title := "Success"
    let $content :=
        <div class="alert alert-success" role="alert">
            <h4 class="alert-heading">{$title}</h4>
            <p>Successfully stored {$store}</p>
            <p><a href="{$base-url}/bases/{$base-id}">Return to browsing base</a></p>
        </div>
    return
        app:wrap($content, $title)
};

(:~
 : Recursively create a collection hierarchy
 :)
declare %private function bases:mkcol($collection as xs:string, $path as xs:string) {
    bases:mkcol-recursive($collection, tokenize($path, "/"))
};

declare 
    %private
function bases:mkcol-recursive($collection as xs:string, $components as xs:string*) {
    if (exists($components)) then
        let $newColl := concat($collection, "/", $components[1])
        return (
            xmldb:create-collection($collection, $components[1]) ! 
                (
                    sm:chgrp(xs:anyURI(.), config:repo-permissions()?group),
                    sm:chmod(xs:anyURI(.), config:repo-permissions()?mode),
                    .
                ),
            bases:mkcol-recursive($newColl, subsequence($components, 2))
        )
    else
        ()
};


(:~
 : Helper function to store resources and set permissions for access by repo group
 :)
declare function bases:store($collection-uri as xs:string, $resource-name as xs:string, $contents as item()?) as xs:string {
    xmldb:store($collection-uri, $resource-name, $contents) !
        (
            sm:chgrp(., config:repo-permissions()?group),
            sm:chmod(., config:repo-permissions()?mode),
            .
        )
};

declare function bases:get-table-for-snapshot($api-key as xs:string, $base-id as xs:string, $base-metadata as map(*)) {
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
declare function bases:fix-columns-entry($table as map(*)*) {
    map:merge((
        for $key in map:keys($table)
        return
            if ($key eq "columns" and map:get($table, $key) instance of map(*)) then
                map:entry("columns", array { $table?columns } )
            else
                map:entry($key, $table($key))
    ))
};

declare function bases:create-snapshot($request as map(*)) {
    let $base-url := $request?parameters?base-url
    let $base-id := $request?parameters?base-id
    let $base := doc("/db/apps/airlock-data/bases/bases.xml")//base[id eq $base-id]
    let $base-name := $base/name/string()
    let $api-key := $base/api-key/string()
    let $snapshots-doc := doc("/db/apps/airlock-data/bases/" || $base-id || "/snapshots.xml")/snapshots
    let $next-id := ($snapshots-doc/snapshot[last()]/id, "0")[1] cast as xs:integer + 1
    let $snapshot := element snapshot { element id { $next-id }, element created-dateTime { current-dateTime() } }
    let $prepare :=
        (
            bases:mkcol("/db/apps/airlock-data/bases/", $base-id || "/snapshots/" || $next-id || "/tables"),
            xmldb:copy-resource(
                "/db/apps/airlock-data/bases/" || $base-id,
                "base-metadata.json",
                "/db/apps/airlock-data/bases/" || $base-id || "/snapshots/" || $next-id,
                "base-metadata.json",
                true()
            ),
            if (exists($snapshots-doc)) then
                update insert $snapshot into $snapshots-doc
            else
                bases:store("/db/apps/airlock-data/bases/" || $base-id, "snapshots.xml", element snapshots { $snapshot } )
        )
    
    (: https://github.com/Airtable/airtable.js/issues/12#issuecomment-349987627
     :
     : for exporting table metadata, start from https://airtable.com/appe0AfkruafOCgrw/api/docs :)
    let $tables := json-doc("/db/apps/airlock-data/bases/" || $base-id || "/snapshots/" || $next-id || "/base-metadata.json")?*
    let $store :=
        for $base-metadata in $tables
        let $contents := bases:get-table-for-snapshot($api-key, $base-id, $base-metadata)
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
            bases:store(
                "/db/apps/airlock-data/bases/" || $base-id || "/snapshots/" || $next-id || "/tables",
                ($base-metadata?name || ".json")
                    (: space, nbsp, plus, colon, slash, bullet point :)
                    => replace("[ &#160;+:/&#x2022;]", "-")
                    (: parentheses :)
                    => replace("[\(\)]", "")
                    => replace("-+", "-")
                    => replace("^-", "_")
                    => lower-case(),
                $contents => serialize(map{ "method": "json", "indent": true() })
            )
    let $summarize := 
        let $resources := xmldb:get-child-resources("/db/apps/airlock-data/bases/" || $base-id || "/snapshots/" || $next-id || "/tables")
        let $tables := $resources ! json-doc("/db/apps/airlock-data/bases/" || $base-id || "/snapshots/" || $next-id || "/tables/" || .)
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
            into $snapshots-doc//snapshot[id eq $next-id cast as xs:string]
    let $content :=
        element div {
            attribute class { "alert alert-success" },
            attribute role { "alert" },
            element h4 { attribute class { "alert-heading" }, "Success" },
            element p { "Stored " || count($store) || " resources:" },
            element ul { $store ! element li { . } },
            element p {
                element a {
                    attribute href { $base-url || "/bases/" || $base-id || "/snapshots/" || $next-id },
                    "View snapshot " || $next-id
                }
            }
        }
    return
        app:wrap($content, "Created snapshot " || $next-id)
};

declare function bases:delete-snapshot($request as map(*)) {
    let $base-url := $request?parameters?base-url
    let $base-id := $request?parameters?base-id
    let $snapshot-id := $request?parameters?snapshot-id
    let $snapshot := doc("/db/apps/airlock-data/bases/" || $base-id || "/snapshots.xml")/snapshots/snapshot[id eq $snapshot-id]
    let $delete := 
        (
            update delete $snapshot,
            xmldb:remove("/db/apps/airlock-data/bases/" || $base-id || "/snapshots/" || $snapshot-id)
        )
    let $content :=
        element div {
            attribute class { "alert alert-success" },
            attribute role { "alert" },
            element h4 { attribute class { "alert-heading" }, "Success" },
            element p { "Deleted snapshot " || $snapshot-id },
            element p {
                element a {
                    attribute href { $base-url || "/bases/" || $base-id },
                    "Return to base"
                }
            }
        }
    return
        app:wrap($content, "Success")
};

declare function bases:welcome($request as map(*)) {
    let $title := "Airlock"
    let $base-url := $request?parameters?base-url
    let $content := 
        <div>
            <h1>{$title}</h1>
            <nav aria-label="breadcrumb">
                <ol class="breadcrumb">
                    <li class="breadcrumb-item active" aria-current="page">Home</li>
                </ol>
            </nav>
            <p>Welcome to Airlock. Guest users can browse existing bases. To add an API key, add bases, and take snapshots, <a href="{$base-url}/login">log in</a> as a user who is a member of the <code>{config:repo-permissions()?group}</code> group.</p>
            <ul>
                {
                    if (sm:id()//sm:real/sm:groups/sm:group = config:repo-permissions()?group) then 
                        <li><a href="{$base-url}/keys">API Keys</a></li>
                    else
                        ()
                }
                <li><a href="{$base-url}/bases">Bases</a></li>
                {
                    if (sm:id()//sm:real/sm:groups/sm:group = config:repo-permissions()?group) then 
                        <li><a href="{$base-url}/login?logout=true">Log out</a>. You are logged in as {sm:id()//sm:real/sm:username/string()}.</li>
                    else
                        <li><a href="{$base-url}/login?logout=true">Log in</a></li>
                }
            </ul>
        </div>
    return
        app:wrap($content, $title)
};

