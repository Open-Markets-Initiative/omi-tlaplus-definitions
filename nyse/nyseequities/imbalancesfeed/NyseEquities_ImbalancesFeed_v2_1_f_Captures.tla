------------ MODULE NyseEquities_ImbalancesFeed_v2_1_f_Captures ------------
(***************************************************************************)
(* Recorded New York Stock Exchange Imbalances Feed v2.1.f packets, as the *)
(* bytes they were captured as. Each one decodes, consumes the whole       *)
(* packet, and encodes back to exactly the bytes it was read from.         *)
(***************************************************************************)
EXTENDS NyseEquities_ImbalancesFeed_v2_1_f

ImbalanceMessageCapture ==
    << 83, 0, 11, 1, 83, 45, 0, 0, 182, 91, 206, 89, 104, 152, 217, 4,
       67, 0, 105, 0, 64, 165, 177, 89, 112, 23, 89, 6, 131, 173, 0, 0,
       10, 0, 0, 0, 184, 199, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 64, 6, 67, 32, 184, 199, 2, 0, 184, 199, 2, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0 >>

SequenceNumberResetMessageCapture ==
    << 30, 0, 12, 1, 1, 0, 0, 0, 158, 91, 206, 89, 114, 62, 67, 52,
       14, 0, 1, 0, 124, 86, 206, 89, 221, 183, 141, 51, 8, 1 >>

Captures == { ImbalanceMessageCapture, SequenceNumberResetMessageCapture }

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
