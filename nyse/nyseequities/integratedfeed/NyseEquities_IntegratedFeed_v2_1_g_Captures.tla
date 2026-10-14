------------ MODULE NyseEquities_IntegratedFeed_v2_1_g_Captures ------------
(***************************************************************************)
(* Recorded New York Stock Exchange Integrated Feed v2.1.g packets, as the *)
(* bytes they were captured as. Each one decodes, consumes the whole       *)
(* packet, and encodes back to exactly the bytes it was read from.         *)
(***************************************************************************)
EXTENDS NyseEquities_IntegratedFeed_v2_1_g

AddOrderMessageCapture ==
    << 55, 0, 11, 1, 221, 1, 0, 0, 167, 86, 206, 89, 202, 231, 229, 10,
       39, 0, 100, 0, 8, 83, 131, 58, 164, 44, 0, 0, 2, 0, 0, 0,
       1, 0, 0, 0, 0, 0, 0, 0, 244, 39, 2, 0, 100, 0, 0, 0,
       66, 32, 32, 32, 32, 32, 0 >>

CrossTradeMessageCapture ==
    << 45, 0, 11, 1, 182, 85, 1, 0, 184, 86, 206, 89, 31, 133, 242, 34,
       29, 0, 111, 0, 40, 107, 4, 39, 214, 40, 0, 0, 114, 0, 0, 0,
       1, 0, 0, 0, 116, 90, 4, 0, 16, 6, 0, 0, 79 >>

DeleteOrderMessageCapture ==
    << 41, 0, 11, 1, 73, 12, 0, 0, 167, 86, 206, 89, 237, 114, 181, 42,
       25, 0, 102, 0, 136, 147, 90, 37, 208, 35, 0, 0, 15, 0, 0, 0,
       220, 11, 0, 0, 0, 0, 0, 0, 0 >>

ImbalanceMessageCapture ==
    << 83, 0, 11, 1, 223, 126, 0, 0, 173, 86, 206, 89, 12, 142, 214, 34,
       67, 0, 105, 0, 200, 175, 166, 89, 56, 187, 2, 0, 145, 4, 0, 0,
       23, 0, 0, 0, 84, 194, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 162, 3, 77, 66, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0 >>

ModifyOrderMessageCapture ==
    << 51, 0, 11, 1, 16, 62, 0, 0, 170, 86, 206, 89, 46, 137, 213, 15,
       35, 0, 101, 0, 104, 146, 228, 57, 155, 42, 0, 0, 20, 0, 0, 0,
       169, 59, 0, 0, 0, 0, 0, 0, 24, 72, 4, 0, 44, 1, 0, 0,
       0, 0, 0 >>

NonDisplayedTradeMessageCapture ==
    << 49, 0, 11, 1, 191, 85, 1, 0, 184, 86, 206, 89, 127, 253, 13, 35,
       33, 0, 110, 0, 40, 107, 4, 39, 214, 40, 0, 0, 123, 0, 0, 0,
       7, 0, 0, 0, 116, 90, 4, 0, 144, 1, 0, 0, 0, 1, 0, 0,
       0 >>

OrderExecutionMessageCapture ==
    << 58, 0, 11, 1, 183, 85, 1, 0, 184, 86, 206, 89, 127, 146, 245, 34,
       42, 0, 103, 0, 40, 107, 4, 39, 214, 40, 0, 0, 115, 0, 0, 0,
       108, 16, 1, 0, 0, 0, 0, 0, 2, 0, 0, 0, 116, 90, 4, 0,
       16, 0, 0, 0, 0, 0, 1, 0, 0, 0 >>

ReplaceOrderMessageCapture ==
    << 58, 0, 11, 1, 89, 19, 0, 0, 168, 86, 206, 89, 47, 67, 169, 4,
       42, 0, 104, 0, 216, 10, 62, 37, 34, 9, 0, 0, 28, 0, 0, 0,
       23, 2, 0, 0, 0, 0, 0, 0, 241, 18, 0, 0, 0, 0, 0, 0,
       240, 156, 9, 0, 44, 1, 0, 0, 0, 0 >>

SecurityStatusMessageCapture ==
    << 62, 0, 11, 1, 238, 0, 0, 0, 167, 86, 206, 89, 156, 104, 12, 8,
       46, 0, 34, 0, 43, 68, 166, 89, 16, 214, 180, 45, 145, 4, 0, 0,
       1, 0, 0, 0, 80, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 126, 80, 32 >>

SequenceNumberResetMessageCapture ==
    << 30, 0, 12, 1, 1, 0, 0, 0, 167, 86, 206, 89, 161, 180, 56, 5,
       14, 0, 1, 0, 129, 161, 202, 89, 130, 192, 237, 11, 11, 1 >>

SourceTimeReferenceMessageCapture ==
    << 32, 0, 11, 1, 237, 0, 0, 0, 167, 86, 206, 89, 92, 91, 9, 8,
       16, 0, 2, 0, 7, 0, 0, 0, 0, 0, 0, 0, 43, 68, 166, 89 >>

SymbolIndexMappingMessageCapture ==
    << 60, 0, 11, 1, 2, 0, 0, 0, 167, 86, 206, 89, 187, 168, 59, 5,
       44, 0, 3, 0, 145, 4, 0, 0, 65, 66, 71, 0, 0, 0, 0, 0,
       0, 0, 0, 65, 1, 0, 7, 78, 4, 65, 100, 0, 84, 194, 7, 0,
       0, 0, 0, 0, 0, 78, 244, 1, 1, 0, 0, 0 >>

Captures == { AddOrderMessageCapture, CrossTradeMessageCapture, DeleteOrderMessageCapture, ImbalanceMessageCapture, ModifyOrderMessageCapture, NonDisplayedTradeMessageCapture, OrderExecutionMessageCapture, ReplaceOrderMessageCapture, SecurityStatusMessageCapture, SequenceNumberResetMessageCapture, SourceTimeReferenceMessageCapture, SymbolIndexMappingMessageCapture }

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
