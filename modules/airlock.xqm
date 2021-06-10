xquery version "3.1";

module namespace airlock="http://joewiz.org/ns/xquery/airlock";

import module namespace config="http://joewiz.org/ns/xquery/airlock/config" at "config.xqm";

declare function airlock:bases() as element(bases) { 
    doc($config:bases-doc)/bases
};

declare function airlock:base($base-id as xs:string) {
    doc($config:bases-doc)//base[id eq $base-id]
};

declare function airlock:snapshots($base-id as xs:string) as element(snapshots) {
    doc($config:bases-col || "/" || $base-id || "/" || $config:snapshots-doc-name)/snapshots
};

declare function airlock:snapshot($base-id as xs:string, $snapshot-id as xs:string) {
    doc($config:bases-col || "/" || $base-id || "/" || $config:snapshots-doc-name)//snapshot[id eq $snapshot-id]
};

declare function airlock:current-snapshot($base-id as xs:string) as element(snapshot)? {
    doc($config:bases-col || "/" || $base-id || "/" || $config:snapshots-doc-name)//snapshot[last()]
};
