---- MODULE NyseEquities_BinaryGateway_v6_0_ClientPillarMessage_Captures ----
(***************************************************************************)
(* Recorded New York Stock Exchange Binary Gateway v6.0 packets, as the    *)
(* bytes they were captured as. Each one decodes, consumes the whole       *)
(* packet, and encodes back to exactly the bytes it was read from.         *)
(***************************************************************************)
EXTENDS NyseEquities_BinaryGateway_v6_0_ClientPillarMessage

LoginMessageCapture ==
    << 1, 2, 76, 0, 84, 69, 83, 84, 85, 83, 69, 82, 32, 32, 32, 32,
       32, 32, 32, 32, 112, 97, 115, 115, 119, 111, 114, 100, 32, 32, 32, 32,
       32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
       32, 32, 32, 32, 65, 82, 67, 88, 49, 46, 49, 32, 32, 32, 32, 32,
       32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32 >>

NewOrderSingleAndCancelReplaceRequestMessageCapture ==
    << 5, 9, 138, 0, 1, 0, 0, 0, 1, 1, 0, 15, 1, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 122, 17, 174, 166, 243, 134, 24,
       64, 2, 106, 0, 233, 3, 0, 0, 84, 69, 83, 84, 0, 0, 0, 0,
       0, 233, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 64, 224, 64, 17, 0, 34, 64, 66, 24, 61, 0, 0, 0,
       0, 44, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 65, 2, 41, 0, 0, 0, 0, 0, 0, 100, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0 >>

OpenCapture ==
    << 5, 2, 30, 0, 1, 0, 0, 0, 1, 1, 0, 15, 1, 0, 0, 0,
       0, 0, 0, 0, 255, 224, 245, 5, 0, 0, 0, 0, 2, 0 >>

Captures == { LoginMessageCapture, NewOrderSingleAndCancelReplaceRequestMessageCapture, OpenCapture }

(* Every recorded packet reads, reads whole, and writes back unchanged *)
CapturesRoundTrip ==
    \A bytes \in Captures :
        LET read == DecodeClientPillarMessage(bytes)
        IN  /\ read.ok
            /\ read.rest = << >>
            /\ EncodeClientPillarMessage(read.value) = bytes

(* Every recorded packet is bytes *)
CapturesAreBytes == \A bytes \in Captures : \A i \in 1 .. Len(bytes) : bytes[i] \in Byte

=============================================================================
