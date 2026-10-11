------------------- MODULE BoxOptions_SolaMulticast_v1_9 -------------------
(***************************************************************************)
(* Box Options Market Sola Multicast v1.9                                  *)
(*                                                                         *)
(* Generated from the binary model. A field is the bytes it occupies; an   *)
(* integer is read only where a rule depends on one - a length, a count, a *)
(* message type - which are the dependencies the parse rules run on.       *)
(*                                                                         *)
(* TLC checks that every record decodes back to what was encoded, that a   *)
(* dispatch selects the message its type names, and that a derived length  *)
(* or count is written from what it describes.                             *)
(*                                                                         *)
(* Note: TLC evaluates integers in 32 bits, so a field wider than that has *)
(* no range it can enumerate; every field is checked as its bytes, which   *)
(* is exact at any width.                                                  *)
(***************************************************************************)
EXTENDS Integers, Sequences

(***************************************************************************)
(* Wire primitives                                                         *)
(***************************************************************************)

Byte == 0 .. 255

(* An unsigned integer, least significant byte first. Read only where a rule *)
(* depends on the value: a length, a count, a message type. *)
RECURSIVE DecodeUIntLE(_)
DecodeUIntLE(bytes) ==
    IF bytes = << >>
    THEN 0
    ELSE Head(bytes) + 256 * DecodeUIntLE(Tail(bytes))

RECURSIVE EncodeUIntLE(_, _)
EncodeUIntLE(value, width) ==
    IF width = 0
    THEN << >>
    ELSE <<value % 256>> \o EncodeUIntLE(value \div 256, width - 1)

(* The same, most significant byte first, which is how a big endian protocol writes it *)
RECURSIVE DecodeUIntBE(_)
DecodeUIntBE(bytes) ==
    IF bytes = << >>
    THEN 0
    ELSE DecodeUIntBE(SubSeq(bytes, 1, Len(bytes) - 1)) * 256 + bytes[Len(bytes)]

RECURSIVE EncodeUIntBE(_, _)
EncodeUIntBE(value, width) ==
    IF width = 0
    THEN << >>
    ELSE EncodeUIntBE(value \div 256, width - 1) \o <<value % 256>>

(***************************************************************************)
(* A decoder yields the value it read and the bytes left, or fails         *)
(***************************************************************************)

Fail == [ok |-> FALSE]
Ok(value, rest) == [ok |-> TRUE, value |-> value, rest |-> rest]

(* The bytes a field of this width occupies, kept as they lie *)
ReadBytes(bytes, width) ==
    IF Len(bytes) < width
    THEN Fail
    ELSE Ok(SubSeq(bytes, 1, width), SubSeq(bytes, width + 1, Len(bytes)))

(* The integer a rule depends on, in the byte order the field states *)
ReadUIntLE(bytes, width) ==
    IF Len(bytes) < width
    THEN Fail
    ELSE Ok(DecodeUIntLE(SubSeq(bytes, 1, width)), SubSeq(bytes, width + 1, Len(bytes)))

ReadUIntBE(bytes, width) ==
    IF Len(bytes) < width
    THEN Fail
    ELSE Ok(DecodeUIntBE(SubSeq(bytes, 1, width)), SubSeq(bytes, width + 1, Len(bytes)))

(***************************************************************************)
(* The values a field is checked at: zero, the spaces a text field is      *)
(* padded with, and                                                        *)
(* every bit set, which is where an encoding goes wrong if it goes wrong   *)
(***************************************************************************)

Sample(width) ==
    { [i \in 1 .. width |-> 0],
      [i \in 1 .. width |-> 32],
      [i \in 1 .. width |-> 255] }

(* The bytes a field of no width of its own is checked at: none, one, and a short run *)
SampleBytes == { << >>, <<0>>, <<32, 255>> }

(* The lists a record is checked over: none, one, and a run of two. What a run has *)
(* to get right is reading one entry after another, which two of a kind already say. *)
SampleLists(entries) ==
    { << >> }
        \cup { <<one>> : one \in entries }
        \cup { <<one, one>> : one \in entries }

(***************************************************************************)
(* End Of Transmission Message: 7 bytes                                    *)
(***************************************************************************)

EndOfTransmissionMessage ==
    [ exchangeId : Sample(1),
      time       : Sample(6) ]

EncodeEndOfTransmissionMessage(message) ==
    message.exchangeId
        \o message.time

DecodeEndOfTransmissionMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET time == ReadBytes(exchangeId.rest, 6) IN IF ~time.ok THEN Fail ELSE
    Ok([ exchangeId |-> exchangeId.value,
         time       |-> time.value ], time.rest)

ZeroEndOfTransmissionMessage ==
    [ exchangeId |-> [i \in 1 .. 1 |-> 0],
      time       |-> [i \in 1 .. 6 |-> 0] ]

(* End Of Transmission Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfTransmissionMessage ==
    { ZeroEndOfTransmissionMessage }
        \cup { [ZeroEndOfTransmissionMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroEndOfTransmissionMessage EXCEPT !.time = one] : one \in Sample(6) }

(***************************************************************************)
(* Circuit Assurance Message: 6 bytes                                      *)
(***************************************************************************)

CircuitAssuranceMessage ==
    [ time : Sample(6) ]

EncodeCircuitAssuranceMessage(message) ==
    message.time

DecodeCircuitAssuranceMessage(bytes) ==
    LET time == ReadBytes(bytes, 6) IN IF ~time.ok THEN Fail ELSE
    Ok([ time |-> time.value ], time.rest)

ZeroCircuitAssuranceMessage ==
    [ time |-> [i \in 1 .. 6 |-> 0] ]

(* Circuit Assurance Message at zero, then each field in turn at the values it is checked at *)
CheckedCircuitAssuranceMessage ==
    { ZeroCircuitAssuranceMessage }
        \cup { [ZeroCircuitAssuranceMessage EXCEPT !.time = one] : one \in Sample(6) }

(***************************************************************************)
(* System Timestamp Message: 9 bytes                                       *)
(***************************************************************************)

SystemTimestampMessage ==
    [ tradingEngineTimestamp : Sample(9) ]

EncodeSystemTimestampMessage(message) ==
    message.tradingEngineTimestamp

DecodeSystemTimestampMessage(bytes) ==
    LET tradingEngineTimestamp == ReadBytes(bytes, 9) IN IF ~tradingEngineTimestamp.ok THEN Fail ELSE
    Ok([ tradingEngineTimestamp |-> tradingEngineTimestamp.value ], tradingEngineTimestamp.rest)

ZeroSystemTimestampMessage ==
    [ tradingEngineTimestamp |-> [i \in 1 .. 9 |-> 0] ]

(* System Timestamp Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemTimestampMessage ==
    { ZeroSystemTimestampMessage }
        \cup { [ZeroSystemTimestampMessage EXCEPT !.tradingEngineTimestamp = one] : one \in Sample(9) }

(***************************************************************************)
(* Instrument Description: 20 bytes                                        *)
(***************************************************************************)

InstrumentDescription ==
    [ rootSymbol                   : Sample(6),
      expiryMonthCode              : Sample(1),
      filler1                      : Sample(1),
      strikePrice                  : Sample(7),
      strikePriceFractionIndicator : Sample(1),
      expiryYear                   : Sample(2),
      expiryDay                    : Sample(2) ]

EncodeInstrumentDescription(message) ==
    message.rootSymbol
        \o message.expiryMonthCode
        \o message.filler1
        \o message.strikePrice
        \o message.strikePriceFractionIndicator
        \o message.expiryYear
        \o message.expiryDay

DecodeInstrumentDescription(bytes) ==
    LET rootSymbol == ReadBytes(bytes, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET expiryMonthCode == ReadBytes(rootSymbol.rest, 1) IN IF ~expiryMonthCode.ok THEN Fail ELSE
    LET filler1 == ReadBytes(expiryMonthCode.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(filler1.rest, 7) IN IF ~strikePrice.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePrice.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(strikePriceFractionIndicator.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ rootSymbol                   |-> rootSymbol.value,
         expiryMonthCode              |-> expiryMonthCode.value,
         filler1                      |-> filler1.value,
         strikePrice                  |-> strikePrice.value,
         strikePriceFractionIndicator |-> strikePriceFractionIndicator.value,
         expiryYear                   |-> expiryYear.value,
         expiryDay                    |-> expiryDay.value ], expiryDay.rest)

ZeroInstrumentDescription ==
    [ rootSymbol                   |-> [i \in 1 .. 6 |-> 0],
      expiryMonthCode              |-> [i \in 1 .. 1 |-> 0],
      filler1                      |-> [i \in 1 .. 1 |-> 0],
      strikePrice                  |-> [i \in 1 .. 7 |-> 0],
      strikePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      expiryYear                   |-> [i \in 1 .. 2 |-> 0],
      expiryDay                    |-> [i \in 1 .. 2 |-> 0] ]

(* Instrument Description at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentDescription ==
    { ZeroInstrumentDescription }
        \cup { [ZeroInstrumentDescription EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroInstrumentDescription EXCEPT !.expiryMonthCode = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDescription EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDescription EXCEPT !.strikePrice = one] : one \in Sample(7) }
        \cup { [ZeroInstrumentDescription EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDescription EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentDescription EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Option Trade Message: 65 bytes                                          *)
(***************************************************************************)

OptionTradeMessage ==
    [ exchangeId                  : Sample(1),
      instrumentDescription       : InstrumentDescription,
      volume                      : Sample(8),
      tradePrice                  : Sample(6),
      tradePriceFractionIndicator : Sample(1),
      netChangeSign               : Sample(1),
      netChange                   : Sample(6),
      netChangeFractionIndicator  : Sample(1),
      opraTradeMarker             : Sample(1),
      filler5                     : Sample(5),
      timestamp                   : Sample(6),
      filler8                     : Sample(8),
      priceIndicatorMarker        : Sample(1) ]

EncodeOptionTradeMessage(message) ==
    message.exchangeId
        \o EncodeInstrumentDescription(message.instrumentDescription)
        \o message.volume
        \o message.tradePrice
        \o message.tradePriceFractionIndicator
        \o message.netChangeSign
        \o message.netChange
        \o message.netChangeFractionIndicator
        \o message.opraTradeMarker
        \o message.filler5
        \o message.timestamp
        \o message.filler8
        \o message.priceIndicatorMarker

DecodeOptionTradeMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET instrumentDescription == DecodeInstrumentDescription(exchangeId.rest) IN IF ~instrumentDescription.ok THEN Fail ELSE
    LET volume == ReadBytes(instrumentDescription.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(volume.rest, 6) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradePriceFractionIndicator == ReadBytes(tradePrice.rest, 1) IN IF ~tradePriceFractionIndicator.ok THEN Fail ELSE
    LET netChangeSign == ReadBytes(tradePriceFractionIndicator.rest, 1) IN IF ~netChangeSign.ok THEN Fail ELSE
    LET netChange == ReadBytes(netChangeSign.rest, 6) IN IF ~netChange.ok THEN Fail ELSE
    LET netChangeFractionIndicator == ReadBytes(netChange.rest, 1) IN IF ~netChangeFractionIndicator.ok THEN Fail ELSE
    LET opraTradeMarker == ReadBytes(netChangeFractionIndicator.rest, 1) IN IF ~opraTradeMarker.ok THEN Fail ELSE
    LET filler5 == ReadBytes(opraTradeMarker.rest, 5) IN IF ~filler5.ok THEN Fail ELSE
    LET timestamp == ReadBytes(filler5.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET filler8 == ReadBytes(timestamp.rest, 8) IN IF ~filler8.ok THEN Fail ELSE
    LET priceIndicatorMarker == ReadBytes(filler8.rest, 1) IN IF ~priceIndicatorMarker.ok THEN Fail ELSE
    Ok([ exchangeId                  |-> exchangeId.value,
         instrumentDescription       |-> instrumentDescription.value,
         volume                      |-> volume.value,
         tradePrice                  |-> tradePrice.value,
         tradePriceFractionIndicator |-> tradePriceFractionIndicator.value,
         netChangeSign               |-> netChangeSign.value,
         netChange                   |-> netChange.value,
         netChangeFractionIndicator  |-> netChangeFractionIndicator.value,
         opraTradeMarker             |-> opraTradeMarker.value,
         filler5                     |-> filler5.value,
         timestamp                   |-> timestamp.value,
         filler8                     |-> filler8.value,
         priceIndicatorMarker        |-> priceIndicatorMarker.value ], priceIndicatorMarker.rest)

ZeroOptionTradeMessage ==
    [ exchangeId                  |-> [i \in 1 .. 1 |-> 0],
      instrumentDescription       |-> ZeroInstrumentDescription,
      volume                      |-> [i \in 1 .. 8 |-> 0],
      tradePrice                  |-> [i \in 1 .. 6 |-> 0],
      tradePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      netChangeSign               |-> [i \in 1 .. 1 |-> 0],
      netChange                   |-> [i \in 1 .. 6 |-> 0],
      netChangeFractionIndicator  |-> [i \in 1 .. 1 |-> 0],
      opraTradeMarker             |-> [i \in 1 .. 1 |-> 0],
      filler5                     |-> [i \in 1 .. 5 |-> 0],
      timestamp                   |-> [i \in 1 .. 6 |-> 0],
      filler8                     |-> [i \in 1 .. 8 |-> 0],
      priceIndicatorMarker        |-> [i \in 1 .. 1 |-> 0] ]

(* Option Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionTradeMessage ==
    { ZeroOptionTradeMessage }
        \cup { [ZeroOptionTradeMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.instrumentDescription = one] : one \in CheckedInstrumentDescription }
        \cup { [ZeroOptionTradeMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.tradePrice = one] : one \in Sample(6) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.tradePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.netChangeSign = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.netChange = one] : one \in Sample(6) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.netChangeFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.opraTradeMarker = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.filler5 = one] : one \in Sample(5) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.filler8 = one] : one \in Sample(8) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.priceIndicatorMarker = one] : one \in Sample(1) }

(***************************************************************************)
(* Strategy Trade Message: 68 bytes                                        *)
(***************************************************************************)

StrategyTradeMessage ==
    [ exchangeId                   : Sample(1),
      complexOrderInstrumentSymbol : Sample(30),
      volume                       : Sample(8),
      tradePriceSign               : Sample(1),
      tradePrice                   : Sample(6),
      tradePriceFractionIndicator  : Sample(1),
      netChangeSign                : Sample(1),
      netChange                    : Sample(6),
      netChangeFractionIndicator   : Sample(1),
      opraTradeMarker              : Sample(1),
      filler5                      : Sample(5),
      timestamp                    : Sample(6),
      priceIndicatorMarker         : Sample(1) ]

EncodeStrategyTradeMessage(message) ==
    message.exchangeId
        \o message.complexOrderInstrumentSymbol
        \o message.volume
        \o message.tradePriceSign
        \o message.tradePrice
        \o message.tradePriceFractionIndicator
        \o message.netChangeSign
        \o message.netChange
        \o message.netChangeFractionIndicator
        \o message.opraTradeMarker
        \o message.filler5
        \o message.timestamp
        \o message.priceIndicatorMarker

DecodeStrategyTradeMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET complexOrderInstrumentSymbol == ReadBytes(exchangeId.rest, 30) IN IF ~complexOrderInstrumentSymbol.ok THEN Fail ELSE
    LET volume == ReadBytes(complexOrderInstrumentSymbol.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET tradePriceSign == ReadBytes(volume.rest, 1) IN IF ~tradePriceSign.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(tradePriceSign.rest, 6) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradePriceFractionIndicator == ReadBytes(tradePrice.rest, 1) IN IF ~tradePriceFractionIndicator.ok THEN Fail ELSE
    LET netChangeSign == ReadBytes(tradePriceFractionIndicator.rest, 1) IN IF ~netChangeSign.ok THEN Fail ELSE
    LET netChange == ReadBytes(netChangeSign.rest, 6) IN IF ~netChange.ok THEN Fail ELSE
    LET netChangeFractionIndicator == ReadBytes(netChange.rest, 1) IN IF ~netChangeFractionIndicator.ok THEN Fail ELSE
    LET opraTradeMarker == ReadBytes(netChangeFractionIndicator.rest, 1) IN IF ~opraTradeMarker.ok THEN Fail ELSE
    LET filler5 == ReadBytes(opraTradeMarker.rest, 5) IN IF ~filler5.ok THEN Fail ELSE
    LET timestamp == ReadBytes(filler5.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET priceIndicatorMarker == ReadBytes(timestamp.rest, 1) IN IF ~priceIndicatorMarker.ok THEN Fail ELSE
    Ok([ exchangeId                   |-> exchangeId.value,
         complexOrderInstrumentSymbol |-> complexOrderInstrumentSymbol.value,
         volume                       |-> volume.value,
         tradePriceSign               |-> tradePriceSign.value,
         tradePrice                   |-> tradePrice.value,
         tradePriceFractionIndicator  |-> tradePriceFractionIndicator.value,
         netChangeSign                |-> netChangeSign.value,
         netChange                    |-> netChange.value,
         netChangeFractionIndicator   |-> netChangeFractionIndicator.value,
         opraTradeMarker              |-> opraTradeMarker.value,
         filler5                      |-> filler5.value,
         timestamp                    |-> timestamp.value,
         priceIndicatorMarker         |-> priceIndicatorMarker.value ], priceIndicatorMarker.rest)

ZeroStrategyTradeMessage ==
    [ exchangeId                   |-> [i \in 1 .. 1 |-> 0],
      complexOrderInstrumentSymbol |-> [i \in 1 .. 30 |-> 0],
      volume                       |-> [i \in 1 .. 8 |-> 0],
      tradePriceSign               |-> [i \in 1 .. 1 |-> 0],
      tradePrice                   |-> [i \in 1 .. 6 |-> 0],
      tradePriceFractionIndicator  |-> [i \in 1 .. 1 |-> 0],
      netChangeSign                |-> [i \in 1 .. 1 |-> 0],
      netChange                    |-> [i \in 1 .. 6 |-> 0],
      netChangeFractionIndicator   |-> [i \in 1 .. 1 |-> 0],
      opraTradeMarker              |-> [i \in 1 .. 1 |-> 0],
      filler5                      |-> [i \in 1 .. 5 |-> 0],
      timestamp                    |-> [i \in 1 .. 6 |-> 0],
      priceIndicatorMarker         |-> [i \in 1 .. 1 |-> 0] ]

(* Strategy Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedStrategyTradeMessage ==
    { ZeroStrategyTradeMessage }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.complexOrderInstrumentSymbol = one] : one \in Sample(30) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.tradePriceSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.tradePrice = one] : one \in Sample(6) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.tradePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.netChangeSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.netChange = one] : one \in Sample(6) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.netChangeFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.opraTradeMarker = one] : one \in Sample(1) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.filler5 = one] : one \in Sample(5) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.priceIndicatorMarker = one] : one \in Sample(1) }

(***************************************************************************)
(* Instrument Description: 20 bytes                                        *)
(***************************************************************************)

InstrumentDescription2 ==
    [ rootSymbol                   : Sample(6),
      expiryMonthCode              : Sample(1),
      filler1                      : Sample(1),
      strikePrice                  : Sample(7),
      strikePriceFractionIndicator : Sample(1),
      expiryYear                   : Sample(2),
      expiryDay                    : Sample(2) ]

EncodeInstrumentDescription2(message) ==
    message.rootSymbol
        \o message.expiryMonthCode
        \o message.filler1
        \o message.strikePrice
        \o message.strikePriceFractionIndicator
        \o message.expiryYear
        \o message.expiryDay

DecodeInstrumentDescription2(bytes) ==
    LET rootSymbol == ReadBytes(bytes, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET expiryMonthCode == ReadBytes(rootSymbol.rest, 1) IN IF ~expiryMonthCode.ok THEN Fail ELSE
    LET filler1 == ReadBytes(expiryMonthCode.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(filler1.rest, 7) IN IF ~strikePrice.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePrice.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(strikePriceFractionIndicator.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ rootSymbol                   |-> rootSymbol.value,
         expiryMonthCode              |-> expiryMonthCode.value,
         filler1                      |-> filler1.value,
         strikePrice                  |-> strikePrice.value,
         strikePriceFractionIndicator |-> strikePriceFractionIndicator.value,
         expiryYear                   |-> expiryYear.value,
         expiryDay                    |-> expiryDay.value ], expiryDay.rest)

ZeroInstrumentDescription2 ==
    [ rootSymbol                   |-> [i \in 1 .. 6 |-> 0],
      expiryMonthCode              |-> [i \in 1 .. 1 |-> 0],
      filler1                      |-> [i \in 1 .. 1 |-> 0],
      strikePrice                  |-> [i \in 1 .. 7 |-> 0],
      strikePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      expiryYear                   |-> [i \in 1 .. 2 |-> 0],
      expiryDay                    |-> [i \in 1 .. 2 |-> 0] ]

(* Instrument Description at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentDescription2 ==
    { ZeroInstrumentDescription2 }
        \cup { [ZeroInstrumentDescription2 EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroInstrumentDescription2 EXCEPT !.expiryMonthCode = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDescription2 EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDescription2 EXCEPT !.strikePrice = one] : one \in Sample(7) }
        \cup { [ZeroInstrumentDescription2 EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDescription2 EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentDescription2 EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Option Request For Quote Message: 29 bytes                              *)
(***************************************************************************)

OptionRequestForQuoteMessage ==
    [ exchangeId            : Sample(1),
      instrumentDescription : InstrumentDescription2,
      requestedSize         : Sample(8) ]

EncodeOptionRequestForQuoteMessage(message) ==
    message.exchangeId
        \o EncodeInstrumentDescription2(message.instrumentDescription)
        \o message.requestedSize

DecodeOptionRequestForQuoteMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET instrumentDescription == DecodeInstrumentDescription2(exchangeId.rest) IN IF ~instrumentDescription.ok THEN Fail ELSE
    LET requestedSize == ReadBytes(instrumentDescription.rest, 8) IN IF ~requestedSize.ok THEN Fail ELSE
    Ok([ exchangeId            |-> exchangeId.value,
         instrumentDescription |-> instrumentDescription.value,
         requestedSize         |-> requestedSize.value ], requestedSize.rest)

ZeroOptionRequestForQuoteMessage ==
    [ exchangeId            |-> [i \in 1 .. 1 |-> 0],
      instrumentDescription |-> ZeroInstrumentDescription2,
      requestedSize         |-> [i \in 1 .. 8 |-> 0] ]

(* Option Request For Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionRequestForQuoteMessage ==
    { ZeroOptionRequestForQuoteMessage }
        \cup { [ZeroOptionRequestForQuoteMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroOptionRequestForQuoteMessage EXCEPT !.instrumentDescription = one] : one \in CheckedInstrumentDescription2 }
        \cup { [ZeroOptionRequestForQuoteMessage EXCEPT !.requestedSize = one] : one \in Sample(8) }

(***************************************************************************)
(* Instrument Description: 20 bytes                                        *)
(***************************************************************************)

InstrumentDescription3 ==
    [ rootSymbol                   : Sample(6),
      expiryMonthCode              : Sample(1),
      filler1                      : Sample(1),
      strikePrice                  : Sample(7),
      strikePriceFractionIndicator : Sample(1),
      expiryYear                   : Sample(2),
      expiryDay                    : Sample(2) ]

EncodeInstrumentDescription3(message) ==
    message.rootSymbol
        \o message.expiryMonthCode
        \o message.filler1
        \o message.strikePrice
        \o message.strikePriceFractionIndicator
        \o message.expiryYear
        \o message.expiryDay

DecodeInstrumentDescription3(bytes) ==
    LET rootSymbol == ReadBytes(bytes, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET expiryMonthCode == ReadBytes(rootSymbol.rest, 1) IN IF ~expiryMonthCode.ok THEN Fail ELSE
    LET filler1 == ReadBytes(expiryMonthCode.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(filler1.rest, 7) IN IF ~strikePrice.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePrice.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(strikePriceFractionIndicator.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ rootSymbol                   |-> rootSymbol.value,
         expiryMonthCode              |-> expiryMonthCode.value,
         filler1                      |-> filler1.value,
         strikePrice                  |-> strikePrice.value,
         strikePriceFractionIndicator |-> strikePriceFractionIndicator.value,
         expiryYear                   |-> expiryYear.value,
         expiryDay                    |-> expiryDay.value ], expiryDay.rest)

ZeroInstrumentDescription3 ==
    [ rootSymbol                   |-> [i \in 1 .. 6 |-> 0],
      expiryMonthCode              |-> [i \in 1 .. 1 |-> 0],
      filler1                      |-> [i \in 1 .. 1 |-> 0],
      strikePrice                  |-> [i \in 1 .. 7 |-> 0],
      strikePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      expiryYear                   |-> [i \in 1 .. 2 |-> 0],
      expiryDay                    |-> [i \in 1 .. 2 |-> 0] ]

(* Instrument Description at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentDescription3 ==
    { ZeroInstrumentDescription3 }
        \cup { [ZeroInstrumentDescription3 EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroInstrumentDescription3 EXCEPT !.expiryMonthCode = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDescription3 EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDescription3 EXCEPT !.strikePrice = one] : one \in Sample(7) }
        \cup { [ZeroInstrumentDescription3 EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDescription3 EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentDescription3 EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Option Quote Message: 57 bytes                                          *)
(***************************************************************************)

OptionQuoteMessage ==
    [ exchangeId                : Sample(1),
      instrumentDescription     : InstrumentDescription3,
      bidPrice                  : Sample(6),
      bidPriceFractionIndicator : Sample(1),
      bidSize                   : Sample(5),
      askPrice                  : Sample(6),
      askPriceFractionIndicator : Sample(1),
      askSize                   : Sample(5),
      filler1                   : Sample(1),
      instrumentStatusMarker    : Sample(1),
      publicCustomerBidSize     : Sample(5),
      publicCustomerAskSize     : Sample(5) ]

EncodeOptionQuoteMessage(message) ==
    message.exchangeId
        \o EncodeInstrumentDescription3(message.instrumentDescription)
        \o message.bidPrice
        \o message.bidPriceFractionIndicator
        \o message.bidSize
        \o message.askPrice
        \o message.askPriceFractionIndicator
        \o message.askSize
        \o message.filler1
        \o message.instrumentStatusMarker
        \o message.publicCustomerBidSize
        \o message.publicCustomerAskSize

DecodeOptionQuoteMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET instrumentDescription == DecodeInstrumentDescription3(exchangeId.rest) IN IF ~instrumentDescription.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(instrumentDescription.rest, 6) IN IF ~bidPrice.ok THEN Fail ELSE
    LET bidPriceFractionIndicator == ReadBytes(bidPrice.rest, 1) IN IF ~bidPriceFractionIndicator.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPriceFractionIndicator.rest, 5) IN IF ~bidSize.ok THEN Fail ELSE
    LET askPrice == ReadBytes(bidSize.rest, 6) IN IF ~askPrice.ok THEN Fail ELSE
    LET askPriceFractionIndicator == ReadBytes(askPrice.rest, 1) IN IF ~askPriceFractionIndicator.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPriceFractionIndicator.rest, 5) IN IF ~askSize.ok THEN Fail ELSE
    LET filler1 == ReadBytes(askSize.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET instrumentStatusMarker == ReadBytes(filler1.rest, 1) IN IF ~instrumentStatusMarker.ok THEN Fail ELSE
    LET publicCustomerBidSize == ReadBytes(instrumentStatusMarker.rest, 5) IN IF ~publicCustomerBidSize.ok THEN Fail ELSE
    LET publicCustomerAskSize == ReadBytes(publicCustomerBidSize.rest, 5) IN IF ~publicCustomerAskSize.ok THEN Fail ELSE
    Ok([ exchangeId                |-> exchangeId.value,
         instrumentDescription     |-> instrumentDescription.value,
         bidPrice                  |-> bidPrice.value,
         bidPriceFractionIndicator |-> bidPriceFractionIndicator.value,
         bidSize                   |-> bidSize.value,
         askPrice                  |-> askPrice.value,
         askPriceFractionIndicator |-> askPriceFractionIndicator.value,
         askSize                   |-> askSize.value,
         filler1                   |-> filler1.value,
         instrumentStatusMarker    |-> instrumentStatusMarker.value,
         publicCustomerBidSize     |-> publicCustomerBidSize.value,
         publicCustomerAskSize     |-> publicCustomerAskSize.value ], publicCustomerAskSize.rest)

ZeroOptionQuoteMessage ==
    [ exchangeId                |-> [i \in 1 .. 1 |-> 0],
      instrumentDescription     |-> ZeroInstrumentDescription3,
      bidPrice                  |-> [i \in 1 .. 6 |-> 0],
      bidPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      bidSize                   |-> [i \in 1 .. 5 |-> 0],
      askPrice                  |-> [i \in 1 .. 6 |-> 0],
      askPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      askSize                   |-> [i \in 1 .. 5 |-> 0],
      filler1                   |-> [i \in 1 .. 1 |-> 0],
      instrumentStatusMarker    |-> [i \in 1 .. 1 |-> 0],
      publicCustomerBidSize     |-> [i \in 1 .. 5 |-> 0],
      publicCustomerAskSize     |-> [i \in 1 .. 5 |-> 0] ]

(* Option Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionQuoteMessage ==
    { ZeroOptionQuoteMessage }
        \cup { [ZeroOptionQuoteMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroOptionQuoteMessage EXCEPT !.instrumentDescription = one] : one \in CheckedInstrumentDescription3 }
        \cup { [ZeroOptionQuoteMessage EXCEPT !.bidPrice = one] : one \in Sample(6) }
        \cup { [ZeroOptionQuoteMessage EXCEPT !.bidPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionQuoteMessage EXCEPT !.bidSize = one] : one \in Sample(5) }
        \cup { [ZeroOptionQuoteMessage EXCEPT !.askPrice = one] : one \in Sample(6) }
        \cup { [ZeroOptionQuoteMessage EXCEPT !.askPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionQuoteMessage EXCEPT !.askSize = one] : one \in Sample(5) }
        \cup { [ZeroOptionQuoteMessage EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroOptionQuoteMessage EXCEPT !.instrumentStatusMarker = one] : one \in Sample(1) }
        \cup { [ZeroOptionQuoteMessage EXCEPT !.publicCustomerBidSize = one] : one \in Sample(5) }
        \cup { [ZeroOptionQuoteMessage EXCEPT !.publicCustomerAskSize = one] : one \in Sample(5) }

(***************************************************************************)
(* Complex Order Quote Message: 68 bytes                                   *)
(***************************************************************************)

ComplexOrderQuoteMessage ==
    [ exchangeId                   : Sample(1),
      complexOrderInstrumentSymbol : Sample(30),
      bidPriceSign                 : Sample(1),
      bidPrice                     : Sample(6),
      bidPriceFractionIndicator    : Sample(1),
      bidSize                      : Sample(5),
      askPriceSign                 : Sample(1),
      askPrice                     : Sample(6),
      askPriceFractionIndicator    : Sample(1),
      askSize                      : Sample(5),
      instrumentStatusMarker       : Sample(1),
      publicCustomerBidSize        : Sample(5),
      publicCustomerAskSize        : Sample(5) ]

EncodeComplexOrderQuoteMessage(message) ==
    message.exchangeId
        \o message.complexOrderInstrumentSymbol
        \o message.bidPriceSign
        \o message.bidPrice
        \o message.bidPriceFractionIndicator
        \o message.bidSize
        \o message.askPriceSign
        \o message.askPrice
        \o message.askPriceFractionIndicator
        \o message.askSize
        \o message.instrumentStatusMarker
        \o message.publicCustomerBidSize
        \o message.publicCustomerAskSize

DecodeComplexOrderQuoteMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET complexOrderInstrumentSymbol == ReadBytes(exchangeId.rest, 30) IN IF ~complexOrderInstrumentSymbol.ok THEN Fail ELSE
    LET bidPriceSign == ReadBytes(complexOrderInstrumentSymbol.rest, 1) IN IF ~bidPriceSign.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(bidPriceSign.rest, 6) IN IF ~bidPrice.ok THEN Fail ELSE
    LET bidPriceFractionIndicator == ReadBytes(bidPrice.rest, 1) IN IF ~bidPriceFractionIndicator.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPriceFractionIndicator.rest, 5) IN IF ~bidSize.ok THEN Fail ELSE
    LET askPriceSign == ReadBytes(bidSize.rest, 1) IN IF ~askPriceSign.ok THEN Fail ELSE
    LET askPrice == ReadBytes(askPriceSign.rest, 6) IN IF ~askPrice.ok THEN Fail ELSE
    LET askPriceFractionIndicator == ReadBytes(askPrice.rest, 1) IN IF ~askPriceFractionIndicator.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPriceFractionIndicator.rest, 5) IN IF ~askSize.ok THEN Fail ELSE
    LET instrumentStatusMarker == ReadBytes(askSize.rest, 1) IN IF ~instrumentStatusMarker.ok THEN Fail ELSE
    LET publicCustomerBidSize == ReadBytes(instrumentStatusMarker.rest, 5) IN IF ~publicCustomerBidSize.ok THEN Fail ELSE
    LET publicCustomerAskSize == ReadBytes(publicCustomerBidSize.rest, 5) IN IF ~publicCustomerAskSize.ok THEN Fail ELSE
    Ok([ exchangeId                   |-> exchangeId.value,
         complexOrderInstrumentSymbol |-> complexOrderInstrumentSymbol.value,
         bidPriceSign                 |-> bidPriceSign.value,
         bidPrice                     |-> bidPrice.value,
         bidPriceFractionIndicator    |-> bidPriceFractionIndicator.value,
         bidSize                      |-> bidSize.value,
         askPriceSign                 |-> askPriceSign.value,
         askPrice                     |-> askPrice.value,
         askPriceFractionIndicator    |-> askPriceFractionIndicator.value,
         askSize                      |-> askSize.value,
         instrumentStatusMarker       |-> instrumentStatusMarker.value,
         publicCustomerBidSize        |-> publicCustomerBidSize.value,
         publicCustomerAskSize        |-> publicCustomerAskSize.value ], publicCustomerAskSize.rest)

ZeroComplexOrderQuoteMessage ==
    [ exchangeId                   |-> [i \in 1 .. 1 |-> 0],
      complexOrderInstrumentSymbol |-> [i \in 1 .. 30 |-> 0],
      bidPriceSign                 |-> [i \in 1 .. 1 |-> 0],
      bidPrice                     |-> [i \in 1 .. 6 |-> 0],
      bidPriceFractionIndicator    |-> [i \in 1 .. 1 |-> 0],
      bidSize                      |-> [i \in 1 .. 5 |-> 0],
      askPriceSign                 |-> [i \in 1 .. 1 |-> 0],
      askPrice                     |-> [i \in 1 .. 6 |-> 0],
      askPriceFractionIndicator    |-> [i \in 1 .. 1 |-> 0],
      askSize                      |-> [i \in 1 .. 5 |-> 0],
      instrumentStatusMarker       |-> [i \in 1 .. 1 |-> 0],
      publicCustomerBidSize        |-> [i \in 1 .. 5 |-> 0],
      publicCustomerAskSize        |-> [i \in 1 .. 5 |-> 0] ]

(* Complex Order Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexOrderQuoteMessage ==
    { ZeroComplexOrderQuoteMessage }
        \cup { [ZeroComplexOrderQuoteMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderQuoteMessage EXCEPT !.complexOrderInstrumentSymbol = one] : one \in Sample(30) }
        \cup { [ZeroComplexOrderQuoteMessage EXCEPT !.bidPriceSign = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderQuoteMessage EXCEPT !.bidPrice = one] : one \in Sample(6) }
        \cup { [ZeroComplexOrderQuoteMessage EXCEPT !.bidPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderQuoteMessage EXCEPT !.bidSize = one] : one \in Sample(5) }
        \cup { [ZeroComplexOrderQuoteMessage EXCEPT !.askPriceSign = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderQuoteMessage EXCEPT !.askPrice = one] : one \in Sample(6) }
        \cup { [ZeroComplexOrderQuoteMessage EXCEPT !.askPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderQuoteMessage EXCEPT !.askSize = one] : one \in Sample(5) }
        \cup { [ZeroComplexOrderQuoteMessage EXCEPT !.instrumentStatusMarker = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderQuoteMessage EXCEPT !.publicCustomerBidSize = one] : one \in Sample(5) }
        \cup { [ZeroComplexOrderQuoteMessage EXCEPT !.publicCustomerAskSize = one] : one \in Sample(5) }

(***************************************************************************)
(* Group Opening Time Message: 14 bytes                                    *)
(***************************************************************************)

GroupOpeningTimeMessage ==
    [ exchangeId    : Sample(1),
      rootSymbol    : Sample(6),
      groupStatus   : Sample(1),
      scheduledTime : Sample(6) ]

EncodeGroupOpeningTimeMessage(message) ==
    message.exchangeId
        \o message.rootSymbol
        \o message.groupStatus
        \o message.scheduledTime

DecodeGroupOpeningTimeMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET rootSymbol == ReadBytes(exchangeId.rest, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET groupStatus == ReadBytes(rootSymbol.rest, 1) IN IF ~groupStatus.ok THEN Fail ELSE
    LET scheduledTime == ReadBytes(groupStatus.rest, 6) IN IF ~scheduledTime.ok THEN Fail ELSE
    Ok([ exchangeId    |-> exchangeId.value,
         rootSymbol    |-> rootSymbol.value,
         groupStatus   |-> groupStatus.value,
         scheduledTime |-> scheduledTime.value ], scheduledTime.rest)

ZeroGroupOpeningTimeMessage ==
    [ exchangeId    |-> [i \in 1 .. 1 |-> 0],
      rootSymbol    |-> [i \in 1 .. 6 |-> 0],
      groupStatus   |-> [i \in 1 .. 1 |-> 0],
      scheduledTime |-> [i \in 1 .. 6 |-> 0] ]

(* Group Opening Time Message at zero, then each field in turn at the values it is checked at *)
CheckedGroupOpeningTimeMessage ==
    { ZeroGroupOpeningTimeMessage }
        \cup { [ZeroGroupOpeningTimeMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroGroupOpeningTimeMessage EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroGroupOpeningTimeMessage EXCEPT !.groupStatus = one] : one \in Sample(1) }
        \cup { [ZeroGroupOpeningTimeMessage EXCEPT !.scheduledTime = one] : one \in Sample(6) }

(***************************************************************************)
(* Group Status Message: 8 bytes                                           *)
(***************************************************************************)

GroupStatusMessage ==
    [ exchangeId  : Sample(1),
      rootSymbol  : Sample(6),
      groupStatus : Sample(1) ]

EncodeGroupStatusMessage(message) ==
    message.exchangeId
        \o message.rootSymbol
        \o message.groupStatus

DecodeGroupStatusMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET rootSymbol == ReadBytes(exchangeId.rest, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET groupStatus == ReadBytes(rootSymbol.rest, 1) IN IF ~groupStatus.ok THEN Fail ELSE
    Ok([ exchangeId  |-> exchangeId.value,
         rootSymbol  |-> rootSymbol.value,
         groupStatus |-> groupStatus.value ], groupStatus.rest)

ZeroGroupStatusMessage ==
    [ exchangeId  |-> [i \in 1 .. 1 |-> 0],
      rootSymbol  |-> [i \in 1 .. 6 |-> 0],
      groupStatus |-> [i \in 1 .. 1 |-> 0] ]

(* Group Status Message at zero, then each field in turn at the values it is checked at *)
CheckedGroupStatusMessage ==
    { ZeroGroupStatusMessage }
        \cup { [ZeroGroupStatusMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroGroupStatusMessage EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroGroupStatusMessage EXCEPT !.groupStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Strategies Group Status Message: 4 bytes                                *)
(***************************************************************************)

StrategiesGroupStatusMessage ==
    [ exchangeId                       : Sample(1),
      groupOfTheComplexOrderInstrument : Sample(2),
      groupStatus                      : Sample(1) ]

EncodeStrategiesGroupStatusMessage(message) ==
    message.exchangeId
        \o message.groupOfTheComplexOrderInstrument
        \o message.groupStatus

DecodeStrategiesGroupStatusMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET groupOfTheComplexOrderInstrument == ReadBytes(exchangeId.rest, 2) IN IF ~groupOfTheComplexOrderInstrument.ok THEN Fail ELSE
    LET groupStatus == ReadBytes(groupOfTheComplexOrderInstrument.rest, 1) IN IF ~groupStatus.ok THEN Fail ELSE
    Ok([ exchangeId                       |-> exchangeId.value,
         groupOfTheComplexOrderInstrument |-> groupOfTheComplexOrderInstrument.value,
         groupStatus                      |-> groupStatus.value ], groupStatus.rest)

ZeroStrategiesGroupStatusMessage ==
    [ exchangeId                       |-> [i \in 1 .. 1 |-> 0],
      groupOfTheComplexOrderInstrument |-> [i \in 1 .. 2 |-> 0],
      groupStatus                      |-> [i \in 1 .. 1 |-> 0] ]

(* Strategies Group Status Message at zero, then each field in turn at the values it is checked at *)
CheckedStrategiesGroupStatusMessage ==
    { ZeroStrategiesGroupStatusMessage }
        \cup { [ZeroStrategiesGroupStatusMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroStrategiesGroupStatusMessage EXCEPT !.groupOfTheComplexOrderInstrument = one] : one \in Sample(2) }
        \cup { [ZeroStrategiesGroupStatusMessage EXCEPT !.groupStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Instrument Description: 20 bytes                                        *)
(***************************************************************************)

InstrumentDescription4 ==
    [ rootSymbol                   : Sample(6),
      expiryMonthCode              : Sample(1),
      filler1                      : Sample(1),
      strikePrice                  : Sample(7),
      strikePriceFractionIndicator : Sample(1),
      expiryYear                   : Sample(2),
      expiryDay                    : Sample(2) ]

EncodeInstrumentDescription4(message) ==
    message.rootSymbol
        \o message.expiryMonthCode
        \o message.filler1
        \o message.strikePrice
        \o message.strikePriceFractionIndicator
        \o message.expiryYear
        \o message.expiryDay

DecodeInstrumentDescription4(bytes) ==
    LET rootSymbol == ReadBytes(bytes, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET expiryMonthCode == ReadBytes(rootSymbol.rest, 1) IN IF ~expiryMonthCode.ok THEN Fail ELSE
    LET filler1 == ReadBytes(expiryMonthCode.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(filler1.rest, 7) IN IF ~strikePrice.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePrice.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(strikePriceFractionIndicator.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ rootSymbol                   |-> rootSymbol.value,
         expiryMonthCode              |-> expiryMonthCode.value,
         filler1                      |-> filler1.value,
         strikePrice                  |-> strikePrice.value,
         strikePriceFractionIndicator |-> strikePriceFractionIndicator.value,
         expiryYear                   |-> expiryYear.value,
         expiryDay                    |-> expiryDay.value ], expiryDay.rest)

ZeroInstrumentDescription4 ==
    [ rootSymbol                   |-> [i \in 1 .. 6 |-> 0],
      expiryMonthCode              |-> [i \in 1 .. 1 |-> 0],
      filler1                      |-> [i \in 1 .. 1 |-> 0],
      strikePrice                  |-> [i \in 1 .. 7 |-> 0],
      strikePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      expiryYear                   |-> [i \in 1 .. 2 |-> 0],
      expiryDay                    |-> [i \in 1 .. 2 |-> 0] ]

(* Instrument Description at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentDescription4 ==
    { ZeroInstrumentDescription4 }
        \cup { [ZeroInstrumentDescription4 EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroInstrumentDescription4 EXCEPT !.expiryMonthCode = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDescription4 EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDescription4 EXCEPT !.strikePrice = one] : one \in Sample(7) }
        \cup { [ZeroInstrumentDescription4 EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDescription4 EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentDescription4 EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Market Depth Level: 29 bytes                                            *)
(***************************************************************************)

MarketDepthLevel ==
    [ levelOfMarketDepth        : Sample(1),
      bidPrice                  : Sample(6),
      bidPriceFractionIndicator : Sample(1),
      bidSize                   : Sample(5),
      numberOfBidOrders         : Sample(2),
      askPrice                  : Sample(6),
      askPriceFractionIndicator : Sample(1),
      askSize                   : Sample(5),
      numberOfAskOrders         : Sample(2) ]

EncodeMarketDepthLevel(message) ==
    message.levelOfMarketDepth
        \o message.bidPrice
        \o message.bidPriceFractionIndicator
        \o message.bidSize
        \o message.numberOfBidOrders
        \o message.askPrice
        \o message.askPriceFractionIndicator
        \o message.askSize
        \o message.numberOfAskOrders

DecodeMarketDepthLevel(bytes) ==
    LET levelOfMarketDepth == ReadBytes(bytes, 1) IN IF ~levelOfMarketDepth.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(levelOfMarketDepth.rest, 6) IN IF ~bidPrice.ok THEN Fail ELSE
    LET bidPriceFractionIndicator == ReadBytes(bidPrice.rest, 1) IN IF ~bidPriceFractionIndicator.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPriceFractionIndicator.rest, 5) IN IF ~bidSize.ok THEN Fail ELSE
    LET numberOfBidOrders == ReadBytes(bidSize.rest, 2) IN IF ~numberOfBidOrders.ok THEN Fail ELSE
    LET askPrice == ReadBytes(numberOfBidOrders.rest, 6) IN IF ~askPrice.ok THEN Fail ELSE
    LET askPriceFractionIndicator == ReadBytes(askPrice.rest, 1) IN IF ~askPriceFractionIndicator.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPriceFractionIndicator.rest, 5) IN IF ~askSize.ok THEN Fail ELSE
    LET numberOfAskOrders == ReadBytes(askSize.rest, 2) IN IF ~numberOfAskOrders.ok THEN Fail ELSE
    Ok([ levelOfMarketDepth        |-> levelOfMarketDepth.value,
         bidPrice                  |-> bidPrice.value,
         bidPriceFractionIndicator |-> bidPriceFractionIndicator.value,
         bidSize                   |-> bidSize.value,
         numberOfBidOrders         |-> numberOfBidOrders.value,
         askPrice                  |-> askPrice.value,
         askPriceFractionIndicator |-> askPriceFractionIndicator.value,
         askSize                   |-> askSize.value,
         numberOfAskOrders         |-> numberOfAskOrders.value ], numberOfAskOrders.rest)

ZeroMarketDepthLevel ==
    [ levelOfMarketDepth        |-> [i \in 1 .. 1 |-> 0],
      bidPrice                  |-> [i \in 1 .. 6 |-> 0],
      bidPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      bidSize                   |-> [i \in 1 .. 5 |-> 0],
      numberOfBidOrders         |-> [i \in 1 .. 2 |-> 0],
      askPrice                  |-> [i \in 1 .. 6 |-> 0],
      askPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      askSize                   |-> [i \in 1 .. 5 |-> 0],
      numberOfAskOrders         |-> [i \in 1 .. 2 |-> 0] ]

(* Market Depth Level at zero, then each field in turn at the values it is checked at *)
CheckedMarketDepthLevel ==
    { ZeroMarketDepthLevel }
        \cup { [ZeroMarketDepthLevel EXCEPT !.levelOfMarketDepth = one] : one \in Sample(1) }
        \cup { [ZeroMarketDepthLevel EXCEPT !.bidPrice = one] : one \in Sample(6) }
        \cup { [ZeroMarketDepthLevel EXCEPT !.bidPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMarketDepthLevel EXCEPT !.bidSize = one] : one \in Sample(5) }
        \cup { [ZeroMarketDepthLevel EXCEPT !.numberOfBidOrders = one] : one \in Sample(2) }
        \cup { [ZeroMarketDepthLevel EXCEPT !.askPrice = one] : one \in Sample(6) }
        \cup { [ZeroMarketDepthLevel EXCEPT !.askPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMarketDepthLevel EXCEPT !.askSize = one] : one \in Sample(5) }
        \cup { [ZeroMarketDepthLevel EXCEPT !.numberOfAskOrders = one] : one \in Sample(2) }

(* A run of Market Depth Level, written one after another *)
RECURSIVE EncodeMarketDepthLevelList(_)
EncodeMarketDepthLevelList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMarketDepthLevel(Head(messages)) \o EncodeMarketDepthLevelList(Tail(messages))

(* As many Market Depth Level as the field that counts them says *)
RECURSIVE ReadMarketDepthLevelList(_, _)
ReadMarketDepthLevelList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMarketDepthLevel(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMarketDepthLevelList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Market Depth Level of each kind, for the lists that carry them *)
OneMarketDepthLevel == { ZeroMarketDepthLevel }

(***************************************************************************)
(* Option Market Depth Message                                             *)
(***************************************************************************)

OptionMarketDepthMessage ==
    [ exchangeId             : Sample(1),
      instrumentDescription  : InstrumentDescription4,
      instrumentStatusMarker : Sample(1),
      marketDepthLevel       : SampleLists(OneMarketDepthLevel) ]

EncodeOptionMarketDepthMessage(message) ==
    message.exchangeId
        \o EncodeInstrumentDescription4(message.instrumentDescription)
        \o message.instrumentStatusMarker
        \o EncodeUIntBE(Len(message.marketDepthLevel), 1)
        \o EncodeMarketDepthLevelList(message.marketDepthLevel)

DecodeOptionMarketDepthMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET instrumentDescription == DecodeInstrumentDescription4(exchangeId.rest) IN IF ~instrumentDescription.ok THEN Fail ELSE
    LET instrumentStatusMarker == ReadBytes(instrumentDescription.rest, 1) IN IF ~instrumentStatusMarker.ok THEN Fail ELSE
    LET numberOfLevels == ReadUIntBE(instrumentStatusMarker.rest, 1) IN IF ~numberOfLevels.ok THEN Fail ELSE
    LET marketDepthLevel == ReadMarketDepthLevelList(numberOfLevels.rest, numberOfLevels.value) IN IF ~marketDepthLevel.ok THEN Fail ELSE
    Ok([ exchangeId             |-> exchangeId.value,
         instrumentDescription  |-> instrumentDescription.value,
         instrumentStatusMarker |-> instrumentStatusMarker.value,
         marketDepthLevel       |-> marketDepthLevel.value ], marketDepthLevel.rest)

ZeroOptionMarketDepthMessage ==
    [ exchangeId             |-> [i \in 1 .. 1 |-> 0],
      instrumentDescription  |-> ZeroInstrumentDescription4,
      instrumentStatusMarker |-> [i \in 1 .. 1 |-> 0],
      marketDepthLevel       |-> << >> ]

(* Option Market Depth Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionMarketDepthMessage ==
    { ZeroOptionMarketDepthMessage }
        \cup { [ZeroOptionMarketDepthMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroOptionMarketDepthMessage EXCEPT !.instrumentDescription = one] : one \in CheckedInstrumentDescription4 }
        \cup { [ZeroOptionMarketDepthMessage EXCEPT !.instrumentStatusMarker = one] : one \in Sample(1) }
        \cup { [ZeroOptionMarketDepthMessage EXCEPT !.marketDepthLevel = one] : one \in SampleLists(OneMarketDepthLevel) }

(***************************************************************************)
(* Complex Market Depth Level: 31 bytes                                    *)
(***************************************************************************)

ComplexMarketDepthLevel ==
    [ levelOfMarketDepth        : Sample(1),
      bidPriceSign              : Sample(1),
      bidPrice                  : Sample(6),
      bidPriceFractionIndicator : Sample(1),
      bidSize                   : Sample(5),
      numberOfBidOrders         : Sample(2),
      askPriceSign              : Sample(1),
      askPrice                  : Sample(6),
      askPriceFractionIndicator : Sample(1),
      askSize                   : Sample(5),
      numberOfAskOrders         : Sample(2) ]

EncodeComplexMarketDepthLevel(message) ==
    message.levelOfMarketDepth
        \o message.bidPriceSign
        \o message.bidPrice
        \o message.bidPriceFractionIndicator
        \o message.bidSize
        \o message.numberOfBidOrders
        \o message.askPriceSign
        \o message.askPrice
        \o message.askPriceFractionIndicator
        \o message.askSize
        \o message.numberOfAskOrders

DecodeComplexMarketDepthLevel(bytes) ==
    LET levelOfMarketDepth == ReadBytes(bytes, 1) IN IF ~levelOfMarketDepth.ok THEN Fail ELSE
    LET bidPriceSign == ReadBytes(levelOfMarketDepth.rest, 1) IN IF ~bidPriceSign.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(bidPriceSign.rest, 6) IN IF ~bidPrice.ok THEN Fail ELSE
    LET bidPriceFractionIndicator == ReadBytes(bidPrice.rest, 1) IN IF ~bidPriceFractionIndicator.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPriceFractionIndicator.rest, 5) IN IF ~bidSize.ok THEN Fail ELSE
    LET numberOfBidOrders == ReadBytes(bidSize.rest, 2) IN IF ~numberOfBidOrders.ok THEN Fail ELSE
    LET askPriceSign == ReadBytes(numberOfBidOrders.rest, 1) IN IF ~askPriceSign.ok THEN Fail ELSE
    LET askPrice == ReadBytes(askPriceSign.rest, 6) IN IF ~askPrice.ok THEN Fail ELSE
    LET askPriceFractionIndicator == ReadBytes(askPrice.rest, 1) IN IF ~askPriceFractionIndicator.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPriceFractionIndicator.rest, 5) IN IF ~askSize.ok THEN Fail ELSE
    LET numberOfAskOrders == ReadBytes(askSize.rest, 2) IN IF ~numberOfAskOrders.ok THEN Fail ELSE
    Ok([ levelOfMarketDepth        |-> levelOfMarketDepth.value,
         bidPriceSign              |-> bidPriceSign.value,
         bidPrice                  |-> bidPrice.value,
         bidPriceFractionIndicator |-> bidPriceFractionIndicator.value,
         bidSize                   |-> bidSize.value,
         numberOfBidOrders         |-> numberOfBidOrders.value,
         askPriceSign              |-> askPriceSign.value,
         askPrice                  |-> askPrice.value,
         askPriceFractionIndicator |-> askPriceFractionIndicator.value,
         askSize                   |-> askSize.value,
         numberOfAskOrders         |-> numberOfAskOrders.value ], numberOfAskOrders.rest)

ZeroComplexMarketDepthLevel ==
    [ levelOfMarketDepth        |-> [i \in 1 .. 1 |-> 0],
      bidPriceSign              |-> [i \in 1 .. 1 |-> 0],
      bidPrice                  |-> [i \in 1 .. 6 |-> 0],
      bidPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      bidSize                   |-> [i \in 1 .. 5 |-> 0],
      numberOfBidOrders         |-> [i \in 1 .. 2 |-> 0],
      askPriceSign              |-> [i \in 1 .. 1 |-> 0],
      askPrice                  |-> [i \in 1 .. 6 |-> 0],
      askPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      askSize                   |-> [i \in 1 .. 5 |-> 0],
      numberOfAskOrders         |-> [i \in 1 .. 2 |-> 0] ]

(* Complex Market Depth Level at zero, then each field in turn at the values it is checked at *)
CheckedComplexMarketDepthLevel ==
    { ZeroComplexMarketDepthLevel }
        \cup { [ZeroComplexMarketDepthLevel EXCEPT !.levelOfMarketDepth = one] : one \in Sample(1) }
        \cup { [ZeroComplexMarketDepthLevel EXCEPT !.bidPriceSign = one] : one \in Sample(1) }
        \cup { [ZeroComplexMarketDepthLevel EXCEPT !.bidPrice = one] : one \in Sample(6) }
        \cup { [ZeroComplexMarketDepthLevel EXCEPT !.bidPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroComplexMarketDepthLevel EXCEPT !.bidSize = one] : one \in Sample(5) }
        \cup { [ZeroComplexMarketDepthLevel EXCEPT !.numberOfBidOrders = one] : one \in Sample(2) }
        \cup { [ZeroComplexMarketDepthLevel EXCEPT !.askPriceSign = one] : one \in Sample(1) }
        \cup { [ZeroComplexMarketDepthLevel EXCEPT !.askPrice = one] : one \in Sample(6) }
        \cup { [ZeroComplexMarketDepthLevel EXCEPT !.askPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroComplexMarketDepthLevel EXCEPT !.askSize = one] : one \in Sample(5) }
        \cup { [ZeroComplexMarketDepthLevel EXCEPT !.numberOfAskOrders = one] : one \in Sample(2) }

(* A run of Complex Market Depth Level, written one after another *)
RECURSIVE EncodeComplexMarketDepthLevelList(_)
EncodeComplexMarketDepthLevelList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeComplexMarketDepthLevel(Head(messages)) \o EncodeComplexMarketDepthLevelList(Tail(messages))

(* As many Complex Market Depth Level as the field that counts them says *)
RECURSIVE ReadComplexMarketDepthLevelList(_, _)
ReadComplexMarketDepthLevelList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeComplexMarketDepthLevel(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadComplexMarketDepthLevelList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Complex Market Depth Level of each kind, for the lists that carry them *)
OneComplexMarketDepthLevel == { ZeroComplexMarketDepthLevel }

(***************************************************************************)
(* Complex Order Market Depth Message                                      *)
(***************************************************************************)

ComplexOrderMarketDepthMessage ==
    [ exchangeId                   : Sample(1),
      complexOrderInstrumentSymbol : Sample(30),
      instrumentStatusMarker       : Sample(1),
      complexMarketDepthLevel      : SampleLists(OneComplexMarketDepthLevel) ]

EncodeComplexOrderMarketDepthMessage(message) ==
    message.exchangeId
        \o message.complexOrderInstrumentSymbol
        \o message.instrumentStatusMarker
        \o EncodeUIntBE(Len(message.complexMarketDepthLevel), 1)
        \o EncodeComplexMarketDepthLevelList(message.complexMarketDepthLevel)

DecodeComplexOrderMarketDepthMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET complexOrderInstrumentSymbol == ReadBytes(exchangeId.rest, 30) IN IF ~complexOrderInstrumentSymbol.ok THEN Fail ELSE
    LET instrumentStatusMarker == ReadBytes(complexOrderInstrumentSymbol.rest, 1) IN IF ~instrumentStatusMarker.ok THEN Fail ELSE
    LET numberOfLevels == ReadUIntBE(instrumentStatusMarker.rest, 1) IN IF ~numberOfLevels.ok THEN Fail ELSE
    LET complexMarketDepthLevel == ReadComplexMarketDepthLevelList(numberOfLevels.rest, numberOfLevels.value) IN IF ~complexMarketDepthLevel.ok THEN Fail ELSE
    Ok([ exchangeId                   |-> exchangeId.value,
         complexOrderInstrumentSymbol |-> complexOrderInstrumentSymbol.value,
         instrumentStatusMarker       |-> instrumentStatusMarker.value,
         complexMarketDepthLevel      |-> complexMarketDepthLevel.value ], complexMarketDepthLevel.rest)

ZeroComplexOrderMarketDepthMessage ==
    [ exchangeId                   |-> [i \in 1 .. 1 |-> 0],
      complexOrderInstrumentSymbol |-> [i \in 1 .. 30 |-> 0],
      instrumentStatusMarker       |-> [i \in 1 .. 1 |-> 0],
      complexMarketDepthLevel      |-> << >> ]

(* Complex Order Market Depth Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexOrderMarketDepthMessage ==
    { ZeroComplexOrderMarketDepthMessage }
        \cup { [ZeroComplexOrderMarketDepthMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderMarketDepthMessage EXCEPT !.complexOrderInstrumentSymbol = one] : one \in Sample(30) }
        \cup { [ZeroComplexOrderMarketDepthMessage EXCEPT !.instrumentStatusMarker = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderMarketDepthMessage EXCEPT !.complexMarketDepthLevel = one] : one \in SampleLists(OneComplexMarketDepthLevel) }

(***************************************************************************)
(* Instrument Description: 20 bytes                                        *)
(***************************************************************************)

InstrumentDescription5 ==
    [ rootSymbol                   : Sample(6),
      expiryMonthCode              : Sample(1),
      filler1                      : Sample(1),
      strikePrice                  : Sample(7),
      strikePriceFractionIndicator : Sample(1),
      expiryYear                   : Sample(2),
      expiryDay                    : Sample(2) ]

EncodeInstrumentDescription5(message) ==
    message.rootSymbol
        \o message.expiryMonthCode
        \o message.filler1
        \o message.strikePrice
        \o message.strikePriceFractionIndicator
        \o message.expiryYear
        \o message.expiryDay

DecodeInstrumentDescription5(bytes) ==
    LET rootSymbol == ReadBytes(bytes, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET expiryMonthCode == ReadBytes(rootSymbol.rest, 1) IN IF ~expiryMonthCode.ok THEN Fail ELSE
    LET filler1 == ReadBytes(expiryMonthCode.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(filler1.rest, 7) IN IF ~strikePrice.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePrice.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(strikePriceFractionIndicator.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ rootSymbol                   |-> rootSymbol.value,
         expiryMonthCode              |-> expiryMonthCode.value,
         filler1                      |-> filler1.value,
         strikePrice                  |-> strikePrice.value,
         strikePriceFractionIndicator |-> strikePriceFractionIndicator.value,
         expiryYear                   |-> expiryYear.value,
         expiryDay                    |-> expiryDay.value ], expiryDay.rest)

ZeroInstrumentDescription5 ==
    [ rootSymbol                   |-> [i \in 1 .. 6 |-> 0],
      expiryMonthCode              |-> [i \in 1 .. 1 |-> 0],
      filler1                      |-> [i \in 1 .. 1 |-> 0],
      strikePrice                  |-> [i \in 1 .. 7 |-> 0],
      strikePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      expiryYear                   |-> [i \in 1 .. 2 |-> 0],
      expiryDay                    |-> [i \in 1 .. 2 |-> 0] ]

(* Instrument Description at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentDescription5 ==
    { ZeroInstrumentDescription5 }
        \cup { [ZeroInstrumentDescription5 EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroInstrumentDescription5 EXCEPT !.expiryMonthCode = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDescription5 EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDescription5 EXCEPT !.strikePrice = one] : one \in Sample(7) }
        \cup { [ZeroInstrumentDescription5 EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDescription5 EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentDescription5 EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Option Trade Cancellation Message: 57 bytes                             *)
(***************************************************************************)

OptionTradeCancellationMessage ==
    [ exchangeId                  : Sample(1),
      instrumentDescription       : InstrumentDescription5,
      volume                      : Sample(8),
      tradePrice                  : Sample(6),
      tradePriceFractionIndicator : Sample(1),
      opraTradeMarker             : Sample(1),
      filler5                     : Sample(5),
      timestamp                   : Sample(6),
      filler8                     : Sample(8),
      priceIndicatorMarker        : Sample(1) ]

EncodeOptionTradeCancellationMessage(message) ==
    message.exchangeId
        \o EncodeInstrumentDescription5(message.instrumentDescription)
        \o message.volume
        \o message.tradePrice
        \o message.tradePriceFractionIndicator
        \o message.opraTradeMarker
        \o message.filler5
        \o message.timestamp
        \o message.filler8
        \o message.priceIndicatorMarker

DecodeOptionTradeCancellationMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET instrumentDescription == DecodeInstrumentDescription5(exchangeId.rest) IN IF ~instrumentDescription.ok THEN Fail ELSE
    LET volume == ReadBytes(instrumentDescription.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(volume.rest, 6) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradePriceFractionIndicator == ReadBytes(tradePrice.rest, 1) IN IF ~tradePriceFractionIndicator.ok THEN Fail ELSE
    LET opraTradeMarker == ReadBytes(tradePriceFractionIndicator.rest, 1) IN IF ~opraTradeMarker.ok THEN Fail ELSE
    LET filler5 == ReadBytes(opraTradeMarker.rest, 5) IN IF ~filler5.ok THEN Fail ELSE
    LET timestamp == ReadBytes(filler5.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET filler8 == ReadBytes(timestamp.rest, 8) IN IF ~filler8.ok THEN Fail ELSE
    LET priceIndicatorMarker == ReadBytes(filler8.rest, 1) IN IF ~priceIndicatorMarker.ok THEN Fail ELSE
    Ok([ exchangeId                  |-> exchangeId.value,
         instrumentDescription       |-> instrumentDescription.value,
         volume                      |-> volume.value,
         tradePrice                  |-> tradePrice.value,
         tradePriceFractionIndicator |-> tradePriceFractionIndicator.value,
         opraTradeMarker             |-> opraTradeMarker.value,
         filler5                     |-> filler5.value,
         timestamp                   |-> timestamp.value,
         filler8                     |-> filler8.value,
         priceIndicatorMarker        |-> priceIndicatorMarker.value ], priceIndicatorMarker.rest)

ZeroOptionTradeCancellationMessage ==
    [ exchangeId                  |-> [i \in 1 .. 1 |-> 0],
      instrumentDescription       |-> ZeroInstrumentDescription5,
      volume                      |-> [i \in 1 .. 8 |-> 0],
      tradePrice                  |-> [i \in 1 .. 6 |-> 0],
      tradePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      opraTradeMarker             |-> [i \in 1 .. 1 |-> 0],
      filler5                     |-> [i \in 1 .. 5 |-> 0],
      timestamp                   |-> [i \in 1 .. 6 |-> 0],
      filler8                     |-> [i \in 1 .. 8 |-> 0],
      priceIndicatorMarker        |-> [i \in 1 .. 1 |-> 0] ]

(* Option Trade Cancellation Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionTradeCancellationMessage ==
    { ZeroOptionTradeCancellationMessage }
        \cup { [ZeroOptionTradeCancellationMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeCancellationMessage EXCEPT !.instrumentDescription = one] : one \in CheckedInstrumentDescription5 }
        \cup { [ZeroOptionTradeCancellationMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroOptionTradeCancellationMessage EXCEPT !.tradePrice = one] : one \in Sample(6) }
        \cup { [ZeroOptionTradeCancellationMessage EXCEPT !.tradePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeCancellationMessage EXCEPT !.opraTradeMarker = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeCancellationMessage EXCEPT !.filler5 = one] : one \in Sample(5) }
        \cup { [ZeroOptionTradeCancellationMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroOptionTradeCancellationMessage EXCEPT !.filler8 = one] : one \in Sample(8) }
        \cup { [ZeroOptionTradeCancellationMessage EXCEPT !.priceIndicatorMarker = one] : one \in Sample(1) }

(***************************************************************************)
(* Complex Order Trade Cancellation Message: 60 bytes                      *)
(***************************************************************************)

ComplexOrderTradeCancellationMessage ==
    [ exchangeId                   : Sample(1),
      complexOrderInstrumentSymbol : Sample(30),
      volume                       : Sample(8),
      tradePriceSign               : Sample(1),
      tradePrice                   : Sample(6),
      tradePriceFractionIndicator  : Sample(1),
      opraTradeMarker              : Sample(1),
      filler5                      : Sample(5),
      timestamp                    : Sample(6),
      priceIndicatorMarker         : Sample(1) ]

EncodeComplexOrderTradeCancellationMessage(message) ==
    message.exchangeId
        \o message.complexOrderInstrumentSymbol
        \o message.volume
        \o message.tradePriceSign
        \o message.tradePrice
        \o message.tradePriceFractionIndicator
        \o message.opraTradeMarker
        \o message.filler5
        \o message.timestamp
        \o message.priceIndicatorMarker

DecodeComplexOrderTradeCancellationMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET complexOrderInstrumentSymbol == ReadBytes(exchangeId.rest, 30) IN IF ~complexOrderInstrumentSymbol.ok THEN Fail ELSE
    LET volume == ReadBytes(complexOrderInstrumentSymbol.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET tradePriceSign == ReadBytes(volume.rest, 1) IN IF ~tradePriceSign.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(tradePriceSign.rest, 6) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradePriceFractionIndicator == ReadBytes(tradePrice.rest, 1) IN IF ~tradePriceFractionIndicator.ok THEN Fail ELSE
    LET opraTradeMarker == ReadBytes(tradePriceFractionIndicator.rest, 1) IN IF ~opraTradeMarker.ok THEN Fail ELSE
    LET filler5 == ReadBytes(opraTradeMarker.rest, 5) IN IF ~filler5.ok THEN Fail ELSE
    LET timestamp == ReadBytes(filler5.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET priceIndicatorMarker == ReadBytes(timestamp.rest, 1) IN IF ~priceIndicatorMarker.ok THEN Fail ELSE
    Ok([ exchangeId                   |-> exchangeId.value,
         complexOrderInstrumentSymbol |-> complexOrderInstrumentSymbol.value,
         volume                       |-> volume.value,
         tradePriceSign               |-> tradePriceSign.value,
         tradePrice                   |-> tradePrice.value,
         tradePriceFractionIndicator  |-> tradePriceFractionIndicator.value,
         opraTradeMarker              |-> opraTradeMarker.value,
         filler5                      |-> filler5.value,
         timestamp                    |-> timestamp.value,
         priceIndicatorMarker         |-> priceIndicatorMarker.value ], priceIndicatorMarker.rest)

ZeroComplexOrderTradeCancellationMessage ==
    [ exchangeId                   |-> [i \in 1 .. 1 |-> 0],
      complexOrderInstrumentSymbol |-> [i \in 1 .. 30 |-> 0],
      volume                       |-> [i \in 1 .. 8 |-> 0],
      tradePriceSign               |-> [i \in 1 .. 1 |-> 0],
      tradePrice                   |-> [i \in 1 .. 6 |-> 0],
      tradePriceFractionIndicator  |-> [i \in 1 .. 1 |-> 0],
      opraTradeMarker              |-> [i \in 1 .. 1 |-> 0],
      filler5                      |-> [i \in 1 .. 5 |-> 0],
      timestamp                    |-> [i \in 1 .. 6 |-> 0],
      priceIndicatorMarker         |-> [i \in 1 .. 1 |-> 0] ]

(* Complex Order Trade Cancellation Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexOrderTradeCancellationMessage ==
    { ZeroComplexOrderTradeCancellationMessage }
        \cup { [ZeroComplexOrderTradeCancellationMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderTradeCancellationMessage EXCEPT !.complexOrderInstrumentSymbol = one] : one \in Sample(30) }
        \cup { [ZeroComplexOrderTradeCancellationMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroComplexOrderTradeCancellationMessage EXCEPT !.tradePriceSign = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderTradeCancellationMessage EXCEPT !.tradePrice = one] : one \in Sample(6) }
        \cup { [ZeroComplexOrderTradeCancellationMessage EXCEPT !.tradePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderTradeCancellationMessage EXCEPT !.opraTradeMarker = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderTradeCancellationMessage EXCEPT !.filler5 = one] : one \in Sample(5) }
        \cup { [ZeroComplexOrderTradeCancellationMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroComplexOrderTradeCancellationMessage EXCEPT !.priceIndicatorMarker = one] : one \in Sample(1) }

(***************************************************************************)
(* Instrument Description: 20 bytes                                        *)
(***************************************************************************)

InstrumentDescription6 ==
    [ rootSymbol                   : Sample(6),
      expiryMonthCode              : Sample(1),
      filler1                      : Sample(1),
      strikePrice                  : Sample(7),
      strikePriceFractionIndicator : Sample(1),
      expiryYear                   : Sample(2),
      expiryDay                    : Sample(2) ]

EncodeInstrumentDescription6(message) ==
    message.rootSymbol
        \o message.expiryMonthCode
        \o message.filler1
        \o message.strikePrice
        \o message.strikePriceFractionIndicator
        \o message.expiryYear
        \o message.expiryDay

DecodeInstrumentDescription6(bytes) ==
    LET rootSymbol == ReadBytes(bytes, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET expiryMonthCode == ReadBytes(rootSymbol.rest, 1) IN IF ~expiryMonthCode.ok THEN Fail ELSE
    LET filler1 == ReadBytes(expiryMonthCode.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(filler1.rest, 7) IN IF ~strikePrice.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePrice.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(strikePriceFractionIndicator.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ rootSymbol                   |-> rootSymbol.value,
         expiryMonthCode              |-> expiryMonthCode.value,
         filler1                      |-> filler1.value,
         strikePrice                  |-> strikePrice.value,
         strikePriceFractionIndicator |-> strikePriceFractionIndicator.value,
         expiryYear                   |-> expiryYear.value,
         expiryDay                    |-> expiryDay.value ], expiryDay.rest)

ZeroInstrumentDescription6 ==
    [ rootSymbol                   |-> [i \in 1 .. 6 |-> 0],
      expiryMonthCode              |-> [i \in 1 .. 1 |-> 0],
      filler1                      |-> [i \in 1 .. 1 |-> 0],
      strikePrice                  |-> [i \in 1 .. 7 |-> 0],
      strikePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      expiryYear                   |-> [i \in 1 .. 2 |-> 0],
      expiryDay                    |-> [i \in 1 .. 2 |-> 0] ]

(* Instrument Description at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentDescription6 ==
    { ZeroInstrumentDescription6 }
        \cup { [ZeroInstrumentDescription6 EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroInstrumentDescription6 EXCEPT !.expiryMonthCode = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDescription6 EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDescription6 EXCEPT !.strikePrice = one] : one \in Sample(7) }
        \cup { [ZeroInstrumentDescription6 EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDescription6 EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentDescription6 EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Market Flow Indicator: 2 bytes                                          *)
(***************************************************************************)

MarketFlowIndicator ==
    [ typeOfInstrument : Sample(1),
      typeOfUnderlying : Sample(1) ]

EncodeMarketFlowIndicator(message) ==
    message.typeOfInstrument
        \o message.typeOfUnderlying

DecodeMarketFlowIndicator(bytes) ==
    LET typeOfInstrument == ReadBytes(bytes, 1) IN IF ~typeOfInstrument.ok THEN Fail ELSE
    LET typeOfUnderlying == ReadBytes(typeOfInstrument.rest, 1) IN IF ~typeOfUnderlying.ok THEN Fail ELSE
    Ok([ typeOfInstrument |-> typeOfInstrument.value,
         typeOfUnderlying |-> typeOfUnderlying.value ], typeOfUnderlying.rest)

ZeroMarketFlowIndicator ==
    [ typeOfInstrument |-> [i \in 1 .. 1 |-> 0],
      typeOfUnderlying |-> [i \in 1 .. 1 |-> 0] ]

(* Market Flow Indicator at zero, then each field in turn at the values it is checked at *)
CheckedMarketFlowIndicator ==
    { ZeroMarketFlowIndicator }
        \cup { [ZeroMarketFlowIndicator EXCEPT !.typeOfInstrument = one] : one \in Sample(1) }
        \cup { [ZeroMarketFlowIndicator EXCEPT !.typeOfUnderlying = one] : one \in Sample(1) }

(***************************************************************************)
(* Option Marker: 2 bytes                                                  *)
(***************************************************************************)

OptionMarker ==
    [ typeOfMarket  : Sample(1),
      typeOfOptions : Sample(1) ]

EncodeOptionMarker(message) ==
    message.typeOfMarket
        \o message.typeOfOptions

DecodeOptionMarker(bytes) ==
    LET typeOfMarket == ReadBytes(bytes, 1) IN IF ~typeOfMarket.ok THEN Fail ELSE
    LET typeOfOptions == ReadBytes(typeOfMarket.rest, 1) IN IF ~typeOfOptions.ok THEN Fail ELSE
    Ok([ typeOfMarket  |-> typeOfMarket.value,
         typeOfOptions |-> typeOfOptions.value ], typeOfOptions.rest)

ZeroOptionMarker ==
    [ typeOfMarket  |-> [i \in 1 .. 1 |-> 0],
      typeOfOptions |-> [i \in 1 .. 1 |-> 0] ]

(* Option Marker at zero, then each field in turn at the values it is checked at *)
CheckedOptionMarker ==
    { ZeroOptionMarker }
        \cup { [ZeroOptionMarker EXCEPT !.typeOfMarket = one] : one \in Sample(1) }
        \cup { [ZeroOptionMarker EXCEPT !.typeOfOptions = one] : one \in Sample(1) }

(***************************************************************************)
(* Option Instrument Keys Message: 108 bytes                               *)
(***************************************************************************)

OptionInstrumentKeysMessage ==
    [ exchangeId                             : Sample(1),
      instrumentDescription                  : InstrumentDescription6,
      strikePriceCurrency                    : Sample(3),
      maximumNumberOfContractsPerOrder       : Sample(6),
      minimumNumberOfContractsPerOrder       : Sample(6),
      maximumThresholdPrice                  : Sample(6),
      maximumThresholdPriceFractionIndicator : Sample(1),
      minimumThresholdPrice                  : Sample(6),
      minimumThresholdPriceFractionIndicator : Sample(1),
      tickIncrement                          : Sample(6),
      tickIncrementFractionIndicator         : Sample(1),
      optionType                             : Sample(1),
      marketFlowIndicator                    : MarketFlowIndicator,
      groupInstrument                        : Sample(2),
      instrument                             : Sample(4),
      instrumentExternalCode                 : Sample(30),
      optionMarker                           : OptionMarker,
      underlyingSymbolRoot                   : Sample(10) ]

EncodeOptionInstrumentKeysMessage(message) ==
    message.exchangeId
        \o EncodeInstrumentDescription6(message.instrumentDescription)
        \o message.strikePriceCurrency
        \o message.maximumNumberOfContractsPerOrder
        \o message.minimumNumberOfContractsPerOrder
        \o message.maximumThresholdPrice
        \o message.maximumThresholdPriceFractionIndicator
        \o message.minimumThresholdPrice
        \o message.minimumThresholdPriceFractionIndicator
        \o message.tickIncrement
        \o message.tickIncrementFractionIndicator
        \o message.optionType
        \o EncodeMarketFlowIndicator(message.marketFlowIndicator)
        \o message.groupInstrument
        \o message.instrument
        \o message.instrumentExternalCode
        \o EncodeOptionMarker(message.optionMarker)
        \o message.underlyingSymbolRoot

DecodeOptionInstrumentKeysMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET instrumentDescription == DecodeInstrumentDescription6(exchangeId.rest) IN IF ~instrumentDescription.ok THEN Fail ELSE
    LET strikePriceCurrency == ReadBytes(instrumentDescription.rest, 3) IN IF ~strikePriceCurrency.ok THEN Fail ELSE
    LET maximumNumberOfContractsPerOrder == ReadBytes(strikePriceCurrency.rest, 6) IN IF ~maximumNumberOfContractsPerOrder.ok THEN Fail ELSE
    LET minimumNumberOfContractsPerOrder == ReadBytes(maximumNumberOfContractsPerOrder.rest, 6) IN IF ~minimumNumberOfContractsPerOrder.ok THEN Fail ELSE
    LET maximumThresholdPrice == ReadBytes(minimumNumberOfContractsPerOrder.rest, 6) IN IF ~maximumThresholdPrice.ok THEN Fail ELSE
    LET maximumThresholdPriceFractionIndicator == ReadBytes(maximumThresholdPrice.rest, 1) IN IF ~maximumThresholdPriceFractionIndicator.ok THEN Fail ELSE
    LET minimumThresholdPrice == ReadBytes(maximumThresholdPriceFractionIndicator.rest, 6) IN IF ~minimumThresholdPrice.ok THEN Fail ELSE
    LET minimumThresholdPriceFractionIndicator == ReadBytes(minimumThresholdPrice.rest, 1) IN IF ~minimumThresholdPriceFractionIndicator.ok THEN Fail ELSE
    LET tickIncrement == ReadBytes(minimumThresholdPriceFractionIndicator.rest, 6) IN IF ~tickIncrement.ok THEN Fail ELSE
    LET tickIncrementFractionIndicator == ReadBytes(tickIncrement.rest, 1) IN IF ~tickIncrementFractionIndicator.ok THEN Fail ELSE
    LET optionType == ReadBytes(tickIncrementFractionIndicator.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET marketFlowIndicator == DecodeMarketFlowIndicator(optionType.rest) IN IF ~marketFlowIndicator.ok THEN Fail ELSE
    LET groupInstrument == ReadBytes(marketFlowIndicator.rest, 2) IN IF ~groupInstrument.ok THEN Fail ELSE
    LET instrument == ReadBytes(groupInstrument.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET instrumentExternalCode == ReadBytes(instrument.rest, 30) IN IF ~instrumentExternalCode.ok THEN Fail ELSE
    LET optionMarker == DecodeOptionMarker(instrumentExternalCode.rest) IN IF ~optionMarker.ok THEN Fail ELSE
    LET underlyingSymbolRoot == ReadBytes(optionMarker.rest, 10) IN IF ~underlyingSymbolRoot.ok THEN Fail ELSE
    Ok([ exchangeId                             |-> exchangeId.value,
         instrumentDescription                  |-> instrumentDescription.value,
         strikePriceCurrency                    |-> strikePriceCurrency.value,
         maximumNumberOfContractsPerOrder       |-> maximumNumberOfContractsPerOrder.value,
         minimumNumberOfContractsPerOrder       |-> minimumNumberOfContractsPerOrder.value,
         maximumThresholdPrice                  |-> maximumThresholdPrice.value,
         maximumThresholdPriceFractionIndicator |-> maximumThresholdPriceFractionIndicator.value,
         minimumThresholdPrice                  |-> minimumThresholdPrice.value,
         minimumThresholdPriceFractionIndicator |-> minimumThresholdPriceFractionIndicator.value,
         tickIncrement                          |-> tickIncrement.value,
         tickIncrementFractionIndicator         |-> tickIncrementFractionIndicator.value,
         optionType                             |-> optionType.value,
         marketFlowIndicator                    |-> marketFlowIndicator.value,
         groupInstrument                        |-> groupInstrument.value,
         instrument                             |-> instrument.value,
         instrumentExternalCode                 |-> instrumentExternalCode.value,
         optionMarker                           |-> optionMarker.value,
         underlyingSymbolRoot                   |-> underlyingSymbolRoot.value ], underlyingSymbolRoot.rest)

ZeroOptionInstrumentKeysMessage ==
    [ exchangeId                             |-> [i \in 1 .. 1 |-> 0],
      instrumentDescription                  |-> ZeroInstrumentDescription6,
      strikePriceCurrency                    |-> [i \in 1 .. 3 |-> 0],
      maximumNumberOfContractsPerOrder       |-> [i \in 1 .. 6 |-> 0],
      minimumNumberOfContractsPerOrder       |-> [i \in 1 .. 6 |-> 0],
      maximumThresholdPrice                  |-> [i \in 1 .. 6 |-> 0],
      maximumThresholdPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      minimumThresholdPrice                  |-> [i \in 1 .. 6 |-> 0],
      minimumThresholdPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      tickIncrement                          |-> [i \in 1 .. 6 |-> 0],
      tickIncrementFractionIndicator         |-> [i \in 1 .. 1 |-> 0],
      optionType                             |-> [i \in 1 .. 1 |-> 0],
      marketFlowIndicator                    |-> ZeroMarketFlowIndicator,
      groupInstrument                        |-> [i \in 1 .. 2 |-> 0],
      instrument                             |-> [i \in 1 .. 4 |-> 0],
      instrumentExternalCode                 |-> [i \in 1 .. 30 |-> 0],
      optionMarker                           |-> ZeroOptionMarker,
      underlyingSymbolRoot                   |-> [i \in 1 .. 10 |-> 0] ]

(* Option Instrument Keys Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionInstrumentKeysMessage ==
    { ZeroOptionInstrumentKeysMessage }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.instrumentDescription = one] : one \in CheckedInstrumentDescription6 }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.strikePriceCurrency = one] : one \in Sample(3) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.maximumNumberOfContractsPerOrder = one] : one \in Sample(6) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.minimumNumberOfContractsPerOrder = one] : one \in Sample(6) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.maximumThresholdPrice = one] : one \in Sample(6) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.maximumThresholdPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.minimumThresholdPrice = one] : one \in Sample(6) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.minimumThresholdPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.tickIncrement = one] : one \in Sample(6) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.tickIncrementFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.marketFlowIndicator = one] : one \in CheckedMarketFlowIndicator }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.groupInstrument = one] : one \in Sample(2) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.instrumentExternalCode = one] : one \in Sample(30) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.optionMarker = one] : one \in CheckedOptionMarker }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.underlyingSymbolRoot = one] : one \in Sample(10) }

(***************************************************************************)
(* Instrument Leg: 39 bytes                                                *)
(***************************************************************************)

InstrumentLeg ==
    [ legRatioSign : Sample(1),
      legRatio     : Sample(8),
      legSymbol    : Sample(30) ]

EncodeInstrumentLeg(message) ==
    message.legRatioSign
        \o message.legRatio
        \o message.legSymbol

DecodeInstrumentLeg(bytes) ==
    LET legRatioSign == ReadBytes(bytes, 1) IN IF ~legRatioSign.ok THEN Fail ELSE
    LET legRatio == ReadBytes(legRatioSign.rest, 8) IN IF ~legRatio.ok THEN Fail ELSE
    LET legSymbol == ReadBytes(legRatio.rest, 30) IN IF ~legSymbol.ok THEN Fail ELSE
    Ok([ legRatioSign |-> legRatioSign.value,
         legRatio     |-> legRatio.value,
         legSymbol    |-> legSymbol.value ], legSymbol.rest)

ZeroInstrumentLeg ==
    [ legRatioSign |-> [i \in 1 .. 1 |-> 0],
      legRatio     |-> [i \in 1 .. 8 |-> 0],
      legSymbol    |-> [i \in 1 .. 30 |-> 0] ]

(* Instrument Leg at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentLeg ==
    { ZeroInstrumentLeg }
        \cup { [ZeroInstrumentLeg EXCEPT !.legRatioSign = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentLeg EXCEPT !.legRatio = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentLeg EXCEPT !.legSymbol = one] : one \in Sample(30) }

(* A run of Instrument Leg, written one after another *)
RECURSIVE EncodeInstrumentLegList(_)
EncodeInstrumentLegList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeInstrumentLeg(Head(messages)) \o EncodeInstrumentLegList(Tail(messages))

(* As many Instrument Leg as the field that counts them says *)
RECURSIVE ReadInstrumentLegList(_, _)
ReadInstrumentLegList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeInstrumentLeg(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadInstrumentLegList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Instrument Leg of each kind, for the lists that carry them *)
OneInstrumentLeg == { ZeroInstrumentLeg }

(***************************************************************************)
(* Complex Order Instrument Keys Message                                   *)
(***************************************************************************)

ComplexOrderInstrumentKeysMessage ==
    [ exchangeId                         : Sample(1),
      complexOrderInstrumentSymbol       : Sample(30),
      expiryYear                         : Sample(2),
      deliveryMonth                      : Sample(1),
      expiryDay                          : Sample(2),
      maxNumberOfContractsPerOrder       : Sample(6),
      minNumberOfContractsPerOrder       : Sample(6),
      maxThresholdPriceSign              : Sample(1),
      maxThresholdPrice                  : Sample(6),
      maxThresholdPriceFractionIndicator : Sample(1),
      minThresholdPriceSign              : Sample(1),
      minThresholdPrice                  : Sample(6),
      minThresholdPriceFractionIndicator : Sample(1),
      tickIncrement                      : Sample(6),
      tickIncrementFractionIndicator     : Sample(1),
      filler2                            : Sample(2),
      group                              : Sample(2),
      instrument                         : Sample(4),
      instrumentExternalCode             : Sample(30),
      complexOrderInstrumentAllowImplied : Sample(1),
      instrumentLeg                      : SampleLists(OneInstrumentLeg) ]

EncodeComplexOrderInstrumentKeysMessage(message) ==
    message.exchangeId
        \o message.complexOrderInstrumentSymbol
        \o message.expiryYear
        \o message.deliveryMonth
        \o message.expiryDay
        \o message.maxNumberOfContractsPerOrder
        \o message.minNumberOfContractsPerOrder
        \o message.maxThresholdPriceSign
        \o message.maxThresholdPrice
        \o message.maxThresholdPriceFractionIndicator
        \o message.minThresholdPriceSign
        \o message.minThresholdPrice
        \o message.minThresholdPriceFractionIndicator
        \o message.tickIncrement
        \o message.tickIncrementFractionIndicator
        \o message.filler2
        \o message.group
        \o message.instrument
        \o message.instrumentExternalCode
        \o message.complexOrderInstrumentAllowImplied
        \o EncodeUIntBE(Len(message.instrumentLeg), 2)
        \o EncodeInstrumentLegList(message.instrumentLeg)

DecodeComplexOrderInstrumentKeysMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET complexOrderInstrumentSymbol == ReadBytes(exchangeId.rest, 30) IN IF ~complexOrderInstrumentSymbol.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(complexOrderInstrumentSymbol.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET deliveryMonth == ReadBytes(expiryYear.rest, 1) IN IF ~deliveryMonth.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(deliveryMonth.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET maxNumberOfContractsPerOrder == ReadBytes(expiryDay.rest, 6) IN IF ~maxNumberOfContractsPerOrder.ok THEN Fail ELSE
    LET minNumberOfContractsPerOrder == ReadBytes(maxNumberOfContractsPerOrder.rest, 6) IN IF ~minNumberOfContractsPerOrder.ok THEN Fail ELSE
    LET maxThresholdPriceSign == ReadBytes(minNumberOfContractsPerOrder.rest, 1) IN IF ~maxThresholdPriceSign.ok THEN Fail ELSE
    LET maxThresholdPrice == ReadBytes(maxThresholdPriceSign.rest, 6) IN IF ~maxThresholdPrice.ok THEN Fail ELSE
    LET maxThresholdPriceFractionIndicator == ReadBytes(maxThresholdPrice.rest, 1) IN IF ~maxThresholdPriceFractionIndicator.ok THEN Fail ELSE
    LET minThresholdPriceSign == ReadBytes(maxThresholdPriceFractionIndicator.rest, 1) IN IF ~minThresholdPriceSign.ok THEN Fail ELSE
    LET minThresholdPrice == ReadBytes(minThresholdPriceSign.rest, 6) IN IF ~minThresholdPrice.ok THEN Fail ELSE
    LET minThresholdPriceFractionIndicator == ReadBytes(minThresholdPrice.rest, 1) IN IF ~minThresholdPriceFractionIndicator.ok THEN Fail ELSE
    LET tickIncrement == ReadBytes(minThresholdPriceFractionIndicator.rest, 6) IN IF ~tickIncrement.ok THEN Fail ELSE
    LET tickIncrementFractionIndicator == ReadBytes(tickIncrement.rest, 1) IN IF ~tickIncrementFractionIndicator.ok THEN Fail ELSE
    LET filler2 == ReadBytes(tickIncrementFractionIndicator.rest, 2) IN IF ~filler2.ok THEN Fail ELSE
    LET group == ReadBytes(filler2.rest, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrument == ReadBytes(group.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET instrumentExternalCode == ReadBytes(instrument.rest, 30) IN IF ~instrumentExternalCode.ok THEN Fail ELSE
    LET complexOrderInstrumentAllowImplied == ReadBytes(instrumentExternalCode.rest, 1) IN IF ~complexOrderInstrumentAllowImplied.ok THEN Fail ELSE
    LET numberOfLegs == ReadUIntBE(complexOrderInstrumentAllowImplied.rest, 2) IN IF ~numberOfLegs.ok THEN Fail ELSE
    LET instrumentLeg == ReadInstrumentLegList(numberOfLegs.rest, numberOfLegs.value) IN IF ~instrumentLeg.ok THEN Fail ELSE
    Ok([ exchangeId                         |-> exchangeId.value,
         complexOrderInstrumentSymbol       |-> complexOrderInstrumentSymbol.value,
         expiryYear                         |-> expiryYear.value,
         deliveryMonth                      |-> deliveryMonth.value,
         expiryDay                          |-> expiryDay.value,
         maxNumberOfContractsPerOrder       |-> maxNumberOfContractsPerOrder.value,
         minNumberOfContractsPerOrder       |-> minNumberOfContractsPerOrder.value,
         maxThresholdPriceSign              |-> maxThresholdPriceSign.value,
         maxThresholdPrice                  |-> maxThresholdPrice.value,
         maxThresholdPriceFractionIndicator |-> maxThresholdPriceFractionIndicator.value,
         minThresholdPriceSign              |-> minThresholdPriceSign.value,
         minThresholdPrice                  |-> minThresholdPrice.value,
         minThresholdPriceFractionIndicator |-> minThresholdPriceFractionIndicator.value,
         tickIncrement                      |-> tickIncrement.value,
         tickIncrementFractionIndicator     |-> tickIncrementFractionIndicator.value,
         filler2                            |-> filler2.value,
         group                              |-> group.value,
         instrument                         |-> instrument.value,
         instrumentExternalCode             |-> instrumentExternalCode.value,
         complexOrderInstrumentAllowImplied |-> complexOrderInstrumentAllowImplied.value,
         instrumentLeg                      |-> instrumentLeg.value ], instrumentLeg.rest)

ZeroComplexOrderInstrumentKeysMessage ==
    [ exchangeId                         |-> [i \in 1 .. 1 |-> 0],
      complexOrderInstrumentSymbol       |-> [i \in 1 .. 30 |-> 0],
      expiryYear                         |-> [i \in 1 .. 2 |-> 0],
      deliveryMonth                      |-> [i \in 1 .. 1 |-> 0],
      expiryDay                          |-> [i \in 1 .. 2 |-> 0],
      maxNumberOfContractsPerOrder       |-> [i \in 1 .. 6 |-> 0],
      minNumberOfContractsPerOrder       |-> [i \in 1 .. 6 |-> 0],
      maxThresholdPriceSign              |-> [i \in 1 .. 1 |-> 0],
      maxThresholdPrice                  |-> [i \in 1 .. 6 |-> 0],
      maxThresholdPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      minThresholdPriceSign              |-> [i \in 1 .. 1 |-> 0],
      minThresholdPrice                  |-> [i \in 1 .. 6 |-> 0],
      minThresholdPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      tickIncrement                      |-> [i \in 1 .. 6 |-> 0],
      tickIncrementFractionIndicator     |-> [i \in 1 .. 1 |-> 0],
      filler2                            |-> [i \in 1 .. 2 |-> 0],
      group                              |-> [i \in 1 .. 2 |-> 0],
      instrument                         |-> [i \in 1 .. 4 |-> 0],
      instrumentExternalCode             |-> [i \in 1 .. 30 |-> 0],
      complexOrderInstrumentAllowImplied |-> [i \in 1 .. 1 |-> 0],
      instrumentLeg                      |-> << >> ]

(* Complex Order Instrument Keys Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexOrderInstrumentKeysMessage ==
    { ZeroComplexOrderInstrumentKeysMessage }
        \cup { [ZeroComplexOrderInstrumentKeysMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderInstrumentKeysMessage EXCEPT !.complexOrderInstrumentSymbol = one] : one \in Sample(30) }
        \cup { [ZeroComplexOrderInstrumentKeysMessage EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroComplexOrderInstrumentKeysMessage EXCEPT !.deliveryMonth = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderInstrumentKeysMessage EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroComplexOrderInstrumentKeysMessage EXCEPT !.maxNumberOfContractsPerOrder = one] : one \in Sample(6) }
        \cup { [ZeroComplexOrderInstrumentKeysMessage EXCEPT !.minNumberOfContractsPerOrder = one] : one \in Sample(6) }
        \cup { [ZeroComplexOrderInstrumentKeysMessage EXCEPT !.maxThresholdPriceSign = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderInstrumentKeysMessage EXCEPT !.maxThresholdPrice = one] : one \in Sample(6) }
        \cup { [ZeroComplexOrderInstrumentKeysMessage EXCEPT !.maxThresholdPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderInstrumentKeysMessage EXCEPT !.minThresholdPriceSign = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderInstrumentKeysMessage EXCEPT !.minThresholdPrice = one] : one \in Sample(6) }
        \cup { [ZeroComplexOrderInstrumentKeysMessage EXCEPT !.minThresholdPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderInstrumentKeysMessage EXCEPT !.tickIncrement = one] : one \in Sample(6) }
        \cup { [ZeroComplexOrderInstrumentKeysMessage EXCEPT !.tickIncrementFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderInstrumentKeysMessage EXCEPT !.filler2 = one] : one \in Sample(2) }
        \cup { [ZeroComplexOrderInstrumentKeysMessage EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroComplexOrderInstrumentKeysMessage EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroComplexOrderInstrumentKeysMessage EXCEPT !.instrumentExternalCode = one] : one \in Sample(30) }
        \cup { [ZeroComplexOrderInstrumentKeysMessage EXCEPT !.complexOrderInstrumentAllowImplied = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderInstrumentKeysMessage EXCEPT !.instrumentLeg = one] : one \in SampleLists(OneInstrumentLeg) }

(***************************************************************************)
(* Bulletins Message: 82 bytes                                             *)
(***************************************************************************)

BulletinsMessage ==
    [ filler1          : Sample(1),
      bulletinType     : Sample(1),
      bulletinContents : Sample(79),
      continueMarker   : Sample(1) ]

EncodeBulletinsMessage(message) ==
    message.filler1
        \o message.bulletinType
        \o message.bulletinContents
        \o message.continueMarker

DecodeBulletinsMessage(bytes) ==
    LET filler1 == ReadBytes(bytes, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET bulletinType == ReadBytes(filler1.rest, 1) IN IF ~bulletinType.ok THEN Fail ELSE
    LET bulletinContents == ReadBytes(bulletinType.rest, 79) IN IF ~bulletinContents.ok THEN Fail ELSE
    LET continueMarker == ReadBytes(bulletinContents.rest, 1) IN IF ~continueMarker.ok THEN Fail ELSE
    Ok([ filler1          |-> filler1.value,
         bulletinType     |-> bulletinType.value,
         bulletinContents |-> bulletinContents.value,
         continueMarker   |-> continueMarker.value ], continueMarker.rest)

ZeroBulletinsMessage ==
    [ filler1          |-> [i \in 1 .. 1 |-> 0],
      bulletinType     |-> [i \in 1 .. 1 |-> 0],
      bulletinContents |-> [i \in 1 .. 79 |-> 0],
      continueMarker   |-> [i \in 1 .. 1 |-> 0] ]

(* Bulletins Message at zero, then each field in turn at the values it is checked at *)
CheckedBulletinsMessage ==
    { ZeroBulletinsMessage }
        \cup { [ZeroBulletinsMessage EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroBulletinsMessage EXCEPT !.bulletinType = one] : one \in Sample(1) }
        \cup { [ZeroBulletinsMessage EXCEPT !.bulletinContents = one] : one \in Sample(79) }
        \cup { [ZeroBulletinsMessage EXCEPT !.continueMarker = one] : one \in Sample(1) }

(***************************************************************************)
(* Instrument Description: 20 bytes                                        *)
(***************************************************************************)

InstrumentDescription7 ==
    [ rootSymbol                   : Sample(6),
      expiryMonthCode              : Sample(1),
      filler1                      : Sample(1),
      strikePrice                  : Sample(7),
      strikePriceFractionIndicator : Sample(1),
      expiryYear                   : Sample(2),
      expiryDay                    : Sample(2) ]

EncodeInstrumentDescription7(message) ==
    message.rootSymbol
        \o message.expiryMonthCode
        \o message.filler1
        \o message.strikePrice
        \o message.strikePriceFractionIndicator
        \o message.expiryYear
        \o message.expiryDay

DecodeInstrumentDescription7(bytes) ==
    LET rootSymbol == ReadBytes(bytes, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET expiryMonthCode == ReadBytes(rootSymbol.rest, 1) IN IF ~expiryMonthCode.ok THEN Fail ELSE
    LET filler1 == ReadBytes(expiryMonthCode.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(filler1.rest, 7) IN IF ~strikePrice.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePrice.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(strikePriceFractionIndicator.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ rootSymbol                   |-> rootSymbol.value,
         expiryMonthCode              |-> expiryMonthCode.value,
         filler1                      |-> filler1.value,
         strikePrice                  |-> strikePrice.value,
         strikePriceFractionIndicator |-> strikePriceFractionIndicator.value,
         expiryYear                   |-> expiryYear.value,
         expiryDay                    |-> expiryDay.value ], expiryDay.rest)

ZeroInstrumentDescription7 ==
    [ rootSymbol                   |-> [i \in 1 .. 6 |-> 0],
      expiryMonthCode              |-> [i \in 1 .. 1 |-> 0],
      filler1                      |-> [i \in 1 .. 1 |-> 0],
      strikePrice                  |-> [i \in 1 .. 7 |-> 0],
      strikePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      expiryYear                   |-> [i \in 1 .. 2 |-> 0],
      expiryDay                    |-> [i \in 1 .. 2 |-> 0] ]

(* Instrument Description at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentDescription7 ==
    { ZeroInstrumentDescription7 }
        \cup { [ZeroInstrumentDescription7 EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroInstrumentDescription7 EXCEPT !.expiryMonthCode = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDescription7 EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDescription7 EXCEPT !.strikePrice = one] : one \in Sample(7) }
        \cup { [ZeroInstrumentDescription7 EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDescription7 EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentDescription7 EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Option Marker: 2 bytes                                                  *)
(***************************************************************************)

OptionMarker2 ==
    [ typeOfMarket  : Sample(1),
      typeOfOptions : Sample(1) ]

EncodeOptionMarker2(message) ==
    message.typeOfMarket
        \o message.typeOfOptions

DecodeOptionMarker2(bytes) ==
    LET typeOfMarket == ReadBytes(bytes, 1) IN IF ~typeOfMarket.ok THEN Fail ELSE
    LET typeOfOptions == ReadBytes(typeOfMarket.rest, 1) IN IF ~typeOfOptions.ok THEN Fail ELSE
    Ok([ typeOfMarket  |-> typeOfMarket.value,
         typeOfOptions |-> typeOfOptions.value ], typeOfOptions.rest)

ZeroOptionMarker2 ==
    [ typeOfMarket  |-> [i \in 1 .. 1 |-> 0],
      typeOfOptions |-> [i \in 1 .. 1 |-> 0] ]

(* Option Marker at zero, then each field in turn at the values it is checked at *)
CheckedOptionMarker2 ==
    { ZeroOptionMarker2 }
        \cup { [ZeroOptionMarker2 EXCEPT !.typeOfMarket = one] : one \in Sample(1) }
        \cup { [ZeroOptionMarker2 EXCEPT !.typeOfOptions = one] : one \in Sample(1) }

(***************************************************************************)
(* Option Summary Message: 116 bytes                                       *)
(***************************************************************************)

OptionSummaryMessage ==
    [ exchangeId                      : Sample(1),
      instrumentDescription           : InstrumentDescription7,
      bidPrice                        : Sample(6),
      bidPriceFractionIndicator       : Sample(1),
      bidSize                         : Sample(5),
      askPrice                        : Sample(6),
      askPriceFractionIndicator       : Sample(1),
      askSize                         : Sample(5),
      lastPrice                       : Sample(6),
      lastPriceFractionIndicator      : Sample(1),
      filler7                         : Sample(7),
      tick                            : Sample(1),
      volume                          : Sample(8),
      netChangeSign                   : Sample(1),
      netChange                       : Sample(6),
      netChangeFractionIndicator      : Sample(1),
      openPrice                       : Sample(6),
      openPriceFractionIndicator      : Sample(1),
      highPrice                       : Sample(6),
      highPriceFractionIndicator      : Sample(1),
      lowPrice                        : Sample(6),
      lowPriceFractionIndicator       : Sample(1),
      optionMarker                    : OptionMarker2,
      underlyingSymbol                : Sample(10),
      referencePrice                  : Sample(6),
      referencePriceFractionIndicator : Sample(1) ]

EncodeOptionSummaryMessage(message) ==
    message.exchangeId
        \o EncodeInstrumentDescription7(message.instrumentDescription)
        \o message.bidPrice
        \o message.bidPriceFractionIndicator
        \o message.bidSize
        \o message.askPrice
        \o message.askPriceFractionIndicator
        \o message.askSize
        \o message.lastPrice
        \o message.lastPriceFractionIndicator
        \o message.filler7
        \o message.tick
        \o message.volume
        \o message.netChangeSign
        \o message.netChange
        \o message.netChangeFractionIndicator
        \o message.openPrice
        \o message.openPriceFractionIndicator
        \o message.highPrice
        \o message.highPriceFractionIndicator
        \o message.lowPrice
        \o message.lowPriceFractionIndicator
        \o EncodeOptionMarker2(message.optionMarker)
        \o message.underlyingSymbol
        \o message.referencePrice
        \o message.referencePriceFractionIndicator

DecodeOptionSummaryMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET instrumentDescription == DecodeInstrumentDescription7(exchangeId.rest) IN IF ~instrumentDescription.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(instrumentDescription.rest, 6) IN IF ~bidPrice.ok THEN Fail ELSE
    LET bidPriceFractionIndicator == ReadBytes(bidPrice.rest, 1) IN IF ~bidPriceFractionIndicator.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPriceFractionIndicator.rest, 5) IN IF ~bidSize.ok THEN Fail ELSE
    LET askPrice == ReadBytes(bidSize.rest, 6) IN IF ~askPrice.ok THEN Fail ELSE
    LET askPriceFractionIndicator == ReadBytes(askPrice.rest, 1) IN IF ~askPriceFractionIndicator.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPriceFractionIndicator.rest, 5) IN IF ~askSize.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(askSize.rest, 6) IN IF ~lastPrice.ok THEN Fail ELSE
    LET lastPriceFractionIndicator == ReadBytes(lastPrice.rest, 1) IN IF ~lastPriceFractionIndicator.ok THEN Fail ELSE
    LET filler7 == ReadBytes(lastPriceFractionIndicator.rest, 7) IN IF ~filler7.ok THEN Fail ELSE
    LET tick == ReadBytes(filler7.rest, 1) IN IF ~tick.ok THEN Fail ELSE
    LET volume == ReadBytes(tick.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET netChangeSign == ReadBytes(volume.rest, 1) IN IF ~netChangeSign.ok THEN Fail ELSE
    LET netChange == ReadBytes(netChangeSign.rest, 6) IN IF ~netChange.ok THEN Fail ELSE
    LET netChangeFractionIndicator == ReadBytes(netChange.rest, 1) IN IF ~netChangeFractionIndicator.ok THEN Fail ELSE
    LET openPrice == ReadBytes(netChangeFractionIndicator.rest, 6) IN IF ~openPrice.ok THEN Fail ELSE
    LET openPriceFractionIndicator == ReadBytes(openPrice.rest, 1) IN IF ~openPriceFractionIndicator.ok THEN Fail ELSE
    LET highPrice == ReadBytes(openPriceFractionIndicator.rest, 6) IN IF ~highPrice.ok THEN Fail ELSE
    LET highPriceFractionIndicator == ReadBytes(highPrice.rest, 1) IN IF ~highPriceFractionIndicator.ok THEN Fail ELSE
    LET lowPrice == ReadBytes(highPriceFractionIndicator.rest, 6) IN IF ~lowPrice.ok THEN Fail ELSE
    LET lowPriceFractionIndicator == ReadBytes(lowPrice.rest, 1) IN IF ~lowPriceFractionIndicator.ok THEN Fail ELSE
    LET optionMarker == DecodeOptionMarker2(lowPriceFractionIndicator.rest) IN IF ~optionMarker.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(optionMarker.rest, 10) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET referencePrice == ReadBytes(underlyingSymbol.rest, 6) IN IF ~referencePrice.ok THEN Fail ELSE
    LET referencePriceFractionIndicator == ReadBytes(referencePrice.rest, 1) IN IF ~referencePriceFractionIndicator.ok THEN Fail ELSE
    Ok([ exchangeId                      |-> exchangeId.value,
         instrumentDescription           |-> instrumentDescription.value,
         bidPrice                        |-> bidPrice.value,
         bidPriceFractionIndicator       |-> bidPriceFractionIndicator.value,
         bidSize                         |-> bidSize.value,
         askPrice                        |-> askPrice.value,
         askPriceFractionIndicator       |-> askPriceFractionIndicator.value,
         askSize                         |-> askSize.value,
         lastPrice                       |-> lastPrice.value,
         lastPriceFractionIndicator      |-> lastPriceFractionIndicator.value,
         filler7                         |-> filler7.value,
         tick                            |-> tick.value,
         volume                          |-> volume.value,
         netChangeSign                   |-> netChangeSign.value,
         netChange                       |-> netChange.value,
         netChangeFractionIndicator      |-> netChangeFractionIndicator.value,
         openPrice                       |-> openPrice.value,
         openPriceFractionIndicator      |-> openPriceFractionIndicator.value,
         highPrice                       |-> highPrice.value,
         highPriceFractionIndicator      |-> highPriceFractionIndicator.value,
         lowPrice                        |-> lowPrice.value,
         lowPriceFractionIndicator       |-> lowPriceFractionIndicator.value,
         optionMarker                    |-> optionMarker.value,
         underlyingSymbol                |-> underlyingSymbol.value,
         referencePrice                  |-> referencePrice.value,
         referencePriceFractionIndicator |-> referencePriceFractionIndicator.value ], referencePriceFractionIndicator.rest)

ZeroOptionSummaryMessage ==
    [ exchangeId                      |-> [i \in 1 .. 1 |-> 0],
      instrumentDescription           |-> ZeroInstrumentDescription7,
      bidPrice                        |-> [i \in 1 .. 6 |-> 0],
      bidPriceFractionIndicator       |-> [i \in 1 .. 1 |-> 0],
      bidSize                         |-> [i \in 1 .. 5 |-> 0],
      askPrice                        |-> [i \in 1 .. 6 |-> 0],
      askPriceFractionIndicator       |-> [i \in 1 .. 1 |-> 0],
      askSize                         |-> [i \in 1 .. 5 |-> 0],
      lastPrice                       |-> [i \in 1 .. 6 |-> 0],
      lastPriceFractionIndicator      |-> [i \in 1 .. 1 |-> 0],
      filler7                         |-> [i \in 1 .. 7 |-> 0],
      tick                            |-> [i \in 1 .. 1 |-> 0],
      volume                          |-> [i \in 1 .. 8 |-> 0],
      netChangeSign                   |-> [i \in 1 .. 1 |-> 0],
      netChange                       |-> [i \in 1 .. 6 |-> 0],
      netChangeFractionIndicator      |-> [i \in 1 .. 1 |-> 0],
      openPrice                       |-> [i \in 1 .. 6 |-> 0],
      openPriceFractionIndicator      |-> [i \in 1 .. 1 |-> 0],
      highPrice                       |-> [i \in 1 .. 6 |-> 0],
      highPriceFractionIndicator      |-> [i \in 1 .. 1 |-> 0],
      lowPrice                        |-> [i \in 1 .. 6 |-> 0],
      lowPriceFractionIndicator       |-> [i \in 1 .. 1 |-> 0],
      optionMarker                    |-> ZeroOptionMarker2,
      underlyingSymbol                |-> [i \in 1 .. 10 |-> 0],
      referencePrice                  |-> [i \in 1 .. 6 |-> 0],
      referencePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Option Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionSummaryMessage ==
    { ZeroOptionSummaryMessage }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.instrumentDescription = one] : one \in CheckedInstrumentDescription7 }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.bidPrice = one] : one \in Sample(6) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.bidPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.bidSize = one] : one \in Sample(5) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.askPrice = one] : one \in Sample(6) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.askPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.askSize = one] : one \in Sample(5) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.lastPrice = one] : one \in Sample(6) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.lastPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.filler7 = one] : one \in Sample(7) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.tick = one] : one \in Sample(1) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.netChangeSign = one] : one \in Sample(1) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.netChange = one] : one \in Sample(6) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.netChangeFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.openPrice = one] : one \in Sample(6) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.openPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.highPrice = one] : one \in Sample(6) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.highPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.lowPrice = one] : one \in Sample(6) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.lowPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.optionMarker = one] : one \in CheckedOptionMarker2 }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(10) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.referencePrice = one] : one \in Sample(6) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.referencePriceFractionIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Complex Order Summary Message: 105 bytes                                *)
(***************************************************************************)

ComplexOrderSummaryMessage ==
    [ exchangeId                   : Sample(1),
      complexOrderInstrumentSymbol : Sample(30),
      bidPriceSign                 : Sample(1),
      bidPrice                     : Sample(6),
      bidPriceFractionIndicator    : Sample(1),
      bidSize                      : Sample(5),
      askPriceSign                 : Sample(1),
      askPrice                     : Sample(6),
      askPriceFractionIndicator    : Sample(1),
      askSize                      : Sample(5),
      lastPriceSign                : Sample(1),
      lastPrice                    : Sample(6),
      lastPriceFractionIndicator   : Sample(1),
      openPriceSign                : Sample(1),
      openPrice                    : Sample(6),
      openPriceFractionIndicator   : Sample(1),
      highPriceSign                : Sample(1),
      highPrice                    : Sample(6),
      highPriceFractionIndicator   : Sample(1),
      lowPriceSign                 : Sample(1),
      lowPrice                     : Sample(6),
      lowPriceFractionIndicator    : Sample(1),
      netChangeSign                : Sample(1),
      netChange                    : Sample(6),
      netChangeFractionIndicator   : Sample(1),
      volume                       : Sample(8) ]

EncodeComplexOrderSummaryMessage(message) ==
    message.exchangeId
        \o message.complexOrderInstrumentSymbol
        \o message.bidPriceSign
        \o message.bidPrice
        \o message.bidPriceFractionIndicator
        \o message.bidSize
        \o message.askPriceSign
        \o message.askPrice
        \o message.askPriceFractionIndicator
        \o message.askSize
        \o message.lastPriceSign
        \o message.lastPrice
        \o message.lastPriceFractionIndicator
        \o message.openPriceSign
        \o message.openPrice
        \o message.openPriceFractionIndicator
        \o message.highPriceSign
        \o message.highPrice
        \o message.highPriceFractionIndicator
        \o message.lowPriceSign
        \o message.lowPrice
        \o message.lowPriceFractionIndicator
        \o message.netChangeSign
        \o message.netChange
        \o message.netChangeFractionIndicator
        \o message.volume

DecodeComplexOrderSummaryMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET complexOrderInstrumentSymbol == ReadBytes(exchangeId.rest, 30) IN IF ~complexOrderInstrumentSymbol.ok THEN Fail ELSE
    LET bidPriceSign == ReadBytes(complexOrderInstrumentSymbol.rest, 1) IN IF ~bidPriceSign.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(bidPriceSign.rest, 6) IN IF ~bidPrice.ok THEN Fail ELSE
    LET bidPriceFractionIndicator == ReadBytes(bidPrice.rest, 1) IN IF ~bidPriceFractionIndicator.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPriceFractionIndicator.rest, 5) IN IF ~bidSize.ok THEN Fail ELSE
    LET askPriceSign == ReadBytes(bidSize.rest, 1) IN IF ~askPriceSign.ok THEN Fail ELSE
    LET askPrice == ReadBytes(askPriceSign.rest, 6) IN IF ~askPrice.ok THEN Fail ELSE
    LET askPriceFractionIndicator == ReadBytes(askPrice.rest, 1) IN IF ~askPriceFractionIndicator.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPriceFractionIndicator.rest, 5) IN IF ~askSize.ok THEN Fail ELSE
    LET lastPriceSign == ReadBytes(askSize.rest, 1) IN IF ~lastPriceSign.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(lastPriceSign.rest, 6) IN IF ~lastPrice.ok THEN Fail ELSE
    LET lastPriceFractionIndicator == ReadBytes(lastPrice.rest, 1) IN IF ~lastPriceFractionIndicator.ok THEN Fail ELSE
    LET openPriceSign == ReadBytes(lastPriceFractionIndicator.rest, 1) IN IF ~openPriceSign.ok THEN Fail ELSE
    LET openPrice == ReadBytes(openPriceSign.rest, 6) IN IF ~openPrice.ok THEN Fail ELSE
    LET openPriceFractionIndicator == ReadBytes(openPrice.rest, 1) IN IF ~openPriceFractionIndicator.ok THEN Fail ELSE
    LET highPriceSign == ReadBytes(openPriceFractionIndicator.rest, 1) IN IF ~highPriceSign.ok THEN Fail ELSE
    LET highPrice == ReadBytes(highPriceSign.rest, 6) IN IF ~highPrice.ok THEN Fail ELSE
    LET highPriceFractionIndicator == ReadBytes(highPrice.rest, 1) IN IF ~highPriceFractionIndicator.ok THEN Fail ELSE
    LET lowPriceSign == ReadBytes(highPriceFractionIndicator.rest, 1) IN IF ~lowPriceSign.ok THEN Fail ELSE
    LET lowPrice == ReadBytes(lowPriceSign.rest, 6) IN IF ~lowPrice.ok THEN Fail ELSE
    LET lowPriceFractionIndicator == ReadBytes(lowPrice.rest, 1) IN IF ~lowPriceFractionIndicator.ok THEN Fail ELSE
    LET netChangeSign == ReadBytes(lowPriceFractionIndicator.rest, 1) IN IF ~netChangeSign.ok THEN Fail ELSE
    LET netChange == ReadBytes(netChangeSign.rest, 6) IN IF ~netChange.ok THEN Fail ELSE
    LET netChangeFractionIndicator == ReadBytes(netChange.rest, 1) IN IF ~netChangeFractionIndicator.ok THEN Fail ELSE
    LET volume == ReadBytes(netChangeFractionIndicator.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    Ok([ exchangeId                   |-> exchangeId.value,
         complexOrderInstrumentSymbol |-> complexOrderInstrumentSymbol.value,
         bidPriceSign                 |-> bidPriceSign.value,
         bidPrice                     |-> bidPrice.value,
         bidPriceFractionIndicator    |-> bidPriceFractionIndicator.value,
         bidSize                      |-> bidSize.value,
         askPriceSign                 |-> askPriceSign.value,
         askPrice                     |-> askPrice.value,
         askPriceFractionIndicator    |-> askPriceFractionIndicator.value,
         askSize                      |-> askSize.value,
         lastPriceSign                |-> lastPriceSign.value,
         lastPrice                    |-> lastPrice.value,
         lastPriceFractionIndicator   |-> lastPriceFractionIndicator.value,
         openPriceSign                |-> openPriceSign.value,
         openPrice                    |-> openPrice.value,
         openPriceFractionIndicator   |-> openPriceFractionIndicator.value,
         highPriceSign                |-> highPriceSign.value,
         highPrice                    |-> highPrice.value,
         highPriceFractionIndicator   |-> highPriceFractionIndicator.value,
         lowPriceSign                 |-> lowPriceSign.value,
         lowPrice                     |-> lowPrice.value,
         lowPriceFractionIndicator    |-> lowPriceFractionIndicator.value,
         netChangeSign                |-> netChangeSign.value,
         netChange                    |-> netChange.value,
         netChangeFractionIndicator   |-> netChangeFractionIndicator.value,
         volume                       |-> volume.value ], volume.rest)

ZeroComplexOrderSummaryMessage ==
    [ exchangeId                   |-> [i \in 1 .. 1 |-> 0],
      complexOrderInstrumentSymbol |-> [i \in 1 .. 30 |-> 0],
      bidPriceSign                 |-> [i \in 1 .. 1 |-> 0],
      bidPrice                     |-> [i \in 1 .. 6 |-> 0],
      bidPriceFractionIndicator    |-> [i \in 1 .. 1 |-> 0],
      bidSize                      |-> [i \in 1 .. 5 |-> 0],
      askPriceSign                 |-> [i \in 1 .. 1 |-> 0],
      askPrice                     |-> [i \in 1 .. 6 |-> 0],
      askPriceFractionIndicator    |-> [i \in 1 .. 1 |-> 0],
      askSize                      |-> [i \in 1 .. 5 |-> 0],
      lastPriceSign                |-> [i \in 1 .. 1 |-> 0],
      lastPrice                    |-> [i \in 1 .. 6 |-> 0],
      lastPriceFractionIndicator   |-> [i \in 1 .. 1 |-> 0],
      openPriceSign                |-> [i \in 1 .. 1 |-> 0],
      openPrice                    |-> [i \in 1 .. 6 |-> 0],
      openPriceFractionIndicator   |-> [i \in 1 .. 1 |-> 0],
      highPriceSign                |-> [i \in 1 .. 1 |-> 0],
      highPrice                    |-> [i \in 1 .. 6 |-> 0],
      highPriceFractionIndicator   |-> [i \in 1 .. 1 |-> 0],
      lowPriceSign                 |-> [i \in 1 .. 1 |-> 0],
      lowPrice                     |-> [i \in 1 .. 6 |-> 0],
      lowPriceFractionIndicator    |-> [i \in 1 .. 1 |-> 0],
      netChangeSign                |-> [i \in 1 .. 1 |-> 0],
      netChange                    |-> [i \in 1 .. 6 |-> 0],
      netChangeFractionIndicator   |-> [i \in 1 .. 1 |-> 0],
      volume                       |-> [i \in 1 .. 8 |-> 0] ]

(* Complex Order Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexOrderSummaryMessage ==
    { ZeroComplexOrderSummaryMessage }
        \cup { [ZeroComplexOrderSummaryMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderSummaryMessage EXCEPT !.complexOrderInstrumentSymbol = one] : one \in Sample(30) }
        \cup { [ZeroComplexOrderSummaryMessage EXCEPT !.bidPriceSign = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderSummaryMessage EXCEPT !.bidPrice = one] : one \in Sample(6) }
        \cup { [ZeroComplexOrderSummaryMessage EXCEPT !.bidPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderSummaryMessage EXCEPT !.bidSize = one] : one \in Sample(5) }
        \cup { [ZeroComplexOrderSummaryMessage EXCEPT !.askPriceSign = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderSummaryMessage EXCEPT !.askPrice = one] : one \in Sample(6) }
        \cup { [ZeroComplexOrderSummaryMessage EXCEPT !.askPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderSummaryMessage EXCEPT !.askSize = one] : one \in Sample(5) }
        \cup { [ZeroComplexOrderSummaryMessage EXCEPT !.lastPriceSign = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderSummaryMessage EXCEPT !.lastPrice = one] : one \in Sample(6) }
        \cup { [ZeroComplexOrderSummaryMessage EXCEPT !.lastPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderSummaryMessage EXCEPT !.openPriceSign = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderSummaryMessage EXCEPT !.openPrice = one] : one \in Sample(6) }
        \cup { [ZeroComplexOrderSummaryMessage EXCEPT !.openPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderSummaryMessage EXCEPT !.highPriceSign = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderSummaryMessage EXCEPT !.highPrice = one] : one \in Sample(6) }
        \cup { [ZeroComplexOrderSummaryMessage EXCEPT !.highPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderSummaryMessage EXCEPT !.lowPriceSign = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderSummaryMessage EXCEPT !.lowPrice = one] : one \in Sample(6) }
        \cup { [ZeroComplexOrderSummaryMessage EXCEPT !.lowPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderSummaryMessage EXCEPT !.netChangeSign = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderSummaryMessage EXCEPT !.netChange = one] : one \in Sample(6) }
        \cup { [ZeroComplexOrderSummaryMessage EXCEPT !.netChangeFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderSummaryMessage EXCEPT !.volume = one] : one \in Sample(8) }

(***************************************************************************)
(* Beginning Of Options Summary Message: 1 bytes                           *)
(***************************************************************************)

BeginningOfOptionsSummaryMessage ==
    [ exchangeId : Sample(1) ]

EncodeBeginningOfOptionsSummaryMessage(message) ==
    message.exchangeId

DecodeBeginningOfOptionsSummaryMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    Ok([ exchangeId |-> exchangeId.value ], exchangeId.rest)

ZeroBeginningOfOptionsSummaryMessage ==
    [ exchangeId |-> [i \in 1 .. 1 |-> 0] ]

(* Beginning Of Options Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedBeginningOfOptionsSummaryMessage ==
    { ZeroBeginningOfOptionsSummaryMessage }
        \cup { [ZeroBeginningOfOptionsSummaryMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }

(***************************************************************************)
(* Beginning Of Complex Order Summary Message: 1 bytes                     *)
(***************************************************************************)

BeginningOfComplexOrderSummaryMessage ==
    [ exchangeId : Sample(1) ]

EncodeBeginningOfComplexOrderSummaryMessage(message) ==
    message.exchangeId

DecodeBeginningOfComplexOrderSummaryMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    Ok([ exchangeId |-> exchangeId.value ], exchangeId.rest)

ZeroBeginningOfComplexOrderSummaryMessage ==
    [ exchangeId |-> [i \in 1 .. 1 |-> 0] ]

(* Beginning Of Complex Order Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedBeginningOfComplexOrderSummaryMessage ==
    { ZeroBeginningOfComplexOrderSummaryMessage }
        \cup { [ZeroBeginningOfComplexOrderSummaryMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }

(***************************************************************************)
(* End Of Sales Message: 7 bytes                                           *)
(***************************************************************************)

EndOfSalesMessage ==
    [ reserved : Sample(1),
      time     : Sample(6) ]

EncodeEndOfSalesMessage(message) ==
    message.reserved
        \o message.time

DecodeEndOfSalesMessage(bytes) ==
    LET reserved == ReadBytes(bytes, 1) IN IF ~reserved.ok THEN Fail ELSE
    LET time == ReadBytes(reserved.rest, 6) IN IF ~time.ok THEN Fail ELSE
    Ok([ reserved |-> reserved.value,
         time     |-> time.value ], time.rest)

ZeroEndOfSalesMessage ==
    [ reserved |-> [i \in 1 .. 1 |-> 0],
      time     |-> [i \in 1 .. 6 |-> 0] ]

(* End Of Sales Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfSalesMessage ==
    { ZeroEndOfSalesMessage }
        \cup { [ZeroEndOfSalesMessage EXCEPT !.reserved = one] : one \in Sample(1) }
        \cup { [ZeroEndOfSalesMessage EXCEPT !.time = one] : one \in Sample(6) }

(***************************************************************************)
(* Instrument Description: 20 bytes                                        *)
(***************************************************************************)

InstrumentDescription8 ==
    [ rootSymbol                   : Sample(6),
      expiryMonthCode              : Sample(1),
      filler1                      : Sample(1),
      strikePrice                  : Sample(7),
      strikePriceFractionIndicator : Sample(1),
      expiryYear                   : Sample(2),
      expiryDay                    : Sample(2) ]

EncodeInstrumentDescription8(message) ==
    message.rootSymbol
        \o message.expiryMonthCode
        \o message.filler1
        \o message.strikePrice
        \o message.strikePriceFractionIndicator
        \o message.expiryYear
        \o message.expiryDay

DecodeInstrumentDescription8(bytes) ==
    LET rootSymbol == ReadBytes(bytes, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET expiryMonthCode == ReadBytes(rootSymbol.rest, 1) IN IF ~expiryMonthCode.ok THEN Fail ELSE
    LET filler1 == ReadBytes(expiryMonthCode.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(filler1.rest, 7) IN IF ~strikePrice.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePrice.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(strikePriceFractionIndicator.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ rootSymbol                   |-> rootSymbol.value,
         expiryMonthCode              |-> expiryMonthCode.value,
         filler1                      |-> filler1.value,
         strikePrice                  |-> strikePrice.value,
         strikePriceFractionIndicator |-> strikePriceFractionIndicator.value,
         expiryYear                   |-> expiryYear.value,
         expiryDay                    |-> expiryDay.value ], expiryDay.rest)

ZeroInstrumentDescription8 ==
    [ rootSymbol                   |-> [i \in 1 .. 6 |-> 0],
      expiryMonthCode              |-> [i \in 1 .. 1 |-> 0],
      filler1                      |-> [i \in 1 .. 1 |-> 0],
      strikePrice                  |-> [i \in 1 .. 7 |-> 0],
      strikePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      expiryYear                   |-> [i \in 1 .. 2 |-> 0],
      expiryDay                    |-> [i \in 1 .. 2 |-> 0] ]

(* Instrument Description at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentDescription8 ==
    { ZeroInstrumentDescription8 }
        \cup { [ZeroInstrumentDescription8 EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroInstrumentDescription8 EXCEPT !.expiryMonthCode = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDescription8 EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDescription8 EXCEPT !.strikePrice = one] : one \in Sample(7) }
        \cup { [ZeroInstrumentDescription8 EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDescription8 EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentDescription8 EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Option Improvement Process Beginning Message: 73 bytes                  *)
(***************************************************************************)

OptionImprovementProcessBeginningMessage ==
    [ exchangeId                         : Sample(1),
      instrumentDescription              : InstrumentDescription8,
      improvementPhaseSequentialNumber   : Sample(6),
      initialOrderPrice                  : Sample(6),
      initialOrderPriceFractionIndicator : Sample(1),
      initialOrderQuantity               : Sample(8),
      initialOrderSide                   : Sample(1),
      improvementPhaseExpiryTime         : Sample(8),
      improvementProcessExpiryDuration   : Sample(4),
      minimumQuantityForImprovementOrder : Sample(8),
      percentageAssuredToInitialOrder    : Sample(8),
      auctionType                        : Sample(1),
      filler1                            : Sample(1) ]

EncodeOptionImprovementProcessBeginningMessage(message) ==
    message.exchangeId
        \o EncodeInstrumentDescription8(message.instrumentDescription)
        \o message.improvementPhaseSequentialNumber
        \o message.initialOrderPrice
        \o message.initialOrderPriceFractionIndicator
        \o message.initialOrderQuantity
        \o message.initialOrderSide
        \o message.improvementPhaseExpiryTime
        \o message.improvementProcessExpiryDuration
        \o message.minimumQuantityForImprovementOrder
        \o message.percentageAssuredToInitialOrder
        \o message.auctionType
        \o message.filler1

DecodeOptionImprovementProcessBeginningMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET instrumentDescription == DecodeInstrumentDescription8(exchangeId.rest) IN IF ~instrumentDescription.ok THEN Fail ELSE
    LET improvementPhaseSequentialNumber == ReadBytes(instrumentDescription.rest, 6) IN IF ~improvementPhaseSequentialNumber.ok THEN Fail ELSE
    LET initialOrderPrice == ReadBytes(improvementPhaseSequentialNumber.rest, 6) IN IF ~initialOrderPrice.ok THEN Fail ELSE
    LET initialOrderPriceFractionIndicator == ReadBytes(initialOrderPrice.rest, 1) IN IF ~initialOrderPriceFractionIndicator.ok THEN Fail ELSE
    LET initialOrderQuantity == ReadBytes(initialOrderPriceFractionIndicator.rest, 8) IN IF ~initialOrderQuantity.ok THEN Fail ELSE
    LET initialOrderSide == ReadBytes(initialOrderQuantity.rest, 1) IN IF ~initialOrderSide.ok THEN Fail ELSE
    LET improvementPhaseExpiryTime == ReadBytes(initialOrderSide.rest, 8) IN IF ~improvementPhaseExpiryTime.ok THEN Fail ELSE
    LET improvementProcessExpiryDuration == ReadBytes(improvementPhaseExpiryTime.rest, 4) IN IF ~improvementProcessExpiryDuration.ok THEN Fail ELSE
    LET minimumQuantityForImprovementOrder == ReadBytes(improvementProcessExpiryDuration.rest, 8) IN IF ~minimumQuantityForImprovementOrder.ok THEN Fail ELSE
    LET percentageAssuredToInitialOrder == ReadBytes(minimumQuantityForImprovementOrder.rest, 8) IN IF ~percentageAssuredToInitialOrder.ok THEN Fail ELSE
    LET auctionType == ReadBytes(percentageAssuredToInitialOrder.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET filler1 == ReadBytes(auctionType.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    Ok([ exchangeId                         |-> exchangeId.value,
         instrumentDescription              |-> instrumentDescription.value,
         improvementPhaseSequentialNumber   |-> improvementPhaseSequentialNumber.value,
         initialOrderPrice                  |-> initialOrderPrice.value,
         initialOrderPriceFractionIndicator |-> initialOrderPriceFractionIndicator.value,
         initialOrderQuantity               |-> initialOrderQuantity.value,
         initialOrderSide                   |-> initialOrderSide.value,
         improvementPhaseExpiryTime         |-> improvementPhaseExpiryTime.value,
         improvementProcessExpiryDuration   |-> improvementProcessExpiryDuration.value,
         minimumQuantityForImprovementOrder |-> minimumQuantityForImprovementOrder.value,
         percentageAssuredToInitialOrder    |-> percentageAssuredToInitialOrder.value,
         auctionType                        |-> auctionType.value,
         filler1                            |-> filler1.value ], filler1.rest)

ZeroOptionImprovementProcessBeginningMessage ==
    [ exchangeId                         |-> [i \in 1 .. 1 |-> 0],
      instrumentDescription              |-> ZeroInstrumentDescription8,
      improvementPhaseSequentialNumber   |-> [i \in 1 .. 6 |-> 0],
      initialOrderPrice                  |-> [i \in 1 .. 6 |-> 0],
      initialOrderPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      initialOrderQuantity               |-> [i \in 1 .. 8 |-> 0],
      initialOrderSide                   |-> [i \in 1 .. 1 |-> 0],
      improvementPhaseExpiryTime         |-> [i \in 1 .. 8 |-> 0],
      improvementProcessExpiryDuration   |-> [i \in 1 .. 4 |-> 0],
      minimumQuantityForImprovementOrder |-> [i \in 1 .. 8 |-> 0],
      percentageAssuredToInitialOrder    |-> [i \in 1 .. 8 |-> 0],
      auctionType                        |-> [i \in 1 .. 1 |-> 0],
      filler1                            |-> [i \in 1 .. 1 |-> 0] ]

(* Option Improvement Process Beginning Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionImprovementProcessBeginningMessage ==
    { ZeroOptionImprovementProcessBeginningMessage }
        \cup { [ZeroOptionImprovementProcessBeginningMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroOptionImprovementProcessBeginningMessage EXCEPT !.instrumentDescription = one] : one \in CheckedInstrumentDescription8 }
        \cup { [ZeroOptionImprovementProcessBeginningMessage EXCEPT !.improvementPhaseSequentialNumber = one] : one \in Sample(6) }
        \cup { [ZeroOptionImprovementProcessBeginningMessage EXCEPT !.initialOrderPrice = one] : one \in Sample(6) }
        \cup { [ZeroOptionImprovementProcessBeginningMessage EXCEPT !.initialOrderPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionImprovementProcessBeginningMessage EXCEPT !.initialOrderQuantity = one] : one \in Sample(8) }
        \cup { [ZeroOptionImprovementProcessBeginningMessage EXCEPT !.initialOrderSide = one] : one \in Sample(1) }
        \cup { [ZeroOptionImprovementProcessBeginningMessage EXCEPT !.improvementPhaseExpiryTime = one] : one \in Sample(8) }
        \cup { [ZeroOptionImprovementProcessBeginningMessage EXCEPT !.improvementProcessExpiryDuration = one] : one \in Sample(4) }
        \cup { [ZeroOptionImprovementProcessBeginningMessage EXCEPT !.minimumQuantityForImprovementOrder = one] : one \in Sample(8) }
        \cup { [ZeroOptionImprovementProcessBeginningMessage EXCEPT !.percentageAssuredToInitialOrder = one] : one \in Sample(8) }
        \cup { [ZeroOptionImprovementProcessBeginningMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroOptionImprovementProcessBeginningMessage EXCEPT !.filler1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Complex Order Improvement Process Beginning Message Message: 83 bytes   *)
(***************************************************************************)

ComplexOrderImprovementProcessBeginningMessageMessage ==
    [ exchangeId                         : Sample(1),
      complexOrderInstrumentSymbol       : Sample(30),
      improvementPhaseSequentialNumber   : Sample(6),
      initialOrderPriceSign              : Sample(1),
      initialOrderPrice                  : Sample(6),
      initialOrderPriceFractionIndicator : Sample(1),
      initialOrderQuantity               : Sample(8),
      initialOrderSide                   : Sample(1),
      improvementPhaseExpiryTime         : Sample(8),
      improvementProcessExpiryDuration   : Sample(4),
      minimumQuantityForImprovementOrder : Sample(8),
      percentageAssuredToInitialOrder    : Sample(8),
      auctionType                        : Sample(1) ]

EncodeComplexOrderImprovementProcessBeginningMessageMessage(message) ==
    message.exchangeId
        \o message.complexOrderInstrumentSymbol
        \o message.improvementPhaseSequentialNumber
        \o message.initialOrderPriceSign
        \o message.initialOrderPrice
        \o message.initialOrderPriceFractionIndicator
        \o message.initialOrderQuantity
        \o message.initialOrderSide
        \o message.improvementPhaseExpiryTime
        \o message.improvementProcessExpiryDuration
        \o message.minimumQuantityForImprovementOrder
        \o message.percentageAssuredToInitialOrder
        \o message.auctionType

DecodeComplexOrderImprovementProcessBeginningMessageMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET complexOrderInstrumentSymbol == ReadBytes(exchangeId.rest, 30) IN IF ~complexOrderInstrumentSymbol.ok THEN Fail ELSE
    LET improvementPhaseSequentialNumber == ReadBytes(complexOrderInstrumentSymbol.rest, 6) IN IF ~improvementPhaseSequentialNumber.ok THEN Fail ELSE
    LET initialOrderPriceSign == ReadBytes(improvementPhaseSequentialNumber.rest, 1) IN IF ~initialOrderPriceSign.ok THEN Fail ELSE
    LET initialOrderPrice == ReadBytes(initialOrderPriceSign.rest, 6) IN IF ~initialOrderPrice.ok THEN Fail ELSE
    LET initialOrderPriceFractionIndicator == ReadBytes(initialOrderPrice.rest, 1) IN IF ~initialOrderPriceFractionIndicator.ok THEN Fail ELSE
    LET initialOrderQuantity == ReadBytes(initialOrderPriceFractionIndicator.rest, 8) IN IF ~initialOrderQuantity.ok THEN Fail ELSE
    LET initialOrderSide == ReadBytes(initialOrderQuantity.rest, 1) IN IF ~initialOrderSide.ok THEN Fail ELSE
    LET improvementPhaseExpiryTime == ReadBytes(initialOrderSide.rest, 8) IN IF ~improvementPhaseExpiryTime.ok THEN Fail ELSE
    LET improvementProcessExpiryDuration == ReadBytes(improvementPhaseExpiryTime.rest, 4) IN IF ~improvementProcessExpiryDuration.ok THEN Fail ELSE
    LET minimumQuantityForImprovementOrder == ReadBytes(improvementProcessExpiryDuration.rest, 8) IN IF ~minimumQuantityForImprovementOrder.ok THEN Fail ELSE
    LET percentageAssuredToInitialOrder == ReadBytes(minimumQuantityForImprovementOrder.rest, 8) IN IF ~percentageAssuredToInitialOrder.ok THEN Fail ELSE
    LET auctionType == ReadBytes(percentageAssuredToInitialOrder.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    Ok([ exchangeId                         |-> exchangeId.value,
         complexOrderInstrumentSymbol       |-> complexOrderInstrumentSymbol.value,
         improvementPhaseSequentialNumber   |-> improvementPhaseSequentialNumber.value,
         initialOrderPriceSign              |-> initialOrderPriceSign.value,
         initialOrderPrice                  |-> initialOrderPrice.value,
         initialOrderPriceFractionIndicator |-> initialOrderPriceFractionIndicator.value,
         initialOrderQuantity               |-> initialOrderQuantity.value,
         initialOrderSide                   |-> initialOrderSide.value,
         improvementPhaseExpiryTime         |-> improvementPhaseExpiryTime.value,
         improvementProcessExpiryDuration   |-> improvementProcessExpiryDuration.value,
         minimumQuantityForImprovementOrder |-> minimumQuantityForImprovementOrder.value,
         percentageAssuredToInitialOrder    |-> percentageAssuredToInitialOrder.value,
         auctionType                        |-> auctionType.value ], auctionType.rest)

ZeroComplexOrderImprovementProcessBeginningMessageMessage ==
    [ exchangeId                         |-> [i \in 1 .. 1 |-> 0],
      complexOrderInstrumentSymbol       |-> [i \in 1 .. 30 |-> 0],
      improvementPhaseSequentialNumber   |-> [i \in 1 .. 6 |-> 0],
      initialOrderPriceSign              |-> [i \in 1 .. 1 |-> 0],
      initialOrderPrice                  |-> [i \in 1 .. 6 |-> 0],
      initialOrderPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      initialOrderQuantity               |-> [i \in 1 .. 8 |-> 0],
      initialOrderSide                   |-> [i \in 1 .. 1 |-> 0],
      improvementPhaseExpiryTime         |-> [i \in 1 .. 8 |-> 0],
      improvementProcessExpiryDuration   |-> [i \in 1 .. 4 |-> 0],
      minimumQuantityForImprovementOrder |-> [i \in 1 .. 8 |-> 0],
      percentageAssuredToInitialOrder    |-> [i \in 1 .. 8 |-> 0],
      auctionType                        |-> [i \in 1 .. 1 |-> 0] ]

(* Complex Order Improvement Process Beginning Message Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexOrderImprovementProcessBeginningMessageMessage ==
    { ZeroComplexOrderImprovementProcessBeginningMessageMessage }
        \cup { [ZeroComplexOrderImprovementProcessBeginningMessageMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderImprovementProcessBeginningMessageMessage EXCEPT !.complexOrderInstrumentSymbol = one] : one \in Sample(30) }
        \cup { [ZeroComplexOrderImprovementProcessBeginningMessageMessage EXCEPT !.improvementPhaseSequentialNumber = one] : one \in Sample(6) }
        \cup { [ZeroComplexOrderImprovementProcessBeginningMessageMessage EXCEPT !.initialOrderPriceSign = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderImprovementProcessBeginningMessageMessage EXCEPT !.initialOrderPrice = one] : one \in Sample(6) }
        \cup { [ZeroComplexOrderImprovementProcessBeginningMessageMessage EXCEPT !.initialOrderPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderImprovementProcessBeginningMessageMessage EXCEPT !.initialOrderQuantity = one] : one \in Sample(8) }
        \cup { [ZeroComplexOrderImprovementProcessBeginningMessageMessage EXCEPT !.initialOrderSide = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderImprovementProcessBeginningMessageMessage EXCEPT !.improvementPhaseExpiryTime = one] : one \in Sample(8) }
        \cup { [ZeroComplexOrderImprovementProcessBeginningMessageMessage EXCEPT !.improvementProcessExpiryDuration = one] : one \in Sample(4) }
        \cup { [ZeroComplexOrderImprovementProcessBeginningMessageMessage EXCEPT !.minimumQuantityForImprovementOrder = one] : one \in Sample(8) }
        \cup { [ZeroComplexOrderImprovementProcessBeginningMessageMessage EXCEPT !.percentageAssuredToInitialOrder = one] : one \in Sample(8) }
        \cup { [ZeroComplexOrderImprovementProcessBeginningMessageMessage EXCEPT !.auctionType = one] : one \in Sample(1) }

(***************************************************************************)
(* Instrument Description: 20 bytes                                        *)
(***************************************************************************)

InstrumentDescription9 ==
    [ rootSymbol                   : Sample(6),
      expiryMonthCode              : Sample(1),
      filler1                      : Sample(1),
      strikePrice                  : Sample(7),
      strikePriceFractionIndicator : Sample(1),
      expiryYear                   : Sample(2),
      expiryDay                    : Sample(2) ]

EncodeInstrumentDescription9(message) ==
    message.rootSymbol
        \o message.expiryMonthCode
        \o message.filler1
        \o message.strikePrice
        \o message.strikePriceFractionIndicator
        \o message.expiryYear
        \o message.expiryDay

DecodeInstrumentDescription9(bytes) ==
    LET rootSymbol == ReadBytes(bytes, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET expiryMonthCode == ReadBytes(rootSymbol.rest, 1) IN IF ~expiryMonthCode.ok THEN Fail ELSE
    LET filler1 == ReadBytes(expiryMonthCode.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(filler1.rest, 7) IN IF ~strikePrice.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePrice.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(strikePriceFractionIndicator.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ rootSymbol                   |-> rootSymbol.value,
         expiryMonthCode              |-> expiryMonthCode.value,
         filler1                      |-> filler1.value,
         strikePrice                  |-> strikePrice.value,
         strikePriceFractionIndicator |-> strikePriceFractionIndicator.value,
         expiryYear                   |-> expiryYear.value,
         expiryDay                    |-> expiryDay.value ], expiryDay.rest)

ZeroInstrumentDescription9 ==
    [ rootSymbol                   |-> [i \in 1 .. 6 |-> 0],
      expiryMonthCode              |-> [i \in 1 .. 1 |-> 0],
      filler1                      |-> [i \in 1 .. 1 |-> 0],
      strikePrice                  |-> [i \in 1 .. 7 |-> 0],
      strikePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      expiryYear                   |-> [i \in 1 .. 2 |-> 0],
      expiryDay                    |-> [i \in 1 .. 2 |-> 0] ]

(* Instrument Description at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentDescription9 ==
    { ZeroInstrumentDescription9 }
        \cup { [ZeroInstrumentDescription9 EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroInstrumentDescription9 EXCEPT !.expiryMonthCode = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDescription9 EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDescription9 EXCEPT !.strikePrice = one] : one \in Sample(7) }
        \cup { [ZeroInstrumentDescription9 EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDescription9 EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentDescription9 EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Market Sheet Initial And Improvement Order Message: 69 bytes            *)
(***************************************************************************)

MarketSheetInitialAndImprovementOrderMessage ==
    [ exchangeId                       : Sample(1),
      instrumentDescription            : InstrumentDescription9,
      orderSide                        : Sample(1),
      typeOfOrder                      : Sample(1),
      limitEnteredForAnOrder           : Sample(6),
      limitFractionIndicator           : Sample(1),
      orderQuantity                    : Sample(8),
      orderSequenceNumber              : Sample(6),
      improvementPhaseSequentialNumber : Sample(6),
      typeOfClearingAccount            : Sample(1),
      filler1                          : Sample(1),
      endOfTheExposition               : Sample(8),
      auctionType                      : Sample(1),
      firmId                           : Sample(4),
      cmta                             : Sample(4) ]

EncodeMarketSheetInitialAndImprovementOrderMessage(message) ==
    message.exchangeId
        \o EncodeInstrumentDescription9(message.instrumentDescription)
        \o message.orderSide
        \o message.typeOfOrder
        \o message.limitEnteredForAnOrder
        \o message.limitFractionIndicator
        \o message.orderQuantity
        \o message.orderSequenceNumber
        \o message.improvementPhaseSequentialNumber
        \o message.typeOfClearingAccount
        \o message.filler1
        \o message.endOfTheExposition
        \o message.auctionType
        \o message.firmId
        \o message.cmta

DecodeMarketSheetInitialAndImprovementOrderMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET instrumentDescription == DecodeInstrumentDescription9(exchangeId.rest) IN IF ~instrumentDescription.ok THEN Fail ELSE
    LET orderSide == ReadBytes(instrumentDescription.rest, 1) IN IF ~orderSide.ok THEN Fail ELSE
    LET typeOfOrder == ReadBytes(orderSide.rest, 1) IN IF ~typeOfOrder.ok THEN Fail ELSE
    LET limitEnteredForAnOrder == ReadBytes(typeOfOrder.rest, 6) IN IF ~limitEnteredForAnOrder.ok THEN Fail ELSE
    LET limitFractionIndicator == ReadBytes(limitEnteredForAnOrder.rest, 1) IN IF ~limitFractionIndicator.ok THEN Fail ELSE
    LET orderQuantity == ReadBytes(limitFractionIndicator.rest, 8) IN IF ~orderQuantity.ok THEN Fail ELSE
    LET orderSequenceNumber == ReadBytes(orderQuantity.rest, 6) IN IF ~orderSequenceNumber.ok THEN Fail ELSE
    LET improvementPhaseSequentialNumber == ReadBytes(orderSequenceNumber.rest, 6) IN IF ~improvementPhaseSequentialNumber.ok THEN Fail ELSE
    LET typeOfClearingAccount == ReadBytes(improvementPhaseSequentialNumber.rest, 1) IN IF ~typeOfClearingAccount.ok THEN Fail ELSE
    LET filler1 == ReadBytes(typeOfClearingAccount.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET endOfTheExposition == ReadBytes(filler1.rest, 8) IN IF ~endOfTheExposition.ok THEN Fail ELSE
    LET auctionType == ReadBytes(endOfTheExposition.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET firmId == ReadBytes(auctionType.rest, 4) IN IF ~firmId.ok THEN Fail ELSE
    LET cmta == ReadBytes(firmId.rest, 4) IN IF ~cmta.ok THEN Fail ELSE
    Ok([ exchangeId                       |-> exchangeId.value,
         instrumentDescription            |-> instrumentDescription.value,
         orderSide                        |-> orderSide.value,
         typeOfOrder                      |-> typeOfOrder.value,
         limitEnteredForAnOrder           |-> limitEnteredForAnOrder.value,
         limitFractionIndicator           |-> limitFractionIndicator.value,
         orderQuantity                    |-> orderQuantity.value,
         orderSequenceNumber              |-> orderSequenceNumber.value,
         improvementPhaseSequentialNumber |-> improvementPhaseSequentialNumber.value,
         typeOfClearingAccount            |-> typeOfClearingAccount.value,
         filler1                          |-> filler1.value,
         endOfTheExposition               |-> endOfTheExposition.value,
         auctionType                      |-> auctionType.value,
         firmId                           |-> firmId.value,
         cmta                             |-> cmta.value ], cmta.rest)

ZeroMarketSheetInitialAndImprovementOrderMessage ==
    [ exchangeId                       |-> [i \in 1 .. 1 |-> 0],
      instrumentDescription            |-> ZeroInstrumentDescription9,
      orderSide                        |-> [i \in 1 .. 1 |-> 0],
      typeOfOrder                      |-> [i \in 1 .. 1 |-> 0],
      limitEnteredForAnOrder           |-> [i \in 1 .. 6 |-> 0],
      limitFractionIndicator           |-> [i \in 1 .. 1 |-> 0],
      orderQuantity                    |-> [i \in 1 .. 8 |-> 0],
      orderSequenceNumber              |-> [i \in 1 .. 6 |-> 0],
      improvementPhaseSequentialNumber |-> [i \in 1 .. 6 |-> 0],
      typeOfClearingAccount            |-> [i \in 1 .. 1 |-> 0],
      filler1                          |-> [i \in 1 .. 1 |-> 0],
      endOfTheExposition               |-> [i \in 1 .. 8 |-> 0],
      auctionType                      |-> [i \in 1 .. 1 |-> 0],
      firmId                           |-> [i \in 1 .. 4 |-> 0],
      cmta                             |-> [i \in 1 .. 4 |-> 0] ]

(* Market Sheet Initial And Improvement Order Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketSheetInitialAndImprovementOrderMessage ==
    { ZeroMarketSheetInitialAndImprovementOrderMessage }
        \cup { [ZeroMarketSheetInitialAndImprovementOrderMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroMarketSheetInitialAndImprovementOrderMessage EXCEPT !.instrumentDescription = one] : one \in CheckedInstrumentDescription9 }
        \cup { [ZeroMarketSheetInitialAndImprovementOrderMessage EXCEPT !.orderSide = one] : one \in Sample(1) }
        \cup { [ZeroMarketSheetInitialAndImprovementOrderMessage EXCEPT !.typeOfOrder = one] : one \in Sample(1) }
        \cup { [ZeroMarketSheetInitialAndImprovementOrderMessage EXCEPT !.limitEnteredForAnOrder = one] : one \in Sample(6) }
        \cup { [ZeroMarketSheetInitialAndImprovementOrderMessage EXCEPT !.limitFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMarketSheetInitialAndImprovementOrderMessage EXCEPT !.orderQuantity = one] : one \in Sample(8) }
        \cup { [ZeroMarketSheetInitialAndImprovementOrderMessage EXCEPT !.orderSequenceNumber = one] : one \in Sample(6) }
        \cup { [ZeroMarketSheetInitialAndImprovementOrderMessage EXCEPT !.improvementPhaseSequentialNumber = one] : one \in Sample(6) }
        \cup { [ZeroMarketSheetInitialAndImprovementOrderMessage EXCEPT !.typeOfClearingAccount = one] : one \in Sample(1) }
        \cup { [ZeroMarketSheetInitialAndImprovementOrderMessage EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroMarketSheetInitialAndImprovementOrderMessage EXCEPT !.endOfTheExposition = one] : one \in Sample(8) }
        \cup { [ZeroMarketSheetInitialAndImprovementOrderMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroMarketSheetInitialAndImprovementOrderMessage EXCEPT !.firmId = one] : one \in Sample(4) }
        \cup { [ZeroMarketSheetInitialAndImprovementOrderMessage EXCEPT !.cmta = one] : one \in Sample(4) }

(***************************************************************************)
(* Complex Order Market Sheet Initial And Improvement Order Message: 80    *)
(* bytes                                                                   *)
(***************************************************************************)

ComplexOrderMarketSheetInitialAndImprovementOrderMessage ==
    [ exchangeId                       : Sample(1),
      complexOrderInstrumentSymbol     : Sample(30),
      orderSide                        : Sample(1),
      typeOfOrder                      : Sample(1),
      limitEnteredForAnOrderSign       : Sample(1),
      limitEnteredForAnOrder           : Sample(6),
      limitFractionIndicator           : Sample(1),
      orderQuantity                    : Sample(8),
      orderSequenceNumber              : Sample(6),
      improvementPhaseSequentialNumber : Sample(6),
      typeOfClearingAccount            : Sample(1),
      filler1                          : Sample(1),
      endOfTheExposition               : Sample(8),
      auctionType                      : Sample(1),
      firmId                           : Sample(4),
      cmta                             : Sample(4) ]

EncodeComplexOrderMarketSheetInitialAndImprovementOrderMessage(message) ==
    message.exchangeId
        \o message.complexOrderInstrumentSymbol
        \o message.orderSide
        \o message.typeOfOrder
        \o message.limitEnteredForAnOrderSign
        \o message.limitEnteredForAnOrder
        \o message.limitFractionIndicator
        \o message.orderQuantity
        \o message.orderSequenceNumber
        \o message.improvementPhaseSequentialNumber
        \o message.typeOfClearingAccount
        \o message.filler1
        \o message.endOfTheExposition
        \o message.auctionType
        \o message.firmId
        \o message.cmta

DecodeComplexOrderMarketSheetInitialAndImprovementOrderMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET complexOrderInstrumentSymbol == ReadBytes(exchangeId.rest, 30) IN IF ~complexOrderInstrumentSymbol.ok THEN Fail ELSE
    LET orderSide == ReadBytes(complexOrderInstrumentSymbol.rest, 1) IN IF ~orderSide.ok THEN Fail ELSE
    LET typeOfOrder == ReadBytes(orderSide.rest, 1) IN IF ~typeOfOrder.ok THEN Fail ELSE
    LET limitEnteredForAnOrderSign == ReadBytes(typeOfOrder.rest, 1) IN IF ~limitEnteredForAnOrderSign.ok THEN Fail ELSE
    LET limitEnteredForAnOrder == ReadBytes(limitEnteredForAnOrderSign.rest, 6) IN IF ~limitEnteredForAnOrder.ok THEN Fail ELSE
    LET limitFractionIndicator == ReadBytes(limitEnteredForAnOrder.rest, 1) IN IF ~limitFractionIndicator.ok THEN Fail ELSE
    LET orderQuantity == ReadBytes(limitFractionIndicator.rest, 8) IN IF ~orderQuantity.ok THEN Fail ELSE
    LET orderSequenceNumber == ReadBytes(orderQuantity.rest, 6) IN IF ~orderSequenceNumber.ok THEN Fail ELSE
    LET improvementPhaseSequentialNumber == ReadBytes(orderSequenceNumber.rest, 6) IN IF ~improvementPhaseSequentialNumber.ok THEN Fail ELSE
    LET typeOfClearingAccount == ReadBytes(improvementPhaseSequentialNumber.rest, 1) IN IF ~typeOfClearingAccount.ok THEN Fail ELSE
    LET filler1 == ReadBytes(typeOfClearingAccount.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET endOfTheExposition == ReadBytes(filler1.rest, 8) IN IF ~endOfTheExposition.ok THEN Fail ELSE
    LET auctionType == ReadBytes(endOfTheExposition.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET firmId == ReadBytes(auctionType.rest, 4) IN IF ~firmId.ok THEN Fail ELSE
    LET cmta == ReadBytes(firmId.rest, 4) IN IF ~cmta.ok THEN Fail ELSE
    Ok([ exchangeId                       |-> exchangeId.value,
         complexOrderInstrumentSymbol     |-> complexOrderInstrumentSymbol.value,
         orderSide                        |-> orderSide.value,
         typeOfOrder                      |-> typeOfOrder.value,
         limitEnteredForAnOrderSign       |-> limitEnteredForAnOrderSign.value,
         limitEnteredForAnOrder           |-> limitEnteredForAnOrder.value,
         limitFractionIndicator           |-> limitFractionIndicator.value,
         orderQuantity                    |-> orderQuantity.value,
         orderSequenceNumber              |-> orderSequenceNumber.value,
         improvementPhaseSequentialNumber |-> improvementPhaseSequentialNumber.value,
         typeOfClearingAccount            |-> typeOfClearingAccount.value,
         filler1                          |-> filler1.value,
         endOfTheExposition               |-> endOfTheExposition.value,
         auctionType                      |-> auctionType.value,
         firmId                           |-> firmId.value,
         cmta                             |-> cmta.value ], cmta.rest)

ZeroComplexOrderMarketSheetInitialAndImprovementOrderMessage ==
    [ exchangeId                       |-> [i \in 1 .. 1 |-> 0],
      complexOrderInstrumentSymbol     |-> [i \in 1 .. 30 |-> 0],
      orderSide                        |-> [i \in 1 .. 1 |-> 0],
      typeOfOrder                      |-> [i \in 1 .. 1 |-> 0],
      limitEnteredForAnOrderSign       |-> [i \in 1 .. 1 |-> 0],
      limitEnteredForAnOrder           |-> [i \in 1 .. 6 |-> 0],
      limitFractionIndicator           |-> [i \in 1 .. 1 |-> 0],
      orderQuantity                    |-> [i \in 1 .. 8 |-> 0],
      orderSequenceNumber              |-> [i \in 1 .. 6 |-> 0],
      improvementPhaseSequentialNumber |-> [i \in 1 .. 6 |-> 0],
      typeOfClearingAccount            |-> [i \in 1 .. 1 |-> 0],
      filler1                          |-> [i \in 1 .. 1 |-> 0],
      endOfTheExposition               |-> [i \in 1 .. 8 |-> 0],
      auctionType                      |-> [i \in 1 .. 1 |-> 0],
      firmId                           |-> [i \in 1 .. 4 |-> 0],
      cmta                             |-> [i \in 1 .. 4 |-> 0] ]

(* Complex Order Market Sheet Initial And Improvement Order Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexOrderMarketSheetInitialAndImprovementOrderMessage ==
    { ZeroComplexOrderMarketSheetInitialAndImprovementOrderMessage }
        \cup { [ZeroComplexOrderMarketSheetInitialAndImprovementOrderMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderMarketSheetInitialAndImprovementOrderMessage EXCEPT !.complexOrderInstrumentSymbol = one] : one \in Sample(30) }
        \cup { [ZeroComplexOrderMarketSheetInitialAndImprovementOrderMessage EXCEPT !.orderSide = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderMarketSheetInitialAndImprovementOrderMessage EXCEPT !.typeOfOrder = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderMarketSheetInitialAndImprovementOrderMessage EXCEPT !.limitEnteredForAnOrderSign = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderMarketSheetInitialAndImprovementOrderMessage EXCEPT !.limitEnteredForAnOrder = one] : one \in Sample(6) }
        \cup { [ZeroComplexOrderMarketSheetInitialAndImprovementOrderMessage EXCEPT !.limitFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderMarketSheetInitialAndImprovementOrderMessage EXCEPT !.orderQuantity = one] : one \in Sample(8) }
        \cup { [ZeroComplexOrderMarketSheetInitialAndImprovementOrderMessage EXCEPT !.orderSequenceNumber = one] : one \in Sample(6) }
        \cup { [ZeroComplexOrderMarketSheetInitialAndImprovementOrderMessage EXCEPT !.improvementPhaseSequentialNumber = one] : one \in Sample(6) }
        \cup { [ZeroComplexOrderMarketSheetInitialAndImprovementOrderMessage EXCEPT !.typeOfClearingAccount = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderMarketSheetInitialAndImprovementOrderMessage EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderMarketSheetInitialAndImprovementOrderMessage EXCEPT !.endOfTheExposition = one] : one \in Sample(8) }
        \cup { [ZeroComplexOrderMarketSheetInitialAndImprovementOrderMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderMarketSheetInitialAndImprovementOrderMessage EXCEPT !.firmId = one] : one \in Sample(4) }
        \cup { [ZeroComplexOrderMarketSheetInitialAndImprovementOrderMessage EXCEPT !.cmta = one] : one \in Sample(4) }

(***************************************************************************)
(* Instrument Description: 20 bytes                                        *)
(***************************************************************************)

InstrumentDescription10 ==
    [ rootSymbol                   : Sample(6),
      expiryMonthCode              : Sample(1),
      filler1                      : Sample(1),
      strikePrice                  : Sample(7),
      strikePriceFractionIndicator : Sample(1),
      expiryYear                   : Sample(2),
      expiryDay                    : Sample(2) ]

EncodeInstrumentDescription10(message) ==
    message.rootSymbol
        \o message.expiryMonthCode
        \o message.filler1
        \o message.strikePrice
        \o message.strikePriceFractionIndicator
        \o message.expiryYear
        \o message.expiryDay

DecodeInstrumentDescription10(bytes) ==
    LET rootSymbol == ReadBytes(bytes, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET expiryMonthCode == ReadBytes(rootSymbol.rest, 1) IN IF ~expiryMonthCode.ok THEN Fail ELSE
    LET filler1 == ReadBytes(expiryMonthCode.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(filler1.rest, 7) IN IF ~strikePrice.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePrice.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(strikePriceFractionIndicator.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ rootSymbol                   |-> rootSymbol.value,
         expiryMonthCode              |-> expiryMonthCode.value,
         filler1                      |-> filler1.value,
         strikePrice                  |-> strikePrice.value,
         strikePriceFractionIndicator |-> strikePriceFractionIndicator.value,
         expiryYear                   |-> expiryYear.value,
         expiryDay                    |-> expiryDay.value ], expiryDay.rest)

ZeroInstrumentDescription10 ==
    [ rootSymbol                   |-> [i \in 1 .. 6 |-> 0],
      expiryMonthCode              |-> [i \in 1 .. 1 |-> 0],
      filler1                      |-> [i \in 1 .. 1 |-> 0],
      strikePrice                  |-> [i \in 1 .. 7 |-> 0],
      strikePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      expiryYear                   |-> [i \in 1 .. 2 |-> 0],
      expiryDay                    |-> [i \in 1 .. 2 |-> 0] ]

(* Instrument Description at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentDescription10 ==
    { ZeroInstrumentDescription10 }
        \cup { [ZeroInstrumentDescription10 EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroInstrumentDescription10 EXCEPT !.expiryMonthCode = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDescription10 EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDescription10 EXCEPT !.strikePrice = one] : one \in Sample(7) }
        \cup { [ZeroInstrumentDescription10 EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDescription10 EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentDescription10 EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Initial And Improvement Order Message: 36 bytes                         *)
(***************************************************************************)

InitialAndImprovementOrderMessage ==
    [ exchangeId                       : Sample(1),
      instrumentDescription            : InstrumentDescription10,
      deletionType                     : Sample(1),
      orderSequenceNumber              : Sample(6),
      improvementOrderSide             : Sample(1),
      improvementPhaseSequentialNumber : Sample(6),
      auctionType                      : Sample(1) ]

EncodeInitialAndImprovementOrderMessage(message) ==
    message.exchangeId
        \o EncodeInstrumentDescription10(message.instrumentDescription)
        \o message.deletionType
        \o message.orderSequenceNumber
        \o message.improvementOrderSide
        \o message.improvementPhaseSequentialNumber
        \o message.auctionType

DecodeInitialAndImprovementOrderMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET instrumentDescription == DecodeInstrumentDescription10(exchangeId.rest) IN IF ~instrumentDescription.ok THEN Fail ELSE
    LET deletionType == ReadBytes(instrumentDescription.rest, 1) IN IF ~deletionType.ok THEN Fail ELSE
    LET orderSequenceNumber == ReadBytes(deletionType.rest, 6) IN IF ~orderSequenceNumber.ok THEN Fail ELSE
    LET improvementOrderSide == ReadBytes(orderSequenceNumber.rest, 1) IN IF ~improvementOrderSide.ok THEN Fail ELSE
    LET improvementPhaseSequentialNumber == ReadBytes(improvementOrderSide.rest, 6) IN IF ~improvementPhaseSequentialNumber.ok THEN Fail ELSE
    LET auctionType == ReadBytes(improvementPhaseSequentialNumber.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    Ok([ exchangeId                       |-> exchangeId.value,
         instrumentDescription            |-> instrumentDescription.value,
         deletionType                     |-> deletionType.value,
         orderSequenceNumber              |-> orderSequenceNumber.value,
         improvementOrderSide             |-> improvementOrderSide.value,
         improvementPhaseSequentialNumber |-> improvementPhaseSequentialNumber.value,
         auctionType                      |-> auctionType.value ], auctionType.rest)

ZeroInitialAndImprovementOrderMessage ==
    [ exchangeId                       |-> [i \in 1 .. 1 |-> 0],
      instrumentDescription            |-> ZeroInstrumentDescription10,
      deletionType                     |-> [i \in 1 .. 1 |-> 0],
      orderSequenceNumber              |-> [i \in 1 .. 6 |-> 0],
      improvementOrderSide             |-> [i \in 1 .. 1 |-> 0],
      improvementPhaseSequentialNumber |-> [i \in 1 .. 6 |-> 0],
      auctionType                      |-> [i \in 1 .. 1 |-> 0] ]

(* Initial And Improvement Order Message at zero, then each field in turn at the values it is checked at *)
CheckedInitialAndImprovementOrderMessage ==
    { ZeroInitialAndImprovementOrderMessage }
        \cup { [ZeroInitialAndImprovementOrderMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroInitialAndImprovementOrderMessage EXCEPT !.instrumentDescription = one] : one \in CheckedInstrumentDescription10 }
        \cup { [ZeroInitialAndImprovementOrderMessage EXCEPT !.deletionType = one] : one \in Sample(1) }
        \cup { [ZeroInitialAndImprovementOrderMessage EXCEPT !.orderSequenceNumber = one] : one \in Sample(6) }
        \cup { [ZeroInitialAndImprovementOrderMessage EXCEPT !.improvementOrderSide = one] : one \in Sample(1) }
        \cup { [ZeroInitialAndImprovementOrderMessage EXCEPT !.improvementPhaseSequentialNumber = one] : one \in Sample(6) }
        \cup { [ZeroInitialAndImprovementOrderMessage EXCEPT !.auctionType = one] : one \in Sample(1) }

(***************************************************************************)
(* Complex Order Initial And Improvement Order Message: 46 bytes           *)
(***************************************************************************)

ComplexOrderInitialAndImprovementOrderMessage ==
    [ exchangeId                       : Sample(1),
      complexOrderInstrumentSymbol     : Sample(30),
      deletionType                     : Sample(1),
      orderSequenceNumber              : Sample(6),
      orderSide                        : Sample(1),
      improvementPhaseSequentialNumber : Sample(6),
      auctionType                      : Sample(1) ]

EncodeComplexOrderInitialAndImprovementOrderMessage(message) ==
    message.exchangeId
        \o message.complexOrderInstrumentSymbol
        \o message.deletionType
        \o message.orderSequenceNumber
        \o message.orderSide
        \o message.improvementPhaseSequentialNumber
        \o message.auctionType

DecodeComplexOrderInitialAndImprovementOrderMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET complexOrderInstrumentSymbol == ReadBytes(exchangeId.rest, 30) IN IF ~complexOrderInstrumentSymbol.ok THEN Fail ELSE
    LET deletionType == ReadBytes(complexOrderInstrumentSymbol.rest, 1) IN IF ~deletionType.ok THEN Fail ELSE
    LET orderSequenceNumber == ReadBytes(deletionType.rest, 6) IN IF ~orderSequenceNumber.ok THEN Fail ELSE
    LET orderSide == ReadBytes(orderSequenceNumber.rest, 1) IN IF ~orderSide.ok THEN Fail ELSE
    LET improvementPhaseSequentialNumber == ReadBytes(orderSide.rest, 6) IN IF ~improvementPhaseSequentialNumber.ok THEN Fail ELSE
    LET auctionType == ReadBytes(improvementPhaseSequentialNumber.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    Ok([ exchangeId                       |-> exchangeId.value,
         complexOrderInstrumentSymbol     |-> complexOrderInstrumentSymbol.value,
         deletionType                     |-> deletionType.value,
         orderSequenceNumber              |-> orderSequenceNumber.value,
         orderSide                        |-> orderSide.value,
         improvementPhaseSequentialNumber |-> improvementPhaseSequentialNumber.value,
         auctionType                      |-> auctionType.value ], auctionType.rest)

ZeroComplexOrderInitialAndImprovementOrderMessage ==
    [ exchangeId                       |-> [i \in 1 .. 1 |-> 0],
      complexOrderInstrumentSymbol     |-> [i \in 1 .. 30 |-> 0],
      deletionType                     |-> [i \in 1 .. 1 |-> 0],
      orderSequenceNumber              |-> [i \in 1 .. 6 |-> 0],
      orderSide                        |-> [i \in 1 .. 1 |-> 0],
      improvementPhaseSequentialNumber |-> [i \in 1 .. 6 |-> 0],
      auctionType                      |-> [i \in 1 .. 1 |-> 0] ]

(* Complex Order Initial And Improvement Order Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexOrderInitialAndImprovementOrderMessage ==
    { ZeroComplexOrderInitialAndImprovementOrderMessage }
        \cup { [ZeroComplexOrderInitialAndImprovementOrderMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderInitialAndImprovementOrderMessage EXCEPT !.complexOrderInstrumentSymbol = one] : one \in Sample(30) }
        \cup { [ZeroComplexOrderInitialAndImprovementOrderMessage EXCEPT !.deletionType = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderInitialAndImprovementOrderMessage EXCEPT !.orderSequenceNumber = one] : one \in Sample(6) }
        \cup { [ZeroComplexOrderInitialAndImprovementOrderMessage EXCEPT !.orderSide = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderInitialAndImprovementOrderMessage EXCEPT !.improvementPhaseSequentialNumber = one] : one \in Sample(6) }
        \cup { [ZeroComplexOrderInitialAndImprovementOrderMessage EXCEPT !.auctionType = one] : one \in Sample(1) }

(***************************************************************************)
(* Message Body, selected by Message Type                                  *)
(***************************************************************************)

EndOfTransmissionMessageCode == 21792  \* "U "
CircuitAssuranceMessageCode == 22048  \* "V "
SystemTimestampMessageCode == 23072  \* "Z "
OptionTradeMessageCode == 17184  \* "C "
StrategyTradeMessageCode == 17235  \* "CS"
OptionRequestForQuoteMessageCode == 17440  \* "D "
OptionQuoteMessageCode == 17952  \* "F "
ComplexOrderQuoteMessageCode == 18003  \* "FS"
GroupOpeningTimeMessageCode == 18243  \* "GC"
GroupStatusMessageCode == 18258  \* "GR"
StrategiesGroupStatusMessageCode == 18259  \* "GS"
OptionMarketDepthMessageCode == 18464  \* "H "
ComplexOrderMarketDepthMessageCode == 18515  \* "HS"
OptionTradeCancellationMessageCode == 18720  \* "I "
ComplexOrderTradeCancellationMessageCode == 18771  \* "IS"
OptionInstrumentKeysMessageCode == 18976  \* "J "
ComplexOrderInstrumentKeysMessageCode == 19027  \* "JS"
BulletinsMessageCode == 19488  \* "L "
OptionSummaryMessageCode == 20000  \* "N "
ComplexOrderSummaryMessageCode == 20051  \* "NS"
BeginningOfOptionsSummaryMessageCode == 20768  \* "Q "
BeginningOfComplexOrderSummaryMessageCode == 20819  \* "QS"
EndOfSalesMessageCode == 21280  \* "S "
OptionImprovementProcessBeginningMessageCode == 19744  \* "M "
ComplexOrderImprovementProcessBeginningMessageMessageCode == 19795  \* "MS"
MarketSheetInitialAndImprovementOrderMessageCode == 20256  \* "O "
ComplexOrderMarketSheetInitialAndImprovementOrderMessageCode == 20307  \* "OS"
InitialAndImprovementOrderMessageCode == 21536  \* "T "
ComplexOrderInitialAndImprovementOrderMessageCode == 21587  \* "TS"

MessageBody ==
    [ tag : {EndOfTransmissionMessageCode}, body : EndOfTransmissionMessage ]
        \cup [ tag : {CircuitAssuranceMessageCode}, body : CircuitAssuranceMessage ]
        \cup [ tag : {SystemTimestampMessageCode}, body : SystemTimestampMessage ]
        \cup [ tag : {OptionTradeMessageCode}, body : OptionTradeMessage ]
        \cup [ tag : {StrategyTradeMessageCode}, body : StrategyTradeMessage ]
        \cup [ tag : {OptionRequestForQuoteMessageCode}, body : OptionRequestForQuoteMessage ]
        \cup [ tag : {OptionQuoteMessageCode}, body : OptionQuoteMessage ]
        \cup [ tag : {ComplexOrderQuoteMessageCode}, body : ComplexOrderQuoteMessage ]
        \cup [ tag : {GroupOpeningTimeMessageCode}, body : GroupOpeningTimeMessage ]
        \cup [ tag : {GroupStatusMessageCode}, body : GroupStatusMessage ]
        \cup [ tag : {StrategiesGroupStatusMessageCode}, body : StrategiesGroupStatusMessage ]
        \cup [ tag : {OptionMarketDepthMessageCode}, body : OptionMarketDepthMessage ]
        \cup [ tag : {ComplexOrderMarketDepthMessageCode}, body : ComplexOrderMarketDepthMessage ]
        \cup [ tag : {OptionTradeCancellationMessageCode}, body : OptionTradeCancellationMessage ]
        \cup [ tag : {ComplexOrderTradeCancellationMessageCode}, body : ComplexOrderTradeCancellationMessage ]
        \cup [ tag : {OptionInstrumentKeysMessageCode}, body : OptionInstrumentKeysMessage ]
        \cup [ tag : {ComplexOrderInstrumentKeysMessageCode}, body : ComplexOrderInstrumentKeysMessage ]
        \cup [ tag : {BulletinsMessageCode}, body : BulletinsMessage ]
        \cup [ tag : {OptionSummaryMessageCode}, body : OptionSummaryMessage ]
        \cup [ tag : {ComplexOrderSummaryMessageCode}, body : ComplexOrderSummaryMessage ]
        \cup [ tag : {BeginningOfOptionsSummaryMessageCode}, body : BeginningOfOptionsSummaryMessage ]
        \cup [ tag : {BeginningOfComplexOrderSummaryMessageCode}, body : BeginningOfComplexOrderSummaryMessage ]
        \cup [ tag : {EndOfSalesMessageCode}, body : EndOfSalesMessage ]
        \cup [ tag : {OptionImprovementProcessBeginningMessageCode}, body : OptionImprovementProcessBeginningMessage ]
        \cup [ tag : {ComplexOrderImprovementProcessBeginningMessageMessageCode}, body : ComplexOrderImprovementProcessBeginningMessageMessage ]
        \cup [ tag : {MarketSheetInitialAndImprovementOrderMessageCode}, body : MarketSheetInitialAndImprovementOrderMessage ]
        \cup [ tag : {ComplexOrderMarketSheetInitialAndImprovementOrderMessageCode}, body : ComplexOrderMarketSheetInitialAndImprovementOrderMessage ]
        \cup [ tag : {InitialAndImprovementOrderMessageCode}, body : InitialAndImprovementOrderMessage ]
        \cup [ tag : {ComplexOrderInitialAndImprovementOrderMessageCode}, body : ComplexOrderInitialAndImprovementOrderMessage ]

EncodeMessageBody(message) ==
    CASE message.tag = EndOfTransmissionMessageCode -> EncodeEndOfTransmissionMessage(message.body)
      [] message.tag = CircuitAssuranceMessageCode -> EncodeCircuitAssuranceMessage(message.body)
      [] message.tag = SystemTimestampMessageCode -> EncodeSystemTimestampMessage(message.body)
      [] message.tag = OptionTradeMessageCode -> EncodeOptionTradeMessage(message.body)
      [] message.tag = StrategyTradeMessageCode -> EncodeStrategyTradeMessage(message.body)
      [] message.tag = OptionRequestForQuoteMessageCode -> EncodeOptionRequestForQuoteMessage(message.body)
      [] message.tag = OptionQuoteMessageCode -> EncodeOptionQuoteMessage(message.body)
      [] message.tag = ComplexOrderQuoteMessageCode -> EncodeComplexOrderQuoteMessage(message.body)
      [] message.tag = GroupOpeningTimeMessageCode -> EncodeGroupOpeningTimeMessage(message.body)
      [] message.tag = GroupStatusMessageCode -> EncodeGroupStatusMessage(message.body)
      [] message.tag = StrategiesGroupStatusMessageCode -> EncodeStrategiesGroupStatusMessage(message.body)
      [] message.tag = OptionMarketDepthMessageCode -> EncodeOptionMarketDepthMessage(message.body)
      [] message.tag = ComplexOrderMarketDepthMessageCode -> EncodeComplexOrderMarketDepthMessage(message.body)
      [] message.tag = OptionTradeCancellationMessageCode -> EncodeOptionTradeCancellationMessage(message.body)
      [] message.tag = ComplexOrderTradeCancellationMessageCode -> EncodeComplexOrderTradeCancellationMessage(message.body)
      [] message.tag = OptionInstrumentKeysMessageCode -> EncodeOptionInstrumentKeysMessage(message.body)
      [] message.tag = ComplexOrderInstrumentKeysMessageCode -> EncodeComplexOrderInstrumentKeysMessage(message.body)
      [] message.tag = BulletinsMessageCode -> EncodeBulletinsMessage(message.body)
      [] message.tag = OptionSummaryMessageCode -> EncodeOptionSummaryMessage(message.body)
      [] message.tag = ComplexOrderSummaryMessageCode -> EncodeComplexOrderSummaryMessage(message.body)
      [] message.tag = BeginningOfOptionsSummaryMessageCode -> EncodeBeginningOfOptionsSummaryMessage(message.body)
      [] message.tag = BeginningOfComplexOrderSummaryMessageCode -> EncodeBeginningOfComplexOrderSummaryMessage(message.body)
      [] message.tag = EndOfSalesMessageCode -> EncodeEndOfSalesMessage(message.body)
      [] message.tag = OptionImprovementProcessBeginningMessageCode -> EncodeOptionImprovementProcessBeginningMessage(message.body)
      [] message.tag = ComplexOrderImprovementProcessBeginningMessageMessageCode -> EncodeComplexOrderImprovementProcessBeginningMessageMessage(message.body)
      [] message.tag = MarketSheetInitialAndImprovementOrderMessageCode -> EncodeMarketSheetInitialAndImprovementOrderMessage(message.body)
      [] message.tag = ComplexOrderMarketSheetInitialAndImprovementOrderMessageCode -> EncodeComplexOrderMarketSheetInitialAndImprovementOrderMessage(message.body)
      [] message.tag = InitialAndImprovementOrderMessageCode -> EncodeInitialAndImprovementOrderMessage(message.body)
      [] message.tag = ComplexOrderInitialAndImprovementOrderMessageCode -> EncodeComplexOrderInitialAndImprovementOrderMessage(message.body)

DecodeMessageBody(tag, bytes) ==
    LET read ==
            CASE tag = EndOfTransmissionMessageCode -> DecodeEndOfTransmissionMessage(bytes)
              [] tag = CircuitAssuranceMessageCode -> DecodeCircuitAssuranceMessage(bytes)
              [] tag = SystemTimestampMessageCode -> DecodeSystemTimestampMessage(bytes)
              [] tag = OptionTradeMessageCode -> DecodeOptionTradeMessage(bytes)
              [] tag = StrategyTradeMessageCode -> DecodeStrategyTradeMessage(bytes)
              [] tag = OptionRequestForQuoteMessageCode -> DecodeOptionRequestForQuoteMessage(bytes)
              [] tag = OptionQuoteMessageCode -> DecodeOptionQuoteMessage(bytes)
              [] tag = ComplexOrderQuoteMessageCode -> DecodeComplexOrderQuoteMessage(bytes)
              [] tag = GroupOpeningTimeMessageCode -> DecodeGroupOpeningTimeMessage(bytes)
              [] tag = GroupStatusMessageCode -> DecodeGroupStatusMessage(bytes)
              [] tag = StrategiesGroupStatusMessageCode -> DecodeStrategiesGroupStatusMessage(bytes)
              [] tag = OptionMarketDepthMessageCode -> DecodeOptionMarketDepthMessage(bytes)
              [] tag = ComplexOrderMarketDepthMessageCode -> DecodeComplexOrderMarketDepthMessage(bytes)
              [] tag = OptionTradeCancellationMessageCode -> DecodeOptionTradeCancellationMessage(bytes)
              [] tag = ComplexOrderTradeCancellationMessageCode -> DecodeComplexOrderTradeCancellationMessage(bytes)
              [] tag = OptionInstrumentKeysMessageCode -> DecodeOptionInstrumentKeysMessage(bytes)
              [] tag = ComplexOrderInstrumentKeysMessageCode -> DecodeComplexOrderInstrumentKeysMessage(bytes)
              [] tag = BulletinsMessageCode -> DecodeBulletinsMessage(bytes)
              [] tag = OptionSummaryMessageCode -> DecodeOptionSummaryMessage(bytes)
              [] tag = ComplexOrderSummaryMessageCode -> DecodeComplexOrderSummaryMessage(bytes)
              [] tag = BeginningOfOptionsSummaryMessageCode -> DecodeBeginningOfOptionsSummaryMessage(bytes)
              [] tag = BeginningOfComplexOrderSummaryMessageCode -> DecodeBeginningOfComplexOrderSummaryMessage(bytes)
              [] tag = EndOfSalesMessageCode -> DecodeEndOfSalesMessage(bytes)
              [] tag = OptionImprovementProcessBeginningMessageCode -> DecodeOptionImprovementProcessBeginningMessage(bytes)
              [] tag = ComplexOrderImprovementProcessBeginningMessageMessageCode -> DecodeComplexOrderImprovementProcessBeginningMessageMessage(bytes)
              [] tag = MarketSheetInitialAndImprovementOrderMessageCode -> DecodeMarketSheetInitialAndImprovementOrderMessage(bytes)
              [] tag = ComplexOrderMarketSheetInitialAndImprovementOrderMessageCode -> DecodeComplexOrderMarketSheetInitialAndImprovementOrderMessage(bytes)
              [] tag = InitialAndImprovementOrderMessageCode -> DecodeInitialAndImprovementOrderMessage(bytes)
              [] tag = ComplexOrderInitialAndImprovementOrderMessageCode -> DecodeComplexOrderInitialAndImprovementOrderMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroMessageBody == [tag |-> EndOfTransmissionMessageCode, body |-> ZeroEndOfTransmissionMessage]

(* Each Message Body in turn, at the values the message it names is checked at *)
CheckedMessageBody ==
    { [tag |-> EndOfTransmissionMessageCode, body |-> one] : one \in CheckedEndOfTransmissionMessage }
        \cup { [tag |-> CircuitAssuranceMessageCode, body |-> one] : one \in CheckedCircuitAssuranceMessage }
        \cup { [tag |-> SystemTimestampMessageCode, body |-> one] : one \in CheckedSystemTimestampMessage }
        \cup { [tag |-> OptionTradeMessageCode, body |-> one] : one \in CheckedOptionTradeMessage }
        \cup { [tag |-> StrategyTradeMessageCode, body |-> one] : one \in CheckedStrategyTradeMessage }
        \cup { [tag |-> OptionRequestForQuoteMessageCode, body |-> one] : one \in CheckedOptionRequestForQuoteMessage }
        \cup { [tag |-> OptionQuoteMessageCode, body |-> one] : one \in CheckedOptionQuoteMessage }
        \cup { [tag |-> ComplexOrderQuoteMessageCode, body |-> one] : one \in CheckedComplexOrderQuoteMessage }
        \cup { [tag |-> GroupOpeningTimeMessageCode, body |-> one] : one \in CheckedGroupOpeningTimeMessage }
        \cup { [tag |-> GroupStatusMessageCode, body |-> one] : one \in CheckedGroupStatusMessage }
        \cup { [tag |-> StrategiesGroupStatusMessageCode, body |-> one] : one \in CheckedStrategiesGroupStatusMessage }
        \cup { [tag |-> OptionMarketDepthMessageCode, body |-> one] : one \in CheckedOptionMarketDepthMessage }
        \cup { [tag |-> ComplexOrderMarketDepthMessageCode, body |-> one] : one \in CheckedComplexOrderMarketDepthMessage }
        \cup { [tag |-> OptionTradeCancellationMessageCode, body |-> one] : one \in CheckedOptionTradeCancellationMessage }
        \cup { [tag |-> ComplexOrderTradeCancellationMessageCode, body |-> one] : one \in CheckedComplexOrderTradeCancellationMessage }
        \cup { [tag |-> OptionInstrumentKeysMessageCode, body |-> one] : one \in CheckedOptionInstrumentKeysMessage }
        \cup { [tag |-> ComplexOrderInstrumentKeysMessageCode, body |-> one] : one \in CheckedComplexOrderInstrumentKeysMessage }
        \cup { [tag |-> BulletinsMessageCode, body |-> one] : one \in CheckedBulletinsMessage }
        \cup { [tag |-> OptionSummaryMessageCode, body |-> one] : one \in CheckedOptionSummaryMessage }
        \cup { [tag |-> ComplexOrderSummaryMessageCode, body |-> one] : one \in CheckedComplexOrderSummaryMessage }
        \cup { [tag |-> BeginningOfOptionsSummaryMessageCode, body |-> one] : one \in CheckedBeginningOfOptionsSummaryMessage }
        \cup { [tag |-> BeginningOfComplexOrderSummaryMessageCode, body |-> one] : one \in CheckedBeginningOfComplexOrderSummaryMessage }
        \cup { [tag |-> EndOfSalesMessageCode, body |-> one] : one \in CheckedEndOfSalesMessage }
        \cup { [tag |-> OptionImprovementProcessBeginningMessageCode, body |-> one] : one \in CheckedOptionImprovementProcessBeginningMessage }
        \cup { [tag |-> ComplexOrderImprovementProcessBeginningMessageMessageCode, body |-> one] : one \in CheckedComplexOrderImprovementProcessBeginningMessageMessage }
        \cup { [tag |-> MarketSheetInitialAndImprovementOrderMessageCode, body |-> one] : one \in CheckedMarketSheetInitialAndImprovementOrderMessage }
        \cup { [tag |-> ComplexOrderMarketSheetInitialAndImprovementOrderMessageCode, body |-> one] : one \in CheckedComplexOrderMarketSheetInitialAndImprovementOrderMessage }
        \cup { [tag |-> InitialAndImprovementOrderMessageCode, body |-> one] : one \in CheckedInitialAndImprovementOrderMessage }
        \cup { [tag |-> ComplexOrderInitialAndImprovementOrderMessageCode, body |-> one] : one \in CheckedComplexOrderInitialAndImprovementOrderMessage }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ hsvfStx        : Sample(1),
      sequenceNumber : Sample(9),
      messageBody    : MessageBody,
      hsvfEtx        : Sample(1) ]

EncodePacket(message) ==
    message.hsvfStx
        \o message.sequenceNumber
        \o EncodeUIntBE(message.messageBody.tag, 2)
        \o EncodeMessageBody(message.messageBody)
        \o message.hsvfEtx

DecodePacket(bytes) ==
    LET hsvfStx == ReadBytes(bytes, 1) IN IF ~hsvfStx.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(hsvfStx.rest, 9) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET messageType == ReadUIntBE(sequenceNumber.rest, 2) IN IF ~messageType.ok THEN Fail ELSE
    LET messageBody == DecodeMessageBody(messageType.value, messageType.rest) IN IF ~messageBody.ok THEN Fail ELSE
    LET hsvfEtx == ReadBytes(messageBody.rest, 1) IN IF ~hsvfEtx.ok THEN Fail ELSE
    Ok([ hsvfStx        |-> hsvfStx.value,
         sequenceNumber |-> sequenceNumber.value,
         messageBody    |-> messageBody.value,
         hsvfEtx        |-> hsvfEtx.value ], hsvfEtx.rest)

ZeroPacket ==
    [ hsvfStx        |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber |-> [i \in 1 .. 9 |-> 0],
      messageBody    |-> ZeroMessageBody,
      hsvfEtx        |-> [i \in 1 .. 1 |-> 0] ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.hsvfStx = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.sequenceNumber = one] : one \in Sample(9) }
        \cup { [ZeroPacket EXCEPT !.messageBody = one] : one \in CheckedMessageBody }
        \cup { [ZeroPacket EXCEPT !.hsvfEtx = one] : one \in Sample(1) }

(***************************************************************************)
(* What TLC checks                                                         *)
(***************************************************************************)

(* An integer a rule depends on writes its width and reads back what was written *)
RoundTripUIntLE ==
    \A width \in 1 .. 3 :
        \A value \in {0, 1, 255, 256, 65535} :
            (value < 256 ^ width) =>
                /\ Len(EncodeUIntLE(value, width)) = width
                /\ DecodeUIntLE(EncodeUIntLE(value, width)) = value
                /\ Len(EncodeUIntBE(value, width)) = width
                /\ DecodeUIntBE(EncodeUIntBE(value, width)) = value
                /\ \A i \in 1 .. width : EncodeUIntLE(value, width)[i] \in Byte
                /\ \A i \in 1 .. width : EncodeUIntBE(value, width)[i] \in Byte

(* Every End Of Transmission Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfTransmissionMessage ==
    \A message \in CheckedEndOfTransmissionMessage :
        LET read == DecodeEndOfTransmissionMessage(EncodeEndOfTransmissionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Circuit Assurance Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCircuitAssuranceMessage ==
    \A message \in CheckedCircuitAssuranceMessage :
        LET read == DecodeCircuitAssuranceMessage(EncodeCircuitAssuranceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every System Timestamp Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSystemTimestampMessage ==
    \A message \in CheckedSystemTimestampMessage :
        LET read == DecodeSystemTimestampMessage(EncodeSystemTimestampMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Description decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentDescription ==
    \A message \in CheckedInstrumentDescription :
        LET read == DecodeInstrumentDescription(EncodeInstrumentDescription(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionTradeMessage ==
    \A message \in CheckedOptionTradeMessage :
        LET read == DecodeOptionTradeMessage(EncodeOptionTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyTradeMessage ==
    \A message \in CheckedStrategyTradeMessage :
        LET read == DecodeStrategyTradeMessage(EncodeStrategyTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Description decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentDescription2 ==
    \A message \in CheckedInstrumentDescription2 :
        LET read == DecodeInstrumentDescription2(EncodeInstrumentDescription2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Request For Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionRequestForQuoteMessage ==
    \A message \in CheckedOptionRequestForQuoteMessage :
        LET read == DecodeOptionRequestForQuoteMessage(EncodeOptionRequestForQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Description decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentDescription3 ==
    \A message \in CheckedInstrumentDescription3 :
        LET read == DecodeInstrumentDescription3(EncodeInstrumentDescription3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionQuoteMessage ==
    \A message \in CheckedOptionQuoteMessage :
        LET read == DecodeOptionQuoteMessage(EncodeOptionQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Order Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexOrderQuoteMessage ==
    \A message \in CheckedComplexOrderQuoteMessage :
        LET read == DecodeComplexOrderQuoteMessage(EncodeComplexOrderQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Group Opening Time Message decodes back to what was encoded, and leaves nothing over *)
RoundTripGroupOpeningTimeMessage ==
    \A message \in CheckedGroupOpeningTimeMessage :
        LET read == DecodeGroupOpeningTimeMessage(EncodeGroupOpeningTimeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Group Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripGroupStatusMessage ==
    \A message \in CheckedGroupStatusMessage :
        LET read == DecodeGroupStatusMessage(EncodeGroupStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategies Group Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategiesGroupStatusMessage ==
    \A message \in CheckedStrategiesGroupStatusMessage :
        LET read == DecodeStrategiesGroupStatusMessage(EncodeStrategiesGroupStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Description decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentDescription4 ==
    \A message \in CheckedInstrumentDescription4 :
        LET read == DecodeInstrumentDescription4(EncodeInstrumentDescription4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Depth Level decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketDepthLevel ==
    \A message \in CheckedMarketDepthLevel :
        LET read == DecodeMarketDepthLevel(EncodeMarketDepthLevel(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Market Depth Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionMarketDepthMessage ==
    \A message \in CheckedOptionMarketDepthMessage :
        LET read == DecodeOptionMarketDepthMessage(EncodeOptionMarketDepthMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Market Depth Level decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexMarketDepthLevel ==
    \A message \in CheckedComplexMarketDepthLevel :
        LET read == DecodeComplexMarketDepthLevel(EncodeComplexMarketDepthLevel(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Order Market Depth Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexOrderMarketDepthMessage ==
    \A message \in CheckedComplexOrderMarketDepthMessage :
        LET read == DecodeComplexOrderMarketDepthMessage(EncodeComplexOrderMarketDepthMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Description decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentDescription5 ==
    \A message \in CheckedInstrumentDescription5 :
        LET read == DecodeInstrumentDescription5(EncodeInstrumentDescription5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Trade Cancellation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionTradeCancellationMessage ==
    \A message \in CheckedOptionTradeCancellationMessage :
        LET read == DecodeOptionTradeCancellationMessage(EncodeOptionTradeCancellationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Order Trade Cancellation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexOrderTradeCancellationMessage ==
    \A message \in CheckedComplexOrderTradeCancellationMessage :
        LET read == DecodeComplexOrderTradeCancellationMessage(EncodeComplexOrderTradeCancellationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Description decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentDescription6 ==
    \A message \in CheckedInstrumentDescription6 :
        LET read == DecodeInstrumentDescription6(EncodeInstrumentDescription6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Flow Indicator decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketFlowIndicator ==
    \A message \in CheckedMarketFlowIndicator :
        LET read == DecodeMarketFlowIndicator(EncodeMarketFlowIndicator(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Marker decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionMarker ==
    \A message \in CheckedOptionMarker :
        LET read == DecodeOptionMarker(EncodeOptionMarker(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Instrument Keys Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionInstrumentKeysMessage ==
    \A message \in CheckedOptionInstrumentKeysMessage :
        LET read == DecodeOptionInstrumentKeysMessage(EncodeOptionInstrumentKeysMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Leg decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentLeg ==
    \A message \in CheckedInstrumentLeg :
        LET read == DecodeInstrumentLeg(EncodeInstrumentLeg(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Order Instrument Keys Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexOrderInstrumentKeysMessage ==
    \A message \in CheckedComplexOrderInstrumentKeysMessage :
        LET read == DecodeComplexOrderInstrumentKeysMessage(EncodeComplexOrderInstrumentKeysMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulletins Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBulletinsMessage ==
    \A message \in CheckedBulletinsMessage :
        LET read == DecodeBulletinsMessage(EncodeBulletinsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Description decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentDescription7 ==
    \A message \in CheckedInstrumentDescription7 :
        LET read == DecodeInstrumentDescription7(EncodeInstrumentDescription7(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Marker decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionMarker2 ==
    \A message \in CheckedOptionMarker2 :
        LET read == DecodeOptionMarker2(EncodeOptionMarker2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionSummaryMessage ==
    \A message \in CheckedOptionSummaryMessage :
        LET read == DecodeOptionSummaryMessage(EncodeOptionSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Order Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexOrderSummaryMessage ==
    \A message \in CheckedComplexOrderSummaryMessage :
        LET read == DecodeComplexOrderSummaryMessage(EncodeComplexOrderSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Beginning Of Options Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBeginningOfOptionsSummaryMessage ==
    \A message \in CheckedBeginningOfOptionsSummaryMessage :
        LET read == DecodeBeginningOfOptionsSummaryMessage(EncodeBeginningOfOptionsSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Beginning Of Complex Order Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBeginningOfComplexOrderSummaryMessage ==
    \A message \in CheckedBeginningOfComplexOrderSummaryMessage :
        LET read == DecodeBeginningOfComplexOrderSummaryMessage(EncodeBeginningOfComplexOrderSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Sales Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfSalesMessage ==
    \A message \in CheckedEndOfSalesMessage :
        LET read == DecodeEndOfSalesMessage(EncodeEndOfSalesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Description decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentDescription8 ==
    \A message \in CheckedInstrumentDescription8 :
        LET read == DecodeInstrumentDescription8(EncodeInstrumentDescription8(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Improvement Process Beginning Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionImprovementProcessBeginningMessage ==
    \A message \in CheckedOptionImprovementProcessBeginningMessage :
        LET read == DecodeOptionImprovementProcessBeginningMessage(EncodeOptionImprovementProcessBeginningMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Order Improvement Process Beginning Message Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexOrderImprovementProcessBeginningMessageMessage ==
    \A message \in CheckedComplexOrderImprovementProcessBeginningMessageMessage :
        LET read == DecodeComplexOrderImprovementProcessBeginningMessageMessage(EncodeComplexOrderImprovementProcessBeginningMessageMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Description decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentDescription9 ==
    \A message \in CheckedInstrumentDescription9 :
        LET read == DecodeInstrumentDescription9(EncodeInstrumentDescription9(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Sheet Initial And Improvement Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketSheetInitialAndImprovementOrderMessage ==
    \A message \in CheckedMarketSheetInitialAndImprovementOrderMessage :
        LET read == DecodeMarketSheetInitialAndImprovementOrderMessage(EncodeMarketSheetInitialAndImprovementOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Order Market Sheet Initial And Improvement Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexOrderMarketSheetInitialAndImprovementOrderMessage ==
    \A message \in CheckedComplexOrderMarketSheetInitialAndImprovementOrderMessage :
        LET read == DecodeComplexOrderMarketSheetInitialAndImprovementOrderMessage(EncodeComplexOrderMarketSheetInitialAndImprovementOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Description decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentDescription10 ==
    \A message \in CheckedInstrumentDescription10 :
        LET read == DecodeInstrumentDescription10(EncodeInstrumentDescription10(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Initial And Improvement Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInitialAndImprovementOrderMessage ==
    \A message \in CheckedInitialAndImprovementOrderMessage :
        LET read == DecodeInitialAndImprovementOrderMessage(EncodeInitialAndImprovementOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Order Initial And Improvement Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexOrderInitialAndImprovementOrderMessage ==
    \A message \in CheckedComplexOrderInitialAndImprovementOrderMessage :
        LET read == DecodeComplexOrderInitialAndImprovementOrderMessage(EncodeComplexOrderInitialAndImprovementOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripPacket ==
    \A message \in CheckedPacket :
        LET read == DecodePacket(EncodePacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Message Body is selected by the Message Type it is written under *)
SelectsMessageBody ==
    \A message \in CheckedMessageBody :
        LET read == DecodeMessageBody(message.tag, EncodeMessageBody(message))
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
