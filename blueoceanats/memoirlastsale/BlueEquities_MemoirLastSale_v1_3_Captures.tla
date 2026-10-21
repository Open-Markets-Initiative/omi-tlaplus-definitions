------------- MODULE BlueEquities_MemoirLastSale_v1_3_Captures -------------
(***************************************************************************)
(* Recorded Blue Ocean Technologies Member Order Information Record Last   *)
(* Sale v1.3 packets, as the bytes they were captured as. Each one         *)
(* decodes, consumes the whole packet, and encodes back to exactly the     *)
(* bytes it was read from.                                                 *)
(***************************************************************************)
EXTENDS BlueEquities_MemoirLastSale_v1_3

InstrumentDirectoryMessageCapture ==
    << 2, 18, 66, 79, 65, 84, 104, 143, 196, 130, 0, 0, 0, 0, 0, 0,
       17, 156, 0, 1, 0, 41, 0, 35, 1, 4, 1, 3, 24, 88, 91, 72,
       240, 72, 245, 53, 44, 66, 67, 80, 78, 74, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 39, 16 >>

SecurityTradingStatusMessageCapture ==
    << 2, 18, 66, 79, 65, 84, 104, 143, 196, 130, 0, 0, 0, 0, 0, 0,
       16, 185, 0, 1, 0, 18, 0, 12, 3, 4, 1, 3, 24, 88, 91, 72,
       240, 67, 166, 201, 52, 251, 72, 65 >>

TradeReportMessageCapture ==
    << 2, 18, 66, 79, 65, 84, 104, 143, 196, 130, 0, 0, 0, 0, 0, 0,
       91, 86, 0, 1, 0, 40, 0, 34, 10, 4, 1, 3, 24, 88, 98, 107,
       190, 198, 45, 29, 43, 82, 22, 0, 0, 0, 0, 0, 0, 1, 0, 0,
       0, 1, 0, 0, 0, 0, 2, 98, 90, 0, 64, 32, 84, 73 >>

TradingSessionStatusMessageCapture ==
    << 2, 18, 66, 79, 65, 84, 104, 143, 196, 130, 0, 0, 0, 0, 0, 0,
       91, 85, 0, 1, 0, 15, 0, 9, 5, 4, 1, 3, 24, 88, 96, 184,
       104, 63, 19, 12, 49 >>

Captures == { InstrumentDirectoryMessageCapture, SecurityTradingStatusMessageCapture, TradeReportMessageCapture, TradingSessionStatusMessageCapture }

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
