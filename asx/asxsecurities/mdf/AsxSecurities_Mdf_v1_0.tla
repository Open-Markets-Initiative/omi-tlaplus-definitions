---------------------- MODULE AsxSecurities_Mdf_v1_0 -----------------------
(***************************************************************************)
(* Australian Securities Exchange Trade Market Data Feed v1.0              *)
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
(* License: MIT No Attribution                                             *)
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
(* Order Book Directory Message: 366 bytes                                 *)
(***************************************************************************)

OrderBookDirectoryMessage ==
    [ timestampNanoseconds              : Sample(4),
      orderBookId                       : Sample(4),
      partitionId                       : Sample(1),
      symbol                            : Sample(32),
      longName                          : Sample(32),
      isin                              : Sample(12),
      assetName                         : Sample(32),
      financialProduct                  : Sample(1),
      tradingCurrency                   : Sample(3),
      numberOfDecimalsInPrice           : Sample(2),
      numberOfDecimalsInNominalValue    : Sample(2),
      roundLotSize                      : Sample(4),
      nominalValue                      : Sample(8),
      numberOfLegs                      : Sample(1),
      commodityCode                     : Sample(4),
      strikePrice                       : Sample(8),
      expirationDate                    : Sample(4),
      numberOfDecimalsInStrikePrice     : Sample(2),
      optionType                        : Sample(1),
      marketId                          : Sample(4),
      exchangeId                        : Sample(4),
      numberOfDecimalsIn                : Sample(2),
      sectorCode                        : Sample(4),
      numberOfTradableEquities          : Sample(8),
      numberOfOutstandingEquities       : Sample(8),
      lastTradedDate                    : Sample(4),
      contractMultiplier                : Sample(8),
      multiplier                        : Sample(8),
      decimalsInMultiplier              : Sample(2),
      minOrderQuantity                  : Sample(8),
      maxOrderQuantity                  : Sample(8),
      numberOfSettlementDays            : Sample(4),
      primary                           : Sample(1),
      testOrderBook                     : Sample(1),
      aliasName                         : Sample(32),
      settlementDate                    : Sample(4),
      tradable                          : Sample(1),
      externallyPriceSourced            : Sample(1),
      deliverable                       : Sample(1),
      priceUnit                         : Sample(1),
      issuer                            : Sample(32),
      foreignOwnershipRestriction       : Sample(1),
      lastTradingTime                   : Sample(6),
      optionStyle                       : Sample(1),
      minimumValueForInitialTradeReport : Sample(8),
      cfiCode                           : Sample(6),
      upperLevelSeries                  : Sample(32),
      upperSeriesLevelOrderBookId       : Sample(4),
      instrumentType                    : Sample(4),
      status                            : Sample(1) ]

EncodeOrderBookDirectoryMessage(message) ==
    message.timestampNanoseconds
        \o message.orderBookId
        \o message.partitionId
        \o message.symbol
        \o message.longName
        \o message.isin
        \o message.assetName
        \o message.financialProduct
        \o message.tradingCurrency
        \o message.numberOfDecimalsInPrice
        \o message.numberOfDecimalsInNominalValue
        \o message.roundLotSize
        \o message.nominalValue
        \o message.numberOfLegs
        \o message.commodityCode
        \o message.strikePrice
        \o message.expirationDate
        \o message.numberOfDecimalsInStrikePrice
        \o message.optionType
        \o message.marketId
        \o message.exchangeId
        \o message.numberOfDecimalsIn
        \o message.sectorCode
        \o message.numberOfTradableEquities
        \o message.numberOfOutstandingEquities
        \o message.lastTradedDate
        \o message.contractMultiplier
        \o message.multiplier
        \o message.decimalsInMultiplier
        \o message.minOrderQuantity
        \o message.maxOrderQuantity
        \o message.numberOfSettlementDays
        \o message.primary
        \o message.testOrderBook
        \o message.aliasName
        \o message.settlementDate
        \o message.tradable
        \o message.externallyPriceSourced
        \o message.deliverable
        \o message.priceUnit
        \o message.issuer
        \o message.foreignOwnershipRestriction
        \o message.lastTradingTime
        \o message.optionStyle
        \o message.minimumValueForInitialTradeReport
        \o message.cfiCode
        \o message.upperLevelSeries
        \o message.upperSeriesLevelOrderBookId
        \o message.instrumentType
        \o message.status

DecodeOrderBookDirectoryMessage(bytes) ==
    LET timestampNanoseconds == ReadBytes(bytes, 4) IN IF ~timestampNanoseconds.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(timestampNanoseconds.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET partitionId == ReadBytes(orderBookId.rest, 1) IN IF ~partitionId.ok THEN Fail ELSE
    LET symbol == ReadBytes(partitionId.rest, 32) IN IF ~symbol.ok THEN Fail ELSE
    LET longName == ReadBytes(symbol.rest, 32) IN IF ~longName.ok THEN Fail ELSE
    LET isin == ReadBytes(longName.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET assetName == ReadBytes(isin.rest, 32) IN IF ~assetName.ok THEN Fail ELSE
    LET financialProduct == ReadBytes(assetName.rest, 1) IN IF ~financialProduct.ok THEN Fail ELSE
    LET tradingCurrency == ReadBytes(financialProduct.rest, 3) IN IF ~tradingCurrency.ok THEN Fail ELSE
    LET numberOfDecimalsInPrice == ReadBytes(tradingCurrency.rest, 2) IN IF ~numberOfDecimalsInPrice.ok THEN Fail ELSE
    LET numberOfDecimalsInNominalValue == ReadBytes(numberOfDecimalsInPrice.rest, 2) IN IF ~numberOfDecimalsInNominalValue.ok THEN Fail ELSE
    LET roundLotSize == ReadBytes(numberOfDecimalsInNominalValue.rest, 4) IN IF ~roundLotSize.ok THEN Fail ELSE
    LET nominalValue == ReadBytes(roundLotSize.rest, 8) IN IF ~nominalValue.ok THEN Fail ELSE
    LET numberOfLegs == ReadBytes(nominalValue.rest, 1) IN IF ~numberOfLegs.ok THEN Fail ELSE
    LET commodityCode == ReadBytes(numberOfLegs.rest, 4) IN IF ~commodityCode.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(commodityCode.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET expirationDate == ReadBytes(strikePrice.rest, 4) IN IF ~expirationDate.ok THEN Fail ELSE
    LET numberOfDecimalsInStrikePrice == ReadBytes(expirationDate.rest, 2) IN IF ~numberOfDecimalsInStrikePrice.ok THEN Fail ELSE
    LET optionType == ReadBytes(numberOfDecimalsInStrikePrice.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET marketId == ReadBytes(optionType.rest, 4) IN IF ~marketId.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(marketId.rest, 4) IN IF ~exchangeId.ok THEN Fail ELSE
    LET numberOfDecimalsIn == ReadBytes(exchangeId.rest, 2) IN IF ~numberOfDecimalsIn.ok THEN Fail ELSE
    LET sectorCode == ReadBytes(numberOfDecimalsIn.rest, 4) IN IF ~sectorCode.ok THEN Fail ELSE
    LET numberOfTradableEquities == ReadBytes(sectorCode.rest, 8) IN IF ~numberOfTradableEquities.ok THEN Fail ELSE
    LET numberOfOutstandingEquities == ReadBytes(numberOfTradableEquities.rest, 8) IN IF ~numberOfOutstandingEquities.ok THEN Fail ELSE
    LET lastTradedDate == ReadBytes(numberOfOutstandingEquities.rest, 4) IN IF ~lastTradedDate.ok THEN Fail ELSE
    LET contractMultiplier == ReadBytes(lastTradedDate.rest, 8) IN IF ~contractMultiplier.ok THEN Fail ELSE
    LET multiplier == ReadBytes(contractMultiplier.rest, 8) IN IF ~multiplier.ok THEN Fail ELSE
    LET decimalsInMultiplier == ReadBytes(multiplier.rest, 2) IN IF ~decimalsInMultiplier.ok THEN Fail ELSE
    LET minOrderQuantity == ReadBytes(decimalsInMultiplier.rest, 8) IN IF ~minOrderQuantity.ok THEN Fail ELSE
    LET maxOrderQuantity == ReadBytes(minOrderQuantity.rest, 8) IN IF ~maxOrderQuantity.ok THEN Fail ELSE
    LET numberOfSettlementDays == ReadBytes(maxOrderQuantity.rest, 4) IN IF ~numberOfSettlementDays.ok THEN Fail ELSE
    LET primary == ReadBytes(numberOfSettlementDays.rest, 1) IN IF ~primary.ok THEN Fail ELSE
    LET testOrderBook == ReadBytes(primary.rest, 1) IN IF ~testOrderBook.ok THEN Fail ELSE
    LET aliasName == ReadBytes(testOrderBook.rest, 32) IN IF ~aliasName.ok THEN Fail ELSE
    LET settlementDate == ReadBytes(aliasName.rest, 4) IN IF ~settlementDate.ok THEN Fail ELSE
    LET tradable == ReadBytes(settlementDate.rest, 1) IN IF ~tradable.ok THEN Fail ELSE
    LET externallyPriceSourced == ReadBytes(tradable.rest, 1) IN IF ~externallyPriceSourced.ok THEN Fail ELSE
    LET deliverable == ReadBytes(externallyPriceSourced.rest, 1) IN IF ~deliverable.ok THEN Fail ELSE
    LET priceUnit == ReadBytes(deliverable.rest, 1) IN IF ~priceUnit.ok THEN Fail ELSE
    LET issuer == ReadBytes(priceUnit.rest, 32) IN IF ~issuer.ok THEN Fail ELSE
    LET foreignOwnershipRestriction == ReadBytes(issuer.rest, 1) IN IF ~foreignOwnershipRestriction.ok THEN Fail ELSE
    LET lastTradingTime == ReadBytes(foreignOwnershipRestriction.rest, 6) IN IF ~lastTradingTime.ok THEN Fail ELSE
    LET optionStyle == ReadBytes(lastTradingTime.rest, 1) IN IF ~optionStyle.ok THEN Fail ELSE
    LET minimumValueForInitialTradeReport == ReadBytes(optionStyle.rest, 8) IN IF ~minimumValueForInitialTradeReport.ok THEN Fail ELSE
    LET cfiCode == ReadBytes(minimumValueForInitialTradeReport.rest, 6) IN IF ~cfiCode.ok THEN Fail ELSE
    LET upperLevelSeries == ReadBytes(cfiCode.rest, 32) IN IF ~upperLevelSeries.ok THEN Fail ELSE
    LET upperSeriesLevelOrderBookId == ReadBytes(upperLevelSeries.rest, 4) IN IF ~upperSeriesLevelOrderBookId.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(upperSeriesLevelOrderBookId.rest, 4) IN IF ~instrumentType.ok THEN Fail ELSE
    LET status == ReadBytes(instrumentType.rest, 1) IN IF ~status.ok THEN Fail ELSE
    Ok([ timestampNanoseconds              |-> timestampNanoseconds.value,
         orderBookId                       |-> orderBookId.value,
         partitionId                       |-> partitionId.value,
         symbol                            |-> symbol.value,
         longName                          |-> longName.value,
         isin                              |-> isin.value,
         assetName                         |-> assetName.value,
         financialProduct                  |-> financialProduct.value,
         tradingCurrency                   |-> tradingCurrency.value,
         numberOfDecimalsInPrice           |-> numberOfDecimalsInPrice.value,
         numberOfDecimalsInNominalValue    |-> numberOfDecimalsInNominalValue.value,
         roundLotSize                      |-> roundLotSize.value,
         nominalValue                      |-> nominalValue.value,
         numberOfLegs                      |-> numberOfLegs.value,
         commodityCode                     |-> commodityCode.value,
         strikePrice                       |-> strikePrice.value,
         expirationDate                    |-> expirationDate.value,
         numberOfDecimalsInStrikePrice     |-> numberOfDecimalsInStrikePrice.value,
         optionType                        |-> optionType.value,
         marketId                          |-> marketId.value,
         exchangeId                        |-> exchangeId.value,
         numberOfDecimalsIn                |-> numberOfDecimalsIn.value,
         sectorCode                        |-> sectorCode.value,
         numberOfTradableEquities          |-> numberOfTradableEquities.value,
         numberOfOutstandingEquities       |-> numberOfOutstandingEquities.value,
         lastTradedDate                    |-> lastTradedDate.value,
         contractMultiplier                |-> contractMultiplier.value,
         multiplier                        |-> multiplier.value,
         decimalsInMultiplier              |-> decimalsInMultiplier.value,
         minOrderQuantity                  |-> minOrderQuantity.value,
         maxOrderQuantity                  |-> maxOrderQuantity.value,
         numberOfSettlementDays            |-> numberOfSettlementDays.value,
         primary                           |-> primary.value,
         testOrderBook                     |-> testOrderBook.value,
         aliasName                         |-> aliasName.value,
         settlementDate                    |-> settlementDate.value,
         tradable                          |-> tradable.value,
         externallyPriceSourced            |-> externallyPriceSourced.value,
         deliverable                       |-> deliverable.value,
         priceUnit                         |-> priceUnit.value,
         issuer                            |-> issuer.value,
         foreignOwnershipRestriction       |-> foreignOwnershipRestriction.value,
         lastTradingTime                   |-> lastTradingTime.value,
         optionStyle                       |-> optionStyle.value,
         minimumValueForInitialTradeReport |-> minimumValueForInitialTradeReport.value,
         cfiCode                           |-> cfiCode.value,
         upperLevelSeries                  |-> upperLevelSeries.value,
         upperSeriesLevelOrderBookId       |-> upperSeriesLevelOrderBookId.value,
         instrumentType                    |-> instrumentType.value,
         status                            |-> status.value ], status.rest)

ZeroOrderBookDirectoryMessage ==
    [ timestampNanoseconds              |-> [i \in 1 .. 4 |-> 0],
      orderBookId                       |-> [i \in 1 .. 4 |-> 0],
      partitionId                       |-> [i \in 1 .. 1 |-> 0],
      symbol                            |-> [i \in 1 .. 32 |-> 0],
      longName                          |-> [i \in 1 .. 32 |-> 0],
      isin                              |-> [i \in 1 .. 12 |-> 0],
      assetName                         |-> [i \in 1 .. 32 |-> 0],
      financialProduct                  |-> [i \in 1 .. 1 |-> 0],
      tradingCurrency                   |-> [i \in 1 .. 3 |-> 0],
      numberOfDecimalsInPrice           |-> [i \in 1 .. 2 |-> 0],
      numberOfDecimalsInNominalValue    |-> [i \in 1 .. 2 |-> 0],
      roundLotSize                      |-> [i \in 1 .. 4 |-> 0],
      nominalValue                      |-> [i \in 1 .. 8 |-> 0],
      numberOfLegs                      |-> [i \in 1 .. 1 |-> 0],
      commodityCode                     |-> [i \in 1 .. 4 |-> 0],
      strikePrice                       |-> [i \in 1 .. 8 |-> 0],
      expirationDate                    |-> [i \in 1 .. 4 |-> 0],
      numberOfDecimalsInStrikePrice     |-> [i \in 1 .. 2 |-> 0],
      optionType                        |-> [i \in 1 .. 1 |-> 0],
      marketId                          |-> [i \in 1 .. 4 |-> 0],
      exchangeId                        |-> [i \in 1 .. 4 |-> 0],
      numberOfDecimalsIn                |-> [i \in 1 .. 2 |-> 0],
      sectorCode                        |-> [i \in 1 .. 4 |-> 0],
      numberOfTradableEquities          |-> [i \in 1 .. 8 |-> 0],
      numberOfOutstandingEquities       |-> [i \in 1 .. 8 |-> 0],
      lastTradedDate                    |-> [i \in 1 .. 4 |-> 0],
      contractMultiplier                |-> [i \in 1 .. 8 |-> 0],
      multiplier                        |-> [i \in 1 .. 8 |-> 0],
      decimalsInMultiplier              |-> [i \in 1 .. 2 |-> 0],
      minOrderQuantity                  |-> [i \in 1 .. 8 |-> 0],
      maxOrderQuantity                  |-> [i \in 1 .. 8 |-> 0],
      numberOfSettlementDays            |-> [i \in 1 .. 4 |-> 0],
      primary                           |-> [i \in 1 .. 1 |-> 0],
      testOrderBook                     |-> [i \in 1 .. 1 |-> 0],
      aliasName                         |-> [i \in 1 .. 32 |-> 0],
      settlementDate                    |-> [i \in 1 .. 4 |-> 0],
      tradable                          |-> [i \in 1 .. 1 |-> 0],
      externallyPriceSourced            |-> [i \in 1 .. 1 |-> 0],
      deliverable                       |-> [i \in 1 .. 1 |-> 0],
      priceUnit                         |-> [i \in 1 .. 1 |-> 0],
      issuer                            |-> [i \in 1 .. 32 |-> 0],
      foreignOwnershipRestriction       |-> [i \in 1 .. 1 |-> 0],
      lastTradingTime                   |-> [i \in 1 .. 6 |-> 0],
      optionStyle                       |-> [i \in 1 .. 1 |-> 0],
      minimumValueForInitialTradeReport |-> [i \in 1 .. 8 |-> 0],
      cfiCode                           |-> [i \in 1 .. 6 |-> 0],
      upperLevelSeries                  |-> [i \in 1 .. 32 |-> 0],
      upperSeriesLevelOrderBookId       |-> [i \in 1 .. 4 |-> 0],
      instrumentType                    |-> [i \in 1 .. 4 |-> 0],
      status                            |-> [i \in 1 .. 1 |-> 0] ]

(* Order Book Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderBookDirectoryMessage ==
    { ZeroOrderBookDirectoryMessage }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.timestampNanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.partitionId = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.symbol = one] : one \in Sample(32) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.longName = one] : one \in Sample(32) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.assetName = one] : one \in Sample(32) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.financialProduct = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.tradingCurrency = one] : one \in Sample(3) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.numberOfDecimalsInPrice = one] : one \in Sample(2) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.numberOfDecimalsInNominalValue = one] : one \in Sample(2) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.roundLotSize = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.nominalValue = one] : one \in Sample(8) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.numberOfLegs = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.commodityCode = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.expirationDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.numberOfDecimalsInStrikePrice = one] : one \in Sample(2) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.marketId = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.exchangeId = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.numberOfDecimalsIn = one] : one \in Sample(2) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.sectorCode = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.numberOfTradableEquities = one] : one \in Sample(8) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.numberOfOutstandingEquities = one] : one \in Sample(8) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.lastTradedDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.contractMultiplier = one] : one \in Sample(8) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.multiplier = one] : one \in Sample(8) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.decimalsInMultiplier = one] : one \in Sample(2) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.minOrderQuantity = one] : one \in Sample(8) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.maxOrderQuantity = one] : one \in Sample(8) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.numberOfSettlementDays = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.primary = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.testOrderBook = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.aliasName = one] : one \in Sample(32) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.settlementDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.tradable = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.externallyPriceSourced = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.deliverable = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.priceUnit = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.issuer = one] : one \in Sample(32) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.foreignOwnershipRestriction = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.lastTradingTime = one] : one \in Sample(6) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.optionStyle = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.minimumValueForInitialTradeReport = one] : one \in Sample(8) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.cfiCode = one] : one \in Sample(6) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.upperLevelSeries = one] : one \in Sample(32) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.upperSeriesLevelOrderBookId = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.instrumentType = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.status = one] : one \in Sample(1) }

(***************************************************************************)
(* Exchange Directory Message: 40 bytes                                    *)
(***************************************************************************)

ExchangeDirectoryMessage ==
    [ timestampNanoseconds : Sample(4),
      exchangeId           : Sample(4),
      exchangeName         : Sample(32) ]

EncodeExchangeDirectoryMessage(message) ==
    message.timestampNanoseconds
        \o message.exchangeId
        \o message.exchangeName

DecodeExchangeDirectoryMessage(bytes) ==
    LET timestampNanoseconds == ReadBytes(bytes, 4) IN IF ~timestampNanoseconds.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(timestampNanoseconds.rest, 4) IN IF ~exchangeId.ok THEN Fail ELSE
    LET exchangeName == ReadBytes(exchangeId.rest, 32) IN IF ~exchangeName.ok THEN Fail ELSE
    Ok([ timestampNanoseconds |-> timestampNanoseconds.value,
         exchangeId           |-> exchangeId.value,
         exchangeName         |-> exchangeName.value ], exchangeName.rest)

ZeroExchangeDirectoryMessage ==
    [ timestampNanoseconds |-> [i \in 1 .. 4 |-> 0],
      exchangeId           |-> [i \in 1 .. 4 |-> 0],
      exchangeName         |-> [i \in 1 .. 32 |-> 0] ]

(* Exchange Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedExchangeDirectoryMessage ==
    { ZeroExchangeDirectoryMessage }
        \cup { [ZeroExchangeDirectoryMessage EXCEPT !.timestampNanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroExchangeDirectoryMessage EXCEPT !.exchangeId = one] : one \in Sample(4) }
        \cup { [ZeroExchangeDirectoryMessage EXCEPT !.exchangeName = one] : one \in Sample(32) }

(***************************************************************************)
(* Market Directory Message: 42 bytes                                      *)
(***************************************************************************)

MarketDirectoryMessage ==
    [ timestampNanoseconds : Sample(4),
      marketId             : Sample(4),
      marketName           : Sample(32),
      marketType           : Sample(1),
      indexMarket          : Sample(1) ]

EncodeMarketDirectoryMessage(message) ==
    message.timestampNanoseconds
        \o message.marketId
        \o message.marketName
        \o message.marketType
        \o message.indexMarket

DecodeMarketDirectoryMessage(bytes) ==
    LET timestampNanoseconds == ReadBytes(bytes, 4) IN IF ~timestampNanoseconds.ok THEN Fail ELSE
    LET marketId == ReadBytes(timestampNanoseconds.rest, 4) IN IF ~marketId.ok THEN Fail ELSE
    LET marketName == ReadBytes(marketId.rest, 32) IN IF ~marketName.ok THEN Fail ELSE
    LET marketType == ReadBytes(marketName.rest, 1) IN IF ~marketType.ok THEN Fail ELSE
    LET indexMarket == ReadBytes(marketType.rest, 1) IN IF ~indexMarket.ok THEN Fail ELSE
    Ok([ timestampNanoseconds |-> timestampNanoseconds.value,
         marketId             |-> marketId.value,
         marketName           |-> marketName.value,
         marketType           |-> marketType.value,
         indexMarket          |-> indexMarket.value ], indexMarket.rest)

ZeroMarketDirectoryMessage ==
    [ timestampNanoseconds |-> [i \in 1 .. 4 |-> 0],
      marketId             |-> [i \in 1 .. 4 |-> 0],
      marketName           |-> [i \in 1 .. 32 |-> 0],
      marketType           |-> [i \in 1 .. 1 |-> 0],
      indexMarket          |-> [i \in 1 .. 1 |-> 0] ]

(* Market Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketDirectoryMessage ==
    { ZeroMarketDirectoryMessage }
        \cup { [ZeroMarketDirectoryMessage EXCEPT !.timestampNanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroMarketDirectoryMessage EXCEPT !.marketId = one] : one \in Sample(4) }
        \cup { [ZeroMarketDirectoryMessage EXCEPT !.marketName = one] : one \in Sample(32) }
        \cup { [ZeroMarketDirectoryMessage EXCEPT !.marketType = one] : one \in Sample(1) }
        \cup { [ZeroMarketDirectoryMessage EXCEPT !.indexMarket = one] : one \in Sample(1) }

(***************************************************************************)
(* Combination Order Book Leg Directory Message: 17 bytes                  *)
(***************************************************************************)

CombinationOrderBookLegDirectoryMessage ==
    [ timestampNanoseconds   : Sample(4),
      combinationOrderBookId : Sample(4),
      legOrderBookId         : Sample(4),
      legSide                : Sample(1),
      legRatio               : Sample(4) ]

EncodeCombinationOrderBookLegDirectoryMessage(message) ==
    message.timestampNanoseconds
        \o message.combinationOrderBookId
        \o message.legOrderBookId
        \o message.legSide
        \o message.legRatio

DecodeCombinationOrderBookLegDirectoryMessage(bytes) ==
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

ZeroCombinationOrderBookLegDirectoryMessage ==
    [ timestampNanoseconds   |-> [i \in 1 .. 4 |-> 0],
      combinationOrderBookId |-> [i \in 1 .. 4 |-> 0],
      legOrderBookId         |-> [i \in 1 .. 4 |-> 0],
      legSide                |-> [i \in 1 .. 1 |-> 0],
      legRatio               |-> [i \in 1 .. 4 |-> 0] ]

(* Combination Order Book Leg Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedCombinationOrderBookLegDirectoryMessage ==
    { ZeroCombinationOrderBookLegDirectoryMessage }
        \cup { [ZeroCombinationOrderBookLegDirectoryMessage EXCEPT !.timestampNanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroCombinationOrderBookLegDirectoryMessage EXCEPT !.combinationOrderBookId = one] : one \in Sample(4) }
        \cup { [ZeroCombinationOrderBookLegDirectoryMessage EXCEPT !.legOrderBookId = one] : one \in Sample(4) }
        \cup { [ZeroCombinationOrderBookLegDirectoryMessage EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroCombinationOrderBookLegDirectoryMessage EXCEPT !.legRatio = one] : one \in Sample(4) }

(***************************************************************************)
(* Tick Size Table Entry Message: 32 bytes                                 *)
(***************************************************************************)

TickSizeTableEntryMessage ==
    [ timestampNanoseconds : Sample(4),
      orderBookId          : Sample(4),
      tickSize             : Sample(8),
      priceFrom            : Sample(8),
      priceTo              : Sample(8) ]

EncodeTickSizeTableEntryMessage(message) ==
    message.timestampNanoseconds
        \o message.orderBookId
        \o message.tickSize
        \o message.priceFrom
        \o message.priceTo

DecodeTickSizeTableEntryMessage(bytes) ==
    LET timestampNanoseconds == ReadBytes(bytes, 4) IN IF ~timestampNanoseconds.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(timestampNanoseconds.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET tickSize == ReadBytes(orderBookId.rest, 8) IN IF ~tickSize.ok THEN Fail ELSE
    LET priceFrom == ReadBytes(tickSize.rest, 8) IN IF ~priceFrom.ok THEN Fail ELSE
    LET priceTo == ReadBytes(priceFrom.rest, 8) IN IF ~priceTo.ok THEN Fail ELSE
    Ok([ timestampNanoseconds |-> timestampNanoseconds.value,
         orderBookId          |-> orderBookId.value,
         tickSize             |-> tickSize.value,
         priceFrom            |-> priceFrom.value,
         priceTo              |-> priceTo.value ], priceTo.rest)

ZeroTickSizeTableEntryMessage ==
    [ timestampNanoseconds |-> [i \in 1 .. 4 |-> 0],
      orderBookId          |-> [i \in 1 .. 4 |-> 0],
      tickSize             |-> [i \in 1 .. 8 |-> 0],
      priceFrom            |-> [i \in 1 .. 8 |-> 0],
      priceTo              |-> [i \in 1 .. 8 |-> 0] ]

(* Tick Size Table Entry Message at zero, then each field in turn at the values it is checked at *)
CheckedTickSizeTableEntryMessage ==
    { ZeroTickSizeTableEntryMessage }
        \cup { [ZeroTickSizeTableEntryMessage EXCEPT !.timestampNanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroTickSizeTableEntryMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroTickSizeTableEntryMessage EXCEPT !.tickSize = one] : one \in Sample(8) }
        \cup { [ZeroTickSizeTableEntryMessage EXCEPT !.priceFrom = one] : one \in Sample(8) }
        \cup { [ZeroTickSizeTableEntryMessage EXCEPT !.priceTo = one] : one \in Sample(8) }

(***************************************************************************)
(* Corporate Action Entry Message: 31 bytes                                *)
(***************************************************************************)

CorporateActionEntryMessage ==
    [ timestampNanoseconds  : Sample(4),
      corporateActionId     : Sample(4),
      orderBookId           : Sample(4),
      corporateActionCode   : Sample(4),
      corporateActionType   : Sample(1),
      startDate             : Sample(4),
      endDate               : Sample(4),
      recordDate            : Sample(4),
      corporateActionStatus : Sample(1),
      action                : Sample(1) ]

EncodeCorporateActionEntryMessage(message) ==
    message.timestampNanoseconds
        \o message.corporateActionId
        \o message.orderBookId
        \o message.corporateActionCode
        \o message.corporateActionType
        \o message.startDate
        \o message.endDate
        \o message.recordDate
        \o message.corporateActionStatus
        \o message.action

DecodeCorporateActionEntryMessage(bytes) ==
    LET timestampNanoseconds == ReadBytes(bytes, 4) IN IF ~timestampNanoseconds.ok THEN Fail ELSE
    LET corporateActionId == ReadBytes(timestampNanoseconds.rest, 4) IN IF ~corporateActionId.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(corporateActionId.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET corporateActionCode == ReadBytes(orderBookId.rest, 4) IN IF ~corporateActionCode.ok THEN Fail ELSE
    LET corporateActionType == ReadBytes(corporateActionCode.rest, 1) IN IF ~corporateActionType.ok THEN Fail ELSE
    LET startDate == ReadBytes(corporateActionType.rest, 4) IN IF ~startDate.ok THEN Fail ELSE
    LET endDate == ReadBytes(startDate.rest, 4) IN IF ~endDate.ok THEN Fail ELSE
    LET recordDate == ReadBytes(endDate.rest, 4) IN IF ~recordDate.ok THEN Fail ELSE
    LET corporateActionStatus == ReadBytes(recordDate.rest, 1) IN IF ~corporateActionStatus.ok THEN Fail ELSE
    LET action == ReadBytes(corporateActionStatus.rest, 1) IN IF ~action.ok THEN Fail ELSE
    Ok([ timestampNanoseconds  |-> timestampNanoseconds.value,
         corporateActionId     |-> corporateActionId.value,
         orderBookId           |-> orderBookId.value,
         corporateActionCode   |-> corporateActionCode.value,
         corporateActionType   |-> corporateActionType.value,
         startDate             |-> startDate.value,
         endDate               |-> endDate.value,
         recordDate            |-> recordDate.value,
         corporateActionStatus |-> corporateActionStatus.value,
         action                |-> action.value ], action.rest)

ZeroCorporateActionEntryMessage ==
    [ timestampNanoseconds  |-> [i \in 1 .. 4 |-> 0],
      corporateActionId     |-> [i \in 1 .. 4 |-> 0],
      orderBookId           |-> [i \in 1 .. 4 |-> 0],
      corporateActionCode   |-> [i \in 1 .. 4 |-> 0],
      corporateActionType   |-> [i \in 1 .. 1 |-> 0],
      startDate             |-> [i \in 1 .. 4 |-> 0],
      endDate               |-> [i \in 1 .. 4 |-> 0],
      recordDate            |-> [i \in 1 .. 4 |-> 0],
      corporateActionStatus |-> [i \in 1 .. 1 |-> 0],
      action                |-> [i \in 1 .. 1 |-> 0] ]

(* Corporate Action Entry Message at zero, then each field in turn at the values it is checked at *)
CheckedCorporateActionEntryMessage ==
    { ZeroCorporateActionEntryMessage }
        \cup { [ZeroCorporateActionEntryMessage EXCEPT !.timestampNanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroCorporateActionEntryMessage EXCEPT !.corporateActionId = one] : one \in Sample(4) }
        \cup { [ZeroCorporateActionEntryMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroCorporateActionEntryMessage EXCEPT !.corporateActionCode = one] : one \in Sample(4) }
        \cup { [ZeroCorporateActionEntryMessage EXCEPT !.corporateActionType = one] : one \in Sample(1) }
        \cup { [ZeroCorporateActionEntryMessage EXCEPT !.startDate = one] : one \in Sample(4) }
        \cup { [ZeroCorporateActionEntryMessage EXCEPT !.endDate = one] : one \in Sample(4) }
        \cup { [ZeroCorporateActionEntryMessage EXCEPT !.recordDate = one] : one \in Sample(4) }
        \cup { [ZeroCorporateActionEntryMessage EXCEPT !.corporateActionStatus = one] : one \in Sample(1) }
        \cup { [ZeroCorporateActionEntryMessage EXCEPT !.action = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Book Directory Extension Message: 92 bytes                        *)
(***************************************************************************)

OrderBookDirectoryExtensionMessage ==
    [ timestampNanoseconds      : Sample(4),
      orderBookId               : Sample(4),
      accruedInterestRounding   : Sample(4),
      accruedInterestUpdown     : Sample(1),
      calculationConvention     : Sample(1),
      cleanPriceRounding        : Sample(4),
      cleanPriceUpdown          : Sample(1),
      couponFrequency           : Sample(4),
      couponInterest            : Sample(8),
      couponFromDate            : Sample(4),
      issueDate                 : Sample(4),
      maturityDate              : Sample(4),
      dayCalculationRule        : Sample(1),
      dayCountConvention        : Sample(1),
      exCouponPeriod            : Sample(4),
      dividend                  : Sample(8),
      fixedIncomeType           : Sample(1),
      rateDeterminationDays     : Sample(4),
      yieldConvention           : Sample(4),
      endOfMonthCountConvention : Sample(4),
      firstSettlementDate       : Sample(4),
      couponDivDate             : Sample(4),
      dateBooksClose            : Sample(4),
      effectiveExpirationDate   : Sample(4),
      proceedDate               : Sample(4),
      setEndConsideration       : Sample(1),
      setStartConsideration     : Sample(1) ]

EncodeOrderBookDirectoryExtensionMessage(message) ==
    message.timestampNanoseconds
        \o message.orderBookId
        \o message.accruedInterestRounding
        \o message.accruedInterestUpdown
        \o message.calculationConvention
        \o message.cleanPriceRounding
        \o message.cleanPriceUpdown
        \o message.couponFrequency
        \o message.couponInterest
        \o message.couponFromDate
        \o message.issueDate
        \o message.maturityDate
        \o message.dayCalculationRule
        \o message.dayCountConvention
        \o message.exCouponPeriod
        \o message.dividend
        \o message.fixedIncomeType
        \o message.rateDeterminationDays
        \o message.yieldConvention
        \o message.endOfMonthCountConvention
        \o message.firstSettlementDate
        \o message.couponDivDate
        \o message.dateBooksClose
        \o message.effectiveExpirationDate
        \o message.proceedDate
        \o message.setEndConsideration
        \o message.setStartConsideration

DecodeOrderBookDirectoryExtensionMessage(bytes) ==
    LET timestampNanoseconds == ReadBytes(bytes, 4) IN IF ~timestampNanoseconds.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(timestampNanoseconds.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET accruedInterestRounding == ReadBytes(orderBookId.rest, 4) IN IF ~accruedInterestRounding.ok THEN Fail ELSE
    LET accruedInterestUpdown == ReadBytes(accruedInterestRounding.rest, 1) IN IF ~accruedInterestUpdown.ok THEN Fail ELSE
    LET calculationConvention == ReadBytes(accruedInterestUpdown.rest, 1) IN IF ~calculationConvention.ok THEN Fail ELSE
    LET cleanPriceRounding == ReadBytes(calculationConvention.rest, 4) IN IF ~cleanPriceRounding.ok THEN Fail ELSE
    LET cleanPriceUpdown == ReadBytes(cleanPriceRounding.rest, 1) IN IF ~cleanPriceUpdown.ok THEN Fail ELSE
    LET couponFrequency == ReadBytes(cleanPriceUpdown.rest, 4) IN IF ~couponFrequency.ok THEN Fail ELSE
    LET couponInterest == ReadBytes(couponFrequency.rest, 8) IN IF ~couponInterest.ok THEN Fail ELSE
    LET couponFromDate == ReadBytes(couponInterest.rest, 4) IN IF ~couponFromDate.ok THEN Fail ELSE
    LET issueDate == ReadBytes(couponFromDate.rest, 4) IN IF ~issueDate.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(issueDate.rest, 4) IN IF ~maturityDate.ok THEN Fail ELSE
    LET dayCalculationRule == ReadBytes(maturityDate.rest, 1) IN IF ~dayCalculationRule.ok THEN Fail ELSE
    LET dayCountConvention == ReadBytes(dayCalculationRule.rest, 1) IN IF ~dayCountConvention.ok THEN Fail ELSE
    LET exCouponPeriod == ReadBytes(dayCountConvention.rest, 4) IN IF ~exCouponPeriod.ok THEN Fail ELSE
    LET dividend == ReadBytes(exCouponPeriod.rest, 8) IN IF ~dividend.ok THEN Fail ELSE
    LET fixedIncomeType == ReadBytes(dividend.rest, 1) IN IF ~fixedIncomeType.ok THEN Fail ELSE
    LET rateDeterminationDays == ReadBytes(fixedIncomeType.rest, 4) IN IF ~rateDeterminationDays.ok THEN Fail ELSE
    LET yieldConvention == ReadBytes(rateDeterminationDays.rest, 4) IN IF ~yieldConvention.ok THEN Fail ELSE
    LET endOfMonthCountConvention == ReadBytes(yieldConvention.rest, 4) IN IF ~endOfMonthCountConvention.ok THEN Fail ELSE
    LET firstSettlementDate == ReadBytes(endOfMonthCountConvention.rest, 4) IN IF ~firstSettlementDate.ok THEN Fail ELSE
    LET couponDivDate == ReadBytes(firstSettlementDate.rest, 4) IN IF ~couponDivDate.ok THEN Fail ELSE
    LET dateBooksClose == ReadBytes(couponDivDate.rest, 4) IN IF ~dateBooksClose.ok THEN Fail ELSE
    LET effectiveExpirationDate == ReadBytes(dateBooksClose.rest, 4) IN IF ~effectiveExpirationDate.ok THEN Fail ELSE
    LET proceedDate == ReadBytes(effectiveExpirationDate.rest, 4) IN IF ~proceedDate.ok THEN Fail ELSE
    LET setEndConsideration == ReadBytes(proceedDate.rest, 1) IN IF ~setEndConsideration.ok THEN Fail ELSE
    LET setStartConsideration == ReadBytes(setEndConsideration.rest, 1) IN IF ~setStartConsideration.ok THEN Fail ELSE
    Ok([ timestampNanoseconds      |-> timestampNanoseconds.value,
         orderBookId               |-> orderBookId.value,
         accruedInterestRounding   |-> accruedInterestRounding.value,
         accruedInterestUpdown     |-> accruedInterestUpdown.value,
         calculationConvention     |-> calculationConvention.value,
         cleanPriceRounding        |-> cleanPriceRounding.value,
         cleanPriceUpdown          |-> cleanPriceUpdown.value,
         couponFrequency           |-> couponFrequency.value,
         couponInterest            |-> couponInterest.value,
         couponFromDate            |-> couponFromDate.value,
         issueDate                 |-> issueDate.value,
         maturityDate              |-> maturityDate.value,
         dayCalculationRule        |-> dayCalculationRule.value,
         dayCountConvention        |-> dayCountConvention.value,
         exCouponPeriod            |-> exCouponPeriod.value,
         dividend                  |-> dividend.value,
         fixedIncomeType           |-> fixedIncomeType.value,
         rateDeterminationDays     |-> rateDeterminationDays.value,
         yieldConvention           |-> yieldConvention.value,
         endOfMonthCountConvention |-> endOfMonthCountConvention.value,
         firstSettlementDate       |-> firstSettlementDate.value,
         couponDivDate             |-> couponDivDate.value,
         dateBooksClose            |-> dateBooksClose.value,
         effectiveExpirationDate   |-> effectiveExpirationDate.value,
         proceedDate               |-> proceedDate.value,
         setEndConsideration       |-> setEndConsideration.value,
         setStartConsideration     |-> setStartConsideration.value ], setStartConsideration.rest)

ZeroOrderBookDirectoryExtensionMessage ==
    [ timestampNanoseconds      |-> [i \in 1 .. 4 |-> 0],
      orderBookId               |-> [i \in 1 .. 4 |-> 0],
      accruedInterestRounding   |-> [i \in 1 .. 4 |-> 0],
      accruedInterestUpdown     |-> [i \in 1 .. 1 |-> 0],
      calculationConvention     |-> [i \in 1 .. 1 |-> 0],
      cleanPriceRounding        |-> [i \in 1 .. 4 |-> 0],
      cleanPriceUpdown          |-> [i \in 1 .. 1 |-> 0],
      couponFrequency           |-> [i \in 1 .. 4 |-> 0],
      couponInterest            |-> [i \in 1 .. 8 |-> 0],
      couponFromDate            |-> [i \in 1 .. 4 |-> 0],
      issueDate                 |-> [i \in 1 .. 4 |-> 0],
      maturityDate              |-> [i \in 1 .. 4 |-> 0],
      dayCalculationRule        |-> [i \in 1 .. 1 |-> 0],
      dayCountConvention        |-> [i \in 1 .. 1 |-> 0],
      exCouponPeriod            |-> [i \in 1 .. 4 |-> 0],
      dividend                  |-> [i \in 1 .. 8 |-> 0],
      fixedIncomeType           |-> [i \in 1 .. 1 |-> 0],
      rateDeterminationDays     |-> [i \in 1 .. 4 |-> 0],
      yieldConvention           |-> [i \in 1 .. 4 |-> 0],
      endOfMonthCountConvention |-> [i \in 1 .. 4 |-> 0],
      firstSettlementDate       |-> [i \in 1 .. 4 |-> 0],
      couponDivDate             |-> [i \in 1 .. 4 |-> 0],
      dateBooksClose            |-> [i \in 1 .. 4 |-> 0],
      effectiveExpirationDate   |-> [i \in 1 .. 4 |-> 0],
      proceedDate               |-> [i \in 1 .. 4 |-> 0],
      setEndConsideration       |-> [i \in 1 .. 1 |-> 0],
      setStartConsideration     |-> [i \in 1 .. 1 |-> 0] ]

(* Order Book Directory Extension Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderBookDirectoryExtensionMessage ==
    { ZeroOrderBookDirectoryExtensionMessage }
        \cup { [ZeroOrderBookDirectoryExtensionMessage EXCEPT !.timestampNanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryExtensionMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryExtensionMessage EXCEPT !.accruedInterestRounding = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryExtensionMessage EXCEPT !.accruedInterestUpdown = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookDirectoryExtensionMessage EXCEPT !.calculationConvention = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookDirectoryExtensionMessage EXCEPT !.cleanPriceRounding = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryExtensionMessage EXCEPT !.cleanPriceUpdown = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookDirectoryExtensionMessage EXCEPT !.couponFrequency = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryExtensionMessage EXCEPT !.couponInterest = one] : one \in Sample(8) }
        \cup { [ZeroOrderBookDirectoryExtensionMessage EXCEPT !.couponFromDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryExtensionMessage EXCEPT !.issueDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryExtensionMessage EXCEPT !.maturityDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryExtensionMessage EXCEPT !.dayCalculationRule = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookDirectoryExtensionMessage EXCEPT !.dayCountConvention = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookDirectoryExtensionMessage EXCEPT !.exCouponPeriod = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryExtensionMessage EXCEPT !.dividend = one] : one \in Sample(8) }
        \cup { [ZeroOrderBookDirectoryExtensionMessage EXCEPT !.fixedIncomeType = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookDirectoryExtensionMessage EXCEPT !.rateDeterminationDays = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryExtensionMessage EXCEPT !.yieldConvention = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryExtensionMessage EXCEPT !.endOfMonthCountConvention = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryExtensionMessage EXCEPT !.firstSettlementDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryExtensionMessage EXCEPT !.couponDivDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryExtensionMessage EXCEPT !.dateBooksClose = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryExtensionMessage EXCEPT !.effectiveExpirationDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryExtensionMessage EXCEPT !.proceedDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryExtensionMessage EXCEPT !.setEndConsideration = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookDirectoryExtensionMessage EXCEPT !.setStartConsideration = one] : one \in Sample(1) }

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
(* Order Book State Message: 48 bytes                                      *)
(***************************************************************************)

OrderBookStateMessage ==
    [ timestampNanoseconds : Sample(4),
      orderBookId          : Sample(4),
      stateName            : Sample(20),
      displayName          : Sample(20) ]

EncodeOrderBookStateMessage(message) ==
    message.timestampNanoseconds
        \o message.orderBookId
        \o message.stateName
        \o message.displayName

DecodeOrderBookStateMessage(bytes) ==
    LET timestampNanoseconds == ReadBytes(bytes, 4) IN IF ~timestampNanoseconds.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(timestampNanoseconds.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET stateName == ReadBytes(orderBookId.rest, 20) IN IF ~stateName.ok THEN Fail ELSE
    LET displayName == ReadBytes(stateName.rest, 20) IN IF ~displayName.ok THEN Fail ELSE
    Ok([ timestampNanoseconds |-> timestampNanoseconds.value,
         orderBookId          |-> orderBookId.value,
         stateName            |-> stateName.value,
         displayName          |-> displayName.value ], displayName.rest)

ZeroOrderBookStateMessage ==
    [ timestampNanoseconds |-> [i \in 1 .. 4 |-> 0],
      orderBookId          |-> [i \in 1 .. 4 |-> 0],
      stateName            |-> [i \in 1 .. 20 |-> 0],
      displayName          |-> [i \in 1 .. 20 |-> 0] ]

(* Order Book State Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderBookStateMessage ==
    { ZeroOrderBookStateMessage }
        \cup { [ZeroOrderBookStateMessage EXCEPT !.timestampNanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookStateMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookStateMessage EXCEPT !.stateName = one] : one \in Sample(20) }
        \cup { [ZeroOrderBookStateMessage EXCEPT !.displayName = one] : one \in Sample(20) }

(***************************************************************************)
(* Business Date Message: 8 bytes                                          *)
(***************************************************************************)

BusinessDateMessage ==
    [ timestampNanoseconds : Sample(4),
      businessDate         : Sample(4) ]

EncodeBusinessDateMessage(message) ==
    message.timestampNanoseconds
        \o message.businessDate

DecodeBusinessDateMessage(bytes) ==
    LET timestampNanoseconds == ReadBytes(bytes, 4) IN IF ~timestampNanoseconds.ok THEN Fail ELSE
    LET businessDate == ReadBytes(timestampNanoseconds.rest, 4) IN IF ~businessDate.ok THEN Fail ELSE
    Ok([ timestampNanoseconds |-> timestampNanoseconds.value,
         businessDate         |-> businessDate.value ], businessDate.rest)

ZeroBusinessDateMessage ==
    [ timestampNanoseconds |-> [i \in 1 .. 4 |-> 0],
      businessDate         |-> [i \in 1 .. 4 |-> 0] ]

(* Business Date Message at zero, then each field in turn at the values it is checked at *)
CheckedBusinessDateMessage ==
    { ZeroBusinessDateMessage }
        \cup { [ZeroBusinessDateMessage EXCEPT !.timestampNanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroBusinessDateMessage EXCEPT !.businessDate = one] : one \in Sample(4) }

(***************************************************************************)
(* Instrument Status Message: 65 bytes                                     *)
(***************************************************************************)

InstrumentStatusMessage ==
    [ timestampNanoseconds          : Sample(4),
      tradingStateName              : Sample(20),
      instrumentStateLevel          : Sample(1),
      nameOfTheInstrumentStateLevel : Sample(32),
      startDate                     : Sample(4),
      startTime                     : Sample(4) ]

EncodeInstrumentStatusMessage(message) ==
    message.timestampNanoseconds
        \o message.tradingStateName
        \o message.instrumentStateLevel
        \o message.nameOfTheInstrumentStateLevel
        \o message.startDate
        \o message.startTime

DecodeInstrumentStatusMessage(bytes) ==
    LET timestampNanoseconds == ReadBytes(bytes, 4) IN IF ~timestampNanoseconds.ok THEN Fail ELSE
    LET tradingStateName == ReadBytes(timestampNanoseconds.rest, 20) IN IF ~tradingStateName.ok THEN Fail ELSE
    LET instrumentStateLevel == ReadBytes(tradingStateName.rest, 1) IN IF ~instrumentStateLevel.ok THEN Fail ELSE
    LET nameOfTheInstrumentStateLevel == ReadBytes(instrumentStateLevel.rest, 32) IN IF ~nameOfTheInstrumentStateLevel.ok THEN Fail ELSE
    LET startDate == ReadBytes(nameOfTheInstrumentStateLevel.rest, 4) IN IF ~startDate.ok THEN Fail ELSE
    LET startTime == ReadBytes(startDate.rest, 4) IN IF ~startTime.ok THEN Fail ELSE
    Ok([ timestampNanoseconds          |-> timestampNanoseconds.value,
         tradingStateName              |-> tradingStateName.value,
         instrumentStateLevel          |-> instrumentStateLevel.value,
         nameOfTheInstrumentStateLevel |-> nameOfTheInstrumentStateLevel.value,
         startDate                     |-> startDate.value,
         startTime                     |-> startTime.value ], startTime.rest)

ZeroInstrumentStatusMessage ==
    [ timestampNanoseconds          |-> [i \in 1 .. 4 |-> 0],
      tradingStateName              |-> [i \in 1 .. 20 |-> 0],
      instrumentStateLevel          |-> [i \in 1 .. 1 |-> 0],
      nameOfTheInstrumentStateLevel |-> [i \in 1 .. 32 |-> 0],
      startDate                     |-> [i \in 1 .. 4 |-> 0],
      startTime                     |-> [i \in 1 .. 4 |-> 0] ]

(* Instrument Status Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentStatusMessage ==
    { ZeroInstrumentStatusMessage }
        \cup { [ZeroInstrumentStatusMessage EXCEPT !.timestampNanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentStatusMessage EXCEPT !.tradingStateName = one] : one \in Sample(20) }
        \cup { [ZeroInstrumentStatusMessage EXCEPT !.instrumentStateLevel = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentStatusMessage EXCEPT !.nameOfTheInstrumentStateLevel = one] : one \in Sample(32) }
        \cup { [ZeroInstrumentStatusMessage EXCEPT !.startDate = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentStatusMessage EXCEPT !.startTime = one] : one \in Sample(4) }

(***************************************************************************)
(* Equilibrium Price Message: 72 bytes                                     *)
(***************************************************************************)

EquilibriumPriceMessage ==
    [ timestampNanoseconds                   : Sample(4),
      orderBookId                            : Sample(4),
      availableBidQuantityAtEquilibriumPrice : Sample(8),
      availableAskQuantityAtEquilibriumPrice : Sample(8),
      equilibriumPrice                       : Sample(8),
      bestBidPrice                           : Sample(8),
      bestAskPrice                           : Sample(8),
      bestBidQuantity                        : Sample(8),
      bestAskQuantity                        : Sample(8),
      equilibriumQuantity                    : Sample(8) ]

EncodeEquilibriumPriceMessage(message) ==
    message.timestampNanoseconds
        \o message.orderBookId
        \o message.availableBidQuantityAtEquilibriumPrice
        \o message.availableAskQuantityAtEquilibriumPrice
        \o message.equilibriumPrice
        \o message.bestBidPrice
        \o message.bestAskPrice
        \o message.bestBidQuantity
        \o message.bestAskQuantity
        \o message.equilibriumQuantity

DecodeEquilibriumPriceMessage(bytes) ==
    LET timestampNanoseconds == ReadBytes(bytes, 4) IN IF ~timestampNanoseconds.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(timestampNanoseconds.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET availableBidQuantityAtEquilibriumPrice == ReadBytes(orderBookId.rest, 8) IN IF ~availableBidQuantityAtEquilibriumPrice.ok THEN Fail ELSE
    LET availableAskQuantityAtEquilibriumPrice == ReadBytes(availableBidQuantityAtEquilibriumPrice.rest, 8) IN IF ~availableAskQuantityAtEquilibriumPrice.ok THEN Fail ELSE
    LET equilibriumPrice == ReadBytes(availableAskQuantityAtEquilibriumPrice.rest, 8) IN IF ~equilibriumPrice.ok THEN Fail ELSE
    LET bestBidPrice == ReadBytes(equilibriumPrice.rest, 8) IN IF ~bestBidPrice.ok THEN Fail ELSE
    LET bestAskPrice == ReadBytes(bestBidPrice.rest, 8) IN IF ~bestAskPrice.ok THEN Fail ELSE
    LET bestBidQuantity == ReadBytes(bestAskPrice.rest, 8) IN IF ~bestBidQuantity.ok THEN Fail ELSE
    LET bestAskQuantity == ReadBytes(bestBidQuantity.rest, 8) IN IF ~bestAskQuantity.ok THEN Fail ELSE
    LET equilibriumQuantity == ReadBytes(bestAskQuantity.rest, 8) IN IF ~equilibriumQuantity.ok THEN Fail ELSE
    Ok([ timestampNanoseconds                   |-> timestampNanoseconds.value,
         orderBookId                            |-> orderBookId.value,
         availableBidQuantityAtEquilibriumPrice |-> availableBidQuantityAtEquilibriumPrice.value,
         availableAskQuantityAtEquilibriumPrice |-> availableAskQuantityAtEquilibriumPrice.value,
         equilibriumPrice                       |-> equilibriumPrice.value,
         bestBidPrice                           |-> bestBidPrice.value,
         bestAskPrice                           |-> bestAskPrice.value,
         bestBidQuantity                        |-> bestBidQuantity.value,
         bestAskQuantity                        |-> bestAskQuantity.value,
         equilibriumQuantity                    |-> equilibriumQuantity.value ], equilibriumQuantity.rest)

ZeroEquilibriumPriceMessage ==
    [ timestampNanoseconds                   |-> [i \in 1 .. 4 |-> 0],
      orderBookId                            |-> [i \in 1 .. 4 |-> 0],
      availableBidQuantityAtEquilibriumPrice |-> [i \in 1 .. 8 |-> 0],
      availableAskQuantityAtEquilibriumPrice |-> [i \in 1 .. 8 |-> 0],
      equilibriumPrice                       |-> [i \in 1 .. 8 |-> 0],
      bestBidPrice                           |-> [i \in 1 .. 8 |-> 0],
      bestAskPrice                           |-> [i \in 1 .. 8 |-> 0],
      bestBidQuantity                        |-> [i \in 1 .. 8 |-> 0],
      bestAskQuantity                        |-> [i \in 1 .. 8 |-> 0],
      equilibriumQuantity                    |-> [i \in 1 .. 8 |-> 0] ]

(* Equilibrium Price Message at zero, then each field in turn at the values it is checked at *)
CheckedEquilibriumPriceMessage ==
    { ZeroEquilibriumPriceMessage }
        \cup { [ZeroEquilibriumPriceMessage EXCEPT !.timestampNanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroEquilibriumPriceMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroEquilibriumPriceMessage EXCEPT !.availableBidQuantityAtEquilibriumPrice = one] : one \in Sample(8) }
        \cup { [ZeroEquilibriumPriceMessage EXCEPT !.availableAskQuantityAtEquilibriumPrice = one] : one \in Sample(8) }
        \cup { [ZeroEquilibriumPriceMessage EXCEPT !.equilibriumPrice = one] : one \in Sample(8) }
        \cup { [ZeroEquilibriumPriceMessage EXCEPT !.bestBidPrice = one] : one \in Sample(8) }
        \cup { [ZeroEquilibriumPriceMessage EXCEPT !.bestAskPrice = one] : one \in Sample(8) }
        \cup { [ZeroEquilibriumPriceMessage EXCEPT !.bestBidQuantity = one] : one \in Sample(8) }
        \cup { [ZeroEquilibriumPriceMessage EXCEPT !.bestAskQuantity = one] : one \in Sample(8) }
        \cup { [ZeroEquilibriumPriceMessage EXCEPT !.equilibriumQuantity = one] : one \in Sample(8) }

(***************************************************************************)
(* Array Of Level Items: 28 bytes                                          *)
(***************************************************************************)

ArrayOfLevelItems ==
    [ levelUpdateAction : Sample(1),
      side              : Sample(1),
      level             : Sample(1),
      price             : Sample(8),
      quantity          : Sample(8),
      numberOfDeletes   : Sample(1),
      numberOfOrders    : Sample(8) ]

EncodeArrayOfLevelItems(message) ==
    message.levelUpdateAction
        \o message.side
        \o message.level
        \o message.price
        \o message.quantity
        \o message.numberOfDeletes
        \o message.numberOfOrders

DecodeArrayOfLevelItems(bytes) ==
    LET levelUpdateAction == ReadBytes(bytes, 1) IN IF ~levelUpdateAction.ok THEN Fail ELSE
    LET side == ReadBytes(levelUpdateAction.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET level == ReadBytes(side.rest, 1) IN IF ~level.ok THEN Fail ELSE
    LET price == ReadBytes(level.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET numberOfDeletes == ReadBytes(quantity.rest, 1) IN IF ~numberOfDeletes.ok THEN Fail ELSE
    LET numberOfOrders == ReadBytes(numberOfDeletes.rest, 8) IN IF ~numberOfOrders.ok THEN Fail ELSE
    Ok([ levelUpdateAction |-> levelUpdateAction.value,
         side              |-> side.value,
         level             |-> level.value,
         price             |-> price.value,
         quantity          |-> quantity.value,
         numberOfDeletes   |-> numberOfDeletes.value,
         numberOfOrders    |-> numberOfOrders.value ], numberOfOrders.rest)

ZeroArrayOfLevelItems ==
    [ levelUpdateAction |-> [i \in 1 .. 1 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      level             |-> [i \in 1 .. 1 |-> 0],
      price             |-> [i \in 1 .. 8 |-> 0],
      quantity          |-> [i \in 1 .. 8 |-> 0],
      numberOfDeletes   |-> [i \in 1 .. 1 |-> 0],
      numberOfOrders    |-> [i \in 1 .. 8 |-> 0] ]

(* Array Of Level Items at zero, then each field in turn at the values it is checked at *)
CheckedArrayOfLevelItems ==
    { ZeroArrayOfLevelItems }
        \cup { [ZeroArrayOfLevelItems EXCEPT !.levelUpdateAction = one] : one \in Sample(1) }
        \cup { [ZeroArrayOfLevelItems EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroArrayOfLevelItems EXCEPT !.level = one] : one \in Sample(1) }
        \cup { [ZeroArrayOfLevelItems EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroArrayOfLevelItems EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroArrayOfLevelItems EXCEPT !.numberOfDeletes = one] : one \in Sample(1) }
        \cup { [ZeroArrayOfLevelItems EXCEPT !.numberOfOrders = one] : one \in Sample(8) }

(* A run of Array Of Level Items, written one after another *)
RECURSIVE EncodeArrayOfLevelItemsList(_)
EncodeArrayOfLevelItemsList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeArrayOfLevelItems(Head(messages)) \o EncodeArrayOfLevelItemsList(Tail(messages))

(* As many Array Of Level Items as the field that counts them says *)
RECURSIVE ReadArrayOfLevelItemsList(_, _)
ReadArrayOfLevelItemsList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeArrayOfLevelItems(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadArrayOfLevelItemsList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Array Of Level Items of each kind, for the lists that carry them *)
OneArrayOfLevelItems == { ZeroArrayOfLevelItems }

(***************************************************************************)
(* Market By Price Message                                                 *)
(***************************************************************************)

MarketByPriceMessage ==
    [ timestampNanoseconds : Sample(4),
      orderBookId          : Sample(4),
      maximumLevel         : Sample(1),
      arrayOfLevelItems    : SampleLists(OneArrayOfLevelItems) ]

EncodeMarketByPriceMessage(message) ==
    message.timestampNanoseconds
        \o message.orderBookId
        \o message.maximumLevel
        \o EncodeUIntBE(Len(message.arrayOfLevelItems), 1)
        \o EncodeArrayOfLevelItemsList(message.arrayOfLevelItems)

DecodeMarketByPriceMessage(bytes) ==
    LET timestampNanoseconds == ReadBytes(bytes, 4) IN IF ~timestampNanoseconds.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(timestampNanoseconds.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET maximumLevel == ReadBytes(orderBookId.rest, 1) IN IF ~maximumLevel.ok THEN Fail ELSE
    LET numberOfLevelItems == ReadUIntBE(maximumLevel.rest, 1) IN IF ~numberOfLevelItems.ok THEN Fail ELSE
    LET arrayOfLevelItems == ReadArrayOfLevelItemsList(numberOfLevelItems.rest, numberOfLevelItems.value) IN IF ~arrayOfLevelItems.ok THEN Fail ELSE
    Ok([ timestampNanoseconds |-> timestampNanoseconds.value,
         orderBookId          |-> orderBookId.value,
         maximumLevel         |-> maximumLevel.value,
         arrayOfLevelItems    |-> arrayOfLevelItems.value ], arrayOfLevelItems.rest)

ZeroMarketByPriceMessage ==
    [ timestampNanoseconds |-> [i \in 1 .. 4 |-> 0],
      orderBookId          |-> [i \in 1 .. 4 |-> 0],
      maximumLevel         |-> [i \in 1 .. 1 |-> 0],
      arrayOfLevelItems    |-> << >> ]

(* Market By Price Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketByPriceMessage ==
    { ZeroMarketByPriceMessage }
        \cup { [ZeroMarketByPriceMessage EXCEPT !.timestampNanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroMarketByPriceMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroMarketByPriceMessage EXCEPT !.maximumLevel = one] : one \in Sample(1) }
        \cup { [ZeroMarketByPriceMessage EXCEPT !.arrayOfLevelItems = one] : one \in SampleLists(OneArrayOfLevelItems) }

(***************************************************************************)
(* Trade Statistics Message: 89 bytes                                      *)
(***************************************************************************)

TradeStatisticsMessage ==
    [ timestampNanoseconds           : Sample(4),
      orderBookId                    : Sample(4),
      openPrice                      : Sample(8),
      highPrice                      : Sample(8),
      lowPrice                       : Sample(8),
      lastPrice                      : Sample(8),
      lastAuctionPrice               : Sample(8),
      lastQuantity                   : Sample(8),
      turnoverQuantity               : Sample(8),
      reportedTradesTurnoverQuantity : Sample(8),
      turnoverValue                  : Sample(8),
      numberOfTrades                 : Sample(8),
      trendIndicator                 : Sample(1) ]

EncodeTradeStatisticsMessage(message) ==
    message.timestampNanoseconds
        \o message.orderBookId
        \o message.openPrice
        \o message.highPrice
        \o message.lowPrice
        \o message.lastPrice
        \o message.lastAuctionPrice
        \o message.lastQuantity
        \o message.turnoverQuantity
        \o message.reportedTradesTurnoverQuantity
        \o message.turnoverValue
        \o message.numberOfTrades
        \o message.trendIndicator

DecodeTradeStatisticsMessage(bytes) ==
    LET timestampNanoseconds == ReadBytes(bytes, 4) IN IF ~timestampNanoseconds.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(timestampNanoseconds.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET openPrice == ReadBytes(orderBookId.rest, 8) IN IF ~openPrice.ok THEN Fail ELSE
    LET highPrice == ReadBytes(openPrice.rest, 8) IN IF ~highPrice.ok THEN Fail ELSE
    LET lowPrice == ReadBytes(highPrice.rest, 8) IN IF ~lowPrice.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(lowPrice.rest, 8) IN IF ~lastPrice.ok THEN Fail ELSE
    LET lastAuctionPrice == ReadBytes(lastPrice.rest, 8) IN IF ~lastAuctionPrice.ok THEN Fail ELSE
    LET lastQuantity == ReadBytes(lastAuctionPrice.rest, 8) IN IF ~lastQuantity.ok THEN Fail ELSE
    LET turnoverQuantity == ReadBytes(lastQuantity.rest, 8) IN IF ~turnoverQuantity.ok THEN Fail ELSE
    LET reportedTradesTurnoverQuantity == ReadBytes(turnoverQuantity.rest, 8) IN IF ~reportedTradesTurnoverQuantity.ok THEN Fail ELSE
    LET turnoverValue == ReadBytes(reportedTradesTurnoverQuantity.rest, 8) IN IF ~turnoverValue.ok THEN Fail ELSE
    LET numberOfTrades == ReadBytes(turnoverValue.rest, 8) IN IF ~numberOfTrades.ok THEN Fail ELSE
    LET trendIndicator == ReadBytes(numberOfTrades.rest, 1) IN IF ~trendIndicator.ok THEN Fail ELSE
    Ok([ timestampNanoseconds           |-> timestampNanoseconds.value,
         orderBookId                    |-> orderBookId.value,
         openPrice                      |-> openPrice.value,
         highPrice                      |-> highPrice.value,
         lowPrice                       |-> lowPrice.value,
         lastPrice                      |-> lastPrice.value,
         lastAuctionPrice               |-> lastAuctionPrice.value,
         lastQuantity                   |-> lastQuantity.value,
         turnoverQuantity               |-> turnoverQuantity.value,
         reportedTradesTurnoverQuantity |-> reportedTradesTurnoverQuantity.value,
         turnoverValue                  |-> turnoverValue.value,
         numberOfTrades                 |-> numberOfTrades.value,
         trendIndicator                 |-> trendIndicator.value ], trendIndicator.rest)

ZeroTradeStatisticsMessage ==
    [ timestampNanoseconds           |-> [i \in 1 .. 4 |-> 0],
      orderBookId                    |-> [i \in 1 .. 4 |-> 0],
      openPrice                      |-> [i \in 1 .. 8 |-> 0],
      highPrice                      |-> [i \in 1 .. 8 |-> 0],
      lowPrice                       |-> [i \in 1 .. 8 |-> 0],
      lastPrice                      |-> [i \in 1 .. 8 |-> 0],
      lastAuctionPrice               |-> [i \in 1 .. 8 |-> 0],
      lastQuantity                   |-> [i \in 1 .. 8 |-> 0],
      turnoverQuantity               |-> [i \in 1 .. 8 |-> 0],
      reportedTradesTurnoverQuantity |-> [i \in 1 .. 8 |-> 0],
      turnoverValue                  |-> [i \in 1 .. 8 |-> 0],
      numberOfTrades                 |-> [i \in 1 .. 8 |-> 0],
      trendIndicator                 |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Statistics Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeStatisticsMessage ==
    { ZeroTradeStatisticsMessage }
        \cup { [ZeroTradeStatisticsMessage EXCEPT !.timestampNanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroTradeStatisticsMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroTradeStatisticsMessage EXCEPT !.openPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeStatisticsMessage EXCEPT !.highPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeStatisticsMessage EXCEPT !.lowPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeStatisticsMessage EXCEPT !.lastPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeStatisticsMessage EXCEPT !.lastAuctionPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeStatisticsMessage EXCEPT !.lastQuantity = one] : one \in Sample(8) }
        \cup { [ZeroTradeStatisticsMessage EXCEPT !.turnoverQuantity = one] : one \in Sample(8) }
        \cup { [ZeroTradeStatisticsMessage EXCEPT !.reportedTradesTurnoverQuantity = one] : one \in Sample(8) }
        \cup { [ZeroTradeStatisticsMessage EXCEPT !.turnoverValue = one] : one \in Sample(8) }
        \cup { [ZeroTradeStatisticsMessage EXCEPT !.numberOfTrades = one] : one \in Sample(8) }
        \cup { [ZeroTradeStatisticsMessage EXCEPT !.trendIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Reference Price Message: 29 bytes                                       *)
(***************************************************************************)

ReferencePriceMessage ==
    [ timestampNanoseconds : Sample(4),
      orderBookId          : Sample(4),
      priceType            : Sample(1),
      price                : Sample(8),
      timestamp            : Sample(8),
      priceDate            : Sample(4) ]

EncodeReferencePriceMessage(message) ==
    message.timestampNanoseconds
        \o message.orderBookId
        \o message.priceType
        \o message.price
        \o message.timestamp
        \o message.priceDate

DecodeReferencePriceMessage(bytes) ==
    LET timestampNanoseconds == ReadBytes(bytes, 4) IN IF ~timestampNanoseconds.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(timestampNanoseconds.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET priceType == ReadBytes(orderBookId.rest, 1) IN IF ~priceType.ok THEN Fail ELSE
    LET price == ReadBytes(priceType.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET timestamp == ReadBytes(price.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET priceDate == ReadBytes(timestamp.rest, 4) IN IF ~priceDate.ok THEN Fail ELSE
    Ok([ timestampNanoseconds |-> timestampNanoseconds.value,
         orderBookId          |-> orderBookId.value,
         priceType            |-> priceType.value,
         price                |-> price.value,
         timestamp            |-> timestamp.value,
         priceDate            |-> priceDate.value ], priceDate.rest)

ZeroReferencePriceMessage ==
    [ timestampNanoseconds |-> [i \in 1 .. 4 |-> 0],
      orderBookId          |-> [i \in 1 .. 4 |-> 0],
      priceType            |-> [i \in 1 .. 1 |-> 0],
      price                |-> [i \in 1 .. 8 |-> 0],
      timestamp            |-> [i \in 1 .. 8 |-> 0],
      priceDate            |-> [i \in 1 .. 4 |-> 0] ]

(* Reference Price Message at zero, then each field in turn at the values it is checked at *)
CheckedReferencePriceMessage ==
    { ZeroReferencePriceMessage }
        \cup { [ZeroReferencePriceMessage EXCEPT !.timestampNanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroReferencePriceMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroReferencePriceMessage EXCEPT !.priceType = one] : one \in Sample(1) }
        \cup { [ZeroReferencePriceMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroReferencePriceMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroReferencePriceMessage EXCEPT !.priceDate = one] : one \in Sample(4) }

(***************************************************************************)
(* Index Message: 37 bytes                                                 *)
(***************************************************************************)

IndexMessage ==
    [ timestampNanoseconds : Sample(4),
      orderBookId          : Sample(4),
      lastPrice            : Sample(8),
      timestamp            : Sample(8),
      changePrevious       : Sample(4),
      changeYesterday      : Sample(4),
      trendIndicator       : Sample(1),
      pointOfMovement      : Sample(4) ]

EncodeIndexMessage(message) ==
    message.timestampNanoseconds
        \o message.orderBookId
        \o message.lastPrice
        \o message.timestamp
        \o message.changePrevious
        \o message.changeYesterday
        \o message.trendIndicator
        \o message.pointOfMovement

DecodeIndexMessage(bytes) ==
    LET timestampNanoseconds == ReadBytes(bytes, 4) IN IF ~timestampNanoseconds.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(timestampNanoseconds.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(orderBookId.rest, 8) IN IF ~lastPrice.ok THEN Fail ELSE
    LET timestamp == ReadBytes(lastPrice.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET changePrevious == ReadBytes(timestamp.rest, 4) IN IF ~changePrevious.ok THEN Fail ELSE
    LET changeYesterday == ReadBytes(changePrevious.rest, 4) IN IF ~changeYesterday.ok THEN Fail ELSE
    LET trendIndicator == ReadBytes(changeYesterday.rest, 1) IN IF ~trendIndicator.ok THEN Fail ELSE
    LET pointOfMovement == ReadBytes(trendIndicator.rest, 4) IN IF ~pointOfMovement.ok THEN Fail ELSE
    Ok([ timestampNanoseconds |-> timestampNanoseconds.value,
         orderBookId          |-> orderBookId.value,
         lastPrice            |-> lastPrice.value,
         timestamp            |-> timestamp.value,
         changePrevious       |-> changePrevious.value,
         changeYesterday      |-> changeYesterday.value,
         trendIndicator       |-> trendIndicator.value,
         pointOfMovement      |-> pointOfMovement.value ], pointOfMovement.rest)

ZeroIndexMessage ==
    [ timestampNanoseconds |-> [i \in 1 .. 4 |-> 0],
      orderBookId          |-> [i \in 1 .. 4 |-> 0],
      lastPrice            |-> [i \in 1 .. 8 |-> 0],
      timestamp            |-> [i \in 1 .. 8 |-> 0],
      changePrevious       |-> [i \in 1 .. 4 |-> 0],
      changeYesterday      |-> [i \in 1 .. 4 |-> 0],
      trendIndicator       |-> [i \in 1 .. 1 |-> 0],
      pointOfMovement      |-> [i \in 1 .. 4 |-> 0] ]

(* Index Message at zero, then each field in turn at the values it is checked at *)
CheckedIndexMessage ==
    { ZeroIndexMessage }
        \cup { [ZeroIndexMessage EXCEPT !.timestampNanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroIndexMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroIndexMessage EXCEPT !.lastPrice = one] : one \in Sample(8) }
        \cup { [ZeroIndexMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroIndexMessage EXCEPT !.changePrevious = one] : one \in Sample(4) }
        \cup { [ZeroIndexMessage EXCEPT !.changeYesterday = one] : one \in Sample(4) }
        \cup { [ZeroIndexMessage EXCEPT !.trendIndicator = one] : one \in Sample(1) }
        \cup { [ZeroIndexMessage EXCEPT !.pointOfMovement = one] : one \in Sample(4) }

(***************************************************************************)
(* Open Interest Message: 24 bytes                                         *)
(***************************************************************************)

OpenInterestMessage ==
    [ timestampNanoseconds : Sample(4),
      orderBookId          : Sample(4),
      openInterest         : Sample(8),
      transactTime         : Sample(8) ]

EncodeOpenInterestMessage(message) ==
    message.timestampNanoseconds
        \o message.orderBookId
        \o message.openInterest
        \o message.transactTime

DecodeOpenInterestMessage(bytes) ==
    LET timestampNanoseconds == ReadBytes(bytes, 4) IN IF ~timestampNanoseconds.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(timestampNanoseconds.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET openInterest == ReadBytes(orderBookId.rest, 8) IN IF ~openInterest.ok THEN Fail ELSE
    LET transactTime == ReadBytes(openInterest.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    Ok([ timestampNanoseconds |-> timestampNanoseconds.value,
         orderBookId          |-> orderBookId.value,
         openInterest         |-> openInterest.value,
         transactTime         |-> transactTime.value ], transactTime.rest)

ZeroOpenInterestMessage ==
    [ timestampNanoseconds |-> [i \in 1 .. 4 |-> 0],
      orderBookId          |-> [i \in 1 .. 4 |-> 0],
      openInterest         |-> [i \in 1 .. 8 |-> 0],
      transactTime         |-> [i \in 1 .. 8 |-> 0] ]

(* Open Interest Message at zero, then each field in turn at the values it is checked at *)
CheckedOpenInterestMessage ==
    { ZeroOpenInterestMessage }
        \cup { [ZeroOpenInterestMessage EXCEPT !.timestampNanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOpenInterestMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroOpenInterestMessage EXCEPT !.openInterest = one] : one \in Sample(8) }
        \cup { [ZeroOpenInterestMessage EXCEPT !.transactTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Ticker Message: 91 bytes                                          *)
(***************************************************************************)

TradeTickerMessage ==
    [ timestampNanoseconds : Sample(4),
      orderBookId          : Sample(4),
      dealId               : Sample(8),
      dealSource           : Sample(1),
      price                : Sample(8),
      quantity             : Sample(8),
      dealTime             : Sample(8),
      action               : Sample(1),
      aggressor            : Sample(1),
      tradeReportType      : Sample(2),
      printable            : Sample(1),
      asOfDate             : Sample(4),
      boqList              : Sample(6),
      participantIdBuy     : Sample(5),
      orderIdBuy           : Sample(8),
      participantIdSell    : Sample(5),
      orderIdSell          : Sample(8),
      tradeSlipNumber      : Sample(4),
      exchangeOrderType    : Sample(4),
      tradeCondition       : Sample(1) ]

EncodeTradeTickerMessage(message) ==
    message.timestampNanoseconds
        \o message.orderBookId
        \o message.dealId
        \o message.dealSource
        \o message.price
        \o message.quantity
        \o message.dealTime
        \o message.action
        \o message.aggressor
        \o message.tradeReportType
        \o message.printable
        \o message.asOfDate
        \o message.boqList
        \o message.participantIdBuy
        \o message.orderIdBuy
        \o message.participantIdSell
        \o message.orderIdSell
        \o message.tradeSlipNumber
        \o message.exchangeOrderType
        \o message.tradeCondition

DecodeTradeTickerMessage(bytes) ==
    LET timestampNanoseconds == ReadBytes(bytes, 4) IN IF ~timestampNanoseconds.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(timestampNanoseconds.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET dealId == ReadBytes(orderBookId.rest, 8) IN IF ~dealId.ok THEN Fail ELSE
    LET dealSource == ReadBytes(dealId.rest, 1) IN IF ~dealSource.ok THEN Fail ELSE
    LET price == ReadBytes(dealSource.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET dealTime == ReadBytes(quantity.rest, 8) IN IF ~dealTime.ok THEN Fail ELSE
    LET action == ReadBytes(dealTime.rest, 1) IN IF ~action.ok THEN Fail ELSE
    LET aggressor == ReadBytes(action.rest, 1) IN IF ~aggressor.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(aggressor.rest, 2) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET printable == ReadBytes(tradeReportType.rest, 1) IN IF ~printable.ok THEN Fail ELSE
    LET asOfDate == ReadBytes(printable.rest, 4) IN IF ~asOfDate.ok THEN Fail ELSE
    LET boqList == ReadBytes(asOfDate.rest, 6) IN IF ~boqList.ok THEN Fail ELSE
    LET participantIdBuy == ReadBytes(boqList.rest, 5) IN IF ~participantIdBuy.ok THEN Fail ELSE
    LET orderIdBuy == ReadBytes(participantIdBuy.rest, 8) IN IF ~orderIdBuy.ok THEN Fail ELSE
    LET participantIdSell == ReadBytes(orderIdBuy.rest, 5) IN IF ~participantIdSell.ok THEN Fail ELSE
    LET orderIdSell == ReadBytes(participantIdSell.rest, 8) IN IF ~orderIdSell.ok THEN Fail ELSE
    LET tradeSlipNumber == ReadBytes(orderIdSell.rest, 4) IN IF ~tradeSlipNumber.ok THEN Fail ELSE
    LET exchangeOrderType == ReadBytes(tradeSlipNumber.rest, 4) IN IF ~exchangeOrderType.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(exchangeOrderType.rest, 1) IN IF ~tradeCondition.ok THEN Fail ELSE
    Ok([ timestampNanoseconds |-> timestampNanoseconds.value,
         orderBookId          |-> orderBookId.value,
         dealId               |-> dealId.value,
         dealSource           |-> dealSource.value,
         price                |-> price.value,
         quantity             |-> quantity.value,
         dealTime             |-> dealTime.value,
         action               |-> action.value,
         aggressor            |-> aggressor.value,
         tradeReportType      |-> tradeReportType.value,
         printable            |-> printable.value,
         asOfDate             |-> asOfDate.value,
         boqList              |-> boqList.value,
         participantIdBuy     |-> participantIdBuy.value,
         orderIdBuy           |-> orderIdBuy.value,
         participantIdSell    |-> participantIdSell.value,
         orderIdSell          |-> orderIdSell.value,
         tradeSlipNumber      |-> tradeSlipNumber.value,
         exchangeOrderType    |-> exchangeOrderType.value,
         tradeCondition       |-> tradeCondition.value ], tradeCondition.rest)

ZeroTradeTickerMessage ==
    [ timestampNanoseconds |-> [i \in 1 .. 4 |-> 0],
      orderBookId          |-> [i \in 1 .. 4 |-> 0],
      dealId               |-> [i \in 1 .. 8 |-> 0],
      dealSource           |-> [i \in 1 .. 1 |-> 0],
      price                |-> [i \in 1 .. 8 |-> 0],
      quantity             |-> [i \in 1 .. 8 |-> 0],
      dealTime             |-> [i \in 1 .. 8 |-> 0],
      action               |-> [i \in 1 .. 1 |-> 0],
      aggressor            |-> [i \in 1 .. 1 |-> 0],
      tradeReportType      |-> [i \in 1 .. 2 |-> 0],
      printable            |-> [i \in 1 .. 1 |-> 0],
      asOfDate             |-> [i \in 1 .. 4 |-> 0],
      boqList              |-> [i \in 1 .. 6 |-> 0],
      participantIdBuy     |-> [i \in 1 .. 5 |-> 0],
      orderIdBuy           |-> [i \in 1 .. 8 |-> 0],
      participantIdSell    |-> [i \in 1 .. 5 |-> 0],
      orderIdSell          |-> [i \in 1 .. 8 |-> 0],
      tradeSlipNumber      |-> [i \in 1 .. 4 |-> 0],
      exchangeOrderType    |-> [i \in 1 .. 4 |-> 0],
      tradeCondition       |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Ticker Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeTickerMessage ==
    { ZeroTradeTickerMessage }
        \cup { [ZeroTradeTickerMessage EXCEPT !.timestampNanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroTradeTickerMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroTradeTickerMessage EXCEPT !.dealId = one] : one \in Sample(8) }
        \cup { [ZeroTradeTickerMessage EXCEPT !.dealSource = one] : one \in Sample(1) }
        \cup { [ZeroTradeTickerMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeTickerMessage EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroTradeTickerMessage EXCEPT !.dealTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeTickerMessage EXCEPT !.action = one] : one \in Sample(1) }
        \cup { [ZeroTradeTickerMessage EXCEPT !.aggressor = one] : one \in Sample(1) }
        \cup { [ZeroTradeTickerMessage EXCEPT !.tradeReportType = one] : one \in Sample(2) }
        \cup { [ZeroTradeTickerMessage EXCEPT !.printable = one] : one \in Sample(1) }
        \cup { [ZeroTradeTickerMessage EXCEPT !.asOfDate = one] : one \in Sample(4) }
        \cup { [ZeroTradeTickerMessage EXCEPT !.boqList = one] : one \in Sample(6) }
        \cup { [ZeroTradeTickerMessage EXCEPT !.participantIdBuy = one] : one \in Sample(5) }
        \cup { [ZeroTradeTickerMessage EXCEPT !.orderIdBuy = one] : one \in Sample(8) }
        \cup { [ZeroTradeTickerMessage EXCEPT !.participantIdSell = one] : one \in Sample(5) }
        \cup { [ZeroTradeTickerMessage EXCEPT !.orderIdSell = one] : one \in Sample(8) }
        \cup { [ZeroTradeTickerMessage EXCEPT !.tradeSlipNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeTickerMessage EXCEPT !.exchangeOrderType = one] : one \in Sample(4) }
        \cup { [ZeroTradeTickerMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Price Limits Message: 34 bytes                                          *)
(***************************************************************************)

PriceLimitsMessage ==
    [ timestampNanoseconds : Sample(4),
      orderBookId          : Sample(4),
      upperLimit           : Sample(8),
      lowerLimit           : Sample(8),
      type                 : Sample(1),
      category             : Sample(1),
      referencePrice       : Sample(8) ]

EncodePriceLimitsMessage(message) ==
    message.timestampNanoseconds
        \o message.orderBookId
        \o message.upperLimit
        \o message.lowerLimit
        \o message.type
        \o message.category
        \o message.referencePrice

DecodePriceLimitsMessage(bytes) ==
    LET timestampNanoseconds == ReadBytes(bytes, 4) IN IF ~timestampNanoseconds.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(timestampNanoseconds.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET upperLimit == ReadBytes(orderBookId.rest, 8) IN IF ~upperLimit.ok THEN Fail ELSE
    LET lowerLimit == ReadBytes(upperLimit.rest, 8) IN IF ~lowerLimit.ok THEN Fail ELSE
    LET type == ReadBytes(lowerLimit.rest, 1) IN IF ~type.ok THEN Fail ELSE
    LET category == ReadBytes(type.rest, 1) IN IF ~category.ok THEN Fail ELSE
    LET referencePrice == ReadBytes(category.rest, 8) IN IF ~referencePrice.ok THEN Fail ELSE
    Ok([ timestampNanoseconds |-> timestampNanoseconds.value,
         orderBookId          |-> orderBookId.value,
         upperLimit           |-> upperLimit.value,
         lowerLimit           |-> lowerLimit.value,
         type                 |-> type.value,
         category             |-> category.value,
         referencePrice       |-> referencePrice.value ], referencePrice.rest)

ZeroPriceLimitsMessage ==
    [ timestampNanoseconds |-> [i \in 1 .. 4 |-> 0],
      orderBookId          |-> [i \in 1 .. 4 |-> 0],
      upperLimit           |-> [i \in 1 .. 8 |-> 0],
      lowerLimit           |-> [i \in 1 .. 8 |-> 0],
      type                 |-> [i \in 1 .. 1 |-> 0],
      category             |-> [i \in 1 .. 1 |-> 0],
      referencePrice       |-> [i \in 1 .. 8 |-> 0] ]

(* Price Limits Message at zero, then each field in turn at the values it is checked at *)
CheckedPriceLimitsMessage ==
    { ZeroPriceLimitsMessage }
        \cup { [ZeroPriceLimitsMessage EXCEPT !.timestampNanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroPriceLimitsMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroPriceLimitsMessage EXCEPT !.upperLimit = one] : one \in Sample(8) }
        \cup { [ZeroPriceLimitsMessage EXCEPT !.lowerLimit = one] : one \in Sample(8) }
        \cup { [ZeroPriceLimitsMessage EXCEPT !.type = one] : one \in Sample(1) }
        \cup { [ZeroPriceLimitsMessage EXCEPT !.category = one] : one \in Sample(1) }
        \cup { [ZeroPriceLimitsMessage EXCEPT !.referencePrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Array Of Message Items: 80 bytes                                        *)
(***************************************************************************)

ArrayOfMessageItems ==
    [ messageItem : Sample(80) ]

EncodeArrayOfMessageItems(message) ==
    message.messageItem

DecodeArrayOfMessageItems(bytes) ==
    LET messageItem == ReadBytes(bytes, 80) IN IF ~messageItem.ok THEN Fail ELSE
    Ok([ messageItem |-> messageItem.value ], messageItem.rest)

ZeroArrayOfMessageItems ==
    [ messageItem |-> [i \in 1 .. 80 |-> 0] ]

(* Array Of Message Items at zero, then each field in turn at the values it is checked at *)
CheckedArrayOfMessageItems ==
    { ZeroArrayOfMessageItems }
        \cup { [ZeroArrayOfMessageItems EXCEPT !.messageItem = one] : one \in Sample(80) }

(* A run of Array Of Message Items, written one after another *)
RECURSIVE EncodeArrayOfMessageItemsList(_)
EncodeArrayOfMessageItemsList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeArrayOfMessageItems(Head(messages)) \o EncodeArrayOfMessageItemsList(Tail(messages))

(* As many Array Of Message Items as the field that counts them says *)
RECURSIVE ReadArrayOfMessageItemsList(_, _)
ReadArrayOfMessageItemsList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeArrayOfMessageItems(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadArrayOfMessageItemsList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Array Of Message Items of each kind, for the lists that carry them *)
OneArrayOfMessageItems == { ZeroArrayOfMessageItems }

(***************************************************************************)
(* Market Announcement Message                                             *)
(***************************************************************************)

MarketAnnouncementMessage ==
    [ timestampNanoseconds   : Sample(4),
      orderBookId            : Sample(4),
      exchangeId             : Sample(4),
      marketId               : Sample(4),
      messageInformationType : Sample(1),
      messageSource          : Sample(80),
      messagePriority        : Sample(1),
      header                 : Sample(80),
      itemsUrl               : Sample(1),
      documentUrl            : Sample(255),
      numberOfMessagesItems  : Sample(1),
      arrayOfMessageItems    : SampleLists(OneArrayOfMessageItems),
      commodityCode          : Sample(4) ]

EncodeMarketAnnouncementMessage(message) ==
    message.timestampNanoseconds
        \o message.orderBookId
        \o message.exchangeId
        \o message.marketId
        \o message.messageInformationType
        \o message.messageSource
        \o message.messagePriority
        \o message.header
        \o message.itemsUrl
        \o message.documentUrl
        \o EncodeUIntBE(Len(message.arrayOfMessageItems), 1)
        \o message.numberOfMessagesItems
        \o EncodeArrayOfMessageItemsList(message.arrayOfMessageItems)
        \o message.commodityCode

DecodeMarketAnnouncementMessage(bytes) ==
    LET timestampNanoseconds == ReadBytes(bytes, 4) IN IF ~timestampNanoseconds.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(timestampNanoseconds.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(orderBookId.rest, 4) IN IF ~exchangeId.ok THEN Fail ELSE
    LET marketId == ReadBytes(exchangeId.rest, 4) IN IF ~marketId.ok THEN Fail ELSE
    LET messageInformationType == ReadBytes(marketId.rest, 1) IN IF ~messageInformationType.ok THEN Fail ELSE
    LET messageSource == ReadBytes(messageInformationType.rest, 80) IN IF ~messageSource.ok THEN Fail ELSE
    LET messagePriority == ReadBytes(messageSource.rest, 1) IN IF ~messagePriority.ok THEN Fail ELSE
    LET header == ReadBytes(messagePriority.rest, 80) IN IF ~header.ok THEN Fail ELSE
    LET itemsUrl == ReadBytes(header.rest, 1) IN IF ~itemsUrl.ok THEN Fail ELSE
    LET documentUrl == ReadBytes(itemsUrl.rest, 255) IN IF ~documentUrl.ok THEN Fail ELSE
    LET numberOfMessageItems == ReadUIntBE(documentUrl.rest, 1) IN IF ~numberOfMessageItems.ok THEN Fail ELSE
    LET numberOfMessagesItems == ReadBytes(numberOfMessageItems.rest, 1) IN IF ~numberOfMessagesItems.ok THEN Fail ELSE
    LET arrayOfMessageItems == ReadArrayOfMessageItemsList(numberOfMessagesItems.rest, numberOfMessageItems.value) IN IF ~arrayOfMessageItems.ok THEN Fail ELSE
    LET commodityCode == ReadBytes(arrayOfMessageItems.rest, 4) IN IF ~commodityCode.ok THEN Fail ELSE
    Ok([ timestampNanoseconds   |-> timestampNanoseconds.value,
         orderBookId            |-> orderBookId.value,
         exchangeId             |-> exchangeId.value,
         marketId               |-> marketId.value,
         messageInformationType |-> messageInformationType.value,
         messageSource          |-> messageSource.value,
         messagePriority        |-> messagePriority.value,
         header                 |-> header.value,
         itemsUrl               |-> itemsUrl.value,
         documentUrl            |-> documentUrl.value,
         numberOfMessagesItems  |-> numberOfMessagesItems.value,
         arrayOfMessageItems    |-> arrayOfMessageItems.value,
         commodityCode          |-> commodityCode.value ], commodityCode.rest)

ZeroMarketAnnouncementMessage ==
    [ timestampNanoseconds   |-> [i \in 1 .. 4 |-> 0],
      orderBookId            |-> [i \in 1 .. 4 |-> 0],
      exchangeId             |-> [i \in 1 .. 4 |-> 0],
      marketId               |-> [i \in 1 .. 4 |-> 0],
      messageInformationType |-> [i \in 1 .. 1 |-> 0],
      messageSource          |-> [i \in 1 .. 80 |-> 0],
      messagePriority        |-> [i \in 1 .. 1 |-> 0],
      header                 |-> [i \in 1 .. 80 |-> 0],
      itemsUrl               |-> [i \in 1 .. 1 |-> 0],
      documentUrl            |-> [i \in 1 .. 255 |-> 0],
      numberOfMessagesItems  |-> [i \in 1 .. 1 |-> 0],
      arrayOfMessageItems    |-> << >>,
      commodityCode          |-> [i \in 1 .. 4 |-> 0] ]

(* Market Announcement Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketAnnouncementMessage ==
    { ZeroMarketAnnouncementMessage }
        \cup { [ZeroMarketAnnouncementMessage EXCEPT !.timestampNanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroMarketAnnouncementMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroMarketAnnouncementMessage EXCEPT !.exchangeId = one] : one \in Sample(4) }
        \cup { [ZeroMarketAnnouncementMessage EXCEPT !.marketId = one] : one \in Sample(4) }
        \cup { [ZeroMarketAnnouncementMessage EXCEPT !.messageInformationType = one] : one \in Sample(1) }
        \cup { [ZeroMarketAnnouncementMessage EXCEPT !.messageSource = one] : one \in Sample(80) }
        \cup { [ZeroMarketAnnouncementMessage EXCEPT !.messagePriority = one] : one \in Sample(1) }
        \cup { [ZeroMarketAnnouncementMessage EXCEPT !.header = one] : one \in Sample(80) }
        \cup { [ZeroMarketAnnouncementMessage EXCEPT !.itemsUrl = one] : one \in Sample(1) }
        \cup { [ZeroMarketAnnouncementMessage EXCEPT !.documentUrl = one] : one \in Sample(255) }
        \cup { [ZeroMarketAnnouncementMessage EXCEPT !.numberOfMessagesItems = one] : one \in Sample(1) }
        \cup { [ZeroMarketAnnouncementMessage EXCEPT !.arrayOfMessageItems = one] : one \in SampleLists(OneArrayOfMessageItems) }
        \cup { [ZeroMarketAnnouncementMessage EXCEPT !.commodityCode = one] : one \in Sample(4) }

(***************************************************************************)
(* End Of Snapshot Message: 20 bytes                                       *)
(***************************************************************************)

EndOfSnapshotMessage ==
    [ snapshotSequenceNumber : Sample(20) ]

EncodeEndOfSnapshotMessage(message) ==
    message.snapshotSequenceNumber

DecodeEndOfSnapshotMessage(bytes) ==
    LET snapshotSequenceNumber == ReadBytes(bytes, 20) IN IF ~snapshotSequenceNumber.ok THEN Fail ELSE
    Ok([ snapshotSequenceNumber |-> snapshotSequenceNumber.value ], snapshotSequenceNumber.rest)

ZeroEndOfSnapshotMessage ==
    [ snapshotSequenceNumber |-> [i \in 1 .. 20 |-> 0] ]

(* End Of Snapshot Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfSnapshotMessage ==
    { ZeroEndOfSnapshotMessage }
        \cup { [ZeroEndOfSnapshotMessage EXCEPT !.snapshotSequenceNumber = one] : one \in Sample(20) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

SecondsMessageCode == 84  \* "T"
OrderBookDirectoryMessageCode == 82  \* "R"
ExchangeDirectoryMessageCode == 101  \* "e"
MarketDirectoryMessageCode == 109  \* "m"
CombinationOrderBookLegDirectoryMessageCode == 77  \* "M"
TickSizeTableEntryMessageCode == 76  \* "L"
CorporateActionEntryMessageCode == 67  \* "C"
OrderBookDirectoryExtensionMessageCode == 102  \* "f"
SystemEventMessageCode == 83  \* "S"
OrderBookStateMessageCode == 79  \* "O"
BusinessDateMessageCode == 66  \* "B"
InstrumentStatusMessageCode == 116  \* "t"
EquilibriumPriceMessageCode == 90  \* "Z"
MarketByPriceMessageCode == 98  \* "b"
TradeStatisticsMessageCode == 73  \* "I"
ReferencePriceMessageCode == 81  \* "Q"
IndexMessageCode == 74  \* "J"
OpenInterestMessageCode == 104  \* "h"
TradeTickerMessageCode == 105  \* "i"
PriceLimitsMessageCode == 107  \* "k"
MarketAnnouncementMessageCode == 78  \* "N"
EndOfSnapshotMessageCode == 71  \* "G"

Payload ==
    [ tag : {SecondsMessageCode}, body : SecondsMessage ]
        \cup [ tag : {OrderBookDirectoryMessageCode}, body : OrderBookDirectoryMessage ]
        \cup [ tag : {ExchangeDirectoryMessageCode}, body : ExchangeDirectoryMessage ]
        \cup [ tag : {MarketDirectoryMessageCode}, body : MarketDirectoryMessage ]
        \cup [ tag : {CombinationOrderBookLegDirectoryMessageCode}, body : CombinationOrderBookLegDirectoryMessage ]
        \cup [ tag : {TickSizeTableEntryMessageCode}, body : TickSizeTableEntryMessage ]
        \cup [ tag : {CorporateActionEntryMessageCode}, body : CorporateActionEntryMessage ]
        \cup [ tag : {OrderBookDirectoryExtensionMessageCode}, body : OrderBookDirectoryExtensionMessage ]
        \cup [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {OrderBookStateMessageCode}, body : OrderBookStateMessage ]
        \cup [ tag : {BusinessDateMessageCode}, body : BusinessDateMessage ]
        \cup [ tag : {InstrumentStatusMessageCode}, body : InstrumentStatusMessage ]
        \cup [ tag : {EquilibriumPriceMessageCode}, body : EquilibriumPriceMessage ]
        \cup [ tag : {MarketByPriceMessageCode}, body : MarketByPriceMessage ]
        \cup [ tag : {TradeStatisticsMessageCode}, body : TradeStatisticsMessage ]
        \cup [ tag : {ReferencePriceMessageCode}, body : ReferencePriceMessage ]
        \cup [ tag : {IndexMessageCode}, body : IndexMessage ]
        \cup [ tag : {OpenInterestMessageCode}, body : OpenInterestMessage ]
        \cup [ tag : {TradeTickerMessageCode}, body : TradeTickerMessage ]
        \cup [ tag : {PriceLimitsMessageCode}, body : PriceLimitsMessage ]
        \cup [ tag : {MarketAnnouncementMessageCode}, body : MarketAnnouncementMessage ]
        \cup [ tag : {EndOfSnapshotMessageCode}, body : EndOfSnapshotMessage ]

EncodePayload(message) ==
    CASE message.tag = SecondsMessageCode -> EncodeSecondsMessage(message.body)
      [] message.tag = OrderBookDirectoryMessageCode -> EncodeOrderBookDirectoryMessage(message.body)
      [] message.tag = ExchangeDirectoryMessageCode -> EncodeExchangeDirectoryMessage(message.body)
      [] message.tag = MarketDirectoryMessageCode -> EncodeMarketDirectoryMessage(message.body)
      [] message.tag = CombinationOrderBookLegDirectoryMessageCode -> EncodeCombinationOrderBookLegDirectoryMessage(message.body)
      [] message.tag = TickSizeTableEntryMessageCode -> EncodeTickSizeTableEntryMessage(message.body)
      [] message.tag = CorporateActionEntryMessageCode -> EncodeCorporateActionEntryMessage(message.body)
      [] message.tag = OrderBookDirectoryExtensionMessageCode -> EncodeOrderBookDirectoryExtensionMessage(message.body)
      [] message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = OrderBookStateMessageCode -> EncodeOrderBookStateMessage(message.body)
      [] message.tag = BusinessDateMessageCode -> EncodeBusinessDateMessage(message.body)
      [] message.tag = InstrumentStatusMessageCode -> EncodeInstrumentStatusMessage(message.body)
      [] message.tag = EquilibriumPriceMessageCode -> EncodeEquilibriumPriceMessage(message.body)
      [] message.tag = MarketByPriceMessageCode -> EncodeMarketByPriceMessage(message.body)
      [] message.tag = TradeStatisticsMessageCode -> EncodeTradeStatisticsMessage(message.body)
      [] message.tag = ReferencePriceMessageCode -> EncodeReferencePriceMessage(message.body)
      [] message.tag = IndexMessageCode -> EncodeIndexMessage(message.body)
      [] message.tag = OpenInterestMessageCode -> EncodeOpenInterestMessage(message.body)
      [] message.tag = TradeTickerMessageCode -> EncodeTradeTickerMessage(message.body)
      [] message.tag = PriceLimitsMessageCode -> EncodePriceLimitsMessage(message.body)
      [] message.tag = MarketAnnouncementMessageCode -> EncodeMarketAnnouncementMessage(message.body)
      [] message.tag = EndOfSnapshotMessageCode -> EncodeEndOfSnapshotMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = SecondsMessageCode -> DecodeSecondsMessage(bytes)
              [] tag = OrderBookDirectoryMessageCode -> DecodeOrderBookDirectoryMessage(bytes)
              [] tag = ExchangeDirectoryMessageCode -> DecodeExchangeDirectoryMessage(bytes)
              [] tag = MarketDirectoryMessageCode -> DecodeMarketDirectoryMessage(bytes)
              [] tag = CombinationOrderBookLegDirectoryMessageCode -> DecodeCombinationOrderBookLegDirectoryMessage(bytes)
              [] tag = TickSizeTableEntryMessageCode -> DecodeTickSizeTableEntryMessage(bytes)
              [] tag = CorporateActionEntryMessageCode -> DecodeCorporateActionEntryMessage(bytes)
              [] tag = OrderBookDirectoryExtensionMessageCode -> DecodeOrderBookDirectoryExtensionMessage(bytes)
              [] tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = OrderBookStateMessageCode -> DecodeOrderBookStateMessage(bytes)
              [] tag = BusinessDateMessageCode -> DecodeBusinessDateMessage(bytes)
              [] tag = InstrumentStatusMessageCode -> DecodeInstrumentStatusMessage(bytes)
              [] tag = EquilibriumPriceMessageCode -> DecodeEquilibriumPriceMessage(bytes)
              [] tag = MarketByPriceMessageCode -> DecodeMarketByPriceMessage(bytes)
              [] tag = TradeStatisticsMessageCode -> DecodeTradeStatisticsMessage(bytes)
              [] tag = ReferencePriceMessageCode -> DecodeReferencePriceMessage(bytes)
              [] tag = IndexMessageCode -> DecodeIndexMessage(bytes)
              [] tag = OpenInterestMessageCode -> DecodeOpenInterestMessage(bytes)
              [] tag = TradeTickerMessageCode -> DecodeTradeTickerMessage(bytes)
              [] tag = PriceLimitsMessageCode -> DecodePriceLimitsMessage(bytes)
              [] tag = MarketAnnouncementMessageCode -> DecodeMarketAnnouncementMessage(bytes)
              [] tag = EndOfSnapshotMessageCode -> DecodeEndOfSnapshotMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> SecondsMessageCode, body |-> ZeroSecondsMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> SecondsMessageCode, body |-> one] : one \in CheckedSecondsMessage }
        \cup { [tag |-> OrderBookDirectoryMessageCode, body |-> one] : one \in CheckedOrderBookDirectoryMessage }
        \cup { [tag |-> ExchangeDirectoryMessageCode, body |-> one] : one \in CheckedExchangeDirectoryMessage }
        \cup { [tag |-> MarketDirectoryMessageCode, body |-> one] : one \in CheckedMarketDirectoryMessage }
        \cup { [tag |-> CombinationOrderBookLegDirectoryMessageCode, body |-> one] : one \in CheckedCombinationOrderBookLegDirectoryMessage }
        \cup { [tag |-> TickSizeTableEntryMessageCode, body |-> one] : one \in CheckedTickSizeTableEntryMessage }
        \cup { [tag |-> CorporateActionEntryMessageCode, body |-> one] : one \in CheckedCorporateActionEntryMessage }
        \cup { [tag |-> OrderBookDirectoryExtensionMessageCode, body |-> one] : one \in CheckedOrderBookDirectoryExtensionMessage }
        \cup { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> OrderBookStateMessageCode, body |-> one] : one \in CheckedOrderBookStateMessage }
        \cup { [tag |-> BusinessDateMessageCode, body |-> one] : one \in CheckedBusinessDateMessage }
        \cup { [tag |-> InstrumentStatusMessageCode, body |-> one] : one \in CheckedInstrumentStatusMessage }
        \cup { [tag |-> EquilibriumPriceMessageCode, body |-> one] : one \in CheckedEquilibriumPriceMessage }
        \cup { [tag |-> MarketByPriceMessageCode, body |-> one] : one \in CheckedMarketByPriceMessage }
        \cup { [tag |-> TradeStatisticsMessageCode, body |-> one] : one \in CheckedTradeStatisticsMessage }
        \cup { [tag |-> ReferencePriceMessageCode, body |-> one] : one \in CheckedReferencePriceMessage }
        \cup { [tag |-> IndexMessageCode, body |-> one] : one \in CheckedIndexMessage }
        \cup { [tag |-> OpenInterestMessageCode, body |-> one] : one \in CheckedOpenInterestMessage }
        \cup { [tag |-> TradeTickerMessageCode, body |-> one] : one \in CheckedTradeTickerMessage }
        \cup { [tag |-> PriceLimitsMessageCode, body |-> one] : one \in CheckedPriceLimitsMessage }
        \cup { [tag |-> MarketAnnouncementMessageCode, body |-> one] : one \in CheckedMarketAnnouncementMessage }
        \cup { [tag |-> EndOfSnapshotMessageCode, body |-> one] : one \in CheckedEndOfSnapshotMessage }

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
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderBookDirectoryMessageCode, body |-> ZeroOrderBookDirectoryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ExchangeDirectoryMessageCode, body |-> ZeroExchangeDirectoryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MarketDirectoryMessageCode, body |-> ZeroMarketDirectoryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CombinationOrderBookLegDirectoryMessageCode, body |-> ZeroCombinationOrderBookLegDirectoryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TickSizeTableEntryMessageCode, body |-> ZeroTickSizeTableEntryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CorporateActionEntryMessageCode, body |-> ZeroCorporateActionEntryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderBookDirectoryExtensionMessageCode, body |-> ZeroOrderBookDirectoryExtensionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderBookStateMessageCode, body |-> ZeroOrderBookStateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> BusinessDateMessageCode, body |-> ZeroBusinessDateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> InstrumentStatusMessageCode, body |-> ZeroInstrumentStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EquilibriumPriceMessageCode, body |-> ZeroEquilibriumPriceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MarketByPriceMessageCode, body |-> ZeroMarketByPriceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeStatisticsMessageCode, body |-> ZeroTradeStatisticsMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ReferencePriceMessageCode, body |-> ZeroReferencePriceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> IndexMessageCode, body |-> ZeroIndexMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OpenInterestMessageCode, body |-> ZeroOpenInterestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeTickerMessageCode, body |-> ZeroTradeTickerMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> PriceLimitsMessageCode, body |-> ZeroPriceLimitsMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MarketAnnouncementMessageCode, body |-> ZeroMarketAnnouncementMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EndOfSnapshotMessageCode, body |-> ZeroEndOfSnapshotMessage]] }

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

(* Every Order Book Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderBookDirectoryMessage ==
    \A message \in CheckedOrderBookDirectoryMessage :
        LET read == DecodeOrderBookDirectoryMessage(EncodeOrderBookDirectoryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Exchange Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExchangeDirectoryMessage ==
    \A message \in CheckedExchangeDirectoryMessage :
        LET read == DecodeExchangeDirectoryMessage(EncodeExchangeDirectoryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketDirectoryMessage ==
    \A message \in CheckedMarketDirectoryMessage :
        LET read == DecodeMarketDirectoryMessage(EncodeMarketDirectoryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Combination Order Book Leg Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCombinationOrderBookLegDirectoryMessage ==
    \A message \in CheckedCombinationOrderBookLegDirectoryMessage :
        LET read == DecodeCombinationOrderBookLegDirectoryMessage(EncodeCombinationOrderBookLegDirectoryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tick Size Table Entry Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTickSizeTableEntryMessage ==
    \A message \in CheckedTickSizeTableEntryMessage :
        LET read == DecodeTickSizeTableEntryMessage(EncodeTickSizeTableEntryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Corporate Action Entry Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCorporateActionEntryMessage ==
    \A message \in CheckedCorporateActionEntryMessage :
        LET read == DecodeCorporateActionEntryMessage(EncodeCorporateActionEntryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Book Directory Extension Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderBookDirectoryExtensionMessage ==
    \A message \in CheckedOrderBookDirectoryExtensionMessage :
        LET read == DecodeOrderBookDirectoryExtensionMessage(EncodeOrderBookDirectoryExtensionMessage(message))
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

(* Every Business Date Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBusinessDateMessage ==
    \A message \in CheckedBusinessDateMessage :
        LET read == DecodeBusinessDateMessage(EncodeBusinessDateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentStatusMessage ==
    \A message \in CheckedInstrumentStatusMessage :
        LET read == DecodeInstrumentStatusMessage(EncodeInstrumentStatusMessage(message))
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

(* Every Array Of Level Items decodes back to what was encoded, and leaves nothing over *)
RoundTripArrayOfLevelItems ==
    \A message \in CheckedArrayOfLevelItems :
        LET read == DecodeArrayOfLevelItems(EncodeArrayOfLevelItems(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market By Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketByPriceMessage ==
    \A message \in CheckedMarketByPriceMessage :
        LET read == DecodeMarketByPriceMessage(EncodeMarketByPriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Statistics Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeStatisticsMessage ==
    \A message \in CheckedTradeStatisticsMessage :
        LET read == DecodeTradeStatisticsMessage(EncodeTradeStatisticsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reference Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReferencePriceMessage ==
    \A message \in CheckedReferencePriceMessage :
        LET read == DecodeReferencePriceMessage(EncodeReferencePriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Index Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIndexMessage ==
    \A message \in CheckedIndexMessage :
        LET read == DecodeIndexMessage(EncodeIndexMessage(message))
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

(* Every Trade Ticker Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeTickerMessage ==
    \A message \in CheckedTradeTickerMessage :
        LET read == DecodeTradeTickerMessage(EncodeTradeTickerMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price Limits Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPriceLimitsMessage ==
    \A message \in CheckedPriceLimitsMessage :
        LET read == DecodePriceLimitsMessage(EncodePriceLimitsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Array Of Message Items decodes back to what was encoded, and leaves nothing over *)
RoundTripArrayOfMessageItems ==
    \A message \in CheckedArrayOfMessageItems :
        LET read == DecodeArrayOfMessageItems(EncodeArrayOfMessageItems(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Announcement Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketAnnouncementMessage ==
    \A message \in CheckedMarketAnnouncementMessage :
        LET read == DecodeMarketAnnouncementMessage(EncodeMarketAnnouncementMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Snapshot Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfSnapshotMessage ==
    \A message \in CheckedEndOfSnapshotMessage :
        LET read == DecodeEndOfSnapshotMessage(EncodeEndOfSnapshotMessage(message))
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
        LET sent == EncodePayload(message)
            read == DecodePayload(message.tag, sent)
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
