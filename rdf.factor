USING: accessors arrays assocs fry generalizations hashtables
io.streams.string kernel math.parser memoize namespaces
sequences sequences.private splitting strings ;
FROM: vocabs.loader => require ;
IN: rdf

TUPLE: subject { predicates hashtable } ;

TUPLE: namespace prefix { uri string } ;

TUPLE: uriref { ns namespace } id ;

TUPLE: bnode id ;

TUPLE: literal value lang type ;

<PRIVATE

SYMBOL: rdf-namespaces

: (<namespace>) ( prefix uri -- ns )
    [ namespace new ] 2dip
    [ >>prefix ] [ >>uri ] bi* ;

: namespaces ( -- map )
    rdf-namespaces get-global
    [ H{ } clone [ rdf-namespaces set-global ] [  ] bi ] unless* ; inline
    
: register-namespace ( ns -- )
    [  ] [ uri>> ] bi namespaces set-at ; inline

: make-namespace ( prefix uri -- ns ? )
    dup namespaces at
    [ 2nip t ] [ (<namespace>) f ] if* ;

PRIVATE>

: <global-namespace> ( prefix uri -- ns )
    make-namespace [ [ register-namespace ] [  ] bi ] unless ;

: <namespace> ( uri -- ns )
    [ f ] dip make-namespace drop ;

<PRIVATE
    
: (<uriref>) ( string string -- uri )
    [ uriref new ] 2dip
    [ <namespace> >>ns ] [ >>id ] bi* ;

: make-uriref ( string string quot -- uri )
    [
        [ split1-last ] [  ] bi
        '[ [ _ append ] dip (<uriref>) ]
    ] dip '[ _ call( string -- uri ) ] if* ; inline

PRIVATE>

MEMO: <uriref> ( string -- uri )
    "#" [ "/" [ drop f ] make-uriref ] make-uriref ;

MEMO: <bnode> ( string -- bnode )
    [ bnode new ] dip >>id ;

: <literal> ( string -- literal )
    [ literal new ] dip >>value ;

: <lang-literal> ( string lang -- literal )
    [ literal new ] 2dip
    [ >>value ] [ >>lang ] bi* ;

: <type-literal> ( string uri -- literal )
    [ literal new ] 2dip
    [ >>value ] [ >>type ] bi* ;

: uri>string ( uri -- string )
    ;

TUPLE: graph { objects hashtable } ;

: <graph> ( -- graph )
    H{ } clone graph boa ;

GENERIC: import-triples ( string graph format -- graph )

GENERIC: serialize-graph ( graph format -- )

: graph>string ( graph format -- str )
    [ serialize-graph ] with-string-writer ;

<PRIVATE

: deep-set ( value deep-key key ht -- )
    [ [ H{ } clone ] unless* [ push-at ] keep ] change-at ;
    
PRIVATE>

: add-triple-seq ( graph triple -- graph )
    over [ reverse first3 ] dip objects>> deep-set ;

: add-triple ( graph object predicate subject -- graph )
    3array add-triple-seq ;

"rdf.ntriple" require
"rdf.syntax" require
"rdf.common" require
