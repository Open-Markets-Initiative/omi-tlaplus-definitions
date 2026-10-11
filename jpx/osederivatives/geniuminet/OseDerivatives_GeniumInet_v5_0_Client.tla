--------------- MODULE OseDerivatives_GeniumInet_v5_0_Client ---------------
(***************************************************************************)
(* Japan Exchange Group Genium Inet v5.0                                   *)
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
(* Note: Unsequenced Data Packet fills what is left of the frame Packet    *)
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
(* Login Request Packet: 46 bytes                                          *)
(***************************************************************************)

LoginRequestPacket ==
    [ username                : Sample(6),
      password                : Sample(10),
      requestedSession        : Sample(10),
      requestedSequenceNumber : Sample(20) ]

EncodeLoginRequestPacket(message) ==
    message.username
        \o message.password
        \o message.requestedSession
        \o message.requestedSequenceNumber

DecodeLoginRequestPacket(bytes) ==
    LET username == ReadBytes(bytes, 6) IN IF ~username.ok THEN Fail ELSE
    LET password == ReadBytes(username.rest, 10) IN IF ~password.ok THEN Fail ELSE
    LET requestedSession == ReadBytes(password.rest, 10) IN IF ~requestedSession.ok THEN Fail ELSE
    LET requestedSequenceNumber == ReadBytes(requestedSession.rest, 20) IN IF ~requestedSequenceNumber.ok THEN Fail ELSE
    Ok([ username                |-> username.value,
         password                |-> password.value,
         requestedSession        |-> requestedSession.value,
         requestedSequenceNumber |-> requestedSequenceNumber.value ], requestedSequenceNumber.rest)

ZeroLoginRequestPacket ==
    [ username                |-> [i \in 1 .. 6 |-> 0],
      password                |-> [i \in 1 .. 10 |-> 0],
      requestedSession        |-> [i \in 1 .. 10 |-> 0],
      requestedSequenceNumber |-> [i \in 1 .. 20 |-> 0] ]

(* Login Request Packet at zero, then each field in turn at the values it is checked at *)
CheckedLoginRequestPacket ==
    { ZeroLoginRequestPacket }
        \cup { [ZeroLoginRequestPacket EXCEPT !.username = one] : one \in Sample(6) }
        \cup { [ZeroLoginRequestPacket EXCEPT !.password = one] : one \in Sample(10) }
        \cup { [ZeroLoginRequestPacket EXCEPT !.requestedSession = one] : one \in Sample(10) }
        \cup { [ZeroLoginRequestPacket EXCEPT !.requestedSequenceNumber = one] : one \in Sample(20) }

(***************************************************************************)
(* Enter Order: 96 bytes                                                   *)
(***************************************************************************)

EnterOrder ==
    [ orderToken    : Sample(14),
      orderBookId   : Sample(4),
      side          : Sample(1),
      quantity      : Sample(8),
      price         : Sample(4),
      timeInForce   : Sample(1),
      openClose     : Sample(1),
      clientAccount : Sample(16),
      customerInfo  : Sample(15),
      exchangeInfo  : Sample(32) ]

EncodeEnterOrder(message) ==
    message.orderToken
        \o message.orderBookId
        \o message.side
        \o message.quantity
        \o message.price
        \o message.timeInForce
        \o message.openClose
        \o message.clientAccount
        \o message.customerInfo
        \o message.exchangeInfo

DecodeEnterOrder(bytes) ==
    LET orderToken == ReadBytes(bytes, 14) IN IF ~orderToken.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(orderToken.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET side == ReadBytes(orderBookId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET quantity == ReadBytes(side.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(price.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET openClose == ReadBytes(timeInForce.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET clientAccount == ReadBytes(openClose.rest, 16) IN IF ~clientAccount.ok THEN Fail ELSE
    LET customerInfo == ReadBytes(clientAccount.rest, 15) IN IF ~customerInfo.ok THEN Fail ELSE
    LET exchangeInfo == ReadBytes(customerInfo.rest, 32) IN IF ~exchangeInfo.ok THEN Fail ELSE
    Ok([ orderToken    |-> orderToken.value,
         orderBookId   |-> orderBookId.value,
         side          |-> side.value,
         quantity      |-> quantity.value,
         price         |-> price.value,
         timeInForce   |-> timeInForce.value,
         openClose     |-> openClose.value,
         clientAccount |-> clientAccount.value,
         customerInfo  |-> customerInfo.value,
         exchangeInfo  |-> exchangeInfo.value ], exchangeInfo.rest)

ZeroEnterOrder ==
    [ orderToken    |-> [i \in 1 .. 14 |-> 0],
      orderBookId   |-> [i \in 1 .. 4 |-> 0],
      side          |-> [i \in 1 .. 1 |-> 0],
      quantity      |-> [i \in 1 .. 8 |-> 0],
      price         |-> [i \in 1 .. 4 |-> 0],
      timeInForce   |-> [i \in 1 .. 1 |-> 0],
      openClose     |-> [i \in 1 .. 1 |-> 0],
      clientAccount |-> [i \in 1 .. 16 |-> 0],
      customerInfo  |-> [i \in 1 .. 15 |-> 0],
      exchangeInfo  |-> [i \in 1 .. 32 |-> 0] ]

(* Enter Order at zero, then each field in turn at the values it is checked at *)
CheckedEnterOrder ==
    { ZeroEnterOrder }
        \cup { [ZeroEnterOrder EXCEPT !.orderToken = one] : one \in Sample(14) }
        \cup { [ZeroEnterOrder EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroEnterOrder EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroEnterOrder EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroEnterOrder EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroEnterOrder EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroEnterOrder EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroEnterOrder EXCEPT !.clientAccount = one] : one \in Sample(16) }
        \cup { [ZeroEnterOrder EXCEPT !.customerInfo = one] : one \in Sample(15) }
        \cup { [ZeroEnterOrder EXCEPT !.exchangeInfo = one] : one \in Sample(32) }

(***************************************************************************)
(* Enter Mm Order: 79 bytes                                                *)
(***************************************************************************)

EnterMmOrder ==
    [ orderToken    : Sample(14),
      orderBookId   : Sample(4),
      side          : Sample(1),
      quantity      : Sample(8),
      price         : Sample(4),
      clientAccount : Sample(16),
      exchangeInfo  : Sample(32) ]

EncodeEnterMmOrder(message) ==
    message.orderToken
        \o message.orderBookId
        \o message.side
        \o message.quantity
        \o message.price
        \o message.clientAccount
        \o message.exchangeInfo

DecodeEnterMmOrder(bytes) ==
    LET orderToken == ReadBytes(bytes, 14) IN IF ~orderToken.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(orderToken.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET side == ReadBytes(orderBookId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET quantity == ReadBytes(side.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET clientAccount == ReadBytes(price.rest, 16) IN IF ~clientAccount.ok THEN Fail ELSE
    LET exchangeInfo == ReadBytes(clientAccount.rest, 32) IN IF ~exchangeInfo.ok THEN Fail ELSE
    Ok([ orderToken    |-> orderToken.value,
         orderBookId   |-> orderBookId.value,
         side          |-> side.value,
         quantity      |-> quantity.value,
         price         |-> price.value,
         clientAccount |-> clientAccount.value,
         exchangeInfo  |-> exchangeInfo.value ], exchangeInfo.rest)

ZeroEnterMmOrder ==
    [ orderToken    |-> [i \in 1 .. 14 |-> 0],
      orderBookId   |-> [i \in 1 .. 4 |-> 0],
      side          |-> [i \in 1 .. 1 |-> 0],
      quantity      |-> [i \in 1 .. 8 |-> 0],
      price         |-> [i \in 1 .. 4 |-> 0],
      clientAccount |-> [i \in 1 .. 16 |-> 0],
      exchangeInfo  |-> [i \in 1 .. 32 |-> 0] ]

(* Enter Mm Order at zero, then each field in turn at the values it is checked at *)
CheckedEnterMmOrder ==
    { ZeroEnterMmOrder }
        \cup { [ZeroEnterMmOrder EXCEPT !.orderToken = one] : one \in Sample(14) }
        \cup { [ZeroEnterMmOrder EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroEnterMmOrder EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroEnterMmOrder EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroEnterMmOrder EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroEnterMmOrder EXCEPT !.clientAccount = one] : one \in Sample(16) }
        \cup { [ZeroEnterMmOrder EXCEPT !.exchangeInfo = one] : one \in Sample(32) }

(***************************************************************************)
(* Replace Order: 104 bytes                                                *)
(***************************************************************************)

ReplaceOrder ==
    [ existingOrderToken    : Sample(14),
      replacementOrderToken : Sample(14),
      quantity              : Sample(8),
      price                 : Sample(4),
      openClose             : Sample(1),
      clientAccount         : Sample(16),
      customerInfo          : Sample(15),
      exchangeInfo          : Sample(32) ]

EncodeReplaceOrder(message) ==
    message.existingOrderToken
        \o message.replacementOrderToken
        \o message.quantity
        \o message.price
        \o message.openClose
        \o message.clientAccount
        \o message.customerInfo
        \o message.exchangeInfo

DecodeReplaceOrder(bytes) ==
    LET existingOrderToken == ReadBytes(bytes, 14) IN IF ~existingOrderToken.ok THEN Fail ELSE
    LET replacementOrderToken == ReadBytes(existingOrderToken.rest, 14) IN IF ~replacementOrderToken.ok THEN Fail ELSE
    LET quantity == ReadBytes(replacementOrderToken.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET openClose == ReadBytes(price.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET clientAccount == ReadBytes(openClose.rest, 16) IN IF ~clientAccount.ok THEN Fail ELSE
    LET customerInfo == ReadBytes(clientAccount.rest, 15) IN IF ~customerInfo.ok THEN Fail ELSE
    LET exchangeInfo == ReadBytes(customerInfo.rest, 32) IN IF ~exchangeInfo.ok THEN Fail ELSE
    Ok([ existingOrderToken    |-> existingOrderToken.value,
         replacementOrderToken |-> replacementOrderToken.value,
         quantity              |-> quantity.value,
         price                 |-> price.value,
         openClose             |-> openClose.value,
         clientAccount         |-> clientAccount.value,
         customerInfo          |-> customerInfo.value,
         exchangeInfo          |-> exchangeInfo.value ], exchangeInfo.rest)

ZeroReplaceOrder ==
    [ existingOrderToken    |-> [i \in 1 .. 14 |-> 0],
      replacementOrderToken |-> [i \in 1 .. 14 |-> 0],
      quantity              |-> [i \in 1 .. 8 |-> 0],
      price                 |-> [i \in 1 .. 4 |-> 0],
      openClose             |-> [i \in 1 .. 1 |-> 0],
      clientAccount         |-> [i \in 1 .. 16 |-> 0],
      customerInfo          |-> [i \in 1 .. 15 |-> 0],
      exchangeInfo          |-> [i \in 1 .. 32 |-> 0] ]

(* Replace Order at zero, then each field in turn at the values it is checked at *)
CheckedReplaceOrder ==
    { ZeroReplaceOrder }
        \cup { [ZeroReplaceOrder EXCEPT !.existingOrderToken = one] : one \in Sample(14) }
        \cup { [ZeroReplaceOrder EXCEPT !.replacementOrderToken = one] : one \in Sample(14) }
        \cup { [ZeroReplaceOrder EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroReplaceOrder EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroReplaceOrder EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroReplaceOrder EXCEPT !.clientAccount = one] : one \in Sample(16) }
        \cup { [ZeroReplaceOrder EXCEPT !.customerInfo = one] : one \in Sample(15) }
        \cup { [ZeroReplaceOrder EXCEPT !.exchangeInfo = one] : one \in Sample(32) }

(***************************************************************************)
(* Cancel Order: 14 bytes                                                  *)
(***************************************************************************)

CancelOrder ==
    [ orderToken : Sample(14) ]

EncodeCancelOrder(message) ==
    message.orderToken

DecodeCancelOrder(bytes) ==
    LET orderToken == ReadBytes(bytes, 14) IN IF ~orderToken.ok THEN Fail ELSE
    Ok([ orderToken |-> orderToken.value ], orderToken.rest)

ZeroCancelOrder ==
    [ orderToken |-> [i \in 1 .. 14 |-> 0] ]

(* Cancel Order at zero, then each field in turn at the values it is checked at *)
CheckedCancelOrder ==
    { ZeroCancelOrder }
        \cup { [ZeroCancelOrder EXCEPT !.orderToken = one] : one \in Sample(14) }

(***************************************************************************)
(* Cancel By Order Id: 13 bytes                                            *)
(***************************************************************************)

CancelByOrderId ==
    [ orderBookId : Sample(4),
      side        : Sample(1),
      orderId     : Sample(8) ]

EncodeCancelByOrderId(message) ==
    message.orderBookId
        \o message.side
        \o message.orderId

DecodeCancelByOrderId(bytes) ==
    LET orderBookId == ReadBytes(bytes, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET side == ReadBytes(orderBookId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderId == ReadBytes(side.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    Ok([ orderBookId |-> orderBookId.value,
         side        |-> side.value,
         orderId     |-> orderId.value ], orderId.rest)

ZeroCancelByOrderId ==
    [ orderBookId |-> [i \in 1 .. 4 |-> 0],
      side        |-> [i \in 1 .. 1 |-> 0],
      orderId     |-> [i \in 1 .. 8 |-> 0] ]

(* Cancel By Order Id at zero, then each field in turn at the values it is checked at *)
CheckedCancelByOrderId ==
    { ZeroCancelByOrderId }
        \cup { [ZeroCancelByOrderId EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroCancelByOrderId EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroCancelByOrderId EXCEPT !.orderId = one] : one \in Sample(8) }

(***************************************************************************)
(* Mass Cancel: 35 bytes                                                   *)
(***************************************************************************)

MassCancel ==
    [ orderToken    : Sample(14),
      underlyingId  : Sample(4),
      scope         : Sample(1),
      clientAccount : Sample(16) ]

EncodeMassCancel(message) ==
    message.orderToken
        \o message.underlyingId
        \o message.scope
        \o message.clientAccount

DecodeMassCancel(bytes) ==
    LET orderToken == ReadBytes(bytes, 14) IN IF ~orderToken.ok THEN Fail ELSE
    LET underlyingId == ReadBytes(orderToken.rest, 4) IN IF ~underlyingId.ok THEN Fail ELSE
    LET scope == ReadBytes(underlyingId.rest, 1) IN IF ~scope.ok THEN Fail ELSE
    LET clientAccount == ReadBytes(scope.rest, 16) IN IF ~clientAccount.ok THEN Fail ELSE
    Ok([ orderToken    |-> orderToken.value,
         underlyingId  |-> underlyingId.value,
         scope         |-> scope.value,
         clientAccount |-> clientAccount.value ], clientAccount.rest)

ZeroMassCancel ==
    [ orderToken    |-> [i \in 1 .. 14 |-> 0],
      underlyingId  |-> [i \in 1 .. 4 |-> 0],
      scope         |-> [i \in 1 .. 1 |-> 0],
      clientAccount |-> [i \in 1 .. 16 |-> 0] ]

(* Mass Cancel at zero, then each field in turn at the values it is checked at *)
CheckedMassCancel ==
    { ZeroMassCancel }
        \cup { [ZeroMassCancel EXCEPT !.orderToken = one] : one \in Sample(14) }
        \cup { [ZeroMassCancel EXCEPT !.underlyingId = one] : one \in Sample(4) }
        \cup { [ZeroMassCancel EXCEPT !.scope = one] : one \in Sample(1) }
        \cup { [ZeroMassCancel EXCEPT !.clientAccount = one] : one \in Sample(16) }

(***************************************************************************)
(* Unsequenced Message, selected by Unsequenced Message Type               *)
(***************************************************************************)

EnterOrderCode == 79  \* "O"
EnterMmOrderCode == 80  \* "P"
ReplaceOrderCode == 85  \* "U"
CancelOrderCode == 88  \* "X"
CancelByOrderIdCode == 89  \* "Y"
MassCancelCode == 77  \* "M"

UnsequencedMessage ==
    [ tag : {EnterOrderCode}, body : EnterOrder ]
        \cup [ tag : {EnterMmOrderCode}, body : EnterMmOrder ]
        \cup [ tag : {ReplaceOrderCode}, body : ReplaceOrder ]
        \cup [ tag : {CancelOrderCode}, body : CancelOrder ]
        \cup [ tag : {CancelByOrderIdCode}, body : CancelByOrderId ]
        \cup [ tag : {MassCancelCode}, body : MassCancel ]

EncodeUnsequencedMessage(message) ==
    CASE message.tag = EnterOrderCode -> EncodeEnterOrder(message.body)
      [] message.tag = EnterMmOrderCode -> EncodeEnterMmOrder(message.body)
      [] message.tag = ReplaceOrderCode -> EncodeReplaceOrder(message.body)
      [] message.tag = CancelOrderCode -> EncodeCancelOrder(message.body)
      [] message.tag = CancelByOrderIdCode -> EncodeCancelByOrderId(message.body)
      [] message.tag = MassCancelCode -> EncodeMassCancel(message.body)

DecodeUnsequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = EnterOrderCode -> DecodeEnterOrder(bytes)
              [] tag = EnterMmOrderCode -> DecodeEnterMmOrder(bytes)
              [] tag = ReplaceOrderCode -> DecodeReplaceOrder(bytes)
              [] tag = CancelOrderCode -> DecodeCancelOrder(bytes)
              [] tag = CancelByOrderIdCode -> DecodeCancelByOrderId(bytes)
              [] tag = MassCancelCode -> DecodeMassCancel(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroUnsequencedMessage == [tag |-> EnterOrderCode, body |-> ZeroEnterOrder]

(* Each Unsequenced Message in turn, at the values the message it names is checked at *)
CheckedUnsequencedMessage ==
    { [tag |-> EnterOrderCode, body |-> one] : one \in CheckedEnterOrder }
        \cup { [tag |-> EnterMmOrderCode, body |-> one] : one \in CheckedEnterMmOrder }
        \cup { [tag |-> ReplaceOrderCode, body |-> one] : one \in CheckedReplaceOrder }
        \cup { [tag |-> CancelOrderCode, body |-> one] : one \in CheckedCancelOrder }
        \cup { [tag |-> CancelByOrderIdCode, body |-> one] : one \in CheckedCancelByOrderId }
        \cup { [tag |-> MassCancelCode, body |-> one] : one \in CheckedMassCancel }

(***************************************************************************)
(* Unsequenced Data Packet                                                 *)
(***************************************************************************)

UnsequencedDataPacket ==
    [ unsequencedMessage : UnsequencedMessage ]

EncodeUnsequencedDataPacket(message) ==
    EncodeUIntBE(message.unsequencedMessage.tag, 1)
        \o EncodeUnsequencedMessage(message.unsequencedMessage)

DecodeUnsequencedDataPacket(bytes) ==
    LET unsequencedMessageType == ReadUIntBE(bytes, 1) IN IF ~unsequencedMessageType.ok THEN Fail ELSE
    LET unsequencedMessage == DecodeUnsequencedMessage(unsequencedMessageType.value, unsequencedMessageType.rest) IN IF ~unsequencedMessage.ok THEN Fail ELSE
    Ok([ unsequencedMessage |-> unsequencedMessage.value ], unsequencedMessage.rest)

ZeroUnsequencedDataPacket ==
    [ unsequencedMessage |-> ZeroUnsequencedMessage ]

(* Unsequenced Data Packet at zero, then each field in turn at the values it is checked at *)
CheckedUnsequencedDataPacket ==
    { ZeroUnsequencedDataPacket }
        \cup { [ZeroUnsequencedDataPacket EXCEPT !.unsequencedMessage = one] : one \in CheckedUnsequencedMessage }

(***************************************************************************)
(* Client Payload, selected by Client Packet Type                          *)
(***************************************************************************)

DebugPacketCode == 43  \* "+"
LoginRequestPacketCode == 76  \* "L"
UnsequencedDataPacketCode == 85  \* "U"
ClientHeartbeatCode == 82  \* "R"
LogoutRequestCode == 79  \* "O"

ClientPayload ==
    [ tag : {DebugPacketCode}, body : DebugPacket ]
        \cup [ tag : {LoginRequestPacketCode}, body : LoginRequestPacket ]
        \cup [ tag : {UnsequencedDataPacketCode}, body : UnsequencedDataPacket ]
        \cup [ tag : {ClientHeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {LogoutRequestCode}, body : {[empty |-> 0]} ]

EncodeClientPayload(message) ==
    CASE message.tag = DebugPacketCode -> EncodeDebugPacket(message.body)
      [] message.tag = LoginRequestPacketCode -> EncodeLoginRequestPacket(message.body)
      [] message.tag = UnsequencedDataPacketCode -> EncodeUnsequencedDataPacket(message.body)
      [] message.tag = ClientHeartbeatCode -> << >>
      [] message.tag = LogoutRequestCode -> << >>

DecodeClientPayload(tag, bytes) ==
    LET read ==
            CASE tag = DebugPacketCode -> DecodeDebugPacket(bytes)
              [] tag = LoginRequestPacketCode -> DecodeLoginRequestPacket(bytes)
              [] tag = UnsequencedDataPacketCode -> DecodeUnsequencedDataPacket(bytes)
              [] tag = ClientHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = LogoutRequestCode -> Ok([empty |-> 0], bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroClientPayload == [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]

(* Each Client Payload in turn, at the values the message it names is checked at *)
CheckedClientPayload ==
    { [tag |-> DebugPacketCode, body |-> one] : one \in CheckedDebugPacket }
        \cup { [tag |-> LoginRequestPacketCode, body |-> one] : one \in CheckedLoginRequestPacket }
        \cup { [tag |-> UnsequencedDataPacketCode, body |-> one] : one \in CheckedUnsequencedDataPacket }
        \cup { [tag |-> ClientHeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> LogoutRequestCode, body |-> [empty |-> 0]] }

(***************************************************************************)
(* Client Soup Bin Tcp Packet, framed by Packet Length                     *)
(***************************************************************************)

ClientSoupBinTcpPacket ==
    [ clientPayload : ClientPayload ]

EncodeClientSoupBinTcpPacketBody(message) ==
    EncodeUIntBE(message.clientPayload.tag, 1)
        \o EncodeClientPayload(message.clientPayload)

(* Packet Length counts the bytes it frames, so it is written from them *)
EncodeClientSoupBinTcpPacket(message) ==
    LET body == EncodeClientSoupBinTcpPacketBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeClientSoupBinTcpPacketBody(bytes) ==
    LET clientPacketType == ReadUIntBE(bytes, 1) IN IF ~clientPacketType.ok THEN Fail ELSE
    LET clientPayload == DecodeClientPayload(clientPacketType.value, clientPacketType.rest) IN IF ~clientPayload.ok THEN Fail ELSE
    Ok([ clientPayload |-> clientPayload.value ], clientPayload.rest)

DecodeClientSoupBinTcpPacket(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeClientSoupBinTcpPacketBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroClientSoupBinTcpPacket ==
    [ clientPayload |-> ZeroClientPayload ]

(* Client Soup Bin Tcp Packet at zero, then each field in turn at the values it is checked at *)
CheckedClientSoupBinTcpPacket ==
    { ZeroClientSoupBinTcpPacket }
        \cup { [ZeroClientSoupBinTcpPacket EXCEPT !.clientPayload = one] : one \in CheckedClientPayload }

(* A run of Client Soup Bin Tcp Packet, written one after another *)
RECURSIVE EncodeClientSoupBinTcpPacketList(_)
EncodeClientSoupBinTcpPacketList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeClientSoupBinTcpPacket(Head(messages)) \o EncodeClientSoupBinTcpPacketList(Tail(messages))

(* As many Client Soup Bin Tcp Packet as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadClientSoupBinTcpPacketAll(_)
ReadClientSoupBinTcpPacketAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeClientSoupBinTcpPacket(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadClientSoupBinTcpPacketAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Client Soup Bin Tcp Packet of each kind, for the lists that carry them *)
OneClientSoupBinTcpPacket ==
    { [ZeroClientSoupBinTcpPacket EXCEPT !.clientPayload = [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]],
      [ZeroClientSoupBinTcpPacket EXCEPT !.clientPayload = [tag |-> LoginRequestPacketCode, body |-> ZeroLoginRequestPacket]],
      [ZeroClientSoupBinTcpPacket EXCEPT !.clientPayload = [tag |-> UnsequencedDataPacketCode, body |-> ZeroUnsequencedDataPacket]],
      [ZeroClientSoupBinTcpPacket EXCEPT !.clientPayload = [tag |-> ClientHeartbeatCode, body |-> [empty |-> 0]]],
      [ZeroClientSoupBinTcpPacket EXCEPT !.clientPayload = [tag |-> LogoutRequestCode, body |-> [empty |-> 0]]] }

(***************************************************************************)
(* Client Packet                                                           *)
(***************************************************************************)

ClientPacket ==
    [ clientSoupBinTcpPacket : SampleLists(OneClientSoupBinTcpPacket) ]

EncodeClientPacket(message) ==
    EncodeClientSoupBinTcpPacketList(message.clientSoupBinTcpPacket)

DecodeClientPacket(bytes) ==
    LET clientSoupBinTcpPacket == ReadClientSoupBinTcpPacketAll(bytes) IN IF ~clientSoupBinTcpPacket.ok THEN Fail ELSE
    Ok([ clientSoupBinTcpPacket |-> clientSoupBinTcpPacket.value ], clientSoupBinTcpPacket.rest)

ZeroClientPacket ==
    [ clientSoupBinTcpPacket |-> << >> ]

(* Client Packet at zero, then each field in turn at the values it is checked at *)
CheckedClientPacket ==
    { ZeroClientPacket }
        \cup { [ZeroClientPacket EXCEPT !.clientSoupBinTcpPacket = one] : one \in SampleLists(OneClientSoupBinTcpPacket) }

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

(* Every Login Request Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRequestPacket ==
    \A message \in CheckedLoginRequestPacket :
        LET read == DecodeLoginRequestPacket(EncodeLoginRequestPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Enter Order decodes back to what was encoded, and leaves nothing over *)
RoundTripEnterOrder ==
    \A message \in CheckedEnterOrder :
        LET read == DecodeEnterOrder(EncodeEnterOrder(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Enter Mm Order decodes back to what was encoded, and leaves nothing over *)
RoundTripEnterMmOrder ==
    \A message \in CheckedEnterMmOrder :
        LET read == DecodeEnterMmOrder(EncodeEnterMmOrder(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Replace Order decodes back to what was encoded, and leaves nothing over *)
RoundTripReplaceOrder ==
    \A message \in CheckedReplaceOrder :
        LET read == DecodeReplaceOrder(EncodeReplaceOrder(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Order decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelOrder ==
    \A message \in CheckedCancelOrder :
        LET read == DecodeCancelOrder(EncodeCancelOrder(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel By Order Id decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelByOrderId ==
    \A message \in CheckedCancelByOrderId :
        LET read == DecodeCancelByOrderId(EncodeCancelByOrderId(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Cancel decodes back to what was encoded, and leaves nothing over *)
RoundTripMassCancel ==
    \A message \in CheckedMassCancel :
        LET read == DecodeMassCancel(EncodeMassCancel(message))
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

(* Every Client Soup Bin Tcp Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripClientSoupBinTcpPacket ==
    \A message \in CheckedClientSoupBinTcpPacket :
        LET read == DecodeClientSoupBinTcpPacket(EncodeClientSoupBinTcpPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripClientPacket ==
    \A message \in CheckedClientPacket :
        LET read == DecodeClientPacket(EncodeClientPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Unsequenced Message is selected by the Unsequenced Message Type it is written under *)
SelectsUnsequencedMessage ==
    \A message \in CheckedUnsequencedMessage :
        LET read == DecodeUnsequencedMessage(message.tag, EncodeUnsequencedMessage(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Client Payload is selected by the Client Packet Type it is written under *)
SelectsClientPayload ==
    \A message \in CheckedClientPayload :
        LET read == DecodeClientPayload(message.tag, EncodeClientPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Packet Length is written from the bytes it frames *)
FramesClientSoupBinTcpPacket ==
    \A message \in CheckedClientSoupBinTcpPacket :
        LET bytes == EncodeClientSoupBinTcpPacket(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
