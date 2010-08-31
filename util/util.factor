USING: arrays combinators combinators.short-circuit io
io.encodings kernel math math.parser namespaces sequences ;
FROM: ascii => >upper ;
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
        { [ dup CHAR: " = ] [ nip  ] }
        { [ dup CHAR: \ = ] [ nip  ] }
        { [ dup CHAR: u = ] [ drop 4 swap stream-read hex> ] }
        { [ dup CHAR: U = ] [ drop 8 swap stream-read hex> ] }
        [ nip ]
    } cond ; inline

PRIVATE>

M: character-string decode-char ( stream encoding -- char/f )
    drop dup stream-read1 dup CHAR: \ = 
    [ drop decode-quoted-char ]
    [ nip ] if ;

: cs-output ( -- encoder )
    output-stream get character-string re-encode ; inline