------ MODULE BzxEquities_MulticastDepthOfBook_Pitch_v2_20_4_Captures ------
(***************************************************************************)
(* Recorded Chicago Board Options Exchange Multicast Depth Of Book v2.20.4 *)
(* packets, as the bytes they were captured as. Each one decodes, consumes *)
(* the whole packet, and encodes back to exactly the bytes it was read     *)
(* from.                                                                   *)
(***************************************************************************)
EXTENDS BzxEquities_MulticastDepthOfBook_Pitch_v2_20_4

AddOrderLongMessageCapture ==
    << 48, 0, 2, 1, 9, 0, 0, 0, 6, 32, 92, 41, 1, 0, 34, 33,
       192, 65, 92, 41, 7, 16, 116, 233, 234, 158, 104, 3, 66, 100, 0, 0,
       0, 65, 32, 32, 32, 32, 32, 25, 0, 0, 0, 0, 0, 0, 0, 1 >>

AddOrderShortMessageCapture ==
    << 40, 0, 2, 1, 3, 0, 0, 0, 6, 32, 19, 41, 1, 0, 26, 34,
       240, 82, 121, 32, 1, 16, 116, 233, 234, 158, 104, 3, 66, 100, 0, 65,
       32, 32, 32, 32, 32, 208, 7, 1 >>

DeleteOrderMessageCapture ==
    << 28, 0, 2, 1, 23, 0, 0, 0, 6, 32, 190, 41, 1, 0, 14, 41,
       112, 223, 50, 0, 17, 16, 116, 233, 234, 158, 104, 3 >>

ModifyOrderLongMessageCapture ==
    << 41, 0, 2, 1, 27, 0, 0, 0, 6, 32, 221, 41, 1, 0, 27, 39,
       128, 21, 175, 31, 18, 16, 116, 233, 234, 158, 104, 3, 232, 3, 0, 0,
       26, 0, 0, 0, 0, 0, 0, 0, 1 >>

ModifyOrderShortMessageCapture ==
    << 33, 0, 2, 1, 21, 0, 0, 0, 6, 32, 179, 41, 1, 0, 19, 40,
       160, 99, 175, 31, 17, 16, 116, 233, 234, 158, 104, 3, 144, 1, 213, 7,
       1 >>

OrderExecutedMessageCapture ==
    << 40, 0, 2, 1, 5, 0, 0, 0, 6, 32, 42, 41, 1, 0, 26, 35,
       152, 4, 163, 16, 1, 16, 116, 233, 234, 158, 104, 3, 100, 0, 0, 0,
       1, 184, 224, 53, 34, 0, 0, 0 >>

ReduceSizeShortMessageCapture ==
    << 30, 0, 2, 1, 33, 0, 0, 0, 6, 32, 48, 42, 1, 0, 16, 38,
       48, 119, 178, 5, 19, 16, 116, 233, 234, 158, 104, 3, 100, 0 >>

TimeMessageCapture ==
    << 40, 0, 2, 1, 3, 0, 0, 0, 6, 32, 19, 41, 1, 0, 26, 34,
       240, 82, 121, 32, 1, 16, 116, 233, 234, 158, 104, 3, 66, 100, 0, 65,
       32, 32, 32, 32, 32, 208, 7, 1 >>

TradeLongMessageCapture ==
    << 122, 0, 4, 1, 15, 0, 0, 0, 6, 32, 133, 41, 1, 0, 26, 35,
       232, 208, 182, 23, 11, 16, 116, 233, 234, 158, 104, 3, 100, 0, 0, 0,
       4, 184, 224, 53, 34, 0, 0, 0, 41, 42, 232, 208, 182, 23, 15, 16,
       116, 233, 234, 158, 104, 3, 66, 100, 0, 0, 0, 65, 32, 32, 32, 32,
       32, 25, 0, 0, 0, 0, 0, 0, 0, 5, 184, 224, 53, 34, 0, 0,
       0, 41, 42, 232, 208, 182, 23, 16, 16, 116, 233, 234, 158, 104, 3, 66,
       200, 0, 0, 0, 65, 32, 32, 32, 32, 32, 25, 0, 0, 0, 0, 0,
       0, 0, 6, 184, 224, 53, 34, 0, 0, 0 >>

TradeShortMessageCapture ==
    << 47, 0, 2, 1, 7, 0, 0, 0, 6, 32, 72, 41, 1, 0, 33, 43,
       240, 43, 166, 36, 6, 16, 116, 233, 234, 158, 104, 3, 66, 100, 0, 65,
       32, 32, 32, 32, 32, 209, 7, 2, 184, 224, 53, 34, 0, 0, 0 >>

Captures == { AddOrderLongMessageCapture, AddOrderShortMessageCapture, DeleteOrderMessageCapture, ModifyOrderLongMessageCapture, ModifyOrderShortMessageCapture, OrderExecutedMessageCapture, ReduceSizeShortMessageCapture, TimeMessageCapture, TradeLongMessageCapture, TradeShortMessageCapture }

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
