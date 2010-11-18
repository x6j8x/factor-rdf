USING: namespaces biassocs rdf.store kernel mongodb.driver mongodb.cmd 
assocs ;

IN: rdf.store.mongodb

TUPLE: mongodb-rdf-store mdbpool ;

SYMBOLS: namespace-map verb-map ;

namespace-map [ <bihash> ] initialize
verb-map [ <bihash> ] initialize

: ns-map ( -- map )
    namespace-map get-global ;

: v-map ( -- map )
    verb-map get-global ;

CONSTANT: get-key-query 
    H{
        { "query" H{ { "_id" "ns-key" } } }
        { "update" H{ { "$inc" H{ { "counter" 1 } } } } }
        { "upsert" t }
        { "new" t }
    }

: get-key ( string -- key )
    findandmodify-cmd make-cmd
    [ assoc>> get-key-query assoc-union! drop ] keep
    run-cmd "counter" swap at ;

: query-key ( string -- key/? )
    ;

: insert-key ( string key -- key )
    [
        <bihash>
        [ set-at ] [
            [ from>> ] [ to>> ] bi assoc-union!
            [ "ns-map" ] dip save
        ]
    ] [ ] bi ;

: >integer-key ( string -- key )
    dup namespace-map at
    [ nip ] [
        dup query-key
        [ swap dupd namespace-map set-at ] [
            get-key insert-key 
        ] if*
    ] if* ; 

: encode-partial ( uriref -- encoded )
    [ ns>> uri>> >integer-key ]

M: mongodb-rdf-store add-triple ( store triple -- )
    2drop ;