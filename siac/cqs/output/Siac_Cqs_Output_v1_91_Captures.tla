------------------ MODULE Siac_Cqs_Output_v1_91_Captures -------------------
(***************************************************************************)
(* Recorded The Securities Industry Automation Corporation Output v1.91    *)
(* packets, as the bytes they were captured as. Each one decodes, consumes *)
(* the whole packet, and encodes back to exactly the bytes it was read     *)
(* from.                                                                   *)
(***************************************************************************)
EXTENDS Siac_Cqs_Output_v1_91

LongQuoteMessageCapture ==
    << 0, 0, 144, 81, 79, 1, 47, 81, 21, 1, 91, 209, 222, 0, 31, 101,
       56, 23, 26, 130, 0, 123, 81, 76, 75, 91, 209, 222, 0, 31, 94, 124,
       176, 1, 7, 77, 179, 112, 0, 0, 48, 48, 85, 105, 85, 104, 83, 84,
       79, 82, 32, 32, 32, 32, 32, 32, 32, 48, 82, 32, 0, 0, 0, 0,
       1, 193, 95, 16, 0, 0, 0, 1, 0, 0, 0, 0, 1, 193, 173, 48,
       0, 0, 0, 1, 32, 32, 32, 32, 32, 32, 32, 32, 0, 0, 0, 0,
       0, 0, 0, 1, 32, 78, 48, 32, 32, 65, 85, 90, 82, 0, 0, 0,
       0, 1, 193, 134, 32, 0, 0, 0, 3, 32, 32, 32, 32, 90, 82, 0,
       0, 0, 0, 1, 193, 173, 48, 0, 0, 0, 2, 32, 32, 32, 32, 0 >>

Captures == { LongQuoteMessageCapture }

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
