------------- MODULE Tsx_QuantumFeedLevel1Recovery_v2_6_Client -------------
(***************************************************************************)
(* TMX Group Quantum Feed Level 1 Recovery v2.6                            *)
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
(* Note: Client Body is chosen by the Msg Type each of its messages begins *)
(* with: those 1 bytes are read at offset 2 before one is picked, and each *)
(* message states its own.                                                 *)
(*                                                                         *)
(* Note: Admin Body closes the bytes Msg Length frames, so it is read to   *)
(* the end of them rather than from Num Body, which this record does not   *)
(* read.                                                                   *)
(*                                                                         *)
(* Note: Replay Range closes the bytes Msg Length frames, so it is read to *)
(* the end of them rather than from Num Body, which this record does not   *)
(* read.                                                                   *)
(*                                                                         *)
(* Note: Client Body and what follows it are read only when the message    *)
(* runs on past what precedes them.                                        *)
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

(* The integer a text protocol writes as the characters of itself: a count of one is *)
(* the character "1", which is the byte 49. Read by its digits, and written back *)
(* zero filled to the width the field states, which is how such a field is filled. *)
Digit == 48 .. 57

RECURSIVE DecodeDigits(_)
DecodeDigits(bytes) ==
    IF bytes = << >>
    THEN 0
    ELSE DecodeDigits(SubSeq(bytes, 1, Len(bytes) - 1)) * 10 + (bytes[Len(bytes)] - 48)

RECURSIVE EncodeDigits(_, _)
EncodeDigits(value, width) ==
    IF width = 0
    THEN << >>
    ELSE EncodeDigits(value \div 10, width - 1) \o <<48 + (value % 10)>>

(* A field written as digits that holds anything else is no number, so it is not read: *)
(* the value would not be what the bytes say, and would not write back as them. *)
ReadDigits(bytes, width) ==
    IF Len(bytes) < width \/ \E i \in 1 .. width : bytes[i] \notin Digit
    THEN Fail
    ELSE Ok(DecodeDigits(SubSeq(bytes, 1, width)), SubSeq(bytes, width + 1, Len(bytes)))

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
(* Admin Body: 8 bytes                                                     *)
(***************************************************************************)

AdminBody ==
    [ sourceId  : Sample(1),
      streamId  : Sample(2),
      sequence0 : Sample(1),
      sequence1 : Sample(4) ]

EncodeAdminBody(message) ==
    message.sourceId
        \o message.streamId
        \o message.sequence0
        \o message.sequence1

DecodeAdminBody(bytes) ==
    LET sourceId == ReadBytes(bytes, 1) IN IF ~sourceId.ok THEN Fail ELSE
    LET streamId == ReadBytes(sourceId.rest, 2) IN IF ~streamId.ok THEN Fail ELSE
    LET sequence0 == ReadBytes(streamId.rest, 1) IN IF ~sequence0.ok THEN Fail ELSE
    LET sequence1 == ReadBytes(sequence0.rest, 4) IN IF ~sequence1.ok THEN Fail ELSE
    Ok([ sourceId  |-> sourceId.value,
         streamId  |-> streamId.value,
         sequence0 |-> sequence0.value,
         sequence1 |-> sequence1.value ], sequence1.rest)

ZeroAdminBody ==
    [ sourceId  |-> [i \in 1 .. 1 |-> 0],
      streamId  |-> [i \in 1 .. 2 |-> 0],
      sequence0 |-> [i \in 1 .. 1 |-> 0],
      sequence1 |-> [i \in 1 .. 4 |-> 0] ]

(* Admin Body at zero, then each field in turn at the values it is checked at *)
CheckedAdminBody ==
    { ZeroAdminBody }
        \cup { [ZeroAdminBody EXCEPT !.sourceId = one] : one \in Sample(1) }
        \cup { [ZeroAdminBody EXCEPT !.streamId = one] : one \in Sample(2) }
        \cup { [ZeroAdminBody EXCEPT !.sequence0 = one] : one \in Sample(1) }
        \cup { [ZeroAdminBody EXCEPT !.sequence1 = one] : one \in Sample(4) }

(* A run of Admin Body, written one after another *)
RECURSIVE EncodeAdminBodyList(_)
EncodeAdminBodyList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeAdminBody(Head(messages)) \o EncodeAdminBodyList(Tail(messages))

(* As many Admin Body as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadAdminBodyAll(_)
ReadAdminBodyAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeAdminBody(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadAdminBodyAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Admin Body of each kind, for the lists that carry them *)
OneAdminBody == { ZeroAdminBody }

(***************************************************************************)
(* Heartbeat Body, framed by Msg Length                                    *)
(***************************************************************************)

HeartbeatBody ==
    [ adminId    : Sample(1),
      hbInterval : Sample(2),
      adminBody  : SampleLists(OneAdminBody) ]

EncodeHeartbeatBodyBody(message) ==
    EncodeUIntBE(48, 1)
        \o message.adminId
        \o message.hbInterval
        \o EncodeAdminBodyList(message.adminBody)

(* Msg Length counts the bytes it frames, so it is written from them *)
EncodeHeartbeatBody(message) ==
    LET body == EncodeHeartbeatBodyBody(message)
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeHeartbeatBodyBody(bytes) ==
    LET msgType == ReadUIntBE(bytes, 1) IN IF ~msgType.ok THEN Fail ELSE
    LET adminId == ReadBytes(msgType.rest, 1) IN IF ~adminId.ok THEN Fail ELSE
    LET hbInterval == ReadBytes(adminId.rest, 2) IN IF ~hbInterval.ok THEN Fail ELSE
    LET adminBody == ReadAdminBodyAll(hbInterval.rest) IN IF ~adminBody.ok THEN Fail ELSE
    Ok([ adminId    |-> adminId.value,
         hbInterval |-> hbInterval.value,
         adminBody  |-> adminBody.value ], adminBody.rest)

DecodeHeartbeatBody(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeHeartbeatBodyBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroHeartbeatBody ==
    [ adminId    |-> [i \in 1 .. 1 |-> 0],
      hbInterval |-> [i \in 1 .. 2 |-> 0],
      adminBody  |-> << >> ]

(* Heartbeat Body at zero, then each field in turn at the values it is checked at *)
CheckedHeartbeatBody ==
    { ZeroHeartbeatBody }
        \cup { [ZeroHeartbeatBody EXCEPT !.adminId = one] : one \in Sample(1) }
        \cup { [ZeroHeartbeatBody EXCEPT !.hbInterval = one] : one \in Sample(2) }
        \cup { [ZeroHeartbeatBody EXCEPT !.adminBody = one] : one \in SampleLists(OneAdminBody) }

(***************************************************************************)
(* Login Request, framed by Msg Length                                     *)
(***************************************************************************)

LoginRequest ==
    [ adminId       : Sample(1),
      hbInterval    : Sample(2),
      replayWinSize : Sample(2),
      replayWinNum  : Sample(2),
      credits       : Sample(2) ]

EncodeLoginRequestBody(message) ==
    EncodeUIntBE(49, 1)
        \o message.adminId
        \o message.hbInterval
        \o message.replayWinSize
        \o message.replayWinNum
        \o message.credits

(* Msg Length counts the bytes it frames, so it is written from them *)
EncodeLoginRequest(message) ==
    LET body == EncodeLoginRequestBody(message)
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeLoginRequestBody(bytes) ==
    LET msgType == ReadUIntBE(bytes, 1) IN IF ~msgType.ok THEN Fail ELSE
    LET adminId == ReadBytes(msgType.rest, 1) IN IF ~adminId.ok THEN Fail ELSE
    LET hbInterval == ReadBytes(adminId.rest, 2) IN IF ~hbInterval.ok THEN Fail ELSE
    LET replayWinSize == ReadBytes(hbInterval.rest, 2) IN IF ~replayWinSize.ok THEN Fail ELSE
    LET replayWinNum == ReadBytes(replayWinSize.rest, 2) IN IF ~replayWinNum.ok THEN Fail ELSE
    LET credits == ReadBytes(replayWinNum.rest, 2) IN IF ~credits.ok THEN Fail ELSE
    Ok([ adminId       |-> adminId.value,
         hbInterval    |-> hbInterval.value,
         replayWinSize |-> replayWinSize.value,
         replayWinNum  |-> replayWinNum.value,
         credits       |-> credits.value ], credits.rest)

DecodeLoginRequest(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeLoginRequestBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroLoginRequest ==
    [ adminId       |-> [i \in 1 .. 1 |-> 0],
      hbInterval    |-> [i \in 1 .. 2 |-> 0],
      replayWinSize |-> [i \in 1 .. 2 |-> 0],
      replayWinNum  |-> [i \in 1 .. 2 |-> 0],
      credits       |-> [i \in 1 .. 2 |-> 0] ]

(* Login Request at zero, then each field in turn at the values it is checked at *)
CheckedLoginRequest ==
    { ZeroLoginRequest }
        \cup { [ZeroLoginRequest EXCEPT !.adminId = one] : one \in Sample(1) }
        \cup { [ZeroLoginRequest EXCEPT !.hbInterval = one] : one \in Sample(2) }
        \cup { [ZeroLoginRequest EXCEPT !.replayWinSize = one] : one \in Sample(2) }
        \cup { [ZeroLoginRequest EXCEPT !.replayWinNum = one] : one \in Sample(2) }
        \cup { [ZeroLoginRequest EXCEPT !.credits = one] : one \in Sample(2) }

(***************************************************************************)
(* Logout, framed by Msg Length                                            *)
(***************************************************************************)

Logout ==
    [ adminId : Sample(1) ]

EncodeLogoutBody(message) ==
    EncodeUIntBE(51, 1)
        \o message.adminId

(* Msg Length counts the bytes it frames, so it is written from them *)
EncodeLogout(message) ==
    LET body == EncodeLogoutBody(message)
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeLogoutBody(bytes) ==
    LET msgType == ReadUIntBE(bytes, 1) IN IF ~msgType.ok THEN Fail ELSE
    LET adminId == ReadBytes(msgType.rest, 1) IN IF ~adminId.ok THEN Fail ELSE
    Ok([ adminId |-> adminId.value ], adminId.rest)

DecodeLogout(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeLogoutBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroLogout ==
    [ adminId |-> [i \in 1 .. 1 |-> 0] ]

(* Logout at zero, then each field in turn at the values it is checked at *)
CheckedLogout ==
    { ZeroLogout }
        \cup { [ZeroLogout EXCEPT !.adminId = one] : one \in Sample(1) }

(***************************************************************************)
(* Replay Range: 12 bytes                                                  *)
(***************************************************************************)

ReplayRange ==
    [ sourceId       : Sample(1),
      streamId       : Sample(2),
      sequence0      : Sample(1),
      sequence1Start : Sample(4),
      sequence1End   : Sample(4) ]

EncodeReplayRange(message) ==
    message.sourceId
        \o message.streamId
        \o message.sequence0
        \o message.sequence1Start
        \o message.sequence1End

DecodeReplayRange(bytes) ==
    LET sourceId == ReadBytes(bytes, 1) IN IF ~sourceId.ok THEN Fail ELSE
    LET streamId == ReadBytes(sourceId.rest, 2) IN IF ~streamId.ok THEN Fail ELSE
    LET sequence0 == ReadBytes(streamId.rest, 1) IN IF ~sequence0.ok THEN Fail ELSE
    LET sequence1Start == ReadBytes(sequence0.rest, 4) IN IF ~sequence1Start.ok THEN Fail ELSE
    LET sequence1End == ReadBytes(sequence1Start.rest, 4) IN IF ~sequence1End.ok THEN Fail ELSE
    Ok([ sourceId       |-> sourceId.value,
         streamId       |-> streamId.value,
         sequence0      |-> sequence0.value,
         sequence1Start |-> sequence1Start.value,
         sequence1End   |-> sequence1End.value ], sequence1End.rest)

ZeroReplayRange ==
    [ sourceId       |-> [i \in 1 .. 1 |-> 0],
      streamId       |-> [i \in 1 .. 2 |-> 0],
      sequence0      |-> [i \in 1 .. 1 |-> 0],
      sequence1Start |-> [i \in 1 .. 4 |-> 0],
      sequence1End   |-> [i \in 1 .. 4 |-> 0] ]

(* Replay Range at zero, then each field in turn at the values it is checked at *)
CheckedReplayRange ==
    { ZeroReplayRange }
        \cup { [ZeroReplayRange EXCEPT !.sourceId = one] : one \in Sample(1) }
        \cup { [ZeroReplayRange EXCEPT !.streamId = one] : one \in Sample(2) }
        \cup { [ZeroReplayRange EXCEPT !.sequence0 = one] : one \in Sample(1) }
        \cup { [ZeroReplayRange EXCEPT !.sequence1Start = one] : one \in Sample(4) }
        \cup { [ZeroReplayRange EXCEPT !.sequence1End = one] : one \in Sample(4) }

(* A run of Replay Range, written one after another *)
RECURSIVE EncodeReplayRangeList(_)
EncodeReplayRangeList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeReplayRange(Head(messages)) \o EncodeReplayRangeList(Tail(messages))

(* As many Replay Range as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadReplayRangeAll(_)
ReadReplayRangeAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeReplayRange(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadReplayRangeAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Replay Range of each kind, for the lists that carry them *)
OneReplayRange == { ZeroReplayRange }

(***************************************************************************)
(* Replay Request, framed by Msg Length                                    *)
(***************************************************************************)

ReplayRequest ==
    [ adminId         : Sample(1),
      replaySessionId : Sample(4),
      replayRange     : SampleLists(OneReplayRange) ]

EncodeReplayRequestBody(message) ==
    EncodeUIntBE(53, 1)
        \o message.adminId
        \o message.replaySessionId
        \o EncodeReplayRangeList(message.replayRange)

(* Msg Length counts the bytes it frames, so it is written from them *)
EncodeReplayRequest(message) ==
    LET body == EncodeReplayRequestBody(message)
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeReplayRequestBody(bytes) ==
    LET msgType == ReadUIntBE(bytes, 1) IN IF ~msgType.ok THEN Fail ELSE
    LET adminId == ReadBytes(msgType.rest, 1) IN IF ~adminId.ok THEN Fail ELSE
    LET replaySessionId == ReadBytes(adminId.rest, 4) IN IF ~replaySessionId.ok THEN Fail ELSE
    LET replayRange == ReadReplayRangeAll(replaySessionId.rest) IN IF ~replayRange.ok THEN Fail ELSE
    Ok([ adminId         |-> adminId.value,
         replaySessionId |-> replaySessionId.value,
         replayRange     |-> replayRange.value ], replayRange.rest)

DecodeReplayRequest(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeReplayRequestBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroReplayRequest ==
    [ adminId         |-> [i \in 1 .. 1 |-> 0],
      replaySessionId |-> [i \in 1 .. 4 |-> 0],
      replayRange     |-> << >> ]

(* Replay Request at zero, then each field in turn at the values it is checked at *)
CheckedReplayRequest ==
    { ZeroReplayRequest }
        \cup { [ZeroReplayRequest EXCEPT !.adminId = one] : one \in Sample(1) }
        \cup { [ZeroReplayRequest EXCEPT !.replaySessionId = one] : one \in Sample(4) }
        \cup { [ZeroReplayRequest EXCEPT !.replayRange = one] : one \in SampleLists(OneReplayRange) }

(***************************************************************************)
(* Client Body, selected by Msg Type                                       *)
(***************************************************************************)

HeartbeatBodyCode == 48  \* "0"
LoginRequestCode == 49  \* "1"
LogoutCode == 51  \* "3"
ReplayRequestCode == 53  \* "5"

ClientBody ==
    [ tag : {HeartbeatBodyCode}, body : HeartbeatBody ]
        \cup [ tag : {LoginRequestCode}, body : LoginRequest ]
        \cup [ tag : {LogoutCode}, body : Logout ]
        \cup [ tag : {ReplayRequestCode}, body : ReplayRequest ]

EncodeClientBody(message) ==
    CASE message.tag = HeartbeatBodyCode -> EncodeHeartbeatBody(message.body)
      [] message.tag = LoginRequestCode -> EncodeLoginRequest(message.body)
      [] message.tag = LogoutCode -> EncodeLogout(message.body)
      [] message.tag = ReplayRequestCode -> EncodeReplayRequest(message.body)

DecodeClientBody(tag, bytes) ==
    LET read ==
            CASE tag = HeartbeatBodyCode -> DecodeHeartbeatBody(bytes)
              [] tag = LoginRequestCode -> DecodeLoginRequest(bytes)
              [] tag = LogoutCode -> DecodeLogout(bytes)
              [] tag = ReplayRequestCode -> DecodeReplayRequest(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroClientBody == [tag |-> HeartbeatBodyCode, body |-> ZeroHeartbeatBody]

(* Each Client Body in turn, at the values the message it names is checked at *)
CheckedClientBody ==
    { [tag |-> HeartbeatBodyCode, body |-> one] : one \in CheckedHeartbeatBody }
        \cup { [tag |-> LoginRequestCode, body |-> one] : one \in CheckedLoginRequest }
        \cup { [tag |-> LogoutCode, body |-> one] : one \in CheckedLogout }
        \cup { [tag |-> ReplayRequestCode, body |-> one] : one \in CheckedReplayRequest }

(***************************************************************************)
(* Client Frame                                                            *)
(***************************************************************************)

ClientFrameTail ==
    [ clientBody : ClientBody ]

EncodeClientFrameTail(message) ==
    EncodeClientBody(message.clientBody)

DecodeClientFrameTail(bytes) ==
    IF Len(bytes) < 3 THEN Fail ELSE
    LET clientBody == DecodeClientBody(DecodeUIntBE(SubSeq(bytes, 3, 3)), bytes) IN IF ~clientBody.ok THEN Fail ELSE
    Ok([ clientBody |-> clientBody.value ], clientBody.rest)

ZeroClientFrameTail ==
    [ clientBody |-> ZeroClientBody ]

(* Client Frame at zero, then each field in turn at the values it is checked at *)
CheckedClientFrameTail ==
    { ZeroClientFrameTail }
        \cup { [ZeroClientFrameTail EXCEPT !.clientBody = one] : one \in CheckedClientBody }

(* Client Frame runs on only when bytes remain, so it is there or it is not *)
WithoutClientFrameTail == [there |-> FALSE, value |-> ZeroClientFrameTail]

MaybeClientFrameTail ==
    { WithoutClientFrameTail }
        \cup { [there |-> TRUE, value |-> one] : one \in CheckedClientFrameTail }

ReadClientFrameTailMaybe(bytes) ==
    IF bytes = << >> THEN Ok(WithoutClientFrameTail, << >>)
    ELSE LET one == DecodeClientFrameTail(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE Ok([there |-> TRUE, value |-> one.value], one.rest)

(***************************************************************************)
(* Client Frame, framed by Message Length                                  *)
(***************************************************************************)

ClientFrame ==
    [ startOfFrame       : Sample(1),
      protocolName       : Sample(1),
      protocolVersion    : Sample(1),
      sessionId          : Sample(4),
      ackRequiredPossDup : Sample(1),
      numBody            : 0 .. 255,
      clientFrameTail    : MaybeClientFrameTail ]

EncodeClientFrameBody(message) ==
    message.sessionId
        \o message.ackRequiredPossDup
        \o EncodeUIntBE(message.numBody, 1)
        \o IF message.clientFrameTail.there THEN EncodeClientFrameTail(message.clientFrameTail.value) ELSE << >>

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeClientFrame(message) ==
    LET body == EncodeClientFrameBody(message)
    IN  message.startOfFrame \o message.protocolName \o message.protocolVersion \o EncodeUIntLE(Len(body), 2) \o body

DecodeClientFrame(bytes) ==
    LET startOfFrame == ReadBytes(bytes, 1) IN IF ~startOfFrame.ok THEN Fail ELSE
    LET protocolName == ReadBytes(startOfFrame.rest, 1) IN IF ~protocolName.ok THEN Fail ELSE
    LET protocolVersion == ReadBytes(protocolName.rest, 1) IN IF ~protocolVersion.ok THEN Fail ELSE
    LET length == ReadUIntLE(protocolVersion.rest, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
    IN
    LET sessionId == ReadBytes(framed, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET ackRequiredPossDup == ReadBytes(sessionId.rest, 1) IN IF ~ackRequiredPossDup.ok THEN Fail ELSE
    LET numBody == ReadUIntBE(ackRequiredPossDup.rest, 1) IN IF ~numBody.ok THEN Fail ELSE
    LET clientFrameTail == ReadClientFrameTailMaybe(numBody.rest) IN IF ~clientFrameTail.ok THEN Fail ELSE
    IF clientFrameTail.rest # << >> THEN Fail ELSE
    Ok([ startOfFrame       |-> startOfFrame.value,
         protocolName       |-> protocolName.value,
         protocolVersion    |-> protocolVersion.value,
         sessionId          |-> sessionId.value,
         ackRequiredPossDup |-> ackRequiredPossDup.value,
         numBody            |-> numBody.value,
         clientFrameTail    |-> clientFrameTail.value ], beyond)

ZeroClientFrame ==
    [ startOfFrame       |-> [i \in 1 .. 1 |-> 0],
      protocolName       |-> [i \in 1 .. 1 |-> 0],
      protocolVersion    |-> [i \in 1 .. 1 |-> 0],
      sessionId          |-> [i \in 1 .. 4 |-> 0],
      ackRequiredPossDup |-> [i \in 1 .. 1 |-> 0],
      numBody            |-> 0,
      clientFrameTail    |-> WithoutClientFrameTail ]

(* Client Frame at zero, then each field in turn at the values it is checked at *)
CheckedClientFrame ==
    { ZeroClientFrame }
        \cup { [ZeroClientFrame EXCEPT !.startOfFrame = one] : one \in Sample(1) }
        \cup { [ZeroClientFrame EXCEPT !.protocolName = one] : one \in Sample(1) }
        \cup { [ZeroClientFrame EXCEPT !.protocolVersion = one] : one \in Sample(1) }
        \cup { [ZeroClientFrame EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroClientFrame EXCEPT !.ackRequiredPossDup = one] : one \in Sample(1) }
        \cup { [ZeroClientFrame EXCEPT !.numBody = one] : one \in {0, 1, 255} }
        \cup { [ZeroClientFrame EXCEPT !.clientFrameTail = one] : one \in MaybeClientFrameTail }

(* A run of Client Frame, written one after another *)
RECURSIVE EncodeClientFrameList(_)
EncodeClientFrameList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeClientFrame(Head(messages)) \o EncodeClientFrameList(Tail(messages))

(* As many Client Frame as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadClientFrameAll(_)
ReadClientFrameAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeClientFrame(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadClientFrameAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Client Frame of each kind, for the lists that carry them *)
OneClientFrame == { ZeroClientFrame }

(***************************************************************************)
(* Client Packet                                                           *)
(***************************************************************************)

ClientPacket ==
    [ clientFrame : SampleLists(OneClientFrame) ]

EncodeClientPacket(message) ==
    EncodeClientFrameList(message.clientFrame)

DecodeClientPacket(bytes) ==
    LET clientFrame == ReadClientFrameAll(bytes) IN IF ~clientFrame.ok THEN Fail ELSE
    Ok([ clientFrame |-> clientFrame.value ], clientFrame.rest)

ZeroClientPacket ==
    [ clientFrame |-> << >> ]

(* Client Packet at zero, then each field in turn at the values it is checked at *)
CheckedClientPacket ==
    { ZeroClientPacket }
        \cup { [ZeroClientPacket EXCEPT !.clientFrame = one] : one \in SampleLists(OneClientFrame) }

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

(* Every Admin Body decodes back to what was encoded, and leaves nothing over *)
RoundTripAdminBody ==
    \A message \in CheckedAdminBody :
        LET read == DecodeAdminBody(EncodeAdminBody(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Heartbeat Body decodes back to what was encoded, and leaves nothing over *)
RoundTripHeartbeatBody ==
    \A message \in CheckedHeartbeatBody :
        LET read == DecodeHeartbeatBody(EncodeHeartbeatBody(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Request decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRequest ==
    \A message \in CheckedLoginRequest :
        LET read == DecodeLoginRequest(EncodeLoginRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logout decodes back to what was encoded, and leaves nothing over *)
RoundTripLogout ==
    \A message \in CheckedLogout :
        LET read == DecodeLogout(EncodeLogout(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Replay Range decodes back to what was encoded, and leaves nothing over *)
RoundTripReplayRange ==
    \A message \in CheckedReplayRange :
        LET read == DecodeReplayRange(EncodeReplayRange(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Replay Request decodes back to what was encoded, and leaves nothing over *)
RoundTripReplayRequest ==
    \A message \in CheckedReplayRequest :
        LET read == DecodeReplayRequest(EncodeReplayRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client Frame decodes back to what was encoded, and leaves nothing over *)
RoundTripClientFrameTail ==
    \A message \in CheckedClientFrameTail :
        LET read == DecodeClientFrameTail(EncodeClientFrameTail(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client Frame decodes back to what was encoded, and leaves nothing over *)
RoundTripClientFrame ==
    \A message \in CheckedClientFrame :
        LET read == DecodeClientFrame(EncodeClientFrame(message))
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

(* A Client Body written out and then looked at is selected by the Msg Type it wrote *)
SelectsClientBody ==
    \A message \in CheckedClientBody :
        LET sent == EncodeClientBody(message)
            read == DecodeClientBody(DecodeUIntBE(SubSeq(sent, 3, 3)), sent)
        IN  Len(sent) >= 3 /\ read.ok /\ read.value.tag = message.tag

(* Msg Length is written from the bytes it frames *)
FramesHeartbeatBody ==
    \A message \in CheckedHeartbeatBody :
        LET bytes == EncodeHeartbeatBody(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

(* Msg Length is written from the bytes it frames *)
FramesLoginRequest ==
    \A message \in CheckedLoginRequest :
        LET bytes == EncodeLoginRequest(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

(* Msg Length is written from the bytes it frames *)
FramesLogout ==
    \A message \in CheckedLogout :
        LET bytes == EncodeLogout(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

(* Msg Length is written from the bytes it frames *)
FramesReplayRequest ==
    \A message \in CheckedReplayRequest :
        LET bytes == EncodeReplayRequest(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

(* Message Length is written from the bytes it frames *)
FramesClientFrame ==
    \A message \in CheckedClientFrame :
        LET bytes == EncodeClientFrame(message)
        IN  DecodeUIntLE(SubSeq(bytes, 4, 5)) = Len(bytes) - 5

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
