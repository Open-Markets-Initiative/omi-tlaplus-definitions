----------- MODULE Spectra_OrdersLogIncremental_v8_0_0_Captures ------------
(***************************************************************************)
(* Recorded Moscow Exchange SIMBA Spectra Orders Log Incremental v8.0.0    *)
(* packets, as the bytes they were captured as. Each one decodes, consumes *)
(* the whole packet, and encodes back to exactly the bytes it was read     *)
(* from.                                                                   *)
(***************************************************************************)
EXTENDS Spectra_OrdersLogIncremental_v8_0_0

BestPricesMessageCapture ==
    << 151, 75, 229, 5, 75, 0, 8, 0, 86, 181, 37, 37, 107, 200, 175, 24,
       86, 92, 37, 37, 107, 200, 175, 24, 138, 29, 0, 0, 0, 0, 14, 0,
       68, 77, 8, 0, 36, 0, 1, 176, 138, 111, 0, 0, 0, 0, 0, 152,
       142, 111, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 136,
       0, 0, 0, 0, 0, 0, 0, 199, 49, 40, 0 >>

OrderExecutionMessageCapture ==
    << 204, 151, 229, 5, 110, 0, 9, 0, 148, 145, 138, 117, 109, 200, 175, 24,
       10, 111, 137, 117, 109, 200, 175, 24, 138, 29, 0, 0, 74, 0, 16, 0,
       68, 77, 8, 0, 125, 122, 38, 0, 138, 29, 110, 28, 40, 77, 118, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 40, 77, 118, 0,
       0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 153, 78, 1, 0,
       138, 29, 110, 28, 1, 16, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 125, 98, 111, 0, 25, 137, 51, 0, 2, 49 >>

OrderUpdateMessageCapture ==
    << 145, 72, 229, 5, 86, 0, 9, 0, 183, 120, 152, 16, 107, 200, 175, 24,
       107, 72, 152, 16, 107, 200, 175, 24, 138, 29, 0, 0, 50, 0, 15, 0,
       68, 77, 8, 0, 211, 229, 2, 0, 138, 29, 21, 28, 224, 130, 111, 0,
       0, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 16, 32, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 199, 49, 40, 0,
       180, 238, 5, 0, 2, 48 >>

Captures == { BestPricesMessageCapture, OrderExecutionMessageCapture, OrderUpdateMessageCapture }

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
