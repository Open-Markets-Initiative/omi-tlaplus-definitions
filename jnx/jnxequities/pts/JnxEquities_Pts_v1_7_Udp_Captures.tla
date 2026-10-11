----------------- MODULE JnxEquities_Pts_v1_7_Udp_Captures -----------------
(***************************************************************************)
(* Recorded Japannext Securities Proprietary Trading System v1.7 packets,  *)
(* as the bytes they were captured as. Each one decodes, consumes the      *)
(* whole packet, and encodes back to exactly the bytes it was read from.   *)
(***************************************************************************)
EXTENDS JnxEquities_Pts_v1_7_Udp

OrderAddedWithoutAttributesMessageCapture ==
    << 49, 54, 57, 55, 54, 53, 57, 50, 56, 52, 0, 0, 0, 0, 0, 0,
       49, 33, 0, 1, 0, 30, 65, 1, 89, 172, 48, 2, 206, 192, 11, 193,
       100, 76, 1, 66, 0, 0, 3, 232, 56, 48, 53, 56, 68, 65, 89, 32,
       0, 1, 22, 172 >>

OrderDeletedMessageCapture ==
    << 49, 54, 57, 55, 54, 53, 57, 50, 56, 52, 0, 0, 0, 0, 0, 0,
       183, 75, 0, 1, 0, 13, 68, 35, 240, 69, 136, 2, 206, 192, 11, 193,
       100, 205, 238 >>

OrderExecutedMessageCapture ==
    << 49, 54, 57, 55, 54, 53, 57, 50, 56, 52, 0, 0, 0, 0, 0, 0,
       49, 45, 0, 1, 0, 25, 69, 5, 36, 178, 56, 2, 206, 192, 11, 193,
       100, 76, 11, 0, 0, 0, 1, 2, 206, 192, 11, 193, 100, 76, 1 >>

OrderReplacedMessageCapture ==
    << 49, 54, 57, 55, 54, 53, 57, 50, 56, 52, 0, 0, 0, 0, 0, 0,
       183, 83, 0, 1, 0, 29, 85, 36, 27, 18, 144, 2, 206, 192, 11, 193,
       100, 205, 243, 2, 206, 192, 11, 193, 100, 205, 243, 0, 0, 0, 100, 0,
       0, 146, 74 >>

SecondsMessageCapture ==
    << 49, 54, 57, 55, 54, 53, 57, 50, 56, 52, 0, 0, 0, 0, 0, 0,
       72, 249, 0, 1, 0, 5, 84, 0, 0, 117, 245 >>

ShortSellingPriceRestrictionStateMessageCapture ==
    << 49, 54, 57, 55, 54, 53, 57, 50, 56, 52, 0, 0, 0, 0, 0, 0,
       49, 22, 0, 1, 0, 14, 89, 0, 0, 19, 136, 51, 54, 50, 56, 68,
       65, 89, 32, 49 >>

SystemEventMessageCapture ==
    << 49, 54, 57, 55, 54, 53, 57, 50, 56, 52, 0, 0, 0, 0, 0, 0,
       49, 32, 0, 1, 0, 10, 83, 0, 0, 19, 136, 68, 65, 89, 32, 81 >>

TradingStateMessageCapture ==
    << 49, 54, 57, 55, 54, 53, 57, 50, 56, 52, 0, 0, 0, 0, 0, 0,
       49, 18, 0, 2, 0, 5, 84, 0, 0, 105, 124, 0, 14, 72, 12, 124,
       152, 32, 49, 51, 50, 52, 68, 65, 89, 32, 86 >>

Captures == { OrderAddedWithoutAttributesMessageCapture, OrderDeletedMessageCapture, OrderExecutedMessageCapture, OrderReplacedMessageCapture, SecondsMessageCapture, ShortSellingPriceRestrictionStateMessageCapture, SystemEventMessageCapture, TradingStateMessageCapture }

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
