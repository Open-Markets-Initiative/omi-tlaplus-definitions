---------------- MODULE MiaxOptions_ComplexTopOfMarket_v1_1 ----------------
(***************************************************************************)
(* Miami International Holdings Complex Top Of Market v1.1                 *)
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
(* Series Update: 72 bytes                                                 *)
(***************************************************************************)

SeriesUpdate ==
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

EncodeSeriesUpdate(message) ==
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

DecodeSeriesUpdate(bytes) ==
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

ZeroSeriesUpdate ==
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

(* Series Update at zero, then each field in turn at the values it is checked at *)
CheckedSeriesUpdate ==
    { ZeroSeriesUpdate }
        \cup { [ZeroSeriesUpdate EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSeriesUpdate EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroSeriesUpdate EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }
        \cup { [ZeroSeriesUpdate EXCEPT !.securitySymbol = one] : one \in Sample(6) }
        \cup { [ZeroSeriesUpdate EXCEPT !.expirationDate = one] : one \in Sample(8) }
        \cup { [ZeroSeriesUpdate EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroSeriesUpdate EXCEPT !.callOrPut = one] : one \in Sample(1) }
        \cup { [ZeroSeriesUpdate EXCEPT !.openingTime = one] : one \in Sample(8) }
        \cup { [ZeroSeriesUpdate EXCEPT !.closingTime = one] : one \in Sample(8) }
        \cup { [ZeroSeriesUpdate EXCEPT !.restrictedOption = one] : one \in Sample(1) }
        \cup { [ZeroSeriesUpdate EXCEPT !.longTermOption = one] : one \in Sample(1) }
        \cup { [ZeroSeriesUpdate EXCEPT !.activeOnMiax = one] : one \in Sample(1) }
        \cup { [ZeroSeriesUpdate EXCEPT !.miaxBboPostingIncrementIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSeriesUpdate EXCEPT !.liquidityAcceptanceIncrementIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSeriesUpdate EXCEPT !.openingUnderlyingMarketCode = one] : one \in Sample(1) }
        \cup { [ZeroSeriesUpdate EXCEPT !.priorityQuoteWidth = one] : one \in Sample(4) }
        \cup { [ZeroSeriesUpdate EXCEPT !.reserved8 = one] : one \in Sample(8) }

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
      cToMVersion  : Sample(8),
      sessionId    : Sample(4),
      systemStatus : Sample(1) ]

EncodeSystemStateMessage(message) ==
    message.nanoseconds
        \o message.cToMVersion
        \o message.sessionId
        \o message.systemStatus

DecodeSystemStateMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET cToMVersion == ReadBytes(nanoseconds.rest, 8) IN IF ~cToMVersion.ok THEN Fail ELSE
    LET sessionId == ReadBytes(cToMVersion.rest, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET systemStatus == ReadBytes(sessionId.rest, 1) IN IF ~systemStatus.ok THEN Fail ELSE
    Ok([ nanoseconds  |-> nanoseconds.value,
         cToMVersion  |-> cToMVersion.value,
         sessionId    |-> sessionId.value,
         systemStatus |-> systemStatus.value ], systemStatus.rest)

ZeroSystemStateMessage ==
    [ nanoseconds  |-> [i \in 1 .. 4 |-> 0],
      cToMVersion  |-> [i \in 1 .. 8 |-> 0],
      sessionId    |-> [i \in 1 .. 4 |-> 0],
      systemStatus |-> [i \in 1 .. 1 |-> 0] ]

(* System State Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemStateMessage ==
    { ZeroSystemStateMessage }
        \cup { [ZeroSystemStateMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSystemStateMessage EXCEPT !.cToMVersion = one] : one \in Sample(8) }
        \cup { [ZeroSystemStateMessage EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroSystemStateMessage EXCEPT !.systemStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Compact Complex Top Of Market Bid Message: 13 bytes                     *)
(***************************************************************************)

CompactComplexTopOfMarketBidMessage ==
    [ nanoseconds               : Sample(4),
      strategyId                : Sample(4),
      compactPrice              : Sample(2),
      compactSize               : Sample(2),
      topOfMarketQuoteCondition : Sample(1) ]

EncodeCompactComplexTopOfMarketBidMessage(message) ==
    message.nanoseconds
        \o message.strategyId
        \o message.compactPrice
        \o message.compactSize
        \o message.topOfMarketQuoteCondition

DecodeCompactComplexTopOfMarketBidMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET strategyId == ReadBytes(nanoseconds.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET compactPrice == ReadBytes(strategyId.rest, 2) IN IF ~compactPrice.ok THEN Fail ELSE
    LET compactSize == ReadBytes(compactPrice.rest, 2) IN IF ~compactSize.ok THEN Fail ELSE
    LET topOfMarketQuoteCondition == ReadBytes(compactSize.rest, 1) IN IF ~topOfMarketQuoteCondition.ok THEN Fail ELSE
    Ok([ nanoseconds               |-> nanoseconds.value,
         strategyId                |-> strategyId.value,
         compactPrice              |-> compactPrice.value,
         compactSize               |-> compactSize.value,
         topOfMarketQuoteCondition |-> topOfMarketQuoteCondition.value ], topOfMarketQuoteCondition.rest)

ZeroCompactComplexTopOfMarketBidMessage ==
    [ nanoseconds               |-> [i \in 1 .. 4 |-> 0],
      strategyId                |-> [i \in 1 .. 4 |-> 0],
      compactPrice              |-> [i \in 1 .. 2 |-> 0],
      compactSize               |-> [i \in 1 .. 2 |-> 0],
      topOfMarketQuoteCondition |-> [i \in 1 .. 1 |-> 0] ]

(* Compact Complex Top Of Market Bid Message at zero, then each field in turn at the values it is checked at *)
CheckedCompactComplexTopOfMarketBidMessage ==
    { ZeroCompactComplexTopOfMarketBidMessage }
        \cup { [ZeroCompactComplexTopOfMarketBidMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroCompactComplexTopOfMarketBidMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroCompactComplexTopOfMarketBidMessage EXCEPT !.compactPrice = one] : one \in Sample(2) }
        \cup { [ZeroCompactComplexTopOfMarketBidMessage EXCEPT !.compactSize = one] : one \in Sample(2) }
        \cup { [ZeroCompactComplexTopOfMarketBidMessage EXCEPT !.topOfMarketQuoteCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Compact Complex Top Of Market Offer Message: 15 bytes                   *)
(***************************************************************************)

CompactComplexTopOfMarketOfferMessage ==
    [ nanoseconds               : Sample(4),
      strategyId                : Sample(4),
      compactPrice              : Sample(2),
      compactSize               : Sample(2),
      reserved2                 : Sample(2),
      topOfMarketQuoteCondition : Sample(1) ]

EncodeCompactComplexTopOfMarketOfferMessage(message) ==
    message.nanoseconds
        \o message.strategyId
        \o message.compactPrice
        \o message.compactSize
        \o message.reserved2
        \o message.topOfMarketQuoteCondition

DecodeCompactComplexTopOfMarketOfferMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET strategyId == ReadBytes(nanoseconds.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET compactPrice == ReadBytes(strategyId.rest, 2) IN IF ~compactPrice.ok THEN Fail ELSE
    LET compactSize == ReadBytes(compactPrice.rest, 2) IN IF ~compactSize.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(compactSize.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET topOfMarketQuoteCondition == ReadBytes(reserved2.rest, 1) IN IF ~topOfMarketQuoteCondition.ok THEN Fail ELSE
    Ok([ nanoseconds               |-> nanoseconds.value,
         strategyId                |-> strategyId.value,
         compactPrice              |-> compactPrice.value,
         compactSize               |-> compactSize.value,
         reserved2                 |-> reserved2.value,
         topOfMarketQuoteCondition |-> topOfMarketQuoteCondition.value ], topOfMarketQuoteCondition.rest)

ZeroCompactComplexTopOfMarketOfferMessage ==
    [ nanoseconds               |-> [i \in 1 .. 4 |-> 0],
      strategyId                |-> [i \in 1 .. 4 |-> 0],
      compactPrice              |-> [i \in 1 .. 2 |-> 0],
      compactSize               |-> [i \in 1 .. 2 |-> 0],
      reserved2                 |-> [i \in 1 .. 2 |-> 0],
      topOfMarketQuoteCondition |-> [i \in 1 .. 1 |-> 0] ]

(* Compact Complex Top Of Market Offer Message at zero, then each field in turn at the values it is checked at *)
CheckedCompactComplexTopOfMarketOfferMessage ==
    { ZeroCompactComplexTopOfMarketOfferMessage }
        \cup { [ZeroCompactComplexTopOfMarketOfferMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroCompactComplexTopOfMarketOfferMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroCompactComplexTopOfMarketOfferMessage EXCEPT !.compactPrice = one] : one \in Sample(2) }
        \cup { [ZeroCompactComplexTopOfMarketOfferMessage EXCEPT !.compactSize = one] : one \in Sample(2) }
        \cup { [ZeroCompactComplexTopOfMarketOfferMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroCompactComplexTopOfMarketOfferMessage EXCEPT !.topOfMarketQuoteCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Wide Complex Top Of Market Bid Message: 25 bytes                        *)
(***************************************************************************)

WideComplexTopOfMarketBidMessage ==
    [ nanoseconds               : Sample(4),
      strategyId                : Sample(4),
      widePrice                 : Sample(8),
      wideSize                  : Sample(4),
      reserved4                 : Sample(4),
      topOfMarketQuoteCondition : Sample(1) ]

EncodeWideComplexTopOfMarketBidMessage(message) ==
    message.nanoseconds
        \o message.strategyId
        \o message.widePrice
        \o message.wideSize
        \o message.reserved4
        \o message.topOfMarketQuoteCondition

DecodeWideComplexTopOfMarketBidMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET strategyId == ReadBytes(nanoseconds.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET widePrice == ReadBytes(strategyId.rest, 8) IN IF ~widePrice.ok THEN Fail ELSE
    LET wideSize == ReadBytes(widePrice.rest, 4) IN IF ~wideSize.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(wideSize.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET topOfMarketQuoteCondition == ReadBytes(reserved4.rest, 1) IN IF ~topOfMarketQuoteCondition.ok THEN Fail ELSE
    Ok([ nanoseconds               |-> nanoseconds.value,
         strategyId                |-> strategyId.value,
         widePrice                 |-> widePrice.value,
         wideSize                  |-> wideSize.value,
         reserved4                 |-> reserved4.value,
         topOfMarketQuoteCondition |-> topOfMarketQuoteCondition.value ], topOfMarketQuoteCondition.rest)

ZeroWideComplexTopOfMarketBidMessage ==
    [ nanoseconds               |-> [i \in 1 .. 4 |-> 0],
      strategyId                |-> [i \in 1 .. 4 |-> 0],
      widePrice                 |-> [i \in 1 .. 8 |-> 0],
      wideSize                  |-> [i \in 1 .. 4 |-> 0],
      reserved4                 |-> [i \in 1 .. 4 |-> 0],
      topOfMarketQuoteCondition |-> [i \in 1 .. 1 |-> 0] ]

(* Wide Complex Top Of Market Bid Message at zero, then each field in turn at the values it is checked at *)
CheckedWideComplexTopOfMarketBidMessage ==
    { ZeroWideComplexTopOfMarketBidMessage }
        \cup { [ZeroWideComplexTopOfMarketBidMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroWideComplexTopOfMarketBidMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroWideComplexTopOfMarketBidMessage EXCEPT !.widePrice = one] : one \in Sample(8) }
        \cup { [ZeroWideComplexTopOfMarketBidMessage EXCEPT !.wideSize = one] : one \in Sample(4) }
        \cup { [ZeroWideComplexTopOfMarketBidMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroWideComplexTopOfMarketBidMessage EXCEPT !.topOfMarketQuoteCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Wide Complex Top Of Market Offer Message: 25 bytes                      *)
(***************************************************************************)

WideComplexTopOfMarketOfferMessage ==
    [ nanoseconds               : Sample(4),
      strategyId                : Sample(4),
      widePrice                 : Sample(8),
      wideSize                  : Sample(4),
      reserved4                 : Sample(4),
      topOfMarketQuoteCondition : Sample(1) ]

EncodeWideComplexTopOfMarketOfferMessage(message) ==
    message.nanoseconds
        \o message.strategyId
        \o message.widePrice
        \o message.wideSize
        \o message.reserved4
        \o message.topOfMarketQuoteCondition

DecodeWideComplexTopOfMarketOfferMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET strategyId == ReadBytes(nanoseconds.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET widePrice == ReadBytes(strategyId.rest, 8) IN IF ~widePrice.ok THEN Fail ELSE
    LET wideSize == ReadBytes(widePrice.rest, 4) IN IF ~wideSize.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(wideSize.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET topOfMarketQuoteCondition == ReadBytes(reserved4.rest, 1) IN IF ~topOfMarketQuoteCondition.ok THEN Fail ELSE
    Ok([ nanoseconds               |-> nanoseconds.value,
         strategyId                |-> strategyId.value,
         widePrice                 |-> widePrice.value,
         wideSize                  |-> wideSize.value,
         reserved4                 |-> reserved4.value,
         topOfMarketQuoteCondition |-> topOfMarketQuoteCondition.value ], topOfMarketQuoteCondition.rest)

ZeroWideComplexTopOfMarketOfferMessage ==
    [ nanoseconds               |-> [i \in 1 .. 4 |-> 0],
      strategyId                |-> [i \in 1 .. 4 |-> 0],
      widePrice                 |-> [i \in 1 .. 8 |-> 0],
      wideSize                  |-> [i \in 1 .. 4 |-> 0],
      reserved4                 |-> [i \in 1 .. 4 |-> 0],
      topOfMarketQuoteCondition |-> [i \in 1 .. 1 |-> 0] ]

(* Wide Complex Top Of Market Offer Message at zero, then each field in turn at the values it is checked at *)
CheckedWideComplexTopOfMarketOfferMessage ==
    { ZeroWideComplexTopOfMarketOfferMessage }
        \cup { [ZeroWideComplexTopOfMarketOfferMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroWideComplexTopOfMarketOfferMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroWideComplexTopOfMarketOfferMessage EXCEPT !.widePrice = one] : one \in Sample(8) }
        \cup { [ZeroWideComplexTopOfMarketOfferMessage EXCEPT !.wideSize = one] : one \in Sample(4) }
        \cup { [ZeroWideComplexTopOfMarketOfferMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroWideComplexTopOfMarketOfferMessage EXCEPT !.topOfMarketQuoteCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Compact Bid: 7 bytes                                                    *)
(***************************************************************************)

CompactBid ==
    [ compactBidPrice : Sample(2),
      compactBidSize  : Sample(2),
      reserved2       : Sample(2),
      bidCondition    : Sample(1) ]

EncodeCompactBid(message) ==
    message.compactBidPrice
        \o message.compactBidSize
        \o message.reserved2
        \o message.bidCondition

DecodeCompactBid(bytes) ==
    LET compactBidPrice == ReadBytes(bytes, 2) IN IF ~compactBidPrice.ok THEN Fail ELSE
    LET compactBidSize == ReadBytes(compactBidPrice.rest, 2) IN IF ~compactBidSize.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(compactBidSize.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET bidCondition == ReadBytes(reserved2.rest, 1) IN IF ~bidCondition.ok THEN Fail ELSE
    Ok([ compactBidPrice |-> compactBidPrice.value,
         compactBidSize  |-> compactBidSize.value,
         reserved2       |-> reserved2.value,
         bidCondition    |-> bidCondition.value ], bidCondition.rest)

ZeroCompactBid ==
    [ compactBidPrice |-> [i \in 1 .. 2 |-> 0],
      compactBidSize  |-> [i \in 1 .. 2 |-> 0],
      reserved2       |-> [i \in 1 .. 2 |-> 0],
      bidCondition    |-> [i \in 1 .. 1 |-> 0] ]

(* Compact Bid at zero, then each field in turn at the values it is checked at *)
CheckedCompactBid ==
    { ZeroCompactBid }
        \cup { [ZeroCompactBid EXCEPT !.compactBidPrice = one] : one \in Sample(2) }
        \cup { [ZeroCompactBid EXCEPT !.compactBidSize = one] : one \in Sample(2) }
        \cup { [ZeroCompactBid EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroCompactBid EXCEPT !.bidCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Compact Offer: 7 bytes                                                  *)
(***************************************************************************)

CompactOffer ==
    [ compactOfferPrice : Sample(2),
      compactOfferSize  : Sample(2),
      reserved2         : Sample(2),
      offerCondition    : Sample(1) ]

EncodeCompactOffer(message) ==
    message.compactOfferPrice
        \o message.compactOfferSize
        \o message.reserved2
        \o message.offerCondition

DecodeCompactOffer(bytes) ==
    LET compactOfferPrice == ReadBytes(bytes, 2) IN IF ~compactOfferPrice.ok THEN Fail ELSE
    LET compactOfferSize == ReadBytes(compactOfferPrice.rest, 2) IN IF ~compactOfferSize.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(compactOfferSize.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET offerCondition == ReadBytes(reserved2.rest, 1) IN IF ~offerCondition.ok THEN Fail ELSE
    Ok([ compactOfferPrice |-> compactOfferPrice.value,
         compactOfferSize  |-> compactOfferSize.value,
         reserved2         |-> reserved2.value,
         offerCondition    |-> offerCondition.value ], offerCondition.rest)

ZeroCompactOffer ==
    [ compactOfferPrice |-> [i \in 1 .. 2 |-> 0],
      compactOfferSize  |-> [i \in 1 .. 2 |-> 0],
      reserved2         |-> [i \in 1 .. 2 |-> 0],
      offerCondition    |-> [i \in 1 .. 1 |-> 0] ]

(* Compact Offer at zero, then each field in turn at the values it is checked at *)
CheckedCompactOffer ==
    { ZeroCompactOffer }
        \cup { [ZeroCompactOffer EXCEPT !.compactOfferPrice = one] : one \in Sample(2) }
        \cup { [ZeroCompactOffer EXCEPT !.compactOfferSize = one] : one \in Sample(2) }
        \cup { [ZeroCompactOffer EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroCompactOffer EXCEPT !.offerCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Compact Complex Double Sided Top Of Market Message: 22 bytes            *)
(***************************************************************************)

CompactComplexDoubleSidedTopOfMarketMessage ==
    [ nanoseconds  : Sample(4),
      strategyId   : Sample(4),
      compactBid   : CompactBid,
      compactOffer : CompactOffer ]

EncodeCompactComplexDoubleSidedTopOfMarketMessage(message) ==
    message.nanoseconds
        \o message.strategyId
        \o EncodeCompactBid(message.compactBid)
        \o EncodeCompactOffer(message.compactOffer)

DecodeCompactComplexDoubleSidedTopOfMarketMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET strategyId == ReadBytes(nanoseconds.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET compactBid == DecodeCompactBid(strategyId.rest) IN IF ~compactBid.ok THEN Fail ELSE
    LET compactOffer == DecodeCompactOffer(compactBid.rest) IN IF ~compactOffer.ok THEN Fail ELSE
    Ok([ nanoseconds  |-> nanoseconds.value,
         strategyId   |-> strategyId.value,
         compactBid   |-> compactBid.value,
         compactOffer |-> compactOffer.value ], compactOffer.rest)

ZeroCompactComplexDoubleSidedTopOfMarketMessage ==
    [ nanoseconds  |-> [i \in 1 .. 4 |-> 0],
      strategyId   |-> [i \in 1 .. 4 |-> 0],
      compactBid   |-> ZeroCompactBid,
      compactOffer |-> ZeroCompactOffer ]

(* Compact Complex Double Sided Top Of Market Message at zero, then each field in turn at the values it is checked at *)
CheckedCompactComplexDoubleSidedTopOfMarketMessage ==
    { ZeroCompactComplexDoubleSidedTopOfMarketMessage }
        \cup { [ZeroCompactComplexDoubleSidedTopOfMarketMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroCompactComplexDoubleSidedTopOfMarketMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroCompactComplexDoubleSidedTopOfMarketMessage EXCEPT !.compactBid = one] : one \in CheckedCompactBid }
        \cup { [ZeroCompactComplexDoubleSidedTopOfMarketMessage EXCEPT !.compactOffer = one] : one \in CheckedCompactOffer }

(***************************************************************************)
(* Wide Bid: 17 bytes                                                      *)
(***************************************************************************)

WideBid ==
    [ wideBidPrice : Sample(8),
      wideBidSize  : Sample(4),
      reserved4    : Sample(4),
      bidCondition : Sample(1) ]

EncodeWideBid(message) ==
    message.wideBidPrice
        \o message.wideBidSize
        \o message.reserved4
        \o message.bidCondition

DecodeWideBid(bytes) ==
    LET wideBidPrice == ReadBytes(bytes, 8) IN IF ~wideBidPrice.ok THEN Fail ELSE
    LET wideBidSize == ReadBytes(wideBidPrice.rest, 4) IN IF ~wideBidSize.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(wideBidSize.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET bidCondition == ReadBytes(reserved4.rest, 1) IN IF ~bidCondition.ok THEN Fail ELSE
    Ok([ wideBidPrice |-> wideBidPrice.value,
         wideBidSize  |-> wideBidSize.value,
         reserved4    |-> reserved4.value,
         bidCondition |-> bidCondition.value ], bidCondition.rest)

ZeroWideBid ==
    [ wideBidPrice |-> [i \in 1 .. 8 |-> 0],
      wideBidSize  |-> [i \in 1 .. 4 |-> 0],
      reserved4    |-> [i \in 1 .. 4 |-> 0],
      bidCondition |-> [i \in 1 .. 1 |-> 0] ]

(* Wide Bid at zero, then each field in turn at the values it is checked at *)
CheckedWideBid ==
    { ZeroWideBid }
        \cup { [ZeroWideBid EXCEPT !.wideBidPrice = one] : one \in Sample(8) }
        \cup { [ZeroWideBid EXCEPT !.wideBidSize = one] : one \in Sample(4) }
        \cup { [ZeroWideBid EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroWideBid EXCEPT !.bidCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Wide Offer: 17 bytes                                                    *)
(***************************************************************************)

WideOffer ==
    [ wideOfferPrice : Sample(8),
      wideOfferSize  : Sample(4),
      reserved4      : Sample(4),
      offerCondition : Sample(1) ]

EncodeWideOffer(message) ==
    message.wideOfferPrice
        \o message.wideOfferSize
        \o message.reserved4
        \o message.offerCondition

DecodeWideOffer(bytes) ==
    LET wideOfferPrice == ReadBytes(bytes, 8) IN IF ~wideOfferPrice.ok THEN Fail ELSE
    LET wideOfferSize == ReadBytes(wideOfferPrice.rest, 4) IN IF ~wideOfferSize.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(wideOfferSize.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET offerCondition == ReadBytes(reserved4.rest, 1) IN IF ~offerCondition.ok THEN Fail ELSE
    Ok([ wideOfferPrice |-> wideOfferPrice.value,
         wideOfferSize  |-> wideOfferSize.value,
         reserved4      |-> reserved4.value,
         offerCondition |-> offerCondition.value ], offerCondition.rest)

ZeroWideOffer ==
    [ wideOfferPrice |-> [i \in 1 .. 8 |-> 0],
      wideOfferSize  |-> [i \in 1 .. 4 |-> 0],
      reserved4      |-> [i \in 1 .. 4 |-> 0],
      offerCondition |-> [i \in 1 .. 1 |-> 0] ]

(* Wide Offer at zero, then each field in turn at the values it is checked at *)
CheckedWideOffer ==
    { ZeroWideOffer }
        \cup { [ZeroWideOffer EXCEPT !.wideOfferPrice = one] : one \in Sample(8) }
        \cup { [ZeroWideOffer EXCEPT !.wideOfferSize = one] : one \in Sample(4) }
        \cup { [ZeroWideOffer EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroWideOffer EXCEPT !.offerCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Wide Complex Double Sided Top Of Market Message: 42 bytes               *)
(***************************************************************************)

WideComplexDoubleSidedTopOfMarketMessage ==
    [ nanoseconds : Sample(4),
      strategyId  : Sample(4),
      wideBid     : WideBid,
      wideOffer   : WideOffer ]

EncodeWideComplexDoubleSidedTopOfMarketMessage(message) ==
    message.nanoseconds
        \o message.strategyId
        \o EncodeWideBid(message.wideBid)
        \o EncodeWideOffer(message.wideOffer)

DecodeWideComplexDoubleSidedTopOfMarketMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET strategyId == ReadBytes(nanoseconds.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET wideBid == DecodeWideBid(strategyId.rest) IN IF ~wideBid.ok THEN Fail ELSE
    LET wideOffer == DecodeWideOffer(wideBid.rest) IN IF ~wideOffer.ok THEN Fail ELSE
    Ok([ nanoseconds |-> nanoseconds.value,
         strategyId  |-> strategyId.value,
         wideBid     |-> wideBid.value,
         wideOffer   |-> wideOffer.value ], wideOffer.rest)

ZeroWideComplexDoubleSidedTopOfMarketMessage ==
    [ nanoseconds |-> [i \in 1 .. 4 |-> 0],
      strategyId  |-> [i \in 1 .. 4 |-> 0],
      wideBid     |-> ZeroWideBid,
      wideOffer   |-> ZeroWideOffer ]

(* Wide Complex Double Sided Top Of Market Message at zero, then each field in turn at the values it is checked at *)
CheckedWideComplexDoubleSidedTopOfMarketMessage ==
    { ZeroWideComplexDoubleSidedTopOfMarketMessage }
        \cup { [ZeroWideComplexDoubleSidedTopOfMarketMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroWideComplexDoubleSidedTopOfMarketMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroWideComplexDoubleSidedTopOfMarketMessage EXCEPT !.wideBid = one] : one \in CheckedWideBid }
        \cup { [ZeroWideComplexDoubleSidedTopOfMarketMessage EXCEPT !.wideOffer = one] : one \in CheckedWideOffer }

(***************************************************************************)
(* Strategy Trade Message: 41 bytes                                        *)
(***************************************************************************)

StrategyTradeMessage ==
    [ nanoseconds    : Sample(4),
      strategyId     : Sample(4),
      tradeId        : Sample(4),
      netPrice       : Sample(8),
      tradeSize      : Sample(4),
      tradeCondition : Sample(1),
      reserved16     : Sample(16) ]

EncodeStrategyTradeMessage(message) ==
    message.nanoseconds
        \o message.strategyId
        \o message.tradeId
        \o message.netPrice
        \o message.tradeSize
        \o message.tradeCondition
        \o message.reserved16

DecodeStrategyTradeMessage(bytes) ==
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

ZeroStrategyTradeMessage ==
    [ nanoseconds    |-> [i \in 1 .. 4 |-> 0],
      strategyId     |-> [i \in 1 .. 4 |-> 0],
      tradeId        |-> [i \in 1 .. 4 |-> 0],
      netPrice       |-> [i \in 1 .. 8 |-> 0],
      tradeSize      |-> [i \in 1 .. 4 |-> 0],
      tradeCondition |-> [i \in 1 .. 1 |-> 0],
      reserved16     |-> [i \in 1 .. 16 |-> 0] ]

(* Strategy Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedStrategyTradeMessage ==
    { ZeroStrategyTradeMessage }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.netPrice = one] : one \in Sample(8) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.tradeSize = one] : one \in Sample(4) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.reserved16 = one] : one \in Sample(16) }

(***************************************************************************)
(* Underlying Trading Status Message: 25 bytes                             *)
(***************************************************************************)

UnderlyingTradingStatusMessage ==
    [ nanoseconds                      : Sample(4),
      underlyingSymbol                 : Sample(11),
      tradingStatus                    : Sample(1),
      eventReason                      : Sample(1),
      secondsPart                      : Sample(4),
      expectedEventTimeNanoSecondsPart : Sample(4) ]

EncodeUnderlyingTradingStatusMessage(message) ==
    message.nanoseconds
        \o message.underlyingSymbol
        \o message.tradingStatus
        \o message.eventReason
        \o message.secondsPart
        \o message.expectedEventTimeNanoSecondsPart

DecodeUnderlyingTradingStatusMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(nanoseconds.rest, 11) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(underlyingSymbol.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET eventReason == ReadBytes(tradingStatus.rest, 1) IN IF ~eventReason.ok THEN Fail ELSE
    LET secondsPart == ReadBytes(eventReason.rest, 4) IN IF ~secondsPart.ok THEN Fail ELSE
    LET expectedEventTimeNanoSecondsPart == ReadBytes(secondsPart.rest, 4) IN IF ~expectedEventTimeNanoSecondsPart.ok THEN Fail ELSE
    Ok([ nanoseconds                      |-> nanoseconds.value,
         underlyingSymbol                 |-> underlyingSymbol.value,
         tradingStatus                    |-> tradingStatus.value,
         eventReason                      |-> eventReason.value,
         secondsPart                      |-> secondsPart.value,
         expectedEventTimeNanoSecondsPart |-> expectedEventTimeNanoSecondsPart.value ], expectedEventTimeNanoSecondsPart.rest)

ZeroUnderlyingTradingStatusMessage ==
    [ nanoseconds                      |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbol                 |-> [i \in 1 .. 11 |-> 0],
      tradingStatus                    |-> [i \in 1 .. 1 |-> 0],
      eventReason                      |-> [i \in 1 .. 1 |-> 0],
      secondsPart                      |-> [i \in 1 .. 4 |-> 0],
      expectedEventTimeNanoSecondsPart |-> [i \in 1 .. 4 |-> 0] ]

(* Underlying Trading Status Message at zero, then each field in turn at the values it is checked at *)
CheckedUnderlyingTradingStatusMessage ==
    { ZeroUnderlyingTradingStatusMessage }
        \cup { [ZeroUnderlyingTradingStatusMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingTradingStatusMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }
        \cup { [ZeroUnderlyingTradingStatusMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingTradingStatusMessage EXCEPT !.eventReason = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingTradingStatusMessage EXCEPT !.secondsPart = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingTradingStatusMessage EXCEPT !.expectedEventTimeNanoSecondsPart = one] : one \in Sample(4) }

(***************************************************************************)
(* Data, selected by Message Type                                          *)
(***************************************************************************)

SystemTimeMessageCode == 49  \* "1"
SeriesUpdateCode == 80  \* "P"
ComplexStrategyDefinitionMessageCode == 67  \* "C"
SystemStateMessageCode == 83  \* "S"
CompactComplexTopOfMarketBidMessageCode == 98  \* "b"
CompactComplexTopOfMarketOfferMessageCode == 111  \* "o"
WideComplexTopOfMarketBidMessageCode == 101  \* "e"
WideComplexTopOfMarketOfferMessageCode == 102  \* "f"
CompactComplexDoubleSidedTopOfMarketMessageCode == 109  \* "m"
WideComplexDoubleSidedTopOfMarketMessageCode == 119  \* "w"
StrategyTradeMessageCode == 116  \* "t"
UnderlyingTradingStatusMessageCode == 72  \* "H"

Data ==
    [ tag : {SystemTimeMessageCode}, body : SystemTimeMessage ]
        \cup [ tag : {SeriesUpdateCode}, body : SeriesUpdate ]
        \cup [ tag : {ComplexStrategyDefinitionMessageCode}, body : ComplexStrategyDefinitionMessage ]
        \cup [ tag : {SystemStateMessageCode}, body : SystemStateMessage ]
        \cup [ tag : {CompactComplexTopOfMarketBidMessageCode}, body : CompactComplexTopOfMarketBidMessage ]
        \cup [ tag : {CompactComplexTopOfMarketOfferMessageCode}, body : CompactComplexTopOfMarketOfferMessage ]
        \cup [ tag : {WideComplexTopOfMarketBidMessageCode}, body : WideComplexTopOfMarketBidMessage ]
        \cup [ tag : {WideComplexTopOfMarketOfferMessageCode}, body : WideComplexTopOfMarketOfferMessage ]
        \cup [ tag : {CompactComplexDoubleSidedTopOfMarketMessageCode}, body : CompactComplexDoubleSidedTopOfMarketMessage ]
        \cup [ tag : {WideComplexDoubleSidedTopOfMarketMessageCode}, body : WideComplexDoubleSidedTopOfMarketMessage ]
        \cup [ tag : {StrategyTradeMessageCode}, body : StrategyTradeMessage ]
        \cup [ tag : {UnderlyingTradingStatusMessageCode}, body : UnderlyingTradingStatusMessage ]

EncodeData(message) ==
    CASE message.tag = SystemTimeMessageCode -> EncodeSystemTimeMessage(message.body)
      [] message.tag = SeriesUpdateCode -> EncodeSeriesUpdate(message.body)
      [] message.tag = ComplexStrategyDefinitionMessageCode -> EncodeComplexStrategyDefinitionMessage(message.body)
      [] message.tag = SystemStateMessageCode -> EncodeSystemStateMessage(message.body)
      [] message.tag = CompactComplexTopOfMarketBidMessageCode -> EncodeCompactComplexTopOfMarketBidMessage(message.body)
      [] message.tag = CompactComplexTopOfMarketOfferMessageCode -> EncodeCompactComplexTopOfMarketOfferMessage(message.body)
      [] message.tag = WideComplexTopOfMarketBidMessageCode -> EncodeWideComplexTopOfMarketBidMessage(message.body)
      [] message.tag = WideComplexTopOfMarketOfferMessageCode -> EncodeWideComplexTopOfMarketOfferMessage(message.body)
      [] message.tag = CompactComplexDoubleSidedTopOfMarketMessageCode -> EncodeCompactComplexDoubleSidedTopOfMarketMessage(message.body)
      [] message.tag = WideComplexDoubleSidedTopOfMarketMessageCode -> EncodeWideComplexDoubleSidedTopOfMarketMessage(message.body)
      [] message.tag = StrategyTradeMessageCode -> EncodeStrategyTradeMessage(message.body)
      [] message.tag = UnderlyingTradingStatusMessageCode -> EncodeUnderlyingTradingStatusMessage(message.body)

DecodeData(tag, bytes) ==
    LET read ==
            CASE tag = SystemTimeMessageCode -> DecodeSystemTimeMessage(bytes)
              [] tag = SeriesUpdateCode -> DecodeSeriesUpdate(bytes)
              [] tag = ComplexStrategyDefinitionMessageCode -> DecodeComplexStrategyDefinitionMessage(bytes)
              [] tag = SystemStateMessageCode -> DecodeSystemStateMessage(bytes)
              [] tag = CompactComplexTopOfMarketBidMessageCode -> DecodeCompactComplexTopOfMarketBidMessage(bytes)
              [] tag = CompactComplexTopOfMarketOfferMessageCode -> DecodeCompactComplexTopOfMarketOfferMessage(bytes)
              [] tag = WideComplexTopOfMarketBidMessageCode -> DecodeWideComplexTopOfMarketBidMessage(bytes)
              [] tag = WideComplexTopOfMarketOfferMessageCode -> DecodeWideComplexTopOfMarketOfferMessage(bytes)
              [] tag = CompactComplexDoubleSidedTopOfMarketMessageCode -> DecodeCompactComplexDoubleSidedTopOfMarketMessage(bytes)
              [] tag = WideComplexDoubleSidedTopOfMarketMessageCode -> DecodeWideComplexDoubleSidedTopOfMarketMessage(bytes)
              [] tag = StrategyTradeMessageCode -> DecodeStrategyTradeMessage(bytes)
              [] tag = UnderlyingTradingStatusMessageCode -> DecodeUnderlyingTradingStatusMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroData == [tag |-> SystemTimeMessageCode, body |-> ZeroSystemTimeMessage]

(* Each Data in turn, at the values the message it names is checked at *)
CheckedData ==
    { [tag |-> SystemTimeMessageCode, body |-> one] : one \in CheckedSystemTimeMessage }
        \cup { [tag |-> SeriesUpdateCode, body |-> one] : one \in CheckedSeriesUpdate }
        \cup { [tag |-> ComplexStrategyDefinitionMessageCode, body |-> one] : one \in CheckedComplexStrategyDefinitionMessage }
        \cup { [tag |-> SystemStateMessageCode, body |-> one] : one \in CheckedSystemStateMessage }
        \cup { [tag |-> CompactComplexTopOfMarketBidMessageCode, body |-> one] : one \in CheckedCompactComplexTopOfMarketBidMessage }
        \cup { [tag |-> CompactComplexTopOfMarketOfferMessageCode, body |-> one] : one \in CheckedCompactComplexTopOfMarketOfferMessage }
        \cup { [tag |-> WideComplexTopOfMarketBidMessageCode, body |-> one] : one \in CheckedWideComplexTopOfMarketBidMessage }
        \cup { [tag |-> WideComplexTopOfMarketOfferMessageCode, body |-> one] : one \in CheckedWideComplexTopOfMarketOfferMessage }
        \cup { [tag |-> CompactComplexDoubleSidedTopOfMarketMessageCode, body |-> one] : one \in CheckedCompactComplexDoubleSidedTopOfMarketMessage }
        \cup { [tag |-> WideComplexDoubleSidedTopOfMarketMessageCode, body |-> one] : one \in CheckedWideComplexDoubleSidedTopOfMarketMessage }
        \cup { [tag |-> StrategyTradeMessageCode, body |-> one] : one \in CheckedStrategyTradeMessage }
        \cup { [tag |-> UnderlyingTradingStatusMessageCode, body |-> one] : one \in CheckedUnderlyingTradingStatusMessage }

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

(* Every Series Update decodes back to what was encoded, and leaves nothing over *)
RoundTripSeriesUpdate ==
    \A message \in CheckedSeriesUpdate :
        LET read == DecodeSeriesUpdate(EncodeSeriesUpdate(message))
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

(* Every Compact Complex Top Of Market Bid Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCompactComplexTopOfMarketBidMessage ==
    \A message \in CheckedCompactComplexTopOfMarketBidMessage :
        LET read == DecodeCompactComplexTopOfMarketBidMessage(EncodeCompactComplexTopOfMarketBidMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Compact Complex Top Of Market Offer Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCompactComplexTopOfMarketOfferMessage ==
    \A message \in CheckedCompactComplexTopOfMarketOfferMessage :
        LET read == DecodeCompactComplexTopOfMarketOfferMessage(EncodeCompactComplexTopOfMarketOfferMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Wide Complex Top Of Market Bid Message decodes back to what was encoded, and leaves nothing over *)
RoundTripWideComplexTopOfMarketBidMessage ==
    \A message \in CheckedWideComplexTopOfMarketBidMessage :
        LET read == DecodeWideComplexTopOfMarketBidMessage(EncodeWideComplexTopOfMarketBidMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Wide Complex Top Of Market Offer Message decodes back to what was encoded, and leaves nothing over *)
RoundTripWideComplexTopOfMarketOfferMessage ==
    \A message \in CheckedWideComplexTopOfMarketOfferMessage :
        LET read == DecodeWideComplexTopOfMarketOfferMessage(EncodeWideComplexTopOfMarketOfferMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Compact Bid decodes back to what was encoded, and leaves nothing over *)
RoundTripCompactBid ==
    \A message \in CheckedCompactBid :
        LET read == DecodeCompactBid(EncodeCompactBid(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Compact Offer decodes back to what was encoded, and leaves nothing over *)
RoundTripCompactOffer ==
    \A message \in CheckedCompactOffer :
        LET read == DecodeCompactOffer(EncodeCompactOffer(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Compact Complex Double Sided Top Of Market Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCompactComplexDoubleSidedTopOfMarketMessage ==
    \A message \in CheckedCompactComplexDoubleSidedTopOfMarketMessage :
        LET read == DecodeCompactComplexDoubleSidedTopOfMarketMessage(EncodeCompactComplexDoubleSidedTopOfMarketMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Wide Bid decodes back to what was encoded, and leaves nothing over *)
RoundTripWideBid ==
    \A message \in CheckedWideBid :
        LET read == DecodeWideBid(EncodeWideBid(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Wide Offer decodes back to what was encoded, and leaves nothing over *)
RoundTripWideOffer ==
    \A message \in CheckedWideOffer :
        LET read == DecodeWideOffer(EncodeWideOffer(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Wide Complex Double Sided Top Of Market Message decodes back to what was encoded, and leaves nothing over *)
RoundTripWideComplexDoubleSidedTopOfMarketMessage ==
    \A message \in CheckedWideComplexDoubleSidedTopOfMarketMessage :
        LET read == DecodeWideComplexDoubleSidedTopOfMarketMessage(EncodeWideComplexDoubleSidedTopOfMarketMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyTradeMessage ==
    \A message \in CheckedStrategyTradeMessage :
        LET read == DecodeStrategyTradeMessage(EncodeStrategyTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Underlying Trading Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUnderlyingTradingStatusMessage ==
    \A message \in CheckedUnderlyingTradingStatusMessage :
        LET read == DecodeUnderlyingTradingStatusMessage(EncodeUnderlyingTradingStatusMessage(message))
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
