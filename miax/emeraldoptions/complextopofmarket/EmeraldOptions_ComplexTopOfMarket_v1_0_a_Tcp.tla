----------- MODULE EmeraldOptions_ComplexTopOfMarket_v1_0_a_Tcp ------------
(***************************************************************************)
(* Miami International Holdings Complex Top of Market v1.0.a               *)
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
(* Complex Strategy Definition Message                                     *)
(***************************************************************************)

ComplexStrategyDefinitionMessage ==
    [ nanoseconds      : Sample(4),
      strategyId       : Sample(4),
      underlyingSymbol : Sample(11),
      activeOnEmerald  : Sample(1),
      reserved1        : Sample(1),
      updateReason     : Sample(1),
      reserved10       : Sample(10),
      legDefinition    : SampleLists(OneLegDefinition) ]

EncodeComplexStrategyDefinitionMessage(message) ==
    message.nanoseconds
        \o message.strategyId
        \o message.underlyingSymbol
        \o message.activeOnEmerald
        \o message.reserved1
        \o message.updateReason
        \o message.reserved10
        \o EncodeUIntBE(Len(message.legDefinition), 1)
        \o EncodeLegDefinitionList(message.legDefinition)

DecodeComplexStrategyDefinitionMessage(bytes) ==
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

ZeroComplexStrategyDefinitionMessage ==
    [ nanoseconds      |-> [i \in 1 .. 4 |-> 0],
      strategyId       |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbol |-> [i \in 1 .. 11 |-> 0],
      activeOnEmerald  |-> [i \in 1 .. 1 |-> 0],
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
        \cup { [ZeroComplexStrategyDefinitionMessage EXCEPT !.activeOnEmerald = one] : one \in Sample(1) }
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
(* Complex Top Of Market Best Bid Or Offer Compact Format Bid Message: 15  *)
(* bytes                                                                   *)
(***************************************************************************)

ComplexTopOfMarketBestBidOrOfferCompactFormatBidMessage ==
    [ nanoseconds               : Sample(4),
      strategyId                : Sample(4),
      priceShort                : Sample(2),
      sizeShort                 : Sample(2),
      priorityCustomerSizeShort : Sample(2),
      condition                 : Sample(1) ]

EncodeComplexTopOfMarketBestBidOrOfferCompactFormatBidMessage(message) ==
    message.nanoseconds
        \o message.strategyId
        \o message.priceShort
        \o message.sizeShort
        \o message.priorityCustomerSizeShort
        \o message.condition

DecodeComplexTopOfMarketBestBidOrOfferCompactFormatBidMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET strategyId == ReadBytes(nanoseconds.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET priceShort == ReadBytes(strategyId.rest, 2) IN IF ~priceShort.ok THEN Fail ELSE
    LET sizeShort == ReadBytes(priceShort.rest, 2) IN IF ~sizeShort.ok THEN Fail ELSE
    LET priorityCustomerSizeShort == ReadBytes(sizeShort.rest, 2) IN IF ~priorityCustomerSizeShort.ok THEN Fail ELSE
    LET condition == ReadBytes(priorityCustomerSizeShort.rest, 1) IN IF ~condition.ok THEN Fail ELSE
    Ok([ nanoseconds               |-> nanoseconds.value,
         strategyId                |-> strategyId.value,
         priceShort                |-> priceShort.value,
         sizeShort                 |-> sizeShort.value,
         priorityCustomerSizeShort |-> priorityCustomerSizeShort.value,
         condition                 |-> condition.value ], condition.rest)

ZeroComplexTopOfMarketBestBidOrOfferCompactFormatBidMessage ==
    [ nanoseconds               |-> [i \in 1 .. 4 |-> 0],
      strategyId                |-> [i \in 1 .. 4 |-> 0],
      priceShort                |-> [i \in 1 .. 2 |-> 0],
      sizeShort                 |-> [i \in 1 .. 2 |-> 0],
      priorityCustomerSizeShort |-> [i \in 1 .. 2 |-> 0],
      condition                 |-> [i \in 1 .. 1 |-> 0] ]

(* Complex Top Of Market Best Bid Or Offer Compact Format Bid Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexTopOfMarketBestBidOrOfferCompactFormatBidMessage ==
    { ZeroComplexTopOfMarketBestBidOrOfferCompactFormatBidMessage }
        \cup { [ZeroComplexTopOfMarketBestBidOrOfferCompactFormatBidMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroComplexTopOfMarketBestBidOrOfferCompactFormatBidMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroComplexTopOfMarketBestBidOrOfferCompactFormatBidMessage EXCEPT !.priceShort = one] : one \in Sample(2) }
        \cup { [ZeroComplexTopOfMarketBestBidOrOfferCompactFormatBidMessage EXCEPT !.sizeShort = one] : one \in Sample(2) }
        \cup { [ZeroComplexTopOfMarketBestBidOrOfferCompactFormatBidMessage EXCEPT !.priorityCustomerSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroComplexTopOfMarketBestBidOrOfferCompactFormatBidMessage EXCEPT !.condition = one] : one \in Sample(1) }

(***************************************************************************)
(* Complex Top Of Market Best Bid Or Offer Compact Format Offer Message:   *)
(* 15 bytes                                                                *)
(***************************************************************************)

ComplexTopOfMarketBestBidOrOfferCompactFormatOfferMessage ==
    [ nanoseconds               : Sample(4),
      strategyId                : Sample(4),
      priceShort                : Sample(2),
      sizeShort                 : Sample(2),
      priorityCustomerSizeShort : Sample(2),
      condition                 : Sample(1) ]

EncodeComplexTopOfMarketBestBidOrOfferCompactFormatOfferMessage(message) ==
    message.nanoseconds
        \o message.strategyId
        \o message.priceShort
        \o message.sizeShort
        \o message.priorityCustomerSizeShort
        \o message.condition

DecodeComplexTopOfMarketBestBidOrOfferCompactFormatOfferMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET strategyId == ReadBytes(nanoseconds.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET priceShort == ReadBytes(strategyId.rest, 2) IN IF ~priceShort.ok THEN Fail ELSE
    LET sizeShort == ReadBytes(priceShort.rest, 2) IN IF ~sizeShort.ok THEN Fail ELSE
    LET priorityCustomerSizeShort == ReadBytes(sizeShort.rest, 2) IN IF ~priorityCustomerSizeShort.ok THEN Fail ELSE
    LET condition == ReadBytes(priorityCustomerSizeShort.rest, 1) IN IF ~condition.ok THEN Fail ELSE
    Ok([ nanoseconds               |-> nanoseconds.value,
         strategyId                |-> strategyId.value,
         priceShort                |-> priceShort.value,
         sizeShort                 |-> sizeShort.value,
         priorityCustomerSizeShort |-> priorityCustomerSizeShort.value,
         condition                 |-> condition.value ], condition.rest)

ZeroComplexTopOfMarketBestBidOrOfferCompactFormatOfferMessage ==
    [ nanoseconds               |-> [i \in 1 .. 4 |-> 0],
      strategyId                |-> [i \in 1 .. 4 |-> 0],
      priceShort                |-> [i \in 1 .. 2 |-> 0],
      sizeShort                 |-> [i \in 1 .. 2 |-> 0],
      priorityCustomerSizeShort |-> [i \in 1 .. 2 |-> 0],
      condition                 |-> [i \in 1 .. 1 |-> 0] ]

(* Complex Top Of Market Best Bid Or Offer Compact Format Offer Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexTopOfMarketBestBidOrOfferCompactFormatOfferMessage ==
    { ZeroComplexTopOfMarketBestBidOrOfferCompactFormatOfferMessage }
        \cup { [ZeroComplexTopOfMarketBestBidOrOfferCompactFormatOfferMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroComplexTopOfMarketBestBidOrOfferCompactFormatOfferMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroComplexTopOfMarketBestBidOrOfferCompactFormatOfferMessage EXCEPT !.priceShort = one] : one \in Sample(2) }
        \cup { [ZeroComplexTopOfMarketBestBidOrOfferCompactFormatOfferMessage EXCEPT !.sizeShort = one] : one \in Sample(2) }
        \cup { [ZeroComplexTopOfMarketBestBidOrOfferCompactFormatOfferMessage EXCEPT !.priorityCustomerSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroComplexTopOfMarketBestBidOrOfferCompactFormatOfferMessage EXCEPT !.condition = one] : one \in Sample(1) }

(***************************************************************************)
(* Complex Top Of Market Best Bid Or Offer Wide Format Bid Message: 25     *)
(* bytes                                                                   *)
(***************************************************************************)

ComplexTopOfMarketBestBidOrOfferWideFormatBidMessage ==
    [ nanoseconds              : Sample(4),
      strategyId               : Sample(4),
      priceLong                : Sample(8),
      sizeLong                 : Sample(4),
      priorityCustomerSizeLong : Sample(4),
      condition                : Sample(1) ]

EncodeComplexTopOfMarketBestBidOrOfferWideFormatBidMessage(message) ==
    message.nanoseconds
        \o message.strategyId
        \o message.priceLong
        \o message.sizeLong
        \o message.priorityCustomerSizeLong
        \o message.condition

DecodeComplexTopOfMarketBestBidOrOfferWideFormatBidMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET strategyId == ReadBytes(nanoseconds.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET priceLong == ReadBytes(strategyId.rest, 8) IN IF ~priceLong.ok THEN Fail ELSE
    LET sizeLong == ReadBytes(priceLong.rest, 4) IN IF ~sizeLong.ok THEN Fail ELSE
    LET priorityCustomerSizeLong == ReadBytes(sizeLong.rest, 4) IN IF ~priorityCustomerSizeLong.ok THEN Fail ELSE
    LET condition == ReadBytes(priorityCustomerSizeLong.rest, 1) IN IF ~condition.ok THEN Fail ELSE
    Ok([ nanoseconds              |-> nanoseconds.value,
         strategyId               |-> strategyId.value,
         priceLong                |-> priceLong.value,
         sizeLong                 |-> sizeLong.value,
         priorityCustomerSizeLong |-> priorityCustomerSizeLong.value,
         condition                |-> condition.value ], condition.rest)

ZeroComplexTopOfMarketBestBidOrOfferWideFormatBidMessage ==
    [ nanoseconds              |-> [i \in 1 .. 4 |-> 0],
      strategyId               |-> [i \in 1 .. 4 |-> 0],
      priceLong                |-> [i \in 1 .. 8 |-> 0],
      sizeLong                 |-> [i \in 1 .. 4 |-> 0],
      priorityCustomerSizeLong |-> [i \in 1 .. 4 |-> 0],
      condition                |-> [i \in 1 .. 1 |-> 0] ]

(* Complex Top Of Market Best Bid Or Offer Wide Format Bid Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexTopOfMarketBestBidOrOfferWideFormatBidMessage ==
    { ZeroComplexTopOfMarketBestBidOrOfferWideFormatBidMessage }
        \cup { [ZeroComplexTopOfMarketBestBidOrOfferWideFormatBidMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroComplexTopOfMarketBestBidOrOfferWideFormatBidMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroComplexTopOfMarketBestBidOrOfferWideFormatBidMessage EXCEPT !.priceLong = one] : one \in Sample(8) }
        \cup { [ZeroComplexTopOfMarketBestBidOrOfferWideFormatBidMessage EXCEPT !.sizeLong = one] : one \in Sample(4) }
        \cup { [ZeroComplexTopOfMarketBestBidOrOfferWideFormatBidMessage EXCEPT !.priorityCustomerSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroComplexTopOfMarketBestBidOrOfferWideFormatBidMessage EXCEPT !.condition = one] : one \in Sample(1) }

(***************************************************************************)
(* Complex Top Of Market Best Bid Or Offer Wide Format Offer Message: 25   *)
(* bytes                                                                   *)
(***************************************************************************)

ComplexTopOfMarketBestBidOrOfferWideFormatOfferMessage ==
    [ nanoseconds              : Sample(4),
      strategyId               : Sample(4),
      priceLong                : Sample(8),
      sizeLong                 : Sample(4),
      priorityCustomerSizeLong : Sample(4),
      condition                : Sample(1) ]

EncodeComplexTopOfMarketBestBidOrOfferWideFormatOfferMessage(message) ==
    message.nanoseconds
        \o message.strategyId
        \o message.priceLong
        \o message.sizeLong
        \o message.priorityCustomerSizeLong
        \o message.condition

DecodeComplexTopOfMarketBestBidOrOfferWideFormatOfferMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET strategyId == ReadBytes(nanoseconds.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET priceLong == ReadBytes(strategyId.rest, 8) IN IF ~priceLong.ok THEN Fail ELSE
    LET sizeLong == ReadBytes(priceLong.rest, 4) IN IF ~sizeLong.ok THEN Fail ELSE
    LET priorityCustomerSizeLong == ReadBytes(sizeLong.rest, 4) IN IF ~priorityCustomerSizeLong.ok THEN Fail ELSE
    LET condition == ReadBytes(priorityCustomerSizeLong.rest, 1) IN IF ~condition.ok THEN Fail ELSE
    Ok([ nanoseconds              |-> nanoseconds.value,
         strategyId               |-> strategyId.value,
         priceLong                |-> priceLong.value,
         sizeLong                 |-> sizeLong.value,
         priorityCustomerSizeLong |-> priorityCustomerSizeLong.value,
         condition                |-> condition.value ], condition.rest)

ZeroComplexTopOfMarketBestBidOrOfferWideFormatOfferMessage ==
    [ nanoseconds              |-> [i \in 1 .. 4 |-> 0],
      strategyId               |-> [i \in 1 .. 4 |-> 0],
      priceLong                |-> [i \in 1 .. 8 |-> 0],
      sizeLong                 |-> [i \in 1 .. 4 |-> 0],
      priorityCustomerSizeLong |-> [i \in 1 .. 4 |-> 0],
      condition                |-> [i \in 1 .. 1 |-> 0] ]

(* Complex Top Of Market Best Bid Or Offer Wide Format Offer Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexTopOfMarketBestBidOrOfferWideFormatOfferMessage ==
    { ZeroComplexTopOfMarketBestBidOrOfferWideFormatOfferMessage }
        \cup { [ZeroComplexTopOfMarketBestBidOrOfferWideFormatOfferMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroComplexTopOfMarketBestBidOrOfferWideFormatOfferMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroComplexTopOfMarketBestBidOrOfferWideFormatOfferMessage EXCEPT !.priceLong = one] : one \in Sample(8) }
        \cup { [ZeroComplexTopOfMarketBestBidOrOfferWideFormatOfferMessage EXCEPT !.sizeLong = one] : one \in Sample(4) }
        \cup { [ZeroComplexTopOfMarketBestBidOrOfferWideFormatOfferMessage EXCEPT !.priorityCustomerSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroComplexTopOfMarketBestBidOrOfferWideFormatOfferMessage EXCEPT !.condition = one] : one \in Sample(1) }

(***************************************************************************)
(* Complex Double Sided Top Of Market Best Bid And Offer Compact Format    *)
(* Message: 22 bytes                                                       *)
(***************************************************************************)

ComplexDoubleSidedTopOfMarketBestBidAndOfferCompactFormatMessage ==
    [ nanoseconds                    : Sample(4),
      strategyId                     : Sample(4),
      bidPriceShort                  : Sample(2),
      bidSizeShort                   : Sample(2),
      bidPriorityCustomerSizeShort   : Sample(2),
      bidCondition                   : Sample(1),
      offerPriceShort                : Sample(2),
      offerSizeShort                 : Sample(2),
      offerPriorityCustomerSizeShort : Sample(2),
      offerCondition                 : Sample(1) ]

EncodeComplexDoubleSidedTopOfMarketBestBidAndOfferCompactFormatMessage(message) ==
    message.nanoseconds
        \o message.strategyId
        \o message.bidPriceShort
        \o message.bidSizeShort
        \o message.bidPriorityCustomerSizeShort
        \o message.bidCondition
        \o message.offerPriceShort
        \o message.offerSizeShort
        \o message.offerPriorityCustomerSizeShort
        \o message.offerCondition

DecodeComplexDoubleSidedTopOfMarketBestBidAndOfferCompactFormatMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET strategyId == ReadBytes(nanoseconds.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET bidPriceShort == ReadBytes(strategyId.rest, 2) IN IF ~bidPriceShort.ok THEN Fail ELSE
    LET bidSizeShort == ReadBytes(bidPriceShort.rest, 2) IN IF ~bidSizeShort.ok THEN Fail ELSE
    LET bidPriorityCustomerSizeShort == ReadBytes(bidSizeShort.rest, 2) IN IF ~bidPriorityCustomerSizeShort.ok THEN Fail ELSE
    LET bidCondition == ReadBytes(bidPriorityCustomerSizeShort.rest, 1) IN IF ~bidCondition.ok THEN Fail ELSE
    LET offerPriceShort == ReadBytes(bidCondition.rest, 2) IN IF ~offerPriceShort.ok THEN Fail ELSE
    LET offerSizeShort == ReadBytes(offerPriceShort.rest, 2) IN IF ~offerSizeShort.ok THEN Fail ELSE
    LET offerPriorityCustomerSizeShort == ReadBytes(offerSizeShort.rest, 2) IN IF ~offerPriorityCustomerSizeShort.ok THEN Fail ELSE
    LET offerCondition == ReadBytes(offerPriorityCustomerSizeShort.rest, 1) IN IF ~offerCondition.ok THEN Fail ELSE
    Ok([ nanoseconds                    |-> nanoseconds.value,
         strategyId                     |-> strategyId.value,
         bidPriceShort                  |-> bidPriceShort.value,
         bidSizeShort                   |-> bidSizeShort.value,
         bidPriorityCustomerSizeShort   |-> bidPriorityCustomerSizeShort.value,
         bidCondition                   |-> bidCondition.value,
         offerPriceShort                |-> offerPriceShort.value,
         offerSizeShort                 |-> offerSizeShort.value,
         offerPriorityCustomerSizeShort |-> offerPriorityCustomerSizeShort.value,
         offerCondition                 |-> offerCondition.value ], offerCondition.rest)

ZeroComplexDoubleSidedTopOfMarketBestBidAndOfferCompactFormatMessage ==
    [ nanoseconds                    |-> [i \in 1 .. 4 |-> 0],
      strategyId                     |-> [i \in 1 .. 4 |-> 0],
      bidPriceShort                  |-> [i \in 1 .. 2 |-> 0],
      bidSizeShort                   |-> [i \in 1 .. 2 |-> 0],
      bidPriorityCustomerSizeShort   |-> [i \in 1 .. 2 |-> 0],
      bidCondition                   |-> [i \in 1 .. 1 |-> 0],
      offerPriceShort                |-> [i \in 1 .. 2 |-> 0],
      offerSizeShort                 |-> [i \in 1 .. 2 |-> 0],
      offerPriorityCustomerSizeShort |-> [i \in 1 .. 2 |-> 0],
      offerCondition                 |-> [i \in 1 .. 1 |-> 0] ]

(* Complex Double Sided Top Of Market Best Bid And Offer Compact Format Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexDoubleSidedTopOfMarketBestBidAndOfferCompactFormatMessage ==
    { ZeroComplexDoubleSidedTopOfMarketBestBidAndOfferCompactFormatMessage }
        \cup { [ZeroComplexDoubleSidedTopOfMarketBestBidAndOfferCompactFormatMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroComplexDoubleSidedTopOfMarketBestBidAndOfferCompactFormatMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroComplexDoubleSidedTopOfMarketBestBidAndOfferCompactFormatMessage EXCEPT !.bidPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroComplexDoubleSidedTopOfMarketBestBidAndOfferCompactFormatMessage EXCEPT !.bidSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroComplexDoubleSidedTopOfMarketBestBidAndOfferCompactFormatMessage EXCEPT !.bidPriorityCustomerSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroComplexDoubleSidedTopOfMarketBestBidAndOfferCompactFormatMessage EXCEPT !.bidCondition = one] : one \in Sample(1) }
        \cup { [ZeroComplexDoubleSidedTopOfMarketBestBidAndOfferCompactFormatMessage EXCEPT !.offerPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroComplexDoubleSidedTopOfMarketBestBidAndOfferCompactFormatMessage EXCEPT !.offerSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroComplexDoubleSidedTopOfMarketBestBidAndOfferCompactFormatMessage EXCEPT !.offerPriorityCustomerSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroComplexDoubleSidedTopOfMarketBestBidAndOfferCompactFormatMessage EXCEPT !.offerCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Complex Double Sided Top Of Market Best Bid And Offer Wide Format       *)
(* Message: 42 bytes                                                       *)
(***************************************************************************)

ComplexDoubleSidedTopOfMarketBestBidAndOfferWideFormatMessage ==
    [ nanoseconds                   : Sample(4),
      strategyId                    : Sample(4),
      bidPriceLong                  : Sample(8),
      bidSizeLong                   : Sample(4),
      bidPriorityCustomerSizeLong   : Sample(4),
      bidCondition                  : Sample(1),
      offerPriceLong                : Sample(8),
      offerSizeLong                 : Sample(4),
      offerPriorityCustomerSizeLong : Sample(4),
      offerCondition                : Sample(1) ]

EncodeComplexDoubleSidedTopOfMarketBestBidAndOfferWideFormatMessage(message) ==
    message.nanoseconds
        \o message.strategyId
        \o message.bidPriceLong
        \o message.bidSizeLong
        \o message.bidPriorityCustomerSizeLong
        \o message.bidCondition
        \o message.offerPriceLong
        \o message.offerSizeLong
        \o message.offerPriorityCustomerSizeLong
        \o message.offerCondition

DecodeComplexDoubleSidedTopOfMarketBestBidAndOfferWideFormatMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET strategyId == ReadBytes(nanoseconds.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET bidPriceLong == ReadBytes(strategyId.rest, 8) IN IF ~bidPriceLong.ok THEN Fail ELSE
    LET bidSizeLong == ReadBytes(bidPriceLong.rest, 4) IN IF ~bidSizeLong.ok THEN Fail ELSE
    LET bidPriorityCustomerSizeLong == ReadBytes(bidSizeLong.rest, 4) IN IF ~bidPriorityCustomerSizeLong.ok THEN Fail ELSE
    LET bidCondition == ReadBytes(bidPriorityCustomerSizeLong.rest, 1) IN IF ~bidCondition.ok THEN Fail ELSE
    LET offerPriceLong == ReadBytes(bidCondition.rest, 8) IN IF ~offerPriceLong.ok THEN Fail ELSE
    LET offerSizeLong == ReadBytes(offerPriceLong.rest, 4) IN IF ~offerSizeLong.ok THEN Fail ELSE
    LET offerPriorityCustomerSizeLong == ReadBytes(offerSizeLong.rest, 4) IN IF ~offerPriorityCustomerSizeLong.ok THEN Fail ELSE
    LET offerCondition == ReadBytes(offerPriorityCustomerSizeLong.rest, 1) IN IF ~offerCondition.ok THEN Fail ELSE
    Ok([ nanoseconds                   |-> nanoseconds.value,
         strategyId                    |-> strategyId.value,
         bidPriceLong                  |-> bidPriceLong.value,
         bidSizeLong                   |-> bidSizeLong.value,
         bidPriorityCustomerSizeLong   |-> bidPriorityCustomerSizeLong.value,
         bidCondition                  |-> bidCondition.value,
         offerPriceLong                |-> offerPriceLong.value,
         offerSizeLong                 |-> offerSizeLong.value,
         offerPriorityCustomerSizeLong |-> offerPriorityCustomerSizeLong.value,
         offerCondition                |-> offerCondition.value ], offerCondition.rest)

ZeroComplexDoubleSidedTopOfMarketBestBidAndOfferWideFormatMessage ==
    [ nanoseconds                   |-> [i \in 1 .. 4 |-> 0],
      strategyId                    |-> [i \in 1 .. 4 |-> 0],
      bidPriceLong                  |-> [i \in 1 .. 8 |-> 0],
      bidSizeLong                   |-> [i \in 1 .. 4 |-> 0],
      bidPriorityCustomerSizeLong   |-> [i \in 1 .. 4 |-> 0],
      bidCondition                  |-> [i \in 1 .. 1 |-> 0],
      offerPriceLong                |-> [i \in 1 .. 8 |-> 0],
      offerSizeLong                 |-> [i \in 1 .. 4 |-> 0],
      offerPriorityCustomerSizeLong |-> [i \in 1 .. 4 |-> 0],
      offerCondition                |-> [i \in 1 .. 1 |-> 0] ]

(* Complex Double Sided Top Of Market Best Bid And Offer Wide Format Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexDoubleSidedTopOfMarketBestBidAndOfferWideFormatMessage ==
    { ZeroComplexDoubleSidedTopOfMarketBestBidAndOfferWideFormatMessage }
        \cup { [ZeroComplexDoubleSidedTopOfMarketBestBidAndOfferWideFormatMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroComplexDoubleSidedTopOfMarketBestBidAndOfferWideFormatMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroComplexDoubleSidedTopOfMarketBestBidAndOfferWideFormatMessage EXCEPT !.bidPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroComplexDoubleSidedTopOfMarketBestBidAndOfferWideFormatMessage EXCEPT !.bidSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroComplexDoubleSidedTopOfMarketBestBidAndOfferWideFormatMessage EXCEPT !.bidPriorityCustomerSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroComplexDoubleSidedTopOfMarketBestBidAndOfferWideFormatMessage EXCEPT !.bidCondition = one] : one \in Sample(1) }
        \cup { [ZeroComplexDoubleSidedTopOfMarketBestBidAndOfferWideFormatMessage EXCEPT !.offerPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroComplexDoubleSidedTopOfMarketBestBidAndOfferWideFormatMessage EXCEPT !.offerSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroComplexDoubleSidedTopOfMarketBestBidAndOfferWideFormatMessage EXCEPT !.offerPriorityCustomerSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroComplexDoubleSidedTopOfMarketBestBidAndOfferWideFormatMessage EXCEPT !.offerCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Strategy Last Sale Message: 41 bytes                                    *)
(***************************************************************************)

StrategyLastSaleMessage ==
    [ nanoseconds : Sample(4),
      strategyId  : Sample(4),
      tradeId     : Sample(4),
      netPrice    : Sample(8),
      sizeLong    : Sample(4),
      condition   : Sample(1),
      reserved16  : Sample(16) ]

EncodeStrategyLastSaleMessage(message) ==
    message.nanoseconds
        \o message.strategyId
        \o message.tradeId
        \o message.netPrice
        \o message.sizeLong
        \o message.condition
        \o message.reserved16

DecodeStrategyLastSaleMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET strategyId == ReadBytes(nanoseconds.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(strategyId.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET netPrice == ReadBytes(tradeId.rest, 8) IN IF ~netPrice.ok THEN Fail ELSE
    LET sizeLong == ReadBytes(netPrice.rest, 4) IN IF ~sizeLong.ok THEN Fail ELSE
    LET condition == ReadBytes(sizeLong.rest, 1) IN IF ~condition.ok THEN Fail ELSE
    LET reserved16 == ReadBytes(condition.rest, 16) IN IF ~reserved16.ok THEN Fail ELSE
    Ok([ nanoseconds |-> nanoseconds.value,
         strategyId  |-> strategyId.value,
         tradeId     |-> tradeId.value,
         netPrice    |-> netPrice.value,
         sizeLong    |-> sizeLong.value,
         condition   |-> condition.value,
         reserved16  |-> reserved16.value ], reserved16.rest)

ZeroStrategyLastSaleMessage ==
    [ nanoseconds |-> [i \in 1 .. 4 |-> 0],
      strategyId  |-> [i \in 1 .. 4 |-> 0],
      tradeId     |-> [i \in 1 .. 4 |-> 0],
      netPrice    |-> [i \in 1 .. 8 |-> 0],
      sizeLong    |-> [i \in 1 .. 4 |-> 0],
      condition   |-> [i \in 1 .. 1 |-> 0],
      reserved16  |-> [i \in 1 .. 16 |-> 0] ]

(* Strategy Last Sale Message at zero, then each field in turn at the values it is checked at *)
CheckedStrategyLastSaleMessage ==
    { ZeroStrategyLastSaleMessage }
        \cup { [ZeroStrategyLastSaleMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroStrategyLastSaleMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroStrategyLastSaleMessage EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroStrategyLastSaleMessage EXCEPT !.netPrice = one] : one \in Sample(8) }
        \cup { [ZeroStrategyLastSaleMessage EXCEPT !.sizeLong = one] : one \in Sample(4) }
        \cup { [ZeroStrategyLastSaleMessage EXCEPT !.condition = one] : one \in Sample(1) }
        \cup { [ZeroStrategyLastSaleMessage EXCEPT !.reserved16 = one] : one \in Sample(16) }

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
ComplexStrategyDefinitionMessageCode == 67  \* "C"
SystemStateMessageCode == 83  \* "S"
ComplexTopOfMarketBestBidOrOfferCompactFormatBidMessageCode == 98  \* "b"
ComplexTopOfMarketBestBidOrOfferCompactFormatOfferMessageCode == 111  \* "o"
ComplexTopOfMarketBestBidOrOfferWideFormatBidMessageCode == 101  \* "e"
ComplexTopOfMarketBestBidOrOfferWideFormatOfferMessageCode == 102  \* "f"
ComplexDoubleSidedTopOfMarketBestBidAndOfferCompactFormatMessageCode == 109  \* "m"
ComplexDoubleSidedTopOfMarketBestBidAndOfferWideFormatMessageCode == 119  \* "w"
StrategyLastSaleMessageCode == 116  \* "t"
UnderlyingTradingStatusNotificationMessageCode == 72  \* "H"

Data ==
    [ tag : {SystemTimeMessageCode}, body : SystemTimeMessage ]
        \cup [ tag : {SimpleSeriesUpdateMessageCode}, body : SimpleSeriesUpdateMessage ]
        \cup [ tag : {ComplexStrategyDefinitionMessageCode}, body : ComplexStrategyDefinitionMessage ]
        \cup [ tag : {SystemStateMessageCode}, body : SystemStateMessage ]
        \cup [ tag : {ComplexTopOfMarketBestBidOrOfferCompactFormatBidMessageCode}, body : ComplexTopOfMarketBestBidOrOfferCompactFormatBidMessage ]
        \cup [ tag : {ComplexTopOfMarketBestBidOrOfferCompactFormatOfferMessageCode}, body : ComplexTopOfMarketBestBidOrOfferCompactFormatOfferMessage ]
        \cup [ tag : {ComplexTopOfMarketBestBidOrOfferWideFormatBidMessageCode}, body : ComplexTopOfMarketBestBidOrOfferWideFormatBidMessage ]
        \cup [ tag : {ComplexTopOfMarketBestBidOrOfferWideFormatOfferMessageCode}, body : ComplexTopOfMarketBestBidOrOfferWideFormatOfferMessage ]
        \cup [ tag : {ComplexDoubleSidedTopOfMarketBestBidAndOfferCompactFormatMessageCode}, body : ComplexDoubleSidedTopOfMarketBestBidAndOfferCompactFormatMessage ]
        \cup [ tag : {ComplexDoubleSidedTopOfMarketBestBidAndOfferWideFormatMessageCode}, body : ComplexDoubleSidedTopOfMarketBestBidAndOfferWideFormatMessage ]
        \cup [ tag : {StrategyLastSaleMessageCode}, body : StrategyLastSaleMessage ]
        \cup [ tag : {UnderlyingTradingStatusNotificationMessageCode}, body : UnderlyingTradingStatusNotificationMessage ]

EncodeData(message) ==
    CASE message.tag = SystemTimeMessageCode -> EncodeSystemTimeMessage(message.body)
      [] message.tag = SimpleSeriesUpdateMessageCode -> EncodeSimpleSeriesUpdateMessage(message.body)
      [] message.tag = ComplexStrategyDefinitionMessageCode -> EncodeComplexStrategyDefinitionMessage(message.body)
      [] message.tag = SystemStateMessageCode -> EncodeSystemStateMessage(message.body)
      [] message.tag = ComplexTopOfMarketBestBidOrOfferCompactFormatBidMessageCode -> EncodeComplexTopOfMarketBestBidOrOfferCompactFormatBidMessage(message.body)
      [] message.tag = ComplexTopOfMarketBestBidOrOfferCompactFormatOfferMessageCode -> EncodeComplexTopOfMarketBestBidOrOfferCompactFormatOfferMessage(message.body)
      [] message.tag = ComplexTopOfMarketBestBidOrOfferWideFormatBidMessageCode -> EncodeComplexTopOfMarketBestBidOrOfferWideFormatBidMessage(message.body)
      [] message.tag = ComplexTopOfMarketBestBidOrOfferWideFormatOfferMessageCode -> EncodeComplexTopOfMarketBestBidOrOfferWideFormatOfferMessage(message.body)
      [] message.tag = ComplexDoubleSidedTopOfMarketBestBidAndOfferCompactFormatMessageCode -> EncodeComplexDoubleSidedTopOfMarketBestBidAndOfferCompactFormatMessage(message.body)
      [] message.tag = ComplexDoubleSidedTopOfMarketBestBidAndOfferWideFormatMessageCode -> EncodeComplexDoubleSidedTopOfMarketBestBidAndOfferWideFormatMessage(message.body)
      [] message.tag = StrategyLastSaleMessageCode -> EncodeStrategyLastSaleMessage(message.body)
      [] message.tag = UnderlyingTradingStatusNotificationMessageCode -> EncodeUnderlyingTradingStatusNotificationMessage(message.body)

DecodeData(tag, bytes) ==
    LET read ==
            CASE tag = SystemTimeMessageCode -> DecodeSystemTimeMessage(bytes)
              [] tag = SimpleSeriesUpdateMessageCode -> DecodeSimpleSeriesUpdateMessage(bytes)
              [] tag = ComplexStrategyDefinitionMessageCode -> DecodeComplexStrategyDefinitionMessage(bytes)
              [] tag = SystemStateMessageCode -> DecodeSystemStateMessage(bytes)
              [] tag = ComplexTopOfMarketBestBidOrOfferCompactFormatBidMessageCode -> DecodeComplexTopOfMarketBestBidOrOfferCompactFormatBidMessage(bytes)
              [] tag = ComplexTopOfMarketBestBidOrOfferCompactFormatOfferMessageCode -> DecodeComplexTopOfMarketBestBidOrOfferCompactFormatOfferMessage(bytes)
              [] tag = ComplexTopOfMarketBestBidOrOfferWideFormatBidMessageCode -> DecodeComplexTopOfMarketBestBidOrOfferWideFormatBidMessage(bytes)
              [] tag = ComplexTopOfMarketBestBidOrOfferWideFormatOfferMessageCode -> DecodeComplexTopOfMarketBestBidOrOfferWideFormatOfferMessage(bytes)
              [] tag = ComplexDoubleSidedTopOfMarketBestBidAndOfferCompactFormatMessageCode -> DecodeComplexDoubleSidedTopOfMarketBestBidAndOfferCompactFormatMessage(bytes)
              [] tag = ComplexDoubleSidedTopOfMarketBestBidAndOfferWideFormatMessageCode -> DecodeComplexDoubleSidedTopOfMarketBestBidAndOfferWideFormatMessage(bytes)
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
        \cup { [tag |-> ComplexTopOfMarketBestBidOrOfferCompactFormatBidMessageCode, body |-> one] : one \in CheckedComplexTopOfMarketBestBidOrOfferCompactFormatBidMessage }
        \cup { [tag |-> ComplexTopOfMarketBestBidOrOfferCompactFormatOfferMessageCode, body |-> one] : one \in CheckedComplexTopOfMarketBestBidOrOfferCompactFormatOfferMessage }
        \cup { [tag |-> ComplexTopOfMarketBestBidOrOfferWideFormatBidMessageCode, body |-> one] : one \in CheckedComplexTopOfMarketBestBidOrOfferWideFormatBidMessage }
        \cup { [tag |-> ComplexTopOfMarketBestBidOrOfferWideFormatOfferMessageCode, body |-> one] : one \in CheckedComplexTopOfMarketBestBidOrOfferWideFormatOfferMessage }
        \cup { [tag |-> ComplexDoubleSidedTopOfMarketBestBidAndOfferCompactFormatMessageCode, body |-> one] : one \in CheckedComplexDoubleSidedTopOfMarketBestBidAndOfferCompactFormatMessage }
        \cup { [tag |-> ComplexDoubleSidedTopOfMarketBestBidAndOfferWideFormatMessageCode, body |-> one] : one \in CheckedComplexDoubleSidedTopOfMarketBestBidAndOfferWideFormatMessage }
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

(* Every Complex Top Of Market Best Bid Or Offer Compact Format Bid Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexTopOfMarketBestBidOrOfferCompactFormatBidMessage ==
    \A message \in CheckedComplexTopOfMarketBestBidOrOfferCompactFormatBidMessage :
        LET read == DecodeComplexTopOfMarketBestBidOrOfferCompactFormatBidMessage(EncodeComplexTopOfMarketBestBidOrOfferCompactFormatBidMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Top Of Market Best Bid Or Offer Compact Format Offer Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexTopOfMarketBestBidOrOfferCompactFormatOfferMessage ==
    \A message \in CheckedComplexTopOfMarketBestBidOrOfferCompactFormatOfferMessage :
        LET read == DecodeComplexTopOfMarketBestBidOrOfferCompactFormatOfferMessage(EncodeComplexTopOfMarketBestBidOrOfferCompactFormatOfferMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Top Of Market Best Bid Or Offer Wide Format Bid Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexTopOfMarketBestBidOrOfferWideFormatBidMessage ==
    \A message \in CheckedComplexTopOfMarketBestBidOrOfferWideFormatBidMessage :
        LET read == DecodeComplexTopOfMarketBestBidOrOfferWideFormatBidMessage(EncodeComplexTopOfMarketBestBidOrOfferWideFormatBidMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Top Of Market Best Bid Or Offer Wide Format Offer Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexTopOfMarketBestBidOrOfferWideFormatOfferMessage ==
    \A message \in CheckedComplexTopOfMarketBestBidOrOfferWideFormatOfferMessage :
        LET read == DecodeComplexTopOfMarketBestBidOrOfferWideFormatOfferMessage(EncodeComplexTopOfMarketBestBidOrOfferWideFormatOfferMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Double Sided Top Of Market Best Bid And Offer Compact Format Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexDoubleSidedTopOfMarketBestBidAndOfferCompactFormatMessage ==
    \A message \in CheckedComplexDoubleSidedTopOfMarketBestBidAndOfferCompactFormatMessage :
        LET read == DecodeComplexDoubleSidedTopOfMarketBestBidAndOfferCompactFormatMessage(EncodeComplexDoubleSidedTopOfMarketBestBidAndOfferCompactFormatMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Double Sided Top Of Market Best Bid And Offer Wide Format Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexDoubleSidedTopOfMarketBestBidAndOfferWideFormatMessage ==
    \A message \in CheckedComplexDoubleSidedTopOfMarketBestBidAndOfferWideFormatMessage :
        LET read == DecodeComplexDoubleSidedTopOfMarketBestBidAndOfferWideFormatMessage(EncodeComplexDoubleSidedTopOfMarketBestBidAndOfferWideFormatMessage(message))
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
