------------------- MODULE NtxOptions_DepthOfMarket_v1_3 -------------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Depth Of Market v1.3                                           *)
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
(* Option Open Message: 9 bytes                                            *)
(***************************************************************************)

OptionOpenMessage ==
    [ nanoseconds : Sample(4),
      optionId    : Sample(4),
      openState   : Sample(1) ]

EncodeOptionOpenMessage(message) ==
    message.nanoseconds
        \o message.optionId
        \o message.openState

DecodeOptionOpenMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET optionId == ReadBytes(nanoseconds.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET openState == ReadBytes(optionId.rest, 1) IN IF ~openState.ok THEN Fail ELSE
    Ok([ nanoseconds |-> nanoseconds.value,
         optionId    |-> optionId.value,
         openState   |-> openState.value ], openState.rest)

ZeroOptionOpenMessage ==
    [ nanoseconds |-> [i \in 1 .. 4 |-> 0],
      optionId    |-> [i \in 1 .. 4 |-> 0],
      openState   |-> [i \in 1 .. 1 |-> 0] ]

(* Option Open Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionOpenMessage ==
    { ZeroOptionOpenMessage }
        \cup { [ZeroOptionOpenMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOptionOpenMessage EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroOptionOpenMessage EXCEPT !.openState = one] : one \in Sample(1) }

(***************************************************************************)
(* Add Order Message Short Form: 17 bytes                                  *)
(***************************************************************************)

AddOrderMessageShortForm ==
    [ nanoseconds               : Sample(4),
      orderReferenceNumberDelta : Sample(4),
      marketSide                : Sample(1),
      optionId                  : Sample(4),
      price                     : Sample(2),
      volume                    : Sample(2) ]

EncodeAddOrderMessageShortForm(message) ==
    message.nanoseconds
        \o message.orderReferenceNumberDelta
        \o message.marketSide
        \o message.optionId
        \o message.price
        \o message.volume

DecodeAddOrderMessageShortForm(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderReferenceNumberDelta == ReadBytes(nanoseconds.rest, 4) IN IF ~orderReferenceNumberDelta.ok THEN Fail ELSE
    LET marketSide == ReadBytes(orderReferenceNumberDelta.rest, 1) IN IF ~marketSide.ok THEN Fail ELSE
    LET optionId == ReadBytes(marketSide.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET price == ReadBytes(optionId.rest, 2) IN IF ~price.ok THEN Fail ELSE
    LET volume == ReadBytes(price.rest, 2) IN IF ~volume.ok THEN Fail ELSE
    Ok([ nanoseconds               |-> nanoseconds.value,
         orderReferenceNumberDelta |-> orderReferenceNumberDelta.value,
         marketSide                |-> marketSide.value,
         optionId                  |-> optionId.value,
         price                     |-> price.value,
         volume                    |-> volume.value ], volume.rest)

ZeroAddOrderMessageShortForm ==
    [ nanoseconds               |-> [i \in 1 .. 4 |-> 0],
      orderReferenceNumberDelta |-> [i \in 1 .. 4 |-> 0],
      marketSide                |-> [i \in 1 .. 1 |-> 0],
      optionId                  |-> [i \in 1 .. 4 |-> 0],
      price                     |-> [i \in 1 .. 2 |-> 0],
      volume                    |-> [i \in 1 .. 2 |-> 0] ]

(* Add Order Message Short Form at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderMessageShortForm ==
    { ZeroAddOrderMessageShortForm }
        \cup { [ZeroAddOrderMessageShortForm EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessageShortForm EXCEPT !.orderReferenceNumberDelta = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessageShortForm EXCEPT !.marketSide = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessageShortForm EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessageShortForm EXCEPT !.price = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderMessageShortForm EXCEPT !.volume = one] : one \in Sample(2) }

(***************************************************************************)
(* Add Order Message Long Form: 21 bytes                                   *)
(***************************************************************************)

AddOrderMessageLongForm ==
    [ nanoseconds               : Sample(4),
      orderReferenceNumberDelta : Sample(4),
      marketSide                : Sample(1),
      optionId                  : Sample(4),
      priceLong                 : Sample(4),
      volumeLong                : Sample(4) ]

EncodeAddOrderMessageLongForm(message) ==
    message.nanoseconds
        \o message.orderReferenceNumberDelta
        \o message.marketSide
        \o message.optionId
        \o message.priceLong
        \o message.volumeLong

DecodeAddOrderMessageLongForm(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderReferenceNumberDelta == ReadBytes(nanoseconds.rest, 4) IN IF ~orderReferenceNumberDelta.ok THEN Fail ELSE
    LET marketSide == ReadBytes(orderReferenceNumberDelta.rest, 1) IN IF ~marketSide.ok THEN Fail ELSE
    LET optionId == ReadBytes(marketSide.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET priceLong == ReadBytes(optionId.rest, 4) IN IF ~priceLong.ok THEN Fail ELSE
    LET volumeLong == ReadBytes(priceLong.rest, 4) IN IF ~volumeLong.ok THEN Fail ELSE
    Ok([ nanoseconds               |-> nanoseconds.value,
         orderReferenceNumberDelta |-> orderReferenceNumberDelta.value,
         marketSide                |-> marketSide.value,
         optionId                  |-> optionId.value,
         priceLong                 |-> priceLong.value,
         volumeLong                |-> volumeLong.value ], volumeLong.rest)

ZeroAddOrderMessageLongForm ==
    [ nanoseconds               |-> [i \in 1 .. 4 |-> 0],
      orderReferenceNumberDelta |-> [i \in 1 .. 4 |-> 0],
      marketSide                |-> [i \in 1 .. 1 |-> 0],
      optionId                  |-> [i \in 1 .. 4 |-> 0],
      priceLong                 |-> [i \in 1 .. 4 |-> 0],
      volumeLong                |-> [i \in 1 .. 4 |-> 0] ]

(* Add Order Message Long Form at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderMessageLongForm ==
    { ZeroAddOrderMessageLongForm }
        \cup { [ZeroAddOrderMessageLongForm EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessageLongForm EXCEPT !.orderReferenceNumberDelta = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessageLongForm EXCEPT !.marketSide = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessageLongForm EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessageLongForm EXCEPT !.priceLong = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessageLongForm EXCEPT !.volumeLong = one] : one \in Sample(4) }

(***************************************************************************)
(* Add Quote Message Short Form: 24 bytes                                  *)
(***************************************************************************)

AddQuoteMessageShortForm ==
    [ nanoseconds             : Sample(4),
      bidReferenceNumberDelta : Sample(4),
      askReferenceNumberDelta : Sample(4),
      optionId                : Sample(4),
      bidPrice                : Sample(2),
      bidSize                 : Sample(2),
      askPrice                : Sample(2),
      askSize                 : Sample(2) ]

EncodeAddQuoteMessageShortForm(message) ==
    message.nanoseconds
        \o message.bidReferenceNumberDelta
        \o message.askReferenceNumberDelta
        \o message.optionId
        \o message.bidPrice
        \o message.bidSize
        \o message.askPrice
        \o message.askSize

DecodeAddQuoteMessageShortForm(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET bidReferenceNumberDelta == ReadBytes(nanoseconds.rest, 4) IN IF ~bidReferenceNumberDelta.ok THEN Fail ELSE
    LET askReferenceNumberDelta == ReadBytes(bidReferenceNumberDelta.rest, 4) IN IF ~askReferenceNumberDelta.ok THEN Fail ELSE
    LET optionId == ReadBytes(askReferenceNumberDelta.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(optionId.rest, 2) IN IF ~bidPrice.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPrice.rest, 2) IN IF ~bidSize.ok THEN Fail ELSE
    LET askPrice == ReadBytes(bidSize.rest, 2) IN IF ~askPrice.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPrice.rest, 2) IN IF ~askSize.ok THEN Fail ELSE
    Ok([ nanoseconds             |-> nanoseconds.value,
         bidReferenceNumberDelta |-> bidReferenceNumberDelta.value,
         askReferenceNumberDelta |-> askReferenceNumberDelta.value,
         optionId                |-> optionId.value,
         bidPrice                |-> bidPrice.value,
         bidSize                 |-> bidSize.value,
         askPrice                |-> askPrice.value,
         askSize                 |-> askSize.value ], askSize.rest)

ZeroAddQuoteMessageShortForm ==
    [ nanoseconds             |-> [i \in 1 .. 4 |-> 0],
      bidReferenceNumberDelta |-> [i \in 1 .. 4 |-> 0],
      askReferenceNumberDelta |-> [i \in 1 .. 4 |-> 0],
      optionId                |-> [i \in 1 .. 4 |-> 0],
      bidPrice                |-> [i \in 1 .. 2 |-> 0],
      bidSize                 |-> [i \in 1 .. 2 |-> 0],
      askPrice                |-> [i \in 1 .. 2 |-> 0],
      askSize                 |-> [i \in 1 .. 2 |-> 0] ]

(* Add Quote Message Short Form at zero, then each field in turn at the values it is checked at *)
CheckedAddQuoteMessageShortForm ==
    { ZeroAddQuoteMessageShortForm }
        \cup { [ZeroAddQuoteMessageShortForm EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroAddQuoteMessageShortForm EXCEPT !.bidReferenceNumberDelta = one] : one \in Sample(4) }
        \cup { [ZeroAddQuoteMessageShortForm EXCEPT !.askReferenceNumberDelta = one] : one \in Sample(4) }
        \cup { [ZeroAddQuoteMessageShortForm EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroAddQuoteMessageShortForm EXCEPT !.bidPrice = one] : one \in Sample(2) }
        \cup { [ZeroAddQuoteMessageShortForm EXCEPT !.bidSize = one] : one \in Sample(2) }
        \cup { [ZeroAddQuoteMessageShortForm EXCEPT !.askPrice = one] : one \in Sample(2) }
        \cup { [ZeroAddQuoteMessageShortForm EXCEPT !.askSize = one] : one \in Sample(2) }

(***************************************************************************)
(* Add Quote Message Long Form: 32 bytes                                   *)
(***************************************************************************)

AddQuoteMessageLongForm ==
    [ nanoseconds             : Sample(4),
      bidReferenceNumberDelta : Sample(4),
      askReferenceNumberDelta : Sample(4),
      optionId                : Sample(4),
      bid                     : Sample(4),
      bidSizeLong             : Sample(4),
      ask                     : Sample(4),
      askSizeLong             : Sample(4) ]

EncodeAddQuoteMessageLongForm(message) ==
    message.nanoseconds
        \o message.bidReferenceNumberDelta
        \o message.askReferenceNumberDelta
        \o message.optionId
        \o message.bid
        \o message.bidSizeLong
        \o message.ask
        \o message.askSizeLong

DecodeAddQuoteMessageLongForm(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET bidReferenceNumberDelta == ReadBytes(nanoseconds.rest, 4) IN IF ~bidReferenceNumberDelta.ok THEN Fail ELSE
    LET askReferenceNumberDelta == ReadBytes(bidReferenceNumberDelta.rest, 4) IN IF ~askReferenceNumberDelta.ok THEN Fail ELSE
    LET optionId == ReadBytes(askReferenceNumberDelta.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET bid == ReadBytes(optionId.rest, 4) IN IF ~bid.ok THEN Fail ELSE
    LET bidSizeLong == ReadBytes(bid.rest, 4) IN IF ~bidSizeLong.ok THEN Fail ELSE
    LET ask == ReadBytes(bidSizeLong.rest, 4) IN IF ~ask.ok THEN Fail ELSE
    LET askSizeLong == ReadBytes(ask.rest, 4) IN IF ~askSizeLong.ok THEN Fail ELSE
    Ok([ nanoseconds             |-> nanoseconds.value,
         bidReferenceNumberDelta |-> bidReferenceNumberDelta.value,
         askReferenceNumberDelta |-> askReferenceNumberDelta.value,
         optionId                |-> optionId.value,
         bid                     |-> bid.value,
         bidSizeLong             |-> bidSizeLong.value,
         ask                     |-> ask.value,
         askSizeLong             |-> askSizeLong.value ], askSizeLong.rest)

ZeroAddQuoteMessageLongForm ==
    [ nanoseconds             |-> [i \in 1 .. 4 |-> 0],
      bidReferenceNumberDelta |-> [i \in 1 .. 4 |-> 0],
      askReferenceNumberDelta |-> [i \in 1 .. 4 |-> 0],
      optionId                |-> [i \in 1 .. 4 |-> 0],
      bid                     |-> [i \in 1 .. 4 |-> 0],
      bidSizeLong             |-> [i \in 1 .. 4 |-> 0],
      ask                     |-> [i \in 1 .. 4 |-> 0],
      askSizeLong             |-> [i \in 1 .. 4 |-> 0] ]

(* Add Quote Message Long Form at zero, then each field in turn at the values it is checked at *)
CheckedAddQuoteMessageLongForm ==
    { ZeroAddQuoteMessageLongForm }
        \cup { [ZeroAddQuoteMessageLongForm EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroAddQuoteMessageLongForm EXCEPT !.bidReferenceNumberDelta = one] : one \in Sample(4) }
        \cup { [ZeroAddQuoteMessageLongForm EXCEPT !.askReferenceNumberDelta = one] : one \in Sample(4) }
        \cup { [ZeroAddQuoteMessageLongForm EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroAddQuoteMessageLongForm EXCEPT !.bid = one] : one \in Sample(4) }
        \cup { [ZeroAddQuoteMessageLongForm EXCEPT !.bidSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroAddQuoteMessageLongForm EXCEPT !.ask = one] : one \in Sample(4) }
        \cup { [ZeroAddQuoteMessageLongForm EXCEPT !.askSizeLong = one] : one \in Sample(4) }

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
(* Single Side Order Executed With Price Message: 25 bytes                 *)
(***************************************************************************)

SingleSideOrderExecutedWithPriceMessage ==
    [ nanoseconds          : Sample(4),
      referenceNumberDelta : Sample(4),
      crossNumber          : Sample(4),
      matchNumber          : Sample(4),
      printable            : Sample(1),
      priceLong            : Sample(4),
      volumeLong           : Sample(4) ]

EncodeSingleSideOrderExecutedWithPriceMessage(message) ==
    message.nanoseconds
        \o message.referenceNumberDelta
        \o message.crossNumber
        \o message.matchNumber
        \o message.printable
        \o message.priceLong
        \o message.volumeLong

DecodeSingleSideOrderExecutedWithPriceMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET referenceNumberDelta == ReadBytes(nanoseconds.rest, 4) IN IF ~referenceNumberDelta.ok THEN Fail ELSE
    LET crossNumber == ReadBytes(referenceNumberDelta.rest, 4) IN IF ~crossNumber.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(crossNumber.rest, 4) IN IF ~matchNumber.ok THEN Fail ELSE
    LET printable == ReadBytes(matchNumber.rest, 1) IN IF ~printable.ok THEN Fail ELSE
    LET priceLong == ReadBytes(printable.rest, 4) IN IF ~priceLong.ok THEN Fail ELSE
    LET volumeLong == ReadBytes(priceLong.rest, 4) IN IF ~volumeLong.ok THEN Fail ELSE
    Ok([ nanoseconds          |-> nanoseconds.value,
         referenceNumberDelta |-> referenceNumberDelta.value,
         crossNumber          |-> crossNumber.value,
         matchNumber          |-> matchNumber.value,
         printable            |-> printable.value,
         priceLong            |-> priceLong.value,
         volumeLong           |-> volumeLong.value ], volumeLong.rest)

ZeroSingleSideOrderExecutedWithPriceMessage ==
    [ nanoseconds          |-> [i \in 1 .. 4 |-> 0],
      referenceNumberDelta |-> [i \in 1 .. 4 |-> 0],
      crossNumber          |-> [i \in 1 .. 4 |-> 0],
      matchNumber          |-> [i \in 1 .. 4 |-> 0],
      printable            |-> [i \in 1 .. 1 |-> 0],
      priceLong            |-> [i \in 1 .. 4 |-> 0],
      volumeLong           |-> [i \in 1 .. 4 |-> 0] ]

(* Single Side Order Executed With Price Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleSideOrderExecutedWithPriceMessage ==
    { ZeroSingleSideOrderExecutedWithPriceMessage }
        \cup { [ZeroSingleSideOrderExecutedWithPriceMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideOrderExecutedWithPriceMessage EXCEPT !.referenceNumberDelta = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideOrderExecutedWithPriceMessage EXCEPT !.crossNumber = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideOrderExecutedWithPriceMessage EXCEPT !.matchNumber = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideOrderExecutedWithPriceMessage EXCEPT !.printable = one] : one \in Sample(1) }
        \cup { [ZeroSingleSideOrderExecutedWithPriceMessage EXCEPT !.priceLong = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideOrderExecutedWithPriceMessage EXCEPT !.volumeLong = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Cancel Message: 12 bytes                                          *)
(***************************************************************************)

OrderCancelMessage ==
    [ nanoseconds               : Sample(4),
      orderReferenceNumberDelta : Sample(4),
      cancelledContracts        : Sample(4) ]

EncodeOrderCancelMessage(message) ==
    message.nanoseconds
        \o message.orderReferenceNumberDelta
        \o message.cancelledContracts

DecodeOrderCancelMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderReferenceNumberDelta == ReadBytes(nanoseconds.rest, 4) IN IF ~orderReferenceNumberDelta.ok THEN Fail ELSE
    LET cancelledContracts == ReadBytes(orderReferenceNumberDelta.rest, 4) IN IF ~cancelledContracts.ok THEN Fail ELSE
    Ok([ nanoseconds               |-> nanoseconds.value,
         orderReferenceNumberDelta |-> orderReferenceNumberDelta.value,
         cancelledContracts        |-> cancelledContracts.value ], cancelledContracts.rest)

ZeroOrderCancelMessage ==
    [ nanoseconds               |-> [i \in 1 .. 4 |-> 0],
      orderReferenceNumberDelta |-> [i \in 1 .. 4 |-> 0],
      cancelledContracts        |-> [i \in 1 .. 4 |-> 0] ]

(* Order Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelMessage ==
    { ZeroOrderCancelMessage }
        \cup { [ZeroOrderCancelMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.orderReferenceNumberDelta = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.cancelledContracts = one] : one \in Sample(4) }

(***************************************************************************)
(* Single Side Replace Message Short Form: 16 bytes                        *)
(***************************************************************************)

SingleSideReplaceMessageShortForm ==
    [ nanoseconds                  : Sample(4),
      originalReferenceNumberDelta : Sample(4),
      newReferenceNumberDelta      : Sample(4),
      price                        : Sample(2),
      volume                       : Sample(2) ]

EncodeSingleSideReplaceMessageShortForm(message) ==
    message.nanoseconds
        \o message.originalReferenceNumberDelta
        \o message.newReferenceNumberDelta
        \o message.price
        \o message.volume

DecodeSingleSideReplaceMessageShortForm(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET originalReferenceNumberDelta == ReadBytes(nanoseconds.rest, 4) IN IF ~originalReferenceNumberDelta.ok THEN Fail ELSE
    LET newReferenceNumberDelta == ReadBytes(originalReferenceNumberDelta.rest, 4) IN IF ~newReferenceNumberDelta.ok THEN Fail ELSE
    LET price == ReadBytes(newReferenceNumberDelta.rest, 2) IN IF ~price.ok THEN Fail ELSE
    LET volume == ReadBytes(price.rest, 2) IN IF ~volume.ok THEN Fail ELSE
    Ok([ nanoseconds                  |-> nanoseconds.value,
         originalReferenceNumberDelta |-> originalReferenceNumberDelta.value,
         newReferenceNumberDelta      |-> newReferenceNumberDelta.value,
         price                        |-> price.value,
         volume                       |-> volume.value ], volume.rest)

ZeroSingleSideReplaceMessageShortForm ==
    [ nanoseconds                  |-> [i \in 1 .. 4 |-> 0],
      originalReferenceNumberDelta |-> [i \in 1 .. 4 |-> 0],
      newReferenceNumberDelta      |-> [i \in 1 .. 4 |-> 0],
      price                        |-> [i \in 1 .. 2 |-> 0],
      volume                       |-> [i \in 1 .. 2 |-> 0] ]

(* Single Side Replace Message Short Form at zero, then each field in turn at the values it is checked at *)
CheckedSingleSideReplaceMessageShortForm ==
    { ZeroSingleSideReplaceMessageShortForm }
        \cup { [ZeroSingleSideReplaceMessageShortForm EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideReplaceMessageShortForm EXCEPT !.originalReferenceNumberDelta = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideReplaceMessageShortForm EXCEPT !.newReferenceNumberDelta = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideReplaceMessageShortForm EXCEPT !.price = one] : one \in Sample(2) }
        \cup { [ZeroSingleSideReplaceMessageShortForm EXCEPT !.volume = one] : one \in Sample(2) }

(***************************************************************************)
(* Single Side Replace Message Long Form: 20 bytes                         *)
(***************************************************************************)

SingleSideReplaceMessageLongForm ==
    [ nanoseconds                  : Sample(4),
      originalReferenceNumberDelta : Sample(4),
      newReferenceNumberDelta      : Sample(4),
      priceLong                    : Sample(4),
      volumeLong                   : Sample(4) ]

EncodeSingleSideReplaceMessageLongForm(message) ==
    message.nanoseconds
        \o message.originalReferenceNumberDelta
        \o message.newReferenceNumberDelta
        \o message.priceLong
        \o message.volumeLong

DecodeSingleSideReplaceMessageLongForm(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET originalReferenceNumberDelta == ReadBytes(nanoseconds.rest, 4) IN IF ~originalReferenceNumberDelta.ok THEN Fail ELSE
    LET newReferenceNumberDelta == ReadBytes(originalReferenceNumberDelta.rest, 4) IN IF ~newReferenceNumberDelta.ok THEN Fail ELSE
    LET priceLong == ReadBytes(newReferenceNumberDelta.rest, 4) IN IF ~priceLong.ok THEN Fail ELSE
    LET volumeLong == ReadBytes(priceLong.rest, 4) IN IF ~volumeLong.ok THEN Fail ELSE
    Ok([ nanoseconds                  |-> nanoseconds.value,
         originalReferenceNumberDelta |-> originalReferenceNumberDelta.value,
         newReferenceNumberDelta      |-> newReferenceNumberDelta.value,
         priceLong                    |-> priceLong.value,
         volumeLong                   |-> volumeLong.value ], volumeLong.rest)

ZeroSingleSideReplaceMessageLongForm ==
    [ nanoseconds                  |-> [i \in 1 .. 4 |-> 0],
      originalReferenceNumberDelta |-> [i \in 1 .. 4 |-> 0],
      newReferenceNumberDelta      |-> [i \in 1 .. 4 |-> 0],
      priceLong                    |-> [i \in 1 .. 4 |-> 0],
      volumeLong                   |-> [i \in 1 .. 4 |-> 0] ]

(* Single Side Replace Message Long Form at zero, then each field in turn at the values it is checked at *)
CheckedSingleSideReplaceMessageLongForm ==
    { ZeroSingleSideReplaceMessageLongForm }
        \cup { [ZeroSingleSideReplaceMessageLongForm EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideReplaceMessageLongForm EXCEPT !.originalReferenceNumberDelta = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideReplaceMessageLongForm EXCEPT !.newReferenceNumberDelta = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideReplaceMessageLongForm EXCEPT !.priceLong = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideReplaceMessageLongForm EXCEPT !.volumeLong = one] : one \in Sample(4) }

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
      priceLong            : Sample(4),
      volumeLong           : Sample(4) ]

EncodeSingleSideUpdateMessage(message) ==
    message.nanoseconds
        \o message.referenceNumberDelta
        \o message.changeReason
        \o message.priceLong
        \o message.volumeLong

DecodeSingleSideUpdateMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET referenceNumberDelta == ReadBytes(nanoseconds.rest, 4) IN IF ~referenceNumberDelta.ok THEN Fail ELSE
    LET changeReason == ReadBytes(referenceNumberDelta.rest, 1) IN IF ~changeReason.ok THEN Fail ELSE
    LET priceLong == ReadBytes(changeReason.rest, 4) IN IF ~priceLong.ok THEN Fail ELSE
    LET volumeLong == ReadBytes(priceLong.rest, 4) IN IF ~volumeLong.ok THEN Fail ELSE
    Ok([ nanoseconds          |-> nanoseconds.value,
         referenceNumberDelta |-> referenceNumberDelta.value,
         changeReason         |-> changeReason.value,
         priceLong            |-> priceLong.value,
         volumeLong           |-> volumeLong.value ], volumeLong.rest)

ZeroSingleSideUpdateMessage ==
    [ nanoseconds          |-> [i \in 1 .. 4 |-> 0],
      referenceNumberDelta |-> [i \in 1 .. 4 |-> 0],
      changeReason         |-> [i \in 1 .. 1 |-> 0],
      priceLong            |-> [i \in 1 .. 4 |-> 0],
      volumeLong           |-> [i \in 1 .. 4 |-> 0] ]

(* Single Side Update Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleSideUpdateMessage ==
    { ZeroSingleSideUpdateMessage }
        \cup { [ZeroSingleSideUpdateMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideUpdateMessage EXCEPT !.referenceNumberDelta = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideUpdateMessage EXCEPT !.changeReason = one] : one \in Sample(1) }
        \cup { [ZeroSingleSideUpdateMessage EXCEPT !.priceLong = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideUpdateMessage EXCEPT !.volumeLong = one] : one \in Sample(4) }

(***************************************************************************)
(* Quote Replace Message Short Form: 28 bytes                              *)
(***************************************************************************)

QuoteReplaceMessageShortForm ==
    [ nanoseconds                     : Sample(4),
      originalBidReferenceNumberDelta : Sample(4),
      bidReferenceNumberDelta         : Sample(4),
      originalAskReferenceNumberDelta : Sample(4),
      askReferenceDeltaNumber         : Sample(4),
      bidPrice                        : Sample(2),
      bidSize                         : Sample(2),
      askPrice                        : Sample(2),
      askSize                         : Sample(2) ]

EncodeQuoteReplaceMessageShortForm(message) ==
    message.nanoseconds
        \o message.originalBidReferenceNumberDelta
        \o message.bidReferenceNumberDelta
        \o message.originalAskReferenceNumberDelta
        \o message.askReferenceDeltaNumber
        \o message.bidPrice
        \o message.bidSize
        \o message.askPrice
        \o message.askSize

DecodeQuoteReplaceMessageShortForm(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET originalBidReferenceNumberDelta == ReadBytes(nanoseconds.rest, 4) IN IF ~originalBidReferenceNumberDelta.ok THEN Fail ELSE
    LET bidReferenceNumberDelta == ReadBytes(originalBidReferenceNumberDelta.rest, 4) IN IF ~bidReferenceNumberDelta.ok THEN Fail ELSE
    LET originalAskReferenceNumberDelta == ReadBytes(bidReferenceNumberDelta.rest, 4) IN IF ~originalAskReferenceNumberDelta.ok THEN Fail ELSE
    LET askReferenceDeltaNumber == ReadBytes(originalAskReferenceNumberDelta.rest, 4) IN IF ~askReferenceDeltaNumber.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(askReferenceDeltaNumber.rest, 2) IN IF ~bidPrice.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPrice.rest, 2) IN IF ~bidSize.ok THEN Fail ELSE
    LET askPrice == ReadBytes(bidSize.rest, 2) IN IF ~askPrice.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPrice.rest, 2) IN IF ~askSize.ok THEN Fail ELSE
    Ok([ nanoseconds                     |-> nanoseconds.value,
         originalBidReferenceNumberDelta |-> originalBidReferenceNumberDelta.value,
         bidReferenceNumberDelta         |-> bidReferenceNumberDelta.value,
         originalAskReferenceNumberDelta |-> originalAskReferenceNumberDelta.value,
         askReferenceDeltaNumber         |-> askReferenceDeltaNumber.value,
         bidPrice                        |-> bidPrice.value,
         bidSize                         |-> bidSize.value,
         askPrice                        |-> askPrice.value,
         askSize                         |-> askSize.value ], askSize.rest)

ZeroQuoteReplaceMessageShortForm ==
    [ nanoseconds                     |-> [i \in 1 .. 4 |-> 0],
      originalBidReferenceNumberDelta |-> [i \in 1 .. 4 |-> 0],
      bidReferenceNumberDelta         |-> [i \in 1 .. 4 |-> 0],
      originalAskReferenceNumberDelta |-> [i \in 1 .. 4 |-> 0],
      askReferenceDeltaNumber         |-> [i \in 1 .. 4 |-> 0],
      bidPrice                        |-> [i \in 1 .. 2 |-> 0],
      bidSize                         |-> [i \in 1 .. 2 |-> 0],
      askPrice                        |-> [i \in 1 .. 2 |-> 0],
      askSize                         |-> [i \in 1 .. 2 |-> 0] ]

(* Quote Replace Message Short Form at zero, then each field in turn at the values it is checked at *)
CheckedQuoteReplaceMessageShortForm ==
    { ZeroQuoteReplaceMessageShortForm }
        \cup { [ZeroQuoteReplaceMessageShortForm EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroQuoteReplaceMessageShortForm EXCEPT !.originalBidReferenceNumberDelta = one] : one \in Sample(4) }
        \cup { [ZeroQuoteReplaceMessageShortForm EXCEPT !.bidReferenceNumberDelta = one] : one \in Sample(4) }
        \cup { [ZeroQuoteReplaceMessageShortForm EXCEPT !.originalAskReferenceNumberDelta = one] : one \in Sample(4) }
        \cup { [ZeroQuoteReplaceMessageShortForm EXCEPT !.askReferenceDeltaNumber = one] : one \in Sample(4) }
        \cup { [ZeroQuoteReplaceMessageShortForm EXCEPT !.bidPrice = one] : one \in Sample(2) }
        \cup { [ZeroQuoteReplaceMessageShortForm EXCEPT !.bidSize = one] : one \in Sample(2) }
        \cup { [ZeroQuoteReplaceMessageShortForm EXCEPT !.askPrice = one] : one \in Sample(2) }
        \cup { [ZeroQuoteReplaceMessageShortForm EXCEPT !.askSize = one] : one \in Sample(2) }

(***************************************************************************)
(* Quote Replace Message Long Form: 36 bytes                               *)
(***************************************************************************)

QuoteReplaceMessageLongForm ==
    [ nanoseconds                     : Sample(4),
      originalBidReferenceNumberDelta : Sample(4),
      bidReferenceNumberDelta         : Sample(4),
      originalAskReferenceNumberDelta : Sample(4),
      askReferenceDeltaNumber         : Sample(4),
      bidPriceLong                    : Sample(4),
      bidSizeLong                     : Sample(4),
      askPriceLong                    : Sample(4),
      askSizeLong                     : Sample(4) ]

EncodeQuoteReplaceMessageLongForm(message) ==
    message.nanoseconds
        \o message.originalBidReferenceNumberDelta
        \o message.bidReferenceNumberDelta
        \o message.originalAskReferenceNumberDelta
        \o message.askReferenceDeltaNumber
        \o message.bidPriceLong
        \o message.bidSizeLong
        \o message.askPriceLong
        \o message.askSizeLong

DecodeQuoteReplaceMessageLongForm(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET originalBidReferenceNumberDelta == ReadBytes(nanoseconds.rest, 4) IN IF ~originalBidReferenceNumberDelta.ok THEN Fail ELSE
    LET bidReferenceNumberDelta == ReadBytes(originalBidReferenceNumberDelta.rest, 4) IN IF ~bidReferenceNumberDelta.ok THEN Fail ELSE
    LET originalAskReferenceNumberDelta == ReadBytes(bidReferenceNumberDelta.rest, 4) IN IF ~originalAskReferenceNumberDelta.ok THEN Fail ELSE
    LET askReferenceDeltaNumber == ReadBytes(originalAskReferenceNumberDelta.rest, 4) IN IF ~askReferenceDeltaNumber.ok THEN Fail ELSE
    LET bidPriceLong == ReadBytes(askReferenceDeltaNumber.rest, 4) IN IF ~bidPriceLong.ok THEN Fail ELSE
    LET bidSizeLong == ReadBytes(bidPriceLong.rest, 4) IN IF ~bidSizeLong.ok THEN Fail ELSE
    LET askPriceLong == ReadBytes(bidSizeLong.rest, 4) IN IF ~askPriceLong.ok THEN Fail ELSE
    LET askSizeLong == ReadBytes(askPriceLong.rest, 4) IN IF ~askSizeLong.ok THEN Fail ELSE
    Ok([ nanoseconds                     |-> nanoseconds.value,
         originalBidReferenceNumberDelta |-> originalBidReferenceNumberDelta.value,
         bidReferenceNumberDelta         |-> bidReferenceNumberDelta.value,
         originalAskReferenceNumberDelta |-> originalAskReferenceNumberDelta.value,
         askReferenceDeltaNumber         |-> askReferenceDeltaNumber.value,
         bidPriceLong                    |-> bidPriceLong.value,
         bidSizeLong                     |-> bidSizeLong.value,
         askPriceLong                    |-> askPriceLong.value,
         askSizeLong                     |-> askSizeLong.value ], askSizeLong.rest)

ZeroQuoteReplaceMessageLongForm ==
    [ nanoseconds                     |-> [i \in 1 .. 4 |-> 0],
      originalBidReferenceNumberDelta |-> [i \in 1 .. 4 |-> 0],
      bidReferenceNumberDelta         |-> [i \in 1 .. 4 |-> 0],
      originalAskReferenceNumberDelta |-> [i \in 1 .. 4 |-> 0],
      askReferenceDeltaNumber         |-> [i \in 1 .. 4 |-> 0],
      bidPriceLong                    |-> [i \in 1 .. 4 |-> 0],
      bidSizeLong                     |-> [i \in 1 .. 4 |-> 0],
      askPriceLong                    |-> [i \in 1 .. 4 |-> 0],
      askSizeLong                     |-> [i \in 1 .. 4 |-> 0] ]

(* Quote Replace Message Long Form at zero, then each field in turn at the values it is checked at *)
CheckedQuoteReplaceMessageLongForm ==
    { ZeroQuoteReplaceMessageLongForm }
        \cup { [ZeroQuoteReplaceMessageLongForm EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroQuoteReplaceMessageLongForm EXCEPT !.originalBidReferenceNumberDelta = one] : one \in Sample(4) }
        \cup { [ZeroQuoteReplaceMessageLongForm EXCEPT !.bidReferenceNumberDelta = one] : one \in Sample(4) }
        \cup { [ZeroQuoteReplaceMessageLongForm EXCEPT !.originalAskReferenceNumberDelta = one] : one \in Sample(4) }
        \cup { [ZeroQuoteReplaceMessageLongForm EXCEPT !.askReferenceDeltaNumber = one] : one \in Sample(4) }
        \cup { [ZeroQuoteReplaceMessageLongForm EXCEPT !.bidPriceLong = one] : one \in Sample(4) }
        \cup { [ZeroQuoteReplaceMessageLongForm EXCEPT !.bidSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroQuoteReplaceMessageLongForm EXCEPT !.askPriceLong = one] : one \in Sample(4) }
        \cup { [ZeroQuoteReplaceMessageLongForm EXCEPT !.askSizeLong = one] : one \in Sample(4) }

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
    [ nanoseconds                        : Sample(4),
      totalNumberOfReferenceNumberDeltas : Sample(2),
      referenceNumberDeltan              : Sample(4) ]

EncodeBlockDeleteMessage(message) ==
    message.nanoseconds
        \o message.totalNumberOfReferenceNumberDeltas
        \o message.referenceNumberDeltan

DecodeBlockDeleteMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET totalNumberOfReferenceNumberDeltas == ReadBytes(nanoseconds.rest, 2) IN IF ~totalNumberOfReferenceNumberDeltas.ok THEN Fail ELSE
    LET referenceNumberDeltan == ReadBytes(totalNumberOfReferenceNumberDeltas.rest, 4) IN IF ~referenceNumberDeltan.ok THEN Fail ELSE
    Ok([ nanoseconds                        |-> nanoseconds.value,
         totalNumberOfReferenceNumberDeltas |-> totalNumberOfReferenceNumberDeltas.value,
         referenceNumberDeltan              |-> referenceNumberDeltan.value ], referenceNumberDeltan.rest)

ZeroBlockDeleteMessage ==
    [ nanoseconds                        |-> [i \in 1 .. 4 |-> 0],
      totalNumberOfReferenceNumberDeltas |-> [i \in 1 .. 2 |-> 0],
      referenceNumberDeltan              |-> [i \in 1 .. 4 |-> 0] ]

(* Block Delete Message at zero, then each field in turn at the values it is checked at *)
CheckedBlockDeleteMessage ==
    { ZeroBlockDeleteMessage }
        \cup { [ZeroBlockDeleteMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroBlockDeleteMessage EXCEPT !.totalNumberOfReferenceNumberDeltas = one] : one \in Sample(2) }
        \cup { [ZeroBlockDeleteMessage EXCEPT !.referenceNumberDeltan = one] : one \in Sample(4) }

(***************************************************************************)
(* Non Auction Options Trade Message: 25 bytes                             *)
(***************************************************************************)

NonAuctionOptionsTradeMessage ==
    [ nanoseconds      : Sample(4),
      buySellIndicator : Sample(1),
      optionId         : Sample(4),
      crossNumber      : Sample(4),
      matchNumber      : Sample(4),
      priceLong        : Sample(4),
      volumeLong       : Sample(4) ]

EncodeNonAuctionOptionsTradeMessage(message) ==
    message.nanoseconds
        \o message.buySellIndicator
        \o message.optionId
        \o message.crossNumber
        \o message.matchNumber
        \o message.priceLong
        \o message.volumeLong

DecodeNonAuctionOptionsTradeMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET buySellIndicator == ReadBytes(nanoseconds.rest, 1) IN IF ~buySellIndicator.ok THEN Fail ELSE
    LET optionId == ReadBytes(buySellIndicator.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET crossNumber == ReadBytes(optionId.rest, 4) IN IF ~crossNumber.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(crossNumber.rest, 4) IN IF ~matchNumber.ok THEN Fail ELSE
    LET priceLong == ReadBytes(matchNumber.rest, 4) IN IF ~priceLong.ok THEN Fail ELSE
    LET volumeLong == ReadBytes(priceLong.rest, 4) IN IF ~volumeLong.ok THEN Fail ELSE
    Ok([ nanoseconds      |-> nanoseconds.value,
         buySellIndicator |-> buySellIndicator.value,
         optionId         |-> optionId.value,
         crossNumber      |-> crossNumber.value,
         matchNumber      |-> matchNumber.value,
         priceLong        |-> priceLong.value,
         volumeLong       |-> volumeLong.value ], volumeLong.rest)

ZeroNonAuctionOptionsTradeMessage ==
    [ nanoseconds      |-> [i \in 1 .. 4 |-> 0],
      buySellIndicator |-> [i \in 1 .. 1 |-> 0],
      optionId         |-> [i \in 1 .. 4 |-> 0],
      crossNumber      |-> [i \in 1 .. 4 |-> 0],
      matchNumber      |-> [i \in 1 .. 4 |-> 0],
      priceLong        |-> [i \in 1 .. 4 |-> 0],
      volumeLong       |-> [i \in 1 .. 4 |-> 0] ]

(* Non Auction Options Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedNonAuctionOptionsTradeMessage ==
    { ZeroNonAuctionOptionsTradeMessage }
        \cup { [ZeroNonAuctionOptionsTradeMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroNonAuctionOptionsTradeMessage EXCEPT !.buySellIndicator = one] : one \in Sample(1) }
        \cup { [ZeroNonAuctionOptionsTradeMessage EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroNonAuctionOptionsTradeMessage EXCEPT !.crossNumber = one] : one \in Sample(4) }
        \cup { [ZeroNonAuctionOptionsTradeMessage EXCEPT !.matchNumber = one] : one \in Sample(4) }
        \cup { [ZeroNonAuctionOptionsTradeMessage EXCEPT !.priceLong = one] : one \in Sample(4) }
        \cup { [ZeroNonAuctionOptionsTradeMessage EXCEPT !.volumeLong = one] : one \in Sample(4) }

(***************************************************************************)
(* Options Cross Trade Message: 25 bytes                                   *)
(***************************************************************************)

OptionsCrossTradeMessage ==
    [ nanoseconds : Sample(4),
      optionId    : Sample(4),
      crossNumber : Sample(4),
      matchNumber : Sample(4),
      crossType   : Sample(1),
      priceLong   : Sample(4),
      volumeLong  : Sample(4) ]

EncodeOptionsCrossTradeMessage(message) ==
    message.nanoseconds
        \o message.optionId
        \o message.crossNumber
        \o message.matchNumber
        \o message.crossType
        \o message.priceLong
        \o message.volumeLong

DecodeOptionsCrossTradeMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET optionId == ReadBytes(nanoseconds.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET crossNumber == ReadBytes(optionId.rest, 4) IN IF ~crossNumber.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(crossNumber.rest, 4) IN IF ~matchNumber.ok THEN Fail ELSE
    LET crossType == ReadBytes(matchNumber.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET priceLong == ReadBytes(crossType.rest, 4) IN IF ~priceLong.ok THEN Fail ELSE
    LET volumeLong == ReadBytes(priceLong.rest, 4) IN IF ~volumeLong.ok THEN Fail ELSE
    Ok([ nanoseconds |-> nanoseconds.value,
         optionId    |-> optionId.value,
         crossNumber |-> crossNumber.value,
         matchNumber |-> matchNumber.value,
         crossType   |-> crossType.value,
         priceLong   |-> priceLong.value,
         volumeLong  |-> volumeLong.value ], volumeLong.rest)

ZeroOptionsCrossTradeMessage ==
    [ nanoseconds |-> [i \in 1 .. 4 |-> 0],
      optionId    |-> [i \in 1 .. 4 |-> 0],
      crossNumber |-> [i \in 1 .. 4 |-> 0],
      matchNumber |-> [i \in 1 .. 4 |-> 0],
      crossType   |-> [i \in 1 .. 1 |-> 0],
      priceLong   |-> [i \in 1 .. 4 |-> 0],
      volumeLong  |-> [i \in 1 .. 4 |-> 0] ]

(* Options Cross Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionsCrossTradeMessage ==
    { ZeroOptionsCrossTradeMessage }
        \cup { [ZeroOptionsCrossTradeMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOptionsCrossTradeMessage EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroOptionsCrossTradeMessage EXCEPT !.crossNumber = one] : one \in Sample(4) }
        \cup { [ZeroOptionsCrossTradeMessage EXCEPT !.matchNumber = one] : one \in Sample(4) }
        \cup { [ZeroOptionsCrossTradeMessage EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroOptionsCrossTradeMessage EXCEPT !.priceLong = one] : one \in Sample(4) }
        \cup { [ZeroOptionsCrossTradeMessage EXCEPT !.volumeLong = one] : one \in Sample(4) }

(***************************************************************************)
(* Broken Trade Or Order Execution Message: 12 bytes                       *)
(***************************************************************************)

BrokenTradeOrOrderExecutionMessage ==
    [ nanoseconds : Sample(4),
      crossNumber : Sample(4),
      matchNumber : Sample(4) ]

EncodeBrokenTradeOrOrderExecutionMessage(message) ==
    message.nanoseconds
        \o message.crossNumber
        \o message.matchNumber

DecodeBrokenTradeOrOrderExecutionMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET crossNumber == ReadBytes(nanoseconds.rest, 4) IN IF ~crossNumber.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(crossNumber.rest, 4) IN IF ~matchNumber.ok THEN Fail ELSE
    Ok([ nanoseconds |-> nanoseconds.value,
         crossNumber |-> crossNumber.value,
         matchNumber |-> matchNumber.value ], matchNumber.rest)

ZeroBrokenTradeOrOrderExecutionMessage ==
    [ nanoseconds |-> [i \in 1 .. 4 |-> 0],
      crossNumber |-> [i \in 1 .. 4 |-> 0],
      matchNumber |-> [i \in 1 .. 4 |-> 0] ]

(* Broken Trade Or Order Execution Message at zero, then each field in turn at the values it is checked at *)
CheckedBrokenTradeOrOrderExecutionMessage ==
    { ZeroBrokenTradeOrOrderExecutionMessage }
        \cup { [ZeroBrokenTradeOrOrderExecutionMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroBrokenTradeOrOrderExecutionMessage EXCEPT !.crossNumber = one] : one \in Sample(4) }
        \cup { [ZeroBrokenTradeOrOrderExecutionMessage EXCEPT !.matchNumber = one] : one \in Sample(4) }

(***************************************************************************)
(* Net Order Imbalance Indicator Message: 30 bytes                         *)
(***************************************************************************)

NetOrderImbalanceIndicatorMessage ==
    [ nanoseconds           : Sample(4),
      auctionId             : Sample(4),
      auctionType           : Sample(1),
      pairedContracts       : Sample(4),
      imbalanceDirection    : Sample(1),
      optionId              : Sample(4),
      imbalancePrice        : Sample(4),
      imbalanceVolume       : Sample(4),
      customerFirmIndicator : Sample(1),
      reserved3             : Sample(3) ]

EncodeNetOrderImbalanceIndicatorMessage(message) ==
    message.nanoseconds
        \o message.auctionId
        \o message.auctionType
        \o message.pairedContracts
        \o message.imbalanceDirection
        \o message.optionId
        \o message.imbalancePrice
        \o message.imbalanceVolume
        \o message.customerFirmIndicator
        \o message.reserved3

DecodeNetOrderImbalanceIndicatorMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET auctionId == ReadBytes(nanoseconds.rest, 4) IN IF ~auctionId.ok THEN Fail ELSE
    LET auctionType == ReadBytes(auctionId.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET pairedContracts == ReadBytes(auctionType.rest, 4) IN IF ~pairedContracts.ok THEN Fail ELSE
    LET imbalanceDirection == ReadBytes(pairedContracts.rest, 1) IN IF ~imbalanceDirection.ok THEN Fail ELSE
    LET optionId == ReadBytes(imbalanceDirection.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET imbalancePrice == ReadBytes(optionId.rest, 4) IN IF ~imbalancePrice.ok THEN Fail ELSE
    LET imbalanceVolume == ReadBytes(imbalancePrice.rest, 4) IN IF ~imbalanceVolume.ok THEN Fail ELSE
    LET customerFirmIndicator == ReadBytes(imbalanceVolume.rest, 1) IN IF ~customerFirmIndicator.ok THEN Fail ELSE
    LET reserved3 == ReadBytes(customerFirmIndicator.rest, 3) IN IF ~reserved3.ok THEN Fail ELSE
    Ok([ nanoseconds           |-> nanoseconds.value,
         auctionId             |-> auctionId.value,
         auctionType           |-> auctionType.value,
         pairedContracts       |-> pairedContracts.value,
         imbalanceDirection    |-> imbalanceDirection.value,
         optionId              |-> optionId.value,
         imbalancePrice        |-> imbalancePrice.value,
         imbalanceVolume       |-> imbalanceVolume.value,
         customerFirmIndicator |-> customerFirmIndicator.value,
         reserved3             |-> reserved3.value ], reserved3.rest)

ZeroNetOrderImbalanceIndicatorMessage ==
    [ nanoseconds           |-> [i \in 1 .. 4 |-> 0],
      auctionId             |-> [i \in 1 .. 4 |-> 0],
      auctionType           |-> [i \in 1 .. 1 |-> 0],
      pairedContracts       |-> [i \in 1 .. 4 |-> 0],
      imbalanceDirection    |-> [i \in 1 .. 1 |-> 0],
      optionId              |-> [i \in 1 .. 4 |-> 0],
      imbalancePrice        |-> [i \in 1 .. 4 |-> 0],
      imbalanceVolume       |-> [i \in 1 .. 4 |-> 0],
      customerFirmIndicator |-> [i \in 1 .. 1 |-> 0],
      reserved3             |-> [i \in 1 .. 3 |-> 0] ]

(* Net Order Imbalance Indicator Message at zero, then each field in turn at the values it is checked at *)
CheckedNetOrderImbalanceIndicatorMessage ==
    { ZeroNetOrderImbalanceIndicatorMessage }
        \cup { [ZeroNetOrderImbalanceIndicatorMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroNetOrderImbalanceIndicatorMessage EXCEPT !.auctionId = one] : one \in Sample(4) }
        \cup { [ZeroNetOrderImbalanceIndicatorMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroNetOrderImbalanceIndicatorMessage EXCEPT !.pairedContracts = one] : one \in Sample(4) }
        \cup { [ZeroNetOrderImbalanceIndicatorMessage EXCEPT !.imbalanceDirection = one] : one \in Sample(1) }
        \cup { [ZeroNetOrderImbalanceIndicatorMessage EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroNetOrderImbalanceIndicatorMessage EXCEPT !.imbalancePrice = one] : one \in Sample(4) }
        \cup { [ZeroNetOrderImbalanceIndicatorMessage EXCEPT !.imbalanceVolume = one] : one \in Sample(4) }
        \cup { [ZeroNetOrderImbalanceIndicatorMessage EXCEPT !.customerFirmIndicator = one] : one \in Sample(1) }
        \cup { [ZeroNetOrderImbalanceIndicatorMessage EXCEPT !.reserved3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

SecondsMessageCode == 84  \* "T"
SystemEventMessageCode == 83  \* "S"
BaseReferenceMessageCode == 76  \* "L"
OptionDirectoryMessageCode == 82  \* "R"
TradingActionMessageCode == 72  \* "H"
OptionOpenMessageCode == 79  \* "O"
AddOrderMessageShortFormCode == 97  \* "a"
AddOrderMessageLongFormCode == 65  \* "A"
AddQuoteMessageShortFormCode == 106  \* "j"
AddQuoteMessageLongFormCode == 74  \* "J"
SingleSideExecutedMessageCode == 69  \* "E"
SingleSideOrderExecutedWithPriceMessageCode == 67  \* "C"
OrderCancelMessageCode == 88  \* "X"
SingleSideReplaceMessageShortFormCode == 117  \* "u"
SingleSideReplaceMessageLongFormCode == 85  \* "U"
SingleSideDeleteMessageCode == 68  \* "D"
SingleSideUpdateMessageCode == 71  \* "G"
QuoteReplaceMessageShortFormCode == 107  \* "k"
QuoteReplaceMessageLongFormCode == 75  \* "K"
QuoteDeleteMessageCode == 89  \* "Y"
BlockDeleteMessageCode == 90  \* "Z"
NonAuctionOptionsTradeMessageCode == 80  \* "P"
OptionsCrossTradeMessageCode == 81  \* "Q"
BrokenTradeOrOrderExecutionMessageCode == 66  \* "B"
NetOrderImbalanceIndicatorMessageCode == 73  \* "I"

Payload ==
    [ tag : {SecondsMessageCode}, body : SecondsMessage ]
        \cup [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {BaseReferenceMessageCode}, body : BaseReferenceMessage ]
        \cup [ tag : {OptionDirectoryMessageCode}, body : OptionDirectoryMessage ]
        \cup [ tag : {TradingActionMessageCode}, body : TradingActionMessage ]
        \cup [ tag : {OptionOpenMessageCode}, body : OptionOpenMessage ]
        \cup [ tag : {AddOrderMessageShortFormCode}, body : AddOrderMessageShortForm ]
        \cup [ tag : {AddOrderMessageLongFormCode}, body : AddOrderMessageLongForm ]
        \cup [ tag : {AddQuoteMessageShortFormCode}, body : AddQuoteMessageShortForm ]
        \cup [ tag : {AddQuoteMessageLongFormCode}, body : AddQuoteMessageLongForm ]
        \cup [ tag : {SingleSideExecutedMessageCode}, body : SingleSideExecutedMessage ]
        \cup [ tag : {SingleSideOrderExecutedWithPriceMessageCode}, body : SingleSideOrderExecutedWithPriceMessage ]
        \cup [ tag : {OrderCancelMessageCode}, body : OrderCancelMessage ]
        \cup [ tag : {SingleSideReplaceMessageShortFormCode}, body : SingleSideReplaceMessageShortForm ]
        \cup [ tag : {SingleSideReplaceMessageLongFormCode}, body : SingleSideReplaceMessageLongForm ]
        \cup [ tag : {SingleSideDeleteMessageCode}, body : SingleSideDeleteMessage ]
        \cup [ tag : {SingleSideUpdateMessageCode}, body : SingleSideUpdateMessage ]
        \cup [ tag : {QuoteReplaceMessageShortFormCode}, body : QuoteReplaceMessageShortForm ]
        \cup [ tag : {QuoteReplaceMessageLongFormCode}, body : QuoteReplaceMessageLongForm ]
        \cup [ tag : {QuoteDeleteMessageCode}, body : QuoteDeleteMessage ]
        \cup [ tag : {BlockDeleteMessageCode}, body : BlockDeleteMessage ]
        \cup [ tag : {NonAuctionOptionsTradeMessageCode}, body : NonAuctionOptionsTradeMessage ]
        \cup [ tag : {OptionsCrossTradeMessageCode}, body : OptionsCrossTradeMessage ]
        \cup [ tag : {BrokenTradeOrOrderExecutionMessageCode}, body : BrokenTradeOrOrderExecutionMessage ]
        \cup [ tag : {NetOrderImbalanceIndicatorMessageCode}, body : NetOrderImbalanceIndicatorMessage ]

EncodePayload(message) ==
    CASE message.tag = SecondsMessageCode -> EncodeSecondsMessage(message.body)
      [] message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = BaseReferenceMessageCode -> EncodeBaseReferenceMessage(message.body)
      [] message.tag = OptionDirectoryMessageCode -> EncodeOptionDirectoryMessage(message.body)
      [] message.tag = TradingActionMessageCode -> EncodeTradingActionMessage(message.body)
      [] message.tag = OptionOpenMessageCode -> EncodeOptionOpenMessage(message.body)
      [] message.tag = AddOrderMessageShortFormCode -> EncodeAddOrderMessageShortForm(message.body)
      [] message.tag = AddOrderMessageLongFormCode -> EncodeAddOrderMessageLongForm(message.body)
      [] message.tag = AddQuoteMessageShortFormCode -> EncodeAddQuoteMessageShortForm(message.body)
      [] message.tag = AddQuoteMessageLongFormCode -> EncodeAddQuoteMessageLongForm(message.body)
      [] message.tag = SingleSideExecutedMessageCode -> EncodeSingleSideExecutedMessage(message.body)
      [] message.tag = SingleSideOrderExecutedWithPriceMessageCode -> EncodeSingleSideOrderExecutedWithPriceMessage(message.body)
      [] message.tag = OrderCancelMessageCode -> EncodeOrderCancelMessage(message.body)
      [] message.tag = SingleSideReplaceMessageShortFormCode -> EncodeSingleSideReplaceMessageShortForm(message.body)
      [] message.tag = SingleSideReplaceMessageLongFormCode -> EncodeSingleSideReplaceMessageLongForm(message.body)
      [] message.tag = SingleSideDeleteMessageCode -> EncodeSingleSideDeleteMessage(message.body)
      [] message.tag = SingleSideUpdateMessageCode -> EncodeSingleSideUpdateMessage(message.body)
      [] message.tag = QuoteReplaceMessageShortFormCode -> EncodeQuoteReplaceMessageShortForm(message.body)
      [] message.tag = QuoteReplaceMessageLongFormCode -> EncodeQuoteReplaceMessageLongForm(message.body)
      [] message.tag = QuoteDeleteMessageCode -> EncodeQuoteDeleteMessage(message.body)
      [] message.tag = BlockDeleteMessageCode -> EncodeBlockDeleteMessage(message.body)
      [] message.tag = NonAuctionOptionsTradeMessageCode -> EncodeNonAuctionOptionsTradeMessage(message.body)
      [] message.tag = OptionsCrossTradeMessageCode -> EncodeOptionsCrossTradeMessage(message.body)
      [] message.tag = BrokenTradeOrOrderExecutionMessageCode -> EncodeBrokenTradeOrOrderExecutionMessage(message.body)
      [] message.tag = NetOrderImbalanceIndicatorMessageCode -> EncodeNetOrderImbalanceIndicatorMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = SecondsMessageCode -> DecodeSecondsMessage(bytes)
              [] tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = BaseReferenceMessageCode -> DecodeBaseReferenceMessage(bytes)
              [] tag = OptionDirectoryMessageCode -> DecodeOptionDirectoryMessage(bytes)
              [] tag = TradingActionMessageCode -> DecodeTradingActionMessage(bytes)
              [] tag = OptionOpenMessageCode -> DecodeOptionOpenMessage(bytes)
              [] tag = AddOrderMessageShortFormCode -> DecodeAddOrderMessageShortForm(bytes)
              [] tag = AddOrderMessageLongFormCode -> DecodeAddOrderMessageLongForm(bytes)
              [] tag = AddQuoteMessageShortFormCode -> DecodeAddQuoteMessageShortForm(bytes)
              [] tag = AddQuoteMessageLongFormCode -> DecodeAddQuoteMessageLongForm(bytes)
              [] tag = SingleSideExecutedMessageCode -> DecodeSingleSideExecutedMessage(bytes)
              [] tag = SingleSideOrderExecutedWithPriceMessageCode -> DecodeSingleSideOrderExecutedWithPriceMessage(bytes)
              [] tag = OrderCancelMessageCode -> DecodeOrderCancelMessage(bytes)
              [] tag = SingleSideReplaceMessageShortFormCode -> DecodeSingleSideReplaceMessageShortForm(bytes)
              [] tag = SingleSideReplaceMessageLongFormCode -> DecodeSingleSideReplaceMessageLongForm(bytes)
              [] tag = SingleSideDeleteMessageCode -> DecodeSingleSideDeleteMessage(bytes)
              [] tag = SingleSideUpdateMessageCode -> DecodeSingleSideUpdateMessage(bytes)
              [] tag = QuoteReplaceMessageShortFormCode -> DecodeQuoteReplaceMessageShortForm(bytes)
              [] tag = QuoteReplaceMessageLongFormCode -> DecodeQuoteReplaceMessageLongForm(bytes)
              [] tag = QuoteDeleteMessageCode -> DecodeQuoteDeleteMessage(bytes)
              [] tag = BlockDeleteMessageCode -> DecodeBlockDeleteMessage(bytes)
              [] tag = NonAuctionOptionsTradeMessageCode -> DecodeNonAuctionOptionsTradeMessage(bytes)
              [] tag = OptionsCrossTradeMessageCode -> DecodeOptionsCrossTradeMessage(bytes)
              [] tag = BrokenTradeOrOrderExecutionMessageCode -> DecodeBrokenTradeOrOrderExecutionMessage(bytes)
              [] tag = NetOrderImbalanceIndicatorMessageCode -> DecodeNetOrderImbalanceIndicatorMessage(bytes)
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
        \cup { [tag |-> OptionOpenMessageCode, body |-> one] : one \in CheckedOptionOpenMessage }
        \cup { [tag |-> AddOrderMessageShortFormCode, body |-> one] : one \in CheckedAddOrderMessageShortForm }
        \cup { [tag |-> AddOrderMessageLongFormCode, body |-> one] : one \in CheckedAddOrderMessageLongForm }
        \cup { [tag |-> AddQuoteMessageShortFormCode, body |-> one] : one \in CheckedAddQuoteMessageShortForm }
        \cup { [tag |-> AddQuoteMessageLongFormCode, body |-> one] : one \in CheckedAddQuoteMessageLongForm }
        \cup { [tag |-> SingleSideExecutedMessageCode, body |-> one] : one \in CheckedSingleSideExecutedMessage }
        \cup { [tag |-> SingleSideOrderExecutedWithPriceMessageCode, body |-> one] : one \in CheckedSingleSideOrderExecutedWithPriceMessage }
        \cup { [tag |-> OrderCancelMessageCode, body |-> one] : one \in CheckedOrderCancelMessage }
        \cup { [tag |-> SingleSideReplaceMessageShortFormCode, body |-> one] : one \in CheckedSingleSideReplaceMessageShortForm }
        \cup { [tag |-> SingleSideReplaceMessageLongFormCode, body |-> one] : one \in CheckedSingleSideReplaceMessageLongForm }
        \cup { [tag |-> SingleSideDeleteMessageCode, body |-> one] : one \in CheckedSingleSideDeleteMessage }
        \cup { [tag |-> SingleSideUpdateMessageCode, body |-> one] : one \in CheckedSingleSideUpdateMessage }
        \cup { [tag |-> QuoteReplaceMessageShortFormCode, body |-> one] : one \in CheckedQuoteReplaceMessageShortForm }
        \cup { [tag |-> QuoteReplaceMessageLongFormCode, body |-> one] : one \in CheckedQuoteReplaceMessageLongForm }
        \cup { [tag |-> QuoteDeleteMessageCode, body |-> one] : one \in CheckedQuoteDeleteMessage }
        \cup { [tag |-> BlockDeleteMessageCode, body |-> one] : one \in CheckedBlockDeleteMessage }
        \cup { [tag |-> NonAuctionOptionsTradeMessageCode, body |-> one] : one \in CheckedNonAuctionOptionsTradeMessage }
        \cup { [tag |-> OptionsCrossTradeMessageCode, body |-> one] : one \in CheckedOptionsCrossTradeMessage }
        \cup { [tag |-> BrokenTradeOrOrderExecutionMessageCode, body |-> one] : one \in CheckedBrokenTradeOrOrderExecutionMessage }
        \cup { [tag |-> NetOrderImbalanceIndicatorMessageCode, body |-> one] : one \in CheckedNetOrderImbalanceIndicatorMessage }

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
      [ZeroMessage EXCEPT !.payload = [tag |-> OptionOpenMessageCode, body |-> ZeroOptionOpenMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddOrderMessageShortFormCode, body |-> ZeroAddOrderMessageShortForm]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddOrderMessageLongFormCode, body |-> ZeroAddOrderMessageLongForm]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddQuoteMessageShortFormCode, body |-> ZeroAddQuoteMessageShortForm]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddQuoteMessageLongFormCode, body |-> ZeroAddQuoteMessageLongForm]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SingleSideExecutedMessageCode, body |-> ZeroSingleSideExecutedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SingleSideOrderExecutedWithPriceMessageCode, body |-> ZeroSingleSideOrderExecutedWithPriceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderCancelMessageCode, body |-> ZeroOrderCancelMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SingleSideReplaceMessageShortFormCode, body |-> ZeroSingleSideReplaceMessageShortForm]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SingleSideReplaceMessageLongFormCode, body |-> ZeroSingleSideReplaceMessageLongForm]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SingleSideDeleteMessageCode, body |-> ZeroSingleSideDeleteMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SingleSideUpdateMessageCode, body |-> ZeroSingleSideUpdateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> QuoteReplaceMessageShortFormCode, body |-> ZeroQuoteReplaceMessageShortForm]],
      [ZeroMessage EXCEPT !.payload = [tag |-> QuoteReplaceMessageLongFormCode, body |-> ZeroQuoteReplaceMessageLongForm]],
      [ZeroMessage EXCEPT !.payload = [tag |-> QuoteDeleteMessageCode, body |-> ZeroQuoteDeleteMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> BlockDeleteMessageCode, body |-> ZeroBlockDeleteMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> NonAuctionOptionsTradeMessageCode, body |-> ZeroNonAuctionOptionsTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OptionsCrossTradeMessageCode, body |-> ZeroOptionsCrossTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> BrokenTradeOrOrderExecutionMessageCode, body |-> ZeroBrokenTradeOrOrderExecutionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> NetOrderImbalanceIndicatorMessageCode, body |-> ZeroNetOrderImbalanceIndicatorMessage]] }

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

(* Every Option Open Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionOpenMessage ==
    \A message \in CheckedOptionOpenMessage :
        LET read == DecodeOptionOpenMessage(EncodeOptionOpenMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Order Message Short Form decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderMessageShortForm ==
    \A message \in CheckedAddOrderMessageShortForm :
        LET read == DecodeAddOrderMessageShortForm(EncodeAddOrderMessageShortForm(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Order Message Long Form decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderMessageLongForm ==
    \A message \in CheckedAddOrderMessageLongForm :
        LET read == DecodeAddOrderMessageLongForm(EncodeAddOrderMessageLongForm(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Quote Message Short Form decodes back to what was encoded, and leaves nothing over *)
RoundTripAddQuoteMessageShortForm ==
    \A message \in CheckedAddQuoteMessageShortForm :
        LET read == DecodeAddQuoteMessageShortForm(EncodeAddQuoteMessageShortForm(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Quote Message Long Form decodes back to what was encoded, and leaves nothing over *)
RoundTripAddQuoteMessageLongForm ==
    \A message \in CheckedAddQuoteMessageLongForm :
        LET read == DecodeAddQuoteMessageLongForm(EncodeAddQuoteMessageLongForm(message))
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

(* Every Single Side Order Executed With Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleSideOrderExecutedWithPriceMessage ==
    \A message \in CheckedSingleSideOrderExecutedWithPriceMessage :
        LET read == DecodeSingleSideOrderExecutedWithPriceMessage(EncodeSingleSideOrderExecutedWithPriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelMessage ==
    \A message \in CheckedOrderCancelMessage :
        LET read == DecodeOrderCancelMessage(EncodeOrderCancelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Side Replace Message Short Form decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleSideReplaceMessageShortForm ==
    \A message \in CheckedSingleSideReplaceMessageShortForm :
        LET read == DecodeSingleSideReplaceMessageShortForm(EncodeSingleSideReplaceMessageShortForm(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Side Replace Message Long Form decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleSideReplaceMessageLongForm ==
    \A message \in CheckedSingleSideReplaceMessageLongForm :
        LET read == DecodeSingleSideReplaceMessageLongForm(EncodeSingleSideReplaceMessageLongForm(message))
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

(* Every Quote Replace Message Short Form decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteReplaceMessageShortForm ==
    \A message \in CheckedQuoteReplaceMessageShortForm :
        LET read == DecodeQuoteReplaceMessageShortForm(EncodeQuoteReplaceMessageShortForm(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Replace Message Long Form decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteReplaceMessageLongForm ==
    \A message \in CheckedQuoteReplaceMessageLongForm :
        LET read == DecodeQuoteReplaceMessageLongForm(EncodeQuoteReplaceMessageLongForm(message))
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

(* Every Broken Trade Or Order Execution Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBrokenTradeOrOrderExecutionMessage ==
    \A message \in CheckedBrokenTradeOrOrderExecutionMessage :
        LET read == DecodeBrokenTradeOrOrderExecutionMessage(EncodeBrokenTradeOrOrderExecutionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Net Order Imbalance Indicator Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNetOrderImbalanceIndicatorMessage ==
    \A message \in CheckedNetOrderImbalanceIndicatorMessage :
        LET read == DecodeNetOrderImbalanceIndicatorMessage(EncodeNetOrderImbalanceIndicatorMessage(message))
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
