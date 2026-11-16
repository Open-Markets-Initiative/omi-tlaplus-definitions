---------- MODULE NationalEquities_IntegratedFeed_v2_5_g_Captures ----------
(***************************************************************************)
(* Recorded New York Stock Exchange Integrated Feed v2.5.g packets, as the *)
(* bytes they were captured as. Each one decodes, consumes the whole       *)
(* packet, and encodes back to exactly the bytes it was read from.         *)
(***************************************************************************)
EXTENDS NationalEquities_IntegratedFeed_v2_5_g

AddOrderMessageCapture ==
    << 55, 0, 11, 1, 136, 207, 0, 0, 148, 132, 22, 98, 0, 8, 120, 35,
       39, 0, 100, 0, 0, 195, 119, 35, 124, 23, 1, 0, 12, 0, 0, 0,
       194, 229, 0, 0, 0, 1, 1, 0, 96, 72, 152, 0, 144, 1, 0, 0,
       83, 32, 32, 32, 32, 32, 0 >>

CrossTradeMessageCapture ==
    << 78, 0, 11, 2, 47, 209, 0, 0, 74, 133, 22, 98, 0, 62, 101, 56,
       29, 0, 111, 0, 0, 115, 100, 56, 125, 31, 0, 0, 11, 0, 0, 0,
       206, 184, 1, 0, 112, 111, 152, 0, 100, 0, 0, 0, 54, 33, 0, 110,
       0, 0, 115, 100, 56, 125, 31, 0, 0, 12, 0, 0, 0, 60, 6, 1,
       0, 112, 111, 152, 0, 100, 0, 0, 0, 0, 64, 54, 32, 32 >>

DeleteOrderMessageCapture ==
    << 41, 0, 11, 1, 158, 207, 0, 0, 154, 132, 22, 98, 0, 65, 246, 58,
       25, 0, 102, 0, 0, 236, 245, 58, 229, 190, 0, 0, 17, 0, 0, 0,
       170, 166, 0, 0, 0, 1, 1, 0, 0 >>

ImbalanceMessageCapture ==
    << 89, 0, 11, 1, 123, 207, 0, 0, 137, 132, 22, 98, 0, 104, 59, 12,
       73, 0, 105, 0, 137, 132, 22, 98, 0, 2, 59, 12, 203, 230, 0, 0,
       11, 0, 0, 0, 128, 150, 152, 0, 244, 1, 0, 0, 244, 1, 0, 0,
       0, 0, 0, 0, 131, 5, 67, 66, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 1, 0, 244, 1, 0, 0, 66, 32 >>

ModifyOrderMessageCapture ==
    << 51, 0, 11, 1, 178, 209, 0, 0, 138, 133, 22, 98, 0, 112, 206, 41,
       35, 0, 101, 0, 0, 217, 205, 41, 164, 67, 0, 0, 7, 0, 0, 0,
       65, 172, 0, 0, 0, 1, 1, 0, 112, 28, 145, 0, 176, 4, 0, 0,
       0, 0, 0 >>

NonDisplayedTradeMessageCapture ==
    << 78, 0, 11, 2, 47, 209, 0, 0, 74, 133, 22, 98, 0, 62, 101, 56,
       29, 0, 111, 0, 0, 115, 100, 56, 125, 31, 0, 0, 11, 0, 0, 0,
       206, 184, 1, 0, 112, 111, 152, 0, 100, 0, 0, 0, 54, 33, 0, 110,
       0, 0, 115, 100, 56, 125, 31, 0, 0, 12, 0, 0, 0, 60, 6, 1,
       0, 112, 111, 152, 0, 100, 0, 0, 0, 0, 64, 54, 32, 32 >>

OrderExecutionMessageCapture ==
    << 58, 0, 11, 1, 253, 209, 0, 0, 182, 133, 22, 98, 0, 101, 95, 11,
       42, 0, 103, 0, 0, 160, 94, 11, 186, 160, 0, 0, 10, 0, 0, 0,
       93, 174, 0, 0, 0, 1, 1, 0, 109, 9, 1, 0, 144, 189, 152, 0,
       100, 0, 0, 0, 1, 0, 64, 32, 32, 32 >>

ReplaceOrderMessageCapture ==
    << 58, 0, 11, 1, 101, 208, 0, 0, 0, 133, 22, 98, 0, 187, 204, 20,
       42, 0, 104, 0, 0, 112, 204, 20, 175, 233, 0, 0, 50, 0, 0, 0,
       136, 230, 0, 0, 0, 1, 1, 0, 226, 230, 0, 0, 0, 1, 1, 0,
       192, 241, 255, 127, 200, 0, 0, 0, 0, 0 >>

SecurityStatusMessageCapture ==
    << 62, 0, 11, 1, 130, 207, 0, 0, 145, 132, 22, 98, 0, 225, 245, 8,
       46, 0, 34, 0, 145, 132, 22, 98, 0, 229, 244, 8, 164, 36, 0, 0,
       8, 0, 0, 0, 53, 126, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 126, 80, 0 >>

SourceTimeReferenceMessageCapture ==
    << 71, 0, 11, 2, 121, 207, 0, 0, 136, 132, 22, 98, 0, 123, 133, 59,
       16, 0, 2, 0, 1, 0, 0, 0, 0, 0, 0, 0, 136, 132, 22, 98,
       39, 0, 100, 0, 0, 176, 132, 59, 203, 230, 0, 0, 10, 0, 0, 0,
       140, 229, 0, 0, 0, 1, 1, 0, 160, 228, 152, 0, 144, 1, 0, 0,
       83, 32, 32, 32, 32, 32, 0 >>

Captures == { AddOrderMessageCapture, CrossTradeMessageCapture, DeleteOrderMessageCapture, ImbalanceMessageCapture, ModifyOrderMessageCapture, NonDisplayedTradeMessageCapture, OrderExecutionMessageCapture, ReplaceOrderMessageCapture, SecurityStatusMessageCapture, SourceTimeReferenceMessageCapture }

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
