-------------------- MODULE ArcaEquities_DepthFeed_v1_6 --------------------
(***************************************************************************)
(* New York Stock Exchange Depth Feed v1.6                                 *)
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
(* Note: a Number Msgs of 0 marks Heartbeat and carries no Message.        *)
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
(* Sequence Number Reset Message: 10 bytes                                 *)
(***************************************************************************)

SequenceNumberResetMessage ==
    [ sourceTime   : Sample(4),
      sourceTimeNs : Sample(4),
      productId    : Sample(1),
      channelId    : Sample(1) ]

EncodeSequenceNumberResetMessage(message) ==
    message.sourceTime
        \o message.sourceTimeNs
        \o message.productId
        \o message.channelId

DecodeSequenceNumberResetMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceTimeNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET productId == ReadBytes(sourceTimeNs.rest, 1) IN IF ~productId.ok THEN Fail ELSE
    LET channelId == ReadBytes(productId.rest, 1) IN IF ~channelId.ok THEN Fail ELSE
    Ok([ sourceTime   |-> sourceTime.value,
         sourceTimeNs |-> sourceTimeNs.value,
         productId    |-> productId.value,
         channelId    |-> channelId.value ], channelId.rest)

ZeroSequenceNumberResetMessage ==
    [ sourceTime   |-> [i \in 1 .. 4 |-> 0],
      sourceTimeNs |-> [i \in 1 .. 4 |-> 0],
      productId    |-> [i \in 1 .. 1 |-> 0],
      channelId    |-> [i \in 1 .. 1 |-> 0] ]

(* Sequence Number Reset Message at zero, then each field in turn at the values it is checked at *)
CheckedSequenceNumberResetMessage ==
    { ZeroSequenceNumberResetMessage }
        \cup { [ZeroSequenceNumberResetMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroSequenceNumberResetMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroSequenceNumberResetMessage EXCEPT !.productId = one] : one \in Sample(1) }
        \cup { [ZeroSequenceNumberResetMessage EXCEPT !.channelId = one] : one \in Sample(1) }

(***************************************************************************)
(* Symbol Index Mapping Message: 40 bytes                                  *)
(***************************************************************************)

SymbolIndexMappingMessage ==
    [ symbolIndex     : Sample(4),
      symbol          : Sample(11),
      reserved1       : Sample(1),
      marketId        : Sample(2),
      systemId        : Sample(1),
      exchangeCode    : Sample(1),
      priceScaleCode  : Sample(1),
      securityType    : Sample(1),
      lotSize         : Sample(2),
      prevClosePrice  : Sample(4),
      prevCloseVolume : Sample(4),
      priceResolution : Sample(1),
      roundLot        : Sample(1),
      mpv             : Sample(2),
      unitOfTrade     : Sample(2),
      reserved2       : Sample(2) ]

EncodeSymbolIndexMappingMessage(message) ==
    message.symbolIndex
        \o message.symbol
        \o message.reserved1
        \o message.marketId
        \o message.systemId
        \o message.exchangeCode
        \o message.priceScaleCode
        \o message.securityType
        \o message.lotSize
        \o message.prevClosePrice
        \o message.prevCloseVolume
        \o message.priceResolution
        \o message.roundLot
        \o message.mpv
        \o message.unitOfTrade
        \o message.reserved2

DecodeSymbolIndexMappingMessage(bytes) ==
    LET symbolIndex == ReadBytes(bytes, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET symbol == ReadBytes(symbolIndex.rest, 11) IN IF ~symbol.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(symbol.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET marketId == ReadBytes(reserved1.rest, 2) IN IF ~marketId.ok THEN Fail ELSE
    LET systemId == ReadBytes(marketId.rest, 1) IN IF ~systemId.ok THEN Fail ELSE
    LET exchangeCode == ReadBytes(systemId.rest, 1) IN IF ~exchangeCode.ok THEN Fail ELSE
    LET priceScaleCode == ReadBytes(exchangeCode.rest, 1) IN IF ~priceScaleCode.ok THEN Fail ELSE
    LET securityType == ReadBytes(priceScaleCode.rest, 1) IN IF ~securityType.ok THEN Fail ELSE
    LET lotSize == ReadBytes(securityType.rest, 2) IN IF ~lotSize.ok THEN Fail ELSE
    LET prevClosePrice == ReadBytes(lotSize.rest, 4) IN IF ~prevClosePrice.ok THEN Fail ELSE
    LET prevCloseVolume == ReadBytes(prevClosePrice.rest, 4) IN IF ~prevCloseVolume.ok THEN Fail ELSE
    LET priceResolution == ReadBytes(prevCloseVolume.rest, 1) IN IF ~priceResolution.ok THEN Fail ELSE
    LET roundLot == ReadBytes(priceResolution.rest, 1) IN IF ~roundLot.ok THEN Fail ELSE
    LET mpv == ReadBytes(roundLot.rest, 2) IN IF ~mpv.ok THEN Fail ELSE
    LET unitOfTrade == ReadBytes(mpv.rest, 2) IN IF ~unitOfTrade.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(unitOfTrade.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    Ok([ symbolIndex     |-> symbolIndex.value,
         symbol          |-> symbol.value,
         reserved1       |-> reserved1.value,
         marketId        |-> marketId.value,
         systemId        |-> systemId.value,
         exchangeCode    |-> exchangeCode.value,
         priceScaleCode  |-> priceScaleCode.value,
         securityType    |-> securityType.value,
         lotSize         |-> lotSize.value,
         prevClosePrice  |-> prevClosePrice.value,
         prevCloseVolume |-> prevCloseVolume.value,
         priceResolution |-> priceResolution.value,
         roundLot        |-> roundLot.value,
         mpv             |-> mpv.value,
         unitOfTrade     |-> unitOfTrade.value,
         reserved2       |-> reserved2.value ], reserved2.rest)

ZeroSymbolIndexMappingMessage ==
    [ symbolIndex     |-> [i \in 1 .. 4 |-> 0],
      symbol          |-> [i \in 1 .. 11 |-> 0],
      reserved1       |-> [i \in 1 .. 1 |-> 0],
      marketId        |-> [i \in 1 .. 2 |-> 0],
      systemId        |-> [i \in 1 .. 1 |-> 0],
      exchangeCode    |-> [i \in 1 .. 1 |-> 0],
      priceScaleCode  |-> [i \in 1 .. 1 |-> 0],
      securityType    |-> [i \in 1 .. 1 |-> 0],
      lotSize         |-> [i \in 1 .. 2 |-> 0],
      prevClosePrice  |-> [i \in 1 .. 4 |-> 0],
      prevCloseVolume |-> [i \in 1 .. 4 |-> 0],
      priceResolution |-> [i \in 1 .. 1 |-> 0],
      roundLot        |-> [i \in 1 .. 1 |-> 0],
      mpv             |-> [i \in 1 .. 2 |-> 0],
      unitOfTrade     |-> [i \in 1 .. 2 |-> 0],
      reserved2       |-> [i \in 1 .. 2 |-> 0] ]

(* Symbol Index Mapping Message at zero, then each field in turn at the values it is checked at *)
CheckedSymbolIndexMappingMessage ==
    { ZeroSymbolIndexMappingMessage }
        \cup { [ZeroSymbolIndexMappingMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroSymbolIndexMappingMessage EXCEPT !.symbol = one] : one \in Sample(11) }
        \cup { [ZeroSymbolIndexMappingMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroSymbolIndexMappingMessage EXCEPT !.marketId = one] : one \in Sample(2) }
        \cup { [ZeroSymbolIndexMappingMessage EXCEPT !.systemId = one] : one \in Sample(1) }
        \cup { [ZeroSymbolIndexMappingMessage EXCEPT !.exchangeCode = one] : one \in Sample(1) }
        \cup { [ZeroSymbolIndexMappingMessage EXCEPT !.priceScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroSymbolIndexMappingMessage EXCEPT !.securityType = one] : one \in Sample(1) }
        \cup { [ZeroSymbolIndexMappingMessage EXCEPT !.lotSize = one] : one \in Sample(2) }
        \cup { [ZeroSymbolIndexMappingMessage EXCEPT !.prevClosePrice = one] : one \in Sample(4) }
        \cup { [ZeroSymbolIndexMappingMessage EXCEPT !.prevCloseVolume = one] : one \in Sample(4) }
        \cup { [ZeroSymbolIndexMappingMessage EXCEPT !.priceResolution = one] : one \in Sample(1) }
        \cup { [ZeroSymbolIndexMappingMessage EXCEPT !.roundLot = one] : one \in Sample(1) }
        \cup { [ZeroSymbolIndexMappingMessage EXCEPT !.mpv = one] : one \in Sample(2) }
        \cup { [ZeroSymbolIndexMappingMessage EXCEPT !.unitOfTrade = one] : one \in Sample(2) }
        \cup { [ZeroSymbolIndexMappingMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Symbol Clear Message: 18 bytes                                          *)
(***************************************************************************)

SymbolClearMessage ==
    [ sourceTime       : Sample(4),
      sourceTimeNs     : Sample(4),
      symbolIndex      : Sample(4),
      nextSourceSeqNum : Sample(4),
      marketId         : Sample(2) ]

EncodeSymbolClearMessage(message) ==
    message.sourceTime
        \o message.sourceTimeNs
        \o message.symbolIndex
        \o message.nextSourceSeqNum
        \o message.marketId

DecodeSymbolClearMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceTimeNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(sourceTimeNs.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET nextSourceSeqNum == ReadBytes(symbolIndex.rest, 4) IN IF ~nextSourceSeqNum.ok THEN Fail ELSE
    LET marketId == ReadBytes(nextSourceSeqNum.rest, 2) IN IF ~marketId.ok THEN Fail ELSE
    Ok([ sourceTime       |-> sourceTime.value,
         sourceTimeNs     |-> sourceTimeNs.value,
         symbolIndex      |-> symbolIndex.value,
         nextSourceSeqNum |-> nextSourceSeqNum.value,
         marketId         |-> marketId.value ], marketId.rest)

ZeroSymbolClearMessage ==
    [ sourceTime       |-> [i \in 1 .. 4 |-> 0],
      sourceTimeNs     |-> [i \in 1 .. 4 |-> 0],
      symbolIndex      |-> [i \in 1 .. 4 |-> 0],
      nextSourceSeqNum |-> [i \in 1 .. 4 |-> 0],
      marketId         |-> [i \in 1 .. 2 |-> 0] ]

(* Symbol Clear Message at zero, then each field in turn at the values it is checked at *)
CheckedSymbolClearMessage ==
    { ZeroSymbolClearMessage }
        \cup { [ZeroSymbolClearMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroSymbolClearMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroSymbolClearMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroSymbolClearMessage EXCEPT !.nextSourceSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroSymbolClearMessage EXCEPT !.marketId = one] : one \in Sample(2) }

(***************************************************************************)
(* Security Status Message: 42 bytes                                       *)
(***************************************************************************)

SecurityStatusMessage ==
    [ sourceTime              : Sample(4),
      sourceTimeNs            : Sample(4),
      symbolIndex             : Sample(4),
      symbolSeqNum            : Sample(4),
      securityStatus          : Sample(1),
      haltCondition           : Sample(1),
      marketId                : Sample(2),
      reserved2               : Sample(2),
      price1                  : Sample(4),
      price2                  : Sample(4),
      ssrTriggeringExchangeId : Sample(1),
      ssrTriggeringVolume     : Sample(4),
      time                    : Sample(4),
      ssrState                : Sample(1),
      marketState             : Sample(1),
      sessionState            : Sample(1) ]

EncodeSecurityStatusMessage(message) ==
    message.sourceTime
        \o message.sourceTimeNs
        \o message.symbolIndex
        \o message.symbolSeqNum
        \o message.securityStatus
        \o message.haltCondition
        \o message.marketId
        \o message.reserved2
        \o message.price1
        \o message.price2
        \o message.ssrTriggeringExchangeId
        \o message.ssrTriggeringVolume
        \o message.time
        \o message.ssrState
        \o message.marketState
        \o message.sessionState

DecodeSecurityStatusMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceTimeNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(sourceTimeNs.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET symbolSeqNum == ReadBytes(symbolIndex.rest, 4) IN IF ~symbolSeqNum.ok THEN Fail ELSE
    LET securityStatus == ReadBytes(symbolSeqNum.rest, 1) IN IF ~securityStatus.ok THEN Fail ELSE
    LET haltCondition == ReadBytes(securityStatus.rest, 1) IN IF ~haltCondition.ok THEN Fail ELSE
    LET marketId == ReadBytes(haltCondition.rest, 2) IN IF ~marketId.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(marketId.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET price1 == ReadBytes(reserved2.rest, 4) IN IF ~price1.ok THEN Fail ELSE
    LET price2 == ReadBytes(price1.rest, 4) IN IF ~price2.ok THEN Fail ELSE
    LET ssrTriggeringExchangeId == ReadBytes(price2.rest, 1) IN IF ~ssrTriggeringExchangeId.ok THEN Fail ELSE
    LET ssrTriggeringVolume == ReadBytes(ssrTriggeringExchangeId.rest, 4) IN IF ~ssrTriggeringVolume.ok THEN Fail ELSE
    LET time == ReadBytes(ssrTriggeringVolume.rest, 4) IN IF ~time.ok THEN Fail ELSE
    LET ssrState == ReadBytes(time.rest, 1) IN IF ~ssrState.ok THEN Fail ELSE
    LET marketState == ReadBytes(ssrState.rest, 1) IN IF ~marketState.ok THEN Fail ELSE
    LET sessionState == ReadBytes(marketState.rest, 1) IN IF ~sessionState.ok THEN Fail ELSE
    Ok([ sourceTime              |-> sourceTime.value,
         sourceTimeNs            |-> sourceTimeNs.value,
         symbolIndex             |-> symbolIndex.value,
         symbolSeqNum            |-> symbolSeqNum.value,
         securityStatus          |-> securityStatus.value,
         haltCondition           |-> haltCondition.value,
         marketId                |-> marketId.value,
         reserved2               |-> reserved2.value,
         price1                  |-> price1.value,
         price2                  |-> price2.value,
         ssrTriggeringExchangeId |-> ssrTriggeringExchangeId.value,
         ssrTriggeringVolume     |-> ssrTriggeringVolume.value,
         time                    |-> time.value,
         ssrState                |-> ssrState.value,
         marketState             |-> marketState.value,
         sessionState            |-> sessionState.value ], sessionState.rest)

ZeroSecurityStatusMessage ==
    [ sourceTime              |-> [i \in 1 .. 4 |-> 0],
      sourceTimeNs            |-> [i \in 1 .. 4 |-> 0],
      symbolIndex             |-> [i \in 1 .. 4 |-> 0],
      symbolSeqNum            |-> [i \in 1 .. 4 |-> 0],
      securityStatus          |-> [i \in 1 .. 1 |-> 0],
      haltCondition           |-> [i \in 1 .. 1 |-> 0],
      marketId                |-> [i \in 1 .. 2 |-> 0],
      reserved2               |-> [i \in 1 .. 2 |-> 0],
      price1                  |-> [i \in 1 .. 4 |-> 0],
      price2                  |-> [i \in 1 .. 4 |-> 0],
      ssrTriggeringExchangeId |-> [i \in 1 .. 1 |-> 0],
      ssrTriggeringVolume     |-> [i \in 1 .. 4 |-> 0],
      time                    |-> [i \in 1 .. 4 |-> 0],
      ssrState                |-> [i \in 1 .. 1 |-> 0],
      marketState             |-> [i \in 1 .. 1 |-> 0],
      sessionState            |-> [i \in 1 .. 1 |-> 0] ]

(* Security Status Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityStatusMessage ==
    { ZeroSecurityStatusMessage }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.symbolSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.securityStatus = one] : one \in Sample(1) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.haltCondition = one] : one \in Sample(1) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.marketId = one] : one \in Sample(2) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.price1 = one] : one \in Sample(4) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.price2 = one] : one \in Sample(4) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.ssrTriggeringExchangeId = one] : one \in Sample(1) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.ssrTriggeringVolume = one] : one \in Sample(4) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.time = one] : one \in Sample(4) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.ssrState = one] : one \in Sample(1) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.marketState = one] : one \in Sample(1) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.sessionState = one] : one \in Sample(1) }

(***************************************************************************)
(* Participant: 8 bytes                                                    *)
(***************************************************************************)

Participant ==
    [ marketId       : Sample(2),
      numberOfOrders : Sample(2),
      volume         : Sample(4) ]

EncodeParticipant(message) ==
    message.marketId
        \o message.numberOfOrders
        \o message.volume

DecodeParticipant(bytes) ==
    LET marketId == ReadBytes(bytes, 2) IN IF ~marketId.ok THEN Fail ELSE
    LET numberOfOrders == ReadBytes(marketId.rest, 2) IN IF ~numberOfOrders.ok THEN Fail ELSE
    LET volume == ReadBytes(numberOfOrders.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    Ok([ marketId       |-> marketId.value,
         numberOfOrders |-> numberOfOrders.value,
         volume         |-> volume.value ], volume.rest)

ZeroParticipant ==
    [ marketId       |-> [i \in 1 .. 2 |-> 0],
      numberOfOrders |-> [i \in 1 .. 2 |-> 0],
      volume         |-> [i \in 1 .. 4 |-> 0] ]

(* Participant at zero, then each field in turn at the values it is checked at *)
CheckedParticipant ==
    { ZeroParticipant }
        \cup { [ZeroParticipant EXCEPT !.marketId = one] : one \in Sample(2) }
        \cup { [ZeroParticipant EXCEPT !.numberOfOrders = one] : one \in Sample(2) }
        \cup { [ZeroParticipant EXCEPT !.volume = one] : one \in Sample(4) }

(* A run of Participant, written one after another *)
RECURSIVE EncodeParticipantList(_)
EncodeParticipantList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeParticipant(Head(messages)) \o EncodeParticipantList(Tail(messages))

(* As many Participant as the field that counts them says *)
RECURSIVE ReadParticipantList(_, _)
ReadParticipantList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeParticipant(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadParticipantList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Participant of each kind, for the lists that carry them *)
OneParticipant == { ZeroParticipant }

(***************************************************************************)
(* Price Point                                                             *)
(***************************************************************************)

PricePoint ==
    [ price       : Sample(4),
      side        : Sample(1),
      participant : SampleLists(OneParticipant) ]

EncodePricePoint(message) ==
    message.price
        \o message.side
        \o EncodeUIntLE(Len(message.participant), 1)
        \o EncodeParticipantList(message.participant)

DecodePricePoint(bytes) ==
    LET price == ReadBytes(bytes, 4) IN IF ~price.ok THEN Fail ELSE
    LET side == ReadBytes(price.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET participants == ReadUIntLE(side.rest, 1) IN IF ~participants.ok THEN Fail ELSE
    LET participant == ReadParticipantList(participants.rest, participants.value) IN IF ~participant.ok THEN Fail ELSE
    Ok([ price       |-> price.value,
         side        |-> side.value,
         participant |-> participant.value ], participant.rest)

ZeroPricePoint ==
    [ price       |-> [i \in 1 .. 4 |-> 0],
      side        |-> [i \in 1 .. 1 |-> 0],
      participant |-> << >> ]

(* Price Point at zero, then each field in turn at the values it is checked at *)
CheckedPricePoint ==
    { ZeroPricePoint }
        \cup { [ZeroPricePoint EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroPricePoint EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroPricePoint EXCEPT !.participant = one] : one \in SampleLists(OneParticipant) }

(* A run of Price Point, written one after another *)
RECURSIVE EncodePricePointList(_)
EncodePricePointList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodePricePoint(Head(messages)) \o EncodePricePointList(Tail(messages))

(* As many Price Point as the field that counts them says *)
RECURSIVE ReadPricePointList(_, _)
ReadPricePointList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodePricePoint(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadPricePointList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Price Point of each kind, for the lists that carry them *)
OnePricePoint == { ZeroPricePoint }

(***************************************************************************)
(* Delta Message                                                           *)
(***************************************************************************)

DeltaMessage ==
    [ sourceTime   : Sample(4),
      sourceTimeNs : Sample(4),
      symbolIndex  : Sample(4),
      symbolSeqNum : Sample(4),
      pricePoint   : SampleLists(OnePricePoint) ]

EncodeDeltaMessage(message) ==
    message.sourceTime
        \o message.sourceTimeNs
        \o message.symbolIndex
        \o message.symbolSeqNum
        \o EncodeUIntLE(Len(message.pricePoint), 1)
        \o EncodePricePointList(message.pricePoint)

DecodeDeltaMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceTimeNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(sourceTimeNs.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET symbolSeqNum == ReadBytes(symbolIndex.rest, 4) IN IF ~symbolSeqNum.ok THEN Fail ELSE
    LET updateCount == ReadUIntLE(symbolSeqNum.rest, 1) IN IF ~updateCount.ok THEN Fail ELSE
    LET pricePoint == ReadPricePointList(updateCount.rest, updateCount.value) IN IF ~pricePoint.ok THEN Fail ELSE
    Ok([ sourceTime   |-> sourceTime.value,
         sourceTimeNs |-> sourceTimeNs.value,
         symbolIndex  |-> symbolIndex.value,
         symbolSeqNum |-> symbolSeqNum.value,
         pricePoint   |-> pricePoint.value ], pricePoint.rest)

ZeroDeltaMessage ==
    [ sourceTime   |-> [i \in 1 .. 4 |-> 0],
      sourceTimeNs |-> [i \in 1 .. 4 |-> 0],
      symbolIndex  |-> [i \in 1 .. 4 |-> 0],
      symbolSeqNum |-> [i \in 1 .. 4 |-> 0],
      pricePoint   |-> << >> ]

(* Delta Message at zero, then each field in turn at the values it is checked at *)
CheckedDeltaMessage ==
    { ZeroDeltaMessage }
        \cup { [ZeroDeltaMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroDeltaMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroDeltaMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroDeltaMessage EXCEPT !.symbolSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroDeltaMessage EXCEPT !.pricePoint = one] : one \in SampleLists(OnePricePoint) }

(***************************************************************************)
(* Imbalance Message: 71 bytes                                             *)
(***************************************************************************)

ImbalanceMessage ==
    [ sourceTime                   : Sample(4),
      sourceTimeNs                 : Sample(4),
      symbolIndex                  : Sample(4),
      symbolSeqNum                 : Sample(4),
      referencePrice               : Sample(4),
      pairedQty                    : Sample(4),
      totalImbalanceQty            : Sample(4),
      marketImbalanceQty           : Sample(4),
      auctionTime                  : Sample(2),
      auctionType                  : Sample(1),
      imbalanceSide                : Sample(1),
      continuousBookClearingPrice  : Sample(4),
      auctionInterestClearingPrice : Sample(4),
      ssrFilingPrice               : Sample(4),
      indicativeMatchPrice         : Sample(4),
      upperCollar                  : Sample(4),
      lowerCollar                  : Sample(4),
      auctionStatus                : Sample(1),
      freezeStatus                 : Sample(1),
      numExtensions                : Sample(1),
      unpairedQty                  : Sample(4),
      unpairedSide                 : Sample(1),
      reserved1                    : Sample(1),
      marketId                     : Sample(2) ]

EncodeImbalanceMessage(message) ==
    message.sourceTime
        \o message.sourceTimeNs
        \o message.symbolIndex
        \o message.symbolSeqNum
        \o message.referencePrice
        \o message.pairedQty
        \o message.totalImbalanceQty
        \o message.marketImbalanceQty
        \o message.auctionTime
        \o message.auctionType
        \o message.imbalanceSide
        \o message.continuousBookClearingPrice
        \o message.auctionInterestClearingPrice
        \o message.ssrFilingPrice
        \o message.indicativeMatchPrice
        \o message.upperCollar
        \o message.lowerCollar
        \o message.auctionStatus
        \o message.freezeStatus
        \o message.numExtensions
        \o message.unpairedQty
        \o message.unpairedSide
        \o message.reserved1
        \o message.marketId

DecodeImbalanceMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceTimeNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(sourceTimeNs.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET symbolSeqNum == ReadBytes(symbolIndex.rest, 4) IN IF ~symbolSeqNum.ok THEN Fail ELSE
    LET referencePrice == ReadBytes(symbolSeqNum.rest, 4) IN IF ~referencePrice.ok THEN Fail ELSE
    LET pairedQty == ReadBytes(referencePrice.rest, 4) IN IF ~pairedQty.ok THEN Fail ELSE
    LET totalImbalanceQty == ReadBytes(pairedQty.rest, 4) IN IF ~totalImbalanceQty.ok THEN Fail ELSE
    LET marketImbalanceQty == ReadBytes(totalImbalanceQty.rest, 4) IN IF ~marketImbalanceQty.ok THEN Fail ELSE
    LET auctionTime == ReadBytes(marketImbalanceQty.rest, 2) IN IF ~auctionTime.ok THEN Fail ELSE
    LET auctionType == ReadBytes(auctionTime.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET imbalanceSide == ReadBytes(auctionType.rest, 1) IN IF ~imbalanceSide.ok THEN Fail ELSE
    LET continuousBookClearingPrice == ReadBytes(imbalanceSide.rest, 4) IN IF ~continuousBookClearingPrice.ok THEN Fail ELSE
    LET auctionInterestClearingPrice == ReadBytes(continuousBookClearingPrice.rest, 4) IN IF ~auctionInterestClearingPrice.ok THEN Fail ELSE
    LET ssrFilingPrice == ReadBytes(auctionInterestClearingPrice.rest, 4) IN IF ~ssrFilingPrice.ok THEN Fail ELSE
    LET indicativeMatchPrice == ReadBytes(ssrFilingPrice.rest, 4) IN IF ~indicativeMatchPrice.ok THEN Fail ELSE
    LET upperCollar == ReadBytes(indicativeMatchPrice.rest, 4) IN IF ~upperCollar.ok THEN Fail ELSE
    LET lowerCollar == ReadBytes(upperCollar.rest, 4) IN IF ~lowerCollar.ok THEN Fail ELSE
    LET auctionStatus == ReadBytes(lowerCollar.rest, 1) IN IF ~auctionStatus.ok THEN Fail ELSE
    LET freezeStatus == ReadBytes(auctionStatus.rest, 1) IN IF ~freezeStatus.ok THEN Fail ELSE
    LET numExtensions == ReadBytes(freezeStatus.rest, 1) IN IF ~numExtensions.ok THEN Fail ELSE
    LET unpairedQty == ReadBytes(numExtensions.rest, 4) IN IF ~unpairedQty.ok THEN Fail ELSE
    LET unpairedSide == ReadBytes(unpairedQty.rest, 1) IN IF ~unpairedSide.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(unpairedSide.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET marketId == ReadBytes(reserved1.rest, 2) IN IF ~marketId.ok THEN Fail ELSE
    Ok([ sourceTime                   |-> sourceTime.value,
         sourceTimeNs                 |-> sourceTimeNs.value,
         symbolIndex                  |-> symbolIndex.value,
         symbolSeqNum                 |-> symbolSeqNum.value,
         referencePrice               |-> referencePrice.value,
         pairedQty                    |-> pairedQty.value,
         totalImbalanceQty            |-> totalImbalanceQty.value,
         marketImbalanceQty           |-> marketImbalanceQty.value,
         auctionTime                  |-> auctionTime.value,
         auctionType                  |-> auctionType.value,
         imbalanceSide                |-> imbalanceSide.value,
         continuousBookClearingPrice  |-> continuousBookClearingPrice.value,
         auctionInterestClearingPrice |-> auctionInterestClearingPrice.value,
         ssrFilingPrice               |-> ssrFilingPrice.value,
         indicativeMatchPrice         |-> indicativeMatchPrice.value,
         upperCollar                  |-> upperCollar.value,
         lowerCollar                  |-> lowerCollar.value,
         auctionStatus                |-> auctionStatus.value,
         freezeStatus                 |-> freezeStatus.value,
         numExtensions                |-> numExtensions.value,
         unpairedQty                  |-> unpairedQty.value,
         unpairedSide                 |-> unpairedSide.value,
         reserved1                    |-> reserved1.value,
         marketId                     |-> marketId.value ], marketId.rest)

ZeroImbalanceMessage ==
    [ sourceTime                   |-> [i \in 1 .. 4 |-> 0],
      sourceTimeNs                 |-> [i \in 1 .. 4 |-> 0],
      symbolIndex                  |-> [i \in 1 .. 4 |-> 0],
      symbolSeqNum                 |-> [i \in 1 .. 4 |-> 0],
      referencePrice               |-> [i \in 1 .. 4 |-> 0],
      pairedQty                    |-> [i \in 1 .. 4 |-> 0],
      totalImbalanceQty            |-> [i \in 1 .. 4 |-> 0],
      marketImbalanceQty           |-> [i \in 1 .. 4 |-> 0],
      auctionTime                  |-> [i \in 1 .. 2 |-> 0],
      auctionType                  |-> [i \in 1 .. 1 |-> 0],
      imbalanceSide                |-> [i \in 1 .. 1 |-> 0],
      continuousBookClearingPrice  |-> [i \in 1 .. 4 |-> 0],
      auctionInterestClearingPrice |-> [i \in 1 .. 4 |-> 0],
      ssrFilingPrice               |-> [i \in 1 .. 4 |-> 0],
      indicativeMatchPrice         |-> [i \in 1 .. 4 |-> 0],
      upperCollar                  |-> [i \in 1 .. 4 |-> 0],
      lowerCollar                  |-> [i \in 1 .. 4 |-> 0],
      auctionStatus                |-> [i \in 1 .. 1 |-> 0],
      freezeStatus                 |-> [i \in 1 .. 1 |-> 0],
      numExtensions                |-> [i \in 1 .. 1 |-> 0],
      unpairedQty                  |-> [i \in 1 .. 4 |-> 0],
      unpairedSide                 |-> [i \in 1 .. 1 |-> 0],
      reserved1                    |-> [i \in 1 .. 1 |-> 0],
      marketId                     |-> [i \in 1 .. 2 |-> 0] ]

(* Imbalance Message at zero, then each field in turn at the values it is checked at *)
CheckedImbalanceMessage ==
    { ZeroImbalanceMessage }
        \cup { [ZeroImbalanceMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroImbalanceMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroImbalanceMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroImbalanceMessage EXCEPT !.symbolSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroImbalanceMessage EXCEPT !.referencePrice = one] : one \in Sample(4) }
        \cup { [ZeroImbalanceMessage EXCEPT !.pairedQty = one] : one \in Sample(4) }
        \cup { [ZeroImbalanceMessage EXCEPT !.totalImbalanceQty = one] : one \in Sample(4) }
        \cup { [ZeroImbalanceMessage EXCEPT !.marketImbalanceQty = one] : one \in Sample(4) }
        \cup { [ZeroImbalanceMessage EXCEPT !.auctionTime = one] : one \in Sample(2) }
        \cup { [ZeroImbalanceMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroImbalanceMessage EXCEPT !.imbalanceSide = one] : one \in Sample(1) }
        \cup { [ZeroImbalanceMessage EXCEPT !.continuousBookClearingPrice = one] : one \in Sample(4) }
        \cup { [ZeroImbalanceMessage EXCEPT !.auctionInterestClearingPrice = one] : one \in Sample(4) }
        \cup { [ZeroImbalanceMessage EXCEPT !.ssrFilingPrice = one] : one \in Sample(4) }
        \cup { [ZeroImbalanceMessage EXCEPT !.indicativeMatchPrice = one] : one \in Sample(4) }
        \cup { [ZeroImbalanceMessage EXCEPT !.upperCollar = one] : one \in Sample(4) }
        \cup { [ZeroImbalanceMessage EXCEPT !.lowerCollar = one] : one \in Sample(4) }
        \cup { [ZeroImbalanceMessage EXCEPT !.auctionStatus = one] : one \in Sample(1) }
        \cup { [ZeroImbalanceMessage EXCEPT !.freezeStatus = one] : one \in Sample(1) }
        \cup { [ZeroImbalanceMessage EXCEPT !.numExtensions = one] : one \in Sample(1) }
        \cup { [ZeroImbalanceMessage EXCEPT !.unpairedQty = one] : one \in Sample(4) }
        \cup { [ZeroImbalanceMessage EXCEPT !.unpairedSide = one] : one \in Sample(1) }
        \cup { [ZeroImbalanceMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroImbalanceMessage EXCEPT !.marketId = one] : one \in Sample(2) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

SequenceNumberResetMessageCode == 1  \* 0x01
SymbolIndexMappingMessageCode == 3  \* 0x03
SymbolClearMessageCode == 32  \* 0x20
SecurityStatusMessageCode == 34  \* 0x22
DeltaMessageCode == 115  \* 0x73
ImbalanceMessageCode == 105  \* 0x69

Payload ==
    [ tag : {SequenceNumberResetMessageCode}, body : SequenceNumberResetMessage ]
        \cup [ tag : {SymbolIndexMappingMessageCode}, body : SymbolIndexMappingMessage ]
        \cup [ tag : {SymbolClearMessageCode}, body : SymbolClearMessage ]
        \cup [ tag : {SecurityStatusMessageCode}, body : SecurityStatusMessage ]
        \cup [ tag : {DeltaMessageCode}, body : DeltaMessage ]
        \cup [ tag : {ImbalanceMessageCode}, body : ImbalanceMessage ]

EncodePayload(message) ==
    CASE message.tag = SequenceNumberResetMessageCode -> EncodeSequenceNumberResetMessage(message.body)
      [] message.tag = SymbolIndexMappingMessageCode -> EncodeSymbolIndexMappingMessage(message.body)
      [] message.tag = SymbolClearMessageCode -> EncodeSymbolClearMessage(message.body)
      [] message.tag = SecurityStatusMessageCode -> EncodeSecurityStatusMessage(message.body)
      [] message.tag = DeltaMessageCode -> EncodeDeltaMessage(message.body)
      [] message.tag = ImbalanceMessageCode -> EncodeImbalanceMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = SequenceNumberResetMessageCode -> DecodeSequenceNumberResetMessage(bytes)
              [] tag = SymbolIndexMappingMessageCode -> DecodeSymbolIndexMappingMessage(bytes)
              [] tag = SymbolClearMessageCode -> DecodeSymbolClearMessage(bytes)
              [] tag = SecurityStatusMessageCode -> DecodeSecurityStatusMessage(bytes)
              [] tag = DeltaMessageCode -> DecodeDeltaMessage(bytes)
              [] tag = ImbalanceMessageCode -> DecodeImbalanceMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> SequenceNumberResetMessageCode, body |-> ZeroSequenceNumberResetMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> SequenceNumberResetMessageCode, body |-> one] : one \in CheckedSequenceNumberResetMessage }
        \cup { [tag |-> SymbolIndexMappingMessageCode, body |-> one] : one \in CheckedSymbolIndexMappingMessage }
        \cup { [tag |-> SymbolClearMessageCode, body |-> one] : one \in CheckedSymbolClearMessage }
        \cup { [tag |-> SecurityStatusMessageCode, body |-> one] : one \in CheckedSecurityStatusMessage }
        \cup { [tag |-> DeltaMessageCode, body |-> one] : one \in CheckedDeltaMessage }
        \cup { [tag |-> ImbalanceMessageCode, body |-> one] : one \in CheckedImbalanceMessage }

(***************************************************************************)
(* Message, framed by Message Size                                         *)
(***************************************************************************)

Message ==
    [ payload : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntLE(message.payload.tag, 2)
        \o EncodePayload(message.payload)

(* Message Size counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntLE(bytes, 2) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroMessage ==
    [ payload |-> ZeroPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.payload = one] : one \in CheckedPayload }

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
    { [ZeroMessage EXCEPT !.payload = [tag |-> SequenceNumberResetMessageCode, body |-> ZeroSequenceNumberResetMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SymbolIndexMappingMessageCode, body |-> ZeroSymbolIndexMappingMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SymbolClearMessageCode, body |-> ZeroSymbolClearMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityStatusMessageCode, body |-> ZeroSecurityStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> DeltaMessageCode, body |-> ZeroDeltaMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ImbalanceMessageCode, body |-> ZeroImbalanceMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ pktSize      : Sample(2),
      deliveryFlag : 0 .. 255,
      seqNum       : Sample(4),
      sendTime     : SendTime,
      message      : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.pktSize
        \o EncodeUIntLE(message.deliveryFlag, 1)
        \o EncodeUIntLE(Len(message.message), 1)
        \o message.seqNum
        \o EncodeSendTime(message.sendTime)
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET pktSize == ReadBytes(bytes, 2) IN IF ~pktSize.ok THEN Fail ELSE
    LET deliveryFlag == ReadUIntLE(pktSize.rest, 1) IN IF ~deliveryFlag.ok THEN Fail ELSE
    LET numberMsgs == ReadUIntLE(deliveryFlag.rest, 1) IN IF ~numberMsgs.ok THEN Fail ELSE
    LET seqNum == ReadBytes(numberMsgs.rest, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET sendTime == DecodeSendTime(seqNum.rest) IN IF ~sendTime.ok THEN Fail ELSE
    LET message == ReadMessageList(sendTime.rest, numberMsgs.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ pktSize      |-> pktSize.value,
         deliveryFlag |-> deliveryFlag.value,
         seqNum       |-> seqNum.value,
         sendTime     |-> sendTime.value,
         message      |-> message.value ], message.rest)

ZeroPacket ==
    [ pktSize      |-> [i \in 1 .. 2 |-> 0],
      deliveryFlag |-> 0,
      seqNum       |-> [i \in 1 .. 4 |-> 0],
      sendTime     |-> ZeroSendTime,
      message      |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.pktSize = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.deliveryFlag = one] : one \in {0, 1, 255} }
        \cup { [ZeroPacket EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.sendTime = one] : one \in CheckedSendTime }
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

(* Every Send Time decodes back to what was encoded, and leaves nothing over *)
RoundTripSendTime ==
    \A message \in CheckedSendTime :
        LET read == DecodeSendTime(EncodeSendTime(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sequence Number Reset Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSequenceNumberResetMessage ==
    \A message \in CheckedSequenceNumberResetMessage :
        LET read == DecodeSequenceNumberResetMessage(EncodeSequenceNumberResetMessage(message))
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

(* Every Symbol Clear Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolClearMessage ==
    \A message \in CheckedSymbolClearMessage :
        LET read == DecodeSymbolClearMessage(EncodeSymbolClearMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityStatusMessage ==
    \A message \in CheckedSecurityStatusMessage :
        LET read == DecodeSecurityStatusMessage(EncodeSecurityStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Participant decodes back to what was encoded, and leaves nothing over *)
RoundTripParticipant ==
    \A message \in CheckedParticipant :
        LET read == DecodeParticipant(EncodeParticipant(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price Point decodes back to what was encoded, and leaves nothing over *)
RoundTripPricePoint ==
    \A message \in CheckedPricePoint :
        LET read == DecodePricePoint(EncodePricePoint(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Delta Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDeltaMessage ==
    \A message \in CheckedDeltaMessage :
        LET read == DecodeDeltaMessage(EncodeDeltaMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Imbalance Message decodes back to what was encoded, and leaves nothing over *)
RoundTripImbalanceMessage ==
    \A message \in CheckedImbalanceMessage :
        LET read == DecodeImbalanceMessage(EncodeImbalanceMessage(message))
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

(* A Payload is selected by the Message Type it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Message Size is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
