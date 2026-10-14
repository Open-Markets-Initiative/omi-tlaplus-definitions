------------ MODULE NyseEquities_ImbalancesFeed_v2_2_a_Captures ------------
(***************************************************************************)
(* Recorded New York Stock Exchange Imbalances Feed v2.2.a packets, as the *)
(* bytes they were captured as. Each one decodes, consumes the whole       *)
(* packet, and encodes back to exactly the bytes it was read from.         *)
(***************************************************************************)
EXTENDS NyseEquities_ImbalancesFeed_v2_2_a

ImbalanceMessageCapture ==
    << 89, 0, 11, 1, 194, 120, 0, 0, 208, 114, 126, 92, 181, 21, 152, 0,
       73, 0, 105, 0, 208, 114, 126, 92, 0, 130, 103, 0, 16, 39, 0, 0,
       2, 0, 0, 0, 64, 60, 135, 1, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 162, 3, 77, 32, 64, 60, 135, 1, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 32, 32 >>

SecurityStatusMessageCapture ==
    << 62, 0, 11, 1, 168, 90, 0, 0, 17, 31, 126, 92, 151, 116, 65, 17,
       46, 0, 34, 0, 247, 30, 126, 92, 248, 81, 227, 34, 191, 17, 0, 0,
       1, 0, 0, 0, 80, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 126, 80, 32 >>

SymbolIndexMappingMessageCapture ==
    << 104, 0, 11, 2, 107, 89, 0, 0, 17, 31, 126, 92, 59, 167, 17, 10,
       44, 0, 3, 0, 191, 17, 0, 0, 65, 65, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 65, 1, 0, 40, 78, 4, 65, 100, 0, 8, 151, 1, 0,
       0, 0, 0, 0, 0, 78, 1, 0, 1, 0, 0, 0, 44, 0, 3, 0,
       22, 63, 0, 0, 65, 66, 0, 0, 0, 0, 0, 0, 0, 0, 0, 65,
       1, 0, 40, 78, 4, 65, 100, 0, 48, 174, 3, 0, 0, 0, 0, 0,
       0, 78, 1, 0, 1, 0, 0, 0 >>

Captures == { ImbalanceMessageCapture, SecurityStatusMessageCapture, SymbolIndexMappingMessageCapture }

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
