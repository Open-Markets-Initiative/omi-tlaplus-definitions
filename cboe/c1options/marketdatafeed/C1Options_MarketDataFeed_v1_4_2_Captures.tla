------------- MODULE C1Options_MarketDataFeed_v1_4_2_Captures --------------
(***************************************************************************)
(* Recorded Chicago Board Options Exchange Market Data Feed v1.4.2         *)
(* packets, as the bytes they were captured as. Each one decodes, consumes *)
(* the whole packet, and encodes back to exactly the bytes it was read     *)
(* from.                                                                   *)
(***************************************************************************)
EXTENDS C1Options_MarketDataFeed_v1_4_2

CurrentMarketRefreshMessageCapture ==
    << 1, 0, 61, 0, 0, 1, 103, 205, 100, 2, 11, 1, 2, 34, 38, 28,
       0, 45, 11, 87, 2, 34, 38, 28, 4, 53, 0, 2, 13, 133, 156, 224,
       25, 3, 0, 0, 5, 139, 2, 48, 254, 255, 255, 255, 251, 0, 0, 1,
       19, 0, 48, 254, 255, 255, 255, 251, 0, 0, 0, 75, 1 >>

CurrentMarketUpdateMessageCapture ==
    << 1, 0, 46, 0, 0, 1, 103, 205, 100, 2, 20, 1, 2, 34, 38, 29,
       0, 30, 12, 88, 2, 34, 38, 29, 71, 113, 127, 79, 22, 167, 81, 36,
       17, 3, 1, 48, 254, 255, 255, 255, 108, 0, 0, 0, 10, 0 >>

HeartbeatMessageCapture ==
    << 1, 0, 24, 0, 0, 1, 103, 205, 100, 3, 158, 1, 2, 34, 39, 102,
       0, 8, 16, 48, 2, 34, 39, 102 >>

MarketDataRefreshMessageCapture ==
    << 1, 0, 59, 0, 0, 1, 103, 205, 106, 111, 144, 1, 2, 42, 86, 184,
       0, 43, 20, 87, 2, 42, 86, 184, 4, 32, 64, 59, 20, 229, 170, 48,
       17, 3, 0, 0, 237, 237, 247, 128, 0, 0, 0, 0, 0, 0, 0, 1,
       48, 254, 0, 0, 5, 98, 0, 0, 0, 100, 0 >>

RecapUpdateMessageCapture ==
    << 1, 0, 83, 0, 0, 1, 103, 205, 100, 2, 10, 1, 2, 34, 38, 22,
       0, 67, 21, 88, 2, 34, 38, 22, 57, 28, 121, 80, 22, 217, 84, 134,
       3, 254, 255, 255, 252, 89, 0, 0, 0, 20, 4, 52, 254, 255, 255, 252,
       89, 0, 0, 0, 0, 50, 254, 255, 255, 252, 89, 0, 0, 0, 20, 55,
       254, 255, 255, 252, 89, 0, 0, 0, 0, 56, 254, 255, 255, 252, 89, 0,
       0, 0, 0 >>

SecurityDefinitionMessageCapture ==
    << 1, 0, 229, 0, 0, 1, 103, 205, 100, 18, 6, 1, 2, 34, 45, 45,
       0, 213, 13, 100, 2, 34, 45, 45, 4, 77, 76, 69, 71, 67, 42, 83,
       80, 88, 95, 115, 112, 114, 101, 97, 100, 32, 119, 105, 116, 104, 32, 53,
       43, 32, 108, 101, 103, 115, 32, 50, 48, 49, 57, 48, 49, 49, 56, 32,
       50, 51, 48, 48, 46, 48, 48, 48, 48, 1, 48, 4, 32, 58, 243, 22,
       217, 115, 157, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0,
       0, 0, 252, 0, 0, 4, 226, 254, 0, 15, 66, 54, 254, 0, 0, 1,
       44, 254, 0, 0, 0, 5, 254, 0, 0, 0, 5, 0, 0, 3, 83, 80,
       88, 4, 73, 78, 68, 88, 0, 0, 0, 1, 10, 0, 0, 0, 1, 10,
       95, 223, 87, 83, 0, 0, 0, 1, 10, 95, 223, 109, 66, 0, 0, 0,
       1, 10, 95, 223, 124, 66, 0, 0, 0, 1, 10, 95, 223, 128, 83, 0,
       0, 0, 1, 21, 37, 248, 200, 83, 0, 0, 0, 1, 21, 37, 249, 182,
       66, 0, 0, 0, 1, 22, 65, 103, 108, 83, 0, 0, 0, 1, 22, 65,
       103, 180, 66, 0, 0, 0, 1, 22, 65, 103, 239, 66, 0, 0, 0, 1,
       22, 65, 104, 31, 83 >>

TickerMessageCapture ==
    << 1, 0, 49, 0, 0, 1, 103, 205, 105, 137, 244, 1, 2, 40, 206, 103,
       0, 33, 14, 88, 2, 40, 206, 103, 4, 32, 58, 243, 22, 213, 57, 81,
       3, 1, 50, 254, 255, 255, 254, 142, 0, 0, 0, 1, 4, 83, 80, 82,
       68 >>

Captures == { CurrentMarketRefreshMessageCapture, CurrentMarketUpdateMessageCapture, HeartbeatMessageCapture, MarketDataRefreshMessageCapture, RecapUpdateMessageCapture, SecurityDefinitionMessageCapture, TickerMessageCapture }

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
