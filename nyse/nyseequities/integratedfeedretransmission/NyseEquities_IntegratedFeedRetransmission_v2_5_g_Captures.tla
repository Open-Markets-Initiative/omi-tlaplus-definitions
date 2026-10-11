----- MODULE NyseEquities_IntegratedFeedRetransmission_v2_5_g_Captures -----
(***************************************************************************)
(* Recorded New York Stock Exchange Integrated Feed Retransmission v2.5.g  *)
(* packets, as the bytes they were captured as. Each one decodes, consumes *)
(* the whole packet, and encodes back to exactly the bytes it was read     *)
(* from.                                                                   *)
(***************************************************************************)
EXTENDS NyseEquities_IntegratedFeedRetransmission_v2_5_g

AddOrderMessageCapture ==
    << 55, 0, 13, 1, 58, 116, 7, 0, 90, 184, 228, 100, 208, 199, 186, 47,
       39, 0, 100, 0, 0, 64, 37, 32, 156, 22, 0, 0, 85, 184, 0, 0,
       130, 221, 9, 0, 0, 1, 53, 0, 32, 177, 16, 5, 107, 0, 0, 0,
       66, 32, 32, 32, 32, 32, 0 >>

CrossTradeMessageCapture ==
    << 45, 0, 15, 1, 232, 213, 5, 0, 89, 184, 228, 100, 240, 208, 131, 6,
       29, 0, 111, 0, 0, 1, 62, 43, 117, 163, 0, 0, 5, 5, 0, 0,
       89, 13, 0, 0, 208, 10, 56, 1, 179, 114, 0, 0, 79 >>

DeleteOrderMessageCapture ==
    << 41, 0, 15, 1, 185, 205, 5, 0, 90, 184, 228, 100, 184, 144, 122, 35,
       25, 0, 102, 0, 0, 5, 250, 43, 161, 23, 0, 0, 40, 2, 0, 0,
       8, 229, 4, 0, 0, 1, 57, 0, 0 >>

ImbalanceMessageCapture ==
    << 89, 0, 13, 1, 169, 66, 7, 0, 104, 184, 228, 100, 128, 172, 27, 48,
       73, 0, 105, 0, 103, 184, 228, 100, 0, 137, 19, 11, 105, 35, 1, 0,
       93, 0, 0, 0, 220, 119, 125, 1, 0, 0, 0, 0, 40, 10, 0, 0,
       0, 0, 0, 0, 162, 3, 77, 66, 112, 237, 125, 1, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 32, 32 >>

MessageUnavailableMessageCapture ==
    << 30, 0, 21, 1, 202, 126, 11, 0, 133, 185, 228, 100, 24, 22, 162, 7,
       14, 0, 31, 0, 202, 126, 11, 0, 202, 126, 11, 0, 11, 55 >>

ModifyOrderMessageCapture ==
    << 51, 0, 13, 1, 27, 49, 7, 0, 90, 184, 228, 100, 168, 150, 230, 47,
       35, 0, 101, 0, 0, 204, 60, 32, 246, 8, 1, 0, 34, 7, 0, 0,
       38, 166, 6, 0, 0, 1, 56, 0, 16, 124, 90, 0, 245, 0, 0, 0,
       0, 66, 0 >>

NonDisplayedTradeMessageCapture ==
    << 49, 0, 13, 1, 53, 51, 7, 0, 90, 184, 228, 100, 88, 93, 40, 54,
       33, 0, 110, 0, 0, 198, 98, 34, 116, 28, 0, 0, 190, 15, 0, 0,
       107, 57, 8, 0, 96, 23, 163, 3, 1, 0, 0, 0, 1, 64, 70, 32,
       73 >>

OrderExecutionMessageCapture ==
    << 58, 0, 13, 1, 91, 218, 6, 0, 90, 184, 228, 100, 112, 58, 197, 53,
       42, 0, 103, 0, 0, 89, 116, 34, 22, 35, 0, 0, 188, 3, 0, 0,
       219, 104, 6, 0, 0, 1, 52, 0, 185, 138, 8, 0, 176, 135, 13, 6,
       1, 0, 0, 0, 1, 0, 64, 70, 32, 73 >>

ReplaceOrderMessageCapture ==
    << 58, 0, 13, 1, 193, 172, 6, 0, 90, 184, 228, 100, 232, 227, 8, 48,
       42, 0, 104, 0, 0, 159, 89, 32, 14, 26, 1, 0, 92, 1, 0, 0,
       139, 84, 10, 0, 0, 1, 54, 0, 109, 105, 10, 0, 0, 1, 54, 0,
       176, 122, 72, 0, 100, 0, 0, 0, 66, 0 >>

RetailPriceImprovementMessageCapture ==
    << 33, 0, 13, 1, 167, 225, 6, 0, 91, 184, 228, 100, 40, 135, 203, 12,
       17, 0, 114, 0, 0, 139, 77, 49, 51, 34, 1, 0, 40, 30, 0, 0,
       65 >>

SecurityStatusMessageCapture ==
    << 62, 0, 15, 1, 52, 4, 0, 0, 22, 80, 228, 100, 144, 111, 129, 6,
       46, 0, 34, 0, 42, 57, 228, 100, 0, 117, 210, 14, 220, 38, 0, 0,
       1, 0, 0, 0, 80, 126, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 126, 80, 0 >>

SequenceNumberResetMessageCapture ==
    << 30, 0, 12, 1, 1, 0, 0, 0, 51, 57, 228, 100, 48, 193, 165, 19,
       14, 0, 1, 0, 169, 56, 228, 100, 0, 142, 111, 43, 11, 52 >>

SourceTimeReferenceMessageCapture ==
    << 32, 0, 15, 1, 210, 228, 6, 0, 91, 184, 228, 100, 24, 42, 45, 19,
       16, 0, 2, 0, 52, 0, 0, 0, 0, 0, 0, 0, 90, 184, 228, 100 >>

SymbolClearMessageCapture ==
    << 36, 0, 15, 1, 3, 0, 0, 0, 20, 80, 228, 100, 208, 114, 120, 43,
       20, 0, 32, 0, 41, 57, 228, 100, 0, 100, 58, 29, 83, 39, 0, 0,
       1, 0, 0, 0 >>

SymbolIndexMappingMessageCapture ==
    << 60, 0, 15, 1, 2, 0, 0, 0, 20, 80, 228, 100, 208, 114, 120, 43,
       44, 0, 3, 0, 83, 39, 0, 0, 87, 87, 87, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 1, 0, 55, 78, 6, 67, 100, 0, 144, 226, 125, 0,
       0, 0, 0, 0, 0, 78, 100, 0, 1, 0, 0, 0 >>

Captures == { AddOrderMessageCapture, CrossTradeMessageCapture, DeleteOrderMessageCapture, ImbalanceMessageCapture, MessageUnavailableMessageCapture, ModifyOrderMessageCapture, NonDisplayedTradeMessageCapture, OrderExecutionMessageCapture, ReplaceOrderMessageCapture, RetailPriceImprovementMessageCapture, SecurityStatusMessageCapture, SequenceNumberResetMessageCapture, SourceTimeReferenceMessageCapture, SymbolClearMessageCapture, SymbolIndexMappingMessageCapture }

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
