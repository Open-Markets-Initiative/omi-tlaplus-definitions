-------------- MODULE C1Options_MarketLevel2_v1_0_4_Captures ---------------
(***************************************************************************)
(* Recorded Chicago Board Options Exchange Market Level 2 Feed v1.0.4      *)
(* packets, as the bytes they were captured as. Each one decodes, consumes *)
(* the whole packet, and encodes back to exactly the bytes it was read     *)
(* from.                                                                   *)
(***************************************************************************)
EXTENDS C1Options_MarketLevel2_v1_0_4

HeartbeatMessageCapture ==
    << 1, 0, 24, 0, 0, 1, 82, 55, 26, 19, 202, 1, 0, 52, 188, 141,
       0, 8, 16, 48, 0, 52, 188, 141 >>

IncrementalRefreshMessageCapture ==
    << 1, 0, 58, 0, 0, 1, 82, 55, 26, 17, 63, 1, 0, 93, 27, 219,
       0, 42, 18, 88, 0, 93, 27, 219, 8, 103, 156, 5, 26, 228, 46, 238,
       0, 87, 52, 213, 17, 3, 1, 1, 49, 2, 254, 0, 0, 9, 1, 2,
       0, 0, 0, 2, 55, 1, 0, 0, 0, 39 >>

SecurityDefinitionMessageCapture ==
    << 1, 0, 93, 0, 0, 1, 103, 205, 112, 80, 44, 1, 7, 209, 141, 195,
       0, 77, 13, 100, 7, 209, 141, 195, 3, 79, 80, 84, 67, 1, 88, 1,
       48, 4, 32, 70, 56, 21, 239, 4, 90, 0, 0, 0, 0, 1, 52, 19,
       152, 3, 253, 0, 0, 111, 84, 1, 252, 0, 0, 4, 226, 254, 0, 15,
       66, 54, 254, 0, 0, 1, 44, 254, 0, 0, 0, 5, 254, 0, 0, 0,
       1, 0, 0, 1, 88, 2, 67, 83, 0, 0, 0, 100, 0 >>

SecurityStatusMessageCapture ==
    << 1, 0, 37, 0, 0, 1, 82, 55, 26, 106, 23, 1, 0, 52, 198, 118,
       0, 21, 19, 102, 0, 52, 198, 118, 8, 128, 124, 190, 28, 16, 65, 26,
       0, 0, 14, 61, 24 >>

SnapshotFullRefreshMessageCapture ==
    << 1, 0, 205, 0, 0, 1, 82, 55, 26, 22, 63, 1, 0, 93, 28, 87,
       0, 189, 17, 87, 0, 93, 28, 87, 8, 103, 156, 5, 26, 228, 46, 238,
       0, 87, 53, 22, 17, 3, 78, 10, 48, 1, 254, 0, 0, 8, 247, 1,
       0, 0, 0, 0, 168, 48, 2, 254, 0, 0, 8, 242, 2, 0, 0, 0,
       2, 66, 1, 0, 0, 0, 6, 48, 3, 254, 0, 0, 8, 237, 2, 0,
       0, 0, 3, 60, 1, 0, 0, 0, 22, 48, 4, 254, 0, 0, 8, 232,
       1, 0, 0, 0, 3, 12, 48, 5, 254, 0, 0, 8, 227, 2, 0, 0,
       0, 3, 27, 1, 0, 0, 0, 12, 49, 1, 254, 0, 0, 8, 252, 2,
       0, 0, 0, 0, 57, 1, 0, 0, 0, 10, 49, 2, 254, 0, 0, 9,
       1, 2, 0, 0, 0, 2, 55, 1, 0, 0, 0, 39, 49, 3, 254, 0,
       0, 9, 6, 2, 0, 0, 0, 3, 6, 1, 0, 0, 0, 2, 49, 4,
       254, 0, 0, 9, 11, 2, 0, 0, 0, 2, 190, 1, 0, 0, 0, 1,
       49, 5, 254, 0, 0, 9, 16, 1, 0, 0, 0, 2, 214 >>

Captures == { HeartbeatMessageCapture, IncrementalRefreshMessageCapture, SecurityDefinitionMessageCapture, SecurityStatusMessageCapture, SnapshotFullRefreshMessageCapture }

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
