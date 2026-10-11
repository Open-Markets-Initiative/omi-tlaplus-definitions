-------------- MODULE C1Options_OpeningAuction_v1_0_Captures ---------------
(***************************************************************************)
(* Recorded Chicago Board Options Exchange Opening Auction Feed v1.0       *)
(* packets, as the bytes they were captured as. Each one decodes, consumes *)
(* the whole packet, and encodes back to exactly the bytes it was read     *)
(* from.                                                                   *)
(***************************************************************************)
EXTENDS C1Options_OpeningAuction_v1_0

CurrentMarketUpdateMessageCapture ==
    << 1, 0, 57, 0, 0, 1, 104, 24, 216, 212, 185, 1, 0, 0, 53, 222,
       0, 41, 12, 88, 0, 0, 53, 222, 4, 32, 58, 242, 21, 7, 91, 215,
       21, 3, 2, 48, 254, 0, 0, 0, 5, 0, 0, 0, 1, 0, 48, 254,
       0, 0, 0, 5, 0, 0, 0, 1, 1 >>

ExpectedOpeningPriceAndSizeMessageCapture ==
    << 1, 0, 43, 0, 0, 1, 104, 25, 21, 144, 177, 1, 0, 1, 143, 65,
       0, 27, 15, 88, 0, 1, 143, 65, 4, 32, 58, 242, 3, 99, 27, 245,
       254, 0, 0, 44, 236, 0, 0, 0, 1, 1, 1 >>

HeartbeatMessageCapture ==
    << 1, 0, 24, 0, 0, 1, 103, 210, 218, 50, 156, 1, 0, 94, 35, 118,
       0, 8, 16, 48, 0, 94, 35, 118 >>

MarketDataRefreshMessageCapture ==
    << 1, 0, 70, 0, 0, 1, 104, 24, 211, 96, 158, 1, 0, 0, 51, 37,
       0, 54, 20, 87, 0, 0, 51, 37, 4, 32, 58, 242, 21, 7, 89, 158,
       21, 3, 0, 0, 0, 3, 247, 128, 0, 0, 0, 0, 0, 0, 0, 2,
       49, 254, 0, 0, 26, 44, 0, 0, 0, 3, 0, 49, 254, 0, 0, 26,
       44, 0, 0, 0, 3, 1 >>

SecurityDefinitionMessageCapture ==
    << 1, 0, 148, 0, 0, 1, 103, 205, 112, 154, 85, 1, 7, 210, 239, 218,
       0, 132, 13, 100, 7, 210, 239, 218, 4, 77, 76, 69, 71, 67, 35, 67,
       78, 73, 95, 85, 110, 107, 110, 111, 119, 110, 32, 83, 112, 114, 101, 97,
       100, 32, 50, 48, 49, 57, 48, 52, 49, 56, 32, 54, 53, 46, 48, 48,
       48, 48, 1, 48, 4, 32, 14, 98, 22, 189, 246, 113, 0, 0, 0, 0,
       0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 252, 0, 0, 4, 226,
       254, 0, 15, 66, 54, 254, 0, 0, 1, 44, 254, 0, 0, 0, 1, 254,
       0, 0, 0, 1, 0, 0, 3, 67, 78, 73, 2, 67, 83, 0, 0, 0,
       1, 2, 0, 0, 0, 1, 19, 91, 45, 218, 66, 0, 0, 0, 2, 21,
       215, 57, 73, 83 >>

Captures == { CurrentMarketUpdateMessageCapture, ExpectedOpeningPriceAndSizeMessageCapture, HeartbeatMessageCapture, MarketDataRefreshMessageCapture, SecurityDefinitionMessageCapture }

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
