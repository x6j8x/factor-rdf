USING: arrays combinators combinators.short-circuit formatting
fry io io.encodings kernel math math.parser namespaces rdf
sequences strings ;
FROM: ascii => >upper ;
FROM: io.encodings.private => (read-until) ;
IN: rdf.util

SINGLETON: character-string

<PRIVATE

: quote-character ( char -- quoted )
    {
        { [ dup CHAR: \n = ] [ drop B{ CHAR: \ CHAR: n } ] }
        { [ dup CHAR: \t = ] [ drop B{ CHAR: \ CHAR: t } ] }
        { [ dup CHAR: \r = ] [ drop B{ CHAR: \ CHAR: r } ] }
        { [ dup CHAR: " = ] [ drop B{ CHAR: \ CHAR: " } ] }
        { [ dup CHAR: \ = ] [ drop B{ CHAR: \ CHAR: \ } ] }
        {
            [ dup { [ HEX: 7E > ] [ HEX: FFFF <= ] } 1&& ]
            [ [ BV{ CHAR: \ CHAR: u } clone ] dip >hex >upper append! ]
        } { 
            [ dup { [ HEX: 7E > ] [ HEX: FFFF <= ] } 1&& ]
            [ [ BV{ CHAR: \ CHAR: U } clone ] dip >hex >upper append! ]
        }
        [ 1array ]
    } cond ; inline

PRIVATE>

M: character-string encode-char ( char stream encoding -- )
    drop [ quote-character ] dip stream-write ;

<PRIVATE

: decode-quoted-char ( stream -- char )
    dup stream-read1
    {
        { [ dup CHAR: n = ] [ 2drop 10 ] }
        { [ dup CHAR: r = ] [ 2drop 13 ] }
        { [ dup CHAR: t = ] [ 2drop 9  ] }
        { [ dup CHAR: " = ] [ nip ] }
        { [ dup CHAR: \ = ] [ nip ] }
        { [ dup CHAR: u = ] [ drop 4 swap stream-read hex> ] }
        { [ dup CHAR: U = ] [ drop 8 swap stream-read hex> ] }
        [ nip ]
    } cond ; inline

: cs-decode-char ( stream -- char/f quoted? )
    dup stream-read1 dup CHAR: \ = 
    [ drop decode-quoted-char t ]
    [ nip f ] if ; inline

: empty/relative? ( string -- ? )
    { [ length 0 = ] [ CHAR: : swap member? not ] } 1|| ; inline

: make-uriref ( string -- uriref )
    [ ] [ empty/relative? ] bi [
        [ document-base get ] dip append
    ] [ ] if >string <uriref> ; inline

PRIVATE>

M: character-string decode-char ( stream encoding -- char/f )
    drop cs-decode-char drop ;

: cs-output ( -- encoder )
    output-stream get character-string re-encode ; inline

: cs-read-until ( sep -- string sep/f )
    [ input-stream get ] dip
    '[
        _ cs-decode-char over 
        [ [ f ] [ dup _ member? ] if ]
        [ 2drop f t ] if
    ] (read-until) ;

: whitespace? ( char -- ? )
    { CHAR: space CHAR: \t CHAR: \n CHAR: \r } member? ; inline

: read-uriref ( -- uri )
    "> \t" cs-read-until CHAR: > = [ make-uriref ] [
        "Invalid URIRef - %s" sprintf throw
    ] if ;

: read-bnode ( -- bnode )
    read1 drop " " cs-read-until drop <named-node> ;

