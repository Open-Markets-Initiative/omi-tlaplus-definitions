-------------- MODULE NsmEquities_TotalView_v3_0_Udp_Captures --------------
(***************************************************************************)
(* Recorded National Association of Securities Dealers Automated           *)
(* Quotations (Nasdaq) TotalView Itch v3.0 packets, as the bytes they were *)
(* captured as. Each one decodes, consumes the whole packet, and encodes   *)
(* back to exactly the bytes it was read from.                             *)
(***************************************************************************)
EXTENDS NsmEquities_TotalView_v3_0_Udp

AddOrderMessageCapture ==
    << 83, 48, 57, 50, 57, 48, 56, 118, 51, 0, 0, 3, 10, 177, 1, 0,
       0, 33, 65, 32, 32, 32, 32, 32, 53, 55, 54, 55, 83, 32, 32, 49,
       48, 48, 48, 80, 80, 32, 32, 32, 32, 32, 32, 32, 32, 32, 55, 56,
       48, 48, 48 >>

AddOrderWithMpidMessageCapture ==
    << 83, 48, 57, 50, 57, 48, 56, 118, 51, 0, 0, 3, 11, 50, 1, 0,
       0, 37, 70, 32, 32, 32, 32, 49, 51, 49, 56, 55, 83, 32, 32, 49,
       48, 48, 48, 65, 67, 72, 32, 32, 32, 32, 32, 32, 32, 49, 53, 57,
       57, 48, 48, 66, 79, 79, 75 >>

BrokenTradeMessageCapture ==
    << 83, 48, 57, 50, 57, 48, 56, 118, 51, 0, 0, 8, 233, 88, 1, 0,
       0, 10, 66, 32, 32, 32, 32, 32, 32, 54, 57, 52 >>

CrossTradeMessageCapture ==
    << 83, 48, 57, 50, 57, 48, 56, 118, 51, 0, 0, 15, 177, 205, 1, 0,
       0, 36, 81, 32, 32, 32, 32, 32, 32, 32, 32, 48, 76, 70, 85, 83,
       32, 32, 32, 32, 32, 32, 32, 48, 48, 48, 48, 48, 32, 32, 32, 32,
       49, 48, 51, 49, 48, 72 >>

MarketParticipantPositionMessageCapture ==
    << 83, 48, 57, 50, 57, 48, 56, 118, 51, 0, 0, 0, 85, 243, 1, 0,
       0, 14, 76, 65, 66, 76, 69, 65, 65, 80, 76, 32, 32, 89, 78, 65 >>

MillisecondsMessageCapture ==
    << 83, 48, 57, 50, 57, 48, 56, 118, 51, 0, 0, 0, 0, 1, 1, 0,
       0, 4, 77, 52, 56, 48 >>

NetOrderImbalanceIndicatorMessageCapture ==
    << 83, 48, 57, 50, 57, 48, 56, 118, 51, 0, 0, 14, 1, 133, 1, 0,
       0, 58, 73, 32, 32, 32, 32, 32, 32, 32, 32, 48, 32, 32, 32, 32,
       32, 32, 32, 32, 48, 79, 76, 70, 85, 83, 32, 32, 32, 32, 32, 32,
       32, 48, 48, 48, 48, 48, 32, 32, 32, 32, 32, 48, 48, 48, 48, 48,
       32, 32, 32, 32, 32, 48, 48, 48, 48, 48, 72, 32 >>

OrderCancelMessageCapture ==
    << 83, 48, 57, 50, 57, 48, 56, 118, 51, 0, 0, 3, 11, 113, 1, 0,
       0, 16, 88, 32, 32, 32, 32, 32, 53, 57, 54, 55, 32, 32, 32, 50,
       48, 48 >>

OrderDeleteMessageCapture ==
    << 83, 48, 57, 50, 57, 48, 56, 118, 51, 0, 0, 3, 11, 50, 1, 0,
       0, 10, 68, 32, 32, 32, 32, 49, 50, 52, 55, 52 >>

OrderExecutedMessageCapture ==
    << 83, 48, 57, 50, 57, 48, 56, 118, 51, 0, 0, 3, 11, 113, 1, 0,
       0, 25, 69, 32, 32, 32, 32, 49, 56, 54, 48, 49, 32, 32, 32, 49,
       48, 48, 32, 32, 32, 32, 32, 32, 32, 32, 49 >>

OrderExecutedWithPriceMessageCapture ==
    << 83, 48, 57, 50, 57, 48, 56, 118, 51, 0, 0, 103, 227, 156, 1, 0,
       0, 36, 67, 32, 32, 49, 53, 55, 51, 50, 52, 56, 32, 32, 32, 32,
       55, 53, 32, 32, 32, 32, 55, 56, 53, 49, 48, 78, 32, 32, 32, 32,
       32, 52, 54, 53, 48, 48 >>

SecondsMessageCapture ==
    << 83, 48, 57, 50, 57, 48, 56, 118, 51, 0, 0, 0, 0, 1, 1, 0,
       0, 6, 84, 50, 50, 52, 56, 55 >>

StockDirectoryMessageCapture ==
    << 83, 48, 57, 50, 57, 48, 56, 118, 51, 0, 0, 0, 0, 1, 1, 0,
       0, 16, 82, 65, 32, 32, 32, 32, 32, 84, 32, 32, 32, 32, 49, 48,
       48, 78 >>

StockTradingActionMessageCapture ==
    << 83, 48, 57, 50, 57, 48, 56, 118, 51, 0, 0, 0, 0, 1, 1, 0,
       0, 13, 72, 65, 32, 32, 32, 32, 32, 84, 32, 32, 32, 32, 32 >>

StockTradingActionMessageWithStockDirectoryMessageCapture1 ==
    << 83, 48, 57, 50, 57, 48, 56, 118, 51, 0, 0, 0, 0, 1, 1, 0,
       0, 16, 82, 65, 32, 32, 32, 32, 32, 84, 32, 32, 32, 32, 49, 48,
       48, 78 >>

StockTradingActionMessageWithStockDirectoryMessageCapture2 ==
    << 83, 48, 57, 50, 57, 48, 56, 118, 51, 0, 0, 0, 0, 1, 1, 0,
       0, 13, 72, 65, 32, 32, 32, 32, 32, 84, 32, 32, 32, 32, 32 >>

SystemEventMessageCapture ==
    << 83, 48, 57, 50, 57, 48, 56, 118, 51, 0, 0, 0, 0, 1, 1, 0,
       0, 2, 83, 79 >>

TradeMessageCapture ==
    << 83, 48, 57, 50, 57, 48, 56, 118, 51, 0, 0, 3, 14, 138, 1, 0,
       0, 42, 80, 32, 32, 32, 32, 51, 48, 48, 50, 52, 66, 32, 32, 32,
       32, 49, 48, 65, 65, 80, 76, 32, 32, 32, 32, 32, 49, 50, 49, 52,
       51, 48, 48, 32, 32, 32, 32, 32, 32, 32, 32, 51 >>

Captures == { AddOrderMessageCapture, AddOrderWithMpidMessageCapture, BrokenTradeMessageCapture, CrossTradeMessageCapture, MarketParticipantPositionMessageCapture, MillisecondsMessageCapture, NetOrderImbalanceIndicatorMessageCapture, OrderCancelMessageCapture, OrderDeleteMessageCapture, OrderExecutedMessageCapture, OrderExecutedWithPriceMessageCapture, SecondsMessageCapture, StockDirectoryMessageCapture, StockTradingActionMessageCapture, StockTradingActionMessageWithStockDirectoryMessageCapture1, StockTradingActionMessageWithStockDirectoryMessageCapture2, SystemEventMessageCapture, TradeMessageCapture }

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
