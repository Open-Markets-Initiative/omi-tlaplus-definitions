---- MODULE NationalEquities_IntegratedFeedStockSummary_v2_5_g_Captures ----
(***************************************************************************)
(* Recorded New York Stock Exchange Integrated Feed Stock Summary v2.5.g   *)
(* packets, as the bytes they were captured as. Each one decodes, consumes *)
(* the whole packet, and encodes back to exactly the bytes it was read     *)
(* from.                                                                   *)
(***************************************************************************)
EXTENDS NationalEquities_IntegratedFeedStockSummary_v2_5_g

StockSummaryMessageCapture ==
    << 52, 0, 11, 1, 59, 76, 3, 0, 136, 132, 22, 98, 0, 202, 131, 17,
       36, 0, 223, 0, 245, 107, 22, 98, 0, 245, 165, 13, 191, 231, 0, 0,
       160, 228, 152, 0, 128, 150, 152, 0, 160, 228, 152, 0, 0, 0, 0, 0,
       132, 3, 0, 0 >>

Captures == { StockSummaryMessageCapture }

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
