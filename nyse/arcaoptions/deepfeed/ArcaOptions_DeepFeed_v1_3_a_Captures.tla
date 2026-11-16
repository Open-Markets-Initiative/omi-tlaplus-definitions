--------------- MODULE ArcaOptions_DeepFeed_v1_3_a_Captures ----------------
(***************************************************************************)
(* Recorded New York Stock Exchange Deep Feed v1.3.a packets, as the bytes *)
(* they were captured as. Each one decodes, consumes the whole packet, and *)
(* encodes back to exactly the bytes it was read from.                     *)
(***************************************************************************)
EXTENDS ArcaOptions_DeepFeed_v1_3_a

OutrightMarketDepthBuyMessageCapture ==
    << 72, 0, 11, 2, 13, 36, 0, 0, 32, 212, 111, 88, 160, 170, 255, 40,
       8, 0, 199, 1, 18, 0, 0, 0, 48, 0, 147, 1, 32, 212, 111, 88,
       96, 3, 236, 40, 8, 175, 147, 3, 3, 0, 0, 0, 80, 195, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 49, 0,
       0, 0, 0, 0, 0, 0, 0, 0 >>

OutrightMarketDepthSellMessageCapture ==
    << 72, 0, 11, 2, 11, 36, 0, 0, 32, 212, 111, 88, 168, 2, 255, 40,
       8, 0, 199, 1, 18, 0, 0, 0, 48, 0, 149, 1, 32, 212, 111, 88,
       96, 3, 236, 40, 8, 175, 147, 3, 2, 0, 0, 0, 216, 214, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 49, 0,
       0, 0, 0, 0, 0, 0, 0, 0 >>

OutrightSeriesStatusMessageCapture ==
    << 48, 0, 11, 2, 217, 19, 0, 0, 101, 211, 111, 88, 232, 56, 250, 2,
       8, 0, 199, 1, 16, 0, 0, 0, 24, 0, 165, 1, 100, 211, 111, 88,
       80, 242, 237, 46, 252, 168, 147, 3, 1, 0, 0, 0, 76, 32, 0, 0 >>

RefreshOutrightMarketDepthBuyMessageCapture ==
    << 72, 0, 3, 2, 219, 36, 0, 0, 160, 212, 111, 88, 144, 80, 83, 18,
       8, 0, 199, 1, 18, 0, 0, 0, 48, 0, 247, 1, 40, 212, 111, 88,
       232, 0, 80, 18, 8, 175, 147, 3, 14, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 49, 0,
       0, 0, 0, 0, 0, 0, 0, 0 >>

RefreshOutrightMarketDepthSellMessageCapture ==
    << 72, 0, 3, 2, 221, 36, 0, 0, 160, 212, 111, 88, 96, 213, 83, 18,
       8, 0, 199, 1, 18, 0, 0, 0, 48, 0, 249, 1, 40, 212, 111, 88,
       232, 0, 80, 18, 8, 175, 147, 3, 14, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 49, 0,
       0, 0, 0, 0, 0, 0, 0, 0 >>

SequenceNumberResetMessageCapture ==
    << 40, 0, 12, 2, 1, 0, 0, 0, 144, 210, 111, 88, 32, 60, 3, 0,
       8, 0, 199, 1, 18, 0, 0, 0, 16, 0, 1, 0, 144, 210, 111, 88,
       56, 56, 3, 0, 2, 28, 0, 0 >>

SeriesIndexMappingMessageCapture ==
    << 84, 0, 11, 2, 5, 0, 0, 0, 144, 210, 111, 88, 208, 126, 112, 44,
       8, 0, 199, 1, 18, 0, 0, 0, 60, 0, 181, 1, 69, 122, 149, 3,
       28, 0, 4, 0, 1, 0, 18, 0, 247, 0, 0, 0, 100, 0, 48, 56,
       48, 49, 49, 57, 0, 56, 53, 0, 0, 0, 0, 0, 0, 0, 0, 4,
       66, 65, 0, 0, 0, 0, 0, 0, 0, 0, 0, 87, 66, 79, 0, 0,
       211, 4, 0, 0 >>

StreamIdMessageCapture ==
    << 24, 0, 1, 1, 1, 0, 0, 0, 135, 210, 111, 88, 184, 1, 61, 4,
       8, 0, 199, 1, 16, 0, 0, 0 >>

UnderlyingIndexMappingMessageCapture ==
    << 52, 0, 11, 2, 3, 0, 0, 0, 144, 210, 111, 88, 16, 194, 106, 44,
       8, 0, 199, 1, 18, 0, 0, 0, 28, 0, 179, 1, 247, 0, 0, 0,
       66, 65, 0, 0, 0, 0, 0, 0, 0, 0, 0, 28, 4, 0, 1, 78,
       4, 67, 5, 0 >>

UnderlyingStatusMessageCapture ==
    << 48, 0, 11, 2, 175, 31, 0, 0, 133, 211, 111, 88, 112, 247, 117, 9,
       8, 0, 199, 1, 18, 0, 0, 0, 24, 0, 163, 1, 133, 211, 111, 88,
       96, 36, 104, 9, 250, 0, 0, 0, 0, 0, 0, 0, 79, 32, 0, 0 >>

Captures == { OutrightMarketDepthBuyMessageCapture, OutrightMarketDepthSellMessageCapture, OutrightSeriesStatusMessageCapture, RefreshOutrightMarketDepthBuyMessageCapture, RefreshOutrightMarketDepthSellMessageCapture, SequenceNumberResetMessageCapture, SeriesIndexMappingMessageCapture, StreamIdMessageCapture, UnderlyingIndexMappingMessageCapture, UnderlyingStatusMessageCapture }

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
