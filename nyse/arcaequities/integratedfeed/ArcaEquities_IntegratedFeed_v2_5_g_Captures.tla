------------ MODULE ArcaEquities_IntegratedFeed_v2_5_g_Captures ------------
(***************************************************************************)
(* Recorded New York Stock Exchange Integrated Feed v2.5.g packets, as the *)
(* bytes they were captured as. Each one decodes, consumes the whole       *)
(* packet, and encodes back to exactly the bytes it was read from.         *)
(***************************************************************************)
EXTENDS ArcaEquities_IntegratedFeed_v2_5_g

AddOrderMessageCapture ==
    << 55, 0, 11, 1, 135, 252, 16, 0, 87, 184, 228, 100, 0, 179, 151, 59,
       39, 0, 100, 0, 0, 150, 151, 59, 143, 39, 0, 0, 108, 41, 0, 0,
       159, 226, 29, 0, 0, 3, 53, 0, 96, 126, 6, 2, 32, 3, 0, 0,
       83, 32, 32, 32, 32, 32, 0 >>

CrossTradeMessageCapture ==
    << 78, 0, 11, 2, 216, 94, 12, 0, 88, 184, 228, 100, 0, 123, 103, 1,
       29, 0, 111, 0, 0, 25, 103, 1, 225, 73, 0, 0, 47, 4, 0, 0,
       168, 77, 0, 0, 16, 13, 28, 3, 1, 0, 0, 0, 79, 33, 0, 110,
       0, 0, 25, 103, 1, 225, 73, 0, 0, 48, 4, 0, 0, 243, 227, 0,
       0, 16, 13, 28, 3, 1, 0, 0, 0, 0, 64, 79, 32, 73 >>

DeleteOrderMessageCapture ==
    << 41, 0, 11, 1, 3, 35, 17, 0, 87, 184, 228, 100, 0, 202, 151, 59,
       25, 0, 102, 0, 0, 166, 151, 59, 248, 121, 0, 0, 183, 9, 0, 0,
       73, 186, 28, 0, 0, 3, 52, 0, 0 >>

ModifyOrderMessageCapture ==
    << 51, 0, 11, 1, 138, 87, 18, 0, 88, 184, 228, 100, 0, 144, 16, 0,
       35, 0, 101, 0, 0, 96, 16, 0, 148, 121, 0, 0, 168, 107, 0, 0,
       60, 83, 21, 0, 0, 3, 51, 0, 208, 255, 167, 0, 240, 35, 0, 0,
       0, 66, 0 >>

NonDisplayedTradeMessageCapture ==
    << 49, 0, 11, 1, 143, 95, 8, 0, 88, 184, 228, 100, 0, 155, 15, 0,
       33, 0, 110, 0, 0, 98, 15, 0, 219, 3, 0, 0, 202, 26, 0, 0,
       89, 105, 4, 0, 192, 142, 78, 3, 27, 0, 0, 0, 1, 64, 32, 84,
       73 >>

OrderExecutionMessageCapture ==
    << 58, 0, 11, 1, 117, 68, 15, 0, 87, 184, 228, 100, 0, 196, 154, 59,
       42, 0, 103, 0, 0, 148, 154, 59, 146, 39, 0, 0, 14, 168, 1, 0,
       62, 40, 21, 0, 0, 3, 57, 0, 68, 25, 2, 0, 0, 85, 30, 10,
       25, 0, 0, 0, 1, 0, 64, 70, 84, 73 >>

ReplaceOrderMessageCapture ==
    << 58, 0, 11, 1, 61, 110, 11, 0, 87, 184, 228, 100, 0, 220, 151, 59,
       42, 0, 104, 0, 0, 186, 151, 59, 86, 231, 0, 0, 82, 0, 0, 0,
       87, 98, 27, 0, 0, 3, 62, 0, 201, 146, 27, 0, 0, 3, 62, 0,
       192, 248, 245, 0, 100, 0, 0, 0, 66, 0 >>

RetailPriceImprovementMessageCapture ==
    << 33, 0, 11, 1, 183, 186, 13, 0, 88, 184, 228, 100, 0, 157, 151, 0,
       17, 0, 114, 0, 0, 190, 150, 0, 27, 110, 0, 0, 168, 0, 0, 0,
       67 >>

SecurityStatusMessageCapture ==
    << 62, 0, 11, 1, 162, 90, 12, 0, 88, 184, 228, 100, 0, 18, 115, 0,
       46, 0, 34, 0, 88, 184, 228, 100, 0, 17, 114, 0, 165, 63, 0, 0,
       113, 0, 0, 0, 79, 126, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 126, 79, 0 >>

SourceTimeReferenceMessageCapture ==
    << 71, 0, 11, 2, 35, 95, 17, 0, 88, 184, 228, 100, 0, 43, 0, 0,
       16, 0, 2, 0, 58, 0, 0, 0, 0, 0, 0, 0, 88, 184, 228, 100,
       39, 0, 100, 0, 0, 4, 0, 0, 32, 152, 0, 0, 135, 19, 0, 0,
       58, 139, 31, 0, 0, 3, 58, 0, 0, 12, 99, 4, 44, 1, 0, 0,
       66, 32, 32, 32, 32, 32, 0 >>

Captures == { AddOrderMessageCapture, CrossTradeMessageCapture, DeleteOrderMessageCapture, ModifyOrderMessageCapture, NonDisplayedTradeMessageCapture, OrderExecutionMessageCapture, ReplaceOrderMessageCapture, RetailPriceImprovementMessageCapture, SecurityStatusMessageCapture, SourceTimeReferenceMessageCapture }

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
