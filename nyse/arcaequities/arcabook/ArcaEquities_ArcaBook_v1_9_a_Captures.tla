--------------- MODULE ArcaEquities_ArcaBook_v1_9_a_Captures ---------------
(***************************************************************************)
(* Recorded New York Stock Exchange ArcaBook v1.9.a packets, as the bytes  *)
(* they were captured as. Each one decodes, consumes the whole packet, and *)
(* encodes back to exactly the bytes it was read from.                     *)
(***************************************************************************)
EXTENDS ArcaEquities_ArcaBook_v1_9_a

AddOrderMessageCapture ==
    << 47, 0, 11, 1, 79, 28, 0, 0, 144, 138, 25, 83, 168, 250, 1, 6,
       31, 0, 100, 0, 192, 14, 254, 5, 84, 31, 0, 0, 14, 0, 0, 0,
       152, 6, 0, 0, 48, 236, 1, 0, 200, 0, 0, 0, 66, 0, 7 >>

DeleteOrderMessageCapture ==
    << 39, 0, 11, 1, 139, 24, 0, 0, 144, 138, 25, 83, 0, 153, 173, 19,
       23, 0, 102, 0, 104, 118, 169, 19, 204, 19, 0, 0, 31, 0, 0, 0,
       30, 7, 0, 0, 66, 0, 0 >>

ExecutionMessageCapture ==
    << 81, 0, 11, 2, 253, 120, 0, 0, 149, 138, 25, 83, 48, 231, 32, 54,
       34, 0, 103, 0, 248, 49, 29, 54, 204, 19, 0, 0, 51, 0, 0, 0,
       43, 7, 0, 0, 196, 99, 10, 0, 200, 0, 0, 0, 0, 0, 2, 0,
       0, 0, 31, 0, 101, 0, 248, 49, 29, 54, 204, 19, 0, 0, 52, 0,
       0, 0, 43, 7, 0, 0, 196, 99, 10, 0, 100, 0, 0, 0, 83, 0,
       0 >>

ImbalanceMessageCapture ==
    << 68, 0, 11, 1, 228, 11, 0, 0, 180, 135, 25, 83, 168, 251, 186, 55,
       52, 0, 105, 0, 180, 135, 25, 83, 160, 193, 182, 55, 140, 157, 0, 0,
       3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 144, 1, 79, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0 >>

ModifyOrderMessageCapture ==
    << 47, 0, 11, 1, 143, 60, 0, 0, 144, 138, 25, 83, 24, 4, 39, 28,
       31, 0, 101, 0, 224, 203, 35, 28, 64, 28, 0, 0, 101, 0, 0, 0,
       246, 6, 0, 0, 68, 18, 9, 0, 244, 1, 0, 0, 83, 0, 0 >>

Captures == { AddOrderMessageCapture, DeleteOrderMessageCapture, ExecutionMessageCapture, ImbalanceMessageCapture, ModifyOrderMessageCapture }

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
