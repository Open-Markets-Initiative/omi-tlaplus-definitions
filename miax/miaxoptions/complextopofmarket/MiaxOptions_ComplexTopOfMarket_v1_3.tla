---------------- MODULE MiaxOptions_ComplexTopOfMarket_v1_3 ----------------
(***************************************************************************)
(* Miami International Holdings Complex Top Of Market v1.3                 *)
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
(* Complex Strategy Definition Message                                     *)
(***************************************************************************)

ComplexStrategyDefinitionMessage ==
    [ nanoseconds      : Sample(4),
      strategyId       : Sample(4),
      underlyingSymbol : Sample(11),
      activeOnMiax     : Sample(1),
      reserved1        : Sample(1),
      updateReason     : Sample(1),
      reserved10       : Sample(10),
      legDefinition    : SampleLists(OneLegDefinition) ]

EncodeComplexStrategyDefinitionMessage(message) ==
    message.nanoseconds
        \o message.strategyId
        \o message.underlyingSymbol
        \o message.activeOnMiax
        \o message.reserved1
        \o message.updateReason
        \o message.reserved10
        \o EncodeUIntLE(Len(message.legDefinition), 1)
        \o EncodeLegDefinitionList(message.legDefinition)

DecodeComplexStrategyDefinitionMessage(bytes) ==
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

ZeroComplexStrategyDefinitionMessage ==
    [ nanoseconds      |-> [i \in 1 .. 4 |-> 0],
      strategyId       |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbol |-> [i \in 1 .. 11 |-> 0],
      activeOnMiax     |-> [i \in 1 .. 1 |-> 0],
      reserved1        |-> [i \in 1 .. 1 |-> 0],
      updateReason     |-> [i \in 1 .. 1 |-> 0],
      reserved10       |-> [i \in 1 .. 10 |-> 0],
      legDefinition    |-> << >> ]

(* Complex Strategy Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexStrategyDefinitionMessage ==
    { ZeroComplexStrategyDefinitionMessage }
        \cup { [ZeroComplexStrategyDefinitionMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroComplexStrategyDefinitionMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroComplexStrategyDefinitionMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }
        \cup { [ZeroComplexStrategyDefinitionMessage EXCEPT !.activeOnMiax = one] : one \in Sample(1) }
        \cup { [ZeroComplexStrategyDefinitionMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroComplexStrategyDefinitionMessage EXCEPT !.updateReason = one] : one \in Sample(1) }
        \cup { [ZeroComplexStrategyDefinitionMessage EXCEPT !.reserved10 = one] : one \in Sample(10) }
        \cup { [ZeroComplexStrategyDefinitionMessage EXCEPT !.legDefinition = one] : one \in SampleLists(OneLegDefinition) }

(***************************************************************************)
(* System State Message: 17 bytes                                          *)
(***************************************************************************)

SystemStateMessage ==
    [ nanoseconds  : Sample(4),
      version      : Sample(8),
      sessionId    : Sample(4),
      systemStatus : Sample(1) ]

EncodeSystemStateMessage(message) ==
    message.nanoseconds
        \o message.version
        \o message.sessionId
        \o message.systemStatus

DecodeSystemStateMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET version == ReadBytes(nanoseconds.rest, 8) IN IF ~version.ok THEN Fail ELSE
    LET sessionId == ReadBytes(version.rest, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET systemStatus == ReadBytes(sessionId.rest, 1) IN IF ~systemStatus.ok THEN Fail ELSE
    Ok([ nanoseconds  |-> nanoseconds.value,
         version      |-> version.value,
         sessionId    |-> sessionId.value,
         systemStatus |-> systemStatus.value ], systemStatus.rest)

ZeroSystemStateMessage ==
    [ nanoseconds  |-> [i \in 1 .. 4 |-> 0],
      version      |-> [i \in 1 .. 8 |-> 0],
      sessionId    |-> [i \in 1 .. 4 |-> 0],
      systemStatus |-> [i \in 1 .. 1 |-> 0] ]

(* System State Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemStateMessage ==
    { ZeroSystemStateMessage }
        \cup { [ZeroSystemStateMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSystemStateMessage EXCEPT !.version = one] : one \in Sample(8) }
        \cup { [ZeroSystemStateMessage EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroSystemStateMessage EXCEPT !.systemStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Complex Top Of Market Bid Compact Message: 15 bytes                     *)
(***************************************************************************)

ComplexTopOfMarketBidCompactMessage ==
    [ nanoseconds               : Sample(4),
      strategyId                : Sample(4),
      price2                    : Sample(2),
      size2                     : Sample(2),
      priorityCustomerSize2     : Sample(2),
      topOfMarketQuoteCondition : Sample(1) ]

EncodeComplexTopOfMarketBidCompactMessage(message) ==
    message.nanoseconds
        \o message.strategyId
        \o message.price2
        \o message.size2
        \o message.priorityCustomerSize2
        \o message.topOfMarketQuoteCondition

DecodeComplexTopOfMarketBidCompactMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET strategyId == ReadBytes(nanoseconds.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET price2 == ReadBytes(strategyId.rest, 2) IN IF ~price2.ok THEN Fail ELSE
    LET size2 == ReadBytes(price2.rest, 2) IN IF ~size2.ok THEN Fail ELSE
    LET priorityCustomerSize2 == ReadBytes(size2.rest, 2) IN IF ~priorityCustomerSize2.ok THEN Fail ELSE
    LET topOfMarketQuoteCondition == ReadBytes(priorityCustomerSize2.rest, 1) IN IF ~topOfMarketQuoteCondition.ok THEN Fail ELSE
    Ok([ nanoseconds               |-> nanoseconds.value,
         strategyId                |-> strategyId.value,
         price2                    |-> price2.value,
         size2                     |-> size2.value,
         priorityCustomerSize2     |-> priorityCustomerSize2.value,
         topOfMarketQuoteCondition |-> topOfMarketQuoteCondition.value ], topOfMarketQuoteCondition.rest)

ZeroComplexTopOfMarketBidCompactMessage ==
    [ nanoseconds               |-> [i \in 1 .. 4 |-> 0],
      strategyId                |-> [i \in 1 .. 4 |-> 0],
      price2                    |-> [i \in 1 .. 2 |-> 0],
      size2                     |-> [i \in 1 .. 2 |-> 0],
      priorityCustomerSize2     |-> [i \in 1 .. 2 |-> 0],
      topOfMarketQuoteCondition |-> [i \in 1 .. 1 |-> 0] ]

(* Complex Top Of Market Bid Compact Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexTopOfMarketBidCompactMessage ==
    { ZeroComplexTopOfMarketBidCompactMessage }
        \cup { [ZeroComplexTopOfMarketBidCompactMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroComplexTopOfMarketBidCompactMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroComplexTopOfMarketBidCompactMessage EXCEPT !.price2 = one] : one \in Sample(2) }
        \cup { [ZeroComplexTopOfMarketBidCompactMessage EXCEPT !.size2 = one] : one \in Sample(2) }
        \cup { [ZeroComplexTopOfMarketBidCompactMessage EXCEPT !.priorityCustomerSize2 = one] : one \in Sample(2) }
        \cup { [ZeroComplexTopOfMarketBidCompactMessage EXCEPT !.topOfMarketQuoteCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Complex Top Of Market Offer Compact Message: 15 bytes                   *)
(***************************************************************************)

ComplexTopOfMarketOfferCompactMessage ==
    [ nanoseconds               : Sample(4),
      strategyId                : Sample(4),
      price2                    : Sample(2),
      size2                     : Sample(2),
      priorityCustomerSize2     : Sample(2),
      topOfMarketQuoteCondition : Sample(1) ]

EncodeComplexTopOfMarketOfferCompactMessage(message) ==
    message.nanoseconds
        \o message.strategyId
        \o message.price2
        \o message.size2
        \o message.priorityCustomerSize2
        \o message.topOfMarketQuoteCondition

DecodeComplexTopOfMarketOfferCompactMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET strategyId == ReadBytes(nanoseconds.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET price2 == ReadBytes(strategyId.rest, 2) IN IF ~price2.ok THEN Fail ELSE
    LET size2 == ReadBytes(price2.rest, 2) IN IF ~size2.ok THEN Fail ELSE
    LET priorityCustomerSize2 == ReadBytes(size2.rest, 2) IN IF ~priorityCustomerSize2.ok THEN Fail ELSE
    LET topOfMarketQuoteCondition == ReadBytes(priorityCustomerSize2.rest, 1) IN IF ~topOfMarketQuoteCondition.ok THEN Fail ELSE
    Ok([ nanoseconds               |-> nanoseconds.value,
         strategyId                |-> strategyId.value,
         price2                    |-> price2.value,
         size2                     |-> size2.value,
         priorityCustomerSize2     |-> priorityCustomerSize2.value,
         topOfMarketQuoteCondition |-> topOfMarketQuoteCondition.value ], topOfMarketQuoteCondition.rest)

ZeroComplexTopOfMarketOfferCompactMessage ==
    [ nanoseconds               |-> [i \in 1 .. 4 |-> 0],
      strategyId                |-> [i \in 1 .. 4 |-> 0],
      price2                    |-> [i \in 1 .. 2 |-> 0],
      size2                     |-> [i \in 1 .. 2 |-> 0],
      priorityCustomerSize2     |-> [i \in 1 .. 2 |-> 0],
      topOfMarketQuoteCondition |-> [i \in 1 .. 1 |-> 0] ]

(* Complex Top Of Market Offer Compact Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexTopOfMarketOfferCompactMessage ==
    { ZeroComplexTopOfMarketOfferCompactMessage }
        \cup { [ZeroComplexTopOfMarketOfferCompactMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroComplexTopOfMarketOfferCompactMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroComplexTopOfMarketOfferCompactMessage EXCEPT !.price2 = one] : one \in Sample(2) }
        \cup { [ZeroComplexTopOfMarketOfferCompactMessage EXCEPT !.size2 = one] : one \in Sample(2) }
        \cup { [ZeroComplexTopOfMarketOfferCompactMessage EXCEPT !.priorityCustomerSize2 = one] : one \in Sample(2) }
        \cup { [ZeroComplexTopOfMarketOfferCompactMessage EXCEPT !.topOfMarketQuoteCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Complex Top Of Market Bid Wide Message: 25 bytes                        *)
(***************************************************************************)

ComplexTopOfMarketBidWideMessage ==
    [ nanoseconds               : Sample(4),
      strategyId                : Sample(4),
      price8                    : Sample(8),
      size4                     : Sample(4),
      priorityCustomerSize4     : Sample(4),
      topOfMarketQuoteCondition : Sample(1) ]

EncodeComplexTopOfMarketBidWideMessage(message) ==
    message.nanoseconds
        \o message.strategyId
        \o message.price8
        \o message.size4
        \o message.priorityCustomerSize4
        \o message.topOfMarketQuoteCondition

DecodeComplexTopOfMarketBidWideMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET strategyId == ReadBytes(nanoseconds.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET price8 == ReadBytes(strategyId.rest, 8) IN IF ~price8.ok THEN Fail ELSE
    LET size4 == ReadBytes(price8.rest, 4) IN IF ~size4.ok THEN Fail ELSE
    LET priorityCustomerSize4 == ReadBytes(size4.rest, 4) IN IF ~priorityCustomerSize4.ok THEN Fail ELSE
    LET topOfMarketQuoteCondition == ReadBytes(priorityCustomerSize4.rest, 1) IN IF ~topOfMarketQuoteCondition.ok THEN Fail ELSE
    Ok([ nanoseconds               |-> nanoseconds.value,
         strategyId                |-> strategyId.value,
         price8                    |-> price8.value,
         size4                     |-> size4.value,
         priorityCustomerSize4     |-> priorityCustomerSize4.value,
         topOfMarketQuoteCondition |-> topOfMarketQuoteCondition.value ], topOfMarketQuoteCondition.rest)

ZeroComplexTopOfMarketBidWideMessage ==
    [ nanoseconds               |-> [i \in 1 .. 4 |-> 0],
      strategyId                |-> [i \in 1 .. 4 |-> 0],
      price8                    |-> [i \in 1 .. 8 |-> 0],
      size4                     |-> [i \in 1 .. 4 |-> 0],
      priorityCustomerSize4     |-> [i \in 1 .. 4 |-> 0],
      topOfMarketQuoteCondition |-> [i \in 1 .. 1 |-> 0] ]

(* Complex Top Of Market Bid Wide Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexTopOfMarketBidWideMessage ==
    { ZeroComplexTopOfMarketBidWideMessage }
        \cup { [ZeroComplexTopOfMarketBidWideMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroComplexTopOfMarketBidWideMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroComplexTopOfMarketBidWideMessage EXCEPT !.price8 = one] : one \in Sample(8) }
        \cup { [ZeroComplexTopOfMarketBidWideMessage EXCEPT !.size4 = one] : one \in Sample(4) }
        \cup { [ZeroComplexTopOfMarketBidWideMessage EXCEPT !.priorityCustomerSize4 = one] : one \in Sample(4) }
        \cup { [ZeroComplexTopOfMarketBidWideMessage EXCEPT !.topOfMarketQuoteCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Complex Top Of Market Offer Wide Message: 25 bytes                      *)
(***************************************************************************)

ComplexTopOfMarketOfferWideMessage ==
    [ nanoseconds               : Sample(4),
      strategyId                : Sample(4),
      price8                    : Sample(8),
      size4                     : Sample(4),
      priorityCustomerSize4     : Sample(4),
      topOfMarketQuoteCondition : Sample(1) ]

EncodeComplexTopOfMarketOfferWideMessage(message) ==
    message.nanoseconds
        \o message.strategyId
        \o message.price8
        \o message.size4
        \o message.priorityCustomerSize4
        \o message.topOfMarketQuoteCondition

DecodeComplexTopOfMarketOfferWideMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET strategyId == ReadBytes(nanoseconds.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET price8 == ReadBytes(strategyId.rest, 8) IN IF ~price8.ok THEN Fail ELSE
    LET size4 == ReadBytes(price8.rest, 4) IN IF ~size4.ok THEN Fail ELSE
    LET priorityCustomerSize4 == ReadBytes(size4.rest, 4) IN IF ~priorityCustomerSize4.ok THEN Fail ELSE
    LET topOfMarketQuoteCondition == ReadBytes(priorityCustomerSize4.rest, 1) IN IF ~topOfMarketQuoteCondition.ok THEN Fail ELSE
    Ok([ nanoseconds               |-> nanoseconds.value,
         strategyId                |-> strategyId.value,
         price8                    |-> price8.value,
         size4                     |-> size4.value,
         priorityCustomerSize4     |-> priorityCustomerSize4.value,
         topOfMarketQuoteCondition |-> topOfMarketQuoteCondition.value ], topOfMarketQuoteCondition.rest)

ZeroComplexTopOfMarketOfferWideMessage ==
    [ nanoseconds               |-> [i \in 1 .. 4 |-> 0],
      strategyId                |-> [i \in 1 .. 4 |-> 0],
      price8                    |-> [i \in 1 .. 8 |-> 0],
      size4                     |-> [i \in 1 .. 4 |-> 0],
      priorityCustomerSize4     |-> [i \in 1 .. 4 |-> 0],
      topOfMarketQuoteCondition |-> [i \in 1 .. 1 |-> 0] ]

(* Complex Top Of Market Offer Wide Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexTopOfMarketOfferWideMessage ==
    { ZeroComplexTopOfMarketOfferWideMessage }
        \cup { [ZeroComplexTopOfMarketOfferWideMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroComplexTopOfMarketOfferWideMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroComplexTopOfMarketOfferWideMessage EXCEPT !.price8 = one] : one \in Sample(8) }
        \cup { [ZeroComplexTopOfMarketOfferWideMessage EXCEPT !.size4 = one] : one \in Sample(4) }
        \cup { [ZeroComplexTopOfMarketOfferWideMessage EXCEPT !.priorityCustomerSize4 = one] : one \in Sample(4) }
        \cup { [ZeroComplexTopOfMarketOfferWideMessage EXCEPT !.topOfMarketQuoteCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Complex Double Sided Top Of Market Compact Message: 22 bytes            *)
(***************************************************************************)

ComplexDoubleSidedTopOfMarketCompactMessage ==
    [ nanoseconds                : Sample(4),
      strategyId                 : Sample(4),
      bidPrice2                  : Sample(2),
      bidSize2                   : Sample(2),
      bidPriorityCustomerSize2   : Sample(2),
      bidCondition               : Sample(1),
      offerPrice2                : Sample(2),
      offerSize2                 : Sample(2),
      offerPriorityCustomerSize2 : Sample(2),
      offerCondition             : Sample(1) ]

EncodeComplexDoubleSidedTopOfMarketCompactMessage(message) ==
    message.nanoseconds
        \o message.strategyId
        \o message.bidPrice2
        \o message.bidSize2
        \o message.bidPriorityCustomerSize2
        \o message.bidCondition
        \o message.offerPrice2
        \o message.offerSize2
        \o message.offerPriorityCustomerSize2
        \o message.offerCondition

DecodeComplexDoubleSidedTopOfMarketCompactMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET strategyId == ReadBytes(nanoseconds.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET bidPrice2 == ReadBytes(strategyId.rest, 2) IN IF ~bidPrice2.ok THEN Fail ELSE
    LET bidSize2 == ReadBytes(bidPrice2.rest, 2) IN IF ~bidSize2.ok THEN Fail ELSE
    LET bidPriorityCustomerSize2 == ReadBytes(bidSize2.rest, 2) IN IF ~bidPriorityCustomerSize2.ok THEN Fail ELSE
    LET bidCondition == ReadBytes(bidPriorityCustomerSize2.rest, 1) IN IF ~bidCondition.ok THEN Fail ELSE
    LET offerPrice2 == ReadBytes(bidCondition.rest, 2) IN IF ~offerPrice2.ok THEN Fail ELSE
    LET offerSize2 == ReadBytes(offerPrice2.rest, 2) IN IF ~offerSize2.ok THEN Fail ELSE
    LET offerPriorityCustomerSize2 == ReadBytes(offerSize2.rest, 2) IN IF ~offerPriorityCustomerSize2.ok THEN Fail ELSE
    LET offerCondition == ReadBytes(offerPriorityCustomerSize2.rest, 1) IN IF ~offerCondition.ok THEN Fail ELSE
    Ok([ nanoseconds                |-> nanoseconds.value,
         strategyId                 |-> strategyId.value,
         bidPrice2                  |-> bidPrice2.value,
         bidSize2                   |-> bidSize2.value,
         bidPriorityCustomerSize2   |-> bidPriorityCustomerSize2.value,
         bidCondition               |-> bidCondition.value,
         offerPrice2                |-> offerPrice2.value,
         offerSize2                 |-> offerSize2.value,
         offerPriorityCustomerSize2 |-> offerPriorityCustomerSize2.value,
         offerCondition             |-> offerCondition.value ], offerCondition.rest)

ZeroComplexDoubleSidedTopOfMarketCompactMessage ==
    [ nanoseconds                |-> [i \in 1 .. 4 |-> 0],
      strategyId                 |-> [i \in 1 .. 4 |-> 0],
      bidPrice2                  |-> [i \in 1 .. 2 |-> 0],
      bidSize2                   |-> [i \in 1 .. 2 |-> 0],
      bidPriorityCustomerSize2   |-> [i \in 1 .. 2 |-> 0],
      bidCondition               |-> [i \in 1 .. 1 |-> 0],
      offerPrice2                |-> [i \in 1 .. 2 |-> 0],
      offerSize2                 |-> [i \in 1 .. 2 |-> 0],
      offerPriorityCustomerSize2 |-> [i \in 1 .. 2 |-> 0],
      offerCondition             |-> [i \in 1 .. 1 |-> 0] ]

(* Complex Double Sided Top Of Market Compact Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexDoubleSidedTopOfMarketCompactMessage ==
    { ZeroComplexDoubleSidedTopOfMarketCompactMessage }
        \cup { [ZeroComplexDoubleSidedTopOfMarketCompactMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroComplexDoubleSidedTopOfMarketCompactMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroComplexDoubleSidedTopOfMarketCompactMessage EXCEPT !.bidPrice2 = one] : one \in Sample(2) }
        \cup { [ZeroComplexDoubleSidedTopOfMarketCompactMessage EXCEPT !.bidSize2 = one] : one \in Sample(2) }
        \cup { [ZeroComplexDoubleSidedTopOfMarketCompactMessage EXCEPT !.bidPriorityCustomerSize2 = one] : one \in Sample(2) }
        \cup { [ZeroComplexDoubleSidedTopOfMarketCompactMessage EXCEPT !.bidCondition = one] : one \in Sample(1) }
        \cup { [ZeroComplexDoubleSidedTopOfMarketCompactMessage EXCEPT !.offerPrice2 = one] : one \in Sample(2) }
        \cup { [ZeroComplexDoubleSidedTopOfMarketCompactMessage EXCEPT !.offerSize2 = one] : one \in Sample(2) }
        \cup { [ZeroComplexDoubleSidedTopOfMarketCompactMessage EXCEPT !.offerPriorityCustomerSize2 = one] : one \in Sample(2) }
        \cup { [ZeroComplexDoubleSidedTopOfMarketCompactMessage EXCEPT !.offerCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Complex Double Sided Top Of Market Wide Message: 42 bytes               *)
(***************************************************************************)

ComplexDoubleSidedTopOfMarketWideMessage ==
    [ nanoseconds                : Sample(4),
      strategyId                 : Sample(4),
      bidPrice8                  : Sample(8),
      bidSize4                   : Sample(4),
      bidPriorityCustomerSize4   : Sample(4),
      bidCondition               : Sample(1),
      offerPrice8                : Sample(8),
      offerSize4                 : Sample(4),
      offerPriorityCustomerSize4 : Sample(4),
      offerCondition             : Sample(1) ]

EncodeComplexDoubleSidedTopOfMarketWideMessage(message) ==
    message.nanoseconds
        \o message.strategyId
        \o message.bidPrice8
        \o message.bidSize4
        \o message.bidPriorityCustomerSize4
        \o message.bidCondition
        \o message.offerPrice8
        \o message.offerSize4
        \o message.offerPriorityCustomerSize4
        \o message.offerCondition

DecodeComplexDoubleSidedTopOfMarketWideMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET strategyId == ReadBytes(nanoseconds.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET bidPrice8 == ReadBytes(strategyId.rest, 8) IN IF ~bidPrice8.ok THEN Fail ELSE
    LET bidSize4 == ReadBytes(bidPrice8.rest, 4) IN IF ~bidSize4.ok THEN Fail ELSE
    LET bidPriorityCustomerSize4 == ReadBytes(bidSize4.rest, 4) IN IF ~bidPriorityCustomerSize4.ok THEN Fail ELSE
    LET bidCondition == ReadBytes(bidPriorityCustomerSize4.rest, 1) IN IF ~bidCondition.ok THEN Fail ELSE
    LET offerPrice8 == ReadBytes(bidCondition.rest, 8) IN IF ~offerPrice8.ok THEN Fail ELSE
    LET offerSize4 == ReadBytes(offerPrice8.rest, 4) IN IF ~offerSize4.ok THEN Fail ELSE
    LET offerPriorityCustomerSize4 == ReadBytes(offerSize4.rest, 4) IN IF ~offerPriorityCustomerSize4.ok THEN Fail ELSE
    LET offerCondition == ReadBytes(offerPriorityCustomerSize4.rest, 1) IN IF ~offerCondition.ok THEN Fail ELSE
    Ok([ nanoseconds                |-> nanoseconds.value,
         strategyId                 |-> strategyId.value,
         bidPrice8                  |-> bidPrice8.value,
         bidSize4                   |-> bidSize4.value,
         bidPriorityCustomerSize4   |-> bidPriorityCustomerSize4.value,
         bidCondition               |-> bidCondition.value,
         offerPrice8                |-> offerPrice8.value,
         offerSize4                 |-> offerSize4.value,
         offerPriorityCustomerSize4 |-> offerPriorityCustomerSize4.value,
         offerCondition             |-> offerCondition.value ], offerCondition.rest)

ZeroComplexDoubleSidedTopOfMarketWideMessage ==
    [ nanoseconds                |-> [i \in 1 .. 4 |-> 0],
      strategyId                 |-> [i \in 1 .. 4 |-> 0],
      bidPrice8                  |-> [i \in 1 .. 8 |-> 0],
      bidSize4                   |-> [i \in 1 .. 4 |-> 0],
      bidPriorityCustomerSize4   |-> [i \in 1 .. 4 |-> 0],
      bidCondition               |-> [i \in 1 .. 1 |-> 0],
      offerPrice8                |-> [i \in 1 .. 8 |-> 0],
      offerSize4                 |-> [i \in 1 .. 4 |-> 0],
      offerPriorityCustomerSize4 |-> [i \in 1 .. 4 |-> 0],
      offerCondition             |-> [i \in 1 .. 1 |-> 0] ]

(* Complex Double Sided Top Of Market Wide Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexDoubleSidedTopOfMarketWideMessage ==
    { ZeroComplexDoubleSidedTopOfMarketWideMessage }
        \cup { [ZeroComplexDoubleSidedTopOfMarketWideMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroComplexDoubleSidedTopOfMarketWideMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroComplexDoubleSidedTopOfMarketWideMessage EXCEPT !.bidPrice8 = one] : one \in Sample(8) }
        \cup { [ZeroComplexDoubleSidedTopOfMarketWideMessage EXCEPT !.bidSize4 = one] : one \in Sample(4) }
        \cup { [ZeroComplexDoubleSidedTopOfMarketWideMessage EXCEPT !.bidPriorityCustomerSize4 = one] : one \in Sample(4) }
        \cup { [ZeroComplexDoubleSidedTopOfMarketWideMessage EXCEPT !.bidCondition = one] : one \in Sample(1) }
        \cup { [ZeroComplexDoubleSidedTopOfMarketWideMessage EXCEPT !.offerPrice8 = one] : one \in Sample(8) }
        \cup { [ZeroComplexDoubleSidedTopOfMarketWideMessage EXCEPT !.offerSize4 = one] : one \in Sample(4) }
        \cup { [ZeroComplexDoubleSidedTopOfMarketWideMessage EXCEPT !.offerPriorityCustomerSize4 = one] : one \in Sample(4) }
        \cup { [ZeroComplexDoubleSidedTopOfMarketWideMessage EXCEPT !.offerCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Strategy Last Sale Message: 41 bytes                                    *)
(***************************************************************************)

StrategyLastSaleMessage ==
    [ nanoseconds    : Sample(4),
      strategyId     : Sample(4),
      tradeId        : Sample(4),
      netPrice       : Sample(8),
      tradeSize      : Sample(4),
      tradeCondition : Sample(1),
      reserved16     : Sample(16) ]

EncodeStrategyLastSaleMessage(message) ==
    message.nanoseconds
        \o message.strategyId
        \o message.tradeId
        \o message.netPrice
        \o message.tradeSize
        \o message.tradeCondition
        \o message.reserved16

DecodeStrategyLastSaleMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET strategyId == ReadBytes(nanoseconds.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(strategyId.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET netPrice == ReadBytes(tradeId.rest, 8) IN IF ~netPrice.ok THEN Fail ELSE
    LET tradeSize == ReadBytes(netPrice.rest, 4) IN IF ~tradeSize.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(tradeSize.rest, 1) IN IF ~tradeCondition.ok THEN Fail ELSE
    LET reserved16 == ReadBytes(tradeCondition.rest, 16) IN IF ~reserved16.ok THEN Fail ELSE
    Ok([ nanoseconds    |-> nanoseconds.value,
         strategyId     |-> strategyId.value,
         tradeId        |-> tradeId.value,
         netPrice       |-> netPrice.value,
         tradeSize      |-> tradeSize.value,
         tradeCondition |-> tradeCondition.value,
         reserved16     |-> reserved16.value ], reserved16.rest)

ZeroStrategyLastSaleMessage ==
    [ nanoseconds    |-> [i \in 1 .. 4 |-> 0],
      strategyId     |-> [i \in 1 .. 4 |-> 0],
      tradeId        |-> [i \in 1 .. 4 |-> 0],
      netPrice       |-> [i \in 1 .. 8 |-> 0],
      tradeSize      |-> [i \in 1 .. 4 |-> 0],
      tradeCondition |-> [i \in 1 .. 1 |-> 0],
      reserved16     |-> [i \in 1 .. 16 |-> 0] ]

(* Strategy Last Sale Message at zero, then each field in turn at the values it is checked at *)
CheckedStrategyLastSaleMessage ==
    { ZeroStrategyLastSaleMessage }
        \cup { [ZeroStrategyLastSaleMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroStrategyLastSaleMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroStrategyLastSaleMessage EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroStrategyLastSaleMessage EXCEPT !.netPrice = one] : one \in Sample(8) }
        \cup { [ZeroStrategyLastSaleMessage EXCEPT !.tradeSize = one] : one \in Sample(4) }
        \cup { [ZeroStrategyLastSaleMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }
        \cup { [ZeroStrategyLastSaleMessage EXCEPT !.reserved16 = one] : one \in Sample(16) }

(***************************************************************************)
(* Underlying Trading Status Notification Message: 25 bytes                *)
(***************************************************************************)

UnderlyingTradingStatusNotificationMessage ==
    [ nanoseconds                  : Sample(4),
      underlyingSymbol             : Sample(11),
      tradingStatus                : Sample(1),
      eventReason                  : Sample(1),
      expectedEventTimeSeconds     : Sample(4),
      expectedEventTimeNanoSeconds : Sample(4) ]

EncodeUnderlyingTradingStatusNotificationMessage(message) ==
    message.nanoseconds
        \o message.underlyingSymbol
        \o message.tradingStatus
        \o message.eventReason
        \o message.expectedEventTimeSeconds
        \o message.expectedEventTimeNanoSeconds

DecodeUnderlyingTradingStatusNotificationMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(nanoseconds.rest, 11) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(underlyingSymbol.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET eventReason == ReadBytes(tradingStatus.rest, 1) IN IF ~eventReason.ok THEN Fail ELSE
    LET expectedEventTimeSeconds == ReadBytes(eventReason.rest, 4) IN IF ~expectedEventTimeSeconds.ok THEN Fail ELSE
    LET expectedEventTimeNanoSeconds == ReadBytes(expectedEventTimeSeconds.rest, 4) IN IF ~expectedEventTimeNanoSeconds.ok THEN Fail ELSE
    Ok([ nanoseconds                  |-> nanoseconds.value,
         underlyingSymbol             |-> underlyingSymbol.value,
         tradingStatus                |-> tradingStatus.value,
         eventReason                  |-> eventReason.value,
         expectedEventTimeSeconds     |-> expectedEventTimeSeconds.value,
         expectedEventTimeNanoSeconds |-> expectedEventTimeNanoSeconds.value ], expectedEventTimeNanoSeconds.rest)

ZeroUnderlyingTradingStatusNotificationMessage ==
    [ nanoseconds                  |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbol             |-> [i \in 1 .. 11 |-> 0],
      tradingStatus                |-> [i \in 1 .. 1 |-> 0],
      eventReason                  |-> [i \in 1 .. 1 |-> 0],
      expectedEventTimeSeconds     |-> [i \in 1 .. 4 |-> 0],
      expectedEventTimeNanoSeconds |-> [i \in 1 .. 4 |-> 0] ]

(* Underlying Trading Status Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedUnderlyingTradingStatusNotificationMessage ==
    { ZeroUnderlyingTradingStatusNotificationMessage }
        \cup { [ZeroUnderlyingTradingStatusNotificationMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingTradingStatusNotificationMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }
        \cup { [ZeroUnderlyingTradingStatusNotificationMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingTradingStatusNotificationMessage EXCEPT !.eventReason = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingTradingStatusNotificationMessage EXCEPT !.expectedEventTimeSeconds = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingTradingStatusNotificationMessage EXCEPT !.expectedEventTimeNanoSeconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Data, selected by Message Type                                          *)
(***************************************************************************)

SystemTimeMessageCode == 49  \* "1"
SimpleSeriesUpdateMessageCode == 80  \* "P"
ComplexStrategyDefinitionMessageCode == 67  \* "C"
SystemStateMessageCode == 83  \* "S"
ComplexTopOfMarketBidCompactMessageCode == 98  \* "b"
ComplexTopOfMarketOfferCompactMessageCode == 111  \* "o"
ComplexTopOfMarketBidWideMessageCode == 101  \* "e"
ComplexTopOfMarketOfferWideMessageCode == 102  \* "f"
ComplexDoubleSidedTopOfMarketCompactMessageCode == 109  \* "m"
ComplexDoubleSidedTopOfMarketWideMessageCode == 119  \* "w"
StrategyLastSaleMessageCode == 116  \* "t"
UnderlyingTradingStatusNotificationMessageCode == 72  \* "H"

Data ==
    [ tag : {SystemTimeMessageCode}, body : SystemTimeMessage ]
        \cup [ tag : {SimpleSeriesUpdateMessageCode}, body : SimpleSeriesUpdateMessage ]
        \cup [ tag : {ComplexStrategyDefinitionMessageCode}, body : ComplexStrategyDefinitionMessage ]
        \cup [ tag : {SystemStateMessageCode}, body : SystemStateMessage ]
        \cup [ tag : {ComplexTopOfMarketBidCompactMessageCode}, body : ComplexTopOfMarketBidCompactMessage ]
        \cup [ tag : {ComplexTopOfMarketOfferCompactMessageCode}, body : ComplexTopOfMarketOfferCompactMessage ]
        \cup [ tag : {ComplexTopOfMarketBidWideMessageCode}, body : ComplexTopOfMarketBidWideMessage ]
        \cup [ tag : {ComplexTopOfMarketOfferWideMessageCode}, body : ComplexTopOfMarketOfferWideMessage ]
        \cup [ tag : {ComplexDoubleSidedTopOfMarketCompactMessageCode}, body : ComplexDoubleSidedTopOfMarketCompactMessage ]
        \cup [ tag : {ComplexDoubleSidedTopOfMarketWideMessageCode}, body : ComplexDoubleSidedTopOfMarketWideMessage ]
        \cup [ tag : {StrategyLastSaleMessageCode}, body : StrategyLastSaleMessage ]
        \cup [ tag : {UnderlyingTradingStatusNotificationMessageCode}, body : UnderlyingTradingStatusNotificationMessage ]

EncodeData(message) ==
    CASE message.tag = SystemTimeMessageCode -> EncodeSystemTimeMessage(message.body)
      [] message.tag = SimpleSeriesUpdateMessageCode -> EncodeSimpleSeriesUpdateMessage(message.body)
      [] message.tag = ComplexStrategyDefinitionMessageCode -> EncodeComplexStrategyDefinitionMessage(message.body)
      [] message.tag = SystemStateMessageCode -> EncodeSystemStateMessage(message.body)
      [] message.tag = ComplexTopOfMarketBidCompactMessageCode -> EncodeComplexTopOfMarketBidCompactMessage(message.body)
      [] message.tag = ComplexTopOfMarketOfferCompactMessageCode -> EncodeComplexTopOfMarketOfferCompactMessage(message.body)
      [] message.tag = ComplexTopOfMarketBidWideMessageCode -> EncodeComplexTopOfMarketBidWideMessage(message.body)
      [] message.tag = ComplexTopOfMarketOfferWideMessageCode -> EncodeComplexTopOfMarketOfferWideMessage(message.body)
      [] message.tag = ComplexDoubleSidedTopOfMarketCompactMessageCode -> EncodeComplexDoubleSidedTopOfMarketCompactMessage(message.body)
      [] message.tag = ComplexDoubleSidedTopOfMarketWideMessageCode -> EncodeComplexDoubleSidedTopOfMarketWideMessage(message.body)
      [] message.tag = StrategyLastSaleMessageCode -> EncodeStrategyLastSaleMessage(message.body)
      [] message.tag = UnderlyingTradingStatusNotificationMessageCode -> EncodeUnderlyingTradingStatusNotificationMessage(message.body)

DecodeData(tag, bytes) ==
    LET read ==
            CASE tag = SystemTimeMessageCode -> DecodeSystemTimeMessage(bytes)
              [] tag = SimpleSeriesUpdateMessageCode -> DecodeSimpleSeriesUpdateMessage(bytes)
              [] tag = ComplexStrategyDefinitionMessageCode -> DecodeComplexStrategyDefinitionMessage(bytes)
              [] tag = SystemStateMessageCode -> DecodeSystemStateMessage(bytes)
              [] tag = ComplexTopOfMarketBidCompactMessageCode -> DecodeComplexTopOfMarketBidCompactMessage(bytes)
              [] tag = ComplexTopOfMarketOfferCompactMessageCode -> DecodeComplexTopOfMarketOfferCompactMessage(bytes)
              [] tag = ComplexTopOfMarketBidWideMessageCode -> DecodeComplexTopOfMarketBidWideMessage(bytes)
              [] tag = ComplexTopOfMarketOfferWideMessageCode -> DecodeComplexTopOfMarketOfferWideMessage(bytes)
              [] tag = ComplexDoubleSidedTopOfMarketCompactMessageCode -> DecodeComplexDoubleSidedTopOfMarketCompactMessage(bytes)
              [] tag = ComplexDoubleSidedTopOfMarketWideMessageCode -> DecodeComplexDoubleSidedTopOfMarketWideMessage(bytes)
              [] tag = StrategyLastSaleMessageCode -> DecodeStrategyLastSaleMessage(bytes)
              [] tag = UnderlyingTradingStatusNotificationMessageCode -> DecodeUnderlyingTradingStatusNotificationMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroData == [tag |-> SystemTimeMessageCode, body |-> ZeroSystemTimeMessage]

(* Each Data in turn, at the values the message it names is checked at *)
CheckedData ==
    { [tag |-> SystemTimeMessageCode, body |-> one] : one \in CheckedSystemTimeMessage }
        \cup { [tag |-> SimpleSeriesUpdateMessageCode, body |-> one] : one \in CheckedSimpleSeriesUpdateMessage }
        \cup { [tag |-> ComplexStrategyDefinitionMessageCode, body |-> one] : one \in CheckedComplexStrategyDefinitionMessage }
        \cup { [tag |-> SystemStateMessageCode, body |-> one] : one \in CheckedSystemStateMessage }
        \cup { [tag |-> ComplexTopOfMarketBidCompactMessageCode, body |-> one] : one \in CheckedComplexTopOfMarketBidCompactMessage }
        \cup { [tag |-> ComplexTopOfMarketOfferCompactMessageCode, body |-> one] : one \in CheckedComplexTopOfMarketOfferCompactMessage }
        \cup { [tag |-> ComplexTopOfMarketBidWideMessageCode, body |-> one] : one \in CheckedComplexTopOfMarketBidWideMessage }
        \cup { [tag |-> ComplexTopOfMarketOfferWideMessageCode, body |-> one] : one \in CheckedComplexTopOfMarketOfferWideMessage }
        \cup { [tag |-> ComplexDoubleSidedTopOfMarketCompactMessageCode, body |-> one] : one \in CheckedComplexDoubleSidedTopOfMarketCompactMessage }
        \cup { [tag |-> ComplexDoubleSidedTopOfMarketWideMessageCode, body |-> one] : one \in CheckedComplexDoubleSidedTopOfMarketWideMessage }
        \cup { [tag |-> StrategyLastSaleMessageCode, body |-> one] : one \in CheckedStrategyLastSaleMessage }
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
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ machMessage : SampleLists(OneMachMessage) ]

EncodePacket(message) ==
    EncodeMachMessageList(message.machMessage)

DecodePacket(bytes) ==
    LET machMessage == ReadMachMessageAll(bytes) IN IF ~machMessage.ok THEN Fail ELSE
    Ok([ machMessage |-> machMessage.value ], machMessage.rest)

ZeroPacket ==
    [ machMessage |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.machMessage = one] : one \in SampleLists(OneMachMessage) }

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

(* Every Complex Strategy Definition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexStrategyDefinitionMessage ==
    \A message \in CheckedComplexStrategyDefinitionMessage :
        LET read == DecodeComplexStrategyDefinitionMessage(EncodeComplexStrategyDefinitionMessage(message))
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

(* Every Complex Top Of Market Bid Compact Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexTopOfMarketBidCompactMessage ==
    \A message \in CheckedComplexTopOfMarketBidCompactMessage :
        LET read == DecodeComplexTopOfMarketBidCompactMessage(EncodeComplexTopOfMarketBidCompactMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Top Of Market Offer Compact Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexTopOfMarketOfferCompactMessage ==
    \A message \in CheckedComplexTopOfMarketOfferCompactMessage :
        LET read == DecodeComplexTopOfMarketOfferCompactMessage(EncodeComplexTopOfMarketOfferCompactMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Top Of Market Bid Wide Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexTopOfMarketBidWideMessage ==
    \A message \in CheckedComplexTopOfMarketBidWideMessage :
        LET read == DecodeComplexTopOfMarketBidWideMessage(EncodeComplexTopOfMarketBidWideMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Top Of Market Offer Wide Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexTopOfMarketOfferWideMessage ==
    \A message \in CheckedComplexTopOfMarketOfferWideMessage :
        LET read == DecodeComplexTopOfMarketOfferWideMessage(EncodeComplexTopOfMarketOfferWideMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Double Sided Top Of Market Compact Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexDoubleSidedTopOfMarketCompactMessage ==
    \A message \in CheckedComplexDoubleSidedTopOfMarketCompactMessage :
        LET read == DecodeComplexDoubleSidedTopOfMarketCompactMessage(EncodeComplexDoubleSidedTopOfMarketCompactMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Double Sided Top Of Market Wide Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexDoubleSidedTopOfMarketWideMessage ==
    \A message \in CheckedComplexDoubleSidedTopOfMarketWideMessage :
        LET read == DecodeComplexDoubleSidedTopOfMarketWideMessage(EncodeComplexDoubleSidedTopOfMarketWideMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Last Sale Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyLastSaleMessage ==
    \A message \in CheckedStrategyLastSaleMessage :
        LET read == DecodeStrategyLastSaleMessage(EncodeStrategyLastSaleMessage(message))
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

(* Every Mach Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMachMessage ==
    \A message \in CheckedMachMessage :
        LET read == DecodeMachMessage(EncodeMachMessage(message))
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
