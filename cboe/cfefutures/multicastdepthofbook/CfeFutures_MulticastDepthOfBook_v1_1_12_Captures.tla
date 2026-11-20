--------- MODULE CfeFutures_MulticastDepthOfBook_v1_1_12_Captures ----------
(***************************************************************************)
(* Recorded Chicago Board Options Exchange Futures Multicast Depth Of Book *)
(* v1.1.12 packets, as the bytes they were captured as. Each one decodes,  *)
(* consumes the whole packet, and encodes back to exactly the bytes it was *)
(* read from.                                                              *)
(***************************************************************************)
EXTENDS CfeFutures_MulticastDepthOfBook_v1_1_12

FuturesInstrumentDefinitionMessageCapture ==
    << 73, 0, 1, 2, 0, 0, 0, 0, 65, 187, 232, 93, 157, 13, 48, 48,
       48, 52, 121, 106, 207, 170, 37, 96, 90, 65, 77, 66, 49, 32, 0, 125,
       98, 52, 1, 50, 0, 84, 196, 9, 0, 0, 0, 0, 0, 0, 2, 45,
       0, 0, 0, 0, 0, 255, 255, 255, 255, 48, 48, 48, 52, 82, 57, 1,
       0, 0, 0, 48, 48, 48, 52, 121, 90 >>

Captures == { FuturesInstrumentDefinitionMessageCapture }

(* Every recorded packet reads, reads whole, and writes back unchanged *)
CapturesRoundTrip ==
    \A bytes \in Captures :
        LET read == DecodePacket(bytes)
        IN  /\ read.ok
            /\ read.rest = << >>
            /\ EncodePacket(read.value) = bytes

(* Every recorded packet is bytes *)
CapturesAreBytes == \A bytes \in Captures : \A i \in 1 .. Len(bytes) : bytes[i] \in Byte

=============================================================================
