----------------- MODULE MrxOptions_SpreadOrders_v2_1_Udp ------------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Phlx Options Spread Orders v2.1                                *)
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
(* Note: a Message Count of 0 marks Heartbeat and carries no Message.      *)
(*                                                                         *)
(* Note: a Message Count of 0 marks End Of Session and carries no Message. *)
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

(* The integer a rule depends on *)
ReadUIntLE(bytes, width) ==
    IF Len(bytes) < width
    THEN Fail
    ELSE Ok(DecodeUIntLE(SubSeq(bytes, 1, width)), SubSeq(bytes, width + 1, Len(bytes)))

(***************************************************************************)
(* The values a field is checked at: zero, the spaces a text field is      *)
(* padded with, and                                                        *)
(* every bit set, which is where an encoding goes wrong if it goes wrong   *)
(***************************************************************************)

Sample(width) ==
    { [i \in 1 .. width |-> 0],
      [i \in 1 .. width |-> 32],
      [i \in 1 .. width |-> 255] }

(* The lists a record is checked over: none, one, and a run of two. What a run has *)
(* to get right is reading one entry after another, which two of a kind already say. *)
SampleLists(entries) ==
    { << >> }
        \cup { <<one>> : one \in entries }
        \cup { <<one, one>> : one \in entries }

(***************************************************************************)
(* System Event Message: 11 bytes                                          *)
(***************************************************************************)

SystemEventMessage ==
    [ trackingNumber : Sample(2),
      timestamp      : Sample(8),
      eventCode      : Sample(1) ]

EncodeSystemEventMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.eventCode

DecodeSystemEventMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET eventCode == ReadBytes(timestamp.rest, 1) IN IF ~eventCode.ok THEN Fail ELSE
    Ok([ trackingNumber |-> trackingNumber.value,
         timestamp      |-> timestamp.value,
         eventCode      |-> eventCode.value ], eventCode.rest)

ZeroSystemEventMessage ==
    [ trackingNumber |-> [i \in 1 .. 2 |-> 0],
      timestamp      |-> [i \in 1 .. 8 |-> 0],
      eventCode      |-> [i \in 1 .. 1 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroSystemEventMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Leg Information: 25 bytes                                               *)
(***************************************************************************)

LegInformation ==
    [ optionId            : Sample(4),
      securitySymbol      : Sample(8),
      expirationYear      : Sample(1),
      expirationMonth     : Sample(1),
      expirationDay       : Sample(1),
      explicitStrikePrice : Sample(4),
      optionType          : Sample(1),
      side                : Sample(1),
      legRatio            : Sample(4) ]

EncodeLegInformation(message) ==
    message.optionId
        \o message.securitySymbol
        \o message.expirationYear
        \o message.expirationMonth
        \o message.expirationDay
        \o message.explicitStrikePrice
        \o message.optionType
        \o message.side
        \o message.legRatio

DecodeLegInformation(bytes) ==
    LET optionId == ReadBytes(bytes, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(optionId.rest, 8) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET expirationYear == ReadBytes(securitySymbol.rest, 1) IN IF ~expirationYear.ok THEN Fail ELSE
    LET expirationMonth == ReadBytes(expirationYear.rest, 1) IN IF ~expirationMonth.ok THEN Fail ELSE
    LET expirationDay == ReadBytes(expirationMonth.rest, 1) IN IF ~expirationDay.ok THEN Fail ELSE
    LET explicitStrikePrice == ReadBytes(expirationDay.rest, 4) IN IF ~explicitStrikePrice.ok THEN Fail ELSE
    LET optionType == ReadBytes(explicitStrikePrice.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET side == ReadBytes(optionType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET legRatio == ReadBytes(side.rest, 4) IN IF ~legRatio.ok THEN Fail ELSE
    Ok([ optionId            |-> optionId.value,
         securitySymbol      |-> securitySymbol.value,
         expirationYear      |-> expirationYear.value,
         expirationMonth     |-> expirationMonth.value,
         expirationDay       |-> expirationDay.value,
         explicitStrikePrice |-> explicitStrikePrice.value,
         optionType          |-> optionType.value,
         side                |-> side.value,
         legRatio            |-> legRatio.value ], legRatio.rest)

ZeroLegInformation ==
    [ optionId            |-> [i \in 1 .. 4 |-> 0],
      securitySymbol      |-> [i \in 1 .. 8 |-> 0],
      expirationYear      |-> [i \in 1 .. 1 |-> 0],
      expirationMonth     |-> [i \in 1 .. 1 |-> 0],
      expirationDay       |-> [i \in 1 .. 1 |-> 0],
      explicitStrikePrice |-> [i \in 1 .. 4 |-> 0],
      optionType          |-> [i \in 1 .. 1 |-> 0],
      side                |-> [i \in 1 .. 1 |-> 0],
      legRatio            |-> [i \in 1 .. 4 |-> 0] ]

(* Leg Information at zero, then each field in turn at the values it is checked at *)
CheckedLegInformation ==
    { ZeroLegInformation }
        \cup { [ZeroLegInformation EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroLegInformation EXCEPT !.securitySymbol = one] : one \in Sample(8) }
        \cup { [ZeroLegInformation EXCEPT !.expirationYear = one] : one \in Sample(1) }
        \cup { [ZeroLegInformation EXCEPT !.expirationMonth = one] : one \in Sample(1) }
        \cup { [ZeroLegInformation EXCEPT !.expirationDay = one] : one \in Sample(1) }
        \cup { [ZeroLegInformation EXCEPT !.explicitStrikePrice = one] : one \in Sample(4) }
        \cup { [ZeroLegInformation EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroLegInformation EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroLegInformation EXCEPT !.legRatio = one] : one \in Sample(4) }

(* A run of Leg Information, written one after another *)
RECURSIVE EncodeLegInformationList(_)
EncodeLegInformationList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLegInformation(Head(messages)) \o EncodeLegInformationList(Tail(messages))

(* As many Leg Information as the field that counts them says *)
RECURSIVE ReadLegInformationList(_, _)
ReadLegInformationList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLegInformation(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLegInformationList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Leg Information of each kind, for the lists that carry them *)
OneLegInformation == { ZeroLegInformation }

(***************************************************************************)
(* Complex Strategy Directory Message                                      *)
(***************************************************************************)

ComplexStrategyDirectoryMessage ==
    [ trackingNumber   : Sample(2),
      timestamp        : Sample(8),
      strategyId       : Sample(4),
      strategyType     : Sample(1),
      underlyingSymbol : Sample(13),
      reserved16       : Sample(16),
      legInformation   : SampleLists(OneLegInformation) ]

EncodeComplexStrategyDirectoryMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.strategyId
        \o message.strategyType
        \o message.underlyingSymbol
        \o message.reserved16
        \o EncodeUIntLE(Len(message.legInformation), 1)
        \o EncodeLegInformationList(message.legInformation)

DecodeComplexStrategyDirectoryMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET strategyId == ReadBytes(timestamp.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET strategyType == ReadBytes(strategyId.rest, 1) IN IF ~strategyType.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(strategyType.rest, 13) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET reserved16 == ReadBytes(underlyingSymbol.rest, 16) IN IF ~reserved16.ok THEN Fail ELSE
    LET numberOfLegs == ReadUIntLE(reserved16.rest, 1) IN IF ~numberOfLegs.ok THEN Fail ELSE
    LET legInformation == ReadLegInformationList(numberOfLegs.rest, numberOfLegs.value) IN IF ~legInformation.ok THEN Fail ELSE
    Ok([ trackingNumber   |-> trackingNumber.value,
         timestamp        |-> timestamp.value,
         strategyId       |-> strategyId.value,
         strategyType     |-> strategyType.value,
         underlyingSymbol |-> underlyingSymbol.value,
         reserved16       |-> reserved16.value,
         legInformation   |-> legInformation.value ], legInformation.rest)

ZeroComplexStrategyDirectoryMessage ==
    [ trackingNumber   |-> [i \in 1 .. 2 |-> 0],
      timestamp        |-> [i \in 1 .. 8 |-> 0],
      strategyId       |-> [i \in 1 .. 4 |-> 0],
      strategyType     |-> [i \in 1 .. 1 |-> 0],
      underlyingSymbol |-> [i \in 1 .. 13 |-> 0],
      reserved16       |-> [i \in 1 .. 16 |-> 0],
      legInformation   |-> << >> ]

(* Complex Strategy Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexStrategyDirectoryMessage ==
    { ZeroComplexStrategyDirectoryMessage }
        \cup { [ZeroComplexStrategyDirectoryMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroComplexStrategyDirectoryMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroComplexStrategyDirectoryMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroComplexStrategyDirectoryMessage EXCEPT !.strategyType = one] : one \in Sample(1) }
        \cup { [ZeroComplexStrategyDirectoryMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(13) }
        \cup { [ZeroComplexStrategyDirectoryMessage EXCEPT !.reserved16 = one] : one \in Sample(16) }
        \cup { [ZeroComplexStrategyDirectoryMessage EXCEPT !.legInformation = one] : one \in SampleLists(OneLegInformation) }

(***************************************************************************)
(* Strategy Trading Action Message: 15 bytes                               *)
(***************************************************************************)

StrategyTradingActionMessage ==
    [ trackingNumber      : Sample(2),
      timestamp           : Sample(8),
      strategyId          : Sample(4),
      currentTradingState : Sample(1) ]

EncodeStrategyTradingActionMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.strategyId
        \o message.currentTradingState

DecodeStrategyTradingActionMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET strategyId == ReadBytes(timestamp.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET currentTradingState == ReadBytes(strategyId.rest, 1) IN IF ~currentTradingState.ok THEN Fail ELSE
    Ok([ trackingNumber      |-> trackingNumber.value,
         timestamp           |-> timestamp.value,
         strategyId          |-> strategyId.value,
         currentTradingState |-> currentTradingState.value ], currentTradingState.rest)

ZeroStrategyTradingActionMessage ==
    [ trackingNumber      |-> [i \in 1 .. 2 |-> 0],
      timestamp           |-> [i \in 1 .. 8 |-> 0],
      strategyId          |-> [i \in 1 .. 4 |-> 0],
      currentTradingState |-> [i \in 1 .. 1 |-> 0] ]

(* Strategy Trading Action Message at zero, then each field in turn at the values it is checked at *)
CheckedStrategyTradingActionMessage ==
    { ZeroStrategyTradingActionMessage }
        \cup { [ZeroStrategyTradingActionMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroStrategyTradingActionMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroStrategyTradingActionMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroStrategyTradingActionMessage EXCEPT !.currentTradingState = one] : one \in Sample(1) }

(***************************************************************************)
(* Complex Add Order Message: 58 bytes                                     *)
(***************************************************************************)

ComplexAddOrderMessage ==
    [ trackingNumber        : Sample(2),
      timestamp             : Sample(8),
      strategyId            : Sample(4),
      orderReferenceNumber  : Sample(8),
      side                  : Sample(1),
      originalOrderVolume   : Sample(4),
      executableOrderVolume : Sample(4),
      orderStatus           : Sample(1),
      orderType             : Sample(1),
      limitPrice            : Sample(4),
      timeInForce           : Sample(1),
      orderCapacity         : Sample(1),
      scope                 : Sample(1),
      ownerId               : Sample(6),
      giveup                : Sample(6),
      cmta                  : Sample(6) ]

EncodeComplexAddOrderMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.strategyId
        \o message.orderReferenceNumber
        \o message.side
        \o message.originalOrderVolume
        \o message.executableOrderVolume
        \o message.orderStatus
        \o message.orderType
        \o message.limitPrice
        \o message.timeInForce
        \o message.orderCapacity
        \o message.scope
        \o message.ownerId
        \o message.giveup
        \o message.cmta

DecodeComplexAddOrderMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET strategyId == ReadBytes(timestamp.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(strategyId.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET side == ReadBytes(orderReferenceNumber.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET originalOrderVolume == ReadBytes(side.rest, 4) IN IF ~originalOrderVolume.ok THEN Fail ELSE
    LET executableOrderVolume == ReadBytes(originalOrderVolume.rest, 4) IN IF ~executableOrderVolume.ok THEN Fail ELSE
    LET orderStatus == ReadBytes(executableOrderVolume.rest, 1) IN IF ~orderStatus.ok THEN Fail ELSE
    LET orderType == ReadBytes(orderStatus.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET limitPrice == ReadBytes(orderType.rest, 4) IN IF ~limitPrice.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(limitPrice.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET orderCapacity == ReadBytes(timeInForce.rest, 1) IN IF ~orderCapacity.ok THEN Fail ELSE
    LET scope == ReadBytes(orderCapacity.rest, 1) IN IF ~scope.ok THEN Fail ELSE
    LET ownerId == ReadBytes(scope.rest, 6) IN IF ~ownerId.ok THEN Fail ELSE
    LET giveup == ReadBytes(ownerId.rest, 6) IN IF ~giveup.ok THEN Fail ELSE
    LET cmta == ReadBytes(giveup.rest, 6) IN IF ~cmta.ok THEN Fail ELSE
    Ok([ trackingNumber        |-> trackingNumber.value,
         timestamp             |-> timestamp.value,
         strategyId            |-> strategyId.value,
         orderReferenceNumber  |-> orderReferenceNumber.value,
         side                  |-> side.value,
         originalOrderVolume   |-> originalOrderVolume.value,
         executableOrderVolume |-> executableOrderVolume.value,
         orderStatus           |-> orderStatus.value,
         orderType             |-> orderType.value,
         limitPrice            |-> limitPrice.value,
         timeInForce           |-> timeInForce.value,
         orderCapacity         |-> orderCapacity.value,
         scope                 |-> scope.value,
         ownerId               |-> ownerId.value,
         giveup                |-> giveup.value,
         cmta                  |-> cmta.value ], cmta.rest)

ZeroComplexAddOrderMessage ==
    [ trackingNumber        |-> [i \in 1 .. 2 |-> 0],
      timestamp             |-> [i \in 1 .. 8 |-> 0],
      strategyId            |-> [i \in 1 .. 4 |-> 0],
      orderReferenceNumber  |-> [i \in 1 .. 8 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      originalOrderVolume   |-> [i \in 1 .. 4 |-> 0],
      executableOrderVolume |-> [i \in 1 .. 4 |-> 0],
      orderStatus           |-> [i \in 1 .. 1 |-> 0],
      orderType             |-> [i \in 1 .. 1 |-> 0],
      limitPrice            |-> [i \in 1 .. 4 |-> 0],
      timeInForce           |-> [i \in 1 .. 1 |-> 0],
      orderCapacity         |-> [i \in 1 .. 1 |-> 0],
      scope                 |-> [i \in 1 .. 1 |-> 0],
      ownerId               |-> [i \in 1 .. 6 |-> 0],
      giveup                |-> [i \in 1 .. 6 |-> 0],
      cmta                  |-> [i \in 1 .. 6 |-> 0] ]

(* Complex Add Order Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexAddOrderMessage ==
    { ZeroComplexAddOrderMessage }
        \cup { [ZeroComplexAddOrderMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroComplexAddOrderMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroComplexAddOrderMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroComplexAddOrderMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroComplexAddOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroComplexAddOrderMessage EXCEPT !.originalOrderVolume = one] : one \in Sample(4) }
        \cup { [ZeroComplexAddOrderMessage EXCEPT !.executableOrderVolume = one] : one \in Sample(4) }
        \cup { [ZeroComplexAddOrderMessage EXCEPT !.orderStatus = one] : one \in Sample(1) }
        \cup { [ZeroComplexAddOrderMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroComplexAddOrderMessage EXCEPT !.limitPrice = one] : one \in Sample(4) }
        \cup { [ZeroComplexAddOrderMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroComplexAddOrderMessage EXCEPT !.orderCapacity = one] : one \in Sample(1) }
        \cup { [ZeroComplexAddOrderMessage EXCEPT !.scope = one] : one \in Sample(1) }
        \cup { [ZeroComplexAddOrderMessage EXCEPT !.ownerId = one] : one \in Sample(6) }
        \cup { [ZeroComplexAddOrderMessage EXCEPT !.giveup = one] : one \in Sample(6) }
        \cup { [ZeroComplexAddOrderMessage EXCEPT !.cmta = one] : one \in Sample(6) }

(***************************************************************************)
(* Flex Dac Leg Information: 8 bytes                                       *)
(***************************************************************************)

FlexDacLegInformation ==
    [ reserved8 : Sample(8) ]

EncodeFlexDacLegInformation(message) ==
    message.reserved8

DecodeFlexDacLegInformation(bytes) ==
    LET reserved8 == ReadBytes(bytes, 8) IN IF ~reserved8.ok THEN Fail ELSE
    Ok([ reserved8 |-> reserved8.value ], reserved8.rest)

ZeroFlexDacLegInformation ==
    [ reserved8 |-> [i \in 1 .. 8 |-> 0] ]

(* Flex Dac Leg Information at zero, then each field in turn at the values it is checked at *)
CheckedFlexDacLegInformation ==
    { ZeroFlexDacLegInformation }
        \cup { [ZeroFlexDacLegInformation EXCEPT !.reserved8 = one] : one \in Sample(8) }

(* A run of Flex Dac Leg Information, written one after another *)
RECURSIVE EncodeFlexDacLegInformationList(_)
EncodeFlexDacLegInformationList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeFlexDacLegInformation(Head(messages)) \o EncodeFlexDacLegInformationList(Tail(messages))

(* As many Flex Dac Leg Information as the field that counts them says *)
RECURSIVE ReadFlexDacLegInformationList(_, _)
ReadFlexDacLegInformationList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeFlexDacLegInformation(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadFlexDacLegInformationList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Flex Dac Leg Information of each kind, for the lists that carry them *)
OneFlexDacLegInformation == { ZeroFlexDacLegInformation }

(***************************************************************************)
(* Complex Strategy Auction Message                                        *)
(***************************************************************************)

ComplexStrategyAuctionMessage ==
    [ trackingNumber        : Sample(2),
      timestamp             : Sample(8),
      strategyId            : Sample(4),
      auctionId             : Sample(4),
      auctionType           : Sample(1),
      auctionDuration       : Sample(4),
      auctionEvent          : Sample(1),
      orderType             : Sample(1),
      side                  : Sample(1),
      price                 : Sample(4),
      size                  : Sample(4),
      execFlag              : Sample(1),
      orderCapacity         : Sample(1),
      scope                 : Sample(1),
      ownerId               : Sample(6),
      giveup                : Sample(6),
      cmta                  : Sample(6),
      responsePrice         : Sample(4),
      responseSize          : Sample(4),
      reserved4             : Sample(4),
      flexDacLegInformation : SampleLists(OneFlexDacLegInformation) ]

EncodeComplexStrategyAuctionMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.strategyId
        \o message.auctionId
        \o message.auctionType
        \o message.auctionDuration
        \o message.auctionEvent
        \o message.orderType
        \o message.side
        \o message.price
        \o message.size
        \o message.execFlag
        \o message.orderCapacity
        \o message.scope
        \o message.ownerId
        \o message.giveup
        \o message.cmta
        \o message.responsePrice
        \o message.responseSize
        \o message.reserved4
        \o EncodeUIntLE(Len(message.flexDacLegInformation), 1)
        \o EncodeFlexDacLegInformationList(message.flexDacLegInformation)

DecodeComplexStrategyAuctionMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET strategyId == ReadBytes(timestamp.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET auctionId == ReadBytes(strategyId.rest, 4) IN IF ~auctionId.ok THEN Fail ELSE
    LET auctionType == ReadBytes(auctionId.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET auctionDuration == ReadBytes(auctionType.rest, 4) IN IF ~auctionDuration.ok THEN Fail ELSE
    LET auctionEvent == ReadBytes(auctionDuration.rest, 1) IN IF ~auctionEvent.ok THEN Fail ELSE
    LET orderType == ReadBytes(auctionEvent.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET side == ReadBytes(orderType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadBytes(side.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET size == ReadBytes(price.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET execFlag == ReadBytes(size.rest, 1) IN IF ~execFlag.ok THEN Fail ELSE
    LET orderCapacity == ReadBytes(execFlag.rest, 1) IN IF ~orderCapacity.ok THEN Fail ELSE
    LET scope == ReadBytes(orderCapacity.rest, 1) IN IF ~scope.ok THEN Fail ELSE
    LET ownerId == ReadBytes(scope.rest, 6) IN IF ~ownerId.ok THEN Fail ELSE
    LET giveup == ReadBytes(ownerId.rest, 6) IN IF ~giveup.ok THEN Fail ELSE
    LET cmta == ReadBytes(giveup.rest, 6) IN IF ~cmta.ok THEN Fail ELSE
    LET responsePrice == ReadBytes(cmta.rest, 4) IN IF ~responsePrice.ok THEN Fail ELSE
    LET responseSize == ReadBytes(responsePrice.rest, 4) IN IF ~responseSize.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(responseSize.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET numberOfFlexDacLegs == ReadUIntLE(reserved4.rest, 1) IN IF ~numberOfFlexDacLegs.ok THEN Fail ELSE
    LET flexDacLegInformation == ReadFlexDacLegInformationList(numberOfFlexDacLegs.rest, numberOfFlexDacLegs.value) IN IF ~flexDacLegInformation.ok THEN Fail ELSE
    Ok([ trackingNumber        |-> trackingNumber.value,
         timestamp             |-> timestamp.value,
         strategyId            |-> strategyId.value,
         auctionId             |-> auctionId.value,
         auctionType           |-> auctionType.value,
         auctionDuration       |-> auctionDuration.value,
         auctionEvent          |-> auctionEvent.value,
         orderType             |-> orderType.value,
         side                  |-> side.value,
         price                 |-> price.value,
         size                  |-> size.value,
         execFlag              |-> execFlag.value,
         orderCapacity         |-> orderCapacity.value,
         scope                 |-> scope.value,
         ownerId               |-> ownerId.value,
         giveup                |-> giveup.value,
         cmta                  |-> cmta.value,
         responsePrice         |-> responsePrice.value,
         responseSize          |-> responseSize.value,
         reserved4             |-> reserved4.value,
         flexDacLegInformation |-> flexDacLegInformation.value ], flexDacLegInformation.rest)

ZeroComplexStrategyAuctionMessage ==
    [ trackingNumber        |-> [i \in 1 .. 2 |-> 0],
      timestamp             |-> [i \in 1 .. 8 |-> 0],
      strategyId            |-> [i \in 1 .. 4 |-> 0],
      auctionId             |-> [i \in 1 .. 4 |-> 0],
      auctionType           |-> [i \in 1 .. 1 |-> 0],
      auctionDuration       |-> [i \in 1 .. 4 |-> 0],
      auctionEvent          |-> [i \in 1 .. 1 |-> 0],
      orderType             |-> [i \in 1 .. 1 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      price                 |-> [i \in 1 .. 4 |-> 0],
      size                  |-> [i \in 1 .. 4 |-> 0],
      execFlag              |-> [i \in 1 .. 1 |-> 0],
      orderCapacity         |-> [i \in 1 .. 1 |-> 0],
      scope                 |-> [i \in 1 .. 1 |-> 0],
      ownerId               |-> [i \in 1 .. 6 |-> 0],
      giveup                |-> [i \in 1 .. 6 |-> 0],
      cmta                  |-> [i \in 1 .. 6 |-> 0],
      responsePrice         |-> [i \in 1 .. 4 |-> 0],
      responseSize          |-> [i \in 1 .. 4 |-> 0],
      reserved4             |-> [i \in 1 .. 4 |-> 0],
      flexDacLegInformation |-> << >> ]

(* Complex Strategy Auction Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexStrategyAuctionMessage ==
    { ZeroComplexStrategyAuctionMessage }
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.auctionId = one] : one \in Sample(4) }
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.auctionDuration = one] : one \in Sample(4) }
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.auctionEvent = one] : one \in Sample(1) }
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.execFlag = one] : one \in Sample(1) }
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.orderCapacity = one] : one \in Sample(1) }
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.scope = one] : one \in Sample(1) }
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.ownerId = one] : one \in Sample(6) }
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.giveup = one] : one \in Sample(6) }
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.cmta = one] : one \in Sample(6) }
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.responsePrice = one] : one \in Sample(4) }
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.responseSize = one] : one \in Sample(4) }
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.flexDacLegInformation = one] : one \in SampleLists(OneFlexDacLegInformation) }

(***************************************************************************)
(* Udp Payload, selected by Message Type                                   *)
(***************************************************************************)

SystemEventMessageCode == 83  \* "S"
ComplexStrategyDirectoryMessageCode == 115  \* "s"
StrategyTradingActionMessageCode == 72  \* "H"
ComplexAddOrderMessageCode == 67  \* "C"
ComplexStrategyAuctionMessageCode == 97  \* "a"

UdpPayload ==
    [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {ComplexStrategyDirectoryMessageCode}, body : ComplexStrategyDirectoryMessage ]
        \cup [ tag : {StrategyTradingActionMessageCode}, body : StrategyTradingActionMessage ]
        \cup [ tag : {ComplexAddOrderMessageCode}, body : ComplexAddOrderMessage ]
        \cup [ tag : {ComplexStrategyAuctionMessageCode}, body : ComplexStrategyAuctionMessage ]

EncodeUdpPayload(message) ==
    CASE message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = ComplexStrategyDirectoryMessageCode -> EncodeComplexStrategyDirectoryMessage(message.body)
      [] message.tag = StrategyTradingActionMessageCode -> EncodeStrategyTradingActionMessage(message.body)
      [] message.tag = ComplexAddOrderMessageCode -> EncodeComplexAddOrderMessage(message.body)
      [] message.tag = ComplexStrategyAuctionMessageCode -> EncodeComplexStrategyAuctionMessage(message.body)

DecodeUdpPayload(tag, bytes) ==
    LET read ==
            CASE tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = ComplexStrategyDirectoryMessageCode -> DecodeComplexStrategyDirectoryMessage(bytes)
              [] tag = StrategyTradingActionMessageCode -> DecodeStrategyTradingActionMessage(bytes)
              [] tag = ComplexAddOrderMessageCode -> DecodeComplexAddOrderMessage(bytes)
              [] tag = ComplexStrategyAuctionMessageCode -> DecodeComplexStrategyAuctionMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroUdpPayload == [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]

(* Each Udp Payload in turn, at the values the message it names is checked at *)
CheckedUdpPayload ==
    { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> ComplexStrategyDirectoryMessageCode, body |-> one] : one \in CheckedComplexStrategyDirectoryMessage }
        \cup { [tag |-> StrategyTradingActionMessageCode, body |-> one] : one \in CheckedStrategyTradingActionMessage }
        \cup { [tag |-> ComplexAddOrderMessageCode, body |-> one] : one \in CheckedComplexAddOrderMessage }
        \cup { [tag |-> ComplexStrategyAuctionMessageCode, body |-> one] : one \in CheckedComplexStrategyAuctionMessage }

(***************************************************************************)
(* Message, framed by Message Length                                       *)
(***************************************************************************)

Message ==
    [ udpPayload : UdpPayload ]

EncodeMessageBody(message) ==
    EncodeUIntLE(message.udpPayload.tag, 1)
        \o EncodeUdpPayload(message.udpPayload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntLE(Len(body), 2) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntLE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET udpPayload == DecodeUdpPayload(messageType.value, messageType.rest) IN IF ~udpPayload.ok THEN Fail ELSE
    Ok([ udpPayload |-> udpPayload.value ], udpPayload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroMessage ==
    [ udpPayload |-> ZeroUdpPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.udpPayload = one] : one \in CheckedUdpPayload }

(* A run of Message, written one after another *)
RECURSIVE EncodeMessageList(_)
EncodeMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMessage(Head(messages)) \o EncodeMessageList(Tail(messages))

(* As many Message as the field that counts them says *)
RECURSIVE ReadMessageList(_, _)
ReadMessageList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMessageList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Message of each kind, for the lists that carry them *)
OneMessage ==
    { [ZeroMessage EXCEPT !.udpPayload = [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]],
      [ZeroMessage EXCEPT !.udpPayload = [tag |-> ComplexStrategyDirectoryMessageCode, body |-> ZeroComplexStrategyDirectoryMessage]],
      [ZeroMessage EXCEPT !.udpPayload = [tag |-> StrategyTradingActionMessageCode, body |-> ZeroStrategyTradingActionMessage]],
      [ZeroMessage EXCEPT !.udpPayload = [tag |-> ComplexAddOrderMessageCode, body |-> ZeroComplexAddOrderMessage]],
      [ZeroMessage EXCEPT !.udpPayload = [tag |-> ComplexStrategyAuctionMessageCode, body |-> ZeroComplexStrategyAuctionMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ udpSession        : Sample(10),
      udpSequenceNumber : Sample(8),
      message           : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.udpSession
        \o message.udpSequenceNumber
        \o EncodeUIntLE(Len(message.message), 2)
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET udpSession == ReadBytes(bytes, 10) IN IF ~udpSession.ok THEN Fail ELSE
    LET udpSequenceNumber == ReadBytes(udpSession.rest, 8) IN IF ~udpSequenceNumber.ok THEN Fail ELSE
    LET messageCount == ReadUIntLE(udpSequenceNumber.rest, 2) IN IF ~messageCount.ok THEN Fail ELSE
    LET message == ReadMessageList(messageCount.rest, messageCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ udpSession        |-> udpSession.value,
         udpSequenceNumber |-> udpSequenceNumber.value,
         message           |-> message.value ], message.rest)

ZeroPacket ==
    [ udpSession        |-> [i \in 1 .. 10 |-> 0],
      udpSequenceNumber |-> [i \in 1 .. 8 |-> 0],
      message           |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.udpSession = one] : one \in Sample(10) }
        \cup { [ZeroPacket EXCEPT !.udpSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroPacket EXCEPT !.message = one] : one \in SampleLists(OneMessage) }

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
                /\ \A i \in 1 .. width : EncodeUIntLE(value, width)[i] \in Byte

(* Every System Event Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSystemEventMessage ==
    \A message \in CheckedSystemEventMessage :
        LET read == DecodeSystemEventMessage(EncodeSystemEventMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Leg Information decodes back to what was encoded, and leaves nothing over *)
RoundTripLegInformation ==
    \A message \in CheckedLegInformation :
        LET read == DecodeLegInformation(EncodeLegInformation(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Strategy Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexStrategyDirectoryMessage ==
    \A message \in CheckedComplexStrategyDirectoryMessage :
        LET read == DecodeComplexStrategyDirectoryMessage(EncodeComplexStrategyDirectoryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Trading Action Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyTradingActionMessage ==
    \A message \in CheckedStrategyTradingActionMessage :
        LET read == DecodeStrategyTradingActionMessage(EncodeStrategyTradingActionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Add Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexAddOrderMessage ==
    \A message \in CheckedComplexAddOrderMessage :
        LET read == DecodeComplexAddOrderMessage(EncodeComplexAddOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Flex Dac Leg Information decodes back to what was encoded, and leaves nothing over *)
RoundTripFlexDacLegInformation ==
    \A message \in CheckedFlexDacLegInformation :
        LET read == DecodeFlexDacLegInformation(EncodeFlexDacLegInformation(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Strategy Auction Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexStrategyAuctionMessage ==
    \A message \in CheckedComplexStrategyAuctionMessage :
        LET read == DecodeComplexStrategyAuctionMessage(EncodeComplexStrategyAuctionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMessage ==
    \A message \in CheckedMessage :
        LET read == DecodeMessage(EncodeMessage(message))
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

(* A Udp Payload is selected by the Message Type it is written under *)
SelectsUdpPayload ==
    \A message \in UdpPayload :
        LET read == DecodeUdpPayload(message.tag, EncodeUdpPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Message Length is written from the bytes it frames *)
FramesMessage ==
    \A message \in Message :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
