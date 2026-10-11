-------- MODULE Cboe_TitaniumConsolidated_Indices_v1_4_13_Captures ---------
(***************************************************************************)
(* Recorded Chicago Board Options Exchange Global Indices Feed v1.4.13     *)
(* packets, as the bytes they were captured as. Each one decodes, consumes *)
(* the whole packet, and encodes back to exactly the bytes it was read     *)
(* from.                                                                   *)
(***************************************************************************)
EXTENDS Cboe_TitaniumConsolidated_Indices_v1_4_13

ContributorValueMessageCapture ==
    << 1, 0, 48, 0, 0, 1, 155, 39, 90, 123, 201, 1, 0, 50, 156, 123,
       0, 32, 23, 88, 0, 50, 156, 123, 0, 0, 1, 155, 39, 90, 123, 192,
       8, 77, 83, 84, 80, 56, 53, 78, 69, 1, 51, 252, 1, 15, 19, 19 >>

HeartbeatMessageCapture ==
    << 1, 0, 24, 0, 0, 1, 155, 39, 90, 127, 197, 1, 0, 9, 236, 81,
       0, 8, 16, 48, 0, 9, 236, 81 >>

IndexDefinitionMessageCapture ==
    << 1, 0, 236, 0, 0, 1, 155, 39, 90, 218, 104, 4, 0, 5, 7, 98,
       0, 55, 26, 68, 0, 5, 7, 98, 0, 0, 0, 165, 0, 0, 7, 152,
       7, 66, 85, 75, 50, 53, 48, 78, 11, 67, 98, 111, 101, 32, 85, 75,
       32, 50, 53, 48, 10, 50, 48, 50, 53, 45, 49, 50, 45, 49, 54, 1,
       67, 79, 1, 3, 67, 71, 73, 0, 55, 26, 68, 0, 5, 7, 99, 0,
       0, 0, 166, 0, 0, 7, 152, 7, 66, 85, 75, 50, 53, 48, 80, 11,
       67, 98, 111, 101, 32, 85, 75, 32, 50, 53, 48, 10, 50, 48, 50, 53,
       45, 49, 50, 45, 49, 54, 1, 67, 79, 1, 3, 67, 71, 73, 0, 55,
       26, 68, 0, 5, 7, 100, 0, 0, 0, 167, 0, 0, 7, 152, 7, 66,
       85, 75, 51, 53, 48, 78, 11, 67, 98, 111, 101, 32, 85, 75, 32, 51,
       53, 48, 10, 50, 48, 50, 53, 45, 49, 50, 45, 49, 54, 1, 67, 79,
       1, 3, 67, 71, 73, 0, 55, 26, 68, 0, 5, 7, 101, 0, 0, 0,
       168, 0, 0, 7, 152, 7, 66, 85, 75, 51, 53, 48, 80, 11, 67, 98,
       111, 101, 32, 85, 75, 32, 51, 53, 48, 10, 50, 48, 50, 53, 45, 49,
       50, 45, 49, 54, 1, 67, 79, 1, 3, 67, 71, 73 >>

IndexValueMessageCapture ==
    << 1, 0, 51, 0, 0, 1, 155, 39, 90, 123, 197, 1, 1, 73, 54, 232,
       0, 35, 22, 88, 1, 73, 54, 232, 7, 79, 88, 84, 53, 75, 82, 80,
       3, 51, 250, 0, 0, 100, 22, 48, 250, 0, 0, 99, 225, 49, 250, 0,
       0, 100, 76 >>

IndexValueWithStatusMessageCapture ==
    << 1, 0, 39, 0, 0, 1, 155, 39, 90, 126, 29, 1, 0, 92, 205, 65,
       0, 23, 25, 88, 0, 92, 205, 65, 78, 6, 66, 68, 69, 52, 48, 78,
       1, 51, 252, 0, 30, 101, 152 >>

Captures == { ContributorValueMessageCapture, HeartbeatMessageCapture, IndexDefinitionMessageCapture, IndexValueMessageCapture, IndexValueWithStatusMessageCapture }

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
