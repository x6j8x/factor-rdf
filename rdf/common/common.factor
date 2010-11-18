USING: rdf.syntax accessors assocs splitting sequences kernel ;

IN: rdf.common

RDF-NS: cc      http://creativecommons.org/ns#
RDF-NS: dc      http://purl.org/dc/elements/1.1/
RDF-NS: fb      http://rdf.freebase.com/ns/
RDF-NS: mo      http://purl.org/ontology/mo/
RDF-NS: owl     http://www.w3.org/2002/07/owl#
RDF-NS: rdf     http://www.w3.org/1999/02/22-rdf-syntax-ns#
RDF-NS: xsd     http://www.w3.org/2001/XMLSchema#
RDF-NS: rdfs    http://www.w3.org/2000/01/rdf-schema#
RDF-NS: foaf    http://xmlns.com/foaf/0.1/


CONSTANT: rdf-uri-preferences H{ }

<PRIVATE

: normalize-uri ( uri -- string )
     "/" split [ first ] [ third ] bi
     [ "//" append ] dip 
     append "/" append ;

PRIVATE>

: add-uri-format ( format base-uri -- )
    normalize-uri rdf-uri-preferences set-at ;

FROM: rdf.n3 => n3 ;
FROM: rdf.ntriple => ntriple ;
n3 "http://dbpedia.org/" add-uri-format
ntriple "http://rdf.freebase.com/" add-uri-format

: uri-rdf-format ( string -- format )
    normalize-uri rdf-uri-preferences at ;