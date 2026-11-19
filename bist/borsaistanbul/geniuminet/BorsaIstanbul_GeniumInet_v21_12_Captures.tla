------------- MODULE BorsaIstanbul_GeniumInet_v21_12_Captures --------------
(***************************************************************************)
(* Recorded Borsa İstanbul A.Ş. Genium Inet v21.12 packets, as the bytes   *)
(* they were captured as. Each one decodes, consumes the whole packet, and *)
(* encodes back to exactly the bytes it was read from.                     *)
(***************************************************************************)
EXTENDS BorsaIstanbul_GeniumInet_v21_12

CombinationOrderBookLegCapture ==
    << 84, 82, 50, 56, 57, 55, 56, 52, 51, 57, 0, 0, 0, 0, 0, 0,
       6, 78, 0, 1, 0, 18, 77, 44, 34, 190, 183, 0, 69, 53, 197, 0,
       203, 53, 197, 67, 0, 0, 0, 1 >>

OrderBookStateMessageCapture ==
    << 84, 82, 50, 56, 57, 55, 56, 52, 51, 57, 0, 0, 0, 0, 0, 0,
       38, 167, 0, 3, 0, 29, 79, 2, 137, 54, 174, 1, 126, 20, 119, 80,
       95, 71, 85, 78, 83, 79, 78, 85, 32, 32, 32, 32, 32, 32, 32, 32,
       32, 32, 32, 0, 29, 79, 2, 137, 54, 174, 1, 128, 20, 119, 80, 95,
       71, 85, 78, 83, 79, 78, 85, 32, 32, 32, 32, 32, 32, 32, 32, 32,
       32, 32, 0, 29, 79, 2, 137, 54, 174, 1, 130, 20, 119, 80, 95, 71,
       85, 78, 83, 79, 78, 85, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
       32 >>

Captures == { CombinationOrderBookLegCapture, OrderBookStateMessageCapture }

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
