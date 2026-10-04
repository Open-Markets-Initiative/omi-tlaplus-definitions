-------------- MODULE MrxOptions_DepthOfMarket_Itch_v2_1_Udp ---------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Depth Of Market v2.1                                           *)
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
(* Derivative Directory Message: 62 bytes                                  *)
(***************************************************************************)

DerivativeDirectoryMessage ==
    [ trackingNumber      : Sample(2),
      timestamp           : Sample(8),
      instrumentId        : Sample(4),
      securitySymbol      : Sample(8),
      expirationYear      : Sample(1),
      expirationMonth     : Sample(1),
      expirationDay       : Sample(1),
      explicitStrikePrice : Sample(4),
      optionType          : Sample(1),
      underlyingSymbol    : Sample(13),
      closingType         : Sample(1),
      tradable            : Sample(1),
      mpv                 : Sample(1),
      reserved16          : Sample(16) ]

EncodeDerivativeDirectoryMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.instrumentId
        \o message.securitySymbol
        \o message.expirationYear
        \o message.expirationMonth
        \o message.expirationDay
        \o message.explicitStrikePrice
        \o message.optionType
        \o message.underlyingSymbol
        \o message.closingType
        \o message.tradable
        \o message.mpv
        \o message.reserved16

DecodeDerivativeDirectoryMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(instrumentId.rest, 8) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET expirationYear == ReadBytes(securitySymbol.rest, 1) IN IF ~expirationYear.ok THEN Fail ELSE
    LET expirationMonth == ReadBytes(expirationYear.rest, 1) IN IF ~expirationMonth.ok THEN Fail ELSE
    LET expirationDay == ReadBytes(expirationMonth.rest, 1) IN IF ~expirationDay.ok THEN Fail ELSE
    LET explicitStrikePrice == ReadBytes(expirationDay.rest, 4) IN IF ~explicitStrikePrice.ok THEN Fail ELSE
    LET optionType == ReadBytes(explicitStrikePrice.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(optionType.rest, 13) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET closingType == ReadBytes(underlyingSymbol.rest, 1) IN IF ~closingType.ok THEN Fail ELSE
    LET tradable == ReadBytes(closingType.rest, 1) IN IF ~tradable.ok THEN Fail ELSE
    LET mpv == ReadBytes(tradable.rest, 1) IN IF ~mpv.ok THEN Fail ELSE
    LET reserved16 == ReadBytes(mpv.rest, 16) IN IF ~reserved16.ok THEN Fail ELSE
    Ok([ trackingNumber      |-> trackingNumber.value,
         timestamp           |-> timestamp.value,
         instrumentId        |-> instrumentId.value,
         securitySymbol      |-> securitySymbol.value,
         expirationYear      |-> expirationYear.value,
         expirationMonth     |-> expirationMonth.value,
         expirationDay       |-> expirationDay.value,
         explicitStrikePrice |-> explicitStrikePrice.value,
         optionType          |-> optionType.value,
         underlyingSymbol    |-> underlyingSymbol.value,
         closingType         |-> closingType.value,
         tradable            |-> tradable.value,
         mpv                 |-> mpv.value,
         reserved16          |-> reserved16.value ], reserved16.rest)

ZeroDerivativeDirectoryMessage ==
    [ trackingNumber      |-> [i \in 1 .. 2 |-> 0],
      timestamp           |-> [i \in 1 .. 8 |-> 0],
      instrumentId        |-> [i \in 1 .. 4 |-> 0],
      securitySymbol      |-> [i \in 1 .. 8 |-> 0],
      expirationYear      |-> [i \in 1 .. 1 |-> 0],
      expirationMonth     |-> [i \in 1 .. 1 |-> 0],
      expirationDay       |-> [i \in 1 .. 1 |-> 0],
      explicitStrikePrice |-> [i \in 1 .. 4 |-> 0],
      optionType          |-> [i \in 1 .. 1 |-> 0],
      underlyingSymbol    |-> [i \in 1 .. 13 |-> 0],
      closingType         |-> [i \in 1 .. 1 |-> 0],
      tradable            |-> [i \in 1 .. 1 |-> 0],
      mpv                 |-> [i \in 1 .. 1 |-> 0],
      reserved16          |-> [i \in 1 .. 16 |-> 0] ]

(* Derivative Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedDerivativeDirectoryMessage ==
    { ZeroDerivativeDirectoryMessage }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.securitySymbol = one] : one \in Sample(8) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.expirationYear = one] : one \in Sample(1) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.expirationMonth = one] : one \in Sample(1) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.expirationDay = one] : one \in Sample(1) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.explicitStrikePrice = one] : one \in Sample(4) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(13) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.closingType = one] : one \in Sample(1) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.tradable = one] : one \in Sample(1) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.mpv = one] : one \in Sample(1) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.reserved16 = one] : one \in Sample(16) }

(***************************************************************************)
(* Trading Action Message: 15 bytes                                        *)
(***************************************************************************)

TradingActionMessage ==
    [ trackingNumber      : Sample(2),
      timestamp           : Sample(8),
      instrumentId        : Sample(4),
      currentTradingState : Sample(1) ]

EncodeTradingActionMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.instrumentId
        \o message.currentTradingState

DecodeTradingActionMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET currentTradingState == ReadBytes(instrumentId.rest, 1) IN IF ~currentTradingState.ok THEN Fail ELSE
    Ok([ trackingNumber      |-> trackingNumber.value,
         timestamp           |-> timestamp.value,
         instrumentId        |-> instrumentId.value,
         currentTradingState |-> currentTradingState.value ], currentTradingState.rest)

ZeroTradingActionMessage ==
    [ trackingNumber      |-> [i \in 1 .. 2 |-> 0],
      timestamp           |-> [i \in 1 .. 8 |-> 0],
      instrumentId        |-> [i \in 1 .. 4 |-> 0],
      currentTradingState |-> [i \in 1 .. 1 |-> 0] ]

(* Trading Action Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingActionMessage ==
    { ZeroTradingActionMessage }
        \cup { [ZeroTradingActionMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroTradingActionMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradingActionMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroTradingActionMessage EXCEPT !.currentTradingState = one] : one \in Sample(1) }

(***************************************************************************)
(* Add Order Short Form Message: 32 bytes                                  *)
(***************************************************************************)

AddOrderShortFormMessage ==
    [ trackingNumber       : Sample(2),
      timestamp            : Sample(8),
      instrumentId         : Sample(4),
      orderReferenceNumber : Sample(8),
      side                 : Sample(1),
      orderCapacity        : Sample(1),
      priceShort           : Sample(2),
      volumeShort          : Sample(2),
      reserved4            : Sample(4) ]

EncodeAddOrderShortFormMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.instrumentId
        \o message.orderReferenceNumber
        \o message.side
        \o message.orderCapacity
        \o message.priceShort
        \o message.volumeShort
        \o message.reserved4

DecodeAddOrderShortFormMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(instrumentId.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET side == ReadBytes(orderReferenceNumber.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderCapacity == ReadBytes(side.rest, 1) IN IF ~orderCapacity.ok THEN Fail ELSE
    LET priceShort == ReadBytes(orderCapacity.rest, 2) IN IF ~priceShort.ok THEN Fail ELSE
    LET volumeShort == ReadBytes(priceShort.rest, 2) IN IF ~volumeShort.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(volumeShort.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    Ok([ trackingNumber       |-> trackingNumber.value,
         timestamp            |-> timestamp.value,
         instrumentId         |-> instrumentId.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         side                 |-> side.value,
         orderCapacity        |-> orderCapacity.value,
         priceShort           |-> priceShort.value,
         volumeShort          |-> volumeShort.value,
         reserved4            |-> reserved4.value ], reserved4.rest)

ZeroAddOrderShortFormMessage ==
    [ trackingNumber       |-> [i \in 1 .. 2 |-> 0],
      timestamp            |-> [i \in 1 .. 8 |-> 0],
      instrumentId         |-> [i \in 1 .. 4 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      orderCapacity        |-> [i \in 1 .. 1 |-> 0],
      priceShort           |-> [i \in 1 .. 2 |-> 0],
      volumeShort          |-> [i \in 1 .. 2 |-> 0],
      reserved4            |-> [i \in 1 .. 4 |-> 0] ]

(* Add Order Short Form Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderShortFormMessage ==
    { ZeroAddOrderShortFormMessage }
        \cup { [ZeroAddOrderShortFormMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderShortFormMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderShortFormMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderShortFormMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderShortFormMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderShortFormMessage EXCEPT !.orderCapacity = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderShortFormMessage EXCEPT !.priceShort = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderShortFormMessage EXCEPT !.volumeShort = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderShortFormMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Add Order Long Form Message: 36 bytes                                   *)
(***************************************************************************)

AddOrderLongFormMessage ==
    [ trackingNumber       : Sample(2),
      timestamp            : Sample(8),
      instrumentId         : Sample(4),
      orderReferenceNumber : Sample(8),
      side                 : Sample(1),
      orderCapacity        : Sample(1),
      priceLong            : Sample(4),
      volumeLong           : Sample(4),
      reserved4            : Sample(4) ]

EncodeAddOrderLongFormMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.instrumentId
        \o message.orderReferenceNumber
        \o message.side
        \o message.orderCapacity
        \o message.priceLong
        \o message.volumeLong
        \o message.reserved4

DecodeAddOrderLongFormMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(instrumentId.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET side == ReadBytes(orderReferenceNumber.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderCapacity == ReadBytes(side.rest, 1) IN IF ~orderCapacity.ok THEN Fail ELSE
    LET priceLong == ReadBytes(orderCapacity.rest, 4) IN IF ~priceLong.ok THEN Fail ELSE
    LET volumeLong == ReadBytes(priceLong.rest, 4) IN IF ~volumeLong.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(volumeLong.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    Ok([ trackingNumber       |-> trackingNumber.value,
         timestamp            |-> timestamp.value,
         instrumentId         |-> instrumentId.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         side                 |-> side.value,
         orderCapacity        |-> orderCapacity.value,
         priceLong            |-> priceLong.value,
         volumeLong           |-> volumeLong.value,
         reserved4            |-> reserved4.value ], reserved4.rest)

ZeroAddOrderLongFormMessage ==
    [ trackingNumber       |-> [i \in 1 .. 2 |-> 0],
      timestamp            |-> [i \in 1 .. 8 |-> 0],
      instrumentId         |-> [i \in 1 .. 4 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      orderCapacity        |-> [i \in 1 .. 1 |-> 0],
      priceLong            |-> [i \in 1 .. 4 |-> 0],
      volumeLong           |-> [i \in 1 .. 4 |-> 0],
      reserved4            |-> [i \in 1 .. 4 |-> 0] ]

(* Add Order Long Form Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderLongFormMessage ==
    { ZeroAddOrderLongFormMessage }
        \cup { [ZeroAddOrderLongFormMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderLongFormMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderLongFormMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderLongFormMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderLongFormMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderLongFormMessage EXCEPT !.orderCapacity = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderLongFormMessage EXCEPT !.priceLong = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderLongFormMessage EXCEPT !.volumeLong = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderLongFormMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Add Quote Short Form Message: 38 bytes                                  *)
(***************************************************************************)

AddQuoteShortFormMessage ==
    [ trackingNumber     : Sample(2),
      timestamp          : Sample(8),
      instrumentId       : Sample(4),
      bidReferenceNumber : Sample(8),
      askReferenceNumber : Sample(8),
      bidPriceShort      : Sample(2),
      bidSizeShort       : Sample(2),
      askPriceShort      : Sample(2),
      askSizeShort       : Sample(2) ]

EncodeAddQuoteShortFormMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.instrumentId
        \o message.bidReferenceNumber
        \o message.askReferenceNumber
        \o message.bidPriceShort
        \o message.bidSizeShort
        \o message.askPriceShort
        \o message.askSizeShort

DecodeAddQuoteShortFormMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET bidReferenceNumber == ReadBytes(instrumentId.rest, 8) IN IF ~bidReferenceNumber.ok THEN Fail ELSE
    LET askReferenceNumber == ReadBytes(bidReferenceNumber.rest, 8) IN IF ~askReferenceNumber.ok THEN Fail ELSE
    LET bidPriceShort == ReadBytes(askReferenceNumber.rest, 2) IN IF ~bidPriceShort.ok THEN Fail ELSE
    LET bidSizeShort == ReadBytes(bidPriceShort.rest, 2) IN IF ~bidSizeShort.ok THEN Fail ELSE
    LET askPriceShort == ReadBytes(bidSizeShort.rest, 2) IN IF ~askPriceShort.ok THEN Fail ELSE
    LET askSizeShort == ReadBytes(askPriceShort.rest, 2) IN IF ~askSizeShort.ok THEN Fail ELSE
    Ok([ trackingNumber     |-> trackingNumber.value,
         timestamp          |-> timestamp.value,
         instrumentId       |-> instrumentId.value,
         bidReferenceNumber |-> bidReferenceNumber.value,
         askReferenceNumber |-> askReferenceNumber.value,
         bidPriceShort      |-> bidPriceShort.value,
         bidSizeShort       |-> bidSizeShort.value,
         askPriceShort      |-> askPriceShort.value,
         askSizeShort       |-> askSizeShort.value ], askSizeShort.rest)

ZeroAddQuoteShortFormMessage ==
    [ trackingNumber     |-> [i \in 1 .. 2 |-> 0],
      timestamp          |-> [i \in 1 .. 8 |-> 0],
      instrumentId       |-> [i \in 1 .. 4 |-> 0],
      bidReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      askReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      bidPriceShort      |-> [i \in 1 .. 2 |-> 0],
      bidSizeShort       |-> [i \in 1 .. 2 |-> 0],
      askPriceShort      |-> [i \in 1 .. 2 |-> 0],
      askSizeShort       |-> [i \in 1 .. 2 |-> 0] ]

(* Add Quote Short Form Message at zero, then each field in turn at the values it is checked at *)
CheckedAddQuoteShortFormMessage ==
    { ZeroAddQuoteShortFormMessage }
        \cup { [ZeroAddQuoteShortFormMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroAddQuoteShortFormMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAddQuoteShortFormMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroAddQuoteShortFormMessage EXCEPT !.bidReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroAddQuoteShortFormMessage EXCEPT !.askReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroAddQuoteShortFormMessage EXCEPT !.bidPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroAddQuoteShortFormMessage EXCEPT !.bidSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroAddQuoteShortFormMessage EXCEPT !.askPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroAddQuoteShortFormMessage EXCEPT !.askSizeShort = one] : one \in Sample(2) }

(***************************************************************************)
(* Add Quote Long Form Message: 46 bytes                                   *)
(***************************************************************************)

AddQuoteLongFormMessage ==
    [ trackingNumber     : Sample(2),
      timestamp          : Sample(8),
      instrumentId       : Sample(4),
      bidReferenceNumber : Sample(8),
      askReferenceNumber : Sample(8),
      bidPriceLong       : Sample(4),
      bidSizeLong        : Sample(4),
      askPriceLong       : Sample(4),
      askSizeLong        : Sample(4) ]

EncodeAddQuoteLongFormMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.instrumentId
        \o message.bidReferenceNumber
        \o message.askReferenceNumber
        \o message.bidPriceLong
        \o message.bidSizeLong
        \o message.askPriceLong
        \o message.askSizeLong

DecodeAddQuoteLongFormMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET bidReferenceNumber == ReadBytes(instrumentId.rest, 8) IN IF ~bidReferenceNumber.ok THEN Fail ELSE
    LET askReferenceNumber == ReadBytes(bidReferenceNumber.rest, 8) IN IF ~askReferenceNumber.ok THEN Fail ELSE
    LET bidPriceLong == ReadBytes(askReferenceNumber.rest, 4) IN IF ~bidPriceLong.ok THEN Fail ELSE
    LET bidSizeLong == ReadBytes(bidPriceLong.rest, 4) IN IF ~bidSizeLong.ok THEN Fail ELSE
    LET askPriceLong == ReadBytes(bidSizeLong.rest, 4) IN IF ~askPriceLong.ok THEN Fail ELSE
    LET askSizeLong == ReadBytes(askPriceLong.rest, 4) IN IF ~askSizeLong.ok THEN Fail ELSE
    Ok([ trackingNumber     |-> trackingNumber.value,
         timestamp          |-> timestamp.value,
         instrumentId       |-> instrumentId.value,
         bidReferenceNumber |-> bidReferenceNumber.value,
         askReferenceNumber |-> askReferenceNumber.value,
         bidPriceLong       |-> bidPriceLong.value,
         bidSizeLong        |-> bidSizeLong.value,
         askPriceLong       |-> askPriceLong.value,
         askSizeLong        |-> askSizeLong.value ], askSizeLong.rest)

ZeroAddQuoteLongFormMessage ==
    [ trackingNumber     |-> [i \in 1 .. 2 |-> 0],
      timestamp          |-> [i \in 1 .. 8 |-> 0],
      instrumentId       |-> [i \in 1 .. 4 |-> 0],
      bidReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      askReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      bidPriceLong       |-> [i \in 1 .. 4 |-> 0],
      bidSizeLong        |-> [i \in 1 .. 4 |-> 0],
      askPriceLong       |-> [i \in 1 .. 4 |-> 0],
      askSizeLong        |-> [i \in 1 .. 4 |-> 0] ]

(* Add Quote Long Form Message at zero, then each field in turn at the values it is checked at *)
CheckedAddQuoteLongFormMessage ==
    { ZeroAddQuoteLongFormMessage }
        \cup { [ZeroAddQuoteLongFormMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroAddQuoteLongFormMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAddQuoteLongFormMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroAddQuoteLongFormMessage EXCEPT !.bidReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroAddQuoteLongFormMessage EXCEPT !.askReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroAddQuoteLongFormMessage EXCEPT !.bidPriceLong = one] : one \in Sample(4) }
        \cup { [ZeroAddQuoteLongFormMessage EXCEPT !.bidSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroAddQuoteLongFormMessage EXCEPT !.askPriceLong = one] : one \in Sample(4) }
        \cup { [ZeroAddQuoteLongFormMessage EXCEPT !.askSizeLong = one] : one \in Sample(4) }

(***************************************************************************)
(* Single Side Executed Message: 43 bytes                                  *)
(***************************************************************************)

SingleSideExecutedMessage ==
    [ trackingNumber       : Sample(2),
      timestamp            : Sample(8),
      instrumentId         : Sample(4),
      strategyId           : Sample(4),
      orderReferenceNumber : Sample(8),
      executedVolume       : Sample(4),
      tradeCondition       : Sample(1),
      auctionId            : Sample(4),
      crossNumber          : Sample(4),
      matchNumber          : Sample(4) ]

EncodeSingleSideExecutedMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.instrumentId
        \o message.strategyId
        \o message.orderReferenceNumber
        \o message.executedVolume
        \o message.tradeCondition
        \o message.auctionId
        \o message.crossNumber
        \o message.matchNumber

DecodeSingleSideExecutedMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET strategyId == ReadBytes(instrumentId.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(strategyId.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET executedVolume == ReadBytes(orderReferenceNumber.rest, 4) IN IF ~executedVolume.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(executedVolume.rest, 1) IN IF ~tradeCondition.ok THEN Fail ELSE
    LET auctionId == ReadBytes(tradeCondition.rest, 4) IN IF ~auctionId.ok THEN Fail ELSE
    LET crossNumber == ReadBytes(auctionId.rest, 4) IN IF ~crossNumber.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(crossNumber.rest, 4) IN IF ~matchNumber.ok THEN Fail ELSE
    Ok([ trackingNumber       |-> trackingNumber.value,
         timestamp            |-> timestamp.value,
         instrumentId         |-> instrumentId.value,
         strategyId           |-> strategyId.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         executedVolume       |-> executedVolume.value,
         tradeCondition       |-> tradeCondition.value,
         auctionId            |-> auctionId.value,
         crossNumber          |-> crossNumber.value,
         matchNumber          |-> matchNumber.value ], matchNumber.rest)

ZeroSingleSideExecutedMessage ==
    [ trackingNumber       |-> [i \in 1 .. 2 |-> 0],
      timestamp            |-> [i \in 1 .. 8 |-> 0],
      instrumentId         |-> [i \in 1 .. 4 |-> 0],
      strategyId           |-> [i \in 1 .. 4 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      executedVolume       |-> [i \in 1 .. 4 |-> 0],
      tradeCondition       |-> [i \in 1 .. 1 |-> 0],
      auctionId            |-> [i \in 1 .. 4 |-> 0],
      crossNumber          |-> [i \in 1 .. 4 |-> 0],
      matchNumber          |-> [i \in 1 .. 4 |-> 0] ]

(* Single Side Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleSideExecutedMessage ==
    { ZeroSingleSideExecutedMessage }
        \cup { [ZeroSingleSideExecutedMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroSingleSideExecutedMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSingleSideExecutedMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideExecutedMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideExecutedMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSingleSideExecutedMessage EXCEPT !.executedVolume = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideExecutedMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }
        \cup { [ZeroSingleSideExecutedMessage EXCEPT !.auctionId = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideExecutedMessage EXCEPT !.crossNumber = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideExecutedMessage EXCEPT !.matchNumber = one] : one \in Sample(4) }

(***************************************************************************)
(* Single Side Executed With Price Message: 48 bytes                       *)
(***************************************************************************)

SingleSideExecutedWithPriceMessage ==
    [ trackingNumber       : Sample(2),
      timestamp            : Sample(8),
      instrumentId         : Sample(4),
      strategyId           : Sample(4),
      orderReferenceNumber : Sample(8),
      crossNumber          : Sample(4),
      matchNumber          : Sample(4),
      printable            : Sample(1),
      priceLong            : Sample(4),
      volumeLong           : Sample(4),
      tradeCondition       : Sample(1),
      auctionId            : Sample(4) ]

EncodeSingleSideExecutedWithPriceMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.instrumentId
        \o message.strategyId
        \o message.orderReferenceNumber
        \o message.crossNumber
        \o message.matchNumber
        \o message.printable
        \o message.priceLong
        \o message.volumeLong
        \o message.tradeCondition
        \o message.auctionId

DecodeSingleSideExecutedWithPriceMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET strategyId == ReadBytes(instrumentId.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(strategyId.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET crossNumber == ReadBytes(orderReferenceNumber.rest, 4) IN IF ~crossNumber.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(crossNumber.rest, 4) IN IF ~matchNumber.ok THEN Fail ELSE
    LET printable == ReadBytes(matchNumber.rest, 1) IN IF ~printable.ok THEN Fail ELSE
    LET priceLong == ReadBytes(printable.rest, 4) IN IF ~priceLong.ok THEN Fail ELSE
    LET volumeLong == ReadBytes(priceLong.rest, 4) IN IF ~volumeLong.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(volumeLong.rest, 1) IN IF ~tradeCondition.ok THEN Fail ELSE
    LET auctionId == ReadBytes(tradeCondition.rest, 4) IN IF ~auctionId.ok THEN Fail ELSE
    Ok([ trackingNumber       |-> trackingNumber.value,
         timestamp            |-> timestamp.value,
         instrumentId         |-> instrumentId.value,
         strategyId           |-> strategyId.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         crossNumber          |-> crossNumber.value,
         matchNumber          |-> matchNumber.value,
         printable            |-> printable.value,
         priceLong            |-> priceLong.value,
         volumeLong           |-> volumeLong.value,
         tradeCondition       |-> tradeCondition.value,
         auctionId            |-> auctionId.value ], auctionId.rest)

ZeroSingleSideExecutedWithPriceMessage ==
    [ trackingNumber       |-> [i \in 1 .. 2 |-> 0],
      timestamp            |-> [i \in 1 .. 8 |-> 0],
      instrumentId         |-> [i \in 1 .. 4 |-> 0],
      strategyId           |-> [i \in 1 .. 4 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      crossNumber          |-> [i \in 1 .. 4 |-> 0],
      matchNumber          |-> [i \in 1 .. 4 |-> 0],
      printable            |-> [i \in 1 .. 1 |-> 0],
      priceLong            |-> [i \in 1 .. 4 |-> 0],
      volumeLong           |-> [i \in 1 .. 4 |-> 0],
      tradeCondition       |-> [i \in 1 .. 1 |-> 0],
      auctionId            |-> [i \in 1 .. 4 |-> 0] ]

(* Single Side Executed With Price Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleSideExecutedWithPriceMessage ==
    { ZeroSingleSideExecutedWithPriceMessage }
        \cup { [ZeroSingleSideExecutedWithPriceMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroSingleSideExecutedWithPriceMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSingleSideExecutedWithPriceMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideExecutedWithPriceMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideExecutedWithPriceMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSingleSideExecutedWithPriceMessage EXCEPT !.crossNumber = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideExecutedWithPriceMessage EXCEPT !.matchNumber = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideExecutedWithPriceMessage EXCEPT !.printable = one] : one \in Sample(1) }
        \cup { [ZeroSingleSideExecutedWithPriceMessage EXCEPT !.priceLong = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideExecutedWithPriceMessage EXCEPT !.volumeLong = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideExecutedWithPriceMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }
        \cup { [ZeroSingleSideExecutedWithPriceMessage EXCEPT !.auctionId = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Cancel Message: 26 bytes                                          *)
(***************************************************************************)

OrderCancelMessage ==
    [ trackingNumber       : Sample(2),
      timestamp            : Sample(8),
      instrumentId         : Sample(4),
      orderReferenceNumber : Sample(8),
      cancelledVolume      : Sample(4) ]

EncodeOrderCancelMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.instrumentId
        \o message.orderReferenceNumber
        \o message.cancelledVolume

DecodeOrderCancelMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(instrumentId.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET cancelledVolume == ReadBytes(orderReferenceNumber.rest, 4) IN IF ~cancelledVolume.ok THEN Fail ELSE
    Ok([ trackingNumber       |-> trackingNumber.value,
         timestamp            |-> timestamp.value,
         instrumentId         |-> instrumentId.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         cancelledVolume      |-> cancelledVolume.value ], cancelledVolume.rest)

ZeroOrderCancelMessage ==
    [ trackingNumber       |-> [i \in 1 .. 2 |-> 0],
      timestamp            |-> [i \in 1 .. 8 |-> 0],
      instrumentId         |-> [i \in 1 .. 4 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      cancelledVolume      |-> [i \in 1 .. 4 |-> 0] ]

(* Order Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelMessage ==
    { ZeroOrderCancelMessage }
        \cup { [ZeroOrderCancelMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.cancelledVolume = one] : one \in Sample(4) }

(***************************************************************************)
(* Single Side Replace Short Form Message: 34 bytes                        *)
(***************************************************************************)

SingleSideReplaceShortFormMessage ==
    [ trackingNumber       : Sample(2),
      timestamp            : Sample(8),
      instrumentId         : Sample(4),
      orderReferenceNumber : Sample(8),
      newReferenceNumber   : Sample(8),
      priceShort           : Sample(2),
      volumeShort          : Sample(2) ]

EncodeSingleSideReplaceShortFormMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.instrumentId
        \o message.orderReferenceNumber
        \o message.newReferenceNumber
        \o message.priceShort
        \o message.volumeShort

DecodeSingleSideReplaceShortFormMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(instrumentId.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET newReferenceNumber == ReadBytes(orderReferenceNumber.rest, 8) IN IF ~newReferenceNumber.ok THEN Fail ELSE
    LET priceShort == ReadBytes(newReferenceNumber.rest, 2) IN IF ~priceShort.ok THEN Fail ELSE
    LET volumeShort == ReadBytes(priceShort.rest, 2) IN IF ~volumeShort.ok THEN Fail ELSE
    Ok([ trackingNumber       |-> trackingNumber.value,
         timestamp            |-> timestamp.value,
         instrumentId         |-> instrumentId.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         newReferenceNumber   |-> newReferenceNumber.value,
         priceShort           |-> priceShort.value,
         volumeShort          |-> volumeShort.value ], volumeShort.rest)

ZeroSingleSideReplaceShortFormMessage ==
    [ trackingNumber       |-> [i \in 1 .. 2 |-> 0],
      timestamp            |-> [i \in 1 .. 8 |-> 0],
      instrumentId         |-> [i \in 1 .. 4 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      newReferenceNumber   |-> [i \in 1 .. 8 |-> 0],
      priceShort           |-> [i \in 1 .. 2 |-> 0],
      volumeShort          |-> [i \in 1 .. 2 |-> 0] ]

(* Single Side Replace Short Form Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleSideReplaceShortFormMessage ==
    { ZeroSingleSideReplaceShortFormMessage }
        \cup { [ZeroSingleSideReplaceShortFormMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroSingleSideReplaceShortFormMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSingleSideReplaceShortFormMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideReplaceShortFormMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSingleSideReplaceShortFormMessage EXCEPT !.newReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSingleSideReplaceShortFormMessage EXCEPT !.priceShort = one] : one \in Sample(2) }
        \cup { [ZeroSingleSideReplaceShortFormMessage EXCEPT !.volumeShort = one] : one \in Sample(2) }

(***************************************************************************)
(* Single Side Replace Long Form Message: 38 bytes                         *)
(***************************************************************************)

SingleSideReplaceLongFormMessage ==
    [ trackingNumber       : Sample(2),
      timestamp            : Sample(8),
      instrumentId         : Sample(4),
      orderReferenceNumber : Sample(8),
      newReferenceNumber   : Sample(8),
      priceLong            : Sample(4),
      volumeLong           : Sample(4) ]

EncodeSingleSideReplaceLongFormMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.instrumentId
        \o message.orderReferenceNumber
        \o message.newReferenceNumber
        \o message.priceLong
        \o message.volumeLong

DecodeSingleSideReplaceLongFormMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(instrumentId.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET newReferenceNumber == ReadBytes(orderReferenceNumber.rest, 8) IN IF ~newReferenceNumber.ok THEN Fail ELSE
    LET priceLong == ReadBytes(newReferenceNumber.rest, 4) IN IF ~priceLong.ok THEN Fail ELSE
    LET volumeLong == ReadBytes(priceLong.rest, 4) IN IF ~volumeLong.ok THEN Fail ELSE
    Ok([ trackingNumber       |-> trackingNumber.value,
         timestamp            |-> timestamp.value,
         instrumentId         |-> instrumentId.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         newReferenceNumber   |-> newReferenceNumber.value,
         priceLong            |-> priceLong.value,
         volumeLong           |-> volumeLong.value ], volumeLong.rest)

ZeroSingleSideReplaceLongFormMessage ==
    [ trackingNumber       |-> [i \in 1 .. 2 |-> 0],
      timestamp            |-> [i \in 1 .. 8 |-> 0],
      instrumentId         |-> [i \in 1 .. 4 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      newReferenceNumber   |-> [i \in 1 .. 8 |-> 0],
      priceLong            |-> [i \in 1 .. 4 |-> 0],
      volumeLong           |-> [i \in 1 .. 4 |-> 0] ]

(* Single Side Replace Long Form Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleSideReplaceLongFormMessage ==
    { ZeroSingleSideReplaceLongFormMessage }
        \cup { [ZeroSingleSideReplaceLongFormMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroSingleSideReplaceLongFormMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSingleSideReplaceLongFormMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideReplaceLongFormMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSingleSideReplaceLongFormMessage EXCEPT !.newReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSingleSideReplaceLongFormMessage EXCEPT !.priceLong = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideReplaceLongFormMessage EXCEPT !.volumeLong = one] : one \in Sample(4) }

(***************************************************************************)
(* Single Side Delete Message: 22 bytes                                    *)
(***************************************************************************)

SingleSideDeleteMessage ==
    [ trackingNumber       : Sample(2),
      timestamp            : Sample(8),
      instrumentId         : Sample(4),
      orderReferenceNumber : Sample(8) ]

EncodeSingleSideDeleteMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.instrumentId
        \o message.orderReferenceNumber

DecodeSingleSideDeleteMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(instrumentId.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    Ok([ trackingNumber       |-> trackingNumber.value,
         timestamp            |-> timestamp.value,
         instrumentId         |-> instrumentId.value,
         orderReferenceNumber |-> orderReferenceNumber.value ], orderReferenceNumber.rest)

ZeroSingleSideDeleteMessage ==
    [ trackingNumber       |-> [i \in 1 .. 2 |-> 0],
      timestamp            |-> [i \in 1 .. 8 |-> 0],
      instrumentId         |-> [i \in 1 .. 4 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Single Side Delete Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleSideDeleteMessage ==
    { ZeroSingleSideDeleteMessage }
        \cup { [ZeroSingleSideDeleteMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroSingleSideDeleteMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSingleSideDeleteMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideDeleteMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Single Side Update Message: 31 bytes                                    *)
(***************************************************************************)

SingleSideUpdateMessage ==
    [ trackingNumber       : Sample(2),
      timestamp            : Sample(8),
      instrumentId         : Sample(4),
      orderReferenceNumber : Sample(8),
      changeReason         : Sample(1),
      priceLong            : Sample(4),
      volumeLong           : Sample(4) ]

EncodeSingleSideUpdateMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.instrumentId
        \o message.orderReferenceNumber
        \o message.changeReason
        \o message.priceLong
        \o message.volumeLong

DecodeSingleSideUpdateMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(instrumentId.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET changeReason == ReadBytes(orderReferenceNumber.rest, 1) IN IF ~changeReason.ok THEN Fail ELSE
    LET priceLong == ReadBytes(changeReason.rest, 4) IN IF ~priceLong.ok THEN Fail ELSE
    LET volumeLong == ReadBytes(priceLong.rest, 4) IN IF ~volumeLong.ok THEN Fail ELSE
    Ok([ trackingNumber       |-> trackingNumber.value,
         timestamp            |-> timestamp.value,
         instrumentId         |-> instrumentId.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         changeReason         |-> changeReason.value,
         priceLong            |-> priceLong.value,
         volumeLong           |-> volumeLong.value ], volumeLong.rest)

ZeroSingleSideUpdateMessage ==
    [ trackingNumber       |-> [i \in 1 .. 2 |-> 0],
      timestamp            |-> [i \in 1 .. 8 |-> 0],
      instrumentId         |-> [i \in 1 .. 4 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      changeReason         |-> [i \in 1 .. 1 |-> 0],
      priceLong            |-> [i \in 1 .. 4 |-> 0],
      volumeLong           |-> [i \in 1 .. 4 |-> 0] ]

(* Single Side Update Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleSideUpdateMessage ==
    { ZeroSingleSideUpdateMessage }
        \cup { [ZeroSingleSideUpdateMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroSingleSideUpdateMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSingleSideUpdateMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideUpdateMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSingleSideUpdateMessage EXCEPT !.changeReason = one] : one \in Sample(1) }
        \cup { [ZeroSingleSideUpdateMessage EXCEPT !.priceLong = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideUpdateMessage EXCEPT !.volumeLong = one] : one \in Sample(4) }

(***************************************************************************)
(* Quote Replace Short Form Message: 54 bytes                              *)
(***************************************************************************)

QuoteReplaceShortFormMessage ==
    [ trackingNumber             : Sample(2),
      timestamp                  : Sample(8),
      instrumentId               : Sample(4),
      originalBidReferenceNumber : Sample(8),
      bidReferenceNumber         : Sample(8),
      originalAskReferenceNumber : Sample(8),
      askReferenceNumber         : Sample(8),
      bidPriceShort              : Sample(2),
      bidSizeShort               : Sample(2),
      askPriceShort              : Sample(2),
      askSizeShort               : Sample(2) ]

EncodeQuoteReplaceShortFormMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.instrumentId
        \o message.originalBidReferenceNumber
        \o message.bidReferenceNumber
        \o message.originalAskReferenceNumber
        \o message.askReferenceNumber
        \o message.bidPriceShort
        \o message.bidSizeShort
        \o message.askPriceShort
        \o message.askSizeShort

DecodeQuoteReplaceShortFormMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET originalBidReferenceNumber == ReadBytes(instrumentId.rest, 8) IN IF ~originalBidReferenceNumber.ok THEN Fail ELSE
    LET bidReferenceNumber == ReadBytes(originalBidReferenceNumber.rest, 8) IN IF ~bidReferenceNumber.ok THEN Fail ELSE
    LET originalAskReferenceNumber == ReadBytes(bidReferenceNumber.rest, 8) IN IF ~originalAskReferenceNumber.ok THEN Fail ELSE
    LET askReferenceNumber == ReadBytes(originalAskReferenceNumber.rest, 8) IN IF ~askReferenceNumber.ok THEN Fail ELSE
    LET bidPriceShort == ReadBytes(askReferenceNumber.rest, 2) IN IF ~bidPriceShort.ok THEN Fail ELSE
    LET bidSizeShort == ReadBytes(bidPriceShort.rest, 2) IN IF ~bidSizeShort.ok THEN Fail ELSE
    LET askPriceShort == ReadBytes(bidSizeShort.rest, 2) IN IF ~askPriceShort.ok THEN Fail ELSE
    LET askSizeShort == ReadBytes(askPriceShort.rest, 2) IN IF ~askSizeShort.ok THEN Fail ELSE
    Ok([ trackingNumber             |-> trackingNumber.value,
         timestamp                  |-> timestamp.value,
         instrumentId               |-> instrumentId.value,
         originalBidReferenceNumber |-> originalBidReferenceNumber.value,
         bidReferenceNumber         |-> bidReferenceNumber.value,
         originalAskReferenceNumber |-> originalAskReferenceNumber.value,
         askReferenceNumber         |-> askReferenceNumber.value,
         bidPriceShort              |-> bidPriceShort.value,
         bidSizeShort               |-> bidSizeShort.value,
         askPriceShort              |-> askPriceShort.value,
         askSizeShort               |-> askSizeShort.value ], askSizeShort.rest)

ZeroQuoteReplaceShortFormMessage ==
    [ trackingNumber             |-> [i \in 1 .. 2 |-> 0],
      timestamp                  |-> [i \in 1 .. 8 |-> 0],
      instrumentId               |-> [i \in 1 .. 4 |-> 0],
      originalBidReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      bidReferenceNumber         |-> [i \in 1 .. 8 |-> 0],
      originalAskReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      askReferenceNumber         |-> [i \in 1 .. 8 |-> 0],
      bidPriceShort              |-> [i \in 1 .. 2 |-> 0],
      bidSizeShort               |-> [i \in 1 .. 2 |-> 0],
      askPriceShort              |-> [i \in 1 .. 2 |-> 0],
      askSizeShort               |-> [i \in 1 .. 2 |-> 0] ]

(* Quote Replace Short Form Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteReplaceShortFormMessage ==
    { ZeroQuoteReplaceShortFormMessage }
        \cup { [ZeroQuoteReplaceShortFormMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroQuoteReplaceShortFormMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroQuoteReplaceShortFormMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteReplaceShortFormMessage EXCEPT !.originalBidReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroQuoteReplaceShortFormMessage EXCEPT !.bidReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroQuoteReplaceShortFormMessage EXCEPT !.originalAskReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroQuoteReplaceShortFormMessage EXCEPT !.askReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroQuoteReplaceShortFormMessage EXCEPT !.bidPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroQuoteReplaceShortFormMessage EXCEPT !.bidSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroQuoteReplaceShortFormMessage EXCEPT !.askPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroQuoteReplaceShortFormMessage EXCEPT !.askSizeShort = one] : one \in Sample(2) }

(***************************************************************************)
(* Quote Replace Long Form Message: 62 bytes                               *)
(***************************************************************************)

QuoteReplaceLongFormMessage ==
    [ trackingNumber             : Sample(2),
      timestamp                  : Sample(8),
      instrumentId               : Sample(4),
      originalBidReferenceNumber : Sample(8),
      bidReferenceNumber         : Sample(8),
      originalAskReferenceNumber : Sample(8),
      askReferenceNumber         : Sample(8),
      bidPriceLong               : Sample(4),
      bidSizeLong                : Sample(4),
      askPriceLong               : Sample(4),
      askSizeLong                : Sample(4) ]

EncodeQuoteReplaceLongFormMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.instrumentId
        \o message.originalBidReferenceNumber
        \o message.bidReferenceNumber
        \o message.originalAskReferenceNumber
        \o message.askReferenceNumber
        \o message.bidPriceLong
        \o message.bidSizeLong
        \o message.askPriceLong
        \o message.askSizeLong

DecodeQuoteReplaceLongFormMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET originalBidReferenceNumber == ReadBytes(instrumentId.rest, 8) IN IF ~originalBidReferenceNumber.ok THEN Fail ELSE
    LET bidReferenceNumber == ReadBytes(originalBidReferenceNumber.rest, 8) IN IF ~bidReferenceNumber.ok THEN Fail ELSE
    LET originalAskReferenceNumber == ReadBytes(bidReferenceNumber.rest, 8) IN IF ~originalAskReferenceNumber.ok THEN Fail ELSE
    LET askReferenceNumber == ReadBytes(originalAskReferenceNumber.rest, 8) IN IF ~askReferenceNumber.ok THEN Fail ELSE
    LET bidPriceLong == ReadBytes(askReferenceNumber.rest, 4) IN IF ~bidPriceLong.ok THEN Fail ELSE
    LET bidSizeLong == ReadBytes(bidPriceLong.rest, 4) IN IF ~bidSizeLong.ok THEN Fail ELSE
    LET askPriceLong == ReadBytes(bidSizeLong.rest, 4) IN IF ~askPriceLong.ok THEN Fail ELSE
    LET askSizeLong == ReadBytes(askPriceLong.rest, 4) IN IF ~askSizeLong.ok THEN Fail ELSE
    Ok([ trackingNumber             |-> trackingNumber.value,
         timestamp                  |-> timestamp.value,
         instrumentId               |-> instrumentId.value,
         originalBidReferenceNumber |-> originalBidReferenceNumber.value,
         bidReferenceNumber         |-> bidReferenceNumber.value,
         originalAskReferenceNumber |-> originalAskReferenceNumber.value,
         askReferenceNumber         |-> askReferenceNumber.value,
         bidPriceLong               |-> bidPriceLong.value,
         bidSizeLong                |-> bidSizeLong.value,
         askPriceLong               |-> askPriceLong.value,
         askSizeLong                |-> askSizeLong.value ], askSizeLong.rest)

ZeroQuoteReplaceLongFormMessage ==
    [ trackingNumber             |-> [i \in 1 .. 2 |-> 0],
      timestamp                  |-> [i \in 1 .. 8 |-> 0],
      instrumentId               |-> [i \in 1 .. 4 |-> 0],
      originalBidReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      bidReferenceNumber         |-> [i \in 1 .. 8 |-> 0],
      originalAskReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      askReferenceNumber         |-> [i \in 1 .. 8 |-> 0],
      bidPriceLong               |-> [i \in 1 .. 4 |-> 0],
      bidSizeLong                |-> [i \in 1 .. 4 |-> 0],
      askPriceLong               |-> [i \in 1 .. 4 |-> 0],
      askSizeLong                |-> [i \in 1 .. 4 |-> 0] ]

(* Quote Replace Long Form Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteReplaceLongFormMessage ==
    { ZeroQuoteReplaceLongFormMessage }
        \cup { [ZeroQuoteReplaceLongFormMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroQuoteReplaceLongFormMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroQuoteReplaceLongFormMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteReplaceLongFormMessage EXCEPT !.originalBidReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroQuoteReplaceLongFormMessage EXCEPT !.bidReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroQuoteReplaceLongFormMessage EXCEPT !.originalAskReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroQuoteReplaceLongFormMessage EXCEPT !.askReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroQuoteReplaceLongFormMessage EXCEPT !.bidPriceLong = one] : one \in Sample(4) }
        \cup { [ZeroQuoteReplaceLongFormMessage EXCEPT !.bidSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroQuoteReplaceLongFormMessage EXCEPT !.askPriceLong = one] : one \in Sample(4) }
        \cup { [ZeroQuoteReplaceLongFormMessage EXCEPT !.askSizeLong = one] : one \in Sample(4) }

(***************************************************************************)
(* Quote Delete Message: 30 bytes                                          *)
(***************************************************************************)

QuoteDeleteMessage ==
    [ trackingNumber     : Sample(2),
      timestamp          : Sample(8),
      instrumentId       : Sample(4),
      bidReferenceNumber : Sample(8),
      askReferenceNumber : Sample(8) ]

EncodeQuoteDeleteMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.instrumentId
        \o message.bidReferenceNumber
        \o message.askReferenceNumber

DecodeQuoteDeleteMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET bidReferenceNumber == ReadBytes(instrumentId.rest, 8) IN IF ~bidReferenceNumber.ok THEN Fail ELSE
    LET askReferenceNumber == ReadBytes(bidReferenceNumber.rest, 8) IN IF ~askReferenceNumber.ok THEN Fail ELSE
    Ok([ trackingNumber     |-> trackingNumber.value,
         timestamp          |-> timestamp.value,
         instrumentId       |-> instrumentId.value,
         bidReferenceNumber |-> bidReferenceNumber.value,
         askReferenceNumber |-> askReferenceNumber.value ], askReferenceNumber.rest)

ZeroQuoteDeleteMessage ==
    [ trackingNumber     |-> [i \in 1 .. 2 |-> 0],
      timestamp          |-> [i \in 1 .. 8 |-> 0],
      instrumentId       |-> [i \in 1 .. 4 |-> 0],
      bidReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      askReferenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Quote Delete Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteDeleteMessage ==
    { ZeroQuoteDeleteMessage }
        \cup { [ZeroQuoteDeleteMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroQuoteDeleteMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroQuoteDeleteMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteDeleteMessage EXCEPT !.bidReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroQuoteDeleteMessage EXCEPT !.askReferenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Message: 58 bytes                                                 *)
(***************************************************************************)

TradeMessage ==
    [ trackingNumber : Sample(2),
      timestamp      : Sample(8),
      instrumentId   : Sample(4),
      crossNumber    : Sample(4),
      matchNumber    : Sample(4),
      strategyId     : Sample(4),
      crossType      : Sample(1),
      priceLong      : Sample(4),
      volumeLong     : Sample(4),
      tradeCondition : Sample(1),
      auctionId      : Sample(4),
      printable      : Sample(1),
      tradeType      : Sample(1),
      reserved16     : Sample(16) ]

EncodeTradeMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.instrumentId
        \o message.crossNumber
        \o message.matchNumber
        \o message.strategyId
        \o message.crossType
        \o message.priceLong
        \o message.volumeLong
        \o message.tradeCondition
        \o message.auctionId
        \o message.printable
        \o message.tradeType
        \o message.reserved16

DecodeTradeMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET crossNumber == ReadBytes(instrumentId.rest, 4) IN IF ~crossNumber.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(crossNumber.rest, 4) IN IF ~matchNumber.ok THEN Fail ELSE
    LET strategyId == ReadBytes(matchNumber.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET crossType == ReadBytes(strategyId.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET priceLong == ReadBytes(crossType.rest, 4) IN IF ~priceLong.ok THEN Fail ELSE
    LET volumeLong == ReadBytes(priceLong.rest, 4) IN IF ~volumeLong.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(volumeLong.rest, 1) IN IF ~tradeCondition.ok THEN Fail ELSE
    LET auctionId == ReadBytes(tradeCondition.rest, 4) IN IF ~auctionId.ok THEN Fail ELSE
    LET printable == ReadBytes(auctionId.rest, 1) IN IF ~printable.ok THEN Fail ELSE
    LET tradeType == ReadBytes(printable.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET reserved16 == ReadBytes(tradeType.rest, 16) IN IF ~reserved16.ok THEN Fail ELSE
    Ok([ trackingNumber |-> trackingNumber.value,
         timestamp      |-> timestamp.value,
         instrumentId   |-> instrumentId.value,
         crossNumber    |-> crossNumber.value,
         matchNumber    |-> matchNumber.value,
         strategyId     |-> strategyId.value,
         crossType      |-> crossType.value,
         priceLong      |-> priceLong.value,
         volumeLong     |-> volumeLong.value,
         tradeCondition |-> tradeCondition.value,
         auctionId      |-> auctionId.value,
         printable      |-> printable.value,
         tradeType      |-> tradeType.value,
         reserved16     |-> reserved16.value ], reserved16.rest)

ZeroTradeMessage ==
    [ trackingNumber |-> [i \in 1 .. 2 |-> 0],
      timestamp      |-> [i \in 1 .. 8 |-> 0],
      instrumentId   |-> [i \in 1 .. 4 |-> 0],
      crossNumber    |-> [i \in 1 .. 4 |-> 0],
      matchNumber    |-> [i \in 1 .. 4 |-> 0],
      strategyId     |-> [i \in 1 .. 4 |-> 0],
      crossType      |-> [i \in 1 .. 1 |-> 0],
      priceLong      |-> [i \in 1 .. 4 |-> 0],
      volumeLong     |-> [i \in 1 .. 4 |-> 0],
      tradeCondition |-> [i \in 1 .. 1 |-> 0],
      auctionId      |-> [i \in 1 .. 4 |-> 0],
      printable      |-> [i \in 1 .. 1 |-> 0],
      tradeType      |-> [i \in 1 .. 1 |-> 0],
      reserved16     |-> [i \in 1 .. 16 |-> 0] ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroTradeMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.crossNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.matchNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.priceLong = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.volumeLong = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.auctionId = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.printable = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.reserved16 = one] : one \in Sample(16) }

(***************************************************************************)
(* Net Order Imbalance Message: 33 bytes                                   *)
(***************************************************************************)

NetOrderImbalanceMessage ==
    [ trackingNumber         : Sample(2),
      timestamp              : Sample(8),
      instrumentId           : Sample(4),
      auctionId              : Sample(4),
      auctionType            : Sample(1),
      pairedQuantity         : Sample(4),
      sideImbalanceDirection : Sample(1),
      priceImbalancePrice    : Sample(4),
      imbalanceVolume        : Sample(4),
      orderCapacity          : Sample(1) ]

EncodeNetOrderImbalanceMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.instrumentId
        \o message.auctionId
        \o message.auctionType
        \o message.pairedQuantity
        \o message.sideImbalanceDirection
        \o message.priceImbalancePrice
        \o message.imbalanceVolume
        \o message.orderCapacity

DecodeNetOrderImbalanceMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET auctionId == ReadBytes(instrumentId.rest, 4) IN IF ~auctionId.ok THEN Fail ELSE
    LET auctionType == ReadBytes(auctionId.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET pairedQuantity == ReadBytes(auctionType.rest, 4) IN IF ~pairedQuantity.ok THEN Fail ELSE
    LET sideImbalanceDirection == ReadBytes(pairedQuantity.rest, 1) IN IF ~sideImbalanceDirection.ok THEN Fail ELSE
    LET priceImbalancePrice == ReadBytes(sideImbalanceDirection.rest, 4) IN IF ~priceImbalancePrice.ok THEN Fail ELSE
    LET imbalanceVolume == ReadBytes(priceImbalancePrice.rest, 4) IN IF ~imbalanceVolume.ok THEN Fail ELSE
    LET orderCapacity == ReadBytes(imbalanceVolume.rest, 1) IN IF ~orderCapacity.ok THEN Fail ELSE
    Ok([ trackingNumber         |-> trackingNumber.value,
         timestamp              |-> timestamp.value,
         instrumentId           |-> instrumentId.value,
         auctionId              |-> auctionId.value,
         auctionType            |-> auctionType.value,
         pairedQuantity         |-> pairedQuantity.value,
         sideImbalanceDirection |-> sideImbalanceDirection.value,
         priceImbalancePrice    |-> priceImbalancePrice.value,
         imbalanceVolume        |-> imbalanceVolume.value,
         orderCapacity          |-> orderCapacity.value ], orderCapacity.rest)

ZeroNetOrderImbalanceMessage ==
    [ trackingNumber         |-> [i \in 1 .. 2 |-> 0],
      timestamp              |-> [i \in 1 .. 8 |-> 0],
      instrumentId           |-> [i \in 1 .. 4 |-> 0],
      auctionId              |-> [i \in 1 .. 4 |-> 0],
      auctionType            |-> [i \in 1 .. 1 |-> 0],
      pairedQuantity         |-> [i \in 1 .. 4 |-> 0],
      sideImbalanceDirection |-> [i \in 1 .. 1 |-> 0],
      priceImbalancePrice    |-> [i \in 1 .. 4 |-> 0],
      imbalanceVolume        |-> [i \in 1 .. 4 |-> 0],
      orderCapacity          |-> [i \in 1 .. 1 |-> 0] ]

(* Net Order Imbalance Message at zero, then each field in turn at the values it is checked at *)
CheckedNetOrderImbalanceMessage ==
    { ZeroNetOrderImbalanceMessage }
        \cup { [ZeroNetOrderImbalanceMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroNetOrderImbalanceMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroNetOrderImbalanceMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroNetOrderImbalanceMessage EXCEPT !.auctionId = one] : one \in Sample(4) }
        \cup { [ZeroNetOrderImbalanceMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroNetOrderImbalanceMessage EXCEPT !.pairedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroNetOrderImbalanceMessage EXCEPT !.sideImbalanceDirection = one] : one \in Sample(1) }
        \cup { [ZeroNetOrderImbalanceMessage EXCEPT !.priceImbalancePrice = one] : one \in Sample(4) }
        \cup { [ZeroNetOrderImbalanceMessage EXCEPT !.imbalanceVolume = one] : one \in Sample(4) }
        \cup { [ZeroNetOrderImbalanceMessage EXCEPT !.orderCapacity = one] : one \in Sample(1) }

(***************************************************************************)
(* Udp Payload, selected by Message Type                                   *)
(***************************************************************************)

SystemEventMessageCode == 83  \* "S"
DerivativeDirectoryMessageCode == 109  \* "m"
TradingActionMessageCode == 72  \* "H"
AddOrderShortFormMessageCode == 114  \* "r"
AddOrderLongFormMessageCode == 111  \* "o"
AddQuoteShortFormMessageCode == 106  \* "j"
AddQuoteLongFormMessageCode == 74  \* "J"
SingleSideExecutedMessageCode == 101  \* "e"
SingleSideExecutedWithPriceMessageCode == 99  \* "c"
OrderCancelMessageCode == 88  \* "X"
SingleSideReplaceShortFormMessageCode == 117  \* "u"
SingleSideReplaceLongFormMessageCode == 85  \* "U"
SingleSideDeleteMessageCode == 68  \* "D"
SingleSideUpdateMessageCode == 71  \* "G"
QuoteReplaceShortFormMessageCode == 107  \* "k"
QuoteReplaceLongFormMessageCode == 75  \* "K"
QuoteDeleteMessageCode == 89  \* "Y"
TradeMessageCode == 113  \* "q"
NetOrderImbalanceMessageCode == 79  \* "O"

UdpPayload ==
    [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {DerivativeDirectoryMessageCode}, body : DerivativeDirectoryMessage ]
        \cup [ tag : {TradingActionMessageCode}, body : TradingActionMessage ]
        \cup [ tag : {AddOrderShortFormMessageCode}, body : AddOrderShortFormMessage ]
        \cup [ tag : {AddOrderLongFormMessageCode}, body : AddOrderLongFormMessage ]
        \cup [ tag : {AddQuoteShortFormMessageCode}, body : AddQuoteShortFormMessage ]
        \cup [ tag : {AddQuoteLongFormMessageCode}, body : AddQuoteLongFormMessage ]
        \cup [ tag : {SingleSideExecutedMessageCode}, body : SingleSideExecutedMessage ]
        \cup [ tag : {SingleSideExecutedWithPriceMessageCode}, body : SingleSideExecutedWithPriceMessage ]
        \cup [ tag : {OrderCancelMessageCode}, body : OrderCancelMessage ]
        \cup [ tag : {SingleSideReplaceShortFormMessageCode}, body : SingleSideReplaceShortFormMessage ]
        \cup [ tag : {SingleSideReplaceLongFormMessageCode}, body : SingleSideReplaceLongFormMessage ]
        \cup [ tag : {SingleSideDeleteMessageCode}, body : SingleSideDeleteMessage ]
        \cup [ tag : {SingleSideUpdateMessageCode}, body : SingleSideUpdateMessage ]
        \cup [ tag : {QuoteReplaceShortFormMessageCode}, body : QuoteReplaceShortFormMessage ]
        \cup [ tag : {QuoteReplaceLongFormMessageCode}, body : QuoteReplaceLongFormMessage ]
        \cup [ tag : {QuoteDeleteMessageCode}, body : QuoteDeleteMessage ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {NetOrderImbalanceMessageCode}, body : NetOrderImbalanceMessage ]

EncodeUdpPayload(message) ==
    CASE message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = DerivativeDirectoryMessageCode -> EncodeDerivativeDirectoryMessage(message.body)
      [] message.tag = TradingActionMessageCode -> EncodeTradingActionMessage(message.body)
      [] message.tag = AddOrderShortFormMessageCode -> EncodeAddOrderShortFormMessage(message.body)
      [] message.tag = AddOrderLongFormMessageCode -> EncodeAddOrderLongFormMessage(message.body)
      [] message.tag = AddQuoteShortFormMessageCode -> EncodeAddQuoteShortFormMessage(message.body)
      [] message.tag = AddQuoteLongFormMessageCode -> EncodeAddQuoteLongFormMessage(message.body)
      [] message.tag = SingleSideExecutedMessageCode -> EncodeSingleSideExecutedMessage(message.body)
      [] message.tag = SingleSideExecutedWithPriceMessageCode -> EncodeSingleSideExecutedWithPriceMessage(message.body)
      [] message.tag = OrderCancelMessageCode -> EncodeOrderCancelMessage(message.body)
      [] message.tag = SingleSideReplaceShortFormMessageCode -> EncodeSingleSideReplaceShortFormMessage(message.body)
      [] message.tag = SingleSideReplaceLongFormMessageCode -> EncodeSingleSideReplaceLongFormMessage(message.body)
      [] message.tag = SingleSideDeleteMessageCode -> EncodeSingleSideDeleteMessage(message.body)
      [] message.tag = SingleSideUpdateMessageCode -> EncodeSingleSideUpdateMessage(message.body)
      [] message.tag = QuoteReplaceShortFormMessageCode -> EncodeQuoteReplaceShortFormMessage(message.body)
      [] message.tag = QuoteReplaceLongFormMessageCode -> EncodeQuoteReplaceLongFormMessage(message.body)
      [] message.tag = QuoteDeleteMessageCode -> EncodeQuoteDeleteMessage(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = NetOrderImbalanceMessageCode -> EncodeNetOrderImbalanceMessage(message.body)

DecodeUdpPayload(tag, bytes) ==
    LET read ==
            CASE tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = DerivativeDirectoryMessageCode -> DecodeDerivativeDirectoryMessage(bytes)
              [] tag = TradingActionMessageCode -> DecodeTradingActionMessage(bytes)
              [] tag = AddOrderShortFormMessageCode -> DecodeAddOrderShortFormMessage(bytes)
              [] tag = AddOrderLongFormMessageCode -> DecodeAddOrderLongFormMessage(bytes)
              [] tag = AddQuoteShortFormMessageCode -> DecodeAddQuoteShortFormMessage(bytes)
              [] tag = AddQuoteLongFormMessageCode -> DecodeAddQuoteLongFormMessage(bytes)
              [] tag = SingleSideExecutedMessageCode -> DecodeSingleSideExecutedMessage(bytes)
              [] tag = SingleSideExecutedWithPriceMessageCode -> DecodeSingleSideExecutedWithPriceMessage(bytes)
              [] tag = OrderCancelMessageCode -> DecodeOrderCancelMessage(bytes)
              [] tag = SingleSideReplaceShortFormMessageCode -> DecodeSingleSideReplaceShortFormMessage(bytes)
              [] tag = SingleSideReplaceLongFormMessageCode -> DecodeSingleSideReplaceLongFormMessage(bytes)
              [] tag = SingleSideDeleteMessageCode -> DecodeSingleSideDeleteMessage(bytes)
              [] tag = SingleSideUpdateMessageCode -> DecodeSingleSideUpdateMessage(bytes)
              [] tag = QuoteReplaceShortFormMessageCode -> DecodeQuoteReplaceShortFormMessage(bytes)
              [] tag = QuoteReplaceLongFormMessageCode -> DecodeQuoteReplaceLongFormMessage(bytes)
              [] tag = QuoteDeleteMessageCode -> DecodeQuoteDeleteMessage(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = NetOrderImbalanceMessageCode -> DecodeNetOrderImbalanceMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroUdpPayload == [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]

(* Each Udp Payload in turn, at the values the message it names is checked at *)
CheckedUdpPayload ==
    { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> DerivativeDirectoryMessageCode, body |-> one] : one \in CheckedDerivativeDirectoryMessage }
        \cup { [tag |-> TradingActionMessageCode, body |-> one] : one \in CheckedTradingActionMessage }
        \cup { [tag |-> AddOrderShortFormMessageCode, body |-> one] : one \in CheckedAddOrderShortFormMessage }
        \cup { [tag |-> AddOrderLongFormMessageCode, body |-> one] : one \in CheckedAddOrderLongFormMessage }
        \cup { [tag |-> AddQuoteShortFormMessageCode, body |-> one] : one \in CheckedAddQuoteShortFormMessage }
        \cup { [tag |-> AddQuoteLongFormMessageCode, body |-> one] : one \in CheckedAddQuoteLongFormMessage }
        \cup { [tag |-> SingleSideExecutedMessageCode, body |-> one] : one \in CheckedSingleSideExecutedMessage }
        \cup { [tag |-> SingleSideExecutedWithPriceMessageCode, body |-> one] : one \in CheckedSingleSideExecutedWithPriceMessage }
        \cup { [tag |-> OrderCancelMessageCode, body |-> one] : one \in CheckedOrderCancelMessage }
        \cup { [tag |-> SingleSideReplaceShortFormMessageCode, body |-> one] : one \in CheckedSingleSideReplaceShortFormMessage }
        \cup { [tag |-> SingleSideReplaceLongFormMessageCode, body |-> one] : one \in CheckedSingleSideReplaceLongFormMessage }
        \cup { [tag |-> SingleSideDeleteMessageCode, body |-> one] : one \in CheckedSingleSideDeleteMessage }
        \cup { [tag |-> SingleSideUpdateMessageCode, body |-> one] : one \in CheckedSingleSideUpdateMessage }
        \cup { [tag |-> QuoteReplaceShortFormMessageCode, body |-> one] : one \in CheckedQuoteReplaceShortFormMessage }
        \cup { [tag |-> QuoteReplaceLongFormMessageCode, body |-> one] : one \in CheckedQuoteReplaceLongFormMessage }
        \cup { [tag |-> QuoteDeleteMessageCode, body |-> one] : one \in CheckedQuoteDeleteMessage }
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> NetOrderImbalanceMessageCode, body |-> one] : one \in CheckedNetOrderImbalanceMessage }

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
      [ZeroMessage EXCEPT !.udpPayload = [tag |-> DerivativeDirectoryMessageCode, body |-> ZeroDerivativeDirectoryMessage]],
      [ZeroMessage EXCEPT !.udpPayload = [tag |-> TradingActionMessageCode, body |-> ZeroTradingActionMessage]],
      [ZeroMessage EXCEPT !.udpPayload = [tag |-> AddOrderShortFormMessageCode, body |-> ZeroAddOrderShortFormMessage]],
      [ZeroMessage EXCEPT !.udpPayload = [tag |-> AddOrderLongFormMessageCode, body |-> ZeroAddOrderLongFormMessage]],
      [ZeroMessage EXCEPT !.udpPayload = [tag |-> AddQuoteShortFormMessageCode, body |-> ZeroAddQuoteShortFormMessage]],
      [ZeroMessage EXCEPT !.udpPayload = [tag |-> AddQuoteLongFormMessageCode, body |-> ZeroAddQuoteLongFormMessage]],
      [ZeroMessage EXCEPT !.udpPayload = [tag |-> SingleSideExecutedMessageCode, body |-> ZeroSingleSideExecutedMessage]],
      [ZeroMessage EXCEPT !.udpPayload = [tag |-> SingleSideExecutedWithPriceMessageCode, body |-> ZeroSingleSideExecutedWithPriceMessage]],
      [ZeroMessage EXCEPT !.udpPayload = [tag |-> OrderCancelMessageCode, body |-> ZeroOrderCancelMessage]],
      [ZeroMessage EXCEPT !.udpPayload = [tag |-> SingleSideReplaceShortFormMessageCode, body |-> ZeroSingleSideReplaceShortFormMessage]],
      [ZeroMessage EXCEPT !.udpPayload = [tag |-> SingleSideReplaceLongFormMessageCode, body |-> ZeroSingleSideReplaceLongFormMessage]],
      [ZeroMessage EXCEPT !.udpPayload = [tag |-> SingleSideDeleteMessageCode, body |-> ZeroSingleSideDeleteMessage]],
      [ZeroMessage EXCEPT !.udpPayload = [tag |-> SingleSideUpdateMessageCode, body |-> ZeroSingleSideUpdateMessage]],
      [ZeroMessage EXCEPT !.udpPayload = [tag |-> QuoteReplaceShortFormMessageCode, body |-> ZeroQuoteReplaceShortFormMessage]],
      [ZeroMessage EXCEPT !.udpPayload = [tag |-> QuoteReplaceLongFormMessageCode, body |-> ZeroQuoteReplaceLongFormMessage]],
      [ZeroMessage EXCEPT !.udpPayload = [tag |-> QuoteDeleteMessageCode, body |-> ZeroQuoteDeleteMessage]],
      [ZeroMessage EXCEPT !.udpPayload = [tag |-> TradeMessageCode, body |-> ZeroTradeMessage]],
      [ZeroMessage EXCEPT !.udpPayload = [tag |-> NetOrderImbalanceMessageCode, body |-> ZeroNetOrderImbalanceMessage]] }

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

(* Every Derivative Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDerivativeDirectoryMessage ==
    \A message \in CheckedDerivativeDirectoryMessage :
        LET read == DecodeDerivativeDirectoryMessage(EncodeDerivativeDirectoryMessage(message))
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

(* Every Add Order Short Form Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderShortFormMessage ==
    \A message \in CheckedAddOrderShortFormMessage :
        LET read == DecodeAddOrderShortFormMessage(EncodeAddOrderShortFormMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Order Long Form Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderLongFormMessage ==
    \A message \in CheckedAddOrderLongFormMessage :
        LET read == DecodeAddOrderLongFormMessage(EncodeAddOrderLongFormMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Quote Short Form Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddQuoteShortFormMessage ==
    \A message \in CheckedAddQuoteShortFormMessage :
        LET read == DecodeAddQuoteShortFormMessage(EncodeAddQuoteShortFormMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Quote Long Form Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddQuoteLongFormMessage ==
    \A message \in CheckedAddQuoteLongFormMessage :
        LET read == DecodeAddQuoteLongFormMessage(EncodeAddQuoteLongFormMessage(message))
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

(* Every Order Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelMessage ==
    \A message \in CheckedOrderCancelMessage :
        LET read == DecodeOrderCancelMessage(EncodeOrderCancelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Side Replace Short Form Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleSideReplaceShortFormMessage ==
    \A message \in CheckedSingleSideReplaceShortFormMessage :
        LET read == DecodeSingleSideReplaceShortFormMessage(EncodeSingleSideReplaceShortFormMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Side Replace Long Form Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleSideReplaceLongFormMessage ==
    \A message \in CheckedSingleSideReplaceLongFormMessage :
        LET read == DecodeSingleSideReplaceLongFormMessage(EncodeSingleSideReplaceLongFormMessage(message))
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

(* Every Quote Replace Short Form Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteReplaceShortFormMessage ==
    \A message \in CheckedQuoteReplaceShortFormMessage :
        LET read == DecodeQuoteReplaceShortFormMessage(EncodeQuoteReplaceShortFormMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Replace Long Form Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteReplaceLongFormMessage ==
    \A message \in CheckedQuoteReplaceLongFormMessage :
        LET read == DecodeQuoteReplaceLongFormMessage(EncodeQuoteReplaceLongFormMessage(message))
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

(* Every Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeMessage ==
    \A message \in CheckedTradeMessage :
        LET read == DecodeTradeMessage(EncodeTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Net Order Imbalance Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNetOrderImbalanceMessage ==
    \A message \in CheckedNetOrderImbalanceMessage :
        LET read == DecodeNetOrderImbalanceMessage(EncodeNetOrderImbalanceMessage(message))
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
