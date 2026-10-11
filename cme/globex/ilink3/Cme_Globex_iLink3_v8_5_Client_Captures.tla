-------------- MODULE Cme_Globex_iLink3_v8_5_Client_Captures ---------------
(***************************************************************************)
(* Recorded CME Group iLink 3 v8.5 packets, as the bytes they were         *)
(* captured as. Each one decodes, consumes the whole packet, and encodes   *)
(* back to exactly the bytes it was read from.                             *)
(***************************************************************************)
EXTENDS Cme_Globex_iLink3_v8_5_Client

QuoteCancelCapture ==
    << 80, 0, 254, 202, 52, 0, 16, 2, 8, 0, 5, 0, 1, 0, 0, 0,
       0, 0, 0, 0, 196, 159, 157, 33, 98, 8, 2, 22, 0, 2, 0, 0,
       0, 84, 83, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 85, 83, 0, 0, 0, 100, 0, 0, 0, 4, 255,
       10, 0, 1, 91, 78, 47, 65, 93, 0, 255, 255, 255, 127, 10, 0, 0 >>

SequenceCapture ==
    << 26, 0, 254, 202, 14, 0, 250, 1, 8, 0, 5, 0, 31, 243, 215, 247,
       79, 162, 5, 0, 3, 0, 0, 0, 1, 0 >>

Captures == { QuoteCancelCapture, SequenceCapture }

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
