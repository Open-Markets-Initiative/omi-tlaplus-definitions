--------- MODULE AmexEquities_IntegratedFeedRequest_v2_5_g_Client ----------
(***************************************************************************)
(* New York Stock Exchange Integrated Feed Request v2.5.g                  *)
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
(* Retransmission Request Message: 20 bytes                                *)
(***************************************************************************)

RetransmissionRequestMessage ==
    [ beginSeqNum : Sample(4),
      endSeqNum   : Sample(4),
      sourceId    : Sample(10),
      productId   : Sample(1),
      channelId   : Sample(1) ]

EncodeRetransmissionRequestMessage(message) ==
    message.beginSeqNum
        \o message.endSeqNum
        \o message.sourceId
        \o message.productId
        \o message.channelId

DecodeRetransmissionRequestMessage(bytes) ==
    LET beginSeqNum == ReadBytes(bytes, 4) IN IF ~beginSeqNum.ok THEN Fail ELSE
    LET endSeqNum == ReadBytes(beginSeqNum.rest, 4) IN IF ~endSeqNum.ok THEN Fail ELSE
    LET sourceId == ReadBytes(endSeqNum.rest, 10) IN IF ~sourceId.ok THEN Fail ELSE
    LET productId == ReadBytes(sourceId.rest, 1) IN IF ~productId.ok THEN Fail ELSE
    LET channelId == ReadBytes(productId.rest, 1) IN IF ~channelId.ok THEN Fail ELSE
    Ok([ beginSeqNum |-> beginSeqNum.value,
         endSeqNum   |-> endSeqNum.value,
         sourceId    |-> sourceId.value,
         productId   |-> productId.value,
         channelId   |-> channelId.value ], channelId.rest)

ZeroRetransmissionRequestMessage ==
    [ beginSeqNum |-> [i \in 1 .. 4 |-> 0],
      endSeqNum   |-> [i \in 1 .. 4 |-> 0],
      sourceId    |-> [i \in 1 .. 10 |-> 0],
      productId   |-> [i \in 1 .. 1 |-> 0],
      channelId   |-> [i \in 1 .. 1 |-> 0] ]

(* Retransmission Request Message at zero, then each field in turn at the values it is checked at *)
CheckedRetransmissionRequestMessage ==
    { ZeroRetransmissionRequestMessage }
        \cup { [ZeroRetransmissionRequestMessage EXCEPT !.beginSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRetransmissionRequestMessage EXCEPT !.endSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRetransmissionRequestMessage EXCEPT !.sourceId = one] : one \in Sample(10) }
        \cup { [ZeroRetransmissionRequestMessage EXCEPT !.productId = one] : one \in Sample(1) }
        \cup { [ZeroRetransmissionRequestMessage EXCEPT !.channelId = one] : one \in Sample(1) }

(***************************************************************************)
(* Heartbeat Response Message: 10 bytes                                    *)
(***************************************************************************)

HeartbeatResponseMessage ==
    [ sourceId : Sample(10) ]

EncodeHeartbeatResponseMessage(message) ==
    message.sourceId

DecodeHeartbeatResponseMessage(bytes) ==
    LET sourceId == ReadBytes(bytes, 10) IN IF ~sourceId.ok THEN Fail ELSE
    Ok([ sourceId |-> sourceId.value ], sourceId.rest)

ZeroHeartbeatResponseMessage ==
    [ sourceId |-> [i \in 1 .. 10 |-> 0] ]

(* Heartbeat Response Message at zero, then each field in turn at the values it is checked at *)
CheckedHeartbeatResponseMessage ==
    { ZeroHeartbeatResponseMessage }
        \cup { [ZeroHeartbeatResponseMessage EXCEPT !.sourceId = one] : one \in Sample(10) }

(***************************************************************************)
(* Symbol Index Mapping Request Message: 17 bytes                          *)
(***************************************************************************)

SymbolIndexMappingRequestMessage ==
    [ symbolIndex      : Sample(4),
      sourceId         : Sample(10),
      productId        : Sample(1),
      channelId        : Sample(1),
      retransmitMethod : Sample(1) ]

EncodeSymbolIndexMappingRequestMessage(message) ==
    message.symbolIndex
        \o message.sourceId
        \o message.productId
        \o message.channelId
        \o message.retransmitMethod

DecodeSymbolIndexMappingRequestMessage(bytes) ==
    LET symbolIndex == ReadBytes(bytes, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET sourceId == ReadBytes(symbolIndex.rest, 10) IN IF ~sourceId.ok THEN Fail ELSE
    LET productId == ReadBytes(sourceId.rest, 1) IN IF ~productId.ok THEN Fail ELSE
    LET channelId == ReadBytes(productId.rest, 1) IN IF ~channelId.ok THEN Fail ELSE
    LET retransmitMethod == ReadBytes(channelId.rest, 1) IN IF ~retransmitMethod.ok THEN Fail ELSE
    Ok([ symbolIndex      |-> symbolIndex.value,
         sourceId         |-> sourceId.value,
         productId        |-> productId.value,
         channelId        |-> channelId.value,
         retransmitMethod |-> retransmitMethod.value ], retransmitMethod.rest)

ZeroSymbolIndexMappingRequestMessage ==
    [ symbolIndex      |-> [i \in 1 .. 4 |-> 0],
      sourceId         |-> [i \in 1 .. 10 |-> 0],
      productId        |-> [i \in 1 .. 1 |-> 0],
      channelId        |-> [i \in 1 .. 1 |-> 0],
      retransmitMethod |-> [i \in 1 .. 1 |-> 0] ]

(* Symbol Index Mapping Request Message at zero, then each field in turn at the values it is checked at *)
CheckedSymbolIndexMappingRequestMessage ==
    { ZeroSymbolIndexMappingRequestMessage }
        \cup { [ZeroSymbolIndexMappingRequestMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroSymbolIndexMappingRequestMessage EXCEPT !.sourceId = one] : one \in Sample(10) }
        \cup { [ZeroSymbolIndexMappingRequestMessage EXCEPT !.productId = one] : one \in Sample(1) }
        \cup { [ZeroSymbolIndexMappingRequestMessage EXCEPT !.channelId = one] : one \in Sample(1) }
        \cup { [ZeroSymbolIndexMappingRequestMessage EXCEPT !.retransmitMethod = one] : one \in Sample(1) }

(***************************************************************************)
(* Refresh Request Message: 16 bytes                                       *)
(***************************************************************************)

RefreshRequestMessage ==
    [ symbolIndex : Sample(4),
      sourceId    : Sample(10),
      productId   : Sample(1),
      channelId   : Sample(1) ]

EncodeRefreshRequestMessage(message) ==
    message.symbolIndex
        \o message.sourceId
        \o message.productId
        \o message.channelId

DecodeRefreshRequestMessage(bytes) ==
    LET symbolIndex == ReadBytes(bytes, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET sourceId == ReadBytes(symbolIndex.rest, 10) IN IF ~sourceId.ok THEN Fail ELSE
    LET productId == ReadBytes(sourceId.rest, 1) IN IF ~productId.ok THEN Fail ELSE
    LET channelId == ReadBytes(productId.rest, 1) IN IF ~channelId.ok THEN Fail ELSE
    Ok([ symbolIndex |-> symbolIndex.value,
         sourceId    |-> sourceId.value,
         productId   |-> productId.value,
         channelId   |-> channelId.value ], channelId.rest)

ZeroRefreshRequestMessage ==
    [ symbolIndex |-> [i \in 1 .. 4 |-> 0],
      sourceId    |-> [i \in 1 .. 10 |-> 0],
      productId   |-> [i \in 1 .. 1 |-> 0],
      channelId   |-> [i \in 1 .. 1 |-> 0] ]

(* Refresh Request Message at zero, then each field in turn at the values it is checked at *)
CheckedRefreshRequestMessage ==
    { ZeroRefreshRequestMessage }
        \cup { [ZeroRefreshRequestMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroRefreshRequestMessage EXCEPT !.sourceId = one] : one \in Sample(10) }
        \cup { [ZeroRefreshRequestMessage EXCEPT !.productId = one] : one \in Sample(1) }
        \cup { [ZeroRefreshRequestMessage EXCEPT !.channelId = one] : one \in Sample(1) }

(***************************************************************************)
(* Client Payload, selected by Message Type                                *)
(***************************************************************************)

RetransmissionRequestMessageCode == 10  \* 0x0a
HeartbeatResponseMessageCode == 12  \* 0x0c
SymbolIndexMappingRequestMessageCode == 13  \* 0x0d
RefreshRequestMessageCode == 15  \* 0x0f

ClientPayload ==
    [ tag : {RetransmissionRequestMessageCode}, body : RetransmissionRequestMessage ]
        \cup [ tag : {HeartbeatResponseMessageCode}, body : HeartbeatResponseMessage ]
        \cup [ tag : {SymbolIndexMappingRequestMessageCode}, body : SymbolIndexMappingRequestMessage ]
        \cup [ tag : {RefreshRequestMessageCode}, body : RefreshRequestMessage ]

EncodeClientPayload(message) ==
    CASE message.tag = RetransmissionRequestMessageCode -> EncodeRetransmissionRequestMessage(message.body)
      [] message.tag = HeartbeatResponseMessageCode -> EncodeHeartbeatResponseMessage(message.body)
      [] message.tag = SymbolIndexMappingRequestMessageCode -> EncodeSymbolIndexMappingRequestMessage(message.body)
      [] message.tag = RefreshRequestMessageCode -> EncodeRefreshRequestMessage(message.body)

DecodeClientPayload(tag, bytes) ==
    LET read ==
            CASE tag = RetransmissionRequestMessageCode -> DecodeRetransmissionRequestMessage(bytes)
              [] tag = HeartbeatResponseMessageCode -> DecodeHeartbeatResponseMessage(bytes)
              [] tag = SymbolIndexMappingRequestMessageCode -> DecodeSymbolIndexMappingRequestMessage(bytes)
              [] tag = RefreshRequestMessageCode -> DecodeRefreshRequestMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroClientPayload == [tag |-> RetransmissionRequestMessageCode, body |-> ZeroRetransmissionRequestMessage]

(* Each Client Payload in turn, at the values the message it names is checked at *)
CheckedClientPayload ==
    { [tag |-> RetransmissionRequestMessageCode, body |-> one] : one \in CheckedRetransmissionRequestMessage }
        \cup { [tag |-> HeartbeatResponseMessageCode, body |-> one] : one \in CheckedHeartbeatResponseMessage }
        \cup { [tag |-> SymbolIndexMappingRequestMessageCode, body |-> one] : one \in CheckedSymbolIndexMappingRequestMessage }
        \cup { [tag |-> RefreshRequestMessageCode, body |-> one] : one \in CheckedRefreshRequestMessage }

(***************************************************************************)
(* Client Message, framed by Message Size                                  *)
(***************************************************************************)

ClientMessage ==
    [ clientPayload : ClientPayload ]

EncodeClientMessageBody(message) ==
    EncodeUIntLE(message.clientPayload.tag, 2)
        \o EncodeClientPayload(message.clientPayload)

(* Message Size counts the bytes it frames, so it is written from them *)
EncodeClientMessage(message) ==
    LET body == EncodeClientMessageBody(message)
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeClientMessageBody(bytes) ==
    LET messageType == ReadUIntLE(bytes, 2) IN IF ~messageType.ok THEN Fail ELSE
    LET clientPayload == DecodeClientPayload(messageType.value, messageType.rest) IN IF ~clientPayload.ok THEN Fail ELSE
    Ok([ clientPayload |-> clientPayload.value ], clientPayload.rest)

DecodeClientMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeClientMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroClientMessage ==
    [ clientPayload |-> ZeroClientPayload ]

(* Client Message at zero, then each field in turn at the values it is checked at *)
CheckedClientMessage ==
    { ZeroClientMessage }
        \cup { [ZeroClientMessage EXCEPT !.clientPayload = one] : one \in CheckedClientPayload }

(* A run of Client Message, written one after another *)
RECURSIVE EncodeClientMessageList(_)
EncodeClientMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeClientMessage(Head(messages)) \o EncodeClientMessageList(Tail(messages))

(* As many Client Message as the field that counts them says *)
RECURSIVE ReadClientMessageList(_, _)
ReadClientMessageList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeClientMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadClientMessageList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Client Message of each kind, for the lists that carry them *)
OneClientMessage ==
    { [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> RetransmissionRequestMessageCode, body |-> ZeroRetransmissionRequestMessage]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> HeartbeatResponseMessageCode, body |-> ZeroHeartbeatResponseMessage]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> SymbolIndexMappingRequestMessageCode, body |-> ZeroSymbolIndexMappingRequestMessage]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> RefreshRequestMessageCode, body |-> ZeroRefreshRequestMessage]] }

(***************************************************************************)
(* Client Packet                                                           *)
(***************************************************************************)

ClientPacket ==
    [ pktSize       : Sample(2),
      deliveryFlag  : Sample(1),
      seqNum        : Sample(4),
      sendTime      : SendTime,
      clientMessage : SampleLists(OneClientMessage) ]

EncodeClientPacket(message) ==
    message.pktSize
        \o message.deliveryFlag
        \o EncodeUIntLE(Len(message.clientMessage), 1)
        \o message.seqNum
        \o EncodeSendTime(message.sendTime)
        \o EncodeClientMessageList(message.clientMessage)

DecodeClientPacket(bytes) ==
    LET pktSize == ReadBytes(bytes, 2) IN IF ~pktSize.ok THEN Fail ELSE
    LET deliveryFlag == ReadBytes(pktSize.rest, 1) IN IF ~deliveryFlag.ok THEN Fail ELSE
    LET numberMsgs == ReadUIntLE(deliveryFlag.rest, 1) IN IF ~numberMsgs.ok THEN Fail ELSE
    LET seqNum == ReadBytes(numberMsgs.rest, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET sendTime == DecodeSendTime(seqNum.rest) IN IF ~sendTime.ok THEN Fail ELSE
    LET clientMessage == ReadClientMessageList(sendTime.rest, numberMsgs.value) IN IF ~clientMessage.ok THEN Fail ELSE
    Ok([ pktSize       |-> pktSize.value,
         deliveryFlag  |-> deliveryFlag.value,
         seqNum        |-> seqNum.value,
         sendTime      |-> sendTime.value,
         clientMessage |-> clientMessage.value ], clientMessage.rest)

ZeroClientPacket ==
    [ pktSize       |-> [i \in 1 .. 2 |-> 0],
      deliveryFlag  |-> [i \in 1 .. 1 |-> 0],
      seqNum        |-> [i \in 1 .. 4 |-> 0],
      sendTime      |-> ZeroSendTime,
      clientMessage |-> << >> ]

(* Client Packet at zero, then each field in turn at the values it is checked at *)
CheckedClientPacket ==
    { ZeroClientPacket }
        \cup { [ZeroClientPacket EXCEPT !.pktSize = one] : one \in Sample(2) }
        \cup { [ZeroClientPacket EXCEPT !.deliveryFlag = one] : one \in Sample(1) }
        \cup { [ZeroClientPacket EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroClientPacket EXCEPT !.sendTime = one] : one \in CheckedSendTime }
        \cup { [ZeroClientPacket EXCEPT !.clientMessage = one] : one \in SampleLists(OneClientMessage) }

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

(* Every Retransmission Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRetransmissionRequestMessage ==
    \A message \in CheckedRetransmissionRequestMessage :
        LET read == DecodeRetransmissionRequestMessage(EncodeRetransmissionRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Heartbeat Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripHeartbeatResponseMessage ==
    \A message \in CheckedHeartbeatResponseMessage :
        LET read == DecodeHeartbeatResponseMessage(EncodeHeartbeatResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol Index Mapping Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolIndexMappingRequestMessage ==
    \A message \in CheckedSymbolIndexMappingRequestMessage :
        LET read == DecodeSymbolIndexMappingRequestMessage(EncodeSymbolIndexMappingRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Refresh Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRefreshRequestMessage ==
    \A message \in CheckedRefreshRequestMessage :
        LET read == DecodeRefreshRequestMessage(EncodeRefreshRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client Message decodes back to what was encoded, and leaves nothing over *)
RoundTripClientMessage ==
    \A message \in CheckedClientMessage :
        LET read == DecodeClientMessage(EncodeClientMessage(message))
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

(* A Client Payload is selected by the Message Type it is written under *)
SelectsClientPayload ==
    \A message \in CheckedClientPayload :
        LET read == DecodeClientPayload(message.tag, EncodeClientPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Message Size is written from the bytes it frames *)
FramesClientMessage ==
    \A message \in CheckedClientMessage :
        LET bytes == EncodeClientMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
