------------------- MODULE BondSpot_PricesAndTrades_v6_8 -------------------
(***************************************************************************)
(* Giełda Papierów Wartościowych w Warszawie BondSpot Prices and Trades    *)
(* v6.8                                                                    *)
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
(* Note: a Delivery Flag of 16 to 255 says Message Buffer was transformed, *)
(* and one of 0 to 15 that it was not, so it is then read as it stands.    *)
(*                                                                         *)
(* Note: Message Buffer untransformed is as many Message as Number Msg     *)
(* Entries says, which is read beside the flag and handed to the choice:   *)
(* the count says how many the bytes hold, and transformed they hold a run *)
(* no reading of them states, so it is carried rather than written from    *)
(* the run.                                                                *)
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
(* Message Buffer                                                          *)
(***************************************************************************)

MessageBufferZlib ==
    [ transformed : SampleBytes ]

EncodeMessageBufferZlib(message) ==
    message.transformed

DecodeMessageBufferZlib(bytes) ==
    LET transformed == Ok(bytes, << >>) IN IF ~transformed.ok THEN Fail ELSE
    Ok([ transformed |-> transformed.value ], transformed.rest)

ZeroMessageBufferZlib ==
    [ transformed |-> << >> ]

(* Message Buffer at zero, then each field in turn at the values it is checked at *)
CheckedMessageBufferZlib ==
    { ZeroMessageBufferZlib }
        \cup { [ZeroMessageBufferZlib EXCEPT !.transformed = one] : one \in SampleBytes }

(***************************************************************************)
(* Trade Full Information Message: 272 bytes                               *)
(***************************************************************************)

TradeFullInformationMessage ==
    [ symbolIndex                 : Sample(4),
      sourceTime                  : Sample(4),
      tradeIdNumber               : Sample(4),
      venueOfExecution            : Sample(4),
      sourceSeqNum                : Sample(4),
      priceNotation               : Sample(4),
      transactionToBeCleared      : Sample(4),
      cumulativeQuantity          : Sample(4),
      highestPrice                : Sample(4),
      lowestPrice                 : Sample(4),
      variationLastPrice          : Sample(4),
      systemId                    : Sample(4),
      sourceTimeMicroSecs         : Sample(2),
      priceCurrency               : Sample(3),
      lastTradeIndicator          : Sample(1),
      typeOfTrade                 : Sample(1),
      tradeOrigin                 : Sample(1),
      tickDirection               : Sample(1),
      openingTradeIndicator       : Sample(1),
      variationScaleCode          : Sample(1),
      priceScaleCode              : Sample(1),
      tradingDateTime             : Sample(27),
      publicationDateTime         : Sample(27),
      instrumentIdCodeType        : Sample(4),
      instrumentIdCode            : Sample(12),
      tradedPrice                 : Sample(20),
      quantity                    : Sample(20),
      notionalAmount              : Sample(20),
      notionalCurrency            : Sample(3),
      reserved1                   : Sample(1),
      transactionIdCode           : Sample(52),
      mmtMarketMechanism          : Sample(1),
      mmtTradingMode              : Sample(1),
      mmtAlgorithmicIndicator     : Sample(4),
      mmtModificationIndicator    : Sample(4),
      mmtNegotiationIndicator     : Sample(4),
      mmtSpecialDividendIndicator : Sample(4),
      mmtContributionToPrice      : Sample(4),
      mmtBenchmarkIndicator       : Sample(4) ]

EncodeTradeFullInformationMessage(message) ==
    message.symbolIndex
        \o message.sourceTime
        \o message.tradeIdNumber
        \o message.venueOfExecution
        \o message.sourceSeqNum
        \o message.priceNotation
        \o message.transactionToBeCleared
        \o message.cumulativeQuantity
        \o message.highestPrice
        \o message.lowestPrice
        \o message.variationLastPrice
        \o message.systemId
        \o message.sourceTimeMicroSecs
        \o message.priceCurrency
        \o message.lastTradeIndicator
        \o message.typeOfTrade
        \o message.tradeOrigin
        \o message.tickDirection
        \o message.openingTradeIndicator
        \o message.variationScaleCode
        \o message.priceScaleCode
        \o message.tradingDateTime
        \o message.publicationDateTime
        \o message.instrumentIdCodeType
        \o message.instrumentIdCode
        \o message.tradedPrice
        \o message.quantity
        \o message.notionalAmount
        \o message.notionalCurrency
        \o message.reserved1
        \o message.transactionIdCode
        \o message.mmtMarketMechanism
        \o message.mmtTradingMode
        \o message.mmtAlgorithmicIndicator
        \o message.mmtModificationIndicator
        \o message.mmtNegotiationIndicator
        \o message.mmtSpecialDividendIndicator
        \o message.mmtContributionToPrice
        \o message.mmtBenchmarkIndicator

DecodeTradeFullInformationMessage(bytes) ==
    LET symbolIndex == ReadBytes(bytes, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET sourceTime == ReadBytes(symbolIndex.rest, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET tradeIdNumber == ReadBytes(sourceTime.rest, 4) IN IF ~tradeIdNumber.ok THEN Fail ELSE
    LET venueOfExecution == ReadBytes(tradeIdNumber.rest, 4) IN IF ~venueOfExecution.ok THEN Fail ELSE
    LET sourceSeqNum == ReadBytes(venueOfExecution.rest, 4) IN IF ~sourceSeqNum.ok THEN Fail ELSE
    LET priceNotation == ReadBytes(sourceSeqNum.rest, 4) IN IF ~priceNotation.ok THEN Fail ELSE
    LET transactionToBeCleared == ReadBytes(priceNotation.rest, 4) IN IF ~transactionToBeCleared.ok THEN Fail ELSE
    LET cumulativeQuantity == ReadBytes(transactionToBeCleared.rest, 4) IN IF ~cumulativeQuantity.ok THEN Fail ELSE
    LET highestPrice == ReadBytes(cumulativeQuantity.rest, 4) IN IF ~highestPrice.ok THEN Fail ELSE
    LET lowestPrice == ReadBytes(highestPrice.rest, 4) IN IF ~lowestPrice.ok THEN Fail ELSE
    LET variationLastPrice == ReadBytes(lowestPrice.rest, 4) IN IF ~variationLastPrice.ok THEN Fail ELSE
    LET systemId == ReadBytes(variationLastPrice.rest, 4) IN IF ~systemId.ok THEN Fail ELSE
    LET sourceTimeMicroSecs == ReadBytes(systemId.rest, 2) IN IF ~sourceTimeMicroSecs.ok THEN Fail ELSE
    LET priceCurrency == ReadBytes(sourceTimeMicroSecs.rest, 3) IN IF ~priceCurrency.ok THEN Fail ELSE
    LET lastTradeIndicator == ReadBytes(priceCurrency.rest, 1) IN IF ~lastTradeIndicator.ok THEN Fail ELSE
    LET typeOfTrade == ReadBytes(lastTradeIndicator.rest, 1) IN IF ~typeOfTrade.ok THEN Fail ELSE
    LET tradeOrigin == ReadBytes(typeOfTrade.rest, 1) IN IF ~tradeOrigin.ok THEN Fail ELSE
    LET tickDirection == ReadBytes(tradeOrigin.rest, 1) IN IF ~tickDirection.ok THEN Fail ELSE
    LET openingTradeIndicator == ReadBytes(tickDirection.rest, 1) IN IF ~openingTradeIndicator.ok THEN Fail ELSE
    LET variationScaleCode == ReadBytes(openingTradeIndicator.rest, 1) IN IF ~variationScaleCode.ok THEN Fail ELSE
    LET priceScaleCode == ReadBytes(variationScaleCode.rest, 1) IN IF ~priceScaleCode.ok THEN Fail ELSE
    LET tradingDateTime == ReadBytes(priceScaleCode.rest, 27) IN IF ~tradingDateTime.ok THEN Fail ELSE
    LET publicationDateTime == ReadBytes(tradingDateTime.rest, 27) IN IF ~publicationDateTime.ok THEN Fail ELSE
    LET instrumentIdCodeType == ReadBytes(publicationDateTime.rest, 4) IN IF ~instrumentIdCodeType.ok THEN Fail ELSE
    LET instrumentIdCode == ReadBytes(instrumentIdCodeType.rest, 12) IN IF ~instrumentIdCode.ok THEN Fail ELSE
    LET tradedPrice == ReadBytes(instrumentIdCode.rest, 20) IN IF ~tradedPrice.ok THEN Fail ELSE
    LET quantity == ReadBytes(tradedPrice.rest, 20) IN IF ~quantity.ok THEN Fail ELSE
    LET notionalAmount == ReadBytes(quantity.rest, 20) IN IF ~notionalAmount.ok THEN Fail ELSE
    LET notionalCurrency == ReadBytes(notionalAmount.rest, 3) IN IF ~notionalCurrency.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(notionalCurrency.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET transactionIdCode == ReadBytes(reserved1.rest, 52) IN IF ~transactionIdCode.ok THEN Fail ELSE
    LET mmtMarketMechanism == ReadBytes(transactionIdCode.rest, 1) IN IF ~mmtMarketMechanism.ok THEN Fail ELSE
    LET mmtTradingMode == ReadBytes(mmtMarketMechanism.rest, 1) IN IF ~mmtTradingMode.ok THEN Fail ELSE
    LET mmtAlgorithmicIndicator == ReadBytes(mmtTradingMode.rest, 4) IN IF ~mmtAlgorithmicIndicator.ok THEN Fail ELSE
    LET mmtModificationIndicator == ReadBytes(mmtAlgorithmicIndicator.rest, 4) IN IF ~mmtModificationIndicator.ok THEN Fail ELSE
    LET mmtNegotiationIndicator == ReadBytes(mmtModificationIndicator.rest, 4) IN IF ~mmtNegotiationIndicator.ok THEN Fail ELSE
    LET mmtSpecialDividendIndicator == ReadBytes(mmtNegotiationIndicator.rest, 4) IN IF ~mmtSpecialDividendIndicator.ok THEN Fail ELSE
    LET mmtContributionToPrice == ReadBytes(mmtSpecialDividendIndicator.rest, 4) IN IF ~mmtContributionToPrice.ok THEN Fail ELSE
    LET mmtBenchmarkIndicator == ReadBytes(mmtContributionToPrice.rest, 4) IN IF ~mmtBenchmarkIndicator.ok THEN Fail ELSE
    Ok([ symbolIndex                 |-> symbolIndex.value,
         sourceTime                  |-> sourceTime.value,
         tradeIdNumber               |-> tradeIdNumber.value,
         venueOfExecution            |-> venueOfExecution.value,
         sourceSeqNum                |-> sourceSeqNum.value,
         priceNotation               |-> priceNotation.value,
         transactionToBeCleared      |-> transactionToBeCleared.value,
         cumulativeQuantity          |-> cumulativeQuantity.value,
         highestPrice                |-> highestPrice.value,
         lowestPrice                 |-> lowestPrice.value,
         variationLastPrice          |-> variationLastPrice.value,
         systemId                    |-> systemId.value,
         sourceTimeMicroSecs         |-> sourceTimeMicroSecs.value,
         priceCurrency               |-> priceCurrency.value,
         lastTradeIndicator          |-> lastTradeIndicator.value,
         typeOfTrade                 |-> typeOfTrade.value,
         tradeOrigin                 |-> tradeOrigin.value,
         tickDirection               |-> tickDirection.value,
         openingTradeIndicator       |-> openingTradeIndicator.value,
         variationScaleCode          |-> variationScaleCode.value,
         priceScaleCode              |-> priceScaleCode.value,
         tradingDateTime             |-> tradingDateTime.value,
         publicationDateTime         |-> publicationDateTime.value,
         instrumentIdCodeType        |-> instrumentIdCodeType.value,
         instrumentIdCode            |-> instrumentIdCode.value,
         tradedPrice                 |-> tradedPrice.value,
         quantity                    |-> quantity.value,
         notionalAmount              |-> notionalAmount.value,
         notionalCurrency            |-> notionalCurrency.value,
         reserved1                   |-> reserved1.value,
         transactionIdCode           |-> transactionIdCode.value,
         mmtMarketMechanism          |-> mmtMarketMechanism.value,
         mmtTradingMode              |-> mmtTradingMode.value,
         mmtAlgorithmicIndicator     |-> mmtAlgorithmicIndicator.value,
         mmtModificationIndicator    |-> mmtModificationIndicator.value,
         mmtNegotiationIndicator     |-> mmtNegotiationIndicator.value,
         mmtSpecialDividendIndicator |-> mmtSpecialDividendIndicator.value,
         mmtContributionToPrice      |-> mmtContributionToPrice.value,
         mmtBenchmarkIndicator       |-> mmtBenchmarkIndicator.value ], mmtBenchmarkIndicator.rest)

ZeroTradeFullInformationMessage ==
    [ symbolIndex                 |-> [i \in 1 .. 4 |-> 0],
      sourceTime                  |-> [i \in 1 .. 4 |-> 0],
      tradeIdNumber               |-> [i \in 1 .. 4 |-> 0],
      venueOfExecution            |-> [i \in 1 .. 4 |-> 0],
      sourceSeqNum                |-> [i \in 1 .. 4 |-> 0],
      priceNotation               |-> [i \in 1 .. 4 |-> 0],
      transactionToBeCleared      |-> [i \in 1 .. 4 |-> 0],
      cumulativeQuantity          |-> [i \in 1 .. 4 |-> 0],
      highestPrice                |-> [i \in 1 .. 4 |-> 0],
      lowestPrice                 |-> [i \in 1 .. 4 |-> 0],
      variationLastPrice          |-> [i \in 1 .. 4 |-> 0],
      systemId                    |-> [i \in 1 .. 4 |-> 0],
      sourceTimeMicroSecs         |-> [i \in 1 .. 2 |-> 0],
      priceCurrency               |-> [i \in 1 .. 3 |-> 0],
      lastTradeIndicator          |-> [i \in 1 .. 1 |-> 0],
      typeOfTrade                 |-> [i \in 1 .. 1 |-> 0],
      tradeOrigin                 |-> [i \in 1 .. 1 |-> 0],
      tickDirection               |-> [i \in 1 .. 1 |-> 0],
      openingTradeIndicator       |-> [i \in 1 .. 1 |-> 0],
      variationScaleCode          |-> [i \in 1 .. 1 |-> 0],
      priceScaleCode              |-> [i \in 1 .. 1 |-> 0],
      tradingDateTime             |-> [i \in 1 .. 27 |-> 0],
      publicationDateTime         |-> [i \in 1 .. 27 |-> 0],
      instrumentIdCodeType        |-> [i \in 1 .. 4 |-> 0],
      instrumentIdCode            |-> [i \in 1 .. 12 |-> 0],
      tradedPrice                 |-> [i \in 1 .. 20 |-> 0],
      quantity                    |-> [i \in 1 .. 20 |-> 0],
      notionalAmount              |-> [i \in 1 .. 20 |-> 0],
      notionalCurrency            |-> [i \in 1 .. 3 |-> 0],
      reserved1                   |-> [i \in 1 .. 1 |-> 0],
      transactionIdCode           |-> [i \in 1 .. 52 |-> 0],
      mmtMarketMechanism          |-> [i \in 1 .. 1 |-> 0],
      mmtTradingMode              |-> [i \in 1 .. 1 |-> 0],
      mmtAlgorithmicIndicator     |-> [i \in 1 .. 4 |-> 0],
      mmtModificationIndicator    |-> [i \in 1 .. 4 |-> 0],
      mmtNegotiationIndicator     |-> [i \in 1 .. 4 |-> 0],
      mmtSpecialDividendIndicator |-> [i \in 1 .. 4 |-> 0],
      mmtContributionToPrice      |-> [i \in 1 .. 4 |-> 0],
      mmtBenchmarkIndicator       |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Full Information Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeFullInformationMessage ==
    { ZeroTradeFullInformationMessage }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.tradeIdNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.venueOfExecution = one] : one \in Sample(4) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.sourceSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.priceNotation = one] : one \in Sample(4) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.transactionToBeCleared = one] : one \in Sample(4) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.cumulativeQuantity = one] : one \in Sample(4) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.highestPrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.lowestPrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.variationLastPrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.systemId = one] : one \in Sample(4) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.sourceTimeMicroSecs = one] : one \in Sample(2) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.priceCurrency = one] : one \in Sample(3) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.lastTradeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.typeOfTrade = one] : one \in Sample(1) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.tradeOrigin = one] : one \in Sample(1) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.tickDirection = one] : one \in Sample(1) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.openingTradeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.variationScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.priceScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.tradingDateTime = one] : one \in Sample(27) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.publicationDateTime = one] : one \in Sample(27) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.instrumentIdCodeType = one] : one \in Sample(4) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.instrumentIdCode = one] : one \in Sample(12) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.tradedPrice = one] : one \in Sample(20) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.quantity = one] : one \in Sample(20) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.notionalAmount = one] : one \in Sample(20) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.notionalCurrency = one] : one \in Sample(3) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.transactionIdCode = one] : one \in Sample(52) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.mmtMarketMechanism = one] : one \in Sample(1) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.mmtTradingMode = one] : one \in Sample(1) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.mmtAlgorithmicIndicator = one] : one \in Sample(4) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.mmtModificationIndicator = one] : one \in Sample(4) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.mmtNegotiationIndicator = one] : one \in Sample(4) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.mmtSpecialDividendIndicator = one] : one \in Sample(4) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.mmtContributionToPrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.mmtBenchmarkIndicator = one] : one \in Sample(4) }

(***************************************************************************)
(* Price Update Message: 40 bytes                                          *)
(***************************************************************************)

PriceUpdateMessage ==
    [ symbolIndex         : Sample(4),
      sourceTime          : Sample(4),
      sourceSeqNum        : Sample(4),
      price               : Sample(4),
      highestPrice        : Sample(4),
      lowestPrice         : Sample(4),
      variationLastPrice  : Sample(4),
      systemId            : Sample(4),
      sourceTimeMicroSecs : Sample(2),
      typeOfPrice         : Sample(2),
      reserved2           : Sample(2),
      priceScaleCode      : Sample(1),
      variationScaleCode  : Sample(1) ]

EncodePriceUpdateMessage(message) ==
    message.symbolIndex
        \o message.sourceTime
        \o message.sourceSeqNum
        \o message.price
        \o message.highestPrice
        \o message.lowestPrice
        \o message.variationLastPrice
        \o message.systemId
        \o message.sourceTimeMicroSecs
        \o message.typeOfPrice
        \o message.reserved2
        \o message.priceScaleCode
        \o message.variationScaleCode

DecodePriceUpdateMessage(bytes) ==
    LET symbolIndex == ReadBytes(bytes, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET sourceTime == ReadBytes(symbolIndex.rest, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceSeqNum == ReadBytes(sourceTime.rest, 4) IN IF ~sourceSeqNum.ok THEN Fail ELSE
    LET price == ReadBytes(sourceSeqNum.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET highestPrice == ReadBytes(price.rest, 4) IN IF ~highestPrice.ok THEN Fail ELSE
    LET lowestPrice == ReadBytes(highestPrice.rest, 4) IN IF ~lowestPrice.ok THEN Fail ELSE
    LET variationLastPrice == ReadBytes(lowestPrice.rest, 4) IN IF ~variationLastPrice.ok THEN Fail ELSE
    LET systemId == ReadBytes(variationLastPrice.rest, 4) IN IF ~systemId.ok THEN Fail ELSE
    LET sourceTimeMicroSecs == ReadBytes(systemId.rest, 2) IN IF ~sourceTimeMicroSecs.ok THEN Fail ELSE
    LET typeOfPrice == ReadBytes(sourceTimeMicroSecs.rest, 2) IN IF ~typeOfPrice.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(typeOfPrice.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET priceScaleCode == ReadBytes(reserved2.rest, 1) IN IF ~priceScaleCode.ok THEN Fail ELSE
    LET variationScaleCode == ReadBytes(priceScaleCode.rest, 1) IN IF ~variationScaleCode.ok THEN Fail ELSE
    Ok([ symbolIndex         |-> symbolIndex.value,
         sourceTime          |-> sourceTime.value,
         sourceSeqNum        |-> sourceSeqNum.value,
         price               |-> price.value,
         highestPrice        |-> highestPrice.value,
         lowestPrice         |-> lowestPrice.value,
         variationLastPrice  |-> variationLastPrice.value,
         systemId            |-> systemId.value,
         sourceTimeMicroSecs |-> sourceTimeMicroSecs.value,
         typeOfPrice         |-> typeOfPrice.value,
         reserved2           |-> reserved2.value,
         priceScaleCode      |-> priceScaleCode.value,
         variationScaleCode  |-> variationScaleCode.value ], variationScaleCode.rest)

ZeroPriceUpdateMessage ==
    [ symbolIndex         |-> [i \in 1 .. 4 |-> 0],
      sourceTime          |-> [i \in 1 .. 4 |-> 0],
      sourceSeqNum        |-> [i \in 1 .. 4 |-> 0],
      price               |-> [i \in 1 .. 4 |-> 0],
      highestPrice        |-> [i \in 1 .. 4 |-> 0],
      lowestPrice         |-> [i \in 1 .. 4 |-> 0],
      variationLastPrice  |-> [i \in 1 .. 4 |-> 0],
      systemId            |-> [i \in 1 .. 4 |-> 0],
      sourceTimeMicroSecs |-> [i \in 1 .. 2 |-> 0],
      typeOfPrice         |-> [i \in 1 .. 2 |-> 0],
      reserved2           |-> [i \in 1 .. 2 |-> 0],
      priceScaleCode      |-> [i \in 1 .. 1 |-> 0],
      variationScaleCode  |-> [i \in 1 .. 1 |-> 0] ]

(* Price Update Message at zero, then each field in turn at the values it is checked at *)
CheckedPriceUpdateMessage ==
    { ZeroPriceUpdateMessage }
        \cup { [ZeroPriceUpdateMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroPriceUpdateMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroPriceUpdateMessage EXCEPT !.sourceSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroPriceUpdateMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroPriceUpdateMessage EXCEPT !.highestPrice = one] : one \in Sample(4) }
        \cup { [ZeroPriceUpdateMessage EXCEPT !.lowestPrice = one] : one \in Sample(4) }
        \cup { [ZeroPriceUpdateMessage EXCEPT !.variationLastPrice = one] : one \in Sample(4) }
        \cup { [ZeroPriceUpdateMessage EXCEPT !.systemId = one] : one \in Sample(4) }
        \cup { [ZeroPriceUpdateMessage EXCEPT !.sourceTimeMicroSecs = one] : one \in Sample(2) }
        \cup { [ZeroPriceUpdateMessage EXCEPT !.typeOfPrice = one] : one \in Sample(2) }
        \cup { [ZeroPriceUpdateMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroPriceUpdateMessage EXCEPT !.priceScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroPriceUpdateMessage EXCEPT !.variationScaleCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

TradeFullInformationMessageCode == 240  \* 0xf0
PriceUpdateMessageCode == 241  \* 0xf1

Payload ==
    [ tag : {TradeFullInformationMessageCode}, body : TradeFullInformationMessage ]
        \cup [ tag : {PriceUpdateMessageCode}, body : PriceUpdateMessage ]

EncodePayload(message) ==
    CASE message.tag = TradeFullInformationMessageCode -> EncodeTradeFullInformationMessage(message.body)
      [] message.tag = PriceUpdateMessageCode -> EncodePriceUpdateMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = TradeFullInformationMessageCode -> DecodeTradeFullInformationMessage(bytes)
              [] tag = PriceUpdateMessageCode -> DecodePriceUpdateMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> TradeFullInformationMessageCode, body |-> ZeroTradeFullInformationMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> TradeFullInformationMessageCode, body |-> one] : one \in CheckedTradeFullInformationMessage }
        \cup { [tag |-> PriceUpdateMessageCode, body |-> one] : one \in CheckedPriceUpdateMessage }

(***************************************************************************)
(* Message, framed by Message Size                                         *)
(***************************************************************************)

Message ==
    [ payload : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntBE(message.payload.tag, 2)
        \o EncodePayload(message.payload)

(* Message Size counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntBE(bytes, 2) IN IF ~messageType.ok THEN Fail ELSE
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> TradeFullInformationMessageCode, body |-> ZeroTradeFullInformationMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> PriceUpdateMessageCode, body |-> ZeroPriceUpdateMessage]] }

(***************************************************************************)
(* Message Buffer, selected by Delivery Flag                               *)
(***************************************************************************)

MessageBufferZlibCode == 16  \* 0x10
MessageBufferPlainCode == 0  \* 0x00

MessageBufferBody ==
    [ tag : 16 .. 255, body : MessageBufferZlib ]
        \cup { [tag |-> tag, body |-> one] : tag \in {0, 15}, one \in SampleLists(OneMessage) }

EncodeMessageBufferBody(message) ==
    CASE message.tag \in 16 .. 255 -> EncodeMessageBufferZlib(message.body)
      [] message.tag \in 0 .. 15 -> EncodeMessageList(message.body)

(* How many Message a Message Buffer holds, which is what Number Msg Entries states. *)
(* A case that is no run of them says nothing about the number, so it holds whatever was stated. *)
CountMessageBufferBody(choice, stated) ==
    CASE choice.tag \in 16 .. 255 -> stated
      [] choice.tag \in 0 .. 15 -> Len(choice.body)

DecodeMessageBufferBody(tag, count, bytes) ==
    LET read ==
            CASE tag \in 16 .. 255 -> DecodeMessageBufferZlib(bytes)
              [] tag \in 0 .. 15 -> ReadMessageList(bytes, count)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroMessageBufferBody == [tag |-> MessageBufferZlibCode, body |-> ZeroMessageBufferZlib]

(* Each Message Buffer in turn, at the values the message it names is checked at *)
CheckedMessageBufferBody ==
    { [tag |-> tag, body |-> one] : tag \in {16, 255}, one \in CheckedMessageBufferZlib }
        \cup { [tag |-> tag, body |-> one] : tag \in {0, 15}, one \in SampleLists(OneMessage) }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ packetLength         : Sample(2),
      packetType           : Sample(2),
      packetSequenceNumber : Sample(4),
      sendTime             : Sample(4),
      serviceId            : Sample(2),
      numberMsgEntries     : 0 .. 255,
      messageBuffer        : MessageBufferBody ]

EncodePacket(message) ==
    message.packetLength
        \o message.packetType
        \o message.packetSequenceNumber
        \o message.sendTime
        \o message.serviceId
        \o EncodeUIntBE(message.messageBuffer.tag, 1)
        \o EncodeUIntBE(message.numberMsgEntries, 1)
        \o EncodeMessageBufferBody(message.messageBuffer)

DecodePacket(bytes) ==
    LET packetLength == ReadBytes(bytes, 2) IN IF ~packetLength.ok THEN Fail ELSE
    LET packetType == ReadBytes(packetLength.rest, 2) IN IF ~packetType.ok THEN Fail ELSE
    LET packetSequenceNumber == ReadBytes(packetType.rest, 4) IN IF ~packetSequenceNumber.ok THEN Fail ELSE
    LET sendTime == ReadBytes(packetSequenceNumber.rest, 4) IN IF ~sendTime.ok THEN Fail ELSE
    LET serviceId == ReadBytes(sendTime.rest, 2) IN IF ~serviceId.ok THEN Fail ELSE
    LET deliveryFlag == ReadUIntBE(serviceId.rest, 1) IN IF ~deliveryFlag.ok THEN Fail ELSE
    LET numberMsgEntries == ReadUIntBE(deliveryFlag.rest, 1) IN IF ~numberMsgEntries.ok THEN Fail ELSE
    LET messageBuffer == DecodeMessageBufferBody(deliveryFlag.value, numberMsgEntries.value, numberMsgEntries.rest) IN IF ~messageBuffer.ok THEN Fail ELSE
    Ok([ packetLength         |-> packetLength.value,
         packetType           |-> packetType.value,
         packetSequenceNumber |-> packetSequenceNumber.value,
         sendTime             |-> sendTime.value,
         serviceId            |-> serviceId.value,
         numberMsgEntries     |-> numberMsgEntries.value,
         messageBuffer        |-> messageBuffer.value ], messageBuffer.rest)

ZeroPacket ==
    [ packetLength         |-> [i \in 1 .. 2 |-> 0],
      packetType           |-> [i \in 1 .. 2 |-> 0],
      packetSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      sendTime             |-> [i \in 1 .. 4 |-> 0],
      serviceId            |-> [i \in 1 .. 2 |-> 0],
      numberMsgEntries     |-> 0,
      messageBuffer        |-> ZeroMessageBufferBody ]

(* Packet at zero, then each field in turn at the values it is checked at *)
(* Number Msg Entries is varied with the Message Buffer it counts, which is read as many as it says *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.packetLength = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.packetType = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.packetSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.sendTime = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.serviceId = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.numberMsgEntries = one] : one \in {0, 1, 255} }
        \cup { [ZeroPacket EXCEPT !.numberMsgEntries = CountMessageBufferBody(one, 0), !.messageBuffer = one] : one \in CheckedMessageBufferBody }

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

(* Every Message Buffer decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageBufferZlib ==
    \A message \in CheckedMessageBufferZlib :
        LET read == DecodeMessageBufferZlib(EncodeMessageBufferZlib(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Full Information Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeFullInformationMessage ==
    \A message \in CheckedTradeFullInformationMessage :
        LET read == DecodeTradeFullInformationMessage(EncodeTradeFullInformationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPriceUpdateMessage ==
    \A message \in CheckedPriceUpdateMessage :
        LET read == DecodePriceUpdateMessage(EncodePriceUpdateMessage(message))
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

(* A Message Buffer is selected by the Delivery Flag it is written under *)
SelectsMessageBufferBody ==
    \A message \in CheckedMessageBufferBody :
        LET sent == EncodeMessageBufferBody(message)
            read == DecodeMessageBufferBody(message.tag, CountMessageBufferBody(message, 0), sent)
        IN  read.ok /\ read.value.tag = message.tag

(* Message Size is written from the bytes it frames *)
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
