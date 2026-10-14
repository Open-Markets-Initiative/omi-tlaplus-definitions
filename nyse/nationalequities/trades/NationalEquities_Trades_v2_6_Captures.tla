--------------- MODULE NationalEquities_Trades_v2_6_Captures ---------------
(***************************************************************************)
(* Recorded New York Stock Exchange Trades v2.6 packets, as the bytes they *)
(* were captured as. Each one decodes, consumes the whole packet, and      *)
(* encodes back to exactly the bytes it was read from.                     *)
(***************************************************************************)
EXTENDS NationalEquities_Trades_v2_6

SecurityStatusMessageCapture ==
    << 62, 0, 11, 1, 147, 250, 0, 0, 88, 184, 228, 100, 0, 84, 207, 0,
       46, 0, 34, 0, 88, 184, 228, 100, 0, 186, 206, 0, 68, 39, 0, 0,
       4, 0, 0, 0, 79, 126, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 126, 79, 0 >>

TradeMessageCapture ==
    << 52, 0, 11, 1, 226, 38, 1, 0, 88, 184, 228, 100, 0, 217, 89, 5,
       36, 0, 220, 0, 88, 184, 228, 100, 0, 59, 89, 5, 34, 152, 0, 0,
       5, 0, 0, 0, 137, 3, 0, 0, 176, 155, 105, 4, 13, 0, 0, 0,
       64, 70, 32, 73 >>

Captures == { SecurityStatusMessageCapture, TradeMessageCapture }

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
