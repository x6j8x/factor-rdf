USING: alien.c-types byte-arrays checksums io.binary kernel
math math.bitwise sequences specialized-arrays typed ;
IN: checksums.murmur2

SINGLETON: murmur2

<PRIVATE

CONSTANT: m HEX: 5bd1e995
CONSTANT: r -24
CONSTANT: seed HEX: 12f1a3cf

SPECIALIZED-ARRAY: uint 

TYPED: do-chksum ( bytes: byte-array -- value: byte-array )
    [ length seed swap bitxor ]
    [ dup length 4 /mod 0 > [ 1 + ] when <direct-uint-array> ] bi
    [ m w* dup r shift bitxor m w* [ m w* ] dip bitxor ] each
    dup -13 shift bitxor m w* dup -15 shift bitxor 
    4 >le ; inline

PRIVATE>

M: murmur2 checksum-bytes ( bytes checksum -- value )
    drop do-chksum ;

