----------------- MODULE Eurex_T7_Eti_v6_1_Server_Captures -----------------
(***************************************************************************)
(* Recorded Eurex Exchange Enhanced Trading Interface v6.1 packets, as the *)
(* bytes they were captured as. Each one decodes, consumes the whole       *)
(* packet, and encodes back to exactly the bytes it was read from.         *)
(***************************************************************************)
EXTENDS Eurex_T7_Eti_v6_1_Server

UserLoginResponseCapture ==
    << 32, 0, 0, 0, 35, 39, 0, 0, 53, 101, 20, 87, 157, 62, 97, 21,
       10, 1, 207, 88, 157, 62, 97, 21, 2, 0, 0, 0, 0, 0, 0, 0 >>

Captures == { UserLoginResponseCapture }

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
