--------------------- MODULE AsxDerivatives_Ntp_v1_05 ----------------------
(***************************************************************************)
(* Australian Securities Exchange New Trading Platform v1.05               *)
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
(*                                                                         *)
(* Note: a Message Count of 0 marks Heartbeat and carries no Message.      *)
(*                                                                         *)
(* Note: a Message Count of 0 marks End Of Session and carries no Message. *)
(*                                                                         *)
(* Note: Combination Leg is written as 6 slots, however many of them the   *)
(* count beside it says are in use.                                        *)
(*                                                                         *)
(* Note: Bundle Leg is written as 20 slots, however many of them the count *)
(* beside it says are in use.                                              *)
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
(* Seconds Message: 4 bytes                                                *)
(***************************************************************************)

SecondsMessage ==
    [ second : Sample(4) ]

EncodeSecondsMessage(message) ==
    message.second

DecodeSecondsMessage(bytes) ==
    LET second == ReadBytes(bytes, 4) IN IF ~second.ok THEN Fail ELSE
    Ok([ second |-> second.value ], second.rest)

ZeroSecondsMessage ==
    [ second |-> [i \in 1 .. 4 |-> 0] ]

(* Seconds Message at zero, then each field in turn at the values it is checked at *)
CheckedSecondsMessage ==
    { ZeroSecondsMessage }
        \cup { [ZeroSecondsMessage EXCEPT !.second = one] : one \in Sample(4) }

(***************************************************************************)
(* End Of Business Trade Date Message: 7 bytes                             *)
(***************************************************************************)

EndOfBusinessTradeDateMessage ==
    [ nanoseconds : Sample(4),
      tradeDate   : Sample(2),
      eventCode   : Sample(1) ]

EncodeEndOfBusinessTradeDateMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.eventCode

DecodeEndOfBusinessTradeDateMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET eventCode == ReadBytes(tradeDate.rest, 1) IN IF ~eventCode.ok THEN Fail ELSE
    Ok([ nanoseconds |-> nanoseconds.value,
         tradeDate   |-> tradeDate.value,
         eventCode   |-> eventCode.value ], eventCode.rest)

ZeroEndOfBusinessTradeDateMessage ==
    [ nanoseconds |-> [i \in 1 .. 4 |-> 0],
      tradeDate   |-> [i \in 1 .. 2 |-> 0],
      eventCode   |-> [i \in 1 .. 1 |-> 0] ]

(* End Of Business Trade Date Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfBusinessTradeDateMessage ==
    { ZeroEndOfBusinessTradeDateMessage }
        \cup { [ZeroEndOfBusinessTradeDateMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroEndOfBusinessTradeDateMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroEndOfBusinessTradeDateMessage EXCEPT !.eventCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Future Symbol Directory Message: 179 bytes                              *)
(***************************************************************************)

FutureSymbolDirectoryMessage ==
    [ nanoseconds                : Sample(4),
      tradeDate                  : Sample(2),
      tradeableInstrumentId      : Sample(4),
      symbolName                 : Sample(32),
      longName                   : Sample(60),
      isin                       : Sample(12),
      exchange                   : Sample(6),
      instrument                 : Sample(6),
      cfiCode                    : Sample(6),
      expiryYear                 : Sample(2),
      expiryMonth                : Sample(1),
      priceDisplayDecimals       : Sample(1),
      priceFractionalDenominator : Sample(4),
      priceMinimumTick           : Sample(4),
      lastTradingDate            : Sample(4),
      priorDaySettlement         : Sample(8),
      currency                   : Sample(3),
      lotSizeOrFaceValue         : Sample(8),
      maturityValue              : Sample(1),
      couponRate                 : Sample(2),
      paymentsPerYear            : Sample(1),
      blockLotSize               : Sample(4),
      expiryDate                 : Sample(4) ]

EncodeFutureSymbolDirectoryMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.tradeableInstrumentId
        \o message.symbolName
        \o message.longName
        \o message.isin
        \o message.exchange
        \o message.instrument
        \o message.cfiCode
        \o message.expiryYear
        \o message.expiryMonth
        \o message.priceDisplayDecimals
        \o message.priceFractionalDenominator
        \o message.priceMinimumTick
        \o message.lastTradingDate
        \o message.priorDaySettlement
        \o message.currency
        \o message.lotSizeOrFaceValue
        \o message.maturityValue
        \o message.couponRate
        \o message.paymentsPerYear
        \o message.blockLotSize
        \o message.expiryDate

DecodeFutureSymbolDirectoryMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET tradeableInstrumentId == ReadBytes(tradeDate.rest, 4) IN IF ~tradeableInstrumentId.ok THEN Fail ELSE
    LET symbolName == ReadBytes(tradeableInstrumentId.rest, 32) IN IF ~symbolName.ok THEN Fail ELSE
    LET longName == ReadBytes(symbolName.rest, 60) IN IF ~longName.ok THEN Fail ELSE
    LET isin == ReadBytes(longName.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET exchange == ReadBytes(isin.rest, 6) IN IF ~exchange.ok THEN Fail ELSE
    LET instrument == ReadBytes(exchange.rest, 6) IN IF ~instrument.ok THEN Fail ELSE
    LET cfiCode == ReadBytes(instrument.rest, 6) IN IF ~cfiCode.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(cfiCode.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryMonth == ReadBytes(expiryYear.rest, 1) IN IF ~expiryMonth.ok THEN Fail ELSE
    LET priceDisplayDecimals == ReadBytes(expiryMonth.rest, 1) IN IF ~priceDisplayDecimals.ok THEN Fail ELSE
    LET priceFractionalDenominator == ReadBytes(priceDisplayDecimals.rest, 4) IN IF ~priceFractionalDenominator.ok THEN Fail ELSE
    LET priceMinimumTick == ReadBytes(priceFractionalDenominator.rest, 4) IN IF ~priceMinimumTick.ok THEN Fail ELSE
    LET lastTradingDate == ReadBytes(priceMinimumTick.rest, 4) IN IF ~lastTradingDate.ok THEN Fail ELSE
    LET priorDaySettlement == ReadBytes(lastTradingDate.rest, 8) IN IF ~priorDaySettlement.ok THEN Fail ELSE
    LET currency == ReadBytes(priorDaySettlement.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET lotSizeOrFaceValue == ReadBytes(currency.rest, 8) IN IF ~lotSizeOrFaceValue.ok THEN Fail ELSE
    LET maturityValue == ReadBytes(lotSizeOrFaceValue.rest, 1) IN IF ~maturityValue.ok THEN Fail ELSE
    LET couponRate == ReadBytes(maturityValue.rest, 2) IN IF ~couponRate.ok THEN Fail ELSE
    LET paymentsPerYear == ReadBytes(couponRate.rest, 1) IN IF ~paymentsPerYear.ok THEN Fail ELSE
    LET blockLotSize == ReadBytes(paymentsPerYear.rest, 4) IN IF ~blockLotSize.ok THEN Fail ELSE
    LET expiryDate == ReadBytes(blockLotSize.rest, 4) IN IF ~expiryDate.ok THEN Fail ELSE
    Ok([ nanoseconds                |-> nanoseconds.value,
         tradeDate                  |-> tradeDate.value,
         tradeableInstrumentId      |-> tradeableInstrumentId.value,
         symbolName                 |-> symbolName.value,
         longName                   |-> longName.value,
         isin                       |-> isin.value,
         exchange                   |-> exchange.value,
         instrument                 |-> instrument.value,
         cfiCode                    |-> cfiCode.value,
         expiryYear                 |-> expiryYear.value,
         expiryMonth                |-> expiryMonth.value,
         priceDisplayDecimals       |-> priceDisplayDecimals.value,
         priceFractionalDenominator |-> priceFractionalDenominator.value,
         priceMinimumTick           |-> priceMinimumTick.value,
         lastTradingDate            |-> lastTradingDate.value,
         priorDaySettlement         |-> priorDaySettlement.value,
         currency                   |-> currency.value,
         lotSizeOrFaceValue         |-> lotSizeOrFaceValue.value,
         maturityValue              |-> maturityValue.value,
         couponRate                 |-> couponRate.value,
         paymentsPerYear            |-> paymentsPerYear.value,
         blockLotSize               |-> blockLotSize.value,
         expiryDate                 |-> expiryDate.value ], expiryDate.rest)

ZeroFutureSymbolDirectoryMessage ==
    [ nanoseconds                |-> [i \in 1 .. 4 |-> 0],
      tradeDate                  |-> [i \in 1 .. 2 |-> 0],
      tradeableInstrumentId      |-> [i \in 1 .. 4 |-> 0],
      symbolName                 |-> [i \in 1 .. 32 |-> 0],
      longName                   |-> [i \in 1 .. 60 |-> 0],
      isin                       |-> [i \in 1 .. 12 |-> 0],
      exchange                   |-> [i \in 1 .. 6 |-> 0],
      instrument                 |-> [i \in 1 .. 6 |-> 0],
      cfiCode                    |-> [i \in 1 .. 6 |-> 0],
      expiryYear                 |-> [i \in 1 .. 2 |-> 0],
      expiryMonth                |-> [i \in 1 .. 1 |-> 0],
      priceDisplayDecimals       |-> [i \in 1 .. 1 |-> 0],
      priceFractionalDenominator |-> [i \in 1 .. 4 |-> 0],
      priceMinimumTick           |-> [i \in 1 .. 4 |-> 0],
      lastTradingDate            |-> [i \in 1 .. 4 |-> 0],
      priorDaySettlement         |-> [i \in 1 .. 8 |-> 0],
      currency                   |-> [i \in 1 .. 3 |-> 0],
      lotSizeOrFaceValue         |-> [i \in 1 .. 8 |-> 0],
      maturityValue              |-> [i \in 1 .. 1 |-> 0],
      couponRate                 |-> [i \in 1 .. 2 |-> 0],
      paymentsPerYear            |-> [i \in 1 .. 1 |-> 0],
      blockLotSize               |-> [i \in 1 .. 4 |-> 0],
      expiryDate                 |-> [i \in 1 .. 4 |-> 0] ]

(* Future Symbol Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedFutureSymbolDirectoryMessage ==
    { ZeroFutureSymbolDirectoryMessage }
        \cup { [ZeroFutureSymbolDirectoryMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroFutureSymbolDirectoryMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroFutureSymbolDirectoryMessage EXCEPT !.tradeableInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroFutureSymbolDirectoryMessage EXCEPT !.symbolName = one] : one \in Sample(32) }
        \cup { [ZeroFutureSymbolDirectoryMessage EXCEPT !.longName = one] : one \in Sample(60) }
        \cup { [ZeroFutureSymbolDirectoryMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroFutureSymbolDirectoryMessage EXCEPT !.exchange = one] : one \in Sample(6) }
        \cup { [ZeroFutureSymbolDirectoryMessage EXCEPT !.instrument = one] : one \in Sample(6) }
        \cup { [ZeroFutureSymbolDirectoryMessage EXCEPT !.cfiCode = one] : one \in Sample(6) }
        \cup { [ZeroFutureSymbolDirectoryMessage EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroFutureSymbolDirectoryMessage EXCEPT !.expiryMonth = one] : one \in Sample(1) }
        \cup { [ZeroFutureSymbolDirectoryMessage EXCEPT !.priceDisplayDecimals = one] : one \in Sample(1) }
        \cup { [ZeroFutureSymbolDirectoryMessage EXCEPT !.priceFractionalDenominator = one] : one \in Sample(4) }
        \cup { [ZeroFutureSymbolDirectoryMessage EXCEPT !.priceMinimumTick = one] : one \in Sample(4) }
        \cup { [ZeroFutureSymbolDirectoryMessage EXCEPT !.lastTradingDate = one] : one \in Sample(4) }
        \cup { [ZeroFutureSymbolDirectoryMessage EXCEPT !.priorDaySettlement = one] : one \in Sample(8) }
        \cup { [ZeroFutureSymbolDirectoryMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroFutureSymbolDirectoryMessage EXCEPT !.lotSizeOrFaceValue = one] : one \in Sample(8) }
        \cup { [ZeroFutureSymbolDirectoryMessage EXCEPT !.maturityValue = one] : one \in Sample(1) }
        \cup { [ZeroFutureSymbolDirectoryMessage EXCEPT !.couponRate = one] : one \in Sample(2) }
        \cup { [ZeroFutureSymbolDirectoryMessage EXCEPT !.paymentsPerYear = one] : one \in Sample(1) }
        \cup { [ZeroFutureSymbolDirectoryMessage EXCEPT !.blockLotSize = one] : one \in Sample(4) }
        \cup { [ZeroFutureSymbolDirectoryMessage EXCEPT !.expiryDate = one] : one \in Sample(4) }

(***************************************************************************)
(* Options Symbol Directory Message: 219 bytes                             *)
(***************************************************************************)

OptionsSymbolDirectoryMessage ==
    [ nanoseconds                      : Sample(4),
      tradeDate                        : Sample(2),
      tradeableInstrumentId            : Sample(4),
      symbolName                       : Sample(32),
      longName                         : Sample(60),
      isin                             : Sample(12),
      exchange                         : Sample(6),
      instrument                       : Sample(6),
      cfiCode                          : Sample(6),
      expiryYear                       : Sample(2),
      expiryMonth                      : Sample(1),
      optionType                       : Sample(1),
      strike                           : Sample(8),
      underlyingTradeableInstrumentId  : Sample(4),
      priceDisplayDecimals             : Sample(1),
      priceFractionalDenominator       : Sample(4),
      priceMinimumTick                 : Sample(4),
      strikePriceDecimalPosition       : Sample(1),
      strikePriceFractionalDenominator : Sample(4),
      strikePriceMinimumTick           : Sample(4),
      lastTradingDate                  : Sample(4),
      priorDaySettlement               : Sample(8),
      volatility                       : Sample(8),
      currency                         : Sample(3),
      lotSizeOrFaceValue               : Sample(8),
      maturityValue                    : Sample(1),
      couponRate                       : Sample(2),
      paymentsPerYear                  : Sample(1),
      blockLotSize                     : Sample(4),
      expiryDate                       : Sample(4),
      basisOfQuotation                 : Sample(10) ]

EncodeOptionsSymbolDirectoryMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.tradeableInstrumentId
        \o message.symbolName
        \o message.longName
        \o message.isin
        \o message.exchange
        \o message.instrument
        \o message.cfiCode
        \o message.expiryYear
        \o message.expiryMonth
        \o message.optionType
        \o message.strike
        \o message.underlyingTradeableInstrumentId
        \o message.priceDisplayDecimals
        \o message.priceFractionalDenominator
        \o message.priceMinimumTick
        \o message.strikePriceDecimalPosition
        \o message.strikePriceFractionalDenominator
        \o message.strikePriceMinimumTick
        \o message.lastTradingDate
        \o message.priorDaySettlement
        \o message.volatility
        \o message.currency
        \o message.lotSizeOrFaceValue
        \o message.maturityValue
        \o message.couponRate
        \o message.paymentsPerYear
        \o message.blockLotSize
        \o message.expiryDate
        \o message.basisOfQuotation

DecodeOptionsSymbolDirectoryMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET tradeableInstrumentId == ReadBytes(tradeDate.rest, 4) IN IF ~tradeableInstrumentId.ok THEN Fail ELSE
    LET symbolName == ReadBytes(tradeableInstrumentId.rest, 32) IN IF ~symbolName.ok THEN Fail ELSE
    LET longName == ReadBytes(symbolName.rest, 60) IN IF ~longName.ok THEN Fail ELSE
    LET isin == ReadBytes(longName.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET exchange == ReadBytes(isin.rest, 6) IN IF ~exchange.ok THEN Fail ELSE
    LET instrument == ReadBytes(exchange.rest, 6) IN IF ~instrument.ok THEN Fail ELSE
    LET cfiCode == ReadBytes(instrument.rest, 6) IN IF ~cfiCode.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(cfiCode.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryMonth == ReadBytes(expiryYear.rest, 1) IN IF ~expiryMonth.ok THEN Fail ELSE
    LET optionType == ReadBytes(expiryMonth.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET strike == ReadBytes(optionType.rest, 8) IN IF ~strike.ok THEN Fail ELSE
    LET underlyingTradeableInstrumentId == ReadBytes(strike.rest, 4) IN IF ~underlyingTradeableInstrumentId.ok THEN Fail ELSE
    LET priceDisplayDecimals == ReadBytes(underlyingTradeableInstrumentId.rest, 1) IN IF ~priceDisplayDecimals.ok THEN Fail ELSE
    LET priceFractionalDenominator == ReadBytes(priceDisplayDecimals.rest, 4) IN IF ~priceFractionalDenominator.ok THEN Fail ELSE
    LET priceMinimumTick == ReadBytes(priceFractionalDenominator.rest, 4) IN IF ~priceMinimumTick.ok THEN Fail ELSE
    LET strikePriceDecimalPosition == ReadBytes(priceMinimumTick.rest, 1) IN IF ~strikePriceDecimalPosition.ok THEN Fail ELSE
    LET strikePriceFractionalDenominator == ReadBytes(strikePriceDecimalPosition.rest, 4) IN IF ~strikePriceFractionalDenominator.ok THEN Fail ELSE
    LET strikePriceMinimumTick == ReadBytes(strikePriceFractionalDenominator.rest, 4) IN IF ~strikePriceMinimumTick.ok THEN Fail ELSE
    LET lastTradingDate == ReadBytes(strikePriceMinimumTick.rest, 4) IN IF ~lastTradingDate.ok THEN Fail ELSE
    LET priorDaySettlement == ReadBytes(lastTradingDate.rest, 8) IN IF ~priorDaySettlement.ok THEN Fail ELSE
    LET volatility == ReadBytes(priorDaySettlement.rest, 8) IN IF ~volatility.ok THEN Fail ELSE
    LET currency == ReadBytes(volatility.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET lotSizeOrFaceValue == ReadBytes(currency.rest, 8) IN IF ~lotSizeOrFaceValue.ok THEN Fail ELSE
    LET maturityValue == ReadBytes(lotSizeOrFaceValue.rest, 1) IN IF ~maturityValue.ok THEN Fail ELSE
    LET couponRate == ReadBytes(maturityValue.rest, 2) IN IF ~couponRate.ok THEN Fail ELSE
    LET paymentsPerYear == ReadBytes(couponRate.rest, 1) IN IF ~paymentsPerYear.ok THEN Fail ELSE
    LET blockLotSize == ReadBytes(paymentsPerYear.rest, 4) IN IF ~blockLotSize.ok THEN Fail ELSE
    LET expiryDate == ReadBytes(blockLotSize.rest, 4) IN IF ~expiryDate.ok THEN Fail ELSE
    LET basisOfQuotation == ReadBytes(expiryDate.rest, 10) IN IF ~basisOfQuotation.ok THEN Fail ELSE
    Ok([ nanoseconds                      |-> nanoseconds.value,
         tradeDate                        |-> tradeDate.value,
         tradeableInstrumentId            |-> tradeableInstrumentId.value,
         symbolName                       |-> symbolName.value,
         longName                         |-> longName.value,
         isin                             |-> isin.value,
         exchange                         |-> exchange.value,
         instrument                       |-> instrument.value,
         cfiCode                          |-> cfiCode.value,
         expiryYear                       |-> expiryYear.value,
         expiryMonth                      |-> expiryMonth.value,
         optionType                       |-> optionType.value,
         strike                           |-> strike.value,
         underlyingTradeableInstrumentId  |-> underlyingTradeableInstrumentId.value,
         priceDisplayDecimals             |-> priceDisplayDecimals.value,
         priceFractionalDenominator       |-> priceFractionalDenominator.value,
         priceMinimumTick                 |-> priceMinimumTick.value,
         strikePriceDecimalPosition       |-> strikePriceDecimalPosition.value,
         strikePriceFractionalDenominator |-> strikePriceFractionalDenominator.value,
         strikePriceMinimumTick           |-> strikePriceMinimumTick.value,
         lastTradingDate                  |-> lastTradingDate.value,
         priorDaySettlement               |-> priorDaySettlement.value,
         volatility                       |-> volatility.value,
         currency                         |-> currency.value,
         lotSizeOrFaceValue               |-> lotSizeOrFaceValue.value,
         maturityValue                    |-> maturityValue.value,
         couponRate                       |-> couponRate.value,
         paymentsPerYear                  |-> paymentsPerYear.value,
         blockLotSize                     |-> blockLotSize.value,
         expiryDate                       |-> expiryDate.value,
         basisOfQuotation                 |-> basisOfQuotation.value ], basisOfQuotation.rest)

ZeroOptionsSymbolDirectoryMessage ==
    [ nanoseconds                      |-> [i \in 1 .. 4 |-> 0],
      tradeDate                        |-> [i \in 1 .. 2 |-> 0],
      tradeableInstrumentId            |-> [i \in 1 .. 4 |-> 0],
      symbolName                       |-> [i \in 1 .. 32 |-> 0],
      longName                         |-> [i \in 1 .. 60 |-> 0],
      isin                             |-> [i \in 1 .. 12 |-> 0],
      exchange                         |-> [i \in 1 .. 6 |-> 0],
      instrument                       |-> [i \in 1 .. 6 |-> 0],
      cfiCode                          |-> [i \in 1 .. 6 |-> 0],
      expiryYear                       |-> [i \in 1 .. 2 |-> 0],
      expiryMonth                      |-> [i \in 1 .. 1 |-> 0],
      optionType                       |-> [i \in 1 .. 1 |-> 0],
      strike                           |-> [i \in 1 .. 8 |-> 0],
      underlyingTradeableInstrumentId  |-> [i \in 1 .. 4 |-> 0],
      priceDisplayDecimals             |-> [i \in 1 .. 1 |-> 0],
      priceFractionalDenominator       |-> [i \in 1 .. 4 |-> 0],
      priceMinimumTick                 |-> [i \in 1 .. 4 |-> 0],
      strikePriceDecimalPosition       |-> [i \in 1 .. 1 |-> 0],
      strikePriceFractionalDenominator |-> [i \in 1 .. 4 |-> 0],
      strikePriceMinimumTick           |-> [i \in 1 .. 4 |-> 0],
      lastTradingDate                  |-> [i \in 1 .. 4 |-> 0],
      priorDaySettlement               |-> [i \in 1 .. 8 |-> 0],
      volatility                       |-> [i \in 1 .. 8 |-> 0],
      currency                         |-> [i \in 1 .. 3 |-> 0],
      lotSizeOrFaceValue               |-> [i \in 1 .. 8 |-> 0],
      maturityValue                    |-> [i \in 1 .. 1 |-> 0],
      couponRate                       |-> [i \in 1 .. 2 |-> 0],
      paymentsPerYear                  |-> [i \in 1 .. 1 |-> 0],
      blockLotSize                     |-> [i \in 1 .. 4 |-> 0],
      expiryDate                       |-> [i \in 1 .. 4 |-> 0],
      basisOfQuotation                 |-> [i \in 1 .. 10 |-> 0] ]

(* Options Symbol Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionsSymbolDirectoryMessage ==
    { ZeroOptionsSymbolDirectoryMessage }
        \cup { [ZeroOptionsSymbolDirectoryMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOptionsSymbolDirectoryMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroOptionsSymbolDirectoryMessage EXCEPT !.tradeableInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroOptionsSymbolDirectoryMessage EXCEPT !.symbolName = one] : one \in Sample(32) }
        \cup { [ZeroOptionsSymbolDirectoryMessage EXCEPT !.longName = one] : one \in Sample(60) }
        \cup { [ZeroOptionsSymbolDirectoryMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroOptionsSymbolDirectoryMessage EXCEPT !.exchange = one] : one \in Sample(6) }
        \cup { [ZeroOptionsSymbolDirectoryMessage EXCEPT !.instrument = one] : one \in Sample(6) }
        \cup { [ZeroOptionsSymbolDirectoryMessage EXCEPT !.cfiCode = one] : one \in Sample(6) }
        \cup { [ZeroOptionsSymbolDirectoryMessage EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroOptionsSymbolDirectoryMessage EXCEPT !.expiryMonth = one] : one \in Sample(1) }
        \cup { [ZeroOptionsSymbolDirectoryMessage EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroOptionsSymbolDirectoryMessage EXCEPT !.strike = one] : one \in Sample(8) }
        \cup { [ZeroOptionsSymbolDirectoryMessage EXCEPT !.underlyingTradeableInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroOptionsSymbolDirectoryMessage EXCEPT !.priceDisplayDecimals = one] : one \in Sample(1) }
        \cup { [ZeroOptionsSymbolDirectoryMessage EXCEPT !.priceFractionalDenominator = one] : one \in Sample(4) }
        \cup { [ZeroOptionsSymbolDirectoryMessage EXCEPT !.priceMinimumTick = one] : one \in Sample(4) }
        \cup { [ZeroOptionsSymbolDirectoryMessage EXCEPT !.strikePriceDecimalPosition = one] : one \in Sample(1) }
        \cup { [ZeroOptionsSymbolDirectoryMessage EXCEPT !.strikePriceFractionalDenominator = one] : one \in Sample(4) }
        \cup { [ZeroOptionsSymbolDirectoryMessage EXCEPT !.strikePriceMinimumTick = one] : one \in Sample(4) }
        \cup { [ZeroOptionsSymbolDirectoryMessage EXCEPT !.lastTradingDate = one] : one \in Sample(4) }
        \cup { [ZeroOptionsSymbolDirectoryMessage EXCEPT !.priorDaySettlement = one] : one \in Sample(8) }
        \cup { [ZeroOptionsSymbolDirectoryMessage EXCEPT !.volatility = one] : one \in Sample(8) }
        \cup { [ZeroOptionsSymbolDirectoryMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroOptionsSymbolDirectoryMessage EXCEPT !.lotSizeOrFaceValue = one] : one \in Sample(8) }
        \cup { [ZeroOptionsSymbolDirectoryMessage EXCEPT !.maturityValue = one] : one \in Sample(1) }
        \cup { [ZeroOptionsSymbolDirectoryMessage EXCEPT !.couponRate = one] : one \in Sample(2) }
        \cup { [ZeroOptionsSymbolDirectoryMessage EXCEPT !.paymentsPerYear = one] : one \in Sample(1) }
        \cup { [ZeroOptionsSymbolDirectoryMessage EXCEPT !.blockLotSize = one] : one \in Sample(4) }
        \cup { [ZeroOptionsSymbolDirectoryMessage EXCEPT !.expiryDate = one] : one \in Sample(4) }
        \cup { [ZeroOptionsSymbolDirectoryMessage EXCEPT !.basisOfQuotation = one] : one \in Sample(10) }

(***************************************************************************)
(* Combination Leg: 17 bytes                                               *)
(***************************************************************************)

CombinationLeg ==
    [ tradeableInstrumentIdLeg : Sample(4),
      sideLeg                  : Sample(1),
      ratioLeg                 : Sample(4),
      priceLeg                 : Sample(8) ]

EncodeCombinationLeg(message) ==
    message.tradeableInstrumentIdLeg
        \o message.sideLeg
        \o message.ratioLeg
        \o message.priceLeg

DecodeCombinationLeg(bytes) ==
    LET tradeableInstrumentIdLeg == ReadBytes(bytes, 4) IN IF ~tradeableInstrumentIdLeg.ok THEN Fail ELSE
    LET sideLeg == ReadBytes(tradeableInstrumentIdLeg.rest, 1) IN IF ~sideLeg.ok THEN Fail ELSE
    LET ratioLeg == ReadBytes(sideLeg.rest, 4) IN IF ~ratioLeg.ok THEN Fail ELSE
    LET priceLeg == ReadBytes(ratioLeg.rest, 8) IN IF ~priceLeg.ok THEN Fail ELSE
    Ok([ tradeableInstrumentIdLeg |-> tradeableInstrumentIdLeg.value,
         sideLeg                  |-> sideLeg.value,
         ratioLeg                 |-> ratioLeg.value,
         priceLeg                 |-> priceLeg.value ], priceLeg.rest)

ZeroCombinationLeg ==
    [ tradeableInstrumentIdLeg |-> [i \in 1 .. 4 |-> 0],
      sideLeg                  |-> [i \in 1 .. 1 |-> 0],
      ratioLeg                 |-> [i \in 1 .. 4 |-> 0],
      priceLeg                 |-> [i \in 1 .. 8 |-> 0] ]

(* Combination Leg at zero, then each field in turn at the values it is checked at *)
CheckedCombinationLeg ==
    { ZeroCombinationLeg }
        \cup { [ZeroCombinationLeg EXCEPT !.tradeableInstrumentIdLeg = one] : one \in Sample(4) }
        \cup { [ZeroCombinationLeg EXCEPT !.sideLeg = one] : one \in Sample(1) }
        \cup { [ZeroCombinationLeg EXCEPT !.ratioLeg = one] : one \in Sample(4) }
        \cup { [ZeroCombinationLeg EXCEPT !.priceLeg = one] : one \in Sample(8) }

(* A run of Combination Leg, written one after another *)
RECURSIVE EncodeCombinationLegList(_)
EncodeCombinationLegList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeCombinationLeg(Head(messages)) \o EncodeCombinationLegList(Tail(messages))

(* As many Combination Leg as the field that counts them says *)
RECURSIVE ReadCombinationLegList(_, _)
ReadCombinationLegList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeCombinationLeg(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadCombinationLegList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Combination Leg of each kind, for the lists that carry them *)
OneCombinationLeg == { ZeroCombinationLeg }

(* The 6 slots a run of Combination Leg is written as, whatever the field beside it says are in use *)
SlotsCombinationLeg == { [i \in 1 .. 6 |-> one] : one \in OneCombinationLeg }

(***************************************************************************)
(* Combination Symbol Directory Message                                    *)
(***************************************************************************)

CombinationSymbolDirectoryMessage ==
    [ nanoseconds                : Sample(4),
      tradeDate                  : Sample(2),
      tradeableInstrumentId      : Sample(4),
      symbolName                 : Sample(32),
      longName                   : Sample(60),
      cfiCode                    : Sample(6),
      priceMethod                : Sample(1),
      priceDisplayDecimals       : Sample(1),
      priceFractionalDenominator : Sample(4),
      priceMinimumTick           : Sample(4),
      legs                       : Sample(1),
      combinationLeg             : SlotsCombinationLeg ]

EncodeCombinationSymbolDirectoryMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.tradeableInstrumentId
        \o message.symbolName
        \o message.longName
        \o message.cfiCode
        \o message.priceMethod
        \o message.priceDisplayDecimals
        \o message.priceFractionalDenominator
        \o message.priceMinimumTick
        \o message.legs
        \o EncodeCombinationLegList(message.combinationLeg)

DecodeCombinationSymbolDirectoryMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET tradeableInstrumentId == ReadBytes(tradeDate.rest, 4) IN IF ~tradeableInstrumentId.ok THEN Fail ELSE
    LET symbolName == ReadBytes(tradeableInstrumentId.rest, 32) IN IF ~symbolName.ok THEN Fail ELSE
    LET longName == ReadBytes(symbolName.rest, 60) IN IF ~longName.ok THEN Fail ELSE
    LET cfiCode == ReadBytes(longName.rest, 6) IN IF ~cfiCode.ok THEN Fail ELSE
    LET priceMethod == ReadBytes(cfiCode.rest, 1) IN IF ~priceMethod.ok THEN Fail ELSE
    LET priceDisplayDecimals == ReadBytes(priceMethod.rest, 1) IN IF ~priceDisplayDecimals.ok THEN Fail ELSE
    LET priceFractionalDenominator == ReadBytes(priceDisplayDecimals.rest, 4) IN IF ~priceFractionalDenominator.ok THEN Fail ELSE
    LET priceMinimumTick == ReadBytes(priceFractionalDenominator.rest, 4) IN IF ~priceMinimumTick.ok THEN Fail ELSE
    LET legs == ReadBytes(priceMinimumTick.rest, 1) IN IF ~legs.ok THEN Fail ELSE
    LET combinationLeg == ReadCombinationLegList(legs.rest, 6) IN IF ~combinationLeg.ok THEN Fail ELSE
    Ok([ nanoseconds                |-> nanoseconds.value,
         tradeDate                  |-> tradeDate.value,
         tradeableInstrumentId      |-> tradeableInstrumentId.value,
         symbolName                 |-> symbolName.value,
         longName                   |-> longName.value,
         cfiCode                    |-> cfiCode.value,
         priceMethod                |-> priceMethod.value,
         priceDisplayDecimals       |-> priceDisplayDecimals.value,
         priceFractionalDenominator |-> priceFractionalDenominator.value,
         priceMinimumTick           |-> priceMinimumTick.value,
         legs                       |-> legs.value,
         combinationLeg             |-> combinationLeg.value ], combinationLeg.rest)

ZeroCombinationSymbolDirectoryMessage ==
    [ nanoseconds                |-> [i \in 1 .. 4 |-> 0],
      tradeDate                  |-> [i \in 1 .. 2 |-> 0],
      tradeableInstrumentId      |-> [i \in 1 .. 4 |-> 0],
      symbolName                 |-> [i \in 1 .. 32 |-> 0],
      longName                   |-> [i \in 1 .. 60 |-> 0],
      cfiCode                    |-> [i \in 1 .. 6 |-> 0],
      priceMethod                |-> [i \in 1 .. 1 |-> 0],
      priceDisplayDecimals       |-> [i \in 1 .. 1 |-> 0],
      priceFractionalDenominator |-> [i \in 1 .. 4 |-> 0],
      priceMinimumTick           |-> [i \in 1 .. 4 |-> 0],
      legs                       |-> [i \in 1 .. 1 |-> 0],
      combinationLeg             |-> [i \in 1 .. 6 |-> ZeroCombinationLeg] ]

(* Combination Symbol Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedCombinationSymbolDirectoryMessage ==
    { ZeroCombinationSymbolDirectoryMessage }
        \cup { [ZeroCombinationSymbolDirectoryMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroCombinationSymbolDirectoryMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroCombinationSymbolDirectoryMessage EXCEPT !.tradeableInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroCombinationSymbolDirectoryMessage EXCEPT !.symbolName = one] : one \in Sample(32) }
        \cup { [ZeroCombinationSymbolDirectoryMessage EXCEPT !.longName = one] : one \in Sample(60) }
        \cup { [ZeroCombinationSymbolDirectoryMessage EXCEPT !.cfiCode = one] : one \in Sample(6) }
        \cup { [ZeroCombinationSymbolDirectoryMessage EXCEPT !.priceMethod = one] : one \in Sample(1) }
        \cup { [ZeroCombinationSymbolDirectoryMessage EXCEPT !.priceDisplayDecimals = one] : one \in Sample(1) }
        \cup { [ZeroCombinationSymbolDirectoryMessage EXCEPT !.priceFractionalDenominator = one] : one \in Sample(4) }
        \cup { [ZeroCombinationSymbolDirectoryMessage EXCEPT !.priceMinimumTick = one] : one \in Sample(4) }
        \cup { [ZeroCombinationSymbolDirectoryMessage EXCEPT !.legs = one] : one \in Sample(1) }
        \cup { [ZeroCombinationSymbolDirectoryMessage EXCEPT !.combinationLeg = one] : one \in SlotsCombinationLeg }

(***************************************************************************)
(* Bundle Leg: 17 bytes                                                    *)
(***************************************************************************)

BundleLeg ==
    [ tradeableInstrumentIdLeg : Sample(4),
      sideLeg                  : Sample(1),
      ratioLeg                 : Sample(4),
      priceLeg                 : Sample(8) ]

EncodeBundleLeg(message) ==
    message.tradeableInstrumentIdLeg
        \o message.sideLeg
        \o message.ratioLeg
        \o message.priceLeg

DecodeBundleLeg(bytes) ==
    LET tradeableInstrumentIdLeg == ReadBytes(bytes, 4) IN IF ~tradeableInstrumentIdLeg.ok THEN Fail ELSE
    LET sideLeg == ReadBytes(tradeableInstrumentIdLeg.rest, 1) IN IF ~sideLeg.ok THEN Fail ELSE
    LET ratioLeg == ReadBytes(sideLeg.rest, 4) IN IF ~ratioLeg.ok THEN Fail ELSE
    LET priceLeg == ReadBytes(ratioLeg.rest, 8) IN IF ~priceLeg.ok THEN Fail ELSE
    Ok([ tradeableInstrumentIdLeg |-> tradeableInstrumentIdLeg.value,
         sideLeg                  |-> sideLeg.value,
         ratioLeg                 |-> ratioLeg.value,
         priceLeg                 |-> priceLeg.value ], priceLeg.rest)

ZeroBundleLeg ==
    [ tradeableInstrumentIdLeg |-> [i \in 1 .. 4 |-> 0],
      sideLeg                  |-> [i \in 1 .. 1 |-> 0],
      ratioLeg                 |-> [i \in 1 .. 4 |-> 0],
      priceLeg                 |-> [i \in 1 .. 8 |-> 0] ]

(* Bundle Leg at zero, then each field in turn at the values it is checked at *)
CheckedBundleLeg ==
    { ZeroBundleLeg }
        \cup { [ZeroBundleLeg EXCEPT !.tradeableInstrumentIdLeg = one] : one \in Sample(4) }
        \cup { [ZeroBundleLeg EXCEPT !.sideLeg = one] : one \in Sample(1) }
        \cup { [ZeroBundleLeg EXCEPT !.ratioLeg = one] : one \in Sample(4) }
        \cup { [ZeroBundleLeg EXCEPT !.priceLeg = one] : one \in Sample(8) }

(* A run of Bundle Leg, written one after another *)
RECURSIVE EncodeBundleLegList(_)
EncodeBundleLegList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeBundleLeg(Head(messages)) \o EncodeBundleLegList(Tail(messages))

(* As many Bundle Leg as the field that counts them says *)
RECURSIVE ReadBundleLegList(_, _)
ReadBundleLegList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeBundleLeg(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadBundleLegList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Bundle Leg of each kind, for the lists that carry them *)
OneBundleLeg == { ZeroBundleLeg }

(* The 20 slots a run of Bundle Leg is written as, whatever the field beside it says are in use *)
SlotsBundleLeg == { [i \in 1 .. 20 |-> one] : one \in OneBundleLeg }

(***************************************************************************)
(* Bundles Symbol Directory                                                *)
(***************************************************************************)

BundlesSymbolDirectory ==
    [ nanoseconds                : Sample(4),
      tradeDate                  : Sample(2),
      tradeableInstrumentId      : Sample(4),
      symbolName                 : Sample(32),
      longName                   : Sample(60),
      cfiCode                    : Sample(6),
      priceMethod                : Sample(1),
      priceDisplayDecimals       : Sample(1),
      priceFractionalDenominator : Sample(4),
      priceMinimumTick           : Sample(4),
      legs                       : Sample(1),
      bundleLeg                  : SlotsBundleLeg ]

EncodeBundlesSymbolDirectory(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.tradeableInstrumentId
        \o message.symbolName
        \o message.longName
        \o message.cfiCode
        \o message.priceMethod
        \o message.priceDisplayDecimals
        \o message.priceFractionalDenominator
        \o message.priceMinimumTick
        \o message.legs
        \o EncodeBundleLegList(message.bundleLeg)

DecodeBundlesSymbolDirectory(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET tradeableInstrumentId == ReadBytes(tradeDate.rest, 4) IN IF ~tradeableInstrumentId.ok THEN Fail ELSE
    LET symbolName == ReadBytes(tradeableInstrumentId.rest, 32) IN IF ~symbolName.ok THEN Fail ELSE
    LET longName == ReadBytes(symbolName.rest, 60) IN IF ~longName.ok THEN Fail ELSE
    LET cfiCode == ReadBytes(longName.rest, 6) IN IF ~cfiCode.ok THEN Fail ELSE
    LET priceMethod == ReadBytes(cfiCode.rest, 1) IN IF ~priceMethod.ok THEN Fail ELSE
    LET priceDisplayDecimals == ReadBytes(priceMethod.rest, 1) IN IF ~priceDisplayDecimals.ok THEN Fail ELSE
    LET priceFractionalDenominator == ReadBytes(priceDisplayDecimals.rest, 4) IN IF ~priceFractionalDenominator.ok THEN Fail ELSE
    LET priceMinimumTick == ReadBytes(priceFractionalDenominator.rest, 4) IN IF ~priceMinimumTick.ok THEN Fail ELSE
    LET legs == ReadBytes(priceMinimumTick.rest, 1) IN IF ~legs.ok THEN Fail ELSE
    LET bundleLeg == ReadBundleLegList(legs.rest, 20) IN IF ~bundleLeg.ok THEN Fail ELSE
    Ok([ nanoseconds                |-> nanoseconds.value,
         tradeDate                  |-> tradeDate.value,
         tradeableInstrumentId      |-> tradeableInstrumentId.value,
         symbolName                 |-> symbolName.value,
         longName                   |-> longName.value,
         cfiCode                    |-> cfiCode.value,
         priceMethod                |-> priceMethod.value,
         priceDisplayDecimals       |-> priceDisplayDecimals.value,
         priceFractionalDenominator |-> priceFractionalDenominator.value,
         priceMinimumTick           |-> priceMinimumTick.value,
         legs                       |-> legs.value,
         bundleLeg                  |-> bundleLeg.value ], bundleLeg.rest)

ZeroBundlesSymbolDirectory ==
    [ nanoseconds                |-> [i \in 1 .. 4 |-> 0],
      tradeDate                  |-> [i \in 1 .. 2 |-> 0],
      tradeableInstrumentId      |-> [i \in 1 .. 4 |-> 0],
      symbolName                 |-> [i \in 1 .. 32 |-> 0],
      longName                   |-> [i \in 1 .. 60 |-> 0],
      cfiCode                    |-> [i \in 1 .. 6 |-> 0],
      priceMethod                |-> [i \in 1 .. 1 |-> 0],
      priceDisplayDecimals       |-> [i \in 1 .. 1 |-> 0],
      priceFractionalDenominator |-> [i \in 1 .. 4 |-> 0],
      priceMinimumTick           |-> [i \in 1 .. 4 |-> 0],
      legs                       |-> [i \in 1 .. 1 |-> 0],
      bundleLeg                  |-> [i \in 1 .. 20 |-> ZeroBundleLeg] ]

(* Bundles Symbol Directory at zero, then each field in turn at the values it is checked at *)
CheckedBundlesSymbolDirectory ==
    { ZeroBundlesSymbolDirectory }
        \cup { [ZeroBundlesSymbolDirectory EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroBundlesSymbolDirectory EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroBundlesSymbolDirectory EXCEPT !.tradeableInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroBundlesSymbolDirectory EXCEPT !.symbolName = one] : one \in Sample(32) }
        \cup { [ZeroBundlesSymbolDirectory EXCEPT !.longName = one] : one \in Sample(60) }
        \cup { [ZeroBundlesSymbolDirectory EXCEPT !.cfiCode = one] : one \in Sample(6) }
        \cup { [ZeroBundlesSymbolDirectory EXCEPT !.priceMethod = one] : one \in Sample(1) }
        \cup { [ZeroBundlesSymbolDirectory EXCEPT !.priceDisplayDecimals = one] : one \in Sample(1) }
        \cup { [ZeroBundlesSymbolDirectory EXCEPT !.priceFractionalDenominator = one] : one \in Sample(4) }
        \cup { [ZeroBundlesSymbolDirectory EXCEPT !.priceMinimumTick = one] : one \in Sample(4) }
        \cup { [ZeroBundlesSymbolDirectory EXCEPT !.legs = one] : one \in Sample(1) }
        \cup { [ZeroBundlesSymbolDirectory EXCEPT !.bundleLeg = one] : one \in SlotsBundleLeg }

(***************************************************************************)
(* Order Book State Message: 11 bytes                                      *)
(***************************************************************************)

OrderBookStateMessage ==
    [ nanoseconds           : Sample(4),
      tradeDate             : Sample(2),
      tradeableInstrumentId : Sample(4),
      sessionState          : Sample(1) ]

EncodeOrderBookStateMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.tradeableInstrumentId
        \o message.sessionState

DecodeOrderBookStateMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET tradeableInstrumentId == ReadBytes(tradeDate.rest, 4) IN IF ~tradeableInstrumentId.ok THEN Fail ELSE
    LET sessionState == ReadBytes(tradeableInstrumentId.rest, 1) IN IF ~sessionState.ok THEN Fail ELSE
    Ok([ nanoseconds           |-> nanoseconds.value,
         tradeDate             |-> tradeDate.value,
         tradeableInstrumentId |-> tradeableInstrumentId.value,
         sessionState          |-> sessionState.value ], sessionState.rest)

ZeroOrderBookStateMessage ==
    [ nanoseconds           |-> [i \in 1 .. 4 |-> 0],
      tradeDate             |-> [i \in 1 .. 2 |-> 0],
      tradeableInstrumentId |-> [i \in 1 .. 4 |-> 0],
      sessionState          |-> [i \in 1 .. 1 |-> 0] ]

(* Order Book State Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderBookStateMessage ==
    { ZeroOrderBookStateMessage }
        \cup { [ZeroOrderBookStateMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookStateMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroOrderBookStateMessage EXCEPT !.tradeableInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookStateMessage EXCEPT !.sessionState = one] : one \in Sample(1) }

(***************************************************************************)
(* Add Order Message: 39 bytes                                             *)
(***************************************************************************)

AddOrderMessage ==
    [ nanoseconds           : Sample(4),
      tradeDate             : Sample(2),
      tradeableInstrumentId : Sample(4),
      side                  : Sample(1),
      orderId               : Sample(8),
      orderBookPriority     : Sample(8),
      quantity              : Sample(4),
      price                 : Sample(8) ]

EncodeAddOrderMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.tradeableInstrumentId
        \o message.side
        \o message.orderId
        \o message.orderBookPriority
        \o message.quantity
        \o message.price

DecodeAddOrderMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET tradeableInstrumentId == ReadBytes(tradeDate.rest, 4) IN IF ~tradeableInstrumentId.ok THEN Fail ELSE
    LET side == ReadBytes(tradeableInstrumentId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderId == ReadBytes(side.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET orderBookPriority == ReadBytes(orderId.rest, 8) IN IF ~orderBookPriority.ok THEN Fail ELSE
    LET quantity == ReadBytes(orderBookPriority.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 8) IN IF ~price.ok THEN Fail ELSE
    Ok([ nanoseconds           |-> nanoseconds.value,
         tradeDate             |-> tradeDate.value,
         tradeableInstrumentId |-> tradeableInstrumentId.value,
         side                  |-> side.value,
         orderId               |-> orderId.value,
         orderBookPriority     |-> orderBookPriority.value,
         quantity              |-> quantity.value,
         price                 |-> price.value ], price.rest)

ZeroAddOrderMessage ==
    [ nanoseconds           |-> [i \in 1 .. 4 |-> 0],
      tradeDate             |-> [i \in 1 .. 2 |-> 0],
      tradeableInstrumentId |-> [i \in 1 .. 4 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      orderId               |-> [i \in 1 .. 8 |-> 0],
      orderBookPriority     |-> [i \in 1 .. 8 |-> 0],
      quantity              |-> [i \in 1 .. 4 |-> 0],
      price                 |-> [i \in 1 .. 8 |-> 0] ]

(* Add Order Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderMessage ==
    { ZeroAddOrderMessage }
        \cup { [ZeroAddOrderMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderMessage EXCEPT !.tradeableInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderBookPriority = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.price = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Volume Cancelled Message: 23 bytes                                *)
(***************************************************************************)

OrderVolumeCancelledMessage ==
    [ nanoseconds           : Sample(4),
      tradeDate             : Sample(2),
      tradeableInstrumentId : Sample(4),
      side                  : Sample(1),
      orderId               : Sample(8),
      quantity              : Sample(4) ]

EncodeOrderVolumeCancelledMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.tradeableInstrumentId
        \o message.side
        \o message.orderId
        \o message.quantity

DecodeOrderVolumeCancelledMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET tradeableInstrumentId == ReadBytes(tradeDate.rest, 4) IN IF ~tradeableInstrumentId.ok THEN Fail ELSE
    LET side == ReadBytes(tradeableInstrumentId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderId == ReadBytes(side.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET quantity == ReadBytes(orderId.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    Ok([ nanoseconds           |-> nanoseconds.value,
         tradeDate             |-> tradeDate.value,
         tradeableInstrumentId |-> tradeableInstrumentId.value,
         side                  |-> side.value,
         orderId               |-> orderId.value,
         quantity              |-> quantity.value ], quantity.rest)

ZeroOrderVolumeCancelledMessage ==
    [ nanoseconds           |-> [i \in 1 .. 4 |-> 0],
      tradeDate             |-> [i \in 1 .. 2 |-> 0],
      tradeableInstrumentId |-> [i \in 1 .. 4 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      orderId               |-> [i \in 1 .. 8 |-> 0],
      quantity              |-> [i \in 1 .. 4 |-> 0] ]

(* Order Volume Cancelled Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderVolumeCancelledMessage ==
    { ZeroOrderVolumeCancelledMessage }
        \cup { [ZeroOrderVolumeCancelledMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderVolumeCancelledMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroOrderVolumeCancelledMessage EXCEPT !.tradeableInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderVolumeCancelledMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderVolumeCancelledMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderVolumeCancelledMessage EXCEPT !.quantity = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Deleted Message: 19 bytes                                         *)
(***************************************************************************)

OrderDeletedMessage ==
    [ nanoseconds           : Sample(4),
      tradeDate             : Sample(2),
      tradeableInstrumentId : Sample(4),
      side                  : Sample(1),
      orderId               : Sample(8) ]

EncodeOrderDeletedMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.tradeableInstrumentId
        \o message.side
        \o message.orderId

DecodeOrderDeletedMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET tradeableInstrumentId == ReadBytes(tradeDate.rest, 4) IN IF ~tradeableInstrumentId.ok THEN Fail ELSE
    LET side == ReadBytes(tradeableInstrumentId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderId == ReadBytes(side.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    Ok([ nanoseconds           |-> nanoseconds.value,
         tradeDate             |-> tradeDate.value,
         tradeableInstrumentId |-> tradeableInstrumentId.value,
         side                  |-> side.value,
         orderId               |-> orderId.value ], orderId.rest)

ZeroOrderDeletedMessage ==
    [ nanoseconds           |-> [i \in 1 .. 4 |-> 0],
      tradeDate             |-> [i \in 1 .. 2 |-> 0],
      tradeableInstrumentId |-> [i \in 1 .. 4 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      orderId               |-> [i \in 1 .. 8 |-> 0] ]

(* Order Deleted Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderDeletedMessage ==
    { ZeroOrderDeletedMessage }
        \cup { [ZeroOrderDeletedMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderDeletedMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroOrderDeletedMessage EXCEPT !.tradeableInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderDeletedMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderDeletedMessage EXCEPT !.orderId = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Executed Message: 55 bytes                                        *)
(***************************************************************************)

OrderExecutedMessage ==
    [ nanoseconds           : Sample(4),
      tradeDate             : Sample(2),
      tradeableInstrumentId : Sample(4),
      side                  : Sample(1),
      orderId               : Sample(8),
      quantityRemaining     : Sample(4),
      tradeType             : Sample(1),
      tradeId               : Sample(8),
      executedQuantity      : Sample(4),
      tradePrice            : Sample(8),
      combinationTradeId    : Sample(8),
      counterPartyId        : Sample(3) ]

EncodeOrderExecutedMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.tradeableInstrumentId
        \o message.side
        \o message.orderId
        \o message.quantityRemaining
        \o message.tradeType
        \o message.tradeId
        \o message.executedQuantity
        \o message.tradePrice
        \o message.combinationTradeId
        \o message.counterPartyId

DecodeOrderExecutedMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET tradeableInstrumentId == ReadBytes(tradeDate.rest, 4) IN IF ~tradeableInstrumentId.ok THEN Fail ELSE
    LET side == ReadBytes(tradeableInstrumentId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderId == ReadBytes(side.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET quantityRemaining == ReadBytes(orderId.rest, 4) IN IF ~quantityRemaining.ok THEN Fail ELSE
    LET tradeType == ReadBytes(quantityRemaining.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET tradeId == ReadBytes(tradeType.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(tradeId.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(executedQuantity.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET combinationTradeId == ReadBytes(tradePrice.rest, 8) IN IF ~combinationTradeId.ok THEN Fail ELSE
    LET counterPartyId == ReadBytes(combinationTradeId.rest, 3) IN IF ~counterPartyId.ok THEN Fail ELSE
    Ok([ nanoseconds           |-> nanoseconds.value,
         tradeDate             |-> tradeDate.value,
         tradeableInstrumentId |-> tradeableInstrumentId.value,
         side                  |-> side.value,
         orderId               |-> orderId.value,
         quantityRemaining     |-> quantityRemaining.value,
         tradeType             |-> tradeType.value,
         tradeId               |-> tradeId.value,
         executedQuantity      |-> executedQuantity.value,
         tradePrice            |-> tradePrice.value,
         combinationTradeId    |-> combinationTradeId.value,
         counterPartyId        |-> counterPartyId.value ], counterPartyId.rest)

ZeroOrderExecutedMessage ==
    [ nanoseconds           |-> [i \in 1 .. 4 |-> 0],
      tradeDate             |-> [i \in 1 .. 2 |-> 0],
      tradeableInstrumentId |-> [i \in 1 .. 4 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      orderId               |-> [i \in 1 .. 8 |-> 0],
      quantityRemaining     |-> [i \in 1 .. 4 |-> 0],
      tradeType             |-> [i \in 1 .. 1 |-> 0],
      tradeId               |-> [i \in 1 .. 8 |-> 0],
      executedQuantity      |-> [i \in 1 .. 4 |-> 0],
      tradePrice            |-> [i \in 1 .. 8 |-> 0],
      combinationTradeId    |-> [i \in 1 .. 8 |-> 0],
      counterPartyId        |-> [i \in 1 .. 3 |-> 0] ]

(* Order Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedMessage ==
    { ZeroOrderExecutedMessage }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.tradeableInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.quantityRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.combinationTradeId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.counterPartyId = one] : one \in Sample(3) }

(***************************************************************************)
(* Auction Order Executed Message: 52 bytes                                *)
(***************************************************************************)

AuctionOrderExecutedMessage ==
    [ nanoseconds           : Sample(4),
      tradeDate             : Sample(2),
      tradeableInstrumentId : Sample(4),
      side                  : Sample(1),
      orderId               : Sample(8),
      quantityRemaining     : Sample(4),
      tradeType             : Sample(1),
      tradeId               : Sample(8),
      executedQuantity      : Sample(4),
      tradePrice            : Sample(8),
      oppositeOrderId       : Sample(8) ]

EncodeAuctionOrderExecutedMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.tradeableInstrumentId
        \o message.side
        \o message.orderId
        \o message.quantityRemaining
        \o message.tradeType
        \o message.tradeId
        \o message.executedQuantity
        \o message.tradePrice
        \o message.oppositeOrderId

DecodeAuctionOrderExecutedMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET tradeableInstrumentId == ReadBytes(tradeDate.rest, 4) IN IF ~tradeableInstrumentId.ok THEN Fail ELSE
    LET side == ReadBytes(tradeableInstrumentId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderId == ReadBytes(side.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET quantityRemaining == ReadBytes(orderId.rest, 4) IN IF ~quantityRemaining.ok THEN Fail ELSE
    LET tradeType == ReadBytes(quantityRemaining.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET tradeId == ReadBytes(tradeType.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(tradeId.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(executedQuantity.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET oppositeOrderId == ReadBytes(tradePrice.rest, 8) IN IF ~oppositeOrderId.ok THEN Fail ELSE
    Ok([ nanoseconds           |-> nanoseconds.value,
         tradeDate             |-> tradeDate.value,
         tradeableInstrumentId |-> tradeableInstrumentId.value,
         side                  |-> side.value,
         orderId               |-> orderId.value,
         quantityRemaining     |-> quantityRemaining.value,
         tradeType             |-> tradeType.value,
         tradeId               |-> tradeId.value,
         executedQuantity      |-> executedQuantity.value,
         tradePrice            |-> tradePrice.value,
         oppositeOrderId       |-> oppositeOrderId.value ], oppositeOrderId.rest)

ZeroAuctionOrderExecutedMessage ==
    [ nanoseconds           |-> [i \in 1 .. 4 |-> 0],
      tradeDate             |-> [i \in 1 .. 2 |-> 0],
      tradeableInstrumentId |-> [i \in 1 .. 4 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      orderId               |-> [i \in 1 .. 8 |-> 0],
      quantityRemaining     |-> [i \in 1 .. 4 |-> 0],
      tradeType             |-> [i \in 1 .. 1 |-> 0],
      tradeId               |-> [i \in 1 .. 8 |-> 0],
      executedQuantity      |-> [i \in 1 .. 4 |-> 0],
      tradePrice            |-> [i \in 1 .. 8 |-> 0],
      oppositeOrderId       |-> [i \in 1 .. 8 |-> 0] ]

(* Auction Order Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionOrderExecutedMessage ==
    { ZeroAuctionOrderExecutedMessage }
        \cup { [ZeroAuctionOrderExecutedMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroAuctionOrderExecutedMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroAuctionOrderExecutedMessage EXCEPT !.tradeableInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroAuctionOrderExecutedMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAuctionOrderExecutedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAuctionOrderExecutedMessage EXCEPT !.quantityRemaining = one] : one \in Sample(4) }
        \cup { [ZeroAuctionOrderExecutedMessage EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionOrderExecutedMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroAuctionOrderExecutedMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroAuctionOrderExecutedMessage EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionOrderExecutedMessage EXCEPT !.oppositeOrderId = one] : one \in Sample(8) }

(***************************************************************************)
(* Combination Order Executed Message: 65 bytes                            *)
(***************************************************************************)

CombinationOrderExecutedMessage ==
    [ nanoseconds                   : Sample(4),
      tradeDate                     : Sample(2),
      tradeableInstrumentId         : Sample(4),
      side                          : Sample(1),
      orderId                       : Sample(8),
      quantityRemaining             : Sample(4),
      tradeType                     : Sample(1),
      tradeId                       : Sample(8),
      executedQuantity              : Sample(4),
      tradePrice                    : Sample(8),
      oppositeTradeableInstrumentId : Sample(4),
      oppositeSide                  : Sample(1),
      oppositeOrderId               : Sample(8),
      combinationTradeId            : Sample(8) ]

EncodeCombinationOrderExecutedMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.tradeableInstrumentId
        \o message.side
        \o message.orderId
        \o message.quantityRemaining
        \o message.tradeType
        \o message.tradeId
        \o message.executedQuantity
        \o message.tradePrice
        \o message.oppositeTradeableInstrumentId
        \o message.oppositeSide
        \o message.oppositeOrderId
        \o message.combinationTradeId

DecodeCombinationOrderExecutedMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET tradeableInstrumentId == ReadBytes(tradeDate.rest, 4) IN IF ~tradeableInstrumentId.ok THEN Fail ELSE
    LET side == ReadBytes(tradeableInstrumentId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderId == ReadBytes(side.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET quantityRemaining == ReadBytes(orderId.rest, 4) IN IF ~quantityRemaining.ok THEN Fail ELSE
    LET tradeType == ReadBytes(quantityRemaining.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET tradeId == ReadBytes(tradeType.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(tradeId.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(executedQuantity.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET oppositeTradeableInstrumentId == ReadBytes(tradePrice.rest, 4) IN IF ~oppositeTradeableInstrumentId.ok THEN Fail ELSE
    LET oppositeSide == ReadBytes(oppositeTradeableInstrumentId.rest, 1) IN IF ~oppositeSide.ok THEN Fail ELSE
    LET oppositeOrderId == ReadBytes(oppositeSide.rest, 8) IN IF ~oppositeOrderId.ok THEN Fail ELSE
    LET combinationTradeId == ReadBytes(oppositeOrderId.rest, 8) IN IF ~combinationTradeId.ok THEN Fail ELSE
    Ok([ nanoseconds                   |-> nanoseconds.value,
         tradeDate                     |-> tradeDate.value,
         tradeableInstrumentId         |-> tradeableInstrumentId.value,
         side                          |-> side.value,
         orderId                       |-> orderId.value,
         quantityRemaining             |-> quantityRemaining.value,
         tradeType                     |-> tradeType.value,
         tradeId                       |-> tradeId.value,
         executedQuantity              |-> executedQuantity.value,
         tradePrice                    |-> tradePrice.value,
         oppositeTradeableInstrumentId |-> oppositeTradeableInstrumentId.value,
         oppositeSide                  |-> oppositeSide.value,
         oppositeOrderId               |-> oppositeOrderId.value,
         combinationTradeId            |-> combinationTradeId.value ], combinationTradeId.rest)

ZeroCombinationOrderExecutedMessage ==
    [ nanoseconds                   |-> [i \in 1 .. 4 |-> 0],
      tradeDate                     |-> [i \in 1 .. 2 |-> 0],
      tradeableInstrumentId         |-> [i \in 1 .. 4 |-> 0],
      side                          |-> [i \in 1 .. 1 |-> 0],
      orderId                       |-> [i \in 1 .. 8 |-> 0],
      quantityRemaining             |-> [i \in 1 .. 4 |-> 0],
      tradeType                     |-> [i \in 1 .. 1 |-> 0],
      tradeId                       |-> [i \in 1 .. 8 |-> 0],
      executedQuantity              |-> [i \in 1 .. 4 |-> 0],
      tradePrice                    |-> [i \in 1 .. 8 |-> 0],
      oppositeTradeableInstrumentId |-> [i \in 1 .. 4 |-> 0],
      oppositeSide                  |-> [i \in 1 .. 1 |-> 0],
      oppositeOrderId               |-> [i \in 1 .. 8 |-> 0],
      combinationTradeId            |-> [i \in 1 .. 8 |-> 0] ]

(* Combination Order Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedCombinationOrderExecutedMessage ==
    { ZeroCombinationOrderExecutedMessage }
        \cup { [ZeroCombinationOrderExecutedMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroCombinationOrderExecutedMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroCombinationOrderExecutedMessage EXCEPT !.tradeableInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroCombinationOrderExecutedMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroCombinationOrderExecutedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroCombinationOrderExecutedMessage EXCEPT !.quantityRemaining = one] : one \in Sample(4) }
        \cup { [ZeroCombinationOrderExecutedMessage EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroCombinationOrderExecutedMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroCombinationOrderExecutedMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroCombinationOrderExecutedMessage EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroCombinationOrderExecutedMessage EXCEPT !.oppositeTradeableInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroCombinationOrderExecutedMessage EXCEPT !.oppositeSide = one] : one \in Sample(1) }
        \cup { [ZeroCombinationOrderExecutedMessage EXCEPT !.oppositeOrderId = one] : one \in Sample(8) }
        \cup { [ZeroCombinationOrderExecutedMessage EXCEPT !.combinationTradeId = one] : one \in Sample(8) }

(***************************************************************************)
(* Implied Order Added Message: 39 bytes                                   *)
(***************************************************************************)

ImpliedOrderAddedMessage ==
    [ nanoseconds           : Sample(4),
      tradeDate             : Sample(2),
      tradeableInstrumentId : Sample(4),
      side                  : Sample(1),
      orderId               : Sample(8),
      orderBookPriority     : Sample(8),
      quantity              : Sample(4),
      price                 : Sample(8) ]

EncodeImpliedOrderAddedMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.tradeableInstrumentId
        \o message.side
        \o message.orderId
        \o message.orderBookPriority
        \o message.quantity
        \o message.price

DecodeImpliedOrderAddedMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET tradeableInstrumentId == ReadBytes(tradeDate.rest, 4) IN IF ~tradeableInstrumentId.ok THEN Fail ELSE
    LET side == ReadBytes(tradeableInstrumentId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderId == ReadBytes(side.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET orderBookPriority == ReadBytes(orderId.rest, 8) IN IF ~orderBookPriority.ok THEN Fail ELSE
    LET quantity == ReadBytes(orderBookPriority.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 8) IN IF ~price.ok THEN Fail ELSE
    Ok([ nanoseconds           |-> nanoseconds.value,
         tradeDate             |-> tradeDate.value,
         tradeableInstrumentId |-> tradeableInstrumentId.value,
         side                  |-> side.value,
         orderId               |-> orderId.value,
         orderBookPriority     |-> orderBookPriority.value,
         quantity              |-> quantity.value,
         price                 |-> price.value ], price.rest)

ZeroImpliedOrderAddedMessage ==
    [ nanoseconds           |-> [i \in 1 .. 4 |-> 0],
      tradeDate             |-> [i \in 1 .. 2 |-> 0],
      tradeableInstrumentId |-> [i \in 1 .. 4 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      orderId               |-> [i \in 1 .. 8 |-> 0],
      orderBookPriority     |-> [i \in 1 .. 8 |-> 0],
      quantity              |-> [i \in 1 .. 4 |-> 0],
      price                 |-> [i \in 1 .. 8 |-> 0] ]

(* Implied Order Added Message at zero, then each field in turn at the values it is checked at *)
CheckedImpliedOrderAddedMessage ==
    { ZeroImpliedOrderAddedMessage }
        \cup { [ZeroImpliedOrderAddedMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroImpliedOrderAddedMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroImpliedOrderAddedMessage EXCEPT !.tradeableInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroImpliedOrderAddedMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroImpliedOrderAddedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroImpliedOrderAddedMessage EXCEPT !.orderBookPriority = one] : one \in Sample(8) }
        \cup { [ZeroImpliedOrderAddedMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroImpliedOrderAddedMessage EXCEPT !.price = one] : one \in Sample(8) }

(***************************************************************************)
(* Implied Order Replaced Message: 39 bytes                                *)
(***************************************************************************)

ImpliedOrderReplacedMessage ==
    [ nanoseconds           : Sample(4),
      tradeDate             : Sample(2),
      tradeableInstrumentId : Sample(4),
      side                  : Sample(1),
      orderId               : Sample(8),
      orderBookPriority     : Sample(8),
      quantity              : Sample(4),
      price                 : Sample(8) ]

EncodeImpliedOrderReplacedMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.tradeableInstrumentId
        \o message.side
        \o message.orderId
        \o message.orderBookPriority
        \o message.quantity
        \o message.price

DecodeImpliedOrderReplacedMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET tradeableInstrumentId == ReadBytes(tradeDate.rest, 4) IN IF ~tradeableInstrumentId.ok THEN Fail ELSE
    LET side == ReadBytes(tradeableInstrumentId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderId == ReadBytes(side.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET orderBookPriority == ReadBytes(orderId.rest, 8) IN IF ~orderBookPriority.ok THEN Fail ELSE
    LET quantity == ReadBytes(orderBookPriority.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 8) IN IF ~price.ok THEN Fail ELSE
    Ok([ nanoseconds           |-> nanoseconds.value,
         tradeDate             |-> tradeDate.value,
         tradeableInstrumentId |-> tradeableInstrumentId.value,
         side                  |-> side.value,
         orderId               |-> orderId.value,
         orderBookPriority     |-> orderBookPriority.value,
         quantity              |-> quantity.value,
         price                 |-> price.value ], price.rest)

ZeroImpliedOrderReplacedMessage ==
    [ nanoseconds           |-> [i \in 1 .. 4 |-> 0],
      tradeDate             |-> [i \in 1 .. 2 |-> 0],
      tradeableInstrumentId |-> [i \in 1 .. 4 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      orderId               |-> [i \in 1 .. 8 |-> 0],
      orderBookPriority     |-> [i \in 1 .. 8 |-> 0],
      quantity              |-> [i \in 1 .. 4 |-> 0],
      price                 |-> [i \in 1 .. 8 |-> 0] ]

(* Implied Order Replaced Message at zero, then each field in turn at the values it is checked at *)
CheckedImpliedOrderReplacedMessage ==
    { ZeroImpliedOrderReplacedMessage }
        \cup { [ZeroImpliedOrderReplacedMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroImpliedOrderReplacedMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroImpliedOrderReplacedMessage EXCEPT !.tradeableInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroImpliedOrderReplacedMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroImpliedOrderReplacedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroImpliedOrderReplacedMessage EXCEPT !.orderBookPriority = one] : one \in Sample(8) }
        \cup { [ZeroImpliedOrderReplacedMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroImpliedOrderReplacedMessage EXCEPT !.price = one] : one \in Sample(8) }

(***************************************************************************)
(* Implied Order Deleted Message: 19 bytes                                 *)
(***************************************************************************)

ImpliedOrderDeletedMessage ==
    [ nanoseconds           : Sample(4),
      tradeDate             : Sample(2),
      tradeableInstrumentId : Sample(4),
      side                  : Sample(1),
      orderId               : Sample(8) ]

EncodeImpliedOrderDeletedMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.tradeableInstrumentId
        \o message.side
        \o message.orderId

DecodeImpliedOrderDeletedMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET tradeableInstrumentId == ReadBytes(tradeDate.rest, 4) IN IF ~tradeableInstrumentId.ok THEN Fail ELSE
    LET side == ReadBytes(tradeableInstrumentId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderId == ReadBytes(side.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    Ok([ nanoseconds           |-> nanoseconds.value,
         tradeDate             |-> tradeDate.value,
         tradeableInstrumentId |-> tradeableInstrumentId.value,
         side                  |-> side.value,
         orderId               |-> orderId.value ], orderId.rest)

ZeroImpliedOrderDeletedMessage ==
    [ nanoseconds           |-> [i \in 1 .. 4 |-> 0],
      tradeDate             |-> [i \in 1 .. 2 |-> 0],
      tradeableInstrumentId |-> [i \in 1 .. 4 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      orderId               |-> [i \in 1 .. 8 |-> 0] ]

(* Implied Order Deleted Message at zero, then each field in turn at the values it is checked at *)
CheckedImpliedOrderDeletedMessage ==
    { ZeroImpliedOrderDeletedMessage }
        \cup { [ZeroImpliedOrderDeletedMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroImpliedOrderDeletedMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroImpliedOrderDeletedMessage EXCEPT !.tradeableInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroImpliedOrderDeletedMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroImpliedOrderDeletedMessage EXCEPT !.orderId = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Executed Message: 45 bytes                                        *)
(***************************************************************************)

TradeExecutedMessage ==
    [ nanoseconds           : Sample(4),
      tradeDate             : Sample(2),
      tradeableInstrumentId : Sample(4),
      tradeType             : Sample(1),
      tradeId               : Sample(8),
      executedQuantity      : Sample(4),
      tradePrice            : Sample(8),
      combinationTradeId    : Sample(8),
      participantIdBuyer    : Sample(3),
      participantIdSeller   : Sample(3) ]

EncodeTradeExecutedMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.tradeableInstrumentId
        \o message.tradeType
        \o message.tradeId
        \o message.executedQuantity
        \o message.tradePrice
        \o message.combinationTradeId
        \o message.participantIdBuyer
        \o message.participantIdSeller

DecodeTradeExecutedMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET tradeableInstrumentId == ReadBytes(tradeDate.rest, 4) IN IF ~tradeableInstrumentId.ok THEN Fail ELSE
    LET tradeType == ReadBytes(tradeableInstrumentId.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET tradeId == ReadBytes(tradeType.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(tradeId.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(executedQuantity.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET combinationTradeId == ReadBytes(tradePrice.rest, 8) IN IF ~combinationTradeId.ok THEN Fail ELSE
    LET participantIdBuyer == ReadBytes(combinationTradeId.rest, 3) IN IF ~participantIdBuyer.ok THEN Fail ELSE
    LET participantIdSeller == ReadBytes(participantIdBuyer.rest, 3) IN IF ~participantIdSeller.ok THEN Fail ELSE
    Ok([ nanoseconds           |-> nanoseconds.value,
         tradeDate             |-> tradeDate.value,
         tradeableInstrumentId |-> tradeableInstrumentId.value,
         tradeType             |-> tradeType.value,
         tradeId               |-> tradeId.value,
         executedQuantity      |-> executedQuantity.value,
         tradePrice            |-> tradePrice.value,
         combinationTradeId    |-> combinationTradeId.value,
         participantIdBuyer    |-> participantIdBuyer.value,
         participantIdSeller   |-> participantIdSeller.value ], participantIdSeller.rest)

ZeroTradeExecutedMessage ==
    [ nanoseconds           |-> [i \in 1 .. 4 |-> 0],
      tradeDate             |-> [i \in 1 .. 2 |-> 0],
      tradeableInstrumentId |-> [i \in 1 .. 4 |-> 0],
      tradeType             |-> [i \in 1 .. 1 |-> 0],
      tradeId               |-> [i \in 1 .. 8 |-> 0],
      executedQuantity      |-> [i \in 1 .. 4 |-> 0],
      tradePrice            |-> [i \in 1 .. 8 |-> 0],
      combinationTradeId    |-> [i \in 1 .. 8 |-> 0],
      participantIdBuyer    |-> [i \in 1 .. 3 |-> 0],
      participantIdSeller   |-> [i \in 1 .. 3 |-> 0] ]

(* Trade Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeExecutedMessage ==
    { ZeroTradeExecutedMessage }
        \cup { [ZeroTradeExecutedMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroTradeExecutedMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroTradeExecutedMessage EXCEPT !.tradeableInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroTradeExecutedMessage EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroTradeExecutedMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroTradeExecutedMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroTradeExecutedMessage EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeExecutedMessage EXCEPT !.combinationTradeId = one] : one \in Sample(8) }
        \cup { [ZeroTradeExecutedMessage EXCEPT !.participantIdBuyer = one] : one \in Sample(3) }
        \cup { [ZeroTradeExecutedMessage EXCEPT !.participantIdSeller = one] : one \in Sample(3) }

(***************************************************************************)
(* Combination Trade Executed Message: 79 bytes                            *)
(***************************************************************************)

CombinationTradeExecutedMessage ==
    [ nanoseconds                 : Sample(4),
      tradeDate                   : Sample(2),
      tradeableInstrumentId       : Sample(4),
      tradeType                   : Sample(1),
      tradeId                     : Sample(8),
      executedQuantity            : Sample(4),
      tradePrice                  : Sample(8),
      buyerTradeableInstrumentId  : Sample(4),
      buyerSide                   : Sample(1),
      buyerOrderId                : Sample(8),
      buyerCombinationTradeId     : Sample(8),
      buyerParticipantId          : Sample(3),
      sellerTradeableInstrumentId : Sample(4),
      sellerSide                  : Sample(1),
      sellerOrderId               : Sample(8),
      sellerCombinationTradeId    : Sample(8),
      sellerParticipantId         : Sample(3) ]

EncodeCombinationTradeExecutedMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.tradeableInstrumentId
        \o message.tradeType
        \o message.tradeId
        \o message.executedQuantity
        \o message.tradePrice
        \o message.buyerTradeableInstrumentId
        \o message.buyerSide
        \o message.buyerOrderId
        \o message.buyerCombinationTradeId
        \o message.buyerParticipantId
        \o message.sellerTradeableInstrumentId
        \o message.sellerSide
        \o message.sellerOrderId
        \o message.sellerCombinationTradeId
        \o message.sellerParticipantId

DecodeCombinationTradeExecutedMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET tradeableInstrumentId == ReadBytes(tradeDate.rest, 4) IN IF ~tradeableInstrumentId.ok THEN Fail ELSE
    LET tradeType == ReadBytes(tradeableInstrumentId.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET tradeId == ReadBytes(tradeType.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(tradeId.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(executedQuantity.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET buyerTradeableInstrumentId == ReadBytes(tradePrice.rest, 4) IN IF ~buyerTradeableInstrumentId.ok THEN Fail ELSE
    LET buyerSide == ReadBytes(buyerTradeableInstrumentId.rest, 1) IN IF ~buyerSide.ok THEN Fail ELSE
    LET buyerOrderId == ReadBytes(buyerSide.rest, 8) IN IF ~buyerOrderId.ok THEN Fail ELSE
    LET buyerCombinationTradeId == ReadBytes(buyerOrderId.rest, 8) IN IF ~buyerCombinationTradeId.ok THEN Fail ELSE
    LET buyerParticipantId == ReadBytes(buyerCombinationTradeId.rest, 3) IN IF ~buyerParticipantId.ok THEN Fail ELSE
    LET sellerTradeableInstrumentId == ReadBytes(buyerParticipantId.rest, 4) IN IF ~sellerTradeableInstrumentId.ok THEN Fail ELSE
    LET sellerSide == ReadBytes(sellerTradeableInstrumentId.rest, 1) IN IF ~sellerSide.ok THEN Fail ELSE
    LET sellerOrderId == ReadBytes(sellerSide.rest, 8) IN IF ~sellerOrderId.ok THEN Fail ELSE
    LET sellerCombinationTradeId == ReadBytes(sellerOrderId.rest, 8) IN IF ~sellerCombinationTradeId.ok THEN Fail ELSE
    LET sellerParticipantId == ReadBytes(sellerCombinationTradeId.rest, 3) IN IF ~sellerParticipantId.ok THEN Fail ELSE
    Ok([ nanoseconds                 |-> nanoseconds.value,
         tradeDate                   |-> tradeDate.value,
         tradeableInstrumentId       |-> tradeableInstrumentId.value,
         tradeType                   |-> tradeType.value,
         tradeId                     |-> tradeId.value,
         executedQuantity            |-> executedQuantity.value,
         tradePrice                  |-> tradePrice.value,
         buyerTradeableInstrumentId  |-> buyerTradeableInstrumentId.value,
         buyerSide                   |-> buyerSide.value,
         buyerOrderId                |-> buyerOrderId.value,
         buyerCombinationTradeId     |-> buyerCombinationTradeId.value,
         buyerParticipantId          |-> buyerParticipantId.value,
         sellerTradeableInstrumentId |-> sellerTradeableInstrumentId.value,
         sellerSide                  |-> sellerSide.value,
         sellerOrderId               |-> sellerOrderId.value,
         sellerCombinationTradeId    |-> sellerCombinationTradeId.value,
         sellerParticipantId         |-> sellerParticipantId.value ], sellerParticipantId.rest)

ZeroCombinationTradeExecutedMessage ==
    [ nanoseconds                 |-> [i \in 1 .. 4 |-> 0],
      tradeDate                   |-> [i \in 1 .. 2 |-> 0],
      tradeableInstrumentId       |-> [i \in 1 .. 4 |-> 0],
      tradeType                   |-> [i \in 1 .. 1 |-> 0],
      tradeId                     |-> [i \in 1 .. 8 |-> 0],
      executedQuantity            |-> [i \in 1 .. 4 |-> 0],
      tradePrice                  |-> [i \in 1 .. 8 |-> 0],
      buyerTradeableInstrumentId  |-> [i \in 1 .. 4 |-> 0],
      buyerSide                   |-> [i \in 1 .. 1 |-> 0],
      buyerOrderId                |-> [i \in 1 .. 8 |-> 0],
      buyerCombinationTradeId     |-> [i \in 1 .. 8 |-> 0],
      buyerParticipantId          |-> [i \in 1 .. 3 |-> 0],
      sellerTradeableInstrumentId |-> [i \in 1 .. 4 |-> 0],
      sellerSide                  |-> [i \in 1 .. 1 |-> 0],
      sellerOrderId               |-> [i \in 1 .. 8 |-> 0],
      sellerCombinationTradeId    |-> [i \in 1 .. 8 |-> 0],
      sellerParticipantId         |-> [i \in 1 .. 3 |-> 0] ]

(* Combination Trade Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedCombinationTradeExecutedMessage ==
    { ZeroCombinationTradeExecutedMessage }
        \cup { [ZeroCombinationTradeExecutedMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroCombinationTradeExecutedMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroCombinationTradeExecutedMessage EXCEPT !.tradeableInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroCombinationTradeExecutedMessage EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroCombinationTradeExecutedMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroCombinationTradeExecutedMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroCombinationTradeExecutedMessage EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroCombinationTradeExecutedMessage EXCEPT !.buyerTradeableInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroCombinationTradeExecutedMessage EXCEPT !.buyerSide = one] : one \in Sample(1) }
        \cup { [ZeroCombinationTradeExecutedMessage EXCEPT !.buyerOrderId = one] : one \in Sample(8) }
        \cup { [ZeroCombinationTradeExecutedMessage EXCEPT !.buyerCombinationTradeId = one] : one \in Sample(8) }
        \cup { [ZeroCombinationTradeExecutedMessage EXCEPT !.buyerParticipantId = one] : one \in Sample(3) }
        \cup { [ZeroCombinationTradeExecutedMessage EXCEPT !.sellerTradeableInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroCombinationTradeExecutedMessage EXCEPT !.sellerSide = one] : one \in Sample(1) }
        \cup { [ZeroCombinationTradeExecutedMessage EXCEPT !.sellerOrderId = one] : one \in Sample(8) }
        \cup { [ZeroCombinationTradeExecutedMessage EXCEPT !.sellerCombinationTradeId = one] : one \in Sample(8) }
        \cup { [ZeroCombinationTradeExecutedMessage EXCEPT !.sellerParticipantId = one] : one \in Sample(3) }

(***************************************************************************)
(* Trade Cancellation Message: 18 bytes                                    *)
(***************************************************************************)

TradeCancellationMessage ==
    [ nanoseconds           : Sample(4),
      tradeDate             : Sample(2),
      tradeableInstrumentId : Sample(4),
      tradeId               : Sample(8) ]

EncodeTradeCancellationMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.tradeableInstrumentId
        \o message.tradeId

DecodeTradeCancellationMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET tradeableInstrumentId == ReadBytes(tradeDate.rest, 4) IN IF ~tradeableInstrumentId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(tradeableInstrumentId.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    Ok([ nanoseconds           |-> nanoseconds.value,
         tradeDate             |-> tradeDate.value,
         tradeableInstrumentId |-> tradeableInstrumentId.value,
         tradeId               |-> tradeId.value ], tradeId.rest)

ZeroTradeCancellationMessage ==
    [ nanoseconds           |-> [i \in 1 .. 4 |-> 0],
      tradeDate             |-> [i \in 1 .. 2 |-> 0],
      tradeableInstrumentId |-> [i \in 1 .. 4 |-> 0],
      tradeId               |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Cancellation Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCancellationMessage ==
    { ZeroTradeCancellationMessage }
        \cup { [ZeroTradeCancellationMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancellationMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroTradeCancellationMessage EXCEPT !.tradeableInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancellationMessage EXCEPT !.tradeId = one] : one \in Sample(8) }

(***************************************************************************)
(* Equilibrium Price Message: 42 bytes                                     *)
(***************************************************************************)

EquilibriumPriceMessage ==
    [ nanoseconds           : Sample(4),
      tradeDate             : Sample(2),
      tradeableInstrumentId : Sample(4),
      equilibriumPrice      : Sample(8),
      matchedQuantity       : Sample(8),
      bidQuantity           : Sample(8),
      askQuantity           : Sample(8) ]

EncodeEquilibriumPriceMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.tradeableInstrumentId
        \o message.equilibriumPrice
        \o message.matchedQuantity
        \o message.bidQuantity
        \o message.askQuantity

DecodeEquilibriumPriceMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET tradeableInstrumentId == ReadBytes(tradeDate.rest, 4) IN IF ~tradeableInstrumentId.ok THEN Fail ELSE
    LET equilibriumPrice == ReadBytes(tradeableInstrumentId.rest, 8) IN IF ~equilibriumPrice.ok THEN Fail ELSE
    LET matchedQuantity == ReadBytes(equilibriumPrice.rest, 8) IN IF ~matchedQuantity.ok THEN Fail ELSE
    LET bidQuantity == ReadBytes(matchedQuantity.rest, 8) IN IF ~bidQuantity.ok THEN Fail ELSE
    LET askQuantity == ReadBytes(bidQuantity.rest, 8) IN IF ~askQuantity.ok THEN Fail ELSE
    Ok([ nanoseconds           |-> nanoseconds.value,
         tradeDate             |-> tradeDate.value,
         tradeableInstrumentId |-> tradeableInstrumentId.value,
         equilibriumPrice      |-> equilibriumPrice.value,
         matchedQuantity       |-> matchedQuantity.value,
         bidQuantity           |-> bidQuantity.value,
         askQuantity           |-> askQuantity.value ], askQuantity.rest)

ZeroEquilibriumPriceMessage ==
    [ nanoseconds           |-> [i \in 1 .. 4 |-> 0],
      tradeDate             |-> [i \in 1 .. 2 |-> 0],
      tradeableInstrumentId |-> [i \in 1 .. 4 |-> 0],
      equilibriumPrice      |-> [i \in 1 .. 8 |-> 0],
      matchedQuantity       |-> [i \in 1 .. 8 |-> 0],
      bidQuantity           |-> [i \in 1 .. 8 |-> 0],
      askQuantity           |-> [i \in 1 .. 8 |-> 0] ]

(* Equilibrium Price Message at zero, then each field in turn at the values it is checked at *)
CheckedEquilibriumPriceMessage ==
    { ZeroEquilibriumPriceMessage }
        \cup { [ZeroEquilibriumPriceMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroEquilibriumPriceMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroEquilibriumPriceMessage EXCEPT !.tradeableInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroEquilibriumPriceMessage EXCEPT !.equilibriumPrice = one] : one \in Sample(8) }
        \cup { [ZeroEquilibriumPriceMessage EXCEPT !.matchedQuantity = one] : one \in Sample(8) }
        \cup { [ZeroEquilibriumPriceMessage EXCEPT !.bidQuantity = one] : one \in Sample(8) }
        \cup { [ZeroEquilibriumPriceMessage EXCEPT !.askQuantity = one] : one \in Sample(8) }

(***************************************************************************)
(* Open High Low Last Trade Adjustment Message: 54 bytes                   *)
(***************************************************************************)

OpenHighLowLastTradeAdjustmentMessage ==
    [ nanoseconds           : Sample(4),
      tradeDate             : Sample(2),
      tradeableInstrumentId : Sample(4),
      openingTrade          : Sample(8),
      highestTrade          : Sample(8),
      lowestTrade           : Sample(8),
      lastTrade             : Sample(8),
      lastVolume            : Sample(4),
      totalTradedVolume     : Sample(8) ]

EncodeOpenHighLowLastTradeAdjustmentMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.tradeableInstrumentId
        \o message.openingTrade
        \o message.highestTrade
        \o message.lowestTrade
        \o message.lastTrade
        \o message.lastVolume
        \o message.totalTradedVolume

DecodeOpenHighLowLastTradeAdjustmentMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET tradeableInstrumentId == ReadBytes(tradeDate.rest, 4) IN IF ~tradeableInstrumentId.ok THEN Fail ELSE
    LET openingTrade == ReadBytes(tradeableInstrumentId.rest, 8) IN IF ~openingTrade.ok THEN Fail ELSE
    LET highestTrade == ReadBytes(openingTrade.rest, 8) IN IF ~highestTrade.ok THEN Fail ELSE
    LET lowestTrade == ReadBytes(highestTrade.rest, 8) IN IF ~lowestTrade.ok THEN Fail ELSE
    LET lastTrade == ReadBytes(lowestTrade.rest, 8) IN IF ~lastTrade.ok THEN Fail ELSE
    LET lastVolume == ReadBytes(lastTrade.rest, 4) IN IF ~lastVolume.ok THEN Fail ELSE
    LET totalTradedVolume == ReadBytes(lastVolume.rest, 8) IN IF ~totalTradedVolume.ok THEN Fail ELSE
    Ok([ nanoseconds           |-> nanoseconds.value,
         tradeDate             |-> tradeDate.value,
         tradeableInstrumentId |-> tradeableInstrumentId.value,
         openingTrade          |-> openingTrade.value,
         highestTrade          |-> highestTrade.value,
         lowestTrade           |-> lowestTrade.value,
         lastTrade             |-> lastTrade.value,
         lastVolume            |-> lastVolume.value,
         totalTradedVolume     |-> totalTradedVolume.value ], totalTradedVolume.rest)

ZeroOpenHighLowLastTradeAdjustmentMessage ==
    [ nanoseconds           |-> [i \in 1 .. 4 |-> 0],
      tradeDate             |-> [i \in 1 .. 2 |-> 0],
      tradeableInstrumentId |-> [i \in 1 .. 4 |-> 0],
      openingTrade          |-> [i \in 1 .. 8 |-> 0],
      highestTrade          |-> [i \in 1 .. 8 |-> 0],
      lowestTrade           |-> [i \in 1 .. 8 |-> 0],
      lastTrade             |-> [i \in 1 .. 8 |-> 0],
      lastVolume            |-> [i \in 1 .. 4 |-> 0],
      totalTradedVolume     |-> [i \in 1 .. 8 |-> 0] ]

(* Open High Low Last Trade Adjustment Message at zero, then each field in turn at the values it is checked at *)
CheckedOpenHighLowLastTradeAdjustmentMessage ==
    { ZeroOpenHighLowLastTradeAdjustmentMessage }
        \cup { [ZeroOpenHighLowLastTradeAdjustmentMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOpenHighLowLastTradeAdjustmentMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroOpenHighLowLastTradeAdjustmentMessage EXCEPT !.tradeableInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroOpenHighLowLastTradeAdjustmentMessage EXCEPT !.openingTrade = one] : one \in Sample(8) }
        \cup { [ZeroOpenHighLowLastTradeAdjustmentMessage EXCEPT !.highestTrade = one] : one \in Sample(8) }
        \cup { [ZeroOpenHighLowLastTradeAdjustmentMessage EXCEPT !.lowestTrade = one] : one \in Sample(8) }
        \cup { [ZeroOpenHighLowLastTradeAdjustmentMessage EXCEPT !.lastTrade = one] : one \in Sample(8) }
        \cup { [ZeroOpenHighLowLastTradeAdjustmentMessage EXCEPT !.lastVolume = one] : one \in Sample(4) }
        \cup { [ZeroOpenHighLowLastTradeAdjustmentMessage EXCEPT !.totalTradedVolume = one] : one \in Sample(8) }

(***************************************************************************)
(* Market Settlement Message: 54 bytes                                     *)
(***************************************************************************)

MarketSettlementMessage ==
    [ nanoseconds           : Sample(4),
      tradeDate             : Sample(2),
      tradeableInstrumentId : Sample(4),
      openingTrade          : Sample(8),
      highestTrade          : Sample(8),
      lowestTrade           : Sample(8),
      lastTrade             : Sample(8),
      lastVolume            : Sample(4),
      totalTradedVolume     : Sample(8) ]

EncodeMarketSettlementMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.tradeableInstrumentId
        \o message.openingTrade
        \o message.highestTrade
        \o message.lowestTrade
        \o message.lastTrade
        \o message.lastVolume
        \o message.totalTradedVolume

DecodeMarketSettlementMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET tradeableInstrumentId == ReadBytes(tradeDate.rest, 4) IN IF ~tradeableInstrumentId.ok THEN Fail ELSE
    LET openingTrade == ReadBytes(tradeableInstrumentId.rest, 8) IN IF ~openingTrade.ok THEN Fail ELSE
    LET highestTrade == ReadBytes(openingTrade.rest, 8) IN IF ~highestTrade.ok THEN Fail ELSE
    LET lowestTrade == ReadBytes(highestTrade.rest, 8) IN IF ~lowestTrade.ok THEN Fail ELSE
    LET lastTrade == ReadBytes(lowestTrade.rest, 8) IN IF ~lastTrade.ok THEN Fail ELSE
    LET lastVolume == ReadBytes(lastTrade.rest, 4) IN IF ~lastVolume.ok THEN Fail ELSE
    LET totalTradedVolume == ReadBytes(lastVolume.rest, 8) IN IF ~totalTradedVolume.ok THEN Fail ELSE
    Ok([ nanoseconds           |-> nanoseconds.value,
         tradeDate             |-> tradeDate.value,
         tradeableInstrumentId |-> tradeableInstrumentId.value,
         openingTrade          |-> openingTrade.value,
         highestTrade          |-> highestTrade.value,
         lowestTrade           |-> lowestTrade.value,
         lastTrade             |-> lastTrade.value,
         lastVolume            |-> lastVolume.value,
         totalTradedVolume     |-> totalTradedVolume.value ], totalTradedVolume.rest)

ZeroMarketSettlementMessage ==
    [ nanoseconds           |-> [i \in 1 .. 4 |-> 0],
      tradeDate             |-> [i \in 1 .. 2 |-> 0],
      tradeableInstrumentId |-> [i \in 1 .. 4 |-> 0],
      openingTrade          |-> [i \in 1 .. 8 |-> 0],
      highestTrade          |-> [i \in 1 .. 8 |-> 0],
      lowestTrade           |-> [i \in 1 .. 8 |-> 0],
      lastTrade             |-> [i \in 1 .. 8 |-> 0],
      lastVolume            |-> [i \in 1 .. 4 |-> 0],
      totalTradedVolume     |-> [i \in 1 .. 8 |-> 0] ]

(* Market Settlement Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketSettlementMessage ==
    { ZeroMarketSettlementMessage }
        \cup { [ZeroMarketSettlementMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroMarketSettlementMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroMarketSettlementMessage EXCEPT !.tradeableInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroMarketSettlementMessage EXCEPT !.openingTrade = one] : one \in Sample(8) }
        \cup { [ZeroMarketSettlementMessage EXCEPT !.highestTrade = one] : one \in Sample(8) }
        \cup { [ZeroMarketSettlementMessage EXCEPT !.lowestTrade = one] : one \in Sample(8) }
        \cup { [ZeroMarketSettlementMessage EXCEPT !.lastTrade = one] : one \in Sample(8) }
        \cup { [ZeroMarketSettlementMessage EXCEPT !.lastVolume = one] : one \in Sample(4) }
        \cup { [ZeroMarketSettlementMessage EXCEPT !.totalTradedVolume = one] : one \in Sample(8) }

(***************************************************************************)
(* Text Message: 112 bytes                                                 *)
(***************************************************************************)

TextMessage ==
    [ nanoseconds : Sample(4),
      tradeDate   : Sample(2),
      sourceId    : Sample(6),
      text        : Sample(100) ]

EncodeTextMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.sourceId
        \o message.text

DecodeTextMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET sourceId == ReadBytes(tradeDate.rest, 6) IN IF ~sourceId.ok THEN Fail ELSE
    LET text == ReadBytes(sourceId.rest, 100) IN IF ~text.ok THEN Fail ELSE
    Ok([ nanoseconds |-> nanoseconds.value,
         tradeDate   |-> tradeDate.value,
         sourceId    |-> sourceId.value,
         text        |-> text.value ], text.rest)

ZeroTextMessage ==
    [ nanoseconds |-> [i \in 1 .. 4 |-> 0],
      tradeDate   |-> [i \in 1 .. 2 |-> 0],
      sourceId    |-> [i \in 1 .. 6 |-> 0],
      text        |-> [i \in 1 .. 100 |-> 0] ]

(* Text Message at zero, then each field in turn at the values it is checked at *)
CheckedTextMessage ==
    { ZeroTextMessage }
        \cup { [ZeroTextMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroTextMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroTextMessage EXCEPT !.sourceId = one] : one \in Sample(6) }
        \cup { [ZeroTextMessage EXCEPT !.text = one] : one \in Sample(100) }

(***************************************************************************)
(* Request For Quote Message: 15 bytes                                     *)
(***************************************************************************)

RequestForQuoteMessage ==
    [ nanoseconds           : Sample(4),
      tradeDate             : Sample(2),
      tradeableInstrumentId : Sample(4),
      rfqSide               : Sample(1),
      quantity              : Sample(4) ]

EncodeRequestForQuoteMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.tradeableInstrumentId
        \o message.rfqSide
        \o message.quantity

DecodeRequestForQuoteMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET tradeableInstrumentId == ReadBytes(tradeDate.rest, 4) IN IF ~tradeableInstrumentId.ok THEN Fail ELSE
    LET rfqSide == ReadBytes(tradeableInstrumentId.rest, 1) IN IF ~rfqSide.ok THEN Fail ELSE
    LET quantity == ReadBytes(rfqSide.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    Ok([ nanoseconds           |-> nanoseconds.value,
         tradeDate             |-> tradeDate.value,
         tradeableInstrumentId |-> tradeableInstrumentId.value,
         rfqSide               |-> rfqSide.value,
         quantity              |-> quantity.value ], quantity.rest)

ZeroRequestForQuoteMessage ==
    [ nanoseconds           |-> [i \in 1 .. 4 |-> 0],
      tradeDate             |-> [i \in 1 .. 2 |-> 0],
      tradeableInstrumentId |-> [i \in 1 .. 4 |-> 0],
      rfqSide               |-> [i \in 1 .. 1 |-> 0],
      quantity              |-> [i \in 1 .. 4 |-> 0] ]

(* Request For Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedRequestForQuoteMessage ==
    { ZeroRequestForQuoteMessage }
        \cup { [ZeroRequestForQuoteMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroRequestForQuoteMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroRequestForQuoteMessage EXCEPT !.tradeableInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroRequestForQuoteMessage EXCEPT !.rfqSide = one] : one \in Sample(1) }
        \cup { [ZeroRequestForQuoteMessage EXCEPT !.quantity = one] : one \in Sample(4) }

(***************************************************************************)
(* Anomalous Order Threshold Publish Message: 58 bytes                     *)
(***************************************************************************)

AnomalousOrderThresholdPublishMessage ==
    [ nanoseconds           : Sample(4),
      tradeDate             : Sample(2),
      tradeableInstrumentId : Sample(4),
      aotPrice              : Sample(8),
      aotUpperPrice         : Sample(8),
      aotLowerPrice         : Sample(8),
      etrPrice              : Sample(8),
      etrUpperPrice         : Sample(8),
      etrLowerPrice         : Sample(8) ]

EncodeAnomalousOrderThresholdPublishMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.tradeableInstrumentId
        \o message.aotPrice
        \o message.aotUpperPrice
        \o message.aotLowerPrice
        \o message.etrPrice
        \o message.etrUpperPrice
        \o message.etrLowerPrice

DecodeAnomalousOrderThresholdPublishMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET tradeableInstrumentId == ReadBytes(tradeDate.rest, 4) IN IF ~tradeableInstrumentId.ok THEN Fail ELSE
    LET aotPrice == ReadBytes(tradeableInstrumentId.rest, 8) IN IF ~aotPrice.ok THEN Fail ELSE
    LET aotUpperPrice == ReadBytes(aotPrice.rest, 8) IN IF ~aotUpperPrice.ok THEN Fail ELSE
    LET aotLowerPrice == ReadBytes(aotUpperPrice.rest, 8) IN IF ~aotLowerPrice.ok THEN Fail ELSE
    LET etrPrice == ReadBytes(aotLowerPrice.rest, 8) IN IF ~etrPrice.ok THEN Fail ELSE
    LET etrUpperPrice == ReadBytes(etrPrice.rest, 8) IN IF ~etrUpperPrice.ok THEN Fail ELSE
    LET etrLowerPrice == ReadBytes(etrUpperPrice.rest, 8) IN IF ~etrLowerPrice.ok THEN Fail ELSE
    Ok([ nanoseconds           |-> nanoseconds.value,
         tradeDate             |-> tradeDate.value,
         tradeableInstrumentId |-> tradeableInstrumentId.value,
         aotPrice              |-> aotPrice.value,
         aotUpperPrice         |-> aotUpperPrice.value,
         aotLowerPrice         |-> aotLowerPrice.value,
         etrPrice              |-> etrPrice.value,
         etrUpperPrice         |-> etrUpperPrice.value,
         etrLowerPrice         |-> etrLowerPrice.value ], etrLowerPrice.rest)

ZeroAnomalousOrderThresholdPublishMessage ==
    [ nanoseconds           |-> [i \in 1 .. 4 |-> 0],
      tradeDate             |-> [i \in 1 .. 2 |-> 0],
      tradeableInstrumentId |-> [i \in 1 .. 4 |-> 0],
      aotPrice              |-> [i \in 1 .. 8 |-> 0],
      aotUpperPrice         |-> [i \in 1 .. 8 |-> 0],
      aotLowerPrice         |-> [i \in 1 .. 8 |-> 0],
      etrPrice              |-> [i \in 1 .. 8 |-> 0],
      etrUpperPrice         |-> [i \in 1 .. 8 |-> 0],
      etrLowerPrice         |-> [i \in 1 .. 8 |-> 0] ]

(* Anomalous Order Threshold Publish Message at zero, then each field in turn at the values it is checked at *)
CheckedAnomalousOrderThresholdPublishMessage ==
    { ZeroAnomalousOrderThresholdPublishMessage }
        \cup { [ZeroAnomalousOrderThresholdPublishMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroAnomalousOrderThresholdPublishMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroAnomalousOrderThresholdPublishMessage EXCEPT !.tradeableInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroAnomalousOrderThresholdPublishMessage EXCEPT !.aotPrice = one] : one \in Sample(8) }
        \cup { [ZeroAnomalousOrderThresholdPublishMessage EXCEPT !.aotUpperPrice = one] : one \in Sample(8) }
        \cup { [ZeroAnomalousOrderThresholdPublishMessage EXCEPT !.aotLowerPrice = one] : one \in Sample(8) }
        \cup { [ZeroAnomalousOrderThresholdPublishMessage EXCEPT !.etrPrice = one] : one \in Sample(8) }
        \cup { [ZeroAnomalousOrderThresholdPublishMessage EXCEPT !.etrUpperPrice = one] : one \in Sample(8) }
        \cup { [ZeroAnomalousOrderThresholdPublishMessage EXCEPT !.etrLowerPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Volume And Open Interest Message: 28 bytes                              *)
(***************************************************************************)

VolumeAndOpenInterestMessage ==
    [ nanoseconds           : Sample(4),
      tradeDate             : Sample(2),
      tradeableInstrumentId : Sample(4),
      cumulativeVolume      : Sample(8),
      openInterest          : Sample(8),
      voiTradeDate          : Sample(2) ]

EncodeVolumeAndOpenInterestMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.tradeableInstrumentId
        \o message.cumulativeVolume
        \o message.openInterest
        \o message.voiTradeDate

DecodeVolumeAndOpenInterestMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET tradeableInstrumentId == ReadBytes(tradeDate.rest, 4) IN IF ~tradeableInstrumentId.ok THEN Fail ELSE
    LET cumulativeVolume == ReadBytes(tradeableInstrumentId.rest, 8) IN IF ~cumulativeVolume.ok THEN Fail ELSE
    LET openInterest == ReadBytes(cumulativeVolume.rest, 8) IN IF ~openInterest.ok THEN Fail ELSE
    LET voiTradeDate == ReadBytes(openInterest.rest, 2) IN IF ~voiTradeDate.ok THEN Fail ELSE
    Ok([ nanoseconds           |-> nanoseconds.value,
         tradeDate             |-> tradeDate.value,
         tradeableInstrumentId |-> tradeableInstrumentId.value,
         cumulativeVolume      |-> cumulativeVolume.value,
         openInterest          |-> openInterest.value,
         voiTradeDate          |-> voiTradeDate.value ], voiTradeDate.rest)

ZeroVolumeAndOpenInterestMessage ==
    [ nanoseconds           |-> [i \in 1 .. 4 |-> 0],
      tradeDate             |-> [i \in 1 .. 2 |-> 0],
      tradeableInstrumentId |-> [i \in 1 .. 4 |-> 0],
      cumulativeVolume      |-> [i \in 1 .. 8 |-> 0],
      openInterest          |-> [i \in 1 .. 8 |-> 0],
      voiTradeDate          |-> [i \in 1 .. 2 |-> 0] ]

(* Volume And Open Interest Message at zero, then each field in turn at the values it is checked at *)
CheckedVolumeAndOpenInterestMessage ==
    { ZeroVolumeAndOpenInterestMessage }
        \cup { [ZeroVolumeAndOpenInterestMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroVolumeAndOpenInterestMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroVolumeAndOpenInterestMessage EXCEPT !.tradeableInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroVolumeAndOpenInterestMessage EXCEPT !.cumulativeVolume = one] : one \in Sample(8) }
        \cup { [ZeroVolumeAndOpenInterestMessage EXCEPT !.openInterest = one] : one \in Sample(8) }
        \cup { [ZeroVolumeAndOpenInterestMessage EXCEPT !.voiTradeDate = one] : one \in Sample(2) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

SecondsMessageCode == 84  \* "T"
EndOfBusinessTradeDateMessageCode == 83  \* "S"
FutureSymbolDirectoryMessageCode == 102  \* "f"
OptionsSymbolDirectoryMessageCode == 104  \* "h"
CombinationSymbolDirectoryMessageCode == 77  \* "M"
BundlesSymbolDirectoryCode == 109  \* "m"
OrderBookStateMessageCode == 79  \* "O"
AddOrderMessageCode == 65  \* "A"
OrderVolumeCancelledMessageCode == 88  \* "X"
OrderDeletedMessageCode == 68  \* "D"
OrderExecutedMessageCode == 69  \* "E"
AuctionOrderExecutedMessageCode == 67  \* "C"
CombinationOrderExecutedMessageCode == 101  \* "e"
ImpliedOrderAddedMessageCode == 106  \* "j"
ImpliedOrderReplacedMessageCode == 108  \* "l"
ImpliedOrderDeletedMessageCode == 107  \* "k"
TradeExecutedMessageCode == 80  \* "P"
CombinationTradeExecutedMessageCode == 112  \* "p"
TradeCancellationMessageCode == 66  \* "B"
EquilibriumPriceMessageCode == 90  \* "Z"
OpenHighLowLastTradeAdjustmentMessageCode == 116  \* "t"
MarketSettlementMessageCode == 89  \* "Y"
TextMessageCode == 120  \* "x"
RequestForQuoteMessageCode == 113  \* "q"
AnomalousOrderThresholdPublishMessageCode == 87  \* "W"
VolumeAndOpenInterestMessageCode == 86  \* "V"

Payload ==
    [ tag : {SecondsMessageCode}, body : SecondsMessage ]
        \cup [ tag : {EndOfBusinessTradeDateMessageCode}, body : EndOfBusinessTradeDateMessage ]
        \cup [ tag : {FutureSymbolDirectoryMessageCode}, body : FutureSymbolDirectoryMessage ]
        \cup [ tag : {OptionsSymbolDirectoryMessageCode}, body : OptionsSymbolDirectoryMessage ]
        \cup [ tag : {CombinationSymbolDirectoryMessageCode}, body : CombinationSymbolDirectoryMessage ]
        \cup [ tag : {BundlesSymbolDirectoryCode}, body : BundlesSymbolDirectory ]
        \cup [ tag : {OrderBookStateMessageCode}, body : OrderBookStateMessage ]
        \cup [ tag : {AddOrderMessageCode}, body : AddOrderMessage ]
        \cup [ tag : {OrderVolumeCancelledMessageCode}, body : OrderVolumeCancelledMessage ]
        \cup [ tag : {OrderDeletedMessageCode}, body : OrderDeletedMessage ]
        \cup [ tag : {OrderExecutedMessageCode}, body : OrderExecutedMessage ]
        \cup [ tag : {AuctionOrderExecutedMessageCode}, body : AuctionOrderExecutedMessage ]
        \cup [ tag : {CombinationOrderExecutedMessageCode}, body : CombinationOrderExecutedMessage ]
        \cup [ tag : {ImpliedOrderAddedMessageCode}, body : ImpliedOrderAddedMessage ]
        \cup [ tag : {ImpliedOrderReplacedMessageCode}, body : ImpliedOrderReplacedMessage ]
        \cup [ tag : {ImpliedOrderDeletedMessageCode}, body : ImpliedOrderDeletedMessage ]
        \cup [ tag : {TradeExecutedMessageCode}, body : TradeExecutedMessage ]
        \cup [ tag : {CombinationTradeExecutedMessageCode}, body : CombinationTradeExecutedMessage ]
        \cup [ tag : {TradeCancellationMessageCode}, body : TradeCancellationMessage ]
        \cup [ tag : {EquilibriumPriceMessageCode}, body : EquilibriumPriceMessage ]
        \cup [ tag : {OpenHighLowLastTradeAdjustmentMessageCode}, body : OpenHighLowLastTradeAdjustmentMessage ]
        \cup [ tag : {MarketSettlementMessageCode}, body : MarketSettlementMessage ]
        \cup [ tag : {TextMessageCode}, body : TextMessage ]
        \cup [ tag : {RequestForQuoteMessageCode}, body : RequestForQuoteMessage ]
        \cup [ tag : {AnomalousOrderThresholdPublishMessageCode}, body : AnomalousOrderThresholdPublishMessage ]
        \cup [ tag : {VolumeAndOpenInterestMessageCode}, body : VolumeAndOpenInterestMessage ]

EncodePayload(message) ==
    CASE message.tag = SecondsMessageCode -> EncodeSecondsMessage(message.body)
      [] message.tag = EndOfBusinessTradeDateMessageCode -> EncodeEndOfBusinessTradeDateMessage(message.body)
      [] message.tag = FutureSymbolDirectoryMessageCode -> EncodeFutureSymbolDirectoryMessage(message.body)
      [] message.tag = OptionsSymbolDirectoryMessageCode -> EncodeOptionsSymbolDirectoryMessage(message.body)
      [] message.tag = CombinationSymbolDirectoryMessageCode -> EncodeCombinationSymbolDirectoryMessage(message.body)
      [] message.tag = BundlesSymbolDirectoryCode -> EncodeBundlesSymbolDirectory(message.body)
      [] message.tag = OrderBookStateMessageCode -> EncodeOrderBookStateMessage(message.body)
      [] message.tag = AddOrderMessageCode -> EncodeAddOrderMessage(message.body)
      [] message.tag = OrderVolumeCancelledMessageCode -> EncodeOrderVolumeCancelledMessage(message.body)
      [] message.tag = OrderDeletedMessageCode -> EncodeOrderDeletedMessage(message.body)
      [] message.tag = OrderExecutedMessageCode -> EncodeOrderExecutedMessage(message.body)
      [] message.tag = AuctionOrderExecutedMessageCode -> EncodeAuctionOrderExecutedMessage(message.body)
      [] message.tag = CombinationOrderExecutedMessageCode -> EncodeCombinationOrderExecutedMessage(message.body)
      [] message.tag = ImpliedOrderAddedMessageCode -> EncodeImpliedOrderAddedMessage(message.body)
      [] message.tag = ImpliedOrderReplacedMessageCode -> EncodeImpliedOrderReplacedMessage(message.body)
      [] message.tag = ImpliedOrderDeletedMessageCode -> EncodeImpliedOrderDeletedMessage(message.body)
      [] message.tag = TradeExecutedMessageCode -> EncodeTradeExecutedMessage(message.body)
      [] message.tag = CombinationTradeExecutedMessageCode -> EncodeCombinationTradeExecutedMessage(message.body)
      [] message.tag = TradeCancellationMessageCode -> EncodeTradeCancellationMessage(message.body)
      [] message.tag = EquilibriumPriceMessageCode -> EncodeEquilibriumPriceMessage(message.body)
      [] message.tag = OpenHighLowLastTradeAdjustmentMessageCode -> EncodeOpenHighLowLastTradeAdjustmentMessage(message.body)
      [] message.tag = MarketSettlementMessageCode -> EncodeMarketSettlementMessage(message.body)
      [] message.tag = TextMessageCode -> EncodeTextMessage(message.body)
      [] message.tag = RequestForQuoteMessageCode -> EncodeRequestForQuoteMessage(message.body)
      [] message.tag = AnomalousOrderThresholdPublishMessageCode -> EncodeAnomalousOrderThresholdPublishMessage(message.body)
      [] message.tag = VolumeAndOpenInterestMessageCode -> EncodeVolumeAndOpenInterestMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = SecondsMessageCode -> DecodeSecondsMessage(bytes)
              [] tag = EndOfBusinessTradeDateMessageCode -> DecodeEndOfBusinessTradeDateMessage(bytes)
              [] tag = FutureSymbolDirectoryMessageCode -> DecodeFutureSymbolDirectoryMessage(bytes)
              [] tag = OptionsSymbolDirectoryMessageCode -> DecodeOptionsSymbolDirectoryMessage(bytes)
              [] tag = CombinationSymbolDirectoryMessageCode -> DecodeCombinationSymbolDirectoryMessage(bytes)
              [] tag = BundlesSymbolDirectoryCode -> DecodeBundlesSymbolDirectory(bytes)
              [] tag = OrderBookStateMessageCode -> DecodeOrderBookStateMessage(bytes)
              [] tag = AddOrderMessageCode -> DecodeAddOrderMessage(bytes)
              [] tag = OrderVolumeCancelledMessageCode -> DecodeOrderVolumeCancelledMessage(bytes)
              [] tag = OrderDeletedMessageCode -> DecodeOrderDeletedMessage(bytes)
              [] tag = OrderExecutedMessageCode -> DecodeOrderExecutedMessage(bytes)
              [] tag = AuctionOrderExecutedMessageCode -> DecodeAuctionOrderExecutedMessage(bytes)
              [] tag = CombinationOrderExecutedMessageCode -> DecodeCombinationOrderExecutedMessage(bytes)
              [] tag = ImpliedOrderAddedMessageCode -> DecodeImpliedOrderAddedMessage(bytes)
              [] tag = ImpliedOrderReplacedMessageCode -> DecodeImpliedOrderReplacedMessage(bytes)
              [] tag = ImpliedOrderDeletedMessageCode -> DecodeImpliedOrderDeletedMessage(bytes)
              [] tag = TradeExecutedMessageCode -> DecodeTradeExecutedMessage(bytes)
              [] tag = CombinationTradeExecutedMessageCode -> DecodeCombinationTradeExecutedMessage(bytes)
              [] tag = TradeCancellationMessageCode -> DecodeTradeCancellationMessage(bytes)
              [] tag = EquilibriumPriceMessageCode -> DecodeEquilibriumPriceMessage(bytes)
              [] tag = OpenHighLowLastTradeAdjustmentMessageCode -> DecodeOpenHighLowLastTradeAdjustmentMessage(bytes)
              [] tag = MarketSettlementMessageCode -> DecodeMarketSettlementMessage(bytes)
              [] tag = TextMessageCode -> DecodeTextMessage(bytes)
              [] tag = RequestForQuoteMessageCode -> DecodeRequestForQuoteMessage(bytes)
              [] tag = AnomalousOrderThresholdPublishMessageCode -> DecodeAnomalousOrderThresholdPublishMessage(bytes)
              [] tag = VolumeAndOpenInterestMessageCode -> DecodeVolumeAndOpenInterestMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> SecondsMessageCode, body |-> ZeroSecondsMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> SecondsMessageCode, body |-> one] : one \in CheckedSecondsMessage }
        \cup { [tag |-> EndOfBusinessTradeDateMessageCode, body |-> one] : one \in CheckedEndOfBusinessTradeDateMessage }
        \cup { [tag |-> FutureSymbolDirectoryMessageCode, body |-> one] : one \in CheckedFutureSymbolDirectoryMessage }
        \cup { [tag |-> OptionsSymbolDirectoryMessageCode, body |-> one] : one \in CheckedOptionsSymbolDirectoryMessage }
        \cup { [tag |-> CombinationSymbolDirectoryMessageCode, body |-> one] : one \in CheckedCombinationSymbolDirectoryMessage }
        \cup { [tag |-> BundlesSymbolDirectoryCode, body |-> one] : one \in CheckedBundlesSymbolDirectory }
        \cup { [tag |-> OrderBookStateMessageCode, body |-> one] : one \in CheckedOrderBookStateMessage }
        \cup { [tag |-> AddOrderMessageCode, body |-> one] : one \in CheckedAddOrderMessage }
        \cup { [tag |-> OrderVolumeCancelledMessageCode, body |-> one] : one \in CheckedOrderVolumeCancelledMessage }
        \cup { [tag |-> OrderDeletedMessageCode, body |-> one] : one \in CheckedOrderDeletedMessage }
        \cup { [tag |-> OrderExecutedMessageCode, body |-> one] : one \in CheckedOrderExecutedMessage }
        \cup { [tag |-> AuctionOrderExecutedMessageCode, body |-> one] : one \in CheckedAuctionOrderExecutedMessage }
        \cup { [tag |-> CombinationOrderExecutedMessageCode, body |-> one] : one \in CheckedCombinationOrderExecutedMessage }
        \cup { [tag |-> ImpliedOrderAddedMessageCode, body |-> one] : one \in CheckedImpliedOrderAddedMessage }
        \cup { [tag |-> ImpliedOrderReplacedMessageCode, body |-> one] : one \in CheckedImpliedOrderReplacedMessage }
        \cup { [tag |-> ImpliedOrderDeletedMessageCode, body |-> one] : one \in CheckedImpliedOrderDeletedMessage }
        \cup { [tag |-> TradeExecutedMessageCode, body |-> one] : one \in CheckedTradeExecutedMessage }
        \cup { [tag |-> CombinationTradeExecutedMessageCode, body |-> one] : one \in CheckedCombinationTradeExecutedMessage }
        \cup { [tag |-> TradeCancellationMessageCode, body |-> one] : one \in CheckedTradeCancellationMessage }
        \cup { [tag |-> EquilibriumPriceMessageCode, body |-> one] : one \in CheckedEquilibriumPriceMessage }
        \cup { [tag |-> OpenHighLowLastTradeAdjustmentMessageCode, body |-> one] : one \in CheckedOpenHighLowLastTradeAdjustmentMessage }
        \cup { [tag |-> MarketSettlementMessageCode, body |-> one] : one \in CheckedMarketSettlementMessage }
        \cup { [tag |-> TextMessageCode, body |-> one] : one \in CheckedTextMessage }
        \cup { [tag |-> RequestForQuoteMessageCode, body |-> one] : one \in CheckedRequestForQuoteMessage }
        \cup { [tag |-> AnomalousOrderThresholdPublishMessageCode, body |-> one] : one \in CheckedAnomalousOrderThresholdPublishMessage }
        \cup { [tag |-> VolumeAndOpenInterestMessageCode, body |-> one] : one \in CheckedVolumeAndOpenInterestMessage }

(***************************************************************************)
(* Message, framed by Message Length                                       *)
(***************************************************************************)

Message ==
    [ payload : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntBE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroMessage ==
    [ payload |-> ZeroPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.payload = one] : one \in CheckedPayload }

(* A run of Message, written one after another *)
RECURSIVE EncodeMessageList(_)
EncodeMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMessage(Head(messages)) \o EncodeMessageList(Tail(messages))

(* As many Message as the field that counts them says *)
RECURSIVE ReadMessageList(_, _)
ReadMessageList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMessageList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Message of each kind, for the lists that carry them *)
OneMessage ==
    { [ZeroMessage EXCEPT !.payload = [tag |-> SecondsMessageCode, body |-> ZeroSecondsMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EndOfBusinessTradeDateMessageCode, body |-> ZeroEndOfBusinessTradeDateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> FutureSymbolDirectoryMessageCode, body |-> ZeroFutureSymbolDirectoryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OptionsSymbolDirectoryMessageCode, body |-> ZeroOptionsSymbolDirectoryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CombinationSymbolDirectoryMessageCode, body |-> ZeroCombinationSymbolDirectoryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> BundlesSymbolDirectoryCode, body |-> ZeroBundlesSymbolDirectory]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderBookStateMessageCode, body |-> ZeroOrderBookStateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddOrderMessageCode, body |-> ZeroAddOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderVolumeCancelledMessageCode, body |-> ZeroOrderVolumeCancelledMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderDeletedMessageCode, body |-> ZeroOrderDeletedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderExecutedMessageCode, body |-> ZeroOrderExecutedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionOrderExecutedMessageCode, body |-> ZeroAuctionOrderExecutedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CombinationOrderExecutedMessageCode, body |-> ZeroCombinationOrderExecutedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ImpliedOrderAddedMessageCode, body |-> ZeroImpliedOrderAddedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ImpliedOrderReplacedMessageCode, body |-> ZeroImpliedOrderReplacedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ImpliedOrderDeletedMessageCode, body |-> ZeroImpliedOrderDeletedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeExecutedMessageCode, body |-> ZeroTradeExecutedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CombinationTradeExecutedMessageCode, body |-> ZeroCombinationTradeExecutedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeCancellationMessageCode, body |-> ZeroTradeCancellationMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EquilibriumPriceMessageCode, body |-> ZeroEquilibriumPriceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OpenHighLowLastTradeAdjustmentMessageCode, body |-> ZeroOpenHighLowLastTradeAdjustmentMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MarketSettlementMessageCode, body |-> ZeroMarketSettlementMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TextMessageCode, body |-> ZeroTextMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RequestForQuoteMessageCode, body |-> ZeroRequestForQuoteMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AnomalousOrderThresholdPublishMessageCode, body |-> ZeroAnomalousOrderThresholdPublishMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> VolumeAndOpenInterestMessageCode, body |-> ZeroVolumeAndOpenInterestMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ session        : Sample(10),
      sequenceNumber : Sample(8),
      message        : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.session
        \o message.sequenceNumber
        \o EncodeUIntBE(Len(message.message), 2)
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET session == ReadBytes(bytes, 10) IN IF ~session.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(session.rest, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET messageCount == ReadUIntBE(sequenceNumber.rest, 2) IN IF ~messageCount.ok THEN Fail ELSE
    LET message == ReadMessageList(messageCount.rest, messageCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ session        |-> session.value,
         sequenceNumber |-> sequenceNumber.value,
         message        |-> message.value ], message.rest)

ZeroPacket ==
    [ session        |-> [i \in 1 .. 10 |-> 0],
      sequenceNumber |-> [i \in 1 .. 8 |-> 0],
      message        |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.session = one] : one \in Sample(10) }
        \cup { [ZeroPacket EXCEPT !.sequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroPacket EXCEPT !.message = one] : one \in SampleLists(OneMessage) }

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

(* Every Seconds Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecondsMessage ==
    \A message \in CheckedSecondsMessage :
        LET read == DecodeSecondsMessage(EncodeSecondsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Business Trade Date Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfBusinessTradeDateMessage ==
    \A message \in CheckedEndOfBusinessTradeDateMessage :
        LET read == DecodeEndOfBusinessTradeDateMessage(EncodeEndOfBusinessTradeDateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Symbol Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureSymbolDirectoryMessage ==
    \A message \in CheckedFutureSymbolDirectoryMessage :
        LET read == DecodeFutureSymbolDirectoryMessage(EncodeFutureSymbolDirectoryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Options Symbol Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionsSymbolDirectoryMessage ==
    \A message \in CheckedOptionsSymbolDirectoryMessage :
        LET read == DecodeOptionsSymbolDirectoryMessage(EncodeOptionsSymbolDirectoryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Combination Leg decodes back to what was encoded, and leaves nothing over *)
RoundTripCombinationLeg ==
    \A message \in CheckedCombinationLeg :
        LET read == DecodeCombinationLeg(EncodeCombinationLeg(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Combination Symbol Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCombinationSymbolDirectoryMessage ==
    \A message \in CheckedCombinationSymbolDirectoryMessage :
        LET read == DecodeCombinationSymbolDirectoryMessage(EncodeCombinationSymbolDirectoryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bundle Leg decodes back to what was encoded, and leaves nothing over *)
RoundTripBundleLeg ==
    \A message \in CheckedBundleLeg :
        LET read == DecodeBundleLeg(EncodeBundleLeg(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bundles Symbol Directory decodes back to what was encoded, and leaves nothing over *)
RoundTripBundlesSymbolDirectory ==
    \A message \in CheckedBundlesSymbolDirectory :
        LET read == DecodeBundlesSymbolDirectory(EncodeBundlesSymbolDirectory(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Book State Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderBookStateMessage ==
    \A message \in CheckedOrderBookStateMessage :
        LET read == DecodeOrderBookStateMessage(EncodeOrderBookStateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderMessage ==
    \A message \in CheckedAddOrderMessage :
        LET read == DecodeAddOrderMessage(EncodeAddOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Volume Cancelled Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderVolumeCancelledMessage ==
    \A message \in CheckedOrderVolumeCancelledMessage :
        LET read == DecodeOrderVolumeCancelledMessage(EncodeOrderVolumeCancelledMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Deleted Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderDeletedMessage ==
    \A message \in CheckedOrderDeletedMessage :
        LET read == DecodeOrderDeletedMessage(EncodeOrderDeletedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Executed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutedMessage ==
    \A message \in CheckedOrderExecutedMessage :
        LET read == DecodeOrderExecutedMessage(EncodeOrderExecutedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Order Executed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionOrderExecutedMessage ==
    \A message \in CheckedAuctionOrderExecutedMessage :
        LET read == DecodeAuctionOrderExecutedMessage(EncodeAuctionOrderExecutedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Combination Order Executed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCombinationOrderExecutedMessage ==
    \A message \in CheckedCombinationOrderExecutedMessage :
        LET read == DecodeCombinationOrderExecutedMessage(EncodeCombinationOrderExecutedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Implied Order Added Message decodes back to what was encoded, and leaves nothing over *)
RoundTripImpliedOrderAddedMessage ==
    \A message \in CheckedImpliedOrderAddedMessage :
        LET read == DecodeImpliedOrderAddedMessage(EncodeImpliedOrderAddedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Implied Order Replaced Message decodes back to what was encoded, and leaves nothing over *)
RoundTripImpliedOrderReplacedMessage ==
    \A message \in CheckedImpliedOrderReplacedMessage :
        LET read == DecodeImpliedOrderReplacedMessage(EncodeImpliedOrderReplacedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Implied Order Deleted Message decodes back to what was encoded, and leaves nothing over *)
RoundTripImpliedOrderDeletedMessage ==
    \A message \in CheckedImpliedOrderDeletedMessage :
        LET read == DecodeImpliedOrderDeletedMessage(EncodeImpliedOrderDeletedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Executed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeExecutedMessage ==
    \A message \in CheckedTradeExecutedMessage :
        LET read == DecodeTradeExecutedMessage(EncodeTradeExecutedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Combination Trade Executed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCombinationTradeExecutedMessage ==
    \A message \in CheckedCombinationTradeExecutedMessage :
        LET read == DecodeCombinationTradeExecutedMessage(EncodeCombinationTradeExecutedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Cancellation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCancellationMessage ==
    \A message \in CheckedTradeCancellationMessage :
        LET read == DecodeTradeCancellationMessage(EncodeTradeCancellationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Equilibrium Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEquilibriumPriceMessage ==
    \A message \in CheckedEquilibriumPriceMessage :
        LET read == DecodeEquilibriumPriceMessage(EncodeEquilibriumPriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Open High Low Last Trade Adjustment Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOpenHighLowLastTradeAdjustmentMessage ==
    \A message \in CheckedOpenHighLowLastTradeAdjustmentMessage :
        LET read == DecodeOpenHighLowLastTradeAdjustmentMessage(EncodeOpenHighLowLastTradeAdjustmentMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Settlement Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketSettlementMessage ==
    \A message \in CheckedMarketSettlementMessage :
        LET read == DecodeMarketSettlementMessage(EncodeMarketSettlementMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Text Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTextMessage ==
    \A message \in CheckedTextMessage :
        LET read == DecodeTextMessage(EncodeTextMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request For Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestForQuoteMessage ==
    \A message \in CheckedRequestForQuoteMessage :
        LET read == DecodeRequestForQuoteMessage(EncodeRequestForQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Anomalous Order Threshold Publish Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAnomalousOrderThresholdPublishMessage ==
    \A message \in CheckedAnomalousOrderThresholdPublishMessage :
        LET read == DecodeAnomalousOrderThresholdPublishMessage(EncodeAnomalousOrderThresholdPublishMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Volume And Open Interest Message decodes back to what was encoded, and leaves nothing over *)
RoundTripVolumeAndOpenInterestMessage ==
    \A message \in CheckedVolumeAndOpenInterestMessage :
        LET read == DecodeVolumeAndOpenInterestMessage(EncodeVolumeAndOpenInterestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMessage ==
    \A message \in CheckedMessage :
        LET read == DecodeMessage(EncodeMessage(message))
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

(* A Payload is selected by the Message Type it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Message Length is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
