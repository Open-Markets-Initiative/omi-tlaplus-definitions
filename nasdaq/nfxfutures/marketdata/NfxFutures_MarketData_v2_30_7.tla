------------------- MODULE NfxFutures_MarketData_v2_30_7 -------------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Genium INET Auxiliary Market Data v2.30.7                      *)
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
(* Order Book Directory: 135 bytes                                         *)
(***************************************************************************)

OrderBookDirectory ==
    [ timestampNanoseconds           : Sample(4),
      orderBookId                    : Sample(4),
      symbol                         : Sample(32),
      longName                       : Sample(32),
      isin                           : Sample(12),
      financialProduct               : Sample(1),
      tradingCurrency                : Sample(3),
      numberOfDecimalsInPrice        : Sample(2),
      numberOfDecimalsInNominalValue : Sample(2),
      oddLotSize                     : Sample(4),
      roundLotSize                   : Sample(4),
      blockLotSize                   : Sample(4),
      nominalValue                   : Sample(8),
      numberOfLegs                   : Sample(1),
      underlyingOrderBookId          : Sample(4),
      strikePrice                    : Sample(4),
      expirationDate                 : Sample(4),
      numberOfDecimalsInStrikePrice  : Sample(2),
      putOrCall                      : Sample(1),
      marketId                       : Sample(2),
      strategySubtype                : Sample(1),
      minimumQuantityAndMultiple     : Sample(4) ]

EncodeOrderBookDirectory(message) ==
    message.timestampNanoseconds
        \o message.orderBookId
        \o message.symbol
        \o message.longName
        \o message.isin
        \o message.financialProduct
        \o message.tradingCurrency
        \o message.numberOfDecimalsInPrice
        \o message.numberOfDecimalsInNominalValue
        \o message.oddLotSize
        \o message.roundLotSize
        \o message.blockLotSize
        \o message.nominalValue
        \o message.numberOfLegs
        \o message.underlyingOrderBookId
        \o message.strikePrice
        \o message.expirationDate
        \o message.numberOfDecimalsInStrikePrice
        \o message.putOrCall
        \o message.marketId
        \o message.strategySubtype
        \o message.minimumQuantityAndMultiple

DecodeOrderBookDirectory(bytes) ==
    LET timestampNanoseconds == ReadBytes(bytes, 4) IN IF ~timestampNanoseconds.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(timestampNanoseconds.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET symbol == ReadBytes(orderBookId.rest, 32) IN IF ~symbol.ok THEN Fail ELSE
    LET longName == ReadBytes(symbol.rest, 32) IN IF ~longName.ok THEN Fail ELSE
    LET isin == ReadBytes(longName.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET financialProduct == ReadBytes(isin.rest, 1) IN IF ~financialProduct.ok THEN Fail ELSE
    LET tradingCurrency == ReadBytes(financialProduct.rest, 3) IN IF ~tradingCurrency.ok THEN Fail ELSE
    LET numberOfDecimalsInPrice == ReadBytes(tradingCurrency.rest, 2) IN IF ~numberOfDecimalsInPrice.ok THEN Fail ELSE
    LET numberOfDecimalsInNominalValue == ReadBytes(numberOfDecimalsInPrice.rest, 2) IN IF ~numberOfDecimalsInNominalValue.ok THEN Fail ELSE
    LET oddLotSize == ReadBytes(numberOfDecimalsInNominalValue.rest, 4) IN IF ~oddLotSize.ok THEN Fail ELSE
    LET roundLotSize == ReadBytes(oddLotSize.rest, 4) IN IF ~roundLotSize.ok THEN Fail ELSE
    LET blockLotSize == ReadBytes(roundLotSize.rest, 4) IN IF ~blockLotSize.ok THEN Fail ELSE
    LET nominalValue == ReadBytes(blockLotSize.rest, 8) IN IF ~nominalValue.ok THEN Fail ELSE
    LET numberOfLegs == ReadBytes(nominalValue.rest, 1) IN IF ~numberOfLegs.ok THEN Fail ELSE
    LET underlyingOrderBookId == ReadBytes(numberOfLegs.rest, 4) IN IF ~underlyingOrderBookId.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(underlyingOrderBookId.rest, 4) IN IF ~strikePrice.ok THEN Fail ELSE
    LET expirationDate == ReadBytes(strikePrice.rest, 4) IN IF ~expirationDate.ok THEN Fail ELSE
    LET numberOfDecimalsInStrikePrice == ReadBytes(expirationDate.rest, 2) IN IF ~numberOfDecimalsInStrikePrice.ok THEN Fail ELSE
    LET putOrCall == ReadBytes(numberOfDecimalsInStrikePrice.rest, 1) IN IF ~putOrCall.ok THEN Fail ELSE
    LET marketId == ReadBytes(putOrCall.rest, 2) IN IF ~marketId.ok THEN Fail ELSE
    LET strategySubtype == ReadBytes(marketId.rest, 1) IN IF ~strategySubtype.ok THEN Fail ELSE
    LET minimumQuantityAndMultiple == ReadBytes(strategySubtype.rest, 4) IN IF ~minimumQuantityAndMultiple.ok THEN Fail ELSE
    Ok([ timestampNanoseconds           |-> timestampNanoseconds.value,
         orderBookId                    |-> orderBookId.value,
         symbol                         |-> symbol.value,
         longName                       |-> longName.value,
         isin                           |-> isin.value,
         financialProduct               |-> financialProduct.value,
         tradingCurrency                |-> tradingCurrency.value,
         numberOfDecimalsInPrice        |-> numberOfDecimalsInPrice.value,
         numberOfDecimalsInNominalValue |-> numberOfDecimalsInNominalValue.value,
         oddLotSize                     |-> oddLotSize.value,
         roundLotSize                   |-> roundLotSize.value,
         blockLotSize                   |-> blockLotSize.value,
         nominalValue                   |-> nominalValue.value,
         numberOfLegs                   |-> numberOfLegs.value,
         underlyingOrderBookId          |-> underlyingOrderBookId.value,
         strikePrice                    |-> strikePrice.value,
         expirationDate                 |-> expirationDate.value,
         numberOfDecimalsInStrikePrice  |-> numberOfDecimalsInStrikePrice.value,
         putOrCall                      |-> putOrCall.value,
         marketId                       |-> marketId.value,
         strategySubtype                |-> strategySubtype.value,
         minimumQuantityAndMultiple     |-> minimumQuantityAndMultiple.value ], minimumQuantityAndMultiple.rest)

ZeroOrderBookDirectory ==
    [ timestampNanoseconds           |-> [i \in 1 .. 4 |-> 0],
      orderBookId                    |-> [i \in 1 .. 4 |-> 0],
      symbol                         |-> [i \in 1 .. 32 |-> 0],
      longName                       |-> [i \in 1 .. 32 |-> 0],
      isin                           |-> [i \in 1 .. 12 |-> 0],
      financialProduct               |-> [i \in 1 .. 1 |-> 0],
      tradingCurrency                |-> [i \in 1 .. 3 |-> 0],
      numberOfDecimalsInPrice        |-> [i \in 1 .. 2 |-> 0],
      numberOfDecimalsInNominalValue |-> [i \in 1 .. 2 |-> 0],
      oddLotSize                     |-> [i \in 1 .. 4 |-> 0],
      roundLotSize                   |-> [i \in 1 .. 4 |-> 0],
      blockLotSize                   |-> [i \in 1 .. 4 |-> 0],
      nominalValue                   |-> [i \in 1 .. 8 |-> 0],
      numberOfLegs                   |-> [i \in 1 .. 1 |-> 0],
      underlyingOrderBookId          |-> [i \in 1 .. 4 |-> 0],
      strikePrice                    |-> [i \in 1 .. 4 |-> 0],
      expirationDate                 |-> [i \in 1 .. 4 |-> 0],
      numberOfDecimalsInStrikePrice  |-> [i \in 1 .. 2 |-> 0],
      putOrCall                      |-> [i \in 1 .. 1 |-> 0],
      marketId                       |-> [i \in 1 .. 2 |-> 0],
      strategySubtype                |-> [i \in 1 .. 1 |-> 0],
      minimumQuantityAndMultiple     |-> [i \in 1 .. 4 |-> 0] ]

(* Order Book Directory at zero, then each field in turn at the values it is checked at *)
CheckedOrderBookDirectory ==
    { ZeroOrderBookDirectory }
        \cup { [ZeroOrderBookDirectory EXCEPT !.timestampNanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.symbol = one] : one \in Sample(32) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.longName = one] : one \in Sample(32) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.financialProduct = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.tradingCurrency = one] : one \in Sample(3) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.numberOfDecimalsInPrice = one] : one \in Sample(2) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.numberOfDecimalsInNominalValue = one] : one \in Sample(2) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.oddLotSize = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.roundLotSize = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.blockLotSize = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.nominalValue = one] : one \in Sample(8) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.numberOfLegs = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.underlyingOrderBookId = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.expirationDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.numberOfDecimalsInStrikePrice = one] : one \in Sample(2) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.putOrCall = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.marketId = one] : one \in Sample(2) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.strategySubtype = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.minimumQuantityAndMultiple = one] : one \in Sample(4) }

(***************************************************************************)
(* Combination Order Book Leg: 29 bytes                                    *)
(***************************************************************************)

CombinationOrderBookLeg ==
    [ timestampNanoseconds   : Sample(4),
      combinationOrderBookId : Sample(4),
      legOrderBookId         : Sample(4),
      legSide                : Sample(1),
      legRatio               : Sample(4),
      legPriceFuture         : Sample(4),
      legDelta               : Sample(4),
      legQuantityFuture      : Sample(4) ]

EncodeCombinationOrderBookLeg(message) ==
    message.timestampNanoseconds
        \o message.combinationOrderBookId
        \o message.legOrderBookId
        \o message.legSide
        \o message.legRatio
        \o message.legPriceFuture
        \o message.legDelta
        \o message.legQuantityFuture

DecodeCombinationOrderBookLeg(bytes) ==
    LET timestampNanoseconds == ReadBytes(bytes, 4) IN IF ~timestampNanoseconds.ok THEN Fail ELSE
    LET combinationOrderBookId == ReadBytes(timestampNanoseconds.rest, 4) IN IF ~combinationOrderBookId.ok THEN Fail ELSE
    LET legOrderBookId == ReadBytes(combinationOrderBookId.rest, 4) IN IF ~legOrderBookId.ok THEN Fail ELSE
    LET legSide == ReadBytes(legOrderBookId.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET legRatio == ReadBytes(legSide.rest, 4) IN IF ~legRatio.ok THEN Fail ELSE
    LET legPriceFuture == ReadBytes(legRatio.rest, 4) IN IF ~legPriceFuture.ok THEN Fail ELSE
    LET legDelta == ReadBytes(legPriceFuture.rest, 4) IN IF ~legDelta.ok THEN Fail ELSE
    LET legQuantityFuture == ReadBytes(legDelta.rest, 4) IN IF ~legQuantityFuture.ok THEN Fail ELSE
    Ok([ timestampNanoseconds   |-> timestampNanoseconds.value,
         combinationOrderBookId |-> combinationOrderBookId.value,
         legOrderBookId         |-> legOrderBookId.value,
         legSide                |-> legSide.value,
         legRatio               |-> legRatio.value,
         legPriceFuture         |-> legPriceFuture.value,
         legDelta               |-> legDelta.value,
         legQuantityFuture      |-> legQuantityFuture.value ], legQuantityFuture.rest)

ZeroCombinationOrderBookLeg ==
    [ timestampNanoseconds   |-> [i \in 1 .. 4 |-> 0],
      combinationOrderBookId |-> [i \in 1 .. 4 |-> 0],
      legOrderBookId         |-> [i \in 1 .. 4 |-> 0],
      legSide                |-> [i \in 1 .. 1 |-> 0],
      legRatio               |-> [i \in 1 .. 4 |-> 0],
      legPriceFuture         |-> [i \in 1 .. 4 |-> 0],
      legDelta               |-> [i \in 1 .. 4 |-> 0],
      legQuantityFuture      |-> [i \in 1 .. 4 |-> 0] ]

(* Combination Order Book Leg at zero, then each field in turn at the values it is checked at *)
CheckedCombinationOrderBookLeg ==
    { ZeroCombinationOrderBookLeg }
        \cup { [ZeroCombinationOrderBookLeg EXCEPT !.timestampNanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroCombinationOrderBookLeg EXCEPT !.combinationOrderBookId = one] : one \in Sample(4) }
        \cup { [ZeroCombinationOrderBookLeg EXCEPT !.legOrderBookId = one] : one \in Sample(4) }
        \cup { [ZeroCombinationOrderBookLeg EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroCombinationOrderBookLeg EXCEPT !.legRatio = one] : one \in Sample(4) }
        \cup { [ZeroCombinationOrderBookLeg EXCEPT !.legPriceFuture = one] : one \in Sample(4) }
        \cup { [ZeroCombinationOrderBookLeg EXCEPT !.legDelta = one] : one \in Sample(4) }
        \cup { [ZeroCombinationOrderBookLeg EXCEPT !.legQuantityFuture = one] : one \in Sample(4) }

(***************************************************************************)
(* Tick Size Table Entry: 24 bytes                                         *)
(***************************************************************************)

TickSizeTableEntry ==
    [ timestampNanoseconds : Sample(4),
      orderBookId          : Sample(4),
      tickSize             : Sample(8),
      priceFrom            : Sample(4),
      priceTo              : Sample(4) ]

EncodeTickSizeTableEntry(message) ==
    message.timestampNanoseconds
        \o message.orderBookId
        \o message.tickSize
        \o message.priceFrom
        \o message.priceTo

DecodeTickSizeTableEntry(bytes) ==
    LET timestampNanoseconds == ReadBytes(bytes, 4) IN IF ~timestampNanoseconds.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(timestampNanoseconds.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET tickSize == ReadBytes(orderBookId.rest, 8) IN IF ~tickSize.ok THEN Fail ELSE
    LET priceFrom == ReadBytes(tickSize.rest, 4) IN IF ~priceFrom.ok THEN Fail ELSE
    LET priceTo == ReadBytes(priceFrom.rest, 4) IN IF ~priceTo.ok THEN Fail ELSE
    Ok([ timestampNanoseconds |-> timestampNanoseconds.value,
         orderBookId          |-> orderBookId.value,
         tickSize             |-> tickSize.value,
         priceFrom            |-> priceFrom.value,
         priceTo              |-> priceTo.value ], priceTo.rest)

ZeroTickSizeTableEntry ==
    [ timestampNanoseconds |-> [i \in 1 .. 4 |-> 0],
      orderBookId          |-> [i \in 1 .. 4 |-> 0],
      tickSize             |-> [i \in 1 .. 8 |-> 0],
      priceFrom            |-> [i \in 1 .. 4 |-> 0],
      priceTo              |-> [i \in 1 .. 4 |-> 0] ]

(* Tick Size Table Entry at zero, then each field in turn at the values it is checked at *)
CheckedTickSizeTableEntry ==
    { ZeroTickSizeTableEntry }
        \cup { [ZeroTickSizeTableEntry EXCEPT !.timestampNanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroTickSizeTableEntry EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroTickSizeTableEntry EXCEPT !.tickSize = one] : one \in Sample(8) }
        \cup { [ZeroTickSizeTableEntry EXCEPT !.priceFrom = one] : one \in Sample(4) }
        \cup { [ZeroTickSizeTableEntry EXCEPT !.priceTo = one] : one \in Sample(4) }

(***************************************************************************)
(* System Event Message: 5 bytes                                           *)
(***************************************************************************)

SystemEventMessage ==
    [ timestampNanoseconds : Sample(4),
      eventCode            : Sample(1) ]

EncodeSystemEventMessage(message) ==
    message.timestampNanoseconds
        \o message.eventCode

DecodeSystemEventMessage(bytes) ==
    LET timestampNanoseconds == ReadBytes(bytes, 4) IN IF ~timestampNanoseconds.ok THEN Fail ELSE
    LET eventCode == ReadBytes(timestampNanoseconds.rest, 1) IN IF ~eventCode.ok THEN Fail ELSE
    Ok([ timestampNanoseconds |-> timestampNanoseconds.value,
         eventCode            |-> eventCode.value ], eventCode.rest)

ZeroSystemEventMessage ==
    [ timestampNanoseconds |-> [i \in 1 .. 4 |-> 0],
      eventCode            |-> [i \in 1 .. 1 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.timestampNanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Book State Message: 28 bytes                                      *)
(***************************************************************************)

OrderBookStateMessage ==
    [ timestampNanoseconds : Sample(4),
      orderBookId          : Sample(4),
      stateName            : Sample(20) ]

EncodeOrderBookStateMessage(message) ==
    message.timestampNanoseconds
        \o message.orderBookId
        \o message.stateName

DecodeOrderBookStateMessage(bytes) ==
    LET timestampNanoseconds == ReadBytes(bytes, 4) IN IF ~timestampNanoseconds.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(timestampNanoseconds.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET stateName == ReadBytes(orderBookId.rest, 20) IN IF ~stateName.ok THEN Fail ELSE
    Ok([ timestampNanoseconds |-> timestampNanoseconds.value,
         orderBookId          |-> orderBookId.value,
         stateName            |-> stateName.value ], stateName.rest)

ZeroOrderBookStateMessage ==
    [ timestampNanoseconds |-> [i \in 1 .. 4 |-> 0],
      orderBookId          |-> [i \in 1 .. 4 |-> 0],
      stateName            |-> [i \in 1 .. 20 |-> 0] ]

(* Order Book State Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderBookStateMessage ==
    { ZeroOrderBookStateMessage }
        \cup { [ZeroOrderBookStateMessage EXCEPT !.timestampNanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookStateMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookStateMessage EXCEPT !.stateName = one] : one \in Sample(20) }

(***************************************************************************)
(* Reported Trade: 72 bytes                                                *)
(***************************************************************************)

ReportedTrade ==
    [ timestampNanoseconds     : Sample(4),
      orderBookId              : Sample(4),
      tradedQuantity           : Sample(8),
      matchId                  : Sample(8),
      comboGroupId             : Sample(4),
      timeOfTradeExecution     : Sample(8),
      timeOfTradeAgreement     : Sample(8),
      timeOfTradeDissemination : Sample(8),
      tradePrice               : Sample(4),
      tradeType                : Sample(2),
      reserved                 : Sample(7),
      secondReserved           : Sample(7) ]

EncodeReportedTrade(message) ==
    message.timestampNanoseconds
        \o message.orderBookId
        \o message.tradedQuantity
        \o message.matchId
        \o message.comboGroupId
        \o message.timeOfTradeExecution
        \o message.timeOfTradeAgreement
        \o message.timeOfTradeDissemination
        \o message.tradePrice
        \o message.tradeType
        \o message.reserved
        \o message.secondReserved

DecodeReportedTrade(bytes) ==
    LET timestampNanoseconds == ReadBytes(bytes, 4) IN IF ~timestampNanoseconds.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(timestampNanoseconds.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET tradedQuantity == ReadBytes(orderBookId.rest, 8) IN IF ~tradedQuantity.ok THEN Fail ELSE
    LET matchId == ReadBytes(tradedQuantity.rest, 8) IN IF ~matchId.ok THEN Fail ELSE
    LET comboGroupId == ReadBytes(matchId.rest, 4) IN IF ~comboGroupId.ok THEN Fail ELSE
    LET timeOfTradeExecution == ReadBytes(comboGroupId.rest, 8) IN IF ~timeOfTradeExecution.ok THEN Fail ELSE
    LET timeOfTradeAgreement == ReadBytes(timeOfTradeExecution.rest, 8) IN IF ~timeOfTradeAgreement.ok THEN Fail ELSE
    LET timeOfTradeDissemination == ReadBytes(timeOfTradeAgreement.rest, 8) IN IF ~timeOfTradeDissemination.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(timeOfTradeDissemination.rest, 4) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradeType == ReadBytes(tradePrice.rest, 2) IN IF ~tradeType.ok THEN Fail ELSE
    LET reserved == ReadBytes(tradeType.rest, 7) IN IF ~reserved.ok THEN Fail ELSE
    LET secondReserved == ReadBytes(reserved.rest, 7) IN IF ~secondReserved.ok THEN Fail ELSE
    Ok([ timestampNanoseconds     |-> timestampNanoseconds.value,
         orderBookId              |-> orderBookId.value,
         tradedQuantity           |-> tradedQuantity.value,
         matchId                  |-> matchId.value,
         comboGroupId             |-> comboGroupId.value,
         timeOfTradeExecution     |-> timeOfTradeExecution.value,
         timeOfTradeAgreement     |-> timeOfTradeAgreement.value,
         timeOfTradeDissemination |-> timeOfTradeDissemination.value,
         tradePrice               |-> tradePrice.value,
         tradeType                |-> tradeType.value,
         reserved                 |-> reserved.value,
         secondReserved           |-> secondReserved.value ], secondReserved.rest)

ZeroReportedTrade ==
    [ timestampNanoseconds     |-> [i \in 1 .. 4 |-> 0],
      orderBookId              |-> [i \in 1 .. 4 |-> 0],
      tradedQuantity           |-> [i \in 1 .. 8 |-> 0],
      matchId                  |-> [i \in 1 .. 8 |-> 0],
      comboGroupId             |-> [i \in 1 .. 4 |-> 0],
      timeOfTradeExecution     |-> [i \in 1 .. 8 |-> 0],
      timeOfTradeAgreement     |-> [i \in 1 .. 8 |-> 0],
      timeOfTradeDissemination |-> [i \in 1 .. 8 |-> 0],
      tradePrice               |-> [i \in 1 .. 4 |-> 0],
      tradeType                |-> [i \in 1 .. 2 |-> 0],
      reserved                 |-> [i \in 1 .. 7 |-> 0],
      secondReserved           |-> [i \in 1 .. 7 |-> 0] ]

(* Reported Trade at zero, then each field in turn at the values it is checked at *)
CheckedReportedTrade ==
    { ZeroReportedTrade }
        \cup { [ZeroReportedTrade EXCEPT !.timestampNanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroReportedTrade EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroReportedTrade EXCEPT !.tradedQuantity = one] : one \in Sample(8) }
        \cup { [ZeroReportedTrade EXCEPT !.matchId = one] : one \in Sample(8) }
        \cup { [ZeroReportedTrade EXCEPT !.comboGroupId = one] : one \in Sample(4) }
        \cup { [ZeroReportedTrade EXCEPT !.timeOfTradeExecution = one] : one \in Sample(8) }
        \cup { [ZeroReportedTrade EXCEPT !.timeOfTradeAgreement = one] : one \in Sample(8) }
        \cup { [ZeroReportedTrade EXCEPT !.timeOfTradeDissemination = one] : one \in Sample(8) }
        \cup { [ZeroReportedTrade EXCEPT !.tradePrice = one] : one \in Sample(4) }
        \cup { [ZeroReportedTrade EXCEPT !.tradeType = one] : one \in Sample(2) }
        \cup { [ZeroReportedTrade EXCEPT !.reserved = one] : one \in Sample(7) }
        \cup { [ZeroReportedTrade EXCEPT !.secondReserved = one] : one \in Sample(7) }

(***************************************************************************)
(* Broken Trade Message: 12 bytes                                          *)
(***************************************************************************)

BrokenTradeMessage ==
    [ timestampNanoseconds : Sample(4),
      matchId              : Sample(8) ]

EncodeBrokenTradeMessage(message) ==
    message.timestampNanoseconds
        \o message.matchId

DecodeBrokenTradeMessage(bytes) ==
    LET timestampNanoseconds == ReadBytes(bytes, 4) IN IF ~timestampNanoseconds.ok THEN Fail ELSE
    LET matchId == ReadBytes(timestampNanoseconds.rest, 8) IN IF ~matchId.ok THEN Fail ELSE
    Ok([ timestampNanoseconds |-> timestampNanoseconds.value,
         matchId              |-> matchId.value ], matchId.rest)

ZeroBrokenTradeMessage ==
    [ timestampNanoseconds |-> [i \in 1 .. 4 |-> 0],
      matchId              |-> [i \in 1 .. 8 |-> 0] ]

(* Broken Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedBrokenTradeMessage ==
    { ZeroBrokenTradeMessage }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.timestampNanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.matchId = one] : one \in Sample(8) }

(***************************************************************************)
(* Open Interest Message: 16 bytes                                         *)
(***************************************************************************)

OpenInterestMessage ==
    [ timestampNanoseconds : Sample(4),
      orderBookId          : Sample(4),
      openInterest         : Sample(8) ]

EncodeOpenInterestMessage(message) ==
    message.timestampNanoseconds
        \o message.orderBookId
        \o message.openInterest

DecodeOpenInterestMessage(bytes) ==
    LET timestampNanoseconds == ReadBytes(bytes, 4) IN IF ~timestampNanoseconds.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(timestampNanoseconds.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET openInterest == ReadBytes(orderBookId.rest, 8) IN IF ~openInterest.ok THEN Fail ELSE
    Ok([ timestampNanoseconds |-> timestampNanoseconds.value,
         orderBookId          |-> orderBookId.value,
         openInterest         |-> openInterest.value ], openInterest.rest)

ZeroOpenInterestMessage ==
    [ timestampNanoseconds |-> [i \in 1 .. 4 |-> 0],
      orderBookId          |-> [i \in 1 .. 4 |-> 0],
      openInterest         |-> [i \in 1 .. 8 |-> 0] ]

(* Open Interest Message at zero, then each field in turn at the values it is checked at *)
CheckedOpenInterestMessage ==
    { ZeroOpenInterestMessage }
        \cup { [ZeroOpenInterestMessage EXCEPT !.timestampNanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOpenInterestMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroOpenInterestMessage EXCEPT !.openInterest = one] : one \in Sample(8) }

(***************************************************************************)
(* Price Message: 13 bytes                                                 *)
(***************************************************************************)

PriceMessage ==
    [ timestampNanoseconds : Sample(4),
      priceType            : Sample(1),
      orderBookId          : Sample(4),
      price                : Sample(4) ]

EncodePriceMessage(message) ==
    message.timestampNanoseconds
        \o message.priceType
        \o message.orderBookId
        \o message.price

DecodePriceMessage(bytes) ==
    LET timestampNanoseconds == ReadBytes(bytes, 4) IN IF ~timestampNanoseconds.ok THEN Fail ELSE
    LET priceType == ReadBytes(timestampNanoseconds.rest, 1) IN IF ~priceType.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(priceType.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET price == ReadBytes(orderBookId.rest, 4) IN IF ~price.ok THEN Fail ELSE
    Ok([ timestampNanoseconds |-> timestampNanoseconds.value,
         priceType            |-> priceType.value,
         orderBookId          |-> orderBookId.value,
         price                |-> price.value ], price.rest)

ZeroPriceMessage ==
    [ timestampNanoseconds |-> [i \in 1 .. 4 |-> 0],
      priceType            |-> [i \in 1 .. 1 |-> 0],
      orderBookId          |-> [i \in 1 .. 4 |-> 0],
      price                |-> [i \in 1 .. 4 |-> 0] ]

(* Price Message at zero, then each field in turn at the values it is checked at *)
CheckedPriceMessage ==
    { ZeroPriceMessage }
        \cup { [ZeroPriceMessage EXCEPT !.timestampNanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroPriceMessage EXCEPT !.priceType = one] : one \in Sample(1) }
        \cup { [ZeroPriceMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroPriceMessage EXCEPT !.price = one] : one \in Sample(4) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

SecondsMessageCode == 84  \* "T"
OrderBookDirectoryCode == 82  \* "R"
CombinationOrderBookLegCode == 77  \* "M"
TickSizeTableEntryCode == 76  \* "L"
SystemEventMessageCode == 83  \* "S"
OrderBookStateMessageCode == 79  \* "O"
ReportedTradeCode == 114  \* "r"
BrokenTradeMessageCode == 66  \* "B"
OpenInterestMessageCode == 111  \* "o"
PriceMessageCode == 112  \* "p"

Payload ==
    [ tag : {SecondsMessageCode}, body : SecondsMessage ]
        \cup [ tag : {OrderBookDirectoryCode}, body : OrderBookDirectory ]
        \cup [ tag : {CombinationOrderBookLegCode}, body : CombinationOrderBookLeg ]
        \cup [ tag : {TickSizeTableEntryCode}, body : TickSizeTableEntry ]
        \cup [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {OrderBookStateMessageCode}, body : OrderBookStateMessage ]
        \cup [ tag : {ReportedTradeCode}, body : ReportedTrade ]
        \cup [ tag : {BrokenTradeMessageCode}, body : BrokenTradeMessage ]
        \cup [ tag : {OpenInterestMessageCode}, body : OpenInterestMessage ]
        \cup [ tag : {PriceMessageCode}, body : PriceMessage ]

EncodePayload(message) ==
    CASE message.tag = SecondsMessageCode -> EncodeSecondsMessage(message.body)
      [] message.tag = OrderBookDirectoryCode -> EncodeOrderBookDirectory(message.body)
      [] message.tag = CombinationOrderBookLegCode -> EncodeCombinationOrderBookLeg(message.body)
      [] message.tag = TickSizeTableEntryCode -> EncodeTickSizeTableEntry(message.body)
      [] message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = OrderBookStateMessageCode -> EncodeOrderBookStateMessage(message.body)
      [] message.tag = ReportedTradeCode -> EncodeReportedTrade(message.body)
      [] message.tag = BrokenTradeMessageCode -> EncodeBrokenTradeMessage(message.body)
      [] message.tag = OpenInterestMessageCode -> EncodeOpenInterestMessage(message.body)
      [] message.tag = PriceMessageCode -> EncodePriceMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = SecondsMessageCode -> DecodeSecondsMessage(bytes)
              [] tag = OrderBookDirectoryCode -> DecodeOrderBookDirectory(bytes)
              [] tag = CombinationOrderBookLegCode -> DecodeCombinationOrderBookLeg(bytes)
              [] tag = TickSizeTableEntryCode -> DecodeTickSizeTableEntry(bytes)
              [] tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = OrderBookStateMessageCode -> DecodeOrderBookStateMessage(bytes)
              [] tag = ReportedTradeCode -> DecodeReportedTrade(bytes)
              [] tag = BrokenTradeMessageCode -> DecodeBrokenTradeMessage(bytes)
              [] tag = OpenInterestMessageCode -> DecodeOpenInterestMessage(bytes)
              [] tag = PriceMessageCode -> DecodePriceMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> SecondsMessageCode, body |-> ZeroSecondsMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> SecondsMessageCode, body |-> one] : one \in CheckedSecondsMessage }
        \cup { [tag |-> OrderBookDirectoryCode, body |-> one] : one \in CheckedOrderBookDirectory }
        \cup { [tag |-> CombinationOrderBookLegCode, body |-> one] : one \in CheckedCombinationOrderBookLeg }
        \cup { [tag |-> TickSizeTableEntryCode, body |-> one] : one \in CheckedTickSizeTableEntry }
        \cup { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> OrderBookStateMessageCode, body |-> one] : one \in CheckedOrderBookStateMessage }
        \cup { [tag |-> ReportedTradeCode, body |-> one] : one \in CheckedReportedTrade }
        \cup { [tag |-> BrokenTradeMessageCode, body |-> one] : one \in CheckedBrokenTradeMessage }
        \cup { [tag |-> OpenInterestMessageCode, body |-> one] : one \in CheckedOpenInterestMessage }
        \cup { [tag |-> PriceMessageCode, body |-> one] : one \in CheckedPriceMessage }

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
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderBookDirectoryCode, body |-> ZeroOrderBookDirectory]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CombinationOrderBookLegCode, body |-> ZeroCombinationOrderBookLeg]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TickSizeTableEntryCode, body |-> ZeroTickSizeTableEntry]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderBookStateMessageCode, body |-> ZeroOrderBookStateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ReportedTradeCode, body |-> ZeroReportedTrade]],
      [ZeroMessage EXCEPT !.payload = [tag |-> BrokenTradeMessageCode, body |-> ZeroBrokenTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OpenInterestMessageCode, body |-> ZeroOpenInterestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> PriceMessageCode, body |-> ZeroPriceMessage]] }

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

(* Every Order Book Directory decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderBookDirectory ==
    \A message \in CheckedOrderBookDirectory :
        LET read == DecodeOrderBookDirectory(EncodeOrderBookDirectory(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Combination Order Book Leg decodes back to what was encoded, and leaves nothing over *)
RoundTripCombinationOrderBookLeg ==
    \A message \in CheckedCombinationOrderBookLeg :
        LET read == DecodeCombinationOrderBookLeg(EncodeCombinationOrderBookLeg(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tick Size Table Entry decodes back to what was encoded, and leaves nothing over *)
RoundTripTickSizeTableEntry ==
    \A message \in CheckedTickSizeTableEntry :
        LET read == DecodeTickSizeTableEntry(EncodeTickSizeTableEntry(message))
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

(* Every Order Book State Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderBookStateMessage ==
    \A message \in CheckedOrderBookStateMessage :
        LET read == DecodeOrderBookStateMessage(EncodeOrderBookStateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reported Trade decodes back to what was encoded, and leaves nothing over *)
RoundTripReportedTrade ==
    \A message \in CheckedReportedTrade :
        LET read == DecodeReportedTrade(EncodeReportedTrade(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Broken Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBrokenTradeMessage ==
    \A message \in CheckedBrokenTradeMessage :
        LET read == DecodeBrokenTradeMessage(EncodeBrokenTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Open Interest Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOpenInterestMessage ==
    \A message \in CheckedOpenInterestMessage :
        LET read == DecodeOpenInterestMessage(EncodeOpenInterestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPriceMessage ==
    \A message \in CheckedPriceMessage :
        LET read == DecodePriceMessage(EncodePriceMessage(message))
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
