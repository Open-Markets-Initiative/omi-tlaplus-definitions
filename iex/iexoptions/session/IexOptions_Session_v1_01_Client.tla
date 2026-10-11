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
(* Client Payload, selected by Schema Id and Template Id                   *)
(***************************************************************************)

LoginRequestMessageCode == <<20000, 1>>  \* 0x4e20, 0x01
ClientHeartbeatMessageCode == <<20000, 4>>  \* 0x4e20, 0x04
LogoutRequestMessageCode == <<20000, 5>>  \* 0x4e20, 0x05
SequencedMessageHeaderMessageCode == <<20000, 7>>  \* 0x4e20, 0x07
SubsessionJoinMessageCode == <<20000, 8>>  \* 0x4e20, 0x08
SubsessionLeaveMessageCode == <<20000, 10>>  \* 0x4e20, 0x0a

ClientPayload ==
    [ tag : {LoginRequestMessageCode}, body : LoginRequestMessage ]
        \cup [ tag : {ClientHeartbeatMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {LogoutRequestMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {SequencedMessageHeaderMessageCode}, body : SequencedMessageHeaderMessage ]
        \cup [ tag : {SubsessionJoinMessageCode}, body : SubsessionJoinMessage ]
        \cup [ tag : {SubsessionLeaveMessageCode}, body : SubsessionLeaveMessage ]

EncodeClientPayload(message) ==
    CASE message.tag = LoginRequestMessageCode -> EncodeLoginRequestMessage(message.body)
      [] message.tag = ClientHeartbeatMessageCode -> << >>
      [] message.tag = LogoutRequestMessageCode -> << >>
      [] message.tag = SequencedMessageHeaderMessageCode -> EncodeSequencedMessageHeaderMessage(message.body)
      [] message.tag = SubsessionJoinMessageCode -> EncodeSubsessionJoinMessage(message.body)
      [] message.tag = SubsessionLeaveMessageCode -> EncodeSubsessionLeaveMessage(message.body)

DecodeClientPayload(schemaId, templateId, bytes) ==
    LET read ==
            CASE <<schemaId, templateId>> = LoginRequestMessageCode -> DecodeLoginRequestMessage(bytes)
              [] <<schemaId, templateId>> = ClientHeartbeatMessageCode -> Ok([empty |-> 0], bytes)
              [] <<schemaId, templateId>> = LogoutRequestMessageCode -> Ok([empty |-> 0], bytes)
              [] <<schemaId, templateId>> = SequencedMessageHeaderMessageCode -> DecodeSequencedMessageHeaderMessage(bytes)
              [] <<schemaId, templateId>> = SubsessionJoinMessageCode -> DecodeSubsessionJoinMessage(bytes)
              [] <<schemaId, templateId>> = SubsessionLeaveMessageCode -> DecodeSubsessionLeaveMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> <<schemaId, templateId>>, body |-> read.value], read.rest)

ZeroClientPayload == [tag |-> LoginRequestMessageCode, body |-> ZeroLoginRequestMessage]

(* Each Client Payload in turn, at the values the message it names is checked at *)
CheckedClientPayload ==
    { [tag |-> LoginRequestMessageCode, body |-> one] : one \in CheckedLoginRequestMessage }
        \cup { [tag |-> ClientHeartbeatMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> LogoutRequestMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> SequencedMessageHeaderMessageCode, body |-> one] : one \in CheckedSequencedMessageHeaderMessage }
        \cup { [tag |-> SubsessionJoinMessageCode, body |-> one] : one \in CheckedSubsessionJoinMessage }
        \cup { [tag |-> SubsessionLeaveMessageCode, body |-> one] : one \in CheckedSubsessionLeaveMessage }

(***************************************************************************)
(* Client Sbe Message, framed by Packet Length                             *)
(***************************************************************************)

ClientSbeMessage ==
    [ blockLength   : Sample(2),
      version       : Sample(2),
      clientPayload : ClientPayload ]

EncodeClientSbeMessageBody(message) ==
    message.blockLength
        \o EncodeUIntLE(message.clientPayload.tag[2], 2)
        \o EncodeUIntLE(message.clientPayload.tag[1], 2)
        \o message.version
        \o EncodeClientPayload(message.clientPayload)

(* Packet Length counts the bytes it frames, so it is written from them *)
EncodeClientSbeMessage(message) ==
    LET body == EncodeClientSbeMessageBody(message)
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeClientSbeMessageBody(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET templateId == ReadUIntLE(blockLength.rest, 2) IN IF ~templateId.ok THEN Fail ELSE
    LET schemaId == ReadUIntLE(templateId.rest, 2) IN IF ~schemaId.ok THEN Fail ELSE
    LET version == ReadBytes(schemaId.rest, 2) IN IF ~version.ok THEN Fail ELSE
    LET clientPayload == DecodeClientPayload(schemaId.value, templateId.value, version.rest) IN IF ~clientPayload.ok THEN Fail ELSE
    Ok([ blockLength   |-> blockLength.value,
         version       |-> version.value,
         clientPayload |-> clientPayload.value ], clientPayload.rest)

DecodeClientSbeMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeClientSbeMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroClientSbeMessage ==
    [ blockLength   |-> [i \in 1 .. 2 |-> 0],
      version       |-> [i \in 1 .. 2 |-> 0],
      clientPayload |-> ZeroClientPayload ]

(* Client Sbe Message at zero, then each field in turn at the values it is checked at *)
CheckedClientSbeMessage ==
    { ZeroClientSbeMessage }
        \cup { [ZeroClientSbeMessage EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroClientSbeMessage EXCEPT !.version = one] : one \in Sample(2) }
        \cup { [ZeroClientSbeMessage EXCEPT !.clientPayload = one] : one \in CheckedClientPayload }

(* A run of Client Sbe Message, written one after another *)
RECURSIVE EncodeClientSbeMessageList(_)
EncodeClientSbeMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeClientSbeMessage(Head(messages)) \o EncodeClientSbeMessageList(Tail(messages))

(* As many Client Sbe Message as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadClientSbeMessageAll(_)
ReadClientSbeMessageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeClientSbeMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadClientSbeMessageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Client Sbe Message of each kind, for the lists that carry them *)
OneClientSbeMessage ==
    { [ZeroClientSbeMessage EXCEPT !.clientPayload = [tag |-> LoginRequestMessageCode, body |-> ZeroLoginRequestMessage]],
      [ZeroClientSbeMessage EXCEPT !.clientPayload = [tag |-> ClientHeartbeatMessageCode, body |-> [empty |-> 0]]],
      [ZeroClientSbeMessage EXCEPT !.clientPayload = [tag |-> LogoutRequestMessageCode, body |-> [empty |-> 0]]],
      [ZeroClientSbeMessage EXCEPT !.clientPayload = [tag |-> SequencedMessageHeaderMessageCode, body |-> ZeroSequencedMessageHeaderMessage]],
      [ZeroClientSbeMessage EXCEPT !.clientPayload = [tag |-> SubsessionJoinMessageCode, body |-> ZeroSubsessionJoinMessage]],
      [ZeroClientSbeMessage EXCEPT !.clientPayload = [tag |-> SubsessionLeaveMessageCode, body |-> ZeroSubsessionLeaveMessage]] }

(***************************************************************************)
(* Client Packet                                                           *)
(***************************************************************************)

ClientPacket ==
    [ clientSbeMessage : SampleLists(OneClientSbeMessage) ]

EncodeClientPacket(message) ==
    EncodeClientSbeMessageList(message.clientSbeMessage)

DecodeClientPacket(bytes) ==
    LET clientSbeMessage == ReadClientSbeMessageAll(bytes) IN IF ~clientSbeMessage.ok THEN Fail ELSE
    Ok([ clientSbeMessage |-> clientSbeMessage.value ], clientSbeMessage.rest)

ZeroClientPacket ==
    [ clientSbeMessage |-> << >> ]

(* Client Packet at zero, then each field in turn at the values it is checked at *)
CheckedClientPacket ==
    { ZeroClientPacket }
        \cup { [ZeroClientPacket EXCEPT !.clientSbeMessage = one] : one \in SampleLists(OneClientSbeMessage) }

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

(* Every Login Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRequestMessage ==
    \A message \in CheckedLoginRequestMessage :
        LET read == DecodeLoginRequestMessage(EncodeLoginRequestMessage(message))
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

(* Every Subsession Leave Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSubsessionLeaveMessage ==
    \A message \in CheckedSubsessionLeaveMessage :
        LET read == DecodeSubsessionLeaveMessage(EncodeSubsessionLeaveMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client Sbe Message decodes back to what was encoded, and leaves nothing over *)
RoundTripClientSbeMessage ==
    \A message \in CheckedClientSbeMessage :
        LET read == DecodeClientSbeMessage(EncodeClientSbeMessage(message))
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

(* A Client Payload is selected by the Schema Id it is written under *)
SelectsClientPayload ==
    \A message \in CheckedClientPayload :
        LET read == DecodeClientPayload(message.tag[1], message.tag[2], EncodeClientPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Packet Length is written from the bytes it frames *)
FramesClientSbeMessage ==
    \A message \in CheckedClientSbeMessage :
        LET bytes == EncodeClientSbeMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
