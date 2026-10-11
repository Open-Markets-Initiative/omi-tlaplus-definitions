------------------- MODULE JnxEquities_Pts_v1_6_Captures -------------------
(***************************************************************************)
(* Recorded Japannext Securities Proprietary Trading System v1.6 packets,  *)
(* as the bytes they were captured as. Each one decodes, consumes the      *)
(* whole packet, and encodes back to exactly the bytes it was read from.   *)
(***************************************************************************)
EXTENDS JnxEquities_Pts_v1_6

OrderDeletedMessageCapture ==
    << 49, 54, 55, 48, 55, 56, 56, 57, 48, 52, 0, 0, 0, 0, 0, 0,
       98, 123, 0, 1, 0, 13, 68, 2, 52, 225, 96, 2, 206, 102, 218, 13,
       225, 32, 253 >>

OrderExecutedMessageCapture ==
    << 49, 54, 55, 48, 55, 56, 56, 57, 48, 52, 0, 0, 0, 0, 0, 0,
       130, 9, 0, 1, 0, 25, 69, 42, 35, 59, 64, 2, 206, 102, 218, 13,
       224, 240, 1, 0, 0, 0, 100, 2, 206, 102, 218, 13, 224, 240, 65 >>

OrderReplacedMessageCapture ==
    << 49, 54, 55, 48, 55, 56, 56, 57, 48, 52, 0, 0, 0, 0, 0, 0,
       48, 67, 0, 1, 0, 29, 85, 15, 25, 235, 200, 2, 206, 102, 218, 13,
       224, 240, 10, 2, 206, 102, 218, 13, 224, 240, 48, 0, 0, 5, 120, 0,
       0, 19, 134 >>

SecondsMessageCapture ==
    << 49, 54, 55, 48, 55, 56, 56, 57, 48, 52, 0, 0, 0, 0, 0, 0,
       141, 113, 0, 2, 0, 5, 84, 0, 0, 225, 0, 0, 10, 83, 0, 0,
       19, 136, 68, 65, 89, 32, 77 >>

ShortSellingPriceRestrictionStateMessageCapture ==
    << 49, 54, 55, 48, 55, 56, 56, 57, 48, 52, 0, 0, 0, 0, 0, 0,
       127, 179, 0, 1, 0, 14, 89, 51, 145, 86, 248, 0, 0, 37, 184, 68,
       65, 89, 32, 49 >>

Captures == { OrderDeletedMessageCapture, OrderExecutedMessageCapture, OrderReplacedMessageCapture, SecondsMessageCapture, ShortSellingPriceRestrictionStateMessageCapture }

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
