------------------ MODULE IexOptions_Session_v1_01_Client ------------------
(***************************************************************************)
(* Investors Exchange Session v1.01                                        *)
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

(* The integer a rule depends on *)
ReadUIntLE(bytes, width) ==
    IF Len(bytes) < width
    THEN Fail
    ELSE Ok(DecodeUIntLE(SubSeq(bytes, 1, width)), SubSeq(bytes, width + 1, Len(bytes)))

(***************************************************************************)
(* The values a field is checked at: zero, the spaces a text field is      *)
(* padded with, and                                                        *)
(* every bit set, which is where an encoding goes wrong if it goes wrong   *)
(***************************************************************************)

Sample(width) ==
    { [i \in 1 .. width |-> 0],
      [i \in 1 .. width |-> 32],
      [i \in 1 .. width |-> 255] }

(* The lists a record is checked over: none, one, and a run of two. What a run has *)
(* to get right is reading one entry after another, which two of a kind already say. *)
SampleLists(entries) ==
    { << >> }
        \cup { <<one>> : one \in entries }
        \cup { <<one, one>> : one \in entries }

(***************************************************************************)
(* Login Request Message: 48 bytes                                         *)
(***************************************************************************)

LoginRequestMessage ==
    [ logonId : Sample(16),
      token   : Sample(32) ]

EncodeLoginRequestMessage(message) ==
    message.logonId
        \o message.token

DecodeLoginRequestMessage(bytes) ==
    LET logonId == ReadBytes(bytes, 16) IN IF ~logonId.ok THEN Fail ELSE
    LET token == ReadBytes(logonId.rest, 32) IN IF ~token.ok THEN Fail ELSE
    Ok([ logonId |-> logonId.value,
         token   |-> token.value ], token.rest)

ZeroLoginRequestMessage ==
    [ logonId |-> [i \in 1 .. 16 |-> 0],
      token   |-> [i \in 1 .. 32 |-> 0] ]

(* Login Request Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginRequestMessage ==
    { ZeroLoginRequestMessage }
        \cup { [ZeroLoginRequestMessage EXCEPT !.logonId = one] : one \in Sample(16) }
        \cup { [ZeroLoginRequestMessage EXCEPT !.token = one] : one \in Sample(32) }

(***************************************************************************)
(* Login Response Message: 17 bytes                                        *)
(***************************************************************************)

LoginResponseMessage ==
    [ logonId : Sample(16),
      status  : Sample(1) ]

EncodeLoginResponseMessage(message) ==
    message.logonId
        \o message.status

DecodeLoginResponseMessage(bytes) ==
    LET logonId == ReadBytes(bytes, 16) IN IF ~logonId.ok THEN Fail ELSE
    LET status == ReadBytes(logonId.rest, 1) IN IF ~status.ok THEN Fail ELSE
    Ok([ logonId |-> logonId.value,
         status  |-> status.value ], status.rest)

ZeroLoginResponseMessage ==
    [ logonId |-> [i \in 1 .. 16 |-> 0],
      status  |-> [i \in 1 .. 1 |-> 0] ]

(* Login Response Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginResponseMessage ==
    { ZeroLoginResponseMessage }
        \cup { [ZeroLoginResponseMessage EXCEPT !.logonId = one] : one \in Sample(16) }
        \cup { [ZeroLoginResponseMessage EXCEPT !.status = one] : one \in Sample(1) }

(***************************************************************************)
(* Sub Sessions Group: 14 bytes                                            *)
(***************************************************************************)

SubSessionsGroup ==
    [ subsessionType : Sample(1),
      subsessionId   : Sample(8),
      joined         : Sample(1),
      nextSeqNo      : Sample(4) ]

EncodeSubSessionsGroup(message) ==
    message.subsessionType
        \o message.subsessionId
        \o message.joined
        \o message.nextSeqNo

DecodeSubSessionsGroup(bytes) ==
    LET subsessionType == ReadBytes(bytes, 1) IN IF ~subsessionType.ok THEN Fail ELSE
    LET subsessionId == ReadBytes(subsessionType.rest, 8) IN IF ~subsessionId.ok THEN Fail ELSE
    LET joined == ReadBytes(subsessionId.rest, 1) IN IF ~joined.ok THEN Fail ELSE
    LET nextSeqNo == ReadBytes(joined.rest, 4) IN IF ~nextSeqNo.ok THEN Fail ELSE
    Ok([ subsessionType |-> subsessionType.value,
         subsessionId   |-> subsessionId.value,
         joined         |-> joined.value,
         nextSeqNo      |-> nextSeqNo.value ], nextSeqNo.rest)

ZeroSubSessionsGroup ==
    [ subsessionType |-> [i \in 1 .. 1 |-> 0],
      subsessionId   |-> [i \in 1 .. 8 |-> 0],
      joined         |-> [i \in 1 .. 1 |-> 0],
      nextSeqNo      |-> [i \in 1 .. 4 |-> 0] ]

(* Sub Sessions Group at zero, then each field in turn at the values it is checked at *)
CheckedSubSessionsGroup ==
    { ZeroSubSessionsGroup }
        \cup { [ZeroSubSessionsGroup EXCEPT !.subsessionType = one] : one \in Sample(1) }
        \cup { [ZeroSubSessionsGroup EXCEPT !.subsessionId = one] : one \in Sample(8) }
        \cup { [ZeroSubSessionsGroup EXCEPT !.joined = one] : one \in Sample(1) }
        \cup { [ZeroSubSessionsGroup EXCEPT !.nextSeqNo = one] : one \in Sample(4) }

(* A run of Sub Sessions Group, written one after another *)
RECURSIVE EncodeSubSessionsGroupList(_)
EncodeSubSessionsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSubSessionsGroup(Head(messages)) \o EncodeSubSessionsGroupList(Tail(messages))

(* As many Sub Sessions Group as the field that counts them says *)
RECURSIVE ReadSubSessionsGroupList(_, _)
ReadSubSessionsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSubSessionsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSubSessionsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Sub Sessions Group of each kind, for the lists that carry them *)
OneSubSessionsGroup == { ZeroSubSessionsGroup }

(***************************************************************************)
(* Sub Sessions Groups                                                     *)
(***************************************************************************)

SubSessionsGroups ==
    [ blockLengthShort : Sample(1),
      subSessionsGroup : SampleLists(OneSubSessionsGroup) ]

EncodeSubSessionsGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntLE(Len(message.subSessionsGroup), 1)
        \o EncodeSubSessionsGroupList(message.subSessionsGroup)

DecodeSubSessionsGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntLE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET subSessionsGroup == ReadSubSessionsGroupList(numInGroup.rest, numInGroup.value) IN IF ~subSessionsGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort |-> blockLengthShort.value,
         subSessionsGroup |-> subSessionsGroup.value ], subSessionsGroup.rest)

ZeroSubSessionsGroups ==
    [ blockLengthShort |-> [i \in 1 .. 1 |-> 0],
      subSessionsGroup |-> << >> ]

(* Sub Sessions Groups at zero, then each field in turn at the values it is checked at *)
CheckedSubSessionsGroups ==
    { ZeroSubSessionsGroups }
        \cup { [ZeroSubSessionsGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroSubSessionsGroups EXCEPT !.subSessionsGroup = one] : one \in SampleLists(OneSubSessionsGroup) }

(***************************************************************************)
(* Gateway Heartbeat Message                                               *)
(***************************************************************************)

GatewayHeartbeatMessage ==
    [ keepAlive         : Sample(1),
      subSessionsGroups : SubSessionsGroups ]

EncodeGatewayHeartbeatMessage(message) ==
    message.keepAlive
        \o EncodeSubSessionsGroups(message.subSessionsGroups)

DecodeGatewayHeartbeatMessage(bytes) ==
    LET keepAlive == ReadBytes(bytes, 1) IN IF ~keepAlive.ok THEN Fail ELSE
    LET subSessionsGroups == DecodeSubSessionsGroups(keepAlive.rest) IN IF ~subSessionsGroups.ok THEN Fail ELSE
    Ok([ keepAlive         |-> keepAlive.value,
         subSessionsGroups |-> subSessionsGroups.value ], subSessionsGroups.rest)

ZeroGatewayHeartbeatMessage ==
    [ keepAlive         |-> [i \in 1 .. 1 |-> 0],
      subSessionsGroups |-> ZeroSubSessionsGroups ]

(* Gateway Heartbeat Message at zero, then each field in turn at the values it is checked at *)
CheckedGatewayHeartbeatMessage ==
    { ZeroGatewayHeartbeatMessage }
        \cup { [ZeroGatewayHeartbeatMessage EXCEPT !.keepAlive = one] : one \in Sample(1) }
        \cup { [ZeroGatewayHeartbeatMessage EXCEPT !.subSessionsGroups = one] : one \in CheckedSubSessionsGroups }

(***************************************************************************)
(* Terminate Message: 1 bytes                                              *)
(***************************************************************************)

TerminateMessage ==
    [ reason : Sample(1) ]

EncodeTerminateMessage(message) ==
    message.reason

DecodeTerminateMessage(bytes) ==
    LET reason == ReadBytes(bytes, 1) IN IF ~reason.ok THEN Fail ELSE
    Ok([ reason |-> reason.value ], reason.rest)

ZeroTerminateMessage ==
    [ reason |-> [i \in 1 .. 1 |-> 0] ]

(* Terminate Message at zero, then each field in turn at the values it is checked at *)
CheckedTerminateMessage ==
    { ZeroTerminateMessage }
        \cup { [ZeroTerminateMessage EXCEPT !.reason = one] : one \in Sample(1) }

(***************************************************************************)
(* Sequenced Message Header Message: 20 bytes                              *)
(***************************************************************************)

SequencedMessageHeaderMessage ==
    [ subsessionId : Sample(8),
      sequence     : Sample(4),
      timestamp    : Sample(8) ]

EncodeSequencedMessageHeaderMessage(message) ==
    message.subsessionId
        \o message.sequence
        \o message.timestamp

DecodeSequencedMessageHeaderMessage(bytes) ==
    LET subsessionId == ReadBytes(bytes, 8) IN IF ~subsessionId.ok THEN Fail ELSE
    LET sequence == ReadBytes(subsessionId.rest, 4) IN IF ~sequence.ok THEN Fail ELSE
    LET timestamp == ReadBytes(sequence.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    Ok([ subsessionId |-> subsessionId.value,
         sequence     |-> sequence.value,
         timestamp    |-> timestamp.value ], timestamp.rest)

ZeroSequencedMessageHeaderMessage ==
    [ subsessionId |-> [i \in 1 .. 8 |-> 0],
      sequence     |-> [i \in 1 .. 4 |-> 0],
      timestamp    |-> [i \in 1 .. 8 |-> 0] ]

(* Sequenced Message Header Message at zero, then each field in turn at the values it is checked at *)
CheckedSequencedMessageHeaderMessage ==
    { ZeroSequencedMessageHeaderMessage }
        \cup { [ZeroSequencedMessageHeaderMessage EXCEPT !.subsessionId = one] : one \in Sample(8) }
        \cup { [ZeroSequencedMessageHeaderMessage EXCEPT !.sequence = one] : one \in Sample(4) }
        \cup { [ZeroSequencedMessageHeaderMessage EXCEPT !.timestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Subsession Join Message: 16 bytes                                       *)
(***************************************************************************)

SubsessionJoinMessage ==
    [ subsessionId  : Sample(8),
      startSequence : Sample(4),
      endSequence   : Sample(4) ]

EncodeSubsessionJoinMessage(message) ==
    message.subsessionId
        \o message.startSequence
        \o message.endSequence

DecodeSubsessionJoinMessage(bytes) ==
    LET subsessionId == ReadBytes(bytes, 8) IN IF ~subsessionId.ok THEN Fail ELSE
    LET startSequence == ReadBytes(subsessionId.rest, 4) IN IF ~startSequence.ok THEN Fail ELSE
    LET endSequence == ReadBytes(startSequence.rest, 4) IN IF ~endSequence.ok THEN Fail ELSE
    Ok([ subsessionId  |-> subsessionId.value,
         startSequence |-> startSequence.value,
         endSequence   |-> endSequence.value ], endSequence.rest)

ZeroSubsessionJoinMessage ==
    [ subsessionId  |-> [i \in 1 .. 8 |-> 0],
      startSequence |-> [i \in 1 .. 4 |-> 0],
      endSequence   |-> [i \in 1 .. 4 |-> 0] ]

(* Subsession Join Message at zero, then each field in turn at the values it is checked at *)
CheckedSubsessionJoinMessage ==
    { ZeroSubsessionJoinMessage }
        \cup { [ZeroSubsessionJoinMessage EXCEPT !.subsessionId = one] : one \in Sample(8) }
        \cup { [ZeroSubsessionJoinMessage EXCEPT !.startSequence = one] : one \in Sample(4) }
        \cup { [ZeroSubsessionJoinMessage EXCEPT !.endSequence = one] : one \in Sample(4) }

(***************************************************************************)
(* Subsession Join Response Message: 9 bytes                               *)
(***************************************************************************)

SubsessionJoinResponseMessage ==
    [ subsessionId : Sample(8),
      status       : Sample(1) ]

EncodeSubsessionJoinResponseMessage(message) ==
    message.subsessionId
        \o message.status

DecodeSubsessionJoinResponseMessage(bytes) ==
    LET subsessionId == ReadBytes(bytes, 8) IN IF ~subsessionId.ok THEN Fail ELSE
    LET status == ReadBytes(subsessionId.rest, 1) IN IF ~status.ok THEN Fail ELSE
    Ok([ subsessionId |-> subsessionId.value,
         status       |-> status.value ], status.rest)

ZeroSubsessionJoinResponseMessage ==
    [ subsessionId |-> [i \in 1 .. 8 |-> 0],
      status       |-> [i \in 1 .. 1 |-> 0] ]

(* Subsession Join Response Message at zero, then each field in turn at the values it is checked at *)
CheckedSubsessionJoinResponseMessage ==
    { ZeroSubsessionJoinResponseMessage }
        \cup { [ZeroSubsessionJoinResponseMessage EXCEPT !.subsessionId = one] : one \in Sample(8) }
        \cup { [ZeroSubsessionJoinResponseMessage EXCEPT !.status = one] : one \in Sample(1) }

(***************************************************************************)
(* Subsession Leave Message: 8 bytes                                       *)
(***************************************************************************)

SubsessionLeaveMessage ==
    [ subsessionId : Sample(8) ]

EncodeSubsessionLeaveMessage(message) ==
    message.subsessionId

DecodeSubsessionLeaveMessage(bytes) ==
    LET subsessionId == ReadBytes(bytes, 8) IN IF ~subsessionId.ok THEN Fail ELSE
    Ok([ subsessionId |-> subsessionId.value ], subsessionId.rest)

ZeroSubsessionLeaveMessage ==
    [ subsessionId |-> [i \in 1 .. 8 |-> 0] ]

(* Subsession Leave Message at zero, then each field in turn at the values it is checked at *)
CheckedSubsessionLeaveMessage ==
    { ZeroSubsessionLeaveMessage }
        \cup { [ZeroSubsessionLeaveMessage EXCEPT !.subsessionId = one] : one \in Sample(8) }

(***************************************************************************)
(* Subsession Leave Response Message: 9 bytes                              *)
(***************************************************************************)

SubsessionLeaveResponseMessage ==
    [ subsessionId : Sample(8),
      reason       : Sample(1) ]

EncodeSubsessionLeaveResponseMessage(message) ==
    message.subsessionId
        \o message.reason

DecodeSubsessionLeaveResponseMessage(bytes) ==
    LET subsessionId == ReadBytes(bytes, 8) IN IF ~subsessionId.ok THEN Fail ELSE
    LET reason == ReadBytes(subsessionId.rest, 1) IN IF ~reason.ok THEN Fail ELSE
    Ok([ subsessionId |-> subsessionId.value,
         reason       |-> reason.value ], reason.rest)

ZeroSubsessionLeaveResponseMessage ==
    [ subsessionId |-> [i \in 1 .. 8 |-> 0],
      reason       |-> [i \in 1 .. 1 |-> 0] ]

(* Subsession Leave Response Message at zero, then each field in turn at the values it is checked at *)
CheckedSubsessionLeaveResponseMessage ==
    { ZeroSubsessionLeaveResponseMessage }
        \cup { [ZeroSubsessionLeaveResponseMessage EXCEPT !.subsessionId = one] : one \in Sample(8) }
        \cup { [ZeroSubsessionLeaveResponseMessage EXCEPT !.reason = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by Template Id                                        *)
(***************************************************************************)

LoginRequestMessageCode == 1  \* 0x01
LoginResponseMessageCode == 2  \* 0x02
GatewayHeartbeatMessageCode == 3  \* 0x03
ClientHeartbeatMessageCode == 4  \* 0x04
LogoutRequestMessageCode == 5  \* 0x05
TerminateMessageCode == 6  \* 0x06
SequencedMessageHeaderMessageCode == 7  \* 0x07
SubsessionJoinMessageCode == 8  \* 0x08
SubsessionJoinResponseMessageCode == 9  \* 0x09
SubsessionLeaveMessageCode == 10  \* 0x0a
SubsessionLeaveResponseMessageCode == 11  \* 0x0b

Payload ==
    [ tag : {LoginRequestMessageCode}, body : LoginRequestMessage ]
        \cup [ tag : {LoginResponseMessageCode}, body : LoginResponseMessage ]
        \cup [ tag : {GatewayHeartbeatMessageCode}, body : GatewayHeartbeatMessage ]
        \cup [ tag : {ClientHeartbeatMessageCode}, body : {0} ]
        \cup [ tag : {LogoutRequestMessageCode}, body : {0} ]
        \cup [ tag : {TerminateMessageCode}, body : TerminateMessage ]
        \cup [ tag : {SequencedMessageHeaderMessageCode}, body : SequencedMessageHeaderMessage ]
        \cup [ tag : {SubsessionJoinMessageCode}, body : SubsessionJoinMessage ]
        \cup [ tag : {SubsessionJoinResponseMessageCode}, body : SubsessionJoinResponseMessage ]
        \cup [ tag : {SubsessionLeaveMessageCode}, body : SubsessionLeaveMessage ]
        \cup [ tag : {SubsessionLeaveResponseMessageCode}, body : SubsessionLeaveResponseMessage ]

EncodePayload(message) ==
    CASE message.tag = LoginRequestMessageCode -> EncodeLoginRequestMessage(message.body)
      [] message.tag = LoginResponseMessageCode -> EncodeLoginResponseMessage(message.body)
      [] message.tag = GatewayHeartbeatMessageCode -> EncodeGatewayHeartbeatMessage(message.body)
      [] message.tag = ClientHeartbeatMessageCode -> << >>
      [] message.tag = LogoutRequestMessageCode -> << >>
      [] message.tag = TerminateMessageCode -> EncodeTerminateMessage(message.body)
      [] message.tag = SequencedMessageHeaderMessageCode -> EncodeSequencedMessageHeaderMessage(message.body)
      [] message.tag = SubsessionJoinMessageCode -> EncodeSubsessionJoinMessage(message.body)
      [] message.tag = SubsessionJoinResponseMessageCode -> EncodeSubsessionJoinResponseMessage(message.body)
      [] message.tag = SubsessionLeaveMessageCode -> EncodeSubsessionLeaveMessage(message.body)
      [] message.tag = SubsessionLeaveResponseMessageCode -> EncodeSubsessionLeaveResponseMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = LoginRequestMessageCode -> DecodeLoginRequestMessage(bytes)
              [] tag = LoginResponseMessageCode -> DecodeLoginResponseMessage(bytes)
              [] tag = GatewayHeartbeatMessageCode -> DecodeGatewayHeartbeatMessage(bytes)
              [] tag = ClientHeartbeatMessageCode -> Ok(0, bytes)
              [] tag = LogoutRequestMessageCode -> Ok(0, bytes)
              [] tag = TerminateMessageCode -> DecodeTerminateMessage(bytes)
              [] tag = SequencedMessageHeaderMessageCode -> DecodeSequencedMessageHeaderMessage(bytes)
              [] tag = SubsessionJoinMessageCode -> DecodeSubsessionJoinMessage(bytes)
              [] tag = SubsessionJoinResponseMessageCode -> DecodeSubsessionJoinResponseMessage(bytes)
              [] tag = SubsessionLeaveMessageCode -> DecodeSubsessionLeaveMessage(bytes)
              [] tag = SubsessionLeaveResponseMessageCode -> DecodeSubsessionLeaveResponseMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> LoginRequestMessageCode, body |-> ZeroLoginRequestMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> LoginRequestMessageCode, body |-> one] : one \in CheckedLoginRequestMessage }
        \cup { [tag |-> LoginResponseMessageCode, body |-> one] : one \in CheckedLoginResponseMessage }
        \cup { [tag |-> GatewayHeartbeatMessageCode, body |-> one] : one \in CheckedGatewayHeartbeatMessage }
        \cup { [tag |-> ClientHeartbeatMessageCode, body |-> 0] }
        \cup { [tag |-> LogoutRequestMessageCode, body |-> 0] }
        \cup { [tag |-> TerminateMessageCode, body |-> one] : one \in CheckedTerminateMessage }
        \cup { [tag |-> SequencedMessageHeaderMessageCode, body |-> one] : one \in CheckedSequencedMessageHeaderMessage }
        \cup { [tag |-> SubsessionJoinMessageCode, body |-> one] : one \in CheckedSubsessionJoinMessage }
        \cup { [tag |-> SubsessionJoinResponseMessageCode, body |-> one] : one \in CheckedSubsessionJoinResponseMessage }
        \cup { [tag |-> SubsessionLeaveMessageCode, body |-> one] : one \in CheckedSubsessionLeaveMessage }
        \cup { [tag |-> SubsessionLeaveResponseMessageCode, body |-> one] : one \in CheckedSubsessionLeaveResponseMessage }

(***************************************************************************)
(* Sbe Message, framed by Packet Length                                    *)
(***************************************************************************)

SbeMessage ==
    [ blockLength : Sample(2),
      schemaId    : Sample(2),
      version     : Sample(2),
      payload     : Payload ]

EncodeSbeMessageBody(message) ==
    message.blockLength
        \o EncodeUIntLE(message.payload.tag, 2)
        \o message.schemaId
        \o message.version
        \o EncodePayload(message.payload)

(* Packet Length counts the bytes it frames, so it is written from them *)
EncodeSbeMessage(message) ==
    LET body == EncodeSbeMessageBody(message)
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeSbeMessageBody(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET templateId == ReadUIntLE(blockLength.rest, 2) IN IF ~templateId.ok THEN Fail ELSE
    LET schemaId == ReadBytes(templateId.rest, 2) IN IF ~schemaId.ok THEN Fail ELSE
    LET version == ReadBytes(schemaId.rest, 2) IN IF ~version.ok THEN Fail ELSE
    LET payload == DecodePayload(templateId.value, version.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ blockLength |-> blockLength.value,
         schemaId    |-> schemaId.value,
         version     |-> version.value,
         payload     |-> payload.value ], payload.rest)

DecodeSbeMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeSbeMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroSbeMessage ==
    [ blockLength |-> [i \in 1 .. 2 |-> 0],
      schemaId    |-> [i \in 1 .. 2 |-> 0],
      version     |-> [i \in 1 .. 2 |-> 0],
      payload     |-> ZeroPayload ]

(* Sbe Message at zero, then each field in turn at the values it is checked at *)
CheckedSbeMessage ==
    { ZeroSbeMessage }
        \cup { [ZeroSbeMessage EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSbeMessage EXCEPT !.schemaId = one] : one \in Sample(2) }
        \cup { [ZeroSbeMessage EXCEPT !.version = one] : one \in Sample(2) }
        \cup { [ZeroSbeMessage EXCEPT !.payload = one] : one \in CheckedPayload }

(* A run of Sbe Message, written one after another *)
RECURSIVE EncodeSbeMessageList(_)
EncodeSbeMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSbeMessage(Head(messages)) \o EncodeSbeMessageList(Tail(messages))

(* As many Sbe Message as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadSbeMessageAll(_)
ReadSbeMessageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeSbeMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSbeMessageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Sbe Message of each kind, for the lists that carry them *)
OneSbeMessage ==
    { [ZeroSbeMessage EXCEPT !.payload = [tag |-> LoginRequestMessageCode, body |-> ZeroLoginRequestMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> LoginResponseMessageCode, body |-> ZeroLoginResponseMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> GatewayHeartbeatMessageCode, body |-> ZeroGatewayHeartbeatMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> ClientHeartbeatMessageCode, body |-> 0]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> LogoutRequestMessageCode, body |-> 0]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> TerminateMessageCode, body |-> ZeroTerminateMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> SequencedMessageHeaderMessageCode, body |-> ZeroSequencedMessageHeaderMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> SubsessionJoinMessageCode, body |-> ZeroSubsessionJoinMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> SubsessionJoinResponseMessageCode, body |-> ZeroSubsessionJoinResponseMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> SubsessionLeaveMessageCode, body |-> ZeroSubsessionLeaveMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> SubsessionLeaveResponseMessageCode, body |-> ZeroSubsessionLeaveResponseMessage]] }

(***************************************************************************)
(* Client Packet                                                           *)
(***************************************************************************)

ClientPacket ==
    [ sbeMessage : SampleLists(OneSbeMessage) ]

EncodeClientPacket(message) ==
    EncodeSbeMessageList(message.sbeMessage)

DecodeClientPacket(bytes) ==
    LET sbeMessage == ReadSbeMessageAll(bytes) IN IF ~sbeMessage.ok THEN Fail ELSE
    Ok([ sbeMessage |-> sbeMessage.value ], sbeMessage.rest)

ZeroClientPacket ==
    [ sbeMessage |-> << >> ]

(* Client Packet at zero, then each field in turn at the values it is checked at *)
CheckedClientPacket ==
    { ZeroClientPacket }
        \cup { [ZeroClientPacket EXCEPT !.sbeMessage = one] : one \in SampleLists(OneSbeMessage) }

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
                /\ \A i \in 1 .. width : EncodeUIntLE(value, width)[i] \in Byte

(* Every Login Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRequestMessage ==
    \A message \in CheckedLoginRequestMessage :
        LET read == DecodeLoginRequestMessage(EncodeLoginRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginResponseMessage ==
    \A message \in CheckedLoginResponseMessage :
        LET read == DecodeLoginResponseMessage(EncodeLoginResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sub Sessions Group decodes back to what was encoded, and leaves nothing over *)
RoundTripSubSessionsGroup ==
    \A message \in CheckedSubSessionsGroup :
        LET read == DecodeSubSessionsGroup(EncodeSubSessionsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sub Sessions Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripSubSessionsGroups ==
    \A message \in CheckedSubSessionsGroups :
        LET read == DecodeSubSessionsGroups(EncodeSubSessionsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Gateway Heartbeat Message decodes back to what was encoded, and leaves nothing over *)
RoundTripGatewayHeartbeatMessage ==
    \A message \in CheckedGatewayHeartbeatMessage :
        LET read == DecodeGatewayHeartbeatMessage(EncodeGatewayHeartbeatMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Terminate Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTerminateMessage ==
    \A message \in CheckedTerminateMessage :
        LET read == DecodeTerminateMessage(EncodeTerminateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sequenced Message Header Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSequencedMessageHeaderMessage ==
    \A message \in CheckedSequencedMessageHeaderMessage :
        LET read == DecodeSequencedMessageHeaderMessage(EncodeSequencedMessageHeaderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Subsession Join Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSubsessionJoinMessage ==
    \A message \in CheckedSubsessionJoinMessage :
        LET read == DecodeSubsessionJoinMessage(EncodeSubsessionJoinMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Subsession Join Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSubsessionJoinResponseMessage ==
    \A message \in CheckedSubsessionJoinResponseMessage :
        LET read == DecodeSubsessionJoinResponseMessage(EncodeSubsessionJoinResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Subsession Leave Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSubsessionLeaveMessage ==
    \A message \in CheckedSubsessionLeaveMessage :
        LET read == DecodeSubsessionLeaveMessage(EncodeSubsessionLeaveMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Subsession Leave Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSubsessionLeaveResponseMessage ==
    \A message \in CheckedSubsessionLeaveResponseMessage :
        LET read == DecodeSubsessionLeaveResponseMessage(EncodeSubsessionLeaveResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sbe Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSbeMessage ==
    \A message \in CheckedSbeMessage :
        LET read == DecodeSbeMessage(EncodeSbeMessage(message))
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

(* A Payload is selected by the Template Id it is written under *)
SelectsPayload ==
    \A message \in Payload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Packet Length is written from the bytes it frames *)
FramesSbeMessage ==
    \A message \in SbeMessage :
        LET bytes == EncodeSbeMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
