--------------- MODULE JnxEquities_Pts_v1_11_Client_Captures ---------------
(***************************************************************************)
(* Recorded Japannext Securities v1.11 packets, as the bytes they were     *)
(* captured as. Each one decodes, consumes the whole packet, and encodes   *)
(* back to exactly the bytes it was read from.                             *)
(***************************************************************************)
EXTENDS JnxEquities_Pts_v1_11_Client

CancelOrderMessageCapture ==
    << 0, 10, 85, 88, 0, 45, 200, 128, 0, 0, 0, 100 >>

EnterOrderMessageCapture ==
    << 0, 49, 85, 79, 0, 0, 0, 74, 114, 101, 102, 49, 32, 32, 32, 32,
       32, 32, 66, 0, 0, 0, 100, 0, 0, 17, 70, 68, 65, 89, 88, 0,
       0, 43, 2, 0, 1, 134, 159, 0, 0, 0, 0, 32, 65, 0, 0, 0,
       0, 49, 49 >>

LoginRequestPacketCapture ==
    << 0, 47, 76, 117, 115, 101, 114, 32, 32, 112, 97, 115, 115, 119, 111, 114,
       100, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
       32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
       48 >>

ReplaceOrderMessageCapture ==
    << 0, 27, 85, 85, 0, 0, 0, 95, 0, 0, 0, 96, 0, 0, 2, 188,
       0, 0, 43, 2, 0, 1, 134, 159, 32, 0, 0, 0, 0 >>

Captures == { CancelOrderMessageCapture, EnterOrderMessageCapture, LoginRequestPacketCapture, ReplaceOrderMessageCapture }

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
