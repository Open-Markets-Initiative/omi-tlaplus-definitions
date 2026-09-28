--------------- MODULE NordicDerivatives_MarketData_v2_28_7 ----------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Genium INET Auxiliary Market Data v2.28.7                      *)
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
(* Order Book Directory: 153 bytes                                         *)
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
      notationDate                   : Sample(4),
      firstTradingDateAndTime        : Sample(8),
      lastTradingDateAndTime         : Sample(8),
      countryId                      : Sample(1),
      marketId                       : Sample(1),
      physicalDelivery               : Sample(1),
      optionStyle                    : Sample(2) ]

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
        \o message.notationDate
        \o message.firstTradingDateAndTime
        \o message.lastTradingDateAndTime
        \o message.countryId
        \o message.marketId
        \o message.physicalDelivery
        \o message.optionStyle

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
    LET notationDate == ReadBytes(putOrCall.rest, 4) IN IF ~notationDate.ok THEN Fail ELSE
    LET firstTradingDateAndTime == ReadBytes(notationDate.rest, 8) IN IF ~firstTradingDateAndTime.ok THEN Fail ELSE
    LET lastTradingDateAndTime == ReadBytes(firstTradingDateAndTime.rest, 8) IN IF ~lastTradingDateAndTime.ok THEN Fail ELSE
    LET countryId == ReadBytes(lastTradingDateAndTime.rest, 1) IN IF ~countryId.ok THEN Fail ELSE
    LET marketId == ReadBytes(countryId.rest, 1) IN IF ~marketId.ok THEN Fail ELSE
    LET physicalDelivery == ReadBytes(marketId.rest, 1) IN IF ~physicalDelivery.ok THEN Fail ELSE
    LET optionStyle == ReadBytes(physicalDelivery.rest, 2) IN IF ~optionStyle.ok THEN Fail ELSE
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
         notationDate                   |-> notationDate.value,
         firstTradingDateAndTime        |-> firstTradingDateAndTime.value,
         lastTradingDateAndTime         |-> lastTradingDateAndTime.value,
         countryId                      |-> countryId.value,
         marketId                       |-> marketId.value,
         physicalDelivery               |-> physicalDelivery.value,
         optionStyle                    |-> optionStyle.value ], optionStyle.rest)

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
      notationDate                   |-> [i \in 1 .. 4 |-> 0],
      firstTradingDateAndTime        |-> [i \in 1 .. 8 |-> 0],
      lastTradingDateAndTime         |-> [i \in 1 .. 8 |-> 0],
      countryId                      |-> [i \in 1 .. 1 |-> 0],
      marketId                       |-> [i \in 1 .. 1 |-> 0],
      physicalDelivery               |-> [i \in 1 .. 1 |-> 0],
      optionStyle                    |-> [i \in 1 .. 2 |-> 0] ]

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
        \cup { [ZeroOrderBookDirectory EXCEPT !.notationDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.firstTradingDateAndTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.lastTradingDateAndTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.countryId = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.marketId = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.physicalDelivery = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.optionStyle = one] : one \in Sample(2) }

(***************************************************************************)
(* Market Directory: 38 bytes                                              *)
(***************************************************************************)

MarketDirectory ==
    [ timestampNanoseconds : Sample(4),
      countryId            : Sample(1),
      marketId             : Sample(1),
      marketName           : Sample(32) ]

EncodeMarketDirectory(message) ==
    message.timestampNanoseconds
        \o message.countryId
        \o message.marketId
        \o message.marketName

DecodeMarketDirectory(bytes) ==
    LET timestampNanoseconds == ReadBytes(bytes, 4) IN IF ~timestampNanoseconds.ok THEN Fail ELSE
    LET countryId == ReadBytes(timestampNanoseconds.rest, 1) IN IF ~countryId.ok THEN Fail ELSE
    LET marketId == ReadBytes(countryId.rest, 1) IN IF ~marketId.ok THEN Fail ELSE
    LET marketName == ReadBytes(marketId.rest, 32) IN IF ~marketName.ok THEN Fail ELSE
    Ok([ timestampNanoseconds |-> timestampNanoseconds.value,
         countryId            |-> countryId.value,
         marketId             |-> marketId.value,
         marketName           |-> marketName.value ], marketName.rest)

ZeroMarketDirectory ==
    [ timestampNanoseconds |-> [i \in 1 .. 4 |-> 0],
      countryId            |-> [i \in 1 .. 1 |-> 0],
      marketId             |-> [i \in 1 .. 1 |-> 0],
      marketName           |-> [i \in 1 .. 32 |-> 0] ]

(* Market Directory at zero, then each field in turn at the values it is checked at *)
CheckedMarketDirectory ==
    { ZeroMarketDirectory }
        \cup { [ZeroMarketDirectory EXCEPT !.timestampNanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroMarketDirectory EXCEPT !.countryId = one] : one \in Sample(1) }
        \cup { [ZeroMarketDirectory EXCEPT !.marketId = one] : one \in Sample(1) }
        \cup { [ZeroMarketDirectory EXCEPT !.marketName = one] : one \in Sample(32) }

(***************************************************************************)
(* Combination Order Book Leg Directory: 17 bytes                          *)
(***************************************************************************)

CombinationOrderBookLegDirectory ==
    [ timestampNanoseconds   : Sample(4),
      combinationOrderBookId : Sample(4),
      legOrderBookId         : Sample(4),
      legSide                : Sample(1),
      legRatio               : Sample(4) ]

EncodeCombinationOrderBookLegDirectory(message) ==
    message.timestampNanoseconds
        \o message.combinationOrderBookId
        \o message.legOrderBookId
        \o message.legSide
        \o message.legRatio

DecodeCombinationOrderBookLegDirectory(bytes) ==
    LET timestampNanoseconds == ReadBytes(bytes, 4) IN IF ~timestampNanoseconds.ok THEN Fail ELSE
    LET combinationOrderBookId == ReadBytes(timestampNanoseconds.rest, 4) IN IF ~combinationOrderBookId.ok THEN Fail ELSE
    LET legOrderBookId == ReadBytes(combinationOrderBookId.rest, 4) IN IF ~legOrderBookId.ok THEN Fail ELSE
    LET legSide == ReadBytes(legOrderBookId.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET legRatio == ReadBytes(legSide.rest, 4) IN IF ~legRatio.ok THEN Fail ELSE
    Ok([ timestampNanoseconds   |-> timestampNanoseconds.value,
         combinationOrderBookId |-> combinationOrderBookId.value,
         legOrderBookId         |-> legOrderBookId.value,
         legSide                |-> legSide.value,
         legRatio               |-> legRatio.value ], legRatio.rest)

ZeroCombinationOrderBookLegDirectory ==
    [ timestampNanoseconds   |-> [i \in 1 .. 4 |-> 0],
      combinationOrderBookId |-> [i \in 1 .. 4 |-> 0],
      legOrderBookId         |-> [i \in 1 .. 4 |-> 0],
      legSide                |-> [i \in 1 .. 1 |-> 0],
      legRatio               |-> [i \in 1 .. 4 |-> 0] ]

(* Combination Order Book Leg Directory at zero, then each field in turn at the values it is checked at *)
CheckedCombinationOrderBookLegDirectory ==
    { ZeroCombinationOrderBookLegDirectory }
        \cup { [ZeroCombinationOrderBookLegDirectory EXCEPT !.timestampNanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroCombinationOrderBookLegDirectory EXCEPT !.combinationOrderBookId = one] : one \in Sample(4) }
        \cup { [ZeroCombinationOrderBookLegDirectory EXCEPT !.legOrderBookId = one] : one \in Sample(4) }
        \cup { [ZeroCombinationOrderBookLegDirectory EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroCombinationOrderBookLegDirectory EXCEPT !.legRatio = one] : one \in Sample(4) }

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
      reservedAlpha7           : Sample(7),
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
        \o message.reservedAlpha7
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
    LET reservedAlpha7 == ReadBytes(tradeType.rest, 7) IN IF ~reservedAlpha7.ok THEN Fail ELSE
    LET secondReserved == ReadBytes(reservedAlpha7.rest, 7) IN IF ~secondReserved.ok THEN Fail ELSE
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
         reservedAlpha7           |-> reservedAlpha7.value,
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
      reservedAlpha7           |-> [i \in 1 .. 7 |-> 0],
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
        \cup { [ZeroReportedTrade EXCEPT !.reservedAlpha7 = one] : one \in Sample(7) }
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
(* Quote Request Message: 30 bytes                                         *)
(***************************************************************************)

QuoteRequestMessage ==
    [ timestampNanoseconds : Sample(4),
      orderBookId          : Sample(4),
      reservedAlpha7       : Sample(7),
      reservedAlpha5       : Sample(5),
      reservedAlpha1       : Sample(1),
      side                 : Sample(1),
      quantity             : Sample(8) ]

EncodeQuoteRequestMessage(message) ==
    message.timestampNanoseconds
        \o message.orderBookId
        \o message.reservedAlpha7
        \o message.reservedAlpha5
        \o message.reservedAlpha1
        \o message.side
        \o message.quantity

DecodeQuoteRequestMessage(bytes) ==
    LET timestampNanoseconds == ReadBytes(bytes, 4) IN IF ~timestampNanoseconds.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(timestampNanoseconds.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET reservedAlpha7 == ReadBytes(orderBookId.rest, 7) IN IF ~reservedAlpha7.ok THEN Fail ELSE
    LET reservedAlpha5 == ReadBytes(reservedAlpha7.rest, 5) IN IF ~reservedAlpha5.ok THEN Fail ELSE
    LET reservedAlpha1 == ReadBytes(reservedAlpha5.rest, 1) IN IF ~reservedAlpha1.ok THEN Fail ELSE
    LET side == ReadBytes(reservedAlpha1.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET quantity == ReadBytes(side.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    Ok([ timestampNanoseconds |-> timestampNanoseconds.value,
         orderBookId          |-> orderBookId.value,
         reservedAlpha7       |-> reservedAlpha7.value,
         reservedAlpha5       |-> reservedAlpha5.value,
         reservedAlpha1       |-> reservedAlpha1.value,
         side                 |-> side.value,
         quantity             |-> quantity.value ], quantity.rest)

ZeroQuoteRequestMessage ==
    [ timestampNanoseconds |-> [i \in 1 .. 4 |-> 0],
      orderBookId          |-> [i \in 1 .. 4 |-> 0],
      reservedAlpha7       |-> [i \in 1 .. 7 |-> 0],
      reservedAlpha5       |-> [i \in 1 .. 5 |-> 0],
      reservedAlpha1       |-> [i \in 1 .. 1 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      quantity             |-> [i \in 1 .. 8 |-> 0] ]

(* Quote Request Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteRequestMessage ==
    { ZeroQuoteRequestMessage }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.timestampNanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.reservedAlpha7 = one] : one \in Sample(7) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.reservedAlpha5 = one] : one \in Sample(5) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.reservedAlpha1 = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.quantity = one] : one \in Sample(8) }

(***************************************************************************)
(* Open Interest Messsage: 20 bytes                                        *)
(***************************************************************************)

OpenInterestMesssage ==
    [ timestampNanoseconds : Sample(4),
      orderBookId          : Sample(4),
      openInterest         : Sample(8),
      previousTradingDate  : Sample(4) ]

EncodeOpenInterestMesssage(message) ==
    message.timestampNanoseconds
        \o message.orderBookId
        \o message.openInterest
        \o message.previousTradingDate

DecodeOpenInterestMesssage(bytes) ==
    LET timestampNanoseconds == ReadBytes(bytes, 4) IN IF ~timestampNanoseconds.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(timestampNanoseconds.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET openInterest == ReadBytes(orderBookId.rest, 8) IN IF ~openInterest.ok THEN Fail ELSE
    LET previousTradingDate == ReadBytes(openInterest.rest, 4) IN IF ~previousTradingDate.ok THEN Fail ELSE
    Ok([ timestampNanoseconds |-> timestampNanoseconds.value,
         orderBookId          |-> orderBookId.value,
         openInterest         |-> openInterest.value,
         previousTradingDate  |-> previousTradingDate.value ], previousTradingDate.rest)

ZeroOpenInterestMesssage ==
    [ timestampNanoseconds |-> [i \in 1 .. 4 |-> 0],
      orderBookId          |-> [i \in 1 .. 4 |-> 0],
      openInterest         |-> [i \in 1 .. 8 |-> 0],
      previousTradingDate  |-> [i \in 1 .. 4 |-> 0] ]

(* Open Interest Messsage at zero, then each field in turn at the values it is checked at *)
CheckedOpenInterestMesssage ==
    { ZeroOpenInterestMesssage }
        \cup { [ZeroOpenInterestMesssage EXCEPT !.timestampNanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOpenInterestMesssage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroOpenInterestMesssage EXCEPT !.openInterest = one] : one \in Sample(8) }
        \cup { [ZeroOpenInterestMesssage EXCEPT !.previousTradingDate = one] : one \in Sample(4) }

(***************************************************************************)
(* Price Message: 14 bytes                                                 *)
(***************************************************************************)

PriceMessage ==
    [ timestampNanoseconds : Sample(4),
      priceType            : Sample(1),
      orderBookId          : Sample(4),
      pricePrice4          : Sample(4),
      priceSource          : Sample(1) ]

EncodePriceMessage(message) ==
    message.timestampNanoseconds
        \o message.priceType
        \o message.orderBookId
        \o message.pricePrice4
        \o message.priceSource

DecodePriceMessage(bytes) ==
    LET timestampNanoseconds == ReadBytes(bytes, 4) IN IF ~timestampNanoseconds.ok THEN Fail ELSE
    LET priceType == ReadBytes(timestampNanoseconds.rest, 1) IN IF ~priceType.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(priceType.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET pricePrice4 == ReadBytes(orderBookId.rest, 4) IN IF ~pricePrice4.ok THEN Fail ELSE
    LET priceSource == ReadBytes(pricePrice4.rest, 1) IN IF ~priceSource.ok THEN Fail ELSE
    Ok([ timestampNanoseconds |-> timestampNanoseconds.value,
         priceType            |-> priceType.value,
         orderBookId          |-> orderBookId.value,
         pricePrice4          |-> pricePrice4.value,
         priceSource          |-> priceSource.value ], priceSource.rest)

ZeroPriceMessage ==
    [ timestampNanoseconds |-> [i \in 1 .. 4 |-> 0],
      priceType            |-> [i \in 1 .. 1 |-> 0],
      orderBookId          |-> [i \in 1 .. 4 |-> 0],
      pricePrice4          |-> [i \in 1 .. 4 |-> 0],
      priceSource          |-> [i \in 1 .. 1 |-> 0] ]

(* Price Message at zero, then each field in turn at the values it is checked at *)
CheckedPriceMessage ==
    { ZeroPriceMessage }
        \cup { [ZeroPriceMessage EXCEPT !.timestampNanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroPriceMessage EXCEPT !.priceType = one] : one \in Sample(1) }
        \cup { [ZeroPriceMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroPriceMessage EXCEPT !.pricePrice4 = one] : one \in Sample(4) }
        \cup { [ZeroPriceMessage EXCEPT !.priceSource = one] : one \in Sample(1) }

(***************************************************************************)
(* Market By Level Message: 27 bytes                                       *)
(***************************************************************************)

MarketByLevelMessage ==
    [ timestampNanoseconds : Sample(4),
      orderBookId          : Sample(4),
      lastMessage          : Sample(1),
      levelUpdateAction    : Sample(1),
      maxDepth             : Sample(2),
      levelUpdate          : Sample(2),
      entryType            : Sample(1),
      marketByLevelPrice   : Sample(4),
      quantity             : Sample(8) ]

EncodeMarketByLevelMessage(message) ==
    message.timestampNanoseconds
        \o message.orderBookId
        \o message.lastMessage
        \o message.levelUpdateAction
        \o message.maxDepth
        \o message.levelUpdate
        \o message.entryType
        \o message.marketByLevelPrice
        \o message.quantity

DecodeMarketByLevelMessage(bytes) ==
    LET timestampNanoseconds == ReadBytes(bytes, 4) IN IF ~timestampNanoseconds.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(timestampNanoseconds.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET lastMessage == ReadBytes(orderBookId.rest, 1) IN IF ~lastMessage.ok THEN Fail ELSE
    LET levelUpdateAction == ReadBytes(lastMessage.rest, 1) IN IF ~levelUpdateAction.ok THEN Fail ELSE
    LET maxDepth == ReadBytes(levelUpdateAction.rest, 2) IN IF ~maxDepth.ok THEN Fail ELSE
    LET levelUpdate == ReadBytes(maxDepth.rest, 2) IN IF ~levelUpdate.ok THEN Fail ELSE
    LET entryType == ReadBytes(levelUpdate.rest, 1) IN IF ~entryType.ok THEN Fail ELSE
    LET marketByLevelPrice == ReadBytes(entryType.rest, 4) IN IF ~marketByLevelPrice.ok THEN Fail ELSE
    LET quantity == ReadBytes(marketByLevelPrice.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    Ok([ timestampNanoseconds |-> timestampNanoseconds.value,
         orderBookId          |-> orderBookId.value,
         lastMessage          |-> lastMessage.value,
         levelUpdateAction    |-> levelUpdateAction.value,
         maxDepth             |-> maxDepth.value,
         levelUpdate          |-> levelUpdate.value,
         entryType            |-> entryType.value,
         marketByLevelPrice   |-> marketByLevelPrice.value,
         quantity             |-> quantity.value ], quantity.rest)

ZeroMarketByLevelMessage ==
    [ timestampNanoseconds |-> [i \in 1 .. 4 |-> 0],
      orderBookId          |-> [i \in 1 .. 4 |-> 0],
      lastMessage          |-> [i \in 1 .. 1 |-> 0],
      levelUpdateAction    |-> [i \in 1 .. 1 |-> 0],
      maxDepth             |-> [i \in 1 .. 2 |-> 0],
      levelUpdate          |-> [i \in 1 .. 2 |-> 0],
      entryType            |-> [i \in 1 .. 1 |-> 0],
      marketByLevelPrice   |-> [i \in 1 .. 4 |-> 0],
      quantity             |-> [i \in 1 .. 8 |-> 0] ]

(* Market By Level Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketByLevelMessage ==
    { ZeroMarketByLevelMessage }
        \cup { [ZeroMarketByLevelMessage EXCEPT !.timestampNanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroMarketByLevelMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroMarketByLevelMessage EXCEPT !.lastMessage = one] : one \in Sample(1) }
        \cup { [ZeroMarketByLevelMessage EXCEPT !.levelUpdateAction = one] : one \in Sample(1) }
        \cup { [ZeroMarketByLevelMessage EXCEPT !.maxDepth = one] : one \in Sample(2) }
        \cup { [ZeroMarketByLevelMessage EXCEPT !.levelUpdate = one] : one \in Sample(2) }
        \cup { [ZeroMarketByLevelMessage EXCEPT !.entryType = one] : one \in Sample(1) }
        \cup { [ZeroMarketByLevelMessage EXCEPT !.marketByLevelPrice = one] : one \in Sample(4) }
        \cup { [ZeroMarketByLevelMessage EXCEPT !.quantity = one] : one \in Sample(8) }

(***************************************************************************)
(* Underlying Price Message: 60 bytes                                      *)
(***************************************************************************)

UnderlyingPriceMessage ==
    [ timestampNanoseconds  : Sample(4),
      underlyingOrderBookId : Sample(4),
      bidPrice              : Sample(4),
      askPrice              : Sample(4),
      closingPrice          : Sample(4),
      openingPrice          : Sample(4),
      highPrice             : Sample(4),
      lowPrice              : Sample(4),
      lastPrice             : Sample(4),
      turnover              : Sample(8),
      bestBidVolume         : Sample(8),
      bestAskVolume         : Sample(8) ]

EncodeUnderlyingPriceMessage(message) ==
    message.timestampNanoseconds
        \o message.underlyingOrderBookId
        \o message.bidPrice
        \o message.askPrice
        \o message.closingPrice
        \o message.openingPrice
        \o message.highPrice
        \o message.lowPrice
        \o message.lastPrice
        \o message.turnover
        \o message.bestBidVolume
        \o message.bestAskVolume

DecodeUnderlyingPriceMessage(bytes) ==
    LET timestampNanoseconds == ReadBytes(bytes, 4) IN IF ~timestampNanoseconds.ok THEN Fail ELSE
    LET underlyingOrderBookId == ReadBytes(timestampNanoseconds.rest, 4) IN IF ~underlyingOrderBookId.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(underlyingOrderBookId.rest, 4) IN IF ~bidPrice.ok THEN Fail ELSE
    LET askPrice == ReadBytes(bidPrice.rest, 4) IN IF ~askPrice.ok THEN Fail ELSE
    LET closingPrice == ReadBytes(askPrice.rest, 4) IN IF ~closingPrice.ok THEN Fail ELSE
    LET openingPrice == ReadBytes(closingPrice.rest, 4) IN IF ~openingPrice.ok THEN Fail ELSE
    LET highPrice == ReadBytes(openingPrice.rest, 4) IN IF ~highPrice.ok THEN Fail ELSE
    LET lowPrice == ReadBytes(highPrice.rest, 4) IN IF ~lowPrice.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(lowPrice.rest, 4) IN IF ~lastPrice.ok THEN Fail ELSE
    LET turnover == ReadBytes(lastPrice.rest, 8) IN IF ~turnover.ok THEN Fail ELSE
    LET bestBidVolume == ReadBytes(turnover.rest, 8) IN IF ~bestBidVolume.ok THEN Fail ELSE
    LET bestAskVolume == ReadBytes(bestBidVolume.rest, 8) IN IF ~bestAskVolume.ok THEN Fail ELSE
    Ok([ timestampNanoseconds  |-> timestampNanoseconds.value,
         underlyingOrderBookId |-> underlyingOrderBookId.value,
         bidPrice              |-> bidPrice.value,
         askPrice              |-> askPrice.value,
         closingPrice          |-> closingPrice.value,
         openingPrice          |-> openingPrice.value,
         highPrice             |-> highPrice.value,
         lowPrice              |-> lowPrice.value,
         lastPrice             |-> lastPrice.value,
         turnover              |-> turnover.value,
         bestBidVolume         |-> bestBidVolume.value,
         bestAskVolume         |-> bestAskVolume.value ], bestAskVolume.rest)

ZeroUnderlyingPriceMessage ==
    [ timestampNanoseconds  |-> [i \in 1 .. 4 |-> 0],
      underlyingOrderBookId |-> [i \in 1 .. 4 |-> 0],
      bidPrice              |-> [i \in 1 .. 4 |-> 0],
      askPrice              |-> [i \in 1 .. 4 |-> 0],
      closingPrice          |-> [i \in 1 .. 4 |-> 0],
      openingPrice          |-> [i \in 1 .. 4 |-> 0],
      highPrice             |-> [i \in 1 .. 4 |-> 0],
      lowPrice              |-> [i \in 1 .. 4 |-> 0],
      lastPrice             |-> [i \in 1 .. 4 |-> 0],
      turnover              |-> [i \in 1 .. 8 |-> 0],
      bestBidVolume         |-> [i \in 1 .. 8 |-> 0],
      bestAskVolume         |-> [i \in 1 .. 8 |-> 0] ]

(* Underlying Price Message at zero, then each field in turn at the values it is checked at *)
CheckedUnderlyingPriceMessage ==
    { ZeroUnderlyingPriceMessage }
        \cup { [ZeroUnderlyingPriceMessage EXCEPT !.timestampNanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingPriceMessage EXCEPT !.underlyingOrderBookId = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingPriceMessage EXCEPT !.bidPrice = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingPriceMessage EXCEPT !.askPrice = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingPriceMessage EXCEPT !.closingPrice = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingPriceMessage EXCEPT !.openingPrice = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingPriceMessage EXCEPT !.highPrice = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingPriceMessage EXCEPT !.lowPrice = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingPriceMessage EXCEPT !.lastPrice = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingPriceMessage EXCEPT !.turnover = one] : one \in Sample(8) }
        \cup { [ZeroUnderlyingPriceMessage EXCEPT !.bestBidVolume = one] : one \in Sample(8) }
        \cup { [ZeroUnderlyingPriceMessage EXCEPT !.bestAskVolume = one] : one \in Sample(8) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

SecondsMessageCode == 84  \* "T"
OrderBookDirectoryCode == 82  \* "R"
MarketDirectoryCode == 86  \* "V"
CombinationOrderBookLegDirectoryCode == 77  \* "M"
TickSizeTableEntryCode == 76  \* "L"
SystemEventMessageCode == 83  \* "S"
ReportedTradeCode == 114  \* "r"
BrokenTradeMessageCode == 66  \* "B"
QuoteRequestMessageCode == 113  \* "q"
OpenInterestMesssageCode == 111  \* "o"
PriceMessageCode == 112  \* "p"
MarketByLevelMessageCode == 87  \* "W"
UnderlyingPriceMessageCode == 85  \* "U"

Payload ==
    [ tag : {SecondsMessageCode}, body : SecondsMessage ]
        \cup [ tag : {OrderBookDirectoryCode}, body : OrderBookDirectory ]
        \cup [ tag : {MarketDirectoryCode}, body : MarketDirectory ]
        \cup [ tag : {CombinationOrderBookLegDirectoryCode}, body : CombinationOrderBookLegDirectory ]
        \cup [ tag : {TickSizeTableEntryCode}, body : TickSizeTableEntry ]
        \cup [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {ReportedTradeCode}, body : ReportedTrade ]
        \cup [ tag : {BrokenTradeMessageCode}, body : BrokenTradeMessage ]
        \cup [ tag : {QuoteRequestMessageCode}, body : QuoteRequestMessage ]
        \cup [ tag : {OpenInterestMesssageCode}, body : OpenInterestMesssage ]
        \cup [ tag : {PriceMessageCode}, body : PriceMessage ]
        \cup [ tag : {MarketByLevelMessageCode}, body : MarketByLevelMessage ]
        \cup [ tag : {UnderlyingPriceMessageCode}, body : UnderlyingPriceMessage ]

EncodePayload(message) ==
    CASE message.tag = SecondsMessageCode -> EncodeSecondsMessage(message.body)
      [] message.tag = OrderBookDirectoryCode -> EncodeOrderBookDirectory(message.body)
      [] message.tag = MarketDirectoryCode -> EncodeMarketDirectory(message.body)
      [] message.tag = CombinationOrderBookLegDirectoryCode -> EncodeCombinationOrderBookLegDirectory(message.body)
      [] message.tag = TickSizeTableEntryCode -> EncodeTickSizeTableEntry(message.body)
      [] message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = ReportedTradeCode -> EncodeReportedTrade(message.body)
      [] message.tag = BrokenTradeMessageCode -> EncodeBrokenTradeMessage(message.body)
      [] message.tag = QuoteRequestMessageCode -> EncodeQuoteRequestMessage(message.body)
      [] message.tag = OpenInterestMesssageCode -> EncodeOpenInterestMesssage(message.body)
      [] message.tag = PriceMessageCode -> EncodePriceMessage(message.body)
      [] message.tag = MarketByLevelMessageCode -> EncodeMarketByLevelMessage(message.body)
      [] message.tag = UnderlyingPriceMessageCode -> EncodeUnderlyingPriceMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = SecondsMessageCode -> DecodeSecondsMessage(bytes)
              [] tag = OrderBookDirectoryCode -> DecodeOrderBookDirectory(bytes)
              [] tag = MarketDirectoryCode -> DecodeMarketDirectory(bytes)
              [] tag = CombinationOrderBookLegDirectoryCode -> DecodeCombinationOrderBookLegDirectory(bytes)
              [] tag = TickSizeTableEntryCode -> DecodeTickSizeTableEntry(bytes)
              [] tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = ReportedTradeCode -> DecodeReportedTrade(bytes)
              [] tag = BrokenTradeMessageCode -> DecodeBrokenTradeMessage(bytes)
              [] tag = QuoteRequestMessageCode -> DecodeQuoteRequestMessage(bytes)
              [] tag = OpenInterestMesssageCode -> DecodeOpenInterestMesssage(bytes)
              [] tag = PriceMessageCode -> DecodePriceMessage(bytes)
              [] tag = MarketByLevelMessageCode -> DecodeMarketByLevelMessage(bytes)
              [] tag = UnderlyingPriceMessageCode -> DecodeUnderlyingPriceMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> SecondsMessageCode, body |-> ZeroSecondsMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> SecondsMessageCode, body |-> one] : one \in CheckedSecondsMessage }
        \cup { [tag |-> OrderBookDirectoryCode, body |-> one] : one \in CheckedOrderBookDirectory }
        \cup { [tag |-> MarketDirectoryCode, body |-> one] : one \in CheckedMarketDirectory }
        \cup { [tag |-> CombinationOrderBookLegDirectoryCode, body |-> one] : one \in CheckedCombinationOrderBookLegDirectory }
        \cup { [tag |-> TickSizeTableEntryCode, body |-> one] : one \in CheckedTickSizeTableEntry }
        \cup { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> ReportedTradeCode, body |-> one] : one \in CheckedReportedTrade }
        \cup { [tag |-> BrokenTradeMessageCode, body |-> one] : one \in CheckedBrokenTradeMessage }
        \cup { [tag |-> QuoteRequestMessageCode, body |-> one] : one \in CheckedQuoteRequestMessage }
        \cup { [tag |-> OpenInterestMesssageCode, body |-> one] : one \in CheckedOpenInterestMesssage }
        \cup { [tag |-> PriceMessageCode, body |-> one] : one \in CheckedPriceMessage }
        \cup { [tag |-> MarketByLevelMessageCode, body |-> one] : one \in CheckedMarketByLevelMessage }
        \cup { [tag |-> UnderlyingPriceMessageCode, body |-> one] : one \in CheckedUnderlyingPriceMessage }

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
      [ZeroMessage EXCEPT !.payload = [tag |-> MarketDirectoryCode, body |-> ZeroMarketDirectory]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CombinationOrderBookLegDirectoryCode, body |-> ZeroCombinationOrderBookLegDirectory]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TickSizeTableEntryCode, body |-> ZeroTickSizeTableEntry]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ReportedTradeCode, body |-> ZeroReportedTrade]],
      [ZeroMessage EXCEPT !.payload = [tag |-> BrokenTradeMessageCode, body |-> ZeroBrokenTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> QuoteRequestMessageCode, body |-> ZeroQuoteRequestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OpenInterestMesssageCode, body |-> ZeroOpenInterestMesssage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> PriceMessageCode, body |-> ZeroPriceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MarketByLevelMessageCode, body |-> ZeroMarketByLevelMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> UnderlyingPriceMessageCode, body |-> ZeroUnderlyingPriceMessage]] }

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

(* Every Market Directory decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketDirectory ==
    \A message \in CheckedMarketDirectory :
        LET read == DecodeMarketDirectory(EncodeMarketDirectory(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Combination Order Book Leg Directory decodes back to what was encoded, and leaves nothing over *)
RoundTripCombinationOrderBookLegDirectory ==
    \A message \in CheckedCombinationOrderBookLegDirectory :
        LET read == DecodeCombinationOrderBookLegDirectory(EncodeCombinationOrderBookLegDirectory(message))
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

(* Every Quote Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteRequestMessage ==
    \A message \in CheckedQuoteRequestMessage :
        LET read == DecodeQuoteRequestMessage(EncodeQuoteRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Open Interest Messsage decodes back to what was encoded, and leaves nothing over *)
RoundTripOpenInterestMesssage ==
    \A message \in CheckedOpenInterestMesssage :
        LET read == DecodeOpenInterestMesssage(EncodeOpenInterestMesssage(message))
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

(* Every Market By Level Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketByLevelMessage ==
    \A message \in CheckedMarketByLevelMessage :
        LET read == DecodeMarketByLevelMessage(EncodeMarketByLevelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Underlying Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUnderlyingPriceMessage ==
    \A message \in CheckedUnderlyingPriceMessage :
        LET read == DecodeUnderlyingPriceMessage(EncodeUnderlyingPriceMessage(message))
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
