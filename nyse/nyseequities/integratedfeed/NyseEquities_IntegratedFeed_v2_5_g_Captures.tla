------------ MODULE NyseEquities_IntegratedFeed_v2_5_g_Captures ------------
(***************************************************************************)
(* Recorded New York Stock Exchange Integrated Feed v2.5.g packets, as the *)
(* bytes they were captured as. Each one decodes, consumes the whole       *)
(* packet, and encodes back to exactly the bytes it was read from.         *)
(***************************************************************************)
EXTENDS NyseEquities_IntegratedFeed_v2_5_g

AddOrderMessageCapture ==
    << 55, 0, 11, 1, 251, 22, 6, 0, 87, 184, 228, 100, 0, 85, 152, 59,
       39, 0, 100, 0, 0, 59, 152, 59, 131, 30, 1, 0, 138, 34, 0, 0,
       124, 151, 5, 0, 0, 1, 53, 0, 80, 67, 170, 3, 144, 1, 0, 0,
       83, 32, 32, 32, 32, 32, 0 >>

CrossTradeMessageCapture ==
    << 45, 0, 11, 1, 122, 153, 7, 0, 121, 184, 228, 100, 0, 209, 140, 22,
       29, 0, 111, 0, 0, 153, 140, 22, 20, 21, 1, 0, 40, 5, 0, 0,
       220, 103, 0, 0, 192, 154, 94, 0, 97, 227, 0, 0, 79 >>

DeleteOrderMessageCapture ==
    << 41, 0, 11, 1, 88, 181, 1, 0, 87, 184, 228, 100, 0, 126, 152, 59,
       25, 0, 102, 0, 0, 96, 152, 59, 176, 239, 0, 0, 15, 0, 0, 0,
       69, 91, 5, 0, 0, 1, 63, 0, 0 >>

ImbalanceMessageCapture ==
    << 89, 0, 11, 1, 183, 25, 5, 0, 88, 184, 228, 100, 0, 179, 93, 40,
       73, 0, 105, 0, 88, 184, 228, 100, 0, 126, 93, 40, 251, 251, 0, 0,
       214, 0, 0, 0, 160, 73, 26, 1, 87, 1, 0, 0, 44, 1, 0, 0,
       0, 0, 0, 0, 162, 3, 77, 83, 112, 212, 25, 1, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 32, 32 >>

ModifyOrderMessageCapture ==
    << 51, 0, 11, 1, 237, 72, 5, 0, 88, 184, 228, 100, 0, 22, 60, 1,
       35, 0, 101, 0, 0, 106, 232, 0, 91, 5, 1, 0, 49, 4, 0, 0,
       208, 157, 4, 0, 0, 1, 54, 0, 112, 224, 4, 0, 254, 25, 0, 0,
       0, 83, 0 >>

NonDisplayedTradeMessageCapture ==
    << 49, 0, 11, 1, 127, 142, 1, 0, 88, 184, 228, 100, 0, 115, 31, 6,
       33, 0, 110, 0, 0, 64, 31, 6, 89, 114, 0, 0, 38, 22, 0, 0,
       254, 17, 0, 0, 72, 168, 220, 0, 100, 0, 0, 0, 1, 64, 32, 32,
       32 >>

OrderExecutionMessageCapture ==
    << 58, 0, 11, 1, 154, 128, 1, 0, 88, 184, 228, 100, 0, 223, 7, 0,
       42, 0, 103, 0, 0, 157, 7, 0, 52, 64, 0, 0, 31, 0, 0, 0,
       217, 117, 4, 0, 0, 1, 61, 0, 109, 13, 0, 0, 32, 245, 112, 1,
       176, 4, 0, 0, 1, 0, 64, 70, 84, 32 >>

ReplaceOrderMessageCapture ==
    << 58, 0, 11, 1, 59, 251, 1, 0, 87, 184, 228, 100, 0, 222, 151, 59,
       42, 0, 104, 0, 0, 178, 151, 59, 78, 163, 0, 0, 36, 27, 0, 0,
       48, 70, 4, 0, 0, 1, 60, 0, 66, 70, 4, 0, 0, 1, 60, 0,
       128, 160, 168, 4, 100, 0, 0, 0, 66, 0 >>

RetailPriceImprovementMessageCapture ==
    << 33, 0, 11, 1, 34, 252, 1, 0, 88, 184, 228, 100, 0, 110, 123, 0,
       17, 0, 114, 0, 0, 249, 122, 0, 183, 115, 0, 0, 62, 0, 0, 0,
       65 >>

SecurityStatusMessageCapture ==
    << 62, 0, 11, 1, 221, 128, 1, 0, 88, 184, 228, 100, 0, 82, 87, 0,
       46, 0, 34, 0, 88, 184, 228, 100, 0, 2, 87, 0, 208, 39, 0, 0,
       6, 0, 0, 0, 79, 126, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 126, 79, 0 >>

SequenceNumberResetMessageCapture ==
    << 30, 0, 12, 1, 1, 0, 0, 0, 238, 56, 228, 100, 0, 40, 75, 32,
       14, 0, 1, 0, 168, 56, 228, 100, 0, 123, 147, 20, 11, 53 >>

SourceTimeReferenceMessageCapture ==
    << 32, 0, 11, 1, 190, 122, 5, 0, 88, 184, 228, 100, 0, 49, 0, 0,
       16, 0, 2, 0, 51, 0, 0, 0, 0, 0, 0, 0, 88, 184, 228, 100 >>

SymbolClearMessageCapture ==
    << 36, 0, 11, 1, 3, 0, 0, 0, 41, 57, 228, 100, 0, 91, 173, 17,
       20, 0, 32, 0, 41, 57, 228, 100, 0, 76, 162, 17, 74, 39, 0, 0,
       1, 0, 0, 0 >>

SymbolIndexMappingMessageCapture ==
    << 60, 0, 11, 1, 2, 0, 0, 0, 41, 57, 228, 100, 0, 91, 173, 17,
       44, 0, 3, 0, 74, 39, 0, 0, 87, 84, 82, 71, 0, 0, 0, 0,
       0, 0, 0, 0, 1, 0, 58, 78, 6, 67, 100, 0, 224, 55, 49, 2,
       0, 0, 0, 0, 0, 78, 100, 0, 1, 0, 0, 0 >>

Captures == { AddOrderMessageCapture, CrossTradeMessageCapture, DeleteOrderMessageCapture, ImbalanceMessageCapture, ModifyOrderMessageCapture, NonDisplayedTradeMessageCapture, OrderExecutionMessageCapture, ReplaceOrderMessageCapture, RetailPriceImprovementMessageCapture, SecurityStatusMessageCapture, SequenceNumberResetMessageCapture, SourceTimeReferenceMessageCapture, SymbolClearMessageCapture, SymbolIndexMappingMessageCapture }

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
