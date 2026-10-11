-------- MODULE ByxEquities_MulticastDepthOfBook_v2_41_29_Captures ---------
(***************************************************************************)
(* Recorded Chicago Board Options Exchange Multicast Depth Of Book         *)
(* v2.41.29 packets, as the bytes they were captured as. Each one decodes, *)
(* consumes the whole packet, and encodes back to exactly the bytes it was *)
(* read from.                                                              *)
(***************************************************************************)
EXTENDS ByxEquities_MulticastDepthOfBook_v2_41_29

AddOrderShortMessageCapture1 ==
    << 34, 0, 1, 17, 179, 54, 0, 0, 26, 34, 72, 190, 154, 59, 240, 119,
       79, 106, 38, 25, 114, 31, 66, 144, 1, 77, 65, 84, 32, 32, 32, 18,
       8, 1 >>

AddOrderShortMessageCapture2 ==
    << 40, 0, 2, 15, 74, 186, 0, 0, 6, 32, 152, 133, 0, 0, 26, 34,
       112, 219, 9, 0, 21, 204, 203, 93, 170, 222, 202, 27, 66, 196, 84, 74,
       68, 83, 84, 32, 32, 244, 2, 1 >>

AddOrderShortMessageCapture3 ==
    << 34, 0, 1, 15, 76, 186, 0, 0, 26, 34, 208, 72, 10, 0, 23, 204,
       203, 93, 170, 222, 202, 27, 66, 200, 0, 73, 88, 78, 32, 32, 32, 102,
       23, 1 >>

AddOrderShortMessageCapture4 ==
    << 60, 0, 2, 15, 77, 186, 0, 0, 26, 34, 184, 195, 11, 0, 27, 204,
       203, 93, 170, 222, 202, 27, 83, 100, 0, 73, 87, 79, 32, 32, 32, 230,
       91, 1, 26, 34, 40, 219, 11, 0, 28, 204, 203, 93, 170, 222, 202, 27,
       66, 100, 0, 73, 87, 79, 32, 32, 32, 118, 91, 1 >>

AddOrderShortMessageCapture5 ==
    << 66, 0, 3, 31, 158, 139, 0, 0, 6, 32, 152, 133, 0, 0, 26, 34,
       80, 129, 11, 0, 217, 194, 205, 193, 138, 178, 4, 57, 66, 8, 32, 89,
       65, 78, 71, 32, 32, 109, 4, 1, 26, 34, 160, 199, 11, 0, 218, 194,
       205, 193, 138, 178, 4, 57, 66, 100, 0, 88, 83, 86, 78, 32, 32, 59,
       18, 1 >>

ModifyOrderShortMessageCapture ==
    << 27, 0, 1, 11, 243, 219, 1, 0, 19, 40, 72, 13, 200, 25, 151, 237,
       204, 68, 178, 105, 124, 20, 100, 0, 227, 10, 1 >>

Captures == { AddOrderShortMessageCapture1, AddOrderShortMessageCapture2, AddOrderShortMessageCapture3, AddOrderShortMessageCapture4, AddOrderShortMessageCapture5, ModifyOrderShortMessageCapture }

(* Every recorded packet reads, reads whole, and writes back unchanged *)
CapturesRoundTrip ==
    \A bytes \in Captures :
        LET read == DecodePacket(bytes)
        IN  /\ read.ok
            /\ read.rest = << >>
            /\ EncodePacket(read.value) = bytes

(* Every recorded packet is bytes *)
CapturesAreBytes == \A bytes \in Captures : \A i \in 1 .. Len(bytes) : bytes[i] \in Byte

=============================================================================
