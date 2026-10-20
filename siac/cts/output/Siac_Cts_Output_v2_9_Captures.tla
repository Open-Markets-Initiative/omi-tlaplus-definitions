------------------- MODULE Siac_Cts_Output_v2_9_Captures -------------------
(***************************************************************************)
(* Recorded The Securities Industry Automation Corporation Output v2.9     *)
(* packets, as the bytes they were captured as. Each one decodes, consumes *)
(* the whole packet, and encodes back to exactly the bytes it was read     *)
(* from.                                                                   *)
(***************************************************************************)
EXTENDS Siac_Cts_Output_v2_9

LineIntegrityMessageCapture ==
    << 2, 0, 46, 84, 79, 0, 42, 49, 147, 1, 103, 151, 236, 247, 20, 128,
       106, 0, 10, 129, 0, 26, 67, 84, 83, 103, 151, 236, 247, 20, 128, 102,
       0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 >>

LongTradeMessageCapture ==
    << 2, 0, 92, 84, 79, 0, 42, 48, 64, 1, 103, 151, 236, 244, 13, 213,
       109, 0, 19, 170, 0, 72, 84, 76, 78, 103, 151, 236, 244, 13, 213, 0,
       227, 1, 15, 1, 6, 93, 0, 0, 48, 48, 50, 49, 73, 84, 71, 77,
       69, 32, 32, 32, 32, 32, 32, 32, 32, 48, 32, 32, 32, 32, 0, 0,
       0, 0, 1, 157, 131, 96, 0, 0, 0, 100, 0, 48, 48, 32, 0, 0,
       0, 0, 0, 0, 0, 0, 32, 78, 48, 32, 68, 68 >>

TradingStatusMessageCapture ==
    << 2, 0, 96, 84, 79, 0, 42, 157, 173, 1, 103, 151, 237, 154, 0, 89,
       255, 0, 16, 161, 0, 76, 84, 83, 83, 103, 151, 237, 154, 0, 89, 230,
       0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 89,
       66, 88, 32, 32, 32, 32, 32, 32, 32, 48, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 2, 4, 52, 112, 0, 0, 0, 0, 1, 166,
       93, 0, 0, 0, 0, 0, 0, 0, 0, 0, 70, 32, 32, 78, 48, 66 >>

Captures == { LineIntegrityMessageCapture, LongTradeMessageCapture, TradingStatusMessageCapture }

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
