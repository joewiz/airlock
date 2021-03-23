xquery version "3.1";

module namespace keys="http://joewiz.org/ns/xquery/airlock/keys";

import module namespace app="http://joewiz.org/ns/xquery/airlock/app" at "app.xqm";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "html";
declare option output:media-type "text/html";

declare function keys:create-key-set($key-id as xs:string, $username as xs:string, $rest-api-key as xs:string, $metadata-api-key as xs:string, $notes as xs:string, $created-dateTime as xs:dateTime, $last-modified-dateTime as xs:dateTime?) {
    element key-set {
        element id { $key-id },
        element username { $username },
        element rest-api-key { $rest-api-key },
        element metadata-api-key { $metadata-api-key },
        element notes { $notes },
        element created-dateTime { $created-dateTime },
        element last-modified-dateTime { $last-modified-dateTime }
    }
};

declare function keys:delete-key-confirm($request as map(*)) {
    let $base-url := $request?parameters?base-url
    let $key-id := $request?parameters?key-id
    let $title := "Are you sure?"
    let $content := 
        <div class="alert alert-danger" role="alert">
            <h4 class="alert-heading">{$title}</h4>
            <form method="POST" action="{$base-url}/keys/{$key-id}/delete">
                <button class="button btn-danger" type="submit">Delete this API key</button>
            </form>
            <a class="button btn-default" href="{$base-url}/keys">Cancel</a>
        </div>
    return
        app:wrap($content, $title)
};

declare function keys:delete-key($request as map(*)) {
    let $base-url := $request?parameters?base-url
    let $key-id := $request?parameters?key-id
    let $key-set := doc("/db/apps/airlock-data/keys/keys.xml")/key-sets/key-set[id eq $key-id]
    let $action := update delete $key-set
    let $title := "Success"
    let $content :=
        <div class="alert alert-success" role="alert">
            <h4 class="alert-heading">{$title}</h4>
            <p>Key successfully deleted. <a href="{$base-url}/keys">Return to API Keys</a>.</p>
        </div>
    return
        app:wrap($content, $title)
};

declare function keys:update-key($request as map(*)) {
    let $base-url := $request?parameters?base-url
    let $key-id := $request?parameters?key-id
    let $key-set := doc("/db/apps/airlock-data/keys/keys.xml")/key-sets/key-set[id eq $key-id]
    let $username := $request?parameters?username
    let $rest-api-key := $request?parameters?rest-api-key
    let $metadata-api-key := $request?parameters?metadata-api-key
    let $notes := $request?parameters?notes
    let $new-key-set := keys:create-key-set($key-id, $username, $rest-api-key, $metadata-api-key, $notes, $key-set/created-dateTime cast as xs:dateTime, current-dateTime())
    let $update := update replace $key-set with $new-key-set
    let $title := "Success"
    let $content := 
        <div class="alert alert-success" role="alert">
            <h4 class="alert-heading">{$title}</h4>
            <p>Key successfully updated. <a href="{$base-url}/keys">Return to API Keys</a>.</p>
        </div>
    return
        $content => app:wrap($title)
};

declare function keys:create-key($request as map(*)) {
    let $base-url := $request?parameters?base-url
    let $key-sets := doc("/db/apps/airlock-data/keys/keys.xml")/key-sets
    let $max-id := max(($key-sets/key-set/id ! (. cast as xs:integer), 0))
    let $new-id := $max-id + 1
    let $username := $request?parameters?username
    let $rest-api-key := $request?parameters?rest-api-key
    let $metadata-api-key := $request?parameters?metadata-api-key
    let $notes := $request?parameters?notes
    let $new-key-set := keys:create-key-set($new-id, $username, $rest-api-key, $metadata-api-key, $notes, current-dateTime(), ())
    let $update := update insert $new-key-set into $key-sets
    let $title := "Success"
    let $content := 
        <div class="alert alert-success" role="alert">
            <h4 class="alert-heading">{$title}</h4>
            <p>Key successfully created. <a href="{$base-url}/keys">Return to API Keys</a>.</p>
        </div>
    return
        $content => app:wrap($title)
};

declare function keys:edit-form($request as map(*)) {
    let $base-url := $request?parameters?base-url
    let $key-id := $request?parameters?key-id
    let $key-set := doc("/db/apps/airlock-data/keys/keys.xml")/key-sets/key-set[id eq $key-id]
    let $title := "Edit Key " || $key-id
    let $content := 
        <div>
            <h1>Airlock</h1>
            <nav aria-label="breadcrumb">
                <ol class="breadcrumb">
                    <li class="breadcrumb-item"><a href="{$base-url}">Home</a></li>
                    <li class="breadcrumb-item"><a href="{$base-url}/keys">API Keys</a></li>
                    <li class="breadcrumb-item active" aria-current="page">{$title}</li>
                </ol>
            </nav>
            <h2>{$title}</h2>
            
            <form method="POST" action="{$base-url}/keys/{$key-id}">
                <div class="mb-3">
                    <label for="username">Airtable Username:</label>
                    <input type="text" id="username" name="username" class="form-control" required="required" autofocus="autofocus" value="{$key-set/username}"/>
                    <div class="form-text">The Airtable username associated with your API key. To help you distinguish between multiple API keys.</div>
                </div>
                <div class="mb-3">
                    <label for="rest-api-key">REST API Key:</label>
                    <input type="text" id="rest-api-key" name="rest-api-key" class="form-control" required="required" value="{$key-set/rest-api-key}"/>
                    <div class="form-text">To find your API Key, go to <a href="https://airtable.com/account" target="_blank">https://airtable.com/account</a> and look at the section called “API.”</div>
                </div>
                <div class="mb-3">
                    <label for="metadata-api-key">Metadata API Key:</label>
                    <input type="text" id="metadata-api-key" name="metadata-api-key" class="form-control" value="{$key-set/metadata-api-key}"/>
                    <div class="form-text">If you have applied for a Airtable Metadata API Access, Airtable support will email the Metadata API Key to you; otherwise, leave this blank.</div>
                </div>
                <div class="mb-3">
                    <label for="notes">Notes:</label>
                    <textarea type="text" id="notes" name="notes" class="form-control" rows="3">{$key-set/notes/string()}</textarea>
                    <div class="form-text">Any additional notes.</div>
                </div>
                <button class="btn btn-secondary" type="reset">Clear</button>
                <button class="btn btn-primary" type="submit">Submit</button>
                <br/>
                <a href="{$base-url}/keys/{$key-id}/delete" class="btn btn-danger" type="submit">Delete</a>
            </form>
        </div>
    return
        app:wrap($content, $title)
};

declare function keys:welcome($request as map(*)) {
    let $title := "API Keys"
    let $base-url := $request?parameters?base-url
    let $key-sets := doc("/db/apps/airlock-data/keys/keys.xml")/key-sets/key-set
    let $content := 
        <div>
            <h1>Airlock</h1>
            <nav aria-label="breadcrumb">
                <ol class="breadcrumb">
                    <li class="breadcrumb-item"><a href="{$base-url}">Home</a></li>
                    <li class="breadcrumb-item active" aria-current="page">{$title}</li>
                </ol>
            </nav>
            <h2>{$title}</h2>
            {
                if (exists($key-sets)) then
                    <table class="table table-bordered">
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Airtable Username</th>
                                <th>REST API Key</th>
                                <th>Metadata API Key</th>
                                <th>Notes</th>
                                <th>Date Created</th>
                                <th>Last Modified</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        {
                            for $key-set in $key-sets
                            return
                                <tr>
                                    <td>{$key-set/id/string()}</td>
                                    <td>{$key-set/username/string()}</td>
                                    <td>{$key-set/rest-api-key/string()}</td>
                                    <td>{$key-set/metadata-api-key/string()}</td>
                                    <td>{$key-set/notes/string()}</td>
                                    <td>{
                                        ($key-set/created-dateTime cast as xs:dateTime) 
                                            => format-dateTime("[MNn] [D], [Y] at [h]:[m01] [PN]")}</td>
                                    <td>{
                                        if ($key-set/last-modified-dateTime ne "") then
                                            ($key-set/last-modified-dateTime cast as xs:dateTime) 
                                                => format-dateTime("[MNn] [D], [Y] at [h]:[m01] [PN]")
                                        else 
                                            <em>No modifications</em>
                                    }</td>
                                    <td><a href="{$base-url}/keys/{$key-set/id}">Edit</a></td>
                                </tr>
                        }
                    </table>
                else
                    <p>No keys have been added.</p>
            }
            <h3>Add an API Key</h3>
            <form method="POST" action="{$base-url}/keys">
                <div class="mb-3">
                    <label for="username">Airtable Username:</label>
                    <input type="text" id="username" name="username" class="form-control" required="required" autofocus="autofocus"/>
                    <div class="form-text">The Airtable username associated with your API Key. To help you distinguish between multiple API Keys.</div>
                </div>
                <div class="mb-3">
                    <label for="rest-api-key">REST API Key:</label>
                    <input type="text" id="rest-api-key" name="rest-api-key" class="form-control" required="required"/>
                    <div class="form-text">To find your API Key, go to <a href="https://airtable.com/account" target="_blank">https://airtable.com/account</a> and look at the section called “API.”</div>
                </div>
                <div class="mb-3">
                    <label for="metadata-api-key">Metadata API Key:</label>
                    <input type="text" id="metadata-api-key" name="metadata-api-key" class="form-control" />
                    <div class="form-text">If you have applied for a Airtable Metadata API Access, Airtable support will email the Metadata API Key to you; otherwise, leave this blank.</div>
                </div>
                <div class="mb-3">
                    <label for="notes">Notes:</label>
                    <textarea type="text" id="notes" name="notes" class="form-control" rows="3"/>
                    <div class="form-text">Any additional notes.</div>
                </div>
                <button class="btn btn-secondary" type="reset">Clear</button>
                <button class="btn btn-primary" type="submit">Create New API Key</button>
            </form>
        </div>
    return
        app:wrap($content, $title)
};
