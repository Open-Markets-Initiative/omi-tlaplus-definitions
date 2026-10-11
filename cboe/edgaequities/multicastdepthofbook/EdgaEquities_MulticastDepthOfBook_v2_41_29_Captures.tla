-------- MODULE EdgaEquities_MulticastDepthOfBook_v2_41_29_Captures --------
(***************************************************************************)
(* Recorded Chicago Board Options Exchange Multicast Depth Of Book         *)
(* v2.41.29 packets, as the bytes they were captured as. Each one decodes, *)
(* consumes the whole packet, and encodes back to exactly the bytes it was *)
(* read from.                                                              *)
(***************************************************************************)
EXTENDS EdgaEquities_MulticastDepthOfBook_v2_41_29

AddOrderLongMessageCapture ==
    << 42, 0, 1, 21, 107, 198, 0, 0, 34, 33, 56, 25, 154, 0, 222, 187,
       74, 131, 46, 142, 192, 38, 66, 0, 25, 0, 0, 80, 83, 68, 78, 32,
       32, 62, 38, 0, 0, 0, 0, 0, 0, 1 >>

AddOrderShortMessageCapture ==
    << 34, 0, 1, 17, 37, 49, 0, 0, 26, 34, 24, 198, 154, 59, 23, 100,
       74, 106, 54, 25, 114, 31, 66, 144, 1, 77, 65, 84, 32, 32, 32, 18,
       8, 1 >>

DeleteOrderMessageCapture ==
    << 22, 0, 1, 2, 69, 37, 0, 0, 14, 41, 80, 21, 29, 0, 242, 142,
       141, 12, 148, 226, 11, 4 >>

ModifyOrderLongMessageCapture ==
    << 35, 0, 1, 4, 189, 135, 0, 0, 27, 39, 96, 64, 195, 0, 14, 141,
       13, 25, 16, 29, 179, 7, 100, 0, 0, 0, 232, 187, 205, 1, 0, 0,
       0, 0, 1 >>

ModifyOrderShortMessageCapture ==
    << 27, 0, 1, 29, 233, 142, 0, 0, 19, 40, 80, 224, 16, 0, 220, 29,
       74, 181, 30, 120, 93, 53, 100, 0, 85, 9, 1 >>

OrderExecutedAtPriceSizeMessageCapture ==
    << 46, 0, 1, 26, 70, 91, 1, 0, 38, 36, 200, 65, 238, 12, 42, 218,
       139, 162, 100, 160, 226, 47, 1, 0, 0, 0, 187, 2, 0, 0, 110, 158,
       146, 98, 218, 1, 0, 0, 224, 241, 5, 0, 0, 0, 0, 0 >>

OrderExecutedMessageCapture ==
    << 34, 0, 1, 24, 132, 219, 1, 0, 26, 35, 208, 119, 23, 0, 23, 193,
       14, 150, 232, 101, 59, 44, 100, 0, 0, 0, 182, 26, 214, 228, 181, 1,
       0, 0 >>

ReduceSizeShortMessageCapture ==
    << 24, 0, 1, 24, 11, 220, 1, 0, 16, 38, 0, 190, 135, 0, 74, 192,
       14, 150, 232, 101, 59, 44, 232, 3 >>

TimeMessageCapture ==
    << 28, 0, 2, 25, 81, 195, 0, 0, 6, 32, 152, 133, 0, 0, 14, 41,
       80, 218, 17, 0, 89, 73, 74, 156, 38, 3, 15, 46 >>

TradeLongMessageCapture ==
    << 49, 0, 1, 23, 196, 207, 0, 0, 41, 42, 64, 185, 230, 6, 206, 79,
       202, 143, 170, 200, 103, 42, 66, 44, 1, 0, 0, 83, 72, 32, 32, 32,
       32, 94, 39, 2, 0, 0, 0, 0, 0, 233, 210, 247, 165, 163, 1, 0,
       0 >>

TradeShortMessageCapture ==
    << 41, 0, 1, 5, 152, 33, 0, 0, 33, 43, 240, 77, 43, 0, 20, 56,
       77, 31, 78, 186, 134, 9, 66, 65, 0, 67, 68, 78, 83, 32, 32, 100,
       88, 174, 89, 87, 58, 91, 0, 0, 0 >>

TradingStatusMessageCapture ==
    << 26, 0, 1, 24, 42, 225, 1, 0, 18, 49, 0, 177, 247, 6, 83, 79,
       80, 65, 32, 32, 32, 32, 84, 49, 32, 32 >>

Captures == { AddOrderLongMessageCapture, AddOrderShortMessageCapture, DeleteOrderMessageCapture, ModifyOrderLongMessageCapture, ModifyOrderShortMessageCapture, OrderExecutedAtPriceSizeMessageCapture, OrderExecutedMessageCapture, ReduceSizeShortMessageCapture, TimeMessageCapture, TradeLongMessageCapture, TradeShortMessageCapture, TradingStatusMessageCapture }

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
