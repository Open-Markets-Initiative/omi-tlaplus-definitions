---------------- MODULE AmexOptions_TopFeed_v1_2_k_Captures ----------------
(***************************************************************************)
(* Recorded New York Stock Exchange Top Feed v1.2.k packets, as the bytes  *)
(* they were captured as. Each one decodes, consumes the whole packet, and *)
(* encodes back to exactly the bytes it was read from.                     *)
(***************************************************************************)
EXTENDS AmexOptions_TopFeed_v1_2_k

OptionsQuoteMessageCapture ==
    << 58, 0, 11, 1, 175, 94, 6, 0, 15, 234, 69, 97, 0, 178, 153, 17,
       42, 0, 84, 1, 0, 34, 153, 17, 13, 62, 1, 2, 3, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       50, 0, 0, 0, 0, 0, 0, 0, 0, 0 >>

OptionsStatusMessageCapture ==
    << 39, 0, 11, 1, 163, 197, 4, 0, 120, 149, 69, 97, 0, 161, 17, 1,
       23, 0, 51, 0, 120, 149, 69, 97, 0, 111, 17, 1, 244, 184, 136, 1,
       2, 0, 0, 0, 66, 80, 126 >>

OutrightSeriesIndexMappingMessageCapture ==
    << 114, 0, 11, 3, 83, 0, 0, 0, 22, 115, 69, 97, 0, 88, 60, 19,
       55, 0, 50, 0, 188, 92, 133, 1, 0, 4, 0, 51, 70, 68, 88, 0,
       0, 0, 70, 68, 88, 0, 0, 0, 0, 0, 0, 0, 0, 128, 24, 0,
       0, 4, 100, 0, 50, 49, 49, 50, 49, 55, 1, 49, 48, 48, 0, 0,
       0, 0, 0, 0, 0, 48, 0, 20, 0, 32, 0, 22, 115, 69, 97, 0,
       205, 59, 19, 188, 92, 133, 1, 1, 0, 0, 0, 23, 0, 51, 0, 22,
       115, 69, 97, 0, 205, 59, 19, 188, 92, 133, 1, 1, 0, 0, 0, 80,
       80, 126 >>

SecurityStatusMessageCapture ==
    << 62, 0, 11, 1, 154, 197, 4, 0, 24, 115, 69, 97, 0, 250, 184, 13,
       46, 0, 34, 0, 24, 115, 69, 97, 0, 198, 184, 13, 29, 5, 1, 0,
       2, 0, 0, 0, 67, 126, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 69, 80, 0 >>

SequenceNumberResetMessageCapture ==
    << 30, 0, 12, 1, 1, 0, 0, 0, 109, 114, 69, 97, 0, 14, 190, 48,
       14, 0, 1, 0, 55, 114, 69, 97, 0, 188, 40, 26, 162, 51 >>

SourceTimeReferenceMessageCapture ==
    << 74, 0, 11, 2, 219, 94, 6, 0, 59, 234, 69, 97, 0, 113, 86, 33,
       16, 0, 2, 0, 51, 0, 0, 0, 0, 0, 0, 0, 59, 234, 69, 97,
       42, 0, 84, 1, 0, 3, 86, 33, 194, 99, 243, 1, 3, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       50, 0, 0, 0, 0, 0, 0, 0, 0, 0 >>

SymbolClearMessageCapture ==
    << 59, 0, 11, 2, 94, 32, 0, 0, 22, 115, 69, 97, 0, 180, 60, 27,
       20, 0, 32, 0, 22, 115, 69, 97, 0, 59, 60, 27, 67, 147, 234, 1,
       1, 0, 0, 0, 23, 0, 51, 0, 22, 115, 69, 97, 0, 59, 60, 27,
       67, 147, 234, 1, 1, 0, 0, 0, 80, 80, 126 >>

SymbolIndexMappingMessageCapture ==
    << 126, 0, 11, 3, 29, 0, 0, 0, 22, 115, 69, 97, 0, 133, 36, 19,
       44, 0, 3, 0, 145, 15, 0, 0, 84, 69, 86, 65, 0, 0, 0, 0,
       0, 0, 0, 0, 4, 0, 51, 78, 6, 72, 100, 0, 48, 45, 137, 0,
       0, 0, 0, 0, 0, 78, 100, 0, 1, 0, 0, 0, 20, 0, 32, 0,
       22, 115, 69, 97, 0, 154, 34, 19, 145, 15, 0, 0, 1, 0, 0, 0,
       46, 0, 34, 0, 22, 115, 69, 97, 0, 154, 34, 19, 145, 15, 0, 0,
       1, 0, 0, 0, 80, 126, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 126, 80, 0 >>

Captures == { OptionsQuoteMessageCapture, OptionsStatusMessageCapture, OutrightSeriesIndexMappingMessageCapture, SecurityStatusMessageCapture, SequenceNumberResetMessageCapture, SourceTimeReferenceMessageCapture, SymbolClearMessageCapture, SymbolIndexMappingMessageCapture }

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
