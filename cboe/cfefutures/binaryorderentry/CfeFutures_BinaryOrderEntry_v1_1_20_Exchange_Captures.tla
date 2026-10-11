------- MODULE CfeFutures_BinaryOrderEntry_v1_1_20_Exchange_Captures -------
(***************************************************************************)
(* Recorded Chicago Board Options Exchange Futures Binary Order Entry      *)
(* v1.1.20 packets, as the bytes they were captured as. Each one decodes,  *)
(* consumes the whole packet, and encodes back to exactly the bytes it was *)
(* read from.                                                              *)
(***************************************************************************)
EXTENDS CfeFutures_BinaryOrderEntry_v1_1_20_Exchange

QuoteUpdateAcknowledgementCapture ==
    << 176, 227, 53, 0, 235, 5, 1, 0, 0, 0, 0, 0, 144, 210, 55, 36,
       128, 80, 130, 22, 49, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 89, 47, 55, 36, 128, 80, 130, 22, 1, 139, 196, 138,
       7, 126, 123, 43, 2, 65, 0 >>

ServerHeartbeatCapture ==
    << 176, 227, 10, 0, 248, 1, 0, 0, 0, 0, 0, 0 >>

Captures == { QuoteUpdateAcknowledgementCapture, ServerHeartbeatCapture }

(* Every recorded packet reads, reads whole, and writes back unchanged *)
CapturesRoundTrip ==
    \A bytes \in Captures :
        LET read == DecodeExchangePacket(bytes)
        IN  /\ read.ok
            /\ read.rest = << >>
            /\ EncodeExchangePacket(read.value) = bytes

(* Every recorded packet is bytes *)
CapturesAreBytes == \A bytes \in Captures : \A i \in 1 .. Len(bytes) : bytes[i] \in Byte

=============================================================================
