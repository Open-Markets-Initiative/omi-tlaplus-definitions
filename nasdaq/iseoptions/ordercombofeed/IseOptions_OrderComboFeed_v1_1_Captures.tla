-------------- MODULE IseOptions_OrderComboFeed_v1_1_Captures --------------
(***************************************************************************)
(* Recorded National Association of Securities Dealers Automated           *)
(* Quotations (Nasdaq) Ise Order Combo Market Data Feed v1.1 packets, as   *)
(* the bytes they were captured as. Each one decodes, consumes the whole   *)
(* packet, and encodes back to exactly the bytes it was read from.         *)
(***************************************************************************)
EXTENDS IseOptions_OrderComboFeed_v1_1

ComplexStrategyAuctionMessageCapture ==
    << 48, 48, 48, 48, 48, 56, 51, 54, 55, 73, 0, 0, 0, 0, 0, 5,
       65, 178, 0, 1, 0, 57, 74, 51, 191, 172, 177, 189, 185, 0, 31, 132,
       112, 0, 17, 128, 140, 76, 66, 0, 0, 25, 100, 0, 0, 0, 1, 78,
       67, 76, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
       32, 32, 32, 32, 85, 69, 1, 0, 0, 20, 80, 0, 0, 0, 4 >>

ComplexStrategyDirectoryMessageCapture ==
    << 48, 48, 48, 48, 48, 56, 51, 54, 55, 73, 0, 0, 0, 0, 0, 5,
       24, 55, 0, 1, 0, 83, 82, 51, 31, 131, 161, 107, 153, 0, 32, 60,
       204, 65, 1, 66, 65, 66, 65, 32, 32, 32, 32, 32, 32, 32, 32, 32,
       2, 0, 1, 62, 61, 66, 65, 66, 65, 32, 32, 0, 19, 1, 11, 0,
       0, 0, 3, 90, 78, 144, 0, 67, 66, 0, 0, 0, 1, 0, 1, 62,
       27, 66, 65, 66, 65, 32, 32, 1, 19, 1, 11, 0, 0, 0, 3, 126,
       17, 214, 0, 67, 83, 0, 0, 0, 2 >>

ComplexStrategyOrderOnBookMessageCapture ==
    << 48, 48, 48, 48, 48, 56, 51, 54, 55, 73, 0, 0, 0, 0, 0, 5,
       9, 90, 0, 1, 0, 42, 76, 50, 218, 217, 92, 153, 205, 0, 31, 76,
       48, 76, 65, 255, 255, 255, 56, 0, 0, 0, 165, 78, 67, 76, 32, 32,
       32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32 >>

HeartbeatCapture ==
    << 48, 48, 48, 48, 48, 56, 51, 54, 55, 73, 0, 0, 0, 0, 0, 5,
       217, 33, 0, 0 >>

StrategyOpenClosedMessageCapture ==
    << 48, 48, 48, 48, 48, 56, 51, 54, 55, 73, 0, 0, 0, 0, 0, 5,
       7, 240, 0, 1, 0, 12, 79, 50, 213, 35, 192, 81, 250, 0, 32, 57,
       40, 89 >>

StrategyTradingActionMessageCapture ==
    << 48, 48, 48, 48, 48, 56, 51, 54, 55, 73, 0, 0, 0, 0, 0, 5,
       38, 136, 0, 1, 0, 12, 72, 51, 101, 142, 146, 216, 42, 0, 32, 63,
       184, 84 >>

Captures == { ComplexStrategyAuctionMessageCapture, ComplexStrategyDirectoryMessageCapture, ComplexStrategyOrderOnBookMessageCapture, HeartbeatCapture, StrategyOpenClosedMessageCapture, StrategyTradingActionMessageCapture }

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
