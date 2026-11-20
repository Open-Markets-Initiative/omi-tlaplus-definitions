------------------------ MODULE Wse_OrderBook_v6_8 -------------------------
(***************************************************************************)
(* Giełda Papierów Wartościowych w Warszawie Warsaw Stock Exchange Order   *)
(* Book v6.8                                                               *)
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
(* Note: a Delivery Flag of 16 to 255 says Message Buffer was transformed, *)
(* and one of 0 to 15 that it was not, so it is then read as it stands.    *)
(*                                                                         *)
(* Note: Message Buffer untransformed is as many Message as Number Msg     *)
(* Entries says, which is read beside the flag and handed to the choice:   *)
(* the count says how many the bytes hold, and transformed they hold a run *)
(* no reading of them states, so it is carried rather than written from    *)
(* the run.                                                                *)
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
(* Order Update Market Sheet Message: 60 bytes                             *)
(***************************************************************************)

OrderUpdateMarketSheetMessage ==
    [ symbolIndex            : Sample(4),
      sourceTime             : Sample(4),
      sourceSeqNum           : Sample(4),
      price                  : Sample(4),
      aggregatedVolume       : Sample(4),
      volume                 : Sample(4),
      linkId                 : Sample(4),
      orderId                : Sample(4),
      systemId               : Sample(4),
      sourceTimeMicroSecs    : Sample(2),
      numberOrders           : Sample(2),
      side                   : Sample(1),
      orderType              : Sample(1),
      actionType             : Sample(1),
      priceScaleCode         : Sample(1),
      orderDate              : Sample(4),
      orderPriorityDate      : Sample(4),
      orderPriorityTime      : Sample(4),
      orderPriorityMicroSecs : Sample(2),
      orderOrigin            : Sample(1),
      reserved1              : Sample(1) ]

EncodeOrderUpdateMarketSheetMessage(message) ==
    message.symbolIndex
        \o message.sourceTime
        \o message.sourceSeqNum
        \o message.price
        \o message.aggregatedVolume
        \o message.volume
        \o message.linkId
        \o message.orderId
        \o message.systemId
        \o message.sourceTimeMicroSecs
        \o message.numberOrders
        \o message.side
        \o message.orderType
        \o message.actionType
        \o message.priceScaleCode
        \o message.orderDate
        \o message.orderPriorityDate
        \o message.orderPriorityTime
        \o message.orderPriorityMicroSecs
        \o message.orderOrigin
        \o message.reserved1

DecodeOrderUpdateMarketSheetMessage(bytes) ==
    LET symbolIndex == ReadBytes(bytes, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET sourceTime == ReadBytes(symbolIndex.rest, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceSeqNum == ReadBytes(sourceTime.rest, 4) IN IF ~sourceSeqNum.ok THEN Fail ELSE
    LET price == ReadBytes(sourceSeqNum.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET aggregatedVolume == ReadBytes(price.rest, 4) IN IF ~aggregatedVolume.ok THEN Fail ELSE
    LET volume == ReadBytes(aggregatedVolume.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET linkId == ReadBytes(volume.rest, 4) IN IF ~linkId.ok THEN Fail ELSE
    LET orderId == ReadBytes(linkId.rest, 4) IN IF ~orderId.ok THEN Fail ELSE
    LET systemId == ReadBytes(orderId.rest, 4) IN IF ~systemId.ok THEN Fail ELSE
    LET sourceTimeMicroSecs == ReadBytes(systemId.rest, 2) IN IF ~sourceTimeMicroSecs.ok THEN Fail ELSE
    LET numberOrders == ReadBytes(sourceTimeMicroSecs.rest, 2) IN IF ~numberOrders.ok THEN Fail ELSE
    LET side == ReadBytes(numberOrders.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderType == ReadBytes(side.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET actionType == ReadBytes(orderType.rest, 1) IN IF ~actionType.ok THEN Fail ELSE
    LET priceScaleCode == ReadBytes(actionType.rest, 1) IN IF ~priceScaleCode.ok THEN Fail ELSE
    LET orderDate == ReadBytes(priceScaleCode.rest, 4) IN IF ~orderDate.ok THEN Fail ELSE
    LET orderPriorityDate == ReadBytes(orderDate.rest, 4) IN IF ~orderPriorityDate.ok THEN Fail ELSE
    LET orderPriorityTime == ReadBytes(orderPriorityDate.rest, 4) IN IF ~orderPriorityTime.ok THEN Fail ELSE
    LET orderPriorityMicroSecs == ReadBytes(orderPriorityTime.rest, 2) IN IF ~orderPriorityMicroSecs.ok THEN Fail ELSE
    LET orderOrigin == ReadBytes(orderPriorityMicroSecs.rest, 1) IN IF ~orderOrigin.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(orderOrigin.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ symbolIndex            |-> symbolIndex.value,
         sourceTime             |-> sourceTime.value,
         sourceSeqNum           |-> sourceSeqNum.value,
         price                  |-> price.value,
         aggregatedVolume       |-> aggregatedVolume.value,
         volume                 |-> volume.value,
         linkId                 |-> linkId.value,
         orderId                |-> orderId.value,
         systemId               |-> systemId.value,
         sourceTimeMicroSecs    |-> sourceTimeMicroSecs.value,
         numberOrders           |-> numberOrders.value,
         side                   |-> side.value,
         orderType              |-> orderType.value,
         actionType             |-> actionType.value,
         priceScaleCode         |-> priceScaleCode.value,
         orderDate              |-> orderDate.value,
         orderPriorityDate      |-> orderPriorityDate.value,
         orderPriorityTime      |-> orderPriorityTime.value,
         orderPriorityMicroSecs |-> orderPriorityMicroSecs.value,
         orderOrigin            |-> orderOrigin.value,
         reserved1              |-> reserved1.value ], reserved1.rest)

ZeroOrderUpdateMarketSheetMessage ==
    [ symbolIndex            |-> [i \in 1 .. 4 |-> 0],
      sourceTime             |-> [i \in 1 .. 4 |-> 0],
      sourceSeqNum           |-> [i \in 1 .. 4 |-> 0],
      price                  |-> [i \in 1 .. 4 |-> 0],
      aggregatedVolume       |-> [i \in 1 .. 4 |-> 0],
      volume                 |-> [i \in 1 .. 4 |-> 0],
      linkId                 |-> [i \in 1 .. 4 |-> 0],
      orderId                |-> [i \in 1 .. 4 |-> 0],
      systemId               |-> [i \in 1 .. 4 |-> 0],
      sourceTimeMicroSecs    |-> [i \in 1 .. 2 |-> 0],
      numberOrders           |-> [i \in 1 .. 2 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      orderType              |-> [i \in 1 .. 1 |-> 0],
      actionType             |-> [i \in 1 .. 1 |-> 0],
      priceScaleCode         |-> [i \in 1 .. 1 |-> 0],
      orderDate              |-> [i \in 1 .. 4 |-> 0],
      orderPriorityDate      |-> [i \in 1 .. 4 |-> 0],
      orderPriorityTime      |-> [i \in 1 .. 4 |-> 0],
      orderPriorityMicroSecs |-> [i \in 1 .. 2 |-> 0],
      orderOrigin            |-> [i \in 1 .. 1 |-> 0],
      reserved1              |-> [i \in 1 .. 1 |-> 0] ]

(* Order Update Market Sheet Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderUpdateMarketSheetMessage ==
    { ZeroOrderUpdateMarketSheetMessage }
        \cup { [ZeroOrderUpdateMarketSheetMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroOrderUpdateMarketSheetMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroOrderUpdateMarketSheetMessage EXCEPT !.sourceSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroOrderUpdateMarketSheetMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderUpdateMarketSheetMessage EXCEPT !.aggregatedVolume = one] : one \in Sample(4) }
        \cup { [ZeroOrderUpdateMarketSheetMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroOrderUpdateMarketSheetMessage EXCEPT !.linkId = one] : one \in Sample(4) }
        \cup { [ZeroOrderUpdateMarketSheetMessage EXCEPT !.orderId = one] : one \in Sample(4) }
        \cup { [ZeroOrderUpdateMarketSheetMessage EXCEPT !.systemId = one] : one \in Sample(4) }
        \cup { [ZeroOrderUpdateMarketSheetMessage EXCEPT !.sourceTimeMicroSecs = one] : one \in Sample(2) }
        \cup { [ZeroOrderUpdateMarketSheetMessage EXCEPT !.numberOrders = one] : one \in Sample(2) }
        \cup { [ZeroOrderUpdateMarketSheetMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderUpdateMarketSheetMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroOrderUpdateMarketSheetMessage EXCEPT !.actionType = one] : one \in Sample(1) }
        \cup { [ZeroOrderUpdateMarketSheetMessage EXCEPT !.priceScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroOrderUpdateMarketSheetMessage EXCEPT !.orderDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderUpdateMarketSheetMessage EXCEPT !.orderPriorityDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderUpdateMarketSheetMessage EXCEPT !.orderPriorityTime = one] : one \in Sample(4) }
        \cup { [ZeroOrderUpdateMarketSheetMessage EXCEPT !.orderPriorityMicroSecs = one] : one \in Sample(2) }
        \cup { [ZeroOrderUpdateMarketSheetMessage EXCEPT !.orderOrigin = one] : one \in Sample(1) }
        \cup { [ZeroOrderUpdateMarketSheetMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Book Retransmission Delimiter Message: 12 bytes                   *)
(***************************************************************************)

OrderBookRetransmissionDelimiterMessage ==
    [ sourceTime              : Sample(4),
      sourceSeqNum            : Sample(4),
      applicationId           : Sample(2),
      instanceNum             : Sample(1),
      retransmissionIndicator : Sample(1) ]

EncodeOrderBookRetransmissionDelimiterMessage(message) ==
    message.sourceTime
        \o message.sourceSeqNum
        \o message.applicationId
        \o message.instanceNum
        \o message.retransmissionIndicator

DecodeOrderBookRetransmissionDelimiterMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceSeqNum == ReadBytes(sourceTime.rest, 4) IN IF ~sourceSeqNum.ok THEN Fail ELSE
    LET applicationId == ReadBytes(sourceSeqNum.rest, 2) IN IF ~applicationId.ok THEN Fail ELSE
    LET instanceNum == ReadBytes(applicationId.rest, 1) IN IF ~instanceNum.ok THEN Fail ELSE
    LET retransmissionIndicator == ReadBytes(instanceNum.rest, 1) IN IF ~retransmissionIndicator.ok THEN Fail ELSE
    Ok([ sourceTime              |-> sourceTime.value,
         sourceSeqNum            |-> sourceSeqNum.value,
         applicationId           |-> applicationId.value,
         instanceNum             |-> instanceNum.value,
         retransmissionIndicator |-> retransmissionIndicator.value ], retransmissionIndicator.rest)

ZeroOrderBookRetransmissionDelimiterMessage ==
    [ sourceTime              |-> [i \in 1 .. 4 |-> 0],
      sourceSeqNum            |-> [i \in 1 .. 4 |-> 0],
      applicationId           |-> [i \in 1 .. 2 |-> 0],
      instanceNum             |-> [i \in 1 .. 1 |-> 0],
      retransmissionIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Order Book Retransmission Delimiter Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderBookRetransmissionDelimiterMessage ==
    { ZeroOrderBookRetransmissionDelimiterMessage }
        \cup { [ZeroOrderBookRetransmissionDelimiterMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookRetransmissionDelimiterMessage EXCEPT !.sourceSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookRetransmissionDelimiterMessage EXCEPT !.applicationId = one] : one \in Sample(2) }
        \cup { [ZeroOrderBookRetransmissionDelimiterMessage EXCEPT !.instanceNum = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookRetransmissionDelimiterMessage EXCEPT !.retransmissionIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

OrderUpdateMarketSheetMessageCode == 230  \* 0xe6
OrderBookRetransmissionDelimiterMessageCode == 231  \* 0xe7

Payload ==
    [ tag : {OrderUpdateMarketSheetMessageCode}, body : OrderUpdateMarketSheetMessage ]
        \cup [ tag : {OrderBookRetransmissionDelimiterMessageCode}, body : OrderBookRetransmissionDelimiterMessage ]

EncodePayload(message) ==
    CASE message.tag = OrderUpdateMarketSheetMessageCode -> EncodeOrderUpdateMarketSheetMessage(message.body)
      [] message.tag = OrderBookRetransmissionDelimiterMessageCode -> EncodeOrderBookRetransmissionDelimiterMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = OrderUpdateMarketSheetMessageCode -> DecodeOrderUpdateMarketSheetMessage(bytes)
              [] tag = OrderBookRetransmissionDelimiterMessageCode -> DecodeOrderBookRetransmissionDelimiterMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> OrderUpdateMarketSheetMessageCode, body |-> ZeroOrderUpdateMarketSheetMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> OrderUpdateMarketSheetMessageCode, body |-> one] : one \in CheckedOrderUpdateMarketSheetMessage }
        \cup { [tag |-> OrderBookRetransmissionDelimiterMessageCode, body |-> one] : one \in CheckedOrderBookRetransmissionDelimiterMessage }

(***************************************************************************)
(* Message, framed by Message Size                                         *)
(***************************************************************************)

Message ==
    [ payload : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntBE(message.payload.tag, 2)
        \o EncodePayload(message.payload)

(* Message Size counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntBE(bytes, 2) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> OrderUpdateMarketSheetMessageCode, body |-> ZeroOrderUpdateMarketSheetMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderBookRetransmissionDelimiterMessageCode, body |-> ZeroOrderBookRetransmissionDelimiterMessage]] }

(***************************************************************************)
(* Message Buffer, selected by Delivery Flag                               *)
(***************************************************************************)

MessageBufferZlibCode == 16  \* 0x10
MessageBufferPlainCode == 0  \* 0x00

MessageBufferBody ==
    [ tag : 16 .. 255, body : MessageBufferZlib ]
        \cup { [tag |-> tag, body |-> one] : tag \in {0, 15}, one \in SampleLists(OneMessage) }

EncodeMessageBufferBody(message) ==
    CASE message.tag \in 16 .. 255 -> EncodeMessageBufferZlib(message.body)
      [] message.tag \in 0 .. 15 -> EncodeMessageList(message.body)

(* How many Message a Message Buffer holds, which is what Number Msg Entries states. *)
(* A case that is no run of them says nothing about the number, so it holds whatever was stated. *)
CountMessageBufferBody(choice, stated) ==
    CASE choice.tag \in 16 .. 255 -> stated
      [] choice.tag \in 0 .. 15 -> Len(choice.body)

DecodeMessageBufferBody(tag, count, bytes) ==
    LET read ==
            CASE tag \in 16 .. 255 -> DecodeMessageBufferZlib(bytes)
              [] tag \in 0 .. 15 -> ReadMessageList(bytes, count)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroMessageBufferBody == [tag |-> MessageBufferZlibCode, body |-> ZeroMessageBufferZlib]

(* Each Message Buffer in turn, at the values the message it names is checked at *)
CheckedMessageBufferBody ==
    { [tag |-> tag, body |-> one] : tag \in {16, 255}, one \in CheckedMessageBufferZlib }
        \cup { [tag |-> tag, body |-> one] : tag \in {0, 15}, one \in SampleLists(OneMessage) }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ packetLength         : Sample(2),
      packetType           : Sample(2),
      packetSequenceNumber : Sample(4),
      sendTime             : Sample(4),
      serviceId            : Sample(2),
      numberMsgEntries     : 0 .. 255,
      messageBuffer        : MessageBufferBody ]

EncodePacket(message) ==
    message.packetLength
        \o message.packetType
        \o message.packetSequenceNumber
        \o message.sendTime
        \o message.serviceId
        \o EncodeUIntBE(message.messageBuffer.tag, 1)
        \o EncodeUIntBE(message.numberMsgEntries, 1)
        \o EncodeMessageBufferBody(message.messageBuffer)

DecodePacket(bytes) ==
    LET packetLength == ReadBytes(bytes, 2) IN IF ~packetLength.ok THEN Fail ELSE
    LET packetType == ReadBytes(packetLength.rest, 2) IN IF ~packetType.ok THEN Fail ELSE
    LET packetSequenceNumber == ReadBytes(packetType.rest, 4) IN IF ~packetSequenceNumber.ok THEN Fail ELSE
    LET sendTime == ReadBytes(packetSequenceNumber.rest, 4) IN IF ~sendTime.ok THEN Fail ELSE
    LET serviceId == ReadBytes(sendTime.rest, 2) IN IF ~serviceId.ok THEN Fail ELSE
    LET deliveryFlag == ReadUIntBE(serviceId.rest, 1) IN IF ~deliveryFlag.ok THEN Fail ELSE
    LET numberMsgEntries == ReadUIntBE(deliveryFlag.rest, 1) IN IF ~numberMsgEntries.ok THEN Fail ELSE
    LET messageBuffer == DecodeMessageBufferBody(deliveryFlag.value, numberMsgEntries.value, numberMsgEntries.rest) IN IF ~messageBuffer.ok THEN Fail ELSE
    Ok([ packetLength         |-> packetLength.value,
         packetType           |-> packetType.value,
         packetSequenceNumber |-> packetSequenceNumber.value,
         sendTime             |-> sendTime.value,
         serviceId            |-> serviceId.value,
         numberMsgEntries     |-> numberMsgEntries.value,
         messageBuffer        |-> messageBuffer.value ], messageBuffer.rest)

ZeroPacket ==
    [ packetLength         |-> [i \in 1 .. 2 |-> 0],
      packetType           |-> [i \in 1 .. 2 |-> 0],
      packetSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      sendTime             |-> [i \in 1 .. 4 |-> 0],
      serviceId            |-> [i \in 1 .. 2 |-> 0],
      numberMsgEntries     |-> 0,
      messageBuffer        |-> ZeroMessageBufferBody ]

(* Packet at zero, then each field in turn at the values it is checked at *)
(* Number Msg Entries is varied with the Message Buffer it counts, which is read as many as it says *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.packetLength = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.packetType = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.packetSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.sendTime = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.serviceId = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.numberMsgEntries = one] : one \in {0, 1, 255} }
        \cup { [ZeroPacket EXCEPT !.numberMsgEntries = CountMessageBufferBody(one, 0), !.messageBuffer = one] : one \in CheckedMessageBufferBody }

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

(* Every Order Update Market Sheet Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderUpdateMarketSheetMessage ==
    \A message \in CheckedOrderUpdateMarketSheetMessage :
        LET read == DecodeOrderUpdateMarketSheetMessage(EncodeOrderUpdateMarketSheetMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Book Retransmission Delimiter Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderBookRetransmissionDelimiterMessage ==
    \A message \in CheckedOrderBookRetransmissionDelimiterMessage :
        LET read == DecodeOrderBookRetransmissionDelimiterMessage(EncodeOrderBookRetransmissionDelimiterMessage(message))
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
        LET sent == EncodePayload(message)
            read == DecodePayload(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Message Buffer is selected by the Delivery Flag it is written under *)
SelectsMessageBufferBody ==
    \A message \in CheckedMessageBufferBody :
        LET sent == EncodeMessageBufferBody(message)
            read == DecodeMessageBufferBody(message.tag, CountMessageBufferBody(message, 0), sent)
        IN  read.ok /\ read.value.tag = message.tag

(* Message Size is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
