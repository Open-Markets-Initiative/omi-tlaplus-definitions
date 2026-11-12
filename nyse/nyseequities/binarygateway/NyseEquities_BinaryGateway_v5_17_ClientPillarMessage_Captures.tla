---- MODULE NyseEquities_BinaryGateway_v5_17_ClientPillarMessage_Captures ----
(***************************************************************************)
(* Recorded New York Stock Exchange Binary Gateway v5.17 packets, as the   *)
(* bytes they were captured as. Each one decodes, consumes the whole       *)
(* packet, and encodes back to exactly the bytes it was read from.         *)
(***************************************************************************)
EXTENDS NyseEquities_BinaryGateway_v5_17_ClientPillarMessage

NewOrderSingleAndCancelReplaceRequestMessageCapture ==
    << 5, 9, 97, 0, 81, 5, 0, 66, 71, 87, 104, 129, 116, 129, 6, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       64, 2, 65, 0, 242, 220, 0, 0, 65, 65, 65, 65, 0, 0, 0, 0,
       0, 148, 11, 52, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 64, 32, 97, 0, 0, 50, 192, 13, 145, 110, 0, 0, 0,
       0, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0 >>

Captures == { NewOrderSingleAndCancelReplaceRequestMessageCapture }

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
