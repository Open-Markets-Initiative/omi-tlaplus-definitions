------------------- MODULE BmvMarketData_Product37_v1_1 --------------------
(***************************************************************************)
(* Bolsa Mexicana de Valores Bmv Market Data Product 37 v1.1               *)
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
(* Order Adition Message: 35 bytes                                         *)
(***************************************************************************)

OrderAditionMessage ==
    [ idInstrument  : Sample(4),
      dateAndHour   : Sample(8),
      folio         : Sample(4),
      direction     : Sample(1),
      volume        : Sample(4),
      price         : Sample(8),
      participant   : Sample(5),
      operationType : Sample(1) ]

EncodeOrderAditionMessage(message) ==
    message.idInstrument
        \o message.dateAndHour
        \o message.folio
        \o message.direction
        \o message.volume
        \o message.price
        \o message.participant
        \o message.operationType

DecodeOrderAditionMessage(bytes) ==
    LET idInstrument == ReadBytes(bytes, 4) IN IF ~idInstrument.ok THEN Fail ELSE
    LET dateAndHour == ReadBytes(idInstrument.rest, 8) IN IF ~dateAndHour.ok THEN Fail ELSE
    LET folio == ReadBytes(dateAndHour.rest, 4) IN IF ~folio.ok THEN Fail ELSE
    LET direction == ReadBytes(folio.rest, 1) IN IF ~direction.ok THEN Fail ELSE
    LET volume == ReadBytes(direction.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET price == ReadBytes(volume.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET participant == ReadBytes(price.rest, 5) IN IF ~participant.ok THEN Fail ELSE
    LET operationType == ReadBytes(participant.rest, 1) IN IF ~operationType.ok THEN Fail ELSE
    Ok([ idInstrument  |-> idInstrument.value,
         dateAndHour   |-> dateAndHour.value,
         folio         |-> folio.value,
         direction     |-> direction.value,
         volume        |-> volume.value,
         price         |-> price.value,
         participant   |-> participant.value,
         operationType |-> operationType.value ], operationType.rest)

ZeroOrderAditionMessage ==
    [ idInstrument  |-> [i \in 1 .. 4 |-> 0],
      dateAndHour   |-> [i \in 1 .. 8 |-> 0],
      folio         |-> [i \in 1 .. 4 |-> 0],
      direction     |-> [i \in 1 .. 1 |-> 0],
      volume        |-> [i \in 1 .. 4 |-> 0],
      price         |-> [i \in 1 .. 8 |-> 0],
      participant   |-> [i \in 1 .. 5 |-> 0],
      operationType |-> [i \in 1 .. 1 |-> 0] ]

(* Order Adition Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderAditionMessage ==
    { ZeroOrderAditionMessage }
        \cup { [ZeroOrderAditionMessage EXCEPT !.idInstrument = one] : one \in Sample(4) }
        \cup { [ZeroOrderAditionMessage EXCEPT !.dateAndHour = one] : one \in Sample(8) }
        \cup { [ZeroOrderAditionMessage EXCEPT !.folio = one] : one \in Sample(4) }
        \cup { [ZeroOrderAditionMessage EXCEPT !.direction = one] : one \in Sample(1) }
        \cup { [ZeroOrderAditionMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroOrderAditionMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderAditionMessage EXCEPT !.participant = one] : one \in Sample(5) }
        \cup { [ZeroOrderAditionMessage EXCEPT !.operationType = one] : one \in Sample(1) }

(***************************************************************************)
(* Execution Of Orders Message: 33 bytes                                   *)
(***************************************************************************)

ExecutionOfOrdersMessage ==
    [ idInstrument   : Sample(4),
      date           : Sample(8),
      folio          : Sample(4),
      volume         : Sample(4),
      tradeNumber    : Sample(4),
      executionPrice : Sample(8),
      operationType  : Sample(1) ]

EncodeExecutionOfOrdersMessage(message) ==
    message.idInstrument
        \o message.date
        \o message.folio
        \o message.volume
        \o message.tradeNumber
        \o message.executionPrice
        \o message.operationType

DecodeExecutionOfOrdersMessage(bytes) ==
    LET idInstrument == ReadBytes(bytes, 4) IN IF ~idInstrument.ok THEN Fail ELSE
    LET date == ReadBytes(idInstrument.rest, 8) IN IF ~date.ok THEN Fail ELSE
    LET folio == ReadBytes(date.rest, 4) IN IF ~folio.ok THEN Fail ELSE
    LET volume == ReadBytes(folio.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(volume.rest, 4) IN IF ~tradeNumber.ok THEN Fail ELSE
    LET executionPrice == ReadBytes(tradeNumber.rest, 8) IN IF ~executionPrice.ok THEN Fail ELSE
    LET operationType == ReadBytes(executionPrice.rest, 1) IN IF ~operationType.ok THEN Fail ELSE
    Ok([ idInstrument   |-> idInstrument.value,
         date           |-> date.value,
         folio          |-> folio.value,
         volume         |-> volume.value,
         tradeNumber    |-> tradeNumber.value,
         executionPrice |-> executionPrice.value,
         operationType  |-> operationType.value ], operationType.rest)

ZeroExecutionOfOrdersMessage ==
    [ idInstrument   |-> [i \in 1 .. 4 |-> 0],
      date           |-> [i \in 1 .. 8 |-> 0],
      folio          |-> [i \in 1 .. 4 |-> 0],
      volume         |-> [i \in 1 .. 4 |-> 0],
      tradeNumber    |-> [i \in 1 .. 4 |-> 0],
      executionPrice |-> [i \in 1 .. 8 |-> 0],
      operationType  |-> [i \in 1 .. 1 |-> 0] ]

(* Execution Of Orders Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionOfOrdersMessage ==
    { ZeroExecutionOfOrdersMessage }
        \cup { [ZeroExecutionOfOrdersMessage EXCEPT !.idInstrument = one] : one \in Sample(4) }
        \cup { [ZeroExecutionOfOrdersMessage EXCEPT !.date = one] : one \in Sample(8) }
        \cup { [ZeroExecutionOfOrdersMessage EXCEPT !.folio = one] : one \in Sample(4) }
        \cup { [ZeroExecutionOfOrdersMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroExecutionOfOrdersMessage EXCEPT !.tradeNumber = one] : one \in Sample(4) }
        \cup { [ZeroExecutionOfOrdersMessage EXCEPT !.executionPrice = one] : one \in Sample(8) }
        \cup { [ZeroExecutionOfOrdersMessage EXCEPT !.operationType = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Cancellation Message: 17 bytes                                    *)
(***************************************************************************)

OrderCancellationMessage ==
    [ idInstrument  : Sample(4),
      date          : Sample(8),
      folio         : Sample(4),
      operationType : Sample(1) ]

EncodeOrderCancellationMessage(message) ==
    message.idInstrument
        \o message.date
        \o message.folio
        \o message.operationType

DecodeOrderCancellationMessage(bytes) ==
    LET idInstrument == ReadBytes(bytes, 4) IN IF ~idInstrument.ok THEN Fail ELSE
    LET date == ReadBytes(idInstrument.rest, 8) IN IF ~date.ok THEN Fail ELSE
    LET folio == ReadBytes(date.rest, 4) IN IF ~folio.ok THEN Fail ELSE
    LET operationType == ReadBytes(folio.rest, 1) IN IF ~operationType.ok THEN Fail ELSE
    Ok([ idInstrument  |-> idInstrument.value,
         date          |-> date.value,
         folio         |-> folio.value,
         operationType |-> operationType.value ], operationType.rest)

ZeroOrderCancellationMessage ==
    [ idInstrument  |-> [i \in 1 .. 4 |-> 0],
      date          |-> [i \in 1 .. 8 |-> 0],
      folio         |-> [i \in 1 .. 4 |-> 0],
      operationType |-> [i \in 1 .. 1 |-> 0] ]

(* Order Cancellation Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancellationMessage ==
    { ZeroOrderCancellationMessage }
        \cup { [ZeroOrderCancellationMessage EXCEPT !.idInstrument = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancellationMessage EXCEPT !.date = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancellationMessage EXCEPT !.folio = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancellationMessage EXCEPT !.operationType = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Change Message: 42 bytes                                          *)
(***************************************************************************)

OrderChangeMessage ==
    [ idInstrument  : Sample(4),
      originalDate  : Sample(8),
      originalFolio : Sample(4),
      newDate       : Sample(8),
      newFolio      : Sample(4),
      direction     : Sample(1),
      volume        : Sample(4),
      price         : Sample(8),
      operationType : Sample(1) ]

EncodeOrderChangeMessage(message) ==
    message.idInstrument
        \o message.originalDate
        \o message.originalFolio
        \o message.newDate
        \o message.newFolio
        \o message.direction
        \o message.volume
        \o message.price
        \o message.operationType

DecodeOrderChangeMessage(bytes) ==
    LET idInstrument == ReadBytes(bytes, 4) IN IF ~idInstrument.ok THEN Fail ELSE
    LET originalDate == ReadBytes(idInstrument.rest, 8) IN IF ~originalDate.ok THEN Fail ELSE
    LET originalFolio == ReadBytes(originalDate.rest, 4) IN IF ~originalFolio.ok THEN Fail ELSE
    LET newDate == ReadBytes(originalFolio.rest, 8) IN IF ~newDate.ok THEN Fail ELSE
    LET newFolio == ReadBytes(newDate.rest, 4) IN IF ~newFolio.ok THEN Fail ELSE
    LET direction == ReadBytes(newFolio.rest, 1) IN IF ~direction.ok THEN Fail ELSE
    LET volume == ReadBytes(direction.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET price == ReadBytes(volume.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET operationType == ReadBytes(price.rest, 1) IN IF ~operationType.ok THEN Fail ELSE
    Ok([ idInstrument  |-> idInstrument.value,
         originalDate  |-> originalDate.value,
         originalFolio |-> originalFolio.value,
         newDate       |-> newDate.value,
         newFolio      |-> newFolio.value,
         direction     |-> direction.value,
         volume        |-> volume.value,
         price         |-> price.value,
         operationType |-> operationType.value ], operationType.rest)

ZeroOrderChangeMessage ==
    [ idInstrument  |-> [i \in 1 .. 4 |-> 0],
      originalDate  |-> [i \in 1 .. 8 |-> 0],
      originalFolio |-> [i \in 1 .. 4 |-> 0],
      newDate       |-> [i \in 1 .. 8 |-> 0],
      newFolio      |-> [i \in 1 .. 4 |-> 0],
      direction     |-> [i \in 1 .. 1 |-> 0],
      volume        |-> [i \in 1 .. 4 |-> 0],
      price         |-> [i \in 1 .. 8 |-> 0],
      operationType |-> [i \in 1 .. 1 |-> 0] ]

(* Order Change Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderChangeMessage ==
    { ZeroOrderChangeMessage }
        \cup { [ZeroOrderChangeMessage EXCEPT !.idInstrument = one] : one \in Sample(4) }
        \cup { [ZeroOrderChangeMessage EXCEPT !.originalDate = one] : one \in Sample(8) }
        \cup { [ZeroOrderChangeMessage EXCEPT !.originalFolio = one] : one \in Sample(4) }
        \cup { [ZeroOrderChangeMessage EXCEPT !.newDate = one] : one \in Sample(8) }
        \cup { [ZeroOrderChangeMessage EXCEPT !.newFolio = one] : one \in Sample(4) }
        \cup { [ZeroOrderChangeMessage EXCEPT !.direction = one] : one \in Sample(1) }
        \cup { [ZeroOrderChangeMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroOrderChangeMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderChangeMessage EXCEPT !.operationType = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

OrderAditionMessageCode == 16707  \* 0x4143
ExecutionOfOrdersMessageCode == 17219  \* 0x4343
OrderCancellationMessageCode == 17475  \* 0x4443
OrderChangeMessageCode == 17987  \* 0x4643

Payload ==
    [ tag : {OrderAditionMessageCode}, body : OrderAditionMessage ]
        \cup [ tag : {ExecutionOfOrdersMessageCode}, body : ExecutionOfOrdersMessage ]
        \cup [ tag : {OrderCancellationMessageCode}, body : OrderCancellationMessage ]
        \cup [ tag : {OrderChangeMessageCode}, body : OrderChangeMessage ]

EncodePayload(message) ==
    CASE message.tag = OrderAditionMessageCode -> EncodeOrderAditionMessage(message.body)
      [] message.tag = ExecutionOfOrdersMessageCode -> EncodeExecutionOfOrdersMessage(message.body)
      [] message.tag = OrderCancellationMessageCode -> EncodeOrderCancellationMessage(message.body)
      [] message.tag = OrderChangeMessageCode -> EncodeOrderChangeMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = OrderAditionMessageCode -> DecodeOrderAditionMessage(bytes)
              [] tag = ExecutionOfOrdersMessageCode -> DecodeExecutionOfOrdersMessage(bytes)
              [] tag = OrderCancellationMessageCode -> DecodeOrderCancellationMessage(bytes)
              [] tag = OrderChangeMessageCode -> DecodeOrderChangeMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> OrderAditionMessageCode, body |-> ZeroOrderAditionMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> OrderAditionMessageCode, body |-> one] : one \in CheckedOrderAditionMessage }
        \cup { [tag |-> ExecutionOfOrdersMessageCode, body |-> one] : one \in CheckedExecutionOfOrdersMessage }
        \cup { [tag |-> OrderCancellationMessageCode, body |-> one] : one \in CheckedOrderCancellationMessage }
        \cup { [tag |-> OrderChangeMessageCode, body |-> one] : one \in CheckedOrderChangeMessage }

(***************************************************************************)
(* Message Block, framed by Message Length                                 *)
(***************************************************************************)

MessageBlock ==
    [ payload : Payload ]

EncodeMessageBlockBody(message) ==
    EncodeUIntBE(message.payload.tag, 2)
        \o EncodePayload(message.payload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessageBlock(message) ==
    LET body == EncodeMessageBlockBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeMessageBlockBody(bytes) ==
    LET messageType == ReadUIntBE(bytes, 2) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

DecodeMessageBlock(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeMessageBlockBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroMessageBlock ==
    [ payload |-> ZeroPayload ]

(* Message Block at zero, then each field in turn at the values it is checked at *)
CheckedMessageBlock ==
    { ZeroMessageBlock }
        \cup { [ZeroMessageBlock EXCEPT !.payload = one] : one \in CheckedPayload }

(* A run of Message Block, written one after another *)
RECURSIVE EncodeMessageBlockList(_)
EncodeMessageBlockList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMessageBlock(Head(messages)) \o EncodeMessageBlockList(Tail(messages))

(* As many Message Block as the field that counts them says *)
RECURSIVE ReadMessageBlockList(_, _)
ReadMessageBlockList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMessageBlock(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMessageBlockList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Message Block of each kind, for the lists that carry them *)
OneMessageBlock ==
    { [ZeroMessageBlock EXCEPT !.payload = [tag |-> OrderAditionMessageCode, body |-> ZeroOrderAditionMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> ExecutionOfOrdersMessageCode, body |-> ZeroExecutionOfOrdersMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> OrderCancellationMessageCode, body |-> ZeroOrderCancellationMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> OrderChangeMessageCode, body |-> ZeroOrderChangeMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ length          : Sample(2),
      marketDataGroup : Sample(1),
      session         : Sample(1),
      sequenceNumber  : Sample(4),
      datetime        : Sample(8),
      messageBlock    : SampleLists(OneMessageBlock) ]

EncodePacket(message) ==
    message.length
        \o EncodeUIntBE(Len(message.messageBlock), 1)
        \o message.marketDataGroup
        \o message.session
        \o message.sequenceNumber
        \o message.datetime
        \o EncodeMessageBlockList(message.messageBlock)

DecodePacket(bytes) ==
    LET length == ReadBytes(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET totalMessages == ReadUIntBE(length.rest, 1) IN IF ~totalMessages.ok THEN Fail ELSE
    LET marketDataGroup == ReadBytes(totalMessages.rest, 1) IN IF ~marketDataGroup.ok THEN Fail ELSE
    LET session == ReadBytes(marketDataGroup.rest, 1) IN IF ~session.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(session.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET datetime == ReadBytes(sequenceNumber.rest, 8) IN IF ~datetime.ok THEN Fail ELSE
    LET messageBlock == ReadMessageBlockList(datetime.rest, totalMessages.value) IN IF ~messageBlock.ok THEN Fail ELSE
    Ok([ length          |-> length.value,
         marketDataGroup |-> marketDataGroup.value,
         session         |-> session.value,
         sequenceNumber  |-> sequenceNumber.value,
         datetime        |-> datetime.value,
         messageBlock    |-> messageBlock.value ], messageBlock.rest)

ZeroPacket ==
    [ length          |-> [i \in 1 .. 2 |-> 0],
      marketDataGroup |-> [i \in 1 .. 1 |-> 0],
      session         |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber  |-> [i \in 1 .. 4 |-> 0],
      datetime        |-> [i \in 1 .. 8 |-> 0],
      messageBlock    |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.length = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.marketDataGroup = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.session = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.datetime = one] : one \in Sample(8) }
        \cup { [ZeroPacket EXCEPT !.messageBlock = one] : one \in SampleLists(OneMessageBlock) }

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

(* Every Order Adition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderAditionMessage ==
    \A message \in CheckedOrderAditionMessage :
        LET read == DecodeOrderAditionMessage(EncodeOrderAditionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Of Orders Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionOfOrdersMessage ==
    \A message \in CheckedExecutionOfOrdersMessage :
        LET read == DecodeExecutionOfOrdersMessage(EncodeExecutionOfOrdersMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancellation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancellationMessage ==
    \A message \in CheckedOrderCancellationMessage :
        LET read == DecodeOrderCancellationMessage(EncodeOrderCancellationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Change Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderChangeMessage ==
    \A message \in CheckedOrderChangeMessage :
        LET read == DecodeOrderChangeMessage(EncodeOrderChangeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message Block decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageBlock ==
    \A message \in CheckedMessageBlock :
        LET read == DecodeMessageBlock(EncodeMessageBlock(message))
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

(* Message Length is written from the bytes it frames *)
FramesMessageBlock ==
    \A message \in CheckedMessageBlock :
        LET bytes == EncodeMessageBlock(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
