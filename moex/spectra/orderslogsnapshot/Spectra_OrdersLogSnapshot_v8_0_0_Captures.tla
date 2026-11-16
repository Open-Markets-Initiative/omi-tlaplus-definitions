------------- MODULE Spectra_OrdersLogSnapshot_v8_0_0_Captures -------------
(***************************************************************************)
(* Recorded Moscow Exchange SIMBA Spectra Orders Log Snapshot v8.0.0       *)
(* packets, as the bytes they were captured as. Each one decodes, consumes *)
(* the whole packet, and encodes back to exactly the bytes it was read     *)
(* from.                                                                   *)
(***************************************************************************)
EXTENDS Spectra_OrdersLogSnapshot_v8_0_0

OrderBookSnapshotMessageCapture ==
    << 83, 42, 0, 0, 157, 0, 6, 0, 191, 245, 160, 16, 107, 200, 175, 24,
       16, 0, 17, 0, 68, 77, 8, 0, 48, 134, 121, 0, 187, 29, 229, 5,
       41, 0, 0, 0, 138, 29, 0, 0, 57, 0, 2, 81, 253, 0, 0, 138,
       29, 238, 27, 120, 177, 88, 1, 132, 171, 175, 24, 92, 43, 0, 0, 0,
       0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 49, 110, 214, 1, 0, 138, 29, 238, 27, 226, 232, 149, 52,
       21, 174, 175, 24, 88, 2, 0, 0, 0, 0, 0, 0, 18, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 16, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 49 >>

SequenceResetMessageCapture ==
    << 142, 57, 0, 0, 28, 0, 1, 0, 177, 63, 143, 166, 107, 200, 175, 24,
       4, 0, 2, 0, 68, 77, 8, 0, 1, 0, 0, 0 >>

Captures == { OrderBookSnapshotMessageCapture, SequenceResetMessageCapture }

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
