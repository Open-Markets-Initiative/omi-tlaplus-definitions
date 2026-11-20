-------------- MODULE TxseEquities_Seed_v1_0_Client_Captures ---------------
(***************************************************************************)
(* Recorded Texas Stock Exchange Session Enabled Entry Daemon v1.0         *)
(* packets, as the bytes they were captured as. Each one decodes, consumes *)
(* the whole packet, and encodes back to exactly the bytes it was read     *)
(* from.                                                                   *)
(***************************************************************************)
EXTENDS TxseEquities_Seed_v1_0_Client

LimitOrderMessageCapture ==
    << 40, 0, 54, 76, 0, 2, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0,
       100, 0, 0, 0, 17, 1, 0, 0, 4, 11, 0, 73, 217, 113, 2, 0,
       0, 0, 80, 79, 28, 1, 102, 222, 171, 0 >>

LogonRequestPacketCapture ==
    << 33, 0, 53, 0, 0, 0, 0, 0, 0, 0, 0, 79, 69, 77, 65, 78,
       74, 85, 76, 79, 69, 77, 65, 78, 74, 85, 76, 1, 0, 0, 0, 0,
       0, 0, 0 >>

Captures == { LimitOrderMessageCapture, LogonRequestPacketCapture }

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
