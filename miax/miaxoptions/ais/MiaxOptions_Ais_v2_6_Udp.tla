--------------------- MODULE MiaxOptions_Ais_v2_6_Udp ----------------------
(***************************************************************************)
(* Miami International Holdings Administrative Information Subscriber v2.6 *)
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
(* Note: Application Message fills what is left of the frame Packet Length *)
(* states, which is what it is read from.                                  *)
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
      activeOnMiax                          : Sample(1),
      miaxBboPostingIncrementIndicator      : Sample(1),
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
        \o message.activeOnMiax
        \o message.miaxBboPostingIncrementIndicator
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
    LET activeOnMiax == ReadBytes(longTermOption.rest, 1) IN IF ~activeOnMiax.ok THEN Fail ELSE
    LET miaxBboPostingIncrementIndicator == ReadBytes(activeOnMiax.rest, 1) IN IF ~miaxBboPostingIncrementIndicator.ok THEN Fail ELSE
    LET liquidityAcceptanceIncrementIndicator == ReadBytes(miaxBboPostingIncrementIndicator.rest, 1) IN IF ~liquidityAcceptanceIncrementIndicator.ok THEN Fail ELSE
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
         activeOnMiax                          |-> activeOnMiax.value,
         miaxBboPostingIncrementIndicator      |-> miaxBboPostingIncrementIndicator.value,
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
      activeOnMiax                          |-> [i \in 1 .. 1 |-> 0],
      miaxBboPostingIncrementIndicator      |-> [i \in 1 .. 1 |-> 0],
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
        \cup { [ZeroSimpleSeriesUpdateMessage EXCEPT !.activeOnMiax = one] : one \in Sample(1) }
        \cup { [ZeroSimpleSeriesUpdateMessage EXCEPT !.miaxBboPostingIncrementIndicator = one] : one \in Sample(1) }
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
      activeOnMiax     : Sample(1),
      reserved1        : Sample(1),
      updateReason     : Sample(1),
      reserved10       : Sample(10),
      legDefinition    : SampleLists(OneLegDefinition) ]

EncodeComplexStrategyDefinitionUpdateMessage(message) ==
    message.nanoseconds
        \o message.strategyId
        \o message.underlyingSymbol
        \o message.activeOnMiax
        \o message.reserved1
        \o message.updateReason
        \o message.reserved10
        \o EncodeUIntLE(Len(message.legDefinition), 1)
        \o EncodeLegDefinitionList(message.legDefinition)

DecodeComplexStrategyDefinitionUpdateMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET strategyId == ReadBytes(nanoseconds.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(strategyId.rest, 11) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET activeOnMiax == ReadBytes(underlyingSymbol.rest, 1) IN IF ~activeOnMiax.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(activeOnMiax.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET updateReason == ReadBytes(reserved1.rest, 1) IN IF ~updateReason.ok THEN Fail ELSE
    LET reserved10 == ReadBytes(updateReason.rest, 10) IN IF ~reserved10.ok THEN Fail ELSE
    LET numberOfLegs == ReadUIntLE(reserved10.rest, 1) IN IF ~numberOfLegs.ok THEN Fail ELSE
    LET legDefinition == ReadLegDefinitionList(numberOfLegs.rest, numberOfLegs.value) IN IF ~legDefinition.ok THEN Fail ELSE
    Ok([ nanoseconds      |-> nanoseconds.value,
         strategyId       |-> strategyId.value,
         underlyingSymbol |-> underlyingSymbol.value,
         activeOnMiax     |-> activeOnMiax.value,
         reserved1        |-> reserved1.value,
         updateReason     |-> updateReason.value,
         reserved10       |-> reserved10.value,
         legDefinition    |-> legDefinition.value ], legDefinition.rest)

ZeroComplexStrategyDefinitionUpdateMessage ==
    [ nanoseconds      |-> [i \in 1 .. 4 |-> 0],
      strategyId       |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbol |-> [i \in 1 .. 11 |-> 0],
      activeOnMiax     |-> [i \in 1 .. 1 |-> 0],
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
        \cup { [ZeroComplexStrategyDefinitionUpdateMessage EXCEPT !.activeOnMiax = one] : one \in Sample(1) }
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
      origin         : Sample(1),
      reserved7      : Sample(7) ]

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
        \o message.origin
        \o message.reserved7

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
    LET origin == ReadBytes(attributableId.rest, 1) IN IF ~origin.ok THEN Fail ELSE
    LET reserved7 == ReadBytes(origin.rest, 7) IN IF ~reserved7.ok THEN Fail ELSE
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
         origin         |-> origin.value,
         reserved7      |-> reserved7.value ], reserved7.rest)

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
      origin         |-> [i \in 1 .. 1 |-> 0],
      reserved7      |-> [i \in 1 .. 7 |-> 0] ]

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
        \cup { [ZeroSimpleLiquiditySeekingEventNotificationMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroSimpleLiquiditySeekingEventNotificationMessage EXCEPT !.reserved7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Complex Liquidity Seeking Event Notification Message: 42 bytes          *)
(***************************************************************************)

ComplexLiquiditySeekingEventNotificationMessage ==
    [ nanoseconds             : Sample(4),
      strategyId              : Sample(4),
      eventType               : Sample(1),
      eventId                 : Sample(4),
      side                    : Sample(1),
      priceLong               : Sample(8),
      matchedQuantity         : Sample(4),
      imbalanceQuantitySigned : Sample(4),
      attributableId          : Sample(4),
      origin                  : Sample(1),
      reserved7               : Sample(7) ]

EncodeComplexLiquiditySeekingEventNotificationMessage(message) ==
    message.nanoseconds
        \o message.strategyId
        \o message.eventType
        \o message.eventId
        \o message.side
        \o message.priceLong
        \o message.matchedQuantity
        \o message.imbalanceQuantitySigned
        \o message.attributableId
        \o message.origin
        \o message.reserved7

DecodeComplexLiquiditySeekingEventNotificationMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET strategyId == ReadBytes(nanoseconds.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET eventType == ReadBytes(strategyId.rest, 1) IN IF ~eventType.ok THEN Fail ELSE
    LET eventId == ReadBytes(eventType.rest, 4) IN IF ~eventId.ok THEN Fail ELSE
    LET side == ReadBytes(eventId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET priceLong == ReadBytes(side.rest, 8) IN IF ~priceLong.ok THEN Fail ELSE
    LET matchedQuantity == ReadBytes(priceLong.rest, 4) IN IF ~matchedQuantity.ok THEN Fail ELSE
    LET imbalanceQuantitySigned == ReadBytes(matchedQuantity.rest, 4) IN IF ~imbalanceQuantitySigned.ok THEN Fail ELSE
    LET attributableId == ReadBytes(imbalanceQuantitySigned.rest, 4) IN IF ~attributableId.ok THEN Fail ELSE
    LET origin == ReadBytes(attributableId.rest, 1) IN IF ~origin.ok THEN Fail ELSE
    LET reserved7 == ReadBytes(origin.rest, 7) IN IF ~reserved7.ok THEN Fail ELSE
    Ok([ nanoseconds             |-> nanoseconds.value,
         strategyId              |-> strategyId.value,
         eventType               |-> eventType.value,
         eventId                 |-> eventId.value,
         side                    |-> side.value,
         priceLong               |-> priceLong.value,
         matchedQuantity         |-> matchedQuantity.value,
         imbalanceQuantitySigned |-> imbalanceQuantitySigned.value,
         attributableId          |-> attributableId.value,
         origin                  |-> origin.value,
         reserved7               |-> reserved7.value ], reserved7.rest)

ZeroComplexLiquiditySeekingEventNotificationMessage ==
    [ nanoseconds             |-> [i \in 1 .. 4 |-> 0],
      strategyId              |-> [i \in 1 .. 4 |-> 0],
      eventType               |-> [i \in 1 .. 1 |-> 0],
      eventId                 |-> [i \in 1 .. 4 |-> 0],
      side                    |-> [i \in 1 .. 1 |-> 0],
      priceLong               |-> [i \in 1 .. 8 |-> 0],
      matchedQuantity         |-> [i \in 1 .. 4 |-> 0],
      imbalanceQuantitySigned |-> [i \in 1 .. 4 |-> 0],
      attributableId          |-> [i \in 1 .. 4 |-> 0],
      origin                  |-> [i \in 1 .. 1 |-> 0],
      reserved7               |-> [i \in 1 .. 7 |-> 0] ]

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
        \cup { [ZeroComplexLiquiditySeekingEventNotificationMessage EXCEPT !.imbalanceQuantitySigned = one] : one \in Sample(4) }
        \cup { [ZeroComplexLiquiditySeekingEventNotificationMessage EXCEPT !.attributableId = one] : one \in Sample(4) }
        \cup { [ZeroComplexLiquiditySeekingEventNotificationMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroComplexLiquiditySeekingEventNotificationMessage EXCEPT !.reserved7 = one] : one \in Sample(7) }

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
(* Theoretical Settlement Reference Price Notification Message: 110 bytes  *)
(***************************************************************************)

TheoreticalSettlementReferencePriceNotificationMessage ==
    [ nanoseconds                  : Sample(4),
      productId                    : Sample(4),
      underlyingSymbol             : Sample(11),
      securitySymbol               : Sample(6),
      expirationDate               : Sample(8),
      strikePrice                  : Sample(4),
      callOrPut                    : Sample(1),
      optionState                  : Sample(1),
      priorDayReferencePrice       : Sample(4),
      settlementReferencePrice     : Sample(4),
      settlementReferencePriceType : Sample(1),
      saoBuyQuantity1              : Sample(4),
      saoSellQuantity1             : Sample(4),
      saoBuyQuantity2              : Sample(4),
      saoSellQuantity2             : Sample(4),
      nonSaoBuyQuantity            : Sample(4),
      nonSaoSellQuantity           : Sample(4),
      totalBuyQuantity             : Sample(4),
      totalSellQuantity            : Sample(4),
      imbalanceSide                : Sample(1),
      imbalanceQuantityUnsigned    : Sample(4),
      mustFillQuantity             : Sample(4),
      matchedQuantity              : Sample(4),
      openingCondition             : Sample(1),
      mbb                          : Sample(4),
      mbo                          : Sample(4),
      reserved8                    : Sample(8) ]

EncodeTheoreticalSettlementReferencePriceNotificationMessage(message) ==
    message.nanoseconds
        \o message.productId
        \o message.underlyingSymbol
        \o message.securitySymbol
        \o message.expirationDate
        \o message.strikePrice
        \o message.callOrPut
        \o message.optionState
        \o message.priorDayReferencePrice
        \o message.settlementReferencePrice
        \o message.settlementReferencePriceType
        \o message.saoBuyQuantity1
        \o message.saoSellQuantity1
        \o message.saoBuyQuantity2
        \o message.saoSellQuantity2
        \o message.nonSaoBuyQuantity
        \o message.nonSaoSellQuantity
        \o message.totalBuyQuantity
        \o message.totalSellQuantity
        \o message.imbalanceSide
        \o message.imbalanceQuantityUnsigned
        \o message.mustFillQuantity
        \o message.matchedQuantity
        \o message.openingCondition
        \o message.mbb
        \o message.mbo
        \o message.reserved8

DecodeTheoreticalSettlementReferencePriceNotificationMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET productId == ReadBytes(nanoseconds.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(productId.rest, 11) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(underlyingSymbol.rest, 6) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET expirationDate == ReadBytes(securitySymbol.rest, 8) IN IF ~expirationDate.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(expirationDate.rest, 4) IN IF ~strikePrice.ok THEN Fail ELSE
    LET callOrPut == ReadBytes(strikePrice.rest, 1) IN IF ~callOrPut.ok THEN Fail ELSE
    LET optionState == ReadBytes(callOrPut.rest, 1) IN IF ~optionState.ok THEN Fail ELSE
    LET priorDayReferencePrice == ReadBytes(optionState.rest, 4) IN IF ~priorDayReferencePrice.ok THEN Fail ELSE
    LET settlementReferencePrice == ReadBytes(priorDayReferencePrice.rest, 4) IN IF ~settlementReferencePrice.ok THEN Fail ELSE
    LET settlementReferencePriceType == ReadBytes(settlementReferencePrice.rest, 1) IN IF ~settlementReferencePriceType.ok THEN Fail ELSE
    LET saoBuyQuantity1 == ReadBytes(settlementReferencePriceType.rest, 4) IN IF ~saoBuyQuantity1.ok THEN Fail ELSE
    LET saoSellQuantity1 == ReadBytes(saoBuyQuantity1.rest, 4) IN IF ~saoSellQuantity1.ok THEN Fail ELSE
    LET saoBuyQuantity2 == ReadBytes(saoSellQuantity1.rest, 4) IN IF ~saoBuyQuantity2.ok THEN Fail ELSE
    LET saoSellQuantity2 == ReadBytes(saoBuyQuantity2.rest, 4) IN IF ~saoSellQuantity2.ok THEN Fail ELSE
    LET nonSaoBuyQuantity == ReadBytes(saoSellQuantity2.rest, 4) IN IF ~nonSaoBuyQuantity.ok THEN Fail ELSE
    LET nonSaoSellQuantity == ReadBytes(nonSaoBuyQuantity.rest, 4) IN IF ~nonSaoSellQuantity.ok THEN Fail ELSE
    LET totalBuyQuantity == ReadBytes(nonSaoSellQuantity.rest, 4) IN IF ~totalBuyQuantity.ok THEN Fail ELSE
    LET totalSellQuantity == ReadBytes(totalBuyQuantity.rest, 4) IN IF ~totalSellQuantity.ok THEN Fail ELSE
    LET imbalanceSide == ReadBytes(totalSellQuantity.rest, 1) IN IF ~imbalanceSide.ok THEN Fail ELSE
    LET imbalanceQuantityUnsigned == ReadBytes(imbalanceSide.rest, 4) IN IF ~imbalanceQuantityUnsigned.ok THEN Fail ELSE
    LET mustFillQuantity == ReadBytes(imbalanceQuantityUnsigned.rest, 4) IN IF ~mustFillQuantity.ok THEN Fail ELSE
    LET matchedQuantity == ReadBytes(mustFillQuantity.rest, 4) IN IF ~matchedQuantity.ok THEN Fail ELSE
    LET openingCondition == ReadBytes(matchedQuantity.rest, 1) IN IF ~openingCondition.ok THEN Fail ELSE
    LET mbb == ReadBytes(openingCondition.rest, 4) IN IF ~mbb.ok THEN Fail ELSE
    LET mbo == ReadBytes(mbb.rest, 4) IN IF ~mbo.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(mbo.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    Ok([ nanoseconds                  |-> nanoseconds.value,
         productId                    |-> productId.value,
         underlyingSymbol             |-> underlyingSymbol.value,
         securitySymbol               |-> securitySymbol.value,
         expirationDate               |-> expirationDate.value,
         strikePrice                  |-> strikePrice.value,
         callOrPut                    |-> callOrPut.value,
         optionState                  |-> optionState.value,
         priorDayReferencePrice       |-> priorDayReferencePrice.value,
         settlementReferencePrice     |-> settlementReferencePrice.value,
         settlementReferencePriceType |-> settlementReferencePriceType.value,
         saoBuyQuantity1              |-> saoBuyQuantity1.value,
         saoSellQuantity1             |-> saoSellQuantity1.value,
         saoBuyQuantity2              |-> saoBuyQuantity2.value,
         saoSellQuantity2             |-> saoSellQuantity2.value,
         nonSaoBuyQuantity            |-> nonSaoBuyQuantity.value,
         nonSaoSellQuantity           |-> nonSaoSellQuantity.value,
         totalBuyQuantity             |-> totalBuyQuantity.value,
         totalSellQuantity            |-> totalSellQuantity.value,
         imbalanceSide                |-> imbalanceSide.value,
         imbalanceQuantityUnsigned    |-> imbalanceQuantityUnsigned.value,
         mustFillQuantity             |-> mustFillQuantity.value,
         matchedQuantity              |-> matchedQuantity.value,
         openingCondition             |-> openingCondition.value,
         mbb                          |-> mbb.value,
         mbo                          |-> mbo.value,
         reserved8                    |-> reserved8.value ], reserved8.rest)

ZeroTheoreticalSettlementReferencePriceNotificationMessage ==
    [ nanoseconds                  |-> [i \in 1 .. 4 |-> 0],
      productId                    |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbol             |-> [i \in 1 .. 11 |-> 0],
      securitySymbol               |-> [i \in 1 .. 6 |-> 0],
      expirationDate               |-> [i \in 1 .. 8 |-> 0],
      strikePrice                  |-> [i \in 1 .. 4 |-> 0],
      callOrPut                    |-> [i \in 1 .. 1 |-> 0],
      optionState                  |-> [i \in 1 .. 1 |-> 0],
      priorDayReferencePrice       |-> [i \in 1 .. 4 |-> 0],
      settlementReferencePrice     |-> [i \in 1 .. 4 |-> 0],
      settlementReferencePriceType |-> [i \in 1 .. 1 |-> 0],
      saoBuyQuantity1              |-> [i \in 1 .. 4 |-> 0],
      saoSellQuantity1             |-> [i \in 1 .. 4 |-> 0],
      saoBuyQuantity2              |-> [i \in 1 .. 4 |-> 0],
      saoSellQuantity2             |-> [i \in 1 .. 4 |-> 0],
      nonSaoBuyQuantity            |-> [i \in 1 .. 4 |-> 0],
      nonSaoSellQuantity           |-> [i \in 1 .. 4 |-> 0],
      totalBuyQuantity             |-> [i \in 1 .. 4 |-> 0],
      totalSellQuantity            |-> [i \in 1 .. 4 |-> 0],
      imbalanceSide                |-> [i \in 1 .. 1 |-> 0],
      imbalanceQuantityUnsigned    |-> [i \in 1 .. 4 |-> 0],
      mustFillQuantity             |-> [i \in 1 .. 4 |-> 0],
      matchedQuantity              |-> [i \in 1 .. 4 |-> 0],
      openingCondition             |-> [i \in 1 .. 1 |-> 0],
      mbb                          |-> [i \in 1 .. 4 |-> 0],
      mbo                          |-> [i \in 1 .. 4 |-> 0],
      reserved8                    |-> [i \in 1 .. 8 |-> 0] ]

(* Theoretical Settlement Reference Price Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedTheoreticalSettlementReferencePriceNotificationMessage ==
    { ZeroTheoreticalSettlementReferencePriceNotificationMessage }
        \cup { [ZeroTheoreticalSettlementReferencePriceNotificationMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroTheoreticalSettlementReferencePriceNotificationMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroTheoreticalSettlementReferencePriceNotificationMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }
        \cup { [ZeroTheoreticalSettlementReferencePriceNotificationMessage EXCEPT !.securitySymbol = one] : one \in Sample(6) }
        \cup { [ZeroTheoreticalSettlementReferencePriceNotificationMessage EXCEPT !.expirationDate = one] : one \in Sample(8) }
        \cup { [ZeroTheoreticalSettlementReferencePriceNotificationMessage EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroTheoreticalSettlementReferencePriceNotificationMessage EXCEPT !.callOrPut = one] : one \in Sample(1) }
        \cup { [ZeroTheoreticalSettlementReferencePriceNotificationMessage EXCEPT !.optionState = one] : one \in Sample(1) }
        \cup { [ZeroTheoreticalSettlementReferencePriceNotificationMessage EXCEPT !.priorDayReferencePrice = one] : one \in Sample(4) }
        \cup { [ZeroTheoreticalSettlementReferencePriceNotificationMessage EXCEPT !.settlementReferencePrice = one] : one \in Sample(4) }
        \cup { [ZeroTheoreticalSettlementReferencePriceNotificationMessage EXCEPT !.settlementReferencePriceType = one] : one \in Sample(1) }
        \cup { [ZeroTheoreticalSettlementReferencePriceNotificationMessage EXCEPT !.saoBuyQuantity1 = one] : one \in Sample(4) }
        \cup { [ZeroTheoreticalSettlementReferencePriceNotificationMessage EXCEPT !.saoSellQuantity1 = one] : one \in Sample(4) }
        \cup { [ZeroTheoreticalSettlementReferencePriceNotificationMessage EXCEPT !.saoBuyQuantity2 = one] : one \in Sample(4) }
        \cup { [ZeroTheoreticalSettlementReferencePriceNotificationMessage EXCEPT !.saoSellQuantity2 = one] : one \in Sample(4) }
        \cup { [ZeroTheoreticalSettlementReferencePriceNotificationMessage EXCEPT !.nonSaoBuyQuantity = one] : one \in Sample(4) }
        \cup { [ZeroTheoreticalSettlementReferencePriceNotificationMessage EXCEPT !.nonSaoSellQuantity = one] : one \in Sample(4) }
        \cup { [ZeroTheoreticalSettlementReferencePriceNotificationMessage EXCEPT !.totalBuyQuantity = one] : one \in Sample(4) }
        \cup { [ZeroTheoreticalSettlementReferencePriceNotificationMessage EXCEPT !.totalSellQuantity = one] : one \in Sample(4) }
        \cup { [ZeroTheoreticalSettlementReferencePriceNotificationMessage EXCEPT !.imbalanceSide = one] : one \in Sample(1) }
        \cup { [ZeroTheoreticalSettlementReferencePriceNotificationMessage EXCEPT !.imbalanceQuantityUnsigned = one] : one \in Sample(4) }
        \cup { [ZeroTheoreticalSettlementReferencePriceNotificationMessage EXCEPT !.mustFillQuantity = one] : one \in Sample(4) }
        \cup { [ZeroTheoreticalSettlementReferencePriceNotificationMessage EXCEPT !.matchedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroTheoreticalSettlementReferencePriceNotificationMessage EXCEPT !.openingCondition = one] : one \in Sample(1) }
        \cup { [ZeroTheoreticalSettlementReferencePriceNotificationMessage EXCEPT !.mbb = one] : one \in Sample(4) }
        \cup { [ZeroTheoreticalSettlementReferencePriceNotificationMessage EXCEPT !.mbo = one] : one \in Sample(4) }
        \cup { [ZeroTheoreticalSettlementReferencePriceNotificationMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }

(***************************************************************************)
(* Theoretical Settlement Price Notification Message: 32 bytes             *)
(***************************************************************************)

TheoreticalSettlementPriceNotificationMessage ==
    [ nanoseconds                : Sample(4),
      settlementSymbol           : Sample(8),
      theoreticalSettlementPrice : Sample(4),
      reserved16                 : Sample(16) ]

EncodeTheoreticalSettlementPriceNotificationMessage(message) ==
    message.nanoseconds
        \o message.settlementSymbol
        \o message.theoreticalSettlementPrice
        \o message.reserved16

DecodeTheoreticalSettlementPriceNotificationMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET settlementSymbol == ReadBytes(nanoseconds.rest, 8) IN IF ~settlementSymbol.ok THEN Fail ELSE
    LET theoreticalSettlementPrice == ReadBytes(settlementSymbol.rest, 4) IN IF ~theoreticalSettlementPrice.ok THEN Fail ELSE
    LET reserved16 == ReadBytes(theoreticalSettlementPrice.rest, 16) IN IF ~reserved16.ok THEN Fail ELSE
    Ok([ nanoseconds                |-> nanoseconds.value,
         settlementSymbol           |-> settlementSymbol.value,
         theoreticalSettlementPrice |-> theoreticalSettlementPrice.value,
         reserved16                 |-> reserved16.value ], reserved16.rest)

ZeroTheoreticalSettlementPriceNotificationMessage ==
    [ nanoseconds                |-> [i \in 1 .. 4 |-> 0],
      settlementSymbol           |-> [i \in 1 .. 8 |-> 0],
      theoreticalSettlementPrice |-> [i \in 1 .. 4 |-> 0],
      reserved16                 |-> [i \in 1 .. 16 |-> 0] ]

(* Theoretical Settlement Price Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedTheoreticalSettlementPriceNotificationMessage ==
    { ZeroTheoreticalSettlementPriceNotificationMessage }
        \cup { [ZeroTheoreticalSettlementPriceNotificationMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroTheoreticalSettlementPriceNotificationMessage EXCEPT !.settlementSymbol = one] : one \in Sample(8) }
        \cup { [ZeroTheoreticalSettlementPriceNotificationMessage EXCEPT !.theoreticalSettlementPrice = one] : one \in Sample(4) }
        \cup { [ZeroTheoreticalSettlementPriceNotificationMessage EXCEPT !.reserved16 = one] : one \in Sample(16) }

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
TheoreticalSettlementReferencePriceNotificationMessageCode == 77  \* "M"
TheoreticalSettlementPriceNotificationMessageCode == 78  \* "N"

Data ==
    [ tag : {SystemTimeMessageCode}, body : SystemTimeMessage ]
        \cup [ tag : {SimpleSeriesUpdateMessageCode}, body : SimpleSeriesUpdateMessage ]
        \cup [ tag : {ComplexStrategyDefinitionUpdateMessageCode}, body : ComplexStrategyDefinitionUpdateMessage ]
        \cup [ tag : {SystemStateMessageCode}, body : SystemStateMessage ]
        \cup [ tag : {SimpleLiquiditySeekingEventNotificationMessageCode}, body : SimpleLiquiditySeekingEventNotificationMessage ]
        \cup [ tag : {ComplexLiquiditySeekingEventNotificationMessageCode}, body : ComplexLiquiditySeekingEventNotificationMessage ]
        \cup [ tag : {UnderlyingTradingStatusNotificationMessageCode}, body : UnderlyingTradingStatusNotificationMessage ]
        \cup [ tag : {TheoreticalSettlementReferencePriceNotificationMessageCode}, body : TheoreticalSettlementReferencePriceNotificationMessage ]
        \cup [ tag : {TheoreticalSettlementPriceNotificationMessageCode}, body : TheoreticalSettlementPriceNotificationMessage ]

EncodeData(message) ==
    CASE message.tag = SystemTimeMessageCode -> EncodeSystemTimeMessage(message.body)
      [] message.tag = SimpleSeriesUpdateMessageCode -> EncodeSimpleSeriesUpdateMessage(message.body)
      [] message.tag = ComplexStrategyDefinitionUpdateMessageCode -> EncodeComplexStrategyDefinitionUpdateMessage(message.body)
      [] message.tag = SystemStateMessageCode -> EncodeSystemStateMessage(message.body)
      [] message.tag = SimpleLiquiditySeekingEventNotificationMessageCode -> EncodeSimpleLiquiditySeekingEventNotificationMessage(message.body)
      [] message.tag = ComplexLiquiditySeekingEventNotificationMessageCode -> EncodeComplexLiquiditySeekingEventNotificationMessage(message.body)
      [] message.tag = UnderlyingTradingStatusNotificationMessageCode -> EncodeUnderlyingTradingStatusNotificationMessage(message.body)
      [] message.tag = TheoreticalSettlementReferencePriceNotificationMessageCode -> EncodeTheoreticalSettlementReferencePriceNotificationMessage(message.body)
      [] message.tag = TheoreticalSettlementPriceNotificationMessageCode -> EncodeTheoreticalSettlementPriceNotificationMessage(message.body)

DecodeData(tag, bytes) ==
    LET read ==
            CASE tag = SystemTimeMessageCode -> DecodeSystemTimeMessage(bytes)
              [] tag = SimpleSeriesUpdateMessageCode -> DecodeSimpleSeriesUpdateMessage(bytes)
              [] tag = ComplexStrategyDefinitionUpdateMessageCode -> DecodeComplexStrategyDefinitionUpdateMessage(bytes)
              [] tag = SystemStateMessageCode -> DecodeSystemStateMessage(bytes)
              [] tag = SimpleLiquiditySeekingEventNotificationMessageCode -> DecodeSimpleLiquiditySeekingEventNotificationMessage(bytes)
              [] tag = ComplexLiquiditySeekingEventNotificationMessageCode -> DecodeComplexLiquiditySeekingEventNotificationMessage(bytes)
              [] tag = UnderlyingTradingStatusNotificationMessageCode -> DecodeUnderlyingTradingStatusNotificationMessage(bytes)
              [] tag = TheoreticalSettlementReferencePriceNotificationMessageCode -> DecodeTheoreticalSettlementReferencePriceNotificationMessage(bytes)
              [] tag = TheoreticalSettlementPriceNotificationMessageCode -> DecodeTheoreticalSettlementPriceNotificationMessage(bytes)
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
        \cup { [tag |-> TheoreticalSettlementReferencePriceNotificationMessageCode, body |-> one] : one \in CheckedTheoreticalSettlementReferencePriceNotificationMessage }
        \cup { [tag |-> TheoreticalSettlementPriceNotificationMessageCode, body |-> one] : one \in CheckedTheoreticalSettlementPriceNotificationMessage }

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
(* Payload, selected by Packet Type                                        *)
(***************************************************************************)

HeartbeatCode == 0  \* 0x00
StartOfSessionCode == 1  \* 0x01
EndOfSessionCode == 2  \* 0x02
ApplicationMessageCode == 3  \* 0x03

Payload ==
    [ tag : {HeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {StartOfSessionCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {EndOfSessionCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ApplicationMessageCode}, body : ApplicationMessage ]

EncodePayload(message) ==
    CASE message.tag = HeartbeatCode -> << >>
      [] message.tag = StartOfSessionCode -> << >>
      [] message.tag = EndOfSessionCode -> << >>
      [] message.tag = ApplicationMessageCode -> EncodeApplicationMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = HeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = StartOfSessionCode -> Ok([empty |-> 0], bytes)
              [] tag = EndOfSessionCode -> Ok([empty |-> 0], bytes)
              [] tag = ApplicationMessageCode -> DecodeApplicationMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> HeartbeatCode, body |-> [empty |-> 0]]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> HeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> StartOfSessionCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> EndOfSessionCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> ApplicationMessageCode, body |-> one] : one \in CheckedApplicationMessage }

(***************************************************************************)
(* Mach Message, framed by Packet Length                                   *)
(***************************************************************************)

MachMessage ==
    [ sequenceNumber : Sample(8),
      sessionNumber  : Sample(1),
      payload        : Payload ]

EncodeMachMessageBody(message) ==
    EncodeUIntLE(message.payload.tag, 1)
        \o message.sessionNumber
        \o EncodePayload(message.payload)

(* Packet Length counts the bytes it frames, so it is written from them *)
EncodeMachMessage(message) ==
    LET body == EncodeMachMessageBody(message)
    IN  message.sequenceNumber \o EncodeUIntLE(Len(body) + 10, 2) \o body

DecodeMachMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET length == ReadUIntLE(sequenceNumber.rest, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 10 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
    IN
    LET packetType == ReadUIntLE(framed, 1) IN IF ~packetType.ok THEN Fail ELSE
    LET sessionNumber == ReadBytes(packetType.rest, 1) IN IF ~sessionNumber.ok THEN Fail ELSE
    LET payload == DecodePayload(packetType.value, sessionNumber.rest) IN IF ~payload.ok THEN Fail ELSE
    IF payload.rest # << >> THEN Fail ELSE
    Ok([ sequenceNumber |-> sequenceNumber.value,
         sessionNumber  |-> sessionNumber.value,
         payload        |-> payload.value ], beyond)

ZeroMachMessage ==
    [ sequenceNumber |-> [i \in 1 .. 8 |-> 0],
      sessionNumber  |-> [i \in 1 .. 1 |-> 0],
      payload        |-> ZeroPayload ]

(* Mach Message at zero, then each field in turn at the values it is checked at *)
CheckedMachMessage ==
    { ZeroMachMessage }
        \cup { [ZeroMachMessage EXCEPT !.sequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroMachMessage EXCEPT !.sessionNumber = one] : one \in Sample(1) }
        \cup { [ZeroMachMessage EXCEPT !.payload = one] : one \in CheckedPayload }

(* A run of Mach Message, written one after another *)
RECURSIVE EncodeMachMessageList(_)
EncodeMachMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMachMessage(Head(messages)) \o EncodeMachMessageList(Tail(messages))

(* As many Mach Message as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadMachMessageAll(_)
ReadMachMessageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeMachMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMachMessageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Mach Message of each kind, for the lists that carry them *)
OneMachMessage ==
    { [ZeroMachMessage EXCEPT !.payload = [tag |-> HeartbeatCode, body |-> [empty |-> 0]]],
      [ZeroMachMessage EXCEPT !.payload = [tag |-> StartOfSessionCode, body |-> [empty |-> 0]]],
      [ZeroMachMessage EXCEPT !.payload = [tag |-> EndOfSessionCode, body |-> [empty |-> 0]]],
      [ZeroMachMessage EXCEPT !.payload = [tag |-> ApplicationMessageCode, body |-> ZeroApplicationMessage]] }

(***************************************************************************)
(* Udp Packet                                                              *)
(***************************************************************************)

UdpPacket ==
    [ machMessage : SampleLists(OneMachMessage) ]

EncodeUdpPacket(message) ==
    EncodeMachMessageList(message.machMessage)

DecodeUdpPacket(bytes) ==
    LET machMessage == ReadMachMessageAll(bytes) IN IF ~machMessage.ok THEN Fail ELSE
    Ok([ machMessage |-> machMessage.value ], machMessage.rest)

ZeroUdpPacket ==
    [ machMessage |-> << >> ]

(* Udp Packet at zero, then each field in turn at the values it is checked at *)
CheckedUdpPacket ==
    { ZeroUdpPacket }
        \cup { [ZeroUdpPacket EXCEPT !.machMessage = one] : one \in SampleLists(OneMachMessage) }

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

(* Every Theoretical Settlement Reference Price Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTheoreticalSettlementReferencePriceNotificationMessage ==
    \A message \in CheckedTheoreticalSettlementReferencePriceNotificationMessage :
        LET read == DecodeTheoreticalSettlementReferencePriceNotificationMessage(EncodeTheoreticalSettlementReferencePriceNotificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Theoretical Settlement Price Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTheoreticalSettlementPriceNotificationMessage ==
    \A message \in CheckedTheoreticalSettlementPriceNotificationMessage :
        LET read == DecodeTheoreticalSettlementPriceNotificationMessage(EncodeTheoreticalSettlementPriceNotificationMessage(message))
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

(* Every Mach Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMachMessage ==
    \A message \in CheckedMachMessage :
        LET read == DecodeMachMessage(EncodeMachMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Udp Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripUdpPacket ==
    \A message \in CheckedUdpPacket :
        LET read == DecodeUdpPacket(EncodeUdpPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Data is selected by the Message Type it is written under *)
SelectsData ==
    \A message \in CheckedData :
        LET read == DecodeData(message.tag, EncodeData(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Payload is selected by the Packet Type it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Packet Length is written from the bytes it frames *)
FramesMachMessage ==
    \A message \in CheckedMachMessage :
        LET bytes == EncodeMachMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 9, 10)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
