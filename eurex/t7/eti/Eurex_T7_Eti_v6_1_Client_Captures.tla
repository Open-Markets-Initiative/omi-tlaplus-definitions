----------------- MODULE Eurex_T7_Eti_v6_1_Client_Captures -----------------
(***************************************************************************)
(* Recorded Eurex Exchange Enhanced Trading Interface v6.1 packets, as the *)
(* bytes they were captured as. Each one decodes, consumes the whole       *)
(* packet, and encodes back to exactly the bytes it was read from.         *)
(***************************************************************************)
EXTENDS Eurex_T7_Eti_v6_1_Client

HeartbeatCapture ==
    << 16, 0, 0, 0, 27, 39, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 >>

RetransmitMeMessageRequestCapture ==
    << 64, 0, 0, 0, 42, 39, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       3, 0, 0, 0, 225, 25, 0, 0, 255, 255, 255, 255, 2, 0, 4, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 >>

Captures == { HeartbeatCapture, RetransmitMeMessageRequestCapture }

(* Every recorded packet reads, reads whole, and writes back unchanged *)
CapturesRoundTrip ==
    \A bytes \in Captures :
        LET read == DecodeClientPacket(bytes)
        IN  /\ read.ok
            /\ read.rest = << >>
            /\ EncodeClientPacket(read.value) = bytes

(* Every recorded packet is bytes *)
CapturesAreBytes == \A bytes \in Captures : \A i \in 1 .. Len(bytes) : bytes[i] \in Byte

=============================================================================
