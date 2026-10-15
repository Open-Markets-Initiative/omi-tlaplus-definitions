------------ MODULE MemxEquities_MemoirDepthFeed_v1_3_Captures -------------
(***************************************************************************)
(* Recorded The Members Exchange Memoir Depth Feed v1.3 packets, as the    *)
(* bytes they were captured as. Each one decodes, consumes the whole       *)
(* packet, and encodes back to exactly the bytes it was read from.         *)
(***************************************************************************)
EXTENDS MemxEquities_MemoirDepthFeed_v1_3

HeartbeatCapture ==
    << 0, 18, 85, 83, 69, 49, 100, 228, 134, 200, 0, 0, 0, 0, 0, 21,
       232, 144 >>

InstrumentDirectoryMessageCapture ==
    << 2, 18, 85, 83, 69, 49, 100, 228, 134, 200, 0, 0, 0, 0, 0, 0,
       2, 55, 0, 1, 0, 42, 0, 36, 1, 2, 1, 3, 23, 125, 172, 45,
       86, 113, 70, 188, 0, 217, 65, 71, 90, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 0, 39, 16 >>

OrderAddedMessageCapture ==
    << 2, 18, 85, 83, 69, 49, 100, 228, 134, 200, 0, 0, 0, 0, 0, 20,
       238, 171, 0, 1, 0, 37, 0, 31, 10, 2, 1, 3, 23, 125, 183, 175,
       166, 103, 58, 64, 31, 60, 0, 0, 0, 0, 1, 62, 160, 106, 83, 0,
       0, 3, 132, 0, 0, 0, 0, 6, 62, 130, 192 >>

OrderDeletedMessageCapture ==
    << 2, 18, 85, 83, 69, 49, 100, 228, 134, 200, 0, 0, 0, 0, 0, 20,
       238, 242, 0, 1, 0, 24, 0, 18, 11, 2, 1, 3, 23, 125, 183, 175,
       166, 108, 77, 14, 11, 68, 0, 0, 0, 0, 1, 7, 105, 34 >>

OrderExecutedMessageCapture ==
    << 2, 18, 85, 83, 69, 49, 100, 228, 134, 200, 0, 0, 0, 0, 0, 82,
       188, 232, 0, 1, 0, 44, 0, 38, 13, 2, 1, 3, 23, 125, 183, 236,
       40, 25, 253, 83, 60, 166, 0, 0, 0, 0, 2, 173, 98, 232, 20, 0,
       0, 0, 0, 0, 7, 246, 0, 0, 0, 1, 0, 0, 0, 0, 1, 96,
       239, 144 >>

OrderReducedMessageCapture ==
    << 2, 18, 85, 83, 69, 49, 100, 228, 134, 200, 0, 0, 0, 0, 0, 144,
       228, 192, 0, 1, 0, 28, 0, 22, 12, 2, 1, 3, 23, 125, 184, 40,
       221, 221, 4, 141, 19, 14, 0, 0, 0, 0, 4, 26, 114, 77, 0, 0,
       0, 200 >>

RegShoRestrictionMessageCapture ==
    << 2, 18, 85, 83, 69, 49, 100, 228, 134, 200, 0, 0, 0, 0, 0, 39,
       152, 4, 0, 1, 0, 17, 0, 11, 2, 2, 1, 3, 23, 125, 183, 191,
       5, 242, 215, 196, 9, 84, 1 >>

SecurityTradingStatusMessageCapture ==
    << 2, 18, 85, 83, 69, 49, 100, 228, 134, 200, 0, 0, 0, 0, 0, 82,
       182, 119, 0, 1, 0, 18, 0, 12, 3, 2, 1, 3, 23, 125, 183, 236,
       37, 7, 140, 91, 1, 100, 80, 82 >>

SessionShutdownCapture ==
    << 1, 18, 85, 83, 69, 49, 100, 227, 53, 104, 0, 0, 0, 0, 12, 220,
       153, 245 >>

TradeMessageCapture ==
    << 2, 18, 85, 83, 69, 49, 100, 228, 134, 200, 0, 0, 0, 0, 0, 20,
       253, 2, 0, 1, 0, 36, 0, 30, 14, 2, 1, 3, 23, 125, 183, 175,
       167, 114, 33, 21, 0, 17, 8, 0, 0, 0, 0, 0, 1, 64, 0, 0,
       0, 3, 0, 0, 0, 0, 10, 141, 184, 160 >>

TradingSessionStatusMessageCapture ==
    << 2, 18, 85, 83, 69, 49, 100, 228, 134, 200, 0, 0, 0, 0, 0, 20,
       238, 170, 0, 1, 0, 15, 0, 9, 5, 2, 1, 3, 23, 125, 183, 175,
       166, 101, 189, 230, 50 >>

Captures == { HeartbeatCapture, InstrumentDirectoryMessageCapture, OrderAddedMessageCapture, OrderDeletedMessageCapture, OrderExecutedMessageCapture, OrderReducedMessageCapture, RegShoRestrictionMessageCapture, SecurityTradingStatusMessageCapture, SessionShutdownCapture, TradeMessageCapture, TradingSessionStatusMessageCapture }

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
