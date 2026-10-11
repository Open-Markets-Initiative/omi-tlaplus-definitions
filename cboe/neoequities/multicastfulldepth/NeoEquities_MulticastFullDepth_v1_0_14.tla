-------------- MODULE NeoEquities_MulticastFullDepth_v1_0_14 ---------------
(***************************************************************************)
(* Chicago Board Options Exchange Multicast Full Depth v1.0.14             *)
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
(* Note: Allowed Book Types is a bit field set, checked as its 1 byte      *)
(* rather than bit by bit.                                                 *)
(*                                                                         *)
(* Note: Instrument Flags is a bit field set, checked as its 1 byte rather *)
(* than bit by bit.                                                        *)
(*                                                                         *)
(* Note: Execution Flags is a bit field set, checked as its 1 byte rather  *)
(* than bit by bit.                                                        *)
(*                                                                         *)
(* Note: Trade Flags is a bit field set, checked as its 1 byte rather than *)
(* bit by bit.                                                             *)
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
(* Unit Clear Message: 4 bytes                                             *)
(***************************************************************************)

UnitClearMessage ==
    [ reserved4 : Sample(4) ]

EncodeUnitClearMessage(message) ==
    message.reserved4

DecodeUnitClearMessage(bytes) ==
    LET reserved4 == ReadBytes(bytes, 4) IN IF ~reserved4.ok THEN Fail ELSE
    Ok([ reserved4 |-> reserved4.value ], reserved4.rest)

ZeroUnitClearMessage ==
    [ reserved4 |-> [i \in 1 .. 4 |-> 0] ]

(* Unit Clear Message at zero, then each field in turn at the values it is checked at *)
CheckedUnitClearMessage ==
    { ZeroUnitClearMessage }
        \cup { [ZeroUnitClearMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Instrument Directory Message: 168 bytes                                 *)
(***************************************************************************)

InstrumentDirectoryMessage ==
    [ timestamp         : Sample(8),
      allowedBookTypes  : Sample(1),
      symbol            : Sample(14),
      segment           : Sample(6),
      currency          : Sample(3),
      lotSize           : Sample(4),
      fullName          : Sample(120),
      activeMarketMaker : Sample(2),
      securityType      : Sample(1),
      instrumentFlags   : Sample(1),
      previousClose     : Sample(8) ]

EncodeInstrumentDirectoryMessage(message) ==
    message.timestamp
        \o message.allowedBookTypes
        \o message.symbol
        \o message.segment
        \o message.currency
        \o message.lotSize
        \o message.fullName
        \o message.activeMarketMaker
        \o message.securityType
        \o message.instrumentFlags
        \o message.previousClose

DecodeInstrumentDirectoryMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET allowedBookTypes == ReadBytes(timestamp.rest, 1) IN IF ~allowedBookTypes.ok THEN Fail ELSE
    LET symbol == ReadBytes(allowedBookTypes.rest, 14) IN IF ~symbol.ok THEN Fail ELSE
    LET segment == ReadBytes(symbol.rest, 6) IN IF ~segment.ok THEN Fail ELSE
    LET currency == ReadBytes(segment.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET lotSize == ReadBytes(currency.rest, 4) IN IF ~lotSize.ok THEN Fail ELSE
    LET fullName == ReadBytes(lotSize.rest, 120) IN IF ~fullName.ok THEN Fail ELSE
    LET activeMarketMaker == ReadBytes(fullName.rest, 2) IN IF ~activeMarketMaker.ok THEN Fail ELSE
    LET securityType == ReadBytes(activeMarketMaker.rest, 1) IN IF ~securityType.ok THEN Fail ELSE
    LET instrumentFlags == ReadBytes(securityType.rest, 1) IN IF ~instrumentFlags.ok THEN Fail ELSE
    LET previousClose == ReadBytes(instrumentFlags.rest, 8) IN IF ~previousClose.ok THEN Fail ELSE
    Ok([ timestamp         |-> timestamp.value,
         allowedBookTypes  |-> allowedBookTypes.value,
         symbol            |-> symbol.value,
         segment           |-> segment.value,
         currency          |-> currency.value,
         lotSize           |-> lotSize.value,
         fullName          |-> fullName.value,
         activeMarketMaker |-> activeMarketMaker.value,
         securityType      |-> securityType.value,
         instrumentFlags   |-> instrumentFlags.value,
         previousClose     |-> previousClose.value ], previousClose.rest)

ZeroInstrumentDirectoryMessage ==
    [ timestamp         |-> [i \in 1 .. 8 |-> 0],
      allowedBookTypes  |-> [i \in 1 .. 1 |-> 0],
      symbol            |-> [i \in 1 .. 14 |-> 0],
      segment           |-> [i \in 1 .. 6 |-> 0],
      currency          |-> [i \in 1 .. 3 |-> 0],
      lotSize           |-> [i \in 1 .. 4 |-> 0],
      fullName          |-> [i \in 1 .. 120 |-> 0],
      activeMarketMaker |-> [i \in 1 .. 2 |-> 0],
      securityType      |-> [i \in 1 .. 1 |-> 0],
      instrumentFlags   |-> [i \in 1 .. 1 |-> 0],
      previousClose     |-> [i \in 1 .. 8 |-> 0] ]

(* Instrument Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentDirectoryMessage ==
    { ZeroInstrumentDirectoryMessage }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.allowedBookTypes = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.symbol = one] : one \in Sample(14) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.segment = one] : one \in Sample(6) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.lotSize = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.fullName = one] : one \in Sample(120) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.activeMarketMaker = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.securityType = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.instrumentFlags = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.previousClose = one] : one \in Sample(8) }

(***************************************************************************)
(* Trading Status Message: 26 bytes                                        *)
(***************************************************************************)

TradingStatusMessage ==
    [ timestamp        : Sample(8),
      orderBookType    : Sample(1),
      symbol           : Sample(14),
      tradingStatus    : Sample(1),
      tradingSubStatus : Sample(1),
      haltReason       : Sample(1) ]

EncodeTradingStatusMessage(message) ==
    message.timestamp
        \o message.orderBookType
        \o message.symbol
        \o message.tradingStatus
        \o message.tradingSubStatus
        \o message.haltReason

DecodeTradingStatusMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderBookType == ReadBytes(timestamp.rest, 1) IN IF ~orderBookType.ok THEN Fail ELSE
    LET symbol == ReadBytes(orderBookType.rest, 14) IN IF ~symbol.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(symbol.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET tradingSubStatus == ReadBytes(tradingStatus.rest, 1) IN IF ~tradingSubStatus.ok THEN Fail ELSE
    LET haltReason == ReadBytes(tradingSubStatus.rest, 1) IN IF ~haltReason.ok THEN Fail ELSE
    Ok([ timestamp        |-> timestamp.value,
         orderBookType    |-> orderBookType.value,
         symbol           |-> symbol.value,
         tradingStatus    |-> tradingStatus.value,
         tradingSubStatus |-> tradingSubStatus.value,
         haltReason       |-> haltReason.value ], haltReason.rest)

ZeroTradingStatusMessage ==
    [ timestamp        |-> [i \in 1 .. 8 |-> 0],
      orderBookType    |-> [i \in 1 .. 1 |-> 0],
      symbol           |-> [i \in 1 .. 14 |-> 0],
      tradingStatus    |-> [i \in 1 .. 1 |-> 0],
      tradingSubStatus |-> [i \in 1 .. 1 |-> 0],
      haltReason       |-> [i \in 1 .. 1 |-> 0] ]

(* Trading Status Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingStatusMessage ==
    { ZeroTradingStatusMessage }
        \cup { [ZeroTradingStatusMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.orderBookType = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.symbol = one] : one \in Sample(14) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.tradingSubStatus = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.haltReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Add Order Message: 52 bytes                                             *)
(***************************************************************************)

AddOrderMessage ==
    [ timestamp      : Sample(8),
      orderBookType  : Sample(1),
      orderId        : Sample(8),
      sideIndicator  : Sample(1),
      quantity       : Sample(4),
      symbol         : Sample(14),
      price          : Sample(8),
      brokerId       : Sample(2),
      settlementType : Sample(1),
      settlementDate : Sample(4),
      reserved1      : Sample(1) ]

EncodeAddOrderMessage(message) ==
    message.timestamp
        \o message.orderBookType
        \o message.orderId
        \o message.sideIndicator
        \o message.quantity
        \o message.symbol
        \o message.price
        \o message.brokerId
        \o message.settlementType
        \o message.settlementDate
        \o message.reserved1

DecodeAddOrderMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderBookType == ReadBytes(timestamp.rest, 1) IN IF ~orderBookType.ok THEN Fail ELSE
    LET orderId == ReadBytes(orderBookType.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET quantity == ReadBytes(sideIndicator.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET symbol == ReadBytes(quantity.rest, 14) IN IF ~symbol.ok THEN Fail ELSE
    LET price == ReadBytes(symbol.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET brokerId == ReadBytes(price.rest, 2) IN IF ~brokerId.ok THEN Fail ELSE
    LET settlementType == ReadBytes(brokerId.rest, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET settlementDate == ReadBytes(settlementType.rest, 4) IN IF ~settlementDate.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(settlementDate.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ timestamp      |-> timestamp.value,
         orderBookType  |-> orderBookType.value,
         orderId        |-> orderId.value,
         sideIndicator  |-> sideIndicator.value,
         quantity       |-> quantity.value,
         symbol         |-> symbol.value,
         price          |-> price.value,
         brokerId       |-> brokerId.value,
         settlementType |-> settlementType.value,
         settlementDate |-> settlementDate.value,
         reserved1      |-> reserved1.value ], reserved1.rest)

ZeroAddOrderMessage ==
    [ timestamp      |-> [i \in 1 .. 8 |-> 0],
      orderBookType  |-> [i \in 1 .. 1 |-> 0],
      orderId        |-> [i \in 1 .. 8 |-> 0],
      sideIndicator  |-> [i \in 1 .. 1 |-> 0],
      quantity       |-> [i \in 1 .. 4 |-> 0],
      symbol         |-> [i \in 1 .. 14 |-> 0],
      price          |-> [i \in 1 .. 8 |-> 0],
      brokerId       |-> [i \in 1 .. 2 |-> 0],
      settlementType |-> [i \in 1 .. 1 |-> 0],
      settlementDate |-> [i \in 1 .. 4 |-> 0],
      reserved1      |-> [i \in 1 .. 1 |-> 0] ]

(* Add Order Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderMessage ==
    { ZeroAddOrderMessage }
        \cup { [ZeroAddOrderMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderBookType = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.symbol = one] : one \in Sample(14) }
        \cup { [ZeroAddOrderMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessage EXCEPT !.brokerId = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderMessage EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.settlementDate = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Reduce Size Message: 21 bytes                                           *)
(***************************************************************************)

ReduceSizeMessage ==
    [ timestamp         : Sample(8),
      orderBookType     : Sample(1),
      orderId           : Sample(8),
      cancelledQuantity : Sample(4) ]

EncodeReduceSizeMessage(message) ==
    message.timestamp
        \o message.orderBookType
        \o message.orderId
        \o message.cancelledQuantity

DecodeReduceSizeMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderBookType == ReadBytes(timestamp.rest, 1) IN IF ~orderBookType.ok THEN Fail ELSE
    LET orderId == ReadBytes(orderBookType.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET cancelledQuantity == ReadBytes(orderId.rest, 4) IN IF ~cancelledQuantity.ok THEN Fail ELSE
    Ok([ timestamp         |-> timestamp.value,
         orderBookType     |-> orderBookType.value,
         orderId           |-> orderId.value,
         cancelledQuantity |-> cancelledQuantity.value ], cancelledQuantity.rest)

ZeroReduceSizeMessage ==
    [ timestamp         |-> [i \in 1 .. 8 |-> 0],
      orderBookType     |-> [i \in 1 .. 1 |-> 0],
      orderId           |-> [i \in 1 .. 8 |-> 0],
      cancelledQuantity |-> [i \in 1 .. 4 |-> 0] ]

(* Reduce Size Message at zero, then each field in turn at the values it is checked at *)
CheckedReduceSizeMessage ==
    { ZeroReduceSizeMessage }
        \cup { [ZeroReduceSizeMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroReduceSizeMessage EXCEPT !.orderBookType = one] : one \in Sample(1) }
        \cup { [ZeroReduceSizeMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroReduceSizeMessage EXCEPT !.cancelledQuantity = one] : one \in Sample(4) }

(***************************************************************************)
(* Delete Order Message: 17 bytes                                          *)
(***************************************************************************)

DeleteOrderMessage ==
    [ timestamp     : Sample(8),
      orderBookType : Sample(1),
      orderId       : Sample(8) ]

EncodeDeleteOrderMessage(message) ==
    message.timestamp
        \o message.orderBookType
        \o message.orderId

DecodeDeleteOrderMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderBookType == ReadBytes(timestamp.rest, 1) IN IF ~orderBookType.ok THEN Fail ELSE
    LET orderId == ReadBytes(orderBookType.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    Ok([ timestamp     |-> timestamp.value,
         orderBookType |-> orderBookType.value,
         orderId       |-> orderId.value ], orderId.rest)

ZeroDeleteOrderMessage ==
    [ timestamp     |-> [i \in 1 .. 8 |-> 0],
      orderBookType |-> [i \in 1 .. 1 |-> 0],
      orderId       |-> [i \in 1 .. 8 |-> 0] ]

(* Delete Order Message at zero, then each field in turn at the values it is checked at *)
CheckedDeleteOrderMessage ==
    { ZeroDeleteOrderMessage }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.orderBookType = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }

(***************************************************************************)
(* Modify Order Message: 30 bytes                                          *)
(***************************************************************************)

ModifyOrderMessage ==
    [ timestamp     : Sample(8),
      orderBookType : Sample(1),
      orderId       : Sample(8),
      quantity      : Sample(4),
      price         : Sample(8),
      reserved1     : Sample(1) ]

EncodeModifyOrderMessage(message) ==
    message.timestamp
        \o message.orderBookType
        \o message.orderId
        \o message.quantity
        \o message.price
        \o message.reserved1

DecodeModifyOrderMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderBookType == ReadBytes(timestamp.rest, 1) IN IF ~orderBookType.ok THEN Fail ELSE
    LET orderId == ReadBytes(orderBookType.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET quantity == ReadBytes(orderId.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(price.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ timestamp     |-> timestamp.value,
         orderBookType |-> orderBookType.value,
         orderId       |-> orderId.value,
         quantity      |-> quantity.value,
         price         |-> price.value,
         reserved1     |-> reserved1.value ], reserved1.rest)

ZeroModifyOrderMessage ==
    [ timestamp     |-> [i \in 1 .. 8 |-> 0],
      orderBookType |-> [i \in 1 .. 1 |-> 0],
      orderId       |-> [i \in 1 .. 8 |-> 0],
      quantity      |-> [i \in 1 .. 4 |-> 0],
      price         |-> [i \in 1 .. 8 |-> 0],
      reserved1     |-> [i \in 1 .. 1 |-> 0] ]

(* Modify Order Message at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderMessage ==
    { ZeroModifyOrderMessage }
        \cup { [ZeroModifyOrderMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.orderBookType = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Executed Message: 34 bytes                                        *)
(***************************************************************************)

OrderExecutedMessage ==
    [ timestamp        : Sample(8),
      orderBookType    : Sample(1),
      orderId          : Sample(8),
      executedQuantity : Sample(4),
      executionId      : Sample(8),
      buyBrokerId      : Sample(2),
      sellBrokerId     : Sample(2),
      executionFlags   : Sample(1) ]

EncodeOrderExecutedMessage(message) ==
    message.timestamp
        \o message.orderBookType
        \o message.orderId
        \o message.executedQuantity
        \o message.executionId
        \o message.buyBrokerId
        \o message.sellBrokerId
        \o message.executionFlags

DecodeOrderExecutedMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderBookType == ReadBytes(timestamp.rest, 1) IN IF ~orderBookType.ok THEN Fail ELSE
    LET orderId == ReadBytes(orderBookType.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(orderId.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET executionId == ReadBytes(executedQuantity.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET buyBrokerId == ReadBytes(executionId.rest, 2) IN IF ~buyBrokerId.ok THEN Fail ELSE
    LET sellBrokerId == ReadBytes(buyBrokerId.rest, 2) IN IF ~sellBrokerId.ok THEN Fail ELSE
    LET executionFlags == ReadBytes(sellBrokerId.rest, 1) IN IF ~executionFlags.ok THEN Fail ELSE
    Ok([ timestamp        |-> timestamp.value,
         orderBookType    |-> orderBookType.value,
         orderId          |-> orderId.value,
         executedQuantity |-> executedQuantity.value,
         executionId      |-> executionId.value,
         buyBrokerId      |-> buyBrokerId.value,
         sellBrokerId     |-> sellBrokerId.value,
         executionFlags   |-> executionFlags.value ], executionFlags.rest)

ZeroOrderExecutedMessage ==
    [ timestamp        |-> [i \in 1 .. 8 |-> 0],
      orderBookType    |-> [i \in 1 .. 1 |-> 0],
      orderId          |-> [i \in 1 .. 8 |-> 0],
      executedQuantity |-> [i \in 1 .. 4 |-> 0],
      executionId      |-> [i \in 1 .. 8 |-> 0],
      buyBrokerId      |-> [i \in 1 .. 2 |-> 0],
      sellBrokerId     |-> [i \in 1 .. 2 |-> 0],
      executionFlags   |-> [i \in 1 .. 1 |-> 0] ]

(* Order Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedMessage ==
    { ZeroOrderExecutedMessage }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.orderBookType = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.buyBrokerId = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.sellBrokerId = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.executionFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Message: 55 bytes                                                 *)
(***************************************************************************)

TradeMessage ==
    [ timestamp      : Sample(8),
      orderBookType  : Sample(1),
      symbol         : Sample(14),
      quantity       : Sample(4),
      price          : Sample(8),
      executionId    : Sample(8),
      buyBrokerId    : Sample(2),
      sellBrokerId   : Sample(2),
      crossType      : Sample(1),
      tradeFlags     : Sample(1),
      settlementType : Sample(1),
      settlementDate : Sample(4),
      reserved1      : Sample(1) ]

EncodeTradeMessage(message) ==
    message.timestamp
        \o message.orderBookType
        \o message.symbol
        \o message.quantity
        \o message.price
        \o message.executionId
        \o message.buyBrokerId
        \o message.sellBrokerId
        \o message.crossType
        \o message.tradeFlags
        \o message.settlementType
        \o message.settlementDate
        \o message.reserved1

DecodeTradeMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderBookType == ReadBytes(timestamp.rest, 1) IN IF ~orderBookType.ok THEN Fail ELSE
    LET symbol == ReadBytes(orderBookType.rest, 14) IN IF ~symbol.ok THEN Fail ELSE
    LET quantity == ReadBytes(symbol.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET executionId == ReadBytes(price.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET buyBrokerId == ReadBytes(executionId.rest, 2) IN IF ~buyBrokerId.ok THEN Fail ELSE
    LET sellBrokerId == ReadBytes(buyBrokerId.rest, 2) IN IF ~sellBrokerId.ok THEN Fail ELSE
    LET crossType == ReadBytes(sellBrokerId.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET tradeFlags == ReadBytes(crossType.rest, 1) IN IF ~tradeFlags.ok THEN Fail ELSE
    LET settlementType == ReadBytes(tradeFlags.rest, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET settlementDate == ReadBytes(settlementType.rest, 4) IN IF ~settlementDate.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(settlementDate.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ timestamp      |-> timestamp.value,
         orderBookType  |-> orderBookType.value,
         symbol         |-> symbol.value,
         quantity       |-> quantity.value,
         price          |-> price.value,
         executionId    |-> executionId.value,
         buyBrokerId    |-> buyBrokerId.value,
         sellBrokerId   |-> sellBrokerId.value,
         crossType      |-> crossType.value,
         tradeFlags     |-> tradeFlags.value,
         settlementType |-> settlementType.value,
         settlementDate |-> settlementDate.value,
         reserved1      |-> reserved1.value ], reserved1.rest)

ZeroTradeMessage ==
    [ timestamp      |-> [i \in 1 .. 8 |-> 0],
      orderBookType  |-> [i \in 1 .. 1 |-> 0],
      symbol         |-> [i \in 1 .. 14 |-> 0],
      quantity       |-> [i \in 1 .. 4 |-> 0],
      price          |-> [i \in 1 .. 8 |-> 0],
      executionId    |-> [i \in 1 .. 8 |-> 0],
      buyBrokerId    |-> [i \in 1 .. 2 |-> 0],
      sellBrokerId   |-> [i \in 1 .. 2 |-> 0],
      crossType      |-> [i \in 1 .. 1 |-> 0],
      tradeFlags     |-> [i \in 1 .. 1 |-> 0],
      settlementType |-> [i \in 1 .. 1 |-> 0],
      settlementDate |-> [i \in 1 .. 4 |-> 0],
      reserved1      |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.orderBookType = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.symbol = one] : one \in Sample(14) }
        \cup { [ZeroTradeMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.buyBrokerId = one] : one \in Sample(2) }
        \cup { [ZeroTradeMessage EXCEPT !.sellBrokerId = one] : one \in Sample(2) }
        \cup { [ZeroTradeMessage EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeFlags = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.settlementDate = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Break Message: 43 bytes                                           *)
(***************************************************************************)

TradeBreakMessage ==
    [ timestamp        : Sample(8),
      orderBookType    : Sample(1),
      symbol           : Sample(14),
      originalQuantity : Sample(4),
      originalPrice    : Sample(8),
      executionId      : Sample(8) ]

EncodeTradeBreakMessage(message) ==
    message.timestamp
        \o message.orderBookType
        \o message.symbol
        \o message.originalQuantity
        \o message.originalPrice
        \o message.executionId

DecodeTradeBreakMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderBookType == ReadBytes(timestamp.rest, 1) IN IF ~orderBookType.ok THEN Fail ELSE
    LET symbol == ReadBytes(orderBookType.rest, 14) IN IF ~symbol.ok THEN Fail ELSE
    LET originalQuantity == ReadBytes(symbol.rest, 4) IN IF ~originalQuantity.ok THEN Fail ELSE
    LET originalPrice == ReadBytes(originalQuantity.rest, 8) IN IF ~originalPrice.ok THEN Fail ELSE
    LET executionId == ReadBytes(originalPrice.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    Ok([ timestamp        |-> timestamp.value,
         orderBookType    |-> orderBookType.value,
         symbol           |-> symbol.value,
         originalQuantity |-> originalQuantity.value,
         originalPrice    |-> originalPrice.value,
         executionId      |-> executionId.value ], executionId.rest)

ZeroTradeBreakMessage ==
    [ timestamp        |-> [i \in 1 .. 8 |-> 0],
      orderBookType    |-> [i \in 1 .. 1 |-> 0],
      symbol           |-> [i \in 1 .. 14 |-> 0],
      originalQuantity |-> [i \in 1 .. 4 |-> 0],
      originalPrice    |-> [i \in 1 .. 8 |-> 0],
      executionId      |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Break Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeBreakMessage ==
    { ZeroTradeBreakMessage }
        \cup { [ZeroTradeBreakMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeBreakMessage EXCEPT !.orderBookType = one] : one \in Sample(1) }
        \cup { [ZeroTradeBreakMessage EXCEPT !.symbol = one] : one \in Sample(14) }
        \cup { [ZeroTradeBreakMessage EXCEPT !.originalQuantity = one] : one \in Sample(4) }
        \cup { [ZeroTradeBreakMessage EXCEPT !.originalPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeBreakMessage EXCEPT !.executionId = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Correction Message: 65 bytes                                      *)
(***************************************************************************)

TradeCorrectionMessage ==
    [ timestamp               : Sample(8),
      orderBookType           : Sample(1),
      symbol                  : Sample(14),
      originalQuantity        : Sample(4),
      originalPrice           : Sample(8),
      originalSettlementType  : Sample(1),
      originalSettlementDate  : Sample(4),
      correctedQuantity       : Sample(4),
      correctedPrice          : Sample(8),
      correctedSettlementType : Sample(1),
      correctedSettlementDate : Sample(4),
      executionId             : Sample(8) ]

EncodeTradeCorrectionMessage(message) ==
    message.timestamp
        \o message.orderBookType
        \o message.symbol
        \o message.originalQuantity
        \o message.originalPrice
        \o message.originalSettlementType
        \o message.originalSettlementDate
        \o message.correctedQuantity
        \o message.correctedPrice
        \o message.correctedSettlementType
        \o message.correctedSettlementDate
        \o message.executionId

DecodeTradeCorrectionMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderBookType == ReadBytes(timestamp.rest, 1) IN IF ~orderBookType.ok THEN Fail ELSE
    LET symbol == ReadBytes(orderBookType.rest, 14) IN IF ~symbol.ok THEN Fail ELSE
    LET originalQuantity == ReadBytes(symbol.rest, 4) IN IF ~originalQuantity.ok THEN Fail ELSE
    LET originalPrice == ReadBytes(originalQuantity.rest, 8) IN IF ~originalPrice.ok THEN Fail ELSE
    LET originalSettlementType == ReadBytes(originalPrice.rest, 1) IN IF ~originalSettlementType.ok THEN Fail ELSE
    LET originalSettlementDate == ReadBytes(originalSettlementType.rest, 4) IN IF ~originalSettlementDate.ok THEN Fail ELSE
    LET correctedQuantity == ReadBytes(originalSettlementDate.rest, 4) IN IF ~correctedQuantity.ok THEN Fail ELSE
    LET correctedPrice == ReadBytes(correctedQuantity.rest, 8) IN IF ~correctedPrice.ok THEN Fail ELSE
    LET correctedSettlementType == ReadBytes(correctedPrice.rest, 1) IN IF ~correctedSettlementType.ok THEN Fail ELSE
    LET correctedSettlementDate == ReadBytes(correctedSettlementType.rest, 4) IN IF ~correctedSettlementDate.ok THEN Fail ELSE
    LET executionId == ReadBytes(correctedSettlementDate.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    Ok([ timestamp               |-> timestamp.value,
         orderBookType           |-> orderBookType.value,
         symbol                  |-> symbol.value,
         originalQuantity        |-> originalQuantity.value,
         originalPrice           |-> originalPrice.value,
         originalSettlementType  |-> originalSettlementType.value,
         originalSettlementDate  |-> originalSettlementDate.value,
         correctedQuantity       |-> correctedQuantity.value,
         correctedPrice          |-> correctedPrice.value,
         correctedSettlementType |-> correctedSettlementType.value,
         correctedSettlementDate |-> correctedSettlementDate.value,
         executionId             |-> executionId.value ], executionId.rest)

ZeroTradeCorrectionMessage ==
    [ timestamp               |-> [i \in 1 .. 8 |-> 0],
      orderBookType           |-> [i \in 1 .. 1 |-> 0],
      symbol                  |-> [i \in 1 .. 14 |-> 0],
      originalQuantity        |-> [i \in 1 .. 4 |-> 0],
      originalPrice           |-> [i \in 1 .. 8 |-> 0],
      originalSettlementType  |-> [i \in 1 .. 1 |-> 0],
      originalSettlementDate  |-> [i \in 1 .. 4 |-> 0],
      correctedQuantity       |-> [i \in 1 .. 4 |-> 0],
      correctedPrice          |-> [i \in 1 .. 8 |-> 0],
      correctedSettlementType |-> [i \in 1 .. 1 |-> 0],
      correctedSettlementDate |-> [i \in 1 .. 4 |-> 0],
      executionId             |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Correction Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCorrectionMessage ==
    { ZeroTradeCorrectionMessage }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.orderBookType = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.symbol = one] : one \in Sample(14) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalQuantity = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalSettlementType = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalSettlementDate = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.correctedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.correctedPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.correctedSettlementType = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.correctedSettlementDate = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.executionId = one] : one \in Sample(8) }

(***************************************************************************)
(* Auction Update Message: 58 bytes                                        *)
(***************************************************************************)

AuctionUpdateMessage ==
    [ timestamp              : Sample(8),
      orderBookType          : Sample(1),
      symbol                 : Sample(14),
      auctionType            : Sample(1),
      referencePrice         : Sample(8),
      imbalanceQuantity      : Sample(4),
      imbalanceSideIndicator : Sample(1),
      matchedShares          : Sample(4),
      indicativePrice        : Sample(8),
      auctionOnlyPrice       : Sample(8),
      reserved1              : Sample(1) ]

EncodeAuctionUpdateMessage(message) ==
    message.timestamp
        \o message.orderBookType
        \o message.symbol
        \o message.auctionType
        \o message.referencePrice
        \o message.imbalanceQuantity
        \o message.imbalanceSideIndicator
        \o message.matchedShares
        \o message.indicativePrice
        \o message.auctionOnlyPrice
        \o message.reserved1

DecodeAuctionUpdateMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderBookType == ReadBytes(timestamp.rest, 1) IN IF ~orderBookType.ok THEN Fail ELSE
    LET symbol == ReadBytes(orderBookType.rest, 14) IN IF ~symbol.ok THEN Fail ELSE
    LET auctionType == ReadBytes(symbol.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET referencePrice == ReadBytes(auctionType.rest, 8) IN IF ~referencePrice.ok THEN Fail ELSE
    LET imbalanceQuantity == ReadBytes(referencePrice.rest, 4) IN IF ~imbalanceQuantity.ok THEN Fail ELSE
    LET imbalanceSideIndicator == ReadBytes(imbalanceQuantity.rest, 1) IN IF ~imbalanceSideIndicator.ok THEN Fail ELSE
    LET matchedShares == ReadBytes(imbalanceSideIndicator.rest, 4) IN IF ~matchedShares.ok THEN Fail ELSE
    LET indicativePrice == ReadBytes(matchedShares.rest, 8) IN IF ~indicativePrice.ok THEN Fail ELSE
    LET auctionOnlyPrice == ReadBytes(indicativePrice.rest, 8) IN IF ~auctionOnlyPrice.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(auctionOnlyPrice.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ timestamp              |-> timestamp.value,
         orderBookType          |-> orderBookType.value,
         symbol                 |-> symbol.value,
         auctionType            |-> auctionType.value,
         referencePrice         |-> referencePrice.value,
         imbalanceQuantity      |-> imbalanceQuantity.value,
         imbalanceSideIndicator |-> imbalanceSideIndicator.value,
         matchedShares          |-> matchedShares.value,
         indicativePrice        |-> indicativePrice.value,
         auctionOnlyPrice       |-> auctionOnlyPrice.value,
         reserved1              |-> reserved1.value ], reserved1.rest)

ZeroAuctionUpdateMessage ==
    [ timestamp              |-> [i \in 1 .. 8 |-> 0],
      orderBookType          |-> [i \in 1 .. 1 |-> 0],
      symbol                 |-> [i \in 1 .. 14 |-> 0],
      auctionType            |-> [i \in 1 .. 1 |-> 0],
      referencePrice         |-> [i \in 1 .. 8 |-> 0],
      imbalanceQuantity      |-> [i \in 1 .. 4 |-> 0],
      imbalanceSideIndicator |-> [i \in 1 .. 1 |-> 0],
      matchedShares          |-> [i \in 1 .. 4 |-> 0],
      indicativePrice        |-> [i \in 1 .. 8 |-> 0],
      auctionOnlyPrice       |-> [i \in 1 .. 8 |-> 0],
      reserved1              |-> [i \in 1 .. 1 |-> 0] ]

(* Auction Update Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionUpdateMessage ==
    { ZeroAuctionUpdateMessage }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.orderBookType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.symbol = one] : one \in Sample(14) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.referencePrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.imbalanceQuantity = one] : one \in Sample(4) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.imbalanceSideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.matchedShares = one] : one \in Sample(4) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.indicativePrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.auctionOnlyPrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Auction Summary Message: 37 bytes                                       *)
(***************************************************************************)

AuctionSummaryMessage ==
    [ timestamp     : Sample(8),
      orderBookType : Sample(1),
      symbol        : Sample(14),
      auctionType   : Sample(1),
      price         : Sample(8),
      shares        : Sample(4),
      reserved1     : Sample(1) ]

EncodeAuctionSummaryMessage(message) ==
    message.timestamp
        \o message.orderBookType
        \o message.symbol
        \o message.auctionType
        \o message.price
        \o message.shares
        \o message.reserved1

DecodeAuctionSummaryMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderBookType == ReadBytes(timestamp.rest, 1) IN IF ~orderBookType.ok THEN Fail ELSE
    LET symbol == ReadBytes(orderBookType.rest, 14) IN IF ~symbol.ok THEN Fail ELSE
    LET auctionType == ReadBytes(symbol.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET price == ReadBytes(auctionType.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET shares == ReadBytes(price.rest, 4) IN IF ~shares.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(shares.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ timestamp     |-> timestamp.value,
         orderBookType |-> orderBookType.value,
         symbol        |-> symbol.value,
         auctionType   |-> auctionType.value,
         price         |-> price.value,
         shares        |-> shares.value,
         reserved1     |-> reserved1.value ], reserved1.rest)

ZeroAuctionSummaryMessage ==
    [ timestamp     |-> [i \in 1 .. 8 |-> 0],
      orderBookType |-> [i \in 1 .. 1 |-> 0],
      symbol        |-> [i \in 1 .. 14 |-> 0],
      auctionType   |-> [i \in 1 .. 1 |-> 0],
      price         |-> [i \in 1 .. 8 |-> 0],
      shares        |-> [i \in 1 .. 4 |-> 0],
      reserved1     |-> [i \in 1 .. 1 |-> 0] ]

(* Auction Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionSummaryMessage ==
    { ZeroAuctionSummaryMessage }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.orderBookType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.symbol = one] : one \in Sample(14) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.shares = one] : one \in Sample(4) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* End Of Session Message: 4 bytes                                         *)
(***************************************************************************)

EndOfSessionMessage ==
    [ reserved4 : Sample(4) ]

EncodeEndOfSessionMessage(message) ==
    message.reserved4

DecodeEndOfSessionMessage(bytes) ==
    LET reserved4 == ReadBytes(bytes, 4) IN IF ~reserved4.ok THEN Fail ELSE
    Ok([ reserved4 |-> reserved4.value ], reserved4.rest)

ZeroEndOfSessionMessage ==
    [ reserved4 |-> [i \in 1 .. 4 |-> 0] ]

(* End Of Session Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfSessionMessage ==
    { ZeroEndOfSessionMessage }
        \cup { [ZeroEndOfSessionMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

UnitClearMessageCode == 151  \* 0x97
InstrumentDirectoryMessageCode == 96  \* 0x60
TradingStatusMessageCode == 97  \* 0x61
AddOrderMessageCode == 98  \* 0x62
ReduceSizeMessageCode == 99  \* 0x63
DeleteOrderMessageCode == 100  \* 0x64
ModifyOrderMessageCode == 101  \* 0x65
OrderExecutedMessageCode == 102  \* 0x66
TradeMessageCode == 103  \* 0x67
TradeBreakMessageCode == 104  \* 0x68
TradeCorrectionMessageCode == 105  \* 0x69
AuctionUpdateMessageCode == 107  \* 0x6b
AuctionSummaryMessageCode == 108  \* 0x6c
EndOfSessionMessageCode == 45  \* 0x2d

Payload ==
    [ tag : {UnitClearMessageCode}, body : UnitClearMessage ]
        \cup [ tag : {InstrumentDirectoryMessageCode}, body : InstrumentDirectoryMessage ]
        \cup [ tag : {TradingStatusMessageCode}, body : TradingStatusMessage ]
        \cup [ tag : {AddOrderMessageCode}, body : AddOrderMessage ]
        \cup [ tag : {ReduceSizeMessageCode}, body : ReduceSizeMessage ]
        \cup [ tag : {DeleteOrderMessageCode}, body : DeleteOrderMessage ]
        \cup [ tag : {ModifyOrderMessageCode}, body : ModifyOrderMessage ]
        \cup [ tag : {OrderExecutedMessageCode}, body : OrderExecutedMessage ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {TradeBreakMessageCode}, body : TradeBreakMessage ]
        \cup [ tag : {TradeCorrectionMessageCode}, body : TradeCorrectionMessage ]
        \cup [ tag : {AuctionUpdateMessageCode}, body : AuctionUpdateMessage ]
        \cup [ tag : {AuctionSummaryMessageCode}, body : AuctionSummaryMessage ]
        \cup [ tag : {EndOfSessionMessageCode}, body : EndOfSessionMessage ]

EncodePayload(message) ==
    CASE message.tag = UnitClearMessageCode -> EncodeUnitClearMessage(message.body)
      [] message.tag = InstrumentDirectoryMessageCode -> EncodeInstrumentDirectoryMessage(message.body)
      [] message.tag = TradingStatusMessageCode -> EncodeTradingStatusMessage(message.body)
      [] message.tag = AddOrderMessageCode -> EncodeAddOrderMessage(message.body)
      [] message.tag = ReduceSizeMessageCode -> EncodeReduceSizeMessage(message.body)
      [] message.tag = DeleteOrderMessageCode -> EncodeDeleteOrderMessage(message.body)
      [] message.tag = ModifyOrderMessageCode -> EncodeModifyOrderMessage(message.body)
      [] message.tag = OrderExecutedMessageCode -> EncodeOrderExecutedMessage(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = TradeBreakMessageCode -> EncodeTradeBreakMessage(message.body)
      [] message.tag = TradeCorrectionMessageCode -> EncodeTradeCorrectionMessage(message.body)
      [] message.tag = AuctionUpdateMessageCode -> EncodeAuctionUpdateMessage(message.body)
      [] message.tag = AuctionSummaryMessageCode -> EncodeAuctionSummaryMessage(message.body)
      [] message.tag = EndOfSessionMessageCode -> EncodeEndOfSessionMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = UnitClearMessageCode -> DecodeUnitClearMessage(bytes)
              [] tag = InstrumentDirectoryMessageCode -> DecodeInstrumentDirectoryMessage(bytes)
              [] tag = TradingStatusMessageCode -> DecodeTradingStatusMessage(bytes)
              [] tag = AddOrderMessageCode -> DecodeAddOrderMessage(bytes)
              [] tag = ReduceSizeMessageCode -> DecodeReduceSizeMessage(bytes)
              [] tag = DeleteOrderMessageCode -> DecodeDeleteOrderMessage(bytes)
              [] tag = ModifyOrderMessageCode -> DecodeModifyOrderMessage(bytes)
              [] tag = OrderExecutedMessageCode -> DecodeOrderExecutedMessage(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = TradeBreakMessageCode -> DecodeTradeBreakMessage(bytes)
              [] tag = TradeCorrectionMessageCode -> DecodeTradeCorrectionMessage(bytes)
              [] tag = AuctionUpdateMessageCode -> DecodeAuctionUpdateMessage(bytes)
              [] tag = AuctionSummaryMessageCode -> DecodeAuctionSummaryMessage(bytes)
              [] tag = EndOfSessionMessageCode -> DecodeEndOfSessionMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> UnitClearMessageCode, body |-> ZeroUnitClearMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> UnitClearMessageCode, body |-> one] : one \in CheckedUnitClearMessage }
        \cup { [tag |-> InstrumentDirectoryMessageCode, body |-> one] : one \in CheckedInstrumentDirectoryMessage }
        \cup { [tag |-> TradingStatusMessageCode, body |-> one] : one \in CheckedTradingStatusMessage }
        \cup { [tag |-> AddOrderMessageCode, body |-> one] : one \in CheckedAddOrderMessage }
        \cup { [tag |-> ReduceSizeMessageCode, body |-> one] : one \in CheckedReduceSizeMessage }
        \cup { [tag |-> DeleteOrderMessageCode, body |-> one] : one \in CheckedDeleteOrderMessage }
        \cup { [tag |-> ModifyOrderMessageCode, body |-> one] : one \in CheckedModifyOrderMessage }
        \cup { [tag |-> OrderExecutedMessageCode, body |-> one] : one \in CheckedOrderExecutedMessage }
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> TradeBreakMessageCode, body |-> one] : one \in CheckedTradeBreakMessage }
        \cup { [tag |-> TradeCorrectionMessageCode, body |-> one] : one \in CheckedTradeCorrectionMessage }
        \cup { [tag |-> AuctionUpdateMessageCode, body |-> one] : one \in CheckedAuctionUpdateMessage }
        \cup { [tag |-> AuctionSummaryMessageCode, body |-> one] : one \in CheckedAuctionSummaryMessage }
        \cup { [tag |-> EndOfSessionMessageCode, body |-> one] : one \in CheckedEndOfSessionMessage }

(***************************************************************************)
(* Message, framed by Message Length                                       *)
(***************************************************************************)

Message ==
    [ payload : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntLE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntLE(Len(body) + 1, 1) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntLE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 1) IN IF ~length.ok THEN Fail ELSE
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> UnitClearMessageCode, body |-> ZeroUnitClearMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> InstrumentDirectoryMessageCode, body |-> ZeroInstrumentDirectoryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradingStatusMessageCode, body |-> ZeroTradingStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddOrderMessageCode, body |-> ZeroAddOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ReduceSizeMessageCode, body |-> ZeroReduceSizeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> DeleteOrderMessageCode, body |-> ZeroDeleteOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ModifyOrderMessageCode, body |-> ZeroModifyOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderExecutedMessageCode, body |-> ZeroOrderExecutedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeMessageCode, body |-> ZeroTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeBreakMessageCode, body |-> ZeroTradeBreakMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeCorrectionMessageCode, body |-> ZeroTradeCorrectionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionUpdateMessageCode, body |-> ZeroAuctionUpdateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionSummaryMessageCode, body |-> ZeroAuctionSummaryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EndOfSessionMessageCode, body |-> ZeroEndOfSessionMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ length   : Sample(2),
      unit     : Sample(1),
      sequence : Sample(4),
      message  : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.length
        \o EncodeUIntLE(Len(message.message), 1)
        \o message.unit
        \o message.sequence
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET length == ReadBytes(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET messageCount == ReadUIntLE(length.rest, 1) IN IF ~messageCount.ok THEN Fail ELSE
    LET unit == ReadBytes(messageCount.rest, 1) IN IF ~unit.ok THEN Fail ELSE
    LET sequence == ReadBytes(unit.rest, 4) IN IF ~sequence.ok THEN Fail ELSE
    LET message == ReadMessageList(sequence.rest, messageCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ length   |-> length.value,
         unit     |-> unit.value,
         sequence |-> sequence.value,
         message  |-> message.value ], message.rest)

ZeroPacket ==
    [ length   |-> [i \in 1 .. 2 |-> 0],
      unit     |-> [i \in 1 .. 1 |-> 0],
      sequence |-> [i \in 1 .. 4 |-> 0],
      message  |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.length = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.unit = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.sequence = one] : one \in Sample(4) }
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

(* Every Unit Clear Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUnitClearMessage ==
    \A message \in CheckedUnitClearMessage :
        LET read == DecodeUnitClearMessage(EncodeUnitClearMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentDirectoryMessage ==
    \A message \in CheckedInstrumentDirectoryMessage :
        LET read == DecodeInstrumentDirectoryMessage(EncodeInstrumentDirectoryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trading Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingStatusMessage ==
    \A message \in CheckedTradingStatusMessage :
        LET read == DecodeTradingStatusMessage(EncodeTradingStatusMessage(message))
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

(* Every Reduce Size Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReduceSizeMessage ==
    \A message \in CheckedReduceSizeMessage :
        LET read == DecodeReduceSizeMessage(EncodeReduceSizeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Delete Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDeleteOrderMessage ==
    \A message \in CheckedDeleteOrderMessage :
        LET read == DecodeDeleteOrderMessage(EncodeDeleteOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyOrderMessage ==
    \A message \in CheckedModifyOrderMessage :
        LET read == DecodeModifyOrderMessage(EncodeModifyOrderMessage(message))
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

(* Every Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeMessage ==
    \A message \in CheckedTradeMessage :
        LET read == DecodeTradeMessage(EncodeTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Break Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBreakMessage ==
    \A message \in CheckedTradeBreakMessage :
        LET read == DecodeTradeBreakMessage(EncodeTradeBreakMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Correction Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCorrectionMessage ==
    \A message \in CheckedTradeCorrectionMessage :
        LET read == DecodeTradeCorrectionMessage(EncodeTradeCorrectionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionUpdateMessage ==
    \A message \in CheckedAuctionUpdateMessage :
        LET read == DecodeAuctionUpdateMessage(EncodeAuctionUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionSummaryMessage ==
    \A message \in CheckedAuctionSummaryMessage :
        LET read == DecodeAuctionSummaryMessage(EncodeAuctionSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Session Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfSessionMessage ==
    \A message \in CheckedEndOfSessionMessage :
        LET read == DecodeEndOfSessionMessage(EncodeEndOfSessionMessage(message))
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
        IN  DecodeUIntLE(SubSeq(bytes, 1, 1)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
