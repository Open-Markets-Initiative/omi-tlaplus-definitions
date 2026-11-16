---------------- MODULE MiaxOptions_ExpressInterface_v1_3_c ----------------
(***************************************************************************)
(* Miami International Holdings Express Interface v1.3.c                   *)
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
(* Series Update: 76 bytes                                                 *)
(***************************************************************************)

SeriesUpdate ==
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

EncodeSeriesUpdate(message) ==
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

DecodeSeriesUpdate(bytes) ==
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

ZeroSeriesUpdate ==
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

(* Series Update at zero, then each field in turn at the values it is checked at *)
CheckedSeriesUpdate ==
    { ZeroSeriesUpdate }
        \cup { [ZeroSeriesUpdate EXCEPT !.productAddUpdateTime = one] : one \in Sample(8) }
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
        \cup { [ZeroSeriesUpdate EXCEPT !.quoteAcceptanceIncrementIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSeriesUpdate EXCEPT !.openingUnderlyingMarketCode = one] : one \in Sample(1) }
        \cup { [ZeroSeriesUpdate EXCEPT !.priorityQuoteWidth = one] : one \in Sample(4) }
        \cup { [ZeroSeriesUpdate EXCEPT !.reserved8 = one] : one \in Sample(8) }

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
(* Enhanced Quote E Quote Response: 17 bytes                               *)
(***************************************************************************)

EnhancedQuoteEQuoteResponse ==
    [ clientMessageId     : Sample(4),
      mpid                : Sample(4),
      eQuoteId            : Sample(8),
      eQuoteRequestStatus : Sample(1) ]

EncodeEnhancedQuoteEQuoteResponse(message) ==
    message.clientMessageId
        \o message.mpid
        \o message.eQuoteId
        \o message.eQuoteRequestStatus

DecodeEnhancedQuoteEQuoteResponse(bytes) ==
    LET clientMessageId == ReadBytes(bytes, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET mpid == ReadBytes(clientMessageId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET eQuoteId == ReadBytes(mpid.rest, 8) IN IF ~eQuoteId.ok THEN Fail ELSE
    LET eQuoteRequestStatus == ReadBytes(eQuoteId.rest, 1) IN IF ~eQuoteRequestStatus.ok THEN Fail ELSE
    Ok([ clientMessageId     |-> clientMessageId.value,
         mpid                |-> mpid.value,
         eQuoteId            |-> eQuoteId.value,
         eQuoteRequestStatus |-> eQuoteRequestStatus.value ], eQuoteRequestStatus.rest)

ZeroEnhancedQuoteEQuoteResponse ==
    [ clientMessageId     |-> [i \in 1 .. 4 |-> 0],
      mpid                |-> [i \in 1 .. 4 |-> 0],
      eQuoteId            |-> [i \in 1 .. 8 |-> 0],
      eQuoteRequestStatus |-> [i \in 1 .. 1 |-> 0] ]

(* Enhanced Quote E Quote Response at zero, then each field in turn at the values it is checked at *)
CheckedEnhancedQuoteEQuoteResponse ==
    { ZeroEnhancedQuoteEQuoteResponse }
        \cup { [ZeroEnhancedQuoteEQuoteResponse EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroEnhancedQuoteEQuoteResponse EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroEnhancedQuoteEQuoteResponse EXCEPT !.eQuoteId = one] : one \in Sample(8) }
        \cup { [ZeroEnhancedQuoteEQuoteResponse EXCEPT !.eQuoteRequestStatus = one] : one \in Sample(1) }

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
(* Trading Status Notification: 21 bytes                                   *)
(***************************************************************************)

TradingStatusNotification ==
    [ notificationTime  : Sample(8),
      productId         : Sample(4),
      tradingStatus     : Sample(1),
      expectedEventTime : Sample(8) ]

EncodeTradingStatusNotification(message) ==
    message.notificationTime
        \o message.productId
        \o message.tradingStatus
        \o message.expectedEventTime

DecodeTradingStatusNotification(bytes) ==
    LET notificationTime == ReadBytes(bytes, 8) IN IF ~notificationTime.ok THEN Fail ELSE
    LET productId == ReadBytes(notificationTime.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(productId.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET expectedEventTime == ReadBytes(tradingStatus.rest, 8) IN IF ~expectedEventTime.ok THEN Fail ELSE
    Ok([ notificationTime  |-> notificationTime.value,
         productId         |-> productId.value,
         tradingStatus     |-> tradingStatus.value,
         expectedEventTime |-> expectedEventTime.value ], expectedEventTime.rest)

ZeroTradingStatusNotification ==
    [ notificationTime  |-> [i \in 1 .. 8 |-> 0],
      productId         |-> [i \in 1 .. 4 |-> 0],
      tradingStatus     |-> [i \in 1 .. 1 |-> 0],
      expectedEventTime |-> [i \in 1 .. 8 |-> 0] ]

(* Trading Status Notification at zero, then each field in turn at the values it is checked at *)
CheckedTradingStatusNotification ==
    { ZeroTradingStatusNotification }
        \cup { [ZeroTradingStatusNotification EXCEPT !.notificationTime = one] : one \in Sample(8) }
        \cup { [ZeroTradingStatusNotification EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroTradingStatusNotification EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusNotification EXCEPT !.expectedEventTime = one] : one \in Sample(8) }

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
(* Arm Protection Settings Notification: 31 bytes                          *)
(***************************************************************************)

ArmProtectionSettingsNotification ==
    [ notificationTime              : Sample(8),
      mpid                          : Sample(4),
      underlyingSymbol              : Sample(11),
      allowableEngagementPercentage : Sample(4),
      countingPeriod                : Sample(2),
      action                        : Sample(1),
      source                        : Sample(1) ]

EncodeArmProtectionSettingsNotification(message) ==
    message.notificationTime
        \o message.mpid
        \o message.underlyingSymbol
        \o message.allowableEngagementPercentage
        \o message.countingPeriod
        \o message.action
        \o message.source

DecodeArmProtectionSettingsNotification(bytes) ==
    LET notificationTime == ReadBytes(bytes, 8) IN IF ~notificationTime.ok THEN Fail ELSE
    LET mpid == ReadBytes(notificationTime.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(mpid.rest, 11) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET allowableEngagementPercentage == ReadBytes(underlyingSymbol.rest, 4) IN IF ~allowableEngagementPercentage.ok THEN Fail ELSE
    LET countingPeriod == ReadBytes(allowableEngagementPercentage.rest, 2) IN IF ~countingPeriod.ok THEN Fail ELSE
    LET action == ReadBytes(countingPeriod.rest, 1) IN IF ~action.ok THEN Fail ELSE
    LET source == ReadBytes(action.rest, 1) IN IF ~source.ok THEN Fail ELSE
    Ok([ notificationTime              |-> notificationTime.value,
         mpid                          |-> mpid.value,
         underlyingSymbol              |-> underlyingSymbol.value,
         allowableEngagementPercentage |-> allowableEngagementPercentage.value,
         countingPeriod                |-> countingPeriod.value,
         action                        |-> action.value,
         source                        |-> source.value ], source.rest)

ZeroArmProtectionSettingsNotification ==
    [ notificationTime              |-> [i \in 1 .. 8 |-> 0],
      mpid                          |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbol              |-> [i \in 1 .. 11 |-> 0],
      allowableEngagementPercentage |-> [i \in 1 .. 4 |-> 0],
      countingPeriod                |-> [i \in 1 .. 2 |-> 0],
      action                        |-> [i \in 1 .. 1 |-> 0],
      source                        |-> [i \in 1 .. 1 |-> 0] ]

(* Arm Protection Settings Notification at zero, then each field in turn at the values it is checked at *)
CheckedArmProtectionSettingsNotification ==
    { ZeroArmProtectionSettingsNotification }
        \cup { [ZeroArmProtectionSettingsNotification EXCEPT !.notificationTime = one] : one \in Sample(8) }
        \cup { [ZeroArmProtectionSettingsNotification EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroArmProtectionSettingsNotification EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }
        \cup { [ZeroArmProtectionSettingsNotification EXCEPT !.allowableEngagementPercentage = one] : one \in Sample(4) }
        \cup { [ZeroArmProtectionSettingsNotification EXCEPT !.countingPeriod = one] : one \in Sample(2) }
        \cup { [ZeroArmProtectionSettingsNotification EXCEPT !.action = one] : one \in Sample(1) }
        \cup { [ZeroArmProtectionSettingsNotification EXCEPT !.source = one] : one \in Sample(1) }

(***************************************************************************)
(* Cancel Notification: 36 bytes                                           *)
(***************************************************************************)

CancelNotification ==
    [ notificationTime     : Sample(8),
      mpid                 : Sample(4),
      productId            : Sample(4),
      liquidityType        : Sample(1),
      clientMessageId      : Sample(4),
      bulkQuoteIndex       : Sample(1),
      quoteeQuoteSide      : Sample(1),
      size                 : Sample(4),
      engineSequenceNumber : Sample(8),
      cancelReason         : Sample(1) ]

EncodeCancelNotification(message) ==
    message.notificationTime
        \o message.mpid
        \o message.productId
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
    LET productId == ReadBytes(mpid.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET liquidityType == ReadBytes(productId.rest, 1) IN IF ~liquidityType.ok THEN Fail ELSE
    LET clientMessageId == ReadBytes(liquidityType.rest, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET bulkQuoteIndex == ReadBytes(clientMessageId.rest, 1) IN IF ~bulkQuoteIndex.ok THEN Fail ELSE
    LET quoteeQuoteSide == ReadBytes(bulkQuoteIndex.rest, 1) IN IF ~quoteeQuoteSide.ok THEN Fail ELSE
    LET size == ReadBytes(quoteeQuoteSide.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET engineSequenceNumber == ReadBytes(size.rest, 8) IN IF ~engineSequenceNumber.ok THEN Fail ELSE
    LET cancelReason == ReadBytes(engineSequenceNumber.rest, 1) IN IF ~cancelReason.ok THEN Fail ELSE
    Ok([ notificationTime     |-> notificationTime.value,
         mpid                 |-> mpid.value,
         productId            |-> productId.value,
         liquidityType        |-> liquidityType.value,
         clientMessageId      |-> clientMessageId.value,
         bulkQuoteIndex       |-> bulkQuoteIndex.value,
         quoteeQuoteSide      |-> quoteeQuoteSide.value,
         size                 |-> size.value,
         engineSequenceNumber |-> engineSequenceNumber.value,
         cancelReason         |-> cancelReason.value ], cancelReason.rest)

ZeroCancelNotification ==
    [ notificationTime     |-> [i \in 1 .. 8 |-> 0],
      mpid                 |-> [i \in 1 .. 4 |-> 0],
      productId            |-> [i \in 1 .. 4 |-> 0],
      liquidityType        |-> [i \in 1 .. 1 |-> 0],
      clientMessageId      |-> [i \in 1 .. 4 |-> 0],
      bulkQuoteIndex       |-> [i \in 1 .. 1 |-> 0],
      quoteeQuoteSide      |-> [i \in 1 .. 1 |-> 0],
      size                 |-> [i \in 1 .. 4 |-> 0],
      engineSequenceNumber |-> [i \in 1 .. 8 |-> 0],
      cancelReason         |-> [i \in 1 .. 1 |-> 0] ]

(* Cancel Notification at zero, then each field in turn at the values it is checked at *)
CheckedCancelNotification ==
    { ZeroCancelNotification }
        \cup { [ZeroCancelNotification EXCEPT !.notificationTime = one] : one \in Sample(8) }
        \cup { [ZeroCancelNotification EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroCancelNotification EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroCancelNotification EXCEPT !.liquidityType = one] : one \in Sample(1) }
        \cup { [ZeroCancelNotification EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroCancelNotification EXCEPT !.bulkQuoteIndex = one] : one \in Sample(1) }
        \cup { [ZeroCancelNotification EXCEPT !.quoteeQuoteSide = one] : one \in Sample(1) }
        \cup { [ZeroCancelNotification EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroCancelNotification EXCEPT !.engineSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroCancelNotification EXCEPT !.cancelReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Execution Notification: 49 bytes                                        *)
(***************************************************************************)

ExecutionNotification ==
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

EncodeExecutionNotification(message) ==
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

DecodeExecutionNotification(bytes) ==
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

ZeroExecutionNotification ==
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

(* Execution Notification at zero, then each field in turn at the values it is checked at *)
CheckedExecutionNotification ==
    { ZeroExecutionNotification }
        \cup { [ZeroExecutionNotification EXCEPT !.notificationTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionNotification EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroExecutionNotification EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionNotification EXCEPT !.liquidityType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionNotification EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionNotification EXCEPT !.bulkQuoteIndex = one] : one \in Sample(1) }
        \cup { [ZeroExecutionNotification EXCEPT !.eventId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionNotification EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionNotification EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionNotification EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroExecutionNotification EXCEPT !.tradeStatus = one] : one \in Sample(1) }
        \cup { [ZeroExecutionNotification EXCEPT !.lastPrice = one] : one \in Sample(4) }
        \cup { [ZeroExecutionNotification EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroExecutionNotification EXCEPT !.lastSize = one] : one \in Sample(4) }

(***************************************************************************)
(* Sequenced Message, selected by Sequenced Message Type                   *)
(***************************************************************************)

SeriesUpdateCode == 21333  \* "SU"
ValidQuoteWidthForOpeningCode == 20823  \* "QW"
EnhancedQuoteEQuoteResponseCode == 17746  \* "ER"
SystemStateNotificationCode == 21326  \* "SN"
TradingStatusNotificationCode == 21582  \* "TN"
QuoteWidthReliefNotificationCode == 20814  \* "QN"
ArmProtectionSettingsNotificationCode == 16718  \* "AN"
CancelNotificationCode == 22606  \* "XN"
ExecutionNotificationCode == 17742  \* "EN"

SequencedMessage ==
    [ tag : {SeriesUpdateCode}, body : SeriesUpdate ]
        \cup [ tag : {ValidQuoteWidthForOpeningCode}, body : ValidQuoteWidthForOpening ]
        \cup [ tag : {EnhancedQuoteEQuoteResponseCode}, body : EnhancedQuoteEQuoteResponse ]
        \cup [ tag : {SystemStateNotificationCode}, body : SystemStateNotification ]
        \cup [ tag : {TradingStatusNotificationCode}, body : TradingStatusNotification ]
        \cup [ tag : {QuoteWidthReliefNotificationCode}, body : QuoteWidthReliefNotification ]
        \cup [ tag : {ArmProtectionSettingsNotificationCode}, body : ArmProtectionSettingsNotification ]
        \cup [ tag : {CancelNotificationCode}, body : CancelNotification ]
        \cup [ tag : {ExecutionNotificationCode}, body : ExecutionNotification ]

EncodeSequencedMessage(message) ==
    CASE message.tag = SeriesUpdateCode -> EncodeSeriesUpdate(message.body)
      [] message.tag = ValidQuoteWidthForOpeningCode -> EncodeValidQuoteWidthForOpening(message.body)
      [] message.tag = EnhancedQuoteEQuoteResponseCode -> EncodeEnhancedQuoteEQuoteResponse(message.body)
      [] message.tag = SystemStateNotificationCode -> EncodeSystemStateNotification(message.body)
      [] message.tag = TradingStatusNotificationCode -> EncodeTradingStatusNotification(message.body)
      [] message.tag = QuoteWidthReliefNotificationCode -> EncodeQuoteWidthReliefNotification(message.body)
      [] message.tag = ArmProtectionSettingsNotificationCode -> EncodeArmProtectionSettingsNotification(message.body)
      [] message.tag = CancelNotificationCode -> EncodeCancelNotification(message.body)
      [] message.tag = ExecutionNotificationCode -> EncodeExecutionNotification(message.body)

DecodeSequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = SeriesUpdateCode -> DecodeSeriesUpdate(bytes)
              [] tag = ValidQuoteWidthForOpeningCode -> DecodeValidQuoteWidthForOpening(bytes)
              [] tag = EnhancedQuoteEQuoteResponseCode -> DecodeEnhancedQuoteEQuoteResponse(bytes)
              [] tag = SystemStateNotificationCode -> DecodeSystemStateNotification(bytes)
              [] tag = TradingStatusNotificationCode -> DecodeTradingStatusNotification(bytes)
              [] tag = QuoteWidthReliefNotificationCode -> DecodeQuoteWidthReliefNotification(bytes)
              [] tag = ArmProtectionSettingsNotificationCode -> DecodeArmProtectionSettingsNotification(bytes)
              [] tag = CancelNotificationCode -> DecodeCancelNotification(bytes)
              [] tag = ExecutionNotificationCode -> DecodeExecutionNotification(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSequencedMessage == [tag |-> SeriesUpdateCode, body |-> ZeroSeriesUpdate]

(* Each Sequenced Message in turn, at the values the message it names is checked at *)
CheckedSequencedMessage ==
    { [tag |-> SeriesUpdateCode, body |-> one] : one \in CheckedSeriesUpdate }
        \cup { [tag |-> ValidQuoteWidthForOpeningCode, body |-> one] : one \in CheckedValidQuoteWidthForOpening }
        \cup { [tag |-> EnhancedQuoteEQuoteResponseCode, body |-> one] : one \in CheckedEnhancedQuoteEQuoteResponse }
        \cup { [tag |-> SystemStateNotificationCode, body |-> one] : one \in CheckedSystemStateNotification }
        \cup { [tag |-> TradingStatusNotificationCode, body |-> one] : one \in CheckedTradingStatusNotification }
        \cup { [tag |-> QuoteWidthReliefNotificationCode, body |-> one] : one \in CheckedQuoteWidthReliefNotification }
        \cup { [tag |-> ArmProtectionSettingsNotificationCode, body |-> one] : one \in CheckedArmProtectionSettingsNotification }
        \cup { [tag |-> CancelNotificationCode, body |-> one] : one \in CheckedCancelNotification }
        \cup { [tag |-> ExecutionNotificationCode, body |-> one] : one \in CheckedExecutionNotification }

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
(* Arm Settings Update Request: 26 bytes                                   *)
(***************************************************************************)

ArmSettingsUpdateRequest ==
    [ clientMessageId               : Sample(4),
      mpid                          : Sample(4),
      action                        : Sample(1),
      underlyingSymbol              : Sample(11),
      allowableEngagementPercentage : Sample(4),
      countingPeriod                : Sample(2) ]

EncodeArmSettingsUpdateRequest(message) ==
    message.clientMessageId
        \o message.mpid
        \o message.action
        \o message.underlyingSymbol
        \o message.allowableEngagementPercentage
        \o message.countingPeriod

DecodeArmSettingsUpdateRequest(bytes) ==
    LET clientMessageId == ReadBytes(bytes, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET mpid == ReadBytes(clientMessageId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET action == ReadBytes(mpid.rest, 1) IN IF ~action.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(action.rest, 11) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET allowableEngagementPercentage == ReadBytes(underlyingSymbol.rest, 4) IN IF ~allowableEngagementPercentage.ok THEN Fail ELSE
    LET countingPeriod == ReadBytes(allowableEngagementPercentage.rest, 2) IN IF ~countingPeriod.ok THEN Fail ELSE
    Ok([ clientMessageId               |-> clientMessageId.value,
         mpid                          |-> mpid.value,
         action                        |-> action.value,
         underlyingSymbol              |-> underlyingSymbol.value,
         allowableEngagementPercentage |-> allowableEngagementPercentage.value,
         countingPeriod                |-> countingPeriod.value ], countingPeriod.rest)

ZeroArmSettingsUpdateRequest ==
    [ clientMessageId               |-> [i \in 1 .. 4 |-> 0],
      mpid                          |-> [i \in 1 .. 4 |-> 0],
      action                        |-> [i \in 1 .. 1 |-> 0],
      underlyingSymbol              |-> [i \in 1 .. 11 |-> 0],
      allowableEngagementPercentage |-> [i \in 1 .. 4 |-> 0],
      countingPeriod                |-> [i \in 1 .. 2 |-> 0] ]

(* Arm Settings Update Request at zero, then each field in turn at the values it is checked at *)
CheckedArmSettingsUpdateRequest ==
    { ZeroArmSettingsUpdateRequest }
        \cup { [ZeroArmSettingsUpdateRequest EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroArmSettingsUpdateRequest EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroArmSettingsUpdateRequest EXCEPT !.action = one] : one \in Sample(1) }
        \cup { [ZeroArmSettingsUpdateRequest EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }
        \cup { [ZeroArmSettingsUpdateRequest EXCEPT !.allowableEngagementPercentage = one] : one \in Sample(4) }
        \cup { [ZeroArmSettingsUpdateRequest EXCEPT !.countingPeriod = one] : one \in Sample(2) }

(***************************************************************************)
(* Arm Settings Update Response: 20 bytes                                  *)
(***************************************************************************)

ArmSettingsUpdateResponse ==
    [ clientMessageId         : Sample(4),
      mpid                    : Sample(4),
      underlyingSymbol        : Sample(11),
      armSettingsUpdateStatus : Sample(1) ]

EncodeArmSettingsUpdateResponse(message) ==
    message.clientMessageId
        \o message.mpid
        \o message.underlyingSymbol
        \o message.armSettingsUpdateStatus

DecodeArmSettingsUpdateResponse(bytes) ==
    LET clientMessageId == ReadBytes(bytes, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET mpid == ReadBytes(clientMessageId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(mpid.rest, 11) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET armSettingsUpdateStatus == ReadBytes(underlyingSymbol.rest, 1) IN IF ~armSettingsUpdateStatus.ok THEN Fail ELSE
    Ok([ clientMessageId         |-> clientMessageId.value,
         mpid                    |-> mpid.value,
         underlyingSymbol        |-> underlyingSymbol.value,
         armSettingsUpdateStatus |-> armSettingsUpdateStatus.value ], armSettingsUpdateStatus.rest)

ZeroArmSettingsUpdateResponse ==
    [ clientMessageId         |-> [i \in 1 .. 4 |-> 0],
      mpid                    |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbol        |-> [i \in 1 .. 11 |-> 0],
      armSettingsUpdateStatus |-> [i \in 1 .. 1 |-> 0] ]

(* Arm Settings Update Response at zero, then each field in turn at the values it is checked at *)
CheckedArmSettingsUpdateResponse ==
    { ZeroArmSettingsUpdateResponse }
        \cup { [ZeroArmSettingsUpdateResponse EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroArmSettingsUpdateResponse EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroArmSettingsUpdateResponse EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }
        \cup { [ZeroArmSettingsUpdateResponse EXCEPT !.armSettingsUpdateStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Single Side Quote: 13 bytes                                             *)
(***************************************************************************)

SingleSideQuote ==
    [ productId : Sample(4),
      price     : Sample(4),
      size      : Sample(4),
      side      : Sample(1) ]

EncodeSingleSideQuote(message) ==
    message.productId
        \o message.price
        \o message.size
        \o message.side

DecodeSingleSideQuote(bytes) ==
    LET productId == ReadBytes(bytes, 4) IN IF ~productId.ok THEN Fail ELSE
    LET price == ReadBytes(productId.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET size == ReadBytes(price.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET side == ReadBytes(size.rest, 1) IN IF ~side.ok THEN Fail ELSE
    Ok([ productId |-> productId.value,
         price     |-> price.value,
         size      |-> size.value,
         side      |-> side.value ], side.rest)

ZeroSingleSideQuote ==
    [ productId |-> [i \in 1 .. 4 |-> 0],
      price     |-> [i \in 1 .. 4 |-> 0],
      size      |-> [i \in 1 .. 4 |-> 0],
      side      |-> [i \in 1 .. 1 |-> 0] ]

(* Single Side Quote at zero, then each field in turn at the values it is checked at *)
CheckedSingleSideQuote ==
    { ZeroSingleSideQuote }
        \cup { [ZeroSingleSideQuote EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideQuote EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideQuote EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideQuote EXCEPT !.side = one] : one \in Sample(1) }

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
(* Bulk Quote Message                                                      *)
(***************************************************************************)

BulkQuoteMessage ==
    [ clientMessageId : Sample(4),
      mpid            : Sample(4),
      singleSideQuote : SampleLists(OneSingleSideQuote) ]

EncodeBulkQuoteMessage(message) ==
    message.clientMessageId
        \o message.mpid
        \o EncodeUIntBE(Len(message.singleSideQuote), 1)
        \o EncodeSingleSideQuoteList(message.singleSideQuote)

DecodeBulkQuoteMessage(bytes) ==
    LET clientMessageId == ReadBytes(bytes, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET mpid == ReadBytes(clientMessageId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET quoteCount == ReadUIntBE(mpid.rest, 1) IN IF ~quoteCount.ok THEN Fail ELSE
    LET singleSideQuote == ReadSingleSideQuoteList(quoteCount.rest, quoteCount.value) IN IF ~singleSideQuote.ok THEN Fail ELSE
    Ok([ clientMessageId |-> clientMessageId.value,
         mpid            |-> mpid.value,
         singleSideQuote |-> singleSideQuote.value ], singleSideQuote.rest)

ZeroBulkQuoteMessage ==
    [ clientMessageId |-> [i \in 1 .. 4 |-> 0],
      mpid            |-> [i \in 1 .. 4 |-> 0],
      singleSideQuote |-> << >> ]

(* Bulk Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuoteMessage ==
    { ZeroBulkQuoteMessage }
        \cup { [ZeroBulkQuoteMessage EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroBulkQuoteMessage EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroBulkQuoteMessage EXCEPT !.singleSideQuote = one] : one \in SampleLists(OneSingleSideQuote) }

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
(* Bulk Quote Response                                                     *)
(***************************************************************************)

BulkQuoteResponse ==
    [ clientMessageId         : Sample(4),
      mpid                    : Sample(4),
      bulkQuoteStatus         : Sample(1),
      quoteCount              : Sample(1),
      quoteAckTime            : Sample(8),
      singleSideQuoteResponse : SampleLists(OneSingleSideQuoteResponse) ]

EncodeBulkQuoteResponse(message) ==
    message.clientMessageId
        \o message.mpid
        \o message.bulkQuoteStatus
        \o message.quoteCount
        \o EncodeUIntBE(Len(message.singleSideQuoteResponse), 1)
        \o message.quoteAckTime
        \o EncodeSingleSideQuoteResponseList(message.singleSideQuoteResponse)

DecodeBulkQuoteResponse(bytes) ==
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

ZeroBulkQuoteResponse ==
    [ clientMessageId         |-> [i \in 1 .. 4 |-> 0],
      mpid                    |-> [i \in 1 .. 4 |-> 0],
      bulkQuoteStatus         |-> [i \in 1 .. 1 |-> 0],
      quoteCount              |-> [i \in 1 .. 1 |-> 0],
      quoteAckTime            |-> [i \in 1 .. 8 |-> 0],
      singleSideQuoteResponse |-> << >> ]

(* Bulk Quote Response at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuoteResponse ==
    { ZeroBulkQuoteResponse }
        \cup { [ZeroBulkQuoteResponse EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroBulkQuoteResponse EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroBulkQuoteResponse EXCEPT !.bulkQuoteStatus = one] : one \in Sample(1) }
        \cup { [ZeroBulkQuoteResponse EXCEPT !.quoteCount = one] : one \in Sample(1) }
        \cup { [ZeroBulkQuoteResponse EXCEPT !.quoteAckTime = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuoteResponse EXCEPT !.singleSideQuoteResponse = one] : one \in SampleLists(OneSingleSideQuoteResponse) }

(***************************************************************************)
(* Enhanced Quote E Quote Message: 31 bytes                                *)
(***************************************************************************)

EnhancedQuoteEQuoteMessage ==
    [ clientMessageId : Sample(4),
      mpid            : Sample(4),
      productId       : Sample(4),
      eQuoteAction    : Sample(1),
      eQuoteType      : Sample(1),
      eventId         : Sample(4),
      targetMessageId : Sample(4),
      price           : Sample(4),
      size            : Sample(4),
      side            : Sample(1) ]

EncodeEnhancedQuoteEQuoteMessage(message) ==
    message.clientMessageId
        \o message.mpid
        \o message.productId
        \o message.eQuoteAction
        \o message.eQuoteType
        \o message.eventId
        \o message.targetMessageId
        \o message.price
        \o message.size
        \o message.side

DecodeEnhancedQuoteEQuoteMessage(bytes) ==
    LET clientMessageId == ReadBytes(bytes, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET mpid == ReadBytes(clientMessageId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET productId == ReadBytes(mpid.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET eQuoteAction == ReadBytes(productId.rest, 1) IN IF ~eQuoteAction.ok THEN Fail ELSE
    LET eQuoteType == ReadBytes(eQuoteAction.rest, 1) IN IF ~eQuoteType.ok THEN Fail ELSE
    LET eventId == ReadBytes(eQuoteType.rest, 4) IN IF ~eventId.ok THEN Fail ELSE
    LET targetMessageId == ReadBytes(eventId.rest, 4) IN IF ~targetMessageId.ok THEN Fail ELSE
    LET price == ReadBytes(targetMessageId.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET size == ReadBytes(price.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET side == ReadBytes(size.rest, 1) IN IF ~side.ok THEN Fail ELSE
    Ok([ clientMessageId |-> clientMessageId.value,
         mpid            |-> mpid.value,
         productId       |-> productId.value,
         eQuoteAction    |-> eQuoteAction.value,
         eQuoteType      |-> eQuoteType.value,
         eventId         |-> eventId.value,
         targetMessageId |-> targetMessageId.value,
         price           |-> price.value,
         size            |-> size.value,
         side            |-> side.value ], side.rest)

ZeroEnhancedQuoteEQuoteMessage ==
    [ clientMessageId |-> [i \in 1 .. 4 |-> 0],
      mpid            |-> [i \in 1 .. 4 |-> 0],
      productId       |-> [i \in 1 .. 4 |-> 0],
      eQuoteAction    |-> [i \in 1 .. 1 |-> 0],
      eQuoteType      |-> [i \in 1 .. 1 |-> 0],
      eventId         |-> [i \in 1 .. 4 |-> 0],
      targetMessageId |-> [i \in 1 .. 4 |-> 0],
      price           |-> [i \in 1 .. 4 |-> 0],
      size            |-> [i \in 1 .. 4 |-> 0],
      side            |-> [i \in 1 .. 1 |-> 0] ]

(* Enhanced Quote E Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedEnhancedQuoteEQuoteMessage ==
    { ZeroEnhancedQuoteEQuoteMessage }
        \cup { [ZeroEnhancedQuoteEQuoteMessage EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroEnhancedQuoteEQuoteMessage EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroEnhancedQuoteEQuoteMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroEnhancedQuoteEQuoteMessage EXCEPT !.eQuoteAction = one] : one \in Sample(1) }
        \cup { [ZeroEnhancedQuoteEQuoteMessage EXCEPT !.eQuoteType = one] : one \in Sample(1) }
        \cup { [ZeroEnhancedQuoteEQuoteMessage EXCEPT !.eventId = one] : one \in Sample(4) }
        \cup { [ZeroEnhancedQuoteEQuoteMessage EXCEPT !.targetMessageId = one] : one \in Sample(4) }
        \cup { [ZeroEnhancedQuoteEQuoteMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroEnhancedQuoteEQuoteMessage EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroEnhancedQuoteEQuoteMessage EXCEPT !.side = one] : one \in Sample(1) }

(***************************************************************************)
(* Mass Quote Cancel Request: 19 bytes                                     *)
(***************************************************************************)

MassQuoteCancelRequest ==
    [ clientMessageId  : Sample(4),
      mpid             : Sample(4),
      underlyingSymbol : Sample(11) ]

EncodeMassQuoteCancelRequest(message) ==
    message.clientMessageId
        \o message.mpid
        \o message.underlyingSymbol

DecodeMassQuoteCancelRequest(bytes) ==
    LET clientMessageId == ReadBytes(bytes, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET mpid == ReadBytes(clientMessageId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(mpid.rest, 11) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    Ok([ clientMessageId  |-> clientMessageId.value,
         mpid             |-> mpid.value,
         underlyingSymbol |-> underlyingSymbol.value ], underlyingSymbol.rest)

ZeroMassQuoteCancelRequest ==
    [ clientMessageId  |-> [i \in 1 .. 4 |-> 0],
      mpid             |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbol |-> [i \in 1 .. 11 |-> 0] ]

(* Mass Quote Cancel Request at zero, then each field in turn at the values it is checked at *)
CheckedMassQuoteCancelRequest ==
    { ZeroMassQuoteCancelRequest }
        \cup { [ZeroMassQuoteCancelRequest EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroMassQuoteCancelRequest EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroMassQuoteCancelRequest EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }

(***************************************************************************)
(* Mass Quote Cancel Response: 9 bytes                                     *)
(***************************************************************************)

MassQuoteCancelResponse ==
    [ clientMessageId       : Sample(4),
      mpid                  : Sample(4),
      massQuoteCancelStatus : Sample(1) ]

EncodeMassQuoteCancelResponse(message) ==
    message.clientMessageId
        \o message.mpid
        \o message.massQuoteCancelStatus

DecodeMassQuoteCancelResponse(bytes) ==
    LET clientMessageId == ReadBytes(bytes, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET mpid == ReadBytes(clientMessageId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET massQuoteCancelStatus == ReadBytes(mpid.rest, 1) IN IF ~massQuoteCancelStatus.ok THEN Fail ELSE
    Ok([ clientMessageId       |-> clientMessageId.value,
         mpid                  |-> mpid.value,
         massQuoteCancelStatus |-> massQuoteCancelStatus.value ], massQuoteCancelStatus.rest)

ZeroMassQuoteCancelResponse ==
    [ clientMessageId       |-> [i \in 1 .. 4 |-> 0],
      mpid                  |-> [i \in 1 .. 4 |-> 0],
      massQuoteCancelStatus |-> [i \in 1 .. 1 |-> 0] ]

(* Mass Quote Cancel Response at zero, then each field in turn at the values it is checked at *)
CheckedMassQuoteCancelResponse ==
    { ZeroMassQuoteCancelResponse }
        \cup { [ZeroMassQuoteCancelResponse EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroMassQuoteCancelResponse EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroMassQuoteCancelResponse EXCEPT !.massQuoteCancelStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Quote Protection Reset Request: 19 bytes                                *)
(***************************************************************************)

QuoteProtectionResetRequest ==
    [ clientMessageId  : Sample(4),
      mpid             : Sample(4),
      underlyingSymbol : Sample(11) ]

EncodeQuoteProtectionResetRequest(message) ==
    message.clientMessageId
        \o message.mpid
        \o message.underlyingSymbol

DecodeQuoteProtectionResetRequest(bytes) ==
    LET clientMessageId == ReadBytes(bytes, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET mpid == ReadBytes(clientMessageId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(mpid.rest, 11) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    Ok([ clientMessageId  |-> clientMessageId.value,
         mpid             |-> mpid.value,
         underlyingSymbol |-> underlyingSymbol.value ], underlyingSymbol.rest)

ZeroQuoteProtectionResetRequest ==
    [ clientMessageId  |-> [i \in 1 .. 4 |-> 0],
      mpid             |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbol |-> [i \in 1 .. 11 |-> 0] ]

(* Quote Protection Reset Request at zero, then each field in turn at the values it is checked at *)
CheckedQuoteProtectionResetRequest ==
    { ZeroQuoteProtectionResetRequest }
        \cup { [ZeroQuoteProtectionResetRequest EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteProtectionResetRequest EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroQuoteProtectionResetRequest EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }

(***************************************************************************)
(* Quote Protection Reset Response: 9 bytes                                *)
(***************************************************************************)

QuoteProtectionResetResponse ==
    [ clientMessageId            : Sample(4),
      mpid                       : Sample(4),
      quoteProtectionResetStatus : Sample(1) ]

EncodeQuoteProtectionResetResponse(message) ==
    message.clientMessageId
        \o message.mpid
        \o message.quoteProtectionResetStatus

DecodeQuoteProtectionResetResponse(bytes) ==
    LET clientMessageId == ReadBytes(bytes, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET mpid == ReadBytes(clientMessageId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET quoteProtectionResetStatus == ReadBytes(mpid.rest, 1) IN IF ~quoteProtectionResetStatus.ok THEN Fail ELSE
    Ok([ clientMessageId            |-> clientMessageId.value,
         mpid                       |-> mpid.value,
         quoteProtectionResetStatus |-> quoteProtectionResetStatus.value ], quoteProtectionResetStatus.rest)

ZeroQuoteProtectionResetResponse ==
    [ clientMessageId            |-> [i \in 1 .. 4 |-> 0],
      mpid                       |-> [i \in 1 .. 4 |-> 0],
      quoteProtectionResetStatus |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Protection Reset Response at zero, then each field in turn at the values it is checked at *)
CheckedQuoteProtectionResetResponse ==
    { ZeroQuoteProtectionResetResponse }
        \cup { [ZeroQuoteProtectionResetResponse EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteProtectionResetResponse EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroQuoteProtectionResetResponse EXCEPT !.quoteProtectionResetStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Quote Protection Trigger Notification: 24 bytes                         *)
(***************************************************************************)

QuoteProtectionTriggerNotification ==
    [ notificationTime : Sample(8),
      mpid             : Sample(4),
      underlyingSymbol : Sample(11),
      triggerReason    : Sample(1) ]

EncodeQuoteProtectionTriggerNotification(message) ==
    message.notificationTime
        \o message.mpid
        \o message.underlyingSymbol
        \o message.triggerReason

DecodeQuoteProtectionTriggerNotification(bytes) ==
    LET notificationTime == ReadBytes(bytes, 8) IN IF ~notificationTime.ok THEN Fail ELSE
    LET mpid == ReadBytes(notificationTime.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(mpid.rest, 11) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET triggerReason == ReadBytes(underlyingSymbol.rest, 1) IN IF ~triggerReason.ok THEN Fail ELSE
    Ok([ notificationTime |-> notificationTime.value,
         mpid             |-> mpid.value,
         underlyingSymbol |-> underlyingSymbol.value,
         triggerReason    |-> triggerReason.value ], triggerReason.rest)

ZeroQuoteProtectionTriggerNotification ==
    [ notificationTime |-> [i \in 1 .. 8 |-> 0],
      mpid             |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbol |-> [i \in 1 .. 11 |-> 0],
      triggerReason    |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Protection Trigger Notification at zero, then each field in turn at the values it is checked at *)
CheckedQuoteProtectionTriggerNotification ==
    { ZeroQuoteProtectionTriggerNotification }
        \cup { [ZeroQuoteProtectionTriggerNotification EXCEPT !.notificationTime = one] : one \in Sample(8) }
        \cup { [ZeroQuoteProtectionTriggerNotification EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroQuoteProtectionTriggerNotification EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }
        \cup { [ZeroQuoteProtectionTriggerNotification EXCEPT !.triggerReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Liquidity Seeking Event Notification: 50 bytes                          *)
(***************************************************************************)

LiquiditySeekingEventNotification ==
    [ notificationTime : Sample(8),
      productId        : Sample(4),
      eventType        : Sample(1),
      eventId          : Sample(4),
      price            : Sample(4),
      imbalanceSide    : Sample(1),
      quantity1        : Sample(4),
      quantity2        : Sample(4),
      quantity3        : Sample(4),
      quantity4        : Sample(4),
      reserved12       : Sample(12) ]

EncodeLiquiditySeekingEventNotification(message) ==
    message.notificationTime
        \o message.productId
        \o message.eventType
        \o message.eventId
        \o message.price
        \o message.imbalanceSide
        \o message.quantity1
        \o message.quantity2
        \o message.quantity3
        \o message.quantity4
        \o message.reserved12

DecodeLiquiditySeekingEventNotification(bytes) ==
    LET notificationTime == ReadBytes(bytes, 8) IN IF ~notificationTime.ok THEN Fail ELSE
    LET productId == ReadBytes(notificationTime.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET eventType == ReadBytes(productId.rest, 1) IN IF ~eventType.ok THEN Fail ELSE
    LET eventId == ReadBytes(eventType.rest, 4) IN IF ~eventId.ok THEN Fail ELSE
    LET price == ReadBytes(eventId.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET imbalanceSide == ReadBytes(price.rest, 1) IN IF ~imbalanceSide.ok THEN Fail ELSE
    LET quantity1 == ReadBytes(imbalanceSide.rest, 4) IN IF ~quantity1.ok THEN Fail ELSE
    LET quantity2 == ReadBytes(quantity1.rest, 4) IN IF ~quantity2.ok THEN Fail ELSE
    LET quantity3 == ReadBytes(quantity2.rest, 4) IN IF ~quantity3.ok THEN Fail ELSE
    LET quantity4 == ReadBytes(quantity3.rest, 4) IN IF ~quantity4.ok THEN Fail ELSE
    LET reserved12 == ReadBytes(quantity4.rest, 12) IN IF ~reserved12.ok THEN Fail ELSE
    Ok([ notificationTime |-> notificationTime.value,
         productId        |-> productId.value,
         eventType        |-> eventType.value,
         eventId          |-> eventId.value,
         price            |-> price.value,
         imbalanceSide    |-> imbalanceSide.value,
         quantity1        |-> quantity1.value,
         quantity2        |-> quantity2.value,
         quantity3        |-> quantity3.value,
         quantity4        |-> quantity4.value,
         reserved12       |-> reserved12.value ], reserved12.rest)

ZeroLiquiditySeekingEventNotification ==
    [ notificationTime |-> [i \in 1 .. 8 |-> 0],
      productId        |-> [i \in 1 .. 4 |-> 0],
      eventType        |-> [i \in 1 .. 1 |-> 0],
      eventId          |-> [i \in 1 .. 4 |-> 0],
      price            |-> [i \in 1 .. 4 |-> 0],
      imbalanceSide    |-> [i \in 1 .. 1 |-> 0],
      quantity1        |-> [i \in 1 .. 4 |-> 0],
      quantity2        |-> [i \in 1 .. 4 |-> 0],
      quantity3        |-> [i \in 1 .. 4 |-> 0],
      quantity4        |-> [i \in 1 .. 4 |-> 0],
      reserved12       |-> [i \in 1 .. 12 |-> 0] ]

(* Liquidity Seeking Event Notification at zero, then each field in turn at the values it is checked at *)
CheckedLiquiditySeekingEventNotification ==
    { ZeroLiquiditySeekingEventNotification }
        \cup { [ZeroLiquiditySeekingEventNotification EXCEPT !.notificationTime = one] : one \in Sample(8) }
        \cup { [ZeroLiquiditySeekingEventNotification EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroLiquiditySeekingEventNotification EXCEPT !.eventType = one] : one \in Sample(1) }
        \cup { [ZeroLiquiditySeekingEventNotification EXCEPT !.eventId = one] : one \in Sample(4) }
        \cup { [ZeroLiquiditySeekingEventNotification EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroLiquiditySeekingEventNotification EXCEPT !.imbalanceSide = one] : one \in Sample(1) }
        \cup { [ZeroLiquiditySeekingEventNotification EXCEPT !.quantity1 = one] : one \in Sample(4) }
        \cup { [ZeroLiquiditySeekingEventNotification EXCEPT !.quantity2 = one] : one \in Sample(4) }
        \cup { [ZeroLiquiditySeekingEventNotification EXCEPT !.quantity3 = one] : one \in Sample(4) }
        \cup { [ZeroLiquiditySeekingEventNotification EXCEPT !.quantity4 = one] : one \in Sample(4) }
        \cup { [ZeroLiquiditySeekingEventNotification EXCEPT !.reserved12 = one] : one \in Sample(12) }

(***************************************************************************)
(* Cancel Notification: 36 bytes                                           *)
(***************************************************************************)

CancelNotification2 ==
    [ notificationTime     : Sample(8),
      mpid                 : Sample(4),
      productId            : Sample(4),
      liquidityType        : Sample(1),
      clientMessageId      : Sample(4),
      bulkQuoteIndex       : Sample(1),
      quoteeQuoteSide      : Sample(1),
      size                 : Sample(4),
      engineSequenceNumber : Sample(8),
      cancelReason         : Sample(1) ]

EncodeCancelNotification2(message) ==
    message.notificationTime
        \o message.mpid
        \o message.productId
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
    LET productId == ReadBytes(mpid.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET liquidityType == ReadBytes(productId.rest, 1) IN IF ~liquidityType.ok THEN Fail ELSE
    LET clientMessageId == ReadBytes(liquidityType.rest, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET bulkQuoteIndex == ReadBytes(clientMessageId.rest, 1) IN IF ~bulkQuoteIndex.ok THEN Fail ELSE
    LET quoteeQuoteSide == ReadBytes(bulkQuoteIndex.rest, 1) IN IF ~quoteeQuoteSide.ok THEN Fail ELSE
    LET size == ReadBytes(quoteeQuoteSide.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET engineSequenceNumber == ReadBytes(size.rest, 8) IN IF ~engineSequenceNumber.ok THEN Fail ELSE
    LET cancelReason == ReadBytes(engineSequenceNumber.rest, 1) IN IF ~cancelReason.ok THEN Fail ELSE
    Ok([ notificationTime     |-> notificationTime.value,
         mpid                 |-> mpid.value,
         productId            |-> productId.value,
         liquidityType        |-> liquidityType.value,
         clientMessageId      |-> clientMessageId.value,
         bulkQuoteIndex       |-> bulkQuoteIndex.value,
         quoteeQuoteSide      |-> quoteeQuoteSide.value,
         size                 |-> size.value,
         engineSequenceNumber |-> engineSequenceNumber.value,
         cancelReason         |-> cancelReason.value ], cancelReason.rest)

ZeroCancelNotification2 ==
    [ notificationTime     |-> [i \in 1 .. 8 |-> 0],
      mpid                 |-> [i \in 1 .. 4 |-> 0],
      productId            |-> [i \in 1 .. 4 |-> 0],
      liquidityType        |-> [i \in 1 .. 1 |-> 0],
      clientMessageId      |-> [i \in 1 .. 4 |-> 0],
      bulkQuoteIndex       |-> [i \in 1 .. 1 |-> 0],
      quoteeQuoteSide      |-> [i \in 1 .. 1 |-> 0],
      size                 |-> [i \in 1 .. 4 |-> 0],
      engineSequenceNumber |-> [i \in 1 .. 8 |-> 0],
      cancelReason         |-> [i \in 1 .. 1 |-> 0] ]

(* Cancel Notification at zero, then each field in turn at the values it is checked at *)
CheckedCancelNotification2 ==
    { ZeroCancelNotification2 }
        \cup { [ZeroCancelNotification2 EXCEPT !.notificationTime = one] : one \in Sample(8) }
        \cup { [ZeroCancelNotification2 EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroCancelNotification2 EXCEPT !.productId = one] : one \in Sample(4) }
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

ArmSettingsUpdateRequestCode == 16723  \* "AS"
ArmSettingsUpdateResponseCode == 16705  \* "AA"
BulkQuoteMessageCode == 20813  \* "QM"
BulkQuoteResponseCode == 20818  \* "QR"
EnhancedQuoteEQuoteMessageCode == 17745  \* "EQ"
MassQuoteCancelRequestCode == 22609  \* "XQ"
MassQuoteCancelResponseCode == 22610  \* "XR"
QuoteProtectionResetRequestCode == 20568  \* "PX"
QuoteProtectionResetResponseCode == 20562  \* "PR"
QuoteProtectionTriggerNotificationCode == 20816  \* "QP"
LiquiditySeekingEventNotificationCode == 19534  \* "LN"
CancelNotificationCode2 == 22606  \* "XN"

UnsequencedMessage ==
    [ tag : {ArmSettingsUpdateRequestCode}, body : ArmSettingsUpdateRequest ]
        \cup [ tag : {ArmSettingsUpdateResponseCode}, body : ArmSettingsUpdateResponse ]
        \cup [ tag : {BulkQuoteMessageCode}, body : BulkQuoteMessage ]
        \cup [ tag : {BulkQuoteResponseCode}, body : BulkQuoteResponse ]
        \cup [ tag : {EnhancedQuoteEQuoteMessageCode}, body : EnhancedQuoteEQuoteMessage ]
        \cup [ tag : {MassQuoteCancelRequestCode}, body : MassQuoteCancelRequest ]
        \cup [ tag : {MassQuoteCancelResponseCode}, body : MassQuoteCancelResponse ]
        \cup [ tag : {QuoteProtectionResetRequestCode}, body : QuoteProtectionResetRequest ]
        \cup [ tag : {QuoteProtectionResetResponseCode}, body : QuoteProtectionResetResponse ]
        \cup [ tag : {QuoteProtectionTriggerNotificationCode}, body : QuoteProtectionTriggerNotification ]
        \cup [ tag : {LiquiditySeekingEventNotificationCode}, body : LiquiditySeekingEventNotification ]
        \cup [ tag : {CancelNotificationCode2}, body : CancelNotification2 ]

EncodeUnsequencedMessage(message) ==
    CASE message.tag = ArmSettingsUpdateRequestCode -> EncodeArmSettingsUpdateRequest(message.body)
      [] message.tag = ArmSettingsUpdateResponseCode -> EncodeArmSettingsUpdateResponse(message.body)
      [] message.tag = BulkQuoteMessageCode -> EncodeBulkQuoteMessage(message.body)
      [] message.tag = BulkQuoteResponseCode -> EncodeBulkQuoteResponse(message.body)
      [] message.tag = EnhancedQuoteEQuoteMessageCode -> EncodeEnhancedQuoteEQuoteMessage(message.body)
      [] message.tag = MassQuoteCancelRequestCode -> EncodeMassQuoteCancelRequest(message.body)
      [] message.tag = MassQuoteCancelResponseCode -> EncodeMassQuoteCancelResponse(message.body)
      [] message.tag = QuoteProtectionResetRequestCode -> EncodeQuoteProtectionResetRequest(message.body)
      [] message.tag = QuoteProtectionResetResponseCode -> EncodeQuoteProtectionResetResponse(message.body)
      [] message.tag = QuoteProtectionTriggerNotificationCode -> EncodeQuoteProtectionTriggerNotification(message.body)
      [] message.tag = LiquiditySeekingEventNotificationCode -> EncodeLiquiditySeekingEventNotification(message.body)
      [] message.tag = CancelNotificationCode2 -> EncodeCancelNotification2(message.body)

DecodeUnsequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = ArmSettingsUpdateRequestCode -> DecodeArmSettingsUpdateRequest(bytes)
              [] tag = ArmSettingsUpdateResponseCode -> DecodeArmSettingsUpdateResponse(bytes)
              [] tag = BulkQuoteMessageCode -> DecodeBulkQuoteMessage(bytes)
              [] tag = BulkQuoteResponseCode -> DecodeBulkQuoteResponse(bytes)
              [] tag = EnhancedQuoteEQuoteMessageCode -> DecodeEnhancedQuoteEQuoteMessage(bytes)
              [] tag = MassQuoteCancelRequestCode -> DecodeMassQuoteCancelRequest(bytes)
              [] tag = MassQuoteCancelResponseCode -> DecodeMassQuoteCancelResponse(bytes)
              [] tag = QuoteProtectionResetRequestCode -> DecodeQuoteProtectionResetRequest(bytes)
              [] tag = QuoteProtectionResetResponseCode -> DecodeQuoteProtectionResetResponse(bytes)
              [] tag = QuoteProtectionTriggerNotificationCode -> DecodeQuoteProtectionTriggerNotification(bytes)
              [] tag = LiquiditySeekingEventNotificationCode -> DecodeLiquiditySeekingEventNotification(bytes)
              [] tag = CancelNotificationCode2 -> DecodeCancelNotification2(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroUnsequencedMessage == [tag |-> ArmSettingsUpdateRequestCode, body |-> ZeroArmSettingsUpdateRequest]

(* Each Unsequenced Message in turn, at the values the message it names is checked at *)
CheckedUnsequencedMessage ==
    { [tag |-> ArmSettingsUpdateRequestCode, body |-> one] : one \in CheckedArmSettingsUpdateRequest }
        \cup { [tag |-> ArmSettingsUpdateResponseCode, body |-> one] : one \in CheckedArmSettingsUpdateResponse }
        \cup { [tag |-> BulkQuoteMessageCode, body |-> one] : one \in CheckedBulkQuoteMessage }
        \cup { [tag |-> BulkQuoteResponseCode, body |-> one] : one \in CheckedBulkQuoteResponse }
        \cup { [tag |-> EnhancedQuoteEQuoteMessageCode, body |-> one] : one \in CheckedEnhancedQuoteEQuoteMessage }
        \cup { [tag |-> MassQuoteCancelRequestCode, body |-> one] : one \in CheckedMassQuoteCancelRequest }
        \cup { [tag |-> MassQuoteCancelResponseCode, body |-> one] : one \in CheckedMassQuoteCancelResponse }
        \cup { [tag |-> QuoteProtectionResetRequestCode, body |-> one] : one \in CheckedQuoteProtectionResetRequest }
        \cup { [tag |-> QuoteProtectionResetResponseCode, body |-> one] : one \in CheckedQuoteProtectionResetResponse }
        \cup { [tag |-> QuoteProtectionTriggerNotificationCode, body |-> one] : one \in CheckedQuoteProtectionTriggerNotification }
        \cup { [tag |-> LiquiditySeekingEventNotificationCode, body |-> one] : one \in CheckedLiquiditySeekingEventNotification }
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

(* Every Series Update decodes back to what was encoded, and leaves nothing over *)
RoundTripSeriesUpdate ==
    \A message \in CheckedSeriesUpdate :
        LET read == DecodeSeriesUpdate(EncodeSeriesUpdate(message))
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

(* Every Enhanced Quote E Quote Response decodes back to what was encoded, and leaves nothing over *)
RoundTripEnhancedQuoteEQuoteResponse ==
    \A message \in CheckedEnhancedQuoteEQuoteResponse :
        LET read == DecodeEnhancedQuoteEQuoteResponse(EncodeEnhancedQuoteEQuoteResponse(message))
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

(* Every Trading Status Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingStatusNotification ==
    \A message \in CheckedTradingStatusNotification :
        LET read == DecodeTradingStatusNotification(EncodeTradingStatusNotification(message))
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

(* Every Arm Protection Settings Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripArmProtectionSettingsNotification ==
    \A message \in CheckedArmProtectionSettingsNotification :
        LET read == DecodeArmProtectionSettingsNotification(EncodeArmProtectionSettingsNotification(message))
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

(* Every Execution Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionNotification ==
    \A message \in CheckedExecutionNotification :
        LET read == DecodeExecutionNotification(EncodeExecutionNotification(message))
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

(* Every Arm Settings Update Request decodes back to what was encoded, and leaves nothing over *)
RoundTripArmSettingsUpdateRequest ==
    \A message \in CheckedArmSettingsUpdateRequest :
        LET read == DecodeArmSettingsUpdateRequest(EncodeArmSettingsUpdateRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Arm Settings Update Response decodes back to what was encoded, and leaves nothing over *)
RoundTripArmSettingsUpdateResponse ==
    \A message \in CheckedArmSettingsUpdateResponse :
        LET read == DecodeArmSettingsUpdateResponse(EncodeArmSettingsUpdateResponse(message))
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

(* Every Bulk Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkQuoteMessage ==
    \A message \in CheckedBulkQuoteMessage :
        LET read == DecodeBulkQuoteMessage(EncodeBulkQuoteMessage(message))
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

(* Every Bulk Quote Response decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkQuoteResponse ==
    \A message \in CheckedBulkQuoteResponse :
        LET read == DecodeBulkQuoteResponse(EncodeBulkQuoteResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Enhanced Quote E Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEnhancedQuoteEQuoteMessage ==
    \A message \in CheckedEnhancedQuoteEQuoteMessage :
        LET read == DecodeEnhancedQuoteEQuoteMessage(EncodeEnhancedQuoteEQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Quote Cancel Request decodes back to what was encoded, and leaves nothing over *)
RoundTripMassQuoteCancelRequest ==
    \A message \in CheckedMassQuoteCancelRequest :
        LET read == DecodeMassQuoteCancelRequest(EncodeMassQuoteCancelRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Quote Cancel Response decodes back to what was encoded, and leaves nothing over *)
RoundTripMassQuoteCancelResponse ==
    \A message \in CheckedMassQuoteCancelResponse :
        LET read == DecodeMassQuoteCancelResponse(EncodeMassQuoteCancelResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Protection Reset Request decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteProtectionResetRequest ==
    \A message \in CheckedQuoteProtectionResetRequest :
        LET read == DecodeQuoteProtectionResetRequest(EncodeQuoteProtectionResetRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Protection Reset Response decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteProtectionResetResponse ==
    \A message \in CheckedQuoteProtectionResetResponse :
        LET read == DecodeQuoteProtectionResetResponse(EncodeQuoteProtectionResetResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Protection Trigger Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteProtectionTriggerNotification ==
    \A message \in CheckedQuoteProtectionTriggerNotification :
        LET read == DecodeQuoteProtectionTriggerNotification(EncodeQuoteProtectionTriggerNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Liquidity Seeking Event Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripLiquiditySeekingEventNotification ==
    \A message \in CheckedLiquiditySeekingEventNotification :
        LET read == DecodeLiquiditySeekingEventNotification(EncodeLiquiditySeekingEventNotification(message))
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
