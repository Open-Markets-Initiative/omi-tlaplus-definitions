------------------ MODULE IseOptions_OrderComboFeed_v1_1 -------------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Ise Order Combo Market Data Feed v1.1                          *)
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
(* System Event Message: 13 bytes                                          *)
(***************************************************************************)

SystemEventMessage ==
    [ timestamp    : Sample(6),
      eventCode    : Sample(1),
      currentYear  : Sample(2),
      currentMonth : Sample(1),
      currentDay   : Sample(1),
      version      : Sample(1),
      subversion   : Sample(1) ]

EncodeSystemEventMessage(message) ==
    message.timestamp
        \o message.eventCode
        \o message.currentYear
        \o message.currentMonth
        \o message.currentDay
        \o message.version
        \o message.subversion

DecodeSystemEventMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET eventCode == ReadBytes(timestamp.rest, 1) IN IF ~eventCode.ok THEN Fail ELSE
    LET currentYear == ReadBytes(eventCode.rest, 2) IN IF ~currentYear.ok THEN Fail ELSE
    LET currentMonth == ReadBytes(currentYear.rest, 1) IN IF ~currentMonth.ok THEN Fail ELSE
    LET currentDay == ReadBytes(currentMonth.rest, 1) IN IF ~currentDay.ok THEN Fail ELSE
    LET version == ReadBytes(currentDay.rest, 1) IN IF ~version.ok THEN Fail ELSE
    LET subversion == ReadBytes(version.rest, 1) IN IF ~subversion.ok THEN Fail ELSE
    Ok([ timestamp    |-> timestamp.value,
         eventCode    |-> eventCode.value,
         currentYear  |-> currentYear.value,
         currentMonth |-> currentMonth.value,
         currentDay   |-> currentDay.value,
         version      |-> version.value,
         subversion   |-> subversion.value ], subversion.rest)

ZeroSystemEventMessage ==
    [ timestamp    |-> [i \in 1 .. 6 |-> 0],
      eventCode    |-> [i \in 1 .. 1 |-> 0],
      currentYear  |-> [i \in 1 .. 2 |-> 0],
      currentMonth |-> [i \in 1 .. 1 |-> 0],
      currentDay   |-> [i \in 1 .. 1 |-> 0],
      version      |-> [i \in 1 .. 1 |-> 0],
      subversion   |-> [i \in 1 .. 1 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventCode = one] : one \in Sample(1) }
        \cup { [ZeroSystemEventMessage EXCEPT !.currentYear = one] : one \in Sample(2) }
        \cup { [ZeroSystemEventMessage EXCEPT !.currentMonth = one] : one \in Sample(1) }
        \cup { [ZeroSystemEventMessage EXCEPT !.currentDay = one] : one \in Sample(1) }
        \cup { [ZeroSystemEventMessage EXCEPT !.version = one] : one \in Sample(1) }
        \cup { [ZeroSystemEventMessage EXCEPT !.subversion = one] : one \in Sample(1) }

(***************************************************************************)
(* Leg Information: 28 bytes                                               *)
(***************************************************************************)

LegInformation ==
    [ optionId            : Sample(4),
      securitySymbol      : Sample(6),
      legId               : Sample(1),
      expirationYear      : Sample(1),
      expirationMonth     : Sample(1),
      expirationDay       : Sample(1),
      explicitStrikePrice : Sample(8),
      optionType          : Sample(1),
      legSide             : Sample(1),
      legRatio            : Sample(4) ]

EncodeLegInformation(message) ==
    message.optionId
        \o message.securitySymbol
        \o message.legId
        \o message.expirationYear
        \o message.expirationMonth
        \o message.expirationDay
        \o message.explicitStrikePrice
        \o message.optionType
        \o message.legSide
        \o message.legRatio

DecodeLegInformation(bytes) ==
    LET optionId == ReadBytes(bytes, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(optionId.rest, 6) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET legId == ReadBytes(securitySymbol.rest, 1) IN IF ~legId.ok THEN Fail ELSE
    LET expirationYear == ReadBytes(legId.rest, 1) IN IF ~expirationYear.ok THEN Fail ELSE
    LET expirationMonth == ReadBytes(expirationYear.rest, 1) IN IF ~expirationMonth.ok THEN Fail ELSE
    LET expirationDay == ReadBytes(expirationMonth.rest, 1) IN IF ~expirationDay.ok THEN Fail ELSE
    LET explicitStrikePrice == ReadBytes(expirationDay.rest, 8) IN IF ~explicitStrikePrice.ok THEN Fail ELSE
    LET optionType == ReadBytes(explicitStrikePrice.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET legSide == ReadBytes(optionType.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET legRatio == ReadBytes(legSide.rest, 4) IN IF ~legRatio.ok THEN Fail ELSE
    Ok([ optionId            |-> optionId.value,
         securitySymbol      |-> securitySymbol.value,
         legId               |-> legId.value,
         expirationYear      |-> expirationYear.value,
         expirationMonth     |-> expirationMonth.value,
         expirationDay       |-> expirationDay.value,
         explicitStrikePrice |-> explicitStrikePrice.value,
         optionType          |-> optionType.value,
         legSide             |-> legSide.value,
         legRatio            |-> legRatio.value ], legRatio.rest)

ZeroLegInformation ==
    [ optionId            |-> [i \in 1 .. 4 |-> 0],
      securitySymbol      |-> [i \in 1 .. 6 |-> 0],
      legId               |-> [i \in 1 .. 1 |-> 0],
      expirationYear      |-> [i \in 1 .. 1 |-> 0],
      expirationMonth     |-> [i \in 1 .. 1 |-> 0],
      expirationDay       |-> [i \in 1 .. 1 |-> 0],
      explicitStrikePrice |-> [i \in 1 .. 8 |-> 0],
      optionType          |-> [i \in 1 .. 1 |-> 0],
      legSide             |-> [i \in 1 .. 1 |-> 0],
      legRatio            |-> [i \in 1 .. 4 |-> 0] ]

(* Leg Information at zero, then each field in turn at the values it is checked at *)
CheckedLegInformation ==
    { ZeroLegInformation }
        \cup { [ZeroLegInformation EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroLegInformation EXCEPT !.securitySymbol = one] : one \in Sample(6) }
        \cup { [ZeroLegInformation EXCEPT !.legId = one] : one \in Sample(1) }
        \cup { [ZeroLegInformation EXCEPT !.expirationYear = one] : one \in Sample(1) }
        \cup { [ZeroLegInformation EXCEPT !.expirationMonth = one] : one \in Sample(1) }
        \cup { [ZeroLegInformation EXCEPT !.expirationDay = one] : one \in Sample(1) }
        \cup { [ZeroLegInformation EXCEPT !.explicitStrikePrice = one] : one \in Sample(8) }
        \cup { [ZeroLegInformation EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroLegInformation EXCEPT !.legSide = one] : one \in Sample(1) }
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
    [ timestamp        : Sample(6),
      strategyId       : Sample(4),
      strategyType     : Sample(1),
      source           : Sample(1),
      underlyingSymbol : Sample(13),
      legInformation   : SampleLists(OneLegInformation) ]

EncodeComplexStrategyDirectoryMessage(message) ==
    message.timestamp
        \o message.strategyId
        \o message.strategyType
        \o message.source
        \o message.underlyingSymbol
        \o EncodeUIntLE(Len(message.legInformation), 1)
        \o EncodeLegInformationList(message.legInformation)

DecodeComplexStrategyDirectoryMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET strategyId == ReadBytes(timestamp.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET strategyType == ReadBytes(strategyId.rest, 1) IN IF ~strategyType.ok THEN Fail ELSE
    LET source == ReadBytes(strategyType.rest, 1) IN IF ~source.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(source.rest, 13) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET numberOfLegs == ReadUIntLE(underlyingSymbol.rest, 1) IN IF ~numberOfLegs.ok THEN Fail ELSE
    LET legInformation == ReadLegInformationList(numberOfLegs.rest, numberOfLegs.value) IN IF ~legInformation.ok THEN Fail ELSE
    Ok([ timestamp        |-> timestamp.value,
         strategyId       |-> strategyId.value,
         strategyType     |-> strategyType.value,
         source           |-> source.value,
         underlyingSymbol |-> underlyingSymbol.value,
         legInformation   |-> legInformation.value ], legInformation.rest)

ZeroComplexStrategyDirectoryMessage ==
    [ timestamp        |-> [i \in 1 .. 6 |-> 0],
      strategyId       |-> [i \in 1 .. 4 |-> 0],
      strategyType     |-> [i \in 1 .. 1 |-> 0],
      source           |-> [i \in 1 .. 1 |-> 0],
      underlyingSymbol |-> [i \in 1 .. 13 |-> 0],
      legInformation   |-> << >> ]

(* Complex Strategy Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexStrategyDirectoryMessage ==
    { ZeroComplexStrategyDirectoryMessage }
        \cup { [ZeroComplexStrategyDirectoryMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroComplexStrategyDirectoryMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroComplexStrategyDirectoryMessage EXCEPT !.strategyType = one] : one \in Sample(1) }
        \cup { [ZeroComplexStrategyDirectoryMessage EXCEPT !.source = one] : one \in Sample(1) }
        \cup { [ZeroComplexStrategyDirectoryMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(13) }
        \cup { [ZeroComplexStrategyDirectoryMessage EXCEPT !.legInformation = one] : one \in SampleLists(OneLegInformation) }

(***************************************************************************)
(* Strategy Trading Action Message: 11 bytes                               *)
(***************************************************************************)

StrategyTradingActionMessage ==
    [ timestamp           : Sample(6),
      strategyId          : Sample(4),
      currentTradingState : Sample(1) ]

EncodeStrategyTradingActionMessage(message) ==
    message.timestamp
        \o message.strategyId
        \o message.currentTradingState

DecodeStrategyTradingActionMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET strategyId == ReadBytes(timestamp.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET currentTradingState == ReadBytes(strategyId.rest, 1) IN IF ~currentTradingState.ok THEN Fail ELSE
    Ok([ timestamp           |-> timestamp.value,
         strategyId          |-> strategyId.value,
         currentTradingState |-> currentTradingState.value ], currentTradingState.rest)

ZeroStrategyTradingActionMessage ==
    [ timestamp           |-> [i \in 1 .. 6 |-> 0],
      strategyId          |-> [i \in 1 .. 4 |-> 0],
      currentTradingState |-> [i \in 1 .. 1 |-> 0] ]

(* Strategy Trading Action Message at zero, then each field in turn at the values it is checked at *)
CheckedStrategyTradingActionMessage ==
    { ZeroStrategyTradingActionMessage }
        \cup { [ZeroStrategyTradingActionMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroStrategyTradingActionMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroStrategyTradingActionMessage EXCEPT !.currentTradingState = one] : one \in Sample(1) }

(***************************************************************************)
(* Strategy Open Closed Message: 11 bytes                                  *)
(***************************************************************************)

StrategyOpenClosedMessage ==
    [ timestamp  : Sample(6),
      strategyId : Sample(4),
      openState  : Sample(1) ]

EncodeStrategyOpenClosedMessage(message) ==
    message.timestamp
        \o message.strategyId
        \o message.openState

DecodeStrategyOpenClosedMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET strategyId == ReadBytes(timestamp.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET openState == ReadBytes(strategyId.rest, 1) IN IF ~openState.ok THEN Fail ELSE
    Ok([ timestamp  |-> timestamp.value,
         strategyId |-> strategyId.value,
         openState  |-> openState.value ], openState.rest)

ZeroStrategyOpenClosedMessage ==
    [ timestamp  |-> [i \in 1 .. 6 |-> 0],
      strategyId |-> [i \in 1 .. 4 |-> 0],
      openState  |-> [i \in 1 .. 1 |-> 0] ]

(* Strategy Open Closed Message at zero, then each field in turn at the values it is checked at *)
CheckedStrategyOpenClosedMessage ==
    { ZeroStrategyOpenClosedMessage }
        \cup { [ZeroStrategyOpenClosedMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroStrategyOpenClosedMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroStrategyOpenClosedMessage EXCEPT !.openState = one] : one \in Sample(1) }

(***************************************************************************)
(* Complex Strategy Order On Book Message: 41 bytes                        *)
(***************************************************************************)

ComplexStrategyOrderOnBookMessage ==
    [ timestamp     : Sample(6),
      strategyId    : Sample(4),
      orderType     : Sample(1),
      side          : Sample(1),
      price         : Sample(4),
      size          : Sample(4),
      execFlag      : Sample(1),
      orderCapacity : Sample(1),
      scope         : Sample(1),
      ownerId       : Sample(6),
      giveup        : Sample(6),
      cmta          : Sample(6) ]

EncodeComplexStrategyOrderOnBookMessage(message) ==
    message.timestamp
        \o message.strategyId
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

DecodeComplexStrategyOrderOnBookMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET strategyId == ReadBytes(timestamp.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET orderType == ReadBytes(strategyId.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET side == ReadBytes(orderType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadBytes(side.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET size == ReadBytes(price.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET execFlag == ReadBytes(size.rest, 1) IN IF ~execFlag.ok THEN Fail ELSE
    LET orderCapacity == ReadBytes(execFlag.rest, 1) IN IF ~orderCapacity.ok THEN Fail ELSE
    LET scope == ReadBytes(orderCapacity.rest, 1) IN IF ~scope.ok THEN Fail ELSE
    LET ownerId == ReadBytes(scope.rest, 6) IN IF ~ownerId.ok THEN Fail ELSE
    LET giveup == ReadBytes(ownerId.rest, 6) IN IF ~giveup.ok THEN Fail ELSE
    LET cmta == ReadBytes(giveup.rest, 6) IN IF ~cmta.ok THEN Fail ELSE
    Ok([ timestamp     |-> timestamp.value,
         strategyId    |-> strategyId.value,
         orderType     |-> orderType.value,
         side          |-> side.value,
         price         |-> price.value,
         size          |-> size.value,
         execFlag      |-> execFlag.value,
         orderCapacity |-> orderCapacity.value,
         scope         |-> scope.value,
         ownerId       |-> ownerId.value,
         giveup        |-> giveup.value,
         cmta          |-> cmta.value ], cmta.rest)

ZeroComplexStrategyOrderOnBookMessage ==
    [ timestamp     |-> [i \in 1 .. 6 |-> 0],
      strategyId    |-> [i \in 1 .. 4 |-> 0],
      orderType     |-> [i \in 1 .. 1 |-> 0],
      side          |-> [i \in 1 .. 1 |-> 0],
      price         |-> [i \in 1 .. 4 |-> 0],
      size          |-> [i \in 1 .. 4 |-> 0],
      execFlag      |-> [i \in 1 .. 1 |-> 0],
      orderCapacity |-> [i \in 1 .. 1 |-> 0],
      scope         |-> [i \in 1 .. 1 |-> 0],
      ownerId       |-> [i \in 1 .. 6 |-> 0],
      giveup        |-> [i \in 1 .. 6 |-> 0],
      cmta          |-> [i \in 1 .. 6 |-> 0] ]

(* Complex Strategy Order On Book Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexStrategyOrderOnBookMessage ==
    { ZeroComplexStrategyOrderOnBookMessage }
        \cup { [ZeroComplexStrategyOrderOnBookMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroComplexStrategyOrderOnBookMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroComplexStrategyOrderOnBookMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroComplexStrategyOrderOnBookMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroComplexStrategyOrderOnBookMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroComplexStrategyOrderOnBookMessage EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroComplexStrategyOrderOnBookMessage EXCEPT !.execFlag = one] : one \in Sample(1) }
        \cup { [ZeroComplexStrategyOrderOnBookMessage EXCEPT !.orderCapacity = one] : one \in Sample(1) }
        \cup { [ZeroComplexStrategyOrderOnBookMessage EXCEPT !.scope = one] : one \in Sample(1) }
        \cup { [ZeroComplexStrategyOrderOnBookMessage EXCEPT !.ownerId = one] : one \in Sample(6) }
        \cup { [ZeroComplexStrategyOrderOnBookMessage EXCEPT !.giveup = one] : one \in Sample(6) }
        \cup { [ZeroComplexStrategyOrderOnBookMessage EXCEPT !.cmta = one] : one \in Sample(6) }

(***************************************************************************)
(* Auction Response: 8 bytes                                               *)
(***************************************************************************)

AuctionResponse ==
    [ responsePrice : Sample(4),
      responseSize  : Sample(4) ]

EncodeAuctionResponse(message) ==
    message.responsePrice
        \o message.responseSize

DecodeAuctionResponse(bytes) ==
    LET responsePrice == ReadBytes(bytes, 4) IN IF ~responsePrice.ok THEN Fail ELSE
    LET responseSize == ReadBytes(responsePrice.rest, 4) IN IF ~responseSize.ok THEN Fail ELSE
    Ok([ responsePrice |-> responsePrice.value,
         responseSize  |-> responseSize.value ], responseSize.rest)

ZeroAuctionResponse ==
    [ responsePrice |-> [i \in 1 .. 4 |-> 0],
      responseSize  |-> [i \in 1 .. 4 |-> 0] ]

(* Auction Response at zero, then each field in turn at the values it is checked at *)
CheckedAuctionResponse ==
    { ZeroAuctionResponse }
        \cup { [ZeroAuctionResponse EXCEPT !.responsePrice = one] : one \in Sample(4) }
        \cup { [ZeroAuctionResponse EXCEPT !.responseSize = one] : one \in Sample(4) }

(* A run of Auction Response, written one after another *)
RECURSIVE EncodeAuctionResponseList(_)
EncodeAuctionResponseList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeAuctionResponse(Head(messages)) \o EncodeAuctionResponseList(Tail(messages))

(* As many Auction Response as the field that counts them says *)
RECURSIVE ReadAuctionResponseList(_, _)
ReadAuctionResponseList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeAuctionResponse(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadAuctionResponseList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Auction Response of each kind, for the lists that carry them *)
OneAuctionResponse == { ZeroAuctionResponse }

(***************************************************************************)
(* Complex Strategy Auction Message                                        *)
(***************************************************************************)

ComplexStrategyAuctionMessage ==
    [ timestamp       : Sample(6),
      strategyId      : Sample(4),
      auctionId       : Sample(4),
      orderType       : Sample(1),
      side            : Sample(1),
      price           : Sample(4),
      size            : Sample(4),
      execFlag        : Sample(1),
      orderCapacity   : Sample(1),
      scope           : Sample(1),
      ownerId         : Sample(6),
      giveup          : Sample(6),
      cmta            : Sample(6),
      auctionEvent    : Sample(1),
      auctionType     : Sample(1),
      auctionResponse : SampleLists(OneAuctionResponse) ]

EncodeComplexStrategyAuctionMessage(message) ==
    message.timestamp
        \o message.strategyId
        \o message.auctionId
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
        \o message.auctionEvent
        \o message.auctionType
        \o EncodeUIntLE(Len(message.auctionResponse), 1)
        \o EncodeAuctionResponseList(message.auctionResponse)

DecodeComplexStrategyAuctionMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET strategyId == ReadBytes(timestamp.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET auctionId == ReadBytes(strategyId.rest, 4) IN IF ~auctionId.ok THEN Fail ELSE
    LET orderType == ReadBytes(auctionId.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET side == ReadBytes(orderType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadBytes(side.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET size == ReadBytes(price.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET execFlag == ReadBytes(size.rest, 1) IN IF ~execFlag.ok THEN Fail ELSE
    LET orderCapacity == ReadBytes(execFlag.rest, 1) IN IF ~orderCapacity.ok THEN Fail ELSE
    LET scope == ReadBytes(orderCapacity.rest, 1) IN IF ~scope.ok THEN Fail ELSE
    LET ownerId == ReadBytes(scope.rest, 6) IN IF ~ownerId.ok THEN Fail ELSE
    LET giveup == ReadBytes(ownerId.rest, 6) IN IF ~giveup.ok THEN Fail ELSE
    LET cmta == ReadBytes(giveup.rest, 6) IN IF ~cmta.ok THEN Fail ELSE
    LET auctionEvent == ReadBytes(cmta.rest, 1) IN IF ~auctionEvent.ok THEN Fail ELSE
    LET auctionType == ReadBytes(auctionEvent.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET numberOfResponses == ReadUIntLE(auctionType.rest, 1) IN IF ~numberOfResponses.ok THEN Fail ELSE
    LET auctionResponse == ReadAuctionResponseList(numberOfResponses.rest, numberOfResponses.value) IN IF ~auctionResponse.ok THEN Fail ELSE
    Ok([ timestamp       |-> timestamp.value,
         strategyId      |-> strategyId.value,
         auctionId       |-> auctionId.value,
         orderType       |-> orderType.value,
         side            |-> side.value,
         price           |-> price.value,
         size            |-> size.value,
         execFlag        |-> execFlag.value,
         orderCapacity   |-> orderCapacity.value,
         scope           |-> scope.value,
         ownerId         |-> ownerId.value,
         giveup          |-> giveup.value,
         cmta            |-> cmta.value,
         auctionEvent    |-> auctionEvent.value,
         auctionType     |-> auctionType.value,
         auctionResponse |-> auctionResponse.value ], auctionResponse.rest)

ZeroComplexStrategyAuctionMessage ==
    [ timestamp       |-> [i \in 1 .. 6 |-> 0],
      strategyId      |-> [i \in 1 .. 4 |-> 0],
      auctionId       |-> [i \in 1 .. 4 |-> 0],
      orderType       |-> [i \in 1 .. 1 |-> 0],
      side            |-> [i \in 1 .. 1 |-> 0],
      price           |-> [i \in 1 .. 4 |-> 0],
      size            |-> [i \in 1 .. 4 |-> 0],
      execFlag        |-> [i \in 1 .. 1 |-> 0],
      orderCapacity   |-> [i \in 1 .. 1 |-> 0],
      scope           |-> [i \in 1 .. 1 |-> 0],
      ownerId         |-> [i \in 1 .. 6 |-> 0],
      giveup          |-> [i \in 1 .. 6 |-> 0],
      cmta            |-> [i \in 1 .. 6 |-> 0],
      auctionEvent    |-> [i \in 1 .. 1 |-> 0],
      auctionType     |-> [i \in 1 .. 1 |-> 0],
      auctionResponse |-> << >> ]

(* Complex Strategy Auction Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexStrategyAuctionMessage ==
    { ZeroComplexStrategyAuctionMessage }
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.auctionId = one] : one \in Sample(4) }
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
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.auctionEvent = one] : one \in Sample(1) }
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroComplexStrategyAuctionMessage EXCEPT !.auctionResponse = one] : one \in SampleLists(OneAuctionResponse) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

SystemEventMessageCode == 83  \* "S"
ComplexStrategyDirectoryMessageCode == 82  \* "R"
StrategyTradingActionMessageCode == 72  \* "H"
StrategyOpenClosedMessageCode == 79  \* "O"
ComplexStrategyOrderOnBookMessageCode == 76  \* "L"
ComplexStrategyAuctionMessageCode == 74  \* "J"

Payload ==
    [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {ComplexStrategyDirectoryMessageCode}, body : ComplexStrategyDirectoryMessage ]
        \cup [ tag : {StrategyTradingActionMessageCode}, body : StrategyTradingActionMessage ]
        \cup [ tag : {StrategyOpenClosedMessageCode}, body : StrategyOpenClosedMessage ]
        \cup [ tag : {ComplexStrategyOrderOnBookMessageCode}, body : ComplexStrategyOrderOnBookMessage ]
        \cup [ tag : {ComplexStrategyAuctionMessageCode}, body : ComplexStrategyAuctionMessage ]

EncodePayload(message) ==
    CASE message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = ComplexStrategyDirectoryMessageCode -> EncodeComplexStrategyDirectoryMessage(message.body)
      [] message.tag = StrategyTradingActionMessageCode -> EncodeStrategyTradingActionMessage(message.body)
      [] message.tag = StrategyOpenClosedMessageCode -> EncodeStrategyOpenClosedMessage(message.body)
      [] message.tag = ComplexStrategyOrderOnBookMessageCode -> EncodeComplexStrategyOrderOnBookMessage(message.body)
      [] message.tag = ComplexStrategyAuctionMessageCode -> EncodeComplexStrategyAuctionMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = ComplexStrategyDirectoryMessageCode -> DecodeComplexStrategyDirectoryMessage(bytes)
              [] tag = StrategyTradingActionMessageCode -> DecodeStrategyTradingActionMessage(bytes)
              [] tag = StrategyOpenClosedMessageCode -> DecodeStrategyOpenClosedMessage(bytes)
              [] tag = ComplexStrategyOrderOnBookMessageCode -> DecodeComplexStrategyOrderOnBookMessage(bytes)
              [] tag = ComplexStrategyAuctionMessageCode -> DecodeComplexStrategyAuctionMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> ComplexStrategyDirectoryMessageCode, body |-> one] : one \in CheckedComplexStrategyDirectoryMessage }
        \cup { [tag |-> StrategyTradingActionMessageCode, body |-> one] : one \in CheckedStrategyTradingActionMessage }
        \cup { [tag |-> StrategyOpenClosedMessageCode, body |-> one] : one \in CheckedStrategyOpenClosedMessage }
        \cup { [tag |-> ComplexStrategyOrderOnBookMessageCode, body |-> one] : one \in CheckedComplexStrategyOrderOnBookMessage }
        \cup { [tag |-> ComplexStrategyAuctionMessageCode, body |-> one] : one \in CheckedComplexStrategyAuctionMessage }

(***************************************************************************)
(* Message, framed by Message Length                                       *)
(***************************************************************************)

Message ==
    [ payload : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntLE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntLE(Len(body), 2) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntLE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroMessage ==
    [ payload |-> ZeroPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.payload = one] : one \in CheckedPayload }

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
    { [ZeroMessage EXCEPT !.payload = [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ComplexStrategyDirectoryMessageCode, body |-> ZeroComplexStrategyDirectoryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StrategyTradingActionMessageCode, body |-> ZeroStrategyTradingActionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StrategyOpenClosedMessageCode, body |-> ZeroStrategyOpenClosedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ComplexStrategyOrderOnBookMessageCode, body |-> ZeroComplexStrategyOrderOnBookMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ComplexStrategyAuctionMessageCode, body |-> ZeroComplexStrategyAuctionMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ session        : Sample(10),
      sequenceNumber : Sample(8),
      message        : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.session
        \o message.sequenceNumber
        \o EncodeUIntLE(Len(message.message), 2)
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET session == ReadBytes(bytes, 10) IN IF ~session.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(session.rest, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET messageCount == ReadUIntLE(sequenceNumber.rest, 2) IN IF ~messageCount.ok THEN Fail ELSE
    LET message == ReadMessageList(messageCount.rest, messageCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ session        |-> session.value,
         sequenceNumber |-> sequenceNumber.value,
         message        |-> message.value ], message.rest)

ZeroPacket ==
    [ session        |-> [i \in 1 .. 10 |-> 0],
      sequenceNumber |-> [i \in 1 .. 8 |-> 0],
      message        |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.session = one] : one \in Sample(10) }
        \cup { [ZeroPacket EXCEPT !.sequenceNumber = one] : one \in Sample(8) }
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

(* Every Strategy Open Closed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyOpenClosedMessage ==
    \A message \in CheckedStrategyOpenClosedMessage :
        LET read == DecodeStrategyOpenClosedMessage(EncodeStrategyOpenClosedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Strategy Order On Book Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexStrategyOrderOnBookMessage ==
    \A message \in CheckedComplexStrategyOrderOnBookMessage :
        LET read == DecodeComplexStrategyOrderOnBookMessage(EncodeComplexStrategyOrderOnBookMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Response decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionResponse ==
    \A message \in CheckedAuctionResponse :
        LET read == DecodeAuctionResponse(EncodeAuctionResponse(message))
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

(* A Payload is selected by the Message Type it is written under *)
SelectsPayload ==
    \A message \in Payload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
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
