---------------------- MODULE NyseBonds_Quote_v1_2_a -----------------------
(***************************************************************************)
(* New York Stock Exchange Quote v1.2.a                                    *)
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
(* Sequence Number Reset Message: 4 bytes                                  *)
(***************************************************************************)

SequenceNumberResetMessage ==
    [ nextSeqNumber : Sample(4) ]

EncodeSequenceNumberResetMessage(message) ==
    message.nextSeqNumber

DecodeSequenceNumberResetMessage(bytes) ==
    LET nextSeqNumber == ReadBytes(bytes, 4) IN IF ~nextSeqNumber.ok THEN Fail ELSE
    Ok([ nextSeqNumber |-> nextSeqNumber.value ], nextSeqNumber.rest)

ZeroSequenceNumberResetMessage ==
    [ nextSeqNumber |-> [i \in 1 .. 4 |-> 0] ]

(* Sequence Number Reset Message at zero, then each field in turn at the values it is checked at *)
CheckedSequenceNumberResetMessage ==
    { ZeroSequenceNumberResetMessage }
        \cup { [ZeroSequenceNumberResetMessage EXCEPT !.nextSeqNumber = one] : one \in Sample(4) }

(***************************************************************************)
(* Message Unavailable Message: 8 bytes                                    *)
(***************************************************************************)

MessageUnavailableMessage ==
    [ beginSeqNum : Sample(4),
      endSeqNum   : Sample(4) ]

EncodeMessageUnavailableMessage(message) ==
    message.beginSeqNum
        \o message.endSeqNum

DecodeMessageUnavailableMessage(bytes) ==
    LET beginSeqNum == ReadBytes(bytes, 4) IN IF ~beginSeqNum.ok THEN Fail ELSE
    LET endSeqNum == ReadBytes(beginSeqNum.rest, 4) IN IF ~endSeqNum.ok THEN Fail ELSE
    Ok([ beginSeqNum |-> beginSeqNum.value,
         endSeqNum   |-> endSeqNum.value ], endSeqNum.rest)

ZeroMessageUnavailableMessage ==
    [ beginSeqNum |-> [i \in 1 .. 4 |-> 0],
      endSeqNum   |-> [i \in 1 .. 4 |-> 0] ]

(* Message Unavailable Message at zero, then each field in turn at the values it is checked at *)
CheckedMessageUnavailableMessage ==
    { ZeroMessageUnavailableMessage }
        \cup { [ZeroMessageUnavailableMessage EXCEPT !.beginSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroMessageUnavailableMessage EXCEPT !.endSeqNum = one] : one \in Sample(4) }

(***************************************************************************)
(* Refresh Quote Message: 72 bytes                                         *)
(***************************************************************************)

RefreshQuoteMessage ==
    [ symbolIndex       : Sample(4),
      sourceTime        : Sample(4),
      quoteLinkId       : Sample(4),
      askPriceNumerator : Sample(4),
      askSize           : Sample(4),
      bidPriceNumerator : Sample(4),
      bidSize           : Sample(4),
      priceScaleCode    : Sample(1),
      exchangeId        : Sample(1),
      securityType      : Sample(1),
      quoteCondition    : Sample(1),
      flatPricing       : Sample(1),
      tradingAction     : Sample(1),
      fillerAscii2      : Sample(2),
      symbol            : Sample(22),
      cusip             : Sample(14) ]

EncodeRefreshQuoteMessage(message) ==
    message.symbolIndex
        \o message.sourceTime
        \o message.quoteLinkId
        \o message.askPriceNumerator
        \o message.askSize
        \o message.bidPriceNumerator
        \o message.bidSize
        \o message.priceScaleCode
        \o message.exchangeId
        \o message.securityType
        \o message.quoteCondition
        \o message.flatPricing
        \o message.tradingAction
        \o message.fillerAscii2
        \o message.symbol
        \o message.cusip

DecodeRefreshQuoteMessage(bytes) ==
    LET symbolIndex == ReadBytes(bytes, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET sourceTime == ReadBytes(symbolIndex.rest, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET quoteLinkId == ReadBytes(sourceTime.rest, 4) IN IF ~quoteLinkId.ok THEN Fail ELSE
    LET askPriceNumerator == ReadBytes(quoteLinkId.rest, 4) IN IF ~askPriceNumerator.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPriceNumerator.rest, 4) IN IF ~askSize.ok THEN Fail ELSE
    LET bidPriceNumerator == ReadBytes(askSize.rest, 4) IN IF ~bidPriceNumerator.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPriceNumerator.rest, 4) IN IF ~bidSize.ok THEN Fail ELSE
    LET priceScaleCode == ReadBytes(bidSize.rest, 1) IN IF ~priceScaleCode.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(priceScaleCode.rest, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET securityType == ReadBytes(exchangeId.rest, 1) IN IF ~securityType.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(securityType.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET flatPricing == ReadBytes(quoteCondition.rest, 1) IN IF ~flatPricing.ok THEN Fail ELSE
    LET tradingAction == ReadBytes(flatPricing.rest, 1) IN IF ~tradingAction.ok THEN Fail ELSE
    LET fillerAscii2 == ReadBytes(tradingAction.rest, 2) IN IF ~fillerAscii2.ok THEN Fail ELSE
    LET symbol == ReadBytes(fillerAscii2.rest, 22) IN IF ~symbol.ok THEN Fail ELSE
    LET cusip == ReadBytes(symbol.rest, 14) IN IF ~cusip.ok THEN Fail ELSE
    Ok([ symbolIndex       |-> symbolIndex.value,
         sourceTime        |-> sourceTime.value,
         quoteLinkId       |-> quoteLinkId.value,
         askPriceNumerator |-> askPriceNumerator.value,
         askSize           |-> askSize.value,
         bidPriceNumerator |-> bidPriceNumerator.value,
         bidSize           |-> bidSize.value,
         priceScaleCode    |-> priceScaleCode.value,
         exchangeId        |-> exchangeId.value,
         securityType      |-> securityType.value,
         quoteCondition    |-> quoteCondition.value,
         flatPricing       |-> flatPricing.value,
         tradingAction     |-> tradingAction.value,
         fillerAscii2      |-> fillerAscii2.value,
         symbol            |-> symbol.value,
         cusip             |-> cusip.value ], cusip.rest)

ZeroRefreshQuoteMessage ==
    [ symbolIndex       |-> [i \in 1 .. 4 |-> 0],
      sourceTime        |-> [i \in 1 .. 4 |-> 0],
      quoteLinkId       |-> [i \in 1 .. 4 |-> 0],
      askPriceNumerator |-> [i \in 1 .. 4 |-> 0],
      askSize           |-> [i \in 1 .. 4 |-> 0],
      bidPriceNumerator |-> [i \in 1 .. 4 |-> 0],
      bidSize           |-> [i \in 1 .. 4 |-> 0],
      priceScaleCode    |-> [i \in 1 .. 1 |-> 0],
      exchangeId        |-> [i \in 1 .. 1 |-> 0],
      securityType      |-> [i \in 1 .. 1 |-> 0],
      quoteCondition    |-> [i \in 1 .. 1 |-> 0],
      flatPricing       |-> [i \in 1 .. 1 |-> 0],
      tradingAction     |-> [i \in 1 .. 1 |-> 0],
      fillerAscii2      |-> [i \in 1 .. 2 |-> 0],
      symbol            |-> [i \in 1 .. 22 |-> 0],
      cusip             |-> [i \in 1 .. 14 |-> 0] ]

(* Refresh Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedRefreshQuoteMessage ==
    { ZeroRefreshQuoteMessage }
        \cup { [ZeroRefreshQuoteMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroRefreshQuoteMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroRefreshQuoteMessage EXCEPT !.quoteLinkId = one] : one \in Sample(4) }
        \cup { [ZeroRefreshQuoteMessage EXCEPT !.askPriceNumerator = one] : one \in Sample(4) }
        \cup { [ZeroRefreshQuoteMessage EXCEPT !.askSize = one] : one \in Sample(4) }
        \cup { [ZeroRefreshQuoteMessage EXCEPT !.bidPriceNumerator = one] : one \in Sample(4) }
        \cup { [ZeroRefreshQuoteMessage EXCEPT !.bidSize = one] : one \in Sample(4) }
        \cup { [ZeroRefreshQuoteMessage EXCEPT !.priceScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroRefreshQuoteMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroRefreshQuoteMessage EXCEPT !.securityType = one] : one \in Sample(1) }
        \cup { [ZeroRefreshQuoteMessage EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroRefreshQuoteMessage EXCEPT !.flatPricing = one] : one \in Sample(1) }
        \cup { [ZeroRefreshQuoteMessage EXCEPT !.tradingAction = one] : one \in Sample(1) }
        \cup { [ZeroRefreshQuoteMessage EXCEPT !.fillerAscii2 = one] : one \in Sample(2) }
        \cup { [ZeroRefreshQuoteMessage EXCEPT !.symbol = one] : one \in Sample(22) }
        \cup { [ZeroRefreshQuoteMessage EXCEPT !.cusip = one] : one \in Sample(14) }

(***************************************************************************)
(* Symbol Index Mapping Message: 44 bytes                                  *)
(***************************************************************************)

SymbolIndexMappingMessage ==
    [ symbolIndex  : Sample(4),
      symbol       : Sample(22),
      cusip        : Sample(14),
      fillerAscii4 : Sample(4) ]

EncodeSymbolIndexMappingMessage(message) ==
    message.symbolIndex
        \o message.symbol
        \o message.cusip
        \o message.fillerAscii4

DecodeSymbolIndexMappingMessage(bytes) ==
    LET symbolIndex == ReadBytes(bytes, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET symbol == ReadBytes(symbolIndex.rest, 22) IN IF ~symbol.ok THEN Fail ELSE
    LET cusip == ReadBytes(symbol.rest, 14) IN IF ~cusip.ok THEN Fail ELSE
    LET fillerAscii4 == ReadBytes(cusip.rest, 4) IN IF ~fillerAscii4.ok THEN Fail ELSE
    Ok([ symbolIndex  |-> symbolIndex.value,
         symbol       |-> symbol.value,
         cusip        |-> cusip.value,
         fillerAscii4 |-> fillerAscii4.value ], fillerAscii4.rest)

ZeroSymbolIndexMappingMessage ==
    [ symbolIndex  |-> [i \in 1 .. 4 |-> 0],
      symbol       |-> [i \in 1 .. 22 |-> 0],
      cusip        |-> [i \in 1 .. 14 |-> 0],
      fillerAscii4 |-> [i \in 1 .. 4 |-> 0] ]

(* Symbol Index Mapping Message at zero, then each field in turn at the values it is checked at *)
CheckedSymbolIndexMappingMessage ==
    { ZeroSymbolIndexMappingMessage }
        \cup { [ZeroSymbolIndexMappingMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroSymbolIndexMappingMessage EXCEPT !.symbol = one] : one \in Sample(22) }
        \cup { [ZeroSymbolIndexMappingMessage EXCEPT !.cusip = one] : one \in Sample(14) }
        \cup { [ZeroSymbolIndexMappingMessage EXCEPT !.fillerAscii4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Quote Message: 36 bytes                                                 *)
(***************************************************************************)

QuoteMessage ==
    [ symbolIndex       : Sample(4),
      sourceTime        : Sample(4),
      quoteLinkId       : Sample(4),
      askPriceNumerator : Sample(4),
      askSize           : Sample(4),
      bidPriceNumerator : Sample(4),
      bidSize           : Sample(4),
      priceScaleCode    : Sample(1),
      exchangeId        : Sample(1),
      securityType      : Sample(1),
      quoteCondition    : Sample(1),
      flatPricing       : Sample(1),
      tradingAction     : Sample(1),
      fillerAscii2      : Sample(2) ]

EncodeQuoteMessage(message) ==
    message.symbolIndex
        \o message.sourceTime
        \o message.quoteLinkId
        \o message.askPriceNumerator
        \o message.askSize
        \o message.bidPriceNumerator
        \o message.bidSize
        \o message.priceScaleCode
        \o message.exchangeId
        \o message.securityType
        \o message.quoteCondition
        \o message.flatPricing
        \o message.tradingAction
        \o message.fillerAscii2

DecodeQuoteMessage(bytes) ==
    LET symbolIndex == ReadBytes(bytes, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET sourceTime == ReadBytes(symbolIndex.rest, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET quoteLinkId == ReadBytes(sourceTime.rest, 4) IN IF ~quoteLinkId.ok THEN Fail ELSE
    LET askPriceNumerator == ReadBytes(quoteLinkId.rest, 4) IN IF ~askPriceNumerator.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPriceNumerator.rest, 4) IN IF ~askSize.ok THEN Fail ELSE
    LET bidPriceNumerator == ReadBytes(askSize.rest, 4) IN IF ~bidPriceNumerator.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPriceNumerator.rest, 4) IN IF ~bidSize.ok THEN Fail ELSE
    LET priceScaleCode == ReadBytes(bidSize.rest, 1) IN IF ~priceScaleCode.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(priceScaleCode.rest, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET securityType == ReadBytes(exchangeId.rest, 1) IN IF ~securityType.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(securityType.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET flatPricing == ReadBytes(quoteCondition.rest, 1) IN IF ~flatPricing.ok THEN Fail ELSE
    LET tradingAction == ReadBytes(flatPricing.rest, 1) IN IF ~tradingAction.ok THEN Fail ELSE
    LET fillerAscii2 == ReadBytes(tradingAction.rest, 2) IN IF ~fillerAscii2.ok THEN Fail ELSE
    Ok([ symbolIndex       |-> symbolIndex.value,
         sourceTime        |-> sourceTime.value,
         quoteLinkId       |-> quoteLinkId.value,
         askPriceNumerator |-> askPriceNumerator.value,
         askSize           |-> askSize.value,
         bidPriceNumerator |-> bidPriceNumerator.value,
         bidSize           |-> bidSize.value,
         priceScaleCode    |-> priceScaleCode.value,
         exchangeId        |-> exchangeId.value,
         securityType      |-> securityType.value,
         quoteCondition    |-> quoteCondition.value,
         flatPricing       |-> flatPricing.value,
         tradingAction     |-> tradingAction.value,
         fillerAscii2      |-> fillerAscii2.value ], fillerAscii2.rest)

ZeroQuoteMessage ==
    [ symbolIndex       |-> [i \in 1 .. 4 |-> 0],
      sourceTime        |-> [i \in 1 .. 4 |-> 0],
      quoteLinkId       |-> [i \in 1 .. 4 |-> 0],
      askPriceNumerator |-> [i \in 1 .. 4 |-> 0],
      askSize           |-> [i \in 1 .. 4 |-> 0],
      bidPriceNumerator |-> [i \in 1 .. 4 |-> 0],
      bidSize           |-> [i \in 1 .. 4 |-> 0],
      priceScaleCode    |-> [i \in 1 .. 1 |-> 0],
      exchangeId        |-> [i \in 1 .. 1 |-> 0],
      securityType      |-> [i \in 1 .. 1 |-> 0],
      quoteCondition    |-> [i \in 1 .. 1 |-> 0],
      flatPricing       |-> [i \in 1 .. 1 |-> 0],
      tradingAction     |-> [i \in 1 .. 1 |-> 0],
      fillerAscii2      |-> [i \in 1 .. 2 |-> 0] ]

(* Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteMessage ==
    { ZeroQuoteMessage }
        \cup { [ZeroQuoteMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroQuoteMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroQuoteMessage EXCEPT !.quoteLinkId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteMessage EXCEPT !.askPriceNumerator = one] : one \in Sample(4) }
        \cup { [ZeroQuoteMessage EXCEPT !.askSize = one] : one \in Sample(4) }
        \cup { [ZeroQuoteMessage EXCEPT !.bidPriceNumerator = one] : one \in Sample(4) }
        \cup { [ZeroQuoteMessage EXCEPT !.bidSize = one] : one \in Sample(4) }
        \cup { [ZeroQuoteMessage EXCEPT !.priceScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroQuoteMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroQuoteMessage EXCEPT !.securityType = one] : one \in Sample(1) }
        \cup { [ZeroQuoteMessage EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroQuoteMessage EXCEPT !.flatPricing = one] : one \in Sample(1) }
        \cup { [ZeroQuoteMessage EXCEPT !.tradingAction = one] : one \in Sample(1) }
        \cup { [ZeroQuoteMessage EXCEPT !.fillerAscii2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Payload, selected by Msg Type                                           *)
(***************************************************************************)

SequenceNumberResetMessageCode == 1  \* 0x01
HeartbeatMessageCode == 2  \* 0x02
MessageUnavailableMessageCode == 5  \* 0x05
RefreshQuoteMessageCode == 23  \* 0x17
SymbolIndexMappingMessageCode == 26  \* 0x1a
QuoteMessageCode == 141  \* 0x8d

Payload ==
    [ tag : {SequenceNumberResetMessageCode}, body : SequenceNumberResetMessage ]
        \cup [ tag : {HeartbeatMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {MessageUnavailableMessageCode}, body : MessageUnavailableMessage ]
        \cup [ tag : {RefreshQuoteMessageCode}, body : RefreshQuoteMessage ]
        \cup [ tag : {SymbolIndexMappingMessageCode}, body : SymbolIndexMappingMessage ]
        \cup [ tag : {QuoteMessageCode}, body : QuoteMessage ]

EncodePayload(message) ==
    CASE message.tag = SequenceNumberResetMessageCode -> EncodeSequenceNumberResetMessage(message.body)
      [] message.tag = HeartbeatMessageCode -> << >>
      [] message.tag = MessageUnavailableMessageCode -> EncodeMessageUnavailableMessage(message.body)
      [] message.tag = RefreshQuoteMessageCode -> EncodeRefreshQuoteMessage(message.body)
      [] message.tag = SymbolIndexMappingMessageCode -> EncodeSymbolIndexMappingMessage(message.body)
      [] message.tag = QuoteMessageCode -> EncodeQuoteMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = SequenceNumberResetMessageCode -> DecodeSequenceNumberResetMessage(bytes)
              [] tag = HeartbeatMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = MessageUnavailableMessageCode -> DecodeMessageUnavailableMessage(bytes)
              [] tag = RefreshQuoteMessageCode -> DecodeRefreshQuoteMessage(bytes)
              [] tag = SymbolIndexMappingMessageCode -> DecodeSymbolIndexMappingMessage(bytes)
              [] tag = QuoteMessageCode -> DecodeQuoteMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> SequenceNumberResetMessageCode, body |-> ZeroSequenceNumberResetMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> SequenceNumberResetMessageCode, body |-> one] : one \in CheckedSequenceNumberResetMessage }
        \cup { [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> MessageUnavailableMessageCode, body |-> one] : one \in CheckedMessageUnavailableMessage }
        \cup { [tag |-> RefreshQuoteMessageCode, body |-> one] : one \in CheckedRefreshQuoteMessage }
        \cup { [tag |-> SymbolIndexMappingMessageCode, body |-> one] : one \in CheckedSymbolIndexMappingMessage }
        \cup { [tag |-> QuoteMessageCode, body |-> one] : one \in CheckedQuoteMessage }

(***************************************************************************)
(* Message, framed by Msg Size                                             *)
(***************************************************************************)

Message ==
    [ msgSeqNum      : Sample(4),
      sendTime       : Sample(4),
      productId      : Sample(1),
      retransFlag    : Sample(1),
      numBodyEntries : Sample(1),
      filler         : Sample(1),
      payload        : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntBE(message.payload.tag, 2)
        \o message.msgSeqNum
        \o message.sendTime
        \o message.productId
        \o message.retransFlag
        \o message.numBodyEntries
        \o message.filler
        \o EncodePayload(message.payload)

(* Msg Size counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeMessageBody(bytes) ==
    LET msgType == ReadUIntBE(bytes, 2) IN IF ~msgType.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(msgType.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET sendTime == ReadBytes(msgSeqNum.rest, 4) IN IF ~sendTime.ok THEN Fail ELSE
    LET productId == ReadBytes(sendTime.rest, 1) IN IF ~productId.ok THEN Fail ELSE
    LET retransFlag == ReadBytes(productId.rest, 1) IN IF ~retransFlag.ok THEN Fail ELSE
    LET numBodyEntries == ReadBytes(retransFlag.rest, 1) IN IF ~numBodyEntries.ok THEN Fail ELSE
    LET filler == ReadBytes(numBodyEntries.rest, 1) IN IF ~filler.ok THEN Fail ELSE
    LET payload == DecodePayload(msgType.value, filler.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ msgSeqNum      |-> msgSeqNum.value,
         sendTime       |-> sendTime.value,
         productId      |-> productId.value,
         retransFlag    |-> retransFlag.value,
         numBodyEntries |-> numBodyEntries.value,
         filler         |-> filler.value,
         payload        |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroMessage ==
    [ msgSeqNum      |-> [i \in 1 .. 4 |-> 0],
      sendTime       |-> [i \in 1 .. 4 |-> 0],
      productId      |-> [i \in 1 .. 1 |-> 0],
      retransFlag    |-> [i \in 1 .. 1 |-> 0],
      numBodyEntries |-> [i \in 1 .. 1 |-> 0],
      filler         |-> [i \in 1 .. 1 |-> 0],
      payload        |-> ZeroPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroMessage EXCEPT !.sendTime = one] : one \in Sample(4) }
        \cup { [ZeroMessage EXCEPT !.productId = one] : one \in Sample(1) }
        \cup { [ZeroMessage EXCEPT !.retransFlag = one] : one \in Sample(1) }
        \cup { [ZeroMessage EXCEPT !.numBodyEntries = one] : one \in Sample(1) }
        \cup { [ZeroMessage EXCEPT !.filler = one] : one \in Sample(1) }
        \cup { [ZeroMessage EXCEPT !.payload = one] : one \in CheckedPayload }

(* A run of Message, written one after another *)
RECURSIVE EncodeMessageList(_)
EncodeMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMessage(Head(messages)) \o EncodeMessageList(Tail(messages))

(* As many Message as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadMessageAll(_)
ReadMessageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMessageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Message of each kind, for the lists that carry them *)
OneMessage ==
    { [ZeroMessage EXCEPT !.payload = [tag |-> SequenceNumberResetMessageCode, body |-> ZeroSequenceNumberResetMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MessageUnavailableMessageCode, body |-> ZeroMessageUnavailableMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RefreshQuoteMessageCode, body |-> ZeroRefreshQuoteMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SymbolIndexMappingMessageCode, body |-> ZeroSymbolIndexMappingMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> QuoteMessageCode, body |-> ZeroQuoteMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ message : SampleLists(OneMessage) ]

EncodePacket(message) ==
    EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET message == ReadMessageAll(bytes) IN IF ~message.ok THEN Fail ELSE
    Ok([ message |-> message.value ], message.rest)

ZeroPacket ==
    [ message |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
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

(* Every Sequence Number Reset Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSequenceNumberResetMessage ==
    \A message \in CheckedSequenceNumberResetMessage :
        LET read == DecodeSequenceNumberResetMessage(EncodeSequenceNumberResetMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message Unavailable Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageUnavailableMessage ==
    \A message \in CheckedMessageUnavailableMessage :
        LET read == DecodeMessageUnavailableMessage(EncodeMessageUnavailableMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Refresh Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRefreshQuoteMessage ==
    \A message \in CheckedRefreshQuoteMessage :
        LET read == DecodeRefreshQuoteMessage(EncodeRefreshQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol Index Mapping Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolIndexMappingMessage ==
    \A message \in CheckedSymbolIndexMappingMessage :
        LET read == DecodeSymbolIndexMappingMessage(EncodeSymbolIndexMappingMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteMessage ==
    \A message \in CheckedQuoteMessage :
        LET read == DecodeQuoteMessage(EncodeQuoteMessage(message))
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

(* A Payload is selected by the Msg Type it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Msg Size is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
