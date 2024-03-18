xquery version "3.1";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

declare variable $base-url := request:get-context-path() || $exist:prefix || $exist:controller;

(: redirect requests for app root "" to "/" :)
if ($exist:path eq "") then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{request:get-uri()}/"/>
    </dispatch>

(: all other requests are passed on the Open API router :)
else
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{
            (: login.xq runs as dba since it needs to check group :)
            if ($exist:path eq "/login") then
                $exist:controller || "/modules/login.xq"
            else
                $exist:controller || "/modules/api.xq"
            }">
            <set-header name="Access-Control-Allow-Origin" value="*"/>
            <set-header name="Access-Control-Allow-Credentials" value="true"/>
            <set-header name="Access-Control-Allow-Methods" value="GET, POST, DELETE, PUT, PATCH, OPTIONS"/>
            <set-header name="Access-Control-Allow-Headers" value="Accept, Content-Type, Authorization, X-Start"/>
            <set-header name="Cache-Control" value="no-cache"/>
            <add-parameter name="base-url" value="{$base-url}"/>
        </forward>
    </dispatch>