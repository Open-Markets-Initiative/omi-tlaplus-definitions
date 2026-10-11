----------- MODULE TexasEquities_IntegratedFeed_v2_5_g_Captures ------------
(***************************************************************************)
(* Recorded New York Stock Exchange Integrated Feed v2.5.g packets, as the *)
(* bytes they were captured as. Each one decodes, consumes the whole       *)
(* packet, and encodes back to exactly the bytes it was read from.         *)
(***************************************************************************)
EXTENDS TexasEquities_IntegratedFeed_v2_5_g

AddOrderMessageCapture ==
    << 55, 0, 11, 1, 234, 100, 1, 0, 87, 184, 228, 100, 0, 53, 150, 59,
       39, 0, 100, 0, 0, 15, 150, 59, 51, 24, 0, 0, 111, 48, 0, 0,
       166, 105, 1, 0, 0, 11, 53, 0, 64, 92, 213, 1, 244, 1, 0, 0,
       83, 32, 32, 32, 32, 32, 0 >>

DeleteOrderMessageCapture ==
    << 41, 0, 11, 1, 254, 100, 1, 0, 88, 184, 228, 100, 0, 235, 17, 0,
       25, 0, 102, 0, 0, 187, 17, 0, 83, 65, 0, 0, 249, 0, 0, 0,
       205, 51, 0, 0, 0, 11, 53, 0, 0 >>

ModifyOrderMessageCapture ==
    << 51, 0, 11, 1, 231, 169, 2, 0, 88, 184, 228, 100, 0, 108, 55, 9,
       35, 0, 101, 0, 0, 72, 55, 9, 137, 95, 0, 0, 40, 0, 0, 0,
       4, 12, 1, 0, 0, 11, 51, 0, 0, 144, 95, 1, 96, 9, 0, 0,
       0, 83, 0 >>

NonDisplayedTradeMessageCapture ==
    << 49, 0, 11, 1, 38, 241, 0, 0, 89, 184, 228, 100, 0, 19, 199, 0,
       33, 0, 110, 0, 0, 216, 198, 0, 251, 11, 0, 0, 15, 0, 0, 0,
       52, 0, 0, 0, 132, 183, 214, 1, 1, 0, 0, 0, 1, 64, 32, 32,
       73 >>

OrderExecutionMessageCapture ==
    << 58, 0, 11, 1, 247, 169, 2, 0, 88, 184, 228, 100, 0, 134, 133, 9,
       42, 0, 103, 0, 0, 37, 133, 9, 11, 24, 0, 0, 10, 0, 0, 0,
       252, 155, 0, 0, 0, 11, 51, 0, 7, 0, 0, 0, 64, 93, 168, 5,
       44, 1, 0, 0, 1, 0, 64, 32, 32, 32 >>

ReplaceOrderMessageCapture ==
    << 58, 0, 11, 1, 49, 101, 1, 0, 88, 184, 228, 100, 0, 250, 40, 0,
       42, 0, 104, 0, 0, 33, 40, 0, 199, 3, 1, 0, 22, 0, 0, 0,
       253, 97, 0, 0, 0, 11, 53, 0, 128, 99, 0, 0, 0, 11, 53, 0,
       96, 224, 67, 3, 220, 5, 0, 0, 83, 0 >>

SecurityStatusMessageCapture ==
    << 62, 0, 11, 1, 162, 164, 1, 0, 88, 184, 228, 100, 0, 148, 146, 0,
       46, 0, 34, 0, 88, 184, 228, 100, 0, 60, 146, 0, 30, 39, 0, 0,
       6, 0, 0, 0, 79, 126, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 126, 79, 0 >>

SourceTimeReferenceMessageCapture ==
    << 57, 0, 11, 2, 42, 164, 1, 0, 88, 184, 228, 100, 0, 136, 4, 0,
       16, 0, 2, 0, 52, 0, 0, 0, 0, 0, 0, 0, 88, 184, 228, 100,
       25, 0, 102, 0, 0, 95, 4, 0, 94, 114, 0, 0, 24, 9, 0, 0,
       160, 139, 0, 0, 0, 11, 52, 0, 0 >>

Captures == { AddOrderMessageCapture, DeleteOrderMessageCapture, ModifyOrderMessageCapture, NonDisplayedTradeMessageCapture, OrderExecutionMessageCapture, ReplaceOrderMessageCapture, SecurityStatusMessageCapture, SourceTimeReferenceMessageCapture }

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
