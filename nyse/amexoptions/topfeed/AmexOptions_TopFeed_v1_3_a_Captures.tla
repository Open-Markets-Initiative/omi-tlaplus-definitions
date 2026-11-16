---------------- MODULE AmexOptions_TopFeed_v1_3_a_Captures ----------------
(***************************************************************************)
(* Recorded New York Stock Exchange Top Feed v1.3.a packets, as the bytes  *)
(* they were captured as. Each one decodes, consumes the whole packet, and *)
(* encodes back to exactly the bytes it was read from.                     *)
(***************************************************************************)
EXTENDS AmexOptions_TopFeed_v1_3_a

OutrightBoldRfqMessageCapture ==
    << 56, 0, 11, 2, 54, 59, 102, 1, 240, 68, 238, 99, 208, 205, 239, 38,
       8, 0, 199, 1, 65, 1, 0, 0, 32, 0, 215, 1, 240, 68, 238, 99,
       120, 178, 239, 38, 43, 135, 143, 15, 38, 187, 0, 0, 66, 48, 10, 0,
       88, 52, 0, 0, 32, 32, 32, 32 >>

OutrightCrossingRfqMessageCapture ==
    << 52, 0, 11, 2, 238, 21, 102, 1, 240, 68, 238, 99, 208, 23, 199, 15,
       8, 0, 199, 1, 65, 1, 0, 0, 28, 0, 159, 1, 240, 68, 238, 99,
       120, 252, 198, 15, 115, 157, 143, 15, 177, 11, 0, 0, 83, 80, 20, 0,
       200, 163, 2, 0 >>

OutrightQuoteMessageCapture ==
    << 64, 0, 11, 2, 58, 246, 16, 1, 240, 68, 238, 99, 176, 54, 0, 0,
       8, 0, 199, 1, 49, 1, 0, 0, 40, 0, 145, 1, 239, 68, 238, 99,
       144, 53, 154, 59, 11, 110, 141, 15, 54, 51, 0, 0, 56, 193, 1, 0,
       80, 189, 1, 0, 8, 0, 180, 0, 0, 0, 0, 0, 49, 0, 0, 0 >>

OutrightSeriesStatusMessageCapture ==
    << 84, 0, 11, 3, 177, 64, 104, 1, 240, 68, 238, 99, 208, 206, 53, 3,
       8, 0, 199, 1, 66, 1, 0, 0, 36, 0, 151, 1, 240, 68, 238, 99,
       40, 240, 52, 3, 143, 149, 143, 15, 145, 189, 0, 0, 224, 70, 0, 0,
       240, 60, 0, 0, 3, 0, 0, 0, 97, 32, 0, 0, 24, 0, 165, 1,
       240, 68, 238, 99, 112, 97, 53, 3, 143, 149, 143, 15, 146, 189, 0, 0,
       81, 32, 0, 0 >>

OutrightTradeMessageCapture ==
    << 60, 0, 11, 2, 152, 95, 210, 0, 240, 68, 238, 99, 8, 158, 130, 4,
       8, 0, 199, 1, 210, 0, 0, 0, 36, 0, 151, 1, 240, 68, 238, 99,
       136, 226, 129, 4, 57, 239, 144, 15, 136, 46, 0, 0, 48, 8, 0, 0,
       184, 36, 0, 0, 1, 0, 0, 0, 73, 32, 0, 0 >>

RefreshOutrightQuoteMessageCapture ==
    << 64, 0, 3, 2, 99, 203, 108, 0, 240, 68, 238, 99, 136, 54, 15, 0,
       8, 0, 199, 1, 177, 0, 0, 0, 40, 0, 245, 1, 237, 61, 238, 99,
       8, 245, 243, 14, 109, 226, 140, 15, 12, 0, 0, 0, 200, 0, 0, 0,
       0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 49, 0, 0, 0 >>

RefreshOutrightTradeMessageCapture ==
    << 60, 0, 3, 2, 211, 204, 116, 1, 240, 68, 238, 99, 208, 132, 125, 0,
       8, 0, 199, 1, 192, 0, 0, 0, 36, 0, 251, 1, 184, 64, 238, 99,
       240, 85, 125, 0, 153, 190, 142, 15, 202, 4, 0, 0, 238, 6, 0, 0,
       128, 62, 0, 0, 1, 0, 0, 0, 68, 32, 0, 0 >>

StreamIdMessageCapture ==
    << 64, 0, 11, 2, 58, 246, 16, 1, 240, 68, 238, 99, 176, 54, 0, 0,
       8, 0, 199, 1, 49, 1, 0, 0, 40, 0, 145, 1, 239, 68, 238, 99,
       144, 53, 154, 59, 11, 110, 141, 15, 54, 51, 0, 0, 56, 193, 1, 0,
       80, 189, 1, 0, 8, 0, 180, 0, 0, 0, 0, 0, 49, 0, 0, 0 >>

Captures == { OutrightBoldRfqMessageCapture, OutrightCrossingRfqMessageCapture, OutrightQuoteMessageCapture, OutrightSeriesStatusMessageCapture, OutrightTradeMessageCapture, RefreshOutrightQuoteMessageCapture, RefreshOutrightTradeMessageCapture, StreamIdMessageCapture }

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
