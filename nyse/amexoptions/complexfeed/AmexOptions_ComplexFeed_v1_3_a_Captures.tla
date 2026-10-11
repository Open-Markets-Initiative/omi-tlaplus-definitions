-------------- MODULE AmexOptions_ComplexFeed_v1_3_a_Captures --------------
(***************************************************************************)
(* Recorded New York Stock Exchange Complex Feed v1.3.a packets, as the    *)
(* bytes they were captured as. Each one decodes, consumes the whole       *)
(* packet, and encodes back to exactly the bytes it was read from.         *)
(***************************************************************************)
EXTENDS AmexOptions_ComplexFeed_v1_3_a

ComplexCrossingRfqMessageCapture ==
    << 52, 0, 11, 2, 45, 17, 3, 0, 240, 68, 238, 99, 56, 189, 172, 48,
       8, 0, 199, 1, 51, 0, 0, 0, 28, 0, 173, 1, 240, 68, 238, 99,
       112, 138, 172, 48, 34, 162, 147, 15, 209, 0, 0, 0, 83, 0, 1, 0,
       255, 201, 154, 59 >>

ComplexQuoteMessageCapture ==
    << 64, 0, 11, 2, 107, 109, 8, 0, 240, 68, 238, 99, 64, 32, 223, 1,
       8, 0, 199, 1, 67, 0, 0, 0, 40, 0, 167, 1, 240, 68, 238, 99,
       24, 253, 222, 1, 1, 170, 147, 15, 35, 0, 0, 0, 68, 47, 0, 0,
       0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 49, 0, 0, 0 >>

ComplexStatusMessageCapture ==
    << 48, 0, 11, 2, 203, 109, 9, 0, 240, 68, 238, 99, 112, 109, 74, 20,
       8, 0, 199, 1, 35, 0, 0, 0, 24, 0, 177, 1, 240, 68, 238, 99,
       48, 78, 74, 20, 237, 171, 147, 15, 6, 0, 0, 0, 81, 32, 0, 0 >>

ComplexSymbolDefinitionMessageCapture ==
    << 80, 0, 11, 2, 30, 22, 2, 0, 240, 68, 238, 99, 16, 78, 31, 25,
       8, 0, 199, 1, 115, 0, 0, 0, 56, 0, 183, 1, 173, 160, 147, 15,
       56, 76, 67, 73, 68, 50, 51, 48, 52, 55, 54, 48, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 123, 8, 0, 7, 0, 115, 0, 2, 0, 0, 0,
       76, 142, 137, 15, 1, 0, 83, 79, 127, 142, 137, 15, 1, 0, 66, 79 >>

ComplexTradeMessageCapture ==
    << 60, 0, 11, 2, 2, 10, 13, 0, 240, 68, 238, 99, 224, 247, 237, 7,
       8, 0, 199, 1, 67, 1, 0, 0, 36, 0, 169, 1, 240, 68, 238, 99,
       136, 220, 237, 7, 92, 175, 147, 15, 5, 0, 0, 0, 7, 1, 0, 0,
       8, 82, 0, 0, 3, 0, 0, 0, 32, 102, 0, 0 >>

RefreshComplexQuoteMessageCapture ==
    << 64, 0, 3, 2, 178, 174, 1, 0, 240, 68, 238, 99, 176, 167, 2, 0,
       8, 0, 199, 1, 51, 1, 0, 0, 40, 0, 255, 1, 199, 63, 238, 99,
       136, 115, 130, 59, 34, 159, 147, 15, 7, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 49, 0, 0, 0 >>

RefreshComplexTradeMessageCapture ==
    << 60, 0, 3, 2, 126, 241, 0, 0, 240, 68, 238, 99, 160, 105, 223, 2,
       8, 0, 199, 1, 19, 1, 0, 0, 36, 0, 1, 2, 64, 64, 238, 99,
       168, 62, 223, 2, 147, 158, 147, 15, 11, 0, 0, 0, 20, 0, 0, 0,
       160, 90, 0, 0, 1, 0, 0, 0, 32, 102, 0, 0 >>

StreamIdMessageCapture ==
    << 48, 0, 11, 2, 203, 109, 9, 0, 240, 68, 238, 99, 112, 109, 74, 20,
       8, 0, 199, 1, 35, 0, 0, 0, 24, 0, 177, 1, 240, 68, 238, 99,
       48, 78, 74, 20, 237, 171, 147, 15, 6, 0, 0, 0, 81, 32, 0, 0 >>

Captures == { ComplexCrossingRfqMessageCapture, ComplexQuoteMessageCapture, ComplexStatusMessageCapture, ComplexSymbolDefinitionMessageCapture, ComplexTradeMessageCapture, RefreshComplexQuoteMessageCapture, RefreshComplexTradeMessageCapture, StreamIdMessageCapture }

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
