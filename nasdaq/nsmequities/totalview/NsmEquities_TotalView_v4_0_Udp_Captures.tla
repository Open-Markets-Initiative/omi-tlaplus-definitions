-------------- MODULE NsmEquities_TotalView_v4_0_Udp_Captures --------------
(***************************************************************************)
(* Recorded National Association of Securities Dealers Automated           *)
(* Quotations (Nasdaq) TotalView Itch v4.0 packets, as the bytes they were *)
(* captured as. Each one decodes, consumes the whole packet, and encodes   *)
(* back to exactly the bytes it was read from.                             *)
(***************************************************************************)
EXTENDS NsmEquities_TotalView_v4_0_Udp

AddOrderMessageCapture ==
    << 83, 48, 51, 50, 52, 48, 57, 118, 52, 46, 0, 0, 0, 0, 0, 2,
       96, 47, 0, 1, 0, 28, 65, 0, 183, 27, 0, 0, 0, 0, 0, 0,
       0, 10, 127, 83, 0, 0, 0, 60, 65, 65, 80, 76, 32, 32, 0, 30,
       210, 160 >>

AddOrderWithMpidMessageCapture ==
    << 83, 48, 51, 50, 52, 48, 57, 118, 52, 46, 0, 0, 0, 0, 0, 2,
       96, 195, 0, 1, 0, 32, 70, 21, 10, 90, 64, 0, 0, 0, 0, 0,
       0, 30, 177, 66, 0, 0, 21, 24, 65, 73, 71, 32, 32, 32, 0, 0,
       53, 232, 66, 79, 79, 75 >>

BrokenTradeMessageCapture ==
    << 83, 48, 51, 50, 52, 48, 57, 118, 52, 46, 0, 0, 0, 0, 4, 201,
       251, 53, 0, 1, 0, 13, 66, 55, 80, 40, 0, 0, 0, 0, 0, 0,
       1, 114, 93 >>

CrossTradeMessageCapture ==
    << 83, 48, 51, 50, 52, 48, 57, 118, 52, 46, 0, 0, 0, 0, 0, 109,
       255, 210, 0, 1, 0, 32, 81, 0, 15, 66, 64, 0, 0, 0, 0, 0,
       0, 0, 0, 81, 67, 67, 79, 32, 32, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 1, 20, 246, 79 >>

MarketParticipantPositionMessageCapture ==
    << 83, 48, 51, 50, 52, 48, 57, 118, 52, 46, 0, 0, 0, 0, 0, 0,
       63, 117, 0, 1, 0, 18, 76, 29, 159, 158, 64, 65, 66, 76, 69, 65,
       65, 80, 76, 32, 32, 89, 78, 65 >>

NetOrderImbalanceIndicatorMessageCapture ==
    << 83, 48, 51, 50, 52, 48, 57, 118, 52, 46, 0, 0, 0, 0, 0, 96,
       37, 99, 0, 1, 0, 42, 73, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 1, 144, 0, 0, 0, 0, 0, 0, 0, 0, 78, 65, 32, 32, 32,
       32, 32, 0, 2, 99, 84, 0, 2, 99, 84, 0, 2, 99, 84, 79, 76 >>

OrderCancelMessageCapture ==
    << 83, 48, 51, 50, 52, 48, 57, 118, 52, 46, 0, 0, 0, 0, 0, 2,
       96, 195, 0, 1, 0, 17, 88, 34, 39, 73, 64, 0, 0, 0, 0, 0,
       0, 31, 17, 0, 0, 39, 16 >>

OrderDeleteMessageCapture ==
    << 83, 48, 51, 50, 52, 48, 57, 118, 52, 46, 0, 0, 0, 0, 0, 2,
       96, 195, 0, 1, 0, 13, 68, 23, 62, 237, 128, 0, 0, 0, 0, 0,
       0, 30, 177 >>

OrderExecutedMessageCapture ==
    << 83, 48, 51, 50, 52, 48, 57, 118, 52, 46, 0, 0, 0, 0, 0, 2,
       103, 96, 0, 1, 0, 25, 69, 48, 178, 110, 64, 0, 0, 0, 0, 0,
       1, 92, 154, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1 >>

OrderExecutedWithPriceMessageCapture ==
    << 83, 48, 51, 50, 52, 48, 57, 118, 52, 46, 0, 0, 0, 0, 0, 110,
       0, 57, 0, 1, 0, 30, 67, 0, 45, 198, 192, 0, 0, 0, 0, 0,
       80, 110, 180, 0, 0, 0, 100, 0, 0, 0, 0, 0, 1, 20, 253, 78,
       0, 0, 252, 88 >>

StockDirectoryMessageCapture ==
    << 83, 48, 51, 50, 52, 48, 57, 118, 52, 46, 0, 0, 0, 0, 0, 0,
       0, 1, 0, 1, 0, 18, 82, 28, 3, 161, 128, 65, 32, 32, 32, 32,
       32, 84, 32, 0, 0, 0, 100, 78 >>

StockTradingActionMessageCapture ==
    << 83, 48, 51, 50, 52, 48, 57, 118, 52, 46, 0, 0, 0, 0, 0, 0,
       0, 1, 0, 1, 0, 17, 72, 28, 18, 227, 192, 65, 32, 32, 32, 32,
       32, 84, 32, 32, 32, 32, 32 >>

StockTradingActionMessageWithStockDirectoryMessageCapture1 ==
    << 83, 48, 51, 50, 52, 48, 57, 118, 52, 46, 0, 0, 0, 0, 0, 0,
       0, 1, 0, 1, 0, 18, 82, 28, 3, 161, 128, 65, 32, 32, 32, 32,
       32, 84, 32, 0, 0, 0, 100, 78 >>

StockTradingActionMessageWithStockDirectoryMessageCapture2 ==
    << 83, 48, 51, 50, 52, 48, 57, 118, 52, 46, 0, 0, 0, 0, 0, 0,
       0, 1, 0, 1, 0, 17, 72, 28, 18, 227, 192, 65, 32, 32, 32, 32,
       32, 84, 32, 32, 32, 32, 32 >>

SystemEventMessageCapture ==
    << 83, 48, 51, 50, 52, 48, 57, 118, 52, 46, 0, 0, 0, 0, 0, 0,
       0, 1, 0, 1, 0, 6, 83, 23, 169, 189, 64, 79 >>

TimestampMessageCapture ==
    << 83, 48, 51, 50, 52, 48, 57, 118, 52, 46, 0, 0, 0, 0, 0, 0,
       0, 1, 0, 1, 0, 5, 84, 0, 0, 89, 57 >>

TradeMessageCapture ==
    << 83, 48, 51, 50, 52, 48, 57, 118, 52, 46, 0, 0, 0, 0, 0, 2,
       103, 96, 0, 1, 0, 36, 80, 48, 178, 110, 64, 0, 0, 0, 0, 0,
       1, 92, 121, 66, 0, 0, 3, 132, 71, 76, 68, 32, 32, 32, 0, 13,
       238, 204, 0, 0, 0, 0, 0, 0, 0, 2 >>

Captures == { AddOrderMessageCapture, AddOrderWithMpidMessageCapture, BrokenTradeMessageCapture, CrossTradeMessageCapture, MarketParticipantPositionMessageCapture, NetOrderImbalanceIndicatorMessageCapture, OrderCancelMessageCapture, OrderDeleteMessageCapture, OrderExecutedMessageCapture, OrderExecutedWithPriceMessageCapture, StockDirectoryMessageCapture, StockTradingActionMessageCapture, StockTradingActionMessageWithStockDirectoryMessageCapture1, StockTradingActionMessageWithStockDirectoryMessageCapture2, SystemEventMessageCapture, TimestampMessageCapture, TradeMessageCapture }

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
