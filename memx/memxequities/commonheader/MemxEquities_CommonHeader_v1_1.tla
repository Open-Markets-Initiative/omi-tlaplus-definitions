------------------ MODULE MemxEquities_CommonHeader_v1_1 -------------------
(***************************************************************************)
(* The Members Exchange Common Header v1.1                                 *)
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
(* Note: Sbe Message is as wide as what is left of Message: it is read as  *)
(* the bytes left of what its record was given, which the records above it *)
(* keep those bytes back from.                                             *)
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
    [ sbeMessage : SampleBytes ]

EncodeMessageBody(message) ==
    message.sbeMessage

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeMessageBody(bytes) ==
    LET sbeMessage == Ok(bytes, << >>) IN IF ~sbeMessage.ok THEN Fail ELSE
    Ok([ sbeMessage |-> sbeMessage.value ], sbeMessage.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroMessage ==
    [ sbeMessage |-> << >> ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.sbeMessage = one] : one \in SampleBytes }

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
(* Sequenced Message                                                       *)
(***************************************************************************)

SequencedMessage ==
    [ message : SampleLists(OneMessage) ]

EncodeSequencedMessage(message) ==
    EncodeUIntBE(Len(message.message), 2)
        \o EncodeMessageList(message.message)

DecodeSequencedMessage(bytes) ==
    LET messageCount == ReadUIntBE(bytes, 2) IN IF ~messageCount.ok THEN Fail ELSE
    LET message == ReadMessageList(messageCount.rest, messageCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ message |-> message.value ], message.rest)

ZeroSequencedMessage ==
    [ message |-> << >> ]

(* Sequenced Message at zero, then each field in turn at the values it is checked at *)
CheckedSequencedMessage ==
    { ZeroSequencedMessage }
        \cup { [ZeroSequencedMessage EXCEPT !.message = one] : one \in SampleLists(OneMessage) }

(***************************************************************************)
(* Sequenced Messages, selected by Message Type                            *)
(***************************************************************************)

HeartbeatCode == 0  \* 0x00
SessionShutdownCode == 1  \* 0x01
SequencedMessageCode == 2  \* 0x02

SequencedMessages ==
    [ tag : {HeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {SessionShutdownCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {SequencedMessageCode}, body : SequencedMessage ]

EncodeSequencedMessages(message) ==
    CASE message.tag = HeartbeatCode -> << >>
      [] message.tag = SessionShutdownCode -> << >>
      [] message.tag = SequencedMessageCode -> EncodeSequencedMessage(message.body)

DecodeSequencedMessages(tag, bytes) ==
    LET read ==
            CASE tag = HeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = SessionShutdownCode -> Ok([empty |-> 0], bytes)
              [] tag = SequencedMessageCode -> DecodeSequencedMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSequencedMessages == [tag |-> HeartbeatCode, body |-> [empty |-> 0]]

(* Each Sequenced Messages in turn, at the values the message it names is checked at *)
CheckedSequencedMessages ==
    { [tag |-> HeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> SessionShutdownCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> SequencedMessageCode, body |-> one] : one \in CheckedSequencedMessage }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ headerLength      : Sample(1),
      sessionId         : Sample(8),
      sequenceNumber    : Sample(8),
      sequencedMessages : SequencedMessages ]

EncodePacket(message) ==
    EncodeUIntBE(message.sequencedMessages.tag, 1)
        \o message.headerLength
        \o message.sessionId
        \o message.sequenceNumber
        \o EncodeSequencedMessages(message.sequencedMessages)

DecodePacket(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET headerLength == ReadBytes(messageType.rest, 1) IN IF ~headerLength.ok THEN Fail ELSE
    LET sessionId == ReadBytes(headerLength.rest, 8) IN IF ~sessionId.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(sessionId.rest, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET sequencedMessages == DecodeSequencedMessages(messageType.value, sequenceNumber.rest) IN IF ~sequencedMessages.ok THEN Fail ELSE
    Ok([ headerLength      |-> headerLength.value,
         sessionId         |-> sessionId.value,
         sequenceNumber    |-> sequenceNumber.value,
         sequencedMessages |-> sequencedMessages.value ], sequencedMessages.rest)

ZeroPacket ==
    [ headerLength      |-> [i \in 1 .. 1 |-> 0],
      sessionId         |-> [i \in 1 .. 8 |-> 0],
      sequenceNumber    |-> [i \in 1 .. 8 |-> 0],
      sequencedMessages |-> ZeroSequencedMessages ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.headerLength = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.sessionId = one] : one \in Sample(8) }
        \cup { [ZeroPacket EXCEPT !.sequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroPacket EXCEPT !.sequencedMessages = one] : one \in CheckedSequencedMessages }

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

(* Every Sequenced Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSequencedMessage ==
    \A message \in CheckedSequencedMessage :
        LET read == DecodeSequencedMessage(EncodeSequencedMessage(message))
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

(* A Sequenced Messages is selected by the Message Type it is written under *)
SelectsSequencedMessages ==
    \A message \in CheckedSequencedMessages :
        LET sent == EncodeSequencedMessages(message)
            read == DecodeSequencedMessages(message.tag, sent)
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
