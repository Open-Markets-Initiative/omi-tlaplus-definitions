----------------- MODULE NyseEquities_Bbo_v2_4_g_Captures ------------------
(***************************************************************************)
(* Recorded New York Stock Exchange Best Bid And Offer v2.4.g packets, as  *)
(* the bytes they were captured as. Each one decodes, consumes the whole   *)
(* packet, and encodes back to exactly the bytes it was read from.         *)
(***************************************************************************)
EXTENDS NyseEquities_Bbo_v2_4_g

QuoteMessageCapture ==
    << 54, 0, 11, 1, 59, 1, 0, 0, 252, 183, 211, 89, 26, 53, 85, 10,
       38, 0, 140, 0, 240, 129, 58, 3, 177, 18, 0, 0, 6, 0, 0, 0,
       120, 180, 0, 0, 144, 1, 0, 0, 176, 179, 0, 0, 68, 47, 0, 0,
       79, 32, 187, 3, 0, 0 >>

SecurityStatusMessageCapture ==
    << 62, 0, 11, 1, 96, 0, 0, 0, 252, 183, 211, 89, 120, 193, 184, 7,
       46, 0, 34, 0, 129, 188, 108, 87, 192, 77, 50, 6, 87, 142, 0, 0,
       2, 0, 0, 0, 80, 32, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 126, 80, 32 >>

SequenceNumberResetMessageCapture ==
    << 30, 0, 12, 1, 1, 0, 0, 0, 252, 183, 211, 89, 118, 221, 150, 6,
       14, 0, 1, 0, 107, 174, 211, 89, 229, 2, 246, 2, 3, 1 >>

SymbolIndexMappingMessageCapture ==
    << 60, 0, 11, 1, 2, 0, 0, 0, 252, 183, 211, 89, 201, 215, 153, 6,
       44, 0, 3, 0, 87, 142, 0, 0, 65, 67, 80, 0, 0, 0, 0, 0,
       0, 0, 0, 65, 1, 0, 5, 78, 4, 80, 100, 0, 168, 216, 1, 0,
       0, 0, 0, 0, 0, 78, 1, 0, 1, 0, 0, 0 >>

TradingSessionChangeMessageCapture ==
    << 37, 0, 11, 1, 51, 1, 0, 0, 252, 183, 211, 89, 227, 201, 60, 10,
       21, 0, 33, 0, 216, 53, 109, 87, 200, 210, 253, 2, 177, 18, 0, 0,
       5, 0, 0, 0, 2 >>

Captures == { QuoteMessageCapture, SecurityStatusMessageCapture, SequenceNumberResetMessageCapture, SymbolIndexMappingMessageCapture, TradingSessionChangeMessageCapture }

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
