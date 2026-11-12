---- MODULE NyseEquities_BinaryGateway_v6_0_ServerPillarMessage_Captures ----
(***************************************************************************)
(* Recorded New York Stock Exchange Binary Gateway v6.0 packets, as the    *)
(* bytes they were captured as. Each one decodes, consumes the whole       *)
(* packet, and encodes back to exactly the bytes it was read from.         *)
(***************************************************************************)
EXTENDS NyseEquities_BinaryGateway_v6_0_ServerPillarMessage

CloseResponseCapture ==
    << 8, 2, 13, 0, 1, 0, 0, 0, 1, 1, 0, 33, 0 >>

EquitiesSymbolReferenceDataMessageCapture ==
    << 5, 9, 88, 0, 1, 0, 0, 0, 1, 1, 0, 33, 1, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 83, 88, 132, 166, 243, 134, 24,
       50, 2, 56, 0, 0, 83, 88, 132, 166, 243, 134, 24, 233, 3, 0, 0,
       80, 84, 69, 83, 84, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
       32, 32, 32, 32, 32, 32, 32, 32, 65, 82, 67, 88, 100, 1, 0, 0,
       0, 0, 0, 0, 0, 2, 0, 1 >>

ExecutionReportMessageCapture ==
    << 5, 9, 116, 0, 1, 0, 0, 0, 1, 1, 0, 13, 12, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 128, 218, 68, 234, 166, 243, 134, 24,
       144, 2, 84, 0, 128, 218, 68, 234, 166, 243, 134, 24, 233, 3, 0, 0,
       84, 69, 83, 84, 162, 187, 13, 0, 0, 0, 0, 0, 234, 3, 0, 0,
       0, 0, 0, 0, 97, 174, 10, 0, 0, 0, 0, 0, 64, 66, 24, 61,
       0, 0, 0, 0, 0, 0, 0, 0, 200, 0, 0, 0, 200, 0, 0, 0,
       82, 0, 0, 0, 0, 0, 0, 0, 0, 1, 128, 0, 0, 0, 0, 0,
       0, 0, 0, 0 >>

HeartbeatCapture ==
    << 4, 2, 4, 0 >>

LoginResponseCapture ==
    << 2, 2, 21, 0, 84, 69, 83, 84, 85, 83, 69, 82, 32, 32, 32, 32,
       32, 32, 32, 32, 0 >>

OpenResponseCapture ==
    << 6, 2, 14, 0, 1, 0, 0, 0, 1, 1, 0, 15, 0, 2 >>

OrderAndCancelReplaceAcknowledgementMessageCapture ==
    << 5, 9, 175, 0, 1, 0, 0, 0, 1, 1, 0, 13, 10, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 128, 16, 170, 174, 166, 243, 134, 24,
       96, 2, 143, 0, 128, 16, 170, 174, 166, 243, 134, 24, 233, 3, 0, 0,
       84, 69, 83, 84, 0, 0, 0, 0, 0, 233, 3, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 64, 224, 64, 17, 0,
       34, 64, 66, 24, 61, 0, 0, 0, 0, 44, 1, 0, 0, 0, 0, 0,
       0, 161, 187, 13, 0, 0, 0, 0, 0, 44, 1, 0, 0, 64, 66, 24,
       61, 0, 0, 0, 0, 0, 53, 0, 0, 0, 127, 0, 1, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 65, 2, 41, 0, 0, 0, 0, 0, 0, 100,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 128, 16, 170, 174, 166, 243, 134, 24 >>

StreamAvailCapture ==
    << 3, 2, 21, 0, 1, 0, 0, 0, 1, 1, 0, 15, 1, 0, 0, 0,
       0, 0, 0, 0, 6 >>

Captures == { CloseResponseCapture, EquitiesSymbolReferenceDataMessageCapture, ExecutionReportMessageCapture, HeartbeatCapture, LoginResponseCapture, OpenResponseCapture, OrderAndCancelReplaceAcknowledgementMessageCapture, StreamAvailCapture }

(* Every recorded packet reads, reads whole, and writes back unchanged *)
CapturesRoundTrip ==
    \A bytes \in Captures :
        LET read == DecodeServerPillarMessage(bytes)
        IN  /\ read.ok
            /\ read.rest = << >>
            /\ EncodeServerPillarMessage(read.value) = bytes

(* Every recorded packet is bytes *)
CapturesAreBytes == \A bytes \in Captures : \A i \in 1 .. Len(bytes) : bytes[i] \in Byte

=============================================================================
