------------- MODULE NyseEquities_DepthFeedRequest_v1_7_Server -------------
(***************************************************************************)
(* New York Stock Exchange Depth Feed Request v1.7                         *)
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
(* Send Time: 8 bytes                                                      *)
(***************************************************************************)

SendTime ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeSendTime(message) ==
    message.seconds
        \o message.nanoseconds

DecodeSendTime(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroSendTime ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Send Time at zero, then each field in turn at the values it is checked at *)
CheckedSendTime ==
    { ZeroSendTime }
        \cup { [ZeroSendTime EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroSendTime EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Request Response Message: 25 bytes                                      *)
(***************************************************************************)

RequestResponseMessage ==
    [ requestSeqNum : Sample(4),
      beginSeqNum   : Sample(4),
      endSeqNum     : Sample(4),
      sourceId      : Sample(10),
      productId     : Sample(1),
      channelId     : Sample(1),
      status        : Sample(1) ]

EncodeRequestResponseMessage(message) ==
    message.requestSeqNum
        \o message.beginSeqNum
        \o message.endSeqNum
        \o message.sourceId
        \o message.productId
        \o message.channelId
        \o message.status

DecodeRequestResponseMessage(bytes) ==
    LET requestSeqNum == ReadBytes(bytes, 4) IN IF ~requestSeqNum.ok THEN Fail ELSE
    LET beginSeqNum == ReadBytes(requestSeqNum.rest, 4) IN IF ~beginSeqNum.ok THEN Fail ELSE
    LET endSeqNum == ReadBytes(beginSeqNum.rest, 4) IN IF ~endSeqNum.ok THEN Fail ELSE
    LET sourceId == ReadBytes(endSeqNum.rest, 10) IN IF ~sourceId.ok THEN Fail ELSE
    LET productId == ReadBytes(sourceId.rest, 1) IN IF ~productId.ok THEN Fail ELSE
    LET channelId == ReadBytes(productId.rest, 1) IN IF ~channelId.ok THEN Fail ELSE
    LET status == ReadBytes(channelId.rest, 1) IN IF ~status.ok THEN Fail ELSE
    Ok([ requestSeqNum |-> requestSeqNum.value,
         beginSeqNum   |-> beginSeqNum.value,
         endSeqNum     |-> endSeqNum.value,
         sourceId      |-> sourceId.value,
         productId     |-> productId.value,
         channelId     |-> channelId.value,
         status        |-> status.value ], status.rest)

ZeroRequestResponseMessage ==
    [ requestSeqNum |-> [i \in 1 .. 4 |-> 0],
      beginSeqNum   |-> [i \in 1 .. 4 |-> 0],
      endSeqNum     |-> [i \in 1 .. 4 |-> 0],
      sourceId      |-> [i \in 1 .. 10 |-> 0],
      productId     |-> [i \in 1 .. 1 |-> 0],
      channelId     |-> [i \in 1 .. 1 |-> 0],
      status        |-> [i \in 1 .. 1 |-> 0] ]

(* Request Response Message at zero, then each field in turn at the values it is checked at *)
CheckedRequestResponseMessage ==
    { ZeroRequestResponseMessage }
        \cup { [ZeroRequestResponseMessage EXCEPT !.requestSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestResponseMessage EXCEPT !.beginSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestResponseMessage EXCEPT !.endSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestResponseMessage EXCEPT !.sourceId = one] : one \in Sample(10) }
        \cup { [ZeroRequestResponseMessage EXCEPT !.productId = one] : one \in Sample(1) }
        \cup { [ZeroRequestResponseMessage EXCEPT !.channelId = one] : one \in Sample(1) }
        \cup { [ZeroRequestResponseMessage EXCEPT !.status = one] : one \in Sample(1) }

(***************************************************************************)
(* Server Payload, selected by Message Type                                *)
(***************************************************************************)

RequestResponseMessageCode == 11  \* 0x0b

ServerPayload ==
    [ tag : {RequestResponseMessageCode}, body : RequestResponseMessage ]

EncodeServerPayload(message) ==
    CASE message.tag = RequestResponseMessageCode -> EncodeRequestResponseMessage(message.body)

DecodeServerPayload(tag, bytes) ==
    LET read ==
            CASE tag = RequestResponseMessageCode -> DecodeRequestResponseMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroServerPayload == [tag |-> RequestResponseMessageCode, body |-> ZeroRequestResponseMessage]

(* Each Server Payload in turn, at the values the message it names is checked at *)
CheckedServerPayload ==
    { [tag |-> RequestResponseMessageCode, body |-> one] : one \in CheckedRequestResponseMessage }

(***************************************************************************)
(* Server Message, framed by Message Size                                  *)
(***************************************************************************)

ServerMessage ==
    [ serverPayload : ServerPayload ]

EncodeServerMessageBody(message) ==
    EncodeUIntLE(message.serverPayload.tag, 2)
        \o EncodeServerPayload(message.serverPayload)

(* Message Size counts the bytes it frames, so it is written from them *)
EncodeServerMessage(message) ==
    LET body == EncodeServerMessageBody(message)
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeServerMessageBody(bytes) ==
    LET messageType == ReadUIntLE(bytes, 2) IN IF ~messageType.ok THEN Fail ELSE
    LET serverPayload == DecodeServerPayload(messageType.value, messageType.rest) IN IF ~serverPayload.ok THEN Fail ELSE
    Ok([ serverPayload |-> serverPayload.value ], serverPayload.rest)

DecodeServerMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeServerMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroServerMessage ==
    [ serverPayload |-> ZeroServerPayload ]

(* Server Message at zero, then each field in turn at the values it is checked at *)
CheckedServerMessage ==
    { ZeroServerMessage }
        \cup { [ZeroServerMessage EXCEPT !.serverPayload = one] : one \in CheckedServerPayload }

(* A run of Server Message, written one after another *)
RECURSIVE EncodeServerMessageList(_)
EncodeServerMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeServerMessage(Head(messages)) \o EncodeServerMessageList(Tail(messages))

(* As many Server Message as the field that counts them says *)
RECURSIVE ReadServerMessageList(_, _)
ReadServerMessageList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeServerMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadServerMessageList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Server Message of each kind, for the lists that carry them *)
OneServerMessage ==
    { [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> RequestResponseMessageCode, body |-> ZeroRequestResponseMessage]] }

(***************************************************************************)
(* Server Packet                                                           *)
(***************************************************************************)

ServerPacket ==
    [ pktSize       : Sample(2),
      deliveryFlag  : Sample(1),
      seqNum        : Sample(4),
      sendTime      : SendTime,
      serverMessage : SampleLists(OneServerMessage) ]

EncodeServerPacket(message) ==
    message.pktSize
        \o message.deliveryFlag
        \o EncodeUIntLE(Len(message.serverMessage), 1)
        \o message.seqNum
        \o EncodeSendTime(message.sendTime)
        \o EncodeServerMessageList(message.serverMessage)

DecodeServerPacket(bytes) ==
    LET pktSize == ReadBytes(bytes, 2) IN IF ~pktSize.ok THEN Fail ELSE
    LET deliveryFlag == ReadBytes(pktSize.rest, 1) IN IF ~deliveryFlag.ok THEN Fail ELSE
    LET numberMsgs == ReadUIntLE(deliveryFlag.rest, 1) IN IF ~numberMsgs.ok THEN Fail ELSE
    LET seqNum == ReadBytes(numberMsgs.rest, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET sendTime == DecodeSendTime(seqNum.rest) IN IF ~sendTime.ok THEN Fail ELSE
    LET serverMessage == ReadServerMessageList(sendTime.rest, numberMsgs.value) IN IF ~serverMessage.ok THEN Fail ELSE
    Ok([ pktSize       |-> pktSize.value,
         deliveryFlag  |-> deliveryFlag.value,
         seqNum        |-> seqNum.value,
         sendTime      |-> sendTime.value,
         serverMessage |-> serverMessage.value ], serverMessage.rest)

ZeroServerPacket ==
    [ pktSize       |-> [i \in 1 .. 2 |-> 0],
      deliveryFlag  |-> [i \in 1 .. 1 |-> 0],
      seqNum        |-> [i \in 1 .. 4 |-> 0],
      sendTime      |-> ZeroSendTime,
      serverMessage |-> << >> ]

(* Server Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerPacket ==
    { ZeroServerPacket }
        \cup { [ZeroServerPacket EXCEPT !.pktSize = one] : one \in Sample(2) }
        \cup { [ZeroServerPacket EXCEPT !.deliveryFlag = one] : one \in Sample(1) }
        \cup { [ZeroServerPacket EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroServerPacket EXCEPT !.sendTime = one] : one \in CheckedSendTime }
        \cup { [ZeroServerPacket EXCEPT !.serverMessage = one] : one \in SampleLists(OneServerMessage) }

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

(* Every Send Time decodes back to what was encoded, and leaves nothing over *)
RoundTripSendTime ==
    \A message \in CheckedSendTime :
        LET read == DecodeSendTime(EncodeSendTime(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestResponseMessage ==
    \A message \in CheckedRequestResponseMessage :
        LET read == DecodeRequestResponseMessage(EncodeRequestResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Server Message decodes back to what was encoded, and leaves nothing over *)
RoundTripServerMessage ==
    \A message \in CheckedServerMessage :
        LET read == DecodeServerMessage(EncodeServerMessage(message))
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

(* A Server Payload is selected by the Message Type it is written under *)
SelectsServerPayload ==
    \A message \in CheckedServerPayload :
        LET read == DecodeServerPayload(message.tag, EncodeServerPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Message Size is written from the bytes it frames *)
FramesServerMessage ==
    \A message \in CheckedServerMessage :
        LET bytes == EncodeServerMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
