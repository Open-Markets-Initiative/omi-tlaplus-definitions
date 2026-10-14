--------------- MODULE NationalEquities_Bbo_v2_5_d_Captures ----------------
(***************************************************************************)
(* Recorded New York Stock Exchange Best Bid And Offer v2.5.d packets, as  *)
(* the bytes they were captured as. Each one decodes, consumes the whole   *)
(* packet, and encodes back to exactly the bytes it was read from.         *)
(***************************************************************************)
EXTENDS NationalEquities_Bbo_v2_5_d

QuoteMessageCapture ==
    << 50, 0, 11, 1, 176, 121, 7, 0, 88, 184, 228, 100, 0, 145, 2, 0,
       34, 0, 140, 0, 0, 2, 2, 0, 40, 175, 0, 0, 25, 0, 0, 0,
       96, 41, 172, 1, 100, 0, 0, 0, 224, 157, 163, 1, 100, 0, 0, 0,
       82, 32 >>

SecurityStatusMessageCapture ==
    << 62, 0, 11, 1, 168, 124, 7, 0, 88, 184, 228, 100, 0, 55, 207, 0,
       46, 0, 34, 0, 88, 184, 228, 100, 0, 186, 206, 0, 68, 39, 0, 0,
       4, 0, 0, 0, 79, 126, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 126, 79, 0 >>

SourceTimeReferenceMessageCapture ==
    << 32, 0, 11, 1, 175, 121, 7, 0, 88, 184, 228, 100, 0, 86, 2, 0,
       16, 0, 2, 0, 54, 0, 0, 0, 0, 0, 0, 0, 88, 184, 228, 100 >>

Captures == { QuoteMessageCapture, SecurityStatusMessageCapture, SourceTimeReferenceMessageCapture }

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
