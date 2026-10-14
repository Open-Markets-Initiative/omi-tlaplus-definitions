---------------- MODULE ArcaOptions_TopFeed_v1_2_c_Captures ----------------
(***************************************************************************)
(* Recorded New York Stock Exchange Top Feed v1.2.c packets, as the bytes  *)
(* they were captured as. Each one decodes, consumes the whole packet, and *)
(* encodes back to exactly the bytes it was read from.                     *)
(***************************************************************************)
EXTENDS ArcaOptions_TopFeed_v1_2_c

HeartBeatCapture ==
    << 16, 0, 1, 0, 2, 0, 0, 0, 55, 60, 180, 97, 0, 61, 102, 3 >>

OptionsQuoteMessageCapture ==
    << 58, 0, 11, 1, 84, 32, 10, 0, 42, 185, 180, 97, 0, 30, 41, 29,
       42, 0, 84, 1, 0, 202, 40, 29, 213, 190, 210, 1, 5, 0, 0, 0,
       212, 167, 1, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       49, 0, 10, 0, 0, 0, 0, 0, 0, 0 >>

SequenceNumberResetMessageCapture ==
    << 30, 0, 12, 1, 1, 0, 0, 0, 46, 60, 180, 97, 0, 236, 23, 2,
       14, 0, 1, 0, 235, 59, 180, 97, 0, 131, 58, 37, 162, 51 >>

Captures == { HeartBeatCapture, OptionsQuoteMessageCapture, SequenceNumberResetMessageCapture }

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
