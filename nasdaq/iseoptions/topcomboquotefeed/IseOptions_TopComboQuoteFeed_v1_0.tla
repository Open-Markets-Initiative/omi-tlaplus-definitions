----------------- MODULE IseOptions_TopComboQuoteFeed_v1_0 -----------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Ise Top Combo Quote Feed v1.0                                  *)
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
      side                : Sample(1),
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
        \o message.side
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
    LET side == ReadBytes(optionType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET legRatio == ReadBytes(side.rest, 4) IN IF ~legRatio.ok THEN Fail ELSE
    Ok([ optionId            |-> optionId.value,
         securitySymbol      |-> securitySymbol.value,
         legId               |-> legId.value,
         expirationYear      |-> expirationYear.value,
         expirationMonth     |-> expirationMonth.value,
         expirationDay       |-> expirationDay.value,
         explicitStrikePrice |-> explicitStrikePrice.value,
         optionType          |-> optionType.value,
         side                |-> side.value,
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
      side                |-> [i \in 1 .. 1 |-> 0],
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
        \o EncodeUIntBE(Len(message.legInformation), 1)
        \o EncodeLegInformationList(message.legInformation)

DecodeComplexStrategyDirectoryMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET strategyId == ReadBytes(timestamp.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET strategyType == ReadBytes(strategyId.rest, 1) IN IF ~strategyType.ok THEN Fail ELSE
    LET source == ReadBytes(strategyType.rest, 1) IN IF ~source.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(source.rest, 13) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET numberOfLegs == ReadUIntBE(underlyingSymbol.rest, 1) IN IF ~numberOfLegs.ok THEN Fail ELSE
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
(* Strategy Best Bid And Ask Update: 67 bytes                              *)
(***************************************************************************)

StrategyBestBidAndAskUpdate ==
    [ timestamp        : Sample(6),
      strategyId       : Sample(4),
      quoteCondition   : Sample(1),
      bidPrice         : Sample(4),
      bidSize          : Sample(4),
      bidCustSize      : Sample(4),
      bidProCustSize   : Sample(4),
      bidNttSize       : Sample(4),
      bidMarketSize    : Sample(4),
      bidNttMarketSize : Sample(4),
      askPrice         : Sample(4),
      askSize          : Sample(4),
      askCustSize      : Sample(4),
      askProCustSize   : Sample(4),
      askNttSize       : Sample(4),
      askMarketSize    : Sample(4),
      askNttMarketSize : Sample(4) ]

EncodeStrategyBestBidAndAskUpdate(message) ==
    message.timestamp
        \o message.strategyId
        \o message.quoteCondition
        \o message.bidPrice
        \o message.bidSize
        \o message.bidCustSize
        \o message.bidProCustSize
        \o message.bidNttSize
        \o message.bidMarketSize
        \o message.bidNttMarketSize
        \o message.askPrice
        \o message.askSize
        \o message.askCustSize
        \o message.askProCustSize
        \o message.askNttSize
        \o message.askMarketSize
        \o message.askNttMarketSize

DecodeStrategyBestBidAndAskUpdate(bytes) ==
    LET timestamp == ReadBytes(bytes, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET strategyId == ReadBytes(timestamp.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(strategyId.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(quoteCondition.rest, 4) IN IF ~bidPrice.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPrice.rest, 4) IN IF ~bidSize.ok THEN Fail ELSE
    LET bidCustSize == ReadBytes(bidSize.rest, 4) IN IF ~bidCustSize.ok THEN Fail ELSE
    LET bidProCustSize == ReadBytes(bidCustSize.rest, 4) IN IF ~bidProCustSize.ok THEN Fail ELSE
    LET bidNttSize == ReadBytes(bidProCustSize.rest, 4) IN IF ~bidNttSize.ok THEN Fail ELSE
    LET bidMarketSize == ReadBytes(bidNttSize.rest, 4) IN IF ~bidMarketSize.ok THEN Fail ELSE
    LET bidNttMarketSize == ReadBytes(bidMarketSize.rest, 4) IN IF ~bidNttMarketSize.ok THEN Fail ELSE
    LET askPrice == ReadBytes(bidNttMarketSize.rest, 4) IN IF ~askPrice.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPrice.rest, 4) IN IF ~askSize.ok THEN Fail ELSE
    LET askCustSize == ReadBytes(askSize.rest, 4) IN IF ~askCustSize.ok THEN Fail ELSE
    LET askProCustSize == ReadBytes(askCustSize.rest, 4) IN IF ~askProCustSize.ok THEN Fail ELSE
    LET askNttSize == ReadBytes(askProCustSize.rest, 4) IN IF ~askNttSize.ok THEN Fail ELSE
    LET askMarketSize == ReadBytes(askNttSize.rest, 4) IN IF ~askMarketSize.ok THEN Fail ELSE
    LET askNttMarketSize == ReadBytes(askMarketSize.rest, 4) IN IF ~askNttMarketSize.ok THEN Fail ELSE
    Ok([ timestamp        |-> timestamp.value,
         strategyId       |-> strategyId.value,
         quoteCondition   |-> quoteCondition.value,
         bidPrice         |-> bidPrice.value,
         bidSize          |-> bidSize.value,
         bidCustSize      |-> bidCustSize.value,
         bidProCustSize   |-> bidProCustSize.value,
         bidNttSize       |-> bidNttSize.value,
         bidMarketSize    |-> bidMarketSize.value,
         bidNttMarketSize |-> bidNttMarketSize.value,
         askPrice         |-> askPrice.value,
         askSize          |-> askSize.value,
         askCustSize      |-> askCustSize.value,
         askProCustSize   |-> askProCustSize.value,
         askNttSize       |-> askNttSize.value,
         askMarketSize    |-> askMarketSize.value,
         askNttMarketSize |-> askNttMarketSize.value ], askNttMarketSize.rest)

ZeroStrategyBestBidAndAskUpdate ==
    [ timestamp        |-> [i \in 1 .. 6 |-> 0],
      strategyId       |-> [i \in 1 .. 4 |-> 0],
      quoteCondition   |-> [i \in 1 .. 1 |-> 0],
      bidPrice         |-> [i \in 1 .. 4 |-> 0],
      bidSize          |-> [i \in 1 .. 4 |-> 0],
      bidCustSize      |-> [i \in 1 .. 4 |-> 0],
      bidProCustSize   |-> [i \in 1 .. 4 |-> 0],
      bidNttSize       |-> [i \in 1 .. 4 |-> 0],
      bidMarketSize    |-> [i \in 1 .. 4 |-> 0],
      bidNttMarketSize |-> [i \in 1 .. 4 |-> 0],
      askPrice         |-> [i \in 1 .. 4 |-> 0],
      askSize          |-> [i \in 1 .. 4 |-> 0],
      askCustSize      |-> [i \in 1 .. 4 |-> 0],
      askProCustSize   |-> [i \in 1 .. 4 |-> 0],
      askNttSize       |-> [i \in 1 .. 4 |-> 0],
      askMarketSize    |-> [i \in 1 .. 4 |-> 0],
      askNttMarketSize |-> [i \in 1 .. 4 |-> 0] ]

(* Strategy Best Bid And Ask Update at zero, then each field in turn at the values it is checked at *)
CheckedStrategyBestBidAndAskUpdate ==
    { ZeroStrategyBestBidAndAskUpdate }
        \cup { [ZeroStrategyBestBidAndAskUpdate EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroStrategyBestBidAndAskUpdate EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestBidAndAskUpdate EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroStrategyBestBidAndAskUpdate EXCEPT !.bidPrice = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestBidAndAskUpdate EXCEPT !.bidSize = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestBidAndAskUpdate EXCEPT !.bidCustSize = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestBidAndAskUpdate EXCEPT !.bidProCustSize = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestBidAndAskUpdate EXCEPT !.bidNttSize = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestBidAndAskUpdate EXCEPT !.bidMarketSize = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestBidAndAskUpdate EXCEPT !.bidNttMarketSize = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestBidAndAskUpdate EXCEPT !.askPrice = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestBidAndAskUpdate EXCEPT !.askSize = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestBidAndAskUpdate EXCEPT !.askCustSize = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestBidAndAskUpdate EXCEPT !.askProCustSize = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestBidAndAskUpdate EXCEPT !.askNttSize = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestBidAndAskUpdate EXCEPT !.askMarketSize = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestBidAndAskUpdate EXCEPT !.askNttMarketSize = one] : one \in Sample(4) }

(***************************************************************************)
(* Strategy Best Bid Update: 39 bytes                                      *)
(***************************************************************************)

StrategyBestBidUpdate ==
    [ timestamp      : Sample(6),
      strategyId     : Sample(4),
      quoteCondition : Sample(1),
      price          : Sample(4),
      size           : Sample(4),
      custSize       : Sample(4),
      proCustSize    : Sample(4),
      nttSize        : Sample(4),
      marketSize     : Sample(4),
      nttMarketSize  : Sample(4) ]

EncodeStrategyBestBidUpdate(message) ==
    message.timestamp
        \o message.strategyId
        \o message.quoteCondition
        \o message.price
        \o message.size
        \o message.custSize
        \o message.proCustSize
        \o message.nttSize
        \o message.marketSize
        \o message.nttMarketSize

DecodeStrategyBestBidUpdate(bytes) ==
    LET timestamp == ReadBytes(bytes, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET strategyId == ReadBytes(timestamp.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(strategyId.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET price == ReadBytes(quoteCondition.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET size == ReadBytes(price.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET custSize == ReadBytes(size.rest, 4) IN IF ~custSize.ok THEN Fail ELSE
    LET proCustSize == ReadBytes(custSize.rest, 4) IN IF ~proCustSize.ok THEN Fail ELSE
    LET nttSize == ReadBytes(proCustSize.rest, 4) IN IF ~nttSize.ok THEN Fail ELSE
    LET marketSize == ReadBytes(nttSize.rest, 4) IN IF ~marketSize.ok THEN Fail ELSE
    LET nttMarketSize == ReadBytes(marketSize.rest, 4) IN IF ~nttMarketSize.ok THEN Fail ELSE
    Ok([ timestamp      |-> timestamp.value,
         strategyId     |-> strategyId.value,
         quoteCondition |-> quoteCondition.value,
         price          |-> price.value,
         size           |-> size.value,
         custSize       |-> custSize.value,
         proCustSize    |-> proCustSize.value,
         nttSize        |-> nttSize.value,
         marketSize     |-> marketSize.value,
         nttMarketSize  |-> nttMarketSize.value ], nttMarketSize.rest)

ZeroStrategyBestBidUpdate ==
    [ timestamp      |-> [i \in 1 .. 6 |-> 0],
      strategyId     |-> [i \in 1 .. 4 |-> 0],
      quoteCondition |-> [i \in 1 .. 1 |-> 0],
      price          |-> [i \in 1 .. 4 |-> 0],
      size           |-> [i \in 1 .. 4 |-> 0],
      custSize       |-> [i \in 1 .. 4 |-> 0],
      proCustSize    |-> [i \in 1 .. 4 |-> 0],
      nttSize        |-> [i \in 1 .. 4 |-> 0],
      marketSize     |-> [i \in 1 .. 4 |-> 0],
      nttMarketSize  |-> [i \in 1 .. 4 |-> 0] ]

(* Strategy Best Bid Update at zero, then each field in turn at the values it is checked at *)
CheckedStrategyBestBidUpdate ==
    { ZeroStrategyBestBidUpdate }
        \cup { [ZeroStrategyBestBidUpdate EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroStrategyBestBidUpdate EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestBidUpdate EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroStrategyBestBidUpdate EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestBidUpdate EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestBidUpdate EXCEPT !.custSize = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestBidUpdate EXCEPT !.proCustSize = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestBidUpdate EXCEPT !.nttSize = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestBidUpdate EXCEPT !.marketSize = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestBidUpdate EXCEPT !.nttMarketSize = one] : one \in Sample(4) }

(***************************************************************************)
(* Strategy Best Ask Update: 39 bytes                                      *)
(***************************************************************************)

StrategyBestAskUpdate ==
    [ timestamp      : Sample(6),
      strategyId     : Sample(4),
      quoteCondition : Sample(1),
      price          : Sample(4),
      size           : Sample(4),
      custSize       : Sample(4),
      proCustSize    : Sample(4),
      nttSize        : Sample(4),
      marketSize     : Sample(4),
      nttMarketSize  : Sample(4) ]

EncodeStrategyBestAskUpdate(message) ==
    message.timestamp
        \o message.strategyId
        \o message.quoteCondition
        \o message.price
        \o message.size
        \o message.custSize
        \o message.proCustSize
        \o message.nttSize
        \o message.marketSize
        \o message.nttMarketSize

DecodeStrategyBestAskUpdate(bytes) ==
    LET timestamp == ReadBytes(bytes, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET strategyId == ReadBytes(timestamp.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(strategyId.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET price == ReadBytes(quoteCondition.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET size == ReadBytes(price.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET custSize == ReadBytes(size.rest, 4) IN IF ~custSize.ok THEN Fail ELSE
    LET proCustSize == ReadBytes(custSize.rest, 4) IN IF ~proCustSize.ok THEN Fail ELSE
    LET nttSize == ReadBytes(proCustSize.rest, 4) IN IF ~nttSize.ok THEN Fail ELSE
    LET marketSize == ReadBytes(nttSize.rest, 4) IN IF ~marketSize.ok THEN Fail ELSE
    LET nttMarketSize == ReadBytes(marketSize.rest, 4) IN IF ~nttMarketSize.ok THEN Fail ELSE
    Ok([ timestamp      |-> timestamp.value,
         strategyId     |-> strategyId.value,
         quoteCondition |-> quoteCondition.value,
         price          |-> price.value,
         size           |-> size.value,
         custSize       |-> custSize.value,
         proCustSize    |-> proCustSize.value,
         nttSize        |-> nttSize.value,
         marketSize     |-> marketSize.value,
         nttMarketSize  |-> nttMarketSize.value ], nttMarketSize.rest)

ZeroStrategyBestAskUpdate ==
    [ timestamp      |-> [i \in 1 .. 6 |-> 0],
      strategyId     |-> [i \in 1 .. 4 |-> 0],
      quoteCondition |-> [i \in 1 .. 1 |-> 0],
      price          |-> [i \in 1 .. 4 |-> 0],
      size           |-> [i \in 1 .. 4 |-> 0],
      custSize       |-> [i \in 1 .. 4 |-> 0],
      proCustSize    |-> [i \in 1 .. 4 |-> 0],
      nttSize        |-> [i \in 1 .. 4 |-> 0],
      marketSize     |-> [i \in 1 .. 4 |-> 0],
      nttMarketSize  |-> [i \in 1 .. 4 |-> 0] ]

(* Strategy Best Ask Update at zero, then each field in turn at the values it is checked at *)
CheckedStrategyBestAskUpdate ==
    { ZeroStrategyBestAskUpdate }
        \cup { [ZeroStrategyBestAskUpdate EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroStrategyBestAskUpdate EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestAskUpdate EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroStrategyBestAskUpdate EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestAskUpdate EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestAskUpdate EXCEPT !.custSize = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestAskUpdate EXCEPT !.proCustSize = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestAskUpdate EXCEPT !.nttSize = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestAskUpdate EXCEPT !.marketSize = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestAskUpdate EXCEPT !.nttMarketSize = one] : one \in Sample(4) }

(***************************************************************************)
(* Complex Strategy Ticker Message: 51 bytes                               *)
(***************************************************************************)

ComplexStrategyTickerMessage ==
    [ timestamp      : Sample(6),
      strategyId     : Sample(4),
      lastPrice      : Sample(8),
      size           : Sample(4),
      volume         : Sample(4),
      high           : Sample(8),
      low            : Sample(8),
      first          : Sample(8),
      tradeCondition : Sample(1) ]

EncodeComplexStrategyTickerMessage(message) ==
    message.timestamp
        \o message.strategyId
        \o message.lastPrice
        \o message.size
        \o message.volume
        \o message.high
        \o message.low
        \o message.first
        \o message.tradeCondition

DecodeComplexStrategyTickerMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET strategyId == ReadBytes(timestamp.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(strategyId.rest, 8) IN IF ~lastPrice.ok THEN Fail ELSE
    LET size == ReadBytes(lastPrice.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET volume == ReadBytes(size.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET high == ReadBytes(volume.rest, 8) IN IF ~high.ok THEN Fail ELSE
    LET low == ReadBytes(high.rest, 8) IN IF ~low.ok THEN Fail ELSE
    LET first == ReadBytes(low.rest, 8) IN IF ~first.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(first.rest, 1) IN IF ~tradeCondition.ok THEN Fail ELSE
    Ok([ timestamp      |-> timestamp.value,
         strategyId     |-> strategyId.value,
         lastPrice      |-> lastPrice.value,
         size           |-> size.value,
         volume         |-> volume.value,
         high           |-> high.value,
         low            |-> low.value,
         first          |-> first.value,
         tradeCondition |-> tradeCondition.value ], tradeCondition.rest)

ZeroComplexStrategyTickerMessage ==
    [ timestamp      |-> [i \in 1 .. 6 |-> 0],
      strategyId     |-> [i \in 1 .. 4 |-> 0],
      lastPrice      |-> [i \in 1 .. 8 |-> 0],
      size           |-> [i \in 1 .. 4 |-> 0],
      volume         |-> [i \in 1 .. 4 |-> 0],
      high           |-> [i \in 1 .. 8 |-> 0],
      low            |-> [i \in 1 .. 8 |-> 0],
      first          |-> [i \in 1 .. 8 |-> 0],
      tradeCondition |-> [i \in 1 .. 1 |-> 0] ]

(* Complex Strategy Ticker Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexStrategyTickerMessage ==
    { ZeroComplexStrategyTickerMessage }
        \cup { [ZeroComplexStrategyTickerMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroComplexStrategyTickerMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroComplexStrategyTickerMessage EXCEPT !.lastPrice = one] : one \in Sample(8) }
        \cup { [ZeroComplexStrategyTickerMessage EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroComplexStrategyTickerMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroComplexStrategyTickerMessage EXCEPT !.high = one] : one \in Sample(8) }
        \cup { [ZeroComplexStrategyTickerMessage EXCEPT !.low = one] : one \in Sample(8) }
        \cup { [ZeroComplexStrategyTickerMessage EXCEPT !.first = one] : one \in Sample(8) }
        \cup { [ZeroComplexStrategyTickerMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

SystemEventMessageCode == 83  \* "S"
ComplexStrategyDirectoryMessageCode == 82  \* "R"
StrategyOpenClosedMessageCode == 79  \* "O"
StrategyTradingActionMessageCode == 72  \* "H"
StrategyBestBidAndAskUpdateCode == 67  \* "C"
StrategyBestBidUpdateCode == 68  \* "D"
StrategyBestAskUpdateCode == 69  \* "E"
ComplexStrategyTickerMessageCode == 116  \* "t"

Payload ==
    [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {ComplexStrategyDirectoryMessageCode}, body : ComplexStrategyDirectoryMessage ]
        \cup [ tag : {StrategyOpenClosedMessageCode}, body : StrategyOpenClosedMessage ]
        \cup [ tag : {StrategyTradingActionMessageCode}, body : StrategyTradingActionMessage ]
        \cup [ tag : {StrategyBestBidAndAskUpdateCode}, body : StrategyBestBidAndAskUpdate ]
        \cup [ tag : {StrategyBestBidUpdateCode}, body : StrategyBestBidUpdate ]
        \cup [ tag : {StrategyBestAskUpdateCode}, body : StrategyBestAskUpdate ]
        \cup [ tag : {ComplexStrategyTickerMessageCode}, body : ComplexStrategyTickerMessage ]

EncodePayload(message) ==
    CASE message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = ComplexStrategyDirectoryMessageCode -> EncodeComplexStrategyDirectoryMessage(message.body)
      [] message.tag = StrategyOpenClosedMessageCode -> EncodeStrategyOpenClosedMessage(message.body)
      [] message.tag = StrategyTradingActionMessageCode -> EncodeStrategyTradingActionMessage(message.body)
      [] message.tag = StrategyBestBidAndAskUpdateCode -> EncodeStrategyBestBidAndAskUpdate(message.body)
      [] message.tag = StrategyBestBidUpdateCode -> EncodeStrategyBestBidUpdate(message.body)
      [] message.tag = StrategyBestAskUpdateCode -> EncodeStrategyBestAskUpdate(message.body)
      [] message.tag = ComplexStrategyTickerMessageCode -> EncodeComplexStrategyTickerMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = ComplexStrategyDirectoryMessageCode -> DecodeComplexStrategyDirectoryMessage(bytes)
              [] tag = StrategyOpenClosedMessageCode -> DecodeStrategyOpenClosedMessage(bytes)
              [] tag = StrategyTradingActionMessageCode -> DecodeStrategyTradingActionMessage(bytes)
              [] tag = StrategyBestBidAndAskUpdateCode -> DecodeStrategyBestBidAndAskUpdate(bytes)
              [] tag = StrategyBestBidUpdateCode -> DecodeStrategyBestBidUpdate(bytes)
              [] tag = StrategyBestAskUpdateCode -> DecodeStrategyBestAskUpdate(bytes)
              [] tag = ComplexStrategyTickerMessageCode -> DecodeComplexStrategyTickerMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> ComplexStrategyDirectoryMessageCode, body |-> one] : one \in CheckedComplexStrategyDirectoryMessage }
        \cup { [tag |-> StrategyOpenClosedMessageCode, body |-> one] : one \in CheckedStrategyOpenClosedMessage }
        \cup { [tag |-> StrategyTradingActionMessageCode, body |-> one] : one \in CheckedStrategyTradingActionMessage }
        \cup { [tag |-> StrategyBestBidAndAskUpdateCode, body |-> one] : one \in CheckedStrategyBestBidAndAskUpdate }
        \cup { [tag |-> StrategyBestBidUpdateCode, body |-> one] : one \in CheckedStrategyBestBidUpdate }
        \cup { [tag |-> StrategyBestAskUpdateCode, body |-> one] : one \in CheckedStrategyBestAskUpdate }
        \cup { [tag |-> ComplexStrategyTickerMessageCode, body |-> one] : one \in CheckedComplexStrategyTickerMessage }

(***************************************************************************)
(* Message, framed by Message Length                                       *)
(***************************************************************************)

Message ==
    [ payload : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntBE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
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
      [ZeroMessage EXCEPT !.payload = [tag |-> StrategyOpenClosedMessageCode, body |-> ZeroStrategyOpenClosedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StrategyTradingActionMessageCode, body |-> ZeroStrategyTradingActionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StrategyBestBidAndAskUpdateCode, body |-> ZeroStrategyBestBidAndAskUpdate]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StrategyBestBidUpdateCode, body |-> ZeroStrategyBestBidUpdate]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StrategyBestAskUpdateCode, body |-> ZeroStrategyBestAskUpdate]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ComplexStrategyTickerMessageCode, body |-> ZeroComplexStrategyTickerMessage]] }

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
        \o EncodeUIntBE(Len(message.message), 2)
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET session == ReadBytes(bytes, 10) IN IF ~session.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(session.rest, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET messageCount == ReadUIntBE(sequenceNumber.rest, 2) IN IF ~messageCount.ok THEN Fail ELSE
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
                /\ Len(EncodeUIntBE(value, width)) = width
                /\ DecodeUIntBE(EncodeUIntBE(value, width)) = value
                /\ \A i \in 1 .. width : EncodeUIntLE(value, width)[i] \in Byte
                /\ \A i \in 1 .. width : EncodeUIntBE(value, width)[i] \in Byte

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

(* Every Strategy Open Closed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyOpenClosedMessage ==
    \A message \in CheckedStrategyOpenClosedMessage :
        LET read == DecodeStrategyOpenClosedMessage(EncodeStrategyOpenClosedMessage(message))
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

(* Every Strategy Best Bid And Ask Update decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyBestBidAndAskUpdate ==
    \A message \in CheckedStrategyBestBidAndAskUpdate :
        LET read == DecodeStrategyBestBidAndAskUpdate(EncodeStrategyBestBidAndAskUpdate(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Best Bid Update decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyBestBidUpdate ==
    \A message \in CheckedStrategyBestBidUpdate :
        LET read == DecodeStrategyBestBidUpdate(EncodeStrategyBestBidUpdate(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Best Ask Update decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyBestAskUpdate ==
    \A message \in CheckedStrategyBestAskUpdate :
        LET read == DecodeStrategyBestAskUpdate(EncodeStrategyBestAskUpdate(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Strategy Ticker Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexStrategyTickerMessage ==
    \A message \in CheckedComplexStrategyTickerMessage :
        LET read == DecodeComplexStrategyTickerMessage(EncodeComplexStrategyTickerMessage(message))
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
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Message Length is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
