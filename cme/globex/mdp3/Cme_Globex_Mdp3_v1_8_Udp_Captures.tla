----------------- MODULE Cme_Globex_Mdp3_v1_8_Udp_Captures -----------------
(***************************************************************************)
(* Recorded CME Group Market Data Platform 3 v1.8 packets, as the bytes    *)
(* they were captured as. Each one decodes, consumes the whole packet, and *)
(* encodes back to exactly the bytes it was read from.                     *)
(***************************************************************************)
EXTENDS Cme_Globex_Mdp3_v1_8_Udp

MdIncrementalRefreshTradeSummaryCapture ==
    << 101, 187, 8, 1, 145, 26, 69, 253, 13, 77, 120, 20, 96, 0, 11, 0,
       42, 0, 1, 0, 8, 0, 111, 194, 64, 253, 13, 77, 120, 20, 1, 0,
       0, 32, 0, 1, 0, 166, 123, 55, 26, 0, 0, 0, 1, 0, 0, 0,
       212, 172, 2, 0, 180, 79, 48, 0, 2, 0, 0, 0, 1, 0, 255, 255,
       255, 255, 0, 0, 16, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0,
       0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 40, 0, 11, 0,
       37, 0, 1, 0, 8, 0, 111, 194, 64, 253, 13, 77, 120, 20, 2, 0,
       0, 16, 0, 1, 35, 0, 0, 0, 212, 172, 2, 0, 181, 79, 48, 0,
       0, 0, 0, 0, 64, 0, 11, 0, 32, 0, 1, 0, 8, 0, 111, 194,
       64, 253, 13, 77, 120, 20, 132, 0, 0, 32, 0, 1, 0, 166, 123, 55,
       26, 0, 0, 0, 26, 0, 0, 0, 212, 172, 2, 0, 182, 79, 48, 0,
       2, 0, 0, 0, 1, 1, 49, 0, 0, 0, 0, 0, 24, 0, 0, 0,
       0, 0, 0, 0 >>

Captures == { MdIncrementalRefreshTradeSummaryCapture }

(* Every recorded packet reads, reads whole, and writes back unchanged *)
CapturesRoundTrip ==
    \A bytes \in Captures :
        LET read == DecodeUdpPacket(bytes)
        IN  /\ read.ok
            /\ read.rest = << >>
            /\ EncodeUdpPacket(read.value) = bytes

(* Every recorded packet is bytes *)
CapturesAreBytes == \A bytes \in Captures : \A i \in 1 .. Len(bytes) : bytes[i] \in Byte

=============================================================================
