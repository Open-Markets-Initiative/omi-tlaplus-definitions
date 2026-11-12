------- MODULE NyseEquities_BinaryGateway_v5_17_ServerPillarMessage --------
(***************************************************************************)
(* New York Stock Exchange Binary Gateway v5.17                            *)
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
(* Note: Equities Symbol Reference Data Message is as wide as Seq Msg      *)
(* Length says, which is the frame it is read from.                        *)
(*                                                                         *)
(* Note: Dmm Symbol Reference Data Message is as wide as Seq Msg Length    *)
(* says, which is the frame it is read from.                               *)
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
(* Note: Mmid Configuration Message is as wide as Seq Msg Length says,     *)
(* which is the frame it is read from.                                     *)
(*                                                                         *)
(* Note: Session Configuration Acknowledgement Message is as wide as Seq   *)
(* Msg Length says, which is the frame it is read from.                    *)
(*                                                                         *)
(* Note: Seq Msg Length frames this record, so it is as long as what the   *)
(* record holds: 102 carries none of them, and each of the others states   *)
(* its own length.                                                         *)
(*                                                                         *)
(* Note: Order And Cancel Replace Acknowledgement Message is as wide as    *)
(* Seq Msg Length says, which is the frame it is read from.                *)
(*                                                                         *)
(* Note: Order Modify Cancel Request Acknowledgment And Urout Message is   *)
(* as wide as Seq Msg Length says, which is the frame it is read from.     *)
(*                                                                         *)
(* Note: Order Priority Update Acknowledgment Message is as wide as Seq    *)
(* Msg Length says, which is the frame it is read from.                    *)
(*                                                                         *)
(* Note: Seq Msg Length frames this record, so it is as long as what the   *)
(* record holds: 84 carries none of them, and each of the others states    *)
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
(* Note: Symbol Subscription Acknowledgement Message is as wide as Seq Msg *)
(* Length says, which is the frame it is read from.                        *)
(*                                                                         *)
(* Note: Gt Begin Message is as wide as Seq Msg Length says, which is the  *)
(* frame it is read from.                                                  *)
(*                                                                         *)
(* Note: Gt End Message is as wide as Seq Msg Length says, which is the    *)
(* frame it is read from.                                                  *)
(*                                                                         *)
(* Note: Auction Price Data Message is as wide as Seq Msg Length says,     *)
(* which is the frame it is read from.                                     *)
(*                                                                         *)
(* Note: Auction Request Message is as wide as Seq Msg Length says, which  *)
(* is the frame it is read from.                                           *)
(*                                                                         *)
(* Note: Manual Action Request Message is as wide as Seq Msg Length says,  *)
(* which is the frame it is read from.                                     *)
(*                                                                         *)
(* Note: Risk Control Acknowledgement Message is as wide as Seq Msg Length *)
(* says, which is the frame it is read from.                               *)
(*                                                                         *)
(* Note: Risk Control Alert Message is as wide as Seq Msg Length says,     *)
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
(* Equities Symbol Reference Data Message: 52 bytes                        *)
(***************************************************************************)

EquitiesSymbolReferenceDataMessage ==
    [ transactTime        : Sample(8),
      symbolId            : Sample(4),
      nyseSymbol          : Sample(24),
      listedMic           : Sample(4),
      roundLotSize        : Sample(1),
      advRiskRangeId      : Sample(1),
      reserved7           : Sample(7),
      mpvClassId          : Sample(2),
      testSymbolIndicator : Sample(1) ]

EncodeEquitiesSymbolReferenceDataMessage(message) ==
    message.transactTime
        \o message.symbolId
        \o message.nyseSymbol
        \o message.listedMic
        \o message.roundLotSize
        \o message.advRiskRangeId
        \o message.reserved7
        \o message.mpvClassId
        \o message.testSymbolIndicator

DecodeEquitiesSymbolReferenceDataMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET symbolId == ReadBytes(transactTime.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET nyseSymbol == ReadBytes(symbolId.rest, 24) IN IF ~nyseSymbol.ok THEN Fail ELSE
    LET listedMic == ReadBytes(nyseSymbol.rest, 4) IN IF ~listedMic.ok THEN Fail ELSE
    LET roundLotSize == ReadBytes(listedMic.rest, 1) IN IF ~roundLotSize.ok THEN Fail ELSE
    LET advRiskRangeId == ReadBytes(roundLotSize.rest, 1) IN IF ~advRiskRangeId.ok THEN Fail ELSE
    LET reserved7 == ReadBytes(advRiskRangeId.rest, 7) IN IF ~reserved7.ok THEN Fail ELSE
    LET mpvClassId == ReadBytes(reserved7.rest, 2) IN IF ~mpvClassId.ok THEN Fail ELSE
    LET testSymbolIndicator == ReadBytes(mpvClassId.rest, 1) IN IF ~testSymbolIndicator.ok THEN Fail ELSE
    Ok([ transactTime        |-> transactTime.value,
         symbolId            |-> symbolId.value,
         nyseSymbol          |-> nyseSymbol.value,
         listedMic           |-> listedMic.value,
         roundLotSize        |-> roundLotSize.value,
         advRiskRangeId      |-> advRiskRangeId.value,
         reserved7           |-> reserved7.value,
         mpvClassId          |-> mpvClassId.value,
         testSymbolIndicator |-> testSymbolIndicator.value ], testSymbolIndicator.rest)

ZeroEquitiesSymbolReferenceDataMessage ==
    [ transactTime        |-> [i \in 1 .. 8 |-> 0],
      symbolId            |-> [i \in 1 .. 4 |-> 0],
      nyseSymbol          |-> [i \in 1 .. 24 |-> 0],
      listedMic           |-> [i \in 1 .. 4 |-> 0],
      roundLotSize        |-> [i \in 1 .. 1 |-> 0],
      advRiskRangeId      |-> [i \in 1 .. 1 |-> 0],
      reserved7           |-> [i \in 1 .. 7 |-> 0],
      mpvClassId          |-> [i \in 1 .. 2 |-> 0],
      testSymbolIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Equities Symbol Reference Data Message at zero, then each field in turn at the values it is checked at *)
CheckedEquitiesSymbolReferenceDataMessage ==
    { ZeroEquitiesSymbolReferenceDataMessage }
        \cup { [ZeroEquitiesSymbolReferenceDataMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroEquitiesSymbolReferenceDataMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroEquitiesSymbolReferenceDataMessage EXCEPT !.nyseSymbol = one] : one \in Sample(24) }
        \cup { [ZeroEquitiesSymbolReferenceDataMessage EXCEPT !.listedMic = one] : one \in Sample(4) }
        \cup { [ZeroEquitiesSymbolReferenceDataMessage EXCEPT !.roundLotSize = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesSymbolReferenceDataMessage EXCEPT !.advRiskRangeId = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesSymbolReferenceDataMessage EXCEPT !.reserved7 = one] : one \in Sample(7) }
        \cup { [ZeroEquitiesSymbolReferenceDataMessage EXCEPT !.mpvClassId = one] : one \in Sample(2) }
        \cup { [ZeroEquitiesSymbolReferenceDataMessage EXCEPT !.testSymbolIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Dmm Symbol Reference Data Message: 125 bytes                            *)
(***************************************************************************)

DmmSymbolReferenceDataMessage ==
    [ transactTime       : Sample(8),
      symbolId           : Sample(4),
      nyseSymbol         : Sample(24),
      book               : Sample(8),
      mpid               : Sample(4),
      dmmUnitNum         : Sample(3),
      post               : Sample(2),
      medianVolume       : Sample(8),
      rdSeq              : Sample(8),
      ridgePrice         : Sample(8),
      ppp1               : Sample(8),
      ppp2               : Sample(8),
      ppp3               : Sample(8),
      openOnTradeMaxQty  : Sample(8),
      closeOnTradeMaxQty : Sample(8),
      lmocp              : Sample(8) ]

EncodeDmmSymbolReferenceDataMessage(message) ==
    message.transactTime
        \o message.symbolId
        \o message.nyseSymbol
        \o message.book
        \o message.mpid
        \o message.dmmUnitNum
        \o message.post
        \o message.medianVolume
        \o message.rdSeq
        \o message.ridgePrice
        \o message.ppp1
        \o message.ppp2
        \o message.ppp3
        \o message.openOnTradeMaxQty
        \o message.closeOnTradeMaxQty
        \o message.lmocp

DecodeDmmSymbolReferenceDataMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET symbolId == ReadBytes(transactTime.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET nyseSymbol == ReadBytes(symbolId.rest, 24) IN IF ~nyseSymbol.ok THEN Fail ELSE
    LET book == ReadBytes(nyseSymbol.rest, 8) IN IF ~book.ok THEN Fail ELSE
    LET mpid == ReadBytes(book.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET dmmUnitNum == ReadBytes(mpid.rest, 3) IN IF ~dmmUnitNum.ok THEN Fail ELSE
    LET post == ReadBytes(dmmUnitNum.rest, 2) IN IF ~post.ok THEN Fail ELSE
    LET medianVolume == ReadBytes(post.rest, 8) IN IF ~medianVolume.ok THEN Fail ELSE
    LET rdSeq == ReadBytes(medianVolume.rest, 8) IN IF ~rdSeq.ok THEN Fail ELSE
    LET ridgePrice == ReadBytes(rdSeq.rest, 8) IN IF ~ridgePrice.ok THEN Fail ELSE
    LET ppp1 == ReadBytes(ridgePrice.rest, 8) IN IF ~ppp1.ok THEN Fail ELSE
    LET ppp2 == ReadBytes(ppp1.rest, 8) IN IF ~ppp2.ok THEN Fail ELSE
    LET ppp3 == ReadBytes(ppp2.rest, 8) IN IF ~ppp3.ok THEN Fail ELSE
    LET openOnTradeMaxQty == ReadBytes(ppp3.rest, 8) IN IF ~openOnTradeMaxQty.ok THEN Fail ELSE
    LET closeOnTradeMaxQty == ReadBytes(openOnTradeMaxQty.rest, 8) IN IF ~closeOnTradeMaxQty.ok THEN Fail ELSE
    LET lmocp == ReadBytes(closeOnTradeMaxQty.rest, 8) IN IF ~lmocp.ok THEN Fail ELSE
    Ok([ transactTime       |-> transactTime.value,
         symbolId           |-> symbolId.value,
         nyseSymbol         |-> nyseSymbol.value,
         book               |-> book.value,
         mpid               |-> mpid.value,
         dmmUnitNum         |-> dmmUnitNum.value,
         post               |-> post.value,
         medianVolume       |-> medianVolume.value,
         rdSeq              |-> rdSeq.value,
         ridgePrice         |-> ridgePrice.value,
         ppp1               |-> ppp1.value,
         ppp2               |-> ppp2.value,
         ppp3               |-> ppp3.value,
         openOnTradeMaxQty  |-> openOnTradeMaxQty.value,
         closeOnTradeMaxQty |-> closeOnTradeMaxQty.value,
         lmocp              |-> lmocp.value ], lmocp.rest)

ZeroDmmSymbolReferenceDataMessage ==
    [ transactTime       |-> [i \in 1 .. 8 |-> 0],
      symbolId           |-> [i \in 1 .. 4 |-> 0],
      nyseSymbol         |-> [i \in 1 .. 24 |-> 0],
      book               |-> [i \in 1 .. 8 |-> 0],
      mpid               |-> [i \in 1 .. 4 |-> 0],
      dmmUnitNum         |-> [i \in 1 .. 3 |-> 0],
      post               |-> [i \in 1 .. 2 |-> 0],
      medianVolume       |-> [i \in 1 .. 8 |-> 0],
      rdSeq              |-> [i \in 1 .. 8 |-> 0],
      ridgePrice         |-> [i \in 1 .. 8 |-> 0],
      ppp1               |-> [i \in 1 .. 8 |-> 0],
      ppp2               |-> [i \in 1 .. 8 |-> 0],
      ppp3               |-> [i \in 1 .. 8 |-> 0],
      openOnTradeMaxQty  |-> [i \in 1 .. 8 |-> 0],
      closeOnTradeMaxQty |-> [i \in 1 .. 8 |-> 0],
      lmocp              |-> [i \in 1 .. 8 |-> 0] ]

(* Dmm Symbol Reference Data Message at zero, then each field in turn at the values it is checked at *)
CheckedDmmSymbolReferenceDataMessage ==
    { ZeroDmmSymbolReferenceDataMessage }
        \cup { [ZeroDmmSymbolReferenceDataMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroDmmSymbolReferenceDataMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroDmmSymbolReferenceDataMessage EXCEPT !.nyseSymbol = one] : one \in Sample(24) }
        \cup { [ZeroDmmSymbolReferenceDataMessage EXCEPT !.book = one] : one \in Sample(8) }
        \cup { [ZeroDmmSymbolReferenceDataMessage EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroDmmSymbolReferenceDataMessage EXCEPT !.dmmUnitNum = one] : one \in Sample(3) }
        \cup { [ZeroDmmSymbolReferenceDataMessage EXCEPT !.post = one] : one \in Sample(2) }
        \cup { [ZeroDmmSymbolReferenceDataMessage EXCEPT !.medianVolume = one] : one \in Sample(8) }
        \cup { [ZeroDmmSymbolReferenceDataMessage EXCEPT !.rdSeq = one] : one \in Sample(8) }
        \cup { [ZeroDmmSymbolReferenceDataMessage EXCEPT !.ridgePrice = one] : one \in Sample(8) }
        \cup { [ZeroDmmSymbolReferenceDataMessage EXCEPT !.ppp1 = one] : one \in Sample(8) }
        \cup { [ZeroDmmSymbolReferenceDataMessage EXCEPT !.ppp2 = one] : one \in Sample(8) }
        \cup { [ZeroDmmSymbolReferenceDataMessage EXCEPT !.ppp3 = one] : one \in Sample(8) }
        \cup { [ZeroDmmSymbolReferenceDataMessage EXCEPT !.openOnTradeMaxQty = one] : one \in Sample(8) }
        \cup { [ZeroDmmSymbolReferenceDataMessage EXCEPT !.closeOnTradeMaxQty = one] : one \in Sample(8) }
        \cup { [ZeroDmmSymbolReferenceDataMessage EXCEPT !.lmocp = one] : one \in Sample(8) }

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
    [ mpvLevelName : Sample(24),
      price        : Sample(8),
      quotingMpv   : Sample(8),
      tradingMpv   : Sample(8),
      mpvClassId   : Sample(2) ]

EncodeMpvLevelDefinition(message) ==
    message.mpvLevelName
        \o message.price
        \o message.quotingMpv
        \o message.tradingMpv
        \o message.mpvClassId

DecodeMpvLevelDefinition(bytes) ==
    LET mpvLevelName == ReadBytes(bytes, 24) IN IF ~mpvLevelName.ok THEN Fail ELSE
    LET price == ReadBytes(mpvLevelName.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quotingMpv == ReadBytes(price.rest, 8) IN IF ~quotingMpv.ok THEN Fail ELSE
    LET tradingMpv == ReadBytes(quotingMpv.rest, 8) IN IF ~tradingMpv.ok THEN Fail ELSE
    LET mpvClassId == ReadBytes(tradingMpv.rest, 2) IN IF ~mpvClassId.ok THEN Fail ELSE
    Ok([ mpvLevelName |-> mpvLevelName.value,
         price        |-> price.value,
         quotingMpv   |-> quotingMpv.value,
         tradingMpv   |-> tradingMpv.value,
         mpvClassId   |-> mpvClassId.value ], mpvClassId.rest)

ZeroMpvLevelDefinition ==
    [ mpvLevelName |-> [i \in 1 .. 24 |-> 0],
      price        |-> [i \in 1 .. 8 |-> 0],
      quotingMpv   |-> [i \in 1 .. 8 |-> 0],
      tradingMpv   |-> [i \in 1 .. 8 |-> 0],
      mpvClassId   |-> [i \in 1 .. 2 |-> 0] ]

(* Mpv Level Definition at zero, then each field in turn at the values it is checked at *)
CheckedMpvLevelDefinition ==
    { ZeroMpvLevelDefinition }
        \cup { [ZeroMpvLevelDefinition EXCEPT !.mpvLevelName = one] : one \in Sample(24) }
        \cup { [ZeroMpvLevelDefinition EXCEPT !.price = one] : one \in Sample(8) }
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
(* Mmid Configuration Message: 138 bytes                                   *)
(***************************************************************************)

MmidConfigurationMessage ==
    [ transactTime : Sample(8),
      marketMaker  : Sample(10),
      mmid         : Sample(4),
      username     : Sample(16),
      reserved100  : Sample(100) ]

EncodeMmidConfigurationMessage(message) ==
    message.transactTime
        \o message.marketMaker
        \o message.mmid
        \o message.username
        \o message.reserved100

DecodeMmidConfigurationMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET marketMaker == ReadBytes(transactTime.rest, 10) IN IF ~marketMaker.ok THEN Fail ELSE
    LET mmid == ReadBytes(marketMaker.rest, 4) IN IF ~mmid.ok THEN Fail ELSE
    LET username == ReadBytes(mmid.rest, 16) IN IF ~username.ok THEN Fail ELSE
    LET reserved100 == ReadBytes(username.rest, 100) IN IF ~reserved100.ok THEN Fail ELSE
    Ok([ transactTime |-> transactTime.value,
         marketMaker  |-> marketMaker.value,
         mmid         |-> mmid.value,
         username     |-> username.value,
         reserved100  |-> reserved100.value ], reserved100.rest)

ZeroMmidConfigurationMessage ==
    [ transactTime |-> [i \in 1 .. 8 |-> 0],
      marketMaker  |-> [i \in 1 .. 10 |-> 0],
      mmid         |-> [i \in 1 .. 4 |-> 0],
      username     |-> [i \in 1 .. 16 |-> 0],
      reserved100  |-> [i \in 1 .. 100 |-> 0] ]

(* Mmid Configuration Message at zero, then each field in turn at the values it is checked at *)
CheckedMmidConfigurationMessage ==
    { ZeroMmidConfigurationMessage }
        \cup { [ZeroMmidConfigurationMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroMmidConfigurationMessage EXCEPT !.marketMaker = one] : one \in Sample(10) }
        \cup { [ZeroMmidConfigurationMessage EXCEPT !.mmid = one] : one \in Sample(4) }
        \cup { [ZeroMmidConfigurationMessage EXCEPT !.username = one] : one \in Sample(16) }
        \cup { [ZeroMmidConfigurationMessage EXCEPT !.reserved100 = one] : one \in Sample(100) }

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

OptionalOrderAddOnCode == 143  \* 0x8f
OptionalRoutingStrategyAddOnCode == 134  \* 0x86
OptionalSettlementTypeAddOnCode == 107  \* 0x6b
SeqMsgLengthNoneCode == 102  \* 

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
(* Order And Cancel Replace Acknowledgement Message                        *)
(***************************************************************************)

OrderAndCancelReplaceAcknowledgementMessage ==
    [ transactTime              : Sample(8),
      symbolId                  : Sample(4),
      mpid                      : Sample(4),
      mmid                      : Sample(4),
      mpsubid1                  : Sample(1),
      clOrdId                   : Sample(8),
      origClOrdId               : Sample(8),
      bitfieldOrderInstructions : Sample(8),
      price                     : Sample(8),
      orderQty                  : Sample(4),
      minQty                    : Sample(4),
      orderId                   : Sample(8),
      leavesQty                 : Sample(4),
      workingPrice              : Sample(8),
      workingAwayFromDisplay    : Sample(1),
      preLiquidityIndicator     : Sample(4),
      reasonCode                : Sample(2),
      ackType                   : Sample(1),
      bitfieldFlowIndicator     : Sample(1),
      userData                  : Sample(8),
      seqMsgLengthChoice        : SeqMsgLengthChoice ]

EncodeOrderAndCancelReplaceAcknowledgementMessage(message) ==
    message.transactTime
        \o message.symbolId
        \o message.mpid
        \o message.mmid
        \o message.mpsubid1
        \o message.clOrdId
        \o message.origClOrdId
        \o message.bitfieldOrderInstructions
        \o message.price
        \o message.orderQty
        \o message.minQty
        \o message.orderId
        \o message.leavesQty
        \o message.workingPrice
        \o message.workingAwayFromDisplay
        \o message.preLiquidityIndicator
        \o message.reasonCode
        \o message.ackType
        \o message.bitfieldFlowIndicator
        \o message.userData
        \o EncodeSeqMsgLengthChoice(message.seqMsgLengthChoice)

DecodeOrderAndCancelReplaceAcknowledgementMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET symbolId == ReadBytes(transactTime.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET mpid == ReadBytes(symbolId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET mmid == ReadBytes(mpid.rest, 4) IN IF ~mmid.ok THEN Fail ELSE
    LET mpsubid1 == ReadBytes(mmid.rest, 1) IN IF ~mpsubid1.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(mpsubid1.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET bitfieldOrderInstructions == ReadBytes(origClOrdId.rest, 8) IN IF ~bitfieldOrderInstructions.ok THEN Fail ELSE
    LET price == ReadBytes(bitfieldOrderInstructions.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderQty == ReadBytes(price.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET minQty == ReadBytes(orderQty.rest, 4) IN IF ~minQty.ok THEN Fail ELSE
    LET orderId == ReadBytes(minQty.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(orderId.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET workingPrice == ReadBytes(leavesQty.rest, 8) IN IF ~workingPrice.ok THEN Fail ELSE
    LET workingAwayFromDisplay == ReadBytes(workingPrice.rest, 1) IN IF ~workingAwayFromDisplay.ok THEN Fail ELSE
    LET preLiquidityIndicator == ReadBytes(workingAwayFromDisplay.rest, 4) IN IF ~preLiquidityIndicator.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(preLiquidityIndicator.rest, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET ackType == ReadBytes(reasonCode.rest, 1) IN IF ~ackType.ok THEN Fail ELSE
    LET bitfieldFlowIndicator == ReadBytes(ackType.rest, 1) IN IF ~bitfieldFlowIndicator.ok THEN Fail ELSE
    LET userData == ReadBytes(bitfieldFlowIndicator.rest, 8) IN IF ~userData.ok THEN Fail ELSE
    LET seqMsgLengthChoice == DecodeSeqMsgLengthChoice(Len(bytes) + 4, userData.rest) IN IF ~seqMsgLengthChoice.ok THEN Fail ELSE
    Ok([ transactTime              |-> transactTime.value,
         symbolId                  |-> symbolId.value,
         mpid                      |-> mpid.value,
         mmid                      |-> mmid.value,
         mpsubid1                  |-> mpsubid1.value,
         clOrdId                   |-> clOrdId.value,
         origClOrdId               |-> origClOrdId.value,
         bitfieldOrderInstructions |-> bitfieldOrderInstructions.value,
         price                     |-> price.value,
         orderQty                  |-> orderQty.value,
         minQty                    |-> minQty.value,
         orderId                   |-> orderId.value,
         leavesQty                 |-> leavesQty.value,
         workingPrice              |-> workingPrice.value,
         workingAwayFromDisplay    |-> workingAwayFromDisplay.value,
         preLiquidityIndicator     |-> preLiquidityIndicator.value,
         reasonCode                |-> reasonCode.value,
         ackType                   |-> ackType.value,
         bitfieldFlowIndicator     |-> bitfieldFlowIndicator.value,
         userData                  |-> userData.value,
         seqMsgLengthChoice        |-> seqMsgLengthChoice.value ], seqMsgLengthChoice.rest)

ZeroOrderAndCancelReplaceAcknowledgementMessage ==
    [ transactTime              |-> [i \in 1 .. 8 |-> 0],
      symbolId                  |-> [i \in 1 .. 4 |-> 0],
      mpid                      |-> [i \in 1 .. 4 |-> 0],
      mmid                      |-> [i \in 1 .. 4 |-> 0],
      mpsubid1                  |-> [i \in 1 .. 1 |-> 0],
      clOrdId                   |-> [i \in 1 .. 8 |-> 0],
      origClOrdId               |-> [i \in 1 .. 8 |-> 0],
      bitfieldOrderInstructions |-> [i \in 1 .. 8 |-> 0],
      price                     |-> [i \in 1 .. 8 |-> 0],
      orderQty                  |-> [i \in 1 .. 4 |-> 0],
      minQty                    |-> [i \in 1 .. 4 |-> 0],
      orderId                   |-> [i \in 1 .. 8 |-> 0],
      leavesQty                 |-> [i \in 1 .. 4 |-> 0],
      workingPrice              |-> [i \in 1 .. 8 |-> 0],
      workingAwayFromDisplay    |-> [i \in 1 .. 1 |-> 0],
      preLiquidityIndicator     |-> [i \in 1 .. 4 |-> 0],
      reasonCode                |-> [i \in 1 .. 2 |-> 0],
      ackType                   |-> [i \in 1 .. 1 |-> 0],
      bitfieldFlowIndicator     |-> [i \in 1 .. 1 |-> 0],
      userData                  |-> [i \in 1 .. 8 |-> 0],
      seqMsgLengthChoice        |-> ZeroSeqMsgLengthChoice ]

(* Order And Cancel Replace Acknowledgement Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderAndCancelReplaceAcknowledgementMessage ==
    { ZeroOrderAndCancelReplaceAcknowledgementMessage }
        \cup { [ZeroOrderAndCancelReplaceAcknowledgementMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderAndCancelReplaceAcknowledgementMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroOrderAndCancelReplaceAcknowledgementMessage EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroOrderAndCancelReplaceAcknowledgementMessage EXCEPT !.mmid = one] : one \in Sample(4) }
        \cup { [ZeroOrderAndCancelReplaceAcknowledgementMessage EXCEPT !.mpsubid1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderAndCancelReplaceAcknowledgementMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderAndCancelReplaceAcknowledgementMessage EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderAndCancelReplaceAcknowledgementMessage EXCEPT !.bitfieldOrderInstructions = one] : one \in Sample(8) }
        \cup { [ZeroOrderAndCancelReplaceAcknowledgementMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderAndCancelReplaceAcknowledgementMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderAndCancelReplaceAcknowledgementMessage EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderAndCancelReplaceAcknowledgementMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderAndCancelReplaceAcknowledgementMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderAndCancelReplaceAcknowledgementMessage EXCEPT !.workingPrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderAndCancelReplaceAcknowledgementMessage EXCEPT !.workingAwayFromDisplay = one] : one \in Sample(1) }
        \cup { [ZeroOrderAndCancelReplaceAcknowledgementMessage EXCEPT !.preLiquidityIndicator = one] : one \in Sample(4) }
        \cup { [ZeroOrderAndCancelReplaceAcknowledgementMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroOrderAndCancelReplaceAcknowledgementMessage EXCEPT !.ackType = one] : one \in Sample(1) }
        \cup { [ZeroOrderAndCancelReplaceAcknowledgementMessage EXCEPT !.bitfieldFlowIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderAndCancelReplaceAcknowledgementMessage EXCEPT !.userData = one] : one \in Sample(8) }
        \cup { [ZeroOrderAndCancelReplaceAcknowledgementMessage EXCEPT !.seqMsgLengthChoice = one] : one \in CheckedSeqMsgLengthChoice }

(***************************************************************************)
(* Order Modify Cancel Request Acknowledgment And Urout Message: 70 bytes  *)
(***************************************************************************)

OrderModifyCancelRequestAcknowledgmentAndUroutMessage ==
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
      locateReqdU81         : Sample(1),
      reasonCode            : Sample(2),
      ackType               : Sample(1),
      bitfieldFlowIndicator : Sample(1),
      userData              : Sample(8) ]

EncodeOrderModifyCancelRequestAcknowledgmentAndUroutMessage(message) ==
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
        \o message.locateReqdU81
        \o message.reasonCode
        \o message.ackType
        \o message.bitfieldFlowIndicator
        \o message.userData

DecodeOrderModifyCancelRequestAcknowledgmentAndUroutMessage(bytes) ==
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
    LET locateReqdU81 == ReadBytes(side.rest, 1) IN IF ~locateReqdU81.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(locateReqdU81.rest, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET ackType == ReadBytes(reasonCode.rest, 1) IN IF ~ackType.ok THEN Fail ELSE
    LET bitfieldFlowIndicator == ReadBytes(ackType.rest, 1) IN IF ~bitfieldFlowIndicator.ok THEN Fail ELSE
    LET userData == ReadBytes(bitfieldFlowIndicator.rest, 8) IN IF ~userData.ok THEN Fail ELSE
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
         locateReqdU81         |-> locateReqdU81.value,
         reasonCode            |-> reasonCode.value,
         ackType               |-> ackType.value,
         bitfieldFlowIndicator |-> bitfieldFlowIndicator.value,
         userData              |-> userData.value ], userData.rest)

ZeroOrderModifyCancelRequestAcknowledgmentAndUroutMessage ==
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
      locateReqdU81         |-> [i \in 1 .. 1 |-> 0],
      reasonCode            |-> [i \in 1 .. 2 |-> 0],
      ackType               |-> [i \in 1 .. 1 |-> 0],
      bitfieldFlowIndicator |-> [i \in 1 .. 1 |-> 0],
      userData              |-> [i \in 1 .. 8 |-> 0] ]

(* Order Modify Cancel Request Acknowledgment And Urout Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderModifyCancelRequestAcknowledgmentAndUroutMessage ==
    { ZeroOrderModifyCancelRequestAcknowledgmentAndUroutMessage }
        \cup { [ZeroOrderModifyCancelRequestAcknowledgmentAndUroutMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyCancelRequestAcknowledgmentAndUroutMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyCancelRequestAcknowledgmentAndUroutMessage EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyCancelRequestAcknowledgmentAndUroutMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyCancelRequestAcknowledgmentAndUroutMessage EXCEPT !.refClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyCancelRequestAcknowledgmentAndUroutMessage EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyCancelRequestAcknowledgmentAndUroutMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyCancelRequestAcknowledgmentAndUroutMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyCancelRequestAcknowledgmentAndUroutMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyCancelRequestAcknowledgmentAndUroutMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifyCancelRequestAcknowledgmentAndUroutMessage EXCEPT !.locateReqdU81 = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifyCancelRequestAcknowledgmentAndUroutMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroOrderModifyCancelRequestAcknowledgmentAndUroutMessage EXCEPT !.ackType = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifyCancelRequestAcknowledgmentAndUroutMessage EXCEPT !.bitfieldFlowIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifyCancelRequestAcknowledgmentAndUroutMessage EXCEPT !.userData = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Priority Update Acknowledgment Message: 58 bytes                  *)
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
      userData               : Sample(8) ]

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
    LET userData == ReadBytes(ackType.rest, 8) IN IF ~userData.ok THEN Fail ELSE
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
      userData               |-> [i \in 1 .. 8 |-> 0] ]

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
        \cup { [ZeroOrderPriorityUpdateAcknowledgmentMessage EXCEPT !.userData = one] : one \in Sample(8) }

(***************************************************************************)
(* Sub Msg Header: 4 bytes                                                 *)
(***************************************************************************)

SubMsgHeader4 ==
    [ subMsgType   : Sample(2),
      subMsgLength : Sample(2) ]

EncodeSubMsgHeader4(message) ==
    message.subMsgType
        \o message.subMsgLength

DecodeSubMsgHeader4(bytes) ==
    LET subMsgType == ReadBytes(bytes, 2) IN IF ~subMsgType.ok THEN Fail ELSE
    LET subMsgLength == ReadBytes(subMsgType.rest, 2) IN IF ~subMsgLength.ok THEN Fail ELSE
    Ok([ subMsgType   |-> subMsgType.value,
         subMsgLength |-> subMsgLength.value ], subMsgLength.rest)

ZeroSubMsgHeader4 ==
    [ subMsgType   |-> [i \in 1 .. 2 |-> 0],
      subMsgLength |-> [i \in 1 .. 2 |-> 0] ]

(* Sub Msg Header at zero, then each field in turn at the values it is checked at *)
CheckedSubMsgHeader4 ==
    { ZeroSubMsgHeader4 }
        \cup { [ZeroSubMsgHeader4 EXCEPT !.subMsgType = one] : one \in Sample(2) }
        \cup { [ZeroSubMsgHeader4 EXCEPT !.subMsgLength = one] : one \in Sample(2) }

(***************************************************************************)
(* Optional Settlement Type Add On: 5 bytes                                *)
(***************************************************************************)

OptionalSettlementTypeAddOn2 ==
    [ subMsgHeader   : SubMsgHeader4,
      settlementType : Sample(1) ]

EncodeOptionalSettlementTypeAddOn2(message) ==
    EncodeSubMsgHeader4(message.subMsgHeader)
        \o message.settlementType

DecodeOptionalSettlementTypeAddOn2(bytes) ==
    LET subMsgHeader == DecodeSubMsgHeader4(bytes) IN IF ~subMsgHeader.ok THEN Fail ELSE
    LET settlementType == ReadBytes(subMsgHeader.rest, 1) IN IF ~settlementType.ok THEN Fail ELSE
    Ok([ subMsgHeader   |-> subMsgHeader.value,
         settlementType |-> settlementType.value ], settlementType.rest)

ZeroOptionalSettlementTypeAddOn2 ==
    [ subMsgHeader   |-> ZeroSubMsgHeader4,
      settlementType |-> [i \in 1 .. 1 |-> 0] ]

(* Optional Settlement Type Add On at zero, then each field in turn at the values it is checked at *)
CheckedOptionalSettlementTypeAddOn2 ==
    { ZeroOptionalSettlementTypeAddOn2 }
        \cup { [ZeroOptionalSettlementTypeAddOn2 EXCEPT !.subMsgHeader = one] : one \in CheckedSubMsgHeader4 }
        \cup { [ZeroOptionalSettlementTypeAddOn2 EXCEPT !.settlementType = one] : one \in Sample(1) }

(***************************************************************************)
(* What Seq Msg Length decides is present                                  *)
(***************************************************************************)

OptionalSettlementTypeAddOnCode2 == 89  \* 0x59
SeqMsgLengthNoneCode2 == 84  \* 

SeqMsgLengthChoice2 ==
    [ tag : {OptionalSettlementTypeAddOnCode2}, body : OptionalSettlementTypeAddOn2 ]
        \cup [ tag : {SeqMsgLengthNoneCode2}, body : {[empty |-> 0]} ]

EncodeSeqMsgLengthChoice2(message) ==
    CASE message.tag = OptionalSettlementTypeAddOnCode2 -> EncodeOptionalSettlementTypeAddOn2(message.body)
      [] OTHER -> << >>

DecodeSeqMsgLengthChoice2(tag, bytes) ==
    LET read ==
            CASE tag = OptionalSettlementTypeAddOnCode2 -> DecodeOptionalSettlementTypeAddOn2(bytes)
              [] OTHER -> Ok([empty |-> 0], bytes)
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSeqMsgLengthChoice2 == [tag |-> OptionalSettlementTypeAddOnCode2, body |-> ZeroOptionalSettlementTypeAddOn2]

(* Each Seq Msg Length in turn, at the values the message it names is checked at *)
CheckedSeqMsgLengthChoice2 ==
    { [tag |-> OptionalSettlementTypeAddOnCode2, body |-> one] : one \in CheckedOptionalSettlementTypeAddOn2 }
        \cup { [tag |-> SeqMsgLengthNoneCode2, body |-> [empty |-> 0]] }

(***************************************************************************)
(* Execution Report Message                                                *)
(***************************************************************************)

ExecutionReportMessage ==
    [ transactTime                : Sample(8),
      symbolId                    : Sample(4),
      mpid                        : Sample(4),
      orderId                     : Sample(8),
      clOrdId                     : Sample(8),
      dealId                      : Sample(8),
      lastPx                      : Sample(8),
      leavesQty                   : Sample(4),
      cumQty                      : Sample(4),
      lastQty                     : Sample(4),
      liquidityIndicator          : Sample(4),
      displayedLiquidityIndicator : Sample(4),
      locateReqdU81               : Sample(1),
      participantType             : Sample(1),
      reasonCode                  : Sample(2),
      userData                    : Sample(8),
      seqMsgLengthChoice          : SeqMsgLengthChoice2 ]

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
        \o message.displayedLiquidityIndicator
        \o message.locateReqdU81
        \o message.participantType
        \o message.reasonCode
        \o message.userData
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
    LET displayedLiquidityIndicator == ReadBytes(liquidityIndicator.rest, 4) IN IF ~displayedLiquidityIndicator.ok THEN Fail ELSE
    LET locateReqdU81 == ReadBytes(displayedLiquidityIndicator.rest, 1) IN IF ~locateReqdU81.ok THEN Fail ELSE
    LET participantType == ReadBytes(locateReqdU81.rest, 1) IN IF ~participantType.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(participantType.rest, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET userData == ReadBytes(reasonCode.rest, 8) IN IF ~userData.ok THEN Fail ELSE
    LET seqMsgLengthChoice == DecodeSeqMsgLengthChoice2(Len(bytes) + 4, userData.rest) IN IF ~seqMsgLengthChoice.ok THEN Fail ELSE
    Ok([ transactTime                |-> transactTime.value,
         symbolId                    |-> symbolId.value,
         mpid                        |-> mpid.value,
         orderId                     |-> orderId.value,
         clOrdId                     |-> clOrdId.value,
         dealId                      |-> dealId.value,
         lastPx                      |-> lastPx.value,
         leavesQty                   |-> leavesQty.value,
         cumQty                      |-> cumQty.value,
         lastQty                     |-> lastQty.value,
         liquidityIndicator          |-> liquidityIndicator.value,
         displayedLiquidityIndicator |-> displayedLiquidityIndicator.value,
         locateReqdU81               |-> locateReqdU81.value,
         participantType             |-> participantType.value,
         reasonCode                  |-> reasonCode.value,
         userData                    |-> userData.value,
         seqMsgLengthChoice          |-> seqMsgLengthChoice.value ], seqMsgLengthChoice.rest)

ZeroExecutionReportMessage ==
    [ transactTime                |-> [i \in 1 .. 8 |-> 0],
      symbolId                    |-> [i \in 1 .. 4 |-> 0],
      mpid                        |-> [i \in 1 .. 4 |-> 0],
      orderId                     |-> [i \in 1 .. 8 |-> 0],
      clOrdId                     |-> [i \in 1 .. 8 |-> 0],
      dealId                      |-> [i \in 1 .. 8 |-> 0],
      lastPx                      |-> [i \in 1 .. 8 |-> 0],
      leavesQty                   |-> [i \in 1 .. 4 |-> 0],
      cumQty                      |-> [i \in 1 .. 4 |-> 0],
      lastQty                     |-> [i \in 1 .. 4 |-> 0],
      liquidityIndicator          |-> [i \in 1 .. 4 |-> 0],
      displayedLiquidityIndicator |-> [i \in 1 .. 4 |-> 0],
      locateReqdU81               |-> [i \in 1 .. 1 |-> 0],
      participantType             |-> [i \in 1 .. 1 |-> 0],
      reasonCode                  |-> [i \in 1 .. 2 |-> 0],
      userData                    |-> [i \in 1 .. 8 |-> 0],
      seqMsgLengthChoice          |-> ZeroSeqMsgLengthChoice2 ]

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
        \cup { [ZeroExecutionReportMessage EXCEPT !.displayedLiquidityIndicator = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.locateReqdU81 = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.participantType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.userData = one] : one \in Sample(8) }
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
(* Trade Bust Correct Message: 78 bytes                                    *)
(***************************************************************************)

TradeBustCorrectMessage ==
    [ transactTime : Sample(8),
      symbolId     : Sample(4),
      mpid         : Sample(4),
      orderId      : Sample(8),
      clOrdId      : Sample(8),
      refSeqMsgId  : RefSeqMsgId,
      dealId       : Sample(8),
      lastPx       : Sample(8),
      lastQty      : Sample(4),
      reasonCode   : Sample(2),
      userData     : Sample(8) ]

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
    LET userData == ReadBytes(reasonCode.rest, 8) IN IF ~userData.ok THEN Fail ELSE
    Ok([ transactTime |-> transactTime.value,
         symbolId     |-> symbolId.value,
         mpid         |-> mpid.value,
         orderId      |-> orderId.value,
         clOrdId      |-> clOrdId.value,
         refSeqMsgId  |-> refSeqMsgId.value,
         dealId       |-> dealId.value,
         lastPx       |-> lastPx.value,
         lastQty      |-> lastQty.value,
         reasonCode   |-> reasonCode.value,
         userData     |-> userData.value ], userData.rest)

ZeroTradeBustCorrectMessage ==
    [ transactTime |-> [i \in 1 .. 8 |-> 0],
      symbolId     |-> [i \in 1 .. 4 |-> 0],
      mpid         |-> [i \in 1 .. 4 |-> 0],
      orderId      |-> [i \in 1 .. 8 |-> 0],
      clOrdId      |-> [i \in 1 .. 8 |-> 0],
      refSeqMsgId  |-> ZeroRefSeqMsgId,
      dealId       |-> [i \in 1 .. 8 |-> 0],
      lastPx       |-> [i \in 1 .. 8 |-> 0],
      lastQty      |-> [i \in 1 .. 4 |-> 0],
      reasonCode   |-> [i \in 1 .. 2 |-> 0],
      userData     |-> [i \in 1 .. 8 |-> 0] ]

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
        \cup { [ZeroTradeBustCorrectMessage EXCEPT !.userData = one] : one \in Sample(8) }

(***************************************************************************)
(* Application Layer Reject Message: 39 bytes                              *)
(***************************************************************************)

ApplicationLayerRejectMessage ==
    [ transactTime : Sample(8),
      symbolId     : Sample(4),
      mpid         : Sample(4),
      clOrdId      : Sample(8),
      reasonCode   : Sample(2),
      rejectType   : Sample(1),
      userData     : Sample(8),
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
    LET userData == ReadBytes(rejectType.rest, 8) IN IF ~userData.ok THEN Fail ELSE
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
      userData     |-> [i \in 1 .. 8 |-> 0],
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
        \cup { [ZeroApplicationLayerRejectMessage EXCEPT !.userData = one] : one \in Sample(8) }
        \cup { [ZeroApplicationLayerRejectMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Symbol Subscription Acknowledgement Message: 29 bytes                   *)
(***************************************************************************)

SymbolSubscriptionAcknowledgementMessage ==
    [ transactTime       : Sample(8),
      symbolId           : Sample(4),
      username           : Sample(16),
      subscriptionStatus : Sample(1) ]

EncodeSymbolSubscriptionAcknowledgementMessage(message) ==
    message.transactTime
        \o message.symbolId
        \o message.username
        \o message.subscriptionStatus

DecodeSymbolSubscriptionAcknowledgementMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET symbolId == ReadBytes(transactTime.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET username == ReadBytes(symbolId.rest, 16) IN IF ~username.ok THEN Fail ELSE
    LET subscriptionStatus == ReadBytes(username.rest, 1) IN IF ~subscriptionStatus.ok THEN Fail ELSE
    Ok([ transactTime       |-> transactTime.value,
         symbolId           |-> symbolId.value,
         username           |-> username.value,
         subscriptionStatus |-> subscriptionStatus.value ], subscriptionStatus.rest)

ZeroSymbolSubscriptionAcknowledgementMessage ==
    [ transactTime       |-> [i \in 1 .. 8 |-> 0],
      symbolId           |-> [i \in 1 .. 4 |-> 0],
      username           |-> [i \in 1 .. 16 |-> 0],
      subscriptionStatus |-> [i \in 1 .. 1 |-> 0] ]

(* Symbol Subscription Acknowledgement Message at zero, then each field in turn at the values it is checked at *)
CheckedSymbolSubscriptionAcknowledgementMessage ==
    { ZeroSymbolSubscriptionAcknowledgementMessage }
        \cup { [ZeroSymbolSubscriptionAcknowledgementMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroSymbolSubscriptionAcknowledgementMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroSymbolSubscriptionAcknowledgementMessage EXCEPT !.username = one] : one \in Sample(16) }
        \cup { [ZeroSymbolSubscriptionAcknowledgementMessage EXCEPT !.subscriptionStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Gt Begin Message: 8 bytes                                               *)
(***************************************************************************)

GtBeginMessage ==
    [ transactTime : Sample(8) ]

EncodeGtBeginMessage(message) ==
    message.transactTime

DecodeGtBeginMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    Ok([ transactTime |-> transactTime.value ], transactTime.rest)

ZeroGtBeginMessage ==
    [ transactTime |-> [i \in 1 .. 8 |-> 0] ]

(* Gt Begin Message at zero, then each field in turn at the values it is checked at *)
CheckedGtBeginMessage ==
    { ZeroGtBeginMessage }
        \cup { [ZeroGtBeginMessage EXCEPT !.transactTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Gt End Message: 8 bytes                                                 *)
(***************************************************************************)

GtEndMessage ==
    [ transactTime : Sample(8) ]

EncodeGtEndMessage(message) ==
    message.transactTime

DecodeGtEndMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    Ok([ transactTime |-> transactTime.value ], transactTime.rest)

ZeroGtEndMessage ==
    [ transactTime |-> [i \in 1 .. 8 |-> 0] ]

(* Gt End Message at zero, then each field in turn at the values it is checked at *)
CheckedGtEndMessage ==
    { ZeroGtEndMessage }
        \cup { [ZeroGtEndMessage EXCEPT !.transactTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Auction Price Data Message: 42 bytes                                    *)
(***************************************************************************)

AuctionPriceDataMessage ==
    [ transactTime        : Sample(8),
      symbolId            : Sample(4),
      imbalanceSide       : Sample(1),
      sideOfUnpairedQty   : Sample(1),
      imbalanceVolume     : Sample(4),
      price               : Sample(8),
      pairedQty           : Sample(4),
      unpairedQty         : Sample(4),
      buyDmmAvailableQty  : Sample(4),
      sellDmmAvailableQty : Sample(4) ]

EncodeAuctionPriceDataMessage(message) ==
    message.transactTime
        \o message.symbolId
        \o message.imbalanceSide
        \o message.sideOfUnpairedQty
        \o message.imbalanceVolume
        \o message.price
        \o message.pairedQty
        \o message.unpairedQty
        \o message.buyDmmAvailableQty
        \o message.sellDmmAvailableQty

DecodeAuctionPriceDataMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET symbolId == ReadBytes(transactTime.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET imbalanceSide == ReadBytes(symbolId.rest, 1) IN IF ~imbalanceSide.ok THEN Fail ELSE
    LET sideOfUnpairedQty == ReadBytes(imbalanceSide.rest, 1) IN IF ~sideOfUnpairedQty.ok THEN Fail ELSE
    LET imbalanceVolume == ReadBytes(sideOfUnpairedQty.rest, 4) IN IF ~imbalanceVolume.ok THEN Fail ELSE
    LET price == ReadBytes(imbalanceVolume.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET pairedQty == ReadBytes(price.rest, 4) IN IF ~pairedQty.ok THEN Fail ELSE
    LET unpairedQty == ReadBytes(pairedQty.rest, 4) IN IF ~unpairedQty.ok THEN Fail ELSE
    LET buyDmmAvailableQty == ReadBytes(unpairedQty.rest, 4) IN IF ~buyDmmAvailableQty.ok THEN Fail ELSE
    LET sellDmmAvailableQty == ReadBytes(buyDmmAvailableQty.rest, 4) IN IF ~sellDmmAvailableQty.ok THEN Fail ELSE
    Ok([ transactTime        |-> transactTime.value,
         symbolId            |-> symbolId.value,
         imbalanceSide       |-> imbalanceSide.value,
         sideOfUnpairedQty   |-> sideOfUnpairedQty.value,
         imbalanceVolume     |-> imbalanceVolume.value,
         price               |-> price.value,
         pairedQty           |-> pairedQty.value,
         unpairedQty         |-> unpairedQty.value,
         buyDmmAvailableQty  |-> buyDmmAvailableQty.value,
         sellDmmAvailableQty |-> sellDmmAvailableQty.value ], sellDmmAvailableQty.rest)

ZeroAuctionPriceDataMessage ==
    [ transactTime        |-> [i \in 1 .. 8 |-> 0],
      symbolId            |-> [i \in 1 .. 4 |-> 0],
      imbalanceSide       |-> [i \in 1 .. 1 |-> 0],
      sideOfUnpairedQty   |-> [i \in 1 .. 1 |-> 0],
      imbalanceVolume     |-> [i \in 1 .. 4 |-> 0],
      price               |-> [i \in 1 .. 8 |-> 0],
      pairedQty           |-> [i \in 1 .. 4 |-> 0],
      unpairedQty         |-> [i \in 1 .. 4 |-> 0],
      buyDmmAvailableQty  |-> [i \in 1 .. 4 |-> 0],
      sellDmmAvailableQty |-> [i \in 1 .. 4 |-> 0] ]

(* Auction Price Data Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionPriceDataMessage ==
    { ZeroAuctionPriceDataMessage }
        \cup { [ZeroAuctionPriceDataMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroAuctionPriceDataMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroAuctionPriceDataMessage EXCEPT !.imbalanceSide = one] : one \in Sample(1) }
        \cup { [ZeroAuctionPriceDataMessage EXCEPT !.sideOfUnpairedQty = one] : one \in Sample(1) }
        \cup { [ZeroAuctionPriceDataMessage EXCEPT !.imbalanceVolume = one] : one \in Sample(4) }
        \cup { [ZeroAuctionPriceDataMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAuctionPriceDataMessage EXCEPT !.pairedQty = one] : one \in Sample(4) }
        \cup { [ZeroAuctionPriceDataMessage EXCEPT !.unpairedQty = one] : one \in Sample(4) }
        \cup { [ZeroAuctionPriceDataMessage EXCEPT !.buyDmmAvailableQty = one] : one \in Sample(4) }
        \cup { [ZeroAuctionPriceDataMessage EXCEPT !.sellDmmAvailableQty = one] : one \in Sample(4) }

(***************************************************************************)
(* Auction Request Message: 21 bytes                                       *)
(***************************************************************************)

AuctionRequestMessage ==
    [ transactTime   : Sample(8),
      symbolId       : Sample(4),
      auctionType    : Sample(1),
      ssrFilingPrice : Sample(8) ]

EncodeAuctionRequestMessage(message) ==
    message.transactTime
        \o message.symbolId
        \o message.auctionType
        \o message.ssrFilingPrice

DecodeAuctionRequestMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET symbolId == ReadBytes(transactTime.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET auctionType == ReadBytes(symbolId.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET ssrFilingPrice == ReadBytes(auctionType.rest, 8) IN IF ~ssrFilingPrice.ok THEN Fail ELSE
    Ok([ transactTime   |-> transactTime.value,
         symbolId       |-> symbolId.value,
         auctionType    |-> auctionType.value,
         ssrFilingPrice |-> ssrFilingPrice.value ], ssrFilingPrice.rest)

ZeroAuctionRequestMessage ==
    [ transactTime   |-> [i \in 1 .. 8 |-> 0],
      symbolId       |-> [i \in 1 .. 4 |-> 0],
      auctionType    |-> [i \in 1 .. 1 |-> 0],
      ssrFilingPrice |-> [i \in 1 .. 8 |-> 0] ]

(* Auction Request Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionRequestMessage ==
    { ZeroAuctionRequestMessage }
        \cup { [ZeroAuctionRequestMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroAuctionRequestMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroAuctionRequestMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionRequestMessage EXCEPT !.ssrFilingPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Stream Id: 8 bytes                                                      *)
(***************************************************************************)

StreamId6 ==
    [ sess  : Sample(4),
      value : Sample(4) ]

EncodeStreamId6(message) ==
    message.sess
        \o message.value

DecodeStreamId6(bytes) ==
    LET sess == ReadBytes(bytes, 4) IN IF ~sess.ok THEN Fail ELSE
    LET value == ReadBytes(sess.rest, 4) IN IF ~value.ok THEN Fail ELSE
    Ok([ sess  |-> sess.value,
         value |-> value.value ], value.rest)

ZeroStreamId6 ==
    [ sess  |-> [i \in 1 .. 4 |-> 0],
      value |-> [i \in 1 .. 4 |-> 0] ]

(* Stream Id at zero, then each field in turn at the values it is checked at *)
CheckedStreamId6 ==
    { ZeroStreamId6 }
        \cup { [ZeroStreamId6 EXCEPT !.sess = one] : one \in Sample(4) }
        \cup { [ZeroStreamId6 EXCEPT !.value = one] : one \in Sample(4) }

(***************************************************************************)
(* Manual Action Id: 16 bytes                                              *)
(***************************************************************************)

ManualActionId ==
    [ streamId : StreamId6,
      seq      : Sample(8) ]

EncodeManualActionId(message) ==
    EncodeStreamId6(message.streamId)
        \o message.seq

DecodeManualActionId(bytes) ==
    LET streamId == DecodeStreamId6(bytes) IN IF ~streamId.ok THEN Fail ELSE
    LET seq == ReadBytes(streamId.rest, 8) IN IF ~seq.ok THEN Fail ELSE
    Ok([ streamId |-> streamId.value,
         seq      |-> seq.value ], seq.rest)

ZeroManualActionId ==
    [ streamId |-> ZeroStreamId6,
      seq      |-> [i \in 1 .. 8 |-> 0] ]

(* Manual Action Id at zero, then each field in turn at the values it is checked at *)
CheckedManualActionId ==
    { ZeroManualActionId }
        \cup { [ZeroManualActionId EXCEPT !.streamId = one] : one \in CheckedStreamId6 }
        \cup { [ZeroManualActionId EXCEPT !.seq = one] : one \in Sample(8) }

(***************************************************************************)
(* Manual Action Request Message: 91 bytes                                 *)
(***************************************************************************)

ManualActionRequestMessage ==
    [ transactTime         : Sample(8),
      symbolId             : Sample(4),
      introducingBadgeId   : Sample(4),
      mpid                 : Sample(4),
      mmid                 : Sample(4),
      manualActionId       : ManualActionId,
      side                 : Sample(1),
      price                : Sample(8),
      dmmRequestedQty      : Sample(4),
      dmmAvailableQty      : Sample(4),
      dmmAllocatedQty      : Sample(4),
      ssrFilingPrice       : Sample(8),
      manualOverride       : Sample(1),
      manualOverrideReason : Sample(20),
      manualActionType     : Sample(1) ]

EncodeManualActionRequestMessage(message) ==
    message.transactTime
        \o message.symbolId
        \o message.introducingBadgeId
        \o message.mpid
        \o message.mmid
        \o EncodeManualActionId(message.manualActionId)
        \o message.side
        \o message.price
        \o message.dmmRequestedQty
        \o message.dmmAvailableQty
        \o message.dmmAllocatedQty
        \o message.ssrFilingPrice
        \o message.manualOverride
        \o message.manualOverrideReason
        \o message.manualActionType

DecodeManualActionRequestMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET symbolId == ReadBytes(transactTime.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET introducingBadgeId == ReadBytes(symbolId.rest, 4) IN IF ~introducingBadgeId.ok THEN Fail ELSE
    LET mpid == ReadBytes(introducingBadgeId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET mmid == ReadBytes(mpid.rest, 4) IN IF ~mmid.ok THEN Fail ELSE
    LET manualActionId == DecodeManualActionId(mmid.rest) IN IF ~manualActionId.ok THEN Fail ELSE
    LET side == ReadBytes(manualActionId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadBytes(side.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET dmmRequestedQty == ReadBytes(price.rest, 4) IN IF ~dmmRequestedQty.ok THEN Fail ELSE
    LET dmmAvailableQty == ReadBytes(dmmRequestedQty.rest, 4) IN IF ~dmmAvailableQty.ok THEN Fail ELSE
    LET dmmAllocatedQty == ReadBytes(dmmAvailableQty.rest, 4) IN IF ~dmmAllocatedQty.ok THEN Fail ELSE
    LET ssrFilingPrice == ReadBytes(dmmAllocatedQty.rest, 8) IN IF ~ssrFilingPrice.ok THEN Fail ELSE
    LET manualOverride == ReadBytes(ssrFilingPrice.rest, 1) IN IF ~manualOverride.ok THEN Fail ELSE
    LET manualOverrideReason == ReadBytes(manualOverride.rest, 20) IN IF ~manualOverrideReason.ok THEN Fail ELSE
    LET manualActionType == ReadBytes(manualOverrideReason.rest, 1) IN IF ~manualActionType.ok THEN Fail ELSE
    Ok([ transactTime         |-> transactTime.value,
         symbolId             |-> symbolId.value,
         introducingBadgeId   |-> introducingBadgeId.value,
         mpid                 |-> mpid.value,
         mmid                 |-> mmid.value,
         manualActionId       |-> manualActionId.value,
         side                 |-> side.value,
         price                |-> price.value,
         dmmRequestedQty      |-> dmmRequestedQty.value,
         dmmAvailableQty      |-> dmmAvailableQty.value,
         dmmAllocatedQty      |-> dmmAllocatedQty.value,
         ssrFilingPrice       |-> ssrFilingPrice.value,
         manualOverride       |-> manualOverride.value,
         manualOverrideReason |-> manualOverrideReason.value,
         manualActionType     |-> manualActionType.value ], manualActionType.rest)

ZeroManualActionRequestMessage ==
    [ transactTime         |-> [i \in 1 .. 8 |-> 0],
      symbolId             |-> [i \in 1 .. 4 |-> 0],
      introducingBadgeId   |-> [i \in 1 .. 4 |-> 0],
      mpid                 |-> [i \in 1 .. 4 |-> 0],
      mmid                 |-> [i \in 1 .. 4 |-> 0],
      manualActionId       |-> ZeroManualActionId,
      side                 |-> [i \in 1 .. 1 |-> 0],
      price                |-> [i \in 1 .. 8 |-> 0],
      dmmRequestedQty      |-> [i \in 1 .. 4 |-> 0],
      dmmAvailableQty      |-> [i \in 1 .. 4 |-> 0],
      dmmAllocatedQty      |-> [i \in 1 .. 4 |-> 0],
      ssrFilingPrice       |-> [i \in 1 .. 8 |-> 0],
      manualOverride       |-> [i \in 1 .. 1 |-> 0],
      manualOverrideReason |-> [i \in 1 .. 20 |-> 0],
      manualActionType     |-> [i \in 1 .. 1 |-> 0] ]

(* Manual Action Request Message at zero, then each field in turn at the values it is checked at *)
CheckedManualActionRequestMessage ==
    { ZeroManualActionRequestMessage }
        \cup { [ZeroManualActionRequestMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroManualActionRequestMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroManualActionRequestMessage EXCEPT !.introducingBadgeId = one] : one \in Sample(4) }
        \cup { [ZeroManualActionRequestMessage EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroManualActionRequestMessage EXCEPT !.mmid = one] : one \in Sample(4) }
        \cup { [ZeroManualActionRequestMessage EXCEPT !.manualActionId = one] : one \in CheckedManualActionId }
        \cup { [ZeroManualActionRequestMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroManualActionRequestMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroManualActionRequestMessage EXCEPT !.dmmRequestedQty = one] : one \in Sample(4) }
        \cup { [ZeroManualActionRequestMessage EXCEPT !.dmmAvailableQty = one] : one \in Sample(4) }
        \cup { [ZeroManualActionRequestMessage EXCEPT !.dmmAllocatedQty = one] : one \in Sample(4) }
        \cup { [ZeroManualActionRequestMessage EXCEPT !.ssrFilingPrice = one] : one \in Sample(8) }
        \cup { [ZeroManualActionRequestMessage EXCEPT !.manualOverride = one] : one \in Sample(1) }
        \cup { [ZeroManualActionRequestMessage EXCEPT !.manualOverrideReason = one] : one \in Sample(20) }
        \cup { [ZeroManualActionRequestMessage EXCEPT !.manualActionType = one] : one \in Sample(1) }

(***************************************************************************)
(* Risk Control Acknowledgement Message: 310 bytes                         *)
(***************************************************************************)

RiskControlAcknowledgementMessage ==
    [ symbolId                     : Sample(4),
      mpid                         : Sample(4),
      marketMakerNul               : Sample(10),
      mpsubid4                     : Sample(4),
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
        \o message.marketMakerNul
        \o message.mpsubid4
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
    LET marketMakerNul == ReadBytes(mpid.rest, 10) IN IF ~marketMakerNul.ok THEN Fail ELSE
    LET mpsubid4 == ReadBytes(marketMakerNul.rest, 4) IN IF ~mpsubid4.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(mpsubid4.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
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
         marketMakerNul               |-> marketMakerNul.value,
         mpsubid4                     |-> mpsubid4.value,
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
      marketMakerNul               |-> [i \in 1 .. 10 |-> 0],
      mpsubid4                     |-> [i \in 1 .. 4 |-> 0],
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
        \cup { [ZeroRiskControlAcknowledgementMessage EXCEPT !.marketMakerNul = one] : one \in Sample(10) }
        \cup { [ZeroRiskControlAcknowledgementMessage EXCEPT !.mpsubid4 = one] : one \in Sample(4) }
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
      marketMakerNul               : Sample(10),
      mpsubid4                     : Sample(4),
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
        \o message.marketMakerNul
        \o message.mpsubid4
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
    LET marketMakerNul == ReadBytes(mpid.rest, 10) IN IF ~marketMakerNul.ok THEN Fail ELSE
    LET mpsubid4 == ReadBytes(marketMakerNul.rest, 4) IN IF ~mpsubid4.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(mpsubid4.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
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
         marketMakerNul               |-> marketMakerNul.value,
         mpsubid4                     |-> mpsubid4.value,
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
      marketMakerNul               |-> [i \in 1 .. 10 |-> 0],
      mpsubid4                     |-> [i \in 1 .. 4 |-> 0],
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
        \cup { [ZeroRiskControlAlertMessage EXCEPT !.marketMakerNul = one] : one \in Sample(10) }
        \cup { [ZeroRiskControlAlertMessage EXCEPT !.mpsubid4 = one] : one \in Sample(4) }
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
(* Server Sequenced Message, selected by Seq Msg Type                      *)
(***************************************************************************)

EquitiesSymbolReferenceDataMessageCode == 562  \* 0x232
DmmSymbolReferenceDataMessageCode == 2098  \* 0x832
MinimumPriceVariantClassReferenceDataMessageCode == 560  \* 0x230
MinimumPriceVariantLevelReferenceDataMessageCode == 561  \* 0x231
MpidConfigurationMessageCode == 626  \* 0x272
MmidConfigurationMessageCode == 627  \* 0x273
SessionConfigurationAcknowledgementMessageCode == 545  \* 0x221
OrderAndCancelReplaceAcknowledgementMessageCode == 608  \* 0x260
OrderModifyCancelRequestAcknowledgmentAndUroutMessageCode == 625  \* 0x271
OrderPriorityUpdateAcknowledgmentMessageCode == 610  \* 0x262
ExecutionReportMessageCode == 656  \* 0x290
TradeBustCorrectMessageCode == 658  \* 0x292
ApplicationLayerRejectMessageCode == 611  \* 0x263
SymbolSubscriptionAcknowledgementMessageCode == 839  \* 0x347
GtBeginMessageCode == 841  \* 0x349
GtEndMessageCode == 848  \* 0x350
AuctionPriceDataMessageCode == 850  \* 0x352
AuctionRequestMessageCode == 840  \* 0x348
ManualActionRequestMessageCode == 851  \* 0x353
RiskControlAcknowledgementMessageCode == 818  \* 0x332
RiskControlAlertMessageCode == 819  \* 0x333

ServerSequencedMessage ==
    [ tag : {EquitiesSymbolReferenceDataMessageCode}, body : EquitiesSymbolReferenceDataMessage ]
        \cup [ tag : {DmmSymbolReferenceDataMessageCode}, body : DmmSymbolReferenceDataMessage ]
        \cup [ tag : {MinimumPriceVariantClassReferenceDataMessageCode}, body : MinimumPriceVariantClassReferenceDataMessage ]
        \cup [ tag : {MinimumPriceVariantLevelReferenceDataMessageCode}, body : MinimumPriceVariantLevelReferenceDataMessage ]
        \cup [ tag : {MpidConfigurationMessageCode}, body : MpidConfigurationMessage ]
        \cup [ tag : {MmidConfigurationMessageCode}, body : MmidConfigurationMessage ]
        \cup [ tag : {SessionConfigurationAcknowledgementMessageCode}, body : SessionConfigurationAcknowledgementMessage ]
        \cup [ tag : {OrderAndCancelReplaceAcknowledgementMessageCode}, body : OrderAndCancelReplaceAcknowledgementMessage ]
        \cup [ tag : {OrderModifyCancelRequestAcknowledgmentAndUroutMessageCode}, body : OrderModifyCancelRequestAcknowledgmentAndUroutMessage ]
        \cup [ tag : {OrderPriorityUpdateAcknowledgmentMessageCode}, body : OrderPriorityUpdateAcknowledgmentMessage ]
        \cup [ tag : {ExecutionReportMessageCode}, body : ExecutionReportMessage ]
        \cup [ tag : {TradeBustCorrectMessageCode}, body : TradeBustCorrectMessage ]
        \cup [ tag : {ApplicationLayerRejectMessageCode}, body : ApplicationLayerRejectMessage ]
        \cup [ tag : {SymbolSubscriptionAcknowledgementMessageCode}, body : SymbolSubscriptionAcknowledgementMessage ]
        \cup [ tag : {GtBeginMessageCode}, body : GtBeginMessage ]
        \cup [ tag : {GtEndMessageCode}, body : GtEndMessage ]
        \cup [ tag : {AuctionPriceDataMessageCode}, body : AuctionPriceDataMessage ]
        \cup [ tag : {AuctionRequestMessageCode}, body : AuctionRequestMessage ]
        \cup [ tag : {ManualActionRequestMessageCode}, body : ManualActionRequestMessage ]
        \cup [ tag : {RiskControlAcknowledgementMessageCode}, body : RiskControlAcknowledgementMessage ]
        \cup [ tag : {RiskControlAlertMessageCode}, body : RiskControlAlertMessage ]

EncodeServerSequencedMessage(message) ==
    CASE message.tag = EquitiesSymbolReferenceDataMessageCode -> EncodeEquitiesSymbolReferenceDataMessage(message.body)
      [] message.tag = DmmSymbolReferenceDataMessageCode -> EncodeDmmSymbolReferenceDataMessage(message.body)
      [] message.tag = MinimumPriceVariantClassReferenceDataMessageCode -> EncodeMinimumPriceVariantClassReferenceDataMessage(message.body)
      [] message.tag = MinimumPriceVariantLevelReferenceDataMessageCode -> EncodeMinimumPriceVariantLevelReferenceDataMessage(message.body)
      [] message.tag = MpidConfigurationMessageCode -> EncodeMpidConfigurationMessage(message.body)
      [] message.tag = MmidConfigurationMessageCode -> EncodeMmidConfigurationMessage(message.body)
      [] message.tag = SessionConfigurationAcknowledgementMessageCode -> EncodeSessionConfigurationAcknowledgementMessage(message.body)
      [] message.tag = OrderAndCancelReplaceAcknowledgementMessageCode -> EncodeOrderAndCancelReplaceAcknowledgementMessage(message.body)
      [] message.tag = OrderModifyCancelRequestAcknowledgmentAndUroutMessageCode -> EncodeOrderModifyCancelRequestAcknowledgmentAndUroutMessage(message.body)
      [] message.tag = OrderPriorityUpdateAcknowledgmentMessageCode -> EncodeOrderPriorityUpdateAcknowledgmentMessage(message.body)
      [] message.tag = ExecutionReportMessageCode -> EncodeExecutionReportMessage(message.body)
      [] message.tag = TradeBustCorrectMessageCode -> EncodeTradeBustCorrectMessage(message.body)
      [] message.tag = ApplicationLayerRejectMessageCode -> EncodeApplicationLayerRejectMessage(message.body)
      [] message.tag = SymbolSubscriptionAcknowledgementMessageCode -> EncodeSymbolSubscriptionAcknowledgementMessage(message.body)
      [] message.tag = GtBeginMessageCode -> EncodeGtBeginMessage(message.body)
      [] message.tag = GtEndMessageCode -> EncodeGtEndMessage(message.body)
      [] message.tag = AuctionPriceDataMessageCode -> EncodeAuctionPriceDataMessage(message.body)
      [] message.tag = AuctionRequestMessageCode -> EncodeAuctionRequestMessage(message.body)
      [] message.tag = ManualActionRequestMessageCode -> EncodeManualActionRequestMessage(message.body)
      [] message.tag = RiskControlAcknowledgementMessageCode -> EncodeRiskControlAcknowledgementMessage(message.body)
      [] message.tag = RiskControlAlertMessageCode -> EncodeRiskControlAlertMessage(message.body)

DecodeServerSequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = EquitiesSymbolReferenceDataMessageCode -> DecodeEquitiesSymbolReferenceDataMessage(bytes)
              [] tag = DmmSymbolReferenceDataMessageCode -> DecodeDmmSymbolReferenceDataMessage(bytes)
              [] tag = MinimumPriceVariantClassReferenceDataMessageCode -> DecodeMinimumPriceVariantClassReferenceDataMessage(bytes)
              [] tag = MinimumPriceVariantLevelReferenceDataMessageCode -> DecodeMinimumPriceVariantLevelReferenceDataMessage(bytes)
              [] tag = MpidConfigurationMessageCode -> DecodeMpidConfigurationMessage(bytes)
              [] tag = MmidConfigurationMessageCode -> DecodeMmidConfigurationMessage(bytes)
              [] tag = SessionConfigurationAcknowledgementMessageCode -> DecodeSessionConfigurationAcknowledgementMessage(bytes)
              [] tag = OrderAndCancelReplaceAcknowledgementMessageCode -> DecodeOrderAndCancelReplaceAcknowledgementMessage(bytes)
              [] tag = OrderModifyCancelRequestAcknowledgmentAndUroutMessageCode -> DecodeOrderModifyCancelRequestAcknowledgmentAndUroutMessage(bytes)
              [] tag = OrderPriorityUpdateAcknowledgmentMessageCode -> DecodeOrderPriorityUpdateAcknowledgmentMessage(bytes)
              [] tag = ExecutionReportMessageCode -> DecodeExecutionReportMessage(bytes)
              [] tag = TradeBustCorrectMessageCode -> DecodeTradeBustCorrectMessage(bytes)
              [] tag = ApplicationLayerRejectMessageCode -> DecodeApplicationLayerRejectMessage(bytes)
              [] tag = SymbolSubscriptionAcknowledgementMessageCode -> DecodeSymbolSubscriptionAcknowledgementMessage(bytes)
              [] tag = GtBeginMessageCode -> DecodeGtBeginMessage(bytes)
              [] tag = GtEndMessageCode -> DecodeGtEndMessage(bytes)
              [] tag = AuctionPriceDataMessageCode -> DecodeAuctionPriceDataMessage(bytes)
              [] tag = AuctionRequestMessageCode -> DecodeAuctionRequestMessage(bytes)
              [] tag = ManualActionRequestMessageCode -> DecodeManualActionRequestMessage(bytes)
              [] tag = RiskControlAcknowledgementMessageCode -> DecodeRiskControlAcknowledgementMessage(bytes)
              [] tag = RiskControlAlertMessageCode -> DecodeRiskControlAlertMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroServerSequencedMessage == [tag |-> EquitiesSymbolReferenceDataMessageCode, body |-> ZeroEquitiesSymbolReferenceDataMessage]

(* Each Server Sequenced Message in turn, at the values the message it names is checked at *)
CheckedServerSequencedMessage ==
    { [tag |-> EquitiesSymbolReferenceDataMessageCode, body |-> one] : one \in CheckedEquitiesSymbolReferenceDataMessage }
        \cup { [tag |-> DmmSymbolReferenceDataMessageCode, body |-> one] : one \in CheckedDmmSymbolReferenceDataMessage }
        \cup { [tag |-> MinimumPriceVariantClassReferenceDataMessageCode, body |-> one] : one \in CheckedMinimumPriceVariantClassReferenceDataMessage }
        \cup { [tag |-> MinimumPriceVariantLevelReferenceDataMessageCode, body |-> one] : one \in CheckedMinimumPriceVariantLevelReferenceDataMessage }
        \cup { [tag |-> MpidConfigurationMessageCode, body |-> one] : one \in CheckedMpidConfigurationMessage }
        \cup { [tag |-> MmidConfigurationMessageCode, body |-> one] : one \in CheckedMmidConfigurationMessage }
        \cup { [tag |-> SessionConfigurationAcknowledgementMessageCode, body |-> one] : one \in CheckedSessionConfigurationAcknowledgementMessage }
        \cup { [tag |-> OrderAndCancelReplaceAcknowledgementMessageCode, body |-> one] : one \in CheckedOrderAndCancelReplaceAcknowledgementMessage }
        \cup { [tag |-> OrderModifyCancelRequestAcknowledgmentAndUroutMessageCode, body |-> one] : one \in CheckedOrderModifyCancelRequestAcknowledgmentAndUroutMessage }
        \cup { [tag |-> OrderPriorityUpdateAcknowledgmentMessageCode, body |-> one] : one \in CheckedOrderPriorityUpdateAcknowledgmentMessage }
        \cup { [tag |-> ExecutionReportMessageCode, body |-> one] : one \in CheckedExecutionReportMessage }
        \cup { [tag |-> TradeBustCorrectMessageCode, body |-> one] : one \in CheckedTradeBustCorrectMessage }
        \cup { [tag |-> ApplicationLayerRejectMessageCode, body |-> one] : one \in CheckedApplicationLayerRejectMessage }
        \cup { [tag |-> SymbolSubscriptionAcknowledgementMessageCode, body |-> one] : one \in CheckedSymbolSubscriptionAcknowledgementMessage }
        \cup { [tag |-> GtBeginMessageCode, body |-> one] : one \in CheckedGtBeginMessage }
        \cup { [tag |-> GtEndMessageCode, body |-> one] : one \in CheckedGtEndMessage }
        \cup { [tag |-> AuctionPriceDataMessageCode, body |-> one] : one \in CheckedAuctionPriceDataMessage }
        \cup { [tag |-> AuctionRequestMessageCode, body |-> one] : one \in CheckedAuctionRequestMessage }
        \cup { [tag |-> ManualActionRequestMessageCode, body |-> one] : one \in CheckedManualActionRequestMessage }
        \cup { [tag |-> RiskControlAcknowledgementMessageCode, body |-> one] : one \in CheckedRiskControlAcknowledgementMessage }
        \cup { [tag |-> RiskControlAlertMessageCode, body |-> one] : one \in CheckedRiskControlAlertMessage }

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

(* Every Equities Symbol Reference Data Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEquitiesSymbolReferenceDataMessage ==
    \A message \in CheckedEquitiesSymbolReferenceDataMessage :
        LET read == DecodeEquitiesSymbolReferenceDataMessage(EncodeEquitiesSymbolReferenceDataMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Dmm Symbol Reference Data Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDmmSymbolReferenceDataMessage ==
    \A message \in CheckedDmmSymbolReferenceDataMessage :
        LET read == DecodeDmmSymbolReferenceDataMessage(EncodeDmmSymbolReferenceDataMessage(message))
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

(* Every Mmid Configuration Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMmidConfigurationMessage ==
    \A message \in CheckedMmidConfigurationMessage :
        LET read == DecodeMmidConfigurationMessage(EncodeMmidConfigurationMessage(message))
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

(* Every Order And Cancel Replace Acknowledgement Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderAndCancelReplaceAcknowledgementMessage ==
    \A message \in CheckedOrderAndCancelReplaceAcknowledgementMessage :
        LET read == DecodeOrderAndCancelReplaceAcknowledgementMessage(EncodeOrderAndCancelReplaceAcknowledgementMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Modify Cancel Request Acknowledgment And Urout Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderModifyCancelRequestAcknowledgmentAndUroutMessage ==
    \A message \in CheckedOrderModifyCancelRequestAcknowledgmentAndUroutMessage :
        LET read == DecodeOrderModifyCancelRequestAcknowledgmentAndUroutMessage(EncodeOrderModifyCancelRequestAcknowledgmentAndUroutMessage(message))
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
RoundTripSubMsgHeader4 ==
    \A message \in CheckedSubMsgHeader4 :
        LET read == DecodeSubMsgHeader4(EncodeSubMsgHeader4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Optional Settlement Type Add On decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionalSettlementTypeAddOn2 ==
    \A message \in CheckedOptionalSettlementTypeAddOn2 :
        LET read == DecodeOptionalSettlementTypeAddOn2(EncodeOptionalSettlementTypeAddOn2(message))
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

(* Every Symbol Subscription Acknowledgement Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolSubscriptionAcknowledgementMessage ==
    \A message \in CheckedSymbolSubscriptionAcknowledgementMessage :
        LET read == DecodeSymbolSubscriptionAcknowledgementMessage(EncodeSymbolSubscriptionAcknowledgementMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Gt Begin Message decodes back to what was encoded, and leaves nothing over *)
RoundTripGtBeginMessage ==
    \A message \in CheckedGtBeginMessage :
        LET read == DecodeGtBeginMessage(EncodeGtBeginMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Gt End Message decodes back to what was encoded, and leaves nothing over *)
RoundTripGtEndMessage ==
    \A message \in CheckedGtEndMessage :
        LET read == DecodeGtEndMessage(EncodeGtEndMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Price Data Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionPriceDataMessage ==
    \A message \in CheckedAuctionPriceDataMessage :
        LET read == DecodeAuctionPriceDataMessage(EncodeAuctionPriceDataMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionRequestMessage ==
    \A message \in CheckedAuctionRequestMessage :
        LET read == DecodeAuctionRequestMessage(EncodeAuctionRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stream Id decodes back to what was encoded, and leaves nothing over *)
RoundTripStreamId6 ==
    \A message \in CheckedStreamId6 :
        LET read == DecodeStreamId6(EncodeStreamId6(message))
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

(* Every Manual Action Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripManualActionRequestMessage ==
    \A message \in CheckedManualActionRequestMessage :
        LET read == DecodeManualActionRequestMessage(EncodeManualActionRequestMessage(message))
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
