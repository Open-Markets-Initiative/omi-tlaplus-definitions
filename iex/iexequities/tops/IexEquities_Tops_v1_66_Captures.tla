------------------ MODULE IexEquities_Tops_v1_66_Captures ------------------
(***************************************************************************)
(* Recorded Investors Exchange Top Of Book v1.66 packets, as the bytes     *)
(* they were captured as. Each one decodes, consumes the whole packet, and *)
(* encodes back to exactly the bytes it was read from.                     *)
(***************************************************************************)
EXTENDS IexEquities_Tops_v1_66

AuctionInformationMessageCapture ==
    << 1, 0, 3, 128, 1, 0, 0, 0, 0, 0, 195, 77, 82, 0, 1, 0,
       215, 251, 185, 0, 0, 0, 0, 0, 99, 150, 4, 0, 0, 0, 0, 0,
       107, 189, 176, 19, 247, 182, 222, 23, 80, 0, 65, 79, 158, 3, 164, 19,
       247, 182, 222, 23, 90, 69, 88, 73, 84, 32, 32, 32, 208, 7, 0, 0,
       160, 134, 1, 0, 0, 0, 0, 0, 160, 134, 1, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 78, 0, 88, 82, 133, 102, 160, 134, 1, 0, 0, 0,
       0, 0, 160, 134, 1, 0, 0, 0, 0, 0, 144, 95, 1, 0, 0, 0,
       0, 0, 176, 173, 1, 0, 0, 0, 0, 0 >>

QuoteUpdateMessageCapture ==
    << 1, 0, 3, 128, 1, 0, 0, 0, 0, 0, 195, 77, 44, 0, 1, 0,
       83, 220, 21, 0, 0, 0, 0, 0, 43, 217, 0, 0, 0, 0, 0, 0,
       71, 119, 46, 202, 41, 178, 222, 23, 42, 0, 81, 64, 171, 117, 9, 202,
       41, 178, 222, 23, 67, 82, 71, 89, 32, 32, 32, 32, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 236, 32, 2, 0, 0, 0, 0, 0,
       125, 0, 0, 0 >>

RetailLiquidityIndicatorMessageCapture ==
    << 1, 0, 3, 128, 1, 0, 0, 0, 0, 0, 195, 77, 20, 0, 1, 0,
       123, 25, 201, 0, 0, 0, 0, 0, 66, 237, 4, 0, 0, 0, 0, 0,
       197, 10, 255, 7, 19, 183, 222, 23, 18, 0, 73, 65, 21, 64, 56, 4,
       19, 183, 222, 23, 85, 68, 79, 87, 32, 32, 32, 32 >>

ShortSalePriceTestStatusMessageCapture ==
    << 1, 0, 3, 128, 1, 0, 0, 0, 0, 0, 195, 77, 21, 0, 1, 0,
       151, 191, 21, 0, 0, 0, 0, 0, 205, 215, 0, 0, 0, 0, 0, 0,
       87, 145, 178, 205, 106, 176, 222, 23, 19, 0, 80, 1, 87, 145, 178, 205,
       106, 176, 222, 23, 70, 71, 73, 32, 32, 32, 32, 32, 78 >>

SystemEventMessageCapture ==
    << 1, 0, 3, 128, 1, 0, 0, 0, 0, 0, 195, 77, 12, 0, 1, 0,
       71, 220, 21, 0, 0, 0, 0, 0, 42, 217, 0, 0, 0, 0, 0, 0,
       205, 162, 235, 186, 41, 178, 222, 23, 10, 0, 83, 83, 205, 162, 235, 186,
       41, 178, 222, 23 >>

TradeReportMessageCapture ==
    << 1, 0, 3, 128, 1, 0, 0, 0, 0, 0, 195, 77, 40, 0, 1, 0,
       143, 222, 21, 0, 0, 0, 0, 0, 56, 217, 0, 0, 0, 0, 0, 0,
       196, 243, 59, 241, 41, 178, 222, 23, 38, 0, 84, 64, 223, 152, 18, 241,
       41, 178, 222, 23, 76, 65, 67, 32, 32, 32, 32, 32, 100, 0, 0, 0,
       156, 99, 0, 0, 0, 0, 0, 0, 165, 249, 23, 0, 0, 0, 0, 0 >>

TradingStatusMessageCapture ==
    << 1, 0, 3, 128, 1, 0, 0, 0, 0, 0, 195, 77, 24, 0, 1, 0,
       173, 196, 21, 0, 0, 0, 0, 0, 11, 216, 0, 0, 0, 0, 0, 0,
       222, 255, 139, 206, 106, 176, 222, 23, 22, 0, 72, 72, 222, 255, 139, 206,
       106, 176, 222, 23, 65, 83, 76, 78, 32, 32, 32, 32, 78, 65, 32, 32 >>

Captures == { AuctionInformationMessageCapture, QuoteUpdateMessageCapture, RetailLiquidityIndicatorMessageCapture, ShortSalePriceTestStatusMessageCapture, SystemEventMessageCapture, TradeReportMessageCapture, TradingStatusMessageCapture }

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
