-------- MODULE EdgxEquities_MulticastDepthOfBook_v2_41_29_Captures --------
(***************************************************************************)
(* Recorded Chicago Board Options Exchange Multicast Depth Of Book         *)
(* v2.41.29 packets, as the bytes they were captured as. Each one decodes, *)
(* consumes the whole packet, and encodes back to exactly the bytes it was *)
(* read from.                                                              *)
(***************************************************************************)
EXTENDS EdgxEquities_MulticastDepthOfBook_v2_41_29

AddOrderExpandedMessageCapture ==
    << 49, 0, 1, 32, 98, 57, 2, 0, 41, 47, 136, 94, 50, 0, 235, 69,
       13, 200, 208, 79, 216, 58, 66, 1, 0, 0, 0, 65, 82, 75, 71, 32,
       32, 32, 32, 236, 120, 4, 0, 0, 0, 0, 0, 1, 82, 84, 65, 76,
       82 >>

AddOrderLongMessageCapture ==
    << 42, 0, 1, 25, 117, 195, 4, 0, 34, 33, 104, 206, 54, 1, 206, 174,
       81, 156, 30, 3, 15, 46, 83, 100, 0, 0, 0, 83, 86, 86, 67, 32,
       32, 142, 28, 0, 0, 0, 0, 0, 0, 1 >>

AddOrderShortMessageCapture ==
    << 34, 0, 1, 15, 67, 171, 2, 0, 26, 34, 160, 181, 14, 0, 91, 235,
       207, 93, 178, 222, 202, 27, 83, 100, 0, 73, 87, 77, 32, 32, 32, 73,
       72, 1 >>

DeleteOrderMessageCapture ==
    << 22, 0, 1, 29, 43, 78, 3, 0, 14, 41, 248, 30, 2, 0, 112, 152,
       78, 181, 22, 120, 93, 53 >>

ModifyOrderLongMessageCapture ==
    << 35, 0, 1, 10, 159, 4, 1, 0, 27, 39, 136, 200, 74, 0, 13, 222,
       143, 62, 124, 204, 168, 18, 15, 0, 0, 0, 120, 63, 132, 0, 0, 0,
       0, 0, 1 >>

ModifyOrderShortMessageCapture ==
    << 27, 0, 1, 10, 92, 4, 1, 0, 19, 40, 144, 53, 154, 59, 8, 220,
       143, 62, 124, 204, 168, 18, 100, 0, 86, 7, 1 >>

OrderExecutedAtPriceSizeMessageCapture ==
    << 46, 0, 1, 2, 207, 14, 2, 0, 38, 36, 16, 178, 194, 2, 153, 42,
       147, 12, 140, 226, 11, 4, 100, 0, 0, 0, 0, 0, 0, 0, 224, 191,
       188, 125, 36, 0, 0, 0, 232, 158, 20, 0, 0, 0, 0, 0 >>

OrderExecutedMessageCapture ==
    << 34, 0, 1, 1, 58, 240, 1, 0, 26, 35, 168, 84, 23, 0, 156, 76,
       80, 6, 78, 69, 56, 2, 2, 0, 0, 0, 61, 112, 222, 62, 18, 0,
       0, 0 >>

ReduceSizeShortMessageCapture ==
    << 24, 0, 1, 20, 186, 58, 1, 0, 16, 38, 168, 54, 28, 0, 152, 148,
       15, 125, 232, 240, 236, 36, 100, 0 >>

TimeMessageCapture ==
    << 28, 0, 2, 19, 178, 49, 3, 0, 6, 32, 152, 133, 0, 0, 14, 41,
       72, 238, 0, 0, 157, 99, 211, 118, 170, 83, 25, 35 >>

TradeLongMessageCapture ==
    << 49, 0, 1, 20, 4, 59, 1, 0, 41, 42, 88, 121, 151, 0, 57, 75,
       16, 125, 232, 240, 236, 36, 66, 100, 0, 0, 0, 80, 67, 84, 32, 32,
       32, 34, 80, 1, 0, 0, 0, 0, 0, 142, 37, 93, 233, 108, 1, 0,
       0 >>

TradeShortMessageCapture ==
    << 41, 0, 1, 31, 164, 123, 7, 0, 33, 43, 48, 140, 17, 0, 6, 228,
       210, 193, 146, 178, 4, 57, 66, 25, 0, 88, 76, 75, 32, 32, 32, 80,
       66, 217, 237, 196, 80, 124, 71, 0, 0 >>

TradingStatusMessageCapture ==
    << 26, 0, 1, 6, 81, 86, 1, 0, 18, 49, 56, 155, 251, 8, 67, 80,
       72, 73, 32, 32, 32, 32, 84, 49, 32, 32 >>

Captures == { AddOrderExpandedMessageCapture, AddOrderLongMessageCapture, AddOrderShortMessageCapture, DeleteOrderMessageCapture, ModifyOrderLongMessageCapture, ModifyOrderShortMessageCapture, OrderExecutedAtPriceSizeMessageCapture, OrderExecutedMessageCapture, ReduceSizeShortMessageCapture, TimeMessageCapture, TradeLongMessageCapture, TradeShortMessageCapture, TradingStatusMessageCapture }

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
