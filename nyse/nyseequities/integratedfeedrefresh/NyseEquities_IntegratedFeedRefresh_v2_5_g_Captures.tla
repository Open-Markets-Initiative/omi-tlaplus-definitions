-------- MODULE NyseEquities_IntegratedFeedRefresh_v2_5_g_Captures ---------
(***************************************************************************)
(* Recorded New York Stock Exchange Integrated Feed Refresh v2.5.g         *)
(* packets, as the bytes they were captured as. Each one decodes, consumes *)
(* the whole packet, and encodes back to exactly the bytes it was read     *)
(* from.                                                                   *)
(***************************************************************************)
EXTENDS NyseEquities_IntegratedFeedRefresh_v2_5_g

AddOrderRefreshMessageCapture ==
    << 59, 0, 18, 1, 53, 131, 57, 2, 91, 184, 228, 100, 0, 244, 155, 24,
       43, 0, 106, 0, 43, 142, 228, 100, 0, 221, 216, 25, 180, 39, 0, 0,
       4, 0, 0, 0, 78, 56, 0, 0, 0, 1, 56, 0, 176, 150, 97, 2,
       5, 0, 0, 0, 66, 32, 32, 32, 32, 32, 0 >>

ImbalanceMessageCapture ==
    << 89, 0, 18, 1, 51, 131, 57, 2, 91, 184, 228, 100, 0, 244, 155, 24,
       73, 0, 105, 0, 87, 184, 228, 100, 0, 208, 197, 40, 180, 39, 0, 0,
       84, 3, 0, 0, 208, 221, 119, 2, 157, 20, 0, 0, 138, 8, 0, 0,
       0, 0, 0, 0, 162, 3, 77, 66, 48, 57, 123, 2, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 32, 32 >>

RefreshHeaderMessageCapture ==
    << 32, 0, 18, 1, 49, 131, 57, 2, 91, 184, 228, 100, 0, 244, 155, 24,
       16, 0, 35, 0, 1, 0, 15, 0, 144, 90, 7, 0, 211, 4, 0, 0 >>

SecurityStatusMessageCapture ==
    << 62, 0, 18, 1, 52, 131, 57, 2, 91, 184, 228, 100, 0, 244, 155, 24,
       46, 0, 34, 0, 88, 184, 228, 100, 0, 231, 162, 38, 180, 39, 0, 0,
       161, 4, 0, 0, 79, 126, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 126, 79, 0 >>

SymbolIndexMappingMessageCapture ==
    << 60, 0, 18, 1, 50, 131, 57, 2, 91, 184, 228, 100, 0, 244, 155, 24,
       44, 0, 3, 0, 180, 39, 0, 0, 67, 85, 66, 69, 0, 0, 0, 0,
       0, 0, 0, 0, 1, 0, 56, 78, 6, 67, 100, 0, 208, 221, 119, 2,
       0, 0, 0, 0, 0, 78, 100, 0, 1, 0, 0, 0 >>

Captures == { AddOrderRefreshMessageCapture, ImbalanceMessageCapture, RefreshHeaderMessageCapture, SecurityStatusMessageCapture, SymbolIndexMappingMessageCapture }

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
