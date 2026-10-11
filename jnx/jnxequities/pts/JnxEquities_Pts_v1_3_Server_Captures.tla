--------------- MODULE JnxEquities_Pts_v1_3_Server_Captures ----------------
(***************************************************************************)
(* Recorded Japannext Securities Proprietary Trading System v1.3 packets,  *)
(* as the bytes they were captured as. Each one decodes, consumes the      *)
(* whole packet, and encodes back to exactly the bytes it was read from.   *)
(***************************************************************************)
EXTENDS JnxEquities_Pts_v1_3_Server

LoginAcceptedPacketCapture ==
    << 0, 31, 65, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
       32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
       49 >>

OrderbookDirectoryMessageCapture ==
    << 0, 46, 83, 82, 0, 134, 0, 176, 0, 0, 28, 199, 74, 80, 51, 52,
       50, 51, 53, 57, 48, 48, 48, 51, 68, 65, 89, 32, 0, 0, 0, 100,
       0, 0, 0, 37, 0, 0, 0, 1, 0, 0, 55, 0, 0, 0, 31, 144,
       0, 46, 83, 82, 0, 134, 0, 176, 0, 0, 28, 200, 74, 80, 51, 55,
       57, 53, 48, 54, 48, 48, 48, 55, 68, 65, 89, 32, 0, 0, 0, 100,
       0, 0, 0, 37, 0, 0, 0, 1, 0, 0, 65, 60, 0, 0, 41, 204,
       0, 46, 83, 82, 0, 134, 0, 176, 0, 0, 28, 201, 74, 80, 51, 57,
       50, 48, 50, 56, 48, 48, 48, 57, 68, 65, 89, 32, 0, 0, 0, 100,
       0, 0, 0, 37, 0, 0, 0, 1, 0, 0, 65, 20, 0, 0, 41, 164,
       0, 46, 83, 82, 0, 134, 0, 176, 0, 0, 28, 202, 74, 80, 51, 49,
       54, 56, 55, 53, 48, 48, 48, 50, 68, 65, 89, 32, 0, 0, 0, 100,
       0, 0, 0, 37, 0, 0, 0, 1, 0, 0, 57, 228, 0, 0, 34, 116,
       0, 46, 83, 82, 0, 134, 0, 176, 0, 0, 28, 203, 74, 80, 51, 52,
       50, 56, 57, 55, 48, 48, 48, 50, 68, 65, 89, 32, 0, 0, 0, 100,
       0, 0, 0, 37, 0, 0, 0, 1, 0, 0, 27, 88, 0, 0, 19, 136,
       0, 46, 83, 82, 0, 134, 0, 176, 0, 0, 28, 204, 74, 80, 51, 53,
       52, 56, 56, 51, 48, 48, 48, 51, 68, 65, 89, 32, 0, 0, 0, 100,
       0, 0, 0, 37, 0, 0, 0, 1, 0, 0, 29, 176, 0, 0, 21, 224,
       0, 46, 83, 82, 0, 134, 0, 176, 0, 0, 28, 205, 74, 80, 51, 49,
       48, 53, 51, 52, 48, 48, 48, 56, 68, 65, 89, 32, 0, 0, 0, 100,
       0, 0, 0, 37, 0, 0, 0, 1, 0, 0, 125, 0, 0, 0, 85, 240,
       0, 46, 83, 82, 0, 134, 0, 176, 0, 0, 28, 206, 74, 80, 51, 51,
       48, 54, 52, 55, 48, 48, 48, 48, 68, 65, 89, 32, 0, 0, 0, 100,
       0, 0, 0, 37, 0, 0, 0, 1, 0, 0, 79, 206, 0, 0, 48, 142 >>

PriceTickSizeMessageCapture ==
    << 0, 18, 83, 76, 0, 134, 0, 176, 0, 0, 0, 37, 0, 0, 3, 232,
       0, 76, 75, 64, 0, 18, 83, 76, 0, 134, 0, 176, 0, 0, 0, 37,
       0, 0, 1, 244, 0, 45, 198, 192 >>

SecondsMessageCapture ==
    << 0, 6, 83, 84, 0, 0, 209, 158 >>

SystemEventMessageCapture ==
    << 0, 11, 83, 83, 0, 134, 0, 176, 32, 32, 32, 32, 79 >>

Captures == { LoginAcceptedPacketCapture, OrderbookDirectoryMessageCapture, PriceTickSizeMessageCapture, SecondsMessageCapture, SystemEventMessageCapture }

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
