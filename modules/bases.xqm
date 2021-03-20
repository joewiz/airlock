xquery version "3.1";

module namespace bases="http://joewiz.org/ns/xquery/airlock/bases";

import module namespace app="http://joewiz.org/ns/xquery/airlock/app" at "app.xqm";
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

declare function bases:render-field($base-id, $snapshot-id, $tables, $table, $record, $field-key) {
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
                                        attribute href { 
                                            "?" 
                                            || string-join((
                                                "base-id=" || $base-id,
                                                "snapshot-id=" || $snapshot-id,
                                                "table-id=" || $foreign-table-id,
                                                "record-id=" || $foreign-record-id
                                            ), "&amp;")
                                        },
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
                                attribute href { 
                                    "?" 
                                    || string-join((
                                        "base-id=" || $base-id,
                                        "snapshot-id=" || $snapshot-id,
                                        "table-id=" || $foreign-table-id,
                                        "record-id=" || $foreign-record-id
                                    ), "&amp;")
                                },
                                $foreign-record-label
                            }
            case "multiSelect" return
                let $values := $field
                let $choices := $type-options?choices
                return
                    if (count($values) gt 1) then
                        element ol {
                            let $ordered-values := sort($values, (), function($value) { index-of($type-options?choiceOrder?*, $value) })
                            for $value in $ordered-values
                            let $color := $choices[?name eq $value?color]
                            return
                                element li {
                                    element span {
                                        attribute class { "badge badge-pill " || $bases:color-to-css-class?($color) },
                                        $value
                                    }
                                }
                        }
                    else
                        let $value := $values
                        let $color := $choices[?name eq $value]?color
                        return
                            element span {
                                attribute class { "badge badge-pill " || $bases:color-to-css-class?($color) },
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
    let $render-function := function($field-key) { bases:render-field($base-id, $snapshot-id, $tables, $table, $record, $field-key) }
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
            <table class="table table-bordered table-hover">
                <thead class="thead-light">
                    <tr>
                        <th>Name</th>
                        <th>Base ID</th>
                        <th>API Key</th>
                        <th>Date Created</th>
                        <th>Last Snapshot</th>
                    </tr>
                </thead>
                <tbody>{
                    for $base in $bases
                    let $base-id := $base/id/string()
                    let $snapshots := doc("/db/apps/airlock-data/bases/" || $base-id || "/snapshots.xml")//snapshot
                    let $base-name := $base/name/string()
                    let $api-key := $base/api-key/string()
                    let $created-dateTime := $base/created-dateTime cast as xs:dateTime
                    let $last-snapshot := $snapshots[last()]/created-dateTime[. ne ""] ! (. cast as xs:dateTime)
                    order by $base-name
                    return
                        <tr>
                            <td><a href="{$base-url}/bases/{$base-id}">{$base-name}</a></td>
                            <td>{$base-id}</td>
                            <td>{$api-key}</td>
                            <td>{format-dateTime($created-dateTime, "[MNn] [D], [Y] [h]:[m01] [PN]")}</td>
                            <td>{if (exists($last-snapshot)) then format-dateTime($last-snapshot, "[MNn] [D], [Y] [h]:[m01] [PN]") else <em>No snapshots</em>}</td>
                        </tr>
                }</tbody>
            </table>
        else if (exists($base-id) and empty($snapshot-id)) then
            let $created-dateTime := $base/created-dateTime cast as xs:dateTime
            let $last-snapshot := $snapshots[last()]/created-dateTime[. ne ""] ! (. cast as xs:dateTime)
            return
                <div>
                    <dl>
                        <dt>Base ID</dt>
                        <dd>{$base-id}</dd>
                        <dt>API Key</dt>
                        <dd>{$api-key}</dd>
                    </dl>
                    <ul>
                        <!--<li><a href="../documentation.xq?base-id={$base-id}">View documentation</a></li>-->
                        <li><a href="{$base-url}/{$base-id}/snapshot">Take a new snapshot</a> (Note: This may take several minutes, depending on the size of the base.)</li>
                        <li>To avoid errors or omitted data, open the <a href="/exist/apps/eXide/index.html?open=/db/apps/airlock-data/bases/{$base-id}/base-metadata.json"><code>base-metadata.json</code> file in eXide</a> and make sure it is present and up-to-date, since snapshots require a complete list of every table's name; to obtain a current copy, go to <a href="https://airtable.com/{$base-id}/api/docs">this base’s API documentation</a> and use the <a href="https://chrome.google.com/webstore/detail/airtable-schema-extractor/cgcjgclmbhcibagnfhjlkigjjokeffia">Airtable Schema Extractor</a> Chrome extension to copy the complete JSON file, save it as <code>base-metadata.json</code> and upload it to the <code>/db/apps/airlock-data/bases/{$base-id}</code> collection in eXist using eXide or a WebDAV client like oXygen or Transmit. <form method="POST" action="{$base-url}/{$base-id}/base-metadata" enctype="multipart/form-data"><label for="upload-base-metadata">Upload a new <code>base-metadata.json</code> file:</label> <input type="file" id="upload-base-metadata" name="files[]" accept="application/json"/> <button>Submit</button></form></li>
                        {
                            for $report in $custom-reports
                            return
                                <li><a href="{$report/location}">{$report/label/string()}</a>: {$report/description/string()}</li>
                        }
                        <!--<li><a href="base-update.xq?base-id={$base-id}">Update base info</a></li>-->
                    </ul>
                    <table class="table table-bordered table-hover">
                        <thead class="thead-light">
                            <tr>
                                <th>Snapshot</th>
                                <th>Date Created</th>
                                <th>Tables</th>
                                <th>Records</th>
                                <th>Fields</th>
                                <th>Cells</th>
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
                                </tr>
                        }</tbody>
                    </table>
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
                                                                attribute class { "badge badge-pill " || $bases:color-to-css-class?($color) },
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
                                attribute href { $base-url || "/bases/" || $base-id || "/snapshots/" || $snapshot-id  || "/" || $table-id || "/fields/" || $column-id},
                                $field-key
                            }
                        },
                        element dd { $render-function($field-key) }
                    )
            }
        else
            ()
    let $breadcrumbs := 
        (
            <a href="{$base-url}">Airlock</a>,
            text { " > " },
            <a href="{$base-url}/bases">Bases</a>,
            if ($base-id) then 
                (
                    text { " > " },
                    <a href="{$base-url}/bases/{$base-id}">{$base-name}</a>
                )
            else 
                (),
            if ($snapshot-id) then 
                (
                    text { " > " },
                    <a href="{$base-url}/bases/{$base-id}/snapshots/{$snapshot-id}">Snapshot {$snapshot-id}</a>
                )
            else 
                (),
            if ($table-id) then 
                (
                    text { " > " },
                    <a href="{$base-url}/bases/{$base-id}/snapshots/{$snapshot-id}/{$table-id}">“{$table-name}” Table</a>
                )
            else 
                (),
            if ($field-id) then 
                (
                    text { " > " },
                    <a href="{$base-url}/bases/{$base-id}/snapshots/{$snapshot-id}/{$table-id}/fields/{$field-id}">“{$column-name}” Field</a>
                )
            else 
                (),
            if ($record-id) then 
                (
                    text { " > " },
                    <a href="{$base-url}/bases/{$base-id}/snapshots/{$snapshot-id}/{$table-id}/records/{$record-id}">“{$record-primary-field}” Record</a>
                )
            else 
                ()
        )
    let $title := $breadcrumbs/normalize-space()
    let $content :=
        element div { 
            element h1 { 
                $breadcrumbs
            },
            $item
        }
    return
        app:wrap($content, $title)
};

declare function bases:welcome($request as map(*)) {
    let $title := "Airlock"
    let $base-url := $request?parameters?base-url
    let $content := 
        <div>
            <h1>{$title}</h1>
            <ul>
                <li><a href="{$base-url}/create-base">Create base</a></li>
                <li><a href="{$base-url}/bases">View bases</a></li>
            </ul>
            <form method="POST" class="form form-horizontal" action="{$base-url}/login">
                <div class="form-group">
                    <label class="control-label col-md-1" for="user">User:</label>
                    <div class="col-md-3">
                        <input type="text" name="user" required="required" autofocus="autofocus"/>
                    </div>
                </div>
                <div class="form-group">
                    <label class="control-label col-md-1" for="password">Password:</label>
                    <div class="col-md-3">
                        <input type="password" name="password"/>
                    </div>
                </div>
                <div class="form-group">
                    <div class="col-md-offset-1 col-sm-12">
                        <button class="btn btn-primary" type="submit">Login</button>
                    </div>
                </div>
            </form>
        </div>
    return
        app:wrap($content, $title)
};
