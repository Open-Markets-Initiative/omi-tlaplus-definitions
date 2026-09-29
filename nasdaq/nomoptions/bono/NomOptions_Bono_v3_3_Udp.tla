--------------------- MODULE NomOptions_Bono_v3_3_Udp ----------------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Nom Binary Order Entry v3.3                                    *)
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
(* Timestamp Message: 4 bytes                                              *)
(***************************************************************************)

TimestampMessage ==
    [ second : Sample(4) ]

EncodeTimestampMessage(message) ==
    message.second

DecodeTimestampMessage(bytes) ==
    LET second == ReadBytes(bytes, 4) IN IF ~second.ok THEN Fail ELSE
    Ok([ second |-> second.value ], second.rest)

ZeroTimestampMessage ==
    [ second |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp Message at zero, then each field in turn at the values it is checked at *)
CheckedTimestampMessage ==
    { ZeroTimestampMessage }
        \cup { [ZeroTimestampMessage EXCEPT !.second = one] : one \in Sample(4) }

(***************************************************************************)
(* System Event Message: 7 bytes                                           *)
(***************************************************************************)

SystemEventMessage ==
    [ nanoseconds : Sample(4),
      eventCode   : Sample(1),
      version     : Sample(1),
      subversion  : Sample(1) ]

EncodeSystemEventMessage(message) ==
    message.nanoseconds
        \o message.eventCode
        \o message.version
        \o message.subversion

DecodeSystemEventMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET eventCode == ReadBytes(nanoseconds.rest, 1) IN IF ~eventCode.ok THEN Fail ELSE
    LET version == ReadBytes(eventCode.rest, 1) IN IF ~version.ok THEN Fail ELSE
    LET subversion == ReadBytes(version.rest, 1) IN IF ~subversion.ok THEN Fail ELSE
    Ok([ nanoseconds |-> nanoseconds.value,
         eventCode   |-> eventCode.value,
         version     |-> version.value,
         subversion  |-> subversion.value ], subversion.rest)

ZeroSystemEventMessage ==
    [ nanoseconds |-> [i \in 1 .. 4 |-> 0],
      eventCode   |-> [i \in 1 .. 1 |-> 0],
      version     |-> [i \in 1 .. 1 |-> 0],
      subversion  |-> [i \in 1 .. 1 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventCode = one] : one \in Sample(1) }
        \cup { [ZeroSystemEventMessage EXCEPT !.version = one] : one \in Sample(1) }
        \cup { [ZeroSystemEventMessage EXCEPT !.subversion = one] : one \in Sample(1) }

(***************************************************************************)
(* Options Directory Message: 39 bytes                                     *)
(***************************************************************************)

OptionsDirectoryMessage ==
    [ nanoseconds       : Sample(4),
      optionId          : Sample(4),
      securitySymbol    : Sample(6),
      expirationYear    : Sample(1),
      expirationMonth   : Sample(1),
      expirationDay     : Sample(1),
      strikePrice       : Sample(4),
      optionType        : Sample(1),
      source            : Sample(1),
      underlyingSymbol  : Sample(13),
      optionClosingType : Sample(1),
      tradable          : Sample(1),
      mpv               : Sample(1) ]

EncodeOptionsDirectoryMessage(message) ==
    message.nanoseconds
        \o message.optionId
        \o message.securitySymbol
        \o message.expirationYear
        \o message.expirationMonth
        \o message.expirationDay
        \o message.strikePrice
        \o message.optionType
        \o message.source
        \o message.underlyingSymbol
        \o message.optionClosingType
        \o message.tradable
        \o message.mpv

DecodeOptionsDirectoryMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET optionId == ReadBytes(nanoseconds.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(optionId.rest, 6) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET expirationYear == ReadBytes(securitySymbol.rest, 1) IN IF ~expirationYear.ok THEN Fail ELSE
    LET expirationMonth == ReadBytes(expirationYear.rest, 1) IN IF ~expirationMonth.ok THEN Fail ELSE
    LET expirationDay == ReadBytes(expirationMonth.rest, 1) IN IF ~expirationDay.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(expirationDay.rest, 4) IN IF ~strikePrice.ok THEN Fail ELSE
    LET optionType == ReadBytes(strikePrice.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET source == ReadBytes(optionType.rest, 1) IN IF ~source.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(source.rest, 13) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET optionClosingType == ReadBytes(underlyingSymbol.rest, 1) IN IF ~optionClosingType.ok THEN Fail ELSE
    LET tradable == ReadBytes(optionClosingType.rest, 1) IN IF ~tradable.ok THEN Fail ELSE
    LET mpv == ReadBytes(tradable.rest, 1) IN IF ~mpv.ok THEN Fail ELSE
    Ok([ nanoseconds       |-> nanoseconds.value,
         optionId          |-> optionId.value,
         securitySymbol    |-> securitySymbol.value,
         expirationYear    |-> expirationYear.value,
         expirationMonth   |-> expirationMonth.value,
         expirationDay     |-> expirationDay.value,
         strikePrice       |-> strikePrice.value,
         optionType        |-> optionType.value,
         source            |-> source.value,
         underlyingSymbol  |-> underlyingSymbol.value,
         optionClosingType |-> optionClosingType.value,
         tradable          |-> tradable.value,
         mpv               |-> mpv.value ], mpv.rest)

ZeroOptionsDirectoryMessage ==
    [ nanoseconds       |-> [i \in 1 .. 4 |-> 0],
      optionId          |-> [i \in 1 .. 4 |-> 0],
      securitySymbol    |-> [i \in 1 .. 6 |-> 0],
      expirationYear    |-> [i \in 1 .. 1 |-> 0],
      expirationMonth   |-> [i \in 1 .. 1 |-> 0],
      expirationDay     |-> [i \in 1 .. 1 |-> 0],
      strikePrice       |-> [i \in 1 .. 4 |-> 0],
      optionType        |-> [i \in 1 .. 1 |-> 0],
      source            |-> [i \in 1 .. 1 |-> 0],
      underlyingSymbol  |-> [i \in 1 .. 13 |-> 0],
      optionClosingType |-> [i \in 1 .. 1 |-> 0],
      tradable          |-> [i \in 1 .. 1 |-> 0],
      mpv               |-> [i \in 1 .. 1 |-> 0] ]

(* Options Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionsDirectoryMessage ==
    { ZeroOptionsDirectoryMessage }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.securitySymbol = one] : one \in Sample(6) }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.expirationYear = one] : one \in Sample(1) }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.expirationMonth = one] : one \in Sample(1) }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.expirationDay = one] : one \in Sample(1) }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.source = one] : one \in Sample(1) }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(13) }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.optionClosingType = one] : one \in Sample(1) }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.tradable = one] : one \in Sample(1) }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.mpv = one] : one \in Sample(1) }

(***************************************************************************)
(* Trading Action Message: 9 bytes                                         *)
(***************************************************************************)

TradingActionMessage ==
    [ nanoseconds         : Sample(4),
      optionId            : Sample(4),
      currentTradingState : Sample(1) ]

EncodeTradingActionMessage(message) ==
    message.nanoseconds
        \o message.optionId
        \o message.currentTradingState

DecodeTradingActionMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET optionId == ReadBytes(nanoseconds.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET currentTradingState == ReadBytes(optionId.rest, 1) IN IF ~currentTradingState.ok THEN Fail ELSE
    Ok([ nanoseconds         |-> nanoseconds.value,
         optionId            |-> optionId.value,
         currentTradingState |-> currentTradingState.value ], currentTradingState.rest)

ZeroTradingActionMessage ==
    [ nanoseconds         |-> [i \in 1 .. 4 |-> 0],
      optionId            |-> [i \in 1 .. 4 |-> 0],
      currentTradingState |-> [i \in 1 .. 1 |-> 0] ]

(* Trading Action Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingActionMessage ==
    { ZeroTradingActionMessage }
        \cup { [ZeroTradingActionMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroTradingActionMessage EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroTradingActionMessage EXCEPT !.currentTradingState = one] : one \in Sample(1) }

(***************************************************************************)
(* Security Open Closed Message: 9 bytes                                   *)
(***************************************************************************)

SecurityOpenClosedMessage ==
    [ nanoseconds : Sample(4),
      optionId    : Sample(4),
      openState   : Sample(1) ]

EncodeSecurityOpenClosedMessage(message) ==
    message.nanoseconds
        \o message.optionId
        \o message.openState

DecodeSecurityOpenClosedMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET optionId == ReadBytes(nanoseconds.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET openState == ReadBytes(optionId.rest, 1) IN IF ~openState.ok THEN Fail ELSE
    Ok([ nanoseconds |-> nanoseconds.value,
         optionId    |-> optionId.value,
         openState   |-> openState.value ], openState.rest)

ZeroSecurityOpenClosedMessage ==
    [ nanoseconds |-> [i \in 1 .. 4 |-> 0],
      optionId    |-> [i \in 1 .. 4 |-> 0],
      openState   |-> [i \in 1 .. 1 |-> 0] ]

(* Security Open Closed Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityOpenClosedMessage ==
    { ZeroSecurityOpenClosedMessage }
        \cup { [ZeroSecurityOpenClosedMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSecurityOpenClosedMessage EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityOpenClosedMessage EXCEPT !.openState = one] : one \in Sample(1) }

(***************************************************************************)
(* Short Best Bid And Ask Update Message: 17 bytes                         *)
(***************************************************************************)

ShortBestBidAndAskUpdateMessage ==
    [ nanoseconds    : Sample(4),
      optionId       : Sample(4),
      quoteCondition : Sample(1),
      bidPrice2      : Sample(2),
      bidSize2       : Sample(2),
      askPrice2      : Sample(2),
      askSize2       : Sample(2) ]

EncodeShortBestBidAndAskUpdateMessage(message) ==
    message.nanoseconds
        \o message.optionId
        \o message.quoteCondition
        \o message.bidPrice2
        \o message.bidSize2
        \o message.askPrice2
        \o message.askSize2

DecodeShortBestBidAndAskUpdateMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET optionId == ReadBytes(nanoseconds.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(optionId.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET bidPrice2 == ReadBytes(quoteCondition.rest, 2) IN IF ~bidPrice2.ok THEN Fail ELSE
    LET bidSize2 == ReadBytes(bidPrice2.rest, 2) IN IF ~bidSize2.ok THEN Fail ELSE
    LET askPrice2 == ReadBytes(bidSize2.rest, 2) IN IF ~askPrice2.ok THEN Fail ELSE
    LET askSize2 == ReadBytes(askPrice2.rest, 2) IN IF ~askSize2.ok THEN Fail ELSE
    Ok([ nanoseconds    |-> nanoseconds.value,
         optionId       |-> optionId.value,
         quoteCondition |-> quoteCondition.value,
         bidPrice2      |-> bidPrice2.value,
         bidSize2       |-> bidSize2.value,
         askPrice2      |-> askPrice2.value,
         askSize2       |-> askSize2.value ], askSize2.rest)

ZeroShortBestBidAndAskUpdateMessage ==
    [ nanoseconds    |-> [i \in 1 .. 4 |-> 0],
      optionId       |-> [i \in 1 .. 4 |-> 0],
      quoteCondition |-> [i \in 1 .. 1 |-> 0],
      bidPrice2      |-> [i \in 1 .. 2 |-> 0],
      bidSize2       |-> [i \in 1 .. 2 |-> 0],
      askPrice2      |-> [i \in 1 .. 2 |-> 0],
      askSize2       |-> [i \in 1 .. 2 |-> 0] ]

(* Short Best Bid And Ask Update Message at zero, then each field in turn at the values it is checked at *)
CheckedShortBestBidAndAskUpdateMessage ==
    { ZeroShortBestBidAndAskUpdateMessage }
        \cup { [ZeroShortBestBidAndAskUpdateMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroShortBestBidAndAskUpdateMessage EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroShortBestBidAndAskUpdateMessage EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroShortBestBidAndAskUpdateMessage EXCEPT !.bidPrice2 = one] : one \in Sample(2) }
        \cup { [ZeroShortBestBidAndAskUpdateMessage EXCEPT !.bidSize2 = one] : one \in Sample(2) }
        \cup { [ZeroShortBestBidAndAskUpdateMessage EXCEPT !.askPrice2 = one] : one \in Sample(2) }
        \cup { [ZeroShortBestBidAndAskUpdateMessage EXCEPT !.askSize2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Long Best Bid And Ask Update Message: 25 bytes                          *)
(***************************************************************************)

LongBestBidAndAskUpdateMessage ==
    [ nanoseconds    : Sample(4),
      optionId       : Sample(4),
      quoteCondition : Sample(1),
      bidPrice4      : Sample(4),
      bidSize4       : Sample(4),
      askPrice4      : Sample(4),
      askSize4       : Sample(4) ]

EncodeLongBestBidAndAskUpdateMessage(message) ==
    message.nanoseconds
        \o message.optionId
        \o message.quoteCondition
        \o message.bidPrice4
        \o message.bidSize4
        \o message.askPrice4
        \o message.askSize4

DecodeLongBestBidAndAskUpdateMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET optionId == ReadBytes(nanoseconds.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(optionId.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET bidPrice4 == ReadBytes(quoteCondition.rest, 4) IN IF ~bidPrice4.ok THEN Fail ELSE
    LET bidSize4 == ReadBytes(bidPrice4.rest, 4) IN IF ~bidSize4.ok THEN Fail ELSE
    LET askPrice4 == ReadBytes(bidSize4.rest, 4) IN IF ~askPrice4.ok THEN Fail ELSE
    LET askSize4 == ReadBytes(askPrice4.rest, 4) IN IF ~askSize4.ok THEN Fail ELSE
    Ok([ nanoseconds    |-> nanoseconds.value,
         optionId       |-> optionId.value,
         quoteCondition |-> quoteCondition.value,
         bidPrice4      |-> bidPrice4.value,
         bidSize4       |-> bidSize4.value,
         askPrice4      |-> askPrice4.value,
         askSize4       |-> askSize4.value ], askSize4.rest)

ZeroLongBestBidAndAskUpdateMessage ==
    [ nanoseconds    |-> [i \in 1 .. 4 |-> 0],
      optionId       |-> [i \in 1 .. 4 |-> 0],
      quoteCondition |-> [i \in 1 .. 1 |-> 0],
      bidPrice4      |-> [i \in 1 .. 4 |-> 0],
      bidSize4       |-> [i \in 1 .. 4 |-> 0],
      askPrice4      |-> [i \in 1 .. 4 |-> 0],
      askSize4       |-> [i \in 1 .. 4 |-> 0] ]

(* Long Best Bid And Ask Update Message at zero, then each field in turn at the values it is checked at *)
CheckedLongBestBidAndAskUpdateMessage ==
    { ZeroLongBestBidAndAskUpdateMessage }
        \cup { [ZeroLongBestBidAndAskUpdateMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroLongBestBidAndAskUpdateMessage EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroLongBestBidAndAskUpdateMessage EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroLongBestBidAndAskUpdateMessage EXCEPT !.bidPrice4 = one] : one \in Sample(4) }
        \cup { [ZeroLongBestBidAndAskUpdateMessage EXCEPT !.bidSize4 = one] : one \in Sample(4) }
        \cup { [ZeroLongBestBidAndAskUpdateMessage EXCEPT !.askPrice4 = one] : one \in Sample(4) }
        \cup { [ZeroLongBestBidAndAskUpdateMessage EXCEPT !.askSize4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Short Best Ask Update Message: 13 bytes                                 *)
(***************************************************************************)

ShortBestAskUpdateMessage ==
    [ nanoseconds    : Sample(4),
      optionId       : Sample(4),
      quoteCondition : Sample(1),
      price2         : Sample(2),
      size2          : Sample(2) ]

EncodeShortBestAskUpdateMessage(message) ==
    message.nanoseconds
        \o message.optionId
        \o message.quoteCondition
        \o message.price2
        \o message.size2

DecodeShortBestAskUpdateMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET optionId == ReadBytes(nanoseconds.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(optionId.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET price2 == ReadBytes(quoteCondition.rest, 2) IN IF ~price2.ok THEN Fail ELSE
    LET size2 == ReadBytes(price2.rest, 2) IN IF ~size2.ok THEN Fail ELSE
    Ok([ nanoseconds    |-> nanoseconds.value,
         optionId       |-> optionId.value,
         quoteCondition |-> quoteCondition.value,
         price2         |-> price2.value,
         size2          |-> size2.value ], size2.rest)

ZeroShortBestAskUpdateMessage ==
    [ nanoseconds    |-> [i \in 1 .. 4 |-> 0],
      optionId       |-> [i \in 1 .. 4 |-> 0],
      quoteCondition |-> [i \in 1 .. 1 |-> 0],
      price2         |-> [i \in 1 .. 2 |-> 0],
      size2          |-> [i \in 1 .. 2 |-> 0] ]

(* Short Best Ask Update Message at zero, then each field in turn at the values it is checked at *)
CheckedShortBestAskUpdateMessage ==
    { ZeroShortBestAskUpdateMessage }
        \cup { [ZeroShortBestAskUpdateMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroShortBestAskUpdateMessage EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroShortBestAskUpdateMessage EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroShortBestAskUpdateMessage EXCEPT !.price2 = one] : one \in Sample(2) }
        \cup { [ZeroShortBestAskUpdateMessage EXCEPT !.size2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Short Best Bid Update Message: 13 bytes                                 *)
(***************************************************************************)

ShortBestBidUpdateMessage ==
    [ nanoseconds    : Sample(4),
      optionId       : Sample(4),
      quoteCondition : Sample(1),
      price2         : Sample(2),
      size2          : Sample(2) ]

EncodeShortBestBidUpdateMessage(message) ==
    message.nanoseconds
        \o message.optionId
        \o message.quoteCondition
        \o message.price2
        \o message.size2

DecodeShortBestBidUpdateMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET optionId == ReadBytes(nanoseconds.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(optionId.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET price2 == ReadBytes(quoteCondition.rest, 2) IN IF ~price2.ok THEN Fail ELSE
    LET size2 == ReadBytes(price2.rest, 2) IN IF ~size2.ok THEN Fail ELSE
    Ok([ nanoseconds    |-> nanoseconds.value,
         optionId       |-> optionId.value,
         quoteCondition |-> quoteCondition.value,
         price2         |-> price2.value,
         size2          |-> size2.value ], size2.rest)

ZeroShortBestBidUpdateMessage ==
    [ nanoseconds    |-> [i \in 1 .. 4 |-> 0],
      optionId       |-> [i \in 1 .. 4 |-> 0],
      quoteCondition |-> [i \in 1 .. 1 |-> 0],
      price2         |-> [i \in 1 .. 2 |-> 0],
      size2          |-> [i \in 1 .. 2 |-> 0] ]

(* Short Best Bid Update Message at zero, then each field in turn at the values it is checked at *)
CheckedShortBestBidUpdateMessage ==
    { ZeroShortBestBidUpdateMessage }
        \cup { [ZeroShortBestBidUpdateMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroShortBestBidUpdateMessage EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroShortBestBidUpdateMessage EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroShortBestBidUpdateMessage EXCEPT !.price2 = one] : one \in Sample(2) }
        \cup { [ZeroShortBestBidUpdateMessage EXCEPT !.size2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Long Best Ask Update Message: 17 bytes                                  *)
(***************************************************************************)

LongBestAskUpdateMessage ==
    [ nanoseconds    : Sample(4),
      optionId       : Sample(4),
      quoteCondition : Sample(1),
      price4         : Sample(4),
      size4          : Sample(4) ]

EncodeLongBestAskUpdateMessage(message) ==
    message.nanoseconds
        \o message.optionId
        \o message.quoteCondition
        \o message.price4
        \o message.size4

DecodeLongBestAskUpdateMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET optionId == ReadBytes(nanoseconds.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(optionId.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET price4 == ReadBytes(quoteCondition.rest, 4) IN IF ~price4.ok THEN Fail ELSE
    LET size4 == ReadBytes(price4.rest, 4) IN IF ~size4.ok THEN Fail ELSE
    Ok([ nanoseconds    |-> nanoseconds.value,
         optionId       |-> optionId.value,
         quoteCondition |-> quoteCondition.value,
         price4         |-> price4.value,
         size4          |-> size4.value ], size4.rest)

ZeroLongBestAskUpdateMessage ==
    [ nanoseconds    |-> [i \in 1 .. 4 |-> 0],
      optionId       |-> [i \in 1 .. 4 |-> 0],
      quoteCondition |-> [i \in 1 .. 1 |-> 0],
      price4         |-> [i \in 1 .. 4 |-> 0],
      size4          |-> [i \in 1 .. 4 |-> 0] ]

(* Long Best Ask Update Message at zero, then each field in turn at the values it is checked at *)
CheckedLongBestAskUpdateMessage ==
    { ZeroLongBestAskUpdateMessage }
        \cup { [ZeroLongBestAskUpdateMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroLongBestAskUpdateMessage EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroLongBestAskUpdateMessage EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroLongBestAskUpdateMessage EXCEPT !.price4 = one] : one \in Sample(4) }
        \cup { [ZeroLongBestAskUpdateMessage EXCEPT !.size4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Long Best Bid Update Message: 17 bytes                                  *)
(***************************************************************************)

LongBestBidUpdateMessage ==
    [ nanoseconds    : Sample(4),
      optionId       : Sample(4),
      quoteCondition : Sample(1),
      price4         : Sample(4),
      size4          : Sample(4) ]

EncodeLongBestBidUpdateMessage(message) ==
    message.nanoseconds
        \o message.optionId
        \o message.quoteCondition
        \o message.price4
        \o message.size4

DecodeLongBestBidUpdateMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET optionId == ReadBytes(nanoseconds.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(optionId.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET price4 == ReadBytes(quoteCondition.rest, 4) IN IF ~price4.ok THEN Fail ELSE
    LET size4 == ReadBytes(price4.rest, 4) IN IF ~size4.ok THEN Fail ELSE
    Ok([ nanoseconds    |-> nanoseconds.value,
         optionId       |-> optionId.value,
         quoteCondition |-> quoteCondition.value,
         price4         |-> price4.value,
         size4          |-> size4.value ], size4.rest)

ZeroLongBestBidUpdateMessage ==
    [ nanoseconds    |-> [i \in 1 .. 4 |-> 0],
      optionId       |-> [i \in 1 .. 4 |-> 0],
      quoteCondition |-> [i \in 1 .. 1 |-> 0],
      price4         |-> [i \in 1 .. 4 |-> 0],
      size4          |-> [i \in 1 .. 4 |-> 0] ]

(* Long Best Bid Update Message at zero, then each field in turn at the values it is checked at *)
CheckedLongBestBidUpdateMessage ==
    { ZeroLongBestBidUpdateMessage }
        \cup { [ZeroLongBestBidUpdateMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroLongBestBidUpdateMessage EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroLongBestBidUpdateMessage EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroLongBestBidUpdateMessage EXCEPT !.price4 = one] : one \in Sample(4) }
        \cup { [ZeroLongBestBidUpdateMessage EXCEPT !.size4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Trade Report Message: 21 bytes                                          *)
(***************************************************************************)

TradeReportMessage ==
    [ nanoseconds    : Sample(4),
      optionId       : Sample(4),
      crossId        : Sample(4),
      tradeCondition : Sample(1),
      price4         : Sample(4),
      volume         : Sample(4) ]

EncodeTradeReportMessage(message) ==
    message.nanoseconds
        \o message.optionId
        \o message.crossId
        \o message.tradeCondition
        \o message.price4
        \o message.volume

DecodeTradeReportMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET optionId == ReadBytes(nanoseconds.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET crossId == ReadBytes(optionId.rest, 4) IN IF ~crossId.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(crossId.rest, 1) IN IF ~tradeCondition.ok THEN Fail ELSE
    LET price4 == ReadBytes(tradeCondition.rest, 4) IN IF ~price4.ok THEN Fail ELSE
    LET volume == ReadBytes(price4.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    Ok([ nanoseconds    |-> nanoseconds.value,
         optionId       |-> optionId.value,
         crossId        |-> crossId.value,
         tradeCondition |-> tradeCondition.value,
         price4         |-> price4.value,
         volume         |-> volume.value ], volume.rest)

ZeroTradeReportMessage ==
    [ nanoseconds    |-> [i \in 1 .. 4 |-> 0],
      optionId       |-> [i \in 1 .. 4 |-> 0],
      crossId        |-> [i \in 1 .. 4 |-> 0],
      tradeCondition |-> [i \in 1 .. 1 |-> 0],
      price4         |-> [i \in 1 .. 4 |-> 0],
      volume         |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Report Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeReportMessage ==
    { ZeroTradeReportMessage }
        \cup { [ZeroTradeReportMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroTradeReportMessage EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroTradeReportMessage EXCEPT !.crossId = one] : one \in Sample(4) }
        \cup { [ZeroTradeReportMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }
        \cup { [ZeroTradeReportMessage EXCEPT !.price4 = one] : one \in Sample(4) }
        \cup { [ZeroTradeReportMessage EXCEPT !.volume = one] : one \in Sample(4) }

(***************************************************************************)
(* Broken Trade Report Message: 20 bytes                                   *)
(***************************************************************************)

BrokenTradeReportMessage ==
    [ nanoseconds     : Sample(4),
      optionId        : Sample(4),
      originalCrossId : Sample(4),
      originalPrice   : Sample(4),
      originalVolume  : Sample(4) ]

EncodeBrokenTradeReportMessage(message) ==
    message.nanoseconds
        \o message.optionId
        \o message.originalCrossId
        \o message.originalPrice
        \o message.originalVolume

DecodeBrokenTradeReportMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET optionId == ReadBytes(nanoseconds.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET originalCrossId == ReadBytes(optionId.rest, 4) IN IF ~originalCrossId.ok THEN Fail ELSE
    LET originalPrice == ReadBytes(originalCrossId.rest, 4) IN IF ~originalPrice.ok THEN Fail ELSE
    LET originalVolume == ReadBytes(originalPrice.rest, 4) IN IF ~originalVolume.ok THEN Fail ELSE
    Ok([ nanoseconds     |-> nanoseconds.value,
         optionId        |-> optionId.value,
         originalCrossId |-> originalCrossId.value,
         originalPrice   |-> originalPrice.value,
         originalVolume  |-> originalVolume.value ], originalVolume.rest)

ZeroBrokenTradeReportMessage ==
    [ nanoseconds     |-> [i \in 1 .. 4 |-> 0],
      optionId        |-> [i \in 1 .. 4 |-> 0],
      originalCrossId |-> [i \in 1 .. 4 |-> 0],
      originalPrice   |-> [i \in 1 .. 4 |-> 0],
      originalVolume  |-> [i \in 1 .. 4 |-> 0] ]

(* Broken Trade Report Message at zero, then each field in turn at the values it is checked at *)
CheckedBrokenTradeReportMessage ==
    { ZeroBrokenTradeReportMessage }
        \cup { [ZeroBrokenTradeReportMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroBrokenTradeReportMessage EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroBrokenTradeReportMessage EXCEPT !.originalCrossId = one] : one \in Sample(4) }
        \cup { [ZeroBrokenTradeReportMessage EXCEPT !.originalPrice = one] : one \in Sample(4) }
        \cup { [ZeroBrokenTradeReportMessage EXCEPT !.originalVolume = one] : one \in Sample(4) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

TimestampMessageCode == 84  \* "T"
SystemEventMessageCode == 83  \* "S"
OptionsDirectoryMessageCode == 68  \* "D"
TradingActionMessageCode == 72  \* "H"
SecurityOpenClosedMessageCode == 79  \* "O"
ShortBestBidAndAskUpdateMessageCode == 113  \* "q"
LongBestBidAndAskUpdateMessageCode == 81  \* "Q"
ShortBestAskUpdateMessageCode == 97  \* "a"
ShortBestBidUpdateMessageCode == 98  \* "b"
LongBestAskUpdateMessageCode == 65  \* "A"
LongBestBidUpdateMessageCode == 66  \* "B"
TradeReportMessageCode == 82  \* "R"
BrokenTradeReportMessageCode == 88  \* "X"

Payload ==
    [ tag : {TimestampMessageCode}, body : TimestampMessage ]
        \cup [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {OptionsDirectoryMessageCode}, body : OptionsDirectoryMessage ]
        \cup [ tag : {TradingActionMessageCode}, body : TradingActionMessage ]
        \cup [ tag : {SecurityOpenClosedMessageCode}, body : SecurityOpenClosedMessage ]
        \cup [ tag : {ShortBestBidAndAskUpdateMessageCode}, body : ShortBestBidAndAskUpdateMessage ]
        \cup [ tag : {LongBestBidAndAskUpdateMessageCode}, body : LongBestBidAndAskUpdateMessage ]
        \cup [ tag : {ShortBestAskUpdateMessageCode}, body : ShortBestAskUpdateMessage ]
        \cup [ tag : {ShortBestBidUpdateMessageCode}, body : ShortBestBidUpdateMessage ]
        \cup [ tag : {LongBestAskUpdateMessageCode}, body : LongBestAskUpdateMessage ]
        \cup [ tag : {LongBestBidUpdateMessageCode}, body : LongBestBidUpdateMessage ]
        \cup [ tag : {TradeReportMessageCode}, body : TradeReportMessage ]
        \cup [ tag : {BrokenTradeReportMessageCode}, body : BrokenTradeReportMessage ]

EncodePayload(message) ==
    CASE message.tag = TimestampMessageCode -> EncodeTimestampMessage(message.body)
      [] message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = OptionsDirectoryMessageCode -> EncodeOptionsDirectoryMessage(message.body)
      [] message.tag = TradingActionMessageCode -> EncodeTradingActionMessage(message.body)
      [] message.tag = SecurityOpenClosedMessageCode -> EncodeSecurityOpenClosedMessage(message.body)
      [] message.tag = ShortBestBidAndAskUpdateMessageCode -> EncodeShortBestBidAndAskUpdateMessage(message.body)
      [] message.tag = LongBestBidAndAskUpdateMessageCode -> EncodeLongBestBidAndAskUpdateMessage(message.body)
      [] message.tag = ShortBestAskUpdateMessageCode -> EncodeShortBestAskUpdateMessage(message.body)
      [] message.tag = ShortBestBidUpdateMessageCode -> EncodeShortBestBidUpdateMessage(message.body)
      [] message.tag = LongBestAskUpdateMessageCode -> EncodeLongBestAskUpdateMessage(message.body)
      [] message.tag = LongBestBidUpdateMessageCode -> EncodeLongBestBidUpdateMessage(message.body)
      [] message.tag = TradeReportMessageCode -> EncodeTradeReportMessage(message.body)
      [] message.tag = BrokenTradeReportMessageCode -> EncodeBrokenTradeReportMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = TimestampMessageCode -> DecodeTimestampMessage(bytes)
              [] tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = OptionsDirectoryMessageCode -> DecodeOptionsDirectoryMessage(bytes)
              [] tag = TradingActionMessageCode -> DecodeTradingActionMessage(bytes)
              [] tag = SecurityOpenClosedMessageCode -> DecodeSecurityOpenClosedMessage(bytes)
              [] tag = ShortBestBidAndAskUpdateMessageCode -> DecodeShortBestBidAndAskUpdateMessage(bytes)
              [] tag = LongBestBidAndAskUpdateMessageCode -> DecodeLongBestBidAndAskUpdateMessage(bytes)
              [] tag = ShortBestAskUpdateMessageCode -> DecodeShortBestAskUpdateMessage(bytes)
              [] tag = ShortBestBidUpdateMessageCode -> DecodeShortBestBidUpdateMessage(bytes)
              [] tag = LongBestAskUpdateMessageCode -> DecodeLongBestAskUpdateMessage(bytes)
              [] tag = LongBestBidUpdateMessageCode -> DecodeLongBestBidUpdateMessage(bytes)
              [] tag = TradeReportMessageCode -> DecodeTradeReportMessage(bytes)
              [] tag = BrokenTradeReportMessageCode -> DecodeBrokenTradeReportMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> TimestampMessageCode, body |-> ZeroTimestampMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> TimestampMessageCode, body |-> one] : one \in CheckedTimestampMessage }
        \cup { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> OptionsDirectoryMessageCode, body |-> one] : one \in CheckedOptionsDirectoryMessage }
        \cup { [tag |-> TradingActionMessageCode, body |-> one] : one \in CheckedTradingActionMessage }
        \cup { [tag |-> SecurityOpenClosedMessageCode, body |-> one] : one \in CheckedSecurityOpenClosedMessage }
        \cup { [tag |-> ShortBestBidAndAskUpdateMessageCode, body |-> one] : one \in CheckedShortBestBidAndAskUpdateMessage }
        \cup { [tag |-> LongBestBidAndAskUpdateMessageCode, body |-> one] : one \in CheckedLongBestBidAndAskUpdateMessage }
        \cup { [tag |-> ShortBestAskUpdateMessageCode, body |-> one] : one \in CheckedShortBestAskUpdateMessage }
        \cup { [tag |-> ShortBestBidUpdateMessageCode, body |-> one] : one \in CheckedShortBestBidUpdateMessage }
        \cup { [tag |-> LongBestAskUpdateMessageCode, body |-> one] : one \in CheckedLongBestAskUpdateMessage }
        \cup { [tag |-> LongBestBidUpdateMessageCode, body |-> one] : one \in CheckedLongBestBidUpdateMessage }
        \cup { [tag |-> TradeReportMessageCode, body |-> one] : one \in CheckedTradeReportMessage }
        \cup { [tag |-> BrokenTradeReportMessageCode, body |-> one] : one \in CheckedBrokenTradeReportMessage }

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
    { [ZeroMessage EXCEPT !.payload = [tag |-> TimestampMessageCode, body |-> ZeroTimestampMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OptionsDirectoryMessageCode, body |-> ZeroOptionsDirectoryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradingActionMessageCode, body |-> ZeroTradingActionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityOpenClosedMessageCode, body |-> ZeroSecurityOpenClosedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ShortBestBidAndAskUpdateMessageCode, body |-> ZeroShortBestBidAndAskUpdateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LongBestBidAndAskUpdateMessageCode, body |-> ZeroLongBestBidAndAskUpdateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ShortBestAskUpdateMessageCode, body |-> ZeroShortBestAskUpdateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ShortBestBidUpdateMessageCode, body |-> ZeroShortBestBidUpdateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LongBestAskUpdateMessageCode, body |-> ZeroLongBestAskUpdateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LongBestBidUpdateMessageCode, body |-> ZeroLongBestBidUpdateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeReportMessageCode, body |-> ZeroTradeReportMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> BrokenTradeReportMessageCode, body |-> ZeroBrokenTradeReportMessage]] }

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

(* Every Timestamp Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestampMessage ==
    \A message \in CheckedTimestampMessage :
        LET read == DecodeTimestampMessage(EncodeTimestampMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every System Event Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSystemEventMessage ==
    \A message \in CheckedSystemEventMessage :
        LET read == DecodeSystemEventMessage(EncodeSystemEventMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Options Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionsDirectoryMessage ==
    \A message \in CheckedOptionsDirectoryMessage :
        LET read == DecodeOptionsDirectoryMessage(EncodeOptionsDirectoryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trading Action Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingActionMessage ==
    \A message \in CheckedTradingActionMessage :
        LET read == DecodeTradingActionMessage(EncodeTradingActionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Open Closed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityOpenClosedMessage ==
    \A message \in CheckedSecurityOpenClosedMessage :
        LET read == DecodeSecurityOpenClosedMessage(EncodeSecurityOpenClosedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Short Best Bid And Ask Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripShortBestBidAndAskUpdateMessage ==
    \A message \in CheckedShortBestBidAndAskUpdateMessage :
        LET read == DecodeShortBestBidAndAskUpdateMessage(EncodeShortBestBidAndAskUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Best Bid And Ask Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLongBestBidAndAskUpdateMessage ==
    \A message \in CheckedLongBestBidAndAskUpdateMessage :
        LET read == DecodeLongBestBidAndAskUpdateMessage(EncodeLongBestBidAndAskUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Short Best Ask Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripShortBestAskUpdateMessage ==
    \A message \in CheckedShortBestAskUpdateMessage :
        LET read == DecodeShortBestAskUpdateMessage(EncodeShortBestAskUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Short Best Bid Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripShortBestBidUpdateMessage ==
    \A message \in CheckedShortBestBidUpdateMessage :
        LET read == DecodeShortBestBidUpdateMessage(EncodeShortBestBidUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Best Ask Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLongBestAskUpdateMessage ==
    \A message \in CheckedLongBestAskUpdateMessage :
        LET read == DecodeLongBestAskUpdateMessage(EncodeLongBestAskUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Best Bid Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLongBestBidUpdateMessage ==
    \A message \in CheckedLongBestBidUpdateMessage :
        LET read == DecodeLongBestBidUpdateMessage(EncodeLongBestBidUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeReportMessage ==
    \A message \in CheckedTradeReportMessage :
        LET read == DecodeTradeReportMessage(EncodeTradeReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Broken Trade Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBrokenTradeReportMessage ==
    \A message \in CheckedBrokenTradeReportMessage :
        LET read == DecodeBrokenTradeReportMessage(EncodeBrokenTradeReportMessage(message))
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
