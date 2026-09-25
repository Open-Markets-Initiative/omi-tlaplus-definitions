------------------ MODULE IexEquities_Tops_v1_56_Captures ------------------
(***************************************************************************)
(* Recorded Investors Exchange Top Of Book v1.56 packets, as the bytes     *)
(* they were captured as. Each one decodes, consumes the whole packet, and *)
(* encodes back to exactly the bytes it was read from.                     *)
(***************************************************************************)
EXTENDS IexEquities_Tops_v1_56

QuoteUpdateMessageCapture ==
    << 1, 0, 2, 128, 1, 0, 0, 0, 0, 0, 59, 68, 44, 0, 1, 0,
       124, 171, 5, 0, 0, 0, 0, 0, 254, 32, 0, 0, 0, 0, 0, 0,
       245, 171, 227, 222, 32, 186, 241, 20, 42, 0, 81, 64, 73, 238, 47, 222,
       32, 186, 241, 20, 90, 73, 69, 88, 84, 32, 32, 32, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 16, 39, 0, 0, 0, 0, 0, 0,
       100, 0, 0, 0 >>

TradeReportMessageCapture ==
    << 1, 0, 2, 128, 1, 0, 0, 0, 0, 0, 59, 68, 44, 0, 1, 0,
       52, 173, 5, 0, 0, 0, 0, 0, 8, 33, 0, 0, 0, 0, 0, 0,
       236, 110, 2, 48, 40, 186, 241, 20, 42, 0, 84, 64, 13, 160, 211, 47,
       40, 186, 241, 20, 90, 73, 69, 88, 84, 32, 32, 32, 100, 0, 0, 0,
       16, 39, 0, 0, 0, 0, 0, 0, 230, 164, 4, 0, 0, 0, 0, 0,
       0, 0, 0, 0 >>

Captures == { QuoteUpdateMessageCapture, TradeReportMessageCapture }

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
