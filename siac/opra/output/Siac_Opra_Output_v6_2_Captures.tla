------------------ MODULE Siac_Opra_Output_v6_2_Captures -------------------
(***************************************************************************)
(* Recorded The Securities Industry Automation Corporation Output v6.2     *)
(* packets, as the bytes they were captured as. Each one decodes, consumes *)
(* the whole packet, and encodes back to exactly the bytes it was read     *)
(* from.                                                                   *)
(***************************************************************************)
EXTENDS Siac_Opra_Output_v6_2

AdministrativeMessageCapture ==
    << 6, 0, 118, 79, 32, 0, 24, 50, 206, 102, 1, 101, 103, 173, 88, 0,
       21, 189, 0, 25, 108, 67, 67, 32, 32, 28, 0, 138, 125, 0, 0, 0,
       0, 0, 83, 84, 69, 88, 84, 32, 67, 70, 76, 69, 88, 32, 81, 81,
       81, 32, 76, 83, 84, 32, 51, 46, 50, 49, 67, 32, 80, 77, 32, 69,
       85, 82, 32, 48, 51, 47, 50, 56, 47, 50, 48, 50, 52, 32, 49, 32,
       64, 32, 51, 56, 53, 46, 53, 53, 32, 50, 81, 81, 81, 32, 65, 68,
       74, 32, 49, 46, 48, 48, 48, 48, 32, 51, 57, 48, 46, 50, 48, 32,
       51, 56, 57, 46, 56, 49 >>

ControlMessageCapture ==
    << 6, 0, 34, 79, 32, 0, 23, 255, 134, 108, 1, 101, 103, 165, 147, 55,
       247, 152, 0, 7, 111, 79, 72, 78, 32, 0, 0, 0, 0, 0, 0, 0,
       0, 0 >>

LongEquityAndIndexQuoteMessageCapture ==
    << 6, 0, 74, 79, 32, 0, 23, 254, 170, 121, 1, 101, 103, 165, 140, 56,
       231, 71, 0, 15, 194, 68, 107, 32, 77, 13, 38, 65, 167, 0, 0, 0,
       0, 65, 77, 90, 78, 32, 0, 65, 19, 24, 66, 0, 0, 64, 141, 66,
       0, 0, 0, 61, 0, 0, 0, 239, 0, 0, 0, 63, 0, 0, 1, 239,
       80, 66, 0, 0, 0, 61, 0, 0, 0, 243 >>

ShortEquityAndIndexQuoteMessageCapture ==
    << 6, 0, 60, 79, 32, 0, 23, 254, 164, 98, 1, 101, 103, 165, 140, 47,
       171, 3, 0, 15, 141, 84, 113, 32, 77, 4, 28, 218, 247, 47, 165, 174,
       153, 65, 77, 90, 78, 76, 29, 23, 5, 50, 5, 130, 0, 43, 5, 185,
       0, 2, 78, 66, 0, 0, 5, 130, 0, 0, 0, 50 >>

Captures == { AdministrativeMessageCapture, ControlMessageCapture, LongEquityAndIndexQuoteMessageCapture, ShortEquityAndIndexQuoteMessageCapture }

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
