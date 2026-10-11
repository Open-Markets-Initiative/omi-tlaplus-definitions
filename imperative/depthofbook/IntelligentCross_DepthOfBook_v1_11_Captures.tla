------------ MODULE IntelligentCross_DepthOfBook_v1_11_Captures ------------
(***************************************************************************)
(* Recorded Imperative Execution Depth Of Book v1.11 packets, as the bytes *)
(* they were captured as. Each one decodes, consumes the whole packet, and *)
(* encodes back to exactly the bytes it was read from.                     *)
(***************************************************************************)
EXTENDS IntelligentCross_DepthOfBook_v1_11

OrderExecutedMessageCapture ==
    << 48, 48, 48, 48, 49, 57, 51, 54, 48, 80, 45, 119, 0, 0, 0, 0,
       0, 0, 1, 0, 40, 0, 74, 145, 27, 252, 100, 98, 189, 230, 210, 54,
       23, 32, 251, 162, 60, 10, 127, 233, 18, 2, 0, 0, 0, 198, 34, 72,
       0, 0, 0, 0, 0, 88, 64, 38, 186, 7, 0, 0, 0, 0 >>

TradeMessageCapture ==
    << 48, 48, 48, 48, 49, 57, 51, 54, 48, 80, 58, 119, 0, 0, 0, 0,
       0, 0, 1, 0, 51, 0, 75, 234, 17, 78, 228, 122, 189, 230, 210, 54,
       23, 255, 255, 255, 255, 255, 255, 255, 255, 88, 1, 0, 0, 0, 75, 76,
       65, 67, 32, 32, 32, 32, 32, 32, 32, 112, 143, 223, 22, 0, 0, 0,
       0, 42, 36, 72, 0, 0, 0, 0, 0 >>

Captures == { OrderExecutedMessageCapture, TradeMessageCapture }

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
