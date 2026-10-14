----------------- MODULE ArcaEquities_Bbo_v2_4_c_Captures ------------------
(***************************************************************************)
(* Recorded New York Stock Exchange Best Bid And Offer v2.4.c packets, as  *)
(* the bytes they were captured as. Each one decodes, consumes the whole   *)
(* packet, and encodes back to exactly the bytes it was read from.         *)
(***************************************************************************)
EXTENDS ArcaEquities_Bbo_v2_4_c

QuoteMessageCapture ==
    << 54, 0, 11, 1, 162, 76, 0, 0, 0, 184, 211, 89, 197, 232, 16, 2,
       38, 0, 140, 0, 216, 162, 197, 45, 189, 25, 0, 0, 224, 3, 0, 0,
       120, 149, 1, 0, 100, 0, 0, 0, 32, 147, 1, 0, 44, 1, 0, 0,
       82, 65, 7, 46, 0, 0 >>

SequenceNumberResetMessageCapture ==
    << 30, 0, 12, 1, 1, 0, 0, 0, 252, 183, 211, 89, 118, 221, 150, 6,
       14, 0, 1, 0, 107, 174, 211, 89, 229, 2, 246, 2, 3, 1 >>

SymbolIndexMappingMessageCapture ==
    << 60, 0, 11, 1, 2, 0, 0, 0, 252, 183, 211, 89, 201, 215, 153, 6,
       44, 0, 3, 0, 87, 142, 0, 0, 65, 67, 80, 0, 0, 0, 0, 0,
       0, 0, 0, 65, 1, 0, 5, 78, 4, 80, 100, 0, 168, 216, 1, 0,
       0, 0, 0, 0, 0, 78, 1, 0, 1, 0, 0, 0 >>

Captures == { QuoteMessageCapture, SequenceNumberResetMessageCapture, SymbolIndexMappingMessageCapture }

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
