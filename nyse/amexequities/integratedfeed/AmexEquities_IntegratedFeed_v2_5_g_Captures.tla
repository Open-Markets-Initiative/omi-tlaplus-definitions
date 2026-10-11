------------ MODULE AmexEquities_IntegratedFeed_v2_5_g_Captures ------------
(***************************************************************************)
(* Recorded New York Stock Exchange Integrated Feed v2.5.g packets, as the *)
(* bytes they were captured as. Each one decodes, consumes the whole       *)
(* packet, and encodes back to exactly the bytes it was read from.         *)
(***************************************************************************)
EXTENDS AmexEquities_IntegratedFeed_v2_5_g

AddOrderMessageCapture ==
    << 55, 0, 11, 1, 131, 207, 0, 0, 87, 184, 228, 100, 203, 18, 153, 59,
       39, 0, 100, 0, 161, 241, 152, 59, 226, 3, 0, 0, 21, 0, 0, 0,
       42, 48, 1, 0, 0, 9, 56, 0, 176, 104, 176, 4, 32, 3, 0, 0,
       66, 32, 32, 32, 32, 32, 0 >>

CrossTradeMessageCapture ==
    << 78, 0, 11, 2, 48, 83, 2, 0, 88, 184, 228, 100, 249, 35, 152, 1,
       29, 0, 111, 0, 252, 195, 150, 1, 56, 61, 0, 0, 28, 0, 0, 0,
       107, 152, 0, 0, 192, 168, 50, 0, 1, 0, 0, 0, 79, 33, 0, 110,
       0, 252, 195, 150, 1, 56, 61, 0, 0, 29, 0, 0, 0, 95, 2, 0,
       0, 192, 168, 50, 0, 1, 0, 0, 0, 0, 64, 79, 32, 73 >>

DeleteOrderMessageCapture ==
    << 41, 0, 11, 1, 149, 81, 2, 0, 88, 184, 228, 100, 86, 167, 3, 0,
       25, 0, 102, 0, 123, 128, 3, 0, 215, 253, 0, 0, 20, 0, 0, 0,
       204, 172, 2, 0, 0, 9, 52, 0, 0 >>

ModifyOrderMessageCapture ==
    << 51, 0, 11, 1, 61, 208, 0, 0, 88, 184, 228, 100, 64, 141, 178, 0,
       35, 0, 101, 0, 212, 43, 178, 0, 139, 25, 1, 0, 0, 3, 0, 0,
       66, 122, 1, 0, 0, 9, 56, 0, 16, 20, 149, 0, 12, 23, 0, 0,
       0, 83, 0 >>

NonDisplayedTradeMessageCapture ==
    << 49, 0, 11, 1, 237, 210, 1, 0, 88, 184, 228, 100, 207, 25, 35, 0,
       33, 0, 110, 0, 184, 83, 34, 0, 90, 59, 0, 0, 50, 0, 0, 0,
       218, 10, 0, 0, 72, 77, 6, 0, 152, 0, 0, 0, 0, 64, 79, 32,
       32 >>

OrderExecutionMessageCapture ==
    << 58, 0, 11, 1, 159, 151, 1, 0, 88, 184, 228, 100, 8, 70, 10, 2,
       42, 0, 103, 0, 113, 202, 9, 2, 226, 67, 0, 0, 71, 2, 0, 0,
       85, 56, 2, 0, 0, 9, 53, 0, 150, 20, 0, 0, 84, 44, 7, 0,
       30, 1, 0, 0, 1, 0, 64, 32, 32, 32 >>

ReplaceOrderMessageCapture ==
    << 58, 0, 11, 1, 91, 142, 1, 0, 88, 184, 228, 100, 221, 89, 12, 0,
       42, 0, 104, 0, 100, 43, 12, 0, 242, 27, 0, 0, 14, 0, 0, 0,
       173, 35, 2, 0, 0, 9, 53, 0, 227, 35, 2, 0, 0, 9, 53, 0,
       176, 195, 146, 3, 100, 0, 0, 0, 66, 0 >>

SecurityStatusMessageCapture ==
    << 62, 0, 11, 1, 97, 211, 1, 0, 88, 184, 228, 100, 14, 177, 154, 0,
       46, 0, 34, 0, 88, 184, 228, 100, 254, 91, 154, 0, 29, 39, 0, 0,
       13, 0, 0, 0, 79, 126, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 126, 79, 0 >>

SourceTimeReferenceMessageCapture ==
    << 57, 0, 11, 2, 146, 81, 2, 0, 88, 184, 228, 100, 15, 35, 2, 0,
       16, 0, 2, 0, 52, 0, 0, 0, 0, 0, 0, 0, 88, 184, 228, 100,
       25, 0, 102, 0, 171, 236, 1, 0, 248, 121, 0, 0, 10, 0, 0, 0,
       236, 136, 2, 0, 0, 9, 52, 0, 0 >>

Captures == { AddOrderMessageCapture, CrossTradeMessageCapture, DeleteOrderMessageCapture, ModifyOrderMessageCapture, NonDisplayedTradeMessageCapture, OrderExecutionMessageCapture, ReplaceOrderMessageCapture, SecurityStatusMessageCapture, SourceTimeReferenceMessageCapture }

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
