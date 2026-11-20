------ MODULE Nyse_Options_StreamProtocol_v1_1_6_ClientPillarMessage -------
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
(* Note: Client Message is chosen by the Msg Type each of its messages     *)
(* begins with: those 2 bytes are read at offset 0 before one is picked,   *)
(* and each message states its own.                                        *)
(*                                                                         *)
(* Note: Client Sequenced Message is its length less the 4 bytes that      *)
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
(* Login Message, framed by Msg Length                                     *)
(***************************************************************************)

LoginMessage ==
    [ username : Sample(16),
      password : Sample(32),
      mic      : Sample(4),
      version  : Sample(20) ]

EncodeLoginMessageBody(message) ==
    message.username
        \o message.password
        \o message.mic
        \o message.version

(* Msg Length counts the bytes it frames, so it is written from them *)
EncodeLoginMessage(message) ==
    LET body == EncodeLoginMessageBody(message)
    IN  EncodeUIntLE(513, 2) \o EncodeUIntLE(Len(body) + 4, 2) \o body

DecodeLoginMessage(bytes) ==
    LET msgType == ReadUIntLE(bytes, 2) IN IF ~msgType.ok THEN Fail ELSE
    LET length == ReadUIntLE(msgType.rest, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 4 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
    IN
    LET username == ReadBytes(framed, 16) IN IF ~username.ok THEN Fail ELSE
    LET password == ReadBytes(username.rest, 32) IN IF ~password.ok THEN Fail ELSE
    LET mic == ReadBytes(password.rest, 4) IN IF ~mic.ok THEN Fail ELSE
    LET version == ReadBytes(mic.rest, 20) IN IF ~version.ok THEN Fail ELSE
    IF version.rest # << >> THEN Fail ELSE
    Ok([ username |-> username.value,
         password |-> password.value,
         mic      |-> mic.value,
         version  |-> version.value ], beyond)

ZeroLoginMessage ==
    [ username |-> [i \in 1 .. 16 |-> 0],
      password |-> [i \in 1 .. 32 |-> 0],
      mic      |-> [i \in 1 .. 4 |-> 0],
      version  |-> [i \in 1 .. 20 |-> 0] ]

(* Login Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginMessage ==
    { ZeroLoginMessage }
        \cup { [ZeroLoginMessage EXCEPT !.username = one] : one \in Sample(16) }
        \cup { [ZeroLoginMessage EXCEPT !.password = one] : one \in Sample(32) }
        \cup { [ZeroLoginMessage EXCEPT !.mic = one] : one \in Sample(4) }
        \cup { [ZeroLoginMessage EXCEPT !.version = one] : one \in Sample(20) }

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
(* Open, framed by Msg Length                                              *)
(***************************************************************************)

Open ==
    [ streamId : StreamId,
      startSeq : Sample(8),
      endSeq   : Sample(8),
      access   : Sample(1),
      mode     : Sample(1) ]

EncodeOpenBody(message) ==
    EncodeStreamId(message.streamId)
        \o message.startSeq
        \o message.endSeq
        \o message.access
        \o message.mode

(* Msg Length counts the bytes it frames, so it is written from them *)
EncodeOpen(message) ==
    LET body == EncodeOpenBody(message)
    IN  EncodeUIntLE(517, 2) \o EncodeUIntLE(Len(body) + 4, 2) \o body

DecodeOpen(bytes) ==
    LET msgType == ReadUIntLE(bytes, 2) IN IF ~msgType.ok THEN Fail ELSE
    LET length == ReadUIntLE(msgType.rest, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 4 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
    IN
    LET streamId == DecodeStreamId(framed) IN IF ~streamId.ok THEN Fail ELSE
    LET startSeq == ReadBytes(streamId.rest, 8) IN IF ~startSeq.ok THEN Fail ELSE
    LET endSeq == ReadBytes(startSeq.rest, 8) IN IF ~endSeq.ok THEN Fail ELSE
    LET access == ReadBytes(endSeq.rest, 1) IN IF ~access.ok THEN Fail ELSE
    LET mode == ReadBytes(access.rest, 1) IN IF ~mode.ok THEN Fail ELSE
    IF mode.rest # << >> THEN Fail ELSE
    Ok([ streamId |-> streamId.value,
         startSeq |-> startSeq.value,
         endSeq   |-> endSeq.value,
         access   |-> access.value,
         mode     |-> mode.value ], beyond)

ZeroOpen ==
    [ streamId |-> ZeroStreamId,
      startSeq |-> [i \in 1 .. 8 |-> 0],
      endSeq   |-> [i \in 1 .. 8 |-> 0],
      access   |-> [i \in 1 .. 1 |-> 0],
      mode     |-> [i \in 1 .. 1 |-> 0] ]

(* Open at zero, then each field in turn at the values it is checked at *)
CheckedOpen ==
    { ZeroOpen }
        \cup { [ZeroOpen EXCEPT !.streamId = one] : one \in CheckedStreamId }
        \cup { [ZeroOpen EXCEPT !.startSeq = one] : one \in Sample(8) }
        \cup { [ZeroOpen EXCEPT !.endSeq = one] : one \in Sample(8) }
        \cup { [ZeroOpen EXCEPT !.access = one] : one \in Sample(1) }
        \cup { [ZeroOpen EXCEPT !.mode = one] : one \in Sample(1) }

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
(* Close, framed by Msg Length                                             *)
(***************************************************************************)

Close ==
    [ streamId : StreamId2 ]

EncodeCloseBody(message) ==
    EncodeStreamId2(message.streamId)

(* Msg Length counts the bytes it frames, so it is written from them *)
EncodeClose(message) ==
    LET body == EncodeCloseBody(message)
    IN  EncodeUIntLE(519, 2) \o EncodeUIntLE(Len(body) + 4, 2) \o body

DecodeClose(bytes) ==
    LET msgType == ReadUIntLE(bytes, 2) IN IF ~msgType.ok THEN Fail ELSE
    LET length == ReadUIntLE(msgType.rest, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 4 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
    IN
    LET streamId == DecodeStreamId2(framed) IN IF ~streamId.ok THEN Fail ELSE
    IF streamId.rest # << >> THEN Fail ELSE
    Ok([ streamId |-> streamId.value ], beyond)

ZeroClose ==
    [ streamId |-> ZeroStreamId2 ]

(* Close at zero, then each field in turn at the values it is checked at *)
CheckedClose ==
    { ZeroClose }
        \cup { [ZeroClose EXCEPT !.streamId = one] : one \in CheckedStreamId2 }

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
(* Seq Msg Id: 16 bytes                                                    *)
(***************************************************************************)

SeqMsgId ==
    [ streamId : StreamId3,
      seq      : Sample(8) ]

EncodeSeqMsgId(message) ==
    EncodeStreamId3(message.streamId)
        \o message.seq

DecodeSeqMsgId(bytes) ==
    LET streamId == DecodeStreamId3(bytes) IN IF ~streamId.ok THEN Fail ELSE
    LET seq == ReadBytes(streamId.rest, 8) IN IF ~seq.ok THEN Fail ELSE
    Ok([ streamId |-> streamId.value,
         seq      |-> seq.value ], seq.rest)

ZeroSeqMsgId ==
    [ streamId |-> ZeroStreamId3,
      seq      |-> [i \in 1 .. 8 |-> 0] ]

(* Seq Msg Id at zero, then each field in turn at the values it is checked at *)
CheckedSeqMsgId ==
    { ZeroSeqMsgId }
        \cup { [ZeroSeqMsgId EXCEPT !.streamId = one] : one \in CheckedStreamId3 }
        \cup { [ZeroSeqMsgId EXCEPT !.seq = one] : one \in Sample(8) }

(***************************************************************************)
(* Client Seq Msg, framed by Msg Length                                    *)
(***************************************************************************)

ClientSeqMsg ==
    [ seqMsgId               : SeqMsgId,
      reserved4              : Sample(4),
      timestamp              : Sample(8),
      seqMsgType             : Sample(2),
      clientSequencedMessage : SampleBytes ]

EncodeClientSeqMsgBody(message) ==
    EncodeSeqMsgId(message.seqMsgId)
        \o message.reserved4
        \o message.timestamp
        \o message.seqMsgType
        \o EncodeUIntLE(Len(message.clientSequencedMessage) + 4, 2)
        \o message.clientSequencedMessage

(* Msg Length counts the bytes it frames, so it is written from them *)
EncodeClientSeqMsg(message) ==
    LET body == EncodeClientSeqMsgBody(message)
    IN  EncodeUIntLE(2309, 2) \o EncodeUIntLE(Len(body) + 4, 2) \o body

DecodeClientSeqMsg(bytes) ==
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
    LET clientSequencedMessage == ReadBytes(seqMsgLength.rest, seqMsgLength.value - 4) IN IF ~clientSequencedMessage.ok THEN Fail ELSE
    IF clientSequencedMessage.rest # << >> THEN Fail ELSE
    Ok([ seqMsgId               |-> seqMsgId.value,
         reserved4              |-> reserved4.value,
         timestamp              |-> timestamp.value,
         seqMsgType             |-> seqMsgType.value,
         clientSequencedMessage |-> clientSequencedMessage.value ], beyond)

ZeroClientSeqMsg ==
    [ seqMsgId               |-> ZeroSeqMsgId,
      reserved4              |-> [i \in 1 .. 4 |-> 0],
      timestamp              |-> [i \in 1 .. 8 |-> 0],
      seqMsgType             |-> [i \in 1 .. 2 |-> 0],
      clientSequencedMessage |-> << >> ]

(* Client Seq Msg at zero, then each field in turn at the values it is checked at *)
CheckedClientSeqMsg ==
    { ZeroClientSeqMsg }
        \cup { [ZeroClientSeqMsg EXCEPT !.seqMsgId = one] : one \in CheckedSeqMsgId }
        \cup { [ZeroClientSeqMsg EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroClientSeqMsg EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroClientSeqMsg EXCEPT !.seqMsgType = one] : one \in Sample(2) }
        \cup { [ZeroClientSeqMsg EXCEPT !.clientSequencedMessage = one] : one \in SampleBytes }

(***************************************************************************)
(* Client Message, selected by Msg Type                                    *)
(***************************************************************************)

LoginMessageCode == 513  \* 0x201
HeartbeatCode == 516  \* 0x204
OpenCode == 517  \* 0x205
CloseCode == 519  \* 0x207
ClientSeqMsgCode == 2309  \* 0x905

ClientMessage ==
    [ tag : {LoginMessageCode}, body : LoginMessage ]
        \cup [ tag : {HeartbeatCode}, body : Heartbeat ]
        \cup [ tag : {OpenCode}, body : Open ]
        \cup [ tag : {CloseCode}, body : Close ]
        \cup [ tag : {ClientSeqMsgCode}, body : ClientSeqMsg ]

EncodeClientMessage(message) ==
    CASE message.tag = LoginMessageCode -> EncodeLoginMessage(message.body)
      [] message.tag = HeartbeatCode -> EncodeHeartbeat(message.body)
      [] message.tag = OpenCode -> EncodeOpen(message.body)
      [] message.tag = CloseCode -> EncodeClose(message.body)
      [] message.tag = ClientSeqMsgCode -> EncodeClientSeqMsg(message.body)

DecodeClientMessage(tag, bytes) ==
    LET read ==
            CASE tag = LoginMessageCode -> DecodeLoginMessage(bytes)
              [] tag = HeartbeatCode -> DecodeHeartbeat(bytes)
              [] tag = OpenCode -> DecodeOpen(bytes)
              [] tag = CloseCode -> DecodeClose(bytes)
              [] tag = ClientSeqMsgCode -> DecodeClientSeqMsg(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroClientMessage == [tag |-> LoginMessageCode, body |-> ZeroLoginMessage]

(* Each Client Message in turn, at the values the message it names is checked at *)
CheckedClientMessage ==
    { [tag |-> LoginMessageCode, body |-> one] : one \in CheckedLoginMessage }
        \cup { [tag |-> HeartbeatCode, body |-> one] : one \in CheckedHeartbeat }
        \cup { [tag |-> OpenCode, body |-> one] : one \in CheckedOpen }
        \cup { [tag |-> CloseCode, body |-> one] : one \in CheckedClose }
        \cup { [tag |-> ClientSeqMsgCode, body |-> one] : one \in CheckedClientSeqMsg }

(***************************************************************************)
(* Client Pillar Message                                                   *)
(***************************************************************************)

ClientPillarMessage ==
    [ clientMessage : ClientMessage ]

EncodeClientPillarMessage(message) ==
    EncodeClientMessage(message.clientMessage)

DecodeClientPillarMessage(bytes) ==
    IF Len(bytes) < 2 THEN Fail ELSE
    LET clientMessage == DecodeClientMessage(DecodeUIntLE(SubSeq(bytes, 1, 2)), bytes) IN IF ~clientMessage.ok THEN Fail ELSE
    Ok([ clientMessage |-> clientMessage.value ], clientMessage.rest)

ZeroClientPillarMessage ==
    [ clientMessage |-> ZeroClientMessage ]

(* Client Pillar Message at zero, then each field in turn at the values it is checked at *)
CheckedClientPillarMessage ==
    { ZeroClientPillarMessage }
        \cup { [ZeroClientPillarMessage EXCEPT !.clientMessage = one] : one \in CheckedClientMessage }

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

(* Every Login Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginMessage ==
    \A message \in CheckedLoginMessage :
        LET read == DecodeLoginMessage(EncodeLoginMessage(message))
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
RoundTripStreamId ==
    \A message \in CheckedStreamId :
        LET read == DecodeStreamId(EncodeStreamId(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Open decodes back to what was encoded, and leaves nothing over *)
RoundTripOpen ==
    \A message \in CheckedOpen :
        LET read == DecodeOpen(EncodeOpen(message))
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

(* Every Close decodes back to what was encoded, and leaves nothing over *)
RoundTripClose ==
    \A message \in CheckedClose :
        LET read == DecodeClose(EncodeClose(message))
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

(* Every Seq Msg Id decodes back to what was encoded, and leaves nothing over *)
RoundTripSeqMsgId ==
    \A message \in CheckedSeqMsgId :
        LET read == DecodeSeqMsgId(EncodeSeqMsgId(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client Seq Msg decodes back to what was encoded, and leaves nothing over *)
RoundTripClientSeqMsg ==
    \A message \in CheckedClientSeqMsg :
        LET read == DecodeClientSeqMsg(EncodeClientSeqMsg(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client Pillar Message decodes back to what was encoded, and leaves nothing over *)
RoundTripClientPillarMessage ==
    \A message \in CheckedClientPillarMessage :
        LET read == DecodeClientPillarMessage(EncodeClientPillarMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Client Message written out and then looked at is selected by the Msg Type it wrote *)
SelectsClientMessage ==
    \A message \in CheckedClientMessage :
        LET sent == EncodeClientMessage(message)
            read == DecodeClientMessage(DecodeUIntLE(SubSeq(sent, 1, 2)), sent)
        IN  Len(sent) >= 2 /\ read.ok /\ read.value.tag = message.tag

(* Msg Length is written from the bytes it frames *)
FramesLoginMessage ==
    \A message \in CheckedLoginMessage :
        LET bytes == EncodeLoginMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 3, 4)) = Len(bytes) - 0

(* Msg Length is written from the bytes it frames *)
FramesHeartbeat ==
    \A message \in CheckedHeartbeat :
        LET bytes == EncodeHeartbeat(message)
        IN  DecodeUIntLE(SubSeq(bytes, 3, 4)) = Len(bytes) - 0

(* Msg Length is written from the bytes it frames *)
FramesOpen ==
    \A message \in CheckedOpen :
        LET bytes == EncodeOpen(message)
        IN  DecodeUIntLE(SubSeq(bytes, 3, 4)) = Len(bytes) - 0

(* Msg Length is written from the bytes it frames *)
FramesClose ==
    \A message \in CheckedClose :
        LET bytes == EncodeClose(message)
        IN  DecodeUIntLE(SubSeq(bytes, 3, 4)) = Len(bytes) - 0

(* Msg Length is written from the bytes it frames *)
FramesClientSeqMsg ==
    \A message \in CheckedClientSeqMsg :
        LET bytes == EncodeClientSeqMsg(message)
        IN  DecodeUIntLE(SubSeq(bytes, 3, 4)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
