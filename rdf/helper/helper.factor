USING: accessors arrays assocs fry generalizations kernel
locals namespaces rdf sequences slots strings ;
IN: rdf.helper 

: ensure-ht ( ht/f -- ht )
    [ H{ } clone ] unless* ; inline

: (index-insert) ( triple key3 key2 key ht -- )
    [ ensure-ht [ [ ensure-ht [ set-at ] keep ] change-at ] keep ] change-at ;

: <triple-reader> ( char -- quot )
    1array >string reader-word '[ _ execute ] ;

: <triple-setter> ( char -- quot )
    1array >string setter-word '[ _ execute ] ;

: [triple-extractor] ( pos-string -- quot )
    reverse [ <triple-reader> ] { } map-as first3
    [ tri ] 3curry ;

: [index-inserter] ( pos-string -- quot )
    reader-word '[ _ execute (index-insert) ] ;

: [insert-prepare] ( quot -- quot )
    '[ _ pick [ call ] dip ] ;

<PRIVATE

: stage-3 ( acc key3 ht -- acc )
    over [ at [ suffix! ] when* ] [
        nip values append!
    ] if ; inline

: stage-2 ( acc key3 key2 ht -- acc )
    over [ at [ stage-3 ] [ drop ] if* ] [
        nip values [ [ 2dup ] dip stage-3 drop ] each drop
    ] if ; inline

: stage-1 ( acc key3 key2 key ht -- acc )
    at [ stage-2 ] [ 2drop ] if* ; inline

PRIVATE>

: [locator] ( -- quot )
    [ [ V{ } clone ] 4 ndip stage-1 >array ] ;
