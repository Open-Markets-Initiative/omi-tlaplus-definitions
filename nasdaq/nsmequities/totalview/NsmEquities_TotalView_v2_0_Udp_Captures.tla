-------------- MODULE NsmEquities_TotalView_v2_0_Udp_Captures --------------
(***************************************************************************)
(* Recorded National Association of Securities Dealers Automated           *)
(* Quotations (Nasdaq) TotalView Itch v2.0 packets, as the bytes they were *)
(* captured as. Each one decodes, consumes the whole packet, and encodes   *)
(* back to exactly the bytes it was read from.                             *)
(***************************************************************************)
EXTENDS NsmEquities_TotalView_v2_0_Udp

AddOrderMessageCapture ==
    << 83, 48, 49, 48, 51, 48, 51, 118, 50, 0, 0, 0, 0, 1, 1, 0,
       0, 42, 50, 53, 50, 48, 51, 56, 52, 55, 65, 32, 32, 32, 32, 32,
       32, 32, 52, 50, 66, 32, 32, 32, 32, 32, 49, 68, 69, 76, 76, 32,
       32, 32, 32, 32, 32, 32, 49, 48, 48, 48, 48, 89 >>

OrderCancelMessageCapture ==
    << 83, 48, 49, 48, 51, 48, 51, 118, 50, 0, 0, 0, 0, 1, 1, 0,
       0, 24, 50, 53, 50, 49, 49, 57, 56, 50, 88, 32, 32, 32, 32, 32,
       32, 32, 52, 50, 32, 32, 32, 32, 32, 49 >>

OrderExecutedMessageCapture ==
    << 83, 48, 49, 48, 51, 48, 51, 118, 50, 0, 0, 0, 0, 1, 1, 0,
       0, 33, 50, 53, 50, 50, 54, 51, 48, 54, 69, 32, 32, 32, 32, 32,
       32, 32, 54, 53, 32, 32, 32, 49, 48, 48, 32, 32, 32, 32, 32, 32,
       32, 32, 49 >>

SystemEventMessageCapture ==
    << 83, 48, 49, 48, 51, 48, 51, 118, 50, 0, 0, 0, 0, 1, 1, 0,
       0, 10, 50, 53, 50, 48, 48, 48, 48, 49, 83, 83 >>

TradeMessageCapture ==
    << 83, 48, 49, 48, 51, 48, 51, 118, 50, 0, 0, 0, 0, 164, 1, 0,
       0, 50, 50, 53, 51, 57, 54, 56, 48, 56, 80, 32, 32, 32, 32, 32,
       32, 49, 50, 53, 83, 32, 32, 32, 49, 48, 48, 83, 80, 89, 32, 32,
       32, 32, 32, 32, 32, 57, 49, 49, 57, 48, 48, 32, 32, 32, 32, 32,
       32, 32, 32, 51 >>

Captures == { AddOrderMessageCapture, OrderCancelMessageCapture, OrderExecutedMessageCapture, SystemEventMessageCapture, TradeMessageCapture }

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
