------------------ MODULE BmvMarketData_Snapshot_v1_1_Tcp ------------------
(***************************************************************************)
(* Bolsa Mexicana de Valores Bmv Market Data Snapshot v1.1                 *)
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
(* Login Response Message: 1 bytes                                         *)
(***************************************************************************)

LoginResponseMessage ==
    [ loginResponseStatus : Sample(1) ]

EncodeLoginResponseMessage(message) ==
    message.loginResponseStatus

DecodeLoginResponseMessage(bytes) ==
    LET loginResponseStatus == ReadBytes(bytes, 1) IN IF ~loginResponseStatus.ok THEN Fail ELSE
    Ok([ loginResponseStatus |-> loginResponseStatus.value ], loginResponseStatus.rest)

ZeroLoginResponseMessage ==
    [ loginResponseStatus |-> [i \in 1 .. 1 |-> 0] ]

(* Login Response Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginResponseMessage ==
    { ZeroLoginResponseMessage }
        \cup { [ZeroLoginResponseMessage EXCEPT !.loginResponseStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Replay Response Message: 8 bytes                                        *)
(***************************************************************************)

ReplayResponseMessage ==
    [ marketDataGroup      : Sample(1),
      firstMessage         : Sample(4),
      quantity             : Sample(2),
      replayResponseStatus : Sample(1) ]

EncodeReplayResponseMessage(message) ==
    message.marketDataGroup
        \o message.firstMessage
        \o message.quantity
        \o message.replayResponseStatus

DecodeReplayResponseMessage(bytes) ==
    LET marketDataGroup == ReadBytes(bytes, 1) IN IF ~marketDataGroup.ok THEN Fail ELSE
    LET firstMessage == ReadBytes(marketDataGroup.rest, 4) IN IF ~firstMessage.ok THEN Fail ELSE
    LET quantity == ReadBytes(firstMessage.rest, 2) IN IF ~quantity.ok THEN Fail ELSE
    LET replayResponseStatus == ReadBytes(quantity.rest, 1) IN IF ~replayResponseStatus.ok THEN Fail ELSE
    Ok([ marketDataGroup      |-> marketDataGroup.value,
         firstMessage         |-> firstMessage.value,
         quantity             |-> quantity.value,
         replayResponseStatus |-> replayResponseStatus.value ], replayResponseStatus.rest)

ZeroReplayResponseMessage ==
    [ marketDataGroup      |-> [i \in 1 .. 1 |-> 0],
      firstMessage         |-> [i \in 1 .. 4 |-> 0],
      quantity             |-> [i \in 1 .. 2 |-> 0],
      replayResponseStatus |-> [i \in 1 .. 1 |-> 0] ]

(* Replay Response Message at zero, then each field in turn at the values it is checked at *)
CheckedReplayResponseMessage ==
    { ZeroReplayResponseMessage }
        \cup { [ZeroReplayResponseMessage EXCEPT !.marketDataGroup = one] : one \in Sample(1) }
        \cup { [ZeroReplayResponseMessage EXCEPT !.firstMessage = one] : one \in Sample(4) }
        \cup { [ZeroReplayResponseMessage EXCEPT !.quantity = one] : one \in Sample(2) }
        \cup { [ZeroReplayResponseMessage EXCEPT !.replayResponseStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Snapshot Response Message: 6 bytes                                      *)
(***************************************************************************)

SnapshotResponseMessage ==
    [ quantityOfMessages     : Sample(4),
      snapshotResponseStatus : Sample(1),
      snapshotType           : Sample(1) ]

EncodeSnapshotResponseMessage(message) ==
    message.quantityOfMessages
        \o message.snapshotResponseStatus
        \o message.snapshotType

DecodeSnapshotResponseMessage(bytes) ==
    LET quantityOfMessages == ReadBytes(bytes, 4) IN IF ~quantityOfMessages.ok THEN Fail ELSE
    LET snapshotResponseStatus == ReadBytes(quantityOfMessages.rest, 1) IN IF ~snapshotResponseStatus.ok THEN Fail ELSE
    LET snapshotType == ReadBytes(snapshotResponseStatus.rest, 1) IN IF ~snapshotType.ok THEN Fail ELSE
    Ok([ quantityOfMessages     |-> quantityOfMessages.value,
         snapshotResponseStatus |-> snapshotResponseStatus.value,
         snapshotType           |-> snapshotType.value ], snapshotType.rest)

ZeroSnapshotResponseMessage ==
    [ quantityOfMessages     |-> [i \in 1 .. 4 |-> 0],
      snapshotResponseStatus |-> [i \in 1 .. 1 |-> 0],
      snapshotType           |-> [i \in 1 .. 1 |-> 0] ]

(* Snapshot Response Message at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotResponseMessage ==
    { ZeroSnapshotResponseMessage }
        \cup { [ZeroSnapshotResponseMessage EXCEPT !.quantityOfMessages = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotResponseMessage EXCEPT !.snapshotResponseStatus = one] : one \in Sample(1) }
        \cup { [ZeroSnapshotResponseMessage EXCEPT !.snapshotType = one] : one \in Sample(1) }

(***************************************************************************)
(* Snapshot Complete Message: 6 bytes                                      *)
(***************************************************************************)

SnapshotCompleteMessage ==
    [ sequenceNumber  : Sample(4),
      marketDataGroup : Sample(1),
      snapshotType    : Sample(1) ]

EncodeSnapshotCompleteMessage(message) ==
    message.sequenceNumber
        \o message.marketDataGroup
        \o message.snapshotType

DecodeSnapshotCompleteMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET marketDataGroup == ReadBytes(sequenceNumber.rest, 1) IN IF ~marketDataGroup.ok THEN Fail ELSE
    LET snapshotType == ReadBytes(marketDataGroup.rest, 1) IN IF ~snapshotType.ok THEN Fail ELSE
    Ok([ sequenceNumber  |-> sequenceNumber.value,
         marketDataGroup |-> marketDataGroup.value,
         snapshotType    |-> snapshotType.value ], snapshotType.rest)

ZeroSnapshotCompleteMessage ==
    [ sequenceNumber  |-> [i \in 1 .. 4 |-> 0],
      marketDataGroup |-> [i \in 1 .. 1 |-> 0],
      snapshotType    |-> [i \in 1 .. 1 |-> 0] ]

(* Snapshot Complete Message at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotCompleteMessage ==
    { ZeroSnapshotCompleteMessage }
        \cup { [ZeroSnapshotCompleteMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotCompleteMessage EXCEPT !.marketDataGroup = one] : one \in Sample(1) }
        \cup { [ZeroSnapshotCompleteMessage EXCEPT !.snapshotType = one] : one \in Sample(1) }

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
      buyAlpha5        : Sample(5),
      sellAlpha5       : Sample(5),
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
        \o message.buyAlpha5
        \o message.sellAlpha5
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
    LET buyAlpha5 == ReadBytes(amount.rest, 5) IN IF ~buyAlpha5.ok THEN Fail ELSE
    LET sellAlpha5 == ReadBytes(buyAlpha5.rest, 5) IN IF ~sellAlpha5.ok THEN Fail ELSE
    LET settlement == ReadBytes(sellAlpha5.rest, 1) IN IF ~settlement.ok THEN Fail ELSE
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
         buyAlpha5        |-> buyAlpha5.value,
         sellAlpha5       |-> sellAlpha5.value,
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
      buyAlpha5        |-> [i \in 1 .. 5 |-> 0],
      sellAlpha5       |-> [i \in 1 .. 5 |-> 0],
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
        \cup { [ZeroCapitalTradesMessage EXCEPT !.buyAlpha5 = one] : one \in Sample(5) }
        \cup { [ZeroCapitalTradesMessage EXCEPT !.sellAlpha5 = one] : one \in Sample(5) }
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
      buyAlpha5           : Sample(5),
      sellAlpha5          : Sample(5) ]

EncodeVirtualTradesMessage(message) ==
    message.instrumentNumber
        \o message.virtualTradesStatus
        \o message.operationType
        \o message.number
        \o message.volumeInt324
        \o message.concertation
        \o message.buyAlpha5
        \o message.sellAlpha5

DecodeVirtualTradesMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET virtualTradesStatus == ReadBytes(instrumentNumber.rest, 1) IN IF ~virtualTradesStatus.ok THEN Fail ELSE
    LET operationType == ReadBytes(virtualTradesStatus.rest, 1) IN IF ~operationType.ok THEN Fail ELSE
    LET number == ReadBytes(operationType.rest, 4) IN IF ~number.ok THEN Fail ELSE
    LET volumeInt324 == ReadBytes(number.rest, 4) IN IF ~volumeInt324.ok THEN Fail ELSE
    LET concertation == ReadBytes(volumeInt324.rest, 1) IN IF ~concertation.ok THEN Fail ELSE
    LET buyAlpha5 == ReadBytes(concertation.rest, 5) IN IF ~buyAlpha5.ok THEN Fail ELSE
    LET sellAlpha5 == ReadBytes(buyAlpha5.rest, 5) IN IF ~sellAlpha5.ok THEN Fail ELSE
    Ok([ instrumentNumber    |-> instrumentNumber.value,
         virtualTradesStatus |-> virtualTradesStatus.value,
         operationType       |-> operationType.value,
         number              |-> number.value,
         volumeInt324        |-> volumeInt324.value,
         concertation        |-> concertation.value,
         buyAlpha5           |-> buyAlpha5.value,
         sellAlpha5          |-> sellAlpha5.value ], sellAlpha5.rest)

ZeroVirtualTradesMessage ==
    [ instrumentNumber    |-> [i \in 1 .. 4 |-> 0],
      virtualTradesStatus |-> [i \in 1 .. 1 |-> 0],
      operationType       |-> [i \in 1 .. 1 |-> 0],
      number              |-> [i \in 1 .. 4 |-> 0],
      volumeInt324        |-> [i \in 1 .. 4 |-> 0],
      concertation        |-> [i \in 1 .. 1 |-> 0],
      buyAlpha5           |-> [i \in 1 .. 5 |-> 0],
      sellAlpha5          |-> [i \in 1 .. 5 |-> 0] ]

(* Virtual Trades Message at zero, then each field in turn at the values it is checked at *)
CheckedVirtualTradesMessage ==
    { ZeroVirtualTradesMessage }
        \cup { [ZeroVirtualTradesMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroVirtualTradesMessage EXCEPT !.virtualTradesStatus = one] : one \in Sample(1) }
        \cup { [ZeroVirtualTradesMessage EXCEPT !.operationType = one] : one \in Sample(1) }
        \cup { [ZeroVirtualTradesMessage EXCEPT !.number = one] : one \in Sample(4) }
        \cup { [ZeroVirtualTradesMessage EXCEPT !.volumeInt324 = one] : one \in Sample(4) }
        \cup { [ZeroVirtualTradesMessage EXCEPT !.concertation = one] : one \in Sample(1) }
        \cup { [ZeroVirtualTradesMessage EXCEPT !.buyAlpha5 = one] : one \in Sample(5) }
        \cup { [ZeroVirtualTradesMessage EXCEPT !.sellAlpha5 = one] : one \in Sample(5) }

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
(* Price Level: 14 bytes                                                   *)
(***************************************************************************)

PriceLevel ==
    [ price          : Sample(8),
      numberOfOrders : Sample(2),
      volumeInt324   : Sample(4) ]

EncodePriceLevel(message) ==
    message.price
        \o message.numberOfOrders
        \o message.volumeInt324

DecodePriceLevel(bytes) ==
    LET price == ReadBytes(bytes, 8) IN IF ~price.ok THEN Fail ELSE
    LET numberOfOrders == ReadBytes(price.rest, 2) IN IF ~numberOfOrders.ok THEN Fail ELSE
    LET volumeInt324 == ReadBytes(numberOfOrders.rest, 4) IN IF ~volumeInt324.ok THEN Fail ELSE
    Ok([ price          |-> price.value,
         numberOfOrders |-> numberOfOrders.value,
         volumeInt324   |-> volumeInt324.value ], volumeInt324.rest)

ZeroPriceLevel ==
    [ price          |-> [i \in 1 .. 8 |-> 0],
      numberOfOrders |-> [i \in 1 .. 2 |-> 0],
      volumeInt324   |-> [i \in 1 .. 4 |-> 0] ]

(* Price Level at zero, then each field in turn at the values it is checked at *)
CheckedPriceLevel ==
    { ZeroPriceLevel }
        \cup { [ZeroPriceLevel EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroPriceLevel EXCEPT !.numberOfOrders = one] : one \in Sample(2) }
        \cup { [ZeroPriceLevel EXCEPT !.volumeInt324 = one] : one \in Sample(4) }

(* A run of Price Level, written one after another *)
RECURSIVE EncodePriceLevelList(_)
EncodePriceLevelList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodePriceLevel(Head(messages)) \o EncodePriceLevelList(Tail(messages))

(* As many Price Level as the field that counts them says *)
RECURSIVE ReadPriceLevelList(_, _)
ReadPriceLevelList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodePriceLevel(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadPriceLevelList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Price Level of each kind, for the lists that carry them *)
OnePriceLevel == { ZeroPriceLevel }

(***************************************************************************)
(* Depth Message                                                           *)
(***************************************************************************)

DepthMessage ==
    [ instrumentNumber : Sample(4),
      side             : Sample(1),
      priceLevel       : SampleLists(OnePriceLevel) ]

EncodeDepthMessage(message) ==
    message.instrumentNumber
        \o message.side
        \o EncodeUIntBE(Len(message.priceLevel), 1)
        \o EncodePriceLevelList(message.priceLevel)

DecodeDepthMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET side == ReadBytes(instrumentNumber.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET purchaseOrSaleLevels == ReadUIntBE(side.rest, 1) IN IF ~purchaseOrSaleLevels.ok THEN Fail ELSE
    LET priceLevel == ReadPriceLevelList(purchaseOrSaleLevels.rest, purchaseOrSaleLevels.value) IN IF ~priceLevel.ok THEN Fail ELSE
    Ok([ instrumentNumber |-> instrumentNumber.value,
         side             |-> side.value,
         priceLevel       |-> priceLevel.value ], priceLevel.rest)

ZeroDepthMessage ==
    [ instrumentNumber |-> [i \in 1 .. 4 |-> 0],
      side             |-> [i \in 1 .. 1 |-> 0],
      priceLevel       |-> << >> ]

(* Depth Message at zero, then each field in turn at the values it is checked at *)
CheckedDepthMessage ==
    { ZeroDepthMessage }
        \cup { [ZeroDepthMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroDepthMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroDepthMessage EXCEPT !.priceLevel = one] : one \in SampleLists(OnePriceLevel) }

(***************************************************************************)
(* Best Offer Message: 18 bytes                                            *)
(***************************************************************************)

BestOfferMessage ==
    [ instrumentNumber : Sample(4),
      volumeInt324     : Sample(4),
      priceRate        : Sample(8),
      offerDirection   : Sample(1),
      operationType    : Sample(1) ]

EncodeBestOfferMessage(message) ==
    message.instrumentNumber
        \o message.volumeInt324
        \o message.priceRate
        \o message.offerDirection
        \o message.operationType

DecodeBestOfferMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET volumeInt324 == ReadBytes(instrumentNumber.rest, 4) IN IF ~volumeInt324.ok THEN Fail ELSE
    LET priceRate == ReadBytes(volumeInt324.rest, 8) IN IF ~priceRate.ok THEN Fail ELSE
    LET offerDirection == ReadBytes(priceRate.rest, 1) IN IF ~offerDirection.ok THEN Fail ELSE
    LET operationType == ReadBytes(offerDirection.rest, 1) IN IF ~operationType.ok THEN Fail ELSE
    Ok([ instrumentNumber |-> instrumentNumber.value,
         volumeInt324     |-> volumeInt324.value,
         priceRate        |-> priceRate.value,
         offerDirection   |-> offerDirection.value,
         operationType    |-> operationType.value ], operationType.rest)

ZeroBestOfferMessage ==
    [ instrumentNumber |-> [i \in 1 .. 4 |-> 0],
      volumeInt324     |-> [i \in 1 .. 4 |-> 0],
      priceRate        |-> [i \in 1 .. 8 |-> 0],
      offerDirection   |-> [i \in 1 .. 1 |-> 0],
      operationType    |-> [i \in 1 .. 1 |-> 0] ]

(* Best Offer Message at zero, then each field in turn at the values it is checked at *)
CheckedBestOfferMessage ==
    { ZeroBestOfferMessage }
        \cup { [ZeroBestOfferMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroBestOfferMessage EXCEPT !.volumeInt324 = one] : one \in Sample(4) }
        \cup { [ZeroBestOfferMessage EXCEPT !.priceRate = one] : one \in Sample(8) }
        \cup { [ZeroBestOfferMessage EXCEPT !.offerDirection = one] : one \in Sample(1) }
        \cup { [ZeroBestOfferMessage EXCEPT !.operationType = one] : one \in Sample(1) }

(***************************************************************************)
(* Public Offerings Message: 66 bytes                                      *)
(***************************************************************************)

PublicOfferingsMessage ==
    [ instrumentNumber    : Sample(4),
      number              : Sample(4),
      volumeInt648        : Sample(8),
      discountRateOrPrice : Sample(8),
      rateOfReturn        : Sample(4),
      termDays            : Sample(2),
      currencyType        : Sample(1),
      settlement          : Sample(1),
      buyAlpha5           : Sample(5),
      sellAlpha5          : Sample(5),
      placementDate       : Sample(8),
      issueDate           : Sample(8),
      maturityDate        : Sample(8) ]

EncodePublicOfferingsMessage(message) ==
    message.instrumentNumber
        \o message.number
        \o message.volumeInt648
        \o message.discountRateOrPrice
        \o message.rateOfReturn
        \o message.termDays
        \o message.currencyType
        \o message.settlement
        \o message.buyAlpha5
        \o message.sellAlpha5
        \o message.placementDate
        \o message.issueDate
        \o message.maturityDate

DecodePublicOfferingsMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET number == ReadBytes(instrumentNumber.rest, 4) IN IF ~number.ok THEN Fail ELSE
    LET volumeInt648 == ReadBytes(number.rest, 8) IN IF ~volumeInt648.ok THEN Fail ELSE
    LET discountRateOrPrice == ReadBytes(volumeInt648.rest, 8) IN IF ~discountRateOrPrice.ok THEN Fail ELSE
    LET rateOfReturn == ReadBytes(discountRateOrPrice.rest, 4) IN IF ~rateOfReturn.ok THEN Fail ELSE
    LET termDays == ReadBytes(rateOfReturn.rest, 2) IN IF ~termDays.ok THEN Fail ELSE
    LET currencyType == ReadBytes(termDays.rest, 1) IN IF ~currencyType.ok THEN Fail ELSE
    LET settlement == ReadBytes(currencyType.rest, 1) IN IF ~settlement.ok THEN Fail ELSE
    LET buyAlpha5 == ReadBytes(settlement.rest, 5) IN IF ~buyAlpha5.ok THEN Fail ELSE
    LET sellAlpha5 == ReadBytes(buyAlpha5.rest, 5) IN IF ~sellAlpha5.ok THEN Fail ELSE
    LET placementDate == ReadBytes(sellAlpha5.rest, 8) IN IF ~placementDate.ok THEN Fail ELSE
    LET issueDate == ReadBytes(placementDate.rest, 8) IN IF ~issueDate.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(issueDate.rest, 8) IN IF ~maturityDate.ok THEN Fail ELSE
    Ok([ instrumentNumber    |-> instrumentNumber.value,
         number              |-> number.value,
         volumeInt648        |-> volumeInt648.value,
         discountRateOrPrice |-> discountRateOrPrice.value,
         rateOfReturn        |-> rateOfReturn.value,
         termDays            |-> termDays.value,
         currencyType        |-> currencyType.value,
         settlement          |-> settlement.value,
         buyAlpha5           |-> buyAlpha5.value,
         sellAlpha5          |-> sellAlpha5.value,
         placementDate       |-> placementDate.value,
         issueDate           |-> issueDate.value,
         maturityDate        |-> maturityDate.value ], maturityDate.rest)

ZeroPublicOfferingsMessage ==
    [ instrumentNumber    |-> [i \in 1 .. 4 |-> 0],
      number              |-> [i \in 1 .. 4 |-> 0],
      volumeInt648        |-> [i \in 1 .. 8 |-> 0],
      discountRateOrPrice |-> [i \in 1 .. 8 |-> 0],
      rateOfReturn        |-> [i \in 1 .. 4 |-> 0],
      termDays            |-> [i \in 1 .. 2 |-> 0],
      currencyType        |-> [i \in 1 .. 1 |-> 0],
      settlement          |-> [i \in 1 .. 1 |-> 0],
      buyAlpha5           |-> [i \in 1 .. 5 |-> 0],
      sellAlpha5          |-> [i \in 1 .. 5 |-> 0],
      placementDate       |-> [i \in 1 .. 8 |-> 0],
      issueDate           |-> [i \in 1 .. 8 |-> 0],
      maturityDate        |-> [i \in 1 .. 8 |-> 0] ]

(* Public Offerings Message at zero, then each field in turn at the values it is checked at *)
CheckedPublicOfferingsMessage ==
    { ZeroPublicOfferingsMessage }
        \cup { [ZeroPublicOfferingsMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroPublicOfferingsMessage EXCEPT !.number = one] : one \in Sample(4) }
        \cup { [ZeroPublicOfferingsMessage EXCEPT !.volumeInt648 = one] : one \in Sample(8) }
        \cup { [ZeroPublicOfferingsMessage EXCEPT !.discountRateOrPrice = one] : one \in Sample(8) }
        \cup { [ZeroPublicOfferingsMessage EXCEPT !.rateOfReturn = one] : one \in Sample(4) }
        \cup { [ZeroPublicOfferingsMessage EXCEPT !.termDays = one] : one \in Sample(2) }
        \cup { [ZeroPublicOfferingsMessage EXCEPT !.currencyType = one] : one \in Sample(1) }
        \cup { [ZeroPublicOfferingsMessage EXCEPT !.settlement = one] : one \in Sample(1) }
        \cup { [ZeroPublicOfferingsMessage EXCEPT !.buyAlpha5 = one] : one \in Sample(5) }
        \cup { [ZeroPublicOfferingsMessage EXCEPT !.sellAlpha5 = one] : one \in Sample(5) }
        \cup { [ZeroPublicOfferingsMessage EXCEPT !.placementDate = one] : one \in Sample(8) }
        \cup { [ZeroPublicOfferingsMessage EXCEPT !.issueDate = one] : one \in Sample(8) }
        \cup { [ZeroPublicOfferingsMessage EXCEPT !.maturityDate = one] : one \in Sample(8) }

(***************************************************************************)
(* Open Interest Message: 8 bytes                                          *)
(***************************************************************************)

OpenInterestMessage ==
    [ instrumentNumber : Sample(4),
      openInterest     : Sample(4) ]

EncodeOpenInterestMessage(message) ==
    message.instrumentNumber
        \o message.openInterest

DecodeOpenInterestMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET openInterest == ReadBytes(instrumentNumber.rest, 4) IN IF ~openInterest.ok THEN Fail ELSE
    Ok([ instrumentNumber |-> instrumentNumber.value,
         openInterest     |-> openInterest.value ], openInterest.rest)

ZeroOpenInterestMessage ==
    [ instrumentNumber |-> [i \in 1 .. 4 |-> 0],
      openInterest     |-> [i \in 1 .. 4 |-> 0] ]

(* Open Interest Message at zero, then each field in turn at the values it is checked at *)
CheckedOpenInterestMessage ==
    { ZeroOpenInterestMessage }
        \cup { [ZeroOpenInterestMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroOpenInterestMessage EXCEPT !.openInterest = one] : one \in Sample(4) }

(***************************************************************************)
(* Derivatives Market Trades Message: 43 bytes                             *)
(***************************************************************************)

DerivativesMarketTradesMessage ==
    [ instrumentNumber  : Sample(4),
      tradeTime         : Sample(8),
      volumeInt324      : Sample(4),
      priceRate         : Sample(8),
      concertationType  : Sample(1),
      tradeNumber       : Sample(4),
      operationType     : Sample(1),
      amount            : Sample(8),
      parentTradeNumber : Sample(4),
      legType           : Sample(1) ]

EncodeDerivativesMarketTradesMessage(message) ==
    message.instrumentNumber
        \o message.tradeTime
        \o message.volumeInt324
        \o message.priceRate
        \o message.concertationType
        \o message.tradeNumber
        \o message.operationType
        \o message.amount
        \o message.parentTradeNumber
        \o message.legType

DecodeDerivativesMarketTradesMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET tradeTime == ReadBytes(instrumentNumber.rest, 8) IN IF ~tradeTime.ok THEN Fail ELSE
    LET volumeInt324 == ReadBytes(tradeTime.rest, 4) IN IF ~volumeInt324.ok THEN Fail ELSE
    LET priceRate == ReadBytes(volumeInt324.rest, 8) IN IF ~priceRate.ok THEN Fail ELSE
    LET concertationType == ReadBytes(priceRate.rest, 1) IN IF ~concertationType.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(concertationType.rest, 4) IN IF ~tradeNumber.ok THEN Fail ELSE
    LET operationType == ReadBytes(tradeNumber.rest, 1) IN IF ~operationType.ok THEN Fail ELSE
    LET amount == ReadBytes(operationType.rest, 8) IN IF ~amount.ok THEN Fail ELSE
    LET parentTradeNumber == ReadBytes(amount.rest, 4) IN IF ~parentTradeNumber.ok THEN Fail ELSE
    LET legType == ReadBytes(parentTradeNumber.rest, 1) IN IF ~legType.ok THEN Fail ELSE
    Ok([ instrumentNumber  |-> instrumentNumber.value,
         tradeTime         |-> tradeTime.value,
         volumeInt324      |-> volumeInt324.value,
         priceRate         |-> priceRate.value,
         concertationType  |-> concertationType.value,
         tradeNumber       |-> tradeNumber.value,
         operationType     |-> operationType.value,
         amount            |-> amount.value,
         parentTradeNumber |-> parentTradeNumber.value,
         legType           |-> legType.value ], legType.rest)

ZeroDerivativesMarketTradesMessage ==
    [ instrumentNumber  |-> [i \in 1 .. 4 |-> 0],
      tradeTime         |-> [i \in 1 .. 8 |-> 0],
      volumeInt324      |-> [i \in 1 .. 4 |-> 0],
      priceRate         |-> [i \in 1 .. 8 |-> 0],
      concertationType  |-> [i \in 1 .. 1 |-> 0],
      tradeNumber       |-> [i \in 1 .. 4 |-> 0],
      operationType     |-> [i \in 1 .. 1 |-> 0],
      amount            |-> [i \in 1 .. 8 |-> 0],
      parentTradeNumber |-> [i \in 1 .. 4 |-> 0],
      legType           |-> [i \in 1 .. 1 |-> 0] ]

(* Derivatives Market Trades Message at zero, then each field in turn at the values it is checked at *)
CheckedDerivativesMarketTradesMessage ==
    { ZeroDerivativesMarketTradesMessage }
        \cup { [ZeroDerivativesMarketTradesMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroDerivativesMarketTradesMessage EXCEPT !.tradeTime = one] : one \in Sample(8) }
        \cup { [ZeroDerivativesMarketTradesMessage EXCEPT !.volumeInt324 = one] : one \in Sample(4) }
        \cup { [ZeroDerivativesMarketTradesMessage EXCEPT !.priceRate = one] : one \in Sample(8) }
        \cup { [ZeroDerivativesMarketTradesMessage EXCEPT !.concertationType = one] : one \in Sample(1) }
        \cup { [ZeroDerivativesMarketTradesMessage EXCEPT !.tradeNumber = one] : one \in Sample(4) }
        \cup { [ZeroDerivativesMarketTradesMessage EXCEPT !.operationType = one] : one \in Sample(1) }
        \cup { [ZeroDerivativesMarketTradesMessage EXCEPT !.amount = one] : one \in Sample(8) }
        \cup { [ZeroDerivativesMarketTradesMessage EXCEPT !.parentTradeNumber = one] : one \in Sample(4) }
        \cup { [ZeroDerivativesMarketTradesMessage EXCEPT !.legType = one] : one \in Sample(1) }

(***************************************************************************)
(* Statistics Of Instruments Message: 44 bytes                             *)
(***************************************************************************)

StatisticsOfInstrumentsMessage ==
    [ instrumentNumber        : Sample(4),
      previousSettlementPrice : Sample(8),
      openingPrice            : Sample(8),
      maxPriceOfTheDay        : Sample(8),
      lowerPriceOfTheDay      : Sample(8),
      lastPriceOfTheDay       : Sample(8) ]

EncodeStatisticsOfInstrumentsMessage(message) ==
    message.instrumentNumber
        \o message.previousSettlementPrice
        \o message.openingPrice
        \o message.maxPriceOfTheDay
        \o message.lowerPriceOfTheDay
        \o message.lastPriceOfTheDay

DecodeStatisticsOfInstrumentsMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET previousSettlementPrice == ReadBytes(instrumentNumber.rest, 8) IN IF ~previousSettlementPrice.ok THEN Fail ELSE
    LET openingPrice == ReadBytes(previousSettlementPrice.rest, 8) IN IF ~openingPrice.ok THEN Fail ELSE
    LET maxPriceOfTheDay == ReadBytes(openingPrice.rest, 8) IN IF ~maxPriceOfTheDay.ok THEN Fail ELSE
    LET lowerPriceOfTheDay == ReadBytes(maxPriceOfTheDay.rest, 8) IN IF ~lowerPriceOfTheDay.ok THEN Fail ELSE
    LET lastPriceOfTheDay == ReadBytes(lowerPriceOfTheDay.rest, 8) IN IF ~lastPriceOfTheDay.ok THEN Fail ELSE
    Ok([ instrumentNumber        |-> instrumentNumber.value,
         previousSettlementPrice |-> previousSettlementPrice.value,
         openingPrice            |-> openingPrice.value,
         maxPriceOfTheDay        |-> maxPriceOfTheDay.value,
         lowerPriceOfTheDay      |-> lowerPriceOfTheDay.value,
         lastPriceOfTheDay       |-> lastPriceOfTheDay.value ], lastPriceOfTheDay.rest)

ZeroStatisticsOfInstrumentsMessage ==
    [ instrumentNumber        |-> [i \in 1 .. 4 |-> 0],
      previousSettlementPrice |-> [i \in 1 .. 8 |-> 0],
      openingPrice            |-> [i \in 1 .. 8 |-> 0],
      maxPriceOfTheDay        |-> [i \in 1 .. 8 |-> 0],
      lowerPriceOfTheDay      |-> [i \in 1 .. 8 |-> 0],
      lastPriceOfTheDay       |-> [i \in 1 .. 8 |-> 0] ]

(* Statistics Of Instruments Message at zero, then each field in turn at the values it is checked at *)
CheckedStatisticsOfInstrumentsMessage ==
    { ZeroStatisticsOfInstrumentsMessage }
        \cup { [ZeroStatisticsOfInstrumentsMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroStatisticsOfInstrumentsMessage EXCEPT !.previousSettlementPrice = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsOfInstrumentsMessage EXCEPT !.openingPrice = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsOfInstrumentsMessage EXCEPT !.maxPriceOfTheDay = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsOfInstrumentsMessage EXCEPT !.lowerPriceOfTheDay = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsOfInstrumentsMessage EXCEPT !.lastPriceOfTheDay = one] : one \in Sample(8) }

(***************************************************************************)
(* General Indices Message: 33 bytes                                       *)
(***************************************************************************)

GeneralIndicesMessage ==
    [ component      : Sample(2),
      sector         : Sample(1),
      indicesHour    : Sample(8),
      volumeInt648   : Sample(8),
      indicesPrice44 : Sample(4),
      variation      : Sample(4),
      percentage     : Sample(4),
      trend          : Sample(1),
      indicesStatus  : Sample(1) ]

EncodeGeneralIndicesMessage(message) ==
    message.component
        \o message.sector
        \o message.indicesHour
        \o message.volumeInt648
        \o message.indicesPrice44
        \o message.variation
        \o message.percentage
        \o message.trend
        \o message.indicesStatus

DecodeGeneralIndicesMessage(bytes) ==
    LET component == ReadBytes(bytes, 2) IN IF ~component.ok THEN Fail ELSE
    LET sector == ReadBytes(component.rest, 1) IN IF ~sector.ok THEN Fail ELSE
    LET indicesHour == ReadBytes(sector.rest, 8) IN IF ~indicesHour.ok THEN Fail ELSE
    LET volumeInt648 == ReadBytes(indicesHour.rest, 8) IN IF ~volumeInt648.ok THEN Fail ELSE
    LET indicesPrice44 == ReadBytes(volumeInt648.rest, 4) IN IF ~indicesPrice44.ok THEN Fail ELSE
    LET variation == ReadBytes(indicesPrice44.rest, 4) IN IF ~variation.ok THEN Fail ELSE
    LET percentage == ReadBytes(variation.rest, 4) IN IF ~percentage.ok THEN Fail ELSE
    LET trend == ReadBytes(percentage.rest, 1) IN IF ~trend.ok THEN Fail ELSE
    LET indicesStatus == ReadBytes(trend.rest, 1) IN IF ~indicesStatus.ok THEN Fail ELSE
    Ok([ component      |-> component.value,
         sector         |-> sector.value,
         indicesHour    |-> indicesHour.value,
         volumeInt648   |-> volumeInt648.value,
         indicesPrice44 |-> indicesPrice44.value,
         variation      |-> variation.value,
         percentage     |-> percentage.value,
         trend          |-> trend.value,
         indicesStatus  |-> indicesStatus.value ], indicesStatus.rest)

ZeroGeneralIndicesMessage ==
    [ component      |-> [i \in 1 .. 2 |-> 0],
      sector         |-> [i \in 1 .. 1 |-> 0],
      indicesHour    |-> [i \in 1 .. 8 |-> 0],
      volumeInt648   |-> [i \in 1 .. 8 |-> 0],
      indicesPrice44 |-> [i \in 1 .. 4 |-> 0],
      variation      |-> [i \in 1 .. 4 |-> 0],
      percentage     |-> [i \in 1 .. 4 |-> 0],
      trend          |-> [i \in 1 .. 1 |-> 0],
      indicesStatus  |-> [i \in 1 .. 1 |-> 0] ]

(* General Indices Message at zero, then each field in turn at the values it is checked at *)
CheckedGeneralIndicesMessage ==
    { ZeroGeneralIndicesMessage }
        \cup { [ZeroGeneralIndicesMessage EXCEPT !.component = one] : one \in Sample(2) }
        \cup { [ZeroGeneralIndicesMessage EXCEPT !.sector = one] : one \in Sample(1) }
        \cup { [ZeroGeneralIndicesMessage EXCEPT !.indicesHour = one] : one \in Sample(8) }
        \cup { [ZeroGeneralIndicesMessage EXCEPT !.volumeInt648 = one] : one \in Sample(8) }
        \cup { [ZeroGeneralIndicesMessage EXCEPT !.indicesPrice44 = one] : one \in Sample(4) }
        \cup { [ZeroGeneralIndicesMessage EXCEPT !.variation = one] : one \in Sample(4) }
        \cup { [ZeroGeneralIndicesMessage EXCEPT !.percentage = one] : one \in Sample(4) }
        \cup { [ZeroGeneralIndicesMessage EXCEPT !.trend = one] : one \in Sample(1) }
        \cup { [ZeroGeneralIndicesMessage EXCEPT !.indicesStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Indices Components Message: 57 bytes                                    *)
(***************************************************************************)

IndicesComponentsMessage ==
    [ date          : Sample(8),
      component     : Sample(2),
      sector        : Sample(1),
      type          : Sample(1),
      issuer        : Sample(7),
      series        : Sample(6),
      indicesStocks : Sample(8),
      lastPrice     : Sample(8),
      closingPrice  : Sample(8),
      influence     : Sample(8) ]

EncodeIndicesComponentsMessage(message) ==
    message.date
        \o message.component
        \o message.sector
        \o message.type
        \o message.issuer
        \o message.series
        \o message.indicesStocks
        \o message.lastPrice
        \o message.closingPrice
        \o message.influence

DecodeIndicesComponentsMessage(bytes) ==
    LET date == ReadBytes(bytes, 8) IN IF ~date.ok THEN Fail ELSE
    LET component == ReadBytes(date.rest, 2) IN IF ~component.ok THEN Fail ELSE
    LET sector == ReadBytes(component.rest, 1) IN IF ~sector.ok THEN Fail ELSE
    LET type == ReadBytes(sector.rest, 1) IN IF ~type.ok THEN Fail ELSE
    LET issuer == ReadBytes(type.rest, 7) IN IF ~issuer.ok THEN Fail ELSE
    LET series == ReadBytes(issuer.rest, 6) IN IF ~series.ok THEN Fail ELSE
    LET indicesStocks == ReadBytes(series.rest, 8) IN IF ~indicesStocks.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(indicesStocks.rest, 8) IN IF ~lastPrice.ok THEN Fail ELSE
    LET closingPrice == ReadBytes(lastPrice.rest, 8) IN IF ~closingPrice.ok THEN Fail ELSE
    LET influence == ReadBytes(closingPrice.rest, 8) IN IF ~influence.ok THEN Fail ELSE
    Ok([ date          |-> date.value,
         component     |-> component.value,
         sector        |-> sector.value,
         type          |-> type.value,
         issuer        |-> issuer.value,
         series        |-> series.value,
         indicesStocks |-> indicesStocks.value,
         lastPrice     |-> lastPrice.value,
         closingPrice  |-> closingPrice.value,
         influence     |-> influence.value ], influence.rest)

ZeroIndicesComponentsMessage ==
    [ date          |-> [i \in 1 .. 8 |-> 0],
      component     |-> [i \in 1 .. 2 |-> 0],
      sector        |-> [i \in 1 .. 1 |-> 0],
      type          |-> [i \in 1 .. 1 |-> 0],
      issuer        |-> [i \in 1 .. 7 |-> 0],
      series        |-> [i \in 1 .. 6 |-> 0],
      indicesStocks |-> [i \in 1 .. 8 |-> 0],
      lastPrice     |-> [i \in 1 .. 8 |-> 0],
      closingPrice  |-> [i \in 1 .. 8 |-> 0],
      influence     |-> [i \in 1 .. 8 |-> 0] ]

(* Indices Components Message at zero, then each field in turn at the values it is checked at *)
CheckedIndicesComponentsMessage ==
    { ZeroIndicesComponentsMessage }
        \cup { [ZeroIndicesComponentsMessage EXCEPT !.date = one] : one \in Sample(8) }
        \cup { [ZeroIndicesComponentsMessage EXCEPT !.component = one] : one \in Sample(2) }
        \cup { [ZeroIndicesComponentsMessage EXCEPT !.sector = one] : one \in Sample(1) }
        \cup { [ZeroIndicesComponentsMessage EXCEPT !.type = one] : one \in Sample(1) }
        \cup { [ZeroIndicesComponentsMessage EXCEPT !.issuer = one] : one \in Sample(7) }
        \cup { [ZeroIndicesComponentsMessage EXCEPT !.series = one] : one \in Sample(6) }
        \cup { [ZeroIndicesComponentsMessage EXCEPT !.indicesStocks = one] : one \in Sample(8) }
        \cup { [ZeroIndicesComponentsMessage EXCEPT !.lastPrice = one] : one \in Sample(8) }
        \cup { [ZeroIndicesComponentsMessage EXCEPT !.closingPrice = one] : one \in Sample(8) }
        \cup { [ZeroIndicesComponentsMessage EXCEPT !.influence = one] : one \in Sample(8) }

(***************************************************************************)
(* Inav Message: 12 bytes                                                  *)
(***************************************************************************)

InavMessage ==
    [ tracNumber              : Sample(4),
      theoreticalCurrentPrice : Sample(8) ]

EncodeInavMessage(message) ==
    message.tracNumber
        \o message.theoreticalCurrentPrice

DecodeInavMessage(bytes) ==
    LET tracNumber == ReadBytes(bytes, 4) IN IF ~tracNumber.ok THEN Fail ELSE
    LET theoreticalCurrentPrice == ReadBytes(tracNumber.rest, 8) IN IF ~theoreticalCurrentPrice.ok THEN Fail ELSE
    Ok([ tracNumber              |-> tracNumber.value,
         theoreticalCurrentPrice |-> theoreticalCurrentPrice.value ], theoreticalCurrentPrice.rest)

ZeroInavMessage ==
    [ tracNumber              |-> [i \in 1 .. 4 |-> 0],
      theoreticalCurrentPrice |-> [i \in 1 .. 8 |-> 0] ]

(* Inav Message at zero, then each field in turn at the values it is checked at *)
CheckedInavMessage ==
    { ZeroInavMessage }
        \cup { [ZeroInavMessage EXCEPT !.tracNumber = one] : one \in Sample(4) }
        \cup { [ZeroInavMessage EXCEPT !.theoreticalCurrentPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Dollar Buy Sell Message: 38 bytes                                       *)
(***************************************************************************)

DollarBuySellMessage ==
    [ postureDate  : Sample(8),
      currency     : Sample(5),
      dollarSide   : Sample(1),
      buyPrecio88  : Sample(8),
      sellPrecio88 : Sample(8),
      lastDeal     : Sample(8) ]

EncodeDollarBuySellMessage(message) ==
    message.postureDate
        \o message.currency
        \o message.dollarSide
        \o message.buyPrecio88
        \o message.sellPrecio88
        \o message.lastDeal

DecodeDollarBuySellMessage(bytes) ==
    LET postureDate == ReadBytes(bytes, 8) IN IF ~postureDate.ok THEN Fail ELSE
    LET currency == ReadBytes(postureDate.rest, 5) IN IF ~currency.ok THEN Fail ELSE
    LET dollarSide == ReadBytes(currency.rest, 1) IN IF ~dollarSide.ok THEN Fail ELSE
    LET buyPrecio88 == ReadBytes(dollarSide.rest, 8) IN IF ~buyPrecio88.ok THEN Fail ELSE
    LET sellPrecio88 == ReadBytes(buyPrecio88.rest, 8) IN IF ~sellPrecio88.ok THEN Fail ELSE
    LET lastDeal == ReadBytes(sellPrecio88.rest, 8) IN IF ~lastDeal.ok THEN Fail ELSE
    Ok([ postureDate  |-> postureDate.value,
         currency     |-> currency.value,
         dollarSide   |-> dollarSide.value,
         buyPrecio88  |-> buyPrecio88.value,
         sellPrecio88 |-> sellPrecio88.value,
         lastDeal     |-> lastDeal.value ], lastDeal.rest)

ZeroDollarBuySellMessage ==
    [ postureDate  |-> [i \in 1 .. 8 |-> 0],
      currency     |-> [i \in 1 .. 5 |-> 0],
      dollarSide   |-> [i \in 1 .. 1 |-> 0],
      buyPrecio88  |-> [i \in 1 .. 8 |-> 0],
      sellPrecio88 |-> [i \in 1 .. 8 |-> 0],
      lastDeal     |-> [i \in 1 .. 8 |-> 0] ]

(* Dollar Buy Sell Message at zero, then each field in turn at the values it is checked at *)
CheckedDollarBuySellMessage ==
    { ZeroDollarBuySellMessage }
        \cup { [ZeroDollarBuySellMessage EXCEPT !.postureDate = one] : one \in Sample(8) }
        \cup { [ZeroDollarBuySellMessage EXCEPT !.currency = one] : one \in Sample(5) }
        \cup { [ZeroDollarBuySellMessage EXCEPT !.dollarSide = one] : one \in Sample(1) }
        \cup { [ZeroDollarBuySellMessage EXCEPT !.buyPrecio88 = one] : one \in Sample(8) }
        \cup { [ZeroDollarBuySellMessage EXCEPT !.sellPrecio88 = one] : one \in Sample(8) }
        \cup { [ZeroDollarBuySellMessage EXCEPT !.lastDeal = one] : one \in Sample(8) }

(***************************************************************************)
(* Short Sales Balances Per Instrument Message: 44 bytes                   *)
(***************************************************************************)

ShortSalesBalancesPerInstrumentMessage ==
    [ instrumentNumber : Sample(4),
      date             : Sample(8),
      previousBalance  : Sample(8),
      amountTraded     : Sample(8),
      buybacks         : Sample(8),
      currentBalance   : Sample(8) ]

EncodeShortSalesBalancesPerInstrumentMessage(message) ==
    message.instrumentNumber
        \o message.date
        \o message.previousBalance
        \o message.amountTraded
        \o message.buybacks
        \o message.currentBalance

DecodeShortSalesBalancesPerInstrumentMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET date == ReadBytes(instrumentNumber.rest, 8) IN IF ~date.ok THEN Fail ELSE
    LET previousBalance == ReadBytes(date.rest, 8) IN IF ~previousBalance.ok THEN Fail ELSE
    LET amountTraded == ReadBytes(previousBalance.rest, 8) IN IF ~amountTraded.ok THEN Fail ELSE
    LET buybacks == ReadBytes(amountTraded.rest, 8) IN IF ~buybacks.ok THEN Fail ELSE
    LET currentBalance == ReadBytes(buybacks.rest, 8) IN IF ~currentBalance.ok THEN Fail ELSE
    Ok([ instrumentNumber |-> instrumentNumber.value,
         date             |-> date.value,
         previousBalance  |-> previousBalance.value,
         amountTraded     |-> amountTraded.value,
         buybacks         |-> buybacks.value,
         currentBalance   |-> currentBalance.value ], currentBalance.rest)

ZeroShortSalesBalancesPerInstrumentMessage ==
    [ instrumentNumber |-> [i \in 1 .. 4 |-> 0],
      date             |-> [i \in 1 .. 8 |-> 0],
      previousBalance  |-> [i \in 1 .. 8 |-> 0],
      amountTraded     |-> [i \in 1 .. 8 |-> 0],
      buybacks         |-> [i \in 1 .. 8 |-> 0],
      currentBalance   |-> [i \in 1 .. 8 |-> 0] ]

(* Short Sales Balances Per Instrument Message at zero, then each field in turn at the values it is checked at *)
CheckedShortSalesBalancesPerInstrumentMessage ==
    { ZeroShortSalesBalancesPerInstrumentMessage }
        \cup { [ZeroShortSalesBalancesPerInstrumentMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroShortSalesBalancesPerInstrumentMessage EXCEPT !.date = one] : one \in Sample(8) }
        \cup { [ZeroShortSalesBalancesPerInstrumentMessage EXCEPT !.previousBalance = one] : one \in Sample(8) }
        \cup { [ZeroShortSalesBalancesPerInstrumentMessage EXCEPT !.amountTraded = one] : one \in Sample(8) }
        \cup { [ZeroShortSalesBalancesPerInstrumentMessage EXCEPT !.buybacks = one] : one \in Sample(8) }
        \cup { [ZeroShortSalesBalancesPerInstrumentMessage EXCEPT !.currentBalance = one] : one \in Sample(8) }

(***************************************************************************)
(* Capital Market Multiples Message: 130 bytes                             *)
(***************************************************************************)

CapitalMarketMultiplesMessage ==
    [ instrumentId     : Sample(4),
      multipleType     : Sample(1),
      registryNumber   : Sample(1),
      sector           : Sample(1),
      subsector        : Sample(1),
      businessLine     : Sample(1),
      subLine          : Sample(1),
      pflepaMultiple   : Sample(8),
      pfepaMultiple    : Sample(8),
      veUaiidaMultiple : Sample(8),
      pU               : Sample(8),
      pVl              : Sample(8),
      f1PUnoc          : Sample(8),
      f2PUnoc          : Sample(8),
      f1PUe            : Sample(8),
      f2PUe            : Sample(8),
      f1VeUaiida       : Sample(8),
      f2VeUaiida       : Sample(8),
      f1PU             : Sample(8),
      f2PU             : Sample(8),
      f1PVl            : Sample(8),
      f2PVl            : Sample(8) ]

EncodeCapitalMarketMultiplesMessage(message) ==
    message.instrumentId
        \o message.multipleType
        \o message.registryNumber
        \o message.sector
        \o message.subsector
        \o message.businessLine
        \o message.subLine
        \o message.pflepaMultiple
        \o message.pfepaMultiple
        \o message.veUaiidaMultiple
        \o message.pU
        \o message.pVl
        \o message.f1PUnoc
        \o message.f2PUnoc
        \o message.f1PUe
        \o message.f2PUe
        \o message.f1VeUaiida
        \o message.f2VeUaiida
        \o message.f1PU
        \o message.f2PU
        \o message.f1PVl
        \o message.f2PVl

DecodeCapitalMarketMultiplesMessage(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET multipleType == ReadBytes(instrumentId.rest, 1) IN IF ~multipleType.ok THEN Fail ELSE
    LET registryNumber == ReadBytes(multipleType.rest, 1) IN IF ~registryNumber.ok THEN Fail ELSE
    LET sector == ReadBytes(registryNumber.rest, 1) IN IF ~sector.ok THEN Fail ELSE
    LET subsector == ReadBytes(sector.rest, 1) IN IF ~subsector.ok THEN Fail ELSE
    LET businessLine == ReadBytes(subsector.rest, 1) IN IF ~businessLine.ok THEN Fail ELSE
    LET subLine == ReadBytes(businessLine.rest, 1) IN IF ~subLine.ok THEN Fail ELSE
    LET pflepaMultiple == ReadBytes(subLine.rest, 8) IN IF ~pflepaMultiple.ok THEN Fail ELSE
    LET pfepaMultiple == ReadBytes(pflepaMultiple.rest, 8) IN IF ~pfepaMultiple.ok THEN Fail ELSE
    LET veUaiidaMultiple == ReadBytes(pfepaMultiple.rest, 8) IN IF ~veUaiidaMultiple.ok THEN Fail ELSE
    LET pU == ReadBytes(veUaiidaMultiple.rest, 8) IN IF ~pU.ok THEN Fail ELSE
    LET pVl == ReadBytes(pU.rest, 8) IN IF ~pVl.ok THEN Fail ELSE
    LET f1PUnoc == ReadBytes(pVl.rest, 8) IN IF ~f1PUnoc.ok THEN Fail ELSE
    LET f2PUnoc == ReadBytes(f1PUnoc.rest, 8) IN IF ~f2PUnoc.ok THEN Fail ELSE
    LET f1PUe == ReadBytes(f2PUnoc.rest, 8) IN IF ~f1PUe.ok THEN Fail ELSE
    LET f2PUe == ReadBytes(f1PUe.rest, 8) IN IF ~f2PUe.ok THEN Fail ELSE
    LET f1VeUaiida == ReadBytes(f2PUe.rest, 8) IN IF ~f1VeUaiida.ok THEN Fail ELSE
    LET f2VeUaiida == ReadBytes(f1VeUaiida.rest, 8) IN IF ~f2VeUaiida.ok THEN Fail ELSE
    LET f1PU == ReadBytes(f2VeUaiida.rest, 8) IN IF ~f1PU.ok THEN Fail ELSE
    LET f2PU == ReadBytes(f1PU.rest, 8) IN IF ~f2PU.ok THEN Fail ELSE
    LET f1PVl == ReadBytes(f2PU.rest, 8) IN IF ~f1PVl.ok THEN Fail ELSE
    LET f2PVl == ReadBytes(f1PVl.rest, 8) IN IF ~f2PVl.ok THEN Fail ELSE
    Ok([ instrumentId     |-> instrumentId.value,
         multipleType     |-> multipleType.value,
         registryNumber   |-> registryNumber.value,
         sector           |-> sector.value,
         subsector        |-> subsector.value,
         businessLine     |-> businessLine.value,
         subLine          |-> subLine.value,
         pflepaMultiple   |-> pflepaMultiple.value,
         pfepaMultiple    |-> pfepaMultiple.value,
         veUaiidaMultiple |-> veUaiidaMultiple.value,
         pU               |-> pU.value,
         pVl              |-> pVl.value,
         f1PUnoc          |-> f1PUnoc.value,
         f2PUnoc          |-> f2PUnoc.value,
         f1PUe            |-> f1PUe.value,
         f2PUe            |-> f2PUe.value,
         f1VeUaiida       |-> f1VeUaiida.value,
         f2VeUaiida       |-> f2VeUaiida.value,
         f1PU             |-> f1PU.value,
         f2PU             |-> f2PU.value,
         f1PVl            |-> f1PVl.value,
         f2PVl            |-> f2PVl.value ], f2PVl.rest)

ZeroCapitalMarketMultiplesMessage ==
    [ instrumentId     |-> [i \in 1 .. 4 |-> 0],
      multipleType     |-> [i \in 1 .. 1 |-> 0],
      registryNumber   |-> [i \in 1 .. 1 |-> 0],
      sector           |-> [i \in 1 .. 1 |-> 0],
      subsector        |-> [i \in 1 .. 1 |-> 0],
      businessLine     |-> [i \in 1 .. 1 |-> 0],
      subLine          |-> [i \in 1 .. 1 |-> 0],
      pflepaMultiple   |-> [i \in 1 .. 8 |-> 0],
      pfepaMultiple    |-> [i \in 1 .. 8 |-> 0],
      veUaiidaMultiple |-> [i \in 1 .. 8 |-> 0],
      pU               |-> [i \in 1 .. 8 |-> 0],
      pVl              |-> [i \in 1 .. 8 |-> 0],
      f1PUnoc          |-> [i \in 1 .. 8 |-> 0],
      f2PUnoc          |-> [i \in 1 .. 8 |-> 0],
      f1PUe            |-> [i \in 1 .. 8 |-> 0],
      f2PUe            |-> [i \in 1 .. 8 |-> 0],
      f1VeUaiida       |-> [i \in 1 .. 8 |-> 0],
      f2VeUaiida       |-> [i \in 1 .. 8 |-> 0],
      f1PU             |-> [i \in 1 .. 8 |-> 0],
      f2PU             |-> [i \in 1 .. 8 |-> 0],
      f1PVl            |-> [i \in 1 .. 8 |-> 0],
      f2PVl            |-> [i \in 1 .. 8 |-> 0] ]

(* Capital Market Multiples Message at zero, then each field in turn at the values it is checked at *)
CheckedCapitalMarketMultiplesMessage ==
    { ZeroCapitalMarketMultiplesMessage }
        \cup { [ZeroCapitalMarketMultiplesMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroCapitalMarketMultiplesMessage EXCEPT !.multipleType = one] : one \in Sample(1) }
        \cup { [ZeroCapitalMarketMultiplesMessage EXCEPT !.registryNumber = one] : one \in Sample(1) }
        \cup { [ZeroCapitalMarketMultiplesMessage EXCEPT !.sector = one] : one \in Sample(1) }
        \cup { [ZeroCapitalMarketMultiplesMessage EXCEPT !.subsector = one] : one \in Sample(1) }
        \cup { [ZeroCapitalMarketMultiplesMessage EXCEPT !.businessLine = one] : one \in Sample(1) }
        \cup { [ZeroCapitalMarketMultiplesMessage EXCEPT !.subLine = one] : one \in Sample(1) }
        \cup { [ZeroCapitalMarketMultiplesMessage EXCEPT !.pflepaMultiple = one] : one \in Sample(8) }
        \cup { [ZeroCapitalMarketMultiplesMessage EXCEPT !.pfepaMultiple = one] : one \in Sample(8) }
        \cup { [ZeroCapitalMarketMultiplesMessage EXCEPT !.veUaiidaMultiple = one] : one \in Sample(8) }
        \cup { [ZeroCapitalMarketMultiplesMessage EXCEPT !.pU = one] : one \in Sample(8) }
        \cup { [ZeroCapitalMarketMultiplesMessage EXCEPT !.pVl = one] : one \in Sample(8) }
        \cup { [ZeroCapitalMarketMultiplesMessage EXCEPT !.f1PUnoc = one] : one \in Sample(8) }
        \cup { [ZeroCapitalMarketMultiplesMessage EXCEPT !.f2PUnoc = one] : one \in Sample(8) }
        \cup { [ZeroCapitalMarketMultiplesMessage EXCEPT !.f1PUe = one] : one \in Sample(8) }
        \cup { [ZeroCapitalMarketMultiplesMessage EXCEPT !.f2PUe = one] : one \in Sample(8) }
        \cup { [ZeroCapitalMarketMultiplesMessage EXCEPT !.f1VeUaiida = one] : one \in Sample(8) }
        \cup { [ZeroCapitalMarketMultiplesMessage EXCEPT !.f2VeUaiida = one] : one \in Sample(8) }
        \cup { [ZeroCapitalMarketMultiplesMessage EXCEPT !.f1PU = one] : one \in Sample(8) }
        \cup { [ZeroCapitalMarketMultiplesMessage EXCEPT !.f2PU = one] : one \in Sample(8) }
        \cup { [ZeroCapitalMarketMultiplesMessage EXCEPT !.f1PVl = one] : one \in Sample(8) }
        \cup { [ZeroCapitalMarketMultiplesMessage EXCEPT !.f2PVl = one] : one \in Sample(8) }

(***************************************************************************)
(* Benchmark Message: 149 bytes                                            *)
(***************************************************************************)

BenchmarkMessage ==
    [ benchmarkName                  : Sample(40),
      benchmarkDate                  : Sample(8),
      outstanding                    : Sample(8),
      integerAmount                  : Sample(8),
      decimalAmount                  : Sample(4),
      indicesPrecio88                : Sample(8),
      indices24                      : Sample(8),
      rebalance                      : Sample(1),
      dailyPerformance               : Sample(8),
      annualPerformance              : Sample(8),
      monthlyPerformance             : Sample(8),
      last12MonthsPerformance        : Sample(8),
      t24HoursDailyPerformance       : Sample(8),
      t24HoursAnnualPerformance      : Sample(8),
      t24HoursMonthlyPerformance     : Sample(8),
      last12Months24HoursPerformance : Sample(8) ]

EncodeBenchmarkMessage(message) ==
    message.benchmarkName
        \o message.benchmarkDate
        \o message.outstanding
        \o message.integerAmount
        \o message.decimalAmount
        \o message.indicesPrecio88
        \o message.indices24
        \o message.rebalance
        \o message.dailyPerformance
        \o message.annualPerformance
        \o message.monthlyPerformance
        \o message.last12MonthsPerformance
        \o message.t24HoursDailyPerformance
        \o message.t24HoursAnnualPerformance
        \o message.t24HoursMonthlyPerformance
        \o message.last12Months24HoursPerformance

DecodeBenchmarkMessage(bytes) ==
    LET benchmarkName == ReadBytes(bytes, 40) IN IF ~benchmarkName.ok THEN Fail ELSE
    LET benchmarkDate == ReadBytes(benchmarkName.rest, 8) IN IF ~benchmarkDate.ok THEN Fail ELSE
    LET outstanding == ReadBytes(benchmarkDate.rest, 8) IN IF ~outstanding.ok THEN Fail ELSE
    LET integerAmount == ReadBytes(outstanding.rest, 8) IN IF ~integerAmount.ok THEN Fail ELSE
    LET decimalAmount == ReadBytes(integerAmount.rest, 4) IN IF ~decimalAmount.ok THEN Fail ELSE
    LET indicesPrecio88 == ReadBytes(decimalAmount.rest, 8) IN IF ~indicesPrecio88.ok THEN Fail ELSE
    LET indices24 == ReadBytes(indicesPrecio88.rest, 8) IN IF ~indices24.ok THEN Fail ELSE
    LET rebalance == ReadBytes(indices24.rest, 1) IN IF ~rebalance.ok THEN Fail ELSE
    LET dailyPerformance == ReadBytes(rebalance.rest, 8) IN IF ~dailyPerformance.ok THEN Fail ELSE
    LET annualPerformance == ReadBytes(dailyPerformance.rest, 8) IN IF ~annualPerformance.ok THEN Fail ELSE
    LET monthlyPerformance == ReadBytes(annualPerformance.rest, 8) IN IF ~monthlyPerformance.ok THEN Fail ELSE
    LET last12MonthsPerformance == ReadBytes(monthlyPerformance.rest, 8) IN IF ~last12MonthsPerformance.ok THEN Fail ELSE
    LET t24HoursDailyPerformance == ReadBytes(last12MonthsPerformance.rest, 8) IN IF ~t24HoursDailyPerformance.ok THEN Fail ELSE
    LET t24HoursAnnualPerformance == ReadBytes(t24HoursDailyPerformance.rest, 8) IN IF ~t24HoursAnnualPerformance.ok THEN Fail ELSE
    LET t24HoursMonthlyPerformance == ReadBytes(t24HoursAnnualPerformance.rest, 8) IN IF ~t24HoursMonthlyPerformance.ok THEN Fail ELSE
    LET last12Months24HoursPerformance == ReadBytes(t24HoursMonthlyPerformance.rest, 8) IN IF ~last12Months24HoursPerformance.ok THEN Fail ELSE
    Ok([ benchmarkName                  |-> benchmarkName.value,
         benchmarkDate                  |-> benchmarkDate.value,
         outstanding                    |-> outstanding.value,
         integerAmount                  |-> integerAmount.value,
         decimalAmount                  |-> decimalAmount.value,
         indicesPrecio88                |-> indicesPrecio88.value,
         indices24                      |-> indices24.value,
         rebalance                      |-> rebalance.value,
         dailyPerformance               |-> dailyPerformance.value,
         annualPerformance              |-> annualPerformance.value,
         monthlyPerformance             |-> monthlyPerformance.value,
         last12MonthsPerformance        |-> last12MonthsPerformance.value,
         t24HoursDailyPerformance       |-> t24HoursDailyPerformance.value,
         t24HoursAnnualPerformance      |-> t24HoursAnnualPerformance.value,
         t24HoursMonthlyPerformance     |-> t24HoursMonthlyPerformance.value,
         last12Months24HoursPerformance |-> last12Months24HoursPerformance.value ], last12Months24HoursPerformance.rest)

ZeroBenchmarkMessage ==
    [ benchmarkName                  |-> [i \in 1 .. 40 |-> 0],
      benchmarkDate                  |-> [i \in 1 .. 8 |-> 0],
      outstanding                    |-> [i \in 1 .. 8 |-> 0],
      integerAmount                  |-> [i \in 1 .. 8 |-> 0],
      decimalAmount                  |-> [i \in 1 .. 4 |-> 0],
      indicesPrecio88                |-> [i \in 1 .. 8 |-> 0],
      indices24                      |-> [i \in 1 .. 8 |-> 0],
      rebalance                      |-> [i \in 1 .. 1 |-> 0],
      dailyPerformance               |-> [i \in 1 .. 8 |-> 0],
      annualPerformance              |-> [i \in 1 .. 8 |-> 0],
      monthlyPerformance             |-> [i \in 1 .. 8 |-> 0],
      last12MonthsPerformance        |-> [i \in 1 .. 8 |-> 0],
      t24HoursDailyPerformance       |-> [i \in 1 .. 8 |-> 0],
      t24HoursAnnualPerformance      |-> [i \in 1 .. 8 |-> 0],
      t24HoursMonthlyPerformance     |-> [i \in 1 .. 8 |-> 0],
      last12Months24HoursPerformance |-> [i \in 1 .. 8 |-> 0] ]

(* Benchmark Message at zero, then each field in turn at the values it is checked at *)
CheckedBenchmarkMessage ==
    { ZeroBenchmarkMessage }
        \cup { [ZeroBenchmarkMessage EXCEPT !.benchmarkName = one] : one \in Sample(40) }
        \cup { [ZeroBenchmarkMessage EXCEPT !.benchmarkDate = one] : one \in Sample(8) }
        \cup { [ZeroBenchmarkMessage EXCEPT !.outstanding = one] : one \in Sample(8) }
        \cup { [ZeroBenchmarkMessage EXCEPT !.integerAmount = one] : one \in Sample(8) }
        \cup { [ZeroBenchmarkMessage EXCEPT !.decimalAmount = one] : one \in Sample(4) }
        \cup { [ZeroBenchmarkMessage EXCEPT !.indicesPrecio88 = one] : one \in Sample(8) }
        \cup { [ZeroBenchmarkMessage EXCEPT !.indices24 = one] : one \in Sample(8) }
        \cup { [ZeroBenchmarkMessage EXCEPT !.rebalance = one] : one \in Sample(1) }
        \cup { [ZeroBenchmarkMessage EXCEPT !.dailyPerformance = one] : one \in Sample(8) }
        \cup { [ZeroBenchmarkMessage EXCEPT !.annualPerformance = one] : one \in Sample(8) }
        \cup { [ZeroBenchmarkMessage EXCEPT !.monthlyPerformance = one] : one \in Sample(8) }
        \cup { [ZeroBenchmarkMessage EXCEPT !.last12MonthsPerformance = one] : one \in Sample(8) }
        \cup { [ZeroBenchmarkMessage EXCEPT !.t24HoursDailyPerformance = one] : one \in Sample(8) }
        \cup { [ZeroBenchmarkMessage EXCEPT !.t24HoursAnnualPerformance = one] : one \in Sample(8) }
        \cup { [ZeroBenchmarkMessage EXCEPT !.t24HoursMonthlyPerformance = one] : one \in Sample(8) }
        \cup { [ZeroBenchmarkMessage EXCEPT !.last12Months24HoursPerformance = one] : one \in Sample(8) }

(***************************************************************************)
(* Capitalization Rules Message: 39 bytes                                  *)
(***************************************************************************)

CapitalizationRulesMessage ==
    [ instrumentNumber           : Sample(4),
      dateIndicators             : Sample(8),
      bursatilityIndices         : Sample(4),
      bursatilityIndicesSign     : Sample(1),
      betaCoefficient            : Sample(8),
      betaCoefficientSign        : Sample(1),
      correlationCoefficient     : Sample(8),
      correlationCoefficientSign : Sample(1),
      deltaDifference            : Sample(4) ]

EncodeCapitalizationRulesMessage(message) ==
    message.instrumentNumber
        \o message.dateIndicators
        \o message.bursatilityIndices
        \o message.bursatilityIndicesSign
        \o message.betaCoefficient
        \o message.betaCoefficientSign
        \o message.correlationCoefficient
        \o message.correlationCoefficientSign
        \o message.deltaDifference

DecodeCapitalizationRulesMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET dateIndicators == ReadBytes(instrumentNumber.rest, 8) IN IF ~dateIndicators.ok THEN Fail ELSE
    LET bursatilityIndices == ReadBytes(dateIndicators.rest, 4) IN IF ~bursatilityIndices.ok THEN Fail ELSE
    LET bursatilityIndicesSign == ReadBytes(bursatilityIndices.rest, 1) IN IF ~bursatilityIndicesSign.ok THEN Fail ELSE
    LET betaCoefficient == ReadBytes(bursatilityIndicesSign.rest, 8) IN IF ~betaCoefficient.ok THEN Fail ELSE
    LET betaCoefficientSign == ReadBytes(betaCoefficient.rest, 1) IN IF ~betaCoefficientSign.ok THEN Fail ELSE
    LET correlationCoefficient == ReadBytes(betaCoefficientSign.rest, 8) IN IF ~correlationCoefficient.ok THEN Fail ELSE
    LET correlationCoefficientSign == ReadBytes(correlationCoefficient.rest, 1) IN IF ~correlationCoefficientSign.ok THEN Fail ELSE
    LET deltaDifference == ReadBytes(correlationCoefficientSign.rest, 4) IN IF ~deltaDifference.ok THEN Fail ELSE
    Ok([ instrumentNumber           |-> instrumentNumber.value,
         dateIndicators             |-> dateIndicators.value,
         bursatilityIndices         |-> bursatilityIndices.value,
         bursatilityIndicesSign     |-> bursatilityIndicesSign.value,
         betaCoefficient            |-> betaCoefficient.value,
         betaCoefficientSign        |-> betaCoefficientSign.value,
         correlationCoefficient     |-> correlationCoefficient.value,
         correlationCoefficientSign |-> correlationCoefficientSign.value,
         deltaDifference            |-> deltaDifference.value ], deltaDifference.rest)

ZeroCapitalizationRulesMessage ==
    [ instrumentNumber           |-> [i \in 1 .. 4 |-> 0],
      dateIndicators             |-> [i \in 1 .. 8 |-> 0],
      bursatilityIndices         |-> [i \in 1 .. 4 |-> 0],
      bursatilityIndicesSign     |-> [i \in 1 .. 1 |-> 0],
      betaCoefficient            |-> [i \in 1 .. 8 |-> 0],
      betaCoefficientSign        |-> [i \in 1 .. 1 |-> 0],
      correlationCoefficient     |-> [i \in 1 .. 8 |-> 0],
      correlationCoefficientSign |-> [i \in 1 .. 1 |-> 0],
      deltaDifference            |-> [i \in 1 .. 4 |-> 0] ]

(* Capitalization Rules Message at zero, then each field in turn at the values it is checked at *)
CheckedCapitalizationRulesMessage ==
    { ZeroCapitalizationRulesMessage }
        \cup { [ZeroCapitalizationRulesMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroCapitalizationRulesMessage EXCEPT !.dateIndicators = one] : one \in Sample(8) }
        \cup { [ZeroCapitalizationRulesMessage EXCEPT !.bursatilityIndices = one] : one \in Sample(4) }
        \cup { [ZeroCapitalizationRulesMessage EXCEPT !.bursatilityIndicesSign = one] : one \in Sample(1) }
        \cup { [ZeroCapitalizationRulesMessage EXCEPT !.betaCoefficient = one] : one \in Sample(8) }
        \cup { [ZeroCapitalizationRulesMessage EXCEPT !.betaCoefficientSign = one] : one \in Sample(1) }
        \cup { [ZeroCapitalizationRulesMessage EXCEPT !.correlationCoefficient = one] : one \in Sample(8) }
        \cup { [ZeroCapitalizationRulesMessage EXCEPT !.correlationCoefficientSign = one] : one \in Sample(1) }
        \cup { [ZeroCapitalizationRulesMessage EXCEPT !.deltaDifference = one] : one \in Sample(4) }

(***************************************************************************)
(* Closing Price Origin Message: 13 bytes                                  *)
(***************************************************************************)

ClosingPriceOriginMessage ==
    [ instrumentNumber : Sample(4),
      originPrice      : Sample(8),
      sending          : Sample(1) ]

EncodeClosingPriceOriginMessage(message) ==
    message.instrumentNumber
        \o message.originPrice
        \o message.sending

DecodeClosingPriceOriginMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET originPrice == ReadBytes(instrumentNumber.rest, 8) IN IF ~originPrice.ok THEN Fail ELSE
    LET sending == ReadBytes(originPrice.rest, 1) IN IF ~sending.ok THEN Fail ELSE
    Ok([ instrumentNumber |-> instrumentNumber.value,
         originPrice      |-> originPrice.value,
         sending          |-> sending.value ], sending.rest)

ZeroClosingPriceOriginMessage ==
    [ instrumentNumber |-> [i \in 1 .. 4 |-> 0],
      originPrice      |-> [i \in 1 .. 8 |-> 0],
      sending          |-> [i \in 1 .. 1 |-> 0] ]

(* Closing Price Origin Message at zero, then each field in turn at the values it is checked at *)
CheckedClosingPriceOriginMessage ==
    { ZeroClosingPriceOriginMessage }
        \cup { [ZeroClosingPriceOriginMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroClosingPriceOriginMessage EXCEPT !.originPrice = one] : one \in Sample(8) }
        \cup { [ZeroClosingPriceOriginMessage EXCEPT !.sending = one] : one \in Sample(1) }

(***************************************************************************)
(* Mutual Funds Trades Message: 53 bytes                                   *)
(***************************************************************************)

MutualFundsTradesMessage ==
    [ instrumentNumber       : Sample(4),
      origin                 : Sample(1),
      dateOfTheTrade         : Sample(8),
      price                  : Sample(8),
      bookValue              : Sample(8),
      numberOfSalesTrades    : Sample(4),
      salesVolume            : Sample(8),
      numberOfPurchaseTrades : Sample(4),
      purchaseVolume         : Sample(8) ]

EncodeMutualFundsTradesMessage(message) ==
    message.instrumentNumber
        \o message.origin
        \o message.dateOfTheTrade
        \o message.price
        \o message.bookValue
        \o message.numberOfSalesTrades
        \o message.salesVolume
        \o message.numberOfPurchaseTrades
        \o message.purchaseVolume

DecodeMutualFundsTradesMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET origin == ReadBytes(instrumentNumber.rest, 1) IN IF ~origin.ok THEN Fail ELSE
    LET dateOfTheTrade == ReadBytes(origin.rest, 8) IN IF ~dateOfTheTrade.ok THEN Fail ELSE
    LET price == ReadBytes(dateOfTheTrade.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET bookValue == ReadBytes(price.rest, 8) IN IF ~bookValue.ok THEN Fail ELSE
    LET numberOfSalesTrades == ReadBytes(bookValue.rest, 4) IN IF ~numberOfSalesTrades.ok THEN Fail ELSE
    LET salesVolume == ReadBytes(numberOfSalesTrades.rest, 8) IN IF ~salesVolume.ok THEN Fail ELSE
    LET numberOfPurchaseTrades == ReadBytes(salesVolume.rest, 4) IN IF ~numberOfPurchaseTrades.ok THEN Fail ELSE
    LET purchaseVolume == ReadBytes(numberOfPurchaseTrades.rest, 8) IN IF ~purchaseVolume.ok THEN Fail ELSE
    Ok([ instrumentNumber       |-> instrumentNumber.value,
         origin                 |-> origin.value,
         dateOfTheTrade         |-> dateOfTheTrade.value,
         price                  |-> price.value,
         bookValue              |-> bookValue.value,
         numberOfSalesTrades    |-> numberOfSalesTrades.value,
         salesVolume            |-> salesVolume.value,
         numberOfPurchaseTrades |-> numberOfPurchaseTrades.value,
         purchaseVolume         |-> purchaseVolume.value ], purchaseVolume.rest)

ZeroMutualFundsTradesMessage ==
    [ instrumentNumber       |-> [i \in 1 .. 4 |-> 0],
      origin                 |-> [i \in 1 .. 1 |-> 0],
      dateOfTheTrade         |-> [i \in 1 .. 8 |-> 0],
      price                  |-> [i \in 1 .. 8 |-> 0],
      bookValue              |-> [i \in 1 .. 8 |-> 0],
      numberOfSalesTrades    |-> [i \in 1 .. 4 |-> 0],
      salesVolume            |-> [i \in 1 .. 8 |-> 0],
      numberOfPurchaseTrades |-> [i \in 1 .. 4 |-> 0],
      purchaseVolume         |-> [i \in 1 .. 8 |-> 0] ]

(* Mutual Funds Trades Message at zero, then each field in turn at the values it is checked at *)
CheckedMutualFundsTradesMessage ==
    { ZeroMutualFundsTradesMessage }
        \cup { [ZeroMutualFundsTradesMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroMutualFundsTradesMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroMutualFundsTradesMessage EXCEPT !.dateOfTheTrade = one] : one \in Sample(8) }
        \cup { [ZeroMutualFundsTradesMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroMutualFundsTradesMessage EXCEPT !.bookValue = one] : one \in Sample(8) }
        \cup { [ZeroMutualFundsTradesMessage EXCEPT !.numberOfSalesTrades = one] : one \in Sample(4) }
        \cup { [ZeroMutualFundsTradesMessage EXCEPT !.salesVolume = one] : one \in Sample(8) }
        \cup { [ZeroMutualFundsTradesMessage EXCEPT !.numberOfPurchaseTrades = one] : one \in Sample(4) }
        \cup { [ZeroMutualFundsTradesMessage EXCEPT !.purchaseVolume = one] : one \in Sample(8) }

(***************************************************************************)
(* Opening Of Continuous Auctions Message: 21 bytes                        *)
(***************************************************************************)

OpeningOfContinuousAuctionsMessage ==
    [ instrumentNumber          : Sample(4),
      origin                    : Sample(1),
      auctionSessionStartupTime : Sample(8),
      auctionSessionEndTime     : Sample(8) ]

EncodeOpeningOfContinuousAuctionsMessage(message) ==
    message.instrumentNumber
        \o message.origin
        \o message.auctionSessionStartupTime
        \o message.auctionSessionEndTime

DecodeOpeningOfContinuousAuctionsMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET origin == ReadBytes(instrumentNumber.rest, 1) IN IF ~origin.ok THEN Fail ELSE
    LET auctionSessionStartupTime == ReadBytes(origin.rest, 8) IN IF ~auctionSessionStartupTime.ok THEN Fail ELSE
    LET auctionSessionEndTime == ReadBytes(auctionSessionStartupTime.rest, 8) IN IF ~auctionSessionEndTime.ok THEN Fail ELSE
    Ok([ instrumentNumber          |-> instrumentNumber.value,
         origin                    |-> origin.value,
         auctionSessionStartupTime |-> auctionSessionStartupTime.value,
         auctionSessionEndTime     |-> auctionSessionEndTime.value ], auctionSessionEndTime.rest)

ZeroOpeningOfContinuousAuctionsMessage ==
    [ instrumentNumber          |-> [i \in 1 .. 4 |-> 0],
      origin                    |-> [i \in 1 .. 1 |-> 0],
      auctionSessionStartupTime |-> [i \in 1 .. 8 |-> 0],
      auctionSessionEndTime     |-> [i \in 1 .. 8 |-> 0] ]

(* Opening Of Continuous Auctions Message at zero, then each field in turn at the values it is checked at *)
CheckedOpeningOfContinuousAuctionsMessage ==
    { ZeroOpeningOfContinuousAuctionsMessage }
        \cup { [ZeroOpeningOfContinuousAuctionsMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroOpeningOfContinuousAuctionsMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroOpeningOfContinuousAuctionsMessage EXCEPT !.auctionSessionStartupTime = one] : one \in Sample(8) }
        \cup { [ZeroOpeningOfContinuousAuctionsMessage EXCEPT !.auctionSessionEndTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Existence Of Bids At Mid Price Message: 6 bytes                         *)
(***************************************************************************)

ExistenceOfBidsAtMidPriceMessage ==
    [ instrumentNumber : Sample(4),
      origin           : Sample(1),
      bidsExisting     : Sample(1) ]

EncodeExistenceOfBidsAtMidPriceMessage(message) ==
    message.instrumentNumber
        \o message.origin
        \o message.bidsExisting

DecodeExistenceOfBidsAtMidPriceMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET origin == ReadBytes(instrumentNumber.rest, 1) IN IF ~origin.ok THEN Fail ELSE
    LET bidsExisting == ReadBytes(origin.rest, 1) IN IF ~bidsExisting.ok THEN Fail ELSE
    Ok([ instrumentNumber |-> instrumentNumber.value,
         origin           |-> origin.value,
         bidsExisting     |-> bidsExisting.value ], bidsExisting.rest)

ZeroExistenceOfBidsAtMidPriceMessage ==
    [ instrumentNumber |-> [i \in 1 .. 4 |-> 0],
      origin           |-> [i \in 1 .. 1 |-> 0],
      bidsExisting     |-> [i \in 1 .. 1 |-> 0] ]

(* Existence Of Bids At Mid Price Message at zero, then each field in turn at the values it is checked at *)
CheckedExistenceOfBidsAtMidPriceMessage ==
    { ZeroExistenceOfBidsAtMidPriceMessage }
        \cup { [ZeroExistenceOfBidsAtMidPriceMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroExistenceOfBidsAtMidPriceMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroExistenceOfBidsAtMidPriceMessage EXCEPT !.bidsExisting = one] : one \in Sample(1) }

(***************************************************************************)
(* Catalogue Of Debt And Metals Instruments Message: 103 bytes             *)
(***************************************************************************)

CatalogueOfDebtAndMetalsInstrumentsMessage ==
    [ numberOfTheInstrument : Sample(4),
      origin                : Sample(1),
      typeOfValue           : Sample(2),
      issuingCompany        : Sample(7),
      issuance              : Sample(6),
      dateOfIssuance        : Sample(8),
      dateOfMaturity        : Sample(8),
      priceRateOfReference  : Sample(8),
      dateOfReference       : Sample(8),
      reference             : Sample(1),
      termDays              : Sample(2),
      couponPeriod          : Sample(2),
      isin                  : Sample(12),
      market                : Sample(1),
      currentNominalValue   : Sample(8),
      originalNominalValue  : Sample(8),
      outstandingShares     : Sample(8),
      amountPlaced          : Sample(8),
      tradesRatePrice       : Sample(1) ]

EncodeCatalogueOfDebtAndMetalsInstrumentsMessage(message) ==
    message.numberOfTheInstrument
        \o message.origin
        \o message.typeOfValue
        \o message.issuingCompany
        \o message.issuance
        \o message.dateOfIssuance
        \o message.dateOfMaturity
        \o message.priceRateOfReference
        \o message.dateOfReference
        \o message.reference
        \o message.termDays
        \o message.couponPeriod
        \o message.isin
        \o message.market
        \o message.currentNominalValue
        \o message.originalNominalValue
        \o message.outstandingShares
        \o message.amountPlaced
        \o message.tradesRatePrice

DecodeCatalogueOfDebtAndMetalsInstrumentsMessage(bytes) ==
    LET numberOfTheInstrument == ReadBytes(bytes, 4) IN IF ~numberOfTheInstrument.ok THEN Fail ELSE
    LET origin == ReadBytes(numberOfTheInstrument.rest, 1) IN IF ~origin.ok THEN Fail ELSE
    LET typeOfValue == ReadBytes(origin.rest, 2) IN IF ~typeOfValue.ok THEN Fail ELSE
    LET issuingCompany == ReadBytes(typeOfValue.rest, 7) IN IF ~issuingCompany.ok THEN Fail ELSE
    LET issuance == ReadBytes(issuingCompany.rest, 6) IN IF ~issuance.ok THEN Fail ELSE
    LET dateOfIssuance == ReadBytes(issuance.rest, 8) IN IF ~dateOfIssuance.ok THEN Fail ELSE
    LET dateOfMaturity == ReadBytes(dateOfIssuance.rest, 8) IN IF ~dateOfMaturity.ok THEN Fail ELSE
    LET priceRateOfReference == ReadBytes(dateOfMaturity.rest, 8) IN IF ~priceRateOfReference.ok THEN Fail ELSE
    LET dateOfReference == ReadBytes(priceRateOfReference.rest, 8) IN IF ~dateOfReference.ok THEN Fail ELSE
    LET reference == ReadBytes(dateOfReference.rest, 1) IN IF ~reference.ok THEN Fail ELSE
    LET termDays == ReadBytes(reference.rest, 2) IN IF ~termDays.ok THEN Fail ELSE
    LET couponPeriod == ReadBytes(termDays.rest, 2) IN IF ~couponPeriod.ok THEN Fail ELSE
    LET isin == ReadBytes(couponPeriod.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET market == ReadBytes(isin.rest, 1) IN IF ~market.ok THEN Fail ELSE
    LET currentNominalValue == ReadBytes(market.rest, 8) IN IF ~currentNominalValue.ok THEN Fail ELSE
    LET originalNominalValue == ReadBytes(currentNominalValue.rest, 8) IN IF ~originalNominalValue.ok THEN Fail ELSE
    LET outstandingShares == ReadBytes(originalNominalValue.rest, 8) IN IF ~outstandingShares.ok THEN Fail ELSE
    LET amountPlaced == ReadBytes(outstandingShares.rest, 8) IN IF ~amountPlaced.ok THEN Fail ELSE
    LET tradesRatePrice == ReadBytes(amountPlaced.rest, 1) IN IF ~tradesRatePrice.ok THEN Fail ELSE
    Ok([ numberOfTheInstrument |-> numberOfTheInstrument.value,
         origin                |-> origin.value,
         typeOfValue           |-> typeOfValue.value,
         issuingCompany        |-> issuingCompany.value,
         issuance              |-> issuance.value,
         dateOfIssuance        |-> dateOfIssuance.value,
         dateOfMaturity        |-> dateOfMaturity.value,
         priceRateOfReference  |-> priceRateOfReference.value,
         dateOfReference       |-> dateOfReference.value,
         reference             |-> reference.value,
         termDays              |-> termDays.value,
         couponPeriod          |-> couponPeriod.value,
         isin                  |-> isin.value,
         market                |-> market.value,
         currentNominalValue   |-> currentNominalValue.value,
         originalNominalValue  |-> originalNominalValue.value,
         outstandingShares     |-> outstandingShares.value,
         amountPlaced          |-> amountPlaced.value,
         tradesRatePrice       |-> tradesRatePrice.value ], tradesRatePrice.rest)

ZeroCatalogueOfDebtAndMetalsInstrumentsMessage ==
    [ numberOfTheInstrument |-> [i \in 1 .. 4 |-> 0],
      origin                |-> [i \in 1 .. 1 |-> 0],
      typeOfValue           |-> [i \in 1 .. 2 |-> 0],
      issuingCompany        |-> [i \in 1 .. 7 |-> 0],
      issuance              |-> [i \in 1 .. 6 |-> 0],
      dateOfIssuance        |-> [i \in 1 .. 8 |-> 0],
      dateOfMaturity        |-> [i \in 1 .. 8 |-> 0],
      priceRateOfReference  |-> [i \in 1 .. 8 |-> 0],
      dateOfReference       |-> [i \in 1 .. 8 |-> 0],
      reference             |-> [i \in 1 .. 1 |-> 0],
      termDays              |-> [i \in 1 .. 2 |-> 0],
      couponPeriod          |-> [i \in 1 .. 2 |-> 0],
      isin                  |-> [i \in 1 .. 12 |-> 0],
      market                |-> [i \in 1 .. 1 |-> 0],
      currentNominalValue   |-> [i \in 1 .. 8 |-> 0],
      originalNominalValue  |-> [i \in 1 .. 8 |-> 0],
      outstandingShares     |-> [i \in 1 .. 8 |-> 0],
      amountPlaced          |-> [i \in 1 .. 8 |-> 0],
      tradesRatePrice       |-> [i \in 1 .. 1 |-> 0] ]

(* Catalogue Of Debt And Metals Instruments Message at zero, then each field in turn at the values it is checked at *)
CheckedCatalogueOfDebtAndMetalsInstrumentsMessage ==
    { ZeroCatalogueOfDebtAndMetalsInstrumentsMessage }
        \cup { [ZeroCatalogueOfDebtAndMetalsInstrumentsMessage EXCEPT !.numberOfTheInstrument = one] : one \in Sample(4) }
        \cup { [ZeroCatalogueOfDebtAndMetalsInstrumentsMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroCatalogueOfDebtAndMetalsInstrumentsMessage EXCEPT !.typeOfValue = one] : one \in Sample(2) }
        \cup { [ZeroCatalogueOfDebtAndMetalsInstrumentsMessage EXCEPT !.issuingCompany = one] : one \in Sample(7) }
        \cup { [ZeroCatalogueOfDebtAndMetalsInstrumentsMessage EXCEPT !.issuance = one] : one \in Sample(6) }
        \cup { [ZeroCatalogueOfDebtAndMetalsInstrumentsMessage EXCEPT !.dateOfIssuance = one] : one \in Sample(8) }
        \cup { [ZeroCatalogueOfDebtAndMetalsInstrumentsMessage EXCEPT !.dateOfMaturity = one] : one \in Sample(8) }
        \cup { [ZeroCatalogueOfDebtAndMetalsInstrumentsMessage EXCEPT !.priceRateOfReference = one] : one \in Sample(8) }
        \cup { [ZeroCatalogueOfDebtAndMetalsInstrumentsMessage EXCEPT !.dateOfReference = one] : one \in Sample(8) }
        \cup { [ZeroCatalogueOfDebtAndMetalsInstrumentsMessage EXCEPT !.reference = one] : one \in Sample(1) }
        \cup { [ZeroCatalogueOfDebtAndMetalsInstrumentsMessage EXCEPT !.termDays = one] : one \in Sample(2) }
        \cup { [ZeroCatalogueOfDebtAndMetalsInstrumentsMessage EXCEPT !.couponPeriod = one] : one \in Sample(2) }
        \cup { [ZeroCatalogueOfDebtAndMetalsInstrumentsMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroCatalogueOfDebtAndMetalsInstrumentsMessage EXCEPT !.market = one] : one \in Sample(1) }
        \cup { [ZeroCatalogueOfDebtAndMetalsInstrumentsMessage EXCEPT !.currentNominalValue = one] : one \in Sample(8) }
        \cup { [ZeroCatalogueOfDebtAndMetalsInstrumentsMessage EXCEPT !.originalNominalValue = one] : one \in Sample(8) }
        \cup { [ZeroCatalogueOfDebtAndMetalsInstrumentsMessage EXCEPT !.outstandingShares = one] : one \in Sample(8) }
        \cup { [ZeroCatalogueOfDebtAndMetalsInstrumentsMessage EXCEPT !.amountPlaced = one] : one \in Sample(8) }
        \cup { [ZeroCatalogueOfDebtAndMetalsInstrumentsMessage EXCEPT !.tradesRatePrice = one] : one \in Sample(1) }

(***************************************************************************)
(* Catalog Sent For Instruments Belonging To Mutual Funds Message: 78      *)
(* bytes                                                                   *)
(***************************************************************************)

CatalogSentForInstrumentsBelongingToMutualFundsMessage ==
    [ numberOfTheInstrument : Sample(4),
      origin                : Sample(1),
      typeOfValue           : Sample(2),
      issuingCompany        : Sample(7),
      series                : Sample(6),
      sector                : Sample(1),
      subsector             : Sample(1),
      industry              : Sample(1),
      subIndustry           : Sample(1),
      tradingCompany        : Sample(10),
      referencePrice        : Sample(8),
      referenceDate         : Sample(8),
      reference             : Sample(1),
      isin                  : Sample(12),
      rating                : Sample(15) ]

EncodeCatalogSentForInstrumentsBelongingToMutualFundsMessage(message) ==
    message.numberOfTheInstrument
        \o message.origin
        \o message.typeOfValue
        \o message.issuingCompany
        \o message.series
        \o message.sector
        \o message.subsector
        \o message.industry
        \o message.subIndustry
        \o message.tradingCompany
        \o message.referencePrice
        \o message.referenceDate
        \o message.reference
        \o message.isin
        \o message.rating

DecodeCatalogSentForInstrumentsBelongingToMutualFundsMessage(bytes) ==
    LET numberOfTheInstrument == ReadBytes(bytes, 4) IN IF ~numberOfTheInstrument.ok THEN Fail ELSE
    LET origin == ReadBytes(numberOfTheInstrument.rest, 1) IN IF ~origin.ok THEN Fail ELSE
    LET typeOfValue == ReadBytes(origin.rest, 2) IN IF ~typeOfValue.ok THEN Fail ELSE
    LET issuingCompany == ReadBytes(typeOfValue.rest, 7) IN IF ~issuingCompany.ok THEN Fail ELSE
    LET series == ReadBytes(issuingCompany.rest, 6) IN IF ~series.ok THEN Fail ELSE
    LET sector == ReadBytes(series.rest, 1) IN IF ~sector.ok THEN Fail ELSE
    LET subsector == ReadBytes(sector.rest, 1) IN IF ~subsector.ok THEN Fail ELSE
    LET industry == ReadBytes(subsector.rest, 1) IN IF ~industry.ok THEN Fail ELSE
    LET subIndustry == ReadBytes(industry.rest, 1) IN IF ~subIndustry.ok THEN Fail ELSE
    LET tradingCompany == ReadBytes(subIndustry.rest, 10) IN IF ~tradingCompany.ok THEN Fail ELSE
    LET referencePrice == ReadBytes(tradingCompany.rest, 8) IN IF ~referencePrice.ok THEN Fail ELSE
    LET referenceDate == ReadBytes(referencePrice.rest, 8) IN IF ~referenceDate.ok THEN Fail ELSE
    LET reference == ReadBytes(referenceDate.rest, 1) IN IF ~reference.ok THEN Fail ELSE
    LET isin == ReadBytes(reference.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET rating == ReadBytes(isin.rest, 15) IN IF ~rating.ok THEN Fail ELSE
    Ok([ numberOfTheInstrument |-> numberOfTheInstrument.value,
         origin                |-> origin.value,
         typeOfValue           |-> typeOfValue.value,
         issuingCompany        |-> issuingCompany.value,
         series                |-> series.value,
         sector                |-> sector.value,
         subsector             |-> subsector.value,
         industry              |-> industry.value,
         subIndustry           |-> subIndustry.value,
         tradingCompany        |-> tradingCompany.value,
         referencePrice        |-> referencePrice.value,
         referenceDate         |-> referenceDate.value,
         reference             |-> reference.value,
         isin                  |-> isin.value,
         rating                |-> rating.value ], rating.rest)

ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage ==
    [ numberOfTheInstrument |-> [i \in 1 .. 4 |-> 0],
      origin                |-> [i \in 1 .. 1 |-> 0],
      typeOfValue           |-> [i \in 1 .. 2 |-> 0],
      issuingCompany        |-> [i \in 1 .. 7 |-> 0],
      series                |-> [i \in 1 .. 6 |-> 0],
      sector                |-> [i \in 1 .. 1 |-> 0],
      subsector             |-> [i \in 1 .. 1 |-> 0],
      industry              |-> [i \in 1 .. 1 |-> 0],
      subIndustry           |-> [i \in 1 .. 1 |-> 0],
      tradingCompany        |-> [i \in 1 .. 10 |-> 0],
      referencePrice        |-> [i \in 1 .. 8 |-> 0],
      referenceDate         |-> [i \in 1 .. 8 |-> 0],
      reference             |-> [i \in 1 .. 1 |-> 0],
      isin                  |-> [i \in 1 .. 12 |-> 0],
      rating                |-> [i \in 1 .. 15 |-> 0] ]

(* Catalog Sent For Instruments Belonging To Mutual Funds Message at zero, then each field in turn at the values it is checked at *)
CheckedCatalogSentForInstrumentsBelongingToMutualFundsMessage ==
    { ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage EXCEPT !.numberOfTheInstrument = one] : one \in Sample(4) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage EXCEPT !.typeOfValue = one] : one \in Sample(2) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage EXCEPT !.issuingCompany = one] : one \in Sample(7) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage EXCEPT !.series = one] : one \in Sample(6) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage EXCEPT !.sector = one] : one \in Sample(1) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage EXCEPT !.subsector = one] : one \in Sample(1) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage EXCEPT !.industry = one] : one \in Sample(1) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage EXCEPT !.subIndustry = one] : one \in Sample(1) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage EXCEPT !.tradingCompany = one] : one \in Sample(10) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage EXCEPT !.referencePrice = one] : one \in Sample(8) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage EXCEPT !.referenceDate = one] : one \in Sample(8) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage EXCEPT !.reference = one] : one \in Sample(1) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage EXCEPT !.rating = one] : one \in Sample(15) }

(***************************************************************************)
(* Weighted Average Price Message: 21 bytes                                *)
(***************************************************************************)

WeightedAveragePriceMessage ==
    [ instrumentNumber     : Sample(4),
      origin               : Sample(1),
      weightedAveragePrice : Sample(8),
      volatility           : Sample(8) ]

EncodeWeightedAveragePriceMessage(message) ==
    message.instrumentNumber
        \o message.origin
        \o message.weightedAveragePrice
        \o message.volatility

DecodeWeightedAveragePriceMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET origin == ReadBytes(instrumentNumber.rest, 1) IN IF ~origin.ok THEN Fail ELSE
    LET weightedAveragePrice == ReadBytes(origin.rest, 8) IN IF ~weightedAveragePrice.ok THEN Fail ELSE
    LET volatility == ReadBytes(weightedAveragePrice.rest, 8) IN IF ~volatility.ok THEN Fail ELSE
    Ok([ instrumentNumber     |-> instrumentNumber.value,
         origin               |-> origin.value,
         weightedAveragePrice |-> weightedAveragePrice.value,
         volatility           |-> volatility.value ], volatility.rest)

ZeroWeightedAveragePriceMessage ==
    [ instrumentNumber     |-> [i \in 1 .. 4 |-> 0],
      origin               |-> [i \in 1 .. 1 |-> 0],
      weightedAveragePrice |-> [i \in 1 .. 8 |-> 0],
      volatility           |-> [i \in 1 .. 8 |-> 0] ]

(* Weighted Average Price Message at zero, then each field in turn at the values it is checked at *)
CheckedWeightedAveragePriceMessage ==
    { ZeroWeightedAveragePriceMessage }
        \cup { [ZeroWeightedAveragePriceMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroWeightedAveragePriceMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroWeightedAveragePriceMessage EXCEPT !.weightedAveragePrice = one] : one \in Sample(8) }
        \cup { [ZeroWeightedAveragePriceMessage EXCEPT !.volatility = one] : one \in Sample(8) }

(***************************************************************************)
(* System Events Message: 31 bytes                                         *)
(***************************************************************************)

SystemEventsMessage ==
    [ instrumentNumber : Sample(4),
      origin           : Sample(1),
      codeOfEvent      : Sample(1),
      market           : Sample(1),
      sendTime         : Sample(8),
      endTime          : Sample(8),
      group            : Sample(8) ]

EncodeSystemEventsMessage(message) ==
    message.instrumentNumber
        \o message.origin
        \o message.codeOfEvent
        \o message.market
        \o message.sendTime
        \o message.endTime
        \o message.group

DecodeSystemEventsMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET origin == ReadBytes(instrumentNumber.rest, 1) IN IF ~origin.ok THEN Fail ELSE
    LET codeOfEvent == ReadBytes(origin.rest, 1) IN IF ~codeOfEvent.ok THEN Fail ELSE
    LET market == ReadBytes(codeOfEvent.rest, 1) IN IF ~market.ok THEN Fail ELSE
    LET sendTime == ReadBytes(market.rest, 8) IN IF ~sendTime.ok THEN Fail ELSE
    LET endTime == ReadBytes(sendTime.rest, 8) IN IF ~endTime.ok THEN Fail ELSE
    LET group == ReadBytes(endTime.rest, 8) IN IF ~group.ok THEN Fail ELSE
    Ok([ instrumentNumber |-> instrumentNumber.value,
         origin           |-> origin.value,
         codeOfEvent      |-> codeOfEvent.value,
         market           |-> market.value,
         sendTime         |-> sendTime.value,
         endTime          |-> endTime.value,
         group            |-> group.value ], group.rest)

ZeroSystemEventsMessage ==
    [ instrumentNumber |-> [i \in 1 .. 4 |-> 0],
      origin           |-> [i \in 1 .. 1 |-> 0],
      codeOfEvent      |-> [i \in 1 .. 1 |-> 0],
      market           |-> [i \in 1 .. 1 |-> 0],
      sendTime         |-> [i \in 1 .. 8 |-> 0],
      endTime          |-> [i \in 1 .. 8 |-> 0],
      group            |-> [i \in 1 .. 8 |-> 0] ]

(* System Events Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventsMessage ==
    { ZeroSystemEventsMessage }
        \cup { [ZeroSystemEventsMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroSystemEventsMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroSystemEventsMessage EXCEPT !.codeOfEvent = one] : one \in Sample(1) }
        \cup { [ZeroSystemEventsMessage EXCEPT !.market = one] : one \in Sample(1) }
        \cup { [ZeroSystemEventsMessage EXCEPT !.sendTime = one] : one \in Sample(8) }
        \cup { [ZeroSystemEventsMessage EXCEPT !.endTime = one] : one \in Sample(8) }
        \cup { [ZeroSystemEventsMessage EXCEPT !.group = one] : one \in Sample(8) }

(***************************************************************************)
(* Reference Price Message: 14 bytes                                       *)
(***************************************************************************)

ReferencePriceMessage ==
    [ instrumentNumber : Sample(4),
      origin           : Sample(1),
      price            : Sample(8),
      priceType        : Sample(1) ]

EncodeReferencePriceMessage(message) ==
    message.instrumentNumber
        \o message.origin
        \o message.price
        \o message.priceType

DecodeReferencePriceMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET origin == ReadBytes(instrumentNumber.rest, 1) IN IF ~origin.ok THEN Fail ELSE
    LET price == ReadBytes(origin.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET priceType == ReadBytes(price.rest, 1) IN IF ~priceType.ok THEN Fail ELSE
    Ok([ instrumentNumber |-> instrumentNumber.value,
         origin           |-> origin.value,
         price            |-> price.value,
         priceType        |-> priceType.value ], priceType.rest)

ZeroReferencePriceMessage ==
    [ instrumentNumber |-> [i \in 1 .. 4 |-> 0],
      origin           |-> [i \in 1 .. 1 |-> 0],
      price            |-> [i \in 1 .. 8 |-> 0],
      priceType        |-> [i \in 1 .. 1 |-> 0] ]

(* Reference Price Message at zero, then each field in turn at the values it is checked at *)
CheckedReferencePriceMessage ==
    { ZeroReferencePriceMessage }
        \cup { [ZeroReferencePriceMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroReferencePriceMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroReferencePriceMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroReferencePriceMessage EXCEPT !.priceType = one] : one \in Sample(1) }

(***************************************************************************)
(* Changes In Status Message: 7 bytes                                      *)
(***************************************************************************)

ChangesInStatusMessage ==
    [ instrumentNumber : Sample(4),
      origin           : Sample(1),
      status           : Sample(1),
      reason           : Sample(1) ]

EncodeChangesInStatusMessage(message) ==
    message.instrumentNumber
        \o message.origin
        \o message.status
        \o message.reason

DecodeChangesInStatusMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET origin == ReadBytes(instrumentNumber.rest, 1) IN IF ~origin.ok THEN Fail ELSE
    LET status == ReadBytes(origin.rest, 1) IN IF ~status.ok THEN Fail ELSE
    LET reason == ReadBytes(status.rest, 1) IN IF ~reason.ok THEN Fail ELSE
    Ok([ instrumentNumber |-> instrumentNumber.value,
         origin           |-> origin.value,
         status           |-> status.value,
         reason           |-> reason.value ], reason.rest)

ZeroChangesInStatusMessage ==
    [ instrumentNumber |-> [i \in 1 .. 4 |-> 0],
      origin           |-> [i \in 1 .. 1 |-> 0],
      status           |-> [i \in 1 .. 1 |-> 0],
      reason           |-> [i \in 1 .. 1 |-> 0] ]

(* Changes In Status Message at zero, then each field in turn at the values it is checked at *)
CheckedChangesInStatusMessage ==
    { ZeroChangesInStatusMessage }
        \cup { [ZeroChangesInStatusMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroChangesInStatusMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroChangesInStatusMessage EXCEPT !.status = one] : one \in Sample(1) }
        \cup { [ZeroChangesInStatusMessage EXCEPT !.reason = one] : one \in Sample(1) }

(***************************************************************************)
(* Catalog For Instruments Belonging To The Capital Warrants Market        *)
(* Message: 66 bytes                                                       *)
(***************************************************************************)

CatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage ==
    [ numberOfTheInstrument : Sample(4),
      origin                : Sample(1),
      typeOfValue           : Sample(2),
      issuingCompany        : Sample(7),
      series                : Sample(6),
      typeOfWarrant         : Sample(1),
      dateOfMaturity        : Sample(8),
      priceOfExercise       : Sample(8),
      referencePrice        : Sample(8),
      referenceDate         : Sample(8),
      reference             : Sample(1),
      isin                  : Sample(12) ]

EncodeCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage(message) ==
    message.numberOfTheInstrument
        \o message.origin
        \o message.typeOfValue
        \o message.issuingCompany
        \o message.series
        \o message.typeOfWarrant
        \o message.dateOfMaturity
        \o message.priceOfExercise
        \o message.referencePrice
        \o message.referenceDate
        \o message.reference
        \o message.isin

DecodeCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage(bytes) ==
    LET numberOfTheInstrument == ReadBytes(bytes, 4) IN IF ~numberOfTheInstrument.ok THEN Fail ELSE
    LET origin == ReadBytes(numberOfTheInstrument.rest, 1) IN IF ~origin.ok THEN Fail ELSE
    LET typeOfValue == ReadBytes(origin.rest, 2) IN IF ~typeOfValue.ok THEN Fail ELSE
    LET issuingCompany == ReadBytes(typeOfValue.rest, 7) IN IF ~issuingCompany.ok THEN Fail ELSE
    LET series == ReadBytes(issuingCompany.rest, 6) IN IF ~series.ok THEN Fail ELSE
    LET typeOfWarrant == ReadBytes(series.rest, 1) IN IF ~typeOfWarrant.ok THEN Fail ELSE
    LET dateOfMaturity == ReadBytes(typeOfWarrant.rest, 8) IN IF ~dateOfMaturity.ok THEN Fail ELSE
    LET priceOfExercise == ReadBytes(dateOfMaturity.rest, 8) IN IF ~priceOfExercise.ok THEN Fail ELSE
    LET referencePrice == ReadBytes(priceOfExercise.rest, 8) IN IF ~referencePrice.ok THEN Fail ELSE
    LET referenceDate == ReadBytes(referencePrice.rest, 8) IN IF ~referenceDate.ok THEN Fail ELSE
    LET reference == ReadBytes(referenceDate.rest, 1) IN IF ~reference.ok THEN Fail ELSE
    LET isin == ReadBytes(reference.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    Ok([ numberOfTheInstrument |-> numberOfTheInstrument.value,
         origin                |-> origin.value,
         typeOfValue           |-> typeOfValue.value,
         issuingCompany        |-> issuingCompany.value,
         series                |-> series.value,
         typeOfWarrant         |-> typeOfWarrant.value,
         dateOfMaturity        |-> dateOfMaturity.value,
         priceOfExercise       |-> priceOfExercise.value,
         referencePrice        |-> referencePrice.value,
         referenceDate         |-> referenceDate.value,
         reference             |-> reference.value,
         isin                  |-> isin.value ], isin.rest)

ZeroCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage ==
    [ numberOfTheInstrument |-> [i \in 1 .. 4 |-> 0],
      origin                |-> [i \in 1 .. 1 |-> 0],
      typeOfValue           |-> [i \in 1 .. 2 |-> 0],
      issuingCompany        |-> [i \in 1 .. 7 |-> 0],
      series                |-> [i \in 1 .. 6 |-> 0],
      typeOfWarrant         |-> [i \in 1 .. 1 |-> 0],
      dateOfMaturity        |-> [i \in 1 .. 8 |-> 0],
      priceOfExercise       |-> [i \in 1 .. 8 |-> 0],
      referencePrice        |-> [i \in 1 .. 8 |-> 0],
      referenceDate         |-> [i \in 1 .. 8 |-> 0],
      reference             |-> [i \in 1 .. 1 |-> 0],
      isin                  |-> [i \in 1 .. 12 |-> 0] ]

(* Catalog For Instruments Belonging To The Capital Warrants Market Message at zero, then each field in turn at the values it is checked at *)
CheckedCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage ==
    { ZeroCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage EXCEPT !.numberOfTheInstrument = one] : one \in Sample(4) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage EXCEPT !.typeOfValue = one] : one \in Sample(2) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage EXCEPT !.issuingCompany = one] : one \in Sample(7) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage EXCEPT !.series = one] : one \in Sample(6) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage EXCEPT !.typeOfWarrant = one] : one \in Sample(1) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage EXCEPT !.dateOfMaturity = one] : one \in Sample(8) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage EXCEPT !.priceOfExercise = one] : one \in Sample(8) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage EXCEPT !.referencePrice = one] : one \in Sample(8) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage EXCEPT !.referenceDate = one] : one \in Sample(8) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage EXCEPT !.reference = one] : one \in Sample(1) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage EXCEPT !.isin = one] : one \in Sample(12) }

(***************************************************************************)
(* Catalog Sent For Instruments Belonging To Capital Tracs Message: 82     *)
(* bytes                                                                   *)
(***************************************************************************)

CatalogSentForInstrumentsBelongingToCapitalTracsMessage ==
    [ numberOfTheTrac          : Sample(4),
      origin                   : Sample(1),
      nameOfTheTrac            : Sample(8),
      underlyingIssuingCompany : Sample(7),
      underlyingSeries         : Sample(6),
      securities               : Sample(8),
      excludedSecurities       : Sample(8),
      price                    : Sample(8),
      componentInCash          : Sample(8),
      excludedValue            : Sample(8),
      numberOfCertificates     : Sample(8),
      theoreticalPrice         : Sample(8) ]

EncodeCatalogSentForInstrumentsBelongingToCapitalTracsMessage(message) ==
    message.numberOfTheTrac
        \o message.origin
        \o message.nameOfTheTrac
        \o message.underlyingIssuingCompany
        \o message.underlyingSeries
        \o message.securities
        \o message.excludedSecurities
        \o message.price
        \o message.componentInCash
        \o message.excludedValue
        \o message.numberOfCertificates
        \o message.theoreticalPrice

DecodeCatalogSentForInstrumentsBelongingToCapitalTracsMessage(bytes) ==
    LET numberOfTheTrac == ReadBytes(bytes, 4) IN IF ~numberOfTheTrac.ok THEN Fail ELSE
    LET origin == ReadBytes(numberOfTheTrac.rest, 1) IN IF ~origin.ok THEN Fail ELSE
    LET nameOfTheTrac == ReadBytes(origin.rest, 8) IN IF ~nameOfTheTrac.ok THEN Fail ELSE
    LET underlyingIssuingCompany == ReadBytes(nameOfTheTrac.rest, 7) IN IF ~underlyingIssuingCompany.ok THEN Fail ELSE
    LET underlyingSeries == ReadBytes(underlyingIssuingCompany.rest, 6) IN IF ~underlyingSeries.ok THEN Fail ELSE
    LET securities == ReadBytes(underlyingSeries.rest, 8) IN IF ~securities.ok THEN Fail ELSE
    LET excludedSecurities == ReadBytes(securities.rest, 8) IN IF ~excludedSecurities.ok THEN Fail ELSE
    LET price == ReadBytes(excludedSecurities.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET componentInCash == ReadBytes(price.rest, 8) IN IF ~componentInCash.ok THEN Fail ELSE
    LET excludedValue == ReadBytes(componentInCash.rest, 8) IN IF ~excludedValue.ok THEN Fail ELSE
    LET numberOfCertificates == ReadBytes(excludedValue.rest, 8) IN IF ~numberOfCertificates.ok THEN Fail ELSE
    LET theoreticalPrice == ReadBytes(numberOfCertificates.rest, 8) IN IF ~theoreticalPrice.ok THEN Fail ELSE
    Ok([ numberOfTheTrac          |-> numberOfTheTrac.value,
         origin                   |-> origin.value,
         nameOfTheTrac            |-> nameOfTheTrac.value,
         underlyingIssuingCompany |-> underlyingIssuingCompany.value,
         underlyingSeries         |-> underlyingSeries.value,
         securities               |-> securities.value,
         excludedSecurities       |-> excludedSecurities.value,
         price                    |-> price.value,
         componentInCash          |-> componentInCash.value,
         excludedValue            |-> excludedValue.value,
         numberOfCertificates     |-> numberOfCertificates.value,
         theoreticalPrice         |-> theoreticalPrice.value ], theoreticalPrice.rest)

ZeroCatalogSentForInstrumentsBelongingToCapitalTracsMessage ==
    [ numberOfTheTrac          |-> [i \in 1 .. 4 |-> 0],
      origin                   |-> [i \in 1 .. 1 |-> 0],
      nameOfTheTrac            |-> [i \in 1 .. 8 |-> 0],
      underlyingIssuingCompany |-> [i \in 1 .. 7 |-> 0],
      underlyingSeries         |-> [i \in 1 .. 6 |-> 0],
      securities               |-> [i \in 1 .. 8 |-> 0],
      excludedSecurities       |-> [i \in 1 .. 8 |-> 0],
      price                    |-> [i \in 1 .. 8 |-> 0],
      componentInCash          |-> [i \in 1 .. 8 |-> 0],
      excludedValue            |-> [i \in 1 .. 8 |-> 0],
      numberOfCertificates     |-> [i \in 1 .. 8 |-> 0],
      theoreticalPrice         |-> [i \in 1 .. 8 |-> 0] ]

(* Catalog Sent For Instruments Belonging To Capital Tracs Message at zero, then each field in turn at the values it is checked at *)
CheckedCatalogSentForInstrumentsBelongingToCapitalTracsMessage ==
    { ZeroCatalogSentForInstrumentsBelongingToCapitalTracsMessage }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToCapitalTracsMessage EXCEPT !.numberOfTheTrac = one] : one \in Sample(4) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToCapitalTracsMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToCapitalTracsMessage EXCEPT !.nameOfTheTrac = one] : one \in Sample(8) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToCapitalTracsMessage EXCEPT !.underlyingIssuingCompany = one] : one \in Sample(7) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToCapitalTracsMessage EXCEPT !.underlyingSeries = one] : one \in Sample(6) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToCapitalTracsMessage EXCEPT !.securities = one] : one \in Sample(8) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToCapitalTracsMessage EXCEPT !.excludedSecurities = one] : one \in Sample(8) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToCapitalTracsMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToCapitalTracsMessage EXCEPT !.componentInCash = one] : one \in Sample(8) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToCapitalTracsMessage EXCEPT !.excludedValue = one] : one \in Sample(8) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToCapitalTracsMessage EXCEPT !.numberOfCertificates = one] : one \in Sample(8) }
        \cup { [ZeroCatalogSentForInstrumentsBelongingToCapitalTracsMessage EXCEPT !.theoreticalPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Consolidated Inav Message: 13 bytes                                     *)
(***************************************************************************)

ConsolidatedInavMessage ==
    [ numberOfTheTrac         : Sample(4),
      origin                  : Sample(1),
      currentTheoreticalPrice : Sample(8) ]

EncodeConsolidatedInavMessage(message) ==
    message.numberOfTheTrac
        \o message.origin
        \o message.currentTheoreticalPrice

DecodeConsolidatedInavMessage(bytes) ==
    LET numberOfTheTrac == ReadBytes(bytes, 4) IN IF ~numberOfTheTrac.ok THEN Fail ELSE
    LET origin == ReadBytes(numberOfTheTrac.rest, 1) IN IF ~origin.ok THEN Fail ELSE
    LET currentTheoreticalPrice == ReadBytes(origin.rest, 8) IN IF ~currentTheoreticalPrice.ok THEN Fail ELSE
    Ok([ numberOfTheTrac         |-> numberOfTheTrac.value,
         origin                  |-> origin.value,
         currentTheoreticalPrice |-> currentTheoreticalPrice.value ], currentTheoreticalPrice.rest)

ZeroConsolidatedInavMessage ==
    [ numberOfTheTrac         |-> [i \in 1 .. 4 |-> 0],
      origin                  |-> [i \in 1 .. 1 |-> 0],
      currentTheoreticalPrice |-> [i \in 1 .. 8 |-> 0] ]

(* Consolidated Inav Message at zero, then each field in turn at the values it is checked at *)
CheckedConsolidatedInavMessage ==
    { ZeroConsolidatedInavMessage }
        \cup { [ZeroConsolidatedInavMessage EXCEPT !.numberOfTheTrac = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedInavMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedInavMessage EXCEPT !.currentTheoreticalPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Catalog For Instruments Belonging To The Local And Global Stock Market  *)
(* Message: 73 bytes                                                       *)
(***************************************************************************)

CatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage ==
    [ mseInstrumentNumber     : Sample(4),
      valueOfType             : Sample(2),
      issuingCompany          : Sample(7),
      series                  : Sample(6),
      lastPrice               : Sample(8),
      pppWeightedAveragePrice : Sample(8),
      referenceDate           : Sample(8),
      reference               : Sample(1),
      couponInEffect          : Sample(2),
      marketability           : Sample(1),
      numericalMarketability  : Sample(4),
      isin                    : Sample(12),
      market                  : Sample(1),
      registeredValues        : Sample(8),
      exchange                : Sample(1) ]

EncodeCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage(message) ==
    message.mseInstrumentNumber
        \o message.valueOfType
        \o message.issuingCompany
        \o message.series
        \o message.lastPrice
        \o message.pppWeightedAveragePrice
        \o message.referenceDate
        \o message.reference
        \o message.couponInEffect
        \o message.marketability
        \o message.numericalMarketability
        \o message.isin
        \o message.market
        \o message.registeredValues
        \o message.exchange

DecodeCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage(bytes) ==
    LET mseInstrumentNumber == ReadBytes(bytes, 4) IN IF ~mseInstrumentNumber.ok THEN Fail ELSE
    LET valueOfType == ReadBytes(mseInstrumentNumber.rest, 2) IN IF ~valueOfType.ok THEN Fail ELSE
    LET issuingCompany == ReadBytes(valueOfType.rest, 7) IN IF ~issuingCompany.ok THEN Fail ELSE
    LET series == ReadBytes(issuingCompany.rest, 6) IN IF ~series.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(series.rest, 8) IN IF ~lastPrice.ok THEN Fail ELSE
    LET pppWeightedAveragePrice == ReadBytes(lastPrice.rest, 8) IN IF ~pppWeightedAveragePrice.ok THEN Fail ELSE
    LET referenceDate == ReadBytes(pppWeightedAveragePrice.rest, 8) IN IF ~referenceDate.ok THEN Fail ELSE
    LET reference == ReadBytes(referenceDate.rest, 1) IN IF ~reference.ok THEN Fail ELSE
    LET couponInEffect == ReadBytes(reference.rest, 2) IN IF ~couponInEffect.ok THEN Fail ELSE
    LET marketability == ReadBytes(couponInEffect.rest, 1) IN IF ~marketability.ok THEN Fail ELSE
    LET numericalMarketability == ReadBytes(marketability.rest, 4) IN IF ~numericalMarketability.ok THEN Fail ELSE
    LET isin == ReadBytes(numericalMarketability.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET market == ReadBytes(isin.rest, 1) IN IF ~market.ok THEN Fail ELSE
    LET registeredValues == ReadBytes(market.rest, 8) IN IF ~registeredValues.ok THEN Fail ELSE
    LET exchange == ReadBytes(registeredValues.rest, 1) IN IF ~exchange.ok THEN Fail ELSE
    Ok([ mseInstrumentNumber     |-> mseInstrumentNumber.value,
         valueOfType             |-> valueOfType.value,
         issuingCompany          |-> issuingCompany.value,
         series                  |-> series.value,
         lastPrice               |-> lastPrice.value,
         pppWeightedAveragePrice |-> pppWeightedAveragePrice.value,
         referenceDate           |-> referenceDate.value,
         reference               |-> reference.value,
         couponInEffect          |-> couponInEffect.value,
         marketability           |-> marketability.value,
         numericalMarketability  |-> numericalMarketability.value,
         isin                    |-> isin.value,
         market                  |-> market.value,
         registeredValues        |-> registeredValues.value,
         exchange                |-> exchange.value ], exchange.rest)

ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage ==
    [ mseInstrumentNumber     |-> [i \in 1 .. 4 |-> 0],
      valueOfType             |-> [i \in 1 .. 2 |-> 0],
      issuingCompany          |-> [i \in 1 .. 7 |-> 0],
      series                  |-> [i \in 1 .. 6 |-> 0],
      lastPrice               |-> [i \in 1 .. 8 |-> 0],
      pppWeightedAveragePrice |-> [i \in 1 .. 8 |-> 0],
      referenceDate           |-> [i \in 1 .. 8 |-> 0],
      reference               |-> [i \in 1 .. 1 |-> 0],
      couponInEffect          |-> [i \in 1 .. 2 |-> 0],
      marketability           |-> [i \in 1 .. 1 |-> 0],
      numericalMarketability  |-> [i \in 1 .. 4 |-> 0],
      isin                    |-> [i \in 1 .. 12 |-> 0],
      market                  |-> [i \in 1 .. 1 |-> 0],
      registeredValues        |-> [i \in 1 .. 8 |-> 0],
      exchange                |-> [i \in 1 .. 1 |-> 0] ]

(* Catalog For Instruments Belonging To The Local And Global Stock Market Message at zero, then each field in turn at the values it is checked at *)
CheckedCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage ==
    { ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.mseInstrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.valueOfType = one] : one \in Sample(2) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.issuingCompany = one] : one \in Sample(7) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.series = one] : one \in Sample(6) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.lastPrice = one] : one \in Sample(8) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.pppWeightedAveragePrice = one] : one \in Sample(8) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.referenceDate = one] : one \in Sample(8) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.reference = one] : one \in Sample(1) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.couponInEffect = one] : one \in Sample(2) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.marketability = one] : one \in Sample(1) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.numericalMarketability = one] : one \in Sample(4) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.market = one] : one \in Sample(1) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.registeredValues = one] : one \in Sample(8) }
        \cup { [ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage EXCEPT !.exchange = one] : one \in Sample(1) }

(***************************************************************************)
(* Probable Price Of Allocation Message: 21 bytes                          *)
(***************************************************************************)

ProbablePriceOfAllocationMessage ==
    [ instrumentNumber          : Sample(4),
      origin                    : Sample(1),
      probablePriceOfAllocation : Sample(8),
      volumeInt648              : Sample(8) ]

EncodeProbablePriceOfAllocationMessage(message) ==
    message.instrumentNumber
        \o message.origin
        \o message.probablePriceOfAllocation
        \o message.volumeInt648

DecodeProbablePriceOfAllocationMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET origin == ReadBytes(instrumentNumber.rest, 1) IN IF ~origin.ok THEN Fail ELSE
    LET probablePriceOfAllocation == ReadBytes(origin.rest, 8) IN IF ~probablePriceOfAllocation.ok THEN Fail ELSE
    LET volumeInt648 == ReadBytes(probablePriceOfAllocation.rest, 8) IN IF ~volumeInt648.ok THEN Fail ELSE
    Ok([ instrumentNumber          |-> instrumentNumber.value,
         origin                    |-> origin.value,
         probablePriceOfAllocation |-> probablePriceOfAllocation.value,
         volumeInt648              |-> volumeInt648.value ], volumeInt648.rest)

ZeroProbablePriceOfAllocationMessage ==
    [ instrumentNumber          |-> [i \in 1 .. 4 |-> 0],
      origin                    |-> [i \in 1 .. 1 |-> 0],
      probablePriceOfAllocation |-> [i \in 1 .. 8 |-> 0],
      volumeInt648              |-> [i \in 1 .. 8 |-> 0] ]

(* Probable Price Of Allocation Message at zero, then each field in turn at the values it is checked at *)
CheckedProbablePriceOfAllocationMessage ==
    { ZeroProbablePriceOfAllocationMessage }
        \cup { [ZeroProbablePriceOfAllocationMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroProbablePriceOfAllocationMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroProbablePriceOfAllocationMessage EXCEPT !.probablePriceOfAllocation = one] : one \in Sample(8) }
        \cup { [ZeroProbablePriceOfAllocationMessage EXCEPT !.volumeInt648 = one] : one \in Sample(8) }

(***************************************************************************)
(* Relation Between Bmvbiva Instruments Message: 9 bytes                   *)
(***************************************************************************)

RelationBetweenBmvbivaInstrumentsMessage ==
    [ numberOfTheBmvInstrument : Sample(4),
      bivaInstrument           : Sample(4),
      typeOfTrading            : Sample(1) ]

EncodeRelationBetweenBmvbivaInstrumentsMessage(message) ==
    message.numberOfTheBmvInstrument
        \o message.bivaInstrument
        \o message.typeOfTrading

DecodeRelationBetweenBmvbivaInstrumentsMessage(bytes) ==
    LET numberOfTheBmvInstrument == ReadBytes(bytes, 4) IN IF ~numberOfTheBmvInstrument.ok THEN Fail ELSE
    LET bivaInstrument == ReadBytes(numberOfTheBmvInstrument.rest, 4) IN IF ~bivaInstrument.ok THEN Fail ELSE
    LET typeOfTrading == ReadBytes(bivaInstrument.rest, 1) IN IF ~typeOfTrading.ok THEN Fail ELSE
    Ok([ numberOfTheBmvInstrument |-> numberOfTheBmvInstrument.value,
         bivaInstrument           |-> bivaInstrument.value,
         typeOfTrading            |-> typeOfTrading.value ], typeOfTrading.rest)

ZeroRelationBetweenBmvbivaInstrumentsMessage ==
    [ numberOfTheBmvInstrument |-> [i \in 1 .. 4 |-> 0],
      bivaInstrument           |-> [i \in 1 .. 4 |-> 0],
      typeOfTrading            |-> [i \in 1 .. 1 |-> 0] ]

(* Relation Between Bmvbiva Instruments Message at zero, then each field in turn at the values it is checked at *)
CheckedRelationBetweenBmvbivaInstrumentsMessage ==
    { ZeroRelationBetweenBmvbivaInstrumentsMessage }
        \cup { [ZeroRelationBetweenBmvbivaInstrumentsMessage EXCEPT !.numberOfTheBmvInstrument = one] : one \in Sample(4) }
        \cup { [ZeroRelationBetweenBmvbivaInstrumentsMessage EXCEPT !.bivaInstrument = one] : one \in Sample(4) }
        \cup { [ZeroRelationBetweenBmvbivaInstrumentsMessage EXCEPT !.typeOfTrading = one] : one \in Sample(1) }

(***************************************************************************)
(* Equities Market Trades Message: 61 bytes                                *)
(***************************************************************************)

EquitiesMarketTradesMessage ==
    [ instrumentNumber            : Sample(4),
      origin                      : Sample(1),
      timeOfTheTrade              : Sample(8),
      volumeInt648                : Sample(8),
      price                       : Sample(8),
      typeOfAgreement             : Sample(1),
      consecutiveNumberOfTheTrade : Sample(8),
      setsPrice                   : Sample(1),
      typeOfTrading               : Sample(1),
      amount                      : Sample(8),
      purchases                   : Sample(5),
      sells                       : Sample(5),
      settlement                  : Sample(1),
      auctionIndicator            : Sample(1),
      indicator                   : Sample(1) ]

EncodeEquitiesMarketTradesMessage(message) ==
    message.instrumentNumber
        \o message.origin
        \o message.timeOfTheTrade
        \o message.volumeInt648
        \o message.price
        \o message.typeOfAgreement
        \o message.consecutiveNumberOfTheTrade
        \o message.setsPrice
        \o message.typeOfTrading
        \o message.amount
        \o message.purchases
        \o message.sells
        \o message.settlement
        \o message.auctionIndicator
        \o message.indicator

DecodeEquitiesMarketTradesMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET origin == ReadBytes(instrumentNumber.rest, 1) IN IF ~origin.ok THEN Fail ELSE
    LET timeOfTheTrade == ReadBytes(origin.rest, 8) IN IF ~timeOfTheTrade.ok THEN Fail ELSE
    LET volumeInt648 == ReadBytes(timeOfTheTrade.rest, 8) IN IF ~volumeInt648.ok THEN Fail ELSE
    LET price == ReadBytes(volumeInt648.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET typeOfAgreement == ReadBytes(price.rest, 1) IN IF ~typeOfAgreement.ok THEN Fail ELSE
    LET consecutiveNumberOfTheTrade == ReadBytes(typeOfAgreement.rest, 8) IN IF ~consecutiveNumberOfTheTrade.ok THEN Fail ELSE
    LET setsPrice == ReadBytes(consecutiveNumberOfTheTrade.rest, 1) IN IF ~setsPrice.ok THEN Fail ELSE
    LET typeOfTrading == ReadBytes(setsPrice.rest, 1) IN IF ~typeOfTrading.ok THEN Fail ELSE
    LET amount == ReadBytes(typeOfTrading.rest, 8) IN IF ~amount.ok THEN Fail ELSE
    LET purchases == ReadBytes(amount.rest, 5) IN IF ~purchases.ok THEN Fail ELSE
    LET sells == ReadBytes(purchases.rest, 5) IN IF ~sells.ok THEN Fail ELSE
    LET settlement == ReadBytes(sells.rest, 1) IN IF ~settlement.ok THEN Fail ELSE
    LET auctionIndicator == ReadBytes(settlement.rest, 1) IN IF ~auctionIndicator.ok THEN Fail ELSE
    LET indicator == ReadBytes(auctionIndicator.rest, 1) IN IF ~indicator.ok THEN Fail ELSE
    Ok([ instrumentNumber            |-> instrumentNumber.value,
         origin                      |-> origin.value,
         timeOfTheTrade              |-> timeOfTheTrade.value,
         volumeInt648                |-> volumeInt648.value,
         price                       |-> price.value,
         typeOfAgreement             |-> typeOfAgreement.value,
         consecutiveNumberOfTheTrade |-> consecutiveNumberOfTheTrade.value,
         setsPrice                   |-> setsPrice.value,
         typeOfTrading               |-> typeOfTrading.value,
         amount                      |-> amount.value,
         purchases                   |-> purchases.value,
         sells                       |-> sells.value,
         settlement                  |-> settlement.value,
         auctionIndicator            |-> auctionIndicator.value,
         indicator                   |-> indicator.value ], indicator.rest)

ZeroEquitiesMarketTradesMessage ==
    [ instrumentNumber            |-> [i \in 1 .. 4 |-> 0],
      origin                      |-> [i \in 1 .. 1 |-> 0],
      timeOfTheTrade              |-> [i \in 1 .. 8 |-> 0],
      volumeInt648                |-> [i \in 1 .. 8 |-> 0],
      price                       |-> [i \in 1 .. 8 |-> 0],
      typeOfAgreement             |-> [i \in 1 .. 1 |-> 0],
      consecutiveNumberOfTheTrade |-> [i \in 1 .. 8 |-> 0],
      setsPrice                   |-> [i \in 1 .. 1 |-> 0],
      typeOfTrading               |-> [i \in 1 .. 1 |-> 0],
      amount                      |-> [i \in 1 .. 8 |-> 0],
      purchases                   |-> [i \in 1 .. 5 |-> 0],
      sells                       |-> [i \in 1 .. 5 |-> 0],
      settlement                  |-> [i \in 1 .. 1 |-> 0],
      auctionIndicator            |-> [i \in 1 .. 1 |-> 0],
      indicator                   |-> [i \in 1 .. 1 |-> 0] ]

(* Equities Market Trades Message at zero, then each field in turn at the values it is checked at *)
CheckedEquitiesMarketTradesMessage ==
    { ZeroEquitiesMarketTradesMessage }
        \cup { [ZeroEquitiesMarketTradesMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroEquitiesMarketTradesMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesMarketTradesMessage EXCEPT !.timeOfTheTrade = one] : one \in Sample(8) }
        \cup { [ZeroEquitiesMarketTradesMessage EXCEPT !.volumeInt648 = one] : one \in Sample(8) }
        \cup { [ZeroEquitiesMarketTradesMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroEquitiesMarketTradesMessage EXCEPT !.typeOfAgreement = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesMarketTradesMessage EXCEPT !.consecutiveNumberOfTheTrade = one] : one \in Sample(8) }
        \cup { [ZeroEquitiesMarketTradesMessage EXCEPT !.setsPrice = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesMarketTradesMessage EXCEPT !.typeOfTrading = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesMarketTradesMessage EXCEPT !.amount = one] : one \in Sample(8) }
        \cup { [ZeroEquitiesMarketTradesMessage EXCEPT !.purchases = one] : one \in Sample(5) }
        \cup { [ZeroEquitiesMarketTradesMessage EXCEPT !.sells = one] : one \in Sample(5) }
        \cup { [ZeroEquitiesMarketTradesMessage EXCEPT !.settlement = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesMarketTradesMessage EXCEPT !.auctionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesMarketTradesMessage EXCEPT !.indicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Consolidated Trade Cancellation Message: 13 bytes                       *)
(***************************************************************************)

ConsolidatedTradeCancellationMessage ==
    [ instrumentNumber            : Sample(4),
      origin                      : Sample(1),
      consecutiveNumberOfTheTrade : Sample(8) ]

EncodeConsolidatedTradeCancellationMessage(message) ==
    message.instrumentNumber
        \o message.origin
        \o message.consecutiveNumberOfTheTrade

DecodeConsolidatedTradeCancellationMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET origin == ReadBytes(instrumentNumber.rest, 1) IN IF ~origin.ok THEN Fail ELSE
    LET consecutiveNumberOfTheTrade == ReadBytes(origin.rest, 8) IN IF ~consecutiveNumberOfTheTrade.ok THEN Fail ELSE
    Ok([ instrumentNumber            |-> instrumentNumber.value,
         origin                      |-> origin.value,
         consecutiveNumberOfTheTrade |-> consecutiveNumberOfTheTrade.value ], consecutiveNumberOfTheTrade.rest)

ZeroConsolidatedTradeCancellationMessage ==
    [ instrumentNumber            |-> [i \in 1 .. 4 |-> 0],
      origin                      |-> [i \in 1 .. 1 |-> 0],
      consecutiveNumberOfTheTrade |-> [i \in 1 .. 8 |-> 0] ]

(* Consolidated Trade Cancellation Message at zero, then each field in turn at the values it is checked at *)
CheckedConsolidatedTradeCancellationMessage ==
    { ZeroConsolidatedTradeCancellationMessage }
        \cup { [ZeroConsolidatedTradeCancellationMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedTradeCancellationMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedTradeCancellationMessage EXCEPT !.consecutiveNumberOfTheTrade = one] : one \in Sample(8) }

(***************************************************************************)
(* Pricevolume Indicator Message: 38 bytes                                 *)
(***************************************************************************)

PricevolumeIndicatorMessage ==
    [ instrumentNumber         : Sample(4),
      origin                   : Sample(1),
      probablePriceOfAllotment : Sample(8),
      volumeInt648             : Sample(8),
      bestSellingPrice         : Sample(8),
      bestPurchasingPrice      : Sample(8),
      typeOfCrossTrading       : Sample(1) ]

EncodePricevolumeIndicatorMessage(message) ==
    message.instrumentNumber
        \o message.origin
        \o message.probablePriceOfAllotment
        \o message.volumeInt648
        \o message.bestSellingPrice
        \o message.bestPurchasingPrice
        \o message.typeOfCrossTrading

DecodePricevolumeIndicatorMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET origin == ReadBytes(instrumentNumber.rest, 1) IN IF ~origin.ok THEN Fail ELSE
    LET probablePriceOfAllotment == ReadBytes(origin.rest, 8) IN IF ~probablePriceOfAllotment.ok THEN Fail ELSE
    LET volumeInt648 == ReadBytes(probablePriceOfAllotment.rest, 8) IN IF ~volumeInt648.ok THEN Fail ELSE
    LET bestSellingPrice == ReadBytes(volumeInt648.rest, 8) IN IF ~bestSellingPrice.ok THEN Fail ELSE
    LET bestPurchasingPrice == ReadBytes(bestSellingPrice.rest, 8) IN IF ~bestPurchasingPrice.ok THEN Fail ELSE
    LET typeOfCrossTrading == ReadBytes(bestPurchasingPrice.rest, 1) IN IF ~typeOfCrossTrading.ok THEN Fail ELSE
    Ok([ instrumentNumber         |-> instrumentNumber.value,
         origin                   |-> origin.value,
         probablePriceOfAllotment |-> probablePriceOfAllotment.value,
         volumeInt648             |-> volumeInt648.value,
         bestSellingPrice         |-> bestSellingPrice.value,
         bestPurchasingPrice      |-> bestPurchasingPrice.value,
         typeOfCrossTrading       |-> typeOfCrossTrading.value ], typeOfCrossTrading.rest)

ZeroPricevolumeIndicatorMessage ==
    [ instrumentNumber         |-> [i \in 1 .. 4 |-> 0],
      origin                   |-> [i \in 1 .. 1 |-> 0],
      probablePriceOfAllotment |-> [i \in 1 .. 8 |-> 0],
      volumeInt648             |-> [i \in 1 .. 8 |-> 0],
      bestSellingPrice         |-> [i \in 1 .. 8 |-> 0],
      bestPurchasingPrice      |-> [i \in 1 .. 8 |-> 0],
      typeOfCrossTrading       |-> [i \in 1 .. 1 |-> 0] ]

(* Pricevolume Indicator Message at zero, then each field in turn at the values it is checked at *)
CheckedPricevolumeIndicatorMessage ==
    { ZeroPricevolumeIndicatorMessage }
        \cup { [ZeroPricevolumeIndicatorMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroPricevolumeIndicatorMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroPricevolumeIndicatorMessage EXCEPT !.probablePriceOfAllotment = one] : one \in Sample(8) }
        \cup { [ZeroPricevolumeIndicatorMessage EXCEPT !.volumeInt648 = one] : one \in Sample(8) }
        \cup { [ZeroPricevolumeIndicatorMessage EXCEPT !.bestSellingPrice = one] : one \in Sample(8) }
        \cup { [ZeroPricevolumeIndicatorMessage EXCEPT !.bestPurchasingPrice = one] : one \in Sample(8) }
        \cup { [ZeroPricevolumeIndicatorMessage EXCEPT !.typeOfCrossTrading = one] : one \in Sample(1) }

(***************************************************************************)
(* Consolidated Execution Of Orders Message: 52 bytes                      *)
(***************************************************************************)

ConsolidatedExecutionOfOrdersMessage ==
    [ instrumentNumber            : Sample(4),
      origin                      : Sample(1),
      date                        : Sample(8),
      consecutiveNumber           : Sample(8),
      volumeInt648                : Sample(8),
      consecutiveNumberOfTheTrade : Sample(8),
      executionPrice              : Sample(8),
      indicator                   : Sample(1),
      setsPrice                   : Sample(1),
      participant                 : Sample(5) ]

EncodeConsolidatedExecutionOfOrdersMessage(message) ==
    message.instrumentNumber
        \o message.origin
        \o message.date
        \o message.consecutiveNumber
        \o message.volumeInt648
        \o message.consecutiveNumberOfTheTrade
        \o message.executionPrice
        \o message.indicator
        \o message.setsPrice
        \o message.participant

DecodeConsolidatedExecutionOfOrdersMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET origin == ReadBytes(instrumentNumber.rest, 1) IN IF ~origin.ok THEN Fail ELSE
    LET date == ReadBytes(origin.rest, 8) IN IF ~date.ok THEN Fail ELSE
    LET consecutiveNumber == ReadBytes(date.rest, 8) IN IF ~consecutiveNumber.ok THEN Fail ELSE
    LET volumeInt648 == ReadBytes(consecutiveNumber.rest, 8) IN IF ~volumeInt648.ok THEN Fail ELSE
    LET consecutiveNumberOfTheTrade == ReadBytes(volumeInt648.rest, 8) IN IF ~consecutiveNumberOfTheTrade.ok THEN Fail ELSE
    LET executionPrice == ReadBytes(consecutiveNumberOfTheTrade.rest, 8) IN IF ~executionPrice.ok THEN Fail ELSE
    LET indicator == ReadBytes(executionPrice.rest, 1) IN IF ~indicator.ok THEN Fail ELSE
    LET setsPrice == ReadBytes(indicator.rest, 1) IN IF ~setsPrice.ok THEN Fail ELSE
    LET participant == ReadBytes(setsPrice.rest, 5) IN IF ~participant.ok THEN Fail ELSE
    Ok([ instrumentNumber            |-> instrumentNumber.value,
         origin                      |-> origin.value,
         date                        |-> date.value,
         consecutiveNumber           |-> consecutiveNumber.value,
         volumeInt648                |-> volumeInt648.value,
         consecutiveNumberOfTheTrade |-> consecutiveNumberOfTheTrade.value,
         executionPrice              |-> executionPrice.value,
         indicator                   |-> indicator.value,
         setsPrice                   |-> setsPrice.value,
         participant                 |-> participant.value ], participant.rest)

ZeroConsolidatedExecutionOfOrdersMessage ==
    [ instrumentNumber            |-> [i \in 1 .. 4 |-> 0],
      origin                      |-> [i \in 1 .. 1 |-> 0],
      date                        |-> [i \in 1 .. 8 |-> 0],
      consecutiveNumber           |-> [i \in 1 .. 8 |-> 0],
      volumeInt648                |-> [i \in 1 .. 8 |-> 0],
      consecutiveNumberOfTheTrade |-> [i \in 1 .. 8 |-> 0],
      executionPrice              |-> [i \in 1 .. 8 |-> 0],
      indicator                   |-> [i \in 1 .. 1 |-> 0],
      setsPrice                   |-> [i \in 1 .. 1 |-> 0],
      participant                 |-> [i \in 1 .. 5 |-> 0] ]

(* Consolidated Execution Of Orders Message at zero, then each field in turn at the values it is checked at *)
CheckedConsolidatedExecutionOfOrdersMessage ==
    { ZeroConsolidatedExecutionOfOrdersMessage }
        \cup { [ZeroConsolidatedExecutionOfOrdersMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedExecutionOfOrdersMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedExecutionOfOrdersMessage EXCEPT !.date = one] : one \in Sample(8) }
        \cup { [ZeroConsolidatedExecutionOfOrdersMessage EXCEPT !.consecutiveNumber = one] : one \in Sample(8) }
        \cup { [ZeroConsolidatedExecutionOfOrdersMessage EXCEPT !.volumeInt648 = one] : one \in Sample(8) }
        \cup { [ZeroConsolidatedExecutionOfOrdersMessage EXCEPT !.consecutiveNumberOfTheTrade = one] : one \in Sample(8) }
        \cup { [ZeroConsolidatedExecutionOfOrdersMessage EXCEPT !.executionPrice = one] : one \in Sample(8) }
        \cup { [ZeroConsolidatedExecutionOfOrdersMessage EXCEPT !.indicator = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedExecutionOfOrdersMessage EXCEPT !.setsPrice = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedExecutionOfOrdersMessage EXCEPT !.participant = one] : one \in Sample(5) }

(***************************************************************************)
(* Registration Of Order Message: 43 bytes                                 *)
(***************************************************************************)

RegistrationOfOrderMessage ==
    [ instrumentNumber  : Sample(4),
      origin            : Sample(1),
      dateAndTime       : Sample(8),
      consecutiveNumber : Sample(8),
      direction         : Sample(1),
      volumeInt648      : Sample(8),
      price             : Sample(8),
      participant       : Sample(5) ]

EncodeRegistrationOfOrderMessage(message) ==
    message.instrumentNumber
        \o message.origin
        \o message.dateAndTime
        \o message.consecutiveNumber
        \o message.direction
        \o message.volumeInt648
        \o message.price
        \o message.participant

DecodeRegistrationOfOrderMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET origin == ReadBytes(instrumentNumber.rest, 1) IN IF ~origin.ok THEN Fail ELSE
    LET dateAndTime == ReadBytes(origin.rest, 8) IN IF ~dateAndTime.ok THEN Fail ELSE
    LET consecutiveNumber == ReadBytes(dateAndTime.rest, 8) IN IF ~consecutiveNumber.ok THEN Fail ELSE
    LET direction == ReadBytes(consecutiveNumber.rest, 1) IN IF ~direction.ok THEN Fail ELSE
    LET volumeInt648 == ReadBytes(direction.rest, 8) IN IF ~volumeInt648.ok THEN Fail ELSE
    LET price == ReadBytes(volumeInt648.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET participant == ReadBytes(price.rest, 5) IN IF ~participant.ok THEN Fail ELSE
    Ok([ instrumentNumber  |-> instrumentNumber.value,
         origin            |-> origin.value,
         dateAndTime       |-> dateAndTime.value,
         consecutiveNumber |-> consecutiveNumber.value,
         direction         |-> direction.value,
         volumeInt648      |-> volumeInt648.value,
         price             |-> price.value,
         participant       |-> participant.value ], participant.rest)

ZeroRegistrationOfOrderMessage ==
    [ instrumentNumber  |-> [i \in 1 .. 4 |-> 0],
      origin            |-> [i \in 1 .. 1 |-> 0],
      dateAndTime       |-> [i \in 1 .. 8 |-> 0],
      consecutiveNumber |-> [i \in 1 .. 8 |-> 0],
      direction         |-> [i \in 1 .. 1 |-> 0],
      volumeInt648      |-> [i \in 1 .. 8 |-> 0],
      price             |-> [i \in 1 .. 8 |-> 0],
      participant       |-> [i \in 1 .. 5 |-> 0] ]

(* Registration Of Order Message at zero, then each field in turn at the values it is checked at *)
CheckedRegistrationOfOrderMessage ==
    { ZeroRegistrationOfOrderMessage }
        \cup { [ZeroRegistrationOfOrderMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroRegistrationOfOrderMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroRegistrationOfOrderMessage EXCEPT !.dateAndTime = one] : one \in Sample(8) }
        \cup { [ZeroRegistrationOfOrderMessage EXCEPT !.consecutiveNumber = one] : one \in Sample(8) }
        \cup { [ZeroRegistrationOfOrderMessage EXCEPT !.direction = one] : one \in Sample(1) }
        \cup { [ZeroRegistrationOfOrderMessage EXCEPT !.volumeInt648 = one] : one \in Sample(8) }
        \cup { [ZeroRegistrationOfOrderMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroRegistrationOfOrderMessage EXCEPT !.participant = one] : one \in Sample(5) }

(***************************************************************************)
(* Cancellations Of Orders Message: 21 bytes                               *)
(***************************************************************************)

CancellationsOfOrdersMessage ==
    [ instrumentNumber  : Sample(4),
      origin            : Sample(1),
      date              : Sample(8),
      consecutiveNumber : Sample(8) ]

EncodeCancellationsOfOrdersMessage(message) ==
    message.instrumentNumber
        \o message.origin
        \o message.date
        \o message.consecutiveNumber

DecodeCancellationsOfOrdersMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET origin == ReadBytes(instrumentNumber.rest, 1) IN IF ~origin.ok THEN Fail ELSE
    LET date == ReadBytes(origin.rest, 8) IN IF ~date.ok THEN Fail ELSE
    LET consecutiveNumber == ReadBytes(date.rest, 8) IN IF ~consecutiveNumber.ok THEN Fail ELSE
    Ok([ instrumentNumber  |-> instrumentNumber.value,
         origin            |-> origin.value,
         date              |-> date.value,
         consecutiveNumber |-> consecutiveNumber.value ], consecutiveNumber.rest)

ZeroCancellationsOfOrdersMessage ==
    [ instrumentNumber  |-> [i \in 1 .. 4 |-> 0],
      origin            |-> [i \in 1 .. 1 |-> 0],
      date              |-> [i \in 1 .. 8 |-> 0],
      consecutiveNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Cancellations Of Orders Message at zero, then each field in turn at the values it is checked at *)
CheckedCancellationsOfOrdersMessage ==
    { ZeroCancellationsOfOrdersMessage }
        \cup { [ZeroCancellationsOfOrdersMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroCancellationsOfOrdersMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroCancellationsOfOrdersMessage EXCEPT !.date = one] : one \in Sample(8) }
        \cup { [ZeroCancellationsOfOrdersMessage EXCEPT !.consecutiveNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Last Quote Message: 23 bytes                                            *)
(***************************************************************************)

LastQuoteMessage ==
    [ instrumentNumber  : Sample(4),
      origin            : Sample(1),
      volumeInt648      : Sample(8),
      priceRate         : Sample(8),
      directionOfTheBid : Sample(1),
      typeOfTrading     : Sample(1) ]

EncodeLastQuoteMessage(message) ==
    message.instrumentNumber
        \o message.origin
        \o message.volumeInt648
        \o message.priceRate
        \o message.directionOfTheBid
        \o message.typeOfTrading

DecodeLastQuoteMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET origin == ReadBytes(instrumentNumber.rest, 1) IN IF ~origin.ok THEN Fail ELSE
    LET volumeInt648 == ReadBytes(origin.rest, 8) IN IF ~volumeInt648.ok THEN Fail ELSE
    LET priceRate == ReadBytes(volumeInt648.rest, 8) IN IF ~priceRate.ok THEN Fail ELSE
    LET directionOfTheBid == ReadBytes(priceRate.rest, 1) IN IF ~directionOfTheBid.ok THEN Fail ELSE
    LET typeOfTrading == ReadBytes(directionOfTheBid.rest, 1) IN IF ~typeOfTrading.ok THEN Fail ELSE
    Ok([ instrumentNumber  |-> instrumentNumber.value,
         origin            |-> origin.value,
         volumeInt648      |-> volumeInt648.value,
         priceRate         |-> priceRate.value,
         directionOfTheBid |-> directionOfTheBid.value,
         typeOfTrading     |-> typeOfTrading.value ], typeOfTrading.rest)

ZeroLastQuoteMessage ==
    [ instrumentNumber  |-> [i \in 1 .. 4 |-> 0],
      origin            |-> [i \in 1 .. 1 |-> 0],
      volumeInt648      |-> [i \in 1 .. 8 |-> 0],
      priceRate         |-> [i \in 1 .. 8 |-> 0],
      directionOfTheBid |-> [i \in 1 .. 1 |-> 0],
      typeOfTrading     |-> [i \in 1 .. 1 |-> 0] ]

(* Last Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedLastQuoteMessage ==
    { ZeroLastQuoteMessage }
        \cup { [ZeroLastQuoteMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroLastQuoteMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroLastQuoteMessage EXCEPT !.volumeInt648 = one] : one \in Sample(8) }
        \cup { [ZeroLastQuoteMessage EXCEPT !.priceRate = one] : one \in Sample(8) }
        \cup { [ZeroLastQuoteMessage EXCEPT !.directionOfTheBid = one] : one \in Sample(1) }
        \cup { [ZeroLastQuoteMessage EXCEPT !.typeOfTrading = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

LoginResponseMessageCode == 38  \* 0x26
ReplayResponseMessageCode == 42  \* 0x2a
SnapshotResponseMessageCode == 43  \* 0x2b
SnapshotCompleteMessageCode == 63  \* 0x3f
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
DepthMessageCode == 49  \* 0x31
BestOfferMessageCode == 79  \* 0x4f
PublicOfferingsMessageCode == 66  \* 0x42
OpenInterestMessageCode == 73  \* 0x49
DerivativesMarketTradesMessageCode == 81  \* 0x51
StatisticsOfInstrumentsMessageCode == 82  \* 0x52
GeneralIndicesMessageCode == 85  \* 0x55
IndicesComponentsMessageCode == 87  \* 0x57
InavMessageCode == 71  \* 0x47
DollarBuySellMessageCode == 114  \* 0x72
ShortSalesBalancesPerInstrumentMessageCode == 115  \* 0x73
CapitalMarketMultiplesMessageCode == 116  \* 0x74
BenchmarkMessageCode == 120  \* 0x78
CapitalizationRulesMessageCode == 122  \* 0x7a
ClosingPriceOriginMessageCode == 126  \* 0x7e
MutualFundsTradesMessageCode == 40  \* 0x28
OpeningOfContinuousAuctionsMessageCode == 41  \* 0x29
ExistenceOfBidsAtMidPriceMessageCode == 44  \* 0x2c
CatalogueOfDebtAndMetalsInstrumentsMessageCode == 46  \* 0x2e
CatalogSentForInstrumentsBelongingToMutualFundsMessageCode == 48  \* 0x30
WeightedAveragePriceMessageCode == 54  \* 0x36
SystemEventsMessageCode == 55  \* 0x37
ReferencePriceMessageCode == 56  \* 0x38
ChangesInStatusMessageCode == 57  \* 0x39
CatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessageCode == 84  \* 0x54
CatalogSentForInstrumentsBelongingToCapitalTracsMessageCode == 91  \* 0x5b
ConsolidatedInavMessageCode == 93  \* 0x5d
CatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessageCode == 104  \* 0x68
ProbablePriceOfAllocationMessageCode == 105  \* 0x69
RelationBetweenBmvbivaInstrumentsMessageCode == 106  \* 0x6a
EquitiesMarketTradesMessageCode == 112  \* 0x70
ConsolidatedTradeCancellationMessageCode == 113  \* 0x71
PricevolumeIndicatorMessageCode == 92  \* 0x5c
ConsolidatedExecutionOfOrdersMessageCode == 107  \* 0x6b
RegistrationOfOrderMessageCode == 110  \* 0x6e
CancellationsOfOrdersMessageCode == 117  \* 0x75
LastQuoteMessageCode == 109  \* 0x6d

Payload ==
    [ tag : {LoginResponseMessageCode}, body : LoginResponseMessage ]
        \cup [ tag : {ReplayResponseMessageCode}, body : ReplayResponseMessage ]
        \cup [ tag : {SnapshotResponseMessageCode}, body : SnapshotResponseMessage ]
        \cup [ tag : {SnapshotCompleteMessageCode}, body : SnapshotCompleteMessage ]
        \cup [ tag : {EventsSystemMessageCode}, body : EventsSystemMessage ]
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
        \cup [ tag : {DepthMessageCode}, body : DepthMessage ]
        \cup [ tag : {BestOfferMessageCode}, body : BestOfferMessage ]
        \cup [ tag : {PublicOfferingsMessageCode}, body : PublicOfferingsMessage ]
        \cup [ tag : {OpenInterestMessageCode}, body : OpenInterestMessage ]
        \cup [ tag : {DerivativesMarketTradesMessageCode}, body : DerivativesMarketTradesMessage ]
        \cup [ tag : {StatisticsOfInstrumentsMessageCode}, body : StatisticsOfInstrumentsMessage ]
        \cup [ tag : {GeneralIndicesMessageCode}, body : GeneralIndicesMessage ]
        \cup [ tag : {IndicesComponentsMessageCode}, body : IndicesComponentsMessage ]
        \cup [ tag : {InavMessageCode}, body : InavMessage ]
        \cup [ tag : {DollarBuySellMessageCode}, body : DollarBuySellMessage ]
        \cup [ tag : {ShortSalesBalancesPerInstrumentMessageCode}, body : ShortSalesBalancesPerInstrumentMessage ]
        \cup [ tag : {CapitalMarketMultiplesMessageCode}, body : CapitalMarketMultiplesMessage ]
        \cup [ tag : {BenchmarkMessageCode}, body : BenchmarkMessage ]
        \cup [ tag : {CapitalizationRulesMessageCode}, body : CapitalizationRulesMessage ]
        \cup [ tag : {ClosingPriceOriginMessageCode}, body : ClosingPriceOriginMessage ]
        \cup [ tag : {MutualFundsTradesMessageCode}, body : MutualFundsTradesMessage ]
        \cup [ tag : {OpeningOfContinuousAuctionsMessageCode}, body : OpeningOfContinuousAuctionsMessage ]
        \cup [ tag : {ExistenceOfBidsAtMidPriceMessageCode}, body : ExistenceOfBidsAtMidPriceMessage ]
        \cup [ tag : {CatalogueOfDebtAndMetalsInstrumentsMessageCode}, body : CatalogueOfDebtAndMetalsInstrumentsMessage ]
        \cup [ tag : {CatalogSentForInstrumentsBelongingToMutualFundsMessageCode}, body : CatalogSentForInstrumentsBelongingToMutualFundsMessage ]
        \cup [ tag : {WeightedAveragePriceMessageCode}, body : WeightedAveragePriceMessage ]
        \cup [ tag : {SystemEventsMessageCode}, body : SystemEventsMessage ]
        \cup [ tag : {ReferencePriceMessageCode}, body : ReferencePriceMessage ]
        \cup [ tag : {ChangesInStatusMessageCode}, body : ChangesInStatusMessage ]
        \cup [ tag : {CatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessageCode}, body : CatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage ]
        \cup [ tag : {CatalogSentForInstrumentsBelongingToCapitalTracsMessageCode}, body : CatalogSentForInstrumentsBelongingToCapitalTracsMessage ]
        \cup [ tag : {ConsolidatedInavMessageCode}, body : ConsolidatedInavMessage ]
        \cup [ tag : {CatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessageCode}, body : CatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage ]
        \cup [ tag : {ProbablePriceOfAllocationMessageCode}, body : ProbablePriceOfAllocationMessage ]
        \cup [ tag : {RelationBetweenBmvbivaInstrumentsMessageCode}, body : RelationBetweenBmvbivaInstrumentsMessage ]
        \cup [ tag : {EquitiesMarketTradesMessageCode}, body : EquitiesMarketTradesMessage ]
        \cup [ tag : {ConsolidatedTradeCancellationMessageCode}, body : ConsolidatedTradeCancellationMessage ]
        \cup [ tag : {PricevolumeIndicatorMessageCode}, body : PricevolumeIndicatorMessage ]
        \cup [ tag : {ConsolidatedExecutionOfOrdersMessageCode}, body : ConsolidatedExecutionOfOrdersMessage ]
        \cup [ tag : {RegistrationOfOrderMessageCode}, body : RegistrationOfOrderMessage ]
        \cup [ tag : {CancellationsOfOrdersMessageCode}, body : CancellationsOfOrdersMessage ]
        \cup [ tag : {LastQuoteMessageCode}, body : LastQuoteMessage ]

EncodePayload(message) ==
    CASE message.tag = LoginResponseMessageCode -> EncodeLoginResponseMessage(message.body)
      [] message.tag = ReplayResponseMessageCode -> EncodeReplayResponseMessage(message.body)
      [] message.tag = SnapshotResponseMessageCode -> EncodeSnapshotResponseMessage(message.body)
      [] message.tag = SnapshotCompleteMessageCode -> EncodeSnapshotCompleteMessage(message.body)
      [] message.tag = EventsSystemMessageCode -> EncodeEventsSystemMessage(message.body)
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
      [] message.tag = DepthMessageCode -> EncodeDepthMessage(message.body)
      [] message.tag = BestOfferMessageCode -> EncodeBestOfferMessage(message.body)
      [] message.tag = PublicOfferingsMessageCode -> EncodePublicOfferingsMessage(message.body)
      [] message.tag = OpenInterestMessageCode -> EncodeOpenInterestMessage(message.body)
      [] message.tag = DerivativesMarketTradesMessageCode -> EncodeDerivativesMarketTradesMessage(message.body)
      [] message.tag = StatisticsOfInstrumentsMessageCode -> EncodeStatisticsOfInstrumentsMessage(message.body)
      [] message.tag = GeneralIndicesMessageCode -> EncodeGeneralIndicesMessage(message.body)
      [] message.tag = IndicesComponentsMessageCode -> EncodeIndicesComponentsMessage(message.body)
      [] message.tag = InavMessageCode -> EncodeInavMessage(message.body)
      [] message.tag = DollarBuySellMessageCode -> EncodeDollarBuySellMessage(message.body)
      [] message.tag = ShortSalesBalancesPerInstrumentMessageCode -> EncodeShortSalesBalancesPerInstrumentMessage(message.body)
      [] message.tag = CapitalMarketMultiplesMessageCode -> EncodeCapitalMarketMultiplesMessage(message.body)
      [] message.tag = BenchmarkMessageCode -> EncodeBenchmarkMessage(message.body)
      [] message.tag = CapitalizationRulesMessageCode -> EncodeCapitalizationRulesMessage(message.body)
      [] message.tag = ClosingPriceOriginMessageCode -> EncodeClosingPriceOriginMessage(message.body)
      [] message.tag = MutualFundsTradesMessageCode -> EncodeMutualFundsTradesMessage(message.body)
      [] message.tag = OpeningOfContinuousAuctionsMessageCode -> EncodeOpeningOfContinuousAuctionsMessage(message.body)
      [] message.tag = ExistenceOfBidsAtMidPriceMessageCode -> EncodeExistenceOfBidsAtMidPriceMessage(message.body)
      [] message.tag = CatalogueOfDebtAndMetalsInstrumentsMessageCode -> EncodeCatalogueOfDebtAndMetalsInstrumentsMessage(message.body)
      [] message.tag = CatalogSentForInstrumentsBelongingToMutualFundsMessageCode -> EncodeCatalogSentForInstrumentsBelongingToMutualFundsMessage(message.body)
      [] message.tag = WeightedAveragePriceMessageCode -> EncodeWeightedAveragePriceMessage(message.body)
      [] message.tag = SystemEventsMessageCode -> EncodeSystemEventsMessage(message.body)
      [] message.tag = ReferencePriceMessageCode -> EncodeReferencePriceMessage(message.body)
      [] message.tag = ChangesInStatusMessageCode -> EncodeChangesInStatusMessage(message.body)
      [] message.tag = CatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessageCode -> EncodeCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage(message.body)
      [] message.tag = CatalogSentForInstrumentsBelongingToCapitalTracsMessageCode -> EncodeCatalogSentForInstrumentsBelongingToCapitalTracsMessage(message.body)
      [] message.tag = ConsolidatedInavMessageCode -> EncodeConsolidatedInavMessage(message.body)
      [] message.tag = CatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessageCode -> EncodeCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage(message.body)
      [] message.tag = ProbablePriceOfAllocationMessageCode -> EncodeProbablePriceOfAllocationMessage(message.body)
      [] message.tag = RelationBetweenBmvbivaInstrumentsMessageCode -> EncodeRelationBetweenBmvbivaInstrumentsMessage(message.body)
      [] message.tag = EquitiesMarketTradesMessageCode -> EncodeEquitiesMarketTradesMessage(message.body)
      [] message.tag = ConsolidatedTradeCancellationMessageCode -> EncodeConsolidatedTradeCancellationMessage(message.body)
      [] message.tag = PricevolumeIndicatorMessageCode -> EncodePricevolumeIndicatorMessage(message.body)
      [] message.tag = ConsolidatedExecutionOfOrdersMessageCode -> EncodeConsolidatedExecutionOfOrdersMessage(message.body)
      [] message.tag = RegistrationOfOrderMessageCode -> EncodeRegistrationOfOrderMessage(message.body)
      [] message.tag = CancellationsOfOrdersMessageCode -> EncodeCancellationsOfOrdersMessage(message.body)
      [] message.tag = LastQuoteMessageCode -> EncodeLastQuoteMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = LoginResponseMessageCode -> DecodeLoginResponseMessage(bytes)
              [] tag = ReplayResponseMessageCode -> DecodeReplayResponseMessage(bytes)
              [] tag = SnapshotResponseMessageCode -> DecodeSnapshotResponseMessage(bytes)
              [] tag = SnapshotCompleteMessageCode -> DecodeSnapshotCompleteMessage(bytes)
              [] tag = EventsSystemMessageCode -> DecodeEventsSystemMessage(bytes)
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
              [] tag = DepthMessageCode -> DecodeDepthMessage(bytes)
              [] tag = BestOfferMessageCode -> DecodeBestOfferMessage(bytes)
              [] tag = PublicOfferingsMessageCode -> DecodePublicOfferingsMessage(bytes)
              [] tag = OpenInterestMessageCode -> DecodeOpenInterestMessage(bytes)
              [] tag = DerivativesMarketTradesMessageCode -> DecodeDerivativesMarketTradesMessage(bytes)
              [] tag = StatisticsOfInstrumentsMessageCode -> DecodeStatisticsOfInstrumentsMessage(bytes)
              [] tag = GeneralIndicesMessageCode -> DecodeGeneralIndicesMessage(bytes)
              [] tag = IndicesComponentsMessageCode -> DecodeIndicesComponentsMessage(bytes)
              [] tag = InavMessageCode -> DecodeInavMessage(bytes)
              [] tag = DollarBuySellMessageCode -> DecodeDollarBuySellMessage(bytes)
              [] tag = ShortSalesBalancesPerInstrumentMessageCode -> DecodeShortSalesBalancesPerInstrumentMessage(bytes)
              [] tag = CapitalMarketMultiplesMessageCode -> DecodeCapitalMarketMultiplesMessage(bytes)
              [] tag = BenchmarkMessageCode -> DecodeBenchmarkMessage(bytes)
              [] tag = CapitalizationRulesMessageCode -> DecodeCapitalizationRulesMessage(bytes)
              [] tag = ClosingPriceOriginMessageCode -> DecodeClosingPriceOriginMessage(bytes)
              [] tag = MutualFundsTradesMessageCode -> DecodeMutualFundsTradesMessage(bytes)
              [] tag = OpeningOfContinuousAuctionsMessageCode -> DecodeOpeningOfContinuousAuctionsMessage(bytes)
              [] tag = ExistenceOfBidsAtMidPriceMessageCode -> DecodeExistenceOfBidsAtMidPriceMessage(bytes)
              [] tag = CatalogueOfDebtAndMetalsInstrumentsMessageCode -> DecodeCatalogueOfDebtAndMetalsInstrumentsMessage(bytes)
              [] tag = CatalogSentForInstrumentsBelongingToMutualFundsMessageCode -> DecodeCatalogSentForInstrumentsBelongingToMutualFundsMessage(bytes)
              [] tag = WeightedAveragePriceMessageCode -> DecodeWeightedAveragePriceMessage(bytes)
              [] tag = SystemEventsMessageCode -> DecodeSystemEventsMessage(bytes)
              [] tag = ReferencePriceMessageCode -> DecodeReferencePriceMessage(bytes)
              [] tag = ChangesInStatusMessageCode -> DecodeChangesInStatusMessage(bytes)
              [] tag = CatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessageCode -> DecodeCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage(bytes)
              [] tag = CatalogSentForInstrumentsBelongingToCapitalTracsMessageCode -> DecodeCatalogSentForInstrumentsBelongingToCapitalTracsMessage(bytes)
              [] tag = ConsolidatedInavMessageCode -> DecodeConsolidatedInavMessage(bytes)
              [] tag = CatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessageCode -> DecodeCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage(bytes)
              [] tag = ProbablePriceOfAllocationMessageCode -> DecodeProbablePriceOfAllocationMessage(bytes)
              [] tag = RelationBetweenBmvbivaInstrumentsMessageCode -> DecodeRelationBetweenBmvbivaInstrumentsMessage(bytes)
              [] tag = EquitiesMarketTradesMessageCode -> DecodeEquitiesMarketTradesMessage(bytes)
              [] tag = ConsolidatedTradeCancellationMessageCode -> DecodeConsolidatedTradeCancellationMessage(bytes)
              [] tag = PricevolumeIndicatorMessageCode -> DecodePricevolumeIndicatorMessage(bytes)
              [] tag = ConsolidatedExecutionOfOrdersMessageCode -> DecodeConsolidatedExecutionOfOrdersMessage(bytes)
              [] tag = RegistrationOfOrderMessageCode -> DecodeRegistrationOfOrderMessage(bytes)
              [] tag = CancellationsOfOrdersMessageCode -> DecodeCancellationsOfOrdersMessage(bytes)
              [] tag = LastQuoteMessageCode -> DecodeLastQuoteMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> LoginResponseMessageCode, body |-> ZeroLoginResponseMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> LoginResponseMessageCode, body |-> one] : one \in CheckedLoginResponseMessage }
        \cup { [tag |-> ReplayResponseMessageCode, body |-> one] : one \in CheckedReplayResponseMessage }
        \cup { [tag |-> SnapshotResponseMessageCode, body |-> one] : one \in CheckedSnapshotResponseMessage }
        \cup { [tag |-> SnapshotCompleteMessageCode, body |-> one] : one \in CheckedSnapshotCompleteMessage }
        \cup { [tag |-> EventsSystemMessageCode, body |-> one] : one \in CheckedEventsSystemMessage }
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
        \cup { [tag |-> DepthMessageCode, body |-> one] : one \in CheckedDepthMessage }
        \cup { [tag |-> BestOfferMessageCode, body |-> one] : one \in CheckedBestOfferMessage }
        \cup { [tag |-> PublicOfferingsMessageCode, body |-> one] : one \in CheckedPublicOfferingsMessage }
        \cup { [tag |-> OpenInterestMessageCode, body |-> one] : one \in CheckedOpenInterestMessage }
        \cup { [tag |-> DerivativesMarketTradesMessageCode, body |-> one] : one \in CheckedDerivativesMarketTradesMessage }
        \cup { [tag |-> StatisticsOfInstrumentsMessageCode, body |-> one] : one \in CheckedStatisticsOfInstrumentsMessage }
        \cup { [tag |-> GeneralIndicesMessageCode, body |-> one] : one \in CheckedGeneralIndicesMessage }
        \cup { [tag |-> IndicesComponentsMessageCode, body |-> one] : one \in CheckedIndicesComponentsMessage }
        \cup { [tag |-> InavMessageCode, body |-> one] : one \in CheckedInavMessage }
        \cup { [tag |-> DollarBuySellMessageCode, body |-> one] : one \in CheckedDollarBuySellMessage }
        \cup { [tag |-> ShortSalesBalancesPerInstrumentMessageCode, body |-> one] : one \in CheckedShortSalesBalancesPerInstrumentMessage }
        \cup { [tag |-> CapitalMarketMultiplesMessageCode, body |-> one] : one \in CheckedCapitalMarketMultiplesMessage }
        \cup { [tag |-> BenchmarkMessageCode, body |-> one] : one \in CheckedBenchmarkMessage }
        \cup { [tag |-> CapitalizationRulesMessageCode, body |-> one] : one \in CheckedCapitalizationRulesMessage }
        \cup { [tag |-> ClosingPriceOriginMessageCode, body |-> one] : one \in CheckedClosingPriceOriginMessage }
        \cup { [tag |-> MutualFundsTradesMessageCode, body |-> one] : one \in CheckedMutualFundsTradesMessage }
        \cup { [tag |-> OpeningOfContinuousAuctionsMessageCode, body |-> one] : one \in CheckedOpeningOfContinuousAuctionsMessage }
        \cup { [tag |-> ExistenceOfBidsAtMidPriceMessageCode, body |-> one] : one \in CheckedExistenceOfBidsAtMidPriceMessage }
        \cup { [tag |-> CatalogueOfDebtAndMetalsInstrumentsMessageCode, body |-> one] : one \in CheckedCatalogueOfDebtAndMetalsInstrumentsMessage }
        \cup { [tag |-> CatalogSentForInstrumentsBelongingToMutualFundsMessageCode, body |-> one] : one \in CheckedCatalogSentForInstrumentsBelongingToMutualFundsMessage }
        \cup { [tag |-> WeightedAveragePriceMessageCode, body |-> one] : one \in CheckedWeightedAveragePriceMessage }
        \cup { [tag |-> SystemEventsMessageCode, body |-> one] : one \in CheckedSystemEventsMessage }
        \cup { [tag |-> ReferencePriceMessageCode, body |-> one] : one \in CheckedReferencePriceMessage }
        \cup { [tag |-> ChangesInStatusMessageCode, body |-> one] : one \in CheckedChangesInStatusMessage }
        \cup { [tag |-> CatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessageCode, body |-> one] : one \in CheckedCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage }
        \cup { [tag |-> CatalogSentForInstrumentsBelongingToCapitalTracsMessageCode, body |-> one] : one \in CheckedCatalogSentForInstrumentsBelongingToCapitalTracsMessage }
        \cup { [tag |-> ConsolidatedInavMessageCode, body |-> one] : one \in CheckedConsolidatedInavMessage }
        \cup { [tag |-> CatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessageCode, body |-> one] : one \in CheckedCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage }
        \cup { [tag |-> ProbablePriceOfAllocationMessageCode, body |-> one] : one \in CheckedProbablePriceOfAllocationMessage }
        \cup { [tag |-> RelationBetweenBmvbivaInstrumentsMessageCode, body |-> one] : one \in CheckedRelationBetweenBmvbivaInstrumentsMessage }
        \cup { [tag |-> EquitiesMarketTradesMessageCode, body |-> one] : one \in CheckedEquitiesMarketTradesMessage }
        \cup { [tag |-> ConsolidatedTradeCancellationMessageCode, body |-> one] : one \in CheckedConsolidatedTradeCancellationMessage }
        \cup { [tag |-> PricevolumeIndicatorMessageCode, body |-> one] : one \in CheckedPricevolumeIndicatorMessage }
        \cup { [tag |-> ConsolidatedExecutionOfOrdersMessageCode, body |-> one] : one \in CheckedConsolidatedExecutionOfOrdersMessage }
        \cup { [tag |-> RegistrationOfOrderMessageCode, body |-> one] : one \in CheckedRegistrationOfOrderMessage }
        \cup { [tag |-> CancellationsOfOrdersMessageCode, body |-> one] : one \in CheckedCancellationsOfOrdersMessage }
        \cup { [tag |-> LastQuoteMessageCode, body |-> one] : one \in CheckedLastQuoteMessage }

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
    { [ZeroMessageBlock EXCEPT !.payload = [tag |-> LoginResponseMessageCode, body |-> ZeroLoginResponseMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> ReplayResponseMessageCode, body |-> ZeroReplayResponseMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> SnapshotResponseMessageCode, body |-> ZeroSnapshotResponseMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> SnapshotCompleteMessageCode, body |-> ZeroSnapshotCompleteMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> EventsSystemMessageCode, body |-> ZeroEventsSystemMessage]],
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
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> OrderChangeMessageCode, body |-> ZeroOrderChangeMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> DepthMessageCode, body |-> ZeroDepthMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> BestOfferMessageCode, body |-> ZeroBestOfferMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> PublicOfferingsMessageCode, body |-> ZeroPublicOfferingsMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> OpenInterestMessageCode, body |-> ZeroOpenInterestMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> DerivativesMarketTradesMessageCode, body |-> ZeroDerivativesMarketTradesMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> StatisticsOfInstrumentsMessageCode, body |-> ZeroStatisticsOfInstrumentsMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> GeneralIndicesMessageCode, body |-> ZeroGeneralIndicesMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> IndicesComponentsMessageCode, body |-> ZeroIndicesComponentsMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> InavMessageCode, body |-> ZeroInavMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> DollarBuySellMessageCode, body |-> ZeroDollarBuySellMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> ShortSalesBalancesPerInstrumentMessageCode, body |-> ZeroShortSalesBalancesPerInstrumentMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> CapitalMarketMultiplesMessageCode, body |-> ZeroCapitalMarketMultiplesMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> BenchmarkMessageCode, body |-> ZeroBenchmarkMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> CapitalizationRulesMessageCode, body |-> ZeroCapitalizationRulesMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> ClosingPriceOriginMessageCode, body |-> ZeroClosingPriceOriginMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> MutualFundsTradesMessageCode, body |-> ZeroMutualFundsTradesMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> OpeningOfContinuousAuctionsMessageCode, body |-> ZeroOpeningOfContinuousAuctionsMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> ExistenceOfBidsAtMidPriceMessageCode, body |-> ZeroExistenceOfBidsAtMidPriceMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> CatalogueOfDebtAndMetalsInstrumentsMessageCode, body |-> ZeroCatalogueOfDebtAndMetalsInstrumentsMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> CatalogSentForInstrumentsBelongingToMutualFundsMessageCode, body |-> ZeroCatalogSentForInstrumentsBelongingToMutualFundsMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> WeightedAveragePriceMessageCode, body |-> ZeroWeightedAveragePriceMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> SystemEventsMessageCode, body |-> ZeroSystemEventsMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> ReferencePriceMessageCode, body |-> ZeroReferencePriceMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> ChangesInStatusMessageCode, body |-> ZeroChangesInStatusMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> CatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessageCode, body |-> ZeroCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> CatalogSentForInstrumentsBelongingToCapitalTracsMessageCode, body |-> ZeroCatalogSentForInstrumentsBelongingToCapitalTracsMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> ConsolidatedInavMessageCode, body |-> ZeroConsolidatedInavMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> CatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessageCode, body |-> ZeroCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> ProbablePriceOfAllocationMessageCode, body |-> ZeroProbablePriceOfAllocationMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> RelationBetweenBmvbivaInstrumentsMessageCode, body |-> ZeroRelationBetweenBmvbivaInstrumentsMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> EquitiesMarketTradesMessageCode, body |-> ZeroEquitiesMarketTradesMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> ConsolidatedTradeCancellationMessageCode, body |-> ZeroConsolidatedTradeCancellationMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> PricevolumeIndicatorMessageCode, body |-> ZeroPricevolumeIndicatorMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> ConsolidatedExecutionOfOrdersMessageCode, body |-> ZeroConsolidatedExecutionOfOrdersMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> RegistrationOfOrderMessageCode, body |-> ZeroRegistrationOfOrderMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> CancellationsOfOrdersMessageCode, body |-> ZeroCancellationsOfOrdersMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> LastQuoteMessageCode, body |-> ZeroLastQuoteMessage]] }

(***************************************************************************)
(* Tcp Unit, framed by Length                                              *)
(***************************************************************************)

TcpUnit ==
    [ marketDataGroup : Sample(1),
      session         : Sample(1),
      sequenceNumber  : Sample(4),
      datetime        : Sample(8),
      messageBlock    : SampleLists(OneMessageBlock) ]

EncodeTcpUnitBody(message) ==
    EncodeUIntBE(Len(message.messageBlock), 1)
        \o message.marketDataGroup
        \o message.session
        \o message.sequenceNumber
        \o message.datetime
        \o EncodeMessageBlockList(message.messageBlock)

(* Length counts the bytes it frames, so it is written from them *)
EncodeTcpUnit(message) ==
    LET body == EncodeTcpUnitBody(message)
    IN  EncodeUIntBE(Len(body) + 2, 2) \o body

DecodeTcpUnitBody(bytes) ==
    LET totalMessages == ReadUIntBE(bytes, 1) IN IF ~totalMessages.ok THEN Fail ELSE
    LET marketDataGroup == ReadBytes(totalMessages.rest, 1) IN IF ~marketDataGroup.ok THEN Fail ELSE
    LET session == ReadBytes(marketDataGroup.rest, 1) IN IF ~session.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(session.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET datetime == ReadBytes(sequenceNumber.rest, 8) IN IF ~datetime.ok THEN Fail ELSE
    LET messageBlock == ReadMessageBlockList(datetime.rest, totalMessages.value) IN IF ~messageBlock.ok THEN Fail ELSE
    Ok([ marketDataGroup |-> marketDataGroup.value,
         session         |-> session.value,
         sequenceNumber  |-> sequenceNumber.value,
         datetime        |-> datetime.value,
         messageBlock    |-> messageBlock.value ], messageBlock.rest)

DecodeTcpUnit(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeTcpUnitBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroTcpUnit ==
    [ marketDataGroup |-> [i \in 1 .. 1 |-> 0],
      session         |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber  |-> [i \in 1 .. 4 |-> 0],
      datetime        |-> [i \in 1 .. 8 |-> 0],
      messageBlock    |-> << >> ]

(* Tcp Unit at zero, then each field in turn at the values it is checked at *)
CheckedTcpUnit ==
    { ZeroTcpUnit }
        \cup { [ZeroTcpUnit EXCEPT !.marketDataGroup = one] : one \in Sample(1) }
        \cup { [ZeroTcpUnit EXCEPT !.session = one] : one \in Sample(1) }
        \cup { [ZeroTcpUnit EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroTcpUnit EXCEPT !.datetime = one] : one \in Sample(8) }
        \cup { [ZeroTcpUnit EXCEPT !.messageBlock = one] : one \in SampleLists(OneMessageBlock) }

(* A run of Tcp Unit, written one after another *)
RECURSIVE EncodeTcpUnitList(_)
EncodeTcpUnitList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTcpUnit(Head(messages)) \o EncodeTcpUnitList(Tail(messages))

(* As many Tcp Unit as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadTcpUnitAll(_)
ReadTcpUnitAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeTcpUnit(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTcpUnitAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Tcp Unit of each kind, for the lists that carry them *)
OneTcpUnit == { ZeroTcpUnit }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ tcpUnit : SampleLists(OneTcpUnit) ]

EncodePacket(message) ==
    EncodeTcpUnitList(message.tcpUnit)

DecodePacket(bytes) ==
    LET tcpUnit == ReadTcpUnitAll(bytes) IN IF ~tcpUnit.ok THEN Fail ELSE
    Ok([ tcpUnit |-> tcpUnit.value ], tcpUnit.rest)

ZeroPacket ==
    [ tcpUnit |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.tcpUnit = one] : one \in SampleLists(OneTcpUnit) }

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

(* Every Login Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginResponseMessage ==
    \A message \in CheckedLoginResponseMessage :
        LET read == DecodeLoginResponseMessage(EncodeLoginResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Replay Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReplayResponseMessage ==
    \A message \in CheckedReplayResponseMessage :
        LET read == DecodeReplayResponseMessage(EncodeReplayResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotResponseMessage ==
    \A message \in CheckedSnapshotResponseMessage :
        LET read == DecodeSnapshotResponseMessage(EncodeSnapshotResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Complete Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotCompleteMessage ==
    \A message \in CheckedSnapshotCompleteMessage :
        LET read == DecodeSnapshotCompleteMessage(EncodeSnapshotCompleteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

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

(* Every Price Level decodes back to what was encoded, and leaves nothing over *)
RoundTripPriceLevel ==
    \A message \in CheckedPriceLevel :
        LET read == DecodePriceLevel(EncodePriceLevel(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Depth Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDepthMessage ==
    \A message \in CheckedDepthMessage :
        LET read == DecodeDepthMessage(EncodeDepthMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Best Offer Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBestOfferMessage ==
    \A message \in CheckedBestOfferMessage :
        LET read == DecodeBestOfferMessage(EncodeBestOfferMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Public Offerings Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPublicOfferingsMessage ==
    \A message \in CheckedPublicOfferingsMessage :
        LET read == DecodePublicOfferingsMessage(EncodePublicOfferingsMessage(message))
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

(* Every Derivatives Market Trades Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDerivativesMarketTradesMessage ==
    \A message \in CheckedDerivativesMarketTradesMessage :
        LET read == DecodeDerivativesMarketTradesMessage(EncodeDerivativesMarketTradesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Statistics Of Instruments Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStatisticsOfInstrumentsMessage ==
    \A message \in CheckedStatisticsOfInstrumentsMessage :
        LET read == DecodeStatisticsOfInstrumentsMessage(EncodeStatisticsOfInstrumentsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every General Indices Message decodes back to what was encoded, and leaves nothing over *)
RoundTripGeneralIndicesMessage ==
    \A message \in CheckedGeneralIndicesMessage :
        LET read == DecodeGeneralIndicesMessage(EncodeGeneralIndicesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Indices Components Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIndicesComponentsMessage ==
    \A message \in CheckedIndicesComponentsMessage :
        LET read == DecodeIndicesComponentsMessage(EncodeIndicesComponentsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Inav Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInavMessage ==
    \A message \in CheckedInavMessage :
        LET read == DecodeInavMessage(EncodeInavMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Dollar Buy Sell Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDollarBuySellMessage ==
    \A message \in CheckedDollarBuySellMessage :
        LET read == DecodeDollarBuySellMessage(EncodeDollarBuySellMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Short Sales Balances Per Instrument Message decodes back to what was encoded, and leaves nothing over *)
RoundTripShortSalesBalancesPerInstrumentMessage ==
    \A message \in CheckedShortSalesBalancesPerInstrumentMessage :
        LET read == DecodeShortSalesBalancesPerInstrumentMessage(EncodeShortSalesBalancesPerInstrumentMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Capital Market Multiples Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCapitalMarketMultiplesMessage ==
    \A message \in CheckedCapitalMarketMultiplesMessage :
        LET read == DecodeCapitalMarketMultiplesMessage(EncodeCapitalMarketMultiplesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Benchmark Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBenchmarkMessage ==
    \A message \in CheckedBenchmarkMessage :
        LET read == DecodeBenchmarkMessage(EncodeBenchmarkMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Capitalization Rules Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCapitalizationRulesMessage ==
    \A message \in CheckedCapitalizationRulesMessage :
        LET read == DecodeCapitalizationRulesMessage(EncodeCapitalizationRulesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Closing Price Origin Message decodes back to what was encoded, and leaves nothing over *)
RoundTripClosingPriceOriginMessage ==
    \A message \in CheckedClosingPriceOriginMessage :
        LET read == DecodeClosingPriceOriginMessage(EncodeClosingPriceOriginMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mutual Funds Trades Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMutualFundsTradesMessage ==
    \A message \in CheckedMutualFundsTradesMessage :
        LET read == DecodeMutualFundsTradesMessage(EncodeMutualFundsTradesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Opening Of Continuous Auctions Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOpeningOfContinuousAuctionsMessage ==
    \A message \in CheckedOpeningOfContinuousAuctionsMessage :
        LET read == DecodeOpeningOfContinuousAuctionsMessage(EncodeOpeningOfContinuousAuctionsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Existence Of Bids At Mid Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExistenceOfBidsAtMidPriceMessage ==
    \A message \in CheckedExistenceOfBidsAtMidPriceMessage :
        LET read == DecodeExistenceOfBidsAtMidPriceMessage(EncodeExistenceOfBidsAtMidPriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Catalogue Of Debt And Metals Instruments Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCatalogueOfDebtAndMetalsInstrumentsMessage ==
    \A message \in CheckedCatalogueOfDebtAndMetalsInstrumentsMessage :
        LET read == DecodeCatalogueOfDebtAndMetalsInstrumentsMessage(EncodeCatalogueOfDebtAndMetalsInstrumentsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Catalog Sent For Instruments Belonging To Mutual Funds Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCatalogSentForInstrumentsBelongingToMutualFundsMessage ==
    \A message \in CheckedCatalogSentForInstrumentsBelongingToMutualFundsMessage :
        LET read == DecodeCatalogSentForInstrumentsBelongingToMutualFundsMessage(EncodeCatalogSentForInstrumentsBelongingToMutualFundsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Weighted Average Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripWeightedAveragePriceMessage ==
    \A message \in CheckedWeightedAveragePriceMessage :
        LET read == DecodeWeightedAveragePriceMessage(EncodeWeightedAveragePriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every System Events Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSystemEventsMessage ==
    \A message \in CheckedSystemEventsMessage :
        LET read == DecodeSystemEventsMessage(EncodeSystemEventsMessage(message))
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

(* Every Changes In Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripChangesInStatusMessage ==
    \A message \in CheckedChangesInStatusMessage :
        LET read == DecodeChangesInStatusMessage(EncodeChangesInStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Catalog For Instruments Belonging To The Capital Warrants Market Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage ==
    \A message \in CheckedCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage :
        LET read == DecodeCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage(EncodeCatalogForInstrumentsBelongingToTheCapitalWarrantsMarketMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Catalog Sent For Instruments Belonging To Capital Tracs Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCatalogSentForInstrumentsBelongingToCapitalTracsMessage ==
    \A message \in CheckedCatalogSentForInstrumentsBelongingToCapitalTracsMessage :
        LET read == DecodeCatalogSentForInstrumentsBelongingToCapitalTracsMessage(EncodeCatalogSentForInstrumentsBelongingToCapitalTracsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Consolidated Inav Message decodes back to what was encoded, and leaves nothing over *)
RoundTripConsolidatedInavMessage ==
    \A message \in CheckedConsolidatedInavMessage :
        LET read == DecodeConsolidatedInavMessage(EncodeConsolidatedInavMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Catalog For Instruments Belonging To The Local And Global Stock Market Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage ==
    \A message \in CheckedCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage :
        LET read == DecodeCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage(EncodeCatalogForInstrumentsBelongingToTheLocalAndGlobalStockMarketMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Probable Price Of Allocation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripProbablePriceOfAllocationMessage ==
    \A message \in CheckedProbablePriceOfAllocationMessage :
        LET read == DecodeProbablePriceOfAllocationMessage(EncodeProbablePriceOfAllocationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Relation Between Bmvbiva Instruments Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRelationBetweenBmvbivaInstrumentsMessage ==
    \A message \in CheckedRelationBetweenBmvbivaInstrumentsMessage :
        LET read == DecodeRelationBetweenBmvbivaInstrumentsMessage(EncodeRelationBetweenBmvbivaInstrumentsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Equities Market Trades Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEquitiesMarketTradesMessage ==
    \A message \in CheckedEquitiesMarketTradesMessage :
        LET read == DecodeEquitiesMarketTradesMessage(EncodeEquitiesMarketTradesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Consolidated Trade Cancellation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripConsolidatedTradeCancellationMessage ==
    \A message \in CheckedConsolidatedTradeCancellationMessage :
        LET read == DecodeConsolidatedTradeCancellationMessage(EncodeConsolidatedTradeCancellationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Pricevolume Indicator Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPricevolumeIndicatorMessage ==
    \A message \in CheckedPricevolumeIndicatorMessage :
        LET read == DecodePricevolumeIndicatorMessage(EncodePricevolumeIndicatorMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Consolidated Execution Of Orders Message decodes back to what was encoded, and leaves nothing over *)
RoundTripConsolidatedExecutionOfOrdersMessage ==
    \A message \in CheckedConsolidatedExecutionOfOrdersMessage :
        LET read == DecodeConsolidatedExecutionOfOrdersMessage(EncodeConsolidatedExecutionOfOrdersMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Registration Of Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRegistrationOfOrderMessage ==
    \A message \in CheckedRegistrationOfOrderMessage :
        LET read == DecodeRegistrationOfOrderMessage(EncodeRegistrationOfOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancellations Of Orders Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCancellationsOfOrdersMessage ==
    \A message \in CheckedCancellationsOfOrdersMessage :
        LET read == DecodeCancellationsOfOrdersMessage(EncodeCancellationsOfOrdersMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Last Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLastQuoteMessage ==
    \A message \in CheckedLastQuoteMessage :
        LET read == DecodeLastQuoteMessage(EncodeLastQuoteMessage(message))
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

(* Every Tcp Unit decodes back to what was encoded, and leaves nothing over *)
RoundTripTcpUnit ==
    \A message \in CheckedTcpUnit :
        LET read == DecodeTcpUnit(EncodeTcpUnit(message))
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

(* Length is written from the bytes it frames *)
FramesTcpUnit ==
    \A message \in CheckedTcpUnit :
        LET bytes == EncodeTcpUnit(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
