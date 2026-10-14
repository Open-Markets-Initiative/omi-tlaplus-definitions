----------------- MODULE NyseEquities_Bbo_v2_5_b_Captures ------------------
(***************************************************************************)
(* Recorded New York Stock Exchange Best Bid And Offer v2.5.b packets, as  *)
(* the bytes they were captured as. Each one decodes, consumes the whole   *)
(* packet, and encodes back to exactly the bytes it was read from.         *)
(***************************************************************************)
EXTENDS NyseEquities_Bbo_v2_5_b

QuoteMessageCapture ==
    << 50, 0, 11, 1, 197, 121, 7, 0, 88, 184, 228, 100, 0, 107, 11, 0,
       34, 0, 140, 0, 0, 230, 10, 0, 64, 63, 0, 0, 4, 0, 0, 0,
       176, 120, 102, 2, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       82, 32 >>

RefreshHeaderMessageCapture ==
    << 122, 0, 19, 3, 50, 11, 21, 0, 81, 185, 228, 100, 0, 91, 88, 13,
       16, 0, 35, 0, 1, 0, 1, 0, 86, 208, 7, 0, 5, 0, 0, 0,
       44, 0, 3, 0, 36, 4, 0, 0, 67, 86, 76, 89, 0, 0, 0, 0,
       0, 0, 0, 0, 10, 0, 56, 81, 6, 67, 100, 0, 176, 158, 60, 1,
       0, 0, 0, 0, 0, 78, 100, 0, 1, 0, 0, 0, 46, 0, 34, 0,
       88, 184, 228, 100, 0, 84, 215, 1, 36, 4, 0, 0, 5, 0, 0, 0,
       79, 126, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 32, 0,
       0, 0, 0, 0, 0, 0, 0, 126, 79, 0 >>

SecurityStatusMessageCapture ==
    << 62, 0, 11, 1, 168, 124, 7, 0, 88, 184, 228, 100, 0, 55, 207, 0,
       46, 0, 34, 0, 88, 184, 228, 100, 0, 186, 206, 0, 68, 39, 0, 0,
       4, 0, 0, 0, 79, 126, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 126, 79, 0 >>

SourceTimeReferenceMessageCapture ==
    << 32, 0, 11, 1, 175, 121, 7, 0, 88, 184, 228, 100, 0, 86, 2, 0,
       16, 0, 2, 0, 54, 0, 0, 0, 0, 0, 0, 0, 88, 184, 228, 100 >>

Captures == { QuoteMessageCapture, RefreshHeaderMessageCapture, SecurityStatusMessageCapture, SourceTimeReferenceMessageCapture }

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
