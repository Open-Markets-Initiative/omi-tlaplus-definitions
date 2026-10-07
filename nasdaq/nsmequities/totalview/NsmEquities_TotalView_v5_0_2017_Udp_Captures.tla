----------- MODULE NsmEquities_TotalView_v5_0_2017_Udp_Captures ------------
(***************************************************************************)
(* Recorded National Association of Securities Dealers Automated           *)
(* Quotations (Nasdaq) TotalView Itch v5.0.2017 packets, as the bytes they *)
(* were captured as. Each one decodes, consumes the whole packet, and      *)
(* encodes back to exactly the bytes it was read from.                     *)
(***************************************************************************)
EXTENDS NsmEquities_TotalView_v5_0_2017_Udp

AddOrderNoMpidAttributionMessageCapture ==
    << 48, 48, 48, 48, 49, 48, 48, 53, 57, 66, 0, 0, 0, 0, 0, 225,
       47, 89, 0, 1, 0, 36, 65, 21, 152, 0, 0, 31, 26, 206, 216, 83,
       6, 0, 0, 0, 0, 1, 102, 181, 62, 66, 0, 0, 6, 64, 73, 86,
       79, 79, 32, 32, 32, 32, 0, 13, 85, 172 >>

AddOrderWithMpidAttributionMessageCapture ==
    << 48, 48, 48, 48, 49, 48, 48, 53, 57, 66, 0, 0, 0, 0, 0, 97,
       140, 233, 0, 1, 0, 40, 70, 43, 103, 0, 0, 23, 49, 53, 127, 254,
       221, 0, 0, 0, 0, 0, 185, 81, 60, 66, 0, 0, 0, 225, 88, 76,
       69, 32, 32, 32, 32, 32, 0, 10, 88, 12, 83, 84, 70, 76 >>

CrossTradeMessageCapture ==
    << 48, 48, 48, 48, 49, 48, 48, 53, 57, 66, 0, 0, 0, 0, 0, 228,
       63, 133, 0, 1, 0, 40, 81, 0, 78, 0, 1, 31, 26, 216, 184, 143,
       200, 0, 0, 0, 0, 0, 0, 0, 0, 65, 67, 65, 88, 32, 32, 32,
       32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 254, 98, 79 >>

LuldAuctionCollarMessageCapture ==
    << 48, 48, 48, 48, 49, 48, 48, 53, 57, 66, 0, 0, 0, 0, 1, 7,
       134, 66, 0, 1, 0, 35, 74, 44, 56, 0, 0, 31, 30, 154, 138, 209,
       241, 90, 86, 90, 90, 84, 32, 32, 32, 0, 4, 31, 120, 0, 5, 9,
       216, 0, 3, 234, 188, 0, 0, 0, 0 >>

MarketParticipantPositionMessageCapture ==
    << 48, 48, 48, 48, 49, 48, 48, 53, 57, 66, 0, 0, 0, 0, 1, 16,
       141, 102, 0, 1, 0, 26, 76, 14, 147, 0, 0, 31, 32, 130, 218, 248,
       45, 77, 65, 88, 77, 70, 71, 77, 67, 32, 32, 32, 32, 89, 78, 65 >>

MwcbDeclineLevelMessageCapture ==
    << 48, 48, 48, 48, 49, 48, 48, 53, 57, 66, 0, 0, 0, 0, 0, 93,
       70, 175, 0, 1, 0, 35, 86, 0, 0, 0, 0, 22, 236, 185, 120, 12,
       255, 0, 0, 0, 95, 68, 232, 202, 128, 0, 0, 0, 89, 31, 104, 4,
       192, 0, 0, 0, 81, 243, 179, 213, 64 >>

NetOrderImbalanceIndicatorMessageCapture ==
    << 48, 48, 48, 48, 49, 48, 48, 53, 57, 66, 0, 0, 0, 0, 0, 225,
       48, 31, 0, 1, 0, 50, 73, 25, 62, 0, 0, 31, 26, 206, 222, 10,
       178, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0,
       0, 78, 77, 68, 67, 32, 32, 32, 32, 32, 0, 7, 22, 16, 0, 7,
       22, 16, 0, 7, 22, 16, 79, 76 >>

NonCrossTradeMessageCapture ==
    << 48, 48, 48, 48, 49, 48, 48, 53, 57, 66, 0, 0, 0, 0, 0, 4,
       164, 5, 0, 1, 0, 44, 80, 21, 5, 0, 2, 13, 24, 252, 112, 127,
       144, 0, 0, 0, 0, 0, 0, 0, 0, 66, 0, 0, 0, 1, 73, 79,
       78, 81, 32, 32, 32, 32, 0, 2, 59, 24, 0, 0, 0, 0, 0, 0,
       88, 132 >>

OrderCancelMessageCapture ==
    << 48, 48, 48, 48, 49, 48, 48, 53, 57, 66, 0, 0, 0, 0, 0, 4,
       139, 12, 0, 1, 0, 23, 88, 43, 43, 0, 0, 13, 24, 197, 50, 202,
       144, 0, 0, 0, 0, 0, 0, 17, 252, 0, 0, 0, 100 >>

OrderDeleteMessageCapture ==
    << 48, 48, 48, 48, 49, 48, 48, 53, 57, 66, 0, 0, 0, 0, 0, 225,
       47, 90, 0, 1, 0, 19, 68, 13, 189, 0, 0, 31, 26, 206, 216, 90,
       216, 0, 0, 0, 0, 1, 102, 139, 214 >>

OrderExecutedMessageCapture ==
    << 48, 48, 48, 48, 49, 48, 48, 53, 57, 66, 0, 0, 0, 0, 0, 225,
       47, 113, 0, 1, 0, 31, 69, 9, 41, 0, 2, 31, 26, 206, 216, 240,
       97, 0, 0, 0, 0, 1, 102, 146, 154, 0, 0, 0, 25, 0, 0, 0,
       0, 0, 3, 230, 59 >>

OrderExecutedWithPriceMessageCapture ==
    << 48, 48, 48, 48, 49, 48, 48, 53, 57, 66, 0, 0, 0, 0, 0, 225,
       109, 98, 0, 1, 0, 36, 67, 36, 197, 0, 2, 31, 26, 207, 237, 142,
       74, 0, 0, 0, 0, 2, 8, 149, 196, 0, 0, 0, 200, 0, 0, 0,
       0, 0, 3, 234, 3, 89, 0, 3, 119, 28 >>

OrderReplaceMessageCapture ==
    << 48, 48, 48, 48, 49, 48, 48, 53, 57, 66, 0, 0, 0, 0, 0, 225,
       47, 69, 0, 1, 0, 35, 85, 29, 179, 0, 0, 31, 26, 206, 215, 113,
       233, 0, 0, 0, 0, 0, 230, 137, 127, 0, 0, 0, 0, 1, 69, 242,
       199, 0, 0, 0, 100, 0, 16, 54, 200 >>

RegShoShortSalePriceTestRestrictedIndicatorMessageCapture ==
    << 48, 48, 48, 48, 49, 48, 48, 53, 57, 66, 0, 0, 0, 0, 0, 0,
       9, 131, 0, 1, 0, 20, 89, 0, 5, 0, 0, 10, 48, 193, 240, 169,
       77, 65, 65, 67, 32, 32, 32, 32, 32, 48 >>

StockDirectoryMessageCapture ==
    << 48, 48, 48, 48, 49, 48, 48, 53, 57, 66, 0, 0, 0, 0, 0, 0,
       0, 2, 0, 1, 0, 39, 82, 0, 1, 0, 0, 10, 48, 191, 113, 201,
       4, 65, 32, 32, 32, 32, 32, 32, 32, 78, 32, 0, 0, 0, 100, 78,
       67, 90, 32, 80, 78, 32, 49, 78, 0, 0, 0, 0, 78 >>

StockTradingActionMessageCapture ==
    << 48, 48, 48, 48, 49, 48, 48, 53, 57, 66, 0, 0, 0, 0, 2, 9,
       14, 121, 0, 1, 0, 25, 72, 1, 208, 0, 0, 31, 157, 247, 124, 158,
       32, 65, 77, 67, 32, 32, 32, 32, 32, 84, 32, 32, 32, 32, 32 >>

SystemEventMessageCapture ==
    << 48, 48, 48, 48, 49, 48, 48, 53, 56, 66, 0, 0, 0, 0, 24, 55,
       215, 196, 0, 1, 0, 12, 83, 0, 0, 0, 0, 65, 123, 206, 108, 213,
       22, 69 >>

Captures == { AddOrderNoMpidAttributionMessageCapture, AddOrderWithMpidAttributionMessageCapture, CrossTradeMessageCapture, LuldAuctionCollarMessageCapture, MarketParticipantPositionMessageCapture, MwcbDeclineLevelMessageCapture, NetOrderImbalanceIndicatorMessageCapture, NonCrossTradeMessageCapture, OrderCancelMessageCapture, OrderDeleteMessageCapture, OrderExecutedMessageCapture, OrderExecutedWithPriceMessageCapture, OrderReplaceMessageCapture, RegShoShortSalePriceTestRestrictedIndicatorMessageCapture, StockDirectoryMessageCapture, StockTradingActionMessageCapture, SystemEventMessageCapture }

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
