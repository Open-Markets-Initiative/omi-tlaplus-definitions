---------------------- MODULE AmexEquities_Bqt_v2_4_c ----------------------
(***************************************************************************)
(* New York Stock Exchange Best Quote And Trade v2.4.c                     *)
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
(* Note: a Current Refresh Pkt of any value but 1 carries none of them.    *)
(*                                                                         *)
(* Note: Retail Pricing Indicator is a bit field set, checked as its 1     *)
(* byte rather than bit by bit.                                            *)
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
(* Best Quotes Message: 31 bytes                                           *)
(***************************************************************************)

BestQuotesMessage ==
    [ symbolIndex            : Sample(4),
      symbolSeqNumber        : Sample(4),
      askPrice               : Sample(4),
      askVolume              : Sample(4),
      bidPrice               : Sample(4),
      bidVolume              : Sample(4),
      askQuoteCondition      : Sample(1),
      bidQuoteCondition      : Sample(1),
      retailPricingIndicator : Sample(1),
      marketIdOfBestAsk      : Sample(2),
      marketIdOfBestBid      : Sample(2) ]

EncodeBestQuotesMessage(message) ==
    message.symbolIndex
        \o message.symbolSeqNumber
        \o message.askPrice
        \o message.askVolume
        \o message.bidPrice
        \o message.bidVolume
        \o message.askQuoteCondition
        \o message.bidQuoteCondition
        \o message.retailPricingIndicator
        \o message.marketIdOfBestAsk
        \o message.marketIdOfBestBid

DecodeBestQuotesMessage(bytes) ==
    LET symbolIndex == ReadBytes(bytes, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET symbolSeqNumber == ReadBytes(symbolIndex.rest, 4) IN IF ~symbolSeqNumber.ok THEN Fail ELSE
    LET askPrice == ReadBytes(symbolSeqNumber.rest, 4) IN IF ~askPrice.ok THEN Fail ELSE
    LET askVolume == ReadBytes(askPrice.rest, 4) IN IF ~askVolume.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(askVolume.rest, 4) IN IF ~bidPrice.ok THEN Fail ELSE
    LET bidVolume == ReadBytes(bidPrice.rest, 4) IN IF ~bidVolume.ok THEN Fail ELSE
    LET askQuoteCondition == ReadBytes(bidVolume.rest, 1) IN IF ~askQuoteCondition.ok THEN Fail ELSE
    LET bidQuoteCondition == ReadBytes(askQuoteCondition.rest, 1) IN IF ~bidQuoteCondition.ok THEN Fail ELSE
    LET retailPricingIndicator == ReadBytes(bidQuoteCondition.rest, 1) IN IF ~retailPricingIndicator.ok THEN Fail ELSE
    LET marketIdOfBestAsk == ReadBytes(retailPricingIndicator.rest, 2) IN IF ~marketIdOfBestAsk.ok THEN Fail ELSE
    LET marketIdOfBestBid == ReadBytes(marketIdOfBestAsk.rest, 2) IN IF ~marketIdOfBestBid.ok THEN Fail ELSE
    Ok([ symbolIndex            |-> symbolIndex.value,
         symbolSeqNumber        |-> symbolSeqNumber.value,
         askPrice               |-> askPrice.value,
         askVolume              |-> askVolume.value,
         bidPrice               |-> bidPrice.value,
         bidVolume              |-> bidVolume.value,
         askQuoteCondition      |-> askQuoteCondition.value,
         bidQuoteCondition      |-> bidQuoteCondition.value,
         retailPricingIndicator |-> retailPricingIndicator.value,
         marketIdOfBestAsk      |-> marketIdOfBestAsk.value,
         marketIdOfBestBid      |-> marketIdOfBestBid.value ], marketIdOfBestBid.rest)

ZeroBestQuotesMessage ==
    [ symbolIndex            |-> [i \in 1 .. 4 |-> 0],
      symbolSeqNumber        |-> [i \in 1 .. 4 |-> 0],
      askPrice               |-> [i \in 1 .. 4 |-> 0],
      askVolume              |-> [i \in 1 .. 4 |-> 0],
      bidPrice               |-> [i \in 1 .. 4 |-> 0],
      bidVolume              |-> [i \in 1 .. 4 |-> 0],
      askQuoteCondition      |-> [i \in 1 .. 1 |-> 0],
      bidQuoteCondition      |-> [i \in 1 .. 1 |-> 0],
      retailPricingIndicator |-> [i \in 1 .. 1 |-> 0],
      marketIdOfBestAsk      |-> [i \in 1 .. 2 |-> 0],
      marketIdOfBestBid      |-> [i \in 1 .. 2 |-> 0] ]

(* Best Quotes Message at zero, then each field in turn at the values it is checked at *)
CheckedBestQuotesMessage ==
    { ZeroBestQuotesMessage }
        \cup { [ZeroBestQuotesMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroBestQuotesMessage EXCEPT !.symbolSeqNumber = one] : one \in Sample(4) }
        \cup { [ZeroBestQuotesMessage EXCEPT !.askPrice = one] : one \in Sample(4) }
        \cup { [ZeroBestQuotesMessage EXCEPT !.askVolume = one] : one \in Sample(4) }
        \cup { [ZeroBestQuotesMessage EXCEPT !.bidPrice = one] : one \in Sample(4) }
        \cup { [ZeroBestQuotesMessage EXCEPT !.bidVolume = one] : one \in Sample(4) }
        \cup { [ZeroBestQuotesMessage EXCEPT !.askQuoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroBestQuotesMessage EXCEPT !.bidQuoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroBestQuotesMessage EXCEPT !.retailPricingIndicator = one] : one \in Sample(1) }
        \cup { [ZeroBestQuotesMessage EXCEPT !.marketIdOfBestAsk = one] : one \in Sample(2) }
        \cup { [ZeroBestQuotesMessage EXCEPT !.marketIdOfBestBid = one] : one \in Sample(2) }

(***************************************************************************)
(* Consolidated Single Sided Quote Message: 21 bytes                       *)
(***************************************************************************)

ConsolidatedSingleSidedQuoteMessage ==
    [ symbolIndex            : Sample(4),
      symbolSeqNumber        : Sample(4),
      side                   : Sample(1),
      price                  : Sample(4),
      volume                 : Sample(4),
      quoteCondition         : Sample(1),
      retailPricingIndicator : Sample(1),
      marketId               : Sample(2) ]

EncodeConsolidatedSingleSidedQuoteMessage(message) ==
    message.symbolIndex
        \o message.symbolSeqNumber
        \o message.side
        \o message.price
        \o message.volume
        \o message.quoteCondition
        \o message.retailPricingIndicator
        \o message.marketId

DecodeConsolidatedSingleSidedQuoteMessage(bytes) ==
    LET symbolIndex == ReadBytes(bytes, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET symbolSeqNumber == ReadBytes(symbolIndex.rest, 4) IN IF ~symbolSeqNumber.ok THEN Fail ELSE
    LET side == ReadBytes(symbolSeqNumber.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadBytes(side.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET volume == ReadBytes(price.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(volume.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET retailPricingIndicator == ReadBytes(quoteCondition.rest, 1) IN IF ~retailPricingIndicator.ok THEN Fail ELSE
    LET marketId == ReadBytes(retailPricingIndicator.rest, 2) IN IF ~marketId.ok THEN Fail ELSE
    Ok([ symbolIndex            |-> symbolIndex.value,
         symbolSeqNumber        |-> symbolSeqNumber.value,
         side                   |-> side.value,
         price                  |-> price.value,
         volume                 |-> volume.value,
         quoteCondition         |-> quoteCondition.value,
         retailPricingIndicator |-> retailPricingIndicator.value,
         marketId               |-> marketId.value ], marketId.rest)

ZeroConsolidatedSingleSidedQuoteMessage ==
    [ symbolIndex            |-> [i \in 1 .. 4 |-> 0],
      symbolSeqNumber        |-> [i \in 1 .. 4 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      price                  |-> [i \in 1 .. 4 |-> 0],
      volume                 |-> [i \in 1 .. 4 |-> 0],
      quoteCondition         |-> [i \in 1 .. 1 |-> 0],
      retailPricingIndicator |-> [i \in 1 .. 1 |-> 0],
      marketId               |-> [i \in 1 .. 2 |-> 0] ]

(* Consolidated Single Sided Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedConsolidatedSingleSidedQuoteMessage ==
    { ZeroConsolidatedSingleSidedQuoteMessage }
        \cup { [ZeroConsolidatedSingleSidedQuoteMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedSingleSidedQuoteMessage EXCEPT !.symbolSeqNumber = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedSingleSidedQuoteMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedSingleSidedQuoteMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedSingleSidedQuoteMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedSingleSidedQuoteMessage EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedSingleSidedQuoteMessage EXCEPT !.retailPricingIndicator = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedSingleSidedQuoteMessage EXCEPT !.marketId = one] : one \in Sample(2) }

(***************************************************************************)
(* Trf Fractional Trade Message: 46 bytes                                  *)
(***************************************************************************)

TrfFractionalTradeMessage ==
    [ sourceTime       : Sample(4),
      sourceTimeNs     : Sample(4),
      symbolIndex      : Sample(4),
      symbolSeqNum     : Sample(4),
      tradeId          : Sample(4),
      price            : Sample(4),
      fractionalVolume : Sample(8),
      tradeCond1       : Sample(1),
      tradeCond2       : Sample(1),
      tradeCond3       : Sample(1),
      tradeCond4       : Sample(1),
      execDayTime      : Sample(4),
      execDayTimeNs    : Sample(4),
      marketId         : Sample(2) ]

EncodeTrfFractionalTradeMessage(message) ==
    message.sourceTime
        \o message.sourceTimeNs
        \o message.symbolIndex
        \o message.symbolSeqNum
        \o message.tradeId
        \o message.price
        \o message.fractionalVolume
        \o message.tradeCond1
        \o message.tradeCond2
        \o message.tradeCond3
        \o message.tradeCond4
        \o message.execDayTime
        \o message.execDayTimeNs
        \o message.marketId

DecodeTrfFractionalTradeMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceTimeNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(sourceTimeNs.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET symbolSeqNum == ReadBytes(symbolIndex.rest, 4) IN IF ~symbolSeqNum.ok THEN Fail ELSE
    LET tradeId == ReadBytes(symbolSeqNum.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET price == ReadBytes(tradeId.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET fractionalVolume == ReadBytes(price.rest, 8) IN IF ~fractionalVolume.ok THEN Fail ELSE
    LET tradeCond1 == ReadBytes(fractionalVolume.rest, 1) IN IF ~tradeCond1.ok THEN Fail ELSE
    LET tradeCond2 == ReadBytes(tradeCond1.rest, 1) IN IF ~tradeCond2.ok THEN Fail ELSE
    LET tradeCond3 == ReadBytes(tradeCond2.rest, 1) IN IF ~tradeCond3.ok THEN Fail ELSE
    LET tradeCond4 == ReadBytes(tradeCond3.rest, 1) IN IF ~tradeCond4.ok THEN Fail ELSE
    LET execDayTime == ReadBytes(tradeCond4.rest, 4) IN IF ~execDayTime.ok THEN Fail ELSE
    LET execDayTimeNs == ReadBytes(execDayTime.rest, 4) IN IF ~execDayTimeNs.ok THEN Fail ELSE
    LET marketId == ReadBytes(execDayTimeNs.rest, 2) IN IF ~marketId.ok THEN Fail ELSE
    Ok([ sourceTime       |-> sourceTime.value,
         sourceTimeNs     |-> sourceTimeNs.value,
         symbolIndex      |-> symbolIndex.value,
         symbolSeqNum     |-> symbolSeqNum.value,
         tradeId          |-> tradeId.value,
         price            |-> price.value,
         fractionalVolume |-> fractionalVolume.value,
         tradeCond1       |-> tradeCond1.value,
         tradeCond2       |-> tradeCond2.value,
         tradeCond3       |-> tradeCond3.value,
         tradeCond4       |-> tradeCond4.value,
         execDayTime      |-> execDayTime.value,
         execDayTimeNs    |-> execDayTimeNs.value,
         marketId         |-> marketId.value ], marketId.rest)

ZeroTrfFractionalTradeMessage ==
    [ sourceTime       |-> [i \in 1 .. 4 |-> 0],
      sourceTimeNs     |-> [i \in 1 .. 4 |-> 0],
      symbolIndex      |-> [i \in 1 .. 4 |-> 0],
      symbolSeqNum     |-> [i \in 1 .. 4 |-> 0],
      tradeId          |-> [i \in 1 .. 4 |-> 0],
      price            |-> [i \in 1 .. 4 |-> 0],
      fractionalVolume |-> [i \in 1 .. 8 |-> 0],
      tradeCond1       |-> [i \in 1 .. 1 |-> 0],
      tradeCond2       |-> [i \in 1 .. 1 |-> 0],
      tradeCond3       |-> [i \in 1 .. 1 |-> 0],
      tradeCond4       |-> [i \in 1 .. 1 |-> 0],
      execDayTime      |-> [i \in 1 .. 4 |-> 0],
      execDayTimeNs    |-> [i \in 1 .. 4 |-> 0],
      marketId         |-> [i \in 1 .. 2 |-> 0] ]

(* Trf Fractional Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTrfFractionalTradeMessage ==
    { ZeroTrfFractionalTradeMessage }
        \cup { [ZeroTrfFractionalTradeMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroTrfFractionalTradeMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroTrfFractionalTradeMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroTrfFractionalTradeMessage EXCEPT !.symbolSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroTrfFractionalTradeMessage EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroTrfFractionalTradeMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroTrfFractionalTradeMessage EXCEPT !.fractionalVolume = one] : one \in Sample(8) }
        \cup { [ZeroTrfFractionalTradeMessage EXCEPT !.tradeCond1 = one] : one \in Sample(1) }
        \cup { [ZeroTrfFractionalTradeMessage EXCEPT !.tradeCond2 = one] : one \in Sample(1) }
        \cup { [ZeroTrfFractionalTradeMessage EXCEPT !.tradeCond3 = one] : one \in Sample(1) }
        \cup { [ZeroTrfFractionalTradeMessage EXCEPT !.tradeCond4 = one] : one \in Sample(1) }
        \cup { [ZeroTrfFractionalTradeMessage EXCEPT !.execDayTime = one] : one \in Sample(4) }
        \cup { [ZeroTrfFractionalTradeMessage EXCEPT !.execDayTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroTrfFractionalTradeMessage EXCEPT !.marketId = one] : one \in Sample(2) }

(***************************************************************************)
(* Consolidated Trade Message: 34 bytes                                    *)
(***************************************************************************)

ConsolidatedTradeMessage ==
    [ sourceTime      : Sample(4),
      sourceTimeNs    : Sample(4),
      symbolIndex     : Sample(4),
      symbolSeqNumber : Sample(4),
      tradeId         : Sample(4),
      price           : Sample(4),
      volume          : Sample(4),
      tradeCondition1 : Sample(1),
      tradeCondition2 : Sample(1),
      tradeCondition3 : Sample(1),
      tradeCondition4 : Sample(1),
      marketId        : Sample(2) ]

EncodeConsolidatedTradeMessage(message) ==
    message.sourceTime
        \o message.sourceTimeNs
        \o message.symbolIndex
        \o message.symbolSeqNumber
        \o message.tradeId
        \o message.price
        \o message.volume
        \o message.tradeCondition1
        \o message.tradeCondition2
        \o message.tradeCondition3
        \o message.tradeCondition4
        \o message.marketId

DecodeConsolidatedTradeMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceTimeNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(sourceTimeNs.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET symbolSeqNumber == ReadBytes(symbolIndex.rest, 4) IN IF ~symbolSeqNumber.ok THEN Fail ELSE
    LET tradeId == ReadBytes(symbolSeqNumber.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET price == ReadBytes(tradeId.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET volume == ReadBytes(price.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET tradeCondition1 == ReadBytes(volume.rest, 1) IN IF ~tradeCondition1.ok THEN Fail ELSE
    LET tradeCondition2 == ReadBytes(tradeCondition1.rest, 1) IN IF ~tradeCondition2.ok THEN Fail ELSE
    LET tradeCondition3 == ReadBytes(tradeCondition2.rest, 1) IN IF ~tradeCondition3.ok THEN Fail ELSE
    LET tradeCondition4 == ReadBytes(tradeCondition3.rest, 1) IN IF ~tradeCondition4.ok THEN Fail ELSE
    LET marketId == ReadBytes(tradeCondition4.rest, 2) IN IF ~marketId.ok THEN Fail ELSE
    Ok([ sourceTime      |-> sourceTime.value,
         sourceTimeNs    |-> sourceTimeNs.value,
         symbolIndex     |-> symbolIndex.value,
         symbolSeqNumber |-> symbolSeqNumber.value,
         tradeId         |-> tradeId.value,
         price           |-> price.value,
         volume          |-> volume.value,
         tradeCondition1 |-> tradeCondition1.value,
         tradeCondition2 |-> tradeCondition2.value,
         tradeCondition3 |-> tradeCondition3.value,
         tradeCondition4 |-> tradeCondition4.value,
         marketId        |-> marketId.value ], marketId.rest)

ZeroConsolidatedTradeMessage ==
    [ sourceTime      |-> [i \in 1 .. 4 |-> 0],
      sourceTimeNs    |-> [i \in 1 .. 4 |-> 0],
      symbolIndex     |-> [i \in 1 .. 4 |-> 0],
      symbolSeqNumber |-> [i \in 1 .. 4 |-> 0],
      tradeId         |-> [i \in 1 .. 4 |-> 0],
      price           |-> [i \in 1 .. 4 |-> 0],
      volume          |-> [i \in 1 .. 4 |-> 0],
      tradeCondition1 |-> [i \in 1 .. 1 |-> 0],
      tradeCondition2 |-> [i \in 1 .. 1 |-> 0],
      tradeCondition3 |-> [i \in 1 .. 1 |-> 0],
      tradeCondition4 |-> [i \in 1 .. 1 |-> 0],
      marketId        |-> [i \in 1 .. 2 |-> 0] ]

(* Consolidated Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedConsolidatedTradeMessage ==
    { ZeroConsolidatedTradeMessage }
        \cup { [ZeroConsolidatedTradeMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedTradeMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedTradeMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedTradeMessage EXCEPT !.symbolSeqNumber = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedTradeMessage EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedTradeMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedTradeMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedTradeMessage EXCEPT !.tradeCondition1 = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedTradeMessage EXCEPT !.tradeCondition2 = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedTradeMessage EXCEPT !.tradeCondition3 = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedTradeMessage EXCEPT !.tradeCondition4 = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedTradeMessage EXCEPT !.marketId = one] : one \in Sample(2) }

(***************************************************************************)
(* Consolidated Trade Cancel Message: 22 bytes                             *)
(***************************************************************************)

ConsolidatedTradeCancelMessage ==
    [ sourceTime      : Sample(4),
      sourceTimeNs    : Sample(4),
      symbolIndex     : Sample(4),
      symbolSeqNumber : Sample(4),
      originalTradeId : Sample(4),
      marketId        : Sample(2) ]

EncodeConsolidatedTradeCancelMessage(message) ==
    message.sourceTime
        \o message.sourceTimeNs
        \o message.symbolIndex
        \o message.symbolSeqNumber
        \o message.originalTradeId
        \o message.marketId

DecodeConsolidatedTradeCancelMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceTimeNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(sourceTimeNs.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET symbolSeqNumber == ReadBytes(symbolIndex.rest, 4) IN IF ~symbolSeqNumber.ok THEN Fail ELSE
    LET originalTradeId == ReadBytes(symbolSeqNumber.rest, 4) IN IF ~originalTradeId.ok THEN Fail ELSE
    LET marketId == ReadBytes(originalTradeId.rest, 2) IN IF ~marketId.ok THEN Fail ELSE
    Ok([ sourceTime      |-> sourceTime.value,
         sourceTimeNs    |-> sourceTimeNs.value,
         symbolIndex     |-> symbolIndex.value,
         symbolSeqNumber |-> symbolSeqNumber.value,
         originalTradeId |-> originalTradeId.value,
         marketId        |-> marketId.value ], marketId.rest)

ZeroConsolidatedTradeCancelMessage ==
    [ sourceTime      |-> [i \in 1 .. 4 |-> 0],
      sourceTimeNs    |-> [i \in 1 .. 4 |-> 0],
      symbolIndex     |-> [i \in 1 .. 4 |-> 0],
      symbolSeqNumber |-> [i \in 1 .. 4 |-> 0],
      originalTradeId |-> [i \in 1 .. 4 |-> 0],
      marketId        |-> [i \in 1 .. 2 |-> 0] ]

(* Consolidated Trade Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedConsolidatedTradeCancelMessage ==
    { ZeroConsolidatedTradeCancelMessage }
        \cup { [ZeroConsolidatedTradeCancelMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedTradeCancelMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedTradeCancelMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedTradeCancelMessage EXCEPT !.symbolSeqNumber = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedTradeCancelMessage EXCEPT !.originalTradeId = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedTradeCancelMessage EXCEPT !.marketId = one] : one \in Sample(2) }

(***************************************************************************)
(* Trf Fractional Trade Correction Message: 50 bytes                       *)
(***************************************************************************)

TrfFractionalTradeCorrectionMessage ==
    [ sourceTime       : Sample(4),
      sourceTimeNs     : Sample(4),
      symbolIndex      : Sample(4),
      symbolSeqNum     : Sample(4),
      originalTradeId  : Sample(4),
      tradeId          : Sample(4),
      price            : Sample(4),
      fractionalVolume : Sample(8),
      tradeCond1       : Sample(1),
      tradeCond2       : Sample(1),
      tradeCond3       : Sample(1),
      tradeCond4       : Sample(1),
      execDayTime      : Sample(4),
      execDayTimeNs    : Sample(4),
      marketId         : Sample(2) ]

EncodeTrfFractionalTradeCorrectionMessage(message) ==
    message.sourceTime
        \o message.sourceTimeNs
        \o message.symbolIndex
        \o message.symbolSeqNum
        \o message.originalTradeId
        \o message.tradeId
        \o message.price
        \o message.fractionalVolume
        \o message.tradeCond1
        \o message.tradeCond2
        \o message.tradeCond3
        \o message.tradeCond4
        \o message.execDayTime
        \o message.execDayTimeNs
        \o message.marketId

DecodeTrfFractionalTradeCorrectionMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceTimeNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(sourceTimeNs.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET symbolSeqNum == ReadBytes(symbolIndex.rest, 4) IN IF ~symbolSeqNum.ok THEN Fail ELSE
    LET originalTradeId == ReadBytes(symbolSeqNum.rest, 4) IN IF ~originalTradeId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(originalTradeId.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET price == ReadBytes(tradeId.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET fractionalVolume == ReadBytes(price.rest, 8) IN IF ~fractionalVolume.ok THEN Fail ELSE
    LET tradeCond1 == ReadBytes(fractionalVolume.rest, 1) IN IF ~tradeCond1.ok THEN Fail ELSE
    LET tradeCond2 == ReadBytes(tradeCond1.rest, 1) IN IF ~tradeCond2.ok THEN Fail ELSE
    LET tradeCond3 == ReadBytes(tradeCond2.rest, 1) IN IF ~tradeCond3.ok THEN Fail ELSE
    LET tradeCond4 == ReadBytes(tradeCond3.rest, 1) IN IF ~tradeCond4.ok THEN Fail ELSE
    LET execDayTime == ReadBytes(tradeCond4.rest, 4) IN IF ~execDayTime.ok THEN Fail ELSE
    LET execDayTimeNs == ReadBytes(execDayTime.rest, 4) IN IF ~execDayTimeNs.ok THEN Fail ELSE
    LET marketId == ReadBytes(execDayTimeNs.rest, 2) IN IF ~marketId.ok THEN Fail ELSE
    Ok([ sourceTime       |-> sourceTime.value,
         sourceTimeNs     |-> sourceTimeNs.value,
         symbolIndex      |-> symbolIndex.value,
         symbolSeqNum     |-> symbolSeqNum.value,
         originalTradeId  |-> originalTradeId.value,
         tradeId          |-> tradeId.value,
         price            |-> price.value,
         fractionalVolume |-> fractionalVolume.value,
         tradeCond1       |-> tradeCond1.value,
         tradeCond2       |-> tradeCond2.value,
         tradeCond3       |-> tradeCond3.value,
         tradeCond4       |-> tradeCond4.value,
         execDayTime      |-> execDayTime.value,
         execDayTimeNs    |-> execDayTimeNs.value,
         marketId         |-> marketId.value ], marketId.rest)

ZeroTrfFractionalTradeCorrectionMessage ==
    [ sourceTime       |-> [i \in 1 .. 4 |-> 0],
      sourceTimeNs     |-> [i \in 1 .. 4 |-> 0],
      symbolIndex      |-> [i \in 1 .. 4 |-> 0],
      symbolSeqNum     |-> [i \in 1 .. 4 |-> 0],
      originalTradeId  |-> [i \in 1 .. 4 |-> 0],
      tradeId          |-> [i \in 1 .. 4 |-> 0],
      price            |-> [i \in 1 .. 4 |-> 0],
      fractionalVolume |-> [i \in 1 .. 8 |-> 0],
      tradeCond1       |-> [i \in 1 .. 1 |-> 0],
      tradeCond2       |-> [i \in 1 .. 1 |-> 0],
      tradeCond3       |-> [i \in 1 .. 1 |-> 0],
      tradeCond4       |-> [i \in 1 .. 1 |-> 0],
      execDayTime      |-> [i \in 1 .. 4 |-> 0],
      execDayTimeNs    |-> [i \in 1 .. 4 |-> 0],
      marketId         |-> [i \in 1 .. 2 |-> 0] ]

(* Trf Fractional Trade Correction Message at zero, then each field in turn at the values it is checked at *)
CheckedTrfFractionalTradeCorrectionMessage ==
    { ZeroTrfFractionalTradeCorrectionMessage }
        \cup { [ZeroTrfFractionalTradeCorrectionMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroTrfFractionalTradeCorrectionMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroTrfFractionalTradeCorrectionMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroTrfFractionalTradeCorrectionMessage EXCEPT !.symbolSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroTrfFractionalTradeCorrectionMessage EXCEPT !.originalTradeId = one] : one \in Sample(4) }
        \cup { [ZeroTrfFractionalTradeCorrectionMessage EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroTrfFractionalTradeCorrectionMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroTrfFractionalTradeCorrectionMessage EXCEPT !.fractionalVolume = one] : one \in Sample(8) }
        \cup { [ZeroTrfFractionalTradeCorrectionMessage EXCEPT !.tradeCond1 = one] : one \in Sample(1) }
        \cup { [ZeroTrfFractionalTradeCorrectionMessage EXCEPT !.tradeCond2 = one] : one \in Sample(1) }
        \cup { [ZeroTrfFractionalTradeCorrectionMessage EXCEPT !.tradeCond3 = one] : one \in Sample(1) }
        \cup { [ZeroTrfFractionalTradeCorrectionMessage EXCEPT !.tradeCond4 = one] : one \in Sample(1) }
        \cup { [ZeroTrfFractionalTradeCorrectionMessage EXCEPT !.execDayTime = one] : one \in Sample(4) }
        \cup { [ZeroTrfFractionalTradeCorrectionMessage EXCEPT !.execDayTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroTrfFractionalTradeCorrectionMessage EXCEPT !.marketId = one] : one \in Sample(2) }

(***************************************************************************)
(* Consolidated Trade Correction Message: 38 bytes                         *)
(***************************************************************************)

ConsolidatedTradeCorrectionMessage ==
    [ sourceTime      : Sample(4),
      sourceTimeNs    : Sample(4),
      symbolIndex     : Sample(4),
      symbolSeqNumber : Sample(4),
      originalTradeId : Sample(4),
      tradeId         : Sample(4),
      price           : Sample(4),
      volume          : Sample(4),
      tradeCondition1 : Sample(1),
      tradeCondition2 : Sample(1),
      tradeCondition3 : Sample(1),
      tradeCondition4 : Sample(1),
      marketId        : Sample(2) ]

EncodeConsolidatedTradeCorrectionMessage(message) ==
    message.sourceTime
        \o message.sourceTimeNs
        \o message.symbolIndex
        \o message.symbolSeqNumber
        \o message.originalTradeId
        \o message.tradeId
        \o message.price
        \o message.volume
        \o message.tradeCondition1
        \o message.tradeCondition2
        \o message.tradeCondition3
        \o message.tradeCondition4
        \o message.marketId

DecodeConsolidatedTradeCorrectionMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceTimeNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(sourceTimeNs.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET symbolSeqNumber == ReadBytes(symbolIndex.rest, 4) IN IF ~symbolSeqNumber.ok THEN Fail ELSE
    LET originalTradeId == ReadBytes(symbolSeqNumber.rest, 4) IN IF ~originalTradeId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(originalTradeId.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET price == ReadBytes(tradeId.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET volume == ReadBytes(price.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET tradeCondition1 == ReadBytes(volume.rest, 1) IN IF ~tradeCondition1.ok THEN Fail ELSE
    LET tradeCondition2 == ReadBytes(tradeCondition1.rest, 1) IN IF ~tradeCondition2.ok THEN Fail ELSE
    LET tradeCondition3 == ReadBytes(tradeCondition2.rest, 1) IN IF ~tradeCondition3.ok THEN Fail ELSE
    LET tradeCondition4 == ReadBytes(tradeCondition3.rest, 1) IN IF ~tradeCondition4.ok THEN Fail ELSE
    LET marketId == ReadBytes(tradeCondition4.rest, 2) IN IF ~marketId.ok THEN Fail ELSE
    Ok([ sourceTime      |-> sourceTime.value,
         sourceTimeNs    |-> sourceTimeNs.value,
         symbolIndex     |-> symbolIndex.value,
         symbolSeqNumber |-> symbolSeqNumber.value,
         originalTradeId |-> originalTradeId.value,
         tradeId         |-> tradeId.value,
         price           |-> price.value,
         volume          |-> volume.value,
         tradeCondition1 |-> tradeCondition1.value,
         tradeCondition2 |-> tradeCondition2.value,
         tradeCondition3 |-> tradeCondition3.value,
         tradeCondition4 |-> tradeCondition4.value,
         marketId        |-> marketId.value ], marketId.rest)

ZeroConsolidatedTradeCorrectionMessage ==
    [ sourceTime      |-> [i \in 1 .. 4 |-> 0],
      sourceTimeNs    |-> [i \in 1 .. 4 |-> 0],
      symbolIndex     |-> [i \in 1 .. 4 |-> 0],
      symbolSeqNumber |-> [i \in 1 .. 4 |-> 0],
      originalTradeId |-> [i \in 1 .. 4 |-> 0],
      tradeId         |-> [i \in 1 .. 4 |-> 0],
      price           |-> [i \in 1 .. 4 |-> 0],
      volume          |-> [i \in 1 .. 4 |-> 0],
      tradeCondition1 |-> [i \in 1 .. 1 |-> 0],
      tradeCondition2 |-> [i \in 1 .. 1 |-> 0],
      tradeCondition3 |-> [i \in 1 .. 1 |-> 0],
      tradeCondition4 |-> [i \in 1 .. 1 |-> 0],
      marketId        |-> [i \in 1 .. 2 |-> 0] ]

(* Consolidated Trade Correction Message at zero, then each field in turn at the values it is checked at *)
CheckedConsolidatedTradeCorrectionMessage ==
    { ZeroConsolidatedTradeCorrectionMessage }
        \cup { [ZeroConsolidatedTradeCorrectionMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedTradeCorrectionMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedTradeCorrectionMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedTradeCorrectionMessage EXCEPT !.symbolSeqNumber = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedTradeCorrectionMessage EXCEPT !.originalTradeId = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedTradeCorrectionMessage EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedTradeCorrectionMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedTradeCorrectionMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedTradeCorrectionMessage EXCEPT !.tradeCondition1 = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedTradeCorrectionMessage EXCEPT !.tradeCondition2 = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedTradeCorrectionMessage EXCEPT !.tradeCondition3 = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedTradeCorrectionMessage EXCEPT !.tradeCondition4 = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedTradeCorrectionMessage EXCEPT !.marketId = one] : one \in Sample(2) }

(***************************************************************************)
(* Trf Fractional Prior Day Trade Message: 44 bytes                        *)
(***************************************************************************)

TrfFractionalPriorDayTradeMessage ==
    [ sourceTime       : Sample(4),
      sourceTimeNs     : Sample(4),
      symbolIndex      : Sample(4),
      symbolSeqNum     : Sample(4),
      tradeId          : Sample(4),
      price            : Sample(4),
      fractionalVolume : Sample(8),
      tradeCond1       : Sample(1),
      tradeCond2       : Sample(1),
      tradeCond3       : Sample(1),
      tradeCond4       : Sample(1),
      priorDayTime     : Sample(4),
      priorDayTimeNs   : Sample(4) ]

EncodeTrfFractionalPriorDayTradeMessage(message) ==
    message.sourceTime
        \o message.sourceTimeNs
        \o message.symbolIndex
        \o message.symbolSeqNum
        \o message.tradeId
        \o message.price
        \o message.fractionalVolume
        \o message.tradeCond1
        \o message.tradeCond2
        \o message.tradeCond3
        \o message.tradeCond4
        \o message.priorDayTime
        \o message.priorDayTimeNs

DecodeTrfFractionalPriorDayTradeMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceTimeNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(sourceTimeNs.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET symbolSeqNum == ReadBytes(symbolIndex.rest, 4) IN IF ~symbolSeqNum.ok THEN Fail ELSE
    LET tradeId == ReadBytes(symbolSeqNum.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET price == ReadBytes(tradeId.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET fractionalVolume == ReadBytes(price.rest, 8) IN IF ~fractionalVolume.ok THEN Fail ELSE
    LET tradeCond1 == ReadBytes(fractionalVolume.rest, 1) IN IF ~tradeCond1.ok THEN Fail ELSE
    LET tradeCond2 == ReadBytes(tradeCond1.rest, 1) IN IF ~tradeCond2.ok THEN Fail ELSE
    LET tradeCond3 == ReadBytes(tradeCond2.rest, 1) IN IF ~tradeCond3.ok THEN Fail ELSE
    LET tradeCond4 == ReadBytes(tradeCond3.rest, 1) IN IF ~tradeCond4.ok THEN Fail ELSE
    LET priorDayTime == ReadBytes(tradeCond4.rest, 4) IN IF ~priorDayTime.ok THEN Fail ELSE
    LET priorDayTimeNs == ReadBytes(priorDayTime.rest, 4) IN IF ~priorDayTimeNs.ok THEN Fail ELSE
    Ok([ sourceTime       |-> sourceTime.value,
         sourceTimeNs     |-> sourceTimeNs.value,
         symbolIndex      |-> symbolIndex.value,
         symbolSeqNum     |-> symbolSeqNum.value,
         tradeId          |-> tradeId.value,
         price            |-> price.value,
         fractionalVolume |-> fractionalVolume.value,
         tradeCond1       |-> tradeCond1.value,
         tradeCond2       |-> tradeCond2.value,
         tradeCond3       |-> tradeCond3.value,
         tradeCond4       |-> tradeCond4.value,
         priorDayTime     |-> priorDayTime.value,
         priorDayTimeNs   |-> priorDayTimeNs.value ], priorDayTimeNs.rest)

ZeroTrfFractionalPriorDayTradeMessage ==
    [ sourceTime       |-> [i \in 1 .. 4 |-> 0],
      sourceTimeNs     |-> [i \in 1 .. 4 |-> 0],
      symbolIndex      |-> [i \in 1 .. 4 |-> 0],
      symbolSeqNum     |-> [i \in 1 .. 4 |-> 0],
      tradeId          |-> [i \in 1 .. 4 |-> 0],
      price            |-> [i \in 1 .. 4 |-> 0],
      fractionalVolume |-> [i \in 1 .. 8 |-> 0],
      tradeCond1       |-> [i \in 1 .. 1 |-> 0],
      tradeCond2       |-> [i \in 1 .. 1 |-> 0],
      tradeCond3       |-> [i \in 1 .. 1 |-> 0],
      tradeCond4       |-> [i \in 1 .. 1 |-> 0],
      priorDayTime     |-> [i \in 1 .. 4 |-> 0],
      priorDayTimeNs   |-> [i \in 1 .. 4 |-> 0] ]

(* Trf Fractional Prior Day Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTrfFractionalPriorDayTradeMessage ==
    { ZeroTrfFractionalPriorDayTradeMessage }
        \cup { [ZeroTrfFractionalPriorDayTradeMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroTrfFractionalPriorDayTradeMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroTrfFractionalPriorDayTradeMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroTrfFractionalPriorDayTradeMessage EXCEPT !.symbolSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroTrfFractionalPriorDayTradeMessage EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroTrfFractionalPriorDayTradeMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroTrfFractionalPriorDayTradeMessage EXCEPT !.fractionalVolume = one] : one \in Sample(8) }
        \cup { [ZeroTrfFractionalPriorDayTradeMessage EXCEPT !.tradeCond1 = one] : one \in Sample(1) }
        \cup { [ZeroTrfFractionalPriorDayTradeMessage EXCEPT !.tradeCond2 = one] : one \in Sample(1) }
        \cup { [ZeroTrfFractionalPriorDayTradeMessage EXCEPT !.tradeCond3 = one] : one \in Sample(1) }
        \cup { [ZeroTrfFractionalPriorDayTradeMessage EXCEPT !.tradeCond4 = one] : one \in Sample(1) }
        \cup { [ZeroTrfFractionalPriorDayTradeMessage EXCEPT !.priorDayTime = one] : one \in Sample(4) }
        \cup { [ZeroTrfFractionalPriorDayTradeMessage EXCEPT !.priorDayTimeNs = one] : one \in Sample(4) }

(***************************************************************************)
(* Trf Fractional Prior Day Trade Cancel Message: 40 bytes                 *)
(***************************************************************************)

TrfFractionalPriorDayTradeCancelMessage ==
    [ sourceTime       : Sample(4),
      sourceTimeNs     : Sample(4),
      symbolIndex      : Sample(4),
      symbolSeqNum     : Sample(4),
      tradeId          : Sample(4),
      price            : Sample(4),
      fractionalVolume : Sample(8),
      priorDayTime     : Sample(4),
      priorDayTimeNs   : Sample(4) ]

EncodeTrfFractionalPriorDayTradeCancelMessage(message) ==
    message.sourceTime
        \o message.sourceTimeNs
        \o message.symbolIndex
        \o message.symbolSeqNum
        \o message.tradeId
        \o message.price
        \o message.fractionalVolume
        \o message.priorDayTime
        \o message.priorDayTimeNs

DecodeTrfFractionalPriorDayTradeCancelMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceTimeNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(sourceTimeNs.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET symbolSeqNum == ReadBytes(symbolIndex.rest, 4) IN IF ~symbolSeqNum.ok THEN Fail ELSE
    LET tradeId == ReadBytes(symbolSeqNum.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET price == ReadBytes(tradeId.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET fractionalVolume == ReadBytes(price.rest, 8) IN IF ~fractionalVolume.ok THEN Fail ELSE
    LET priorDayTime == ReadBytes(fractionalVolume.rest, 4) IN IF ~priorDayTime.ok THEN Fail ELSE
    LET priorDayTimeNs == ReadBytes(priorDayTime.rest, 4) IN IF ~priorDayTimeNs.ok THEN Fail ELSE
    Ok([ sourceTime       |-> sourceTime.value,
         sourceTimeNs     |-> sourceTimeNs.value,
         symbolIndex      |-> symbolIndex.value,
         symbolSeqNum     |-> symbolSeqNum.value,
         tradeId          |-> tradeId.value,
         price            |-> price.value,
         fractionalVolume |-> fractionalVolume.value,
         priorDayTime     |-> priorDayTime.value,
         priorDayTimeNs   |-> priorDayTimeNs.value ], priorDayTimeNs.rest)

ZeroTrfFractionalPriorDayTradeCancelMessage ==
    [ sourceTime       |-> [i \in 1 .. 4 |-> 0],
      sourceTimeNs     |-> [i \in 1 .. 4 |-> 0],
      symbolIndex      |-> [i \in 1 .. 4 |-> 0],
      symbolSeqNum     |-> [i \in 1 .. 4 |-> 0],
      tradeId          |-> [i \in 1 .. 4 |-> 0],
      price            |-> [i \in 1 .. 4 |-> 0],
      fractionalVolume |-> [i \in 1 .. 8 |-> 0],
      priorDayTime     |-> [i \in 1 .. 4 |-> 0],
      priorDayTimeNs   |-> [i \in 1 .. 4 |-> 0] ]

(* Trf Fractional Prior Day Trade Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedTrfFractionalPriorDayTradeCancelMessage ==
    { ZeroTrfFractionalPriorDayTradeCancelMessage }
        \cup { [ZeroTrfFractionalPriorDayTradeCancelMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroTrfFractionalPriorDayTradeCancelMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroTrfFractionalPriorDayTradeCancelMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroTrfFractionalPriorDayTradeCancelMessage EXCEPT !.symbolSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroTrfFractionalPriorDayTradeCancelMessage EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroTrfFractionalPriorDayTradeCancelMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroTrfFractionalPriorDayTradeCancelMessage EXCEPT !.fractionalVolume = one] : one \in Sample(8) }
        \cup { [ZeroTrfFractionalPriorDayTradeCancelMessage EXCEPT !.priorDayTime = one] : one \in Sample(4) }
        \cup { [ZeroTrfFractionalPriorDayTradeCancelMessage EXCEPT !.priorDayTimeNs = one] : one \in Sample(4) }

(***************************************************************************)
(* Consolidated Fractional Stock Summary Message: 62 bytes                 *)
(***************************************************************************)

ConsolidatedFractionalStockSummaryMessage ==
    [ sourceTime                             : Sample(4),
      sourceTimeNs                           : Sample(4),
      symbolIndex                            : Sample(4),
      nyseGroupHighPrice                     : Sample(4),
      nyseGroupLowPrice                      : Sample(4),
      primaryListingMarketOfficialOpenPrice  : Sample(4),
      fractionalNyseGroupVolume              : Sample(8),
      nyseGroupMarketIdOfHighPrice           : Sample(2),
      nyseGroupMarketIdOfLowPrice            : Sample(2),
      marketIdOfOpenPrice                    : Sample(2),
      numClosePrices                         : Sample(1),
      nyseGroupMarketIdOfTheClose            : Sample(2),
      primaryListingMarketOfficialClosePrice : Sample(4),
      consolidatedHighPrice                  : Sample(4),
      consolidatedLowPrice                   : Sample(4),
      consolidatedFirstPrice                 : Sample(4),
      consolidatedLastPrice                  : Sample(4),
      complete                               : Sample(1) ]

EncodeConsolidatedFractionalStockSummaryMessage(message) ==
    message.sourceTime
        \o message.sourceTimeNs
        \o message.symbolIndex
        \o message.nyseGroupHighPrice
        \o message.nyseGroupLowPrice
        \o message.primaryListingMarketOfficialOpenPrice
        \o message.fractionalNyseGroupVolume
        \o message.nyseGroupMarketIdOfHighPrice
        \o message.nyseGroupMarketIdOfLowPrice
        \o message.marketIdOfOpenPrice
        \o message.numClosePrices
        \o message.nyseGroupMarketIdOfTheClose
        \o message.primaryListingMarketOfficialClosePrice
        \o message.consolidatedHighPrice
        \o message.consolidatedLowPrice
        \o message.consolidatedFirstPrice
        \o message.consolidatedLastPrice
        \o message.complete

DecodeConsolidatedFractionalStockSummaryMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceTimeNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(sourceTimeNs.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET nyseGroupHighPrice == ReadBytes(symbolIndex.rest, 4) IN IF ~nyseGroupHighPrice.ok THEN Fail ELSE
    LET nyseGroupLowPrice == ReadBytes(nyseGroupHighPrice.rest, 4) IN IF ~nyseGroupLowPrice.ok THEN Fail ELSE
    LET primaryListingMarketOfficialOpenPrice == ReadBytes(nyseGroupLowPrice.rest, 4) IN IF ~primaryListingMarketOfficialOpenPrice.ok THEN Fail ELSE
    LET fractionalNyseGroupVolume == ReadBytes(primaryListingMarketOfficialOpenPrice.rest, 8) IN IF ~fractionalNyseGroupVolume.ok THEN Fail ELSE
    LET nyseGroupMarketIdOfHighPrice == ReadBytes(fractionalNyseGroupVolume.rest, 2) IN IF ~nyseGroupMarketIdOfHighPrice.ok THEN Fail ELSE
    LET nyseGroupMarketIdOfLowPrice == ReadBytes(nyseGroupMarketIdOfHighPrice.rest, 2) IN IF ~nyseGroupMarketIdOfLowPrice.ok THEN Fail ELSE
    LET marketIdOfOpenPrice == ReadBytes(nyseGroupMarketIdOfLowPrice.rest, 2) IN IF ~marketIdOfOpenPrice.ok THEN Fail ELSE
    LET numClosePrices == ReadBytes(marketIdOfOpenPrice.rest, 1) IN IF ~numClosePrices.ok THEN Fail ELSE
    LET nyseGroupMarketIdOfTheClose == ReadBytes(numClosePrices.rest, 2) IN IF ~nyseGroupMarketIdOfTheClose.ok THEN Fail ELSE
    LET primaryListingMarketOfficialClosePrice == ReadBytes(nyseGroupMarketIdOfTheClose.rest, 4) IN IF ~primaryListingMarketOfficialClosePrice.ok THEN Fail ELSE
    LET consolidatedHighPrice == ReadBytes(primaryListingMarketOfficialClosePrice.rest, 4) IN IF ~consolidatedHighPrice.ok THEN Fail ELSE
    LET consolidatedLowPrice == ReadBytes(consolidatedHighPrice.rest, 4) IN IF ~consolidatedLowPrice.ok THEN Fail ELSE
    LET consolidatedFirstPrice == ReadBytes(consolidatedLowPrice.rest, 4) IN IF ~consolidatedFirstPrice.ok THEN Fail ELSE
    LET consolidatedLastPrice == ReadBytes(consolidatedFirstPrice.rest, 4) IN IF ~consolidatedLastPrice.ok THEN Fail ELSE
    LET complete == ReadBytes(consolidatedLastPrice.rest, 1) IN IF ~complete.ok THEN Fail ELSE
    Ok([ sourceTime                             |-> sourceTime.value,
         sourceTimeNs                           |-> sourceTimeNs.value,
         symbolIndex                            |-> symbolIndex.value,
         nyseGroupHighPrice                     |-> nyseGroupHighPrice.value,
         nyseGroupLowPrice                      |-> nyseGroupLowPrice.value,
         primaryListingMarketOfficialOpenPrice  |-> primaryListingMarketOfficialOpenPrice.value,
         fractionalNyseGroupVolume              |-> fractionalNyseGroupVolume.value,
         nyseGroupMarketIdOfHighPrice           |-> nyseGroupMarketIdOfHighPrice.value,
         nyseGroupMarketIdOfLowPrice            |-> nyseGroupMarketIdOfLowPrice.value,
         marketIdOfOpenPrice                    |-> marketIdOfOpenPrice.value,
         numClosePrices                         |-> numClosePrices.value,
         nyseGroupMarketIdOfTheClose            |-> nyseGroupMarketIdOfTheClose.value,
         primaryListingMarketOfficialClosePrice |-> primaryListingMarketOfficialClosePrice.value,
         consolidatedHighPrice                  |-> consolidatedHighPrice.value,
         consolidatedLowPrice                   |-> consolidatedLowPrice.value,
         consolidatedFirstPrice                 |-> consolidatedFirstPrice.value,
         consolidatedLastPrice                  |-> consolidatedLastPrice.value,
         complete                               |-> complete.value ], complete.rest)

ZeroConsolidatedFractionalStockSummaryMessage ==
    [ sourceTime                             |-> [i \in 1 .. 4 |-> 0],
      sourceTimeNs                           |-> [i \in 1 .. 4 |-> 0],
      symbolIndex                            |-> [i \in 1 .. 4 |-> 0],
      nyseGroupHighPrice                     |-> [i \in 1 .. 4 |-> 0],
      nyseGroupLowPrice                      |-> [i \in 1 .. 4 |-> 0],
      primaryListingMarketOfficialOpenPrice  |-> [i \in 1 .. 4 |-> 0],
      fractionalNyseGroupVolume              |-> [i \in 1 .. 8 |-> 0],
      nyseGroupMarketIdOfHighPrice           |-> [i \in 1 .. 2 |-> 0],
      nyseGroupMarketIdOfLowPrice            |-> [i \in 1 .. 2 |-> 0],
      marketIdOfOpenPrice                    |-> [i \in 1 .. 2 |-> 0],
      numClosePrices                         |-> [i \in 1 .. 1 |-> 0],
      nyseGroupMarketIdOfTheClose            |-> [i \in 1 .. 2 |-> 0],
      primaryListingMarketOfficialClosePrice |-> [i \in 1 .. 4 |-> 0],
      consolidatedHighPrice                  |-> [i \in 1 .. 4 |-> 0],
      consolidatedLowPrice                   |-> [i \in 1 .. 4 |-> 0],
      consolidatedFirstPrice                 |-> [i \in 1 .. 4 |-> 0],
      consolidatedLastPrice                  |-> [i \in 1 .. 4 |-> 0],
      complete                               |-> [i \in 1 .. 1 |-> 0] ]

(* Consolidated Fractional Stock Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedConsolidatedFractionalStockSummaryMessage ==
    { ZeroConsolidatedFractionalStockSummaryMessage }
        \cup { [ZeroConsolidatedFractionalStockSummaryMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedFractionalStockSummaryMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedFractionalStockSummaryMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedFractionalStockSummaryMessage EXCEPT !.nyseGroupHighPrice = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedFractionalStockSummaryMessage EXCEPT !.nyseGroupLowPrice = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedFractionalStockSummaryMessage EXCEPT !.primaryListingMarketOfficialOpenPrice = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedFractionalStockSummaryMessage EXCEPT !.fractionalNyseGroupVolume = one] : one \in Sample(8) }
        \cup { [ZeroConsolidatedFractionalStockSummaryMessage EXCEPT !.nyseGroupMarketIdOfHighPrice = one] : one \in Sample(2) }
        \cup { [ZeroConsolidatedFractionalStockSummaryMessage EXCEPT !.nyseGroupMarketIdOfLowPrice = one] : one \in Sample(2) }
        \cup { [ZeroConsolidatedFractionalStockSummaryMessage EXCEPT !.marketIdOfOpenPrice = one] : one \in Sample(2) }
        \cup { [ZeroConsolidatedFractionalStockSummaryMessage EXCEPT !.numClosePrices = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedFractionalStockSummaryMessage EXCEPT !.nyseGroupMarketIdOfTheClose = one] : one \in Sample(2) }
        \cup { [ZeroConsolidatedFractionalStockSummaryMessage EXCEPT !.primaryListingMarketOfficialClosePrice = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedFractionalStockSummaryMessage EXCEPT !.consolidatedHighPrice = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedFractionalStockSummaryMessage EXCEPT !.consolidatedLowPrice = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedFractionalStockSummaryMessage EXCEPT !.consolidatedFirstPrice = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedFractionalStockSummaryMessage EXCEPT !.consolidatedLastPrice = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedFractionalStockSummaryMessage EXCEPT !.complete = one] : one \in Sample(1) }

(***************************************************************************)
(* Consolidated Fractional Volume Message: 18 bytes                        *)
(***************************************************************************)

ConsolidatedFractionalVolumeMessage ==
    [ symbolIndex                  : Sample(4),
      symbolSeqNumber              : Sample(4),
      fractionalConsolidatedVolume : Sample(8),
      reason                       : Sample(1),
      complete                     : Sample(1) ]

EncodeConsolidatedFractionalVolumeMessage(message) ==
    message.symbolIndex
        \o message.symbolSeqNumber
        \o message.fractionalConsolidatedVolume
        \o message.reason
        \o message.complete

DecodeConsolidatedFractionalVolumeMessage(bytes) ==
    LET symbolIndex == ReadBytes(bytes, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET symbolSeqNumber == ReadBytes(symbolIndex.rest, 4) IN IF ~symbolSeqNumber.ok THEN Fail ELSE
    LET fractionalConsolidatedVolume == ReadBytes(symbolSeqNumber.rest, 8) IN IF ~fractionalConsolidatedVolume.ok THEN Fail ELSE
    LET reason == ReadBytes(fractionalConsolidatedVolume.rest, 1) IN IF ~reason.ok THEN Fail ELSE
    LET complete == ReadBytes(reason.rest, 1) IN IF ~complete.ok THEN Fail ELSE
    Ok([ symbolIndex                  |-> symbolIndex.value,
         symbolSeqNumber              |-> symbolSeqNumber.value,
         fractionalConsolidatedVolume |-> fractionalConsolidatedVolume.value,
         reason                       |-> reason.value,
         complete                     |-> complete.value ], complete.rest)

ZeroConsolidatedFractionalVolumeMessage ==
    [ symbolIndex                  |-> [i \in 1 .. 4 |-> 0],
      symbolSeqNumber              |-> [i \in 1 .. 4 |-> 0],
      fractionalConsolidatedVolume |-> [i \in 1 .. 8 |-> 0],
      reason                       |-> [i \in 1 .. 1 |-> 0],
      complete                     |-> [i \in 1 .. 1 |-> 0] ]

(* Consolidated Fractional Volume Message at zero, then each field in turn at the values it is checked at *)
CheckedConsolidatedFractionalVolumeMessage ==
    { ZeroConsolidatedFractionalVolumeMessage }
        \cup { [ZeroConsolidatedFractionalVolumeMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedFractionalVolumeMessage EXCEPT !.symbolSeqNumber = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedFractionalVolumeMessage EXCEPT !.fractionalConsolidatedVolume = one] : one \in Sample(8) }
        \cup { [ZeroConsolidatedFractionalVolumeMessage EXCEPT !.reason = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedFractionalVolumeMessage EXCEPT !.complete = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

SequenceNumberResetMessageCode == 1  \* 0x01
SourceTimeReferenceMessageCode == 2  \* 0x02
SymbolIndexMappingMessageCode == 3  \* 0x03
SymbolClearMessageCode == 32  \* 0x20
SecurityStatusMessageCode == 34  \* 0x22
RetransmissionRequestMessageCode == 10  \* 0x0a
SymbolIndexMappingRequestMessageCode == 13  \* 0x0d
RefreshRequestMessageCode == 15  \* 0x0f
MessageUnavailableMessageCode == 31  \* 0x1f
RefreshHeaderMessageCode == 35  \* 0x23
RequestResponseMessageCode == 11  \* 0x0b
HeartbeatResponseMessageCode == 12  \* 0x0c
BestQuotesMessageCode == 142  \* 0x8e
ConsolidatedSingleSidedQuoteMessageCode == 143  \* 0x8f
TrfFractionalTradeMessageCode == 210  \* 0xd2
ConsolidatedTradeMessageCode == 220  \* 0xdc
ConsolidatedTradeCancelMessageCode == 221  \* 0xdd
TrfFractionalTradeCorrectionMessageCode == 212  \* 0xd4
ConsolidatedTradeCorrectionMessageCode == 222  \* 0xde
TrfFractionalPriorDayTradeMessageCode == 213  \* 0xd5
TrfFractionalPriorDayTradeCancelMessageCode == 214  \* 0xd6
ConsolidatedFractionalStockSummaryMessageCode == 202  \* 0xca
ConsolidatedFractionalVolumeMessageCode == 201  \* 0xc9

Payload ==
    [ tag : {SequenceNumberResetMessageCode}, body : SequenceNumberResetMessage ]
        \cup [ tag : {SourceTimeReferenceMessageCode}, body : SourceTimeReferenceMessage ]
        \cup [ tag : {SymbolIndexMappingMessageCode}, body : SymbolIndexMappingMessage ]
        \cup [ tag : {SymbolClearMessageCode}, body : SymbolClearMessage ]
        \cup [ tag : {SecurityStatusMessageCode}, body : SecurityStatusMessage ]
        \cup [ tag : {RetransmissionRequestMessageCode}, body : RetransmissionRequestMessage ]
        \cup [ tag : {SymbolIndexMappingRequestMessageCode}, body : SymbolIndexMappingRequestMessage ]
        \cup [ tag : {RefreshRequestMessageCode}, body : RefreshRequestMessage ]
        \cup [ tag : {MessageUnavailableMessageCode}, body : MessageUnavailableMessage ]
        \cup [ tag : {RefreshHeaderMessageCode}, body : RefreshHeaderMessage ]
        \cup [ tag : {RequestResponseMessageCode}, body : RequestResponseMessage ]
        \cup [ tag : {HeartbeatResponseMessageCode}, body : HeartbeatResponseMessage ]
        \cup [ tag : {BestQuotesMessageCode}, body : BestQuotesMessage ]
        \cup [ tag : {ConsolidatedSingleSidedQuoteMessageCode}, body : ConsolidatedSingleSidedQuoteMessage ]
        \cup [ tag : {TrfFractionalTradeMessageCode}, body : TrfFractionalTradeMessage ]
        \cup [ tag : {ConsolidatedTradeMessageCode}, body : ConsolidatedTradeMessage ]
        \cup [ tag : {ConsolidatedTradeCancelMessageCode}, body : ConsolidatedTradeCancelMessage ]
        \cup [ tag : {TrfFractionalTradeCorrectionMessageCode}, body : TrfFractionalTradeCorrectionMessage ]
        \cup [ tag : {ConsolidatedTradeCorrectionMessageCode}, body : ConsolidatedTradeCorrectionMessage ]
        \cup [ tag : {TrfFractionalPriorDayTradeMessageCode}, body : TrfFractionalPriorDayTradeMessage ]
        \cup [ tag : {TrfFractionalPriorDayTradeCancelMessageCode}, body : TrfFractionalPriorDayTradeCancelMessage ]
        \cup [ tag : {ConsolidatedFractionalStockSummaryMessageCode}, body : ConsolidatedFractionalStockSummaryMessage ]
        \cup [ tag : {ConsolidatedFractionalVolumeMessageCode}, body : ConsolidatedFractionalVolumeMessage ]

EncodePayload(message) ==
    CASE message.tag = SequenceNumberResetMessageCode -> EncodeSequenceNumberResetMessage(message.body)
      [] message.tag = SourceTimeReferenceMessageCode -> EncodeSourceTimeReferenceMessage(message.body)
      [] message.tag = SymbolIndexMappingMessageCode -> EncodeSymbolIndexMappingMessage(message.body)
      [] message.tag = SymbolClearMessageCode -> EncodeSymbolClearMessage(message.body)
      [] message.tag = SecurityStatusMessageCode -> EncodeSecurityStatusMessage(message.body)
      [] message.tag = RetransmissionRequestMessageCode -> EncodeRetransmissionRequestMessage(message.body)
      [] message.tag = SymbolIndexMappingRequestMessageCode -> EncodeSymbolIndexMappingRequestMessage(message.body)
      [] message.tag = RefreshRequestMessageCode -> EncodeRefreshRequestMessage(message.body)
      [] message.tag = MessageUnavailableMessageCode -> EncodeMessageUnavailableMessage(message.body)
      [] message.tag = RefreshHeaderMessageCode -> EncodeRefreshHeaderMessage(message.body)
      [] message.tag = RequestResponseMessageCode -> EncodeRequestResponseMessage(message.body)
      [] message.tag = HeartbeatResponseMessageCode -> EncodeHeartbeatResponseMessage(message.body)
      [] message.tag = BestQuotesMessageCode -> EncodeBestQuotesMessage(message.body)
      [] message.tag = ConsolidatedSingleSidedQuoteMessageCode -> EncodeConsolidatedSingleSidedQuoteMessage(message.body)
      [] message.tag = TrfFractionalTradeMessageCode -> EncodeTrfFractionalTradeMessage(message.body)
      [] message.tag = ConsolidatedTradeMessageCode -> EncodeConsolidatedTradeMessage(message.body)
      [] message.tag = ConsolidatedTradeCancelMessageCode -> EncodeConsolidatedTradeCancelMessage(message.body)
      [] message.tag = TrfFractionalTradeCorrectionMessageCode -> EncodeTrfFractionalTradeCorrectionMessage(message.body)
      [] message.tag = ConsolidatedTradeCorrectionMessageCode -> EncodeConsolidatedTradeCorrectionMessage(message.body)
      [] message.tag = TrfFractionalPriorDayTradeMessageCode -> EncodeTrfFractionalPriorDayTradeMessage(message.body)
      [] message.tag = TrfFractionalPriorDayTradeCancelMessageCode -> EncodeTrfFractionalPriorDayTradeCancelMessage(message.body)
      [] message.tag = ConsolidatedFractionalStockSummaryMessageCode -> EncodeConsolidatedFractionalStockSummaryMessage(message.body)
      [] message.tag = ConsolidatedFractionalVolumeMessageCode -> EncodeConsolidatedFractionalVolumeMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = SequenceNumberResetMessageCode -> DecodeSequenceNumberResetMessage(bytes)
              [] tag = SourceTimeReferenceMessageCode -> DecodeSourceTimeReferenceMessage(bytes)
              [] tag = SymbolIndexMappingMessageCode -> DecodeSymbolIndexMappingMessage(bytes)
              [] tag = SymbolClearMessageCode -> DecodeSymbolClearMessage(bytes)
              [] tag = SecurityStatusMessageCode -> DecodeSecurityStatusMessage(bytes)
              [] tag = RetransmissionRequestMessageCode -> DecodeRetransmissionRequestMessage(bytes)
              [] tag = SymbolIndexMappingRequestMessageCode -> DecodeSymbolIndexMappingRequestMessage(bytes)
              [] tag = RefreshRequestMessageCode -> DecodeRefreshRequestMessage(bytes)
              [] tag = MessageUnavailableMessageCode -> DecodeMessageUnavailableMessage(bytes)
              [] tag = RefreshHeaderMessageCode -> DecodeRefreshHeaderMessage(bytes)
              [] tag = RequestResponseMessageCode -> DecodeRequestResponseMessage(bytes)
              [] tag = HeartbeatResponseMessageCode -> DecodeHeartbeatResponseMessage(bytes)
              [] tag = BestQuotesMessageCode -> DecodeBestQuotesMessage(bytes)
              [] tag = ConsolidatedSingleSidedQuoteMessageCode -> DecodeConsolidatedSingleSidedQuoteMessage(bytes)
              [] tag = TrfFractionalTradeMessageCode -> DecodeTrfFractionalTradeMessage(bytes)
              [] tag = ConsolidatedTradeMessageCode -> DecodeConsolidatedTradeMessage(bytes)
              [] tag = ConsolidatedTradeCancelMessageCode -> DecodeConsolidatedTradeCancelMessage(bytes)
              [] tag = TrfFractionalTradeCorrectionMessageCode -> DecodeTrfFractionalTradeCorrectionMessage(bytes)
              [] tag = ConsolidatedTradeCorrectionMessageCode -> DecodeConsolidatedTradeCorrectionMessage(bytes)
              [] tag = TrfFractionalPriorDayTradeMessageCode -> DecodeTrfFractionalPriorDayTradeMessage(bytes)
              [] tag = TrfFractionalPriorDayTradeCancelMessageCode -> DecodeTrfFractionalPriorDayTradeCancelMessage(bytes)
              [] tag = ConsolidatedFractionalStockSummaryMessageCode -> DecodeConsolidatedFractionalStockSummaryMessage(bytes)
              [] tag = ConsolidatedFractionalVolumeMessageCode -> DecodeConsolidatedFractionalVolumeMessage(bytes)
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
        \cup { [tag |-> RetransmissionRequestMessageCode, body |-> one] : one \in CheckedRetransmissionRequestMessage }
        \cup { [tag |-> SymbolIndexMappingRequestMessageCode, body |-> one] : one \in CheckedSymbolIndexMappingRequestMessage }
        \cup { [tag |-> RefreshRequestMessageCode, body |-> one] : one \in CheckedRefreshRequestMessage }
        \cup { [tag |-> MessageUnavailableMessageCode, body |-> one] : one \in CheckedMessageUnavailableMessage }
        \cup { [tag |-> RefreshHeaderMessageCode, body |-> one] : one \in CheckedRefreshHeaderMessage }
        \cup { [tag |-> RequestResponseMessageCode, body |-> one] : one \in CheckedRequestResponseMessage }
        \cup { [tag |-> HeartbeatResponseMessageCode, body |-> one] : one \in CheckedHeartbeatResponseMessage }
        \cup { [tag |-> BestQuotesMessageCode, body |-> one] : one \in CheckedBestQuotesMessage }
        \cup { [tag |-> ConsolidatedSingleSidedQuoteMessageCode, body |-> one] : one \in CheckedConsolidatedSingleSidedQuoteMessage }
        \cup { [tag |-> TrfFractionalTradeMessageCode, body |-> one] : one \in CheckedTrfFractionalTradeMessage }
        \cup { [tag |-> ConsolidatedTradeMessageCode, body |-> one] : one \in CheckedConsolidatedTradeMessage }
        \cup { [tag |-> ConsolidatedTradeCancelMessageCode, body |-> one] : one \in CheckedConsolidatedTradeCancelMessage }
        \cup { [tag |-> TrfFractionalTradeCorrectionMessageCode, body |-> one] : one \in CheckedTrfFractionalTradeCorrectionMessage }
        \cup { [tag |-> ConsolidatedTradeCorrectionMessageCode, body |-> one] : one \in CheckedConsolidatedTradeCorrectionMessage }
        \cup { [tag |-> TrfFractionalPriorDayTradeMessageCode, body |-> one] : one \in CheckedTrfFractionalPriorDayTradeMessage }
        \cup { [tag |-> TrfFractionalPriorDayTradeCancelMessageCode, body |-> one] : one \in CheckedTrfFractionalPriorDayTradeCancelMessage }
        \cup { [tag |-> ConsolidatedFractionalStockSummaryMessageCode, body |-> one] : one \in CheckedConsolidatedFractionalStockSummaryMessage }
        \cup { [tag |-> ConsolidatedFractionalVolumeMessageCode, body |-> one] : one \in CheckedConsolidatedFractionalVolumeMessage }

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
      [ZeroMessage EXCEPT !.payload = [tag |-> RetransmissionRequestMessageCode, body |-> ZeroRetransmissionRequestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SymbolIndexMappingRequestMessageCode, body |-> ZeroSymbolIndexMappingRequestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RefreshRequestMessageCode, body |-> ZeroRefreshRequestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MessageUnavailableMessageCode, body |-> ZeroMessageUnavailableMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RefreshHeaderMessageCode, body |-> ZeroRefreshHeaderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RequestResponseMessageCode, body |-> ZeroRequestResponseMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> HeartbeatResponseMessageCode, body |-> ZeroHeartbeatResponseMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> BestQuotesMessageCode, body |-> ZeroBestQuotesMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ConsolidatedSingleSidedQuoteMessageCode, body |-> ZeroConsolidatedSingleSidedQuoteMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TrfFractionalTradeMessageCode, body |-> ZeroTrfFractionalTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ConsolidatedTradeMessageCode, body |-> ZeroConsolidatedTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ConsolidatedTradeCancelMessageCode, body |-> ZeroConsolidatedTradeCancelMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TrfFractionalTradeCorrectionMessageCode, body |-> ZeroTrfFractionalTradeCorrectionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ConsolidatedTradeCorrectionMessageCode, body |-> ZeroConsolidatedTradeCorrectionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TrfFractionalPriorDayTradeMessageCode, body |-> ZeroTrfFractionalPriorDayTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TrfFractionalPriorDayTradeCancelMessageCode, body |-> ZeroTrfFractionalPriorDayTradeCancelMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ConsolidatedFractionalStockSummaryMessageCode, body |-> ZeroConsolidatedFractionalStockSummaryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ConsolidatedFractionalVolumeMessageCode, body |-> ZeroConsolidatedFractionalVolumeMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ packetSize     : Sample(2),
      deliveryFlag   : Sample(1),
      sequenceNumber : Sample(4),
      sendTime       : SendTime,
      message        : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.packetSize
        \o message.deliveryFlag
        \o EncodeUIntLE(Len(message.message), 1)
        \o message.sequenceNumber
        \o EncodeSendTime(message.sendTime)
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET packetSize == ReadBytes(bytes, 2) IN IF ~packetSize.ok THEN Fail ELSE
    LET deliveryFlag == ReadBytes(packetSize.rest, 1) IN IF ~deliveryFlag.ok THEN Fail ELSE
    LET messageCount == ReadUIntLE(deliveryFlag.rest, 1) IN IF ~messageCount.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(messageCount.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET sendTime == DecodeSendTime(sequenceNumber.rest) IN IF ~sendTime.ok THEN Fail ELSE
    LET message == ReadMessageList(sendTime.rest, messageCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ packetSize     |-> packetSize.value,
         deliveryFlag   |-> deliveryFlag.value,
         sequenceNumber |-> sequenceNumber.value,
         sendTime       |-> sendTime.value,
         message        |-> message.value ], message.rest)

ZeroPacket ==
    [ packetSize     |-> [i \in 1 .. 2 |-> 0],
      deliveryFlag   |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber |-> [i \in 1 .. 4 |-> 0],
      sendTime       |-> ZeroSendTime,
      message        |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.packetSize = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.deliveryFlag = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
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

(* Every Retransmission Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRetransmissionRequestMessage ==
    \A message \in CheckedRetransmissionRequestMessage :
        LET read == DecodeRetransmissionRequestMessage(EncodeRetransmissionRequestMessage(message))
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

(* Every Message Unavailable Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageUnavailableMessage ==
    \A message \in CheckedMessageUnavailableMessage :
        LET read == DecodeMessageUnavailableMessage(EncodeMessageUnavailableMessage(message))
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

(* Every Best Quotes Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBestQuotesMessage ==
    \A message \in CheckedBestQuotesMessage :
        LET read == DecodeBestQuotesMessage(EncodeBestQuotesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Consolidated Single Sided Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripConsolidatedSingleSidedQuoteMessage ==
    \A message \in CheckedConsolidatedSingleSidedQuoteMessage :
        LET read == DecodeConsolidatedSingleSidedQuoteMessage(EncodeConsolidatedSingleSidedQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trf Fractional Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTrfFractionalTradeMessage ==
    \A message \in CheckedTrfFractionalTradeMessage :
        LET read == DecodeTrfFractionalTradeMessage(EncodeTrfFractionalTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Consolidated Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripConsolidatedTradeMessage ==
    \A message \in CheckedConsolidatedTradeMessage :
        LET read == DecodeConsolidatedTradeMessage(EncodeConsolidatedTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Consolidated Trade Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripConsolidatedTradeCancelMessage ==
    \A message \in CheckedConsolidatedTradeCancelMessage :
        LET read == DecodeConsolidatedTradeCancelMessage(EncodeConsolidatedTradeCancelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trf Fractional Trade Correction Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTrfFractionalTradeCorrectionMessage ==
    \A message \in CheckedTrfFractionalTradeCorrectionMessage :
        LET read == DecodeTrfFractionalTradeCorrectionMessage(EncodeTrfFractionalTradeCorrectionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Consolidated Trade Correction Message decodes back to what was encoded, and leaves nothing over *)
RoundTripConsolidatedTradeCorrectionMessage ==
    \A message \in CheckedConsolidatedTradeCorrectionMessage :
        LET read == DecodeConsolidatedTradeCorrectionMessage(EncodeConsolidatedTradeCorrectionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trf Fractional Prior Day Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTrfFractionalPriorDayTradeMessage ==
    \A message \in CheckedTrfFractionalPriorDayTradeMessage :
        LET read == DecodeTrfFractionalPriorDayTradeMessage(EncodeTrfFractionalPriorDayTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trf Fractional Prior Day Trade Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTrfFractionalPriorDayTradeCancelMessage ==
    \A message \in CheckedTrfFractionalPriorDayTradeCancelMessage :
        LET read == DecodeTrfFractionalPriorDayTradeCancelMessage(EncodeTrfFractionalPriorDayTradeCancelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Consolidated Fractional Stock Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripConsolidatedFractionalStockSummaryMessage ==
    \A message \in CheckedConsolidatedFractionalStockSummaryMessage :
        LET read == DecodeConsolidatedFractionalStockSummaryMessage(EncodeConsolidatedFractionalStockSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Consolidated Fractional Volume Message decodes back to what was encoded, and leaves nothing over *)
RoundTripConsolidatedFractionalVolumeMessage ==
    \A message \in CheckedConsolidatedFractionalVolumeMessage :
        LET read == DecodeConsolidatedFractionalVolumeMessage(EncodeConsolidatedFractionalVolumeMessage(message))
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
