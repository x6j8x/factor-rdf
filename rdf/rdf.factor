USING: accessors arrays assocs combinators fry generalizations
hashtables http http.client io.streams.string kernel locals
macros math math.parser memoize namespaces rdf.helper sequences
sequences.private slots splitting strings ;
FROM: vocabs.loader => require ;
IN: rdf

TUPLE: subject { predicates hashtable } ;

TUPLE: namespace prefix { uri string } ;

TUPLE: uriref { ns namespace } id ;

TUPLE: bnode id ;

TUPLE: literal value lang type ;

SYMBOL: document-base

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

: uriref>string ( ref -- string )
    [ ns>> uri>> ] [ id>> ] bi append ;

MEMO: <named-node> ( string -- bnode )
    [ bnode new ] dip >>id ;

: <bnode> ( -- bnode )
    "node" bnode counter
    number>string append
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

TUPLE: graph
    { namespaces hashtable }
    { prefixes hashtable }
    { spo hashtable }
    { pos hashtable }
    { osp hashtable } ;

TUPLE: triple s p o ;

M: triple like ( seq exemplar -- newseq )
    over triple? [ drop clone ] [
        clone [ [ 0 ] dip copy ] keep
    ] if ;

M: triple new-sequence ( length triple -- triple )
    2drop triple new ;

M: triple nth-unsafe ( n triple -- object )
    {
        { [ over 0 = ] [ nip s>> ] }
        { [ over 1 = ] [ nip p>> ] }
        { [ over 2 = ] [ nip o>> ] }
    } cond ;

M: triple nth ( n triple -- object )
    over 2 > [ bounds-error ] when
    nth-unsafe ;

M: triple set-nth-unsafe ( elt n triple -- )
    {
        { [ over 0 = ] [ nip swap >>s drop ] }
        { [ over 1 = ] [ nip swap >>p drop ] }
        { [ over 2 = ] [ nip swap >>o drop ] }    
    } cond ;

M: triple set-nth ( elt n triple -- )
    over 2 > [ bounds-error ] when
    set-nth-unsafe ;

M: triple length ( triple -- n )
    drop 3 ;

M: triple lengthen ( n seq -- )
    over 3 > [ bounds-error ] when 2drop ;

: <triple> ( s p o -- triple )
    [ triple new ] 3dip 
    [ >>s ] [ >>p ] [ >>o ] tri* ; inline

<PRIVATE

CONSTANT: triple-exemplar T{ triple f f f f }

PRIVATE>

: seq>triple ( seq -- triple )
    triple-exemplar like ; inline

: <graph> ( -- graph )
    graph new
    H{ } clone >>namespaces
    H{ } clone >>prefixes
    H{ } clone >>spo
    H{ } clone >>pos
    H{ } clone >>osp ;

GENERIC: import-triples ( string graph format -- graph )

GENERIC: serialize-graph ( graph format -- )

GENERIC: serialize-triples ( seq format -- )

: base-import-triples ( base string graph format -- graph )
    [ import-triples ] 3curry [ document-base ] dip with-variable ;

: graph>string ( graph format -- str )
    [ serialize-graph ] with-string-writer ;

: triples>string ( seq format -- str )
    [ serialize-triples ] with-string-writer ;

<PRIVATE

MACRO: >index ( pos-string -- )
    [
        [ [ dup ] ] dip
        [triple-extractor] compose
        [insert-prepare]
    ] [ [index-inserter] ] bi compose ;

PRIVATE>

: add-triple ( graph triple -- graph )
    [ "spo" >index ] [ "pos" >index ] [ "osp" >index ] tri ; inline

: add-triple-seq ( graph triple -- graph )
    seq>triple add-triple ;

GENERIC: mime-type ( format -- mime-type )

USING: http http.client ;

<PRIVATE

: >accept ( request format -- request )
    mime-type "Accept" set-header ;

PRIVATE>

: load-graph ( url format -- graph )
    2dup [ <get-request> ] dip >accept http-request
    swap code>> 200 = [
        [ <uriref> ns>> uri>> ] 2dip
        swap [ <graph> ] dip base-import-triples
    ] [ "http error" throw ] if ;

: load-graph-deep ( url format depth -- graph )
    2over load-graph [ 3drop ] dip ;

: merge-graphs ( g1 g2 -- graph )
    [ <graph> ] 2dip
    {
        [ [ spo>> ] bi@ assoc-union >>spo ]
        [ [ pos>> ] bi@ assoc-union >>pos ]
        [ [ osp>> ] bi@ assoc-union >>osp ]    
    } 2cleave ;

:: graph>triples ( graph -- seq )
    V{ } clone :> acc
    graph spo>>
    [ [ keys [ [ 2dup ] dip <triple> acc push ] each drop ] assoc-each drop ] assoc-each
    acc ;

<PRIVATE

MACRO: find-triples ( pos-string -- )
    [ [ swap ] ] dip
    [ [triple-extractor] ]
    [ reader-word '[ _ execute ] ] bi
    '[ @ _ _ bi* ] [locator] compose ;

PRIVATE>

: triples ( graph triple -- seq )
    {
        { [ dup s>> ] [ "spo" find-triples ] }
        { [ dup p>> ] [ "pos" find-triples ] }
        { [ dup o>> ] [ "osp" find-triples ] }
        [ drop graph>triples ]
    } cond ; inline

: seq>triples ( graph seq -- seq )
    seq>triple triples ; inline

"rdf.syntax"    require
"rdf.common"    require
"rdf.ntriple"   require
"rdf.turtle"    require
"rdf.n3"        require

