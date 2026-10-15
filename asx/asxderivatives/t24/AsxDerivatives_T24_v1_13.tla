--------------------- MODULE AsxDerivatives_T24_v1_13 ----------------------
(***************************************************************************)
(* Australian Securities Exchange 24 Itch v1.13                            *)
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
(* Note: Contract Legs is written as 6 slots, however many of them the     *)
(* count beside it says are in use.                                        *)
(*                                                                         *)
(* Note: Market Updates is a bit field set, checked as its 1 byte rather   *)
(* than bit by bit.                                                        *)
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
(* Session: 10 bytes                                                       *)
(***************************************************************************)

Session ==
    [ protocolVersion : Sample(3),
      sessionYear     : Sample(2),
      sessionWeek     : Sample(2),
      tradingService  : Sample(3) ]

EncodeSession(message) ==
    message.protocolVersion
        \o message.sessionYear
        \o message.sessionWeek
        \o message.tradingService

DecodeSession(bytes) ==
    LET protocolVersion == ReadBytes(bytes, 3) IN IF ~protocolVersion.ok THEN Fail ELSE
    LET sessionYear == ReadBytes(protocolVersion.rest, 2) IN IF ~sessionYear.ok THEN Fail ELSE
    LET sessionWeek == ReadBytes(sessionYear.rest, 2) IN IF ~sessionWeek.ok THEN Fail ELSE
    LET tradingService == ReadBytes(sessionWeek.rest, 3) IN IF ~tradingService.ok THEN Fail ELSE
    Ok([ protocolVersion |-> protocolVersion.value,
         sessionYear     |-> sessionYear.value,
         sessionWeek     |-> sessionWeek.value,
         tradingService  |-> tradingService.value ], tradingService.rest)

ZeroSession ==
    [ protocolVersion |-> [i \in 1 .. 3 |-> 0],
      sessionYear     |-> [i \in 1 .. 2 |-> 0],
      sessionWeek     |-> [i \in 1 .. 2 |-> 0],
      tradingService  |-> [i \in 1 .. 3 |-> 0] ]

(* Session at zero, then each field in turn at the values it is checked at *)
CheckedSession ==
    { ZeroSession }
        \cup { [ZeroSession EXCEPT !.protocolVersion = one] : one \in Sample(3) }
        \cup { [ZeroSession EXCEPT !.sessionYear = one] : one \in Sample(2) }
        \cup { [ZeroSession EXCEPT !.sessionWeek = one] : one \in Sample(2) }
        \cup { [ZeroSession EXCEPT !.tradingService = one] : one \in Sample(3) }

(***************************************************************************)
(* Time Message: 4 bytes                                                   *)
(***************************************************************************)

TimeMessage ==
    [ second : Sample(4) ]

EncodeTimeMessage(message) ==
    message.second

DecodeTimeMessage(bytes) ==
    LET second == ReadBytes(bytes, 4) IN IF ~second.ok THEN Fail ELSE
    Ok([ second |-> second.value ], second.rest)

ZeroTimeMessage ==
    [ second |-> [i \in 1 .. 4 |-> 0] ]

(* Time Message at zero, then each field in turn at the values it is checked at *)
CheckedTimeMessage ==
    { ZeroTimeMessage }
        \cup { [ZeroTimeMessage EXCEPT !.second = one] : one \in Sample(4) }

(***************************************************************************)
(* System Event Message: 7 bytes                                           *)
(***************************************************************************)

SystemEventMessage ==
    [ nanoseconds : Sample(4),
      tradeDate   : Sample(2),
      eventCode   : Sample(1) ]

EncodeSystemEventMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.eventCode

DecodeSystemEventMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET eventCode == ReadBytes(tradeDate.rest, 1) IN IF ~eventCode.ok THEN Fail ELSE
    Ok([ nanoseconds |-> nanoseconds.value,
         tradeDate   |-> tradeDate.value,
         eventCode   |-> eventCode.value ], eventCode.rest)

ZeroSystemEventMessage ==
    [ nanoseconds |-> [i \in 1 .. 4 |-> 0],
      tradeDate   |-> [i \in 1 .. 2 |-> 0],
      eventCode   |-> [i \in 1 .. 1 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSystemEventMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Future Symbol Directory Message: 53 bytes                               *)
(***************************************************************************)

FutureSymbolDirectoryMessage ==
    [ nanoseconds                : Sample(4),
      tradeDate                  : Sample(2),
      contractNumber             : Sample(4),
      exchange                   : Sample(6),
      instrument                 : Sample(6),
      contractType               : Sample(1),
      expiryYear                 : Sample(2),
      expiryMonth                : Sample(1),
      priceDecimalPosition       : Sample(1),
      priceFractionalDenominator : Sample(4),
      priceMinimumTick           : Sample(2),
      lastTradingDate            : Sample(4),
      priorDaySettlement         : Sample(4),
      financialType              : Sample(1),
      currency                   : Sample(3),
      lotSizeOrFaceValue         : Sample(4),
      maturityValue              : Sample(1),
      couponRate                 : Sample(2),
      paymentsPerYear            : Sample(1) ]

EncodeFutureSymbolDirectoryMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.contractNumber
        \o message.exchange
        \o message.instrument
        \o message.contractType
        \o message.expiryYear
        \o message.expiryMonth
        \o message.priceDecimalPosition
        \o message.priceFractionalDenominator
        \o message.priceMinimumTick
        \o message.lastTradingDate
        \o message.priorDaySettlement
        \o message.financialType
        \o message.currency
        \o message.lotSizeOrFaceValue
        \o message.maturityValue
        \o message.couponRate
        \o message.paymentsPerYear

DecodeFutureSymbolDirectoryMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET contractNumber == ReadBytes(tradeDate.rest, 4) IN IF ~contractNumber.ok THEN Fail ELSE
    LET exchange == ReadBytes(contractNumber.rest, 6) IN IF ~exchange.ok THEN Fail ELSE
    LET instrument == ReadBytes(exchange.rest, 6) IN IF ~instrument.ok THEN Fail ELSE
    LET contractType == ReadBytes(instrument.rest, 1) IN IF ~contractType.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(contractType.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryMonth == ReadBytes(expiryYear.rest, 1) IN IF ~expiryMonth.ok THEN Fail ELSE
    LET priceDecimalPosition == ReadBytes(expiryMonth.rest, 1) IN IF ~priceDecimalPosition.ok THEN Fail ELSE
    LET priceFractionalDenominator == ReadBytes(priceDecimalPosition.rest, 4) IN IF ~priceFractionalDenominator.ok THEN Fail ELSE
    LET priceMinimumTick == ReadBytes(priceFractionalDenominator.rest, 2) IN IF ~priceMinimumTick.ok THEN Fail ELSE
    LET lastTradingDate == ReadBytes(priceMinimumTick.rest, 4) IN IF ~lastTradingDate.ok THEN Fail ELSE
    LET priorDaySettlement == ReadBytes(lastTradingDate.rest, 4) IN IF ~priorDaySettlement.ok THEN Fail ELSE
    LET financialType == ReadBytes(priorDaySettlement.rest, 1) IN IF ~financialType.ok THEN Fail ELSE
    LET currency == ReadBytes(financialType.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET lotSizeOrFaceValue == ReadBytes(currency.rest, 4) IN IF ~lotSizeOrFaceValue.ok THEN Fail ELSE
    LET maturityValue == ReadBytes(lotSizeOrFaceValue.rest, 1) IN IF ~maturityValue.ok THEN Fail ELSE
    LET couponRate == ReadBytes(maturityValue.rest, 2) IN IF ~couponRate.ok THEN Fail ELSE
    LET paymentsPerYear == ReadBytes(couponRate.rest, 1) IN IF ~paymentsPerYear.ok THEN Fail ELSE
    Ok([ nanoseconds                |-> nanoseconds.value,
         tradeDate                  |-> tradeDate.value,
         contractNumber             |-> contractNumber.value,
         exchange                   |-> exchange.value,
         instrument                 |-> instrument.value,
         contractType               |-> contractType.value,
         expiryYear                 |-> expiryYear.value,
         expiryMonth                |-> expiryMonth.value,
         priceDecimalPosition       |-> priceDecimalPosition.value,
         priceFractionalDenominator |-> priceFractionalDenominator.value,
         priceMinimumTick           |-> priceMinimumTick.value,
         lastTradingDate            |-> lastTradingDate.value,
         priorDaySettlement         |-> priorDaySettlement.value,
         financialType              |-> financialType.value,
         currency                   |-> currency.value,
         lotSizeOrFaceValue         |-> lotSizeOrFaceValue.value,
         maturityValue              |-> maturityValue.value,
         couponRate                 |-> couponRate.value,
         paymentsPerYear            |-> paymentsPerYear.value ], paymentsPerYear.rest)

ZeroFutureSymbolDirectoryMessage ==
    [ nanoseconds                |-> [i \in 1 .. 4 |-> 0],
      tradeDate                  |-> [i \in 1 .. 2 |-> 0],
      contractNumber             |-> [i \in 1 .. 4 |-> 0],
      exchange                   |-> [i \in 1 .. 6 |-> 0],
      instrument                 |-> [i \in 1 .. 6 |-> 0],
      contractType               |-> [i \in 1 .. 1 |-> 0],
      expiryYear                 |-> [i \in 1 .. 2 |-> 0],
      expiryMonth                |-> [i \in 1 .. 1 |-> 0],
      priceDecimalPosition       |-> [i \in 1 .. 1 |-> 0],
      priceFractionalDenominator |-> [i \in 1 .. 4 |-> 0],
      priceMinimumTick           |-> [i \in 1 .. 2 |-> 0],
      lastTradingDate            |-> [i \in 1 .. 4 |-> 0],
      priorDaySettlement         |-> [i \in 1 .. 4 |-> 0],
      financialType              |-> [i \in 1 .. 1 |-> 0],
      currency                   |-> [i \in 1 .. 3 |-> 0],
      lotSizeOrFaceValue         |-> [i \in 1 .. 4 |-> 0],
      maturityValue              |-> [i \in 1 .. 1 |-> 0],
      couponRate                 |-> [i \in 1 .. 2 |-> 0],
      paymentsPerYear            |-> [i \in 1 .. 1 |-> 0] ]

(* Future Symbol Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedFutureSymbolDirectoryMessage ==
    { ZeroFutureSymbolDirectoryMessage }
        \cup { [ZeroFutureSymbolDirectoryMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroFutureSymbolDirectoryMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroFutureSymbolDirectoryMessage EXCEPT !.contractNumber = one] : one \in Sample(4) }
        \cup { [ZeroFutureSymbolDirectoryMessage EXCEPT !.exchange = one] : one \in Sample(6) }
        \cup { [ZeroFutureSymbolDirectoryMessage EXCEPT !.instrument = one] : one \in Sample(6) }
        \cup { [ZeroFutureSymbolDirectoryMessage EXCEPT !.contractType = one] : one \in Sample(1) }
        \cup { [ZeroFutureSymbolDirectoryMessage EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroFutureSymbolDirectoryMessage EXCEPT !.expiryMonth = one] : one \in Sample(1) }
        \cup { [ZeroFutureSymbolDirectoryMessage EXCEPT !.priceDecimalPosition = one] : one \in Sample(1) }
        \cup { [ZeroFutureSymbolDirectoryMessage EXCEPT !.priceFractionalDenominator = one] : one \in Sample(4) }
        \cup { [ZeroFutureSymbolDirectoryMessage EXCEPT !.priceMinimumTick = one] : one \in Sample(2) }
        \cup { [ZeroFutureSymbolDirectoryMessage EXCEPT !.lastTradingDate = one] : one \in Sample(4) }
        \cup { [ZeroFutureSymbolDirectoryMessage EXCEPT !.priorDaySettlement = one] : one \in Sample(4) }
        \cup { [ZeroFutureSymbolDirectoryMessage EXCEPT !.financialType = one] : one \in Sample(1) }
        \cup { [ZeroFutureSymbolDirectoryMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroFutureSymbolDirectoryMessage EXCEPT !.lotSizeOrFaceValue = one] : one \in Sample(4) }
        \cup { [ZeroFutureSymbolDirectoryMessage EXCEPT !.maturityValue = one] : one \in Sample(1) }
        \cup { [ZeroFutureSymbolDirectoryMessage EXCEPT !.couponRate = one] : one \in Sample(2) }
        \cup { [ZeroFutureSymbolDirectoryMessage EXCEPT !.paymentsPerYear = one] : one \in Sample(1) }

(***************************************************************************)
(* Spread Symbol Directory Message: 34 bytes                               *)
(***************************************************************************)

SpreadSymbolDirectoryMessage ==
    [ nanoseconds                : Sample(4),
      tradeDate                  : Sample(2),
      contractNumber             : Sample(4),
      exchange                   : Sample(6),
      contractType               : Sample(1),
      firstLegContractNumber     : Sample(4),
      secondLegContractNumber    : Sample(4),
      primaryRatio               : Sample(1),
      secondaryRatio             : Sample(1),
      priceDecimalPosition       : Sample(1),
      priceFractionalDenominator : Sample(4),
      priceMinimumTick           : Sample(2) ]

EncodeSpreadSymbolDirectoryMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.contractNumber
        \o message.exchange
        \o message.contractType
        \o message.firstLegContractNumber
        \o message.secondLegContractNumber
        \o message.primaryRatio
        \o message.secondaryRatio
        \o message.priceDecimalPosition
        \o message.priceFractionalDenominator
        \o message.priceMinimumTick

DecodeSpreadSymbolDirectoryMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET contractNumber == ReadBytes(tradeDate.rest, 4) IN IF ~contractNumber.ok THEN Fail ELSE
    LET exchange == ReadBytes(contractNumber.rest, 6) IN IF ~exchange.ok THEN Fail ELSE
    LET contractType == ReadBytes(exchange.rest, 1) IN IF ~contractType.ok THEN Fail ELSE
    LET firstLegContractNumber == ReadBytes(contractType.rest, 4) IN IF ~firstLegContractNumber.ok THEN Fail ELSE
    LET secondLegContractNumber == ReadBytes(firstLegContractNumber.rest, 4) IN IF ~secondLegContractNumber.ok THEN Fail ELSE
    LET primaryRatio == ReadBytes(secondLegContractNumber.rest, 1) IN IF ~primaryRatio.ok THEN Fail ELSE
    LET secondaryRatio == ReadBytes(primaryRatio.rest, 1) IN IF ~secondaryRatio.ok THEN Fail ELSE
    LET priceDecimalPosition == ReadBytes(secondaryRatio.rest, 1) IN IF ~priceDecimalPosition.ok THEN Fail ELSE
    LET priceFractionalDenominator == ReadBytes(priceDecimalPosition.rest, 4) IN IF ~priceFractionalDenominator.ok THEN Fail ELSE
    LET priceMinimumTick == ReadBytes(priceFractionalDenominator.rest, 2) IN IF ~priceMinimumTick.ok THEN Fail ELSE
    Ok([ nanoseconds                |-> nanoseconds.value,
         tradeDate                  |-> tradeDate.value,
         contractNumber             |-> contractNumber.value,
         exchange                   |-> exchange.value,
         contractType               |-> contractType.value,
         firstLegContractNumber     |-> firstLegContractNumber.value,
         secondLegContractNumber    |-> secondLegContractNumber.value,
         primaryRatio               |-> primaryRatio.value,
         secondaryRatio             |-> secondaryRatio.value,
         priceDecimalPosition       |-> priceDecimalPosition.value,
         priceFractionalDenominator |-> priceFractionalDenominator.value,
         priceMinimumTick           |-> priceMinimumTick.value ], priceMinimumTick.rest)

ZeroSpreadSymbolDirectoryMessage ==
    [ nanoseconds                |-> [i \in 1 .. 4 |-> 0],
      tradeDate                  |-> [i \in 1 .. 2 |-> 0],
      contractNumber             |-> [i \in 1 .. 4 |-> 0],
      exchange                   |-> [i \in 1 .. 6 |-> 0],
      contractType               |-> [i \in 1 .. 1 |-> 0],
      firstLegContractNumber     |-> [i \in 1 .. 4 |-> 0],
      secondLegContractNumber    |-> [i \in 1 .. 4 |-> 0],
      primaryRatio               |-> [i \in 1 .. 1 |-> 0],
      secondaryRatio             |-> [i \in 1 .. 1 |-> 0],
      priceDecimalPosition       |-> [i \in 1 .. 1 |-> 0],
      priceFractionalDenominator |-> [i \in 1 .. 4 |-> 0],
      priceMinimumTick           |-> [i \in 1 .. 2 |-> 0] ]

(* Spread Symbol Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedSpreadSymbolDirectoryMessage ==
    { ZeroSpreadSymbolDirectoryMessage }
        \cup { [ZeroSpreadSymbolDirectoryMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSpreadSymbolDirectoryMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroSpreadSymbolDirectoryMessage EXCEPT !.contractNumber = one] : one \in Sample(4) }
        \cup { [ZeroSpreadSymbolDirectoryMessage EXCEPT !.exchange = one] : one \in Sample(6) }
        \cup { [ZeroSpreadSymbolDirectoryMessage EXCEPT !.contractType = one] : one \in Sample(1) }
        \cup { [ZeroSpreadSymbolDirectoryMessage EXCEPT !.firstLegContractNumber = one] : one \in Sample(4) }
        \cup { [ZeroSpreadSymbolDirectoryMessage EXCEPT !.secondLegContractNumber = one] : one \in Sample(4) }
        \cup { [ZeroSpreadSymbolDirectoryMessage EXCEPT !.primaryRatio = one] : one \in Sample(1) }
        \cup { [ZeroSpreadSymbolDirectoryMessage EXCEPT !.secondaryRatio = one] : one \in Sample(1) }
        \cup { [ZeroSpreadSymbolDirectoryMessage EXCEPT !.priceDecimalPosition = one] : one \in Sample(1) }
        \cup { [ZeroSpreadSymbolDirectoryMessage EXCEPT !.priceFractionalDenominator = one] : one \in Sample(4) }
        \cup { [ZeroSpreadSymbolDirectoryMessage EXCEPT !.priceMinimumTick = one] : one \in Sample(2) }

(***************************************************************************)
(* Option Symbol Directory Message: 74 bytes                               *)
(***************************************************************************)

OptionSymbolDirectoryMessage ==
    [ nanoseconds                      : Sample(4),
      tradeDate                        : Sample(2),
      contractNumber                   : Sample(4),
      exchange                         : Sample(6),
      instrument                       : Sample(6),
      contractType                     : Sample(1),
      expiryYear                       : Sample(2),
      expiryMonth                      : Sample(1),
      optionType                       : Sample(1),
      strike                           : Sample(4),
      underlyingContractNumber         : Sample(4),
      priceDecimalPosition             : Sample(1),
      priceFractionalDenominator       : Sample(4),
      priceMinimumTick                 : Sample(2),
      strikePriceDecimalPosition       : Sample(1),
      strikePriceFractionalDenominator : Sample(4),
      strikePriceMinimumTick           : Sample(2),
      lastTradingDate                  : Sample(4),
      priorDaySettlement               : Sample(4),
      volatility                       : Sample(4),
      financialType                    : Sample(1),
      currency                         : Sample(3),
      lotSizeOrFaceValue               : Sample(4),
      maturityValue                    : Sample(1),
      couponRate                       : Sample(2),
      paymentsPerYear                  : Sample(1),
      activated                        : Sample(1) ]

EncodeOptionSymbolDirectoryMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.contractNumber
        \o message.exchange
        \o message.instrument
        \o message.contractType
        \o message.expiryYear
        \o message.expiryMonth
        \o message.optionType
        \o message.strike
        \o message.underlyingContractNumber
        \o message.priceDecimalPosition
        \o message.priceFractionalDenominator
        \o message.priceMinimumTick
        \o message.strikePriceDecimalPosition
        \o message.strikePriceFractionalDenominator
        \o message.strikePriceMinimumTick
        \o message.lastTradingDate
        \o message.priorDaySettlement
        \o message.volatility
        \o message.financialType
        \o message.currency
        \o message.lotSizeOrFaceValue
        \o message.maturityValue
        \o message.couponRate
        \o message.paymentsPerYear
        \o message.activated

DecodeOptionSymbolDirectoryMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET contractNumber == ReadBytes(tradeDate.rest, 4) IN IF ~contractNumber.ok THEN Fail ELSE
    LET exchange == ReadBytes(contractNumber.rest, 6) IN IF ~exchange.ok THEN Fail ELSE
    LET instrument == ReadBytes(exchange.rest, 6) IN IF ~instrument.ok THEN Fail ELSE
    LET contractType == ReadBytes(instrument.rest, 1) IN IF ~contractType.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(contractType.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryMonth == ReadBytes(expiryYear.rest, 1) IN IF ~expiryMonth.ok THEN Fail ELSE
    LET optionType == ReadBytes(expiryMonth.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET strike == ReadBytes(optionType.rest, 4) IN IF ~strike.ok THEN Fail ELSE
    LET underlyingContractNumber == ReadBytes(strike.rest, 4) IN IF ~underlyingContractNumber.ok THEN Fail ELSE
    LET priceDecimalPosition == ReadBytes(underlyingContractNumber.rest, 1) IN IF ~priceDecimalPosition.ok THEN Fail ELSE
    LET priceFractionalDenominator == ReadBytes(priceDecimalPosition.rest, 4) IN IF ~priceFractionalDenominator.ok THEN Fail ELSE
    LET priceMinimumTick == ReadBytes(priceFractionalDenominator.rest, 2) IN IF ~priceMinimumTick.ok THEN Fail ELSE
    LET strikePriceDecimalPosition == ReadBytes(priceMinimumTick.rest, 1) IN IF ~strikePriceDecimalPosition.ok THEN Fail ELSE
    LET strikePriceFractionalDenominator == ReadBytes(strikePriceDecimalPosition.rest, 4) IN IF ~strikePriceFractionalDenominator.ok THEN Fail ELSE
    LET strikePriceMinimumTick == ReadBytes(strikePriceFractionalDenominator.rest, 2) IN IF ~strikePriceMinimumTick.ok THEN Fail ELSE
    LET lastTradingDate == ReadBytes(strikePriceMinimumTick.rest, 4) IN IF ~lastTradingDate.ok THEN Fail ELSE
    LET priorDaySettlement == ReadBytes(lastTradingDate.rest, 4) IN IF ~priorDaySettlement.ok THEN Fail ELSE
    LET volatility == ReadBytes(priorDaySettlement.rest, 4) IN IF ~volatility.ok THEN Fail ELSE
    LET financialType == ReadBytes(volatility.rest, 1) IN IF ~financialType.ok THEN Fail ELSE
    LET currency == ReadBytes(financialType.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET lotSizeOrFaceValue == ReadBytes(currency.rest, 4) IN IF ~lotSizeOrFaceValue.ok THEN Fail ELSE
    LET maturityValue == ReadBytes(lotSizeOrFaceValue.rest, 1) IN IF ~maturityValue.ok THEN Fail ELSE
    LET couponRate == ReadBytes(maturityValue.rest, 2) IN IF ~couponRate.ok THEN Fail ELSE
    LET paymentsPerYear == ReadBytes(couponRate.rest, 1) IN IF ~paymentsPerYear.ok THEN Fail ELSE
    LET activated == ReadBytes(paymentsPerYear.rest, 1) IN IF ~activated.ok THEN Fail ELSE
    Ok([ nanoseconds                      |-> nanoseconds.value,
         tradeDate                        |-> tradeDate.value,
         contractNumber                   |-> contractNumber.value,
         exchange                         |-> exchange.value,
         instrument                       |-> instrument.value,
         contractType                     |-> contractType.value,
         expiryYear                       |-> expiryYear.value,
         expiryMonth                      |-> expiryMonth.value,
         optionType                       |-> optionType.value,
         strike                           |-> strike.value,
         underlyingContractNumber         |-> underlyingContractNumber.value,
         priceDecimalPosition             |-> priceDecimalPosition.value,
         priceFractionalDenominator       |-> priceFractionalDenominator.value,
         priceMinimumTick                 |-> priceMinimumTick.value,
         strikePriceDecimalPosition       |-> strikePriceDecimalPosition.value,
         strikePriceFractionalDenominator |-> strikePriceFractionalDenominator.value,
         strikePriceMinimumTick           |-> strikePriceMinimumTick.value,
         lastTradingDate                  |-> lastTradingDate.value,
         priorDaySettlement               |-> priorDaySettlement.value,
         volatility                       |-> volatility.value,
         financialType                    |-> financialType.value,
         currency                         |-> currency.value,
         lotSizeOrFaceValue               |-> lotSizeOrFaceValue.value,
         maturityValue                    |-> maturityValue.value,
         couponRate                       |-> couponRate.value,
         paymentsPerYear                  |-> paymentsPerYear.value,
         activated                        |-> activated.value ], activated.rest)

ZeroOptionSymbolDirectoryMessage ==
    [ nanoseconds                      |-> [i \in 1 .. 4 |-> 0],
      tradeDate                        |-> [i \in 1 .. 2 |-> 0],
      contractNumber                   |-> [i \in 1 .. 4 |-> 0],
      exchange                         |-> [i \in 1 .. 6 |-> 0],
      instrument                       |-> [i \in 1 .. 6 |-> 0],
      contractType                     |-> [i \in 1 .. 1 |-> 0],
      expiryYear                       |-> [i \in 1 .. 2 |-> 0],
      expiryMonth                      |-> [i \in 1 .. 1 |-> 0],
      optionType                       |-> [i \in 1 .. 1 |-> 0],
      strike                           |-> [i \in 1 .. 4 |-> 0],
      underlyingContractNumber         |-> [i \in 1 .. 4 |-> 0],
      priceDecimalPosition             |-> [i \in 1 .. 1 |-> 0],
      priceFractionalDenominator       |-> [i \in 1 .. 4 |-> 0],
      priceMinimumTick                 |-> [i \in 1 .. 2 |-> 0],
      strikePriceDecimalPosition       |-> [i \in 1 .. 1 |-> 0],
      strikePriceFractionalDenominator |-> [i \in 1 .. 4 |-> 0],
      strikePriceMinimumTick           |-> [i \in 1 .. 2 |-> 0],
      lastTradingDate                  |-> [i \in 1 .. 4 |-> 0],
      priorDaySettlement               |-> [i \in 1 .. 4 |-> 0],
      volatility                       |-> [i \in 1 .. 4 |-> 0],
      financialType                    |-> [i \in 1 .. 1 |-> 0],
      currency                         |-> [i \in 1 .. 3 |-> 0],
      lotSizeOrFaceValue               |-> [i \in 1 .. 4 |-> 0],
      maturityValue                    |-> [i \in 1 .. 1 |-> 0],
      couponRate                       |-> [i \in 1 .. 2 |-> 0],
      paymentsPerYear                  |-> [i \in 1 .. 1 |-> 0],
      activated                        |-> [i \in 1 .. 1 |-> 0] ]

(* Option Symbol Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionSymbolDirectoryMessage ==
    { ZeroOptionSymbolDirectoryMessage }
        \cup { [ZeroOptionSymbolDirectoryMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOptionSymbolDirectoryMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroOptionSymbolDirectoryMessage EXCEPT !.contractNumber = one] : one \in Sample(4) }
        \cup { [ZeroOptionSymbolDirectoryMessage EXCEPT !.exchange = one] : one \in Sample(6) }
        \cup { [ZeroOptionSymbolDirectoryMessage EXCEPT !.instrument = one] : one \in Sample(6) }
        \cup { [ZeroOptionSymbolDirectoryMessage EXCEPT !.contractType = one] : one \in Sample(1) }
        \cup { [ZeroOptionSymbolDirectoryMessage EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroOptionSymbolDirectoryMessage EXCEPT !.expiryMonth = one] : one \in Sample(1) }
        \cup { [ZeroOptionSymbolDirectoryMessage EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroOptionSymbolDirectoryMessage EXCEPT !.strike = one] : one \in Sample(4) }
        \cup { [ZeroOptionSymbolDirectoryMessage EXCEPT !.underlyingContractNumber = one] : one \in Sample(4) }
        \cup { [ZeroOptionSymbolDirectoryMessage EXCEPT !.priceDecimalPosition = one] : one \in Sample(1) }
        \cup { [ZeroOptionSymbolDirectoryMessage EXCEPT !.priceFractionalDenominator = one] : one \in Sample(4) }
        \cup { [ZeroOptionSymbolDirectoryMessage EXCEPT !.priceMinimumTick = one] : one \in Sample(2) }
        \cup { [ZeroOptionSymbolDirectoryMessage EXCEPT !.strikePriceDecimalPosition = one] : one \in Sample(1) }
        \cup { [ZeroOptionSymbolDirectoryMessage EXCEPT !.strikePriceFractionalDenominator = one] : one \in Sample(4) }
        \cup { [ZeroOptionSymbolDirectoryMessage EXCEPT !.strikePriceMinimumTick = one] : one \in Sample(2) }
        \cup { [ZeroOptionSymbolDirectoryMessage EXCEPT !.lastTradingDate = one] : one \in Sample(4) }
        \cup { [ZeroOptionSymbolDirectoryMessage EXCEPT !.priorDaySettlement = one] : one \in Sample(4) }
        \cup { [ZeroOptionSymbolDirectoryMessage EXCEPT !.volatility = one] : one \in Sample(4) }
        \cup { [ZeroOptionSymbolDirectoryMessage EXCEPT !.financialType = one] : one \in Sample(1) }
        \cup { [ZeroOptionSymbolDirectoryMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroOptionSymbolDirectoryMessage EXCEPT !.lotSizeOrFaceValue = one] : one \in Sample(4) }
        \cup { [ZeroOptionSymbolDirectoryMessage EXCEPT !.maturityValue = one] : one \in Sample(1) }
        \cup { [ZeroOptionSymbolDirectoryMessage EXCEPT !.couponRate = one] : one \in Sample(2) }
        \cup { [ZeroOptionSymbolDirectoryMessage EXCEPT !.paymentsPerYear = one] : one \in Sample(1) }
        \cup { [ZeroOptionSymbolDirectoryMessage EXCEPT !.activated = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Book State Message: 11 bytes                                      *)
(***************************************************************************)

OrderBookStateMessage ==
    [ nanoseconds    : Sample(4),
      tradeDate      : Sample(2),
      contractNumber : Sample(4),
      tradingStatus  : Sample(1) ]

EncodeOrderBookStateMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.contractNumber
        \o message.tradingStatus

DecodeOrderBookStateMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET contractNumber == ReadBytes(tradeDate.rest, 4) IN IF ~contractNumber.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(contractNumber.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    Ok([ nanoseconds    |-> nanoseconds.value,
         tradeDate      |-> tradeDate.value,
         contractNumber |-> contractNumber.value,
         tradingStatus  |-> tradingStatus.value ], tradingStatus.rest)

ZeroOrderBookStateMessage ==
    [ nanoseconds    |-> [i \in 1 .. 4 |-> 0],
      tradeDate      |-> [i \in 1 .. 2 |-> 0],
      contractNumber |-> [i \in 1 .. 4 |-> 0],
      tradingStatus  |-> [i \in 1 .. 1 |-> 0] ]

(* Order Book State Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderBookStateMessage ==
    { ZeroOrderBookStateMessage }
        \cup { [ZeroOrderBookStateMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookStateMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroOrderBookStateMessage EXCEPT !.contractNumber = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookStateMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Added Message: 31 bytes                                           *)
(***************************************************************************)

OrderAddedMessage ==
    [ nanoseconds       : Sample(4),
      tradeDate         : Sample(2),
      contractNumber    : Sample(4),
      side              : Sample(1),
      orderNumber       : Sample(8),
      orderBookPriority : Sample(4),
      quantity          : Sample(4),
      price             : Sample(4) ]

EncodeOrderAddedMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.contractNumber
        \o message.side
        \o message.orderNumber
        \o message.orderBookPriority
        \o message.quantity
        \o message.price

DecodeOrderAddedMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET contractNumber == ReadBytes(tradeDate.rest, 4) IN IF ~contractNumber.ok THEN Fail ELSE
    LET side == ReadBytes(contractNumber.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(side.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET orderBookPriority == ReadBytes(orderNumber.rest, 4) IN IF ~orderBookPriority.ok THEN Fail ELSE
    LET quantity == ReadBytes(orderBookPriority.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 4) IN IF ~price.ok THEN Fail ELSE
    Ok([ nanoseconds       |-> nanoseconds.value,
         tradeDate         |-> tradeDate.value,
         contractNumber    |-> contractNumber.value,
         side              |-> side.value,
         orderNumber       |-> orderNumber.value,
         orderBookPriority |-> orderBookPriority.value,
         quantity          |-> quantity.value,
         price             |-> price.value ], price.rest)

ZeroOrderAddedMessage ==
    [ nanoseconds       |-> [i \in 1 .. 4 |-> 0],
      tradeDate         |-> [i \in 1 .. 2 |-> 0],
      contractNumber    |-> [i \in 1 .. 4 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      orderNumber       |-> [i \in 1 .. 8 |-> 0],
      orderBookPriority |-> [i \in 1 .. 4 |-> 0],
      quantity          |-> [i \in 1 .. 4 |-> 0],
      price             |-> [i \in 1 .. 4 |-> 0] ]

(* Order Added Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderAddedMessage ==
    { ZeroOrderAddedMessage }
        \cup { [ZeroOrderAddedMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderAddedMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroOrderAddedMessage EXCEPT !.contractNumber = one] : one \in Sample(4) }
        \cup { [ZeroOrderAddedMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderAddedMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderAddedMessage EXCEPT !.orderBookPriority = one] : one \in Sample(4) }
        \cup { [ZeroOrderAddedMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderAddedMessage EXCEPT !.price = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Replaced Message: 31 bytes                                        *)
(***************************************************************************)

OrderReplacedMessage ==
    [ nanoseconds       : Sample(4),
      tradeDate         : Sample(2),
      contractNumber    : Sample(4),
      side              : Sample(1),
      orderNumber       : Sample(8),
      orderBookPriority : Sample(4),
      quantity          : Sample(4),
      price             : Sample(4) ]

EncodeOrderReplacedMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.contractNumber
        \o message.side
        \o message.orderNumber
        \o message.orderBookPriority
        \o message.quantity
        \o message.price

DecodeOrderReplacedMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET contractNumber == ReadBytes(tradeDate.rest, 4) IN IF ~contractNumber.ok THEN Fail ELSE
    LET side == ReadBytes(contractNumber.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(side.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET orderBookPriority == ReadBytes(orderNumber.rest, 4) IN IF ~orderBookPriority.ok THEN Fail ELSE
    LET quantity == ReadBytes(orderBookPriority.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 4) IN IF ~price.ok THEN Fail ELSE
    Ok([ nanoseconds       |-> nanoseconds.value,
         tradeDate         |-> tradeDate.value,
         contractNumber    |-> contractNumber.value,
         side              |-> side.value,
         orderNumber       |-> orderNumber.value,
         orderBookPriority |-> orderBookPriority.value,
         quantity          |-> quantity.value,
         price             |-> price.value ], price.rest)

ZeroOrderReplacedMessage ==
    [ nanoseconds       |-> [i \in 1 .. 4 |-> 0],
      tradeDate         |-> [i \in 1 .. 2 |-> 0],
      contractNumber    |-> [i \in 1 .. 4 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      orderNumber       |-> [i \in 1 .. 8 |-> 0],
      orderBookPriority |-> [i \in 1 .. 4 |-> 0],
      quantity          |-> [i \in 1 .. 4 |-> 0],
      price             |-> [i \in 1 .. 4 |-> 0] ]

(* Order Replaced Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderReplacedMessage ==
    { ZeroOrderReplacedMessage }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.contractNumber = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.orderBookPriority = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.price = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Volume Cancelled Message: 23 bytes                                *)
(***************************************************************************)

OrderVolumeCancelledMessage ==
    [ nanoseconds    : Sample(4),
      tradeDate      : Sample(2),
      contractNumber : Sample(4),
      side           : Sample(1),
      orderNumber    : Sample(8),
      quantity       : Sample(4) ]

EncodeOrderVolumeCancelledMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.contractNumber
        \o message.side
        \o message.orderNumber
        \o message.quantity

DecodeOrderVolumeCancelledMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET contractNumber == ReadBytes(tradeDate.rest, 4) IN IF ~contractNumber.ok THEN Fail ELSE
    LET side == ReadBytes(contractNumber.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(side.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET quantity == ReadBytes(orderNumber.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    Ok([ nanoseconds    |-> nanoseconds.value,
         tradeDate      |-> tradeDate.value,
         contractNumber |-> contractNumber.value,
         side           |-> side.value,
         orderNumber    |-> orderNumber.value,
         quantity       |-> quantity.value ], quantity.rest)

ZeroOrderVolumeCancelledMessage ==
    [ nanoseconds    |-> [i \in 1 .. 4 |-> 0],
      tradeDate      |-> [i \in 1 .. 2 |-> 0],
      contractNumber |-> [i \in 1 .. 4 |-> 0],
      side           |-> [i \in 1 .. 1 |-> 0],
      orderNumber    |-> [i \in 1 .. 8 |-> 0],
      quantity       |-> [i \in 1 .. 4 |-> 0] ]

(* Order Volume Cancelled Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderVolumeCancelledMessage ==
    { ZeroOrderVolumeCancelledMessage }
        \cup { [ZeroOrderVolumeCancelledMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderVolumeCancelledMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroOrderVolumeCancelledMessage EXCEPT !.contractNumber = one] : one \in Sample(4) }
        \cup { [ZeroOrderVolumeCancelledMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderVolumeCancelledMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderVolumeCancelledMessage EXCEPT !.quantity = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Deleted Message: 19 bytes                                         *)
(***************************************************************************)

OrderDeletedMessage ==
    [ nanoseconds    : Sample(4),
      tradeDate      : Sample(2),
      contractNumber : Sample(4),
      side           : Sample(1),
      orderNumber    : Sample(8) ]

EncodeOrderDeletedMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.contractNumber
        \o message.side
        \o message.orderNumber

DecodeOrderDeletedMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET contractNumber == ReadBytes(tradeDate.rest, 4) IN IF ~contractNumber.ok THEN Fail ELSE
    LET side == ReadBytes(contractNumber.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(side.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    Ok([ nanoseconds    |-> nanoseconds.value,
         tradeDate      |-> tradeDate.value,
         contractNumber |-> contractNumber.value,
         side           |-> side.value,
         orderNumber    |-> orderNumber.value ], orderNumber.rest)

ZeroOrderDeletedMessage ==
    [ nanoseconds    |-> [i \in 1 .. 4 |-> 0],
      tradeDate      |-> [i \in 1 .. 2 |-> 0],
      contractNumber |-> [i \in 1 .. 4 |-> 0],
      side           |-> [i \in 1 .. 1 |-> 0],
      orderNumber    |-> [i \in 1 .. 8 |-> 0] ]

(* Order Deleted Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderDeletedMessage ==
    { ZeroOrderDeletedMessage }
        \cup { [ZeroOrderDeletedMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderDeletedMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroOrderDeletedMessage EXCEPT !.contractNumber = one] : one \in Sample(4) }
        \cup { [ZeroOrderDeletedMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderDeletedMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Implied Order Added Message: 31 bytes                                   *)
(***************************************************************************)

ImpliedOrderAddedMessage ==
    [ nanoseconds       : Sample(4),
      tradeDate         : Sample(2),
      contractNumber    : Sample(4),
      side              : Sample(1),
      orderNumber       : Sample(8),
      orderBookPriority : Sample(4),
      quantity          : Sample(4),
      price             : Sample(4) ]

EncodeImpliedOrderAddedMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.contractNumber
        \o message.side
        \o message.orderNumber
        \o message.orderBookPriority
        \o message.quantity
        \o message.price

DecodeImpliedOrderAddedMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET contractNumber == ReadBytes(tradeDate.rest, 4) IN IF ~contractNumber.ok THEN Fail ELSE
    LET side == ReadBytes(contractNumber.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(side.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET orderBookPriority == ReadBytes(orderNumber.rest, 4) IN IF ~orderBookPriority.ok THEN Fail ELSE
    LET quantity == ReadBytes(orderBookPriority.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 4) IN IF ~price.ok THEN Fail ELSE
    Ok([ nanoseconds       |-> nanoseconds.value,
         tradeDate         |-> tradeDate.value,
         contractNumber    |-> contractNumber.value,
         side              |-> side.value,
         orderNumber       |-> orderNumber.value,
         orderBookPriority |-> orderBookPriority.value,
         quantity          |-> quantity.value,
         price             |-> price.value ], price.rest)

ZeroImpliedOrderAddedMessage ==
    [ nanoseconds       |-> [i \in 1 .. 4 |-> 0],
      tradeDate         |-> [i \in 1 .. 2 |-> 0],
      contractNumber    |-> [i \in 1 .. 4 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      orderNumber       |-> [i \in 1 .. 8 |-> 0],
      orderBookPriority |-> [i \in 1 .. 4 |-> 0],
      quantity          |-> [i \in 1 .. 4 |-> 0],
      price             |-> [i \in 1 .. 4 |-> 0] ]

(* Implied Order Added Message at zero, then each field in turn at the values it is checked at *)
CheckedImpliedOrderAddedMessage ==
    { ZeroImpliedOrderAddedMessage }
        \cup { [ZeroImpliedOrderAddedMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroImpliedOrderAddedMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroImpliedOrderAddedMessage EXCEPT !.contractNumber = one] : one \in Sample(4) }
        \cup { [ZeroImpliedOrderAddedMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroImpliedOrderAddedMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroImpliedOrderAddedMessage EXCEPT !.orderBookPriority = one] : one \in Sample(4) }
        \cup { [ZeroImpliedOrderAddedMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroImpliedOrderAddedMessage EXCEPT !.price = one] : one \in Sample(4) }

(***************************************************************************)
(* Implied Order Replaced Message: 31 bytes                                *)
(***************************************************************************)

ImpliedOrderReplacedMessage ==
    [ nanoseconds       : Sample(4),
      tradeDate         : Sample(2),
      contractNumber    : Sample(4),
      side              : Sample(1),
      orderNumber       : Sample(8),
      orderBookPriority : Sample(4),
      quantity          : Sample(4),
      price             : Sample(4) ]

EncodeImpliedOrderReplacedMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.contractNumber
        \o message.side
        \o message.orderNumber
        \o message.orderBookPriority
        \o message.quantity
        \o message.price

DecodeImpliedOrderReplacedMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET contractNumber == ReadBytes(tradeDate.rest, 4) IN IF ~contractNumber.ok THEN Fail ELSE
    LET side == ReadBytes(contractNumber.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(side.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET orderBookPriority == ReadBytes(orderNumber.rest, 4) IN IF ~orderBookPriority.ok THEN Fail ELSE
    LET quantity == ReadBytes(orderBookPriority.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 4) IN IF ~price.ok THEN Fail ELSE
    Ok([ nanoseconds       |-> nanoseconds.value,
         tradeDate         |-> tradeDate.value,
         contractNumber    |-> contractNumber.value,
         side              |-> side.value,
         orderNumber       |-> orderNumber.value,
         orderBookPriority |-> orderBookPriority.value,
         quantity          |-> quantity.value,
         price             |-> price.value ], price.rest)

ZeroImpliedOrderReplacedMessage ==
    [ nanoseconds       |-> [i \in 1 .. 4 |-> 0],
      tradeDate         |-> [i \in 1 .. 2 |-> 0],
      contractNumber    |-> [i \in 1 .. 4 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      orderNumber       |-> [i \in 1 .. 8 |-> 0],
      orderBookPriority |-> [i \in 1 .. 4 |-> 0],
      quantity          |-> [i \in 1 .. 4 |-> 0],
      price             |-> [i \in 1 .. 4 |-> 0] ]

(* Implied Order Replaced Message at zero, then each field in turn at the values it is checked at *)
CheckedImpliedOrderReplacedMessage ==
    { ZeroImpliedOrderReplacedMessage }
        \cup { [ZeroImpliedOrderReplacedMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroImpliedOrderReplacedMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroImpliedOrderReplacedMessage EXCEPT !.contractNumber = one] : one \in Sample(4) }
        \cup { [ZeroImpliedOrderReplacedMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroImpliedOrderReplacedMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroImpliedOrderReplacedMessage EXCEPT !.orderBookPriority = one] : one \in Sample(4) }
        \cup { [ZeroImpliedOrderReplacedMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroImpliedOrderReplacedMessage EXCEPT !.price = one] : one \in Sample(4) }

(***************************************************************************)
(* Implied Order Deleted Message: 19 bytes                                 *)
(***************************************************************************)

ImpliedOrderDeletedMessage ==
    [ nanoseconds    : Sample(4),
      tradeDate      : Sample(2),
      contractNumber : Sample(4),
      side           : Sample(1),
      orderNumber    : Sample(8) ]

EncodeImpliedOrderDeletedMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.contractNumber
        \o message.side
        \o message.orderNumber

DecodeImpliedOrderDeletedMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET contractNumber == ReadBytes(tradeDate.rest, 4) IN IF ~contractNumber.ok THEN Fail ELSE
    LET side == ReadBytes(contractNumber.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(side.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    Ok([ nanoseconds    |-> nanoseconds.value,
         tradeDate      |-> tradeDate.value,
         contractNumber |-> contractNumber.value,
         side           |-> side.value,
         orderNumber    |-> orderNumber.value ], orderNumber.rest)

ZeroImpliedOrderDeletedMessage ==
    [ nanoseconds    |-> [i \in 1 .. 4 |-> 0],
      tradeDate      |-> [i \in 1 .. 2 |-> 0],
      contractNumber |-> [i \in 1 .. 4 |-> 0],
      side           |-> [i \in 1 .. 1 |-> 0],
      orderNumber    |-> [i \in 1 .. 8 |-> 0] ]

(* Implied Order Deleted Message at zero, then each field in turn at the values it is checked at *)
CheckedImpliedOrderDeletedMessage ==
    { ZeroImpliedOrderDeletedMessage }
        \cup { [ZeroImpliedOrderDeletedMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroImpliedOrderDeletedMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroImpliedOrderDeletedMessage EXCEPT !.contractNumber = one] : one \in Sample(4) }
        \cup { [ZeroImpliedOrderDeletedMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroImpliedOrderDeletedMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Contract Legs: 11 bytes                                                 *)
(***************************************************************************)

ContractLegs ==
    [ contractNumber : Sample(4),
      side           : Sample(1),
      ratio          : Sample(2),
      price          : Sample(4) ]

EncodeContractLegs(message) ==
    message.contractNumber
        \o message.side
        \o message.ratio
        \o message.price

DecodeContractLegs(bytes) ==
    LET contractNumber == ReadBytes(bytes, 4) IN IF ~contractNumber.ok THEN Fail ELSE
    LET side == ReadBytes(contractNumber.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ratio == ReadBytes(side.rest, 2) IN IF ~ratio.ok THEN Fail ELSE
    LET price == ReadBytes(ratio.rest, 4) IN IF ~price.ok THEN Fail ELSE
    Ok([ contractNumber |-> contractNumber.value,
         side           |-> side.value,
         ratio          |-> ratio.value,
         price          |-> price.value ], price.rest)

ZeroContractLegs ==
    [ contractNumber |-> [i \in 1 .. 4 |-> 0],
      side           |-> [i \in 1 .. 1 |-> 0],
      ratio          |-> [i \in 1 .. 2 |-> 0],
      price          |-> [i \in 1 .. 4 |-> 0] ]

(* Contract Legs at zero, then each field in turn at the values it is checked at *)
CheckedContractLegs ==
    { ZeroContractLegs }
        \cup { [ZeroContractLegs EXCEPT !.contractNumber = one] : one \in Sample(4) }
        \cup { [ZeroContractLegs EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroContractLegs EXCEPT !.ratio = one] : one \in Sample(2) }
        \cup { [ZeroContractLegs EXCEPT !.price = one] : one \in Sample(4) }

(* A run of Contract Legs, written one after another *)
RECURSIVE EncodeContractLegsList(_)
EncodeContractLegsList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeContractLegs(Head(messages)) \o EncodeContractLegsList(Tail(messages))

(* As many Contract Legs as the field that counts them says *)
RECURSIVE ReadContractLegsList(_, _)
ReadContractLegsList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeContractLegs(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadContractLegsList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Contract Legs of each kind, for the lists that carry them *)
OneContractLegs == { ZeroContractLegs }

(* The 6 slots a run of Contract Legs is written as, whatever the field beside it says are in use *)
SlotsContractLegs == { [i \in 1 .. 6 |-> one] : one \in OneContractLegs }

(***************************************************************************)
(* Custom Market Order Added Message                                       *)
(***************************************************************************)

CustomMarketOrderAddedMessage ==
    [ nanoseconds       : Sample(4),
      tradeDate         : Sample(2),
      orderNumber       : Sample(8),
      orderBookPriority : Sample(4),
      quantity          : Sample(4),
      legs              : Sample(1),
      contractLegs      : SlotsContractLegs ]

EncodeCustomMarketOrderAddedMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.orderNumber
        \o message.orderBookPriority
        \o message.quantity
        \o message.legs
        \o EncodeContractLegsList(message.contractLegs)

DecodeCustomMarketOrderAddedMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(tradeDate.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET orderBookPriority == ReadBytes(orderNumber.rest, 4) IN IF ~orderBookPriority.ok THEN Fail ELSE
    LET quantity == ReadBytes(orderBookPriority.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET legs == ReadBytes(quantity.rest, 1) IN IF ~legs.ok THEN Fail ELSE
    LET contractLegs == ReadContractLegsList(legs.rest, 6) IN IF ~contractLegs.ok THEN Fail ELSE
    Ok([ nanoseconds       |-> nanoseconds.value,
         tradeDate         |-> tradeDate.value,
         orderNumber       |-> orderNumber.value,
         orderBookPriority |-> orderBookPriority.value,
         quantity          |-> quantity.value,
         legs              |-> legs.value,
         contractLegs      |-> contractLegs.value ], contractLegs.rest)

ZeroCustomMarketOrderAddedMessage ==
    [ nanoseconds       |-> [i \in 1 .. 4 |-> 0],
      tradeDate         |-> [i \in 1 .. 2 |-> 0],
      orderNumber       |-> [i \in 1 .. 8 |-> 0],
      orderBookPriority |-> [i \in 1 .. 4 |-> 0],
      quantity          |-> [i \in 1 .. 4 |-> 0],
      legs              |-> [i \in 1 .. 1 |-> 0],
      contractLegs      |-> [i \in 1 .. 6 |-> ZeroContractLegs] ]

(* Custom Market Order Added Message at zero, then each field in turn at the values it is checked at *)
CheckedCustomMarketOrderAddedMessage ==
    { ZeroCustomMarketOrderAddedMessage }
        \cup { [ZeroCustomMarketOrderAddedMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroCustomMarketOrderAddedMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroCustomMarketOrderAddedMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroCustomMarketOrderAddedMessage EXCEPT !.orderBookPriority = one] : one \in Sample(4) }
        \cup { [ZeroCustomMarketOrderAddedMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroCustomMarketOrderAddedMessage EXCEPT !.legs = one] : one \in Sample(1) }
        \cup { [ZeroCustomMarketOrderAddedMessage EXCEPT !.contractLegs = one] : one \in SlotsContractLegs }

(***************************************************************************)
(* Custom Market Order Replaced Message: 22 bytes                          *)
(***************************************************************************)

CustomMarketOrderReplacedMessage ==
    [ nanoseconds       : Sample(4),
      tradeDate         : Sample(2),
      orderNumber       : Sample(8),
      orderBookPriority : Sample(4),
      quantity          : Sample(4) ]

EncodeCustomMarketOrderReplacedMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.orderNumber
        \o message.orderBookPriority
        \o message.quantity

DecodeCustomMarketOrderReplacedMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(tradeDate.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET orderBookPriority == ReadBytes(orderNumber.rest, 4) IN IF ~orderBookPriority.ok THEN Fail ELSE
    LET quantity == ReadBytes(orderBookPriority.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    Ok([ nanoseconds       |-> nanoseconds.value,
         tradeDate         |-> tradeDate.value,
         orderNumber       |-> orderNumber.value,
         orderBookPriority |-> orderBookPriority.value,
         quantity          |-> quantity.value ], quantity.rest)

ZeroCustomMarketOrderReplacedMessage ==
    [ nanoseconds       |-> [i \in 1 .. 4 |-> 0],
      tradeDate         |-> [i \in 1 .. 2 |-> 0],
      orderNumber       |-> [i \in 1 .. 8 |-> 0],
      orderBookPriority |-> [i \in 1 .. 4 |-> 0],
      quantity          |-> [i \in 1 .. 4 |-> 0] ]

(* Custom Market Order Replaced Message at zero, then each field in turn at the values it is checked at *)
CheckedCustomMarketOrderReplacedMessage ==
    { ZeroCustomMarketOrderReplacedMessage }
        \cup { [ZeroCustomMarketOrderReplacedMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroCustomMarketOrderReplacedMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroCustomMarketOrderReplacedMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroCustomMarketOrderReplacedMessage EXCEPT !.orderBookPriority = one] : one \in Sample(4) }
        \cup { [ZeroCustomMarketOrderReplacedMessage EXCEPT !.quantity = one] : one \in Sample(4) }

(***************************************************************************)
(* Custom Market Order Deleted Message: 14 bytes                           *)
(***************************************************************************)

CustomMarketOrderDeletedMessage ==
    [ nanoseconds : Sample(4),
      tradeDate   : Sample(2),
      orderNumber : Sample(8) ]

EncodeCustomMarketOrderDeletedMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.orderNumber

DecodeCustomMarketOrderDeletedMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(tradeDate.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    Ok([ nanoseconds |-> nanoseconds.value,
         tradeDate   |-> tradeDate.value,
         orderNumber |-> orderNumber.value ], orderNumber.rest)

ZeroCustomMarketOrderDeletedMessage ==
    [ nanoseconds |-> [i \in 1 .. 4 |-> 0],
      tradeDate   |-> [i \in 1 .. 2 |-> 0],
      orderNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Custom Market Order Deleted Message at zero, then each field in turn at the values it is checked at *)
CheckedCustomMarketOrderDeletedMessage ==
    { ZeroCustomMarketOrderDeletedMessage }
        \cup { [ZeroCustomMarketOrderDeletedMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroCustomMarketOrderDeletedMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroCustomMarketOrderDeletedMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Executed Message: 36 bytes                                        *)
(***************************************************************************)

OrderExecutedMessage ==
    [ nanoseconds       : Sample(4),
      tradeDate         : Sample(2),
      contractNumber    : Sample(4),
      side              : Sample(1),
      orderNumber       : Sample(8),
      quantityRemaining : Sample(4),
      tradeType         : Sample(1),
      matchNumber       : Sample(4),
      executedQuantity  : Sample(4),
      tradePrice        : Sample(4) ]

EncodeOrderExecutedMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.contractNumber
        \o message.side
        \o message.orderNumber
        \o message.quantityRemaining
        \o message.tradeType
        \o message.matchNumber
        \o message.executedQuantity
        \o message.tradePrice

DecodeOrderExecutedMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET contractNumber == ReadBytes(tradeDate.rest, 4) IN IF ~contractNumber.ok THEN Fail ELSE
    LET side == ReadBytes(contractNumber.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(side.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET quantityRemaining == ReadBytes(orderNumber.rest, 4) IN IF ~quantityRemaining.ok THEN Fail ELSE
    LET tradeType == ReadBytes(quantityRemaining.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(tradeType.rest, 4) IN IF ~matchNumber.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(matchNumber.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(executedQuantity.rest, 4) IN IF ~tradePrice.ok THEN Fail ELSE
    Ok([ nanoseconds       |-> nanoseconds.value,
         tradeDate         |-> tradeDate.value,
         contractNumber    |-> contractNumber.value,
         side              |-> side.value,
         orderNumber       |-> orderNumber.value,
         quantityRemaining |-> quantityRemaining.value,
         tradeType         |-> tradeType.value,
         matchNumber       |-> matchNumber.value,
         executedQuantity  |-> executedQuantity.value,
         tradePrice        |-> tradePrice.value ], tradePrice.rest)

ZeroOrderExecutedMessage ==
    [ nanoseconds       |-> [i \in 1 .. 4 |-> 0],
      tradeDate         |-> [i \in 1 .. 2 |-> 0],
      contractNumber    |-> [i \in 1 .. 4 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      orderNumber       |-> [i \in 1 .. 8 |-> 0],
      quantityRemaining |-> [i \in 1 .. 4 |-> 0],
      tradeType         |-> [i \in 1 .. 1 |-> 0],
      matchNumber       |-> [i \in 1 .. 4 |-> 0],
      executedQuantity  |-> [i \in 1 .. 4 |-> 0],
      tradePrice        |-> [i \in 1 .. 4 |-> 0] ]

(* Order Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedMessage ==
    { ZeroOrderExecutedMessage }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.contractNumber = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.quantityRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.matchNumber = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.tradePrice = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Executed With Price Message: 47 bytes                             *)
(***************************************************************************)

OrderExecutedWithPriceMessage ==
    [ nanoseconds             : Sample(4),
      tradeDate               : Sample(2),
      contractNumber          : Sample(4),
      buyingOrderNumber       : Sample(8),
      buyerQuantityRemaining  : Sample(4),
      sellingOrderNumber      : Sample(8),
      sellerQuantityRemaining : Sample(4),
      tradeType               : Sample(1),
      matchNumber             : Sample(4),
      executedQuantity        : Sample(4),
      tradePrice              : Sample(4) ]

EncodeOrderExecutedWithPriceMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.contractNumber
        \o message.buyingOrderNumber
        \o message.buyerQuantityRemaining
        \o message.sellingOrderNumber
        \o message.sellerQuantityRemaining
        \o message.tradeType
        \o message.matchNumber
        \o message.executedQuantity
        \o message.tradePrice

DecodeOrderExecutedWithPriceMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET contractNumber == ReadBytes(tradeDate.rest, 4) IN IF ~contractNumber.ok THEN Fail ELSE
    LET buyingOrderNumber == ReadBytes(contractNumber.rest, 8) IN IF ~buyingOrderNumber.ok THEN Fail ELSE
    LET buyerQuantityRemaining == ReadBytes(buyingOrderNumber.rest, 4) IN IF ~buyerQuantityRemaining.ok THEN Fail ELSE
    LET sellingOrderNumber == ReadBytes(buyerQuantityRemaining.rest, 8) IN IF ~sellingOrderNumber.ok THEN Fail ELSE
    LET sellerQuantityRemaining == ReadBytes(sellingOrderNumber.rest, 4) IN IF ~sellerQuantityRemaining.ok THEN Fail ELSE
    LET tradeType == ReadBytes(sellerQuantityRemaining.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(tradeType.rest, 4) IN IF ~matchNumber.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(matchNumber.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(executedQuantity.rest, 4) IN IF ~tradePrice.ok THEN Fail ELSE
    Ok([ nanoseconds             |-> nanoseconds.value,
         tradeDate               |-> tradeDate.value,
         contractNumber          |-> contractNumber.value,
         buyingOrderNumber       |-> buyingOrderNumber.value,
         buyerQuantityRemaining  |-> buyerQuantityRemaining.value,
         sellingOrderNumber      |-> sellingOrderNumber.value,
         sellerQuantityRemaining |-> sellerQuantityRemaining.value,
         tradeType               |-> tradeType.value,
         matchNumber             |-> matchNumber.value,
         executedQuantity        |-> executedQuantity.value,
         tradePrice              |-> tradePrice.value ], tradePrice.rest)

ZeroOrderExecutedWithPriceMessage ==
    [ nanoseconds             |-> [i \in 1 .. 4 |-> 0],
      tradeDate               |-> [i \in 1 .. 2 |-> 0],
      contractNumber          |-> [i \in 1 .. 4 |-> 0],
      buyingOrderNumber       |-> [i \in 1 .. 8 |-> 0],
      buyerQuantityRemaining  |-> [i \in 1 .. 4 |-> 0],
      sellingOrderNumber      |-> [i \in 1 .. 8 |-> 0],
      sellerQuantityRemaining |-> [i \in 1 .. 4 |-> 0],
      tradeType               |-> [i \in 1 .. 1 |-> 0],
      matchNumber             |-> [i \in 1 .. 4 |-> 0],
      executedQuantity        |-> [i \in 1 .. 4 |-> 0],
      tradePrice              |-> [i \in 1 .. 4 |-> 0] ]

(* Order Executed With Price Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedWithPriceMessage ==
    { ZeroOrderExecutedWithPriceMessage }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.contractNumber = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.buyingOrderNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.buyerQuantityRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.sellingOrderNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.sellerQuantityRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.matchNumber = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.tradePrice = one] : one \in Sample(4) }

(***************************************************************************)
(* Spread Executed Message: 46 bytes                                       *)
(***************************************************************************)

SpreadExecutedMessage ==
    [ nanoseconds          : Sample(4),
      tradeDate            : Sample(2),
      contractNumber       : Sample(4),
      side                 : Sample(1),
      orderNumber          : Sample(8),
      quantityRemaining    : Sample(4),
      tradeType            : Sample(1),
      matchNumber          : Sample(4),
      executedQuantity     : Sample(4),
      tradePrice           : Sample(4),
      tradedContractNumber : Sample(4),
      spreadTradePrice     : Sample(4),
      tradeSideOfLeg       : Sample(1),
      printable            : Sample(1) ]

EncodeSpreadExecutedMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.contractNumber
        \o message.side
        \o message.orderNumber
        \o message.quantityRemaining
        \o message.tradeType
        \o message.matchNumber
        \o message.executedQuantity
        \o message.tradePrice
        \o message.tradedContractNumber
        \o message.spreadTradePrice
        \o message.tradeSideOfLeg
        \o message.printable

DecodeSpreadExecutedMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET contractNumber == ReadBytes(tradeDate.rest, 4) IN IF ~contractNumber.ok THEN Fail ELSE
    LET side == ReadBytes(contractNumber.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(side.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET quantityRemaining == ReadBytes(orderNumber.rest, 4) IN IF ~quantityRemaining.ok THEN Fail ELSE
    LET tradeType == ReadBytes(quantityRemaining.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(tradeType.rest, 4) IN IF ~matchNumber.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(matchNumber.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(executedQuantity.rest, 4) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradedContractNumber == ReadBytes(tradePrice.rest, 4) IN IF ~tradedContractNumber.ok THEN Fail ELSE
    LET spreadTradePrice == ReadBytes(tradedContractNumber.rest, 4) IN IF ~spreadTradePrice.ok THEN Fail ELSE
    LET tradeSideOfLeg == ReadBytes(spreadTradePrice.rest, 1) IN IF ~tradeSideOfLeg.ok THEN Fail ELSE
    LET printable == ReadBytes(tradeSideOfLeg.rest, 1) IN IF ~printable.ok THEN Fail ELSE
    Ok([ nanoseconds          |-> nanoseconds.value,
         tradeDate            |-> tradeDate.value,
         contractNumber       |-> contractNumber.value,
         side                 |-> side.value,
         orderNumber          |-> orderNumber.value,
         quantityRemaining    |-> quantityRemaining.value,
         tradeType            |-> tradeType.value,
         matchNumber          |-> matchNumber.value,
         executedQuantity     |-> executedQuantity.value,
         tradePrice           |-> tradePrice.value,
         tradedContractNumber |-> tradedContractNumber.value,
         spreadTradePrice     |-> spreadTradePrice.value,
         tradeSideOfLeg       |-> tradeSideOfLeg.value,
         printable            |-> printable.value ], printable.rest)

ZeroSpreadExecutedMessage ==
    [ nanoseconds          |-> [i \in 1 .. 4 |-> 0],
      tradeDate            |-> [i \in 1 .. 2 |-> 0],
      contractNumber       |-> [i \in 1 .. 4 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      orderNumber          |-> [i \in 1 .. 8 |-> 0],
      quantityRemaining    |-> [i \in 1 .. 4 |-> 0],
      tradeType            |-> [i \in 1 .. 1 |-> 0],
      matchNumber          |-> [i \in 1 .. 4 |-> 0],
      executedQuantity     |-> [i \in 1 .. 4 |-> 0],
      tradePrice           |-> [i \in 1 .. 4 |-> 0],
      tradedContractNumber |-> [i \in 1 .. 4 |-> 0],
      spreadTradePrice     |-> [i \in 1 .. 4 |-> 0],
      tradeSideOfLeg       |-> [i \in 1 .. 1 |-> 0],
      printable            |-> [i \in 1 .. 1 |-> 0] ]

(* Spread Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedSpreadExecutedMessage ==
    { ZeroSpreadExecutedMessage }
        \cup { [ZeroSpreadExecutedMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSpreadExecutedMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroSpreadExecutedMessage EXCEPT !.contractNumber = one] : one \in Sample(4) }
        \cup { [ZeroSpreadExecutedMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroSpreadExecutedMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroSpreadExecutedMessage EXCEPT !.quantityRemaining = one] : one \in Sample(4) }
        \cup { [ZeroSpreadExecutedMessage EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroSpreadExecutedMessage EXCEPT !.matchNumber = one] : one \in Sample(4) }
        \cup { [ZeroSpreadExecutedMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroSpreadExecutedMessage EXCEPT !.tradePrice = one] : one \in Sample(4) }
        \cup { [ZeroSpreadExecutedMessage EXCEPT !.tradedContractNumber = one] : one \in Sample(4) }
        \cup { [ZeroSpreadExecutedMessage EXCEPT !.spreadTradePrice = one] : one \in Sample(4) }
        \cup { [ZeroSpreadExecutedMessage EXCEPT !.tradeSideOfLeg = one] : one \in Sample(1) }
        \cup { [ZeroSpreadExecutedMessage EXCEPT !.printable = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Spread Execution Chain Message: 62 bytes                          *)
(***************************************************************************)

TradeSpreadExecutionChainMessage ==
    [ nanoseconds             : Sample(4),
      tradeDate               : Sample(2),
      buyer                   : Sample(4),
      sideOfBuyer             : Sample(1),
      buyerOrderNumber        : Sample(8),
      buyerQuantityRemaining  : Sample(4),
      sellerContractNumber    : Sample(4),
      sideOfSeller            : Sample(1),
      sellingOrderNumber      : Sample(8),
      sellerQuantityRemaining : Sample(4),
      tradeType               : Sample(1),
      matchNumber             : Sample(4),
      executedQuantity        : Sample(4),
      tradePrice              : Sample(4),
      tradedContractNumber    : Sample(4),
      spreadTradePrice        : Sample(4),
      printable               : Sample(1) ]

EncodeTradeSpreadExecutionChainMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.buyer
        \o message.sideOfBuyer
        \o message.buyerOrderNumber
        \o message.buyerQuantityRemaining
        \o message.sellerContractNumber
        \o message.sideOfSeller
        \o message.sellingOrderNumber
        \o message.sellerQuantityRemaining
        \o message.tradeType
        \o message.matchNumber
        \o message.executedQuantity
        \o message.tradePrice
        \o message.tradedContractNumber
        \o message.spreadTradePrice
        \o message.printable

DecodeTradeSpreadExecutionChainMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET buyer == ReadBytes(tradeDate.rest, 4) IN IF ~buyer.ok THEN Fail ELSE
    LET sideOfBuyer == ReadBytes(buyer.rest, 1) IN IF ~sideOfBuyer.ok THEN Fail ELSE
    LET buyerOrderNumber == ReadBytes(sideOfBuyer.rest, 8) IN IF ~buyerOrderNumber.ok THEN Fail ELSE
    LET buyerQuantityRemaining == ReadBytes(buyerOrderNumber.rest, 4) IN IF ~buyerQuantityRemaining.ok THEN Fail ELSE
    LET sellerContractNumber == ReadBytes(buyerQuantityRemaining.rest, 4) IN IF ~sellerContractNumber.ok THEN Fail ELSE
    LET sideOfSeller == ReadBytes(sellerContractNumber.rest, 1) IN IF ~sideOfSeller.ok THEN Fail ELSE
    LET sellingOrderNumber == ReadBytes(sideOfSeller.rest, 8) IN IF ~sellingOrderNumber.ok THEN Fail ELSE
    LET sellerQuantityRemaining == ReadBytes(sellingOrderNumber.rest, 4) IN IF ~sellerQuantityRemaining.ok THEN Fail ELSE
    LET tradeType == ReadBytes(sellerQuantityRemaining.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(tradeType.rest, 4) IN IF ~matchNumber.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(matchNumber.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(executedQuantity.rest, 4) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradedContractNumber == ReadBytes(tradePrice.rest, 4) IN IF ~tradedContractNumber.ok THEN Fail ELSE
    LET spreadTradePrice == ReadBytes(tradedContractNumber.rest, 4) IN IF ~spreadTradePrice.ok THEN Fail ELSE
    LET printable == ReadBytes(spreadTradePrice.rest, 1) IN IF ~printable.ok THEN Fail ELSE
    Ok([ nanoseconds             |-> nanoseconds.value,
         tradeDate               |-> tradeDate.value,
         buyer                   |-> buyer.value,
         sideOfBuyer             |-> sideOfBuyer.value,
         buyerOrderNumber        |-> buyerOrderNumber.value,
         buyerQuantityRemaining  |-> buyerQuantityRemaining.value,
         sellerContractNumber    |-> sellerContractNumber.value,
         sideOfSeller            |-> sideOfSeller.value,
         sellingOrderNumber      |-> sellingOrderNumber.value,
         sellerQuantityRemaining |-> sellerQuantityRemaining.value,
         tradeType               |-> tradeType.value,
         matchNumber             |-> matchNumber.value,
         executedQuantity        |-> executedQuantity.value,
         tradePrice              |-> tradePrice.value,
         tradedContractNumber    |-> tradedContractNumber.value,
         spreadTradePrice        |-> spreadTradePrice.value,
         printable               |-> printable.value ], printable.rest)

ZeroTradeSpreadExecutionChainMessage ==
    [ nanoseconds             |-> [i \in 1 .. 4 |-> 0],
      tradeDate               |-> [i \in 1 .. 2 |-> 0],
      buyer                   |-> [i \in 1 .. 4 |-> 0],
      sideOfBuyer             |-> [i \in 1 .. 1 |-> 0],
      buyerOrderNumber        |-> [i \in 1 .. 8 |-> 0],
      buyerQuantityRemaining  |-> [i \in 1 .. 4 |-> 0],
      sellerContractNumber    |-> [i \in 1 .. 4 |-> 0],
      sideOfSeller            |-> [i \in 1 .. 1 |-> 0],
      sellingOrderNumber      |-> [i \in 1 .. 8 |-> 0],
      sellerQuantityRemaining |-> [i \in 1 .. 4 |-> 0],
      tradeType               |-> [i \in 1 .. 1 |-> 0],
      matchNumber             |-> [i \in 1 .. 4 |-> 0],
      executedQuantity        |-> [i \in 1 .. 4 |-> 0],
      tradePrice              |-> [i \in 1 .. 4 |-> 0],
      tradedContractNumber    |-> [i \in 1 .. 4 |-> 0],
      spreadTradePrice        |-> [i \in 1 .. 4 |-> 0],
      printable               |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Spread Execution Chain Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeSpreadExecutionChainMessage ==
    { ZeroTradeSpreadExecutionChainMessage }
        \cup { [ZeroTradeSpreadExecutionChainMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroTradeSpreadExecutionChainMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroTradeSpreadExecutionChainMessage EXCEPT !.buyer = one] : one \in Sample(4) }
        \cup { [ZeroTradeSpreadExecutionChainMessage EXCEPT !.sideOfBuyer = one] : one \in Sample(1) }
        \cup { [ZeroTradeSpreadExecutionChainMessage EXCEPT !.buyerOrderNumber = one] : one \in Sample(8) }
        \cup { [ZeroTradeSpreadExecutionChainMessage EXCEPT !.buyerQuantityRemaining = one] : one \in Sample(4) }
        \cup { [ZeroTradeSpreadExecutionChainMessage EXCEPT !.sellerContractNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeSpreadExecutionChainMessage EXCEPT !.sideOfSeller = one] : one \in Sample(1) }
        \cup { [ZeroTradeSpreadExecutionChainMessage EXCEPT !.sellingOrderNumber = one] : one \in Sample(8) }
        \cup { [ZeroTradeSpreadExecutionChainMessage EXCEPT !.sellerQuantityRemaining = one] : one \in Sample(4) }
        \cup { [ZeroTradeSpreadExecutionChainMessage EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroTradeSpreadExecutionChainMessage EXCEPT !.matchNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeSpreadExecutionChainMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroTradeSpreadExecutionChainMessage EXCEPT !.tradePrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeSpreadExecutionChainMessage EXCEPT !.tradedContractNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeSpreadExecutionChainMessage EXCEPT !.spreadTradePrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeSpreadExecutionChainMessage EXCEPT !.printable = one] : one \in Sample(1) }

(***************************************************************************)
(* Custom Market Executed Message: 37 bytes                                *)
(***************************************************************************)

CustomMarketExecutedMessage ==
    [ nanoseconds          : Sample(4),
      tradeDate            : Sample(2),
      orderNumber          : Sample(8),
      quantityRemaining    : Sample(4),
      tradeType            : Sample(1),
      matchNumber          : Sample(4),
      executedQuantity     : Sample(4),
      tradePrice           : Sample(4),
      tradedContractNumber : Sample(4),
      tradeSideOfLeg       : Sample(1),
      printable            : Sample(1) ]

EncodeCustomMarketExecutedMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.orderNumber
        \o message.quantityRemaining
        \o message.tradeType
        \o message.matchNumber
        \o message.executedQuantity
        \o message.tradePrice
        \o message.tradedContractNumber
        \o message.tradeSideOfLeg
        \o message.printable

DecodeCustomMarketExecutedMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(tradeDate.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET quantityRemaining == ReadBytes(orderNumber.rest, 4) IN IF ~quantityRemaining.ok THEN Fail ELSE
    LET tradeType == ReadBytes(quantityRemaining.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(tradeType.rest, 4) IN IF ~matchNumber.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(matchNumber.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(executedQuantity.rest, 4) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradedContractNumber == ReadBytes(tradePrice.rest, 4) IN IF ~tradedContractNumber.ok THEN Fail ELSE
    LET tradeSideOfLeg == ReadBytes(tradedContractNumber.rest, 1) IN IF ~tradeSideOfLeg.ok THEN Fail ELSE
    LET printable == ReadBytes(tradeSideOfLeg.rest, 1) IN IF ~printable.ok THEN Fail ELSE
    Ok([ nanoseconds          |-> nanoseconds.value,
         tradeDate            |-> tradeDate.value,
         orderNumber          |-> orderNumber.value,
         quantityRemaining    |-> quantityRemaining.value,
         tradeType            |-> tradeType.value,
         matchNumber          |-> matchNumber.value,
         executedQuantity     |-> executedQuantity.value,
         tradePrice           |-> tradePrice.value,
         tradedContractNumber |-> tradedContractNumber.value,
         tradeSideOfLeg       |-> tradeSideOfLeg.value,
         printable            |-> printable.value ], printable.rest)

ZeroCustomMarketExecutedMessage ==
    [ nanoseconds          |-> [i \in 1 .. 4 |-> 0],
      tradeDate            |-> [i \in 1 .. 2 |-> 0],
      orderNumber          |-> [i \in 1 .. 8 |-> 0],
      quantityRemaining    |-> [i \in 1 .. 4 |-> 0],
      tradeType            |-> [i \in 1 .. 1 |-> 0],
      matchNumber          |-> [i \in 1 .. 4 |-> 0],
      executedQuantity     |-> [i \in 1 .. 4 |-> 0],
      tradePrice           |-> [i \in 1 .. 4 |-> 0],
      tradedContractNumber |-> [i \in 1 .. 4 |-> 0],
      tradeSideOfLeg       |-> [i \in 1 .. 1 |-> 0],
      printable            |-> [i \in 1 .. 1 |-> 0] ]

(* Custom Market Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedCustomMarketExecutedMessage ==
    { ZeroCustomMarketExecutedMessage }
        \cup { [ZeroCustomMarketExecutedMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroCustomMarketExecutedMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroCustomMarketExecutedMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroCustomMarketExecutedMessage EXCEPT !.quantityRemaining = one] : one \in Sample(4) }
        \cup { [ZeroCustomMarketExecutedMessage EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroCustomMarketExecutedMessage EXCEPT !.matchNumber = one] : one \in Sample(4) }
        \cup { [ZeroCustomMarketExecutedMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroCustomMarketExecutedMessage EXCEPT !.tradePrice = one] : one \in Sample(4) }
        \cup { [ZeroCustomMarketExecutedMessage EXCEPT !.tradedContractNumber = one] : one \in Sample(4) }
        \cup { [ZeroCustomMarketExecutedMessage EXCEPT !.tradeSideOfLeg = one] : one \in Sample(1) }
        \cup { [ZeroCustomMarketExecutedMessage EXCEPT !.printable = one] : one \in Sample(1) }

(***************************************************************************)
(* Custom Market Trade Message: 54 bytes                                   *)
(***************************************************************************)

CustomMarketTradeMessage ==
    [ nanoseconds                   : Sample(4),
      tradeDate                     : Sample(2),
      contractNumber                : Sample(4),
      side                          : Sample(1),
      orderNumber                   : Sample(8),
      quantityRemaining             : Sample(4),
      customMarketOrderNumber       : Sample(8),
      customMarketQuantityRemaining : Sample(4),
      tradeType                     : Sample(1),
      matchNumber                   : Sample(4),
      executedQuantity              : Sample(4),
      tradePrice                    : Sample(4),
      tradedContractNumber          : Sample(4),
      tradeSideOfNonCustomOrder     : Sample(1),
      printable                     : Sample(1) ]

EncodeCustomMarketTradeMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.contractNumber
        \o message.side
        \o message.orderNumber
        \o message.quantityRemaining
        \o message.customMarketOrderNumber
        \o message.customMarketQuantityRemaining
        \o message.tradeType
        \o message.matchNumber
        \o message.executedQuantity
        \o message.tradePrice
        \o message.tradedContractNumber
        \o message.tradeSideOfNonCustomOrder
        \o message.printable

DecodeCustomMarketTradeMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET contractNumber == ReadBytes(tradeDate.rest, 4) IN IF ~contractNumber.ok THEN Fail ELSE
    LET side == ReadBytes(contractNumber.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(side.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET quantityRemaining == ReadBytes(orderNumber.rest, 4) IN IF ~quantityRemaining.ok THEN Fail ELSE
    LET customMarketOrderNumber == ReadBytes(quantityRemaining.rest, 8) IN IF ~customMarketOrderNumber.ok THEN Fail ELSE
    LET customMarketQuantityRemaining == ReadBytes(customMarketOrderNumber.rest, 4) IN IF ~customMarketQuantityRemaining.ok THEN Fail ELSE
    LET tradeType == ReadBytes(customMarketQuantityRemaining.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(tradeType.rest, 4) IN IF ~matchNumber.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(matchNumber.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(executedQuantity.rest, 4) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradedContractNumber == ReadBytes(tradePrice.rest, 4) IN IF ~tradedContractNumber.ok THEN Fail ELSE
    LET tradeSideOfNonCustomOrder == ReadBytes(tradedContractNumber.rest, 1) IN IF ~tradeSideOfNonCustomOrder.ok THEN Fail ELSE
    LET printable == ReadBytes(tradeSideOfNonCustomOrder.rest, 1) IN IF ~printable.ok THEN Fail ELSE
    Ok([ nanoseconds                   |-> nanoseconds.value,
         tradeDate                     |-> tradeDate.value,
         contractNumber                |-> contractNumber.value,
         side                          |-> side.value,
         orderNumber                   |-> orderNumber.value,
         quantityRemaining             |-> quantityRemaining.value,
         customMarketOrderNumber       |-> customMarketOrderNumber.value,
         customMarketQuantityRemaining |-> customMarketQuantityRemaining.value,
         tradeType                     |-> tradeType.value,
         matchNumber                   |-> matchNumber.value,
         executedQuantity              |-> executedQuantity.value,
         tradePrice                    |-> tradePrice.value,
         tradedContractNumber          |-> tradedContractNumber.value,
         tradeSideOfNonCustomOrder     |-> tradeSideOfNonCustomOrder.value,
         printable                     |-> printable.value ], printable.rest)

ZeroCustomMarketTradeMessage ==
    [ nanoseconds                   |-> [i \in 1 .. 4 |-> 0],
      tradeDate                     |-> [i \in 1 .. 2 |-> 0],
      contractNumber                |-> [i \in 1 .. 4 |-> 0],
      side                          |-> [i \in 1 .. 1 |-> 0],
      orderNumber                   |-> [i \in 1 .. 8 |-> 0],
      quantityRemaining             |-> [i \in 1 .. 4 |-> 0],
      customMarketOrderNumber       |-> [i \in 1 .. 8 |-> 0],
      customMarketQuantityRemaining |-> [i \in 1 .. 4 |-> 0],
      tradeType                     |-> [i \in 1 .. 1 |-> 0],
      matchNumber                   |-> [i \in 1 .. 4 |-> 0],
      executedQuantity              |-> [i \in 1 .. 4 |-> 0],
      tradePrice                    |-> [i \in 1 .. 4 |-> 0],
      tradedContractNumber          |-> [i \in 1 .. 4 |-> 0],
      tradeSideOfNonCustomOrder     |-> [i \in 1 .. 1 |-> 0],
      printable                     |-> [i \in 1 .. 1 |-> 0] ]

(* Custom Market Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedCustomMarketTradeMessage ==
    { ZeroCustomMarketTradeMessage }
        \cup { [ZeroCustomMarketTradeMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroCustomMarketTradeMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroCustomMarketTradeMessage EXCEPT !.contractNumber = one] : one \in Sample(4) }
        \cup { [ZeroCustomMarketTradeMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroCustomMarketTradeMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroCustomMarketTradeMessage EXCEPT !.quantityRemaining = one] : one \in Sample(4) }
        \cup { [ZeroCustomMarketTradeMessage EXCEPT !.customMarketOrderNumber = one] : one \in Sample(8) }
        \cup { [ZeroCustomMarketTradeMessage EXCEPT !.customMarketQuantityRemaining = one] : one \in Sample(4) }
        \cup { [ZeroCustomMarketTradeMessage EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroCustomMarketTradeMessage EXCEPT !.matchNumber = one] : one \in Sample(4) }
        \cup { [ZeroCustomMarketTradeMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroCustomMarketTradeMessage EXCEPT !.tradePrice = one] : one \in Sample(4) }
        \cup { [ZeroCustomMarketTradeMessage EXCEPT !.tradedContractNumber = one] : one \in Sample(4) }
        \cup { [ZeroCustomMarketTradeMessage EXCEPT !.tradeSideOfNonCustomOrder = one] : one \in Sample(1) }
        \cup { [ZeroCustomMarketTradeMessage EXCEPT !.printable = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Cancellation Message: 10 bytes                                    *)
(***************************************************************************)

TradeCancellationMessage ==
    [ nanoseconds : Sample(4),
      tradeDate   : Sample(2),
      matchNumber : Sample(4) ]

EncodeTradeCancellationMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.matchNumber

DecodeTradeCancellationMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(tradeDate.rest, 4) IN IF ~matchNumber.ok THEN Fail ELSE
    Ok([ nanoseconds |-> nanoseconds.value,
         tradeDate   |-> tradeDate.value,
         matchNumber |-> matchNumber.value ], matchNumber.rest)

ZeroTradeCancellationMessage ==
    [ nanoseconds |-> [i \in 1 .. 4 |-> 0],
      tradeDate   |-> [i \in 1 .. 2 |-> 0],
      matchNumber |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Cancellation Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCancellationMessage ==
    { ZeroTradeCancellationMessage }
        \cup { [ZeroTradeCancellationMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancellationMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroTradeCancellationMessage EXCEPT !.matchNumber = one] : one \in Sample(4) }

(***************************************************************************)
(* Equilibrium Price Auction Info Message: 30 bytes                        *)
(***************************************************************************)

EquilibriumPriceAuctionInfoMessage ==
    [ nanoseconds      : Sample(4),
      tradeDate        : Sample(2),
      contractNumber   : Sample(4),
      equilibriumPrice : Sample(4),
      bestBidPrice     : Sample(4),
      bestAskPrice     : Sample(4),
      bestBidQuantity  : Sample(4),
      bestAskQuantity  : Sample(4) ]

EncodeEquilibriumPriceAuctionInfoMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.contractNumber
        \o message.equilibriumPrice
        \o message.bestBidPrice
        \o message.bestAskPrice
        \o message.bestBidQuantity
        \o message.bestAskQuantity

DecodeEquilibriumPriceAuctionInfoMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET contractNumber == ReadBytes(tradeDate.rest, 4) IN IF ~contractNumber.ok THEN Fail ELSE
    LET equilibriumPrice == ReadBytes(contractNumber.rest, 4) IN IF ~equilibriumPrice.ok THEN Fail ELSE
    LET bestBidPrice == ReadBytes(equilibriumPrice.rest, 4) IN IF ~bestBidPrice.ok THEN Fail ELSE
    LET bestAskPrice == ReadBytes(bestBidPrice.rest, 4) IN IF ~bestAskPrice.ok THEN Fail ELSE
    LET bestBidQuantity == ReadBytes(bestAskPrice.rest, 4) IN IF ~bestBidQuantity.ok THEN Fail ELSE
    LET bestAskQuantity == ReadBytes(bestBidQuantity.rest, 4) IN IF ~bestAskQuantity.ok THEN Fail ELSE
    Ok([ nanoseconds      |-> nanoseconds.value,
         tradeDate        |-> tradeDate.value,
         contractNumber   |-> contractNumber.value,
         equilibriumPrice |-> equilibriumPrice.value,
         bestBidPrice     |-> bestBidPrice.value,
         bestAskPrice     |-> bestAskPrice.value,
         bestBidQuantity  |-> bestBidQuantity.value,
         bestAskQuantity  |-> bestAskQuantity.value ], bestAskQuantity.rest)

ZeroEquilibriumPriceAuctionInfoMessage ==
    [ nanoseconds      |-> [i \in 1 .. 4 |-> 0],
      tradeDate        |-> [i \in 1 .. 2 |-> 0],
      contractNumber   |-> [i \in 1 .. 4 |-> 0],
      equilibriumPrice |-> [i \in 1 .. 4 |-> 0],
      bestBidPrice     |-> [i \in 1 .. 4 |-> 0],
      bestAskPrice     |-> [i \in 1 .. 4 |-> 0],
      bestBidQuantity  |-> [i \in 1 .. 4 |-> 0],
      bestAskQuantity  |-> [i \in 1 .. 4 |-> 0] ]

(* Equilibrium Price Auction Info Message at zero, then each field in turn at the values it is checked at *)
CheckedEquilibriumPriceAuctionInfoMessage ==
    { ZeroEquilibriumPriceAuctionInfoMessage }
        \cup { [ZeroEquilibriumPriceAuctionInfoMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroEquilibriumPriceAuctionInfoMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroEquilibriumPriceAuctionInfoMessage EXCEPT !.contractNumber = one] : one \in Sample(4) }
        \cup { [ZeroEquilibriumPriceAuctionInfoMessage EXCEPT !.equilibriumPrice = one] : one \in Sample(4) }
        \cup { [ZeroEquilibriumPriceAuctionInfoMessage EXCEPT !.bestBidPrice = one] : one \in Sample(4) }
        \cup { [ZeroEquilibriumPriceAuctionInfoMessage EXCEPT !.bestAskPrice = one] : one \in Sample(4) }
        \cup { [ZeroEquilibriumPriceAuctionInfoMessage EXCEPT !.bestBidQuantity = one] : one \in Sample(4) }
        \cup { [ZeroEquilibriumPriceAuctionInfoMessage EXCEPT !.bestAskQuantity = one] : one \in Sample(4) }

(***************************************************************************)
(* Open High Low Last Trade Adjustment Message: 39 bytes                   *)
(***************************************************************************)

OpenHighLowLastTradeAdjustmentMessage ==
    [ nanoseconds       : Sample(4),
      tradeDate         : Sample(2),
      contractNumber    : Sample(4),
      openingTrade      : Sample(4),
      highestTrade      : Sample(4),
      lowestTrade       : Sample(4),
      lastTrade         : Sample(4),
      lastVolume        : Sample(4),
      totalTradedVolume : Sample(4),
      totalTrades       : Sample(4),
      marketUpdates     : Sample(1) ]

EncodeOpenHighLowLastTradeAdjustmentMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.contractNumber
        \o message.openingTrade
        \o message.highestTrade
        \o message.lowestTrade
        \o message.lastTrade
        \o message.lastVolume
        \o message.totalTradedVolume
        \o message.totalTrades
        \o message.marketUpdates

DecodeOpenHighLowLastTradeAdjustmentMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET contractNumber == ReadBytes(tradeDate.rest, 4) IN IF ~contractNumber.ok THEN Fail ELSE
    LET openingTrade == ReadBytes(contractNumber.rest, 4) IN IF ~openingTrade.ok THEN Fail ELSE
    LET highestTrade == ReadBytes(openingTrade.rest, 4) IN IF ~highestTrade.ok THEN Fail ELSE
    LET lowestTrade == ReadBytes(highestTrade.rest, 4) IN IF ~lowestTrade.ok THEN Fail ELSE
    LET lastTrade == ReadBytes(lowestTrade.rest, 4) IN IF ~lastTrade.ok THEN Fail ELSE
    LET lastVolume == ReadBytes(lastTrade.rest, 4) IN IF ~lastVolume.ok THEN Fail ELSE
    LET totalTradedVolume == ReadBytes(lastVolume.rest, 4) IN IF ~totalTradedVolume.ok THEN Fail ELSE
    LET totalTrades == ReadBytes(totalTradedVolume.rest, 4) IN IF ~totalTrades.ok THEN Fail ELSE
    LET marketUpdates == ReadBytes(totalTrades.rest, 1) IN IF ~marketUpdates.ok THEN Fail ELSE
    Ok([ nanoseconds       |-> nanoseconds.value,
         tradeDate         |-> tradeDate.value,
         contractNumber    |-> contractNumber.value,
         openingTrade      |-> openingTrade.value,
         highestTrade      |-> highestTrade.value,
         lowestTrade       |-> lowestTrade.value,
         lastTrade         |-> lastTrade.value,
         lastVolume        |-> lastVolume.value,
         totalTradedVolume |-> totalTradedVolume.value,
         totalTrades       |-> totalTrades.value,
         marketUpdates     |-> marketUpdates.value ], marketUpdates.rest)

ZeroOpenHighLowLastTradeAdjustmentMessage ==
    [ nanoseconds       |-> [i \in 1 .. 4 |-> 0],
      tradeDate         |-> [i \in 1 .. 2 |-> 0],
      contractNumber    |-> [i \in 1 .. 4 |-> 0],
      openingTrade      |-> [i \in 1 .. 4 |-> 0],
      highestTrade      |-> [i \in 1 .. 4 |-> 0],
      lowestTrade       |-> [i \in 1 .. 4 |-> 0],
      lastTrade         |-> [i \in 1 .. 4 |-> 0],
      lastVolume        |-> [i \in 1 .. 4 |-> 0],
      totalTradedVolume |-> [i \in 1 .. 4 |-> 0],
      totalTrades       |-> [i \in 1 .. 4 |-> 0],
      marketUpdates     |-> [i \in 1 .. 1 |-> 0] ]

(* Open High Low Last Trade Adjustment Message at zero, then each field in turn at the values it is checked at *)
CheckedOpenHighLowLastTradeAdjustmentMessage ==
    { ZeroOpenHighLowLastTradeAdjustmentMessage }
        \cup { [ZeroOpenHighLowLastTradeAdjustmentMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOpenHighLowLastTradeAdjustmentMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroOpenHighLowLastTradeAdjustmentMessage EXCEPT !.contractNumber = one] : one \in Sample(4) }
        \cup { [ZeroOpenHighLowLastTradeAdjustmentMessage EXCEPT !.openingTrade = one] : one \in Sample(4) }
        \cup { [ZeroOpenHighLowLastTradeAdjustmentMessage EXCEPT !.highestTrade = one] : one \in Sample(4) }
        \cup { [ZeroOpenHighLowLastTradeAdjustmentMessage EXCEPT !.lowestTrade = one] : one \in Sample(4) }
        \cup { [ZeroOpenHighLowLastTradeAdjustmentMessage EXCEPT !.lastTrade = one] : one \in Sample(4) }
        \cup { [ZeroOpenHighLowLastTradeAdjustmentMessage EXCEPT !.lastVolume = one] : one \in Sample(4) }
        \cup { [ZeroOpenHighLowLastTradeAdjustmentMessage EXCEPT !.totalTradedVolume = one] : one \in Sample(4) }
        \cup { [ZeroOpenHighLowLastTradeAdjustmentMessage EXCEPT !.totalTrades = one] : one \in Sample(4) }
        \cup { [ZeroOpenHighLowLastTradeAdjustmentMessage EXCEPT !.marketUpdates = one] : one \in Sample(1) }

(***************************************************************************)
(* Market Settlement Message: 19 bytes                                     *)
(***************************************************************************)

MarketSettlementMessage ==
    [ nanoseconds     : Sample(4),
      tradeDate       : Sample(2),
      contractNumber  : Sample(4),
      settlementPrice : Sample(4),
      volatility      : Sample(4),
      settlementType  : Sample(1) ]

EncodeMarketSettlementMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.contractNumber
        \o message.settlementPrice
        \o message.volatility
        \o message.settlementType

DecodeMarketSettlementMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET contractNumber == ReadBytes(tradeDate.rest, 4) IN IF ~contractNumber.ok THEN Fail ELSE
    LET settlementPrice == ReadBytes(contractNumber.rest, 4) IN IF ~settlementPrice.ok THEN Fail ELSE
    LET volatility == ReadBytes(settlementPrice.rest, 4) IN IF ~volatility.ok THEN Fail ELSE
    LET settlementType == ReadBytes(volatility.rest, 1) IN IF ~settlementType.ok THEN Fail ELSE
    Ok([ nanoseconds     |-> nanoseconds.value,
         tradeDate       |-> tradeDate.value,
         contractNumber  |-> contractNumber.value,
         settlementPrice |-> settlementPrice.value,
         volatility      |-> volatility.value,
         settlementType  |-> settlementType.value ], settlementType.rest)

ZeroMarketSettlementMessage ==
    [ nanoseconds     |-> [i \in 1 .. 4 |-> 0],
      tradeDate       |-> [i \in 1 .. 2 |-> 0],
      contractNumber  |-> [i \in 1 .. 4 |-> 0],
      settlementPrice |-> [i \in 1 .. 4 |-> 0],
      volatility      |-> [i \in 1 .. 4 |-> 0],
      settlementType  |-> [i \in 1 .. 1 |-> 0] ]

(* Market Settlement Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketSettlementMessage ==
    { ZeroMarketSettlementMessage }
        \cup { [ZeroMarketSettlementMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroMarketSettlementMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroMarketSettlementMessage EXCEPT !.contractNumber = one] : one \in Sample(4) }
        \cup { [ZeroMarketSettlementMessage EXCEPT !.settlementPrice = one] : one \in Sample(4) }
        \cup { [ZeroMarketSettlementMessage EXCEPT !.volatility = one] : one \in Sample(4) }
        \cup { [ZeroMarketSettlementMessage EXCEPT !.settlementType = one] : one \in Sample(1) }

(***************************************************************************)
(* Ad Hoc Text Message: 112 bytes                                          *)
(***************************************************************************)

AdHocTextMessage ==
    [ nanoseconds : Sample(4),
      tradeDate   : Sample(2),
      sourceId    : Sample(6),
      textMessage : Sample(100) ]

EncodeAdHocTextMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.sourceId
        \o message.textMessage

DecodeAdHocTextMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET sourceId == ReadBytes(tradeDate.rest, 6) IN IF ~sourceId.ok THEN Fail ELSE
    LET textMessage == ReadBytes(sourceId.rest, 100) IN IF ~textMessage.ok THEN Fail ELSE
    Ok([ nanoseconds |-> nanoseconds.value,
         tradeDate   |-> tradeDate.value,
         sourceId    |-> sourceId.value,
         textMessage |-> textMessage.value ], textMessage.rest)

ZeroAdHocTextMessage ==
    [ nanoseconds |-> [i \in 1 .. 4 |-> 0],
      tradeDate   |-> [i \in 1 .. 2 |-> 0],
      sourceId    |-> [i \in 1 .. 6 |-> 0],
      textMessage |-> [i \in 1 .. 100 |-> 0] ]

(* Ad Hoc Text Message at zero, then each field in turn at the values it is checked at *)
CheckedAdHocTextMessage ==
    { ZeroAdHocTextMessage }
        \cup { [ZeroAdHocTextMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroAdHocTextMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroAdHocTextMessage EXCEPT !.sourceId = one] : one \in Sample(6) }
        \cup { [ZeroAdHocTextMessage EXCEPT !.textMessage = one] : one \in Sample(100) }

(***************************************************************************)
(* Request For Quote Message: 18 bytes                                     *)
(***************************************************************************)

RequestForQuoteMessage ==
    [ nanoseconds    : Sample(4),
      tradeDate      : Sample(2),
      contractNumber : Sample(4),
      price          : Sample(4),
      quantity       : Sample(4) ]

EncodeRequestForQuoteMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.contractNumber
        \o message.price
        \o message.quantity

DecodeRequestForQuoteMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET contractNumber == ReadBytes(tradeDate.rest, 4) IN IF ~contractNumber.ok THEN Fail ELSE
    LET price == ReadBytes(contractNumber.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    Ok([ nanoseconds    |-> nanoseconds.value,
         tradeDate      |-> tradeDate.value,
         contractNumber |-> contractNumber.value,
         price          |-> price.value,
         quantity       |-> quantity.value ], quantity.rest)

ZeroRequestForQuoteMessage ==
    [ nanoseconds    |-> [i \in 1 .. 4 |-> 0],
      tradeDate      |-> [i \in 1 .. 2 |-> 0],
      contractNumber |-> [i \in 1 .. 4 |-> 0],
      price          |-> [i \in 1 .. 4 |-> 0],
      quantity       |-> [i \in 1 .. 4 |-> 0] ]

(* Request For Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedRequestForQuoteMessage ==
    { ZeroRequestForQuoteMessage }
        \cup { [ZeroRequestForQuoteMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroRequestForQuoteMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroRequestForQuoteMessage EXCEPT !.contractNumber = one] : one \in Sample(4) }
        \cup { [ZeroRequestForQuoteMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroRequestForQuoteMessage EXCEPT !.quantity = one] : one \in Sample(4) }

(***************************************************************************)
(* Anomalous Order Threshold Publish Message: 34 bytes                     *)
(***************************************************************************)

AnomalousOrderThresholdPublishMessage ==
    [ nanoseconds    : Sample(4),
      tradeDate      : Sample(2),
      contractNumber : Sample(4),
      aotPrice       : Sample(4),
      aotUpperPrice  : Sample(4),
      aotLowerPrice  : Sample(4),
      etrPrice       : Sample(4),
      etrUpperPrice  : Sample(4),
      etrLowerPrice  : Sample(4) ]

EncodeAnomalousOrderThresholdPublishMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.contractNumber
        \o message.aotPrice
        \o message.aotUpperPrice
        \o message.aotLowerPrice
        \o message.etrPrice
        \o message.etrUpperPrice
        \o message.etrLowerPrice

DecodeAnomalousOrderThresholdPublishMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET contractNumber == ReadBytes(tradeDate.rest, 4) IN IF ~contractNumber.ok THEN Fail ELSE
    LET aotPrice == ReadBytes(contractNumber.rest, 4) IN IF ~aotPrice.ok THEN Fail ELSE
    LET aotUpperPrice == ReadBytes(aotPrice.rest, 4) IN IF ~aotUpperPrice.ok THEN Fail ELSE
    LET aotLowerPrice == ReadBytes(aotUpperPrice.rest, 4) IN IF ~aotLowerPrice.ok THEN Fail ELSE
    LET etrPrice == ReadBytes(aotLowerPrice.rest, 4) IN IF ~etrPrice.ok THEN Fail ELSE
    LET etrUpperPrice == ReadBytes(etrPrice.rest, 4) IN IF ~etrUpperPrice.ok THEN Fail ELSE
    LET etrLowerPrice == ReadBytes(etrUpperPrice.rest, 4) IN IF ~etrLowerPrice.ok THEN Fail ELSE
    Ok([ nanoseconds    |-> nanoseconds.value,
         tradeDate      |-> tradeDate.value,
         contractNumber |-> contractNumber.value,
         aotPrice       |-> aotPrice.value,
         aotUpperPrice  |-> aotUpperPrice.value,
         aotLowerPrice  |-> aotLowerPrice.value,
         etrPrice       |-> etrPrice.value,
         etrUpperPrice  |-> etrUpperPrice.value,
         etrLowerPrice  |-> etrLowerPrice.value ], etrLowerPrice.rest)

ZeroAnomalousOrderThresholdPublishMessage ==
    [ nanoseconds    |-> [i \in 1 .. 4 |-> 0],
      tradeDate      |-> [i \in 1 .. 2 |-> 0],
      contractNumber |-> [i \in 1 .. 4 |-> 0],
      aotPrice       |-> [i \in 1 .. 4 |-> 0],
      aotUpperPrice  |-> [i \in 1 .. 4 |-> 0],
      aotLowerPrice  |-> [i \in 1 .. 4 |-> 0],
      etrPrice       |-> [i \in 1 .. 4 |-> 0],
      etrUpperPrice  |-> [i \in 1 .. 4 |-> 0],
      etrLowerPrice  |-> [i \in 1 .. 4 |-> 0] ]

(* Anomalous Order Threshold Publish Message at zero, then each field in turn at the values it is checked at *)
CheckedAnomalousOrderThresholdPublishMessage ==
    { ZeroAnomalousOrderThresholdPublishMessage }
        \cup { [ZeroAnomalousOrderThresholdPublishMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroAnomalousOrderThresholdPublishMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroAnomalousOrderThresholdPublishMessage EXCEPT !.contractNumber = one] : one \in Sample(4) }
        \cup { [ZeroAnomalousOrderThresholdPublishMessage EXCEPT !.aotPrice = one] : one \in Sample(4) }
        \cup { [ZeroAnomalousOrderThresholdPublishMessage EXCEPT !.aotUpperPrice = one] : one \in Sample(4) }
        \cup { [ZeroAnomalousOrderThresholdPublishMessage EXCEPT !.aotLowerPrice = one] : one \in Sample(4) }
        \cup { [ZeroAnomalousOrderThresholdPublishMessage EXCEPT !.etrPrice = one] : one \in Sample(4) }
        \cup { [ZeroAnomalousOrderThresholdPublishMessage EXCEPT !.etrUpperPrice = one] : one \in Sample(4) }
        \cup { [ZeroAnomalousOrderThresholdPublishMessage EXCEPT !.etrLowerPrice = one] : one \in Sample(4) }

(***************************************************************************)
(* Volume And Open Interest Message: 20 bytes                              *)
(***************************************************************************)

VolumeAndOpenInterestMessage ==
    [ nanoseconds      : Sample(4),
      tradeDate        : Sample(2),
      contractNumber   : Sample(4),
      cumulativeVolume : Sample(4),
      openInterest     : Sample(4),
      voiTradeDate     : Sample(2) ]

EncodeVolumeAndOpenInterestMessage(message) ==
    message.nanoseconds
        \o message.tradeDate
        \o message.contractNumber
        \o message.cumulativeVolume
        \o message.openInterest
        \o message.voiTradeDate

DecodeVolumeAndOpenInterestMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(nanoseconds.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET contractNumber == ReadBytes(tradeDate.rest, 4) IN IF ~contractNumber.ok THEN Fail ELSE
    LET cumulativeVolume == ReadBytes(contractNumber.rest, 4) IN IF ~cumulativeVolume.ok THEN Fail ELSE
    LET openInterest == ReadBytes(cumulativeVolume.rest, 4) IN IF ~openInterest.ok THEN Fail ELSE
    LET voiTradeDate == ReadBytes(openInterest.rest, 2) IN IF ~voiTradeDate.ok THEN Fail ELSE
    Ok([ nanoseconds      |-> nanoseconds.value,
         tradeDate        |-> tradeDate.value,
         contractNumber   |-> contractNumber.value,
         cumulativeVolume |-> cumulativeVolume.value,
         openInterest     |-> openInterest.value,
         voiTradeDate     |-> voiTradeDate.value ], voiTradeDate.rest)

ZeroVolumeAndOpenInterestMessage ==
    [ nanoseconds      |-> [i \in 1 .. 4 |-> 0],
      tradeDate        |-> [i \in 1 .. 2 |-> 0],
      contractNumber   |-> [i \in 1 .. 4 |-> 0],
      cumulativeVolume |-> [i \in 1 .. 4 |-> 0],
      openInterest     |-> [i \in 1 .. 4 |-> 0],
      voiTradeDate     |-> [i \in 1 .. 2 |-> 0] ]

(* Volume And Open Interest Message at zero, then each field in turn at the values it is checked at *)
CheckedVolumeAndOpenInterestMessage ==
    { ZeroVolumeAndOpenInterestMessage }
        \cup { [ZeroVolumeAndOpenInterestMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroVolumeAndOpenInterestMessage EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroVolumeAndOpenInterestMessage EXCEPT !.contractNumber = one] : one \in Sample(4) }
        \cup { [ZeroVolumeAndOpenInterestMessage EXCEPT !.cumulativeVolume = one] : one \in Sample(4) }
        \cup { [ZeroVolumeAndOpenInterestMessage EXCEPT !.openInterest = one] : one \in Sample(4) }
        \cup { [ZeroVolumeAndOpenInterestMessage EXCEPT !.voiTradeDate = one] : one \in Sample(2) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

TimeMessageCode == 84  \* "T"
SystemEventMessageCode == 83  \* "S"
FutureSymbolDirectoryMessageCode == 102  \* "f"
SpreadSymbolDirectoryMessageCode == 103  \* "g"
OptionSymbolDirectoryMessageCode == 104  \* "h"
OrderBookStateMessageCode == 79  \* "O"
OrderAddedMessageCode == 65  \* "A"
OrderReplacedMessageCode == 85  \* "U"
OrderVolumeCancelledMessageCode == 88  \* "X"
OrderDeletedMessageCode == 68  \* "D"
ImpliedOrderAddedMessageCode == 106  \* "j"
ImpliedOrderReplacedMessageCode == 108  \* "l"
ImpliedOrderDeletedMessageCode == 107  \* "k"
CustomMarketOrderAddedMessageCode == 109  \* "m"
CustomMarketOrderReplacedMessageCode == 110  \* "n"
CustomMarketOrderDeletedMessageCode == 114  \* "r"
OrderExecutedMessageCode == 69  \* "E"
OrderExecutedWithPriceMessageCode == 67  \* "C"
SpreadExecutedMessageCode == 101  \* "e"
TradeSpreadExecutionChainMessageCode == 80  \* "P"
CustomMarketExecutedMessageCode == 117  \* "u"
CustomMarketTradeMessageCode == 112  \* "p"
TradeCancellationMessageCode == 66  \* "B"
EquilibriumPriceAuctionInfoMessageCode == 90  \* "Z"
OpenHighLowLastTradeAdjustmentMessageCode == 116  \* "t"
MarketSettlementMessageCode == 89  \* "Y"
AdHocTextMessageCode == 120  \* "x"
RequestForQuoteMessageCode == 113  \* "q"
AnomalousOrderThresholdPublishMessageCode == 87  \* "W"
VolumeAndOpenInterestMessageCode == 86  \* "V"

Payload ==
    [ tag : {TimeMessageCode}, body : TimeMessage ]
        \cup [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {FutureSymbolDirectoryMessageCode}, body : FutureSymbolDirectoryMessage ]
        \cup [ tag : {SpreadSymbolDirectoryMessageCode}, body : SpreadSymbolDirectoryMessage ]
        \cup [ tag : {OptionSymbolDirectoryMessageCode}, body : OptionSymbolDirectoryMessage ]
        \cup [ tag : {OrderBookStateMessageCode}, body : OrderBookStateMessage ]
        \cup [ tag : {OrderAddedMessageCode}, body : OrderAddedMessage ]
        \cup [ tag : {OrderReplacedMessageCode}, body : OrderReplacedMessage ]
        \cup [ tag : {OrderVolumeCancelledMessageCode}, body : OrderVolumeCancelledMessage ]
        \cup [ tag : {OrderDeletedMessageCode}, body : OrderDeletedMessage ]
        \cup [ tag : {ImpliedOrderAddedMessageCode}, body : ImpliedOrderAddedMessage ]
        \cup [ tag : {ImpliedOrderReplacedMessageCode}, body : ImpliedOrderReplacedMessage ]
        \cup [ tag : {ImpliedOrderDeletedMessageCode}, body : ImpliedOrderDeletedMessage ]
        \cup [ tag : {CustomMarketOrderAddedMessageCode}, body : CustomMarketOrderAddedMessage ]
        \cup [ tag : {CustomMarketOrderReplacedMessageCode}, body : CustomMarketOrderReplacedMessage ]
        \cup [ tag : {CustomMarketOrderDeletedMessageCode}, body : CustomMarketOrderDeletedMessage ]
        \cup [ tag : {OrderExecutedMessageCode}, body : OrderExecutedMessage ]
        \cup [ tag : {OrderExecutedWithPriceMessageCode}, body : OrderExecutedWithPriceMessage ]
        \cup [ tag : {SpreadExecutedMessageCode}, body : SpreadExecutedMessage ]
        \cup [ tag : {TradeSpreadExecutionChainMessageCode}, body : TradeSpreadExecutionChainMessage ]
        \cup [ tag : {CustomMarketExecutedMessageCode}, body : CustomMarketExecutedMessage ]
        \cup [ tag : {CustomMarketTradeMessageCode}, body : CustomMarketTradeMessage ]
        \cup [ tag : {TradeCancellationMessageCode}, body : TradeCancellationMessage ]
        \cup [ tag : {EquilibriumPriceAuctionInfoMessageCode}, body : EquilibriumPriceAuctionInfoMessage ]
        \cup [ tag : {OpenHighLowLastTradeAdjustmentMessageCode}, body : OpenHighLowLastTradeAdjustmentMessage ]
        \cup [ tag : {MarketSettlementMessageCode}, body : MarketSettlementMessage ]
        \cup [ tag : {AdHocTextMessageCode}, body : AdHocTextMessage ]
        \cup [ tag : {RequestForQuoteMessageCode}, body : RequestForQuoteMessage ]
        \cup [ tag : {AnomalousOrderThresholdPublishMessageCode}, body : AnomalousOrderThresholdPublishMessage ]
        \cup [ tag : {VolumeAndOpenInterestMessageCode}, body : VolumeAndOpenInterestMessage ]

EncodePayload(message) ==
    CASE message.tag = TimeMessageCode -> EncodeTimeMessage(message.body)
      [] message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = FutureSymbolDirectoryMessageCode -> EncodeFutureSymbolDirectoryMessage(message.body)
      [] message.tag = SpreadSymbolDirectoryMessageCode -> EncodeSpreadSymbolDirectoryMessage(message.body)
      [] message.tag = OptionSymbolDirectoryMessageCode -> EncodeOptionSymbolDirectoryMessage(message.body)
      [] message.tag = OrderBookStateMessageCode -> EncodeOrderBookStateMessage(message.body)
      [] message.tag = OrderAddedMessageCode -> EncodeOrderAddedMessage(message.body)
      [] message.tag = OrderReplacedMessageCode -> EncodeOrderReplacedMessage(message.body)
      [] message.tag = OrderVolumeCancelledMessageCode -> EncodeOrderVolumeCancelledMessage(message.body)
      [] message.tag = OrderDeletedMessageCode -> EncodeOrderDeletedMessage(message.body)
      [] message.tag = ImpliedOrderAddedMessageCode -> EncodeImpliedOrderAddedMessage(message.body)
      [] message.tag = ImpliedOrderReplacedMessageCode -> EncodeImpliedOrderReplacedMessage(message.body)
      [] message.tag = ImpliedOrderDeletedMessageCode -> EncodeImpliedOrderDeletedMessage(message.body)
      [] message.tag = CustomMarketOrderAddedMessageCode -> EncodeCustomMarketOrderAddedMessage(message.body)
      [] message.tag = CustomMarketOrderReplacedMessageCode -> EncodeCustomMarketOrderReplacedMessage(message.body)
      [] message.tag = CustomMarketOrderDeletedMessageCode -> EncodeCustomMarketOrderDeletedMessage(message.body)
      [] message.tag = OrderExecutedMessageCode -> EncodeOrderExecutedMessage(message.body)
      [] message.tag = OrderExecutedWithPriceMessageCode -> EncodeOrderExecutedWithPriceMessage(message.body)
      [] message.tag = SpreadExecutedMessageCode -> EncodeSpreadExecutedMessage(message.body)
      [] message.tag = TradeSpreadExecutionChainMessageCode -> EncodeTradeSpreadExecutionChainMessage(message.body)
      [] message.tag = CustomMarketExecutedMessageCode -> EncodeCustomMarketExecutedMessage(message.body)
      [] message.tag = CustomMarketTradeMessageCode -> EncodeCustomMarketTradeMessage(message.body)
      [] message.tag = TradeCancellationMessageCode -> EncodeTradeCancellationMessage(message.body)
      [] message.tag = EquilibriumPriceAuctionInfoMessageCode -> EncodeEquilibriumPriceAuctionInfoMessage(message.body)
      [] message.tag = OpenHighLowLastTradeAdjustmentMessageCode -> EncodeOpenHighLowLastTradeAdjustmentMessage(message.body)
      [] message.tag = MarketSettlementMessageCode -> EncodeMarketSettlementMessage(message.body)
      [] message.tag = AdHocTextMessageCode -> EncodeAdHocTextMessage(message.body)
      [] message.tag = RequestForQuoteMessageCode -> EncodeRequestForQuoteMessage(message.body)
      [] message.tag = AnomalousOrderThresholdPublishMessageCode -> EncodeAnomalousOrderThresholdPublishMessage(message.body)
      [] message.tag = VolumeAndOpenInterestMessageCode -> EncodeVolumeAndOpenInterestMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = TimeMessageCode -> DecodeTimeMessage(bytes)
              [] tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = FutureSymbolDirectoryMessageCode -> DecodeFutureSymbolDirectoryMessage(bytes)
              [] tag = SpreadSymbolDirectoryMessageCode -> DecodeSpreadSymbolDirectoryMessage(bytes)
              [] tag = OptionSymbolDirectoryMessageCode -> DecodeOptionSymbolDirectoryMessage(bytes)
              [] tag = OrderBookStateMessageCode -> DecodeOrderBookStateMessage(bytes)
              [] tag = OrderAddedMessageCode -> DecodeOrderAddedMessage(bytes)
              [] tag = OrderReplacedMessageCode -> DecodeOrderReplacedMessage(bytes)
              [] tag = OrderVolumeCancelledMessageCode -> DecodeOrderVolumeCancelledMessage(bytes)
              [] tag = OrderDeletedMessageCode -> DecodeOrderDeletedMessage(bytes)
              [] tag = ImpliedOrderAddedMessageCode -> DecodeImpliedOrderAddedMessage(bytes)
              [] tag = ImpliedOrderReplacedMessageCode -> DecodeImpliedOrderReplacedMessage(bytes)
              [] tag = ImpliedOrderDeletedMessageCode -> DecodeImpliedOrderDeletedMessage(bytes)
              [] tag = CustomMarketOrderAddedMessageCode -> DecodeCustomMarketOrderAddedMessage(bytes)
              [] tag = CustomMarketOrderReplacedMessageCode -> DecodeCustomMarketOrderReplacedMessage(bytes)
              [] tag = CustomMarketOrderDeletedMessageCode -> DecodeCustomMarketOrderDeletedMessage(bytes)
              [] tag = OrderExecutedMessageCode -> DecodeOrderExecutedMessage(bytes)
              [] tag = OrderExecutedWithPriceMessageCode -> DecodeOrderExecutedWithPriceMessage(bytes)
              [] tag = SpreadExecutedMessageCode -> DecodeSpreadExecutedMessage(bytes)
              [] tag = TradeSpreadExecutionChainMessageCode -> DecodeTradeSpreadExecutionChainMessage(bytes)
              [] tag = CustomMarketExecutedMessageCode -> DecodeCustomMarketExecutedMessage(bytes)
              [] tag = CustomMarketTradeMessageCode -> DecodeCustomMarketTradeMessage(bytes)
              [] tag = TradeCancellationMessageCode -> DecodeTradeCancellationMessage(bytes)
              [] tag = EquilibriumPriceAuctionInfoMessageCode -> DecodeEquilibriumPriceAuctionInfoMessage(bytes)
              [] tag = OpenHighLowLastTradeAdjustmentMessageCode -> DecodeOpenHighLowLastTradeAdjustmentMessage(bytes)
              [] tag = MarketSettlementMessageCode -> DecodeMarketSettlementMessage(bytes)
              [] tag = AdHocTextMessageCode -> DecodeAdHocTextMessage(bytes)
              [] tag = RequestForQuoteMessageCode -> DecodeRequestForQuoteMessage(bytes)
              [] tag = AnomalousOrderThresholdPublishMessageCode -> DecodeAnomalousOrderThresholdPublishMessage(bytes)
              [] tag = VolumeAndOpenInterestMessageCode -> DecodeVolumeAndOpenInterestMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> TimeMessageCode, body |-> ZeroTimeMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> TimeMessageCode, body |-> one] : one \in CheckedTimeMessage }
        \cup { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> FutureSymbolDirectoryMessageCode, body |-> one] : one \in CheckedFutureSymbolDirectoryMessage }
        \cup { [tag |-> SpreadSymbolDirectoryMessageCode, body |-> one] : one \in CheckedSpreadSymbolDirectoryMessage }
        \cup { [tag |-> OptionSymbolDirectoryMessageCode, body |-> one] : one \in CheckedOptionSymbolDirectoryMessage }
        \cup { [tag |-> OrderBookStateMessageCode, body |-> one] : one \in CheckedOrderBookStateMessage }
        \cup { [tag |-> OrderAddedMessageCode, body |-> one] : one \in CheckedOrderAddedMessage }
        \cup { [tag |-> OrderReplacedMessageCode, body |-> one] : one \in CheckedOrderReplacedMessage }
        \cup { [tag |-> OrderVolumeCancelledMessageCode, body |-> one] : one \in CheckedOrderVolumeCancelledMessage }
        \cup { [tag |-> OrderDeletedMessageCode, body |-> one] : one \in CheckedOrderDeletedMessage }
        \cup { [tag |-> ImpliedOrderAddedMessageCode, body |-> one] : one \in CheckedImpliedOrderAddedMessage }
        \cup { [tag |-> ImpliedOrderReplacedMessageCode, body |-> one] : one \in CheckedImpliedOrderReplacedMessage }
        \cup { [tag |-> ImpliedOrderDeletedMessageCode, body |-> one] : one \in CheckedImpliedOrderDeletedMessage }
        \cup { [tag |-> CustomMarketOrderAddedMessageCode, body |-> one] : one \in CheckedCustomMarketOrderAddedMessage }
        \cup { [tag |-> CustomMarketOrderReplacedMessageCode, body |-> one] : one \in CheckedCustomMarketOrderReplacedMessage }
        \cup { [tag |-> CustomMarketOrderDeletedMessageCode, body |-> one] : one \in CheckedCustomMarketOrderDeletedMessage }
        \cup { [tag |-> OrderExecutedMessageCode, body |-> one] : one \in CheckedOrderExecutedMessage }
        \cup { [tag |-> OrderExecutedWithPriceMessageCode, body |-> one] : one \in CheckedOrderExecutedWithPriceMessage }
        \cup { [tag |-> SpreadExecutedMessageCode, body |-> one] : one \in CheckedSpreadExecutedMessage }
        \cup { [tag |-> TradeSpreadExecutionChainMessageCode, body |-> one] : one \in CheckedTradeSpreadExecutionChainMessage }
        \cup { [tag |-> CustomMarketExecutedMessageCode, body |-> one] : one \in CheckedCustomMarketExecutedMessage }
        \cup { [tag |-> CustomMarketTradeMessageCode, body |-> one] : one \in CheckedCustomMarketTradeMessage }
        \cup { [tag |-> TradeCancellationMessageCode, body |-> one] : one \in CheckedTradeCancellationMessage }
        \cup { [tag |-> EquilibriumPriceAuctionInfoMessageCode, body |-> one] : one \in CheckedEquilibriumPriceAuctionInfoMessage }
        \cup { [tag |-> OpenHighLowLastTradeAdjustmentMessageCode, body |-> one] : one \in CheckedOpenHighLowLastTradeAdjustmentMessage }
        \cup { [tag |-> MarketSettlementMessageCode, body |-> one] : one \in CheckedMarketSettlementMessage }
        \cup { [tag |-> AdHocTextMessageCode, body |-> one] : one \in CheckedAdHocTextMessage }
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> TimeMessageCode, body |-> ZeroTimeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> FutureSymbolDirectoryMessageCode, body |-> ZeroFutureSymbolDirectoryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SpreadSymbolDirectoryMessageCode, body |-> ZeroSpreadSymbolDirectoryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OptionSymbolDirectoryMessageCode, body |-> ZeroOptionSymbolDirectoryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderBookStateMessageCode, body |-> ZeroOrderBookStateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderAddedMessageCode, body |-> ZeroOrderAddedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderReplacedMessageCode, body |-> ZeroOrderReplacedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderVolumeCancelledMessageCode, body |-> ZeroOrderVolumeCancelledMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderDeletedMessageCode, body |-> ZeroOrderDeletedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ImpliedOrderAddedMessageCode, body |-> ZeroImpliedOrderAddedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ImpliedOrderReplacedMessageCode, body |-> ZeroImpliedOrderReplacedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ImpliedOrderDeletedMessageCode, body |-> ZeroImpliedOrderDeletedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CustomMarketOrderAddedMessageCode, body |-> ZeroCustomMarketOrderAddedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CustomMarketOrderReplacedMessageCode, body |-> ZeroCustomMarketOrderReplacedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CustomMarketOrderDeletedMessageCode, body |-> ZeroCustomMarketOrderDeletedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderExecutedMessageCode, body |-> ZeroOrderExecutedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderExecutedWithPriceMessageCode, body |-> ZeroOrderExecutedWithPriceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SpreadExecutedMessageCode, body |-> ZeroSpreadExecutedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeSpreadExecutionChainMessageCode, body |-> ZeroTradeSpreadExecutionChainMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CustomMarketExecutedMessageCode, body |-> ZeroCustomMarketExecutedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CustomMarketTradeMessageCode, body |-> ZeroCustomMarketTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeCancellationMessageCode, body |-> ZeroTradeCancellationMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EquilibriumPriceAuctionInfoMessageCode, body |-> ZeroEquilibriumPriceAuctionInfoMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OpenHighLowLastTradeAdjustmentMessageCode, body |-> ZeroOpenHighLowLastTradeAdjustmentMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MarketSettlementMessageCode, body |-> ZeroMarketSettlementMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AdHocTextMessageCode, body |-> ZeroAdHocTextMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RequestForQuoteMessageCode, body |-> ZeroRequestForQuoteMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AnomalousOrderThresholdPublishMessageCode, body |-> ZeroAnomalousOrderThresholdPublishMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> VolumeAndOpenInterestMessageCode, body |-> ZeroVolumeAndOpenInterestMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ session        : Session,
      sequenceNumber : Sample(8),
      message        : SampleLists(OneMessage) ]

EncodePacket(message) ==
    EncodeSession(message.session)
        \o message.sequenceNumber
        \o EncodeUIntBE(Len(message.message), 2)
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET session == DecodeSession(bytes) IN IF ~session.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(session.rest, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET messageCount == ReadUIntBE(sequenceNumber.rest, 2) IN IF ~messageCount.ok THEN Fail ELSE
    LET message == ReadMessageList(messageCount.rest, messageCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ session        |-> session.value,
         sequenceNumber |-> sequenceNumber.value,
         message        |-> message.value ], message.rest)

ZeroPacket ==
    [ session        |-> ZeroSession,
      sequenceNumber |-> [i \in 1 .. 8 |-> 0],
      message        |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.session = one] : one \in CheckedSession }
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

(* Every Session decodes back to what was encoded, and leaves nothing over *)
RoundTripSession ==
    \A message \in CheckedSession :
        LET read == DecodeSession(EncodeSession(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Time Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTimeMessage ==
    \A message \in CheckedTimeMessage :
        LET read == DecodeTimeMessage(EncodeTimeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every System Event Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSystemEventMessage ==
    \A message \in CheckedSystemEventMessage :
        LET read == DecodeSystemEventMessage(EncodeSystemEventMessage(message))
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

(* Every Spread Symbol Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSpreadSymbolDirectoryMessage ==
    \A message \in CheckedSpreadSymbolDirectoryMessage :
        LET read == DecodeSpreadSymbolDirectoryMessage(EncodeSpreadSymbolDirectoryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Symbol Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionSymbolDirectoryMessage ==
    \A message \in CheckedOptionSymbolDirectoryMessage :
        LET read == DecodeOptionSymbolDirectoryMessage(EncodeOptionSymbolDirectoryMessage(message))
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

(* Every Order Added Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderAddedMessage ==
    \A message \in CheckedOrderAddedMessage :
        LET read == DecodeOrderAddedMessage(EncodeOrderAddedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Replaced Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderReplacedMessage ==
    \A message \in CheckedOrderReplacedMessage :
        LET read == DecodeOrderReplacedMessage(EncodeOrderReplacedMessage(message))
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

(* Every Contract Legs decodes back to what was encoded, and leaves nothing over *)
RoundTripContractLegs ==
    \A message \in CheckedContractLegs :
        LET read == DecodeContractLegs(EncodeContractLegs(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Custom Market Order Added Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCustomMarketOrderAddedMessage ==
    \A message \in CheckedCustomMarketOrderAddedMessage :
        LET read == DecodeCustomMarketOrderAddedMessage(EncodeCustomMarketOrderAddedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Custom Market Order Replaced Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCustomMarketOrderReplacedMessage ==
    \A message \in CheckedCustomMarketOrderReplacedMessage :
        LET read == DecodeCustomMarketOrderReplacedMessage(EncodeCustomMarketOrderReplacedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Custom Market Order Deleted Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCustomMarketOrderDeletedMessage ==
    \A message \in CheckedCustomMarketOrderDeletedMessage :
        LET read == DecodeCustomMarketOrderDeletedMessage(EncodeCustomMarketOrderDeletedMessage(message))
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

(* Every Order Executed With Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutedWithPriceMessage ==
    \A message \in CheckedOrderExecutedWithPriceMessage :
        LET read == DecodeOrderExecutedWithPriceMessage(EncodeOrderExecutedWithPriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Spread Executed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSpreadExecutedMessage ==
    \A message \in CheckedSpreadExecutedMessage :
        LET read == DecodeSpreadExecutedMessage(EncodeSpreadExecutedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Spread Execution Chain Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeSpreadExecutionChainMessage ==
    \A message \in CheckedTradeSpreadExecutionChainMessage :
        LET read == DecodeTradeSpreadExecutionChainMessage(EncodeTradeSpreadExecutionChainMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Custom Market Executed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCustomMarketExecutedMessage ==
    \A message \in CheckedCustomMarketExecutedMessage :
        LET read == DecodeCustomMarketExecutedMessage(EncodeCustomMarketExecutedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Custom Market Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCustomMarketTradeMessage ==
    \A message \in CheckedCustomMarketTradeMessage :
        LET read == DecodeCustomMarketTradeMessage(EncodeCustomMarketTradeMessage(message))
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

(* Every Equilibrium Price Auction Info Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEquilibriumPriceAuctionInfoMessage ==
    \A message \in CheckedEquilibriumPriceAuctionInfoMessage :
        LET read == DecodeEquilibriumPriceAuctionInfoMessage(EncodeEquilibriumPriceAuctionInfoMessage(message))
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

(* Every Ad Hoc Text Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAdHocTextMessage ==
    \A message \in CheckedAdHocTextMessage :
        LET read == DecodeAdHocTextMessage(EncodeAdHocTextMessage(message))
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
