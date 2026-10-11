--------------- MODULE JnxEquities_Pts_v1_3_Client_Captures ----------------
(***************************************************************************)
(* Recorded Japannext Securities Proprietary Trading System v1.3 packets,  *)
(* as the bytes they were captured as. Each one decodes, consumes the      *)
(* whole packet, and encodes back to exactly the bytes it was read from.   *)
(***************************************************************************)
EXTENDS JnxEquities_Pts_v1_3_Client

LoginRequestPacketCapture ==
    << 0, 47, 76, 117, 115, 101, 114, 32, 32, 112, 97, 115, 115, 119, 111, 114,
       100, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
       32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
       49 >>

Captures == { LoginRequestPacketCapture }

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
