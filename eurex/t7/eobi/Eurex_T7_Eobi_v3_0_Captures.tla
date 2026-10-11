-------------------- MODULE Eurex_T7_Eobi_v3_0_Captures --------------------
(***************************************************************************)
(* Recorded Eurex Exchange Enhanced Order Book Interface v3.0 packets, as  *)
(* the bytes they were captured as. Each one decodes, consumes the whole   *)
(* packet, and encodes back to exactly the bytes it was read from.         *)
(***************************************************************************)
EXTENDS Eurex_T7_Eobi_v3_0

HeartbeatCapture ==
    << 32, 0, 204, 50, 255, 255, 255, 255, 226, 63, 18, 0, 26, 28, 0, 0,
       6, 1, 0, 0, 0, 0, 0, 0, 130, 234, 147, 221, 169, 48, 81, 20,
       16, 0, 201, 50, 255, 255, 255, 255, 94, 12, 0, 0, 0, 0, 0, 0 >>

OrderAddCapture ==
    << 32, 0, 204, 50, 255, 255, 255, 255, 161, 169, 27, 0, 163, 2, 0, 0,
       3, 1, 0, 0, 0, 0, 0, 0, 199, 205, 123, 229, 155, 48, 81, 20,
       48, 0, 44, 51, 200, 22, 29, 0, 34, 132, 122, 229, 155, 48, 81, 20,
       39, 156, 21, 0, 0, 0, 0, 0, 190, 202, 122, 229, 155, 48, 81, 20,
       4, 0, 0, 0, 1, 0, 0, 0, 0, 197, 172, 234, 67, 0, 0, 0 >>

SnapshotOrderCapture ==
    << 32, 0, 204, 50, 255, 255, 255, 255, 6, 162, 7, 0, 179, 2, 0, 0,
       6, 1, 0, 0, 0, 0, 0, 0, 153, 136, 178, 63, 167, 48, 81, 20,
       32, 0, 34, 53, 60, 14, 0, 0, 86, 226, 149, 88, 98, 27, 81, 20,
       5, 0, 0, 0, 1, 0, 0, 0, 128, 87, 237, 254, 255, 255, 255, 255 >>

Captures == { HeartbeatCapture, OrderAddCapture, SnapshotOrderCapture }

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
