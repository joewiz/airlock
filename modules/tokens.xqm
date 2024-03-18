xquery version "3.1";

module namespace tokens="http://joewiz.org/ns/xquery/airlock/tokens";

import module namespace app="http://joewiz.org/ns/xquery/airlock/app" at "app.xqm";

declare function tokens:create-token-set($token-id as xs:string, $username as xs:string, $access-token as xs:string, $notes as xs:string, $created-dateTime as xs:dateTime, $last-modified-dateTime as xs:dateTime?) {
    element token-set {
        element id { $token-id },
        element username { $username },
        element access-token { $access-token },
        element notes { $notes },
        element created-dateTime { $created-dateTime },
        element last-modified-dateTime { $last-modified-dateTime }
    }
};

declare function tokens:delete-token-confirm($request as map(*)) {
    let $base-url := $request?parameters?base-url
    let $token-id := $request?parameters?token-id
    let $title := "Delete this token?"
    let $content := 
        <div class="alert alert-danger" role="alert">
            <h4 class="alert-heading">{$title}</h4>
            <form method="POST" action="{$base-url}/tokens/{$token-id}/delete">
                <button class="button btn-danger" type="submit">Delete this access token</button>
            </form>
            <a class="button btn-default" href="{$base-url}/tokens">Cancel</a>
        </div>
    return
        app:wrap($content, $title)
};

declare function tokens:delete-token($request as map(*)) {
    let $base-url := $request?parameters?base-url
    let $token-id := $request?parameters?token-id
    let $token-set := doc("/db/apps/airlock-data/tokens/tokens.xml")/token-sets/token-set[id eq $token-id]
    let $action := update delete $token-set
    let $title := "Success"
    let $content :=
        <div class="alert alert-success" role="alert">
            <h4 class="alert-heading">{$title}</h4>
            <p>Token successfully deleted. <a href="{$base-url}/tokens">Return to Access Tokens</a>.</p>
        </div>
    return
        app:wrap($content, $title)
};

declare function tokens:update-token($request as map(*)) {
    let $base-url := $request?parameters?base-url
    let $token-id := $request?parameters?token-id
    let $token-set := doc("/db/apps/airlock-data/tokens/tokens.xml")/token-sets/token-set[id eq $token-id]
    let $username := $request?parameters?username
    let $access-token := $request?parameters?access-token
    let $notes := $request?parameters?notes
    let $new-token-set := tokens:create-token-set($token-id, $username, $access-token, $notes, $token-set/created-dateTime cast as xs:dateTime, current-dateTime())
    let $update := update replace $token-set with $new-token-set
    let $title := "Success"
    let $content := 
        <div class="alert alert-success" role="alert">
            <h4 class="alert-heading">{$title}</h4>
            <p>Token successfully updated. <a href="{$base-url}/tokens">Return to Access Tokens</a>.</p>
        </div>
    return
        $content => app:wrap($title)
};

declare function tokens:create-token($request as map(*)) {
    let $base-url := $request?parameters?base-url
    let $token-sets := doc("/db/apps/airlock-data/tokens/tokens.xml")/token-sets
    let $max-id := max(($token-sets/token-set/id ! (. cast as xs:integer), 0))
    let $new-id := $max-id + 1
    let $username := $request?parameters?username
    let $access-token := $request?parameters?access-token
    let $notes := $request?parameters?notes
    let $new-token-set := tokens:create-token-set($new-id, $username, $access-token, $notes, current-dateTime(), ())
    let $update := update insert $new-token-set into $token-sets
    let $title := "Success"
    let $content := 
        <div class="alert alert-success" role="alert">
            <h4 class="alert-heading">{$title}</h4>
            <p>Token successfully created. <a href="{$base-url}/tokens">Return to Access Tokens</a>.</p>
        </div>
    return
        $content => app:wrap($title)
};

declare function tokens:edit-form($request as map(*)) {
    let $base-url := $request?parameters?base-url
    let $token-id := $request?parameters?token-id
    let $token-set := doc("/db/apps/airlock-data/tokens/tokens.xml")/token-sets/token-set[id eq $token-id]
    let $title := "Edit Access Token " || $token-id
    let $content := 
        <div>
            <h1>Airlock</h1>
            <nav aria-label="breadcrumb">
                <ol class="breadcrumb">
                    <li class="breadcrumb-item"><a href="{$base-url}">Home</a></li>
                    <li class="breadcrumb-item"><a href="{$base-url}/access-tokens">Access Tokens</a></li>
                    <li class="breadcrumb-item active" aria-current="page">{$title}</li>
                </ol>
            </nav>
            <h2>{$title}</h2>
            
            <form method="POST" action="{$base-url}/tokens/{$token-id}">
                <div class="mb-3">
                    <label for="username">Airtable Username:</label>
                    <input type="text" id="username" name="username" class="form-control" required="required" autofocus="autofocus" value="{$token-set/username}"/>
                    <div class="form-text">The Airtable username associated with your personal access token or service account access token. Rate limits are applied on the account level, and not per access token or per base.</div>
                </div>
                <div class="mb-3">
                    <label for="access-token">Access Token:</label>
                    <input type="text" id="access-token" name="access-token" class="form-control" required="required" value="{$token-set/access-token}"/>
                    <div class="form-text">To create a personal access token, go to <a href="https://airtable.com/create/tokens" target="_blank">https://airtable.com/create/tokens</a> and select “Create new token.”</div>
                </div>
                <div class="mb-3">
                    <label for="notes">Notes:</label>
                    <textarea type="text" id="notes" name="notes" class="form-control" rows="3">{$token-set/notes/string()}</textarea>
                    <div class="form-text">Any additional notes.</div>
                </div>
                <button class="btn btn-secondary" type="reset">Clear</button>
                <button class="btn btn-primary" type="submit">Submit</button>
                <br/>
                <a href="{$base-url}/tokens/{$token-id}/delete" class="btn btn-danger" type="submit">Delete</a>
            </form>
        </div>
    return
        app:wrap($content, $title)
};

declare function tokens:welcome($request as map(*)) {
    let $title := "Access Tokens"
    let $base-url := $request?parameters?base-url
    let $token-sets := doc("/db/apps/airlock-data/tokens/tokens.xml")/token-sets/token-set
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
                if (exists($token-sets)) then
                    <table class="table table-bordered">
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Airtable Username</th>
                                <th>Access Token</th>
                                <th>Notes</th>
                                <th>Date Created</th>
                                <th>Last Modified</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        {
                            for $token-set in $token-sets
                            return
                                <tr>
                                    <td>{$token-set/id/string()}</td>
                                    <td>{$token-set/username/string()}</td>
                                    <td>{$token-set/access-token/string()}</td>
                                    <td>{$token-set/notes/string()}</td>
                                    <td>{
                                        ($token-set/created-dateTime cast as xs:dateTime) 
                                            => format-dateTime("[MNn] [D], [Y] at [h]:[m01] [PN]")}</td>
                                    <td>{
                                        if ($token-set/last-modified-dateTime ne "") then
                                            ($token-set/last-modified-dateTime cast as xs:dateTime) 
                                                => format-dateTime("[MNn] [D], [Y] at [h]:[m01] [PN]")
                                        else 
                                            <em>No modifications</em>
                                    }</td>
                                    <td><a href="{$base-url}/tokens/{$token-set/id}">Edit</a></td>
                                </tr>
                        }
                    </table>
                else
                    <p>No tokens have been added.</p>
            }
            <h3>Add an Access Token</h3>
            <form method="POST" action="{$base-url}/tokens">
                <div class="mb-3">
                    <label for="username">Airtable Username:</label>
                    <input type="email" id="username" name="username" class="form-control" required="required" autofocus="autofocus"/>
                    <div class="form-text">The Airtable username associated with your access token. Rate limits are applied on the account level, and not per access token or per base.</div>
                </div>
                <div class="mb-3">
                    <label for="access-token">Access Token:</label>
                    <input type="text" id="access-token" name="access-token" class="form-control" required="required"/>
                    <div class="form-text">To create an access token, go to <a href="https://airtable.com/create/tokens" target="_blank">https://airtable.com/create/tokens</a> and select “Create new token.”</div>
                </div>
                <div class="mb-3">
                    <label for="notes">Notes:</label>
                    <textarea type="text" id="notes" name="notes" class="form-control" rows="3"/>
                    <div class="form-text">Any additional notes.</div>
                </div>
                <button class="btn btn-secondary" type="reset">Clear</button>
                <button class="btn btn-primary" type="submit">Store Access Token</button>
            </form>
        </div>
    return
        app:wrap($content, $title)
};
