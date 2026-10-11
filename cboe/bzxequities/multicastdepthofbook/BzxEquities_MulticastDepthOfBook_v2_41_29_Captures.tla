-------- MODULE BzxEquities_MulticastDepthOfBook_v2_41_29_Captures ---------
(***************************************************************************)
(* Recorded Chicago Board Options Exchange Multicast Depth Of Book         *)
(* v2.41.29 packets, as the bytes they were captured as. Each one decodes, *)
(* consumes the whole packet, and encodes back to exactly the bytes it was *)
(* read from.                                                              *)
(***************************************************************************)
EXTENDS BzxEquities_MulticastDepthOfBook_v2_41_29

AddOrderExpandedMessageCapture ==
    << 49, 0, 1, 6, 174, 111, 0, 0, 41, 47, 56, 246, 126, 2, 242, 125,
       195, 51, 184, 225, 19, 12, 66, 100, 0, 0, 0, 67, 79, 68, 73, 32,
       32, 32, 32, 220, 243, 2, 0, 0, 0, 0, 0, 1, 88, 71, 87, 68,
       32 >>

AddOrderLongMessageCapture ==
    << 42, 0, 1, 11, 113, 183, 1, 0, 34, 33, 0, 45, 55, 0, 119, 14,
       9, 76, 236, 243, 53, 21, 83, 248, 36, 1, 0, 71, 66, 73, 76, 32,
       32, 176, 64, 15, 0, 0, 0, 0, 0, 1 >>

AddOrderShortMessageCapture ==
    << 34, 0, 1, 27, 5, 185, 3, 0, 26, 34, 80, 52, 3, 0, 144, 219,
       200, 49, 205, 199, 111, 50, 66, 100, 0, 85, 66, 82, 32, 32, 32, 106,
       9, 1 >>

AuctionSummaryMessageCapture ==
    << 82, 0, 2, 33, 87, 97, 4, 0, 27, 150, 232, 247, 1, 0, 70, 80,
       65, 71, 32, 32, 32, 32, 79, 80, 177, 3, 0, 0, 0, 0, 0, 100,
       0, 0, 0, 47, 149, 232, 247, 1, 0, 85, 74, 85, 76, 32, 32, 32,
       32, 79, 124, 97, 4, 0, 0, 0, 0, 0, 10, 0, 0, 0, 94, 0,
       0, 0, 236, 95, 4, 0, 0, 0, 0, 0, 36, 95, 4, 0, 0, 0,
       0, 0 >>

AuctionUpdateMessageCapture ==
    << 82, 0, 2, 33, 87, 97, 4, 0, 27, 150, 232, 247, 1, 0, 70, 80,
       65, 71, 32, 32, 32, 32, 79, 80, 177, 3, 0, 0, 0, 0, 0, 100,
       0, 0, 0, 47, 149, 232, 247, 1, 0, 85, 74, 85, 76, 32, 32, 32,
       32, 79, 124, 97, 4, 0, 0, 0, 0, 0, 10, 0, 0, 0, 94, 0,
       0, 0, 236, 95, 4, 0, 0, 0, 0, 0, 36, 95, 4, 0, 0, 0,
       0, 0 >>

DeleteOrderMessageCapture ==
    << 22, 0, 1, 6, 42, 110, 0, 0, 14, 41, 16, 134, 5, 0, 247, 123,
       195, 51, 184, 225, 19, 12 >>

ModifyOrderLongMessageCapture ==
    << 35, 0, 1, 12, 186, 188, 0, 0, 27, 39, 168, 161, 132, 4, 34, 12,
       7, 212, 42, 145, 9, 23, 244, 1, 0, 0, 98, 17, 0, 0, 0, 0,
       0, 0, 1 >>

ModifyOrderShortMessageCapture ==
    << 27, 0, 1, 28, 37, 174, 1, 0, 19, 40, 104, 149, 7, 0, 205, 93,
       198, 185, 11, 101, 67, 52, 100, 0, 236, 166, 1 >>

OrderExecutedAtPriceSizeMessageCapture ==
    << 46, 0, 1, 24, 122, 33, 6, 0, 38, 36, 48, 157, 142, 3, 40, 71,
       20, 24, 17, 240, 244, 44, 100, 0, 0, 0, 44, 1, 0, 0, 3, 5,
       22, 214, 184, 1, 0, 0, 102, 81, 67, 0, 0, 0, 0, 0 >>

OrderExecutedMessageCapture ==
    << 34, 0, 1, 7, 44, 12, 3, 0, 26, 35, 72, 178, 10, 0, 1, 8,
       70, 184, 245, 126, 231, 13, 1, 0, 0, 0, 5, 169, 83, 169, 130, 0,
       0, 0 >>

ReduceSizeShortMessageCapture ==
    << 24, 0, 1, 24, 152, 24, 6, 0, 16, 38, 152, 140, 28, 0, 139, 43,
       20, 24, 17, 240, 244, 44, 100, 0 >>

TimeMessageCapture ==
    << 28, 0, 2, 7, 42, 12, 3, 0, 6, 32, 152, 133, 0, 0, 14, 41,
       184, 130, 1, 0, 167, 8, 70, 184, 245, 126, 231, 13 >>

TradeLongMessageCapture ==
    << 49, 0, 1, 34, 54, 10, 4, 0, 41, 42, 240, 49, 6, 0, 248, 23,
       199, 219, 126, 20, 57, 63, 66, 18, 0, 0, 0, 72, 83, 85, 78, 32,
       32, 194, 252, 4, 0, 0, 0, 0, 0, 86, 100, 208, 97, 57, 33, 0,
       0 >>

TradeShortMessageCapture ==
    << 41, 0, 1, 33, 91, 97, 4, 0, 33, 43, 232, 247, 1, 0, 189, 64,
       134, 213, 64, 119, 101, 61, 66, 84, 0, 85, 74, 85, 76, 32, 32, 51,
       11, 94, 36, 242, 34, 39, 33, 0, 0 >>

TradingStatusMessageCapture ==
    << 26, 0, 1, 24, 77, 39, 6, 0, 18, 49, 0, 165, 249, 6, 83, 79,
       80, 65, 32, 32, 32, 32, 84, 49, 32, 32 >>

Captures == { AddOrderExpandedMessageCapture, AddOrderLongMessageCapture, AddOrderShortMessageCapture, AuctionSummaryMessageCapture, AuctionUpdateMessageCapture, DeleteOrderMessageCapture, ModifyOrderLongMessageCapture, ModifyOrderShortMessageCapture, OrderExecutedAtPriceSizeMessageCapture, OrderExecutedMessageCapture, ReduceSizeShortMessageCapture, TimeMessageCapture, TradeLongMessageCapture, TradeShortMessageCapture, TradingStatusMessageCapture }

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
