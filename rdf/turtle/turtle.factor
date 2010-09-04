USING: accessors arrays assocs combinators
combinators.short-circuit formatting io io.streams.string
kernel math math.parser namespaces rdf rdf.common rdf.util
sequences strings ;
FROM: ascii => digit? ;
IN: rdf.turtle

SINGLETON: turtle

<PRIVATE

SINGLETONS: triple subject predicate
            directive collection blanknode ;

SYMBOL: turtle-parse-state 

: set-state ( state -- )
    turtle-parse-state set ; inline

: init-state ( -- )
    f turtle-parse-state set ; inline

TUPLE: turtle-context 
    prefixes base stack current triples lookahead ;

: <turtle-context> ( -- ctx )
    turtle-context new
    H{ } clone >>prefixes
    V{ } clone >>stack
    V{ } clone >>current
    V{ } clone >>triples ;

: ctx ( -- context )
    turtle-context get ;

: >lookahead ( char -- )
    dup whitespace? [ drop ] [
        [ ctx ] dip >>lookahead drop
    ] if ;

: lookahead? ( -- ? )
    ctx lookahead>> ;

: lookahead> ( -- seq )
    ctx [ lookahead>> ] [ f >>lookahead drop ] bi ;

: push-triple ( seq -- )
    ctx triples>> push ; 

: current>triples ( -- )
    ctx current>> >array push-triple ;

: reset-current ( -- )
    ctx current>> delete-all ; inline

: push-current ( value -- )
    ctx current>> push ;

: remember ( -- )
    ctx [ ] [ current>> ] [ stack>> ] tri
    push V{ } clone >>current drop ;

: recall ( -- )
    ctx [ ] [ stack>> pop ] bi >>current drop ;

HOOK: parse-turtle turtle-parse-state ( -- )

: ?skip-whitespace ( -- char )
    lookahead? [ lookahead> ] [
        read1 dup whitespace?
        [ drop ?skip-whitespace ] [  ] if
    ] if ; inline recursive

: read-prefix ( -- token )
    ":" cs-read-until drop ":" append ; inline

: check-prefix ( token -- token )
    dup { [ string? ] [ last CHAR: : = ] } 1&&
    [ ] [ "prefix not valid - %s" sprintf throw ] if ; inline

: add-prefix ( uri prefix -- )
    [ swap uriref>string <global-namespace> ] [ ] bi
    ctx prefixes>> set-at ; inline

: lookup-prefix ( prefix -- uri/f )
    ctx prefixes>> at ; inline

: set-base ( uri -- )
    [ ctx ] dip >>base drop ; inline

: (read-token) ( -- string )
    " \t\n;,." cs-read-until >lookahead ; inline

: read-qname ( char -- uriref )
    dup sequence? [ ] [ 1array ] if >string
    dup first CHAR: : = [  ] [ read-prefix append ] if
    dup lookup-prefix
    [
        nip [ uriref new ] dip >>ns
        (read-token) >>id
    ] [ "unregistered prefix - %s" sprintf throw ] if* ;

: read-uriref/qname ( char -- uriref )
    dup CHAR: < =
    [ drop read-uriref ] [ read-qname ] if ;

: read-typed-literal ( string -- typed-literal )
    read1 drop read1 read-uriref/qname <type-literal> ;

: read-literal ( -- literal )
    "\"" cs-read-until drop >string
    read1 dup CHAR: @ = [ drop (read-token) <lang-literal> ] [
        dup CHAR: ^ = [ drop read-typed-literal ]
        [ >lookahead <literal> ] if
    ] if ;

: read-number ( char -- number )
    1array (read-token) append dup string>number
    dup fixnum? [ drop "integer" xsd <type-literal> ] [
        dup float? [ drop "double" xsd <type-literal> ] [
            drop "decimal" xsd <type-literal>
        ] if
    ] if ;

HOOK: finish turtle-parse-state ( -- )

M: directive finish ( -- )
    f set-state ;

M: triple finish ( -- )
    current>triples reset-current f set-state ;

: continue ( -- )
    ?skip-whitespace
    {   
        { [ dup CHAR: . = ] [ drop finish parse-turtle ] }
        { [ dup CHAR: , = ] [ drop predicate set-state finish ] }
        { [ dup CHAR: ; = ] [ drop subject set-state finish ] } 
        { [ dup CHAR: ] = ] [ drop current>triples reset-current recall ] }
        [ drop ]
    } cond ; inline

DEFER: read-collection
DEFER: read-blank-node
DEFER: read-predicate

: (digit?) ( char -- ? )
    { [ digit? ] [ CHAR: + = ] [ CHAR: - = ] } 1|| ; inline

: (boolean?) ( char -- ? )
    { [ CHAR: t = ] [ CHAR: f = ] } 1|| ; inline

: read-boolean ( char -- boolean )
    1array (read-token) append
    dup { [ "true" = ] [ "false" = ] } 1||
    [ "boolean" xsd <type-literal> ]
    [ "expected boolean, got %s" sprintf throw ] if ; inline

: read-comment ( char -- )
    drop "\n\r" read-until 2drop ;

: (read-object) ( char -- object )
    {
        { [ dup CHAR: # = ] [ read-comment ?skip-whitespace (read-object) ] }
        { [ dup CHAR: " = ] [ drop read-literal ] }
        { [ dup (digit?) ] [ read-number ] }
        { [ dup CHAR: _ = ] [ drop read-bnode ] }
        { [ dup CHAR: ( = ] [ drop read-collection ] }
        { [ dup CHAR: [ = ] [ drop read-blank-node ] }
        { [ dup (boolean?) ] [ read-boolean ] }
        {
            [ dup { [ CHAR: , = ] [ CHAR: ; = ] [ CHAR: a = ] } 1|| ]
            [
                1array >string
                "Character not allowed in object definition - %s" sprintf throw
            ]
        }
        [ read-uriref/qname ]
    } cond ; inline recursive

: (read-predicate) ( char -- predicate )
    {
        { [ dup CHAR: [ = ] [ "predicate can not be blank" throw ] }
        {
            [ dup CHAR: a = ] [
                read1 dup { CHAR: space CHAR: \t } member?
                [ 2drop "type" rdf ] [ 2array read-qname ] if
            ]
        }
        [ read-uriref/qname ]
    } cond ;

: collection-end? ( -- char ? )
    ?skip-whitespace 
    dup CHAR: # = [ read-comment collection-end? ]
    [ dup CHAR: ) = ] if ; inline recursive

: read-collection-objects ( bnode char -- )
    dupd (read-object) [ "first" rdf ] dip 3array push-triple
    collection-end? [ drop "rest" rdf "nil" rdf 3array push-triple ] [
        [ "rest" rdf <bnode> [ 3array push-triple ] keep ] dip
        read-collection-objects
    ] if ;

: read-collection ( -- bnode )
    <bnode> dup collection-end? [ 3drop "nil" rdf ] [
        read-collection-objects
    ] if ;

: blank-node-end? ( -- char ? )
    ?skip-whitespace dup CHAR: ] = ;

: read-blank-node ( -- bnode )
    <bnode> dup blank-node-end? [ 2drop ] [ 
        [ remember push-current ] dip
        read-predicate
    ] if ;

: read-object ( char -- )
    (read-object) push-current triple set-state continue ;

: read-predicate ( char -- )
    (read-predicate) push-current ?skip-whitespace read-object ;
    
: read-subject ( char -- )
    dup CHAR: _ = [ drop read-bnode ] [
        dup CHAR: [ = [ drop read-blank-node ] [
            read-uriref/qname
        ] if
    ] if
    push-current ?skip-whitespace read-predicate ;

: keep-subject/predicate ( -- )
    2 ctx current>> shorten ;

: keep-subject ( -- )
    1 ctx current>> shorten ;

M: predicate finish ( -- )
    current>triples keep-subject/predicate
    ?skip-whitespace read-object ;

M: subject finish ( -- )
    current>triples keep-subject
    ?skip-whitespace dup CHAR: . = [
        drop reset-current f set-state parse-turtle
    ] [ read-predicate ] if ;

: parse-prefix ( -- uri prefix )
    (read-token) check-prefix
    [ ?skip-whitespace read-uriref/qname ] dip ; inline

: read-base/prefix ( -- )
    directive set-state
    " \t" read-until drop >string dup "prefix" = 
    [ drop parse-prefix add-prefix continue ] [ 
        dup "base" = [ drop read-uriref set-base ] [
            "unkown directive %s" sprintf throw
        ] if
    ] if ; inline

M: f parse-turtle ( -- )
    ?skip-whitespace
    dup CHAR: @ = [ drop read-base/prefix ] [ 
        dup CHAR: # = [ read-comment parse-turtle ] [  
            dup [ read-subject ] [ drop ] if
        ] if
    ] if ;

: read-turtle ( -- ctx )
    <turtle-context> dup turtle-context
    [ init-state parse-turtle ] with-variable ;

PRIVATE>

M: turtle import-triples ( string graph format -- graph )
    drop swap [ read-turtle ] with-string-reader
    [ triples>> [ add-triple-seq ] each ]
    [ prefixes>> [ dup prefixes>> ] dip assoc-union! >>prefixes ] bi ;

M: turtle mime-type drop "text/turtle" ;