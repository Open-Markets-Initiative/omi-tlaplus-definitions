------------ MODULE BlueEquities_MemoirDepthFeed_v1_3_Captures -------------
(***************************************************************************)
(* Recorded Blue Ocean Technologies Member Order Information Record Depth  *)
(* Feed v1.3 packets, as the bytes they were captured as. Each one         *)
(* decodes, consumes the whole packet, and encodes back to exactly the     *)
(* bytes it was read from.                                                 *)
(***************************************************************************)
EXTENDS BlueEquities_MemoirDepthFeed_v1_3

HeartbeatCapture ==
    << 0, 18, 66, 79, 65, 84, 104, 171, 116, 85, 0, 0, 0, 0, 0, 0,
       115, 244 >>

InstrumentDirectoryMessageCapture ==
    << 2, 18, 66, 79, 65, 84, 104, 172, 197, 232, 0, 0, 0, 0, 0, 0,
       4, 110, 0, 1, 0, 42, 0, 36, 1, 2, 1, 3, 24, 95, 28, 37,
       181, 200, 152, 20, 0, 17, 65, 80, 82, 90, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 0, 39, 16 >>

OrderAddedMessageCapture ==
    << 2, 18, 66, 79, 65, 84, 104, 171, 116, 85, 0, 0, 0, 0, 0, 134,
       205, 105, 0, 1, 0, 37, 0, 31, 10, 2, 1, 3, 24, 94, 220, 186,
       230, 79, 17, 206, 15, 219, 0, 0, 0, 0, 1, 62, 196, 17, 66, 0,
       0, 1, 44, 0, 0, 0, 0, 10, 239, 213, 208 >>

OrderDeletedMessageCapture ==
    << 2, 18, 66, 79, 65, 84, 104, 171, 116, 85, 0, 0, 0, 0, 0, 134,
       205, 99, 0, 1, 0, 24, 0, 18, 11, 2, 1, 3, 24, 94, 220, 186,
       230, 1, 19, 214, 10, 225, 0, 0, 0, 0, 0, 202, 109, 127 >>

OrderExecutedMessageCapture ==
    << 2, 18, 66, 79, 65, 84, 104, 171, 116, 85, 0, 0, 0, 0, 0, 134,
       207, 184, 0, 1, 0, 44, 0, 38, 13, 2, 1, 3, 24, 94, 220, 186,
       248, 12, 82, 201, 40, 180, 0, 0, 0, 0, 0, 160, 128, 210, 7, 0,
       0, 0, 0, 0, 14, 28, 0, 0, 0, 30, 0, 0, 0, 0, 0, 122,
       18, 0 >>

OrderReducedMessageCapture ==
    << 2, 18, 66, 79, 65, 84, 104, 171, 116, 85, 0, 0, 0, 0, 0, 134,
       205, 230, 0, 1, 0, 28, 0, 22, 12, 2, 1, 3, 24, 94, 220, 186,
       234, 56, 72, 101, 26, 190, 0, 0, 0, 0, 1, 62, 185, 31, 0, 0,
       0, 2 >>

SecurityTradingStatusMessageCapture ==
    << 2, 18, 66, 79, 65, 84, 104, 172, 197, 232, 0, 0, 0, 0, 0, 0,
       8, 140, 0, 1, 0, 18, 0, 12, 3, 2, 1, 3, 24, 95, 28, 37,
       181, 234, 7, 234, 53, 143, 72, 65 >>

TradingSessionStatusMessageCapture ==
    << 2, 18, 66, 79, 65, 84, 104, 171, 116, 85, 0, 0, 0, 0, 0, 0,
       92, 55, 0, 1, 0, 15, 0, 9, 5, 2, 1, 3, 24, 94, 217, 116,
       181, 43, 66, 48, 50 >>

Captures == { HeartbeatCapture, InstrumentDirectoryMessageCapture, OrderAddedMessageCapture, OrderDeletedMessageCapture, OrderExecutedMessageCapture, OrderReducedMessageCapture, SecurityTradingStatusMessageCapture, TradingSessionStatusMessageCapture }

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
