xquery version "3.1";

module namespace app="http://joewiz.org/ns/xquery/airlock/app";

import module namespace config="http://joewiz.org/ns/xquery/airlock/config" at "config.xqm";

import module namespace login="http://exist-db.org/xquery/login" at "resource:org/exist/xquery/modules/persistentlogin/login.xql";

declare namespace sm="http://exist-db.org/xquery/securitymanager";

declare function app:login-form($request as map(*)) {
    let $base-url := $request?parameters?base-url
    let $title := "Log in"
    let $content :=
        <div>
            <h1>Airlock</h1>
            <nav aria-label="breadcrumb">
                <ol class="breadcrumb">
                    <li class="breadcrumb-item" aria-current="page"><a href="{$base-url}">Home</a></li>
                    <li class="breadcrumb-item active" aria-current="page">Log in</li>
                </ol>
            </nav>
            <h2>{$title}</h2>
            <form method="POST" class="form form-horizontal" action="{$base-url}/login">
                <div class="mb-3">
                    <label class="form-label" for="user">User:</label>
                    <input class="form-control" type="text" id="name" name="user" required="required" autofocus="autofocus"/>
                    <div class="form-text">User must be a member of the <code>airlock</code> group.</div>
                </div>
                <div class="mb-3">
                    <label class="form-label" for="password">Password:</label>
                    <input class="form-control" type="password" id="password" name="password"/>
                </div>
                <button class="btn btn-primary" type="submit">Login</button>
            </form>
            {
                if (sm:id()//sm:real/sm:groups/sm:group = config:repo-permissions()?group) then
                    <form method="POST" class="form form-horizontal" action="{$base-url}/login">
                        <input type="hidden" name="logout" value="true"/>
                        <button class="btn btn-secondary" href="{$base-url}/logout=true">Logout {sm:id()//sm:real/sm:username/string()}</button>
                    </form>
                else 
                    ()
            }
        </div>
    return
        app:wrap($content, $title)
};


(:~
 : Either login a user (if parameter `user` is specified) or check if the current user is logged in.
 : Setting parameter `logout` to any value will log out the current user.
 :
 : Copied and adapted from tei-publisher, I think?
 :)
declare function app:login($request as map(*)) {
    let $base-url := $request?parameters?base-url
    let $logout := $request?parameters?logout
    let $user := $request?parameters?user
    let $loginDomain := $config:login-domain
    return
        if ($logout) then
            (
                login:set-user($loginDomain, (), false()),
                let $title := "Success"
                let $content :=
                    <div class="alert alert-success" role="alert">
                        <h4 class="alert-heading">{$title}</h4>
                        <p>Successfully logged out</p>
                        <p><a href="{$base-url}">Return to Home</a></p>
                    </div>
                return
                    app:wrap($content, $title)
            )
        else if (sm:get-user-groups($user) = config:repo-permissions()?group) then
            (
                login:set-user($loginDomain, (), false()),
                let $user := request:get-attribute($loginDomain || ".user")
                return
                    if (exists($user)) then
                        let $title := "Success"
                        let $content :=
                            <div class="alert alert-success" role="alert">
                                <h4 class="alert-heading">{$title}</h4>
                                <p>Successfully logged in</p>
                                <p><a href="{$base-url}">Return to Home</a></p>
                            </div>
                        return
                            app:wrap($content, $title)
                    else
                        let $title := "Login failed"
                        let $content :=
                            <div class="alert alert-success" role="alert">
                                <h4 class="alert-heading">{$title}</h4>
                                <p>Incorrect username or password</p>
                                <p><a href="{$base-url}">Return to Home</a></p>
                            </div>
                        return
                            app:wrap($content, $title)
            )
        else
            let $title := "Login failed"
            let $content :=
                <div class="alert alert-success" role="alert">
                    <h4 class="alert-heading">{$title}</h4>
                    <p>User does not belong to the <code>{config:repo-permissions()?group}</code> group.</p>
                    <p><a href="{$base-url}">Return to Home</a></p>
                </div>
            return
                app:wrap($content, $title)
};

(: see browse.xq for where the color CSS classes are used :)
declare function app:wrap($content, $title) {
    <html lang="en">
        <head>
            <!-- Required meta tags -->
            <meta charset="utf-8"/>
            <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no"/>

            <!-- Bootstrap CSS -->
            <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.0-beta2/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-BmbxuPwQa2lc/FVzBcNJ7UAyJxM6wuqIj61tLrc4wSX0szH/Ev+nYRRuWlolflfl" crossorigin="anonymous"/>

            <style>{``[
                body { font-family: HelveticaNeue, Helvetica, Arial, sans; }
                .highlight { background-color: yellow }
                .tag { color: green }
                tr { page-break-inside: avoid; }
                td { vertical-align: top; }
                a[href].external:after { content: " ⤤" ; text-decoration: none; display: inline-block; padding-left: .3em }
                
                /* Classes used in Airtable's CSS color picker */
                .blue, .blueBright { background-color:#2d7ff9 } 
                .blueDark1 { background-color:#2750ae } 
                .blueLight1 { background-color:#9cc7ff } 
                .blueLight2 { background-color:#cfdfff } 
                .cyan, .cyanBright { background-color:#18bfff } 
                .cyanDark1 { background-color:#0b76b7 } 
                .cyanLight1 { background-color:#77d1f3 } 
                .cyanLight2 { background-color:#d0f0fd } 
                .gray, .grayBright { background-color:#666 } 
                .grayDark1 { background-color:#444 } 
                .grayLight1 { background-color:#ccc } 
                .grayLight2 { background-color:#eee } 
                .green, .greenBright, .greenDark { background-color:#20c933 } 
                .greenDark1 { background-color:#338a17 } 
                .greenLight1 { background-color:#93e088 } 
                .greenLight2 { background-color:#d1f7c4 } 
                .orange, .orangeBright { background-color:#ff6f2c } 
                .orangeDark1 { background-color:#d74d26 } 
                .orangeLight1 { background-color:#ffa981 } 
                .orangeLight2 { background-color:#fee2d5 } 
                .pink, .pinkBright, .pinkDark { background-color:#ff08c2 } 
                .pinkDark1 { background-color:#b2158b } 
                .pinkLight1 { background-color:#f99de2 } 
                .pinkLight2 { background-color:#ffdaf6 } 
                .purple, .purpleBright { background-color:#8b46ff } 
                .purpleDark1 { background-color:#6b1cb0 } 
                .purpleLight1 { background-color:#cdb0ff } 
                .purpleLight2 { background-color:#ede2fe } 
                .red, .redBright, .redDarker { background-color:#f82b60 } 
                .redDark1 { background-color:#ba1e45 } 
                .redLight1 { background-color:#ff9eb7 } 
                .redLight2 { background-color:#ffdce5 } 
                .teal, .tealBright { background-color:#20d9d2 } 
                .tealDark1 { background-color:#06a09b } 
                .tealLight1 { background-color:#72ddc3 } 
                .tealLight2 { background-color:#c2f5e9 } 
                .yellow, .yellowBright, .yellowDark { background-color:#fcb400 } 
                .yellowDark1 { background-color:#b87503 } 
                .yellowLight1 { background-color:#ffd66e } 
                .yellowLight2 { background-color:#ffeab6 } 
                
                .text-blue-dark1 { color:#102046 } 
                .text-blue-light2 { color:#cfdfff } 
                .text-cyan-dark1 { color:#04283f } 
                .text-cyan-light2 { color:#d0f0fd } 
                .text-gray-dark1 { color:#040404 } 
                .text-gray-light2 { color:#eee } 
                .text-green-dark1 { color:#0b1d05 } 
                .text-green-light2 { color:#d1f7c4 } 
                .text-orange-dark1 { color:#6b2613 } 
                .text-orange-light2 { color:#fee2d5 } 
                .text-pink-dark1 { color:#400832 } 
                .text-pink-light2 { color:#ffdaf6 } 
                .text-purple-dark1 { color:#280b42 } 
                .text-purple-light2 { color:#ede2fe } 
                .text-red-dark1 { color:#4c0c1c } 
                .text-red-light2 { color:#ffdce5 } 
                .text-teal-dark1 { color:#012524 } 
                .text-teal-light2 { color:#c2f5e9 } 
                .text-white { color:#fff } 
                .text-yellow-dark1 { color:#3b2501 } 
                .text-yellow-light2 { color:#ffeab6 }

            ]``}</style>
            <style media="print">{``[
                a, a:visited { text-decoration: underline; color: #428bca; }
                a[href]:after { content: ""; }
            ]``}</style>
            <title>{ $title }</title>
        </head>
        <body>
            <div class="container-fluid">
                { $content }
            </div>
        </body>
    </html>
};
