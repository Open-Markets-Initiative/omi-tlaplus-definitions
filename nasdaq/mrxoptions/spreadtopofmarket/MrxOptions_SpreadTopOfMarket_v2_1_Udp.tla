--------------- MODULE MrxOptions_SpreadTopOfMarket_v2_1_Udp ---------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Phlx Options Spread Top Of Market v2.1                         *)
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
        \o EncodeUIntBE(Len(message.legInformation), 1)
        \o EncodeLegInformationList(message.legInformation)

DecodeComplexStrategyDirectoryMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET strategyId == ReadBytes(timestamp.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET strategyType == ReadBytes(strategyId.rest, 1) IN IF ~strategyType.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(strategyType.rest, 13) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET reserved16 == ReadBytes(underlyingSymbol.rest, 16) IN IF ~reserved16.ok THEN Fail ELSE
    LET numberOfLegs == ReadUIntBE(reserved16.rest, 1) IN IF ~numberOfLegs.ok THEN Fail ELSE
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
(* Strategy Best Bid And Ask Update Message: 71 bytes                      *)
(***************************************************************************)

StrategyBestBidAndAskUpdateMessage ==
    [ trackingNumber    : Sample(2),
      timestamp         : Sample(8),
      strategyId        : Sample(4),
      quoteCondition    : Sample(1),
      bidMarketSize     : Sample(4),
      bidPrice          : Sample(4),
      bidSize           : Sample(4),
      bidCustSize       : Sample(4),
      bidProCustSize    : Sample(4),
      bidDnttSize       : Sample(4),
      bidDnttMarketSize : Sample(4),
      askMarketSize     : Sample(4),
      askPrice          : Sample(4),
      askSize           : Sample(4),
      askCustSize       : Sample(4),
      askProCustSize    : Sample(4),
      askDnttSize       : Sample(4),
      askDnttMarketSize : Sample(4) ]

EncodeStrategyBestBidAndAskUpdateMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.strategyId
        \o message.quoteCondition
        \o message.bidMarketSize
        \o message.bidPrice
        \o message.bidSize
        \o message.bidCustSize
        \o message.bidProCustSize
        \o message.bidDnttSize
        \o message.bidDnttMarketSize
        \o message.askMarketSize
        \o message.askPrice
        \o message.askSize
        \o message.askCustSize
        \o message.askProCustSize
        \o message.askDnttSize
        \o message.askDnttMarketSize

DecodeStrategyBestBidAndAskUpdateMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET strategyId == ReadBytes(timestamp.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(strategyId.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET bidMarketSize == ReadBytes(quoteCondition.rest, 4) IN IF ~bidMarketSize.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(bidMarketSize.rest, 4) IN IF ~bidPrice.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPrice.rest, 4) IN IF ~bidSize.ok THEN Fail ELSE
    LET bidCustSize == ReadBytes(bidSize.rest, 4) IN IF ~bidCustSize.ok THEN Fail ELSE
    LET bidProCustSize == ReadBytes(bidCustSize.rest, 4) IN IF ~bidProCustSize.ok THEN Fail ELSE
    LET bidDnttSize == ReadBytes(bidProCustSize.rest, 4) IN IF ~bidDnttSize.ok THEN Fail ELSE
    LET bidDnttMarketSize == ReadBytes(bidDnttSize.rest, 4) IN IF ~bidDnttMarketSize.ok THEN Fail ELSE
    LET askMarketSize == ReadBytes(bidDnttMarketSize.rest, 4) IN IF ~askMarketSize.ok THEN Fail ELSE
    LET askPrice == ReadBytes(askMarketSize.rest, 4) IN IF ~askPrice.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPrice.rest, 4) IN IF ~askSize.ok THEN Fail ELSE
    LET askCustSize == ReadBytes(askSize.rest, 4) IN IF ~askCustSize.ok THEN Fail ELSE
    LET askProCustSize == ReadBytes(askCustSize.rest, 4) IN IF ~askProCustSize.ok THEN Fail ELSE
    LET askDnttSize == ReadBytes(askProCustSize.rest, 4) IN IF ~askDnttSize.ok THEN Fail ELSE
    LET askDnttMarketSize == ReadBytes(askDnttSize.rest, 4) IN IF ~askDnttMarketSize.ok THEN Fail ELSE
    Ok([ trackingNumber    |-> trackingNumber.value,
         timestamp         |-> timestamp.value,
         strategyId        |-> strategyId.value,
         quoteCondition    |-> quoteCondition.value,
         bidMarketSize     |-> bidMarketSize.value,
         bidPrice          |-> bidPrice.value,
         bidSize           |-> bidSize.value,
         bidCustSize       |-> bidCustSize.value,
         bidProCustSize    |-> bidProCustSize.value,
         bidDnttSize       |-> bidDnttSize.value,
         bidDnttMarketSize |-> bidDnttMarketSize.value,
         askMarketSize     |-> askMarketSize.value,
         askPrice          |-> askPrice.value,
         askSize           |-> askSize.value,
         askCustSize       |-> askCustSize.value,
         askProCustSize    |-> askProCustSize.value,
         askDnttSize       |-> askDnttSize.value,
         askDnttMarketSize |-> askDnttMarketSize.value ], askDnttMarketSize.rest)

ZeroStrategyBestBidAndAskUpdateMessage ==
    [ trackingNumber    |-> [i \in 1 .. 2 |-> 0],
      timestamp         |-> [i \in 1 .. 8 |-> 0],
      strategyId        |-> [i \in 1 .. 4 |-> 0],
      quoteCondition    |-> [i \in 1 .. 1 |-> 0],
      bidMarketSize     |-> [i \in 1 .. 4 |-> 0],
      bidPrice          |-> [i \in 1 .. 4 |-> 0],
      bidSize           |-> [i \in 1 .. 4 |-> 0],
      bidCustSize       |-> [i \in 1 .. 4 |-> 0],
      bidProCustSize    |-> [i \in 1 .. 4 |-> 0],
      bidDnttSize       |-> [i \in 1 .. 4 |-> 0],
      bidDnttMarketSize |-> [i \in 1 .. 4 |-> 0],
      askMarketSize     |-> [i \in 1 .. 4 |-> 0],
      askPrice          |-> [i \in 1 .. 4 |-> 0],
      askSize           |-> [i \in 1 .. 4 |-> 0],
      askCustSize       |-> [i \in 1 .. 4 |-> 0],
      askProCustSize    |-> [i \in 1 .. 4 |-> 0],
      askDnttSize       |-> [i \in 1 .. 4 |-> 0],
      askDnttMarketSize |-> [i \in 1 .. 4 |-> 0] ]

(* Strategy Best Bid And Ask Update Message at zero, then each field in turn at the values it is checked at *)
CheckedStrategyBestBidAndAskUpdateMessage ==
    { ZeroStrategyBestBidAndAskUpdateMessage }
        \cup { [ZeroStrategyBestBidAndAskUpdateMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroStrategyBestBidAndAskUpdateMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroStrategyBestBidAndAskUpdateMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestBidAndAskUpdateMessage EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroStrategyBestBidAndAskUpdateMessage EXCEPT !.bidMarketSize = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestBidAndAskUpdateMessage EXCEPT !.bidPrice = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestBidAndAskUpdateMessage EXCEPT !.bidSize = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestBidAndAskUpdateMessage EXCEPT !.bidCustSize = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestBidAndAskUpdateMessage EXCEPT !.bidProCustSize = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestBidAndAskUpdateMessage EXCEPT !.bidDnttSize = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestBidAndAskUpdateMessage EXCEPT !.bidDnttMarketSize = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestBidAndAskUpdateMessage EXCEPT !.askMarketSize = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestBidAndAskUpdateMessage EXCEPT !.askPrice = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestBidAndAskUpdateMessage EXCEPT !.askSize = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestBidAndAskUpdateMessage EXCEPT !.askCustSize = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestBidAndAskUpdateMessage EXCEPT !.askProCustSize = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestBidAndAskUpdateMessage EXCEPT !.askDnttSize = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestBidAndAskUpdateMessage EXCEPT !.askDnttMarketSize = one] : one \in Sample(4) }

(***************************************************************************)
(* Strategy Best Bid Update Message: 43 bytes                              *)
(***************************************************************************)

StrategyBestBidUpdateMessage ==
    [ trackingNumber : Sample(2),
      timestamp      : Sample(8),
      strategyId     : Sample(4),
      quoteCondition : Sample(1),
      marketSize     : Sample(4),
      price          : Sample(4),
      size           : Sample(4),
      custSize       : Sample(4),
      proCustSize    : Sample(4),
      dnttSize       : Sample(4),
      dnttMarketSize : Sample(4) ]

EncodeStrategyBestBidUpdateMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.strategyId
        \o message.quoteCondition
        \o message.marketSize
        \o message.price
        \o message.size
        \o message.custSize
        \o message.proCustSize
        \o message.dnttSize
        \o message.dnttMarketSize

DecodeStrategyBestBidUpdateMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET strategyId == ReadBytes(timestamp.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(strategyId.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET marketSize == ReadBytes(quoteCondition.rest, 4) IN IF ~marketSize.ok THEN Fail ELSE
    LET price == ReadBytes(marketSize.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET size == ReadBytes(price.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET custSize == ReadBytes(size.rest, 4) IN IF ~custSize.ok THEN Fail ELSE
    LET proCustSize == ReadBytes(custSize.rest, 4) IN IF ~proCustSize.ok THEN Fail ELSE
    LET dnttSize == ReadBytes(proCustSize.rest, 4) IN IF ~dnttSize.ok THEN Fail ELSE
    LET dnttMarketSize == ReadBytes(dnttSize.rest, 4) IN IF ~dnttMarketSize.ok THEN Fail ELSE
    Ok([ trackingNumber |-> trackingNumber.value,
         timestamp      |-> timestamp.value,
         strategyId     |-> strategyId.value,
         quoteCondition |-> quoteCondition.value,
         marketSize     |-> marketSize.value,
         price          |-> price.value,
         size           |-> size.value,
         custSize       |-> custSize.value,
         proCustSize    |-> proCustSize.value,
         dnttSize       |-> dnttSize.value,
         dnttMarketSize |-> dnttMarketSize.value ], dnttMarketSize.rest)

ZeroStrategyBestBidUpdateMessage ==
    [ trackingNumber |-> [i \in 1 .. 2 |-> 0],
      timestamp      |-> [i \in 1 .. 8 |-> 0],
      strategyId     |-> [i \in 1 .. 4 |-> 0],
      quoteCondition |-> [i \in 1 .. 1 |-> 0],
      marketSize     |-> [i \in 1 .. 4 |-> 0],
      price          |-> [i \in 1 .. 4 |-> 0],
      size           |-> [i \in 1 .. 4 |-> 0],
      custSize       |-> [i \in 1 .. 4 |-> 0],
      proCustSize    |-> [i \in 1 .. 4 |-> 0],
      dnttSize       |-> [i \in 1 .. 4 |-> 0],
      dnttMarketSize |-> [i \in 1 .. 4 |-> 0] ]

(* Strategy Best Bid Update Message at zero, then each field in turn at the values it is checked at *)
CheckedStrategyBestBidUpdateMessage ==
    { ZeroStrategyBestBidUpdateMessage }
        \cup { [ZeroStrategyBestBidUpdateMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroStrategyBestBidUpdateMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroStrategyBestBidUpdateMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestBidUpdateMessage EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroStrategyBestBidUpdateMessage EXCEPT !.marketSize = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestBidUpdateMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestBidUpdateMessage EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestBidUpdateMessage EXCEPT !.custSize = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestBidUpdateMessage EXCEPT !.proCustSize = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestBidUpdateMessage EXCEPT !.dnttSize = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestBidUpdateMessage EXCEPT !.dnttMarketSize = one] : one \in Sample(4) }

(***************************************************************************)
(* Strategy Best Ask Update Message: 43 bytes                              *)
(***************************************************************************)

StrategyBestAskUpdateMessage ==
    [ trackingNumber : Sample(2),
      timestamp      : Sample(8),
      strategyId     : Sample(4),
      quoteCondition : Sample(1),
      marketSize     : Sample(4),
      price          : Sample(4),
      size           : Sample(4),
      custSize       : Sample(4),
      proCustSize    : Sample(4),
      dnttSize       : Sample(4),
      dnttMarketSize : Sample(4) ]

EncodeStrategyBestAskUpdateMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.strategyId
        \o message.quoteCondition
        \o message.marketSize
        \o message.price
        \o message.size
        \o message.custSize
        \o message.proCustSize
        \o message.dnttSize
        \o message.dnttMarketSize

DecodeStrategyBestAskUpdateMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET strategyId == ReadBytes(timestamp.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(strategyId.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET marketSize == ReadBytes(quoteCondition.rest, 4) IN IF ~marketSize.ok THEN Fail ELSE
    LET price == ReadBytes(marketSize.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET size == ReadBytes(price.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET custSize == ReadBytes(size.rest, 4) IN IF ~custSize.ok THEN Fail ELSE
    LET proCustSize == ReadBytes(custSize.rest, 4) IN IF ~proCustSize.ok THEN Fail ELSE
    LET dnttSize == ReadBytes(proCustSize.rest, 4) IN IF ~dnttSize.ok THEN Fail ELSE
    LET dnttMarketSize == ReadBytes(dnttSize.rest, 4) IN IF ~dnttMarketSize.ok THEN Fail ELSE
    Ok([ trackingNumber |-> trackingNumber.value,
         timestamp      |-> timestamp.value,
         strategyId     |-> strategyId.value,
         quoteCondition |-> quoteCondition.value,
         marketSize     |-> marketSize.value,
         price          |-> price.value,
         size           |-> size.value,
         custSize       |-> custSize.value,
         proCustSize    |-> proCustSize.value,
         dnttSize       |-> dnttSize.value,
         dnttMarketSize |-> dnttMarketSize.value ], dnttMarketSize.rest)

ZeroStrategyBestAskUpdateMessage ==
    [ trackingNumber |-> [i \in 1 .. 2 |-> 0],
      timestamp      |-> [i \in 1 .. 8 |-> 0],
      strategyId     |-> [i \in 1 .. 4 |-> 0],
      quoteCondition |-> [i \in 1 .. 1 |-> 0],
      marketSize     |-> [i \in 1 .. 4 |-> 0],
      price          |-> [i \in 1 .. 4 |-> 0],
      size           |-> [i \in 1 .. 4 |-> 0],
      custSize       |-> [i \in 1 .. 4 |-> 0],
      proCustSize    |-> [i \in 1 .. 4 |-> 0],
      dnttSize       |-> [i \in 1 .. 4 |-> 0],
      dnttMarketSize |-> [i \in 1 .. 4 |-> 0] ]

(* Strategy Best Ask Update Message at zero, then each field in turn at the values it is checked at *)
CheckedStrategyBestAskUpdateMessage ==
    { ZeroStrategyBestAskUpdateMessage }
        \cup { [ZeroStrategyBestAskUpdateMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroStrategyBestAskUpdateMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroStrategyBestAskUpdateMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestAskUpdateMessage EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroStrategyBestAskUpdateMessage EXCEPT !.marketSize = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestAskUpdateMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestAskUpdateMessage EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestAskUpdateMessage EXCEPT !.custSize = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestAskUpdateMessage EXCEPT !.proCustSize = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestAskUpdateMessage EXCEPT !.dnttSize = one] : one \in Sample(4) }
        \cup { [ZeroStrategyBestAskUpdateMessage EXCEPT !.dnttMarketSize = one] : one \in Sample(4) }

(***************************************************************************)
(* Udp Payload, selected by Message Type                                   *)
(***************************************************************************)

SystemEventMessageCode == 83  \* "S"
ComplexStrategyDirectoryMessageCode == 115  \* "s"
StrategyTradingActionMessageCode == 72  \* "H"
StrategyBestBidAndAskUpdateMessageCode == 69  \* "E"
StrategyBestBidUpdateMessageCode == 99  \* "c"
StrategyBestAskUpdateMessageCode == 100  \* "d"

UdpPayload ==
    [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {ComplexStrategyDirectoryMessageCode}, body : ComplexStrategyDirectoryMessage ]
        \cup [ tag : {StrategyTradingActionMessageCode}, body : StrategyTradingActionMessage ]
        \cup [ tag : {StrategyBestBidAndAskUpdateMessageCode}, body : StrategyBestBidAndAskUpdateMessage ]
        \cup [ tag : {StrategyBestBidUpdateMessageCode}, body : StrategyBestBidUpdateMessage ]
        \cup [ tag : {StrategyBestAskUpdateMessageCode}, body : StrategyBestAskUpdateMessage ]

EncodeUdpPayload(message) ==
    CASE message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = ComplexStrategyDirectoryMessageCode -> EncodeComplexStrategyDirectoryMessage(message.body)
      [] message.tag = StrategyTradingActionMessageCode -> EncodeStrategyTradingActionMessage(message.body)
      [] message.tag = StrategyBestBidAndAskUpdateMessageCode -> EncodeStrategyBestBidAndAskUpdateMessage(message.body)
      [] message.tag = StrategyBestBidUpdateMessageCode -> EncodeStrategyBestBidUpdateMessage(message.body)
      [] message.tag = StrategyBestAskUpdateMessageCode -> EncodeStrategyBestAskUpdateMessage(message.body)

DecodeUdpPayload(tag, bytes) ==
    LET read ==
            CASE tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = ComplexStrategyDirectoryMessageCode -> DecodeComplexStrategyDirectoryMessage(bytes)
              [] tag = StrategyTradingActionMessageCode -> DecodeStrategyTradingActionMessage(bytes)
              [] tag = StrategyBestBidAndAskUpdateMessageCode -> DecodeStrategyBestBidAndAskUpdateMessage(bytes)
              [] tag = StrategyBestBidUpdateMessageCode -> DecodeStrategyBestBidUpdateMessage(bytes)
              [] tag = StrategyBestAskUpdateMessageCode -> DecodeStrategyBestAskUpdateMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroUdpPayload == [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]

(* Each Udp Payload in turn, at the values the message it names is checked at *)
CheckedUdpPayload ==
    { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> ComplexStrategyDirectoryMessageCode, body |-> one] : one \in CheckedComplexStrategyDirectoryMessage }
        \cup { [tag |-> StrategyTradingActionMessageCode, body |-> one] : one \in CheckedStrategyTradingActionMessage }
        \cup { [tag |-> StrategyBestBidAndAskUpdateMessageCode, body |-> one] : one \in CheckedStrategyBestBidAndAskUpdateMessage }
        \cup { [tag |-> StrategyBestBidUpdateMessageCode, body |-> one] : one \in CheckedStrategyBestBidUpdateMessage }
        \cup { [tag |-> StrategyBestAskUpdateMessageCode, body |-> one] : one \in CheckedStrategyBestAskUpdateMessage }

(***************************************************************************)
(* Message, framed by Message Length                                       *)
(***************************************************************************)

Message ==
    [ udpPayload : UdpPayload ]

EncodeMessageBody(message) ==
    EncodeUIntBE(message.udpPayload.tag, 1)
        \o EncodeUdpPayload(message.udpPayload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET udpPayload == DecodeUdpPayload(messageType.value, messageType.rest) IN IF ~udpPayload.ok THEN Fail ELSE
    Ok([ udpPayload |-> udpPayload.value ], udpPayload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
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
      [ZeroMessage EXCEPT !.udpPayload = [tag |-> StrategyBestBidAndAskUpdateMessageCode, body |-> ZeroStrategyBestBidAndAskUpdateMessage]],
      [ZeroMessage EXCEPT !.udpPayload = [tag |-> StrategyBestBidUpdateMessageCode, body |-> ZeroStrategyBestBidUpdateMessage]],
      [ZeroMessage EXCEPT !.udpPayload = [tag |-> StrategyBestAskUpdateMessageCode, body |-> ZeroStrategyBestAskUpdateMessage]] }

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
        \o EncodeUIntBE(Len(message.message), 2)
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET udpSession == ReadBytes(bytes, 10) IN IF ~udpSession.ok THEN Fail ELSE
    LET udpSequenceNumber == ReadBytes(udpSession.rest, 8) IN IF ~udpSequenceNumber.ok THEN Fail ELSE
    LET messageCount == ReadUIntBE(udpSequenceNumber.rest, 2) IN IF ~messageCount.ok THEN Fail ELSE
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

(* Every Strategy Trading Action Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyTradingActionMessage ==
    \A message \in CheckedStrategyTradingActionMessage :
        LET read == DecodeStrategyTradingActionMessage(EncodeStrategyTradingActionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Best Bid And Ask Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyBestBidAndAskUpdateMessage ==
    \A message \in CheckedStrategyBestBidAndAskUpdateMessage :
        LET read == DecodeStrategyBestBidAndAskUpdateMessage(EncodeStrategyBestBidAndAskUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Best Bid Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyBestBidUpdateMessage ==
    \A message \in CheckedStrategyBestBidUpdateMessage :
        LET read == DecodeStrategyBestBidUpdateMessage(EncodeStrategyBestBidUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Best Ask Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyBestAskUpdateMessage ==
    \A message \in CheckedStrategyBestAskUpdateMessage :
        LET read == DecodeStrategyBestAskUpdateMessage(EncodeStrategyBestAskUpdateMessage(message))
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
    \A message \in CheckedUdpPayload :
        LET read == DecodeUdpPayload(message.tag, EncodeUdpPayload(message))
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
