---------------- MODULE C1Options_Complex_v2_1_18_Captures -----------------
(***************************************************************************)
(* Recorded Chicago Board Options Exchange Complex v2.1.18 packets, as the *)
(* bytes they were captured as. Each one decodes, consumes the whole       *)
(* packet, and encodes back to exactly the bytes it was read from.         *)
(***************************************************************************)
EXTENDS C1Options_Complex_v2_1_18

AuctionCancelMessageCapture ==
    << 48, 0, 2, 33, 175, 50, 152, 0, 14, 174, 144, 224, 200, 57, 116, 22,
       177, 208, 46, 213, 152, 60, 26, 34, 144, 224, 200, 57, 115, 22, 177, 208,
       46, 213, 152, 60, 66, 1, 0, 84, 48, 50, 75, 72, 97, 68, 2, 1 >>

AuctionNotificationMessageCapture ==
    << 55, 0, 1, 33, 145, 218, 152, 0, 47, 173, 8, 206, 48, 58, 84, 48,
       50, 75, 69, 67, 242, 234, 29, 209, 46, 213, 152, 60, 67, 66, 0, 0,
       0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 78, 32, 32, 32, 32, 8,
       152, 203, 117, 32, 32, 32, 32 >>

AuctionUpdateMessageCapture ==
    << 72, 0, 1, 33, 193, 231, 6, 0, 64, 209, 104, 93, 241, 32, 84, 48,
       50, 54, 113, 76, 32, 32, 71, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0 >>

ComplexInstrumentDefinitionExpandedMessageCapture ==
    << 59, 0, 1, 33, 0, 0, 0, 0, 51, 154, 0, 0, 0, 0, 84, 48,
       49, 117, 86, 106, 83, 80, 88, 32, 32, 32, 32, 32, 79, 32, 32, 32,
       2, 48, 50, 49, 70, 88, 122, 32, 32, 1, 0, 0, 0, 79, 48, 50,
       49, 70, 88, 118, 32, 32, 255, 255, 255, 255, 79 >>

DeleteOrderMessageCapture ==
    << 22, 0, 1, 33, 10, 25, 153, 0, 14, 41, 208, 247, 202, 43, 220, 139,
       126, 209, 46, 213, 152, 60 >>

HeartbeatCapture ==
    << 8, 0, 0, 1, 1, 0, 0, 0 >>

ModifyOrderShortMessageCapture ==
    << 27, 0, 1, 33, 228, 253, 152, 0, 19, 40, 184, 242, 119, 5, 129, 115,
       149, 211, 46, 157, 152, 60, 11, 0, 207, 169, 1 >>

OrderExecutedMessageCapture ==
    << 35, 0, 1, 33, 236, 52, 152, 0, 27, 35, 128, 58, 178, 26, 203, 182,
       173, 208, 46, 213, 152, 60, 1, 0, 0, 0, 220, 206, 20, 232, 90, 2,
       0, 0, 102 >>

SymbolMappingMessageCapture ==
    << 46, 0, 1, 33, 0, 0, 0, 0, 38, 46, 48, 50, 55, 119, 117, 69,
       83, 80, 88, 32, 32, 32, 50, 48, 48, 54, 49, 57, 80, 48, 48, 53,
       48, 48, 48, 48, 48, 78, 83, 80, 88, 32, 32, 32, 32, 32 >>

TimeMessageCapture ==
    << 28, 0, 2, 33, 38, 70, 142, 0, 6, 32, 177, 132, 0, 0, 14, 41,
       40, 110, 150, 25, 199, 82, 189, 207, 46, 213, 152, 60 >>

Captures == { AuctionCancelMessageCapture, AuctionNotificationMessageCapture, AuctionUpdateMessageCapture, ComplexInstrumentDefinitionExpandedMessageCapture, DeleteOrderMessageCapture, HeartbeatCapture, ModifyOrderShortMessageCapture, OrderExecutedMessageCapture, SymbolMappingMessageCapture, TimeMessageCapture }

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
