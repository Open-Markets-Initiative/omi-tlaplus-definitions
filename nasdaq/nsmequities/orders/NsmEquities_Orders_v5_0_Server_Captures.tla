-------------- MODULE NsmEquities_Orders_v5_0_Server_Captures --------------
(***************************************************************************)
(* Recorded National Association of Securities Dealers Automated           *)
(* Quotations (Nasdaq) Orders v5.0 packets, as the bytes they were         *)
(* captured as. Each one decodes, consumes the whole packet, and encodes   *)
(* back to exactly the bytes it was read from.                             *)
(***************************************************************************)
EXTENDS NsmEquities_Orders_v5_0_Server

CanceledMessageCapture ==
    << 0, 19, 83, 67, 0, 0, 40, 155, 77, 104, 19, 23, 0, 117, 58, 141,
       0, 0, 0, 40, 85 >>

OrderAcceptedMessageCapture ==
    << 0, 74, 83, 65, 0, 0, 40, 155, 77, 100, 175, 135, 0, 117, 58, 141,
       66, 0, 0, 0, 40, 65, 68, 66, 69, 32, 32, 32, 32, 0, 0, 0,
       0, 0, 72, 231, 72, 53, 89, 0, 0, 0, 0, 15, 86, 180, 245, 65,
       78, 78, 76, 55, 54, 56, 50, 55, 48, 49, 32, 32, 32, 32, 32, 32,
       32, 0, 9, 5, 2, 77, 76, 82, 79, 2, 18, 48 >>

ServerHeartbeatCapture ==
    << 0, 1, 72 >>

Captures == { CanceledMessageCapture, OrderAcceptedMessageCapture, ServerHeartbeatCapture }

(* Every recorded packet reads, reads whole, and writes back unchanged *)
CapturesRoundTrip ==
    \A bytes \in Captures :
        LET read == DecodeServerPacket(bytes)
        IN  /\ read.ok
            /\ read.rest = << >>
            /\ EncodeServerPacket(read.value) = bytes

(* Every recorded packet is bytes *)
CapturesAreBytes == \A bytes \in Captures : \A i \in 1 .. Len(bytes) : bytes[i] \in Byte

=============================================================================
