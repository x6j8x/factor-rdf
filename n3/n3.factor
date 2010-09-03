USING: kernel rdf rdf.turtle ;

IN: rdf.n3

SINGLETON: n3

M: n3 import-triples ( string graph format -- graph )
    drop turtle import-triples ;

M: n3 mime-type drop "text/n3" ;