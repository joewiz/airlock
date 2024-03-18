xquery version "3.1";

module namespace bases="http://joewiz.org/ns/xquery/airlock/bases";

import module namespace app="http://joewiz.org/ns/xquery/airlock/app" at "app.xqm";
import module namespace config="http://joewiz.org/ns/xquery/airlock/config" at "config.xqm";

import module namespace airtable="http://joewiz.org/ns/xquery/airtable";
import module namespace markdown="http://exist-db.org/xquery/markdown";

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
    let $options := $column?options
    return
        switch ($type)
            (: TODO: Create additional test fields for
                - lookup(error|text|multilineText|foreignKey)
            Check color options for:
                - checkbox
            Split these cases into per-field-type functions, and eliminate the copied/pasted versions
            :)
            case "barcode" return
                (: "Barcode": {"text": "1234"} :)
                if ($field instance of map(*)) then
                    if ($field?text) then
                        $field?text
                    else
                        "UNKNOWN BARCODE TYPE " || map:keys($field) || ": " || serialize($field, map { "method": "adaptive" })
                else
                    "UNKNOWN BARCODE TYPE: " || map:keys($field) || ": " || serialize($field, map { "method": "adaptive" })
            case "phone" return
                element a {
                    attribute href { "tel:" || replace($field, "\D", "") },
                    $field
                }
            case "text" return
                switch ($options?validatorName)
                    case "url" return
                        element a {
                            attribute href { $field },
                            $field
                        }
                    case "email" return
                        element a {
                            attribute href { "mailto:" || $field },
                            $field
                        }
                    default return
                        $field
            case "button" return
                element a {
                    attribute class { "btn btn-primary" },
                    attribute href { $field?url },
                    $field?label
                }
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
            case "select" return
                let $value := $field
                let $choices := $options?choices
                let $color := $choices?*[?name eq $value]?color
                return
                    element span {
                        attribute class { "badge rounded-pill " || $bases:color-to-css-class?($color) },
                        $value
                    }
            case "multiSelect" return
                let $values := $field?*
                let $choices := $options?choices
                return
                    if (count($values) gt 1) then
                        element ol {
                            let $ordered-values := sort($values, (), function($value) { index-of($options?choiceOrder?*, $value) })
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
                        case "image/png" case "image/jpeg" case "application/pdf" return
                            let $thumbnails := $attachment?thumbnails
                            let $small := $thumbnails?small
                            return
                                element p {
                                    element a {
                                        attribute href { $url },
                                        element img {
                                            attribute src { 
                                                $small?url
                                            }
                                        }
                                    }
                                }
                        default return
                            "unknown image type " || $type
            case "count" 
            case "formula" 
            case "lookup"
            case "rollup" return
                switch ($options?resultType) 
                    case "text" return 
                        if ($field instance of array(*)) then
                            $field?*
                        else
                            $field
                    case "number" return 
                        if ($field instance of map(*)) then
                            if ($field?specialValue) then
                                element em { "not a number" }
                            else
                                element em { map:keys($field) || ": " || $field?* }
                        else if ($field instance of array (*)) then
                            element ol {
                                for $value in $field?*
                                return
                                    element li { $value }
                            }
                        else if ($options?format eq "percentV2") then
                            format-number($field, "0." || string-join((1 to $options?precision cast as xs:integer) ! "0") || "%")
                        else 
                            $field
                    case "date" return 
                        if ($options?isDateTime) then
                            let $dateTime := $field cast as xs:dateTime
                            let $date-format :=
                                switch ($options?dateFormat)
                                    case "Local" return
                                        "[M]/[D]/[Y]"
                                    case "Friendly" return
                                        "[MNn] [D], [Y]"
                                    case "US" return
                                        "[M]/[D]/[Y]"
                                    case "European" return
                                        "[D]/[M]/[Y]"
                                    case "ISO" return
                                        "[Y0001]-[M01]-[D01]"
                                    default return
                                        "UNKNOWN"
                            let $time-format := 
                                if ($options?timeFormat eq "24hour") then
                                    "[H01]:[m01]"
                                else (: if ($options?timeFormat eq "12hour") then :)
                                    "[h]:[m01][Pn]"
                            let $format := $date-format || " " || $time-format
                            return
                                if ($format ne "UNKNOWN") then 
                                    format-dateTime($dateTime, $format)
                                else
                                    "UNKNOWN FORMAT OPTIONS FOR DATE: " || $field
                        else
                            let $date := $field cast as xs:date
                            let $format :=
                                switch ($options?dateFormat)
                                    case "Local" return
                                        "[M]/[D]/[Y]"
                                    case "Friendly" return
                                        "[MNn] [D], [Y]"
                                    case "US" return
                                        "[M]/[D]/[Y]"
                                    case "European" return
                                        "[D]/[M]/[Y]"
                                    case "ISO" return
                                        "[Y0001]-[M01]-[D01]"
                                    default return
                                        "UNKNOWN"
                            return
                                if ($format ne "UNKNOWN") then 
                                    format-date($date, $format)
                                else
                                    "UNKNOWN FORMAT OPTIONS FOR DATE: " || $field
                    (: TODO get foreignkey lookups working properly :)
                    (:
                    case "foreignKey" return
                        let $foreign-table-rollup-column-id := $column?foreignTableRollupColumnId
                        let $relation-column := $
                        let $foreign-table-for-rollup-column := $tables[?id eq $relation-column?foreignTableId]
                        let $foreign-table-rollup-column := $foreign-table-for-rollup-column?columns?*[?id eq $foreign-table-rollup-column-id]
                        let $foreign-records := $foreign-table-for-rollup-column?records?*[?id = $field?*]
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
                    :)
                    default return
                        "UNIMPLEMENTED " || upper-case($type) || " FORMAT: " || $field
            (: TODO handle timeZone: client vs. UTC - but no apparent difference in Airtable UI? :)
            case "date" return
                if ($options?isDateTime) then
                    let $dateTime := $field cast as xs:dateTime
                    let $date-format :=
                        switch ($options?dateFormat)
                            case "Local" return
                                "[M]/[D]/[Y]"
                            case "Friendly" return
                                "[MNn] [D], [Y]"
                            case "US" return
                                "[M]/[D]/[Y]"
                            case "European" return
                                "[D]/[M]/[Y]"
                            case "ISO" return
                                "[Y0001]-[M01]-[D01]"
                            default return
                                "UNKNOWN"
                    let $time-format := 
                        if ($options?timeFormat eq "24hour") then
                            "[H01]:[m01]"
                        else (: if ($options?timeFormat eq "12hour") then :)
                            "[h]:[m01][Pn]"
                    let $format := $date-format || " " || $time-format
                    return
                        if ($format ne "UNKNOWN") then 
                            format-dateTime($dateTime, $format)
                        else
                            "UNKNOWN FORMAT OPTIONS FOR DATE: " || $field
                else
                    let $date := $field cast as xs:date
                    let $format :=
                        switch ($options?dateFormat)
                            case "Local" return
                                "[M]/[D]/[Y]"
                            case "Friendly" return
                                "[MNn] [D], [Y]"
                            case "US" return
                                "[M]/[D]/[Y]"
                            case "European" return
                                "[D]/[M]/[Y]"
                            case "ISO" return
                                "[Y0001]-[M01]-[D01]"
                            default return
                                "UNKNOWN"
                    return
                        if ($format ne "UNKNOWN") then 
                            format-date($date, $format)
                        else
                            "UNKNOWN FORMAT OPTIONS FOR DATE: " || $field
            (: TODO: show actual rating symbols, filled vs. outline: type-options: ?icon, ?max, ?color :)
            case "rating" return
                $field
            case "autoNumber" return
                $field
            case "number" return
                switch ($options?format) 
                    case "decimal" return
                        format-number($field, "0." || string-join((1 to $options?precision cast as xs:integer) ! "0"))
                    case "integer" return
                        format-number($field, "0")
                    case "currency" return
                        format-number($field, $options?symbol || "0." || string-join((1 to $options?precision cast as xs:integer) ! "0"))
                    case "percentV2" return
                        format-number($field, "0." || string-join((1 to $options?precision cast as xs:integer) ! "0") || "%")
                    case "duration" return
                        let $duration := xs:duration("PT" || $field || "S")
                        let $hours := hours-from-duration($duration)
                        let $minutes := minutes-from-duration($duration) => format-number("00")
                        let $seconds := seconds-from-duration($duration)
                        return
                            switch ($options?durationFormat)
                                case "h:mm" return
                                    $hours || ":" || $minutes
                                case "h:mm:ss" return
                                    $hours || ":" || $minutes || ":" || $seconds => format-number("00")
                                case "h:mm:ss.S" return
                                    $hours || ":" || $minutes || ":" || $seconds => format-number("00.0")
                                case "h:mm:ss.SS" return
                                    $hours || ":" || $minutes || ":" || $seconds => format-number("00.00")
                                case "h:mm:ss.SSS" return
                                    $hours || ":" || $minutes || ":" || $seconds => format-number("00.000")
                                default return
                                    "UNIMPLEMENTED DURATION: " || $field
                    default return
                        "UNSUPPORTED TYPE: " || $field
            case "collaborator" 
            case "multiCollaborator" return
                let $computation-type := $options?computationType
                let $values := if ($field instance of array(*)) then $field?* else $field
                return
                    if (count($values) gt 1) then
                        element ol {
                            for $value in $values
                            return
                                element li {
                                    text { $value?name || " <" },
                                    element a {
                                        attribute href { "mailto:" || $value?email },
                                        $value?email
                                    },
                                    text { ">" }
                                }
                        }
                    else
                        let $value := $values
                        return
                            (
                                text { $value?name || " <" },
                                element a {
                                    attribute href { "mailto:" || $value?email },
                                    $value?email
                                },
                                text { ">" }
                            )
            (: TODO "computation" can be used for createdBy, lastModifiedBy with various field options :)
            case "computation" return
                switch ($options?resultType) 
                    case "collaborator" return
                        let $value := $field
                        return
                            (
                                text { $value?name || " <" },
                                element a {
                                    attribute href { "mailto:" || $value?email },
                                    $value?email
                                },
                                text { ">" }
                            )
                    default return
                        $field
            case "checkbox" return
                if ($field) then
                    let $color := $options?color
                    return
                        (: TODO move these SVG definitions into global map variable, to facilitate reuse - between checkbox & rating
                            and test colors using pro/enterprise plan definitions:
                            
                            color: "yellowBright" | "orangeBright" | "redBright" | "pinkBright" | "purpleBright" | "blueBright" | "cyanBright" | "tealBright" | "greenBright" | "grayBright",
                        
                        :)
                        switch ($options?icon)
                            case "star" return 
                                (: https://icons.getbootstrap.com/icons/star-fill/ :) 
                                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="{$color}" class="bi bi-star-fill" viewBox="0 0 16 16">
                                    <path d="M3.612 15.443c-.386.198-.824-.149-.746-.592l.83-4.73L.173 6.765c-.329-.314-.158-.888.283-.95l4.898-.696L7.538.792c.197-.39.73-.39.927 0l2.184 4.327 4.898.696c.441.062.612.636.283.95l-3.523 3.356.83 4.73c.078.443-.36.79-.746.592L8 13.187l-4.389 2.256z"/>
                                </svg>
                            case "heart" return 
                                (: https://icons.getbootstrap.com/icons/heart-fill/ :)
                                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="{$color}" class="bi bi-heart-fill" viewBox="0 0 16 16">
                                <path fill-rule="evenodd" d="M8 1.314C12.438-3.248 23.534 4.735 8 15-7.534 4.736 3.562-3.248 8 1.314z"/>
                                </svg>
                            case "thumbsUp" return
                                (: https://icons.getbootstrap.com/icons/hand-thumbs-up-fill/ :)
                                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="{$color}" class="bi bi-hand-thumbs-up-fill" viewBox="0 0 16 16">
                                    <path d="M6.956 1.745C7.021.81 7.908.087 8.864.325l.261.066c.463.116.874.456 1.012.964.22.817.533 2.512.062 4.51a9.84 9.84 0 0 1 .443-.05c.713-.065 1.669-.072 2.516.21.518.173.994.68 1.2 1.273.184.532.16 1.162-.234 1.733.058.119.103.242.138.363.077.27.113.567.113.856 0 .289-.036.586-.113.856-.039.135-.09.273-.16.404.169.387.107.819-.003 1.148a3.162 3.162 0 0 1-.488.9c.054.153.076.313.076.465 0 .306-.089.626-.253.912C13.1 15.522 12.437 16 11.5 16H8c-.605 0-1.07-.081-1.466-.218a4.826 4.826 0 0 1-.97-.484l-.048-.03c-.504-.307-.999-.609-2.068-.722C2.682 14.464 2 13.846 2 13V9c0-.85.685-1.432 1.357-1.616.849-.231 1.574-.786 2.132-1.41.56-.626.914-1.279 1.039-1.638.199-.575.356-1.54.428-2.59z"/>
                                </svg>
                            case "flag" return 
                                (: https://icons.getbootstrap.com/icons/flag-fill/ :)
                                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="{$color}" class="bi bi-flag-fill" viewBox="0 0 16 16">
                                    <path d="M14.778.085A.5.5 0 0 1 15 .5V8a.5.5 0 0 1-.314.464L14.5 8l.186.464-.003.001-.006.003-.023.009a12.435 12.435 0 0 1-.397.15c-.264.095-.631.223-1.047.35-.816.252-1.879.523-2.71.523-.847 0-1.548-.28-2.158-.525l-.028-.01C7.68 8.71 7.14 8.5 6.5 8.5c-.7 0-1.638.23-2.437.477A19.626 19.626 0 0 0 3 9.342V15.5a.5.5 0 0 1-1 0V.5a.5.5 0 0 1 1 0v.282c.226-.079.496-.17.79-.26C4.606.272 5.67 0 6.5 0c.84 0 1.524.277 2.121.519l.043.018C9.286.788 9.828 1 10.5 1c.7 0 1.638-.23 2.437-.477a19.587 19.587 0 0 0 1.349-.476l.019-.007.004-.002h.001"/>
                                </svg>
                            default (: case "check" :) return 
                                (: https://icons.getbootstrap.com/icons/check/ :)
                                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="{$color}" class="bi bi-check" viewBox="0 0 16 16">
                                    <path d="M10.97 4.97a.75.75 0 0 1 1.07 1.05l-3.99 4.99a.75.75 0 0 1-1.08.02L4.324 8.384a.75.75 0 1 1 1.06-1.06l2.094 2.093 3.473-4.425a.267.267 0 0 1 .02-.022z"/>
                                </svg>
                else
                    ()
            default return
(:                if ($field instance of array(*)) then:)
(:                    if (array:size($field) gt 1) then:)
(:                        element ul {:)
(:                            $field?* ! element li { . } :)
(:                        }:)
(:                    else:)
(:                        $field?*:)
                (: "Position Length" : { "specialValue" : "NaN" } :)
(:                else if ($field instance of map(*)) then:)
(:                    $field?*:)
(:                else:)
                    "DEFAULT: " || serialize($field, map { "method": "adaptive" })
};

declare function bases:view-bases($request as map(*)) {
    let $base-url := $request?parameters?base-url
    let $base-id := $request?parameters?base-id
    let $snapshot-id := $request?parameters?snapshot-id
    let $format := $request?parameters?format
    let $bases := doc("/db/apps/airlock-data/bases/bases.xml")//base
    let $user-has-edit-permissions := sm:id()//sm:real/sm:groups/sm:group = config:repo-permissions()?group
    let $item :=
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
                                    if ($user-has-edit-permissions) then 
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
                            let $access-token := $base/access-token/string()
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
                                        if ($user-has-edit-permissions) then 
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
            if ($user-has-edit-permissions) then
                if (empty(doc("/db/apps/airlock-data/tokens/tokens.xml")//token-set)) then
                    <div>
                        <h3>Add a base</h3>
                        <p>To add a base, first <a href="{$base-url}/tokens">add your access token</a>.</p>
                    </div>
                else
                   <div>
                       <h3>Add a base</h3>
                       <p>Use the Notes field as you wish.</p>
                       <form method="POST" action="{$base-url}/bases">
                           <div class="mb-3">
                               <label for="base-id">Base ID:</label>
                               <input type="text" id="base-id" name="base-id" class="form-control" required="required" autofocus="autofocus"/>
                               <div class="form-text">To find your base's ID, see <a href="https://support.airtable.com/docs/finding-airtable-ids#finding-base-url-ids" target="_blank">Finding base URL IDs</a>.</div>
                           </div>
                           <div class="mb-3">
                               <label for="base-name">Base name:</label>
                               <input type="text" id="base-name" name="base-name" class="form-control" required="required"/>
                           </div>
                           <div class="mb-3">
                               <label for="access-token">Access token:</label>
                               <select class="form-select" aria-label="Select an access token" id="access-token" name="access-token">
                                   <option selected="selected">Select an access token</option>
                                   {
                                       for $token-set at $n in doc("/db/apps/airlock-data/tokens/tokens.xml")//token-set
                                       return
                                           <option value="{$token-set/access-token}">{$token-set/access-token/string()} ({$token-set/username/string()}) ({$token-set/notes/string()})</option>
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
    let $breadcrumb-entries :=
        (
            <a href="{$base-url}">Home</a>,
            <a href="{$base-url}/bases">Bases</a>
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

declare function bases:view-base($request as map(*)) {
    let $base-url := $request?parameters?base-url
    let $base-id := $request?parameters?base-id
    let $snapshot-id := $request?parameters?snapshot-id
    let $format := $request?parameters?format
    let $bases := doc("/db/apps/airlock-data/bases/bases.xml")//base
    let $base := $bases[id eq $base-id]
    let $base-name := $base/name/string()
    let $created-dateTime := $base/created-dateTime cast as xs:dateTime
    let $custom-reports := $base//custom-report
    let $snapshots := doc("/db/apps/airlock-data/bases/" || $base-id || "/snapshots.xml")//snapshot
    let $last-snapshot := $snapshots[last()]/created-dateTime[. ne ""] ! (. cast as xs:dateTime)
    let $user-has-edit-permissions := sm:id()//sm:real/sm:groups/sm:group = config:repo-permissions()?group
    let $item := 
        element div {
            element h2 { $base-name },
            element dl {
                element dt { "Base ID" },
                element dd { $base-id }
            },
            element ul {
                if ($user-has-edit-permissions) then
                    element li {
                        element a {
                            attribute href { $base-url || "/bases/" || $base-id || "/snapshot" },
                            "Take a new snapshot"
                        },
                        " (Note: This may take several minutes, depending on the size of the base.)"
                    }
                else
                    (),
                for $report in $custom-reports
                return
                    element li { 
                        element a { 
                            attribute href { $report/location },
                            $report/label/string()
                        },
                        ": ",
                        $report/description/string()
                    }
                },
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
                                    if ($user-has-edit-permissions) then 
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
                                        if ($user-has-edit-permissions) then 
                                            <td><a href="{$base-url || "/bases/" || $base-id || "/snapshots/" || $snapshot-id || "/delete"}">Delete</a></td>
                                        else
                                            ()
                                    }
                                </tr>
                        }</tbody>
                    </table>
                else if ($user-has-edit-permissions) then
                    ()
                else
                    <p>No snapshots. Please <a href="{$base-url}">log in</a> to take a new snapshot.</p>
        }
    let $breadcrumb-entries :=
        (
            <a href="{$base-url}">Home</a>,
            <a href="{$base-url}/bases">Bases</a>,
            <a href="{$base-url}/bases/{$base-id}">{$base-name}</a>
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

declare function bases:view-snapshot($request as map(*)) {
    let $base-url := $request?parameters?base-url
    let $base-id := $request?parameters?base-id
    let $snapshot-id := $request?parameters?snapshot-id
    let $format := $request?parameters?format
    let $bases := doc("/db/apps/airlock-data/bases/bases.xml")//base
    let $base := $bases[id eq $base-id]
    let $base-name := $base/name/string()
    let $snapshots := doc("/db/apps/airlock-data/bases/" || $base-id || "/snapshots.xml")//snapshot
    let $snapshot := $snapshots[id eq $snapshot-id]
    let $tables := 
        xmldb:get-child-resources("/db/apps/airlock-data/bases/" || $base-id || "/snapshots/" || $snapshot-id || "/tables") 
        ! json-doc("/db/apps/airlock-data/bases/" || $base-id || "/snapshots/" || $snapshot-id || "/tables/" || .) 
    let $item := 
        element div {
            element h2 { "Snapshot " || $snapshot-id },
            element dl {
                attribute class { "row" },
                element dt { attribute class { "col-sm-2" }, "Snapshot Date" },
                element dd { attribute class { "col-sm-10" }, ($snapshot/created-dateTime cast as xs:dateTime) => format-dateTime("[MNn] [D], [Y] [h]:[m01] [PN]") },
                element dt { attribute class { "col-sm-2" }, "Number of Tables" },
                element dd { attribute class { "col-sm-10" }, count($tables) }
            },
            element h3 { "Tables" },
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
    let $breadcrumb-entries :=
        (
            <a href="{$base-url}">Home</a>,
            <a href="{$base-url}/bases">Bases</a>,
            <a href="{$base-url}/bases/{$base-id}">{$base-name}</a>,
            <a href="{$base-url}/bases/{$base-id}/snapshots/{$snapshot-id}">Snapshot {$snapshot-id}</a>
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

declare function bases:view-table($request as map(*)) {
    let $base-url := $request?parameters?base-url
    let $base-id := $request?parameters?base-id
    let $snapshot-id := $request?parameters?snapshot-id
    let $table-id := $request?parameters?table-id
    let $format := $request?parameters?format
    let $bases := doc("/db/apps/airlock-data/bases/bases.xml")//base
    let $base := $bases[id eq $base-id]
    let $base-name := $base/name/string()
    let $snapshots := doc("/db/apps/airlock-data/bases/" || $base-id || "/snapshots.xml")//snapshot
    let $snapshot := $snapshots[id eq $snapshot-id]
    let $tables := 
        xmldb:get-child-resources("/db/apps/airlock-data/bases/" || $base-id || "/snapshots/" || $snapshot-id || "/tables") 
        ! json-doc("/db/apps/airlock-data/bases/" || $base-id || "/snapshots/" || $snapshot-id || "/tables/" || .)
    let $table := $tables[?id eq $table-id]
    let $table-name := $table?name
    let $primary-field-name := $table?fields?*[?id eq $table?primaryFieldId]?name
    let $fields-schema := $table?fields?*
    let $records := $table?records?*
    let $item := 
        element div {
            element h2 { $table-name },
            element dl {
                attribute class { "row" },
                element dt { attribute class { "col-sm-2" }, "Table ID" },
                element dd { attribute class { "col-sm-10" }, $table-id },
                element dt { attribute class { "col-sm-2" }, "Number of Fields" },
                element dd { attribute class { "col-sm-10" }, count($fields-schema) },
                element dt { attribute class { "col-sm-2" }, "Number of Records" },
                element dd { attribute class { "col-sm-10" }, count($records) }
            },
            element h3 { "Fields" },
            element ul {
                for $field-schema in $fields-schema
                let $field-id := $field-schema?id
                let $field-name := $field-schema?name
                return
                    element li {
                        element a {
                            attribute href { $base-url || "/bases/" || $base-id || "/snapshots/" || $snapshot-id  || "/" || $table-id || "/fields/" || $field-id },
                            $field-name
                        }
                    }
            },
            element h3 { "Records" },
            element ul {
                for $record in $records
                let $record-id := $record?id
                let $fields := $record?fields
                let $record-name := ($fields?($primary-field-name), "[null]")[1]
                order by $record-name collation "http://www.w3.org/2013/collation/UCA?numeric=yes"
                return
                    element li {
                        element a {
                            attribute href { $base-url || "/bases/" || $base-id || "/snapshots/" || $snapshot-id  || "/" || $table-id || "/records/" || $record-id },
                            $record-name
                        }
                    }
            },
(:            element pre {
                $table => serialize( map{ "method": "json", "indent": true() } )
            },:)
            element a {
                attribute href { "./" || $table-id || "?format=json" },
                "View raw JSON"
            }
        }
    let $breadcrumb-entries :=
        (
            <a href="{$base-url}">Home</a>,
            <a href="{$base-url}/bases">Bases</a>,
            <a href="{$base-url}/bases/{$base-id}">{$base-name}</a>,
            <a href="{$base-url}/bases/{$base-id}/snapshots/{$snapshot-id}">Snapshot {$snapshot-id}</a>,
            <a href="{$base-url}/bases/{$base-id}/snapshots/{$snapshot-id}/{$table-id}">Table “{$table-name}”</a>
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

declare function bases:view-field($request as map(*)) {
    let $base-url := $request?parameters?base-url
    let $base-id := $request?parameters?base-id
    let $snapshot-id := $request?parameters?snapshot-id
    let $table-id := $request?parameters?table-id
    let $field-id := $request?parameters?field-id
    let $format := $request?parameters?format
    let $bases := doc("/db/apps/airlock-data/bases/bases.xml")//base
    let $base := $bases[id eq $base-id]
    let $base-name := $base/name/string()
    let $snapshots := doc("/db/apps/airlock-data/bases/" || $base-id || "/snapshots.xml")//snapshot
    let $snapshot := $snapshots[id eq $snapshot-id]
    let $tables := 
        xmldb:get-child-resources("/db/apps/airlock-data/bases/" || $base-id || "/snapshots/" || $snapshot-id || "/tables") 
        ! json-doc("/db/apps/airlock-data/bases/" || $base-id || "/snapshots/" || $snapshot-id || "/tables/" || .)
    let $table := $tables[?id eq $table-id]
    let $table-name := $table?name
    let $primary-field-name := $table?fields?*[?id eq $table?primaryFieldId]?name
    let $fields-schema := $table?fields?*
    let $field-schema := $fields-schema[?id eq $field-id]
    let $field-name := $field-schema?name
    let $item := 
        element div {
            element h2 { $field-name },
            element dl {
                attribute class { "row" },
                element dt { attribute class { "col-sm-2" }, "Field ID" },
                element dd { attribute class { "col-sm-10" }, $field-id },
                element dt { attribute class { "col-sm-2" }, "Field Type" },
                element dd { attribute class { "col-sm-10" }, $field-schema?type },
                if (map:contains($field-schema, "options")) then
                    if (count($field-schema?options?*) gt 0) then
                        (
                            element dt { attribute class { "col-sm-2" }, "typeOptions" },
                            element dd {
                                attribute class { "col-sm-10" }, 
                                let $options := $field-schema?options
                                let $choices := $options?choices?*
                                let $choice-order := $options?choiceOrder
                                let $foreign-table-id := $options?foreignTableId
                                let $foreign-table := $tables[?id eq $foreign-table-id]
                                let $symmetric-column-id := $options?symmetricColumnId
                                let $symmetric-column := $foreign-table?columns?*[?id eq $symmetric-column-id]
                                let $relation-column-id := $options?relationColumnId
                                let $relation-column := $table?columns?*[?id eq $relation-column-id]
                                let $foreign-table-rollup-column-id := $options?foreignTableRollupColumnId
                                let $foreign-table-for-rollup-column := $tables[?id eq $relation-column?foreignTableId]
                                let $foreign-table-rollup-column := $foreign-table-for-rollup-column?columns?*[?id eq $foreign-table-rollup-column-id]
                                return
                                    if (exists($choices) and exists($choice-order)) then
                                        element dl {
                                            attribute class { "row" },
                                            element dt { attribute class { "col-sm-2" }, "choices" },
                                            element dd {
                                                attribute class { "col-sm-10" }, 
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
                                        element dl {
                                            attribute class { "row" },
                                            for $option-key in ($options ! map:keys(.)[not(. = ("choices", "choice-order"))]) (: except ($choices, $choice-order) :)
                                            let $option-value := $options($option-key)
                                            let $dt-dd-pair :=
                                                (
                                                    element dt { attribute class { "col-sm-2" }, $option-key },
                                                    element dd { attribute class { "col-sm-10" }, 
                                                        switch ($option-key)
                                                            case "foreignTableRollupColumnId" return
                                                                element a {
                                                                    attribute href {
                                                                        $base-url || "/bases/" || $base-id || "/snapshots/" || $snapshot-id  || "/" || $foreign-table-for-rollup-column?id
                                                                    },
                                                                    $foreign-table-rollup-column?name
                                                                }
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
                                                                (: TODO: confirm there's no need to display dependencies since they're always a duplicate of data in other entries :)
                                                                ()
                                                                (:
                                                                element ol {
                                                                    for $referenced-column-id in $option-value?referencedColumnIdsForValue?*
                                                                    let $referenced-column := $table?columns?*[?id eq $referenced-column-id]
                                                                    return
                                                                        element li { 
                                                                            element a {
                                                                                attribute href {
                                                                                    $base-url || "/bases/" || $base-id || "/snapshots/" || $snapshot-id  || "/" || $table-id || "/fields/" || $referenced-column-id
                                                                                },
                                                                                $referenced-column?name || " (" || $referenced-column-id || ")"
                                                                            }
                                                                        }
                                                                }
                                                                :)
                                                            (: TODO make field references into links - switch from replace to analyze-string :)
                                                            case "formulaTextParsed" return
                                                                element code { element pre { 
                                                                    (: rollups sometimes contain dependencies?referencedColumnIdsForValue that have nothing to do with formulaTextParsed :)
                                                                    if (contains($options?formulaTextParsed, "column_value_") or contains($options?formulaTextParsed, "column_modified_time_")) then
                                                                        fold-left(
                                                                            $options?dependencies?referencedColumnIdsForValue?*,
                                                                            $options?formulaTextParsed,
                                                                            function ($text, $id) {
                                                                                replace(
                                                                                    $text,
                                                                                    "column_value_" || $id,
                                                                                    $columns[?id eq $id]?name
                                                                                )
                                                                            }
                                                                        )
                                                                        => 
                                                                            (
                                                                                function($processed-text) { 
                                                                                    fold-left(
                                                                                        $options?dependencies?referencedColumnIdsForModification?*,
                                                                                        $processed-text,
                                                                                        function ($text, $id) {
                                                                                            replace(
                                                                                                $text,
                                                                                                "column_modified_time_" || $id,
                                                                                                $columns[?id eq $id]?name
                                                                                            )
                                                                                        }
                                                                                    )
                                                                                }
                                                                            )()
                                                                    else
                                                                        $options?formulaTextParsed
                                                                } }
                                                            case "actionType" 
                                                            case "color" 
                                                            case "computationType"
                                                            case "dateFormat" 
                                                            case "displayType"
                                                            case "durationFormat"
                                                            case "format"
                                                            case "icon" 
                                                            case "isDateTime"
                                                            case "max" 
                                                            case "maxUsedAutoNumber"
                                                            case "negative"
                                                            case "precision"
                                                            case "relationship"
                                                            case "resultType" 
                                                            case "shouldNotify"
                                                            case "symbol"
                                                            case "timeFormat"
                                                            case "timeZone"
                                                            case "unreversed"
                                                            case "validatorName"
                                                            return
                                                                $option-value
                                                            
                                                            (: TODO computationParams below can reference columnIds, which should be parsed/linked:)
                                                            case "label" 
                                                            case "variant" 
                                                            case "computationParams" return
                                                                ``[
                                                                element dl {
                                                                    attribute class { "row" },
                                                                    for $k in map:keys($option-value)
                                                                    let $e := $option-value?($k)
                                                                    let $dt-dd-pair :=
                                                                        (
                                                                            element dt { 
                                                                                attribute class { "col-sm-2" },
                                                                                $k
                                                                            },
                                                                            element dd { 
                                                                                attribute class { "col-sm-10" },
                                                                                if ($e instance of array(*)) then
                                                                                    if ($k eq "columnIds" and count($e?*) ge 1) then
                                                                                        let $field := $fields[?id = $e?*]
                                                                                        let $field-schema := $fields-schema[?id = $e?*]
                                                                                        return
                                                                                            element a { 
                                                                                                attribute href { $base-url || "/bases/" || $base-id || "/snapshots/" || $snapshot-id || "/" || $table-id || "/fields/" || $field?id }, 
                                                                                                $field-schema?name 
                                                                                            }
                                                                                    else
                                                                                        serialize($e, map { "method": "adaptive" })
                                                                                else
                                                                                    $e
                                                                            }
                                                                        )
                                                                    where ($dt-dd-pair[2] => string-join() => string-length()) gt 0
                                                                    return 
                                                                        $dt-dd-pair
                                                                }
                                                                ]``
                                                                
                                                            default return
                                                                "UNKNOWN TYPE OPTION: " || $option-value => serialize(map { "method": "adaptive" } )
                                                    }
                                                )
                                            (: filter out empty entries, such as "dependencies": { "referencedColumnIdsForValue": [] } :)
                                            where ($dt-dd-pair[2] => string-join() => string-length()) gt 0
                                            return
                                                $dt-dd-pair
                                        }
                            }
                        )
                    else
                        ()
                else
                    ()
            },
            element pre {
                $field-schema => serialize( map{ "method": "json", "indent": true() } )
            },
            element a {
                attribute href { "./" || $field-id || "?format=json" },
                "View raw JSON"
            }
        }
    let $breadcrumb-entries :=
        (
            <a href="{$base-url}">Home</a>,
            <a href="{$base-url}/bases">Bases</a>,
            <a href="{$base-url}/bases/{$base-id}">{$base-name}</a>,
            <a href="{$base-url}/bases/{$base-id}/snapshots/{$snapshot-id}">Snapshot {$snapshot-id}</a>,
            <a href="{$base-url}/bases/{$base-id}/snapshots/{$snapshot-id}/{$table-id}">Table “{$table-name}”</a>,
            <a href="{$base-url}/bases/{$base-id}/snapshots/{$snapshot-id}/{$table-id}/fields/{$field-id}">Field “{$field-name}”</a>
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

declare function bases:view-record($request as map(*)) {
    let $base-url := $request?parameters?base-url
    let $base-id := $request?parameters?base-id
    let $snapshot-id := $request?parameters?snapshot-id
    let $table-id := $request?parameters?table-id
    let $record-id := $request?parameters?record-id
    let $format := $request?parameters?format
    let $bases := doc("/db/apps/airlock-data/bases/bases.xml")//base
    let $base := $bases[id eq $base-id]
    let $base-name := $base/name/string()
    let $snapshots := doc("/db/apps/airlock-data/bases/" || $base-id || "/snapshots.xml")//snapshot
    let $snapshot := $snapshots[id eq $snapshot-id]
    let $tables := 
        xmldb:get-child-resources("/db/apps/airlock-data/bases/" || $base-id || "/snapshots/" || $snapshot-id || "/tables") 
        ! json-doc("/db/apps/airlock-data/bases/" || $base-id || "/snapshots/" || $snapshot-id || "/tables/" || .)
    let $table := $tables[?id eq $table-id]
    let $table-name := $table?name
    let $fields-schema := $table?fields?*
    let $primary-field-name := $fields-schema[?id eq $table?primaryFieldId]?name
    let $records := $table?records?*
    let $record := $records[?id eq $record-id]
    let $render-function := function($field-key) { bases:render-field($base-url, $base-id, $snapshot-id, $tables, $table, $record, $field-key) }
    let $item := 
        element div { 
            element h2 { $render-function($primary-field-name) },
            element dl { 
                attribute class { "row" },
                element dt { attribute class { "col-sm-2" }, "Record ID" },
                element dd { attribute class { "col-sm-10" }, $record-id }
            },
            element table {
                attribute class { "table table-bordered" },
                element thead { 
                    element tr { 
                        element th { "Field name" },
                        element th { "Value" }
                    }
                },
                element tbody {
                    for $field-key in ($primary-field-name, $fields-schema?name[. ne $primary-field-name])
                    let $field-id := $fields-schema[?name eq $field-key]?id
                    return
                        element tr {
                            element th { attribute class { "col-sm-2" }, 
                                element a {
                                    attribute href { $base-url || "/bases/" || $base-id || "/snapshots/" || $snapshot-id  || "/" || $table-id || "/fields/" || $field-id[1] },
                                    $field-key
                                }
                            },
                            element td { attribute class { "col-sm-10" }, 
    (:                            $render-function($field-key):)
                                try { 
                                    let $rendered-field := $render-function($field-key)
                                    return
                                        if ($rendered-field instance of map(*) or $rendered-field instance of array(*)) then
                                            "MAP OR ARRAY!!! " || $rendered-field => serialize(map { "method": "adaptive" }) 
                                        else
                                            $rendered-field
                                } catch * { "error rendering: table-id: " || $table-id || " record-id: " || $record-id || " error: " || $err:description } 
                            }
                        }
                }
            },
            element pre {
                $record => serialize( map{ "method": "json", "indent": true() } )
            },
            element a {
                attribute href { "./" || $record-id || "?format=json" },
                "View raw JSON"
            }
        }
    let $breadcrumb-entries :=
        (
            <a href="{$base-url}">Home</a>,
            <a href="{$base-url}/bases">Bases</a>,
            <a href="{$base-url}/bases/{$base-id}">{$base-name}</a>,
            <a href="{$base-url}/bases/{$base-id}/snapshots/{$snapshot-id}">Snapshot {$snapshot-id}</a>,
            <a href="{$base-url}/bases/{$base-id}/snapshots/{$snapshot-id}/{$table-id}">Table “{$table-name}”</a>,
            <a href="{$base-url}/bases/{$base-id}/snapshots/{$snapshot-id}/{$table-id}/records/{$record-id}">Record “{$primary-field-name}”</a>
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
    let $access-token := $request?parameters?access-token
    let $permission-level := $request?parameters?permission-level
    let $notes := $request?parameters?notes
    let $new-base := bases:base-element($new-base-id, $base-name, $access-token, $permission-level, $notes, $base/custom-reports/custom-report, $base/created-dateTime cast as xs:dateTime, current-dateTime())
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
    let $base-access-token := $base/access-token
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
                    <label for="access-token">Access token:</label>
                    <div>
                        <select class="form-select" aria-label="Select an access token" id="access-token" name="access-token">
                            <option>Select an access token</option>
                            {
                                for $token-set at $n in doc("/db/apps/airlock-data/tokens/tokens.xml")//token-set
                                return
                                    <option value="{$token-set/access-token}">{
                                        if ($token-set/access-token eq $base-access-token) then
                                            attribute selected { "selected" }
                                        else
                                            (),
                                        $token-set/access-token/string()
                                    } ({$token-set/username/string()})</option>
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

declare function bases:base-element($base-id as xs:string, $base-name as xs:string, $access-token as xs:string, $permission-level as xs:string, $notes as xs:string, $custom-reports as element(custom-report)*, $created-dateTime as xs:dateTime, $last-modified-dateTime as xs:dateTime?) {
    element base {
        element id { $base-id },
        element name { $base-name },
        element access-token { $access-token },
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
    let $access-token := $request?parameters?access-token
    let $permission-level := $request?parameters?permission-level
    let $notes := $request?parameters?notes
    let $new-base := bases:base-element($base-id, $base-name, $access-token, $permission-level, $notes, (), current-dateTime(), ())
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
    let $store := bases:store("/db/apps/airlock-data/bases/" || $base-id, $config:base-schema-doc-name, $file)
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
    let $access-token := $base/access-token/string()
    let $snapshots-doc := doc("/db/apps/airlock-data/bases/" || $base-id || "/snapshots.xml")/snapshots
    let $next-id := ($snapshots-doc/snapshot[last()]/id, "0")[1] cast as xs:integer + 1
    let $snapshot := element snapshot { element id { $next-id }, element created-dateTime { current-dateTime() } }
    let $schema := airtable:get-base-schema($access-token, $base-id)
    let $prepare :=
        (
            bases:mkcol("/db/apps/airlock-data/bases/", $base-id || "/snapshots/" || $next-id || "/tables"),
            bases:store("/db/apps/airlock-data/bases/" || $base-id || "/snapshots/" || $next-id, $config:base-schema-doc-name, $schema => serialize(map{"method": "json", "indent": true()})),
            if (exists($snapshots-doc)) then
                update insert $snapshot into $snapshots-doc
            else
                bases:store("/db/apps/airlock-data/bases/" || $base-id, "snapshots.xml", element snapshots { $snapshot } )
        )
    let $tables := json-doc("/db/apps/airlock-data/bases/" || $base-id || "/snapshots/" || $next-id || "/" || $config:base-schema-doc-name)?tables?*
    let $store :=
        for $table-schema in $tables
        let $table-name := $table-schema?name
        let $table-id := $table-schema?id
        let $records := airtable:list-records($access-token, $base-id, $table-id)?records
        let $contents := 
            map { 
                "name": $table-name,
                "id": $table-schema?id,
                "primaryFieldId": $table-schema?primaryFieldId,
                "fields": $table-schema?fields,
                "records": array:join($records)
            }
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
                ($table-name || ".json")
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
            <p>Welcome to Airlock. Guest users can browse existing bases. To add an access token, add bases, and take snapshots, <a href="{$base-url}/login">log in</a> as a user who is a member of the <code>{config:repo-permissions()?group}</code> group.</p>
            <ul>
                {
                    if (sm:id()//sm:real/sm:groups/sm:group = config:repo-permissions()?group) then 
                        <li><a href="{$base-url}/tokens">Access tokens</a></li>
                    else
                        ()
                }
                <li><a href="{$base-url}/bases">Bases</a></li>
                {
                    if (sm:id()//sm:real/sm:groups/sm:group = config:repo-permissions()?group) then 
                        <li><a href="{$base-url}/login?logout=true">Log out</a>. You are logged in as {sm:id()//sm:real/sm:username/string()}.</li>
                    else
                        <li><a href="{$base-url}/login">Log in</a></li>
                }
            </ul>
        </div>
    return
        app:wrap($content, $title)
};

