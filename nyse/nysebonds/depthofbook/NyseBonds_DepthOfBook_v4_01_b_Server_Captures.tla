----------- MODULE NyseBonds_DepthOfBook_v4_01_b_Server_Captures -----------
(***************************************************************************)
(* Recorded New York Stock Exchange DepthOfBook v4.01.b packets, as the    *)
(* bytes they were captured as. Each one decodes, consumes the whole       *)
(* packet, and encodes back to exactly the bytes it was read from.         *)
(***************************************************************************)
EXTENDS NyseBonds_DepthOfBook_v4_01_b_Server

AddOrderMessageCapture ==
    << 0, 76, 78, 0, 3, 31, 70, 73, 0, 0, 226, 165, 0, 107, 65, 23,
       0, 0, 0, 130, 0, 0, 38, 172, 50, 32, 70, 66, 0, 0, 1, 0,
       70, 47, 50, 53, 65, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 51, 52, 53, 51, 57, 55, 88, 76, 50, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 >>

DeleteOrderMessageCapture ==
    << 0, 60, 75, 0, 3, 31, 101, 57, 0, 0, 226, 196, 0, 107, 65, 47,
       32, 70, 83, 0, 0, 1, 0, 76, 76, 76, 47, 50, 49, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 53, 48, 50,
       52, 49, 51, 66, 65, 52, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 >>

Captures == { AddOrderMessageCapture, DeleteOrderMessageCapture }

(* Every recorded packet reads, reads whole, and writes back unchanged *)
CapturesRoundTrip ==
    \A bytes \in Captures :
        LET read == DecodeServerPacket(bytes)
        IN  /\ read.ok
            /\ read.rest = << >>
            /\ EncodeServerPacket(read.value) = bytes

(* Every recorded packet is bytes *)
CapturesAreBytes == \A bytes \in Captures : \A i \in 1 .. Len(bytes) : bytes[i] \in Byte

=============================================================================
