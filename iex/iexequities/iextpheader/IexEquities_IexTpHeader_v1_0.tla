------------------- MODULE IexEquities_IexTpHeader_v1_0 --------------------
(***************************************************************************)
(* Investors Exchange IexTp Header v1.0                                    *)
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
(* Note: a Message Count of 0 marks Heartbeat and carries no Message.      *)
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
(* Message, framed by Message Length                                       *)
(***************************************************************************)

Message ==
    [ messageType : Sample(1),
      messageData : SampleBytes ]

EncodeMessageBody(message) ==
    message.messageType
        \o message.messageData

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntLE(Len(body), 2) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadBytes(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET messageData == Ok(messageType.rest, << >>) IN IF ~messageData.ok THEN Fail ELSE
    Ok([ messageType |-> messageType.value,
         messageData |-> messageData.value ], messageData.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroMessage ==
    [ messageType |-> [i \in 1 .. 1 |-> 0],
      messageData |-> << >> ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.messageType = one] : one \in Sample(1) }
        \cup { [ZeroMessage EXCEPT !.messageData = one] : one \in SampleBytes }

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
OneMessage == { ZeroMessage }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ version                    : Sample(1),
      reserved                   : Sample(1),
      messageProtocolId          : Sample(2),
      channelId                  : Sample(4),
      sessionId                  : Sample(4),
      streamOffset               : Sample(8),
      firstMessageSequenceNumber : Sample(8),
      sendTime                   : Sample(8),
      message                    : SampleLists(OneMessage) ]

EncodePacket(message) ==
    LET payload == EncodeMessageList(message.message)
    IN  message.version
            \o message.reserved
            \o message.messageProtocolId
            \o message.channelId
            \o message.sessionId
            \o EncodeUIntLE(Len(payload), 2)
            \o EncodeUIntLE(Len(message.message), 2)
            \o message.streamOffset
            \o message.firstMessageSequenceNumber
            \o message.sendTime
            \o payload

DecodePacket(bytes) ==
    LET version == ReadBytes(bytes, 1) IN IF ~version.ok THEN Fail ELSE
    LET reserved == ReadBytes(version.rest, 1) IN IF ~reserved.ok THEN Fail ELSE
    LET messageProtocolId == ReadBytes(reserved.rest, 2) IN IF ~messageProtocolId.ok THEN Fail ELSE
    LET channelId == ReadBytes(messageProtocolId.rest, 4) IN IF ~channelId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(channelId.rest, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET payloadLength == ReadUIntLE(sessionId.rest, 2) IN IF ~payloadLength.ok THEN Fail ELSE
    LET messageCount == ReadUIntLE(payloadLength.rest, 2) IN IF ~messageCount.ok THEN Fail ELSE
    LET streamOffset == ReadBytes(messageCount.rest, 8) IN IF ~streamOffset.ok THEN Fail ELSE
    LET firstMessageSequenceNumber == ReadBytes(streamOffset.rest, 8) IN IF ~firstMessageSequenceNumber.ok THEN Fail ELSE
    LET sendTime == ReadBytes(firstMessageSequenceNumber.rest, 8) IN IF ~sendTime.ok THEN Fail ELSE
    IF Len(sendTime.rest) < payloadLength.value THEN Fail ELSE
    LET framed == SubSeq(sendTime.rest, 1, payloadLength.value)
        beyond == SubSeq(sendTime.rest, payloadLength.value + 1, Len(sendTime.rest))
        message == ReadMessageList(framed, messageCount.value)
    IN  IF ~message.ok \/ message.rest # << >> THEN Fail ELSE
    Ok([ version                    |-> version.value,
         reserved                   |-> reserved.value,
         messageProtocolId          |-> messageProtocolId.value,
         channelId                  |-> channelId.value,
         sessionId                  |-> sessionId.value,
         streamOffset               |-> streamOffset.value,
         firstMessageSequenceNumber |-> firstMessageSequenceNumber.value,
         sendTime                   |-> sendTime.value,
         message                    |-> message.value ], beyond)

ZeroPacket ==
    [ version                    |-> [i \in 1 .. 1 |-> 0],
      reserved                   |-> [i \in 1 .. 1 |-> 0],
      messageProtocolId          |-> [i \in 1 .. 2 |-> 0],
      channelId                  |-> [i \in 1 .. 4 |-> 0],
      sessionId                  |-> [i \in 1 .. 4 |-> 0],
      streamOffset               |-> [i \in 1 .. 8 |-> 0],
      firstMessageSequenceNumber |-> [i \in 1 .. 8 |-> 0],
      sendTime                   |-> [i \in 1 .. 8 |-> 0],
      message                    |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.version = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.reserved = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.messageProtocolId = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.channelId = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.streamOffset = one] : one \in Sample(8) }
        \cup { [ZeroPacket EXCEPT !.firstMessageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroPacket EXCEPT !.sendTime = one] : one \in Sample(8) }
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

(* Message Length is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
