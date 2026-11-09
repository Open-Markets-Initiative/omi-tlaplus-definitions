-------- MODULE ByxEquities_MulticastDepthOfBook_v2_41_29_Captures ---------
(***************************************************************************)
(* Recorded Chicago Board Options Exchange Multicast Depth Of Book         *)
(* v2.41.29 packets, as the bytes they were captured as. Each one decodes, *)
(* consumes the whole packet, and encodes back to exactly the bytes it was *)
(* read from.                                                              *)
(***************************************************************************)
EXTENDS ByxEquities_MulticastDepthOfBook_v2_41_29

AddOrderLongMessageCapture ==
    << 42, 0, 1, 8, 81, 110, 0, 0, 34, 33, 184, 93, 22, 1, 39, 38,
       15, 50, 248, 145, 1, 15, 83, 160, 0, 0, 0, 68, 88, 89, 78, 32,
       32, 71, 38, 0, 0, 0, 0, 0, 0, 1 >>

AddOrderShortMessageCapture1 ==
    << 34, 0, 1, 17, 179, 54, 0, 0, 26, 34, 72, 190, 154, 59, 240, 119,
       79, 106, 38, 25, 114, 31, 66, 144, 1, 77, 65, 84, 32, 32, 32, 18,
       8, 1 >>

AddOrderShortMessageCapture2 ==
    << 40, 0, 2, 15, 74, 186, 0, 0, 6, 32, 152, 133, 0, 0, 26, 34,
       112, 219, 9, 0, 21, 204, 203, 93, 170, 222, 202, 27, 66, 196, 84, 74,
       68, 83, 84, 32, 32, 244, 2, 1 >>

AddOrderShortMessageCapture3 ==
    << 34, 0, 1, 15, 76, 186, 0, 0, 26, 34, 208, 72, 10, 0, 23, 204,
       203, 93, 170, 222, 202, 27, 66, 200, 0, 73, 88, 78, 32, 32, 32, 102,
       23, 1 >>

AddOrderShortMessageCapture4 ==
    << 60, 0, 2, 15, 77, 186, 0, 0, 26, 34, 184, 195, 11, 0, 27, 204,
       203, 93, 170, 222, 202, 27, 83, 100, 0, 73, 87, 79, 32, 32, 32, 230,
       91, 1, 26, 34, 40, 219, 11, 0, 28, 204, 203, 93, 170, 222, 202, 27,
       66, 100, 0, 73, 87, 79, 32, 32, 32, 118, 91, 1 >>

AddOrderShortMessageCapture5 ==
    << 66, 0, 3, 31, 158, 139, 0, 0, 6, 32, 152, 133, 0, 0, 26, 34,
       80, 129, 11, 0, 217, 194, 205, 193, 138, 178, 4, 57, 66, 8, 32, 89,
       65, 78, 71, 32, 32, 109, 4, 1, 26, 34, 160, 199, 11, 0, 218, 194,
       205, 193, 138, 178, 4, 57, 66, 100, 0, 88, 83, 86, 78, 32, 32, 59,
       18, 1 >>

AuctionSummaryMessageCapture ==
    << 82, 0, 2, 24, 241, 25, 3, 0, 47, 149, 24, 208, 125, 8, 83, 79,
       88, 76, 32, 32, 32, 32, 80, 40, 117, 3, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 27, 150, 24, 208, 125, 8, 83, 79, 88,
       76, 32, 32, 32, 32, 80, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0 >>

AuctionUpdateMessageCapture ==
    << 55, 0, 1, 24, 235, 25, 3, 0, 47, 149, 216, 36, 71, 7, 83, 79,
       88, 76, 32, 32, 32, 32, 80, 40, 117, 3, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0 >>

DeleteOrderMessageCapture ==
    << 22, 0, 1, 2, 129, 69, 0, 0, 14, 41, 112, 87, 31, 0, 57, 47,
       143, 12, 132, 226, 11, 4 >>

ModifyOrderLongMessageCapture ==
    << 35, 0, 1, 1, 131, 83, 0, 0, 27, 39, 96, 46, 192, 1, 11, 193,
       77, 6, 70, 69, 56, 2, 100, 0, 0, 0, 155, 3, 0, 0, 0, 0,
       0, 0, 1 >>

ModifyOrderShortMessageCapture ==
    << 27, 0, 1, 11, 243, 219, 1, 0, 19, 40, 72, 13, 200, 25, 151, 237,
       204, 68, 178, 105, 124, 20, 100, 0, 227, 10, 1 >>

OrderExecutedAtPriceSizeMessageCapture ==
    << 46, 0, 1, 18, 222, 46, 0, 0, 38, 36, 176, 169, 185, 25, 7, 195,
       143, 112, 100, 182, 69, 33, 100, 0, 0, 0, 0, 0, 0, 0, 176, 157,
       160, 107, 72, 1, 0, 0, 192, 174, 49, 0, 0, 0, 0, 0 >>

OrderExecutedMessageCapture ==
    << 34, 0, 1, 7, 50, 108, 1, 0, 26, 35, 240, 177, 68, 0, 138, 27,
       208, 43, 186, 244, 45, 13, 176, 4, 0, 0, 230, 220, 19, 184, 127, 0,
       0, 0 >>

ReduceSizeShortMessageCapture ==
    << 24, 0, 1, 4, 103, 192, 0, 0, 16, 38, 24, 127, 124, 0, 96, 19,
       15, 25, 0, 29, 179, 7, 208, 7 >>

RetailPriceImprovementMessageCapture ==
    << 23, 0, 1, 15, 82, 186, 0, 0, 15, 152, 160, 50, 15, 0, 73, 87,
       77, 32, 32, 32, 32, 32, 78 >>

TradeLongMessageCapture ==
    << 49, 0, 1, 26, 68, 244, 1, 0, 41, 42, 248, 113, 187, 12, 221, 117,
       143, 162, 84, 160, 226, 47, 66, 35, 0, 0, 0, 84, 81, 81, 81, 32,
       32, 174, 241, 5, 0, 0, 0, 0, 0, 95, 159, 146, 98, 218, 1, 0,
       0 >>

TradeShortMessageCapture ==
    << 41, 0, 1, 31, 174, 139, 0, 0, 33, 43, 32, 99, 59, 0, 9, 195,
       205, 193, 138, 178, 4, 57, 66, 5, 0, 89, 73, 78, 78, 32, 32, 122,
       11, 157, 217, 233, 156, 53, 2, 0, 0 >>

TradingStatusMessageCapture ==
    << 26, 0, 1, 24, 192, 109, 2, 0, 18, 49, 24, 173, 247, 6, 83, 79,
       80, 65, 32, 32, 32, 32, 84, 49, 32, 32 >>

Captures == { AddOrderLongMessageCapture, AddOrderShortMessageCapture1, AddOrderShortMessageCapture2, AddOrderShortMessageCapture3, AddOrderShortMessageCapture4, AddOrderShortMessageCapture5, AuctionSummaryMessageCapture, AuctionUpdateMessageCapture, DeleteOrderMessageCapture, ModifyOrderLongMessageCapture, ModifyOrderShortMessageCapture, OrderExecutedAtPriceSizeMessageCapture, OrderExecutedMessageCapture, ReduceSizeShortMessageCapture, RetailPriceImprovementMessageCapture, TradeLongMessageCapture, TradeShortMessageCapture, TradingStatusMessageCapture }

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
