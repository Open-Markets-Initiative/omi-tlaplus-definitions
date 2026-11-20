---------- MODULE CfeFutures_MulticastDepthOfBook_v1_1_6_Captures ----------
(***************************************************************************)
(* Recorded Chicago Board Options Exchange Futures Multicast Depth Of Book *)
(* v1.1.6 packets, as the bytes they were captured as. Each one decodes,   *)
(* consumes the whole packet, and encodes back to exactly the bytes it was *)
(* read from.                                                              *)
(***************************************************************************)
EXTENDS CfeFutures_MulticastDepthOfBook_v1_1_6

AddOrderShortMessageCapture ==
    << 33, 0, 1, 1, 148, 83, 0, 0, 25, 34, 40, 246, 221, 58, 241, 44,
       117, 7, 126, 178, 31, 2, 66, 1, 0, 48, 48, 48, 50, 97, 86, 200,
       5 >>

DeleteOrderMessageCapture ==
    << 22, 0, 1, 1, 144, 83, 0, 0, 14, 41, 72, 4, 191, 58, 238, 148,
       55, 7, 126, 166, 31, 2 >>

FuturesInstrumentDefinitionMessageCapture ==
    << 49, 0, 1, 2, 0, 0, 0, 0, 41, 187, 152, 130, 159, 34, 48, 48,
       48, 50, 84, 116, 45, 11, 202, 92, 90, 86, 65, 79, 32, 32, 0, 171,
       60, 52, 1, 1, 0, 84, 244, 1, 0, 0, 0, 0, 0, 0, 0, 0,
       0 >>

HeartbeatCapture ==
    << 8, 0, 0, 1, 142, 82, 0, 0 >>

ModifyOrderShortMessageCapture ==
    << 26, 0, 1, 1, 245, 85, 0, 0, 18, 40, 232, 193, 236, 4, 83, 47,
       123, 7, 126, 86, 31, 2, 35, 0, 109, 6 >>

TimeMessageCapture ==
    << 36, 0, 2, 1, 92, 142, 0, 0, 10, 32, 149, 235, 0, 0, 101, 19,
       202, 92, 18, 40, 152, 129, 9, 0, 228, 48, 117, 7, 126, 178, 31, 2,
       1, 0, 54, 6 >>

TradingStatusMessageCapture ==
    << 40, 1, 16, 1, 94, 140, 0, 0, 18, 49, 128, 173, 125, 49, 48, 48,
       48, 51, 71, 99, 32, 32, 81, 48, 32, 32, 18, 49, 128, 173, 125, 49,
       48, 48, 48, 51, 71, 106, 32, 32, 81, 48, 32, 32, 18, 49, 128, 173,
       125, 49, 48, 48, 48, 51, 71, 102, 32, 32, 81, 48, 32, 32, 18, 49,
       128, 173, 125, 49, 48, 48, 48, 51, 71, 111, 32, 32, 81, 48, 32, 32,
       18, 49, 128, 173, 125, 49, 48, 48, 48, 51, 71, 108, 32, 32, 81, 48,
       32, 32, 18, 49, 128, 173, 125, 49, 48, 48, 48, 51, 71, 101, 32, 32,
       81, 48, 32, 32, 18, 49, 128, 173, 125, 49, 48, 48, 48, 51, 72, 90,
       32, 32, 81, 48, 32, 32, 18, 49, 128, 173, 125, 49, 48, 48, 48, 51,
       72, 70, 32, 32, 81, 48, 32, 32, 18, 49, 128, 173, 125, 49, 48, 48,
       48, 51, 72, 121, 32, 32, 81, 48, 32, 32, 18, 49, 128, 173, 125, 49,
       48, 48, 48, 51, 76, 84, 32, 32, 81, 48, 32, 32, 18, 49, 128, 173,
       125, 49, 48, 48, 48, 50, 103, 48, 32, 32, 81, 48, 32, 32, 18, 49,
       128, 173, 125, 49, 48, 48, 48, 50, 108, 50, 32, 32, 81, 48, 32, 32,
       18, 49, 128, 173, 125, 49, 48, 48, 48, 50, 113, 103, 32, 32, 81, 48,
       32, 32, 18, 49, 128, 173, 125, 49, 48, 48, 48, 50, 118, 106, 32, 32,
       81, 48, 32, 32, 18, 49, 128, 173, 125, 49, 48, 48, 48, 51, 49, 121,
       32, 32, 81, 48, 32, 32, 18, 49, 128, 173, 125, 49, 48, 48, 48, 51,
       55, 57, 32, 32, 81, 48, 32, 32 >>

Captures == { AddOrderShortMessageCapture, DeleteOrderMessageCapture, FuturesInstrumentDefinitionMessageCapture, HeartbeatCapture, ModifyOrderShortMessageCapture, TimeMessageCapture, TradingStatusMessageCapture }

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
