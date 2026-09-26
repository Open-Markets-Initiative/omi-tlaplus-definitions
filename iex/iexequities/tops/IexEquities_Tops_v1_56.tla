---------------------- MODULE IexEquities_Tops_v1_56 -----------------------
(***************************************************************************)
(* Investors Exchange Top Of Book v1.56                                    *)
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
(* Note: a Message Count of 0 marks Heartbeat and carries no Message.      *)
(*                                                                         *)
(* Note: Quote Update Flags is a bit field set, checked as its 1 byte      *)
(* rather than bit by bit.                                                 *)
(*                                                                         *)
(* Note: Sale Condition Flags is a bit field set, checked as its 1 byte    *)
(* rather than bit by bit.                                                 *)
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
(* Quote Update Message: 41 bytes                                          *)
(***************************************************************************)

QuoteUpdateMessage ==
    [ quoteUpdateFlags : Sample(1),
      timestamp        : Sample(8),
      symbol           : Sample(8),
      bidSize          : Sample(4),
      bidPrice         : Sample(8),
      askPrice         : Sample(8),
      askSize          : Sample(4) ]

EncodeQuoteUpdateMessage(message) ==
    message.quoteUpdateFlags
        \o message.timestamp
        \o message.symbol
        \o message.bidSize
        \o message.bidPrice
        \o message.askPrice
        \o message.askSize

DecodeQuoteUpdateMessage(bytes) ==
    LET quoteUpdateFlags == ReadBytes(bytes, 1) IN IF ~quoteUpdateFlags.ok THEN Fail ELSE
    LET timestamp == ReadBytes(quoteUpdateFlags.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET bidSize == ReadBytes(symbol.rest, 4) IN IF ~bidSize.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(bidSize.rest, 8) IN IF ~bidPrice.ok THEN Fail ELSE
    LET askPrice == ReadBytes(bidPrice.rest, 8) IN IF ~askPrice.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPrice.rest, 4) IN IF ~askSize.ok THEN Fail ELSE
    Ok([ quoteUpdateFlags |-> quoteUpdateFlags.value,
         timestamp        |-> timestamp.value,
         symbol           |-> symbol.value,
         bidSize          |-> bidSize.value,
         bidPrice         |-> bidPrice.value,
         askPrice         |-> askPrice.value,
         askSize          |-> askSize.value ], askSize.rest)

ZeroQuoteUpdateMessage ==
    [ quoteUpdateFlags |-> [i \in 1 .. 1 |-> 0],
      timestamp        |-> [i \in 1 .. 8 |-> 0],
      symbol           |-> [i \in 1 .. 8 |-> 0],
      bidSize          |-> [i \in 1 .. 4 |-> 0],
      bidPrice         |-> [i \in 1 .. 8 |-> 0],
      askPrice         |-> [i \in 1 .. 8 |-> 0],
      askSize          |-> [i \in 1 .. 4 |-> 0] ]

(* Quote Update Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteUpdateMessage ==
    { ZeroQuoteUpdateMessage }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.quoteUpdateFlags = one] : one \in Sample(1) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.bidSize = one] : one \in Sample(4) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.bidPrice = one] : one \in Sample(8) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.askPrice = one] : one \in Sample(8) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.askSize = one] : one \in Sample(4) }

(***************************************************************************)
(* Trade Report Message: 41 bytes                                          *)
(***************************************************************************)

TradeReportMessage ==
    [ saleConditionFlags : Sample(1),
      timestamp          : Sample(8),
      symbol             : Sample(8),
      size               : Sample(4),
      price              : Sample(8),
      tradeId            : Sample(8),
      reserved4          : Sample(4) ]

EncodeTradeReportMessage(message) ==
    message.saleConditionFlags
        \o message.timestamp
        \o message.symbol
        \o message.size
        \o message.price
        \o message.tradeId
        \o message.reserved4

DecodeTradeReportMessage(bytes) ==
    LET saleConditionFlags == ReadBytes(bytes, 1) IN IF ~saleConditionFlags.ok THEN Fail ELSE
    LET timestamp == ReadBytes(saleConditionFlags.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET size == ReadBytes(symbol.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET price == ReadBytes(size.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET tradeId == ReadBytes(price.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(tradeId.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    Ok([ saleConditionFlags |-> saleConditionFlags.value,
         timestamp          |-> timestamp.value,
         symbol             |-> symbol.value,
         size               |-> size.value,
         price              |-> price.value,
         tradeId            |-> tradeId.value,
         reserved4          |-> reserved4.value ], reserved4.rest)

ZeroTradeReportMessage ==
    [ saleConditionFlags |-> [i \in 1 .. 1 |-> 0],
      timestamp          |-> [i \in 1 .. 8 |-> 0],
      symbol             |-> [i \in 1 .. 8 |-> 0],
      size               |-> [i \in 1 .. 4 |-> 0],
      price              |-> [i \in 1 .. 8 |-> 0],
      tradeId            |-> [i \in 1 .. 8 |-> 0],
      reserved4          |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Report Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeReportMessage ==
    { ZeroTradeReportMessage }
        \cup { [ZeroTradeReportMessage EXCEPT !.saleConditionFlags = one] : one \in Sample(1) }
        \cup { [ZeroTradeReportMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeReportMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroTradeReportMessage EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroTradeReportMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeReportMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroTradeReportMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Trade Break Message: 41 bytes                                           *)
(***************************************************************************)

TradeBreakMessage ==
    [ saleConditionFlags : Sample(1),
      timestamp          : Sample(8),
      symbol             : Sample(8),
      size               : Sample(4),
      price              : Sample(8),
      tradeId            : Sample(8),
      reserved4          : Sample(4) ]

EncodeTradeBreakMessage(message) ==
    message.saleConditionFlags
        \o message.timestamp
        \o message.symbol
        \o message.size
        \o message.price
        \o message.tradeId
        \o message.reserved4

DecodeTradeBreakMessage(bytes) ==
    LET saleConditionFlags == ReadBytes(bytes, 1) IN IF ~saleConditionFlags.ok THEN Fail ELSE
    LET timestamp == ReadBytes(saleConditionFlags.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET size == ReadBytes(symbol.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET price == ReadBytes(size.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET tradeId == ReadBytes(price.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(tradeId.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    Ok([ saleConditionFlags |-> saleConditionFlags.value,
         timestamp          |-> timestamp.value,
         symbol             |-> symbol.value,
         size               |-> size.value,
         price              |-> price.value,
         tradeId            |-> tradeId.value,
         reserved4          |-> reserved4.value ], reserved4.rest)

ZeroTradeBreakMessage ==
    [ saleConditionFlags |-> [i \in 1 .. 1 |-> 0],
      timestamp          |-> [i \in 1 .. 8 |-> 0],
      symbol             |-> [i \in 1 .. 8 |-> 0],
      size               |-> [i \in 1 .. 4 |-> 0],
      price              |-> [i \in 1 .. 8 |-> 0],
      tradeId            |-> [i \in 1 .. 8 |-> 0],
      reserved4          |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Break Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeBreakMessage ==
    { ZeroTradeBreakMessage }
        \cup { [ZeroTradeBreakMessage EXCEPT !.saleConditionFlags = one] : one \in Sample(1) }
        \cup { [ZeroTradeBreakMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeBreakMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroTradeBreakMessage EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroTradeBreakMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeBreakMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroTradeBreakMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Message Data, selected by Message Type                                  *)
(***************************************************************************)

QuoteUpdateMessageCode == 81  \* "Q"
TradeReportMessageCode == 84  \* "T"
TradeBreakMessageCode == 66  \* "B"

MessageData ==
    [ tag : {QuoteUpdateMessageCode}, body : QuoteUpdateMessage ]
        \cup [ tag : {TradeReportMessageCode}, body : TradeReportMessage ]
        \cup [ tag : {TradeBreakMessageCode}, body : TradeBreakMessage ]

EncodeMessageData(message) ==
    CASE message.tag = QuoteUpdateMessageCode -> EncodeQuoteUpdateMessage(message.body)
      [] message.tag = TradeReportMessageCode -> EncodeTradeReportMessage(message.body)
      [] message.tag = TradeBreakMessageCode -> EncodeTradeBreakMessage(message.body)

DecodeMessageData(tag, bytes) ==
    LET read ==
            CASE tag = QuoteUpdateMessageCode -> DecodeQuoteUpdateMessage(bytes)
              [] tag = TradeReportMessageCode -> DecodeTradeReportMessage(bytes)
              [] tag = TradeBreakMessageCode -> DecodeTradeBreakMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroMessageData == [tag |-> QuoteUpdateMessageCode, body |-> ZeroQuoteUpdateMessage]

(* Each Message Data in turn, at the values the message it names is checked at *)
CheckedMessageData ==
    { [tag |-> QuoteUpdateMessageCode, body |-> one] : one \in CheckedQuoteUpdateMessage }
        \cup { [tag |-> TradeReportMessageCode, body |-> one] : one \in CheckedTradeReportMessage }
        \cup { [tag |-> TradeBreakMessageCode, body |-> one] : one \in CheckedTradeBreakMessage }

(***************************************************************************)
(* Message, framed by Message Length                                       *)
(***************************************************************************)

Message ==
    [ messageData : MessageData ]

EncodeMessageBody(message) ==
    EncodeUIntBE(message.messageData.tag, 1)
        \o EncodeMessageData(message.messageData)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntLE(Len(body), 2) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET messageData == DecodeMessageData(messageType.value, messageType.rest) IN IF ~messageData.ok THEN Fail ELSE
    Ok([ messageData |-> messageData.value ], messageData.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroMessage ==
    [ messageData |-> ZeroMessageData ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.messageData = one] : one \in CheckedMessageData }

(* A run of Message, written one after another *)
RECURSIVE EncodeMessageList(_)
EncodeMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMessage(Head(messages)) \o EncodeMessageList(Tail(messages))

(* As many Message as the field that counts them says *)
RECURSIVE ReadMessageList(_, _)
ReadMessageList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMessageList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Message of each kind, for the lists that carry them *)
OneMessage ==
    { [ZeroMessage EXCEPT !.messageData = [tag |-> QuoteUpdateMessageCode, body |-> ZeroQuoteUpdateMessage]],
      [ZeroMessage EXCEPT !.messageData = [tag |-> TradeReportMessageCode, body |-> ZeroTradeReportMessage]],
      [ZeroMessage EXCEPT !.messageData = [tag |-> TradeBreakMessageCode, body |-> ZeroTradeBreakMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ version                    : Sample(1),
      reserved                   : Sample(1),
      messageProtocolId          : Sample(2),
      channelId                  : Sample(4),
      sessionId                  : Sample(4),
      streamOffset               : Sample(8),
      firstMessageSequenceNumber : Sample(8),
      sendTime                   : Sample(8),
      message                    : SampleLists(OneMessage) ]

EncodePacket(message) ==
    LET payload == EncodeMessageList(message.message)
    IN  message.version
            \o message.reserved
            \o message.messageProtocolId
            \o message.channelId
            \o message.sessionId
            \o EncodeUIntLE(Len(payload), 2)
            \o EncodeUIntLE(Len(message.message), 2)
            \o message.streamOffset
            \o message.firstMessageSequenceNumber
            \o message.sendTime
            \o payload

DecodePacket(bytes) ==
    LET version == ReadBytes(bytes, 1) IN IF ~version.ok THEN Fail ELSE
    LET reserved == ReadBytes(version.rest, 1) IN IF ~reserved.ok THEN Fail ELSE
    LET messageProtocolId == ReadBytes(reserved.rest, 2) IN IF ~messageProtocolId.ok THEN Fail ELSE
    LET channelId == ReadBytes(messageProtocolId.rest, 4) IN IF ~channelId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(channelId.rest, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET payloadLength == ReadUIntLE(sessionId.rest, 2) IN IF ~payloadLength.ok THEN Fail ELSE
    LET messageCount == ReadUIntLE(payloadLength.rest, 2) IN IF ~messageCount.ok THEN Fail ELSE
    LET streamOffset == ReadBytes(messageCount.rest, 8) IN IF ~streamOffset.ok THEN Fail ELSE
    LET firstMessageSequenceNumber == ReadBytes(streamOffset.rest, 8) IN IF ~firstMessageSequenceNumber.ok THEN Fail ELSE
    LET sendTime == ReadBytes(firstMessageSequenceNumber.rest, 8) IN IF ~sendTime.ok THEN Fail ELSE
    IF Len(sendTime.rest) < payloadLength.value THEN Fail ELSE
    LET framed == SubSeq(sendTime.rest, 1, payloadLength.value)
        beyond == SubSeq(sendTime.rest, payloadLength.value + 1, Len(sendTime.rest))
        message == ReadMessageList(framed, messageCount.value)
    IN  IF ~message.ok \/ message.rest # << >> THEN Fail ELSE
    Ok([ version                    |-> version.value,
         reserved                   |-> reserved.value,
         messageProtocolId          |-> messageProtocolId.value,
         channelId                  |-> channelId.value,
         sessionId                  |-> sessionId.value,
         streamOffset               |-> streamOffset.value,
         firstMessageSequenceNumber |-> firstMessageSequenceNumber.value,
         sendTime                   |-> sendTime.value,
         message                    |-> message.value ], beyond)

ZeroPacket ==
    [ version                    |-> [i \in 1 .. 1 |-> 0],
      reserved                   |-> [i \in 1 .. 1 |-> 0],
      messageProtocolId          |-> [i \in 1 .. 2 |-> 0],
      channelId                  |-> [i \in 1 .. 4 |-> 0],
      sessionId                  |-> [i \in 1 .. 4 |-> 0],
      streamOffset               |-> [i \in 1 .. 8 |-> 0],
      firstMessageSequenceNumber |-> [i \in 1 .. 8 |-> 0],
      sendTime                   |-> [i \in 1 .. 8 |-> 0],
      message                    |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.version = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.reserved = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.messageProtocolId = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.channelId = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.streamOffset = one] : one \in Sample(8) }
        \cup { [ZeroPacket EXCEPT !.firstMessageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroPacket EXCEPT !.sendTime = one] : one \in Sample(8) }
        \cup { [ZeroPacket EXCEPT !.message = one] : one \in SampleLists(OneMessage) }

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

(* Every Quote Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteUpdateMessage ==
    \A message \in CheckedQuoteUpdateMessage :
        LET read == DecodeQuoteUpdateMessage(EncodeQuoteUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeReportMessage ==
    \A message \in CheckedTradeReportMessage :
        LET read == DecodeTradeReportMessage(EncodeTradeReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Break Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBreakMessage ==
    \A message \in CheckedTradeBreakMessage :
        LET read == DecodeTradeBreakMessage(EncodeTradeBreakMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMessage ==
    \A message \in CheckedMessage :
        LET read == DecodeMessage(EncodeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripPacket ==
    \A message \in CheckedPacket :
        LET read == DecodePacket(EncodePacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Message Data is selected by the Message Type it is written under *)
SelectsMessageData ==
    \A message \in CheckedMessageData :
        LET read == DecodeMessageData(message.tag, EncodeMessageData(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Message Length is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
