--------------------- MODULE JnxBonds_Pts_v2_01_Server ---------------------
(***************************************************************************)
(* Japannext Securities  v2.01                                             *)
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
(* Note: Sequenced Data Packet fills what is left of the frame Packet      *)
(* Length states, which is what it is read from.                           *)
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
(* Debug Packet                                                            *)
(***************************************************************************)

DebugPacket ==
    [ debugText : SampleBytes ]

EncodeDebugPacket(message) ==
    message.debugText

DecodeDebugPacket(bytes) ==
    LET debugText == Ok(bytes, << >>) IN IF ~debugText.ok THEN Fail ELSE
    Ok([ debugText |-> debugText.value ], debugText.rest)

ZeroDebugPacket ==
    [ debugText |-> << >> ]

(* Debug Packet at zero, then each field in turn at the values it is checked at *)
CheckedDebugPacket ==
    { ZeroDebugPacket }
        \cup { [ZeroDebugPacket EXCEPT !.debugText = one] : one \in SampleBytes }

(***************************************************************************)
(* Login Accepted Packet: 30 bytes                                         *)
(***************************************************************************)

LoginAcceptedPacket ==
    [ acceptedSession        : Sample(10),
      acceptedSequenceNumber : Sample(20) ]

EncodeLoginAcceptedPacket(message) ==
    message.acceptedSession
        \o message.acceptedSequenceNumber

DecodeLoginAcceptedPacket(bytes) ==
    LET acceptedSession == ReadBytes(bytes, 10) IN IF ~acceptedSession.ok THEN Fail ELSE
    LET acceptedSequenceNumber == ReadBytes(acceptedSession.rest, 20) IN IF ~acceptedSequenceNumber.ok THEN Fail ELSE
    Ok([ acceptedSession        |-> acceptedSession.value,
         acceptedSequenceNumber |-> acceptedSequenceNumber.value ], acceptedSequenceNumber.rest)

ZeroLoginAcceptedPacket ==
    [ acceptedSession        |-> [i \in 1 .. 10 |-> 0],
      acceptedSequenceNumber |-> [i \in 1 .. 20 |-> 0] ]

(* Login Accepted Packet at zero, then each field in turn at the values it is checked at *)
CheckedLoginAcceptedPacket ==
    { ZeroLoginAcceptedPacket }
        \cup { [ZeroLoginAcceptedPacket EXCEPT !.acceptedSession = one] : one \in Sample(10) }
        \cup { [ZeroLoginAcceptedPacket EXCEPT !.acceptedSequenceNumber = one] : one \in Sample(20) }

(***************************************************************************)
(* Login Rejected Packet: 1 bytes                                          *)
(***************************************************************************)

LoginRejectedPacket ==
    [ rejectReasonCode : Sample(1) ]

EncodeLoginRejectedPacket(message) ==
    message.rejectReasonCode

DecodeLoginRejectedPacket(bytes) ==
    LET rejectReasonCode == ReadBytes(bytes, 1) IN IF ~rejectReasonCode.ok THEN Fail ELSE
    Ok([ rejectReasonCode |-> rejectReasonCode.value ], rejectReasonCode.rest)

ZeroLoginRejectedPacket ==
    [ rejectReasonCode |-> [i \in 1 .. 1 |-> 0] ]

(* Login Rejected Packet at zero, then each field in turn at the values it is checked at *)
CheckedLoginRejectedPacket ==
    { ZeroLoginRejectedPacket }
        \cup { [ZeroLoginRejectedPacket EXCEPT !.rejectReasonCode = one] : one \in Sample(1) }

(***************************************************************************)
(* System Event Message: 9 bytes                                           *)
(***************************************************************************)

SystemEventMessage ==
    [ timestamp   : Sample(8),
      systemEvent : Sample(1) ]

EncodeSystemEventMessage(message) ==
    message.timestamp
        \o message.systemEvent

DecodeSystemEventMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET systemEvent == ReadBytes(timestamp.rest, 1) IN IF ~systemEvent.ok THEN Fail ELSE
    Ok([ timestamp   |-> timestamp.value,
         systemEvent |-> systemEvent.value ], systemEvent.rest)

ZeroSystemEventMessage ==
    [ timestamp   |-> [i \in 1 .. 8 |-> 0],
      systemEvent |-> [i \in 1 .. 1 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSystemEventMessage EXCEPT !.systemEvent = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Accepted Message: 64 bytes                                        *)
(***************************************************************************)

OrderAcceptedMessage ==
    [ timestamp           : Sample(8),
      orderToken          : Sample(4),
      clientReference     : Sample(10),
      buySellIndicator    : Sample(1),
      quantity            : Sample(4),
      orderbookId         : Sample(4),
      group               : Sample(4),
      price               : Sample(4),
      timeInForce         : Sample(4),
      firmId              : Sample(4),
      display             : Sample(1),
      capacity            : Sample(1),
      orderNumber         : Sample(8),
      minimumQuantity     : Sample(4),
      orderState          : Sample(1),
      orderClassification : Sample(1),
      cashMarginType      : Sample(1) ]

EncodeOrderAcceptedMessage(message) ==
    message.timestamp
        \o message.orderToken
        \o message.clientReference
        \o message.buySellIndicator
        \o message.quantity
        \o message.orderbookId
        \o message.group
        \o message.price
        \o message.timeInForce
        \o message.firmId
        \o message.display
        \o message.capacity
        \o message.orderNumber
        \o message.minimumQuantity
        \o message.orderState
        \o message.orderClassification
        \o message.cashMarginType

DecodeOrderAcceptedMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderToken == ReadBytes(timestamp.rest, 4) IN IF ~orderToken.ok THEN Fail ELSE
    LET clientReference == ReadBytes(orderToken.rest, 10) IN IF ~clientReference.ok THEN Fail ELSE
    LET buySellIndicator == ReadBytes(clientReference.rest, 1) IN IF ~buySellIndicator.ok THEN Fail ELSE
    LET quantity == ReadBytes(buySellIndicator.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET orderbookId == ReadBytes(quantity.rest, 4) IN IF ~orderbookId.ok THEN Fail ELSE
    LET group == ReadBytes(orderbookId.rest, 4) IN IF ~group.ok THEN Fail ELSE
    LET price == ReadBytes(group.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(price.rest, 4) IN IF ~timeInForce.ok THEN Fail ELSE
    LET firmId == ReadBytes(timeInForce.rest, 4) IN IF ~firmId.ok THEN Fail ELSE
    LET display == ReadBytes(firmId.rest, 1) IN IF ~display.ok THEN Fail ELSE
    LET capacity == ReadBytes(display.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(capacity.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET minimumQuantity == ReadBytes(orderNumber.rest, 4) IN IF ~minimumQuantity.ok THEN Fail ELSE
    LET orderState == ReadBytes(minimumQuantity.rest, 1) IN IF ~orderState.ok THEN Fail ELSE
    LET orderClassification == ReadBytes(orderState.rest, 1) IN IF ~orderClassification.ok THEN Fail ELSE
    LET cashMarginType == ReadBytes(orderClassification.rest, 1) IN IF ~cashMarginType.ok THEN Fail ELSE
    Ok([ timestamp           |-> timestamp.value,
         orderToken          |-> orderToken.value,
         clientReference     |-> clientReference.value,
         buySellIndicator    |-> buySellIndicator.value,
         quantity            |-> quantity.value,
         orderbookId         |-> orderbookId.value,
         group               |-> group.value,
         price               |-> price.value,
         timeInForce         |-> timeInForce.value,
         firmId              |-> firmId.value,
         display             |-> display.value,
         capacity            |-> capacity.value,
         orderNumber         |-> orderNumber.value,
         minimumQuantity     |-> minimumQuantity.value,
         orderState          |-> orderState.value,
         orderClassification |-> orderClassification.value,
         cashMarginType      |-> cashMarginType.value ], cashMarginType.rest)

ZeroOrderAcceptedMessage ==
    [ timestamp           |-> [i \in 1 .. 8 |-> 0],
      orderToken          |-> [i \in 1 .. 4 |-> 0],
      clientReference     |-> [i \in 1 .. 10 |-> 0],
      buySellIndicator    |-> [i \in 1 .. 1 |-> 0],
      quantity            |-> [i \in 1 .. 4 |-> 0],
      orderbookId         |-> [i \in 1 .. 4 |-> 0],
      group               |-> [i \in 1 .. 4 |-> 0],
      price               |-> [i \in 1 .. 4 |-> 0],
      timeInForce         |-> [i \in 1 .. 4 |-> 0],
      firmId              |-> [i \in 1 .. 4 |-> 0],
      display             |-> [i \in 1 .. 1 |-> 0],
      capacity            |-> [i \in 1 .. 1 |-> 0],
      orderNumber         |-> [i \in 1 .. 8 |-> 0],
      minimumQuantity     |-> [i \in 1 .. 4 |-> 0],
      orderState          |-> [i \in 1 .. 1 |-> 0],
      orderClassification |-> [i \in 1 .. 1 |-> 0],
      cashMarginType      |-> [i \in 1 .. 1 |-> 0] ]

(* Order Accepted Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderAcceptedMessage ==
    { ZeroOrderAcceptedMessage }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.orderToken = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.clientReference = one] : one \in Sample(10) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.buySellIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.orderbookId = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.group = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.timeInForce = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.firmId = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.display = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.minimumQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.orderState = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.orderClassification = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.cashMarginType = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Replaced Message: 51 bytes                                        *)
(***************************************************************************)

OrderReplacedMessage ==
    [ timestamp             : Sample(8),
      replacementOrderToken : Sample(4),
      buySellIndicator      : Sample(1),
      quantity              : Sample(4),
      orderbookId           : Sample(4),
      group                 : Sample(4),
      price                 : Sample(4),
      timeInForce           : Sample(4),
      display               : Sample(1),
      orderNumber           : Sample(8),
      minimumQuantity       : Sample(4),
      orderState            : Sample(1),
      previousOrderToken    : Sample(4) ]

EncodeOrderReplacedMessage(message) ==
    message.timestamp
        \o message.replacementOrderToken
        \o message.buySellIndicator
        \o message.quantity
        \o message.orderbookId
        \o message.group
        \o message.price
        \o message.timeInForce
        \o message.display
        \o message.orderNumber
        \o message.minimumQuantity
        \o message.orderState
        \o message.previousOrderToken

DecodeOrderReplacedMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET replacementOrderToken == ReadBytes(timestamp.rest, 4) IN IF ~replacementOrderToken.ok THEN Fail ELSE
    LET buySellIndicator == ReadBytes(replacementOrderToken.rest, 1) IN IF ~buySellIndicator.ok THEN Fail ELSE
    LET quantity == ReadBytes(buySellIndicator.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET orderbookId == ReadBytes(quantity.rest, 4) IN IF ~orderbookId.ok THEN Fail ELSE
    LET group == ReadBytes(orderbookId.rest, 4) IN IF ~group.ok THEN Fail ELSE
    LET price == ReadBytes(group.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(price.rest, 4) IN IF ~timeInForce.ok THEN Fail ELSE
    LET display == ReadBytes(timeInForce.rest, 1) IN IF ~display.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(display.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET minimumQuantity == ReadBytes(orderNumber.rest, 4) IN IF ~minimumQuantity.ok THEN Fail ELSE
    LET orderState == ReadBytes(minimumQuantity.rest, 1) IN IF ~orderState.ok THEN Fail ELSE
    LET previousOrderToken == ReadBytes(orderState.rest, 4) IN IF ~previousOrderToken.ok THEN Fail ELSE
    Ok([ timestamp             |-> timestamp.value,
         replacementOrderToken |-> replacementOrderToken.value,
         buySellIndicator      |-> buySellIndicator.value,
         quantity              |-> quantity.value,
         orderbookId           |-> orderbookId.value,
         group                 |-> group.value,
         price                 |-> price.value,
         timeInForce           |-> timeInForce.value,
         display               |-> display.value,
         orderNumber           |-> orderNumber.value,
         minimumQuantity       |-> minimumQuantity.value,
         orderState            |-> orderState.value,
         previousOrderToken    |-> previousOrderToken.value ], previousOrderToken.rest)

ZeroOrderReplacedMessage ==
    [ timestamp             |-> [i \in 1 .. 8 |-> 0],
      replacementOrderToken |-> [i \in 1 .. 4 |-> 0],
      buySellIndicator      |-> [i \in 1 .. 1 |-> 0],
      quantity              |-> [i \in 1 .. 4 |-> 0],
      orderbookId           |-> [i \in 1 .. 4 |-> 0],
      group                 |-> [i \in 1 .. 4 |-> 0],
      price                 |-> [i \in 1 .. 4 |-> 0],
      timeInForce           |-> [i \in 1 .. 4 |-> 0],
      display               |-> [i \in 1 .. 1 |-> 0],
      orderNumber           |-> [i \in 1 .. 8 |-> 0],
      minimumQuantity       |-> [i \in 1 .. 4 |-> 0],
      orderState            |-> [i \in 1 .. 1 |-> 0],
      previousOrderToken    |-> [i \in 1 .. 4 |-> 0] ]

(* Order Replaced Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderReplacedMessage ==
    { ZeroOrderReplacedMessage }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.replacementOrderToken = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.buySellIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.orderbookId = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.group = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.timeInForce = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.display = one] : one \in Sample(1) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.minimumQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.orderState = one] : one \in Sample(1) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.previousOrderToken = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Canceled Message: 17 bytes                                        *)
(***************************************************************************)

OrderCanceledMessage ==
    [ timestamp           : Sample(8),
      orderToken          : Sample(4),
      decrementQuantity   : Sample(4),
      orderCanceledReason : Sample(1) ]

EncodeOrderCanceledMessage(message) ==
    message.timestamp
        \o message.orderToken
        \o message.decrementQuantity
        \o message.orderCanceledReason

DecodeOrderCanceledMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderToken == ReadBytes(timestamp.rest, 4) IN IF ~orderToken.ok THEN Fail ELSE
    LET decrementQuantity == ReadBytes(orderToken.rest, 4) IN IF ~decrementQuantity.ok THEN Fail ELSE
    LET orderCanceledReason == ReadBytes(decrementQuantity.rest, 1) IN IF ~orderCanceledReason.ok THEN Fail ELSE
    Ok([ timestamp           |-> timestamp.value,
         orderToken          |-> orderToken.value,
         decrementQuantity   |-> decrementQuantity.value,
         orderCanceledReason |-> orderCanceledReason.value ], orderCanceledReason.rest)

ZeroOrderCanceledMessage ==
    [ timestamp           |-> [i \in 1 .. 8 |-> 0],
      orderToken          |-> [i \in 1 .. 4 |-> 0],
      decrementQuantity   |-> [i \in 1 .. 4 |-> 0],
      orderCanceledReason |-> [i \in 1 .. 1 |-> 0] ]

(* Order Canceled Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCanceledMessage ==
    { ZeroOrderCanceledMessage }
        \cup { [ZeroOrderCanceledMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderCanceledMessage EXCEPT !.orderToken = one] : one \in Sample(4) }
        \cup { [ZeroOrderCanceledMessage EXCEPT !.decrementQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderCanceledMessage EXCEPT !.orderCanceledReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Aiq Canceled Message: 26 bytes                                    *)
(***************************************************************************)

OrderAiqCanceledMessage ==
    [ timestamp                    : Sample(8),
      orderToken                   : Sample(4),
      decrementQuantity            : Sample(4),
      orderCanceledReason          : Sample(1),
      quantityPreventedFromTrading : Sample(4),
      executionPrice               : Sample(4),
      liquidityIndicator           : Sample(1) ]

EncodeOrderAiqCanceledMessage(message) ==
    message.timestamp
        \o message.orderToken
        \o message.decrementQuantity
        \o message.orderCanceledReason
        \o message.quantityPreventedFromTrading
        \o message.executionPrice
        \o message.liquidityIndicator

DecodeOrderAiqCanceledMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderToken == ReadBytes(timestamp.rest, 4) IN IF ~orderToken.ok THEN Fail ELSE
    LET decrementQuantity == ReadBytes(orderToken.rest, 4) IN IF ~decrementQuantity.ok THEN Fail ELSE
    LET orderCanceledReason == ReadBytes(decrementQuantity.rest, 1) IN IF ~orderCanceledReason.ok THEN Fail ELSE
    LET quantityPreventedFromTrading == ReadBytes(orderCanceledReason.rest, 4) IN IF ~quantityPreventedFromTrading.ok THEN Fail ELSE
    LET executionPrice == ReadBytes(quantityPreventedFromTrading.rest, 4) IN IF ~executionPrice.ok THEN Fail ELSE
    LET liquidityIndicator == ReadBytes(executionPrice.rest, 1) IN IF ~liquidityIndicator.ok THEN Fail ELSE
    Ok([ timestamp                    |-> timestamp.value,
         orderToken                   |-> orderToken.value,
         decrementQuantity            |-> decrementQuantity.value,
         orderCanceledReason          |-> orderCanceledReason.value,
         quantityPreventedFromTrading |-> quantityPreventedFromTrading.value,
         executionPrice               |-> executionPrice.value,
         liquidityIndicator           |-> liquidityIndicator.value ], liquidityIndicator.rest)

ZeroOrderAiqCanceledMessage ==
    [ timestamp                    |-> [i \in 1 .. 8 |-> 0],
      orderToken                   |-> [i \in 1 .. 4 |-> 0],
      decrementQuantity            |-> [i \in 1 .. 4 |-> 0],
      orderCanceledReason          |-> [i \in 1 .. 1 |-> 0],
      quantityPreventedFromTrading |-> [i \in 1 .. 4 |-> 0],
      executionPrice               |-> [i \in 1 .. 4 |-> 0],
      liquidityIndicator           |-> [i \in 1 .. 1 |-> 0] ]

(* Order Aiq Canceled Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderAiqCanceledMessage ==
    { ZeroOrderAiqCanceledMessage }
        \cup { [ZeroOrderAiqCanceledMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderAiqCanceledMessage EXCEPT !.orderToken = one] : one \in Sample(4) }
        \cup { [ZeroOrderAiqCanceledMessage EXCEPT !.decrementQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderAiqCanceledMessage EXCEPT !.orderCanceledReason = one] : one \in Sample(1) }
        \cup { [ZeroOrderAiqCanceledMessage EXCEPT !.quantityPreventedFromTrading = one] : one \in Sample(4) }
        \cup { [ZeroOrderAiqCanceledMessage EXCEPT !.executionPrice = one] : one \in Sample(4) }
        \cup { [ZeroOrderAiqCanceledMessage EXCEPT !.liquidityIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Executed With Counter Party Message: 41 bytes                     *)
(***************************************************************************)

OrderExecutedWithCounterPartyMessage ==
    [ timestamp          : Sample(8),
      orderToken         : Sample(4),
      executedQuantity   : Sample(4),
      executionPrice     : Sample(4),
      liquidityIndicator : Sample(1),
      counterParty       : Sample(12),
      matchNumber        : Sample(8) ]

EncodeOrderExecutedWithCounterPartyMessage(message) ==
    message.timestamp
        \o message.orderToken
        \o message.executedQuantity
        \o message.executionPrice
        \o message.liquidityIndicator
        \o message.counterParty
        \o message.matchNumber

DecodeOrderExecutedWithCounterPartyMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderToken == ReadBytes(timestamp.rest, 4) IN IF ~orderToken.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(orderToken.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET executionPrice == ReadBytes(executedQuantity.rest, 4) IN IF ~executionPrice.ok THEN Fail ELSE
    LET liquidityIndicator == ReadBytes(executionPrice.rest, 1) IN IF ~liquidityIndicator.ok THEN Fail ELSE
    LET counterParty == ReadBytes(liquidityIndicator.rest, 12) IN IF ~counterParty.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(counterParty.rest, 8) IN IF ~matchNumber.ok THEN Fail ELSE
    Ok([ timestamp          |-> timestamp.value,
         orderToken         |-> orderToken.value,
         executedQuantity   |-> executedQuantity.value,
         executionPrice     |-> executionPrice.value,
         liquidityIndicator |-> liquidityIndicator.value,
         counterParty       |-> counterParty.value,
         matchNumber        |-> matchNumber.value ], matchNumber.rest)

ZeroOrderExecutedWithCounterPartyMessage ==
    [ timestamp          |-> [i \in 1 .. 8 |-> 0],
      orderToken         |-> [i \in 1 .. 4 |-> 0],
      executedQuantity   |-> [i \in 1 .. 4 |-> 0],
      executionPrice     |-> [i \in 1 .. 4 |-> 0],
      liquidityIndicator |-> [i \in 1 .. 1 |-> 0],
      counterParty       |-> [i \in 1 .. 12 |-> 0],
      matchNumber        |-> [i \in 1 .. 8 |-> 0] ]

(* Order Executed With Counter Party Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedWithCounterPartyMessage ==
    { ZeroOrderExecutedWithCounterPartyMessage }
        \cup { [ZeroOrderExecutedWithCounterPartyMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedWithCounterPartyMessage EXCEPT !.orderToken = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithCounterPartyMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithCounterPartyMessage EXCEPT !.executionPrice = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithCounterPartyMessage EXCEPT !.liquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutedWithCounterPartyMessage EXCEPT !.counterParty = one] : one \in Sample(12) }
        \cup { [ZeroOrderExecutedWithCounterPartyMessage EXCEPT !.matchNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Rejected Message: 13 bytes                                        *)
(***************************************************************************)

OrderRejectedMessage ==
    [ timestamp           : Sample(8),
      orderToken          : Sample(4),
      orderRejectedReason : Sample(1) ]

EncodeOrderRejectedMessage(message) ==
    message.timestamp
        \o message.orderToken
        \o message.orderRejectedReason

DecodeOrderRejectedMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderToken == ReadBytes(timestamp.rest, 4) IN IF ~orderToken.ok THEN Fail ELSE
    LET orderRejectedReason == ReadBytes(orderToken.rest, 1) IN IF ~orderRejectedReason.ok THEN Fail ELSE
    Ok([ timestamp           |-> timestamp.value,
         orderToken          |-> orderToken.value,
         orderRejectedReason |-> orderRejectedReason.value ], orderRejectedReason.rest)

ZeroOrderRejectedMessage ==
    [ timestamp           |-> [i \in 1 .. 8 |-> 0],
      orderToken          |-> [i \in 1 .. 4 |-> 0],
      orderRejectedReason |-> [i \in 1 .. 1 |-> 0] ]

(* Order Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderRejectedMessage ==
    { ZeroOrderRejectedMessage }
        \cup { [ZeroOrderRejectedMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderRejectedMessage EXCEPT !.orderToken = one] : one \in Sample(4) }
        \cup { [ZeroOrderRejectedMessage EXCEPT !.orderRejectedReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Sequenced Message, selected by Sequenced Message Type                   *)
(***************************************************************************)

SystemEventMessageCode == 83  \* "S"
OrderAcceptedMessageCode == 65  \* "A"
OrderReplacedMessageCode == 85  \* "U"
OrderCanceledMessageCode == 67  \* "C"
OrderAiqCanceledMessageCode == 68  \* "D"
OrderExecutedWithCounterPartyMessageCode == 69  \* "E"
OrderRejectedMessageCode == 74  \* "J"

SequencedMessage ==
    [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {OrderAcceptedMessageCode}, body : OrderAcceptedMessage ]
        \cup [ tag : {OrderReplacedMessageCode}, body : OrderReplacedMessage ]
        \cup [ tag : {OrderCanceledMessageCode}, body : OrderCanceledMessage ]
        \cup [ tag : {OrderAiqCanceledMessageCode}, body : OrderAiqCanceledMessage ]
        \cup [ tag : {OrderExecutedWithCounterPartyMessageCode}, body : OrderExecutedWithCounterPartyMessage ]
        \cup [ tag : {OrderRejectedMessageCode}, body : OrderRejectedMessage ]

EncodeSequencedMessage(message) ==
    CASE message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = OrderAcceptedMessageCode -> EncodeOrderAcceptedMessage(message.body)
      [] message.tag = OrderReplacedMessageCode -> EncodeOrderReplacedMessage(message.body)
      [] message.tag = OrderCanceledMessageCode -> EncodeOrderCanceledMessage(message.body)
      [] message.tag = OrderAiqCanceledMessageCode -> EncodeOrderAiqCanceledMessage(message.body)
      [] message.tag = OrderExecutedWithCounterPartyMessageCode -> EncodeOrderExecutedWithCounterPartyMessage(message.body)
      [] message.tag = OrderRejectedMessageCode -> EncodeOrderRejectedMessage(message.body)

DecodeSequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = OrderAcceptedMessageCode -> DecodeOrderAcceptedMessage(bytes)
              [] tag = OrderReplacedMessageCode -> DecodeOrderReplacedMessage(bytes)
              [] tag = OrderCanceledMessageCode -> DecodeOrderCanceledMessage(bytes)
              [] tag = OrderAiqCanceledMessageCode -> DecodeOrderAiqCanceledMessage(bytes)
              [] tag = OrderExecutedWithCounterPartyMessageCode -> DecodeOrderExecutedWithCounterPartyMessage(bytes)
              [] tag = OrderRejectedMessageCode -> DecodeOrderRejectedMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSequencedMessage == [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]

(* Each Sequenced Message in turn, at the values the message it names is checked at *)
CheckedSequencedMessage ==
    { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> OrderAcceptedMessageCode, body |-> one] : one \in CheckedOrderAcceptedMessage }
        \cup { [tag |-> OrderReplacedMessageCode, body |-> one] : one \in CheckedOrderReplacedMessage }
        \cup { [tag |-> OrderCanceledMessageCode, body |-> one] : one \in CheckedOrderCanceledMessage }
        \cup { [tag |-> OrderAiqCanceledMessageCode, body |-> one] : one \in CheckedOrderAiqCanceledMessage }
        \cup { [tag |-> OrderExecutedWithCounterPartyMessageCode, body |-> one] : one \in CheckedOrderExecutedWithCounterPartyMessage }
        \cup { [tag |-> OrderRejectedMessageCode, body |-> one] : one \in CheckedOrderRejectedMessage }

(***************************************************************************)
(* Sequenced Data Packet                                                   *)
(***************************************************************************)

SequencedDataPacket ==
    [ sequencedMessage : SequencedMessage ]

EncodeSequencedDataPacket(message) ==
    EncodeUIntBE(message.sequencedMessage.tag, 1)
        \o EncodeSequencedMessage(message.sequencedMessage)

DecodeSequencedDataPacket(bytes) ==
    LET sequencedMessageType == ReadUIntBE(bytes, 1) IN IF ~sequencedMessageType.ok THEN Fail ELSE
    LET sequencedMessage == DecodeSequencedMessage(sequencedMessageType.value, sequencedMessageType.rest) IN IF ~sequencedMessage.ok THEN Fail ELSE
    Ok([ sequencedMessage |-> sequencedMessage.value ], sequencedMessage.rest)

ZeroSequencedDataPacket ==
    [ sequencedMessage |-> ZeroSequencedMessage ]

(* Sequenced Data Packet at zero, then each field in turn at the values it is checked at *)
CheckedSequencedDataPacket ==
    { ZeroSequencedDataPacket }
        \cup { [ZeroSequencedDataPacket EXCEPT !.sequencedMessage = one] : one \in CheckedSequencedMessage }

(***************************************************************************)
(* Server Payload, selected by Server Packet Type                          *)
(***************************************************************************)

DebugPacketCode == 43  \* "+"
LoginAcceptedPacketCode == 65  \* "A"
LoginRejectedPacketCode == 74  \* "J"
SequencedDataPacketCode == 83  \* "S"
ServerHeartbeatCode == 72  \* "H"
EndOfSessionCode == 90  \* "Z"

ServerPayload ==
    [ tag : {DebugPacketCode}, body : DebugPacket ]
        \cup [ tag : {LoginAcceptedPacketCode}, body : LoginAcceptedPacket ]
        \cup [ tag : {LoginRejectedPacketCode}, body : LoginRejectedPacket ]
        \cup [ tag : {SequencedDataPacketCode}, body : SequencedDataPacket ]
        \cup [ tag : {ServerHeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {EndOfSessionCode}, body : {[empty |-> 0]} ]

EncodeServerPayload(message) ==
    CASE message.tag = DebugPacketCode -> EncodeDebugPacket(message.body)
      [] message.tag = LoginAcceptedPacketCode -> EncodeLoginAcceptedPacket(message.body)
      [] message.tag = LoginRejectedPacketCode -> EncodeLoginRejectedPacket(message.body)
      [] message.tag = SequencedDataPacketCode -> EncodeSequencedDataPacket(message.body)
      [] message.tag = ServerHeartbeatCode -> << >>
      [] message.tag = EndOfSessionCode -> << >>

DecodeServerPayload(tag, bytes) ==
    LET read ==
            CASE tag = DebugPacketCode -> DecodeDebugPacket(bytes)
              [] tag = LoginAcceptedPacketCode -> DecodeLoginAcceptedPacket(bytes)
              [] tag = LoginRejectedPacketCode -> DecodeLoginRejectedPacket(bytes)
              [] tag = SequencedDataPacketCode -> DecodeSequencedDataPacket(bytes)
              [] tag = ServerHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = EndOfSessionCode -> Ok([empty |-> 0], bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroServerPayload == [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]

(* Each Server Payload in turn, at the values the message it names is checked at *)
CheckedServerPayload ==
    { [tag |-> DebugPacketCode, body |-> one] : one \in CheckedDebugPacket }
        \cup { [tag |-> LoginAcceptedPacketCode, body |-> one] : one \in CheckedLoginAcceptedPacket }
        \cup { [tag |-> LoginRejectedPacketCode, body |-> one] : one \in CheckedLoginRejectedPacket }
        \cup { [tag |-> SequencedDataPacketCode, body |-> one] : one \in CheckedSequencedDataPacket }
        \cup { [tag |-> ServerHeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> EndOfSessionCode, body |-> [empty |-> 0]] }

(***************************************************************************)
(* Server Soup Bin Tcp Packet, framed by Packet Length                     *)
(***************************************************************************)

ServerSoupBinTcpPacket ==
    [ serverPayload : ServerPayload ]

EncodeServerSoupBinTcpPacketBody(message) ==
    EncodeUIntBE(message.serverPayload.tag, 1)
        \o EncodeServerPayload(message.serverPayload)

(* Packet Length counts the bytes it frames, so it is written from them *)
EncodeServerSoupBinTcpPacket(message) ==
    LET body == EncodeServerSoupBinTcpPacketBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeServerSoupBinTcpPacketBody(bytes) ==
    LET serverPacketType == ReadUIntBE(bytes, 1) IN IF ~serverPacketType.ok THEN Fail ELSE
    LET serverPayload == DecodeServerPayload(serverPacketType.value, serverPacketType.rest) IN IF ~serverPayload.ok THEN Fail ELSE
    Ok([ serverPayload |-> serverPayload.value ], serverPayload.rest)

DecodeServerSoupBinTcpPacket(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeServerSoupBinTcpPacketBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroServerSoupBinTcpPacket ==
    [ serverPayload |-> ZeroServerPayload ]

(* Server Soup Bin Tcp Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerSoupBinTcpPacket ==
    { ZeroServerSoupBinTcpPacket }
        \cup { [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = one] : one \in CheckedServerPayload }

(* A run of Server Soup Bin Tcp Packet, written one after another *)
RECURSIVE EncodeServerSoupBinTcpPacketList(_)
EncodeServerSoupBinTcpPacketList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeServerSoupBinTcpPacket(Head(messages)) \o EncodeServerSoupBinTcpPacketList(Tail(messages))

(* As many Server Soup Bin Tcp Packet as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadServerSoupBinTcpPacketAll(_)
ReadServerSoupBinTcpPacketAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeServerSoupBinTcpPacket(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadServerSoupBinTcpPacketAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Server Soup Bin Tcp Packet of each kind, for the lists that carry them *)
OneServerSoupBinTcpPacket ==
    { [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> LoginAcceptedPacketCode, body |-> ZeroLoginAcceptedPacket]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> LoginRejectedPacketCode, body |-> ZeroLoginRejectedPacket]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> SequencedDataPacketCode, body |-> ZeroSequencedDataPacket]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> ServerHeartbeatCode, body |-> [empty |-> 0]]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> EndOfSessionCode, body |-> [empty |-> 0]]] }

(***************************************************************************)
(* Server Packet                                                           *)
(***************************************************************************)

ServerPacket ==
    [ serverSoupBinTcpPacket : SampleLists(OneServerSoupBinTcpPacket) ]

EncodeServerPacket(message) ==
    EncodeServerSoupBinTcpPacketList(message.serverSoupBinTcpPacket)

DecodeServerPacket(bytes) ==
    LET serverSoupBinTcpPacket == ReadServerSoupBinTcpPacketAll(bytes) IN IF ~serverSoupBinTcpPacket.ok THEN Fail ELSE
    Ok([ serverSoupBinTcpPacket |-> serverSoupBinTcpPacket.value ], serverSoupBinTcpPacket.rest)

ZeroServerPacket ==
    [ serverSoupBinTcpPacket |-> << >> ]

(* Server Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerPacket ==
    { ZeroServerPacket }
        \cup { [ZeroServerPacket EXCEPT !.serverSoupBinTcpPacket = one] : one \in SampleLists(OneServerSoupBinTcpPacket) }

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

(* Every Debug Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripDebugPacket ==
    \A message \in CheckedDebugPacket :
        LET read == DecodeDebugPacket(EncodeDebugPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Accepted Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginAcceptedPacket ==
    \A message \in CheckedLoginAcceptedPacket :
        LET read == DecodeLoginAcceptedPacket(EncodeLoginAcceptedPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Rejected Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRejectedPacket ==
    \A message \in CheckedLoginRejectedPacket :
        LET read == DecodeLoginRejectedPacket(EncodeLoginRejectedPacket(message))
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

(* Every Order Accepted Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderAcceptedMessage ==
    \A message \in CheckedOrderAcceptedMessage :
        LET read == DecodeOrderAcceptedMessage(EncodeOrderAcceptedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Replaced Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderReplacedMessage ==
    \A message \in CheckedOrderReplacedMessage :
        LET read == DecodeOrderReplacedMessage(EncodeOrderReplacedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Canceled Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCanceledMessage ==
    \A message \in CheckedOrderCanceledMessage :
        LET read == DecodeOrderCanceledMessage(EncodeOrderCanceledMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Aiq Canceled Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderAiqCanceledMessage ==
    \A message \in CheckedOrderAiqCanceledMessage :
        LET read == DecodeOrderAiqCanceledMessage(EncodeOrderAiqCanceledMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Executed With Counter Party Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutedWithCounterPartyMessage ==
    \A message \in CheckedOrderExecutedWithCounterPartyMessage :
        LET read == DecodeOrderExecutedWithCounterPartyMessage(EncodeOrderExecutedWithCounterPartyMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderRejectedMessage ==
    \A message \in CheckedOrderRejectedMessage :
        LET read == DecodeOrderRejectedMessage(EncodeOrderRejectedMessage(message))
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

(* Every Server Soup Bin Tcp Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripServerSoupBinTcpPacket ==
    \A message \in CheckedServerSoupBinTcpPacket :
        LET read == DecodeServerSoupBinTcpPacket(EncodeServerSoupBinTcpPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Server Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripServerPacket ==
    \A message \in CheckedServerPacket :
        LET read == DecodeServerPacket(EncodeServerPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Sequenced Message is selected by the Sequenced Message Type it is written under *)
SelectsSequencedMessage ==
    \A message \in CheckedSequencedMessage :
        LET read == DecodeSequencedMessage(message.tag, EncodeSequencedMessage(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Server Payload is selected by the Server Packet Type it is written under *)
SelectsServerPayload ==
    \A message \in CheckedServerPayload :
        LET read == DecodeServerPayload(message.tag, EncodeServerPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Packet Length is written from the bytes it frames *)
FramesServerSoupBinTcpPacket ==
    \A message \in CheckedServerSoupBinTcpPacket :
        LET bytes == EncodeServerSoupBinTcpPacket(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
