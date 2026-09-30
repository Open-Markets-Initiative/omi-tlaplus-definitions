----------------- MODULE Nasdaq_Uqdf_Output_v1_5_Captures ------------------
(***************************************************************************)
(* Recorded National Association of Securities Dealers Automated           *)
(* Quotations (Nasdaq) Output v1.5 packets, as the bytes they were         *)
(* captured as. Each one decodes, consumes the whole packet, and encodes   *)
(* back to exactly the bytes it was read from.                             *)
(***************************************************************************)
EXTENDS Nasdaq_Uqdf_Output_v1_5

LimitUpLimitDownPriceBandMessageCapture ==
    << 48, 48, 48, 48, 48, 55, 53, 50, 55, 81, 0, 0, 0, 0, 1, 48,
       113, 245, 0, 1, 0, 65, 49, 65, 80, 69, 32, 20, 116, 143, 71, 96,
       16, 44, 80, 0, 0, 0, 0, 0, 0, 0, 0, 255, 255, 255, 255, 255,
       255, 255, 255, 65, 78, 68, 65, 32, 32, 32, 32, 32, 32, 32, 67, 20,
       116, 131, 20, 1, 69, 202, 13, 0, 0, 0, 0, 0, 135, 88, 112, 0,
       0, 0, 0, 0, 165, 103, 192 >>

QuoteLongFormMessageCapture ==
    << 48, 48, 48, 48, 48, 55, 53, 50, 55, 81, 0, 0, 0, 0, 1, 48,
       183, 143, 0, 1, 0, 106, 49, 81, 70, 75, 32, 20, 116, 143, 75, 168,
       62, 51, 87, 20, 116, 143, 75, 168, 59, 82, 112, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 65, 77, 90, 78, 32,
       32, 32, 32, 32, 32, 32, 0, 0, 0, 0, 45, 187, 78, 80, 0, 0,
       0, 3, 0, 0, 0, 0, 45, 188, 56, 176, 0, 0, 0, 2, 82, 32,
       32, 32, 51, 65, 32, 82, 75, 0, 0, 0, 0, 45, 187, 78, 80, 0,
       0, 0, 3, 90, 0, 0, 0, 0, 45, 187, 117, 96, 0, 0, 0, 1 >>

QuoteShortFormMessageCapture ==
    << 48, 48, 48, 48, 48, 55, 53, 50, 55, 81, 0, 0, 0, 0, 1, 46,
       107, 77, 0, 1, 0, 48, 49, 81, 69, 75, 32, 20, 116, 143, 48, 211,
       71, 133, 170, 20, 116, 143, 48, 211, 68, 148, 96, 0, 0, 0, 0, 0,
       0, 0, 0, 65, 75, 65, 77, 32, 20, 3, 0, 1, 20, 4, 0, 1,
       82, 32, 32, 32, 48, 65 >>

Captures == { LimitUpLimitDownPriceBandMessageCapture, QuoteLongFormMessageCapture, QuoteShortFormMessageCapture }

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
