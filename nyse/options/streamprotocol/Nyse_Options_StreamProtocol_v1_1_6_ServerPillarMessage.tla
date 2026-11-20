------ MODULE Nyse_Options_StreamProtocol_v1_1_6_ServerPillarMessage -------
(***************************************************************************)
(* New York Stock Exchange Stream Protocol v1.1.6                          *)
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
(* Note: Server Message is chosen by the Msg Type each of its messages     *)
(* begins with: those 2 bytes are read at offset 0 before one is picked,   *)
(* and each message states its own.                                        *)
(*                                                                         *)
(* Note: Server Sequenced Message is its length less the 4 bytes that      *)
(* length counts besides it.                                               *)
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
(* Login Response, framed by Msg Length                                    *)
(***************************************************************************)

LoginResponse ==
    [ username : Sample(16),
      status   : Sample(1) ]

EncodeLoginResponseBody(message) ==
    message.username
        \o message.status

(* Msg Length counts the bytes it frames, so it is written from them *)
EncodeLoginResponse(message) ==
    LET body == EncodeLoginResponseBody(message)
    IN  EncodeUIntLE(514, 2) \o EncodeUIntLE(Len(body) + 4, 2) \o body

DecodeLoginResponse(bytes) ==
    LET msgType == ReadUIntLE(bytes, 2) IN IF ~msgType.ok THEN Fail ELSE
    LET length == ReadUIntLE(msgType.rest, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 4 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
    IN
    LET username == ReadBytes(framed, 16) IN IF ~username.ok THEN Fail ELSE
    LET status == ReadBytes(username.rest, 1) IN IF ~status.ok THEN Fail ELSE
    IF status.rest # << >> THEN Fail ELSE
    Ok([ username |-> username.value,
         status   |-> status.value ], beyond)

ZeroLoginResponse ==
    [ username |-> [i \in 1 .. 16 |-> 0],
      status   |-> [i \in 1 .. 1 |-> 0] ]

(* Login Response at zero, then each field in turn at the values it is checked at *)
CheckedLoginResponse ==
    { ZeroLoginResponse }
        \cup { [ZeroLoginResponse EXCEPT !.username = one] : one \in Sample(16) }
        \cup { [ZeroLoginResponse EXCEPT !.status = one] : one \in Sample(1) }

(***************************************************************************)
(* Stream Id: 8 bytes                                                      *)
(***************************************************************************)

StreamId ==
    [ sess : Sample(4),
      user : Sample(4) ]

EncodeStreamId(message) ==
    message.sess
        \o message.user

DecodeStreamId(bytes) ==
    LET sess == ReadBytes(bytes, 4) IN IF ~sess.ok THEN Fail ELSE
    LET user == ReadBytes(sess.rest, 4) IN IF ~user.ok THEN Fail ELSE
    Ok([ sess |-> sess.value,
         user |-> user.value ], user.rest)

ZeroStreamId ==
    [ sess |-> [i \in 1 .. 4 |-> 0],
      user |-> [i \in 1 .. 4 |-> 0] ]

(* Stream Id at zero, then each field in turn at the values it is checked at *)
CheckedStreamId ==
    { ZeroStreamId }
        \cup { [ZeroStreamId EXCEPT !.sess = one] : one \in Sample(4) }
        \cup { [ZeroStreamId EXCEPT !.user = one] : one \in Sample(4) }

(***************************************************************************)
(* Stream Avail, framed by Msg Length                                      *)
(***************************************************************************)

StreamAvail ==
    [ streamId : StreamId,
      nextSeq  : Sample(8),
      access   : Sample(1) ]

EncodeStreamAvailBody(message) ==
    EncodeStreamId(message.streamId)
        \o message.nextSeq
        \o message.access

(* Msg Length counts the bytes it frames, so it is written from them *)
EncodeStreamAvail(message) ==
    LET body == EncodeStreamAvailBody(message)
    IN  EncodeUIntLE(515, 2) \o EncodeUIntLE(Len(body) + 4, 2) \o body

DecodeStreamAvail(bytes) ==
    LET msgType == ReadUIntLE(bytes, 2) IN IF ~msgType.ok THEN Fail ELSE
    LET length == ReadUIntLE(msgType.rest, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 4 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
    IN
    LET streamId == DecodeStreamId(framed) IN IF ~streamId.ok THEN Fail ELSE
    LET nextSeq == ReadBytes(streamId.rest, 8) IN IF ~nextSeq.ok THEN Fail ELSE
    LET access == ReadBytes(nextSeq.rest, 1) IN IF ~access.ok THEN Fail ELSE
    IF access.rest # << >> THEN Fail ELSE
    Ok([ streamId |-> streamId.value,
         nextSeq  |-> nextSeq.value,
         access   |-> access.value ], beyond)

ZeroStreamAvail ==
    [ streamId |-> ZeroStreamId,
      nextSeq  |-> [i \in 1 .. 8 |-> 0],
      access   |-> [i \in 1 .. 1 |-> 0] ]

(* Stream Avail at zero, then each field in turn at the values it is checked at *)
CheckedStreamAvail ==
    { ZeroStreamAvail }
        \cup { [ZeroStreamAvail EXCEPT !.streamId = one] : one \in CheckedStreamId }
        \cup { [ZeroStreamAvail EXCEPT !.nextSeq = one] : one \in Sample(8) }
        \cup { [ZeroStreamAvail EXCEPT !.access = one] : one \in Sample(1) }

(***************************************************************************)
(* Heartbeat, framed by Msg Length                                         *)
(***************************************************************************)

Heartbeat == [ empty : {0} ]  \* reads nothing of its own

EncodeHeartbeatBody(message) == << >>  \* frames no bytes of its own

(* Msg Length counts the bytes it frames, so it is written from them *)
EncodeHeartbeat(message) ==
    LET body == EncodeHeartbeatBody(message)
    IN  EncodeUIntLE(516, 2) \o EncodeUIntLE(Len(body) + 4, 2) \o body

DecodeHeartbeat(bytes) ==
    LET msgType == ReadUIntLE(bytes, 2) IN IF ~msgType.ok THEN Fail ELSE
    LET length == ReadUIntLE(msgType.rest, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 4 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
    IN
    IF framed # << >> THEN Fail ELSE
    Ok([empty |-> 0], beyond)

ZeroHeartbeat == [empty |-> 0]

(* Heartbeat at zero, then each field in turn at the values it is checked at *)
CheckedHeartbeat == { ZeroHeartbeat }

(***************************************************************************)
(* Stream Id: 8 bytes                                                      *)
(***************************************************************************)

StreamId2 ==
    [ sess : Sample(4),
      user : Sample(4) ]

EncodeStreamId2(message) ==
    message.sess
        \o message.user

DecodeStreamId2(bytes) ==
    LET sess == ReadBytes(bytes, 4) IN IF ~sess.ok THEN Fail ELSE
    LET user == ReadBytes(sess.rest, 4) IN IF ~user.ok THEN Fail ELSE
    Ok([ sess |-> sess.value,
         user |-> user.value ], user.rest)

ZeroStreamId2 ==
    [ sess |-> [i \in 1 .. 4 |-> 0],
      user |-> [i \in 1 .. 4 |-> 0] ]

(* Stream Id at zero, then each field in turn at the values it is checked at *)
CheckedStreamId2 ==
    { ZeroStreamId2 }
        \cup { [ZeroStreamId2 EXCEPT !.sess = one] : one \in Sample(4) }
        \cup { [ZeroStreamId2 EXCEPT !.user = one] : one \in Sample(4) }

(***************************************************************************)
(* Open Response, framed by Msg Length                                     *)
(***************************************************************************)

OpenResponse ==
    [ streamId : StreamId2,
      status   : Sample(1),
      access   : Sample(1) ]

EncodeOpenResponseBody(message) ==
    EncodeStreamId2(message.streamId)
        \o message.status
        \o message.access

(* Msg Length counts the bytes it frames, so it is written from them *)
EncodeOpenResponse(message) ==
    LET body == EncodeOpenResponseBody(message)
    IN  EncodeUIntLE(518, 2) \o EncodeUIntLE(Len(body) + 4, 2) \o body

DecodeOpenResponse(bytes) ==
    LET msgType == ReadUIntLE(bytes, 2) IN IF ~msgType.ok THEN Fail ELSE
    LET length == ReadUIntLE(msgType.rest, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 4 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
    IN
    LET streamId == DecodeStreamId2(framed) IN IF ~streamId.ok THEN Fail ELSE
    LET status == ReadBytes(streamId.rest, 1) IN IF ~status.ok THEN Fail ELSE
    LET access == ReadBytes(status.rest, 1) IN IF ~access.ok THEN Fail ELSE
    IF access.rest # << >> THEN Fail ELSE
    Ok([ streamId |-> streamId.value,
         status   |-> status.value,
         access   |-> access.value ], beyond)

ZeroOpenResponse ==
    [ streamId |-> ZeroStreamId2,
      status   |-> [i \in 1 .. 1 |-> 0],
      access   |-> [i \in 1 .. 1 |-> 0] ]

(* Open Response at zero, then each field in turn at the values it is checked at *)
CheckedOpenResponse ==
    { ZeroOpenResponse }
        \cup { [ZeroOpenResponse EXCEPT !.streamId = one] : one \in CheckedStreamId2 }
        \cup { [ZeroOpenResponse EXCEPT !.status = one] : one \in Sample(1) }
        \cup { [ZeroOpenResponse EXCEPT !.access = one] : one \in Sample(1) }

(***************************************************************************)
(* Stream Id: 8 bytes                                                      *)
(***************************************************************************)

StreamId3 ==
    [ sess : Sample(4),
      user : Sample(4) ]

EncodeStreamId3(message) ==
    message.sess
        \o message.user

DecodeStreamId3(bytes) ==
    LET sess == ReadBytes(bytes, 4) IN IF ~sess.ok THEN Fail ELSE
    LET user == ReadBytes(sess.rest, 4) IN IF ~user.ok THEN Fail ELSE
    Ok([ sess |-> sess.value,
         user |-> user.value ], user.rest)

ZeroStreamId3 ==
    [ sess |-> [i \in 1 .. 4 |-> 0],
      user |-> [i \in 1 .. 4 |-> 0] ]

(* Stream Id at zero, then each field in turn at the values it is checked at *)
CheckedStreamId3 ==
    { ZeroStreamId3 }
        \cup { [ZeroStreamId3 EXCEPT !.sess = one] : one \in Sample(4) }
        \cup { [ZeroStreamId3 EXCEPT !.user = one] : one \in Sample(4) }

(***************************************************************************)
(* Close Response, framed by Msg Length                                    *)
(***************************************************************************)

CloseResponse ==
    [ streamId : StreamId3,
      status   : Sample(1) ]

EncodeCloseResponseBody(message) ==
    EncodeStreamId3(message.streamId)
        \o message.status

(* Msg Length counts the bytes it frames, so it is written from them *)
EncodeCloseResponse(message) ==
    LET body == EncodeCloseResponseBody(message)
    IN  EncodeUIntLE(520, 2) \o EncodeUIntLE(Len(body) + 4, 2) \o body

DecodeCloseResponse(bytes) ==
    LET msgType == ReadUIntLE(bytes, 2) IN IF ~msgType.ok THEN Fail ELSE
    LET length == ReadUIntLE(msgType.rest, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 4 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
    IN
    LET streamId == DecodeStreamId3(framed) IN IF ~streamId.ok THEN Fail ELSE
    LET status == ReadBytes(streamId.rest, 1) IN IF ~status.ok THEN Fail ELSE
    IF status.rest # << >> THEN Fail ELSE
    Ok([ streamId |-> streamId.value,
         status   |-> status.value ], beyond)

ZeroCloseResponse ==
    [ streamId |-> ZeroStreamId3,
      status   |-> [i \in 1 .. 1 |-> 0] ]

(* Close Response at zero, then each field in turn at the values it is checked at *)
CheckedCloseResponse ==
    { ZeroCloseResponse }
        \cup { [ZeroCloseResponse EXCEPT !.streamId = one] : one \in CheckedStreamId3 }
        \cup { [ZeroCloseResponse EXCEPT !.status = one] : one \in Sample(1) }

(***************************************************************************)
(* Stream Id: 8 bytes                                                      *)
(***************************************************************************)

StreamId4 ==
    [ sess : Sample(4),
      user : Sample(4) ]

EncodeStreamId4(message) ==
    message.sess
        \o message.user

DecodeStreamId4(bytes) ==
    LET sess == ReadBytes(bytes, 4) IN IF ~sess.ok THEN Fail ELSE
    LET user == ReadBytes(sess.rest, 4) IN IF ~user.ok THEN Fail ELSE
    Ok([ sess |-> sess.value,
         user |-> user.value ], user.rest)

ZeroStreamId4 ==
    [ sess |-> [i \in 1 .. 4 |-> 0],
      user |-> [i \in 1 .. 4 |-> 0] ]

(* Stream Id at zero, then each field in turn at the values it is checked at *)
CheckedStreamId4 ==
    { ZeroStreamId4 }
        \cup { [ZeroStreamId4 EXCEPT !.sess = one] : one \in Sample(4) }
        \cup { [ZeroStreamId4 EXCEPT !.user = one] : one \in Sample(4) }

(***************************************************************************)
(* Seq Msg Id: 16 bytes                                                    *)
(***************************************************************************)

SeqMsgId ==
    [ streamId : StreamId4,
      seq      : Sample(8) ]

EncodeSeqMsgId(message) ==
    EncodeStreamId4(message.streamId)
        \o message.seq

DecodeSeqMsgId(bytes) ==
    LET streamId == DecodeStreamId4(bytes) IN IF ~streamId.ok THEN Fail ELSE
    LET seq == ReadBytes(streamId.rest, 8) IN IF ~seq.ok THEN Fail ELSE
    Ok([ streamId |-> streamId.value,
         seq      |-> seq.value ], seq.rest)

ZeroSeqMsgId ==
    [ streamId |-> ZeroStreamId4,
      seq      |-> [i \in 1 .. 8 |-> 0] ]

(* Seq Msg Id at zero, then each field in turn at the values it is checked at *)
CheckedSeqMsgId ==
    { ZeroSeqMsgId }
        \cup { [ZeroSeqMsgId EXCEPT !.streamId = one] : one \in CheckedStreamId4 }
        \cup { [ZeroSeqMsgId EXCEPT !.seq = one] : one \in Sample(8) }

(***************************************************************************)
(* Server Seq Msg, framed by Msg Length                                    *)
(***************************************************************************)

ServerSeqMsg ==
    [ seqMsgId               : SeqMsgId,
      reserved4              : Sample(4),
      timestamp              : Sample(8),
      seqMsgType             : Sample(2),
      serverSequencedMessage : SampleBytes ]

EncodeServerSeqMsgBody(message) ==
    EncodeSeqMsgId(message.seqMsgId)
        \o message.reserved4
        \o message.timestamp
        \o message.seqMsgType
        \o EncodeUIntLE(Len(message.serverSequencedMessage) + 4, 2)
        \o message.serverSequencedMessage

(* Msg Length counts the bytes it frames, so it is written from them *)
EncodeServerSeqMsg(message) ==
    LET body == EncodeServerSeqMsgBody(message)
    IN  EncodeUIntLE(2309, 2) \o EncodeUIntLE(Len(body) + 4, 2) \o body

DecodeServerSeqMsg(bytes) ==
    LET msgType == ReadUIntLE(bytes, 2) IN IF ~msgType.ok THEN Fail ELSE
    LET length == ReadUIntLE(msgType.rest, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 4 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
    IN
    LET seqMsgId == DecodeSeqMsgId(framed) IN IF ~seqMsgId.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(seqMsgId.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET timestamp == ReadBytes(reserved4.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET seqMsgType == ReadBytes(timestamp.rest, 2) IN IF ~seqMsgType.ok THEN Fail ELSE
    LET seqMsgLength == ReadUIntLE(seqMsgType.rest, 2) IN IF ~seqMsgLength.ok THEN Fail ELSE
    IF seqMsgLength.value < 4 THEN Fail ELSE
    LET serverSequencedMessage == ReadBytes(seqMsgLength.rest, seqMsgLength.value - 4) IN IF ~serverSequencedMessage.ok THEN Fail ELSE
    IF serverSequencedMessage.rest # << >> THEN Fail ELSE
    Ok([ seqMsgId               |-> seqMsgId.value,
         reserved4              |-> reserved4.value,
         timestamp              |-> timestamp.value,
         seqMsgType             |-> seqMsgType.value,
         serverSequencedMessage |-> serverSequencedMessage.value ], beyond)

ZeroServerSeqMsg ==
    [ seqMsgId               |-> ZeroSeqMsgId,
      reserved4              |-> [i \in 1 .. 4 |-> 0],
      timestamp              |-> [i \in 1 .. 8 |-> 0],
      seqMsgType             |-> [i \in 1 .. 2 |-> 0],
      serverSequencedMessage |-> << >> ]

(* Server Seq Msg at zero, then each field in turn at the values it is checked at *)
CheckedServerSeqMsg ==
    { ZeroServerSeqMsg }
        \cup { [ZeroServerSeqMsg EXCEPT !.seqMsgId = one] : one \in CheckedSeqMsgId }
        \cup { [ZeroServerSeqMsg EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroServerSeqMsg EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroServerSeqMsg EXCEPT !.seqMsgType = one] : one \in Sample(2) }
        \cup { [ZeroServerSeqMsg EXCEPT !.serverSequencedMessage = one] : one \in SampleBytes }

(***************************************************************************)
(* Server Message, selected by Msg Type                                    *)
(***************************************************************************)

LoginResponseCode == 514  \* 0x202
StreamAvailCode == 515  \* 0x203
HeartbeatCode == 516  \* 0x204
OpenResponseCode == 518  \* 0x206
CloseResponseCode == 520  \* 0x208
ServerSeqMsgCode == 2309  \* 0x905

ServerMessage ==
    [ tag : {LoginResponseCode}, body : LoginResponse ]
        \cup [ tag : {StreamAvailCode}, body : StreamAvail ]
        \cup [ tag : {HeartbeatCode}, body : Heartbeat ]
        \cup [ tag : {OpenResponseCode}, body : OpenResponse ]
        \cup [ tag : {CloseResponseCode}, body : CloseResponse ]
        \cup [ tag : {ServerSeqMsgCode}, body : ServerSeqMsg ]

EncodeServerMessage(message) ==
    CASE message.tag = LoginResponseCode -> EncodeLoginResponse(message.body)
      [] message.tag = StreamAvailCode -> EncodeStreamAvail(message.body)
      [] message.tag = HeartbeatCode -> EncodeHeartbeat(message.body)
      [] message.tag = OpenResponseCode -> EncodeOpenResponse(message.body)
      [] message.tag = CloseResponseCode -> EncodeCloseResponse(message.body)
      [] message.tag = ServerSeqMsgCode -> EncodeServerSeqMsg(message.body)

DecodeServerMessage(tag, bytes) ==
    LET read ==
            CASE tag = LoginResponseCode -> DecodeLoginResponse(bytes)
              [] tag = StreamAvailCode -> DecodeStreamAvail(bytes)
              [] tag = HeartbeatCode -> DecodeHeartbeat(bytes)
              [] tag = OpenResponseCode -> DecodeOpenResponse(bytes)
              [] tag = CloseResponseCode -> DecodeCloseResponse(bytes)
              [] tag = ServerSeqMsgCode -> DecodeServerSeqMsg(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroServerMessage == [tag |-> LoginResponseCode, body |-> ZeroLoginResponse]

(* Each Server Message in turn, at the values the message it names is checked at *)
CheckedServerMessage ==
    { [tag |-> LoginResponseCode, body |-> one] : one \in CheckedLoginResponse }
        \cup { [tag |-> StreamAvailCode, body |-> one] : one \in CheckedStreamAvail }
        \cup { [tag |-> HeartbeatCode, body |-> one] : one \in CheckedHeartbeat }
        \cup { [tag |-> OpenResponseCode, body |-> one] : one \in CheckedOpenResponse }
        \cup { [tag |-> CloseResponseCode, body |-> one] : one \in CheckedCloseResponse }
        \cup { [tag |-> ServerSeqMsgCode, body |-> one] : one \in CheckedServerSeqMsg }

(***************************************************************************)
(* Server Pillar Message                                                   *)
(***************************************************************************)

ServerPillarMessage ==
    [ serverMessage : ServerMessage ]

EncodeServerPillarMessage(message) ==
    EncodeServerMessage(message.serverMessage)

DecodeServerPillarMessage(bytes) ==
    IF Len(bytes) < 2 THEN Fail ELSE
    LET serverMessage == DecodeServerMessage(DecodeUIntLE(SubSeq(bytes, 1, 2)), bytes) IN IF ~serverMessage.ok THEN Fail ELSE
    Ok([ serverMessage |-> serverMessage.value ], serverMessage.rest)

ZeroServerPillarMessage ==
    [ serverMessage |-> ZeroServerMessage ]

(* Server Pillar Message at zero, then each field in turn at the values it is checked at *)
CheckedServerPillarMessage ==
    { ZeroServerPillarMessage }
        \cup { [ZeroServerPillarMessage EXCEPT !.serverMessage = one] : one \in CheckedServerMessage }

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

(* Every Login Response decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginResponse ==
    \A message \in CheckedLoginResponse :
        LET read == DecodeLoginResponse(EncodeLoginResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stream Id decodes back to what was encoded, and leaves nothing over *)
RoundTripStreamId ==
    \A message \in CheckedStreamId :
        LET read == DecodeStreamId(EncodeStreamId(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stream Avail decodes back to what was encoded, and leaves nothing over *)
RoundTripStreamAvail ==
    \A message \in CheckedStreamAvail :
        LET read == DecodeStreamAvail(EncodeStreamAvail(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Heartbeat decodes back to what was encoded, and leaves nothing over *)
RoundTripHeartbeat ==
    \A message \in CheckedHeartbeat :
        LET read == DecodeHeartbeat(EncodeHeartbeat(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stream Id decodes back to what was encoded, and leaves nothing over *)
RoundTripStreamId2 ==
    \A message \in CheckedStreamId2 :
        LET read == DecodeStreamId2(EncodeStreamId2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Open Response decodes back to what was encoded, and leaves nothing over *)
RoundTripOpenResponse ==
    \A message \in CheckedOpenResponse :
        LET read == DecodeOpenResponse(EncodeOpenResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stream Id decodes back to what was encoded, and leaves nothing over *)
RoundTripStreamId3 ==
    \A message \in CheckedStreamId3 :
        LET read == DecodeStreamId3(EncodeStreamId3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Close Response decodes back to what was encoded, and leaves nothing over *)
RoundTripCloseResponse ==
    \A message \in CheckedCloseResponse :
        LET read == DecodeCloseResponse(EncodeCloseResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stream Id decodes back to what was encoded, and leaves nothing over *)
RoundTripStreamId4 ==
    \A message \in CheckedStreamId4 :
        LET read == DecodeStreamId4(EncodeStreamId4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Seq Msg Id decodes back to what was encoded, and leaves nothing over *)
RoundTripSeqMsgId ==
    \A message \in CheckedSeqMsgId :
        LET read == DecodeSeqMsgId(EncodeSeqMsgId(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Server Seq Msg decodes back to what was encoded, and leaves nothing over *)
RoundTripServerSeqMsg ==
    \A message \in CheckedServerSeqMsg :
        LET read == DecodeServerSeqMsg(EncodeServerSeqMsg(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Server Pillar Message decodes back to what was encoded, and leaves nothing over *)
RoundTripServerPillarMessage ==
    \A message \in CheckedServerPillarMessage :
        LET read == DecodeServerPillarMessage(EncodeServerPillarMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Server Message written out and then looked at is selected by the Msg Type it wrote *)
SelectsServerMessage ==
    \A message \in CheckedServerMessage :
        LET sent == EncodeServerMessage(message)
            read == DecodeServerMessage(DecodeUIntLE(SubSeq(sent, 1, 2)), sent)
        IN  Len(sent) >= 2 /\ read.ok /\ read.value.tag = message.tag

(* Msg Length is written from the bytes it frames *)
FramesLoginResponse ==
    \A message \in CheckedLoginResponse :
        LET bytes == EncodeLoginResponse(message)
        IN  DecodeUIntLE(SubSeq(bytes, 3, 4)) = Len(bytes) - 0

(* Msg Length is written from the bytes it frames *)
FramesStreamAvail ==
    \A message \in CheckedStreamAvail :
        LET bytes == EncodeStreamAvail(message)
        IN  DecodeUIntLE(SubSeq(bytes, 3, 4)) = Len(bytes) - 0

(* Msg Length is written from the bytes it frames *)
FramesHeartbeat ==
    \A message \in CheckedHeartbeat :
        LET bytes == EncodeHeartbeat(message)
        IN  DecodeUIntLE(SubSeq(bytes, 3, 4)) = Len(bytes) - 0

(* Msg Length is written from the bytes it frames *)
FramesOpenResponse ==
    \A message \in CheckedOpenResponse :
        LET bytes == EncodeOpenResponse(message)
        IN  DecodeUIntLE(SubSeq(bytes, 3, 4)) = Len(bytes) - 0

(* Msg Length is written from the bytes it frames *)
FramesCloseResponse ==
    \A message \in CheckedCloseResponse :
        LET bytes == EncodeCloseResponse(message)
        IN  DecodeUIntLE(SubSeq(bytes, 3, 4)) = Len(bytes) - 0

(* Msg Length is written from the bytes it frames *)
FramesServerSeqMsg ==
    \A message \in CheckedServerSeqMsg :
        LET bytes == EncodeServerSeqMsg(message)
        IN  DecodeUIntLE(SubSeq(bytes, 3, 4)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
