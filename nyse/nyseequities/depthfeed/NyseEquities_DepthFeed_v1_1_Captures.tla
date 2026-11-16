--------------- MODULE NyseEquities_DepthFeed_v1_1_Captures ----------------
(***************************************************************************)
(* Recorded New York Stock Exchange Depth Feed v1.1 packets, as the bytes  *)
(* they were captured as. Each one decodes, consumes the whole packet, and *)
(* encodes back to exactly the bytes it was read from.                     *)
(***************************************************************************)
EXTENDS NyseEquities_DepthFeed_v1_1

DeltaMessageCapture ==
    << 51, 0, 11, 1, 27, 149, 3, 0, 225, 31, 33, 102, 225, 211, 90, 16,
       35, 0, 115, 0, 223, 31, 33, 102, 53, 72, 24, 57, 28, 27, 0, 0,
       226, 3, 0, 0, 1, 112, 205, 243, 10, 83, 1, 11, 0, 7, 0, 188,
       2, 0, 0 >>

ImbalanceMessageCapture ==
    << 89, 0, 11, 1, 239, 148, 3, 0, 224, 31, 33, 102, 115, 105, 30, 3,
       73, 0, 105, 0, 224, 31, 33, 102, 188, 71, 29, 3, 71, 65, 0, 0,
       212, 1, 0, 0, 48, 11, 202, 4, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 162, 3, 77, 32, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 64, 209, 238, 4, 32, 69, 165, 4,
       0, 0, 0, 0, 0, 0, 0, 32, 32 >>

SecurityStatusMessageCapture ==
    << 62, 0, 11, 1, 173, 160, 3, 0, 88, 32, 33, 102, 110, 10, 70, 0,
       46, 0, 34, 0, 88, 32, 33, 102, 17, 123, 68, 0, 174, 6, 0, 0,
       25, 0, 0, 0, 79, 80, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 126, 79, 0 >>

Captures == { DeltaMessageCapture, ImbalanceMessageCapture, SecurityStatusMessageCapture }

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
