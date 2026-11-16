--------------- MODULE HkexDerivatives_FullTickRefresh_v2_2 ----------------
(***************************************************************************)
(* Hong Kong Exchanges and Clearing Orion Market Data Derivatives FullTick *)
(* Refresh v2.2                                                            *)
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
(* Add Order: 40 bytes                                                     *)
(***************************************************************************)

AddOrder ==
    [ orderbookId       : Sample(4),
      orderId           : Sample(8),
      price             : Sample(8),
      quantity          : Sample(4),
      side              : Sample(1),
      lotType           : Sample(1),
      orderType         : Sample(1),
      orderBookPosition : Sample(4),
      businessTime      : Sample(8),
      filler1           : Sample(1) ]

EncodeAddOrder(message) ==
    message.orderbookId
        \o message.orderId
        \o message.price
        \o message.quantity
        \o message.side
        \o message.lotType
        \o message.orderType
        \o message.orderBookPosition
        \o message.businessTime
        \o message.filler1

DecodeAddOrder(bytes) ==
    LET orderbookId == ReadBytes(bytes, 4) IN IF ~orderbookId.ok THEN Fail ELSE
    LET orderId == ReadBytes(orderbookId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET price == ReadBytes(orderId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET side == ReadBytes(quantity.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET lotType == ReadBytes(side.rest, 1) IN IF ~lotType.ok THEN Fail ELSE
    LET orderType == ReadBytes(lotType.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET orderBookPosition == ReadBytes(orderType.rest, 4) IN IF ~orderBookPosition.ok THEN Fail ELSE
    LET businessTime == ReadBytes(orderBookPosition.rest, 8) IN IF ~businessTime.ok THEN Fail ELSE
    LET filler1 == ReadBytes(businessTime.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    Ok([ orderbookId       |-> orderbookId.value,
         orderId           |-> orderId.value,
         price             |-> price.value,
         quantity          |-> quantity.value,
         side              |-> side.value,
         lotType           |-> lotType.value,
         orderType         |-> orderType.value,
         orderBookPosition |-> orderBookPosition.value,
         businessTime      |-> businessTime.value,
         filler1           |-> filler1.value ], filler1.rest)

ZeroAddOrder ==
    [ orderbookId       |-> [i \in 1 .. 4 |-> 0],
      orderId           |-> [i \in 1 .. 8 |-> 0],
      price             |-> [i \in 1 .. 8 |-> 0],
      quantity          |-> [i \in 1 .. 4 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      lotType           |-> [i \in 1 .. 1 |-> 0],
      orderType         |-> [i \in 1 .. 1 |-> 0],
      orderBookPosition |-> [i \in 1 .. 4 |-> 0],
      businessTime      |-> [i \in 1 .. 8 |-> 0],
      filler1           |-> [i \in 1 .. 1 |-> 0] ]

(* Add Order at zero, then each field in turn at the values it is checked at *)
CheckedAddOrder ==
    { ZeroAddOrder }
        \cup { [ZeroAddOrder EXCEPT !.orderbookId = one] : one \in Sample(4) }
        \cup { [ZeroAddOrder EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrder EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAddOrder EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroAddOrder EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAddOrder EXCEPT !.lotType = one] : one \in Sample(1) }
        \cup { [ZeroAddOrder EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroAddOrder EXCEPT !.orderBookPosition = one] : one \in Sample(4) }
        \cup { [ZeroAddOrder EXCEPT !.businessTime = one] : one \in Sample(8) }
        \cup { [ZeroAddOrder EXCEPT !.filler1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Aggregate Implied Order: 22 bytes                                       *)
(***************************************************************************)

AggregateImpliedOrder ==
    [ orderbookId     : Sample(4),
      impliedPrice    : Sample(8),
      impliedQuantity : Sample(8),
      side            : Sample(1),
      filler1         : Sample(1) ]

EncodeAggregateImpliedOrder(message) ==
    message.orderbookId
        \o message.impliedPrice
        \o message.impliedQuantity
        \o message.side
        \o message.filler1

DecodeAggregateImpliedOrder(bytes) ==
    LET orderbookId == ReadBytes(bytes, 4) IN IF ~orderbookId.ok THEN Fail ELSE
    LET impliedPrice == ReadBytes(orderbookId.rest, 8) IN IF ~impliedPrice.ok THEN Fail ELSE
    LET impliedQuantity == ReadBytes(impliedPrice.rest, 8) IN IF ~impliedQuantity.ok THEN Fail ELSE
    LET side == ReadBytes(impliedQuantity.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET filler1 == ReadBytes(side.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    Ok([ orderbookId     |-> orderbookId.value,
         impliedPrice    |-> impliedPrice.value,
         impliedQuantity |-> impliedQuantity.value,
         side            |-> side.value,
         filler1         |-> filler1.value ], filler1.rest)

ZeroAggregateImpliedOrder ==
    [ orderbookId     |-> [i \in 1 .. 4 |-> 0],
      impliedPrice    |-> [i \in 1 .. 8 |-> 0],
      impliedQuantity |-> [i \in 1 .. 8 |-> 0],
      side            |-> [i \in 1 .. 1 |-> 0],
      filler1         |-> [i \in 1 .. 1 |-> 0] ]

(* Aggregate Implied Order at zero, then each field in turn at the values it is checked at *)
CheckedAggregateImpliedOrder ==
    { ZeroAggregateImpliedOrder }
        \cup { [ZeroAggregateImpliedOrder EXCEPT !.orderbookId = one] : one \in Sample(4) }
        \cup { [ZeroAggregateImpliedOrder EXCEPT !.impliedPrice = one] : one \in Sample(8) }
        \cup { [ZeroAggregateImpliedOrder EXCEPT !.impliedQuantity = one] : one \in Sample(8) }
        \cup { [ZeroAggregateImpliedOrder EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAggregateImpliedOrder EXCEPT !.filler1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Calculated Opening Price Message: 24 bytes                              *)
(***************************************************************************)

CalculatedOpeningPriceMessage ==
    [ orderbookId               : Sample(4),
      calculatedOpeningPrice    : Sample(8),
      filler4                   : Sample(4),
      calculatedOpeningQuantity : Sample(8) ]

EncodeCalculatedOpeningPriceMessage(message) ==
    message.orderbookId
        \o message.calculatedOpeningPrice
        \o message.filler4
        \o message.calculatedOpeningQuantity

DecodeCalculatedOpeningPriceMessage(bytes) ==
    LET orderbookId == ReadBytes(bytes, 4) IN IF ~orderbookId.ok THEN Fail ELSE
    LET calculatedOpeningPrice == ReadBytes(orderbookId.rest, 8) IN IF ~calculatedOpeningPrice.ok THEN Fail ELSE
    LET filler4 == ReadBytes(calculatedOpeningPrice.rest, 4) IN IF ~filler4.ok THEN Fail ELSE
    LET calculatedOpeningQuantity == ReadBytes(filler4.rest, 8) IN IF ~calculatedOpeningQuantity.ok THEN Fail ELSE
    Ok([ orderbookId               |-> orderbookId.value,
         calculatedOpeningPrice    |-> calculatedOpeningPrice.value,
         filler4                   |-> filler4.value,
         calculatedOpeningQuantity |-> calculatedOpeningQuantity.value ], calculatedOpeningQuantity.rest)

ZeroCalculatedOpeningPriceMessage ==
    [ orderbookId               |-> [i \in 1 .. 4 |-> 0],
      calculatedOpeningPrice    |-> [i \in 1 .. 8 |-> 0],
      filler4                   |-> [i \in 1 .. 4 |-> 0],
      calculatedOpeningQuantity |-> [i \in 1 .. 8 |-> 0] ]

(* Calculated Opening Price Message at zero, then each field in turn at the values it is checked at *)
CheckedCalculatedOpeningPriceMessage ==
    { ZeroCalculatedOpeningPriceMessage }
        \cup { [ZeroCalculatedOpeningPriceMessage EXCEPT !.orderbookId = one] : one \in Sample(4) }
        \cup { [ZeroCalculatedOpeningPriceMessage EXCEPT !.calculatedOpeningPrice = one] : one \in Sample(8) }
        \cup { [ZeroCalculatedOpeningPriceMessage EXCEPT !.filler4 = one] : one \in Sample(4) }
        \cup { [ZeroCalculatedOpeningPriceMessage EXCEPT !.calculatedOpeningQuantity = one] : one \in Sample(8) }

(***************************************************************************)
(* Market Alert Message: 653 bytes                                         *)
(***************************************************************************)

MarketAlertMessage ==
    [ alertId      : Sample(8),
      source       : Sample(1),
      header       : Sample(320),
      lastFragment : Sample(1),
      infoType     : Sample(1),
      priority     : Sample(1),
      noofLines    : 0 .. 255,
      content      : Sample(320) ]

EncodeMarketAlertMessage(message) ==
    message.alertId
        \o message.source
        \o message.header
        \o message.lastFragment
        \o message.infoType
        \o message.priority
        \o EncodeUIntBE(message.noofLines, 1)
        \o message.content

DecodeMarketAlertMessage(bytes) ==
    LET alertId == ReadBytes(bytes, 8) IN IF ~alertId.ok THEN Fail ELSE
    LET source == ReadBytes(alertId.rest, 1) IN IF ~source.ok THEN Fail ELSE
    LET header == ReadBytes(source.rest, 320) IN IF ~header.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(header.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET infoType == ReadBytes(lastFragment.rest, 1) IN IF ~infoType.ok THEN Fail ELSE
    LET priority == ReadBytes(infoType.rest, 1) IN IF ~priority.ok THEN Fail ELSE
    LET noofLines == ReadUIntBE(priority.rest, 1) IN IF ~noofLines.ok THEN Fail ELSE
    LET content == ReadBytes(noofLines.rest, 320) IN IF ~content.ok THEN Fail ELSE
    Ok([ alertId      |-> alertId.value,
         source       |-> source.value,
         header       |-> header.value,
         lastFragment |-> lastFragment.value,
         infoType     |-> infoType.value,
         priority     |-> priority.value,
         noofLines    |-> noofLines.value,
         content      |-> content.value ], content.rest)

ZeroMarketAlertMessage ==
    [ alertId      |-> [i \in 1 .. 8 |-> 0],
      source       |-> [i \in 1 .. 1 |-> 0],
      header       |-> [i \in 1 .. 320 |-> 0],
      lastFragment |-> [i \in 1 .. 1 |-> 0],
      infoType     |-> [i \in 1 .. 1 |-> 0],
      priority     |-> [i \in 1 .. 1 |-> 0],
      noofLines    |-> 0,
      content      |-> [i \in 1 .. 320 |-> 0] ]

(* Market Alert Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketAlertMessage ==
    { ZeroMarketAlertMessage }
        \cup { [ZeroMarketAlertMessage EXCEPT !.alertId = one] : one \in Sample(8) }
        \cup { [ZeroMarketAlertMessage EXCEPT !.source = one] : one \in Sample(1) }
        \cup { [ZeroMarketAlertMessage EXCEPT !.header = one] : one \in Sample(320) }
        \cup { [ZeroMarketAlertMessage EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroMarketAlertMessage EXCEPT !.infoType = one] : one \in Sample(1) }
        \cup { [ZeroMarketAlertMessage EXCEPT !.priority = one] : one \in Sample(1) }
        \cup { [ZeroMarketAlertMessage EXCEPT !.noofLines = one] : one \in {0, 1, 255} }
        \cup { [ZeroMarketAlertMessage EXCEPT !.content = one] : one \in Sample(320) }

(***************************************************************************)
(* Open Interest Message: 28 bytes                                         *)
(***************************************************************************)

OpenInterestMessage ==
    [ dayIndicator    : Sample(2),
      filler6         : Sample(6),
      orderbookId     : Sample(4),
      settlementPrice : Sample(8),
      grossOi         : Sample(4),
      netOi           : Sample(4) ]

EncodeOpenInterestMessage(message) ==
    message.dayIndicator
        \o message.filler6
        \o message.orderbookId
        \o message.settlementPrice
        \o message.grossOi
        \o message.netOi

DecodeOpenInterestMessage(bytes) ==
    LET dayIndicator == ReadBytes(bytes, 2) IN IF ~dayIndicator.ok THEN Fail ELSE
    LET filler6 == ReadBytes(dayIndicator.rest, 6) IN IF ~filler6.ok THEN Fail ELSE
    LET orderbookId == ReadBytes(filler6.rest, 4) IN IF ~orderbookId.ok THEN Fail ELSE
    LET settlementPrice == ReadBytes(orderbookId.rest, 8) IN IF ~settlementPrice.ok THEN Fail ELSE
    LET grossOi == ReadBytes(settlementPrice.rest, 4) IN IF ~grossOi.ok THEN Fail ELSE
    LET netOi == ReadBytes(grossOi.rest, 4) IN IF ~netOi.ok THEN Fail ELSE
    Ok([ dayIndicator    |-> dayIndicator.value,
         filler6         |-> filler6.value,
         orderbookId     |-> orderbookId.value,
         settlementPrice |-> settlementPrice.value,
         grossOi         |-> grossOi.value,
         netOi           |-> netOi.value ], netOi.rest)

ZeroOpenInterestMessage ==
    [ dayIndicator    |-> [i \in 1 .. 2 |-> 0],
      filler6         |-> [i \in 1 .. 6 |-> 0],
      orderbookId     |-> [i \in 1 .. 4 |-> 0],
      settlementPrice |-> [i \in 1 .. 8 |-> 0],
      grossOi         |-> [i \in 1 .. 4 |-> 0],
      netOi           |-> [i \in 1 .. 4 |-> 0] ]

(* Open Interest Message at zero, then each field in turn at the values it is checked at *)
CheckedOpenInterestMessage ==
    { ZeroOpenInterestMessage }
        \cup { [ZeroOpenInterestMessage EXCEPT !.dayIndicator = one] : one \in Sample(2) }
        \cup { [ZeroOpenInterestMessage EXCEPT !.filler6 = one] : one \in Sample(6) }
        \cup { [ZeroOpenInterestMessage EXCEPT !.orderbookId = one] : one \in Sample(4) }
        \cup { [ZeroOpenInterestMessage EXCEPT !.settlementPrice = one] : one \in Sample(8) }
        \cup { [ZeroOpenInterestMessage EXCEPT !.grossOi = one] : one \in Sample(4) }
        \cup { [ZeroOpenInterestMessage EXCEPT !.netOi = one] : one \in Sample(4) }

(***************************************************************************)
(* Commodity Definition: 89 bytes                                          *)
(***************************************************************************)

CommodityDefinition ==
    [ commodityCode            : Sample(4),
      commodityName            : Sample(40),
      commodityId              : Sample(6),
      underlyingCode           : Sample(20),
      underlyingType           : Sample(1),
      decimalInUnderlyingPrice : Sample(1),
      baseCurrency             : Sample(3),
      underlyingIssuer         : Sample(6),
      caCreated                : Sample(1),
      effectiveTomorrow        : Sample(1),
      filler6                  : Sample(6) ]

EncodeCommodityDefinition(message) ==
    message.commodityCode
        \o message.commodityName
        \o message.commodityId
        \o message.underlyingCode
        \o message.underlyingType
        \o message.decimalInUnderlyingPrice
        \o message.baseCurrency
        \o message.underlyingIssuer
        \o message.caCreated
        \o message.effectiveTomorrow
        \o message.filler6

DecodeCommodityDefinition(bytes) ==
    LET commodityCode == ReadBytes(bytes, 4) IN IF ~commodityCode.ok THEN Fail ELSE
    LET commodityName == ReadBytes(commodityCode.rest, 40) IN IF ~commodityName.ok THEN Fail ELSE
    LET commodityId == ReadBytes(commodityName.rest, 6) IN IF ~commodityId.ok THEN Fail ELSE
    LET underlyingCode == ReadBytes(commodityId.rest, 20) IN IF ~underlyingCode.ok THEN Fail ELSE
    LET underlyingType == ReadBytes(underlyingCode.rest, 1) IN IF ~underlyingType.ok THEN Fail ELSE
    LET decimalInUnderlyingPrice == ReadBytes(underlyingType.rest, 1) IN IF ~decimalInUnderlyingPrice.ok THEN Fail ELSE
    LET baseCurrency == ReadBytes(decimalInUnderlyingPrice.rest, 3) IN IF ~baseCurrency.ok THEN Fail ELSE
    LET underlyingIssuer == ReadBytes(baseCurrency.rest, 6) IN IF ~underlyingIssuer.ok THEN Fail ELSE
    LET caCreated == ReadBytes(underlyingIssuer.rest, 1) IN IF ~caCreated.ok THEN Fail ELSE
    LET effectiveTomorrow == ReadBytes(caCreated.rest, 1) IN IF ~effectiveTomorrow.ok THEN Fail ELSE
    LET filler6 == ReadBytes(effectiveTomorrow.rest, 6) IN IF ~filler6.ok THEN Fail ELSE
    Ok([ commodityCode            |-> commodityCode.value,
         commodityName            |-> commodityName.value,
         commodityId              |-> commodityId.value,
         underlyingCode           |-> underlyingCode.value,
         underlyingType           |-> underlyingType.value,
         decimalInUnderlyingPrice |-> decimalInUnderlyingPrice.value,
         baseCurrency             |-> baseCurrency.value,
         underlyingIssuer         |-> underlyingIssuer.value,
         caCreated                |-> caCreated.value,
         effectiveTomorrow        |-> effectiveTomorrow.value,
         filler6                  |-> filler6.value ], filler6.rest)

ZeroCommodityDefinition ==
    [ commodityCode            |-> [i \in 1 .. 4 |-> 0],
      commodityName            |-> [i \in 1 .. 40 |-> 0],
      commodityId              |-> [i \in 1 .. 6 |-> 0],
      underlyingCode           |-> [i \in 1 .. 20 |-> 0],
      underlyingType           |-> [i \in 1 .. 1 |-> 0],
      decimalInUnderlyingPrice |-> [i \in 1 .. 1 |-> 0],
      baseCurrency             |-> [i \in 1 .. 3 |-> 0],
      underlyingIssuer         |-> [i \in 1 .. 6 |-> 0],
      caCreated                |-> [i \in 1 .. 1 |-> 0],
      effectiveTomorrow        |-> [i \in 1 .. 1 |-> 0],
      filler6                  |-> [i \in 1 .. 6 |-> 0] ]

(* Commodity Definition at zero, then each field in turn at the values it is checked at *)
CheckedCommodityDefinition ==
    { ZeroCommodityDefinition }
        \cup { [ZeroCommodityDefinition EXCEPT !.commodityCode = one] : one \in Sample(4) }
        \cup { [ZeroCommodityDefinition EXCEPT !.commodityName = one] : one \in Sample(40) }
        \cup { [ZeroCommodityDefinition EXCEPT !.commodityId = one] : one \in Sample(6) }
        \cup { [ZeroCommodityDefinition EXCEPT !.underlyingCode = one] : one \in Sample(20) }
        \cup { [ZeroCommodityDefinition EXCEPT !.underlyingType = one] : one \in Sample(1) }
        \cup { [ZeroCommodityDefinition EXCEPT !.decimalInUnderlyingPrice = one] : one \in Sample(1) }
        \cup { [ZeroCommodityDefinition EXCEPT !.baseCurrency = one] : one \in Sample(3) }
        \cup { [ZeroCommodityDefinition EXCEPT !.underlyingIssuer = one] : one \in Sample(6) }
        \cup { [ZeroCommodityDefinition EXCEPT !.caCreated = one] : one \in Sample(1) }
        \cup { [ZeroCommodityDefinition EXCEPT !.effectiveTomorrow = one] : one \in Sample(1) }
        \cup { [ZeroCommodityDefinition EXCEPT !.filler6 = one] : one \in Sample(6) }

(***************************************************************************)
(* Class Definition: 106 bytes                                             *)
(***************************************************************************)

ClassDefinition ==
    [ instrumentClassId     : Sample(14),
      instrumentClassKey    : Sample(4),
      instrumentClassName   : Sample(40),
      exchange              : Sample(2),
      market                : Sample(2),
      instrumentGroup       : Sample(2),
      modifier              : Sample(1),
      commodityCode         : Sample(4),
      filler3               : Sample(3),
      priceQuotationFactor  : Sample(4),
      contractSize          : Sample(4),
      decimalInContractSize : Sample(1),
      decimalInStrikePrice  : Sample(1),
      decimalInPrice        : Sample(1),
      tickSize              : Sample(8),
      tradable              : Sample(1),
      baseCurrency          : Sample(3),
      settlementCurrencyId  : Sample(3),
      effectiveTomorrow     : Sample(1),
      filler7               : Sample(7) ]

EncodeClassDefinition(message) ==
    message.instrumentClassId
        \o message.instrumentClassKey
        \o message.instrumentClassName
        \o message.exchange
        \o message.market
        \o message.instrumentGroup
        \o message.modifier
        \o message.commodityCode
        \o message.filler3
        \o message.priceQuotationFactor
        \o message.contractSize
        \o message.decimalInContractSize
        \o message.decimalInStrikePrice
        \o message.decimalInPrice
        \o message.tickSize
        \o message.tradable
        \o message.baseCurrency
        \o message.settlementCurrencyId
        \o message.effectiveTomorrow
        \o message.filler7

DecodeClassDefinition(bytes) ==
    LET instrumentClassId == ReadBytes(bytes, 14) IN IF ~instrumentClassId.ok THEN Fail ELSE
    LET instrumentClassKey == ReadBytes(instrumentClassId.rest, 4) IN IF ~instrumentClassKey.ok THEN Fail ELSE
    LET instrumentClassName == ReadBytes(instrumentClassKey.rest, 40) IN IF ~instrumentClassName.ok THEN Fail ELSE
    LET exchange == ReadBytes(instrumentClassName.rest, 2) IN IF ~exchange.ok THEN Fail ELSE
    LET market == ReadBytes(exchange.rest, 2) IN IF ~market.ok THEN Fail ELSE
    LET instrumentGroup == ReadBytes(market.rest, 2) IN IF ~instrumentGroup.ok THEN Fail ELSE
    LET modifier == ReadBytes(instrumentGroup.rest, 1) IN IF ~modifier.ok THEN Fail ELSE
    LET commodityCode == ReadBytes(modifier.rest, 4) IN IF ~commodityCode.ok THEN Fail ELSE
    LET filler3 == ReadBytes(commodityCode.rest, 3) IN IF ~filler3.ok THEN Fail ELSE
    LET priceQuotationFactor == ReadBytes(filler3.rest, 4) IN IF ~priceQuotationFactor.ok THEN Fail ELSE
    LET contractSize == ReadBytes(priceQuotationFactor.rest, 4) IN IF ~contractSize.ok THEN Fail ELSE
    LET decimalInContractSize == ReadBytes(contractSize.rest, 1) IN IF ~decimalInContractSize.ok THEN Fail ELSE
    LET decimalInStrikePrice == ReadBytes(decimalInContractSize.rest, 1) IN IF ~decimalInStrikePrice.ok THEN Fail ELSE
    LET decimalInPrice == ReadBytes(decimalInStrikePrice.rest, 1) IN IF ~decimalInPrice.ok THEN Fail ELSE
    LET tickSize == ReadBytes(decimalInPrice.rest, 8) IN IF ~tickSize.ok THEN Fail ELSE
    LET tradable == ReadBytes(tickSize.rest, 1) IN IF ~tradable.ok THEN Fail ELSE
    LET baseCurrency == ReadBytes(tradable.rest, 3) IN IF ~baseCurrency.ok THEN Fail ELSE
    LET settlementCurrencyId == ReadBytes(baseCurrency.rest, 3) IN IF ~settlementCurrencyId.ok THEN Fail ELSE
    LET effectiveTomorrow == ReadBytes(settlementCurrencyId.rest, 1) IN IF ~effectiveTomorrow.ok THEN Fail ELSE
    LET filler7 == ReadBytes(effectiveTomorrow.rest, 7) IN IF ~filler7.ok THEN Fail ELSE
    Ok([ instrumentClassId     |-> instrumentClassId.value,
         instrumentClassKey    |-> instrumentClassKey.value,
         instrumentClassName   |-> instrumentClassName.value,
         exchange              |-> exchange.value,
         market                |-> market.value,
         instrumentGroup       |-> instrumentGroup.value,
         modifier              |-> modifier.value,
         commodityCode         |-> commodityCode.value,
         filler3               |-> filler3.value,
         priceQuotationFactor  |-> priceQuotationFactor.value,
         contractSize          |-> contractSize.value,
         decimalInContractSize |-> decimalInContractSize.value,
         decimalInStrikePrice  |-> decimalInStrikePrice.value,
         decimalInPrice        |-> decimalInPrice.value,
         tickSize              |-> tickSize.value,
         tradable              |-> tradable.value,
         baseCurrency          |-> baseCurrency.value,
         settlementCurrencyId  |-> settlementCurrencyId.value,
         effectiveTomorrow     |-> effectiveTomorrow.value,
         filler7               |-> filler7.value ], filler7.rest)

ZeroClassDefinition ==
    [ instrumentClassId     |-> [i \in 1 .. 14 |-> 0],
      instrumentClassKey    |-> [i \in 1 .. 4 |-> 0],
      instrumentClassName   |-> [i \in 1 .. 40 |-> 0],
      exchange              |-> [i \in 1 .. 2 |-> 0],
      market                |-> [i \in 1 .. 2 |-> 0],
      instrumentGroup       |-> [i \in 1 .. 2 |-> 0],
      modifier              |-> [i \in 1 .. 1 |-> 0],
      commodityCode         |-> [i \in 1 .. 4 |-> 0],
      filler3               |-> [i \in 1 .. 3 |-> 0],
      priceQuotationFactor  |-> [i \in 1 .. 4 |-> 0],
      contractSize          |-> [i \in 1 .. 4 |-> 0],
      decimalInContractSize |-> [i \in 1 .. 1 |-> 0],
      decimalInStrikePrice  |-> [i \in 1 .. 1 |-> 0],
      decimalInPrice        |-> [i \in 1 .. 1 |-> 0],
      tickSize              |-> [i \in 1 .. 8 |-> 0],
      tradable              |-> [i \in 1 .. 1 |-> 0],
      baseCurrency          |-> [i \in 1 .. 3 |-> 0],
      settlementCurrencyId  |-> [i \in 1 .. 3 |-> 0],
      effectiveTomorrow     |-> [i \in 1 .. 1 |-> 0],
      filler7               |-> [i \in 1 .. 7 |-> 0] ]

(* Class Definition at zero, then each field in turn at the values it is checked at *)
CheckedClassDefinition ==
    { ZeroClassDefinition }
        \cup { [ZeroClassDefinition EXCEPT !.instrumentClassId = one] : one \in Sample(14) }
        \cup { [ZeroClassDefinition EXCEPT !.instrumentClassKey = one] : one \in Sample(4) }
        \cup { [ZeroClassDefinition EXCEPT !.instrumentClassName = one] : one \in Sample(40) }
        \cup { [ZeroClassDefinition EXCEPT !.exchange = one] : one \in Sample(2) }
        \cup { [ZeroClassDefinition EXCEPT !.market = one] : one \in Sample(2) }
        \cup { [ZeroClassDefinition EXCEPT !.instrumentGroup = one] : one \in Sample(2) }
        \cup { [ZeroClassDefinition EXCEPT !.modifier = one] : one \in Sample(1) }
        \cup { [ZeroClassDefinition EXCEPT !.commodityCode = one] : one \in Sample(4) }
        \cup { [ZeroClassDefinition EXCEPT !.filler3 = one] : one \in Sample(3) }
        \cup { [ZeroClassDefinition EXCEPT !.priceQuotationFactor = one] : one \in Sample(4) }
        \cup { [ZeroClassDefinition EXCEPT !.contractSize = one] : one \in Sample(4) }
        \cup { [ZeroClassDefinition EXCEPT !.decimalInContractSize = one] : one \in Sample(1) }
        \cup { [ZeroClassDefinition EXCEPT !.decimalInStrikePrice = one] : one \in Sample(1) }
        \cup { [ZeroClassDefinition EXCEPT !.decimalInPrice = one] : one \in Sample(1) }
        \cup { [ZeroClassDefinition EXCEPT !.tickSize = one] : one \in Sample(8) }
        \cup { [ZeroClassDefinition EXCEPT !.tradable = one] : one \in Sample(1) }
        \cup { [ZeroClassDefinition EXCEPT !.baseCurrency = one] : one \in Sample(3) }
        \cup { [ZeroClassDefinition EXCEPT !.settlementCurrencyId = one] : one \in Sample(3) }
        \cup { [ZeroClassDefinition EXCEPT !.effectiveTomorrow = one] : one \in Sample(1) }
        \cup { [ZeroClassDefinition EXCEPT !.filler7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Instrument Definition: 118 bytes                                        *)
(***************************************************************************)

InstrumentDefinition ==
    [ orderbookId                    : Sample(4),
      symbol                         : Sample(32),
      instrumentClassKey             : Sample(4),
      exchange                       : Sample(2),
      market                         : Sample(2),
      instrumentGroup                : Sample(2),
      modifier                       : Sample(1),
      commodityCode                  : Sample(4),
      lastTradingDate                : Sample(4),
      strikePrice                    : Sample(8),
      filler3                        : Sample(3),
      dateTimeLastTrading            : Sample(8),
      effectiveLastTradingDate       : Sample(4),
      dateTimeFirstTrading           : Sample(8),
      instrumentStatusCode           : Sample(1),
      decimalInStrikePrice           : Sample(1),
      decimalInPrice                 : Sample(1),
      financialProduct               : Sample(1),
      putOrCall                      : Sample(1),
      instrumentContractSize         : Sample(4),
      instrumentPriceQuotationFactor : Sample(4),
      numberOfLegs                   : Sample(1),
      vcmFlag                        : Sample(1),
      isinCode                       : Sample(12),
      effectiveTomorrow              : Sample(1),
      filler4                        : Sample(4) ]

EncodeInstrumentDefinition(message) ==
    message.orderbookId
        \o message.symbol
        \o message.instrumentClassKey
        \o message.exchange
        \o message.market
        \o message.instrumentGroup
        \o message.modifier
        \o message.commodityCode
        \o message.lastTradingDate
        \o message.strikePrice
        \o message.filler3
        \o message.dateTimeLastTrading
        \o message.effectiveLastTradingDate
        \o message.dateTimeFirstTrading
        \o message.instrumentStatusCode
        \o message.decimalInStrikePrice
        \o message.decimalInPrice
        \o message.financialProduct
        \o message.putOrCall
        \o message.instrumentContractSize
        \o message.instrumentPriceQuotationFactor
        \o message.numberOfLegs
        \o message.vcmFlag
        \o message.isinCode
        \o message.effectiveTomorrow
        \o message.filler4

DecodeInstrumentDefinition(bytes) ==
    LET orderbookId == ReadBytes(bytes, 4) IN IF ~orderbookId.ok THEN Fail ELSE
    LET symbol == ReadBytes(orderbookId.rest, 32) IN IF ~symbol.ok THEN Fail ELSE
    LET instrumentClassKey == ReadBytes(symbol.rest, 4) IN IF ~instrumentClassKey.ok THEN Fail ELSE
    LET exchange == ReadBytes(instrumentClassKey.rest, 2) IN IF ~exchange.ok THEN Fail ELSE
    LET market == ReadBytes(exchange.rest, 2) IN IF ~market.ok THEN Fail ELSE
    LET instrumentGroup == ReadBytes(market.rest, 2) IN IF ~instrumentGroup.ok THEN Fail ELSE
    LET modifier == ReadBytes(instrumentGroup.rest, 1) IN IF ~modifier.ok THEN Fail ELSE
    LET commodityCode == ReadBytes(modifier.rest, 4) IN IF ~commodityCode.ok THEN Fail ELSE
    LET lastTradingDate == ReadBytes(commodityCode.rest, 4) IN IF ~lastTradingDate.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(lastTradingDate.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET filler3 == ReadBytes(strikePrice.rest, 3) IN IF ~filler3.ok THEN Fail ELSE
    LET dateTimeLastTrading == ReadBytes(filler3.rest, 8) IN IF ~dateTimeLastTrading.ok THEN Fail ELSE
    LET effectiveLastTradingDate == ReadBytes(dateTimeLastTrading.rest, 4) IN IF ~effectiveLastTradingDate.ok THEN Fail ELSE
    LET dateTimeFirstTrading == ReadBytes(effectiveLastTradingDate.rest, 8) IN IF ~dateTimeFirstTrading.ok THEN Fail ELSE
    LET instrumentStatusCode == ReadBytes(dateTimeFirstTrading.rest, 1) IN IF ~instrumentStatusCode.ok THEN Fail ELSE
    LET decimalInStrikePrice == ReadBytes(instrumentStatusCode.rest, 1) IN IF ~decimalInStrikePrice.ok THEN Fail ELSE
    LET decimalInPrice == ReadBytes(decimalInStrikePrice.rest, 1) IN IF ~decimalInPrice.ok THEN Fail ELSE
    LET financialProduct == ReadBytes(decimalInPrice.rest, 1) IN IF ~financialProduct.ok THEN Fail ELSE
    LET putOrCall == ReadBytes(financialProduct.rest, 1) IN IF ~putOrCall.ok THEN Fail ELSE
    LET instrumentContractSize == ReadBytes(putOrCall.rest, 4) IN IF ~instrumentContractSize.ok THEN Fail ELSE
    LET instrumentPriceQuotationFactor == ReadBytes(instrumentContractSize.rest, 4) IN IF ~instrumentPriceQuotationFactor.ok THEN Fail ELSE
    LET numberOfLegs == ReadBytes(instrumentPriceQuotationFactor.rest, 1) IN IF ~numberOfLegs.ok THEN Fail ELSE
    LET vcmFlag == ReadBytes(numberOfLegs.rest, 1) IN IF ~vcmFlag.ok THEN Fail ELSE
    LET isinCode == ReadBytes(vcmFlag.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET effectiveTomorrow == ReadBytes(isinCode.rest, 1) IN IF ~effectiveTomorrow.ok THEN Fail ELSE
    LET filler4 == ReadBytes(effectiveTomorrow.rest, 4) IN IF ~filler4.ok THEN Fail ELSE
    Ok([ orderbookId                    |-> orderbookId.value,
         symbol                         |-> symbol.value,
         instrumentClassKey             |-> instrumentClassKey.value,
         exchange                       |-> exchange.value,
         market                         |-> market.value,
         instrumentGroup                |-> instrumentGroup.value,
         modifier                       |-> modifier.value,
         commodityCode                  |-> commodityCode.value,
         lastTradingDate                |-> lastTradingDate.value,
         strikePrice                    |-> strikePrice.value,
         filler3                        |-> filler3.value,
         dateTimeLastTrading            |-> dateTimeLastTrading.value,
         effectiveLastTradingDate       |-> effectiveLastTradingDate.value,
         dateTimeFirstTrading           |-> dateTimeFirstTrading.value,
         instrumentStatusCode           |-> instrumentStatusCode.value,
         decimalInStrikePrice           |-> decimalInStrikePrice.value,
         decimalInPrice                 |-> decimalInPrice.value,
         financialProduct               |-> financialProduct.value,
         putOrCall                      |-> putOrCall.value,
         instrumentContractSize         |-> instrumentContractSize.value,
         instrumentPriceQuotationFactor |-> instrumentPriceQuotationFactor.value,
         numberOfLegs                   |-> numberOfLegs.value,
         vcmFlag                        |-> vcmFlag.value,
         isinCode                       |-> isinCode.value,
         effectiveTomorrow              |-> effectiveTomorrow.value,
         filler4                        |-> filler4.value ], filler4.rest)

ZeroInstrumentDefinition ==
    [ orderbookId                    |-> [i \in 1 .. 4 |-> 0],
      symbol                         |-> [i \in 1 .. 32 |-> 0],
      instrumentClassKey             |-> [i \in 1 .. 4 |-> 0],
      exchange                       |-> [i \in 1 .. 2 |-> 0],
      market                         |-> [i \in 1 .. 2 |-> 0],
      instrumentGroup                |-> [i \in 1 .. 2 |-> 0],
      modifier                       |-> [i \in 1 .. 1 |-> 0],
      commodityCode                  |-> [i \in 1 .. 4 |-> 0],
      lastTradingDate                |-> [i \in 1 .. 4 |-> 0],
      strikePrice                    |-> [i \in 1 .. 8 |-> 0],
      filler3                        |-> [i \in 1 .. 3 |-> 0],
      dateTimeLastTrading            |-> [i \in 1 .. 8 |-> 0],
      effectiveLastTradingDate       |-> [i \in 1 .. 4 |-> 0],
      dateTimeFirstTrading           |-> [i \in 1 .. 8 |-> 0],
      instrumentStatusCode           |-> [i \in 1 .. 1 |-> 0],
      decimalInStrikePrice           |-> [i \in 1 .. 1 |-> 0],
      decimalInPrice                 |-> [i \in 1 .. 1 |-> 0],
      financialProduct               |-> [i \in 1 .. 1 |-> 0],
      putOrCall                      |-> [i \in 1 .. 1 |-> 0],
      instrumentContractSize         |-> [i \in 1 .. 4 |-> 0],
      instrumentPriceQuotationFactor |-> [i \in 1 .. 4 |-> 0],
      numberOfLegs                   |-> [i \in 1 .. 1 |-> 0],
      vcmFlag                        |-> [i \in 1 .. 1 |-> 0],
      isinCode                       |-> [i \in 1 .. 12 |-> 0],
      effectiveTomorrow              |-> [i \in 1 .. 1 |-> 0],
      filler4                        |-> [i \in 1 .. 4 |-> 0] ]

(* Instrument Definition at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentDefinition ==
    { ZeroInstrumentDefinition }
        \cup { [ZeroInstrumentDefinition EXCEPT !.orderbookId = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentDefinition EXCEPT !.symbol = one] : one \in Sample(32) }
        \cup { [ZeroInstrumentDefinition EXCEPT !.instrumentClassKey = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentDefinition EXCEPT !.exchange = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentDefinition EXCEPT !.market = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentDefinition EXCEPT !.instrumentGroup = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentDefinition EXCEPT !.modifier = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDefinition EXCEPT !.commodityCode = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentDefinition EXCEPT !.lastTradingDate = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentDefinition EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDefinition EXCEPT !.filler3 = one] : one \in Sample(3) }
        \cup { [ZeroInstrumentDefinition EXCEPT !.dateTimeLastTrading = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDefinition EXCEPT !.effectiveLastTradingDate = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentDefinition EXCEPT !.dateTimeFirstTrading = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDefinition EXCEPT !.instrumentStatusCode = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDefinition EXCEPT !.decimalInStrikePrice = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDefinition EXCEPT !.decimalInPrice = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDefinition EXCEPT !.financialProduct = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDefinition EXCEPT !.putOrCall = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDefinition EXCEPT !.instrumentContractSize = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentDefinition EXCEPT !.instrumentPriceQuotationFactor = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentDefinition EXCEPT !.numberOfLegs = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDefinition EXCEPT !.vcmFlag = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDefinition EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroInstrumentDefinition EXCEPT !.effectiveTomorrow = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDefinition EXCEPT !.filler4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Combination Definition: 16 bytes                                        *)
(***************************************************************************)

CombinationDefinition ==
    [ comboOrderbookId : Sample(4),
      legOrderbookId   : Sample(4),
      filler3          : Sample(3),
      legSide          : Sample(1),
      legRatio         : Sample(4) ]

EncodeCombinationDefinition(message) ==
    message.comboOrderbookId
        \o message.legOrderbookId
        \o message.filler3
        \o message.legSide
        \o message.legRatio

DecodeCombinationDefinition(bytes) ==
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

ZeroCombinationDefinition ==
    [ comboOrderbookId |-> [i \in 1 .. 4 |-> 0],
      legOrderbookId   |-> [i \in 1 .. 4 |-> 0],
      filler3          |-> [i \in 1 .. 3 |-> 0],
      legSide          |-> [i \in 1 .. 1 |-> 0],
      legRatio         |-> [i \in 1 .. 4 |-> 0] ]

(* Combination Definition at zero, then each field in turn at the values it is checked at *)
CheckedCombinationDefinition ==
    { ZeroCombinationDefinition }
        \cup { [ZeroCombinationDefinition EXCEPT !.comboOrderbookId = one] : one \in Sample(4) }
        \cup { [ZeroCombinationDefinition EXCEPT !.legOrderbookId = one] : one \in Sample(4) }
        \cup { [ZeroCombinationDefinition EXCEPT !.filler3 = one] : one \in Sample(3) }
        \cup { [ZeroCombinationDefinition EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroCombinationDefinition EXCEPT !.legRatio = one] : one \in Sample(4) }

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
(* Market Status: 54 bytes                                                 *)
(***************************************************************************)

MarketStatus ==
    [ stateLevel         : Sample(1),
      instrumentClassKey : Sample(4),
      market             : Sample(2),
      instrumentGroup    : Sample(2),
      commodityCode      : Sample(4),
      filler8            : Sample(8),
      actualStartDate    : Sample(8),
      actualStartTime    : Sample(6),
      plannedStartDate   : Sample(8),
      plannedStartTime   : Sample(6),
      tradingSession     : Sample(1),
      state              : Sample(2),
      filler2            : Sample(2) ]

EncodeMarketStatus(message) ==
    message.stateLevel
        \o message.instrumentClassKey
        \o message.market
        \o message.instrumentGroup
        \o message.commodityCode
        \o message.filler8
        \o message.actualStartDate
        \o message.actualStartTime
        \o message.plannedStartDate
        \o message.plannedStartTime
        \o message.tradingSession
        \o message.state
        \o message.filler2

DecodeMarketStatus(bytes) ==
    LET stateLevel == ReadBytes(bytes, 1) IN IF ~stateLevel.ok THEN Fail ELSE
    LET instrumentClassKey == ReadBytes(stateLevel.rest, 4) IN IF ~instrumentClassKey.ok THEN Fail ELSE
    LET market == ReadBytes(instrumentClassKey.rest, 2) IN IF ~market.ok THEN Fail ELSE
    LET instrumentGroup == ReadBytes(market.rest, 2) IN IF ~instrumentGroup.ok THEN Fail ELSE
    LET commodityCode == ReadBytes(instrumentGroup.rest, 4) IN IF ~commodityCode.ok THEN Fail ELSE
    LET filler8 == ReadBytes(commodityCode.rest, 8) IN IF ~filler8.ok THEN Fail ELSE
    LET actualStartDate == ReadBytes(filler8.rest, 8) IN IF ~actualStartDate.ok THEN Fail ELSE
    LET actualStartTime == ReadBytes(actualStartDate.rest, 6) IN IF ~actualStartTime.ok THEN Fail ELSE
    LET plannedStartDate == ReadBytes(actualStartTime.rest, 8) IN IF ~plannedStartDate.ok THEN Fail ELSE
    LET plannedStartTime == ReadBytes(plannedStartDate.rest, 6) IN IF ~plannedStartTime.ok THEN Fail ELSE
    LET tradingSession == ReadBytes(plannedStartTime.rest, 1) IN IF ~tradingSession.ok THEN Fail ELSE
    LET state == ReadBytes(tradingSession.rest, 2) IN IF ~state.ok THEN Fail ELSE
    LET filler2 == ReadBytes(state.rest, 2) IN IF ~filler2.ok THEN Fail ELSE
    Ok([ stateLevel         |-> stateLevel.value,
         instrumentClassKey |-> instrumentClassKey.value,
         market             |-> market.value,
         instrumentGroup    |-> instrumentGroup.value,
         commodityCode      |-> commodityCode.value,
         filler8            |-> filler8.value,
         actualStartDate    |-> actualStartDate.value,
         actualStartTime    |-> actualStartTime.value,
         plannedStartDate   |-> plannedStartDate.value,
         plannedStartTime   |-> plannedStartTime.value,
         tradingSession     |-> tradingSession.value,
         state              |-> state.value,
         filler2            |-> filler2.value ], filler2.rest)

ZeroMarketStatus ==
    [ stateLevel         |-> [i \in 1 .. 1 |-> 0],
      instrumentClassKey |-> [i \in 1 .. 4 |-> 0],
      market             |-> [i \in 1 .. 2 |-> 0],
      instrumentGroup    |-> [i \in 1 .. 2 |-> 0],
      commodityCode      |-> [i \in 1 .. 4 |-> 0],
      filler8            |-> [i \in 1 .. 8 |-> 0],
      actualStartDate    |-> [i \in 1 .. 8 |-> 0],
      actualStartTime    |-> [i \in 1 .. 6 |-> 0],
      plannedStartDate   |-> [i \in 1 .. 8 |-> 0],
      plannedStartTime   |-> [i \in 1 .. 6 |-> 0],
      tradingSession     |-> [i \in 1 .. 1 |-> 0],
      state              |-> [i \in 1 .. 2 |-> 0],
      filler2            |-> [i \in 1 .. 2 |-> 0] ]

(* Market Status at zero, then each field in turn at the values it is checked at *)
CheckedMarketStatus ==
    { ZeroMarketStatus }
        \cup { [ZeroMarketStatus EXCEPT !.stateLevel = one] : one \in Sample(1) }
        \cup { [ZeroMarketStatus EXCEPT !.instrumentClassKey = one] : one \in Sample(4) }
        \cup { [ZeroMarketStatus EXCEPT !.market = one] : one \in Sample(2) }
        \cup { [ZeroMarketStatus EXCEPT !.instrumentGroup = one] : one \in Sample(2) }
        \cup { [ZeroMarketStatus EXCEPT !.commodityCode = one] : one \in Sample(4) }
        \cup { [ZeroMarketStatus EXCEPT !.filler8 = one] : one \in Sample(8) }
        \cup { [ZeroMarketStatus EXCEPT !.actualStartDate = one] : one \in Sample(8) }
        \cup { [ZeroMarketStatus EXCEPT !.actualStartTime = one] : one \in Sample(6) }
        \cup { [ZeroMarketStatus EXCEPT !.plannedStartDate = one] : one \in Sample(8) }
        \cup { [ZeroMarketStatus EXCEPT !.plannedStartTime = one] : one \in Sample(6) }
        \cup { [ZeroMarketStatus EXCEPT !.tradingSession = one] : one \in Sample(1) }
        \cup { [ZeroMarketStatus EXCEPT !.state = one] : one \in Sample(2) }
        \cup { [ZeroMarketStatus EXCEPT !.filler2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Instrument Status: 8 bytes                                              *)
(***************************************************************************)

InstrumentStatus ==
    [ orderbookId          : Sample(4),
      suspensionIndicator  : Sample(1),
      instrumentStatusCode : Sample(1),
      filler2              : Sample(2) ]

EncodeInstrumentStatus(message) ==
    message.orderbookId
        \o message.suspensionIndicator
        \o message.instrumentStatusCode
        \o message.filler2

DecodeInstrumentStatus(bytes) ==
    LET orderbookId == ReadBytes(bytes, 4) IN IF ~orderbookId.ok THEN Fail ELSE
    LET suspensionIndicator == ReadBytes(orderbookId.rest, 1) IN IF ~suspensionIndicator.ok THEN Fail ELSE
    LET instrumentStatusCode == ReadBytes(suspensionIndicator.rest, 1) IN IF ~instrumentStatusCode.ok THEN Fail ELSE
    LET filler2 == ReadBytes(instrumentStatusCode.rest, 2) IN IF ~filler2.ok THEN Fail ELSE
    Ok([ orderbookId          |-> orderbookId.value,
         suspensionIndicator  |-> suspensionIndicator.value,
         instrumentStatusCode |-> instrumentStatusCode.value,
         filler2              |-> filler2.value ], filler2.rest)

ZeroInstrumentStatus ==
    [ orderbookId          |-> [i \in 1 .. 4 |-> 0],
      suspensionIndicator  |-> [i \in 1 .. 1 |-> 0],
      instrumentStatusCode |-> [i \in 1 .. 1 |-> 0],
      filler2              |-> [i \in 1 .. 2 |-> 0] ]

(* Instrument Status at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentStatus ==
    { ZeroInstrumentStatus }
        \cup { [ZeroInstrumentStatus EXCEPT !.orderbookId = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentStatus EXCEPT !.suspensionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentStatus EXCEPT !.instrumentStatusCode = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentStatus EXCEPT !.filler2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Commodity And Class Status: 10 bytes                                    *)
(***************************************************************************)

CommodityAndClassStatus ==
    [ commodityCode      : Sample(4),
      instrumentClassKey : Sample(4),
      suspended          : Sample(1),
      filler1            : Sample(1) ]

EncodeCommodityAndClassStatus(message) ==
    message.commodityCode
        \o message.instrumentClassKey
        \o message.suspended
        \o message.filler1

DecodeCommodityAndClassStatus(bytes) ==
    LET commodityCode == ReadBytes(bytes, 4) IN IF ~commodityCode.ok THEN Fail ELSE
    LET instrumentClassKey == ReadBytes(commodityCode.rest, 4) IN IF ~instrumentClassKey.ok THEN Fail ELSE
    LET suspended == ReadBytes(instrumentClassKey.rest, 1) IN IF ~suspended.ok THEN Fail ELSE
    LET filler1 == ReadBytes(suspended.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    Ok([ commodityCode      |-> commodityCode.value,
         instrumentClassKey |-> instrumentClassKey.value,
         suspended          |-> suspended.value,
         filler1            |-> filler1.value ], filler1.rest)

ZeroCommodityAndClassStatus ==
    [ commodityCode      |-> [i \in 1 .. 4 |-> 0],
      instrumentClassKey |-> [i \in 1 .. 4 |-> 0],
      suspended          |-> [i \in 1 .. 1 |-> 0],
      filler1            |-> [i \in 1 .. 1 |-> 0] ]

(* Commodity And Class Status at zero, then each field in turn at the values it is checked at *)
CheckedCommodityAndClassStatus ==
    { ZeroCommodityAndClassStatus }
        \cup { [ZeroCommodityAndClassStatus EXCEPT !.commodityCode = one] : one \in Sample(4) }
        \cup { [ZeroCommodityAndClassStatus EXCEPT !.instrumentClassKey = one] : one \in Sample(4) }
        \cup { [ZeroCommodityAndClassStatus EXCEPT !.suspended = one] : one \in Sample(1) }
        \cup { [ZeroCommodityAndClassStatus EXCEPT !.filler1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Vcm Trigger: 46 bytes                                                   *)
(***************************************************************************)

VcmTrigger ==
    [ orderbookId         : Sample(4),
      coolingOffStartTime : Sample(8),
      coolingOffEndTime   : Sample(8),
      vcmReferencePrice   : Sample(8),
      vcmLowerPrice       : Sample(8),
      vcmUpperPrice       : Sample(8),
      filler2             : Sample(2) ]

EncodeVcmTrigger(message) ==
    message.orderbookId
        \o message.coolingOffStartTime
        \o message.coolingOffEndTime
        \o message.vcmReferencePrice
        \o message.vcmLowerPrice
        \o message.vcmUpperPrice
        \o message.filler2

DecodeVcmTrigger(bytes) ==
    LET orderbookId == ReadBytes(bytes, 4) IN IF ~orderbookId.ok THEN Fail ELSE
    LET coolingOffStartTime == ReadBytes(orderbookId.rest, 8) IN IF ~coolingOffStartTime.ok THEN Fail ELSE
    LET coolingOffEndTime == ReadBytes(coolingOffStartTime.rest, 8) IN IF ~coolingOffEndTime.ok THEN Fail ELSE
    LET vcmReferencePrice == ReadBytes(coolingOffEndTime.rest, 8) IN IF ~vcmReferencePrice.ok THEN Fail ELSE
    LET vcmLowerPrice == ReadBytes(vcmReferencePrice.rest, 8) IN IF ~vcmLowerPrice.ok THEN Fail ELSE
    LET vcmUpperPrice == ReadBytes(vcmLowerPrice.rest, 8) IN IF ~vcmUpperPrice.ok THEN Fail ELSE
    LET filler2 == ReadBytes(vcmUpperPrice.rest, 2) IN IF ~filler2.ok THEN Fail ELSE
    Ok([ orderbookId         |-> orderbookId.value,
         coolingOffStartTime |-> coolingOffStartTime.value,
         coolingOffEndTime   |-> coolingOffEndTime.value,
         vcmReferencePrice   |-> vcmReferencePrice.value,
         vcmLowerPrice       |-> vcmLowerPrice.value,
         vcmUpperPrice       |-> vcmUpperPrice.value,
         filler2             |-> filler2.value ], filler2.rest)

ZeroVcmTrigger ==
    [ orderbookId         |-> [i \in 1 .. 4 |-> 0],
      coolingOffStartTime |-> [i \in 1 .. 8 |-> 0],
      coolingOffEndTime   |-> [i \in 1 .. 8 |-> 0],
      vcmReferencePrice   |-> [i \in 1 .. 8 |-> 0],
      vcmLowerPrice       |-> [i \in 1 .. 8 |-> 0],
      vcmUpperPrice       |-> [i \in 1 .. 8 |-> 0],
      filler2             |-> [i \in 1 .. 2 |-> 0] ]

(* Vcm Trigger at zero, then each field in turn at the values it is checked at *)
CheckedVcmTrigger ==
    { ZeroVcmTrigger }
        \cup { [ZeroVcmTrigger EXCEPT !.orderbookId = one] : one \in Sample(4) }
        \cup { [ZeroVcmTrigger EXCEPT !.coolingOffStartTime = one] : one \in Sample(8) }
        \cup { [ZeroVcmTrigger EXCEPT !.coolingOffEndTime = one] : one \in Sample(8) }
        \cup { [ZeroVcmTrigger EXCEPT !.vcmReferencePrice = one] : one \in Sample(8) }
        \cup { [ZeroVcmTrigger EXCEPT !.vcmLowerPrice = one] : one \in Sample(8) }
        \cup { [ZeroVcmTrigger EXCEPT !.vcmUpperPrice = one] : one \in Sample(8) }
        \cup { [ZeroVcmTrigger EXCEPT !.filler2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Thm Trigger: 16 bytes                                                   *)
(***************************************************************************)

ThmTrigger ==
    [ instrumentClassKey : Sample(4),
      market             : Sample(2),
      instrumentGroup    : Sample(2),
      modifier           : Sample(1),
      commodityCode      : Sample(4),
      filler3            : Sample(3) ]

EncodeThmTrigger(message) ==
    message.instrumentClassKey
        \o message.market
        \o message.instrumentGroup
        \o message.modifier
        \o message.commodityCode
        \o message.filler3

DecodeThmTrigger(bytes) ==
    LET instrumentClassKey == ReadBytes(bytes, 4) IN IF ~instrumentClassKey.ok THEN Fail ELSE
    LET market == ReadBytes(instrumentClassKey.rest, 2) IN IF ~market.ok THEN Fail ELSE
    LET instrumentGroup == ReadBytes(market.rest, 2) IN IF ~instrumentGroup.ok THEN Fail ELSE
    LET modifier == ReadBytes(instrumentGroup.rest, 1) IN IF ~modifier.ok THEN Fail ELSE
    LET commodityCode == ReadBytes(modifier.rest, 4) IN IF ~commodityCode.ok THEN Fail ELSE
    LET filler3 == ReadBytes(commodityCode.rest, 3) IN IF ~filler3.ok THEN Fail ELSE
    Ok([ instrumentClassKey |-> instrumentClassKey.value,
         market             |-> market.value,
         instrumentGroup    |-> instrumentGroup.value,
         modifier           |-> modifier.value,
         commodityCode      |-> commodityCode.value,
         filler3            |-> filler3.value ], filler3.rest)

ZeroThmTrigger ==
    [ instrumentClassKey |-> [i \in 1 .. 4 |-> 0],
      market             |-> [i \in 1 .. 2 |-> 0],
      instrumentGroup    |-> [i \in 1 .. 2 |-> 0],
      modifier           |-> [i \in 1 .. 1 |-> 0],
      commodityCode      |-> [i \in 1 .. 4 |-> 0],
      filler3            |-> [i \in 1 .. 3 |-> 0] ]

(* Thm Trigger at zero, then each field in turn at the values it is checked at *)
CheckedThmTrigger ==
    { ZeroThmTrigger }
        \cup { [ZeroThmTrigger EXCEPT !.instrumentClassKey = one] : one \in Sample(4) }
        \cup { [ZeroThmTrigger EXCEPT !.market = one] : one \in Sample(2) }
        \cup { [ZeroThmTrigger EXCEPT !.instrumentGroup = one] : one \in Sample(2) }
        \cup { [ZeroThmTrigger EXCEPT !.modifier = one] : one \in Sample(1) }
        \cup { [ZeroThmTrigger EXCEPT !.commodityCode = one] : one \in Sample(4) }
        \cup { [ZeroThmTrigger EXCEPT !.filler3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Payload, selected by Msg Type                                           *)
(***************************************************************************)

AddOrderCode == 330  \* 0x14a
AggregateImpliedOrderCode == 337  \* 0x151
CalculatedOpeningPriceMessageCode == 364  \* 0x16c
MarketAlertMessageCode == 323  \* 0x143
OpenInterestMessageCode == 366  \* 0x16e
CommodityDefinitionCode == 301  \* 0x12d
ClassDefinitionCode == 302  \* 0x12e
InstrumentDefinitionCode == 303  \* 0x12f
CombinationDefinitionCode == 305  \* 0x131
RefreshCompleteCode == 203  \* 0xcb
MarketStatusCode == 320  \* 0x140
InstrumentStatusCode == 321  \* 0x141
CommodityAndClassStatusCode == 322  \* 0x142
VcmTriggerCode == 324  \* 0x144
ThmTriggerCode == 325  \* 0x145

Payload ==
    [ tag : {AddOrderCode}, body : AddOrder ]
        \cup [ tag : {AggregateImpliedOrderCode}, body : AggregateImpliedOrder ]
        \cup [ tag : {CalculatedOpeningPriceMessageCode}, body : CalculatedOpeningPriceMessage ]
        \cup [ tag : {MarketAlertMessageCode}, body : MarketAlertMessage ]
        \cup [ tag : {OpenInterestMessageCode}, body : OpenInterestMessage ]
        \cup [ tag : {CommodityDefinitionCode}, body : CommodityDefinition ]
        \cup [ tag : {ClassDefinitionCode}, body : ClassDefinition ]
        \cup [ tag : {InstrumentDefinitionCode}, body : InstrumentDefinition ]
        \cup [ tag : {CombinationDefinitionCode}, body : CombinationDefinition ]
        \cup [ tag : {RefreshCompleteCode}, body : RefreshComplete ]
        \cup [ tag : {MarketStatusCode}, body : MarketStatus ]
        \cup [ tag : {InstrumentStatusCode}, body : InstrumentStatus ]
        \cup [ tag : {CommodityAndClassStatusCode}, body : CommodityAndClassStatus ]
        \cup [ tag : {VcmTriggerCode}, body : VcmTrigger ]
        \cup [ tag : {ThmTriggerCode}, body : ThmTrigger ]

EncodePayload(message) ==
    CASE message.tag = AddOrderCode -> EncodeAddOrder(message.body)
      [] message.tag = AggregateImpliedOrderCode -> EncodeAggregateImpliedOrder(message.body)
      [] message.tag = CalculatedOpeningPriceMessageCode -> EncodeCalculatedOpeningPriceMessage(message.body)
      [] message.tag = MarketAlertMessageCode -> EncodeMarketAlertMessage(message.body)
      [] message.tag = OpenInterestMessageCode -> EncodeOpenInterestMessage(message.body)
      [] message.tag = CommodityDefinitionCode -> EncodeCommodityDefinition(message.body)
      [] message.tag = ClassDefinitionCode -> EncodeClassDefinition(message.body)
      [] message.tag = InstrumentDefinitionCode -> EncodeInstrumentDefinition(message.body)
      [] message.tag = CombinationDefinitionCode -> EncodeCombinationDefinition(message.body)
      [] message.tag = RefreshCompleteCode -> EncodeRefreshComplete(message.body)
      [] message.tag = MarketStatusCode -> EncodeMarketStatus(message.body)
      [] message.tag = InstrumentStatusCode -> EncodeInstrumentStatus(message.body)
      [] message.tag = CommodityAndClassStatusCode -> EncodeCommodityAndClassStatus(message.body)
      [] message.tag = VcmTriggerCode -> EncodeVcmTrigger(message.body)
      [] message.tag = ThmTriggerCode -> EncodeThmTrigger(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = AddOrderCode -> DecodeAddOrder(bytes)
              [] tag = AggregateImpliedOrderCode -> DecodeAggregateImpliedOrder(bytes)
              [] tag = CalculatedOpeningPriceMessageCode -> DecodeCalculatedOpeningPriceMessage(bytes)
              [] tag = MarketAlertMessageCode -> DecodeMarketAlertMessage(bytes)
              [] tag = OpenInterestMessageCode -> DecodeOpenInterestMessage(bytes)
              [] tag = CommodityDefinitionCode -> DecodeCommodityDefinition(bytes)
              [] tag = ClassDefinitionCode -> DecodeClassDefinition(bytes)
              [] tag = InstrumentDefinitionCode -> DecodeInstrumentDefinition(bytes)
              [] tag = CombinationDefinitionCode -> DecodeCombinationDefinition(bytes)
              [] tag = RefreshCompleteCode -> DecodeRefreshComplete(bytes)
              [] tag = MarketStatusCode -> DecodeMarketStatus(bytes)
              [] tag = InstrumentStatusCode -> DecodeInstrumentStatus(bytes)
              [] tag = CommodityAndClassStatusCode -> DecodeCommodityAndClassStatus(bytes)
              [] tag = VcmTriggerCode -> DecodeVcmTrigger(bytes)
              [] tag = ThmTriggerCode -> DecodeThmTrigger(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> AddOrderCode, body |-> ZeroAddOrder]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> AddOrderCode, body |-> one] : one \in CheckedAddOrder }
        \cup { [tag |-> AggregateImpliedOrderCode, body |-> one] : one \in CheckedAggregateImpliedOrder }
        \cup { [tag |-> CalculatedOpeningPriceMessageCode, body |-> one] : one \in CheckedCalculatedOpeningPriceMessage }
        \cup { [tag |-> MarketAlertMessageCode, body |-> one] : one \in CheckedMarketAlertMessage }
        \cup { [tag |-> OpenInterestMessageCode, body |-> one] : one \in CheckedOpenInterestMessage }
        \cup { [tag |-> CommodityDefinitionCode, body |-> one] : one \in CheckedCommodityDefinition }
        \cup { [tag |-> ClassDefinitionCode, body |-> one] : one \in CheckedClassDefinition }
        \cup { [tag |-> InstrumentDefinitionCode, body |-> one] : one \in CheckedInstrumentDefinition }
        \cup { [tag |-> CombinationDefinitionCode, body |-> one] : one \in CheckedCombinationDefinition }
        \cup { [tag |-> RefreshCompleteCode, body |-> one] : one \in CheckedRefreshComplete }
        \cup { [tag |-> MarketStatusCode, body |-> one] : one \in CheckedMarketStatus }
        \cup { [tag |-> InstrumentStatusCode, body |-> one] : one \in CheckedInstrumentStatus }
        \cup { [tag |-> CommodityAndClassStatusCode, body |-> one] : one \in CheckedCommodityAndClassStatus }
        \cup { [tag |-> VcmTriggerCode, body |-> one] : one \in CheckedVcmTrigger }
        \cup { [tag |-> ThmTriggerCode, body |-> one] : one \in CheckedThmTrigger }

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
    { [ZeroMessage EXCEPT !.payload = [tag |-> AddOrderCode, body |-> ZeroAddOrder]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AggregateImpliedOrderCode, body |-> ZeroAggregateImpliedOrder]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CalculatedOpeningPriceMessageCode, body |-> ZeroCalculatedOpeningPriceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MarketAlertMessageCode, body |-> ZeroMarketAlertMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OpenInterestMessageCode, body |-> ZeroOpenInterestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CommodityDefinitionCode, body |-> ZeroCommodityDefinition]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ClassDefinitionCode, body |-> ZeroClassDefinition]],
      [ZeroMessage EXCEPT !.payload = [tag |-> InstrumentDefinitionCode, body |-> ZeroInstrumentDefinition]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CombinationDefinitionCode, body |-> ZeroCombinationDefinition]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RefreshCompleteCode, body |-> ZeroRefreshComplete]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MarketStatusCode, body |-> ZeroMarketStatus]],
      [ZeroMessage EXCEPT !.payload = [tag |-> InstrumentStatusCode, body |-> ZeroInstrumentStatus]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CommodityAndClassStatusCode, body |-> ZeroCommodityAndClassStatus]],
      [ZeroMessage EXCEPT !.payload = [tag |-> VcmTriggerCode, body |-> ZeroVcmTrigger]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ThmTriggerCode, body |-> ZeroThmTrigger]] }

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

(* Every Add Order decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrder ==
    \A message \in CheckedAddOrder :
        LET read == DecodeAddOrder(EncodeAddOrder(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Aggregate Implied Order decodes back to what was encoded, and leaves nothing over *)
RoundTripAggregateImpliedOrder ==
    \A message \in CheckedAggregateImpliedOrder :
        LET read == DecodeAggregateImpliedOrder(EncodeAggregateImpliedOrder(message))
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

(* Every Commodity Definition decodes back to what was encoded, and leaves nothing over *)
RoundTripCommodityDefinition ==
    \A message \in CheckedCommodityDefinition :
        LET read == DecodeCommodityDefinition(EncodeCommodityDefinition(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Class Definition decodes back to what was encoded, and leaves nothing over *)
RoundTripClassDefinition ==
    \A message \in CheckedClassDefinition :
        LET read == DecodeClassDefinition(EncodeClassDefinition(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Definition decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentDefinition ==
    \A message \in CheckedInstrumentDefinition :
        LET read == DecodeInstrumentDefinition(EncodeInstrumentDefinition(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Combination Definition decodes back to what was encoded, and leaves nothing over *)
RoundTripCombinationDefinition ==
    \A message \in CheckedCombinationDefinition :
        LET read == DecodeCombinationDefinition(EncodeCombinationDefinition(message))
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

(* Every Market Status decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketStatus ==
    \A message \in CheckedMarketStatus :
        LET read == DecodeMarketStatus(EncodeMarketStatus(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Status decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentStatus ==
    \A message \in CheckedInstrumentStatus :
        LET read == DecodeInstrumentStatus(EncodeInstrumentStatus(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Commodity And Class Status decodes back to what was encoded, and leaves nothing over *)
RoundTripCommodityAndClassStatus ==
    \A message \in CheckedCommodityAndClassStatus :
        LET read == DecodeCommodityAndClassStatus(EncodeCommodityAndClassStatus(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Vcm Trigger decodes back to what was encoded, and leaves nothing over *)
RoundTripVcmTrigger ==
    \A message \in CheckedVcmTrigger :
        LET read == DecodeVcmTrigger(EncodeVcmTrigger(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Thm Trigger decodes back to what was encoded, and leaves nothing over *)
RoundTripThmTrigger ==
    \A message \in CheckedThmTrigger :
        LET read == DecodeThmTrigger(EncodeThmTrigger(message))
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
