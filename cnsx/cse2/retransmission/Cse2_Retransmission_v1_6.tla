--------------------- MODULE Cse2_Retransmission_v1_6 ----------------------
(***************************************************************************)
(* Canadian Securities Exchange CSE2 Multicast Market Data Retransmission  *)
(* v1.6                                                                    *)
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
(* Time Message: 6 bytes                                                   *)
(***************************************************************************)

TimeMessage ==
    [ second      : Sample(4),
      millisecond : Sample(2) ]

EncodeTimeMessage(message) ==
    message.second
        \o message.millisecond

DecodeTimeMessage(bytes) ==
    LET second == ReadBytes(bytes, 4) IN IF ~second.ok THEN Fail ELSE
    LET millisecond == ReadBytes(second.rest, 2) IN IF ~millisecond.ok THEN Fail ELSE
    Ok([ second      |-> second.value,
         millisecond |-> millisecond.value ], millisecond.rest)

ZeroTimeMessage ==
    [ second      |-> [i \in 1 .. 4 |-> 0],
      millisecond |-> [i \in 1 .. 2 |-> 0] ]

(* Time Message at zero, then each field in turn at the values it is checked at *)
CheckedTimeMessage ==
    { ZeroTimeMessage }
        \cup { [ZeroTimeMessage EXCEPT !.second = one] : one \in Sample(4) }
        \cup { [ZeroTimeMessage EXCEPT !.millisecond = one] : one \in Sample(2) }

(***************************************************************************)
(* System Event Message: 21 bytes                                          *)
(***************************************************************************)

SystemEventMessage ==
    [ timeOffset        : Sample(4),
      group             : Sample(8),
      eventCode         : Sample(1),
      exchangeTimestamp : Sample(8) ]

EncodeSystemEventMessage(message) ==
    message.timeOffset
        \o message.group
        \o message.eventCode
        \o message.exchangeTimestamp

DecodeSystemEventMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET group == ReadBytes(timeOffset.rest, 8) IN IF ~group.ok THEN Fail ELSE
    LET eventCode == ReadBytes(group.rest, 1) IN IF ~eventCode.ok THEN Fail ELSE
    LET exchangeTimestamp == ReadBytes(eventCode.rest, 8) IN IF ~exchangeTimestamp.ok THEN Fail ELSE
    Ok([ timeOffset        |-> timeOffset.value,
         group             |-> group.value,
         eventCode         |-> eventCode.value,
         exchangeTimestamp |-> exchangeTimestamp.value ], exchangeTimestamp.rest)

ZeroSystemEventMessage ==
    [ timeOffset        |-> [i \in 1 .. 4 |-> 0],
      group             |-> [i \in 1 .. 8 |-> 0],
      eventCode         |-> [i \in 1 .. 1 |-> 0],
      exchangeTimestamp |-> [i \in 1 .. 8 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroSystemEventMessage EXCEPT !.group = one] : one \in Sample(8) }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventCode = one] : one \in Sample(1) }
        \cup { [ZeroSystemEventMessage EXCEPT !.exchangeTimestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Symbol Directory Message: 195 bytes                                     *)
(***************************************************************************)

SymbolDirectoryMessage ==
    [ timeOffset             : Sample(4),
      symbol                 : Sample(12),
      cusip                  : Sample(12),
      secName                : Sample(15),
      currency               : Sample(3),
      stockGroup             : Sample(8),
      listing                : Sample(8),
      expiry                 : Sample(8),
      lotSize                : Sample(4),
      settlementTerm         : Sample(8),
      listingMarket          : Sample(1),
      previousClosingPrice   : Sample(4),
      listingTier            : Sample(1),
      marketMakerName        : Sample(20),
      marketMakerPhoneNumber : Sample(12),
      fullSecName            : Sample(75) ]

EncodeSymbolDirectoryMessage(message) ==
    message.timeOffset
        \o message.symbol
        \o message.cusip
        \o message.secName
        \o message.currency
        \o message.stockGroup
        \o message.listing
        \o message.expiry
        \o message.lotSize
        \o message.settlementTerm
        \o message.listingMarket
        \o message.previousClosingPrice
        \o message.listingTier
        \o message.marketMakerName
        \o message.marketMakerPhoneNumber
        \o message.fullSecName

DecodeSymbolDirectoryMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET symbol == ReadBytes(timeOffset.rest, 12) IN IF ~symbol.ok THEN Fail ELSE
    LET cusip == ReadBytes(symbol.rest, 12) IN IF ~cusip.ok THEN Fail ELSE
    LET secName == ReadBytes(cusip.rest, 15) IN IF ~secName.ok THEN Fail ELSE
    LET currency == ReadBytes(secName.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET stockGroup == ReadBytes(currency.rest, 8) IN IF ~stockGroup.ok THEN Fail ELSE
    LET listing == ReadBytes(stockGroup.rest, 8) IN IF ~listing.ok THEN Fail ELSE
    LET expiry == ReadBytes(listing.rest, 8) IN IF ~expiry.ok THEN Fail ELSE
    LET lotSize == ReadBytes(expiry.rest, 4) IN IF ~lotSize.ok THEN Fail ELSE
    LET settlementTerm == ReadBytes(lotSize.rest, 8) IN IF ~settlementTerm.ok THEN Fail ELSE
    LET listingMarket == ReadBytes(settlementTerm.rest, 1) IN IF ~listingMarket.ok THEN Fail ELSE
    LET previousClosingPrice == ReadBytes(listingMarket.rest, 4) IN IF ~previousClosingPrice.ok THEN Fail ELSE
    LET listingTier == ReadBytes(previousClosingPrice.rest, 1) IN IF ~listingTier.ok THEN Fail ELSE
    LET marketMakerName == ReadBytes(listingTier.rest, 20) IN IF ~marketMakerName.ok THEN Fail ELSE
    LET marketMakerPhoneNumber == ReadBytes(marketMakerName.rest, 12) IN IF ~marketMakerPhoneNumber.ok THEN Fail ELSE
    LET fullSecName == ReadBytes(marketMakerPhoneNumber.rest, 75) IN IF ~fullSecName.ok THEN Fail ELSE
    Ok([ timeOffset             |-> timeOffset.value,
         symbol                 |-> symbol.value,
         cusip                  |-> cusip.value,
         secName                |-> secName.value,
         currency               |-> currency.value,
         stockGroup             |-> stockGroup.value,
         listing                |-> listing.value,
         expiry                 |-> expiry.value,
         lotSize                |-> lotSize.value,
         settlementTerm         |-> settlementTerm.value,
         listingMarket          |-> listingMarket.value,
         previousClosingPrice   |-> previousClosingPrice.value,
         listingTier            |-> listingTier.value,
         marketMakerName        |-> marketMakerName.value,
         marketMakerPhoneNumber |-> marketMakerPhoneNumber.value,
         fullSecName            |-> fullSecName.value ], fullSecName.rest)

ZeroSymbolDirectoryMessage ==
    [ timeOffset             |-> [i \in 1 .. 4 |-> 0],
      symbol                 |-> [i \in 1 .. 12 |-> 0],
      cusip                  |-> [i \in 1 .. 12 |-> 0],
      secName                |-> [i \in 1 .. 15 |-> 0],
      currency               |-> [i \in 1 .. 3 |-> 0],
      stockGroup             |-> [i \in 1 .. 8 |-> 0],
      listing                |-> [i \in 1 .. 8 |-> 0],
      expiry                 |-> [i \in 1 .. 8 |-> 0],
      lotSize                |-> [i \in 1 .. 4 |-> 0],
      settlementTerm         |-> [i \in 1 .. 8 |-> 0],
      listingMarket          |-> [i \in 1 .. 1 |-> 0],
      previousClosingPrice   |-> [i \in 1 .. 4 |-> 0],
      listingTier            |-> [i \in 1 .. 1 |-> 0],
      marketMakerName        |-> [i \in 1 .. 20 |-> 0],
      marketMakerPhoneNumber |-> [i \in 1 .. 12 |-> 0],
      fullSecName            |-> [i \in 1 .. 75 |-> 0] ]

(* Symbol Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedSymbolDirectoryMessage ==
    { ZeroSymbolDirectoryMessage }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.symbol = one] : one \in Sample(12) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.cusip = one] : one \in Sample(12) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.secName = one] : one \in Sample(15) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.stockGroup = one] : one \in Sample(8) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.listing = one] : one \in Sample(8) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.expiry = one] : one \in Sample(8) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.lotSize = one] : one \in Sample(4) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.settlementTerm = one] : one \in Sample(8) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.listingMarket = one] : one \in Sample(1) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.previousClosingPrice = one] : one \in Sample(4) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.listingTier = one] : one \in Sample(1) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.marketMakerName = one] : one \in Sample(20) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.marketMakerPhoneNumber = one] : one \in Sample(12) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.fullSecName = one] : one \in Sample(75) }

(***************************************************************************)
(* Symbol Dynamics Message: 35 bytes                                       *)
(***************************************************************************)

SymbolDynamicsMessage ==
    [ timeOffset       : Sample(4),
      symbol           : Sample(12),
      settlementTerm   : Sample(8),
      gmfSetting       : Sample(1),
      gmfVolume        : Sample(8),
      anonymousSetting : Sample(1),
      mocEligible      : Sample(1) ]

EncodeSymbolDynamicsMessage(message) ==
    message.timeOffset
        \o message.symbol
        \o message.settlementTerm
        \o message.gmfSetting
        \o message.gmfVolume
        \o message.anonymousSetting
        \o message.mocEligible

DecodeSymbolDynamicsMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET symbol == ReadBytes(timeOffset.rest, 12) IN IF ~symbol.ok THEN Fail ELSE
    LET settlementTerm == ReadBytes(symbol.rest, 8) IN IF ~settlementTerm.ok THEN Fail ELSE
    LET gmfSetting == ReadBytes(settlementTerm.rest, 1) IN IF ~gmfSetting.ok THEN Fail ELSE
    LET gmfVolume == ReadBytes(gmfSetting.rest, 8) IN IF ~gmfVolume.ok THEN Fail ELSE
    LET anonymousSetting == ReadBytes(gmfVolume.rest, 1) IN IF ~anonymousSetting.ok THEN Fail ELSE
    LET mocEligible == ReadBytes(anonymousSetting.rest, 1) IN IF ~mocEligible.ok THEN Fail ELSE
    Ok([ timeOffset       |-> timeOffset.value,
         symbol           |-> symbol.value,
         settlementTerm   |-> settlementTerm.value,
         gmfSetting       |-> gmfSetting.value,
         gmfVolume        |-> gmfVolume.value,
         anonymousSetting |-> anonymousSetting.value,
         mocEligible      |-> mocEligible.value ], mocEligible.rest)

ZeroSymbolDynamicsMessage ==
    [ timeOffset       |-> [i \in 1 .. 4 |-> 0],
      symbol           |-> [i \in 1 .. 12 |-> 0],
      settlementTerm   |-> [i \in 1 .. 8 |-> 0],
      gmfSetting       |-> [i \in 1 .. 1 |-> 0],
      gmfVolume        |-> [i \in 1 .. 8 |-> 0],
      anonymousSetting |-> [i \in 1 .. 1 |-> 0],
      mocEligible      |-> [i \in 1 .. 1 |-> 0] ]

(* Symbol Dynamics Message at zero, then each field in turn at the values it is checked at *)
CheckedSymbolDynamicsMessage ==
    { ZeroSymbolDynamicsMessage }
        \cup { [ZeroSymbolDynamicsMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroSymbolDynamicsMessage EXCEPT !.symbol = one] : one \in Sample(12) }
        \cup { [ZeroSymbolDynamicsMessage EXCEPT !.settlementTerm = one] : one \in Sample(8) }
        \cup { [ZeroSymbolDynamicsMessage EXCEPT !.gmfSetting = one] : one \in Sample(1) }
        \cup { [ZeroSymbolDynamicsMessage EXCEPT !.gmfVolume = one] : one \in Sample(8) }
        \cup { [ZeroSymbolDynamicsMessage EXCEPT !.anonymousSetting = one] : one \in Sample(1) }
        \cup { [ZeroSymbolDynamicsMessage EXCEPT !.mocEligible = one] : one \in Sample(1) }

(***************************************************************************)
(* Trading Action Message: 25 bytes                                        *)
(***************************************************************************)

TradingActionMessage ==
    [ timeOffset        : Sample(4),
      symbol            : Sample(12),
      tradingState      : Sample(1),
      exchangeTimestamp : Sample(8) ]

EncodeTradingActionMessage(message) ==
    message.timeOffset
        \o message.symbol
        \o message.tradingState
        \o message.exchangeTimestamp

DecodeTradingActionMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET symbol == ReadBytes(timeOffset.rest, 12) IN IF ~symbol.ok THEN Fail ELSE
    LET tradingState == ReadBytes(symbol.rest, 1) IN IF ~tradingState.ok THEN Fail ELSE
    LET exchangeTimestamp == ReadBytes(tradingState.rest, 8) IN IF ~exchangeTimestamp.ok THEN Fail ELSE
    Ok([ timeOffset        |-> timeOffset.value,
         symbol            |-> symbol.value,
         tradingState      |-> tradingState.value,
         exchangeTimestamp |-> exchangeTimestamp.value ], exchangeTimestamp.rest)

ZeroTradingActionMessage ==
    [ timeOffset        |-> [i \in 1 .. 4 |-> 0],
      symbol            |-> [i \in 1 .. 12 |-> 0],
      tradingState      |-> [i \in 1 .. 1 |-> 0],
      exchangeTimestamp |-> [i \in 1 .. 8 |-> 0] ]

(* Trading Action Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingActionMessage ==
    { ZeroTradingActionMessage }
        \cup { [ZeroTradingActionMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroTradingActionMessage EXCEPT !.symbol = one] : one \in Sample(12) }
        \cup { [ZeroTradingActionMessage EXCEPT !.tradingState = one] : one \in Sample(1) }
        \cup { [ZeroTradingActionMessage EXCEPT !.exchangeTimestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Add Order Message: 71 bytes                                             *)
(***************************************************************************)

AddOrderMessage ==
    [ timeOffset        : Sample(4),
      orderNumber       : Sample(18),
      orderVerb         : Sample(1),
      quantity          : Sample(4),
      symbol            : Sample(12),
      price             : Sample(4),
      firmId            : Sample(3),
      settlementTerm    : Sample(8),
      oddLotFlag        : Sample(1),
      exchangeTimestamp : Sample(8),
      priorityTimestamp : Sample(8) ]

EncodeAddOrderMessage(message) ==
    message.timeOffset
        \o message.orderNumber
        \o message.orderVerb
        \o message.quantity
        \o message.symbol
        \o message.price
        \o message.firmId
        \o message.settlementTerm
        \o message.oddLotFlag
        \o message.exchangeTimestamp
        \o message.priorityTimestamp

DecodeAddOrderMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(timeOffset.rest, 18) IN IF ~orderNumber.ok THEN Fail ELSE
    LET orderVerb == ReadBytes(orderNumber.rest, 1) IN IF ~orderVerb.ok THEN Fail ELSE
    LET quantity == ReadBytes(orderVerb.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET symbol == ReadBytes(quantity.rest, 12) IN IF ~symbol.ok THEN Fail ELSE
    LET price == ReadBytes(symbol.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET firmId == ReadBytes(price.rest, 3) IN IF ~firmId.ok THEN Fail ELSE
    LET settlementTerm == ReadBytes(firmId.rest, 8) IN IF ~settlementTerm.ok THEN Fail ELSE
    LET oddLotFlag == ReadBytes(settlementTerm.rest, 1) IN IF ~oddLotFlag.ok THEN Fail ELSE
    LET exchangeTimestamp == ReadBytes(oddLotFlag.rest, 8) IN IF ~exchangeTimestamp.ok THEN Fail ELSE
    LET priorityTimestamp == ReadBytes(exchangeTimestamp.rest, 8) IN IF ~priorityTimestamp.ok THEN Fail ELSE
    Ok([ timeOffset        |-> timeOffset.value,
         orderNumber       |-> orderNumber.value,
         orderVerb         |-> orderVerb.value,
         quantity          |-> quantity.value,
         symbol            |-> symbol.value,
         price             |-> price.value,
         firmId            |-> firmId.value,
         settlementTerm    |-> settlementTerm.value,
         oddLotFlag        |-> oddLotFlag.value,
         exchangeTimestamp |-> exchangeTimestamp.value,
         priorityTimestamp |-> priorityTimestamp.value ], priorityTimestamp.rest)

ZeroAddOrderMessage ==
    [ timeOffset        |-> [i \in 1 .. 4 |-> 0],
      orderNumber       |-> [i \in 1 .. 18 |-> 0],
      orderVerb         |-> [i \in 1 .. 1 |-> 0],
      quantity          |-> [i \in 1 .. 4 |-> 0],
      symbol            |-> [i \in 1 .. 12 |-> 0],
      price             |-> [i \in 1 .. 4 |-> 0],
      firmId            |-> [i \in 1 .. 3 |-> 0],
      settlementTerm    |-> [i \in 1 .. 8 |-> 0],
      oddLotFlag        |-> [i \in 1 .. 1 |-> 0],
      exchangeTimestamp |-> [i \in 1 .. 8 |-> 0],
      priorityTimestamp |-> [i \in 1 .. 8 |-> 0] ]

(* Add Order Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderMessage ==
    { ZeroAddOrderMessage }
        \cup { [ZeroAddOrderMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderNumber = one] : one \in Sample(18) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderVerb = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.symbol = one] : one \in Sample(12) }
        \cup { [ZeroAddOrderMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.firmId = one] : one \in Sample(3) }
        \cup { [ZeroAddOrderMessage EXCEPT !.settlementTerm = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessage EXCEPT !.oddLotFlag = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.exchangeTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessage EXCEPT !.priorityTimestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Executed Message: 52 bytes                                        *)
(***************************************************************************)

OrderExecutedMessage ==
    [ timeOffset        : Sample(4),
      orderNumber       : Sample(18),
      executedQuantity  : Sample(4),
      matchNumber       : Sample(18),
      exchangeTimestamp : Sample(8) ]

EncodeOrderExecutedMessage(message) ==
    message.timeOffset
        \o message.orderNumber
        \o message.executedQuantity
        \o message.matchNumber
        \o message.exchangeTimestamp

DecodeOrderExecutedMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(timeOffset.rest, 18) IN IF ~orderNumber.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(orderNumber.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(executedQuantity.rest, 18) IN IF ~matchNumber.ok THEN Fail ELSE
    LET exchangeTimestamp == ReadBytes(matchNumber.rest, 8) IN IF ~exchangeTimestamp.ok THEN Fail ELSE
    Ok([ timeOffset        |-> timeOffset.value,
         orderNumber       |-> orderNumber.value,
         executedQuantity  |-> executedQuantity.value,
         matchNumber       |-> matchNumber.value,
         exchangeTimestamp |-> exchangeTimestamp.value ], exchangeTimestamp.rest)

ZeroOrderExecutedMessage ==
    [ timeOffset        |-> [i \in 1 .. 4 |-> 0],
      orderNumber       |-> [i \in 1 .. 18 |-> 0],
      executedQuantity  |-> [i \in 1 .. 4 |-> 0],
      matchNumber       |-> [i \in 1 .. 18 |-> 0],
      exchangeTimestamp |-> [i \in 1 .. 8 |-> 0] ]

(* Order Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedMessage ==
    { ZeroOrderExecutedMessage }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.orderNumber = one] : one \in Sample(18) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.matchNumber = one] : one \in Sample(18) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.exchangeTimestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Executed With Price Message: 56 bytes                             *)
(***************************************************************************)

OrderExecutedWithPriceMessage ==
    [ timeOffset        : Sample(4),
      orderNumber       : Sample(18),
      executedQuantity  : Sample(4),
      matchNumber       : Sample(18),
      executionPrice    : Sample(4),
      exchangeTimestamp : Sample(8) ]

EncodeOrderExecutedWithPriceMessage(message) ==
    message.timeOffset
        \o message.orderNumber
        \o message.executedQuantity
        \o message.matchNumber
        \o message.executionPrice
        \o message.exchangeTimestamp

DecodeOrderExecutedWithPriceMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(timeOffset.rest, 18) IN IF ~orderNumber.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(orderNumber.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(executedQuantity.rest, 18) IN IF ~matchNumber.ok THEN Fail ELSE
    LET executionPrice == ReadBytes(matchNumber.rest, 4) IN IF ~executionPrice.ok THEN Fail ELSE
    LET exchangeTimestamp == ReadBytes(executionPrice.rest, 8) IN IF ~exchangeTimestamp.ok THEN Fail ELSE
    Ok([ timeOffset        |-> timeOffset.value,
         orderNumber       |-> orderNumber.value,
         executedQuantity  |-> executedQuantity.value,
         matchNumber       |-> matchNumber.value,
         executionPrice    |-> executionPrice.value,
         exchangeTimestamp |-> exchangeTimestamp.value ], exchangeTimestamp.rest)

ZeroOrderExecutedWithPriceMessage ==
    [ timeOffset        |-> [i \in 1 .. 4 |-> 0],
      orderNumber       |-> [i \in 1 .. 18 |-> 0],
      executedQuantity  |-> [i \in 1 .. 4 |-> 0],
      matchNumber       |-> [i \in 1 .. 18 |-> 0],
      executionPrice    |-> [i \in 1 .. 4 |-> 0],
      exchangeTimestamp |-> [i \in 1 .. 8 |-> 0] ]

(* Order Executed With Price Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedWithPriceMessage ==
    { ZeroOrderExecutedWithPriceMessage }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.orderNumber = one] : one \in Sample(18) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.matchNumber = one] : one \in Sample(18) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.executionPrice = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.exchangeTimestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Message: 71 bytes                                                 *)
(***************************************************************************)

TradeMessage ==
    [ timeOffset        : Sample(4),
      executedQuantity  : Sample(4),
      symbol            : Sample(12),
      executionPrice    : Sample(4),
      matchNumber       : Sample(18),
      firmId            : Sample(3),
      contraFirmId      : Sample(3),
      settlementTerm    : Sample(8),
      tradeAttribute    : Sample(1),
      crossType         : Sample(1),
      oddLotFlag        : Sample(1),
      setsTheLastPrice  : Sample(1),
      exchangeTimestamp : Sample(8),
      openingTrade      : Sample(1),
      ccpSessionTrade   : Sample(1),
      mocTradeMarker    : Sample(1) ]

EncodeTradeMessage(message) ==
    message.timeOffset
        \o message.executedQuantity
        \o message.symbol
        \o message.executionPrice
        \o message.matchNumber
        \o message.firmId
        \o message.contraFirmId
        \o message.settlementTerm
        \o message.tradeAttribute
        \o message.crossType
        \o message.oddLotFlag
        \o message.setsTheLastPrice
        \o message.exchangeTimestamp
        \o message.openingTrade
        \o message.ccpSessionTrade
        \o message.mocTradeMarker

DecodeTradeMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(timeOffset.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET symbol == ReadBytes(executedQuantity.rest, 12) IN IF ~symbol.ok THEN Fail ELSE
    LET executionPrice == ReadBytes(symbol.rest, 4) IN IF ~executionPrice.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(executionPrice.rest, 18) IN IF ~matchNumber.ok THEN Fail ELSE
    LET firmId == ReadBytes(matchNumber.rest, 3) IN IF ~firmId.ok THEN Fail ELSE
    LET contraFirmId == ReadBytes(firmId.rest, 3) IN IF ~contraFirmId.ok THEN Fail ELSE
    LET settlementTerm == ReadBytes(contraFirmId.rest, 8) IN IF ~settlementTerm.ok THEN Fail ELSE
    LET tradeAttribute == ReadBytes(settlementTerm.rest, 1) IN IF ~tradeAttribute.ok THEN Fail ELSE
    LET crossType == ReadBytes(tradeAttribute.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET oddLotFlag == ReadBytes(crossType.rest, 1) IN IF ~oddLotFlag.ok THEN Fail ELSE
    LET setsTheLastPrice == ReadBytes(oddLotFlag.rest, 1) IN IF ~setsTheLastPrice.ok THEN Fail ELSE
    LET exchangeTimestamp == ReadBytes(setsTheLastPrice.rest, 8) IN IF ~exchangeTimestamp.ok THEN Fail ELSE
    LET openingTrade == ReadBytes(exchangeTimestamp.rest, 1) IN IF ~openingTrade.ok THEN Fail ELSE
    LET ccpSessionTrade == ReadBytes(openingTrade.rest, 1) IN IF ~ccpSessionTrade.ok THEN Fail ELSE
    LET mocTradeMarker == ReadBytes(ccpSessionTrade.rest, 1) IN IF ~mocTradeMarker.ok THEN Fail ELSE
    Ok([ timeOffset        |-> timeOffset.value,
         executedQuantity  |-> executedQuantity.value,
         symbol            |-> symbol.value,
         executionPrice    |-> executionPrice.value,
         matchNumber       |-> matchNumber.value,
         firmId            |-> firmId.value,
         contraFirmId      |-> contraFirmId.value,
         settlementTerm    |-> settlementTerm.value,
         tradeAttribute    |-> tradeAttribute.value,
         crossType         |-> crossType.value,
         oddLotFlag        |-> oddLotFlag.value,
         setsTheLastPrice  |-> setsTheLastPrice.value,
         exchangeTimestamp |-> exchangeTimestamp.value,
         openingTrade      |-> openingTrade.value,
         ccpSessionTrade   |-> ccpSessionTrade.value,
         mocTradeMarker    |-> mocTradeMarker.value ], mocTradeMarker.rest)

ZeroTradeMessage ==
    [ timeOffset        |-> [i \in 1 .. 4 |-> 0],
      executedQuantity  |-> [i \in 1 .. 4 |-> 0],
      symbol            |-> [i \in 1 .. 12 |-> 0],
      executionPrice    |-> [i \in 1 .. 4 |-> 0],
      matchNumber       |-> [i \in 1 .. 18 |-> 0],
      firmId            |-> [i \in 1 .. 3 |-> 0],
      contraFirmId      |-> [i \in 1 .. 3 |-> 0],
      settlementTerm    |-> [i \in 1 .. 8 |-> 0],
      tradeAttribute    |-> [i \in 1 .. 1 |-> 0],
      crossType         |-> [i \in 1 .. 1 |-> 0],
      oddLotFlag        |-> [i \in 1 .. 1 |-> 0],
      setsTheLastPrice  |-> [i \in 1 .. 1 |-> 0],
      exchangeTimestamp |-> [i \in 1 .. 8 |-> 0],
      openingTrade      |-> [i \in 1 .. 1 |-> 0],
      ccpSessionTrade   |-> [i \in 1 .. 1 |-> 0],
      mocTradeMarker    |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.symbol = one] : one \in Sample(12) }
        \cup { [ZeroTradeMessage EXCEPT !.executionPrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.matchNumber = one] : one \in Sample(18) }
        \cup { [ZeroTradeMessage EXCEPT !.firmId = one] : one \in Sample(3) }
        \cup { [ZeroTradeMessage EXCEPT !.contraFirmId = one] : one \in Sample(3) }
        \cup { [ZeroTradeMessage EXCEPT !.settlementTerm = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeAttribute = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.oddLotFlag = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.setsTheLastPrice = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.exchangeTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.openingTrade = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.ccpSessionTrade = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.mocTradeMarker = one] : one \in Sample(1) }

(***************************************************************************)
(* Broken Trade Message: 31 bytes                                          *)
(***************************************************************************)

BrokenTradeMessage ==
    [ timeOffset        : Sample(4),
      matchNumber       : Sample(18),
      reason            : Sample(1),
      exchangeTimestamp : Sample(8) ]

EncodeBrokenTradeMessage(message) ==
    message.timeOffset
        \o message.matchNumber
        \o message.reason
        \o message.exchangeTimestamp

DecodeBrokenTradeMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(timeOffset.rest, 18) IN IF ~matchNumber.ok THEN Fail ELSE
    LET reason == ReadBytes(matchNumber.rest, 1) IN IF ~reason.ok THEN Fail ELSE
    LET exchangeTimestamp == ReadBytes(reason.rest, 8) IN IF ~exchangeTimestamp.ok THEN Fail ELSE
    Ok([ timeOffset        |-> timeOffset.value,
         matchNumber       |-> matchNumber.value,
         reason            |-> reason.value,
         exchangeTimestamp |-> exchangeTimestamp.value ], exchangeTimestamp.rest)

ZeroBrokenTradeMessage ==
    [ timeOffset        |-> [i \in 1 .. 4 |-> 0],
      matchNumber       |-> [i \in 1 .. 18 |-> 0],
      reason            |-> [i \in 1 .. 1 |-> 0],
      exchangeTimestamp |-> [i \in 1 .. 8 |-> 0] ]

(* Broken Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedBrokenTradeMessage ==
    { ZeroBrokenTradeMessage }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.matchNumber = one] : one \in Sample(18) }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.reason = one] : one \in Sample(1) }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.exchangeTimestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Delete Message: 30 bytes                                          *)
(***************************************************************************)

OrderDeleteMessage ==
    [ timeOffset        : Sample(4),
      orderNumber       : Sample(18),
      exchangeTimestamp : Sample(8) ]

EncodeOrderDeleteMessage(message) ==
    message.timeOffset
        \o message.orderNumber
        \o message.exchangeTimestamp

DecodeOrderDeleteMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(timeOffset.rest, 18) IN IF ~orderNumber.ok THEN Fail ELSE
    LET exchangeTimestamp == ReadBytes(orderNumber.rest, 8) IN IF ~exchangeTimestamp.ok THEN Fail ELSE
    Ok([ timeOffset        |-> timeOffset.value,
         orderNumber       |-> orderNumber.value,
         exchangeTimestamp |-> exchangeTimestamp.value ], exchangeTimestamp.rest)

ZeroOrderDeleteMessage ==
    [ timeOffset        |-> [i \in 1 .. 4 |-> 0],
      orderNumber       |-> [i \in 1 .. 18 |-> 0],
      exchangeTimestamp |-> [i \in 1 .. 8 |-> 0] ]

(* Order Delete Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderDeleteMessage ==
    { ZeroOrderDeleteMessage }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.orderNumber = one] : one \in Sample(18) }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.exchangeTimestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Replace Message: 38 bytes                                         *)
(***************************************************************************)

OrderReplaceMessage ==
    [ timeOffset        : Sample(4),
      orderNumber       : Sample(18),
      quantity          : Sample(4),
      price             : Sample(4),
      exchangeTimestamp : Sample(8) ]

EncodeOrderReplaceMessage(message) ==
    message.timeOffset
        \o message.orderNumber
        \o message.quantity
        \o message.price
        \o message.exchangeTimestamp

DecodeOrderReplaceMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(timeOffset.rest, 18) IN IF ~orderNumber.ok THEN Fail ELSE
    LET quantity == ReadBytes(orderNumber.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET exchangeTimestamp == ReadBytes(price.rest, 8) IN IF ~exchangeTimestamp.ok THEN Fail ELSE
    Ok([ timeOffset        |-> timeOffset.value,
         orderNumber       |-> orderNumber.value,
         quantity          |-> quantity.value,
         price             |-> price.value,
         exchangeTimestamp |-> exchangeTimestamp.value ], exchangeTimestamp.rest)

ZeroOrderReplaceMessage ==
    [ timeOffset        |-> [i \in 1 .. 4 |-> 0],
      orderNumber       |-> [i \in 1 .. 18 |-> 0],
      quantity          |-> [i \in 1 .. 4 |-> 0],
      price             |-> [i \in 1 .. 4 |-> 0],
      exchangeTimestamp |-> [i \in 1 .. 8 |-> 0] ]

(* Order Replace Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderReplaceMessage ==
    { ZeroOrderReplaceMessage }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.orderNumber = one] : one \in Sample(18) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.exchangeTimestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Best Bid Offer Message: 40 bytes                                        *)
(***************************************************************************)

BestBidOfferMessage ==
    [ timeOffset        : Sample(4),
      symbol            : Sample(12),
      bestBid           : Sample(4),
      bestBidSize       : Sample(4),
      bestOffer         : Sample(4),
      bestOfferSize     : Sample(4),
      exchangeTimestamp : Sample(8) ]

EncodeBestBidOfferMessage(message) ==
    message.timeOffset
        \o message.symbol
        \o message.bestBid
        \o message.bestBidSize
        \o message.bestOffer
        \o message.bestOfferSize
        \o message.exchangeTimestamp

DecodeBestBidOfferMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET symbol == ReadBytes(timeOffset.rest, 12) IN IF ~symbol.ok THEN Fail ELSE
    LET bestBid == ReadBytes(symbol.rest, 4) IN IF ~bestBid.ok THEN Fail ELSE
    LET bestBidSize == ReadBytes(bestBid.rest, 4) IN IF ~bestBidSize.ok THEN Fail ELSE
    LET bestOffer == ReadBytes(bestBidSize.rest, 4) IN IF ~bestOffer.ok THEN Fail ELSE
    LET bestOfferSize == ReadBytes(bestOffer.rest, 4) IN IF ~bestOfferSize.ok THEN Fail ELSE
    LET exchangeTimestamp == ReadBytes(bestOfferSize.rest, 8) IN IF ~exchangeTimestamp.ok THEN Fail ELSE
    Ok([ timeOffset        |-> timeOffset.value,
         symbol            |-> symbol.value,
         bestBid           |-> bestBid.value,
         bestBidSize       |-> bestBidSize.value,
         bestOffer         |-> bestOffer.value,
         bestOfferSize     |-> bestOfferSize.value,
         exchangeTimestamp |-> exchangeTimestamp.value ], exchangeTimestamp.rest)

ZeroBestBidOfferMessage ==
    [ timeOffset        |-> [i \in 1 .. 4 |-> 0],
      symbol            |-> [i \in 1 .. 12 |-> 0],
      bestBid           |-> [i \in 1 .. 4 |-> 0],
      bestBidSize       |-> [i \in 1 .. 4 |-> 0],
      bestOffer         |-> [i \in 1 .. 4 |-> 0],
      bestOfferSize     |-> [i \in 1 .. 4 |-> 0],
      exchangeTimestamp |-> [i \in 1 .. 8 |-> 0] ]

(* Best Bid Offer Message at zero, then each field in turn at the values it is checked at *)
CheckedBestBidOfferMessage ==
    { ZeroBestBidOfferMessage }
        \cup { [ZeroBestBidOfferMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroBestBidOfferMessage EXCEPT !.symbol = one] : one \in Sample(12) }
        \cup { [ZeroBestBidOfferMessage EXCEPT !.bestBid = one] : one \in Sample(4) }
        \cup { [ZeroBestBidOfferMessage EXCEPT !.bestBidSize = one] : one \in Sample(4) }
        \cup { [ZeroBestBidOfferMessage EXCEPT !.bestOffer = one] : one \in Sample(4) }
        \cup { [ZeroBestBidOfferMessage EXCEPT !.bestOfferSize = one] : one \in Sample(4) }
        \cup { [ZeroBestBidOfferMessage EXCEPT !.exchangeTimestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Closing Price Message: 20 bytes                                         *)
(***************************************************************************)

ClosingPriceMessage ==
    [ timeOffset : Sample(4),
      symbol     : Sample(12),
      price      : Sample(4) ]

EncodeClosingPriceMessage(message) ==
    message.timeOffset
        \o message.symbol
        \o message.price

DecodeClosingPriceMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET symbol == ReadBytes(timeOffset.rest, 12) IN IF ~symbol.ok THEN Fail ELSE
    LET price == ReadBytes(symbol.rest, 4) IN IF ~price.ok THEN Fail ELSE
    Ok([ timeOffset |-> timeOffset.value,
         symbol     |-> symbol.value,
         price      |-> price.value ], price.rest)

ZeroClosingPriceMessage ==
    [ timeOffset |-> [i \in 1 .. 4 |-> 0],
      symbol     |-> [i \in 1 .. 12 |-> 0],
      price      |-> [i \in 1 .. 4 |-> 0] ]

(* Closing Price Message at zero, then each field in turn at the values it is checked at *)
CheckedClosingPriceMessage ==
    { ZeroClosingPriceMessage }
        \cup { [ZeroClosingPriceMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroClosingPriceMessage EXCEPT !.symbol = one] : one \in Sample(12) }
        \cup { [ZeroClosingPriceMessage EXCEPT !.price = one] : one \in Sample(4) }

(***************************************************************************)
(* General Message: 132 bytes                                              *)
(***************************************************************************)

GeneralMessage ==
    [ timeOffset  : Sample(4),
      messageText : Sample(128) ]

EncodeGeneralMessage(message) ==
    message.timeOffset
        \o message.messageText

DecodeGeneralMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET messageText == ReadBytes(timeOffset.rest, 128) IN IF ~messageText.ok THEN Fail ELSE
    Ok([ timeOffset  |-> timeOffset.value,
         messageText |-> messageText.value ], messageText.rest)

ZeroGeneralMessage ==
    [ timeOffset  |-> [i \in 1 .. 4 |-> 0],
      messageText |-> [i \in 1 .. 128 |-> 0] ]

(* General Message at zero, then each field in turn at the values it is checked at *)
CheckedGeneralMessage ==
    { ZeroGeneralMessage }
        \cup { [ZeroGeneralMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroGeneralMessage EXCEPT !.messageText = one] : one \in Sample(128) }

(***************************************************************************)
(* Login Request Message: 32 bytes                                         *)
(***************************************************************************)

LoginRequestMessage ==
    [ userId   : Sample(16),
      password : Sample(16) ]

EncodeLoginRequestMessage(message) ==
    message.userId
        \o message.password

DecodeLoginRequestMessage(bytes) ==
    LET userId == ReadBytes(bytes, 16) IN IF ~userId.ok THEN Fail ELSE
    LET password == ReadBytes(userId.rest, 16) IN IF ~password.ok THEN Fail ELSE
    Ok([ userId   |-> userId.value,
         password |-> password.value ], password.rest)

ZeroLoginRequestMessage ==
    [ userId   |-> [i \in 1 .. 16 |-> 0],
      password |-> [i \in 1 .. 16 |-> 0] ]

(* Login Request Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginRequestMessage ==
    { ZeroLoginRequestMessage }
        \cup { [ZeroLoginRequestMessage EXCEPT !.userId = one] : one \in Sample(16) }
        \cup { [ZeroLoginRequestMessage EXCEPT !.password = one] : one \in Sample(16) }

(***************************************************************************)
(* Login Response Message: 17 bytes                                        *)
(***************************************************************************)

LoginResponseMessage ==
    [ userId      : Sample(16),
      loginStatus : Sample(1) ]

EncodeLoginResponseMessage(message) ==
    message.userId
        \o message.loginStatus

DecodeLoginResponseMessage(bytes) ==
    LET userId == ReadBytes(bytes, 16) IN IF ~userId.ok THEN Fail ELSE
    LET loginStatus == ReadBytes(userId.rest, 1) IN IF ~loginStatus.ok THEN Fail ELSE
    Ok([ userId      |-> userId.value,
         loginStatus |-> loginStatus.value ], loginStatus.rest)

ZeroLoginResponseMessage ==
    [ userId      |-> [i \in 1 .. 16 |-> 0],
      loginStatus |-> [i \in 1 .. 1 |-> 0] ]

(* Login Response Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginResponseMessage ==
    { ZeroLoginResponseMessage }
        \cup { [ZeroLoginResponseMessage EXCEPT !.userId = one] : one \in Sample(16) }
        \cup { [ZeroLoginResponseMessage EXCEPT !.loginStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Retransmission Request Message: 8 bytes                                 *)
(***************************************************************************)

RetransmissionRequestMessage ==
    [ startSequence    : Sample(4),
      numberOfMessages : Sample(4) ]

EncodeRetransmissionRequestMessage(message) ==
    message.startSequence
        \o message.numberOfMessages

DecodeRetransmissionRequestMessage(bytes) ==
    LET startSequence == ReadBytes(bytes, 4) IN IF ~startSequence.ok THEN Fail ELSE
    LET numberOfMessages == ReadBytes(startSequence.rest, 4) IN IF ~numberOfMessages.ok THEN Fail ELSE
    Ok([ startSequence    |-> startSequence.value,
         numberOfMessages |-> numberOfMessages.value ], numberOfMessages.rest)

ZeroRetransmissionRequestMessage ==
    [ startSequence    |-> [i \in 1 .. 4 |-> 0],
      numberOfMessages |-> [i \in 1 .. 4 |-> 0] ]

(* Retransmission Request Message at zero, then each field in turn at the values it is checked at *)
CheckedRetransmissionRequestMessage ==
    { ZeroRetransmissionRequestMessage }
        \cup { [ZeroRetransmissionRequestMessage EXCEPT !.startSequence = one] : one \in Sample(4) }
        \cup { [ZeroRetransmissionRequestMessage EXCEPT !.numberOfMessages = one] : one \in Sample(4) }

(***************************************************************************)
(* Retransmission Response Message: 9 bytes                                *)
(***************************************************************************)

RetransmissionResponseMessage ==
    [ startSequence        : Sample(4),
      numberOfMessages     : Sample(4),
      retransmissionStatus : Sample(1) ]

EncodeRetransmissionResponseMessage(message) ==
    message.startSequence
        \o message.numberOfMessages
        \o message.retransmissionStatus

DecodeRetransmissionResponseMessage(bytes) ==
    LET startSequence == ReadBytes(bytes, 4) IN IF ~startSequence.ok THEN Fail ELSE
    LET numberOfMessages == ReadBytes(startSequence.rest, 4) IN IF ~numberOfMessages.ok THEN Fail ELSE
    LET retransmissionStatus == ReadBytes(numberOfMessages.rest, 1) IN IF ~retransmissionStatus.ok THEN Fail ELSE
    Ok([ startSequence        |-> startSequence.value,
         numberOfMessages     |-> numberOfMessages.value,
         retransmissionStatus |-> retransmissionStatus.value ], retransmissionStatus.rest)

ZeroRetransmissionResponseMessage ==
    [ startSequence        |-> [i \in 1 .. 4 |-> 0],
      numberOfMessages     |-> [i \in 1 .. 4 |-> 0],
      retransmissionStatus |-> [i \in 1 .. 1 |-> 0] ]

(* Retransmission Response Message at zero, then each field in turn at the values it is checked at *)
CheckedRetransmissionResponseMessage ==
    { ZeroRetransmissionResponseMessage }
        \cup { [ZeroRetransmissionResponseMessage EXCEPT !.startSequence = one] : one \in Sample(4) }
        \cup { [ZeroRetransmissionResponseMessage EXCEPT !.numberOfMessages = one] : one \in Sample(4) }
        \cup { [ZeroRetransmissionResponseMessage EXCEPT !.retransmissionStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Spin Request Message: 4 bytes                                           *)
(***************************************************************************)

SpinRequestMessage ==
    [ clientIdentifier : Sample(4) ]

EncodeSpinRequestMessage(message) ==
    message.clientIdentifier

DecodeSpinRequestMessage(bytes) ==
    LET clientIdentifier == ReadBytes(bytes, 4) IN IF ~clientIdentifier.ok THEN Fail ELSE
    Ok([ clientIdentifier |-> clientIdentifier.value ], clientIdentifier.rest)

ZeroSpinRequestMessage ==
    [ clientIdentifier |-> [i \in 1 .. 4 |-> 0] ]

(* Spin Request Message at zero, then each field in turn at the values it is checked at *)
CheckedSpinRequestMessage ==
    { ZeroSpinRequestMessage }
        \cup { [ZeroSpinRequestMessage EXCEPT !.clientIdentifier = one] : one \in Sample(4) }

(***************************************************************************)
(* Spin Response Message: 5 bytes                                          *)
(***************************************************************************)

SpinResponseMessage ==
    [ clientIdentifier : Sample(4),
      spinStatus       : Sample(1) ]

EncodeSpinResponseMessage(message) ==
    message.clientIdentifier
        \o message.spinStatus

DecodeSpinResponseMessage(bytes) ==
    LET clientIdentifier == ReadBytes(bytes, 4) IN IF ~clientIdentifier.ok THEN Fail ELSE
    LET spinStatus == ReadBytes(clientIdentifier.rest, 1) IN IF ~spinStatus.ok THEN Fail ELSE
    Ok([ clientIdentifier |-> clientIdentifier.value,
         spinStatus       |-> spinStatus.value ], spinStatus.rest)

ZeroSpinResponseMessage ==
    [ clientIdentifier |-> [i \in 1 .. 4 |-> 0],
      spinStatus       |-> [i \in 1 .. 1 |-> 0] ]

(* Spin Response Message at zero, then each field in turn at the values it is checked at *)
CheckedSpinResponseMessage ==
    { ZeroSpinResponseMessage }
        \cup { [ZeroSpinResponseMessage EXCEPT !.clientIdentifier = one] : one \in Sample(4) }
        \cup { [ZeroSpinResponseMessage EXCEPT !.spinStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Heartbeat Message: 4 bytes                                              *)
(***************************************************************************)

HeartbeatMessage ==
    [ clientIdentifier : Sample(4) ]

EncodeHeartbeatMessage(message) ==
    message.clientIdentifier

DecodeHeartbeatMessage(bytes) ==
    LET clientIdentifier == ReadBytes(bytes, 4) IN IF ~clientIdentifier.ok THEN Fail ELSE
    Ok([ clientIdentifier |-> clientIdentifier.value ], clientIdentifier.rest)

ZeroHeartbeatMessage ==
    [ clientIdentifier |-> [i \in 1 .. 4 |-> 0] ]

(* Heartbeat Message at zero, then each field in turn at the values it is checked at *)
CheckedHeartbeatMessage ==
    { ZeroHeartbeatMessage }
        \cup { [ZeroHeartbeatMessage EXCEPT !.clientIdentifier = one] : one \in Sample(4) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

TimeMessageCode == 84  \* "T"
SystemEventMessageCode == 83  \* "S"
SymbolDirectoryMessageCode == 82  \* "R"
SymbolDynamicsMessageCode == 79  \* "O"
TradingActionMessageCode == 72  \* "H"
AddOrderMessageCode == 65  \* "A"
OrderExecutedMessageCode == 69  \* "E"
OrderExecutedWithPriceMessageCode == 67  \* "C"
TradeMessageCode == 80  \* "P"
BrokenTradeMessageCode == 66  \* "B"
OrderDeleteMessageCode == 68  \* "D"
OrderReplaceMessageCode == 85  \* "U"
BestBidOfferMessageCode == 81  \* "Q"
ClosingPriceMessageCode == 70  \* "F"
GeneralMessageCode == 71  \* "G"
LoginRequestMessageCode == 108  \* "l"
LoginResponseMessageCode == 97  \* "a"
RetransmissionRequestMessageCode == 114  \* "r"
RetransmissionResponseMessageCode == 98  \* "b"
SpinRequestMessageCode == 115  \* "s"
SpinResponseMessageCode == 99  \* "c"
HeartbeatMessageCode == 104  \* "h"

Payload ==
    [ tag : {TimeMessageCode}, body : TimeMessage ]
        \cup [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {SymbolDirectoryMessageCode}, body : SymbolDirectoryMessage ]
        \cup [ tag : {SymbolDynamicsMessageCode}, body : SymbolDynamicsMessage ]
        \cup [ tag : {TradingActionMessageCode}, body : TradingActionMessage ]
        \cup [ tag : {AddOrderMessageCode}, body : AddOrderMessage ]
        \cup [ tag : {OrderExecutedMessageCode}, body : OrderExecutedMessage ]
        \cup [ tag : {OrderExecutedWithPriceMessageCode}, body : OrderExecutedWithPriceMessage ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {BrokenTradeMessageCode}, body : BrokenTradeMessage ]
        \cup [ tag : {OrderDeleteMessageCode}, body : OrderDeleteMessage ]
        \cup [ tag : {OrderReplaceMessageCode}, body : OrderReplaceMessage ]
        \cup [ tag : {BestBidOfferMessageCode}, body : BestBidOfferMessage ]
        \cup [ tag : {ClosingPriceMessageCode}, body : ClosingPriceMessage ]
        \cup [ tag : {GeneralMessageCode}, body : GeneralMessage ]
        \cup [ tag : {LoginRequestMessageCode}, body : LoginRequestMessage ]
        \cup [ tag : {LoginResponseMessageCode}, body : LoginResponseMessage ]
        \cup [ tag : {RetransmissionRequestMessageCode}, body : RetransmissionRequestMessage ]
        \cup [ tag : {RetransmissionResponseMessageCode}, body : RetransmissionResponseMessage ]
        \cup [ tag : {SpinRequestMessageCode}, body : SpinRequestMessage ]
        \cup [ tag : {SpinResponseMessageCode}, body : SpinResponseMessage ]
        \cup [ tag : {HeartbeatMessageCode}, body : HeartbeatMessage ]

EncodePayload(message) ==
    CASE message.tag = TimeMessageCode -> EncodeTimeMessage(message.body)
      [] message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = SymbolDirectoryMessageCode -> EncodeSymbolDirectoryMessage(message.body)
      [] message.tag = SymbolDynamicsMessageCode -> EncodeSymbolDynamicsMessage(message.body)
      [] message.tag = TradingActionMessageCode -> EncodeTradingActionMessage(message.body)
      [] message.tag = AddOrderMessageCode -> EncodeAddOrderMessage(message.body)
      [] message.tag = OrderExecutedMessageCode -> EncodeOrderExecutedMessage(message.body)
      [] message.tag = OrderExecutedWithPriceMessageCode -> EncodeOrderExecutedWithPriceMessage(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = BrokenTradeMessageCode -> EncodeBrokenTradeMessage(message.body)
      [] message.tag = OrderDeleteMessageCode -> EncodeOrderDeleteMessage(message.body)
      [] message.tag = OrderReplaceMessageCode -> EncodeOrderReplaceMessage(message.body)
      [] message.tag = BestBidOfferMessageCode -> EncodeBestBidOfferMessage(message.body)
      [] message.tag = ClosingPriceMessageCode -> EncodeClosingPriceMessage(message.body)
      [] message.tag = GeneralMessageCode -> EncodeGeneralMessage(message.body)
      [] message.tag = LoginRequestMessageCode -> EncodeLoginRequestMessage(message.body)
      [] message.tag = LoginResponseMessageCode -> EncodeLoginResponseMessage(message.body)
      [] message.tag = RetransmissionRequestMessageCode -> EncodeRetransmissionRequestMessage(message.body)
      [] message.tag = RetransmissionResponseMessageCode -> EncodeRetransmissionResponseMessage(message.body)
      [] message.tag = SpinRequestMessageCode -> EncodeSpinRequestMessage(message.body)
      [] message.tag = SpinResponseMessageCode -> EncodeSpinResponseMessage(message.body)
      [] message.tag = HeartbeatMessageCode -> EncodeHeartbeatMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = TimeMessageCode -> DecodeTimeMessage(bytes)
              [] tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = SymbolDirectoryMessageCode -> DecodeSymbolDirectoryMessage(bytes)
              [] tag = SymbolDynamicsMessageCode -> DecodeSymbolDynamicsMessage(bytes)
              [] tag = TradingActionMessageCode -> DecodeTradingActionMessage(bytes)
              [] tag = AddOrderMessageCode -> DecodeAddOrderMessage(bytes)
              [] tag = OrderExecutedMessageCode -> DecodeOrderExecutedMessage(bytes)
              [] tag = OrderExecutedWithPriceMessageCode -> DecodeOrderExecutedWithPriceMessage(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = BrokenTradeMessageCode -> DecodeBrokenTradeMessage(bytes)
              [] tag = OrderDeleteMessageCode -> DecodeOrderDeleteMessage(bytes)
              [] tag = OrderReplaceMessageCode -> DecodeOrderReplaceMessage(bytes)
              [] tag = BestBidOfferMessageCode -> DecodeBestBidOfferMessage(bytes)
              [] tag = ClosingPriceMessageCode -> DecodeClosingPriceMessage(bytes)
              [] tag = GeneralMessageCode -> DecodeGeneralMessage(bytes)
              [] tag = LoginRequestMessageCode -> DecodeLoginRequestMessage(bytes)
              [] tag = LoginResponseMessageCode -> DecodeLoginResponseMessage(bytes)
              [] tag = RetransmissionRequestMessageCode -> DecodeRetransmissionRequestMessage(bytes)
              [] tag = RetransmissionResponseMessageCode -> DecodeRetransmissionResponseMessage(bytes)
              [] tag = SpinRequestMessageCode -> DecodeSpinRequestMessage(bytes)
              [] tag = SpinResponseMessageCode -> DecodeSpinResponseMessage(bytes)
              [] tag = HeartbeatMessageCode -> DecodeHeartbeatMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> TimeMessageCode, body |-> ZeroTimeMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> TimeMessageCode, body |-> one] : one \in CheckedTimeMessage }
        \cup { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> SymbolDirectoryMessageCode, body |-> one] : one \in CheckedSymbolDirectoryMessage }
        \cup { [tag |-> SymbolDynamicsMessageCode, body |-> one] : one \in CheckedSymbolDynamicsMessage }
        \cup { [tag |-> TradingActionMessageCode, body |-> one] : one \in CheckedTradingActionMessage }
        \cup { [tag |-> AddOrderMessageCode, body |-> one] : one \in CheckedAddOrderMessage }
        \cup { [tag |-> OrderExecutedMessageCode, body |-> one] : one \in CheckedOrderExecutedMessage }
        \cup { [tag |-> OrderExecutedWithPriceMessageCode, body |-> one] : one \in CheckedOrderExecutedWithPriceMessage }
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> BrokenTradeMessageCode, body |-> one] : one \in CheckedBrokenTradeMessage }
        \cup { [tag |-> OrderDeleteMessageCode, body |-> one] : one \in CheckedOrderDeleteMessage }
        \cup { [tag |-> OrderReplaceMessageCode, body |-> one] : one \in CheckedOrderReplaceMessage }
        \cup { [tag |-> BestBidOfferMessageCode, body |-> one] : one \in CheckedBestBidOfferMessage }
        \cup { [tag |-> ClosingPriceMessageCode, body |-> one] : one \in CheckedClosingPriceMessage }
        \cup { [tag |-> GeneralMessageCode, body |-> one] : one \in CheckedGeneralMessage }
        \cup { [tag |-> LoginRequestMessageCode, body |-> one] : one \in CheckedLoginRequestMessage }
        \cup { [tag |-> LoginResponseMessageCode, body |-> one] : one \in CheckedLoginResponseMessage }
        \cup { [tag |-> RetransmissionRequestMessageCode, body |-> one] : one \in CheckedRetransmissionRequestMessage }
        \cup { [tag |-> RetransmissionResponseMessageCode, body |-> one] : one \in CheckedRetransmissionResponseMessage }
        \cup { [tag |-> SpinRequestMessageCode, body |-> one] : one \in CheckedSpinRequestMessage }
        \cup { [tag |-> SpinResponseMessageCode, body |-> one] : one \in CheckedSpinResponseMessage }
        \cup { [tag |-> HeartbeatMessageCode, body |-> one] : one \in CheckedHeartbeatMessage }

(***************************************************************************)
(* Message, framed by Sub Length                                           *)
(***************************************************************************)

Message ==
    [ payload : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntBE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

(* Sub Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntBE(Len(body) + 1, 1) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntBE(bytes, 1) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 1 IN
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> TimeMessageCode, body |-> ZeroTimeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SymbolDirectoryMessageCode, body |-> ZeroSymbolDirectoryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SymbolDynamicsMessageCode, body |-> ZeroSymbolDynamicsMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradingActionMessageCode, body |-> ZeroTradingActionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddOrderMessageCode, body |-> ZeroAddOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderExecutedMessageCode, body |-> ZeroOrderExecutedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderExecutedWithPriceMessageCode, body |-> ZeroOrderExecutedWithPriceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeMessageCode, body |-> ZeroTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> BrokenTradeMessageCode, body |-> ZeroBrokenTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderDeleteMessageCode, body |-> ZeroOrderDeleteMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderReplaceMessageCode, body |-> ZeroOrderReplaceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> BestBidOfferMessageCode, body |-> ZeroBestBidOfferMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ClosingPriceMessageCode, body |-> ZeroClosingPriceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> GeneralMessageCode, body |-> ZeroGeneralMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LoginRequestMessageCode, body |-> ZeroLoginRequestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LoginResponseMessageCode, body |-> ZeroLoginResponseMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RetransmissionRequestMessageCode, body |-> ZeroRetransmissionRequestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RetransmissionResponseMessageCode, body |-> ZeroRetransmissionResponseMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SpinRequestMessageCode, body |-> ZeroSpinRequestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SpinResponseMessageCode, body |-> ZeroSpinResponseMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> HeartbeatMessageCode, body |-> ZeroHeartbeatMessage]] }

(***************************************************************************)
(* Block, framed by Block Length                                           *)
(***************************************************************************)

Block ==
    [ blockStartSequence : Sample(4),
      message            : SampleLists(OneMessage) ]

EncodeBlockBody(message) ==
    EncodeUIntBE(Len(message.message), 1)
        \o message.blockStartSequence
        \o EncodeMessageList(message.message)

(* Block Length counts the bytes it frames, so it is written from them *)
EncodeBlock(message) ==
    LET body == EncodeBlockBody(message)
    IN  EncodeUIntBE(Len(body) + 2, 2) \o body

DecodeBlockBody(bytes) ==
    LET blockNumberOfMessages == ReadUIntBE(bytes, 1) IN IF ~blockNumberOfMessages.ok THEN Fail ELSE
    LET blockStartSequence == ReadBytes(blockNumberOfMessages.rest, 4) IN IF ~blockStartSequence.ok THEN Fail ELSE
    LET message == ReadMessageList(blockStartSequence.rest, blockNumberOfMessages.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ blockStartSequence |-> blockStartSequence.value,
         message            |-> message.value ], message.rest)

DecodeBlock(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeBlockBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroBlock ==
    [ blockStartSequence |-> [i \in 1 .. 4 |-> 0],
      message            |-> << >> ]

(* Block at zero, then each field in turn at the values it is checked at *)
CheckedBlock ==
    { ZeroBlock }
        \cup { [ZeroBlock EXCEPT !.blockStartSequence = one] : one \in Sample(4) }
        \cup { [ZeroBlock EXCEPT !.message = one] : one \in SampleLists(OneMessage) }

(* A run of Block, written one after another *)
RECURSIVE EncodeBlockList(_)
EncodeBlockList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeBlock(Head(messages)) \o EncodeBlockList(Tail(messages))

(* As many Block as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadBlockAll(_)
ReadBlockAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeBlock(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadBlockAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Block of each kind, for the lists that carry them *)
OneBlock == { ZeroBlock }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ block : SampleLists(OneBlock) ]

EncodePacket(message) ==
    EncodeBlockList(message.block)

DecodePacket(bytes) ==
    LET block == ReadBlockAll(bytes) IN IF ~block.ok THEN Fail ELSE
    Ok([ block |-> block.value ], block.rest)

ZeroPacket ==
    [ block |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.block = one] : one \in SampleLists(OneBlock) }

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

(* Every Symbol Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolDirectoryMessage ==
    \A message \in CheckedSymbolDirectoryMessage :
        LET read == DecodeSymbolDirectoryMessage(EncodeSymbolDirectoryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol Dynamics Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolDynamicsMessage ==
    \A message \in CheckedSymbolDynamicsMessage :
        LET read == DecodeSymbolDynamicsMessage(EncodeSymbolDynamicsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trading Action Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingActionMessage ==
    \A message \in CheckedTradingActionMessage :
        LET read == DecodeTradingActionMessage(EncodeTradingActionMessage(message))
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

(* Every Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeMessage ==
    \A message \in CheckedTradeMessage :
        LET read == DecodeTradeMessage(EncodeTradeMessage(message))
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

(* Every Order Delete Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderDeleteMessage ==
    \A message \in CheckedOrderDeleteMessage :
        LET read == DecodeOrderDeleteMessage(EncodeOrderDeleteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Replace Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderReplaceMessage ==
    \A message \in CheckedOrderReplaceMessage :
        LET read == DecodeOrderReplaceMessage(EncodeOrderReplaceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Best Bid Offer Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBestBidOfferMessage ==
    \A message \in CheckedBestBidOfferMessage :
        LET read == DecodeBestBidOfferMessage(EncodeBestBidOfferMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Closing Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripClosingPriceMessage ==
    \A message \in CheckedClosingPriceMessage :
        LET read == DecodeClosingPriceMessage(EncodeClosingPriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every General Message decodes back to what was encoded, and leaves nothing over *)
RoundTripGeneralMessage ==
    \A message \in CheckedGeneralMessage :
        LET read == DecodeGeneralMessage(EncodeGeneralMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRequestMessage ==
    \A message \in CheckedLoginRequestMessage :
        LET read == DecodeLoginRequestMessage(EncodeLoginRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginResponseMessage ==
    \A message \in CheckedLoginResponseMessage :
        LET read == DecodeLoginResponseMessage(EncodeLoginResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Retransmission Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRetransmissionRequestMessage ==
    \A message \in CheckedRetransmissionRequestMessage :
        LET read == DecodeRetransmissionRequestMessage(EncodeRetransmissionRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Retransmission Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRetransmissionResponseMessage ==
    \A message \in CheckedRetransmissionResponseMessage :
        LET read == DecodeRetransmissionResponseMessage(EncodeRetransmissionResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Spin Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSpinRequestMessage ==
    \A message \in CheckedSpinRequestMessage :
        LET read == DecodeSpinRequestMessage(EncodeSpinRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Spin Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSpinResponseMessage ==
    \A message \in CheckedSpinResponseMessage :
        LET read == DecodeSpinResponseMessage(EncodeSpinResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Heartbeat Message decodes back to what was encoded, and leaves nothing over *)
RoundTripHeartbeatMessage ==
    \A message \in CheckedHeartbeatMessage :
        LET read == DecodeHeartbeatMessage(EncodeHeartbeatMessage(message))
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

(* Every Block decodes back to what was encoded, and leaves nothing over *)
RoundTripBlock ==
    \A message \in CheckedBlock :
        LET read == DecodeBlock(EncodeBlock(message))
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

(* Sub Length is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 1)) = Len(bytes) - 0

(* Block Length is written from the bytes it frames *)
FramesBlock ==
    \A message \in CheckedBlock :
        LET bytes == EncodeBlock(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
