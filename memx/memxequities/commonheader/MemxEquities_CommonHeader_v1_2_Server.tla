--------------- MODULE MemxEquities_CommonHeader_v1_2_Server ---------------
(***************************************************************************)
(* The Members Exchange Common Header v1.2                                 *)
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
(* Note: Server Data is framed by Message Length: the choice is read from  *)
(* that many bytes and must take them all.                                 *)
(*                                                                         *)
(* Note: Server Sbe Message is as wide as what is left of Sequenced        *)
(* Message: it is read as the bytes left of what its record was given,     *)
(* which the records above it keep those bytes back from.                  *)
(*                                                                         *)
(* Note: Sequenced Message is as wide as Message Length says, which is the *)
(* frame it is read from.                                                  *)
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
(* Login Accepted Message: 1 bytes                                         *)
(***************************************************************************)

LoginAcceptedMessage ==
    [ supportedRequestMode : Sample(1) ]

EncodeLoginAcceptedMessage(message) ==
    message.supportedRequestMode

DecodeLoginAcceptedMessage(bytes) ==
    LET supportedRequestMode == ReadBytes(bytes, 1) IN IF ~supportedRequestMode.ok THEN Fail ELSE
    Ok([ supportedRequestMode |-> supportedRequestMode.value ], supportedRequestMode.rest)

ZeroLoginAcceptedMessage ==
    [ supportedRequestMode |-> [i \in 1 .. 1 |-> 0] ]

(* Login Accepted Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginAcceptedMessage ==
    { ZeroLoginAcceptedMessage }
        \cup { [ZeroLoginAcceptedMessage EXCEPT !.supportedRequestMode = one] : one \in Sample(1) }

(***************************************************************************)
(* Login Rejected Message: 1 bytes                                         *)
(***************************************************************************)

LoginRejectedMessage ==
    [ loginRejectCode : Sample(1) ]

EncodeLoginRejectedMessage(message) ==
    message.loginRejectCode

DecodeLoginRejectedMessage(bytes) ==
    LET loginRejectCode == ReadBytes(bytes, 1) IN IF ~loginRejectCode.ok THEN Fail ELSE
    Ok([ loginRejectCode |-> loginRejectCode.value ], loginRejectCode.rest)

ZeroLoginRejectedMessage ==
    [ loginRejectCode |-> [i \in 1 .. 1 |-> 0] ]

(* Login Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginRejectedMessage ==
    { ZeroLoginRejectedMessage }
        \cup { [ZeroLoginRejectedMessage EXCEPT !.loginRejectCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Start Of Session Message: 8 bytes                                       *)
(***************************************************************************)

StartOfSessionMessage ==
    [ sessionId : Sample(8) ]

EncodeStartOfSessionMessage(message) ==
    message.sessionId

DecodeStartOfSessionMessage(bytes) ==
    LET sessionId == ReadBytes(bytes, 8) IN IF ~sessionId.ok THEN Fail ELSE
    Ok([ sessionId |-> sessionId.value ], sessionId.rest)

ZeroStartOfSessionMessage ==
    [ sessionId |-> [i \in 1 .. 8 |-> 0] ]

(* Start Of Session Message at zero, then each field in turn at the values it is checked at *)
CheckedStartOfSessionMessage ==
    { ZeroStartOfSessionMessage }
        \cup { [ZeroStartOfSessionMessage EXCEPT !.sessionId = one] : one \in Sample(8) }

(***************************************************************************)
(* Replay Begin Message: 12 bytes                                          *)
(***************************************************************************)

ReplayBeginMessage ==
    [ nextSequenceNumber  : Sample(8),
      pendingMessageCount : Sample(4) ]

EncodeReplayBeginMessage(message) ==
    message.nextSequenceNumber
        \o message.pendingMessageCount

DecodeReplayBeginMessage(bytes) ==
    LET nextSequenceNumber == ReadBytes(bytes, 8) IN IF ~nextSequenceNumber.ok THEN Fail ELSE
    LET pendingMessageCount == ReadBytes(nextSequenceNumber.rest, 4) IN IF ~pendingMessageCount.ok THEN Fail ELSE
    Ok([ nextSequenceNumber  |-> nextSequenceNumber.value,
         pendingMessageCount |-> pendingMessageCount.value ], pendingMessageCount.rest)

ZeroReplayBeginMessage ==
    [ nextSequenceNumber  |-> [i \in 1 .. 8 |-> 0],
      pendingMessageCount |-> [i \in 1 .. 4 |-> 0] ]

(* Replay Begin Message at zero, then each field in turn at the values it is checked at *)
CheckedReplayBeginMessage ==
    { ZeroReplayBeginMessage }
        \cup { [ZeroReplayBeginMessage EXCEPT !.nextSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroReplayBeginMessage EXCEPT !.pendingMessageCount = one] : one \in Sample(4) }

(***************************************************************************)
(* Replay Rejected Message: 1 bytes                                        *)
(***************************************************************************)

ReplayRejectedMessage ==
    [ replayRejectCode : Sample(1) ]

EncodeReplayRejectedMessage(message) ==
    message.replayRejectCode

DecodeReplayRejectedMessage(bytes) ==
    LET replayRejectCode == ReadBytes(bytes, 1) IN IF ~replayRejectCode.ok THEN Fail ELSE
    Ok([ replayRejectCode |-> replayRejectCode.value ], replayRejectCode.rest)

ZeroReplayRejectedMessage ==
    [ replayRejectCode |-> [i \in 1 .. 1 |-> 0] ]

(* Replay Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedReplayRejectedMessage ==
    { ZeroReplayRejectedMessage }
        \cup { [ZeroReplayRejectedMessage EXCEPT !.replayRejectCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Replay Complete Message: 8 bytes                                        *)
(***************************************************************************)

ReplayCompleteMessage ==
    [ messageCount : Sample(8) ]

EncodeReplayCompleteMessage(message) ==
    message.messageCount

DecodeReplayCompleteMessage(bytes) ==
    LET messageCount == ReadBytes(bytes, 8) IN IF ~messageCount.ok THEN Fail ELSE
    Ok([ messageCount |-> messageCount.value ], messageCount.rest)

ZeroReplayCompleteMessage ==
    [ messageCount |-> [i \in 1 .. 8 |-> 0] ]

(* Replay Complete Message at zero, then each field in turn at the values it is checked at *)
CheckedReplayCompleteMessage ==
    { ZeroReplayCompleteMessage }
        \cup { [ZeroReplayCompleteMessage EXCEPT !.messageCount = one] : one \in Sample(8) }

(***************************************************************************)
(* Stream Begin Message: 16 bytes                                          *)
(***************************************************************************)

StreamBeginMessage ==
    [ nextSequenceNumber : Sample(8),
      maxSequenceNumber  : Sample(8) ]

EncodeStreamBeginMessage(message) ==
    message.nextSequenceNumber
        \o message.maxSequenceNumber

DecodeStreamBeginMessage(bytes) ==
    LET nextSequenceNumber == ReadBytes(bytes, 8) IN IF ~nextSequenceNumber.ok THEN Fail ELSE
    LET maxSequenceNumber == ReadBytes(nextSequenceNumber.rest, 8) IN IF ~maxSequenceNumber.ok THEN Fail ELSE
    Ok([ nextSequenceNumber |-> nextSequenceNumber.value,
         maxSequenceNumber  |-> maxSequenceNumber.value ], maxSequenceNumber.rest)

ZeroStreamBeginMessage ==
    [ nextSequenceNumber |-> [i \in 1 .. 8 |-> 0],
      maxSequenceNumber  |-> [i \in 1 .. 8 |-> 0] ]

(* Stream Begin Message at zero, then each field in turn at the values it is checked at *)
CheckedStreamBeginMessage ==
    { ZeroStreamBeginMessage }
        \cup { [ZeroStreamBeginMessage EXCEPT !.nextSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroStreamBeginMessage EXCEPT !.maxSequenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Stream Rejected Message: 1 bytes                                        *)
(***************************************************************************)

StreamRejectedMessage ==
    [ streamRejectCode : Sample(1) ]

EncodeStreamRejectedMessage(message) ==
    message.streamRejectCode

DecodeStreamRejectedMessage(bytes) ==
    LET streamRejectCode == ReadBytes(bytes, 1) IN IF ~streamRejectCode.ok THEN Fail ELSE
    Ok([ streamRejectCode |-> streamRejectCode.value ], streamRejectCode.rest)

ZeroStreamRejectedMessage ==
    [ streamRejectCode |-> [i \in 1 .. 1 |-> 0] ]

(* Stream Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedStreamRejectedMessage ==
    { ZeroStreamRejectedMessage }
        \cup { [ZeroStreamRejectedMessage EXCEPT !.streamRejectCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Stream Complete Message: 8 bytes                                        *)
(***************************************************************************)

StreamCompleteMessage ==
    [ totalSequenceCount : Sample(8) ]

EncodeStreamCompleteMessage(message) ==
    message.totalSequenceCount

DecodeStreamCompleteMessage(bytes) ==
    LET totalSequenceCount == ReadBytes(bytes, 8) IN IF ~totalSequenceCount.ok THEN Fail ELSE
    Ok([ totalSequenceCount |-> totalSequenceCount.value ], totalSequenceCount.rest)

ZeroStreamCompleteMessage ==
    [ totalSequenceCount |-> [i \in 1 .. 8 |-> 0] ]

(* Stream Complete Message at zero, then each field in turn at the values it is checked at *)
CheckedStreamCompleteMessage ==
    { ZeroStreamCompleteMessage }
        \cup { [ZeroStreamCompleteMessage EXCEPT !.totalSequenceCount = one] : one \in Sample(8) }

(***************************************************************************)
(* Sequenced Message                                                       *)
(***************************************************************************)

SequencedMessage ==
    [ serverSbeMessage : SampleBytes ]

EncodeSequencedMessage(message) ==
    message.serverSbeMessage

DecodeSequencedMessage(bytes) ==
    LET serverSbeMessage == Ok(bytes, << >>) IN IF ~serverSbeMessage.ok THEN Fail ELSE
    Ok([ serverSbeMessage |-> serverSbeMessage.value ], serverSbeMessage.rest)

ZeroSequencedMessage ==
    [ serverSbeMessage |-> << >> ]

(* Sequenced Message at zero, then each field in turn at the values it is checked at *)
CheckedSequencedMessage ==
    { ZeroSequencedMessage }
        \cup { [ZeroSequencedMessage EXCEPT !.serverSbeMessage = one] : one \in SampleBytes }

(***************************************************************************)
(* Server Data, selected by Message Type                                   *)
(***************************************************************************)

LoginAcceptedMessageCode == 1  \* 0x01
LoginRejectedMessageCode == 2  \* 0x02
StartOfSessionMessageCode == 3  \* 0x03
ReplayBeginMessageCode == 5  \* 0x05
ReplayRejectedMessageCode == 6  \* 0x06
ReplayCompleteMessageCode == 7  \* 0x07
StreamBeginMessageCode == 8  \* 0x08
StreamRejectedMessageCode == 9  \* 0x09
StreamCompleteMessageCode == 10  \* 0x0a
SequencedMessageCode == 11  \* 0x0b

ServerData ==
    [ tag : {LoginAcceptedMessageCode}, body : LoginAcceptedMessage ]
        \cup [ tag : {LoginRejectedMessageCode}, body : LoginRejectedMessage ]
        \cup [ tag : {StartOfSessionMessageCode}, body : StartOfSessionMessage ]
        \cup [ tag : {ReplayBeginMessageCode}, body : ReplayBeginMessage ]
        \cup [ tag : {ReplayRejectedMessageCode}, body : ReplayRejectedMessage ]
        \cup [ tag : {ReplayCompleteMessageCode}, body : ReplayCompleteMessage ]
        \cup [ tag : {StreamBeginMessageCode}, body : StreamBeginMessage ]
        \cup [ tag : {StreamRejectedMessageCode}, body : StreamRejectedMessage ]
        \cup [ tag : {StreamCompleteMessageCode}, body : StreamCompleteMessage ]
        \cup [ tag : {SequencedMessageCode}, body : SequencedMessage ]

EncodeServerData(message) ==
    CASE message.tag = LoginAcceptedMessageCode -> EncodeLoginAcceptedMessage(message.body)
      [] message.tag = LoginRejectedMessageCode -> EncodeLoginRejectedMessage(message.body)
      [] message.tag = StartOfSessionMessageCode -> EncodeStartOfSessionMessage(message.body)
      [] message.tag = ReplayBeginMessageCode -> EncodeReplayBeginMessage(message.body)
      [] message.tag = ReplayRejectedMessageCode -> EncodeReplayRejectedMessage(message.body)
      [] message.tag = ReplayCompleteMessageCode -> EncodeReplayCompleteMessage(message.body)
      [] message.tag = StreamBeginMessageCode -> EncodeStreamBeginMessage(message.body)
      [] message.tag = StreamRejectedMessageCode -> EncodeStreamRejectedMessage(message.body)
      [] message.tag = StreamCompleteMessageCode -> EncodeStreamCompleteMessage(message.body)
      [] message.tag = SequencedMessageCode -> EncodeSequencedMessage(message.body)

DecodeServerData(tag, bytes) ==
    LET read ==
            CASE tag = LoginAcceptedMessageCode -> DecodeLoginAcceptedMessage(bytes)
              [] tag = LoginRejectedMessageCode -> DecodeLoginRejectedMessage(bytes)
              [] tag = StartOfSessionMessageCode -> DecodeStartOfSessionMessage(bytes)
              [] tag = ReplayBeginMessageCode -> DecodeReplayBeginMessage(bytes)
              [] tag = ReplayRejectedMessageCode -> DecodeReplayRejectedMessage(bytes)
              [] tag = ReplayCompleteMessageCode -> DecodeReplayCompleteMessage(bytes)
              [] tag = StreamBeginMessageCode -> DecodeStreamBeginMessage(bytes)
              [] tag = StreamRejectedMessageCode -> DecodeStreamRejectedMessage(bytes)
              [] tag = StreamCompleteMessageCode -> DecodeStreamCompleteMessage(bytes)
              [] tag = SequencedMessageCode -> DecodeSequencedMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroServerData == [tag |-> LoginAcceptedMessageCode, body |-> ZeroLoginAcceptedMessage]

(* Each Server Data in turn, at the values the message it names is checked at *)
CheckedServerData ==
    { [tag |-> LoginAcceptedMessageCode, body |-> one] : one \in CheckedLoginAcceptedMessage }
        \cup { [tag |-> LoginRejectedMessageCode, body |-> one] : one \in CheckedLoginRejectedMessage }
        \cup { [tag |-> StartOfSessionMessageCode, body |-> one] : one \in CheckedStartOfSessionMessage }
        \cup { [tag |-> ReplayBeginMessageCode, body |-> one] : one \in CheckedReplayBeginMessage }
        \cup { [tag |-> ReplayRejectedMessageCode, body |-> one] : one \in CheckedReplayRejectedMessage }
        \cup { [tag |-> ReplayCompleteMessageCode, body |-> one] : one \in CheckedReplayCompleteMessage }
        \cup { [tag |-> StreamBeginMessageCode, body |-> one] : one \in CheckedStreamBeginMessage }
        \cup { [tag |-> StreamRejectedMessageCode, body |-> one] : one \in CheckedStreamRejectedMessage }
        \cup { [tag |-> StreamCompleteMessageCode, body |-> one] : one \in CheckedStreamCompleteMessage }
        \cup { [tag |-> SequencedMessageCode, body |-> one] : one \in CheckedSequencedMessage }

(***************************************************************************)
(* Server Packet                                                           *)
(***************************************************************************)

ServerPacket ==
    [ serverData : ServerData ]

EncodeServerPacket(message) ==
    EncodeUIntBE(message.serverData.tag, 1)
        \o EncodeUIntBE(Len(EncodeServerData(message.serverData)), 2)
        \o EncodeServerData(message.serverData)

DecodeServerPacket(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET messageLength == ReadUIntBE(messageType.rest, 2) IN IF ~messageLength.ok THEN Fail ELSE
    LET serverDataSize == messageLength.value IN
    IF serverDataSize < 0 \/ Len(messageLength.rest) < serverDataSize THEN Fail ELSE
    LET serverDataFramed == SubSeq(messageLength.rest, 1, serverDataSize)
        serverDataBeyond == SubSeq(messageLength.rest, serverDataSize + 1, Len(messageLength.rest))
        serverData == DecodeServerData(messageType.value, serverDataFramed)
    IN  IF ~serverData.ok \/ serverData.rest # << >> THEN Fail ELSE
    Ok([ serverData |-> serverData.value ], serverDataBeyond)

ZeroServerPacket ==
    [ serverData |-> ZeroServerData ]

(* Server Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerPacket ==
    { ZeroServerPacket }
        \cup { [ZeroServerPacket EXCEPT !.serverData = one] : one \in CheckedServerData }

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

(* Every Login Accepted Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginAcceptedMessage ==
    \A message \in CheckedLoginAcceptedMessage :
        LET read == DecodeLoginAcceptedMessage(EncodeLoginAcceptedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRejectedMessage ==
    \A message \in CheckedLoginRejectedMessage :
        LET read == DecodeLoginRejectedMessage(EncodeLoginRejectedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Start Of Session Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStartOfSessionMessage ==
    \A message \in CheckedStartOfSessionMessage :
        LET read == DecodeStartOfSessionMessage(EncodeStartOfSessionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Replay Begin Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReplayBeginMessage ==
    \A message \in CheckedReplayBeginMessage :
        LET read == DecodeReplayBeginMessage(EncodeReplayBeginMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Replay Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReplayRejectedMessage ==
    \A message \in CheckedReplayRejectedMessage :
        LET read == DecodeReplayRejectedMessage(EncodeReplayRejectedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Replay Complete Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReplayCompleteMessage ==
    \A message \in CheckedReplayCompleteMessage :
        LET read == DecodeReplayCompleteMessage(EncodeReplayCompleteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stream Begin Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStreamBeginMessage ==
    \A message \in CheckedStreamBeginMessage :
        LET read == DecodeStreamBeginMessage(EncodeStreamBeginMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stream Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStreamRejectedMessage ==
    \A message \in CheckedStreamRejectedMessage :
        LET read == DecodeStreamRejectedMessage(EncodeStreamRejectedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stream Complete Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStreamCompleteMessage ==
    \A message \in CheckedStreamCompleteMessage :
        LET read == DecodeStreamCompleteMessage(EncodeStreamCompleteMessage(message))
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

(* Every Server Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripServerPacket ==
    \A message \in CheckedServerPacket :
        LET read == DecodeServerPacket(EncodeServerPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Server Data is selected by the Message Type it is written under *)
SelectsServerData ==
    \A message \in CheckedServerData :
        LET sent == EncodeServerData(message)
            read == DecodeServerData(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
