-------------- MODULE B3Derivatives_BinaryUmdf_v1_8_Captures ---------------
(***************************************************************************)
(* Recorded Brasil, Bolsa, Balcão Binary Unified Market Data Feed v1.8     *)
(* packets, as the bytes they were captured as. Each one decodes, consumes *)
(* the whole packet, and encodes back to exactly the bytes it was read     *)
(* from.                                                                   *)
(***************************************************************************)
EXTENDS B3Derivatives_BinaryUmdf_v1_8

SecurityDefinitionMessageCapture ==
    << 50, 0, 223, 21, 6, 0, 0, 0, 45, 183, 229, 244, 230, 155, 243, 23,
       42, 1, 80, 235, 230, 0, 12, 0, 2, 0, 9, 0, 239, 133, 243, 144,
       46, 0, 0, 0, 66, 86, 77, 70, 56, 49, 57, 0, 65, 72, 69, 66,
       51, 70, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       77, 3, 235, 3, 1, 0, 0, 0, 64, 66, 15, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 128, 0, 225, 245, 5, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 128, 255, 180, 134, 165, 0, 0, 0, 0,
       69, 75, 128, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       1, 0, 0, 0, 0, 0, 0, 0, 99, 0, 0, 0, 0, 0, 0, 0,
       1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       106, 0, 0, 0, 134, 71, 0, 0, 160, 192, 44, 0, 66, 82, 0, 0,
       0, 0, 0, 0, 0, 0, 2, 0, 160, 192, 44, 0, 0, 0, 0, 0,
       66, 82, 65, 72, 69, 66, 65, 67, 78, 79, 82, 48, 65, 72, 69, 66,
       0, 0, 69, 83, 86, 85, 70, 82, 15, 39, 12, 0, 0, 15, 39, 12,
       0, 0, 66, 82, 76, 0, 0, 0, 66, 82, 76, 0, 0, 0, 1, 2,
       5, 255, 255, 0, 50, 0, 255, 0, 255, 255, 0, 0, 0, 0, 0, 0,
       0, 128, 28, 0, 1, 66, 133, 243, 144, 46, 0, 0, 0, 65, 72, 69,
       66, 51, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 38, 0, 0, 2, 0, 2, 34, 1, 24, 1, 14, 83, 80, 84, 85,
       82, 73, 83, 32, 32, 32, 32, 32, 79, 78 >>

SequenceMessageCapture ==
    << 50, 1, 223, 21, 0, 0, 0, 0, 13, 183, 146, 97, 151, 156, 243, 23,
       16, 0, 80, 235, 4, 0, 2, 0, 2, 0, 9, 0, 68, 45, 1, 0 >>

Captures == { SecurityDefinitionMessageCapture, SequenceMessageCapture }

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
