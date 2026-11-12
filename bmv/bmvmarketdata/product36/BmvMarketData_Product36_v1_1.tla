------------------- MODULE BmvMarketData_Product36_v1_1 --------------------
(***************************************************************************)
(* Bolsa Mexicana de Valores Bmv Market Data Product 36 v1.1               *)
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
(* Events System Message: 22 bytes                                         *)
(***************************************************************************)

EventsSystemMessage ==
    [ instrumentNumber : Sample(4),
      eventCode        : Sample(1),
      market           : Sample(1),
      sendingTime      : Sample(8),
      endingTime       : Sample(8) ]

EncodeEventsSystemMessage(message) ==
    message.instrumentNumber
        \o message.eventCode
        \o message.market
        \o message.sendingTime
        \o message.endingTime

DecodeEventsSystemMessage(bytes) ==
    LET instrumentNumber == ReadBytes(bytes, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET eventCode == ReadBytes(instrumentNumber.rest, 1) IN IF ~eventCode.ok THEN Fail ELSE
    LET market == ReadBytes(eventCode.rest, 1) IN IF ~market.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(market.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET endingTime == ReadBytes(sendingTime.rest, 8) IN IF ~endingTime.ok THEN Fail ELSE
    Ok([ instrumentNumber |-> instrumentNumber.value,
         eventCode        |-> eventCode.value,
         market           |-> market.value,
         sendingTime      |-> sendingTime.value,
         endingTime       |-> endingTime.value ], endingTime.rest)

ZeroEventsSystemMessage ==
    [ instrumentNumber |-> [i \in 1 .. 4 |-> 0],
      eventCode        |-> [i \in 1 .. 1 |-> 0],
      market           |-> [i \in 1 .. 1 |-> 0],
      sendingTime      |-> [i \in 1 .. 8 |-> 0],
      endingTime       |-> [i \in 1 .. 8 |-> 0] ]

(* Events System Message at zero, then each field in turn at the values it is checked at *)
CheckedEventsSystemMessage ==
    { ZeroEventsSystemMessage }
        \cup { [ZeroEventsSystemMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroEventsSystemMessage EXCEPT !.eventCode = one] : one \in Sample(1) }
        \cup { [ZeroEventsSystemMessage EXCEPT !.market = one] : one \in Sample(1) }
        \cup { [ZeroEventsSystemMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroEventsSystemMessage EXCEPT !.endingTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Indices Components Message: 57 bytes                                    *)
(***************************************************************************)

IndicesComponentsMessage ==
    [ date          : Sample(8),
      component     : Sample(2),
      sector        : Sample(1),
      type          : Sample(1),
      issuer        : Sample(7),
      series        : Sample(6),
      indicesStocks : Sample(8),
      lastPrice     : Sample(8),
      closingPrice  : Sample(8),
      influence     : Sample(8) ]

EncodeIndicesComponentsMessage(message) ==
    message.date
        \o message.component
        \o message.sector
        \o message.type
        \o message.issuer
        \o message.series
        \o message.indicesStocks
        \o message.lastPrice
        \o message.closingPrice
        \o message.influence

DecodeIndicesComponentsMessage(bytes) ==
    LET date == ReadBytes(bytes, 8) IN IF ~date.ok THEN Fail ELSE
    LET component == ReadBytes(date.rest, 2) IN IF ~component.ok THEN Fail ELSE
    LET sector == ReadBytes(component.rest, 1) IN IF ~sector.ok THEN Fail ELSE
    LET type == ReadBytes(sector.rest, 1) IN IF ~type.ok THEN Fail ELSE
    LET issuer == ReadBytes(type.rest, 7) IN IF ~issuer.ok THEN Fail ELSE
    LET series == ReadBytes(issuer.rest, 6) IN IF ~series.ok THEN Fail ELSE
    LET indicesStocks == ReadBytes(series.rest, 8) IN IF ~indicesStocks.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(indicesStocks.rest, 8) IN IF ~lastPrice.ok THEN Fail ELSE
    LET closingPrice == ReadBytes(lastPrice.rest, 8) IN IF ~closingPrice.ok THEN Fail ELSE
    LET influence == ReadBytes(closingPrice.rest, 8) IN IF ~influence.ok THEN Fail ELSE
    Ok([ date          |-> date.value,
         component     |-> component.value,
         sector        |-> sector.value,
         type          |-> type.value,
         issuer        |-> issuer.value,
         series        |-> series.value,
         indicesStocks |-> indicesStocks.value,
         lastPrice     |-> lastPrice.value,
         closingPrice  |-> closingPrice.value,
         influence     |-> influence.value ], influence.rest)

ZeroIndicesComponentsMessage ==
    [ date          |-> [i \in 1 .. 8 |-> 0],
      component     |-> [i \in 1 .. 2 |-> 0],
      sector        |-> [i \in 1 .. 1 |-> 0],
      type          |-> [i \in 1 .. 1 |-> 0],
      issuer        |-> [i \in 1 .. 7 |-> 0],
      series        |-> [i \in 1 .. 6 |-> 0],
      indicesStocks |-> [i \in 1 .. 8 |-> 0],
      lastPrice     |-> [i \in 1 .. 8 |-> 0],
      closingPrice  |-> [i \in 1 .. 8 |-> 0],
      influence     |-> [i \in 1 .. 8 |-> 0] ]

(* Indices Components Message at zero, then each field in turn at the values it is checked at *)
CheckedIndicesComponentsMessage ==
    { ZeroIndicesComponentsMessage }
        \cup { [ZeroIndicesComponentsMessage EXCEPT !.date = one] : one \in Sample(8) }
        \cup { [ZeroIndicesComponentsMessage EXCEPT !.component = one] : one \in Sample(2) }
        \cup { [ZeroIndicesComponentsMessage EXCEPT !.sector = one] : one \in Sample(1) }
        \cup { [ZeroIndicesComponentsMessage EXCEPT !.type = one] : one \in Sample(1) }
        \cup { [ZeroIndicesComponentsMessage EXCEPT !.issuer = one] : one \in Sample(7) }
        \cup { [ZeroIndicesComponentsMessage EXCEPT !.series = one] : one \in Sample(6) }
        \cup { [ZeroIndicesComponentsMessage EXCEPT !.indicesStocks = one] : one \in Sample(8) }
        \cup { [ZeroIndicesComponentsMessage EXCEPT !.lastPrice = one] : one \in Sample(8) }
        \cup { [ZeroIndicesComponentsMessage EXCEPT !.closingPrice = one] : one \in Sample(8) }
        \cup { [ZeroIndicesComponentsMessage EXCEPT !.influence = one] : one \in Sample(8) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

EventsSystemMessageCode == 83  \* 0x53
IndicesComponentsMessageCode == 87  \* 0x57

Payload ==
    [ tag : {EventsSystemMessageCode}, body : EventsSystemMessage ]
        \cup [ tag : {IndicesComponentsMessageCode}, body : IndicesComponentsMessage ]

EncodePayload(message) ==
    CASE message.tag = EventsSystemMessageCode -> EncodeEventsSystemMessage(message.body)
      [] message.tag = IndicesComponentsMessageCode -> EncodeIndicesComponentsMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = EventsSystemMessageCode -> DecodeEventsSystemMessage(bytes)
              [] tag = IndicesComponentsMessageCode -> DecodeIndicesComponentsMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> EventsSystemMessageCode, body |-> ZeroEventsSystemMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> EventsSystemMessageCode, body |-> one] : one \in CheckedEventsSystemMessage }
        \cup { [tag |-> IndicesComponentsMessageCode, body |-> one] : one \in CheckedIndicesComponentsMessage }

(***************************************************************************)
(* Message Block, framed by Message Length                                 *)
(***************************************************************************)

MessageBlock ==
    [ payload : Payload ]

EncodeMessageBlockBody(message) ==
    EncodeUIntBE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessageBlock(message) ==
    LET body == EncodeMessageBlockBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeMessageBlockBody(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
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
    { [ZeroMessageBlock EXCEPT !.payload = [tag |-> EventsSystemMessageCode, body |-> ZeroEventsSystemMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> IndicesComponentsMessageCode, body |-> ZeroIndicesComponentsMessage]] }

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

(* Every Events System Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEventsSystemMessage ==
    \A message \in CheckedEventsSystemMessage :
        LET read == DecodeEventsSystemMessage(EncodeEventsSystemMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Indices Components Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIndicesComponentsMessage ==
    \A message \in CheckedIndicesComponentsMessage :
        LET read == DecodeIndicesComponentsMessage(EncodeIndicesComponentsMessage(message))
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
