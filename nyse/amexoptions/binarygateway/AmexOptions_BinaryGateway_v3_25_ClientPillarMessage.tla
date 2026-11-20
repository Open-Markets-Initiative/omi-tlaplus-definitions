-------- MODULE AmexOptions_BinaryGateway_v3_25_ClientPillarMessage --------
(***************************************************************************)
(* New York Stock Exchange Binary Gateway v3.25                            *)
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
(* Note: Client Sequenced Message is framed by Seq Msg Length, which       *)
(* states the 4 bytes of Seq Msg Header beside it and the message that     *)
(* follows: the choice is read from that many bytes and must take them     *)
(* all.                                                                    *)
(*                                                                         *)
(* Note: Session Configuration Request Message is as wide as Seq Msg       *)
(* Length says, which is the frame it is read from.                        *)
(*                                                                         *)
(* Note: Seq Msg Length frames this record, so it is as long as what the   *)
(* record holds: 100 carries none of them, and each of the others states   *)
(* its own length.                                                         *)
(*                                                                         *)
(* Note: New Order Message is as wide as Seq Msg Length says, which is the *)
(* frame it is read from.                                                  *)
(*                                                                         *)
(* Note: Order Cancel Request Message is as wide as Seq Msg Length says,   *)
(* which is the frame it is read from.                                     *)
(*                                                                         *)
(* Note: Order Modify Request Message is as wide as Seq Msg Length says,   *)
(* which is the frame it is read from.                                     *)
(*                                                                         *)
(* Note: New Bulk Quote Type 243 Message is as wide as Seq Msg Length      *)
(* says, which is the frame it is read from.                               *)
(*                                                                         *)
(* Note: New Bulk Quote Type 259 Message is as wide as Seq Msg Length      *)
(* says, which is the frame it is read from.                               *)
(*                                                                         *)
(* Note: New Order Cross Message is as wide as Seq Msg Length says, which  *)
(* is the frame it is read from.                                           *)
(*                                                                         *)
(* Note: Bulk Cancel Request Type 223 Message is as wide as Seq Msg Length *)
(* says, which is the frame it is read from.                               *)
(*                                                                         *)
(* Note: Bulk Cancel Request Type 224 Message is as wide as Seq Msg Length *)
(* says, which is the frame it is read from.                               *)
(*                                                                         *)
(* Note: Risk Limit Update Request Message is as wide as Seq Msg Length    *)
(* says, which is the frame it is read from.                               *)
(*                                                                         *)
(* Note: Risk Action Request Message is as wide as Seq Msg Length says,    *)
(* which is the frame it is read from.                                     *)
(*                                                                         *)
(* Note: New Complex Series Request Message is as wide as Seq Msg Length   *)
(* says, which is the frame it is read from.                               *)
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
    [ sess  : Sample(4),
      value : Sample(4) ]

EncodeStreamId(message) ==
    message.sess
        \o message.value

DecodeStreamId(bytes) ==
    LET sess == ReadBytes(bytes, 4) IN IF ~sess.ok THEN Fail ELSE
    LET value == ReadBytes(sess.rest, 4) IN IF ~value.ok THEN Fail ELSE
    Ok([ sess  |-> sess.value,
         value |-> value.value ], value.rest)

ZeroStreamId ==
    [ sess  |-> [i \in 1 .. 4 |-> 0],
      value |-> [i \in 1 .. 4 |-> 0] ]

(* Stream Id at zero, then each field in turn at the values it is checked at *)
CheckedStreamId ==
    { ZeroStreamId }
        \cup { [ZeroStreamId EXCEPT !.sess = one] : one \in Sample(4) }
        \cup { [ZeroStreamId EXCEPT !.value = one] : one \in Sample(4) }

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
    [ sess  : Sample(4),
      value : Sample(4) ]

EncodeStreamId2(message) ==
    message.sess
        \o message.value

DecodeStreamId2(bytes) ==
    LET sess == ReadBytes(bytes, 4) IN IF ~sess.ok THEN Fail ELSE
    LET value == ReadBytes(sess.rest, 4) IN IF ~value.ok THEN Fail ELSE
    Ok([ sess  |-> sess.value,
         value |-> value.value ], value.rest)

ZeroStreamId2 ==
    [ sess  |-> [i \in 1 .. 4 |-> 0],
      value |-> [i \in 1 .. 4 |-> 0] ]

(* Stream Id at zero, then each field in turn at the values it is checked at *)
CheckedStreamId2 ==
    { ZeroStreamId2 }
        \cup { [ZeroStreamId2 EXCEPT !.sess = one] : one \in Sample(4) }
        \cup { [ZeroStreamId2 EXCEPT !.value = one] : one \in Sample(4) }

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
    [ sess  : Sample(4),
      value : Sample(4) ]

EncodeStreamId3(message) ==
    message.sess
        \o message.value

DecodeStreamId3(bytes) ==
    LET sess == ReadBytes(bytes, 4) IN IF ~sess.ok THEN Fail ELSE
    LET value == ReadBytes(sess.rest, 4) IN IF ~value.ok THEN Fail ELSE
    Ok([ sess  |-> sess.value,
         value |-> value.value ], value.rest)

ZeroStreamId3 ==
    [ sess  |-> [i \in 1 .. 4 |-> 0],
      value |-> [i \in 1 .. 4 |-> 0] ]

(* Stream Id at zero, then each field in turn at the values it is checked at *)
CheckedStreamId3 ==
    { ZeroStreamId3 }
        \cup { [ZeroStreamId3 EXCEPT !.sess = one] : one \in Sample(4) }
        \cup { [ZeroStreamId3 EXCEPT !.value = one] : one \in Sample(4) }

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
(* Session Configuration Request Message: 70 bytes                         *)
(***************************************************************************)

SessionConfigurationRequestMessage ==
    [ username                           : Sample(16),
      cancelOnDisconnect                 : Sample(1),
      throttlePreference                 : Sample(1),
      selfTradePrevention                : Sample(1),
      orderPriorityUpdateAckSubscription : Sample(1),
      boldDesignation                    : Sample(1),
      reserved49                         : Sample(49) ]

EncodeSessionConfigurationRequestMessage(message) ==
    message.username
        \o message.cancelOnDisconnect
        \o message.throttlePreference
        \o message.selfTradePrevention
        \o message.orderPriorityUpdateAckSubscription
        \o message.boldDesignation
        \o message.reserved49

DecodeSessionConfigurationRequestMessage(bytes) ==
    LET username == ReadBytes(bytes, 16) IN IF ~username.ok THEN Fail ELSE
    LET cancelOnDisconnect == ReadBytes(username.rest, 1) IN IF ~cancelOnDisconnect.ok THEN Fail ELSE
    LET throttlePreference == ReadBytes(cancelOnDisconnect.rest, 1) IN IF ~throttlePreference.ok THEN Fail ELSE
    LET selfTradePrevention == ReadBytes(throttlePreference.rest, 1) IN IF ~selfTradePrevention.ok THEN Fail ELSE
    LET orderPriorityUpdateAckSubscription == ReadBytes(selfTradePrevention.rest, 1) IN IF ~orderPriorityUpdateAckSubscription.ok THEN Fail ELSE
    LET boldDesignation == ReadBytes(orderPriorityUpdateAckSubscription.rest, 1) IN IF ~boldDesignation.ok THEN Fail ELSE
    LET reserved49 == ReadBytes(boldDesignation.rest, 49) IN IF ~reserved49.ok THEN Fail ELSE
    Ok([ username                           |-> username.value,
         cancelOnDisconnect                 |-> cancelOnDisconnect.value,
         throttlePreference                 |-> throttlePreference.value,
         selfTradePrevention                |-> selfTradePrevention.value,
         orderPriorityUpdateAckSubscription |-> orderPriorityUpdateAckSubscription.value,
         boldDesignation                    |-> boldDesignation.value,
         reserved49                         |-> reserved49.value ], reserved49.rest)

ZeroSessionConfigurationRequestMessage ==
    [ username                           |-> [i \in 1 .. 16 |-> 0],
      cancelOnDisconnect                 |-> [i \in 1 .. 1 |-> 0],
      throttlePreference                 |-> [i \in 1 .. 1 |-> 0],
      selfTradePrevention                |-> [i \in 1 .. 1 |-> 0],
      orderPriorityUpdateAckSubscription |-> [i \in 1 .. 1 |-> 0],
      boldDesignation                    |-> [i \in 1 .. 1 |-> 0],
      reserved49                         |-> [i \in 1 .. 49 |-> 0] ]

(* Session Configuration Request Message at zero, then each field in turn at the values it is checked at *)
CheckedSessionConfigurationRequestMessage ==
    { ZeroSessionConfigurationRequestMessage }
        \cup { [ZeroSessionConfigurationRequestMessage EXCEPT !.username = one] : one \in Sample(16) }
        \cup { [ZeroSessionConfigurationRequestMessage EXCEPT !.cancelOnDisconnect = one] : one \in Sample(1) }
        \cup { [ZeroSessionConfigurationRequestMessage EXCEPT !.throttlePreference = one] : one \in Sample(1) }
        \cup { [ZeroSessionConfigurationRequestMessage EXCEPT !.selfTradePrevention = one] : one \in Sample(1) }
        \cup { [ZeroSessionConfigurationRequestMessage EXCEPT !.orderPriorityUpdateAckSubscription = one] : one \in Sample(1) }
        \cup { [ZeroSessionConfigurationRequestMessage EXCEPT !.boldDesignation = one] : one \in Sample(1) }
        \cup { [ZeroSessionConfigurationRequestMessage EXCEPT !.reserved49 = one] : one \in Sample(49) }

(***************************************************************************)
(* Sub Msg Header: 4 bytes                                                 *)
(***************************************************************************)

SubMsgHeader ==
    [ subMsgType   : Sample(2),
      subMsgLength : Sample(2) ]

EncodeSubMsgHeader(message) ==
    message.subMsgType
        \o message.subMsgLength

DecodeSubMsgHeader(bytes) ==
    LET subMsgType == ReadBytes(bytes, 2) IN IF ~subMsgType.ok THEN Fail ELSE
    LET subMsgLength == ReadBytes(subMsgType.rest, 2) IN IF ~subMsgLength.ok THEN Fail ELSE
    Ok([ subMsgType   |-> subMsgType.value,
         subMsgLength |-> subMsgLength.value ], subMsgLength.rest)

ZeroSubMsgHeader ==
    [ subMsgType   |-> [i \in 1 .. 2 |-> 0],
      subMsgLength |-> [i \in 1 .. 2 |-> 0] ]

(* Sub Msg Header at zero, then each field in turn at the values it is checked at *)
CheckedSubMsgHeader ==
    { ZeroSubMsgHeader }
        \cup { [ZeroSubMsgHeader EXCEPT !.subMsgType = one] : one \in Sample(2) }
        \cup { [ZeroSubMsgHeader EXCEPT !.subMsgLength = one] : one \in Sample(2) }

(***************************************************************************)
(* Optional Order Add On: 47 bytes                                         *)
(***************************************************************************)

OptionalOrderAddOn ==
    [ subMsgHeader    : SubMsgHeader,
      stopPx          : Sample(8),
      maxFloor        : Sample(4),
      deliverToCompId : Sample(5),
      clearingFirm    : Sample(5),
      optionalData    : Sample(16),
      clearingAccount : Sample(5) ]

EncodeOptionalOrderAddOn(message) ==
    EncodeSubMsgHeader(message.subMsgHeader)
        \o message.stopPx
        \o message.maxFloor
        \o message.deliverToCompId
        \o message.clearingFirm
        \o message.optionalData
        \o message.clearingAccount

DecodeOptionalOrderAddOn(bytes) ==
    LET subMsgHeader == DecodeSubMsgHeader(bytes) IN IF ~subMsgHeader.ok THEN Fail ELSE
    LET stopPx == ReadBytes(subMsgHeader.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET maxFloor == ReadBytes(stopPx.rest, 4) IN IF ~maxFloor.ok THEN Fail ELSE
    LET deliverToCompId == ReadBytes(maxFloor.rest, 5) IN IF ~deliverToCompId.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(deliverToCompId.rest, 5) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET optionalData == ReadBytes(clearingFirm.rest, 16) IN IF ~optionalData.ok THEN Fail ELSE
    LET clearingAccount == ReadBytes(optionalData.rest, 5) IN IF ~clearingAccount.ok THEN Fail ELSE
    Ok([ subMsgHeader    |-> subMsgHeader.value,
         stopPx          |-> stopPx.value,
         maxFloor        |-> maxFloor.value,
         deliverToCompId |-> deliverToCompId.value,
         clearingFirm    |-> clearingFirm.value,
         optionalData    |-> optionalData.value,
         clearingAccount |-> clearingAccount.value ], clearingAccount.rest)

ZeroOptionalOrderAddOn ==
    [ subMsgHeader    |-> ZeroSubMsgHeader,
      stopPx          |-> [i \in 1 .. 8 |-> 0],
      maxFloor        |-> [i \in 1 .. 4 |-> 0],
      deliverToCompId |-> [i \in 1 .. 5 |-> 0],
      clearingFirm    |-> [i \in 1 .. 5 |-> 0],
      optionalData    |-> [i \in 1 .. 16 |-> 0],
      clearingAccount |-> [i \in 1 .. 5 |-> 0] ]

(* Optional Order Add On at zero, then each field in turn at the values it is checked at *)
CheckedOptionalOrderAddOn ==
    { ZeroOptionalOrderAddOn }
        \cup { [ZeroOptionalOrderAddOn EXCEPT !.subMsgHeader = one] : one \in CheckedSubMsgHeader }
        \cup { [ZeroOptionalOrderAddOn EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroOptionalOrderAddOn EXCEPT !.maxFloor = one] : one \in Sample(4) }
        \cup { [ZeroOptionalOrderAddOn EXCEPT !.deliverToCompId = one] : one \in Sample(5) }
        \cup { [ZeroOptionalOrderAddOn EXCEPT !.clearingFirm = one] : one \in Sample(5) }
        \cup { [ZeroOptionalOrderAddOn EXCEPT !.optionalData = one] : one \in Sample(16) }
        \cup { [ZeroOptionalOrderAddOn EXCEPT !.clearingAccount = one] : one \in Sample(5) }

(***************************************************************************)
(* What Seq Msg Length decides is present                                  *)
(***************************************************************************)

OptionalOrderAddOnCode == 147  \* 0x93
SeqMsgLengthNoneCode == 100  \* 

SeqMsgLengthChoice ==
    [ tag : {OptionalOrderAddOnCode}, body : OptionalOrderAddOn ]
        \cup [ tag : {SeqMsgLengthNoneCode}, body : {[empty |-> 0]} ]

EncodeSeqMsgLengthChoice(message) ==
    CASE message.tag = OptionalOrderAddOnCode -> EncodeOptionalOrderAddOn(message.body)
      [] OTHER -> << >>

DecodeSeqMsgLengthChoice(tag, bytes) ==
    LET read ==
            CASE tag = OptionalOrderAddOnCode -> DecodeOptionalOrderAddOn(bytes)
              [] OTHER -> Ok([empty |-> 0], bytes)
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSeqMsgLengthChoice == [tag |-> OptionalOrderAddOnCode, body |-> ZeroOptionalOrderAddOn]

(* Each Seq Msg Length in turn, at the values the message it names is checked at *)
CheckedSeqMsgLengthChoice ==
    { [tag |-> OptionalOrderAddOnCode, body |-> one] : one \in CheckedOptionalOrderAddOn }
        \cup { [tag |-> SeqMsgLengthNoneCode, body |-> [empty |-> 0]] }

(***************************************************************************)
(* New Order Message                                                       *)
(***************************************************************************)

NewOrderMessage ==
    [ symbolId                  : Sample(4),
      mpid                      : Sample(4),
      marketMaker               : Sample(10),
      mpSubId                   : Sample(4),
      clOrdId                   : Sample(8),
      origClOrdId               : Sample(8),
      bitfieldOrderInstructions : Sample(16),
      price                     : Sample(8),
      orderQty                  : Sample(4),
      minQty                    : Sample(4),
      userData                  : Sample(10),
      legOpenClose              : Sample(8),
      auctionId                 : Sample(8),
      seqMsgLengthChoice        : SeqMsgLengthChoice ]

EncodeNewOrderMessage(message) ==
    message.symbolId
        \o message.mpid
        \o message.marketMaker
        \o message.mpSubId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.bitfieldOrderInstructions
        \o message.price
        \o message.orderQty
        \o message.minQty
        \o message.userData
        \o message.legOpenClose
        \o message.auctionId
        \o EncodeSeqMsgLengthChoice(message.seqMsgLengthChoice)

DecodeNewOrderMessage(bytes) ==
    LET symbolId == ReadBytes(bytes, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET mpid == ReadBytes(symbolId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET marketMaker == ReadBytes(mpid.rest, 10) IN IF ~marketMaker.ok THEN Fail ELSE
    LET mpSubId == ReadBytes(marketMaker.rest, 4) IN IF ~mpSubId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(mpSubId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET bitfieldOrderInstructions == ReadBytes(origClOrdId.rest, 16) IN IF ~bitfieldOrderInstructions.ok THEN Fail ELSE
    LET price == ReadBytes(bitfieldOrderInstructions.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderQty == ReadBytes(price.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET minQty == ReadBytes(orderQty.rest, 4) IN IF ~minQty.ok THEN Fail ELSE
    LET userData == ReadBytes(minQty.rest, 10) IN IF ~userData.ok THEN Fail ELSE
    LET legOpenClose == ReadBytes(userData.rest, 8) IN IF ~legOpenClose.ok THEN Fail ELSE
    LET auctionId == ReadBytes(legOpenClose.rest, 8) IN IF ~auctionId.ok THEN Fail ELSE
    LET seqMsgLengthChoice == DecodeSeqMsgLengthChoice(Len(bytes) + 4, auctionId.rest) IN IF ~seqMsgLengthChoice.ok THEN Fail ELSE
    Ok([ symbolId                  |-> symbolId.value,
         mpid                      |-> mpid.value,
         marketMaker               |-> marketMaker.value,
         mpSubId                   |-> mpSubId.value,
         clOrdId                   |-> clOrdId.value,
         origClOrdId               |-> origClOrdId.value,
         bitfieldOrderInstructions |-> bitfieldOrderInstructions.value,
         price                     |-> price.value,
         orderQty                  |-> orderQty.value,
         minQty                    |-> minQty.value,
         userData                  |-> userData.value,
         legOpenClose              |-> legOpenClose.value,
         auctionId                 |-> auctionId.value,
         seqMsgLengthChoice        |-> seqMsgLengthChoice.value ], seqMsgLengthChoice.rest)

ZeroNewOrderMessage ==
    [ symbolId                  |-> [i \in 1 .. 4 |-> 0],
      mpid                      |-> [i \in 1 .. 4 |-> 0],
      marketMaker               |-> [i \in 1 .. 10 |-> 0],
      mpSubId                   |-> [i \in 1 .. 4 |-> 0],
      clOrdId                   |-> [i \in 1 .. 8 |-> 0],
      origClOrdId               |-> [i \in 1 .. 8 |-> 0],
      bitfieldOrderInstructions |-> [i \in 1 .. 16 |-> 0],
      price                     |-> [i \in 1 .. 8 |-> 0],
      orderQty                  |-> [i \in 1 .. 4 |-> 0],
      minQty                    |-> [i \in 1 .. 4 |-> 0],
      userData                  |-> [i \in 1 .. 10 |-> 0],
      legOpenClose              |-> [i \in 1 .. 8 |-> 0],
      auctionId                 |-> [i \in 1 .. 8 |-> 0],
      seqMsgLengthChoice        |-> ZeroSeqMsgLengthChoice ]

(* New Order Message at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderMessage ==
    { ZeroNewOrderMessage }
        \cup { [ZeroNewOrderMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderMessage EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderMessage EXCEPT !.marketMaker = one] : one \in Sample(10) }
        \cup { [ZeroNewOrderMessage EXCEPT !.mpSubId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderMessage EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderMessage EXCEPT !.bitfieldOrderInstructions = one] : one \in Sample(16) }
        \cup { [ZeroNewOrderMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderMessage EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderMessage EXCEPT !.userData = one] : one \in Sample(10) }
        \cup { [ZeroNewOrderMessage EXCEPT !.legOpenClose = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderMessage EXCEPT !.auctionId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderMessage EXCEPT !.seqMsgLengthChoice = one] : one \in CheckedSeqMsgLengthChoice }

(***************************************************************************)
(* Order Cancel Request Message: 24 bytes                                  *)
(***************************************************************************)

OrderCancelRequestMessage ==
    [ symbolId    : Sample(4),
      mpid        : Sample(4),
      clOrdId     : Sample(8),
      origClOrdId : Sample(8) ]

EncodeOrderCancelRequestMessage(message) ==
    message.symbolId
        \o message.mpid
        \o message.clOrdId
        \o message.origClOrdId

DecodeOrderCancelRequestMessage(bytes) ==
    LET symbolId == ReadBytes(bytes, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET mpid == ReadBytes(symbolId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(mpid.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    Ok([ symbolId    |-> symbolId.value,
         mpid        |-> mpid.value,
         clOrdId     |-> clOrdId.value,
         origClOrdId |-> origClOrdId.value ], origClOrdId.rest)

ZeroOrderCancelRequestMessage ==
    [ symbolId    |-> [i \in 1 .. 4 |-> 0],
      mpid        |-> [i \in 1 .. 4 |-> 0],
      clOrdId     |-> [i \in 1 .. 8 |-> 0],
      origClOrdId |-> [i \in 1 .. 8 |-> 0] ]

(* Order Cancel Request Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelRequestMessage ==
    { ZeroOrderCancelRequestMessage }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.origClOrdId = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Modify Request Message: 30 bytes                                  *)
(***************************************************************************)

OrderModifyRequestMessage ==
    [ symbolId      : Sample(4),
      mpid          : Sample(4),
      clOrdId       : Sample(8),
      origClOrdId   : Sample(8),
      orderQty      : Sample(4),
      sideU81       : Sample(1),
      locateReqdU81 : Sample(1) ]

EncodeOrderModifyRequestMessage(message) ==
    message.symbolId
        \o message.mpid
        \o message.clOrdId
        \o message.origClOrdId
        \o message.orderQty
        \o message.sideU81
        \o message.locateReqdU81

DecodeOrderModifyRequestMessage(bytes) ==
    LET symbolId == ReadBytes(bytes, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET mpid == ReadBytes(symbolId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(mpid.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(origClOrdId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET sideU81 == ReadBytes(orderQty.rest, 1) IN IF ~sideU81.ok THEN Fail ELSE
    LET locateReqdU81 == ReadBytes(sideU81.rest, 1) IN IF ~locateReqdU81.ok THEN Fail ELSE
    Ok([ symbolId      |-> symbolId.value,
         mpid          |-> mpid.value,
         clOrdId       |-> clOrdId.value,
         origClOrdId   |-> origClOrdId.value,
         orderQty      |-> orderQty.value,
         sideU81       |-> sideU81.value,
         locateReqdU81 |-> locateReqdU81.value ], locateReqdU81.rest)

ZeroOrderModifyRequestMessage ==
    [ symbolId      |-> [i \in 1 .. 4 |-> 0],
      mpid          |-> [i \in 1 .. 4 |-> 0],
      clOrdId       |-> [i \in 1 .. 8 |-> 0],
      origClOrdId   |-> [i \in 1 .. 8 |-> 0],
      orderQty      |-> [i \in 1 .. 4 |-> 0],
      sideU81       |-> [i \in 1 .. 1 |-> 0],
      locateReqdU81 |-> [i \in 1 .. 1 |-> 0] ]

(* Order Modify Request Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderModifyRequestMessage ==
    { ZeroOrderModifyRequestMessage }
        \cup { [ZeroOrderModifyRequestMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyRequestMessage EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyRequestMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyRequestMessage EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyRequestMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyRequestMessage EXCEPT !.sideU81 = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifyRequestMessage EXCEPT !.locateReqdU81 = one] : one \in Sample(1) }

(***************************************************************************)
(* Quote Request Group: 17 bytes                                           *)
(***************************************************************************)

QuoteRequestGroup ==
    [ seriesIndex       : Sample(4),
      bitfieldQuoteInst : Sample(1),
      price             : Sample(8),
      orderQty          : Sample(4) ]

EncodeQuoteRequestGroup(message) ==
    message.seriesIndex
        \o message.bitfieldQuoteInst
        \o message.price
        \o message.orderQty

DecodeQuoteRequestGroup(bytes) ==
    LET seriesIndex == ReadBytes(bytes, 4) IN IF ~seriesIndex.ok THEN Fail ELSE
    LET bitfieldQuoteInst == ReadBytes(seriesIndex.rest, 1) IN IF ~bitfieldQuoteInst.ok THEN Fail ELSE
    LET price == ReadBytes(bitfieldQuoteInst.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderQty == ReadBytes(price.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    Ok([ seriesIndex       |-> seriesIndex.value,
         bitfieldQuoteInst |-> bitfieldQuoteInst.value,
         price             |-> price.value,
         orderQty          |-> orderQty.value ], orderQty.rest)

ZeroQuoteRequestGroup ==
    [ seriesIndex       |-> [i \in 1 .. 4 |-> 0],
      bitfieldQuoteInst |-> [i \in 1 .. 1 |-> 0],
      price             |-> [i \in 1 .. 8 |-> 0],
      orderQty          |-> [i \in 1 .. 4 |-> 0] ]

(* Quote Request Group at zero, then each field in turn at the values it is checked at *)
CheckedQuoteRequestGroup ==
    { ZeroQuoteRequestGroup }
        \cup { [ZeroQuoteRequestGroup EXCEPT !.seriesIndex = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRequestGroup EXCEPT !.bitfieldQuoteInst = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRequestGroup EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRequestGroup EXCEPT !.orderQty = one] : one \in Sample(4) }

(* A run of Quote Request Group, written one after another *)
RECURSIVE EncodeQuoteRequestGroupList(_)
EncodeQuoteRequestGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeQuoteRequestGroup(Head(messages)) \o EncodeQuoteRequestGroupList(Tail(messages))

(* As many Quote Request Group as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadQuoteRequestGroupAll(_)
ReadQuoteRequestGroupAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeQuoteRequestGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadQuoteRequestGroupAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Quote Request Group of each kind, for the lists that carry them *)
OneQuoteRequestGroup == { ZeroQuoteRequestGroup }

(***************************************************************************)
(* New Bulk Quote Type 243 Message                                         *)
(***************************************************************************)

NewBulkQuoteType243Message ==
    [ mpid              : Sample(4),
      marketMaker       : Sample(10),
      subId             : Sample(4),
      clOrdId           : Sample(8),
      selfTradeTypeU81  : Sample(1),
      groupId           : Sample(4),
      mmSentTime        : Sample(8),
      quoteRequestGroup : SampleLists(OneQuoteRequestGroup) ]

EncodeNewBulkQuoteType243Message(message) ==
    message.mpid
        \o message.marketMaker
        \o message.subId
        \o message.clOrdId
        \o message.selfTradeTypeU81
        \o message.groupId
        \o message.mmSentTime
        \o EncodeQuoteRequestGroupList(message.quoteRequestGroup)

DecodeNewBulkQuoteType243Message(bytes) ==
    LET mpid == ReadBytes(bytes, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET marketMaker == ReadBytes(mpid.rest, 10) IN IF ~marketMaker.ok THEN Fail ELSE
    LET subId == ReadBytes(marketMaker.rest, 4) IN IF ~subId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(subId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET selfTradeTypeU81 == ReadBytes(clOrdId.rest, 1) IN IF ~selfTradeTypeU81.ok THEN Fail ELSE
    LET groupId == ReadBytes(selfTradeTypeU81.rest, 4) IN IF ~groupId.ok THEN Fail ELSE
    LET mmSentTime == ReadBytes(groupId.rest, 8) IN IF ~mmSentTime.ok THEN Fail ELSE
    LET quoteRequestGroup == ReadQuoteRequestGroupAll(mmSentTime.rest) IN IF ~quoteRequestGroup.ok THEN Fail ELSE
    Ok([ mpid              |-> mpid.value,
         marketMaker       |-> marketMaker.value,
         subId             |-> subId.value,
         clOrdId           |-> clOrdId.value,
         selfTradeTypeU81  |-> selfTradeTypeU81.value,
         groupId           |-> groupId.value,
         mmSentTime        |-> mmSentTime.value,
         quoteRequestGroup |-> quoteRequestGroup.value ], quoteRequestGroup.rest)

ZeroNewBulkQuoteType243Message ==
    [ mpid              |-> [i \in 1 .. 4 |-> 0],
      marketMaker       |-> [i \in 1 .. 10 |-> 0],
      subId             |-> [i \in 1 .. 4 |-> 0],
      clOrdId           |-> [i \in 1 .. 8 |-> 0],
      selfTradeTypeU81  |-> [i \in 1 .. 1 |-> 0],
      groupId           |-> [i \in 1 .. 4 |-> 0],
      mmSentTime        |-> [i \in 1 .. 8 |-> 0],
      quoteRequestGroup |-> << >> ]

(* New Bulk Quote Type 243 Message at zero, then each field in turn at the values it is checked at *)
CheckedNewBulkQuoteType243Message ==
    { ZeroNewBulkQuoteType243Message }
        \cup { [ZeroNewBulkQuoteType243Message EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroNewBulkQuoteType243Message EXCEPT !.marketMaker = one] : one \in Sample(10) }
        \cup { [ZeroNewBulkQuoteType243Message EXCEPT !.subId = one] : one \in Sample(4) }
        \cup { [ZeroNewBulkQuoteType243Message EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroNewBulkQuoteType243Message EXCEPT !.selfTradeTypeU81 = one] : one \in Sample(1) }
        \cup { [ZeroNewBulkQuoteType243Message EXCEPT !.groupId = one] : one \in Sample(4) }
        \cup { [ZeroNewBulkQuoteType243Message EXCEPT !.mmSentTime = one] : one \in Sample(8) }
        \cup { [ZeroNewBulkQuoteType243Message EXCEPT !.quoteRequestGroup = one] : one \in SampleLists(OneQuoteRequestGroup) }

(***************************************************************************)
(* Quote Request Group: 17 bytes                                           *)
(***************************************************************************)

QuoteRequestGroup2 ==
    [ seriesIndex       : Sample(4),
      bitfieldQuoteInst : Sample(1),
      price             : Sample(8),
      orderQty          : Sample(4) ]

EncodeQuoteRequestGroup2(message) ==
    message.seriesIndex
        \o message.bitfieldQuoteInst
        \o message.price
        \o message.orderQty

DecodeQuoteRequestGroup2(bytes) ==
    LET seriesIndex == ReadBytes(bytes, 4) IN IF ~seriesIndex.ok THEN Fail ELSE
    LET bitfieldQuoteInst == ReadBytes(seriesIndex.rest, 1) IN IF ~bitfieldQuoteInst.ok THEN Fail ELSE
    LET price == ReadBytes(bitfieldQuoteInst.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderQty == ReadBytes(price.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    Ok([ seriesIndex       |-> seriesIndex.value,
         bitfieldQuoteInst |-> bitfieldQuoteInst.value,
         price             |-> price.value,
         orderQty          |-> orderQty.value ], orderQty.rest)

ZeroQuoteRequestGroup2 ==
    [ seriesIndex       |-> [i \in 1 .. 4 |-> 0],
      bitfieldQuoteInst |-> [i \in 1 .. 1 |-> 0],
      price             |-> [i \in 1 .. 8 |-> 0],
      orderQty          |-> [i \in 1 .. 4 |-> 0] ]

(* Quote Request Group at zero, then each field in turn at the values it is checked at *)
CheckedQuoteRequestGroup2 ==
    { ZeroQuoteRequestGroup2 }
        \cup { [ZeroQuoteRequestGroup2 EXCEPT !.seriesIndex = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRequestGroup2 EXCEPT !.bitfieldQuoteInst = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRequestGroup2 EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRequestGroup2 EXCEPT !.orderQty = one] : one \in Sample(4) }

(* A run of Quote Request Group, written one after another *)
RECURSIVE EncodeQuoteRequestGroup2List(_)
EncodeQuoteRequestGroup2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeQuoteRequestGroup2(Head(messages)) \o EncodeQuoteRequestGroup2List(Tail(messages))

(* As many Quote Request Group as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadQuoteRequestGroup2All(_)
ReadQuoteRequestGroup2All(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeQuoteRequestGroup2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadQuoteRequestGroup2All(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Quote Request Group of each kind, for the lists that carry them *)
OneQuoteRequestGroup2 == { ZeroQuoteRequestGroup2 }

(***************************************************************************)
(* New Bulk Quote Type 259 Message                                         *)
(***************************************************************************)

NewBulkQuoteType259Message ==
    [ mpid              : Sample(4),
      marketMaker       : Sample(10),
      subId             : Sample(4),
      clOrdId           : Sample(8),
      selfTradeTypeU81  : Sample(1),
      groupId           : Sample(4),
      mmSentTime        : Sample(8),
      quoteRequestGroup : SampleLists(OneQuoteRequestGroup2) ]

EncodeNewBulkQuoteType259Message(message) ==
    message.mpid
        \o message.marketMaker
        \o message.subId
        \o message.clOrdId
        \o message.selfTradeTypeU81
        \o message.groupId
        \o message.mmSentTime
        \o EncodeQuoteRequestGroup2List(message.quoteRequestGroup)

DecodeNewBulkQuoteType259Message(bytes) ==
    LET mpid == ReadBytes(bytes, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET marketMaker == ReadBytes(mpid.rest, 10) IN IF ~marketMaker.ok THEN Fail ELSE
    LET subId == ReadBytes(marketMaker.rest, 4) IN IF ~subId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(subId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET selfTradeTypeU81 == ReadBytes(clOrdId.rest, 1) IN IF ~selfTradeTypeU81.ok THEN Fail ELSE
    LET groupId == ReadBytes(selfTradeTypeU81.rest, 4) IN IF ~groupId.ok THEN Fail ELSE
    LET mmSentTime == ReadBytes(groupId.rest, 8) IN IF ~mmSentTime.ok THEN Fail ELSE
    LET quoteRequestGroup == ReadQuoteRequestGroup2All(mmSentTime.rest) IN IF ~quoteRequestGroup.ok THEN Fail ELSE
    Ok([ mpid              |-> mpid.value,
         marketMaker       |-> marketMaker.value,
         subId             |-> subId.value,
         clOrdId           |-> clOrdId.value,
         selfTradeTypeU81  |-> selfTradeTypeU81.value,
         groupId           |-> groupId.value,
         mmSentTime        |-> mmSentTime.value,
         quoteRequestGroup |-> quoteRequestGroup.value ], quoteRequestGroup.rest)

ZeroNewBulkQuoteType259Message ==
    [ mpid              |-> [i \in 1 .. 4 |-> 0],
      marketMaker       |-> [i \in 1 .. 10 |-> 0],
      subId             |-> [i \in 1 .. 4 |-> 0],
      clOrdId           |-> [i \in 1 .. 8 |-> 0],
      selfTradeTypeU81  |-> [i \in 1 .. 1 |-> 0],
      groupId           |-> [i \in 1 .. 4 |-> 0],
      mmSentTime        |-> [i \in 1 .. 8 |-> 0],
      quoteRequestGroup |-> << >> ]

(* New Bulk Quote Type 259 Message at zero, then each field in turn at the values it is checked at *)
CheckedNewBulkQuoteType259Message ==
    { ZeroNewBulkQuoteType259Message }
        \cup { [ZeroNewBulkQuoteType259Message EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroNewBulkQuoteType259Message EXCEPT !.marketMaker = one] : one \in Sample(10) }
        \cup { [ZeroNewBulkQuoteType259Message EXCEPT !.subId = one] : one \in Sample(4) }
        \cup { [ZeroNewBulkQuoteType259Message EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroNewBulkQuoteType259Message EXCEPT !.selfTradeTypeU81 = one] : one \in Sample(1) }
        \cup { [ZeroNewBulkQuoteType259Message EXCEPT !.groupId = one] : one \in Sample(4) }
        \cup { [ZeroNewBulkQuoteType259Message EXCEPT !.mmSentTime = one] : one \in Sample(8) }
        \cup { [ZeroNewBulkQuoteType259Message EXCEPT !.quoteRequestGroup = one] : one \in SampleLists(OneQuoteRequestGroup2) }

(***************************************************************************)
(* Sub Msg Header: 4 bytes                                                 *)
(***************************************************************************)

SubMsgHeader2 ==
    [ subMsgType   : Sample(2),
      subMsgLength : Sample(2) ]

EncodeSubMsgHeader2(message) ==
    message.subMsgType
        \o message.subMsgLength

DecodeSubMsgHeader2(bytes) ==
    LET subMsgType == ReadBytes(bytes, 2) IN IF ~subMsgType.ok THEN Fail ELSE
    LET subMsgLength == ReadBytes(subMsgType.rest, 2) IN IF ~subMsgLength.ok THEN Fail ELSE
    Ok([ subMsgType   |-> subMsgType.value,
         subMsgLength |-> subMsgLength.value ], subMsgLength.rest)

ZeroSubMsgHeader2 ==
    [ subMsgType   |-> [i \in 1 .. 2 |-> 0],
      subMsgLength |-> [i \in 1 .. 2 |-> 0] ]

(* Sub Msg Header at zero, then each field in turn at the values it is checked at *)
CheckedSubMsgHeader2 ==
    { ZeroSubMsgHeader2 }
        \cup { [ZeroSubMsgHeader2 EXCEPT !.subMsgType = one] : one \in Sample(2) }
        \cup { [ZeroSubMsgHeader2 EXCEPT !.subMsgLength = one] : one \in Sample(2) }

(***************************************************************************)
(* Exposed: 100 bytes                                                      *)
(***************************************************************************)

Exposed ==
    [ subMsgHeader              : SubMsgHeader2,
      symbolId                  : Sample(4),
      mpid                      : Sample(4),
      marketMaker               : Sample(10),
      mpSubId                   : Sample(4),
      clOrdId                   : Sample(8),
      origClOrdId               : Sample(8),
      bitfieldOrderInstructions : Sample(16),
      price                     : Sample(8),
      orderQty                  : Sample(4),
      minQty                    : Sample(4),
      userData                  : Sample(10),
      legOpenClose              : Sample(8),
      auctionId                 : Sample(8) ]

EncodeExposed(message) ==
    EncodeSubMsgHeader2(message.subMsgHeader)
        \o message.symbolId
        \o message.mpid
        \o message.marketMaker
        \o message.mpSubId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.bitfieldOrderInstructions
        \o message.price
        \o message.orderQty
        \o message.minQty
        \o message.userData
        \o message.legOpenClose
        \o message.auctionId

DecodeExposed(bytes) ==
    LET subMsgHeader == DecodeSubMsgHeader2(bytes) IN IF ~subMsgHeader.ok THEN Fail ELSE
    LET symbolId == ReadBytes(subMsgHeader.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET mpid == ReadBytes(symbolId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET marketMaker == ReadBytes(mpid.rest, 10) IN IF ~marketMaker.ok THEN Fail ELSE
    LET mpSubId == ReadBytes(marketMaker.rest, 4) IN IF ~mpSubId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(mpSubId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET bitfieldOrderInstructions == ReadBytes(origClOrdId.rest, 16) IN IF ~bitfieldOrderInstructions.ok THEN Fail ELSE
    LET price == ReadBytes(bitfieldOrderInstructions.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderQty == ReadBytes(price.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET minQty == ReadBytes(orderQty.rest, 4) IN IF ~minQty.ok THEN Fail ELSE
    LET userData == ReadBytes(minQty.rest, 10) IN IF ~userData.ok THEN Fail ELSE
    LET legOpenClose == ReadBytes(userData.rest, 8) IN IF ~legOpenClose.ok THEN Fail ELSE
    LET auctionId == ReadBytes(legOpenClose.rest, 8) IN IF ~auctionId.ok THEN Fail ELSE
    Ok([ subMsgHeader              |-> subMsgHeader.value,
         symbolId                  |-> symbolId.value,
         mpid                      |-> mpid.value,
         marketMaker               |-> marketMaker.value,
         mpSubId                   |-> mpSubId.value,
         clOrdId                   |-> clOrdId.value,
         origClOrdId               |-> origClOrdId.value,
         bitfieldOrderInstructions |-> bitfieldOrderInstructions.value,
         price                     |-> price.value,
         orderQty                  |-> orderQty.value,
         minQty                    |-> minQty.value,
         userData                  |-> userData.value,
         legOpenClose              |-> legOpenClose.value,
         auctionId                 |-> auctionId.value ], auctionId.rest)

ZeroExposed ==
    [ subMsgHeader              |-> ZeroSubMsgHeader2,
      symbolId                  |-> [i \in 1 .. 4 |-> 0],
      mpid                      |-> [i \in 1 .. 4 |-> 0],
      marketMaker               |-> [i \in 1 .. 10 |-> 0],
      mpSubId                   |-> [i \in 1 .. 4 |-> 0],
      clOrdId                   |-> [i \in 1 .. 8 |-> 0],
      origClOrdId               |-> [i \in 1 .. 8 |-> 0],
      bitfieldOrderInstructions |-> [i \in 1 .. 16 |-> 0],
      price                     |-> [i \in 1 .. 8 |-> 0],
      orderQty                  |-> [i \in 1 .. 4 |-> 0],
      minQty                    |-> [i \in 1 .. 4 |-> 0],
      userData                  |-> [i \in 1 .. 10 |-> 0],
      legOpenClose              |-> [i \in 1 .. 8 |-> 0],
      auctionId                 |-> [i \in 1 .. 8 |-> 0] ]

(* Exposed at zero, then each field in turn at the values it is checked at *)
CheckedExposed ==
    { ZeroExposed }
        \cup { [ZeroExposed EXCEPT !.subMsgHeader = one] : one \in CheckedSubMsgHeader2 }
        \cup { [ZeroExposed EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroExposed EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroExposed EXCEPT !.marketMaker = one] : one \in Sample(10) }
        \cup { [ZeroExposed EXCEPT !.mpSubId = one] : one \in Sample(4) }
        \cup { [ZeroExposed EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroExposed EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroExposed EXCEPT !.bitfieldOrderInstructions = one] : one \in Sample(16) }
        \cup { [ZeroExposed EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroExposed EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroExposed EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroExposed EXCEPT !.userData = one] : one \in Sample(10) }
        \cup { [ZeroExposed EXCEPT !.legOpenClose = one] : one \in Sample(8) }
        \cup { [ZeroExposed EXCEPT !.auctionId = one] : one \in Sample(8) }

(***************************************************************************)
(* Sub Msg Header: 4 bytes                                                 *)
(***************************************************************************)

SubMsgHeader3 ==
    [ subMsgType   : Sample(2),
      subMsgLength : Sample(2) ]

EncodeSubMsgHeader3(message) ==
    message.subMsgType
        \o message.subMsgLength

DecodeSubMsgHeader3(bytes) ==
    LET subMsgType == ReadBytes(bytes, 2) IN IF ~subMsgType.ok THEN Fail ELSE
    LET subMsgLength == ReadBytes(subMsgType.rest, 2) IN IF ~subMsgLength.ok THEN Fail ELSE
    Ok([ subMsgType   |-> subMsgType.value,
         subMsgLength |-> subMsgLength.value ], subMsgLength.rest)

ZeroSubMsgHeader3 ==
    [ subMsgType   |-> [i \in 1 .. 2 |-> 0],
      subMsgLength |-> [i \in 1 .. 2 |-> 0] ]

(* Sub Msg Header at zero, then each field in turn at the values it is checked at *)
CheckedSubMsgHeader3 ==
    { ZeroSubMsgHeader3 }
        \cup { [ZeroSubMsgHeader3 EXCEPT !.subMsgType = one] : one \in Sample(2) }
        \cup { [ZeroSubMsgHeader3 EXCEPT !.subMsgLength = one] : one \in Sample(2) }

(***************************************************************************)
(* Covered: 100 bytes                                                      *)
(***************************************************************************)

Covered ==
    [ subMsgHeader              : SubMsgHeader3,
      symbolId                  : Sample(4),
      mpid                      : Sample(4),
      marketMaker               : Sample(10),
      mpSubId                   : Sample(4),
      clOrdId                   : Sample(8),
      origClOrdId               : Sample(8),
      bitfieldOrderInstructions : Sample(16),
      price                     : Sample(8),
      orderQty                  : Sample(4),
      minQty                    : Sample(4),
      userData                  : Sample(10),
      legOpenClose              : Sample(8),
      auctionId                 : Sample(8) ]

EncodeCovered(message) ==
    EncodeSubMsgHeader3(message.subMsgHeader)
        \o message.symbolId
        \o message.mpid
        \o message.marketMaker
        \o message.mpSubId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.bitfieldOrderInstructions
        \o message.price
        \o message.orderQty
        \o message.minQty
        \o message.userData
        \o message.legOpenClose
        \o message.auctionId

DecodeCovered(bytes) ==
    LET subMsgHeader == DecodeSubMsgHeader3(bytes) IN IF ~subMsgHeader.ok THEN Fail ELSE
    LET symbolId == ReadBytes(subMsgHeader.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET mpid == ReadBytes(symbolId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET marketMaker == ReadBytes(mpid.rest, 10) IN IF ~marketMaker.ok THEN Fail ELSE
    LET mpSubId == ReadBytes(marketMaker.rest, 4) IN IF ~mpSubId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(mpSubId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET bitfieldOrderInstructions == ReadBytes(origClOrdId.rest, 16) IN IF ~bitfieldOrderInstructions.ok THEN Fail ELSE
    LET price == ReadBytes(bitfieldOrderInstructions.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderQty == ReadBytes(price.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET minQty == ReadBytes(orderQty.rest, 4) IN IF ~minQty.ok THEN Fail ELSE
    LET userData == ReadBytes(minQty.rest, 10) IN IF ~userData.ok THEN Fail ELSE
    LET legOpenClose == ReadBytes(userData.rest, 8) IN IF ~legOpenClose.ok THEN Fail ELSE
    LET auctionId == ReadBytes(legOpenClose.rest, 8) IN IF ~auctionId.ok THEN Fail ELSE
    Ok([ subMsgHeader              |-> subMsgHeader.value,
         symbolId                  |-> symbolId.value,
         mpid                      |-> mpid.value,
         marketMaker               |-> marketMaker.value,
         mpSubId                   |-> mpSubId.value,
         clOrdId                   |-> clOrdId.value,
         origClOrdId               |-> origClOrdId.value,
         bitfieldOrderInstructions |-> bitfieldOrderInstructions.value,
         price                     |-> price.value,
         orderQty                  |-> orderQty.value,
         minQty                    |-> minQty.value,
         userData                  |-> userData.value,
         legOpenClose              |-> legOpenClose.value,
         auctionId                 |-> auctionId.value ], auctionId.rest)

ZeroCovered ==
    [ subMsgHeader              |-> ZeroSubMsgHeader3,
      symbolId                  |-> [i \in 1 .. 4 |-> 0],
      mpid                      |-> [i \in 1 .. 4 |-> 0],
      marketMaker               |-> [i \in 1 .. 10 |-> 0],
      mpSubId                   |-> [i \in 1 .. 4 |-> 0],
      clOrdId                   |-> [i \in 1 .. 8 |-> 0],
      origClOrdId               |-> [i \in 1 .. 8 |-> 0],
      bitfieldOrderInstructions |-> [i \in 1 .. 16 |-> 0],
      price                     |-> [i \in 1 .. 8 |-> 0],
      orderQty                  |-> [i \in 1 .. 4 |-> 0],
      minQty                    |-> [i \in 1 .. 4 |-> 0],
      userData                  |-> [i \in 1 .. 10 |-> 0],
      legOpenClose              |-> [i \in 1 .. 8 |-> 0],
      auctionId                 |-> [i \in 1 .. 8 |-> 0] ]

(* Covered at zero, then each field in turn at the values it is checked at *)
CheckedCovered ==
    { ZeroCovered }
        \cup { [ZeroCovered EXCEPT !.subMsgHeader = one] : one \in CheckedSubMsgHeader3 }
        \cup { [ZeroCovered EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroCovered EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroCovered EXCEPT !.marketMaker = one] : one \in Sample(10) }
        \cup { [ZeroCovered EXCEPT !.mpSubId = one] : one \in Sample(4) }
        \cup { [ZeroCovered EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroCovered EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroCovered EXCEPT !.bitfieldOrderInstructions = one] : one \in Sample(16) }
        \cup { [ZeroCovered EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroCovered EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroCovered EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroCovered EXCEPT !.userData = one] : one \in Sample(10) }
        \cup { [ZeroCovered EXCEPT !.legOpenClose = one] : one \in Sample(8) }
        \cup { [ZeroCovered EXCEPT !.auctionId = one] : one \in Sample(8) }

(***************************************************************************)
(* New Order Cross Message: 277 bytes                                      *)
(***************************************************************************)

NewOrderCrossMessage ==
    [ crossId                : Sample(8),
      allocationPct          : Sample(1),
      clearingFirmExposed    : Sample(5),
      clearingAccountExposed : Sample(5),
      optionalDataExposed    : Sample(16),
      clearingFirmCovered    : Sample(5),
      clearingAccountCovered : Sample(5),
      optionalDataCovered    : Sample(16),
      reserved16             : Sample(16),
      exposed                : Exposed,
      covered                : Covered ]

EncodeNewOrderCrossMessage(message) ==
    message.crossId
        \o message.allocationPct
        \o message.clearingFirmExposed
        \o message.clearingAccountExposed
        \o message.optionalDataExposed
        \o message.clearingFirmCovered
        \o message.clearingAccountCovered
        \o message.optionalDataCovered
        \o message.reserved16
        \o EncodeExposed(message.exposed)
        \o EncodeCovered(message.covered)

DecodeNewOrderCrossMessage(bytes) ==
    LET crossId == ReadBytes(bytes, 8) IN IF ~crossId.ok THEN Fail ELSE
    LET allocationPct == ReadBytes(crossId.rest, 1) IN IF ~allocationPct.ok THEN Fail ELSE
    LET clearingFirmExposed == ReadBytes(allocationPct.rest, 5) IN IF ~clearingFirmExposed.ok THEN Fail ELSE
    LET clearingAccountExposed == ReadBytes(clearingFirmExposed.rest, 5) IN IF ~clearingAccountExposed.ok THEN Fail ELSE
    LET optionalDataExposed == ReadBytes(clearingAccountExposed.rest, 16) IN IF ~optionalDataExposed.ok THEN Fail ELSE
    LET clearingFirmCovered == ReadBytes(optionalDataExposed.rest, 5) IN IF ~clearingFirmCovered.ok THEN Fail ELSE
    LET clearingAccountCovered == ReadBytes(clearingFirmCovered.rest, 5) IN IF ~clearingAccountCovered.ok THEN Fail ELSE
    LET optionalDataCovered == ReadBytes(clearingAccountCovered.rest, 16) IN IF ~optionalDataCovered.ok THEN Fail ELSE
    LET reserved16 == ReadBytes(optionalDataCovered.rest, 16) IN IF ~reserved16.ok THEN Fail ELSE
    LET exposed == DecodeExposed(reserved16.rest) IN IF ~exposed.ok THEN Fail ELSE
    LET covered == DecodeCovered(exposed.rest) IN IF ~covered.ok THEN Fail ELSE
    Ok([ crossId                |-> crossId.value,
         allocationPct          |-> allocationPct.value,
         clearingFirmExposed    |-> clearingFirmExposed.value,
         clearingAccountExposed |-> clearingAccountExposed.value,
         optionalDataExposed    |-> optionalDataExposed.value,
         clearingFirmCovered    |-> clearingFirmCovered.value,
         clearingAccountCovered |-> clearingAccountCovered.value,
         optionalDataCovered    |-> optionalDataCovered.value,
         reserved16             |-> reserved16.value,
         exposed                |-> exposed.value,
         covered                |-> covered.value ], covered.rest)

ZeroNewOrderCrossMessage ==
    [ crossId                |-> [i \in 1 .. 8 |-> 0],
      allocationPct          |-> [i \in 1 .. 1 |-> 0],
      clearingFirmExposed    |-> [i \in 1 .. 5 |-> 0],
      clearingAccountExposed |-> [i \in 1 .. 5 |-> 0],
      optionalDataExposed    |-> [i \in 1 .. 16 |-> 0],
      clearingFirmCovered    |-> [i \in 1 .. 5 |-> 0],
      clearingAccountCovered |-> [i \in 1 .. 5 |-> 0],
      optionalDataCovered    |-> [i \in 1 .. 16 |-> 0],
      reserved16             |-> [i \in 1 .. 16 |-> 0],
      exposed                |-> ZeroExposed,
      covered                |-> ZeroCovered ]

(* New Order Cross Message at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderCrossMessage ==
    { ZeroNewOrderCrossMessage }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.crossId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.allocationPct = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.clearingFirmExposed = one] : one \in Sample(5) }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.clearingAccountExposed = one] : one \in Sample(5) }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.optionalDataExposed = one] : one \in Sample(16) }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.clearingFirmCovered = one] : one \in Sample(5) }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.clearingAccountCovered = one] : one \in Sample(5) }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.optionalDataCovered = one] : one \in Sample(16) }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.reserved16 = one] : one \in Sample(16) }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.exposed = one] : one \in CheckedExposed }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.covered = one] : one \in CheckedCovered }

(***************************************************************************)
(* Bulk Cancel Request Type 223 Message: 61 bytes                          *)
(***************************************************************************)

BulkCancelRequestType223Message ==
    [ symbolId             : Sample(4),
      mpid                 : Sample(4),
      marketMaker          : Sample(10),
      clOrdId              : Sample(8),
      mmSentTime           : Sample(8),
      sideU81              : Sample(1),
      groupId              : Sample(4),
      targetCancelUsername : Sample(16),
      bulkAction           : Sample(1),
      cancelScope          : Sample(1),
      targetCancelMpid     : Sample(4) ]

EncodeBulkCancelRequestType223Message(message) ==
    message.symbolId
        \o message.mpid
        \o message.marketMaker
        \o message.clOrdId
        \o message.mmSentTime
        \o message.sideU81
        \o message.groupId
        \o message.targetCancelUsername
        \o message.bulkAction
        \o message.cancelScope
        \o message.targetCancelMpid

DecodeBulkCancelRequestType223Message(bytes) ==
    LET symbolId == ReadBytes(bytes, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET mpid == ReadBytes(symbolId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET marketMaker == ReadBytes(mpid.rest, 10) IN IF ~marketMaker.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(marketMaker.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET mmSentTime == ReadBytes(clOrdId.rest, 8) IN IF ~mmSentTime.ok THEN Fail ELSE
    LET sideU81 == ReadBytes(mmSentTime.rest, 1) IN IF ~sideU81.ok THEN Fail ELSE
    LET groupId == ReadBytes(sideU81.rest, 4) IN IF ~groupId.ok THEN Fail ELSE
    LET targetCancelUsername == ReadBytes(groupId.rest, 16) IN IF ~targetCancelUsername.ok THEN Fail ELSE
    LET bulkAction == ReadBytes(targetCancelUsername.rest, 1) IN IF ~bulkAction.ok THEN Fail ELSE
    LET cancelScope == ReadBytes(bulkAction.rest, 1) IN IF ~cancelScope.ok THEN Fail ELSE
    LET targetCancelMpid == ReadBytes(cancelScope.rest, 4) IN IF ~targetCancelMpid.ok THEN Fail ELSE
    Ok([ symbolId             |-> symbolId.value,
         mpid                 |-> mpid.value,
         marketMaker          |-> marketMaker.value,
         clOrdId              |-> clOrdId.value,
         mmSentTime           |-> mmSentTime.value,
         sideU81              |-> sideU81.value,
         groupId              |-> groupId.value,
         targetCancelUsername |-> targetCancelUsername.value,
         bulkAction           |-> bulkAction.value,
         cancelScope          |-> cancelScope.value,
         targetCancelMpid     |-> targetCancelMpid.value ], targetCancelMpid.rest)

ZeroBulkCancelRequestType223Message ==
    [ symbolId             |-> [i \in 1 .. 4 |-> 0],
      mpid                 |-> [i \in 1 .. 4 |-> 0],
      marketMaker          |-> [i \in 1 .. 10 |-> 0],
      clOrdId              |-> [i \in 1 .. 8 |-> 0],
      mmSentTime           |-> [i \in 1 .. 8 |-> 0],
      sideU81              |-> [i \in 1 .. 1 |-> 0],
      groupId              |-> [i \in 1 .. 4 |-> 0],
      targetCancelUsername |-> [i \in 1 .. 16 |-> 0],
      bulkAction           |-> [i \in 1 .. 1 |-> 0],
      cancelScope          |-> [i \in 1 .. 1 |-> 0],
      targetCancelMpid     |-> [i \in 1 .. 4 |-> 0] ]

(* Bulk Cancel Request Type 223 Message at zero, then each field in turn at the values it is checked at *)
CheckedBulkCancelRequestType223Message ==
    { ZeroBulkCancelRequestType223Message }
        \cup { [ZeroBulkCancelRequestType223Message EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroBulkCancelRequestType223Message EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroBulkCancelRequestType223Message EXCEPT !.marketMaker = one] : one \in Sample(10) }
        \cup { [ZeroBulkCancelRequestType223Message EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroBulkCancelRequestType223Message EXCEPT !.mmSentTime = one] : one \in Sample(8) }
        \cup { [ZeroBulkCancelRequestType223Message EXCEPT !.sideU81 = one] : one \in Sample(1) }
        \cup { [ZeroBulkCancelRequestType223Message EXCEPT !.groupId = one] : one \in Sample(4) }
        \cup { [ZeroBulkCancelRequestType223Message EXCEPT !.targetCancelUsername = one] : one \in Sample(16) }
        \cup { [ZeroBulkCancelRequestType223Message EXCEPT !.bulkAction = one] : one \in Sample(1) }
        \cup { [ZeroBulkCancelRequestType223Message EXCEPT !.cancelScope = one] : one \in Sample(1) }
        \cup { [ZeroBulkCancelRequestType223Message EXCEPT !.targetCancelMpid = one] : one \in Sample(4) }

(***************************************************************************)
(* Bulk Cancel Request Type 224 Message: 62 bytes                          *)
(***************************************************************************)

BulkCancelRequestType224Message ==
    [ symbolId             : Sample(4),
      mpid                 : Sample(4),
      mpSubId              : Sample(4),
      clOrdId              : Sample(8),
      sideU81              : Sample(1),
      targetCancelUsername : Sample(16),
      bulkAction           : Sample(1),
      targetCancelMpid     : Sample(4),
      reserved20           : Sample(20) ]

EncodeBulkCancelRequestType224Message(message) ==
    message.symbolId
        \o message.mpid
        \o message.mpSubId
        \o message.clOrdId
        \o message.sideU81
        \o message.targetCancelUsername
        \o message.bulkAction
        \o message.targetCancelMpid
        \o message.reserved20

DecodeBulkCancelRequestType224Message(bytes) ==
    LET symbolId == ReadBytes(bytes, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET mpid == ReadBytes(symbolId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET mpSubId == ReadBytes(mpid.rest, 4) IN IF ~mpSubId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(mpSubId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET sideU81 == ReadBytes(clOrdId.rest, 1) IN IF ~sideU81.ok THEN Fail ELSE
    LET targetCancelUsername == ReadBytes(sideU81.rest, 16) IN IF ~targetCancelUsername.ok THEN Fail ELSE
    LET bulkAction == ReadBytes(targetCancelUsername.rest, 1) IN IF ~bulkAction.ok THEN Fail ELSE
    LET targetCancelMpid == ReadBytes(bulkAction.rest, 4) IN IF ~targetCancelMpid.ok THEN Fail ELSE
    LET reserved20 == ReadBytes(targetCancelMpid.rest, 20) IN IF ~reserved20.ok THEN Fail ELSE
    Ok([ symbolId             |-> symbolId.value,
         mpid                 |-> mpid.value,
         mpSubId              |-> mpSubId.value,
         clOrdId              |-> clOrdId.value,
         sideU81              |-> sideU81.value,
         targetCancelUsername |-> targetCancelUsername.value,
         bulkAction           |-> bulkAction.value,
         targetCancelMpid     |-> targetCancelMpid.value,
         reserved20           |-> reserved20.value ], reserved20.rest)

ZeroBulkCancelRequestType224Message ==
    [ symbolId             |-> [i \in 1 .. 4 |-> 0],
      mpid                 |-> [i \in 1 .. 4 |-> 0],
      mpSubId              |-> [i \in 1 .. 4 |-> 0],
      clOrdId              |-> [i \in 1 .. 8 |-> 0],
      sideU81              |-> [i \in 1 .. 1 |-> 0],
      targetCancelUsername |-> [i \in 1 .. 16 |-> 0],
      bulkAction           |-> [i \in 1 .. 1 |-> 0],
      targetCancelMpid     |-> [i \in 1 .. 4 |-> 0],
      reserved20           |-> [i \in 1 .. 20 |-> 0] ]

(* Bulk Cancel Request Type 224 Message at zero, then each field in turn at the values it is checked at *)
CheckedBulkCancelRequestType224Message ==
    { ZeroBulkCancelRequestType224Message }
        \cup { [ZeroBulkCancelRequestType224Message EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroBulkCancelRequestType224Message EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroBulkCancelRequestType224Message EXCEPT !.mpSubId = one] : one \in Sample(4) }
        \cup { [ZeroBulkCancelRequestType224Message EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroBulkCancelRequestType224Message EXCEPT !.sideU81 = one] : one \in Sample(1) }
        \cup { [ZeroBulkCancelRequestType224Message EXCEPT !.targetCancelUsername = one] : one \in Sample(16) }
        \cup { [ZeroBulkCancelRequestType224Message EXCEPT !.bulkAction = one] : one \in Sample(1) }
        \cup { [ZeroBulkCancelRequestType224Message EXCEPT !.targetCancelMpid = one] : one \in Sample(4) }
        \cup { [ZeroBulkCancelRequestType224Message EXCEPT !.reserved20 = one] : one \in Sample(20) }

(***************************************************************************)
(* Risk Limit Update Request Message: 268 bytes                            *)
(***************************************************************************)

RiskLimitUpdateRequestMessage ==
    [ symbolId              : Sample(4),
      mpid                  : Sample(4),
      marketMaker           : Sample(10),
      mpSubId               : Sample(4),
      reserved4             : Sample(4),
      clearingNumber        : Sample(5),
      clOrdId               : Sample(8),
      riskUserCrd           : Sample(4),
      riskUserType          : Sample(1),
      riskControlType       : Sample(1),
      riskControlActivation : Sample(1),
      usdLimit              : Sample(8),
      timeLimit             : Sample(4),
      percentageLimit       : Sample(4),
      countLimit            : Sample(4),
      breachActionRequest   : Sample(1),
      iocAttribution        : Sample(1),
      riskRangeId           : Sample(1),
      riskMinimumValue      : Sample(8),
      priceScale            : Sample(1),
      reserved190           : Sample(190) ]

EncodeRiskLimitUpdateRequestMessage(message) ==
    message.symbolId
        \o message.mpid
        \o message.marketMaker
        \o message.mpSubId
        \o message.reserved4
        \o message.clearingNumber
        \o message.clOrdId
        \o message.riskUserCrd
        \o message.riskUserType
        \o message.riskControlType
        \o message.riskControlActivation
        \o message.usdLimit
        \o message.timeLimit
        \o message.percentageLimit
        \o message.countLimit
        \o message.breachActionRequest
        \o message.iocAttribution
        \o message.riskRangeId
        \o message.riskMinimumValue
        \o message.priceScale
        \o message.reserved190

DecodeRiskLimitUpdateRequestMessage(bytes) ==
    LET symbolId == ReadBytes(bytes, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET mpid == ReadBytes(symbolId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET marketMaker == ReadBytes(mpid.rest, 10) IN IF ~marketMaker.ok THEN Fail ELSE
    LET mpSubId == ReadBytes(marketMaker.rest, 4) IN IF ~mpSubId.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(mpSubId.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET clearingNumber == ReadBytes(reserved4.rest, 5) IN IF ~clearingNumber.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(clearingNumber.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET riskUserCrd == ReadBytes(clOrdId.rest, 4) IN IF ~riskUserCrd.ok THEN Fail ELSE
    LET riskUserType == ReadBytes(riskUserCrd.rest, 1) IN IF ~riskUserType.ok THEN Fail ELSE
    LET riskControlType == ReadBytes(riskUserType.rest, 1) IN IF ~riskControlType.ok THEN Fail ELSE
    LET riskControlActivation == ReadBytes(riskControlType.rest, 1) IN IF ~riskControlActivation.ok THEN Fail ELSE
    LET usdLimit == ReadBytes(riskControlActivation.rest, 8) IN IF ~usdLimit.ok THEN Fail ELSE
    LET timeLimit == ReadBytes(usdLimit.rest, 4) IN IF ~timeLimit.ok THEN Fail ELSE
    LET percentageLimit == ReadBytes(timeLimit.rest, 4) IN IF ~percentageLimit.ok THEN Fail ELSE
    LET countLimit == ReadBytes(percentageLimit.rest, 4) IN IF ~countLimit.ok THEN Fail ELSE
    LET breachActionRequest == ReadBytes(countLimit.rest, 1) IN IF ~breachActionRequest.ok THEN Fail ELSE
    LET iocAttribution == ReadBytes(breachActionRequest.rest, 1) IN IF ~iocAttribution.ok THEN Fail ELSE
    LET riskRangeId == ReadBytes(iocAttribution.rest, 1) IN IF ~riskRangeId.ok THEN Fail ELSE
    LET riskMinimumValue == ReadBytes(riskRangeId.rest, 8) IN IF ~riskMinimumValue.ok THEN Fail ELSE
    LET priceScale == ReadBytes(riskMinimumValue.rest, 1) IN IF ~priceScale.ok THEN Fail ELSE
    LET reserved190 == ReadBytes(priceScale.rest, 190) IN IF ~reserved190.ok THEN Fail ELSE
    Ok([ symbolId              |-> symbolId.value,
         mpid                  |-> mpid.value,
         marketMaker           |-> marketMaker.value,
         mpSubId               |-> mpSubId.value,
         reserved4             |-> reserved4.value,
         clearingNumber        |-> clearingNumber.value,
         clOrdId               |-> clOrdId.value,
         riskUserCrd           |-> riskUserCrd.value,
         riskUserType          |-> riskUserType.value,
         riskControlType       |-> riskControlType.value,
         riskControlActivation |-> riskControlActivation.value,
         usdLimit              |-> usdLimit.value,
         timeLimit             |-> timeLimit.value,
         percentageLimit       |-> percentageLimit.value,
         countLimit            |-> countLimit.value,
         breachActionRequest   |-> breachActionRequest.value,
         iocAttribution        |-> iocAttribution.value,
         riskRangeId           |-> riskRangeId.value,
         riskMinimumValue      |-> riskMinimumValue.value,
         priceScale            |-> priceScale.value,
         reserved190           |-> reserved190.value ], reserved190.rest)

ZeroRiskLimitUpdateRequestMessage ==
    [ symbolId              |-> [i \in 1 .. 4 |-> 0],
      mpid                  |-> [i \in 1 .. 4 |-> 0],
      marketMaker           |-> [i \in 1 .. 10 |-> 0],
      mpSubId               |-> [i \in 1 .. 4 |-> 0],
      reserved4             |-> [i \in 1 .. 4 |-> 0],
      clearingNumber        |-> [i \in 1 .. 5 |-> 0],
      clOrdId               |-> [i \in 1 .. 8 |-> 0],
      riskUserCrd           |-> [i \in 1 .. 4 |-> 0],
      riskUserType          |-> [i \in 1 .. 1 |-> 0],
      riskControlType       |-> [i \in 1 .. 1 |-> 0],
      riskControlActivation |-> [i \in 1 .. 1 |-> 0],
      usdLimit              |-> [i \in 1 .. 8 |-> 0],
      timeLimit             |-> [i \in 1 .. 4 |-> 0],
      percentageLimit       |-> [i \in 1 .. 4 |-> 0],
      countLimit            |-> [i \in 1 .. 4 |-> 0],
      breachActionRequest   |-> [i \in 1 .. 1 |-> 0],
      iocAttribution        |-> [i \in 1 .. 1 |-> 0],
      riskRangeId           |-> [i \in 1 .. 1 |-> 0],
      riskMinimumValue      |-> [i \in 1 .. 8 |-> 0],
      priceScale            |-> [i \in 1 .. 1 |-> 0],
      reserved190           |-> [i \in 1 .. 190 |-> 0] ]

(* Risk Limit Update Request Message at zero, then each field in turn at the values it is checked at *)
CheckedRiskLimitUpdateRequestMessage ==
    { ZeroRiskLimitUpdateRequestMessage }
        \cup { [ZeroRiskLimitUpdateRequestMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroRiskLimitUpdateRequestMessage EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroRiskLimitUpdateRequestMessage EXCEPT !.marketMaker = one] : one \in Sample(10) }
        \cup { [ZeroRiskLimitUpdateRequestMessage EXCEPT !.mpSubId = one] : one \in Sample(4) }
        \cup { [ZeroRiskLimitUpdateRequestMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroRiskLimitUpdateRequestMessage EXCEPT !.clearingNumber = one] : one \in Sample(5) }
        \cup { [ZeroRiskLimitUpdateRequestMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroRiskLimitUpdateRequestMessage EXCEPT !.riskUserCrd = one] : one \in Sample(4) }
        \cup { [ZeroRiskLimitUpdateRequestMessage EXCEPT !.riskUserType = one] : one \in Sample(1) }
        \cup { [ZeroRiskLimitUpdateRequestMessage EXCEPT !.riskControlType = one] : one \in Sample(1) }
        \cup { [ZeroRiskLimitUpdateRequestMessage EXCEPT !.riskControlActivation = one] : one \in Sample(1) }
        \cup { [ZeroRiskLimitUpdateRequestMessage EXCEPT !.usdLimit = one] : one \in Sample(8) }
        \cup { [ZeroRiskLimitUpdateRequestMessage EXCEPT !.timeLimit = one] : one \in Sample(4) }
        \cup { [ZeroRiskLimitUpdateRequestMessage EXCEPT !.percentageLimit = one] : one \in Sample(4) }
        \cup { [ZeroRiskLimitUpdateRequestMessage EXCEPT !.countLimit = one] : one \in Sample(4) }
        \cup { [ZeroRiskLimitUpdateRequestMessage EXCEPT !.breachActionRequest = one] : one \in Sample(1) }
        \cup { [ZeroRiskLimitUpdateRequestMessage EXCEPT !.iocAttribution = one] : one \in Sample(1) }
        \cup { [ZeroRiskLimitUpdateRequestMessage EXCEPT !.riskRangeId = one] : one \in Sample(1) }
        \cup { [ZeroRiskLimitUpdateRequestMessage EXCEPT !.riskMinimumValue = one] : one \in Sample(8) }
        \cup { [ZeroRiskLimitUpdateRequestMessage EXCEPT !.priceScale = one] : one \in Sample(1) }
        \cup { [ZeroRiskLimitUpdateRequestMessage EXCEPT !.reserved190 = one] : one \in Sample(190) }

(***************************************************************************)
(* Risk Action Request Message: 246 bytes                                  *)
(***************************************************************************)

RiskActionRequestMessage ==
    [ symbolId        : Sample(4),
      mpid            : Sample(4),
      marketMaker     : Sample(10),
      mpSubId         : Sample(4),
      reserved4       : Sample(4),
      clearingNumber  : Sample(5),
      clOrdId         : Sample(8),
      riskUserCrd     : Sample(4),
      riskUserType    : Sample(1),
      riskControlType : Sample(1),
      riskActionType  : Sample(1),
      riskRangeId     : Sample(1),
      reserved199     : Sample(199) ]

EncodeRiskActionRequestMessage(message) ==
    message.symbolId
        \o message.mpid
        \o message.marketMaker
        \o message.mpSubId
        \o message.reserved4
        \o message.clearingNumber
        \o message.clOrdId
        \o message.riskUserCrd
        \o message.riskUserType
        \o message.riskControlType
        \o message.riskActionType
        \o message.riskRangeId
        \o message.reserved199

DecodeRiskActionRequestMessage(bytes) ==
    LET symbolId == ReadBytes(bytes, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET mpid == ReadBytes(symbolId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET marketMaker == ReadBytes(mpid.rest, 10) IN IF ~marketMaker.ok THEN Fail ELSE
    LET mpSubId == ReadBytes(marketMaker.rest, 4) IN IF ~mpSubId.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(mpSubId.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET clearingNumber == ReadBytes(reserved4.rest, 5) IN IF ~clearingNumber.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(clearingNumber.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET riskUserCrd == ReadBytes(clOrdId.rest, 4) IN IF ~riskUserCrd.ok THEN Fail ELSE
    LET riskUserType == ReadBytes(riskUserCrd.rest, 1) IN IF ~riskUserType.ok THEN Fail ELSE
    LET riskControlType == ReadBytes(riskUserType.rest, 1) IN IF ~riskControlType.ok THEN Fail ELSE
    LET riskActionType == ReadBytes(riskControlType.rest, 1) IN IF ~riskActionType.ok THEN Fail ELSE
    LET riskRangeId == ReadBytes(riskActionType.rest, 1) IN IF ~riskRangeId.ok THEN Fail ELSE
    LET reserved199 == ReadBytes(riskRangeId.rest, 199) IN IF ~reserved199.ok THEN Fail ELSE
    Ok([ symbolId        |-> symbolId.value,
         mpid            |-> mpid.value,
         marketMaker     |-> marketMaker.value,
         mpSubId         |-> mpSubId.value,
         reserved4       |-> reserved4.value,
         clearingNumber  |-> clearingNumber.value,
         clOrdId         |-> clOrdId.value,
         riskUserCrd     |-> riskUserCrd.value,
         riskUserType    |-> riskUserType.value,
         riskControlType |-> riskControlType.value,
         riskActionType  |-> riskActionType.value,
         riskRangeId     |-> riskRangeId.value,
         reserved199     |-> reserved199.value ], reserved199.rest)

ZeroRiskActionRequestMessage ==
    [ symbolId        |-> [i \in 1 .. 4 |-> 0],
      mpid            |-> [i \in 1 .. 4 |-> 0],
      marketMaker     |-> [i \in 1 .. 10 |-> 0],
      mpSubId         |-> [i \in 1 .. 4 |-> 0],
      reserved4       |-> [i \in 1 .. 4 |-> 0],
      clearingNumber  |-> [i \in 1 .. 5 |-> 0],
      clOrdId         |-> [i \in 1 .. 8 |-> 0],
      riskUserCrd     |-> [i \in 1 .. 4 |-> 0],
      riskUserType    |-> [i \in 1 .. 1 |-> 0],
      riskControlType |-> [i \in 1 .. 1 |-> 0],
      riskActionType  |-> [i \in 1 .. 1 |-> 0],
      riskRangeId     |-> [i \in 1 .. 1 |-> 0],
      reserved199     |-> [i \in 1 .. 199 |-> 0] ]

(* Risk Action Request Message at zero, then each field in turn at the values it is checked at *)
CheckedRiskActionRequestMessage ==
    { ZeroRiskActionRequestMessage }
        \cup { [ZeroRiskActionRequestMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroRiskActionRequestMessage EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroRiskActionRequestMessage EXCEPT !.marketMaker = one] : one \in Sample(10) }
        \cup { [ZeroRiskActionRequestMessage EXCEPT !.mpSubId = one] : one \in Sample(4) }
        \cup { [ZeroRiskActionRequestMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroRiskActionRequestMessage EXCEPT !.clearingNumber = one] : one \in Sample(5) }
        \cup { [ZeroRiskActionRequestMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroRiskActionRequestMessage EXCEPT !.riskUserCrd = one] : one \in Sample(4) }
        \cup { [ZeroRiskActionRequestMessage EXCEPT !.riskUserType = one] : one \in Sample(1) }
        \cup { [ZeroRiskActionRequestMessage EXCEPT !.riskControlType = one] : one \in Sample(1) }
        \cup { [ZeroRiskActionRequestMessage EXCEPT !.riskActionType = one] : one \in Sample(1) }
        \cup { [ZeroRiskActionRequestMessage EXCEPT !.riskRangeId = one] : one \in Sample(1) }
        \cup { [ZeroRiskActionRequestMessage EXCEPT !.reserved199 = one] : one \in Sample(199) }

(***************************************************************************)
(* Complex Series Leg Group: 7 bytes                                       *)
(***************************************************************************)

ComplexSeriesLegGroup ==
    [ legSymbolId : Sample(4),
      legRatioQty : Sample(2),
      legSide     : Sample(1) ]

EncodeComplexSeriesLegGroup(message) ==
    message.legSymbolId
        \o message.legRatioQty
        \o message.legSide

DecodeComplexSeriesLegGroup(bytes) ==
    LET legSymbolId == ReadBytes(bytes, 4) IN IF ~legSymbolId.ok THEN Fail ELSE
    LET legRatioQty == ReadBytes(legSymbolId.rest, 2) IN IF ~legRatioQty.ok THEN Fail ELSE
    LET legSide == ReadBytes(legRatioQty.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    Ok([ legSymbolId |-> legSymbolId.value,
         legRatioQty |-> legRatioQty.value,
         legSide     |-> legSide.value ], legSide.rest)

ZeroComplexSeriesLegGroup ==
    [ legSymbolId |-> [i \in 1 .. 4 |-> 0],
      legRatioQty |-> [i \in 1 .. 2 |-> 0],
      legSide     |-> [i \in 1 .. 1 |-> 0] ]

(* Complex Series Leg Group at zero, then each field in turn at the values it is checked at *)
CheckedComplexSeriesLegGroup ==
    { ZeroComplexSeriesLegGroup }
        \cup { [ZeroComplexSeriesLegGroup EXCEPT !.legSymbolId = one] : one \in Sample(4) }
        \cup { [ZeroComplexSeriesLegGroup EXCEPT !.legRatioQty = one] : one \in Sample(2) }
        \cup { [ZeroComplexSeriesLegGroup EXCEPT !.legSide = one] : one \in Sample(1) }

(* A run of Complex Series Leg Group, written one after another *)
RECURSIVE EncodeComplexSeriesLegGroupList(_)
EncodeComplexSeriesLegGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeComplexSeriesLegGroup(Head(messages)) \o EncodeComplexSeriesLegGroupList(Tail(messages))

(* As many Complex Series Leg Group as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadComplexSeriesLegGroupAll(_)
ReadComplexSeriesLegGroupAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeComplexSeriesLegGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadComplexSeriesLegGroupAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Complex Series Leg Group of each kind, for the lists that carry them *)
OneComplexSeriesLegGroup == { ZeroComplexSeriesLegGroup }

(***************************************************************************)
(* New Complex Series Request Message                                      *)
(***************************************************************************)

NewComplexSeriesRequestMessage ==
    [ clOrdId               : Sample(8),
      mpid                  : Sample(4),
      complexSeriesLegGroup : SampleLists(OneComplexSeriesLegGroup) ]

EncodeNewComplexSeriesRequestMessage(message) ==
    message.clOrdId
        \o message.mpid
        \o EncodeComplexSeriesLegGroupList(message.complexSeriesLegGroup)

DecodeNewComplexSeriesRequestMessage(bytes) ==
    LET clOrdId == ReadBytes(bytes, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET mpid == ReadBytes(clOrdId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET complexSeriesLegGroup == ReadComplexSeriesLegGroupAll(mpid.rest) IN IF ~complexSeriesLegGroup.ok THEN Fail ELSE
    Ok([ clOrdId               |-> clOrdId.value,
         mpid                  |-> mpid.value,
         complexSeriesLegGroup |-> complexSeriesLegGroup.value ], complexSeriesLegGroup.rest)

ZeroNewComplexSeriesRequestMessage ==
    [ clOrdId               |-> [i \in 1 .. 8 |-> 0],
      mpid                  |-> [i \in 1 .. 4 |-> 0],
      complexSeriesLegGroup |-> << >> ]

(* New Complex Series Request Message at zero, then each field in turn at the values it is checked at *)
CheckedNewComplexSeriesRequestMessage ==
    { ZeroNewComplexSeriesRequestMessage }
        \cup { [ZeroNewComplexSeriesRequestMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroNewComplexSeriesRequestMessage EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexSeriesRequestMessage EXCEPT !.complexSeriesLegGroup = one] : one \in SampleLists(OneComplexSeriesLegGroup) }

(***************************************************************************)
(* Client Sequenced Message, selected by Seq Msg Type                      *)
(***************************************************************************)

SessionConfigurationRequestMessageCode == 544  \* 0x220
SequencedFillerMessageCode == 642  \* 0x282
NewOrderMessageCode == 584  \* 0x248
OrderCancelRequestMessageCode == 592  \* 0x250
OrderModifyRequestMessageCode == 593  \* 0x251
NewBulkQuoteType243MessageCode == 579  \* 0x243
NewBulkQuoteType259MessageCode == 601  \* 0x259
NewOrderCrossMessageCode == 546  \* 0x222
BulkCancelRequestType223MessageCode == 547  \* 0x223
BulkCancelRequestType224MessageCode == 548  \* 0x224
RiskLimitUpdateRequestMessageCode == 816  \* 0x330
RiskActionRequestMessageCode == 817  \* 0x331
NewComplexSeriesRequestMessageCode == 855  \* 0x357

ClientSequencedMessage ==
    [ tag : {SessionConfigurationRequestMessageCode}, body : SessionConfigurationRequestMessage ]
        \cup [ tag : {SequencedFillerMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {NewOrderMessageCode}, body : NewOrderMessage ]
        \cup [ tag : {OrderCancelRequestMessageCode}, body : OrderCancelRequestMessage ]
        \cup [ tag : {OrderModifyRequestMessageCode}, body : OrderModifyRequestMessage ]
        \cup [ tag : {NewBulkQuoteType243MessageCode}, body : NewBulkQuoteType243Message ]
        \cup [ tag : {NewBulkQuoteType259MessageCode}, body : NewBulkQuoteType259Message ]
        \cup [ tag : {NewOrderCrossMessageCode}, body : NewOrderCrossMessage ]
        \cup [ tag : {BulkCancelRequestType223MessageCode}, body : BulkCancelRequestType223Message ]
        \cup [ tag : {BulkCancelRequestType224MessageCode}, body : BulkCancelRequestType224Message ]
        \cup [ tag : {RiskLimitUpdateRequestMessageCode}, body : RiskLimitUpdateRequestMessage ]
        \cup [ tag : {RiskActionRequestMessageCode}, body : RiskActionRequestMessage ]
        \cup [ tag : {NewComplexSeriesRequestMessageCode}, body : NewComplexSeriesRequestMessage ]

EncodeClientSequencedMessage(message) ==
    CASE message.tag = SessionConfigurationRequestMessageCode -> EncodeSessionConfigurationRequestMessage(message.body)
      [] message.tag = SequencedFillerMessageCode -> << >>
      [] message.tag = NewOrderMessageCode -> EncodeNewOrderMessage(message.body)
      [] message.tag = OrderCancelRequestMessageCode -> EncodeOrderCancelRequestMessage(message.body)
      [] message.tag = OrderModifyRequestMessageCode -> EncodeOrderModifyRequestMessage(message.body)
      [] message.tag = NewBulkQuoteType243MessageCode -> EncodeNewBulkQuoteType243Message(message.body)
      [] message.tag = NewBulkQuoteType259MessageCode -> EncodeNewBulkQuoteType259Message(message.body)
      [] message.tag = NewOrderCrossMessageCode -> EncodeNewOrderCrossMessage(message.body)
      [] message.tag = BulkCancelRequestType223MessageCode -> EncodeBulkCancelRequestType223Message(message.body)
      [] message.tag = BulkCancelRequestType224MessageCode -> EncodeBulkCancelRequestType224Message(message.body)
      [] message.tag = RiskLimitUpdateRequestMessageCode -> EncodeRiskLimitUpdateRequestMessage(message.body)
      [] message.tag = RiskActionRequestMessageCode -> EncodeRiskActionRequestMessage(message.body)
      [] message.tag = NewComplexSeriesRequestMessageCode -> EncodeNewComplexSeriesRequestMessage(message.body)

DecodeClientSequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = SessionConfigurationRequestMessageCode -> DecodeSessionConfigurationRequestMessage(bytes)
              [] tag = SequencedFillerMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = NewOrderMessageCode -> DecodeNewOrderMessage(bytes)
              [] tag = OrderCancelRequestMessageCode -> DecodeOrderCancelRequestMessage(bytes)
              [] tag = OrderModifyRequestMessageCode -> DecodeOrderModifyRequestMessage(bytes)
              [] tag = NewBulkQuoteType243MessageCode -> DecodeNewBulkQuoteType243Message(bytes)
              [] tag = NewBulkQuoteType259MessageCode -> DecodeNewBulkQuoteType259Message(bytes)
              [] tag = NewOrderCrossMessageCode -> DecodeNewOrderCrossMessage(bytes)
              [] tag = BulkCancelRequestType223MessageCode -> DecodeBulkCancelRequestType223Message(bytes)
              [] tag = BulkCancelRequestType224MessageCode -> DecodeBulkCancelRequestType224Message(bytes)
              [] tag = RiskLimitUpdateRequestMessageCode -> DecodeRiskLimitUpdateRequestMessage(bytes)
              [] tag = RiskActionRequestMessageCode -> DecodeRiskActionRequestMessage(bytes)
              [] tag = NewComplexSeriesRequestMessageCode -> DecodeNewComplexSeriesRequestMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroClientSequencedMessage == [tag |-> SessionConfigurationRequestMessageCode, body |-> ZeroSessionConfigurationRequestMessage]

(* Each Client Sequenced Message in turn, at the values the message it names is checked at *)
CheckedClientSequencedMessage ==
    { [tag |-> SessionConfigurationRequestMessageCode, body |-> one] : one \in CheckedSessionConfigurationRequestMessage }
        \cup { [tag |-> SequencedFillerMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> NewOrderMessageCode, body |-> one] : one \in CheckedNewOrderMessage }
        \cup { [tag |-> OrderCancelRequestMessageCode, body |-> one] : one \in CheckedOrderCancelRequestMessage }
        \cup { [tag |-> OrderModifyRequestMessageCode, body |-> one] : one \in CheckedOrderModifyRequestMessage }
        \cup { [tag |-> NewBulkQuoteType243MessageCode, body |-> one] : one \in CheckedNewBulkQuoteType243Message }
        \cup { [tag |-> NewBulkQuoteType259MessageCode, body |-> one] : one \in CheckedNewBulkQuoteType259Message }
        \cup { [tag |-> NewOrderCrossMessageCode, body |-> one] : one \in CheckedNewOrderCrossMessage }
        \cup { [tag |-> BulkCancelRequestType223MessageCode, body |-> one] : one \in CheckedBulkCancelRequestType223Message }
        \cup { [tag |-> BulkCancelRequestType224MessageCode, body |-> one] : one \in CheckedBulkCancelRequestType224Message }
        \cup { [tag |-> RiskLimitUpdateRequestMessageCode, body |-> one] : one \in CheckedRiskLimitUpdateRequestMessage }
        \cup { [tag |-> RiskActionRequestMessageCode, body |-> one] : one \in CheckedRiskActionRequestMessage }
        \cup { [tag |-> NewComplexSeriesRequestMessageCode, body |-> one] : one \in CheckedNewComplexSeriesRequestMessage }

(***************************************************************************)
(* Client Seq Msg, framed by Msg Length                                    *)
(***************************************************************************)

ClientSeqMsg ==
    [ seqMsgId               : SeqMsgId,
      reserved4              : Sample(4),
      timestamp              : Sample(8),
      clientSequencedMessage : ClientSequencedMessage ]

EncodeClientSeqMsgBody(message) ==
    EncodeSeqMsgId(message.seqMsgId)
        \o message.reserved4
        \o message.timestamp
        \o EncodeUIntLE(message.clientSequencedMessage.tag, 2)
        \o EncodeUIntLE(Len(EncodeClientSequencedMessage(message.clientSequencedMessage)) + 4, 2)
        \o EncodeClientSequencedMessage(message.clientSequencedMessage)

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
    LET seqMsgType == ReadUIntLE(timestamp.rest, 2) IN IF ~seqMsgType.ok THEN Fail ELSE
    LET seqMsgLength == ReadUIntLE(seqMsgType.rest, 2) IN IF ~seqMsgLength.ok THEN Fail ELSE
    LET clientSequencedMessageSize == seqMsgLength.value - 4 IN
    IF clientSequencedMessageSize < 0 \/ Len(seqMsgLength.rest) < clientSequencedMessageSize THEN Fail ELSE
    LET clientSequencedMessageFramed == SubSeq(seqMsgLength.rest, 1, clientSequencedMessageSize)
        clientSequencedMessageBeyond == SubSeq(seqMsgLength.rest, clientSequencedMessageSize + 1, Len(seqMsgLength.rest))
        clientSequencedMessage == DecodeClientSequencedMessage(seqMsgType.value, clientSequencedMessageFramed)
    IN  IF ~clientSequencedMessage.ok \/ clientSequencedMessage.rest # << >> THEN Fail ELSE
    IF clientSequencedMessageBeyond # << >> THEN Fail ELSE
    Ok([ seqMsgId               |-> seqMsgId.value,
         reserved4              |-> reserved4.value,
         timestamp              |-> timestamp.value,
         clientSequencedMessage |-> clientSequencedMessage.value ], beyond)

ZeroClientSeqMsg ==
    [ seqMsgId               |-> ZeroSeqMsgId,
      reserved4              |-> [i \in 1 .. 4 |-> 0],
      timestamp              |-> [i \in 1 .. 8 |-> 0],
      clientSequencedMessage |-> ZeroClientSequencedMessage ]

(* Client Seq Msg at zero, then each field in turn at the values it is checked at *)
CheckedClientSeqMsg ==
    { ZeroClientSeqMsg }
        \cup { [ZeroClientSeqMsg EXCEPT !.seqMsgId = one] : one \in CheckedSeqMsgId }
        \cup { [ZeroClientSeqMsg EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroClientSeqMsg EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroClientSeqMsg EXCEPT !.clientSequencedMessage = one] : one \in CheckedClientSequencedMessage }

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

(* Every Session Configuration Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSessionConfigurationRequestMessage ==
    \A message \in CheckedSessionConfigurationRequestMessage :
        LET read == DecodeSessionConfigurationRequestMessage(EncodeSessionConfigurationRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sub Msg Header decodes back to what was encoded, and leaves nothing over *)
RoundTripSubMsgHeader ==
    \A message \in CheckedSubMsgHeader :
        LET read == DecodeSubMsgHeader(EncodeSubMsgHeader(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Optional Order Add On decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionalOrderAddOn ==
    \A message \in CheckedOptionalOrderAddOn :
        LET read == DecodeOptionalOrderAddOn(EncodeOptionalOrderAddOn(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderMessage ==
    \A message \in CheckedNewOrderMessage :
        LET read == DecodeNewOrderMessage(EncodeNewOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancel Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelRequestMessage ==
    \A message \in CheckedOrderCancelRequestMessage :
        LET read == DecodeOrderCancelRequestMessage(EncodeOrderCancelRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Modify Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderModifyRequestMessage ==
    \A message \in CheckedOrderModifyRequestMessage :
        LET read == DecodeOrderModifyRequestMessage(EncodeOrderModifyRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Request Group decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteRequestGroup ==
    \A message \in CheckedQuoteRequestGroup :
        LET read == DecodeQuoteRequestGroup(EncodeQuoteRequestGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Bulk Quote Type 243 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewBulkQuoteType243Message ==
    \A message \in CheckedNewBulkQuoteType243Message :
        LET read == DecodeNewBulkQuoteType243Message(EncodeNewBulkQuoteType243Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Request Group decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteRequestGroup2 ==
    \A message \in CheckedQuoteRequestGroup2 :
        LET read == DecodeQuoteRequestGroup2(EncodeQuoteRequestGroup2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Bulk Quote Type 259 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewBulkQuoteType259Message ==
    \A message \in CheckedNewBulkQuoteType259Message :
        LET read == DecodeNewBulkQuoteType259Message(EncodeNewBulkQuoteType259Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sub Msg Header decodes back to what was encoded, and leaves nothing over *)
RoundTripSubMsgHeader2 ==
    \A message \in CheckedSubMsgHeader2 :
        LET read == DecodeSubMsgHeader2(EncodeSubMsgHeader2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Exposed decodes back to what was encoded, and leaves nothing over *)
RoundTripExposed ==
    \A message \in CheckedExposed :
        LET read == DecodeExposed(EncodeExposed(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sub Msg Header decodes back to what was encoded, and leaves nothing over *)
RoundTripSubMsgHeader3 ==
    \A message \in CheckedSubMsgHeader3 :
        LET read == DecodeSubMsgHeader3(EncodeSubMsgHeader3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Covered decodes back to what was encoded, and leaves nothing over *)
RoundTripCovered ==
    \A message \in CheckedCovered :
        LET read == DecodeCovered(EncodeCovered(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Cross Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderCrossMessage ==
    \A message \in CheckedNewOrderCrossMessage :
        LET read == DecodeNewOrderCrossMessage(EncodeNewOrderCrossMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulk Cancel Request Type 223 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkCancelRequestType223Message ==
    \A message \in CheckedBulkCancelRequestType223Message :
        LET read == DecodeBulkCancelRequestType223Message(EncodeBulkCancelRequestType223Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulk Cancel Request Type 224 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkCancelRequestType224Message ==
    \A message \in CheckedBulkCancelRequestType224Message :
        LET read == DecodeBulkCancelRequestType224Message(EncodeBulkCancelRequestType224Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Risk Limit Update Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRiskLimitUpdateRequestMessage ==
    \A message \in CheckedRiskLimitUpdateRequestMessage :
        LET read == DecodeRiskLimitUpdateRequestMessage(EncodeRiskLimitUpdateRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Risk Action Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRiskActionRequestMessage ==
    \A message \in CheckedRiskActionRequestMessage :
        LET read == DecodeRiskActionRequestMessage(EncodeRiskActionRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Series Leg Group decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexSeriesLegGroup ==
    \A message \in CheckedComplexSeriesLegGroup :
        LET read == DecodeComplexSeriesLegGroup(EncodeComplexSeriesLegGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Complex Series Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewComplexSeriesRequestMessage ==
    \A message \in CheckedNewComplexSeriesRequestMessage :
        LET read == DecodeNewComplexSeriesRequestMessage(EncodeNewComplexSeriesRequestMessage(message))
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

(* A Seq Msg Length is selected by the Seq Msg Length it is written under *)
SelectsSeqMsgLengthChoice ==
    \A message \in CheckedSeqMsgLengthChoice :
        LET sent == EncodeSeqMsgLengthChoice(message)
            read == DecodeSeqMsgLengthChoice(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Client Sequenced Message is selected by the Seq Msg Type it is written under *)
SelectsClientSequencedMessage ==
    \A message \in CheckedClientSequencedMessage :
        LET sent == EncodeClientSequencedMessage(message)
            read == DecodeClientSequencedMessage(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

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
