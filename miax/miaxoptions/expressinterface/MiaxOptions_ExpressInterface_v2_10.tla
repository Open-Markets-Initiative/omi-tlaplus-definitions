---------------- MODULE MiaxOptions_ExpressInterface_v2_10 -----------------
(***************************************************************************)
(* Miami International Holdings Express Interface v2.10                    *)
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
(* Note: Unsequenced Data Packet fills what is left of the frame Sesm      *)
(* Packet Length states, which is what it is read from.                    *)
(*                                                                         *)
(* Note: a Sesm Tcp Packet that ends the session is the last of its        *)
(* Packet: nothing may follow it.                                          *)
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
(* Simple Series Update: 76 bytes                                          *)
(***************************************************************************)

SimpleSeriesUpdate ==
    [ productAddUpdateTime              : Sample(8),
      productId                         : Sample(4),
      underlyingSymbol                  : Sample(11),
      securitySymbol                    : Sample(6),
      expirationDate                    : Sample(8),
      strikePrice                       : Sample(4),
      callOrPut                         : Sample(1),
      openingTime                       : Sample(8),
      closingTime                       : Sample(8),
      restrictedOption                  : Sample(1),
      longTermOption                    : Sample(1),
      activeOnMiax                      : Sample(1),
      miaxBboPostingIncrementIndicator  : Sample(1),
      quoteAcceptanceIncrementIndicator : Sample(1),
      openingUnderlyingMarketCode       : Sample(1),
      priorityQuoteWidth                : Sample(4),
      reserved8                         : Sample(8) ]

EncodeSimpleSeriesUpdate(message) ==
    message.productAddUpdateTime
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
        \o message.quoteAcceptanceIncrementIndicator
        \o message.openingUnderlyingMarketCode
        \o message.priorityQuoteWidth
        \o message.reserved8

DecodeSimpleSeriesUpdate(bytes) ==
    LET productAddUpdateTime == ReadBytes(bytes, 8) IN IF ~productAddUpdateTime.ok THEN Fail ELSE
    LET productId == ReadBytes(productAddUpdateTime.rest, 4) IN IF ~productId.ok THEN Fail ELSE
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
    LET quoteAcceptanceIncrementIndicator == ReadBytes(miaxBboPostingIncrementIndicator.rest, 1) IN IF ~quoteAcceptanceIncrementIndicator.ok THEN Fail ELSE
    LET openingUnderlyingMarketCode == ReadBytes(quoteAcceptanceIncrementIndicator.rest, 1) IN IF ~openingUnderlyingMarketCode.ok THEN Fail ELSE
    LET priorityQuoteWidth == ReadBytes(openingUnderlyingMarketCode.rest, 4) IN IF ~priorityQuoteWidth.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(priorityQuoteWidth.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    Ok([ productAddUpdateTime              |-> productAddUpdateTime.value,
         productId                         |-> productId.value,
         underlyingSymbol                  |-> underlyingSymbol.value,
         securitySymbol                    |-> securitySymbol.value,
         expirationDate                    |-> expirationDate.value,
         strikePrice                       |-> strikePrice.value,
         callOrPut                         |-> callOrPut.value,
         openingTime                       |-> openingTime.value,
         closingTime                       |-> closingTime.value,
         restrictedOption                  |-> restrictedOption.value,
         longTermOption                    |-> longTermOption.value,
         activeOnMiax                      |-> activeOnMiax.value,
         miaxBboPostingIncrementIndicator  |-> miaxBboPostingIncrementIndicator.value,
         quoteAcceptanceIncrementIndicator |-> quoteAcceptanceIncrementIndicator.value,
         openingUnderlyingMarketCode       |-> openingUnderlyingMarketCode.value,
         priorityQuoteWidth                |-> priorityQuoteWidth.value,
         reserved8                         |-> reserved8.value ], reserved8.rest)

ZeroSimpleSeriesUpdate ==
    [ productAddUpdateTime              |-> [i \in 1 .. 8 |-> 0],
      productId                         |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbol                  |-> [i \in 1 .. 11 |-> 0],
      securitySymbol                    |-> [i \in 1 .. 6 |-> 0],
      expirationDate                    |-> [i \in 1 .. 8 |-> 0],
      strikePrice                       |-> [i \in 1 .. 4 |-> 0],
      callOrPut                         |-> [i \in 1 .. 1 |-> 0],
      openingTime                       |-> [i \in 1 .. 8 |-> 0],
      closingTime                       |-> [i \in 1 .. 8 |-> 0],
      restrictedOption                  |-> [i \in 1 .. 1 |-> 0],
      longTermOption                    |-> [i \in 1 .. 1 |-> 0],
      activeOnMiax                      |-> [i \in 1 .. 1 |-> 0],
      miaxBboPostingIncrementIndicator  |-> [i \in 1 .. 1 |-> 0],
      quoteAcceptanceIncrementIndicator |-> [i \in 1 .. 1 |-> 0],
      openingUnderlyingMarketCode       |-> [i \in 1 .. 1 |-> 0],
      priorityQuoteWidth                |-> [i \in 1 .. 4 |-> 0],
      reserved8                         |-> [i \in 1 .. 8 |-> 0] ]

(* Simple Series Update at zero, then each field in turn at the values it is checked at *)
CheckedSimpleSeriesUpdate ==
    { ZeroSimpleSeriesUpdate }
        \cup { [ZeroSimpleSeriesUpdate EXCEPT !.productAddUpdateTime = one] : one \in Sample(8) }
        \cup { [ZeroSimpleSeriesUpdate EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleSeriesUpdate EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }
        \cup { [ZeroSimpleSeriesUpdate EXCEPT !.securitySymbol = one] : one \in Sample(6) }
        \cup { [ZeroSimpleSeriesUpdate EXCEPT !.expirationDate = one] : one \in Sample(8) }
        \cup { [ZeroSimpleSeriesUpdate EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroSimpleSeriesUpdate EXCEPT !.callOrPut = one] : one \in Sample(1) }
        \cup { [ZeroSimpleSeriesUpdate EXCEPT !.openingTime = one] : one \in Sample(8) }
        \cup { [ZeroSimpleSeriesUpdate EXCEPT !.closingTime = one] : one \in Sample(8) }
        \cup { [ZeroSimpleSeriesUpdate EXCEPT !.restrictedOption = one] : one \in Sample(1) }
        \cup { [ZeroSimpleSeriesUpdate EXCEPT !.longTermOption = one] : one \in Sample(1) }
        \cup { [ZeroSimpleSeriesUpdate EXCEPT !.activeOnMiax = one] : one \in Sample(1) }
        \cup { [ZeroSimpleSeriesUpdate EXCEPT !.miaxBboPostingIncrementIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSimpleSeriesUpdate EXCEPT !.quoteAcceptanceIncrementIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSimpleSeriesUpdate EXCEPT !.openingUnderlyingMarketCode = one] : one \in Sample(1) }
        \cup { [ZeroSimpleSeriesUpdate EXCEPT !.priorityQuoteWidth = one] : one \in Sample(4) }
        \cup { [ZeroSimpleSeriesUpdate EXCEPT !.reserved8 = one] : one \in Sample(8) }

(***************************************************************************)
(* Valid Quote Width For Opening: 21 bytes                                 *)
(***************************************************************************)

ValidQuoteWidthForOpening ==
    [ notificationTime         : Sample(8),
      mpvClass                 : Sample(1),
      lowEndOfApplicableRange  : Sample(4),
      maximumQuoteWidth        : Sample(4),
      longTermOptionMultiplier : Sample(4) ]

EncodeValidQuoteWidthForOpening(message) ==
    message.notificationTime
        \o message.mpvClass
        \o message.lowEndOfApplicableRange
        \o message.maximumQuoteWidth
        \o message.longTermOptionMultiplier

DecodeValidQuoteWidthForOpening(bytes) ==
    LET notificationTime == ReadBytes(bytes, 8) IN IF ~notificationTime.ok THEN Fail ELSE
    LET mpvClass == ReadBytes(notificationTime.rest, 1) IN IF ~mpvClass.ok THEN Fail ELSE
    LET lowEndOfApplicableRange == ReadBytes(mpvClass.rest, 4) IN IF ~lowEndOfApplicableRange.ok THEN Fail ELSE
    LET maximumQuoteWidth == ReadBytes(lowEndOfApplicableRange.rest, 4) IN IF ~maximumQuoteWidth.ok THEN Fail ELSE
    LET longTermOptionMultiplier == ReadBytes(maximumQuoteWidth.rest, 4) IN IF ~longTermOptionMultiplier.ok THEN Fail ELSE
    Ok([ notificationTime         |-> notificationTime.value,
         mpvClass                 |-> mpvClass.value,
         lowEndOfApplicableRange  |-> lowEndOfApplicableRange.value,
         maximumQuoteWidth        |-> maximumQuoteWidth.value,
         longTermOptionMultiplier |-> longTermOptionMultiplier.value ], longTermOptionMultiplier.rest)

ZeroValidQuoteWidthForOpening ==
    [ notificationTime         |-> [i \in 1 .. 8 |-> 0],
      mpvClass                 |-> [i \in 1 .. 1 |-> 0],
      lowEndOfApplicableRange  |-> [i \in 1 .. 4 |-> 0],
      maximumQuoteWidth        |-> [i \in 1 .. 4 |-> 0],
      longTermOptionMultiplier |-> [i \in 1 .. 4 |-> 0] ]

(* Valid Quote Width For Opening at zero, then each field in turn at the values it is checked at *)
CheckedValidQuoteWidthForOpening ==
    { ZeroValidQuoteWidthForOpening }
        \cup { [ZeroValidQuoteWidthForOpening EXCEPT !.notificationTime = one] : one \in Sample(8) }
        \cup { [ZeroValidQuoteWidthForOpening EXCEPT !.mpvClass = one] : one \in Sample(1) }
        \cup { [ZeroValidQuoteWidthForOpening EXCEPT !.lowEndOfApplicableRange = one] : one \in Sample(4) }
        \cup { [ZeroValidQuoteWidthForOpening EXCEPT !.maximumQuoteWidth = one] : one \in Sample(4) }
        \cup { [ZeroValidQuoteWidthForOpening EXCEPT !.longTermOptionMultiplier = one] : one \in Sample(4) }

(***************************************************************************)
(* Simple Enhanced Quote E Quote Response: 17 bytes                        *)
(***************************************************************************)

SimpleEnhancedQuoteEQuoteResponse ==
    [ clientMessageId     : Sample(4),
      mpid                : Sample(4),
      eQuoteId            : Sample(8),
      eQuoteRequestStatus : Sample(1) ]

EncodeSimpleEnhancedQuoteEQuoteResponse(message) ==
    message.clientMessageId
        \o message.mpid
        \o message.eQuoteId
        \o message.eQuoteRequestStatus

DecodeSimpleEnhancedQuoteEQuoteResponse(bytes) ==
    LET clientMessageId == ReadBytes(bytes, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET mpid == ReadBytes(clientMessageId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET eQuoteId == ReadBytes(mpid.rest, 8) IN IF ~eQuoteId.ok THEN Fail ELSE
    LET eQuoteRequestStatus == ReadBytes(eQuoteId.rest, 1) IN IF ~eQuoteRequestStatus.ok THEN Fail ELSE
    Ok([ clientMessageId     |-> clientMessageId.value,
         mpid                |-> mpid.value,
         eQuoteId            |-> eQuoteId.value,
         eQuoteRequestStatus |-> eQuoteRequestStatus.value ], eQuoteRequestStatus.rest)

ZeroSimpleEnhancedQuoteEQuoteResponse ==
    [ clientMessageId     |-> [i \in 1 .. 4 |-> 0],
      mpid                |-> [i \in 1 .. 4 |-> 0],
      eQuoteId            |-> [i \in 1 .. 8 |-> 0],
      eQuoteRequestStatus |-> [i \in 1 .. 1 |-> 0] ]

(* Simple Enhanced Quote E Quote Response at zero, then each field in turn at the values it is checked at *)
CheckedSimpleEnhancedQuoteEQuoteResponse ==
    { ZeroSimpleEnhancedQuoteEQuoteResponse }
        \cup { [ZeroSimpleEnhancedQuoteEQuoteResponse EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleEnhancedQuoteEQuoteResponse EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroSimpleEnhancedQuoteEQuoteResponse EXCEPT !.eQuoteId = one] : one \in Sample(8) }
        \cup { [ZeroSimpleEnhancedQuoteEQuoteResponse EXCEPT !.eQuoteRequestStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Complex Enhanced Quote E Quote Response: 17 bytes                       *)
(***************************************************************************)

ComplexEnhancedQuoteEQuoteResponse ==
    [ clientMessageId     : Sample(4),
      mpid                : Sample(4),
      eQuoteId            : Sample(8),
      eQuoteRequestStatus : Sample(1) ]

EncodeComplexEnhancedQuoteEQuoteResponse(message) ==
    message.clientMessageId
        \o message.mpid
        \o message.eQuoteId
        \o message.eQuoteRequestStatus

DecodeComplexEnhancedQuoteEQuoteResponse(bytes) ==
    LET clientMessageId == ReadBytes(bytes, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET mpid == ReadBytes(clientMessageId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET eQuoteId == ReadBytes(mpid.rest, 8) IN IF ~eQuoteId.ok THEN Fail ELSE
    LET eQuoteRequestStatus == ReadBytes(eQuoteId.rest, 1) IN IF ~eQuoteRequestStatus.ok THEN Fail ELSE
    Ok([ clientMessageId     |-> clientMessageId.value,
         mpid                |-> mpid.value,
         eQuoteId            |-> eQuoteId.value,
         eQuoteRequestStatus |-> eQuoteRequestStatus.value ], eQuoteRequestStatus.rest)

ZeroComplexEnhancedQuoteEQuoteResponse ==
    [ clientMessageId     |-> [i \in 1 .. 4 |-> 0],
      mpid                |-> [i \in 1 .. 4 |-> 0],
      eQuoteId            |-> [i \in 1 .. 8 |-> 0],
      eQuoteRequestStatus |-> [i \in 1 .. 1 |-> 0] ]

(* Complex Enhanced Quote E Quote Response at zero, then each field in turn at the values it is checked at *)
CheckedComplexEnhancedQuoteEQuoteResponse ==
    { ZeroComplexEnhancedQuoteEQuoteResponse }
        \cup { [ZeroComplexEnhancedQuoteEQuoteResponse EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroComplexEnhancedQuoteEQuoteResponse EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroComplexEnhancedQuoteEQuoteResponse EXCEPT !.eQuoteId = one] : one \in Sample(8) }
        \cup { [ZeroComplexEnhancedQuoteEQuoteResponse EXCEPT !.eQuoteRequestStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* System State Notification: 18 bytes                                     *)
(***************************************************************************)

SystemStateNotification ==
    [ notificationTime : Sample(8),
      meiVersion       : Sample(8),
      sessionId        : Sample(1),
      systemStatus     : Sample(1) ]

EncodeSystemStateNotification(message) ==
    message.notificationTime
        \o message.meiVersion
        \o message.sessionId
        \o message.systemStatus

DecodeSystemStateNotification(bytes) ==
    LET notificationTime == ReadBytes(bytes, 8) IN IF ~notificationTime.ok THEN Fail ELSE
    LET meiVersion == ReadBytes(notificationTime.rest, 8) IN IF ~meiVersion.ok THEN Fail ELSE
    LET sessionId == ReadBytes(meiVersion.rest, 1) IN IF ~sessionId.ok THEN Fail ELSE
    LET systemStatus == ReadBytes(sessionId.rest, 1) IN IF ~systemStatus.ok THEN Fail ELSE
    Ok([ notificationTime |-> notificationTime.value,
         meiVersion       |-> meiVersion.value,
         sessionId        |-> sessionId.value,
         systemStatus     |-> systemStatus.value ], systemStatus.rest)

ZeroSystemStateNotification ==
    [ notificationTime |-> [i \in 1 .. 8 |-> 0],
      meiVersion       |-> [i \in 1 .. 8 |-> 0],
      sessionId        |-> [i \in 1 .. 1 |-> 0],
      systemStatus     |-> [i \in 1 .. 1 |-> 0] ]

(* System State Notification at zero, then each field in turn at the values it is checked at *)
CheckedSystemStateNotification ==
    { ZeroSystemStateNotification }
        \cup { [ZeroSystemStateNotification EXCEPT !.notificationTime = one] : one \in Sample(8) }
        \cup { [ZeroSystemStateNotification EXCEPT !.meiVersion = one] : one \in Sample(8) }
        \cup { [ZeroSystemStateNotification EXCEPT !.sessionId = one] : one \in Sample(1) }
        \cup { [ZeroSystemStateNotification EXCEPT !.systemStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Product Trading Status Notification: 21 bytes                           *)
(***************************************************************************)

ProductTradingStatusNotification ==
    [ notificationTime  : Sample(8),
      productId         : Sample(4),
      tradingStatus     : Sample(1),
      expectedEventTime : Sample(8) ]

EncodeProductTradingStatusNotification(message) ==
    message.notificationTime
        \o message.productId
        \o message.tradingStatus
        \o message.expectedEventTime

DecodeProductTradingStatusNotification(bytes) ==
    LET notificationTime == ReadBytes(bytes, 8) IN IF ~notificationTime.ok THEN Fail ELSE
    LET productId == ReadBytes(notificationTime.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(productId.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET expectedEventTime == ReadBytes(tradingStatus.rest, 8) IN IF ~expectedEventTime.ok THEN Fail ELSE
    Ok([ notificationTime  |-> notificationTime.value,
         productId         |-> productId.value,
         tradingStatus     |-> tradingStatus.value,
         expectedEventTime |-> expectedEventTime.value ], expectedEventTime.rest)

ZeroProductTradingStatusNotification ==
    [ notificationTime  |-> [i \in 1 .. 8 |-> 0],
      productId         |-> [i \in 1 .. 4 |-> 0],
      tradingStatus     |-> [i \in 1 .. 1 |-> 0],
      expectedEventTime |-> [i \in 1 .. 8 |-> 0] ]

(* Product Trading Status Notification at zero, then each field in turn at the values it is checked at *)
CheckedProductTradingStatusNotification ==
    { ZeroProductTradingStatusNotification }
        \cup { [ZeroProductTradingStatusNotification EXCEPT !.notificationTime = one] : one \in Sample(8) }
        \cup { [ZeroProductTradingStatusNotification EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroProductTradingStatusNotification EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroProductTradingStatusNotification EXCEPT !.expectedEventTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Underlying Trading Status Notification: 29 bytes                        *)
(***************************************************************************)

UnderlyingTradingStatusNotification ==
    [ notificationTime  : Sample(8),
      underlyingSymbol  : Sample(11),
      tradingStatus     : Sample(1),
      eventReason       : Sample(1),
      expectedEventTime : Sample(8) ]

EncodeUnderlyingTradingStatusNotification(message) ==
    message.notificationTime
        \o message.underlyingSymbol
        \o message.tradingStatus
        \o message.eventReason
        \o message.expectedEventTime

DecodeUnderlyingTradingStatusNotification(bytes) ==
    LET notificationTime == ReadBytes(bytes, 8) IN IF ~notificationTime.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(notificationTime.rest, 11) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(underlyingSymbol.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET eventReason == ReadBytes(tradingStatus.rest, 1) IN IF ~eventReason.ok THEN Fail ELSE
    LET expectedEventTime == ReadBytes(eventReason.rest, 8) IN IF ~expectedEventTime.ok THEN Fail ELSE
    Ok([ notificationTime  |-> notificationTime.value,
         underlyingSymbol  |-> underlyingSymbol.value,
         tradingStatus     |-> tradingStatus.value,
         eventReason       |-> eventReason.value,
         expectedEventTime |-> expectedEventTime.value ], expectedEventTime.rest)

ZeroUnderlyingTradingStatusNotification ==
    [ notificationTime  |-> [i \in 1 .. 8 |-> 0],
      underlyingSymbol  |-> [i \in 1 .. 11 |-> 0],
      tradingStatus     |-> [i \in 1 .. 1 |-> 0],
      eventReason       |-> [i \in 1 .. 1 |-> 0],
      expectedEventTime |-> [i \in 1 .. 8 |-> 0] ]

(* Underlying Trading Status Notification at zero, then each field in turn at the values it is checked at *)
CheckedUnderlyingTradingStatusNotification ==
    { ZeroUnderlyingTradingStatusNotification }
        \cup { [ZeroUnderlyingTradingStatusNotification EXCEPT !.notificationTime = one] : one \in Sample(8) }
        \cup { [ZeroUnderlyingTradingStatusNotification EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }
        \cup { [ZeroUnderlyingTradingStatusNotification EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingTradingStatusNotification EXCEPT !.eventReason = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingTradingStatusNotification EXCEPT !.expectedEventTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Quote Width Relief Notification: 23 bytes                               *)
(***************************************************************************)

QuoteWidthReliefNotification ==
    [ notificationTime : Sample(8),
      underlyingSymbol : Sample(11),
      reliefMultiplier : Sample(4) ]

EncodeQuoteWidthReliefNotification(message) ==
    message.notificationTime
        \o message.underlyingSymbol
        \o message.reliefMultiplier

DecodeQuoteWidthReliefNotification(bytes) ==
    LET notificationTime == ReadBytes(bytes, 8) IN IF ~notificationTime.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(notificationTime.rest, 11) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET reliefMultiplier == ReadBytes(underlyingSymbol.rest, 4) IN IF ~reliefMultiplier.ok THEN Fail ELSE
    Ok([ notificationTime |-> notificationTime.value,
         underlyingSymbol |-> underlyingSymbol.value,
         reliefMultiplier |-> reliefMultiplier.value ], reliefMultiplier.rest)

ZeroQuoteWidthReliefNotification ==
    [ notificationTime |-> [i \in 1 .. 8 |-> 0],
      underlyingSymbol |-> [i \in 1 .. 11 |-> 0],
      reliefMultiplier |-> [i \in 1 .. 4 |-> 0] ]

(* Quote Width Relief Notification at zero, then each field in turn at the values it is checked at *)
CheckedQuoteWidthReliefNotification ==
    { ZeroQuoteWidthReliefNotification }
        \cup { [ZeroQuoteWidthReliefNotification EXCEPT !.notificationTime = one] : one \in Sample(8) }
        \cup { [ZeroQuoteWidthReliefNotification EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }
        \cup { [ZeroQuoteWidthReliefNotification EXCEPT !.reliefMultiplier = one] : one \in Sample(4) }

(***************************************************************************)
(* Simple Arm Protection Settings Notification: 31 bytes                   *)
(***************************************************************************)

SimpleArmProtectionSettingsNotification ==
    [ notificationTime              : Sample(8),
      mpid                          : Sample(4),
      underlyingSymbol              : Sample(11),
      allowableEngagementPercentage : Sample(4),
      countingPeriodBinaryU2        : Sample(2),
      action                        : Sample(1),
      source                        : Sample(1) ]

EncodeSimpleArmProtectionSettingsNotification(message) ==
    message.notificationTime
        \o message.mpid
        \o message.underlyingSymbol
        \o message.allowableEngagementPercentage
        \o message.countingPeriodBinaryU2
        \o message.action
        \o message.source

DecodeSimpleArmProtectionSettingsNotification(bytes) ==
    LET notificationTime == ReadBytes(bytes, 8) IN IF ~notificationTime.ok THEN Fail ELSE
    LET mpid == ReadBytes(notificationTime.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(mpid.rest, 11) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET allowableEngagementPercentage == ReadBytes(underlyingSymbol.rest, 4) IN IF ~allowableEngagementPercentage.ok THEN Fail ELSE
    LET countingPeriodBinaryU2 == ReadBytes(allowableEngagementPercentage.rest, 2) IN IF ~countingPeriodBinaryU2.ok THEN Fail ELSE
    LET action == ReadBytes(countingPeriodBinaryU2.rest, 1) IN IF ~action.ok THEN Fail ELSE
    LET source == ReadBytes(action.rest, 1) IN IF ~source.ok THEN Fail ELSE
    Ok([ notificationTime              |-> notificationTime.value,
         mpid                          |-> mpid.value,
         underlyingSymbol              |-> underlyingSymbol.value,
         allowableEngagementPercentage |-> allowableEngagementPercentage.value,
         countingPeriodBinaryU2        |-> countingPeriodBinaryU2.value,
         action                        |-> action.value,
         source                        |-> source.value ], source.rest)

ZeroSimpleArmProtectionSettingsNotification ==
    [ notificationTime              |-> [i \in 1 .. 8 |-> 0],
      mpid                          |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbol              |-> [i \in 1 .. 11 |-> 0],
      allowableEngagementPercentage |-> [i \in 1 .. 4 |-> 0],
      countingPeriodBinaryU2        |-> [i \in 1 .. 2 |-> 0],
      action                        |-> [i \in 1 .. 1 |-> 0],
      source                        |-> [i \in 1 .. 1 |-> 0] ]

(* Simple Arm Protection Settings Notification at zero, then each field in turn at the values it is checked at *)
CheckedSimpleArmProtectionSettingsNotification ==
    { ZeroSimpleArmProtectionSettingsNotification }
        \cup { [ZeroSimpleArmProtectionSettingsNotification EXCEPT !.notificationTime = one] : one \in Sample(8) }
        \cup { [ZeroSimpleArmProtectionSettingsNotification EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroSimpleArmProtectionSettingsNotification EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }
        \cup { [ZeroSimpleArmProtectionSettingsNotification EXCEPT !.allowableEngagementPercentage = one] : one \in Sample(4) }
        \cup { [ZeroSimpleArmProtectionSettingsNotification EXCEPT !.countingPeriodBinaryU2 = one] : one \in Sample(2) }
        \cup { [ZeroSimpleArmProtectionSettingsNotification EXCEPT !.action = one] : one \in Sample(1) }
        \cup { [ZeroSimpleArmProtectionSettingsNotification EXCEPT !.source = one] : one \in Sample(1) }

(***************************************************************************)
(* Arm 2 Underlying Level Protection Settings Notification: 48 bytes       *)
(***************************************************************************)

Arm2UnderlyingLevelProtectionSettingsNotification ==
    [ notificationTime          : Sample(8),
      mpid                      : Sample(4),
      action                    : Sample(1),
      underlyingSymbol          : Sample(11),
      armThresholdCountBinaryU4 : Sample(4),
      countingPeriodBinaryU4    : Sample(4),
      reserved16                : Sample(16) ]

EncodeArm2UnderlyingLevelProtectionSettingsNotification(message) ==
    message.notificationTime
        \o message.mpid
        \o message.action
        \o message.underlyingSymbol
        \o message.armThresholdCountBinaryU4
        \o message.countingPeriodBinaryU4
        \o message.reserved16

DecodeArm2UnderlyingLevelProtectionSettingsNotification(bytes) ==
    LET notificationTime == ReadBytes(bytes, 8) IN IF ~notificationTime.ok THEN Fail ELSE
    LET mpid == ReadBytes(notificationTime.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET action == ReadBytes(mpid.rest, 1) IN IF ~action.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(action.rest, 11) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET armThresholdCountBinaryU4 == ReadBytes(underlyingSymbol.rest, 4) IN IF ~armThresholdCountBinaryU4.ok THEN Fail ELSE
    LET countingPeriodBinaryU4 == ReadBytes(armThresholdCountBinaryU4.rest, 4) IN IF ~countingPeriodBinaryU4.ok THEN Fail ELSE
    LET reserved16 == ReadBytes(countingPeriodBinaryU4.rest, 16) IN IF ~reserved16.ok THEN Fail ELSE
    Ok([ notificationTime          |-> notificationTime.value,
         mpid                      |-> mpid.value,
         action                    |-> action.value,
         underlyingSymbol          |-> underlyingSymbol.value,
         armThresholdCountBinaryU4 |-> armThresholdCountBinaryU4.value,
         countingPeriodBinaryU4    |-> countingPeriodBinaryU4.value,
         reserved16                |-> reserved16.value ], reserved16.rest)

ZeroArm2UnderlyingLevelProtectionSettingsNotification ==
    [ notificationTime          |-> [i \in 1 .. 8 |-> 0],
      mpid                      |-> [i \in 1 .. 4 |-> 0],
      action                    |-> [i \in 1 .. 1 |-> 0],
      underlyingSymbol          |-> [i \in 1 .. 11 |-> 0],
      armThresholdCountBinaryU4 |-> [i \in 1 .. 4 |-> 0],
      countingPeriodBinaryU4    |-> [i \in 1 .. 4 |-> 0],
      reserved16                |-> [i \in 1 .. 16 |-> 0] ]

(* Arm 2 Underlying Level Protection Settings Notification at zero, then each field in turn at the values it is checked at *)
CheckedArm2UnderlyingLevelProtectionSettingsNotification ==
    { ZeroArm2UnderlyingLevelProtectionSettingsNotification }
        \cup { [ZeroArm2UnderlyingLevelProtectionSettingsNotification EXCEPT !.notificationTime = one] : one \in Sample(8) }
        \cup { [ZeroArm2UnderlyingLevelProtectionSettingsNotification EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroArm2UnderlyingLevelProtectionSettingsNotification EXCEPT !.action = one] : one \in Sample(1) }
        \cup { [ZeroArm2UnderlyingLevelProtectionSettingsNotification EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }
        \cup { [ZeroArm2UnderlyingLevelProtectionSettingsNotification EXCEPT !.armThresholdCountBinaryU4 = one] : one \in Sample(4) }
        \cup { [ZeroArm2UnderlyingLevelProtectionSettingsNotification EXCEPT !.countingPeriodBinaryU4 = one] : one \in Sample(4) }
        \cup { [ZeroArm2UnderlyingLevelProtectionSettingsNotification EXCEPT !.reserved16 = one] : one \in Sample(16) }

(***************************************************************************)
(* Single Side Liquidity Protection Trigger Notification: 27 bytes         *)
(***************************************************************************)

SingleSideLiquidityProtectionTriggerNotification ==
    [ notificationTime          : Sample(8),
      mpid                      : Sample(4),
      securityIdScope           : Sample(1),
      securityId                : Sample(4),
      side                      : Sample(1),
      triggeringClientMessageId : Sample(4),
      triggeringBulkQuoteIndex  : Sample(1),
      reserved4                 : Sample(4) ]

EncodeSingleSideLiquidityProtectionTriggerNotification(message) ==
    message.notificationTime
        \o message.mpid
        \o message.securityIdScope
        \o message.securityId
        \o message.side
        \o message.triggeringClientMessageId
        \o message.triggeringBulkQuoteIndex
        \o message.reserved4

DecodeSingleSideLiquidityProtectionTriggerNotification(bytes) ==
    LET notificationTime == ReadBytes(bytes, 8) IN IF ~notificationTime.ok THEN Fail ELSE
    LET mpid == ReadBytes(notificationTime.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET securityIdScope == ReadBytes(mpid.rest, 1) IN IF ~securityIdScope.ok THEN Fail ELSE
    LET securityId == ReadBytes(securityIdScope.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET side == ReadBytes(securityId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET triggeringClientMessageId == ReadBytes(side.rest, 4) IN IF ~triggeringClientMessageId.ok THEN Fail ELSE
    LET triggeringBulkQuoteIndex == ReadBytes(triggeringClientMessageId.rest, 1) IN IF ~triggeringBulkQuoteIndex.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(triggeringBulkQuoteIndex.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    Ok([ notificationTime          |-> notificationTime.value,
         mpid                      |-> mpid.value,
         securityIdScope           |-> securityIdScope.value,
         securityId                |-> securityId.value,
         side                      |-> side.value,
         triggeringClientMessageId |-> triggeringClientMessageId.value,
         triggeringBulkQuoteIndex  |-> triggeringBulkQuoteIndex.value,
         reserved4                 |-> reserved4.value ], reserved4.rest)

ZeroSingleSideLiquidityProtectionTriggerNotification ==
    [ notificationTime          |-> [i \in 1 .. 8 |-> 0],
      mpid                      |-> [i \in 1 .. 4 |-> 0],
      securityIdScope           |-> [i \in 1 .. 1 |-> 0],
      securityId                |-> [i \in 1 .. 4 |-> 0],
      side                      |-> [i \in 1 .. 1 |-> 0],
      triggeringClientMessageId |-> [i \in 1 .. 4 |-> 0],
      triggeringBulkQuoteIndex  |-> [i \in 1 .. 1 |-> 0],
      reserved4                 |-> [i \in 1 .. 4 |-> 0] ]

(* Single Side Liquidity Protection Trigger Notification at zero, then each field in turn at the values it is checked at *)
CheckedSingleSideLiquidityProtectionTriggerNotification ==
    { ZeroSingleSideLiquidityProtectionTriggerNotification }
        \cup { [ZeroSingleSideLiquidityProtectionTriggerNotification EXCEPT !.notificationTime = one] : one \in Sample(8) }
        \cup { [ZeroSingleSideLiquidityProtectionTriggerNotification EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideLiquidityProtectionTriggerNotification EXCEPT !.securityIdScope = one] : one \in Sample(1) }
        \cup { [ZeroSingleSideLiquidityProtectionTriggerNotification EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideLiquidityProtectionTriggerNotification EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroSingleSideLiquidityProtectionTriggerNotification EXCEPT !.triggeringClientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideLiquidityProtectionTriggerNotification EXCEPT !.triggeringBulkQuoteIndex = one] : one \in Sample(1) }
        \cup { [ZeroSingleSideLiquidityProtectionTriggerNotification EXCEPT !.reserved4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Arm 2 Underlying Level Protection Notification: 48 bytes                *)
(***************************************************************************)

Arm2UnderlyingLevelProtectionNotification ==
    [ notificationTime          : Sample(8),
      mpid                      : Sample(4),
      underlyingSymbol          : Sample(11),
      notificationType          : Sample(1),
      armThresholdCountBinaryU4 : Sample(4),
      countingPeriodBinaryU4    : Sample(4),
      reserved16                : Sample(16) ]

EncodeArm2UnderlyingLevelProtectionNotification(message) ==
    message.notificationTime
        \o message.mpid
        \o message.underlyingSymbol
        \o message.notificationType
        \o message.armThresholdCountBinaryU4
        \o message.countingPeriodBinaryU4
        \o message.reserved16

DecodeArm2UnderlyingLevelProtectionNotification(bytes) ==
    LET notificationTime == ReadBytes(bytes, 8) IN IF ~notificationTime.ok THEN Fail ELSE
    LET mpid == ReadBytes(notificationTime.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(mpid.rest, 11) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET notificationType == ReadBytes(underlyingSymbol.rest, 1) IN IF ~notificationType.ok THEN Fail ELSE
    LET armThresholdCountBinaryU4 == ReadBytes(notificationType.rest, 4) IN IF ~armThresholdCountBinaryU4.ok THEN Fail ELSE
    LET countingPeriodBinaryU4 == ReadBytes(armThresholdCountBinaryU4.rest, 4) IN IF ~countingPeriodBinaryU4.ok THEN Fail ELSE
    LET reserved16 == ReadBytes(countingPeriodBinaryU4.rest, 16) IN IF ~reserved16.ok THEN Fail ELSE
    Ok([ notificationTime          |-> notificationTime.value,
         mpid                      |-> mpid.value,
         underlyingSymbol          |-> underlyingSymbol.value,
         notificationType          |-> notificationType.value,
         armThresholdCountBinaryU4 |-> armThresholdCountBinaryU4.value,
         countingPeriodBinaryU4    |-> countingPeriodBinaryU4.value,
         reserved16                |-> reserved16.value ], reserved16.rest)

ZeroArm2UnderlyingLevelProtectionNotification ==
    [ notificationTime          |-> [i \in 1 .. 8 |-> 0],
      mpid                      |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbol          |-> [i \in 1 .. 11 |-> 0],
      notificationType          |-> [i \in 1 .. 1 |-> 0],
      armThresholdCountBinaryU4 |-> [i \in 1 .. 4 |-> 0],
      countingPeriodBinaryU4    |-> [i \in 1 .. 4 |-> 0],
      reserved16                |-> [i \in 1 .. 16 |-> 0] ]

(* Arm 2 Underlying Level Protection Notification at zero, then each field in turn at the values it is checked at *)
CheckedArm2UnderlyingLevelProtectionNotification ==
    { ZeroArm2UnderlyingLevelProtectionNotification }
        \cup { [ZeroArm2UnderlyingLevelProtectionNotification EXCEPT !.notificationTime = one] : one \in Sample(8) }
        \cup { [ZeroArm2UnderlyingLevelProtectionNotification EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroArm2UnderlyingLevelProtectionNotification EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }
        \cup { [ZeroArm2UnderlyingLevelProtectionNotification EXCEPT !.notificationType = one] : one \in Sample(1) }
        \cup { [ZeroArm2UnderlyingLevelProtectionNotification EXCEPT !.armThresholdCountBinaryU4 = one] : one \in Sample(4) }
        \cup { [ZeroArm2UnderlyingLevelProtectionNotification EXCEPT !.countingPeriodBinaryU4 = one] : one \in Sample(4) }
        \cup { [ZeroArm2UnderlyingLevelProtectionNotification EXCEPT !.reserved16 = one] : one \in Sample(16) }

(***************************************************************************)
(* Arm 2 Firm Level Protection Notification: 33 bytes                      *)
(***************************************************************************)

Arm2FirmLevelProtectionNotification ==
    [ notificationTime           : Sample(8),
      armThresholdCountBinary4u4 : Sample(4),
      countingPeriodBinary4u4    : Sample(4),
      notificationType           : Sample(1),
      reserved16                 : Sample(16) ]

EncodeArm2FirmLevelProtectionNotification(message) ==
    message.notificationTime
        \o message.armThresholdCountBinary4u4
        \o message.countingPeriodBinary4u4
        \o message.notificationType
        \o message.reserved16

DecodeArm2FirmLevelProtectionNotification(bytes) ==
    LET notificationTime == ReadBytes(bytes, 8) IN IF ~notificationTime.ok THEN Fail ELSE
    LET armThresholdCountBinary4u4 == ReadBytes(notificationTime.rest, 4) IN IF ~armThresholdCountBinary4u4.ok THEN Fail ELSE
    LET countingPeriodBinary4u4 == ReadBytes(armThresholdCountBinary4u4.rest, 4) IN IF ~countingPeriodBinary4u4.ok THEN Fail ELSE
    LET notificationType == ReadBytes(countingPeriodBinary4u4.rest, 1) IN IF ~notificationType.ok THEN Fail ELSE
    LET reserved16 == ReadBytes(notificationType.rest, 16) IN IF ~reserved16.ok THEN Fail ELSE
    Ok([ notificationTime           |-> notificationTime.value,
         armThresholdCountBinary4u4 |-> armThresholdCountBinary4u4.value,
         countingPeriodBinary4u4    |-> countingPeriodBinary4u4.value,
         notificationType           |-> notificationType.value,
         reserved16                 |-> reserved16.value ], reserved16.rest)

ZeroArm2FirmLevelProtectionNotification ==
    [ notificationTime           |-> [i \in 1 .. 8 |-> 0],
      armThresholdCountBinary4u4 |-> [i \in 1 .. 4 |-> 0],
      countingPeriodBinary4u4    |-> [i \in 1 .. 4 |-> 0],
      notificationType           |-> [i \in 1 .. 1 |-> 0],
      reserved16                 |-> [i \in 1 .. 16 |-> 0] ]

(* Arm 2 Firm Level Protection Notification at zero, then each field in turn at the values it is checked at *)
CheckedArm2FirmLevelProtectionNotification ==
    { ZeroArm2FirmLevelProtectionNotification }
        \cup { [ZeroArm2FirmLevelProtectionNotification EXCEPT !.notificationTime = one] : one \in Sample(8) }
        \cup { [ZeroArm2FirmLevelProtectionNotification EXCEPT !.armThresholdCountBinary4u4 = one] : one \in Sample(4) }
        \cup { [ZeroArm2FirmLevelProtectionNotification EXCEPT !.countingPeriodBinary4u4 = one] : one \in Sample(4) }
        \cup { [ZeroArm2FirmLevelProtectionNotification EXCEPT !.notificationType = one] : one \in Sample(1) }
        \cup { [ZeroArm2FirmLevelProtectionNotification EXCEPT !.reserved16 = one] : one \in Sample(16) }

(***************************************************************************)
(* Leg: 15 bytes                                                           *)
(***************************************************************************)

Leg ==
    [ productId   : Sample(4),
      legRatioQty : Sample(2),
      legSide     : Sample(1),
      reserved8   : Sample(8) ]

EncodeLeg(message) ==
    message.productId
        \o message.legRatioQty
        \o message.legSide
        \o message.reserved8

DecodeLeg(bytes) ==
    LET productId == ReadBytes(bytes, 4) IN IF ~productId.ok THEN Fail ELSE
    LET legRatioQty == ReadBytes(productId.rest, 2) IN IF ~legRatioQty.ok THEN Fail ELSE
    LET legSide == ReadBytes(legRatioQty.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(legSide.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    Ok([ productId   |-> productId.value,
         legRatioQty |-> legRatioQty.value,
         legSide     |-> legSide.value,
         reserved8   |-> reserved8.value ], reserved8.rest)

ZeroLeg ==
    [ productId   |-> [i \in 1 .. 4 |-> 0],
      legRatioQty |-> [i \in 1 .. 2 |-> 0],
      legSide     |-> [i \in 1 .. 1 |-> 0],
      reserved8   |-> [i \in 1 .. 8 |-> 0] ]

(* Leg at zero, then each field in turn at the values it is checked at *)
CheckedLeg ==
    { ZeroLeg }
        \cup { [ZeroLeg EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroLeg EXCEPT !.legRatioQty = one] : one \in Sample(2) }
        \cup { [ZeroLeg EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroLeg EXCEPT !.reserved8 = one] : one \in Sample(8) }

(* A run of Leg, written one after another *)
RECURSIVE EncodeLegList(_)
EncodeLegList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLeg(Head(messages)) \o EncodeLegList(Tail(messages))

(* As many Leg as the field that counts them says *)
RECURSIVE ReadLegList(_, _)
ReadLegList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLeg(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLegList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Leg of each kind, for the lists that carry them *)
OneLeg == { ZeroLeg }

(***************************************************************************)
(* Complex Strategy Definition Notification                                *)
(***************************************************************************)

ComplexStrategyDefinitionNotification ==
    [ notificationTime : Sample(8),
      strategyId       : Sample(4),
      underlyingSymbol : Sample(11),
      activeOnMiax     : Sample(1),
      reserved1        : Sample(1),
      updateReason     : Sample(1),
      reserved10       : Sample(10),
      leg              : SampleLists(OneLeg) ]

EncodeComplexStrategyDefinitionNotification(message) ==
    message.notificationTime
        \o message.strategyId
        \o message.underlyingSymbol
        \o message.activeOnMiax
        \o message.reserved1
        \o message.updateReason
        \o message.reserved10
        \o EncodeUIntBE(Len(message.leg), 1)
        \o EncodeLegList(message.leg)

DecodeComplexStrategyDefinitionNotification(bytes) ==
    LET notificationTime == ReadBytes(bytes, 8) IN IF ~notificationTime.ok THEN Fail ELSE
    LET strategyId == ReadBytes(notificationTime.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(strategyId.rest, 11) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET activeOnMiax == ReadBytes(underlyingSymbol.rest, 1) IN IF ~activeOnMiax.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(activeOnMiax.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET updateReason == ReadBytes(reserved1.rest, 1) IN IF ~updateReason.ok THEN Fail ELSE
    LET reserved10 == ReadBytes(updateReason.rest, 10) IN IF ~reserved10.ok THEN Fail ELSE
    LET numberOfLegs == ReadUIntBE(reserved10.rest, 1) IN IF ~numberOfLegs.ok THEN Fail ELSE
    LET leg == ReadLegList(numberOfLegs.rest, numberOfLegs.value) IN IF ~leg.ok THEN Fail ELSE
    Ok([ notificationTime |-> notificationTime.value,
         strategyId       |-> strategyId.value,
         underlyingSymbol |-> underlyingSymbol.value,
         activeOnMiax     |-> activeOnMiax.value,
         reserved1        |-> reserved1.value,
         updateReason     |-> updateReason.value,
         reserved10       |-> reserved10.value,
         leg              |-> leg.value ], leg.rest)

ZeroComplexStrategyDefinitionNotification ==
    [ notificationTime |-> [i \in 1 .. 8 |-> 0],
      strategyId       |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbol |-> [i \in 1 .. 11 |-> 0],
      activeOnMiax     |-> [i \in 1 .. 1 |-> 0],
      reserved1        |-> [i \in 1 .. 1 |-> 0],
      updateReason     |-> [i \in 1 .. 1 |-> 0],
      reserved10       |-> [i \in 1 .. 10 |-> 0],
      leg              |-> << >> ]

(* Complex Strategy Definition Notification at zero, then each field in turn at the values it is checked at *)
CheckedComplexStrategyDefinitionNotification ==
    { ZeroComplexStrategyDefinitionNotification }
        \cup { [ZeroComplexStrategyDefinitionNotification EXCEPT !.notificationTime = one] : one \in Sample(8) }
        \cup { [ZeroComplexStrategyDefinitionNotification EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroComplexStrategyDefinitionNotification EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }
        \cup { [ZeroComplexStrategyDefinitionNotification EXCEPT !.activeOnMiax = one] : one \in Sample(1) }
        \cup { [ZeroComplexStrategyDefinitionNotification EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroComplexStrategyDefinitionNotification EXCEPT !.updateReason = one] : one \in Sample(1) }
        \cup { [ZeroComplexStrategyDefinitionNotification EXCEPT !.reserved10 = one] : one \in Sample(10) }
        \cup { [ZeroComplexStrategyDefinitionNotification EXCEPT !.leg = one] : one \in SampleLists(OneLeg) }

(***************************************************************************)
(* Cancel Notification: 36 bytes                                           *)
(***************************************************************************)

CancelNotification ==
    [ notificationTime      : Sample(8),
      mpid                  : Sample(4),
      productIdOrStrategyId : Sample(4),
      liquidityType         : Sample(1),
      clientMessageId       : Sample(4),
      bulkQuoteIndex        : Sample(1),
      quoteeQuoteSide       : Sample(1),
      size                  : Sample(4),
      engineSequenceNumber  : Sample(8),
      cancelReason          : Sample(1) ]

EncodeCancelNotification(message) ==
    message.notificationTime
        \o message.mpid
        \o message.productIdOrStrategyId
        \o message.liquidityType
        \o message.clientMessageId
        \o message.bulkQuoteIndex
        \o message.quoteeQuoteSide
        \o message.size
        \o message.engineSequenceNumber
        \o message.cancelReason

DecodeCancelNotification(bytes) ==
    LET notificationTime == ReadBytes(bytes, 8) IN IF ~notificationTime.ok THEN Fail ELSE
    LET mpid == ReadBytes(notificationTime.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET productIdOrStrategyId == ReadBytes(mpid.rest, 4) IN IF ~productIdOrStrategyId.ok THEN Fail ELSE
    LET liquidityType == ReadBytes(productIdOrStrategyId.rest, 1) IN IF ~liquidityType.ok THEN Fail ELSE
    LET clientMessageId == ReadBytes(liquidityType.rest, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET bulkQuoteIndex == ReadBytes(clientMessageId.rest, 1) IN IF ~bulkQuoteIndex.ok THEN Fail ELSE
    LET quoteeQuoteSide == ReadBytes(bulkQuoteIndex.rest, 1) IN IF ~quoteeQuoteSide.ok THEN Fail ELSE
    LET size == ReadBytes(quoteeQuoteSide.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET engineSequenceNumber == ReadBytes(size.rest, 8) IN IF ~engineSequenceNumber.ok THEN Fail ELSE
    LET cancelReason == ReadBytes(engineSequenceNumber.rest, 1) IN IF ~cancelReason.ok THEN Fail ELSE
    Ok([ notificationTime      |-> notificationTime.value,
         mpid                  |-> mpid.value,
         productIdOrStrategyId |-> productIdOrStrategyId.value,
         liquidityType         |-> liquidityType.value,
         clientMessageId       |-> clientMessageId.value,
         bulkQuoteIndex        |-> bulkQuoteIndex.value,
         quoteeQuoteSide       |-> quoteeQuoteSide.value,
         size                  |-> size.value,
         engineSequenceNumber  |-> engineSequenceNumber.value,
         cancelReason          |-> cancelReason.value ], cancelReason.rest)

ZeroCancelNotification ==
    [ notificationTime      |-> [i \in 1 .. 8 |-> 0],
      mpid                  |-> [i \in 1 .. 4 |-> 0],
      productIdOrStrategyId |-> [i \in 1 .. 4 |-> 0],
      liquidityType         |-> [i \in 1 .. 1 |-> 0],
      clientMessageId       |-> [i \in 1 .. 4 |-> 0],
      bulkQuoteIndex        |-> [i \in 1 .. 1 |-> 0],
      quoteeQuoteSide       |-> [i \in 1 .. 1 |-> 0],
      size                  |-> [i \in 1 .. 4 |-> 0],
      engineSequenceNumber  |-> [i \in 1 .. 8 |-> 0],
      cancelReason          |-> [i \in 1 .. 1 |-> 0] ]

(* Cancel Notification at zero, then each field in turn at the values it is checked at *)
CheckedCancelNotification ==
    { ZeroCancelNotification }
        \cup { [ZeroCancelNotification EXCEPT !.notificationTime = one] : one \in Sample(8) }
        \cup { [ZeroCancelNotification EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroCancelNotification EXCEPT !.productIdOrStrategyId = one] : one \in Sample(4) }
        \cup { [ZeroCancelNotification EXCEPT !.liquidityType = one] : one \in Sample(1) }
        \cup { [ZeroCancelNotification EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroCancelNotification EXCEPT !.bulkQuoteIndex = one] : one \in Sample(1) }
        \cup { [ZeroCancelNotification EXCEPT !.quoteeQuoteSide = one] : one \in Sample(1) }
        \cup { [ZeroCancelNotification EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroCancelNotification EXCEPT !.engineSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroCancelNotification EXCEPT !.cancelReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Option Execution Notification: 49 bytes                                 *)
(***************************************************************************)

OptionExecutionNotification ==
    [ notificationTime : Sample(8),
      mpid             : Sample(4),
      productId        : Sample(4),
      liquidityType    : Sample(1),
      clientMessageId  : Sample(4),
      bulkQuoteIndex   : Sample(1),
      eventId          : Sample(4),
      tradeId          : Sample(4),
      executionId      : Sample(8),
      reserved1        : Sample(1),
      tradeStatus      : Sample(1),
      lastPrice        : Sample(4),
      side             : Sample(1),
      lastSize         : Sample(4) ]

EncodeOptionExecutionNotification(message) ==
    message.notificationTime
        \o message.mpid
        \o message.productId
        \o message.liquidityType
        \o message.clientMessageId
        \o message.bulkQuoteIndex
        \o message.eventId
        \o message.tradeId
        \o message.executionId
        \o message.reserved1
        \o message.tradeStatus
        \o message.lastPrice
        \o message.side
        \o message.lastSize

DecodeOptionExecutionNotification(bytes) ==
    LET notificationTime == ReadBytes(bytes, 8) IN IF ~notificationTime.ok THEN Fail ELSE
    LET mpid == ReadBytes(notificationTime.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET productId == ReadBytes(mpid.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET liquidityType == ReadBytes(productId.rest, 1) IN IF ~liquidityType.ok THEN Fail ELSE
    LET clientMessageId == ReadBytes(liquidityType.rest, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET bulkQuoteIndex == ReadBytes(clientMessageId.rest, 1) IN IF ~bulkQuoteIndex.ok THEN Fail ELSE
    LET eventId == ReadBytes(bulkQuoteIndex.rest, 4) IN IF ~eventId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(eventId.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET executionId == ReadBytes(tradeId.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(executionId.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET tradeStatus == ReadBytes(reserved1.rest, 1) IN IF ~tradeStatus.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(tradeStatus.rest, 4) IN IF ~lastPrice.ok THEN Fail ELSE
    LET side == ReadBytes(lastPrice.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET lastSize == ReadBytes(side.rest, 4) IN IF ~lastSize.ok THEN Fail ELSE
    Ok([ notificationTime |-> notificationTime.value,
         mpid             |-> mpid.value,
         productId        |-> productId.value,
         liquidityType    |-> liquidityType.value,
         clientMessageId  |-> clientMessageId.value,
         bulkQuoteIndex   |-> bulkQuoteIndex.value,
         eventId          |-> eventId.value,
         tradeId          |-> tradeId.value,
         executionId      |-> executionId.value,
         reserved1        |-> reserved1.value,
         tradeStatus      |-> tradeStatus.value,
         lastPrice        |-> lastPrice.value,
         side             |-> side.value,
         lastSize         |-> lastSize.value ], lastSize.rest)

ZeroOptionExecutionNotification ==
    [ notificationTime |-> [i \in 1 .. 8 |-> 0],
      mpid             |-> [i \in 1 .. 4 |-> 0],
      productId        |-> [i \in 1 .. 4 |-> 0],
      liquidityType    |-> [i \in 1 .. 1 |-> 0],
      clientMessageId  |-> [i \in 1 .. 4 |-> 0],
      bulkQuoteIndex   |-> [i \in 1 .. 1 |-> 0],
      eventId          |-> [i \in 1 .. 4 |-> 0],
      tradeId          |-> [i \in 1 .. 4 |-> 0],
      executionId      |-> [i \in 1 .. 8 |-> 0],
      reserved1        |-> [i \in 1 .. 1 |-> 0],
      tradeStatus      |-> [i \in 1 .. 1 |-> 0],
      lastPrice        |-> [i \in 1 .. 4 |-> 0],
      side             |-> [i \in 1 .. 1 |-> 0],
      lastSize         |-> [i \in 1 .. 4 |-> 0] ]

(* Option Execution Notification at zero, then each field in turn at the values it is checked at *)
CheckedOptionExecutionNotification ==
    { ZeroOptionExecutionNotification }
        \cup { [ZeroOptionExecutionNotification EXCEPT !.notificationTime = one] : one \in Sample(8) }
        \cup { [ZeroOptionExecutionNotification EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroOptionExecutionNotification EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroOptionExecutionNotification EXCEPT !.liquidityType = one] : one \in Sample(1) }
        \cup { [ZeroOptionExecutionNotification EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroOptionExecutionNotification EXCEPT !.bulkQuoteIndex = one] : one \in Sample(1) }
        \cup { [ZeroOptionExecutionNotification EXCEPT !.eventId = one] : one \in Sample(4) }
        \cup { [ZeroOptionExecutionNotification EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroOptionExecutionNotification EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroOptionExecutionNotification EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOptionExecutionNotification EXCEPT !.tradeStatus = one] : one \in Sample(1) }
        \cup { [ZeroOptionExecutionNotification EXCEPT !.lastPrice = one] : one \in Sample(4) }
        \cup { [ZeroOptionExecutionNotification EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOptionExecutionNotification EXCEPT !.lastSize = one] : one \in Sample(4) }

(***************************************************************************)
(* Stock Leg Execution Notification: 71 bytes                              *)
(***************************************************************************)

StockLegExecutionNotification ==
    [ notificationTime        : Sample(8),
      mpid                    : Sample(4),
      underlyingSymbol        : Sample(11),
      liquidityType           : Sample(1),
      clientMessageId         : Sample(4),
      eventId                 : Sample(4),
      tradeId                 : Sample(4),
      executionId             : Sample(8),
      tradeStatus             : Sample(1),
      lastPrice               : Sample(4),
      side                    : Sample(1),
      stockSellShortIndicator : Sample(1),
      lastSize                : Sample(4),
      reserved16              : Sample(16) ]

EncodeStockLegExecutionNotification(message) ==
    message.notificationTime
        \o message.mpid
        \o message.underlyingSymbol
        \o message.liquidityType
        \o message.clientMessageId
        \o message.eventId
        \o message.tradeId
        \o message.executionId
        \o message.tradeStatus
        \o message.lastPrice
        \o message.side
        \o message.stockSellShortIndicator
        \o message.lastSize
        \o message.reserved16

DecodeStockLegExecutionNotification(bytes) ==
    LET notificationTime == ReadBytes(bytes, 8) IN IF ~notificationTime.ok THEN Fail ELSE
    LET mpid == ReadBytes(notificationTime.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(mpid.rest, 11) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET liquidityType == ReadBytes(underlyingSymbol.rest, 1) IN IF ~liquidityType.ok THEN Fail ELSE
    LET clientMessageId == ReadBytes(liquidityType.rest, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET eventId == ReadBytes(clientMessageId.rest, 4) IN IF ~eventId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(eventId.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET executionId == ReadBytes(tradeId.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET tradeStatus == ReadBytes(executionId.rest, 1) IN IF ~tradeStatus.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(tradeStatus.rest, 4) IN IF ~lastPrice.ok THEN Fail ELSE
    LET side == ReadBytes(lastPrice.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET stockSellShortIndicator == ReadBytes(side.rest, 1) IN IF ~stockSellShortIndicator.ok THEN Fail ELSE
    LET lastSize == ReadBytes(stockSellShortIndicator.rest, 4) IN IF ~lastSize.ok THEN Fail ELSE
    LET reserved16 == ReadBytes(lastSize.rest, 16) IN IF ~reserved16.ok THEN Fail ELSE
    Ok([ notificationTime        |-> notificationTime.value,
         mpid                    |-> mpid.value,
         underlyingSymbol        |-> underlyingSymbol.value,
         liquidityType           |-> liquidityType.value,
         clientMessageId         |-> clientMessageId.value,
         eventId                 |-> eventId.value,
         tradeId                 |-> tradeId.value,
         executionId             |-> executionId.value,
         tradeStatus             |-> tradeStatus.value,
         lastPrice               |-> lastPrice.value,
         side                    |-> side.value,
         stockSellShortIndicator |-> stockSellShortIndicator.value,
         lastSize                |-> lastSize.value,
         reserved16              |-> reserved16.value ], reserved16.rest)

ZeroStockLegExecutionNotification ==
    [ notificationTime        |-> [i \in 1 .. 8 |-> 0],
      mpid                    |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbol        |-> [i \in 1 .. 11 |-> 0],
      liquidityType           |-> [i \in 1 .. 1 |-> 0],
      clientMessageId         |-> [i \in 1 .. 4 |-> 0],
      eventId                 |-> [i \in 1 .. 4 |-> 0],
      tradeId                 |-> [i \in 1 .. 4 |-> 0],
      executionId             |-> [i \in 1 .. 8 |-> 0],
      tradeStatus             |-> [i \in 1 .. 1 |-> 0],
      lastPrice               |-> [i \in 1 .. 4 |-> 0],
      side                    |-> [i \in 1 .. 1 |-> 0],
      stockSellShortIndicator |-> [i \in 1 .. 1 |-> 0],
      lastSize                |-> [i \in 1 .. 4 |-> 0],
      reserved16              |-> [i \in 1 .. 16 |-> 0] ]

(* Stock Leg Execution Notification at zero, then each field in turn at the values it is checked at *)
CheckedStockLegExecutionNotification ==
    { ZeroStockLegExecutionNotification }
        \cup { [ZeroStockLegExecutionNotification EXCEPT !.notificationTime = one] : one \in Sample(8) }
        \cup { [ZeroStockLegExecutionNotification EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroStockLegExecutionNotification EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }
        \cup { [ZeroStockLegExecutionNotification EXCEPT !.liquidityType = one] : one \in Sample(1) }
        \cup { [ZeroStockLegExecutionNotification EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroStockLegExecutionNotification EXCEPT !.eventId = one] : one \in Sample(4) }
        \cup { [ZeroStockLegExecutionNotification EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroStockLegExecutionNotification EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroStockLegExecutionNotification EXCEPT !.tradeStatus = one] : one \in Sample(1) }
        \cup { [ZeroStockLegExecutionNotification EXCEPT !.lastPrice = one] : one \in Sample(4) }
        \cup { [ZeroStockLegExecutionNotification EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroStockLegExecutionNotification EXCEPT !.stockSellShortIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStockLegExecutionNotification EXCEPT !.lastSize = one] : one \in Sample(4) }
        \cup { [ZeroStockLegExecutionNotification EXCEPT !.reserved16 = one] : one \in Sample(16) }

(***************************************************************************)
(* Sequenced Message, selected by Sequenced Message Type                   *)
(***************************************************************************)

SimpleSeriesUpdateCode == 21333  \* "SU"
ValidQuoteWidthForOpeningCode == 20823  \* "QW"
SimpleEnhancedQuoteEQuoteResponseCode == 17746  \* "ER"
ComplexEnhancedQuoteEQuoteResponseCode == 17234  \* "CR"
SystemStateNotificationCode == 21326  \* "SN"
ProductTradingStatusNotificationCode == 21582  \* "TN"
UnderlyingTradingStatusNotificationCode == 21838  \* "UN"
QuoteWidthReliefNotificationCode == 20814  \* "QN"
SimpleArmProtectionSettingsNotificationCode == 16718  \* "AN"
Arm2UnderlyingLevelProtectionSettingsNotificationCode == 16690  \* "A2"
SingleSideLiquidityProtectionTriggerNotificationCode == 20824  \* "QX"
Arm2UnderlyingLevelProtectionNotificationCode == 21840  \* "UP"
Arm2FirmLevelProtectionNotificationCode == 18000  \* "FP"
ComplexStrategyDefinitionNotificationCode == 21315  \* "SC"
CancelNotificationCode == 22606  \* "XN"
OptionExecutionNotificationCode == 17742  \* "EN"
StockLegExecutionNotificationCode == 21332  \* "ST"

SequencedMessage ==
    [ tag : {SimpleSeriesUpdateCode}, body : SimpleSeriesUpdate ]
        \cup [ tag : {ValidQuoteWidthForOpeningCode}, body : ValidQuoteWidthForOpening ]
        \cup [ tag : {SimpleEnhancedQuoteEQuoteResponseCode}, body : SimpleEnhancedQuoteEQuoteResponse ]
        \cup [ tag : {ComplexEnhancedQuoteEQuoteResponseCode}, body : ComplexEnhancedQuoteEQuoteResponse ]
        \cup [ tag : {SystemStateNotificationCode}, body : SystemStateNotification ]
        \cup [ tag : {ProductTradingStatusNotificationCode}, body : ProductTradingStatusNotification ]
        \cup [ tag : {UnderlyingTradingStatusNotificationCode}, body : UnderlyingTradingStatusNotification ]
        \cup [ tag : {QuoteWidthReliefNotificationCode}, body : QuoteWidthReliefNotification ]
        \cup [ tag : {SimpleArmProtectionSettingsNotificationCode}, body : SimpleArmProtectionSettingsNotification ]
        \cup [ tag : {Arm2UnderlyingLevelProtectionSettingsNotificationCode}, body : Arm2UnderlyingLevelProtectionSettingsNotification ]
        \cup [ tag : {SingleSideLiquidityProtectionTriggerNotificationCode}, body : SingleSideLiquidityProtectionTriggerNotification ]
        \cup [ tag : {Arm2UnderlyingLevelProtectionNotificationCode}, body : Arm2UnderlyingLevelProtectionNotification ]
        \cup [ tag : {Arm2FirmLevelProtectionNotificationCode}, body : Arm2FirmLevelProtectionNotification ]
        \cup [ tag : {ComplexStrategyDefinitionNotificationCode}, body : ComplexStrategyDefinitionNotification ]
        \cup [ tag : {CancelNotificationCode}, body : CancelNotification ]
        \cup [ tag : {OptionExecutionNotificationCode}, body : OptionExecutionNotification ]
        \cup [ tag : {StockLegExecutionNotificationCode}, body : StockLegExecutionNotification ]

EncodeSequencedMessage(message) ==
    CASE message.tag = SimpleSeriesUpdateCode -> EncodeSimpleSeriesUpdate(message.body)
      [] message.tag = ValidQuoteWidthForOpeningCode -> EncodeValidQuoteWidthForOpening(message.body)
      [] message.tag = SimpleEnhancedQuoteEQuoteResponseCode -> EncodeSimpleEnhancedQuoteEQuoteResponse(message.body)
      [] message.tag = ComplexEnhancedQuoteEQuoteResponseCode -> EncodeComplexEnhancedQuoteEQuoteResponse(message.body)
      [] message.tag = SystemStateNotificationCode -> EncodeSystemStateNotification(message.body)
      [] message.tag = ProductTradingStatusNotificationCode -> EncodeProductTradingStatusNotification(message.body)
      [] message.tag = UnderlyingTradingStatusNotificationCode -> EncodeUnderlyingTradingStatusNotification(message.body)
      [] message.tag = QuoteWidthReliefNotificationCode -> EncodeQuoteWidthReliefNotification(message.body)
      [] message.tag = SimpleArmProtectionSettingsNotificationCode -> EncodeSimpleArmProtectionSettingsNotification(message.body)
      [] message.tag = Arm2UnderlyingLevelProtectionSettingsNotificationCode -> EncodeArm2UnderlyingLevelProtectionSettingsNotification(message.body)
      [] message.tag = SingleSideLiquidityProtectionTriggerNotificationCode -> EncodeSingleSideLiquidityProtectionTriggerNotification(message.body)
      [] message.tag = Arm2UnderlyingLevelProtectionNotificationCode -> EncodeArm2UnderlyingLevelProtectionNotification(message.body)
      [] message.tag = Arm2FirmLevelProtectionNotificationCode -> EncodeArm2FirmLevelProtectionNotification(message.body)
      [] message.tag = ComplexStrategyDefinitionNotificationCode -> EncodeComplexStrategyDefinitionNotification(message.body)
      [] message.tag = CancelNotificationCode -> EncodeCancelNotification(message.body)
      [] message.tag = OptionExecutionNotificationCode -> EncodeOptionExecutionNotification(message.body)
      [] message.tag = StockLegExecutionNotificationCode -> EncodeStockLegExecutionNotification(message.body)

DecodeSequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = SimpleSeriesUpdateCode -> DecodeSimpleSeriesUpdate(bytes)
              [] tag = ValidQuoteWidthForOpeningCode -> DecodeValidQuoteWidthForOpening(bytes)
              [] tag = SimpleEnhancedQuoteEQuoteResponseCode -> DecodeSimpleEnhancedQuoteEQuoteResponse(bytes)
              [] tag = ComplexEnhancedQuoteEQuoteResponseCode -> DecodeComplexEnhancedQuoteEQuoteResponse(bytes)
              [] tag = SystemStateNotificationCode -> DecodeSystemStateNotification(bytes)
              [] tag = ProductTradingStatusNotificationCode -> DecodeProductTradingStatusNotification(bytes)
              [] tag = UnderlyingTradingStatusNotificationCode -> DecodeUnderlyingTradingStatusNotification(bytes)
              [] tag = QuoteWidthReliefNotificationCode -> DecodeQuoteWidthReliefNotification(bytes)
              [] tag = SimpleArmProtectionSettingsNotificationCode -> DecodeSimpleArmProtectionSettingsNotification(bytes)
              [] tag = Arm2UnderlyingLevelProtectionSettingsNotificationCode -> DecodeArm2UnderlyingLevelProtectionSettingsNotification(bytes)
              [] tag = SingleSideLiquidityProtectionTriggerNotificationCode -> DecodeSingleSideLiquidityProtectionTriggerNotification(bytes)
              [] tag = Arm2UnderlyingLevelProtectionNotificationCode -> DecodeArm2UnderlyingLevelProtectionNotification(bytes)
              [] tag = Arm2FirmLevelProtectionNotificationCode -> DecodeArm2FirmLevelProtectionNotification(bytes)
              [] tag = ComplexStrategyDefinitionNotificationCode -> DecodeComplexStrategyDefinitionNotification(bytes)
              [] tag = CancelNotificationCode -> DecodeCancelNotification(bytes)
              [] tag = OptionExecutionNotificationCode -> DecodeOptionExecutionNotification(bytes)
              [] tag = StockLegExecutionNotificationCode -> DecodeStockLegExecutionNotification(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSequencedMessage == [tag |-> SimpleSeriesUpdateCode, body |-> ZeroSimpleSeriesUpdate]

(* Each Sequenced Message in turn, at the values the message it names is checked at *)
CheckedSequencedMessage ==
    { [tag |-> SimpleSeriesUpdateCode, body |-> one] : one \in CheckedSimpleSeriesUpdate }
        \cup { [tag |-> ValidQuoteWidthForOpeningCode, body |-> one] : one \in CheckedValidQuoteWidthForOpening }
        \cup { [tag |-> SimpleEnhancedQuoteEQuoteResponseCode, body |-> one] : one \in CheckedSimpleEnhancedQuoteEQuoteResponse }
        \cup { [tag |-> ComplexEnhancedQuoteEQuoteResponseCode, body |-> one] : one \in CheckedComplexEnhancedQuoteEQuoteResponse }
        \cup { [tag |-> SystemStateNotificationCode, body |-> one] : one \in CheckedSystemStateNotification }
        \cup { [tag |-> ProductTradingStatusNotificationCode, body |-> one] : one \in CheckedProductTradingStatusNotification }
        \cup { [tag |-> UnderlyingTradingStatusNotificationCode, body |-> one] : one \in CheckedUnderlyingTradingStatusNotification }
        \cup { [tag |-> QuoteWidthReliefNotificationCode, body |-> one] : one \in CheckedQuoteWidthReliefNotification }
        \cup { [tag |-> SimpleArmProtectionSettingsNotificationCode, body |-> one] : one \in CheckedSimpleArmProtectionSettingsNotification }
        \cup { [tag |-> Arm2UnderlyingLevelProtectionSettingsNotificationCode, body |-> one] : one \in CheckedArm2UnderlyingLevelProtectionSettingsNotification }
        \cup { [tag |-> SingleSideLiquidityProtectionTriggerNotificationCode, body |-> one] : one \in CheckedSingleSideLiquidityProtectionTriggerNotification }
        \cup { [tag |-> Arm2UnderlyingLevelProtectionNotificationCode, body |-> one] : one \in CheckedArm2UnderlyingLevelProtectionNotification }
        \cup { [tag |-> Arm2FirmLevelProtectionNotificationCode, body |-> one] : one \in CheckedArm2FirmLevelProtectionNotification }
        \cup { [tag |-> ComplexStrategyDefinitionNotificationCode, body |-> one] : one \in CheckedComplexStrategyDefinitionNotification }
        \cup { [tag |-> CancelNotificationCode, body |-> one] : one \in CheckedCancelNotification }
        \cup { [tag |-> OptionExecutionNotificationCode, body |-> one] : one \in CheckedOptionExecutionNotification }
        \cup { [tag |-> StockLegExecutionNotificationCode, body |-> one] : one \in CheckedStockLegExecutionNotification }

(***************************************************************************)
(* Sequenced Data Packet                                                   *)
(***************************************************************************)

SequencedDataPacket ==
    [ sequenceNumber   : Sample(8),
      sequencedMessage : SequencedMessage ]

EncodeSequencedDataPacket(message) ==
    message.sequenceNumber
        \o EncodeUIntBE(message.sequencedMessage.tag, 2)
        \o EncodeSequencedMessage(message.sequencedMessage)

DecodeSequencedDataPacket(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET sequencedMessageType == ReadUIntBE(sequenceNumber.rest, 2) IN IF ~sequencedMessageType.ok THEN Fail ELSE
    LET sequencedMessage == DecodeSequencedMessage(sequencedMessageType.value, sequencedMessageType.rest) IN IF ~sequencedMessage.ok THEN Fail ELSE
    Ok([ sequenceNumber   |-> sequenceNumber.value,
         sequencedMessage |-> sequencedMessage.value ], sequencedMessage.rest)

ZeroSequencedDataPacket ==
    [ sequenceNumber   |-> [i \in 1 .. 8 |-> 0],
      sequencedMessage |-> ZeroSequencedMessage ]

(* Sequenced Data Packet at zero, then each field in turn at the values it is checked at *)
CheckedSequencedDataPacket ==
    { ZeroSequencedDataPacket }
        \cup { [ZeroSequencedDataPacket EXCEPT !.sequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSequencedDataPacket EXCEPT !.sequencedMessage = one] : one \in CheckedSequencedMessage }

(***************************************************************************)
(* Simple Arm Settings Update Request: 26 bytes                            *)
(***************************************************************************)

SimpleArmSettingsUpdateRequest ==
    [ clientMessageId               : Sample(4),
      mpid                          : Sample(4),
      action                        : Sample(1),
      underlyingSymbol              : Sample(11),
      allowableEngagementPercentage : Sample(4),
      countingPeriodBinaryU2        : Sample(2) ]

EncodeSimpleArmSettingsUpdateRequest(message) ==
    message.clientMessageId
        \o message.mpid
        \o message.action
        \o message.underlyingSymbol
        \o message.allowableEngagementPercentage
        \o message.countingPeriodBinaryU2

DecodeSimpleArmSettingsUpdateRequest(bytes) ==
    LET clientMessageId == ReadBytes(bytes, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET mpid == ReadBytes(clientMessageId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET action == ReadBytes(mpid.rest, 1) IN IF ~action.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(action.rest, 11) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET allowableEngagementPercentage == ReadBytes(underlyingSymbol.rest, 4) IN IF ~allowableEngagementPercentage.ok THEN Fail ELSE
    LET countingPeriodBinaryU2 == ReadBytes(allowableEngagementPercentage.rest, 2) IN IF ~countingPeriodBinaryU2.ok THEN Fail ELSE
    Ok([ clientMessageId               |-> clientMessageId.value,
         mpid                          |-> mpid.value,
         action                        |-> action.value,
         underlyingSymbol              |-> underlyingSymbol.value,
         allowableEngagementPercentage |-> allowableEngagementPercentage.value,
         countingPeriodBinaryU2        |-> countingPeriodBinaryU2.value ], countingPeriodBinaryU2.rest)

ZeroSimpleArmSettingsUpdateRequest ==
    [ clientMessageId               |-> [i \in 1 .. 4 |-> 0],
      mpid                          |-> [i \in 1 .. 4 |-> 0],
      action                        |-> [i \in 1 .. 1 |-> 0],
      underlyingSymbol              |-> [i \in 1 .. 11 |-> 0],
      allowableEngagementPercentage |-> [i \in 1 .. 4 |-> 0],
      countingPeriodBinaryU2        |-> [i \in 1 .. 2 |-> 0] ]

(* Simple Arm Settings Update Request at zero, then each field in turn at the values it is checked at *)
CheckedSimpleArmSettingsUpdateRequest ==
    { ZeroSimpleArmSettingsUpdateRequest }
        \cup { [ZeroSimpleArmSettingsUpdateRequest EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleArmSettingsUpdateRequest EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroSimpleArmSettingsUpdateRequest EXCEPT !.action = one] : one \in Sample(1) }
        \cup { [ZeroSimpleArmSettingsUpdateRequest EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }
        \cup { [ZeroSimpleArmSettingsUpdateRequest EXCEPT !.allowableEngagementPercentage = one] : one \in Sample(4) }
        \cup { [ZeroSimpleArmSettingsUpdateRequest EXCEPT !.countingPeriodBinaryU2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Simple Arm Settings Update Response: 20 bytes                           *)
(***************************************************************************)

SimpleArmSettingsUpdateResponse ==
    [ clientMessageId         : Sample(4),
      mpid                    : Sample(4),
      underlyingSymbol        : Sample(11),
      armSettingsUpdateStatus : Sample(1) ]

EncodeSimpleArmSettingsUpdateResponse(message) ==
    message.clientMessageId
        \o message.mpid
        \o message.underlyingSymbol
        \o message.armSettingsUpdateStatus

DecodeSimpleArmSettingsUpdateResponse(bytes) ==
    LET clientMessageId == ReadBytes(bytes, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET mpid == ReadBytes(clientMessageId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(mpid.rest, 11) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET armSettingsUpdateStatus == ReadBytes(underlyingSymbol.rest, 1) IN IF ~armSettingsUpdateStatus.ok THEN Fail ELSE
    Ok([ clientMessageId         |-> clientMessageId.value,
         mpid                    |-> mpid.value,
         underlyingSymbol        |-> underlyingSymbol.value,
         armSettingsUpdateStatus |-> armSettingsUpdateStatus.value ], armSettingsUpdateStatus.rest)

ZeroSimpleArmSettingsUpdateResponse ==
    [ clientMessageId         |-> [i \in 1 .. 4 |-> 0],
      mpid                    |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbol        |-> [i \in 1 .. 11 |-> 0],
      armSettingsUpdateStatus |-> [i \in 1 .. 1 |-> 0] ]

(* Simple Arm Settings Update Response at zero, then each field in turn at the values it is checked at *)
CheckedSimpleArmSettingsUpdateResponse ==
    { ZeroSimpleArmSettingsUpdateResponse }
        \cup { [ZeroSimpleArmSettingsUpdateResponse EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleArmSettingsUpdateResponse EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroSimpleArmSettingsUpdateResponse EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }
        \cup { [ZeroSimpleArmSettingsUpdateResponse EXCEPT !.armSettingsUpdateStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Arm 2 Underlying Level Protection Settings Update Request: 28 bytes     *)
(***************************************************************************)

Arm2UnderlyingLevelProtectionSettingsUpdateRequest ==
    [ clientMessageId           : Sample(4),
      mpid                      : Sample(4),
      action                    : Sample(1),
      underlyingSymbol          : Sample(11),
      armThresholdCountBinaryU4 : Sample(4),
      countingPeriodBinaryU4    : Sample(4) ]

EncodeArm2UnderlyingLevelProtectionSettingsUpdateRequest(message) ==
    message.clientMessageId
        \o message.mpid
        \o message.action
        \o message.underlyingSymbol
        \o message.armThresholdCountBinaryU4
        \o message.countingPeriodBinaryU4

DecodeArm2UnderlyingLevelProtectionSettingsUpdateRequest(bytes) ==
    LET clientMessageId == ReadBytes(bytes, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET mpid == ReadBytes(clientMessageId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET action == ReadBytes(mpid.rest, 1) IN IF ~action.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(action.rest, 11) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET armThresholdCountBinaryU4 == ReadBytes(underlyingSymbol.rest, 4) IN IF ~armThresholdCountBinaryU4.ok THEN Fail ELSE
    LET countingPeriodBinaryU4 == ReadBytes(armThresholdCountBinaryU4.rest, 4) IN IF ~countingPeriodBinaryU4.ok THEN Fail ELSE
    Ok([ clientMessageId           |-> clientMessageId.value,
         mpid                      |-> mpid.value,
         action                    |-> action.value,
         underlyingSymbol          |-> underlyingSymbol.value,
         armThresholdCountBinaryU4 |-> armThresholdCountBinaryU4.value,
         countingPeriodBinaryU4    |-> countingPeriodBinaryU4.value ], countingPeriodBinaryU4.rest)

ZeroArm2UnderlyingLevelProtectionSettingsUpdateRequest ==
    [ clientMessageId           |-> [i \in 1 .. 4 |-> 0],
      mpid                      |-> [i \in 1 .. 4 |-> 0],
      action                    |-> [i \in 1 .. 1 |-> 0],
      underlyingSymbol          |-> [i \in 1 .. 11 |-> 0],
      armThresholdCountBinaryU4 |-> [i \in 1 .. 4 |-> 0],
      countingPeriodBinaryU4    |-> [i \in 1 .. 4 |-> 0] ]

(* Arm 2 Underlying Level Protection Settings Update Request at zero, then each field in turn at the values it is checked at *)
CheckedArm2UnderlyingLevelProtectionSettingsUpdateRequest ==
    { ZeroArm2UnderlyingLevelProtectionSettingsUpdateRequest }
        \cup { [ZeroArm2UnderlyingLevelProtectionSettingsUpdateRequest EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroArm2UnderlyingLevelProtectionSettingsUpdateRequest EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroArm2UnderlyingLevelProtectionSettingsUpdateRequest EXCEPT !.action = one] : one \in Sample(1) }
        \cup { [ZeroArm2UnderlyingLevelProtectionSettingsUpdateRequest EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }
        \cup { [ZeroArm2UnderlyingLevelProtectionSettingsUpdateRequest EXCEPT !.armThresholdCountBinaryU4 = one] : one \in Sample(4) }
        \cup { [ZeroArm2UnderlyingLevelProtectionSettingsUpdateRequest EXCEPT !.countingPeriodBinaryU4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Arm 2 Underlying Level Protection Settings Update Response: 20 bytes    *)
(***************************************************************************)

Arm2UnderlyingLevelProtectionSettingsUpdateResponse ==
    [ clientMessageId         : Sample(4),
      mpid                    : Sample(4),
      underlyingSymbol        : Sample(11),
      armSettingsUpdateStatus : Sample(1) ]

EncodeArm2UnderlyingLevelProtectionSettingsUpdateResponse(message) ==
    message.clientMessageId
        \o message.mpid
        \o message.underlyingSymbol
        \o message.armSettingsUpdateStatus

DecodeArm2UnderlyingLevelProtectionSettingsUpdateResponse(bytes) ==
    LET clientMessageId == ReadBytes(bytes, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET mpid == ReadBytes(clientMessageId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(mpid.rest, 11) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET armSettingsUpdateStatus == ReadBytes(underlyingSymbol.rest, 1) IN IF ~armSettingsUpdateStatus.ok THEN Fail ELSE
    Ok([ clientMessageId         |-> clientMessageId.value,
         mpid                    |-> mpid.value,
         underlyingSymbol        |-> underlyingSymbol.value,
         armSettingsUpdateStatus |-> armSettingsUpdateStatus.value ], armSettingsUpdateStatus.rest)

ZeroArm2UnderlyingLevelProtectionSettingsUpdateResponse ==
    [ clientMessageId         |-> [i \in 1 .. 4 |-> 0],
      mpid                    |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbol        |-> [i \in 1 .. 11 |-> 0],
      armSettingsUpdateStatus |-> [i \in 1 .. 1 |-> 0] ]

(* Arm 2 Underlying Level Protection Settings Update Response at zero, then each field in turn at the values it is checked at *)
CheckedArm2UnderlyingLevelProtectionSettingsUpdateResponse ==
    { ZeroArm2UnderlyingLevelProtectionSettingsUpdateResponse }
        \cup { [ZeroArm2UnderlyingLevelProtectionSettingsUpdateResponse EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroArm2UnderlyingLevelProtectionSettingsUpdateResponse EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroArm2UnderlyingLevelProtectionSettingsUpdateResponse EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }
        \cup { [ZeroArm2UnderlyingLevelProtectionSettingsUpdateResponse EXCEPT !.armSettingsUpdateStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Single Side Quote: 15 bytes                                             *)
(***************************************************************************)

SingleSideQuote ==
    [ productId         : Sample(4),
      priceBinaryPrc4u4 : Sample(4),
      size              : Sample(4),
      side              : Sample(1),
      reserved2         : Sample(2) ]

EncodeSingleSideQuote(message) ==
    message.productId
        \o message.priceBinaryPrc4u4
        \o message.size
        \o message.side
        \o message.reserved2

DecodeSingleSideQuote(bytes) ==
    LET productId == ReadBytes(bytes, 4) IN IF ~productId.ok THEN Fail ELSE
    LET priceBinaryPrc4u4 == ReadBytes(productId.rest, 4) IN IF ~priceBinaryPrc4u4.ok THEN Fail ELSE
    LET size == ReadBytes(priceBinaryPrc4u4.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET side == ReadBytes(size.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(side.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    Ok([ productId         |-> productId.value,
         priceBinaryPrc4u4 |-> priceBinaryPrc4u4.value,
         size              |-> size.value,
         side              |-> side.value,
         reserved2         |-> reserved2.value ], reserved2.rest)

ZeroSingleSideQuote ==
    [ productId         |-> [i \in 1 .. 4 |-> 0],
      priceBinaryPrc4u4 |-> [i \in 1 .. 4 |-> 0],
      size              |-> [i \in 1 .. 4 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      reserved2         |-> [i \in 1 .. 2 |-> 0] ]

(* Single Side Quote at zero, then each field in turn at the values it is checked at *)
CheckedSingleSideQuote ==
    { ZeroSingleSideQuote }
        \cup { [ZeroSingleSideQuote EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideQuote EXCEPT !.priceBinaryPrc4u4 = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideQuote EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideQuote EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroSingleSideQuote EXCEPT !.reserved2 = one] : one \in Sample(2) }

(* A run of Single Side Quote, written one after another *)
RECURSIVE EncodeSingleSideQuoteList(_)
EncodeSingleSideQuoteList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSingleSideQuote(Head(messages)) \o EncodeSingleSideQuoteList(Tail(messages))

(* As many Single Side Quote as the field that counts them says *)
RECURSIVE ReadSingleSideQuoteList(_, _)
ReadSingleSideQuoteList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSingleSideQuote(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSingleSideQuoteList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Single Side Quote of each kind, for the lists that carry them *)
OneSingleSideQuote == { ZeroSingleSideQuote }

(***************************************************************************)
(* Simple Bulk Quote Message                                               *)
(***************************************************************************)

SimpleBulkQuoteMessage ==
    [ clientMessageId : Sample(4),
      mpid            : Sample(4),
      clientSendTime  : Sample(8),
      reserved32      : Sample(32),
      singleSideQuote : SampleLists(OneSingleSideQuote) ]

EncodeSimpleBulkQuoteMessage(message) ==
    message.clientMessageId
        \o message.mpid
        \o message.clientSendTime
        \o EncodeUIntBE(Len(message.singleSideQuote), 1)
        \o message.reserved32
        \o EncodeSingleSideQuoteList(message.singleSideQuote)

DecodeSimpleBulkQuoteMessage(bytes) ==
    LET clientMessageId == ReadBytes(bytes, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET mpid == ReadBytes(clientMessageId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET clientSendTime == ReadBytes(mpid.rest, 8) IN IF ~clientSendTime.ok THEN Fail ELSE
    LET quoteCount == ReadUIntBE(clientSendTime.rest, 1) IN IF ~quoteCount.ok THEN Fail ELSE
    LET reserved32 == ReadBytes(quoteCount.rest, 32) IN IF ~reserved32.ok THEN Fail ELSE
    LET singleSideQuote == ReadSingleSideQuoteList(reserved32.rest, quoteCount.value) IN IF ~singleSideQuote.ok THEN Fail ELSE
    Ok([ clientMessageId |-> clientMessageId.value,
         mpid            |-> mpid.value,
         clientSendTime  |-> clientSendTime.value,
         reserved32      |-> reserved32.value,
         singleSideQuote |-> singleSideQuote.value ], singleSideQuote.rest)

ZeroSimpleBulkQuoteMessage ==
    [ clientMessageId |-> [i \in 1 .. 4 |-> 0],
      mpid            |-> [i \in 1 .. 4 |-> 0],
      clientSendTime  |-> [i \in 1 .. 8 |-> 0],
      reserved32      |-> [i \in 1 .. 32 |-> 0],
      singleSideQuote |-> << >> ]

(* Simple Bulk Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleBulkQuoteMessage ==
    { ZeroSimpleBulkQuoteMessage }
        \cup { [ZeroSimpleBulkQuoteMessage EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleBulkQuoteMessage EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroSimpleBulkQuoteMessage EXCEPT !.clientSendTime = one] : one \in Sample(8) }
        \cup { [ZeroSimpleBulkQuoteMessage EXCEPT !.reserved32 = one] : one \in Sample(32) }
        \cup { [ZeroSimpleBulkQuoteMessage EXCEPT !.singleSideQuote = one] : one \in SampleLists(OneSingleSideQuote) }

(***************************************************************************)
(* Single Side Quote Response: 9 bytes                                     *)
(***************************************************************************)

SingleSideQuoteResponse ==
    [ quoteStatus          : Sample(1),
      engineSequenceNumber : Sample(8) ]

EncodeSingleSideQuoteResponse(message) ==
    message.quoteStatus
        \o message.engineSequenceNumber

DecodeSingleSideQuoteResponse(bytes) ==
    LET quoteStatus == ReadBytes(bytes, 1) IN IF ~quoteStatus.ok THEN Fail ELSE
    LET engineSequenceNumber == ReadBytes(quoteStatus.rest, 8) IN IF ~engineSequenceNumber.ok THEN Fail ELSE
    Ok([ quoteStatus          |-> quoteStatus.value,
         engineSequenceNumber |-> engineSequenceNumber.value ], engineSequenceNumber.rest)

ZeroSingleSideQuoteResponse ==
    [ quoteStatus          |-> [i \in 1 .. 1 |-> 0],
      engineSequenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Single Side Quote Response at zero, then each field in turn at the values it is checked at *)
CheckedSingleSideQuoteResponse ==
    { ZeroSingleSideQuoteResponse }
        \cup { [ZeroSingleSideQuoteResponse EXCEPT !.quoteStatus = one] : one \in Sample(1) }
        \cup { [ZeroSingleSideQuoteResponse EXCEPT !.engineSequenceNumber = one] : one \in Sample(8) }

(* A run of Single Side Quote Response, written one after another *)
RECURSIVE EncodeSingleSideQuoteResponseList(_)
EncodeSingleSideQuoteResponseList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSingleSideQuoteResponse(Head(messages)) \o EncodeSingleSideQuoteResponseList(Tail(messages))

(* As many Single Side Quote Response as the field that counts them says *)
RECURSIVE ReadSingleSideQuoteResponseList(_, _)
ReadSingleSideQuoteResponseList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSingleSideQuoteResponse(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSingleSideQuoteResponseList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Single Side Quote Response of each kind, for the lists that carry them *)
OneSingleSideQuoteResponse == { ZeroSingleSideQuoteResponse }

(***************************************************************************)
(* Simple Bulk Quote Response                                              *)
(***************************************************************************)

SimpleBulkQuoteResponse ==
    [ clientMessageId         : Sample(4),
      mpid                    : Sample(4),
      bulkQuoteStatus         : Sample(1),
      quoteCount              : Sample(1),
      quoteAckTime            : Sample(8),
      singleSideQuoteResponse : SampleLists(OneSingleSideQuoteResponse) ]

EncodeSimpleBulkQuoteResponse(message) ==
    message.clientMessageId
        \o message.mpid
        \o message.bulkQuoteStatus
        \o message.quoteCount
        \o EncodeUIntBE(Len(message.singleSideQuoteResponse), 1)
        \o message.quoteAckTime
        \o EncodeSingleSideQuoteResponseList(message.singleSideQuoteResponse)

DecodeSimpleBulkQuoteResponse(bytes) ==
    LET clientMessageId == ReadBytes(bytes, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET mpid == ReadBytes(clientMessageId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET bulkQuoteStatus == ReadBytes(mpid.rest, 1) IN IF ~bulkQuoteStatus.ok THEN Fail ELSE
    LET quoteCount == ReadBytes(bulkQuoteStatus.rest, 1) IN IF ~quoteCount.ok THEN Fail ELSE
    LET invalidQuoteCount == ReadUIntBE(quoteCount.rest, 1) IN IF ~invalidQuoteCount.ok THEN Fail ELSE
    LET quoteAckTime == ReadBytes(invalidQuoteCount.rest, 8) IN IF ~quoteAckTime.ok THEN Fail ELSE
    LET singleSideQuoteResponse == ReadSingleSideQuoteResponseList(quoteAckTime.rest, invalidQuoteCount.value) IN IF ~singleSideQuoteResponse.ok THEN Fail ELSE
    Ok([ clientMessageId         |-> clientMessageId.value,
         mpid                    |-> mpid.value,
         bulkQuoteStatus         |-> bulkQuoteStatus.value,
         quoteCount              |-> quoteCount.value,
         quoteAckTime            |-> quoteAckTime.value,
         singleSideQuoteResponse |-> singleSideQuoteResponse.value ], singleSideQuoteResponse.rest)

ZeroSimpleBulkQuoteResponse ==
    [ clientMessageId         |-> [i \in 1 .. 4 |-> 0],
      mpid                    |-> [i \in 1 .. 4 |-> 0],
      bulkQuoteStatus         |-> [i \in 1 .. 1 |-> 0],
      quoteCount              |-> [i \in 1 .. 1 |-> 0],
      quoteAckTime            |-> [i \in 1 .. 8 |-> 0],
      singleSideQuoteResponse |-> << >> ]

(* Simple Bulk Quote Response at zero, then each field in turn at the values it is checked at *)
CheckedSimpleBulkQuoteResponse ==
    { ZeroSimpleBulkQuoteResponse }
        \cup { [ZeroSimpleBulkQuoteResponse EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleBulkQuoteResponse EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroSimpleBulkQuoteResponse EXCEPT !.bulkQuoteStatus = one] : one \in Sample(1) }
        \cup { [ZeroSimpleBulkQuoteResponse EXCEPT !.quoteCount = one] : one \in Sample(1) }
        \cup { [ZeroSimpleBulkQuoteResponse EXCEPT !.quoteAckTime = one] : one \in Sample(8) }
        \cup { [ZeroSimpleBulkQuoteResponse EXCEPT !.singleSideQuoteResponse = one] : one \in SampleLists(OneSingleSideQuoteResponse) }

(***************************************************************************)
(* Simple Enhanced Quote E Quote Message: 43 bytes                         *)
(***************************************************************************)

SimpleEnhancedQuoteEQuoteMessage ==
    [ clientMessageId   : Sample(4),
      mpid              : Sample(4),
      clientSendTime    : Sample(8),
      productId         : Sample(4),
      eQuoteAction      : Sample(1),
      eQuoteType        : Sample(1),
      eventId           : Sample(4),
      targetMessageId   : Sample(4),
      priceBinaryPrc4u4 : Sample(4),
      size              : Sample(4),
      side              : Sample(1),
      reserved4         : Sample(4) ]

EncodeSimpleEnhancedQuoteEQuoteMessage(message) ==
    message.clientMessageId
        \o message.mpid
        \o message.clientSendTime
        \o message.productId
        \o message.eQuoteAction
        \o message.eQuoteType
        \o message.eventId
        \o message.targetMessageId
        \o message.priceBinaryPrc4u4
        \o message.size
        \o message.side
        \o message.reserved4

DecodeSimpleEnhancedQuoteEQuoteMessage(bytes) ==
    LET clientMessageId == ReadBytes(bytes, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET mpid == ReadBytes(clientMessageId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET clientSendTime == ReadBytes(mpid.rest, 8) IN IF ~clientSendTime.ok THEN Fail ELSE
    LET productId == ReadBytes(clientSendTime.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET eQuoteAction == ReadBytes(productId.rest, 1) IN IF ~eQuoteAction.ok THEN Fail ELSE
    LET eQuoteType == ReadBytes(eQuoteAction.rest, 1) IN IF ~eQuoteType.ok THEN Fail ELSE
    LET eventId == ReadBytes(eQuoteType.rest, 4) IN IF ~eventId.ok THEN Fail ELSE
    LET targetMessageId == ReadBytes(eventId.rest, 4) IN IF ~targetMessageId.ok THEN Fail ELSE
    LET priceBinaryPrc4u4 == ReadBytes(targetMessageId.rest, 4) IN IF ~priceBinaryPrc4u4.ok THEN Fail ELSE
    LET size == ReadBytes(priceBinaryPrc4u4.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET side == ReadBytes(size.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(side.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    Ok([ clientMessageId   |-> clientMessageId.value,
         mpid              |-> mpid.value,
         clientSendTime    |-> clientSendTime.value,
         productId         |-> productId.value,
         eQuoteAction      |-> eQuoteAction.value,
         eQuoteType        |-> eQuoteType.value,
         eventId           |-> eventId.value,
         targetMessageId   |-> targetMessageId.value,
         priceBinaryPrc4u4 |-> priceBinaryPrc4u4.value,
         size              |-> size.value,
         side              |-> side.value,
         reserved4         |-> reserved4.value ], reserved4.rest)

ZeroSimpleEnhancedQuoteEQuoteMessage ==
    [ clientMessageId   |-> [i \in 1 .. 4 |-> 0],
      mpid              |-> [i \in 1 .. 4 |-> 0],
      clientSendTime    |-> [i \in 1 .. 8 |-> 0],
      productId         |-> [i \in 1 .. 4 |-> 0],
      eQuoteAction      |-> [i \in 1 .. 1 |-> 0],
      eQuoteType        |-> [i \in 1 .. 1 |-> 0],
      eventId           |-> [i \in 1 .. 4 |-> 0],
      targetMessageId   |-> [i \in 1 .. 4 |-> 0],
      priceBinaryPrc4u4 |-> [i \in 1 .. 4 |-> 0],
      size              |-> [i \in 1 .. 4 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      reserved4         |-> [i \in 1 .. 4 |-> 0] ]

(* Simple Enhanced Quote E Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleEnhancedQuoteEQuoteMessage ==
    { ZeroSimpleEnhancedQuoteEQuoteMessage }
        \cup { [ZeroSimpleEnhancedQuoteEQuoteMessage EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleEnhancedQuoteEQuoteMessage EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroSimpleEnhancedQuoteEQuoteMessage EXCEPT !.clientSendTime = one] : one \in Sample(8) }
        \cup { [ZeroSimpleEnhancedQuoteEQuoteMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleEnhancedQuoteEQuoteMessage EXCEPT !.eQuoteAction = one] : one \in Sample(1) }
        \cup { [ZeroSimpleEnhancedQuoteEQuoteMessage EXCEPT !.eQuoteType = one] : one \in Sample(1) }
        \cup { [ZeroSimpleEnhancedQuoteEQuoteMessage EXCEPT !.eventId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleEnhancedQuoteEQuoteMessage EXCEPT !.targetMessageId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleEnhancedQuoteEQuoteMessage EXCEPT !.priceBinaryPrc4u4 = one] : one \in Sample(4) }
        \cup { [ZeroSimpleEnhancedQuoteEQuoteMessage EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroSimpleEnhancedQuoteEQuoteMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroSimpleEnhancedQuoteEQuoteMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Complex Enhanced Quote E Quote Message: 59 bytes                        *)
(***************************************************************************)

ComplexEnhancedQuoteEQuoteMessage ==
    [ clientMessageId         : Sample(4),
      mpid                    : Sample(4),
      clientSendTime          : Sample(8),
      strategyId              : Sample(4),
      eQuoteAction            : Sample(1),
      eQuoteType              : Sample(1),
      complexEventId          : Sample(4),
      targetMessageId         : Sample(4),
      priceBinaryPrc4s8       : Sample(8),
      size                    : Sample(4),
      side                    : Sample(1),
      stockSellShortIndicator : Sample(1),
      reserved15              : Sample(15) ]

EncodeComplexEnhancedQuoteEQuoteMessage(message) ==
    message.clientMessageId
        \o message.mpid
        \o message.clientSendTime
        \o message.strategyId
        \o message.eQuoteAction
        \o message.eQuoteType
        \o message.complexEventId
        \o message.targetMessageId
        \o message.priceBinaryPrc4s8
        \o message.size
        \o message.side
        \o message.stockSellShortIndicator
        \o message.reserved15

DecodeComplexEnhancedQuoteEQuoteMessage(bytes) ==
    LET clientMessageId == ReadBytes(bytes, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET mpid == ReadBytes(clientMessageId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET clientSendTime == ReadBytes(mpid.rest, 8) IN IF ~clientSendTime.ok THEN Fail ELSE
    LET strategyId == ReadBytes(clientSendTime.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET eQuoteAction == ReadBytes(strategyId.rest, 1) IN IF ~eQuoteAction.ok THEN Fail ELSE
    LET eQuoteType == ReadBytes(eQuoteAction.rest, 1) IN IF ~eQuoteType.ok THEN Fail ELSE
    LET complexEventId == ReadBytes(eQuoteType.rest, 4) IN IF ~complexEventId.ok THEN Fail ELSE
    LET targetMessageId == ReadBytes(complexEventId.rest, 4) IN IF ~targetMessageId.ok THEN Fail ELSE
    LET priceBinaryPrc4s8 == ReadBytes(targetMessageId.rest, 8) IN IF ~priceBinaryPrc4s8.ok THEN Fail ELSE
    LET size == ReadBytes(priceBinaryPrc4s8.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET side == ReadBytes(size.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET stockSellShortIndicator == ReadBytes(side.rest, 1) IN IF ~stockSellShortIndicator.ok THEN Fail ELSE
    LET reserved15 == ReadBytes(stockSellShortIndicator.rest, 15) IN IF ~reserved15.ok THEN Fail ELSE
    Ok([ clientMessageId         |-> clientMessageId.value,
         mpid                    |-> mpid.value,
         clientSendTime          |-> clientSendTime.value,
         strategyId              |-> strategyId.value,
         eQuoteAction            |-> eQuoteAction.value,
         eQuoteType              |-> eQuoteType.value,
         complexEventId          |-> complexEventId.value,
         targetMessageId         |-> targetMessageId.value,
         priceBinaryPrc4s8       |-> priceBinaryPrc4s8.value,
         size                    |-> size.value,
         side                    |-> side.value,
         stockSellShortIndicator |-> stockSellShortIndicator.value,
         reserved15              |-> reserved15.value ], reserved15.rest)

ZeroComplexEnhancedQuoteEQuoteMessage ==
    [ clientMessageId         |-> [i \in 1 .. 4 |-> 0],
      mpid                    |-> [i \in 1 .. 4 |-> 0],
      clientSendTime          |-> [i \in 1 .. 8 |-> 0],
      strategyId              |-> [i \in 1 .. 4 |-> 0],
      eQuoteAction            |-> [i \in 1 .. 1 |-> 0],
      eQuoteType              |-> [i \in 1 .. 1 |-> 0],
      complexEventId          |-> [i \in 1 .. 4 |-> 0],
      targetMessageId         |-> [i \in 1 .. 4 |-> 0],
      priceBinaryPrc4s8       |-> [i \in 1 .. 8 |-> 0],
      size                    |-> [i \in 1 .. 4 |-> 0],
      side                    |-> [i \in 1 .. 1 |-> 0],
      stockSellShortIndicator |-> [i \in 1 .. 1 |-> 0],
      reserved15              |-> [i \in 1 .. 15 |-> 0] ]

(* Complex Enhanced Quote E Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexEnhancedQuoteEQuoteMessage ==
    { ZeroComplexEnhancedQuoteEQuoteMessage }
        \cup { [ZeroComplexEnhancedQuoteEQuoteMessage EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroComplexEnhancedQuoteEQuoteMessage EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroComplexEnhancedQuoteEQuoteMessage EXCEPT !.clientSendTime = one] : one \in Sample(8) }
        \cup { [ZeroComplexEnhancedQuoteEQuoteMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroComplexEnhancedQuoteEQuoteMessage EXCEPT !.eQuoteAction = one] : one \in Sample(1) }
        \cup { [ZeroComplexEnhancedQuoteEQuoteMessage EXCEPT !.eQuoteType = one] : one \in Sample(1) }
        \cup { [ZeroComplexEnhancedQuoteEQuoteMessage EXCEPT !.complexEventId = one] : one \in Sample(4) }
        \cup { [ZeroComplexEnhancedQuoteEQuoteMessage EXCEPT !.targetMessageId = one] : one \in Sample(4) }
        \cup { [ZeroComplexEnhancedQuoteEQuoteMessage EXCEPT !.priceBinaryPrc4s8 = one] : one \in Sample(8) }
        \cup { [ZeroComplexEnhancedQuoteEQuoteMessage EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroComplexEnhancedQuoteEQuoteMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroComplexEnhancedQuoteEQuoteMessage EXCEPT !.stockSellShortIndicator = one] : one \in Sample(1) }
        \cup { [ZeroComplexEnhancedQuoteEQuoteMessage EXCEPT !.reserved15 = one] : one \in Sample(15) }

(***************************************************************************)
(* Simple Mass Quote Cancel Request: 31 bytes                              *)
(***************************************************************************)

SimpleMassQuoteCancelRequest ==
    [ clientMessageId  : Sample(4),
      mpid             : Sample(4),
      clientSendTime   : Sample(8),
      underlyingSymbol : Sample(11),
      reserved4        : Sample(4) ]

EncodeSimpleMassQuoteCancelRequest(message) ==
    message.clientMessageId
        \o message.mpid
        \o message.clientSendTime
        \o message.underlyingSymbol
        \o message.reserved4

DecodeSimpleMassQuoteCancelRequest(bytes) ==
    LET clientMessageId == ReadBytes(bytes, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET mpid == ReadBytes(clientMessageId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET clientSendTime == ReadBytes(mpid.rest, 8) IN IF ~clientSendTime.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(clientSendTime.rest, 11) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(underlyingSymbol.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    Ok([ clientMessageId  |-> clientMessageId.value,
         mpid             |-> mpid.value,
         clientSendTime   |-> clientSendTime.value,
         underlyingSymbol |-> underlyingSymbol.value,
         reserved4        |-> reserved4.value ], reserved4.rest)

ZeroSimpleMassQuoteCancelRequest ==
    [ clientMessageId  |-> [i \in 1 .. 4 |-> 0],
      mpid             |-> [i \in 1 .. 4 |-> 0],
      clientSendTime   |-> [i \in 1 .. 8 |-> 0],
      underlyingSymbol |-> [i \in 1 .. 11 |-> 0],
      reserved4        |-> [i \in 1 .. 4 |-> 0] ]

(* Simple Mass Quote Cancel Request at zero, then each field in turn at the values it is checked at *)
CheckedSimpleMassQuoteCancelRequest ==
    { ZeroSimpleMassQuoteCancelRequest }
        \cup { [ZeroSimpleMassQuoteCancelRequest EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleMassQuoteCancelRequest EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroSimpleMassQuoteCancelRequest EXCEPT !.clientSendTime = one] : one \in Sample(8) }
        \cup { [ZeroSimpleMassQuoteCancelRequest EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }
        \cup { [ZeroSimpleMassQuoteCancelRequest EXCEPT !.reserved4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Simple Mass Quote Cancel Response: 9 bytes                              *)
(***************************************************************************)

SimpleMassQuoteCancelResponse ==
    [ clientMessageId             : Sample(4),
      mpid                        : Sample(4),
      simpleMassQuoteCancelStatus : Sample(1) ]

EncodeSimpleMassQuoteCancelResponse(message) ==
    message.clientMessageId
        \o message.mpid
        \o message.simpleMassQuoteCancelStatus

DecodeSimpleMassQuoteCancelResponse(bytes) ==
    LET clientMessageId == ReadBytes(bytes, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET mpid == ReadBytes(clientMessageId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET simpleMassQuoteCancelStatus == ReadBytes(mpid.rest, 1) IN IF ~simpleMassQuoteCancelStatus.ok THEN Fail ELSE
    Ok([ clientMessageId             |-> clientMessageId.value,
         mpid                        |-> mpid.value,
         simpleMassQuoteCancelStatus |-> simpleMassQuoteCancelStatus.value ], simpleMassQuoteCancelStatus.rest)

ZeroSimpleMassQuoteCancelResponse ==
    [ clientMessageId             |-> [i \in 1 .. 4 |-> 0],
      mpid                        |-> [i \in 1 .. 4 |-> 0],
      simpleMassQuoteCancelStatus |-> [i \in 1 .. 1 |-> 0] ]

(* Simple Mass Quote Cancel Response at zero, then each field in turn at the values it is checked at *)
CheckedSimpleMassQuoteCancelResponse ==
    { ZeroSimpleMassQuoteCancelResponse }
        \cup { [ZeroSimpleMassQuoteCancelResponse EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleMassQuoteCancelResponse EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroSimpleMassQuoteCancelResponse EXCEPT !.simpleMassQuoteCancelStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Mass Liquidity Cancel Request Simple And Complex: 37 bytes              *)
(***************************************************************************)

MassLiquidityCancelRequestSimpleAndComplex ==
    [ clientMessageId   : Sample(4),
      mpid              : Sample(4),
      clientSendTime    : Sample(8),
      underlyingSymbol  : Sample(11),
      simpleMassCancel  : Sample(1),
      complexMassCancel : Sample(1),
      reserved8         : Sample(8) ]

EncodeMassLiquidityCancelRequestSimpleAndComplex(message) ==
    message.clientMessageId
        \o message.mpid
        \o message.clientSendTime
        \o message.underlyingSymbol
        \o message.simpleMassCancel
        \o message.complexMassCancel
        \o message.reserved8

DecodeMassLiquidityCancelRequestSimpleAndComplex(bytes) ==
    LET clientMessageId == ReadBytes(bytes, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET mpid == ReadBytes(clientMessageId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET clientSendTime == ReadBytes(mpid.rest, 8) IN IF ~clientSendTime.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(clientSendTime.rest, 11) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET simpleMassCancel == ReadBytes(underlyingSymbol.rest, 1) IN IF ~simpleMassCancel.ok THEN Fail ELSE
    LET complexMassCancel == ReadBytes(simpleMassCancel.rest, 1) IN IF ~complexMassCancel.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(complexMassCancel.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    Ok([ clientMessageId   |-> clientMessageId.value,
         mpid              |-> mpid.value,
         clientSendTime    |-> clientSendTime.value,
         underlyingSymbol  |-> underlyingSymbol.value,
         simpleMassCancel  |-> simpleMassCancel.value,
         complexMassCancel |-> complexMassCancel.value,
         reserved8         |-> reserved8.value ], reserved8.rest)

ZeroMassLiquidityCancelRequestSimpleAndComplex ==
    [ clientMessageId   |-> [i \in 1 .. 4 |-> 0],
      mpid              |-> [i \in 1 .. 4 |-> 0],
      clientSendTime    |-> [i \in 1 .. 8 |-> 0],
      underlyingSymbol  |-> [i \in 1 .. 11 |-> 0],
      simpleMassCancel  |-> [i \in 1 .. 1 |-> 0],
      complexMassCancel |-> [i \in 1 .. 1 |-> 0],
      reserved8         |-> [i \in 1 .. 8 |-> 0] ]

(* Mass Liquidity Cancel Request Simple And Complex at zero, then each field in turn at the values it is checked at *)
CheckedMassLiquidityCancelRequestSimpleAndComplex ==
    { ZeroMassLiquidityCancelRequestSimpleAndComplex }
        \cup { [ZeroMassLiquidityCancelRequestSimpleAndComplex EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroMassLiquidityCancelRequestSimpleAndComplex EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroMassLiquidityCancelRequestSimpleAndComplex EXCEPT !.clientSendTime = one] : one \in Sample(8) }
        \cup { [ZeroMassLiquidityCancelRequestSimpleAndComplex EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }
        \cup { [ZeroMassLiquidityCancelRequestSimpleAndComplex EXCEPT !.simpleMassCancel = one] : one \in Sample(1) }
        \cup { [ZeroMassLiquidityCancelRequestSimpleAndComplex EXCEPT !.complexMassCancel = one] : one \in Sample(1) }
        \cup { [ZeroMassLiquidityCancelRequestSimpleAndComplex EXCEPT !.reserved8 = one] : one \in Sample(8) }

(***************************************************************************)
(* Mass Liquidity Cancel Response: 10 bytes                                *)
(***************************************************************************)

MassLiquidityCancelResponse ==
    [ clientMessageId                  : Sample(4),
      mpid                             : Sample(4),
      simpleMassLiquidityCancelStatus  : Sample(1),
      complexMassLiquidityCancelStatus : Sample(1) ]

EncodeMassLiquidityCancelResponse(message) ==
    message.clientMessageId
        \o message.mpid
        \o message.simpleMassLiquidityCancelStatus
        \o message.complexMassLiquidityCancelStatus

DecodeMassLiquidityCancelResponse(bytes) ==
    LET clientMessageId == ReadBytes(bytes, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET mpid == ReadBytes(clientMessageId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET simpleMassLiquidityCancelStatus == ReadBytes(mpid.rest, 1) IN IF ~simpleMassLiquidityCancelStatus.ok THEN Fail ELSE
    LET complexMassLiquidityCancelStatus == ReadBytes(simpleMassLiquidityCancelStatus.rest, 1) IN IF ~complexMassLiquidityCancelStatus.ok THEN Fail ELSE
    Ok([ clientMessageId                  |-> clientMessageId.value,
         mpid                             |-> mpid.value,
         simpleMassLiquidityCancelStatus  |-> simpleMassLiquidityCancelStatus.value,
         complexMassLiquidityCancelStatus |-> complexMassLiquidityCancelStatus.value ], complexMassLiquidityCancelStatus.rest)

ZeroMassLiquidityCancelResponse ==
    [ clientMessageId                  |-> [i \in 1 .. 4 |-> 0],
      mpid                             |-> [i \in 1 .. 4 |-> 0],
      simpleMassLiquidityCancelStatus  |-> [i \in 1 .. 1 |-> 0],
      complexMassLiquidityCancelStatus |-> [i \in 1 .. 1 |-> 0] ]

(* Mass Liquidity Cancel Response at zero, then each field in turn at the values it is checked at *)
CheckedMassLiquidityCancelResponse ==
    { ZeroMassLiquidityCancelResponse }
        \cup { [ZeroMassLiquidityCancelResponse EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroMassLiquidityCancelResponse EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroMassLiquidityCancelResponse EXCEPT !.simpleMassLiquidityCancelStatus = one] : one \in Sample(1) }
        \cup { [ZeroMassLiquidityCancelResponse EXCEPT !.complexMassLiquidityCancelStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Simple Quote Protection Reset Request: 19 bytes                         *)
(***************************************************************************)

SimpleQuoteProtectionResetRequest ==
    [ clientMessageId  : Sample(4),
      mpid             : Sample(4),
      underlyingSymbol : Sample(11) ]

EncodeSimpleQuoteProtectionResetRequest(message) ==
    message.clientMessageId
        \o message.mpid
        \o message.underlyingSymbol

DecodeSimpleQuoteProtectionResetRequest(bytes) ==
    LET clientMessageId == ReadBytes(bytes, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET mpid == ReadBytes(clientMessageId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(mpid.rest, 11) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    Ok([ clientMessageId  |-> clientMessageId.value,
         mpid             |-> mpid.value,
         underlyingSymbol |-> underlyingSymbol.value ], underlyingSymbol.rest)

ZeroSimpleQuoteProtectionResetRequest ==
    [ clientMessageId  |-> [i \in 1 .. 4 |-> 0],
      mpid             |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbol |-> [i \in 1 .. 11 |-> 0] ]

(* Simple Quote Protection Reset Request at zero, then each field in turn at the values it is checked at *)
CheckedSimpleQuoteProtectionResetRequest ==
    { ZeroSimpleQuoteProtectionResetRequest }
        \cup { [ZeroSimpleQuoteProtectionResetRequest EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleQuoteProtectionResetRequest EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroSimpleQuoteProtectionResetRequest EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }

(***************************************************************************)
(* Simple Quote Protection Reset Response: 9 bytes                         *)
(***************************************************************************)

SimpleQuoteProtectionResetResponse ==
    [ clientMessageId            : Sample(4),
      mpid                       : Sample(4),
      quoteProtectionResetStatus : Sample(1) ]

EncodeSimpleQuoteProtectionResetResponse(message) ==
    message.clientMessageId
        \o message.mpid
        \o message.quoteProtectionResetStatus

DecodeSimpleQuoteProtectionResetResponse(bytes) ==
    LET clientMessageId == ReadBytes(bytes, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET mpid == ReadBytes(clientMessageId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET quoteProtectionResetStatus == ReadBytes(mpid.rest, 1) IN IF ~quoteProtectionResetStatus.ok THEN Fail ELSE
    Ok([ clientMessageId            |-> clientMessageId.value,
         mpid                       |-> mpid.value,
         quoteProtectionResetStatus |-> quoteProtectionResetStatus.value ], quoteProtectionResetStatus.rest)

ZeroSimpleQuoteProtectionResetResponse ==
    [ clientMessageId            |-> [i \in 1 .. 4 |-> 0],
      mpid                       |-> [i \in 1 .. 4 |-> 0],
      quoteProtectionResetStatus |-> [i \in 1 .. 1 |-> 0] ]

(* Simple Quote Protection Reset Response at zero, then each field in turn at the values it is checked at *)
CheckedSimpleQuoteProtectionResetResponse ==
    { ZeroSimpleQuoteProtectionResetResponse }
        \cup { [ZeroSimpleQuoteProtectionResetResponse EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleQuoteProtectionResetResponse EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroSimpleQuoteProtectionResetResponse EXCEPT !.quoteProtectionResetStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Liquidity Protection Reset Request: 29 bytes                            *)
(***************************************************************************)

LiquidityProtectionResetRequest ==
    [ clientMessageId       : Sample(4),
      mpid                  : Sample(4),
      underlyingSymbol      : Sample(11),
      simpleLiquidityReset  : Sample(1),
      complexLiquidityReset : Sample(1),
      reserved8             : Sample(8) ]

EncodeLiquidityProtectionResetRequest(message) ==
    message.clientMessageId
        \o message.mpid
        \o message.underlyingSymbol
        \o message.simpleLiquidityReset
        \o message.complexLiquidityReset
        \o message.reserved8

DecodeLiquidityProtectionResetRequest(bytes) ==
    LET clientMessageId == ReadBytes(bytes, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET mpid == ReadBytes(clientMessageId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(mpid.rest, 11) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET simpleLiquidityReset == ReadBytes(underlyingSymbol.rest, 1) IN IF ~simpleLiquidityReset.ok THEN Fail ELSE
    LET complexLiquidityReset == ReadBytes(simpleLiquidityReset.rest, 1) IN IF ~complexLiquidityReset.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(complexLiquidityReset.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    Ok([ clientMessageId       |-> clientMessageId.value,
         mpid                  |-> mpid.value,
         underlyingSymbol      |-> underlyingSymbol.value,
         simpleLiquidityReset  |-> simpleLiquidityReset.value,
         complexLiquidityReset |-> complexLiquidityReset.value,
         reserved8             |-> reserved8.value ], reserved8.rest)

ZeroLiquidityProtectionResetRequest ==
    [ clientMessageId       |-> [i \in 1 .. 4 |-> 0],
      mpid                  |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbol      |-> [i \in 1 .. 11 |-> 0],
      simpleLiquidityReset  |-> [i \in 1 .. 1 |-> 0],
      complexLiquidityReset |-> [i \in 1 .. 1 |-> 0],
      reserved8             |-> [i \in 1 .. 8 |-> 0] ]

(* Liquidity Protection Reset Request at zero, then each field in turn at the values it is checked at *)
CheckedLiquidityProtectionResetRequest ==
    { ZeroLiquidityProtectionResetRequest }
        \cup { [ZeroLiquidityProtectionResetRequest EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroLiquidityProtectionResetRequest EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroLiquidityProtectionResetRequest EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }
        \cup { [ZeroLiquidityProtectionResetRequest EXCEPT !.simpleLiquidityReset = one] : one \in Sample(1) }
        \cup { [ZeroLiquidityProtectionResetRequest EXCEPT !.complexLiquidityReset = one] : one \in Sample(1) }
        \cup { [ZeroLiquidityProtectionResetRequest EXCEPT !.reserved8 = one] : one \in Sample(8) }

(***************************************************************************)
(* Liquidity Protection Reset Response: 10 bytes                           *)
(***************************************************************************)

LiquidityProtectionResetResponse ==
    [ clientMessageId                       : Sample(4),
      mpid                                  : Sample(4),
      simpleLiquidityProtectionResetStatus  : Sample(1),
      complexLiquidityProtectionResetStatus : Sample(1) ]

EncodeLiquidityProtectionResetResponse(message) ==
    message.clientMessageId
        \o message.mpid
        \o message.simpleLiquidityProtectionResetStatus
        \o message.complexLiquidityProtectionResetStatus

DecodeLiquidityProtectionResetResponse(bytes) ==
    LET clientMessageId == ReadBytes(bytes, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET mpid == ReadBytes(clientMessageId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET simpleLiquidityProtectionResetStatus == ReadBytes(mpid.rest, 1) IN IF ~simpleLiquidityProtectionResetStatus.ok THEN Fail ELSE
    LET complexLiquidityProtectionResetStatus == ReadBytes(simpleLiquidityProtectionResetStatus.rest, 1) IN IF ~complexLiquidityProtectionResetStatus.ok THEN Fail ELSE
    Ok([ clientMessageId                       |-> clientMessageId.value,
         mpid                                  |-> mpid.value,
         simpleLiquidityProtectionResetStatus  |-> simpleLiquidityProtectionResetStatus.value,
         complexLiquidityProtectionResetStatus |-> complexLiquidityProtectionResetStatus.value ], complexLiquidityProtectionResetStatus.rest)

ZeroLiquidityProtectionResetResponse ==
    [ clientMessageId                       |-> [i \in 1 .. 4 |-> 0],
      mpid                                  |-> [i \in 1 .. 4 |-> 0],
      simpleLiquidityProtectionResetStatus  |-> [i \in 1 .. 1 |-> 0],
      complexLiquidityProtectionResetStatus |-> [i \in 1 .. 1 |-> 0] ]

(* Liquidity Protection Reset Response at zero, then each field in turn at the values it is checked at *)
CheckedLiquidityProtectionResetResponse ==
    { ZeroLiquidityProtectionResetResponse }
        \cup { [ZeroLiquidityProtectionResetResponse EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroLiquidityProtectionResetResponse EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroLiquidityProtectionResetResponse EXCEPT !.simpleLiquidityProtectionResetStatus = one] : one \in Sample(1) }
        \cup { [ZeroLiquidityProtectionResetResponse EXCEPT !.complexLiquidityProtectionResetStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Single Side Liquidity Protection Reset Request: 18 bytes                *)
(***************************************************************************)

SingleSideLiquidityProtectionResetRequest ==
    [ clientMessageId : Sample(4),
      mpid            : Sample(4),
      securityIdScope : Sample(1),
      securityId      : Sample(4),
      side            : Sample(1),
      reserved4       : Sample(4) ]

EncodeSingleSideLiquidityProtectionResetRequest(message) ==
    message.clientMessageId
        \o message.mpid
        \o message.securityIdScope
        \o message.securityId
        \o message.side
        \o message.reserved4

DecodeSingleSideLiquidityProtectionResetRequest(bytes) ==
    LET clientMessageId == ReadBytes(bytes, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET mpid == ReadBytes(clientMessageId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET securityIdScope == ReadBytes(mpid.rest, 1) IN IF ~securityIdScope.ok THEN Fail ELSE
    LET securityId == ReadBytes(securityIdScope.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET side == ReadBytes(securityId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(side.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    Ok([ clientMessageId |-> clientMessageId.value,
         mpid            |-> mpid.value,
         securityIdScope |-> securityIdScope.value,
         securityId      |-> securityId.value,
         side            |-> side.value,
         reserved4       |-> reserved4.value ], reserved4.rest)

ZeroSingleSideLiquidityProtectionResetRequest ==
    [ clientMessageId |-> [i \in 1 .. 4 |-> 0],
      mpid            |-> [i \in 1 .. 4 |-> 0],
      securityIdScope |-> [i \in 1 .. 1 |-> 0],
      securityId      |-> [i \in 1 .. 4 |-> 0],
      side            |-> [i \in 1 .. 1 |-> 0],
      reserved4       |-> [i \in 1 .. 4 |-> 0] ]

(* Single Side Liquidity Protection Reset Request at zero, then each field in turn at the values it is checked at *)
CheckedSingleSideLiquidityProtectionResetRequest ==
    { ZeroSingleSideLiquidityProtectionResetRequest }
        \cup { [ZeroSingleSideLiquidityProtectionResetRequest EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideLiquidityProtectionResetRequest EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideLiquidityProtectionResetRequest EXCEPT !.securityIdScope = one] : one \in Sample(1) }
        \cup { [ZeroSingleSideLiquidityProtectionResetRequest EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideLiquidityProtectionResetRequest EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroSingleSideLiquidityProtectionResetRequest EXCEPT !.reserved4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Single Side Liquidity Protection Reset Response: 13 bytes               *)
(***************************************************************************)

SingleSideLiquidityProtectionResetResponse ==
    [ clientMessageId : Sample(4),
      mpid            : Sample(4),
      reserved4       : Sample(4),
      status          : Sample(1) ]

EncodeSingleSideLiquidityProtectionResetResponse(message) ==
    message.clientMessageId
        \o message.mpid
        \o message.reserved4
        \o message.status

DecodeSingleSideLiquidityProtectionResetResponse(bytes) ==
    LET clientMessageId == ReadBytes(bytes, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET mpid == ReadBytes(clientMessageId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(mpid.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET status == ReadBytes(reserved4.rest, 1) IN IF ~status.ok THEN Fail ELSE
    Ok([ clientMessageId |-> clientMessageId.value,
         mpid            |-> mpid.value,
         reserved4       |-> reserved4.value,
         status          |-> status.value ], status.rest)

ZeroSingleSideLiquidityProtectionResetResponse ==
    [ clientMessageId |-> [i \in 1 .. 4 |-> 0],
      mpid            |-> [i \in 1 .. 4 |-> 0],
      reserved4       |-> [i \in 1 .. 4 |-> 0],
      status          |-> [i \in 1 .. 1 |-> 0] ]

(* Single Side Liquidity Protection Reset Response at zero, then each field in turn at the values it is checked at *)
CheckedSingleSideLiquidityProtectionResetResponse ==
    { ZeroSingleSideLiquidityProtectionResetResponse }
        \cup { [ZeroSingleSideLiquidityProtectionResetResponse EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideLiquidityProtectionResetResponse EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideLiquidityProtectionResetResponse EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideLiquidityProtectionResetResponse EXCEPT !.status = one] : one \in Sample(1) }

(***************************************************************************)
(* Simple Quote Protection Trigger Notification: 24 bytes                  *)
(***************************************************************************)

SimpleQuoteProtectionTriggerNotification ==
    [ notificationTime : Sample(8),
      mpid             : Sample(4),
      underlyingSymbol : Sample(11),
      triggerReason    : Sample(1) ]

EncodeSimpleQuoteProtectionTriggerNotification(message) ==
    message.notificationTime
        \o message.mpid
        \o message.underlyingSymbol
        \o message.triggerReason

DecodeSimpleQuoteProtectionTriggerNotification(bytes) ==
    LET notificationTime == ReadBytes(bytes, 8) IN IF ~notificationTime.ok THEN Fail ELSE
    LET mpid == ReadBytes(notificationTime.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(mpid.rest, 11) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET triggerReason == ReadBytes(underlyingSymbol.rest, 1) IN IF ~triggerReason.ok THEN Fail ELSE
    Ok([ notificationTime |-> notificationTime.value,
         mpid             |-> mpid.value,
         underlyingSymbol |-> underlyingSymbol.value,
         triggerReason    |-> triggerReason.value ], triggerReason.rest)

ZeroSimpleQuoteProtectionTriggerNotification ==
    [ notificationTime |-> [i \in 1 .. 8 |-> 0],
      mpid             |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbol |-> [i \in 1 .. 11 |-> 0],
      triggerReason    |-> [i \in 1 .. 1 |-> 0] ]

(* Simple Quote Protection Trigger Notification at zero, then each field in turn at the values it is checked at *)
CheckedSimpleQuoteProtectionTriggerNotification ==
    { ZeroSimpleQuoteProtectionTriggerNotification }
        \cup { [ZeroSimpleQuoteProtectionTriggerNotification EXCEPT !.notificationTime = one] : one \in Sample(8) }
        \cup { [ZeroSimpleQuoteProtectionTriggerNotification EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroSimpleQuoteProtectionTriggerNotification EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }
        \cup { [ZeroSimpleQuoteProtectionTriggerNotification EXCEPT !.triggerReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Complex Liquidity Protection Trigger Notification: 24 bytes             *)
(***************************************************************************)

ComplexLiquidityProtectionTriggerNotification ==
    [ notificationTime : Sample(8),
      mpid             : Sample(4),
      underlyingSymbol : Sample(11),
      triggerReason    : Sample(1) ]

EncodeComplexLiquidityProtectionTriggerNotification(message) ==
    message.notificationTime
        \o message.mpid
        \o message.underlyingSymbol
        \o message.triggerReason

DecodeComplexLiquidityProtectionTriggerNotification(bytes) ==
    LET notificationTime == ReadBytes(bytes, 8) IN IF ~notificationTime.ok THEN Fail ELSE
    LET mpid == ReadBytes(notificationTime.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(mpid.rest, 11) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET triggerReason == ReadBytes(underlyingSymbol.rest, 1) IN IF ~triggerReason.ok THEN Fail ELSE
    Ok([ notificationTime |-> notificationTime.value,
         mpid             |-> mpid.value,
         underlyingSymbol |-> underlyingSymbol.value,
         triggerReason    |-> triggerReason.value ], triggerReason.rest)

ZeroComplexLiquidityProtectionTriggerNotification ==
    [ notificationTime |-> [i \in 1 .. 8 |-> 0],
      mpid             |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbol |-> [i \in 1 .. 11 |-> 0],
      triggerReason    |-> [i \in 1 .. 1 |-> 0] ]

(* Complex Liquidity Protection Trigger Notification at zero, then each field in turn at the values it is checked at *)
CheckedComplexLiquidityProtectionTriggerNotification ==
    { ZeroComplexLiquidityProtectionTriggerNotification }
        \cup { [ZeroComplexLiquidityProtectionTriggerNotification EXCEPT !.notificationTime = one] : one \in Sample(8) }
        \cup { [ZeroComplexLiquidityProtectionTriggerNotification EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroComplexLiquidityProtectionTriggerNotification EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }
        \cup { [ZeroComplexLiquidityProtectionTriggerNotification EXCEPT !.triggerReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Cancel Notification: 36 bytes                                           *)
(***************************************************************************)

CancelNotification2 ==
    [ notificationTime      : Sample(8),
      mpid                  : Sample(4),
      productIdOrStrategyId : Sample(4),
      liquidityType         : Sample(1),
      clientMessageId       : Sample(4),
      bulkQuoteIndex        : Sample(1),
      quoteeQuoteSide       : Sample(1),
      size                  : Sample(4),
      engineSequenceNumber  : Sample(8),
      cancelReason          : Sample(1) ]

EncodeCancelNotification2(message) ==
    message.notificationTime
        \o message.mpid
        \o message.productIdOrStrategyId
        \o message.liquidityType
        \o message.clientMessageId
        \o message.bulkQuoteIndex
        \o message.quoteeQuoteSide
        \o message.size
        \o message.engineSequenceNumber
        \o message.cancelReason

DecodeCancelNotification2(bytes) ==
    LET notificationTime == ReadBytes(bytes, 8) IN IF ~notificationTime.ok THEN Fail ELSE
    LET mpid == ReadBytes(notificationTime.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET productIdOrStrategyId == ReadBytes(mpid.rest, 4) IN IF ~productIdOrStrategyId.ok THEN Fail ELSE
    LET liquidityType == ReadBytes(productIdOrStrategyId.rest, 1) IN IF ~liquidityType.ok THEN Fail ELSE
    LET clientMessageId == ReadBytes(liquidityType.rest, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET bulkQuoteIndex == ReadBytes(clientMessageId.rest, 1) IN IF ~bulkQuoteIndex.ok THEN Fail ELSE
    LET quoteeQuoteSide == ReadBytes(bulkQuoteIndex.rest, 1) IN IF ~quoteeQuoteSide.ok THEN Fail ELSE
    LET size == ReadBytes(quoteeQuoteSide.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET engineSequenceNumber == ReadBytes(size.rest, 8) IN IF ~engineSequenceNumber.ok THEN Fail ELSE
    LET cancelReason == ReadBytes(engineSequenceNumber.rest, 1) IN IF ~cancelReason.ok THEN Fail ELSE
    Ok([ notificationTime      |-> notificationTime.value,
         mpid                  |-> mpid.value,
         productIdOrStrategyId |-> productIdOrStrategyId.value,
         liquidityType         |-> liquidityType.value,
         clientMessageId       |-> clientMessageId.value,
         bulkQuoteIndex        |-> bulkQuoteIndex.value,
         quoteeQuoteSide       |-> quoteeQuoteSide.value,
         size                  |-> size.value,
         engineSequenceNumber  |-> engineSequenceNumber.value,
         cancelReason          |-> cancelReason.value ], cancelReason.rest)

ZeroCancelNotification2 ==
    [ notificationTime      |-> [i \in 1 .. 8 |-> 0],
      mpid                  |-> [i \in 1 .. 4 |-> 0],
      productIdOrStrategyId |-> [i \in 1 .. 4 |-> 0],
      liquidityType         |-> [i \in 1 .. 1 |-> 0],
      clientMessageId       |-> [i \in 1 .. 4 |-> 0],
      bulkQuoteIndex        |-> [i \in 1 .. 1 |-> 0],
      quoteeQuoteSide       |-> [i \in 1 .. 1 |-> 0],
      size                  |-> [i \in 1 .. 4 |-> 0],
      engineSequenceNumber  |-> [i \in 1 .. 8 |-> 0],
      cancelReason          |-> [i \in 1 .. 1 |-> 0] ]

(* Cancel Notification at zero, then each field in turn at the values it is checked at *)
CheckedCancelNotification2 ==
    { ZeroCancelNotification2 }
        \cup { [ZeroCancelNotification2 EXCEPT !.notificationTime = one] : one \in Sample(8) }
        \cup { [ZeroCancelNotification2 EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroCancelNotification2 EXCEPT !.productIdOrStrategyId = one] : one \in Sample(4) }
        \cup { [ZeroCancelNotification2 EXCEPT !.liquidityType = one] : one \in Sample(1) }
        \cup { [ZeroCancelNotification2 EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroCancelNotification2 EXCEPT !.bulkQuoteIndex = one] : one \in Sample(1) }
        \cup { [ZeroCancelNotification2 EXCEPT !.quoteeQuoteSide = one] : one \in Sample(1) }
        \cup { [ZeroCancelNotification2 EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroCancelNotification2 EXCEPT !.engineSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroCancelNotification2 EXCEPT !.cancelReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Unsequenced Message, selected by Unsequenced Message Type               *)
(***************************************************************************)

SimpleArmSettingsUpdateRequestCode == 16723  \* "AS"
SimpleArmSettingsUpdateResponseCode == 16705  \* "AA"
Arm2UnderlyingLevelProtectionSettingsUpdateRequestCode == 12883  \* "2S"
Arm2UnderlyingLevelProtectionSettingsUpdateResponseCode == 12882  \* "2R"
SimpleBulkQuoteMessageCode == 29041  \* "qq"
SimpleBulkQuoteResponseCode == 20818  \* "QR"
SimpleEnhancedQuoteEQuoteMessageCode == 25969  \* "eq"
ComplexEnhancedQuoteEQuoteMessageCode == 25445  \* "ce"
SimpleMassQuoteCancelRequestCode == 30833  \* "xq"
SimpleMassQuoteCancelResponseCode == 22610  \* "XR"
MassLiquidityCancelRequestSimpleAndComplexCode == 30827  \* "xk"
MassLiquidityCancelResponseCode == 22608  \* "XP"
SimpleQuoteProtectionResetRequestCode == 20568  \* "PX"
SimpleQuoteProtectionResetResponseCode == 20562  \* "PR"
LiquidityProtectionResetRequestCode == 20547  \* "PC"
LiquidityProtectionResetResponseCode == 20555  \* "PK"
SingleSideLiquidityProtectionResetRequestCode == 21331  \* "SS"
SingleSideLiquidityProtectionResetResponseCode == 21330  \* "SR"
SimpleQuoteProtectionTriggerNotificationCode == 20816  \* "QP"
ComplexLiquidityProtectionTriggerNotificationCode == 20803  \* "QC"
CancelNotificationCode2 == 22606  \* "XN"

UnsequencedMessage ==
    [ tag : {SimpleArmSettingsUpdateRequestCode}, body : SimpleArmSettingsUpdateRequest ]
        \cup [ tag : {SimpleArmSettingsUpdateResponseCode}, body : SimpleArmSettingsUpdateResponse ]
        \cup [ tag : {Arm2UnderlyingLevelProtectionSettingsUpdateRequestCode}, body : Arm2UnderlyingLevelProtectionSettingsUpdateRequest ]
        \cup [ tag : {Arm2UnderlyingLevelProtectionSettingsUpdateResponseCode}, body : Arm2UnderlyingLevelProtectionSettingsUpdateResponse ]
        \cup [ tag : {SimpleBulkQuoteMessageCode}, body : SimpleBulkQuoteMessage ]
        \cup [ tag : {SimpleBulkQuoteResponseCode}, body : SimpleBulkQuoteResponse ]
        \cup [ tag : {SimpleEnhancedQuoteEQuoteMessageCode}, body : SimpleEnhancedQuoteEQuoteMessage ]
        \cup [ tag : {ComplexEnhancedQuoteEQuoteMessageCode}, body : ComplexEnhancedQuoteEQuoteMessage ]
        \cup [ tag : {SimpleMassQuoteCancelRequestCode}, body : SimpleMassQuoteCancelRequest ]
        \cup [ tag : {SimpleMassQuoteCancelResponseCode}, body : SimpleMassQuoteCancelResponse ]
        \cup [ tag : {MassLiquidityCancelRequestSimpleAndComplexCode}, body : MassLiquidityCancelRequestSimpleAndComplex ]
        \cup [ tag : {MassLiquidityCancelResponseCode}, body : MassLiquidityCancelResponse ]
        \cup [ tag : {SimpleQuoteProtectionResetRequestCode}, body : SimpleQuoteProtectionResetRequest ]
        \cup [ tag : {SimpleQuoteProtectionResetResponseCode}, body : SimpleQuoteProtectionResetResponse ]
        \cup [ tag : {LiquidityProtectionResetRequestCode}, body : LiquidityProtectionResetRequest ]
        \cup [ tag : {LiquidityProtectionResetResponseCode}, body : LiquidityProtectionResetResponse ]
        \cup [ tag : {SingleSideLiquidityProtectionResetRequestCode}, body : SingleSideLiquidityProtectionResetRequest ]
        \cup [ tag : {SingleSideLiquidityProtectionResetResponseCode}, body : SingleSideLiquidityProtectionResetResponse ]
        \cup [ tag : {SimpleQuoteProtectionTriggerNotificationCode}, body : SimpleQuoteProtectionTriggerNotification ]
        \cup [ tag : {ComplexLiquidityProtectionTriggerNotificationCode}, body : ComplexLiquidityProtectionTriggerNotification ]
        \cup [ tag : {CancelNotificationCode2}, body : CancelNotification2 ]

EncodeUnsequencedMessage(message) ==
    CASE message.tag = SimpleArmSettingsUpdateRequestCode -> EncodeSimpleArmSettingsUpdateRequest(message.body)
      [] message.tag = SimpleArmSettingsUpdateResponseCode -> EncodeSimpleArmSettingsUpdateResponse(message.body)
      [] message.tag = Arm2UnderlyingLevelProtectionSettingsUpdateRequestCode -> EncodeArm2UnderlyingLevelProtectionSettingsUpdateRequest(message.body)
      [] message.tag = Arm2UnderlyingLevelProtectionSettingsUpdateResponseCode -> EncodeArm2UnderlyingLevelProtectionSettingsUpdateResponse(message.body)
      [] message.tag = SimpleBulkQuoteMessageCode -> EncodeSimpleBulkQuoteMessage(message.body)
      [] message.tag = SimpleBulkQuoteResponseCode -> EncodeSimpleBulkQuoteResponse(message.body)
      [] message.tag = SimpleEnhancedQuoteEQuoteMessageCode -> EncodeSimpleEnhancedQuoteEQuoteMessage(message.body)
      [] message.tag = ComplexEnhancedQuoteEQuoteMessageCode -> EncodeComplexEnhancedQuoteEQuoteMessage(message.body)
      [] message.tag = SimpleMassQuoteCancelRequestCode -> EncodeSimpleMassQuoteCancelRequest(message.body)
      [] message.tag = SimpleMassQuoteCancelResponseCode -> EncodeSimpleMassQuoteCancelResponse(message.body)
      [] message.tag = MassLiquidityCancelRequestSimpleAndComplexCode -> EncodeMassLiquidityCancelRequestSimpleAndComplex(message.body)
      [] message.tag = MassLiquidityCancelResponseCode -> EncodeMassLiquidityCancelResponse(message.body)
      [] message.tag = SimpleQuoteProtectionResetRequestCode -> EncodeSimpleQuoteProtectionResetRequest(message.body)
      [] message.tag = SimpleQuoteProtectionResetResponseCode -> EncodeSimpleQuoteProtectionResetResponse(message.body)
      [] message.tag = LiquidityProtectionResetRequestCode -> EncodeLiquidityProtectionResetRequest(message.body)
      [] message.tag = LiquidityProtectionResetResponseCode -> EncodeLiquidityProtectionResetResponse(message.body)
      [] message.tag = SingleSideLiquidityProtectionResetRequestCode -> EncodeSingleSideLiquidityProtectionResetRequest(message.body)
      [] message.tag = SingleSideLiquidityProtectionResetResponseCode -> EncodeSingleSideLiquidityProtectionResetResponse(message.body)
      [] message.tag = SimpleQuoteProtectionTriggerNotificationCode -> EncodeSimpleQuoteProtectionTriggerNotification(message.body)
      [] message.tag = ComplexLiquidityProtectionTriggerNotificationCode -> EncodeComplexLiquidityProtectionTriggerNotification(message.body)
      [] message.tag = CancelNotificationCode2 -> EncodeCancelNotification2(message.body)

DecodeUnsequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = SimpleArmSettingsUpdateRequestCode -> DecodeSimpleArmSettingsUpdateRequest(bytes)
              [] tag = SimpleArmSettingsUpdateResponseCode -> DecodeSimpleArmSettingsUpdateResponse(bytes)
              [] tag = Arm2UnderlyingLevelProtectionSettingsUpdateRequestCode -> DecodeArm2UnderlyingLevelProtectionSettingsUpdateRequest(bytes)
              [] tag = Arm2UnderlyingLevelProtectionSettingsUpdateResponseCode -> DecodeArm2UnderlyingLevelProtectionSettingsUpdateResponse(bytes)
              [] tag = SimpleBulkQuoteMessageCode -> DecodeSimpleBulkQuoteMessage(bytes)
              [] tag = SimpleBulkQuoteResponseCode -> DecodeSimpleBulkQuoteResponse(bytes)
              [] tag = SimpleEnhancedQuoteEQuoteMessageCode -> DecodeSimpleEnhancedQuoteEQuoteMessage(bytes)
              [] tag = ComplexEnhancedQuoteEQuoteMessageCode -> DecodeComplexEnhancedQuoteEQuoteMessage(bytes)
              [] tag = SimpleMassQuoteCancelRequestCode -> DecodeSimpleMassQuoteCancelRequest(bytes)
              [] tag = SimpleMassQuoteCancelResponseCode -> DecodeSimpleMassQuoteCancelResponse(bytes)
              [] tag = MassLiquidityCancelRequestSimpleAndComplexCode -> DecodeMassLiquidityCancelRequestSimpleAndComplex(bytes)
              [] tag = MassLiquidityCancelResponseCode -> DecodeMassLiquidityCancelResponse(bytes)
              [] tag = SimpleQuoteProtectionResetRequestCode -> DecodeSimpleQuoteProtectionResetRequest(bytes)
              [] tag = SimpleQuoteProtectionResetResponseCode -> DecodeSimpleQuoteProtectionResetResponse(bytes)
              [] tag = LiquidityProtectionResetRequestCode -> DecodeLiquidityProtectionResetRequest(bytes)
              [] tag = LiquidityProtectionResetResponseCode -> DecodeLiquidityProtectionResetResponse(bytes)
              [] tag = SingleSideLiquidityProtectionResetRequestCode -> DecodeSingleSideLiquidityProtectionResetRequest(bytes)
              [] tag = SingleSideLiquidityProtectionResetResponseCode -> DecodeSingleSideLiquidityProtectionResetResponse(bytes)
              [] tag = SimpleQuoteProtectionTriggerNotificationCode -> DecodeSimpleQuoteProtectionTriggerNotification(bytes)
              [] tag = ComplexLiquidityProtectionTriggerNotificationCode -> DecodeComplexLiquidityProtectionTriggerNotification(bytes)
              [] tag = CancelNotificationCode2 -> DecodeCancelNotification2(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroUnsequencedMessage == [tag |-> SimpleArmSettingsUpdateRequestCode, body |-> ZeroSimpleArmSettingsUpdateRequest]

(* Each Unsequenced Message in turn, at the values the message it names is checked at *)
CheckedUnsequencedMessage ==
    { [tag |-> SimpleArmSettingsUpdateRequestCode, body |-> one] : one \in CheckedSimpleArmSettingsUpdateRequest }
        \cup { [tag |-> SimpleArmSettingsUpdateResponseCode, body |-> one] : one \in CheckedSimpleArmSettingsUpdateResponse }
        \cup { [tag |-> Arm2UnderlyingLevelProtectionSettingsUpdateRequestCode, body |-> one] : one \in CheckedArm2UnderlyingLevelProtectionSettingsUpdateRequest }
        \cup { [tag |-> Arm2UnderlyingLevelProtectionSettingsUpdateResponseCode, body |-> one] : one \in CheckedArm2UnderlyingLevelProtectionSettingsUpdateResponse }
        \cup { [tag |-> SimpleBulkQuoteMessageCode, body |-> one] : one \in CheckedSimpleBulkQuoteMessage }
        \cup { [tag |-> SimpleBulkQuoteResponseCode, body |-> one] : one \in CheckedSimpleBulkQuoteResponse }
        \cup { [tag |-> SimpleEnhancedQuoteEQuoteMessageCode, body |-> one] : one \in CheckedSimpleEnhancedQuoteEQuoteMessage }
        \cup { [tag |-> ComplexEnhancedQuoteEQuoteMessageCode, body |-> one] : one \in CheckedComplexEnhancedQuoteEQuoteMessage }
        \cup { [tag |-> SimpleMassQuoteCancelRequestCode, body |-> one] : one \in CheckedSimpleMassQuoteCancelRequest }
        \cup { [tag |-> SimpleMassQuoteCancelResponseCode, body |-> one] : one \in CheckedSimpleMassQuoteCancelResponse }
        \cup { [tag |-> MassLiquidityCancelRequestSimpleAndComplexCode, body |-> one] : one \in CheckedMassLiquidityCancelRequestSimpleAndComplex }
        \cup { [tag |-> MassLiquidityCancelResponseCode, body |-> one] : one \in CheckedMassLiquidityCancelResponse }
        \cup { [tag |-> SimpleQuoteProtectionResetRequestCode, body |-> one] : one \in CheckedSimpleQuoteProtectionResetRequest }
        \cup { [tag |-> SimpleQuoteProtectionResetResponseCode, body |-> one] : one \in CheckedSimpleQuoteProtectionResetResponse }
        \cup { [tag |-> LiquidityProtectionResetRequestCode, body |-> one] : one \in CheckedLiquidityProtectionResetRequest }
        \cup { [tag |-> LiquidityProtectionResetResponseCode, body |-> one] : one \in CheckedLiquidityProtectionResetResponse }
        \cup { [tag |-> SingleSideLiquidityProtectionResetRequestCode, body |-> one] : one \in CheckedSingleSideLiquidityProtectionResetRequest }
        \cup { [tag |-> SingleSideLiquidityProtectionResetResponseCode, body |-> one] : one \in CheckedSingleSideLiquidityProtectionResetResponse }
        \cup { [tag |-> SimpleQuoteProtectionTriggerNotificationCode, body |-> one] : one \in CheckedSimpleQuoteProtectionTriggerNotification }
        \cup { [tag |-> ComplexLiquidityProtectionTriggerNotificationCode, body |-> one] : one \in CheckedComplexLiquidityProtectionTriggerNotification }
        \cup { [tag |-> CancelNotificationCode2, body |-> one] : one \in CheckedCancelNotification2 }

(***************************************************************************)
(* Unsequenced Data Packet                                                 *)
(***************************************************************************)

UnsequencedDataPacket ==
    [ unsequencedMessage : UnsequencedMessage ]

EncodeUnsequencedDataPacket(message) ==
    EncodeUIntBE(message.unsequencedMessage.tag, 2)
        \o EncodeUnsequencedMessage(message.unsequencedMessage)

DecodeUnsequencedDataPacket(bytes) ==
    LET unsequencedMessageType == ReadUIntBE(bytes, 2) IN IF ~unsequencedMessageType.ok THEN Fail ELSE
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
    [ sesmVersion             : Sample(5),
      username                : Sample(5),
      computerId              : Sample(8),
      applicationProtocol     : Sample(8),
      requestedSession        : Sample(1),
      requestedSequenceNumber : Sample(8) ]

EncodeLoginRequest(message) ==
    message.sesmVersion
        \o message.username
        \o message.computerId
        \o message.applicationProtocol
        \o message.requestedSession
        \o message.requestedSequenceNumber

DecodeLoginRequest(bytes) ==
    LET sesmVersion == ReadBytes(bytes, 5) IN IF ~sesmVersion.ok THEN Fail ELSE
    LET username == ReadBytes(sesmVersion.rest, 5) IN IF ~username.ok THEN Fail ELSE
    LET computerId == ReadBytes(username.rest, 8) IN IF ~computerId.ok THEN Fail ELSE
    LET applicationProtocol == ReadBytes(computerId.rest, 8) IN IF ~applicationProtocol.ok THEN Fail ELSE
    LET requestedSession == ReadBytes(applicationProtocol.rest, 1) IN IF ~requestedSession.ok THEN Fail ELSE
    LET requestedSequenceNumber == ReadBytes(requestedSession.rest, 8) IN IF ~requestedSequenceNumber.ok THEN Fail ELSE
    Ok([ sesmVersion             |-> sesmVersion.value,
         username                |-> username.value,
         computerId              |-> computerId.value,
         applicationProtocol     |-> applicationProtocol.value,
         requestedSession        |-> requestedSession.value,
         requestedSequenceNumber |-> requestedSequenceNumber.value ], requestedSequenceNumber.rest)

ZeroLoginRequest ==
    [ sesmVersion             |-> [i \in 1 .. 5 |-> 0],
      username                |-> [i \in 1 .. 5 |-> 0],
      computerId              |-> [i \in 1 .. 8 |-> 0],
      applicationProtocol     |-> [i \in 1 .. 8 |-> 0],
      requestedSession        |-> [i \in 1 .. 1 |-> 0],
      requestedSequenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Login Request at zero, then each field in turn at the values it is checked at *)
CheckedLoginRequest ==
    { ZeroLoginRequest }
        \cup { [ZeroLoginRequest EXCEPT !.sesmVersion = one] : one \in Sample(5) }
        \cup { [ZeroLoginRequest EXCEPT !.username = one] : one \in Sample(5) }
        \cup { [ZeroLoginRequest EXCEPT !.computerId = one] : one \in Sample(8) }
        \cup { [ZeroLoginRequest EXCEPT !.applicationProtocol = one] : one \in Sample(8) }
        \cup { [ZeroLoginRequest EXCEPT !.requestedSession = one] : one \in Sample(1) }
        \cup { [ZeroLoginRequest EXCEPT !.requestedSequenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Login Response: 10 bytes                                                *)
(***************************************************************************)

LoginResponse ==
    [ loginStatus           : Sample(1),
      sessionId             : Sample(1),
      highestSequenceNumber : Sample(8) ]

EncodeLoginResponse(message) ==
    message.loginStatus
        \o message.sessionId
        \o message.highestSequenceNumber

DecodeLoginResponse(bytes) ==
    LET loginStatus == ReadBytes(bytes, 1) IN IF ~loginStatus.ok THEN Fail ELSE
    LET sessionId == ReadBytes(loginStatus.rest, 1) IN IF ~sessionId.ok THEN Fail ELSE
    LET highestSequenceNumber == ReadBytes(sessionId.rest, 8) IN IF ~highestSequenceNumber.ok THEN Fail ELSE
    Ok([ loginStatus           |-> loginStatus.value,
         sessionId             |-> sessionId.value,
         highestSequenceNumber |-> highestSequenceNumber.value ], highestSequenceNumber.rest)

ZeroLoginResponse ==
    [ loginStatus           |-> [i \in 1 .. 1 |-> 0],
      sessionId             |-> [i \in 1 .. 1 |-> 0],
      highestSequenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Login Response at zero, then each field in turn at the values it is checked at *)
CheckedLoginResponse ==
    { ZeroLoginResponse }
        \cup { [ZeroLoginResponse EXCEPT !.loginStatus = one] : one \in Sample(1) }
        \cup { [ZeroLoginResponse EXCEPT !.sessionId = one] : one \in Sample(1) }
        \cup { [ZeroLoginResponse EXCEPT !.highestSequenceNumber = one] : one \in Sample(8) }

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
    [ goodbyeReason : Sample(1),
      logoutText    : SampleBytes ]

EncodeGoodbyePacket(message) ==
    message.goodbyeReason
        \o message.logoutText

DecodeGoodbyePacket(bytes) ==
    LET goodbyeReason == ReadBytes(bytes, 1) IN IF ~goodbyeReason.ok THEN Fail ELSE
    LET logoutText == Ok(goodbyeReason.rest, << >>) IN IF ~logoutText.ok THEN Fail ELSE
    Ok([ goodbyeReason |-> goodbyeReason.value,
         logoutText    |-> logoutText.value ], logoutText.rest)

ZeroGoodbyePacket ==
    [ goodbyeReason |-> [i \in 1 .. 1 |-> 0],
      logoutText    |-> << >> ]

(* Goodbye Packet at zero, then each field in turn at the values it is checked at *)
CheckedGoodbyePacket ==
    { ZeroGoodbyePacket }
        \cup { [ZeroGoodbyePacket EXCEPT !.goodbyeReason = one] : one \in Sample(1) }
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

SequencedDataPacketCode == 83  \* "S"
UnsequencedDataPacketCode == 85  \* "U"
LoginRequestCode == 76  \* "L"
LoginResponseCode == 82  \* "R"
SynchronizationCompleteCode == 67  \* "C"
RetransmissionRequestCode == 65  \* "A"
LogoutRequestCode == 88  \* "X"
GoodbyePacketCode == 71  \* "G"
EndOfSessionCode == 69  \* "E"
ServerHeartbeatCode == 48  \* "0"
ClientHeartbeatCode == 49  \* "1"
TestPacketCode == 84  \* "T"

SesmPayload ==
    [ tag : {SequencedDataPacketCode}, body : SequencedDataPacket ]
        \cup [ tag : {UnsequencedDataPacketCode}, body : UnsequencedDataPacket ]
        \cup [ tag : {LoginRequestCode}, body : LoginRequest ]
        \cup [ tag : {LoginResponseCode}, body : LoginResponse ]
        \cup [ tag : {SynchronizationCompleteCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {RetransmissionRequestCode}, body : RetransmissionRequest ]
        \cup [ tag : {LogoutRequestCode}, body : LogoutRequest ]
        \cup [ tag : {GoodbyePacketCode}, body : GoodbyePacket ]
        \cup [ tag : {EndOfSessionCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ServerHeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ClientHeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {TestPacketCode}, body : TestPacket ]

EncodeSesmPayload(message) ==
    CASE message.tag = SequencedDataPacketCode -> EncodeSequencedDataPacket(message.body)
      [] message.tag = UnsequencedDataPacketCode -> EncodeUnsequencedDataPacket(message.body)
      [] message.tag = LoginRequestCode -> EncodeLoginRequest(message.body)
      [] message.tag = LoginResponseCode -> EncodeLoginResponse(message.body)
      [] message.tag = SynchronizationCompleteCode -> << >>
      [] message.tag = RetransmissionRequestCode -> EncodeRetransmissionRequest(message.body)
      [] message.tag = LogoutRequestCode -> EncodeLogoutRequest(message.body)
      [] message.tag = GoodbyePacketCode -> EncodeGoodbyePacket(message.body)
      [] message.tag = EndOfSessionCode -> << >>
      [] message.tag = ServerHeartbeatCode -> << >>
      [] message.tag = ClientHeartbeatCode -> << >>
      [] message.tag = TestPacketCode -> EncodeTestPacket(message.body)

DecodeSesmPayload(tag, bytes) ==
    LET read ==
            CASE tag = SequencedDataPacketCode -> DecodeSequencedDataPacket(bytes)
              [] tag = UnsequencedDataPacketCode -> DecodeUnsequencedDataPacket(bytes)
              [] tag = LoginRequestCode -> DecodeLoginRequest(bytes)
              [] tag = LoginResponseCode -> DecodeLoginResponse(bytes)
              [] tag = SynchronizationCompleteCode -> Ok([empty |-> 0], bytes)
              [] tag = RetransmissionRequestCode -> DecodeRetransmissionRequest(bytes)
              [] tag = LogoutRequestCode -> DecodeLogoutRequest(bytes)
              [] tag = GoodbyePacketCode -> DecodeGoodbyePacket(bytes)
              [] tag = EndOfSessionCode -> Ok([empty |-> 0], bytes)
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
        \cup { [tag |-> SynchronizationCompleteCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> RetransmissionRequestCode, body |-> one] : one \in CheckedRetransmissionRequest }
        \cup { [tag |-> LogoutRequestCode, body |-> one] : one \in CheckedLogoutRequest }
        \cup { [tag |-> GoodbyePacketCode, body |-> one] : one \in CheckedGoodbyePacket }
        \cup { [tag |-> EndOfSessionCode, body |-> [empty |-> 0]] }
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

(* Does a Sesm Tcp Packet end the session? Nothing may follow one that does *)
EndsSessionSesmTcpPacket(message) == message.sesmPayload.tag \in {EndOfSessionCode}

(* A run of Sesm Tcp Packet, written one after another *)
RECURSIVE EncodeSesmTcpPacketList(_)
EncodeSesmTcpPacketList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSesmTcpPacket(Head(messages)) \o EncodeSesmTcpPacketList(Tail(messages))

(* As many Sesm Tcp Packet as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
(* Only the last of them may end the session, so one that does with bytes left fails *)
RECURSIVE ReadSesmTcpPacketAll(_)
ReadSesmTcpPacketAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeSesmTcpPacket(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE IF EndsSessionSesmTcpPacket(one.value) /\ one.rest # << >> THEN Fail
             ELSE LET more == ReadSesmTcpPacketAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Sesm Tcp Packet of each kind, for the lists that carry them *)
OneSesmTcpPacket ==
    { [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> SequencedDataPacketCode, body |-> ZeroSequencedDataPacket]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> UnsequencedDataPacketCode, body |-> ZeroUnsequencedDataPacket]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> LoginRequestCode, body |-> ZeroLoginRequest]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> LoginResponseCode, body |-> ZeroLoginResponse]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> SynchronizationCompleteCode, body |-> [empty |-> 0]]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> RetransmissionRequestCode, body |-> ZeroRetransmissionRequest]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> LogoutRequestCode, body |-> ZeroLogoutRequest]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> GoodbyePacketCode, body |-> ZeroGoodbyePacket]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> EndOfSessionCode, body |-> [empty |-> 0]]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> ServerHeartbeatCode, body |-> [empty |-> 0]]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> ClientHeartbeatCode, body |-> [empty |-> 0]]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> TestPacketCode, body |-> ZeroTestPacket]] }

(* The runs of Sesm Tcp Packet checked: none, one, two of a kind and each kind followed by *)
(* another, keeping those in which only the last may end the session *)
SampleSesmTcpPacketLists ==
    { run \in SampleLists(OneSesmTcpPacket) \cup { <<one, other>> : one \in OneSesmTcpPacket, other \in OneSesmTcpPacket } :
          \A at \in 1 .. Len(run) - 1 : ~EndsSessionSesmTcpPacket(run[at]) }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ sesmTcpPacket : SampleSesmTcpPacketLists ]

EncodePacket(message) ==
    EncodeSesmTcpPacketList(message.sesmTcpPacket)

DecodePacket(bytes) ==
    LET sesmTcpPacket == ReadSesmTcpPacketAll(bytes) IN IF ~sesmTcpPacket.ok THEN Fail ELSE
    Ok([ sesmTcpPacket |-> sesmTcpPacket.value ], sesmTcpPacket.rest)

ZeroPacket ==
    [ sesmTcpPacket |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.sesmTcpPacket = one] : one \in SampleSesmTcpPacketLists }

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

(* Every Simple Series Update decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleSeriesUpdate ==
    \A message \in CheckedSimpleSeriesUpdate :
        LET read == DecodeSimpleSeriesUpdate(EncodeSimpleSeriesUpdate(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Valid Quote Width For Opening decodes back to what was encoded, and leaves nothing over *)
RoundTripValidQuoteWidthForOpening ==
    \A message \in CheckedValidQuoteWidthForOpening :
        LET read == DecodeValidQuoteWidthForOpening(EncodeValidQuoteWidthForOpening(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Enhanced Quote E Quote Response decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleEnhancedQuoteEQuoteResponse ==
    \A message \in CheckedSimpleEnhancedQuoteEQuoteResponse :
        LET read == DecodeSimpleEnhancedQuoteEQuoteResponse(EncodeSimpleEnhancedQuoteEQuoteResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Enhanced Quote E Quote Response decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexEnhancedQuoteEQuoteResponse ==
    \A message \in CheckedComplexEnhancedQuoteEQuoteResponse :
        LET read == DecodeComplexEnhancedQuoteEQuoteResponse(EncodeComplexEnhancedQuoteEQuoteResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every System State Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripSystemStateNotification ==
    \A message \in CheckedSystemStateNotification :
        LET read == DecodeSystemStateNotification(EncodeSystemStateNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Product Trading Status Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripProductTradingStatusNotification ==
    \A message \in CheckedProductTradingStatusNotification :
        LET read == DecodeProductTradingStatusNotification(EncodeProductTradingStatusNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Underlying Trading Status Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripUnderlyingTradingStatusNotification ==
    \A message \in CheckedUnderlyingTradingStatusNotification :
        LET read == DecodeUnderlyingTradingStatusNotification(EncodeUnderlyingTradingStatusNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Width Relief Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteWidthReliefNotification ==
    \A message \in CheckedQuoteWidthReliefNotification :
        LET read == DecodeQuoteWidthReliefNotification(EncodeQuoteWidthReliefNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Arm Protection Settings Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleArmProtectionSettingsNotification ==
    \A message \in CheckedSimpleArmProtectionSettingsNotification :
        LET read == DecodeSimpleArmProtectionSettingsNotification(EncodeSimpleArmProtectionSettingsNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Arm 2 Underlying Level Protection Settings Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripArm2UnderlyingLevelProtectionSettingsNotification ==
    \A message \in CheckedArm2UnderlyingLevelProtectionSettingsNotification :
        LET read == DecodeArm2UnderlyingLevelProtectionSettingsNotification(EncodeArm2UnderlyingLevelProtectionSettingsNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Side Liquidity Protection Trigger Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleSideLiquidityProtectionTriggerNotification ==
    \A message \in CheckedSingleSideLiquidityProtectionTriggerNotification :
        LET read == DecodeSingleSideLiquidityProtectionTriggerNotification(EncodeSingleSideLiquidityProtectionTriggerNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Arm 2 Underlying Level Protection Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripArm2UnderlyingLevelProtectionNotification ==
    \A message \in CheckedArm2UnderlyingLevelProtectionNotification :
        LET read == DecodeArm2UnderlyingLevelProtectionNotification(EncodeArm2UnderlyingLevelProtectionNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Arm 2 Firm Level Protection Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripArm2FirmLevelProtectionNotification ==
    \A message \in CheckedArm2FirmLevelProtectionNotification :
        LET read == DecodeArm2FirmLevelProtectionNotification(EncodeArm2FirmLevelProtectionNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Leg decodes back to what was encoded, and leaves nothing over *)
RoundTripLeg ==
    \A message \in CheckedLeg :
        LET read == DecodeLeg(EncodeLeg(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Strategy Definition Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexStrategyDefinitionNotification ==
    \A message \in CheckedComplexStrategyDefinitionNotification :
        LET read == DecodeComplexStrategyDefinitionNotification(EncodeComplexStrategyDefinitionNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelNotification ==
    \A message \in CheckedCancelNotification :
        LET read == DecodeCancelNotification(EncodeCancelNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Execution Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionExecutionNotification ==
    \A message \in CheckedOptionExecutionNotification :
        LET read == DecodeOptionExecutionNotification(EncodeOptionExecutionNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stock Leg Execution Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripStockLegExecutionNotification ==
    \A message \in CheckedStockLegExecutionNotification :
        LET read == DecodeStockLegExecutionNotification(EncodeStockLegExecutionNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sequenced Data Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripSequencedDataPacket ==
    \A message \in CheckedSequencedDataPacket :
        LET read == DecodeSequencedDataPacket(EncodeSequencedDataPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Arm Settings Update Request decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleArmSettingsUpdateRequest ==
    \A message \in CheckedSimpleArmSettingsUpdateRequest :
        LET read == DecodeSimpleArmSettingsUpdateRequest(EncodeSimpleArmSettingsUpdateRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Arm Settings Update Response decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleArmSettingsUpdateResponse ==
    \A message \in CheckedSimpleArmSettingsUpdateResponse :
        LET read == DecodeSimpleArmSettingsUpdateResponse(EncodeSimpleArmSettingsUpdateResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Arm 2 Underlying Level Protection Settings Update Request decodes back to what was encoded, and leaves nothing over *)
RoundTripArm2UnderlyingLevelProtectionSettingsUpdateRequest ==
    \A message \in CheckedArm2UnderlyingLevelProtectionSettingsUpdateRequest :
        LET read == DecodeArm2UnderlyingLevelProtectionSettingsUpdateRequest(EncodeArm2UnderlyingLevelProtectionSettingsUpdateRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Arm 2 Underlying Level Protection Settings Update Response decodes back to what was encoded, and leaves nothing over *)
RoundTripArm2UnderlyingLevelProtectionSettingsUpdateResponse ==
    \A message \in CheckedArm2UnderlyingLevelProtectionSettingsUpdateResponse :
        LET read == DecodeArm2UnderlyingLevelProtectionSettingsUpdateResponse(EncodeArm2UnderlyingLevelProtectionSettingsUpdateResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Side Quote decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleSideQuote ==
    \A message \in CheckedSingleSideQuote :
        LET read == DecodeSingleSideQuote(EncodeSingleSideQuote(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Bulk Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleBulkQuoteMessage ==
    \A message \in CheckedSimpleBulkQuoteMessage :
        LET read == DecodeSimpleBulkQuoteMessage(EncodeSimpleBulkQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Side Quote Response decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleSideQuoteResponse ==
    \A message \in CheckedSingleSideQuoteResponse :
        LET read == DecodeSingleSideQuoteResponse(EncodeSingleSideQuoteResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Bulk Quote Response decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleBulkQuoteResponse ==
    \A message \in CheckedSimpleBulkQuoteResponse :
        LET read == DecodeSimpleBulkQuoteResponse(EncodeSimpleBulkQuoteResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Enhanced Quote E Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleEnhancedQuoteEQuoteMessage ==
    \A message \in CheckedSimpleEnhancedQuoteEQuoteMessage :
        LET read == DecodeSimpleEnhancedQuoteEQuoteMessage(EncodeSimpleEnhancedQuoteEQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Enhanced Quote E Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexEnhancedQuoteEQuoteMessage ==
    \A message \in CheckedComplexEnhancedQuoteEQuoteMessage :
        LET read == DecodeComplexEnhancedQuoteEQuoteMessage(EncodeComplexEnhancedQuoteEQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Mass Quote Cancel Request decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleMassQuoteCancelRequest ==
    \A message \in CheckedSimpleMassQuoteCancelRequest :
        LET read == DecodeSimpleMassQuoteCancelRequest(EncodeSimpleMassQuoteCancelRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Mass Quote Cancel Response decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleMassQuoteCancelResponse ==
    \A message \in CheckedSimpleMassQuoteCancelResponse :
        LET read == DecodeSimpleMassQuoteCancelResponse(EncodeSimpleMassQuoteCancelResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Liquidity Cancel Request Simple And Complex decodes back to what was encoded, and leaves nothing over *)
RoundTripMassLiquidityCancelRequestSimpleAndComplex ==
    \A message \in CheckedMassLiquidityCancelRequestSimpleAndComplex :
        LET read == DecodeMassLiquidityCancelRequestSimpleAndComplex(EncodeMassLiquidityCancelRequestSimpleAndComplex(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Liquidity Cancel Response decodes back to what was encoded, and leaves nothing over *)
RoundTripMassLiquidityCancelResponse ==
    \A message \in CheckedMassLiquidityCancelResponse :
        LET read == DecodeMassLiquidityCancelResponse(EncodeMassLiquidityCancelResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Quote Protection Reset Request decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleQuoteProtectionResetRequest ==
    \A message \in CheckedSimpleQuoteProtectionResetRequest :
        LET read == DecodeSimpleQuoteProtectionResetRequest(EncodeSimpleQuoteProtectionResetRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Quote Protection Reset Response decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleQuoteProtectionResetResponse ==
    \A message \in CheckedSimpleQuoteProtectionResetResponse :
        LET read == DecodeSimpleQuoteProtectionResetResponse(EncodeSimpleQuoteProtectionResetResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Liquidity Protection Reset Request decodes back to what was encoded, and leaves nothing over *)
RoundTripLiquidityProtectionResetRequest ==
    \A message \in CheckedLiquidityProtectionResetRequest :
        LET read == DecodeLiquidityProtectionResetRequest(EncodeLiquidityProtectionResetRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Liquidity Protection Reset Response decodes back to what was encoded, and leaves nothing over *)
RoundTripLiquidityProtectionResetResponse ==
    \A message \in CheckedLiquidityProtectionResetResponse :
        LET read == DecodeLiquidityProtectionResetResponse(EncodeLiquidityProtectionResetResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Side Liquidity Protection Reset Request decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleSideLiquidityProtectionResetRequest ==
    \A message \in CheckedSingleSideLiquidityProtectionResetRequest :
        LET read == DecodeSingleSideLiquidityProtectionResetRequest(EncodeSingleSideLiquidityProtectionResetRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Side Liquidity Protection Reset Response decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleSideLiquidityProtectionResetResponse ==
    \A message \in CheckedSingleSideLiquidityProtectionResetResponse :
        LET read == DecodeSingleSideLiquidityProtectionResetResponse(EncodeSingleSideLiquidityProtectionResetResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Quote Protection Trigger Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleQuoteProtectionTriggerNotification ==
    \A message \in CheckedSimpleQuoteProtectionTriggerNotification :
        LET read == DecodeSimpleQuoteProtectionTriggerNotification(EncodeSimpleQuoteProtectionTriggerNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Liquidity Protection Trigger Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexLiquidityProtectionTriggerNotification ==
    \A message \in CheckedComplexLiquidityProtectionTriggerNotification :
        LET read == DecodeComplexLiquidityProtectionTriggerNotification(EncodeComplexLiquidityProtectionTriggerNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelNotification2 ==
    \A message \in CheckedCancelNotification2 :
        LET read == DecodeCancelNotification2(EncodeCancelNotification2(message))
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

(* Every Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripPacket ==
    \A message \in CheckedPacket :
        LET read == DecodePacket(EncodePacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Sequenced Message is selected by the Sequenced Message Type it is written under *)
SelectsSequencedMessage ==
    \A message \in CheckedSequencedMessage :
        LET sent == EncodeSequencedMessage(message)
            read == DecodeSequencedMessage(message.tag, sent)
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

(* A Sesm Tcp Packet that ends the session is the last of its Packet: a run with one after it does not decode *)
EndsSessionLastSesmTcpPacket ==
    \A last \in { one \in OneSesmTcpPacket : EndsSessionSesmTcpPacket(one) } :
        \A after \in OneSesmTcpPacket :
            ~ReadSesmTcpPacketAll(EncodeSesmTcpPacketList(<<last, after>>)).ok

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
