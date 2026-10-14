------------ MODULE AmexEquities_IntegratedFeed_v2_1_g_Captures ------------
(***************************************************************************)
(* Recorded New York Stock Exchange Integrated Feed v2.1.g packets, as the *)
(* bytes they were captured as. Each one decodes, consumes the whole       *)
(* packet, and encodes back to exactly the bytes it was read from.         *)
(***************************************************************************)
EXTENDS AmexEquities_IntegratedFeed_v2_1_g

AddOrderMessageCapture ==
    << 55, 0, 11, 1, 126, 247, 18, 0, 159, 87, 206, 89, 95, 86, 134, 45,
       39, 0, 100, 0, 64, 146, 77, 43, 207, 9, 0, 0, 27, 26, 0, 0,
       11, 57, 21, 0, 0, 0, 0, 0, 252, 116, 7, 0, 61, 0, 0, 0,
       66, 32, 32, 32, 32, 32, 0 >>

ImbalanceMessageCapture ==
    << 83, 0, 11, 1, 61, 94, 58, 0, 164, 89, 206, 89, 238, 58, 168, 22,
       67, 0, 105, 0, 64, 25, 167, 89, 0, 98, 43, 4, 107, 5, 0, 0,
       78, 54, 0, 0, 228, 219, 3, 0, 240, 60, 0, 0, 244, 1, 0, 0,
       0, 0, 0, 0, 64, 6, 67, 66, 228, 219, 3, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0 >>

OrderExecutionMessageCapture ==
    << 58, 0, 11, 1, 154, 248, 36, 0, 139, 88, 206, 89, 151, 74, 184, 49,
       42, 0, 103, 0, 32, 227, 142, 59, 145, 10, 0, 0, 231, 17, 2, 0,
       135, 125, 38, 0, 0, 0, 0, 0, 147, 120, 1, 0, 192, 237, 1, 0,
       100, 0, 0, 0, 1, 0, 168, 10, 0, 0 >>

ReplaceOrderMessageCapture ==
    << 58, 0, 11, 1, 5, 248, 36, 0, 139, 88, 206, 89, 61, 128, 241, 47,
       42, 0, 104, 0, 160, 192, 127, 26, 106, 30, 0, 0, 164, 151, 0, 0,
       170, 99, 39, 0, 0, 0, 0, 0, 3, 100, 39, 0, 0, 0, 0, 0,
       212, 130, 3, 0, 100, 0, 0, 0, 0, 0 >>

SecurityStatusMessageCapture ==
    << 62, 0, 11, 1, 242, 0, 0, 0, 159, 91, 206, 89, 205, 73, 99, 21,
       46, 0, 34, 0, 25, 211, 176, 89, 112, 90, 81, 2, 246, 168, 0, 0,
       1, 0, 0, 0, 80, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 126, 80, 32 >>

SequenceNumberResetMessageCapture ==
    << 30, 0, 12, 1, 1, 0, 0, 0, 167, 86, 206, 89, 161, 180, 56, 5,
       14, 0, 1, 0, 129, 161, 202, 89, 130, 192, 237, 11, 11, 1 >>

SourceTimeReferenceMessageCapture ==
    << 32, 0, 11, 1, 216, 7, 0, 0, 167, 86, 206, 89, 29, 250, 38, 29,
       16, 0, 2, 0, 7, 0, 0, 0, 0, 0, 0, 0, 186, 161, 166, 89 >>

SymbolIndexMappingMessageCapture ==
    << 60, 0, 11, 1, 2, 0, 0, 0, 167, 86, 206, 89, 187, 168, 59, 5,
       44, 0, 3, 0, 145, 4, 0, 0, 65, 66, 71, 0, 0, 0, 0, 0,
       0, 0, 0, 65, 1, 0, 7, 78, 4, 65, 100, 0, 84, 194, 7, 0,
       0, 0, 0, 0, 0, 78, 244, 1, 1, 0, 0, 0 >>

Captures == { AddOrderMessageCapture, ImbalanceMessageCapture, OrderExecutionMessageCapture, ReplaceOrderMessageCapture, SecurityStatusMessageCapture, SequenceNumberResetMessageCapture, SourceTimeReferenceMessageCapture, SymbolIndexMappingMessageCapture }

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
