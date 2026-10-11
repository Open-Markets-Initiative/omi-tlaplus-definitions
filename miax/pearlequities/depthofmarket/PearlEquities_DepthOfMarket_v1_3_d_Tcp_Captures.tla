---------- MODULE PearlEquities_DepthOfMarket_v1_3_d_Tcp_Captures ----------
(***************************************************************************)
(* Recorded Miami International Holdings Depth Of Market v1.3.d packets,   *)
(* as the bytes they were captured as. Each one decodes, consumes the      *)
(* whole packet, and encodes back to exactly the bytes it was read from.   *)
(***************************************************************************)
EXTENDS PearlEquities_DepthOfMarket_v1_3_d_Tcp

AddOrderMessageCapture ==
    << 59, 6, 0, 0, 0, 0, 0, 0, 46, 0, 3, 1, 20, 136, 97, 11,
       0, 111, 0, 0, 32, 46, 8, 0, 0, 192, 33, 83, 32, 66, 64, 219,
       28, 4, 0, 0, 0, 0, 100, 0, 0, 0, 32, 32, 32, 32 >>

DeleteOrderMessageCapture ==
    << 33, 8, 0, 0, 0, 0, 0, 0, 29, 0, 3, 1, 23, 195, 247, 34,
       0, 92, 0, 0, 26, 7, 16, 0, 0, 192, 33, 83, 26 >>

ModifyOrderMessageCapture ==
    << 234, 6, 0, 0, 0, 0, 0, 0, 42, 0, 3, 1, 21, 33, 138, 46,
       0, 200, 0, 0, 22, 5, 6, 0, 0, 192, 33, 83, 22, 224, 212, 85,
       9, 0, 0, 0, 0, 232, 3, 0, 0, 1 >>

OrderExecutionMessageCapture ==
    << 228, 6, 0, 0, 0, 0, 0, 0, 50, 0, 3, 1, 24, 93, 139, 152,
       4, 39, 0, 0, 34, 62, 23, 0, 0, 192, 33, 83, 34, 38, 0, 0,
       0, 0, 0, 64, 34, 208, 232, 150, 0, 0, 0, 0, 0, 1, 0, 0,
       0, 1 >>

SecurityTradingStatusNotificationMessageCapture ==
    << 55, 6, 0, 0, 0, 0, 0, 0, 24, 0, 3, 1, 4, 255, 32, 9,
       0, 246, 0, 0, 32, 2, 3, 78 >>

SystemTimeMessageCapture ==
    << 96, 7, 0, 0, 0, 0, 0, 0, 17, 0, 3, 1, 49, 88, 184, 228,
       100 >>

TradeMessageCapture ==
    << 205, 8, 0, 0, 0, 0, 0, 0, 43, 0, 3, 1, 10, 238, 56, 39,
       0, 22, 0, 0, 24, 1, 0, 0, 0, 0, 0, 64, 24, 0, 92, 62,
       1, 0, 0, 0, 0, 0, 232, 3, 0, 0, 0 >>

Captures == { AddOrderMessageCapture, DeleteOrderMessageCapture, ModifyOrderMessageCapture, OrderExecutionMessageCapture, SecurityTradingStatusNotificationMessageCapture, SystemTimeMessageCapture, TradeMessageCapture }

(* Every recorded packet reads, reads whole, and writes back unchanged *)
CapturesRoundTrip ==
    \A bytes \in Captures :
        LET read == DecodeTcpPacket(bytes)
        IN  /\ read.ok
            /\ read.rest = << >>
            /\ EncodeTcpPacket(read.value) = bytes

(* Every recorded packet is bytes *)
CapturesAreBytes == \A bytes \in Captures : \A i \in 1 .. Len(bytes) : bytes[i] \in Byte

=============================================================================
