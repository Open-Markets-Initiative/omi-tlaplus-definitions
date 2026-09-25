----------------- MODULE NsmEquities_NlsPlus_v3_0_Captures -----------------
(***************************************************************************)
(* Recorded National Association of Securities Dealers Automated           *)
(* Quotations (Nasdaq) Last Sale Plus v3.0 packets, as the bytes they were *)
(* captured as. Each one decodes, consumes the whole packet, and encodes   *)
(* back to exactly the bytes it was read from.                             *)
(***************************************************************************)
EXTENDS NsmEquities_NlsPlus_v3_0

NlsPlusRegShoShortSalePriceTestRestrictedIndicatorMessageCapture1 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 18, 0, 0, 31, 26, 207, 142, 107, 119, 89, 72,
       85, 82, 65, 32, 32, 32, 32, 49 >>

NlsPlusRegShoShortSalePriceTestRestrictedIndicatorMessageCapture2 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 18, 0, 0, 31, 26, 219, 19, 3, 13, 89, 70,
       65, 65, 83, 32, 32, 32, 32, 49 >>

NlsPlusRegShoShortSalePriceTestRestrictedIndicatorMessageCapture3 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 18, 0, 0, 31, 26, 220, 112, 244, 46, 89, 67,
       71, 66, 83, 87, 32, 32, 32, 49 >>

NlsPlusRegShoShortSalePriceTestRestrictedIndicatorMessageCapture4 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 18, 0, 0, 31, 26, 228, 234, 49, 119, 89, 84,
       67, 77, 68, 32, 32, 32, 32, 49 >>

NlsPlusRegShoShortSalePriceTestRestrictedIndicatorMessageCapture5 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 18, 0, 0, 31, 26, 238, 41, 210, 60, 89, 87,
       71, 83, 87, 87, 32, 32, 32, 49 >>

NlsPlusStockTradingActionMessageCapture1 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 24, 0, 0, 31, 30, 148, 69, 119, 52, 72, 32,
       90, 86, 90, 90, 84, 32, 32, 32, 81, 80, 76, 85, 68, 80 >>

NlsPlusStockTradingActionMessageCapture2 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 24, 0, 0, 31, 63, 0, 10, 117, 194, 72, 32,
       66, 86, 83, 32, 32, 32, 32, 32, 81, 80, 76, 85, 68, 80 >>

NlsPlusStockTradingActionMessageCapture3 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 24, 0, 0, 31, 93, 207, 118, 37, 81, 72, 32,
       90, 88, 90, 90, 84, 32, 32, 32, 81, 80, 76, 85, 68, 80 >>

NlsPlusStockTradingActionMessageCapture4 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 24, 0, 0, 31, 100, 109, 172, 108, 122, 72, 32,
       90, 86, 90, 90, 84, 32, 32, 32, 81, 84, 32, 32, 32, 32 >>

NlsPlusStockTradingActionMessageCapture5 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 24, 0, 0, 31, 163, 168, 221, 168, 37, 72, 32,
       90, 88, 90, 90, 84, 32, 32, 32, 81, 84, 32, 32, 32, 32 >>

NlsPlusSystemEventMessageCapture1 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 10, 0, 0, 31, 26, 206, 219, 18, 129, 83, 81 >>

NlsPlusSystemEventMessageCapture2 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 10, 0, 0, 31, 26, 206, 219, 18, 129, 83, 81 >>

NlsPlusTradeReportLongPriceMessageCapture1 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 53, 0, 0, 31, 26, 251, 173, 90, 145, 116, 76,
       66, 82, 75, 46, 65, 32, 32, 32, 78, 48, 48, 48, 48, 65, 48, 50,
       65, 68, 48, 0, 0, 0, 1, 140, 39, 250, 210, 0, 0, 0, 1, 64,
       32, 32, 32, 0, 0, 0, 0, 0, 0, 0, 1 >>

NlsPlusTradeReportLongPriceMessageCapture2 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 53, 0, 0, 31, 27, 7, 25, 157, 114, 116, 76,
       66, 82, 75, 46, 65, 32, 32, 32, 78, 48, 48, 48, 48, 65, 48, 50,
       67, 87, 73, 0, 0, 0, 1, 139, 254, 32, 44, 0, 0, 0, 1, 64,
       32, 32, 32, 0, 0, 0, 0, 0, 0, 0, 2 >>

NlsPlusTradeReportLongPriceMessageCapture3 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 53, 0, 0, 31, 27, 7, 76, 244, 205, 116, 76,
       66, 82, 75, 46, 65, 32, 32, 32, 78, 48, 48, 48, 48, 65, 48, 50,
       67, 89, 78, 0, 0, 0, 1, 139, 254, 32, 44, 0, 0, 0, 1, 64,
       32, 32, 32, 0, 0, 0, 0, 0, 0, 0, 3 >>

NlsPlusTradeReportLongPriceMessageCapture4 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 53, 0, 0, 31, 27, 7, 113, 141, 141, 116, 76,
       66, 82, 75, 46, 65, 32, 32, 32, 78, 48, 48, 48, 48, 65, 48, 50,
       68, 48, 51, 0, 0, 0, 1, 140, 55, 2, 222, 0, 0, 0, 1, 64,
       32, 32, 32, 0, 0, 0, 0, 0, 0, 0, 4 >>

NlsPlusTradeReportLongPriceMessageCapture5 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 53, 0, 0, 31, 27, 7, 115, 18, 57, 116, 76,
       66, 82, 75, 46, 65, 32, 32, 32, 78, 48, 48, 48, 48, 65, 48, 50,
       68, 48, 55, 0, 0, 0, 1, 139, 254, 32, 44, 0, 0, 0, 1, 64,
       32, 32, 32, 0, 0, 0, 0, 0, 0, 0, 5 >>

NlsPlusTradeReportMessageCapture1 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 49, 0, 0, 31, 26, 206, 215, 87, 179, 84, 81,
       76, 65, 66, 68, 32, 32, 32, 32, 80, 32, 32, 32, 32, 51, 56, 51,
       57, 57, 51, 0, 0, 229, 76, 0, 0, 2, 88, 64, 32, 84, 32, 0,
       0, 0, 0, 0, 2, 45, 142 >>

NlsPlusTradeReportMessageCapture2 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 49, 0, 0, 31, 26, 206, 215, 152, 30, 84, 81,
       76, 65, 66, 85, 32, 32, 32, 32, 80, 32, 32, 32, 32, 51, 56, 51,
       57, 57, 52, 0, 19, 33, 68, 0, 0, 0, 32, 64, 32, 84, 111, 0,
       0, 0, 0, 0, 0, 43, 88 >>

NlsPlusTradeReportMessageCapture3 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 49, 0, 0, 31, 26, 206, 216, 228, 174, 84, 81,
       70, 68, 85, 83, 32, 32, 32, 32, 81, 32, 32, 32, 32, 51, 56, 51,
       57, 57, 53, 0, 2, 237, 156, 0, 0, 0, 1, 64, 32, 84, 111, 0,
       0, 0, 0, 0, 0, 0, 17 >>

NlsPlusTradeReportMessageCapture4 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 49, 0, 0, 31, 26, 206, 217, 133, 46, 84, 81,
       65, 75, 66, 65, 32, 32, 32, 32, 81, 32, 32, 32, 32, 51, 56, 51,
       57, 57, 54, 0, 0, 72, 168, 0, 0, 0, 100, 64, 32, 84, 32, 0,
       0, 0, 0, 0, 0, 137, 174 >>

NlsPlusTradeReportMessageCapture5 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 49, 0, 0, 31, 26, 206, 219, 122, 243, 84, 81,
       76, 82, 67, 88, 32, 32, 32, 32, 81, 32, 32, 32, 32, 51, 56, 51,
       57, 57, 55, 0, 11, 91, 108, 0, 0, 0, 31, 64, 70, 84, 111, 0,
       0, 0, 0, 0, 0, 83, 43 >>

Captures == { NlsPlusRegShoShortSalePriceTestRestrictedIndicatorMessageCapture1, NlsPlusRegShoShortSalePriceTestRestrictedIndicatorMessageCapture2, NlsPlusRegShoShortSalePriceTestRestrictedIndicatorMessageCapture3, NlsPlusRegShoShortSalePriceTestRestrictedIndicatorMessageCapture4, NlsPlusRegShoShortSalePriceTestRestrictedIndicatorMessageCapture5, NlsPlusStockTradingActionMessageCapture1, NlsPlusStockTradingActionMessageCapture2, NlsPlusStockTradingActionMessageCapture3, NlsPlusStockTradingActionMessageCapture4, NlsPlusStockTradingActionMessageCapture5, NlsPlusSystemEventMessageCapture1, NlsPlusSystemEventMessageCapture2, NlsPlusTradeReportLongPriceMessageCapture1, NlsPlusTradeReportLongPriceMessageCapture2, NlsPlusTradeReportLongPriceMessageCapture3, NlsPlusTradeReportLongPriceMessageCapture4, NlsPlusTradeReportLongPriceMessageCapture5, NlsPlusTradeReportMessageCapture1, NlsPlusTradeReportMessageCapture2, NlsPlusTradeReportMessageCapture3, NlsPlusTradeReportMessageCapture4, NlsPlusTradeReportMessageCapture5 }

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
