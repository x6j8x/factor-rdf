
IN: rdf.store.tokyo


TUPLE: tokyo-store tdb ;

! Ideas:
! Layout
! ------
! string -> int ; int -> string => hashdb
! spo, pos, osp => btree+
! 
! Performance:
! cache predicate uri -> id, id -> uri mapping
! 


M: tokyo-store add-triple ( store triple -- )
    2drop ;

M: tokyo-store add-triples ( store seq -- )
    2drop ;

M: tokyo-store remove-triple ( store triple -- )
    2drop ;

M: tokyo-store remove-triples ( store seq -- )
    2drop ;