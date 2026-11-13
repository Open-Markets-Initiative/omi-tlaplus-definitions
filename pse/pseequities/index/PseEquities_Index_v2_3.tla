---------------------- MODULE PseEquities_Index_v2_3 -----------------------
(***************************************************************************)
(* Philippine Stock Exchange Pse Equities Itch Index v2.3                  *)
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
(* Note: a Message Count of 0 marks Heartbeat and carries no Message.      *)
(*                                                                         *)
(* Note: a Message Count of 0 marks End Of Session and carries no Message. *)
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
(* Time Stamp Seconds Message: 4 bytes                                     *)
(***************************************************************************)

TimeStampSecondsMessage ==
    [ second : Sample(4) ]

EncodeTimeStampSecondsMessage(message) ==
    message.second

DecodeTimeStampSecondsMessage(bytes) ==
    LET second == ReadBytes(bytes, 4) IN IF ~second.ok THEN Fail ELSE
    Ok([ second |-> second.value ], second.rest)

ZeroTimeStampSecondsMessage ==
    [ second |-> [i \in 1 .. 4 |-> 0] ]

(* Time Stamp Seconds Message at zero, then each field in turn at the values it is checked at *)
CheckedTimeStampSecondsMessage ==
    { ZeroTimeStampSecondsMessage }
        \cup { [ZeroTimeStampSecondsMessage EXCEPT !.second = one] : one \in Sample(4) }

(***************************************************************************)
(* System Event Message: 17 bytes                                          *)
(***************************************************************************)

SystemEventMessage ==
    [ timestamp : Sample(4),
      group     : Sample(8),
      eventCode : Sample(1),
      orderbook : Sample(4) ]

EncodeSystemEventMessage(message) ==
    message.timestamp
        \o message.group
        \o message.eventCode
        \o message.orderbook

DecodeSystemEventMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 4) IN IF ~timestamp.ok THEN Fail ELSE
    LET group == ReadBytes(timestamp.rest, 8) IN IF ~group.ok THEN Fail ELSE
    LET eventCode == ReadBytes(group.rest, 1) IN IF ~eventCode.ok THEN Fail ELSE
    LET orderbook == ReadBytes(eventCode.rest, 4) IN IF ~orderbook.ok THEN Fail ELSE
    Ok([ timestamp |-> timestamp.value,
         group     |-> group.value,
         eventCode |-> eventCode.value,
         orderbook |-> orderbook.value ], orderbook.rest)

ZeroSystemEventMessage ==
    [ timestamp |-> [i \in 1 .. 4 |-> 0],
      group     |-> [i \in 1 .. 8 |-> 0],
      eventCode |-> [i \in 1 .. 1 |-> 0],
      orderbook |-> [i \in 1 .. 4 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.timestamp = one] : one \in Sample(4) }
        \cup { [ZeroSystemEventMessage EXCEPT !.group = one] : one \in Sample(8) }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventCode = one] : one \in Sample(1) }
        \cup { [ZeroSystemEventMessage EXCEPT !.orderbook = one] : one \in Sample(4) }

(***************************************************************************)
(* Orderbook Directory Message: 89 bytes                                   *)
(***************************************************************************)

OrderbookDirectoryMessage ==
    [ timestamp               : Sample(4),
      orderbook               : Sample(4),
      priceType               : Sample(1),
      isin                    : Sample(12),
      secCode                 : Sample(12),
      currency                : Sample(3),
      group                   : Sample(8),
      lotSize                 : Sample(8),
      quantityTickSizeTableId : Sample(4),
      priceTickSizeTableId    : Sample(4),
      priceDecimals           : Sample(4),
      delistingDate           : Sample(4),
      delistingTime           : Sample(4),
      instrumentType          : Sample(1),
      shares                  : Sample(8),
      productCode             : Sample(8) ]

EncodeOrderbookDirectoryMessage(message) ==
    message.timestamp
        \o message.orderbook
        \o message.priceType
        \o message.isin
        \o message.secCode
        \o message.currency
        \o message.group
        \o message.lotSize
        \o message.quantityTickSizeTableId
        \o message.priceTickSizeTableId
        \o message.priceDecimals
        \o message.delistingDate
        \o message.delistingTime
        \o message.instrumentType
        \o message.shares
        \o message.productCode

DecodeOrderbookDirectoryMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 4) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderbook == ReadBytes(timestamp.rest, 4) IN IF ~orderbook.ok THEN Fail ELSE
    LET priceType == ReadBytes(orderbook.rest, 1) IN IF ~priceType.ok THEN Fail ELSE
    LET isin == ReadBytes(priceType.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET secCode == ReadBytes(isin.rest, 12) IN IF ~secCode.ok THEN Fail ELSE
    LET currency == ReadBytes(secCode.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET group == ReadBytes(currency.rest, 8) IN IF ~group.ok THEN Fail ELSE
    LET lotSize == ReadBytes(group.rest, 8) IN IF ~lotSize.ok THEN Fail ELSE
    LET quantityTickSizeTableId == ReadBytes(lotSize.rest, 4) IN IF ~quantityTickSizeTableId.ok THEN Fail ELSE
    LET priceTickSizeTableId == ReadBytes(quantityTickSizeTableId.rest, 4) IN IF ~priceTickSizeTableId.ok THEN Fail ELSE
    LET priceDecimals == ReadBytes(priceTickSizeTableId.rest, 4) IN IF ~priceDecimals.ok THEN Fail ELSE
    LET delistingDate == ReadBytes(priceDecimals.rest, 4) IN IF ~delistingDate.ok THEN Fail ELSE
    LET delistingTime == ReadBytes(delistingDate.rest, 4) IN IF ~delistingTime.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(delistingTime.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET shares == ReadBytes(instrumentType.rest, 8) IN IF ~shares.ok THEN Fail ELSE
    LET productCode == ReadBytes(shares.rest, 8) IN IF ~productCode.ok THEN Fail ELSE
    Ok([ timestamp               |-> timestamp.value,
         orderbook               |-> orderbook.value,
         priceType               |-> priceType.value,
         isin                    |-> isin.value,
         secCode                 |-> secCode.value,
         currency                |-> currency.value,
         group                   |-> group.value,
         lotSize                 |-> lotSize.value,
         quantityTickSizeTableId |-> quantityTickSizeTableId.value,
         priceTickSizeTableId    |-> priceTickSizeTableId.value,
         priceDecimals           |-> priceDecimals.value,
         delistingDate           |-> delistingDate.value,
         delistingTime           |-> delistingTime.value,
         instrumentType          |-> instrumentType.value,
         shares                  |-> shares.value,
         productCode             |-> productCode.value ], productCode.rest)

ZeroOrderbookDirectoryMessage ==
    [ timestamp               |-> [i \in 1 .. 4 |-> 0],
      orderbook               |-> [i \in 1 .. 4 |-> 0],
      priceType               |-> [i \in 1 .. 1 |-> 0],
      isin                    |-> [i \in 1 .. 12 |-> 0],
      secCode                 |-> [i \in 1 .. 12 |-> 0],
      currency                |-> [i \in 1 .. 3 |-> 0],
      group                   |-> [i \in 1 .. 8 |-> 0],
      lotSize                 |-> [i \in 1 .. 8 |-> 0],
      quantityTickSizeTableId |-> [i \in 1 .. 4 |-> 0],
      priceTickSizeTableId    |-> [i \in 1 .. 4 |-> 0],
      priceDecimals           |-> [i \in 1 .. 4 |-> 0],
      delistingDate           |-> [i \in 1 .. 4 |-> 0],
      delistingTime           |-> [i \in 1 .. 4 |-> 0],
      instrumentType          |-> [i \in 1 .. 1 |-> 0],
      shares                  |-> [i \in 1 .. 8 |-> 0],
      productCode             |-> [i \in 1 .. 8 |-> 0] ]

(* Orderbook Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderbookDirectoryMessage ==
    { ZeroOrderbookDirectoryMessage }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.timestamp = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.orderbook = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.priceType = one] : one \in Sample(1) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.secCode = one] : one \in Sample(12) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.group = one] : one \in Sample(8) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.lotSize = one] : one \in Sample(8) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.quantityTickSizeTableId = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.priceTickSizeTableId = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.priceDecimals = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.delistingDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.delistingTime = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.shares = one] : one \in Sample(8) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.productCode = one] : one \in Sample(8) }

(***************************************************************************)
(* Index Member Directory Message: 20 bytes                                *)
(***************************************************************************)

IndexMemberDirectoryMessage ==
    [ timestamp         : Sample(4),
      indexOrderbook    : Sample(4),
      memberOrderbook   : Sample(4),
      indexMemberWeight : Sample(8) ]

EncodeIndexMemberDirectoryMessage(message) ==
    message.timestamp
        \o message.indexOrderbook
        \o message.memberOrderbook
        \o message.indexMemberWeight

DecodeIndexMemberDirectoryMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 4) IN IF ~timestamp.ok THEN Fail ELSE
    LET indexOrderbook == ReadBytes(timestamp.rest, 4) IN IF ~indexOrderbook.ok THEN Fail ELSE
    LET memberOrderbook == ReadBytes(indexOrderbook.rest, 4) IN IF ~memberOrderbook.ok THEN Fail ELSE
    LET indexMemberWeight == ReadBytes(memberOrderbook.rest, 8) IN IF ~indexMemberWeight.ok THEN Fail ELSE
    Ok([ timestamp         |-> timestamp.value,
         indexOrderbook    |-> indexOrderbook.value,
         memberOrderbook   |-> memberOrderbook.value,
         indexMemberWeight |-> indexMemberWeight.value ], indexMemberWeight.rest)

ZeroIndexMemberDirectoryMessage ==
    [ timestamp         |-> [i \in 1 .. 4 |-> 0],
      indexOrderbook    |-> [i \in 1 .. 4 |-> 0],
      memberOrderbook   |-> [i \in 1 .. 4 |-> 0],
      indexMemberWeight |-> [i \in 1 .. 8 |-> 0] ]

(* Index Member Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedIndexMemberDirectoryMessage ==
    { ZeroIndexMemberDirectoryMessage }
        \cup { [ZeroIndexMemberDirectoryMessage EXCEPT !.timestamp = one] : one \in Sample(4) }
        \cup { [ZeroIndexMemberDirectoryMessage EXCEPT !.indexOrderbook = one] : one \in Sample(4) }
        \cup { [ZeroIndexMemberDirectoryMessage EXCEPT !.memberOrderbook = one] : one \in Sample(4) }
        \cup { [ZeroIndexMemberDirectoryMessage EXCEPT !.indexMemberWeight = one] : one \in Sample(8) }

(***************************************************************************)
(* Index Value Message: 16 bytes                                           *)
(***************************************************************************)

IndexValueMessage ==
    [ timestamp      : Sample(4),
      indexOrderbook : Sample(4),
      value          : Sample(8) ]

EncodeIndexValueMessage(message) ==
    message.timestamp
        \o message.indexOrderbook
        \o message.value

DecodeIndexValueMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 4) IN IF ~timestamp.ok THEN Fail ELSE
    LET indexOrderbook == ReadBytes(timestamp.rest, 4) IN IF ~indexOrderbook.ok THEN Fail ELSE
    LET value == ReadBytes(indexOrderbook.rest, 8) IN IF ~value.ok THEN Fail ELSE
    Ok([ timestamp      |-> timestamp.value,
         indexOrderbook |-> indexOrderbook.value,
         value          |-> value.value ], value.rest)

ZeroIndexValueMessage ==
    [ timestamp      |-> [i \in 1 .. 4 |-> 0],
      indexOrderbook |-> [i \in 1 .. 4 |-> 0],
      value          |-> [i \in 1 .. 8 |-> 0] ]

(* Index Value Message at zero, then each field in turn at the values it is checked at *)
CheckedIndexValueMessage ==
    { ZeroIndexValueMessage }
        \cup { [ZeroIndexValueMessage EXCEPT !.timestamp = one] : one \in Sample(4) }
        \cup { [ZeroIndexValueMessage EXCEPT !.indexOrderbook = one] : one \in Sample(4) }
        \cup { [ZeroIndexValueMessage EXCEPT !.value = one] : one \in Sample(8) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

TimeStampSecondsMessageCode == 84  \* "T"
SystemEventMessageCode == 83  \* "S"
OrderbookDirectoryMessageCode == 82  \* "R"
IndexMemberDirectoryMessageCode == 89  \* "Y"
IndexValueMessageCode == 90  \* "Z"

Payload ==
    [ tag : {TimeStampSecondsMessageCode}, body : TimeStampSecondsMessage ]
        \cup [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {OrderbookDirectoryMessageCode}, body : OrderbookDirectoryMessage ]
        \cup [ tag : {IndexMemberDirectoryMessageCode}, body : IndexMemberDirectoryMessage ]
        \cup [ tag : {IndexValueMessageCode}, body : IndexValueMessage ]

EncodePayload(message) ==
    CASE message.tag = TimeStampSecondsMessageCode -> EncodeTimeStampSecondsMessage(message.body)
      [] message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = OrderbookDirectoryMessageCode -> EncodeOrderbookDirectoryMessage(message.body)
      [] message.tag = IndexMemberDirectoryMessageCode -> EncodeIndexMemberDirectoryMessage(message.body)
      [] message.tag = IndexValueMessageCode -> EncodeIndexValueMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = TimeStampSecondsMessageCode -> DecodeTimeStampSecondsMessage(bytes)
              [] tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = OrderbookDirectoryMessageCode -> DecodeOrderbookDirectoryMessage(bytes)
              [] tag = IndexMemberDirectoryMessageCode -> DecodeIndexMemberDirectoryMessage(bytes)
              [] tag = IndexValueMessageCode -> DecodeIndexValueMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> TimeStampSecondsMessageCode, body |-> ZeroTimeStampSecondsMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> TimeStampSecondsMessageCode, body |-> one] : one \in CheckedTimeStampSecondsMessage }
        \cup { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> OrderbookDirectoryMessageCode, body |-> one] : one \in CheckedOrderbookDirectoryMessage }
        \cup { [tag |-> IndexMemberDirectoryMessageCode, body |-> one] : one \in CheckedIndexMemberDirectoryMessage }
        \cup { [tag |-> IndexValueMessageCode, body |-> one] : one \in CheckedIndexValueMessage }

(***************************************************************************)
(* Message, framed by Message Length                                       *)
(***************************************************************************)

Message ==
    [ payload : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntBE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> TimeStampSecondsMessageCode, body |-> ZeroTimeStampSecondsMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderbookDirectoryMessageCode, body |-> ZeroOrderbookDirectoryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> IndexMemberDirectoryMessageCode, body |-> ZeroIndexMemberDirectoryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> IndexValueMessageCode, body |-> ZeroIndexValueMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ session        : Sample(10),
      sequenceNumber : Sample(8),
      message        : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.session
        \o message.sequenceNumber
        \o EncodeUIntBE(Len(message.message), 2)
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET session == ReadBytes(bytes, 10) IN IF ~session.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(session.rest, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET messageCount == ReadUIntBE(sequenceNumber.rest, 2) IN IF ~messageCount.ok THEN Fail ELSE
    LET message == ReadMessageList(messageCount.rest, messageCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ session        |-> session.value,
         sequenceNumber |-> sequenceNumber.value,
         message        |-> message.value ], message.rest)

ZeroPacket ==
    [ session        |-> [i \in 1 .. 10 |-> 0],
      sequenceNumber |-> [i \in 1 .. 8 |-> 0],
      message        |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.session = one] : one \in Sample(10) }
        \cup { [ZeroPacket EXCEPT !.sequenceNumber = one] : one \in Sample(8) }
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

(* Every Time Stamp Seconds Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTimeStampSecondsMessage ==
    \A message \in CheckedTimeStampSecondsMessage :
        LET read == DecodeTimeStampSecondsMessage(EncodeTimeStampSecondsMessage(message))
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

(* Every Orderbook Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderbookDirectoryMessage ==
    \A message \in CheckedOrderbookDirectoryMessage :
        LET read == DecodeOrderbookDirectoryMessage(EncodeOrderbookDirectoryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Index Member Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIndexMemberDirectoryMessage ==
    \A message \in CheckedIndexMemberDirectoryMessage :
        LET read == DecodeIndexMemberDirectoryMessage(EncodeIndexMemberDirectoryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Index Value Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIndexValueMessage ==
    \A message \in CheckedIndexValueMessage :
        LET read == DecodeIndexValueMessage(EncodeIndexValueMessage(message))
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

(* Message Length is written from the bytes it frames *)
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
