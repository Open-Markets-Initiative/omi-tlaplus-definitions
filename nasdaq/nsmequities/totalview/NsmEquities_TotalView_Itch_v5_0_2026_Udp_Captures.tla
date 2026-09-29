--------- MODULE NsmEquities_TotalView_Itch_v5_0_2026_Udp_Captures ---------
(***************************************************************************)
(* Recorded National Association of Securities Dealers Automated           *)
(* Quotations (Nasdaq) TotalView Itch v5.0.2026 packets, as the bytes they *)
(* were captured as. Each one decodes, consumes the whole packet, and      *)
(* encodes back to exactly the bytes it was read from.                     *)
(***************************************************************************)
EXTENDS NsmEquities_TotalView_Itch_v5_0_2026_Udp

AddOrderNoMPIDCapture ==
    << 83, 48, 54, 49, 50, 50, 54, 32, 32, 32, 0, 0, 0, 0, 0, 0,
       0, 1, 0, 1, 0, 36, 65, 36, 52, 0, 0, 13, 24, 194, 232, 255,
       8, 0, 0, 0, 0, 0, 0, 0, 3, 66, 0, 0, 0, 100, 81, 73,
       68, 32, 32, 32, 32, 32, 0, 2, 58, 80 >>

AddOrderwithMpidCapture ==
    << 83, 48, 54, 49, 50, 50, 54, 32, 32, 32, 0, 0, 0, 0, 0, 0,
       0, 2, 0, 1, 0, 40, 70, 13, 6, 0, 0, 13, 24, 205, 4, 109,
       119, 0, 0, 0, 0, 0, 0, 141, 174, 66, 0, 0, 0, 100, 68, 89,
       78, 70, 32, 32, 32, 32, 0, 8, 156, 176, 79, 80, 84, 71 >>

CrossTradeCapture ==
    << 83, 48, 54, 49, 50, 50, 54, 32, 32, 32, 0, 0, 0, 0, 0, 0,
       0, 15, 0, 1, 0, 40, 81, 49, 77, 0, 2, 29, 119, 182, 139, 78,
       214, 0, 0, 0, 0, 0, 0, 0, 34, 88, 88, 73, 73, 32, 32, 32,
       32, 0, 0, 246, 24, 0, 0, 0, 0, 0, 10, 65, 234, 72 >>

LULDAuctionCollarCapture ==
    << 83, 48, 54, 49, 50, 50, 54, 32, 32, 32, 0, 0, 0, 0, 0, 0,
       0, 16, 0, 1, 0, 35, 74, 0, 234, 0, 0, 29, 49, 221, 29, 233,
       168, 65, 69, 82, 84, 32, 32, 32, 32, 0, 0, 206, 64, 0, 0, 245,
       80, 0, 0, 167, 48, 0, 0, 0, 0 >>

MarketParticipantPositionCapture ==
    << 83, 48, 54, 49, 50, 50, 54, 32, 32, 32, 0, 0, 0, 0, 0, 0,
       0, 3, 0, 1, 0, 26, 76, 24, 231, 0, 0, 10, 25, 6, 71, 16,
       182, 66, 75, 67, 77, 75, 66, 87, 66, 32, 32, 32, 32, 89, 78, 65 >>

NetOrderImbalanceIndicatorCapture ==
    << 83, 48, 54, 49, 50, 50, 54, 32, 32, 32, 0, 0, 0, 0, 0, 0,
       0, 17, 0, 1, 0, 50, 73, 0, 234, 0, 0, 29, 50, 24, 181, 21,
       241, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 79, 65, 69, 82, 84, 32, 32, 32, 32, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 72, 32 >>

NonCrossTradeCapture ==
    << 83, 48, 54, 49, 50, 50, 54, 32, 32, 32, 0, 0, 0, 0, 0, 0,
       0, 4, 0, 1, 0, 44, 80, 3, 39, 0, 2, 13, 24, 196, 130, 199,
       169, 0, 0, 0, 0, 0, 0, 0, 0, 66, 0, 0, 0, 1, 65, 83,
       77, 76, 32, 32, 32, 32, 1, 27, 21, 236, 0, 0, 0, 0, 0, 0,
       100, 4 >>

OrderCancelCapture ==
    << 83, 48, 54, 49, 50, 50, 54, 32, 32, 32, 0, 0, 0, 0, 0, 0,
       0, 5, 0, 1, 0, 23, 88, 22, 213, 0, 0, 13, 24, 195, 187, 3,
       147, 0, 0, 0, 0, 0, 0, 5, 198, 0, 0, 3, 62 >>

OrderDeleteCapture ==
    << 83, 48, 54, 49, 50, 50, 54, 32, 32, 32, 0, 0, 0, 0, 0, 0,
       0, 6, 0, 1, 0, 19, 68, 28, 100, 0, 0, 13, 24, 194, 245, 249,
       58, 0, 0, 0, 0, 0, 0, 0, 175 >>

OrderExecutedCapture ==
    << 83, 48, 54, 49, 50, 50, 54, 32, 32, 32, 0, 0, 0, 0, 0, 0,
       0, 7, 0, 1, 0, 31, 69, 22, 243, 0, 2, 13, 24, 195, 154, 226,
       210, 0, 0, 0, 0, 0, 0, 8, 154, 0, 0, 13, 172, 0, 0, 0,
       0, 0, 0, 99, 253 >>

OrderExecutedWithPriceCapture ==
    << 83, 48, 54, 49, 50, 50, 54, 32, 32, 32, 0, 0, 0, 0, 0, 0,
       0, 18, 0, 1, 0, 36, 67, 49, 77, 0, 1, 29, 119, 182, 139, 78,
       214, 0, 0, 0, 0, 3, 154, 213, 16, 0, 0, 0, 29, 0, 0, 0,
       0, 0, 10, 65, 233, 78, 0, 0, 246, 24 >>

OrderReplaceCapture ==
    << 83, 48, 54, 49, 50, 50, 54, 32, 32, 32, 0, 0, 0, 0, 0, 0,
       0, 8, 0, 1, 0, 35, 85, 44, 36, 0, 0, 13, 24, 195, 127, 122,
       216, 0, 0, 0, 0, 0, 0, 0, 124, 0, 0, 0, 0, 0, 0, 5,
       36, 0, 0, 0, 100, 0, 11, 147, 172 >>

RegSHORestrictionCapture ==
    << 83, 48, 54, 49, 50, 50, 54, 32, 32, 32, 0, 0, 0, 0, 0, 0,
       0, 9, 0, 1, 0, 20, 89, 0, 1, 0, 0, 10, 23, 196, 116, 250,
       42, 65, 32, 32, 32, 32, 32, 32, 32, 48 >>

StockDirectoryCapture ==
    << 83, 48, 54, 49, 50, 50, 54, 32, 32, 32, 0, 0, 0, 0, 0, 0,
       0, 14, 0, 1, 0, 39, 82, 0, 25, 0, 0, 10, 23, 196, 105, 239,
       177, 65, 65, 76, 32, 32, 32, 32, 32, 81, 78, 0, 0, 0, 100, 78,
       67, 90, 32, 80, 78, 78, 49, 78, 0, 0, 0, 0, 78 >>

StockTradingActionCapture ==
    << 83, 48, 54, 49, 50, 50, 54, 32, 32, 32, 0, 0, 0, 0, 0, 0,
       0, 11, 0, 1, 0, 25, 72, 0, 1, 0, 0, 10, 23, 196, 116, 95,
       232, 65, 32, 32, 32, 32, 32, 32, 32, 84, 32, 32, 32, 32, 32 >>

SystemEventCapture ==
    << 83, 48, 54, 49, 50, 50, 54, 32, 32, 32, 0, 0, 0, 0, 0, 0,
       0, 12, 0, 1, 0, 12, 83, 0, 0, 0, 0, 9, 231, 254, 83, 113,
       2, 79 >>

Captures == { AddOrderNoMPIDCapture, AddOrderwithMpidCapture, CrossTradeCapture, LULDAuctionCollarCapture, MarketParticipantPositionCapture, NetOrderImbalanceIndicatorCapture, NonCrossTradeCapture, OrderCancelCapture, OrderDeleteCapture, OrderExecutedCapture, OrderExecutedWithPriceCapture, OrderReplaceCapture, RegSHORestrictionCapture, StockDirectoryCapture, StockTradingActionCapture, SystemEventCapture }

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
