----------------- MODULE CoinbaseDerivatives_Session_v1_2 ------------------
(***************************************************************************)
(* Coinbase  v1.2                                                          *)
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
(* Note: Flags is a bit field set, checked as its 1 byte rather than bit   *)
(* by bit.                                                                 *)
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
(* Logon Message: 49 bytes                                                 *)
(***************************************************************************)

LogonMessage ==
    [ username    : Sample(16),
      password    : Sample(32),
      resetSeqNum : Sample(1) ]

EncodeLogonMessage(message) ==
    message.username
        \o message.password
        \o message.resetSeqNum

DecodeLogonMessage(bytes) ==
    LET username == ReadBytes(bytes, 16) IN IF ~username.ok THEN Fail ELSE
    LET password == ReadBytes(username.rest, 32) IN IF ~password.ok THEN Fail ELSE
    LET resetSeqNum == ReadBytes(password.rest, 1) IN IF ~resetSeqNum.ok THEN Fail ELSE
    Ok([ username    |-> username.value,
         password    |-> password.value,
         resetSeqNum |-> resetSeqNum.value ], resetSeqNum.rest)

ZeroLogonMessage ==
    [ username    |-> [i \in 1 .. 16 |-> 0],
      password    |-> [i \in 1 .. 32 |-> 0],
      resetSeqNum |-> [i \in 1 .. 1 |-> 0] ]

(* Logon Message at zero, then each field in turn at the values it is checked at *)
CheckedLogonMessage ==
    { ZeroLogonMessage }
        \cup { [ZeroLogonMessage EXCEPT !.username = one] : one \in Sample(16) }
        \cup { [ZeroLogonMessage EXCEPT !.password = one] : one \in Sample(32) }
        \cup { [ZeroLogonMessage EXCEPT !.resetSeqNum = one] : one \in Sample(1) }

(***************************************************************************)
(* Logon Conf Message: 4 bytes                                             *)
(***************************************************************************)

LogonConfMessage ==
    [ heartbeatIntervalSeconds : Sample(4) ]

EncodeLogonConfMessage(message) ==
    message.heartbeatIntervalSeconds

DecodeLogonConfMessage(bytes) ==
    LET heartbeatIntervalSeconds == ReadBytes(bytes, 4) IN IF ~heartbeatIntervalSeconds.ok THEN Fail ELSE
    Ok([ heartbeatIntervalSeconds |-> heartbeatIntervalSeconds.value ], heartbeatIntervalSeconds.rest)

ZeroLogonConfMessage ==
    [ heartbeatIntervalSeconds |-> [i \in 1 .. 4 |-> 0] ]

(* Logon Conf Message at zero, then each field in turn at the values it is checked at *)
CheckedLogonConfMessage ==
    { ZeroLogonConfMessage }
        \cup { [ZeroLogonConfMessage EXCEPT !.heartbeatIntervalSeconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Logout Message: 64 bytes                                                *)
(***************************************************************************)

LogoutMessage ==
    [ reasonString64 : Sample(64) ]

EncodeLogoutMessage(message) ==
    message.reasonString64

DecodeLogoutMessage(bytes) ==
    LET reasonString64 == ReadBytes(bytes, 64) IN IF ~reasonString64.ok THEN Fail ELSE
    Ok([ reasonString64 |-> reasonString64.value ], reasonString64.rest)

ZeroLogoutMessage ==
    [ reasonString64 |-> [i \in 1 .. 64 |-> 0] ]

(* Logout Message at zero, then each field in turn at the values it is checked at *)
CheckedLogoutMessage ==
    { ZeroLogoutMessage }
        \cup { [ZeroLogoutMessage EXCEPT !.reasonString64 = one] : one \in Sample(64) }

(***************************************************************************)
(* Logged Out Message: 64 bytes                                            *)
(***************************************************************************)

LoggedOutMessage ==
    [ reasonString64 : Sample(64) ]

EncodeLoggedOutMessage(message) ==
    message.reasonString64

DecodeLoggedOutMessage(bytes) ==
    LET reasonString64 == ReadBytes(bytes, 64) IN IF ~reasonString64.ok THEN Fail ELSE
    Ok([ reasonString64 |-> reasonString64.value ], reasonString64.rest)

ZeroLoggedOutMessage ==
    [ reasonString64 |-> [i \in 1 .. 64 |-> 0] ]

(* Logged Out Message at zero, then each field in turn at the values it is checked at *)
CheckedLoggedOutMessage ==
    { ZeroLoggedOutMessage }
        \cup { [ZeroLoggedOutMessage EXCEPT !.reasonString64 = one] : one \in Sample(64) }

(***************************************************************************)
(* Heartbeat Message: 8 bytes                                              *)
(***************************************************************************)

HeartbeatMessage ==
    [ correlationId : Sample(8) ]

EncodeHeartbeatMessage(message) ==
    message.correlationId

DecodeHeartbeatMessage(bytes) ==
    LET correlationId == ReadBytes(bytes, 8) IN IF ~correlationId.ok THEN Fail ELSE
    Ok([ correlationId |-> correlationId.value ], correlationId.rest)

ZeroHeartbeatMessage ==
    [ correlationId |-> [i \in 1 .. 8 |-> 0] ]

(* Heartbeat Message at zero, then each field in turn at the values it is checked at *)
CheckedHeartbeatMessage ==
    { ZeroHeartbeatMessage }
        \cup { [ZeroHeartbeatMessage EXCEPT !.correlationId = one] : one \in Sample(8) }

(***************************************************************************)
(* Test Request Message: 8 bytes                                           *)
(***************************************************************************)

TestRequestMessage ==
    [ correlationId : Sample(8) ]

EncodeTestRequestMessage(message) ==
    message.correlationId

DecodeTestRequestMessage(bytes) ==
    LET correlationId == ReadBytes(bytes, 8) IN IF ~correlationId.ok THEN Fail ELSE
    Ok([ correlationId |-> correlationId.value ], correlationId.rest)

ZeroTestRequestMessage ==
    [ correlationId |-> [i \in 1 .. 8 |-> 0] ]

(* Test Request Message at zero, then each field in turn at the values it is checked at *)
CheckedTestRequestMessage ==
    { ZeroTestRequestMessage }
        \cup { [ZeroTestRequestMessage EXCEPT !.correlationId = one] : one \in Sample(8) }

(***************************************************************************)
(* Resend Request Message: 8 bytes                                         *)
(***************************************************************************)

ResendRequestMessage ==
    [ fromSequenceNumber : Sample(4),
      toSequenceNumber   : Sample(4) ]

EncodeResendRequestMessage(message) ==
    message.fromSequenceNumber
        \o message.toSequenceNumber

DecodeResendRequestMessage(bytes) ==
    LET fromSequenceNumber == ReadBytes(bytes, 4) IN IF ~fromSequenceNumber.ok THEN Fail ELSE
    LET toSequenceNumber == ReadBytes(fromSequenceNumber.rest, 4) IN IF ~toSequenceNumber.ok THEN Fail ELSE
    Ok([ fromSequenceNumber |-> fromSequenceNumber.value,
         toSequenceNumber   |-> toSequenceNumber.value ], toSequenceNumber.rest)

ZeroResendRequestMessage ==
    [ fromSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      toSequenceNumber   |-> [i \in 1 .. 4 |-> 0] ]

(* Resend Request Message at zero, then each field in turn at the values it is checked at *)
CheckedResendRequestMessage ==
    { ZeroResendRequestMessage }
        \cup { [ZeroResendRequestMessage EXCEPT !.fromSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroResendRequestMessage EXCEPT !.toSequenceNumber = one] : one \in Sample(4) }

(***************************************************************************)
(* Gap Fill Message: 8 bytes                                               *)
(***************************************************************************)

GapFillMessage ==
    [ newSequenceNumber : Sample(4),
      gapFillPadding    : Sample(4) ]

EncodeGapFillMessage(message) ==
    message.newSequenceNumber
        \o message.gapFillPadding

DecodeGapFillMessage(bytes) ==
    LET newSequenceNumber == ReadBytes(bytes, 4) IN IF ~newSequenceNumber.ok THEN Fail ELSE
    LET gapFillPadding == ReadBytes(newSequenceNumber.rest, 4) IN IF ~gapFillPadding.ok THEN Fail ELSE
    Ok([ newSequenceNumber |-> newSequenceNumber.value,
         gapFillPadding    |-> gapFillPadding.value ], gapFillPadding.rest)

ZeroGapFillMessage ==
    [ newSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      gapFillPadding    |-> [i \in 1 .. 4 |-> 0] ]

(* Gap Fill Message at zero, then each field in turn at the values it is checked at *)
CheckedGapFillMessage ==
    { ZeroGapFillMessage }
        \cup { [ZeroGapFillMessage EXCEPT !.newSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroGapFillMessage EXCEPT !.gapFillPadding = one] : one \in Sample(4) }

(***************************************************************************)
(* Reject Message: 72 bytes                                                *)
(***************************************************************************)

RejectMessage ==
    [ refSequenceNumber  : Sample(4),
      reasonRejectReason : Sample(4),
      details            : Sample(64) ]

EncodeRejectMessage(message) ==
    message.refSequenceNumber
        \o message.reasonRejectReason
        \o message.details

DecodeRejectMessage(bytes) ==
    LET refSequenceNumber == ReadBytes(bytes, 4) IN IF ~refSequenceNumber.ok THEN Fail ELSE
    LET reasonRejectReason == ReadBytes(refSequenceNumber.rest, 4) IN IF ~reasonRejectReason.ok THEN Fail ELSE
    LET details == ReadBytes(reasonRejectReason.rest, 64) IN IF ~details.ok THEN Fail ELSE
    Ok([ refSequenceNumber  |-> refSequenceNumber.value,
         reasonRejectReason |-> reasonRejectReason.value,
         details            |-> details.value ], details.rest)

ZeroRejectMessage ==
    [ refSequenceNumber  |-> [i \in 1 .. 4 |-> 0],
      reasonRejectReason |-> [i \in 1 .. 4 |-> 0],
      details            |-> [i \in 1 .. 64 |-> 0] ]

(* Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedRejectMessage ==
    { ZeroRejectMessage }
        \cup { [ZeroRejectMessage EXCEPT !.refSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroRejectMessage EXCEPT !.reasonRejectReason = one] : one \in Sample(4) }
        \cup { [ZeroRejectMessage EXCEPT !.details = one] : one \in Sample(64) }

(***************************************************************************)
(* Payload, selected by Template Id                                        *)
(***************************************************************************)

LogonMessageCode == 100  \* 0x64
LogonConfMessageCode == 200  \* 0xc8
LogoutMessageCode == 101  \* 0x65
LoggedOutMessageCode == 201  \* 0xc9
HeartbeatMessageCode == 10  \* 0x0a
TestRequestMessageCode == 11  \* 0x0b
ResendRequestMessageCode == 102  \* 0x66
GapFillMessageCode == 202  \* 0xca
RejectMessageCode == 210  \* 0xd2

Payload ==
    [ tag : {LogonMessageCode}, body : LogonMessage ]
        \cup [ tag : {LogonConfMessageCode}, body : LogonConfMessage ]
        \cup [ tag : {LogoutMessageCode}, body : LogoutMessage ]
        \cup [ tag : {LoggedOutMessageCode}, body : LoggedOutMessage ]
        \cup [ tag : {HeartbeatMessageCode}, body : HeartbeatMessage ]
        \cup [ tag : {TestRequestMessageCode}, body : TestRequestMessage ]
        \cup [ tag : {ResendRequestMessageCode}, body : ResendRequestMessage ]
        \cup [ tag : {GapFillMessageCode}, body : GapFillMessage ]
        \cup [ tag : {RejectMessageCode}, body : RejectMessage ]

EncodePayload(message) ==
    CASE message.tag = LogonMessageCode -> EncodeLogonMessage(message.body)
      [] message.tag = LogonConfMessageCode -> EncodeLogonConfMessage(message.body)
      [] message.tag = LogoutMessageCode -> EncodeLogoutMessage(message.body)
      [] message.tag = LoggedOutMessageCode -> EncodeLoggedOutMessage(message.body)
      [] message.tag = HeartbeatMessageCode -> EncodeHeartbeatMessage(message.body)
      [] message.tag = TestRequestMessageCode -> EncodeTestRequestMessage(message.body)
      [] message.tag = ResendRequestMessageCode -> EncodeResendRequestMessage(message.body)
      [] message.tag = GapFillMessageCode -> EncodeGapFillMessage(message.body)
      [] message.tag = RejectMessageCode -> EncodeRejectMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = LogonMessageCode -> DecodeLogonMessage(bytes)
              [] tag = LogonConfMessageCode -> DecodeLogonConfMessage(bytes)
              [] tag = LogoutMessageCode -> DecodeLogoutMessage(bytes)
              [] tag = LoggedOutMessageCode -> DecodeLoggedOutMessage(bytes)
              [] tag = HeartbeatMessageCode -> DecodeHeartbeatMessage(bytes)
              [] tag = TestRequestMessageCode -> DecodeTestRequestMessage(bytes)
              [] tag = ResendRequestMessageCode -> DecodeResendRequestMessage(bytes)
              [] tag = GapFillMessageCode -> DecodeGapFillMessage(bytes)
              [] tag = RejectMessageCode -> DecodeRejectMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> LogonMessageCode, body |-> ZeroLogonMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> LogonMessageCode, body |-> one] : one \in CheckedLogonMessage }
        \cup { [tag |-> LogonConfMessageCode, body |-> one] : one \in CheckedLogonConfMessage }
        \cup { [tag |-> LogoutMessageCode, body |-> one] : one \in CheckedLogoutMessage }
        \cup { [tag |-> LoggedOutMessageCode, body |-> one] : one \in CheckedLoggedOutMessage }
        \cup { [tag |-> HeartbeatMessageCode, body |-> one] : one \in CheckedHeartbeatMessage }
        \cup { [tag |-> TestRequestMessageCode, body |-> one] : one \in CheckedTestRequestMessage }
        \cup { [tag |-> ResendRequestMessageCode, body |-> one] : one \in CheckedResendRequestMessage }
        \cup { [tag |-> GapFillMessageCode, body |-> one] : one \in CheckedGapFillMessage }
        \cup { [tag |-> RejectMessageCode, body |-> one] : one \in CheckedRejectMessage }

(***************************************************************************)
(* Sbe Message, framed by Message Length                                   *)
(***************************************************************************)

SbeMessage ==
    [ protocolId         : Sample(1),
      flags              : Sample(1),
      sequenceNumber     : Sample(4),
      lastProcessedSeqNo : Sample(4),
      reserved           : Sample(4),
      sendTimeEpochNanos : Sample(8),
      blockLength        : Sample(2),
      schemaId           : Sample(2),
      version            : Sample(2),
      payload            : Payload,
      padding            : SampleBytes ]

EncodeSbeMessageBody(message) ==
    message.sequenceNumber
        \o message.lastProcessedSeqNo
        \o message.reserved
        \o message.sendTimeEpochNanos
        \o message.blockLength
        \o EncodeUIntLE(message.payload.tag, 2)
        \o message.schemaId
        \o message.version
        \o EncodePayload(message.payload)
        \o message.padding

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeSbeMessage(message) ==
    LET body == EncodeSbeMessageBody(message)
    IN  message.protocolId \o message.flags \o EncodeUIntLE(Len(body) + 4, 2) \o body

DecodeSbeMessage(bytes) ==
    LET protocolId == ReadBytes(bytes, 1) IN IF ~protocolId.ok THEN Fail ELSE
    LET flags == ReadBytes(protocolId.rest, 1) IN IF ~flags.ok THEN Fail ELSE
    LET length == ReadUIntLE(flags.rest, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 4 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
    IN
    LET sequenceNumber == ReadBytes(framed, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET lastProcessedSeqNo == ReadBytes(sequenceNumber.rest, 4) IN IF ~lastProcessedSeqNo.ok THEN Fail ELSE
    LET reserved == ReadBytes(lastProcessedSeqNo.rest, 4) IN IF ~reserved.ok THEN Fail ELSE
    LET sendTimeEpochNanos == ReadBytes(reserved.rest, 8) IN IF ~sendTimeEpochNanos.ok THEN Fail ELSE
    LET blockLength == ReadBytes(sendTimeEpochNanos.rest, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET templateId == ReadUIntLE(blockLength.rest, 2) IN IF ~templateId.ok THEN Fail ELSE
    LET schemaId == ReadBytes(templateId.rest, 2) IN IF ~schemaId.ok THEN Fail ELSE
    LET version == ReadBytes(schemaId.rest, 2) IN IF ~version.ok THEN Fail ELSE
    LET payload == DecodePayload(templateId.value, version.rest) IN IF ~payload.ok THEN Fail ELSE
    LET padding == Ok(payload.rest, << >>) IN IF ~padding.ok THEN Fail ELSE
    IF padding.rest # << >> THEN Fail ELSE
    Ok([ protocolId         |-> protocolId.value,
         flags              |-> flags.value,
         sequenceNumber     |-> sequenceNumber.value,
         lastProcessedSeqNo |-> lastProcessedSeqNo.value,
         reserved           |-> reserved.value,
         sendTimeEpochNanos |-> sendTimeEpochNanos.value,
         blockLength        |-> blockLength.value,
         schemaId           |-> schemaId.value,
         version            |-> version.value,
         payload            |-> payload.value,
         padding            |-> padding.value ], beyond)

ZeroSbeMessage ==
    [ protocolId         |-> [i \in 1 .. 1 |-> 0],
      flags              |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber     |-> [i \in 1 .. 4 |-> 0],
      lastProcessedSeqNo |-> [i \in 1 .. 4 |-> 0],
      reserved           |-> [i \in 1 .. 4 |-> 0],
      sendTimeEpochNanos |-> [i \in 1 .. 8 |-> 0],
      blockLength        |-> [i \in 1 .. 2 |-> 0],
      schemaId           |-> [i \in 1 .. 2 |-> 0],
      version            |-> [i \in 1 .. 2 |-> 0],
      payload            |-> ZeroPayload,
      padding            |-> << >> ]

(* Sbe Message at zero, then each field in turn at the values it is checked at *)
CheckedSbeMessage ==
    { ZeroSbeMessage }
        \cup { [ZeroSbeMessage EXCEPT !.protocolId = one] : one \in Sample(1) }
        \cup { [ZeroSbeMessage EXCEPT !.flags = one] : one \in Sample(1) }
        \cup { [ZeroSbeMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroSbeMessage EXCEPT !.lastProcessedSeqNo = one] : one \in Sample(4) }
        \cup { [ZeroSbeMessage EXCEPT !.reserved = one] : one \in Sample(4) }
        \cup { [ZeroSbeMessage EXCEPT !.sendTimeEpochNanos = one] : one \in Sample(8) }
        \cup { [ZeroSbeMessage EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSbeMessage EXCEPT !.schemaId = one] : one \in Sample(2) }
        \cup { [ZeroSbeMessage EXCEPT !.version = one] : one \in Sample(2) }
        \cup { [ZeroSbeMessage EXCEPT !.payload = one] : one \in CheckedPayload }
        \cup { [ZeroSbeMessage EXCEPT !.padding = one] : one \in SampleBytes }

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
    { [ZeroSbeMessage EXCEPT !.payload = [tag |-> LogonMessageCode, body |-> ZeroLogonMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> LogonConfMessageCode, body |-> ZeroLogonConfMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> LogoutMessageCode, body |-> ZeroLogoutMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> LoggedOutMessageCode, body |-> ZeroLoggedOutMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> HeartbeatMessageCode, body |-> ZeroHeartbeatMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> TestRequestMessageCode, body |-> ZeroTestRequestMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> ResendRequestMessageCode, body |-> ZeroResendRequestMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> GapFillMessageCode, body |-> ZeroGapFillMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> RejectMessageCode, body |-> ZeroRejectMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ sbeMessage : SampleLists(OneSbeMessage) ]

EncodePacket(message) ==
    EncodeSbeMessageList(message.sbeMessage)

DecodePacket(bytes) ==
    LET sbeMessage == ReadSbeMessageAll(bytes) IN IF ~sbeMessage.ok THEN Fail ELSE
    Ok([ sbeMessage |-> sbeMessage.value ], sbeMessage.rest)

ZeroPacket ==
    [ sbeMessage |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.sbeMessage = one] : one \in SampleLists(OneSbeMessage) }

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

(* Every Logon Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogonMessage ==
    \A message \in CheckedLogonMessage :
        LET read == DecodeLogonMessage(EncodeLogonMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logon Conf Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogonConfMessage ==
    \A message \in CheckedLogonConfMessage :
        LET read == DecodeLogonConfMessage(EncodeLogonConfMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logout Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogoutMessage ==
    \A message \in CheckedLogoutMessage :
        LET read == DecodeLogoutMessage(EncodeLogoutMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logged Out Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoggedOutMessage ==
    \A message \in CheckedLoggedOutMessage :
        LET read == DecodeLoggedOutMessage(EncodeLoggedOutMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Heartbeat Message decodes back to what was encoded, and leaves nothing over *)
RoundTripHeartbeatMessage ==
    \A message \in CheckedHeartbeatMessage :
        LET read == DecodeHeartbeatMessage(EncodeHeartbeatMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Test Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTestRequestMessage ==
    \A message \in CheckedTestRequestMessage :
        LET read == DecodeTestRequestMessage(EncodeTestRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Resend Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripResendRequestMessage ==
    \A message \in CheckedResendRequestMessage :
        LET read == DecodeResendRequestMessage(EncodeResendRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Gap Fill Message decodes back to what was encoded, and leaves nothing over *)
RoundTripGapFillMessage ==
    \A message \in CheckedGapFillMessage :
        LET read == DecodeGapFillMessage(EncodeGapFillMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRejectMessage ==
    \A message \in CheckedRejectMessage :
        LET read == DecodeRejectMessage(EncodeRejectMessage(message))
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

(* Every Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripPacket ==
    \A message \in CheckedPacket :
        LET read == DecodePacket(EncodePacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Payload is selected by the Template Id it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Message Length is written from the bytes it frames *)
FramesSbeMessage ==
    \A message \in CheckedSbeMessage :
        LET bytes == EncodeSbeMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 3, 4)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
