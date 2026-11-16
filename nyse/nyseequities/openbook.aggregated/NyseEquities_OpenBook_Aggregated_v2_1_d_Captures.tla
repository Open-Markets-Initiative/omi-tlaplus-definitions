--------- MODULE NyseEquities_OpenBook_Aggregated_v2_1_d_Captures ----------
(***************************************************************************)
(* Recorded New York Stock Exchange Open Book Aggregated v2.1.d packets,   *)
(* as the bytes they were captured as. Each one decodes, consumes the      *)
(* whole packet, and encodes back to exactly the bytes it was read from.   *)
(***************************************************************************)
EXTENDS NyseEquities_OpenBook_Aggregated_v2_1_d

OrderbookDeltaUpdateMessageCapture ==
    << 40, 0, 11, 1, 126, 24, 0, 0, 60, 64, 182, 89, 102, 25, 70, 35,
       24, 0, 111, 0, 60, 64, 182, 89, 207, 78, 69, 35, 132, 18, 0, 0,
       0, 0, 0, 0, 72, 0, 0, 0 >>

OrderbookSnapshotMessageCapture ==
    << 98, 0, 11, 2, 24, 5, 0, 0, 193, 22, 182, 89, 150, 96, 71, 49,
       44, 0, 3, 0, 106, 19, 0, 0, 66, 66, 75, 0, 0, 0, 0, 0,
       0, 0, 0, 65, 1, 0, 10, 78, 4, 80, 100, 0, 232, 116, 2, 0,
       0, 0, 0, 0, 0, 78, 1, 0, 1, 0, 0, 0, 38, 0, 110, 0,
       193, 22, 182, 89, 75, 19, 68, 49, 106, 19, 0, 0, 0, 0, 0, 0,
       66, 66, 75, 0, 0, 0, 0, 0, 0, 0, 0, 4, 80, 0, 0, 1,
       0, 0 >>

SequenceNumberResetMessageCapture ==
    << 30, 0, 12, 1, 1, 0, 0, 0, 167, 15, 182, 89, 211, 68, 138, 57,
       14, 0, 1, 0, 152, 15, 182, 89, 221, 151, 224, 38, 1, 1 >>

SymbolIndexMappingMessageCapture ==
    << 98, 0, 11, 2, 24, 5, 0, 0, 193, 22, 182, 89, 150, 96, 71, 49,
       44, 0, 3, 0, 106, 19, 0, 0, 66, 66, 75, 0, 0, 0, 0, 0,
       0, 0, 0, 65, 1, 0, 10, 78, 4, 80, 100, 0, 232, 116, 2, 0,
       0, 0, 0, 0, 0, 78, 1, 0, 1, 0, 0, 0, 38, 0, 110, 0,
       193, 22, 182, 89, 75, 19, 68, 49, 106, 19, 0, 0, 0, 0, 0, 0,
       66, 66, 75, 0, 0, 0, 0, 0, 0, 0, 0, 4, 80, 0, 0, 1,
       0, 0 >>

Captures == { OrderbookDeltaUpdateMessageCapture, OrderbookSnapshotMessageCapture, SequenceNumberResetMessageCapture, SymbolIndexMappingMessageCapture }

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
