------------------ MODULE Siac_Cts_Output_v2_10_Captures -------------------
(***************************************************************************)
(* Recorded The Securities Industry Automation Corporation Output v2.10    *)
(* packets, as the bytes they were captured as. Each one decodes, consumes *)
(* the whole packet, and encodes back to exactly the bytes it was read     *)
(* from.                                                                   *)
(***************************************************************************)
EXTENDS Siac_Cts_Output_v2_10

TradeCorrectionMessageCapture ==
    << 2, 0, 192, 84, 79, 0, 51, 81, 37, 1, 103, 151, 250, 10, 29, 212,
       142, 0, 41, 25, 0, 172, 84, 67, 68, 103, 151, 241, 51, 36, 122, 97,
       0, 1, 105, 16, 21, 22, 0, 0, 72, 48, 77, 76, 57, 50, 72, 76,
       32, 32, 32, 32, 32, 32, 32, 32, 32, 48, 32, 55, 90, 86, 0, 0,
       0, 0, 0, 85, 8, 92, 0, 0, 128, 232, 0, 48, 49, 32, 78, 103,
       151, 250, 10, 29, 211, 227, 100, 0, 0, 72, 48, 75, 82, 55, 78, 32,
       55, 32, 86, 0, 0, 0, 0, 0, 85, 8, 92, 0, 0, 128, 232, 0,
       48, 49, 32, 78, 48, 0, 0, 0, 0, 78, 0, 0, 0, 0, 0, 81,
       84, 80, 0, 0, 0, 0, 0, 82, 121, 72, 0, 0, 0, 0, 0, 79,
       166, 160, 1, 37, 60, 215, 52, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       81, 103, 216, 0, 0, 0, 0, 0, 82, 121, 72, 0, 0, 0, 0, 0,
       79, 166, 160, 0, 0, 0, 0, 0, 81, 209, 80, 0, 187, 58, 250, 52 >>

Captures == { TradeCorrectionMessageCapture }

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
