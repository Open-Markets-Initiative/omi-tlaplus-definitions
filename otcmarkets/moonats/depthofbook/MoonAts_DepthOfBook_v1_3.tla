--------------------- MODULE MoonAts_DepthOfBook_v1_3 ----------------------
(***************************************************************************)
(* OTC Markets Group OTC Depth of Book v1.3                                *)
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
(* Note: Packet Flag is a bit field set, checked as its 1 byte rather than *)
(* bit by bit.                                                             *)
(*                                                                         *)
(* Note: a Message Count of 0 marks Heartbeat Packet and carries no        *)
(* Message.                                                                *)
(*                                                                         *)
(* Note: Security Flags is a bit field set, checked as its 2 bytes rather  *)
(* than bit by bit.                                                        *)
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
(* Start Of Spin Message: 13 bytes                                         *)
(***************************************************************************)

StartOfSpinMessage ==
    [ spinType           : Sample(1),
      spinStartTimeMilli : Sample(8),
      spinLastSeqNum     : Sample(4) ]

EncodeStartOfSpinMessage(message) ==
    message.spinType
        \o message.spinStartTimeMilli
        \o message.spinLastSeqNum

DecodeStartOfSpinMessage(bytes) ==
    LET spinType == ReadBytes(bytes, 1) IN IF ~spinType.ok THEN Fail ELSE
    LET spinStartTimeMilli == ReadBytes(spinType.rest, 8) IN IF ~spinStartTimeMilli.ok THEN Fail ELSE
    LET spinLastSeqNum == ReadBytes(spinStartTimeMilli.rest, 4) IN IF ~spinLastSeqNum.ok THEN Fail ELSE
    Ok([ spinType           |-> spinType.value,
         spinStartTimeMilli |-> spinStartTimeMilli.value,
         spinLastSeqNum     |-> spinLastSeqNum.value ], spinLastSeqNum.rest)

ZeroStartOfSpinMessage ==
    [ spinType           |-> [i \in 1 .. 1 |-> 0],
      spinStartTimeMilli |-> [i \in 1 .. 8 |-> 0],
      spinLastSeqNum     |-> [i \in 1 .. 4 |-> 0] ]

(* Start Of Spin Message at zero, then each field in turn at the values it is checked at *)
CheckedStartOfSpinMessage ==
    { ZeroStartOfSpinMessage }
        \cup { [ZeroStartOfSpinMessage EXCEPT !.spinType = one] : one \in Sample(1) }
        \cup { [ZeroStartOfSpinMessage EXCEPT !.spinStartTimeMilli = one] : one \in Sample(8) }
        \cup { [ZeroStartOfSpinMessage EXCEPT !.spinLastSeqNum = one] : one \in Sample(4) }

(***************************************************************************)
(* End Of Spin Message: 17 bytes                                           *)
(***************************************************************************)

EndOfSpinMessage ==
    [ spinType         : Sample(1),
      spinMsgCt        : Sample(4),
      spinEndTimeMilli : Sample(8),
      spinLastSeqNum   : Sample(4) ]

EncodeEndOfSpinMessage(message) ==
    message.spinType
        \o message.spinMsgCt
        \o message.spinEndTimeMilli
        \o message.spinLastSeqNum

DecodeEndOfSpinMessage(bytes) ==
    LET spinType == ReadBytes(bytes, 1) IN IF ~spinType.ok THEN Fail ELSE
    LET spinMsgCt == ReadBytes(spinType.rest, 4) IN IF ~spinMsgCt.ok THEN Fail ELSE
    LET spinEndTimeMilli == ReadBytes(spinMsgCt.rest, 8) IN IF ~spinEndTimeMilli.ok THEN Fail ELSE
    LET spinLastSeqNum == ReadBytes(spinEndTimeMilli.rest, 4) IN IF ~spinLastSeqNum.ok THEN Fail ELSE
    Ok([ spinType         |-> spinType.value,
         spinMsgCt        |-> spinMsgCt.value,
         spinEndTimeMilli |-> spinEndTimeMilli.value,
         spinLastSeqNum   |-> spinLastSeqNum.value ], spinLastSeqNum.rest)

ZeroEndOfSpinMessage ==
    [ spinType         |-> [i \in 1 .. 1 |-> 0],
      spinMsgCt        |-> [i \in 1 .. 4 |-> 0],
      spinEndTimeMilli |-> [i \in 1 .. 8 |-> 0],
      spinLastSeqNum   |-> [i \in 1 .. 4 |-> 0] ]

(* End Of Spin Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfSpinMessage ==
    { ZeroEndOfSpinMessage }
        \cup { [ZeroEndOfSpinMessage EXCEPT !.spinType = one] : one \in Sample(1) }
        \cup { [ZeroEndOfSpinMessage EXCEPT !.spinMsgCt = one] : one \in Sample(4) }
        \cup { [ZeroEndOfSpinMessage EXCEPT !.spinEndTimeMilli = one] : one \in Sample(8) }
        \cup { [ZeroEndOfSpinMessage EXCEPT !.spinLastSeqNum = one] : one \in Sample(4) }

(***************************************************************************)
(* Trading Session Message: 9 bytes                                        *)
(***************************************************************************)

TradingSessionMessage ==
    [ sessionTime    : Sample(8),
      tradingSession : Sample(1) ]

EncodeTradingSessionMessage(message) ==
    message.sessionTime
        \o message.tradingSession

DecodeTradingSessionMessage(bytes) ==
    LET sessionTime == ReadBytes(bytes, 8) IN IF ~sessionTime.ok THEN Fail ELSE
    LET tradingSession == ReadBytes(sessionTime.rest, 1) IN IF ~tradingSession.ok THEN Fail ELSE
    Ok([ sessionTime    |-> sessionTime.value,
         tradingSession |-> tradingSession.value ], tradingSession.rest)

ZeroTradingSessionMessage ==
    [ sessionTime    |-> [i \in 1 .. 8 |-> 0],
      tradingSession |-> [i \in 1 .. 1 |-> 0] ]

(* Trading Session Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingSessionMessage ==
    { ZeroTradingSessionMessage }
        \cup { [ZeroTradingSessionMessage EXCEPT !.sessionTime = one] : one \in Sample(8) }
        \cup { [ZeroTradingSessionMessage EXCEPT !.tradingSession = one] : one \in Sample(1) }

(***************************************************************************)
(* Security Message: 33 bytes                                              *)
(***************************************************************************)

SecurityMessage ==
    [ symbol          : Sample(14),
      lastUpdateMilli : Sample(8),
      securityAction  : Sample(1),
      assetClass      : Sample(1),
      securityId      : Sample(4),
      securityFlags   : Sample(2),
      tier            : Sample(1),
      reportingStatus : Sample(1),
      securityStatus  : Sample(1) ]

EncodeSecurityMessage(message) ==
    message.symbol
        \o message.lastUpdateMilli
        \o message.securityAction
        \o message.assetClass
        \o message.securityId
        \o message.securityFlags
        \o message.tier
        \o message.reportingStatus
        \o message.securityStatus

DecodeSecurityMessage(bytes) ==
    LET symbol == ReadBytes(bytes, 14) IN IF ~symbol.ok THEN Fail ELSE
    LET lastUpdateMilli == ReadBytes(symbol.rest, 8) IN IF ~lastUpdateMilli.ok THEN Fail ELSE
    LET securityAction == ReadBytes(lastUpdateMilli.rest, 1) IN IF ~securityAction.ok THEN Fail ELSE
    LET assetClass == ReadBytes(securityAction.rest, 1) IN IF ~assetClass.ok THEN Fail ELSE
    LET securityId == ReadBytes(assetClass.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET securityFlags == ReadBytes(securityId.rest, 2) IN IF ~securityFlags.ok THEN Fail ELSE
    LET tier == ReadBytes(securityFlags.rest, 1) IN IF ~tier.ok THEN Fail ELSE
    LET reportingStatus == ReadBytes(tier.rest, 1) IN IF ~reportingStatus.ok THEN Fail ELSE
    LET securityStatus == ReadBytes(reportingStatus.rest, 1) IN IF ~securityStatus.ok THEN Fail ELSE
    Ok([ symbol          |-> symbol.value,
         lastUpdateMilli |-> lastUpdateMilli.value,
         securityAction  |-> securityAction.value,
         assetClass      |-> assetClass.value,
         securityId      |-> securityId.value,
         securityFlags   |-> securityFlags.value,
         tier            |-> tier.value,
         reportingStatus |-> reportingStatus.value,
         securityStatus  |-> securityStatus.value ], securityStatus.rest)

ZeroSecurityMessage ==
    [ symbol          |-> [i \in 1 .. 14 |-> 0],
      lastUpdateMilli |-> [i \in 1 .. 8 |-> 0],
      securityAction  |-> [i \in 1 .. 1 |-> 0],
      assetClass      |-> [i \in 1 .. 1 |-> 0],
      securityId      |-> [i \in 1 .. 4 |-> 0],
      securityFlags   |-> [i \in 1 .. 2 |-> 0],
      tier            |-> [i \in 1 .. 1 |-> 0],
      reportingStatus |-> [i \in 1 .. 1 |-> 0],
      securityStatus  |-> [i \in 1 .. 1 |-> 0] ]

(* Security Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityMessage ==
    { ZeroSecurityMessage }
        \cup { [ZeroSecurityMessage EXCEPT !.symbol = one] : one \in Sample(14) }
        \cup { [ZeroSecurityMessage EXCEPT !.lastUpdateMilli = one] : one \in Sample(8) }
        \cup { [ZeroSecurityMessage EXCEPT !.securityAction = one] : one \in Sample(1) }
        \cup { [ZeroSecurityMessage EXCEPT !.assetClass = one] : one \in Sample(1) }
        \cup { [ZeroSecurityMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityMessage EXCEPT !.securityFlags = one] : one \in Sample(2) }
        \cup { [ZeroSecurityMessage EXCEPT !.tier = one] : one \in Sample(1) }
        \cup { [ZeroSecurityMessage EXCEPT !.reportingStatus = one] : one \in Sample(1) }
        \cup { [ZeroSecurityMessage EXCEPT !.securityStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Add Message: 52 bytes                                             *)
(***************************************************************************)

OrderAddMessage ==
    [ time          : Sample(4),
      orderId       : Sample(14),
      sideIndicator : Sample(1),
      quantity      : Sample(4),
      symbol        : Sample(14),
      price         : Sample(8),
      firmId        : Sample(4),
      unsolicited   : Sample(1),
      orderFlags    : Sample(2) ]

EncodeOrderAddMessage(message) ==
    message.time
        \o message.orderId
        \o message.sideIndicator
        \o message.quantity
        \o message.symbol
        \o message.price
        \o message.firmId
        \o message.unsolicited
        \o message.orderFlags

DecodeOrderAddMessage(bytes) ==
    LET time == ReadBytes(bytes, 4) IN IF ~time.ok THEN Fail ELSE
    LET orderId == ReadBytes(time.rest, 14) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET quantity == ReadBytes(sideIndicator.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET symbol == ReadBytes(quantity.rest, 14) IN IF ~symbol.ok THEN Fail ELSE
    LET price == ReadBytes(symbol.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET firmId == ReadBytes(price.rest, 4) IN IF ~firmId.ok THEN Fail ELSE
    LET unsolicited == ReadBytes(firmId.rest, 1) IN IF ~unsolicited.ok THEN Fail ELSE
    LET orderFlags == ReadBytes(unsolicited.rest, 2) IN IF ~orderFlags.ok THEN Fail ELSE
    Ok([ time          |-> time.value,
         orderId       |-> orderId.value,
         sideIndicator |-> sideIndicator.value,
         quantity      |-> quantity.value,
         symbol        |-> symbol.value,
         price         |-> price.value,
         firmId        |-> firmId.value,
         unsolicited   |-> unsolicited.value,
         orderFlags    |-> orderFlags.value ], orderFlags.rest)

ZeroOrderAddMessage ==
    [ time          |-> [i \in 1 .. 4 |-> 0],
      orderId       |-> [i \in 1 .. 14 |-> 0],
      sideIndicator |-> [i \in 1 .. 1 |-> 0],
      quantity      |-> [i \in 1 .. 4 |-> 0],
      symbol        |-> [i \in 1 .. 14 |-> 0],
      price         |-> [i \in 1 .. 8 |-> 0],
      firmId        |-> [i \in 1 .. 4 |-> 0],
      unsolicited   |-> [i \in 1 .. 1 |-> 0],
      orderFlags    |-> [i \in 1 .. 2 |-> 0] ]

(* Order Add Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderAddMessage ==
    { ZeroOrderAddMessage }
        \cup { [ZeroOrderAddMessage EXCEPT !.time = one] : one \in Sample(4) }
        \cup { [ZeroOrderAddMessage EXCEPT !.orderId = one] : one \in Sample(14) }
        \cup { [ZeroOrderAddMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderAddMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderAddMessage EXCEPT !.symbol = one] : one \in Sample(14) }
        \cup { [ZeroOrderAddMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderAddMessage EXCEPT !.firmId = one] : one \in Sample(4) }
        \cup { [ZeroOrderAddMessage EXCEPT !.unsolicited = one] : one \in Sample(1) }
        \cup { [ZeroOrderAddMessage EXCEPT !.orderFlags = one] : one \in Sample(2) }

(***************************************************************************)
(* Order Update Message: 32 bytes                                          *)
(***************************************************************************)

OrderUpdateMessage ==
    [ time       : Sample(4),
      orderId    : Sample(14),
      quantity   : Sample(4),
      price      : Sample(8),
      orderFlags : Sample(2) ]

EncodeOrderUpdateMessage(message) ==
    message.time
        \o message.orderId
        \o message.quantity
        \o message.price
        \o message.orderFlags

DecodeOrderUpdateMessage(bytes) ==
    LET time == ReadBytes(bytes, 4) IN IF ~time.ok THEN Fail ELSE
    LET orderId == ReadBytes(time.rest, 14) IN IF ~orderId.ok THEN Fail ELSE
    LET quantity == ReadBytes(orderId.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderFlags == ReadBytes(price.rest, 2) IN IF ~orderFlags.ok THEN Fail ELSE
    Ok([ time       |-> time.value,
         orderId    |-> orderId.value,
         quantity   |-> quantity.value,
         price      |-> price.value,
         orderFlags |-> orderFlags.value ], orderFlags.rest)

ZeroOrderUpdateMessage ==
    [ time       |-> [i \in 1 .. 4 |-> 0],
      orderId    |-> [i \in 1 .. 14 |-> 0],
      quantity   |-> [i \in 1 .. 4 |-> 0],
      price      |-> [i \in 1 .. 8 |-> 0],
      orderFlags |-> [i \in 1 .. 2 |-> 0] ]

(* Order Update Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderUpdateMessage ==
    { ZeroOrderUpdateMessage }
        \cup { [ZeroOrderUpdateMessage EXCEPT !.time = one] : one \in Sample(4) }
        \cup { [ZeroOrderUpdateMessage EXCEPT !.orderId = one] : one \in Sample(14) }
        \cup { [ZeroOrderUpdateMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderUpdateMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderUpdateMessage EXCEPT !.orderFlags = one] : one \in Sample(2) }

(***************************************************************************)
(* Order Delete Message: 18 bytes                                          *)
(***************************************************************************)

OrderDeleteMessage ==
    [ time    : Sample(4),
      orderId : Sample(14) ]

EncodeOrderDeleteMessage(message) ==
    message.time
        \o message.orderId

DecodeOrderDeleteMessage(bytes) ==
    LET time == ReadBytes(bytes, 4) IN IF ~time.ok THEN Fail ELSE
    LET orderId == ReadBytes(time.rest, 14) IN IF ~orderId.ok THEN Fail ELSE
    Ok([ time    |-> time.value,
         orderId |-> orderId.value ], orderId.rest)

ZeroOrderDeleteMessage ==
    [ time    |-> [i \in 1 .. 4 |-> 0],
      orderId |-> [i \in 1 .. 14 |-> 0] ]

(* Order Delete Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderDeleteMessage ==
    { ZeroOrderDeleteMessage }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.time = one] : one \in Sample(4) }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.orderId = one] : one \in Sample(14) }

(***************************************************************************)
(* Order Execution Message: 34 bytes                                       *)
(***************************************************************************)

OrderExecutionMessage ==
    [ time              : Sample(4),
      orderId           : Sample(14),
      executedQuantity  : Sample(4),
      remainingQuantity : Sample(4),
      executionId       : Sample(8) ]

EncodeOrderExecutionMessage(message) ==
    message.time
        \o message.orderId
        \o message.executedQuantity
        \o message.remainingQuantity
        \o message.executionId

DecodeOrderExecutionMessage(bytes) ==
    LET time == ReadBytes(bytes, 4) IN IF ~time.ok THEN Fail ELSE
    LET orderId == ReadBytes(time.rest, 14) IN IF ~orderId.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(orderId.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET remainingQuantity == ReadBytes(executedQuantity.rest, 4) IN IF ~remainingQuantity.ok THEN Fail ELSE
    LET executionId == ReadBytes(remainingQuantity.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    Ok([ time              |-> time.value,
         orderId           |-> orderId.value,
         executedQuantity  |-> executedQuantity.value,
         remainingQuantity |-> remainingQuantity.value,
         executionId       |-> executionId.value ], executionId.rest)

ZeroOrderExecutionMessage ==
    [ time              |-> [i \in 1 .. 4 |-> 0],
      orderId           |-> [i \in 1 .. 14 |-> 0],
      executedQuantity  |-> [i \in 1 .. 4 |-> 0],
      remainingQuantity |-> [i \in 1 .. 4 |-> 0],
      executionId       |-> [i \in 1 .. 8 |-> 0] ]

(* Order Execution Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutionMessage ==
    { ZeroOrderExecutionMessage }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.time = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.orderId = one] : one \in Sample(14) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.remainingQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.executionId = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Execution With Price Message: 42 bytes                            *)
(***************************************************************************)

OrderExecutionWithPriceMessage ==
    [ time              : Sample(4),
      orderId           : Sample(14),
      executedQuantity  : Sample(4),
      remainingQuantity : Sample(4),
      executionId       : Sample(8),
      price             : Sample(8) ]

EncodeOrderExecutionWithPriceMessage(message) ==
    message.time
        \o message.orderId
        \o message.executedQuantity
        \o message.remainingQuantity
        \o message.executionId
        \o message.price

DecodeOrderExecutionWithPriceMessage(bytes) ==
    LET time == ReadBytes(bytes, 4) IN IF ~time.ok THEN Fail ELSE
    LET orderId == ReadBytes(time.rest, 14) IN IF ~orderId.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(orderId.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET remainingQuantity == ReadBytes(executedQuantity.rest, 4) IN IF ~remainingQuantity.ok THEN Fail ELSE
    LET executionId == ReadBytes(remainingQuantity.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET price == ReadBytes(executionId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    Ok([ time              |-> time.value,
         orderId           |-> orderId.value,
         executedQuantity  |-> executedQuantity.value,
         remainingQuantity |-> remainingQuantity.value,
         executionId       |-> executionId.value,
         price             |-> price.value ], price.rest)

ZeroOrderExecutionWithPriceMessage ==
    [ time              |-> [i \in 1 .. 4 |-> 0],
      orderId           |-> [i \in 1 .. 14 |-> 0],
      executedQuantity  |-> [i \in 1 .. 4 |-> 0],
      remainingQuantity |-> [i \in 1 .. 4 |-> 0],
      executionId       |-> [i \in 1 .. 8 |-> 0],
      price             |-> [i \in 1 .. 8 |-> 0] ]

(* Order Execution With Price Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutionWithPriceMessage ==
    { ZeroOrderExecutionWithPriceMessage }
        \cup { [ZeroOrderExecutionWithPriceMessage EXCEPT !.time = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionWithPriceMessage EXCEPT !.orderId = one] : one \in Sample(14) }
        \cup { [ZeroOrderExecutionWithPriceMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionWithPriceMessage EXCEPT !.remainingQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionWithPriceMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionWithPriceMessage EXCEPT !.price = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Message: 47 bytes                                                 *)
(***************************************************************************)

TradeMessage ==
    [ time                : Sample(4),
      sideIndicator       : Sample(1),
      quantity            : Sample(4),
      symbol              : Sample(14),
      price               : Sample(8),
      executionId         : Sample(8),
      reservedBinaryLong8 : Sample(8) ]

EncodeTradeMessage(message) ==
    message.time
        \o message.sideIndicator
        \o message.quantity
        \o message.symbol
        \o message.price
        \o message.executionId
        \o message.reservedBinaryLong8

DecodeTradeMessage(bytes) ==
    LET time == ReadBytes(bytes, 4) IN IF ~time.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(time.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET quantity == ReadBytes(sideIndicator.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET symbol == ReadBytes(quantity.rest, 14) IN IF ~symbol.ok THEN Fail ELSE
    LET price == ReadBytes(symbol.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET executionId == ReadBytes(price.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET reservedBinaryLong8 == ReadBytes(executionId.rest, 8) IN IF ~reservedBinaryLong8.ok THEN Fail ELSE
    Ok([ time                |-> time.value,
         sideIndicator       |-> sideIndicator.value,
         quantity            |-> quantity.value,
         symbol              |-> symbol.value,
         price               |-> price.value,
         executionId         |-> executionId.value,
         reservedBinaryLong8 |-> reservedBinaryLong8.value ], reservedBinaryLong8.rest)

ZeroTradeMessage ==
    [ time                |-> [i \in 1 .. 4 |-> 0],
      sideIndicator       |-> [i \in 1 .. 1 |-> 0],
      quantity            |-> [i \in 1 .. 4 |-> 0],
      symbol              |-> [i \in 1 .. 14 |-> 0],
      price               |-> [i \in 1 .. 8 |-> 0],
      executionId         |-> [i \in 1 .. 8 |-> 0],
      reservedBinaryLong8 |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.time = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.symbol = one] : one \in Sample(14) }
        \cup { [ZeroTradeMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.reservedBinaryLong8 = one] : one \in Sample(8) }

(***************************************************************************)
(* Imbalance Message: 52 bytes                                             *)
(***************************************************************************)

ImbalanceMessage ==
    [ time                           : Sample(4),
      symbol                         : Sample(14),
      currentInsidePairedShares      : Sample(4),
      currentInsideClosingPrice      : Sample(8),
      currentInsideImbalanceQuantity : Sample(4),
      currentInsideImbalanceSide     : Sample(1),
      fullClosingPrice               : Sample(8),
      ocioOnlyClosingPrice           : Sample(8),
      mocSharesUnmatched             : Sample(1) ]

EncodeImbalanceMessage(message) ==
    message.time
        \o message.symbol
        \o message.currentInsidePairedShares
        \o message.currentInsideClosingPrice
        \o message.currentInsideImbalanceQuantity
        \o message.currentInsideImbalanceSide
        \o message.fullClosingPrice
        \o message.ocioOnlyClosingPrice
        \o message.mocSharesUnmatched

DecodeImbalanceMessage(bytes) ==
    LET time == ReadBytes(bytes, 4) IN IF ~time.ok THEN Fail ELSE
    LET symbol == ReadBytes(time.rest, 14) IN IF ~symbol.ok THEN Fail ELSE
    LET currentInsidePairedShares == ReadBytes(symbol.rest, 4) IN IF ~currentInsidePairedShares.ok THEN Fail ELSE
    LET currentInsideClosingPrice == ReadBytes(currentInsidePairedShares.rest, 8) IN IF ~currentInsideClosingPrice.ok THEN Fail ELSE
    LET currentInsideImbalanceQuantity == ReadBytes(currentInsideClosingPrice.rest, 4) IN IF ~currentInsideImbalanceQuantity.ok THEN Fail ELSE
    LET currentInsideImbalanceSide == ReadBytes(currentInsideImbalanceQuantity.rest, 1) IN IF ~currentInsideImbalanceSide.ok THEN Fail ELSE
    LET fullClosingPrice == ReadBytes(currentInsideImbalanceSide.rest, 8) IN IF ~fullClosingPrice.ok THEN Fail ELSE
    LET ocioOnlyClosingPrice == ReadBytes(fullClosingPrice.rest, 8) IN IF ~ocioOnlyClosingPrice.ok THEN Fail ELSE
    LET mocSharesUnmatched == ReadBytes(ocioOnlyClosingPrice.rest, 1) IN IF ~mocSharesUnmatched.ok THEN Fail ELSE
    Ok([ time                           |-> time.value,
         symbol                         |-> symbol.value,
         currentInsidePairedShares      |-> currentInsidePairedShares.value,
         currentInsideClosingPrice      |-> currentInsideClosingPrice.value,
         currentInsideImbalanceQuantity |-> currentInsideImbalanceQuantity.value,
         currentInsideImbalanceSide     |-> currentInsideImbalanceSide.value,
         fullClosingPrice               |-> fullClosingPrice.value,
         ocioOnlyClosingPrice           |-> ocioOnlyClosingPrice.value,
         mocSharesUnmatched             |-> mocSharesUnmatched.value ], mocSharesUnmatched.rest)

ZeroImbalanceMessage ==
    [ time                           |-> [i \in 1 .. 4 |-> 0],
      symbol                         |-> [i \in 1 .. 14 |-> 0],
      currentInsidePairedShares      |-> [i \in 1 .. 4 |-> 0],
      currentInsideClosingPrice      |-> [i \in 1 .. 8 |-> 0],
      currentInsideImbalanceQuantity |-> [i \in 1 .. 4 |-> 0],
      currentInsideImbalanceSide     |-> [i \in 1 .. 1 |-> 0],
      fullClosingPrice               |-> [i \in 1 .. 8 |-> 0],
      ocioOnlyClosingPrice           |-> [i \in 1 .. 8 |-> 0],
      mocSharesUnmatched             |-> [i \in 1 .. 1 |-> 0] ]

(* Imbalance Message at zero, then each field in turn at the values it is checked at *)
CheckedImbalanceMessage ==
    { ZeroImbalanceMessage }
        \cup { [ZeroImbalanceMessage EXCEPT !.time = one] : one \in Sample(4) }
        \cup { [ZeroImbalanceMessage EXCEPT !.symbol = one] : one \in Sample(14) }
        \cup { [ZeroImbalanceMessage EXCEPT !.currentInsidePairedShares = one] : one \in Sample(4) }
        \cup { [ZeroImbalanceMessage EXCEPT !.currentInsideClosingPrice = one] : one \in Sample(8) }
        \cup { [ZeroImbalanceMessage EXCEPT !.currentInsideImbalanceQuantity = one] : one \in Sample(4) }
        \cup { [ZeroImbalanceMessage EXCEPT !.currentInsideImbalanceSide = one] : one \in Sample(1) }
        \cup { [ZeroImbalanceMessage EXCEPT !.fullClosingPrice = one] : one \in Sample(8) }
        \cup { [ZeroImbalanceMessage EXCEPT !.ocioOnlyClosingPrice = one] : one \in Sample(8) }
        \cup { [ZeroImbalanceMessage EXCEPT !.mocSharesUnmatched = one] : one \in Sample(1) }

(***************************************************************************)
(* System Recovery Event Message: 17 bytes                                 *)
(***************************************************************************)

SystemRecoveryEventMessage ==
    [ deprecated         : Sample(4),
      recoveryType       : Sample(1),
      nextSequenceNumber : Sample(4),
      recoveryStartTime  : Sample(8) ]

EncodeSystemRecoveryEventMessage(message) ==
    message.deprecated
        \o message.recoveryType
        \o message.nextSequenceNumber
        \o message.recoveryStartTime

DecodeSystemRecoveryEventMessage(bytes) ==
    LET deprecated == ReadBytes(bytes, 4) IN IF ~deprecated.ok THEN Fail ELSE
    LET recoveryType == ReadBytes(deprecated.rest, 1) IN IF ~recoveryType.ok THEN Fail ELSE
    LET nextSequenceNumber == ReadBytes(recoveryType.rest, 4) IN IF ~nextSequenceNumber.ok THEN Fail ELSE
    LET recoveryStartTime == ReadBytes(nextSequenceNumber.rest, 8) IN IF ~recoveryStartTime.ok THEN Fail ELSE
    Ok([ deprecated         |-> deprecated.value,
         recoveryType       |-> recoveryType.value,
         nextSequenceNumber |-> nextSequenceNumber.value,
         recoveryStartTime  |-> recoveryStartTime.value ], recoveryStartTime.rest)

ZeroSystemRecoveryEventMessage ==
    [ deprecated         |-> [i \in 1 .. 4 |-> 0],
      recoveryType       |-> [i \in 1 .. 1 |-> 0],
      nextSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      recoveryStartTime  |-> [i \in 1 .. 8 |-> 0] ]

(* System Recovery Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemRecoveryEventMessage ==
    { ZeroSystemRecoveryEventMessage }
        \cup { [ZeroSystemRecoveryEventMessage EXCEPT !.deprecated = one] : one \in Sample(4) }
        \cup { [ZeroSystemRecoveryEventMessage EXCEPT !.recoveryType = one] : one \in Sample(1) }
        \cup { [ZeroSystemRecoveryEventMessage EXCEPT !.nextSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroSystemRecoveryEventMessage EXCEPT !.recoveryStartTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

StartOfSpinMessageCode == 11  \* 0x0b
EndOfSpinMessageCode == 12  \* 0x0c
TradingSessionMessageCode == 20  \* 0x14
SecurityMessageCode == 9  \* 0x09
OrderAddMessageCode == 21  \* 0x15
OrderUpdateMessageCode == 22  \* 0x16
OrderDeleteMessageCode == 23  \* 0x17
OrderExecutionMessageCode == 24  \* 0x18
OrderExecutionWithPriceMessageCode == 25  \* 0x19
TradeMessageCode == 26  \* 0x1a
ImbalanceMessageCode == 28  \* 0x1c
SystemRecoveryEventMessageCode == 74  \* 0x4a

Payload ==
    [ tag : {StartOfSpinMessageCode}, body : StartOfSpinMessage ]
        \cup [ tag : {EndOfSpinMessageCode}, body : EndOfSpinMessage ]
        \cup [ tag : {TradingSessionMessageCode}, body : TradingSessionMessage ]
        \cup [ tag : {SecurityMessageCode}, body : SecurityMessage ]
        \cup [ tag : {OrderAddMessageCode}, body : OrderAddMessage ]
        \cup [ tag : {OrderUpdateMessageCode}, body : OrderUpdateMessage ]
        \cup [ tag : {OrderDeleteMessageCode}, body : OrderDeleteMessage ]
        \cup [ tag : {OrderExecutionMessageCode}, body : OrderExecutionMessage ]
        \cup [ tag : {OrderExecutionWithPriceMessageCode}, body : OrderExecutionWithPriceMessage ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {ImbalanceMessageCode}, body : ImbalanceMessage ]
        \cup [ tag : {SystemRecoveryEventMessageCode}, body : SystemRecoveryEventMessage ]

EncodePayload(message) ==
    CASE message.tag = StartOfSpinMessageCode -> EncodeStartOfSpinMessage(message.body)
      [] message.tag = EndOfSpinMessageCode -> EncodeEndOfSpinMessage(message.body)
      [] message.tag = TradingSessionMessageCode -> EncodeTradingSessionMessage(message.body)
      [] message.tag = SecurityMessageCode -> EncodeSecurityMessage(message.body)
      [] message.tag = OrderAddMessageCode -> EncodeOrderAddMessage(message.body)
      [] message.tag = OrderUpdateMessageCode -> EncodeOrderUpdateMessage(message.body)
      [] message.tag = OrderDeleteMessageCode -> EncodeOrderDeleteMessage(message.body)
      [] message.tag = OrderExecutionMessageCode -> EncodeOrderExecutionMessage(message.body)
      [] message.tag = OrderExecutionWithPriceMessageCode -> EncodeOrderExecutionWithPriceMessage(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = ImbalanceMessageCode -> EncodeImbalanceMessage(message.body)
      [] message.tag = SystemRecoveryEventMessageCode -> EncodeSystemRecoveryEventMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = StartOfSpinMessageCode -> DecodeStartOfSpinMessage(bytes)
              [] tag = EndOfSpinMessageCode -> DecodeEndOfSpinMessage(bytes)
              [] tag = TradingSessionMessageCode -> DecodeTradingSessionMessage(bytes)
              [] tag = SecurityMessageCode -> DecodeSecurityMessage(bytes)
              [] tag = OrderAddMessageCode -> DecodeOrderAddMessage(bytes)
              [] tag = OrderUpdateMessageCode -> DecodeOrderUpdateMessage(bytes)
              [] tag = OrderDeleteMessageCode -> DecodeOrderDeleteMessage(bytes)
              [] tag = OrderExecutionMessageCode -> DecodeOrderExecutionMessage(bytes)
              [] tag = OrderExecutionWithPriceMessageCode -> DecodeOrderExecutionWithPriceMessage(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = ImbalanceMessageCode -> DecodeImbalanceMessage(bytes)
              [] tag = SystemRecoveryEventMessageCode -> DecodeSystemRecoveryEventMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> StartOfSpinMessageCode, body |-> ZeroStartOfSpinMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> StartOfSpinMessageCode, body |-> one] : one \in CheckedStartOfSpinMessage }
        \cup { [tag |-> EndOfSpinMessageCode, body |-> one] : one \in CheckedEndOfSpinMessage }
        \cup { [tag |-> TradingSessionMessageCode, body |-> one] : one \in CheckedTradingSessionMessage }
        \cup { [tag |-> SecurityMessageCode, body |-> one] : one \in CheckedSecurityMessage }
        \cup { [tag |-> OrderAddMessageCode, body |-> one] : one \in CheckedOrderAddMessage }
        \cup { [tag |-> OrderUpdateMessageCode, body |-> one] : one \in CheckedOrderUpdateMessage }
        \cup { [tag |-> OrderDeleteMessageCode, body |-> one] : one \in CheckedOrderDeleteMessage }
        \cup { [tag |-> OrderExecutionMessageCode, body |-> one] : one \in CheckedOrderExecutionMessage }
        \cup { [tag |-> OrderExecutionWithPriceMessageCode, body |-> one] : one \in CheckedOrderExecutionWithPriceMessage }
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> ImbalanceMessageCode, body |-> one] : one \in CheckedImbalanceMessage }
        \cup { [tag |-> SystemRecoveryEventMessageCode, body |-> one] : one \in CheckedSystemRecoveryEventMessage }

(***************************************************************************)
(* Message, framed by Message Size                                         *)
(***************************************************************************)

Message ==
    [ payload : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntBE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

(* Message Size counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntBE(Len(body) + 2, 2) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> StartOfSpinMessageCode, body |-> ZeroStartOfSpinMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EndOfSpinMessageCode, body |-> ZeroEndOfSpinMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradingSessionMessageCode, body |-> ZeroTradingSessionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityMessageCode, body |-> ZeroSecurityMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderAddMessageCode, body |-> ZeroOrderAddMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderUpdateMessageCode, body |-> ZeroOrderUpdateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderDeleteMessageCode, body |-> ZeroOrderDeleteMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderExecutionMessageCode, body |-> ZeroOrderExecutionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderExecutionWithPriceMessageCode, body |-> ZeroOrderExecutionWithPriceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeMessageCode, body |-> ZeroTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ImbalanceMessageCode, body |-> ZeroImbalanceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SystemRecoveryEventMessageCode, body |-> ZeroSystemRecoveryEventMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ packetSize  : Sample(2),
      seqNum      : Sample(4),
      packetFlag  : Sample(1),
      packetMilli : Sample(4),
      message     : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.packetSize
        \o message.seqNum
        \o message.packetFlag
        \o EncodeUIntBE(Len(message.message), 1)
        \o message.packetMilli
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET packetSize == ReadBytes(bytes, 2) IN IF ~packetSize.ok THEN Fail ELSE
    LET seqNum == ReadBytes(packetSize.rest, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET packetFlag == ReadBytes(seqNum.rest, 1) IN IF ~packetFlag.ok THEN Fail ELSE
    LET messageCount == ReadUIntBE(packetFlag.rest, 1) IN IF ~messageCount.ok THEN Fail ELSE
    LET packetMilli == ReadBytes(messageCount.rest, 4) IN IF ~packetMilli.ok THEN Fail ELSE
    LET message == ReadMessageList(packetMilli.rest, messageCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ packetSize  |-> packetSize.value,
         seqNum      |-> seqNum.value,
         packetFlag  |-> packetFlag.value,
         packetMilli |-> packetMilli.value,
         message     |-> message.value ], message.rest)

ZeroPacket ==
    [ packetSize  |-> [i \in 1 .. 2 |-> 0],
      seqNum      |-> [i \in 1 .. 4 |-> 0],
      packetFlag  |-> [i \in 1 .. 1 |-> 0],
      packetMilli |-> [i \in 1 .. 4 |-> 0],
      message     |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.packetSize = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.packetFlag = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.packetMilli = one] : one \in Sample(4) }
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

(* Every Start Of Spin Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStartOfSpinMessage ==
    \A message \in CheckedStartOfSpinMessage :
        LET read == DecodeStartOfSpinMessage(EncodeStartOfSpinMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Spin Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfSpinMessage ==
    \A message \in CheckedEndOfSpinMessage :
        LET read == DecodeEndOfSpinMessage(EncodeEndOfSpinMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trading Session Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingSessionMessage ==
    \A message \in CheckedTradingSessionMessage :
        LET read == DecodeTradingSessionMessage(EncodeTradingSessionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityMessage ==
    \A message \in CheckedSecurityMessage :
        LET read == DecodeSecurityMessage(EncodeSecurityMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Add Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderAddMessage ==
    \A message \in CheckedOrderAddMessage :
        LET read == DecodeOrderAddMessage(EncodeOrderAddMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderUpdateMessage ==
    \A message \in CheckedOrderUpdateMessage :
        LET read == DecodeOrderUpdateMessage(EncodeOrderUpdateMessage(message))
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

(* Every Order Execution Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutionMessage ==
    \A message \in CheckedOrderExecutionMessage :
        LET read == DecodeOrderExecutionMessage(EncodeOrderExecutionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Execution With Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutionWithPriceMessage ==
    \A message \in CheckedOrderExecutionWithPriceMessage :
        LET read == DecodeOrderExecutionWithPriceMessage(EncodeOrderExecutionWithPriceMessage(message))
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

(* Every Imbalance Message decodes back to what was encoded, and leaves nothing over *)
RoundTripImbalanceMessage ==
    \A message \in CheckedImbalanceMessage :
        LET read == DecodeImbalanceMessage(EncodeImbalanceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every System Recovery Event Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSystemRecoveryEventMessage ==
    \A message \in CheckedSystemRecoveryEventMessage :
        LET read == DecodeSystemRecoveryEventMessage(EncodeSystemRecoveryEventMessage(message))
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

(* Message Size is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
