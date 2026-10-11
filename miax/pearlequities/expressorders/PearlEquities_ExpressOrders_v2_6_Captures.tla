------------- MODULE PearlEquities_ExpressOrders_v2_6_Captures -------------
(***************************************************************************)
(* Recorded Miami International Holdings Express Orders v2.6 packets, as   *)
(* the bytes they were captured as. Each one decodes, consumes the whole   *)
(* packet, and encodes back to exactly the bytes it was read from.         *)
(***************************************************************************)
EXTENDS PearlEquities_ExpressOrders_v2_6

CancelOrderRequestCapture ==
    << 69, 0, 85, 67, 79, 0, 0, 0, 0, 0, 0, 0, 0, 81, 83, 83,
       75, 49, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 53, 51, 56, 52, 55, 48, 57, 54, 50, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 2, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0 >>

CancelOrderResponseCapture ==
    << 91, 0, 115, 28, 0, 0, 0, 0, 0, 0, 0, 1, 67, 82, 89, 29,
       94, 116, 140, 233, 239, 23, 81, 83, 83, 75, 49, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 53, 51,
       56, 52, 55, 48, 57, 54, 50, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 2, 0, 0, 2, 81, 0, 0, 0, 192, 126, 83, 2, 0, 0,
       0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 >>

CancelReduceSizeOrderNotificationCapture ==
    << 83, 0, 115, 29, 0, 0, 0, 0, 0, 0, 0, 1, 88, 78, 89, 29,
       94, 116, 140, 233, 239, 23, 81, 83, 83, 75, 53, 51, 56, 52, 55, 48,
       57, 54, 50, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0,
       0, 2, 81, 0, 0, 0, 192, 126, 83, 2, 0, 0, 0, 0, 85, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 32, 32, 0, 0, 0,
       0, 0, 0, 0, 0 >>

ClientHeartbeatCapture ==
    << 1, 0, 49 >>

LoginRequestCapture ==
    << 46, 0, 108, 49, 46, 48, 32, 32, 81, 83, 83, 75, 49, 48, 48, 49,
       69, 81, 84, 49, 32, 77, 69, 79, 50, 46, 54, 32, 32, 2, 1, 1,
       0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0 >>

LoginResponseCapture ==
    << 22, 0, 114, 2, 32, 1, 24, 0, 0, 0, 0, 0, 0, 0, 32, 1,
       18, 0, 0, 0, 0, 0, 0, 0 >>

NewOrderNotificationCapture ==
    << 149, 0, 115, 26, 0, 0, 0, 0, 0, 0, 0, 1, 79, 49, 52, 18,
       150, 81, 1, 233, 239, 23, 81, 83, 83, 75, 81, 0, 0, 0, 192, 126,
       83, 2, 53, 51, 56, 52, 55, 48, 57, 54, 50, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 2, 0, 0, 2, 48, 5, 36, 11, 0, 0,
       0, 0, 8, 0, 0, 0, 8, 0, 82, 49, 78, 0, 32, 2, 0, 0,
       0, 0, 0, 0, 0, 0, 65, 66, 69, 67, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 66, 69, 67, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 66,
       69, 67, 0, 32, 65, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0 >>

NewOrderRequestMessageCapture ==
    << 132, 0, 85, 78, 49, 0, 0, 0, 0, 0, 0, 0, 0, 81, 83, 83,
       75, 53, 51, 56, 52, 55, 49, 49, 55, 52, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 2, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0,
       0, 8, 0, 0, 0, 8, 100, 73, 50, 78, 0, 32, 2, 0, 0, 0,
       0, 0, 0, 0, 0, 65, 66, 69, 67, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 66, 69, 67, 0, 2, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 66, 69,
       67, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0 >>

OrderPriceUpdateNotificationCapture ==
    << 50, 0, 115, 27, 0, 0, 0, 0, 0, 0, 0, 1, 80, 85, 52, 18,
       150, 81, 1, 233, 239, 23, 2, 0, 0, 2, 81, 0, 0, 0, 192, 126,
       83, 2, 48, 5, 36, 11, 0, 0, 0, 0, 78, 0, 0, 0, 0, 0,
       0, 0, 0, 0 >>

ServerHeartbeatCapture ==
    << 1, 0, 48 >>

SymbolUpdateCapture ==
    << 71, 0, 115, 2, 0, 0, 0, 0, 0, 0, 0, 1, 83, 85, 80, 151,
       66, 225, 59, 220, 239, 23, 1, 0, 0, 2, 65, 65, 76, 32, 32, 32,
       32, 32, 32, 32, 32, 0, 78, 0, 100, 0, 0, 0, 48, 54, 58, 48,
       48, 58, 48, 48, 50, 51, 58, 48, 48, 58, 48, 48, 81, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0 >>

SystemStateNotificationCapture ==
    << 38, 0, 115, 1, 0, 0, 0, 0, 0, 0, 0, 1, 83, 78, 68, 239,
       57, 68, 59, 220, 239, 23, 77, 69, 79, 50, 46, 54, 32, 32, 1, 83,
       0, 0, 0, 0, 0, 0, 0, 0 >>

Captures == { CancelOrderRequestCapture, CancelOrderResponseCapture, CancelReduceSizeOrderNotificationCapture, ClientHeartbeatCapture, LoginRequestCapture, LoginResponseCapture, NewOrderNotificationCapture, NewOrderRequestMessageCapture, OrderPriceUpdateNotificationCapture, ServerHeartbeatCapture, SymbolUpdateCapture, SystemStateNotificationCapture }

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
