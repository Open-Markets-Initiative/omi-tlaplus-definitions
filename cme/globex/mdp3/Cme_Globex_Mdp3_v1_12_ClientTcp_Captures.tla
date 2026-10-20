------------- MODULE Cme_Globex_Mdp3_v1_12_ClientTcp_Captures --------------
(***************************************************************************)
(* Recorded CME Group Market Data Platform 3 v1.12 packets, as the bytes   *)
(* they were captured as. Each one decodes, consumes the whole packet, and *)
(* encodes back to exactly the bytes it was read from.                     *)
(***************************************************************************)
EXTENDS Cme_Globex_Mdp3_v1_12_ClientTcp

MarketDataRequestCapture ==
    << 254, 202, 4, 0, 0, 0, 64, 44, 70, 123, 231, 194, 162, 22, 25, 0,
       5, 0, 205, 0, 2, 0, 0, 0, 3, 0, 0, 0, 1, 6, 0, 0,
       4, 0, 1, 120, 120, 180, 0 >>

SecurityListRequestCapture ==
    << 254, 202, 2, 0, 0, 0, 160, 253, 89, 85, 225, 194, 162, 22, 29, 0,
       5, 0, 208, 0, 2, 0, 0, 0, 1, 0, 0, 0, 1, 6, 0, 0,
       4, 0, 2, 120, 120, 180, 0, 157, 120, 180, 0 >>

SecurityStatusRequestCapture ==
    << 254, 202, 3, 0, 0, 0, 60, 154, 91, 102, 225, 194, 162, 22, 29, 0,
       5, 0, 209, 0, 2, 0, 0, 0, 2, 0, 0, 0, 1, 6, 0, 0,
       4, 0, 2, 120, 120, 180, 0, 157, 120, 180, 0 >>

SubscriberHeartbeatCapture ==
    << 254, 202, 6, 0, 0, 0, 192, 196, 87, 160, 242, 194, 162, 22, 10, 0,
       0, 0, 210, 0, 2, 0, 0, 0 >>

Captures == { MarketDataRequestCapture, SecurityListRequestCapture, SecurityStatusRequestCapture, SubscriberHeartbeatCapture }

(* Every recorded packet reads, reads whole, and writes back unchanged *)
CapturesRoundTrip ==
    \A bytes \in Captures :
        LET read == DecodeClientTcpPacket(bytes)
        IN  /\ read.ok
            /\ read.rest = << >>
            /\ EncodeClientTcpPacket(read.value) = bytes

(* Every recorded packet is bytes *)
CapturesAreBytes == \A bytes \in Captures : \A i \in 1 .. Len(bytes) : bytes[i] \in Byte

=============================================================================
