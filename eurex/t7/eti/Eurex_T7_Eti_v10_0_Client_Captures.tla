---------------- MODULE Eurex_T7_Eti_v10_0_Client_Captures -----------------
(***************************************************************************)
(* Recorded Eurex Exchange Enhanced Trading Interface v10.0 packets, as    *)
(* the bytes they were captured as. Each one decodes, consumes the whole   *)
(* packet, and encodes back to exactly the bytes it was read from.         *)
(***************************************************************************)
EXTENDS Eurex_T7_Eti_v10_0_Client

OrderExecResponseCapture ==
    << 16, 1, 0, 0, 119, 39, 80, 0, 88, 146, 239, 99, 225, 71, 66, 23,
       235, 1, 241, 99, 225, 71, 66, 23, 89, 19, 245, 99, 225, 71, 66, 23,
       5, 21, 245, 99, 225, 71, 66, 23, 196, 199, 245, 99, 225, 71, 66, 23,
       3, 0, 0, 0, 1, 0, 4, 23, 66, 64, 6, 132, 168, 140, 31, 0,
       0, 0, 0, 0, 0, 0, 1, 1, 69, 85, 181, 16, 241, 69, 66, 23,
       1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0,
       2, 0, 0, 0, 163, 2, 0, 1, 186, 192, 241, 99, 225, 71, 66, 23,
       255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
       0, 0, 0, 0, 0, 0, 0, 0, 16, 39, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 163, 2, 0, 0, 2, 0, 101, 0,
       2, 5, 50, 70, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 232, 118, 72, 23, 0, 0, 0, 16, 39, 0, 0, 0, 0, 0, 0,
       2, 0, 0, 5, 144, 1, 0, 5, 2, 0, 0, 0, 0, 0, 0, 0,
       192, 191, 94, 0, 0, 0, 0, 0, 0, 156, 244, 4, 96, 0, 0, 0,
       16, 39, 0, 0, 0, 0, 0, 0, 145, 1, 0, 5, 1, 1, 0, 0,
       67, 73, 99, 0, 0, 0, 0, 0, 0, 180, 125, 188, 72, 0, 0, 0,
       16, 39, 0, 0, 0, 0, 0, 0, 146, 1, 0, 5, 2, 1, 0, 0 >>

Captures == { OrderExecResponseCapture }

(* Every recorded packet reads, reads whole, and writes back unchanged *)
CapturesRoundTrip ==
    \A bytes \in Captures :
        LET read == DecodeClientPacket(bytes)
        IN  /\ read.ok
            /\ read.rest = << >>
            /\ EncodeClientPacket(read.value) = bytes

(* Every recorded packet is bytes *)
CapturesAreBytes == \A bytes \in Captures : \A i \in 1 .. Len(bytes) : bytes[i] \in Byte

=============================================================================
