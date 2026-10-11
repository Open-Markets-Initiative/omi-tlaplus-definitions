----------- MODULE B3Derivatives_BinaryEntryPoint_v8_0_Captures ------------
(***************************************************************************)
(* Recorded Brasil, Bolsa, Balcão Binary Entry Point v8.0 packets, as the  *)
(* bytes they were captured as. Each one decodes, consumes the whole       *)
(* packet, and encodes back to exactly the bytes it was read from.         *)
(***************************************************************************)
EXTENDS B3Derivatives_BinaryEntryPoint_v8_0

EstablishAckMessageCapture ==
    << 48, 0, 80, 235, 36, 0, 5, 0, 1, 0, 2, 0, 8, 225, 245, 5,
       167, 18, 159, 46, 143, 1, 0, 0, 64, 233, 197, 80, 242, 13, 203, 23,
       232, 3, 0, 0, 0, 0, 0, 0, 20, 3, 0, 0, 118, 1, 0, 0 >>

EstablishRejectMessageCapture ==
    << 38, 0, 80, 235, 26, 0, 6, 0, 1, 0, 2, 0, 8, 225, 245, 5,
       167, 18, 159, 46, 143, 1, 0, 0, 0, 113, 72, 79, 242, 13, 203, 23,
       9, 0, 118, 1, 0, 0 >>

NegotiateRejectMessageCapture ==
    << 48, 0, 80, 235, 36, 0, 3, 0, 1, 0, 2, 0, 8, 225, 245, 5,
       22, 198, 239, 46, 143, 1, 0, 0, 192, 239, 141, 77, 242, 13, 203, 23,
       45, 0, 0, 0, 3, 0, 0, 0, 167, 18, 159, 46, 143, 1, 0, 0 >>

RetransmissionMessageCapture ==
    << 32, 0, 80, 235, 20, 0, 13, 0, 1, 0, 2, 0, 8, 225, 245, 5,
       64, 60, 111, 215, 93, 16, 203, 23, 140, 4, 0, 0, 5, 0, 0, 0 >>

RetransmitRejectMessageCapture ==
    << 25, 0, 80, 235, 13, 0, 14, 0, 1, 0, 2, 0, 8, 225, 245, 5,
       0, 104, 133, 172, 94, 16, 203, 23, 0 >>

SequenceMessageCapture ==
    << 16, 0, 80, 235, 4, 0, 9, 0, 1, 0, 2, 0, 159, 1, 0, 0 >>

TerminateMessageCapture ==
    << 25, 0, 80, 235, 13, 0, 7, 0, 1, 0, 2, 0, 8, 225, 245, 5,
       22, 198, 239, 46, 143, 1, 0, 0, 2 >>

Captures == { EstablishAckMessageCapture, EstablishRejectMessageCapture, NegotiateRejectMessageCapture, RetransmissionMessageCapture, RetransmitRejectMessageCapture, SequenceMessageCapture, TerminateMessageCapture }

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
