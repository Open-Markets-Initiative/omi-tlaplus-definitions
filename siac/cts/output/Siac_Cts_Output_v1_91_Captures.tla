------------------ MODULE Siac_Cts_Output_v1_91_Captures -------------------
(***************************************************************************)
(* Recorded The Securities Industry Automation Corporation Output v1.91    *)
(* packets, as the bytes they were captured as. Each one decodes, consumes *)
(* the whole packet, and encodes back to exactly the bytes it was read     *)
(* from.                                                                   *)
(***************************************************************************)
EXTENDS Siac_Cts_Output_v1_91

IndexMessageCapture ==
    << 0, 0, 66, 84, 79, 0, 4, 20, 183, 1, 89, 178, 237, 230, 3, 247,
       62, 88, 13, 182, 0, 45, 73, 73, 90, 0, 0, 0, 0, 0, 0, 0,
       0, 1, 4, 1, 33, 169, 0, 0, 48, 48, 50, 88, 118, 101, 78, 69,
       65, 82, 46, 73, 86, 32, 32, 32, 32, 0, 0, 0, 0, 2, 254, 102,
       12, 0 >>

LineIntegrityMessageCapture ==
    << 0, 0, 46, 84, 79, 0, 4, 22, 215, 1, 89, 178, 238, 22, 0, 0,
       156, 64, 5, 179, 0, 26, 67, 84, 83, 0, 0, 0, 0, 0, 0, 0,
       0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 >>

LongTradeMessageCapture ==
    << 0, 0, 92, 84, 79, 0, 14, 191, 220, 1, 89, 178, 242, 116, 54, 143,
       61, 72, 23, 242, 0, 72, 84, 76, 78, 89, 178, 242, 116, 54, 137, 66,
       8, 1, 22, 1, 217, 208, 0, 0, 48, 70, 83, 75, 75, 68, 65, 76,
       76, 69, 32, 32, 32, 32, 32, 32, 32, 48, 32, 70, 32, 73, 0, 0,
       0, 0, 4, 209, 16, 16, 0, 0, 0, 17, 0, 48, 49, 32, 89, 178,
       242, 116, 42, 70, 189, 24, 32, 78, 48, 32, 65, 65 >>

ShortTradeMessageCapture ==
    << 0, 0, 60, 84, 79, 0, 14, 191, 224, 1, 89, 178, 242, 116, 57, 134,
       30, 184, 17, 148, 0, 40, 84, 84, 84, 89, 178, 242, 116, 57, 124, 71,
       48, 1, 1, 9, 182, 110, 0, 0, 57, 48, 68, 64, 67, 86, 65, 77,
       80, 32, 32, 73, 52, 51, 217, 0, 20, 78, 65, 65 >>

TradingStatusMessageCapture ==
    << 0, 0, 96, 84, 79, 0, 15, 65, 245, 1, 89, 178, 243, 210, 1, 227,
       184, 8, 14, 108, 0, 76, 84, 83, 83, 0, 0, 0, 0, 0, 0, 0,
       0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 65, 78,
       87, 32, 32, 32, 32, 32, 32, 32, 32, 48, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 88, 128, 64, 0, 0, 0, 0, 0, 57,
       251, 192, 0, 0, 0, 0, 0, 0, 0, 0, 70, 32, 32, 78, 48, 66 >>

Captures == { IndexMessageCapture, LineIntegrityMessageCapture, LongTradeMessageCapture, ShortTradeMessageCapture, TradingStatusMessageCapture }

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
