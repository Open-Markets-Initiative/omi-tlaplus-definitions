----------- MODULE MiaxOptions_ComplexTopOfMarket_v1_1_Captures ------------
(***************************************************************************)
(* Recorded Miami International Holdings Complex Top Of Market v1.1        *)
(* packets, as the bytes they were captured as. Each one decodes, consumes *)
(* the whole packet, and encodes back to exactly the bytes it was read     *)
(* from.                                                                   *)
(***************************************************************************)
EXTENDS MiaxOptions_ComplexTopOfMarket_v1_1

HeartbeatCapture ==
    << 247, 4, 0, 0, 0, 0, 0, 0, 12, 0, 0, 1 >>

SystemStateMessageCapture ==
    << 214, 4, 0, 0, 0, 0, 0, 0, 30, 0, 3, 1, 83, 7, 84, 26,
       54, 67, 84, 79, 77, 49, 46, 48, 32, 1, 0, 0, 0, 49 >>

Captures == { HeartbeatCapture, SystemStateMessageCapture }

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
