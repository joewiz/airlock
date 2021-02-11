xquery version "3.1";

module namespace app="http://joewiz.org/ns/xquery/airvac/app";

(: see browse.xq for where the color CSS classes are used :)
declare function app:wrap($content, $title) {
    <html lang="en">
        <head>
            <!-- Required meta tags -->
            <meta charset="utf-8"/>
            <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no"/>

            <!-- Bootstrap CSS -->
            <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css" integrity="sha384-Gn5384xqQ1aoWXA+058RXPxPg6fy4IWvTNh0E263XmFcJlSAwiGgFAW/dAiS6JXm" crossorigin="anonymous"/>

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
