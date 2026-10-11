------------------ MODULE IexOptions_Session_v1_01_Server ------------------
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
        \o EncodeUIntBE(Len(message.subSessionsGroup), 1)
        \o EncodeSubSessionsGroupList(message.subSessionsGroup)

DecodeSubSessionsGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
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
(* Server Payload, selected by Schema Id and Template Id                   *)
(***************************************************************************)

LoginResponseMessageCode == <<20000, 2>>  \* 0x4e20, 0x02
GatewayHeartbeatMessageCode == <<20000, 3>>  \* 0x4e20, 0x03
TerminateMessageCode == <<20000, 6>>  \* 0x4e20, 0x06
SequencedMessageHeaderMessageCode == <<20000, 7>>  \* 0x4e20, 0x07
SubsessionJoinResponseMessageCode == <<20000, 9>>  \* 0x4e20, 0x09
SubsessionLeaveResponseMessageCode == <<20000, 11>>  \* 0x4e20, 0x0b

ServerPayload ==
    [ tag : {LoginResponseMessageCode}, body : LoginResponseMessage ]
        \cup [ tag : {GatewayHeartbeatMessageCode}, body : GatewayHeartbeatMessage ]
        \cup [ tag : {TerminateMessageCode}, body : TerminateMessage ]
        \cup [ tag : {SequencedMessageHeaderMessageCode}, body : SequencedMessageHeaderMessage ]
        \cup [ tag : {SubsessionJoinResponseMessageCode}, body : SubsessionJoinResponseMessage ]
        \cup [ tag : {SubsessionLeaveResponseMessageCode}, body : SubsessionLeaveResponseMessage ]

EncodeServerPayload(message) ==
    CASE message.tag = LoginResponseMessageCode -> EncodeLoginResponseMessage(message.body)
      [] message.tag = GatewayHeartbeatMessageCode -> EncodeGatewayHeartbeatMessage(message.body)
      [] message.tag = TerminateMessageCode -> EncodeTerminateMessage(message.body)
      [] message.tag = SequencedMessageHeaderMessageCode -> EncodeSequencedMessageHeaderMessage(message.body)
      [] message.tag = SubsessionJoinResponseMessageCode -> EncodeSubsessionJoinResponseMessage(message.body)
      [] message.tag = SubsessionLeaveResponseMessageCode -> EncodeSubsessionLeaveResponseMessage(message.body)

DecodeServerPayload(schemaId, templateId, bytes) ==
    LET read ==
            CASE <<schemaId, templateId>> = LoginResponseMessageCode -> DecodeLoginResponseMessage(bytes)
              [] <<schemaId, templateId>> = GatewayHeartbeatMessageCode -> DecodeGatewayHeartbeatMessage(bytes)
              [] <<schemaId, templateId>> = TerminateMessageCode -> DecodeTerminateMessage(bytes)
              [] <<schemaId, templateId>> = SequencedMessageHeaderMessageCode -> DecodeSequencedMessageHeaderMessage(bytes)
              [] <<schemaId, templateId>> = SubsessionJoinResponseMessageCode -> DecodeSubsessionJoinResponseMessage(bytes)
              [] <<schemaId, templateId>> = SubsessionLeaveResponseMessageCode -> DecodeSubsessionLeaveResponseMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> <<schemaId, templateId>>, body |-> read.value], read.rest)

ZeroServerPayload == [tag |-> LoginResponseMessageCode, body |-> ZeroLoginResponseMessage]

(* Each Server Payload in turn, at the values the message it names is checked at *)
CheckedServerPayload ==
    { [tag |-> LoginResponseMessageCode, body |-> one] : one \in CheckedLoginResponseMessage }
        \cup { [tag |-> GatewayHeartbeatMessageCode, body |-> one] : one \in CheckedGatewayHeartbeatMessage }
        \cup { [tag |-> TerminateMessageCode, body |-> one] : one \in CheckedTerminateMessage }
        \cup { [tag |-> SequencedMessageHeaderMessageCode, body |-> one] : one \in CheckedSequencedMessageHeaderMessage }
        \cup { [tag |-> SubsessionJoinResponseMessageCode, body |-> one] : one \in CheckedSubsessionJoinResponseMessage }
        \cup { [tag |-> SubsessionLeaveResponseMessageCode, body |-> one] : one \in CheckedSubsessionLeaveResponseMessage }

(***************************************************************************)
(* Server Sbe Message, framed by Packet Length                             *)
(***************************************************************************)

ServerSbeMessage ==
    [ blockLength   : Sample(2),
      version       : Sample(2),
      serverPayload : ServerPayload ]

EncodeServerSbeMessageBody(message) ==
    message.blockLength
        \o EncodeUIntLE(message.serverPayload.tag[2], 2)
        \o EncodeUIntLE(message.serverPayload.tag[1], 2)
        \o message.version
        \o EncodeServerPayload(message.serverPayload)

(* Packet Length counts the bytes it frames, so it is written from them *)
EncodeServerSbeMessage(message) ==
    LET body == EncodeServerSbeMessageBody(message)
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeServerSbeMessageBody(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET templateId == ReadUIntLE(blockLength.rest, 2) IN IF ~templateId.ok THEN Fail ELSE
    LET schemaId == ReadUIntLE(templateId.rest, 2) IN IF ~schemaId.ok THEN Fail ELSE
    LET version == ReadBytes(schemaId.rest, 2) IN IF ~version.ok THEN Fail ELSE
    LET serverPayload == DecodeServerPayload(schemaId.value, templateId.value, version.rest) IN IF ~serverPayload.ok THEN Fail ELSE
    Ok([ blockLength   |-> blockLength.value,
         version       |-> version.value,
         serverPayload |-> serverPayload.value ], serverPayload.rest)

DecodeServerSbeMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeServerSbeMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroServerSbeMessage ==
    [ blockLength   |-> [i \in 1 .. 2 |-> 0],
      version       |-> [i \in 1 .. 2 |-> 0],
      serverPayload |-> ZeroServerPayload ]

(* Server Sbe Message at zero, then each field in turn at the values it is checked at *)
CheckedServerSbeMessage ==
    { ZeroServerSbeMessage }
        \cup { [ZeroServerSbeMessage EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroServerSbeMessage EXCEPT !.version = one] : one \in Sample(2) }
        \cup { [ZeroServerSbeMessage EXCEPT !.serverPayload = one] : one \in CheckedServerPayload }

(* A run of Server Sbe Message, written one after another *)
RECURSIVE EncodeServerSbeMessageList(_)
EncodeServerSbeMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeServerSbeMessage(Head(messages)) \o EncodeServerSbeMessageList(Tail(messages))

(* As many Server Sbe Message as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadServerSbeMessageAll(_)
ReadServerSbeMessageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeServerSbeMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadServerSbeMessageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Server Sbe Message of each kind, for the lists that carry them *)
OneServerSbeMessage ==
    { [ZeroServerSbeMessage EXCEPT !.serverPayload = [tag |-> LoginResponseMessageCode, body |-> ZeroLoginResponseMessage]],
      [ZeroServerSbeMessage EXCEPT !.serverPayload = [tag |-> GatewayHeartbeatMessageCode, body |-> ZeroGatewayHeartbeatMessage]],
      [ZeroServerSbeMessage EXCEPT !.serverPayload = [tag |-> TerminateMessageCode, body |-> ZeroTerminateMessage]],
      [ZeroServerSbeMessage EXCEPT !.serverPayload = [tag |-> SequencedMessageHeaderMessageCode, body |-> ZeroSequencedMessageHeaderMessage]],
      [ZeroServerSbeMessage EXCEPT !.serverPayload = [tag |-> SubsessionJoinResponseMessageCode, body |-> ZeroSubsessionJoinResponseMessage]],
      [ZeroServerSbeMessage EXCEPT !.serverPayload = [tag |-> SubsessionLeaveResponseMessageCode, body |-> ZeroSubsessionLeaveResponseMessage]] }

(***************************************************************************)
(* Server Packet                                                           *)
(***************************************************************************)

ServerPacket ==
    [ serverSbeMessage : SampleLists(OneServerSbeMessage) ]

EncodeServerPacket(message) ==
    EncodeServerSbeMessageList(message.serverSbeMessage)

DecodeServerPacket(bytes) ==
    LET serverSbeMessage == ReadServerSbeMessageAll(bytes) IN IF ~serverSbeMessage.ok THEN Fail ELSE
    Ok([ serverSbeMessage |-> serverSbeMessage.value ], serverSbeMessage.rest)

ZeroServerPacket ==
    [ serverSbeMessage |-> << >> ]

(* Server Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerPacket ==
    { ZeroServerPacket }
        \cup { [ZeroServerPacket EXCEPT !.serverSbeMessage = one] : one \in SampleLists(OneServerSbeMessage) }

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

(* Every Subsession Join Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSubsessionJoinResponseMessage ==
    \A message \in CheckedSubsessionJoinResponseMessage :
        LET read == DecodeSubsessionJoinResponseMessage(EncodeSubsessionJoinResponseMessage(message))
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

(* Every Server Sbe Message decodes back to what was encoded, and leaves nothing over *)
RoundTripServerSbeMessage ==
    \A message \in CheckedServerSbeMessage :
        LET read == DecodeServerSbeMessage(EncodeServerSbeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Server Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripServerPacket ==
    \A message \in CheckedServerPacket :
        LET read == DecodeServerPacket(EncodeServerPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Server Payload is selected by the Schema Id it is written under *)
SelectsServerPayload ==
    \A message \in CheckedServerPayload :
        LET read == DecodeServerPayload(message.tag[1], message.tag[2], EncodeServerPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Packet Length is written from the bytes it frames *)
FramesServerSbeMessage ==
    \A message \in CheckedServerSbeMessage :
        LET bytes == EncodeServerSbeMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
