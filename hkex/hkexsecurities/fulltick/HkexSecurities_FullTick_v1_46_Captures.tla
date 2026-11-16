-------------- MODULE HkexSecurities_FullTick_v1_46_Captures ---------------
(***************************************************************************)
(* Recorded Hong Kong Exchanges and Clearing Orion Market Data Cash        *)
(* FullTick v1.46 packets, as the bytes they were captured as. Each one    *)
(* decodes, consumes the whole packet, and encodes back to exactly the     *)
(* bytes it was read from.                                                 *)
(***************************************************************************)
EXTENDS HkexSecurities_FullTick_v1_46

AddOrderMessageCapture ==
    << 48, 0, 1, 0, 12, 237, 86, 1, 128, 164, 169, 7, 162, 251, 225, 24,
       32, 0, 30, 0, 67, 30, 0, 0, 2, 5, 149, 172, 0, 0, 0, 0,
       208, 182, 0, 0, 104, 16, 0, 0, 0, 0, 50, 94, 0, 0, 0, 0 >>

DeleteOrderMessageCapture ==
    << 36, 0, 1, 0, 4, 133, 102, 1, 0, 95, 54, 9, 162, 251, 225, 24,
       20, 0, 32, 0, 68, 10, 0, 0, 3, 106, 232, 181, 0, 0, 0, 0,
       0, 0, 0, 0 >>

ModifyOrderMessageCapture ==
    << 44, 0, 1, 0, 51, 134, 102, 1, 192, 46, 161, 9, 162, 251, 225, 24,
       28, 0, 31, 0, 66, 0, 0, 0, 3, 253, 200, 181, 0, 0, 0, 0,
       244, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0 >>

TradeMessageCapture ==
    << 48, 0, 1, 0, 36, 5, 87, 1, 128, 196, 74, 15, 162, 251, 225, 24,
       32, 0, 50, 0, 28, 5, 0, 0, 159, 4, 0, 0, 154, 186, 0, 0,
       232, 3, 0, 0, 101, 0, 0, 0, 120, 191, 82, 15, 162, 251, 225, 24 >>

TradingSessionStatusMessageCapture ==
    << 48, 0, 1, 0, 38, 0, 0, 0, 0, 32, 139, 7, 162, 251, 225, 24,
       32, 0, 20, 0, 71, 69, 77, 32, 0, 3, 30, 48, 32, 32, 32, 32,
       0, 32, 139, 7, 162, 251, 225, 24, 0, 54, 26, 94, 116, 5, 226, 24 >>

Captures == { AddOrderMessageCapture, DeleteOrderMessageCapture, ModifyOrderMessageCapture, TradeMessageCapture, TradingSessionStatusMessageCapture }

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
