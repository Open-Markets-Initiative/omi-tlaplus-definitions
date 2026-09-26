------------------ MODULE PhlxOptions_DepthOfMarket_v1_6 -------------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Depth Of Market v1.6                                           *)
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
(* Seconds Message: 4 bytes                                                *)
(***************************************************************************)

SecondsMessage ==
    [ second : Sample(4) ]

EncodeSecondsMessage(message) ==
    message.second

DecodeSecondsMessage(bytes) ==
    LET second == ReadBytes(bytes, 4) IN IF ~second.ok THEN Fail ELSE
    Ok([ second |-> second.value ], second.rest)

ZeroSecondsMessage ==
    [ second |-> [i \in 1 .. 4 |-> 0] ]

(* Seconds Message at zero, then each field in turn at the values it is checked at *)
CheckedSecondsMessage ==
    { ZeroSecondsMessage }
        \cup { [ZeroSecondsMessage EXCEPT !.second = one] : one \in Sample(4) }

(***************************************************************************)
(* System Event Message: 5 bytes                                           *)
(***************************************************************************)

SystemEventMessage ==
    [ nanoseconds : Sample(4),
      eventCode   : Sample(1) ]

EncodeSystemEventMessage(message) ==
    message.nanoseconds
        \o message.eventCode

DecodeSystemEventMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET eventCode == ReadBytes(nanoseconds.rest, 1) IN IF ~eventCode.ok THEN Fail ELSE
    Ok([ nanoseconds |-> nanoseconds.value,
         eventCode   |-> eventCode.value ], eventCode.rest)

ZeroSystemEventMessage ==
    [ nanoseconds |-> [i \in 1 .. 4 |-> 0],
      eventCode   |-> [i \in 1 .. 1 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Base Reference Message: 12 bytes                                        *)
(***************************************************************************)

BaseReferenceMessage ==
    [ nanoseconds         : Sample(4),
      baseReferenceNumber : Sample(8) ]

EncodeBaseReferenceMessage(message) ==
    message.nanoseconds
        \o message.baseReferenceNumber

DecodeBaseReferenceMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET baseReferenceNumber == ReadBytes(nanoseconds.rest, 8) IN IF ~baseReferenceNumber.ok THEN Fail ELSE
    Ok([ nanoseconds         |-> nanoseconds.value,
         baseReferenceNumber |-> baseReferenceNumber.value ], baseReferenceNumber.rest)

ZeroBaseReferenceMessage ==
    [ nanoseconds         |-> [i \in 1 .. 4 |-> 0],
      baseReferenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Base Reference Message at zero, then each field in turn at the values it is checked at *)
CheckedBaseReferenceMessage ==
    { ZeroBaseReferenceMessage }
        \cup { [ZeroBaseReferenceMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroBaseReferenceMessage EXCEPT !.baseReferenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Option Directory Message: 39 bytes                                      *)
(***************************************************************************)

OptionDirectoryMessage ==
    [ nanoseconds         : Sample(4),
      optionId            : Sample(4),
      securitySymbol      : Sample(6),
      expirationYear      : Sample(1),
      expirationMonth     : Sample(1),
      expirationDate      : Sample(1),
      explicitStrikePrice : Sample(4),
      optionType          : Sample(1),
      source              : Sample(1),
      underlyingSymbol    : Sample(13),
      optionsClosingType  : Sample(1),
      tradable            : Sample(1),
      mpv                 : Sample(1) ]

EncodeOptionDirectoryMessage(message) ==
    message.nanoseconds
        \o message.optionId
        \o message.securitySymbol
        \o message.expirationYear
        \o message.expirationMonth
        \o message.expirationDate
        \o message.explicitStrikePrice
        \o message.optionType
        \o message.source
        \o message.underlyingSymbol
        \o message.optionsClosingType
        \o message.tradable
        \o message.mpv

DecodeOptionDirectoryMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET optionId == ReadBytes(nanoseconds.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(optionId.rest, 6) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET expirationYear == ReadBytes(securitySymbol.rest, 1) IN IF ~expirationYear.ok THEN Fail ELSE
    LET expirationMonth == ReadBytes(expirationYear.rest, 1) IN IF ~expirationMonth.ok THEN Fail ELSE
    LET expirationDate == ReadBytes(expirationMonth.rest, 1) IN IF ~expirationDate.ok THEN Fail ELSE
    LET explicitStrikePrice == ReadBytes(expirationDate.rest, 4) IN IF ~explicitStrikePrice.ok THEN Fail ELSE
    LET optionType == ReadBytes(explicitStrikePrice.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET source == ReadBytes(optionType.rest, 1) IN IF ~source.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(source.rest, 13) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET optionsClosingType == ReadBytes(underlyingSymbol.rest, 1) IN IF ~optionsClosingType.ok THEN Fail ELSE
    LET tradable == ReadBytes(optionsClosingType.rest, 1) IN IF ~tradable.ok THEN Fail ELSE
    LET mpv == ReadBytes(tradable.rest, 1) IN IF ~mpv.ok THEN Fail ELSE
    Ok([ nanoseconds         |-> nanoseconds.value,
         optionId            |-> optionId.value,
         securitySymbol      |-> securitySymbol.value,
         expirationYear      |-> expirationYear.value,
         expirationMonth     |-> expirationMonth.value,
         expirationDate      |-> expirationDate.value,
         explicitStrikePrice |-> explicitStrikePrice.value,
         optionType          |-> optionType.value,
         source              |-> source.value,
         underlyingSymbol    |-> underlyingSymbol.value,
         optionsClosingType  |-> optionsClosingType.value,
         tradable            |-> tradable.value,
         mpv                 |-> mpv.value ], mpv.rest)

ZeroOptionDirectoryMessage ==
    [ nanoseconds         |-> [i \in 1 .. 4 |-> 0],
      optionId            |-> [i \in 1 .. 4 |-> 0],
      securitySymbol      |-> [i \in 1 .. 6 |-> 0],
      expirationYear      |-> [i \in 1 .. 1 |-> 0],
      expirationMonth     |-> [i \in 1 .. 1 |-> 0],
      expirationDate      |-> [i \in 1 .. 1 |-> 0],
      explicitStrikePrice |-> [i \in 1 .. 4 |-> 0],
      optionType          |-> [i \in 1 .. 1 |-> 0],
      source              |-> [i \in 1 .. 1 |-> 0],
      underlyingSymbol    |-> [i \in 1 .. 13 |-> 0],
      optionsClosingType  |-> [i \in 1 .. 1 |-> 0],
      tradable            |-> [i \in 1 .. 1 |-> 0],
      mpv                 |-> [i \in 1 .. 1 |-> 0] ]

(* Option Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionDirectoryMessage ==
    { ZeroOptionDirectoryMessage }
        \cup { [ZeroOptionDirectoryMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOptionDirectoryMessage EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroOptionDirectoryMessage EXCEPT !.securitySymbol = one] : one \in Sample(6) }
        \cup { [ZeroOptionDirectoryMessage EXCEPT !.expirationYear = one] : one \in Sample(1) }
        \cup { [ZeroOptionDirectoryMessage EXCEPT !.expirationMonth = one] : one \in Sample(1) }
        \cup { [ZeroOptionDirectoryMessage EXCEPT !.expirationDate = one] : one \in Sample(1) }
        \cup { [ZeroOptionDirectoryMessage EXCEPT !.explicitStrikePrice = one] : one \in Sample(4) }
        \cup { [ZeroOptionDirectoryMessage EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroOptionDirectoryMessage EXCEPT !.source = one] : one \in Sample(1) }
        \cup { [ZeroOptionDirectoryMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(13) }
        \cup { [ZeroOptionDirectoryMessage EXCEPT !.optionsClosingType = one] : one \in Sample(1) }
        \cup { [ZeroOptionDirectoryMessage EXCEPT !.tradable = one] : one \in Sample(1) }
        \cup { [ZeroOptionDirectoryMessage EXCEPT !.mpv = one] : one \in Sample(1) }

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
(* Security Open Message: 9 bytes                                          *)
(***************************************************************************)

SecurityOpenMessage ==
    [ nanoseconds : Sample(4),
      optionId    : Sample(4),
      openState   : Sample(1) ]

EncodeSecurityOpenMessage(message) ==
    message.nanoseconds
        \o message.optionId
        \o message.openState

DecodeSecurityOpenMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET optionId == ReadBytes(nanoseconds.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET openState == ReadBytes(optionId.rest, 1) IN IF ~openState.ok THEN Fail ELSE
    Ok([ nanoseconds |-> nanoseconds.value,
         optionId    |-> optionId.value,
         openState   |-> openState.value ], openState.rest)

ZeroSecurityOpenMessage ==
    [ nanoseconds |-> [i \in 1 .. 4 |-> 0],
      optionId    |-> [i \in 1 .. 4 |-> 0],
      openState   |-> [i \in 1 .. 1 |-> 0] ]

(* Security Open Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityOpenMessage ==
    { ZeroSecurityOpenMessage }
        \cup { [ZeroSecurityOpenMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSecurityOpenMessage EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityOpenMessage EXCEPT !.openState = one] : one \in Sample(1) }

(***************************************************************************)
(* Add Order Short Message: 21 bytes                                       *)
(***************************************************************************)

AddOrderShortMessage ==
    [ nanoseconds               : Sample(4),
      orderReferenceNumberDelta : Sample(4),
      marketSide                : Sample(1),
      optionId                  : Sample(4),
      shortPrice                : Sample(2),
      shortVolume               : Sample(2),
      orderId                   : Sample(4) ]

EncodeAddOrderShortMessage(message) ==
    message.nanoseconds
        \o message.orderReferenceNumberDelta
        \o message.marketSide
        \o message.optionId
        \o message.shortPrice
        \o message.shortVolume
        \o message.orderId

DecodeAddOrderShortMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderReferenceNumberDelta == ReadBytes(nanoseconds.rest, 4) IN IF ~orderReferenceNumberDelta.ok THEN Fail ELSE
    LET marketSide == ReadBytes(orderReferenceNumberDelta.rest, 1) IN IF ~marketSide.ok THEN Fail ELSE
    LET optionId == ReadBytes(marketSide.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET shortPrice == ReadBytes(optionId.rest, 2) IN IF ~shortPrice.ok THEN Fail ELSE
    LET shortVolume == ReadBytes(shortPrice.rest, 2) IN IF ~shortVolume.ok THEN Fail ELSE
    LET orderId == ReadBytes(shortVolume.rest, 4) IN IF ~orderId.ok THEN Fail ELSE
    Ok([ nanoseconds               |-> nanoseconds.value,
         orderReferenceNumberDelta |-> orderReferenceNumberDelta.value,
         marketSide                |-> marketSide.value,
         optionId                  |-> optionId.value,
         shortPrice                |-> shortPrice.value,
         shortVolume               |-> shortVolume.value,
         orderId                   |-> orderId.value ], orderId.rest)

ZeroAddOrderShortMessage ==
    [ nanoseconds               |-> [i \in 1 .. 4 |-> 0],
      orderReferenceNumberDelta |-> [i \in 1 .. 4 |-> 0],
      marketSide                |-> [i \in 1 .. 1 |-> 0],
      optionId                  |-> [i \in 1 .. 4 |-> 0],
      shortPrice                |-> [i \in 1 .. 2 |-> 0],
      shortVolume               |-> [i \in 1 .. 2 |-> 0],
      orderId                   |-> [i \in 1 .. 4 |-> 0] ]

(* Add Order Short Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderShortMessage ==
    { ZeroAddOrderShortMessage }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.orderReferenceNumberDelta = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.marketSide = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.shortPrice = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.shortVolume = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.orderId = one] : one \in Sample(4) }

(***************************************************************************)
(* Add Order Long Message: 25 bytes                                        *)
(***************************************************************************)

AddOrderLongMessage ==
    [ nanoseconds               : Sample(4),
      orderReferenceNumberDelta : Sample(4),
      marketSide                : Sample(1),
      optionId                  : Sample(4),
      price                     : Sample(4),
      volume                    : Sample(4),
      orderId                   : Sample(4) ]

EncodeAddOrderLongMessage(message) ==
    message.nanoseconds
        \o message.orderReferenceNumberDelta
        \o message.marketSide
        \o message.optionId
        \o message.price
        \o message.volume
        \o message.orderId

DecodeAddOrderLongMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderReferenceNumberDelta == ReadBytes(nanoseconds.rest, 4) IN IF ~orderReferenceNumberDelta.ok THEN Fail ELSE
    LET marketSide == ReadBytes(orderReferenceNumberDelta.rest, 1) IN IF ~marketSide.ok THEN Fail ELSE
    LET optionId == ReadBytes(marketSide.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET price == ReadBytes(optionId.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET volume == ReadBytes(price.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET orderId == ReadBytes(volume.rest, 4) IN IF ~orderId.ok THEN Fail ELSE
    Ok([ nanoseconds               |-> nanoseconds.value,
         orderReferenceNumberDelta |-> orderReferenceNumberDelta.value,
         marketSide                |-> marketSide.value,
         optionId                  |-> optionId.value,
         price                     |-> price.value,
         volume                    |-> volume.value,
         orderId                   |-> orderId.value ], orderId.rest)

ZeroAddOrderLongMessage ==
    [ nanoseconds               |-> [i \in 1 .. 4 |-> 0],
      orderReferenceNumberDelta |-> [i \in 1 .. 4 |-> 0],
      marketSide                |-> [i \in 1 .. 1 |-> 0],
      optionId                  |-> [i \in 1 .. 4 |-> 0],
      price                     |-> [i \in 1 .. 4 |-> 0],
      volume                    |-> [i \in 1 .. 4 |-> 0],
      orderId                   |-> [i \in 1 .. 4 |-> 0] ]

(* Add Order Long Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderLongMessage ==
    { ZeroAddOrderLongMessage }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.orderReferenceNumberDelta = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.marketSide = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.orderId = one] : one \in Sample(4) }

(***************************************************************************)
(* Add Quote Short Message: 24 bytes                                       *)
(***************************************************************************)

AddQuoteShortMessage ==
    [ nanoseconds             : Sample(4),
      bidReferenceNumberDelta : Sample(4),
      askReferenceNumberDelta : Sample(4),
      optionId                : Sample(4),
      shortBidPrice           : Sample(2),
      shortBidSize            : Sample(2),
      shortAskPrice           : Sample(2),
      shortAskSize            : Sample(2) ]

EncodeAddQuoteShortMessage(message) ==
    message.nanoseconds
        \o message.bidReferenceNumberDelta
        \o message.askReferenceNumberDelta
        \o message.optionId
        \o message.shortBidPrice
        \o message.shortBidSize
        \o message.shortAskPrice
        \o message.shortAskSize

DecodeAddQuoteShortMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET bidReferenceNumberDelta == ReadBytes(nanoseconds.rest, 4) IN IF ~bidReferenceNumberDelta.ok THEN Fail ELSE
    LET askReferenceNumberDelta == ReadBytes(bidReferenceNumberDelta.rest, 4) IN IF ~askReferenceNumberDelta.ok THEN Fail ELSE
    LET optionId == ReadBytes(askReferenceNumberDelta.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET shortBidPrice == ReadBytes(optionId.rest, 2) IN IF ~shortBidPrice.ok THEN Fail ELSE
    LET shortBidSize == ReadBytes(shortBidPrice.rest, 2) IN IF ~shortBidSize.ok THEN Fail ELSE
    LET shortAskPrice == ReadBytes(shortBidSize.rest, 2) IN IF ~shortAskPrice.ok THEN Fail ELSE
    LET shortAskSize == ReadBytes(shortAskPrice.rest, 2) IN IF ~shortAskSize.ok THEN Fail ELSE
    Ok([ nanoseconds             |-> nanoseconds.value,
         bidReferenceNumberDelta |-> bidReferenceNumberDelta.value,
         askReferenceNumberDelta |-> askReferenceNumberDelta.value,
         optionId                |-> optionId.value,
         shortBidPrice           |-> shortBidPrice.value,
         shortBidSize            |-> shortBidSize.value,
         shortAskPrice           |-> shortAskPrice.value,
         shortAskSize            |-> shortAskSize.value ], shortAskSize.rest)

ZeroAddQuoteShortMessage ==
    [ nanoseconds             |-> [i \in 1 .. 4 |-> 0],
      bidReferenceNumberDelta |-> [i \in 1 .. 4 |-> 0],
      askReferenceNumberDelta |-> [i \in 1 .. 4 |-> 0],
      optionId                |-> [i \in 1 .. 4 |-> 0],
      shortBidPrice           |-> [i \in 1 .. 2 |-> 0],
      shortBidSize            |-> [i \in 1 .. 2 |-> 0],
      shortAskPrice           |-> [i \in 1 .. 2 |-> 0],
      shortAskSize            |-> [i \in 1 .. 2 |-> 0] ]

(* Add Quote Short Message at zero, then each field in turn at the values it is checked at *)
CheckedAddQuoteShortMessage ==
    { ZeroAddQuoteShortMessage }
        \cup { [ZeroAddQuoteShortMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroAddQuoteShortMessage EXCEPT !.bidReferenceNumberDelta = one] : one \in Sample(4) }
        \cup { [ZeroAddQuoteShortMessage EXCEPT !.askReferenceNumberDelta = one] : one \in Sample(4) }
        \cup { [ZeroAddQuoteShortMessage EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroAddQuoteShortMessage EXCEPT !.shortBidPrice = one] : one \in Sample(2) }
        \cup { [ZeroAddQuoteShortMessage EXCEPT !.shortBidSize = one] : one \in Sample(2) }
        \cup { [ZeroAddQuoteShortMessage EXCEPT !.shortAskPrice = one] : one \in Sample(2) }
        \cup { [ZeroAddQuoteShortMessage EXCEPT !.shortAskSize = one] : one \in Sample(2) }

(***************************************************************************)
(* Add Quote Long Message: 32 bytes                                        *)
(***************************************************************************)

AddQuoteLongMessage ==
    [ nanoseconds             : Sample(4),
      bidReferenceNumberDelta : Sample(4),
      askReferenceNumberDelta : Sample(4),
      optionId                : Sample(4),
      bidPrice                : Sample(4),
      bidSize                 : Sample(4),
      askPrice                : Sample(4),
      askSize                 : Sample(4) ]

EncodeAddQuoteLongMessage(message) ==
    message.nanoseconds
        \o message.bidReferenceNumberDelta
        \o message.askReferenceNumberDelta
        \o message.optionId
        \o message.bidPrice
        \o message.bidSize
        \o message.askPrice
        \o message.askSize

DecodeAddQuoteLongMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET bidReferenceNumberDelta == ReadBytes(nanoseconds.rest, 4) IN IF ~bidReferenceNumberDelta.ok THEN Fail ELSE
    LET askReferenceNumberDelta == ReadBytes(bidReferenceNumberDelta.rest, 4) IN IF ~askReferenceNumberDelta.ok THEN Fail ELSE
    LET optionId == ReadBytes(askReferenceNumberDelta.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(optionId.rest, 4) IN IF ~bidPrice.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPrice.rest, 4) IN IF ~bidSize.ok THEN Fail ELSE
    LET askPrice == ReadBytes(bidSize.rest, 4) IN IF ~askPrice.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPrice.rest, 4) IN IF ~askSize.ok THEN Fail ELSE
    Ok([ nanoseconds             |-> nanoseconds.value,
         bidReferenceNumberDelta |-> bidReferenceNumberDelta.value,
         askReferenceNumberDelta |-> askReferenceNumberDelta.value,
         optionId                |-> optionId.value,
         bidPrice                |-> bidPrice.value,
         bidSize                 |-> bidSize.value,
         askPrice                |-> askPrice.value,
         askSize                 |-> askSize.value ], askSize.rest)

ZeroAddQuoteLongMessage ==
    [ nanoseconds             |-> [i \in 1 .. 4 |-> 0],
      bidReferenceNumberDelta |-> [i \in 1 .. 4 |-> 0],
      askReferenceNumberDelta |-> [i \in 1 .. 4 |-> 0],
      optionId                |-> [i \in 1 .. 4 |-> 0],
      bidPrice                |-> [i \in 1 .. 4 |-> 0],
      bidSize                 |-> [i \in 1 .. 4 |-> 0],
      askPrice                |-> [i \in 1 .. 4 |-> 0],
      askSize                 |-> [i \in 1 .. 4 |-> 0] ]

(* Add Quote Long Message at zero, then each field in turn at the values it is checked at *)
CheckedAddQuoteLongMessage ==
    { ZeroAddQuoteLongMessage }
        \cup { [ZeroAddQuoteLongMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroAddQuoteLongMessage EXCEPT !.bidReferenceNumberDelta = one] : one \in Sample(4) }
        \cup { [ZeroAddQuoteLongMessage EXCEPT !.askReferenceNumberDelta = one] : one \in Sample(4) }
        \cup { [ZeroAddQuoteLongMessage EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroAddQuoteLongMessage EXCEPT !.bidPrice = one] : one \in Sample(4) }
        \cup { [ZeroAddQuoteLongMessage EXCEPT !.bidSize = one] : one \in Sample(4) }
        \cup { [ZeroAddQuoteLongMessage EXCEPT !.askPrice = one] : one \in Sample(4) }
        \cup { [ZeroAddQuoteLongMessage EXCEPT !.askSize = one] : one \in Sample(4) }

(***************************************************************************)
(* Single Side Executed Message: 20 bytes                                  *)
(***************************************************************************)

SingleSideExecutedMessage ==
    [ nanoseconds          : Sample(4),
      referenceNumberDelta : Sample(4),
      executedContracts    : Sample(4),
      crossNumber          : Sample(4),
      matchNumber          : Sample(4) ]

EncodeSingleSideExecutedMessage(message) ==
    message.nanoseconds
        \o message.referenceNumberDelta
        \o message.executedContracts
        \o message.crossNumber
        \o message.matchNumber

DecodeSingleSideExecutedMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET referenceNumberDelta == ReadBytes(nanoseconds.rest, 4) IN IF ~referenceNumberDelta.ok THEN Fail ELSE
    LET executedContracts == ReadBytes(referenceNumberDelta.rest, 4) IN IF ~executedContracts.ok THEN Fail ELSE
    LET crossNumber == ReadBytes(executedContracts.rest, 4) IN IF ~crossNumber.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(crossNumber.rest, 4) IN IF ~matchNumber.ok THEN Fail ELSE
    Ok([ nanoseconds          |-> nanoseconds.value,
         referenceNumberDelta |-> referenceNumberDelta.value,
         executedContracts    |-> executedContracts.value,
         crossNumber          |-> crossNumber.value,
         matchNumber          |-> matchNumber.value ], matchNumber.rest)

ZeroSingleSideExecutedMessage ==
    [ nanoseconds          |-> [i \in 1 .. 4 |-> 0],
      referenceNumberDelta |-> [i \in 1 .. 4 |-> 0],
      executedContracts    |-> [i \in 1 .. 4 |-> 0],
      crossNumber          |-> [i \in 1 .. 4 |-> 0],
      matchNumber          |-> [i \in 1 .. 4 |-> 0] ]

(* Single Side Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleSideExecutedMessage ==
    { ZeroSingleSideExecutedMessage }
        \cup { [ZeroSingleSideExecutedMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideExecutedMessage EXCEPT !.referenceNumberDelta = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideExecutedMessage EXCEPT !.executedContracts = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideExecutedMessage EXCEPT !.crossNumber = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideExecutedMessage EXCEPT !.matchNumber = one] : one \in Sample(4) }

(***************************************************************************)
(* Single Side Executed With Price Message: 25 bytes                       *)
(***************************************************************************)

SingleSideExecutedWithPriceMessage ==
    [ nanoseconds          : Sample(4),
      referenceNumberDelta : Sample(4),
      crossNumber          : Sample(4),
      matchNumber          : Sample(4),
      printable            : Sample(1),
      price                : Sample(4),
      volume               : Sample(4) ]

EncodeSingleSideExecutedWithPriceMessage(message) ==
    message.nanoseconds
        \o message.referenceNumberDelta
        \o message.crossNumber
        \o message.matchNumber
        \o message.printable
        \o message.price
        \o message.volume

DecodeSingleSideExecutedWithPriceMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET referenceNumberDelta == ReadBytes(nanoseconds.rest, 4) IN IF ~referenceNumberDelta.ok THEN Fail ELSE
    LET crossNumber == ReadBytes(referenceNumberDelta.rest, 4) IN IF ~crossNumber.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(crossNumber.rest, 4) IN IF ~matchNumber.ok THEN Fail ELSE
    LET printable == ReadBytes(matchNumber.rest, 1) IN IF ~printable.ok THEN Fail ELSE
    LET price == ReadBytes(printable.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET volume == ReadBytes(price.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    Ok([ nanoseconds          |-> nanoseconds.value,
         referenceNumberDelta |-> referenceNumberDelta.value,
         crossNumber          |-> crossNumber.value,
         matchNumber          |-> matchNumber.value,
         printable            |-> printable.value,
         price                |-> price.value,
         volume               |-> volume.value ], volume.rest)

ZeroSingleSideExecutedWithPriceMessage ==
    [ nanoseconds          |-> [i \in 1 .. 4 |-> 0],
      referenceNumberDelta |-> [i \in 1 .. 4 |-> 0],
      crossNumber          |-> [i \in 1 .. 4 |-> 0],
      matchNumber          |-> [i \in 1 .. 4 |-> 0],
      printable            |-> [i \in 1 .. 1 |-> 0],
      price                |-> [i \in 1 .. 4 |-> 0],
      volume               |-> [i \in 1 .. 4 |-> 0] ]

(* Single Side Executed With Price Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleSideExecutedWithPriceMessage ==
    { ZeroSingleSideExecutedWithPriceMessage }
        \cup { [ZeroSingleSideExecutedWithPriceMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideExecutedWithPriceMessage EXCEPT !.referenceNumberDelta = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideExecutedWithPriceMessage EXCEPT !.crossNumber = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideExecutedWithPriceMessage EXCEPT !.matchNumber = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideExecutedWithPriceMessage EXCEPT !.printable = one] : one \in Sample(1) }
        \cup { [ZeroSingleSideExecutedWithPriceMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideExecutedWithPriceMessage EXCEPT !.volume = one] : one \in Sample(4) }

(***************************************************************************)
(* Single Side Cancel Message: 12 bytes                                    *)
(***************************************************************************)

SingleSideCancelMessage ==
    [ nanoseconds          : Sample(4),
      referenceNumberDelta : Sample(4),
      cancelledContracts   : Sample(4) ]

EncodeSingleSideCancelMessage(message) ==
    message.nanoseconds
        \o message.referenceNumberDelta
        \o message.cancelledContracts

DecodeSingleSideCancelMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET referenceNumberDelta == ReadBytes(nanoseconds.rest, 4) IN IF ~referenceNumberDelta.ok THEN Fail ELSE
    LET cancelledContracts == ReadBytes(referenceNumberDelta.rest, 4) IN IF ~cancelledContracts.ok THEN Fail ELSE
    Ok([ nanoseconds          |-> nanoseconds.value,
         referenceNumberDelta |-> referenceNumberDelta.value,
         cancelledContracts   |-> cancelledContracts.value ], cancelledContracts.rest)

ZeroSingleSideCancelMessage ==
    [ nanoseconds          |-> [i \in 1 .. 4 |-> 0],
      referenceNumberDelta |-> [i \in 1 .. 4 |-> 0],
      cancelledContracts   |-> [i \in 1 .. 4 |-> 0] ]

(* Single Side Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleSideCancelMessage ==
    { ZeroSingleSideCancelMessage }
        \cup { [ZeroSingleSideCancelMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideCancelMessage EXCEPT !.referenceNumberDelta = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideCancelMessage EXCEPT !.cancelledContracts = one] : one \in Sample(4) }

(***************************************************************************)
(* Single Side Replace Short Message: 16 bytes                             *)
(***************************************************************************)

SingleSideReplaceShortMessage ==
    [ nanoseconds                  : Sample(4),
      originalReferenceNumberDelta : Sample(4),
      newReferenceNumberDelta      : Sample(4),
      shortPrice                   : Sample(2),
      shortVolume                  : Sample(2) ]

EncodeSingleSideReplaceShortMessage(message) ==
    message.nanoseconds
        \o message.originalReferenceNumberDelta
        \o message.newReferenceNumberDelta
        \o message.shortPrice
        \o message.shortVolume

DecodeSingleSideReplaceShortMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET originalReferenceNumberDelta == ReadBytes(nanoseconds.rest, 4) IN IF ~originalReferenceNumberDelta.ok THEN Fail ELSE
    LET newReferenceNumberDelta == ReadBytes(originalReferenceNumberDelta.rest, 4) IN IF ~newReferenceNumberDelta.ok THEN Fail ELSE
    LET shortPrice == ReadBytes(newReferenceNumberDelta.rest, 2) IN IF ~shortPrice.ok THEN Fail ELSE
    LET shortVolume == ReadBytes(shortPrice.rest, 2) IN IF ~shortVolume.ok THEN Fail ELSE
    Ok([ nanoseconds                  |-> nanoseconds.value,
         originalReferenceNumberDelta |-> originalReferenceNumberDelta.value,
         newReferenceNumberDelta      |-> newReferenceNumberDelta.value,
         shortPrice                   |-> shortPrice.value,
         shortVolume                  |-> shortVolume.value ], shortVolume.rest)

ZeroSingleSideReplaceShortMessage ==
    [ nanoseconds                  |-> [i \in 1 .. 4 |-> 0],
      originalReferenceNumberDelta |-> [i \in 1 .. 4 |-> 0],
      newReferenceNumberDelta      |-> [i \in 1 .. 4 |-> 0],
      shortPrice                   |-> [i \in 1 .. 2 |-> 0],
      shortVolume                  |-> [i \in 1 .. 2 |-> 0] ]

(* Single Side Replace Short Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleSideReplaceShortMessage ==
    { ZeroSingleSideReplaceShortMessage }
        \cup { [ZeroSingleSideReplaceShortMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideReplaceShortMessage EXCEPT !.originalReferenceNumberDelta = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideReplaceShortMessage EXCEPT !.newReferenceNumberDelta = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideReplaceShortMessage EXCEPT !.shortPrice = one] : one \in Sample(2) }
        \cup { [ZeroSingleSideReplaceShortMessage EXCEPT !.shortVolume = one] : one \in Sample(2) }

(***************************************************************************)
(* Single Side Replace Long Message: 20 bytes                              *)
(***************************************************************************)

SingleSideReplaceLongMessage ==
    [ nanoseconds                  : Sample(4),
      originalReferenceNumberDelta : Sample(4),
      newReferenceNumberDelta      : Sample(4),
      price                        : Sample(4),
      volume                       : Sample(4) ]

EncodeSingleSideReplaceLongMessage(message) ==
    message.nanoseconds
        \o message.originalReferenceNumberDelta
        \o message.newReferenceNumberDelta
        \o message.price
        \o message.volume

DecodeSingleSideReplaceLongMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET originalReferenceNumberDelta == ReadBytes(nanoseconds.rest, 4) IN IF ~originalReferenceNumberDelta.ok THEN Fail ELSE
    LET newReferenceNumberDelta == ReadBytes(originalReferenceNumberDelta.rest, 4) IN IF ~newReferenceNumberDelta.ok THEN Fail ELSE
    LET price == ReadBytes(newReferenceNumberDelta.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET volume == ReadBytes(price.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    Ok([ nanoseconds                  |-> nanoseconds.value,
         originalReferenceNumberDelta |-> originalReferenceNumberDelta.value,
         newReferenceNumberDelta      |-> newReferenceNumberDelta.value,
         price                        |-> price.value,
         volume                       |-> volume.value ], volume.rest)

ZeroSingleSideReplaceLongMessage ==
    [ nanoseconds                  |-> [i \in 1 .. 4 |-> 0],
      originalReferenceNumberDelta |-> [i \in 1 .. 4 |-> 0],
      newReferenceNumberDelta      |-> [i \in 1 .. 4 |-> 0],
      price                        |-> [i \in 1 .. 4 |-> 0],
      volume                       |-> [i \in 1 .. 4 |-> 0] ]

(* Single Side Replace Long Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleSideReplaceLongMessage ==
    { ZeroSingleSideReplaceLongMessage }
        \cup { [ZeroSingleSideReplaceLongMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideReplaceLongMessage EXCEPT !.originalReferenceNumberDelta = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideReplaceLongMessage EXCEPT !.newReferenceNumberDelta = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideReplaceLongMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideReplaceLongMessage EXCEPT !.volume = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Replace Short Message: 20 bytes                                   *)
(***************************************************************************)

OrderReplaceShortMessage ==
    [ nanoseconds                  : Sample(4),
      originalReferenceNumberDelta : Sample(4),
      newReferenceNumberDelta      : Sample(4),
      shortPrice                   : Sample(2),
      shortVolume                  : Sample(2),
      orderId                      : Sample(4) ]

EncodeOrderReplaceShortMessage(message) ==
    message.nanoseconds
        \o message.originalReferenceNumberDelta
        \o message.newReferenceNumberDelta
        \o message.shortPrice
        \o message.shortVolume
        \o message.orderId

DecodeOrderReplaceShortMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET originalReferenceNumberDelta == ReadBytes(nanoseconds.rest, 4) IN IF ~originalReferenceNumberDelta.ok THEN Fail ELSE
    LET newReferenceNumberDelta == ReadBytes(originalReferenceNumberDelta.rest, 4) IN IF ~newReferenceNumberDelta.ok THEN Fail ELSE
    LET shortPrice == ReadBytes(newReferenceNumberDelta.rest, 2) IN IF ~shortPrice.ok THEN Fail ELSE
    LET shortVolume == ReadBytes(shortPrice.rest, 2) IN IF ~shortVolume.ok THEN Fail ELSE
    LET orderId == ReadBytes(shortVolume.rest, 4) IN IF ~orderId.ok THEN Fail ELSE
    Ok([ nanoseconds                  |-> nanoseconds.value,
         originalReferenceNumberDelta |-> originalReferenceNumberDelta.value,
         newReferenceNumberDelta      |-> newReferenceNumberDelta.value,
         shortPrice                   |-> shortPrice.value,
         shortVolume                  |-> shortVolume.value,
         orderId                      |-> orderId.value ], orderId.rest)

ZeroOrderReplaceShortMessage ==
    [ nanoseconds                  |-> [i \in 1 .. 4 |-> 0],
      originalReferenceNumberDelta |-> [i \in 1 .. 4 |-> 0],
      newReferenceNumberDelta      |-> [i \in 1 .. 4 |-> 0],
      shortPrice                   |-> [i \in 1 .. 2 |-> 0],
      shortVolume                  |-> [i \in 1 .. 2 |-> 0],
      orderId                      |-> [i \in 1 .. 4 |-> 0] ]

(* Order Replace Short Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderReplaceShortMessage ==
    { ZeroOrderReplaceShortMessage }
        \cup { [ZeroOrderReplaceShortMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplaceShortMessage EXCEPT !.originalReferenceNumberDelta = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplaceShortMessage EXCEPT !.newReferenceNumberDelta = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplaceShortMessage EXCEPT !.shortPrice = one] : one \in Sample(2) }
        \cup { [ZeroOrderReplaceShortMessage EXCEPT !.shortVolume = one] : one \in Sample(2) }
        \cup { [ZeroOrderReplaceShortMessage EXCEPT !.orderId = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Replace Long Message: 24 bytes                                    *)
(***************************************************************************)

OrderReplaceLongMessage ==
    [ nanoseconds                  : Sample(4),
      originalReferenceNumberDelta : Sample(4),
      newReferenceNumberDelta      : Sample(4),
      price                        : Sample(4),
      volume                       : Sample(4),
      orderId                      : Sample(4) ]

EncodeOrderReplaceLongMessage(message) ==
    message.nanoseconds
        \o message.originalReferenceNumberDelta
        \o message.newReferenceNumberDelta
        \o message.price
        \o message.volume
        \o message.orderId

DecodeOrderReplaceLongMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET originalReferenceNumberDelta == ReadBytes(nanoseconds.rest, 4) IN IF ~originalReferenceNumberDelta.ok THEN Fail ELSE
    LET newReferenceNumberDelta == ReadBytes(originalReferenceNumberDelta.rest, 4) IN IF ~newReferenceNumberDelta.ok THEN Fail ELSE
    LET price == ReadBytes(newReferenceNumberDelta.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET volume == ReadBytes(price.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET orderId == ReadBytes(volume.rest, 4) IN IF ~orderId.ok THEN Fail ELSE
    Ok([ nanoseconds                  |-> nanoseconds.value,
         originalReferenceNumberDelta |-> originalReferenceNumberDelta.value,
         newReferenceNumberDelta      |-> newReferenceNumberDelta.value,
         price                        |-> price.value,
         volume                       |-> volume.value,
         orderId                      |-> orderId.value ], orderId.rest)

ZeroOrderReplaceLongMessage ==
    [ nanoseconds                  |-> [i \in 1 .. 4 |-> 0],
      originalReferenceNumberDelta |-> [i \in 1 .. 4 |-> 0],
      newReferenceNumberDelta      |-> [i \in 1 .. 4 |-> 0],
      price                        |-> [i \in 1 .. 4 |-> 0],
      volume                       |-> [i \in 1 .. 4 |-> 0],
      orderId                      |-> [i \in 1 .. 4 |-> 0] ]

(* Order Replace Long Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderReplaceLongMessage ==
    { ZeroOrderReplaceLongMessage }
        \cup { [ZeroOrderReplaceLongMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplaceLongMessage EXCEPT !.originalReferenceNumberDelta = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplaceLongMessage EXCEPT !.newReferenceNumberDelta = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplaceLongMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplaceLongMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplaceLongMessage EXCEPT !.orderId = one] : one \in Sample(4) }

(***************************************************************************)
(* Single Side Delete Message: 8 bytes                                     *)
(***************************************************************************)

SingleSideDeleteMessage ==
    [ nanoseconds          : Sample(4),
      referenceNumberDelta : Sample(4) ]

EncodeSingleSideDeleteMessage(message) ==
    message.nanoseconds
        \o message.referenceNumberDelta

DecodeSingleSideDeleteMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET referenceNumberDelta == ReadBytes(nanoseconds.rest, 4) IN IF ~referenceNumberDelta.ok THEN Fail ELSE
    Ok([ nanoseconds          |-> nanoseconds.value,
         referenceNumberDelta |-> referenceNumberDelta.value ], referenceNumberDelta.rest)

ZeroSingleSideDeleteMessage ==
    [ nanoseconds          |-> [i \in 1 .. 4 |-> 0],
      referenceNumberDelta |-> [i \in 1 .. 4 |-> 0] ]

(* Single Side Delete Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleSideDeleteMessage ==
    { ZeroSingleSideDeleteMessage }
        \cup { [ZeroSingleSideDeleteMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideDeleteMessage EXCEPT !.referenceNumberDelta = one] : one \in Sample(4) }

(***************************************************************************)
(* Single Side Update Message: 17 bytes                                    *)
(***************************************************************************)

SingleSideUpdateMessage ==
    [ nanoseconds          : Sample(4),
      referenceNumberDelta : Sample(4),
      changeReason         : Sample(1),
      price                : Sample(4),
      volume               : Sample(4) ]

EncodeSingleSideUpdateMessage(message) ==
    message.nanoseconds
        \o message.referenceNumberDelta
        \o message.changeReason
        \o message.price
        \o message.volume

DecodeSingleSideUpdateMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET referenceNumberDelta == ReadBytes(nanoseconds.rest, 4) IN IF ~referenceNumberDelta.ok THEN Fail ELSE
    LET changeReason == ReadBytes(referenceNumberDelta.rest, 1) IN IF ~changeReason.ok THEN Fail ELSE
    LET price == ReadBytes(changeReason.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET volume == ReadBytes(price.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    Ok([ nanoseconds          |-> nanoseconds.value,
         referenceNumberDelta |-> referenceNumberDelta.value,
         changeReason         |-> changeReason.value,
         price                |-> price.value,
         volume               |-> volume.value ], volume.rest)

ZeroSingleSideUpdateMessage ==
    [ nanoseconds          |-> [i \in 1 .. 4 |-> 0],
      referenceNumberDelta |-> [i \in 1 .. 4 |-> 0],
      changeReason         |-> [i \in 1 .. 1 |-> 0],
      price                |-> [i \in 1 .. 4 |-> 0],
      volume               |-> [i \in 1 .. 4 |-> 0] ]

(* Single Side Update Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleSideUpdateMessage ==
    { ZeroSingleSideUpdateMessage }
        \cup { [ZeroSingleSideUpdateMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideUpdateMessage EXCEPT !.referenceNumberDelta = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideUpdateMessage EXCEPT !.changeReason = one] : one \in Sample(1) }
        \cup { [ZeroSingleSideUpdateMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideUpdateMessage EXCEPT !.volume = one] : one \in Sample(4) }

(***************************************************************************)
(* Quote Replace Short Message: 28 bytes                                   *)
(***************************************************************************)

QuoteReplaceShortMessage ==
    [ nanoseconds                     : Sample(4),
      originalBidReferenceNumberDelta : Sample(4),
      bidReferenceNumberDelta         : Sample(4),
      originalAskReferenceNumberDelta : Sample(4),
      askReferenceNumberDelta         : Sample(4),
      shortBidPrice                   : Sample(2),
      shortBidSize                    : Sample(2),
      shortAskPrice                   : Sample(2),
      shortAskSize                    : Sample(2) ]

EncodeQuoteReplaceShortMessage(message) ==
    message.nanoseconds
        \o message.originalBidReferenceNumberDelta
        \o message.bidReferenceNumberDelta
        \o message.originalAskReferenceNumberDelta
        \o message.askReferenceNumberDelta
        \o message.shortBidPrice
        \o message.shortBidSize
        \o message.shortAskPrice
        \o message.shortAskSize

DecodeQuoteReplaceShortMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET originalBidReferenceNumberDelta == ReadBytes(nanoseconds.rest, 4) IN IF ~originalBidReferenceNumberDelta.ok THEN Fail ELSE
    LET bidReferenceNumberDelta == ReadBytes(originalBidReferenceNumberDelta.rest, 4) IN IF ~bidReferenceNumberDelta.ok THEN Fail ELSE
    LET originalAskReferenceNumberDelta == ReadBytes(bidReferenceNumberDelta.rest, 4) IN IF ~originalAskReferenceNumberDelta.ok THEN Fail ELSE
    LET askReferenceNumberDelta == ReadBytes(originalAskReferenceNumberDelta.rest, 4) IN IF ~askReferenceNumberDelta.ok THEN Fail ELSE
    LET shortBidPrice == ReadBytes(askReferenceNumberDelta.rest, 2) IN IF ~shortBidPrice.ok THEN Fail ELSE
    LET shortBidSize == ReadBytes(shortBidPrice.rest, 2) IN IF ~shortBidSize.ok THEN Fail ELSE
    LET shortAskPrice == ReadBytes(shortBidSize.rest, 2) IN IF ~shortAskPrice.ok THEN Fail ELSE
    LET shortAskSize == ReadBytes(shortAskPrice.rest, 2) IN IF ~shortAskSize.ok THEN Fail ELSE
    Ok([ nanoseconds                     |-> nanoseconds.value,
         originalBidReferenceNumberDelta |-> originalBidReferenceNumberDelta.value,
         bidReferenceNumberDelta         |-> bidReferenceNumberDelta.value,
         originalAskReferenceNumberDelta |-> originalAskReferenceNumberDelta.value,
         askReferenceNumberDelta         |-> askReferenceNumberDelta.value,
         shortBidPrice                   |-> shortBidPrice.value,
         shortBidSize                    |-> shortBidSize.value,
         shortAskPrice                   |-> shortAskPrice.value,
         shortAskSize                    |-> shortAskSize.value ], shortAskSize.rest)

ZeroQuoteReplaceShortMessage ==
    [ nanoseconds                     |-> [i \in 1 .. 4 |-> 0],
      originalBidReferenceNumberDelta |-> [i \in 1 .. 4 |-> 0],
      bidReferenceNumberDelta         |-> [i \in 1 .. 4 |-> 0],
      originalAskReferenceNumberDelta |-> [i \in 1 .. 4 |-> 0],
      askReferenceNumberDelta         |-> [i \in 1 .. 4 |-> 0],
      shortBidPrice                   |-> [i \in 1 .. 2 |-> 0],
      shortBidSize                    |-> [i \in 1 .. 2 |-> 0],
      shortAskPrice                   |-> [i \in 1 .. 2 |-> 0],
      shortAskSize                    |-> [i \in 1 .. 2 |-> 0] ]

(* Quote Replace Short Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteReplaceShortMessage ==
    { ZeroQuoteReplaceShortMessage }
        \cup { [ZeroQuoteReplaceShortMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroQuoteReplaceShortMessage EXCEPT !.originalBidReferenceNumberDelta = one] : one \in Sample(4) }
        \cup { [ZeroQuoteReplaceShortMessage EXCEPT !.bidReferenceNumberDelta = one] : one \in Sample(4) }
        \cup { [ZeroQuoteReplaceShortMessage EXCEPT !.originalAskReferenceNumberDelta = one] : one \in Sample(4) }
        \cup { [ZeroQuoteReplaceShortMessage EXCEPT !.askReferenceNumberDelta = one] : one \in Sample(4) }
        \cup { [ZeroQuoteReplaceShortMessage EXCEPT !.shortBidPrice = one] : one \in Sample(2) }
        \cup { [ZeroQuoteReplaceShortMessage EXCEPT !.shortBidSize = one] : one \in Sample(2) }
        \cup { [ZeroQuoteReplaceShortMessage EXCEPT !.shortAskPrice = one] : one \in Sample(2) }
        \cup { [ZeroQuoteReplaceShortMessage EXCEPT !.shortAskSize = one] : one \in Sample(2) }

(***************************************************************************)
(* Quote Replace Long Message: 36 bytes                                    *)
(***************************************************************************)

QuoteReplaceLongMessage ==
    [ nanoseconds                     : Sample(4),
      originalBidReferenceNumberDelta : Sample(4),
      bidReferenceNumberDelta         : Sample(4),
      originalAskReferenceNumberDelta : Sample(4),
      askReferenceNumberDelta         : Sample(4),
      bidPrice                        : Sample(4),
      bidSize                         : Sample(4),
      askPrice                        : Sample(4),
      askSize                         : Sample(4) ]

EncodeQuoteReplaceLongMessage(message) ==
    message.nanoseconds
        \o message.originalBidReferenceNumberDelta
        \o message.bidReferenceNumberDelta
        \o message.originalAskReferenceNumberDelta
        \o message.askReferenceNumberDelta
        \o message.bidPrice
        \o message.bidSize
        \o message.askPrice
        \o message.askSize

DecodeQuoteReplaceLongMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET originalBidReferenceNumberDelta == ReadBytes(nanoseconds.rest, 4) IN IF ~originalBidReferenceNumberDelta.ok THEN Fail ELSE
    LET bidReferenceNumberDelta == ReadBytes(originalBidReferenceNumberDelta.rest, 4) IN IF ~bidReferenceNumberDelta.ok THEN Fail ELSE
    LET originalAskReferenceNumberDelta == ReadBytes(bidReferenceNumberDelta.rest, 4) IN IF ~originalAskReferenceNumberDelta.ok THEN Fail ELSE
    LET askReferenceNumberDelta == ReadBytes(originalAskReferenceNumberDelta.rest, 4) IN IF ~askReferenceNumberDelta.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(askReferenceNumberDelta.rest, 4) IN IF ~bidPrice.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPrice.rest, 4) IN IF ~bidSize.ok THEN Fail ELSE
    LET askPrice == ReadBytes(bidSize.rest, 4) IN IF ~askPrice.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPrice.rest, 4) IN IF ~askSize.ok THEN Fail ELSE
    Ok([ nanoseconds                     |-> nanoseconds.value,
         originalBidReferenceNumberDelta |-> originalBidReferenceNumberDelta.value,
         bidReferenceNumberDelta         |-> bidReferenceNumberDelta.value,
         originalAskReferenceNumberDelta |-> originalAskReferenceNumberDelta.value,
         askReferenceNumberDelta         |-> askReferenceNumberDelta.value,
         bidPrice                        |-> bidPrice.value,
         bidSize                         |-> bidSize.value,
         askPrice                        |-> askPrice.value,
         askSize                         |-> askSize.value ], askSize.rest)

ZeroQuoteReplaceLongMessage ==
    [ nanoseconds                     |-> [i \in 1 .. 4 |-> 0],
      originalBidReferenceNumberDelta |-> [i \in 1 .. 4 |-> 0],
      bidReferenceNumberDelta         |-> [i \in 1 .. 4 |-> 0],
      originalAskReferenceNumberDelta |-> [i \in 1 .. 4 |-> 0],
      askReferenceNumberDelta         |-> [i \in 1 .. 4 |-> 0],
      bidPrice                        |-> [i \in 1 .. 4 |-> 0],
      bidSize                         |-> [i \in 1 .. 4 |-> 0],
      askPrice                        |-> [i \in 1 .. 4 |-> 0],
      askSize                         |-> [i \in 1 .. 4 |-> 0] ]

(* Quote Replace Long Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteReplaceLongMessage ==
    { ZeroQuoteReplaceLongMessage }
        \cup { [ZeroQuoteReplaceLongMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroQuoteReplaceLongMessage EXCEPT !.originalBidReferenceNumberDelta = one] : one \in Sample(4) }
        \cup { [ZeroQuoteReplaceLongMessage EXCEPT !.bidReferenceNumberDelta = one] : one \in Sample(4) }
        \cup { [ZeroQuoteReplaceLongMessage EXCEPT !.originalAskReferenceNumberDelta = one] : one \in Sample(4) }
        \cup { [ZeroQuoteReplaceLongMessage EXCEPT !.askReferenceNumberDelta = one] : one \in Sample(4) }
        \cup { [ZeroQuoteReplaceLongMessage EXCEPT !.bidPrice = one] : one \in Sample(4) }
        \cup { [ZeroQuoteReplaceLongMessage EXCEPT !.bidSize = one] : one \in Sample(4) }
        \cup { [ZeroQuoteReplaceLongMessage EXCEPT !.askPrice = one] : one \in Sample(4) }
        \cup { [ZeroQuoteReplaceLongMessage EXCEPT !.askSize = one] : one \in Sample(4) }

(***************************************************************************)
(* Quote Delete Message: 12 bytes                                          *)
(***************************************************************************)

QuoteDeleteMessage ==
    [ nanoseconds             : Sample(4),
      bidReferenceNumberDelta : Sample(4),
      askReferenceNumberDelta : Sample(4) ]

EncodeQuoteDeleteMessage(message) ==
    message.nanoseconds
        \o message.bidReferenceNumberDelta
        \o message.askReferenceNumberDelta

DecodeQuoteDeleteMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET bidReferenceNumberDelta == ReadBytes(nanoseconds.rest, 4) IN IF ~bidReferenceNumberDelta.ok THEN Fail ELSE
    LET askReferenceNumberDelta == ReadBytes(bidReferenceNumberDelta.rest, 4) IN IF ~askReferenceNumberDelta.ok THEN Fail ELSE
    Ok([ nanoseconds             |-> nanoseconds.value,
         bidReferenceNumberDelta |-> bidReferenceNumberDelta.value,
         askReferenceNumberDelta |-> askReferenceNumberDelta.value ], askReferenceNumberDelta.rest)

ZeroQuoteDeleteMessage ==
    [ nanoseconds             |-> [i \in 1 .. 4 |-> 0],
      bidReferenceNumberDelta |-> [i \in 1 .. 4 |-> 0],
      askReferenceNumberDelta |-> [i \in 1 .. 4 |-> 0] ]

(* Quote Delete Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteDeleteMessage ==
    { ZeroQuoteDeleteMessage }
        \cup { [ZeroQuoteDeleteMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroQuoteDeleteMessage EXCEPT !.bidReferenceNumberDelta = one] : one \in Sample(4) }
        \cup { [ZeroQuoteDeleteMessage EXCEPT !.askReferenceNumberDelta = one] : one \in Sample(4) }

(***************************************************************************)
(* Block Delete Message: 10 bytes                                          *)
(***************************************************************************)

BlockDeleteMessage ==
    [ nanoseconds                   : Sample(4),
      numberOfReferenceNumberDeltas : Sample(2),
      referenceNumberDelta          : Sample(4) ]

EncodeBlockDeleteMessage(message) ==
    message.nanoseconds
        \o message.numberOfReferenceNumberDeltas
        \o message.referenceNumberDelta

DecodeBlockDeleteMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET numberOfReferenceNumberDeltas == ReadBytes(nanoseconds.rest, 2) IN IF ~numberOfReferenceNumberDeltas.ok THEN Fail ELSE
    LET referenceNumberDelta == ReadBytes(numberOfReferenceNumberDeltas.rest, 4) IN IF ~referenceNumberDelta.ok THEN Fail ELSE
    Ok([ nanoseconds                   |-> nanoseconds.value,
         numberOfReferenceNumberDeltas |-> numberOfReferenceNumberDeltas.value,
         referenceNumberDelta          |-> referenceNumberDelta.value ], referenceNumberDelta.rest)

ZeroBlockDeleteMessage ==
    [ nanoseconds                   |-> [i \in 1 .. 4 |-> 0],
      numberOfReferenceNumberDeltas |-> [i \in 1 .. 2 |-> 0],
      referenceNumberDelta          |-> [i \in 1 .. 4 |-> 0] ]

(* Block Delete Message at zero, then each field in turn at the values it is checked at *)
CheckedBlockDeleteMessage ==
    { ZeroBlockDeleteMessage }
        \cup { [ZeroBlockDeleteMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroBlockDeleteMessage EXCEPT !.numberOfReferenceNumberDeltas = one] : one \in Sample(2) }
        \cup { [ZeroBlockDeleteMessage EXCEPT !.referenceNumberDelta = one] : one \in Sample(4) }

(***************************************************************************)
(* Non Auction Options Trade Message: 25 bytes                             *)
(***************************************************************************)

NonAuctionOptionsTradeMessage ==
    [ nanoseconds    : Sample(4),
      tradeIndicator : Sample(1),
      optionId       : Sample(4),
      crossNumber    : Sample(4),
      matchNumber    : Sample(4),
      price          : Sample(4),
      volume         : Sample(4) ]

EncodeNonAuctionOptionsTradeMessage(message) ==
    message.nanoseconds
        \o message.tradeIndicator
        \o message.optionId
        \o message.crossNumber
        \o message.matchNumber
        \o message.price
        \o message.volume

DecodeNonAuctionOptionsTradeMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET tradeIndicator == ReadBytes(nanoseconds.rest, 1) IN IF ~tradeIndicator.ok THEN Fail ELSE
    LET optionId == ReadBytes(tradeIndicator.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET crossNumber == ReadBytes(optionId.rest, 4) IN IF ~crossNumber.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(crossNumber.rest, 4) IN IF ~matchNumber.ok THEN Fail ELSE
    LET price == ReadBytes(matchNumber.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET volume == ReadBytes(price.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    Ok([ nanoseconds    |-> nanoseconds.value,
         tradeIndicator |-> tradeIndicator.value,
         optionId       |-> optionId.value,
         crossNumber    |-> crossNumber.value,
         matchNumber    |-> matchNumber.value,
         price          |-> price.value,
         volume         |-> volume.value ], volume.rest)

ZeroNonAuctionOptionsTradeMessage ==
    [ nanoseconds    |-> [i \in 1 .. 4 |-> 0],
      tradeIndicator |-> [i \in 1 .. 1 |-> 0],
      optionId       |-> [i \in 1 .. 4 |-> 0],
      crossNumber    |-> [i \in 1 .. 4 |-> 0],
      matchNumber    |-> [i \in 1 .. 4 |-> 0],
      price          |-> [i \in 1 .. 4 |-> 0],
      volume         |-> [i \in 1 .. 4 |-> 0] ]

(* Non Auction Options Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedNonAuctionOptionsTradeMessage ==
    { ZeroNonAuctionOptionsTradeMessage }
        \cup { [ZeroNonAuctionOptionsTradeMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroNonAuctionOptionsTradeMessage EXCEPT !.tradeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroNonAuctionOptionsTradeMessage EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroNonAuctionOptionsTradeMessage EXCEPT !.crossNumber = one] : one \in Sample(4) }
        \cup { [ZeroNonAuctionOptionsTradeMessage EXCEPT !.matchNumber = one] : one \in Sample(4) }
        \cup { [ZeroNonAuctionOptionsTradeMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroNonAuctionOptionsTradeMessage EXCEPT !.volume = one] : one \in Sample(4) }

(***************************************************************************)
(* Options Cross Trade Message: 25 bytes                                   *)
(***************************************************************************)

OptionsCrossTradeMessage ==
    [ nanoseconds : Sample(4),
      optionId    : Sample(4),
      crossNumber : Sample(4),
      matchNumber : Sample(4),
      crossType   : Sample(1),
      price       : Sample(4),
      volume      : Sample(4) ]

EncodeOptionsCrossTradeMessage(message) ==
    message.nanoseconds
        \o message.optionId
        \o message.crossNumber
        \o message.matchNumber
        \o message.crossType
        \o message.price
        \o message.volume

DecodeOptionsCrossTradeMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET optionId == ReadBytes(nanoseconds.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET crossNumber == ReadBytes(optionId.rest, 4) IN IF ~crossNumber.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(crossNumber.rest, 4) IN IF ~matchNumber.ok THEN Fail ELSE
    LET crossType == ReadBytes(matchNumber.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET price == ReadBytes(crossType.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET volume == ReadBytes(price.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    Ok([ nanoseconds |-> nanoseconds.value,
         optionId    |-> optionId.value,
         crossNumber |-> crossNumber.value,
         matchNumber |-> matchNumber.value,
         crossType   |-> crossType.value,
         price       |-> price.value,
         volume      |-> volume.value ], volume.rest)

ZeroOptionsCrossTradeMessage ==
    [ nanoseconds |-> [i \in 1 .. 4 |-> 0],
      optionId    |-> [i \in 1 .. 4 |-> 0],
      crossNumber |-> [i \in 1 .. 4 |-> 0],
      matchNumber |-> [i \in 1 .. 4 |-> 0],
      crossType   |-> [i \in 1 .. 1 |-> 0],
      price       |-> [i \in 1 .. 4 |-> 0],
      volume      |-> [i \in 1 .. 4 |-> 0] ]

(* Options Cross Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionsCrossTradeMessage ==
    { ZeroOptionsCrossTradeMessage }
        \cup { [ZeroOptionsCrossTradeMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOptionsCrossTradeMessage EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroOptionsCrossTradeMessage EXCEPT !.crossNumber = one] : one \in Sample(4) }
        \cup { [ZeroOptionsCrossTradeMessage EXCEPT !.matchNumber = one] : one \in Sample(4) }
        \cup { [ZeroOptionsCrossTradeMessage EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroOptionsCrossTradeMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOptionsCrossTradeMessage EXCEPT !.volume = one] : one \in Sample(4) }

(***************************************************************************)
(* Broken Trade Order Executed Message: 12 bytes                           *)
(***************************************************************************)

BrokenTradeOrderExecutedMessage ==
    [ nanoseconds : Sample(4),
      crossNumber : Sample(4),
      matchNumber : Sample(4) ]

EncodeBrokenTradeOrderExecutedMessage(message) ==
    message.nanoseconds
        \o message.crossNumber
        \o message.matchNumber

DecodeBrokenTradeOrderExecutedMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET crossNumber == ReadBytes(nanoseconds.rest, 4) IN IF ~crossNumber.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(crossNumber.rest, 4) IN IF ~matchNumber.ok THEN Fail ELSE
    Ok([ nanoseconds |-> nanoseconds.value,
         crossNumber |-> crossNumber.value,
         matchNumber |-> matchNumber.value ], matchNumber.rest)

ZeroBrokenTradeOrderExecutedMessage ==
    [ nanoseconds |-> [i \in 1 .. 4 |-> 0],
      crossNumber |-> [i \in 1 .. 4 |-> 0],
      matchNumber |-> [i \in 1 .. 4 |-> 0] ]

(* Broken Trade Order Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedBrokenTradeOrderExecutedMessage ==
    { ZeroBrokenTradeOrderExecutedMessage }
        \cup { [ZeroBrokenTradeOrderExecutedMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroBrokenTradeOrderExecutedMessage EXCEPT !.crossNumber = one] : one \in Sample(4) }
        \cup { [ZeroBrokenTradeOrderExecutedMessage EXCEPT !.matchNumber = one] : one \in Sample(4) }

(***************************************************************************)
(* Auction Notification Message: 30 bytes                                  *)
(***************************************************************************)

AuctionNotificationMessage ==
    [ nanoseconds        : Sample(4),
      auctionId          : Sample(4),
      auctionType        : Sample(1),
      pairedContracts    : Sample(4),
      imbalanceDirection : Sample(1),
      optionId           : Sample(4),
      imbalancePrice     : Sample(4),
      imbalanceVolume    : Sample(4),
      customerIndicator  : Sample(1),
      reserved3          : Sample(3) ]

EncodeAuctionNotificationMessage(message) ==
    message.nanoseconds
        \o message.auctionId
        \o message.auctionType
        \o message.pairedContracts
        \o message.imbalanceDirection
        \o message.optionId
        \o message.imbalancePrice
        \o message.imbalanceVolume
        \o message.customerIndicator
        \o message.reserved3

DecodeAuctionNotificationMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET auctionId == ReadBytes(nanoseconds.rest, 4) IN IF ~auctionId.ok THEN Fail ELSE
    LET auctionType == ReadBytes(auctionId.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET pairedContracts == ReadBytes(auctionType.rest, 4) IN IF ~pairedContracts.ok THEN Fail ELSE
    LET imbalanceDirection == ReadBytes(pairedContracts.rest, 1) IN IF ~imbalanceDirection.ok THEN Fail ELSE
    LET optionId == ReadBytes(imbalanceDirection.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET imbalancePrice == ReadBytes(optionId.rest, 4) IN IF ~imbalancePrice.ok THEN Fail ELSE
    LET imbalanceVolume == ReadBytes(imbalancePrice.rest, 4) IN IF ~imbalanceVolume.ok THEN Fail ELSE
    LET customerIndicator == ReadBytes(imbalanceVolume.rest, 1) IN IF ~customerIndicator.ok THEN Fail ELSE
    LET reserved3 == ReadBytes(customerIndicator.rest, 3) IN IF ~reserved3.ok THEN Fail ELSE
    Ok([ nanoseconds        |-> nanoseconds.value,
         auctionId          |-> auctionId.value,
         auctionType        |-> auctionType.value,
         pairedContracts    |-> pairedContracts.value,
         imbalanceDirection |-> imbalanceDirection.value,
         optionId           |-> optionId.value,
         imbalancePrice     |-> imbalancePrice.value,
         imbalanceVolume    |-> imbalanceVolume.value,
         customerIndicator  |-> customerIndicator.value,
         reserved3          |-> reserved3.value ], reserved3.rest)

ZeroAuctionNotificationMessage ==
    [ nanoseconds        |-> [i \in 1 .. 4 |-> 0],
      auctionId          |-> [i \in 1 .. 4 |-> 0],
      auctionType        |-> [i \in 1 .. 1 |-> 0],
      pairedContracts    |-> [i \in 1 .. 4 |-> 0],
      imbalanceDirection |-> [i \in 1 .. 1 |-> 0],
      optionId           |-> [i \in 1 .. 4 |-> 0],
      imbalancePrice     |-> [i \in 1 .. 4 |-> 0],
      imbalanceVolume    |-> [i \in 1 .. 4 |-> 0],
      customerIndicator  |-> [i \in 1 .. 1 |-> 0],
      reserved3          |-> [i \in 1 .. 3 |-> 0] ]

(* Auction Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionNotificationMessage ==
    { ZeroAuctionNotificationMessage }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.auctionId = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.pairedContracts = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.imbalanceDirection = one] : one \in Sample(1) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.imbalancePrice = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.imbalanceVolume = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.customerIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.reserved3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

SecondsMessageCode == 84  \* "T"
SystemEventMessageCode == 83  \* "S"
BaseReferenceMessageCode == 76  \* "L"
OptionDirectoryMessageCode == 82  \* "R"
TradingActionMessageCode == 72  \* "H"
SecurityOpenMessageCode == 79  \* "O"
AddOrderShortMessageCode == 97  \* "a"
AddOrderLongMessageCode == 65  \* "A"
AddQuoteShortMessageCode == 106  \* "j"
AddQuoteLongMessageCode == 74  \* "J"
SingleSideExecutedMessageCode == 69  \* "E"
SingleSideExecutedWithPriceMessageCode == 67  \* "C"
SingleSideCancelMessageCode == 88  \* "X"
SingleSideReplaceShortMessageCode == 117  \* "u"
SingleSideReplaceLongMessageCode == 85  \* "U"
OrderReplaceShortMessageCode == 118  \* "v"
OrderReplaceLongMessageCode == 86  \* "V"
SingleSideDeleteMessageCode == 68  \* "D"
SingleSideUpdateMessageCode == 71  \* "G"
QuoteReplaceShortMessageCode == 107  \* "k"
QuoteReplaceLongMessageCode == 75  \* "K"
QuoteDeleteMessageCode == 89  \* "Y"
BlockDeleteMessageCode == 90  \* "Z"
NonAuctionOptionsTradeMessageCode == 80  \* "P"
OptionsCrossTradeMessageCode == 81  \* "Q"
BrokenTradeOrderExecutedMessageCode == 66  \* "B"
AuctionNotificationMessageCode == 73  \* "I"

Payload ==
    [ tag : {SecondsMessageCode}, body : SecondsMessage ]
        \cup [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {BaseReferenceMessageCode}, body : BaseReferenceMessage ]
        \cup [ tag : {OptionDirectoryMessageCode}, body : OptionDirectoryMessage ]
        \cup [ tag : {TradingActionMessageCode}, body : TradingActionMessage ]
        \cup [ tag : {SecurityOpenMessageCode}, body : SecurityOpenMessage ]
        \cup [ tag : {AddOrderShortMessageCode}, body : AddOrderShortMessage ]
        \cup [ tag : {AddOrderLongMessageCode}, body : AddOrderLongMessage ]
        \cup [ tag : {AddQuoteShortMessageCode}, body : AddQuoteShortMessage ]
        \cup [ tag : {AddQuoteLongMessageCode}, body : AddQuoteLongMessage ]
        \cup [ tag : {SingleSideExecutedMessageCode}, body : SingleSideExecutedMessage ]
        \cup [ tag : {SingleSideExecutedWithPriceMessageCode}, body : SingleSideExecutedWithPriceMessage ]
        \cup [ tag : {SingleSideCancelMessageCode}, body : SingleSideCancelMessage ]
        \cup [ tag : {SingleSideReplaceShortMessageCode}, body : SingleSideReplaceShortMessage ]
        \cup [ tag : {SingleSideReplaceLongMessageCode}, body : SingleSideReplaceLongMessage ]
        \cup [ tag : {OrderReplaceShortMessageCode}, body : OrderReplaceShortMessage ]
        \cup [ tag : {OrderReplaceLongMessageCode}, body : OrderReplaceLongMessage ]
        \cup [ tag : {SingleSideDeleteMessageCode}, body : SingleSideDeleteMessage ]
        \cup [ tag : {SingleSideUpdateMessageCode}, body : SingleSideUpdateMessage ]
        \cup [ tag : {QuoteReplaceShortMessageCode}, body : QuoteReplaceShortMessage ]
        \cup [ tag : {QuoteReplaceLongMessageCode}, body : QuoteReplaceLongMessage ]
        \cup [ tag : {QuoteDeleteMessageCode}, body : QuoteDeleteMessage ]
        \cup [ tag : {BlockDeleteMessageCode}, body : BlockDeleteMessage ]
        \cup [ tag : {NonAuctionOptionsTradeMessageCode}, body : NonAuctionOptionsTradeMessage ]
        \cup [ tag : {OptionsCrossTradeMessageCode}, body : OptionsCrossTradeMessage ]
        \cup [ tag : {BrokenTradeOrderExecutedMessageCode}, body : BrokenTradeOrderExecutedMessage ]
        \cup [ tag : {AuctionNotificationMessageCode}, body : AuctionNotificationMessage ]

EncodePayload(message) ==
    CASE message.tag = SecondsMessageCode -> EncodeSecondsMessage(message.body)
      [] message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = BaseReferenceMessageCode -> EncodeBaseReferenceMessage(message.body)
      [] message.tag = OptionDirectoryMessageCode -> EncodeOptionDirectoryMessage(message.body)
      [] message.tag = TradingActionMessageCode -> EncodeTradingActionMessage(message.body)
      [] message.tag = SecurityOpenMessageCode -> EncodeSecurityOpenMessage(message.body)
      [] message.tag = AddOrderShortMessageCode -> EncodeAddOrderShortMessage(message.body)
      [] message.tag = AddOrderLongMessageCode -> EncodeAddOrderLongMessage(message.body)
      [] message.tag = AddQuoteShortMessageCode -> EncodeAddQuoteShortMessage(message.body)
      [] message.tag = AddQuoteLongMessageCode -> EncodeAddQuoteLongMessage(message.body)
      [] message.tag = SingleSideExecutedMessageCode -> EncodeSingleSideExecutedMessage(message.body)
      [] message.tag = SingleSideExecutedWithPriceMessageCode -> EncodeSingleSideExecutedWithPriceMessage(message.body)
      [] message.tag = SingleSideCancelMessageCode -> EncodeSingleSideCancelMessage(message.body)
      [] message.tag = SingleSideReplaceShortMessageCode -> EncodeSingleSideReplaceShortMessage(message.body)
      [] message.tag = SingleSideReplaceLongMessageCode -> EncodeSingleSideReplaceLongMessage(message.body)
      [] message.tag = OrderReplaceShortMessageCode -> EncodeOrderReplaceShortMessage(message.body)
      [] message.tag = OrderReplaceLongMessageCode -> EncodeOrderReplaceLongMessage(message.body)
      [] message.tag = SingleSideDeleteMessageCode -> EncodeSingleSideDeleteMessage(message.body)
      [] message.tag = SingleSideUpdateMessageCode -> EncodeSingleSideUpdateMessage(message.body)
      [] message.tag = QuoteReplaceShortMessageCode -> EncodeQuoteReplaceShortMessage(message.body)
      [] message.tag = QuoteReplaceLongMessageCode -> EncodeQuoteReplaceLongMessage(message.body)
      [] message.tag = QuoteDeleteMessageCode -> EncodeQuoteDeleteMessage(message.body)
      [] message.tag = BlockDeleteMessageCode -> EncodeBlockDeleteMessage(message.body)
      [] message.tag = NonAuctionOptionsTradeMessageCode -> EncodeNonAuctionOptionsTradeMessage(message.body)
      [] message.tag = OptionsCrossTradeMessageCode -> EncodeOptionsCrossTradeMessage(message.body)
      [] message.tag = BrokenTradeOrderExecutedMessageCode -> EncodeBrokenTradeOrderExecutedMessage(message.body)
      [] message.tag = AuctionNotificationMessageCode -> EncodeAuctionNotificationMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = SecondsMessageCode -> DecodeSecondsMessage(bytes)
              [] tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = BaseReferenceMessageCode -> DecodeBaseReferenceMessage(bytes)
              [] tag = OptionDirectoryMessageCode -> DecodeOptionDirectoryMessage(bytes)
              [] tag = TradingActionMessageCode -> DecodeTradingActionMessage(bytes)
              [] tag = SecurityOpenMessageCode -> DecodeSecurityOpenMessage(bytes)
              [] tag = AddOrderShortMessageCode -> DecodeAddOrderShortMessage(bytes)
              [] tag = AddOrderLongMessageCode -> DecodeAddOrderLongMessage(bytes)
              [] tag = AddQuoteShortMessageCode -> DecodeAddQuoteShortMessage(bytes)
              [] tag = AddQuoteLongMessageCode -> DecodeAddQuoteLongMessage(bytes)
              [] tag = SingleSideExecutedMessageCode -> DecodeSingleSideExecutedMessage(bytes)
              [] tag = SingleSideExecutedWithPriceMessageCode -> DecodeSingleSideExecutedWithPriceMessage(bytes)
              [] tag = SingleSideCancelMessageCode -> DecodeSingleSideCancelMessage(bytes)
              [] tag = SingleSideReplaceShortMessageCode -> DecodeSingleSideReplaceShortMessage(bytes)
              [] tag = SingleSideReplaceLongMessageCode -> DecodeSingleSideReplaceLongMessage(bytes)
              [] tag = OrderReplaceShortMessageCode -> DecodeOrderReplaceShortMessage(bytes)
              [] tag = OrderReplaceLongMessageCode -> DecodeOrderReplaceLongMessage(bytes)
              [] tag = SingleSideDeleteMessageCode -> DecodeSingleSideDeleteMessage(bytes)
              [] tag = SingleSideUpdateMessageCode -> DecodeSingleSideUpdateMessage(bytes)
              [] tag = QuoteReplaceShortMessageCode -> DecodeQuoteReplaceShortMessage(bytes)
              [] tag = QuoteReplaceLongMessageCode -> DecodeQuoteReplaceLongMessage(bytes)
              [] tag = QuoteDeleteMessageCode -> DecodeQuoteDeleteMessage(bytes)
              [] tag = BlockDeleteMessageCode -> DecodeBlockDeleteMessage(bytes)
              [] tag = NonAuctionOptionsTradeMessageCode -> DecodeNonAuctionOptionsTradeMessage(bytes)
              [] tag = OptionsCrossTradeMessageCode -> DecodeOptionsCrossTradeMessage(bytes)
              [] tag = BrokenTradeOrderExecutedMessageCode -> DecodeBrokenTradeOrderExecutedMessage(bytes)
              [] tag = AuctionNotificationMessageCode -> DecodeAuctionNotificationMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> SecondsMessageCode, body |-> ZeroSecondsMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> SecondsMessageCode, body |-> one] : one \in CheckedSecondsMessage }
        \cup { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> BaseReferenceMessageCode, body |-> one] : one \in CheckedBaseReferenceMessage }
        \cup { [tag |-> OptionDirectoryMessageCode, body |-> one] : one \in CheckedOptionDirectoryMessage }
        \cup { [tag |-> TradingActionMessageCode, body |-> one] : one \in CheckedTradingActionMessage }
        \cup { [tag |-> SecurityOpenMessageCode, body |-> one] : one \in CheckedSecurityOpenMessage }
        \cup { [tag |-> AddOrderShortMessageCode, body |-> one] : one \in CheckedAddOrderShortMessage }
        \cup { [tag |-> AddOrderLongMessageCode, body |-> one] : one \in CheckedAddOrderLongMessage }
        \cup { [tag |-> AddQuoteShortMessageCode, body |-> one] : one \in CheckedAddQuoteShortMessage }
        \cup { [tag |-> AddQuoteLongMessageCode, body |-> one] : one \in CheckedAddQuoteLongMessage }
        \cup { [tag |-> SingleSideExecutedMessageCode, body |-> one] : one \in CheckedSingleSideExecutedMessage }
        \cup { [tag |-> SingleSideExecutedWithPriceMessageCode, body |-> one] : one \in CheckedSingleSideExecutedWithPriceMessage }
        \cup { [tag |-> SingleSideCancelMessageCode, body |-> one] : one \in CheckedSingleSideCancelMessage }
        \cup { [tag |-> SingleSideReplaceShortMessageCode, body |-> one] : one \in CheckedSingleSideReplaceShortMessage }
        \cup { [tag |-> SingleSideReplaceLongMessageCode, body |-> one] : one \in CheckedSingleSideReplaceLongMessage }
        \cup { [tag |-> OrderReplaceShortMessageCode, body |-> one] : one \in CheckedOrderReplaceShortMessage }
        \cup { [tag |-> OrderReplaceLongMessageCode, body |-> one] : one \in CheckedOrderReplaceLongMessage }
        \cup { [tag |-> SingleSideDeleteMessageCode, body |-> one] : one \in CheckedSingleSideDeleteMessage }
        \cup { [tag |-> SingleSideUpdateMessageCode, body |-> one] : one \in CheckedSingleSideUpdateMessage }
        \cup { [tag |-> QuoteReplaceShortMessageCode, body |-> one] : one \in CheckedQuoteReplaceShortMessage }
        \cup { [tag |-> QuoteReplaceLongMessageCode, body |-> one] : one \in CheckedQuoteReplaceLongMessage }
        \cup { [tag |-> QuoteDeleteMessageCode, body |-> one] : one \in CheckedQuoteDeleteMessage }
        \cup { [tag |-> BlockDeleteMessageCode, body |-> one] : one \in CheckedBlockDeleteMessage }
        \cup { [tag |-> NonAuctionOptionsTradeMessageCode, body |-> one] : one \in CheckedNonAuctionOptionsTradeMessage }
        \cup { [tag |-> OptionsCrossTradeMessageCode, body |-> one] : one \in CheckedOptionsCrossTradeMessage }
        \cup { [tag |-> BrokenTradeOrderExecutedMessageCode, body |-> one] : one \in CheckedBrokenTradeOrderExecutedMessage }
        \cup { [tag |-> AuctionNotificationMessageCode, body |-> one] : one \in CheckedAuctionNotificationMessage }

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
    { [ZeroMessage EXCEPT !.payload = [tag |-> SecondsMessageCode, body |-> ZeroSecondsMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> BaseReferenceMessageCode, body |-> ZeroBaseReferenceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OptionDirectoryMessageCode, body |-> ZeroOptionDirectoryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradingActionMessageCode, body |-> ZeroTradingActionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityOpenMessageCode, body |-> ZeroSecurityOpenMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddOrderShortMessageCode, body |-> ZeroAddOrderShortMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddOrderLongMessageCode, body |-> ZeroAddOrderLongMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddQuoteShortMessageCode, body |-> ZeroAddQuoteShortMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddQuoteLongMessageCode, body |-> ZeroAddQuoteLongMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SingleSideExecutedMessageCode, body |-> ZeroSingleSideExecutedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SingleSideExecutedWithPriceMessageCode, body |-> ZeroSingleSideExecutedWithPriceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SingleSideCancelMessageCode, body |-> ZeroSingleSideCancelMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SingleSideReplaceShortMessageCode, body |-> ZeroSingleSideReplaceShortMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SingleSideReplaceLongMessageCode, body |-> ZeroSingleSideReplaceLongMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderReplaceShortMessageCode, body |-> ZeroOrderReplaceShortMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderReplaceLongMessageCode, body |-> ZeroOrderReplaceLongMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SingleSideDeleteMessageCode, body |-> ZeroSingleSideDeleteMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SingleSideUpdateMessageCode, body |-> ZeroSingleSideUpdateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> QuoteReplaceShortMessageCode, body |-> ZeroQuoteReplaceShortMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> QuoteReplaceLongMessageCode, body |-> ZeroQuoteReplaceLongMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> QuoteDeleteMessageCode, body |-> ZeroQuoteDeleteMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> BlockDeleteMessageCode, body |-> ZeroBlockDeleteMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> NonAuctionOptionsTradeMessageCode, body |-> ZeroNonAuctionOptionsTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OptionsCrossTradeMessageCode, body |-> ZeroOptionsCrossTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> BrokenTradeOrderExecutedMessageCode, body |-> ZeroBrokenTradeOrderExecutedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionNotificationMessageCode, body |-> ZeroAuctionNotificationMessage]] }

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

(* Every Seconds Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecondsMessage ==
    \A message \in CheckedSecondsMessage :
        LET read == DecodeSecondsMessage(EncodeSecondsMessage(message))
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

(* Every Base Reference Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBaseReferenceMessage ==
    \A message \in CheckedBaseReferenceMessage :
        LET read == DecodeBaseReferenceMessage(EncodeBaseReferenceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionDirectoryMessage ==
    \A message \in CheckedOptionDirectoryMessage :
        LET read == DecodeOptionDirectoryMessage(EncodeOptionDirectoryMessage(message))
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

(* Every Security Open Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityOpenMessage ==
    \A message \in CheckedSecurityOpenMessage :
        LET read == DecodeSecurityOpenMessage(EncodeSecurityOpenMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Order Short Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderShortMessage ==
    \A message \in CheckedAddOrderShortMessage :
        LET read == DecodeAddOrderShortMessage(EncodeAddOrderShortMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Order Long Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderLongMessage ==
    \A message \in CheckedAddOrderLongMessage :
        LET read == DecodeAddOrderLongMessage(EncodeAddOrderLongMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Quote Short Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddQuoteShortMessage ==
    \A message \in CheckedAddQuoteShortMessage :
        LET read == DecodeAddQuoteShortMessage(EncodeAddQuoteShortMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Quote Long Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddQuoteLongMessage ==
    \A message \in CheckedAddQuoteLongMessage :
        LET read == DecodeAddQuoteLongMessage(EncodeAddQuoteLongMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Side Executed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleSideExecutedMessage ==
    \A message \in CheckedSingleSideExecutedMessage :
        LET read == DecodeSingleSideExecutedMessage(EncodeSingleSideExecutedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Side Executed With Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleSideExecutedWithPriceMessage ==
    \A message \in CheckedSingleSideExecutedWithPriceMessage :
        LET read == DecodeSingleSideExecutedWithPriceMessage(EncodeSingleSideExecutedWithPriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Side Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleSideCancelMessage ==
    \A message \in CheckedSingleSideCancelMessage :
        LET read == DecodeSingleSideCancelMessage(EncodeSingleSideCancelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Side Replace Short Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleSideReplaceShortMessage ==
    \A message \in CheckedSingleSideReplaceShortMessage :
        LET read == DecodeSingleSideReplaceShortMessage(EncodeSingleSideReplaceShortMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Side Replace Long Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleSideReplaceLongMessage ==
    \A message \in CheckedSingleSideReplaceLongMessage :
        LET read == DecodeSingleSideReplaceLongMessage(EncodeSingleSideReplaceLongMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Replace Short Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderReplaceShortMessage ==
    \A message \in CheckedOrderReplaceShortMessage :
        LET read == DecodeOrderReplaceShortMessage(EncodeOrderReplaceShortMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Replace Long Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderReplaceLongMessage ==
    \A message \in CheckedOrderReplaceLongMessage :
        LET read == DecodeOrderReplaceLongMessage(EncodeOrderReplaceLongMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Side Delete Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleSideDeleteMessage ==
    \A message \in CheckedSingleSideDeleteMessage :
        LET read == DecodeSingleSideDeleteMessage(EncodeSingleSideDeleteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Side Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleSideUpdateMessage ==
    \A message \in CheckedSingleSideUpdateMessage :
        LET read == DecodeSingleSideUpdateMessage(EncodeSingleSideUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Replace Short Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteReplaceShortMessage ==
    \A message \in CheckedQuoteReplaceShortMessage :
        LET read == DecodeQuoteReplaceShortMessage(EncodeQuoteReplaceShortMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Replace Long Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteReplaceLongMessage ==
    \A message \in CheckedQuoteReplaceLongMessage :
        LET read == DecodeQuoteReplaceLongMessage(EncodeQuoteReplaceLongMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Delete Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteDeleteMessage ==
    \A message \in CheckedQuoteDeleteMessage :
        LET read == DecodeQuoteDeleteMessage(EncodeQuoteDeleteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Block Delete Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBlockDeleteMessage ==
    \A message \in CheckedBlockDeleteMessage :
        LET read == DecodeBlockDeleteMessage(EncodeBlockDeleteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Non Auction Options Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNonAuctionOptionsTradeMessage ==
    \A message \in CheckedNonAuctionOptionsTradeMessage :
        LET read == DecodeNonAuctionOptionsTradeMessage(EncodeNonAuctionOptionsTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Options Cross Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionsCrossTradeMessage ==
    \A message \in CheckedOptionsCrossTradeMessage :
        LET read == DecodeOptionsCrossTradeMessage(EncodeOptionsCrossTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Broken Trade Order Executed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBrokenTradeOrderExecutedMessage ==
    \A message \in CheckedBrokenTradeOrderExecutedMessage :
        LET read == DecodeBrokenTradeOrderExecutedMessage(EncodeBrokenTradeOrderExecutedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionNotificationMessage ==
    \A message \in CheckedAuctionNotificationMessage :
        LET read == DecodeAuctionNotificationMessage(EncodeAuctionNotificationMessage(message))
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
