-------------------- MODULE A2XEquities_Snapshot_v1_3_2 --------------------
(***************************************************************************)
(* A2X Markets Snapshot Feed v1.3.2                                        *)
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
(* Note: Market Flags is a bit field set, checked as its 1 byte rather     *)
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
(* Snapshot Start Message: 14 bytes                                        *)
(***************************************************************************)

SnapshotStartMessage ==
    [ streamSeqNo   : Sample(4),
      securityCount : Sample(2),
      timestamp     : Sample(8) ]

EncodeSnapshotStartMessage(message) ==
    message.streamSeqNo
        \o message.securityCount
        \o message.timestamp

DecodeSnapshotStartMessage(bytes) ==
    LET streamSeqNo == ReadBytes(bytes, 4) IN IF ~streamSeqNo.ok THEN Fail ELSE
    LET securityCount == ReadBytes(streamSeqNo.rest, 2) IN IF ~securityCount.ok THEN Fail ELSE
    LET timestamp == ReadBytes(securityCount.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    Ok([ streamSeqNo   |-> streamSeqNo.value,
         securityCount |-> securityCount.value,
         timestamp     |-> timestamp.value ], timestamp.rest)

ZeroSnapshotStartMessage ==
    [ streamSeqNo   |-> [i \in 1 .. 4 |-> 0],
      securityCount |-> [i \in 1 .. 2 |-> 0],
      timestamp     |-> [i \in 1 .. 8 |-> 0] ]

(* Snapshot Start Message at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotStartMessage ==
    { ZeroSnapshotStartMessage }
        \cup { [ZeroSnapshotStartMessage EXCEPT !.streamSeqNo = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotStartMessage EXCEPT !.securityCount = one] : one \in Sample(2) }
        \cup { [ZeroSnapshotStartMessage EXCEPT !.timestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Book Status Message: 22 bytes                                           *)
(***************************************************************************)

BookStatusMessage ==
    [ securityId      : Sample(2),
      tradingStatus   : Sample(1),
      marketFlags     : Sample(1),
      entries         : Sample(2),
      closingBuyQty   : Sample(4),
      closingSellQty  : Sample(4),
      indicativePrice : Sample(8) ]

EncodeBookStatusMessage(message) ==
    message.securityId
        \o message.tradingStatus
        \o message.marketFlags
        \o message.entries
        \o message.closingBuyQty
        \o message.closingSellQty
        \o message.indicativePrice

DecodeBookStatusMessage(bytes) ==
    LET securityId == ReadBytes(bytes, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(securityId.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET marketFlags == ReadBytes(tradingStatus.rest, 1) IN IF ~marketFlags.ok THEN Fail ELSE
    LET entries == ReadBytes(marketFlags.rest, 2) IN IF ~entries.ok THEN Fail ELSE
    LET closingBuyQty == ReadBytes(entries.rest, 4) IN IF ~closingBuyQty.ok THEN Fail ELSE
    LET closingSellQty == ReadBytes(closingBuyQty.rest, 4) IN IF ~closingSellQty.ok THEN Fail ELSE
    LET indicativePrice == ReadBytes(closingSellQty.rest, 8) IN IF ~indicativePrice.ok THEN Fail ELSE
    Ok([ securityId      |-> securityId.value,
         tradingStatus   |-> tradingStatus.value,
         marketFlags     |-> marketFlags.value,
         entries         |-> entries.value,
         closingBuyQty   |-> closingBuyQty.value,
         closingSellQty  |-> closingSellQty.value,
         indicativePrice |-> indicativePrice.value ], indicativePrice.rest)

ZeroBookStatusMessage ==
    [ securityId      |-> [i \in 1 .. 2 |-> 0],
      tradingStatus   |-> [i \in 1 .. 1 |-> 0],
      marketFlags     |-> [i \in 1 .. 1 |-> 0],
      entries         |-> [i \in 1 .. 2 |-> 0],
      closingBuyQty   |-> [i \in 1 .. 4 |-> 0],
      closingSellQty  |-> [i \in 1 .. 4 |-> 0],
      indicativePrice |-> [i \in 1 .. 8 |-> 0] ]

(* Book Status Message at zero, then each field in turn at the values it is checked at *)
CheckedBookStatusMessage ==
    { ZeroBookStatusMessage }
        \cup { [ZeroBookStatusMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroBookStatusMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroBookStatusMessage EXCEPT !.marketFlags = one] : one \in Sample(1) }
        \cup { [ZeroBookStatusMessage EXCEPT !.entries = one] : one \in Sample(2) }
        \cup { [ZeroBookStatusMessage EXCEPT !.closingBuyQty = one] : one \in Sample(4) }
        \cup { [ZeroBookStatusMessage EXCEPT !.closingSellQty = one] : one \in Sample(4) }
        \cup { [ZeroBookStatusMessage EXCEPT !.indicativePrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Book Entry Message: 19 bytes                                            *)
(***************************************************************************)

BookEntryMessage ==
    [ securityId : Sample(2),
      side       : Sample(1),
      quantity   : Sample(4),
      price      : Sample(8),
      orderRef   : Sample(4) ]

EncodeBookEntryMessage(message) ==
    message.securityId
        \o message.side
        \o message.quantity
        \o message.price
        \o message.orderRef

DecodeBookEntryMessage(bytes) ==
    LET securityId == ReadBytes(bytes, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET side == ReadBytes(securityId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET quantity == ReadBytes(side.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderRef == ReadBytes(price.rest, 4) IN IF ~orderRef.ok THEN Fail ELSE
    Ok([ securityId |-> securityId.value,
         side       |-> side.value,
         quantity   |-> quantity.value,
         price      |-> price.value,
         orderRef   |-> orderRef.value ], orderRef.rest)

ZeroBookEntryMessage ==
    [ securityId |-> [i \in 1 .. 2 |-> 0],
      side       |-> [i \in 1 .. 1 |-> 0],
      quantity   |-> [i \in 1 .. 4 |-> 0],
      price      |-> [i \in 1 .. 8 |-> 0],
      orderRef   |-> [i \in 1 .. 4 |-> 0] ]

(* Book Entry Message at zero, then each field in turn at the values it is checked at *)
CheckedBookEntryMessage ==
    { ZeroBookEntryMessage }
        \cup { [ZeroBookEntryMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroBookEntryMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroBookEntryMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroBookEntryMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroBookEntryMessage EXCEPT !.orderRef = one] : one \in Sample(4) }

(***************************************************************************)
(* Mac Book Entry Message: 19 bytes                                        *)
(***************************************************************************)

MacBookEntryMessage ==
    [ securityId : Sample(2),
      side       : Sample(1),
      quantity   : Sample(4),
      price      : Sample(8),
      orderRef   : Sample(4) ]

EncodeMacBookEntryMessage(message) ==
    message.securityId
        \o message.side
        \o message.quantity
        \o message.price
        \o message.orderRef

DecodeMacBookEntryMessage(bytes) ==
    LET securityId == ReadBytes(bytes, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET side == ReadBytes(securityId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET quantity == ReadBytes(side.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderRef == ReadBytes(price.rest, 4) IN IF ~orderRef.ok THEN Fail ELSE
    Ok([ securityId |-> securityId.value,
         side       |-> side.value,
         quantity   |-> quantity.value,
         price      |-> price.value,
         orderRef   |-> orderRef.value ], orderRef.rest)

ZeroMacBookEntryMessage ==
    [ securityId |-> [i \in 1 .. 2 |-> 0],
      side       |-> [i \in 1 .. 1 |-> 0],
      quantity   |-> [i \in 1 .. 4 |-> 0],
      price      |-> [i \in 1 .. 8 |-> 0],
      orderRef   |-> [i \in 1 .. 4 |-> 0] ]

(* Mac Book Entry Message at zero, then each field in turn at the values it is checked at *)
CheckedMacBookEntryMessage ==
    { ZeroMacBookEntryMessage }
        \cup { [ZeroMacBookEntryMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroMacBookEntryMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroMacBookEntryMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroMacBookEntryMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroMacBookEntryMessage EXCEPT !.orderRef = one] : one \in Sample(4) }

(***************************************************************************)
(* Payload, selected by Msg Type                                           *)
(***************************************************************************)

HeartbeatMessageCode == 1  \* 0x01
SnapshotStartMessageCode == 10  \* 0x0a
BookStatusMessageCode == 11  \* 0x0b
BookEntryMessageCode == 12  \* 0x0c
MacBookEntryMessageCode == 18  \* 0x12

Payload ==
    [ tag : {HeartbeatMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {SnapshotStartMessageCode}, body : SnapshotStartMessage ]
        \cup [ tag : {BookStatusMessageCode}, body : BookStatusMessage ]
        \cup [ tag : {BookEntryMessageCode}, body : BookEntryMessage ]
        \cup [ tag : {MacBookEntryMessageCode}, body : MacBookEntryMessage ]

EncodePayload(message) ==
    CASE message.tag = HeartbeatMessageCode -> << >>
      [] message.tag = SnapshotStartMessageCode -> EncodeSnapshotStartMessage(message.body)
      [] message.tag = BookStatusMessageCode -> EncodeBookStatusMessage(message.body)
      [] message.tag = BookEntryMessageCode -> EncodeBookEntryMessage(message.body)
      [] message.tag = MacBookEntryMessageCode -> EncodeMacBookEntryMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = HeartbeatMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = SnapshotStartMessageCode -> DecodeSnapshotStartMessage(bytes)
              [] tag = BookStatusMessageCode -> DecodeBookStatusMessage(bytes)
              [] tag = BookEntryMessageCode -> DecodeBookEntryMessage(bytes)
              [] tag = MacBookEntryMessageCode -> DecodeMacBookEntryMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> SnapshotStartMessageCode, body |-> one] : one \in CheckedSnapshotStartMessage }
        \cup { [tag |-> BookStatusMessageCode, body |-> one] : one \in CheckedBookStatusMessage }
        \cup { [tag |-> BookEntryMessageCode, body |-> one] : one \in CheckedBookEntryMessage }
        \cup { [tag |-> MacBookEntryMessageCode, body |-> one] : one \in CheckedMacBookEntryMessage }

(***************************************************************************)
(* Message, framed by Msg Length                                           *)
(***************************************************************************)

Message ==
    [ seqNo   : Sample(4),
      payload : Payload ]

EncodeMessageBody(message) ==
    message.seqNo
        \o EncodePayload(message.payload)

(* Msg Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntBE(message.payload.tag, 1) \o EncodeUIntBE(Len(body) + 2, 1) \o body

DecodeMessage(bytes) ==
    LET msgType == ReadUIntBE(bytes, 1) IN IF ~msgType.ok THEN Fail ELSE
    LET length == ReadUIntBE(msgType.rest, 1) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
    IN
    LET seqNo == ReadBytes(framed, 4) IN IF ~seqNo.ok THEN Fail ELSE
    LET payload == DecodePayload(msgType.value, seqNo.rest) IN IF ~payload.ok THEN Fail ELSE
    IF payload.rest # << >> THEN Fail ELSE
    Ok([ seqNo   |-> seqNo.value,
         payload |-> payload.value ], beyond)

ZeroMessage ==
    [ seqNo   |-> [i \in 1 .. 4 |-> 0],
      payload |-> ZeroPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.seqNo = one] : one \in Sample(4) }
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SnapshotStartMessageCode, body |-> ZeroSnapshotStartMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> BookStatusMessageCode, body |-> ZeroBookStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> BookEntryMessageCode, body |-> ZeroBookEntryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MacBookEntryMessageCode, body |-> ZeroMacBookEntryMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ message : SampleLists(OneMessage) ]

EncodePacket(message) ==
    EncodeUIntBE(Len(message.message), 1)
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET messageCount == ReadUIntBE(bytes, 1) IN IF ~messageCount.ok THEN Fail ELSE
    LET message == ReadMessageList(messageCount.rest, messageCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ message |-> message.value ], message.rest)

ZeroPacket ==
    [ message |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
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

(* Every Snapshot Start Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotStartMessage ==
    \A message \in CheckedSnapshotStartMessage :
        LET read == DecodeSnapshotStartMessage(EncodeSnapshotStartMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Book Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBookStatusMessage ==
    \A message \in CheckedBookStatusMessage :
        LET read == DecodeBookStatusMessage(EncodeBookStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Book Entry Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBookEntryMessage ==
    \A message \in CheckedBookEntryMessage :
        LET read == DecodeBookEntryMessage(EncodeBookEntryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mac Book Entry Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMacBookEntryMessage ==
    \A message \in CheckedMacBookEntryMessage :
        LET read == DecodeMacBookEntryMessage(EncodeMacBookEntryMessage(message))
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

(* A Payload is selected by the Msg Type it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Msg Length is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 2, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
