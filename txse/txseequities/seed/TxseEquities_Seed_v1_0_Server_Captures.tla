-------------- MODULE TxseEquities_Seed_v1_0_Server_Captures ---------------
(***************************************************************************)
(* Recorded Texas Stock Exchange Session Enabled Entry Daemon v1.0         *)
(* packets, as the bytes they were captured as. Each one decodes, consumes *)
(* the whole packet, and encodes back to exactly the bytes it was read     *)
(* from.                                                                   *)
(***************************************************************************)
EXTENDS TxseEquities_Seed_v1_0_Server

LimitOrderAcceptedMessageCapture ==
    << 66, 0, 50, 2, 73, 7, 14, 0, 0, 48, 51, 197, 249, 171, 158, 119,
       24, 2, 229, 133, 1, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0,
       0, 100, 0, 0, 0, 17, 1, 0, 0, 4, 11, 0, 73, 217, 113, 2,
       0, 0, 0, 0, 0, 0, 80, 79, 28, 1, 102, 222, 171, 0, 84, 88,
       83, 69, 32, 32 >>

LogonResponseMessageCapture ==
    << 31, 0, 49, 148, 212, 21, 105, 49, 49, 65, 68, 1, 0, 0, 0, 0,
       0, 0, 0, 224, 46, 0, 0, 0, 0, 0, 0, 0, 3, 251, 162, 221,
       65 >>

Captures == { LimitOrderAcceptedMessageCapture, LogonResponseMessageCapture }

(* Every recorded packet reads, reads whole, and writes back unchanged *)
CapturesRoundTrip ==
    \A bytes \in Captures :
        LET read == DecodeServerPacket(bytes)
        IN  /\ read.ok
            /\ read.rest = << >>
            /\ EncodeServerPacket(read.value) = bytes

(* Every recorded packet is bytes *)
CapturesAreBytes == \A bytes \in Captures : \A i \in 1 .. Len(bytes) : bytes[i] \in Byte

=============================================================================
