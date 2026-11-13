------------------- MODULE EmeraldOptions_Ais_v1_0_a_Tcp -------------------
(***************************************************************************)
(* Miami International Holdings Administrative Information Subscriber      *)
(* v1.0.a                                                                  *)
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
(* Note: Sequenced Data Packet fills what is left of the frame Sesm Packet *)
(* Length states, which is what it is read from.                           *)
(*                                                                         *)
(* Note: Application Message fills what is left of the frame Sesm Packet   *)
(* Length states, which is what it is read from.                           *)
(*                                                                         *)
(* Note: Unsequenced Data Packet fills what is left of the frame Sesm      *)
(* Packet Length states, which is what it is read from.                    *)
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
(* Sequenced Data Packet: 10 bytes                                         *)
(***************************************************************************)

SequencedDataPacket ==
    [ sequenceNumber       : Sample(8),
      matchingEngineId     : Sample(1),
      sequencedMessageType : Sample(1) ]

EncodeSequencedDataPacket(message) ==
    message.sequenceNumber
        \o message.matchingEngineId
        \o message.sequencedMessageType

DecodeSequencedDataPacket(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET matchingEngineId == ReadBytes(sequenceNumber.rest, 1) IN IF ~matchingEngineId.ok THEN Fail ELSE
    LET sequencedMessageType == ReadBytes(matchingEngineId.rest, 1) IN IF ~sequencedMessageType.ok THEN Fail ELSE
    Ok([ sequenceNumber       |-> sequenceNumber.value,
         matchingEngineId     |-> matchingEngineId.value,
         sequencedMessageType |-> sequencedMessageType.value ], sequencedMessageType.rest)

ZeroSequencedDataPacket ==
    [ sequenceNumber       |-> [i \in 1 .. 8 |-> 0],
      matchingEngineId     |-> [i \in 1 .. 1 |-> 0],
      sequencedMessageType |-> [i \in 1 .. 1 |-> 0] ]

(* Sequenced Data Packet at zero, then each field in turn at the values it is checked at *)
CheckedSequencedDataPacket ==
    { ZeroSequencedDataPacket }
        \cup { [ZeroSequencedDataPacket EXCEPT !.sequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSequencedDataPacket EXCEPT !.matchingEngineId = one] : one \in Sample(1) }
        \cup { [ZeroSequencedDataPacket EXCEPT !.sequencedMessageType = one] : one \in Sample(1) }

(***************************************************************************)
(* Refresh Request Message: 1 bytes                                        *)
(***************************************************************************)

RefreshRequestMessage ==
    [ refreshMessageType : Sample(1) ]

EncodeRefreshRequestMessage(message) ==
    message.refreshMessageType

DecodeRefreshRequestMessage(bytes) ==
    LET refreshMessageType == ReadBytes(bytes, 1) IN IF ~refreshMessageType.ok THEN Fail ELSE
    Ok([ refreshMessageType |-> refreshMessageType.value ], refreshMessageType.rest)

ZeroRefreshRequestMessage ==
    [ refreshMessageType |-> [i \in 1 .. 1 |-> 0] ]

(* Refresh Request Message at zero, then each field in turn at the values it is checked at *)
CheckedRefreshRequestMessage ==
    { ZeroRefreshRequestMessage }
        \cup { [ZeroRefreshRequestMessage EXCEPT !.refreshMessageType = one] : one \in Sample(1) }

(***************************************************************************)
(* System Time Message: 4 bytes                                            *)
(***************************************************************************)

SystemTimeMessage ==
    [ seconds : Sample(4) ]

EncodeSystemTimeMessage(message) ==
    message.seconds

DecodeSystemTimeMessage(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    Ok([ seconds |-> seconds.value ], seconds.rest)

ZeroSystemTimeMessage ==
    [ seconds |-> [i \in 1 .. 4 |-> 0] ]

(* System Time Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemTimeMessage ==
    { ZeroSystemTimeMessage }
        \cup { [ZeroSystemTimeMessage EXCEPT !.seconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Simple Series Update Message: 72 bytes                                  *)
(***************************************************************************)

SimpleSeriesUpdateMessage ==
    [ nanoseconds                           : Sample(4),
      productId                             : Sample(4),
      underlyingSymbol                      : Sample(11),
      securitySymbol                        : Sample(6),
      expirationDate                        : Sample(8),
      strikePrice                           : Sample(4),
      callOrPut                             : Sample(1),
      openingTime                           : Sample(8),
      closingTime                           : Sample(8),
      restrictedOption                      : Sample(1),
      longTermOption                        : Sample(1),
      activeOnEmerald                       : Sample(1),
      emeraldBboPostingIncrementIndicator   : Sample(1),
      liquidityAcceptanceIncrementIndicator : Sample(1),
      openingUnderlyingMarketCode           : Sample(1),
      priorityQuoteWidth                    : Sample(4),
      reserved8                             : Sample(8) ]

EncodeSimpleSeriesUpdateMessage(message) ==
    message.nanoseconds
        \o message.productId
        \o message.underlyingSymbol
        \o message.securitySymbol
        \o message.expirationDate
        \o message.strikePrice
        \o message.callOrPut
        \o message.openingTime
        \o message.closingTime
        \o message.restrictedOption
        \o message.longTermOption
        \o message.activeOnEmerald
        \o message.emeraldBboPostingIncrementIndicator
        \o message.liquidityAcceptanceIncrementIndicator
        \o message.openingUnderlyingMarketCode
        \o message.priorityQuoteWidth
        \o message.reserved8

DecodeSimpleSeriesUpdateMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET productId == ReadBytes(nanoseconds.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(productId.rest, 11) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(underlyingSymbol.rest, 6) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET expirationDate == ReadBytes(securitySymbol.rest, 8) IN IF ~expirationDate.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(expirationDate.rest, 4) IN IF ~strikePrice.ok THEN Fail ELSE
    LET callOrPut == ReadBytes(strikePrice.rest, 1) IN IF ~callOrPut.ok THEN Fail ELSE
    LET openingTime == ReadBytes(callOrPut.rest, 8) IN IF ~openingTime.ok THEN Fail ELSE
    LET closingTime == ReadBytes(openingTime.rest, 8) IN IF ~closingTime.ok THEN Fail ELSE
    LET restrictedOption == ReadBytes(closingTime.rest, 1) IN IF ~restrictedOption.ok THEN Fail ELSE
    LET longTermOption == ReadBytes(restrictedOption.rest, 1) IN IF ~longTermOption.ok THEN Fail ELSE
    LET activeOnEmerald == ReadBytes(longTermOption.rest, 1) IN IF ~activeOnEmerald.ok THEN Fail ELSE
    LET emeraldBboPostingIncrementIndicator == ReadBytes(activeOnEmerald.rest, 1) IN IF ~emeraldBboPostingIncrementIndicator.ok THEN Fail ELSE
    LET liquidityAcceptanceIncrementIndicator == ReadBytes(emeraldBboPostingIncrementIndicator.rest, 1) IN IF ~liquidityAcceptanceIncrementIndicator.ok THEN Fail ELSE
    LET openingUnderlyingMarketCode == ReadBytes(liquidityAcceptanceIncrementIndicator.rest, 1) IN IF ~openingUnderlyingMarketCode.ok THEN Fail ELSE
    LET priorityQuoteWidth == ReadBytes(openingUnderlyingMarketCode.rest, 4) IN IF ~priorityQuoteWidth.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(priorityQuoteWidth.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    Ok([ nanoseconds                           |-> nanoseconds.value,
         productId                             |-> productId.value,
         underlyingSymbol                      |-> underlyingSymbol.value,
         securitySymbol                        |-> securitySymbol.value,
         expirationDate                        |-> expirationDate.value,
         strikePrice                           |-> strikePrice.value,
         callOrPut                             |-> callOrPut.value,
         openingTime                           |-> openingTime.value,
         closingTime                           |-> closingTime.value,
         restrictedOption                      |-> restrictedOption.value,
         longTermOption                        |-> longTermOption.value,
         activeOnEmerald                       |-> activeOnEmerald.value,
         emeraldBboPostingIncrementIndicator   |-> emeraldBboPostingIncrementIndicator.value,
         liquidityAcceptanceIncrementIndicator |-> liquidityAcceptanceIncrementIndicator.value,
         openingUnderlyingMarketCode           |-> openingUnderlyingMarketCode.value,
         priorityQuoteWidth                    |-> priorityQuoteWidth.value,
         reserved8                             |-> reserved8.value ], reserved8.rest)

ZeroSimpleSeriesUpdateMessage ==
    [ nanoseconds                           |-> [i \in 1 .. 4 |-> 0],
      productId                             |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbol                      |-> [i \in 1 .. 11 |-> 0],
      securitySymbol                        |-> [i \in 1 .. 6 |-> 0],
      expirationDate                        |-> [i \in 1 .. 8 |-> 0],
      strikePrice                           |-> [i \in 1 .. 4 |-> 0],
      callOrPut                             |-> [i \in 1 .. 1 |-> 0],
      openingTime                           |-> [i \in 1 .. 8 |-> 0],
      closingTime                           |-> [i \in 1 .. 8 |-> 0],
      restrictedOption                      |-> [i \in 1 .. 1 |-> 0],
      longTermOption                        |-> [i \in 1 .. 1 |-> 0],
      activeOnEmerald                       |-> [i \in 1 .. 1 |-> 0],
      emeraldBboPostingIncrementIndicator   |-> [i \in 1 .. 1 |-> 0],
      liquidityAcceptanceIncrementIndicator |-> [i \in 1 .. 1 |-> 0],
      openingUnderlyingMarketCode           |-> [i \in 1 .. 1 |-> 0],
      priorityQuoteWidth                    |-> [i \in 1 .. 4 |-> 0],
      reserved8                             |-> [i \in 1 .. 8 |-> 0] ]

(* Simple Series Update Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleSeriesUpdateMessage ==
    { ZeroSimpleSeriesUpdateMessage }
        \cup { [ZeroSimpleSeriesUpdateMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSimpleSeriesUpdateMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleSeriesUpdateMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }
        \cup { [ZeroSimpleSeriesUpdateMessage EXCEPT !.securitySymbol = one] : one \in Sample(6) }
        \cup { [ZeroSimpleSeriesUpdateMessage EXCEPT !.expirationDate = one] : one \in Sample(8) }
        \cup { [ZeroSimpleSeriesUpdateMessage EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroSimpleSeriesUpdateMessage EXCEPT !.callOrPut = one] : one \in Sample(1) }
        \cup { [ZeroSimpleSeriesUpdateMessage EXCEPT !.openingTime = one] : one \in Sample(8) }
        \cup { [ZeroSimpleSeriesUpdateMessage EXCEPT !.closingTime = one] : one \in Sample(8) }
        \cup { [ZeroSimpleSeriesUpdateMessage EXCEPT !.restrictedOption = one] : one \in Sample(1) }
        \cup { [ZeroSimpleSeriesUpdateMessage EXCEPT !.longTermOption = one] : one \in Sample(1) }
        \cup { [ZeroSimpleSeriesUpdateMessage EXCEPT !.activeOnEmerald = one] : one \in Sample(1) }
        \cup { [ZeroSimpleSeriesUpdateMessage EXCEPT !.emeraldBboPostingIncrementIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSimpleSeriesUpdateMessage EXCEPT !.liquidityAcceptanceIncrementIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSimpleSeriesUpdateMessage EXCEPT !.openingUnderlyingMarketCode = one] : one \in Sample(1) }
        \cup { [ZeroSimpleSeriesUpdateMessage EXCEPT !.priorityQuoteWidth = one] : one \in Sample(4) }
        \cup { [ZeroSimpleSeriesUpdateMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }

(***************************************************************************)
(* Leg Definition: 15 bytes                                                *)
(***************************************************************************)

LegDefinition ==
    [ productId   : Sample(4),
      legRatioQty : Sample(2),
      legSide     : Sample(1),
      reserved8   : Sample(8) ]

EncodeLegDefinition(message) ==
    message.productId
        \o message.legRatioQty
        \o message.legSide
        \o message.reserved8

DecodeLegDefinition(bytes) ==
    LET productId == ReadBytes(bytes, 4) IN IF ~productId.ok THEN Fail ELSE
    LET legRatioQty == ReadBytes(productId.rest, 2) IN IF ~legRatioQty.ok THEN Fail ELSE
    LET legSide == ReadBytes(legRatioQty.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(legSide.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    Ok([ productId   |-> productId.value,
         legRatioQty |-> legRatioQty.value,
         legSide     |-> legSide.value,
         reserved8   |-> reserved8.value ], reserved8.rest)

ZeroLegDefinition ==
    [ productId   |-> [i \in 1 .. 4 |-> 0],
      legRatioQty |-> [i \in 1 .. 2 |-> 0],
      legSide     |-> [i \in 1 .. 1 |-> 0],
      reserved8   |-> [i \in 1 .. 8 |-> 0] ]

(* Leg Definition at zero, then each field in turn at the values it is checked at *)
CheckedLegDefinition ==
    { ZeroLegDefinition }
        \cup { [ZeroLegDefinition EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroLegDefinition EXCEPT !.legRatioQty = one] : one \in Sample(2) }
        \cup { [ZeroLegDefinition EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroLegDefinition EXCEPT !.reserved8 = one] : one \in Sample(8) }

(* A run of Leg Definition, written one after another *)
RECURSIVE EncodeLegDefinitionList(_)
EncodeLegDefinitionList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLegDefinition(Head(messages)) \o EncodeLegDefinitionList(Tail(messages))

(* As many Leg Definition as the field that counts them says *)
RECURSIVE ReadLegDefinitionList(_, _)
ReadLegDefinitionList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLegDefinition(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLegDefinitionList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Leg Definition of each kind, for the lists that carry them *)
OneLegDefinition == { ZeroLegDefinition }

(***************************************************************************)
(* Complex Strategy Definition Update Message                              *)
(***************************************************************************)

ComplexStrategyDefinitionUpdateMessage ==
    [ nanoseconds      : Sample(4),
      strategyId       : Sample(4),
      underlyingSymbol : Sample(11),
      activeOnEmerald  : Sample(1),
      reserved1        : Sample(1),
      updateReason     : Sample(1),
      reserved10       : Sample(10),
      legDefinition    : SampleLists(OneLegDefinition) ]

EncodeComplexStrategyDefinitionUpdateMessage(message) ==
    message.nanoseconds
        \o message.strategyId
        \o message.underlyingSymbol
        \o message.activeOnEmerald
        \o message.reserved1
        \o message.updateReason
        \o message.reserved10
        \o EncodeUIntBE(Len(message.legDefinition), 1)
        \o EncodeLegDefinitionList(message.legDefinition)

DecodeComplexStrategyDefinitionUpdateMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET strategyId == ReadBytes(nanoseconds.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(strategyId.rest, 11) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET activeOnEmerald == ReadBytes(underlyingSymbol.rest, 1) IN IF ~activeOnEmerald.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(activeOnEmerald.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET updateReason == ReadBytes(reserved1.rest, 1) IN IF ~updateReason.ok THEN Fail ELSE
    LET reserved10 == ReadBytes(updateReason.rest, 10) IN IF ~reserved10.ok THEN Fail ELSE
    LET numberOfLegs == ReadUIntBE(reserved10.rest, 1) IN IF ~numberOfLegs.ok THEN Fail ELSE
    LET legDefinition == ReadLegDefinitionList(numberOfLegs.rest, numberOfLegs.value) IN IF ~legDefinition.ok THEN Fail ELSE
    Ok([ nanoseconds      |-> nanoseconds.value,
         strategyId       |-> strategyId.value,
         underlyingSymbol |-> underlyingSymbol.value,
         activeOnEmerald  |-> activeOnEmerald.value,
         reserved1        |-> reserved1.value,
         updateReason     |-> updateReason.value,
         reserved10       |-> reserved10.value,
         legDefinition    |-> legDefinition.value ], legDefinition.rest)

ZeroComplexStrategyDefinitionUpdateMessage ==
    [ nanoseconds      |-> [i \in 1 .. 4 |-> 0],
      strategyId       |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbol |-> [i \in 1 .. 11 |-> 0],
      activeOnEmerald  |-> [i \in 1 .. 1 |-> 0],
      reserved1        |-> [i \in 1 .. 1 |-> 0],
      updateReason     |-> [i \in 1 .. 1 |-> 0],
      reserved10       |-> [i \in 1 .. 10 |-> 0],
      legDefinition    |-> << >> ]

(* Complex Strategy Definition Update Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexStrategyDefinitionUpdateMessage ==
    { ZeroComplexStrategyDefinitionUpdateMessage }
        \cup { [ZeroComplexStrategyDefinitionUpdateMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroComplexStrategyDefinitionUpdateMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroComplexStrategyDefinitionUpdateMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }
        \cup { [ZeroComplexStrategyDefinitionUpdateMessage EXCEPT !.activeOnEmerald = one] : one \in Sample(1) }
        \cup { [ZeroComplexStrategyDefinitionUpdateMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroComplexStrategyDefinitionUpdateMessage EXCEPT !.updateReason = one] : one \in Sample(1) }
        \cup { [ZeroComplexStrategyDefinitionUpdateMessage EXCEPT !.reserved10 = one] : one \in Sample(10) }
        \cup { [ZeroComplexStrategyDefinitionUpdateMessage EXCEPT !.legDefinition = one] : one \in SampleLists(OneLegDefinition) }

(***************************************************************************)
(* System State Message: 17 bytes                                          *)
(***************************************************************************)

SystemStateMessage ==
    [ nanoseconds  : Sample(4),
      aisVersion   : Sample(8),
      sessionId    : Sample(4),
      systemStatus : Sample(1) ]

EncodeSystemStateMessage(message) ==
    message.nanoseconds
        \o message.aisVersion
        \o message.sessionId
        \o message.systemStatus

DecodeSystemStateMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET aisVersion == ReadBytes(nanoseconds.rest, 8) IN IF ~aisVersion.ok THEN Fail ELSE
    LET sessionId == ReadBytes(aisVersion.rest, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET systemStatus == ReadBytes(sessionId.rest, 1) IN IF ~systemStatus.ok THEN Fail ELSE
    Ok([ nanoseconds  |-> nanoseconds.value,
         aisVersion   |-> aisVersion.value,
         sessionId    |-> sessionId.value,
         systemStatus |-> systemStatus.value ], systemStatus.rest)

ZeroSystemStateMessage ==
    [ nanoseconds  |-> [i \in 1 .. 4 |-> 0],
      aisVersion   |-> [i \in 1 .. 8 |-> 0],
      sessionId    |-> [i \in 1 .. 4 |-> 0],
      systemStatus |-> [i \in 1 .. 1 |-> 0] ]

(* System State Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemStateMessage ==
    { ZeroSystemStateMessage }
        \cup { [ZeroSystemStateMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSystemStateMessage EXCEPT !.aisVersion = one] : one \in Sample(8) }
        \cup { [ZeroSystemStateMessage EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroSystemStateMessage EXCEPT !.systemStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Simple Liquidity Seeking Event Notification Message: 46 bytes           *)
(***************************************************************************)

SimpleLiquiditySeekingEventNotificationMessage ==
    [ nanoseconds    : Sample(4),
      productId      : Sample(4),
      eventType      : Sample(1),
      eventId        : Sample(4),
      priceShort     : Sample(4),
      imbalanceSide  : Sample(1),
      quantity1      : Sample(4),
      quantity2      : Sample(4),
      quantity3      : Sample(4),
      quantity4      : Sample(4),
      attributableId : Sample(4),
      reserved8      : Sample(8) ]

EncodeSimpleLiquiditySeekingEventNotificationMessage(message) ==
    message.nanoseconds
        \o message.productId
        \o message.eventType
        \o message.eventId
        \o message.priceShort
        \o message.imbalanceSide
        \o message.quantity1
        \o message.quantity2
        \o message.quantity3
        \o message.quantity4
        \o message.attributableId
        \o message.reserved8

DecodeSimpleLiquiditySeekingEventNotificationMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET productId == ReadBytes(nanoseconds.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET eventType == ReadBytes(productId.rest, 1) IN IF ~eventType.ok THEN Fail ELSE
    LET eventId == ReadBytes(eventType.rest, 4) IN IF ~eventId.ok THEN Fail ELSE
    LET priceShort == ReadBytes(eventId.rest, 4) IN IF ~priceShort.ok THEN Fail ELSE
    LET imbalanceSide == ReadBytes(priceShort.rest, 1) IN IF ~imbalanceSide.ok THEN Fail ELSE
    LET quantity1 == ReadBytes(imbalanceSide.rest, 4) IN IF ~quantity1.ok THEN Fail ELSE
    LET quantity2 == ReadBytes(quantity1.rest, 4) IN IF ~quantity2.ok THEN Fail ELSE
    LET quantity3 == ReadBytes(quantity2.rest, 4) IN IF ~quantity3.ok THEN Fail ELSE
    LET quantity4 == ReadBytes(quantity3.rest, 4) IN IF ~quantity4.ok THEN Fail ELSE
    LET attributableId == ReadBytes(quantity4.rest, 4) IN IF ~attributableId.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(attributableId.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    Ok([ nanoseconds    |-> nanoseconds.value,
         productId      |-> productId.value,
         eventType      |-> eventType.value,
         eventId        |-> eventId.value,
         priceShort     |-> priceShort.value,
         imbalanceSide  |-> imbalanceSide.value,
         quantity1      |-> quantity1.value,
         quantity2      |-> quantity2.value,
         quantity3      |-> quantity3.value,
         quantity4      |-> quantity4.value,
         attributableId |-> attributableId.value,
         reserved8      |-> reserved8.value ], reserved8.rest)

ZeroSimpleLiquiditySeekingEventNotificationMessage ==
    [ nanoseconds    |-> [i \in 1 .. 4 |-> 0],
      productId      |-> [i \in 1 .. 4 |-> 0],
      eventType      |-> [i \in 1 .. 1 |-> 0],
      eventId        |-> [i \in 1 .. 4 |-> 0],
      priceShort     |-> [i \in 1 .. 4 |-> 0],
      imbalanceSide  |-> [i \in 1 .. 1 |-> 0],
      quantity1      |-> [i \in 1 .. 4 |-> 0],
      quantity2      |-> [i \in 1 .. 4 |-> 0],
      quantity3      |-> [i \in 1 .. 4 |-> 0],
      quantity4      |-> [i \in 1 .. 4 |-> 0],
      attributableId |-> [i \in 1 .. 4 |-> 0],
      reserved8      |-> [i \in 1 .. 8 |-> 0] ]

(* Simple Liquidity Seeking Event Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleLiquiditySeekingEventNotificationMessage ==
    { ZeroSimpleLiquiditySeekingEventNotificationMessage }
        \cup { [ZeroSimpleLiquiditySeekingEventNotificationMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSimpleLiquiditySeekingEventNotificationMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleLiquiditySeekingEventNotificationMessage EXCEPT !.eventType = one] : one \in Sample(1) }
        \cup { [ZeroSimpleLiquiditySeekingEventNotificationMessage EXCEPT !.eventId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleLiquiditySeekingEventNotificationMessage EXCEPT !.priceShort = one] : one \in Sample(4) }
        \cup { [ZeroSimpleLiquiditySeekingEventNotificationMessage EXCEPT !.imbalanceSide = one] : one \in Sample(1) }
        \cup { [ZeroSimpleLiquiditySeekingEventNotificationMessage EXCEPT !.quantity1 = one] : one \in Sample(4) }
        \cup { [ZeroSimpleLiquiditySeekingEventNotificationMessage EXCEPT !.quantity2 = one] : one \in Sample(4) }
        \cup { [ZeroSimpleLiquiditySeekingEventNotificationMessage EXCEPT !.quantity3 = one] : one \in Sample(4) }
        \cup { [ZeroSimpleLiquiditySeekingEventNotificationMessage EXCEPT !.quantity4 = one] : one \in Sample(4) }
        \cup { [ZeroSimpleLiquiditySeekingEventNotificationMessage EXCEPT !.attributableId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleLiquiditySeekingEventNotificationMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }

(***************************************************************************)
(* Complex Liquidity Seeking Event Notification Message: 42 bytes          *)
(***************************************************************************)

ComplexLiquiditySeekingEventNotificationMessage ==
    [ nanoseconds       : Sample(4),
      strategyId        : Sample(4),
      eventType         : Sample(1),
      eventId           : Sample(4),
      side              : Sample(1),
      priceLong         : Sample(8),
      matchedQuantity   : Sample(4),
      imbalanceQuantity : Sample(4),
      attributableId    : Sample(4),
      reserved8         : Sample(8) ]

EncodeComplexLiquiditySeekingEventNotificationMessage(message) ==
    message.nanoseconds
        \o message.strategyId
        \o message.eventType
        \o message.eventId
        \o message.side
        \o message.priceLong
        \o message.matchedQuantity
        \o message.imbalanceQuantity
        \o message.attributableId
        \o message.reserved8

DecodeComplexLiquiditySeekingEventNotificationMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET strategyId == ReadBytes(nanoseconds.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET eventType == ReadBytes(strategyId.rest, 1) IN IF ~eventType.ok THEN Fail ELSE
    LET eventId == ReadBytes(eventType.rest, 4) IN IF ~eventId.ok THEN Fail ELSE
    LET side == ReadBytes(eventId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET priceLong == ReadBytes(side.rest, 8) IN IF ~priceLong.ok THEN Fail ELSE
    LET matchedQuantity == ReadBytes(priceLong.rest, 4) IN IF ~matchedQuantity.ok THEN Fail ELSE
    LET imbalanceQuantity == ReadBytes(matchedQuantity.rest, 4) IN IF ~imbalanceQuantity.ok THEN Fail ELSE
    LET attributableId == ReadBytes(imbalanceQuantity.rest, 4) IN IF ~attributableId.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(attributableId.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    Ok([ nanoseconds       |-> nanoseconds.value,
         strategyId        |-> strategyId.value,
         eventType         |-> eventType.value,
         eventId           |-> eventId.value,
         side              |-> side.value,
         priceLong         |-> priceLong.value,
         matchedQuantity   |-> matchedQuantity.value,
         imbalanceQuantity |-> imbalanceQuantity.value,
         attributableId    |-> attributableId.value,
         reserved8         |-> reserved8.value ], reserved8.rest)

ZeroComplexLiquiditySeekingEventNotificationMessage ==
    [ nanoseconds       |-> [i \in 1 .. 4 |-> 0],
      strategyId        |-> [i \in 1 .. 4 |-> 0],
      eventType         |-> [i \in 1 .. 1 |-> 0],
      eventId           |-> [i \in 1 .. 4 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      priceLong         |-> [i \in 1 .. 8 |-> 0],
      matchedQuantity   |-> [i \in 1 .. 4 |-> 0],
      imbalanceQuantity |-> [i \in 1 .. 4 |-> 0],
      attributableId    |-> [i \in 1 .. 4 |-> 0],
      reserved8         |-> [i \in 1 .. 8 |-> 0] ]

(* Complex Liquidity Seeking Event Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexLiquiditySeekingEventNotificationMessage ==
    { ZeroComplexLiquiditySeekingEventNotificationMessage }
        \cup { [ZeroComplexLiquiditySeekingEventNotificationMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroComplexLiquiditySeekingEventNotificationMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroComplexLiquiditySeekingEventNotificationMessage EXCEPT !.eventType = one] : one \in Sample(1) }
        \cup { [ZeroComplexLiquiditySeekingEventNotificationMessage EXCEPT !.eventId = one] : one \in Sample(4) }
        \cup { [ZeroComplexLiquiditySeekingEventNotificationMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroComplexLiquiditySeekingEventNotificationMessage EXCEPT !.priceLong = one] : one \in Sample(8) }
        \cup { [ZeroComplexLiquiditySeekingEventNotificationMessage EXCEPT !.matchedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroComplexLiquiditySeekingEventNotificationMessage EXCEPT !.imbalanceQuantity = one] : one \in Sample(4) }
        \cup { [ZeroComplexLiquiditySeekingEventNotificationMessage EXCEPT !.attributableId = one] : one \in Sample(4) }
        \cup { [ZeroComplexLiquiditySeekingEventNotificationMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }

(***************************************************************************)
(* Underlying Trading Status Notification Message: 25 bytes                *)
(***************************************************************************)

UnderlyingTradingStatusNotificationMessage ==
    [ nanoseconds                      : Sample(4),
      underlyingSymbol                 : Sample(11),
      tradingStatus                    : Sample(1),
      eventReason                      : Sample(1),
      expectedEventTimeSecondsPart     : Sample(4),
      expectedEventTimeNanoSecondsPart : Sample(4) ]

EncodeUnderlyingTradingStatusNotificationMessage(message) ==
    message.nanoseconds
        \o message.underlyingSymbol
        \o message.tradingStatus
        \o message.eventReason
        \o message.expectedEventTimeSecondsPart
        \o message.expectedEventTimeNanoSecondsPart

DecodeUnderlyingTradingStatusNotificationMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(nanoseconds.rest, 11) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(underlyingSymbol.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET eventReason == ReadBytes(tradingStatus.rest, 1) IN IF ~eventReason.ok THEN Fail ELSE
    LET expectedEventTimeSecondsPart == ReadBytes(eventReason.rest, 4) IN IF ~expectedEventTimeSecondsPart.ok THEN Fail ELSE
    LET expectedEventTimeNanoSecondsPart == ReadBytes(expectedEventTimeSecondsPart.rest, 4) IN IF ~expectedEventTimeNanoSecondsPart.ok THEN Fail ELSE
    Ok([ nanoseconds                      |-> nanoseconds.value,
         underlyingSymbol                 |-> underlyingSymbol.value,
         tradingStatus                    |-> tradingStatus.value,
         eventReason                      |-> eventReason.value,
         expectedEventTimeSecondsPart     |-> expectedEventTimeSecondsPart.value,
         expectedEventTimeNanoSecondsPart |-> expectedEventTimeNanoSecondsPart.value ], expectedEventTimeNanoSecondsPart.rest)

ZeroUnderlyingTradingStatusNotificationMessage ==
    [ nanoseconds                      |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbol                 |-> [i \in 1 .. 11 |-> 0],
      tradingStatus                    |-> [i \in 1 .. 1 |-> 0],
      eventReason                      |-> [i \in 1 .. 1 |-> 0],
      expectedEventTimeSecondsPart     |-> [i \in 1 .. 4 |-> 0],
      expectedEventTimeNanoSecondsPart |-> [i \in 1 .. 4 |-> 0] ]

(* Underlying Trading Status Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedUnderlyingTradingStatusNotificationMessage ==
    { ZeroUnderlyingTradingStatusNotificationMessage }
        \cup { [ZeroUnderlyingTradingStatusNotificationMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingTradingStatusNotificationMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }
        \cup { [ZeroUnderlyingTradingStatusNotificationMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingTradingStatusNotificationMessage EXCEPT !.eventReason = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingTradingStatusNotificationMessage EXCEPT !.expectedEventTimeSecondsPart = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingTradingStatusNotificationMessage EXCEPT !.expectedEventTimeNanoSecondsPart = one] : one \in Sample(4) }

(***************************************************************************)
(* Data, selected by Message Type                                          *)
(***************************************************************************)

SystemTimeMessageCode == 49  \* "1"
SimpleSeriesUpdateMessageCode == 80  \* "P"
ComplexStrategyDefinitionUpdateMessageCode == 67  \* "C"
SystemStateMessageCode == 83  \* "S"
SimpleLiquiditySeekingEventNotificationMessageCode == 76  \* "L"
ComplexLiquiditySeekingEventNotificationMessageCode == 108  \* "l"
UnderlyingTradingStatusNotificationMessageCode == 72  \* "H"

Data ==
    [ tag : {SystemTimeMessageCode}, body : SystemTimeMessage ]
        \cup [ tag : {SimpleSeriesUpdateMessageCode}, body : SimpleSeriesUpdateMessage ]
        \cup [ tag : {ComplexStrategyDefinitionUpdateMessageCode}, body : ComplexStrategyDefinitionUpdateMessage ]
        \cup [ tag : {SystemStateMessageCode}, body : SystemStateMessage ]
        \cup [ tag : {SimpleLiquiditySeekingEventNotificationMessageCode}, body : SimpleLiquiditySeekingEventNotificationMessage ]
        \cup [ tag : {ComplexLiquiditySeekingEventNotificationMessageCode}, body : ComplexLiquiditySeekingEventNotificationMessage ]
        \cup [ tag : {UnderlyingTradingStatusNotificationMessageCode}, body : UnderlyingTradingStatusNotificationMessage ]

EncodeData(message) ==
    CASE message.tag = SystemTimeMessageCode -> EncodeSystemTimeMessage(message.body)
      [] message.tag = SimpleSeriesUpdateMessageCode -> EncodeSimpleSeriesUpdateMessage(message.body)
      [] message.tag = ComplexStrategyDefinitionUpdateMessageCode -> EncodeComplexStrategyDefinitionUpdateMessage(message.body)
      [] message.tag = SystemStateMessageCode -> EncodeSystemStateMessage(message.body)
      [] message.tag = SimpleLiquiditySeekingEventNotificationMessageCode -> EncodeSimpleLiquiditySeekingEventNotificationMessage(message.body)
      [] message.tag = ComplexLiquiditySeekingEventNotificationMessageCode -> EncodeComplexLiquiditySeekingEventNotificationMessage(message.body)
      [] message.tag = UnderlyingTradingStatusNotificationMessageCode -> EncodeUnderlyingTradingStatusNotificationMessage(message.body)

DecodeData(tag, bytes) ==
    LET read ==
            CASE tag = SystemTimeMessageCode -> DecodeSystemTimeMessage(bytes)
              [] tag = SimpleSeriesUpdateMessageCode -> DecodeSimpleSeriesUpdateMessage(bytes)
              [] tag = ComplexStrategyDefinitionUpdateMessageCode -> DecodeComplexStrategyDefinitionUpdateMessage(bytes)
              [] tag = SystemStateMessageCode -> DecodeSystemStateMessage(bytes)
              [] tag = SimpleLiquiditySeekingEventNotificationMessageCode -> DecodeSimpleLiquiditySeekingEventNotificationMessage(bytes)
              [] tag = ComplexLiquiditySeekingEventNotificationMessageCode -> DecodeComplexLiquiditySeekingEventNotificationMessage(bytes)
              [] tag = UnderlyingTradingStatusNotificationMessageCode -> DecodeUnderlyingTradingStatusNotificationMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroData == [tag |-> SystemTimeMessageCode, body |-> ZeroSystemTimeMessage]

(* Each Data in turn, at the values the message it names is checked at *)
CheckedData ==
    { [tag |-> SystemTimeMessageCode, body |-> one] : one \in CheckedSystemTimeMessage }
        \cup { [tag |-> SimpleSeriesUpdateMessageCode, body |-> one] : one \in CheckedSimpleSeriesUpdateMessage }
        \cup { [tag |-> ComplexStrategyDefinitionUpdateMessageCode, body |-> one] : one \in CheckedComplexStrategyDefinitionUpdateMessage }
        \cup { [tag |-> SystemStateMessageCode, body |-> one] : one \in CheckedSystemStateMessage }
        \cup { [tag |-> SimpleLiquiditySeekingEventNotificationMessageCode, body |-> one] : one \in CheckedSimpleLiquiditySeekingEventNotificationMessage }
        \cup { [tag |-> ComplexLiquiditySeekingEventNotificationMessageCode, body |-> one] : one \in CheckedComplexLiquiditySeekingEventNotificationMessage }
        \cup { [tag |-> UnderlyingTradingStatusNotificationMessageCode, body |-> one] : one \in CheckedUnderlyingTradingStatusNotificationMessage }

(***************************************************************************)
(* Application Message                                                     *)
(***************************************************************************)

ApplicationMessage ==
    [ data : Data ]

EncodeApplicationMessage(message) ==
    EncodeUIntBE(message.data.tag, 1)
        \o EncodeData(message.data)

DecodeApplicationMessage(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET data == DecodeData(messageType.value, messageType.rest) IN IF ~data.ok THEN Fail ELSE
    Ok([ data |-> data.value ], data.rest)

ZeroApplicationMessage ==
    [ data |-> ZeroData ]

(* Application Message at zero, then each field in turn at the values it is checked at *)
CheckedApplicationMessage ==
    { ZeroApplicationMessage }
        \cup { [ZeroApplicationMessage EXCEPT !.data = one] : one \in CheckedData }

(***************************************************************************)
(* Refresh Response Message                                                *)
(***************************************************************************)

RefreshResponseMessage ==
    [ sequenceNumber     : Sample(8),
      applicationMessage : ApplicationMessage ]

EncodeRefreshResponseMessage(message) ==
    message.sequenceNumber
        \o EncodeApplicationMessage(message.applicationMessage)

DecodeRefreshResponseMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET applicationMessage == DecodeApplicationMessage(sequenceNumber.rest) IN IF ~applicationMessage.ok THEN Fail ELSE
    Ok([ sequenceNumber     |-> sequenceNumber.value,
         applicationMessage |-> applicationMessage.value ], applicationMessage.rest)

ZeroRefreshResponseMessage ==
    [ sequenceNumber     |-> [i \in 1 .. 8 |-> 0],
      applicationMessage |-> ZeroApplicationMessage ]

(* Refresh Response Message at zero, then each field in turn at the values it is checked at *)
CheckedRefreshResponseMessage ==
    { ZeroRefreshResponseMessage }
        \cup { [ZeroRefreshResponseMessage EXCEPT !.sequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroRefreshResponseMessage EXCEPT !.applicationMessage = one] : one \in CheckedApplicationMessage }

(***************************************************************************)
(* End Of Refresh Notification Message: 1 bytes                            *)
(***************************************************************************)

EndOfRefreshNotificationMessage ==
    [ refreshMessageType : Sample(1) ]

EncodeEndOfRefreshNotificationMessage(message) ==
    message.refreshMessageType

DecodeEndOfRefreshNotificationMessage(bytes) ==
    LET refreshMessageType == ReadBytes(bytes, 1) IN IF ~refreshMessageType.ok THEN Fail ELSE
    Ok([ refreshMessageType |-> refreshMessageType.value ], refreshMessageType.rest)

ZeroEndOfRefreshNotificationMessage ==
    [ refreshMessageType |-> [i \in 1 .. 1 |-> 0] ]

(* End Of Refresh Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfRefreshNotificationMessage ==
    { ZeroEndOfRefreshNotificationMessage }
        \cup { [ZeroEndOfRefreshNotificationMessage EXCEPT !.refreshMessageType = one] : one \in Sample(1) }

(***************************************************************************)
(* Unsequenced Message, selected by Unsequenced Message Type               *)
(***************************************************************************)

RefreshRequestMessageCode == 82  \* "R"
RefreshResponseMessageCode == 114  \* "r"
EndOfRefreshNotificationMessageCode == 69  \* "E"

UnsequencedMessage ==
    [ tag : {RefreshRequestMessageCode}, body : RefreshRequestMessage ]
        \cup [ tag : {RefreshResponseMessageCode}, body : RefreshResponseMessage ]
        \cup [ tag : {EndOfRefreshNotificationMessageCode}, body : EndOfRefreshNotificationMessage ]

EncodeUnsequencedMessage(message) ==
    CASE message.tag = RefreshRequestMessageCode -> EncodeRefreshRequestMessage(message.body)
      [] message.tag = RefreshResponseMessageCode -> EncodeRefreshResponseMessage(message.body)
      [] message.tag = EndOfRefreshNotificationMessageCode -> EncodeEndOfRefreshNotificationMessage(message.body)

DecodeUnsequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = RefreshRequestMessageCode -> DecodeRefreshRequestMessage(bytes)
              [] tag = RefreshResponseMessageCode -> DecodeRefreshResponseMessage(bytes)
              [] tag = EndOfRefreshNotificationMessageCode -> DecodeEndOfRefreshNotificationMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroUnsequencedMessage == [tag |-> RefreshRequestMessageCode, body |-> ZeroRefreshRequestMessage]

(* Each Unsequenced Message in turn, at the values the message it names is checked at *)
CheckedUnsequencedMessage ==
    { [tag |-> RefreshRequestMessageCode, body |-> one] : one \in CheckedRefreshRequestMessage }
        \cup { [tag |-> RefreshResponseMessageCode, body |-> one] : one \in CheckedRefreshResponseMessage }
        \cup { [tag |-> EndOfRefreshNotificationMessageCode, body |-> one] : one \in CheckedEndOfRefreshNotificationMessage }

(***************************************************************************)
(* Unsequenced Data Packet                                                 *)
(***************************************************************************)

UnsequencedDataPacket ==
    [ unsequencedMessage : UnsequencedMessage ]

EncodeUnsequencedDataPacket(message) ==
    EncodeUIntBE(message.unsequencedMessage.tag, 1)
        \o EncodeUnsequencedMessage(message.unsequencedMessage)

DecodeUnsequencedDataPacket(bytes) ==
    LET unsequencedMessageType == ReadUIntBE(bytes, 1) IN IF ~unsequencedMessageType.ok THEN Fail ELSE
    LET unsequencedMessage == DecodeUnsequencedMessage(unsequencedMessageType.value, unsequencedMessageType.rest) IN IF ~unsequencedMessage.ok THEN Fail ELSE
    Ok([ unsequencedMessage |-> unsequencedMessage.value ], unsequencedMessage.rest)

ZeroUnsequencedDataPacket ==
    [ unsequencedMessage |-> ZeroUnsequencedMessage ]

(* Unsequenced Data Packet at zero, then each field in turn at the values it is checked at *)
CheckedUnsequencedDataPacket ==
    { ZeroUnsequencedDataPacket }
        \cup { [ZeroUnsequencedDataPacket EXCEPT !.unsequencedMessage = one] : one \in CheckedUnsequencedMessage }

(***************************************************************************)
(* Login Request: 35 bytes                                                 *)
(***************************************************************************)

LoginRequest ==
    [ sesmVersion               : Sample(5),
      username                  : Sample(5),
      computerId                : Sample(8),
      applicationProtocol       : Sample(8),
      requestedTradingSessionId : Sample(1),
      requestedSequenceNumber   : Sample(8) ]

EncodeLoginRequest(message) ==
    message.sesmVersion
        \o message.username
        \o message.computerId
        \o message.applicationProtocol
        \o message.requestedTradingSessionId
        \o message.requestedSequenceNumber

DecodeLoginRequest(bytes) ==
    LET sesmVersion == ReadBytes(bytes, 5) IN IF ~sesmVersion.ok THEN Fail ELSE
    LET username == ReadBytes(sesmVersion.rest, 5) IN IF ~username.ok THEN Fail ELSE
    LET computerId == ReadBytes(username.rest, 8) IN IF ~computerId.ok THEN Fail ELSE
    LET applicationProtocol == ReadBytes(computerId.rest, 8) IN IF ~applicationProtocol.ok THEN Fail ELSE
    LET requestedTradingSessionId == ReadBytes(applicationProtocol.rest, 1) IN IF ~requestedTradingSessionId.ok THEN Fail ELSE
    LET requestedSequenceNumber == ReadBytes(requestedTradingSessionId.rest, 8) IN IF ~requestedSequenceNumber.ok THEN Fail ELSE
    Ok([ sesmVersion               |-> sesmVersion.value,
         username                  |-> username.value,
         computerId                |-> computerId.value,
         applicationProtocol       |-> applicationProtocol.value,
         requestedTradingSessionId |-> requestedTradingSessionId.value,
         requestedSequenceNumber   |-> requestedSequenceNumber.value ], requestedSequenceNumber.rest)

ZeroLoginRequest ==
    [ sesmVersion               |-> [i \in 1 .. 5 |-> 0],
      username                  |-> [i \in 1 .. 5 |-> 0],
      computerId                |-> [i \in 1 .. 8 |-> 0],
      applicationProtocol       |-> [i \in 1 .. 8 |-> 0],
      requestedTradingSessionId |-> [i \in 1 .. 1 |-> 0],
      requestedSequenceNumber   |-> [i \in 1 .. 8 |-> 0] ]

(* Login Request at zero, then each field in turn at the values it is checked at *)
CheckedLoginRequest ==
    { ZeroLoginRequest }
        \cup { [ZeroLoginRequest EXCEPT !.sesmVersion = one] : one \in Sample(5) }
        \cup { [ZeroLoginRequest EXCEPT !.username = one] : one \in Sample(5) }
        \cup { [ZeroLoginRequest EXCEPT !.computerId = one] : one \in Sample(8) }
        \cup { [ZeroLoginRequest EXCEPT !.applicationProtocol = one] : one \in Sample(8) }
        \cup { [ZeroLoginRequest EXCEPT !.requestedTradingSessionId = one] : one \in Sample(1) }
        \cup { [ZeroLoginRequest EXCEPT !.requestedSequenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Login Response: 11 bytes                                                *)
(***************************************************************************)

LoginResponse ==
    [ numberOfMatchingEngines : Sample(1),
      loginStatus             : Sample(1),
      tradingSessionId        : Sample(1),
      highestSequenceNumber   : Sample(8) ]

EncodeLoginResponse(message) ==
    message.numberOfMatchingEngines
        \o message.loginStatus
        \o message.tradingSessionId
        \o message.highestSequenceNumber

DecodeLoginResponse(bytes) ==
    LET numberOfMatchingEngines == ReadBytes(bytes, 1) IN IF ~numberOfMatchingEngines.ok THEN Fail ELSE
    LET loginStatus == ReadBytes(numberOfMatchingEngines.rest, 1) IN IF ~loginStatus.ok THEN Fail ELSE
    LET tradingSessionId == ReadBytes(loginStatus.rest, 1) IN IF ~tradingSessionId.ok THEN Fail ELSE
    LET highestSequenceNumber == ReadBytes(tradingSessionId.rest, 8) IN IF ~highestSequenceNumber.ok THEN Fail ELSE
    Ok([ numberOfMatchingEngines |-> numberOfMatchingEngines.value,
         loginStatus             |-> loginStatus.value,
         tradingSessionId        |-> tradingSessionId.value,
         highestSequenceNumber   |-> highestSequenceNumber.value ], highestSequenceNumber.rest)

ZeroLoginResponse ==
    [ numberOfMatchingEngines |-> [i \in 1 .. 1 |-> 0],
      loginStatus             |-> [i \in 1 .. 1 |-> 0],
      tradingSessionId        |-> [i \in 1 .. 1 |-> 0],
      highestSequenceNumber   |-> [i \in 1 .. 8 |-> 0] ]

(* Login Response at zero, then each field in turn at the values it is checked at *)
CheckedLoginResponse ==
    { ZeroLoginResponse }
        \cup { [ZeroLoginResponse EXCEPT !.numberOfMatchingEngines = one] : one \in Sample(1) }
        \cup { [ZeroLoginResponse EXCEPT !.loginStatus = one] : one \in Sample(1) }
        \cup { [ZeroLoginResponse EXCEPT !.tradingSessionId = one] : one \in Sample(1) }
        \cup { [ZeroLoginResponse EXCEPT !.highestSequenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Synchronization Complete: 1 bytes                                       *)
(***************************************************************************)

SynchronizationComplete ==
    [ numberOfMatchingEngines : Sample(1) ]

EncodeSynchronizationComplete(message) ==
    message.numberOfMatchingEngines

DecodeSynchronizationComplete(bytes) ==
    LET numberOfMatchingEngines == ReadBytes(bytes, 1) IN IF ~numberOfMatchingEngines.ok THEN Fail ELSE
    Ok([ numberOfMatchingEngines |-> numberOfMatchingEngines.value ], numberOfMatchingEngines.rest)

ZeroSynchronizationComplete ==
    [ numberOfMatchingEngines |-> [i \in 1 .. 1 |-> 0] ]

(* Synchronization Complete at zero, then each field in turn at the values it is checked at *)
CheckedSynchronizationComplete ==
    { ZeroSynchronizationComplete }
        \cup { [ZeroSynchronizationComplete EXCEPT !.numberOfMatchingEngines = one] : one \in Sample(1) }

(***************************************************************************)
(* Retransmission Request: 16 bytes                                        *)
(***************************************************************************)

RetransmissionRequest ==
    [ startSequenceNumber : Sample(8),
      endSequenceNumber   : Sample(8) ]

EncodeRetransmissionRequest(message) ==
    message.startSequenceNumber
        \o message.endSequenceNumber

DecodeRetransmissionRequest(bytes) ==
    LET startSequenceNumber == ReadBytes(bytes, 8) IN IF ~startSequenceNumber.ok THEN Fail ELSE
    LET endSequenceNumber == ReadBytes(startSequenceNumber.rest, 8) IN IF ~endSequenceNumber.ok THEN Fail ELSE
    Ok([ startSequenceNumber |-> startSequenceNumber.value,
         endSequenceNumber   |-> endSequenceNumber.value ], endSequenceNumber.rest)

ZeroRetransmissionRequest ==
    [ startSequenceNumber |-> [i \in 1 .. 8 |-> 0],
      endSequenceNumber   |-> [i \in 1 .. 8 |-> 0] ]

(* Retransmission Request at zero, then each field in turn at the values it is checked at *)
CheckedRetransmissionRequest ==
    { ZeroRetransmissionRequest }
        \cup { [ZeroRetransmissionRequest EXCEPT !.startSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroRetransmissionRequest EXCEPT !.endSequenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Logout Request                                                          *)
(***************************************************************************)

LogoutRequest ==
    [ logoutReason : Sample(1),
      logoutText   : SampleBytes ]

EncodeLogoutRequest(message) ==
    message.logoutReason
        \o message.logoutText

DecodeLogoutRequest(bytes) ==
    LET logoutReason == ReadBytes(bytes, 1) IN IF ~logoutReason.ok THEN Fail ELSE
    LET logoutText == Ok(logoutReason.rest, << >>) IN IF ~logoutText.ok THEN Fail ELSE
    Ok([ logoutReason |-> logoutReason.value,
         logoutText   |-> logoutText.value ], logoutText.rest)

ZeroLogoutRequest ==
    [ logoutReason |-> [i \in 1 .. 1 |-> 0],
      logoutText   |-> << >> ]

(* Logout Request at zero, then each field in turn at the values it is checked at *)
CheckedLogoutRequest ==
    { ZeroLogoutRequest }
        \cup { [ZeroLogoutRequest EXCEPT !.logoutReason = one] : one \in Sample(1) }
        \cup { [ZeroLogoutRequest EXCEPT !.logoutText = one] : one \in SampleBytes }

(***************************************************************************)
(* Goodbye Packet                                                          *)
(***************************************************************************)

GoodbyePacket ==
    [ logoutReason : Sample(1),
      logoutText   : SampleBytes ]

EncodeGoodbyePacket(message) ==
    message.logoutReason
        \o message.logoutText

DecodeGoodbyePacket(bytes) ==
    LET logoutReason == ReadBytes(bytes, 1) IN IF ~logoutReason.ok THEN Fail ELSE
    LET logoutText == Ok(logoutReason.rest, << >>) IN IF ~logoutText.ok THEN Fail ELSE
    Ok([ logoutReason |-> logoutReason.value,
         logoutText   |-> logoutText.value ], logoutText.rest)

ZeroGoodbyePacket ==
    [ logoutReason |-> [i \in 1 .. 1 |-> 0],
      logoutText   |-> << >> ]

(* Goodbye Packet at zero, then each field in turn at the values it is checked at *)
CheckedGoodbyePacket ==
    { ZeroGoodbyePacket }
        \cup { [ZeroGoodbyePacket EXCEPT !.logoutReason = one] : one \in Sample(1) }
        \cup { [ZeroGoodbyePacket EXCEPT !.logoutText = one] : one \in SampleBytes }

(***************************************************************************)
(* Test Packet                                                             *)
(***************************************************************************)

TestPacket ==
    [ testText : SampleBytes ]

EncodeTestPacket(message) ==
    message.testText

DecodeTestPacket(bytes) ==
    LET testText == Ok(bytes, << >>) IN IF ~testText.ok THEN Fail ELSE
    Ok([ testText |-> testText.value ], testText.rest)

ZeroTestPacket ==
    [ testText |-> << >> ]

(* Test Packet at zero, then each field in turn at the values it is checked at *)
CheckedTestPacket ==
    { ZeroTestPacket }
        \cup { [ZeroTestPacket EXCEPT !.testText = one] : one \in SampleBytes }

(***************************************************************************)
(* Sesm Payload, selected by Sesm Packet Type                              *)
(***************************************************************************)

SequencedDataPacketCode == 115  \* "s"
UnsequencedDataPacketCode == 85  \* "U"
LoginRequestCode == 108  \* "l"
LoginResponseCode == 114  \* "r"
SynchronizationCompleteCode == 99  \* "c"
RetransmissionRequestCode == 97  \* "a"
LogoutRequestCode == 88  \* "X"
GoodbyePacketCode == 71  \* "G"
TradingSessionUpdateCode == 117  \* "u"
ServerHeartbeatCode == 48  \* "0"
ClientHeartbeatCode == 49  \* "1"
TestPacketCode == 84  \* "T"

SesmPayload ==
    [ tag : {SequencedDataPacketCode}, body : SequencedDataPacket ]
        \cup [ tag : {UnsequencedDataPacketCode}, body : UnsequencedDataPacket ]
        \cup [ tag : {LoginRequestCode}, body : LoginRequest ]
        \cup [ tag : {LoginResponseCode}, body : LoginResponse ]
        \cup [ tag : {SynchronizationCompleteCode}, body : SynchronizationComplete ]
        \cup [ tag : {RetransmissionRequestCode}, body : RetransmissionRequest ]
        \cup [ tag : {LogoutRequestCode}, body : LogoutRequest ]
        \cup [ tag : {GoodbyePacketCode}, body : GoodbyePacket ]
        \cup [ tag : {TradingSessionUpdateCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ServerHeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ClientHeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {TestPacketCode}, body : TestPacket ]

EncodeSesmPayload(message) ==
    CASE message.tag = SequencedDataPacketCode -> EncodeSequencedDataPacket(message.body)
      [] message.tag = UnsequencedDataPacketCode -> EncodeUnsequencedDataPacket(message.body)
      [] message.tag = LoginRequestCode -> EncodeLoginRequest(message.body)
      [] message.tag = LoginResponseCode -> EncodeLoginResponse(message.body)
      [] message.tag = SynchronizationCompleteCode -> EncodeSynchronizationComplete(message.body)
      [] message.tag = RetransmissionRequestCode -> EncodeRetransmissionRequest(message.body)
      [] message.tag = LogoutRequestCode -> EncodeLogoutRequest(message.body)
      [] message.tag = GoodbyePacketCode -> EncodeGoodbyePacket(message.body)
      [] message.tag = TradingSessionUpdateCode -> << >>
      [] message.tag = ServerHeartbeatCode -> << >>
      [] message.tag = ClientHeartbeatCode -> << >>
      [] message.tag = TestPacketCode -> EncodeTestPacket(message.body)

DecodeSesmPayload(tag, bytes) ==
    LET read ==
            CASE tag = SequencedDataPacketCode -> DecodeSequencedDataPacket(bytes)
              [] tag = UnsequencedDataPacketCode -> DecodeUnsequencedDataPacket(bytes)
              [] tag = LoginRequestCode -> DecodeLoginRequest(bytes)
              [] tag = LoginResponseCode -> DecodeLoginResponse(bytes)
              [] tag = SynchronizationCompleteCode -> DecodeSynchronizationComplete(bytes)
              [] tag = RetransmissionRequestCode -> DecodeRetransmissionRequest(bytes)
              [] tag = LogoutRequestCode -> DecodeLogoutRequest(bytes)
              [] tag = GoodbyePacketCode -> DecodeGoodbyePacket(bytes)
              [] tag = TradingSessionUpdateCode -> Ok([empty |-> 0], bytes)
              [] tag = ServerHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = ClientHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = TestPacketCode -> DecodeTestPacket(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSesmPayload == [tag |-> SequencedDataPacketCode, body |-> ZeroSequencedDataPacket]

(* Each Sesm Payload in turn, at the values the message it names is checked at *)
CheckedSesmPayload ==
    { [tag |-> SequencedDataPacketCode, body |-> one] : one \in CheckedSequencedDataPacket }
        \cup { [tag |-> UnsequencedDataPacketCode, body |-> one] : one \in CheckedUnsequencedDataPacket }
        \cup { [tag |-> LoginRequestCode, body |-> one] : one \in CheckedLoginRequest }
        \cup { [tag |-> LoginResponseCode, body |-> one] : one \in CheckedLoginResponse }
        \cup { [tag |-> SynchronizationCompleteCode, body |-> one] : one \in CheckedSynchronizationComplete }
        \cup { [tag |-> RetransmissionRequestCode, body |-> one] : one \in CheckedRetransmissionRequest }
        \cup { [tag |-> LogoutRequestCode, body |-> one] : one \in CheckedLogoutRequest }
        \cup { [tag |-> GoodbyePacketCode, body |-> one] : one \in CheckedGoodbyePacket }
        \cup { [tag |-> TradingSessionUpdateCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> ServerHeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> ClientHeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> TestPacketCode, body |-> one] : one \in CheckedTestPacket }

(***************************************************************************)
(* Sesm Tcp Packet, framed by Sesm Packet Length                           *)
(***************************************************************************)

SesmTcpPacket ==
    [ sesmPayload : SesmPayload ]

EncodeSesmTcpPacketBody(message) ==
    EncodeUIntBE(message.sesmPayload.tag, 1)
        \o EncodeSesmPayload(message.sesmPayload)

(* Sesm Packet Length counts the bytes it frames, so it is written from them *)
EncodeSesmTcpPacket(message) ==
    LET body == EncodeSesmTcpPacketBody(message)
    IN  EncodeUIntLE(Len(body), 2) \o body

DecodeSesmTcpPacketBody(bytes) ==
    LET sesmPacketType == ReadUIntBE(bytes, 1) IN IF ~sesmPacketType.ok THEN Fail ELSE
    LET sesmPayload == DecodeSesmPayload(sesmPacketType.value, sesmPacketType.rest) IN IF ~sesmPayload.ok THEN Fail ELSE
    Ok([ sesmPayload |-> sesmPayload.value ], sesmPayload.rest)

DecodeSesmTcpPacket(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeSesmTcpPacketBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroSesmTcpPacket ==
    [ sesmPayload |-> ZeroSesmPayload ]

(* Sesm Tcp Packet at zero, then each field in turn at the values it is checked at *)
CheckedSesmTcpPacket ==
    { ZeroSesmTcpPacket }
        \cup { [ZeroSesmTcpPacket EXCEPT !.sesmPayload = one] : one \in CheckedSesmPayload }

(* A run of Sesm Tcp Packet, written one after another *)
RECURSIVE EncodeSesmTcpPacketList(_)
EncodeSesmTcpPacketList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSesmTcpPacket(Head(messages)) \o EncodeSesmTcpPacketList(Tail(messages))

(* As many Sesm Tcp Packet as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadSesmTcpPacketAll(_)
ReadSesmTcpPacketAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeSesmTcpPacket(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSesmTcpPacketAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Sesm Tcp Packet of each kind, for the lists that carry them *)
OneSesmTcpPacket ==
    { [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> SequencedDataPacketCode, body |-> ZeroSequencedDataPacket]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> UnsequencedDataPacketCode, body |-> ZeroUnsequencedDataPacket]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> LoginRequestCode, body |-> ZeroLoginRequest]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> LoginResponseCode, body |-> ZeroLoginResponse]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> SynchronizationCompleteCode, body |-> ZeroSynchronizationComplete]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> RetransmissionRequestCode, body |-> ZeroRetransmissionRequest]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> LogoutRequestCode, body |-> ZeroLogoutRequest]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> GoodbyePacketCode, body |-> ZeroGoodbyePacket]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> TradingSessionUpdateCode, body |-> [empty |-> 0]]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> ServerHeartbeatCode, body |-> [empty |-> 0]]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> ClientHeartbeatCode, body |-> [empty |-> 0]]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> TestPacketCode, body |-> ZeroTestPacket]] }

(***************************************************************************)
(* Tcp Packet                                                              *)
(***************************************************************************)

TcpPacket ==
    [ sesmTcpPacket : SampleLists(OneSesmTcpPacket) ]

EncodeTcpPacket(message) ==
    EncodeSesmTcpPacketList(message.sesmTcpPacket)

DecodeTcpPacket(bytes) ==
    LET sesmTcpPacket == ReadSesmTcpPacketAll(bytes) IN IF ~sesmTcpPacket.ok THEN Fail ELSE
    Ok([ sesmTcpPacket |-> sesmTcpPacket.value ], sesmTcpPacket.rest)

ZeroTcpPacket ==
    [ sesmTcpPacket |-> << >> ]

(* Tcp Packet at zero, then each field in turn at the values it is checked at *)
CheckedTcpPacket ==
    { ZeroTcpPacket }
        \cup { [ZeroTcpPacket EXCEPT !.sesmTcpPacket = one] : one \in SampleLists(OneSesmTcpPacket) }

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

(* Every Sequenced Data Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripSequencedDataPacket ==
    \A message \in CheckedSequencedDataPacket :
        LET read == DecodeSequencedDataPacket(EncodeSequencedDataPacket(message))
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

(* Every System Time Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSystemTimeMessage ==
    \A message \in CheckedSystemTimeMessage :
        LET read == DecodeSystemTimeMessage(EncodeSystemTimeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Series Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleSeriesUpdateMessage ==
    \A message \in CheckedSimpleSeriesUpdateMessage :
        LET read == DecodeSimpleSeriesUpdateMessage(EncodeSimpleSeriesUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Leg Definition decodes back to what was encoded, and leaves nothing over *)
RoundTripLegDefinition ==
    \A message \in CheckedLegDefinition :
        LET read == DecodeLegDefinition(EncodeLegDefinition(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Strategy Definition Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexStrategyDefinitionUpdateMessage ==
    \A message \in CheckedComplexStrategyDefinitionUpdateMessage :
        LET read == DecodeComplexStrategyDefinitionUpdateMessage(EncodeComplexStrategyDefinitionUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every System State Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSystemStateMessage ==
    \A message \in CheckedSystemStateMessage :
        LET read == DecodeSystemStateMessage(EncodeSystemStateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Liquidity Seeking Event Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleLiquiditySeekingEventNotificationMessage ==
    \A message \in CheckedSimpleLiquiditySeekingEventNotificationMessage :
        LET read == DecodeSimpleLiquiditySeekingEventNotificationMessage(EncodeSimpleLiquiditySeekingEventNotificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Liquidity Seeking Event Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexLiquiditySeekingEventNotificationMessage ==
    \A message \in CheckedComplexLiquiditySeekingEventNotificationMessage :
        LET read == DecodeComplexLiquiditySeekingEventNotificationMessage(EncodeComplexLiquiditySeekingEventNotificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Underlying Trading Status Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUnderlyingTradingStatusNotificationMessage ==
    \A message \in CheckedUnderlyingTradingStatusNotificationMessage :
        LET read == DecodeUnderlyingTradingStatusNotificationMessage(EncodeUnderlyingTradingStatusNotificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Application Message decodes back to what was encoded, and leaves nothing over *)
RoundTripApplicationMessage ==
    \A message \in CheckedApplicationMessage :
        LET read == DecodeApplicationMessage(EncodeApplicationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Refresh Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRefreshResponseMessage ==
    \A message \in CheckedRefreshResponseMessage :
        LET read == DecodeRefreshResponseMessage(EncodeRefreshResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Refresh Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfRefreshNotificationMessage ==
    \A message \in CheckedEndOfRefreshNotificationMessage :
        LET read == DecodeEndOfRefreshNotificationMessage(EncodeEndOfRefreshNotificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Unsequenced Data Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripUnsequencedDataPacket ==
    \A message \in CheckedUnsequencedDataPacket :
        LET read == DecodeUnsequencedDataPacket(EncodeUnsequencedDataPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Request decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRequest ==
    \A message \in CheckedLoginRequest :
        LET read == DecodeLoginRequest(EncodeLoginRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Response decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginResponse ==
    \A message \in CheckedLoginResponse :
        LET read == DecodeLoginResponse(EncodeLoginResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Synchronization Complete decodes back to what was encoded, and leaves nothing over *)
RoundTripSynchronizationComplete ==
    \A message \in CheckedSynchronizationComplete :
        LET read == DecodeSynchronizationComplete(EncodeSynchronizationComplete(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Retransmission Request decodes back to what was encoded, and leaves nothing over *)
RoundTripRetransmissionRequest ==
    \A message \in CheckedRetransmissionRequest :
        LET read == DecodeRetransmissionRequest(EncodeRetransmissionRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logout Request decodes back to what was encoded, and leaves nothing over *)
RoundTripLogoutRequest ==
    \A message \in CheckedLogoutRequest :
        LET read == DecodeLogoutRequest(EncodeLogoutRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Goodbye Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripGoodbyePacket ==
    \A message \in CheckedGoodbyePacket :
        LET read == DecodeGoodbyePacket(EncodeGoodbyePacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Test Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripTestPacket ==
    \A message \in CheckedTestPacket :
        LET read == DecodeTestPacket(EncodeTestPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sesm Tcp Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripSesmTcpPacket ==
    \A message \in CheckedSesmTcpPacket :
        LET read == DecodeSesmTcpPacket(EncodeSesmTcpPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tcp Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripTcpPacket ==
    \A message \in CheckedTcpPacket :
        LET read == DecodeTcpPacket(EncodeTcpPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Data is selected by the Message Type it is written under *)
SelectsData ==
    \A message \in CheckedData :
        LET sent == EncodeData(message)
            read == DecodeData(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Unsequenced Message is selected by the Unsequenced Message Type it is written under *)
SelectsUnsequencedMessage ==
    \A message \in CheckedUnsequencedMessage :
        LET sent == EncodeUnsequencedMessage(message)
            read == DecodeUnsequencedMessage(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Sesm Payload is selected by the Sesm Packet Type it is written under *)
SelectsSesmPayload ==
    \A message \in CheckedSesmPayload :
        LET sent == EncodeSesmPayload(message)
            read == DecodeSesmPayload(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* Sesm Packet Length is written from the bytes it frames *)
FramesSesmTcpPacket ==
    \A message \in CheckedSesmTcpPacket :
        LET bytes == EncodeSesmTcpPacket(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
