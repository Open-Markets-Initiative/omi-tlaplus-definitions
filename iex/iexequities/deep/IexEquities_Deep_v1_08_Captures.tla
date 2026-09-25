------------------ MODULE IexEquities_Deep_v1_08_Captures ------------------
(***************************************************************************)
(* Recorded Investors Exchange Depth Of Book v1.08 packets, as the bytes   *)
(* they were captured as. Each one decodes, consumes the whole packet, and *)
(* encodes back to exactly the bytes it was read from.                     *)
(***************************************************************************)
EXTENDS IexEquities_Deep_v1_08

AuctionInformationMessageCapture ==
    << 1, 0, 4, 128, 1, 0, 0, 0, 0, 0, 112, 78, 82, 0, 1, 0,
       108, 104, 165, 0, 0, 0, 0, 0, 162, 99, 5, 0, 0, 0, 0, 0,
       7, 217, 172, 118, 163, 212, 19, 24, 80, 0, 65, 79, 233, 12, 165, 118,
       163, 212, 19, 24, 90, 73, 69, 88, 84, 32, 32, 32, 232, 3, 0, 0,
       16, 39, 0, 0, 0, 0, 0, 0, 16, 39, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 78, 0, 232, 115, 105, 103, 16, 39, 0, 0, 0, 0,
       0, 0, 16, 39, 0, 0, 0, 0, 0, 0, 136, 19, 0, 0, 0, 0,
       0, 0, 152, 58, 0, 0, 0, 0, 0, 0 >>

OperationalHaltStatusMessageCapture ==
    << 1, 0, 4, 128, 1, 0, 0, 0, 0, 0, 112, 78, 20, 0, 1, 0,
       200, 150, 14, 0, 0, 0, 0, 0, 200, 175, 0, 0, 0, 0, 0, 0,
       29, 56, 17, 115, 61, 207, 19, 24, 18, 0, 79, 78, 29, 56, 17, 115,
       61, 207, 19, 24, 73, 67, 67, 84, 32, 32, 32, 32 >>

PriceLevelBuyUpdateMessageCapture ==
    << 1, 0, 4, 128, 1, 0, 0, 0, 0, 0, 112, 78, 32, 0, 1, 0,
       84, 151, 14, 0, 0, 0, 0, 0, 207, 175, 0, 0, 0, 0, 0, 0,
       245, 123, 52, 35, 214, 207, 19, 24, 30, 0, 56, 1, 66, 50, 170, 30,
       214, 207, 19, 24, 76, 65, 66, 68, 32, 32, 32, 32, 176, 4, 0, 0,
       36, 13, 1, 0, 0, 0, 0, 0 >>

PriceLevelSellUpdateMessageCapture ==
    << 1, 0, 4, 128, 1, 0, 0, 0, 0, 0, 112, 78, 32, 0, 1, 0,
       116, 151, 14, 0, 0, 0, 0, 0, 208, 175, 0, 0, 0, 0, 0, 0,
       158, 112, 11, 36, 214, 207, 19, 24, 30, 0, 53, 1, 86, 66, 205, 30,
       214, 207, 19, 24, 83, 77, 83, 84, 32, 32, 32, 32, 152, 8, 0, 0,
       0, 225, 0, 0, 0, 0, 0, 0 >>

RetailLiquidityIndicatorMessageCapture ==
    << 1, 0, 4, 128, 1, 0, 0, 0, 0, 0, 112, 78, 20, 0, 1, 0,
       237, 79, 181, 0, 0, 0, 0, 0, 240, 240, 5, 0, 0, 0, 0, 0,
       33, 61, 149, 106, 191, 212, 19, 24, 18, 0, 73, 66, 140, 46, 206, 105,
       191, 212, 19, 24, 83, 83, 79, 32, 32, 32, 32, 32 >>

SecurityEventMessageCapture ==
    << 1, 0, 4, 128, 1, 0, 0, 0, 0, 0, 112, 78, 20, 0, 1, 0,
       80, 12, 177, 0, 0, 0, 0, 0, 127, 190, 5, 0, 0, 0, 0, 0,
       165, 189, 12, 103, 191, 212, 19, 24, 18, 0, 69, 79, 47, 230, 6, 103,
       191, 212, 19, 24, 90, 67, 90, 90, 84, 32, 32, 32 >>

ShortSalePriceTestStatusMessageCapture ==
    << 1, 0, 4, 128, 1, 0, 0, 0, 0, 0, 112, 78, 21, 0, 1, 0,
       67, 115, 14, 0, 0, 0, 0, 0, 21, 174, 0, 0, 0, 0, 0, 0,
       246, 117, 197, 203, 100, 206, 19, 24, 19, 0, 80, 1, 246, 117, 197, 203,
       100, 206, 19, 24, 82, 86, 80, 72, 32, 32, 32, 32, 78 >>

SystemEventMessageCapture ==
    << 1, 0, 4, 128, 1, 0, 0, 0, 0, 0, 112, 78, 12, 0, 1, 0,
       72, 151, 14, 0, 0, 0, 0, 0, 206, 175, 0, 0, 0, 0, 0, 0,
       152, 79, 252, 29, 214, 207, 19, 24, 10, 0, 83, 83, 152, 79, 252, 29,
       214, 207, 19, 24 >>

TradeReportMessageCapture ==
    << 1, 0, 4, 128, 1, 0, 0, 0, 0, 0, 112, 78, 40, 0, 1, 0,
       52, 245, 14, 0, 0, 0, 0, 0, 190, 178, 0, 0, 0, 0, 0, 0,
       238, 198, 246, 226, 214, 207, 19, 24, 38, 0, 84, 64, 245, 134, 235, 226,
       214, 207, 19, 24, 71, 84, 66, 80, 32, 32, 32, 32, 100, 0, 0, 0,
       172, 138, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0 >>

TradingStatusMessageCapture ==
    << 1, 0, 4, 128, 1, 0, 0, 0, 0, 0, 112, 78, 24, 0, 1, 0,
       111, 125, 14, 0, 0, 0, 0, 0, 145, 174, 0, 0, 0, 0, 0, 0,
       164, 53, 224, 198, 106, 206, 19, 24, 22, 0, 72, 72, 164, 53, 224, 198,
       106, 206, 19, 24, 90, 74, 90, 90, 84, 32, 32, 32, 78, 65, 32, 32 >>

Captures == { AuctionInformationMessageCapture, OperationalHaltStatusMessageCapture, PriceLevelBuyUpdateMessageCapture, PriceLevelSellUpdateMessageCapture, RetailLiquidityIndicatorMessageCapture, SecurityEventMessageCapture, ShortSalePriceTestStatusMessageCapture, SystemEventMessageCapture, TradeReportMessageCapture, TradingStatusMessageCapture }

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
