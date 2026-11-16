-------------- MODULE ArcaOptions_ComplexFeed_v1_0_h_Captures --------------
(***************************************************************************)
(* Recorded New York Stock Exchange Complex Feed v1.0.h packets, as the    *)
(* bytes they were captured as. Each one decodes, consumes the whole       *)
(* packet, and encodes back to exactly the bytes it was read from.         *)
(***************************************************************************)
EXTENDS ArcaOptions_ComplexFeed_v1_0_h

ComplexSeriesIndexMappingMessageCapture ==
    << 111, 0, 11, 4, 238, 135, 3, 0, 240, 68, 238, 99, 0, 58, 203, 0,
       29, 0, 60, 0, 148, 226, 143, 81, 4, 0, 60, 2, 0, 195, 231, 124,
       2, 1, 0, 66, 79, 197, 231, 124, 2, 1, 0, 83, 79, 20, 0, 32,
       0, 240, 68, 238, 99, 0, 112, 202, 0, 148, 226, 143, 81, 1, 0, 0,
       0, 23, 0, 51, 0, 240, 68, 238, 99, 0, 112, 202, 0, 148, 226, 143,
       81, 1, 0, 0, 0, 66, 79, 126, 23, 0, 51, 0, 240, 68, 238, 99,
       0, 112, 202, 0, 148, 226, 143, 81, 2, 0, 0, 0, 79, 79, 126 >>

OptionsQuoteMessageCapture ==
    << 58, 0, 11, 1, 242, 135, 3, 0, 240, 68, 238, 99, 0, 186, 203, 0,
       42, 0, 84, 1, 0, 162, 203, 0, 148, 226, 143, 81, 3, 0, 0, 0,
       100, 50, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       49, 0, 0, 0, 0, 0, 0, 0, 0, 0 >>

OptionsStatusMessageCapture ==
    << 111, 0, 11, 4, 238, 135, 3, 0, 240, 68, 238, 99, 0, 58, 203, 0,
       29, 0, 60, 0, 148, 226, 143, 81, 4, 0, 60, 2, 0, 195, 231, 124,
       2, 1, 0, 66, 79, 197, 231, 124, 2, 1, 0, 83, 79, 20, 0, 32,
       0, 240, 68, 238, 99, 0, 112, 202, 0, 148, 226, 143, 81, 1, 0, 0,
       0, 23, 0, 51, 0, 240, 68, 238, 99, 0, 112, 202, 0, 148, 226, 143,
       81, 1, 0, 0, 0, 66, 79, 126, 23, 0, 51, 0, 240, 68, 238, 99,
       0, 112, 202, 0, 148, 226, 143, 81, 2, 0, 0, 0, 79, 79, 126 >>

OptionsTradeMessageCapture ==
    << 52, 0, 11, 1, 177, 224, 0, 0, 240, 68, 238, 99, 0, 241, 45, 47,
       36, 0, 64, 1, 240, 68, 238, 99, 0, 145, 45, 47, 246, 50, 140, 81,
       9, 0, 0, 0, 15, 92, 89, 0, 44, 207, 255, 255, 40, 0, 0, 0,
       106, 32, 0, 32 >>

SourceTimeReferenceMessageCapture ==
    << 74, 0, 11, 2, 80, 189, 8, 0, 240, 68, 238, 99, 0, 198, 85, 0,
       16, 0, 2, 0, 51, 0, 0, 0, 0, 0, 0, 0, 240, 68, 238, 99,
       42, 0, 84, 1, 0, 60, 85, 0, 45, 117, 138, 81, 106, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       49, 0, 0, 0, 0, 0, 0, 0, 0, 0 >>

SymbolClearMessageCapture ==
    << 111, 0, 11, 4, 238, 135, 3, 0, 240, 68, 238, 99, 0, 58, 203, 0,
       29, 0, 60, 0, 148, 226, 143, 81, 4, 0, 60, 2, 0, 195, 231, 124,
       2, 1, 0, 66, 79, 197, 231, 124, 2, 1, 0, 83, 79, 20, 0, 32,
       0, 240, 68, 238, 99, 0, 112, 202, 0, 148, 226, 143, 81, 1, 0, 0,
       0, 23, 0, 51, 0, 240, 68, 238, 99, 0, 112, 202, 0, 148, 226, 143,
       81, 1, 0, 0, 0, 66, 79, 126, 23, 0, 51, 0, 240, 68, 238, 99,
       0, 112, 202, 0, 148, 226, 143, 81, 2, 0, 0, 0, 79, 79, 126 >>

Captures == { ComplexSeriesIndexMappingMessageCapture, OptionsQuoteMessageCapture, OptionsStatusMessageCapture, OptionsTradeMessageCapture, SourceTimeReferenceMessageCapture, SymbolClearMessageCapture }

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
