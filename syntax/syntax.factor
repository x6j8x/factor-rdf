USING: kernel lexer memoize parser rdf words accessors ;
IN: rdf.syntax

SYNTAX: RDF-NS: ( name uri-string -- word: ( id -- uri ) )
    CREATE-WORD dup name>> scan
    [ <global-namespace> [ uriref new ] 2dip [ >>id ] [ >>ns ] bi* ] curry curry
    (( id -- uri )) define-memoized ;
