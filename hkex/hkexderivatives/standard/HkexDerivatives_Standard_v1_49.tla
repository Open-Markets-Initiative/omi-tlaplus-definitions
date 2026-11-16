------------------ MODULE HkexDerivatives_Standard_v1_49 -------------------
(***************************************************************************)
(* Hong Kong Exchanges and Clearing Orion Market Data Derivatives Standard *)
(* v1.49                                                                   *)
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
(* Note: a Compression Mode of any value but 1 says nothing transformed    *)
(* Message Buffer, which is then read as it stands.                        *)
(*                                                                         *)
(* Note: Message Buffer untransformed is as many Message as Msg Count      *)
(* says, which is read beside the flag and handed to the choice: the count *)
(* says how many the bytes hold, and transformed they hold a run no        *)
(* reading of them states, so it is carried rather than written from the   *)
(* run.                                                                    *)
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
(* Book Entry: 24 bytes                                                    *)
(***************************************************************************)

BookEntry ==
    [ aggregateQuantity : Sample(8),
      price             : Sample(4),
      numberOfOrders    : Sample(4),
      side              : Sample(1),
      filler1           : Sample(1),
      priceLevel        : Sample(1),
      updateAction      : Sample(1),
      filler4           : Sample(4) ]

EncodeBookEntry(message) ==
    message.aggregateQuantity
        \o message.price
        \o message.numberOfOrders
        \o message.side
        \o message.filler1
        \o message.priceLevel
        \o message.updateAction
        \o message.filler4

DecodeBookEntry(bytes) ==
    LET aggregateQuantity == ReadBytes(bytes, 8) IN IF ~aggregateQuantity.ok THEN Fail ELSE
    LET price == ReadBytes(aggregateQuantity.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET numberOfOrders == ReadBytes(price.rest, 4) IN IF ~numberOfOrders.ok THEN Fail ELSE
    LET side == ReadBytes(numberOfOrders.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET filler1 == ReadBytes(side.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET priceLevel == ReadBytes(filler1.rest, 1) IN IF ~priceLevel.ok THEN Fail ELSE
    LET updateAction == ReadBytes(priceLevel.rest, 1) IN IF ~updateAction.ok THEN Fail ELSE
    LET filler4 == ReadBytes(updateAction.rest, 4) IN IF ~filler4.ok THEN Fail ELSE
    Ok([ aggregateQuantity |-> aggregateQuantity.value,
         price             |-> price.value,
         numberOfOrders    |-> numberOfOrders.value,
         side              |-> side.value,
         filler1           |-> filler1.value,
         priceLevel        |-> priceLevel.value,
         updateAction      |-> updateAction.value,
         filler4           |-> filler4.value ], filler4.rest)

ZeroBookEntry ==
    [ aggregateQuantity |-> [i \in 1 .. 8 |-> 0],
      price             |-> [i \in 1 .. 4 |-> 0],
      numberOfOrders    |-> [i \in 1 .. 4 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      filler1           |-> [i \in 1 .. 1 |-> 0],
      priceLevel        |-> [i \in 1 .. 1 |-> 0],
      updateAction      |-> [i \in 1 .. 1 |-> 0],
      filler4           |-> [i \in 1 .. 4 |-> 0] ]

(* Book Entry at zero, then each field in turn at the values it is checked at *)
CheckedBookEntry ==
    { ZeroBookEntry }
        \cup { [ZeroBookEntry EXCEPT !.aggregateQuantity = one] : one \in Sample(8) }
        \cup { [ZeroBookEntry EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroBookEntry EXCEPT !.numberOfOrders = one] : one \in Sample(4) }
        \cup { [ZeroBookEntry EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroBookEntry EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroBookEntry EXCEPT !.priceLevel = one] : one \in Sample(1) }
        \cup { [ZeroBookEntry EXCEPT !.updateAction = one] : one \in Sample(1) }
        \cup { [ZeroBookEntry EXCEPT !.filler4 = one] : one \in Sample(4) }

(* A run of Book Entry, written one after another *)
RECURSIVE EncodeBookEntryList(_)
EncodeBookEntryList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeBookEntry(Head(messages)) \o EncodeBookEntryList(Tail(messages))

(* As many Book Entry as the field that counts them says *)
RECURSIVE ReadBookEntryList(_, _)
ReadBookEntryList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeBookEntry(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadBookEntryList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Book Entry of each kind, for the lists that carry them *)
OneBookEntry == { ZeroBookEntry }

(***************************************************************************)
(* Aggregate Order Book Update Message                                     *)
(***************************************************************************)

AggregateOrderBookUpdateMessage ==
    [ orderbookId : Sample(4),
      filler3     : Sample(3),
      bookEntry   : SampleLists(OneBookEntry) ]

EncodeAggregateOrderBookUpdateMessage(message) ==
    message.orderbookId
        \o message.filler3
        \o EncodeUIntBE(Len(message.bookEntry), 1)
        \o EncodeBookEntryList(message.bookEntry)

DecodeAggregateOrderBookUpdateMessage(bytes) ==
    LET orderbookId == ReadBytes(bytes, 4) IN IF ~orderbookId.ok THEN Fail ELSE
    LET filler3 == ReadBytes(orderbookId.rest, 3) IN IF ~filler3.ok THEN Fail ELSE
    LET noEntries == ReadUIntBE(filler3.rest, 1) IN IF ~noEntries.ok THEN Fail ELSE
    LET bookEntry == ReadBookEntryList(noEntries.rest, noEntries.value) IN IF ~bookEntry.ok THEN Fail ELSE
    Ok([ orderbookId |-> orderbookId.value,
         filler3     |-> filler3.value,
         bookEntry   |-> bookEntry.value ], bookEntry.rest)

ZeroAggregateOrderBookUpdateMessage ==
    [ orderbookId |-> [i \in 1 .. 4 |-> 0],
      filler3     |-> [i \in 1 .. 3 |-> 0],
      bookEntry   |-> << >> ]

(* Aggregate Order Book Update Message at zero, then each field in turn at the values it is checked at *)
CheckedAggregateOrderBookUpdateMessage ==
    { ZeroAggregateOrderBookUpdateMessage }
        \cup { [ZeroAggregateOrderBookUpdateMessage EXCEPT !.orderbookId = one] : one \in Sample(4) }
        \cup { [ZeroAggregateOrderBookUpdateMessage EXCEPT !.filler3 = one] : one \in Sample(3) }
        \cup { [ZeroAggregateOrderBookUpdateMessage EXCEPT !.bookEntry = one] : one \in SampleLists(OneBookEntry) }

(***************************************************************************)
(* Calculated Opening Price Message: 20 bytes                              *)
(***************************************************************************)

CalculatedOpeningPriceMessage ==
    [ orderbookId            : Sample(4),
      calculatedOpeningPrice : Sample(4),
      filler4                : Sample(4),
      quantity               : Sample(8) ]

EncodeCalculatedOpeningPriceMessage(message) ==
    message.orderbookId
        \o message.calculatedOpeningPrice
        \o message.filler4
        \o message.quantity

DecodeCalculatedOpeningPriceMessage(bytes) ==
    LET orderbookId == ReadBytes(bytes, 4) IN IF ~orderbookId.ok THEN Fail ELSE
    LET calculatedOpeningPrice == ReadBytes(orderbookId.rest, 4) IN IF ~calculatedOpeningPrice.ok THEN Fail ELSE
    LET filler4 == ReadBytes(calculatedOpeningPrice.rest, 4) IN IF ~filler4.ok THEN Fail ELSE
    LET quantity == ReadBytes(filler4.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    Ok([ orderbookId            |-> orderbookId.value,
         calculatedOpeningPrice |-> calculatedOpeningPrice.value,
         filler4                |-> filler4.value,
         quantity               |-> quantity.value ], quantity.rest)

ZeroCalculatedOpeningPriceMessage ==
    [ orderbookId            |-> [i \in 1 .. 4 |-> 0],
      calculatedOpeningPrice |-> [i \in 1 .. 4 |-> 0],
      filler4                |-> [i \in 1 .. 4 |-> 0],
      quantity               |-> [i \in 1 .. 8 |-> 0] ]

(* Calculated Opening Price Message at zero, then each field in turn at the values it is checked at *)
CheckedCalculatedOpeningPriceMessage ==
    { ZeroCalculatedOpeningPriceMessage }
        \cup { [ZeroCalculatedOpeningPriceMessage EXCEPT !.orderbookId = one] : one \in Sample(4) }
        \cup { [ZeroCalculatedOpeningPriceMessage EXCEPT !.calculatedOpeningPrice = one] : one \in Sample(4) }
        \cup { [ZeroCalculatedOpeningPriceMessage EXCEPT !.filler4 = one] : one \in Sample(4) }
        \cup { [ZeroCalculatedOpeningPriceMessage EXCEPT !.quantity = one] : one \in Sample(8) }

(***************************************************************************)
(* Sequence Reset: 4 bytes                                                 *)
(***************************************************************************)

SequenceReset ==
    [ newSeqNo : Sample(4) ]

EncodeSequenceReset(message) ==
    message.newSeqNo

DecodeSequenceReset(bytes) ==
    LET newSeqNo == ReadBytes(bytes, 4) IN IF ~newSeqNo.ok THEN Fail ELSE
    Ok([ newSeqNo |-> newSeqNo.value ], newSeqNo.rest)

ZeroSequenceReset ==
    [ newSeqNo |-> [i \in 1 .. 4 |-> 0] ]

(* Sequence Reset at zero, then each field in turn at the values it is checked at *)
CheckedSequenceReset ==
    { ZeroSequenceReset }
        \cup { [ZeroSequenceReset EXCEPT !.newSeqNo = one] : one \in Sample(4) }

(***************************************************************************)
(* Disaster Recovery Signal Message: 4 bytes                               *)
(***************************************************************************)

DisasterRecoverySignalMessage ==
    [ drStatus : Sample(4) ]

EncodeDisasterRecoverySignalMessage(message) ==
    message.drStatus

DecodeDisasterRecoverySignalMessage(bytes) ==
    LET drStatus == ReadBytes(bytes, 4) IN IF ~drStatus.ok THEN Fail ELSE
    Ok([ drStatus |-> drStatus.value ], drStatus.rest)

ZeroDisasterRecoverySignalMessage ==
    [ drStatus |-> [i \in 1 .. 4 |-> 0] ]

(* Disaster Recovery Signal Message at zero, then each field in turn at the values it is checked at *)
CheckedDisasterRecoverySignalMessage ==
    { ZeroDisasterRecoverySignalMessage }
        \cup { [ZeroDisasterRecoverySignalMessage EXCEPT !.drStatus = one] : one \in Sample(4) }

(***************************************************************************)
(* Market Alert Message: 648 bytes                                         *)
(***************************************************************************)

MarketAlertMessage ==
    [ alertId      : Sample(2),
      source       : Sample(1),
      filler1      : Sample(1),
      header       : Sample(320),
      lastFragment : Sample(1),
      infoType     : Sample(1),
      priority     : Sample(1),
      noLines      : 0 .. 255,
      content      : Sample(320) ]

EncodeMarketAlertMessage(message) ==
    message.alertId
        \o message.source
        \o message.filler1
        \o message.header
        \o message.lastFragment
        \o message.infoType
        \o message.priority
        \o EncodeUIntBE(message.noLines, 1)
        \o message.content

DecodeMarketAlertMessage(bytes) ==
    LET alertId == ReadBytes(bytes, 2) IN IF ~alertId.ok THEN Fail ELSE
    LET source == ReadBytes(alertId.rest, 1) IN IF ~source.ok THEN Fail ELSE
    LET filler1 == ReadBytes(source.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET header == ReadBytes(filler1.rest, 320) IN IF ~header.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(header.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET infoType == ReadBytes(lastFragment.rest, 1) IN IF ~infoType.ok THEN Fail ELSE
    LET priority == ReadBytes(infoType.rest, 1) IN IF ~priority.ok THEN Fail ELSE
    LET noLines == ReadUIntBE(priority.rest, 1) IN IF ~noLines.ok THEN Fail ELSE
    LET content == ReadBytes(noLines.rest, 320) IN IF ~content.ok THEN Fail ELSE
    Ok([ alertId      |-> alertId.value,
         source       |-> source.value,
         filler1      |-> filler1.value,
         header       |-> header.value,
         lastFragment |-> lastFragment.value,
         infoType     |-> infoType.value,
         priority     |-> priority.value,
         noLines      |-> noLines.value,
         content      |-> content.value ], content.rest)

ZeroMarketAlertMessage ==
    [ alertId      |-> [i \in 1 .. 2 |-> 0],
      source       |-> [i \in 1 .. 1 |-> 0],
      filler1      |-> [i \in 1 .. 1 |-> 0],
      header       |-> [i \in 1 .. 320 |-> 0],
      lastFragment |-> [i \in 1 .. 1 |-> 0],
      infoType     |-> [i \in 1 .. 1 |-> 0],
      priority     |-> [i \in 1 .. 1 |-> 0],
      noLines      |-> 0,
      content      |-> [i \in 1 .. 320 |-> 0] ]

(* Market Alert Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketAlertMessage ==
    { ZeroMarketAlertMessage }
        \cup { [ZeroMarketAlertMessage EXCEPT !.alertId = one] : one \in Sample(2) }
        \cup { [ZeroMarketAlertMessage EXCEPT !.source = one] : one \in Sample(1) }
        \cup { [ZeroMarketAlertMessage EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroMarketAlertMessage EXCEPT !.header = one] : one \in Sample(320) }
        \cup { [ZeroMarketAlertMessage EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroMarketAlertMessage EXCEPT !.infoType = one] : one \in Sample(1) }
        \cup { [ZeroMarketAlertMessage EXCEPT !.priority = one] : one \in Sample(1) }
        \cup { [ZeroMarketAlertMessage EXCEPT !.noLines = one] : one \in {0, 1, 255} }
        \cup { [ZeroMarketAlertMessage EXCEPT !.content = one] : one \in Sample(320) }

(***************************************************************************)
(* Open Interest Message: 36 bytes                                         *)
(***************************************************************************)

OpenInterestMessage ==
    [ dayIndicator : Sample(2),
      filler6      : Sample(6),
      orderbookId  : Sample(4),
      settlement   : Sample(4),
      dealCount    : Sample(4),
      grossOi      : Sample(4),
      netOi        : Sample(4),
      turnover     : Sample(8) ]

EncodeOpenInterestMessage(message) ==
    message.dayIndicator
        \o message.filler6
        \o message.orderbookId
        \o message.settlement
        \o message.dealCount
        \o message.grossOi
        \o message.netOi
        \o message.turnover

DecodeOpenInterestMessage(bytes) ==
    LET dayIndicator == ReadBytes(bytes, 2) IN IF ~dayIndicator.ok THEN Fail ELSE
    LET filler6 == ReadBytes(dayIndicator.rest, 6) IN IF ~filler6.ok THEN Fail ELSE
    LET orderbookId == ReadBytes(filler6.rest, 4) IN IF ~orderbookId.ok THEN Fail ELSE
    LET settlement == ReadBytes(orderbookId.rest, 4) IN IF ~settlement.ok THEN Fail ELSE
    LET dealCount == ReadBytes(settlement.rest, 4) IN IF ~dealCount.ok THEN Fail ELSE
    LET grossOi == ReadBytes(dealCount.rest, 4) IN IF ~grossOi.ok THEN Fail ELSE
    LET netOi == ReadBytes(grossOi.rest, 4) IN IF ~netOi.ok THEN Fail ELSE
    LET turnover == ReadBytes(netOi.rest, 8) IN IF ~turnover.ok THEN Fail ELSE
    Ok([ dayIndicator |-> dayIndicator.value,
         filler6      |-> filler6.value,
         orderbookId  |-> orderbookId.value,
         settlement   |-> settlement.value,
         dealCount    |-> dealCount.value,
         grossOi      |-> grossOi.value,
         netOi        |-> netOi.value,
         turnover     |-> turnover.value ], turnover.rest)

ZeroOpenInterestMessage ==
    [ dayIndicator |-> [i \in 1 .. 2 |-> 0],
      filler6      |-> [i \in 1 .. 6 |-> 0],
      orderbookId  |-> [i \in 1 .. 4 |-> 0],
      settlement   |-> [i \in 1 .. 4 |-> 0],
      dealCount    |-> [i \in 1 .. 4 |-> 0],
      grossOi      |-> [i \in 1 .. 4 |-> 0],
      netOi        |-> [i \in 1 .. 4 |-> 0],
      turnover     |-> [i \in 1 .. 8 |-> 0] ]

(* Open Interest Message at zero, then each field in turn at the values it is checked at *)
CheckedOpenInterestMessage ==
    { ZeroOpenInterestMessage }
        \cup { [ZeroOpenInterestMessage EXCEPT !.dayIndicator = one] : one \in Sample(2) }
        \cup { [ZeroOpenInterestMessage EXCEPT !.filler6 = one] : one \in Sample(6) }
        \cup { [ZeroOpenInterestMessage EXCEPT !.orderbookId = one] : one \in Sample(4) }
        \cup { [ZeroOpenInterestMessage EXCEPT !.settlement = one] : one \in Sample(4) }
        \cup { [ZeroOpenInterestMessage EXCEPT !.dealCount = one] : one \in Sample(4) }
        \cup { [ZeroOpenInterestMessage EXCEPT !.grossOi = one] : one \in Sample(4) }
        \cup { [ZeroOpenInterestMessage EXCEPT !.netOi = one] : one \in Sample(4) }
        \cup { [ZeroOpenInterestMessage EXCEPT !.turnover = one] : one \in Sample(8) }

(***************************************************************************)
(* Quote Request: 12 bytes                                                 *)
(***************************************************************************)

QuoteRequest ==
    [ orderbookId  : Sample(4),
      numberOfLots : Sample(4),
      bidAskFlag   : Sample(1),
      filler3      : Sample(3) ]

EncodeQuoteRequest(message) ==
    message.orderbookId
        \o message.numberOfLots
        \o message.bidAskFlag
        \o message.filler3

DecodeQuoteRequest(bytes) ==
    LET orderbookId == ReadBytes(bytes, 4) IN IF ~orderbookId.ok THEN Fail ELSE
    LET numberOfLots == ReadBytes(orderbookId.rest, 4) IN IF ~numberOfLots.ok THEN Fail ELSE
    LET bidAskFlag == ReadBytes(numberOfLots.rest, 1) IN IF ~bidAskFlag.ok THEN Fail ELSE
    LET filler3 == ReadBytes(bidAskFlag.rest, 3) IN IF ~filler3.ok THEN Fail ELSE
    Ok([ orderbookId  |-> orderbookId.value,
         numberOfLots |-> numberOfLots.value,
         bidAskFlag   |-> bidAskFlag.value,
         filler3      |-> filler3.value ], filler3.rest)

ZeroQuoteRequest ==
    [ orderbookId  |-> [i \in 1 .. 4 |-> 0],
      numberOfLots |-> [i \in 1 .. 4 |-> 0],
      bidAskFlag   |-> [i \in 1 .. 1 |-> 0],
      filler3      |-> [i \in 1 .. 3 |-> 0] ]

(* Quote Request at zero, then each field in turn at the values it is checked at *)
CheckedQuoteRequest ==
    { ZeroQuoteRequest }
        \cup { [ZeroQuoteRequest EXCEPT !.orderbookId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRequest EXCEPT !.numberOfLots = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRequest EXCEPT !.bidAskFlag = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRequest EXCEPT !.filler3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Commodity Definition Message: 90 bytes                                  *)
(***************************************************************************)

CommodityDefinitionMessage ==
    [ commodityCode            : Sample(2),
      decimalInUnderlyingPrice : Sample(2),
      isinCode                 : Sample(12),
      baseCurrency             : Sample(3),
      underlyingPriceUnit      : Sample(1),
      commodityName            : Sample(32),
      nominalValue             : Sample(8),
      underlyingCode           : Sample(20),
      underlyingType           : Sample(1),
      effectiveTomorrow        : Sample(1),
      commodityId              : Sample(6),
      filler2                  : Sample(2) ]

EncodeCommodityDefinitionMessage(message) ==
    message.commodityCode
        \o message.decimalInUnderlyingPrice
        \o message.isinCode
        \o message.baseCurrency
        \o message.underlyingPriceUnit
        \o message.commodityName
        \o message.nominalValue
        \o message.underlyingCode
        \o message.underlyingType
        \o message.effectiveTomorrow
        \o message.commodityId
        \o message.filler2

DecodeCommodityDefinitionMessage(bytes) ==
    LET commodityCode == ReadBytes(bytes, 2) IN IF ~commodityCode.ok THEN Fail ELSE
    LET decimalInUnderlyingPrice == ReadBytes(commodityCode.rest, 2) IN IF ~decimalInUnderlyingPrice.ok THEN Fail ELSE
    LET isinCode == ReadBytes(decimalInUnderlyingPrice.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET baseCurrency == ReadBytes(isinCode.rest, 3) IN IF ~baseCurrency.ok THEN Fail ELSE
    LET underlyingPriceUnit == ReadBytes(baseCurrency.rest, 1) IN IF ~underlyingPriceUnit.ok THEN Fail ELSE
    LET commodityName == ReadBytes(underlyingPriceUnit.rest, 32) IN IF ~commodityName.ok THEN Fail ELSE
    LET nominalValue == ReadBytes(commodityName.rest, 8) IN IF ~nominalValue.ok THEN Fail ELSE
    LET underlyingCode == ReadBytes(nominalValue.rest, 20) IN IF ~underlyingCode.ok THEN Fail ELSE
    LET underlyingType == ReadBytes(underlyingCode.rest, 1) IN IF ~underlyingType.ok THEN Fail ELSE
    LET effectiveTomorrow == ReadBytes(underlyingType.rest, 1) IN IF ~effectiveTomorrow.ok THEN Fail ELSE
    LET commodityId == ReadBytes(effectiveTomorrow.rest, 6) IN IF ~commodityId.ok THEN Fail ELSE
    LET filler2 == ReadBytes(commodityId.rest, 2) IN IF ~filler2.ok THEN Fail ELSE
    Ok([ commodityCode            |-> commodityCode.value,
         decimalInUnderlyingPrice |-> decimalInUnderlyingPrice.value,
         isinCode                 |-> isinCode.value,
         baseCurrency             |-> baseCurrency.value,
         underlyingPriceUnit      |-> underlyingPriceUnit.value,
         commodityName            |-> commodityName.value,
         nominalValue             |-> nominalValue.value,
         underlyingCode           |-> underlyingCode.value,
         underlyingType           |-> underlyingType.value,
         effectiveTomorrow        |-> effectiveTomorrow.value,
         commodityId              |-> commodityId.value,
         filler2                  |-> filler2.value ], filler2.rest)

ZeroCommodityDefinitionMessage ==
    [ commodityCode            |-> [i \in 1 .. 2 |-> 0],
      decimalInUnderlyingPrice |-> [i \in 1 .. 2 |-> 0],
      isinCode                 |-> [i \in 1 .. 12 |-> 0],
      baseCurrency             |-> [i \in 1 .. 3 |-> 0],
      underlyingPriceUnit      |-> [i \in 1 .. 1 |-> 0],
      commodityName            |-> [i \in 1 .. 32 |-> 0],
      nominalValue             |-> [i \in 1 .. 8 |-> 0],
      underlyingCode           |-> [i \in 1 .. 20 |-> 0],
      underlyingType           |-> [i \in 1 .. 1 |-> 0],
      effectiveTomorrow        |-> [i \in 1 .. 1 |-> 0],
      commodityId              |-> [i \in 1 .. 6 |-> 0],
      filler2                  |-> [i \in 1 .. 2 |-> 0] ]

(* Commodity Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedCommodityDefinitionMessage ==
    { ZeroCommodityDefinitionMessage }
        \cup { [ZeroCommodityDefinitionMessage EXCEPT !.commodityCode = one] : one \in Sample(2) }
        \cup { [ZeroCommodityDefinitionMessage EXCEPT !.decimalInUnderlyingPrice = one] : one \in Sample(2) }
        \cup { [ZeroCommodityDefinitionMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroCommodityDefinitionMessage EXCEPT !.baseCurrency = one] : one \in Sample(3) }
        \cup { [ZeroCommodityDefinitionMessage EXCEPT !.underlyingPriceUnit = one] : one \in Sample(1) }
        \cup { [ZeroCommodityDefinitionMessage EXCEPT !.commodityName = one] : one \in Sample(32) }
        \cup { [ZeroCommodityDefinitionMessage EXCEPT !.nominalValue = one] : one \in Sample(8) }
        \cup { [ZeroCommodityDefinitionMessage EXCEPT !.underlyingCode = one] : one \in Sample(20) }
        \cup { [ZeroCommodityDefinitionMessage EXCEPT !.underlyingType = one] : one \in Sample(1) }
        \cup { [ZeroCommodityDefinitionMessage EXCEPT !.effectiveTomorrow = one] : one \in Sample(1) }
        \cup { [ZeroCommodityDefinitionMessage EXCEPT !.commodityId = one] : one \in Sample(6) }
        \cup { [ZeroCommodityDefinitionMessage EXCEPT !.filler2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Class Definition Message: 114 bytes                                     *)
(***************************************************************************)

ClassDefinitionMessage ==
    [ country               : Sample(1),
      market                : Sample(1),
      instrumentGroup       : Sample(1),
      modifier              : Sample(1),
      commodityCode         : Sample(2),
      filler2               : Sample(2),
      priceQuotationFactor  : Sample(4),
      contractSize          : Sample(4),
      decimalInStrikePrice  : Sample(2),
      decimalInContractSize : Sample(2),
      decimalInPremium      : Sample(2),
      rankingType           : Sample(2),
      tradable              : Sample(1),
      premiumUnit4Price     : Sample(1),
      baseCurrency          : Sample(3),
      instrumentClassId     : Sample(14),
      instrumentClassName   : Sample(32),
      isFractions           : Sample(1),
      settlementCurrencyId  : Sample(32),
      effectiveTomorrow     : Sample(1),
      tickStepSize          : Sample(4),
      filler1               : Sample(1) ]

EncodeClassDefinitionMessage(message) ==
    message.country
        \o message.market
        \o message.instrumentGroup
        \o message.modifier
        \o message.commodityCode
        \o message.filler2
        \o message.priceQuotationFactor
        \o message.contractSize
        \o message.decimalInStrikePrice
        \o message.decimalInContractSize
        \o message.decimalInPremium
        \o message.rankingType
        \o message.tradable
        \o message.premiumUnit4Price
        \o message.baseCurrency
        \o message.instrumentClassId
        \o message.instrumentClassName
        \o message.isFractions
        \o message.settlementCurrencyId
        \o message.effectiveTomorrow
        \o message.tickStepSize
        \o message.filler1

DecodeClassDefinitionMessage(bytes) ==
    LET country == ReadBytes(bytes, 1) IN IF ~country.ok THEN Fail ELSE
    LET market == ReadBytes(country.rest, 1) IN IF ~market.ok THEN Fail ELSE
    LET instrumentGroup == ReadBytes(market.rest, 1) IN IF ~instrumentGroup.ok THEN Fail ELSE
    LET modifier == ReadBytes(instrumentGroup.rest, 1) IN IF ~modifier.ok THEN Fail ELSE
    LET commodityCode == ReadBytes(modifier.rest, 2) IN IF ~commodityCode.ok THEN Fail ELSE
    LET filler2 == ReadBytes(commodityCode.rest, 2) IN IF ~filler2.ok THEN Fail ELSE
    LET priceQuotationFactor == ReadBytes(filler2.rest, 4) IN IF ~priceQuotationFactor.ok THEN Fail ELSE
    LET contractSize == ReadBytes(priceQuotationFactor.rest, 4) IN IF ~contractSize.ok THEN Fail ELSE
    LET decimalInStrikePrice == ReadBytes(contractSize.rest, 2) IN IF ~decimalInStrikePrice.ok THEN Fail ELSE
    LET decimalInContractSize == ReadBytes(decimalInStrikePrice.rest, 2) IN IF ~decimalInContractSize.ok THEN Fail ELSE
    LET decimalInPremium == ReadBytes(decimalInContractSize.rest, 2) IN IF ~decimalInPremium.ok THEN Fail ELSE
    LET rankingType == ReadBytes(decimalInPremium.rest, 2) IN IF ~rankingType.ok THEN Fail ELSE
    LET tradable == ReadBytes(rankingType.rest, 1) IN IF ~tradable.ok THEN Fail ELSE
    LET premiumUnit4Price == ReadBytes(tradable.rest, 1) IN IF ~premiumUnit4Price.ok THEN Fail ELSE
    LET baseCurrency == ReadBytes(premiumUnit4Price.rest, 3) IN IF ~baseCurrency.ok THEN Fail ELSE
    LET instrumentClassId == ReadBytes(baseCurrency.rest, 14) IN IF ~instrumentClassId.ok THEN Fail ELSE
    LET instrumentClassName == ReadBytes(instrumentClassId.rest, 32) IN IF ~instrumentClassName.ok THEN Fail ELSE
    LET isFractions == ReadBytes(instrumentClassName.rest, 1) IN IF ~isFractions.ok THEN Fail ELSE
    LET settlementCurrencyId == ReadBytes(isFractions.rest, 32) IN IF ~settlementCurrencyId.ok THEN Fail ELSE
    LET effectiveTomorrow == ReadBytes(settlementCurrencyId.rest, 1) IN IF ~effectiveTomorrow.ok THEN Fail ELSE
    LET tickStepSize == ReadBytes(effectiveTomorrow.rest, 4) IN IF ~tickStepSize.ok THEN Fail ELSE
    LET filler1 == ReadBytes(tickStepSize.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    Ok([ country               |-> country.value,
         market                |-> market.value,
         instrumentGroup       |-> instrumentGroup.value,
         modifier              |-> modifier.value,
         commodityCode         |-> commodityCode.value,
         filler2               |-> filler2.value,
         priceQuotationFactor  |-> priceQuotationFactor.value,
         contractSize          |-> contractSize.value,
         decimalInStrikePrice  |-> decimalInStrikePrice.value,
         decimalInContractSize |-> decimalInContractSize.value,
         decimalInPremium      |-> decimalInPremium.value,
         rankingType           |-> rankingType.value,
         tradable              |-> tradable.value,
         premiumUnit4Price     |-> premiumUnit4Price.value,
         baseCurrency          |-> baseCurrency.value,
         instrumentClassId     |-> instrumentClassId.value,
         instrumentClassName   |-> instrumentClassName.value,
         isFractions           |-> isFractions.value,
         settlementCurrencyId  |-> settlementCurrencyId.value,
         effectiveTomorrow     |-> effectiveTomorrow.value,
         tickStepSize          |-> tickStepSize.value,
         filler1               |-> filler1.value ], filler1.rest)

ZeroClassDefinitionMessage ==
    [ country               |-> [i \in 1 .. 1 |-> 0],
      market                |-> [i \in 1 .. 1 |-> 0],
      instrumentGroup       |-> [i \in 1 .. 1 |-> 0],
      modifier              |-> [i \in 1 .. 1 |-> 0],
      commodityCode         |-> [i \in 1 .. 2 |-> 0],
      filler2               |-> [i \in 1 .. 2 |-> 0],
      priceQuotationFactor  |-> [i \in 1 .. 4 |-> 0],
      contractSize          |-> [i \in 1 .. 4 |-> 0],
      decimalInStrikePrice  |-> [i \in 1 .. 2 |-> 0],
      decimalInContractSize |-> [i \in 1 .. 2 |-> 0],
      decimalInPremium      |-> [i \in 1 .. 2 |-> 0],
      rankingType           |-> [i \in 1 .. 2 |-> 0],
      tradable              |-> [i \in 1 .. 1 |-> 0],
      premiumUnit4Price     |-> [i \in 1 .. 1 |-> 0],
      baseCurrency          |-> [i \in 1 .. 3 |-> 0],
      instrumentClassId     |-> [i \in 1 .. 14 |-> 0],
      instrumentClassName   |-> [i \in 1 .. 32 |-> 0],
      isFractions           |-> [i \in 1 .. 1 |-> 0],
      settlementCurrencyId  |-> [i \in 1 .. 32 |-> 0],
      effectiveTomorrow     |-> [i \in 1 .. 1 |-> 0],
      tickStepSize          |-> [i \in 1 .. 4 |-> 0],
      filler1               |-> [i \in 1 .. 1 |-> 0] ]

(* Class Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedClassDefinitionMessage ==
    { ZeroClassDefinitionMessage }
        \cup { [ZeroClassDefinitionMessage EXCEPT !.country = one] : one \in Sample(1) }
        \cup { [ZeroClassDefinitionMessage EXCEPT !.market = one] : one \in Sample(1) }
        \cup { [ZeroClassDefinitionMessage EXCEPT !.instrumentGroup = one] : one \in Sample(1) }
        \cup { [ZeroClassDefinitionMessage EXCEPT !.modifier = one] : one \in Sample(1) }
        \cup { [ZeroClassDefinitionMessage EXCEPT !.commodityCode = one] : one \in Sample(2) }
        \cup { [ZeroClassDefinitionMessage EXCEPT !.filler2 = one] : one \in Sample(2) }
        \cup { [ZeroClassDefinitionMessage EXCEPT !.priceQuotationFactor = one] : one \in Sample(4) }
        \cup { [ZeroClassDefinitionMessage EXCEPT !.contractSize = one] : one \in Sample(4) }
        \cup { [ZeroClassDefinitionMessage EXCEPT !.decimalInStrikePrice = one] : one \in Sample(2) }
        \cup { [ZeroClassDefinitionMessage EXCEPT !.decimalInContractSize = one] : one \in Sample(2) }
        \cup { [ZeroClassDefinitionMessage EXCEPT !.decimalInPremium = one] : one \in Sample(2) }
        \cup { [ZeroClassDefinitionMessage EXCEPT !.rankingType = one] : one \in Sample(2) }
        \cup { [ZeroClassDefinitionMessage EXCEPT !.tradable = one] : one \in Sample(1) }
        \cup { [ZeroClassDefinitionMessage EXCEPT !.premiumUnit4Price = one] : one \in Sample(1) }
        \cup { [ZeroClassDefinitionMessage EXCEPT !.baseCurrency = one] : one \in Sample(3) }
        \cup { [ZeroClassDefinitionMessage EXCEPT !.instrumentClassId = one] : one \in Sample(14) }
        \cup { [ZeroClassDefinitionMessage EXCEPT !.instrumentClassName = one] : one \in Sample(32) }
        \cup { [ZeroClassDefinitionMessage EXCEPT !.isFractions = one] : one \in Sample(1) }
        \cup { [ZeroClassDefinitionMessage EXCEPT !.settlementCurrencyId = one] : one \in Sample(32) }
        \cup { [ZeroClassDefinitionMessage EXCEPT !.effectiveTomorrow = one] : one \in Sample(1) }
        \cup { [ZeroClassDefinitionMessage EXCEPT !.tickStepSize = one] : one \in Sample(4) }
        \cup { [ZeroClassDefinitionMessage EXCEPT !.filler1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Series Definition Base Message: 56 bytes                                *)
(***************************************************************************)

SeriesDefinitionBaseMessage ==
    [ orderbookId           : Sample(4),
      symbol                : Sample(32),
      financialProduct      : Sample(1),
      numberOfDecimalsPrice : Sample(2),
      numberOfLegs          : Sample(1),
      strikePrice           : Sample(4),
      expirationDate        : Sample(8),
      decimalInStrikePrice  : Sample(2),
      putOrCall             : Sample(1),
      filler1               : Sample(1) ]

EncodeSeriesDefinitionBaseMessage(message) ==
    message.orderbookId
        \o message.symbol
        \o message.financialProduct
        \o message.numberOfDecimalsPrice
        \o message.numberOfLegs
        \o message.strikePrice
        \o message.expirationDate
        \o message.decimalInStrikePrice
        \o message.putOrCall
        \o message.filler1

DecodeSeriesDefinitionBaseMessage(bytes) ==
    LET orderbookId == ReadBytes(bytes, 4) IN IF ~orderbookId.ok THEN Fail ELSE
    LET symbol == ReadBytes(orderbookId.rest, 32) IN IF ~symbol.ok THEN Fail ELSE
    LET financialProduct == ReadBytes(symbol.rest, 1) IN IF ~financialProduct.ok THEN Fail ELSE
    LET numberOfDecimalsPrice == ReadBytes(financialProduct.rest, 2) IN IF ~numberOfDecimalsPrice.ok THEN Fail ELSE
    LET numberOfLegs == ReadBytes(numberOfDecimalsPrice.rest, 1) IN IF ~numberOfLegs.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(numberOfLegs.rest, 4) IN IF ~strikePrice.ok THEN Fail ELSE
    LET expirationDate == ReadBytes(strikePrice.rest, 8) IN IF ~expirationDate.ok THEN Fail ELSE
    LET decimalInStrikePrice == ReadBytes(expirationDate.rest, 2) IN IF ~decimalInStrikePrice.ok THEN Fail ELSE
    LET putOrCall == ReadBytes(decimalInStrikePrice.rest, 1) IN IF ~putOrCall.ok THEN Fail ELSE
    LET filler1 == ReadBytes(putOrCall.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    Ok([ orderbookId           |-> orderbookId.value,
         symbol                |-> symbol.value,
         financialProduct      |-> financialProduct.value,
         numberOfDecimalsPrice |-> numberOfDecimalsPrice.value,
         numberOfLegs          |-> numberOfLegs.value,
         strikePrice           |-> strikePrice.value,
         expirationDate        |-> expirationDate.value,
         decimalInStrikePrice  |-> decimalInStrikePrice.value,
         putOrCall             |-> putOrCall.value,
         filler1               |-> filler1.value ], filler1.rest)

ZeroSeriesDefinitionBaseMessage ==
    [ orderbookId           |-> [i \in 1 .. 4 |-> 0],
      symbol                |-> [i \in 1 .. 32 |-> 0],
      financialProduct      |-> [i \in 1 .. 1 |-> 0],
      numberOfDecimalsPrice |-> [i \in 1 .. 2 |-> 0],
      numberOfLegs          |-> [i \in 1 .. 1 |-> 0],
      strikePrice           |-> [i \in 1 .. 4 |-> 0],
      expirationDate        |-> [i \in 1 .. 8 |-> 0],
      decimalInStrikePrice  |-> [i \in 1 .. 2 |-> 0],
      putOrCall             |-> [i \in 1 .. 1 |-> 0],
      filler1               |-> [i \in 1 .. 1 |-> 0] ]

(* Series Definition Base Message at zero, then each field in turn at the values it is checked at *)
CheckedSeriesDefinitionBaseMessage ==
    { ZeroSeriesDefinitionBaseMessage }
        \cup { [ZeroSeriesDefinitionBaseMessage EXCEPT !.orderbookId = one] : one \in Sample(4) }
        \cup { [ZeroSeriesDefinitionBaseMessage EXCEPT !.symbol = one] : one \in Sample(32) }
        \cup { [ZeroSeriesDefinitionBaseMessage EXCEPT !.financialProduct = one] : one \in Sample(1) }
        \cup { [ZeroSeriesDefinitionBaseMessage EXCEPT !.numberOfDecimalsPrice = one] : one \in Sample(2) }
        \cup { [ZeroSeriesDefinitionBaseMessage EXCEPT !.numberOfLegs = one] : one \in Sample(1) }
        \cup { [ZeroSeriesDefinitionBaseMessage EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroSeriesDefinitionBaseMessage EXCEPT !.expirationDate = one] : one \in Sample(8) }
        \cup { [ZeroSeriesDefinitionBaseMessage EXCEPT !.decimalInStrikePrice = one] : one \in Sample(2) }
        \cup { [ZeroSeriesDefinitionBaseMessage EXCEPT !.putOrCall = one] : one \in Sample(1) }
        \cup { [ZeroSeriesDefinitionBaseMessage EXCEPT !.filler1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Series Definition Extended Message: 100 bytes                           *)
(***************************************************************************)

SeriesDefinitionExtendedMessage ==
    [ orderbookId          : Sample(4),
      symbol               : Sample(32),
      country              : Sample(1),
      market               : Sample(1),
      instrumentGroup      : Sample(1),
      modifier             : Sample(1),
      commodityCode        : Sample(2),
      expiryDate           : Sample(2),
      strikePrice          : Sample(4),
      contractSizeExtended : Sample(8),
      isinCode             : Sample(12),
      seriesStatus         : Sample(1),
      effectiveTomorrow    : Sample(1),
      priceQuotationFactor : Sample(4),
      priceMethod          : Sample(1),
      filler1              : Sample(1),
      effectiveExpDate     : Sample(8),
      dateTimeLastTrading  : Sample(8),
      dateTimeFirstTrading : Sample(8) ]

EncodeSeriesDefinitionExtendedMessage(message) ==
    message.orderbookId
        \o message.symbol
        \o message.country
        \o message.market
        \o message.instrumentGroup
        \o message.modifier
        \o message.commodityCode
        \o message.expiryDate
        \o message.strikePrice
        \o message.contractSizeExtended
        \o message.isinCode
        \o message.seriesStatus
        \o message.effectiveTomorrow
        \o message.priceQuotationFactor
        \o message.priceMethod
        \o message.filler1
        \o message.effectiveExpDate
        \o message.dateTimeLastTrading
        \o message.dateTimeFirstTrading

DecodeSeriesDefinitionExtendedMessage(bytes) ==
    LET orderbookId == ReadBytes(bytes, 4) IN IF ~orderbookId.ok THEN Fail ELSE
    LET symbol == ReadBytes(orderbookId.rest, 32) IN IF ~symbol.ok THEN Fail ELSE
    LET country == ReadBytes(symbol.rest, 1) IN IF ~country.ok THEN Fail ELSE
    LET market == ReadBytes(country.rest, 1) IN IF ~market.ok THEN Fail ELSE
    LET instrumentGroup == ReadBytes(market.rest, 1) IN IF ~instrumentGroup.ok THEN Fail ELSE
    LET modifier == ReadBytes(instrumentGroup.rest, 1) IN IF ~modifier.ok THEN Fail ELSE
    LET commodityCode == ReadBytes(modifier.rest, 2) IN IF ~commodityCode.ok THEN Fail ELSE
    LET expiryDate == ReadBytes(commodityCode.rest, 2) IN IF ~expiryDate.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(expiryDate.rest, 4) IN IF ~strikePrice.ok THEN Fail ELSE
    LET contractSizeExtended == ReadBytes(strikePrice.rest, 8) IN IF ~contractSizeExtended.ok THEN Fail ELSE
    LET isinCode == ReadBytes(contractSizeExtended.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET seriesStatus == ReadBytes(isinCode.rest, 1) IN IF ~seriesStatus.ok THEN Fail ELSE
    LET effectiveTomorrow == ReadBytes(seriesStatus.rest, 1) IN IF ~effectiveTomorrow.ok THEN Fail ELSE
    LET priceQuotationFactor == ReadBytes(effectiveTomorrow.rest, 4) IN IF ~priceQuotationFactor.ok THEN Fail ELSE
    LET priceMethod == ReadBytes(priceQuotationFactor.rest, 1) IN IF ~priceMethod.ok THEN Fail ELSE
    LET filler1 == ReadBytes(priceMethod.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET effectiveExpDate == ReadBytes(filler1.rest, 8) IN IF ~effectiveExpDate.ok THEN Fail ELSE
    LET dateTimeLastTrading == ReadBytes(effectiveExpDate.rest, 8) IN IF ~dateTimeLastTrading.ok THEN Fail ELSE
    LET dateTimeFirstTrading == ReadBytes(dateTimeLastTrading.rest, 8) IN IF ~dateTimeFirstTrading.ok THEN Fail ELSE
    Ok([ orderbookId          |-> orderbookId.value,
         symbol               |-> symbol.value,
         country              |-> country.value,
         market               |-> market.value,
         instrumentGroup      |-> instrumentGroup.value,
         modifier             |-> modifier.value,
         commodityCode        |-> commodityCode.value,
         expiryDate           |-> expiryDate.value,
         strikePrice          |-> strikePrice.value,
         contractSizeExtended |-> contractSizeExtended.value,
         isinCode             |-> isinCode.value,
         seriesStatus         |-> seriesStatus.value,
         effectiveTomorrow    |-> effectiveTomorrow.value,
         priceQuotationFactor |-> priceQuotationFactor.value,
         priceMethod          |-> priceMethod.value,
         filler1              |-> filler1.value,
         effectiveExpDate     |-> effectiveExpDate.value,
         dateTimeLastTrading  |-> dateTimeLastTrading.value,
         dateTimeFirstTrading |-> dateTimeFirstTrading.value ], dateTimeFirstTrading.rest)

ZeroSeriesDefinitionExtendedMessage ==
    [ orderbookId          |-> [i \in 1 .. 4 |-> 0],
      symbol               |-> [i \in 1 .. 32 |-> 0],
      country              |-> [i \in 1 .. 1 |-> 0],
      market               |-> [i \in 1 .. 1 |-> 0],
      instrumentGroup      |-> [i \in 1 .. 1 |-> 0],
      modifier             |-> [i \in 1 .. 1 |-> 0],
      commodityCode        |-> [i \in 1 .. 2 |-> 0],
      expiryDate           |-> [i \in 1 .. 2 |-> 0],
      strikePrice          |-> [i \in 1 .. 4 |-> 0],
      contractSizeExtended |-> [i \in 1 .. 8 |-> 0],
      isinCode             |-> [i \in 1 .. 12 |-> 0],
      seriesStatus         |-> [i \in 1 .. 1 |-> 0],
      effectiveTomorrow    |-> [i \in 1 .. 1 |-> 0],
      priceQuotationFactor |-> [i \in 1 .. 4 |-> 0],
      priceMethod          |-> [i \in 1 .. 1 |-> 0],
      filler1              |-> [i \in 1 .. 1 |-> 0],
      effectiveExpDate     |-> [i \in 1 .. 8 |-> 0],
      dateTimeLastTrading  |-> [i \in 1 .. 8 |-> 0],
      dateTimeFirstTrading |-> [i \in 1 .. 8 |-> 0] ]

(* Series Definition Extended Message at zero, then each field in turn at the values it is checked at *)
CheckedSeriesDefinitionExtendedMessage ==
    { ZeroSeriesDefinitionExtendedMessage }
        \cup { [ZeroSeriesDefinitionExtendedMessage EXCEPT !.orderbookId = one] : one \in Sample(4) }
        \cup { [ZeroSeriesDefinitionExtendedMessage EXCEPT !.symbol = one] : one \in Sample(32) }
        \cup { [ZeroSeriesDefinitionExtendedMessage EXCEPT !.country = one] : one \in Sample(1) }
        \cup { [ZeroSeriesDefinitionExtendedMessage EXCEPT !.market = one] : one \in Sample(1) }
        \cup { [ZeroSeriesDefinitionExtendedMessage EXCEPT !.instrumentGroup = one] : one \in Sample(1) }
        \cup { [ZeroSeriesDefinitionExtendedMessage EXCEPT !.modifier = one] : one \in Sample(1) }
        \cup { [ZeroSeriesDefinitionExtendedMessage EXCEPT !.commodityCode = one] : one \in Sample(2) }
        \cup { [ZeroSeriesDefinitionExtendedMessage EXCEPT !.expiryDate = one] : one \in Sample(2) }
        \cup { [ZeroSeriesDefinitionExtendedMessage EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroSeriesDefinitionExtendedMessage EXCEPT !.contractSizeExtended = one] : one \in Sample(8) }
        \cup { [ZeroSeriesDefinitionExtendedMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSeriesDefinitionExtendedMessage EXCEPT !.seriesStatus = one] : one \in Sample(1) }
        \cup { [ZeroSeriesDefinitionExtendedMessage EXCEPT !.effectiveTomorrow = one] : one \in Sample(1) }
        \cup { [ZeroSeriesDefinitionExtendedMessage EXCEPT !.priceQuotationFactor = one] : one \in Sample(4) }
        \cup { [ZeroSeriesDefinitionExtendedMessage EXCEPT !.priceMethod = one] : one \in Sample(1) }
        \cup { [ZeroSeriesDefinitionExtendedMessage EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroSeriesDefinitionExtendedMessage EXCEPT !.effectiveExpDate = one] : one \in Sample(8) }
        \cup { [ZeroSeriesDefinitionExtendedMessage EXCEPT !.dateTimeLastTrading = one] : one \in Sample(8) }
        \cup { [ZeroSeriesDefinitionExtendedMessage EXCEPT !.dateTimeFirstTrading = one] : one \in Sample(8) }

(***************************************************************************)
(* Combination Definition Message: 16 bytes                                *)
(***************************************************************************)

CombinationDefinitionMessage ==
    [ comboOrderbookId : Sample(4),
      legOrderbookId   : Sample(4),
      filler3          : Sample(3),
      legSide          : Sample(1),
      legRatio         : Sample(4) ]

EncodeCombinationDefinitionMessage(message) ==
    message.comboOrderbookId
        \o message.legOrderbookId
        \o message.filler3
        \o message.legSide
        \o message.legRatio

DecodeCombinationDefinitionMessage(bytes) ==
    LET comboOrderbookId == ReadBytes(bytes, 4) IN IF ~comboOrderbookId.ok THEN Fail ELSE
    LET legOrderbookId == ReadBytes(comboOrderbookId.rest, 4) IN IF ~legOrderbookId.ok THEN Fail ELSE
    LET filler3 == ReadBytes(legOrderbookId.rest, 3) IN IF ~filler3.ok THEN Fail ELSE
    LET legSide == ReadBytes(filler3.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET legRatio == ReadBytes(legSide.rest, 4) IN IF ~legRatio.ok THEN Fail ELSE
    Ok([ comboOrderbookId |-> comboOrderbookId.value,
         legOrderbookId   |-> legOrderbookId.value,
         filler3          |-> filler3.value,
         legSide          |-> legSide.value,
         legRatio         |-> legRatio.value ], legRatio.rest)

ZeroCombinationDefinitionMessage ==
    [ comboOrderbookId |-> [i \in 1 .. 4 |-> 0],
      legOrderbookId   |-> [i \in 1 .. 4 |-> 0],
      filler3          |-> [i \in 1 .. 3 |-> 0],
      legSide          |-> [i \in 1 .. 1 |-> 0],
      legRatio         |-> [i \in 1 .. 4 |-> 0] ]

(* Combination Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedCombinationDefinitionMessage ==
    { ZeroCombinationDefinitionMessage }
        \cup { [ZeroCombinationDefinitionMessage EXCEPT !.comboOrderbookId = one] : one \in Sample(4) }
        \cup { [ZeroCombinationDefinitionMessage EXCEPT !.legOrderbookId = one] : one \in Sample(4) }
        \cup { [ZeroCombinationDefinitionMessage EXCEPT !.filler3 = one] : one \in Sample(3) }
        \cup { [ZeroCombinationDefinitionMessage EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroCombinationDefinitionMessage EXCEPT !.legRatio = one] : one \in Sample(4) }

(***************************************************************************)
(* Refresh Complete: 4 bytes                                               *)
(***************************************************************************)

RefreshComplete ==
    [ lastSeqNum : Sample(4) ]

EncodeRefreshComplete(message) ==
    message.lastSeqNum

DecodeRefreshComplete(bytes) ==
    LET lastSeqNum == ReadBytes(bytes, 4) IN IF ~lastSeqNum.ok THEN Fail ELSE
    Ok([ lastSeqNum |-> lastSeqNum.value ], lastSeqNum.rest)

ZeroRefreshComplete ==
    [ lastSeqNum |-> [i \in 1 .. 4 |-> 0] ]

(* Refresh Complete at zero, then each field in turn at the values it is checked at *)
CheckedRefreshComplete ==
    { ZeroRefreshComplete }
        \cup { [ZeroRefreshComplete EXCEPT !.lastSeqNum = one] : one \in Sample(4) }

(***************************************************************************)
(* Market Status Message: 48 bytes                                         *)
(***************************************************************************)

MarketStatusMessage ==
    [ stateLevel           : Sample(2),
      market               : Sample(1),
      instrument           : Sample(1),
      orderbookId          : Sample(4),
      commodityCode        : Sample(2),
      filler2              : Sample(2),
      actualStartDate      : Sample(8),
      actualStartTime      : Sample(6),
      plannedStartDate     : Sample(8),
      plannedStartTime     : Sample(6),
      secondsToStateChange : Sample(2),
      state                : Sample(2),
      priority             : Sample(1),
      filler3              : Sample(3) ]

EncodeMarketStatusMessage(message) ==
    message.stateLevel
        \o message.market
        \o message.instrument
        \o message.orderbookId
        \o message.commodityCode
        \o message.filler2
        \o message.actualStartDate
        \o message.actualStartTime
        \o message.plannedStartDate
        \o message.plannedStartTime
        \o message.secondsToStateChange
        \o message.state
        \o message.priority
        \o message.filler3

DecodeMarketStatusMessage(bytes) ==
    LET stateLevel == ReadBytes(bytes, 2) IN IF ~stateLevel.ok THEN Fail ELSE
    LET market == ReadBytes(stateLevel.rest, 1) IN IF ~market.ok THEN Fail ELSE
    LET instrument == ReadBytes(market.rest, 1) IN IF ~instrument.ok THEN Fail ELSE
    LET orderbookId == ReadBytes(instrument.rest, 4) IN IF ~orderbookId.ok THEN Fail ELSE
    LET commodityCode == ReadBytes(orderbookId.rest, 2) IN IF ~commodityCode.ok THEN Fail ELSE
    LET filler2 == ReadBytes(commodityCode.rest, 2) IN IF ~filler2.ok THEN Fail ELSE
    LET actualStartDate == ReadBytes(filler2.rest, 8) IN IF ~actualStartDate.ok THEN Fail ELSE
    LET actualStartTime == ReadBytes(actualStartDate.rest, 6) IN IF ~actualStartTime.ok THEN Fail ELSE
    LET plannedStartDate == ReadBytes(actualStartTime.rest, 8) IN IF ~plannedStartDate.ok THEN Fail ELSE
    LET plannedStartTime == ReadBytes(plannedStartDate.rest, 6) IN IF ~plannedStartTime.ok THEN Fail ELSE
    LET secondsToStateChange == ReadBytes(plannedStartTime.rest, 2) IN IF ~secondsToStateChange.ok THEN Fail ELSE
    LET state == ReadBytes(secondsToStateChange.rest, 2) IN IF ~state.ok THEN Fail ELSE
    LET priority == ReadBytes(state.rest, 1) IN IF ~priority.ok THEN Fail ELSE
    LET filler3 == ReadBytes(priority.rest, 3) IN IF ~filler3.ok THEN Fail ELSE
    Ok([ stateLevel           |-> stateLevel.value,
         market               |-> market.value,
         instrument           |-> instrument.value,
         orderbookId          |-> orderbookId.value,
         commodityCode        |-> commodityCode.value,
         filler2              |-> filler2.value,
         actualStartDate      |-> actualStartDate.value,
         actualStartTime      |-> actualStartTime.value,
         plannedStartDate     |-> plannedStartDate.value,
         plannedStartTime     |-> plannedStartTime.value,
         secondsToStateChange |-> secondsToStateChange.value,
         state                |-> state.value,
         priority             |-> priority.value,
         filler3              |-> filler3.value ], filler3.rest)

ZeroMarketStatusMessage ==
    [ stateLevel           |-> [i \in 1 .. 2 |-> 0],
      market               |-> [i \in 1 .. 1 |-> 0],
      instrument           |-> [i \in 1 .. 1 |-> 0],
      orderbookId          |-> [i \in 1 .. 4 |-> 0],
      commodityCode        |-> [i \in 1 .. 2 |-> 0],
      filler2              |-> [i \in 1 .. 2 |-> 0],
      actualStartDate      |-> [i \in 1 .. 8 |-> 0],
      actualStartTime      |-> [i \in 1 .. 6 |-> 0],
      plannedStartDate     |-> [i \in 1 .. 8 |-> 0],
      plannedStartTime     |-> [i \in 1 .. 6 |-> 0],
      secondsToStateChange |-> [i \in 1 .. 2 |-> 0],
      state                |-> [i \in 1 .. 2 |-> 0],
      priority             |-> [i \in 1 .. 1 |-> 0],
      filler3              |-> [i \in 1 .. 3 |-> 0] ]

(* Market Status Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketStatusMessage ==
    { ZeroMarketStatusMessage }
        \cup { [ZeroMarketStatusMessage EXCEPT !.stateLevel = one] : one \in Sample(2) }
        \cup { [ZeroMarketStatusMessage EXCEPT !.market = one] : one \in Sample(1) }
        \cup { [ZeroMarketStatusMessage EXCEPT !.instrument = one] : one \in Sample(1) }
        \cup { [ZeroMarketStatusMessage EXCEPT !.orderbookId = one] : one \in Sample(4) }
        \cup { [ZeroMarketStatusMessage EXCEPT !.commodityCode = one] : one \in Sample(2) }
        \cup { [ZeroMarketStatusMessage EXCEPT !.filler2 = one] : one \in Sample(2) }
        \cup { [ZeroMarketStatusMessage EXCEPT !.actualStartDate = one] : one \in Sample(8) }
        \cup { [ZeroMarketStatusMessage EXCEPT !.actualStartTime = one] : one \in Sample(6) }
        \cup { [ZeroMarketStatusMessage EXCEPT !.plannedStartDate = one] : one \in Sample(8) }
        \cup { [ZeroMarketStatusMessage EXCEPT !.plannedStartTime = one] : one \in Sample(6) }
        \cup { [ZeroMarketStatusMessage EXCEPT !.secondsToStateChange = one] : one \in Sample(2) }
        \cup { [ZeroMarketStatusMessage EXCEPT !.state = one] : one \in Sample(2) }
        \cup { [ZeroMarketStatusMessage EXCEPT !.priority = one] : one \in Sample(1) }
        \cup { [ZeroMarketStatusMessage EXCEPT !.filler3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Series Status Message: 8 bytes                                          *)
(***************************************************************************)

SeriesStatusMessage ==
    [ orderbookId         : Sample(4),
      suspensionIndicator : Sample(1),
      seriesStatus        : Sample(1),
      filler2             : Sample(2) ]

EncodeSeriesStatusMessage(message) ==
    message.orderbookId
        \o message.suspensionIndicator
        \o message.seriesStatus
        \o message.filler2

DecodeSeriesStatusMessage(bytes) ==
    LET orderbookId == ReadBytes(bytes, 4) IN IF ~orderbookId.ok THEN Fail ELSE
    LET suspensionIndicator == ReadBytes(orderbookId.rest, 1) IN IF ~suspensionIndicator.ok THEN Fail ELSE
    LET seriesStatus == ReadBytes(suspensionIndicator.rest, 1) IN IF ~seriesStatus.ok THEN Fail ELSE
    LET filler2 == ReadBytes(seriesStatus.rest, 2) IN IF ~filler2.ok THEN Fail ELSE
    Ok([ orderbookId         |-> orderbookId.value,
         suspensionIndicator |-> suspensionIndicator.value,
         seriesStatus        |-> seriesStatus.value,
         filler2             |-> filler2.value ], filler2.rest)

ZeroSeriesStatusMessage ==
    [ orderbookId         |-> [i \in 1 .. 4 |-> 0],
      suspensionIndicator |-> [i \in 1 .. 1 |-> 0],
      seriesStatus        |-> [i \in 1 .. 1 |-> 0],
      filler2             |-> [i \in 1 .. 2 |-> 0] ]

(* Series Status Message at zero, then each field in turn at the values it is checked at *)
CheckedSeriesStatusMessage ==
    { ZeroSeriesStatusMessage }
        \cup { [ZeroSeriesStatusMessage EXCEPT !.orderbookId = one] : one \in Sample(4) }
        \cup { [ZeroSeriesStatusMessage EXCEPT !.suspensionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSeriesStatusMessage EXCEPT !.seriesStatus = one] : one \in Sample(1) }
        \cup { [ZeroSeriesStatusMessage EXCEPT !.filler2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Commodity Status Message: 4 bytes                                       *)
(***************************************************************************)

CommodityStatusMessage ==
    [ commodityCode : Sample(2),
      suspended     : Sample(1),
      locked        : Sample(1) ]

EncodeCommodityStatusMessage(message) ==
    message.commodityCode
        \o message.suspended
        \o message.locked

DecodeCommodityStatusMessage(bytes) ==
    LET commodityCode == ReadBytes(bytes, 2) IN IF ~commodityCode.ok THEN Fail ELSE
    LET suspended == ReadBytes(commodityCode.rest, 1) IN IF ~suspended.ok THEN Fail ELSE
    LET locked == ReadBytes(suspended.rest, 1) IN IF ~locked.ok THEN Fail ELSE
    Ok([ commodityCode |-> commodityCode.value,
         suspended     |-> suspended.value,
         locked        |-> locked.value ], locked.rest)

ZeroCommodityStatusMessage ==
    [ commodityCode |-> [i \in 1 .. 2 |-> 0],
      suspended     |-> [i \in 1 .. 1 |-> 0],
      locked        |-> [i \in 1 .. 1 |-> 0] ]

(* Commodity Status Message at zero, then each field in turn at the values it is checked at *)
CheckedCommodityStatusMessage ==
    { ZeroCommodityStatusMessage }
        \cup { [ZeroCommodityStatusMessage EXCEPT !.commodityCode = one] : one \in Sample(2) }
        \cup { [ZeroCommodityStatusMessage EXCEPT !.suspended = one] : one \in Sample(1) }
        \cup { [ZeroCommodityStatusMessage EXCEPT !.locked = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Statistics Message: 56 bytes                                      *)
(***************************************************************************)

TradeStatisticsMessage ==
    [ orderbookId                 : Sample(4),
      price                       : Sample(4),
      dealSource                  : Sample(1),
      session                     : Sample(1),
      filler2                     : Sample(2),
      statisticsAggregateQuantity : Sample(8),
      open                        : Sample(4),
      high                        : Sample(4),
      low                         : Sample(4),
      filler4                     : Sample(4),
      tradeReportVolume           : Sample(8),
      dealCount                   : Sample(4),
      turnover                    : Sample(8) ]

EncodeTradeStatisticsMessage(message) ==
    message.orderbookId
        \o message.price
        \o message.dealSource
        \o message.session
        \o message.filler2
        \o message.statisticsAggregateQuantity
        \o message.open
        \o message.high
        \o message.low
        \o message.filler4
        \o message.tradeReportVolume
        \o message.dealCount
        \o message.turnover

DecodeTradeStatisticsMessage(bytes) ==
    LET orderbookId == ReadBytes(bytes, 4) IN IF ~orderbookId.ok THEN Fail ELSE
    LET price == ReadBytes(orderbookId.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET dealSource == ReadBytes(price.rest, 1) IN IF ~dealSource.ok THEN Fail ELSE
    LET session == ReadBytes(dealSource.rest, 1) IN IF ~session.ok THEN Fail ELSE
    LET filler2 == ReadBytes(session.rest, 2) IN IF ~filler2.ok THEN Fail ELSE
    LET statisticsAggregateQuantity == ReadBytes(filler2.rest, 8) IN IF ~statisticsAggregateQuantity.ok THEN Fail ELSE
    LET open == ReadBytes(statisticsAggregateQuantity.rest, 4) IN IF ~open.ok THEN Fail ELSE
    LET high == ReadBytes(open.rest, 4) IN IF ~high.ok THEN Fail ELSE
    LET low == ReadBytes(high.rest, 4) IN IF ~low.ok THEN Fail ELSE
    LET filler4 == ReadBytes(low.rest, 4) IN IF ~filler4.ok THEN Fail ELSE
    LET tradeReportVolume == ReadBytes(filler4.rest, 8) IN IF ~tradeReportVolume.ok THEN Fail ELSE
    LET dealCount == ReadBytes(tradeReportVolume.rest, 4) IN IF ~dealCount.ok THEN Fail ELSE
    LET turnover == ReadBytes(dealCount.rest, 8) IN IF ~turnover.ok THEN Fail ELSE
    Ok([ orderbookId                 |-> orderbookId.value,
         price                       |-> price.value,
         dealSource                  |-> dealSource.value,
         session                     |-> session.value,
         filler2                     |-> filler2.value,
         statisticsAggregateQuantity |-> statisticsAggregateQuantity.value,
         open                        |-> open.value,
         high                        |-> high.value,
         low                         |-> low.value,
         filler4                     |-> filler4.value,
         tradeReportVolume           |-> tradeReportVolume.value,
         dealCount                   |-> dealCount.value,
         turnover                    |-> turnover.value ], turnover.rest)

ZeroTradeStatisticsMessage ==
    [ orderbookId                 |-> [i \in 1 .. 4 |-> 0],
      price                       |-> [i \in 1 .. 4 |-> 0],
      dealSource                  |-> [i \in 1 .. 1 |-> 0],
      session                     |-> [i \in 1 .. 1 |-> 0],
      filler2                     |-> [i \in 1 .. 2 |-> 0],
      statisticsAggregateQuantity |-> [i \in 1 .. 8 |-> 0],
      open                        |-> [i \in 1 .. 4 |-> 0],
      high                        |-> [i \in 1 .. 4 |-> 0],
      low                         |-> [i \in 1 .. 4 |-> 0],
      filler4                     |-> [i \in 1 .. 4 |-> 0],
      tradeReportVolume           |-> [i \in 1 .. 8 |-> 0],
      dealCount                   |-> [i \in 1 .. 4 |-> 0],
      turnover                    |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Statistics Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeStatisticsMessage ==
    { ZeroTradeStatisticsMessage }
        \cup { [ZeroTradeStatisticsMessage EXCEPT !.orderbookId = one] : one \in Sample(4) }
        \cup { [ZeroTradeStatisticsMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroTradeStatisticsMessage EXCEPT !.dealSource = one] : one \in Sample(1) }
        \cup { [ZeroTradeStatisticsMessage EXCEPT !.session = one] : one \in Sample(1) }
        \cup { [ZeroTradeStatisticsMessage EXCEPT !.filler2 = one] : one \in Sample(2) }
        \cup { [ZeroTradeStatisticsMessage EXCEPT !.statisticsAggregateQuantity = one] : one \in Sample(8) }
        \cup { [ZeroTradeStatisticsMessage EXCEPT !.open = one] : one \in Sample(4) }
        \cup { [ZeroTradeStatisticsMessage EXCEPT !.high = one] : one \in Sample(4) }
        \cup { [ZeroTradeStatisticsMessage EXCEPT !.low = one] : one \in Sample(4) }
        \cup { [ZeroTradeStatisticsMessage EXCEPT !.filler4 = one] : one \in Sample(4) }
        \cup { [ZeroTradeStatisticsMessage EXCEPT !.tradeReportVolume = one] : one \in Sample(8) }
        \cup { [ZeroTradeStatisticsMessage EXCEPT !.dealCount = one] : one \in Sample(4) }
        \cup { [ZeroTradeStatisticsMessage EXCEPT !.turnover = one] : one \in Sample(8) }

(***************************************************************************)
(* Payload, selected by Msg Type                                           *)
(***************************************************************************)

AggregateOrderBookUpdateMessageCode == 353  \* 0x161
CalculatedOpeningPriceMessageCode == 364  \* 0x16c
SequenceResetCode == 100  \* 0x64
DisasterRecoverySignalMessageCode == 105  \* 0x69
MarketAlertMessageCode == 323  \* 0x143
OpenInterestMessageCode == 366  \* 0x16e
QuoteRequestCode == 336  \* 0x150
CommodityDefinitionMessageCode == 301  \* 0x12d
ClassDefinitionMessageCode == 302  \* 0x12e
SeriesDefinitionBaseMessageCode == 303  \* 0x12f
SeriesDefinitionExtendedMessageCode == 304  \* 0x130
CombinationDefinitionMessageCode == 305  \* 0x131
RefreshCompleteCode == 203  \* 0xcb
MarketStatusMessageCode == 320  \* 0x140
SeriesStatusMessageCode == 321  \* 0x141
CommodityStatusMessageCode == 322  \* 0x142
TradeStatisticsMessageCode == 360  \* 0x168

Payload ==
    [ tag : {AggregateOrderBookUpdateMessageCode}, body : AggregateOrderBookUpdateMessage ]
        \cup [ tag : {CalculatedOpeningPriceMessageCode}, body : CalculatedOpeningPriceMessage ]
        \cup [ tag : {SequenceResetCode}, body : SequenceReset ]
        \cup [ tag : {DisasterRecoverySignalMessageCode}, body : DisasterRecoverySignalMessage ]
        \cup [ tag : {MarketAlertMessageCode}, body : MarketAlertMessage ]
        \cup [ tag : {OpenInterestMessageCode}, body : OpenInterestMessage ]
        \cup [ tag : {QuoteRequestCode}, body : QuoteRequest ]
        \cup [ tag : {CommodityDefinitionMessageCode}, body : CommodityDefinitionMessage ]
        \cup [ tag : {ClassDefinitionMessageCode}, body : ClassDefinitionMessage ]
        \cup [ tag : {SeriesDefinitionBaseMessageCode}, body : SeriesDefinitionBaseMessage ]
        \cup [ tag : {SeriesDefinitionExtendedMessageCode}, body : SeriesDefinitionExtendedMessage ]
        \cup [ tag : {CombinationDefinitionMessageCode}, body : CombinationDefinitionMessage ]
        \cup [ tag : {RefreshCompleteCode}, body : RefreshComplete ]
        \cup [ tag : {MarketStatusMessageCode}, body : MarketStatusMessage ]
        \cup [ tag : {SeriesStatusMessageCode}, body : SeriesStatusMessage ]
        \cup [ tag : {CommodityStatusMessageCode}, body : CommodityStatusMessage ]
        \cup [ tag : {TradeStatisticsMessageCode}, body : TradeStatisticsMessage ]

EncodePayload(message) ==
    CASE message.tag = AggregateOrderBookUpdateMessageCode -> EncodeAggregateOrderBookUpdateMessage(message.body)
      [] message.tag = CalculatedOpeningPriceMessageCode -> EncodeCalculatedOpeningPriceMessage(message.body)
      [] message.tag = SequenceResetCode -> EncodeSequenceReset(message.body)
      [] message.tag = DisasterRecoverySignalMessageCode -> EncodeDisasterRecoverySignalMessage(message.body)
      [] message.tag = MarketAlertMessageCode -> EncodeMarketAlertMessage(message.body)
      [] message.tag = OpenInterestMessageCode -> EncodeOpenInterestMessage(message.body)
      [] message.tag = QuoteRequestCode -> EncodeQuoteRequest(message.body)
      [] message.tag = CommodityDefinitionMessageCode -> EncodeCommodityDefinitionMessage(message.body)
      [] message.tag = ClassDefinitionMessageCode -> EncodeClassDefinitionMessage(message.body)
      [] message.tag = SeriesDefinitionBaseMessageCode -> EncodeSeriesDefinitionBaseMessage(message.body)
      [] message.tag = SeriesDefinitionExtendedMessageCode -> EncodeSeriesDefinitionExtendedMessage(message.body)
      [] message.tag = CombinationDefinitionMessageCode -> EncodeCombinationDefinitionMessage(message.body)
      [] message.tag = RefreshCompleteCode -> EncodeRefreshComplete(message.body)
      [] message.tag = MarketStatusMessageCode -> EncodeMarketStatusMessage(message.body)
      [] message.tag = SeriesStatusMessageCode -> EncodeSeriesStatusMessage(message.body)
      [] message.tag = CommodityStatusMessageCode -> EncodeCommodityStatusMessage(message.body)
      [] message.tag = TradeStatisticsMessageCode -> EncodeTradeStatisticsMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = AggregateOrderBookUpdateMessageCode -> DecodeAggregateOrderBookUpdateMessage(bytes)
              [] tag = CalculatedOpeningPriceMessageCode -> DecodeCalculatedOpeningPriceMessage(bytes)
              [] tag = SequenceResetCode -> DecodeSequenceReset(bytes)
              [] tag = DisasterRecoverySignalMessageCode -> DecodeDisasterRecoverySignalMessage(bytes)
              [] tag = MarketAlertMessageCode -> DecodeMarketAlertMessage(bytes)
              [] tag = OpenInterestMessageCode -> DecodeOpenInterestMessage(bytes)
              [] tag = QuoteRequestCode -> DecodeQuoteRequest(bytes)
              [] tag = CommodityDefinitionMessageCode -> DecodeCommodityDefinitionMessage(bytes)
              [] tag = ClassDefinitionMessageCode -> DecodeClassDefinitionMessage(bytes)
              [] tag = SeriesDefinitionBaseMessageCode -> DecodeSeriesDefinitionBaseMessage(bytes)
              [] tag = SeriesDefinitionExtendedMessageCode -> DecodeSeriesDefinitionExtendedMessage(bytes)
              [] tag = CombinationDefinitionMessageCode -> DecodeCombinationDefinitionMessage(bytes)
              [] tag = RefreshCompleteCode -> DecodeRefreshComplete(bytes)
              [] tag = MarketStatusMessageCode -> DecodeMarketStatusMessage(bytes)
              [] tag = SeriesStatusMessageCode -> DecodeSeriesStatusMessage(bytes)
              [] tag = CommodityStatusMessageCode -> DecodeCommodityStatusMessage(bytes)
              [] tag = TradeStatisticsMessageCode -> DecodeTradeStatisticsMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> AggregateOrderBookUpdateMessageCode, body |-> ZeroAggregateOrderBookUpdateMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> AggregateOrderBookUpdateMessageCode, body |-> one] : one \in CheckedAggregateOrderBookUpdateMessage }
        \cup { [tag |-> CalculatedOpeningPriceMessageCode, body |-> one] : one \in CheckedCalculatedOpeningPriceMessage }
        \cup { [tag |-> SequenceResetCode, body |-> one] : one \in CheckedSequenceReset }
        \cup { [tag |-> DisasterRecoverySignalMessageCode, body |-> one] : one \in CheckedDisasterRecoverySignalMessage }
        \cup { [tag |-> MarketAlertMessageCode, body |-> one] : one \in CheckedMarketAlertMessage }
        \cup { [tag |-> OpenInterestMessageCode, body |-> one] : one \in CheckedOpenInterestMessage }
        \cup { [tag |-> QuoteRequestCode, body |-> one] : one \in CheckedQuoteRequest }
        \cup { [tag |-> CommodityDefinitionMessageCode, body |-> one] : one \in CheckedCommodityDefinitionMessage }
        \cup { [tag |-> ClassDefinitionMessageCode, body |-> one] : one \in CheckedClassDefinitionMessage }
        \cup { [tag |-> SeriesDefinitionBaseMessageCode, body |-> one] : one \in CheckedSeriesDefinitionBaseMessage }
        \cup { [tag |-> SeriesDefinitionExtendedMessageCode, body |-> one] : one \in CheckedSeriesDefinitionExtendedMessage }
        \cup { [tag |-> CombinationDefinitionMessageCode, body |-> one] : one \in CheckedCombinationDefinitionMessage }
        \cup { [tag |-> RefreshCompleteCode, body |-> one] : one \in CheckedRefreshComplete }
        \cup { [tag |-> MarketStatusMessageCode, body |-> one] : one \in CheckedMarketStatusMessage }
        \cup { [tag |-> SeriesStatusMessageCode, body |-> one] : one \in CheckedSeriesStatusMessage }
        \cup { [tag |-> CommodityStatusMessageCode, body |-> one] : one \in CheckedCommodityStatusMessage }
        \cup { [tag |-> TradeStatisticsMessageCode, body |-> one] : one \in CheckedTradeStatisticsMessage }

(***************************************************************************)
(* Message, framed by Msg Size                                             *)
(***************************************************************************)

Message ==
    [ payload : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntLE(message.payload.tag, 2)
        \o EncodePayload(message.payload)

(* Msg Size counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeMessageBody(bytes) ==
    LET msgType == ReadUIntLE(bytes, 2) IN IF ~msgType.ok THEN Fail ELSE
    LET payload == DecodePayload(msgType.value, msgType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> AggregateOrderBookUpdateMessageCode, body |-> ZeroAggregateOrderBookUpdateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CalculatedOpeningPriceMessageCode, body |-> ZeroCalculatedOpeningPriceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SequenceResetCode, body |-> ZeroSequenceReset]],
      [ZeroMessage EXCEPT !.payload = [tag |-> DisasterRecoverySignalMessageCode, body |-> ZeroDisasterRecoverySignalMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MarketAlertMessageCode, body |-> ZeroMarketAlertMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OpenInterestMessageCode, body |-> ZeroOpenInterestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> QuoteRequestCode, body |-> ZeroQuoteRequest]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CommodityDefinitionMessageCode, body |-> ZeroCommodityDefinitionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ClassDefinitionMessageCode, body |-> ZeroClassDefinitionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SeriesDefinitionBaseMessageCode, body |-> ZeroSeriesDefinitionBaseMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SeriesDefinitionExtendedMessageCode, body |-> ZeroSeriesDefinitionExtendedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CombinationDefinitionMessageCode, body |-> ZeroCombinationDefinitionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RefreshCompleteCode, body |-> ZeroRefreshComplete]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MarketStatusMessageCode, body |-> ZeroMarketStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SeriesStatusMessageCode, body |-> ZeroSeriesStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CommodityStatusMessageCode, body |-> ZeroCommodityStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeStatisticsMessageCode, body |-> ZeroTradeStatisticsMessage]] }

(***************************************************************************)
(* Message Buffer, selected by Compression Mode                            *)
(***************************************************************************)

MessageBufferZlibCode == 1  \* 0x01
MessageBufferPlainCode == 0  \* stands for every value no other case names

MessageBufferBody ==
    [ tag : {MessageBufferZlibCode}, body : MessageBufferZlib ]
        \cup [ tag : (0 .. 255) \ {MessageBufferZlibCode}, body : SampleLists(OneMessage) ]

EncodeMessageBufferBody(message) ==
    CASE message.tag = MessageBufferZlibCode -> EncodeMessageBufferZlib(message.body)
      [] OTHER -> EncodeMessageList(message.body)

(* How many Message a Message Buffer holds, which is what Msg Count states. *)
(* A case that is no run of them says nothing about the number, so it holds whatever was stated. *)
CountMessageBufferBody(choice, stated) ==
    CASE choice.tag = MessageBufferZlibCode -> stated
      [] OTHER -> Len(choice.body)

DecodeMessageBufferBody(tag, count, bytes) ==
    LET read ==
            CASE tag = MessageBufferZlibCode -> DecodeMessageBufferZlib(bytes)
              [] OTHER -> ReadMessageList(bytes, count)
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroMessageBufferBody == [tag |-> MessageBufferZlibCode, body |-> ZeroMessageBufferZlib]

(* Each Message Buffer in turn, at the values the message it names is checked at *)
CheckedMessageBufferBody ==
    { [tag |-> MessageBufferZlibCode, body |-> one] : one \in CheckedMessageBufferZlib }
        \cup [ tag : {0, 1, 255} \ {MessageBufferZlibCode}, body : SampleLists(OneMessage) ]

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ pktSize       : Sample(2),
      msgCount      : 0 .. 255,
      seqNum        : Sample(4),
      sendTime      : Sample(8),
      messageBuffer : MessageBufferBody ]

EncodePacket(message) ==
    message.pktSize
        \o EncodeUIntBE(message.msgCount, 1)
        \o EncodeUIntBE(message.messageBuffer.tag, 1)
        \o message.seqNum
        \o message.sendTime
        \o EncodeMessageBufferBody(message.messageBuffer)

DecodePacket(bytes) ==
    LET pktSize == ReadBytes(bytes, 2) IN IF ~pktSize.ok THEN Fail ELSE
    LET msgCount == ReadUIntBE(pktSize.rest, 1) IN IF ~msgCount.ok THEN Fail ELSE
    LET compressionMode == ReadUIntBE(msgCount.rest, 1) IN IF ~compressionMode.ok THEN Fail ELSE
    LET seqNum == ReadBytes(compressionMode.rest, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET sendTime == ReadBytes(seqNum.rest, 8) IN IF ~sendTime.ok THEN Fail ELSE
    LET messageBuffer == DecodeMessageBufferBody(compressionMode.value, msgCount.value, sendTime.rest) IN IF ~messageBuffer.ok THEN Fail ELSE
    Ok([ pktSize       |-> pktSize.value,
         msgCount      |-> msgCount.value,
         seqNum        |-> seqNum.value,
         sendTime      |-> sendTime.value,
         messageBuffer |-> messageBuffer.value ], messageBuffer.rest)

ZeroPacket ==
    [ pktSize       |-> [i \in 1 .. 2 |-> 0],
      msgCount      |-> 0,
      seqNum        |-> [i \in 1 .. 4 |-> 0],
      sendTime      |-> [i \in 1 .. 8 |-> 0],
      messageBuffer |-> ZeroMessageBufferBody ]

(* Packet at zero, then each field in turn at the values it is checked at *)
(* Msg Count is varied with the Message Buffer it counts, which is read as many as it says *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.pktSize = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.msgCount = one] : one \in {0, 1, 255} }
        \cup { [ZeroPacket EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.sendTime = one] : one \in Sample(8) }
        \cup { [ZeroPacket EXCEPT !.msgCount = CountMessageBufferBody(one, 0), !.messageBuffer = one] : one \in CheckedMessageBufferBody }

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

(* Every Book Entry decodes back to what was encoded, and leaves nothing over *)
RoundTripBookEntry ==
    \A message \in CheckedBookEntry :
        LET read == DecodeBookEntry(EncodeBookEntry(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Aggregate Order Book Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAggregateOrderBookUpdateMessage ==
    \A message \in CheckedAggregateOrderBookUpdateMessage :
        LET read == DecodeAggregateOrderBookUpdateMessage(EncodeAggregateOrderBookUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Calculated Opening Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCalculatedOpeningPriceMessage ==
    \A message \in CheckedCalculatedOpeningPriceMessage :
        LET read == DecodeCalculatedOpeningPriceMessage(EncodeCalculatedOpeningPriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sequence Reset decodes back to what was encoded, and leaves nothing over *)
RoundTripSequenceReset ==
    \A message \in CheckedSequenceReset :
        LET read == DecodeSequenceReset(EncodeSequenceReset(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Disaster Recovery Signal Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDisasterRecoverySignalMessage ==
    \A message \in CheckedDisasterRecoverySignalMessage :
        LET read == DecodeDisasterRecoverySignalMessage(EncodeDisasterRecoverySignalMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Alert Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketAlertMessage ==
    \A message \in CheckedMarketAlertMessage :
        LET read == DecodeMarketAlertMessage(EncodeMarketAlertMessage(message))
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

(* Every Quote Request decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteRequest ==
    \A message \in CheckedQuoteRequest :
        LET read == DecodeQuoteRequest(EncodeQuoteRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Commodity Definition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCommodityDefinitionMessage ==
    \A message \in CheckedCommodityDefinitionMessage :
        LET read == DecodeCommodityDefinitionMessage(EncodeCommodityDefinitionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Class Definition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripClassDefinitionMessage ==
    \A message \in CheckedClassDefinitionMessage :
        LET read == DecodeClassDefinitionMessage(EncodeClassDefinitionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Series Definition Base Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSeriesDefinitionBaseMessage ==
    \A message \in CheckedSeriesDefinitionBaseMessage :
        LET read == DecodeSeriesDefinitionBaseMessage(EncodeSeriesDefinitionBaseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Series Definition Extended Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSeriesDefinitionExtendedMessage ==
    \A message \in CheckedSeriesDefinitionExtendedMessage :
        LET read == DecodeSeriesDefinitionExtendedMessage(EncodeSeriesDefinitionExtendedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Combination Definition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCombinationDefinitionMessage ==
    \A message \in CheckedCombinationDefinitionMessage :
        LET read == DecodeCombinationDefinitionMessage(EncodeCombinationDefinitionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Refresh Complete decodes back to what was encoded, and leaves nothing over *)
RoundTripRefreshComplete ==
    \A message \in CheckedRefreshComplete :
        LET read == DecodeRefreshComplete(EncodeRefreshComplete(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketStatusMessage ==
    \A message \in CheckedMarketStatusMessage :
        LET read == DecodeMarketStatusMessage(EncodeMarketStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Series Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSeriesStatusMessage ==
    \A message \in CheckedSeriesStatusMessage :
        LET read == DecodeSeriesStatusMessage(EncodeSeriesStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Commodity Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCommodityStatusMessage ==
    \A message \in CheckedCommodityStatusMessage :
        LET read == DecodeCommodityStatusMessage(EncodeCommodityStatusMessage(message))
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

(* A Payload is selected by the Msg Type it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET sent == EncodePayload(message)
            read == DecodePayload(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Message Buffer is selected by the Compression Mode it is written under *)
SelectsMessageBufferBody ==
    \A message \in CheckedMessageBufferBody :
        LET sent == EncodeMessageBufferBody(message)
            read == DecodeMessageBufferBody(message.tag, CountMessageBufferBody(message, 0), sent)
        IN  read.ok /\ read.value.tag = message.tag

(* Msg Size is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
