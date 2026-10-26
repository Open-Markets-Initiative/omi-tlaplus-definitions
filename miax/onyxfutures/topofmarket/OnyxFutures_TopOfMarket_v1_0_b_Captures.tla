-------------- MODULE OnyxFutures_TopOfMarket_v1_0_b_Captures --------------
(***************************************************************************)
(* Recorded Miami International Holdings Top Of Market v1.0.b packets, as  *)
(* the bytes they were captured as. Each one decodes, consumes the whole   *)
(* packet, and encodes back to exactly the bytes it was read from.         *)
(***************************************************************************)
EXTENDS OnyxFutures_TopOfMarket_v1_0_b

BestBidAndOfferMessageCapture ==
    << 96, 3, 0, 0, 0, 0, 0, 0, 49, 0, 3, 1, 15, 58, 119, 113,
       45, 99, 247, 76, 24, 28, 0, 0, 2, 0, 249, 2, 149, 0, 0, 0,
       0, 200, 0, 0, 0, 224, 165, 127, 98, 1, 0, 0, 0, 1, 0, 0,
       0 >>

HeartbeatCapture ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 12, 0, 0, 0 >>

InstrumentTradingStatusNotificationMessageCapture ==
    << 159, 3, 0, 0, 0, 0, 0, 0, 27, 0, 3, 1, 4, 22, 153, 133,
       10, 62, 249, 76, 24, 16, 0, 0, 2, 6, 3 >>

SystemStateMessageCapture ==
    << 2, 4, 0, 0, 0, 0, 0, 0, 31, 0, 3, 1, 3, 14, 158, 138,
       239, 65, 2, 77, 24, 84, 79, 77, 49, 46, 48, 32, 32, 1, 67 >>

Captures == { BestBidAndOfferMessageCapture, HeartbeatCapture, InstrumentTradingStatusNotificationMessageCapture, SystemStateMessageCapture }

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
