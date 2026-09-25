------------------ MODULE IexEquities_Deep_v1_06_Captures ------------------
(***************************************************************************)
(* Recorded Investors Exchange Depth Of Book v1.06 packets, as the bytes   *)
(* they were captured as. Each one decodes, consumes the whole packet, and *)
(* encodes back to exactly the bytes it was read from.                     *)
(***************************************************************************)
EXTENDS IexEquities_Deep_v1_06

AuctionInformationMessageCapture ==
    << 1, 0, 4, 128, 1, 0, 0, 0, 0, 0, 221, 72, 82, 0, 1, 0,
       97, 181, 94, 0, 0, 0, 0, 0, 252, 17, 3, 0, 0, 0, 0, 0,
       227, 186, 30, 124, 125, 206, 93, 22, 80, 0, 65, 79, 5, 243, 240, 123,
       125, 206, 93, 22, 90, 73, 69, 88, 84, 32, 32, 32, 208, 7, 0, 0,
       16, 39, 0, 0, 0, 0, 0, 0, 16, 39, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 78, 0, 104, 39, 16, 96, 16, 39, 0, 0, 0, 0,
       0, 0, 16, 39, 0, 0, 0, 0, 0, 0, 136, 19, 0, 0, 0, 0,
       0, 0, 152, 58, 0, 0, 0, 0, 0, 0 >>

HeartbeatCapture ==
    << 1, 0, 4, 128, 1, 0, 0, 0, 0, 0, 221, 72, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0,
       189, 68, 70, 95, 90, 199, 93, 22 >>

OfficialPriceMessageCapture ==
    << 1, 0, 4, 128, 1, 0, 0, 0, 0, 0, 221, 72, 28, 0, 1, 0,
       153, 55, 100, 0, 0, 0, 0, 0, 129, 61, 3, 0, 0, 0, 0, 0,
       103, 49, 147, 108, 153, 206, 93, 22, 26, 0, 88, 81, 103, 49, 147, 108,
       153, 206, 93, 22, 90, 69, 88, 73, 84, 32, 32, 32, 160, 134, 1, 0,
       0, 0, 0, 0 >>

PriceLevelBuyUpdateMessageCapture ==
    << 1, 0, 4, 128, 1, 0, 0, 0, 0, 0, 221, 72, 32, 0, 1, 0,
       209, 175, 9, 0, 0, 0, 0, 0, 122, 114, 0, 0, 0, 0, 0, 0,
       217, 64, 191, 45, 176, 201, 93, 22, 30, 0, 56, 1, 70, 39, 186, 43,
       176, 201, 93, 22, 73, 80, 79, 69, 32, 32, 32, 32, 100, 0, 0, 0,
       8, 195, 2, 0, 0, 0, 0, 0 >>

PriceLevelSellUpdateMessageCapture ==
    << 1, 0, 4, 128, 1, 0, 0, 0, 0, 0, 221, 72, 32, 0, 1, 0,
       177, 175, 9, 0, 0, 0, 0, 0, 121, 114, 0, 0, 0, 0, 0, 0,
       142, 125, 115, 45, 176, 201, 93, 22, 30, 0, 53, 1, 238, 38, 72, 44,
       176, 201, 93, 22, 76, 84, 72, 77, 32, 32, 32, 32, 100, 0, 0, 0,
       112, 130, 3, 0, 0, 0, 0, 0 >>

SecurityEventMessageCapture ==
    << 1, 0, 4, 128, 1, 0, 0, 0, 0, 0, 221, 72, 20, 0, 1, 0,
       169, 190, 99, 0, 0, 0, 0, 0, 17, 56, 3, 0, 0, 0, 0, 0,
       112, 176, 234, 107, 153, 206, 93, 22, 18, 0, 69, 79, 215, 123, 177, 107,
       153, 206, 93, 22, 66, 68, 71, 69, 32, 32, 32, 32 >>

ShortSalePriceTestStatusMessageCapture ==
    << 1, 0, 4, 128, 1, 0, 0, 0, 0, 0, 221, 72, 21, 0, 1, 0,
       154, 150, 9, 0, 0, 0, 0, 0, 74, 113, 0, 0, 0, 0, 0, 0,
       2, 101, 132, 131, 113, 199, 93, 22, 19, 0, 80, 1, 218, 76, 132, 131,
       113, 199, 93, 22, 65, 77, 80, 69, 32, 32, 32, 32, 78 >>

SystemEventMessageCapture ==
    << 1, 0, 4, 128, 1, 0, 0, 0, 0, 0, 221, 72, 12, 0, 1, 0,
       165, 175, 9, 0, 0, 0, 0, 0, 120, 114, 0, 0, 0, 0, 0, 0,
       57, 136, 64, 35, 176, 201, 93, 22, 10, 0, 83, 83, 57, 136, 64, 35,
       176, 201, 93, 22 >>

TradeReportMessageCapture ==
    << 1, 0, 4, 128, 1, 0, 0, 0, 0, 0, 221, 72, 40, 0, 1, 0,
       209, 195, 9, 0, 0, 0, 0, 0, 26, 115, 0, 0, 0, 0, 0, 0,
       127, 63, 248, 88, 176, 201, 93, 22, 38, 0, 84, 64, 237, 70, 219, 88,
       176, 201, 93, 22, 65, 77, 67, 32, 32, 32, 32, 32, 105, 0, 0, 0,
       72, 188, 0, 0, 0, 0, 0, 0, 64, 36, 36, 0, 0, 0, 0, 0 >>

TradingStatusMessageCapture ==
    << 1, 0, 4, 128, 1, 0, 0, 0, 0, 0, 221, 72, 24, 0, 1, 0,
       117, 154, 9, 0, 0, 0, 0, 0, 121, 113, 0, 0, 0, 0, 0, 0,
       182, 51, 38, 134, 113, 199, 93, 22, 22, 0, 72, 72, 182, 51, 38, 134,
       113, 199, 93, 22, 69, 73, 68, 88, 32, 32, 32, 32, 78, 65, 32, 32 >>

Captures == { AuctionInformationMessageCapture, HeartbeatCapture, OfficialPriceMessageCapture, PriceLevelBuyUpdateMessageCapture, PriceLevelSellUpdateMessageCapture, SecurityEventMessageCapture, ShortSalePriceTestStatusMessageCapture, SystemEventMessageCapture, TradeReportMessageCapture, TradingStatusMessageCapture }

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
