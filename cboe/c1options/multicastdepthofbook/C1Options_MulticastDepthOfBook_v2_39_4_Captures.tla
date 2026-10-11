---------- MODULE C1Options_MulticastDepthOfBook_v2_39_4_Captures ----------
(***************************************************************************)
(* Recorded Chicago Board Options Exchange Multicast Depth Of Book v2.39.4 *)
(* packets, as the bytes they were captured as. Each one decodes, consumes *)
(* the whole packet, and encodes back to exactly the bytes it was read     *)
(* from.                                                                   *)
(***************************************************************************)
EXTENDS C1Options_MulticastDepthOfBook_v2_39_4

AddOrderLongMessageCapture ==
    << 48, 0, 2, 1, 37, 0, 0, 0, 6, 32, 62, 42, 1, 0, 34, 33,
       192, 204, 43, 21, 20, 16, 116, 233, 234, 158, 104, 3, 66, 232, 3, 0,
       0, 65, 32, 32, 32, 32, 32, 29, 0, 0, 0, 0, 0, 0, 0, 1 >>

DeleteOrderMessageCapture ==
    << 28, 0, 2, 1, 41, 0, 0, 0, 6, 32, 102, 42, 1, 0, 14, 41,
       176, 192, 70, 47, 20, 16, 116, 233, 234, 158, 104, 3 >>

HeartbeatCapture ==
    << 8, 0, 0, 1, 1, 0, 0, 0 >>

ModifyOrderLongMessageCapture ==
    << 41, 0, 2, 1, 27, 0, 0, 0, 6, 32, 221, 41, 1, 0, 27, 39,
       128, 21, 175, 31, 18, 16, 116, 233, 234, 158, 104, 3, 232, 3, 0, 0,
       26, 0, 0, 0, 0, 0, 0, 0, 1 >>

Captures == { AddOrderLongMessageCapture, DeleteOrderMessageCapture, HeartbeatCapture, ModifyOrderLongMessageCapture }

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
