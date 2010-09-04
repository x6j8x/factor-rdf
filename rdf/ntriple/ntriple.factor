USING: accessors arrays assocs byte-arrays combinators math math.parser
combinators.short-circuit io io.encodings io.streams.string
kernel namespaces peg peg.ebnf rdf rdf.util sequences strings ;
IN: rdf.ntriple

SINGLETON: ntriple

<PRIVATE

: ?skip-whitespace ( -- char )
    read1 dup whitespace?
    [ drop ?skip-whitespace ] [  ] if ; inline recursive

: read-literal ( -- literal )
    "\"" cs-read-until drop >string
    read1
    {
        { [ dup CHAR: @ = ] [ drop " ." cs-read-until drop >string <lang-literal> ] }
        { [ dup CHAR: ^ = ] [ drop 2 read drop read-uriref <type-literal> ] }
        [ drop <literal> ]
    } cond ;

: read-subject ( -- subject )
    ?skip-whitespace
    {
        { [ dup CHAR: < = ] [ drop read-uriref ] }
        { [ dup CHAR: _ = ] [ drop read-bnode ] }
        [ drop f ]
    } cond ;

: read-predicate ( -- predicate )
    ?skip-whitespace CHAR: < =
    [ read-uriref ] [ f ] if ;

: read-object ( -- object )
    ?skip-whitespace
    {
        { [ dup CHAR: < = ] [ drop read-uriref ] }
        { [ dup CHAR: _ = ] [ drop read-bnode ] }
        { [ dup CHAR: " = ] [ drop read-literal ] }
        [ drop f ]
    } cond ;

: (collect) ( acc value -- acc value )
    [ [ over push ] keep ] [ f ] if* ; inline

: read-ntriple ( line -- triple )
    [
        V{ } clone {
            [ read-subject (collect) ]
            [ read-predicate (collect) ]
            [ read-object (collect) ]
        } 0&&
        [ >array ] [ drop f ] if
    ] with-string-reader ; inline

: read-ntriples ( -- seq )
    V{ } clone [ read-ntriple [ over push ] when* ] each-line ;

GENERIC: write-ntriple-part ( object -- )

M: uriref write-ntriple-part ( object -- )
    CHAR: < write1 cs-output
    [ [ ns>> uri>> ] dip stream-write ]
    [ [ id>> ] dip stream-write ] 2bi
    B{ CHAR: > CHAR: space } write ;

M: bnode write-ntriple-part ( object -- )
    B{ CHAR: _ CHAR: : } write
    id>> >byte-array write
    CHAR: space write1 ;

: write-lang ( lang -- )
    CHAR: @ write1 >byte-array write ;

: write-type ( uriref -- )
    B{ CHAR: ^ CHAR: ^ } write write-ntriple-part ;

: write-string ( string -- )
    CHAR: " write1 cs-output stream-write CHAR: " write1 ; inline

M: literal write-ntriple-part ( object -- )
    [ value>> write-string ]
    [
        dup lang>>
        [ nip write-lang ]
        [ type>> [ write-type ] when* ] if*
    ] bi
    CHAR: space write1 ;

M: number write-ntriple-part ( object -- )
    number>string write-string CHAR: space write1 ;

: write-triple ( object predicate subject -- )
    [ write-ntriple-part ] tri@
    B{ CHAR: space CHAR: . CHAR: \n } write ; inline 

PRIVATE>

M: ntriple import-triples ( string graph format -- graph )
    drop swap [ read-ntriples ] with-string-reader
    [ add-triple-seq ] each ;

M: ntriple serialize-graph ( graph format -- )
    drop spo>>
    [ [ keys [ [ 2dup ] dip write-triple ] each drop ] assoc-each drop ] assoc-each ;

M: ntriple serialize-triples ( seq format -- )
    drop [ [ s>> ] [ p>> ] [ o>> ] tri write-triple ] each ;

M: ntriple mime-type drop "text/plain" ;
