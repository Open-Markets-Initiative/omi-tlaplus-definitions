--------- MODULE CfeFutures_BinaryOrderEntry_v1_1_20_Firm_Captures ---------
(***************************************************************************)
(* Recorded Chicago Board Options Exchange Futures Binary Order Entry      *)
(* v1.1.20 packets, as the bytes they were captured as. Each one decodes,  *)
(* consumes the whole packet, and encodes back to exactly the bytes it was *)
(* read from.                                                              *)
(***************************************************************************)
EXTENDS CfeFutures_BinaryOrderEntry_v1_1_20_Firm

ClientHeartbeatCapture ==
    << 176, 227, 10, 0, 3, 0, 0, 0, 0, 0, 0, 0 >>

QuoteUpdateCapture ==
    << 176, 227, 99, 0, 238, 3, 0, 0, 20, 0, 0, 0, 49, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 79, 77, 73, 32,
       0, 0, 0, 0, 0, 0, 0, 0, 79, 77, 73, 49, 50, 51, 52, 53,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 67, 50, 78, 79, 77, 73,
       32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       1, 48, 48, 48, 51, 100, 90, 49, 78, 24, 222, 4, 0, 0, 0, 0,
       0, 2, 0, 0, 0 >>

Captures == { ClientHeartbeatCapture, QuoteUpdateCapture }

(* Every recorded packet reads, reads whole, and writes back unchanged *)
CapturesRoundTrip ==
    \A bytes \in Captures :
        LET read == DecodeFirmPacket(bytes)
        IN  /\ read.ok
            /\ read.rest = << >>
            /\ EncodeFirmPacket(read.value) = bytes

(* Every recorded packet is bytes *)
CapturesAreBytes == \A bytes \in Captures : \A i \in 1 .. Len(bytes) : bytes[i] \in Byte

=============================================================================
