--------------- MODULE AmexOptions_DeepFeed_v1_3_a_Captures ----------------
(***************************************************************************)
(* Recorded New York Stock Exchange Deep Feed v1.3.a packets, as the bytes *)
(* they were captured as. Each one decodes, consumes the whole packet, and *)
(* encodes back to exactly the bytes it was read from.                     *)
(***************************************************************************)
EXTENDS AmexOptions_DeepFeed_v1_3_a

OutrightMarketDepthBuyMessageCapture ==
    << 72, 0, 11, 2, 211, 25, 101, 0, 240, 68, 238, 99, 32, 78, 0, 0,
       8, 0, 199, 1, 98, 0, 0, 0, 48, 0, 147, 1, 239, 68, 238, 99,
       40, 112, 154, 59, 211, 60, 135, 15, 152, 12, 0, 0, 36, 113, 1, 0,
       84, 105, 1, 0, 96, 103, 1, 0, 1, 0, 2, 0, 3, 0, 49, 0,
       0, 0, 0, 0, 0, 0, 0, 0 >>

OutrightMarketDepthSellMessageCapture ==
    << 72, 0, 11, 2, 224, 114, 154, 1, 240, 68, 238, 99, 88, 27, 0, 0,
       8, 0, 199, 1, 49, 1, 0, 0, 48, 0, 149, 1, 239, 68, 238, 99,
       144, 53, 154, 59, 11, 110, 141, 15, 223, 75, 0, 0, 56, 193, 1, 0,
       44, 195, 1, 0, 200, 13, 2, 0, 8, 0, 175, 0, 1, 0, 49, 0,
       0, 0, 0, 0, 0, 0, 0, 0 >>

RefreshOutrightMarketDepthBuyMessageCapture ==
    << 72, 0, 3, 2, 28, 215, 59, 1, 240, 68, 238, 99, 128, 169, 3, 0,
       8, 0, 199, 1, 209, 0, 0, 0, 48, 0, 247, 1, 235, 61, 238, 99,
       128, 130, 183, 44, 171, 41, 144, 15, 34, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 49, 0,
       0, 0, 0, 0, 0, 0, 0, 0 >>

RefreshOutrightMarketDepthSellMessageCapture ==
    << 72, 0, 3, 2, 188, 212, 113, 0, 240, 68, 238, 99, 152, 206, 17, 0,
       8, 0, 199, 1, 82, 0, 0, 0, 48, 0, 249, 1, 137, 67, 238, 99,
       144, 148, 177, 56, 161, 206, 133, 15, 18, 0, 0, 0, 148, 17, 0, 0,
       80, 195, 0, 0, 0, 0, 0, 0, 35, 0, 3, 0, 0, 0, 49, 0,
       0, 0, 0, 0, 0, 0, 0, 0 >>

StreamIdMessageCapture ==
    << 72, 0, 11, 2, 224, 114, 154, 1, 240, 68, 238, 99, 88, 27, 0, 0,
       8, 0, 199, 1, 49, 1, 0, 0, 48, 0, 149, 1, 239, 68, 238, 99,
       144, 53, 154, 59, 11, 110, 141, 15, 223, 75, 0, 0, 56, 193, 1, 0,
       44, 195, 1, 0, 200, 13, 2, 0, 8, 0, 175, 0, 1, 0, 49, 0,
       0, 0, 0, 0, 0, 0, 0, 0 >>

Captures == { OutrightMarketDepthBuyMessageCapture, OutrightMarketDepthSellMessageCapture, RefreshOutrightMarketDepthBuyMessageCapture, RefreshOutrightMarketDepthSellMessageCapture, StreamIdMessageCapture }

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
