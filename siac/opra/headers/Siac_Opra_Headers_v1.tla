----------------------- MODULE Siac_Opra_Headers_v1 ------------------------
(***************************************************************************)
(* The Securities Industry Automation Corporation Headers v1               *)
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
(* Note: Block Pad Byte pads to a 2 byte boundary: it is read as the bytes *)
(* left to the end of the frame, and the frame's length is trusted to keep *)
(* that boundary.                                                          *)
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
(* Block Timestamp: 8 bytes                                                *)
(***************************************************************************)

BlockTimestamp ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeBlockTimestamp(message) ==
    message.seconds
        \o message.nanoseconds

DecodeBlockTimestamp(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroBlockTimestamp ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Block Timestamp at zero, then each field in turn at the values it is checked at *)
CheckedBlockTimestamp ==
    { ZeroBlockTimestamp }
        \cup { [ZeroBlockTimestamp EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroBlockTimestamp EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Administrative Message                                                  *)
(***************************************************************************)

AdministrativeMessage ==
    [ messageType                : Sample(1),
      messageIndicator           : Sample(1),
      transactionId              : Sample(4),
      participantReferenceNumber : Sample(4),
      messageData                : SampleBytes ]

EncodeAdministrativeMessage(message) ==
    message.messageType
        \o message.messageIndicator
        \o message.transactionId
        \o message.participantReferenceNumber
        \o EncodeUIntBE(Len(message.messageData), 2)
        \o message.messageData

DecodeAdministrativeMessage(bytes) ==
    LET messageType == ReadBytes(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET messageIndicator == ReadBytes(messageType.rest, 1) IN IF ~messageIndicator.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageIndicator.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 4) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET messageDataLength == ReadUIntBE(participantReferenceNumber.rest, 2) IN IF ~messageDataLength.ok THEN Fail ELSE
    LET messageData == ReadBytes(messageDataLength.rest, messageDataLength.value) IN IF ~messageData.ok THEN Fail ELSE
    Ok([ messageType                |-> messageType.value,
         messageIndicator           |-> messageIndicator.value,
         transactionId              |-> transactionId.value,
         participantReferenceNumber |-> participantReferenceNumber.value,
         messageData                |-> messageData.value ], messageData.rest)

ZeroAdministrativeMessage ==
    [ messageType                |-> [i \in 1 .. 1 |-> 0],
      messageIndicator           |-> [i \in 1 .. 1 |-> 0],
      transactionId              |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 4 |-> 0],
      messageData                |-> << >> ]

(* Administrative Message at zero, then each field in turn at the values it is checked at *)
CheckedAdministrativeMessage ==
    { ZeroAdministrativeMessage }
        \cup { [ZeroAdministrativeMessage EXCEPT !.messageType = one] : one \in Sample(1) }
        \cup { [ZeroAdministrativeMessage EXCEPT !.messageIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAdministrativeMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroAdministrativeMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroAdministrativeMessage EXCEPT !.messageData = one] : one \in SampleBytes }

(***************************************************************************)
(* Control Message: 10 bytes                                               *)
(***************************************************************************)

ControlMessage ==
    [ controlMessageType         : Sample(1),
      messageIndicator           : Sample(1),
      transactionId              : Sample(4),
      participantReferenceNumber : Sample(4) ]

EncodeControlMessage(message) ==
    message.controlMessageType
        \o message.messageIndicator
        \o message.transactionId
        \o message.participantReferenceNumber

DecodeControlMessage(bytes) ==
    LET controlMessageType == ReadBytes(bytes, 1) IN IF ~controlMessageType.ok THEN Fail ELSE
    LET messageIndicator == ReadBytes(controlMessageType.rest, 1) IN IF ~messageIndicator.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageIndicator.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 4) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    Ok([ controlMessageType         |-> controlMessageType.value,
         messageIndicator           |-> messageIndicator.value,
         transactionId              |-> transactionId.value,
         participantReferenceNumber |-> participantReferenceNumber.value ], participantReferenceNumber.rest)

ZeroControlMessage ==
    [ controlMessageType         |-> [i \in 1 .. 1 |-> 0],
      messageIndicator           |-> [i \in 1 .. 1 |-> 0],
      transactionId              |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 4 |-> 0] ]

(* Control Message at zero, then each field in turn at the values it is checked at *)
CheckedControlMessage ==
    { ZeroControlMessage }
        \cup { [ZeroControlMessage EXCEPT !.controlMessageType = one] : one \in Sample(1) }
        \cup { [ZeroControlMessage EXCEPT !.messageIndicator = one] : one \in Sample(1) }
        \cup { [ZeroControlMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroControlMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(4) }

(***************************************************************************)
(* Payload, selected by Message Category                                   *)
(***************************************************************************)

AdministrativeMessageCode == 67  \* "C"
ControlMessageCode == 72  \* "H"

Payload ==
    [ tag : {AdministrativeMessageCode}, body : AdministrativeMessage ]
        \cup [ tag : {ControlMessageCode}, body : ControlMessage ]

EncodePayload(message) ==
    CASE message.tag = AdministrativeMessageCode -> EncodeAdministrativeMessage(message.body)
      [] message.tag = ControlMessageCode -> EncodeControlMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = AdministrativeMessageCode -> DecodeAdministrativeMessage(bytes)
              [] tag = ControlMessageCode -> DecodeControlMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> AdministrativeMessageCode, body |-> ZeroAdministrativeMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> AdministrativeMessageCode, body |-> one] : one \in CheckedAdministrativeMessage }
        \cup { [tag |-> ControlMessageCode, body |-> one] : one \in CheckedControlMessage }

(***************************************************************************)
(* Message                                                                 *)
(***************************************************************************)

Message ==
    [ participantId : Sample(1),
      payload       : Payload ]

EncodeMessage(message) ==
    message.participantId
        \o EncodeUIntBE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

DecodeMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET messageCategory == ReadUIntBE(participantId.rest, 1) IN IF ~messageCategory.ok THEN Fail ELSE
    LET payload == DecodePayload(messageCategory.value, messageCategory.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ participantId |-> participantId.value,
         payload       |-> payload.value ], payload.rest)

ZeroMessage ==
    [ participantId |-> [i \in 1 .. 1 |-> 0],
      payload       |-> ZeroPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.participantId = one] : one \in Sample(1) }
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> AdministrativeMessageCode, body |-> ZeroAdministrativeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ControlMessageCode, body |-> ZeroControlMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ version                 : Sample(1),
      blockSize               : Sample(2),
      dataFeedIndicator       : Sample(1),
      retransmissionIndicator : Sample(1),
      sessionIndicator        : Sample(1),
      blockSequenceNumber     : Sample(4),
      blockTimestamp          : BlockTimestamp,
      blockChecksum           : Sample(2),
      message                 : SampleLists(OneMessage),
      blockPadByte            : SampleBytes ]

EncodePacket(message) ==
    message.version
        \o message.blockSize
        \o message.dataFeedIndicator
        \o message.retransmissionIndicator
        \o message.sessionIndicator
        \o message.blockSequenceNumber
        \o EncodeUIntBE(Len(message.message), 1)
        \o EncodeBlockTimestamp(message.blockTimestamp)
        \o message.blockChecksum
        \o EncodeMessageList(message.message)
        \o message.blockPadByte

DecodePacket(bytes) ==
    LET version == ReadBytes(bytes, 1) IN IF ~version.ok THEN Fail ELSE
    LET blockSize == ReadBytes(version.rest, 2) IN IF ~blockSize.ok THEN Fail ELSE
    LET dataFeedIndicator == ReadBytes(blockSize.rest, 1) IN IF ~dataFeedIndicator.ok THEN Fail ELSE
    LET retransmissionIndicator == ReadBytes(dataFeedIndicator.rest, 1) IN IF ~retransmissionIndicator.ok THEN Fail ELSE
    LET sessionIndicator == ReadBytes(retransmissionIndicator.rest, 1) IN IF ~sessionIndicator.ok THEN Fail ELSE
    LET blockSequenceNumber == ReadBytes(sessionIndicator.rest, 4) IN IF ~blockSequenceNumber.ok THEN Fail ELSE
    LET messagesInBlock == ReadUIntBE(blockSequenceNumber.rest, 1) IN IF ~messagesInBlock.ok THEN Fail ELSE
    LET blockTimestamp == DecodeBlockTimestamp(messagesInBlock.rest) IN IF ~blockTimestamp.ok THEN Fail ELSE
    LET blockChecksum == ReadBytes(blockTimestamp.rest, 2) IN IF ~blockChecksum.ok THEN Fail ELSE
    LET message == ReadMessageList(blockChecksum.rest, messagesInBlock.value) IN IF ~message.ok THEN Fail ELSE
    LET blockPadByte == Ok(message.rest, << >>) IN IF ~blockPadByte.ok THEN Fail ELSE
    Ok([ version                 |-> version.value,
         blockSize               |-> blockSize.value,
         dataFeedIndicator       |-> dataFeedIndicator.value,
         retransmissionIndicator |-> retransmissionIndicator.value,
         sessionIndicator        |-> sessionIndicator.value,
         blockSequenceNumber     |-> blockSequenceNumber.value,
         blockTimestamp          |-> blockTimestamp.value,
         blockChecksum           |-> blockChecksum.value,
         message                 |-> message.value,
         blockPadByte            |-> blockPadByte.value ], blockPadByte.rest)

ZeroPacket ==
    [ version                 |-> [i \in 1 .. 1 |-> 0],
      blockSize               |-> [i \in 1 .. 2 |-> 0],
      dataFeedIndicator       |-> [i \in 1 .. 1 |-> 0],
      retransmissionIndicator |-> [i \in 1 .. 1 |-> 0],
      sessionIndicator        |-> [i \in 1 .. 1 |-> 0],
      blockSequenceNumber     |-> [i \in 1 .. 4 |-> 0],
      blockTimestamp          |-> ZeroBlockTimestamp,
      blockChecksum           |-> [i \in 1 .. 2 |-> 0],
      message                 |-> << >>,
      blockPadByte            |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.version = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.blockSize = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.dataFeedIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.retransmissionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.sessionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.blockSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.blockTimestamp = one] : one \in CheckedBlockTimestamp }
        \cup { [ZeroPacket EXCEPT !.blockChecksum = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.message = one] : one \in SampleLists(OneMessage) }
        \cup { [ZeroPacket EXCEPT !.blockPadByte = one] : one \in SampleBytes }

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

(* Every Block Timestamp decodes back to what was encoded, and leaves nothing over *)
RoundTripBlockTimestamp ==
    \A message \in CheckedBlockTimestamp :
        LET read == DecodeBlockTimestamp(EncodeBlockTimestamp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Administrative Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAdministrativeMessage ==
    \A message \in CheckedAdministrativeMessage :
        LET read == DecodeAdministrativeMessage(EncodeAdministrativeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Control Message decodes back to what was encoded, and leaves nothing over *)
RoundTripControlMessage ==
    \A message \in CheckedControlMessage :
        LET read == DecodeControlMessage(EncodeControlMessage(message))
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

(* A Payload is selected by the Message Category it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
