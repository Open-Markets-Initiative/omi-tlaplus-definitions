------------------ MODULE NsmEquities_Qbbo_v2_1_Captures -------------------
(***************************************************************************)
(* Recorded National Association of Securities Dealers Automated           *)
(* Quotations (Nasdaq) Quoted Best Bid And Offer v2.1 packets, as the      *)
(* bytes they were captured as. Each one decodes, consumes the whole       *)
(* packet, and encodes back to exactly the bytes it was read from.         *)
(***************************************************************************)
EXTENDS NsmEquities_Qbbo_v2_1

BboBboQuotationMessageCapture1 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 34, 81, 0, 0, 31, 26, 206, 215, 92, 236, 73,
       88, 74, 32, 32, 32, 32, 32, 80, 0, 14, 32, 104, 0, 0, 1, 144,
       0, 14, 48, 208, 0, 0, 3, 32 >>

BboBboQuotationMessageCapture2 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 34, 81, 0, 0, 31, 26, 206, 215, 201, 73, 88,
       66, 73, 32, 32, 32, 32, 32, 80, 0, 15, 6, 224, 0, 0, 15, 160,
       0, 15, 30, 180, 0, 0, 0, 100 >>

BboBboQuotationMessageCapture3 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 34, 81, 0, 0, 31, 26, 206, 216, 6, 33, 76,
       65, 66, 85, 32, 32, 32, 32, 80, 0, 19, 18, 208, 0, 0, 0, 1,
       0, 19, 84, 212, 0, 0, 0, 3 >>

BboBboQuotationMessageCapture4 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 34, 81, 0, 0, 31, 26, 206, 216, 25, 2, 67,
       76, 79, 85, 32, 32, 32, 32, 81, 0, 3, 60, 232, 0, 0, 5, 120,
       0, 3, 63, 64, 0, 0, 0, 200 >>

BboBboQuotationMessageCapture5 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 34, 81, 0, 0, 31, 26, 206, 216, 126, 136, 76,
       65, 66, 68, 32, 32, 32, 32, 80, 0, 0, 226, 244, 0, 0, 11, 42,
       0, 0, 229, 176, 0, 0, 11, 84 >>

BboRegShoRestrictionMessageCapture1 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 18, 89, 0, 0, 31, 26, 207, 142, 107, 119, 72,
       85, 82, 65, 32, 32, 32, 32, 49 >>

BboRegShoRestrictionMessageCapture2 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 18, 89, 0, 0, 31, 26, 219, 19, 3, 13, 70,
       65, 65, 83, 32, 32, 32, 32, 49 >>

BboRegShoRestrictionMessageCapture3 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 18, 89, 0, 0, 31, 26, 220, 112, 244, 46, 67,
       71, 66, 83, 87, 32, 32, 32, 49 >>

BboRegShoRestrictionMessageCapture4 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 18, 89, 0, 0, 31, 26, 228, 234, 49, 119, 84,
       67, 77, 68, 32, 32, 32, 32, 49 >>

BboRegShoRestrictionMessageCapture5 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 18, 89, 0, 0, 31, 26, 238, 41, 210, 60, 87,
       71, 83, 87, 87, 32, 32, 32, 49 >>

BboStockTradingActionMessageCapture1 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 23, 72, 0, 0, 31, 30, 148, 69, 119, 52, 90,
       86, 90, 90, 84, 32, 32, 32, 81, 80, 76, 85, 68, 80 >>

BboStockTradingActionMessageCapture2 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 23, 72, 0, 0, 31, 63, 0, 10, 117, 194, 66,
       86, 83, 32, 32, 32, 32, 32, 81, 80, 76, 85, 68, 80 >>

BboStockTradingActionMessageCapture3 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 23, 72, 0, 0, 31, 93, 207, 118, 37, 81, 90,
       88, 90, 90, 84, 32, 32, 32, 81, 80, 76, 85, 68, 80 >>

BboStockTradingActionMessageCapture4 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 23, 72, 0, 3, 31, 100, 109, 172, 108, 122, 90,
       86, 90, 90, 84, 32, 32, 32, 81, 84, 32, 32, 32, 32 >>

BboStockTradingActionMessageCapture5 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 23, 72, 0, 2, 31, 163, 168, 221, 168, 37, 90,
       88, 90, 90, 84, 32, 32, 32, 81, 84, 32, 32, 32, 32 >>

BboSystemEventMessageCapture1 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 10, 83, 0, 0, 31, 26, 206, 219, 18, 129, 81 >>

BboSystemEventMessageCapture2 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 10, 83, 0, 0, 31, 26, 206, 219, 18, 129, 81 >>

BboSystemEventMessageCapture3 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 10, 83, 0, 0, 31, 26, 206, 219, 18, 129, 81 >>

Captures == { BboBboQuotationMessageCapture1, BboBboQuotationMessageCapture2, BboBboQuotationMessageCapture3, BboBboQuotationMessageCapture4, BboBboQuotationMessageCapture5, BboRegShoRestrictionMessageCapture1, BboRegShoRestrictionMessageCapture2, BboRegShoRestrictionMessageCapture3, BboRegShoRestrictionMessageCapture4, BboRegShoRestrictionMessageCapture5, BboStockTradingActionMessageCapture1, BboStockTradingActionMessageCapture2, BboStockTradingActionMessageCapture3, BboStockTradingActionMessageCapture4, BboStockTradingActionMessageCapture5, BboSystemEventMessageCapture1, BboSystemEventMessageCapture2, BboSystemEventMessageCapture3 }

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
