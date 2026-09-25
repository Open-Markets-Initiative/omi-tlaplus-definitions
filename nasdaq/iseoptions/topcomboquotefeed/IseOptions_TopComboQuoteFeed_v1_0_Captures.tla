------------ MODULE IseOptions_TopComboQuoteFeed_v1_0_Captures -------------
(***************************************************************************)
(* Recorded National Association of Securities Dealers Automated           *)
(* Quotations (Nasdaq) Ise Top Combo Quote Feed v1.0 packets, as the bytes *)
(* they were captured as. Each one decodes, consumes the whole packet, and *)
(* encodes back to exactly the bytes it was read from.                     *)
(***************************************************************************)
EXTENDS IseOptions_TopComboQuoteFeed_v1_0

ComplexStrategyDirectoryMessageCapture ==
    << 48, 48, 48, 48, 48, 56, 51, 54, 55, 73, 0, 0, 0, 0, 0, 4,
       225, 38, 0, 1, 0, 83, 82, 46, 28, 20, 35, 187, 157, 0, 32, 11,
       152, 86, 1, 65, 77, 90, 78, 32, 32, 32, 32, 32, 32, 32, 32, 32,
       2, 0, 0, 190, 7, 65, 77, 90, 78, 32, 32, 0, 19, 1, 4, 0,
       0, 0, 35, 189, 80, 31, 0, 67, 66, 0, 0, 0, 1, 0, 0, 190,
       9, 65, 77, 90, 78, 32, 32, 1, 19, 1, 4, 0, 0, 0, 35, 204,
       54, 209, 128, 67, 83, 0, 0, 0, 1 >>

ComplexStrategyTickerMessageCapture ==
    << 48, 48, 48, 48, 48, 56, 51, 54, 55, 73, 0, 0, 0, 0, 0, 4,
       232, 220, 0, 1, 0, 52, 116, 46, 74, 169, 33, 123, 6, 0, 31, 239,
       220, 0, 0, 0, 0, 7, 39, 14, 0, 0, 0, 0, 1, 0, 0, 0,
       8, 0, 0, 0, 0, 7, 54, 80, 64, 0, 0, 0, 0, 7, 39, 14,
       0, 0, 0, 0, 0, 7, 54, 80, 64, 76 >>

HeartbeatCapture ==
    << 48, 48, 48, 48, 48, 56, 51, 54, 55, 73, 0, 0, 0, 0, 0, 5,
       217, 33, 0, 0 >>

StrategyBestAskUpdateCapture ==
    << 48, 48, 48, 48, 48, 56, 51, 54, 55, 73, 0, 0, 0, 0, 0, 4,
       198, 252, 0, 1, 0, 40, 69, 45, 155, 4, 22, 212, 2, 0, 32, 6,
       164, 32, 0, 0, 10, 40, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 >>

StrategyBestBidAndAskUpdateCapture ==
    << 48, 48, 48, 48, 48, 56, 51, 54, 55, 73, 0, 0, 0, 0, 0, 4,
       207, 181, 0, 1, 0, 68, 67, 45, 195, 36, 52, 99, 155, 0, 31, 235,
       0, 32, 0, 0, 97, 168, 0, 0, 0, 61, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 61, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0 >>

StrategyBestBidUpdateCapture ==
    << 48, 48, 48, 48, 48, 56, 51, 54, 55, 73, 0, 0, 0, 0, 0, 4,
       198, 247, 0, 1, 0, 40, 68, 45, 154, 249, 11, 235, 211, 0, 31, 145,
       36, 32, 0, 0, 53, 232, 0, 0, 0, 27, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 >>

StrategyOpenClosedMessageCapture ==
    << 48, 48, 48, 48, 48, 56, 51, 54, 55, 73, 0, 0, 0, 0, 0, 5,
       102, 14, 0, 1, 0, 12, 79, 48, 241, 193, 48, 223, 64, 0, 32, 34,
       152, 89 >>

StrategyTradingActionMessageCapture ==
    << 48, 48, 48, 48, 48, 56, 51, 54, 55, 73, 0, 0, 0, 0, 0, 5,
       102, 29, 0, 1, 0, 12, 72, 48, 241, 214, 186, 129, 116, 0, 32, 34,
       156, 84 >>

Captures == { ComplexStrategyDirectoryMessageCapture, ComplexStrategyTickerMessageCapture, HeartbeatCapture, StrategyBestAskUpdateCapture, StrategyBestBidAndAskUpdateCapture, StrategyBestBidUpdateCapture, StrategyOpenClosedMessageCapture, StrategyTradingActionMessageCapture }

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
