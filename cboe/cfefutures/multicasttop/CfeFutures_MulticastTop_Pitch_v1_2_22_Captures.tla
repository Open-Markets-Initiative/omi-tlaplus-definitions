---------- MODULE CfeFutures_MulticastTop_Pitch_v1_2_22_Captures -----------
(***************************************************************************)
(* Recorded Chicago Board Options Exchange Futures Multicast Top v1.2.22   *)
(* packets, as the bytes they were captured as. Each one decodes, consumes *)
(* the whole packet, and encodes back to exactly the bytes it was read     *)
(* from.                                                                   *)
(***************************************************************************)
EXTENDS CfeFutures_MulticastTop_Pitch_v1_2_22

MarketSnapshotLongMessageCapture ==
    << 69, 0, 1, 1, 0, 0, 0, 0, 61, 179, 120, 200, 152, 38, 48, 48,
       48, 48, 70, 67, 104, 63, 77, 90, 184, 124, 2, 0, 0, 0, 0, 0,
       234, 0, 0, 0, 128, 254, 33, 10, 0, 0, 0, 0, 1, 0, 0, 0,
       16, 152, 2, 0, 0, 0, 0, 0, 28, 0, 0, 0, 32, 169, 28, 0,
       0, 84, 48, 32, 32 >>

MarketSnapshotShortMessageCapture ==
    << 45, 0, 1, 1, 0, 0, 0, 0, 37, 178, 128, 50, 2, 0, 48, 48,
       48, 48, 48, 76, 0, 254, 76, 90, 0, 0, 0, 0, 0, 0, 0, 0,
       10, 5, 1, 0, 83, 55, 55, 0, 0, 83, 48, 32, 32 >>

PriceLimitsMessageCapture ==
    << 46, 1, 16, 2, 124, 0, 0, 0, 28, 190, 208, 237, 139, 26, 48, 48,
       48, 48, 70, 105, 32, 121, 245, 17, 0, 0, 0, 0, 0, 101, 99, 5,
       0, 0, 0, 0, 28, 190, 208, 237, 139, 26, 48, 48, 48, 48, 54, 74,
       128, 180, 170, 17, 0, 0, 0, 0, 64, 8, 78, 5, 0, 0, 0, 0,
       17, 180, 208, 237, 139, 26, 48, 48, 48, 48, 65, 111, 66, 255, 255, 10,
       0, 17, 180, 208, 237, 139, 26, 48, 48, 48, 48, 70, 105, 66, 40, 35,
       1, 0, 17, 180, 208, 237, 139, 26, 48, 48, 48, 48, 70, 105, 66, 40,
       35, 2, 0, 17, 180, 208, 237, 139, 26, 48, 48, 48, 48, 70, 105, 66,
       40, 35, 3, 0, 17, 180, 208, 237, 139, 26, 48, 48, 48, 48, 70, 105,
       66, 40, 35, 4, 0, 17, 180, 208, 237, 139, 26, 48, 48, 48, 48, 70,
       105, 66, 40, 35, 5, 0, 17, 180, 208, 237, 139, 26, 48, 48, 48, 48,
       70, 105, 66, 40, 35, 6, 0, 17, 180, 208, 237, 139, 26, 48, 48, 48,
       48, 70, 105, 66, 40, 35, 7, 0, 17, 180, 208, 237, 139, 26, 48, 48,
       48, 48, 70, 105, 66, 40, 35, 8, 0, 17, 180, 208, 237, 139, 26, 48,
       48, 48, 48, 70, 105, 66, 40, 35, 9, 0, 17, 180, 208, 237, 139, 26,
       48, 48, 48, 48, 70, 105, 66, 40, 35, 10, 0, 17, 180, 208, 237, 139,
       26, 48, 48, 48, 48, 70, 105, 66, 40, 35, 11, 0, 17, 180, 208, 237,
       139, 26, 48, 48, 48, 48, 70, 105, 66, 40, 35, 12, 0, 17, 180, 208,
       237, 139, 26, 48, 48, 48, 48, 70, 105, 66, 40, 35, 13, 0 >>

SettlementMessageCapture ==
    << 33, 0, 1, 1, 40, 117, 5, 0, 25, 185, 104, 53, 159, 19, 48, 48,
       48, 48, 72, 106, 136, 236, 51, 1, 192, 212, 1, 0, 0, 0, 0, 0,
       83 >>

SingleSideUpdateLongMessageCapture ==
    << 33, 0, 1, 2, 166, 0, 0, 0, 25, 181, 128, 58, 36, 8, 48, 48,
       48, 48, 54, 74, 66, 32, 185, 205, 8, 0, 0, 0, 0, 121, 0, 0,
       0 >>

SingleSideUpdateShortMessageCapture ==
    << 25, 0, 1, 1, 16, 2, 0, 0, 17, 180, 32, 9, 102, 37, 48, 48,
       48, 48, 48, 86, 66, 210, 5, 25, 0 >>

TimeMessageCapture ==
    << 18, 0, 1, 1, 29, 1, 0, 0, 10, 32, 140, 235, 0, 0, 236, 92,
       77, 90 >>

TimeReferenceMessageCapture ==
    << 26, 0, 1, 1, 1, 0, 0, 0, 18, 177, 96, 113, 76, 90, 204, 226,
       0, 0, 0, 16, 85, 34, 136, 236, 51, 1 >>

TopTradeMessageCapture ==
    << 45, 0, 1, 1, 58, 3, 0, 0, 37, 184, 192, 231, 197, 5, 48, 48,
       48, 48, 48, 55, 3, 0, 0, 0, 84, 230, 1, 0, 0, 0, 0, 0,
       7, 228, 185, 25, 163, 2, 0, 0, 6, 0, 0, 0, 83 >>

TradingStatusMessageCapture ==
    << 26, 0, 1, 1, 93, 1, 0, 0, 18, 49, 56, 27, 70, 7, 48, 48,
       48, 48, 74, 66, 32, 32, 81, 48, 32, 32 >>

TwoSideUpdateLongMessageCapture ==
    << 44, 0, 1, 1, 247, 137, 1, 0, 36, 183, 8, 132, 110, 15, 48, 48,
       48, 48, 70, 67, 16, 152, 2, 0, 0, 0, 0, 0, 19, 2, 0, 0,
       128, 254, 33, 10, 0, 0, 0, 0, 1, 0, 0, 0 >>

TwoSideUpdateShortMessageCapture ==
    << 28, 0, 1, 1, 232, 2, 0, 0, 20, 182, 224, 233, 114, 14, 48, 48,
       48, 48, 48, 86, 24, 6, 74, 0, 0, 0, 0, 0 >>

Captures == { MarketSnapshotLongMessageCapture, MarketSnapshotShortMessageCapture, PriceLimitsMessageCapture, SettlementMessageCapture, SingleSideUpdateLongMessageCapture, SingleSideUpdateShortMessageCapture, TimeMessageCapture, TimeReferenceMessageCapture, TopTradeMessageCapture, TradingStatusMessageCapture, TwoSideUpdateLongMessageCapture, TwoSideUpdateShortMessageCapture }

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
