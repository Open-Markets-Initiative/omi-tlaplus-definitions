--------------- MODULE AmexOptions_DeepFeed_v1_2_m_Captures ----------------
(***************************************************************************)
(* Recorded New York Stock Exchange Deep Feed v1.2.m packets, as the bytes *)
(* they were captured as. Each one decodes, consumes the whole packet, and *)
(* encodes back to exactly the bytes it was read from.                     *)
(***************************************************************************)
EXTENDS AmexOptions_DeepFeed_v1_2_m

OptionsAddOrderMessageCapture ==
    << 72, 0, 11, 2, 176, 46, 12, 0, 105, 242, 69, 97, 0, 122, 116, 24,
       16, 0, 2, 0, 51, 0, 0, 0, 0, 0, 0, 0, 105, 242, 69, 97,
       40, 0, 44, 1, 0, 0, 116, 24, 51, 152, 7, 2, 19, 0, 0, 0,
       36, 0, 0, 0, 0, 0, 51, 0, 128, 169, 3, 0, 10, 0, 0, 0,
       83, 32, 32, 32, 32, 32, 0, 78 >>

OptionsDeleteOrderMessageCapture ==
    << 41, 0, 11, 1, 203, 46, 12, 0, 49, 245, 69, 97, 0, 251, 201, 48,
       25, 0, 46, 1, 0, 209, 201, 48, 202, 136, 232, 1, 12, 0, 0, 0,
       177, 0, 0, 0, 0, 0, 51, 0, 0 >>

OptionsImbalanceMessageCapture ==
    << 81, 0, 11, 1, 186, 93, 6, 0, 73, 212, 69, 97, 0, 12, 12, 3,
       65, 0, 49, 1, 73, 212, 69, 97, 0, 233, 11, 3, 125, 192, 246, 1,
       4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 72, 32, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0 >>

OptionsStatusMessageCapture ==
    << 39, 0, 11, 1, 78, 13, 0, 0, 22, 115, 69, 97, 0, 132, 53, 23,
       23, 0, 51, 0, 22, 115, 69, 97, 0, 31, 53, 23, 165, 91, 202, 1,
       1, 0, 0, 0, 80, 80, 126 >>

OutrightSeriesIndexMappingMessageCapture ==
    << 114, 0, 11, 3, 83, 0, 0, 0, 22, 115, 69, 97, 0, 57, 60, 19,
       55, 0, 50, 0, 188, 92, 133, 1, 0, 4, 0, 51, 70, 68, 88, 0,
       0, 0, 70, 68, 88, 0, 0, 0, 0, 0, 0, 0, 0, 128, 24, 0,
       0, 4, 100, 0, 50, 49, 49, 50, 49, 55, 1, 49, 48, 48, 0, 0,
       0, 0, 0, 0, 0, 48, 0, 20, 0, 32, 0, 22, 115, 69, 97, 0,
       205, 59, 19, 188, 92, 133, 1, 1, 0, 0, 0, 23, 0, 51, 0, 22,
       115, 69, 97, 0, 205, 59, 19, 188, 92, 133, 1, 1, 0, 0, 0, 80,
       80, 126 >>

SecurityStatusMessageCapture ==
    << 62, 0, 11, 1, 28, 0, 0, 0, 22, 115, 69, 97, 0, 78, 32, 19,
       46, 0, 34, 0, 22, 115, 69, 97, 0, 200, 31, 19, 17, 126, 0, 0,
       1, 0, 0, 0, 80, 126, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 126, 80, 0 >>

SequenceNumberResetMessageCapture ==
    << 30, 0, 12, 1, 1, 0, 0, 0, 109, 114, 69, 97, 0, 35, 190, 48,
       14, 0, 1, 0, 55, 114, 69, 97, 0, 188, 40, 26, 161, 51 >>

SourceTimeReferenceMessageCapture ==
    << 72, 0, 11, 2, 176, 46, 12, 0, 105, 242, 69, 97, 0, 122, 116, 24,
       16, 0, 2, 0, 51, 0, 0, 0, 0, 0, 0, 0, 105, 242, 69, 97,
       40, 0, 44, 1, 0, 0, 116, 24, 51, 152, 7, 2, 19, 0, 0, 0,
       36, 0, 0, 0, 0, 0, 51, 0, 128, 169, 3, 0, 10, 0, 0, 0,
       83, 32, 32, 32, 32, 32, 0, 78 >>

SymbolClearMessageCapture ==
    << 126, 0, 11, 3, 29, 0, 0, 0, 22, 115, 69, 97, 0, 91, 36, 19,
       44, 0, 3, 0, 145, 15, 0, 0, 84, 69, 86, 65, 0, 0, 0, 0,
       0, 0, 0, 0, 4, 0, 51, 78, 6, 72, 100, 0, 48, 45, 137, 0,
       0, 0, 0, 0, 0, 78, 100, 0, 1, 0, 0, 0, 20, 0, 32, 0,
       22, 115, 69, 97, 0, 154, 34, 19, 145, 15, 0, 0, 1, 0, 0, 0,
       46, 0, 34, 0, 22, 115, 69, 97, 0, 154, 34, 19, 145, 15, 0, 0,
       1, 0, 0, 0, 80, 126, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 126, 80, 0 >>

SymbolIndexMappingMessageCapture ==
    << 126, 0, 11, 3, 29, 0, 0, 0, 22, 115, 69, 97, 0, 91, 36, 19,
       44, 0, 3, 0, 145, 15, 0, 0, 84, 69, 86, 65, 0, 0, 0, 0,
       0, 0, 0, 0, 4, 0, 51, 78, 6, 72, 100, 0, 48, 45, 137, 0,
       0, 0, 0, 0, 0, 78, 100, 0, 1, 0, 0, 0, 20, 0, 32, 0,
       22, 115, 69, 97, 0, 154, 34, 19, 145, 15, 0, 0, 1, 0, 0, 0,
       46, 0, 34, 0, 22, 115, 69, 97, 0, 154, 34, 19, 145, 15, 0, 0,
       1, 0, 0, 0, 80, 126, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 126, 80, 0 >>

Captures == { OptionsAddOrderMessageCapture, OptionsDeleteOrderMessageCapture, OptionsImbalanceMessageCapture, OptionsStatusMessageCapture, OutrightSeriesIndexMappingMessageCapture, SecurityStatusMessageCapture, SequenceNumberResetMessageCapture, SourceTimeReferenceMessageCapture, SymbolClearMessageCapture, SymbolIndexMappingMessageCapture }

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
