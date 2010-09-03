USING: arrays assocs fry kernel rdf sequences slots strings locals ;
IN: rdf.helper 

: ensure-ht ( ht/f -- ht )
    [ H{ } clone ] unless* ; inline

: set-1 ( key ht -- ht )
    [ 1 ] 2dip [ set-at ] keep ; inline

: (index-insert) ( key3 key2 key ht -- )
    [ ensure-ht [ [ ensure-ht set-1 ] change-at ] keep ] change-at ;

: <triple-reader> ( char -- quot )
    1array >string reader-word '[ _ execute ] ;

: <triple-setter> ( char -- quot )
    1array >string setter-word '[ _ execute ] ;

: [triple-extractor] ( pos-string -- quot )
    [ <triple-reader> ] { } map-as first3 [ tri ] 3curry ;

: [index-inserter] ( pos-string -- quot )
    reader-word '[ _ execute (index-insert) ] ;

: [insert-prepare] ( quot -- quot )
    '[ _ pick [ call ] dip ] ;

IN: rdf

DEFER: triple

IN: rdf.helper

: [triple-constructor] ( pos-string -- quot )
    [ [ [ triple new ] 3dip ] ] dip
    [ <triple-setter> ] { } map-as 
    first3 [ tri* ] 3curry compose ;

<PRIVATE

: >result ( o o o c a -- )
    [ call( o o o -- t ) ] [ push ] bi* ; inline

PRIVATE>

:: [locator] ( constructor -- quot )
    [
        :> 3rd :> 2nd :> 1st :> ht V{ } clone :> acc
        1st ht at [
            2nd [
                [ 2nd ] dip at [
                    3rd [
                        [ 3rd ] dip at [ drop 1st 2nd 3rd constructor acc >result ] when*
                    ] [ 
                        keys [ [ 1st 2nd ] dip constructor acc >result ] each
                    ] if
                ] when* 
            ] [
                [
                    :> tmp-value :> tmp-key
                    3rd [ 
                        3rd tmp-value at [ 1st tmp-key 3rd constructor acc >result ] when
                    ] [
                        tmp-value keys [ [ 1st tmp-key ] dip constructor acc >result ] each
                    ] if
                ] assoc-each
            ] if
        ] when*
        acc
    ] ;