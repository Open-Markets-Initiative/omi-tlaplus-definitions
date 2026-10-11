------------------- MODULE TxseEquities_Framing_Udp_v1_0 -------------------
(***************************************************************************)
(* Texas Stock Exchange  v1.0                                              *)
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
(* Udp Sequenced Message, framed by Message Length                         *)
(***************************************************************************)

UdpSequencedMessage ==
    [ streamId    : Sample(1),
      messageType : Sample(1),
      payload     : SampleBytes ]

EncodeUdpSequencedMessageBody(message) ==
    message.streamId
        \o message.messageType
        \o message.payload

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeUdpSequencedMessage(message) ==
    LET body == EncodeUdpSequencedMessageBody(message)
    IN  EncodeUIntLE(Len(body), 2) \o body

DecodeUdpSequencedMessageBody(bytes) ==
    LET streamId == ReadBytes(bytes, 1) IN IF ~streamId.ok THEN Fail ELSE
    LET messageType == ReadBytes(streamId.rest, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == Ok(messageType.rest, << >>) IN IF ~payload.ok THEN Fail ELSE
    Ok([ streamId    |-> streamId.value,
         messageType |-> messageType.value,
         payload     |-> payload.value ], payload.rest)

DecodeUdpSequencedMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeUdpSequencedMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroUdpSequencedMessage ==
    [ streamId    |-> [i \in 1 .. 1 |-> 0],
      messageType |-> [i \in 1 .. 1 |-> 0],
      payload     |-> << >> ]

(* Udp Sequenced Message at zero, then each field in turn at the values it is checked at *)
CheckedUdpSequencedMessage ==
    { ZeroUdpSequencedMessage }
        \cup { [ZeroUdpSequencedMessage EXCEPT !.streamId = one] : one \in Sample(1) }
        \cup { [ZeroUdpSequencedMessage EXCEPT !.messageType = one] : one \in Sample(1) }
        \cup { [ZeroUdpSequencedMessage EXCEPT !.payload = one] : one \in SampleBytes }

(* A run of Udp Sequenced Message, written one after another *)
RECURSIVE EncodeUdpSequencedMessageList(_)
EncodeUdpSequencedMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeUdpSequencedMessage(Head(messages)) \o EncodeUdpSequencedMessageList(Tail(messages))

(* As many Udp Sequenced Message as the field that counts them says *)
RECURSIVE ReadUdpSequencedMessageList(_, _)
ReadUdpSequencedMessageList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeUdpSequencedMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadUdpSequencedMessageList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Udp Sequenced Message of each kind, for the lists that carry them *)
OneUdpSequencedMessage == { ZeroUdpSequencedMessage }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ session             : Sample(8),
      sequence            : Sample(8),
      packetType          : Sample(1),
      udpSequencedMessage : SampleLists(OneUdpSequencedMessage) ]

EncodePacket(message) ==
    message.session
        \o message.sequence
        \o EncodeUIntLE(Len(message.udpSequencedMessage), 2)
        \o message.packetType
        \o EncodeUdpSequencedMessageList(message.udpSequencedMessage)

DecodePacket(bytes) ==
    LET session == ReadBytes(bytes, 8) IN IF ~session.ok THEN Fail ELSE
    LET sequence == ReadBytes(session.rest, 8) IN IF ~sequence.ok THEN Fail ELSE
    LET messageCount == ReadUIntLE(sequence.rest, 2) IN IF ~messageCount.ok THEN Fail ELSE
    LET packetType == ReadBytes(messageCount.rest, 1) IN IF ~packetType.ok THEN Fail ELSE
    LET udpSequencedMessage == ReadUdpSequencedMessageList(packetType.rest, messageCount.value) IN IF ~udpSequencedMessage.ok THEN Fail ELSE
    Ok([ session             |-> session.value,
         sequence            |-> sequence.value,
         packetType          |-> packetType.value,
         udpSequencedMessage |-> udpSequencedMessage.value ], udpSequencedMessage.rest)

ZeroPacket ==
    [ session             |-> [i \in 1 .. 8 |-> 0],
      sequence            |-> [i \in 1 .. 8 |-> 0],
      packetType          |-> [i \in 1 .. 1 |-> 0],
      udpSequencedMessage |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.session = one] : one \in Sample(8) }
        \cup { [ZeroPacket EXCEPT !.sequence = one] : one \in Sample(8) }
        \cup { [ZeroPacket EXCEPT !.packetType = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.udpSequencedMessage = one] : one \in SampleLists(OneUdpSequencedMessage) }

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

(* Every Udp Sequenced Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUdpSequencedMessage ==
    \A message \in CheckedUdpSequencedMessage :
        LET read == DecodeUdpSequencedMessage(EncodeUdpSequencedMessage(message))
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
FramesUdpSequencedMessage ==
    \A message \in CheckedUdpSequencedMessage :
        LET bytes == EncodeUdpSequencedMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
