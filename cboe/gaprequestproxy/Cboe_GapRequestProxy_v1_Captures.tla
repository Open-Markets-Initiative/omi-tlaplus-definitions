----------------- MODULE Cboe_GapRequestProxy_v1_Captures ------------------
(***************************************************************************)
(* Recorded Chicago Board Options Exchange v1 packets, as the bytes they   *)
(* were captured as. Each one decodes, consumes the whole packet, and      *)
(* encodes back to exactly the bytes it was read from.                     *)
(***************************************************************************)
EXTENDS Cboe_GapRequestProxy_v1

GapRequestMessageCapture ==
    << 17, 0, 1, 0, 0, 0, 0, 0, 9, 3, 1, 14, 0, 0, 0, 1,
       0 >>

GapResponseMessageCapture ==
    << 18, 0, 1, 0, 0, 0, 0, 0, 10, 4, 1, 14, 0, 0, 0, 1,
       0, 65 >>

LoginMessageCapture ==
    << 30, 0, 1, 0, 0, 0, 0, 0, 22, 1, 48, 48, 48, 54, 77, 75,
       68, 65, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32 >>

LoginResponseMessageCapture ==
    << 11, 0, 1, 0, 0, 0, 0, 0, 3, 2, 65 >>

Captures == { GapRequestMessageCapture, GapResponseMessageCapture, LoginMessageCapture, LoginResponseMessageCapture }

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
