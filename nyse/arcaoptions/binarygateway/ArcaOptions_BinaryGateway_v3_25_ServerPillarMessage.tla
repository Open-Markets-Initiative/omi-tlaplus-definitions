-------- MODULE ArcaOptions_BinaryGateway_v3_25_ServerPillarMessage --------
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
(* Note: Server Message is chosen by the Msg Type each of its messages     *)
(* begins with: those 2 bytes are read at offset 0 before one is picked,   *)
(* and each message states its own.                                        *)
(*                                                                         *)
(* Note: Server Sequenced Message is framed by Seq Msg Length, which       *)
(* states the 4 bytes of Seq Msg Header beside it and the message that     *)
(* follows: the choice is read from that many bytes and must take them     *)
(* all.                                                                    *)
(*                                                                         *)
(* Note: Underlying Symbol Reference Data Message is as wide as Seq Msg    *)
(* Length says, which is the frame it is read from.                        *)
(*                                                                         *)
(* Note: Series Reference Data Message is as wide as Seq Msg Length says,  *)
(* which is the frame it is read from.                                     *)
(*                                                                         *)
(* Note: Minimum Price Variant Class Reference Data Message is as wide as  *)
(* Seq Msg Length says, which is the frame it is read from.                *)
(*                                                                         *)
(* Note: Minimum Price Variant Level Reference Data Message is as wide as  *)
(* Seq Msg Length says, which is the frame it is read from.                *)
(*                                                                         *)
(* Note: Mpid Configuration Message is as wide as Seq Msg Length says,     *)
(* which is the frame it is read from.                                     *)
(*                                                                         *)
(* Note: Options Market Maker Symbol Appointment Reference Data Message is *)
(* as wide as Seq Msg Length says, which is the frame it is read from.     *)
(*                                                                         *)
(* Note: Session Configuration Acknowledgement Message is as wide as Seq   *)
(* Msg Length says, which is the frame it is read from.                    *)
(*                                                                         *)
(* Note: Seq Msg Length frames this record, so it is as long as what the   *)
(* record holds: 137 carries none of them, and each of the others states   *)
(* its own length.                                                         *)
(*                                                                         *)
(* Note: Order And Cancel Replace Acknowledgement Message is as wide as    *)
(* Seq Msg Length says, which is the frame it is read from.                *)
(*                                                                         *)
(* Note: Bulk Quote Acknowledgment Message is as wide as Seq Msg Length    *)
(* says, which is the frame it is read from.                               *)
(*                                                                         *)
(* Note: Bulk Quote Acknowledgment With Details Message is as wide as Seq  *)
(* Msg Length says, which is the frame it is read from.                    *)
(*                                                                         *)
(* Note: Order Single Complex Modify Cancel Request Acknowledgment And     *)
(* Urout Message is as wide as Seq Msg Length says, which is the frame it  *)
(* is read from.                                                           *)
(*                                                                         *)
(* Note: Order Priority Update Acknowledgment Message is as wide as Seq    *)
(* Msg Length says, which is the frame it is read from.                    *)
(*                                                                         *)
(* Note: Seq Msg Length frames this record, so it is as long as what the   *)
(* record holds: 136 carries none of them, and each of the others states   *)
(* its own length.                                                         *)
(*                                                                         *)
(* Note: Execution Report Message is as wide as Seq Msg Length says, which *)
(* is the frame it is read from.                                           *)
(*                                                                         *)
(* Note: Trade Bust Correct Message is as wide as Seq Msg Length says,     *)
(* which is the frame it is read from.                                     *)
(*                                                                         *)
(* Note: Application Layer Reject Message is as wide as Seq Msg Length     *)
(* says, which is the frame it is read from.                               *)
(*                                                                         *)
(* Note: Risk Control Acknowledgement Message is as wide as Seq Msg Length *)
(* says, which is the frame it is read from.                               *)
(*                                                                         *)
(* Note: Risk Control Alert Message is as wide as Seq Msg Length says,     *)
(* which is the frame it is read from.                                     *)
(*                                                                         *)
(* Note: Complex Series Request Acknowledgement Message is as wide as Seq  *)
(* Msg Length says, which is the frame it is read from.                    *)
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
(* Underlying Symbol Reference Data Message: 54 bytes                      *)
(***************************************************************************)

UnderlyingSymbolReferenceDataMessage ==
    [ transactTime         : Sample(8),
      symbolId             : Sample(4),
      nyseSymbol           : Sample(24),
      listedMic            : Sample(4),
      underlyingType       : Sample(1),
      maxOrderPrice        : Sample(8),
      mpvClassId           : Sample(2),
      testSymbolIndicator  : Sample(1),
      channelId            : Sample(1),
      legalWidthMultiplier : Sample(1) ]

EncodeUnderlyingSymbolReferenceDataMessage(message) ==
    message.transactTime
        \o message.symbolId
        \o message.nyseSymbol
        \o message.listedMic
        \o message.underlyingType
        \o message.maxOrderPrice
        \o message.mpvClassId
        \o message.testSymbolIndicator
        \o message.channelId
        \o message.legalWidthMultiplier

DecodeUnderlyingSymbolReferenceDataMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET symbolId == ReadBytes(transactTime.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET nyseSymbol == ReadBytes(symbolId.rest, 24) IN IF ~nyseSymbol.ok THEN Fail ELSE
    LET listedMic == ReadBytes(nyseSymbol.rest, 4) IN IF ~listedMic.ok THEN Fail ELSE
    LET underlyingType == ReadBytes(listedMic.rest, 1) IN IF ~underlyingType.ok THEN Fail ELSE
    LET maxOrderPrice == ReadBytes(underlyingType.rest, 8) IN IF ~maxOrderPrice.ok THEN Fail ELSE
    LET mpvClassId == ReadBytes(maxOrderPrice.rest, 2) IN IF ~mpvClassId.ok THEN Fail ELSE
    LET testSymbolIndicator == ReadBytes(mpvClassId.rest, 1) IN IF ~testSymbolIndicator.ok THEN Fail ELSE
    LET channelId == ReadBytes(testSymbolIndicator.rest, 1) IN IF ~channelId.ok THEN Fail ELSE
    LET legalWidthMultiplier == ReadBytes(channelId.rest, 1) IN IF ~legalWidthMultiplier.ok THEN Fail ELSE
    Ok([ transactTime         |-> transactTime.value,
         symbolId             |-> symbolId.value,
         nyseSymbol           |-> nyseSymbol.value,
         listedMic            |-> listedMic.value,
         underlyingType       |-> underlyingType.value,
         maxOrderPrice        |-> maxOrderPrice.value,
         mpvClassId           |-> mpvClassId.value,
         testSymbolIndicator  |-> testSymbolIndicator.value,
         channelId            |-> channelId.value,
         legalWidthMultiplier |-> legalWidthMultiplier.value ], legalWidthMultiplier.rest)

ZeroUnderlyingSymbolReferenceDataMessage ==
    [ transactTime         |-> [i \in 1 .. 8 |-> 0],
      symbolId             |-> [i \in 1 .. 4 |-> 0],
      nyseSymbol           |-> [i \in 1 .. 24 |-> 0],
      listedMic            |-> [i \in 1 .. 4 |-> 0],
      underlyingType       |-> [i \in 1 .. 1 |-> 0],
      maxOrderPrice        |-> [i \in 1 .. 8 |-> 0],
      mpvClassId           |-> [i \in 1 .. 2 |-> 0],
      testSymbolIndicator  |-> [i \in 1 .. 1 |-> 0],
      channelId            |-> [i \in 1 .. 1 |-> 0],
      legalWidthMultiplier |-> [i \in 1 .. 1 |-> 0] ]

(* Underlying Symbol Reference Data Message at zero, then each field in turn at the values it is checked at *)
CheckedUnderlyingSymbolReferenceDataMessage ==
    { ZeroUnderlyingSymbolReferenceDataMessage }
        \cup { [ZeroUnderlyingSymbolReferenceDataMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroUnderlyingSymbolReferenceDataMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingSymbolReferenceDataMessage EXCEPT !.nyseSymbol = one] : one \in Sample(24) }
        \cup { [ZeroUnderlyingSymbolReferenceDataMessage EXCEPT !.listedMic = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingSymbolReferenceDataMessage EXCEPT !.underlyingType = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingSymbolReferenceDataMessage EXCEPT !.maxOrderPrice = one] : one \in Sample(8) }
        \cup { [ZeroUnderlyingSymbolReferenceDataMessage EXCEPT !.mpvClassId = one] : one \in Sample(2) }
        \cup { [ZeroUnderlyingSymbolReferenceDataMessage EXCEPT !.testSymbolIndicator = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingSymbolReferenceDataMessage EXCEPT !.channelId = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingSymbolReferenceDataMessage EXCEPT !.legalWidthMultiplier = one] : one \in Sample(1) }

(***************************************************************************)
(* Series Reference Data Message: 63 bytes                                 *)
(***************************************************************************)

SeriesReferenceDataMessage ==
    [ transactTime         : Sample(8),
      seriesIndex          : Sample(4),
      symbolId             : Sample(4),
      occSymbolRoot        : Sample(24),
      putOrCall            : Sample(1),
      strikePrice          : Sample(8),
      maturityDate         : Sample(8),
      contractMultiplier   : Sample(4),
      seriesType           : Sample(1),
      closingOnlyIndicator : Sample(1) ]

EncodeSeriesReferenceDataMessage(message) ==
    message.transactTime
        \o message.seriesIndex
        \o message.symbolId
        \o message.occSymbolRoot
        \o message.putOrCall
        \o message.strikePrice
        \o message.maturityDate
        \o message.contractMultiplier
        \o message.seriesType
        \o message.closingOnlyIndicator

DecodeSeriesReferenceDataMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET seriesIndex == ReadBytes(transactTime.rest, 4) IN IF ~seriesIndex.ok THEN Fail ELSE
    LET symbolId == ReadBytes(seriesIndex.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET occSymbolRoot == ReadBytes(symbolId.rest, 24) IN IF ~occSymbolRoot.ok THEN Fail ELSE
    LET putOrCall == ReadBytes(occSymbolRoot.rest, 1) IN IF ~putOrCall.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(putOrCall.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(strikePrice.rest, 8) IN IF ~maturityDate.ok THEN Fail ELSE
    LET contractMultiplier == ReadBytes(maturityDate.rest, 4) IN IF ~contractMultiplier.ok THEN Fail ELSE
    LET seriesType == ReadBytes(contractMultiplier.rest, 1) IN IF ~seriesType.ok THEN Fail ELSE
    LET closingOnlyIndicator == ReadBytes(seriesType.rest, 1) IN IF ~closingOnlyIndicator.ok THEN Fail ELSE
    Ok([ transactTime         |-> transactTime.value,
         seriesIndex          |-> seriesIndex.value,
         symbolId             |-> symbolId.value,
         occSymbolRoot        |-> occSymbolRoot.value,
         putOrCall            |-> putOrCall.value,
         strikePrice          |-> strikePrice.value,
         maturityDate         |-> maturityDate.value,
         contractMultiplier   |-> contractMultiplier.value,
         seriesType           |-> seriesType.value,
         closingOnlyIndicator |-> closingOnlyIndicator.value ], closingOnlyIndicator.rest)

ZeroSeriesReferenceDataMessage ==
    [ transactTime         |-> [i \in 1 .. 8 |-> 0],
      seriesIndex          |-> [i \in 1 .. 4 |-> 0],
      symbolId             |-> [i \in 1 .. 4 |-> 0],
      occSymbolRoot        |-> [i \in 1 .. 24 |-> 0],
      putOrCall            |-> [i \in 1 .. 1 |-> 0],
      strikePrice          |-> [i \in 1 .. 8 |-> 0],
      maturityDate         |-> [i \in 1 .. 8 |-> 0],
      contractMultiplier   |-> [i \in 1 .. 4 |-> 0],
      seriesType           |-> [i \in 1 .. 1 |-> 0],
      closingOnlyIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Series Reference Data Message at zero, then each field in turn at the values it is checked at *)
CheckedSeriesReferenceDataMessage ==
    { ZeroSeriesReferenceDataMessage }
        \cup { [ZeroSeriesReferenceDataMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroSeriesReferenceDataMessage EXCEPT !.seriesIndex = one] : one \in Sample(4) }
        \cup { [ZeroSeriesReferenceDataMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroSeriesReferenceDataMessage EXCEPT !.occSymbolRoot = one] : one \in Sample(24) }
        \cup { [ZeroSeriesReferenceDataMessage EXCEPT !.putOrCall = one] : one \in Sample(1) }
        \cup { [ZeroSeriesReferenceDataMessage EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroSeriesReferenceDataMessage EXCEPT !.maturityDate = one] : one \in Sample(8) }
        \cup { [ZeroSeriesReferenceDataMessage EXCEPT !.contractMultiplier = one] : one \in Sample(4) }
        \cup { [ZeroSeriesReferenceDataMessage EXCEPT !.seriesType = one] : one \in Sample(1) }
        \cup { [ZeroSeriesReferenceDataMessage EXCEPT !.closingOnlyIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Minimum Price Variant Class Reference Data Message: 46 bytes            *)
(***************************************************************************)

MinimumPriceVariantClassReferenceDataMessage ==
    [ transactTime : Sample(8),
      mpvClassName : Sample(20),
      mpvClassId   : Sample(2),
      rpimpv       : Sample(8),
      luldmpv      : Sample(8) ]

EncodeMinimumPriceVariantClassReferenceDataMessage(message) ==
    message.transactTime
        \o message.mpvClassName
        \o message.mpvClassId
        \o message.rpimpv
        \o message.luldmpv

DecodeMinimumPriceVariantClassReferenceDataMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET mpvClassName == ReadBytes(transactTime.rest, 20) IN IF ~mpvClassName.ok THEN Fail ELSE
    LET mpvClassId == ReadBytes(mpvClassName.rest, 2) IN IF ~mpvClassId.ok THEN Fail ELSE
    LET rpimpv == ReadBytes(mpvClassId.rest, 8) IN IF ~rpimpv.ok THEN Fail ELSE
    LET luldmpv == ReadBytes(rpimpv.rest, 8) IN IF ~luldmpv.ok THEN Fail ELSE
    Ok([ transactTime |-> transactTime.value,
         mpvClassName |-> mpvClassName.value,
         mpvClassId   |-> mpvClassId.value,
         rpimpv       |-> rpimpv.value,
         luldmpv      |-> luldmpv.value ], luldmpv.rest)

ZeroMinimumPriceVariantClassReferenceDataMessage ==
    [ transactTime |-> [i \in 1 .. 8 |-> 0],
      mpvClassName |-> [i \in 1 .. 20 |-> 0],
      mpvClassId   |-> [i \in 1 .. 2 |-> 0],
      rpimpv       |-> [i \in 1 .. 8 |-> 0],
      luldmpv      |-> [i \in 1 .. 8 |-> 0] ]

(* Minimum Price Variant Class Reference Data Message at zero, then each field in turn at the values it is checked at *)
CheckedMinimumPriceVariantClassReferenceDataMessage ==
    { ZeroMinimumPriceVariantClassReferenceDataMessage }
        \cup { [ZeroMinimumPriceVariantClassReferenceDataMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroMinimumPriceVariantClassReferenceDataMessage EXCEPT !.mpvClassName = one] : one \in Sample(20) }
        \cup { [ZeroMinimumPriceVariantClassReferenceDataMessage EXCEPT !.mpvClassId = one] : one \in Sample(2) }
        \cup { [ZeroMinimumPriceVariantClassReferenceDataMessage EXCEPT !.rpimpv = one] : one \in Sample(8) }
        \cup { [ZeroMinimumPriceVariantClassReferenceDataMessage EXCEPT !.luldmpv = one] : one \in Sample(8) }

(***************************************************************************)
(* Mpv Level Definition: 50 bytes                                          *)
(***************************************************************************)

MpvLevelDefinition ==
    [ mpvLevelName         : Sample(24),
      orderEntryLimitPrice : Sample(8),
      quotingMpv           : Sample(8),
      tradingMpv           : Sample(8),
      mpvClassId           : Sample(2) ]

EncodeMpvLevelDefinition(message) ==
    message.mpvLevelName
        \o message.orderEntryLimitPrice
        \o message.quotingMpv
        \o message.tradingMpv
        \o message.mpvClassId

DecodeMpvLevelDefinition(bytes) ==
    LET mpvLevelName == ReadBytes(bytes, 24) IN IF ~mpvLevelName.ok THEN Fail ELSE
    LET orderEntryLimitPrice == ReadBytes(mpvLevelName.rest, 8) IN IF ~orderEntryLimitPrice.ok THEN Fail ELSE
    LET quotingMpv == ReadBytes(orderEntryLimitPrice.rest, 8) IN IF ~quotingMpv.ok THEN Fail ELSE
    LET tradingMpv == ReadBytes(quotingMpv.rest, 8) IN IF ~tradingMpv.ok THEN Fail ELSE
    LET mpvClassId == ReadBytes(tradingMpv.rest, 2) IN IF ~mpvClassId.ok THEN Fail ELSE
    Ok([ mpvLevelName         |-> mpvLevelName.value,
         orderEntryLimitPrice |-> orderEntryLimitPrice.value,
         quotingMpv           |-> quotingMpv.value,
         tradingMpv           |-> tradingMpv.value,
         mpvClassId           |-> mpvClassId.value ], mpvClassId.rest)

ZeroMpvLevelDefinition ==
    [ mpvLevelName         |-> [i \in 1 .. 24 |-> 0],
      orderEntryLimitPrice |-> [i \in 1 .. 8 |-> 0],
      quotingMpv           |-> [i \in 1 .. 8 |-> 0],
      tradingMpv           |-> [i \in 1 .. 8 |-> 0],
      mpvClassId           |-> [i \in 1 .. 2 |-> 0] ]

(* Mpv Level Definition at zero, then each field in turn at the values it is checked at *)
CheckedMpvLevelDefinition ==
    { ZeroMpvLevelDefinition }
        \cup { [ZeroMpvLevelDefinition EXCEPT !.mpvLevelName = one] : one \in Sample(24) }
        \cup { [ZeroMpvLevelDefinition EXCEPT !.orderEntryLimitPrice = one] : one \in Sample(8) }
        \cup { [ZeroMpvLevelDefinition EXCEPT !.quotingMpv = one] : one \in Sample(8) }
        \cup { [ZeroMpvLevelDefinition EXCEPT !.tradingMpv = one] : one \in Sample(8) }
        \cup { [ZeroMpvLevelDefinition EXCEPT !.mpvClassId = one] : one \in Sample(2) }

(* A run of Mpv Level Definition, written one after another *)
RECURSIVE EncodeMpvLevelDefinitionList(_)
EncodeMpvLevelDefinitionList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMpvLevelDefinition(Head(messages)) \o EncodeMpvLevelDefinitionList(Tail(messages))

(* As many Mpv Level Definition as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadMpvLevelDefinitionAll(_)
ReadMpvLevelDefinitionAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeMpvLevelDefinition(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMpvLevelDefinitionAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Mpv Level Definition of each kind, for the lists that carry them *)
OneMpvLevelDefinition == { ZeroMpvLevelDefinition }

(***************************************************************************)
(* Minimum Price Variant Level Reference Data Message                      *)
(***************************************************************************)

MinimumPriceVariantLevelReferenceDataMessage ==
    [ transactTime       : Sample(8),
      mpvLevelDefinition : SampleLists(OneMpvLevelDefinition) ]

EncodeMinimumPriceVariantLevelReferenceDataMessage(message) ==
    message.transactTime
        \o EncodeMpvLevelDefinitionList(message.mpvLevelDefinition)

DecodeMinimumPriceVariantLevelReferenceDataMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET mpvLevelDefinition == ReadMpvLevelDefinitionAll(transactTime.rest) IN IF ~mpvLevelDefinition.ok THEN Fail ELSE
    Ok([ transactTime       |-> transactTime.value,
         mpvLevelDefinition |-> mpvLevelDefinition.value ], mpvLevelDefinition.rest)

ZeroMinimumPriceVariantLevelReferenceDataMessage ==
    [ transactTime       |-> [i \in 1 .. 8 |-> 0],
      mpvLevelDefinition |-> << >> ]

(* Minimum Price Variant Level Reference Data Message at zero, then each field in turn at the values it is checked at *)
CheckedMinimumPriceVariantLevelReferenceDataMessage ==
    { ZeroMinimumPriceVariantLevelReferenceDataMessage }
        \cup { [ZeroMinimumPriceVariantLevelReferenceDataMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroMinimumPriceVariantLevelReferenceDataMessage EXCEPT !.mpvLevelDefinition = one] : one \in SampleLists(OneMpvLevelDefinition) }

(***************************************************************************)
(* Mpid Configuration Message: 79 bytes                                    *)
(***************************************************************************)

MpidConfigurationMessage ==
    [ transactTime : Sample(8),
      mpidStatus   : Sample(1),
      mpid         : Sample(4),
      username     : Sample(16),
      reserved50   : Sample(50) ]

EncodeMpidConfigurationMessage(message) ==
    message.transactTime
        \o message.mpidStatus
        \o message.mpid
        \o message.username
        \o message.reserved50

DecodeMpidConfigurationMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET mpidStatus == ReadBytes(transactTime.rest, 1) IN IF ~mpidStatus.ok THEN Fail ELSE
    LET mpid == ReadBytes(mpidStatus.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET username == ReadBytes(mpid.rest, 16) IN IF ~username.ok THEN Fail ELSE
    LET reserved50 == ReadBytes(username.rest, 50) IN IF ~reserved50.ok THEN Fail ELSE
    Ok([ transactTime |-> transactTime.value,
         mpidStatus   |-> mpidStatus.value,
         mpid         |-> mpid.value,
         username     |-> username.value,
         reserved50   |-> reserved50.value ], reserved50.rest)

ZeroMpidConfigurationMessage ==
    [ transactTime |-> [i \in 1 .. 8 |-> 0],
      mpidStatus   |-> [i \in 1 .. 1 |-> 0],
      mpid         |-> [i \in 1 .. 4 |-> 0],
      username     |-> [i \in 1 .. 16 |-> 0],
      reserved50   |-> [i \in 1 .. 50 |-> 0] ]

(* Mpid Configuration Message at zero, then each field in turn at the values it is checked at *)
CheckedMpidConfigurationMessage ==
    { ZeroMpidConfigurationMessage }
        \cup { [ZeroMpidConfigurationMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroMpidConfigurationMessage EXCEPT !.mpidStatus = one] : one \in Sample(1) }
        \cup { [ZeroMpidConfigurationMessage EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroMpidConfigurationMessage EXCEPT !.username = one] : one \in Sample(16) }
        \cup { [ZeroMpidConfigurationMessage EXCEPT !.reserved50 = one] : one \in Sample(50) }

(***************************************************************************)
(* Options Market Maker Symbol Appointment Reference Data Message: 102     *)
(* bytes                                                                   *)
(***************************************************************************)

OptionsMarketMakerSymbolAppointmentReferenceDataMessage ==
    [ transactTime      : Sample(8),
      symbolId          : Sample(4),
      nyseSymbol        : Sample(24),
      marketMaker       : Sample(10),
      mpid              : Sample(4),
      mmType            : Sample(1),
      appointmentStatus : Sample(1),
      reserved50        : Sample(50) ]

EncodeOptionsMarketMakerSymbolAppointmentReferenceDataMessage(message) ==
    message.transactTime
        \o message.symbolId
        \o message.nyseSymbol
        \o message.marketMaker
        \o message.mpid
        \o message.mmType
        \o message.appointmentStatus
        \o message.reserved50

DecodeOptionsMarketMakerSymbolAppointmentReferenceDataMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET symbolId == ReadBytes(transactTime.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET nyseSymbol == ReadBytes(symbolId.rest, 24) IN IF ~nyseSymbol.ok THEN Fail ELSE
    LET marketMaker == ReadBytes(nyseSymbol.rest, 10) IN IF ~marketMaker.ok THEN Fail ELSE
    LET mpid == ReadBytes(marketMaker.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET mmType == ReadBytes(mpid.rest, 1) IN IF ~mmType.ok THEN Fail ELSE
    LET appointmentStatus == ReadBytes(mmType.rest, 1) IN IF ~appointmentStatus.ok THEN Fail ELSE
    LET reserved50 == ReadBytes(appointmentStatus.rest, 50) IN IF ~reserved50.ok THEN Fail ELSE
    Ok([ transactTime      |-> transactTime.value,
         symbolId          |-> symbolId.value,
         nyseSymbol        |-> nyseSymbol.value,
         marketMaker       |-> marketMaker.value,
         mpid              |-> mpid.value,
         mmType            |-> mmType.value,
         appointmentStatus |-> appointmentStatus.value,
         reserved50        |-> reserved50.value ], reserved50.rest)

ZeroOptionsMarketMakerSymbolAppointmentReferenceDataMessage ==
    [ transactTime      |-> [i \in 1 .. 8 |-> 0],
      symbolId          |-> [i \in 1 .. 4 |-> 0],
      nyseSymbol        |-> [i \in 1 .. 24 |-> 0],
      marketMaker       |-> [i \in 1 .. 10 |-> 0],
      mpid              |-> [i \in 1 .. 4 |-> 0],
      mmType            |-> [i \in 1 .. 1 |-> 0],
      appointmentStatus |-> [i \in 1 .. 1 |-> 0],
      reserved50        |-> [i \in 1 .. 50 |-> 0] ]

(* Options Market Maker Symbol Appointment Reference Data Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionsMarketMakerSymbolAppointmentReferenceDataMessage ==
    { ZeroOptionsMarketMakerSymbolAppointmentReferenceDataMessage }
        \cup { [ZeroOptionsMarketMakerSymbolAppointmentReferenceDataMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroOptionsMarketMakerSymbolAppointmentReferenceDataMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroOptionsMarketMakerSymbolAppointmentReferenceDataMessage EXCEPT !.nyseSymbol = one] : one \in Sample(24) }
        \cup { [ZeroOptionsMarketMakerSymbolAppointmentReferenceDataMessage EXCEPT !.marketMaker = one] : one \in Sample(10) }
        \cup { [ZeroOptionsMarketMakerSymbolAppointmentReferenceDataMessage EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroOptionsMarketMakerSymbolAppointmentReferenceDataMessage EXCEPT !.mmType = one] : one \in Sample(1) }
        \cup { [ZeroOptionsMarketMakerSymbolAppointmentReferenceDataMessage EXCEPT !.appointmentStatus = one] : one \in Sample(1) }
        \cup { [ZeroOptionsMarketMakerSymbolAppointmentReferenceDataMessage EXCEPT !.reserved50 = one] : one \in Sample(50) }

(***************************************************************************)
(* Session Configuration Acknowledgement Message: 94 bytes                 *)
(***************************************************************************)

SessionConfigurationAcknowledgementMessage ==
    [ transactTime                       : Sample(8),
      userSessionType                    : Sample(1),
      userSessionStatus                  : Sample(1),
      username                           : Sample(16),
      mic                                : Sample(4),
      cancelOnDisconnect                 : Sample(1),
      throttlePreference                 : Sample(1),
      throttleWindow                     : Sample(2),
      throttleThreshold                  : Sample(2),
      symbolEligibility                  : Sample(1),
      maxOrderQuantity                   : Sample(4),
      selfTradePrevention                : Sample(1),
      orderPriorityUpdateAckSubscription : Sample(1),
      ackStatus                          : Sample(1),
      boldDesignation                    : Sample(1),
      reserved49                         : Sample(49) ]

EncodeSessionConfigurationAcknowledgementMessage(message) ==
    message.transactTime
        \o message.userSessionType
        \o message.userSessionStatus
        \o message.username
        \o message.mic
        \o message.cancelOnDisconnect
        \o message.throttlePreference
        \o message.throttleWindow
        \o message.throttleThreshold
        \o message.symbolEligibility
        \o message.maxOrderQuantity
        \o message.selfTradePrevention
        \o message.orderPriorityUpdateAckSubscription
        \o message.ackStatus
        \o message.boldDesignation
        \o message.reserved49

DecodeSessionConfigurationAcknowledgementMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET userSessionType == ReadBytes(transactTime.rest, 1) IN IF ~userSessionType.ok THEN Fail ELSE
    LET userSessionStatus == ReadBytes(userSessionType.rest, 1) IN IF ~userSessionStatus.ok THEN Fail ELSE
    LET username == ReadBytes(userSessionStatus.rest, 16) IN IF ~username.ok THEN Fail ELSE
    LET mic == ReadBytes(username.rest, 4) IN IF ~mic.ok THEN Fail ELSE
    LET cancelOnDisconnect == ReadBytes(mic.rest, 1) IN IF ~cancelOnDisconnect.ok THEN Fail ELSE
    LET throttlePreference == ReadBytes(cancelOnDisconnect.rest, 1) IN IF ~throttlePreference.ok THEN Fail ELSE
    LET throttleWindow == ReadBytes(throttlePreference.rest, 2) IN IF ~throttleWindow.ok THEN Fail ELSE
    LET throttleThreshold == ReadBytes(throttleWindow.rest, 2) IN IF ~throttleThreshold.ok THEN Fail ELSE
    LET symbolEligibility == ReadBytes(throttleThreshold.rest, 1) IN IF ~symbolEligibility.ok THEN Fail ELSE
    LET maxOrderQuantity == ReadBytes(symbolEligibility.rest, 4) IN IF ~maxOrderQuantity.ok THEN Fail ELSE
    LET selfTradePrevention == ReadBytes(maxOrderQuantity.rest, 1) IN IF ~selfTradePrevention.ok THEN Fail ELSE
    LET orderPriorityUpdateAckSubscription == ReadBytes(selfTradePrevention.rest, 1) IN IF ~orderPriorityUpdateAckSubscription.ok THEN Fail ELSE
    LET ackStatus == ReadBytes(orderPriorityUpdateAckSubscription.rest, 1) IN IF ~ackStatus.ok THEN Fail ELSE
    LET boldDesignation == ReadBytes(ackStatus.rest, 1) IN IF ~boldDesignation.ok THEN Fail ELSE
    LET reserved49 == ReadBytes(boldDesignation.rest, 49) IN IF ~reserved49.ok THEN Fail ELSE
    Ok([ transactTime                       |-> transactTime.value,
         userSessionType                    |-> userSessionType.value,
         userSessionStatus                  |-> userSessionStatus.value,
         username                           |-> username.value,
         mic                                |-> mic.value,
         cancelOnDisconnect                 |-> cancelOnDisconnect.value,
         throttlePreference                 |-> throttlePreference.value,
         throttleWindow                     |-> throttleWindow.value,
         throttleThreshold                  |-> throttleThreshold.value,
         symbolEligibility                  |-> symbolEligibility.value,
         maxOrderQuantity                   |-> maxOrderQuantity.value,
         selfTradePrevention                |-> selfTradePrevention.value,
         orderPriorityUpdateAckSubscription |-> orderPriorityUpdateAckSubscription.value,
         ackStatus                          |-> ackStatus.value,
         boldDesignation                    |-> boldDesignation.value,
         reserved49                         |-> reserved49.value ], reserved49.rest)

ZeroSessionConfigurationAcknowledgementMessage ==
    [ transactTime                       |-> [i \in 1 .. 8 |-> 0],
      userSessionType                    |-> [i \in 1 .. 1 |-> 0],
      userSessionStatus                  |-> [i \in 1 .. 1 |-> 0],
      username                           |-> [i \in 1 .. 16 |-> 0],
      mic                                |-> [i \in 1 .. 4 |-> 0],
      cancelOnDisconnect                 |-> [i \in 1 .. 1 |-> 0],
      throttlePreference                 |-> [i \in 1 .. 1 |-> 0],
      throttleWindow                     |-> [i \in 1 .. 2 |-> 0],
      throttleThreshold                  |-> [i \in 1 .. 2 |-> 0],
      symbolEligibility                  |-> [i \in 1 .. 1 |-> 0],
      maxOrderQuantity                   |-> [i \in 1 .. 4 |-> 0],
      selfTradePrevention                |-> [i \in 1 .. 1 |-> 0],
      orderPriorityUpdateAckSubscription |-> [i \in 1 .. 1 |-> 0],
      ackStatus                          |-> [i \in 1 .. 1 |-> 0],
      boldDesignation                    |-> [i \in 1 .. 1 |-> 0],
      reserved49                         |-> [i \in 1 .. 49 |-> 0] ]

(* Session Configuration Acknowledgement Message at zero, then each field in turn at the values it is checked at *)
CheckedSessionConfigurationAcknowledgementMessage ==
    { ZeroSessionConfigurationAcknowledgementMessage }
        \cup { [ZeroSessionConfigurationAcknowledgementMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroSessionConfigurationAcknowledgementMessage EXCEPT !.userSessionType = one] : one \in Sample(1) }
        \cup { [ZeroSessionConfigurationAcknowledgementMessage EXCEPT !.userSessionStatus = one] : one \in Sample(1) }
        \cup { [ZeroSessionConfigurationAcknowledgementMessage EXCEPT !.username = one] : one \in Sample(16) }
        \cup { [ZeroSessionConfigurationAcknowledgementMessage EXCEPT !.mic = one] : one \in Sample(4) }
        \cup { [ZeroSessionConfigurationAcknowledgementMessage EXCEPT !.cancelOnDisconnect = one] : one \in Sample(1) }
        \cup { [ZeroSessionConfigurationAcknowledgementMessage EXCEPT !.throttlePreference = one] : one \in Sample(1) }
        \cup { [ZeroSessionConfigurationAcknowledgementMessage EXCEPT !.throttleWindow = one] : one \in Sample(2) }
        \cup { [ZeroSessionConfigurationAcknowledgementMessage EXCEPT !.throttleThreshold = one] : one \in Sample(2) }
        \cup { [ZeroSessionConfigurationAcknowledgementMessage EXCEPT !.symbolEligibility = one] : one \in Sample(1) }
        \cup { [ZeroSessionConfigurationAcknowledgementMessage EXCEPT !.maxOrderQuantity = one] : one \in Sample(4) }
        \cup { [ZeroSessionConfigurationAcknowledgementMessage EXCEPT !.selfTradePrevention = one] : one \in Sample(1) }
        \cup { [ZeroSessionConfigurationAcknowledgementMessage EXCEPT !.orderPriorityUpdateAckSubscription = one] : one \in Sample(1) }
        \cup { [ZeroSessionConfigurationAcknowledgementMessage EXCEPT !.ackStatus = one] : one \in Sample(1) }
        \cup { [ZeroSessionConfigurationAcknowledgementMessage EXCEPT !.boldDesignation = one] : one \in Sample(1) }
        \cup { [ZeroSessionConfigurationAcknowledgementMessage EXCEPT !.reserved49 = one] : one \in Sample(49) }

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

OptionalOrderAddOnCode == 184  \* 0xb8
SeqMsgLengthNoneCode == 137  \* 

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
(* Order And Cancel Replace Acknowledgement Message                        *)
(***************************************************************************)

OrderAndCancelReplaceAcknowledgementMessage ==
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
      transactTime              : Sample(8),
      orderId                   : Sample(8),
      leavesQty                 : Sample(4),
      workingPrice              : Sample(8),
      workingAwayFromDisplay    : Sample(1),
      preLiquidityIndicator     : Sample(4),
      reasonCode                : Sample(2),
      ackType                   : Sample(1),
      bitfieldFlowIndicator     : Sample(1),
      legOpenClose              : Sample(8),
      auctionId                 : Sample(8),
      seqMsgLengthChoice        : SeqMsgLengthChoice ]

EncodeOrderAndCancelReplaceAcknowledgementMessage(message) ==
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
        \o message.transactTime
        \o message.orderId
        \o message.leavesQty
        \o message.workingPrice
        \o message.workingAwayFromDisplay
        \o message.preLiquidityIndicator
        \o message.reasonCode
        \o message.ackType
        \o message.bitfieldFlowIndicator
        \o message.legOpenClose
        \o message.auctionId
        \o EncodeSeqMsgLengthChoice(message.seqMsgLengthChoice)

DecodeOrderAndCancelReplaceAcknowledgementMessage(bytes) ==
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
    LET transactTime == ReadBytes(userData.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET orderId == ReadBytes(transactTime.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(orderId.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET workingPrice == ReadBytes(leavesQty.rest, 8) IN IF ~workingPrice.ok THEN Fail ELSE
    LET workingAwayFromDisplay == ReadBytes(workingPrice.rest, 1) IN IF ~workingAwayFromDisplay.ok THEN Fail ELSE
    LET preLiquidityIndicator == ReadBytes(workingAwayFromDisplay.rest, 4) IN IF ~preLiquidityIndicator.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(preLiquidityIndicator.rest, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET ackType == ReadBytes(reasonCode.rest, 1) IN IF ~ackType.ok THEN Fail ELSE
    LET bitfieldFlowIndicator == ReadBytes(ackType.rest, 1) IN IF ~bitfieldFlowIndicator.ok THEN Fail ELSE
    LET legOpenClose == ReadBytes(bitfieldFlowIndicator.rest, 8) IN IF ~legOpenClose.ok THEN Fail ELSE
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
         transactTime              |-> transactTime.value,
         orderId                   |-> orderId.value,
         leavesQty                 |-> leavesQty.value,
         workingPrice              |-> workingPrice.value,
         workingAwayFromDisplay    |-> workingAwayFromDisplay.value,
         preLiquidityIndicator     |-> preLiquidityIndicator.value,
         reasonCode                |-> reasonCode.value,
         ackType                   |-> ackType.value,
         bitfieldFlowIndicator     |-> bitfieldFlowIndicator.value,
         legOpenClose              |-> legOpenClose.value,
         auctionId                 |-> auctionId.value,
         seqMsgLengthChoice        |-> seqMsgLengthChoice.value ], seqMsgLengthChoice.rest)

ZeroOrderAndCancelReplaceAcknowledgementMessage ==
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
      transactTime              |-> [i \in 1 .. 8 |-> 0],
      orderId                   |-> [i \in 1 .. 8 |-> 0],
      leavesQty                 |-> [i \in 1 .. 4 |-> 0],
      workingPrice              |-> [i \in 1 .. 8 |-> 0],
      workingAwayFromDisplay    |-> [i \in 1 .. 1 |-> 0],
      preLiquidityIndicator     |-> [i \in 1 .. 4 |-> 0],
      reasonCode                |-> [i \in 1 .. 2 |-> 0],
      ackType                   |-> [i \in 1 .. 1 |-> 0],
      bitfieldFlowIndicator     |-> [i \in 1 .. 1 |-> 0],
      legOpenClose              |-> [i \in 1 .. 8 |-> 0],
      auctionId                 |-> [i \in 1 .. 8 |-> 0],
      seqMsgLengthChoice        |-> ZeroSeqMsgLengthChoice ]

(* Order And Cancel Replace Acknowledgement Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderAndCancelReplaceAcknowledgementMessage ==
    { ZeroOrderAndCancelReplaceAcknowledgementMessage }
        \cup { [ZeroOrderAndCancelReplaceAcknowledgementMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroOrderAndCancelReplaceAcknowledgementMessage EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroOrderAndCancelReplaceAcknowledgementMessage EXCEPT !.marketMaker = one] : one \in Sample(10) }
        \cup { [ZeroOrderAndCancelReplaceAcknowledgementMessage EXCEPT !.mpSubId = one] : one \in Sample(4) }
        \cup { [ZeroOrderAndCancelReplaceAcknowledgementMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderAndCancelReplaceAcknowledgementMessage EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderAndCancelReplaceAcknowledgementMessage EXCEPT !.bitfieldOrderInstructions = one] : one \in Sample(16) }
        \cup { [ZeroOrderAndCancelReplaceAcknowledgementMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderAndCancelReplaceAcknowledgementMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderAndCancelReplaceAcknowledgementMessage EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderAndCancelReplaceAcknowledgementMessage EXCEPT !.userData = one] : one \in Sample(10) }
        \cup { [ZeroOrderAndCancelReplaceAcknowledgementMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderAndCancelReplaceAcknowledgementMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderAndCancelReplaceAcknowledgementMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderAndCancelReplaceAcknowledgementMessage EXCEPT !.workingPrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderAndCancelReplaceAcknowledgementMessage EXCEPT !.workingAwayFromDisplay = one] : one \in Sample(1) }
        \cup { [ZeroOrderAndCancelReplaceAcknowledgementMessage EXCEPT !.preLiquidityIndicator = one] : one \in Sample(4) }
        \cup { [ZeroOrderAndCancelReplaceAcknowledgementMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroOrderAndCancelReplaceAcknowledgementMessage EXCEPT !.ackType = one] : one \in Sample(1) }
        \cup { [ZeroOrderAndCancelReplaceAcknowledgementMessage EXCEPT !.bitfieldFlowIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderAndCancelReplaceAcknowledgementMessage EXCEPT !.legOpenClose = one] : one \in Sample(8) }
        \cup { [ZeroOrderAndCancelReplaceAcknowledgementMessage EXCEPT !.auctionId = one] : one \in Sample(8) }
        \cup { [ZeroOrderAndCancelReplaceAcknowledgementMessage EXCEPT !.seqMsgLengthChoice = one] : one \in CheckedSeqMsgLengthChoice }

(***************************************************************************)
(* Quote Ack Group: 21 bytes                                               *)
(***************************************************************************)

QuoteAckGroup ==
    [ seriesIndex            : Sample(4),
      side                   : Sample(1),
      ackType                : Sample(1),
      price                  : Sample(8),
      quantity               : Sample(4),
      reasonCode             : Sample(2),
      workingAwayFromDisplay : Sample(1) ]

EncodeQuoteAckGroup(message) ==
    message.seriesIndex
        \o message.side
        \o message.ackType
        \o message.price
        \o message.quantity
        \o message.reasonCode
        \o message.workingAwayFromDisplay

DecodeQuoteAckGroup(bytes) ==
    LET seriesIndex == ReadBytes(bytes, 4) IN IF ~seriesIndex.ok THEN Fail ELSE
    LET side == ReadBytes(seriesIndex.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ackType == ReadBytes(side.rest, 1) IN IF ~ackType.ok THEN Fail ELSE
    LET price == ReadBytes(ackType.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(quantity.rest, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET workingAwayFromDisplay == ReadBytes(reasonCode.rest, 1) IN IF ~workingAwayFromDisplay.ok THEN Fail ELSE
    Ok([ seriesIndex            |-> seriesIndex.value,
         side                   |-> side.value,
         ackType                |-> ackType.value,
         price                  |-> price.value,
         quantity               |-> quantity.value,
         reasonCode             |-> reasonCode.value,
         workingAwayFromDisplay |-> workingAwayFromDisplay.value ], workingAwayFromDisplay.rest)

ZeroQuoteAckGroup ==
    [ seriesIndex            |-> [i \in 1 .. 4 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      ackType                |-> [i \in 1 .. 1 |-> 0],
      price                  |-> [i \in 1 .. 8 |-> 0],
      quantity               |-> [i \in 1 .. 4 |-> 0],
      reasonCode             |-> [i \in 1 .. 2 |-> 0],
      workingAwayFromDisplay |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Ack Group at zero, then each field in turn at the values it is checked at *)
CheckedQuoteAckGroup ==
    { ZeroQuoteAckGroup }
        \cup { [ZeroQuoteAckGroup EXCEPT !.seriesIndex = one] : one \in Sample(4) }
        \cup { [ZeroQuoteAckGroup EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroQuoteAckGroup EXCEPT !.ackType = one] : one \in Sample(1) }
        \cup { [ZeroQuoteAckGroup EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroQuoteAckGroup EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroQuoteAckGroup EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroQuoteAckGroup EXCEPT !.workingAwayFromDisplay = one] : one \in Sample(1) }

(* A run of Quote Ack Group, written one after another *)
RECURSIVE EncodeQuoteAckGroupList(_)
EncodeQuoteAckGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeQuoteAckGroup(Head(messages)) \o EncodeQuoteAckGroupList(Tail(messages))

(* As many Quote Ack Group as the field that counts them says *)
RECURSIVE ReadQuoteAckGroupList(_, _)
ReadQuoteAckGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeQuoteAckGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadQuoteAckGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Quote Ack Group of each kind, for the lists that carry them *)
OneQuoteAckGroup == { ZeroQuoteAckGroup }

(***************************************************************************)
(* Bulk Quote Acknowledgment Message                                       *)
(***************************************************************************)

BulkQuoteAcknowledgmentMessage ==
    [ transactTime          : Sample(8),
      mpid                  : Sample(4),
      marketMaker           : Sample(10),
      subId                 : Sample(4),
      clOrdId               : Sample(8),
      bitfieldFlowIndicator : Sample(1),
      selfTradeType         : Sample(1),
      groupId               : Sample(4),
      quoteAckGroup         : SampleLists(OneQuoteAckGroup) ]

EncodeBulkQuoteAcknowledgmentMessage(message) ==
    message.transactTime
        \o message.mpid
        \o message.marketMaker
        \o message.subId
        \o message.clOrdId
        \o message.bitfieldFlowIndicator
        \o message.selfTradeType
        \o message.groupId
        \o EncodeUIntBE(Len(message.quoteAckGroup), 1)
        \o EncodeQuoteAckGroupList(message.quoteAckGroup)

DecodeBulkQuoteAcknowledgmentMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET mpid == ReadBytes(transactTime.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET marketMaker == ReadBytes(mpid.rest, 10) IN IF ~marketMaker.ok THEN Fail ELSE
    LET subId == ReadBytes(marketMaker.rest, 4) IN IF ~subId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(subId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET bitfieldFlowIndicator == ReadBytes(clOrdId.rest, 1) IN IF ~bitfieldFlowIndicator.ok THEN Fail ELSE
    LET selfTradeType == ReadBytes(bitfieldFlowIndicator.rest, 1) IN IF ~selfTradeType.ok THEN Fail ELSE
    LET groupId == ReadBytes(selfTradeType.rest, 4) IN IF ~groupId.ok THEN Fail ELSE
    LET repeatingGroups == ReadUIntBE(groupId.rest, 1) IN IF ~repeatingGroups.ok THEN Fail ELSE
    LET quoteAckGroup == ReadQuoteAckGroupList(repeatingGroups.rest, repeatingGroups.value) IN IF ~quoteAckGroup.ok THEN Fail ELSE
    Ok([ transactTime          |-> transactTime.value,
         mpid                  |-> mpid.value,
         marketMaker           |-> marketMaker.value,
         subId                 |-> subId.value,
         clOrdId               |-> clOrdId.value,
         bitfieldFlowIndicator |-> bitfieldFlowIndicator.value,
         selfTradeType         |-> selfTradeType.value,
         groupId               |-> groupId.value,
         quoteAckGroup         |-> quoteAckGroup.value ], quoteAckGroup.rest)

ZeroBulkQuoteAcknowledgmentMessage ==
    [ transactTime          |-> [i \in 1 .. 8 |-> 0],
      mpid                  |-> [i \in 1 .. 4 |-> 0],
      marketMaker           |-> [i \in 1 .. 10 |-> 0],
      subId                 |-> [i \in 1 .. 4 |-> 0],
      clOrdId               |-> [i \in 1 .. 8 |-> 0],
      bitfieldFlowIndicator |-> [i \in 1 .. 1 |-> 0],
      selfTradeType         |-> [i \in 1 .. 1 |-> 0],
      groupId               |-> [i \in 1 .. 4 |-> 0],
      quoteAckGroup         |-> << >> ]

(* Bulk Quote Acknowledgment Message at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuoteAcknowledgmentMessage ==
    { ZeroBulkQuoteAcknowledgmentMessage }
        \cup { [ZeroBulkQuoteAcknowledgmentMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuoteAcknowledgmentMessage EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroBulkQuoteAcknowledgmentMessage EXCEPT !.marketMaker = one] : one \in Sample(10) }
        \cup { [ZeroBulkQuoteAcknowledgmentMessage EXCEPT !.subId = one] : one \in Sample(4) }
        \cup { [ZeroBulkQuoteAcknowledgmentMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuoteAcknowledgmentMessage EXCEPT !.bitfieldFlowIndicator = one] : one \in Sample(1) }
        \cup { [ZeroBulkQuoteAcknowledgmentMessage EXCEPT !.selfTradeType = one] : one \in Sample(1) }
        \cup { [ZeroBulkQuoteAcknowledgmentMessage EXCEPT !.groupId = one] : one \in Sample(4) }
        \cup { [ZeroBulkQuoteAcknowledgmentMessage EXCEPT !.quoteAckGroup = one] : one \in SampleLists(OneQuoteAckGroup) }

(***************************************************************************)
(* Quote Ack With Id Group: 29 bytes                                       *)
(***************************************************************************)

QuoteAckWithIdGroup ==
    [ seriesIndex            : Sample(4),
      side                   : Sample(1),
      ackType                : Sample(1),
      price                  : Sample(8),
      quantity               : Sample(4),
      reasonCode             : Sample(2),
      workingAwayFromDisplay : Sample(1),
      orderId                : Sample(8) ]

EncodeQuoteAckWithIdGroup(message) ==
    message.seriesIndex
        \o message.side
        \o message.ackType
        \o message.price
        \o message.quantity
        \o message.reasonCode
        \o message.workingAwayFromDisplay
        \o message.orderId

DecodeQuoteAckWithIdGroup(bytes) ==
    LET seriesIndex == ReadBytes(bytes, 4) IN IF ~seriesIndex.ok THEN Fail ELSE
    LET side == ReadBytes(seriesIndex.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ackType == ReadBytes(side.rest, 1) IN IF ~ackType.ok THEN Fail ELSE
    LET price == ReadBytes(ackType.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(quantity.rest, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET workingAwayFromDisplay == ReadBytes(reasonCode.rest, 1) IN IF ~workingAwayFromDisplay.ok THEN Fail ELSE
    LET orderId == ReadBytes(workingAwayFromDisplay.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    Ok([ seriesIndex            |-> seriesIndex.value,
         side                   |-> side.value,
         ackType                |-> ackType.value,
         price                  |-> price.value,
         quantity               |-> quantity.value,
         reasonCode             |-> reasonCode.value,
         workingAwayFromDisplay |-> workingAwayFromDisplay.value,
         orderId                |-> orderId.value ], orderId.rest)

ZeroQuoteAckWithIdGroup ==
    [ seriesIndex            |-> [i \in 1 .. 4 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      ackType                |-> [i \in 1 .. 1 |-> 0],
      price                  |-> [i \in 1 .. 8 |-> 0],
      quantity               |-> [i \in 1 .. 4 |-> 0],
      reasonCode             |-> [i \in 1 .. 2 |-> 0],
      workingAwayFromDisplay |-> [i \in 1 .. 1 |-> 0],
      orderId                |-> [i \in 1 .. 8 |-> 0] ]

(* Quote Ack With Id Group at zero, then each field in turn at the values it is checked at *)
CheckedQuoteAckWithIdGroup ==
    { ZeroQuoteAckWithIdGroup }
        \cup { [ZeroQuoteAckWithIdGroup EXCEPT !.seriesIndex = one] : one \in Sample(4) }
        \cup { [ZeroQuoteAckWithIdGroup EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroQuoteAckWithIdGroup EXCEPT !.ackType = one] : one \in Sample(1) }
        \cup { [ZeroQuoteAckWithIdGroup EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroQuoteAckWithIdGroup EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroQuoteAckWithIdGroup EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroQuoteAckWithIdGroup EXCEPT !.workingAwayFromDisplay = one] : one \in Sample(1) }
        \cup { [ZeroQuoteAckWithIdGroup EXCEPT !.orderId = one] : one \in Sample(8) }

(* A run of Quote Ack With Id Group, written one after another *)
RECURSIVE EncodeQuoteAckWithIdGroupList(_)
EncodeQuoteAckWithIdGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeQuoteAckWithIdGroup(Head(messages)) \o EncodeQuoteAckWithIdGroupList(Tail(messages))

(* As many Quote Ack With Id Group as the field that counts them says *)
RECURSIVE ReadQuoteAckWithIdGroupList(_, _)
ReadQuoteAckWithIdGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeQuoteAckWithIdGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadQuoteAckWithIdGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Quote Ack With Id Group of each kind, for the lists that carry them *)
OneQuoteAckWithIdGroup == { ZeroQuoteAckWithIdGroup }

(***************************************************************************)
(* Bulk Quote Acknowledgment With Details Message                          *)
(***************************************************************************)

BulkQuoteAcknowledgmentWithDetailsMessage ==
    [ transactTime          : Sample(8),
      mpid                  : Sample(4),
      marketMaker           : Sample(10),
      subId                 : Sample(4),
      clOrdId               : Sample(8),
      bitfieldFlowIndicator : Sample(1),
      selfTradeType         : Sample(1),
      groupId               : Sample(4),
      quoteAckWithIdGroup   : SampleLists(OneQuoteAckWithIdGroup) ]

EncodeBulkQuoteAcknowledgmentWithDetailsMessage(message) ==
    message.transactTime
        \o message.mpid
        \o message.marketMaker
        \o message.subId
        \o message.clOrdId
        \o message.bitfieldFlowIndicator
        \o message.selfTradeType
        \o message.groupId
        \o EncodeUIntBE(Len(message.quoteAckWithIdGroup), 1)
        \o EncodeQuoteAckWithIdGroupList(message.quoteAckWithIdGroup)

DecodeBulkQuoteAcknowledgmentWithDetailsMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET mpid == ReadBytes(transactTime.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET marketMaker == ReadBytes(mpid.rest, 10) IN IF ~marketMaker.ok THEN Fail ELSE
    LET subId == ReadBytes(marketMaker.rest, 4) IN IF ~subId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(subId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET bitfieldFlowIndicator == ReadBytes(clOrdId.rest, 1) IN IF ~bitfieldFlowIndicator.ok THEN Fail ELSE
    LET selfTradeType == ReadBytes(bitfieldFlowIndicator.rest, 1) IN IF ~selfTradeType.ok THEN Fail ELSE
    LET groupId == ReadBytes(selfTradeType.rest, 4) IN IF ~groupId.ok THEN Fail ELSE
    LET repeatingGroups == ReadUIntBE(groupId.rest, 1) IN IF ~repeatingGroups.ok THEN Fail ELSE
    LET quoteAckWithIdGroup == ReadQuoteAckWithIdGroupList(repeatingGroups.rest, repeatingGroups.value) IN IF ~quoteAckWithIdGroup.ok THEN Fail ELSE
    Ok([ transactTime          |-> transactTime.value,
         mpid                  |-> mpid.value,
         marketMaker           |-> marketMaker.value,
         subId                 |-> subId.value,
         clOrdId               |-> clOrdId.value,
         bitfieldFlowIndicator |-> bitfieldFlowIndicator.value,
         selfTradeType         |-> selfTradeType.value,
         groupId               |-> groupId.value,
         quoteAckWithIdGroup   |-> quoteAckWithIdGroup.value ], quoteAckWithIdGroup.rest)

ZeroBulkQuoteAcknowledgmentWithDetailsMessage ==
    [ transactTime          |-> [i \in 1 .. 8 |-> 0],
      mpid                  |-> [i \in 1 .. 4 |-> 0],
      marketMaker           |-> [i \in 1 .. 10 |-> 0],
      subId                 |-> [i \in 1 .. 4 |-> 0],
      clOrdId               |-> [i \in 1 .. 8 |-> 0],
      bitfieldFlowIndicator |-> [i \in 1 .. 1 |-> 0],
      selfTradeType         |-> [i \in 1 .. 1 |-> 0],
      groupId               |-> [i \in 1 .. 4 |-> 0],
      quoteAckWithIdGroup   |-> << >> ]

(* Bulk Quote Acknowledgment With Details Message at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuoteAcknowledgmentWithDetailsMessage ==
    { ZeroBulkQuoteAcknowledgmentWithDetailsMessage }
        \cup { [ZeroBulkQuoteAcknowledgmentWithDetailsMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuoteAcknowledgmentWithDetailsMessage EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroBulkQuoteAcknowledgmentWithDetailsMessage EXCEPT !.marketMaker = one] : one \in Sample(10) }
        \cup { [ZeroBulkQuoteAcknowledgmentWithDetailsMessage EXCEPT !.subId = one] : one \in Sample(4) }
        \cup { [ZeroBulkQuoteAcknowledgmentWithDetailsMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuoteAcknowledgmentWithDetailsMessage EXCEPT !.bitfieldFlowIndicator = one] : one \in Sample(1) }
        \cup { [ZeroBulkQuoteAcknowledgmentWithDetailsMessage EXCEPT !.selfTradeType = one] : one \in Sample(1) }
        \cup { [ZeroBulkQuoteAcknowledgmentWithDetailsMessage EXCEPT !.groupId = one] : one \in Sample(4) }
        \cup { [ZeroBulkQuoteAcknowledgmentWithDetailsMessage EXCEPT !.quoteAckWithIdGroup = one] : one \in SampleLists(OneQuoteAckWithIdGroup) }

(***************************************************************************)
(* Order Single Complex Modify Cancel Request Acknowledgment And Urout     *)
(* Message: 108 bytes                                                      *)
(***************************************************************************)

OrderSingleComplexModifyCancelRequestAcknowledgmentAndUroutMessage ==
    [ transactTime          : Sample(8),
      symbolId              : Sample(4),
      mpid                  : Sample(4),
      orderId               : Sample(8),
      refClOrdId            : Sample(8),
      origClOrdId           : Sample(8),
      price                 : Sample(8),
      orderQty              : Sample(4),
      leavesQty             : Sample(4),
      side                  : Sample(1),
      locateReqd            : Sample(1),
      reasonCode            : Sample(2),
      ackType               : Sample(1),
      bitfieldFlowIndicator : Sample(1),
      userData              : Sample(10),
      groupId               : Sample(4),
      marketMaker           : Sample(10),
      targetCancelUsername  : Sample(16),
      targetCancelMpid      : Sample(4),
      bulkAction            : Sample(1),
      cancelScope           : Sample(1) ]

EncodeOrderSingleComplexModifyCancelRequestAcknowledgmentAndUroutMessage(message) ==
    message.transactTime
        \o message.symbolId
        \o message.mpid
        \o message.orderId
        \o message.refClOrdId
        \o message.origClOrdId
        \o message.price
        \o message.orderQty
        \o message.leavesQty
        \o message.side
        \o message.locateReqd
        \o message.reasonCode
        \o message.ackType
        \o message.bitfieldFlowIndicator
        \o message.userData
        \o message.groupId
        \o message.marketMaker
        \o message.targetCancelUsername
        \o message.targetCancelMpid
        \o message.bulkAction
        \o message.cancelScope

DecodeOrderSingleComplexModifyCancelRequestAcknowledgmentAndUroutMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET symbolId == ReadBytes(transactTime.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET mpid == ReadBytes(symbolId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET orderId == ReadBytes(mpid.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET refClOrdId == ReadBytes(orderId.rest, 8) IN IF ~refClOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(refClOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET price == ReadBytes(origClOrdId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderQty == ReadBytes(price.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(orderQty.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET side == ReadBytes(leavesQty.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET locateReqd == ReadBytes(side.rest, 1) IN IF ~locateReqd.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(locateReqd.rest, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET ackType == ReadBytes(reasonCode.rest, 1) IN IF ~ackType.ok THEN Fail ELSE
    LET bitfieldFlowIndicator == ReadBytes(ackType.rest, 1) IN IF ~bitfieldFlowIndicator.ok THEN Fail ELSE
    LET userData == ReadBytes(bitfieldFlowIndicator.rest, 10) IN IF ~userData.ok THEN Fail ELSE
    LET groupId == ReadBytes(userData.rest, 4) IN IF ~groupId.ok THEN Fail ELSE
    LET marketMaker == ReadBytes(groupId.rest, 10) IN IF ~marketMaker.ok THEN Fail ELSE
    LET targetCancelUsername == ReadBytes(marketMaker.rest, 16) IN IF ~targetCancelUsername.ok THEN Fail ELSE
    LET targetCancelMpid == ReadBytes(targetCancelUsername.rest, 4) IN IF ~targetCancelMpid.ok THEN Fail ELSE
    LET bulkAction == ReadBytes(targetCancelMpid.rest, 1) IN IF ~bulkAction.ok THEN Fail ELSE
    LET cancelScope == ReadBytes(bulkAction.rest, 1) IN IF ~cancelScope.ok THEN Fail ELSE
    Ok([ transactTime          |-> transactTime.value,
         symbolId              |-> symbolId.value,
         mpid                  |-> mpid.value,
         orderId               |-> orderId.value,
         refClOrdId            |-> refClOrdId.value,
         origClOrdId           |-> origClOrdId.value,
         price                 |-> price.value,
         orderQty              |-> orderQty.value,
         leavesQty             |-> leavesQty.value,
         side                  |-> side.value,
         locateReqd            |-> locateReqd.value,
         reasonCode            |-> reasonCode.value,
         ackType               |-> ackType.value,
         bitfieldFlowIndicator |-> bitfieldFlowIndicator.value,
         userData              |-> userData.value,
         groupId               |-> groupId.value,
         marketMaker           |-> marketMaker.value,
         targetCancelUsername  |-> targetCancelUsername.value,
         targetCancelMpid      |-> targetCancelMpid.value,
         bulkAction            |-> bulkAction.value,
         cancelScope           |-> cancelScope.value ], cancelScope.rest)

ZeroOrderSingleComplexModifyCancelRequestAcknowledgmentAndUroutMessage ==
    [ transactTime          |-> [i \in 1 .. 8 |-> 0],
      symbolId              |-> [i \in 1 .. 4 |-> 0],
      mpid                  |-> [i \in 1 .. 4 |-> 0],
      orderId               |-> [i \in 1 .. 8 |-> 0],
      refClOrdId            |-> [i \in 1 .. 8 |-> 0],
      origClOrdId           |-> [i \in 1 .. 8 |-> 0],
      price                 |-> [i \in 1 .. 8 |-> 0],
      orderQty              |-> [i \in 1 .. 4 |-> 0],
      leavesQty             |-> [i \in 1 .. 4 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      locateReqd            |-> [i \in 1 .. 1 |-> 0],
      reasonCode            |-> [i \in 1 .. 2 |-> 0],
      ackType               |-> [i \in 1 .. 1 |-> 0],
      bitfieldFlowIndicator |-> [i \in 1 .. 1 |-> 0],
      userData              |-> [i \in 1 .. 10 |-> 0],
      groupId               |-> [i \in 1 .. 4 |-> 0],
      marketMaker           |-> [i \in 1 .. 10 |-> 0],
      targetCancelUsername  |-> [i \in 1 .. 16 |-> 0],
      targetCancelMpid      |-> [i \in 1 .. 4 |-> 0],
      bulkAction            |-> [i \in 1 .. 1 |-> 0],
      cancelScope           |-> [i \in 1 .. 1 |-> 0] ]

(* Order Single Complex Modify Cancel Request Acknowledgment And Urout Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderSingleComplexModifyCancelRequestAcknowledgmentAndUroutMessage ==
    { ZeroOrderSingleComplexModifyCancelRequestAcknowledgmentAndUroutMessage }
        \cup { [ZeroOrderSingleComplexModifyCancelRequestAcknowledgmentAndUroutMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderSingleComplexModifyCancelRequestAcknowledgmentAndUroutMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroOrderSingleComplexModifyCancelRequestAcknowledgmentAndUroutMessage EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroOrderSingleComplexModifyCancelRequestAcknowledgmentAndUroutMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderSingleComplexModifyCancelRequestAcknowledgmentAndUroutMessage EXCEPT !.refClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderSingleComplexModifyCancelRequestAcknowledgmentAndUroutMessage EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderSingleComplexModifyCancelRequestAcknowledgmentAndUroutMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderSingleComplexModifyCancelRequestAcknowledgmentAndUroutMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderSingleComplexModifyCancelRequestAcknowledgmentAndUroutMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderSingleComplexModifyCancelRequestAcknowledgmentAndUroutMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderSingleComplexModifyCancelRequestAcknowledgmentAndUroutMessage EXCEPT !.locateReqd = one] : one \in Sample(1) }
        \cup { [ZeroOrderSingleComplexModifyCancelRequestAcknowledgmentAndUroutMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroOrderSingleComplexModifyCancelRequestAcknowledgmentAndUroutMessage EXCEPT !.ackType = one] : one \in Sample(1) }
        \cup { [ZeroOrderSingleComplexModifyCancelRequestAcknowledgmentAndUroutMessage EXCEPT !.bitfieldFlowIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderSingleComplexModifyCancelRequestAcknowledgmentAndUroutMessage EXCEPT !.userData = one] : one \in Sample(10) }
        \cup { [ZeroOrderSingleComplexModifyCancelRequestAcknowledgmentAndUroutMessage EXCEPT !.groupId = one] : one \in Sample(4) }
        \cup { [ZeroOrderSingleComplexModifyCancelRequestAcknowledgmentAndUroutMessage EXCEPT !.marketMaker = one] : one \in Sample(10) }
        \cup { [ZeroOrderSingleComplexModifyCancelRequestAcknowledgmentAndUroutMessage EXCEPT !.targetCancelUsername = one] : one \in Sample(16) }
        \cup { [ZeroOrderSingleComplexModifyCancelRequestAcknowledgmentAndUroutMessage EXCEPT !.targetCancelMpid = one] : one \in Sample(4) }
        \cup { [ZeroOrderSingleComplexModifyCancelRequestAcknowledgmentAndUroutMessage EXCEPT !.bulkAction = one] : one \in Sample(1) }
        \cup { [ZeroOrderSingleComplexModifyCancelRequestAcknowledgmentAndUroutMessage EXCEPT !.cancelScope = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Priority Update Acknowledgment Message: 60 bytes                  *)
(***************************************************************************)

OrderPriorityUpdateAcknowledgmentMessage ==
    [ transactTime           : Sample(8),
      symbolId               : Sample(4),
      mpid                   : Sample(4),
      orderId                : Sample(8),
      clOrdId                : Sample(8),
      workingPrice           : Sample(8),
      orderQty               : Sample(4),
      workingAwayFromDisplay : Sample(1),
      preLiquidityIndicator  : Sample(4),
      ackType                : Sample(1),
      userData               : Sample(10) ]

EncodeOrderPriorityUpdateAcknowledgmentMessage(message) ==
    message.transactTime
        \o message.symbolId
        \o message.mpid
        \o message.orderId
        \o message.clOrdId
        \o message.workingPrice
        \o message.orderQty
        \o message.workingAwayFromDisplay
        \o message.preLiquidityIndicator
        \o message.ackType
        \o message.userData

DecodeOrderPriorityUpdateAcknowledgmentMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET symbolId == ReadBytes(transactTime.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET mpid == ReadBytes(symbolId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET orderId == ReadBytes(mpid.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET workingPrice == ReadBytes(clOrdId.rest, 8) IN IF ~workingPrice.ok THEN Fail ELSE
    LET orderQty == ReadBytes(workingPrice.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET workingAwayFromDisplay == ReadBytes(orderQty.rest, 1) IN IF ~workingAwayFromDisplay.ok THEN Fail ELSE
    LET preLiquidityIndicator == ReadBytes(workingAwayFromDisplay.rest, 4) IN IF ~preLiquidityIndicator.ok THEN Fail ELSE
    LET ackType == ReadBytes(preLiquidityIndicator.rest, 1) IN IF ~ackType.ok THEN Fail ELSE
    LET userData == ReadBytes(ackType.rest, 10) IN IF ~userData.ok THEN Fail ELSE
    Ok([ transactTime           |-> transactTime.value,
         symbolId               |-> symbolId.value,
         mpid                   |-> mpid.value,
         orderId                |-> orderId.value,
         clOrdId                |-> clOrdId.value,
         workingPrice           |-> workingPrice.value,
         orderQty               |-> orderQty.value,
         workingAwayFromDisplay |-> workingAwayFromDisplay.value,
         preLiquidityIndicator  |-> preLiquidityIndicator.value,
         ackType                |-> ackType.value,
         userData               |-> userData.value ], userData.rest)

ZeroOrderPriorityUpdateAcknowledgmentMessage ==
    [ transactTime           |-> [i \in 1 .. 8 |-> 0],
      symbolId               |-> [i \in 1 .. 4 |-> 0],
      mpid                   |-> [i \in 1 .. 4 |-> 0],
      orderId                |-> [i \in 1 .. 8 |-> 0],
      clOrdId                |-> [i \in 1 .. 8 |-> 0],
      workingPrice           |-> [i \in 1 .. 8 |-> 0],
      orderQty               |-> [i \in 1 .. 4 |-> 0],
      workingAwayFromDisplay |-> [i \in 1 .. 1 |-> 0],
      preLiquidityIndicator  |-> [i \in 1 .. 4 |-> 0],
      ackType                |-> [i \in 1 .. 1 |-> 0],
      userData               |-> [i \in 1 .. 10 |-> 0] ]

(* Order Priority Update Acknowledgment Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderPriorityUpdateAcknowledgmentMessage ==
    { ZeroOrderPriorityUpdateAcknowledgmentMessage }
        \cup { [ZeroOrderPriorityUpdateAcknowledgmentMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderPriorityUpdateAcknowledgmentMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroOrderPriorityUpdateAcknowledgmentMessage EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroOrderPriorityUpdateAcknowledgmentMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderPriorityUpdateAcknowledgmentMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderPriorityUpdateAcknowledgmentMessage EXCEPT !.workingPrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderPriorityUpdateAcknowledgmentMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderPriorityUpdateAcknowledgmentMessage EXCEPT !.workingAwayFromDisplay = one] : one \in Sample(1) }
        \cup { [ZeroOrderPriorityUpdateAcknowledgmentMessage EXCEPT !.preLiquidityIndicator = one] : one \in Sample(4) }
        \cup { [ZeroOrderPriorityUpdateAcknowledgmentMessage EXCEPT !.ackType = one] : one \in Sample(1) }
        \cup { [ZeroOrderPriorityUpdateAcknowledgmentMessage EXCEPT !.userData = one] : one \in Sample(10) }

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
(* Optional Order Add On: 47 bytes                                         *)
(***************************************************************************)

OptionalOrderAddOn2 ==
    [ subMsgHeader    : SubMsgHeader2,
      stopPx          : Sample(8),
      maxFloor        : Sample(4),
      deliverToCompId : Sample(5),
      clearingFirm    : Sample(5),
      optionalData    : Sample(16),
      clearingAccount : Sample(5) ]

EncodeOptionalOrderAddOn2(message) ==
    EncodeSubMsgHeader2(message.subMsgHeader)
        \o message.stopPx
        \o message.maxFloor
        \o message.deliverToCompId
        \o message.clearingFirm
        \o message.optionalData
        \o message.clearingAccount

DecodeOptionalOrderAddOn2(bytes) ==
    LET subMsgHeader == DecodeSubMsgHeader2(bytes) IN IF ~subMsgHeader.ok THEN Fail ELSE
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

ZeroOptionalOrderAddOn2 ==
    [ subMsgHeader    |-> ZeroSubMsgHeader2,
      stopPx          |-> [i \in 1 .. 8 |-> 0],
      maxFloor        |-> [i \in 1 .. 4 |-> 0],
      deliverToCompId |-> [i \in 1 .. 5 |-> 0],
      clearingFirm    |-> [i \in 1 .. 5 |-> 0],
      optionalData    |-> [i \in 1 .. 16 |-> 0],
      clearingAccount |-> [i \in 1 .. 5 |-> 0] ]

(* Optional Order Add On at zero, then each field in turn at the values it is checked at *)
CheckedOptionalOrderAddOn2 ==
    { ZeroOptionalOrderAddOn2 }
        \cup { [ZeroOptionalOrderAddOn2 EXCEPT !.subMsgHeader = one] : one \in CheckedSubMsgHeader2 }
        \cup { [ZeroOptionalOrderAddOn2 EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroOptionalOrderAddOn2 EXCEPT !.maxFloor = one] : one \in Sample(4) }
        \cup { [ZeroOptionalOrderAddOn2 EXCEPT !.deliverToCompId = one] : one \in Sample(5) }
        \cup { [ZeroOptionalOrderAddOn2 EXCEPT !.clearingFirm = one] : one \in Sample(5) }
        \cup { [ZeroOptionalOrderAddOn2 EXCEPT !.optionalData = one] : one \in Sample(16) }
        \cup { [ZeroOptionalOrderAddOn2 EXCEPT !.clearingAccount = one] : one \in Sample(5) }

(***************************************************************************)
(* What Seq Msg Length decides is present                                  *)
(***************************************************************************)

OptionalOrderAddOnCode2 == 183  \* 0xb7
SeqMsgLengthNoneCode2 == 136  \* 

SeqMsgLengthChoice2 ==
    [ tag : {OptionalOrderAddOnCode2}, body : OptionalOrderAddOn2 ]
        \cup [ tag : {SeqMsgLengthNoneCode2}, body : {[empty |-> 0]} ]

EncodeSeqMsgLengthChoice2(message) ==
    CASE message.tag = OptionalOrderAddOnCode2 -> EncodeOptionalOrderAddOn2(message.body)
      [] OTHER -> << >>

DecodeSeqMsgLengthChoice2(tag, bytes) ==
    LET read ==
            CASE tag = OptionalOrderAddOnCode2 -> DecodeOptionalOrderAddOn2(bytes)
              [] OTHER -> Ok([empty |-> 0], bytes)
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSeqMsgLengthChoice2 == [tag |-> OptionalOrderAddOnCode2, body |-> ZeroOptionalOrderAddOn2]

(* Each Seq Msg Length in turn, at the values the message it names is checked at *)
CheckedSeqMsgLengthChoice2 ==
    { [tag |-> OptionalOrderAddOnCode2, body |-> one] : one \in CheckedOptionalOrderAddOn2 }
        \cup { [tag |-> SeqMsgLengthNoneCode2, body |-> [empty |-> 0]] }

(***************************************************************************)
(* Execution Report Message                                                *)
(***************************************************************************)

ExecutionReportMessage ==
    [ transactTime             : Sample(8),
      symbolId                 : Sample(4),
      mpid                     : Sample(4),
      orderId                  : Sample(8),
      clOrdId                  : Sample(8),
      dealId                   : Sample(8),
      lastPx                   : Sample(8),
      leavesQty                : Sample(4),
      cumQty                   : Sample(4),
      lastQty                  : Sample(4),
      liquidityIndicator       : Sample(4),
      multilegReportingType    : Sample(1),
      reserved1                : Sample(1),
      reserved2                : Sample(2),
      locateReqd               : Sample(1),
      participantType          : Sample(1),
      reasonCode               : Sample(2),
      userData                 : Sample(10),
      side                     : Sample(1),
      marketMaker              : Sample(10),
      contraMarketMaker        : Sample(10),
      contraClearingFirm       : Sample(5),
      contraMpid               : Sample(4),
      contraOpenClose          : Sample(1),
      contraCustomerOrFirm     : Sample(1),
      contraClearingAccount    : Sample(5),
      contraCrossType          : Sample(2),
      contraCoveredOrUncovered : Sample(1),
      coveredOrUncovered       : Sample(1),
      crossId                  : Sample(8),
      openClose                : Sample(1),
      seqMsgLengthChoice       : SeqMsgLengthChoice2 ]

EncodeExecutionReportMessage(message) ==
    message.transactTime
        \o message.symbolId
        \o message.mpid
        \o message.orderId
        \o message.clOrdId
        \o message.dealId
        \o message.lastPx
        \o message.leavesQty
        \o message.cumQty
        \o message.lastQty
        \o message.liquidityIndicator
        \o message.multilegReportingType
        \o message.reserved1
        \o message.reserved2
        \o message.locateReqd
        \o message.participantType
        \o message.reasonCode
        \o message.userData
        \o message.side
        \o message.marketMaker
        \o message.contraMarketMaker
        \o message.contraClearingFirm
        \o message.contraMpid
        \o message.contraOpenClose
        \o message.contraCustomerOrFirm
        \o message.contraClearingAccount
        \o message.contraCrossType
        \o message.contraCoveredOrUncovered
        \o message.coveredOrUncovered
        \o message.crossId
        \o message.openClose
        \o EncodeSeqMsgLengthChoice2(message.seqMsgLengthChoice)

DecodeExecutionReportMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET symbolId == ReadBytes(transactTime.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET mpid == ReadBytes(symbolId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET orderId == ReadBytes(mpid.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET dealId == ReadBytes(clOrdId.rest, 8) IN IF ~dealId.ok THEN Fail ELSE
    LET lastPx == ReadBytes(dealId.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(lastPx.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET lastQty == ReadBytes(cumQty.rest, 4) IN IF ~lastQty.ok THEN Fail ELSE
    LET liquidityIndicator == ReadBytes(lastQty.rest, 4) IN IF ~liquidityIndicator.ok THEN Fail ELSE
    LET multilegReportingType == ReadBytes(liquidityIndicator.rest, 1) IN IF ~multilegReportingType.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(multilegReportingType.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(reserved1.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET locateReqd == ReadBytes(reserved2.rest, 1) IN IF ~locateReqd.ok THEN Fail ELSE
    LET participantType == ReadBytes(locateReqd.rest, 1) IN IF ~participantType.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(participantType.rest, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET userData == ReadBytes(reasonCode.rest, 10) IN IF ~userData.ok THEN Fail ELSE
    LET side == ReadBytes(userData.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET marketMaker == ReadBytes(side.rest, 10) IN IF ~marketMaker.ok THEN Fail ELSE
    LET contraMarketMaker == ReadBytes(marketMaker.rest, 10) IN IF ~contraMarketMaker.ok THEN Fail ELSE
    LET contraClearingFirm == ReadBytes(contraMarketMaker.rest, 5) IN IF ~contraClearingFirm.ok THEN Fail ELSE
    LET contraMpid == ReadBytes(contraClearingFirm.rest, 4) IN IF ~contraMpid.ok THEN Fail ELSE
    LET contraOpenClose == ReadBytes(contraMpid.rest, 1) IN IF ~contraOpenClose.ok THEN Fail ELSE
    LET contraCustomerOrFirm == ReadBytes(contraOpenClose.rest, 1) IN IF ~contraCustomerOrFirm.ok THEN Fail ELSE
    LET contraClearingAccount == ReadBytes(contraCustomerOrFirm.rest, 5) IN IF ~contraClearingAccount.ok THEN Fail ELSE
    LET contraCrossType == ReadBytes(contraClearingAccount.rest, 2) IN IF ~contraCrossType.ok THEN Fail ELSE
    LET contraCoveredOrUncovered == ReadBytes(contraCrossType.rest, 1) IN IF ~contraCoveredOrUncovered.ok THEN Fail ELSE
    LET coveredOrUncovered == ReadBytes(contraCoveredOrUncovered.rest, 1) IN IF ~coveredOrUncovered.ok THEN Fail ELSE
    LET crossId == ReadBytes(coveredOrUncovered.rest, 8) IN IF ~crossId.ok THEN Fail ELSE
    LET openClose == ReadBytes(crossId.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET seqMsgLengthChoice == DecodeSeqMsgLengthChoice2(Len(bytes) + 4, openClose.rest) IN IF ~seqMsgLengthChoice.ok THEN Fail ELSE
    Ok([ transactTime             |-> transactTime.value,
         symbolId                 |-> symbolId.value,
         mpid                     |-> mpid.value,
         orderId                  |-> orderId.value,
         clOrdId                  |-> clOrdId.value,
         dealId                   |-> dealId.value,
         lastPx                   |-> lastPx.value,
         leavesQty                |-> leavesQty.value,
         cumQty                   |-> cumQty.value,
         lastQty                  |-> lastQty.value,
         liquidityIndicator       |-> liquidityIndicator.value,
         multilegReportingType    |-> multilegReportingType.value,
         reserved1                |-> reserved1.value,
         reserved2                |-> reserved2.value,
         locateReqd               |-> locateReqd.value,
         participantType          |-> participantType.value,
         reasonCode               |-> reasonCode.value,
         userData                 |-> userData.value,
         side                     |-> side.value,
         marketMaker              |-> marketMaker.value,
         contraMarketMaker        |-> contraMarketMaker.value,
         contraClearingFirm       |-> contraClearingFirm.value,
         contraMpid               |-> contraMpid.value,
         contraOpenClose          |-> contraOpenClose.value,
         contraCustomerOrFirm     |-> contraCustomerOrFirm.value,
         contraClearingAccount    |-> contraClearingAccount.value,
         contraCrossType          |-> contraCrossType.value,
         contraCoveredOrUncovered |-> contraCoveredOrUncovered.value,
         coveredOrUncovered       |-> coveredOrUncovered.value,
         crossId                  |-> crossId.value,
         openClose                |-> openClose.value,
         seqMsgLengthChoice       |-> seqMsgLengthChoice.value ], seqMsgLengthChoice.rest)

ZeroExecutionReportMessage ==
    [ transactTime             |-> [i \in 1 .. 8 |-> 0],
      symbolId                 |-> [i \in 1 .. 4 |-> 0],
      mpid                     |-> [i \in 1 .. 4 |-> 0],
      orderId                  |-> [i \in 1 .. 8 |-> 0],
      clOrdId                  |-> [i \in 1 .. 8 |-> 0],
      dealId                   |-> [i \in 1 .. 8 |-> 0],
      lastPx                   |-> [i \in 1 .. 8 |-> 0],
      leavesQty                |-> [i \in 1 .. 4 |-> 0],
      cumQty                   |-> [i \in 1 .. 4 |-> 0],
      lastQty                  |-> [i \in 1 .. 4 |-> 0],
      liquidityIndicator       |-> [i \in 1 .. 4 |-> 0],
      multilegReportingType    |-> [i \in 1 .. 1 |-> 0],
      reserved1                |-> [i \in 1 .. 1 |-> 0],
      reserved2                |-> [i \in 1 .. 2 |-> 0],
      locateReqd               |-> [i \in 1 .. 1 |-> 0],
      participantType          |-> [i \in 1 .. 1 |-> 0],
      reasonCode               |-> [i \in 1 .. 2 |-> 0],
      userData                 |-> [i \in 1 .. 10 |-> 0],
      side                     |-> [i \in 1 .. 1 |-> 0],
      marketMaker              |-> [i \in 1 .. 10 |-> 0],
      contraMarketMaker        |-> [i \in 1 .. 10 |-> 0],
      contraClearingFirm       |-> [i \in 1 .. 5 |-> 0],
      contraMpid               |-> [i \in 1 .. 4 |-> 0],
      contraOpenClose          |-> [i \in 1 .. 1 |-> 0],
      contraCustomerOrFirm     |-> [i \in 1 .. 1 |-> 0],
      contraClearingAccount    |-> [i \in 1 .. 5 |-> 0],
      contraCrossType          |-> [i \in 1 .. 2 |-> 0],
      contraCoveredOrUncovered |-> [i \in 1 .. 1 |-> 0],
      coveredOrUncovered       |-> [i \in 1 .. 1 |-> 0],
      crossId                  |-> [i \in 1 .. 8 |-> 0],
      openClose                |-> [i \in 1 .. 1 |-> 0],
      seqMsgLengthChoice       |-> ZeroSeqMsgLengthChoice2 ]

(* Execution Report Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportMessage ==
    { ZeroExecutionReportMessage }
        \cup { [ZeroExecutionReportMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.dealId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.lastQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.liquidityIndicator = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.multilegReportingType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.locateReqd = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.participantType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.userData = one] : one \in Sample(10) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.marketMaker = one] : one \in Sample(10) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.contraMarketMaker = one] : one \in Sample(10) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.contraClearingFirm = one] : one \in Sample(5) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.contraMpid = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.contraOpenClose = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.contraCustomerOrFirm = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.contraClearingAccount = one] : one \in Sample(5) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.contraCrossType = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.contraCoveredOrUncovered = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.coveredOrUncovered = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.crossId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.seqMsgLengthChoice = one] : one \in CheckedSeqMsgLengthChoice2 }

(***************************************************************************)
(* Stream Id: 8 bytes                                                      *)
(***************************************************************************)

StreamId5 ==
    [ sess  : Sample(4),
      value : Sample(4) ]

EncodeStreamId5(message) ==
    message.sess
        \o message.value

DecodeStreamId5(bytes) ==
    LET sess == ReadBytes(bytes, 4) IN IF ~sess.ok THEN Fail ELSE
    LET value == ReadBytes(sess.rest, 4) IN IF ~value.ok THEN Fail ELSE
    Ok([ sess  |-> sess.value,
         value |-> value.value ], value.rest)

ZeroStreamId5 ==
    [ sess  |-> [i \in 1 .. 4 |-> 0],
      value |-> [i \in 1 .. 4 |-> 0] ]

(* Stream Id at zero, then each field in turn at the values it is checked at *)
CheckedStreamId5 ==
    { ZeroStreamId5 }
        \cup { [ZeroStreamId5 EXCEPT !.sess = one] : one \in Sample(4) }
        \cup { [ZeroStreamId5 EXCEPT !.value = one] : one \in Sample(4) }

(***************************************************************************)
(* Ref Seq Msg Id: 16 bytes                                                *)
(***************************************************************************)

RefSeqMsgId ==
    [ streamId : StreamId5,
      seq      : Sample(8) ]

EncodeRefSeqMsgId(message) ==
    EncodeStreamId5(message.streamId)
        \o message.seq

DecodeRefSeqMsgId(bytes) ==
    LET streamId == DecodeStreamId5(bytes) IN IF ~streamId.ok THEN Fail ELSE
    LET seq == ReadBytes(streamId.rest, 8) IN IF ~seq.ok THEN Fail ELSE
    Ok([ streamId |-> streamId.value,
         seq      |-> seq.value ], seq.rest)

ZeroRefSeqMsgId ==
    [ streamId |-> ZeroStreamId5,
      seq      |-> [i \in 1 .. 8 |-> 0] ]

(* Ref Seq Msg Id at zero, then each field in turn at the values it is checked at *)
CheckedRefSeqMsgId ==
    { ZeroRefSeqMsgId }
        \cup { [ZeroRefSeqMsgId EXCEPT !.streamId = one] : one \in CheckedStreamId5 }
        \cup { [ZeroRefSeqMsgId EXCEPT !.seq = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Bust Correct Message: 81 bytes                                    *)
(***************************************************************************)

TradeBustCorrectMessage ==
    [ transactTime         : Sample(8),
      symbolId             : Sample(4),
      mpid                 : Sample(4),
      orderId              : Sample(8),
      clOrdId              : Sample(8),
      refSeqMsgId          : RefSeqMsgId,
      dealId               : Sample(8),
      lastPx               : Sample(8),
      lastQty              : Sample(4),
      reasonCode           : Sample(2),
      userData             : Sample(10),
      bustCorrectIndicator : Sample(1) ]

EncodeTradeBustCorrectMessage(message) ==
    message.transactTime
        \o message.symbolId
        \o message.mpid
        \o message.orderId
        \o message.clOrdId
        \o EncodeRefSeqMsgId(message.refSeqMsgId)
        \o message.dealId
        \o message.lastPx
        \o message.lastQty
        \o message.reasonCode
        \o message.userData
        \o message.bustCorrectIndicator

DecodeTradeBustCorrectMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET symbolId == ReadBytes(transactTime.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET mpid == ReadBytes(symbolId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET orderId == ReadBytes(mpid.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET refSeqMsgId == DecodeRefSeqMsgId(clOrdId.rest) IN IF ~refSeqMsgId.ok THEN Fail ELSE
    LET dealId == ReadBytes(refSeqMsgId.rest, 8) IN IF ~dealId.ok THEN Fail ELSE
    LET lastPx == ReadBytes(dealId.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 4) IN IF ~lastQty.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(lastQty.rest, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET userData == ReadBytes(reasonCode.rest, 10) IN IF ~userData.ok THEN Fail ELSE
    LET bustCorrectIndicator == ReadBytes(userData.rest, 1) IN IF ~bustCorrectIndicator.ok THEN Fail ELSE
    Ok([ transactTime         |-> transactTime.value,
         symbolId             |-> symbolId.value,
         mpid                 |-> mpid.value,
         orderId              |-> orderId.value,
         clOrdId              |-> clOrdId.value,
         refSeqMsgId          |-> refSeqMsgId.value,
         dealId               |-> dealId.value,
         lastPx               |-> lastPx.value,
         lastQty              |-> lastQty.value,
         reasonCode           |-> reasonCode.value,
         userData             |-> userData.value,
         bustCorrectIndicator |-> bustCorrectIndicator.value ], bustCorrectIndicator.rest)

ZeroTradeBustCorrectMessage ==
    [ transactTime         |-> [i \in 1 .. 8 |-> 0],
      symbolId             |-> [i \in 1 .. 4 |-> 0],
      mpid                 |-> [i \in 1 .. 4 |-> 0],
      orderId              |-> [i \in 1 .. 8 |-> 0],
      clOrdId              |-> [i \in 1 .. 8 |-> 0],
      refSeqMsgId          |-> ZeroRefSeqMsgId,
      dealId               |-> [i \in 1 .. 8 |-> 0],
      lastPx               |-> [i \in 1 .. 8 |-> 0],
      lastQty              |-> [i \in 1 .. 4 |-> 0],
      reasonCode           |-> [i \in 1 .. 2 |-> 0],
      userData             |-> [i \in 1 .. 10 |-> 0],
      bustCorrectIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Bust Correct Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeBustCorrectMessage ==
    { ZeroTradeBustCorrectMessage }
        \cup { [ZeroTradeBustCorrectMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustCorrectMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroTradeBustCorrectMessage EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroTradeBustCorrectMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustCorrectMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustCorrectMessage EXCEPT !.refSeqMsgId = one] : one \in CheckedRefSeqMsgId }
        \cup { [ZeroTradeBustCorrectMessage EXCEPT !.dealId = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustCorrectMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustCorrectMessage EXCEPT !.lastQty = one] : one \in Sample(4) }
        \cup { [ZeroTradeBustCorrectMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroTradeBustCorrectMessage EXCEPT !.userData = one] : one \in Sample(10) }
        \cup { [ZeroTradeBustCorrectMessage EXCEPT !.bustCorrectIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Application Layer Reject Message: 41 bytes                              *)
(***************************************************************************)

ApplicationLayerRejectMessage ==
    [ transactTime : Sample(8),
      symbolId     : Sample(4),
      mpid         : Sample(4),
      clOrdId      : Sample(8),
      reasonCode   : Sample(2),
      rejectType   : Sample(1),
      userData     : Sample(10),
      reserved4    : Sample(4) ]

EncodeApplicationLayerRejectMessage(message) ==
    message.transactTime
        \o message.symbolId
        \o message.mpid
        \o message.clOrdId
        \o message.reasonCode
        \o message.rejectType
        \o message.userData
        \o message.reserved4

DecodeApplicationLayerRejectMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET symbolId == ReadBytes(transactTime.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET mpid == ReadBytes(symbolId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(mpid.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(clOrdId.rest, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET rejectType == ReadBytes(reasonCode.rest, 1) IN IF ~rejectType.ok THEN Fail ELSE
    LET userData == ReadBytes(rejectType.rest, 10) IN IF ~userData.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(userData.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    Ok([ transactTime |-> transactTime.value,
         symbolId     |-> symbolId.value,
         mpid         |-> mpid.value,
         clOrdId      |-> clOrdId.value,
         reasonCode   |-> reasonCode.value,
         rejectType   |-> rejectType.value,
         userData     |-> userData.value,
         reserved4    |-> reserved4.value ], reserved4.rest)

ZeroApplicationLayerRejectMessage ==
    [ transactTime |-> [i \in 1 .. 8 |-> 0],
      symbolId     |-> [i \in 1 .. 4 |-> 0],
      mpid         |-> [i \in 1 .. 4 |-> 0],
      clOrdId      |-> [i \in 1 .. 8 |-> 0],
      reasonCode   |-> [i \in 1 .. 2 |-> 0],
      rejectType   |-> [i \in 1 .. 1 |-> 0],
      userData     |-> [i \in 1 .. 10 |-> 0],
      reserved4    |-> [i \in 1 .. 4 |-> 0] ]

(* Application Layer Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedApplicationLayerRejectMessage ==
    { ZeroApplicationLayerRejectMessage }
        \cup { [ZeroApplicationLayerRejectMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroApplicationLayerRejectMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroApplicationLayerRejectMessage EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroApplicationLayerRejectMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroApplicationLayerRejectMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroApplicationLayerRejectMessage EXCEPT !.rejectType = one] : one \in Sample(1) }
        \cup { [ZeroApplicationLayerRejectMessage EXCEPT !.userData = one] : one \in Sample(10) }
        \cup { [ZeroApplicationLayerRejectMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Risk Control Acknowledgement Message: 310 bytes                         *)
(***************************************************************************)

RiskControlAcknowledgementMessage ==
    [ symbolId                     : Sample(4),
      mpid                         : Sample(4),
      marketMaker                  : Sample(10),
      mpSubId                      : Sample(4),
      reserved4                    : Sample(4),
      clearingNumber               : Sample(5),
      clOrdId                      : Sample(8),
      riskAckType                  : Sample(1),
      riskUserCrd                  : Sample(4),
      riskUserType                 : Sample(1),
      riskControlType              : Sample(1),
      riskControlActivation        : Sample(1),
      riskActionType               : Sample(1),
      usdLimit                     : Sample(8),
      timeLimit                    : Sample(4),
      percentageLimit              : Sample(4),
      countLimit                   : Sample(4),
      breachActionResponse         : Sample(1),
      iocAttribution               : Sample(1),
      usdCalculation1              : Sample(8),
      usdCalculation2              : Sample(8),
      usdCalculation3              : Sample(8),
      usdCalculation4              : Sample(8),
      countCalculation             : Sample(4),
      blockedByBreachIndicator     : Sample(1),
      blockedByKillSwitchIndicator : Sample(1),
      reinstatementRequiredBySelf  : Sample(1),
      reinstatementRequiredByOther : Sample(1),
      riskRangeId                  : Sample(1),
      riskMinimumValue             : Sample(8),
      priceScale                   : Sample(1),
      reserved190                  : Sample(190) ]

EncodeRiskControlAcknowledgementMessage(message) ==
    message.symbolId
        \o message.mpid
        \o message.marketMaker
        \o message.mpSubId
        \o message.reserved4
        \o message.clearingNumber
        \o message.clOrdId
        \o message.riskAckType
        \o message.riskUserCrd
        \o message.riskUserType
        \o message.riskControlType
        \o message.riskControlActivation
        \o message.riskActionType
        \o message.usdLimit
        \o message.timeLimit
        \o message.percentageLimit
        \o message.countLimit
        \o message.breachActionResponse
        \o message.iocAttribution
        \o message.usdCalculation1
        \o message.usdCalculation2
        \o message.usdCalculation3
        \o message.usdCalculation4
        \o message.countCalculation
        \o message.blockedByBreachIndicator
        \o message.blockedByKillSwitchIndicator
        \o message.reinstatementRequiredBySelf
        \o message.reinstatementRequiredByOther
        \o message.riskRangeId
        \o message.riskMinimumValue
        \o message.priceScale
        \o message.reserved190

DecodeRiskControlAcknowledgementMessage(bytes) ==
    LET symbolId == ReadBytes(bytes, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET mpid == ReadBytes(symbolId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET marketMaker == ReadBytes(mpid.rest, 10) IN IF ~marketMaker.ok THEN Fail ELSE
    LET mpSubId == ReadBytes(marketMaker.rest, 4) IN IF ~mpSubId.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(mpSubId.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET clearingNumber == ReadBytes(reserved4.rest, 5) IN IF ~clearingNumber.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(clearingNumber.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET riskAckType == ReadBytes(clOrdId.rest, 1) IN IF ~riskAckType.ok THEN Fail ELSE
    LET riskUserCrd == ReadBytes(riskAckType.rest, 4) IN IF ~riskUserCrd.ok THEN Fail ELSE
    LET riskUserType == ReadBytes(riskUserCrd.rest, 1) IN IF ~riskUserType.ok THEN Fail ELSE
    LET riskControlType == ReadBytes(riskUserType.rest, 1) IN IF ~riskControlType.ok THEN Fail ELSE
    LET riskControlActivation == ReadBytes(riskControlType.rest, 1) IN IF ~riskControlActivation.ok THEN Fail ELSE
    LET riskActionType == ReadBytes(riskControlActivation.rest, 1) IN IF ~riskActionType.ok THEN Fail ELSE
    LET usdLimit == ReadBytes(riskActionType.rest, 8) IN IF ~usdLimit.ok THEN Fail ELSE
    LET timeLimit == ReadBytes(usdLimit.rest, 4) IN IF ~timeLimit.ok THEN Fail ELSE
    LET percentageLimit == ReadBytes(timeLimit.rest, 4) IN IF ~percentageLimit.ok THEN Fail ELSE
    LET countLimit == ReadBytes(percentageLimit.rest, 4) IN IF ~countLimit.ok THEN Fail ELSE
    LET breachActionResponse == ReadBytes(countLimit.rest, 1) IN IF ~breachActionResponse.ok THEN Fail ELSE
    LET iocAttribution == ReadBytes(breachActionResponse.rest, 1) IN IF ~iocAttribution.ok THEN Fail ELSE
    LET usdCalculation1 == ReadBytes(iocAttribution.rest, 8) IN IF ~usdCalculation1.ok THEN Fail ELSE
    LET usdCalculation2 == ReadBytes(usdCalculation1.rest, 8) IN IF ~usdCalculation2.ok THEN Fail ELSE
    LET usdCalculation3 == ReadBytes(usdCalculation2.rest, 8) IN IF ~usdCalculation3.ok THEN Fail ELSE
    LET usdCalculation4 == ReadBytes(usdCalculation3.rest, 8) IN IF ~usdCalculation4.ok THEN Fail ELSE
    LET countCalculation == ReadBytes(usdCalculation4.rest, 4) IN IF ~countCalculation.ok THEN Fail ELSE
    LET blockedByBreachIndicator == ReadBytes(countCalculation.rest, 1) IN IF ~blockedByBreachIndicator.ok THEN Fail ELSE
    LET blockedByKillSwitchIndicator == ReadBytes(blockedByBreachIndicator.rest, 1) IN IF ~blockedByKillSwitchIndicator.ok THEN Fail ELSE
    LET reinstatementRequiredBySelf == ReadBytes(blockedByKillSwitchIndicator.rest, 1) IN IF ~reinstatementRequiredBySelf.ok THEN Fail ELSE
    LET reinstatementRequiredByOther == ReadBytes(reinstatementRequiredBySelf.rest, 1) IN IF ~reinstatementRequiredByOther.ok THEN Fail ELSE
    LET riskRangeId == ReadBytes(reinstatementRequiredByOther.rest, 1) IN IF ~riskRangeId.ok THEN Fail ELSE
    LET riskMinimumValue == ReadBytes(riskRangeId.rest, 8) IN IF ~riskMinimumValue.ok THEN Fail ELSE
    LET priceScale == ReadBytes(riskMinimumValue.rest, 1) IN IF ~priceScale.ok THEN Fail ELSE
    LET reserved190 == ReadBytes(priceScale.rest, 190) IN IF ~reserved190.ok THEN Fail ELSE
    Ok([ symbolId                     |-> symbolId.value,
         mpid                         |-> mpid.value,
         marketMaker                  |-> marketMaker.value,
         mpSubId                      |-> mpSubId.value,
         reserved4                    |-> reserved4.value,
         clearingNumber               |-> clearingNumber.value,
         clOrdId                      |-> clOrdId.value,
         riskAckType                  |-> riskAckType.value,
         riskUserCrd                  |-> riskUserCrd.value,
         riskUserType                 |-> riskUserType.value,
         riskControlType              |-> riskControlType.value,
         riskControlActivation        |-> riskControlActivation.value,
         riskActionType               |-> riskActionType.value,
         usdLimit                     |-> usdLimit.value,
         timeLimit                    |-> timeLimit.value,
         percentageLimit              |-> percentageLimit.value,
         countLimit                   |-> countLimit.value,
         breachActionResponse         |-> breachActionResponse.value,
         iocAttribution               |-> iocAttribution.value,
         usdCalculation1              |-> usdCalculation1.value,
         usdCalculation2              |-> usdCalculation2.value,
         usdCalculation3              |-> usdCalculation3.value,
         usdCalculation4              |-> usdCalculation4.value,
         countCalculation             |-> countCalculation.value,
         blockedByBreachIndicator     |-> blockedByBreachIndicator.value,
         blockedByKillSwitchIndicator |-> blockedByKillSwitchIndicator.value,
         reinstatementRequiredBySelf  |-> reinstatementRequiredBySelf.value,
         reinstatementRequiredByOther |-> reinstatementRequiredByOther.value,
         riskRangeId                  |-> riskRangeId.value,
         riskMinimumValue             |-> riskMinimumValue.value,
         priceScale                   |-> priceScale.value,
         reserved190                  |-> reserved190.value ], reserved190.rest)

ZeroRiskControlAcknowledgementMessage ==
    [ symbolId                     |-> [i \in 1 .. 4 |-> 0],
      mpid                         |-> [i \in 1 .. 4 |-> 0],
      marketMaker                  |-> [i \in 1 .. 10 |-> 0],
      mpSubId                      |-> [i \in 1 .. 4 |-> 0],
      reserved4                    |-> [i \in 1 .. 4 |-> 0],
      clearingNumber               |-> [i \in 1 .. 5 |-> 0],
      clOrdId                      |-> [i \in 1 .. 8 |-> 0],
      riskAckType                  |-> [i \in 1 .. 1 |-> 0],
      riskUserCrd                  |-> [i \in 1 .. 4 |-> 0],
      riskUserType                 |-> [i \in 1 .. 1 |-> 0],
      riskControlType              |-> [i \in 1 .. 1 |-> 0],
      riskControlActivation        |-> [i \in 1 .. 1 |-> 0],
      riskActionType               |-> [i \in 1 .. 1 |-> 0],
      usdLimit                     |-> [i \in 1 .. 8 |-> 0],
      timeLimit                    |-> [i \in 1 .. 4 |-> 0],
      percentageLimit              |-> [i \in 1 .. 4 |-> 0],
      countLimit                   |-> [i \in 1 .. 4 |-> 0],
      breachActionResponse         |-> [i \in 1 .. 1 |-> 0],
      iocAttribution               |-> [i \in 1 .. 1 |-> 0],
      usdCalculation1              |-> [i \in 1 .. 8 |-> 0],
      usdCalculation2              |-> [i \in 1 .. 8 |-> 0],
      usdCalculation3              |-> [i \in 1 .. 8 |-> 0],
      usdCalculation4              |-> [i \in 1 .. 8 |-> 0],
      countCalculation             |-> [i \in 1 .. 4 |-> 0],
      blockedByBreachIndicator     |-> [i \in 1 .. 1 |-> 0],
      blockedByKillSwitchIndicator |-> [i \in 1 .. 1 |-> 0],
      reinstatementRequiredBySelf  |-> [i \in 1 .. 1 |-> 0],
      reinstatementRequiredByOther |-> [i \in 1 .. 1 |-> 0],
      riskRangeId                  |-> [i \in 1 .. 1 |-> 0],
      riskMinimumValue             |-> [i \in 1 .. 8 |-> 0],
      priceScale                   |-> [i \in 1 .. 1 |-> 0],
      reserved190                  |-> [i \in 1 .. 190 |-> 0] ]

(* Risk Control Acknowledgement Message at zero, then each field in turn at the values it is checked at *)
CheckedRiskControlAcknowledgementMessage ==
    { ZeroRiskControlAcknowledgementMessage }
        \cup { [ZeroRiskControlAcknowledgementMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroRiskControlAcknowledgementMessage EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroRiskControlAcknowledgementMessage EXCEPT !.marketMaker = one] : one \in Sample(10) }
        \cup { [ZeroRiskControlAcknowledgementMessage EXCEPT !.mpSubId = one] : one \in Sample(4) }
        \cup { [ZeroRiskControlAcknowledgementMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroRiskControlAcknowledgementMessage EXCEPT !.clearingNumber = one] : one \in Sample(5) }
        \cup { [ZeroRiskControlAcknowledgementMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroRiskControlAcknowledgementMessage EXCEPT !.riskAckType = one] : one \in Sample(1) }
        \cup { [ZeroRiskControlAcknowledgementMessage EXCEPT !.riskUserCrd = one] : one \in Sample(4) }
        \cup { [ZeroRiskControlAcknowledgementMessage EXCEPT !.riskUserType = one] : one \in Sample(1) }
        \cup { [ZeroRiskControlAcknowledgementMessage EXCEPT !.riskControlType = one] : one \in Sample(1) }
        \cup { [ZeroRiskControlAcknowledgementMessage EXCEPT !.riskControlActivation = one] : one \in Sample(1) }
        \cup { [ZeroRiskControlAcknowledgementMessage EXCEPT !.riskActionType = one] : one \in Sample(1) }
        \cup { [ZeroRiskControlAcknowledgementMessage EXCEPT !.usdLimit = one] : one \in Sample(8) }
        \cup { [ZeroRiskControlAcknowledgementMessage EXCEPT !.timeLimit = one] : one \in Sample(4) }
        \cup { [ZeroRiskControlAcknowledgementMessage EXCEPT !.percentageLimit = one] : one \in Sample(4) }
        \cup { [ZeroRiskControlAcknowledgementMessage EXCEPT !.countLimit = one] : one \in Sample(4) }
        \cup { [ZeroRiskControlAcknowledgementMessage EXCEPT !.breachActionResponse = one] : one \in Sample(1) }
        \cup { [ZeroRiskControlAcknowledgementMessage EXCEPT !.iocAttribution = one] : one \in Sample(1) }
        \cup { [ZeroRiskControlAcknowledgementMessage EXCEPT !.usdCalculation1 = one] : one \in Sample(8) }
        \cup { [ZeroRiskControlAcknowledgementMessage EXCEPT !.usdCalculation2 = one] : one \in Sample(8) }
        \cup { [ZeroRiskControlAcknowledgementMessage EXCEPT !.usdCalculation3 = one] : one \in Sample(8) }
        \cup { [ZeroRiskControlAcknowledgementMessage EXCEPT !.usdCalculation4 = one] : one \in Sample(8) }
        \cup { [ZeroRiskControlAcknowledgementMessage EXCEPT !.countCalculation = one] : one \in Sample(4) }
        \cup { [ZeroRiskControlAcknowledgementMessage EXCEPT !.blockedByBreachIndicator = one] : one \in Sample(1) }
        \cup { [ZeroRiskControlAcknowledgementMessage EXCEPT !.blockedByKillSwitchIndicator = one] : one \in Sample(1) }
        \cup { [ZeroRiskControlAcknowledgementMessage EXCEPT !.reinstatementRequiredBySelf = one] : one \in Sample(1) }
        \cup { [ZeroRiskControlAcknowledgementMessage EXCEPT !.reinstatementRequiredByOther = one] : one \in Sample(1) }
        \cup { [ZeroRiskControlAcknowledgementMessage EXCEPT !.riskRangeId = one] : one \in Sample(1) }
        \cup { [ZeroRiskControlAcknowledgementMessage EXCEPT !.riskMinimumValue = one] : one \in Sample(8) }
        \cup { [ZeroRiskControlAcknowledgementMessage EXCEPT !.priceScale = one] : one \in Sample(1) }
        \cup { [ZeroRiskControlAcknowledgementMessage EXCEPT !.reserved190 = one] : one \in Sample(190) }

(***************************************************************************)
(* Risk Control Alert Message: 301 bytes                                   *)
(***************************************************************************)

RiskControlAlertMessage ==
    [ symbolId                     : Sample(4),
      mpid                         : Sample(4),
      marketMaker                  : Sample(10),
      mpSubId                      : Sample(4),
      reserved4                    : Sample(4),
      clearingNumber               : Sample(5),
      riskUserCrd                  : Sample(4),
      riskUserType                 : Sample(1),
      riskControlType              : Sample(1),
      usdLimit                     : Sample(8),
      timeLimit                    : Sample(4),
      percentageLimit              : Sample(4),
      countLimit                   : Sample(4),
      breachActionResponse         : Sample(1),
      iocAttribution               : Sample(1),
      usdCalculation1              : Sample(8),
      usdCalculation2              : Sample(8),
      usdCalculation3              : Sample(8),
      usdCalculation4              : Sample(8),
      countCalculation             : Sample(4),
      riskActionType               : Sample(1),
      thresholdBreachLevel         : Sample(1),
      blockedByBreachIndicator     : Sample(1),
      blockedByKillSwitchIndicator : Sample(1),
      reinstatementRequiredBySelf  : Sample(1),
      reinstatementRequiredByOther : Sample(1),
      reserved200                  : Sample(200) ]

EncodeRiskControlAlertMessage(message) ==
    message.symbolId
        \o message.mpid
        \o message.marketMaker
        \o message.mpSubId
        \o message.reserved4
        \o message.clearingNumber
        \o message.riskUserCrd
        \o message.riskUserType
        \o message.riskControlType
        \o message.usdLimit
        \o message.timeLimit
        \o message.percentageLimit
        \o message.countLimit
        \o message.breachActionResponse
        \o message.iocAttribution
        \o message.usdCalculation1
        \o message.usdCalculation2
        \o message.usdCalculation3
        \o message.usdCalculation4
        \o message.countCalculation
        \o message.riskActionType
        \o message.thresholdBreachLevel
        \o message.blockedByBreachIndicator
        \o message.blockedByKillSwitchIndicator
        \o message.reinstatementRequiredBySelf
        \o message.reinstatementRequiredByOther
        \o message.reserved200

DecodeRiskControlAlertMessage(bytes) ==
    LET symbolId == ReadBytes(bytes, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET mpid == ReadBytes(symbolId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET marketMaker == ReadBytes(mpid.rest, 10) IN IF ~marketMaker.ok THEN Fail ELSE
    LET mpSubId == ReadBytes(marketMaker.rest, 4) IN IF ~mpSubId.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(mpSubId.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET clearingNumber == ReadBytes(reserved4.rest, 5) IN IF ~clearingNumber.ok THEN Fail ELSE
    LET riskUserCrd == ReadBytes(clearingNumber.rest, 4) IN IF ~riskUserCrd.ok THEN Fail ELSE
    LET riskUserType == ReadBytes(riskUserCrd.rest, 1) IN IF ~riskUserType.ok THEN Fail ELSE
    LET riskControlType == ReadBytes(riskUserType.rest, 1) IN IF ~riskControlType.ok THEN Fail ELSE
    LET usdLimit == ReadBytes(riskControlType.rest, 8) IN IF ~usdLimit.ok THEN Fail ELSE
    LET timeLimit == ReadBytes(usdLimit.rest, 4) IN IF ~timeLimit.ok THEN Fail ELSE
    LET percentageLimit == ReadBytes(timeLimit.rest, 4) IN IF ~percentageLimit.ok THEN Fail ELSE
    LET countLimit == ReadBytes(percentageLimit.rest, 4) IN IF ~countLimit.ok THEN Fail ELSE
    LET breachActionResponse == ReadBytes(countLimit.rest, 1) IN IF ~breachActionResponse.ok THEN Fail ELSE
    LET iocAttribution == ReadBytes(breachActionResponse.rest, 1) IN IF ~iocAttribution.ok THEN Fail ELSE
    LET usdCalculation1 == ReadBytes(iocAttribution.rest, 8) IN IF ~usdCalculation1.ok THEN Fail ELSE
    LET usdCalculation2 == ReadBytes(usdCalculation1.rest, 8) IN IF ~usdCalculation2.ok THEN Fail ELSE
    LET usdCalculation3 == ReadBytes(usdCalculation2.rest, 8) IN IF ~usdCalculation3.ok THEN Fail ELSE
    LET usdCalculation4 == ReadBytes(usdCalculation3.rest, 8) IN IF ~usdCalculation4.ok THEN Fail ELSE
    LET countCalculation == ReadBytes(usdCalculation4.rest, 4) IN IF ~countCalculation.ok THEN Fail ELSE
    LET riskActionType == ReadBytes(countCalculation.rest, 1) IN IF ~riskActionType.ok THEN Fail ELSE
    LET thresholdBreachLevel == ReadBytes(riskActionType.rest, 1) IN IF ~thresholdBreachLevel.ok THEN Fail ELSE
    LET blockedByBreachIndicator == ReadBytes(thresholdBreachLevel.rest, 1) IN IF ~blockedByBreachIndicator.ok THEN Fail ELSE
    LET blockedByKillSwitchIndicator == ReadBytes(blockedByBreachIndicator.rest, 1) IN IF ~blockedByKillSwitchIndicator.ok THEN Fail ELSE
    LET reinstatementRequiredBySelf == ReadBytes(blockedByKillSwitchIndicator.rest, 1) IN IF ~reinstatementRequiredBySelf.ok THEN Fail ELSE
    LET reinstatementRequiredByOther == ReadBytes(reinstatementRequiredBySelf.rest, 1) IN IF ~reinstatementRequiredByOther.ok THEN Fail ELSE
    LET reserved200 == ReadBytes(reinstatementRequiredByOther.rest, 200) IN IF ~reserved200.ok THEN Fail ELSE
    Ok([ symbolId                     |-> symbolId.value,
         mpid                         |-> mpid.value,
         marketMaker                  |-> marketMaker.value,
         mpSubId                      |-> mpSubId.value,
         reserved4                    |-> reserved4.value,
         clearingNumber               |-> clearingNumber.value,
         riskUserCrd                  |-> riskUserCrd.value,
         riskUserType                 |-> riskUserType.value,
         riskControlType              |-> riskControlType.value,
         usdLimit                     |-> usdLimit.value,
         timeLimit                    |-> timeLimit.value,
         percentageLimit              |-> percentageLimit.value,
         countLimit                   |-> countLimit.value,
         breachActionResponse         |-> breachActionResponse.value,
         iocAttribution               |-> iocAttribution.value,
         usdCalculation1              |-> usdCalculation1.value,
         usdCalculation2              |-> usdCalculation2.value,
         usdCalculation3              |-> usdCalculation3.value,
         usdCalculation4              |-> usdCalculation4.value,
         countCalculation             |-> countCalculation.value,
         riskActionType               |-> riskActionType.value,
         thresholdBreachLevel         |-> thresholdBreachLevel.value,
         blockedByBreachIndicator     |-> blockedByBreachIndicator.value,
         blockedByKillSwitchIndicator |-> blockedByKillSwitchIndicator.value,
         reinstatementRequiredBySelf  |-> reinstatementRequiredBySelf.value,
         reinstatementRequiredByOther |-> reinstatementRequiredByOther.value,
         reserved200                  |-> reserved200.value ], reserved200.rest)

ZeroRiskControlAlertMessage ==
    [ symbolId                     |-> [i \in 1 .. 4 |-> 0],
      mpid                         |-> [i \in 1 .. 4 |-> 0],
      marketMaker                  |-> [i \in 1 .. 10 |-> 0],
      mpSubId                      |-> [i \in 1 .. 4 |-> 0],
      reserved4                    |-> [i \in 1 .. 4 |-> 0],
      clearingNumber               |-> [i \in 1 .. 5 |-> 0],
      riskUserCrd                  |-> [i \in 1 .. 4 |-> 0],
      riskUserType                 |-> [i \in 1 .. 1 |-> 0],
      riskControlType              |-> [i \in 1 .. 1 |-> 0],
      usdLimit                     |-> [i \in 1 .. 8 |-> 0],
      timeLimit                    |-> [i \in 1 .. 4 |-> 0],
      percentageLimit              |-> [i \in 1 .. 4 |-> 0],
      countLimit                   |-> [i \in 1 .. 4 |-> 0],
      breachActionResponse         |-> [i \in 1 .. 1 |-> 0],
      iocAttribution               |-> [i \in 1 .. 1 |-> 0],
      usdCalculation1              |-> [i \in 1 .. 8 |-> 0],
      usdCalculation2              |-> [i \in 1 .. 8 |-> 0],
      usdCalculation3              |-> [i \in 1 .. 8 |-> 0],
      usdCalculation4              |-> [i \in 1 .. 8 |-> 0],
      countCalculation             |-> [i \in 1 .. 4 |-> 0],
      riskActionType               |-> [i \in 1 .. 1 |-> 0],
      thresholdBreachLevel         |-> [i \in 1 .. 1 |-> 0],
      blockedByBreachIndicator     |-> [i \in 1 .. 1 |-> 0],
      blockedByKillSwitchIndicator |-> [i \in 1 .. 1 |-> 0],
      reinstatementRequiredBySelf  |-> [i \in 1 .. 1 |-> 0],
      reinstatementRequiredByOther |-> [i \in 1 .. 1 |-> 0],
      reserved200                  |-> [i \in 1 .. 200 |-> 0] ]

(* Risk Control Alert Message at zero, then each field in turn at the values it is checked at *)
CheckedRiskControlAlertMessage ==
    { ZeroRiskControlAlertMessage }
        \cup { [ZeroRiskControlAlertMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroRiskControlAlertMessage EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroRiskControlAlertMessage EXCEPT !.marketMaker = one] : one \in Sample(10) }
        \cup { [ZeroRiskControlAlertMessage EXCEPT !.mpSubId = one] : one \in Sample(4) }
        \cup { [ZeroRiskControlAlertMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroRiskControlAlertMessage EXCEPT !.clearingNumber = one] : one \in Sample(5) }
        \cup { [ZeroRiskControlAlertMessage EXCEPT !.riskUserCrd = one] : one \in Sample(4) }
        \cup { [ZeroRiskControlAlertMessage EXCEPT !.riskUserType = one] : one \in Sample(1) }
        \cup { [ZeroRiskControlAlertMessage EXCEPT !.riskControlType = one] : one \in Sample(1) }
        \cup { [ZeroRiskControlAlertMessage EXCEPT !.usdLimit = one] : one \in Sample(8) }
        \cup { [ZeroRiskControlAlertMessage EXCEPT !.timeLimit = one] : one \in Sample(4) }
        \cup { [ZeroRiskControlAlertMessage EXCEPT !.percentageLimit = one] : one \in Sample(4) }
        \cup { [ZeroRiskControlAlertMessage EXCEPT !.countLimit = one] : one \in Sample(4) }
        \cup { [ZeroRiskControlAlertMessage EXCEPT !.breachActionResponse = one] : one \in Sample(1) }
        \cup { [ZeroRiskControlAlertMessage EXCEPT !.iocAttribution = one] : one \in Sample(1) }
        \cup { [ZeroRiskControlAlertMessage EXCEPT !.usdCalculation1 = one] : one \in Sample(8) }
        \cup { [ZeroRiskControlAlertMessage EXCEPT !.usdCalculation2 = one] : one \in Sample(8) }
        \cup { [ZeroRiskControlAlertMessage EXCEPT !.usdCalculation3 = one] : one \in Sample(8) }
        \cup { [ZeroRiskControlAlertMessage EXCEPT !.usdCalculation4 = one] : one \in Sample(8) }
        \cup { [ZeroRiskControlAlertMessage EXCEPT !.countCalculation = one] : one \in Sample(4) }
        \cup { [ZeroRiskControlAlertMessage EXCEPT !.riskActionType = one] : one \in Sample(1) }
        \cup { [ZeroRiskControlAlertMessage EXCEPT !.thresholdBreachLevel = one] : one \in Sample(1) }
        \cup { [ZeroRiskControlAlertMessage EXCEPT !.blockedByBreachIndicator = one] : one \in Sample(1) }
        \cup { [ZeroRiskControlAlertMessage EXCEPT !.blockedByKillSwitchIndicator = one] : one \in Sample(1) }
        \cup { [ZeroRiskControlAlertMessage EXCEPT !.reinstatementRequiredBySelf = one] : one \in Sample(1) }
        \cup { [ZeroRiskControlAlertMessage EXCEPT !.reinstatementRequiredByOther = one] : one \in Sample(1) }
        \cup { [ZeroRiskControlAlertMessage EXCEPT !.reserved200 = one] : one \in Sample(200) }

(***************************************************************************)
(* Leg Group: 7 bytes                                                      *)
(***************************************************************************)

LegGroup ==
    [ legSymbolId : Sample(4),
      legRatioQty : Sample(2),
      legSide     : Sample(1) ]

EncodeLegGroup(message) ==
    message.legSymbolId
        \o message.legRatioQty
        \o message.legSide

DecodeLegGroup(bytes) ==
    LET legSymbolId == ReadBytes(bytes, 4) IN IF ~legSymbolId.ok THEN Fail ELSE
    LET legRatioQty == ReadBytes(legSymbolId.rest, 2) IN IF ~legRatioQty.ok THEN Fail ELSE
    LET legSide == ReadBytes(legRatioQty.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    Ok([ legSymbolId |-> legSymbolId.value,
         legRatioQty |-> legRatioQty.value,
         legSide     |-> legSide.value ], legSide.rest)

ZeroLegGroup ==
    [ legSymbolId |-> [i \in 1 .. 4 |-> 0],
      legRatioQty |-> [i \in 1 .. 2 |-> 0],
      legSide     |-> [i \in 1 .. 1 |-> 0] ]

(* Leg Group at zero, then each field in turn at the values it is checked at *)
CheckedLegGroup ==
    { ZeroLegGroup }
        \cup { [ZeroLegGroup EXCEPT !.legSymbolId = one] : one \in Sample(4) }
        \cup { [ZeroLegGroup EXCEPT !.legRatioQty = one] : one \in Sample(2) }
        \cup { [ZeroLegGroup EXCEPT !.legSide = one] : one \in Sample(1) }

(* A run of Leg Group, written one after another *)
RECURSIVE EncodeLegGroupList(_)
EncodeLegGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLegGroup(Head(messages)) \o EncodeLegGroupList(Tail(messages))

(* As many Leg Group as the field that counts them says *)
RECURSIVE ReadLegGroupList(_, _)
ReadLegGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLegGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLegGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Leg Group of each kind, for the lists that carry them *)
OneLegGroup == { ZeroLegGroup }

(***************************************************************************)
(* Complex Series Request Acknowledgement Message                          *)
(***************************************************************************)

ComplexSeriesRequestAcknowledgementMessage ==
    [ transactTime : Sample(8),
      clOrdId      : Sample(8),
      reasonCode   : Sample(2),
      symbolId     : Sample(4),
      side         : Sample(1),
      legGroup     : SampleLists(OneLegGroup) ]

EncodeComplexSeriesRequestAcknowledgementMessage(message) ==
    message.transactTime
        \o message.clOrdId
        \o message.reasonCode
        \o message.symbolId
        \o message.side
        \o EncodeUIntBE(Len(message.legGroup), 1)
        \o EncodeLegGroupList(message.legGroup)

DecodeComplexSeriesRequestAcknowledgementMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactTime.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(clOrdId.rest, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET symbolId == ReadBytes(reasonCode.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET side == ReadBytes(symbolId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET repeatingGroups == ReadUIntBE(side.rest, 1) IN IF ~repeatingGroups.ok THEN Fail ELSE
    LET legGroup == ReadLegGroupList(repeatingGroups.rest, repeatingGroups.value) IN IF ~legGroup.ok THEN Fail ELSE
    Ok([ transactTime |-> transactTime.value,
         clOrdId      |-> clOrdId.value,
         reasonCode   |-> reasonCode.value,
         symbolId     |-> symbolId.value,
         side         |-> side.value,
         legGroup     |-> legGroup.value ], legGroup.rest)

ZeroComplexSeriesRequestAcknowledgementMessage ==
    [ transactTime |-> [i \in 1 .. 8 |-> 0],
      clOrdId      |-> [i \in 1 .. 8 |-> 0],
      reasonCode   |-> [i \in 1 .. 2 |-> 0],
      symbolId     |-> [i \in 1 .. 4 |-> 0],
      side         |-> [i \in 1 .. 1 |-> 0],
      legGroup     |-> << >> ]

(* Complex Series Request Acknowledgement Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexSeriesRequestAcknowledgementMessage ==
    { ZeroComplexSeriesRequestAcknowledgementMessage }
        \cup { [ZeroComplexSeriesRequestAcknowledgementMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroComplexSeriesRequestAcknowledgementMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroComplexSeriesRequestAcknowledgementMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroComplexSeriesRequestAcknowledgementMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroComplexSeriesRequestAcknowledgementMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroComplexSeriesRequestAcknowledgementMessage EXCEPT !.legGroup = one] : one \in SampleLists(OneLegGroup) }

(***************************************************************************)
(* Server Sequenced Message, selected by Seq Msg Type                      *)
(***************************************************************************)

UnderlyingSymbolReferenceDataMessageCode == 563  \* 0x233
SeriesReferenceDataMessageCode == 564  \* 0x234
MinimumPriceVariantClassReferenceDataMessageCode == 560  \* 0x230
MinimumPriceVariantLevelReferenceDataMessageCode == 561  \* 0x231
MpidConfigurationMessageCode == 626  \* 0x272
OptionsMarketMakerSymbolAppointmentReferenceDataMessageCode == 2099  \* 0x833
SessionConfigurationAcknowledgementMessageCode == 545  \* 0x221
OrderAndCancelReplaceAcknowledgementMessageCode == 617  \* 0x269
BulkQuoteAcknowledgmentMessageCode == 660  \* 0x294
BulkQuoteAcknowledgmentWithDetailsMessageCode == 776  \* 0x308
OrderSingleComplexModifyCancelRequestAcknowledgmentAndUroutMessageCode == 632  \* 0x278
OrderPriorityUpdateAcknowledgmentMessageCode == 616  \* 0x268
ExecutionReportMessageCode == 661  \* 0x295
TradeBustCorrectMessageCode == 659  \* 0x293
ApplicationLayerRejectMessageCode == 615  \* 0x267
RiskControlAcknowledgementMessageCode == 818  \* 0x332
RiskControlAlertMessageCode == 819  \* 0x333
ComplexSeriesRequestAcknowledgementMessageCode == 856  \* 0x358

ServerSequencedMessage ==
    [ tag : {UnderlyingSymbolReferenceDataMessageCode}, body : UnderlyingSymbolReferenceDataMessage ]
        \cup [ tag : {SeriesReferenceDataMessageCode}, body : SeriesReferenceDataMessage ]
        \cup [ tag : {MinimumPriceVariantClassReferenceDataMessageCode}, body : MinimumPriceVariantClassReferenceDataMessage ]
        \cup [ tag : {MinimumPriceVariantLevelReferenceDataMessageCode}, body : MinimumPriceVariantLevelReferenceDataMessage ]
        \cup [ tag : {MpidConfigurationMessageCode}, body : MpidConfigurationMessage ]
        \cup [ tag : {OptionsMarketMakerSymbolAppointmentReferenceDataMessageCode}, body : OptionsMarketMakerSymbolAppointmentReferenceDataMessage ]
        \cup [ tag : {SessionConfigurationAcknowledgementMessageCode}, body : SessionConfigurationAcknowledgementMessage ]
        \cup [ tag : {OrderAndCancelReplaceAcknowledgementMessageCode}, body : OrderAndCancelReplaceAcknowledgementMessage ]
        \cup [ tag : {BulkQuoteAcknowledgmentMessageCode}, body : BulkQuoteAcknowledgmentMessage ]
        \cup [ tag : {BulkQuoteAcknowledgmentWithDetailsMessageCode}, body : BulkQuoteAcknowledgmentWithDetailsMessage ]
        \cup [ tag : {OrderSingleComplexModifyCancelRequestAcknowledgmentAndUroutMessageCode}, body : OrderSingleComplexModifyCancelRequestAcknowledgmentAndUroutMessage ]
        \cup [ tag : {OrderPriorityUpdateAcknowledgmentMessageCode}, body : OrderPriorityUpdateAcknowledgmentMessage ]
        \cup [ tag : {ExecutionReportMessageCode}, body : ExecutionReportMessage ]
        \cup [ tag : {TradeBustCorrectMessageCode}, body : TradeBustCorrectMessage ]
        \cup [ tag : {ApplicationLayerRejectMessageCode}, body : ApplicationLayerRejectMessage ]
        \cup [ tag : {RiskControlAcknowledgementMessageCode}, body : RiskControlAcknowledgementMessage ]
        \cup [ tag : {RiskControlAlertMessageCode}, body : RiskControlAlertMessage ]
        \cup [ tag : {ComplexSeriesRequestAcknowledgementMessageCode}, body : ComplexSeriesRequestAcknowledgementMessage ]

EncodeServerSequencedMessage(message) ==
    CASE message.tag = UnderlyingSymbolReferenceDataMessageCode -> EncodeUnderlyingSymbolReferenceDataMessage(message.body)
      [] message.tag = SeriesReferenceDataMessageCode -> EncodeSeriesReferenceDataMessage(message.body)
      [] message.tag = MinimumPriceVariantClassReferenceDataMessageCode -> EncodeMinimumPriceVariantClassReferenceDataMessage(message.body)
      [] message.tag = MinimumPriceVariantLevelReferenceDataMessageCode -> EncodeMinimumPriceVariantLevelReferenceDataMessage(message.body)
      [] message.tag = MpidConfigurationMessageCode -> EncodeMpidConfigurationMessage(message.body)
      [] message.tag = OptionsMarketMakerSymbolAppointmentReferenceDataMessageCode -> EncodeOptionsMarketMakerSymbolAppointmentReferenceDataMessage(message.body)
      [] message.tag = SessionConfigurationAcknowledgementMessageCode -> EncodeSessionConfigurationAcknowledgementMessage(message.body)
      [] message.tag = OrderAndCancelReplaceAcknowledgementMessageCode -> EncodeOrderAndCancelReplaceAcknowledgementMessage(message.body)
      [] message.tag = BulkQuoteAcknowledgmentMessageCode -> EncodeBulkQuoteAcknowledgmentMessage(message.body)
      [] message.tag = BulkQuoteAcknowledgmentWithDetailsMessageCode -> EncodeBulkQuoteAcknowledgmentWithDetailsMessage(message.body)
      [] message.tag = OrderSingleComplexModifyCancelRequestAcknowledgmentAndUroutMessageCode -> EncodeOrderSingleComplexModifyCancelRequestAcknowledgmentAndUroutMessage(message.body)
      [] message.tag = OrderPriorityUpdateAcknowledgmentMessageCode -> EncodeOrderPriorityUpdateAcknowledgmentMessage(message.body)
      [] message.tag = ExecutionReportMessageCode -> EncodeExecutionReportMessage(message.body)
      [] message.tag = TradeBustCorrectMessageCode -> EncodeTradeBustCorrectMessage(message.body)
      [] message.tag = ApplicationLayerRejectMessageCode -> EncodeApplicationLayerRejectMessage(message.body)
      [] message.tag = RiskControlAcknowledgementMessageCode -> EncodeRiskControlAcknowledgementMessage(message.body)
      [] message.tag = RiskControlAlertMessageCode -> EncodeRiskControlAlertMessage(message.body)
      [] message.tag = ComplexSeriesRequestAcknowledgementMessageCode -> EncodeComplexSeriesRequestAcknowledgementMessage(message.body)

DecodeServerSequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = UnderlyingSymbolReferenceDataMessageCode -> DecodeUnderlyingSymbolReferenceDataMessage(bytes)
              [] tag = SeriesReferenceDataMessageCode -> DecodeSeriesReferenceDataMessage(bytes)
              [] tag = MinimumPriceVariantClassReferenceDataMessageCode -> DecodeMinimumPriceVariantClassReferenceDataMessage(bytes)
              [] tag = MinimumPriceVariantLevelReferenceDataMessageCode -> DecodeMinimumPriceVariantLevelReferenceDataMessage(bytes)
              [] tag = MpidConfigurationMessageCode -> DecodeMpidConfigurationMessage(bytes)
              [] tag = OptionsMarketMakerSymbolAppointmentReferenceDataMessageCode -> DecodeOptionsMarketMakerSymbolAppointmentReferenceDataMessage(bytes)
              [] tag = SessionConfigurationAcknowledgementMessageCode -> DecodeSessionConfigurationAcknowledgementMessage(bytes)
              [] tag = OrderAndCancelReplaceAcknowledgementMessageCode -> DecodeOrderAndCancelReplaceAcknowledgementMessage(bytes)
              [] tag = BulkQuoteAcknowledgmentMessageCode -> DecodeBulkQuoteAcknowledgmentMessage(bytes)
              [] tag = BulkQuoteAcknowledgmentWithDetailsMessageCode -> DecodeBulkQuoteAcknowledgmentWithDetailsMessage(bytes)
              [] tag = OrderSingleComplexModifyCancelRequestAcknowledgmentAndUroutMessageCode -> DecodeOrderSingleComplexModifyCancelRequestAcknowledgmentAndUroutMessage(bytes)
              [] tag = OrderPriorityUpdateAcknowledgmentMessageCode -> DecodeOrderPriorityUpdateAcknowledgmentMessage(bytes)
              [] tag = ExecutionReportMessageCode -> DecodeExecutionReportMessage(bytes)
              [] tag = TradeBustCorrectMessageCode -> DecodeTradeBustCorrectMessage(bytes)
              [] tag = ApplicationLayerRejectMessageCode -> DecodeApplicationLayerRejectMessage(bytes)
              [] tag = RiskControlAcknowledgementMessageCode -> DecodeRiskControlAcknowledgementMessage(bytes)
              [] tag = RiskControlAlertMessageCode -> DecodeRiskControlAlertMessage(bytes)
              [] tag = ComplexSeriesRequestAcknowledgementMessageCode -> DecodeComplexSeriesRequestAcknowledgementMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroServerSequencedMessage == [tag |-> UnderlyingSymbolReferenceDataMessageCode, body |-> ZeroUnderlyingSymbolReferenceDataMessage]

(* Each Server Sequenced Message in turn, at the values the message it names is checked at *)
CheckedServerSequencedMessage ==
    { [tag |-> UnderlyingSymbolReferenceDataMessageCode, body |-> one] : one \in CheckedUnderlyingSymbolReferenceDataMessage }
        \cup { [tag |-> SeriesReferenceDataMessageCode, body |-> one] : one \in CheckedSeriesReferenceDataMessage }
        \cup { [tag |-> MinimumPriceVariantClassReferenceDataMessageCode, body |-> one] : one \in CheckedMinimumPriceVariantClassReferenceDataMessage }
        \cup { [tag |-> MinimumPriceVariantLevelReferenceDataMessageCode, body |-> one] : one \in CheckedMinimumPriceVariantLevelReferenceDataMessage }
        \cup { [tag |-> MpidConfigurationMessageCode, body |-> one] : one \in CheckedMpidConfigurationMessage }
        \cup { [tag |-> OptionsMarketMakerSymbolAppointmentReferenceDataMessageCode, body |-> one] : one \in CheckedOptionsMarketMakerSymbolAppointmentReferenceDataMessage }
        \cup { [tag |-> SessionConfigurationAcknowledgementMessageCode, body |-> one] : one \in CheckedSessionConfigurationAcknowledgementMessage }
        \cup { [tag |-> OrderAndCancelReplaceAcknowledgementMessageCode, body |-> one] : one \in CheckedOrderAndCancelReplaceAcknowledgementMessage }
        \cup { [tag |-> BulkQuoteAcknowledgmentMessageCode, body |-> one] : one \in CheckedBulkQuoteAcknowledgmentMessage }
        \cup { [tag |-> BulkQuoteAcknowledgmentWithDetailsMessageCode, body |-> one] : one \in CheckedBulkQuoteAcknowledgmentWithDetailsMessage }
        \cup { [tag |-> OrderSingleComplexModifyCancelRequestAcknowledgmentAndUroutMessageCode, body |-> one] : one \in CheckedOrderSingleComplexModifyCancelRequestAcknowledgmentAndUroutMessage }
        \cup { [tag |-> OrderPriorityUpdateAcknowledgmentMessageCode, body |-> one] : one \in CheckedOrderPriorityUpdateAcknowledgmentMessage }
        \cup { [tag |-> ExecutionReportMessageCode, body |-> one] : one \in CheckedExecutionReportMessage }
        \cup { [tag |-> TradeBustCorrectMessageCode, body |-> one] : one \in CheckedTradeBustCorrectMessage }
        \cup { [tag |-> ApplicationLayerRejectMessageCode, body |-> one] : one \in CheckedApplicationLayerRejectMessage }
        \cup { [tag |-> RiskControlAcknowledgementMessageCode, body |-> one] : one \in CheckedRiskControlAcknowledgementMessage }
        \cup { [tag |-> RiskControlAlertMessageCode, body |-> one] : one \in CheckedRiskControlAlertMessage }
        \cup { [tag |-> ComplexSeriesRequestAcknowledgementMessageCode, body |-> one] : one \in CheckedComplexSeriesRequestAcknowledgementMessage }

(***************************************************************************)
(* Server Seq Msg, framed by Msg Length                                    *)
(***************************************************************************)

ServerSeqMsg ==
    [ seqMsgId               : SeqMsgId,
      reserved4              : Sample(4),
      timestamp              : Sample(8),
      serverSequencedMessage : ServerSequencedMessage ]

EncodeServerSeqMsgBody(message) ==
    EncodeSeqMsgId(message.seqMsgId)
        \o message.reserved4
        \o message.timestamp
        \o EncodeUIntLE(message.serverSequencedMessage.tag, 2)
        \o EncodeUIntLE(Len(EncodeServerSequencedMessage(message.serverSequencedMessage)) + 4, 2)
        \o EncodeServerSequencedMessage(message.serverSequencedMessage)

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
    LET seqMsgType == ReadUIntLE(timestamp.rest, 2) IN IF ~seqMsgType.ok THEN Fail ELSE
    LET seqMsgLength == ReadUIntLE(seqMsgType.rest, 2) IN IF ~seqMsgLength.ok THEN Fail ELSE
    LET serverSequencedMessageSize == seqMsgLength.value - 4 IN
    IF serverSequencedMessageSize < 0 \/ Len(seqMsgLength.rest) < serverSequencedMessageSize THEN Fail ELSE
    LET serverSequencedMessageFramed == SubSeq(seqMsgLength.rest, 1, serverSequencedMessageSize)
        serverSequencedMessageBeyond == SubSeq(seqMsgLength.rest, serverSequencedMessageSize + 1, Len(seqMsgLength.rest))
        serverSequencedMessage == DecodeServerSequencedMessage(seqMsgType.value, serverSequencedMessageFramed)
    IN  IF ~serverSequencedMessage.ok \/ serverSequencedMessage.rest # << >> THEN Fail ELSE
    IF serverSequencedMessageBeyond # << >> THEN Fail ELSE
    Ok([ seqMsgId               |-> seqMsgId.value,
         reserved4              |-> reserved4.value,
         timestamp              |-> timestamp.value,
         serverSequencedMessage |-> serverSequencedMessage.value ], beyond)

ZeroServerSeqMsg ==
    [ seqMsgId               |-> ZeroSeqMsgId,
      reserved4              |-> [i \in 1 .. 4 |-> 0],
      timestamp              |-> [i \in 1 .. 8 |-> 0],
      serverSequencedMessage |-> ZeroServerSequencedMessage ]

(* Server Seq Msg at zero, then each field in turn at the values it is checked at *)
CheckedServerSeqMsg ==
    { ZeroServerSeqMsg }
        \cup { [ZeroServerSeqMsg EXCEPT !.seqMsgId = one] : one \in CheckedSeqMsgId }
        \cup { [ZeroServerSeqMsg EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroServerSeqMsg EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroServerSeqMsg EXCEPT !.serverSequencedMessage = one] : one \in CheckedServerSequencedMessage }

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

(* Every Underlying Symbol Reference Data Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUnderlyingSymbolReferenceDataMessage ==
    \A message \in CheckedUnderlyingSymbolReferenceDataMessage :
        LET read == DecodeUnderlyingSymbolReferenceDataMessage(EncodeUnderlyingSymbolReferenceDataMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Series Reference Data Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSeriesReferenceDataMessage ==
    \A message \in CheckedSeriesReferenceDataMessage :
        LET read == DecodeSeriesReferenceDataMessage(EncodeSeriesReferenceDataMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Minimum Price Variant Class Reference Data Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMinimumPriceVariantClassReferenceDataMessage ==
    \A message \in CheckedMinimumPriceVariantClassReferenceDataMessage :
        LET read == DecodeMinimumPriceVariantClassReferenceDataMessage(EncodeMinimumPriceVariantClassReferenceDataMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mpv Level Definition decodes back to what was encoded, and leaves nothing over *)
RoundTripMpvLevelDefinition ==
    \A message \in CheckedMpvLevelDefinition :
        LET read == DecodeMpvLevelDefinition(EncodeMpvLevelDefinition(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Minimum Price Variant Level Reference Data Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMinimumPriceVariantLevelReferenceDataMessage ==
    \A message \in CheckedMinimumPriceVariantLevelReferenceDataMessage :
        LET read == DecodeMinimumPriceVariantLevelReferenceDataMessage(EncodeMinimumPriceVariantLevelReferenceDataMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mpid Configuration Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMpidConfigurationMessage ==
    \A message \in CheckedMpidConfigurationMessage :
        LET read == DecodeMpidConfigurationMessage(EncodeMpidConfigurationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Options Market Maker Symbol Appointment Reference Data Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionsMarketMakerSymbolAppointmentReferenceDataMessage ==
    \A message \in CheckedOptionsMarketMakerSymbolAppointmentReferenceDataMessage :
        LET read == DecodeOptionsMarketMakerSymbolAppointmentReferenceDataMessage(EncodeOptionsMarketMakerSymbolAppointmentReferenceDataMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Session Configuration Acknowledgement Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSessionConfigurationAcknowledgementMessage ==
    \A message \in CheckedSessionConfigurationAcknowledgementMessage :
        LET read == DecodeSessionConfigurationAcknowledgementMessage(EncodeSessionConfigurationAcknowledgementMessage(message))
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

(* Every Order And Cancel Replace Acknowledgement Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderAndCancelReplaceAcknowledgementMessage ==
    \A message \in CheckedOrderAndCancelReplaceAcknowledgementMessage :
        LET read == DecodeOrderAndCancelReplaceAcknowledgementMessage(EncodeOrderAndCancelReplaceAcknowledgementMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Ack Group decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteAckGroup ==
    \A message \in CheckedQuoteAckGroup :
        LET read == DecodeQuoteAckGroup(EncodeQuoteAckGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulk Quote Acknowledgment Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkQuoteAcknowledgmentMessage ==
    \A message \in CheckedBulkQuoteAcknowledgmentMessage :
        LET read == DecodeBulkQuoteAcknowledgmentMessage(EncodeBulkQuoteAcknowledgmentMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Ack With Id Group decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteAckWithIdGroup ==
    \A message \in CheckedQuoteAckWithIdGroup :
        LET read == DecodeQuoteAckWithIdGroup(EncodeQuoteAckWithIdGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulk Quote Acknowledgment With Details Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkQuoteAcknowledgmentWithDetailsMessage ==
    \A message \in CheckedBulkQuoteAcknowledgmentWithDetailsMessage :
        LET read == DecodeBulkQuoteAcknowledgmentWithDetailsMessage(EncodeBulkQuoteAcknowledgmentWithDetailsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Single Complex Modify Cancel Request Acknowledgment And Urout Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderSingleComplexModifyCancelRequestAcknowledgmentAndUroutMessage ==
    \A message \in CheckedOrderSingleComplexModifyCancelRequestAcknowledgmentAndUroutMessage :
        LET read == DecodeOrderSingleComplexModifyCancelRequestAcknowledgmentAndUroutMessage(EncodeOrderSingleComplexModifyCancelRequestAcknowledgmentAndUroutMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Priority Update Acknowledgment Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderPriorityUpdateAcknowledgmentMessage ==
    \A message \in CheckedOrderPriorityUpdateAcknowledgmentMessage :
        LET read == DecodeOrderPriorityUpdateAcknowledgmentMessage(EncodeOrderPriorityUpdateAcknowledgmentMessage(message))
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

(* Every Optional Order Add On decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionalOrderAddOn2 ==
    \A message \in CheckedOptionalOrderAddOn2 :
        LET read == DecodeOptionalOrderAddOn2(EncodeOptionalOrderAddOn2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionReportMessage ==
    \A message \in CheckedExecutionReportMessage :
        LET read == DecodeExecutionReportMessage(EncodeExecutionReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stream Id decodes back to what was encoded, and leaves nothing over *)
RoundTripStreamId5 ==
    \A message \in CheckedStreamId5 :
        LET read == DecodeStreamId5(EncodeStreamId5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ref Seq Msg Id decodes back to what was encoded, and leaves nothing over *)
RoundTripRefSeqMsgId ==
    \A message \in CheckedRefSeqMsgId :
        LET read == DecodeRefSeqMsgId(EncodeRefSeqMsgId(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Bust Correct Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBustCorrectMessage ==
    \A message \in CheckedTradeBustCorrectMessage :
        LET read == DecodeTradeBustCorrectMessage(EncodeTradeBustCorrectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Application Layer Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripApplicationLayerRejectMessage ==
    \A message \in CheckedApplicationLayerRejectMessage :
        LET read == DecodeApplicationLayerRejectMessage(EncodeApplicationLayerRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Risk Control Acknowledgement Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRiskControlAcknowledgementMessage ==
    \A message \in CheckedRiskControlAcknowledgementMessage :
        LET read == DecodeRiskControlAcknowledgementMessage(EncodeRiskControlAcknowledgementMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Risk Control Alert Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRiskControlAlertMessage ==
    \A message \in CheckedRiskControlAlertMessage :
        LET read == DecodeRiskControlAlertMessage(EncodeRiskControlAlertMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Leg Group decodes back to what was encoded, and leaves nothing over *)
RoundTripLegGroup ==
    \A message \in CheckedLegGroup :
        LET read == DecodeLegGroup(EncodeLegGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Series Request Acknowledgement Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexSeriesRequestAcknowledgementMessage ==
    \A message \in CheckedComplexSeriesRequestAcknowledgementMessage :
        LET read == DecodeComplexSeriesRequestAcknowledgementMessage(EncodeComplexSeriesRequestAcknowledgementMessage(message))
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

(* A Seq Msg Length is selected by the Seq Msg Length it is written under *)
SelectsSeqMsgLengthChoice ==
    \A message \in CheckedSeqMsgLengthChoice :
        LET sent == EncodeSeqMsgLengthChoice(message)
            read == DecodeSeqMsgLengthChoice(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Seq Msg Length is selected by the Seq Msg Length it is written under *)
SelectsSeqMsgLengthChoice2 ==
    \A message \in CheckedSeqMsgLengthChoice2 :
        LET sent == EncodeSeqMsgLengthChoice2(message)
            read == DecodeSeqMsgLengthChoice2(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Server Sequenced Message is selected by the Seq Msg Type it is written under *)
SelectsServerSequencedMessage ==
    \A message \in CheckedServerSequencedMessage :
        LET sent == EncodeServerSequencedMessage(message)
            read == DecodeServerSequencedMessage(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

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
