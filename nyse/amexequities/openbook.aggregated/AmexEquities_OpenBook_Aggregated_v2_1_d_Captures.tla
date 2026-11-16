--------- MODULE AmexEquities_OpenBook_Aggregated_v2_1_d_Captures ----------
(***************************************************************************)
(* Recorded New York Stock Exchange Open Book Aggregated v2.1.d packets,   *)
(* as the bytes they were captured as. Each one decodes, consumes the      *)
(* whole packet, and encodes back to exactly the bytes it was read from.   *)
(***************************************************************************)
EXTENDS AmexEquities_OpenBook_Aggregated_v2_1_d

OrderbookDeltaUpdateMessageCapture ==
    << 40, 0, 11, 1, 46, 3, 0, 0, 176, 104, 66, 89, 3, 53, 157, 1,
       24, 0, 111, 0, 176, 104, 66, 89, 50, 226, 152, 1, 185, 17, 0, 0,
       0, 0, 0, 0, 69, 0, 0, 0 >>

OrderbookSnapshotMessageCapture ==
    << 98, 0, 11, 2, 10, 0, 0, 0, 242, 12, 66, 89, 38, 83, 46, 56,
       44, 0, 3, 0, 206, 222, 0, 0, 65, 84, 69, 83, 84, 32, 76, 0,
       0, 0, 0, 0, 9, 0, 56, 65, 6, 84, 100, 0, 48, 81, 125, 1,
       0, 0, 0, 0, 0, 78, 100, 0, 1, 0, 0, 0, 38, 0, 110, 0,
       242, 12, 66, 89, 8, 234, 43, 56, 206, 222, 0, 0, 0, 0, 0, 0,
       65, 84, 69, 83, 84, 32, 76, 0, 0, 0, 0, 6, 80, 0, 0, 100,
       0, 0 >>

SequenceNumberResetMessageCapture ==
    << 30, 0, 12, 1, 1, 0, 0, 0, 156, 12, 66, 89, 41, 28, 143, 52,
       14, 0, 1, 0, 81, 12, 66, 89, 39, 14, 49, 53, 50, 1 >>

SymbolIndexMappingMessageCapture ==
    << 98, 0, 11, 2, 10, 0, 0, 0, 242, 12, 66, 89, 38, 83, 46, 56,
       44, 0, 3, 0, 206, 222, 0, 0, 65, 84, 69, 83, 84, 32, 76, 0,
       0, 0, 0, 0, 9, 0, 56, 65, 6, 84, 100, 0, 48, 81, 125, 1,
       0, 0, 0, 0, 0, 78, 100, 0, 1, 0, 0, 0, 38, 0, 110, 0,
       242, 12, 66, 89, 8, 234, 43, 56, 206, 222, 0, 0, 0, 0, 0, 0,
       65, 84, 69, 83, 84, 32, 76, 0, 0, 0, 0, 6, 80, 0, 0, 100,
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
