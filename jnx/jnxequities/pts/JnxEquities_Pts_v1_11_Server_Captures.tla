--------------- MODULE JnxEquities_Pts_v1_11_Server_Captures ---------------
(***************************************************************************)
(* Recorded Japannext Securities v1.11 packets, as the bytes they were     *)
(* captured as. Each one decodes, consumes the whole packet, and encodes   *)
(* back to exactly the bytes it was read from.                             *)
(***************************************************************************)
EXTENDS JnxEquities_Pts_v1_11_Server

LoginAcceptedPacketCapture ==
    << 0, 31, 65, 49, 54, 56, 57, 49, 57, 50, 49, 50, 49, 32, 32, 32,
       32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 49, 51,
       53 >>

OrderAcceptedMessageCapture ==
    << 0, 66, 83, 65, 0, 0, 40, 158, 14, 167, 151, 0, 0, 0, 0, 74,
       114, 101, 102, 49, 32, 32, 32, 32, 32, 32, 66, 0, 0, 0, 100, 0,
       0, 17, 70, 68, 65, 89, 88, 0, 0, 43, 2, 0, 1, 134, 159, 0,
       0, 0, 0, 32, 65, 2, 206, 189, 67, 75, 45, 196, 93, 0, 0, 0,
       0, 76, 49, 49 >>

OrderCanceledMessageCapture ==
    << 0, 19, 83, 67, 0, 0, 29, 55, 12, 55, 164, 160, 0, 45, 200, 128,
       0, 0, 0, 100, 85 >>

OrderExecutedMessageCapture ==
    << 0, 31, 83, 69, 0, 0, 29, 55, 12, 11, 159, 24, 0, 45, 200, 122,
       0, 0, 0, 100, 0, 0, 195, 80, 65, 2, 206, 192, 11, 193, 100, 167,
       157, 0, 31, 83, 69, 0, 0, 29, 55, 12, 11, 159, 24, 0, 45, 200,
       123, 0, 0, 0, 100, 0, 0, 195, 80, 82, 2, 206, 192, 11, 193, 100,
       167, 157 >>

OrderRejectedMessageCapture ==
    << 0, 15, 83, 74, 0, 0, 29, 55, 12, 48, 167, 144, 0, 45, 200, 127,
       88 >>

Captures == { LoginAcceptedPacketCapture, OrderAcceptedMessageCapture, OrderCanceledMessageCapture, OrderExecutedMessageCapture, OrderRejectedMessageCapture }

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
