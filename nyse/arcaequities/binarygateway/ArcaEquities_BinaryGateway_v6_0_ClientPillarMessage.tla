-------- MODULE ArcaEquities_BinaryGateway_v6_0_ClientPillarMessage --------
(***************************************************************************)
(* New York Stock Exchange Binary Gateway v6.0                             *)
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
(* record holds: 65 carries none of them, and each of the others states    *)
(* its own length.                                                         *)
(*                                                                         *)
(* Note: New Order Single And Cancel Replace Request Message is as wide as *)
(* Seq Msg Length says, which is the frame it is read from.                *)
(*                                                                         *)
(* Note: Order Cancel Request Message is as wide as Seq Msg Length says,   *)
(* which is the frame it is read from.                                     *)
(*                                                                         *)
(* Note: Order Modify Request Message is as wide as Seq Msg Length says,   *)
(* which is the frame it is read from.                                     *)
(*                                                                         *)
(* Note: Bulk Cancel Request Message is as wide as Seq Msg Length says,    *)
(* which is the frame it is read from.                                     *)
(*                                                                         *)
(* Note: Symbol Subscription Request Message is as wide as Seq Msg Length  *)
(* says, which is the frame it is read from.                               *)
(*                                                                         *)
(* Note: Manual Action Response Message is as wide as Seq Msg Length says, *)
(* which is the frame it is read from.                                     *)
(*                                                                         *)
(* Note: Risk Limit Update Request Message is as wide as Seq Msg Length    *)
(* says, which is the frame it is read from.                               *)
(*                                                                         *)
(* Note: Risk Action Request Message is as wide as Seq Msg Length says,    *)
(* which is the frame it is read from.                                     *)
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
(* Optional Order Add On: 41 bytes                                         *)
(***************************************************************************)

OptionalOrderAddOn ==
    [ subMsgHeader    : SubMsgHeader,
      deliverToCompId : Sample(5),
      maxFloor        : Sample(4),
      locateBroker    : Sample(4),
      reserved8       : Sample(8),
      offsetPrice     : Sample(8),
      effectiveTime   : Sample(8) ]

EncodeOptionalOrderAddOn(message) ==
    EncodeSubMsgHeader(message.subMsgHeader)
        \o message.deliverToCompId
        \o message.maxFloor
        \o message.locateBroker
        \o message.reserved8
        \o message.offsetPrice
        \o message.effectiveTime

DecodeOptionalOrderAddOn(bytes) ==
    LET subMsgHeader == DecodeSubMsgHeader(bytes) IN IF ~subMsgHeader.ok THEN Fail ELSE
    LET deliverToCompId == ReadBytes(subMsgHeader.rest, 5) IN IF ~deliverToCompId.ok THEN Fail ELSE
    LET maxFloor == ReadBytes(deliverToCompId.rest, 4) IN IF ~maxFloor.ok THEN Fail ELSE
    LET locateBroker == ReadBytes(maxFloor.rest, 4) IN IF ~locateBroker.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(locateBroker.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    LET offsetPrice == ReadBytes(reserved8.rest, 8) IN IF ~offsetPrice.ok THEN Fail ELSE
    LET effectiveTime == ReadBytes(offsetPrice.rest, 8) IN IF ~effectiveTime.ok THEN Fail ELSE
    Ok([ subMsgHeader    |-> subMsgHeader.value,
         deliverToCompId |-> deliverToCompId.value,
         maxFloor        |-> maxFloor.value,
         locateBroker    |-> locateBroker.value,
         reserved8       |-> reserved8.value,
         offsetPrice     |-> offsetPrice.value,
         effectiveTime   |-> effectiveTime.value ], effectiveTime.rest)

ZeroOptionalOrderAddOn ==
    [ subMsgHeader    |-> ZeroSubMsgHeader,
      deliverToCompId |-> [i \in 1 .. 5 |-> 0],
      maxFloor        |-> [i \in 1 .. 4 |-> 0],
      locateBroker    |-> [i \in 1 .. 4 |-> 0],
      reserved8       |-> [i \in 1 .. 8 |-> 0],
      offsetPrice     |-> [i \in 1 .. 8 |-> 0],
      effectiveTime   |-> [i \in 1 .. 8 |-> 0] ]

(* Optional Order Add On at zero, then each field in turn at the values it is checked at *)
CheckedOptionalOrderAddOn ==
    { ZeroOptionalOrderAddOn }
        \cup { [ZeroOptionalOrderAddOn EXCEPT !.subMsgHeader = one] : one \in CheckedSubMsgHeader }
        \cup { [ZeroOptionalOrderAddOn EXCEPT !.deliverToCompId = one] : one \in Sample(5) }
        \cup { [ZeroOptionalOrderAddOn EXCEPT !.maxFloor = one] : one \in Sample(4) }
        \cup { [ZeroOptionalOrderAddOn EXCEPT !.locateBroker = one] : one \in Sample(4) }
        \cup { [ZeroOptionalOrderAddOn EXCEPT !.reserved8 = one] : one \in Sample(8) }
        \cup { [ZeroOptionalOrderAddOn EXCEPT !.offsetPrice = one] : one \in Sample(8) }
        \cup { [ZeroOptionalOrderAddOn EXCEPT !.effectiveTime = one] : one \in Sample(8) }

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
(* Optional Routing Strategy Add On: 32 bytes                              *)
(***************************************************************************)

OptionalRoutingStrategyAddOn ==
    [ subMsgHeader    : SubMsgHeader2,
      routingStrategy : Sample(1),
      reserved27      : Sample(27) ]

EncodeOptionalRoutingStrategyAddOn(message) ==
    EncodeSubMsgHeader2(message.subMsgHeader)
        \o message.routingStrategy
        \o message.reserved27

DecodeOptionalRoutingStrategyAddOn(bytes) ==
    LET subMsgHeader == DecodeSubMsgHeader2(bytes) IN IF ~subMsgHeader.ok THEN Fail ELSE
    LET routingStrategy == ReadBytes(subMsgHeader.rest, 1) IN IF ~routingStrategy.ok THEN Fail ELSE
    LET reserved27 == ReadBytes(routingStrategy.rest, 27) IN IF ~reserved27.ok THEN Fail ELSE
    Ok([ subMsgHeader    |-> subMsgHeader.value,
         routingStrategy |-> routingStrategy.value,
         reserved27      |-> reserved27.value ], reserved27.rest)

ZeroOptionalRoutingStrategyAddOn ==
    [ subMsgHeader    |-> ZeroSubMsgHeader2,
      routingStrategy |-> [i \in 1 .. 1 |-> 0],
      reserved27      |-> [i \in 1 .. 27 |-> 0] ]

(* Optional Routing Strategy Add On at zero, then each field in turn at the values it is checked at *)
CheckedOptionalRoutingStrategyAddOn ==
    { ZeroOptionalRoutingStrategyAddOn }
        \cup { [ZeroOptionalRoutingStrategyAddOn EXCEPT !.subMsgHeader = one] : one \in CheckedSubMsgHeader2 }
        \cup { [ZeroOptionalRoutingStrategyAddOn EXCEPT !.routingStrategy = one] : one \in Sample(1) }
        \cup { [ZeroOptionalRoutingStrategyAddOn EXCEPT !.reserved27 = one] : one \in Sample(27) }

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
(* Optional Settlement Type Add On: 5 bytes                                *)
(***************************************************************************)

OptionalSettlementTypeAddOn ==
    [ subMsgHeader   : SubMsgHeader3,
      settlementType : Sample(1) ]

EncodeOptionalSettlementTypeAddOn(message) ==
    EncodeSubMsgHeader3(message.subMsgHeader)
        \o message.settlementType

DecodeOptionalSettlementTypeAddOn(bytes) ==
    LET subMsgHeader == DecodeSubMsgHeader3(bytes) IN IF ~subMsgHeader.ok THEN Fail ELSE
    LET settlementType == ReadBytes(subMsgHeader.rest, 1) IN IF ~settlementType.ok THEN Fail ELSE
    Ok([ subMsgHeader   |-> subMsgHeader.value,
         settlementType |-> settlementType.value ], settlementType.rest)

ZeroOptionalSettlementTypeAddOn ==
    [ subMsgHeader   |-> ZeroSubMsgHeader3,
      settlementType |-> [i \in 1 .. 1 |-> 0] ]

(* Optional Settlement Type Add On at zero, then each field in turn at the values it is checked at *)
CheckedOptionalSettlementTypeAddOn ==
    { ZeroOptionalSettlementTypeAddOn }
        \cup { [ZeroOptionalSettlementTypeAddOn EXCEPT !.subMsgHeader = one] : one \in CheckedSubMsgHeader3 }
        \cup { [ZeroOptionalSettlementTypeAddOn EXCEPT !.settlementType = one] : one \in Sample(1) }

(***************************************************************************)
(* What Seq Msg Length decides is present                                  *)
(***************************************************************************)

OptionalOrderAddOnCode == 106  \* 0x6a
OptionalRoutingStrategyAddOnCode == 97  \* 0x61
OptionalSettlementTypeAddOnCode == 70  \* 0x46
SeqMsgLengthNoneCode == 65  \* 

SeqMsgLengthChoice ==
    [ tag : {OptionalOrderAddOnCode}, body : OptionalOrderAddOn ]
        \cup [ tag : {OptionalRoutingStrategyAddOnCode}, body : OptionalRoutingStrategyAddOn ]
        \cup [ tag : {OptionalSettlementTypeAddOnCode}, body : OptionalSettlementTypeAddOn ]
        \cup [ tag : {SeqMsgLengthNoneCode}, body : {[empty |-> 0]} ]

EncodeSeqMsgLengthChoice(message) ==
    CASE message.tag = OptionalOrderAddOnCode -> EncodeOptionalOrderAddOn(message.body)
      [] message.tag = OptionalRoutingStrategyAddOnCode -> EncodeOptionalRoutingStrategyAddOn(message.body)
      [] message.tag = OptionalSettlementTypeAddOnCode -> EncodeOptionalSettlementTypeAddOn(message.body)
      [] OTHER -> << >>

DecodeSeqMsgLengthChoice(tag, bytes) ==
    LET read ==
            CASE tag = OptionalOrderAddOnCode -> DecodeOptionalOrderAddOn(bytes)
              [] tag = OptionalRoutingStrategyAddOnCode -> DecodeOptionalRoutingStrategyAddOn(bytes)
              [] tag = OptionalSettlementTypeAddOnCode -> DecodeOptionalSettlementTypeAddOn(bytes)
              [] OTHER -> Ok([empty |-> 0], bytes)
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSeqMsgLengthChoice == [tag |-> OptionalOrderAddOnCode, body |-> ZeroOptionalOrderAddOn]

(* Each Seq Msg Length in turn, at the values the message it names is checked at *)
CheckedSeqMsgLengthChoice ==
    { [tag |-> OptionalOrderAddOnCode, body |-> one] : one \in CheckedOptionalOrderAddOn }
        \cup { [tag |-> OptionalRoutingStrategyAddOnCode, body |-> one] : one \in CheckedOptionalRoutingStrategyAddOn }
        \cup { [tag |-> OptionalSettlementTypeAddOnCode, body |-> one] : one \in CheckedOptionalSettlementTypeAddOn }
        \cup { [tag |-> SeqMsgLengthNoneCode, body |-> [empty |-> 0]] }

(***************************************************************************)
(* New Order Single And Cancel Replace Request Message                     *)
(***************************************************************************)

NewOrderSingleAndCancelReplaceRequestMessage ==
    [ symbolId                  : Sample(4),
      mpid                      : Sample(4),
      mmid                      : Sample(4),
      mpsubid1                  : Sample(1),
      clOrdId                   : Sample(8),
      origClOrdId               : Sample(8),
      bitfieldOrderInstructions : Sample(8),
      price                     : Sample(8),
      orderQty                  : Sample(4),
      minQty                    : Sample(4),
      userData                  : Sample(8),
      seqMsgLengthChoice        : SeqMsgLengthChoice ]

EncodeNewOrderSingleAndCancelReplaceRequestMessage(message) ==
    message.symbolId
        \o message.mpid
        \o message.mmid
        \o message.mpsubid1
        \o message.clOrdId
        \o message.origClOrdId
        \o message.bitfieldOrderInstructions
        \o message.price
        \o message.orderQty
        \o message.minQty
        \o message.userData
        \o EncodeSeqMsgLengthChoice(message.seqMsgLengthChoice)

DecodeNewOrderSingleAndCancelReplaceRequestMessage(bytes) ==
    LET symbolId == ReadBytes(bytes, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET mpid == ReadBytes(symbolId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET mmid == ReadBytes(mpid.rest, 4) IN IF ~mmid.ok THEN Fail ELSE
    LET mpsubid1 == ReadBytes(mmid.rest, 1) IN IF ~mpsubid1.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(mpsubid1.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET bitfieldOrderInstructions == ReadBytes(origClOrdId.rest, 8) IN IF ~bitfieldOrderInstructions.ok THEN Fail ELSE
    LET price == ReadBytes(bitfieldOrderInstructions.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderQty == ReadBytes(price.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET minQty == ReadBytes(orderQty.rest, 4) IN IF ~minQty.ok THEN Fail ELSE
    LET userData == ReadBytes(minQty.rest, 8) IN IF ~userData.ok THEN Fail ELSE
    LET seqMsgLengthChoice == DecodeSeqMsgLengthChoice(Len(bytes) + 4, userData.rest) IN IF ~seqMsgLengthChoice.ok THEN Fail ELSE
    Ok([ symbolId                  |-> symbolId.value,
         mpid                      |-> mpid.value,
         mmid                      |-> mmid.value,
         mpsubid1                  |-> mpsubid1.value,
         clOrdId                   |-> clOrdId.value,
         origClOrdId               |-> origClOrdId.value,
         bitfieldOrderInstructions |-> bitfieldOrderInstructions.value,
         price                     |-> price.value,
         orderQty                  |-> orderQty.value,
         minQty                    |-> minQty.value,
         userData                  |-> userData.value,
         seqMsgLengthChoice        |-> seqMsgLengthChoice.value ], seqMsgLengthChoice.rest)

ZeroNewOrderSingleAndCancelReplaceRequestMessage ==
    [ symbolId                  |-> [i \in 1 .. 4 |-> 0],
      mpid                      |-> [i \in 1 .. 4 |-> 0],
      mmid                      |-> [i \in 1 .. 4 |-> 0],
      mpsubid1                  |-> [i \in 1 .. 1 |-> 0],
      clOrdId                   |-> [i \in 1 .. 8 |-> 0],
      origClOrdId               |-> [i \in 1 .. 8 |-> 0],
      bitfieldOrderInstructions |-> [i \in 1 .. 8 |-> 0],
      price                     |-> [i \in 1 .. 8 |-> 0],
      orderQty                  |-> [i \in 1 .. 4 |-> 0],
      minQty                    |-> [i \in 1 .. 4 |-> 0],
      userData                  |-> [i \in 1 .. 8 |-> 0],
      seqMsgLengthChoice        |-> ZeroSeqMsgLengthChoice ]

(* New Order Single And Cancel Replace Request Message at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderSingleAndCancelReplaceRequestMessage ==
    { ZeroNewOrderSingleAndCancelReplaceRequestMessage }
        \cup { [ZeroNewOrderSingleAndCancelReplaceRequestMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleAndCancelReplaceRequestMessage EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleAndCancelReplaceRequestMessage EXCEPT !.mmid = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleAndCancelReplaceRequestMessage EXCEPT !.mpsubid1 = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleAndCancelReplaceRequestMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleAndCancelReplaceRequestMessage EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleAndCancelReplaceRequestMessage EXCEPT !.bitfieldOrderInstructions = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleAndCancelReplaceRequestMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleAndCancelReplaceRequestMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleAndCancelReplaceRequestMessage EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleAndCancelReplaceRequestMessage EXCEPT !.userData = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleAndCancelReplaceRequestMessage EXCEPT !.seqMsgLengthChoice = one] : one \in CheckedSeqMsgLengthChoice }

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
      side          : Sample(1),
      locateReqdU81 : Sample(1) ]

EncodeOrderModifyRequestMessage(message) ==
    message.symbolId
        \o message.mpid
        \o message.clOrdId
        \o message.origClOrdId
        \o message.orderQty
        \o message.side
        \o message.locateReqdU81

DecodeOrderModifyRequestMessage(bytes) ==
    LET symbolId == ReadBytes(bytes, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET mpid == ReadBytes(symbolId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(mpid.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(origClOrdId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET side == ReadBytes(orderQty.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET locateReqdU81 == ReadBytes(side.rest, 1) IN IF ~locateReqdU81.ok THEN Fail ELSE
    Ok([ symbolId      |-> symbolId.value,
         mpid          |-> mpid.value,
         clOrdId       |-> clOrdId.value,
         origClOrdId   |-> origClOrdId.value,
         orderQty      |-> orderQty.value,
         side          |-> side.value,
         locateReqdU81 |-> locateReqdU81.value ], locateReqdU81.rest)

ZeroOrderModifyRequestMessage ==
    [ symbolId      |-> [i \in 1 .. 4 |-> 0],
      mpid          |-> [i \in 1 .. 4 |-> 0],
      clOrdId       |-> [i \in 1 .. 8 |-> 0],
      origClOrdId   |-> [i \in 1 .. 8 |-> 0],
      orderQty      |-> [i \in 1 .. 4 |-> 0],
      side          |-> [i \in 1 .. 1 |-> 0],
      locateReqdU81 |-> [i \in 1 .. 1 |-> 0] ]

(* Order Modify Request Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderModifyRequestMessage ==
    { ZeroOrderModifyRequestMessage }
        \cup { [ZeroOrderModifyRequestMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyRequestMessage EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyRequestMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyRequestMessage EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyRequestMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyRequestMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifyRequestMessage EXCEPT !.locateReqdU81 = one] : one \in Sample(1) }

(***************************************************************************)
(* Bulk Cancel Request Message: 27 bytes                                   *)
(***************************************************************************)

BulkCancelRequestMessage ==
    [ symbolId        : Sample(4),
      mpid            : Sample(4),
      mmid            : Sample(4),
      clOrdId         : Sample(8),
      deliverToCompId : Sample(5),
      bulkCancelType  : Sample(1),
      side            : Sample(1) ]

EncodeBulkCancelRequestMessage(message) ==
    message.symbolId
        \o message.mpid
        \o message.mmid
        \o message.clOrdId
        \o message.deliverToCompId
        \o message.bulkCancelType
        \o message.side

DecodeBulkCancelRequestMessage(bytes) ==
    LET symbolId == ReadBytes(bytes, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET mpid == ReadBytes(symbolId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET mmid == ReadBytes(mpid.rest, 4) IN IF ~mmid.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(mmid.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET deliverToCompId == ReadBytes(clOrdId.rest, 5) IN IF ~deliverToCompId.ok THEN Fail ELSE
    LET bulkCancelType == ReadBytes(deliverToCompId.rest, 1) IN IF ~bulkCancelType.ok THEN Fail ELSE
    LET side == ReadBytes(bulkCancelType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    Ok([ symbolId        |-> symbolId.value,
         mpid            |-> mpid.value,
         mmid            |-> mmid.value,
         clOrdId         |-> clOrdId.value,
         deliverToCompId |-> deliverToCompId.value,
         bulkCancelType  |-> bulkCancelType.value,
         side            |-> side.value ], side.rest)

ZeroBulkCancelRequestMessage ==
    [ symbolId        |-> [i \in 1 .. 4 |-> 0],
      mpid            |-> [i \in 1 .. 4 |-> 0],
      mmid            |-> [i \in 1 .. 4 |-> 0],
      clOrdId         |-> [i \in 1 .. 8 |-> 0],
      deliverToCompId |-> [i \in 1 .. 5 |-> 0],
      bulkCancelType  |-> [i \in 1 .. 1 |-> 0],
      side            |-> [i \in 1 .. 1 |-> 0] ]

(* Bulk Cancel Request Message at zero, then each field in turn at the values it is checked at *)
CheckedBulkCancelRequestMessage ==
    { ZeroBulkCancelRequestMessage }
        \cup { [ZeroBulkCancelRequestMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroBulkCancelRequestMessage EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroBulkCancelRequestMessage EXCEPT !.mmid = one] : one \in Sample(4) }
        \cup { [ZeroBulkCancelRequestMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroBulkCancelRequestMessage EXCEPT !.deliverToCompId = one] : one \in Sample(5) }
        \cup { [ZeroBulkCancelRequestMessage EXCEPT !.bulkCancelType = one] : one \in Sample(1) }
        \cup { [ZeroBulkCancelRequestMessage EXCEPT !.side = one] : one \in Sample(1) }

(***************************************************************************)
(* Symbol Subscription Request Message: 20 bytes                           *)
(***************************************************************************)

SymbolSubscriptionRequestMessage ==
    [ symbolId : Sample(4),
      username : Sample(16) ]

EncodeSymbolSubscriptionRequestMessage(message) ==
    message.symbolId
        \o message.username

DecodeSymbolSubscriptionRequestMessage(bytes) ==
    LET symbolId == ReadBytes(bytes, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET username == ReadBytes(symbolId.rest, 16) IN IF ~username.ok THEN Fail ELSE
    Ok([ symbolId |-> symbolId.value,
         username |-> username.value ], username.rest)

ZeroSymbolSubscriptionRequestMessage ==
    [ symbolId |-> [i \in 1 .. 4 |-> 0],
      username |-> [i \in 1 .. 16 |-> 0] ]

(* Symbol Subscription Request Message at zero, then each field in turn at the values it is checked at *)
CheckedSymbolSubscriptionRequestMessage ==
    { ZeroSymbolSubscriptionRequestMessage }
        \cup { [ZeroSymbolSubscriptionRequestMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroSymbolSubscriptionRequestMessage EXCEPT !.username = one] : one \in Sample(16) }

(***************************************************************************)
(* Stream Id: 8 bytes                                                      *)
(***************************************************************************)

StreamId4 ==
    [ sess  : Sample(4),
      value : Sample(4) ]

EncodeStreamId4(message) ==
    message.sess
        \o message.value

DecodeStreamId4(bytes) ==
    LET sess == ReadBytes(bytes, 4) IN IF ~sess.ok THEN Fail ELSE
    LET value == ReadBytes(sess.rest, 4) IN IF ~value.ok THEN Fail ELSE
    Ok([ sess  |-> sess.value,
         value |-> value.value ], value.rest)

ZeroStreamId4 ==
    [ sess  |-> [i \in 1 .. 4 |-> 0],
      value |-> [i \in 1 .. 4 |-> 0] ]

(* Stream Id at zero, then each field in turn at the values it is checked at *)
CheckedStreamId4 ==
    { ZeroStreamId4 }
        \cup { [ZeroStreamId4 EXCEPT !.sess = one] : one \in Sample(4) }
        \cup { [ZeroStreamId4 EXCEPT !.value = one] : one \in Sample(4) }

(***************************************************************************)
(* Manual Action Id: 16 bytes                                              *)
(***************************************************************************)

ManualActionId ==
    [ streamId : StreamId4,
      seq      : Sample(8) ]

EncodeManualActionId(message) ==
    EncodeStreamId4(message.streamId)
        \o message.seq

DecodeManualActionId(bytes) ==
    LET streamId == DecodeStreamId4(bytes) IN IF ~streamId.ok THEN Fail ELSE
    LET seq == ReadBytes(streamId.rest, 8) IN IF ~seq.ok THEN Fail ELSE
    Ok([ streamId |-> streamId.value,
         seq      |-> seq.value ], seq.rest)

ZeroManualActionId ==
    [ streamId |-> ZeroStreamId4,
      seq      |-> [i \in 1 .. 8 |-> 0] ]

(* Manual Action Id at zero, then each field in turn at the values it is checked at *)
CheckedManualActionId ==
    { ZeroManualActionId }
        \cup { [ZeroManualActionId EXCEPT !.streamId = one] : one \in CheckedStreamId4 }
        \cup { [ZeroManualActionId EXCEPT !.seq = one] : one \in Sample(8) }

(***************************************************************************)
(* Manual Action Response Message: 65 bytes                                *)
(***************************************************************************)

ManualActionResponseMessage ==
    [ symbolId             : Sample(4),
      clOrdId              : Sample(8),
      manualActionId       : ManualActionId,
      sellIndicator        : Sample(1),
      intradaySellShortQty : Sample(4),
      mpsubid1             : Sample(1),
      locateReqdU81        : Sample(1),
      selfTradeTypeBits    : Sample(1),
      userData             : Sample(8),
      manualResponseType   : Sample(1),
      dmmRejectReason      : Sample(20) ]

EncodeManualActionResponseMessage(message) ==
    message.symbolId
        \o message.clOrdId
        \o EncodeManualActionId(message.manualActionId)
        \o message.sellIndicator
        \o message.intradaySellShortQty
        \o message.mpsubid1
        \o message.locateReqdU81
        \o message.selfTradeTypeBits
        \o message.userData
        \o message.manualResponseType
        \o message.dmmRejectReason

DecodeManualActionResponseMessage(bytes) ==
    LET symbolId == ReadBytes(bytes, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(symbolId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET manualActionId == DecodeManualActionId(clOrdId.rest) IN IF ~manualActionId.ok THEN Fail ELSE
    LET sellIndicator == ReadBytes(manualActionId.rest, 1) IN IF ~sellIndicator.ok THEN Fail ELSE
    LET intradaySellShortQty == ReadBytes(sellIndicator.rest, 4) IN IF ~intradaySellShortQty.ok THEN Fail ELSE
    LET mpsubid1 == ReadBytes(intradaySellShortQty.rest, 1) IN IF ~mpsubid1.ok THEN Fail ELSE
    LET locateReqdU81 == ReadBytes(mpsubid1.rest, 1) IN IF ~locateReqdU81.ok THEN Fail ELSE
    LET selfTradeTypeBits == ReadBytes(locateReqdU81.rest, 1) IN IF ~selfTradeTypeBits.ok THEN Fail ELSE
    LET userData == ReadBytes(selfTradeTypeBits.rest, 8) IN IF ~userData.ok THEN Fail ELSE
    LET manualResponseType == ReadBytes(userData.rest, 1) IN IF ~manualResponseType.ok THEN Fail ELSE
    LET dmmRejectReason == ReadBytes(manualResponseType.rest, 20) IN IF ~dmmRejectReason.ok THEN Fail ELSE
    Ok([ symbolId             |-> symbolId.value,
         clOrdId              |-> clOrdId.value,
         manualActionId       |-> manualActionId.value,
         sellIndicator        |-> sellIndicator.value,
         intradaySellShortQty |-> intradaySellShortQty.value,
         mpsubid1             |-> mpsubid1.value,
         locateReqdU81        |-> locateReqdU81.value,
         selfTradeTypeBits    |-> selfTradeTypeBits.value,
         userData             |-> userData.value,
         manualResponseType   |-> manualResponseType.value,
         dmmRejectReason      |-> dmmRejectReason.value ], dmmRejectReason.rest)

ZeroManualActionResponseMessage ==
    [ symbolId             |-> [i \in 1 .. 4 |-> 0],
      clOrdId              |-> [i \in 1 .. 8 |-> 0],
      manualActionId       |-> ZeroManualActionId,
      sellIndicator        |-> [i \in 1 .. 1 |-> 0],
      intradaySellShortQty |-> [i \in 1 .. 4 |-> 0],
      mpsubid1             |-> [i \in 1 .. 1 |-> 0],
      locateReqdU81        |-> [i \in 1 .. 1 |-> 0],
      selfTradeTypeBits    |-> [i \in 1 .. 1 |-> 0],
      userData             |-> [i \in 1 .. 8 |-> 0],
      manualResponseType   |-> [i \in 1 .. 1 |-> 0],
      dmmRejectReason      |-> [i \in 1 .. 20 |-> 0] ]

(* Manual Action Response Message at zero, then each field in turn at the values it is checked at *)
CheckedManualActionResponseMessage ==
    { ZeroManualActionResponseMessage }
        \cup { [ZeroManualActionResponseMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroManualActionResponseMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroManualActionResponseMessage EXCEPT !.manualActionId = one] : one \in CheckedManualActionId }
        \cup { [ZeroManualActionResponseMessage EXCEPT !.sellIndicator = one] : one \in Sample(1) }
        \cup { [ZeroManualActionResponseMessage EXCEPT !.intradaySellShortQty = one] : one \in Sample(4) }
        \cup { [ZeroManualActionResponseMessage EXCEPT !.mpsubid1 = one] : one \in Sample(1) }
        \cup { [ZeroManualActionResponseMessage EXCEPT !.locateReqdU81 = one] : one \in Sample(1) }
        \cup { [ZeroManualActionResponseMessage EXCEPT !.selfTradeTypeBits = one] : one \in Sample(1) }
        \cup { [ZeroManualActionResponseMessage EXCEPT !.userData = one] : one \in Sample(8) }
        \cup { [ZeroManualActionResponseMessage EXCEPT !.manualResponseType = one] : one \in Sample(1) }
        \cup { [ZeroManualActionResponseMessage EXCEPT !.dmmRejectReason = one] : one \in Sample(20) }

(***************************************************************************)
(* Risk Limit Update Request Message: 268 bytes                            *)
(***************************************************************************)

RiskLimitUpdateRequestMessage ==
    [ symbolId              : Sample(4),
      mpid                  : Sample(4),
      marketMakerNul        : Sample(10),
      mpsubid4              : Sample(4),
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
        \o message.marketMakerNul
        \o message.mpsubid4
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
    LET marketMakerNul == ReadBytes(mpid.rest, 10) IN IF ~marketMakerNul.ok THEN Fail ELSE
    LET mpsubid4 == ReadBytes(marketMakerNul.rest, 4) IN IF ~mpsubid4.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(mpsubid4.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
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
         marketMakerNul        |-> marketMakerNul.value,
         mpsubid4              |-> mpsubid4.value,
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
      marketMakerNul        |-> [i \in 1 .. 10 |-> 0],
      mpsubid4              |-> [i \in 1 .. 4 |-> 0],
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
        \cup { [ZeroRiskLimitUpdateRequestMessage EXCEPT !.marketMakerNul = one] : one \in Sample(10) }
        \cup { [ZeroRiskLimitUpdateRequestMessage EXCEPT !.mpsubid4 = one] : one \in Sample(4) }
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
      marketMakerNul  : Sample(10),
      mpsubid4        : Sample(4),
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
        \o message.marketMakerNul
        \o message.mpsubid4
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
    LET marketMakerNul == ReadBytes(mpid.rest, 10) IN IF ~marketMakerNul.ok THEN Fail ELSE
    LET mpsubid4 == ReadBytes(marketMakerNul.rest, 4) IN IF ~mpsubid4.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(mpsubid4.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
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
         marketMakerNul  |-> marketMakerNul.value,
         mpsubid4        |-> mpsubid4.value,
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
      marketMakerNul  |-> [i \in 1 .. 10 |-> 0],
      mpsubid4        |-> [i \in 1 .. 4 |-> 0],
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
        \cup { [ZeroRiskActionRequestMessage EXCEPT !.marketMakerNul = one] : one \in Sample(10) }
        \cup { [ZeroRiskActionRequestMessage EXCEPT !.mpsubid4 = one] : one \in Sample(4) }
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
(* Client Sequenced Message, selected by Seq Msg Type                      *)
(***************************************************************************)

SessionConfigurationRequestMessageCode == 544  \* 0x220
SequencedFillerMessageCode == 642  \* 0x282
NewOrderSingleAndCancelReplaceRequestMessageCode == 576  \* 0x240
OrderCancelRequestMessageCode == 640  \* 0x280
OrderModifyRequestMessageCode == 624  \* 0x270
BulkCancelRequestMessageCode == 641  \* 0x281
SymbolSubscriptionRequestMessageCode == 838  \* 0x346
TgBeginMessageCode == 835  \* 0x343
TgEndMessageCode == 836  \* 0x344
ManualActionResponseMessageCode == 852  \* 0x354
RiskLimitUpdateRequestMessageCode == 816  \* 0x330
RiskActionRequestMessageCode == 817  \* 0x331

ClientSequencedMessage ==
    [ tag : {SessionConfigurationRequestMessageCode}, body : SessionConfigurationRequestMessage ]
        \cup [ tag : {SequencedFillerMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {NewOrderSingleAndCancelReplaceRequestMessageCode}, body : NewOrderSingleAndCancelReplaceRequestMessage ]
        \cup [ tag : {OrderCancelRequestMessageCode}, body : OrderCancelRequestMessage ]
        \cup [ tag : {OrderModifyRequestMessageCode}, body : OrderModifyRequestMessage ]
        \cup [ tag : {BulkCancelRequestMessageCode}, body : BulkCancelRequestMessage ]
        \cup [ tag : {SymbolSubscriptionRequestMessageCode}, body : SymbolSubscriptionRequestMessage ]
        \cup [ tag : {TgBeginMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {TgEndMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ManualActionResponseMessageCode}, body : ManualActionResponseMessage ]
        \cup [ tag : {RiskLimitUpdateRequestMessageCode}, body : RiskLimitUpdateRequestMessage ]
        \cup [ tag : {RiskActionRequestMessageCode}, body : RiskActionRequestMessage ]

EncodeClientSequencedMessage(message) ==
    CASE message.tag = SessionConfigurationRequestMessageCode -> EncodeSessionConfigurationRequestMessage(message.body)
      [] message.tag = SequencedFillerMessageCode -> << >>
      [] message.tag = NewOrderSingleAndCancelReplaceRequestMessageCode -> EncodeNewOrderSingleAndCancelReplaceRequestMessage(message.body)
      [] message.tag = OrderCancelRequestMessageCode -> EncodeOrderCancelRequestMessage(message.body)
      [] message.tag = OrderModifyRequestMessageCode -> EncodeOrderModifyRequestMessage(message.body)
      [] message.tag = BulkCancelRequestMessageCode -> EncodeBulkCancelRequestMessage(message.body)
      [] message.tag = SymbolSubscriptionRequestMessageCode -> EncodeSymbolSubscriptionRequestMessage(message.body)
      [] message.tag = TgBeginMessageCode -> << >>
      [] message.tag = TgEndMessageCode -> << >>
      [] message.tag = ManualActionResponseMessageCode -> EncodeManualActionResponseMessage(message.body)
      [] message.tag = RiskLimitUpdateRequestMessageCode -> EncodeRiskLimitUpdateRequestMessage(message.body)
      [] message.tag = RiskActionRequestMessageCode -> EncodeRiskActionRequestMessage(message.body)

DecodeClientSequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = SessionConfigurationRequestMessageCode -> DecodeSessionConfigurationRequestMessage(bytes)
              [] tag = SequencedFillerMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = NewOrderSingleAndCancelReplaceRequestMessageCode -> DecodeNewOrderSingleAndCancelReplaceRequestMessage(bytes)
              [] tag = OrderCancelRequestMessageCode -> DecodeOrderCancelRequestMessage(bytes)
              [] tag = OrderModifyRequestMessageCode -> DecodeOrderModifyRequestMessage(bytes)
              [] tag = BulkCancelRequestMessageCode -> DecodeBulkCancelRequestMessage(bytes)
              [] tag = SymbolSubscriptionRequestMessageCode -> DecodeSymbolSubscriptionRequestMessage(bytes)
              [] tag = TgBeginMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = TgEndMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = ManualActionResponseMessageCode -> DecodeManualActionResponseMessage(bytes)
              [] tag = RiskLimitUpdateRequestMessageCode -> DecodeRiskLimitUpdateRequestMessage(bytes)
              [] tag = RiskActionRequestMessageCode -> DecodeRiskActionRequestMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroClientSequencedMessage == [tag |-> SessionConfigurationRequestMessageCode, body |-> ZeroSessionConfigurationRequestMessage]

(* Each Client Sequenced Message in turn, at the values the message it names is checked at *)
CheckedClientSequencedMessage ==
    { [tag |-> SessionConfigurationRequestMessageCode, body |-> one] : one \in CheckedSessionConfigurationRequestMessage }
        \cup { [tag |-> SequencedFillerMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> NewOrderSingleAndCancelReplaceRequestMessageCode, body |-> one] : one \in CheckedNewOrderSingleAndCancelReplaceRequestMessage }
        \cup { [tag |-> OrderCancelRequestMessageCode, body |-> one] : one \in CheckedOrderCancelRequestMessage }
        \cup { [tag |-> OrderModifyRequestMessageCode, body |-> one] : one \in CheckedOrderModifyRequestMessage }
        \cup { [tag |-> BulkCancelRequestMessageCode, body |-> one] : one \in CheckedBulkCancelRequestMessage }
        \cup { [tag |-> SymbolSubscriptionRequestMessageCode, body |-> one] : one \in CheckedSymbolSubscriptionRequestMessage }
        \cup { [tag |-> TgBeginMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> TgEndMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> ManualActionResponseMessageCode, body |-> one] : one \in CheckedManualActionResponseMessage }
        \cup { [tag |-> RiskLimitUpdateRequestMessageCode, body |-> one] : one \in CheckedRiskLimitUpdateRequestMessage }
        \cup { [tag |-> RiskActionRequestMessageCode, body |-> one] : one \in CheckedRiskActionRequestMessage }

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

(* Every Sub Msg Header decodes back to what was encoded, and leaves nothing over *)
RoundTripSubMsgHeader2 ==
    \A message \in CheckedSubMsgHeader2 :
        LET read == DecodeSubMsgHeader2(EncodeSubMsgHeader2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Optional Routing Strategy Add On decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionalRoutingStrategyAddOn ==
    \A message \in CheckedOptionalRoutingStrategyAddOn :
        LET read == DecodeOptionalRoutingStrategyAddOn(EncodeOptionalRoutingStrategyAddOn(message))
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

(* Every Optional Settlement Type Add On decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionalSettlementTypeAddOn ==
    \A message \in CheckedOptionalSettlementTypeAddOn :
        LET read == DecodeOptionalSettlementTypeAddOn(EncodeOptionalSettlementTypeAddOn(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Single And Cancel Replace Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderSingleAndCancelReplaceRequestMessage ==
    \A message \in CheckedNewOrderSingleAndCancelReplaceRequestMessage :
        LET read == DecodeNewOrderSingleAndCancelReplaceRequestMessage(EncodeNewOrderSingleAndCancelReplaceRequestMessage(message))
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

(* Every Bulk Cancel Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkCancelRequestMessage ==
    \A message \in CheckedBulkCancelRequestMessage :
        LET read == DecodeBulkCancelRequestMessage(EncodeBulkCancelRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol Subscription Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolSubscriptionRequestMessage ==
    \A message \in CheckedSymbolSubscriptionRequestMessage :
        LET read == DecodeSymbolSubscriptionRequestMessage(EncodeSymbolSubscriptionRequestMessage(message))
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

(* Every Manual Action Id decodes back to what was encoded, and leaves nothing over *)
RoundTripManualActionId ==
    \A message \in CheckedManualActionId :
        LET read == DecodeManualActionId(EncodeManualActionId(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Manual Action Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripManualActionResponseMessage ==
    \A message \in CheckedManualActionResponseMessage :
        LET read == DecodeManualActionResponseMessage(EncodeManualActionResponseMessage(message))
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
