-------------------- MODULE AmexOptions_TopFeed_v1_2_j ---------------------
(***************************************************************************)
(* New York Stock Exchange Top Feed v1.2.j                                 *)
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
(*                                                                         *)
(* Note: a Current Refresh Pkt of any value but 1 carries none of them.    *)
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
(* Source Time Reference Message: 12 bytes                                 *)
(***************************************************************************)

SourceTimeReferenceMessage ==
    [ id           : Sample(4),
      symbolSeqNum : Sample(4),
      sourceTime   : Sample(4) ]

EncodeSourceTimeReferenceMessage(message) ==
    message.id
        \o message.symbolSeqNum
        \o message.sourceTime

DecodeSourceTimeReferenceMessage(bytes) ==
    LET id == ReadBytes(bytes, 4) IN IF ~id.ok THEN Fail ELSE
    LET symbolSeqNum == ReadBytes(id.rest, 4) IN IF ~symbolSeqNum.ok THEN Fail ELSE
    LET sourceTime == ReadBytes(symbolSeqNum.rest, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    Ok([ id           |-> id.value,
         symbolSeqNum |-> symbolSeqNum.value,
         sourceTime   |-> sourceTime.value ], sourceTime.rest)

ZeroSourceTimeReferenceMessage ==
    [ id           |-> [i \in 1 .. 4 |-> 0],
      symbolSeqNum |-> [i \in 1 .. 4 |-> 0],
      sourceTime   |-> [i \in 1 .. 4 |-> 0] ]

(* Source Time Reference Message at zero, then each field in turn at the values it is checked at *)
CheckedSourceTimeReferenceMessage ==
    { ZeroSourceTimeReferenceMessage }
        \cup { [ZeroSourceTimeReferenceMessage EXCEPT !.id = one] : one \in Sample(4) }
        \cup { [ZeroSourceTimeReferenceMessage EXCEPT !.symbolSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroSourceTimeReferenceMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }

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
      reserved2       : Sample(2),
      secondReserved2 : Sample(2),
      thirdReserved2  : Sample(2) ]

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
        \o message.reserved2
        \o message.secondReserved2
        \o message.thirdReserved2

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
    LET reserved2 == ReadBytes(roundLot.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET secondReserved2 == ReadBytes(reserved2.rest, 2) IN IF ~secondReserved2.ok THEN Fail ELSE
    LET thirdReserved2 == ReadBytes(secondReserved2.rest, 2) IN IF ~thirdReserved2.ok THEN Fail ELSE
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
         reserved2       |-> reserved2.value,
         secondReserved2 |-> secondReserved2.value,
         thirdReserved2  |-> thirdReserved2.value ], thirdReserved2.rest)

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
      reserved2       |-> [i \in 1 .. 2 |-> 0],
      secondReserved2 |-> [i \in 1 .. 2 |-> 0],
      thirdReserved2  |-> [i \in 1 .. 2 |-> 0] ]

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
        \cup { [ZeroSymbolIndexMappingMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroSymbolIndexMappingMessage EXCEPT !.secondReserved2 = one] : one \in Sample(2) }
        \cup { [ZeroSymbolIndexMappingMessage EXCEPT !.thirdReserved2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Symbol Clear Message: 16 bytes                                          *)
(***************************************************************************)

SymbolClearMessage ==
    [ sourceTime       : Sample(4),
      sourceTimeNs     : Sample(4),
      symbolIndex      : Sample(4),
      nextSourceSeqNum : Sample(4) ]

EncodeSymbolClearMessage(message) ==
    message.sourceTime
        \o message.sourceTimeNs
        \o message.symbolIndex
        \o message.nextSourceSeqNum

DecodeSymbolClearMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceTimeNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(sourceTimeNs.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET nextSourceSeqNum == ReadBytes(symbolIndex.rest, 4) IN IF ~nextSourceSeqNum.ok THEN Fail ELSE
    Ok([ sourceTime       |-> sourceTime.value,
         sourceTimeNs     |-> sourceTimeNs.value,
         symbolIndex      |-> symbolIndex.value,
         nextSourceSeqNum |-> nextSourceSeqNum.value ], nextSourceSeqNum.rest)

ZeroSymbolClearMessage ==
    [ sourceTime       |-> [i \in 1 .. 4 |-> 0],
      sourceTimeNs     |-> [i \in 1 .. 4 |-> 0],
      symbolIndex      |-> [i \in 1 .. 4 |-> 0],
      nextSourceSeqNum |-> [i \in 1 .. 4 |-> 0] ]

(* Symbol Clear Message at zero, then each field in turn at the values it is checked at *)
CheckedSymbolClearMessage ==
    { ZeroSymbolClearMessage }
        \cup { [ZeroSymbolClearMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroSymbolClearMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroSymbolClearMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroSymbolClearMessage EXCEPT !.nextSourceSeqNum = one] : one \in Sample(4) }

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
      reserved4               : Sample(4),
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
        \o message.reserved4
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
    LET reserved4 == ReadBytes(haltCondition.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET price1 == ReadBytes(reserved4.rest, 4) IN IF ~price1.ok THEN Fail ELSE
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
         reserved4               |-> reserved4.value,
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
      reserved4               |-> [i \in 1 .. 4 |-> 0],
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
        \cup { [ZeroSecurityStatusMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.price1 = one] : one \in Sample(4) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.price2 = one] : one \in Sample(4) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.ssrTriggeringExchangeId = one] : one \in Sample(1) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.ssrTriggeringVolume = one] : one \in Sample(4) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.time = one] : one \in Sample(4) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.ssrState = one] : one \in Sample(1) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.marketState = one] : one \in Sample(1) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.sessionState = one] : one \in Sample(1) }

(***************************************************************************)
(* Outright Series Index Mapping Message: 51 bytes                         *)
(***************************************************************************)

OutrightSeriesIndexMappingMessage ==
    [ seriesIndex          : Sample(4),
      seriesType           : Sample(1),
      marketId             : Sample(2),
      systemId             : Sample(1),
      optionSymbolRoot     : Sample(6),
      underlyingSymbol     : Sample(11),
      underlyingIndex      : Sample(4),
      priceScaleCode       : Sample(1),
      contractMultiplier   : Sample(2),
      maturityDate         : Sample(6),
      putOrCall            : Sample(1),
      strikePrice          : Sample(10),
      closingOnlyIndicator : Sample(1),
      reserved1            : Sample(1) ]

EncodeOutrightSeriesIndexMappingMessage(message) ==
    message.seriesIndex
        \o message.seriesType
        \o message.marketId
        \o message.systemId
        \o message.optionSymbolRoot
        \o message.underlyingSymbol
        \o message.underlyingIndex
        \o message.priceScaleCode
        \o message.contractMultiplier
        \o message.maturityDate
        \o message.putOrCall
        \o message.strikePrice
        \o message.closingOnlyIndicator
        \o message.reserved1

DecodeOutrightSeriesIndexMappingMessage(bytes) ==
    LET seriesIndex == ReadBytes(bytes, 4) IN IF ~seriesIndex.ok THEN Fail ELSE
    LET seriesType == ReadBytes(seriesIndex.rest, 1) IN IF ~seriesType.ok THEN Fail ELSE
    LET marketId == ReadBytes(seriesType.rest, 2) IN IF ~marketId.ok THEN Fail ELSE
    LET systemId == ReadBytes(marketId.rest, 1) IN IF ~systemId.ok THEN Fail ELSE
    LET optionSymbolRoot == ReadBytes(systemId.rest, 6) IN IF ~optionSymbolRoot.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(optionSymbolRoot.rest, 11) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET underlyingIndex == ReadBytes(underlyingSymbol.rest, 4) IN IF ~underlyingIndex.ok THEN Fail ELSE
    LET priceScaleCode == ReadBytes(underlyingIndex.rest, 1) IN IF ~priceScaleCode.ok THEN Fail ELSE
    LET contractMultiplier == ReadBytes(priceScaleCode.rest, 2) IN IF ~contractMultiplier.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(contractMultiplier.rest, 6) IN IF ~maturityDate.ok THEN Fail ELSE
    LET putOrCall == ReadBytes(maturityDate.rest, 1) IN IF ~putOrCall.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(putOrCall.rest, 10) IN IF ~strikePrice.ok THEN Fail ELSE
    LET closingOnlyIndicator == ReadBytes(strikePrice.rest, 1) IN IF ~closingOnlyIndicator.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(closingOnlyIndicator.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ seriesIndex          |-> seriesIndex.value,
         seriesType           |-> seriesType.value,
         marketId             |-> marketId.value,
         systemId             |-> systemId.value,
         optionSymbolRoot     |-> optionSymbolRoot.value,
         underlyingSymbol     |-> underlyingSymbol.value,
         underlyingIndex      |-> underlyingIndex.value,
         priceScaleCode       |-> priceScaleCode.value,
         contractMultiplier   |-> contractMultiplier.value,
         maturityDate         |-> maturityDate.value,
         putOrCall            |-> putOrCall.value,
         strikePrice          |-> strikePrice.value,
         closingOnlyIndicator |-> closingOnlyIndicator.value,
         reserved1            |-> reserved1.value ], reserved1.rest)

ZeroOutrightSeriesIndexMappingMessage ==
    [ seriesIndex          |-> [i \in 1 .. 4 |-> 0],
      seriesType           |-> [i \in 1 .. 1 |-> 0],
      marketId             |-> [i \in 1 .. 2 |-> 0],
      systemId             |-> [i \in 1 .. 1 |-> 0],
      optionSymbolRoot     |-> [i \in 1 .. 6 |-> 0],
      underlyingSymbol     |-> [i \in 1 .. 11 |-> 0],
      underlyingIndex      |-> [i \in 1 .. 4 |-> 0],
      priceScaleCode       |-> [i \in 1 .. 1 |-> 0],
      contractMultiplier   |-> [i \in 1 .. 2 |-> 0],
      maturityDate         |-> [i \in 1 .. 6 |-> 0],
      putOrCall            |-> [i \in 1 .. 1 |-> 0],
      strikePrice          |-> [i \in 1 .. 10 |-> 0],
      closingOnlyIndicator |-> [i \in 1 .. 1 |-> 0],
      reserved1            |-> [i \in 1 .. 1 |-> 0] ]

(* Outright Series Index Mapping Message at zero, then each field in turn at the values it is checked at *)
CheckedOutrightSeriesIndexMappingMessage ==
    { ZeroOutrightSeriesIndexMappingMessage }
        \cup { [ZeroOutrightSeriesIndexMappingMessage EXCEPT !.seriesIndex = one] : one \in Sample(4) }
        \cup { [ZeroOutrightSeriesIndexMappingMessage EXCEPT !.seriesType = one] : one \in Sample(1) }
        \cup { [ZeroOutrightSeriesIndexMappingMessage EXCEPT !.marketId = one] : one \in Sample(2) }
        \cup { [ZeroOutrightSeriesIndexMappingMessage EXCEPT !.systemId = one] : one \in Sample(1) }
        \cup { [ZeroOutrightSeriesIndexMappingMessage EXCEPT !.optionSymbolRoot = one] : one \in Sample(6) }
        \cup { [ZeroOutrightSeriesIndexMappingMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }
        \cup { [ZeroOutrightSeriesIndexMappingMessage EXCEPT !.underlyingIndex = one] : one \in Sample(4) }
        \cup { [ZeroOutrightSeriesIndexMappingMessage EXCEPT !.priceScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroOutrightSeriesIndexMappingMessage EXCEPT !.contractMultiplier = one] : one \in Sample(2) }
        \cup { [ZeroOutrightSeriesIndexMappingMessage EXCEPT !.maturityDate = one] : one \in Sample(6) }
        \cup { [ZeroOutrightSeriesIndexMappingMessage EXCEPT !.putOrCall = one] : one \in Sample(1) }
        \cup { [ZeroOutrightSeriesIndexMappingMessage EXCEPT !.strikePrice = one] : one \in Sample(10) }
        \cup { [ZeroOutrightSeriesIndexMappingMessage EXCEPT !.closingOnlyIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOutrightSeriesIndexMappingMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Options Status Message: 19 bytes                                        *)
(***************************************************************************)

OptionsStatusMessage ==
    [ sourceTime                 : Sample(4),
      sourceTimeNs               : Sample(4),
      seriesIndex                : Sample(4),
      seriesSeqNum               : Sample(4),
      seriesStatus               : Sample(1),
      marketState                : Sample(1),
      optionsStatusHaltCondition : Sample(1) ]

EncodeOptionsStatusMessage(message) ==
    message.sourceTime
        \o message.sourceTimeNs
        \o message.seriesIndex
        \o message.seriesSeqNum
        \o message.seriesStatus
        \o message.marketState
        \o message.optionsStatusHaltCondition

DecodeOptionsStatusMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceTimeNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET seriesIndex == ReadBytes(sourceTimeNs.rest, 4) IN IF ~seriesIndex.ok THEN Fail ELSE
    LET seriesSeqNum == ReadBytes(seriesIndex.rest, 4) IN IF ~seriesSeqNum.ok THEN Fail ELSE
    LET seriesStatus == ReadBytes(seriesSeqNum.rest, 1) IN IF ~seriesStatus.ok THEN Fail ELSE
    LET marketState == ReadBytes(seriesStatus.rest, 1) IN IF ~marketState.ok THEN Fail ELSE
    LET optionsStatusHaltCondition == ReadBytes(marketState.rest, 1) IN IF ~optionsStatusHaltCondition.ok THEN Fail ELSE
    Ok([ sourceTime                 |-> sourceTime.value,
         sourceTimeNs               |-> sourceTimeNs.value,
         seriesIndex                |-> seriesIndex.value,
         seriesSeqNum               |-> seriesSeqNum.value,
         seriesStatus               |-> seriesStatus.value,
         marketState                |-> marketState.value,
         optionsStatusHaltCondition |-> optionsStatusHaltCondition.value ], optionsStatusHaltCondition.rest)

ZeroOptionsStatusMessage ==
    [ sourceTime                 |-> [i \in 1 .. 4 |-> 0],
      sourceTimeNs               |-> [i \in 1 .. 4 |-> 0],
      seriesIndex                |-> [i \in 1 .. 4 |-> 0],
      seriesSeqNum               |-> [i \in 1 .. 4 |-> 0],
      seriesStatus               |-> [i \in 1 .. 1 |-> 0],
      marketState                |-> [i \in 1 .. 1 |-> 0],
      optionsStatusHaltCondition |-> [i \in 1 .. 1 |-> 0] ]

(* Options Status Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionsStatusMessage ==
    { ZeroOptionsStatusMessage }
        \cup { [ZeroOptionsStatusMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroOptionsStatusMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroOptionsStatusMessage EXCEPT !.seriesIndex = one] : one \in Sample(4) }
        \cup { [ZeroOptionsStatusMessage EXCEPT !.seriesSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroOptionsStatusMessage EXCEPT !.seriesStatus = one] : one \in Sample(1) }
        \cup { [ZeroOptionsStatusMessage EXCEPT !.marketState = one] : one \in Sample(1) }
        \cup { [ZeroOptionsStatusMessage EXCEPT !.optionsStatusHaltCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Complex Series Index Mapping Leg: 8 bytes                               *)
(***************************************************************************)

ComplexSeriesIndexMappingLeg ==
    [ symbolIndex     : Sample(4),
      legRatioQty     : Sample(2),
      legSide         : Sample(1),
      legSecurityType : Sample(1) ]

EncodeComplexSeriesIndexMappingLeg(message) ==
    message.symbolIndex
        \o message.legRatioQty
        \o message.legSide
        \o message.legSecurityType

DecodeComplexSeriesIndexMappingLeg(bytes) ==
    LET symbolIndex == ReadBytes(bytes, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET legRatioQty == ReadBytes(symbolIndex.rest, 2) IN IF ~legRatioQty.ok THEN Fail ELSE
    LET legSide == ReadBytes(legRatioQty.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET legSecurityType == ReadBytes(legSide.rest, 1) IN IF ~legSecurityType.ok THEN Fail ELSE
    Ok([ symbolIndex     |-> symbolIndex.value,
         legRatioQty     |-> legRatioQty.value,
         legSide         |-> legSide.value,
         legSecurityType |-> legSecurityType.value ], legSecurityType.rest)

ZeroComplexSeriesIndexMappingLeg ==
    [ symbolIndex     |-> [i \in 1 .. 4 |-> 0],
      legRatioQty     |-> [i \in 1 .. 2 |-> 0],
      legSide         |-> [i \in 1 .. 1 |-> 0],
      legSecurityType |-> [i \in 1 .. 1 |-> 0] ]

(* Complex Series Index Mapping Leg at zero, then each field in turn at the values it is checked at *)
CheckedComplexSeriesIndexMappingLeg ==
    { ZeroComplexSeriesIndexMappingLeg }
        \cup { [ZeroComplexSeriesIndexMappingLeg EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroComplexSeriesIndexMappingLeg EXCEPT !.legRatioQty = one] : one \in Sample(2) }
        \cup { [ZeroComplexSeriesIndexMappingLeg EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroComplexSeriesIndexMappingLeg EXCEPT !.legSecurityType = one] : one \in Sample(1) }

(* A run of Complex Series Index Mapping Leg, written one after another *)
RECURSIVE EncodeComplexSeriesIndexMappingLegList(_)
EncodeComplexSeriesIndexMappingLegList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeComplexSeriesIndexMappingLeg(Head(messages)) \o EncodeComplexSeriesIndexMappingLegList(Tail(messages))

(* As many Complex Series Index Mapping Leg as the field that counts them says *)
RECURSIVE ReadComplexSeriesIndexMappingLegList(_, _)
ReadComplexSeriesIndexMappingLegList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeComplexSeriesIndexMappingLeg(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadComplexSeriesIndexMappingLegList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Complex Series Index Mapping Leg of each kind, for the lists that carry them *)
OneComplexSeriesIndexMappingLeg == { ZeroComplexSeriesIndexMappingLeg }

(***************************************************************************)
(* Complex Series Index Mapping Message                                    *)
(***************************************************************************)

ComplexSeriesIndexMappingMessage ==
    [ seriesIndex                  : Sample(4),
      marketId                     : Sample(2),
      systemId                     : Sample(1),
      complexSeriesIndexMappingLeg : SampleLists(OneComplexSeriesIndexMappingLeg) ]

EncodeComplexSeriesIndexMappingMessage(message) ==
    message.seriesIndex
        \o message.marketId
        \o message.systemId
        \o EncodeUIntLE(Len(message.complexSeriesIndexMappingLeg), 2)
        \o EncodeComplexSeriesIndexMappingLegList(message.complexSeriesIndexMappingLeg)

DecodeComplexSeriesIndexMappingMessage(bytes) ==
    LET seriesIndex == ReadBytes(bytes, 4) IN IF ~seriesIndex.ok THEN Fail ELSE
    LET marketId == ReadBytes(seriesIndex.rest, 2) IN IF ~marketId.ok THEN Fail ELSE
    LET systemId == ReadBytes(marketId.rest, 1) IN IF ~systemId.ok THEN Fail ELSE
    LET noOfLegs == ReadUIntLE(systemId.rest, 2) IN IF ~noOfLegs.ok THEN Fail ELSE
    LET complexSeriesIndexMappingLeg == ReadComplexSeriesIndexMappingLegList(noOfLegs.rest, noOfLegs.value) IN IF ~complexSeriesIndexMappingLeg.ok THEN Fail ELSE
    Ok([ seriesIndex                  |-> seriesIndex.value,
         marketId                     |-> marketId.value,
         systemId                     |-> systemId.value,
         complexSeriesIndexMappingLeg |-> complexSeriesIndexMappingLeg.value ], complexSeriesIndexMappingLeg.rest)

ZeroComplexSeriesIndexMappingMessage ==
    [ seriesIndex                  |-> [i \in 1 .. 4 |-> 0],
      marketId                     |-> [i \in 1 .. 2 |-> 0],
      systemId                     |-> [i \in 1 .. 1 |-> 0],
      complexSeriesIndexMappingLeg |-> << >> ]

(* Complex Series Index Mapping Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexSeriesIndexMappingMessage ==
    { ZeroComplexSeriesIndexMappingMessage }
        \cup { [ZeroComplexSeriesIndexMappingMessage EXCEPT !.seriesIndex = one] : one \in Sample(4) }
        \cup { [ZeroComplexSeriesIndexMappingMessage EXCEPT !.marketId = one] : one \in Sample(2) }
        \cup { [ZeroComplexSeriesIndexMappingMessage EXCEPT !.systemId = one] : one \in Sample(1) }
        \cup { [ZeroComplexSeriesIndexMappingMessage EXCEPT !.complexSeriesIndexMappingLeg = one] : one \in SampleLists(OneComplexSeriesIndexMappingLeg) }

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
(* Full Refresh Header: 8 bytes                                            *)
(***************************************************************************)

FullRefreshHeader ==
    [ lastSeqNum       : Sample(4),
      lastSymbolSeqNum : Sample(4) ]

EncodeFullRefreshHeader(message) ==
    message.lastSeqNum
        \o message.lastSymbolSeqNum

DecodeFullRefreshHeader(bytes) ==
    LET lastSeqNum == ReadBytes(bytes, 4) IN IF ~lastSeqNum.ok THEN Fail ELSE
    LET lastSymbolSeqNum == ReadBytes(lastSeqNum.rest, 4) IN IF ~lastSymbolSeqNum.ok THEN Fail ELSE
    Ok([ lastSeqNum       |-> lastSeqNum.value,
         lastSymbolSeqNum |-> lastSymbolSeqNum.value ], lastSymbolSeqNum.rest)

ZeroFullRefreshHeader ==
    [ lastSeqNum       |-> [i \in 1 .. 4 |-> 0],
      lastSymbolSeqNum |-> [i \in 1 .. 4 |-> 0] ]

(* Full Refresh Header at zero, then each field in turn at the values it is checked at *)
CheckedFullRefreshHeader ==
    { ZeroFullRefreshHeader }
        \cup { [ZeroFullRefreshHeader EXCEPT !.lastSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroFullRefreshHeader EXCEPT !.lastSymbolSeqNum = one] : one \in Sample(4) }

(***************************************************************************)
(* What Current Refresh Pkt decides is present                             *)
(***************************************************************************)

FullRefreshHeaderCode == 1  \* 0x01
CurrentRefreshPktNoneCode == 0  \* 

CurrentRefreshPktChoice ==
    [ tag : {FullRefreshHeaderCode}, body : FullRefreshHeader ]
        \cup [ tag : {CurrentRefreshPktNoneCode}, body : {[empty |-> 0]} ]

EncodeCurrentRefreshPktChoice(message) ==
    CASE message.tag = FullRefreshHeaderCode -> EncodeFullRefreshHeader(message.body)
      [] OTHER -> << >>

DecodeCurrentRefreshPktChoice(tag, bytes) ==
    LET read ==
            CASE tag = FullRefreshHeaderCode -> DecodeFullRefreshHeader(bytes)
              [] OTHER -> Ok([empty |-> 0], bytes)
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroCurrentRefreshPktChoice == [tag |-> FullRefreshHeaderCode, body |-> ZeroFullRefreshHeader]

(* Each Current Refresh Pkt in turn, at the values the message it names is checked at *)
CheckedCurrentRefreshPktChoice ==
    { [tag |-> FullRefreshHeaderCode, body |-> one] : one \in CheckedFullRefreshHeader }
        \cup { [tag |-> CurrentRefreshPktNoneCode, body |-> [empty |-> 0]] }

(***************************************************************************)
(* Refresh Header Message                                                  *)
(***************************************************************************)

RefreshHeaderMessage ==
    [ totalRefreshPkts        : Sample(2),
      currentRefreshPktChoice : CurrentRefreshPktChoice ]

EncodeRefreshHeaderMessage(message) ==
    EncodeUIntLE(message.currentRefreshPktChoice.tag, 2)
        \o message.totalRefreshPkts
        \o EncodeCurrentRefreshPktChoice(message.currentRefreshPktChoice)

DecodeRefreshHeaderMessage(bytes) ==
    LET currentRefreshPkt == ReadUIntLE(bytes, 2) IN IF ~currentRefreshPkt.ok THEN Fail ELSE
    LET totalRefreshPkts == ReadBytes(currentRefreshPkt.rest, 2) IN IF ~totalRefreshPkts.ok THEN Fail ELSE
    LET currentRefreshPktChoice == DecodeCurrentRefreshPktChoice(currentRefreshPkt.value, totalRefreshPkts.rest) IN IF ~currentRefreshPktChoice.ok THEN Fail ELSE
    Ok([ totalRefreshPkts        |-> totalRefreshPkts.value,
         currentRefreshPktChoice |-> currentRefreshPktChoice.value ], currentRefreshPktChoice.rest)

ZeroRefreshHeaderMessage ==
    [ totalRefreshPkts        |-> [i \in 1 .. 2 |-> 0],
      currentRefreshPktChoice |-> ZeroCurrentRefreshPktChoice ]

(* Refresh Header Message at zero, then each field in turn at the values it is checked at *)
CheckedRefreshHeaderMessage ==
    { ZeroRefreshHeaderMessage }
        \cup { [ZeroRefreshHeaderMessage EXCEPT !.totalRefreshPkts = one] : one \in Sample(2) }
        \cup { [ZeroRefreshHeaderMessage EXCEPT !.currentRefreshPktChoice = one] : one \in CheckedCurrentRefreshPktChoice }

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
(* Message Unavailable Message: 10 bytes                                   *)
(***************************************************************************)

MessageUnavailableMessage ==
    [ beginSeqNum : Sample(4),
      endSeqNum   : Sample(4),
      productId   : Sample(1),
      channelId   : Sample(1) ]

EncodeMessageUnavailableMessage(message) ==
    message.beginSeqNum
        \o message.endSeqNum
        \o message.productId
        \o message.channelId

DecodeMessageUnavailableMessage(bytes) ==
    LET beginSeqNum == ReadBytes(bytes, 4) IN IF ~beginSeqNum.ok THEN Fail ELSE
    LET endSeqNum == ReadBytes(beginSeqNum.rest, 4) IN IF ~endSeqNum.ok THEN Fail ELSE
    LET productId == ReadBytes(endSeqNum.rest, 1) IN IF ~productId.ok THEN Fail ELSE
    LET channelId == ReadBytes(productId.rest, 1) IN IF ~channelId.ok THEN Fail ELSE
    Ok([ beginSeqNum |-> beginSeqNum.value,
         endSeqNum   |-> endSeqNum.value,
         productId   |-> productId.value,
         channelId   |-> channelId.value ], channelId.rest)

ZeroMessageUnavailableMessage ==
    [ beginSeqNum |-> [i \in 1 .. 4 |-> 0],
      endSeqNum   |-> [i \in 1 .. 4 |-> 0],
      productId   |-> [i \in 1 .. 1 |-> 0],
      channelId   |-> [i \in 1 .. 1 |-> 0] ]

(* Message Unavailable Message at zero, then each field in turn at the values it is checked at *)
CheckedMessageUnavailableMessage ==
    { ZeroMessageUnavailableMessage }
        \cup { [ZeroMessageUnavailableMessage EXCEPT !.beginSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroMessageUnavailableMessage EXCEPT !.endSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroMessageUnavailableMessage EXCEPT !.productId = one] : one \in Sample(1) }
        \cup { [ZeroMessageUnavailableMessage EXCEPT !.channelId = one] : one \in Sample(1) }

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
(* Options Quote Message: 38 bytes                                         *)
(***************************************************************************)

OptionsQuoteMessage ==
    [ sourceTimeNs      : Sample(4),
      seriesIndex       : Sample(4),
      seriesSeqNum      : Sample(4),
      askPrice          : Sample(4),
      askVolume         : Sample(4),
      bidPrice          : Sample(4),
      bidVolume         : Sample(4),
      quoteCondition    : Sample(1),
      reserved1         : Sample(1),
      askCustomerVolume : Sample(4),
      bidCustomerVolume : Sample(4) ]

EncodeOptionsQuoteMessage(message) ==
    message.sourceTimeNs
        \o message.seriesIndex
        \o message.seriesSeqNum
        \o message.askPrice
        \o message.askVolume
        \o message.bidPrice
        \o message.bidVolume
        \o message.quoteCondition
        \o message.reserved1
        \o message.askCustomerVolume
        \o message.bidCustomerVolume

DecodeOptionsQuoteMessage(bytes) ==
    LET sourceTimeNs == ReadBytes(bytes, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET seriesIndex == ReadBytes(sourceTimeNs.rest, 4) IN IF ~seriesIndex.ok THEN Fail ELSE
    LET seriesSeqNum == ReadBytes(seriesIndex.rest, 4) IN IF ~seriesSeqNum.ok THEN Fail ELSE
    LET askPrice == ReadBytes(seriesSeqNum.rest, 4) IN IF ~askPrice.ok THEN Fail ELSE
    LET askVolume == ReadBytes(askPrice.rest, 4) IN IF ~askVolume.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(askVolume.rest, 4) IN IF ~bidPrice.ok THEN Fail ELSE
    LET bidVolume == ReadBytes(bidPrice.rest, 4) IN IF ~bidVolume.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(bidVolume.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(quoteCondition.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET askCustomerVolume == ReadBytes(reserved1.rest, 4) IN IF ~askCustomerVolume.ok THEN Fail ELSE
    LET bidCustomerVolume == ReadBytes(askCustomerVolume.rest, 4) IN IF ~bidCustomerVolume.ok THEN Fail ELSE
    Ok([ sourceTimeNs      |-> sourceTimeNs.value,
         seriesIndex       |-> seriesIndex.value,
         seriesSeqNum      |-> seriesSeqNum.value,
         askPrice          |-> askPrice.value,
         askVolume         |-> askVolume.value,
         bidPrice          |-> bidPrice.value,
         bidVolume         |-> bidVolume.value,
         quoteCondition    |-> quoteCondition.value,
         reserved1         |-> reserved1.value,
         askCustomerVolume |-> askCustomerVolume.value,
         bidCustomerVolume |-> bidCustomerVolume.value ], bidCustomerVolume.rest)

ZeroOptionsQuoteMessage ==
    [ sourceTimeNs      |-> [i \in 1 .. 4 |-> 0],
      seriesIndex       |-> [i \in 1 .. 4 |-> 0],
      seriesSeqNum      |-> [i \in 1 .. 4 |-> 0],
      askPrice          |-> [i \in 1 .. 4 |-> 0],
      askVolume         |-> [i \in 1 .. 4 |-> 0],
      bidPrice          |-> [i \in 1 .. 4 |-> 0],
      bidVolume         |-> [i \in 1 .. 4 |-> 0],
      quoteCondition    |-> [i \in 1 .. 1 |-> 0],
      reserved1         |-> [i \in 1 .. 1 |-> 0],
      askCustomerVolume |-> [i \in 1 .. 4 |-> 0],
      bidCustomerVolume |-> [i \in 1 .. 4 |-> 0] ]

(* Options Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionsQuoteMessage ==
    { ZeroOptionsQuoteMessage }
        \cup { [ZeroOptionsQuoteMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroOptionsQuoteMessage EXCEPT !.seriesIndex = one] : one \in Sample(4) }
        \cup { [ZeroOptionsQuoteMessage EXCEPT !.seriesSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroOptionsQuoteMessage EXCEPT !.askPrice = one] : one \in Sample(4) }
        \cup { [ZeroOptionsQuoteMessage EXCEPT !.askVolume = one] : one \in Sample(4) }
        \cup { [ZeroOptionsQuoteMessage EXCEPT !.bidPrice = one] : one \in Sample(4) }
        \cup { [ZeroOptionsQuoteMessage EXCEPT !.bidVolume = one] : one \in Sample(4) }
        \cup { [ZeroOptionsQuoteMessage EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroOptionsQuoteMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOptionsQuoteMessage EXCEPT !.askCustomerVolume = one] : one \in Sample(4) }
        \cup { [ZeroOptionsQuoteMessage EXCEPT !.bidCustomerVolume = one] : one \in Sample(4) }

(***************************************************************************)
(* Options Trade Message: 32 bytes                                         *)
(***************************************************************************)

OptionsTradeMessage ==
    [ sourceTime   : Sample(4),
      sourceTimeNs : Sample(4),
      seriesIndex  : Sample(4),
      seriesSeqNum : Sample(4),
      tradeId      : Sample(4),
      price        : Sample(4),
      volume       : Sample(4),
      tradeCond1   : Sample(1),
      tradeCond2   : Sample(1),
      reserved1    : Sample(1),
      tradeCond4   : Sample(1) ]

EncodeOptionsTradeMessage(message) ==
    message.sourceTime
        \o message.sourceTimeNs
        \o message.seriesIndex
        \o message.seriesSeqNum
        \o message.tradeId
        \o message.price
        \o message.volume
        \o message.tradeCond1
        \o message.tradeCond2
        \o message.reserved1
        \o message.tradeCond4

DecodeOptionsTradeMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceTimeNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET seriesIndex == ReadBytes(sourceTimeNs.rest, 4) IN IF ~seriesIndex.ok THEN Fail ELSE
    LET seriesSeqNum == ReadBytes(seriesIndex.rest, 4) IN IF ~seriesSeqNum.ok THEN Fail ELSE
    LET tradeId == ReadBytes(seriesSeqNum.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET price == ReadBytes(tradeId.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET volume == ReadBytes(price.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET tradeCond1 == ReadBytes(volume.rest, 1) IN IF ~tradeCond1.ok THEN Fail ELSE
    LET tradeCond2 == ReadBytes(tradeCond1.rest, 1) IN IF ~tradeCond2.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(tradeCond2.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET tradeCond4 == ReadBytes(reserved1.rest, 1) IN IF ~tradeCond4.ok THEN Fail ELSE
    Ok([ sourceTime   |-> sourceTime.value,
         sourceTimeNs |-> sourceTimeNs.value,
         seriesIndex  |-> seriesIndex.value,
         seriesSeqNum |-> seriesSeqNum.value,
         tradeId      |-> tradeId.value,
         price        |-> price.value,
         volume       |-> volume.value,
         tradeCond1   |-> tradeCond1.value,
         tradeCond2   |-> tradeCond2.value,
         reserved1    |-> reserved1.value,
         tradeCond4   |-> tradeCond4.value ], tradeCond4.rest)

ZeroOptionsTradeMessage ==
    [ sourceTime   |-> [i \in 1 .. 4 |-> 0],
      sourceTimeNs |-> [i \in 1 .. 4 |-> 0],
      seriesIndex  |-> [i \in 1 .. 4 |-> 0],
      seriesSeqNum |-> [i \in 1 .. 4 |-> 0],
      tradeId      |-> [i \in 1 .. 4 |-> 0],
      price        |-> [i \in 1 .. 4 |-> 0],
      volume       |-> [i \in 1 .. 4 |-> 0],
      tradeCond1   |-> [i \in 1 .. 1 |-> 0],
      tradeCond2   |-> [i \in 1 .. 1 |-> 0],
      reserved1    |-> [i \in 1 .. 1 |-> 0],
      tradeCond4   |-> [i \in 1 .. 1 |-> 0] ]

(* Options Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionsTradeMessage ==
    { ZeroOptionsTradeMessage }
        \cup { [ZeroOptionsTradeMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroOptionsTradeMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroOptionsTradeMessage EXCEPT !.seriesIndex = one] : one \in Sample(4) }
        \cup { [ZeroOptionsTradeMessage EXCEPT !.seriesSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroOptionsTradeMessage EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroOptionsTradeMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOptionsTradeMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroOptionsTradeMessage EXCEPT !.tradeCond1 = one] : one \in Sample(1) }
        \cup { [ZeroOptionsTradeMessage EXCEPT !.tradeCond2 = one] : one \in Sample(1) }
        \cup { [ZeroOptionsTradeMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOptionsTradeMessage EXCEPT !.tradeCond4 = one] : one \in Sample(1) }

(***************************************************************************)
(* Options Trade Cancel Message: 20 bytes                                  *)
(***************************************************************************)

OptionsTradeCancelMessage ==
    [ sourceTime      : Sample(4),
      sourceTimeNs    : Sample(4),
      seriesIndex     : Sample(4),
      seriesSeqNum    : Sample(4),
      originalTradeId : Sample(4) ]

EncodeOptionsTradeCancelMessage(message) ==
    message.sourceTime
        \o message.sourceTimeNs
        \o message.seriesIndex
        \o message.seriesSeqNum
        \o message.originalTradeId

DecodeOptionsTradeCancelMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceTimeNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET seriesIndex == ReadBytes(sourceTimeNs.rest, 4) IN IF ~seriesIndex.ok THEN Fail ELSE
    LET seriesSeqNum == ReadBytes(seriesIndex.rest, 4) IN IF ~seriesSeqNum.ok THEN Fail ELSE
    LET originalTradeId == ReadBytes(seriesSeqNum.rest, 4) IN IF ~originalTradeId.ok THEN Fail ELSE
    Ok([ sourceTime      |-> sourceTime.value,
         sourceTimeNs    |-> sourceTimeNs.value,
         seriesIndex     |-> seriesIndex.value,
         seriesSeqNum    |-> seriesSeqNum.value,
         originalTradeId |-> originalTradeId.value ], originalTradeId.rest)

ZeroOptionsTradeCancelMessage ==
    [ sourceTime      |-> [i \in 1 .. 4 |-> 0],
      sourceTimeNs    |-> [i \in 1 .. 4 |-> 0],
      seriesIndex     |-> [i \in 1 .. 4 |-> 0],
      seriesSeqNum    |-> [i \in 1 .. 4 |-> 0],
      originalTradeId |-> [i \in 1 .. 4 |-> 0] ]

(* Options Trade Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionsTradeCancelMessage ==
    { ZeroOptionsTradeCancelMessage }
        \cup { [ZeroOptionsTradeCancelMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroOptionsTradeCancelMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroOptionsTradeCancelMessage EXCEPT !.seriesIndex = one] : one \in Sample(4) }
        \cup { [ZeroOptionsTradeCancelMessage EXCEPT !.seriesSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroOptionsTradeCancelMessage EXCEPT !.originalTradeId = one] : one \in Sample(4) }

(***************************************************************************)
(* Options Trade Correction Message: 36 bytes                              *)
(***************************************************************************)

OptionsTradeCorrectionMessage ==
    [ sourceTime      : Sample(4),
      sourceTimeNs    : Sample(4),
      seriesIndex     : Sample(4),
      seriesSeqNum    : Sample(4),
      originalTradeId : Sample(4),
      tradeId         : Sample(4),
      price           : Sample(4),
      volume          : Sample(4),
      tradeCond1      : Sample(1),
      reserved1       : Sample(1),
      secondReserved1 : Sample(1),
      thirdReserved1  : Sample(1) ]

EncodeOptionsTradeCorrectionMessage(message) ==
    message.sourceTime
        \o message.sourceTimeNs
        \o message.seriesIndex
        \o message.seriesSeqNum
        \o message.originalTradeId
        \o message.tradeId
        \o message.price
        \o message.volume
        \o message.tradeCond1
        \o message.reserved1
        \o message.secondReserved1
        \o message.thirdReserved1

DecodeOptionsTradeCorrectionMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceTimeNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET seriesIndex == ReadBytes(sourceTimeNs.rest, 4) IN IF ~seriesIndex.ok THEN Fail ELSE
    LET seriesSeqNum == ReadBytes(seriesIndex.rest, 4) IN IF ~seriesSeqNum.ok THEN Fail ELSE
    LET originalTradeId == ReadBytes(seriesSeqNum.rest, 4) IN IF ~originalTradeId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(originalTradeId.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET price == ReadBytes(tradeId.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET volume == ReadBytes(price.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET tradeCond1 == ReadBytes(volume.rest, 1) IN IF ~tradeCond1.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(tradeCond1.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET secondReserved1 == ReadBytes(reserved1.rest, 1) IN IF ~secondReserved1.ok THEN Fail ELSE
    LET thirdReserved1 == ReadBytes(secondReserved1.rest, 1) IN IF ~thirdReserved1.ok THEN Fail ELSE
    Ok([ sourceTime      |-> sourceTime.value,
         sourceTimeNs    |-> sourceTimeNs.value,
         seriesIndex     |-> seriesIndex.value,
         seriesSeqNum    |-> seriesSeqNum.value,
         originalTradeId |-> originalTradeId.value,
         tradeId         |-> tradeId.value,
         price           |-> price.value,
         volume          |-> volume.value,
         tradeCond1      |-> tradeCond1.value,
         reserved1       |-> reserved1.value,
         secondReserved1 |-> secondReserved1.value,
         thirdReserved1  |-> thirdReserved1.value ], thirdReserved1.rest)

ZeroOptionsTradeCorrectionMessage ==
    [ sourceTime      |-> [i \in 1 .. 4 |-> 0],
      sourceTimeNs    |-> [i \in 1 .. 4 |-> 0],
      seriesIndex     |-> [i \in 1 .. 4 |-> 0],
      seriesSeqNum    |-> [i \in 1 .. 4 |-> 0],
      originalTradeId |-> [i \in 1 .. 4 |-> 0],
      tradeId         |-> [i \in 1 .. 4 |-> 0],
      price           |-> [i \in 1 .. 4 |-> 0],
      volume          |-> [i \in 1 .. 4 |-> 0],
      tradeCond1      |-> [i \in 1 .. 1 |-> 0],
      reserved1       |-> [i \in 1 .. 1 |-> 0],
      secondReserved1 |-> [i \in 1 .. 1 |-> 0],
      thirdReserved1  |-> [i \in 1 .. 1 |-> 0] ]

(* Options Trade Correction Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionsTradeCorrectionMessage ==
    { ZeroOptionsTradeCorrectionMessage }
        \cup { [ZeroOptionsTradeCorrectionMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroOptionsTradeCorrectionMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroOptionsTradeCorrectionMessage EXCEPT !.seriesIndex = one] : one \in Sample(4) }
        \cup { [ZeroOptionsTradeCorrectionMessage EXCEPT !.seriesSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroOptionsTradeCorrectionMessage EXCEPT !.originalTradeId = one] : one \in Sample(4) }
        \cup { [ZeroOptionsTradeCorrectionMessage EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroOptionsTradeCorrectionMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOptionsTradeCorrectionMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroOptionsTradeCorrectionMessage EXCEPT !.tradeCond1 = one] : one \in Sample(1) }
        \cup { [ZeroOptionsTradeCorrectionMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOptionsTradeCorrectionMessage EXCEPT !.secondReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOptionsTradeCorrectionMessage EXCEPT !.thirdReserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Options Imbalance Message: 61 bytes                                     *)
(***************************************************************************)

OptionsImbalanceMessage ==
    [ sourceTime                   : Sample(4),
      sourceTimeNs                 : Sample(4),
      seriesIndex                  : Sample(4),
      seriesSeqNum                 : Sample(4),
      reserved4                    : Sample(4),
      pairedQty                    : Sample(4),
      totalImbalanceQty            : Sample(4),
      marketImbalanceQty           : Sample(4),
      reserved2                    : Sample(2),
      auctionType                  : Sample(1),
      imbalanceSide                : Sample(1),
      continuousBookClearingPrice  : Sample(4),
      auctionInterestClearingPrice : Sample(4),
      secondReserved4              : Sample(4),
      indicativeMatchPrice         : Sample(4),
      upperCollar                  : Sample(4),
      lowerCollar                  : Sample(4),
      auctionStatus                : Sample(1) ]

EncodeOptionsImbalanceMessage(message) ==
    message.sourceTime
        \o message.sourceTimeNs
        \o message.seriesIndex
        \o message.seriesSeqNum
        \o message.reserved4
        \o message.pairedQty
        \o message.totalImbalanceQty
        \o message.marketImbalanceQty
        \o message.reserved2
        \o message.auctionType
        \o message.imbalanceSide
        \o message.continuousBookClearingPrice
        \o message.auctionInterestClearingPrice
        \o message.secondReserved4
        \o message.indicativeMatchPrice
        \o message.upperCollar
        \o message.lowerCollar
        \o message.auctionStatus

DecodeOptionsImbalanceMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceTimeNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET seriesIndex == ReadBytes(sourceTimeNs.rest, 4) IN IF ~seriesIndex.ok THEN Fail ELSE
    LET seriesSeqNum == ReadBytes(seriesIndex.rest, 4) IN IF ~seriesSeqNum.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(seriesSeqNum.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET pairedQty == ReadBytes(reserved4.rest, 4) IN IF ~pairedQty.ok THEN Fail ELSE
    LET totalImbalanceQty == ReadBytes(pairedQty.rest, 4) IN IF ~totalImbalanceQty.ok THEN Fail ELSE
    LET marketImbalanceQty == ReadBytes(totalImbalanceQty.rest, 4) IN IF ~marketImbalanceQty.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(marketImbalanceQty.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET auctionType == ReadBytes(reserved2.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET imbalanceSide == ReadBytes(auctionType.rest, 1) IN IF ~imbalanceSide.ok THEN Fail ELSE
    LET continuousBookClearingPrice == ReadBytes(imbalanceSide.rest, 4) IN IF ~continuousBookClearingPrice.ok THEN Fail ELSE
    LET auctionInterestClearingPrice == ReadBytes(continuousBookClearingPrice.rest, 4) IN IF ~auctionInterestClearingPrice.ok THEN Fail ELSE
    LET secondReserved4 == ReadBytes(auctionInterestClearingPrice.rest, 4) IN IF ~secondReserved4.ok THEN Fail ELSE
    LET indicativeMatchPrice == ReadBytes(secondReserved4.rest, 4) IN IF ~indicativeMatchPrice.ok THEN Fail ELSE
    LET upperCollar == ReadBytes(indicativeMatchPrice.rest, 4) IN IF ~upperCollar.ok THEN Fail ELSE
    LET lowerCollar == ReadBytes(upperCollar.rest, 4) IN IF ~lowerCollar.ok THEN Fail ELSE
    LET auctionStatus == ReadBytes(lowerCollar.rest, 1) IN IF ~auctionStatus.ok THEN Fail ELSE
    Ok([ sourceTime                   |-> sourceTime.value,
         sourceTimeNs                 |-> sourceTimeNs.value,
         seriesIndex                  |-> seriesIndex.value,
         seriesSeqNum                 |-> seriesSeqNum.value,
         reserved4                    |-> reserved4.value,
         pairedQty                    |-> pairedQty.value,
         totalImbalanceQty            |-> totalImbalanceQty.value,
         marketImbalanceQty           |-> marketImbalanceQty.value,
         reserved2                    |-> reserved2.value,
         auctionType                  |-> auctionType.value,
         imbalanceSide                |-> imbalanceSide.value,
         continuousBookClearingPrice  |-> continuousBookClearingPrice.value,
         auctionInterestClearingPrice |-> auctionInterestClearingPrice.value,
         secondReserved4              |-> secondReserved4.value,
         indicativeMatchPrice         |-> indicativeMatchPrice.value,
         upperCollar                  |-> upperCollar.value,
         lowerCollar                  |-> lowerCollar.value,
         auctionStatus                |-> auctionStatus.value ], auctionStatus.rest)

ZeroOptionsImbalanceMessage ==
    [ sourceTime                   |-> [i \in 1 .. 4 |-> 0],
      sourceTimeNs                 |-> [i \in 1 .. 4 |-> 0],
      seriesIndex                  |-> [i \in 1 .. 4 |-> 0],
      seriesSeqNum                 |-> [i \in 1 .. 4 |-> 0],
      reserved4                    |-> [i \in 1 .. 4 |-> 0],
      pairedQty                    |-> [i \in 1 .. 4 |-> 0],
      totalImbalanceQty            |-> [i \in 1 .. 4 |-> 0],
      marketImbalanceQty           |-> [i \in 1 .. 4 |-> 0],
      reserved2                    |-> [i \in 1 .. 2 |-> 0],
      auctionType                  |-> [i \in 1 .. 1 |-> 0],
      imbalanceSide                |-> [i \in 1 .. 1 |-> 0],
      continuousBookClearingPrice  |-> [i \in 1 .. 4 |-> 0],
      auctionInterestClearingPrice |-> [i \in 1 .. 4 |-> 0],
      secondReserved4              |-> [i \in 1 .. 4 |-> 0],
      indicativeMatchPrice         |-> [i \in 1 .. 4 |-> 0],
      upperCollar                  |-> [i \in 1 .. 4 |-> 0],
      lowerCollar                  |-> [i \in 1 .. 4 |-> 0],
      auctionStatus                |-> [i \in 1 .. 1 |-> 0] ]

(* Options Imbalance Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionsImbalanceMessage ==
    { ZeroOptionsImbalanceMessage }
        \cup { [ZeroOptionsImbalanceMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroOptionsImbalanceMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroOptionsImbalanceMessage EXCEPT !.seriesIndex = one] : one \in Sample(4) }
        \cup { [ZeroOptionsImbalanceMessage EXCEPT !.seriesSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroOptionsImbalanceMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroOptionsImbalanceMessage EXCEPT !.pairedQty = one] : one \in Sample(4) }
        \cup { [ZeroOptionsImbalanceMessage EXCEPT !.totalImbalanceQty = one] : one \in Sample(4) }
        \cup { [ZeroOptionsImbalanceMessage EXCEPT !.marketImbalanceQty = one] : one \in Sample(4) }
        \cup { [ZeroOptionsImbalanceMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOptionsImbalanceMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroOptionsImbalanceMessage EXCEPT !.imbalanceSide = one] : one \in Sample(1) }
        \cup { [ZeroOptionsImbalanceMessage EXCEPT !.continuousBookClearingPrice = one] : one \in Sample(4) }
        \cup { [ZeroOptionsImbalanceMessage EXCEPT !.auctionInterestClearingPrice = one] : one \in Sample(4) }
        \cup { [ZeroOptionsImbalanceMessage EXCEPT !.secondReserved4 = one] : one \in Sample(4) }
        \cup { [ZeroOptionsImbalanceMessage EXCEPT !.indicativeMatchPrice = one] : one \in Sample(4) }
        \cup { [ZeroOptionsImbalanceMessage EXCEPT !.upperCollar = one] : one \in Sample(4) }
        \cup { [ZeroOptionsImbalanceMessage EXCEPT !.lowerCollar = one] : one \in Sample(4) }
        \cup { [ZeroOptionsImbalanceMessage EXCEPT !.auctionStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Series Rfq Message: 40 bytes                                            *)
(***************************************************************************)

SeriesRfqMessage ==
    [ sourceTime    : Sample(4),
      sourceTimeNs  : Sample(4),
      seriesIndex   : Sample(4),
      seriesSeqNum  : Sample(4),
      side          : Sample(1),
      type          : Sample(1),
      capacity      : Sample(1),
      totalQuantity : Sample(4),
      workingPrice  : Sample(4),
      participant   : Sample(4),
      auctionId     : Sample(8),
      rfqStatus     : Sample(1) ]

EncodeSeriesRfqMessage(message) ==
    message.sourceTime
        \o message.sourceTimeNs
        \o message.seriesIndex
        \o message.seriesSeqNum
        \o message.side
        \o message.type
        \o message.capacity
        \o message.totalQuantity
        \o message.workingPrice
        \o message.participant
        \o message.auctionId
        \o message.rfqStatus

DecodeSeriesRfqMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceTimeNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET seriesIndex == ReadBytes(sourceTimeNs.rest, 4) IN IF ~seriesIndex.ok THEN Fail ELSE
    LET seriesSeqNum == ReadBytes(seriesIndex.rest, 4) IN IF ~seriesSeqNum.ok THEN Fail ELSE
    LET side == ReadBytes(seriesSeqNum.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET type == ReadBytes(side.rest, 1) IN IF ~type.ok THEN Fail ELSE
    LET capacity == ReadBytes(type.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET totalQuantity == ReadBytes(capacity.rest, 4) IN IF ~totalQuantity.ok THEN Fail ELSE
    LET workingPrice == ReadBytes(totalQuantity.rest, 4) IN IF ~workingPrice.ok THEN Fail ELSE
    LET participant == ReadBytes(workingPrice.rest, 4) IN IF ~participant.ok THEN Fail ELSE
    LET auctionId == ReadBytes(participant.rest, 8) IN IF ~auctionId.ok THEN Fail ELSE
    LET rfqStatus == ReadBytes(auctionId.rest, 1) IN IF ~rfqStatus.ok THEN Fail ELSE
    Ok([ sourceTime    |-> sourceTime.value,
         sourceTimeNs  |-> sourceTimeNs.value,
         seriesIndex   |-> seriesIndex.value,
         seriesSeqNum  |-> seriesSeqNum.value,
         side          |-> side.value,
         type          |-> type.value,
         capacity      |-> capacity.value,
         totalQuantity |-> totalQuantity.value,
         workingPrice  |-> workingPrice.value,
         participant   |-> participant.value,
         auctionId     |-> auctionId.value,
         rfqStatus     |-> rfqStatus.value ], rfqStatus.rest)

ZeroSeriesRfqMessage ==
    [ sourceTime    |-> [i \in 1 .. 4 |-> 0],
      sourceTimeNs  |-> [i \in 1 .. 4 |-> 0],
      seriesIndex   |-> [i \in 1 .. 4 |-> 0],
      seriesSeqNum  |-> [i \in 1 .. 4 |-> 0],
      side          |-> [i \in 1 .. 1 |-> 0],
      type          |-> [i \in 1 .. 1 |-> 0],
      capacity      |-> [i \in 1 .. 1 |-> 0],
      totalQuantity |-> [i \in 1 .. 4 |-> 0],
      workingPrice  |-> [i \in 1 .. 4 |-> 0],
      participant   |-> [i \in 1 .. 4 |-> 0],
      auctionId     |-> [i \in 1 .. 8 |-> 0],
      rfqStatus     |-> [i \in 1 .. 1 |-> 0] ]

(* Series Rfq Message at zero, then each field in turn at the values it is checked at *)
CheckedSeriesRfqMessage ==
    { ZeroSeriesRfqMessage }
        \cup { [ZeroSeriesRfqMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroSeriesRfqMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroSeriesRfqMessage EXCEPT !.seriesIndex = one] : one \in Sample(4) }
        \cup { [ZeroSeriesRfqMessage EXCEPT !.seriesSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroSeriesRfqMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroSeriesRfqMessage EXCEPT !.type = one] : one \in Sample(1) }
        \cup { [ZeroSeriesRfqMessage EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroSeriesRfqMessage EXCEPT !.totalQuantity = one] : one \in Sample(4) }
        \cup { [ZeroSeriesRfqMessage EXCEPT !.workingPrice = one] : one \in Sample(4) }
        \cup { [ZeroSeriesRfqMessage EXCEPT !.participant = one] : one \in Sample(4) }
        \cup { [ZeroSeriesRfqMessage EXCEPT !.auctionId = one] : one \in Sample(8) }
        \cup { [ZeroSeriesRfqMessage EXCEPT !.rfqStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Outright Series Summary Message: 32 bytes                               *)
(***************************************************************************)

OutrightSeriesSummaryMessage ==
    [ sourceTime   : Sample(4),
      sourceTimeNs : Sample(4),
      seriesIndex  : Sample(4),
      highPrice    : Sample(4),
      lowPrice     : Sample(4),
      open         : Sample(4),
      close        : Sample(4),
      totalVolume  : Sample(4) ]

EncodeOutrightSeriesSummaryMessage(message) ==
    message.sourceTime
        \o message.sourceTimeNs
        \o message.seriesIndex
        \o message.highPrice
        \o message.lowPrice
        \o message.open
        \o message.close
        \o message.totalVolume

DecodeOutrightSeriesSummaryMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceTimeNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET seriesIndex == ReadBytes(sourceTimeNs.rest, 4) IN IF ~seriesIndex.ok THEN Fail ELSE
    LET highPrice == ReadBytes(seriesIndex.rest, 4) IN IF ~highPrice.ok THEN Fail ELSE
    LET lowPrice == ReadBytes(highPrice.rest, 4) IN IF ~lowPrice.ok THEN Fail ELSE
    LET open == ReadBytes(lowPrice.rest, 4) IN IF ~open.ok THEN Fail ELSE
    LET close == ReadBytes(open.rest, 4) IN IF ~close.ok THEN Fail ELSE
    LET totalVolume == ReadBytes(close.rest, 4) IN IF ~totalVolume.ok THEN Fail ELSE
    Ok([ sourceTime   |-> sourceTime.value,
         sourceTimeNs |-> sourceTimeNs.value,
         seriesIndex  |-> seriesIndex.value,
         highPrice    |-> highPrice.value,
         lowPrice     |-> lowPrice.value,
         open         |-> open.value,
         close        |-> close.value,
         totalVolume  |-> totalVolume.value ], totalVolume.rest)

ZeroOutrightSeriesSummaryMessage ==
    [ sourceTime   |-> [i \in 1 .. 4 |-> 0],
      sourceTimeNs |-> [i \in 1 .. 4 |-> 0],
      seriesIndex  |-> [i \in 1 .. 4 |-> 0],
      highPrice    |-> [i \in 1 .. 4 |-> 0],
      lowPrice     |-> [i \in 1 .. 4 |-> 0],
      open         |-> [i \in 1 .. 4 |-> 0],
      close        |-> [i \in 1 .. 4 |-> 0],
      totalVolume  |-> [i \in 1 .. 4 |-> 0] ]

(* Outright Series Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedOutrightSeriesSummaryMessage ==
    { ZeroOutrightSeriesSummaryMessage }
        \cup { [ZeroOutrightSeriesSummaryMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroOutrightSeriesSummaryMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroOutrightSeriesSummaryMessage EXCEPT !.seriesIndex = one] : one \in Sample(4) }
        \cup { [ZeroOutrightSeriesSummaryMessage EXCEPT !.highPrice = one] : one \in Sample(4) }
        \cup { [ZeroOutrightSeriesSummaryMessage EXCEPT !.lowPrice = one] : one \in Sample(4) }
        \cup { [ZeroOutrightSeriesSummaryMessage EXCEPT !.open = one] : one \in Sample(4) }
        \cup { [ZeroOutrightSeriesSummaryMessage EXCEPT !.close = one] : one \in Sample(4) }
        \cup { [ZeroOutrightSeriesSummaryMessage EXCEPT !.totalVolume = one] : one \in Sample(4) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

SequenceNumberResetMessageCode == 1  \* 0x01
SourceTimeReferenceMessageCode == 2  \* 0x02
SymbolIndexMappingMessageCode == 3  \* 0x03
SymbolClearMessageCode == 32  \* 0x20
SecurityStatusMessageCode == 34  \* 0x22
OutrightSeriesIndexMappingMessageCode == 50  \* 0x32
OptionsStatusMessageCode == 51  \* 0x33
ComplexSeriesIndexMappingMessageCode == 60  \* 0x3c
RetransmissionRequestMessageCode == 10  \* 0x0a
RefreshHeaderMessageCode == 35  \* 0x23
RefreshRequestMessageCode == 15  \* 0x0f
SymbolIndexMappingRequestMessageCode == 13  \* 0x0d
MessageUnavailableMessageCode == 31  \* 0x1f
RequestResponseMessageCode == 11  \* 0x0b
HeartbeatResponseMessageCode == 12  \* 0x0c
OptionsQuoteMessageCode == 340  \* 0x154
OptionsTradeMessageCode == 320  \* 0x140
OptionsTradeCancelMessageCode == 321  \* 0x141
OptionsTradeCorrectionMessageCode == 322  \* 0x142
OptionsImbalanceMessageCode == 305  \* 0x131
SeriesRfqMessageCode == 307  \* 0x133
OutrightSeriesSummaryMessageCode == 323  \* 0x143

Payload ==
    [ tag : {SequenceNumberResetMessageCode}, body : SequenceNumberResetMessage ]
        \cup [ tag : {SourceTimeReferenceMessageCode}, body : SourceTimeReferenceMessage ]
        \cup [ tag : {SymbolIndexMappingMessageCode}, body : SymbolIndexMappingMessage ]
        \cup [ tag : {SymbolClearMessageCode}, body : SymbolClearMessage ]
        \cup [ tag : {SecurityStatusMessageCode}, body : SecurityStatusMessage ]
        \cup [ tag : {OutrightSeriesIndexMappingMessageCode}, body : OutrightSeriesIndexMappingMessage ]
        \cup [ tag : {OptionsStatusMessageCode}, body : OptionsStatusMessage ]
        \cup [ tag : {ComplexSeriesIndexMappingMessageCode}, body : ComplexSeriesIndexMappingMessage ]
        \cup [ tag : {RetransmissionRequestMessageCode}, body : RetransmissionRequestMessage ]
        \cup [ tag : {RefreshHeaderMessageCode}, body : RefreshHeaderMessage ]
        \cup [ tag : {RefreshRequestMessageCode}, body : RefreshRequestMessage ]
        \cup [ tag : {SymbolIndexMappingRequestMessageCode}, body : SymbolIndexMappingRequestMessage ]
        \cup [ tag : {MessageUnavailableMessageCode}, body : MessageUnavailableMessage ]
        \cup [ tag : {RequestResponseMessageCode}, body : RequestResponseMessage ]
        \cup [ tag : {HeartbeatResponseMessageCode}, body : HeartbeatResponseMessage ]
        \cup [ tag : {OptionsQuoteMessageCode}, body : OptionsQuoteMessage ]
        \cup [ tag : {OptionsTradeMessageCode}, body : OptionsTradeMessage ]
        \cup [ tag : {OptionsTradeCancelMessageCode}, body : OptionsTradeCancelMessage ]
        \cup [ tag : {OptionsTradeCorrectionMessageCode}, body : OptionsTradeCorrectionMessage ]
        \cup [ tag : {OptionsImbalanceMessageCode}, body : OptionsImbalanceMessage ]
        \cup [ tag : {SeriesRfqMessageCode}, body : SeriesRfqMessage ]
        \cup [ tag : {OutrightSeriesSummaryMessageCode}, body : OutrightSeriesSummaryMessage ]

EncodePayload(message) ==
    CASE message.tag = SequenceNumberResetMessageCode -> EncodeSequenceNumberResetMessage(message.body)
      [] message.tag = SourceTimeReferenceMessageCode -> EncodeSourceTimeReferenceMessage(message.body)
      [] message.tag = SymbolIndexMappingMessageCode -> EncodeSymbolIndexMappingMessage(message.body)
      [] message.tag = SymbolClearMessageCode -> EncodeSymbolClearMessage(message.body)
      [] message.tag = SecurityStatusMessageCode -> EncodeSecurityStatusMessage(message.body)
      [] message.tag = OutrightSeriesIndexMappingMessageCode -> EncodeOutrightSeriesIndexMappingMessage(message.body)
      [] message.tag = OptionsStatusMessageCode -> EncodeOptionsStatusMessage(message.body)
      [] message.tag = ComplexSeriesIndexMappingMessageCode -> EncodeComplexSeriesIndexMappingMessage(message.body)
      [] message.tag = RetransmissionRequestMessageCode -> EncodeRetransmissionRequestMessage(message.body)
      [] message.tag = RefreshHeaderMessageCode -> EncodeRefreshHeaderMessage(message.body)
      [] message.tag = RefreshRequestMessageCode -> EncodeRefreshRequestMessage(message.body)
      [] message.tag = SymbolIndexMappingRequestMessageCode -> EncodeSymbolIndexMappingRequestMessage(message.body)
      [] message.tag = MessageUnavailableMessageCode -> EncodeMessageUnavailableMessage(message.body)
      [] message.tag = RequestResponseMessageCode -> EncodeRequestResponseMessage(message.body)
      [] message.tag = HeartbeatResponseMessageCode -> EncodeHeartbeatResponseMessage(message.body)
      [] message.tag = OptionsQuoteMessageCode -> EncodeOptionsQuoteMessage(message.body)
      [] message.tag = OptionsTradeMessageCode -> EncodeOptionsTradeMessage(message.body)
      [] message.tag = OptionsTradeCancelMessageCode -> EncodeOptionsTradeCancelMessage(message.body)
      [] message.tag = OptionsTradeCorrectionMessageCode -> EncodeOptionsTradeCorrectionMessage(message.body)
      [] message.tag = OptionsImbalanceMessageCode -> EncodeOptionsImbalanceMessage(message.body)
      [] message.tag = SeriesRfqMessageCode -> EncodeSeriesRfqMessage(message.body)
      [] message.tag = OutrightSeriesSummaryMessageCode -> EncodeOutrightSeriesSummaryMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = SequenceNumberResetMessageCode -> DecodeSequenceNumberResetMessage(bytes)
              [] tag = SourceTimeReferenceMessageCode -> DecodeSourceTimeReferenceMessage(bytes)
              [] tag = SymbolIndexMappingMessageCode -> DecodeSymbolIndexMappingMessage(bytes)
              [] tag = SymbolClearMessageCode -> DecodeSymbolClearMessage(bytes)
              [] tag = SecurityStatusMessageCode -> DecodeSecurityStatusMessage(bytes)
              [] tag = OutrightSeriesIndexMappingMessageCode -> DecodeOutrightSeriesIndexMappingMessage(bytes)
              [] tag = OptionsStatusMessageCode -> DecodeOptionsStatusMessage(bytes)
              [] tag = ComplexSeriesIndexMappingMessageCode -> DecodeComplexSeriesIndexMappingMessage(bytes)
              [] tag = RetransmissionRequestMessageCode -> DecodeRetransmissionRequestMessage(bytes)
              [] tag = RefreshHeaderMessageCode -> DecodeRefreshHeaderMessage(bytes)
              [] tag = RefreshRequestMessageCode -> DecodeRefreshRequestMessage(bytes)
              [] tag = SymbolIndexMappingRequestMessageCode -> DecodeSymbolIndexMappingRequestMessage(bytes)
              [] tag = MessageUnavailableMessageCode -> DecodeMessageUnavailableMessage(bytes)
              [] tag = RequestResponseMessageCode -> DecodeRequestResponseMessage(bytes)
              [] tag = HeartbeatResponseMessageCode -> DecodeHeartbeatResponseMessage(bytes)
              [] tag = OptionsQuoteMessageCode -> DecodeOptionsQuoteMessage(bytes)
              [] tag = OptionsTradeMessageCode -> DecodeOptionsTradeMessage(bytes)
              [] tag = OptionsTradeCancelMessageCode -> DecodeOptionsTradeCancelMessage(bytes)
              [] tag = OptionsTradeCorrectionMessageCode -> DecodeOptionsTradeCorrectionMessage(bytes)
              [] tag = OptionsImbalanceMessageCode -> DecodeOptionsImbalanceMessage(bytes)
              [] tag = SeriesRfqMessageCode -> DecodeSeriesRfqMessage(bytes)
              [] tag = OutrightSeriesSummaryMessageCode -> DecodeOutrightSeriesSummaryMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> SequenceNumberResetMessageCode, body |-> ZeroSequenceNumberResetMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> SequenceNumberResetMessageCode, body |-> one] : one \in CheckedSequenceNumberResetMessage }
        \cup { [tag |-> SourceTimeReferenceMessageCode, body |-> one] : one \in CheckedSourceTimeReferenceMessage }
        \cup { [tag |-> SymbolIndexMappingMessageCode, body |-> one] : one \in CheckedSymbolIndexMappingMessage }
        \cup { [tag |-> SymbolClearMessageCode, body |-> one] : one \in CheckedSymbolClearMessage }
        \cup { [tag |-> SecurityStatusMessageCode, body |-> one] : one \in CheckedSecurityStatusMessage }
        \cup { [tag |-> OutrightSeriesIndexMappingMessageCode, body |-> one] : one \in CheckedOutrightSeriesIndexMappingMessage }
        \cup { [tag |-> OptionsStatusMessageCode, body |-> one] : one \in CheckedOptionsStatusMessage }
        \cup { [tag |-> ComplexSeriesIndexMappingMessageCode, body |-> one] : one \in CheckedComplexSeriesIndexMappingMessage }
        \cup { [tag |-> RetransmissionRequestMessageCode, body |-> one] : one \in CheckedRetransmissionRequestMessage }
        \cup { [tag |-> RefreshHeaderMessageCode, body |-> one] : one \in CheckedRefreshHeaderMessage }
        \cup { [tag |-> RefreshRequestMessageCode, body |-> one] : one \in CheckedRefreshRequestMessage }
        \cup { [tag |-> SymbolIndexMappingRequestMessageCode, body |-> one] : one \in CheckedSymbolIndexMappingRequestMessage }
        \cup { [tag |-> MessageUnavailableMessageCode, body |-> one] : one \in CheckedMessageUnavailableMessage }
        \cup { [tag |-> RequestResponseMessageCode, body |-> one] : one \in CheckedRequestResponseMessage }
        \cup { [tag |-> HeartbeatResponseMessageCode, body |-> one] : one \in CheckedHeartbeatResponseMessage }
        \cup { [tag |-> OptionsQuoteMessageCode, body |-> one] : one \in CheckedOptionsQuoteMessage }
        \cup { [tag |-> OptionsTradeMessageCode, body |-> one] : one \in CheckedOptionsTradeMessage }
        \cup { [tag |-> OptionsTradeCancelMessageCode, body |-> one] : one \in CheckedOptionsTradeCancelMessage }
        \cup { [tag |-> OptionsTradeCorrectionMessageCode, body |-> one] : one \in CheckedOptionsTradeCorrectionMessage }
        \cup { [tag |-> OptionsImbalanceMessageCode, body |-> one] : one \in CheckedOptionsImbalanceMessage }
        \cup { [tag |-> SeriesRfqMessageCode, body |-> one] : one \in CheckedSeriesRfqMessage }
        \cup { [tag |-> OutrightSeriesSummaryMessageCode, body |-> one] : one \in CheckedOutrightSeriesSummaryMessage }

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
      [ZeroMessage EXCEPT !.payload = [tag |-> SourceTimeReferenceMessageCode, body |-> ZeroSourceTimeReferenceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SymbolIndexMappingMessageCode, body |-> ZeroSymbolIndexMappingMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SymbolClearMessageCode, body |-> ZeroSymbolClearMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityStatusMessageCode, body |-> ZeroSecurityStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OutrightSeriesIndexMappingMessageCode, body |-> ZeroOutrightSeriesIndexMappingMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OptionsStatusMessageCode, body |-> ZeroOptionsStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ComplexSeriesIndexMappingMessageCode, body |-> ZeroComplexSeriesIndexMappingMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RetransmissionRequestMessageCode, body |-> ZeroRetransmissionRequestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RefreshHeaderMessageCode, body |-> ZeroRefreshHeaderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RefreshRequestMessageCode, body |-> ZeroRefreshRequestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SymbolIndexMappingRequestMessageCode, body |-> ZeroSymbolIndexMappingRequestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MessageUnavailableMessageCode, body |-> ZeroMessageUnavailableMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RequestResponseMessageCode, body |-> ZeroRequestResponseMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> HeartbeatResponseMessageCode, body |-> ZeroHeartbeatResponseMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OptionsQuoteMessageCode, body |-> ZeroOptionsQuoteMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OptionsTradeMessageCode, body |-> ZeroOptionsTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OptionsTradeCancelMessageCode, body |-> ZeroOptionsTradeCancelMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OptionsTradeCorrectionMessageCode, body |-> ZeroOptionsTradeCorrectionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OptionsImbalanceMessageCode, body |-> ZeroOptionsImbalanceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SeriesRfqMessageCode, body |-> ZeroSeriesRfqMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OutrightSeriesSummaryMessageCode, body |-> ZeroOutrightSeriesSummaryMessage]] }

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

(* Every Source Time Reference Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSourceTimeReferenceMessage ==
    \A message \in CheckedSourceTimeReferenceMessage :
        LET read == DecodeSourceTimeReferenceMessage(EncodeSourceTimeReferenceMessage(message))
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

(* Every Outright Series Index Mapping Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOutrightSeriesIndexMappingMessage ==
    \A message \in CheckedOutrightSeriesIndexMappingMessage :
        LET read == DecodeOutrightSeriesIndexMappingMessage(EncodeOutrightSeriesIndexMappingMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Options Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionsStatusMessage ==
    \A message \in CheckedOptionsStatusMessage :
        LET read == DecodeOptionsStatusMessage(EncodeOptionsStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Series Index Mapping Leg decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexSeriesIndexMappingLeg ==
    \A message \in CheckedComplexSeriesIndexMappingLeg :
        LET read == DecodeComplexSeriesIndexMappingLeg(EncodeComplexSeriesIndexMappingLeg(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Series Index Mapping Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexSeriesIndexMappingMessage ==
    \A message \in CheckedComplexSeriesIndexMappingMessage :
        LET read == DecodeComplexSeriesIndexMappingMessage(EncodeComplexSeriesIndexMappingMessage(message))
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

(* Every Full Refresh Header decodes back to what was encoded, and leaves nothing over *)
RoundTripFullRefreshHeader ==
    \A message \in CheckedFullRefreshHeader :
        LET read == DecodeFullRefreshHeader(EncodeFullRefreshHeader(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Refresh Header Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRefreshHeaderMessage ==
    \A message \in CheckedRefreshHeaderMessage :
        LET read == DecodeRefreshHeaderMessage(EncodeRefreshHeaderMessage(message))
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

(* Every Symbol Index Mapping Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolIndexMappingRequestMessage ==
    \A message \in CheckedSymbolIndexMappingRequestMessage :
        LET read == DecodeSymbolIndexMappingRequestMessage(EncodeSymbolIndexMappingRequestMessage(message))
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

(* Every Request Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestResponseMessage ==
    \A message \in CheckedRequestResponseMessage :
        LET read == DecodeRequestResponseMessage(EncodeRequestResponseMessage(message))
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

(* Every Options Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionsQuoteMessage ==
    \A message \in CheckedOptionsQuoteMessage :
        LET read == DecodeOptionsQuoteMessage(EncodeOptionsQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Options Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionsTradeMessage ==
    \A message \in CheckedOptionsTradeMessage :
        LET read == DecodeOptionsTradeMessage(EncodeOptionsTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Options Trade Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionsTradeCancelMessage ==
    \A message \in CheckedOptionsTradeCancelMessage :
        LET read == DecodeOptionsTradeCancelMessage(EncodeOptionsTradeCancelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Options Trade Correction Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionsTradeCorrectionMessage ==
    \A message \in CheckedOptionsTradeCorrectionMessage :
        LET read == DecodeOptionsTradeCorrectionMessage(EncodeOptionsTradeCorrectionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Options Imbalance Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionsImbalanceMessage ==
    \A message \in CheckedOptionsImbalanceMessage :
        LET read == DecodeOptionsImbalanceMessage(EncodeOptionsImbalanceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Series Rfq Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSeriesRfqMessage ==
    \A message \in CheckedSeriesRfqMessage :
        LET read == DecodeSeriesRfqMessage(EncodeSeriesRfqMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Outright Series Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOutrightSeriesSummaryMessage ==
    \A message \in CheckedOutrightSeriesSummaryMessage :
        LET read == DecodeOutrightSeriesSummaryMessage(EncodeOutrightSeriesSummaryMessage(message))
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

(* A Current Refresh Pkt is selected by the Current Refresh Pkt it is written under *)
SelectsCurrentRefreshPktChoice ==
    \A message \in CheckedCurrentRefreshPktChoice :
        LET read == DecodeCurrentRefreshPktChoice(message.tag, EncodeCurrentRefreshPktChoice(message))
        IN  read.ok /\ read.value.tag = message.tag

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
