---------------- MODULE PearlOptions_LiquidityFeed_v1_2_Tcp ----------------
(***************************************************************************)
(* Miami International Holdings Liquidity Feed v1.2                        *)
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
(* Series Update Message: 72 bytes                                         *)
(***************************************************************************)

SeriesUpdateMessage ==
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
      activeOnPearl                         : Sample(1),
      pearlBboPostingIncrementIndicator     : Sample(1),
      liquidityAcceptanceIncrementIndicator : Sample(1),
      openingUnderlyingMarketCode           : Sample(1),
      reserved12                            : Sample(12) ]

EncodeSeriesUpdateMessage(message) ==
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
        \o message.activeOnPearl
        \o message.pearlBboPostingIncrementIndicator
        \o message.liquidityAcceptanceIncrementIndicator
        \o message.openingUnderlyingMarketCode
        \o message.reserved12

DecodeSeriesUpdateMessage(bytes) ==
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
    LET activeOnPearl == ReadBytes(longTermOption.rest, 1) IN IF ~activeOnPearl.ok THEN Fail ELSE
    LET pearlBboPostingIncrementIndicator == ReadBytes(activeOnPearl.rest, 1) IN IF ~pearlBboPostingIncrementIndicator.ok THEN Fail ELSE
    LET liquidityAcceptanceIncrementIndicator == ReadBytes(pearlBboPostingIncrementIndicator.rest, 1) IN IF ~liquidityAcceptanceIncrementIndicator.ok THEN Fail ELSE
    LET openingUnderlyingMarketCode == ReadBytes(liquidityAcceptanceIncrementIndicator.rest, 1) IN IF ~openingUnderlyingMarketCode.ok THEN Fail ELSE
    LET reserved12 == ReadBytes(openingUnderlyingMarketCode.rest, 12) IN IF ~reserved12.ok THEN Fail ELSE
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
         activeOnPearl                         |-> activeOnPearl.value,
         pearlBboPostingIncrementIndicator     |-> pearlBboPostingIncrementIndicator.value,
         liquidityAcceptanceIncrementIndicator |-> liquidityAcceptanceIncrementIndicator.value,
         openingUnderlyingMarketCode           |-> openingUnderlyingMarketCode.value,
         reserved12                            |-> reserved12.value ], reserved12.rest)

ZeroSeriesUpdateMessage ==
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
      activeOnPearl                         |-> [i \in 1 .. 1 |-> 0],
      pearlBboPostingIncrementIndicator     |-> [i \in 1 .. 1 |-> 0],
      liquidityAcceptanceIncrementIndicator |-> [i \in 1 .. 1 |-> 0],
      openingUnderlyingMarketCode           |-> [i \in 1 .. 1 |-> 0],
      reserved12                            |-> [i \in 1 .. 12 |-> 0] ]

(* Series Update Message at zero, then each field in turn at the values it is checked at *)
CheckedSeriesUpdateMessage ==
    { ZeroSeriesUpdateMessage }
        \cup { [ZeroSeriesUpdateMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSeriesUpdateMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroSeriesUpdateMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }
        \cup { [ZeroSeriesUpdateMessage EXCEPT !.securitySymbol = one] : one \in Sample(6) }
        \cup { [ZeroSeriesUpdateMessage EXCEPT !.expirationDate = one] : one \in Sample(8) }
        \cup { [ZeroSeriesUpdateMessage EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroSeriesUpdateMessage EXCEPT !.callOrPut = one] : one \in Sample(1) }
        \cup { [ZeroSeriesUpdateMessage EXCEPT !.openingTime = one] : one \in Sample(8) }
        \cup { [ZeroSeriesUpdateMessage EXCEPT !.closingTime = one] : one \in Sample(8) }
        \cup { [ZeroSeriesUpdateMessage EXCEPT !.restrictedOption = one] : one \in Sample(1) }
        \cup { [ZeroSeriesUpdateMessage EXCEPT !.longTermOption = one] : one \in Sample(1) }
        \cup { [ZeroSeriesUpdateMessage EXCEPT !.activeOnPearl = one] : one \in Sample(1) }
        \cup { [ZeroSeriesUpdateMessage EXCEPT !.pearlBboPostingIncrementIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSeriesUpdateMessage EXCEPT !.liquidityAcceptanceIncrementIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSeriesUpdateMessage EXCEPT !.openingUnderlyingMarketCode = one] : one \in Sample(1) }
        \cup { [ZeroSeriesUpdateMessage EXCEPT !.reserved12 = one] : one \in Sample(12) }

(***************************************************************************)
(* System State Message: 17 bytes                                          *)
(***************************************************************************)

SystemStateMessage ==
    [ nanoseconds  : Sample(4),
      plfVersion   : Sample(8),
      sessionId    : Sample(4),
      systemStatus : Sample(1) ]

EncodeSystemStateMessage(message) ==
    message.nanoseconds
        \o message.plfVersion
        \o message.sessionId
        \o message.systemStatus

DecodeSystemStateMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET plfVersion == ReadBytes(nanoseconds.rest, 8) IN IF ~plfVersion.ok THEN Fail ELSE
    LET sessionId == ReadBytes(plfVersion.rest, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET systemStatus == ReadBytes(sessionId.rest, 1) IN IF ~systemStatus.ok THEN Fail ELSE
    Ok([ nanoseconds  |-> nanoseconds.value,
         plfVersion   |-> plfVersion.value,
         sessionId    |-> sessionId.value,
         systemStatus |-> systemStatus.value ], systemStatus.rest)

ZeroSystemStateMessage ==
    [ nanoseconds  |-> [i \in 1 .. 4 |-> 0],
      plfVersion   |-> [i \in 1 .. 8 |-> 0],
      sessionId    |-> [i \in 1 .. 4 |-> 0],
      systemStatus |-> [i \in 1 .. 1 |-> 0] ]

(* System State Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemStateMessage ==
    { ZeroSystemStateMessage }
        \cup { [ZeroSystemStateMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSystemStateMessage EXCEPT !.plfVersion = one] : one \in Sample(8) }
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
(* Order Message: 43 bytes                                                 *)
(***************************************************************************)

OrderMessage ==
    [ nanoseconds         : Sample(4),
      action              : Sample(1),
      productId           : Sample(4),
      orderId             : Sample(8),
      orderSide           : Sample(1),
      orderType           : Sample(1),
      orderPrice          : Sample(4),
      orderOriginalVolume : Sample(4),
      remainingVolumeOpen : Sample(4),
      timeInForceTif      : Sample(1),
      origin              : Sample(1),
      opencloseIndicator  : Sample(1),
      orderInstruction    : Sample(1),
      reserved8           : Sample(8) ]

EncodeOrderMessage(message) ==
    message.nanoseconds
        \o message.action
        \o message.productId
        \o message.orderId
        \o message.orderSide
        \o message.orderType
        \o message.orderPrice
        \o message.orderOriginalVolume
        \o message.remainingVolumeOpen
        \o message.timeInForceTif
        \o message.origin
        \o message.opencloseIndicator
        \o message.orderInstruction
        \o message.reserved8

DecodeOrderMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET action == ReadBytes(nanoseconds.rest, 1) IN IF ~action.ok THEN Fail ELSE
    LET productId == ReadBytes(action.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET orderId == ReadBytes(productId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET orderSide == ReadBytes(orderId.rest, 1) IN IF ~orderSide.ok THEN Fail ELSE
    LET orderType == ReadBytes(orderSide.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET orderPrice == ReadBytes(orderType.rest, 4) IN IF ~orderPrice.ok THEN Fail ELSE
    LET orderOriginalVolume == ReadBytes(orderPrice.rest, 4) IN IF ~orderOriginalVolume.ok THEN Fail ELSE
    LET remainingVolumeOpen == ReadBytes(orderOriginalVolume.rest, 4) IN IF ~remainingVolumeOpen.ok THEN Fail ELSE
    LET timeInForceTif == ReadBytes(remainingVolumeOpen.rest, 1) IN IF ~timeInForceTif.ok THEN Fail ELSE
    LET origin == ReadBytes(timeInForceTif.rest, 1) IN IF ~origin.ok THEN Fail ELSE
    LET opencloseIndicator == ReadBytes(origin.rest, 1) IN IF ~opencloseIndicator.ok THEN Fail ELSE
    LET orderInstruction == ReadBytes(opencloseIndicator.rest, 1) IN IF ~orderInstruction.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(orderInstruction.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    Ok([ nanoseconds         |-> nanoseconds.value,
         action              |-> action.value,
         productId           |-> productId.value,
         orderId             |-> orderId.value,
         orderSide           |-> orderSide.value,
         orderType           |-> orderType.value,
         orderPrice          |-> orderPrice.value,
         orderOriginalVolume |-> orderOriginalVolume.value,
         remainingVolumeOpen |-> remainingVolumeOpen.value,
         timeInForceTif      |-> timeInForceTif.value,
         origin              |-> origin.value,
         opencloseIndicator  |-> opencloseIndicator.value,
         orderInstruction    |-> orderInstruction.value,
         reserved8           |-> reserved8.value ], reserved8.rest)

ZeroOrderMessage ==
    [ nanoseconds         |-> [i \in 1 .. 4 |-> 0],
      action              |-> [i \in 1 .. 1 |-> 0],
      productId           |-> [i \in 1 .. 4 |-> 0],
      orderId             |-> [i \in 1 .. 8 |-> 0],
      orderSide           |-> [i \in 1 .. 1 |-> 0],
      orderType           |-> [i \in 1 .. 1 |-> 0],
      orderPrice          |-> [i \in 1 .. 4 |-> 0],
      orderOriginalVolume |-> [i \in 1 .. 4 |-> 0],
      remainingVolumeOpen |-> [i \in 1 .. 4 |-> 0],
      timeInForceTif      |-> [i \in 1 .. 1 |-> 0],
      origin              |-> [i \in 1 .. 1 |-> 0],
      opencloseIndicator  |-> [i \in 1 .. 1 |-> 0],
      orderInstruction    |-> [i \in 1 .. 1 |-> 0],
      reserved8           |-> [i \in 1 .. 8 |-> 0] ]

(* Order Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderMessage ==
    { ZeroOrderMessage }
        \cup { [ZeroOrderMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderMessage EXCEPT !.action = one] : one \in Sample(1) }
        \cup { [ZeroOrderMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderMessage EXCEPT !.orderSide = one] : one \in Sample(1) }
        \cup { [ZeroOrderMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroOrderMessage EXCEPT !.orderPrice = one] : one \in Sample(4) }
        \cup { [ZeroOrderMessage EXCEPT !.orderOriginalVolume = one] : one \in Sample(4) }
        \cup { [ZeroOrderMessage EXCEPT !.remainingVolumeOpen = one] : one \in Sample(4) }
        \cup { [ZeroOrderMessage EXCEPT !.timeInForceTif = one] : one \in Sample(1) }
        \cup { [ZeroOrderMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroOrderMessage EXCEPT !.opencloseIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderMessage EXCEPT !.orderInstruction = one] : one \in Sample(1) }
        \cup { [ZeroOrderMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Close Message: 12 bytes                                           *)
(***************************************************************************)

OrderCloseMessage ==
    [ nanoseconds : Sample(4),
      orderId     : Sample(8) ]

EncodeOrderCloseMessage(message) ==
    message.nanoseconds
        \o message.orderId

DecodeOrderCloseMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderId == ReadBytes(nanoseconds.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    Ok([ nanoseconds |-> nanoseconds.value,
         orderId     |-> orderId.value ], orderId.rest)

ZeroOrderCloseMessage ==
    [ nanoseconds |-> [i \in 1 .. 4 |-> 0],
      orderId     |-> [i \in 1 .. 8 |-> 0] ]

(* Order Close Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCloseMessage ==
    { ZeroOrderCloseMessage }
        \cup { [ZeroOrderCloseMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderCloseMessage EXCEPT !.orderId = one] : one \in Sample(8) }

(***************************************************************************)
(* Data, selected by Message Type                                          *)
(***************************************************************************)

SystemTimeMessageCode == 49  \* "1"
SeriesUpdateMessageCode == 80  \* "P"
SystemStateMessageCode == 83  \* "S"
UnderlyingTradingStatusNotificationMessageCode == 72  \* "H"
OrderMessageCode == 70  \* "F"
OrderCloseMessageCode == 120  \* "x"

Data ==
    [ tag : {SystemTimeMessageCode}, body : SystemTimeMessage ]
        \cup [ tag : {SeriesUpdateMessageCode}, body : SeriesUpdateMessage ]
        \cup [ tag : {SystemStateMessageCode}, body : SystemStateMessage ]
        \cup [ tag : {UnderlyingTradingStatusNotificationMessageCode}, body : UnderlyingTradingStatusNotificationMessage ]
        \cup [ tag : {OrderMessageCode}, body : OrderMessage ]
        \cup [ tag : {OrderCloseMessageCode}, body : OrderCloseMessage ]

EncodeData(message) ==
    CASE message.tag = SystemTimeMessageCode -> EncodeSystemTimeMessage(message.body)
      [] message.tag = SeriesUpdateMessageCode -> EncodeSeriesUpdateMessage(message.body)
      [] message.tag = SystemStateMessageCode -> EncodeSystemStateMessage(message.body)
      [] message.tag = UnderlyingTradingStatusNotificationMessageCode -> EncodeUnderlyingTradingStatusNotificationMessage(message.body)
      [] message.tag = OrderMessageCode -> EncodeOrderMessage(message.body)
      [] message.tag = OrderCloseMessageCode -> EncodeOrderCloseMessage(message.body)

DecodeData(tag, bytes) ==
    LET read ==
            CASE tag = SystemTimeMessageCode -> DecodeSystemTimeMessage(bytes)
              [] tag = SeriesUpdateMessageCode -> DecodeSeriesUpdateMessage(bytes)
              [] tag = SystemStateMessageCode -> DecodeSystemStateMessage(bytes)
              [] tag = UnderlyingTradingStatusNotificationMessageCode -> DecodeUnderlyingTradingStatusNotificationMessage(bytes)
              [] tag = OrderMessageCode -> DecodeOrderMessage(bytes)
              [] tag = OrderCloseMessageCode -> DecodeOrderCloseMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroData == [tag |-> SystemTimeMessageCode, body |-> ZeroSystemTimeMessage]

(* Each Data in turn, at the values the message it names is checked at *)
CheckedData ==
    { [tag |-> SystemTimeMessageCode, body |-> one] : one \in CheckedSystemTimeMessage }
        \cup { [tag |-> SeriesUpdateMessageCode, body |-> one] : one \in CheckedSeriesUpdateMessage }
        \cup { [tag |-> SystemStateMessageCode, body |-> one] : one \in CheckedSystemStateMessage }
        \cup { [tag |-> UnderlyingTradingStatusNotificationMessageCode, body |-> one] : one \in CheckedUnderlyingTradingStatusNotificationMessage }
        \cup { [tag |-> OrderMessageCode, body |-> one] : one \in CheckedOrderMessage }
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

(* Every Series Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSeriesUpdateMessage ==
    \A message \in CheckedSeriesUpdateMessage :
        LET read == DecodeSeriesUpdateMessage(EncodeSeriesUpdateMessage(message))
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

(* Every Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderMessage ==
    \A message \in CheckedOrderMessage :
        LET read == DecodeOrderMessage(EncodeOrderMessage(message))
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
