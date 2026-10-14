--------------- MODULE BivaEquities_OrderEntry_v1_05_Server ----------------
(***************************************************************************)
(* Bolsa Institucional de Valores Order Entry v1.05                        *)
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
(*                                                                         *)
(* Note: a Server Soup Bin Tcp Packet that ends the session is the last of *)
(* its Server Packet: nothing may follow it.                               *)
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
    [ timestamp : Sample(8),
      eventCode : Sample(1) ]

EncodeSystemEventMessage(message) ==
    message.timestamp
        \o message.eventCode

DecodeSystemEventMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET eventCode == ReadBytes(timestamp.rest, 1) IN IF ~eventCode.ok THEN Fail ELSE
    Ok([ timestamp |-> timestamp.value,
         eventCode |-> eventCode.value ], eventCode.rest)

ZeroSystemEventMessage ==
    [ timestamp |-> [i \in 1 .. 8 |-> 0],
      eventCode |-> [i \in 1 .. 1 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Accepted Message: 59 bytes                                              *)
(***************************************************************************)

AcceptedMessage ==
    [ timestamp            : Sample(8),
      orderToken           : Sample(4),
      accountType          : Sample(1),
      accountId            : Sample(4),
      orderVerb            : Sample(1),
      quantity             : Sample(8),
      orderbook            : Sample(4),
      price                : Sample(4),
      timeInForce          : Sample(4),
      clientId             : Sample(4),
      orderReferenceNumber : Sample(8),
      minimumQuantity      : Sample(8),
      orderState           : Sample(1) ]

EncodeAcceptedMessage(message) ==
    message.timestamp
        \o message.orderToken
        \o message.accountType
        \o message.accountId
        \o message.orderVerb
        \o message.quantity
        \o message.orderbook
        \o message.price
        \o message.timeInForce
        \o message.clientId
        \o message.orderReferenceNumber
        \o message.minimumQuantity
        \o message.orderState

DecodeAcceptedMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderToken == ReadBytes(timestamp.rest, 4) IN IF ~orderToken.ok THEN Fail ELSE
    LET accountType == ReadBytes(orderToken.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET accountId == ReadBytes(accountType.rest, 4) IN IF ~accountId.ok THEN Fail ELSE
    LET orderVerb == ReadBytes(accountId.rest, 1) IN IF ~orderVerb.ok THEN Fail ELSE
    LET quantity == ReadBytes(orderVerb.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET orderbook == ReadBytes(quantity.rest, 4) IN IF ~orderbook.ok THEN Fail ELSE
    LET price == ReadBytes(orderbook.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(price.rest, 4) IN IF ~timeInForce.ok THEN Fail ELSE
    LET clientId == ReadBytes(timeInForce.rest, 4) IN IF ~clientId.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(clientId.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET minimumQuantity == ReadBytes(orderReferenceNumber.rest, 8) IN IF ~minimumQuantity.ok THEN Fail ELSE
    LET orderState == ReadBytes(minimumQuantity.rest, 1) IN IF ~orderState.ok THEN Fail ELSE
    Ok([ timestamp            |-> timestamp.value,
         orderToken           |-> orderToken.value,
         accountType          |-> accountType.value,
         accountId            |-> accountId.value,
         orderVerb            |-> orderVerb.value,
         quantity             |-> quantity.value,
         orderbook            |-> orderbook.value,
         price                |-> price.value,
         timeInForce          |-> timeInForce.value,
         clientId             |-> clientId.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         minimumQuantity      |-> minimumQuantity.value,
         orderState           |-> orderState.value ], orderState.rest)

ZeroAcceptedMessage ==
    [ timestamp            |-> [i \in 1 .. 8 |-> 0],
      orderToken           |-> [i \in 1 .. 4 |-> 0],
      accountType          |-> [i \in 1 .. 1 |-> 0],
      accountId            |-> [i \in 1 .. 4 |-> 0],
      orderVerb            |-> [i \in 1 .. 1 |-> 0],
      quantity             |-> [i \in 1 .. 8 |-> 0],
      orderbook            |-> [i \in 1 .. 4 |-> 0],
      price                |-> [i \in 1 .. 4 |-> 0],
      timeInForce          |-> [i \in 1 .. 4 |-> 0],
      clientId             |-> [i \in 1 .. 4 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      minimumQuantity      |-> [i \in 1 .. 8 |-> 0],
      orderState           |-> [i \in 1 .. 1 |-> 0] ]

(* Accepted Message at zero, then each field in turn at the values it is checked at *)
CheckedAcceptedMessage ==
    { ZeroAcceptedMessage }
        \cup { [ZeroAcceptedMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAcceptedMessage EXCEPT !.orderToken = one] : one \in Sample(4) }
        \cup { [ZeroAcceptedMessage EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroAcceptedMessage EXCEPT !.accountId = one] : one \in Sample(4) }
        \cup { [ZeroAcceptedMessage EXCEPT !.orderVerb = one] : one \in Sample(1) }
        \cup { [ZeroAcceptedMessage EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroAcceptedMessage EXCEPT !.orderbook = one] : one \in Sample(4) }
        \cup { [ZeroAcceptedMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroAcceptedMessage EXCEPT !.timeInForce = one] : one \in Sample(4) }
        \cup { [ZeroAcceptedMessage EXCEPT !.clientId = one] : one \in Sample(4) }
        \cup { [ZeroAcceptedMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroAcceptedMessage EXCEPT !.minimumQuantity = one] : one \in Sample(8) }
        \cup { [ZeroAcceptedMessage EXCEPT !.orderState = one] : one \in Sample(1) }

(***************************************************************************)
(* Replaced Message: 42 bytes                                              *)
(***************************************************************************)

ReplacedMessage ==
    [ timestamp             : Sample(8),
      replacementOrderToken : Sample(4),
      orderVerb             : Sample(1),
      quantity              : Sample(8),
      orderbook             : Sample(4),
      price                 : Sample(4),
      orderReferenceNumber  : Sample(8),
      orderState            : Sample(1),
      previousOrderToken    : Sample(4) ]

EncodeReplacedMessage(message) ==
    message.timestamp
        \o message.replacementOrderToken
        \o message.orderVerb
        \o message.quantity
        \o message.orderbook
        \o message.price
        \o message.orderReferenceNumber
        \o message.orderState
        \o message.previousOrderToken

DecodeReplacedMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET replacementOrderToken == ReadBytes(timestamp.rest, 4) IN IF ~replacementOrderToken.ok THEN Fail ELSE
    LET orderVerb == ReadBytes(replacementOrderToken.rest, 1) IN IF ~orderVerb.ok THEN Fail ELSE
    LET quantity == ReadBytes(orderVerb.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET orderbook == ReadBytes(quantity.rest, 4) IN IF ~orderbook.ok THEN Fail ELSE
    LET price == ReadBytes(orderbook.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(price.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET orderState == ReadBytes(orderReferenceNumber.rest, 1) IN IF ~orderState.ok THEN Fail ELSE
    LET previousOrderToken == ReadBytes(orderState.rest, 4) IN IF ~previousOrderToken.ok THEN Fail ELSE
    Ok([ timestamp             |-> timestamp.value,
         replacementOrderToken |-> replacementOrderToken.value,
         orderVerb             |-> orderVerb.value,
         quantity              |-> quantity.value,
         orderbook             |-> orderbook.value,
         price                 |-> price.value,
         orderReferenceNumber  |-> orderReferenceNumber.value,
         orderState            |-> orderState.value,
         previousOrderToken    |-> previousOrderToken.value ], previousOrderToken.rest)

ZeroReplacedMessage ==
    [ timestamp             |-> [i \in 1 .. 8 |-> 0],
      replacementOrderToken |-> [i \in 1 .. 4 |-> 0],
      orderVerb             |-> [i \in 1 .. 1 |-> 0],
      quantity              |-> [i \in 1 .. 8 |-> 0],
      orderbook             |-> [i \in 1 .. 4 |-> 0],
      price                 |-> [i \in 1 .. 4 |-> 0],
      orderReferenceNumber  |-> [i \in 1 .. 8 |-> 0],
      orderState            |-> [i \in 1 .. 1 |-> 0],
      previousOrderToken    |-> [i \in 1 .. 4 |-> 0] ]

(* Replaced Message at zero, then each field in turn at the values it is checked at *)
CheckedReplacedMessage ==
    { ZeroReplacedMessage }
        \cup { [ZeroReplacedMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroReplacedMessage EXCEPT !.replacementOrderToken = one] : one \in Sample(4) }
        \cup { [ZeroReplacedMessage EXCEPT !.orderVerb = one] : one \in Sample(1) }
        \cup { [ZeroReplacedMessage EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroReplacedMessage EXCEPT !.orderbook = one] : one \in Sample(4) }
        \cup { [ZeroReplacedMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroReplacedMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroReplacedMessage EXCEPT !.orderState = one] : one \in Sample(1) }
        \cup { [ZeroReplacedMessage EXCEPT !.previousOrderToken = one] : one \in Sample(4) }

(***************************************************************************)
(* Canceled Message: 21 bytes                                              *)
(***************************************************************************)

CanceledMessage ==
    [ timestamp      : Sample(8),
      orderToken     : Sample(4),
      quantity       : Sample(8),
      canceledReason : Sample(1) ]

EncodeCanceledMessage(message) ==
    message.timestamp
        \o message.orderToken
        \o message.quantity
        \o message.canceledReason

DecodeCanceledMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderToken == ReadBytes(timestamp.rest, 4) IN IF ~orderToken.ok THEN Fail ELSE
    LET quantity == ReadBytes(orderToken.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET canceledReason == ReadBytes(quantity.rest, 1) IN IF ~canceledReason.ok THEN Fail ELSE
    Ok([ timestamp      |-> timestamp.value,
         orderToken     |-> orderToken.value,
         quantity       |-> quantity.value,
         canceledReason |-> canceledReason.value ], canceledReason.rest)

ZeroCanceledMessage ==
    [ timestamp      |-> [i \in 1 .. 8 |-> 0],
      orderToken     |-> [i \in 1 .. 4 |-> 0],
      quantity       |-> [i \in 1 .. 8 |-> 0],
      canceledReason |-> [i \in 1 .. 1 |-> 0] ]

(* Canceled Message at zero, then each field in turn at the values it is checked at *)
CheckedCanceledMessage ==
    { ZeroCanceledMessage }
        \cup { [ZeroCanceledMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroCanceledMessage EXCEPT !.orderToken = one] : one \in Sample(4) }
        \cup { [ZeroCanceledMessage EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroCanceledMessage EXCEPT !.canceledReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Executed Order Message: 37 bytes                                        *)
(***************************************************************************)

ExecutedOrderMessage ==
    [ timestamp        : Sample(8),
      orderToken       : Sample(4),
      executedQuantity : Sample(8),
      executedPrice    : Sample(4),
      liquidityFlag    : Sample(1),
      matchNumber      : Sample(8),
      counterPartyId   : Sample(4) ]

EncodeExecutedOrderMessage(message) ==
    message.timestamp
        \o message.orderToken
        \o message.executedQuantity
        \o message.executedPrice
        \o message.liquidityFlag
        \o message.matchNumber
        \o message.counterPartyId

DecodeExecutedOrderMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderToken == ReadBytes(timestamp.rest, 4) IN IF ~orderToken.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(orderToken.rest, 8) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET executedPrice == ReadBytes(executedQuantity.rest, 4) IN IF ~executedPrice.ok THEN Fail ELSE
    LET liquidityFlag == ReadBytes(executedPrice.rest, 1) IN IF ~liquidityFlag.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(liquidityFlag.rest, 8) IN IF ~matchNumber.ok THEN Fail ELSE
    LET counterPartyId == ReadBytes(matchNumber.rest, 4) IN IF ~counterPartyId.ok THEN Fail ELSE
    Ok([ timestamp        |-> timestamp.value,
         orderToken       |-> orderToken.value,
         executedQuantity |-> executedQuantity.value,
         executedPrice    |-> executedPrice.value,
         liquidityFlag    |-> liquidityFlag.value,
         matchNumber      |-> matchNumber.value,
         counterPartyId   |-> counterPartyId.value ], counterPartyId.rest)

ZeroExecutedOrderMessage ==
    [ timestamp        |-> [i \in 1 .. 8 |-> 0],
      orderToken       |-> [i \in 1 .. 4 |-> 0],
      executedQuantity |-> [i \in 1 .. 8 |-> 0],
      executedPrice    |-> [i \in 1 .. 4 |-> 0],
      liquidityFlag    |-> [i \in 1 .. 1 |-> 0],
      matchNumber      |-> [i \in 1 .. 8 |-> 0],
      counterPartyId   |-> [i \in 1 .. 4 |-> 0] ]

(* Executed Order Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutedOrderMessage ==
    { ZeroExecutedOrderMessage }
        \cup { [ZeroExecutedOrderMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroExecutedOrderMessage EXCEPT !.orderToken = one] : one \in Sample(4) }
        \cup { [ZeroExecutedOrderMessage EXCEPT !.executedQuantity = one] : one \in Sample(8) }
        \cup { [ZeroExecutedOrderMessage EXCEPT !.executedPrice = one] : one \in Sample(4) }
        \cup { [ZeroExecutedOrderMessage EXCEPT !.liquidityFlag = one] : one \in Sample(1) }
        \cup { [ZeroExecutedOrderMessage EXCEPT !.matchNumber = one] : one \in Sample(8) }
        \cup { [ZeroExecutedOrderMessage EXCEPT !.counterPartyId = one] : one \in Sample(4) }

(***************************************************************************)
(* Broken Trade Message: 21 bytes                                          *)
(***************************************************************************)

BrokenTradeMessage ==
    [ timestamp         : Sample(8),
      orderToken        : Sample(4),
      matchNumber       : Sample(8),
      brokenTradeReason : Sample(1) ]

EncodeBrokenTradeMessage(message) ==
    message.timestamp
        \o message.orderToken
        \o message.matchNumber
        \o message.brokenTradeReason

DecodeBrokenTradeMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderToken == ReadBytes(timestamp.rest, 4) IN IF ~orderToken.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(orderToken.rest, 8) IN IF ~matchNumber.ok THEN Fail ELSE
    LET brokenTradeReason == ReadBytes(matchNumber.rest, 1) IN IF ~brokenTradeReason.ok THEN Fail ELSE
    Ok([ timestamp         |-> timestamp.value,
         orderToken        |-> orderToken.value,
         matchNumber       |-> matchNumber.value,
         brokenTradeReason |-> brokenTradeReason.value ], brokenTradeReason.rest)

ZeroBrokenTradeMessage ==
    [ timestamp         |-> [i \in 1 .. 8 |-> 0],
      orderToken        |-> [i \in 1 .. 4 |-> 0],
      matchNumber       |-> [i \in 1 .. 8 |-> 0],
      brokenTradeReason |-> [i \in 1 .. 1 |-> 0] ]

(* Broken Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedBrokenTradeMessage ==
    { ZeroBrokenTradeMessage }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.orderToken = one] : one \in Sample(4) }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.matchNumber = one] : one \in Sample(8) }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.brokenTradeReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Rejected Order Message: 13 bytes                                        *)
(***************************************************************************)

RejectedOrderMessage ==
    [ timestamp      : Sample(8),
      orderToken     : Sample(4),
      rejectedReason : Sample(1) ]

EncodeRejectedOrderMessage(message) ==
    message.timestamp
        \o message.orderToken
        \o message.rejectedReason

DecodeRejectedOrderMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderToken == ReadBytes(timestamp.rest, 4) IN IF ~orderToken.ok THEN Fail ELSE
    LET rejectedReason == ReadBytes(orderToken.rest, 1) IN IF ~rejectedReason.ok THEN Fail ELSE
    Ok([ timestamp      |-> timestamp.value,
         orderToken     |-> orderToken.value,
         rejectedReason |-> rejectedReason.value ], rejectedReason.rest)

ZeroRejectedOrderMessage ==
    [ timestamp      |-> [i \in 1 .. 8 |-> 0],
      orderToken     |-> [i \in 1 .. 4 |-> 0],
      rejectedReason |-> [i \in 1 .. 1 |-> 0] ]

(* Rejected Order Message at zero, then each field in turn at the values it is checked at *)
CheckedRejectedOrderMessage ==
    { ZeroRejectedOrderMessage }
        \cup { [ZeroRejectedOrderMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroRejectedOrderMessage EXCEPT !.orderToken = one] : one \in Sample(4) }
        \cup { [ZeroRejectedOrderMessage EXCEPT !.rejectedReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Sequenced Message, selected by Sequenced Message Type                   *)
(***************************************************************************)

SystemEventMessageCode == 83  \* "S"
AcceptedMessageCode == 65  \* "A"
ReplacedMessageCode == 85  \* "U"
CanceledMessageCode == 67  \* "C"
ExecutedOrderMessageCode == 69  \* "E"
BrokenTradeMessageCode == 66  \* "B"
RejectedOrderMessageCode == 74  \* "J"

SequencedMessage ==
    [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {AcceptedMessageCode}, body : AcceptedMessage ]
        \cup [ tag : {ReplacedMessageCode}, body : ReplacedMessage ]
        \cup [ tag : {CanceledMessageCode}, body : CanceledMessage ]
        \cup [ tag : {ExecutedOrderMessageCode}, body : ExecutedOrderMessage ]
        \cup [ tag : {BrokenTradeMessageCode}, body : BrokenTradeMessage ]
        \cup [ tag : {RejectedOrderMessageCode}, body : RejectedOrderMessage ]

EncodeSequencedMessage(message) ==
    CASE message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = AcceptedMessageCode -> EncodeAcceptedMessage(message.body)
      [] message.tag = ReplacedMessageCode -> EncodeReplacedMessage(message.body)
      [] message.tag = CanceledMessageCode -> EncodeCanceledMessage(message.body)
      [] message.tag = ExecutedOrderMessageCode -> EncodeExecutedOrderMessage(message.body)
      [] message.tag = BrokenTradeMessageCode -> EncodeBrokenTradeMessage(message.body)
      [] message.tag = RejectedOrderMessageCode -> EncodeRejectedOrderMessage(message.body)

DecodeSequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = AcceptedMessageCode -> DecodeAcceptedMessage(bytes)
              [] tag = ReplacedMessageCode -> DecodeReplacedMessage(bytes)
              [] tag = CanceledMessageCode -> DecodeCanceledMessage(bytes)
              [] tag = ExecutedOrderMessageCode -> DecodeExecutedOrderMessage(bytes)
              [] tag = BrokenTradeMessageCode -> DecodeBrokenTradeMessage(bytes)
              [] tag = RejectedOrderMessageCode -> DecodeRejectedOrderMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSequencedMessage == [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]

(* Each Sequenced Message in turn, at the values the message it names is checked at *)
CheckedSequencedMessage ==
    { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> AcceptedMessageCode, body |-> one] : one \in CheckedAcceptedMessage }
        \cup { [tag |-> ReplacedMessageCode, body |-> one] : one \in CheckedReplacedMessage }
        \cup { [tag |-> CanceledMessageCode, body |-> one] : one \in CheckedCanceledMessage }
        \cup { [tag |-> ExecutedOrderMessageCode, body |-> one] : one \in CheckedExecutedOrderMessage }
        \cup { [tag |-> BrokenTradeMessageCode, body |-> one] : one \in CheckedBrokenTradeMessage }
        \cup { [tag |-> RejectedOrderMessageCode, body |-> one] : one \in CheckedRejectedOrderMessage }

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

(* Does a Server Soup Bin Tcp Packet end the session? Nothing may follow one that does *)
EndsSessionServerSoupBinTcpPacket(message) == message.serverPayload.tag \in {EndOfSessionCode}

(* A run of Server Soup Bin Tcp Packet, written one after another *)
RECURSIVE EncodeServerSoupBinTcpPacketList(_)
EncodeServerSoupBinTcpPacketList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeServerSoupBinTcpPacket(Head(messages)) \o EncodeServerSoupBinTcpPacketList(Tail(messages))

(* As many Server Soup Bin Tcp Packet as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
(* Only the last of them may end the session, so one that does with bytes left fails *)
RECURSIVE ReadServerSoupBinTcpPacketAll(_)
ReadServerSoupBinTcpPacketAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeServerSoupBinTcpPacket(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE IF EndsSessionServerSoupBinTcpPacket(one.value) /\ one.rest # << >> THEN Fail
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

(* The runs of Server Soup Bin Tcp Packet checked: none, one, two of a kind and each kind followed by *)
(* another, keeping those in which only the last may end the session *)
SampleServerSoupBinTcpPacketLists ==
    { run \in SampleLists(OneServerSoupBinTcpPacket) \cup { <<one, other>> : one \in OneServerSoupBinTcpPacket, other \in OneServerSoupBinTcpPacket } :
          \A at \in 1 .. Len(run) - 1 : ~EndsSessionServerSoupBinTcpPacket(run[at]) }

(***************************************************************************)
(* Server Packet                                                           *)
(***************************************************************************)

ServerPacket ==
    [ serverSoupBinTcpPacket : SampleServerSoupBinTcpPacketLists ]

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
        \cup { [ZeroServerPacket EXCEPT !.serverSoupBinTcpPacket = one] : one \in SampleServerSoupBinTcpPacketLists }

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

(* Every Accepted Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAcceptedMessage ==
    \A message \in CheckedAcceptedMessage :
        LET read == DecodeAcceptedMessage(EncodeAcceptedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Replaced Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReplacedMessage ==
    \A message \in CheckedReplacedMessage :
        LET read == DecodeReplacedMessage(EncodeReplacedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Canceled Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCanceledMessage ==
    \A message \in CheckedCanceledMessage :
        LET read == DecodeCanceledMessage(EncodeCanceledMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Executed Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutedOrderMessage ==
    \A message \in CheckedExecutedOrderMessage :
        LET read == DecodeExecutedOrderMessage(EncodeExecutedOrderMessage(message))
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

(* Every Rejected Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRejectedOrderMessage ==
    \A message \in CheckedRejectedOrderMessage :
        LET read == DecodeRejectedOrderMessage(EncodeRejectedOrderMessage(message))
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

(* A Server Soup Bin Tcp Packet that ends the session is the last of its Server Packet: a run with one after it does not decode *)
EndsSessionLastServerSoupBinTcpPacket ==
    \A last \in { one \in OneServerSoupBinTcpPacket : EndsSessionServerSoupBinTcpPacket(one) } :
        \A after \in OneServerSoupBinTcpPacket :
            ~ReadServerSoupBinTcpPacketAll(EncodeServerSoupBinTcpPacketList(<<last, after>>)).ok

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
