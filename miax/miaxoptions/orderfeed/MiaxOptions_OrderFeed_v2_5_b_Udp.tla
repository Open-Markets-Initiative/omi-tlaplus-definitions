----------------- MODULE MiaxOptions_OrderFeed_v2_5_b_Udp ------------------
(***************************************************************************)
(* Miami International Holdings Order Feed v2.5.b                          *)
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
(* System State Message: 17 bytes                                          *)
(***************************************************************************)

SystemStateMessage ==
    [ nanoseconds  : Sample(4),
      morVersion   : Sample(8),
      sessionId    : Sample(4),
      systemStatus : Sample(1) ]

EncodeSystemStateMessage(message) ==
    message.nanoseconds
        \o message.morVersion
        \o message.sessionId
        \o message.systemStatus

DecodeSystemStateMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET morVersion == ReadBytes(nanoseconds.rest, 8) IN IF ~morVersion.ok THEN Fail ELSE
    LET sessionId == ReadBytes(morVersion.rest, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET systemStatus == ReadBytes(sessionId.rest, 1) IN IF ~systemStatus.ok THEN Fail ELSE
    Ok([ nanoseconds  |-> nanoseconds.value,
         morVersion   |-> morVersion.value,
         sessionId    |-> sessionId.value,
         systemStatus |-> systemStatus.value ], systemStatus.rest)

ZeroSystemStateMessage ==
    [ nanoseconds  |-> [i \in 1 .. 4 |-> 0],
      morVersion   |-> [i \in 1 .. 8 |-> 0],
      sessionId    |-> [i \in 1 .. 4 |-> 0],
      systemStatus |-> [i \in 1 .. 1 |-> 0] ]

(* System State Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemStateMessage ==
    { ZeroSystemStateMessage }
        \cup { [ZeroSystemStateMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSystemStateMessage EXCEPT !.morVersion = one] : one \in Sample(8) }
        \cup { [ZeroSystemStateMessage EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroSystemStateMessage EXCEPT !.systemStatus = one] : one \in Sample(1) }

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
(* Simple Order Message: 71 bytes                                          *)
(***************************************************************************)

SimpleOrderMessage ==
    [ nanoseconds            : Sample(4),
      action                 : Sample(1),
      productId              : Sample(4),
      orderId                : Sample(8),
      orderSide              : Sample(1),
      orderType              : Sample(1),
      orderPriceShort        : Sample(4),
      orderOriginalVolume    : Sample(4),
      remainingVolumeOpen    : Sample(4),
      timeInForceTif         : Sample(1),
      origin                 : Sample(1),
      opencloseIndicator     : Sample(1),
      routeInstruction       : Sample(1),
      attributedId           : Sample(4),
      priorityCustomerVolume : Sample(4),
      reserved28             : Sample(28) ]

EncodeSimpleOrderMessage(message) ==
    message.nanoseconds
        \o message.action
        \o message.productId
        \o message.orderId
        \o message.orderSide
        \o message.orderType
        \o message.orderPriceShort
        \o message.orderOriginalVolume
        \o message.remainingVolumeOpen
        \o message.timeInForceTif
        \o message.origin
        \o message.opencloseIndicator
        \o message.routeInstruction
        \o message.attributedId
        \o message.priorityCustomerVolume
        \o message.reserved28

DecodeSimpleOrderMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET action == ReadBytes(nanoseconds.rest, 1) IN IF ~action.ok THEN Fail ELSE
    LET productId == ReadBytes(action.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET orderId == ReadBytes(productId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET orderSide == ReadBytes(orderId.rest, 1) IN IF ~orderSide.ok THEN Fail ELSE
    LET orderType == ReadBytes(orderSide.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET orderPriceShort == ReadBytes(orderType.rest, 4) IN IF ~orderPriceShort.ok THEN Fail ELSE
    LET orderOriginalVolume == ReadBytes(orderPriceShort.rest, 4) IN IF ~orderOriginalVolume.ok THEN Fail ELSE
    LET remainingVolumeOpen == ReadBytes(orderOriginalVolume.rest, 4) IN IF ~remainingVolumeOpen.ok THEN Fail ELSE
    LET timeInForceTif == ReadBytes(remainingVolumeOpen.rest, 1) IN IF ~timeInForceTif.ok THEN Fail ELSE
    LET origin == ReadBytes(timeInForceTif.rest, 1) IN IF ~origin.ok THEN Fail ELSE
    LET opencloseIndicator == ReadBytes(origin.rest, 1) IN IF ~opencloseIndicator.ok THEN Fail ELSE
    LET routeInstruction == ReadBytes(opencloseIndicator.rest, 1) IN IF ~routeInstruction.ok THEN Fail ELSE
    LET attributedId == ReadBytes(routeInstruction.rest, 4) IN IF ~attributedId.ok THEN Fail ELSE
    LET priorityCustomerVolume == ReadBytes(attributedId.rest, 4) IN IF ~priorityCustomerVolume.ok THEN Fail ELSE
    LET reserved28 == ReadBytes(priorityCustomerVolume.rest, 28) IN IF ~reserved28.ok THEN Fail ELSE
    Ok([ nanoseconds            |-> nanoseconds.value,
         action                 |-> action.value,
         productId              |-> productId.value,
         orderId                |-> orderId.value,
         orderSide              |-> orderSide.value,
         orderType              |-> orderType.value,
         orderPriceShort        |-> orderPriceShort.value,
         orderOriginalVolume    |-> orderOriginalVolume.value,
         remainingVolumeOpen    |-> remainingVolumeOpen.value,
         timeInForceTif         |-> timeInForceTif.value,
         origin                 |-> origin.value,
         opencloseIndicator     |-> opencloseIndicator.value,
         routeInstruction       |-> routeInstruction.value,
         attributedId           |-> attributedId.value,
         priorityCustomerVolume |-> priorityCustomerVolume.value,
         reserved28             |-> reserved28.value ], reserved28.rest)

ZeroSimpleOrderMessage ==
    [ nanoseconds            |-> [i \in 1 .. 4 |-> 0],
      action                 |-> [i \in 1 .. 1 |-> 0],
      productId              |-> [i \in 1 .. 4 |-> 0],
      orderId                |-> [i \in 1 .. 8 |-> 0],
      orderSide              |-> [i \in 1 .. 1 |-> 0],
      orderType              |-> [i \in 1 .. 1 |-> 0],
      orderPriceShort        |-> [i \in 1 .. 4 |-> 0],
      orderOriginalVolume    |-> [i \in 1 .. 4 |-> 0],
      remainingVolumeOpen    |-> [i \in 1 .. 4 |-> 0],
      timeInForceTif         |-> [i \in 1 .. 1 |-> 0],
      origin                 |-> [i \in 1 .. 1 |-> 0],
      opencloseIndicator     |-> [i \in 1 .. 1 |-> 0],
      routeInstruction       |-> [i \in 1 .. 1 |-> 0],
      attributedId           |-> [i \in 1 .. 4 |-> 0],
      priorityCustomerVolume |-> [i \in 1 .. 4 |-> 0],
      reserved28             |-> [i \in 1 .. 28 |-> 0] ]

(* Simple Order Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleOrderMessage ==
    { ZeroSimpleOrderMessage }
        \cup { [ZeroSimpleOrderMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSimpleOrderMessage EXCEPT !.action = one] : one \in Sample(1) }
        \cup { [ZeroSimpleOrderMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroSimpleOrderMessage EXCEPT !.orderSide = one] : one \in Sample(1) }
        \cup { [ZeroSimpleOrderMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroSimpleOrderMessage EXCEPT !.orderPriceShort = one] : one \in Sample(4) }
        \cup { [ZeroSimpleOrderMessage EXCEPT !.orderOriginalVolume = one] : one \in Sample(4) }
        \cup { [ZeroSimpleOrderMessage EXCEPT !.remainingVolumeOpen = one] : one \in Sample(4) }
        \cup { [ZeroSimpleOrderMessage EXCEPT !.timeInForceTif = one] : one \in Sample(1) }
        \cup { [ZeroSimpleOrderMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroSimpleOrderMessage EXCEPT !.opencloseIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSimpleOrderMessage EXCEPT !.routeInstruction = one] : one \in Sample(1) }
        \cup { [ZeroSimpleOrderMessage EXCEPT !.attributedId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleOrderMessage EXCEPT !.priorityCustomerVolume = one] : one \in Sample(4) }
        \cup { [ZeroSimpleOrderMessage EXCEPT !.reserved28 = one] : one \in Sample(28) }

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
(* Complex Order Message: 69 bytes                                         *)
(***************************************************************************)

ComplexOrderMessage ==
    [ nanoseconds         : Sample(4),
      action              : Sample(1),
      strategyId          : Sample(4),
      orderId             : Sample(8),
      orderSide           : Sample(1),
      orderType           : Sample(1),
      orderPriceLong      : Sample(8),
      orderOriginalVolume : Sample(4),
      remainingVolumeOpen : Sample(4),
      timeInForceTif      : Sample(1),
      origin              : Sample(1),
      attributedId        : Sample(4),
      reserved28          : Sample(28) ]

EncodeComplexOrderMessage(message) ==
    message.nanoseconds
        \o message.action
        \o message.strategyId
        \o message.orderId
        \o message.orderSide
        \o message.orderType
        \o message.orderPriceLong
        \o message.orderOriginalVolume
        \o message.remainingVolumeOpen
        \o message.timeInForceTif
        \o message.origin
        \o message.attributedId
        \o message.reserved28

DecodeComplexOrderMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET action == ReadBytes(nanoseconds.rest, 1) IN IF ~action.ok THEN Fail ELSE
    LET strategyId == ReadBytes(action.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET orderId == ReadBytes(strategyId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET orderSide == ReadBytes(orderId.rest, 1) IN IF ~orderSide.ok THEN Fail ELSE
    LET orderType == ReadBytes(orderSide.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET orderPriceLong == ReadBytes(orderType.rest, 8) IN IF ~orderPriceLong.ok THEN Fail ELSE
    LET orderOriginalVolume == ReadBytes(orderPriceLong.rest, 4) IN IF ~orderOriginalVolume.ok THEN Fail ELSE
    LET remainingVolumeOpen == ReadBytes(orderOriginalVolume.rest, 4) IN IF ~remainingVolumeOpen.ok THEN Fail ELSE
    LET timeInForceTif == ReadBytes(remainingVolumeOpen.rest, 1) IN IF ~timeInForceTif.ok THEN Fail ELSE
    LET origin == ReadBytes(timeInForceTif.rest, 1) IN IF ~origin.ok THEN Fail ELSE
    LET attributedId == ReadBytes(origin.rest, 4) IN IF ~attributedId.ok THEN Fail ELSE
    LET reserved28 == ReadBytes(attributedId.rest, 28) IN IF ~reserved28.ok THEN Fail ELSE
    Ok([ nanoseconds         |-> nanoseconds.value,
         action              |-> action.value,
         strategyId          |-> strategyId.value,
         orderId             |-> orderId.value,
         orderSide           |-> orderSide.value,
         orderType           |-> orderType.value,
         orderPriceLong      |-> orderPriceLong.value,
         orderOriginalVolume |-> orderOriginalVolume.value,
         remainingVolumeOpen |-> remainingVolumeOpen.value,
         timeInForceTif      |-> timeInForceTif.value,
         origin              |-> origin.value,
         attributedId        |-> attributedId.value,
         reserved28          |-> reserved28.value ], reserved28.rest)

ZeroComplexOrderMessage ==
    [ nanoseconds         |-> [i \in 1 .. 4 |-> 0],
      action              |-> [i \in 1 .. 1 |-> 0],
      strategyId          |-> [i \in 1 .. 4 |-> 0],
      orderId             |-> [i \in 1 .. 8 |-> 0],
      orderSide           |-> [i \in 1 .. 1 |-> 0],
      orderType           |-> [i \in 1 .. 1 |-> 0],
      orderPriceLong      |-> [i \in 1 .. 8 |-> 0],
      orderOriginalVolume |-> [i \in 1 .. 4 |-> 0],
      remainingVolumeOpen |-> [i \in 1 .. 4 |-> 0],
      timeInForceTif      |-> [i \in 1 .. 1 |-> 0],
      origin              |-> [i \in 1 .. 1 |-> 0],
      attributedId        |-> [i \in 1 .. 4 |-> 0],
      reserved28          |-> [i \in 1 .. 28 |-> 0] ]

(* Complex Order Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexOrderMessage ==
    { ZeroComplexOrderMessage }
        \cup { [ZeroComplexOrderMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroComplexOrderMessage EXCEPT !.action = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroComplexOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroComplexOrderMessage EXCEPT !.orderSide = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderMessage EXCEPT !.orderPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroComplexOrderMessage EXCEPT !.orderOriginalVolume = one] : one \in Sample(4) }
        \cup { [ZeroComplexOrderMessage EXCEPT !.remainingVolumeOpen = one] : one \in Sample(4) }
        \cup { [ZeroComplexOrderMessage EXCEPT !.timeInForceTif = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderMessage EXCEPT !.attributedId = one] : one \in Sample(4) }
        \cup { [ZeroComplexOrderMessage EXCEPT !.reserved28 = one] : one \in Sample(28) }

(***************************************************************************)
(* Order Close Message: 13 bytes                                           *)
(***************************************************************************)

OrderCloseMessage ==
    [ nanoseconds          : Sample(4),
      simpleOrComplexOrder : Sample(1),
      orderId              : Sample(8) ]

EncodeOrderCloseMessage(message) ==
    message.nanoseconds
        \o message.simpleOrComplexOrder
        \o message.orderId

DecodeOrderCloseMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET simpleOrComplexOrder == ReadBytes(nanoseconds.rest, 1) IN IF ~simpleOrComplexOrder.ok THEN Fail ELSE
    LET orderId == ReadBytes(simpleOrComplexOrder.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    Ok([ nanoseconds          |-> nanoseconds.value,
         simpleOrComplexOrder |-> simpleOrComplexOrder.value,
         orderId              |-> orderId.value ], orderId.rest)

ZeroOrderCloseMessage ==
    [ nanoseconds          |-> [i \in 1 .. 4 |-> 0],
      simpleOrComplexOrder |-> [i \in 1 .. 1 |-> 0],
      orderId              |-> [i \in 1 .. 8 |-> 0] ]

(* Order Close Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCloseMessage ==
    { ZeroOrderCloseMessage }
        \cup { [ZeroOrderCloseMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderCloseMessage EXCEPT !.simpleOrComplexOrder = one] : one \in Sample(1) }
        \cup { [ZeroOrderCloseMessage EXCEPT !.orderId = one] : one \in Sample(8) }

(***************************************************************************)
(* Data, selected by Message Type                                          *)
(***************************************************************************)

SystemTimeMessageCode == 49  \* "1"
SimpleSeriesUpdateMessageCode == 80  \* "P"
SystemStateMessageCode == 83  \* "S"
UnderlyingTradingStatusNotificationMessageCode == 72  \* "H"
SimpleOrderMessageCode == 70  \* "F"
ComplexStrategyDefinitionUpdateMessageCode == 67  \* "C"
ComplexOrderMessageCode == 82  \* "R"
OrderCloseMessageCode == 120  \* "x"

Data ==
    [ tag : {SystemTimeMessageCode}, body : SystemTimeMessage ]
        \cup [ tag : {SimpleSeriesUpdateMessageCode}, body : SimpleSeriesUpdateMessage ]
        \cup [ tag : {SystemStateMessageCode}, body : SystemStateMessage ]
        \cup [ tag : {UnderlyingTradingStatusNotificationMessageCode}, body : UnderlyingTradingStatusNotificationMessage ]
        \cup [ tag : {SimpleOrderMessageCode}, body : SimpleOrderMessage ]
        \cup [ tag : {ComplexStrategyDefinitionUpdateMessageCode}, body : ComplexStrategyDefinitionUpdateMessage ]
        \cup [ tag : {ComplexOrderMessageCode}, body : ComplexOrderMessage ]
        \cup [ tag : {OrderCloseMessageCode}, body : OrderCloseMessage ]

EncodeData(message) ==
    CASE message.tag = SystemTimeMessageCode -> EncodeSystemTimeMessage(message.body)
      [] message.tag = SimpleSeriesUpdateMessageCode -> EncodeSimpleSeriesUpdateMessage(message.body)
      [] message.tag = SystemStateMessageCode -> EncodeSystemStateMessage(message.body)
      [] message.tag = UnderlyingTradingStatusNotificationMessageCode -> EncodeUnderlyingTradingStatusNotificationMessage(message.body)
      [] message.tag = SimpleOrderMessageCode -> EncodeSimpleOrderMessage(message.body)
      [] message.tag = ComplexStrategyDefinitionUpdateMessageCode -> EncodeComplexStrategyDefinitionUpdateMessage(message.body)
      [] message.tag = ComplexOrderMessageCode -> EncodeComplexOrderMessage(message.body)
      [] message.tag = OrderCloseMessageCode -> EncodeOrderCloseMessage(message.body)

DecodeData(tag, bytes) ==
    LET read ==
            CASE tag = SystemTimeMessageCode -> DecodeSystemTimeMessage(bytes)
              [] tag = SimpleSeriesUpdateMessageCode -> DecodeSimpleSeriesUpdateMessage(bytes)
              [] tag = SystemStateMessageCode -> DecodeSystemStateMessage(bytes)
              [] tag = UnderlyingTradingStatusNotificationMessageCode -> DecodeUnderlyingTradingStatusNotificationMessage(bytes)
              [] tag = SimpleOrderMessageCode -> DecodeSimpleOrderMessage(bytes)
              [] tag = ComplexStrategyDefinitionUpdateMessageCode -> DecodeComplexStrategyDefinitionUpdateMessage(bytes)
              [] tag = ComplexOrderMessageCode -> DecodeComplexOrderMessage(bytes)
              [] tag = OrderCloseMessageCode -> DecodeOrderCloseMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroData == [tag |-> SystemTimeMessageCode, body |-> ZeroSystemTimeMessage]

(* Each Data in turn, at the values the message it names is checked at *)
CheckedData ==
    { [tag |-> SystemTimeMessageCode, body |-> one] : one \in CheckedSystemTimeMessage }
        \cup { [tag |-> SimpleSeriesUpdateMessageCode, body |-> one] : one \in CheckedSimpleSeriesUpdateMessage }
        \cup { [tag |-> SystemStateMessageCode, body |-> one] : one \in CheckedSystemStateMessage }
        \cup { [tag |-> UnderlyingTradingStatusNotificationMessageCode, body |-> one] : one \in CheckedUnderlyingTradingStatusNotificationMessage }
        \cup { [tag |-> SimpleOrderMessageCode, body |-> one] : one \in CheckedSimpleOrderMessage }
        \cup { [tag |-> ComplexStrategyDefinitionUpdateMessageCode, body |-> one] : one \in CheckedComplexStrategyDefinitionUpdateMessage }
        \cup { [tag |-> ComplexOrderMessageCode, body |-> one] : one \in CheckedComplexOrderMessage }
        \cup { [tag |-> OrderCloseMessageCode, body |-> one] : one \in CheckedOrderCloseMessage }

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

(* Every System State Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSystemStateMessage ==
    \A message \in CheckedSystemStateMessage :
        LET read == DecodeSystemStateMessage(EncodeSystemStateMessage(message))
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

(* Every Simple Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleOrderMessage ==
    \A message \in CheckedSimpleOrderMessage :
        LET read == DecodeSimpleOrderMessage(EncodeSimpleOrderMessage(message))
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

(* Every Complex Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexOrderMessage ==
    \A message \in CheckedComplexOrderMessage :
        LET read == DecodeComplexOrderMessage(EncodeComplexOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Close Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCloseMessage ==
    \A message \in CheckedOrderCloseMessage :
        LET read == DecodeOrderCloseMessage(EncodeOrderCloseMessage(message))
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
