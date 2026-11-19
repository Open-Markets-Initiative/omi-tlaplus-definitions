----------------- MODULE PearlOptions_ExpressOrders_v2_0_c -----------------
(***************************************************************************)
(* Miami International Holdings Express Orders v2.0.c                      *)
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
      activeOnPearl                     : Sample(1),
      pearlBboPostingIncrementIndicator : Sample(1),
      orderAcceptanceIncrementIndicator : Sample(1),
      openingUnderlyingMarketCode       : Sample(1),
      reserved12                        : Sample(12) ]

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
        \o message.activeOnPearl
        \o message.pearlBboPostingIncrementIndicator
        \o message.orderAcceptanceIncrementIndicator
        \o message.openingUnderlyingMarketCode
        \o message.reserved12

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
    LET activeOnPearl == ReadBytes(longTermOption.rest, 1) IN IF ~activeOnPearl.ok THEN Fail ELSE
    LET pearlBboPostingIncrementIndicator == ReadBytes(activeOnPearl.rest, 1) IN IF ~pearlBboPostingIncrementIndicator.ok THEN Fail ELSE
    LET orderAcceptanceIncrementIndicator == ReadBytes(pearlBboPostingIncrementIndicator.rest, 1) IN IF ~orderAcceptanceIncrementIndicator.ok THEN Fail ELSE
    LET openingUnderlyingMarketCode == ReadBytes(orderAcceptanceIncrementIndicator.rest, 1) IN IF ~openingUnderlyingMarketCode.ok THEN Fail ELSE
    LET reserved12 == ReadBytes(openingUnderlyingMarketCode.rest, 12) IN IF ~reserved12.ok THEN Fail ELSE
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
         activeOnPearl                     |-> activeOnPearl.value,
         pearlBboPostingIncrementIndicator |-> pearlBboPostingIncrementIndicator.value,
         orderAcceptanceIncrementIndicator |-> orderAcceptanceIncrementIndicator.value,
         openingUnderlyingMarketCode       |-> openingUnderlyingMarketCode.value,
         reserved12                        |-> reserved12.value ], reserved12.rest)

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
      activeOnPearl                     |-> [i \in 1 .. 1 |-> 0],
      pearlBboPostingIncrementIndicator |-> [i \in 1 .. 1 |-> 0],
      orderAcceptanceIncrementIndicator |-> [i \in 1 .. 1 |-> 0],
      openingUnderlyingMarketCode       |-> [i \in 1 .. 1 |-> 0],
      reserved12                        |-> [i \in 1 .. 12 |-> 0] ]

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
        \cup { [ZeroSeriesUpdate EXCEPT !.activeOnPearl = one] : one \in Sample(1) }
        \cup { [ZeroSeriesUpdate EXCEPT !.pearlBboPostingIncrementIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSeriesUpdate EXCEPT !.orderAcceptanceIncrementIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSeriesUpdate EXCEPT !.openingUnderlyingMarketCode = one] : one \in Sample(1) }
        \cup { [ZeroSeriesUpdate EXCEPT !.reserved12 = one] : one \in Sample(12) }

(***************************************************************************)
(* System State Notification: 18 bytes                                     *)
(***************************************************************************)

SystemStateNotification ==
    [ notificationTime : Sample(8),
      meoVersion       : Sample(8),
      sessionId        : Sample(1),
      systemStatus     : Sample(1) ]

EncodeSystemStateNotification(message) ==
    message.notificationTime
        \o message.meoVersion
        \o message.sessionId
        \o message.systemStatus

DecodeSystemStateNotification(bytes) ==
    LET notificationTime == ReadBytes(bytes, 8) IN IF ~notificationTime.ok THEN Fail ELSE
    LET meoVersion == ReadBytes(notificationTime.rest, 8) IN IF ~meoVersion.ok THEN Fail ELSE
    LET sessionId == ReadBytes(meoVersion.rest, 1) IN IF ~sessionId.ok THEN Fail ELSE
    LET systemStatus == ReadBytes(sessionId.rest, 1) IN IF ~systemStatus.ok THEN Fail ELSE
    Ok([ notificationTime |-> notificationTime.value,
         meoVersion       |-> meoVersion.value,
         sessionId        |-> sessionId.value,
         systemStatus     |-> systemStatus.value ], systemStatus.rest)

ZeroSystemStateNotification ==
    [ notificationTime |-> [i \in 1 .. 8 |-> 0],
      meoVersion       |-> [i \in 1 .. 8 |-> 0],
      sessionId        |-> [i \in 1 .. 1 |-> 0],
      systemStatus     |-> [i \in 1 .. 1 |-> 0] ]

(* System State Notification at zero, then each field in turn at the values it is checked at *)
CheckedSystemStateNotification ==
    { ZeroSystemStateNotification }
        \cup { [ZeroSystemStateNotification EXCEPT !.notificationTime = one] : one \in Sample(8) }
        \cup { [ZeroSystemStateNotification EXCEPT !.meoVersion = one] : one \in Sample(8) }
        \cup { [ZeroSystemStateNotification EXCEPT !.sessionId = one] : one \in Sample(1) }
        \cup { [ZeroSystemStateNotification EXCEPT !.systemStatus = one] : one \in Sample(1) }

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
(* Opening Width Relief Notification: 23 bytes                             *)
(***************************************************************************)

OpeningWidthReliefNotification ==
    [ notificationTime : Sample(8),
      underlyingSymbol : Sample(11),
      reliefMultiplier : Sample(4) ]

EncodeOpeningWidthReliefNotification(message) ==
    message.notificationTime
        \o message.underlyingSymbol
        \o message.reliefMultiplier

DecodeOpeningWidthReliefNotification(bytes) ==
    LET notificationTime == ReadBytes(bytes, 8) IN IF ~notificationTime.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(notificationTime.rest, 11) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET reliefMultiplier == ReadBytes(underlyingSymbol.rest, 4) IN IF ~reliefMultiplier.ok THEN Fail ELSE
    Ok([ notificationTime |-> notificationTime.value,
         underlyingSymbol |-> underlyingSymbol.value,
         reliefMultiplier |-> reliefMultiplier.value ], reliefMultiplier.rest)

ZeroOpeningWidthReliefNotification ==
    [ notificationTime |-> [i \in 1 .. 8 |-> 0],
      underlyingSymbol |-> [i \in 1 .. 11 |-> 0],
      reliefMultiplier |-> [i \in 1 .. 4 |-> 0] ]

(* Opening Width Relief Notification at zero, then each field in turn at the values it is checked at *)
CheckedOpeningWidthReliefNotification ==
    { ZeroOpeningWidthReliefNotification }
        \cup { [ZeroOpeningWidthReliefNotification EXCEPT !.notificationTime = one] : one \in Sample(8) }
        \cup { [ZeroOpeningWidthReliefNotification EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }
        \cup { [ZeroOpeningWidthReliefNotification EXCEPT !.reliefMultiplier = one] : one \in Sample(4) }

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
(* Arm 2 Underlying Level Protection Settings Notification: 48 bytes       *)
(***************************************************************************)

Arm2UnderlyingLevelProtectionSettingsNotification ==
    [ notificationTime   : Sample(8),
      mpid               : Sample(4),
      action             : Sample(1),
      underlyingSymbol   : Sample(11),
      armThresholdCount  : Sample(4),
      arm2CountingPeriod : Sample(4),
      reserved16         : Sample(16) ]

EncodeArm2UnderlyingLevelProtectionSettingsNotification(message) ==
    message.notificationTime
        \o message.mpid
        \o message.action
        \o message.underlyingSymbol
        \o message.armThresholdCount
        \o message.arm2CountingPeriod
        \o message.reserved16

DecodeArm2UnderlyingLevelProtectionSettingsNotification(bytes) ==
    LET notificationTime == ReadBytes(bytes, 8) IN IF ~notificationTime.ok THEN Fail ELSE
    LET mpid == ReadBytes(notificationTime.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET action == ReadBytes(mpid.rest, 1) IN IF ~action.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(action.rest, 11) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET armThresholdCount == ReadBytes(underlyingSymbol.rest, 4) IN IF ~armThresholdCount.ok THEN Fail ELSE
    LET arm2CountingPeriod == ReadBytes(armThresholdCount.rest, 4) IN IF ~arm2CountingPeriod.ok THEN Fail ELSE
    LET reserved16 == ReadBytes(arm2CountingPeriod.rest, 16) IN IF ~reserved16.ok THEN Fail ELSE
    Ok([ notificationTime   |-> notificationTime.value,
         mpid               |-> mpid.value,
         action             |-> action.value,
         underlyingSymbol   |-> underlyingSymbol.value,
         armThresholdCount  |-> armThresholdCount.value,
         arm2CountingPeriod |-> arm2CountingPeriod.value,
         reserved16         |-> reserved16.value ], reserved16.rest)

ZeroArm2UnderlyingLevelProtectionSettingsNotification ==
    [ notificationTime   |-> [i \in 1 .. 8 |-> 0],
      mpid               |-> [i \in 1 .. 4 |-> 0],
      action             |-> [i \in 1 .. 1 |-> 0],
      underlyingSymbol   |-> [i \in 1 .. 11 |-> 0],
      armThresholdCount  |-> [i \in 1 .. 4 |-> 0],
      arm2CountingPeriod |-> [i \in 1 .. 4 |-> 0],
      reserved16         |-> [i \in 1 .. 16 |-> 0] ]

(* Arm 2 Underlying Level Protection Settings Notification at zero, then each field in turn at the values it is checked at *)
CheckedArm2UnderlyingLevelProtectionSettingsNotification ==
    { ZeroArm2UnderlyingLevelProtectionSettingsNotification }
        \cup { [ZeroArm2UnderlyingLevelProtectionSettingsNotification EXCEPT !.notificationTime = one] : one \in Sample(8) }
        \cup { [ZeroArm2UnderlyingLevelProtectionSettingsNotification EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroArm2UnderlyingLevelProtectionSettingsNotification EXCEPT !.action = one] : one \in Sample(1) }
        \cup { [ZeroArm2UnderlyingLevelProtectionSettingsNotification EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }
        \cup { [ZeroArm2UnderlyingLevelProtectionSettingsNotification EXCEPT !.armThresholdCount = one] : one \in Sample(4) }
        \cup { [ZeroArm2UnderlyingLevelProtectionSettingsNotification EXCEPT !.arm2CountingPeriod = one] : one \in Sample(4) }
        \cup { [ZeroArm2UnderlyingLevelProtectionSettingsNotification EXCEPT !.reserved16 = one] : one \in Sample(16) }

(***************************************************************************)
(* Single Side Liquidity Protection Trigger Notification: 26 bytes         *)
(***************************************************************************)

SingleSideLiquidityProtectionTriggerNotification ==
    [ notificationTime          : Sample(8),
      mpid                      : Sample(4),
      productId                 : Sample(4),
      side                      : Sample(1),
      triggeringClientMessageId : Sample(4),
      triggeringBulkOrderIndex  : Sample(1),
      reserved4                 : Sample(4) ]

EncodeSingleSideLiquidityProtectionTriggerNotification(message) ==
    message.notificationTime
        \o message.mpid
        \o message.productId
        \o message.side
        \o message.triggeringClientMessageId
        \o message.triggeringBulkOrderIndex
        \o message.reserved4

DecodeSingleSideLiquidityProtectionTriggerNotification(bytes) ==
    LET notificationTime == ReadBytes(bytes, 8) IN IF ~notificationTime.ok THEN Fail ELSE
    LET mpid == ReadBytes(notificationTime.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET productId == ReadBytes(mpid.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET side == ReadBytes(productId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET triggeringClientMessageId == ReadBytes(side.rest, 4) IN IF ~triggeringClientMessageId.ok THEN Fail ELSE
    LET triggeringBulkOrderIndex == ReadBytes(triggeringClientMessageId.rest, 1) IN IF ~triggeringBulkOrderIndex.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(triggeringBulkOrderIndex.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    Ok([ notificationTime          |-> notificationTime.value,
         mpid                      |-> mpid.value,
         productId                 |-> productId.value,
         side                      |-> side.value,
         triggeringClientMessageId |-> triggeringClientMessageId.value,
         triggeringBulkOrderIndex  |-> triggeringBulkOrderIndex.value,
         reserved4                 |-> reserved4.value ], reserved4.rest)

ZeroSingleSideLiquidityProtectionTriggerNotification ==
    [ notificationTime          |-> [i \in 1 .. 8 |-> 0],
      mpid                      |-> [i \in 1 .. 4 |-> 0],
      productId                 |-> [i \in 1 .. 4 |-> 0],
      side                      |-> [i \in 1 .. 1 |-> 0],
      triggeringClientMessageId |-> [i \in 1 .. 4 |-> 0],
      triggeringBulkOrderIndex  |-> [i \in 1 .. 1 |-> 0],
      reserved4                 |-> [i \in 1 .. 4 |-> 0] ]

(* Single Side Liquidity Protection Trigger Notification at zero, then each field in turn at the values it is checked at *)
CheckedSingleSideLiquidityProtectionTriggerNotification ==
    { ZeroSingleSideLiquidityProtectionTriggerNotification }
        \cup { [ZeroSingleSideLiquidityProtectionTriggerNotification EXCEPT !.notificationTime = one] : one \in Sample(8) }
        \cup { [ZeroSingleSideLiquidityProtectionTriggerNotification EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideLiquidityProtectionTriggerNotification EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideLiquidityProtectionTriggerNotification EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroSingleSideLiquidityProtectionTriggerNotification EXCEPT !.triggeringClientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideLiquidityProtectionTriggerNotification EXCEPT !.triggeringBulkOrderIndex = one] : one \in Sample(1) }
        \cup { [ZeroSingleSideLiquidityProtectionTriggerNotification EXCEPT !.reserved4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Arm 2 Underlying Level Protection Notification: 48 bytes                *)
(***************************************************************************)

Arm2UnderlyingLevelProtectionNotification ==
    [ notificationTime   : Sample(8),
      mpid               : Sample(4),
      underlyingSymbol   : Sample(11),
      notificationType   : Sample(1),
      armThresholdCount  : Sample(4),
      arm2CountingPeriod : Sample(4),
      reserved16         : Sample(16) ]

EncodeArm2UnderlyingLevelProtectionNotification(message) ==
    message.notificationTime
        \o message.mpid
        \o message.underlyingSymbol
        \o message.notificationType
        \o message.armThresholdCount
        \o message.arm2CountingPeriod
        \o message.reserved16

DecodeArm2UnderlyingLevelProtectionNotification(bytes) ==
    LET notificationTime == ReadBytes(bytes, 8) IN IF ~notificationTime.ok THEN Fail ELSE
    LET mpid == ReadBytes(notificationTime.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(mpid.rest, 11) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET notificationType == ReadBytes(underlyingSymbol.rest, 1) IN IF ~notificationType.ok THEN Fail ELSE
    LET armThresholdCount == ReadBytes(notificationType.rest, 4) IN IF ~armThresholdCount.ok THEN Fail ELSE
    LET arm2CountingPeriod == ReadBytes(armThresholdCount.rest, 4) IN IF ~arm2CountingPeriod.ok THEN Fail ELSE
    LET reserved16 == ReadBytes(arm2CountingPeriod.rest, 16) IN IF ~reserved16.ok THEN Fail ELSE
    Ok([ notificationTime   |-> notificationTime.value,
         mpid               |-> mpid.value,
         underlyingSymbol   |-> underlyingSymbol.value,
         notificationType   |-> notificationType.value,
         armThresholdCount  |-> armThresholdCount.value,
         arm2CountingPeriod |-> arm2CountingPeriod.value,
         reserved16         |-> reserved16.value ], reserved16.rest)

ZeroArm2UnderlyingLevelProtectionNotification ==
    [ notificationTime   |-> [i \in 1 .. 8 |-> 0],
      mpid               |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbol   |-> [i \in 1 .. 11 |-> 0],
      notificationType   |-> [i \in 1 .. 1 |-> 0],
      armThresholdCount  |-> [i \in 1 .. 4 |-> 0],
      arm2CountingPeriod |-> [i \in 1 .. 4 |-> 0],
      reserved16         |-> [i \in 1 .. 16 |-> 0] ]

(* Arm 2 Underlying Level Protection Notification at zero, then each field in turn at the values it is checked at *)
CheckedArm2UnderlyingLevelProtectionNotification ==
    { ZeroArm2UnderlyingLevelProtectionNotification }
        \cup { [ZeroArm2UnderlyingLevelProtectionNotification EXCEPT !.notificationTime = one] : one \in Sample(8) }
        \cup { [ZeroArm2UnderlyingLevelProtectionNotification EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroArm2UnderlyingLevelProtectionNotification EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }
        \cup { [ZeroArm2UnderlyingLevelProtectionNotification EXCEPT !.notificationType = one] : one \in Sample(1) }
        \cup { [ZeroArm2UnderlyingLevelProtectionNotification EXCEPT !.armThresholdCount = one] : one \in Sample(4) }
        \cup { [ZeroArm2UnderlyingLevelProtectionNotification EXCEPT !.arm2CountingPeriod = one] : one \in Sample(4) }
        \cup { [ZeroArm2UnderlyingLevelProtectionNotification EXCEPT !.reserved16 = one] : one \in Sample(16) }

(***************************************************************************)
(* Arm 2 Firm Level Protection Notification: 33 bytes                      *)
(***************************************************************************)

Arm2FirmLevelProtectionNotification ==
    [ notificationTime   : Sample(8),
      armThresholdCount  : Sample(4),
      arm2CountingPeriod : Sample(4),
      notificationType   : Sample(1),
      reserved16         : Sample(16) ]

EncodeArm2FirmLevelProtectionNotification(message) ==
    message.notificationTime
        \o message.armThresholdCount
        \o message.arm2CountingPeriod
        \o message.notificationType
        \o message.reserved16

DecodeArm2FirmLevelProtectionNotification(bytes) ==
    LET notificationTime == ReadBytes(bytes, 8) IN IF ~notificationTime.ok THEN Fail ELSE
    LET armThresholdCount == ReadBytes(notificationTime.rest, 4) IN IF ~armThresholdCount.ok THEN Fail ELSE
    LET arm2CountingPeriod == ReadBytes(armThresholdCount.rest, 4) IN IF ~arm2CountingPeriod.ok THEN Fail ELSE
    LET notificationType == ReadBytes(arm2CountingPeriod.rest, 1) IN IF ~notificationType.ok THEN Fail ELSE
    LET reserved16 == ReadBytes(notificationType.rest, 16) IN IF ~reserved16.ok THEN Fail ELSE
    Ok([ notificationTime   |-> notificationTime.value,
         armThresholdCount  |-> armThresholdCount.value,
         arm2CountingPeriod |-> arm2CountingPeriod.value,
         notificationType   |-> notificationType.value,
         reserved16         |-> reserved16.value ], reserved16.rest)

ZeroArm2FirmLevelProtectionNotification ==
    [ notificationTime   |-> [i \in 1 .. 8 |-> 0],
      armThresholdCount  |-> [i \in 1 .. 4 |-> 0],
      arm2CountingPeriod |-> [i \in 1 .. 4 |-> 0],
      notificationType   |-> [i \in 1 .. 1 |-> 0],
      reserved16         |-> [i \in 1 .. 16 |-> 0] ]

(* Arm 2 Firm Level Protection Notification at zero, then each field in turn at the values it is checked at *)
CheckedArm2FirmLevelProtectionNotification ==
    { ZeroArm2FirmLevelProtectionNotification }
        \cup { [ZeroArm2FirmLevelProtectionNotification EXCEPT !.notificationTime = one] : one \in Sample(8) }
        \cup { [ZeroArm2FirmLevelProtectionNotification EXCEPT !.armThresholdCount = one] : one \in Sample(4) }
        \cup { [ZeroArm2FirmLevelProtectionNotification EXCEPT !.arm2CountingPeriod = one] : one \in Sample(4) }
        \cup { [ZeroArm2FirmLevelProtectionNotification EXCEPT !.notificationType = one] : one \in Sample(1) }
        \cup { [ZeroArm2FirmLevelProtectionNotification EXCEPT !.reserved16 = one] : one \in Sample(16) }

(***************************************************************************)
(* Cancel Notification: 40 bytes                                           *)
(***************************************************************************)

CancelNotification ==
    [ notificationTime     : Sample(8),
      mpid                 : Sample(4),
      productId            : Sample(4),
      liquidityType        : Sample(1),
      clientMessageId      : Sample(4),
      clientOrderId        : Sample(4),
      bulkOrderIndex       : Sample(1),
      side                 : Sample(1),
      size                 : Sample(4),
      engineSequenceNumber : Sample(8),
      cancelReason         : Sample(1) ]

EncodeCancelNotification(message) ==
    message.notificationTime
        \o message.mpid
        \o message.productId
        \o message.liquidityType
        \o message.clientMessageId
        \o message.clientOrderId
        \o message.bulkOrderIndex
        \o message.side
        \o message.size
        \o message.engineSequenceNumber
        \o message.cancelReason

DecodeCancelNotification(bytes) ==
    LET notificationTime == ReadBytes(bytes, 8) IN IF ~notificationTime.ok THEN Fail ELSE
    LET mpid == ReadBytes(notificationTime.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET productId == ReadBytes(mpid.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET liquidityType == ReadBytes(productId.rest, 1) IN IF ~liquidityType.ok THEN Fail ELSE
    LET clientMessageId == ReadBytes(liquidityType.rest, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(clientMessageId.rest, 4) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET bulkOrderIndex == ReadBytes(clientOrderId.rest, 1) IN IF ~bulkOrderIndex.ok THEN Fail ELSE
    LET side == ReadBytes(bulkOrderIndex.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET size == ReadBytes(side.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET engineSequenceNumber == ReadBytes(size.rest, 8) IN IF ~engineSequenceNumber.ok THEN Fail ELSE
    LET cancelReason == ReadBytes(engineSequenceNumber.rest, 1) IN IF ~cancelReason.ok THEN Fail ELSE
    Ok([ notificationTime     |-> notificationTime.value,
         mpid                 |-> mpid.value,
         productId            |-> productId.value,
         liquidityType        |-> liquidityType.value,
         clientMessageId      |-> clientMessageId.value,
         clientOrderId        |-> clientOrderId.value,
         bulkOrderIndex       |-> bulkOrderIndex.value,
         side                 |-> side.value,
         size                 |-> size.value,
         engineSequenceNumber |-> engineSequenceNumber.value,
         cancelReason         |-> cancelReason.value ], cancelReason.rest)

ZeroCancelNotification ==
    [ notificationTime     |-> [i \in 1 .. 8 |-> 0],
      mpid                 |-> [i \in 1 .. 4 |-> 0],
      productId            |-> [i \in 1 .. 4 |-> 0],
      liquidityType        |-> [i \in 1 .. 1 |-> 0],
      clientMessageId      |-> [i \in 1 .. 4 |-> 0],
      clientOrderId        |-> [i \in 1 .. 4 |-> 0],
      bulkOrderIndex       |-> [i \in 1 .. 1 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
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
        \cup { [ZeroCancelNotification EXCEPT !.clientOrderId = one] : one \in Sample(4) }
        \cup { [ZeroCancelNotification EXCEPT !.bulkOrderIndex = one] : one \in Sample(1) }
        \cup { [ZeroCancelNotification EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroCancelNotification EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroCancelNotification EXCEPT !.engineSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroCancelNotification EXCEPT !.cancelReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Execution Notification: 64 bytes                                        *)
(***************************************************************************)

ExecutionNotification ==
    [ notificationTime   : Sample(8),
      mpid               : Sample(4),
      productId          : Sample(4),
      liquidityType      : Sample(1),
      clientMessageId    : Sample(4),
      clientOrderId      : Sample(4),
      bulkOrderIndex     : Sample(1),
      tradeId            : Sample(4),
      executionId        : Sample(8),
      tradeStatus        : Sample(1),
      lastPrice          : Sample(4),
      side               : Sample(1),
      lastSize           : Sample(4),
      liquidityIndicator : Sample(1),
      reserved15         : Sample(15) ]

EncodeExecutionNotification(message) ==
    message.notificationTime
        \o message.mpid
        \o message.productId
        \o message.liquidityType
        \o message.clientMessageId
        \o message.clientOrderId
        \o message.bulkOrderIndex
        \o message.tradeId
        \o message.executionId
        \o message.tradeStatus
        \o message.lastPrice
        \o message.side
        \o message.lastSize
        \o message.liquidityIndicator
        \o message.reserved15

DecodeExecutionNotification(bytes) ==
    LET notificationTime == ReadBytes(bytes, 8) IN IF ~notificationTime.ok THEN Fail ELSE
    LET mpid == ReadBytes(notificationTime.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET productId == ReadBytes(mpid.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET liquidityType == ReadBytes(productId.rest, 1) IN IF ~liquidityType.ok THEN Fail ELSE
    LET clientMessageId == ReadBytes(liquidityType.rest, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(clientMessageId.rest, 4) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET bulkOrderIndex == ReadBytes(clientOrderId.rest, 1) IN IF ~bulkOrderIndex.ok THEN Fail ELSE
    LET tradeId == ReadBytes(bulkOrderIndex.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET executionId == ReadBytes(tradeId.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET tradeStatus == ReadBytes(executionId.rest, 1) IN IF ~tradeStatus.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(tradeStatus.rest, 4) IN IF ~lastPrice.ok THEN Fail ELSE
    LET side == ReadBytes(lastPrice.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET lastSize == ReadBytes(side.rest, 4) IN IF ~lastSize.ok THEN Fail ELSE
    LET liquidityIndicator == ReadBytes(lastSize.rest, 1) IN IF ~liquidityIndicator.ok THEN Fail ELSE
    LET reserved15 == ReadBytes(liquidityIndicator.rest, 15) IN IF ~reserved15.ok THEN Fail ELSE
    Ok([ notificationTime   |-> notificationTime.value,
         mpid               |-> mpid.value,
         productId          |-> productId.value,
         liquidityType      |-> liquidityType.value,
         clientMessageId    |-> clientMessageId.value,
         clientOrderId      |-> clientOrderId.value,
         bulkOrderIndex     |-> bulkOrderIndex.value,
         tradeId            |-> tradeId.value,
         executionId        |-> executionId.value,
         tradeStatus        |-> tradeStatus.value,
         lastPrice          |-> lastPrice.value,
         side               |-> side.value,
         lastSize           |-> lastSize.value,
         liquidityIndicator |-> liquidityIndicator.value,
         reserved15         |-> reserved15.value ], reserved15.rest)

ZeroExecutionNotification ==
    [ notificationTime   |-> [i \in 1 .. 8 |-> 0],
      mpid               |-> [i \in 1 .. 4 |-> 0],
      productId          |-> [i \in 1 .. 4 |-> 0],
      liquidityType      |-> [i \in 1 .. 1 |-> 0],
      clientMessageId    |-> [i \in 1 .. 4 |-> 0],
      clientOrderId      |-> [i \in 1 .. 4 |-> 0],
      bulkOrderIndex     |-> [i \in 1 .. 1 |-> 0],
      tradeId            |-> [i \in 1 .. 4 |-> 0],
      executionId        |-> [i \in 1 .. 8 |-> 0],
      tradeStatus        |-> [i \in 1 .. 1 |-> 0],
      lastPrice          |-> [i \in 1 .. 4 |-> 0],
      side               |-> [i \in 1 .. 1 |-> 0],
      lastSize           |-> [i \in 1 .. 4 |-> 0],
      liquidityIndicator |-> [i \in 1 .. 1 |-> 0],
      reserved15         |-> [i \in 1 .. 15 |-> 0] ]

(* Execution Notification at zero, then each field in turn at the values it is checked at *)
CheckedExecutionNotification ==
    { ZeroExecutionNotification }
        \cup { [ZeroExecutionNotification EXCEPT !.notificationTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionNotification EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroExecutionNotification EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionNotification EXCEPT !.liquidityType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionNotification EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionNotification EXCEPT !.clientOrderId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionNotification EXCEPT !.bulkOrderIndex = one] : one \in Sample(1) }
        \cup { [ZeroExecutionNotification EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionNotification EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionNotification EXCEPT !.tradeStatus = one] : one \in Sample(1) }
        \cup { [ZeroExecutionNotification EXCEPT !.lastPrice = one] : one \in Sample(4) }
        \cup { [ZeroExecutionNotification EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroExecutionNotification EXCEPT !.lastSize = one] : one \in Sample(4) }
        \cup { [ZeroExecutionNotification EXCEPT !.liquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExecutionNotification EXCEPT !.reserved15 = one] : one \in Sample(15) }

(***************************************************************************)
(* Sequenced Message, selected by Sequenced Message Type                   *)
(***************************************************************************)

SeriesUpdateCode == 21333  \* "SU"
SystemStateNotificationCode == 21326  \* "SN"
UnderlyingTradingStatusNotificationCode == 21838  \* "UN"
OpeningWidthReliefNotificationCode == 20814  \* "QN"
ArmProtectionSettingsNotificationCode == 16718  \* "AN"
Arm2UnderlyingLevelProtectionSettingsNotificationCode == 16690  \* "A2"
SingleSideLiquidityProtectionTriggerNotificationCode == 20824  \* "QX"
Arm2UnderlyingLevelProtectionNotificationCode == 21840  \* "UP"
Arm2FirmLevelProtectionNotificationCode == 18000  \* "FP"
CancelNotificationCode == 22606  \* "XN"
ExecutionNotificationCode == 17742  \* "EN"

SequencedMessage ==
    [ tag : {SeriesUpdateCode}, body : SeriesUpdate ]
        \cup [ tag : {SystemStateNotificationCode}, body : SystemStateNotification ]
        \cup [ tag : {UnderlyingTradingStatusNotificationCode}, body : UnderlyingTradingStatusNotification ]
        \cup [ tag : {OpeningWidthReliefNotificationCode}, body : OpeningWidthReliefNotification ]
        \cup [ tag : {ArmProtectionSettingsNotificationCode}, body : ArmProtectionSettingsNotification ]
        \cup [ tag : {Arm2UnderlyingLevelProtectionSettingsNotificationCode}, body : Arm2UnderlyingLevelProtectionSettingsNotification ]
        \cup [ tag : {SingleSideLiquidityProtectionTriggerNotificationCode}, body : SingleSideLiquidityProtectionTriggerNotification ]
        \cup [ tag : {Arm2UnderlyingLevelProtectionNotificationCode}, body : Arm2UnderlyingLevelProtectionNotification ]
        \cup [ tag : {Arm2FirmLevelProtectionNotificationCode}, body : Arm2FirmLevelProtectionNotification ]
        \cup [ tag : {CancelNotificationCode}, body : CancelNotification ]
        \cup [ tag : {ExecutionNotificationCode}, body : ExecutionNotification ]

EncodeSequencedMessage(message) ==
    CASE message.tag = SeriesUpdateCode -> EncodeSeriesUpdate(message.body)
      [] message.tag = SystemStateNotificationCode -> EncodeSystemStateNotification(message.body)
      [] message.tag = UnderlyingTradingStatusNotificationCode -> EncodeUnderlyingTradingStatusNotification(message.body)
      [] message.tag = OpeningWidthReliefNotificationCode -> EncodeOpeningWidthReliefNotification(message.body)
      [] message.tag = ArmProtectionSettingsNotificationCode -> EncodeArmProtectionSettingsNotification(message.body)
      [] message.tag = Arm2UnderlyingLevelProtectionSettingsNotificationCode -> EncodeArm2UnderlyingLevelProtectionSettingsNotification(message.body)
      [] message.tag = SingleSideLiquidityProtectionTriggerNotificationCode -> EncodeSingleSideLiquidityProtectionTriggerNotification(message.body)
      [] message.tag = Arm2UnderlyingLevelProtectionNotificationCode -> EncodeArm2UnderlyingLevelProtectionNotification(message.body)
      [] message.tag = Arm2FirmLevelProtectionNotificationCode -> EncodeArm2FirmLevelProtectionNotification(message.body)
      [] message.tag = CancelNotificationCode -> EncodeCancelNotification(message.body)
      [] message.tag = ExecutionNotificationCode -> EncodeExecutionNotification(message.body)

DecodeSequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = SeriesUpdateCode -> DecodeSeriesUpdate(bytes)
              [] tag = SystemStateNotificationCode -> DecodeSystemStateNotification(bytes)
              [] tag = UnderlyingTradingStatusNotificationCode -> DecodeUnderlyingTradingStatusNotification(bytes)
              [] tag = OpeningWidthReliefNotificationCode -> DecodeOpeningWidthReliefNotification(bytes)
              [] tag = ArmProtectionSettingsNotificationCode -> DecodeArmProtectionSettingsNotification(bytes)
              [] tag = Arm2UnderlyingLevelProtectionSettingsNotificationCode -> DecodeArm2UnderlyingLevelProtectionSettingsNotification(bytes)
              [] tag = SingleSideLiquidityProtectionTriggerNotificationCode -> DecodeSingleSideLiquidityProtectionTriggerNotification(bytes)
              [] tag = Arm2UnderlyingLevelProtectionNotificationCode -> DecodeArm2UnderlyingLevelProtectionNotification(bytes)
              [] tag = Arm2FirmLevelProtectionNotificationCode -> DecodeArm2FirmLevelProtectionNotification(bytes)
              [] tag = CancelNotificationCode -> DecodeCancelNotification(bytes)
              [] tag = ExecutionNotificationCode -> DecodeExecutionNotification(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSequencedMessage == [tag |-> SeriesUpdateCode, body |-> ZeroSeriesUpdate]

(* Each Sequenced Message in turn, at the values the message it names is checked at *)
CheckedSequencedMessage ==
    { [tag |-> SeriesUpdateCode, body |-> one] : one \in CheckedSeriesUpdate }
        \cup { [tag |-> SystemStateNotificationCode, body |-> one] : one \in CheckedSystemStateNotification }
        \cup { [tag |-> UnderlyingTradingStatusNotificationCode, body |-> one] : one \in CheckedUnderlyingTradingStatusNotification }
        \cup { [tag |-> OpeningWidthReliefNotificationCode, body |-> one] : one \in CheckedOpeningWidthReliefNotification }
        \cup { [tag |-> ArmProtectionSettingsNotificationCode, body |-> one] : one \in CheckedArmProtectionSettingsNotification }
        \cup { [tag |-> Arm2UnderlyingLevelProtectionSettingsNotificationCode, body |-> one] : one \in CheckedArm2UnderlyingLevelProtectionSettingsNotification }
        \cup { [tag |-> SingleSideLiquidityProtectionTriggerNotificationCode, body |-> one] : one \in CheckedSingleSideLiquidityProtectionTriggerNotification }
        \cup { [tag |-> Arm2UnderlyingLevelProtectionNotificationCode, body |-> one] : one \in CheckedArm2UnderlyingLevelProtectionNotification }
        \cup { [tag |-> Arm2FirmLevelProtectionNotificationCode, body |-> one] : one \in CheckedArm2FirmLevelProtectionNotification }
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
(* Arm 2 Underlying Level Protection Settings Update Request: 28 bytes     *)
(***************************************************************************)

Arm2UnderlyingLevelProtectionSettingsUpdateRequest ==
    [ clientMessageId    : Sample(4),
      mpid               : Sample(4),
      action             : Sample(1),
      underlyingSymbol   : Sample(11),
      armThresholdCount  : Sample(4),
      arm2CountingPeriod : Sample(4) ]

EncodeArm2UnderlyingLevelProtectionSettingsUpdateRequest(message) ==
    message.clientMessageId
        \o message.mpid
        \o message.action
        \o message.underlyingSymbol
        \o message.armThresholdCount
        \o message.arm2CountingPeriod

DecodeArm2UnderlyingLevelProtectionSettingsUpdateRequest(bytes) ==
    LET clientMessageId == ReadBytes(bytes, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET mpid == ReadBytes(clientMessageId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET action == ReadBytes(mpid.rest, 1) IN IF ~action.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(action.rest, 11) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET armThresholdCount == ReadBytes(underlyingSymbol.rest, 4) IN IF ~armThresholdCount.ok THEN Fail ELSE
    LET arm2CountingPeriod == ReadBytes(armThresholdCount.rest, 4) IN IF ~arm2CountingPeriod.ok THEN Fail ELSE
    Ok([ clientMessageId    |-> clientMessageId.value,
         mpid               |-> mpid.value,
         action             |-> action.value,
         underlyingSymbol   |-> underlyingSymbol.value,
         armThresholdCount  |-> armThresholdCount.value,
         arm2CountingPeriod |-> arm2CountingPeriod.value ], arm2CountingPeriod.rest)

ZeroArm2UnderlyingLevelProtectionSettingsUpdateRequest ==
    [ clientMessageId    |-> [i \in 1 .. 4 |-> 0],
      mpid               |-> [i \in 1 .. 4 |-> 0],
      action             |-> [i \in 1 .. 1 |-> 0],
      underlyingSymbol   |-> [i \in 1 .. 11 |-> 0],
      armThresholdCount  |-> [i \in 1 .. 4 |-> 0],
      arm2CountingPeriod |-> [i \in 1 .. 4 |-> 0] ]

(* Arm 2 Underlying Level Protection Settings Update Request at zero, then each field in turn at the values it is checked at *)
CheckedArm2UnderlyingLevelProtectionSettingsUpdateRequest ==
    { ZeroArm2UnderlyingLevelProtectionSettingsUpdateRequest }
        \cup { [ZeroArm2UnderlyingLevelProtectionSettingsUpdateRequest EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroArm2UnderlyingLevelProtectionSettingsUpdateRequest EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroArm2UnderlyingLevelProtectionSettingsUpdateRequest EXCEPT !.action = one] : one \in Sample(1) }
        \cup { [ZeroArm2UnderlyingLevelProtectionSettingsUpdateRequest EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }
        \cup { [ZeroArm2UnderlyingLevelProtectionSettingsUpdateRequest EXCEPT !.armThresholdCount = one] : one \in Sample(4) }
        \cup { [ZeroArm2UnderlyingLevelProtectionSettingsUpdateRequest EXCEPT !.arm2CountingPeriod = one] : one \in Sample(4) }

(***************************************************************************)
(* Arm 2 Underlying Level Protection Settings Update Response: 20 bytes    *)
(***************************************************************************)

Arm2UnderlyingLevelProtectionSettingsUpdateResponse ==
    [ clientMessageId          : Sample(4),
      mpid                     : Sample(4),
      underlyingSymbol         : Sample(11),
      arm2SettingsUpdateStatus : Sample(1) ]

EncodeArm2UnderlyingLevelProtectionSettingsUpdateResponse(message) ==
    message.clientMessageId
        \o message.mpid
        \o message.underlyingSymbol
        \o message.arm2SettingsUpdateStatus

DecodeArm2UnderlyingLevelProtectionSettingsUpdateResponse(bytes) ==
    LET clientMessageId == ReadBytes(bytes, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET mpid == ReadBytes(clientMessageId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(mpid.rest, 11) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET arm2SettingsUpdateStatus == ReadBytes(underlyingSymbol.rest, 1) IN IF ~arm2SettingsUpdateStatus.ok THEN Fail ELSE
    Ok([ clientMessageId          |-> clientMessageId.value,
         mpid                     |-> mpid.value,
         underlyingSymbol         |-> underlyingSymbol.value,
         arm2SettingsUpdateStatus |-> arm2SettingsUpdateStatus.value ], arm2SettingsUpdateStatus.rest)

ZeroArm2UnderlyingLevelProtectionSettingsUpdateResponse ==
    [ clientMessageId          |-> [i \in 1 .. 4 |-> 0],
      mpid                     |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbol         |-> [i \in 1 .. 11 |-> 0],
      arm2SettingsUpdateStatus |-> [i \in 1 .. 1 |-> 0] ]

(* Arm 2 Underlying Level Protection Settings Update Response at zero, then each field in turn at the values it is checked at *)
CheckedArm2UnderlyingLevelProtectionSettingsUpdateResponse ==
    { ZeroArm2UnderlyingLevelProtectionSettingsUpdateResponse }
        \cup { [ZeroArm2UnderlyingLevelProtectionSettingsUpdateResponse EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroArm2UnderlyingLevelProtectionSettingsUpdateResponse EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroArm2UnderlyingLevelProtectionSettingsUpdateResponse EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }
        \cup { [ZeroArm2UnderlyingLevelProtectionSettingsUpdateResponse EXCEPT !.arm2SettingsUpdateStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Series Assignment Request: 13 bytes                                     *)
(***************************************************************************)

SeriesAssignmentRequest ==
    [ clientMessageId : Sample(4),
      mpid            : Sample(4),
      productId       : Sample(4),
      action          : Sample(1) ]

EncodeSeriesAssignmentRequest(message) ==
    message.clientMessageId
        \o message.mpid
        \o message.productId
        \o message.action

DecodeSeriesAssignmentRequest(bytes) ==
    LET clientMessageId == ReadBytes(bytes, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET mpid == ReadBytes(clientMessageId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET productId == ReadBytes(mpid.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET action == ReadBytes(productId.rest, 1) IN IF ~action.ok THEN Fail ELSE
    Ok([ clientMessageId |-> clientMessageId.value,
         mpid            |-> mpid.value,
         productId       |-> productId.value,
         action          |-> action.value ], action.rest)

ZeroSeriesAssignmentRequest ==
    [ clientMessageId |-> [i \in 1 .. 4 |-> 0],
      mpid            |-> [i \in 1 .. 4 |-> 0],
      productId       |-> [i \in 1 .. 4 |-> 0],
      action          |-> [i \in 1 .. 1 |-> 0] ]

(* Series Assignment Request at zero, then each field in turn at the values it is checked at *)
CheckedSeriesAssignmentRequest ==
    { ZeroSeriesAssignmentRequest }
        \cup { [ZeroSeriesAssignmentRequest EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroSeriesAssignmentRequest EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroSeriesAssignmentRequest EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroSeriesAssignmentRequest EXCEPT !.action = one] : one \in Sample(1) }

(***************************************************************************)
(* Series Assignment Response: 9 bytes                                     *)
(***************************************************************************)

SeriesAssignmentResponse ==
    [ clientMessageId          : Sample(4),
      mpid                     : Sample(4),
      assignmentSettingsStatus : Sample(1) ]

EncodeSeriesAssignmentResponse(message) ==
    message.clientMessageId
        \o message.mpid
        \o message.assignmentSettingsStatus

DecodeSeriesAssignmentResponse(bytes) ==
    LET clientMessageId == ReadBytes(bytes, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET mpid == ReadBytes(clientMessageId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET assignmentSettingsStatus == ReadBytes(mpid.rest, 1) IN IF ~assignmentSettingsStatus.ok THEN Fail ELSE
    Ok([ clientMessageId          |-> clientMessageId.value,
         mpid                     |-> mpid.value,
         assignmentSettingsStatus |-> assignmentSettingsStatus.value ], assignmentSettingsStatus.rest)

ZeroSeriesAssignmentResponse ==
    [ clientMessageId          |-> [i \in 1 .. 4 |-> 0],
      mpid                     |-> [i \in 1 .. 4 |-> 0],
      assignmentSettingsStatus |-> [i \in 1 .. 1 |-> 0] ]

(* Series Assignment Response at zero, then each field in turn at the values it is checked at *)
CheckedSeriesAssignmentResponse ==
    { ZeroSeriesAssignmentResponse }
        \cup { [ZeroSeriesAssignmentResponse EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroSeriesAssignmentResponse EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroSeriesAssignmentResponse EXCEPT !.assignmentSettingsStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Self Trade Protection Designation Request: 9 bytes                      *)
(***************************************************************************)

SelfTradeProtectionDesignationRequest ==
    [ clientMessageId : Sample(4),
      mpid            : Sample(4),
      action          : Sample(1) ]

EncodeSelfTradeProtectionDesignationRequest(message) ==
    message.clientMessageId
        \o message.mpid
        \o message.action

DecodeSelfTradeProtectionDesignationRequest(bytes) ==
    LET clientMessageId == ReadBytes(bytes, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET mpid == ReadBytes(clientMessageId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET action == ReadBytes(mpid.rest, 1) IN IF ~action.ok THEN Fail ELSE
    Ok([ clientMessageId |-> clientMessageId.value,
         mpid            |-> mpid.value,
         action          |-> action.value ], action.rest)

ZeroSelfTradeProtectionDesignationRequest ==
    [ clientMessageId |-> [i \in 1 .. 4 |-> 0],
      mpid            |-> [i \in 1 .. 4 |-> 0],
      action          |-> [i \in 1 .. 1 |-> 0] ]

(* Self Trade Protection Designation Request at zero, then each field in turn at the values it is checked at *)
CheckedSelfTradeProtectionDesignationRequest ==
    { ZeroSelfTradeProtectionDesignationRequest }
        \cup { [ZeroSelfTradeProtectionDesignationRequest EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroSelfTradeProtectionDesignationRequest EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroSelfTradeProtectionDesignationRequest EXCEPT !.action = one] : one \in Sample(1) }

(***************************************************************************)
(* Self Trade Protection Designation Response: 9 bytes                     *)
(***************************************************************************)

SelfTradeProtectionDesignationResponse ==
    [ clientMessageId           : Sample(4),
      mpid                      : Sample(4),
      selfTradeProtectionStatus : Sample(1) ]

EncodeSelfTradeProtectionDesignationResponse(message) ==
    message.clientMessageId
        \o message.mpid
        \o message.selfTradeProtectionStatus

DecodeSelfTradeProtectionDesignationResponse(bytes) ==
    LET clientMessageId == ReadBytes(bytes, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET mpid == ReadBytes(clientMessageId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET selfTradeProtectionStatus == ReadBytes(mpid.rest, 1) IN IF ~selfTradeProtectionStatus.ok THEN Fail ELSE
    Ok([ clientMessageId           |-> clientMessageId.value,
         mpid                      |-> mpid.value,
         selfTradeProtectionStatus |-> selfTradeProtectionStatus.value ], selfTradeProtectionStatus.rest)

ZeroSelfTradeProtectionDesignationResponse ==
    [ clientMessageId           |-> [i \in 1 .. 4 |-> 0],
      mpid                      |-> [i \in 1 .. 4 |-> 0],
      selfTradeProtectionStatus |-> [i \in 1 .. 1 |-> 0] ]

(* Self Trade Protection Designation Response at zero, then each field in turn at the values it is checked at *)
CheckedSelfTradeProtectionDesignationResponse ==
    { ZeroSelfTradeProtectionDesignationResponse }
        \cup { [ZeroSelfTradeProtectionDesignationResponse EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroSelfTradeProtectionDesignationResponse EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroSelfTradeProtectionDesignationResponse EXCEPT !.selfTradeProtectionStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Liquidity Units: 57 bytes                                               *)
(***************************************************************************)

LiquidityUnits ==
    [ liquidityUnit : Sample(57) ]

EncodeLiquidityUnits(message) ==
    message.liquidityUnit

DecodeLiquidityUnits(bytes) ==
    LET liquidityUnit == ReadBytes(bytes, 57) IN IF ~liquidityUnit.ok THEN Fail ELSE
    Ok([ liquidityUnit |-> liquidityUnit.value ], liquidityUnit.rest)

ZeroLiquidityUnits ==
    [ liquidityUnit |-> [i \in 1 .. 57 |-> 0] ]

(* Liquidity Units at zero, then each field in turn at the values it is checked at *)
CheckedLiquidityUnits ==
    { ZeroLiquidityUnits }
        \cup { [ZeroLiquidityUnits EXCEPT !.liquidityUnit = one] : one \in Sample(57) }

(* A run of Liquidity Units, written one after another *)
RECURSIVE EncodeLiquidityUnitsList(_)
EncodeLiquidityUnitsList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLiquidityUnits(Head(messages)) \o EncodeLiquidityUnitsList(Tail(messages))

(* As many Liquidity Units as the field that counts them says *)
RECURSIVE ReadLiquidityUnitsList(_, _)
ReadLiquidityUnitsList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLiquidityUnits(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLiquidityUnitsList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Liquidity Units of each kind, for the lists that carry them *)
OneLiquidityUnits == { ZeroLiquidityUnits }

(***************************************************************************)
(* Bulk Liquidity Message                                                  *)
(***************************************************************************)

BulkLiquidityMessage ==
    [ clientMessageId : Sample(4),
      clientSendTime  : Sample(8),
      reserved4       : Sample(4),
      liquidityUnits  : SampleLists(OneLiquidityUnits) ]

EncodeBulkLiquidityMessage(message) ==
    message.clientMessageId
        \o message.clientSendTime
        \o EncodeUIntBE(Len(message.liquidityUnits), 1)
        \o message.reserved4
        \o EncodeLiquidityUnitsList(message.liquidityUnits)

DecodeBulkLiquidityMessage(bytes) ==
    LET clientMessageId == ReadBytes(bytes, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET clientSendTime == ReadBytes(clientMessageId.rest, 8) IN IF ~clientSendTime.ok THEN Fail ELSE
    LET liquidityUnitCount == ReadUIntBE(clientSendTime.rest, 1) IN IF ~liquidityUnitCount.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(liquidityUnitCount.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET liquidityUnits == ReadLiquidityUnitsList(reserved4.rest, liquidityUnitCount.value) IN IF ~liquidityUnits.ok THEN Fail ELSE
    Ok([ clientMessageId |-> clientMessageId.value,
         clientSendTime  |-> clientSendTime.value,
         reserved4       |-> reserved4.value,
         liquidityUnits  |-> liquidityUnits.value ], liquidityUnits.rest)

ZeroBulkLiquidityMessage ==
    [ clientMessageId |-> [i \in 1 .. 4 |-> 0],
      clientSendTime  |-> [i \in 1 .. 8 |-> 0],
      reserved4       |-> [i \in 1 .. 4 |-> 0],
      liquidityUnits  |-> << >> ]

(* Bulk Liquidity Message at zero, then each field in turn at the values it is checked at *)
CheckedBulkLiquidityMessage ==
    { ZeroBulkLiquidityMessage }
        \cup { [ZeroBulkLiquidityMessage EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroBulkLiquidityMessage EXCEPT !.clientSendTime = one] : one \in Sample(8) }
        \cup { [ZeroBulkLiquidityMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroBulkLiquidityMessage EXCEPT !.liquidityUnits = one] : one \in SampleLists(OneLiquidityUnits) }

(***************************************************************************)
(* Order Response: 13 bytes                                                *)
(***************************************************************************)

OrderResponse ==
    [ orderStatus          : Sample(1),
      engineSequenceNumber : Sample(8),
      openSize             : Sample(4) ]

EncodeOrderResponse(message) ==
    message.orderStatus
        \o message.engineSequenceNumber
        \o message.openSize

DecodeOrderResponse(bytes) ==
    LET orderStatus == ReadBytes(bytes, 1) IN IF ~orderStatus.ok THEN Fail ELSE
    LET engineSequenceNumber == ReadBytes(orderStatus.rest, 8) IN IF ~engineSequenceNumber.ok THEN Fail ELSE
    LET openSize == ReadBytes(engineSequenceNumber.rest, 4) IN IF ~openSize.ok THEN Fail ELSE
    Ok([ orderStatus          |-> orderStatus.value,
         engineSequenceNumber |-> engineSequenceNumber.value,
         openSize             |-> openSize.value ], openSize.rest)

ZeroOrderResponse ==
    [ orderStatus          |-> [i \in 1 .. 1 |-> 0],
      engineSequenceNumber |-> [i \in 1 .. 8 |-> 0],
      openSize             |-> [i \in 1 .. 4 |-> 0] ]

(* Order Response at zero, then each field in turn at the values it is checked at *)
CheckedOrderResponse ==
    { ZeroOrderResponse }
        \cup { [ZeroOrderResponse EXCEPT !.orderStatus = one] : one \in Sample(1) }
        \cup { [ZeroOrderResponse EXCEPT !.engineSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderResponse EXCEPT !.openSize = one] : one \in Sample(4) }

(* A run of Order Response, written one after another *)
RECURSIVE EncodeOrderResponseList(_)
EncodeOrderResponseList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOrderResponse(Head(messages)) \o EncodeOrderResponseList(Tail(messages))

(* As many Order Response as the field that counts them says *)
RECURSIVE ReadOrderResponseList(_, _)
ReadOrderResponseList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOrderResponse(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOrderResponseList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Order Response of each kind, for the lists that carry them *)
OneOrderResponse == { ZeroOrderResponse }

(***************************************************************************)
(* Bulk Liquidity Message Response                                         *)
(***************************************************************************)

BulkLiquidityMessageResponse ==
    [ clientMessageId : Sample(4),
      bulkOrderStatus : Sample(1),
      orderCount      : Sample(1),
      orderAckTime    : Sample(8),
      orderResponse   : SampleLists(OneOrderResponse) ]

EncodeBulkLiquidityMessageResponse(message) ==
    message.clientMessageId
        \o message.bulkOrderStatus
        \o message.orderCount
        \o EncodeUIntBE(Len(message.orderResponse), 1)
        \o message.orderAckTime
        \o EncodeOrderResponseList(message.orderResponse)

DecodeBulkLiquidityMessageResponse(bytes) ==
    LET clientMessageId == ReadBytes(bytes, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET bulkOrderStatus == ReadBytes(clientMessageId.rest, 1) IN IF ~bulkOrderStatus.ok THEN Fail ELSE
    LET orderCount == ReadBytes(bulkOrderStatus.rest, 1) IN IF ~orderCount.ok THEN Fail ELSE
    LET invalidOrderCount == ReadUIntBE(orderCount.rest, 1) IN IF ~invalidOrderCount.ok THEN Fail ELSE
    LET orderAckTime == ReadBytes(invalidOrderCount.rest, 8) IN IF ~orderAckTime.ok THEN Fail ELSE
    LET orderResponse == ReadOrderResponseList(orderAckTime.rest, invalidOrderCount.value) IN IF ~orderResponse.ok THEN Fail ELSE
    Ok([ clientMessageId |-> clientMessageId.value,
         bulkOrderStatus |-> bulkOrderStatus.value,
         orderCount      |-> orderCount.value,
         orderAckTime    |-> orderAckTime.value,
         orderResponse   |-> orderResponse.value ], orderResponse.rest)

ZeroBulkLiquidityMessageResponse ==
    [ clientMessageId |-> [i \in 1 .. 4 |-> 0],
      bulkOrderStatus |-> [i \in 1 .. 1 |-> 0],
      orderCount      |-> [i \in 1 .. 1 |-> 0],
      orderAckTime    |-> [i \in 1 .. 8 |-> 0],
      orderResponse   |-> << >> ]

(* Bulk Liquidity Message Response at zero, then each field in turn at the values it is checked at *)
CheckedBulkLiquidityMessageResponse ==
    { ZeroBulkLiquidityMessageResponse }
        \cup { [ZeroBulkLiquidityMessageResponse EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroBulkLiquidityMessageResponse EXCEPT !.bulkOrderStatus = one] : one \in Sample(1) }
        \cup { [ZeroBulkLiquidityMessageResponse EXCEPT !.orderCount = one] : one \in Sample(1) }
        \cup { [ZeroBulkLiquidityMessageResponse EXCEPT !.orderAckTime = one] : one \in Sample(8) }
        \cup { [ZeroBulkLiquidityMessageResponse EXCEPT !.orderResponse = one] : one \in SampleLists(OneOrderResponse) }

(***************************************************************************)
(* Liquidity Mass Cancel Request: 35 bytes                                 *)
(***************************************************************************)

LiquidityMassCancelRequest ==
    [ clientMessageId  : Sample(4),
      mpid             : Sample(4),
      clientSendTime   : Sample(8),
      underlyingSymbol : Sample(11),
      massCancelScope  : Sample(1),
      reserved7        : Sample(7) ]

EncodeLiquidityMassCancelRequest(message) ==
    message.clientMessageId
        \o message.mpid
        \o message.clientSendTime
        \o message.underlyingSymbol
        \o message.massCancelScope
        \o message.reserved7

DecodeLiquidityMassCancelRequest(bytes) ==
    LET clientMessageId == ReadBytes(bytes, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET mpid == ReadBytes(clientMessageId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET clientSendTime == ReadBytes(mpid.rest, 8) IN IF ~clientSendTime.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(clientSendTime.rest, 11) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET massCancelScope == ReadBytes(underlyingSymbol.rest, 1) IN IF ~massCancelScope.ok THEN Fail ELSE
    LET reserved7 == ReadBytes(massCancelScope.rest, 7) IN IF ~reserved7.ok THEN Fail ELSE
    Ok([ clientMessageId  |-> clientMessageId.value,
         mpid             |-> mpid.value,
         clientSendTime   |-> clientSendTime.value,
         underlyingSymbol |-> underlyingSymbol.value,
         massCancelScope  |-> massCancelScope.value,
         reserved7        |-> reserved7.value ], reserved7.rest)

ZeroLiquidityMassCancelRequest ==
    [ clientMessageId  |-> [i \in 1 .. 4 |-> 0],
      mpid             |-> [i \in 1 .. 4 |-> 0],
      clientSendTime   |-> [i \in 1 .. 8 |-> 0],
      underlyingSymbol |-> [i \in 1 .. 11 |-> 0],
      massCancelScope  |-> [i \in 1 .. 1 |-> 0],
      reserved7        |-> [i \in 1 .. 7 |-> 0] ]

(* Liquidity Mass Cancel Request at zero, then each field in turn at the values it is checked at *)
CheckedLiquidityMassCancelRequest ==
    { ZeroLiquidityMassCancelRequest }
        \cup { [ZeroLiquidityMassCancelRequest EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroLiquidityMassCancelRequest EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroLiquidityMassCancelRequest EXCEPT !.clientSendTime = one] : one \in Sample(8) }
        \cup { [ZeroLiquidityMassCancelRequest EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }
        \cup { [ZeroLiquidityMassCancelRequest EXCEPT !.massCancelScope = one] : one \in Sample(1) }
        \cup { [ZeroLiquidityMassCancelRequest EXCEPT !.reserved7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Liquidity Mass Cancel Response: 9 bytes                                 *)
(***************************************************************************)

LiquidityMassCancelResponse ==
    [ clientMessageId : Sample(4),
      mpid            : Sample(4),
      status          : Sample(1) ]

EncodeLiquidityMassCancelResponse(message) ==
    message.clientMessageId
        \o message.mpid
        \o message.status

DecodeLiquidityMassCancelResponse(bytes) ==
    LET clientMessageId == ReadBytes(bytes, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET mpid == ReadBytes(clientMessageId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET status == ReadBytes(mpid.rest, 1) IN IF ~status.ok THEN Fail ELSE
    Ok([ clientMessageId |-> clientMessageId.value,
         mpid            |-> mpid.value,
         status          |-> status.value ], status.rest)

ZeroLiquidityMassCancelResponse ==
    [ clientMessageId |-> [i \in 1 .. 4 |-> 0],
      mpid            |-> [i \in 1 .. 4 |-> 0],
      status          |-> [i \in 1 .. 1 |-> 0] ]

(* Liquidity Mass Cancel Response at zero, then each field in turn at the values it is checked at *)
CheckedLiquidityMassCancelResponse ==
    { ZeroLiquidityMassCancelResponse }
        \cup { [ZeroLiquidityMassCancelResponse EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroLiquidityMassCancelResponse EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroLiquidityMassCancelResponse EXCEPT !.status = one] : one \in Sample(1) }

(***************************************************************************)
(* Liquidity Protection Reset Request: 19 bytes                            *)
(***************************************************************************)

LiquidityProtectionResetRequest ==
    [ clientMessageId  : Sample(4),
      mpid             : Sample(4),
      underlyingSymbol : Sample(11) ]

EncodeLiquidityProtectionResetRequest(message) ==
    message.clientMessageId
        \o message.mpid
        \o message.underlyingSymbol

DecodeLiquidityProtectionResetRequest(bytes) ==
    LET clientMessageId == ReadBytes(bytes, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET mpid == ReadBytes(clientMessageId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(mpid.rest, 11) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    Ok([ clientMessageId  |-> clientMessageId.value,
         mpid             |-> mpid.value,
         underlyingSymbol |-> underlyingSymbol.value ], underlyingSymbol.rest)

ZeroLiquidityProtectionResetRequest ==
    [ clientMessageId  |-> [i \in 1 .. 4 |-> 0],
      mpid             |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbol |-> [i \in 1 .. 11 |-> 0] ]

(* Liquidity Protection Reset Request at zero, then each field in turn at the values it is checked at *)
CheckedLiquidityProtectionResetRequest ==
    { ZeroLiquidityProtectionResetRequest }
        \cup { [ZeroLiquidityProtectionResetRequest EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroLiquidityProtectionResetRequest EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroLiquidityProtectionResetRequest EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }

(***************************************************************************)
(* Liquidity Protection Reset Response: 9 bytes                            *)
(***************************************************************************)

LiquidityProtectionResetResponse ==
    [ clientMessageId : Sample(4),
      mpid            : Sample(4),
      status          : Sample(1) ]

EncodeLiquidityProtectionResetResponse(message) ==
    message.clientMessageId
        \o message.mpid
        \o message.status

DecodeLiquidityProtectionResetResponse(bytes) ==
    LET clientMessageId == ReadBytes(bytes, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET mpid == ReadBytes(clientMessageId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET status == ReadBytes(mpid.rest, 1) IN IF ~status.ok THEN Fail ELSE
    Ok([ clientMessageId |-> clientMessageId.value,
         mpid            |-> mpid.value,
         status          |-> status.value ], status.rest)

ZeroLiquidityProtectionResetResponse ==
    [ clientMessageId |-> [i \in 1 .. 4 |-> 0],
      mpid            |-> [i \in 1 .. 4 |-> 0],
      status          |-> [i \in 1 .. 1 |-> 0] ]

(* Liquidity Protection Reset Response at zero, then each field in turn at the values it is checked at *)
CheckedLiquidityProtectionResetResponse ==
    { ZeroLiquidityProtectionResetResponse }
        \cup { [ZeroLiquidityProtectionResetResponse EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroLiquidityProtectionResetResponse EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroLiquidityProtectionResetResponse EXCEPT !.status = one] : one \in Sample(1) }

(***************************************************************************)
(* Single Side Liquidity Protection Reset Request: 17 bytes                *)
(***************************************************************************)

SingleSideLiquidityProtectionResetRequest ==
    [ clientMessageId : Sample(4),
      mpid            : Sample(4),
      productId       : Sample(4),
      side            : Sample(1),
      reserved4       : Sample(4) ]

EncodeSingleSideLiquidityProtectionResetRequest(message) ==
    message.clientMessageId
        \o message.mpid
        \o message.productId
        \o message.side
        \o message.reserved4

DecodeSingleSideLiquidityProtectionResetRequest(bytes) ==
    LET clientMessageId == ReadBytes(bytes, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET mpid == ReadBytes(clientMessageId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET productId == ReadBytes(mpid.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET side == ReadBytes(productId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(side.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    Ok([ clientMessageId |-> clientMessageId.value,
         mpid            |-> mpid.value,
         productId       |-> productId.value,
         side            |-> side.value,
         reserved4       |-> reserved4.value ], reserved4.rest)

ZeroSingleSideLiquidityProtectionResetRequest ==
    [ clientMessageId |-> [i \in 1 .. 4 |-> 0],
      mpid            |-> [i \in 1 .. 4 |-> 0],
      productId       |-> [i \in 1 .. 4 |-> 0],
      side            |-> [i \in 1 .. 1 |-> 0],
      reserved4       |-> [i \in 1 .. 4 |-> 0] ]

(* Single Side Liquidity Protection Reset Request at zero, then each field in turn at the values it is checked at *)
CheckedSingleSideLiquidityProtectionResetRequest ==
    { ZeroSingleSideLiquidityProtectionResetRequest }
        \cup { [ZeroSingleSideLiquidityProtectionResetRequest EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideLiquidityProtectionResetRequest EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideLiquidityProtectionResetRequest EXCEPT !.productId = one] : one \in Sample(4) }
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
(* Liquidity Protection Trigger Notification: 24 bytes                     *)
(***************************************************************************)

LiquidityProtectionTriggerNotification ==
    [ notificationTime : Sample(8),
      mpid             : Sample(4),
      underlyingSymbol : Sample(11),
      triggerReason    : Sample(1) ]

EncodeLiquidityProtectionTriggerNotification(message) ==
    message.notificationTime
        \o message.mpid
        \o message.underlyingSymbol
        \o message.triggerReason

DecodeLiquidityProtectionTriggerNotification(bytes) ==
    LET notificationTime == ReadBytes(bytes, 8) IN IF ~notificationTime.ok THEN Fail ELSE
    LET mpid == ReadBytes(notificationTime.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(mpid.rest, 11) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET triggerReason == ReadBytes(underlyingSymbol.rest, 1) IN IF ~triggerReason.ok THEN Fail ELSE
    Ok([ notificationTime |-> notificationTime.value,
         mpid             |-> mpid.value,
         underlyingSymbol |-> underlyingSymbol.value,
         triggerReason    |-> triggerReason.value ], triggerReason.rest)

ZeroLiquidityProtectionTriggerNotification ==
    [ notificationTime |-> [i \in 1 .. 8 |-> 0],
      mpid             |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbol |-> [i \in 1 .. 11 |-> 0],
      triggerReason    |-> [i \in 1 .. 1 |-> 0] ]

(* Liquidity Protection Trigger Notification at zero, then each field in turn at the values it is checked at *)
CheckedLiquidityProtectionTriggerNotification ==
    { ZeroLiquidityProtectionTriggerNotification }
        \cup { [ZeroLiquidityProtectionTriggerNotification EXCEPT !.notificationTime = one] : one \in Sample(8) }
        \cup { [ZeroLiquidityProtectionTriggerNotification EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroLiquidityProtectionTriggerNotification EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }
        \cup { [ZeroLiquidityProtectionTriggerNotification EXCEPT !.triggerReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Notification: 63 bytes                                            *)
(***************************************************************************)

OrderNotification ==
    [ notificationTime    : Sample(8),
      clientOrderId       : Sample(4),
      clientMessageId     : Sample(4),
      bulkOrderIndex      : Sample(1),
      targetClientOrderId : Sample(4),
      mpid                : Sample(4),
      productId           : Sample(4),
      timeInForceTif      : Sample(1),
      orderInstruction    : Sample(1),
      origin              : Sample(1),
      mvp                 : Sample(1),
      price               : Sample(4),
      size                : Sample(4),
      side                : Sample(1),
      openClose           : Sample(1),
      coveredUncovered    : Sample(1),
      clearingAccount     : Sample(5),
      cmta                : Sample(4),
      account             : Sample(10) ]

EncodeOrderNotification(message) ==
    message.notificationTime
        \o message.clientOrderId
        \o message.clientMessageId
        \o message.bulkOrderIndex
        \o message.targetClientOrderId
        \o message.mpid
        \o message.productId
        \o message.timeInForceTif
        \o message.orderInstruction
        \o message.origin
        \o message.mvp
        \o message.price
        \o message.size
        \o message.side
        \o message.openClose
        \o message.coveredUncovered
        \o message.clearingAccount
        \o message.cmta
        \o message.account

DecodeOrderNotification(bytes) ==
    LET notificationTime == ReadBytes(bytes, 8) IN IF ~notificationTime.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(notificationTime.rest, 4) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET clientMessageId == ReadBytes(clientOrderId.rest, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET bulkOrderIndex == ReadBytes(clientMessageId.rest, 1) IN IF ~bulkOrderIndex.ok THEN Fail ELSE
    LET targetClientOrderId == ReadBytes(bulkOrderIndex.rest, 4) IN IF ~targetClientOrderId.ok THEN Fail ELSE
    LET mpid == ReadBytes(targetClientOrderId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET productId == ReadBytes(mpid.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET timeInForceTif == ReadBytes(productId.rest, 1) IN IF ~timeInForceTif.ok THEN Fail ELSE
    LET orderInstruction == ReadBytes(timeInForceTif.rest, 1) IN IF ~orderInstruction.ok THEN Fail ELSE
    LET origin == ReadBytes(orderInstruction.rest, 1) IN IF ~origin.ok THEN Fail ELSE
    LET mvp == ReadBytes(origin.rest, 1) IN IF ~mvp.ok THEN Fail ELSE
    LET price == ReadBytes(mvp.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET size == ReadBytes(price.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET side == ReadBytes(size.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET openClose == ReadBytes(side.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET coveredUncovered == ReadBytes(openClose.rest, 1) IN IF ~coveredUncovered.ok THEN Fail ELSE
    LET clearingAccount == ReadBytes(coveredUncovered.rest, 5) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET cmta == ReadBytes(clearingAccount.rest, 4) IN IF ~cmta.ok THEN Fail ELSE
    LET account == ReadBytes(cmta.rest, 10) IN IF ~account.ok THEN Fail ELSE
    Ok([ notificationTime    |-> notificationTime.value,
         clientOrderId       |-> clientOrderId.value,
         clientMessageId     |-> clientMessageId.value,
         bulkOrderIndex      |-> bulkOrderIndex.value,
         targetClientOrderId |-> targetClientOrderId.value,
         mpid                |-> mpid.value,
         productId           |-> productId.value,
         timeInForceTif      |-> timeInForceTif.value,
         orderInstruction    |-> orderInstruction.value,
         origin              |-> origin.value,
         mvp                 |-> mvp.value,
         price               |-> price.value,
         size                |-> size.value,
         side                |-> side.value,
         openClose           |-> openClose.value,
         coveredUncovered    |-> coveredUncovered.value,
         clearingAccount     |-> clearingAccount.value,
         cmta                |-> cmta.value,
         account             |-> account.value ], account.rest)

ZeroOrderNotification ==
    [ notificationTime    |-> [i \in 1 .. 8 |-> 0],
      clientOrderId       |-> [i \in 1 .. 4 |-> 0],
      clientMessageId     |-> [i \in 1 .. 4 |-> 0],
      bulkOrderIndex      |-> [i \in 1 .. 1 |-> 0],
      targetClientOrderId |-> [i \in 1 .. 4 |-> 0],
      mpid                |-> [i \in 1 .. 4 |-> 0],
      productId           |-> [i \in 1 .. 4 |-> 0],
      timeInForceTif      |-> [i \in 1 .. 1 |-> 0],
      orderInstruction    |-> [i \in 1 .. 1 |-> 0],
      origin              |-> [i \in 1 .. 1 |-> 0],
      mvp                 |-> [i \in 1 .. 1 |-> 0],
      price               |-> [i \in 1 .. 4 |-> 0],
      size                |-> [i \in 1 .. 4 |-> 0],
      side                |-> [i \in 1 .. 1 |-> 0],
      openClose           |-> [i \in 1 .. 1 |-> 0],
      coveredUncovered    |-> [i \in 1 .. 1 |-> 0],
      clearingAccount     |-> [i \in 1 .. 5 |-> 0],
      cmta                |-> [i \in 1 .. 4 |-> 0],
      account             |-> [i \in 1 .. 10 |-> 0] ]

(* Order Notification at zero, then each field in turn at the values it is checked at *)
CheckedOrderNotification ==
    { ZeroOrderNotification }
        \cup { [ZeroOrderNotification EXCEPT !.notificationTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderNotification EXCEPT !.clientOrderId = one] : one \in Sample(4) }
        \cup { [ZeroOrderNotification EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroOrderNotification EXCEPT !.bulkOrderIndex = one] : one \in Sample(1) }
        \cup { [ZeroOrderNotification EXCEPT !.targetClientOrderId = one] : one \in Sample(4) }
        \cup { [ZeroOrderNotification EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroOrderNotification EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroOrderNotification EXCEPT !.timeInForceTif = one] : one \in Sample(1) }
        \cup { [ZeroOrderNotification EXCEPT !.orderInstruction = one] : one \in Sample(1) }
        \cup { [ZeroOrderNotification EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroOrderNotification EXCEPT !.mvp = one] : one \in Sample(1) }
        \cup { [ZeroOrderNotification EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderNotification EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroOrderNotification EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderNotification EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroOrderNotification EXCEPT !.coveredUncovered = one] : one \in Sample(1) }
        \cup { [ZeroOrderNotification EXCEPT !.clearingAccount = one] : one \in Sample(5) }
        \cup { [ZeroOrderNotification EXCEPT !.cmta = one] : one \in Sample(4) }
        \cup { [ZeroOrderNotification EXCEPT !.account = one] : one \in Sample(10) }

(***************************************************************************)
(* Done For The Day Notification: 63 bytes                                 *)
(***************************************************************************)

DoneForTheDayNotification ==
    [ notificationTime    : Sample(8),
      clientOrderId       : Sample(4),
      clientMessageId     : Sample(4),
      bulkOrderIndex      : Sample(1),
      targetClientOrderId : Sample(4),
      mpid                : Sample(4),
      productId           : Sample(4),
      timeInForceTif      : Sample(1),
      orderInstruction    : Sample(1),
      origin              : Sample(1),
      mvp                 : Sample(1),
      price               : Sample(4),
      size                : Sample(4),
      side                : Sample(1),
      openClose           : Sample(1),
      coveredUncovered    : Sample(1),
      clearingAccount     : Sample(5),
      cmta                : Sample(4),
      account             : Sample(10) ]

EncodeDoneForTheDayNotification(message) ==
    message.notificationTime
        \o message.clientOrderId
        \o message.clientMessageId
        \o message.bulkOrderIndex
        \o message.targetClientOrderId
        \o message.mpid
        \o message.productId
        \o message.timeInForceTif
        \o message.orderInstruction
        \o message.origin
        \o message.mvp
        \o message.price
        \o message.size
        \o message.side
        \o message.openClose
        \o message.coveredUncovered
        \o message.clearingAccount
        \o message.cmta
        \o message.account

DecodeDoneForTheDayNotification(bytes) ==
    LET notificationTime == ReadBytes(bytes, 8) IN IF ~notificationTime.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(notificationTime.rest, 4) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET clientMessageId == ReadBytes(clientOrderId.rest, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET bulkOrderIndex == ReadBytes(clientMessageId.rest, 1) IN IF ~bulkOrderIndex.ok THEN Fail ELSE
    LET targetClientOrderId == ReadBytes(bulkOrderIndex.rest, 4) IN IF ~targetClientOrderId.ok THEN Fail ELSE
    LET mpid == ReadBytes(targetClientOrderId.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET productId == ReadBytes(mpid.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET timeInForceTif == ReadBytes(productId.rest, 1) IN IF ~timeInForceTif.ok THEN Fail ELSE
    LET orderInstruction == ReadBytes(timeInForceTif.rest, 1) IN IF ~orderInstruction.ok THEN Fail ELSE
    LET origin == ReadBytes(orderInstruction.rest, 1) IN IF ~origin.ok THEN Fail ELSE
    LET mvp == ReadBytes(origin.rest, 1) IN IF ~mvp.ok THEN Fail ELSE
    LET price == ReadBytes(mvp.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET size == ReadBytes(price.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET side == ReadBytes(size.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET openClose == ReadBytes(side.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET coveredUncovered == ReadBytes(openClose.rest, 1) IN IF ~coveredUncovered.ok THEN Fail ELSE
    LET clearingAccount == ReadBytes(coveredUncovered.rest, 5) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET cmta == ReadBytes(clearingAccount.rest, 4) IN IF ~cmta.ok THEN Fail ELSE
    LET account == ReadBytes(cmta.rest, 10) IN IF ~account.ok THEN Fail ELSE
    Ok([ notificationTime    |-> notificationTime.value,
         clientOrderId       |-> clientOrderId.value,
         clientMessageId     |-> clientMessageId.value,
         bulkOrderIndex      |-> bulkOrderIndex.value,
         targetClientOrderId |-> targetClientOrderId.value,
         mpid                |-> mpid.value,
         productId           |-> productId.value,
         timeInForceTif      |-> timeInForceTif.value,
         orderInstruction    |-> orderInstruction.value,
         origin              |-> origin.value,
         mvp                 |-> mvp.value,
         price               |-> price.value,
         size                |-> size.value,
         side                |-> side.value,
         openClose           |-> openClose.value,
         coveredUncovered    |-> coveredUncovered.value,
         clearingAccount     |-> clearingAccount.value,
         cmta                |-> cmta.value,
         account             |-> account.value ], account.rest)

ZeroDoneForTheDayNotification ==
    [ notificationTime    |-> [i \in 1 .. 8 |-> 0],
      clientOrderId       |-> [i \in 1 .. 4 |-> 0],
      clientMessageId     |-> [i \in 1 .. 4 |-> 0],
      bulkOrderIndex      |-> [i \in 1 .. 1 |-> 0],
      targetClientOrderId |-> [i \in 1 .. 4 |-> 0],
      mpid                |-> [i \in 1 .. 4 |-> 0],
      productId           |-> [i \in 1 .. 4 |-> 0],
      timeInForceTif      |-> [i \in 1 .. 1 |-> 0],
      orderInstruction    |-> [i \in 1 .. 1 |-> 0],
      origin              |-> [i \in 1 .. 1 |-> 0],
      mvp                 |-> [i \in 1 .. 1 |-> 0],
      price               |-> [i \in 1 .. 4 |-> 0],
      size                |-> [i \in 1 .. 4 |-> 0],
      side                |-> [i \in 1 .. 1 |-> 0],
      openClose           |-> [i \in 1 .. 1 |-> 0],
      coveredUncovered    |-> [i \in 1 .. 1 |-> 0],
      clearingAccount     |-> [i \in 1 .. 5 |-> 0],
      cmta                |-> [i \in 1 .. 4 |-> 0],
      account             |-> [i \in 1 .. 10 |-> 0] ]

(* Done For The Day Notification at zero, then each field in turn at the values it is checked at *)
CheckedDoneForTheDayNotification ==
    { ZeroDoneForTheDayNotification }
        \cup { [ZeroDoneForTheDayNotification EXCEPT !.notificationTime = one] : one \in Sample(8) }
        \cup { [ZeroDoneForTheDayNotification EXCEPT !.clientOrderId = one] : one \in Sample(4) }
        \cup { [ZeroDoneForTheDayNotification EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroDoneForTheDayNotification EXCEPT !.bulkOrderIndex = one] : one \in Sample(1) }
        \cup { [ZeroDoneForTheDayNotification EXCEPT !.targetClientOrderId = one] : one \in Sample(4) }
        \cup { [ZeroDoneForTheDayNotification EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroDoneForTheDayNotification EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroDoneForTheDayNotification EXCEPT !.timeInForceTif = one] : one \in Sample(1) }
        \cup { [ZeroDoneForTheDayNotification EXCEPT !.orderInstruction = one] : one \in Sample(1) }
        \cup { [ZeroDoneForTheDayNotification EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroDoneForTheDayNotification EXCEPT !.mvp = one] : one \in Sample(1) }
        \cup { [ZeroDoneForTheDayNotification EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroDoneForTheDayNotification EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroDoneForTheDayNotification EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroDoneForTheDayNotification EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroDoneForTheDayNotification EXCEPT !.coveredUncovered = one] : one \in Sample(1) }
        \cup { [ZeroDoneForTheDayNotification EXCEPT !.clearingAccount = one] : one \in Sample(5) }
        \cup { [ZeroDoneForTheDayNotification EXCEPT !.cmta = one] : one \in Sample(4) }
        \cup { [ZeroDoneForTheDayNotification EXCEPT !.account = one] : one \in Sample(10) }

(***************************************************************************)
(* Cancel Notification: 40 bytes                                           *)
(***************************************************************************)

CancelNotification2 ==
    [ notificationTime     : Sample(8),
      mpid                 : Sample(4),
      productId            : Sample(4),
      liquidityType        : Sample(1),
      clientMessageId      : Sample(4),
      clientOrderId        : Sample(4),
      bulkOrderIndex       : Sample(1),
      side                 : Sample(1),
      size                 : Sample(4),
      engineSequenceNumber : Sample(8),
      cancelReason         : Sample(1) ]

EncodeCancelNotification2(message) ==
    message.notificationTime
        \o message.mpid
        \o message.productId
        \o message.liquidityType
        \o message.clientMessageId
        \o message.clientOrderId
        \o message.bulkOrderIndex
        \o message.side
        \o message.size
        \o message.engineSequenceNumber
        \o message.cancelReason

DecodeCancelNotification2(bytes) ==
    LET notificationTime == ReadBytes(bytes, 8) IN IF ~notificationTime.ok THEN Fail ELSE
    LET mpid == ReadBytes(notificationTime.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET productId == ReadBytes(mpid.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET liquidityType == ReadBytes(productId.rest, 1) IN IF ~liquidityType.ok THEN Fail ELSE
    LET clientMessageId == ReadBytes(liquidityType.rest, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(clientMessageId.rest, 4) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET bulkOrderIndex == ReadBytes(clientOrderId.rest, 1) IN IF ~bulkOrderIndex.ok THEN Fail ELSE
    LET side == ReadBytes(bulkOrderIndex.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET size == ReadBytes(side.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET engineSequenceNumber == ReadBytes(size.rest, 8) IN IF ~engineSequenceNumber.ok THEN Fail ELSE
    LET cancelReason == ReadBytes(engineSequenceNumber.rest, 1) IN IF ~cancelReason.ok THEN Fail ELSE
    Ok([ notificationTime     |-> notificationTime.value,
         mpid                 |-> mpid.value,
         productId            |-> productId.value,
         liquidityType        |-> liquidityType.value,
         clientMessageId      |-> clientMessageId.value,
         clientOrderId        |-> clientOrderId.value,
         bulkOrderIndex       |-> bulkOrderIndex.value,
         side                 |-> side.value,
         size                 |-> size.value,
         engineSequenceNumber |-> engineSequenceNumber.value,
         cancelReason         |-> cancelReason.value ], cancelReason.rest)

ZeroCancelNotification2 ==
    [ notificationTime     |-> [i \in 1 .. 8 |-> 0],
      mpid                 |-> [i \in 1 .. 4 |-> 0],
      productId            |-> [i \in 1 .. 4 |-> 0],
      liquidityType        |-> [i \in 1 .. 1 |-> 0],
      clientMessageId      |-> [i \in 1 .. 4 |-> 0],
      clientOrderId        |-> [i \in 1 .. 4 |-> 0],
      bulkOrderIndex       |-> [i \in 1 .. 1 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
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
        \cup { [ZeroCancelNotification2 EXCEPT !.clientOrderId = one] : one \in Sample(4) }
        \cup { [ZeroCancelNotification2 EXCEPT !.bulkOrderIndex = one] : one \in Sample(1) }
        \cup { [ZeroCancelNotification2 EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroCancelNotification2 EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroCancelNotification2 EXCEPT !.engineSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroCancelNotification2 EXCEPT !.cancelReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Unsequenced Message, selected by Unsequenced Message Type               *)
(***************************************************************************)

ArmSettingsUpdateRequestCode == 16723  \* "AS"
ArmSettingsUpdateResponseCode == 16705  \* "AA"
Arm2UnderlyingLevelProtectionSettingsUpdateRequestCode == 12883  \* "2S"
Arm2UnderlyingLevelProtectionSettingsUpdateResponseCode == 12882  \* "2R"
SeriesAssignmentRequestCode == 21313  \* "SA"
SeriesAssignmentResponseCode == 16722  \* "AR"
SelfTradeProtectionDesignationRequestCode == 21328  \* "SP"
SelfTradeProtectionDesignationResponseCode == 21330  \* "SR"
BulkLiquidityMessageCode == 27757  \* "lm"
BulkLiquidityMessageResponseCode == 19538  \* "LR"
LiquidityMassCancelRequestCode == 30833  \* "xq"
LiquidityMassCancelResponseCode == 22610  \* "XR"
LiquidityProtectionResetRequestCode == 20568  \* "PX"
LiquidityProtectionResetResponseCode == 20562  \* "PR"
SingleSideLiquidityProtectionResetRequestCode == 21331  \* "SS"
SingleSideLiquidityProtectionResetResponseCode == 21332  \* "ST"
LiquidityProtectionTriggerNotificationCode == 20816  \* "QP"
OrderNotificationCode == 20302  \* "ON"
DoneForTheDayNotificationCode == 17476  \* "DD"
CancelNotificationCode2 == 22606  \* "XN"

UnsequencedMessage ==
    [ tag : {ArmSettingsUpdateRequestCode}, body : ArmSettingsUpdateRequest ]
        \cup [ tag : {ArmSettingsUpdateResponseCode}, body : ArmSettingsUpdateResponse ]
        \cup [ tag : {Arm2UnderlyingLevelProtectionSettingsUpdateRequestCode}, body : Arm2UnderlyingLevelProtectionSettingsUpdateRequest ]
        \cup [ tag : {Arm2UnderlyingLevelProtectionSettingsUpdateResponseCode}, body : Arm2UnderlyingLevelProtectionSettingsUpdateResponse ]
        \cup [ tag : {SeriesAssignmentRequestCode}, body : SeriesAssignmentRequest ]
        \cup [ tag : {SeriesAssignmentResponseCode}, body : SeriesAssignmentResponse ]
        \cup [ tag : {SelfTradeProtectionDesignationRequestCode}, body : SelfTradeProtectionDesignationRequest ]
        \cup [ tag : {SelfTradeProtectionDesignationResponseCode}, body : SelfTradeProtectionDesignationResponse ]
        \cup [ tag : {BulkLiquidityMessageCode}, body : BulkLiquidityMessage ]
        \cup [ tag : {BulkLiquidityMessageResponseCode}, body : BulkLiquidityMessageResponse ]
        \cup [ tag : {LiquidityMassCancelRequestCode}, body : LiquidityMassCancelRequest ]
        \cup [ tag : {LiquidityMassCancelResponseCode}, body : LiquidityMassCancelResponse ]
        \cup [ tag : {LiquidityProtectionResetRequestCode}, body : LiquidityProtectionResetRequest ]
        \cup [ tag : {LiquidityProtectionResetResponseCode}, body : LiquidityProtectionResetResponse ]
        \cup [ tag : {SingleSideLiquidityProtectionResetRequestCode}, body : SingleSideLiquidityProtectionResetRequest ]
        \cup [ tag : {SingleSideLiquidityProtectionResetResponseCode}, body : SingleSideLiquidityProtectionResetResponse ]
        \cup [ tag : {LiquidityProtectionTriggerNotificationCode}, body : LiquidityProtectionTriggerNotification ]
        \cup [ tag : {OrderNotificationCode}, body : OrderNotification ]
        \cup [ tag : {DoneForTheDayNotificationCode}, body : DoneForTheDayNotification ]
        \cup [ tag : {CancelNotificationCode2}, body : CancelNotification2 ]

EncodeUnsequencedMessage(message) ==
    CASE message.tag = ArmSettingsUpdateRequestCode -> EncodeArmSettingsUpdateRequest(message.body)
      [] message.tag = ArmSettingsUpdateResponseCode -> EncodeArmSettingsUpdateResponse(message.body)
      [] message.tag = Arm2UnderlyingLevelProtectionSettingsUpdateRequestCode -> EncodeArm2UnderlyingLevelProtectionSettingsUpdateRequest(message.body)
      [] message.tag = Arm2UnderlyingLevelProtectionSettingsUpdateResponseCode -> EncodeArm2UnderlyingLevelProtectionSettingsUpdateResponse(message.body)
      [] message.tag = SeriesAssignmentRequestCode -> EncodeSeriesAssignmentRequest(message.body)
      [] message.tag = SeriesAssignmentResponseCode -> EncodeSeriesAssignmentResponse(message.body)
      [] message.tag = SelfTradeProtectionDesignationRequestCode -> EncodeSelfTradeProtectionDesignationRequest(message.body)
      [] message.tag = SelfTradeProtectionDesignationResponseCode -> EncodeSelfTradeProtectionDesignationResponse(message.body)
      [] message.tag = BulkLiquidityMessageCode -> EncodeBulkLiquidityMessage(message.body)
      [] message.tag = BulkLiquidityMessageResponseCode -> EncodeBulkLiquidityMessageResponse(message.body)
      [] message.tag = LiquidityMassCancelRequestCode -> EncodeLiquidityMassCancelRequest(message.body)
      [] message.tag = LiquidityMassCancelResponseCode -> EncodeLiquidityMassCancelResponse(message.body)
      [] message.tag = LiquidityProtectionResetRequestCode -> EncodeLiquidityProtectionResetRequest(message.body)
      [] message.tag = LiquidityProtectionResetResponseCode -> EncodeLiquidityProtectionResetResponse(message.body)
      [] message.tag = SingleSideLiquidityProtectionResetRequestCode -> EncodeSingleSideLiquidityProtectionResetRequest(message.body)
      [] message.tag = SingleSideLiquidityProtectionResetResponseCode -> EncodeSingleSideLiquidityProtectionResetResponse(message.body)
      [] message.tag = LiquidityProtectionTriggerNotificationCode -> EncodeLiquidityProtectionTriggerNotification(message.body)
      [] message.tag = OrderNotificationCode -> EncodeOrderNotification(message.body)
      [] message.tag = DoneForTheDayNotificationCode -> EncodeDoneForTheDayNotification(message.body)
      [] message.tag = CancelNotificationCode2 -> EncodeCancelNotification2(message.body)

DecodeUnsequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = ArmSettingsUpdateRequestCode -> DecodeArmSettingsUpdateRequest(bytes)
              [] tag = ArmSettingsUpdateResponseCode -> DecodeArmSettingsUpdateResponse(bytes)
              [] tag = Arm2UnderlyingLevelProtectionSettingsUpdateRequestCode -> DecodeArm2UnderlyingLevelProtectionSettingsUpdateRequest(bytes)
              [] tag = Arm2UnderlyingLevelProtectionSettingsUpdateResponseCode -> DecodeArm2UnderlyingLevelProtectionSettingsUpdateResponse(bytes)
              [] tag = SeriesAssignmentRequestCode -> DecodeSeriesAssignmentRequest(bytes)
              [] tag = SeriesAssignmentResponseCode -> DecodeSeriesAssignmentResponse(bytes)
              [] tag = SelfTradeProtectionDesignationRequestCode -> DecodeSelfTradeProtectionDesignationRequest(bytes)
              [] tag = SelfTradeProtectionDesignationResponseCode -> DecodeSelfTradeProtectionDesignationResponse(bytes)
              [] tag = BulkLiquidityMessageCode -> DecodeBulkLiquidityMessage(bytes)
              [] tag = BulkLiquidityMessageResponseCode -> DecodeBulkLiquidityMessageResponse(bytes)
              [] tag = LiquidityMassCancelRequestCode -> DecodeLiquidityMassCancelRequest(bytes)
              [] tag = LiquidityMassCancelResponseCode -> DecodeLiquidityMassCancelResponse(bytes)
              [] tag = LiquidityProtectionResetRequestCode -> DecodeLiquidityProtectionResetRequest(bytes)
              [] tag = LiquidityProtectionResetResponseCode -> DecodeLiquidityProtectionResetResponse(bytes)
              [] tag = SingleSideLiquidityProtectionResetRequestCode -> DecodeSingleSideLiquidityProtectionResetRequest(bytes)
              [] tag = SingleSideLiquidityProtectionResetResponseCode -> DecodeSingleSideLiquidityProtectionResetResponse(bytes)
              [] tag = LiquidityProtectionTriggerNotificationCode -> DecodeLiquidityProtectionTriggerNotification(bytes)
              [] tag = OrderNotificationCode -> DecodeOrderNotification(bytes)
              [] tag = DoneForTheDayNotificationCode -> DecodeDoneForTheDayNotification(bytes)
              [] tag = CancelNotificationCode2 -> DecodeCancelNotification2(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroUnsequencedMessage == [tag |-> ArmSettingsUpdateRequestCode, body |-> ZeroArmSettingsUpdateRequest]

(* Each Unsequenced Message in turn, at the values the message it names is checked at *)
CheckedUnsequencedMessage ==
    { [tag |-> ArmSettingsUpdateRequestCode, body |-> one] : one \in CheckedArmSettingsUpdateRequest }
        \cup { [tag |-> ArmSettingsUpdateResponseCode, body |-> one] : one \in CheckedArmSettingsUpdateResponse }
        \cup { [tag |-> Arm2UnderlyingLevelProtectionSettingsUpdateRequestCode, body |-> one] : one \in CheckedArm2UnderlyingLevelProtectionSettingsUpdateRequest }
        \cup { [tag |-> Arm2UnderlyingLevelProtectionSettingsUpdateResponseCode, body |-> one] : one \in CheckedArm2UnderlyingLevelProtectionSettingsUpdateResponse }
        \cup { [tag |-> SeriesAssignmentRequestCode, body |-> one] : one \in CheckedSeriesAssignmentRequest }
        \cup { [tag |-> SeriesAssignmentResponseCode, body |-> one] : one \in CheckedSeriesAssignmentResponse }
        \cup { [tag |-> SelfTradeProtectionDesignationRequestCode, body |-> one] : one \in CheckedSelfTradeProtectionDesignationRequest }
        \cup { [tag |-> SelfTradeProtectionDesignationResponseCode, body |-> one] : one \in CheckedSelfTradeProtectionDesignationResponse }
        \cup { [tag |-> BulkLiquidityMessageCode, body |-> one] : one \in CheckedBulkLiquidityMessage }
        \cup { [tag |-> BulkLiquidityMessageResponseCode, body |-> one] : one \in CheckedBulkLiquidityMessageResponse }
        \cup { [tag |-> LiquidityMassCancelRequestCode, body |-> one] : one \in CheckedLiquidityMassCancelRequest }
        \cup { [tag |-> LiquidityMassCancelResponseCode, body |-> one] : one \in CheckedLiquidityMassCancelResponse }
        \cup { [tag |-> LiquidityProtectionResetRequestCode, body |-> one] : one \in CheckedLiquidityProtectionResetRequest }
        \cup { [tag |-> LiquidityProtectionResetResponseCode, body |-> one] : one \in CheckedLiquidityProtectionResetResponse }
        \cup { [tag |-> SingleSideLiquidityProtectionResetRequestCode, body |-> one] : one \in CheckedSingleSideLiquidityProtectionResetRequest }
        \cup { [tag |-> SingleSideLiquidityProtectionResetResponseCode, body |-> one] : one \in CheckedSingleSideLiquidityProtectionResetResponse }
        \cup { [tag |-> LiquidityProtectionTriggerNotificationCode, body |-> one] : one \in CheckedLiquidityProtectionTriggerNotification }
        \cup { [tag |-> OrderNotificationCode, body |-> one] : one \in CheckedOrderNotification }
        \cup { [tag |-> DoneForTheDayNotificationCode, body |-> one] : one \in CheckedDoneForTheDayNotification }
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

(* Every System State Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripSystemStateNotification ==
    \A message \in CheckedSystemStateNotification :
        LET read == DecodeSystemStateNotification(EncodeSystemStateNotification(message))
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

(* Every Opening Width Relief Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripOpeningWidthReliefNotification ==
    \A message \in CheckedOpeningWidthReliefNotification :
        LET read == DecodeOpeningWidthReliefNotification(EncodeOpeningWidthReliefNotification(message))
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

(* Every Series Assignment Request decodes back to what was encoded, and leaves nothing over *)
RoundTripSeriesAssignmentRequest ==
    \A message \in CheckedSeriesAssignmentRequest :
        LET read == DecodeSeriesAssignmentRequest(EncodeSeriesAssignmentRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Series Assignment Response decodes back to what was encoded, and leaves nothing over *)
RoundTripSeriesAssignmentResponse ==
    \A message \in CheckedSeriesAssignmentResponse :
        LET read == DecodeSeriesAssignmentResponse(EncodeSeriesAssignmentResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Self Trade Protection Designation Request decodes back to what was encoded, and leaves nothing over *)
RoundTripSelfTradeProtectionDesignationRequest ==
    \A message \in CheckedSelfTradeProtectionDesignationRequest :
        LET read == DecodeSelfTradeProtectionDesignationRequest(EncodeSelfTradeProtectionDesignationRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Self Trade Protection Designation Response decodes back to what was encoded, and leaves nothing over *)
RoundTripSelfTradeProtectionDesignationResponse ==
    \A message \in CheckedSelfTradeProtectionDesignationResponse :
        LET read == DecodeSelfTradeProtectionDesignationResponse(EncodeSelfTradeProtectionDesignationResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Liquidity Units decodes back to what was encoded, and leaves nothing over *)
RoundTripLiquidityUnits ==
    \A message \in CheckedLiquidityUnits :
        LET read == DecodeLiquidityUnits(EncodeLiquidityUnits(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulk Liquidity Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkLiquidityMessage ==
    \A message \in CheckedBulkLiquidityMessage :
        LET read == DecodeBulkLiquidityMessage(EncodeBulkLiquidityMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Response decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderResponse ==
    \A message \in CheckedOrderResponse :
        LET read == DecodeOrderResponse(EncodeOrderResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulk Liquidity Message Response decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkLiquidityMessageResponse ==
    \A message \in CheckedBulkLiquidityMessageResponse :
        LET read == DecodeBulkLiquidityMessageResponse(EncodeBulkLiquidityMessageResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Liquidity Mass Cancel Request decodes back to what was encoded, and leaves nothing over *)
RoundTripLiquidityMassCancelRequest ==
    \A message \in CheckedLiquidityMassCancelRequest :
        LET read == DecodeLiquidityMassCancelRequest(EncodeLiquidityMassCancelRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Liquidity Mass Cancel Response decodes back to what was encoded, and leaves nothing over *)
RoundTripLiquidityMassCancelResponse ==
    \A message \in CheckedLiquidityMassCancelResponse :
        LET read == DecodeLiquidityMassCancelResponse(EncodeLiquidityMassCancelResponse(message))
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

(* Every Liquidity Protection Trigger Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripLiquidityProtectionTriggerNotification ==
    \A message \in CheckedLiquidityProtectionTriggerNotification :
        LET read == DecodeLiquidityProtectionTriggerNotification(EncodeLiquidityProtectionTriggerNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderNotification ==
    \A message \in CheckedOrderNotification :
        LET read == DecodeOrderNotification(EncodeOrderNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Done For The Day Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripDoneForTheDayNotification ==
    \A message \in CheckedDoneForTheDayNotification :
        LET read == DecodeDoneForTheDayNotification(EncodeDoneForTheDayNotification(message))
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
