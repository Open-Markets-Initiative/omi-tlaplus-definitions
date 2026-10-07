-------------- MODULE NsmEquities_Orders_v5_0_Client_Captures --------------
(***************************************************************************)
(* Recorded National Association of Securities Dealers Automated           *)
(* Quotations (Nasdaq) Orders v5.0 packets, as the bytes they were         *)
(* captured as. Each one decodes, consumes the whole packet, and encodes   *)
(* back to exactly the bytes it was read from.                             *)
(***************************************************************************)
EXTENDS NsmEquities_Orders_v5_0_Client

CancelOrderMessageCapture ==
    << 0, 10, 85, 88, 0, 117, 46, 113, 0, 0, 0, 0 >>

ClientHeartbeatCapture ==
    << 0, 1, 82 >>

EnterOrderMessageCapture ==
    << 0, 54, 85, 79, 0, 0, 0, 113, 84, 0, 0, 0, 225, 67, 86, 76,
       84, 32, 32, 32, 32, 0, 0, 0, 0, 0, 9, 157, 184, 48, 89, 65,
       78, 78, 72, 56, 70, 85, 66, 56, 73, 86, 32, 32, 32, 32, 32, 32,
       0, 6, 5, 2, 76, 73, 77, 69 >>

Captures == { CancelOrderMessageCapture, ClientHeartbeatCapture, EnterOrderMessageCapture }

(* Every recorded packet reads, reads whole, and writes back unchanged *)
CapturesRoundTrip ==
    \A bytes \in Captures :
        LET read == DecodeClientPacket(bytes)
        IN  /\ read.ok
            /\ read.rest = << >>
            /\ EncodeClientPacket(read.value) = bytes

(* Every recorded packet is bytes *)
CapturesAreBytes == \A bytes \in Captures : \A i \in 1 .. Len(bytes) : bytes[i] \in Byte

=============================================================================
