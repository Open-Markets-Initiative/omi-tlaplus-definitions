------------ MODULE Spectra_FutInfoIncremental_v8_0_0_Captures -------------
(***************************************************************************)
(* Recorded Moscow Exchange SIMBA Spectra Futures Instrument Incremental   *)
(* v8.0.0 packets, as the bytes they were captured as. Each one decodes,   *)
(* consumes the whole packet, and encodes back to exactly the bytes it was *)
(* read from.                                                              *)
(***************************************************************************)
EXTENDS Spectra_FutInfoIncremental_v8_0_0

HeartbeatMessageCapture ==
    << 173, 19, 0, 0, 36, 0, 9, 0, 46, 91, 238, 55, 108, 200, 175, 24,
       0, 0, 0, 0, 0, 0, 0, 0, 255, 255, 255, 255, 0, 0, 1, 0,
       68, 77, 8, 0 >>

SecurityGroupStatusMessageCapture ==
    << 175, 19, 0, 0, 74, 0, 9, 0, 156, 87, 154, 9, 121, 200, 175, 24,
       0, 0, 0, 0, 0, 0, 0, 0, 255, 255, 255, 255, 38, 0, 22, 0,
       68, 77, 8, 0, 13, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0,
       0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 238, 27, 0,
       0, 18, 0, 0, 222, 8, 121, 200, 175, 24 >>

SecurityMassStatusMessageCapture ==
    << 19, 21, 0, 0, 50, 0, 9, 0, 112, 118, 95, 95, 122, 200, 175, 24,
       0, 0, 0, 0, 0, 0, 0, 0, 255, 255, 255, 255, 0, 0, 19, 0,
       68, 77, 8, 0, 5, 0, 2, 0, 214, 55, 118, 0, 122, 4, 13, 121,
       0, 122 >>

TradingSessionStatusMessageCapture ==
    << 17, 21, 0, 0, 84, 0, 9, 0, 249, 48, 251, 46, 121, 200, 175, 24,
       0, 0, 0, 0, 0, 0, 0, 0, 255, 255, 255, 255, 48, 0, 26, 0,
       68, 77, 8, 0, 0, 6, 20, 201, 212, 250, 71, 0, 64, 171, 194, 203,
       212, 250, 71, 0, 5, 138, 29, 0, 0, 2, 68, 3, 233, 2, 0, 0,
       0, 0, 0, 0, 128, 156, 172, 201, 212, 250, 71, 0, 64, 171, 194, 203,
       212, 250, 71, 0 >>

Captures == { HeartbeatMessageCapture, SecurityGroupStatusMessageCapture, SecurityMassStatusMessageCapture, TradingSessionStatusMessageCapture }

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
