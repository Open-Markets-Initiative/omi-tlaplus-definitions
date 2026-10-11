---------------- MODULE OnyxFutures_ExpressInterface_v1_0_c ----------------
(***************************************************************************)
(* Miami International Holdings Express Interface v1.0.c                   *)
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
(* Note: Order Instructions is a bit field set, checked as its 2 bytes     *)
(* rather than bit by bit.                                                 *)
(*                                                                         *)
(* Note: Self Trade Protection is a bit field set, checked as its 1 byte   *)
(* rather than bit by bit.                                                 *)
(*                                                                         *)
(* Note: Additional Order Indicators is a bit field set, checked as its 1  *)
(* byte rather than bit by bit.                                            *)
(*                                                                         *)
(* Note: Sequenced Data Packet fills what is left of the frame Sesm Packet *)
(* Length states, which is what it is read from.                           *)
(*                                                                         *)
(* Note: Unsequenced Data Packet fills what is left of the frame Sesm      *)
(* Packet Length states, which is what it is read from.                    *)
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
(* New Order Response Message: 56 bytes                                    *)
(***************************************************************************)

NewOrderResponseMessage ==
    [ matchingEngine       : Sample(8),
      mpId                 : Sample(5),
      clientOrderId        : Sample(20),
      instrumentIdBinaryU4 : Sample(4),
      orderId              : Sample(8),
      status               : Sample(1),
      reserved10           : Sample(10) ]

EncodeNewOrderResponseMessage(message) ==
    message.matchingEngine
        \o message.mpId
        \o message.clientOrderId
        \o message.instrumentIdBinaryU4
        \o message.orderId
        \o message.status
        \o message.reserved10

DecodeNewOrderResponseMessage(bytes) ==
    LET matchingEngine == ReadBytes(bytes, 8) IN IF ~matchingEngine.ok THEN Fail ELSE
    LET mpId == ReadBytes(matchingEngine.rest, 5) IN IF ~mpId.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(mpId.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET instrumentIdBinaryU4 == ReadBytes(clientOrderId.rest, 4) IN IF ~instrumentIdBinaryU4.ok THEN Fail ELSE
    LET orderId == ReadBytes(instrumentIdBinaryU4.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET status == ReadBytes(orderId.rest, 1) IN IF ~status.ok THEN Fail ELSE
    LET reserved10 == ReadBytes(status.rest, 10) IN IF ~reserved10.ok THEN Fail ELSE
    Ok([ matchingEngine       |-> matchingEngine.value,
         mpId                 |-> mpId.value,
         clientOrderId        |-> clientOrderId.value,
         instrumentIdBinaryU4 |-> instrumentIdBinaryU4.value,
         orderId              |-> orderId.value,
         status               |-> status.value,
         reserved10           |-> reserved10.value ], reserved10.rest)

ZeroNewOrderResponseMessage ==
    [ matchingEngine       |-> [i \in 1 .. 8 |-> 0],
      mpId                 |-> [i \in 1 .. 5 |-> 0],
      clientOrderId        |-> [i \in 1 .. 20 |-> 0],
      instrumentIdBinaryU4 |-> [i \in 1 .. 4 |-> 0],
      orderId              |-> [i \in 1 .. 8 |-> 0],
      status               |-> [i \in 1 .. 1 |-> 0],
      reserved10           |-> [i \in 1 .. 10 |-> 0] ]

(* New Order Response Message at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderResponseMessage ==
    { ZeroNewOrderResponseMessage }
        \cup { [ZeroNewOrderResponseMessage EXCEPT !.matchingEngine = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderResponseMessage EXCEPT !.mpId = one] : one \in Sample(5) }
        \cup { [ZeroNewOrderResponseMessage EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderResponseMessage EXCEPT !.instrumentIdBinaryU4 = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderResponseMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderResponseMessage EXCEPT !.status = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderResponseMessage EXCEPT !.reserved10 = one] : one \in Sample(10) }

(***************************************************************************)
(* Modify Order Response: 80 bytes                                         *)
(***************************************************************************)

ModifyOrderResponse ==
    [ matchingEngineTime    : Sample(8),
      mpId                  : Sample(5),
      clientOrderId         : Sample(20),
      originalClientOrderId : Sample(20),
      instrumentIdBinaryU4  : Sample(4),
      orderId               : Sample(8),
      leavesQty             : Sample(4),
      status                : Sample(1),
      reserved10            : Sample(10) ]

EncodeModifyOrderResponse(message) ==
    message.matchingEngineTime
        \o message.mpId
        \o message.clientOrderId
        \o message.originalClientOrderId
        \o message.instrumentIdBinaryU4
        \o message.orderId
        \o message.leavesQty
        \o message.status
        \o message.reserved10

DecodeModifyOrderResponse(bytes) ==
    LET matchingEngineTime == ReadBytes(bytes, 8) IN IF ~matchingEngineTime.ok THEN Fail ELSE
    LET mpId == ReadBytes(matchingEngineTime.rest, 5) IN IF ~mpId.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(mpId.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET originalClientOrderId == ReadBytes(clientOrderId.rest, 20) IN IF ~originalClientOrderId.ok THEN Fail ELSE
    LET instrumentIdBinaryU4 == ReadBytes(originalClientOrderId.rest, 4) IN IF ~instrumentIdBinaryU4.ok THEN Fail ELSE
    LET orderId == ReadBytes(instrumentIdBinaryU4.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(orderId.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET status == ReadBytes(leavesQty.rest, 1) IN IF ~status.ok THEN Fail ELSE
    LET reserved10 == ReadBytes(status.rest, 10) IN IF ~reserved10.ok THEN Fail ELSE
    Ok([ matchingEngineTime    |-> matchingEngineTime.value,
         mpId                  |-> mpId.value,
         clientOrderId         |-> clientOrderId.value,
         originalClientOrderId |-> originalClientOrderId.value,
         instrumentIdBinaryU4  |-> instrumentIdBinaryU4.value,
         orderId               |-> orderId.value,
         leavesQty             |-> leavesQty.value,
         status                |-> status.value,
         reserved10            |-> reserved10.value ], reserved10.rest)

ZeroModifyOrderResponse ==
    [ matchingEngineTime    |-> [i \in 1 .. 8 |-> 0],
      mpId                  |-> [i \in 1 .. 5 |-> 0],
      clientOrderId         |-> [i \in 1 .. 20 |-> 0],
      originalClientOrderId |-> [i \in 1 .. 20 |-> 0],
      instrumentIdBinaryU4  |-> [i \in 1 .. 4 |-> 0],
      orderId               |-> [i \in 1 .. 8 |-> 0],
      leavesQty             |-> [i \in 1 .. 4 |-> 0],
      status                |-> [i \in 1 .. 1 |-> 0],
      reserved10            |-> [i \in 1 .. 10 |-> 0] ]

(* Modify Order Response at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderResponse ==
    { ZeroModifyOrderResponse }
        \cup { [ZeroModifyOrderResponse EXCEPT !.matchingEngineTime = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.mpId = one] : one \in Sample(5) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.originalClientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.instrumentIdBinaryU4 = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.status = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.reserved10 = one] : one \in Sample(10) }

(***************************************************************************)
(* Cancel Order Response: 66 bytes                                         *)
(***************************************************************************)

CancelOrderResponse ==
    [ matchingEngineTime   : Sample(8),
      mpId                 : Sample(5),
      clientOrderId        : Sample(20),
      originalClientOrder  : Sample(20),
      instrumentIdBinaryU4 : Sample(4),
      orderId              : Sample(8),
      status               : Sample(1) ]

EncodeCancelOrderResponse(message) ==
    message.matchingEngineTime
        \o message.mpId
        \o message.clientOrderId
        \o message.originalClientOrder
        \o message.instrumentIdBinaryU4
        \o message.orderId
        \o message.status

DecodeCancelOrderResponse(bytes) ==
    LET matchingEngineTime == ReadBytes(bytes, 8) IN IF ~matchingEngineTime.ok THEN Fail ELSE
    LET mpId == ReadBytes(matchingEngineTime.rest, 5) IN IF ~mpId.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(mpId.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET originalClientOrder == ReadBytes(clientOrderId.rest, 20) IN IF ~originalClientOrder.ok THEN Fail ELSE
    LET instrumentIdBinaryU4 == ReadBytes(originalClientOrder.rest, 4) IN IF ~instrumentIdBinaryU4.ok THEN Fail ELSE
    LET orderId == ReadBytes(instrumentIdBinaryU4.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET status == ReadBytes(orderId.rest, 1) IN IF ~status.ok THEN Fail ELSE
    Ok([ matchingEngineTime   |-> matchingEngineTime.value,
         mpId                 |-> mpId.value,
         clientOrderId        |-> clientOrderId.value,
         originalClientOrder  |-> originalClientOrder.value,
         instrumentIdBinaryU4 |-> instrumentIdBinaryU4.value,
         orderId              |-> orderId.value,
         status               |-> status.value ], status.rest)

ZeroCancelOrderResponse ==
    [ matchingEngineTime   |-> [i \in 1 .. 8 |-> 0],
      mpId                 |-> [i \in 1 .. 5 |-> 0],
      clientOrderId        |-> [i \in 1 .. 20 |-> 0],
      originalClientOrder  |-> [i \in 1 .. 20 |-> 0],
      instrumentIdBinaryU4 |-> [i \in 1 .. 4 |-> 0],
      orderId              |-> [i \in 1 .. 8 |-> 0],
      status               |-> [i \in 1 .. 1 |-> 0] ]

(* Cancel Order Response at zero, then each field in turn at the values it is checked at *)
CheckedCancelOrderResponse ==
    { ZeroCancelOrderResponse }
        \cup { [ZeroCancelOrderResponse EXCEPT !.matchingEngineTime = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrderResponse EXCEPT !.mpId = one] : one \in Sample(5) }
        \cup { [ZeroCancelOrderResponse EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroCancelOrderResponse EXCEPT !.originalClientOrder = one] : one \in Sample(20) }
        \cup { [ZeroCancelOrderResponse EXCEPT !.instrumentIdBinaryU4 = one] : one \in Sample(4) }
        \cup { [ZeroCancelOrderResponse EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrderResponse EXCEPT !.status = one] : one \in Sample(1) }

(***************************************************************************)
(* Mass Cancel Response: 44 bytes                                          *)
(***************************************************************************)

MassCancelResponse ==
    [ matchingEngineTime : Sample(8),
      mpId               : Sample(5),
      clientOrderId      : Sample(20),
      status             : Sample(1),
      reserved10         : Sample(10) ]

EncodeMassCancelResponse(message) ==
    message.matchingEngineTime
        \o message.mpId
        \o message.clientOrderId
        \o message.status
        \o message.reserved10

DecodeMassCancelResponse(bytes) ==
    LET matchingEngineTime == ReadBytes(bytes, 8) IN IF ~matchingEngineTime.ok THEN Fail ELSE
    LET mpId == ReadBytes(matchingEngineTime.rest, 5) IN IF ~mpId.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(mpId.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET status == ReadBytes(clientOrderId.rest, 1) IN IF ~status.ok THEN Fail ELSE
    LET reserved10 == ReadBytes(status.rest, 10) IN IF ~reserved10.ok THEN Fail ELSE
    Ok([ matchingEngineTime |-> matchingEngineTime.value,
         mpId               |-> mpId.value,
         clientOrderId      |-> clientOrderId.value,
         status             |-> status.value,
         reserved10         |-> reserved10.value ], reserved10.rest)

ZeroMassCancelResponse ==
    [ matchingEngineTime |-> [i \in 1 .. 8 |-> 0],
      mpId               |-> [i \in 1 .. 5 |-> 0],
      clientOrderId      |-> [i \in 1 .. 20 |-> 0],
      status             |-> [i \in 1 .. 1 |-> 0],
      reserved10         |-> [i \in 1 .. 10 |-> 0] ]

(* Mass Cancel Response at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelResponse ==
    { ZeroMassCancelResponse }
        \cup { [ZeroMassCancelResponse EXCEPT !.matchingEngineTime = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelResponse EXCEPT !.mpId = one] : one \in Sample(5) }
        \cup { [ZeroMassCancelResponse EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroMassCancelResponse EXCEPT !.status = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelResponse EXCEPT !.reserved10 = one] : one \in Sample(10) }

(***************************************************************************)
(* Strategy Creation Response Message: 70 bytes                            *)
(***************************************************************************)

StrategyCreationResponseMessage ==
    [ matchingEngineTime   : Sample(8),
      mpId                 : Sample(5),
      clientOrderId        : Sample(20),
      instrumentIdString20 : Sample(20),
      status               : Sample(1),
      reserved16           : Sample(16) ]

EncodeStrategyCreationResponseMessage(message) ==
    message.matchingEngineTime
        \o message.mpId
        \o message.clientOrderId
        \o message.instrumentIdString20
        \o message.status
        \o message.reserved16

DecodeStrategyCreationResponseMessage(bytes) ==
    LET matchingEngineTime == ReadBytes(bytes, 8) IN IF ~matchingEngineTime.ok THEN Fail ELSE
    LET mpId == ReadBytes(matchingEngineTime.rest, 5) IN IF ~mpId.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(mpId.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET instrumentIdString20 == ReadBytes(clientOrderId.rest, 20) IN IF ~instrumentIdString20.ok THEN Fail ELSE
    LET status == ReadBytes(instrumentIdString20.rest, 1) IN IF ~status.ok THEN Fail ELSE
    LET reserved16 == ReadBytes(status.rest, 16) IN IF ~reserved16.ok THEN Fail ELSE
    Ok([ matchingEngineTime   |-> matchingEngineTime.value,
         mpId                 |-> mpId.value,
         clientOrderId        |-> clientOrderId.value,
         instrumentIdString20 |-> instrumentIdString20.value,
         status               |-> status.value,
         reserved16           |-> reserved16.value ], reserved16.rest)

ZeroStrategyCreationResponseMessage ==
    [ matchingEngineTime   |-> [i \in 1 .. 8 |-> 0],
      mpId                 |-> [i \in 1 .. 5 |-> 0],
      clientOrderId        |-> [i \in 1 .. 20 |-> 0],
      instrumentIdString20 |-> [i \in 1 .. 20 |-> 0],
      status               |-> [i \in 1 .. 1 |-> 0],
      reserved16           |-> [i \in 1 .. 16 |-> 0] ]

(* Strategy Creation Response Message at zero, then each field in turn at the values it is checked at *)
CheckedStrategyCreationResponseMessage ==
    { ZeroStrategyCreationResponseMessage }
        \cup { [ZeroStrategyCreationResponseMessage EXCEPT !.matchingEngineTime = one] : one \in Sample(8) }
        \cup { [ZeroStrategyCreationResponseMessage EXCEPT !.mpId = one] : one \in Sample(5) }
        \cup { [ZeroStrategyCreationResponseMessage EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroStrategyCreationResponseMessage EXCEPT !.instrumentIdString20 = one] : one \in Sample(20) }
        \cup { [ZeroStrategyCreationResponseMessage EXCEPT !.status = one] : one \in Sample(1) }
        \cup { [ZeroStrategyCreationResponseMessage EXCEPT !.reserved16 = one] : one \in Sample(16) }

(***************************************************************************)
(* System State Notification Message: 26 bytes                             *)
(***************************************************************************)

SystemStateNotificationMessage ==
    [ matchingEngineTime : Sample(8),
      version            : Sample(8),
      sessionId          : Sample(1),
      systemStatus       : Sample(1),
      reserved8          : Sample(8) ]

EncodeSystemStateNotificationMessage(message) ==
    message.matchingEngineTime
        \o message.version
        \o message.sessionId
        \o message.systemStatus
        \o message.reserved8

DecodeSystemStateNotificationMessage(bytes) ==
    LET matchingEngineTime == ReadBytes(bytes, 8) IN IF ~matchingEngineTime.ok THEN Fail ELSE
    LET version == ReadBytes(matchingEngineTime.rest, 8) IN IF ~version.ok THEN Fail ELSE
    LET sessionId == ReadBytes(version.rest, 1) IN IF ~sessionId.ok THEN Fail ELSE
    LET systemStatus == ReadBytes(sessionId.rest, 1) IN IF ~systemStatus.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(systemStatus.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    Ok([ matchingEngineTime |-> matchingEngineTime.value,
         version            |-> version.value,
         sessionId          |-> sessionId.value,
         systemStatus       |-> systemStatus.value,
         reserved8          |-> reserved8.value ], reserved8.rest)

ZeroSystemStateNotificationMessage ==
    [ matchingEngineTime |-> [i \in 1 .. 8 |-> 0],
      version            |-> [i \in 1 .. 8 |-> 0],
      sessionId          |-> [i \in 1 .. 1 |-> 0],
      systemStatus       |-> [i \in 1 .. 1 |-> 0],
      reserved8          |-> [i \in 1 .. 8 |-> 0] ]

(* System State Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemStateNotificationMessage ==
    { ZeroSystemStateNotificationMessage }
        \cup { [ZeroSystemStateNotificationMessage EXCEPT !.matchingEngineTime = one] : one \in Sample(8) }
        \cup { [ZeroSystemStateNotificationMessage EXCEPT !.version = one] : one \in Sample(8) }
        \cup { [ZeroSystemStateNotificationMessage EXCEPT !.sessionId = one] : one \in Sample(1) }
        \cup { [ZeroSystemStateNotificationMessage EXCEPT !.systemStatus = one] : one \in Sample(1) }
        \cup { [ZeroSystemStateNotificationMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }

(***************************************************************************)
(* New Order Notification: 190 bytes                                       *)
(***************************************************************************)

NewOrderNotification ==
    [ matchingEngineTime               : Sample(8),
      mpId                             : Sample(5),
      orderId                          : Sample(8),
      clientSendTime                   : Sample(8),
      operatorId                       : Sample(18),
      operatorLocation                 : Sample(6),
      account                          : Sample(16),
      clientOrderId                    : Sample(20),
      instrumentIdBinaryU4             : Sample(4),
      price                            : Sample(8),
      stopOrderTriggerPrice            : Sample(8),
      sizeBinaryU4                     : Sample(4),
      orderInstructions                : Sample(2),
      timeInForce                      : Sample(1),
      orderType                        : Sample(1),
      selfTradeProtection              : Sample(1),
      selfTradeProtectionGroup         : Sample(2),
      purgeGroup                       : Sample(1),
      customerOrderHandlingInstruction : Sample(1),
      additionalOrderIndicators        : Sample(1),
      minQty                           : Sample(4),
      orderExpiryDate                  : Sample(2),
      tradingCollarDollarValue         : Sample(8),
      ctiCode                          : Sample(1),
      textMemo                         : Sample(20),
      reserved32                       : Sample(32) ]

EncodeNewOrderNotification(message) ==
    message.matchingEngineTime
        \o message.mpId
        \o message.orderId
        \o message.clientSendTime
        \o message.operatorId
        \o message.operatorLocation
        \o message.account
        \o message.clientOrderId
        \o message.instrumentIdBinaryU4
        \o message.price
        \o message.stopOrderTriggerPrice
        \o message.sizeBinaryU4
        \o message.orderInstructions
        \o message.timeInForce
        \o message.orderType
        \o message.selfTradeProtection
        \o message.selfTradeProtectionGroup
        \o message.purgeGroup
        \o message.customerOrderHandlingInstruction
        \o message.additionalOrderIndicators
        \o message.minQty
        \o message.orderExpiryDate
        \o message.tradingCollarDollarValue
        \o message.ctiCode
        \o message.textMemo
        \o message.reserved32

DecodeNewOrderNotification(bytes) ==
    LET matchingEngineTime == ReadBytes(bytes, 8) IN IF ~matchingEngineTime.ok THEN Fail ELSE
    LET mpId == ReadBytes(matchingEngineTime.rest, 5) IN IF ~mpId.ok THEN Fail ELSE
    LET orderId == ReadBytes(mpId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clientSendTime == ReadBytes(orderId.rest, 8) IN IF ~clientSendTime.ok THEN Fail ELSE
    LET operatorId == ReadBytes(clientSendTime.rest, 18) IN IF ~operatorId.ok THEN Fail ELSE
    LET operatorLocation == ReadBytes(operatorId.rest, 6) IN IF ~operatorLocation.ok THEN Fail ELSE
    LET account == ReadBytes(operatorLocation.rest, 16) IN IF ~account.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(account.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET instrumentIdBinaryU4 == ReadBytes(clientOrderId.rest, 4) IN IF ~instrumentIdBinaryU4.ok THEN Fail ELSE
    LET price == ReadBytes(instrumentIdBinaryU4.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET stopOrderTriggerPrice == ReadBytes(price.rest, 8) IN IF ~stopOrderTriggerPrice.ok THEN Fail ELSE
    LET sizeBinaryU4 == ReadBytes(stopOrderTriggerPrice.rest, 4) IN IF ~sizeBinaryU4.ok THEN Fail ELSE
    LET orderInstructions == ReadBytes(sizeBinaryU4.rest, 2) IN IF ~orderInstructions.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(orderInstructions.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET orderType == ReadBytes(timeInForce.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET selfTradeProtection == ReadBytes(orderType.rest, 1) IN IF ~selfTradeProtection.ok THEN Fail ELSE
    LET selfTradeProtectionGroup == ReadBytes(selfTradeProtection.rest, 2) IN IF ~selfTradeProtectionGroup.ok THEN Fail ELSE
    LET purgeGroup == ReadBytes(selfTradeProtectionGroup.rest, 1) IN IF ~purgeGroup.ok THEN Fail ELSE
    LET customerOrderHandlingInstruction == ReadBytes(purgeGroup.rest, 1) IN IF ~customerOrderHandlingInstruction.ok THEN Fail ELSE
    LET additionalOrderIndicators == ReadBytes(customerOrderHandlingInstruction.rest, 1) IN IF ~additionalOrderIndicators.ok THEN Fail ELSE
    LET minQty == ReadBytes(additionalOrderIndicators.rest, 4) IN IF ~minQty.ok THEN Fail ELSE
    LET orderExpiryDate == ReadBytes(minQty.rest, 2) IN IF ~orderExpiryDate.ok THEN Fail ELSE
    LET tradingCollarDollarValue == ReadBytes(orderExpiryDate.rest, 8) IN IF ~tradingCollarDollarValue.ok THEN Fail ELSE
    LET ctiCode == ReadBytes(tradingCollarDollarValue.rest, 1) IN IF ~ctiCode.ok THEN Fail ELSE
    LET textMemo == ReadBytes(ctiCode.rest, 20) IN IF ~textMemo.ok THEN Fail ELSE
    LET reserved32 == ReadBytes(textMemo.rest, 32) IN IF ~reserved32.ok THEN Fail ELSE
    Ok([ matchingEngineTime               |-> matchingEngineTime.value,
         mpId                             |-> mpId.value,
         orderId                          |-> orderId.value,
         clientSendTime                   |-> clientSendTime.value,
         operatorId                       |-> operatorId.value,
         operatorLocation                 |-> operatorLocation.value,
         account                          |-> account.value,
         clientOrderId                    |-> clientOrderId.value,
         instrumentIdBinaryU4             |-> instrumentIdBinaryU4.value,
         price                            |-> price.value,
         stopOrderTriggerPrice            |-> stopOrderTriggerPrice.value,
         sizeBinaryU4                     |-> sizeBinaryU4.value,
         orderInstructions                |-> orderInstructions.value,
         timeInForce                      |-> timeInForce.value,
         orderType                        |-> orderType.value,
         selfTradeProtection              |-> selfTradeProtection.value,
         selfTradeProtectionGroup         |-> selfTradeProtectionGroup.value,
         purgeGroup                       |-> purgeGroup.value,
         customerOrderHandlingInstruction |-> customerOrderHandlingInstruction.value,
         additionalOrderIndicators        |-> additionalOrderIndicators.value,
         minQty                           |-> minQty.value,
         orderExpiryDate                  |-> orderExpiryDate.value,
         tradingCollarDollarValue         |-> tradingCollarDollarValue.value,
         ctiCode                          |-> ctiCode.value,
         textMemo                         |-> textMemo.value,
         reserved32                       |-> reserved32.value ], reserved32.rest)

ZeroNewOrderNotification ==
    [ matchingEngineTime               |-> [i \in 1 .. 8 |-> 0],
      mpId                             |-> [i \in 1 .. 5 |-> 0],
      orderId                          |-> [i \in 1 .. 8 |-> 0],
      clientSendTime                   |-> [i \in 1 .. 8 |-> 0],
      operatorId                       |-> [i \in 1 .. 18 |-> 0],
      operatorLocation                 |-> [i \in 1 .. 6 |-> 0],
      account                          |-> [i \in 1 .. 16 |-> 0],
      clientOrderId                    |-> [i \in 1 .. 20 |-> 0],
      instrumentIdBinaryU4             |-> [i \in 1 .. 4 |-> 0],
      price                            |-> [i \in 1 .. 8 |-> 0],
      stopOrderTriggerPrice            |-> [i \in 1 .. 8 |-> 0],
      sizeBinaryU4                     |-> [i \in 1 .. 4 |-> 0],
      orderInstructions                |-> [i \in 1 .. 2 |-> 0],
      timeInForce                      |-> [i \in 1 .. 1 |-> 0],
      orderType                        |-> [i \in 1 .. 1 |-> 0],
      selfTradeProtection              |-> [i \in 1 .. 1 |-> 0],
      selfTradeProtectionGroup         |-> [i \in 1 .. 2 |-> 0],
      purgeGroup                       |-> [i \in 1 .. 1 |-> 0],
      customerOrderHandlingInstruction |-> [i \in 1 .. 1 |-> 0],
      additionalOrderIndicators        |-> [i \in 1 .. 1 |-> 0],
      minQty                           |-> [i \in 1 .. 4 |-> 0],
      orderExpiryDate                  |-> [i \in 1 .. 2 |-> 0],
      tradingCollarDollarValue         |-> [i \in 1 .. 8 |-> 0],
      ctiCode                          |-> [i \in 1 .. 1 |-> 0],
      textMemo                         |-> [i \in 1 .. 20 |-> 0],
      reserved32                       |-> [i \in 1 .. 32 |-> 0] ]

(* New Order Notification at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderNotification ==
    { ZeroNewOrderNotification }
        \cup { [ZeroNewOrderNotification EXCEPT !.matchingEngineTime = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderNotification EXCEPT !.mpId = one] : one \in Sample(5) }
        \cup { [ZeroNewOrderNotification EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderNotification EXCEPT !.clientSendTime = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderNotification EXCEPT !.operatorId = one] : one \in Sample(18) }
        \cup { [ZeroNewOrderNotification EXCEPT !.operatorLocation = one] : one \in Sample(6) }
        \cup { [ZeroNewOrderNotification EXCEPT !.account = one] : one \in Sample(16) }
        \cup { [ZeroNewOrderNotification EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderNotification EXCEPT !.instrumentIdBinaryU4 = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderNotification EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderNotification EXCEPT !.stopOrderTriggerPrice = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderNotification EXCEPT !.sizeBinaryU4 = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderNotification EXCEPT !.orderInstructions = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderNotification EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderNotification EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderNotification EXCEPT !.selfTradeProtection = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderNotification EXCEPT !.selfTradeProtectionGroup = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderNotification EXCEPT !.purgeGroup = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderNotification EXCEPT !.customerOrderHandlingInstruction = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderNotification EXCEPT !.additionalOrderIndicators = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderNotification EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderNotification EXCEPT !.orderExpiryDate = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderNotification EXCEPT !.tradingCollarDollarValue = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderNotification EXCEPT !.ctiCode = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderNotification EXCEPT !.textMemo = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderNotification EXCEPT !.reserved32 = one] : one \in Sample(32) }

(***************************************************************************)
(* Modify Order Notification: 160 bytes                                    *)
(***************************************************************************)

ModifyOrderNotification ==
    [ matchingEngineTime               : Sample(8),
      mpId                             : Sample(5),
      orderId                          : Sample(8),
      clientSendTime                   : Sample(8),
      leavesQty                        : Sample(4),
      operatorId                       : Sample(18),
      operatorLocation                 : Sample(6),
      clientOrderId                    : Sample(20),
      originalClientOrderId            : Sample(20),
      instrumentIdBinaryU4             : Sample(4),
      price                            : Sample(8),
      stopOrderTriggerPrice            : Sample(8),
      sizeBinaryS4                     : Sample(4),
      orderExpiryDate                  : Sample(2),
      selfTradeProtectionGroup         : Sample(2),
      purgeGroup                       : Sample(1),
      customerOrderHandlingInstruction : Sample(1),
      additionalOrderIndicators        : Sample(1),
      reserved32                       : Sample(32) ]

EncodeModifyOrderNotification(message) ==
    message.matchingEngineTime
        \o message.mpId
        \o message.orderId
        \o message.clientSendTime
        \o message.leavesQty
        \o message.operatorId
        \o message.operatorLocation
        \o message.clientOrderId
        \o message.originalClientOrderId
        \o message.instrumentIdBinaryU4
        \o message.price
        \o message.stopOrderTriggerPrice
        \o message.sizeBinaryS4
        \o message.orderExpiryDate
        \o message.selfTradeProtectionGroup
        \o message.purgeGroup
        \o message.customerOrderHandlingInstruction
        \o message.additionalOrderIndicators
        \o message.reserved32

DecodeModifyOrderNotification(bytes) ==
    LET matchingEngineTime == ReadBytes(bytes, 8) IN IF ~matchingEngineTime.ok THEN Fail ELSE
    LET mpId == ReadBytes(matchingEngineTime.rest, 5) IN IF ~mpId.ok THEN Fail ELSE
    LET orderId == ReadBytes(mpId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clientSendTime == ReadBytes(orderId.rest, 8) IN IF ~clientSendTime.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(clientSendTime.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET operatorId == ReadBytes(leavesQty.rest, 18) IN IF ~operatorId.ok THEN Fail ELSE
    LET operatorLocation == ReadBytes(operatorId.rest, 6) IN IF ~operatorLocation.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(operatorLocation.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET originalClientOrderId == ReadBytes(clientOrderId.rest, 20) IN IF ~originalClientOrderId.ok THEN Fail ELSE
    LET instrumentIdBinaryU4 == ReadBytes(originalClientOrderId.rest, 4) IN IF ~instrumentIdBinaryU4.ok THEN Fail ELSE
    LET price == ReadBytes(instrumentIdBinaryU4.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET stopOrderTriggerPrice == ReadBytes(price.rest, 8) IN IF ~stopOrderTriggerPrice.ok THEN Fail ELSE
    LET sizeBinaryS4 == ReadBytes(stopOrderTriggerPrice.rest, 4) IN IF ~sizeBinaryS4.ok THEN Fail ELSE
    LET orderExpiryDate == ReadBytes(sizeBinaryS4.rest, 2) IN IF ~orderExpiryDate.ok THEN Fail ELSE
    LET selfTradeProtectionGroup == ReadBytes(orderExpiryDate.rest, 2) IN IF ~selfTradeProtectionGroup.ok THEN Fail ELSE
    LET purgeGroup == ReadBytes(selfTradeProtectionGroup.rest, 1) IN IF ~purgeGroup.ok THEN Fail ELSE
    LET customerOrderHandlingInstruction == ReadBytes(purgeGroup.rest, 1) IN IF ~customerOrderHandlingInstruction.ok THEN Fail ELSE
    LET additionalOrderIndicators == ReadBytes(customerOrderHandlingInstruction.rest, 1) IN IF ~additionalOrderIndicators.ok THEN Fail ELSE
    LET reserved32 == ReadBytes(additionalOrderIndicators.rest, 32) IN IF ~reserved32.ok THEN Fail ELSE
    Ok([ matchingEngineTime               |-> matchingEngineTime.value,
         mpId                             |-> mpId.value,
         orderId                          |-> orderId.value,
         clientSendTime                   |-> clientSendTime.value,
         leavesQty                        |-> leavesQty.value,
         operatorId                       |-> operatorId.value,
         operatorLocation                 |-> operatorLocation.value,
         clientOrderId                    |-> clientOrderId.value,
         originalClientOrderId            |-> originalClientOrderId.value,
         instrumentIdBinaryU4             |-> instrumentIdBinaryU4.value,
         price                            |-> price.value,
         stopOrderTriggerPrice            |-> stopOrderTriggerPrice.value,
         sizeBinaryS4                     |-> sizeBinaryS4.value,
         orderExpiryDate                  |-> orderExpiryDate.value,
         selfTradeProtectionGroup         |-> selfTradeProtectionGroup.value,
         purgeGroup                       |-> purgeGroup.value,
         customerOrderHandlingInstruction |-> customerOrderHandlingInstruction.value,
         additionalOrderIndicators        |-> additionalOrderIndicators.value,
         reserved32                       |-> reserved32.value ], reserved32.rest)

ZeroModifyOrderNotification ==
    [ matchingEngineTime               |-> [i \in 1 .. 8 |-> 0],
      mpId                             |-> [i \in 1 .. 5 |-> 0],
      orderId                          |-> [i \in 1 .. 8 |-> 0],
      clientSendTime                   |-> [i \in 1 .. 8 |-> 0],
      leavesQty                        |-> [i \in 1 .. 4 |-> 0],
      operatorId                       |-> [i \in 1 .. 18 |-> 0],
      operatorLocation                 |-> [i \in 1 .. 6 |-> 0],
      clientOrderId                    |-> [i \in 1 .. 20 |-> 0],
      originalClientOrderId            |-> [i \in 1 .. 20 |-> 0],
      instrumentIdBinaryU4             |-> [i \in 1 .. 4 |-> 0],
      price                            |-> [i \in 1 .. 8 |-> 0],
      stopOrderTriggerPrice            |-> [i \in 1 .. 8 |-> 0],
      sizeBinaryS4                     |-> [i \in 1 .. 4 |-> 0],
      orderExpiryDate                  |-> [i \in 1 .. 2 |-> 0],
      selfTradeProtectionGroup         |-> [i \in 1 .. 2 |-> 0],
      purgeGroup                       |-> [i \in 1 .. 1 |-> 0],
      customerOrderHandlingInstruction |-> [i \in 1 .. 1 |-> 0],
      additionalOrderIndicators        |-> [i \in 1 .. 1 |-> 0],
      reserved32                       |-> [i \in 1 .. 32 |-> 0] ]

(* Modify Order Notification at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderNotification ==
    { ZeroModifyOrderNotification }
        \cup { [ZeroModifyOrderNotification EXCEPT !.matchingEngineTime = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderNotification EXCEPT !.mpId = one] : one \in Sample(5) }
        \cup { [ZeroModifyOrderNotification EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderNotification EXCEPT !.clientSendTime = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderNotification EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderNotification EXCEPT !.operatorId = one] : one \in Sample(18) }
        \cup { [ZeroModifyOrderNotification EXCEPT !.operatorLocation = one] : one \in Sample(6) }
        \cup { [ZeroModifyOrderNotification EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroModifyOrderNotification EXCEPT !.originalClientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroModifyOrderNotification EXCEPT !.instrumentIdBinaryU4 = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderNotification EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderNotification EXCEPT !.stopOrderTriggerPrice = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderNotification EXCEPT !.sizeBinaryS4 = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderNotification EXCEPT !.orderExpiryDate = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderNotification EXCEPT !.selfTradeProtectionGroup = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderNotification EXCEPT !.purgeGroup = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderNotification EXCEPT !.customerOrderHandlingInstruction = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderNotification EXCEPT !.additionalOrderIndicators = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderNotification EXCEPT !.reserved32 = one] : one \in Sample(32) }

(***************************************************************************)
(* Cancel Reduce Size Order Notification: 102 bytes                        *)
(***************************************************************************)

CancelReduceSizeOrderNotification ==
    [ matchingEngineTime   : Sample(8),
      mpId                 : Sample(5),
      operatorId           : Sample(18),
      operatorLocation     : Sample(6),
      clientOrderId        : Sample(20),
      instrumentIdBinaryU4 : Sample(4),
      orderId              : Sample(8),
      clientSendTime       : Sample(8),
      leavesQty            : Sample(4),
      cancelReason         : Sample(1),
      lastPrice            : Sample(8),
      lastSize             : Sample(4),
      reserved8            : Sample(8) ]

EncodeCancelReduceSizeOrderNotification(message) ==
    message.matchingEngineTime
        \o message.mpId
        \o message.operatorId
        \o message.operatorLocation
        \o message.clientOrderId
        \o message.instrumentIdBinaryU4
        \o message.orderId
        \o message.clientSendTime
        \o message.leavesQty
        \o message.cancelReason
        \o message.lastPrice
        \o message.lastSize
        \o message.reserved8

DecodeCancelReduceSizeOrderNotification(bytes) ==
    LET matchingEngineTime == ReadBytes(bytes, 8) IN IF ~matchingEngineTime.ok THEN Fail ELSE
    LET mpId == ReadBytes(matchingEngineTime.rest, 5) IN IF ~mpId.ok THEN Fail ELSE
    LET operatorId == ReadBytes(mpId.rest, 18) IN IF ~operatorId.ok THEN Fail ELSE
    LET operatorLocation == ReadBytes(operatorId.rest, 6) IN IF ~operatorLocation.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(operatorLocation.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET instrumentIdBinaryU4 == ReadBytes(clientOrderId.rest, 4) IN IF ~instrumentIdBinaryU4.ok THEN Fail ELSE
    LET orderId == ReadBytes(instrumentIdBinaryU4.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clientSendTime == ReadBytes(orderId.rest, 8) IN IF ~clientSendTime.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(clientSendTime.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cancelReason == ReadBytes(leavesQty.rest, 1) IN IF ~cancelReason.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(cancelReason.rest, 8) IN IF ~lastPrice.ok THEN Fail ELSE
    LET lastSize == ReadBytes(lastPrice.rest, 4) IN IF ~lastSize.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(lastSize.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    Ok([ matchingEngineTime   |-> matchingEngineTime.value,
         mpId                 |-> mpId.value,
         operatorId           |-> operatorId.value,
         operatorLocation     |-> operatorLocation.value,
         clientOrderId        |-> clientOrderId.value,
         instrumentIdBinaryU4 |-> instrumentIdBinaryU4.value,
         orderId              |-> orderId.value,
         clientSendTime       |-> clientSendTime.value,
         leavesQty            |-> leavesQty.value,
         cancelReason         |-> cancelReason.value,
         lastPrice            |-> lastPrice.value,
         lastSize             |-> lastSize.value,
         reserved8            |-> reserved8.value ], reserved8.rest)

ZeroCancelReduceSizeOrderNotification ==
    [ matchingEngineTime   |-> [i \in 1 .. 8 |-> 0],
      mpId                 |-> [i \in 1 .. 5 |-> 0],
      operatorId           |-> [i \in 1 .. 18 |-> 0],
      operatorLocation     |-> [i \in 1 .. 6 |-> 0],
      clientOrderId        |-> [i \in 1 .. 20 |-> 0],
      instrumentIdBinaryU4 |-> [i \in 1 .. 4 |-> 0],
      orderId              |-> [i \in 1 .. 8 |-> 0],
      clientSendTime       |-> [i \in 1 .. 8 |-> 0],
      leavesQty            |-> [i \in 1 .. 4 |-> 0],
      cancelReason         |-> [i \in 1 .. 1 |-> 0],
      lastPrice            |-> [i \in 1 .. 8 |-> 0],
      lastSize             |-> [i \in 1 .. 4 |-> 0],
      reserved8            |-> [i \in 1 .. 8 |-> 0] ]

(* Cancel Reduce Size Order Notification at zero, then each field in turn at the values it is checked at *)
CheckedCancelReduceSizeOrderNotification ==
    { ZeroCancelReduceSizeOrderNotification }
        \cup { [ZeroCancelReduceSizeOrderNotification EXCEPT !.matchingEngineTime = one] : one \in Sample(8) }
        \cup { [ZeroCancelReduceSizeOrderNotification EXCEPT !.mpId = one] : one \in Sample(5) }
        \cup { [ZeroCancelReduceSizeOrderNotification EXCEPT !.operatorId = one] : one \in Sample(18) }
        \cup { [ZeroCancelReduceSizeOrderNotification EXCEPT !.operatorLocation = one] : one \in Sample(6) }
        \cup { [ZeroCancelReduceSizeOrderNotification EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroCancelReduceSizeOrderNotification EXCEPT !.instrumentIdBinaryU4 = one] : one \in Sample(4) }
        \cup { [ZeroCancelReduceSizeOrderNotification EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroCancelReduceSizeOrderNotification EXCEPT !.clientSendTime = one] : one \in Sample(8) }
        \cup { [ZeroCancelReduceSizeOrderNotification EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroCancelReduceSizeOrderNotification EXCEPT !.cancelReason = one] : one \in Sample(1) }
        \cup { [ZeroCancelReduceSizeOrderNotification EXCEPT !.lastPrice = one] : one \in Sample(8) }
        \cup { [ZeroCancelReduceSizeOrderNotification EXCEPT !.lastSize = one] : one \in Sample(4) }
        \cup { [ZeroCancelReduceSizeOrderNotification EXCEPT !.reserved8 = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Status Update Notification: 53 bytes                              *)
(***************************************************************************)

OrderStatusUpdateNotification ==
    [ matchingEngineTime   : Sample(8),
      instrumentIdBinaryU4 : Sample(4),
      orderId              : Sample(8),
      updateStatus         : Sample(1),
      reserved32           : Sample(32) ]

EncodeOrderStatusUpdateNotification(message) ==
    message.matchingEngineTime
        \o message.instrumentIdBinaryU4
        \o message.orderId
        \o message.updateStatus
        \o message.reserved32

DecodeOrderStatusUpdateNotification(bytes) ==
    LET matchingEngineTime == ReadBytes(bytes, 8) IN IF ~matchingEngineTime.ok THEN Fail ELSE
    LET instrumentIdBinaryU4 == ReadBytes(matchingEngineTime.rest, 4) IN IF ~instrumentIdBinaryU4.ok THEN Fail ELSE
    LET orderId == ReadBytes(instrumentIdBinaryU4.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET updateStatus == ReadBytes(orderId.rest, 1) IN IF ~updateStatus.ok THEN Fail ELSE
    LET reserved32 == ReadBytes(updateStatus.rest, 32) IN IF ~reserved32.ok THEN Fail ELSE
    Ok([ matchingEngineTime   |-> matchingEngineTime.value,
         instrumentIdBinaryU4 |-> instrumentIdBinaryU4.value,
         orderId              |-> orderId.value,
         updateStatus         |-> updateStatus.value,
         reserved32           |-> reserved32.value ], reserved32.rest)

ZeroOrderStatusUpdateNotification ==
    [ matchingEngineTime   |-> [i \in 1 .. 8 |-> 0],
      instrumentIdBinaryU4 |-> [i \in 1 .. 4 |-> 0],
      orderId              |-> [i \in 1 .. 8 |-> 0],
      updateStatus         |-> [i \in 1 .. 1 |-> 0],
      reserved32           |-> [i \in 1 .. 32 |-> 0] ]

(* Order Status Update Notification at zero, then each field in turn at the values it is checked at *)
CheckedOrderStatusUpdateNotification ==
    { ZeroOrderStatusUpdateNotification }
        \cup { [ZeroOrderStatusUpdateNotification EXCEPT !.matchingEngineTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderStatusUpdateNotification EXCEPT !.instrumentIdBinaryU4 = one] : one \in Sample(4) }
        \cup { [ZeroOrderStatusUpdateNotification EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderStatusUpdateNotification EXCEPT !.updateStatus = one] : one \in Sample(1) }
        \cup { [ZeroOrderStatusUpdateNotification EXCEPT !.reserved32 = one] : one \in Sample(32) }

(***************************************************************************)
(* Simple Execution Notification: 159 bytes                                *)
(***************************************************************************)

SimpleExecutionNotification ==
    [ matchingEngineTime   : Sample(8),
      mpId                 : Sample(5),
      operatorId           : Sample(18),
      operatorLocation     : Sample(6),
      instrumentIdBinaryU4 : Sample(4),
      clientOrderId        : Sample(20),
      simpleTradeId        : Sample(8),
      complexTradeId       : Sample(8),
      executionId          : Sample(8),
      tradeDate            : Sample(2),
      correctionNumber     : Sample(1),
      tradeStatus          : Sample(1),
      lastPrice            : Sample(8),
      lastSize             : Sample(4),
      orderInstructions    : Sample(2),
      ctiCode              : Sample(1),
      textMemo             : Sample(20),
      liquidityIndicator   : Sample(3),
      reserved32           : Sample(32) ]

EncodeSimpleExecutionNotification(message) ==
    message.matchingEngineTime
        \o message.mpId
        \o message.operatorId
        \o message.operatorLocation
        \o message.instrumentIdBinaryU4
        \o message.clientOrderId
        \o message.simpleTradeId
        \o message.complexTradeId
        \o message.executionId
        \o message.tradeDate
        \o message.correctionNumber
        \o message.tradeStatus
        \o message.lastPrice
        \o message.lastSize
        \o message.orderInstructions
        \o message.ctiCode
        \o message.textMemo
        \o message.liquidityIndicator
        \o message.reserved32

DecodeSimpleExecutionNotification(bytes) ==
    LET matchingEngineTime == ReadBytes(bytes, 8) IN IF ~matchingEngineTime.ok THEN Fail ELSE
    LET mpId == ReadBytes(matchingEngineTime.rest, 5) IN IF ~mpId.ok THEN Fail ELSE
    LET operatorId == ReadBytes(mpId.rest, 18) IN IF ~operatorId.ok THEN Fail ELSE
    LET operatorLocation == ReadBytes(operatorId.rest, 6) IN IF ~operatorLocation.ok THEN Fail ELSE
    LET instrumentIdBinaryU4 == ReadBytes(operatorLocation.rest, 4) IN IF ~instrumentIdBinaryU4.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(instrumentIdBinaryU4.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET simpleTradeId == ReadBytes(clientOrderId.rest, 8) IN IF ~simpleTradeId.ok THEN Fail ELSE
    LET complexTradeId == ReadBytes(simpleTradeId.rest, 8) IN IF ~complexTradeId.ok THEN Fail ELSE
    LET executionId == ReadBytes(complexTradeId.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(executionId.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET correctionNumber == ReadBytes(tradeDate.rest, 1) IN IF ~correctionNumber.ok THEN Fail ELSE
    LET tradeStatus == ReadBytes(correctionNumber.rest, 1) IN IF ~tradeStatus.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(tradeStatus.rest, 8) IN IF ~lastPrice.ok THEN Fail ELSE
    LET lastSize == ReadBytes(lastPrice.rest, 4) IN IF ~lastSize.ok THEN Fail ELSE
    LET orderInstructions == ReadBytes(lastSize.rest, 2) IN IF ~orderInstructions.ok THEN Fail ELSE
    LET ctiCode == ReadBytes(orderInstructions.rest, 1) IN IF ~ctiCode.ok THEN Fail ELSE
    LET textMemo == ReadBytes(ctiCode.rest, 20) IN IF ~textMemo.ok THEN Fail ELSE
    LET liquidityIndicator == ReadBytes(textMemo.rest, 3) IN IF ~liquidityIndicator.ok THEN Fail ELSE
    LET reserved32 == ReadBytes(liquidityIndicator.rest, 32) IN IF ~reserved32.ok THEN Fail ELSE
    Ok([ matchingEngineTime   |-> matchingEngineTime.value,
         mpId                 |-> mpId.value,
         operatorId           |-> operatorId.value,
         operatorLocation     |-> operatorLocation.value,
         instrumentIdBinaryU4 |-> instrumentIdBinaryU4.value,
         clientOrderId        |-> clientOrderId.value,
         simpleTradeId        |-> simpleTradeId.value,
         complexTradeId       |-> complexTradeId.value,
         executionId          |-> executionId.value,
         tradeDate            |-> tradeDate.value,
         correctionNumber     |-> correctionNumber.value,
         tradeStatus          |-> tradeStatus.value,
         lastPrice            |-> lastPrice.value,
         lastSize             |-> lastSize.value,
         orderInstructions    |-> orderInstructions.value,
         ctiCode              |-> ctiCode.value,
         textMemo             |-> textMemo.value,
         liquidityIndicator   |-> liquidityIndicator.value,
         reserved32           |-> reserved32.value ], reserved32.rest)

ZeroSimpleExecutionNotification ==
    [ matchingEngineTime   |-> [i \in 1 .. 8 |-> 0],
      mpId                 |-> [i \in 1 .. 5 |-> 0],
      operatorId           |-> [i \in 1 .. 18 |-> 0],
      operatorLocation     |-> [i \in 1 .. 6 |-> 0],
      instrumentIdBinaryU4 |-> [i \in 1 .. 4 |-> 0],
      clientOrderId        |-> [i \in 1 .. 20 |-> 0],
      simpleTradeId        |-> [i \in 1 .. 8 |-> 0],
      complexTradeId       |-> [i \in 1 .. 8 |-> 0],
      executionId          |-> [i \in 1 .. 8 |-> 0],
      tradeDate            |-> [i \in 1 .. 2 |-> 0],
      correctionNumber     |-> [i \in 1 .. 1 |-> 0],
      tradeStatus          |-> [i \in 1 .. 1 |-> 0],
      lastPrice            |-> [i \in 1 .. 8 |-> 0],
      lastSize             |-> [i \in 1 .. 4 |-> 0],
      orderInstructions    |-> [i \in 1 .. 2 |-> 0],
      ctiCode              |-> [i \in 1 .. 1 |-> 0],
      textMemo             |-> [i \in 1 .. 20 |-> 0],
      liquidityIndicator   |-> [i \in 1 .. 3 |-> 0],
      reserved32           |-> [i \in 1 .. 32 |-> 0] ]

(* Simple Execution Notification at zero, then each field in turn at the values it is checked at *)
CheckedSimpleExecutionNotification ==
    { ZeroSimpleExecutionNotification }
        \cup { [ZeroSimpleExecutionNotification EXCEPT !.matchingEngineTime = one] : one \in Sample(8) }
        \cup { [ZeroSimpleExecutionNotification EXCEPT !.mpId = one] : one \in Sample(5) }
        \cup { [ZeroSimpleExecutionNotification EXCEPT !.operatorId = one] : one \in Sample(18) }
        \cup { [ZeroSimpleExecutionNotification EXCEPT !.operatorLocation = one] : one \in Sample(6) }
        \cup { [ZeroSimpleExecutionNotification EXCEPT !.instrumentIdBinaryU4 = one] : one \in Sample(4) }
        \cup { [ZeroSimpleExecutionNotification EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroSimpleExecutionNotification EXCEPT !.simpleTradeId = one] : one \in Sample(8) }
        \cup { [ZeroSimpleExecutionNotification EXCEPT !.complexTradeId = one] : one \in Sample(8) }
        \cup { [ZeroSimpleExecutionNotification EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroSimpleExecutionNotification EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroSimpleExecutionNotification EXCEPT !.correctionNumber = one] : one \in Sample(1) }
        \cup { [ZeroSimpleExecutionNotification EXCEPT !.tradeStatus = one] : one \in Sample(1) }
        \cup { [ZeroSimpleExecutionNotification EXCEPT !.lastPrice = one] : one \in Sample(8) }
        \cup { [ZeroSimpleExecutionNotification EXCEPT !.lastSize = one] : one \in Sample(4) }
        \cup { [ZeroSimpleExecutionNotification EXCEPT !.orderInstructions = one] : one \in Sample(2) }
        \cup { [ZeroSimpleExecutionNotification EXCEPT !.ctiCode = one] : one \in Sample(1) }
        \cup { [ZeroSimpleExecutionNotification EXCEPT !.textMemo = one] : one \in Sample(20) }
        \cup { [ZeroSimpleExecutionNotification EXCEPT !.liquidityIndicator = one] : one \in Sample(3) }
        \cup { [ZeroSimpleExecutionNotification EXCEPT !.reserved32 = one] : one \in Sample(32) }

(***************************************************************************)
(* Complex Execution Notification: 93 bytes                                *)
(***************************************************************************)

ComplexExecutionNotification ==
    [ matchingEngineTime   : Sample(8),
      mpId                 : Sample(5),
      instrumentIdBinaryU4 : Sample(4),
      clientOrderId        : Sample(20),
      complexTradeId       : Sample(8),
      tradeDate            : Sample(2),
      lastNetPrice         : Sample(8),
      lastSize             : Sample(4),
      orderInstructions    : Sample(2),
      reserved32           : Sample(32) ]

EncodeComplexExecutionNotification(message) ==
    message.matchingEngineTime
        \o message.mpId
        \o message.instrumentIdBinaryU4
        \o message.clientOrderId
        \o message.complexTradeId
        \o message.tradeDate
        \o message.lastNetPrice
        \o message.lastSize
        \o message.orderInstructions
        \o message.reserved32

DecodeComplexExecutionNotification(bytes) ==
    LET matchingEngineTime == ReadBytes(bytes, 8) IN IF ~matchingEngineTime.ok THEN Fail ELSE
    LET mpId == ReadBytes(matchingEngineTime.rest, 5) IN IF ~mpId.ok THEN Fail ELSE
    LET instrumentIdBinaryU4 == ReadBytes(mpId.rest, 4) IN IF ~instrumentIdBinaryU4.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(instrumentIdBinaryU4.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET complexTradeId == ReadBytes(clientOrderId.rest, 8) IN IF ~complexTradeId.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(complexTradeId.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET lastNetPrice == ReadBytes(tradeDate.rest, 8) IN IF ~lastNetPrice.ok THEN Fail ELSE
    LET lastSize == ReadBytes(lastNetPrice.rest, 4) IN IF ~lastSize.ok THEN Fail ELSE
    LET orderInstructions == ReadBytes(lastSize.rest, 2) IN IF ~orderInstructions.ok THEN Fail ELSE
    LET reserved32 == ReadBytes(orderInstructions.rest, 32) IN IF ~reserved32.ok THEN Fail ELSE
    Ok([ matchingEngineTime   |-> matchingEngineTime.value,
         mpId                 |-> mpId.value,
         instrumentIdBinaryU4 |-> instrumentIdBinaryU4.value,
         clientOrderId        |-> clientOrderId.value,
         complexTradeId       |-> complexTradeId.value,
         tradeDate            |-> tradeDate.value,
         lastNetPrice         |-> lastNetPrice.value,
         lastSize             |-> lastSize.value,
         orderInstructions    |-> orderInstructions.value,
         reserved32           |-> reserved32.value ], reserved32.rest)

ZeroComplexExecutionNotification ==
    [ matchingEngineTime   |-> [i \in 1 .. 8 |-> 0],
      mpId                 |-> [i \in 1 .. 5 |-> 0],
      instrumentIdBinaryU4 |-> [i \in 1 .. 4 |-> 0],
      clientOrderId        |-> [i \in 1 .. 20 |-> 0],
      complexTradeId       |-> [i \in 1 .. 8 |-> 0],
      tradeDate            |-> [i \in 1 .. 2 |-> 0],
      lastNetPrice         |-> [i \in 1 .. 8 |-> 0],
      lastSize             |-> [i \in 1 .. 4 |-> 0],
      orderInstructions    |-> [i \in 1 .. 2 |-> 0],
      reserved32           |-> [i \in 1 .. 32 |-> 0] ]

(* Complex Execution Notification at zero, then each field in turn at the values it is checked at *)
CheckedComplexExecutionNotification ==
    { ZeroComplexExecutionNotification }
        \cup { [ZeroComplexExecutionNotification EXCEPT !.matchingEngineTime = one] : one \in Sample(8) }
        \cup { [ZeroComplexExecutionNotification EXCEPT !.mpId = one] : one \in Sample(5) }
        \cup { [ZeroComplexExecutionNotification EXCEPT !.instrumentIdBinaryU4 = one] : one \in Sample(4) }
        \cup { [ZeroComplexExecutionNotification EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroComplexExecutionNotification EXCEPT !.complexTradeId = one] : one \in Sample(8) }
        \cup { [ZeroComplexExecutionNotification EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroComplexExecutionNotification EXCEPT !.lastNetPrice = one] : one \in Sample(8) }
        \cup { [ZeroComplexExecutionNotification EXCEPT !.lastSize = one] : one \in Sample(4) }
        \cup { [ZeroComplexExecutionNotification EXCEPT !.orderInstructions = one] : one \in Sample(2) }
        \cup { [ZeroComplexExecutionNotification EXCEPT !.reserved32 = one] : one \in Sample(32) }

(***************************************************************************)
(* Sequenced Message, selected by Sequenced Message Type                   *)
(***************************************************************************)

NewOrderResponseMessageCode == 20050  \* "NR"
ModifyOrderResponseCode == 19794  \* "MR"
CancelOrderResponseCode == 17234  \* "CR"
MassCancelResponseCode == 22610  \* "XR"
StrategyCreationResponseMessageCode == 21330  \* "SR"
SystemStateNotificationMessageCode == 21326  \* "SN"
NewOrderNotificationCode == 20273  \* "O1"
ModifyOrderNotificationCode == 19790  \* "MN"
CancelReduceSizeOrderNotificationCode == 22606  \* "XN"
OrderStatusUpdateNotificationCode == 20307  \* "OS"
SimpleExecutionNotificationCode == 17742  \* "EN"
ComplexExecutionNotificationCode == 17230  \* "CN"

SequencedMessage ==
    [ tag : {NewOrderResponseMessageCode}, body : NewOrderResponseMessage ]
        \cup [ tag : {ModifyOrderResponseCode}, body : ModifyOrderResponse ]
        \cup [ tag : {CancelOrderResponseCode}, body : CancelOrderResponse ]
        \cup [ tag : {MassCancelResponseCode}, body : MassCancelResponse ]
        \cup [ tag : {StrategyCreationResponseMessageCode}, body : StrategyCreationResponseMessage ]
        \cup [ tag : {SystemStateNotificationMessageCode}, body : SystemStateNotificationMessage ]
        \cup [ tag : {NewOrderNotificationCode}, body : NewOrderNotification ]
        \cup [ tag : {ModifyOrderNotificationCode}, body : ModifyOrderNotification ]
        \cup [ tag : {CancelReduceSizeOrderNotificationCode}, body : CancelReduceSizeOrderNotification ]
        \cup [ tag : {OrderStatusUpdateNotificationCode}, body : OrderStatusUpdateNotification ]
        \cup [ tag : {SimpleExecutionNotificationCode}, body : SimpleExecutionNotification ]
        \cup [ tag : {ComplexExecutionNotificationCode}, body : ComplexExecutionNotification ]

EncodeSequencedMessage(message) ==
    CASE message.tag = NewOrderResponseMessageCode -> EncodeNewOrderResponseMessage(message.body)
      [] message.tag = ModifyOrderResponseCode -> EncodeModifyOrderResponse(message.body)
      [] message.tag = CancelOrderResponseCode -> EncodeCancelOrderResponse(message.body)
      [] message.tag = MassCancelResponseCode -> EncodeMassCancelResponse(message.body)
      [] message.tag = StrategyCreationResponseMessageCode -> EncodeStrategyCreationResponseMessage(message.body)
      [] message.tag = SystemStateNotificationMessageCode -> EncodeSystemStateNotificationMessage(message.body)
      [] message.tag = NewOrderNotificationCode -> EncodeNewOrderNotification(message.body)
      [] message.tag = ModifyOrderNotificationCode -> EncodeModifyOrderNotification(message.body)
      [] message.tag = CancelReduceSizeOrderNotificationCode -> EncodeCancelReduceSizeOrderNotification(message.body)
      [] message.tag = OrderStatusUpdateNotificationCode -> EncodeOrderStatusUpdateNotification(message.body)
      [] message.tag = SimpleExecutionNotificationCode -> EncodeSimpleExecutionNotification(message.body)
      [] message.tag = ComplexExecutionNotificationCode -> EncodeComplexExecutionNotification(message.body)

DecodeSequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = NewOrderResponseMessageCode -> DecodeNewOrderResponseMessage(bytes)
              [] tag = ModifyOrderResponseCode -> DecodeModifyOrderResponse(bytes)
              [] tag = CancelOrderResponseCode -> DecodeCancelOrderResponse(bytes)
              [] tag = MassCancelResponseCode -> DecodeMassCancelResponse(bytes)
              [] tag = StrategyCreationResponseMessageCode -> DecodeStrategyCreationResponseMessage(bytes)
              [] tag = SystemStateNotificationMessageCode -> DecodeSystemStateNotificationMessage(bytes)
              [] tag = NewOrderNotificationCode -> DecodeNewOrderNotification(bytes)
              [] tag = ModifyOrderNotificationCode -> DecodeModifyOrderNotification(bytes)
              [] tag = CancelReduceSizeOrderNotificationCode -> DecodeCancelReduceSizeOrderNotification(bytes)
              [] tag = OrderStatusUpdateNotificationCode -> DecodeOrderStatusUpdateNotification(bytes)
              [] tag = SimpleExecutionNotificationCode -> DecodeSimpleExecutionNotification(bytes)
              [] tag = ComplexExecutionNotificationCode -> DecodeComplexExecutionNotification(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSequencedMessage == [tag |-> NewOrderResponseMessageCode, body |-> ZeroNewOrderResponseMessage]

(* Each Sequenced Message in turn, at the values the message it names is checked at *)
CheckedSequencedMessage ==
    { [tag |-> NewOrderResponseMessageCode, body |-> one] : one \in CheckedNewOrderResponseMessage }
        \cup { [tag |-> ModifyOrderResponseCode, body |-> one] : one \in CheckedModifyOrderResponse }
        \cup { [tag |-> CancelOrderResponseCode, body |-> one] : one \in CheckedCancelOrderResponse }
        \cup { [tag |-> MassCancelResponseCode, body |-> one] : one \in CheckedMassCancelResponse }
        \cup { [tag |-> StrategyCreationResponseMessageCode, body |-> one] : one \in CheckedStrategyCreationResponseMessage }
        \cup { [tag |-> SystemStateNotificationMessageCode, body |-> one] : one \in CheckedSystemStateNotificationMessage }
        \cup { [tag |-> NewOrderNotificationCode, body |-> one] : one \in CheckedNewOrderNotification }
        \cup { [tag |-> ModifyOrderNotificationCode, body |-> one] : one \in CheckedModifyOrderNotification }
        \cup { [tag |-> CancelReduceSizeOrderNotificationCode, body |-> one] : one \in CheckedCancelReduceSizeOrderNotification }
        \cup { [tag |-> OrderStatusUpdateNotificationCode, body |-> one] : one \in CheckedOrderStatusUpdateNotification }
        \cup { [tag |-> SimpleExecutionNotificationCode, body |-> one] : one \in CheckedSimpleExecutionNotification }
        \cup { [tag |-> ComplexExecutionNotificationCode, body |-> one] : one \in CheckedComplexExecutionNotification }

(***************************************************************************)
(* Sequenced Data Packet                                                   *)
(***************************************************************************)

SequencedDataPacket ==
    [ sequenceNumber   : Sample(8),
      sequencedMessage : SequencedMessage ]

EncodeSequencedDataPacket(message) ==
    message.sequenceNumber
        \o EncodeUIntBE(message.sequencedMessage.tag, 2)
        \o EncodeSequencedMessage(message.sequencedMessage)

DecodeSequencedDataPacket(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET sequencedMessageType == ReadUIntBE(sequenceNumber.rest, 2) IN IF ~sequencedMessageType.ok THEN Fail ELSE
    LET sequencedMessage == DecodeSequencedMessage(sequencedMessageType.value, sequencedMessageType.rest) IN IF ~sequencedMessage.ok THEN Fail ELSE
    Ok([ sequenceNumber   |-> sequenceNumber.value,
         sequencedMessage |-> sequencedMessage.value ], sequencedMessage.rest)

ZeroSequencedDataPacket ==
    [ sequenceNumber   |-> [i \in 1 .. 8 |-> 0],
      sequencedMessage |-> ZeroSequencedMessage ]

(* Sequenced Data Packet at zero, then each field in turn at the values it is checked at *)
CheckedSequencedDataPacket ==
    { ZeroSequencedDataPacket }
        \cup { [ZeroSequencedDataPacket EXCEPT !.sequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSequencedDataPacket EXCEPT !.sequencedMessage = one] : one \in CheckedSequencedMessage }

(***************************************************************************)
(* New Order Request Message: 174 bytes                                    *)
(***************************************************************************)

NewOrderRequestMessage ==
    [ clientSendTime                   : Sample(8),
      mpId                             : Sample(5),
      operatorId                       : Sample(18),
      operatorLocation                 : Sample(6),
      account                          : Sample(16),
      clientOrderId                    : Sample(20),
      instrumentIdBinaryU4             : Sample(4),
      price                            : Sample(8),
      stopOrderTriggerPrice            : Sample(8),
      sizeBinaryU4                     : Sample(4),
      orderInstructions                : Sample(2),
      timeInForce                      : Sample(1),
      orderType                        : Sample(1),
      selfTradeProtection              : Sample(1),
      selfTradeProtectionGroup         : Sample(2),
      purgeGroup                       : Sample(1),
      customerOrderHandlingInstruction : Sample(1),
      additionalOrderIndicators        : Sample(1),
      minQty                           : Sample(4),
      orderExpiryDate                  : Sample(2),
      tradingCollarDollarValue         : Sample(8),
      ctiCode                          : Sample(1),
      textMemo                         : Sample(20),
      reserved32                       : Sample(32) ]

EncodeNewOrderRequestMessage(message) ==
    message.clientSendTime
        \o message.mpId
        \o message.operatorId
        \o message.operatorLocation
        \o message.account
        \o message.clientOrderId
        \o message.instrumentIdBinaryU4
        \o message.price
        \o message.stopOrderTriggerPrice
        \o message.sizeBinaryU4
        \o message.orderInstructions
        \o message.timeInForce
        \o message.orderType
        \o message.selfTradeProtection
        \o message.selfTradeProtectionGroup
        \o message.purgeGroup
        \o message.customerOrderHandlingInstruction
        \o message.additionalOrderIndicators
        \o message.minQty
        \o message.orderExpiryDate
        \o message.tradingCollarDollarValue
        \o message.ctiCode
        \o message.textMemo
        \o message.reserved32

DecodeNewOrderRequestMessage(bytes) ==
    LET clientSendTime == ReadBytes(bytes, 8) IN IF ~clientSendTime.ok THEN Fail ELSE
    LET mpId == ReadBytes(clientSendTime.rest, 5) IN IF ~mpId.ok THEN Fail ELSE
    LET operatorId == ReadBytes(mpId.rest, 18) IN IF ~operatorId.ok THEN Fail ELSE
    LET operatorLocation == ReadBytes(operatorId.rest, 6) IN IF ~operatorLocation.ok THEN Fail ELSE
    LET account == ReadBytes(operatorLocation.rest, 16) IN IF ~account.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(account.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET instrumentIdBinaryU4 == ReadBytes(clientOrderId.rest, 4) IN IF ~instrumentIdBinaryU4.ok THEN Fail ELSE
    LET price == ReadBytes(instrumentIdBinaryU4.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET stopOrderTriggerPrice == ReadBytes(price.rest, 8) IN IF ~stopOrderTriggerPrice.ok THEN Fail ELSE
    LET sizeBinaryU4 == ReadBytes(stopOrderTriggerPrice.rest, 4) IN IF ~sizeBinaryU4.ok THEN Fail ELSE
    LET orderInstructions == ReadBytes(sizeBinaryU4.rest, 2) IN IF ~orderInstructions.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(orderInstructions.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET orderType == ReadBytes(timeInForce.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET selfTradeProtection == ReadBytes(orderType.rest, 1) IN IF ~selfTradeProtection.ok THEN Fail ELSE
    LET selfTradeProtectionGroup == ReadBytes(selfTradeProtection.rest, 2) IN IF ~selfTradeProtectionGroup.ok THEN Fail ELSE
    LET purgeGroup == ReadBytes(selfTradeProtectionGroup.rest, 1) IN IF ~purgeGroup.ok THEN Fail ELSE
    LET customerOrderHandlingInstruction == ReadBytes(purgeGroup.rest, 1) IN IF ~customerOrderHandlingInstruction.ok THEN Fail ELSE
    LET additionalOrderIndicators == ReadBytes(customerOrderHandlingInstruction.rest, 1) IN IF ~additionalOrderIndicators.ok THEN Fail ELSE
    LET minQty == ReadBytes(additionalOrderIndicators.rest, 4) IN IF ~minQty.ok THEN Fail ELSE
    LET orderExpiryDate == ReadBytes(minQty.rest, 2) IN IF ~orderExpiryDate.ok THEN Fail ELSE
    LET tradingCollarDollarValue == ReadBytes(orderExpiryDate.rest, 8) IN IF ~tradingCollarDollarValue.ok THEN Fail ELSE
    LET ctiCode == ReadBytes(tradingCollarDollarValue.rest, 1) IN IF ~ctiCode.ok THEN Fail ELSE
    LET textMemo == ReadBytes(ctiCode.rest, 20) IN IF ~textMemo.ok THEN Fail ELSE
    LET reserved32 == ReadBytes(textMemo.rest, 32) IN IF ~reserved32.ok THEN Fail ELSE
    Ok([ clientSendTime                   |-> clientSendTime.value,
         mpId                             |-> mpId.value,
         operatorId                       |-> operatorId.value,
         operatorLocation                 |-> operatorLocation.value,
         account                          |-> account.value,
         clientOrderId                    |-> clientOrderId.value,
         instrumentIdBinaryU4             |-> instrumentIdBinaryU4.value,
         price                            |-> price.value,
         stopOrderTriggerPrice            |-> stopOrderTriggerPrice.value,
         sizeBinaryU4                     |-> sizeBinaryU4.value,
         orderInstructions                |-> orderInstructions.value,
         timeInForce                      |-> timeInForce.value,
         orderType                        |-> orderType.value,
         selfTradeProtection              |-> selfTradeProtection.value,
         selfTradeProtectionGroup         |-> selfTradeProtectionGroup.value,
         purgeGroup                       |-> purgeGroup.value,
         customerOrderHandlingInstruction |-> customerOrderHandlingInstruction.value,
         additionalOrderIndicators        |-> additionalOrderIndicators.value,
         minQty                           |-> minQty.value,
         orderExpiryDate                  |-> orderExpiryDate.value,
         tradingCollarDollarValue         |-> tradingCollarDollarValue.value,
         ctiCode                          |-> ctiCode.value,
         textMemo                         |-> textMemo.value,
         reserved32                       |-> reserved32.value ], reserved32.rest)

ZeroNewOrderRequestMessage ==
    [ clientSendTime                   |-> [i \in 1 .. 8 |-> 0],
      mpId                             |-> [i \in 1 .. 5 |-> 0],
      operatorId                       |-> [i \in 1 .. 18 |-> 0],
      operatorLocation                 |-> [i \in 1 .. 6 |-> 0],
      account                          |-> [i \in 1 .. 16 |-> 0],
      clientOrderId                    |-> [i \in 1 .. 20 |-> 0],
      instrumentIdBinaryU4             |-> [i \in 1 .. 4 |-> 0],
      price                            |-> [i \in 1 .. 8 |-> 0],
      stopOrderTriggerPrice            |-> [i \in 1 .. 8 |-> 0],
      sizeBinaryU4                     |-> [i \in 1 .. 4 |-> 0],
      orderInstructions                |-> [i \in 1 .. 2 |-> 0],
      timeInForce                      |-> [i \in 1 .. 1 |-> 0],
      orderType                        |-> [i \in 1 .. 1 |-> 0],
      selfTradeProtection              |-> [i \in 1 .. 1 |-> 0],
      selfTradeProtectionGroup         |-> [i \in 1 .. 2 |-> 0],
      purgeGroup                       |-> [i \in 1 .. 1 |-> 0],
      customerOrderHandlingInstruction |-> [i \in 1 .. 1 |-> 0],
      additionalOrderIndicators        |-> [i \in 1 .. 1 |-> 0],
      minQty                           |-> [i \in 1 .. 4 |-> 0],
      orderExpiryDate                  |-> [i \in 1 .. 2 |-> 0],
      tradingCollarDollarValue         |-> [i \in 1 .. 8 |-> 0],
      ctiCode                          |-> [i \in 1 .. 1 |-> 0],
      textMemo                         |-> [i \in 1 .. 20 |-> 0],
      reserved32                       |-> [i \in 1 .. 32 |-> 0] ]

(* New Order Request Message at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderRequestMessage ==
    { ZeroNewOrderRequestMessage }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.clientSendTime = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.mpId = one] : one \in Sample(5) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.operatorId = one] : one \in Sample(18) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.operatorLocation = one] : one \in Sample(6) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.account = one] : one \in Sample(16) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.instrumentIdBinaryU4 = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.stopOrderTriggerPrice = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.sizeBinaryU4 = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.orderInstructions = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.selfTradeProtection = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.selfTradeProtectionGroup = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.purgeGroup = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.customerOrderHandlingInstruction = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.additionalOrderIndicators = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.orderExpiryDate = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.tradingCollarDollarValue = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.ctiCode = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.textMemo = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.reserved32 = one] : one \in Sample(32) }

(***************************************************************************)
(* New Order Response Message: 56 bytes                                    *)
(***************************************************************************)

NewOrderResponseMessage2 ==
    [ matchingEngine       : Sample(8),
      mpId                 : Sample(5),
      clientOrderId        : Sample(20),
      instrumentIdBinaryU4 : Sample(4),
      orderId              : Sample(8),
      status               : Sample(1),
      reserved10           : Sample(10) ]

EncodeNewOrderResponseMessage2(message) ==
    message.matchingEngine
        \o message.mpId
        \o message.clientOrderId
        \o message.instrumentIdBinaryU4
        \o message.orderId
        \o message.status
        \o message.reserved10

DecodeNewOrderResponseMessage2(bytes) ==
    LET matchingEngine == ReadBytes(bytes, 8) IN IF ~matchingEngine.ok THEN Fail ELSE
    LET mpId == ReadBytes(matchingEngine.rest, 5) IN IF ~mpId.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(mpId.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET instrumentIdBinaryU4 == ReadBytes(clientOrderId.rest, 4) IN IF ~instrumentIdBinaryU4.ok THEN Fail ELSE
    LET orderId == ReadBytes(instrumentIdBinaryU4.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET status == ReadBytes(orderId.rest, 1) IN IF ~status.ok THEN Fail ELSE
    LET reserved10 == ReadBytes(status.rest, 10) IN IF ~reserved10.ok THEN Fail ELSE
    Ok([ matchingEngine       |-> matchingEngine.value,
         mpId                 |-> mpId.value,
         clientOrderId        |-> clientOrderId.value,
         instrumentIdBinaryU4 |-> instrumentIdBinaryU4.value,
         orderId              |-> orderId.value,
         status               |-> status.value,
         reserved10           |-> reserved10.value ], reserved10.rest)

ZeroNewOrderResponseMessage2 ==
    [ matchingEngine       |-> [i \in 1 .. 8 |-> 0],
      mpId                 |-> [i \in 1 .. 5 |-> 0],
      clientOrderId        |-> [i \in 1 .. 20 |-> 0],
      instrumentIdBinaryU4 |-> [i \in 1 .. 4 |-> 0],
      orderId              |-> [i \in 1 .. 8 |-> 0],
      status               |-> [i \in 1 .. 1 |-> 0],
      reserved10           |-> [i \in 1 .. 10 |-> 0] ]

(* New Order Response Message at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderResponseMessage2 ==
    { ZeroNewOrderResponseMessage2 }
        \cup { [ZeroNewOrderResponseMessage2 EXCEPT !.matchingEngine = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderResponseMessage2 EXCEPT !.mpId = one] : one \in Sample(5) }
        \cup { [ZeroNewOrderResponseMessage2 EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderResponseMessage2 EXCEPT !.instrumentIdBinaryU4 = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderResponseMessage2 EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderResponseMessage2 EXCEPT !.status = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderResponseMessage2 EXCEPT !.reserved10 = one] : one \in Sample(10) }

(***************************************************************************)
(* Modify Order Request Message: 140 bytes                                 *)
(***************************************************************************)

ModifyOrderRequestMessage ==
    [ clientSendTime                   : Sample(8),
      mpId                             : Sample(5),
      operatorId                       : Sample(18),
      operatorLocation                 : Sample(6),
      clientOrderId                    : Sample(20),
      originalClientOrderId            : Sample(20),
      instrumentIdBinaryU4             : Sample(4),
      price                            : Sample(8),
      stopOrderTriggerPrice            : Sample(8),
      sizeBinaryS4                     : Sample(4),
      orderExpiryDate                  : Sample(2),
      selfTradeProtectionGroup         : Sample(2),
      purgeGroup                       : Sample(1),
      customerOrderHandlingInstruction : Sample(1),
      additionalOrderIndicators        : Sample(1),
      reserved32                       : Sample(32) ]

EncodeModifyOrderRequestMessage(message) ==
    message.clientSendTime
        \o message.mpId
        \o message.operatorId
        \o message.operatorLocation
        \o message.clientOrderId
        \o message.originalClientOrderId
        \o message.instrumentIdBinaryU4
        \o message.price
        \o message.stopOrderTriggerPrice
        \o message.sizeBinaryS4
        \o message.orderExpiryDate
        \o message.selfTradeProtectionGroup
        \o message.purgeGroup
        \o message.customerOrderHandlingInstruction
        \o message.additionalOrderIndicators
        \o message.reserved32

DecodeModifyOrderRequestMessage(bytes) ==
    LET clientSendTime == ReadBytes(bytes, 8) IN IF ~clientSendTime.ok THEN Fail ELSE
    LET mpId == ReadBytes(clientSendTime.rest, 5) IN IF ~mpId.ok THEN Fail ELSE
    LET operatorId == ReadBytes(mpId.rest, 18) IN IF ~operatorId.ok THEN Fail ELSE
    LET operatorLocation == ReadBytes(operatorId.rest, 6) IN IF ~operatorLocation.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(operatorLocation.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET originalClientOrderId == ReadBytes(clientOrderId.rest, 20) IN IF ~originalClientOrderId.ok THEN Fail ELSE
    LET instrumentIdBinaryU4 == ReadBytes(originalClientOrderId.rest, 4) IN IF ~instrumentIdBinaryU4.ok THEN Fail ELSE
    LET price == ReadBytes(instrumentIdBinaryU4.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET stopOrderTriggerPrice == ReadBytes(price.rest, 8) IN IF ~stopOrderTriggerPrice.ok THEN Fail ELSE
    LET sizeBinaryS4 == ReadBytes(stopOrderTriggerPrice.rest, 4) IN IF ~sizeBinaryS4.ok THEN Fail ELSE
    LET orderExpiryDate == ReadBytes(sizeBinaryS4.rest, 2) IN IF ~orderExpiryDate.ok THEN Fail ELSE
    LET selfTradeProtectionGroup == ReadBytes(orderExpiryDate.rest, 2) IN IF ~selfTradeProtectionGroup.ok THEN Fail ELSE
    LET purgeGroup == ReadBytes(selfTradeProtectionGroup.rest, 1) IN IF ~purgeGroup.ok THEN Fail ELSE
    LET customerOrderHandlingInstruction == ReadBytes(purgeGroup.rest, 1) IN IF ~customerOrderHandlingInstruction.ok THEN Fail ELSE
    LET additionalOrderIndicators == ReadBytes(customerOrderHandlingInstruction.rest, 1) IN IF ~additionalOrderIndicators.ok THEN Fail ELSE
    LET reserved32 == ReadBytes(additionalOrderIndicators.rest, 32) IN IF ~reserved32.ok THEN Fail ELSE
    Ok([ clientSendTime                   |-> clientSendTime.value,
         mpId                             |-> mpId.value,
         operatorId                       |-> operatorId.value,
         operatorLocation                 |-> operatorLocation.value,
         clientOrderId                    |-> clientOrderId.value,
         originalClientOrderId            |-> originalClientOrderId.value,
         instrumentIdBinaryU4             |-> instrumentIdBinaryU4.value,
         price                            |-> price.value,
         stopOrderTriggerPrice            |-> stopOrderTriggerPrice.value,
         sizeBinaryS4                     |-> sizeBinaryS4.value,
         orderExpiryDate                  |-> orderExpiryDate.value,
         selfTradeProtectionGroup         |-> selfTradeProtectionGroup.value,
         purgeGroup                       |-> purgeGroup.value,
         customerOrderHandlingInstruction |-> customerOrderHandlingInstruction.value,
         additionalOrderIndicators        |-> additionalOrderIndicators.value,
         reserved32                       |-> reserved32.value ], reserved32.rest)

ZeroModifyOrderRequestMessage ==
    [ clientSendTime                   |-> [i \in 1 .. 8 |-> 0],
      mpId                             |-> [i \in 1 .. 5 |-> 0],
      operatorId                       |-> [i \in 1 .. 18 |-> 0],
      operatorLocation                 |-> [i \in 1 .. 6 |-> 0],
      clientOrderId                    |-> [i \in 1 .. 20 |-> 0],
      originalClientOrderId            |-> [i \in 1 .. 20 |-> 0],
      instrumentIdBinaryU4             |-> [i \in 1 .. 4 |-> 0],
      price                            |-> [i \in 1 .. 8 |-> 0],
      stopOrderTriggerPrice            |-> [i \in 1 .. 8 |-> 0],
      sizeBinaryS4                     |-> [i \in 1 .. 4 |-> 0],
      orderExpiryDate                  |-> [i \in 1 .. 2 |-> 0],
      selfTradeProtectionGroup         |-> [i \in 1 .. 2 |-> 0],
      purgeGroup                       |-> [i \in 1 .. 1 |-> 0],
      customerOrderHandlingInstruction |-> [i \in 1 .. 1 |-> 0],
      additionalOrderIndicators        |-> [i \in 1 .. 1 |-> 0],
      reserved32                       |-> [i \in 1 .. 32 |-> 0] ]

(* Modify Order Request Message at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderRequestMessage ==
    { ZeroModifyOrderRequestMessage }
        \cup { [ZeroModifyOrderRequestMessage EXCEPT !.clientSendTime = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderRequestMessage EXCEPT !.mpId = one] : one \in Sample(5) }
        \cup { [ZeroModifyOrderRequestMessage EXCEPT !.operatorId = one] : one \in Sample(18) }
        \cup { [ZeroModifyOrderRequestMessage EXCEPT !.operatorLocation = one] : one \in Sample(6) }
        \cup { [ZeroModifyOrderRequestMessage EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroModifyOrderRequestMessage EXCEPT !.originalClientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroModifyOrderRequestMessage EXCEPT !.instrumentIdBinaryU4 = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderRequestMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderRequestMessage EXCEPT !.stopOrderTriggerPrice = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderRequestMessage EXCEPT !.sizeBinaryS4 = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderRequestMessage EXCEPT !.orderExpiryDate = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderRequestMessage EXCEPT !.selfTradeProtectionGroup = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderRequestMessage EXCEPT !.purgeGroup = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderRequestMessage EXCEPT !.customerOrderHandlingInstruction = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderRequestMessage EXCEPT !.additionalOrderIndicators = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderRequestMessage EXCEPT !.reserved32 = one] : one \in Sample(32) }

(***************************************************************************)
(* Modify Order Response: 80 bytes                                         *)
(***************************************************************************)

ModifyOrderResponse2 ==
    [ matchingEngineTime    : Sample(8),
      mpId                  : Sample(5),
      clientOrderId         : Sample(20),
      originalClientOrderId : Sample(20),
      instrumentIdBinaryU4  : Sample(4),
      orderId               : Sample(8),
      leavesQty             : Sample(4),
      status                : Sample(1),
      reserved10            : Sample(10) ]

EncodeModifyOrderResponse2(message) ==
    message.matchingEngineTime
        \o message.mpId
        \o message.clientOrderId
        \o message.originalClientOrderId
        \o message.instrumentIdBinaryU4
        \o message.orderId
        \o message.leavesQty
        \o message.status
        \o message.reserved10

DecodeModifyOrderResponse2(bytes) ==
    LET matchingEngineTime == ReadBytes(bytes, 8) IN IF ~matchingEngineTime.ok THEN Fail ELSE
    LET mpId == ReadBytes(matchingEngineTime.rest, 5) IN IF ~mpId.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(mpId.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET originalClientOrderId == ReadBytes(clientOrderId.rest, 20) IN IF ~originalClientOrderId.ok THEN Fail ELSE
    LET instrumentIdBinaryU4 == ReadBytes(originalClientOrderId.rest, 4) IN IF ~instrumentIdBinaryU4.ok THEN Fail ELSE
    LET orderId == ReadBytes(instrumentIdBinaryU4.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(orderId.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET status == ReadBytes(leavesQty.rest, 1) IN IF ~status.ok THEN Fail ELSE
    LET reserved10 == ReadBytes(status.rest, 10) IN IF ~reserved10.ok THEN Fail ELSE
    Ok([ matchingEngineTime    |-> matchingEngineTime.value,
         mpId                  |-> mpId.value,
         clientOrderId         |-> clientOrderId.value,
         originalClientOrderId |-> originalClientOrderId.value,
         instrumentIdBinaryU4  |-> instrumentIdBinaryU4.value,
         orderId               |-> orderId.value,
         leavesQty             |-> leavesQty.value,
         status                |-> status.value,
         reserved10            |-> reserved10.value ], reserved10.rest)

ZeroModifyOrderResponse2 ==
    [ matchingEngineTime    |-> [i \in 1 .. 8 |-> 0],
      mpId                  |-> [i \in 1 .. 5 |-> 0],
      clientOrderId         |-> [i \in 1 .. 20 |-> 0],
      originalClientOrderId |-> [i \in 1 .. 20 |-> 0],
      instrumentIdBinaryU4  |-> [i \in 1 .. 4 |-> 0],
      orderId               |-> [i \in 1 .. 8 |-> 0],
      leavesQty             |-> [i \in 1 .. 4 |-> 0],
      status                |-> [i \in 1 .. 1 |-> 0],
      reserved10            |-> [i \in 1 .. 10 |-> 0] ]

(* Modify Order Response at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderResponse2 ==
    { ZeroModifyOrderResponse2 }
        \cup { [ZeroModifyOrderResponse2 EXCEPT !.matchingEngineTime = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderResponse2 EXCEPT !.mpId = one] : one \in Sample(5) }
        \cup { [ZeroModifyOrderResponse2 EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroModifyOrderResponse2 EXCEPT !.originalClientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroModifyOrderResponse2 EXCEPT !.instrumentIdBinaryU4 = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderResponse2 EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderResponse2 EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderResponse2 EXCEPT !.status = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderResponse2 EXCEPT !.reserved10 = one] : one \in Sample(10) }

(***************************************************************************)
(* Cancel Order Request Message: 99 bytes                                  *)
(***************************************************************************)

CancelOrderRequestMessage ==
    [ clientSendTime        : Sample(8),
      mpId                  : Sample(5),
      operatorId            : Sample(18),
      operatorLocation      : Sample(6),
      orderId               : Sample(8),
      clientOrderId         : Sample(20),
      originalClientOrderId : Sample(20),
      instrumentIdBinaryU4  : Sample(4),
      reserved10            : Sample(10) ]

EncodeCancelOrderRequestMessage(message) ==
    message.clientSendTime
        \o message.mpId
        \o message.operatorId
        \o message.operatorLocation
        \o message.orderId
        \o message.clientOrderId
        \o message.originalClientOrderId
        \o message.instrumentIdBinaryU4
        \o message.reserved10

DecodeCancelOrderRequestMessage(bytes) ==
    LET clientSendTime == ReadBytes(bytes, 8) IN IF ~clientSendTime.ok THEN Fail ELSE
    LET mpId == ReadBytes(clientSendTime.rest, 5) IN IF ~mpId.ok THEN Fail ELSE
    LET operatorId == ReadBytes(mpId.rest, 18) IN IF ~operatorId.ok THEN Fail ELSE
    LET operatorLocation == ReadBytes(operatorId.rest, 6) IN IF ~operatorLocation.ok THEN Fail ELSE
    LET orderId == ReadBytes(operatorLocation.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(orderId.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET originalClientOrderId == ReadBytes(clientOrderId.rest, 20) IN IF ~originalClientOrderId.ok THEN Fail ELSE
    LET instrumentIdBinaryU4 == ReadBytes(originalClientOrderId.rest, 4) IN IF ~instrumentIdBinaryU4.ok THEN Fail ELSE
    LET reserved10 == ReadBytes(instrumentIdBinaryU4.rest, 10) IN IF ~reserved10.ok THEN Fail ELSE
    Ok([ clientSendTime        |-> clientSendTime.value,
         mpId                  |-> mpId.value,
         operatorId            |-> operatorId.value,
         operatorLocation      |-> operatorLocation.value,
         orderId               |-> orderId.value,
         clientOrderId         |-> clientOrderId.value,
         originalClientOrderId |-> originalClientOrderId.value,
         instrumentIdBinaryU4  |-> instrumentIdBinaryU4.value,
         reserved10            |-> reserved10.value ], reserved10.rest)

ZeroCancelOrderRequestMessage ==
    [ clientSendTime        |-> [i \in 1 .. 8 |-> 0],
      mpId                  |-> [i \in 1 .. 5 |-> 0],
      operatorId            |-> [i \in 1 .. 18 |-> 0],
      operatorLocation      |-> [i \in 1 .. 6 |-> 0],
      orderId               |-> [i \in 1 .. 8 |-> 0],
      clientOrderId         |-> [i \in 1 .. 20 |-> 0],
      originalClientOrderId |-> [i \in 1 .. 20 |-> 0],
      instrumentIdBinaryU4  |-> [i \in 1 .. 4 |-> 0],
      reserved10            |-> [i \in 1 .. 10 |-> 0] ]

(* Cancel Order Request Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelOrderRequestMessage ==
    { ZeroCancelOrderRequestMessage }
        \cup { [ZeroCancelOrderRequestMessage EXCEPT !.clientSendTime = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrderRequestMessage EXCEPT !.mpId = one] : one \in Sample(5) }
        \cup { [ZeroCancelOrderRequestMessage EXCEPT !.operatorId = one] : one \in Sample(18) }
        \cup { [ZeroCancelOrderRequestMessage EXCEPT !.operatorLocation = one] : one \in Sample(6) }
        \cup { [ZeroCancelOrderRequestMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrderRequestMessage EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroCancelOrderRequestMessage EXCEPT !.originalClientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroCancelOrderRequestMessage EXCEPT !.instrumentIdBinaryU4 = one] : one \in Sample(4) }
        \cup { [ZeroCancelOrderRequestMessage EXCEPT !.reserved10 = one] : one \in Sample(10) }

(***************************************************************************)
(* Cancel Order Response: 66 bytes                                         *)
(***************************************************************************)

CancelOrderResponse2 ==
    [ matchingEngineTime   : Sample(8),
      mpId                 : Sample(5),
      clientOrderId        : Sample(20),
      originalClientOrder  : Sample(20),
      instrumentIdBinaryU4 : Sample(4),
      orderId              : Sample(8),
      status               : Sample(1) ]

EncodeCancelOrderResponse2(message) ==
    message.matchingEngineTime
        \o message.mpId
        \o message.clientOrderId
        \o message.originalClientOrder
        \o message.instrumentIdBinaryU4
        \o message.orderId
        \o message.status

DecodeCancelOrderResponse2(bytes) ==
    LET matchingEngineTime == ReadBytes(bytes, 8) IN IF ~matchingEngineTime.ok THEN Fail ELSE
    LET mpId == ReadBytes(matchingEngineTime.rest, 5) IN IF ~mpId.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(mpId.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET originalClientOrder == ReadBytes(clientOrderId.rest, 20) IN IF ~originalClientOrder.ok THEN Fail ELSE
    LET instrumentIdBinaryU4 == ReadBytes(originalClientOrder.rest, 4) IN IF ~instrumentIdBinaryU4.ok THEN Fail ELSE
    LET orderId == ReadBytes(instrumentIdBinaryU4.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET status == ReadBytes(orderId.rest, 1) IN IF ~status.ok THEN Fail ELSE
    Ok([ matchingEngineTime   |-> matchingEngineTime.value,
         mpId                 |-> mpId.value,
         clientOrderId        |-> clientOrderId.value,
         originalClientOrder  |-> originalClientOrder.value,
         instrumentIdBinaryU4 |-> instrumentIdBinaryU4.value,
         orderId              |-> orderId.value,
         status               |-> status.value ], status.rest)

ZeroCancelOrderResponse2 ==
    [ matchingEngineTime   |-> [i \in 1 .. 8 |-> 0],
      mpId                 |-> [i \in 1 .. 5 |-> 0],
      clientOrderId        |-> [i \in 1 .. 20 |-> 0],
      originalClientOrder  |-> [i \in 1 .. 20 |-> 0],
      instrumentIdBinaryU4 |-> [i \in 1 .. 4 |-> 0],
      orderId              |-> [i \in 1 .. 8 |-> 0],
      status               |-> [i \in 1 .. 1 |-> 0] ]

(* Cancel Order Response at zero, then each field in turn at the values it is checked at *)
CheckedCancelOrderResponse2 ==
    { ZeroCancelOrderResponse2 }
        \cup { [ZeroCancelOrderResponse2 EXCEPT !.matchingEngineTime = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrderResponse2 EXCEPT !.mpId = one] : one \in Sample(5) }
        \cup { [ZeroCancelOrderResponse2 EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroCancelOrderResponse2 EXCEPT !.originalClientOrder = one] : one \in Sample(20) }
        \cup { [ZeroCancelOrderResponse2 EXCEPT !.instrumentIdBinaryU4 = one] : one \in Sample(4) }
        \cup { [ZeroCancelOrderResponse2 EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrderResponse2 EXCEPT !.status = one] : one \in Sample(1) }

(***************************************************************************)
(* Mass Cancel Request: 86 bytes                                           *)
(***************************************************************************)

MassCancelRequest ==
    [ clientSendTime   : Sample(8),
      mpId             : Sample(5),
      operatorId       : Sample(18),
      operatorLocation : Sample(6),
      reserved10       : Sample(10),
      clientOrderId    : Sample(20),
      scope            : Sample(1),
      action           : Sample(1),
      productGroupCode : Sample(6),
      productType      : Sample(1),
      purgeGroup       : Sample(1),
      reserved9        : Sample(9) ]

EncodeMassCancelRequest(message) ==
    message.clientSendTime
        \o message.mpId
        \o message.operatorId
        \o message.operatorLocation
        \o message.reserved10
        \o message.clientOrderId
        \o message.scope
        \o message.action
        \o message.productGroupCode
        \o message.productType
        \o message.purgeGroup
        \o message.reserved9

DecodeMassCancelRequest(bytes) ==
    LET clientSendTime == ReadBytes(bytes, 8) IN IF ~clientSendTime.ok THEN Fail ELSE
    LET mpId == ReadBytes(clientSendTime.rest, 5) IN IF ~mpId.ok THEN Fail ELSE
    LET operatorId == ReadBytes(mpId.rest, 18) IN IF ~operatorId.ok THEN Fail ELSE
    LET operatorLocation == ReadBytes(operatorId.rest, 6) IN IF ~operatorLocation.ok THEN Fail ELSE
    LET reserved10 == ReadBytes(operatorLocation.rest, 10) IN IF ~reserved10.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(reserved10.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET scope == ReadBytes(clientOrderId.rest, 1) IN IF ~scope.ok THEN Fail ELSE
    LET action == ReadBytes(scope.rest, 1) IN IF ~action.ok THEN Fail ELSE
    LET productGroupCode == ReadBytes(action.rest, 6) IN IF ~productGroupCode.ok THEN Fail ELSE
    LET productType == ReadBytes(productGroupCode.rest, 1) IN IF ~productType.ok THEN Fail ELSE
    LET purgeGroup == ReadBytes(productType.rest, 1) IN IF ~purgeGroup.ok THEN Fail ELSE
    LET reserved9 == ReadBytes(purgeGroup.rest, 9) IN IF ~reserved9.ok THEN Fail ELSE
    Ok([ clientSendTime   |-> clientSendTime.value,
         mpId             |-> mpId.value,
         operatorId       |-> operatorId.value,
         operatorLocation |-> operatorLocation.value,
         reserved10       |-> reserved10.value,
         clientOrderId    |-> clientOrderId.value,
         scope            |-> scope.value,
         action           |-> action.value,
         productGroupCode |-> productGroupCode.value,
         productType      |-> productType.value,
         purgeGroup       |-> purgeGroup.value,
         reserved9        |-> reserved9.value ], reserved9.rest)

ZeroMassCancelRequest ==
    [ clientSendTime   |-> [i \in 1 .. 8 |-> 0],
      mpId             |-> [i \in 1 .. 5 |-> 0],
      operatorId       |-> [i \in 1 .. 18 |-> 0],
      operatorLocation |-> [i \in 1 .. 6 |-> 0],
      reserved10       |-> [i \in 1 .. 10 |-> 0],
      clientOrderId    |-> [i \in 1 .. 20 |-> 0],
      scope            |-> [i \in 1 .. 1 |-> 0],
      action           |-> [i \in 1 .. 1 |-> 0],
      productGroupCode |-> [i \in 1 .. 6 |-> 0],
      productType      |-> [i \in 1 .. 1 |-> 0],
      purgeGroup       |-> [i \in 1 .. 1 |-> 0],
      reserved9        |-> [i \in 1 .. 9 |-> 0] ]

(* Mass Cancel Request at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelRequest ==
    { ZeroMassCancelRequest }
        \cup { [ZeroMassCancelRequest EXCEPT !.clientSendTime = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelRequest EXCEPT !.mpId = one] : one \in Sample(5) }
        \cup { [ZeroMassCancelRequest EXCEPT !.operatorId = one] : one \in Sample(18) }
        \cup { [ZeroMassCancelRequest EXCEPT !.operatorLocation = one] : one \in Sample(6) }
        \cup { [ZeroMassCancelRequest EXCEPT !.reserved10 = one] : one \in Sample(10) }
        \cup { [ZeroMassCancelRequest EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroMassCancelRequest EXCEPT !.scope = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelRequest EXCEPT !.action = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelRequest EXCEPT !.productGroupCode = one] : one \in Sample(6) }
        \cup { [ZeroMassCancelRequest EXCEPT !.productType = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelRequest EXCEPT !.purgeGroup = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelRequest EXCEPT !.reserved9 = one] : one \in Sample(9) }

(***************************************************************************)
(* Mass Cancel Response: 44 bytes                                          *)
(***************************************************************************)

MassCancelResponse2 ==
    [ matchingEngineTime : Sample(8),
      mpId               : Sample(5),
      clientOrderId      : Sample(20),
      status             : Sample(1),
      reserved10         : Sample(10) ]

EncodeMassCancelResponse2(message) ==
    message.matchingEngineTime
        \o message.mpId
        \o message.clientOrderId
        \o message.status
        \o message.reserved10

DecodeMassCancelResponse2(bytes) ==
    LET matchingEngineTime == ReadBytes(bytes, 8) IN IF ~matchingEngineTime.ok THEN Fail ELSE
    LET mpId == ReadBytes(matchingEngineTime.rest, 5) IN IF ~mpId.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(mpId.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET status == ReadBytes(clientOrderId.rest, 1) IN IF ~status.ok THEN Fail ELSE
    LET reserved10 == ReadBytes(status.rest, 10) IN IF ~reserved10.ok THEN Fail ELSE
    Ok([ matchingEngineTime |-> matchingEngineTime.value,
         mpId               |-> mpId.value,
         clientOrderId      |-> clientOrderId.value,
         status             |-> status.value,
         reserved10         |-> reserved10.value ], reserved10.rest)

ZeroMassCancelResponse2 ==
    [ matchingEngineTime |-> [i \in 1 .. 8 |-> 0],
      mpId               |-> [i \in 1 .. 5 |-> 0],
      clientOrderId      |-> [i \in 1 .. 20 |-> 0],
      status             |-> [i \in 1 .. 1 |-> 0],
      reserved10         |-> [i \in 1 .. 10 |-> 0] ]

(* Mass Cancel Response at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelResponse2 ==
    { ZeroMassCancelResponse2 }
        \cup { [ZeroMassCancelResponse2 EXCEPT !.matchingEngineTime = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelResponse2 EXCEPT !.mpId = one] : one \in Sample(5) }
        \cup { [ZeroMassCancelResponse2 EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroMassCancelResponse2 EXCEPT !.status = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelResponse2 EXCEPT !.reserved10 = one] : one \in Sample(10) }

(***************************************************************************)
(* Strategy Leg: 16 bytes                                                  *)
(***************************************************************************)

StrategyLeg ==
    [ instrumentIdBinaryU4 : Sample(4),
      legRatio             : Sample(4),
      reserved8            : Sample(8) ]

EncodeStrategyLeg(message) ==
    message.instrumentIdBinaryU4
        \o message.legRatio
        \o message.reserved8

DecodeStrategyLeg(bytes) ==
    LET instrumentIdBinaryU4 == ReadBytes(bytes, 4) IN IF ~instrumentIdBinaryU4.ok THEN Fail ELSE
    LET legRatio == ReadBytes(instrumentIdBinaryU4.rest, 4) IN IF ~legRatio.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(legRatio.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    Ok([ instrumentIdBinaryU4 |-> instrumentIdBinaryU4.value,
         legRatio             |-> legRatio.value,
         reserved8            |-> reserved8.value ], reserved8.rest)

ZeroStrategyLeg ==
    [ instrumentIdBinaryU4 |-> [i \in 1 .. 4 |-> 0],
      legRatio             |-> [i \in 1 .. 4 |-> 0],
      reserved8            |-> [i \in 1 .. 8 |-> 0] ]

(* Strategy Leg at zero, then each field in turn at the values it is checked at *)
CheckedStrategyLeg ==
    { ZeroStrategyLeg }
        \cup { [ZeroStrategyLeg EXCEPT !.instrumentIdBinaryU4 = one] : one \in Sample(4) }
        \cup { [ZeroStrategyLeg EXCEPT !.legRatio = one] : one \in Sample(4) }
        \cup { [ZeroStrategyLeg EXCEPT !.reserved8 = one] : one \in Sample(8) }

(* A run of Strategy Leg, written one after another *)
RECURSIVE EncodeStrategyLegList(_)
EncodeStrategyLegList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeStrategyLeg(Head(messages)) \o EncodeStrategyLegList(Tail(messages))

(* As many Strategy Leg as the field that counts them says *)
RECURSIVE ReadStrategyLegList(_, _)
ReadStrategyLegList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeStrategyLeg(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadStrategyLegList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Strategy Leg of each kind, for the lists that carry them *)
OneStrategyLeg == { ZeroStrategyLeg }

(***************************************************************************)
(* Strategy Creation Request                                               *)
(***************************************************************************)

StrategyCreationRequest ==
    [ clientSendTime   : Sample(8),
      mpId             : Sample(5),
      operatorId       : Sample(18),
      operatorLocation : Sample(6),
      clientOrderId    : Sample(20),
      reserved16       : Sample(16),
      strategyLeg      : SampleLists(OneStrategyLeg) ]

EncodeStrategyCreationRequest(message) ==
    message.clientSendTime
        \o message.mpId
        \o message.operatorId
        \o message.operatorLocation
        \o message.clientOrderId
        \o message.reserved16
        \o EncodeUIntLE(Len(message.strategyLeg), 1)
        \o EncodeStrategyLegList(message.strategyLeg)

DecodeStrategyCreationRequest(bytes) ==
    LET clientSendTime == ReadBytes(bytes, 8) IN IF ~clientSendTime.ok THEN Fail ELSE
    LET mpId == ReadBytes(clientSendTime.rest, 5) IN IF ~mpId.ok THEN Fail ELSE
    LET operatorId == ReadBytes(mpId.rest, 18) IN IF ~operatorId.ok THEN Fail ELSE
    LET operatorLocation == ReadBytes(operatorId.rest, 6) IN IF ~operatorLocation.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(operatorLocation.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET reserved16 == ReadBytes(clientOrderId.rest, 16) IN IF ~reserved16.ok THEN Fail ELSE
    LET numberOfLegs == ReadUIntLE(reserved16.rest, 1) IN IF ~numberOfLegs.ok THEN Fail ELSE
    LET strategyLeg == ReadStrategyLegList(numberOfLegs.rest, numberOfLegs.value) IN IF ~strategyLeg.ok THEN Fail ELSE
    Ok([ clientSendTime   |-> clientSendTime.value,
         mpId             |-> mpId.value,
         operatorId       |-> operatorId.value,
         operatorLocation |-> operatorLocation.value,
         clientOrderId    |-> clientOrderId.value,
         reserved16       |-> reserved16.value,
         strategyLeg      |-> strategyLeg.value ], strategyLeg.rest)

ZeroStrategyCreationRequest ==
    [ clientSendTime   |-> [i \in 1 .. 8 |-> 0],
      mpId             |-> [i \in 1 .. 5 |-> 0],
      operatorId       |-> [i \in 1 .. 18 |-> 0],
      operatorLocation |-> [i \in 1 .. 6 |-> 0],
      clientOrderId    |-> [i \in 1 .. 20 |-> 0],
      reserved16       |-> [i \in 1 .. 16 |-> 0],
      strategyLeg      |-> << >> ]

(* Strategy Creation Request at zero, then each field in turn at the values it is checked at *)
CheckedStrategyCreationRequest ==
    { ZeroStrategyCreationRequest }
        \cup { [ZeroStrategyCreationRequest EXCEPT !.clientSendTime = one] : one \in Sample(8) }
        \cup { [ZeroStrategyCreationRequest EXCEPT !.mpId = one] : one \in Sample(5) }
        \cup { [ZeroStrategyCreationRequest EXCEPT !.operatorId = one] : one \in Sample(18) }
        \cup { [ZeroStrategyCreationRequest EXCEPT !.operatorLocation = one] : one \in Sample(6) }
        \cup { [ZeroStrategyCreationRequest EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroStrategyCreationRequest EXCEPT !.reserved16 = one] : one \in Sample(16) }
        \cup { [ZeroStrategyCreationRequest EXCEPT !.strategyLeg = one] : one \in SampleLists(OneStrategyLeg) }

(***************************************************************************)
(* Strategy Creation Response Message: 70 bytes                            *)
(***************************************************************************)

StrategyCreationResponseMessage2 ==
    [ matchingEngineTime   : Sample(8),
      mpId                 : Sample(5),
      clientOrderId        : Sample(20),
      instrumentIdString20 : Sample(20),
      status               : Sample(1),
      reserved16           : Sample(16) ]

EncodeStrategyCreationResponseMessage2(message) ==
    message.matchingEngineTime
        \o message.mpId
        \o message.clientOrderId
        \o message.instrumentIdString20
        \o message.status
        \o message.reserved16

DecodeStrategyCreationResponseMessage2(bytes) ==
    LET matchingEngineTime == ReadBytes(bytes, 8) IN IF ~matchingEngineTime.ok THEN Fail ELSE
    LET mpId == ReadBytes(matchingEngineTime.rest, 5) IN IF ~mpId.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(mpId.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET instrumentIdString20 == ReadBytes(clientOrderId.rest, 20) IN IF ~instrumentIdString20.ok THEN Fail ELSE
    LET status == ReadBytes(instrumentIdString20.rest, 1) IN IF ~status.ok THEN Fail ELSE
    LET reserved16 == ReadBytes(status.rest, 16) IN IF ~reserved16.ok THEN Fail ELSE
    Ok([ matchingEngineTime   |-> matchingEngineTime.value,
         mpId                 |-> mpId.value,
         clientOrderId        |-> clientOrderId.value,
         instrumentIdString20 |-> instrumentIdString20.value,
         status               |-> status.value,
         reserved16           |-> reserved16.value ], reserved16.rest)

ZeroStrategyCreationResponseMessage2 ==
    [ matchingEngineTime   |-> [i \in 1 .. 8 |-> 0],
      mpId                 |-> [i \in 1 .. 5 |-> 0],
      clientOrderId        |-> [i \in 1 .. 20 |-> 0],
      instrumentIdString20 |-> [i \in 1 .. 20 |-> 0],
      status               |-> [i \in 1 .. 1 |-> 0],
      reserved16           |-> [i \in 1 .. 16 |-> 0] ]

(* Strategy Creation Response Message at zero, then each field in turn at the values it is checked at *)
CheckedStrategyCreationResponseMessage2 ==
    { ZeroStrategyCreationResponseMessage2 }
        \cup { [ZeroStrategyCreationResponseMessage2 EXCEPT !.matchingEngineTime = one] : one \in Sample(8) }
        \cup { [ZeroStrategyCreationResponseMessage2 EXCEPT !.mpId = one] : one \in Sample(5) }
        \cup { [ZeroStrategyCreationResponseMessage2 EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroStrategyCreationResponseMessage2 EXCEPT !.instrumentIdString20 = one] : one \in Sample(20) }
        \cup { [ZeroStrategyCreationResponseMessage2 EXCEPT !.status = one] : one \in Sample(1) }
        \cup { [ZeroStrategyCreationResponseMessage2 EXCEPT !.reserved16 = one] : one \in Sample(16) }

(***************************************************************************)
(* Unsequenced Message, selected by Unsequenced Message Type               *)
(***************************************************************************)

NewOrderRequestMessageCode == 20017  \* "N1"
NewOrderResponseMessageCode2 == 20050  \* "NR"
ModifyOrderRequestMessageCode == 19761  \* "M1"
ModifyOrderResponseCode2 == 19794  \* "MR"
CancelOrderRequestMessageCode == 17231  \* "CO"
CancelOrderResponseCode2 == 17234  \* "CR"
MassCancelRequestCode == 22609  \* "XQ"
MassCancelResponseCode2 == 22610  \* "XR"
StrategyCreationRequestCode == 21316  \* "SD"
StrategyCreationResponseMessageCode2 == 21330  \* "SR"

UnsequencedMessage ==
    [ tag : {NewOrderRequestMessageCode}, body : NewOrderRequestMessage ]
        \cup [ tag : {NewOrderResponseMessageCode2}, body : NewOrderResponseMessage2 ]
        \cup [ tag : {ModifyOrderRequestMessageCode}, body : ModifyOrderRequestMessage ]
        \cup [ tag : {ModifyOrderResponseCode2}, body : ModifyOrderResponse2 ]
        \cup [ tag : {CancelOrderRequestMessageCode}, body : CancelOrderRequestMessage ]
        \cup [ tag : {CancelOrderResponseCode2}, body : CancelOrderResponse2 ]
        \cup [ tag : {MassCancelRequestCode}, body : MassCancelRequest ]
        \cup [ tag : {MassCancelResponseCode2}, body : MassCancelResponse2 ]
        \cup [ tag : {StrategyCreationRequestCode}, body : StrategyCreationRequest ]
        \cup [ tag : {StrategyCreationResponseMessageCode2}, body : StrategyCreationResponseMessage2 ]

EncodeUnsequencedMessage(message) ==
    CASE message.tag = NewOrderRequestMessageCode -> EncodeNewOrderRequestMessage(message.body)
      [] message.tag = NewOrderResponseMessageCode2 -> EncodeNewOrderResponseMessage2(message.body)
      [] message.tag = ModifyOrderRequestMessageCode -> EncodeModifyOrderRequestMessage(message.body)
      [] message.tag = ModifyOrderResponseCode2 -> EncodeModifyOrderResponse2(message.body)
      [] message.tag = CancelOrderRequestMessageCode -> EncodeCancelOrderRequestMessage(message.body)
      [] message.tag = CancelOrderResponseCode2 -> EncodeCancelOrderResponse2(message.body)
      [] message.tag = MassCancelRequestCode -> EncodeMassCancelRequest(message.body)
      [] message.tag = MassCancelResponseCode2 -> EncodeMassCancelResponse2(message.body)
      [] message.tag = StrategyCreationRequestCode -> EncodeStrategyCreationRequest(message.body)
      [] message.tag = StrategyCreationResponseMessageCode2 -> EncodeStrategyCreationResponseMessage2(message.body)

DecodeUnsequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = NewOrderRequestMessageCode -> DecodeNewOrderRequestMessage(bytes)
              [] tag = NewOrderResponseMessageCode2 -> DecodeNewOrderResponseMessage2(bytes)
              [] tag = ModifyOrderRequestMessageCode -> DecodeModifyOrderRequestMessage(bytes)
              [] tag = ModifyOrderResponseCode2 -> DecodeModifyOrderResponse2(bytes)
              [] tag = CancelOrderRequestMessageCode -> DecodeCancelOrderRequestMessage(bytes)
              [] tag = CancelOrderResponseCode2 -> DecodeCancelOrderResponse2(bytes)
              [] tag = MassCancelRequestCode -> DecodeMassCancelRequest(bytes)
              [] tag = MassCancelResponseCode2 -> DecodeMassCancelResponse2(bytes)
              [] tag = StrategyCreationRequestCode -> DecodeStrategyCreationRequest(bytes)
              [] tag = StrategyCreationResponseMessageCode2 -> DecodeStrategyCreationResponseMessage2(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroUnsequencedMessage == [tag |-> NewOrderRequestMessageCode, body |-> ZeroNewOrderRequestMessage]

(* Each Unsequenced Message in turn, at the values the message it names is checked at *)
CheckedUnsequencedMessage ==
    { [tag |-> NewOrderRequestMessageCode, body |-> one] : one \in CheckedNewOrderRequestMessage }
        \cup { [tag |-> NewOrderResponseMessageCode2, body |-> one] : one \in CheckedNewOrderResponseMessage2 }
        \cup { [tag |-> ModifyOrderRequestMessageCode, body |-> one] : one \in CheckedModifyOrderRequestMessage }
        \cup { [tag |-> ModifyOrderResponseCode2, body |-> one] : one \in CheckedModifyOrderResponse2 }
        \cup { [tag |-> CancelOrderRequestMessageCode, body |-> one] : one \in CheckedCancelOrderRequestMessage }
        \cup { [tag |-> CancelOrderResponseCode2, body |-> one] : one \in CheckedCancelOrderResponse2 }
        \cup { [tag |-> MassCancelRequestCode, body |-> one] : one \in CheckedMassCancelRequest }
        \cup { [tag |-> MassCancelResponseCode2, body |-> one] : one \in CheckedMassCancelResponse2 }
        \cup { [tag |-> StrategyCreationRequestCode, body |-> one] : one \in CheckedStrategyCreationRequest }
        \cup { [tag |-> StrategyCreationResponseMessageCode2, body |-> one] : one \in CheckedStrategyCreationResponseMessage2 }

(***************************************************************************)
(* Unsequenced Data Packet                                                 *)
(***************************************************************************)

UnsequencedDataPacket ==
    [ unsequencedMessage : UnsequencedMessage ]

EncodeUnsequencedDataPacket(message) ==
    EncodeUIntBE(message.unsequencedMessage.tag, 2)
        \o EncodeUnsequencedMessage(message.unsequencedMessage)

DecodeUnsequencedDataPacket(bytes) ==
    LET unsequencedMessageType == ReadUIntBE(bytes, 2) IN IF ~unsequencedMessageType.ok THEN Fail ELSE
    LET unsequencedMessage == DecodeUnsequencedMessage(unsequencedMessageType.value, unsequencedMessageType.rest) IN IF ~unsequencedMessage.ok THEN Fail ELSE
    Ok([ unsequencedMessage |-> unsequencedMessage.value ], unsequencedMessage.rest)

ZeroUnsequencedDataPacket ==
    [ unsequencedMessage |-> ZeroUnsequencedMessage ]

(* Unsequenced Data Packet at zero, then each field in turn at the values it is checked at *)
CheckedUnsequencedDataPacket ==
    { ZeroUnsequencedDataPacket }
        \cup { [ZeroUnsequencedDataPacket EXCEPT !.unsequencedMessage = one] : one \in CheckedUnsequencedMessage }

(***************************************************************************)
(* Login Request: 35 bytes                                                 *)
(***************************************************************************)

LoginRequest ==
    [ sesmVersion             : Sample(5),
      username                : Sample(5),
      computerId              : Sample(8),
      applicationProtocol     : Sample(8),
      requestedSession        : Sample(1),
      requestedSequenceNumber : Sample(8) ]

EncodeLoginRequest(message) ==
    message.sesmVersion
        \o message.username
        \o message.computerId
        \o message.applicationProtocol
        \o message.requestedSession
        \o message.requestedSequenceNumber

DecodeLoginRequest(bytes) ==
    LET sesmVersion == ReadBytes(bytes, 5) IN IF ~sesmVersion.ok THEN Fail ELSE
    LET username == ReadBytes(sesmVersion.rest, 5) IN IF ~username.ok THEN Fail ELSE
    LET computerId == ReadBytes(username.rest, 8) IN IF ~computerId.ok THEN Fail ELSE
    LET applicationProtocol == ReadBytes(computerId.rest, 8) IN IF ~applicationProtocol.ok THEN Fail ELSE
    LET requestedSession == ReadBytes(applicationProtocol.rest, 1) IN IF ~requestedSession.ok THEN Fail ELSE
    LET requestedSequenceNumber == ReadBytes(requestedSession.rest, 8) IN IF ~requestedSequenceNumber.ok THEN Fail ELSE
    Ok([ sesmVersion             |-> sesmVersion.value,
         username                |-> username.value,
         computerId              |-> computerId.value,
         applicationProtocol     |-> applicationProtocol.value,
         requestedSession        |-> requestedSession.value,
         requestedSequenceNumber |-> requestedSequenceNumber.value ], requestedSequenceNumber.rest)

ZeroLoginRequest ==
    [ sesmVersion             |-> [i \in 1 .. 5 |-> 0],
      username                |-> [i \in 1 .. 5 |-> 0],
      computerId              |-> [i \in 1 .. 8 |-> 0],
      applicationProtocol     |-> [i \in 1 .. 8 |-> 0],
      requestedSession        |-> [i \in 1 .. 1 |-> 0],
      requestedSequenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Login Request at zero, then each field in turn at the values it is checked at *)
CheckedLoginRequest ==
    { ZeroLoginRequest }
        \cup { [ZeroLoginRequest EXCEPT !.sesmVersion = one] : one \in Sample(5) }
        \cup { [ZeroLoginRequest EXCEPT !.username = one] : one \in Sample(5) }
        \cup { [ZeroLoginRequest EXCEPT !.computerId = one] : one \in Sample(8) }
        \cup { [ZeroLoginRequest EXCEPT !.applicationProtocol = one] : one \in Sample(8) }
        \cup { [ZeroLoginRequest EXCEPT !.requestedSession = one] : one \in Sample(1) }
        \cup { [ZeroLoginRequest EXCEPT !.requestedSequenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Login Response: 10 bytes                                                *)
(***************************************************************************)

LoginResponse ==
    [ loginStatus           : Sample(1),
      sessionId             : Sample(1),
      highestSequenceNumber : Sample(8) ]

EncodeLoginResponse(message) ==
    message.loginStatus
        \o message.sessionId
        \o message.highestSequenceNumber

DecodeLoginResponse(bytes) ==
    LET loginStatus == ReadBytes(bytes, 1) IN IF ~loginStatus.ok THEN Fail ELSE
    LET sessionId == ReadBytes(loginStatus.rest, 1) IN IF ~sessionId.ok THEN Fail ELSE
    LET highestSequenceNumber == ReadBytes(sessionId.rest, 8) IN IF ~highestSequenceNumber.ok THEN Fail ELSE
    Ok([ loginStatus           |-> loginStatus.value,
         sessionId             |-> sessionId.value,
         highestSequenceNumber |-> highestSequenceNumber.value ], highestSequenceNumber.rest)

ZeroLoginResponse ==
    [ loginStatus           |-> [i \in 1 .. 1 |-> 0],
      sessionId             |-> [i \in 1 .. 1 |-> 0],
      highestSequenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Login Response at zero, then each field in turn at the values it is checked at *)
CheckedLoginResponse ==
    { ZeroLoginResponse }
        \cup { [ZeroLoginResponse EXCEPT !.loginStatus = one] : one \in Sample(1) }
        \cup { [ZeroLoginResponse EXCEPT !.sessionId = one] : one \in Sample(1) }
        \cup { [ZeroLoginResponse EXCEPT !.highestSequenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Retransmission Request: 16 bytes                                        *)
(***************************************************************************)

RetransmissionRequest ==
    [ startSequenceNumber : Sample(8),
      endSequenceNumber   : Sample(8) ]

EncodeRetransmissionRequest(message) ==
    message.startSequenceNumber
        \o message.endSequenceNumber

DecodeRetransmissionRequest(bytes) ==
    LET startSequenceNumber == ReadBytes(bytes, 8) IN IF ~startSequenceNumber.ok THEN Fail ELSE
    LET endSequenceNumber == ReadBytes(startSequenceNumber.rest, 8) IN IF ~endSequenceNumber.ok THEN Fail ELSE
    Ok([ startSequenceNumber |-> startSequenceNumber.value,
         endSequenceNumber   |-> endSequenceNumber.value ], endSequenceNumber.rest)

ZeroRetransmissionRequest ==
    [ startSequenceNumber |-> [i \in 1 .. 8 |-> 0],
      endSequenceNumber   |-> [i \in 1 .. 8 |-> 0] ]

(* Retransmission Request at zero, then each field in turn at the values it is checked at *)
CheckedRetransmissionRequest ==
    { ZeroRetransmissionRequest }
        \cup { [ZeroRetransmissionRequest EXCEPT !.startSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroRetransmissionRequest EXCEPT !.endSequenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Logout Request                                                          *)
(***************************************************************************)

LogoutRequest ==
    [ logoutReason : Sample(1),
      logoutText   : SampleBytes ]

EncodeLogoutRequest(message) ==
    message.logoutReason
        \o message.logoutText

DecodeLogoutRequest(bytes) ==
    LET logoutReason == ReadBytes(bytes, 1) IN IF ~logoutReason.ok THEN Fail ELSE
    LET logoutText == Ok(logoutReason.rest, << >>) IN IF ~logoutText.ok THEN Fail ELSE
    Ok([ logoutReason |-> logoutReason.value,
         logoutText   |-> logoutText.value ], logoutText.rest)

ZeroLogoutRequest ==
    [ logoutReason |-> [i \in 1 .. 1 |-> 0],
      logoutText   |-> << >> ]

(* Logout Request at zero, then each field in turn at the values it is checked at *)
CheckedLogoutRequest ==
    { ZeroLogoutRequest }
        \cup { [ZeroLogoutRequest EXCEPT !.logoutReason = one] : one \in Sample(1) }
        \cup { [ZeroLogoutRequest EXCEPT !.logoutText = one] : one \in SampleBytes }

(***************************************************************************)
(* Goodbye Packet                                                          *)
(***************************************************************************)

GoodbyePacket ==
    [ logoutReason : Sample(1),
      logoutText   : SampleBytes ]

EncodeGoodbyePacket(message) ==
    message.logoutReason
        \o message.logoutText

DecodeGoodbyePacket(bytes) ==
    LET logoutReason == ReadBytes(bytes, 1) IN IF ~logoutReason.ok THEN Fail ELSE
    LET logoutText == Ok(logoutReason.rest, << >>) IN IF ~logoutText.ok THEN Fail ELSE
    Ok([ logoutReason |-> logoutReason.value,
         logoutText   |-> logoutText.value ], logoutText.rest)

ZeroGoodbyePacket ==
    [ logoutReason |-> [i \in 1 .. 1 |-> 0],
      logoutText   |-> << >> ]

(* Goodbye Packet at zero, then each field in turn at the values it is checked at *)
CheckedGoodbyePacket ==
    { ZeroGoodbyePacket }
        \cup { [ZeroGoodbyePacket EXCEPT !.logoutReason = one] : one \in Sample(1) }
        \cup { [ZeroGoodbyePacket EXCEPT !.logoutText = one] : one \in SampleBytes }

(***************************************************************************)
(* Sesm Payload, selected by Sesm Packet Type                              *)
(***************************************************************************)

SequencedDataPacketCode == 83  \* "S"
UnsequencedDataPacketCode == 85  \* "U"
LoginRequestCode == 76  \* "L"
LoginResponseCode == 82  \* "R"
SynchronizationCompleteCode == 67  \* "C"
RetransmissionRequestCode == 65  \* "A"
LogoutRequestCode == 88  \* "X"
GoodbyePacketCode == 71  \* "G"
EndOfSessionCode == 69  \* "E"
ServerHeartbeatCode == 48  \* "0"
ClientHeartbeatCode == 49  \* "1"

SesmPayload ==
    [ tag : {SequencedDataPacketCode}, body : SequencedDataPacket ]
        \cup [ tag : {UnsequencedDataPacketCode}, body : UnsequencedDataPacket ]
        \cup [ tag : {LoginRequestCode}, body : LoginRequest ]
        \cup [ tag : {LoginResponseCode}, body : LoginResponse ]
        \cup [ tag : {SynchronizationCompleteCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {RetransmissionRequestCode}, body : RetransmissionRequest ]
        \cup [ tag : {LogoutRequestCode}, body : LogoutRequest ]
        \cup [ tag : {GoodbyePacketCode}, body : GoodbyePacket ]
        \cup [ tag : {EndOfSessionCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ServerHeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ClientHeartbeatCode}, body : {[empty |-> 0]} ]

EncodeSesmPayload(message) ==
    CASE message.tag = SequencedDataPacketCode -> EncodeSequencedDataPacket(message.body)
      [] message.tag = UnsequencedDataPacketCode -> EncodeUnsequencedDataPacket(message.body)
      [] message.tag = LoginRequestCode -> EncodeLoginRequest(message.body)
      [] message.tag = LoginResponseCode -> EncodeLoginResponse(message.body)
      [] message.tag = SynchronizationCompleteCode -> << >>
      [] message.tag = RetransmissionRequestCode -> EncodeRetransmissionRequest(message.body)
      [] message.tag = LogoutRequestCode -> EncodeLogoutRequest(message.body)
      [] message.tag = GoodbyePacketCode -> EncodeGoodbyePacket(message.body)
      [] message.tag = EndOfSessionCode -> << >>
      [] message.tag = ServerHeartbeatCode -> << >>
      [] message.tag = ClientHeartbeatCode -> << >>

DecodeSesmPayload(tag, bytes) ==
    LET read ==
            CASE tag = SequencedDataPacketCode -> DecodeSequencedDataPacket(bytes)
              [] tag = UnsequencedDataPacketCode -> DecodeUnsequencedDataPacket(bytes)
              [] tag = LoginRequestCode -> DecodeLoginRequest(bytes)
              [] tag = LoginResponseCode -> DecodeLoginResponse(bytes)
              [] tag = SynchronizationCompleteCode -> Ok([empty |-> 0], bytes)
              [] tag = RetransmissionRequestCode -> DecodeRetransmissionRequest(bytes)
              [] tag = LogoutRequestCode -> DecodeLogoutRequest(bytes)
              [] tag = GoodbyePacketCode -> DecodeGoodbyePacket(bytes)
              [] tag = EndOfSessionCode -> Ok([empty |-> 0], bytes)
              [] tag = ServerHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = ClientHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSesmPayload == [tag |-> SequencedDataPacketCode, body |-> ZeroSequencedDataPacket]

(* Each Sesm Payload in turn, at the values the message it names is checked at *)
CheckedSesmPayload ==
    { [tag |-> SequencedDataPacketCode, body |-> one] : one \in CheckedSequencedDataPacket }
        \cup { [tag |-> UnsequencedDataPacketCode, body |-> one] : one \in CheckedUnsequencedDataPacket }
        \cup { [tag |-> LoginRequestCode, body |-> one] : one \in CheckedLoginRequest }
        \cup { [tag |-> LoginResponseCode, body |-> one] : one \in CheckedLoginResponse }
        \cup { [tag |-> SynchronizationCompleteCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> RetransmissionRequestCode, body |-> one] : one \in CheckedRetransmissionRequest }
        \cup { [tag |-> LogoutRequestCode, body |-> one] : one \in CheckedLogoutRequest }
        \cup { [tag |-> GoodbyePacketCode, body |-> one] : one \in CheckedGoodbyePacket }
        \cup { [tag |-> EndOfSessionCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> ServerHeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> ClientHeartbeatCode, body |-> [empty |-> 0]] }

(***************************************************************************)
(* Sesm Tcp Packet, framed by Sesm Packet Length                           *)
(***************************************************************************)

SesmTcpPacket ==
    [ sesmPayload : SesmPayload ]

EncodeSesmTcpPacketBody(message) ==
    EncodeUIntBE(message.sesmPayload.tag, 1)
        \o EncodeSesmPayload(message.sesmPayload)

(* Sesm Packet Length counts the bytes it frames, so it is written from them *)
EncodeSesmTcpPacket(message) ==
    LET body == EncodeSesmTcpPacketBody(message)
    IN  EncodeUIntLE(Len(body), 2) \o body

DecodeSesmTcpPacketBody(bytes) ==
    LET sesmPacketType == ReadUIntBE(bytes, 1) IN IF ~sesmPacketType.ok THEN Fail ELSE
    LET sesmPayload == DecodeSesmPayload(sesmPacketType.value, sesmPacketType.rest) IN IF ~sesmPayload.ok THEN Fail ELSE
    Ok([ sesmPayload |-> sesmPayload.value ], sesmPayload.rest)

DecodeSesmTcpPacket(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeSesmTcpPacketBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroSesmTcpPacket ==
    [ sesmPayload |-> ZeroSesmPayload ]

(* Sesm Tcp Packet at zero, then each field in turn at the values it is checked at *)
CheckedSesmTcpPacket ==
    { ZeroSesmTcpPacket }
        \cup { [ZeroSesmTcpPacket EXCEPT !.sesmPayload = one] : one \in CheckedSesmPayload }

(* A run of Sesm Tcp Packet, written one after another *)
RECURSIVE EncodeSesmTcpPacketList(_)
EncodeSesmTcpPacketList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSesmTcpPacket(Head(messages)) \o EncodeSesmTcpPacketList(Tail(messages))

(* As many Sesm Tcp Packet as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadSesmTcpPacketAll(_)
ReadSesmTcpPacketAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeSesmTcpPacket(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSesmTcpPacketAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Sesm Tcp Packet of each kind, for the lists that carry them *)
OneSesmTcpPacket ==
    { [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> SequencedDataPacketCode, body |-> ZeroSequencedDataPacket]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> UnsequencedDataPacketCode, body |-> ZeroUnsequencedDataPacket]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> LoginRequestCode, body |-> ZeroLoginRequest]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> LoginResponseCode, body |-> ZeroLoginResponse]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> SynchronizationCompleteCode, body |-> [empty |-> 0]]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> RetransmissionRequestCode, body |-> ZeroRetransmissionRequest]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> LogoutRequestCode, body |-> ZeroLogoutRequest]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> GoodbyePacketCode, body |-> ZeroGoodbyePacket]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> EndOfSessionCode, body |-> [empty |-> 0]]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> ServerHeartbeatCode, body |-> [empty |-> 0]]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> ClientHeartbeatCode, body |-> [empty |-> 0]]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ sesmTcpPacket : SampleLists(OneSesmTcpPacket) ]

EncodePacket(message) ==
    EncodeSesmTcpPacketList(message.sesmTcpPacket)

DecodePacket(bytes) ==
    LET sesmTcpPacket == ReadSesmTcpPacketAll(bytes) IN IF ~sesmTcpPacket.ok THEN Fail ELSE
    Ok([ sesmTcpPacket |-> sesmTcpPacket.value ], sesmTcpPacket.rest)

ZeroPacket ==
    [ sesmTcpPacket |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.sesmTcpPacket = one] : one \in SampleLists(OneSesmTcpPacket) }

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

(* Every New Order Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderResponseMessage ==
    \A message \in CheckedNewOrderResponseMessage :
        LET read == DecodeNewOrderResponseMessage(EncodeNewOrderResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Order Response decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyOrderResponse ==
    \A message \in CheckedModifyOrderResponse :
        LET read == DecodeModifyOrderResponse(EncodeModifyOrderResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Order Response decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelOrderResponse ==
    \A message \in CheckedCancelOrderResponse :
        LET read == DecodeCancelOrderResponse(EncodeCancelOrderResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Cancel Response decodes back to what was encoded, and leaves nothing over *)
RoundTripMassCancelResponse ==
    \A message \in CheckedMassCancelResponse :
        LET read == DecodeMassCancelResponse(EncodeMassCancelResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Creation Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyCreationResponseMessage ==
    \A message \in CheckedStrategyCreationResponseMessage :
        LET read == DecodeStrategyCreationResponseMessage(EncodeStrategyCreationResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every System State Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSystemStateNotificationMessage ==
    \A message \in CheckedSystemStateNotificationMessage :
        LET read == DecodeSystemStateNotificationMessage(EncodeSystemStateNotificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderNotification ==
    \A message \in CheckedNewOrderNotification :
        LET read == DecodeNewOrderNotification(EncodeNewOrderNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Order Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyOrderNotification ==
    \A message \in CheckedModifyOrderNotification :
        LET read == DecodeModifyOrderNotification(EncodeModifyOrderNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Reduce Size Order Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelReduceSizeOrderNotification ==
    \A message \in CheckedCancelReduceSizeOrderNotification :
        LET read == DecodeCancelReduceSizeOrderNotification(EncodeCancelReduceSizeOrderNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Status Update Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderStatusUpdateNotification ==
    \A message \in CheckedOrderStatusUpdateNotification :
        LET read == DecodeOrderStatusUpdateNotification(EncodeOrderStatusUpdateNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Execution Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleExecutionNotification ==
    \A message \in CheckedSimpleExecutionNotification :
        LET read == DecodeSimpleExecutionNotification(EncodeSimpleExecutionNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Execution Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexExecutionNotification ==
    \A message \in CheckedComplexExecutionNotification :
        LET read == DecodeComplexExecutionNotification(EncodeComplexExecutionNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sequenced Data Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripSequencedDataPacket ==
    \A message \in CheckedSequencedDataPacket :
        LET read == DecodeSequencedDataPacket(EncodeSequencedDataPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderRequestMessage ==
    \A message \in CheckedNewOrderRequestMessage :
        LET read == DecodeNewOrderRequestMessage(EncodeNewOrderRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderResponseMessage2 ==
    \A message \in CheckedNewOrderResponseMessage2 :
        LET read == DecodeNewOrderResponseMessage2(EncodeNewOrderResponseMessage2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Order Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyOrderRequestMessage ==
    \A message \in CheckedModifyOrderRequestMessage :
        LET read == DecodeModifyOrderRequestMessage(EncodeModifyOrderRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Order Response decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyOrderResponse2 ==
    \A message \in CheckedModifyOrderResponse2 :
        LET read == DecodeModifyOrderResponse2(EncodeModifyOrderResponse2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Order Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelOrderRequestMessage ==
    \A message \in CheckedCancelOrderRequestMessage :
        LET read == DecodeCancelOrderRequestMessage(EncodeCancelOrderRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Order Response decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelOrderResponse2 ==
    \A message \in CheckedCancelOrderResponse2 :
        LET read == DecodeCancelOrderResponse2(EncodeCancelOrderResponse2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Cancel Request decodes back to what was encoded, and leaves nothing over *)
RoundTripMassCancelRequest ==
    \A message \in CheckedMassCancelRequest :
        LET read == DecodeMassCancelRequest(EncodeMassCancelRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Cancel Response decodes back to what was encoded, and leaves nothing over *)
RoundTripMassCancelResponse2 ==
    \A message \in CheckedMassCancelResponse2 :
        LET read == DecodeMassCancelResponse2(EncodeMassCancelResponse2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Leg decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyLeg ==
    \A message \in CheckedStrategyLeg :
        LET read == DecodeStrategyLeg(EncodeStrategyLeg(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Creation Request decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyCreationRequest ==
    \A message \in CheckedStrategyCreationRequest :
        LET read == DecodeStrategyCreationRequest(EncodeStrategyCreationRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Creation Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyCreationResponseMessage2 ==
    \A message \in CheckedStrategyCreationResponseMessage2 :
        LET read == DecodeStrategyCreationResponseMessage2(EncodeStrategyCreationResponseMessage2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Unsequenced Data Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripUnsequencedDataPacket ==
    \A message \in CheckedUnsequencedDataPacket :
        LET read == DecodeUnsequencedDataPacket(EncodeUnsequencedDataPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Request decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRequest ==
    \A message \in CheckedLoginRequest :
        LET read == DecodeLoginRequest(EncodeLoginRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Response decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginResponse ==
    \A message \in CheckedLoginResponse :
        LET read == DecodeLoginResponse(EncodeLoginResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Retransmission Request decodes back to what was encoded, and leaves nothing over *)
RoundTripRetransmissionRequest ==
    \A message \in CheckedRetransmissionRequest :
        LET read == DecodeRetransmissionRequest(EncodeRetransmissionRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logout Request decodes back to what was encoded, and leaves nothing over *)
RoundTripLogoutRequest ==
    \A message \in CheckedLogoutRequest :
        LET read == DecodeLogoutRequest(EncodeLogoutRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Goodbye Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripGoodbyePacket ==
    \A message \in CheckedGoodbyePacket :
        LET read == DecodeGoodbyePacket(EncodeGoodbyePacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sesm Tcp Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripSesmTcpPacket ==
    \A message \in CheckedSesmTcpPacket :
        LET read == DecodeSesmTcpPacket(EncodeSesmTcpPacket(message))
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

(* A Sequenced Message is selected by the Sequenced Message Type it is written under *)
SelectsSequencedMessage ==
    \A message \in CheckedSequencedMessage :
        LET read == DecodeSequencedMessage(message.tag, EncodeSequencedMessage(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Unsequenced Message is selected by the Unsequenced Message Type it is written under *)
SelectsUnsequencedMessage ==
    \A message \in CheckedUnsequencedMessage :
        LET read == DecodeUnsequencedMessage(message.tag, EncodeUnsequencedMessage(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Sesm Payload is selected by the Sesm Packet Type it is written under *)
SelectsSesmPayload ==
    \A message \in CheckedSesmPayload :
        LET read == DecodeSesmPayload(message.tag, EncodeSesmPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Sesm Packet Length is written from the bytes it frames *)
FramesSesmTcpPacket ==
    \A message \in CheckedSesmTcpPacket :
        LET bytes == EncodeSesmTcpPacket(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
