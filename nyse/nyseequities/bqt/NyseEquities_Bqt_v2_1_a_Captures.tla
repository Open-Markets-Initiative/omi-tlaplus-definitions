----------------- MODULE NyseEquities_Bqt_v2_1_a_Captures ------------------
(***************************************************************************)
(* Recorded New York Stock Exchange Best Quote And Trade v2.1.a packets,   *)
(* as the bytes they were captured as. Each one decodes, consumes the      *)
(* whole packet, and encodes back to exactly the bytes it was read from.   *)
(***************************************************************************)
EXTENDS NyseEquities_Bqt_v2_1_a

ConsolidatedStockSummaryMessageCapture ==
    << 55, 0, 11, 1, 179, 128, 8, 0, 104, 3, 172, 95, 40, 221, 88, 1,
       39, 0, 229, 0, 103, 3, 172, 95, 192, 224, 56, 53, 19, 10, 1, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 76, 42, 2, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 100, 0, 0 >>

SequenceNumberResetMessageCapture ==
    << 30, 0, 12, 1, 1, 0, 0, 0, 252, 115, 171, 95, 168, 151, 241, 0,
       14, 0, 1, 0, 251, 115, 171, 95, 136, 229, 242, 58, 25, 231 >>

Captures == { ConsolidatedStockSummaryMessageCapture, SequenceNumberResetMessageCapture }

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
