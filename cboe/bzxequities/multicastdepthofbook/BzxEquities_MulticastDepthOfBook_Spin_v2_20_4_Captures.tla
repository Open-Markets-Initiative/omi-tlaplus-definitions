------ MODULE BzxEquities_MulticastDepthOfBook_Spin_v2_20_4_Captures -------
(***************************************************************************)
(* Recorded Chicago Board Options Exchange Multicast Depth Of Book v2.20.4 *)
(* packets, as the bytes they were captured as. Each one decodes, consumes *)
(* the whole packet, and encodes back to exactly the bytes it was read     *)
(* from.                                                                   *)
(***************************************************************************)
EXTENDS BzxEquities_MulticastDepthOfBook_Spin_v2_20_4

LoginMessageCapture ==
    << 30, 0, 1, 0, 0, 0, 0, 0, 22, 1, 48, 48, 50, 51, 66, 65,
       84, 83, 32, 32, 115, 49, 98, 97, 116, 115, 32, 32, 32, 32 >>

LoginResponseMessageCapture ==
    << 11, 0, 1, 0, 0, 0, 0, 0, 3, 2, 65 >>

SpinFinishedMessageCapture ==
    << 20, 0, 2, 0, 0, 0, 0, 0, 6, 32, 178, 38, 1, 0, 6, 131,
       56, 1, 0, 0 >>

SpinImageAvailableMessageCapture ==
    << 14, 0, 1, 0, 0, 0, 0, 0, 6, 128, 56, 1, 0, 0 >>

SpinRequestMessageCapture ==
    << 14, 0, 1, 0, 0, 0, 0, 0, 6, 129, 56, 1, 0, 0 >>

SpinResponseMessageCapture ==
    << 19, 0, 1, 0, 0, 0, 0, 0, 11, 130, 56, 1, 0, 0, 0, 0,
       0, 0, 65 >>

TimeMessageCapture ==
    << 20, 0, 2, 0, 0, 0, 0, 0, 6, 32, 178, 38, 1, 0, 6, 131,
       56, 1, 0, 0 >>

Captures == { LoginMessageCapture, LoginResponseMessageCapture, SpinFinishedMessageCapture, SpinImageAvailableMessageCapture, SpinRequestMessageCapture, SpinResponseMessageCapture, TimeMessageCapture }

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
