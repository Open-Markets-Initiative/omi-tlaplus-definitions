-------------- MODULE BoxOptions_SolaMulticast_v1_8_Captures ---------------
(***************************************************************************)
(* Recorded Box Options Market Sola Multicast v1.8 packets, as the bytes   *)
(* they were captured as. Each one decodes, consumes the whole packet, and *)
(* encodes back to exactly the bytes it was read from.                     *)
(***************************************************************************)
EXTENDS BoxOptions_SolaMulticast_v1_8

OptionQuoteMessageCapture ==
    << 2, 48, 57, 52, 57, 56, 57, 55, 53, 48, 70, 32, 81, 65, 68, 73,
       32, 32, 32, 84, 32, 48, 48, 49, 51, 52, 48, 48, 50, 49, 57, 50,
       51, 48, 48, 50, 50, 53, 48, 50, 48, 48, 48, 48, 51, 48, 48, 50,
       55, 51, 48, 50, 48, 48, 48, 48, 49, 32, 84, 48, 48, 48, 48, 48,
       48, 48, 48, 48, 48, 3 >>

Captures == { OptionQuoteMessageCapture }

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
