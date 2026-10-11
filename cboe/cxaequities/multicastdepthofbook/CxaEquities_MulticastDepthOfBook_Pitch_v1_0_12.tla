---------- MODULE CxaEquities_MulticastDepthOfBook_Pitch_v1_0_12 -----------
(***************************************************************************)
(* Chicago Board Options Exchange Multicast Depth Of Book v1.0.12          *)
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
(* Note: Flags is a bit field set, checked as its 1 byte rather than bit   *)
(* by bit.                                                                 *)
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
(* Trading Status Message: 20 bytes                                        *)
(***************************************************************************)

TradingStatusMessage ==
    [ timestamp     : Sample(8),
      symbol        : Sample(6),
      tradingStatus : Sample(1),
      marketIdCode  : Sample(4),
      reserved1     : Sample(1) ]

EncodeTradingStatusMessage(message) ==
    message.timestamp
        \o message.symbol
        \o message.tradingStatus
        \o message.marketIdCode
        \o message.reserved1

DecodeTradingStatusMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(symbol.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET marketIdCode == ReadBytes(tradingStatus.rest, 4) IN IF ~marketIdCode.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(marketIdCode.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ timestamp     |-> timestamp.value,
         symbol        |-> symbol.value,
         tradingStatus |-> tradingStatus.value,
         marketIdCode  |-> marketIdCode.value,
         reserved1     |-> reserved1.value ], reserved1.rest)

ZeroTradingStatusMessage ==
    [ timestamp     |-> [i \in 1 .. 8 |-> 0],
      symbol        |-> [i \in 1 .. 6 |-> 0],
      tradingStatus |-> [i \in 1 .. 1 |-> 0],
      marketIdCode  |-> [i \in 1 .. 4 |-> 0],
      reserved1     |-> [i \in 1 .. 1 |-> 0] ]

(* Trading Status Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingStatusMessage ==
    { ZeroTradingStatusMessage }
        \cup { [ZeroTradingStatusMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.marketIdCode = one] : one \in Sample(4) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Add Order Message: 40 bytes                                             *)
(***************************************************************************)

AddOrderMessage ==
    [ timestamp     : Sample(8),
      orderId       : Sample(8),
      sideIndicator : Sample(1),
      quantity      : Sample(4),
      symbol        : Sample(6),
      price         : Sample(8),
      pid           : Sample(4),
      reserved1     : Sample(1) ]

EncodeAddOrderMessage(message) ==
    message.timestamp
        \o message.orderId
        \o message.sideIndicator
        \o message.quantity
        \o message.symbol
        \o message.price
        \o message.pid
        \o message.reserved1

DecodeAddOrderMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderId == ReadBytes(timestamp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET quantity == ReadBytes(sideIndicator.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET symbol == ReadBytes(quantity.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET price == ReadBytes(symbol.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET pid == ReadBytes(price.rest, 4) IN IF ~pid.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(pid.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ timestamp     |-> timestamp.value,
         orderId       |-> orderId.value,
         sideIndicator |-> sideIndicator.value,
         quantity      |-> quantity.value,
         symbol        |-> symbol.value,
         price         |-> price.value,
         pid           |-> pid.value,
         reserved1     |-> reserved1.value ], reserved1.rest)

ZeroAddOrderMessage ==
    [ timestamp     |-> [i \in 1 .. 8 |-> 0],
      orderId       |-> [i \in 1 .. 8 |-> 0],
      sideIndicator |-> [i \in 1 .. 1 |-> 0],
      quantity      |-> [i \in 1 .. 4 |-> 0],
      symbol        |-> [i \in 1 .. 6 |-> 0],
      price         |-> [i \in 1 .. 8 |-> 0],
      pid           |-> [i \in 1 .. 4 |-> 0],
      reserved1     |-> [i \in 1 .. 1 |-> 0] ]

(* Add Order Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderMessage ==
    { ZeroAddOrderMessage }
        \cup { [ZeroAddOrderMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroAddOrderMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessage EXCEPT !.pid = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Executed Message: 41 bytes                                        *)
(***************************************************************************)

OrderExecutedMessage ==
    [ timestamp        : Sample(8),
      orderId          : Sample(8),
      executedQuantity : Sample(4),
      executionId      : Sample(8),
      contraOrderId    : Sample(8),
      contraPid        : Sample(4),
      reserved1        : Sample(1) ]

EncodeOrderExecutedMessage(message) ==
    message.timestamp
        \o message.orderId
        \o message.executedQuantity
        \o message.executionId
        \o message.contraOrderId
        \o message.contraPid
        \o message.reserved1

DecodeOrderExecutedMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderId == ReadBytes(timestamp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(orderId.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET executionId == ReadBytes(executedQuantity.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET contraOrderId == ReadBytes(executionId.rest, 8) IN IF ~contraOrderId.ok THEN Fail ELSE
    LET contraPid == ReadBytes(contraOrderId.rest, 4) IN IF ~contraPid.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(contraPid.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ timestamp        |-> timestamp.value,
         orderId          |-> orderId.value,
         executedQuantity |-> executedQuantity.value,
         executionId      |-> executionId.value,
         contraOrderId    |-> contraOrderId.value,
         contraPid        |-> contraPid.value,
         reserved1        |-> reserved1.value ], reserved1.rest)

ZeroOrderExecutedMessage ==
    [ timestamp        |-> [i \in 1 .. 8 |-> 0],
      orderId          |-> [i \in 1 .. 8 |-> 0],
      executedQuantity |-> [i \in 1 .. 4 |-> 0],
      executionId      |-> [i \in 1 .. 8 |-> 0],
      contraOrderId    |-> [i \in 1 .. 8 |-> 0],
      contraPid        |-> [i \in 1 .. 4 |-> 0],
      reserved1        |-> [i \in 1 .. 1 |-> 0] ]

(* Order Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedMessage ==
    { ZeroOrderExecutedMessage }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.contraOrderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.contraPid = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Executed At Price Message: 50 bytes                               *)
(***************************************************************************)

OrderExecutedAtPriceMessage ==
    [ timestamp        : Sample(8),
      orderId          : Sample(8),
      executedQuantity : Sample(4),
      executionId      : Sample(8),
      contraOrderId    : Sample(8),
      contraPid        : Sample(4),
      executionType    : Sample(1),
      price            : Sample(8),
      reserved1        : Sample(1) ]

EncodeOrderExecutedAtPriceMessage(message) ==
    message.timestamp
        \o message.orderId
        \o message.executedQuantity
        \o message.executionId
        \o message.contraOrderId
        \o message.contraPid
        \o message.executionType
        \o message.price
        \o message.reserved1

DecodeOrderExecutedAtPriceMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderId == ReadBytes(timestamp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(orderId.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET executionId == ReadBytes(executedQuantity.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET contraOrderId == ReadBytes(executionId.rest, 8) IN IF ~contraOrderId.ok THEN Fail ELSE
    LET contraPid == ReadBytes(contraOrderId.rest, 4) IN IF ~contraPid.ok THEN Fail ELSE
    LET executionType == ReadBytes(contraPid.rest, 1) IN IF ~executionType.ok THEN Fail ELSE
    LET price == ReadBytes(executionType.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(price.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ timestamp        |-> timestamp.value,
         orderId          |-> orderId.value,
         executedQuantity |-> executedQuantity.value,
         executionId      |-> executionId.value,
         contraOrderId    |-> contraOrderId.value,
         contraPid        |-> contraPid.value,
         executionType    |-> executionType.value,
         price            |-> price.value,
         reserved1        |-> reserved1.value ], reserved1.rest)

ZeroOrderExecutedAtPriceMessage ==
    [ timestamp        |-> [i \in 1 .. 8 |-> 0],
      orderId          |-> [i \in 1 .. 8 |-> 0],
      executedQuantity |-> [i \in 1 .. 4 |-> 0],
      executionId      |-> [i \in 1 .. 8 |-> 0],
      contraOrderId    |-> [i \in 1 .. 8 |-> 0],
      contraPid        |-> [i \in 1 .. 4 |-> 0],
      executionType    |-> [i \in 1 .. 1 |-> 0],
      price            |-> [i \in 1 .. 8 |-> 0],
      reserved1        |-> [i \in 1 .. 1 |-> 0] ]

(* Order Executed At Price Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedAtPriceMessage ==
    { ZeroOrderExecutedAtPriceMessage }
        \cup { [ZeroOrderExecutedAtPriceMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedAtPriceMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedAtPriceMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedAtPriceMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedAtPriceMessage EXCEPT !.contraOrderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedAtPriceMessage EXCEPT !.contraPid = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedAtPriceMessage EXCEPT !.executionType = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutedAtPriceMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedAtPriceMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Reduce Size Message: 20 bytes                                           *)
(***************************************************************************)

ReduceSizeMessage ==
    [ timestamp         : Sample(8),
      orderId           : Sample(8),
      cancelledQuantity : Sample(4) ]

EncodeReduceSizeMessage(message) ==
    message.timestamp
        \o message.orderId
        \o message.cancelledQuantity

DecodeReduceSizeMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderId == ReadBytes(timestamp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET cancelledQuantity == ReadBytes(orderId.rest, 4) IN IF ~cancelledQuantity.ok THEN Fail ELSE
    Ok([ timestamp         |-> timestamp.value,
         orderId           |-> orderId.value,
         cancelledQuantity |-> cancelledQuantity.value ], cancelledQuantity.rest)

ZeroReduceSizeMessage ==
    [ timestamp         |-> [i \in 1 .. 8 |-> 0],
      orderId           |-> [i \in 1 .. 8 |-> 0],
      cancelledQuantity |-> [i \in 1 .. 4 |-> 0] ]

(* Reduce Size Message at zero, then each field in turn at the values it is checked at *)
CheckedReduceSizeMessage ==
    { ZeroReduceSizeMessage }
        \cup { [ZeroReduceSizeMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroReduceSizeMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroReduceSizeMessage EXCEPT !.cancelledQuantity = one] : one \in Sample(4) }

(***************************************************************************)
(* Modify Order Message: 29 bytes                                          *)
(***************************************************************************)

ModifyOrderMessage ==
    [ timestamp : Sample(8),
      orderId   : Sample(8),
      quantity  : Sample(4),
      price     : Sample(8),
      reserved1 : Sample(1) ]

EncodeModifyOrderMessage(message) ==
    message.timestamp
        \o message.orderId
        \o message.quantity
        \o message.price
        \o message.reserved1

DecodeModifyOrderMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderId == ReadBytes(timestamp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET quantity == ReadBytes(orderId.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(price.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ timestamp |-> timestamp.value,
         orderId   |-> orderId.value,
         quantity  |-> quantity.value,
         price     |-> price.value,
         reserved1 |-> reserved1.value ], reserved1.rest)

ZeroModifyOrderMessage ==
    [ timestamp |-> [i \in 1 .. 8 |-> 0],
      orderId   |-> [i \in 1 .. 8 |-> 0],
      quantity  |-> [i \in 1 .. 4 |-> 0],
      price     |-> [i \in 1 .. 8 |-> 0],
      reserved1 |-> [i \in 1 .. 1 |-> 0] ]

(* Modify Order Message at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderMessage ==
    { ZeroModifyOrderMessage }
        \cup { [ZeroModifyOrderMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Delete Order Message: 16 bytes                                          *)
(***************************************************************************)

DeleteOrderMessage ==
    [ timestamp : Sample(8),
      orderId   : Sample(8) ]

EncodeDeleteOrderMessage(message) ==
    message.timestamp
        \o message.orderId

DecodeDeleteOrderMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderId == ReadBytes(timestamp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    Ok([ timestamp |-> timestamp.value,
         orderId   |-> orderId.value ], orderId.rest)

ZeroDeleteOrderMessage ==
    [ timestamp |-> [i \in 1 .. 8 |-> 0],
      orderId   |-> [i \in 1 .. 8 |-> 0] ]

(* Delete Order Message at zero, then each field in turn at the values it is checked at *)
CheckedDeleteOrderMessage ==
    { ZeroDeleteOrderMessage }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Message: 70 bytes                                                 *)
(***************************************************************************)

TradeMessage ==
    [ timestamp            : Sample(8),
      symbol               : Sample(6),
      quantity             : Sample(4),
      price                : Sample(8),
      executionId          : Sample(8),
      orderId              : Sample(8),
      contraOrderId        : Sample(8),
      pid                  : Sample(4),
      contraPid            : Sample(4),
      tradeType            : Sample(1),
      tradeDesignation     : Sample(1),
      tradeReportType      : Sample(1),
      tradeTransactionTime : Sample(8),
      flags                : Sample(1) ]

EncodeTradeMessage(message) ==
    message.timestamp
        \o message.symbol
        \o message.quantity
        \o message.price
        \o message.executionId
        \o message.orderId
        \o message.contraOrderId
        \o message.pid
        \o message.contraPid
        \o message.tradeType
        \o message.tradeDesignation
        \o message.tradeReportType
        \o message.tradeTransactionTime
        \o message.flags

DecodeTradeMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET quantity == ReadBytes(symbol.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET executionId == ReadBytes(price.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET orderId == ReadBytes(executionId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET contraOrderId == ReadBytes(orderId.rest, 8) IN IF ~contraOrderId.ok THEN Fail ELSE
    LET pid == ReadBytes(contraOrderId.rest, 4) IN IF ~pid.ok THEN Fail ELSE
    LET contraPid == ReadBytes(pid.rest, 4) IN IF ~contraPid.ok THEN Fail ELSE
    LET tradeType == ReadBytes(contraPid.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET tradeDesignation == ReadBytes(tradeType.rest, 1) IN IF ~tradeDesignation.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(tradeDesignation.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET tradeTransactionTime == ReadBytes(tradeReportType.rest, 8) IN IF ~tradeTransactionTime.ok THEN Fail ELSE
    LET flags == ReadBytes(tradeTransactionTime.rest, 1) IN IF ~flags.ok THEN Fail ELSE
    Ok([ timestamp            |-> timestamp.value,
         symbol               |-> symbol.value,
         quantity             |-> quantity.value,
         price                |-> price.value,
         executionId          |-> executionId.value,
         orderId              |-> orderId.value,
         contraOrderId        |-> contraOrderId.value,
         pid                  |-> pid.value,
         contraPid            |-> contraPid.value,
         tradeType            |-> tradeType.value,
         tradeDesignation     |-> tradeDesignation.value,
         tradeReportType      |-> tradeReportType.value,
         tradeTransactionTime |-> tradeTransactionTime.value,
         flags                |-> flags.value ], flags.rest)

ZeroTradeMessage ==
    [ timestamp            |-> [i \in 1 .. 8 |-> 0],
      symbol               |-> [i \in 1 .. 6 |-> 0],
      quantity             |-> [i \in 1 .. 4 |-> 0],
      price                |-> [i \in 1 .. 8 |-> 0],
      executionId          |-> [i \in 1 .. 8 |-> 0],
      orderId              |-> [i \in 1 .. 8 |-> 0],
      contraOrderId        |-> [i \in 1 .. 8 |-> 0],
      pid                  |-> [i \in 1 .. 4 |-> 0],
      contraPid            |-> [i \in 1 .. 4 |-> 0],
      tradeType            |-> [i \in 1 .. 1 |-> 0],
      tradeDesignation     |-> [i \in 1 .. 1 |-> 0],
      tradeReportType      |-> [i \in 1 .. 1 |-> 0],
      tradeTransactionTime |-> [i \in 1 .. 8 |-> 0],
      flags                |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroTradeMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.contraOrderId = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.pid = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.contraPid = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeDesignation = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeTransactionTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.flags = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Break Message: 16 bytes                                           *)
(***************************************************************************)

TradeBreakMessage ==
    [ timestamp   : Sample(8),
      executionId : Sample(8) ]

EncodeTradeBreakMessage(message) ==
    message.timestamp
        \o message.executionId

DecodeTradeBreakMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET executionId == ReadBytes(timestamp.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    Ok([ timestamp   |-> timestamp.value,
         executionId |-> executionId.value ], executionId.rest)

ZeroTradeBreakMessage ==
    [ timestamp   |-> [i \in 1 .. 8 |-> 0],
      executionId |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Break Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeBreakMessage ==
    { ZeroTradeBreakMessage }
        \cup { [ZeroTradeBreakMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeBreakMessage EXCEPT !.executionId = one] : one \in Sample(8) }

(***************************************************************************)
(* Calculated Value Message: 31 bytes                                      *)
(***************************************************************************)

CalculatedValueMessage ==
    [ timestamp      : Sample(8),
      symbol         : Sample(6),
      valueCategory  : Sample(1),
      value          : Sample(8),
      valueTimestamp : Sample(8) ]

EncodeCalculatedValueMessage(message) ==
    message.timestamp
        \o message.symbol
        \o message.valueCategory
        \o message.value
        \o message.valueTimestamp

DecodeCalculatedValueMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET valueCategory == ReadBytes(symbol.rest, 1) IN IF ~valueCategory.ok THEN Fail ELSE
    LET value == ReadBytes(valueCategory.rest, 8) IN IF ~value.ok THEN Fail ELSE
    LET valueTimestamp == ReadBytes(value.rest, 8) IN IF ~valueTimestamp.ok THEN Fail ELSE
    Ok([ timestamp      |-> timestamp.value,
         symbol         |-> symbol.value,
         valueCategory  |-> valueCategory.value,
         value          |-> value.value,
         valueTimestamp |-> valueTimestamp.value ], valueTimestamp.rest)

ZeroCalculatedValueMessage ==
    [ timestamp      |-> [i \in 1 .. 8 |-> 0],
      symbol         |-> [i \in 1 .. 6 |-> 0],
      valueCategory  |-> [i \in 1 .. 1 |-> 0],
      value          |-> [i \in 1 .. 8 |-> 0],
      valueTimestamp |-> [i \in 1 .. 8 |-> 0] ]

(* Calculated Value Message at zero, then each field in turn at the values it is checked at *)
CheckedCalculatedValueMessage ==
    { ZeroCalculatedValueMessage }
        \cup { [ZeroCalculatedValueMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroCalculatedValueMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroCalculatedValueMessage EXCEPT !.valueCategory = one] : one \in Sample(1) }
        \cup { [ZeroCalculatedValueMessage EXCEPT !.value = one] : one \in Sample(8) }
        \cup { [ZeroCalculatedValueMessage EXCEPT !.valueTimestamp = one] : one \in Sample(8) }

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
(* Auction Update Message: 32 bytes                                        *)
(***************************************************************************)

AuctionUpdateMessage ==
    [ timestamp       : Sample(8),
      symbol          : Sample(6),
      auctionType     : Sample(1),
      buyShares       : Sample(4),
      sellShares      : Sample(4),
      indicativePrice : Sample(8),
      reserved1       : Sample(1) ]

EncodeAuctionUpdateMessage(message) ==
    message.timestamp
        \o message.symbol
        \o message.auctionType
        \o message.buyShares
        \o message.sellShares
        \o message.indicativePrice
        \o message.reserved1

DecodeAuctionUpdateMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET auctionType == ReadBytes(symbol.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET buyShares == ReadBytes(auctionType.rest, 4) IN IF ~buyShares.ok THEN Fail ELSE
    LET sellShares == ReadBytes(buyShares.rest, 4) IN IF ~sellShares.ok THEN Fail ELSE
    LET indicativePrice == ReadBytes(sellShares.rest, 8) IN IF ~indicativePrice.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(indicativePrice.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ timestamp       |-> timestamp.value,
         symbol          |-> symbol.value,
         auctionType     |-> auctionType.value,
         buyShares       |-> buyShares.value,
         sellShares      |-> sellShares.value,
         indicativePrice |-> indicativePrice.value,
         reserved1       |-> reserved1.value ], reserved1.rest)

ZeroAuctionUpdateMessage ==
    [ timestamp       |-> [i \in 1 .. 8 |-> 0],
      symbol          |-> [i \in 1 .. 6 |-> 0],
      auctionType     |-> [i \in 1 .. 1 |-> 0],
      buyShares       |-> [i \in 1 .. 4 |-> 0],
      sellShares      |-> [i \in 1 .. 4 |-> 0],
      indicativePrice |-> [i \in 1 .. 8 |-> 0],
      reserved1       |-> [i \in 1 .. 1 |-> 0] ]

(* Auction Update Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionUpdateMessage ==
    { ZeroAuctionUpdateMessage }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.buyShares = one] : one \in Sample(4) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.sellShares = one] : one \in Sample(4) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.indicativePrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Auction Summary Message: 28 bytes                                       *)
(***************************************************************************)

AuctionSummaryMessage ==
    [ timestamp   : Sample(8),
      symbol      : Sample(6),
      auctionType : Sample(1),
      price       : Sample(8),
      shares      : Sample(4),
      reserved1   : Sample(1) ]

EncodeAuctionSummaryMessage(message) ==
    message.timestamp
        \o message.symbol
        \o message.auctionType
        \o message.price
        \o message.shares
        \o message.reserved1

DecodeAuctionSummaryMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET auctionType == ReadBytes(symbol.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET price == ReadBytes(auctionType.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET shares == ReadBytes(price.rest, 4) IN IF ~shares.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(shares.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ timestamp   |-> timestamp.value,
         symbol      |-> symbol.value,
         auctionType |-> auctionType.value,
         price       |-> price.value,
         shares      |-> shares.value,
         reserved1   |-> reserved1.value ], reserved1.rest)

ZeroAuctionSummaryMessage ==
    [ timestamp   |-> [i \in 1 .. 8 |-> 0],
      symbol      |-> [i \in 1 .. 6 |-> 0],
      auctionType |-> [i \in 1 .. 1 |-> 0],
      price       |-> [i \in 1 .. 8 |-> 0],
      shares      |-> [i \in 1 .. 4 |-> 0],
      reserved1   |-> [i \in 1 .. 1 |-> 0] ]

(* Auction Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionSummaryMessage ==
    { ZeroAuctionSummaryMessage }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.shares = one] : one \in Sample(4) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

UnitClearMessageCode == 151  \* 0x97
TradingStatusMessageCode == 59  \* 0x3b
AddOrderMessageCode == 55  \* 0x37
OrderExecutedMessageCode == 56  \* 0x38
OrderExecutedAtPriceMessageCode == 88  \* 0x58
ReduceSizeMessageCode == 57  \* 0x39
ModifyOrderMessageCode == 58  \* 0x3a
DeleteOrderMessageCode == 60  \* 0x3c
TradeMessageCode == 61  \* 0x3d
TradeBreakMessageCode == 62  \* 0x3e
CalculatedValueMessageCode == 227  \* 0xe3
EndOfSessionMessageCode == 45  \* 0x2d
AuctionUpdateMessageCode == 89  \* 0x59
AuctionSummaryMessageCode == 90  \* 0x5a

Payload ==
    [ tag : {UnitClearMessageCode}, body : UnitClearMessage ]
        \cup [ tag : {TradingStatusMessageCode}, body : TradingStatusMessage ]
        \cup [ tag : {AddOrderMessageCode}, body : AddOrderMessage ]
        \cup [ tag : {OrderExecutedMessageCode}, body : OrderExecutedMessage ]
        \cup [ tag : {OrderExecutedAtPriceMessageCode}, body : OrderExecutedAtPriceMessage ]
        \cup [ tag : {ReduceSizeMessageCode}, body : ReduceSizeMessage ]
        \cup [ tag : {ModifyOrderMessageCode}, body : ModifyOrderMessage ]
        \cup [ tag : {DeleteOrderMessageCode}, body : DeleteOrderMessage ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {TradeBreakMessageCode}, body : TradeBreakMessage ]
        \cup [ tag : {CalculatedValueMessageCode}, body : CalculatedValueMessage ]
        \cup [ tag : {EndOfSessionMessageCode}, body : EndOfSessionMessage ]
        \cup [ tag : {AuctionUpdateMessageCode}, body : AuctionUpdateMessage ]
        \cup [ tag : {AuctionSummaryMessageCode}, body : AuctionSummaryMessage ]

EncodePayload(message) ==
    CASE message.tag = UnitClearMessageCode -> EncodeUnitClearMessage(message.body)
      [] message.tag = TradingStatusMessageCode -> EncodeTradingStatusMessage(message.body)
      [] message.tag = AddOrderMessageCode -> EncodeAddOrderMessage(message.body)
      [] message.tag = OrderExecutedMessageCode -> EncodeOrderExecutedMessage(message.body)
      [] message.tag = OrderExecutedAtPriceMessageCode -> EncodeOrderExecutedAtPriceMessage(message.body)
      [] message.tag = ReduceSizeMessageCode -> EncodeReduceSizeMessage(message.body)
      [] message.tag = ModifyOrderMessageCode -> EncodeModifyOrderMessage(message.body)
      [] message.tag = DeleteOrderMessageCode -> EncodeDeleteOrderMessage(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = TradeBreakMessageCode -> EncodeTradeBreakMessage(message.body)
      [] message.tag = CalculatedValueMessageCode -> EncodeCalculatedValueMessage(message.body)
      [] message.tag = EndOfSessionMessageCode -> EncodeEndOfSessionMessage(message.body)
      [] message.tag = AuctionUpdateMessageCode -> EncodeAuctionUpdateMessage(message.body)
      [] message.tag = AuctionSummaryMessageCode -> EncodeAuctionSummaryMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = UnitClearMessageCode -> DecodeUnitClearMessage(bytes)
              [] tag = TradingStatusMessageCode -> DecodeTradingStatusMessage(bytes)
              [] tag = AddOrderMessageCode -> DecodeAddOrderMessage(bytes)
              [] tag = OrderExecutedMessageCode -> DecodeOrderExecutedMessage(bytes)
              [] tag = OrderExecutedAtPriceMessageCode -> DecodeOrderExecutedAtPriceMessage(bytes)
              [] tag = ReduceSizeMessageCode -> DecodeReduceSizeMessage(bytes)
              [] tag = ModifyOrderMessageCode -> DecodeModifyOrderMessage(bytes)
              [] tag = DeleteOrderMessageCode -> DecodeDeleteOrderMessage(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = TradeBreakMessageCode -> DecodeTradeBreakMessage(bytes)
              [] tag = CalculatedValueMessageCode -> DecodeCalculatedValueMessage(bytes)
              [] tag = EndOfSessionMessageCode -> DecodeEndOfSessionMessage(bytes)
              [] tag = AuctionUpdateMessageCode -> DecodeAuctionUpdateMessage(bytes)
              [] tag = AuctionSummaryMessageCode -> DecodeAuctionSummaryMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> UnitClearMessageCode, body |-> ZeroUnitClearMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> UnitClearMessageCode, body |-> one] : one \in CheckedUnitClearMessage }
        \cup { [tag |-> TradingStatusMessageCode, body |-> one] : one \in CheckedTradingStatusMessage }
        \cup { [tag |-> AddOrderMessageCode, body |-> one] : one \in CheckedAddOrderMessage }
        \cup { [tag |-> OrderExecutedMessageCode, body |-> one] : one \in CheckedOrderExecutedMessage }
        \cup { [tag |-> OrderExecutedAtPriceMessageCode, body |-> one] : one \in CheckedOrderExecutedAtPriceMessage }
        \cup { [tag |-> ReduceSizeMessageCode, body |-> one] : one \in CheckedReduceSizeMessage }
        \cup { [tag |-> ModifyOrderMessageCode, body |-> one] : one \in CheckedModifyOrderMessage }
        \cup { [tag |-> DeleteOrderMessageCode, body |-> one] : one \in CheckedDeleteOrderMessage }
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> TradeBreakMessageCode, body |-> one] : one \in CheckedTradeBreakMessage }
        \cup { [tag |-> CalculatedValueMessageCode, body |-> one] : one \in CheckedCalculatedValueMessage }
        \cup { [tag |-> EndOfSessionMessageCode, body |-> one] : one \in CheckedEndOfSessionMessage }
        \cup { [tag |-> AuctionUpdateMessageCode, body |-> one] : one \in CheckedAuctionUpdateMessage }
        \cup { [tag |-> AuctionSummaryMessageCode, body |-> one] : one \in CheckedAuctionSummaryMessage }

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
      [ZeroMessage EXCEPT !.payload = [tag |-> TradingStatusMessageCode, body |-> ZeroTradingStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddOrderMessageCode, body |-> ZeroAddOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderExecutedMessageCode, body |-> ZeroOrderExecutedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderExecutedAtPriceMessageCode, body |-> ZeroOrderExecutedAtPriceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ReduceSizeMessageCode, body |-> ZeroReduceSizeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ModifyOrderMessageCode, body |-> ZeroModifyOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> DeleteOrderMessageCode, body |-> ZeroDeleteOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeMessageCode, body |-> ZeroTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeBreakMessageCode, body |-> ZeroTradeBreakMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CalculatedValueMessageCode, body |-> ZeroCalculatedValueMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EndOfSessionMessageCode, body |-> ZeroEndOfSessionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionUpdateMessageCode, body |-> ZeroAuctionUpdateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionSummaryMessageCode, body |-> ZeroAuctionSummaryMessage]] }

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

(* Every Order Executed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutedMessage ==
    \A message \in CheckedOrderExecutedMessage :
        LET read == DecodeOrderExecutedMessage(EncodeOrderExecutedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Executed At Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutedAtPriceMessage ==
    \A message \in CheckedOrderExecutedAtPriceMessage :
        LET read == DecodeOrderExecutedAtPriceMessage(EncodeOrderExecutedAtPriceMessage(message))
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

(* Every Modify Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyOrderMessage ==
    \A message \in CheckedModifyOrderMessage :
        LET read == DecodeModifyOrderMessage(EncodeModifyOrderMessage(message))
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

(* Every Calculated Value Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCalculatedValueMessage ==
    \A message \in CheckedCalculatedValueMessage :
        LET read == DecodeCalculatedValueMessage(EncodeCalculatedValueMessage(message))
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
