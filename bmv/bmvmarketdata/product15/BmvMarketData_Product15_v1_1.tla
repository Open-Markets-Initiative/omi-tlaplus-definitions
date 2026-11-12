------------------- MODULE BmvMarketData_Product15_v1_1 --------------------
(***************************************************************************)
(* Bolsa Mexicana de Valores Bmv Market Data Product 15 v1.1               *)
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
(* Events System Message: 22 bytes                                         *)
(***************************************************************************)

EventsSystemMessage ==
    [ instrumentNumber : Sample(4),
      eventCode        : Sample(1),
      market           : Sample(1),
      sendingTime      : Sample(8),
      endingTime       : Sample(8) ]

EncodeEventsSystemMessage(message) ==
    message.instrumentNumber
        \o message.eventCode
        \o message.market
        \o message.sendingTime
        \o message.endingTime

DecodeEventsSystemMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET eventCode == ReadBytes(instrumentNumber.rest, 1) IN IF ~eventCode.ok THEN Fail ELSE
    LET market == ReadBytes(eventCode.rest, 1) IN IF ~market.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(market.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET endingTime == ReadBytes(sendingTime.rest, 8) IN IF ~endingTime.ok THEN Fail ELSE
    Ok([ instrumentNumber |-> instrumentNumber.value,
         eventCode        |-> eventCode.value,
         market           |-> market.value,
         sendingTime      |-> sendingTime.value,
         endingTime       |-> endingTime.value ], endingTime.rest)

ZeroEventsSystemMessage ==
    [ instrumentNumber |-> [i \in 1 .. 4 |-> 0],
      eventCode        |-> [i \in 1 .. 1 |-> 0],
      market           |-> [i \in 1 .. 1 |-> 0],
      sendingTime      |-> [i \in 1 .. 8 |-> 0],
      endingTime       |-> [i \in 1 .. 8 |-> 0] ]

(* Events System Message at zero, then each field in turn at the values it is checked at *)
CheckedEventsSystemMessage ==
    { ZeroEventsSystemMessage }
        \cup { [ZeroEventsSystemMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroEventsSystemMessage EXCEPT !.eventCode = one] : one \in Sample(1) }
        \cup { [ZeroEventsSystemMessage EXCEPT !.market = one] : one \in Sample(1) }
        \cup { [ZeroEventsSystemMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroEventsSystemMessage EXCEPT !.endingTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Cancellation Message: 8 bytes                                     *)
(***************************************************************************)

TradeCancellationMessage ==
    [ instrumentNumber : Sample(4),
      tradeNumber      : Sample(4) ]

EncodeTradeCancellationMessage(message) ==
    message.instrumentNumber
        \o message.tradeNumber

DecodeTradeCancellationMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(instrumentNumber.rest, 4) IN IF ~tradeNumber.ok THEN Fail ELSE
    Ok([ instrumentNumber |-> instrumentNumber.value,
         tradeNumber      |-> tradeNumber.value ], tradeNumber.rest)

ZeroTradeCancellationMessage ==
    [ instrumentNumber |-> [i \in 1 .. 4 |-> 0],
      tradeNumber      |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Cancellation Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCancellationMessage ==
    { ZeroTradeCancellationMessage }
        \cup { [ZeroTradeCancellationMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancellationMessage EXCEPT !.tradeNumber = one] : one \in Sample(4) }

(***************************************************************************)
(* Status Changes Message: 5 bytes                                         *)
(***************************************************************************)

StatusChangesMessage ==
    [ instrumentNumber : Sample(4),
      instrumentStatus : Sample(1) ]

EncodeStatusChangesMessage(message) ==
    message.instrumentNumber
        \o message.instrumentStatus

DecodeStatusChangesMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET instrumentStatus == ReadBytes(instrumentNumber.rest, 1) IN IF ~instrumentStatus.ok THEN Fail ELSE
    Ok([ instrumentNumber |-> instrumentNumber.value,
         instrumentStatus |-> instrumentStatus.value ], instrumentStatus.rest)

ZeroStatusChangesMessage ==
    [ instrumentNumber |-> [i \in 1 .. 4 |-> 0],
      instrumentStatus |-> [i \in 1 .. 1 |-> 0] ]

(* Status Changes Message at zero, then each field in turn at the values it is checked at *)
CheckedStatusChangesMessage ==
    { ZeroStatusChangesMessage }
        \cup { [ZeroStatusChangesMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroStatusChangesMessage EXCEPT !.instrumentStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Weighted Average Price Settlement Prices Message: 20 bytes              *)
(***************************************************************************)

WeightedAveragePriceSettlementPricesMessage ==
    [ instrumentNumber     : Sample(4),
      weightedAveragePrice : Sample(8),
      volatility           : Sample(8) ]

EncodeWeightedAveragePriceSettlementPricesMessage(message) ==
    message.instrumentNumber
        \o message.weightedAveragePrice
        \o message.volatility

DecodeWeightedAveragePriceSettlementPricesMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET weightedAveragePrice == ReadBytes(instrumentNumber.rest, 8) IN IF ~weightedAveragePrice.ok THEN Fail ELSE
    LET volatility == ReadBytes(weightedAveragePrice.rest, 8) IN IF ~volatility.ok THEN Fail ELSE
    Ok([ instrumentNumber     |-> instrumentNumber.value,
         weightedAveragePrice |-> weightedAveragePrice.value,
         volatility           |-> volatility.value ], volatility.rest)

ZeroWeightedAveragePriceSettlementPricesMessage ==
    [ instrumentNumber     |-> [i \in 1 .. 4 |-> 0],
      weightedAveragePrice |-> [i \in 1 .. 8 |-> 0],
      volatility           |-> [i \in 1 .. 8 |-> 0] ]

(* Weighted Average Price Settlement Prices Message at zero, then each field in turn at the values it is checked at *)
CheckedWeightedAveragePriceSettlementPricesMessage ==
    { ZeroWeightedAveragePriceSettlementPricesMessage }
        \cup { [ZeroWeightedAveragePriceSettlementPricesMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroWeightedAveragePriceSettlementPricesMessage EXCEPT !.weightedAveragePrice = one] : one \in Sample(8) }
        \cup { [ZeroWeightedAveragePriceSettlementPricesMessage EXCEPT !.volatility = one] : one \in Sample(8) }

(***************************************************************************)
(* Capital Trades Message: 51 bytes                                        *)
(***************************************************************************)

CapitalTradesMessage ==
    [ instrumentNumber : Sample(4),
      tradeTime        : Sample(8),
      volumeInt324     : Sample(4),
      price            : Sample(8),
      concertationType : Sample(1),
      tradeNumber      : Sample(4),
      priceSetter      : Sample(1),
      operationType    : Sample(1),
      amount           : Sample(8),
      buy              : Sample(5),
      sell             : Sample(5),
      settlement       : Sample(1),
      auctionIndicator : Sample(1) ]

EncodeCapitalTradesMessage(message) ==
    message.instrumentNumber
        \o message.tradeTime
        \o message.volumeInt324
        \o message.price
        \o message.concertationType
        \o message.tradeNumber
        \o message.priceSetter
        \o message.operationType
        \o message.amount
        \o message.buy
        \o message.sell
        \o message.settlement
        \o message.auctionIndicator

DecodeCapitalTradesMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET tradeTime == ReadBytes(instrumentNumber.rest, 8) IN IF ~tradeTime.ok THEN Fail ELSE
    LET volumeInt324 == ReadBytes(tradeTime.rest, 4) IN IF ~volumeInt324.ok THEN Fail ELSE
    LET price == ReadBytes(volumeInt324.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET concertationType == ReadBytes(price.rest, 1) IN IF ~concertationType.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(concertationType.rest, 4) IN IF ~tradeNumber.ok THEN Fail ELSE
    LET priceSetter == ReadBytes(tradeNumber.rest, 1) IN IF ~priceSetter.ok THEN Fail ELSE
    LET operationType == ReadBytes(priceSetter.rest, 1) IN IF ~operationType.ok THEN Fail ELSE
    LET amount == ReadBytes(operationType.rest, 8) IN IF ~amount.ok THEN Fail ELSE
    LET buy == ReadBytes(amount.rest, 5) IN IF ~buy.ok THEN Fail ELSE
    LET sell == ReadBytes(buy.rest, 5) IN IF ~sell.ok THEN Fail ELSE
    LET settlement == ReadBytes(sell.rest, 1) IN IF ~settlement.ok THEN Fail ELSE
    LET auctionIndicator == ReadBytes(settlement.rest, 1) IN IF ~auctionIndicator.ok THEN Fail ELSE
    Ok([ instrumentNumber |-> instrumentNumber.value,
         tradeTime        |-> tradeTime.value,
         volumeInt324     |-> volumeInt324.value,
         price            |-> price.value,
         concertationType |-> concertationType.value,
         tradeNumber      |-> tradeNumber.value,
         priceSetter      |-> priceSetter.value,
         operationType    |-> operationType.value,
         amount           |-> amount.value,
         buy              |-> buy.value,
         sell             |-> sell.value,
         settlement       |-> settlement.value,
         auctionIndicator |-> auctionIndicator.value ], auctionIndicator.rest)

ZeroCapitalTradesMessage ==
    [ instrumentNumber |-> [i \in 1 .. 4 |-> 0],
      tradeTime        |-> [i \in 1 .. 8 |-> 0],
      volumeInt324     |-> [i \in 1 .. 4 |-> 0],
      price            |-> [i \in 1 .. 8 |-> 0],
      concertationType |-> [i \in 1 .. 1 |-> 0],
      tradeNumber      |-> [i \in 1 .. 4 |-> 0],
      priceSetter      |-> [i \in 1 .. 1 |-> 0],
      operationType    |-> [i \in 1 .. 1 |-> 0],
      amount           |-> [i \in 1 .. 8 |-> 0],
      buy              |-> [i \in 1 .. 5 |-> 0],
      sell             |-> [i \in 1 .. 5 |-> 0],
      settlement       |-> [i \in 1 .. 1 |-> 0],
      auctionIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Capital Trades Message at zero, then each field in turn at the values it is checked at *)
CheckedCapitalTradesMessage ==
    { ZeroCapitalTradesMessage }
        \cup { [ZeroCapitalTradesMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroCapitalTradesMessage EXCEPT !.tradeTime = one] : one \in Sample(8) }
        \cup { [ZeroCapitalTradesMessage EXCEPT !.volumeInt324 = one] : one \in Sample(4) }
        \cup { [ZeroCapitalTradesMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroCapitalTradesMessage EXCEPT !.concertationType = one] : one \in Sample(1) }
        \cup { [ZeroCapitalTradesMessage EXCEPT !.tradeNumber = one] : one \in Sample(4) }
        \cup { [ZeroCapitalTradesMessage EXCEPT !.priceSetter = one] : one \in Sample(1) }
        \cup { [ZeroCapitalTradesMessage EXCEPT !.operationType = one] : one \in Sample(1) }
        \cup { [ZeroCapitalTradesMessage EXCEPT !.amount = one] : one \in Sample(8) }
        \cup { [ZeroCapitalTradesMessage EXCEPT !.buy = one] : one \in Sample(5) }
        \cup { [ZeroCapitalTradesMessage EXCEPT !.sell = one] : one \in Sample(5) }
        \cup { [ZeroCapitalTradesMessage EXCEPT !.settlement = one] : one \in Sample(1) }
        \cup { [ZeroCapitalTradesMessage EXCEPT !.auctionIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Probable Allocation Price Message: 16 bytes                             *)
(***************************************************************************)

ProbableAllocationPriceMessage ==
    [ instrumentNumber        : Sample(4),
      probableAllocationPrice : Sample(8),
      volumeInt324            : Sample(4) ]

EncodeProbableAllocationPriceMessage(message) ==
    message.instrumentNumber
        \o message.probableAllocationPrice
        \o message.volumeInt324

DecodeProbableAllocationPriceMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET probableAllocationPrice == ReadBytes(instrumentNumber.rest, 8) IN IF ~probableAllocationPrice.ok THEN Fail ELSE
    LET volumeInt324 == ReadBytes(probableAllocationPrice.rest, 4) IN IF ~volumeInt324.ok THEN Fail ELSE
    Ok([ instrumentNumber        |-> instrumentNumber.value,
         probableAllocationPrice |-> probableAllocationPrice.value,
         volumeInt324            |-> volumeInt324.value ], volumeInt324.rest)

ZeroProbableAllocationPriceMessage ==
    [ instrumentNumber        |-> [i \in 1 .. 4 |-> 0],
      probableAllocationPrice |-> [i \in 1 .. 8 |-> 0],
      volumeInt324            |-> [i \in 1 .. 4 |-> 0] ]

(* Probable Allocation Price Message at zero, then each field in turn at the values it is checked at *)
CheckedProbableAllocationPriceMessage ==
    { ZeroProbableAllocationPriceMessage }
        \cup { [ZeroProbableAllocationPriceMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroProbableAllocationPriceMessage EXCEPT !.probableAllocationPrice = one] : one \in Sample(8) }
        \cup { [ZeroProbableAllocationPriceMessage EXCEPT !.volumeInt324 = one] : one \in Sample(4) }

(***************************************************************************)
(* Continuous Auctions Beginning Message: 20 bytes                         *)
(***************************************************************************)

ContinuousAuctionsBeginningMessage ==
    [ instrumentNumber       : Sample(4),
      beginningTimeOfAuction : Sample(8),
      endAuctionTime         : Sample(8) ]

EncodeContinuousAuctionsBeginningMessage(message) ==
    message.instrumentNumber
        \o message.beginningTimeOfAuction
        \o message.endAuctionTime

DecodeContinuousAuctionsBeginningMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET beginningTimeOfAuction == ReadBytes(instrumentNumber.rest, 8) IN IF ~beginningTimeOfAuction.ok THEN Fail ELSE
    LET endAuctionTime == ReadBytes(beginningTimeOfAuction.rest, 8) IN IF ~endAuctionTime.ok THEN Fail ELSE
    Ok([ instrumentNumber       |-> instrumentNumber.value,
         beginningTimeOfAuction |-> beginningTimeOfAuction.value,
         endAuctionTime         |-> endAuctionTime.value ], endAuctionTime.rest)

ZeroContinuousAuctionsBeginningMessage ==
    [ instrumentNumber       |-> [i \in 1 .. 4 |-> 0],
      beginningTimeOfAuction |-> [i \in 1 .. 8 |-> 0],
      endAuctionTime         |-> [i \in 1 .. 8 |-> 0] ]

(* Continuous Auctions Beginning Message at zero, then each field in turn at the values it is checked at *)
CheckedContinuousAuctionsBeginningMessage ==
    { ZeroContinuousAuctionsBeginningMessage }
        \cup { [ZeroContinuousAuctionsBeginningMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroContinuousAuctionsBeginningMessage EXCEPT !.beginningTimeOfAuction = one] : one \in Sample(8) }
        \cup { [ZeroContinuousAuctionsBeginningMessage EXCEPT !.endAuctionTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Middle Price Existing Quotes Message: 5 bytes                           *)
(***************************************************************************)

MiddlePriceExistingQuotesMessage ==
    [ instrumentNumber : Sample(4),
      existingPostures : Sample(1) ]

EncodeMiddlePriceExistingQuotesMessage(message) ==
    message.instrumentNumber
        \o message.existingPostures

DecodeMiddlePriceExistingQuotesMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET existingPostures == ReadBytes(instrumentNumber.rest, 1) IN IF ~existingPostures.ok THEN Fail ELSE
    Ok([ instrumentNumber |-> instrumentNumber.value,
         existingPostures |-> existingPostures.value ], existingPostures.rest)

ZeroMiddlePriceExistingQuotesMessage ==
    [ instrumentNumber |-> [i \in 1 .. 4 |-> 0],
      existingPostures |-> [i \in 1 .. 1 |-> 0] ]

(* Middle Price Existing Quotes Message at zero, then each field in turn at the values it is checked at *)
CheckedMiddlePriceExistingQuotesMessage ==
    { ZeroMiddlePriceExistingQuotesMessage }
        \cup { [ZeroMiddlePriceExistingQuotesMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroMiddlePriceExistingQuotesMessage EXCEPT !.existingPostures = one] : one \in Sample(1) }

(***************************************************************************)
(* Registry Operations Message: 61 bytes                                   *)
(***************************************************************************)

RegistryOperationsMessage ==
    [ instrumentNumber : Sample(4),
      offerType        : Sample(1),
      income           : Sample(1),
      valueType        : Sample(4),
      issuer           : Sample(7),
      series           : Sample(6),
      maximumVolume    : Sample(8),
      registeredVolume : Sample(8),
      priceRate        : Sample(8),
      settlementDate   : Sample(8),
      firm             : Sample(5),
      movement         : Sample(1) ]

EncodeRegistryOperationsMessage(message) ==
    message.instrumentNumber
        \o message.offerType
        \o message.income
        \o message.valueType
        \o message.issuer
        \o message.series
        \o message.maximumVolume
        \o message.registeredVolume
        \o message.priceRate
        \o message.settlementDate
        \o message.firm
        \o message.movement

DecodeRegistryOperationsMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET offerType == ReadBytes(instrumentNumber.rest, 1) IN IF ~offerType.ok THEN Fail ELSE
    LET income == ReadBytes(offerType.rest, 1) IN IF ~income.ok THEN Fail ELSE
    LET valueType == ReadBytes(income.rest, 4) IN IF ~valueType.ok THEN Fail ELSE
    LET issuer == ReadBytes(valueType.rest, 7) IN IF ~issuer.ok THEN Fail ELSE
    LET series == ReadBytes(issuer.rest, 6) IN IF ~series.ok THEN Fail ELSE
    LET maximumVolume == ReadBytes(series.rest, 8) IN IF ~maximumVolume.ok THEN Fail ELSE
    LET registeredVolume == ReadBytes(maximumVolume.rest, 8) IN IF ~registeredVolume.ok THEN Fail ELSE
    LET priceRate == ReadBytes(registeredVolume.rest, 8) IN IF ~priceRate.ok THEN Fail ELSE
    LET settlementDate == ReadBytes(priceRate.rest, 8) IN IF ~settlementDate.ok THEN Fail ELSE
    LET firm == ReadBytes(settlementDate.rest, 5) IN IF ~firm.ok THEN Fail ELSE
    LET movement == ReadBytes(firm.rest, 1) IN IF ~movement.ok THEN Fail ELSE
    Ok([ instrumentNumber |-> instrumentNumber.value,
         offerType        |-> offerType.value,
         income           |-> income.value,
         valueType        |-> valueType.value,
         issuer           |-> issuer.value,
         series           |-> series.value,
         maximumVolume    |-> maximumVolume.value,
         registeredVolume |-> registeredVolume.value,
         priceRate        |-> priceRate.value,
         settlementDate   |-> settlementDate.value,
         firm             |-> firm.value,
         movement         |-> movement.value ], movement.rest)

ZeroRegistryOperationsMessage ==
    [ instrumentNumber |-> [i \in 1 .. 4 |-> 0],
      offerType        |-> [i \in 1 .. 1 |-> 0],
      income           |-> [i \in 1 .. 1 |-> 0],
      valueType        |-> [i \in 1 .. 4 |-> 0],
      issuer           |-> [i \in 1 .. 7 |-> 0],
      series           |-> [i \in 1 .. 6 |-> 0],
      maximumVolume    |-> [i \in 1 .. 8 |-> 0],
      registeredVolume |-> [i \in 1 .. 8 |-> 0],
      priceRate        |-> [i \in 1 .. 8 |-> 0],
      settlementDate   |-> [i \in 1 .. 8 |-> 0],
      firm             |-> [i \in 1 .. 5 |-> 0],
      movement         |-> [i \in 1 .. 1 |-> 0] ]

(* Registry Operations Message at zero, then each field in turn at the values it is checked at *)
CheckedRegistryOperationsMessage ==
    { ZeroRegistryOperationsMessage }
        \cup { [ZeroRegistryOperationsMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroRegistryOperationsMessage EXCEPT !.offerType = one] : one \in Sample(1) }
        \cup { [ZeroRegistryOperationsMessage EXCEPT !.income = one] : one \in Sample(1) }
        \cup { [ZeroRegistryOperationsMessage EXCEPT !.valueType = one] : one \in Sample(4) }
        \cup { [ZeroRegistryOperationsMessage EXCEPT !.issuer = one] : one \in Sample(7) }
        \cup { [ZeroRegistryOperationsMessage EXCEPT !.series = one] : one \in Sample(6) }
        \cup { [ZeroRegistryOperationsMessage EXCEPT !.maximumVolume = one] : one \in Sample(8) }
        \cup { [ZeroRegistryOperationsMessage EXCEPT !.registeredVolume = one] : one \in Sample(8) }
        \cup { [ZeroRegistryOperationsMessage EXCEPT !.priceRate = one] : one \in Sample(8) }
        \cup { [ZeroRegistryOperationsMessage EXCEPT !.settlementDate = one] : one \in Sample(8) }
        \cup { [ZeroRegistryOperationsMessage EXCEPT !.firm = one] : one \in Sample(5) }
        \cup { [ZeroRegistryOperationsMessage EXCEPT !.movement = one] : one \in Sample(1) }

(***************************************************************************)
(* Mutual Fund Trades Message: 52 bytes                                    *)
(***************************************************************************)

MutualFundTradesMessage ==
    [ instrumentNumber          : Sample(4),
      tradeDate                 : Sample(8),
      price                     : Sample(8),
      bookValue                 : Sample(8),
      numberOfSalesTransactions : Sample(4),
      salesVolume               : Sample(8),
      numberOfBuyTransactions   : Sample(4),
      buyVolume                 : Sample(8) ]

EncodeMutualFundTradesMessage(message) ==
    message.instrumentNumber
        \o message.tradeDate
        \o message.price
        \o message.bookValue
        \o message.numberOfSalesTransactions
        \o message.salesVolume
        \o message.numberOfBuyTransactions
        \o message.buyVolume

DecodeMutualFundTradesMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(instrumentNumber.rest, 8) IN IF ~tradeDate.ok THEN Fail ELSE
    LET price == ReadBytes(tradeDate.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET bookValue == ReadBytes(price.rest, 8) IN IF ~bookValue.ok THEN Fail ELSE
    LET numberOfSalesTransactions == ReadBytes(bookValue.rest, 4) IN IF ~numberOfSalesTransactions.ok THEN Fail ELSE
    LET salesVolume == ReadBytes(numberOfSalesTransactions.rest, 8) IN IF ~salesVolume.ok THEN Fail ELSE
    LET numberOfBuyTransactions == ReadBytes(salesVolume.rest, 4) IN IF ~numberOfBuyTransactions.ok THEN Fail ELSE
    LET buyVolume == ReadBytes(numberOfBuyTransactions.rest, 8) IN IF ~buyVolume.ok THEN Fail ELSE
    Ok([ instrumentNumber          |-> instrumentNumber.value,
         tradeDate                 |-> tradeDate.value,
         price                     |-> price.value,
         bookValue                 |-> bookValue.value,
         numberOfSalesTransactions |-> numberOfSalesTransactions.value,
         salesVolume               |-> salesVolume.value,
         numberOfBuyTransactions   |-> numberOfBuyTransactions.value,
         buyVolume                 |-> buyVolume.value ], buyVolume.rest)

ZeroMutualFundTradesMessage ==
    [ instrumentNumber          |-> [i \in 1 .. 4 |-> 0],
      tradeDate                 |-> [i \in 1 .. 8 |-> 0],
      price                     |-> [i \in 1 .. 8 |-> 0],
      bookValue                 |-> [i \in 1 .. 8 |-> 0],
      numberOfSalesTransactions |-> [i \in 1 .. 4 |-> 0],
      salesVolume               |-> [i \in 1 .. 8 |-> 0],
      numberOfBuyTransactions   |-> [i \in 1 .. 4 |-> 0],
      buyVolume                 |-> [i \in 1 .. 8 |-> 0] ]

(* Mutual Fund Trades Message at zero, then each field in turn at the values it is checked at *)
CheckedMutualFundTradesMessage ==
    { ZeroMutualFundTradesMessage }
        \cup { [ZeroMutualFundTradesMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroMutualFundTradesMessage EXCEPT !.tradeDate = one] : one \in Sample(8) }
        \cup { [ZeroMutualFundTradesMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroMutualFundTradesMessage EXCEPT !.bookValue = one] : one \in Sample(8) }
        \cup { [ZeroMutualFundTradesMessage EXCEPT !.numberOfSalesTransactions = one] : one \in Sample(4) }
        \cup { [ZeroMutualFundTradesMessage EXCEPT !.salesVolume = one] : one \in Sample(8) }
        \cup { [ZeroMutualFundTradesMessage EXCEPT !.numberOfBuyTransactions = one] : one \in Sample(4) }
        \cup { [ZeroMutualFundTradesMessage EXCEPT !.buyVolume = one] : one \in Sample(8) }

(***************************************************************************)
(* Tradability Message: 64 bytes                                           *)
(***************************************************************************)

TradabilityMessage ==
    [ instrumentNumber   : Sample(4),
      numberOfOperations : Sample(4),
      volumeInt648       : Sample(8),
      amount             : Sample(8),
      openingPrice       : Sample(8),
      maximum            : Sample(8),
      minimum            : Sample(8),
      average            : Sample(8),
      last               : Sample(8) ]

EncodeTradabilityMessage(message) ==
    message.instrumentNumber
        \o message.numberOfOperations
        \o message.volumeInt648
        \o message.amount
        \o message.openingPrice
        \o message.maximum
        \o message.minimum
        \o message.average
        \o message.last

DecodeTradabilityMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET numberOfOperations == ReadBytes(instrumentNumber.rest, 4) IN IF ~numberOfOperations.ok THEN Fail ELSE
    LET volumeInt648 == ReadBytes(numberOfOperations.rest, 8) IN IF ~volumeInt648.ok THEN Fail ELSE
    LET amount == ReadBytes(volumeInt648.rest, 8) IN IF ~amount.ok THEN Fail ELSE
    LET openingPrice == ReadBytes(amount.rest, 8) IN IF ~openingPrice.ok THEN Fail ELSE
    LET maximum == ReadBytes(openingPrice.rest, 8) IN IF ~maximum.ok THEN Fail ELSE
    LET minimum == ReadBytes(maximum.rest, 8) IN IF ~minimum.ok THEN Fail ELSE
    LET average == ReadBytes(minimum.rest, 8) IN IF ~average.ok THEN Fail ELSE
    LET last == ReadBytes(average.rest, 8) IN IF ~last.ok THEN Fail ELSE
    Ok([ instrumentNumber   |-> instrumentNumber.value,
         numberOfOperations |-> numberOfOperations.value,
         volumeInt648       |-> volumeInt648.value,
         amount             |-> amount.value,
         openingPrice       |-> openingPrice.value,
         maximum            |-> maximum.value,
         minimum            |-> minimum.value,
         average            |-> average.value,
         last               |-> last.value ], last.rest)

ZeroTradabilityMessage ==
    [ instrumentNumber   |-> [i \in 1 .. 4 |-> 0],
      numberOfOperations |-> [i \in 1 .. 4 |-> 0],
      volumeInt648       |-> [i \in 1 .. 8 |-> 0],
      amount             |-> [i \in 1 .. 8 |-> 0],
      openingPrice       |-> [i \in 1 .. 8 |-> 0],
      maximum            |-> [i \in 1 .. 8 |-> 0],
      minimum            |-> [i \in 1 .. 8 |-> 0],
      average            |-> [i \in 1 .. 8 |-> 0],
      last               |-> [i \in 1 .. 8 |-> 0] ]

(* Tradability Message at zero, then each field in turn at the values it is checked at *)
CheckedTradabilityMessage ==
    { ZeroTradabilityMessage }
        \cup { [ZeroTradabilityMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradabilityMessage EXCEPT !.numberOfOperations = one] : one \in Sample(4) }
        \cup { [ZeroTradabilityMessage EXCEPT !.volumeInt648 = one] : one \in Sample(8) }
        \cup { [ZeroTradabilityMessage EXCEPT !.amount = one] : one \in Sample(8) }
        \cup { [ZeroTradabilityMessage EXCEPT !.openingPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradabilityMessage EXCEPT !.maximum = one] : one \in Sample(8) }
        \cup { [ZeroTradabilityMessage EXCEPT !.minimum = one] : one \in Sample(8) }
        \cup { [ZeroTradabilityMessage EXCEPT !.average = one] : one \in Sample(8) }
        \cup { [ZeroTradabilityMessage EXCEPT !.last = one] : one \in Sample(8) }

(***************************************************************************)
(* Virtual Trades Message: 25 bytes                                        *)
(***************************************************************************)

VirtualTradesMessage ==
    [ instrumentNumber    : Sample(4),
      virtualTradesStatus : Sample(1),
      operationType       : Sample(1),
      number              : Sample(4),
      volumeInt324        : Sample(4),
      concertation        : Sample(1),
      buy                 : Sample(5),
      sell                : Sample(5) ]

EncodeVirtualTradesMessage(message) ==
    message.instrumentNumber
        \o message.virtualTradesStatus
        \o message.operationType
        \o message.number
        \o message.volumeInt324
        \o message.concertation
        \o message.buy
        \o message.sell

DecodeVirtualTradesMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET virtualTradesStatus == ReadBytes(instrumentNumber.rest, 1) IN IF ~virtualTradesStatus.ok THEN Fail ELSE
    LET operationType == ReadBytes(virtualTradesStatus.rest, 1) IN IF ~operationType.ok THEN Fail ELSE
    LET number == ReadBytes(operationType.rest, 4) IN IF ~number.ok THEN Fail ELSE
    LET volumeInt324 == ReadBytes(number.rest, 4) IN IF ~volumeInt324.ok THEN Fail ELSE
    LET concertation == ReadBytes(volumeInt324.rest, 1) IN IF ~concertation.ok THEN Fail ELSE
    LET buy == ReadBytes(concertation.rest, 5) IN IF ~buy.ok THEN Fail ELSE
    LET sell == ReadBytes(buy.rest, 5) IN IF ~sell.ok THEN Fail ELSE
    Ok([ instrumentNumber    |-> instrumentNumber.value,
         virtualTradesStatus |-> virtualTradesStatus.value,
         operationType       |-> operationType.value,
         number              |-> number.value,
         volumeInt324        |-> volumeInt324.value,
         concertation        |-> concertation.value,
         buy                 |-> buy.value,
         sell                |-> sell.value ], sell.rest)

ZeroVirtualTradesMessage ==
    [ instrumentNumber    |-> [i \in 1 .. 4 |-> 0],
      virtualTradesStatus |-> [i \in 1 .. 1 |-> 0],
      operationType       |-> [i \in 1 .. 1 |-> 0],
      number              |-> [i \in 1 .. 4 |-> 0],
      volumeInt324        |-> [i \in 1 .. 4 |-> 0],
      concertation        |-> [i \in 1 .. 1 |-> 0],
      buy                 |-> [i \in 1 .. 5 |-> 0],
      sell                |-> [i \in 1 .. 5 |-> 0] ]

(* Virtual Trades Message at zero, then each field in turn at the values it is checked at *)
CheckedVirtualTradesMessage ==
    { ZeroVirtualTradesMessage }
        \cup { [ZeroVirtualTradesMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroVirtualTradesMessage EXCEPT !.virtualTradesStatus = one] : one \in Sample(1) }
        \cup { [ZeroVirtualTradesMessage EXCEPT !.operationType = one] : one \in Sample(1) }
        \cup { [ZeroVirtualTradesMessage EXCEPT !.number = one] : one \in Sample(4) }
        \cup { [ZeroVirtualTradesMessage EXCEPT !.volumeInt324 = one] : one \in Sample(4) }
        \cup { [ZeroVirtualTradesMessage EXCEPT !.concertation = one] : one \in Sample(1) }
        \cup { [ZeroVirtualTradesMessage EXCEPT !.buy = one] : one \in Sample(5) }
        \cup { [ZeroVirtualTradesMessage EXCEPT !.sell = one] : one \in Sample(5) }

(***************************************************************************)
(* Order Addition Message: 34 bytes                                        *)
(***************************************************************************)

OrderAdditionMessage ==
    [ instrumentNumber : Sample(4),
      dateAndTime      : Sample(8),
      number           : Sample(4),
      direction        : Sample(1),
      volumeInt324     : Sample(4),
      price            : Sample(8),
      participant      : Sample(5) ]

EncodeOrderAdditionMessage(message) ==
    message.instrumentNumber
        \o message.dateAndTime
        \o message.number
        \o message.direction
        \o message.volumeInt324
        \o message.price
        \o message.participant

DecodeOrderAdditionMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET dateAndTime == ReadBytes(instrumentNumber.rest, 8) IN IF ~dateAndTime.ok THEN Fail ELSE
    LET number == ReadBytes(dateAndTime.rest, 4) IN IF ~number.ok THEN Fail ELSE
    LET direction == ReadBytes(number.rest, 1) IN IF ~direction.ok THEN Fail ELSE
    LET volumeInt324 == ReadBytes(direction.rest, 4) IN IF ~volumeInt324.ok THEN Fail ELSE
    LET price == ReadBytes(volumeInt324.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET participant == ReadBytes(price.rest, 5) IN IF ~participant.ok THEN Fail ELSE
    Ok([ instrumentNumber |-> instrumentNumber.value,
         dateAndTime      |-> dateAndTime.value,
         number           |-> number.value,
         direction        |-> direction.value,
         volumeInt324     |-> volumeInt324.value,
         price            |-> price.value,
         participant      |-> participant.value ], participant.rest)

ZeroOrderAdditionMessage ==
    [ instrumentNumber |-> [i \in 1 .. 4 |-> 0],
      dateAndTime      |-> [i \in 1 .. 8 |-> 0],
      number           |-> [i \in 1 .. 4 |-> 0],
      direction        |-> [i \in 1 .. 1 |-> 0],
      volumeInt324     |-> [i \in 1 .. 4 |-> 0],
      price            |-> [i \in 1 .. 8 |-> 0],
      participant      |-> [i \in 1 .. 5 |-> 0] ]

(* Order Addition Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderAdditionMessage ==
    { ZeroOrderAdditionMessage }
        \cup { [ZeroOrderAdditionMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroOrderAdditionMessage EXCEPT !.dateAndTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderAdditionMessage EXCEPT !.number = one] : one \in Sample(4) }
        \cup { [ZeroOrderAdditionMessage EXCEPT !.direction = one] : one \in Sample(1) }
        \cup { [ZeroOrderAdditionMessage EXCEPT !.volumeInt324 = one] : one \in Sample(4) }
        \cup { [ZeroOrderAdditionMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderAdditionMessage EXCEPT !.participant = one] : one \in Sample(5) }

(***************************************************************************)
(* Execution Of Orders Message: 32 bytes                                   *)
(***************************************************************************)

ExecutionOfOrdersMessage ==
    [ instrumentNumber : Sample(4),
      date             : Sample(8),
      number           : Sample(4),
      volumeInt324     : Sample(4),
      tradeNumber      : Sample(4),
      executionPrice   : Sample(8) ]

EncodeExecutionOfOrdersMessage(message) ==
    message.instrumentNumber
        \o message.date
        \o message.number
        \o message.volumeInt324
        \o message.tradeNumber
        \o message.executionPrice

DecodeExecutionOfOrdersMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET date == ReadBytes(instrumentNumber.rest, 8) IN IF ~date.ok THEN Fail ELSE
    LET number == ReadBytes(date.rest, 4) IN IF ~number.ok THEN Fail ELSE
    LET volumeInt324 == ReadBytes(number.rest, 4) IN IF ~volumeInt324.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(volumeInt324.rest, 4) IN IF ~tradeNumber.ok THEN Fail ELSE
    LET executionPrice == ReadBytes(tradeNumber.rest, 8) IN IF ~executionPrice.ok THEN Fail ELSE
    Ok([ instrumentNumber |-> instrumentNumber.value,
         date             |-> date.value,
         number           |-> number.value,
         volumeInt324     |-> volumeInt324.value,
         tradeNumber      |-> tradeNumber.value,
         executionPrice   |-> executionPrice.value ], executionPrice.rest)

ZeroExecutionOfOrdersMessage ==
    [ instrumentNumber |-> [i \in 1 .. 4 |-> 0],
      date             |-> [i \in 1 .. 8 |-> 0],
      number           |-> [i \in 1 .. 4 |-> 0],
      volumeInt324     |-> [i \in 1 .. 4 |-> 0],
      tradeNumber      |-> [i \in 1 .. 4 |-> 0],
      executionPrice   |-> [i \in 1 .. 8 |-> 0] ]

(* Execution Of Orders Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionOfOrdersMessage ==
    { ZeroExecutionOfOrdersMessage }
        \cup { [ZeroExecutionOfOrdersMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroExecutionOfOrdersMessage EXCEPT !.date = one] : one \in Sample(8) }
        \cup { [ZeroExecutionOfOrdersMessage EXCEPT !.number = one] : one \in Sample(4) }
        \cup { [ZeroExecutionOfOrdersMessage EXCEPT !.volumeInt324 = one] : one \in Sample(4) }
        \cup { [ZeroExecutionOfOrdersMessage EXCEPT !.tradeNumber = one] : one \in Sample(4) }
        \cup { [ZeroExecutionOfOrdersMessage EXCEPT !.executionPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Cancellation Message: 16 bytes                                    *)
(***************************************************************************)

OrderCancellationMessage ==
    [ instrumentNumber : Sample(4),
      date             : Sample(8),
      number           : Sample(4) ]

EncodeOrderCancellationMessage(message) ==
    message.instrumentNumber
        \o message.date
        \o message.number

DecodeOrderCancellationMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET date == ReadBytes(instrumentNumber.rest, 8) IN IF ~date.ok THEN Fail ELSE
    LET number == ReadBytes(date.rest, 4) IN IF ~number.ok THEN Fail ELSE
    Ok([ instrumentNumber |-> instrumentNumber.value,
         date             |-> date.value,
         number           |-> number.value ], number.rest)

ZeroOrderCancellationMessage ==
    [ instrumentNumber |-> [i \in 1 .. 4 |-> 0],
      date             |-> [i \in 1 .. 8 |-> 0],
      number           |-> [i \in 1 .. 4 |-> 0] ]

(* Order Cancellation Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancellationMessage ==
    { ZeroOrderCancellationMessage }
        \cup { [ZeroOrderCancellationMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancellationMessage EXCEPT !.date = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancellationMessage EXCEPT !.number = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Change Message: 41 bytes                                          *)
(***************************************************************************)

OrderChangeMessage ==
    [ instrumentNumber : Sample(4),
      originalDate     : Sample(8),
      originalNumber   : Sample(4),
      newDate          : Sample(8),
      newNumber        : Sample(4),
      direction        : Sample(1),
      volumeInt324     : Sample(4),
      price            : Sample(8) ]

EncodeOrderChangeMessage(message) ==
    message.instrumentNumber
        \o message.originalDate
        \o message.originalNumber
        \o message.newDate
        \o message.newNumber
        \o message.direction
        \o message.volumeInt324
        \o message.price

DecodeOrderChangeMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET originalDate == ReadBytes(instrumentNumber.rest, 8) IN IF ~originalDate.ok THEN Fail ELSE
    LET originalNumber == ReadBytes(originalDate.rest, 4) IN IF ~originalNumber.ok THEN Fail ELSE
    LET newDate == ReadBytes(originalNumber.rest, 8) IN IF ~newDate.ok THEN Fail ELSE
    LET newNumber == ReadBytes(newDate.rest, 4) IN IF ~newNumber.ok THEN Fail ELSE
    LET direction == ReadBytes(newNumber.rest, 1) IN IF ~direction.ok THEN Fail ELSE
    LET volumeInt324 == ReadBytes(direction.rest, 4) IN IF ~volumeInt324.ok THEN Fail ELSE
    LET price == ReadBytes(volumeInt324.rest, 8) IN IF ~price.ok THEN Fail ELSE
    Ok([ instrumentNumber |-> instrumentNumber.value,
         originalDate     |-> originalDate.value,
         originalNumber   |-> originalNumber.value,
         newDate          |-> newDate.value,
         newNumber        |-> newNumber.value,
         direction        |-> direction.value,
         volumeInt324     |-> volumeInt324.value,
         price            |-> price.value ], price.rest)

ZeroOrderChangeMessage ==
    [ instrumentNumber |-> [i \in 1 .. 4 |-> 0],
      originalDate     |-> [i \in 1 .. 8 |-> 0],
      originalNumber   |-> [i \in 1 .. 4 |-> 0],
      newDate          |-> [i \in 1 .. 8 |-> 0],
      newNumber        |-> [i \in 1 .. 4 |-> 0],
      direction        |-> [i \in 1 .. 1 |-> 0],
      volumeInt324     |-> [i \in 1 .. 4 |-> 0],
      price            |-> [i \in 1 .. 8 |-> 0] ]

(* Order Change Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderChangeMessage ==
    { ZeroOrderChangeMessage }
        \cup { [ZeroOrderChangeMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroOrderChangeMessage EXCEPT !.originalDate = one] : one \in Sample(8) }
        \cup { [ZeroOrderChangeMessage EXCEPT !.originalNumber = one] : one \in Sample(4) }
        \cup { [ZeroOrderChangeMessage EXCEPT !.newDate = one] : one \in Sample(8) }
        \cup { [ZeroOrderChangeMessage EXCEPT !.newNumber = one] : one \in Sample(4) }
        \cup { [ZeroOrderChangeMessage EXCEPT !.direction = one] : one \in Sample(1) }
        \cup { [ZeroOrderChangeMessage EXCEPT !.volumeInt324 = one] : one \in Sample(4) }
        \cup { [ZeroOrderChangeMessage EXCEPT !.price = one] : one \in Sample(8) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

EventsSystemMessageCode == 83  \* 0x53
TradeCancellationMessageCode == 72  \* 0x48
StatusChangesMessageCode == 52  \* 0x34
WeightedAveragePriceSettlementPricesMessageCode == 77  \* 0x4d
CapitalTradesMessageCode == 80  \* 0x50
ProbableAllocationPriceMessageCode == 50  \* 0x32
ContinuousAuctionsBeginningMessageCode == 51  \* 0x33
MiddlePriceExistingQuotesMessageCode == 53  \* 0x35
RegistryOperationsMessageCode == 90  \* 0x5a
MutualFundTradesMessageCode == 89  \* 0x59
TradabilityMessageCode == 69  \* 0x45
VirtualTradesMessageCode == 86  \* 0x56
OrderAdditionMessageCode == 65  \* 0x41
ExecutionOfOrdersMessageCode == 67  \* 0x43
OrderCancellationMessageCode == 68  \* 0x44
OrderChangeMessageCode == 70  \* 0x46

Payload ==
    [ tag : {EventsSystemMessageCode}, body : EventsSystemMessage ]
        \cup [ tag : {TradeCancellationMessageCode}, body : TradeCancellationMessage ]
        \cup [ tag : {StatusChangesMessageCode}, body : StatusChangesMessage ]
        \cup [ tag : {WeightedAveragePriceSettlementPricesMessageCode}, body : WeightedAveragePriceSettlementPricesMessage ]
        \cup [ tag : {CapitalTradesMessageCode}, body : CapitalTradesMessage ]
        \cup [ tag : {ProbableAllocationPriceMessageCode}, body : ProbableAllocationPriceMessage ]
        \cup [ tag : {ContinuousAuctionsBeginningMessageCode}, body : ContinuousAuctionsBeginningMessage ]
        \cup [ tag : {MiddlePriceExistingQuotesMessageCode}, body : MiddlePriceExistingQuotesMessage ]
        \cup [ tag : {RegistryOperationsMessageCode}, body : RegistryOperationsMessage ]
        \cup [ tag : {MutualFundTradesMessageCode}, body : MutualFundTradesMessage ]
        \cup [ tag : {TradabilityMessageCode}, body : TradabilityMessage ]
        \cup [ tag : {VirtualTradesMessageCode}, body : VirtualTradesMessage ]
        \cup [ tag : {OrderAdditionMessageCode}, body : OrderAdditionMessage ]
        \cup [ tag : {ExecutionOfOrdersMessageCode}, body : ExecutionOfOrdersMessage ]
        \cup [ tag : {OrderCancellationMessageCode}, body : OrderCancellationMessage ]
        \cup [ tag : {OrderChangeMessageCode}, body : OrderChangeMessage ]

EncodePayload(message) ==
    CASE message.tag = EventsSystemMessageCode -> EncodeEventsSystemMessage(message.body)
      [] message.tag = TradeCancellationMessageCode -> EncodeTradeCancellationMessage(message.body)
      [] message.tag = StatusChangesMessageCode -> EncodeStatusChangesMessage(message.body)
      [] message.tag = WeightedAveragePriceSettlementPricesMessageCode -> EncodeWeightedAveragePriceSettlementPricesMessage(message.body)
      [] message.tag = CapitalTradesMessageCode -> EncodeCapitalTradesMessage(message.body)
      [] message.tag = ProbableAllocationPriceMessageCode -> EncodeProbableAllocationPriceMessage(message.body)
      [] message.tag = ContinuousAuctionsBeginningMessageCode -> EncodeContinuousAuctionsBeginningMessage(message.body)
      [] message.tag = MiddlePriceExistingQuotesMessageCode -> EncodeMiddlePriceExistingQuotesMessage(message.body)
      [] message.tag = RegistryOperationsMessageCode -> EncodeRegistryOperationsMessage(message.body)
      [] message.tag = MutualFundTradesMessageCode -> EncodeMutualFundTradesMessage(message.body)
      [] message.tag = TradabilityMessageCode -> EncodeTradabilityMessage(message.body)
      [] message.tag = VirtualTradesMessageCode -> EncodeVirtualTradesMessage(message.body)
      [] message.tag = OrderAdditionMessageCode -> EncodeOrderAdditionMessage(message.body)
      [] message.tag = ExecutionOfOrdersMessageCode -> EncodeExecutionOfOrdersMessage(message.body)
      [] message.tag = OrderCancellationMessageCode -> EncodeOrderCancellationMessage(message.body)
      [] message.tag = OrderChangeMessageCode -> EncodeOrderChangeMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = EventsSystemMessageCode -> DecodeEventsSystemMessage(bytes)
              [] tag = TradeCancellationMessageCode -> DecodeTradeCancellationMessage(bytes)
              [] tag = StatusChangesMessageCode -> DecodeStatusChangesMessage(bytes)
              [] tag = WeightedAveragePriceSettlementPricesMessageCode -> DecodeWeightedAveragePriceSettlementPricesMessage(bytes)
              [] tag = CapitalTradesMessageCode -> DecodeCapitalTradesMessage(bytes)
              [] tag = ProbableAllocationPriceMessageCode -> DecodeProbableAllocationPriceMessage(bytes)
              [] tag = ContinuousAuctionsBeginningMessageCode -> DecodeContinuousAuctionsBeginningMessage(bytes)
              [] tag = MiddlePriceExistingQuotesMessageCode -> DecodeMiddlePriceExistingQuotesMessage(bytes)
              [] tag = RegistryOperationsMessageCode -> DecodeRegistryOperationsMessage(bytes)
              [] tag = MutualFundTradesMessageCode -> DecodeMutualFundTradesMessage(bytes)
              [] tag = TradabilityMessageCode -> DecodeTradabilityMessage(bytes)
              [] tag = VirtualTradesMessageCode -> DecodeVirtualTradesMessage(bytes)
              [] tag = OrderAdditionMessageCode -> DecodeOrderAdditionMessage(bytes)
              [] tag = ExecutionOfOrdersMessageCode -> DecodeExecutionOfOrdersMessage(bytes)
              [] tag = OrderCancellationMessageCode -> DecodeOrderCancellationMessage(bytes)
              [] tag = OrderChangeMessageCode -> DecodeOrderChangeMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> EventsSystemMessageCode, body |-> ZeroEventsSystemMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> EventsSystemMessageCode, body |-> one] : one \in CheckedEventsSystemMessage }
        \cup { [tag |-> TradeCancellationMessageCode, body |-> one] : one \in CheckedTradeCancellationMessage }
        \cup { [tag |-> StatusChangesMessageCode, body |-> one] : one \in CheckedStatusChangesMessage }
        \cup { [tag |-> WeightedAveragePriceSettlementPricesMessageCode, body |-> one] : one \in CheckedWeightedAveragePriceSettlementPricesMessage }
        \cup { [tag |-> CapitalTradesMessageCode, body |-> one] : one \in CheckedCapitalTradesMessage }
        \cup { [tag |-> ProbableAllocationPriceMessageCode, body |-> one] : one \in CheckedProbableAllocationPriceMessage }
        \cup { [tag |-> ContinuousAuctionsBeginningMessageCode, body |-> one] : one \in CheckedContinuousAuctionsBeginningMessage }
        \cup { [tag |-> MiddlePriceExistingQuotesMessageCode, body |-> one] : one \in CheckedMiddlePriceExistingQuotesMessage }
        \cup { [tag |-> RegistryOperationsMessageCode, body |-> one] : one \in CheckedRegistryOperationsMessage }
        \cup { [tag |-> MutualFundTradesMessageCode, body |-> one] : one \in CheckedMutualFundTradesMessage }
        \cup { [tag |-> TradabilityMessageCode, body |-> one] : one \in CheckedTradabilityMessage }
        \cup { [tag |-> VirtualTradesMessageCode, body |-> one] : one \in CheckedVirtualTradesMessage }
        \cup { [tag |-> OrderAdditionMessageCode, body |-> one] : one \in CheckedOrderAdditionMessage }
        \cup { [tag |-> ExecutionOfOrdersMessageCode, body |-> one] : one \in CheckedExecutionOfOrdersMessage }
        \cup { [tag |-> OrderCancellationMessageCode, body |-> one] : one \in CheckedOrderCancellationMessage }
        \cup { [tag |-> OrderChangeMessageCode, body |-> one] : one \in CheckedOrderChangeMessage }

(***************************************************************************)
(* Message Block, framed by Message Length                                 *)
(***************************************************************************)

MessageBlock ==
    [ payload : Payload ]

EncodeMessageBlockBody(message) ==
    EncodeUIntBE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessageBlock(message) ==
    LET body == EncodeMessageBlockBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeMessageBlockBody(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

DecodeMessageBlock(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeMessageBlockBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroMessageBlock ==
    [ payload |-> ZeroPayload ]

(* Message Block at zero, then each field in turn at the values it is checked at *)
CheckedMessageBlock ==
    { ZeroMessageBlock }
        \cup { [ZeroMessageBlock EXCEPT !.payload = one] : one \in CheckedPayload }

(* A run of Message Block, written one after another *)
RECURSIVE EncodeMessageBlockList(_)
EncodeMessageBlockList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMessageBlock(Head(messages)) \o EncodeMessageBlockList(Tail(messages))

(* As many Message Block as the field that counts them says *)
RECURSIVE ReadMessageBlockList(_, _)
ReadMessageBlockList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMessageBlock(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMessageBlockList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Message Block of each kind, for the lists that carry them *)
OneMessageBlock ==
    { [ZeroMessageBlock EXCEPT !.payload = [tag |-> EventsSystemMessageCode, body |-> ZeroEventsSystemMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> TradeCancellationMessageCode, body |-> ZeroTradeCancellationMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> StatusChangesMessageCode, body |-> ZeroStatusChangesMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> WeightedAveragePriceSettlementPricesMessageCode, body |-> ZeroWeightedAveragePriceSettlementPricesMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> CapitalTradesMessageCode, body |-> ZeroCapitalTradesMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> ProbableAllocationPriceMessageCode, body |-> ZeroProbableAllocationPriceMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> ContinuousAuctionsBeginningMessageCode, body |-> ZeroContinuousAuctionsBeginningMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> MiddlePriceExistingQuotesMessageCode, body |-> ZeroMiddlePriceExistingQuotesMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> RegistryOperationsMessageCode, body |-> ZeroRegistryOperationsMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> MutualFundTradesMessageCode, body |-> ZeroMutualFundTradesMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> TradabilityMessageCode, body |-> ZeroTradabilityMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> VirtualTradesMessageCode, body |-> ZeroVirtualTradesMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> OrderAdditionMessageCode, body |-> ZeroOrderAdditionMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> ExecutionOfOrdersMessageCode, body |-> ZeroExecutionOfOrdersMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> OrderCancellationMessageCode, body |-> ZeroOrderCancellationMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> OrderChangeMessageCode, body |-> ZeroOrderChangeMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ length          : Sample(2),
      marketDataGroup : Sample(1),
      session         : Sample(1),
      sequenceNumber  : Sample(4),
      datetime        : Sample(8),
      messageBlock    : SampleLists(OneMessageBlock) ]

EncodePacket(message) ==
    message.length
        \o EncodeUIntBE(Len(message.messageBlock), 1)
        \o message.marketDataGroup
        \o message.session
        \o message.sequenceNumber
        \o message.datetime
        \o EncodeMessageBlockList(message.messageBlock)

DecodePacket(bytes) ==
    LET length == ReadBytes(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET totalMessages == ReadUIntBE(length.rest, 1) IN IF ~totalMessages.ok THEN Fail ELSE
    LET marketDataGroup == ReadBytes(totalMessages.rest, 1) IN IF ~marketDataGroup.ok THEN Fail ELSE
    LET session == ReadBytes(marketDataGroup.rest, 1) IN IF ~session.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(session.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET datetime == ReadBytes(sequenceNumber.rest, 8) IN IF ~datetime.ok THEN Fail ELSE
    LET messageBlock == ReadMessageBlockList(datetime.rest, totalMessages.value) IN IF ~messageBlock.ok THEN Fail ELSE
    Ok([ length          |-> length.value,
         marketDataGroup |-> marketDataGroup.value,
         session         |-> session.value,
         sequenceNumber  |-> sequenceNumber.value,
         datetime        |-> datetime.value,
         messageBlock    |-> messageBlock.value ], messageBlock.rest)

ZeroPacket ==
    [ length          |-> [i \in 1 .. 2 |-> 0],
      marketDataGroup |-> [i \in 1 .. 1 |-> 0],
      session         |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber  |-> [i \in 1 .. 4 |-> 0],
      datetime        |-> [i \in 1 .. 8 |-> 0],
      messageBlock    |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.length = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.marketDataGroup = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.session = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.datetime = one] : one \in Sample(8) }
        \cup { [ZeroPacket EXCEPT !.messageBlock = one] : one \in SampleLists(OneMessageBlock) }

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

(* Every Events System Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEventsSystemMessage ==
    \A message \in CheckedEventsSystemMessage :
        LET read == DecodeEventsSystemMessage(EncodeEventsSystemMessage(message))
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

(* Every Status Changes Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStatusChangesMessage ==
    \A message \in CheckedStatusChangesMessage :
        LET read == DecodeStatusChangesMessage(EncodeStatusChangesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Weighted Average Price Settlement Prices Message decodes back to what was encoded, and leaves nothing over *)
RoundTripWeightedAveragePriceSettlementPricesMessage ==
    \A message \in CheckedWeightedAveragePriceSettlementPricesMessage :
        LET read == DecodeWeightedAveragePriceSettlementPricesMessage(EncodeWeightedAveragePriceSettlementPricesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Capital Trades Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCapitalTradesMessage ==
    \A message \in CheckedCapitalTradesMessage :
        LET read == DecodeCapitalTradesMessage(EncodeCapitalTradesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Probable Allocation Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripProbableAllocationPriceMessage ==
    \A message \in CheckedProbableAllocationPriceMessage :
        LET read == DecodeProbableAllocationPriceMessage(EncodeProbableAllocationPriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Continuous Auctions Beginning Message decodes back to what was encoded, and leaves nothing over *)
RoundTripContinuousAuctionsBeginningMessage ==
    \A message \in CheckedContinuousAuctionsBeginningMessage :
        LET read == DecodeContinuousAuctionsBeginningMessage(EncodeContinuousAuctionsBeginningMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Middle Price Existing Quotes Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMiddlePriceExistingQuotesMessage ==
    \A message \in CheckedMiddlePriceExistingQuotesMessage :
        LET read == DecodeMiddlePriceExistingQuotesMessage(EncodeMiddlePriceExistingQuotesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Registry Operations Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRegistryOperationsMessage ==
    \A message \in CheckedRegistryOperationsMessage :
        LET read == DecodeRegistryOperationsMessage(EncodeRegistryOperationsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mutual Fund Trades Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMutualFundTradesMessage ==
    \A message \in CheckedMutualFundTradesMessage :
        LET read == DecodeMutualFundTradesMessage(EncodeMutualFundTradesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tradability Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradabilityMessage ==
    \A message \in CheckedTradabilityMessage :
        LET read == DecodeTradabilityMessage(EncodeTradabilityMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Virtual Trades Message decodes back to what was encoded, and leaves nothing over *)
RoundTripVirtualTradesMessage ==
    \A message \in CheckedVirtualTradesMessage :
        LET read == DecodeVirtualTradesMessage(EncodeVirtualTradesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Addition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderAdditionMessage ==
    \A message \in CheckedOrderAdditionMessage :
        LET read == DecodeOrderAdditionMessage(EncodeOrderAdditionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Of Orders Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionOfOrdersMessage ==
    \A message \in CheckedExecutionOfOrdersMessage :
        LET read == DecodeExecutionOfOrdersMessage(EncodeExecutionOfOrdersMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancellation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancellationMessage ==
    \A message \in CheckedOrderCancellationMessage :
        LET read == DecodeOrderCancellationMessage(EncodeOrderCancellationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Change Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderChangeMessage ==
    \A message \in CheckedOrderChangeMessage :
        LET read == DecodeOrderChangeMessage(EncodeOrderChangeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message Block decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageBlock ==
    \A message \in CheckedMessageBlock :
        LET read == DecodeMessageBlock(EncodeMessageBlock(message))
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
FramesMessageBlock ==
    \A message \in CheckedMessageBlock :
        LET bytes == EncodeMessageBlock(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
