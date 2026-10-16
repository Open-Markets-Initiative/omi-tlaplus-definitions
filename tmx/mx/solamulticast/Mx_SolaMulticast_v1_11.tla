---------------------- MODULE Mx_SolaMulticast_v1_11 -----------------------
(***************************************************************************)
(* TMX Group Sola Multicast v1.11                                          *)
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
(* Note: Packet fills its datagram with as many messages as the bytes      *)
(* hold, so it is read as a run of them.                                   *)
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

(* The integer a text protocol writes as the characters of itself: a count of one is *)
(* the character "1", which is the byte 49. Read by its digits, and written back *)
(* zero filled to the width the field states, which is how such a field is filled. *)
Digit == 48 .. 57

RECURSIVE DecodeDigits(_)
DecodeDigits(bytes) ==
    IF bytes = << >>
    THEN 0
    ELSE DecodeDigits(SubSeq(bytes, 1, Len(bytes) - 1)) * 10 + (bytes[Len(bytes)] - 48)

RECURSIVE EncodeDigits(_, _)
EncodeDigits(value, width) ==
    IF width = 0
    THEN << >>
    ELSE EncodeDigits(value \div 10, width - 1) \o <<48 + (value % 10)>>

(* A field written as digits that holds anything else is no number, so it is not read: *)
(* the value would not be what the bytes say, and would not write back as them. *)
ReadDigits(bytes, width) ==
    IF Len(bytes) < width \/ \E i \in 1 .. width : bytes[i] \notin Digit
    THEN Fail
    ELSE Ok(DecodeDigits(SubSeq(bytes, 1, width)), SubSeq(bytes, width + 1, Len(bytes)))

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
(* Option Trade Message: 76 bytes                                          *)
(***************************************************************************)

OptionTradeMessage ==
    [ exchangeId                   : Sample(1),
      rootSymbol                   : Sample(6),
      expiryMonth                  : Sample(1),
      filler1                      : Sample(1),
      strikePriceInstrument        : Sample(7),
      strikePriceFractionIndicator : Sample(1),
      expiryYear                   : Sample(2),
      expiryDay                    : Sample(2),
      volume                       : Sample(8),
      tradePrice                   : Sample(6),
      tradePriceFractionIndicator  : Sample(1),
      netChangeSign                : Sample(1),
      netChange                    : Sample(6),
      netChangeFractionIndicator   : Sample(1),
      filler6                      : Sample(6),
      timestamp                    : Sample(9),
      openInterest                 : Sample(7),
      secondFiller1                : Sample(1),
      priceIndicatorMarker         : Sample(1),
      tradeNumber                  : Sample(8) ]

EncodeOptionTradeMessage(message) ==
    message.exchangeId
        \o message.rootSymbol
        \o message.expiryMonth
        \o message.filler1
        \o message.strikePriceInstrument
        \o message.strikePriceFractionIndicator
        \o message.expiryYear
        \o message.expiryDay
        \o message.volume
        \o message.tradePrice
        \o message.tradePriceFractionIndicator
        \o message.netChangeSign
        \o message.netChange
        \o message.netChangeFractionIndicator
        \o message.filler6
        \o message.timestamp
        \o message.openInterest
        \o message.secondFiller1
        \o message.priceIndicatorMarker
        \o message.tradeNumber

DecodeOptionTradeMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET rootSymbol == ReadBytes(exchangeId.rest, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET expiryMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~expiryMonth.ok THEN Fail ELSE
    LET filler1 == ReadBytes(expiryMonth.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET strikePriceInstrument == ReadBytes(filler1.rest, 7) IN IF ~strikePriceInstrument.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePriceInstrument.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(strikePriceFractionIndicator.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET volume == ReadBytes(expiryDay.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(volume.rest, 6) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradePriceFractionIndicator == ReadBytes(tradePrice.rest, 1) IN IF ~tradePriceFractionIndicator.ok THEN Fail ELSE
    LET netChangeSign == ReadBytes(tradePriceFractionIndicator.rest, 1) IN IF ~netChangeSign.ok THEN Fail ELSE
    LET netChange == ReadBytes(netChangeSign.rest, 6) IN IF ~netChange.ok THEN Fail ELSE
    LET netChangeFractionIndicator == ReadBytes(netChange.rest, 1) IN IF ~netChangeFractionIndicator.ok THEN Fail ELSE
    LET filler6 == ReadBytes(netChangeFractionIndicator.rest, 6) IN IF ~filler6.ok THEN Fail ELSE
    LET timestamp == ReadBytes(filler6.rest, 9) IN IF ~timestamp.ok THEN Fail ELSE
    LET openInterest == ReadBytes(timestamp.rest, 7) IN IF ~openInterest.ok THEN Fail ELSE
    LET secondFiller1 == ReadBytes(openInterest.rest, 1) IN IF ~secondFiller1.ok THEN Fail ELSE
    LET priceIndicatorMarker == ReadBytes(secondFiller1.rest, 1) IN IF ~priceIndicatorMarker.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(priceIndicatorMarker.rest, 8) IN IF ~tradeNumber.ok THEN Fail ELSE
    Ok([ exchangeId                   |-> exchangeId.value,
         rootSymbol                   |-> rootSymbol.value,
         expiryMonth                  |-> expiryMonth.value,
         filler1                      |-> filler1.value,
         strikePriceInstrument        |-> strikePriceInstrument.value,
         strikePriceFractionIndicator |-> strikePriceFractionIndicator.value,
         expiryYear                   |-> expiryYear.value,
         expiryDay                    |-> expiryDay.value,
         volume                       |-> volume.value,
         tradePrice                   |-> tradePrice.value,
         tradePriceFractionIndicator  |-> tradePriceFractionIndicator.value,
         netChangeSign                |-> netChangeSign.value,
         netChange                    |-> netChange.value,
         netChangeFractionIndicator   |-> netChangeFractionIndicator.value,
         filler6                      |-> filler6.value,
         timestamp                    |-> timestamp.value,
         openInterest                 |-> openInterest.value,
         secondFiller1                |-> secondFiller1.value,
         priceIndicatorMarker         |-> priceIndicatorMarker.value,
         tradeNumber                  |-> tradeNumber.value ], tradeNumber.rest)

ZeroOptionTradeMessage ==
    [ exchangeId                   |-> [i \in 1 .. 1 |-> 0],
      rootSymbol                   |-> [i \in 1 .. 6 |-> 0],
      expiryMonth                  |-> [i \in 1 .. 1 |-> 0],
      filler1                      |-> [i \in 1 .. 1 |-> 0],
      strikePriceInstrument        |-> [i \in 1 .. 7 |-> 0],
      strikePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      expiryYear                   |-> [i \in 1 .. 2 |-> 0],
      expiryDay                    |-> [i \in 1 .. 2 |-> 0],
      volume                       |-> [i \in 1 .. 8 |-> 0],
      tradePrice                   |-> [i \in 1 .. 6 |-> 0],
      tradePriceFractionIndicator  |-> [i \in 1 .. 1 |-> 0],
      netChangeSign                |-> [i \in 1 .. 1 |-> 0],
      netChange                    |-> [i \in 1 .. 6 |-> 0],
      netChangeFractionIndicator   |-> [i \in 1 .. 1 |-> 0],
      filler6                      |-> [i \in 1 .. 6 |-> 0],
      timestamp                    |-> [i \in 1 .. 9 |-> 0],
      openInterest                 |-> [i \in 1 .. 7 |-> 0],
      secondFiller1                |-> [i \in 1 .. 1 |-> 0],
      priceIndicatorMarker         |-> [i \in 1 .. 1 |-> 0],
      tradeNumber                  |-> [i \in 1 .. 8 |-> 0] ]

(* Option Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionTradeMessage ==
    { ZeroOptionTradeMessage }
        \cup { [ZeroOptionTradeMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.expiryMonth = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.strikePriceInstrument = one] : one \in Sample(7) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.tradePrice = one] : one \in Sample(6) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.tradePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.netChangeSign = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.netChange = one] : one \in Sample(6) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.netChangeFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.filler6 = one] : one \in Sample(6) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.timestamp = one] : one \in Sample(9) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.openInterest = one] : one \in Sample(7) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.secondFiller1 = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.priceIndicatorMarker = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.tradeNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Future Options Trade Message: 77 bytes                                  *)
(***************************************************************************)

FutureOptionsTradeMessage ==
    [ exchangeId                   : Sample(1),
      rootSymbol                   : Sample(6),
      contractMonthCode            : Sample(1),
      expiryYear                   : Sample(2),
      expiryDay                    : Sample(2),
      callPutCode                  : Sample(1),
      strikePriceInstrument        : Sample(7),
      strikePriceFractionIndicator : Sample(1),
      volume                       : Sample(8),
      tradePrice                   : Sample(6),
      tradePriceFractionIndicator  : Sample(1),
      priceIndicatorMarker         : Sample(1),
      netChangeSign                : Sample(1),
      netChange                    : Sample(6),
      netChangeFractionIndicator   : Sample(1),
      filler6                      : Sample(6),
      timestamp                    : Sample(9),
      openInterest                 : Sample(7),
      filler2                      : Sample(2),
      tradeNumber                  : Sample(8) ]

EncodeFutureOptionsTradeMessage(message) ==
    message.exchangeId
        \o message.rootSymbol
        \o message.contractMonthCode
        \o message.expiryYear
        \o message.expiryDay
        \o message.callPutCode
        \o message.strikePriceInstrument
        \o message.strikePriceFractionIndicator
        \o message.volume
        \o message.tradePrice
        \o message.tradePriceFractionIndicator
        \o message.priceIndicatorMarker
        \o message.netChangeSign
        \o message.netChange
        \o message.netChangeFractionIndicator
        \o message.filler6
        \o message.timestamp
        \o message.openInterest
        \o message.filler2
        \o message.tradeNumber

DecodeFutureOptionsTradeMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET rootSymbol == ReadBytes(exchangeId.rest, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET contractMonthCode == ReadBytes(rootSymbol.rest, 1) IN IF ~contractMonthCode.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(contractMonthCode.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET callPutCode == ReadBytes(expiryDay.rest, 1) IN IF ~callPutCode.ok THEN Fail ELSE
    LET strikePriceInstrument == ReadBytes(callPutCode.rest, 7) IN IF ~strikePriceInstrument.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePriceInstrument.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    LET volume == ReadBytes(strikePriceFractionIndicator.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(volume.rest, 6) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradePriceFractionIndicator == ReadBytes(tradePrice.rest, 1) IN IF ~tradePriceFractionIndicator.ok THEN Fail ELSE
    LET priceIndicatorMarker == ReadBytes(tradePriceFractionIndicator.rest, 1) IN IF ~priceIndicatorMarker.ok THEN Fail ELSE
    LET netChangeSign == ReadBytes(priceIndicatorMarker.rest, 1) IN IF ~netChangeSign.ok THEN Fail ELSE
    LET netChange == ReadBytes(netChangeSign.rest, 6) IN IF ~netChange.ok THEN Fail ELSE
    LET netChangeFractionIndicator == ReadBytes(netChange.rest, 1) IN IF ~netChangeFractionIndicator.ok THEN Fail ELSE
    LET filler6 == ReadBytes(netChangeFractionIndicator.rest, 6) IN IF ~filler6.ok THEN Fail ELSE
    LET timestamp == ReadBytes(filler6.rest, 9) IN IF ~timestamp.ok THEN Fail ELSE
    LET openInterest == ReadBytes(timestamp.rest, 7) IN IF ~openInterest.ok THEN Fail ELSE
    LET filler2 == ReadBytes(openInterest.rest, 2) IN IF ~filler2.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(filler2.rest, 8) IN IF ~tradeNumber.ok THEN Fail ELSE
    Ok([ exchangeId                   |-> exchangeId.value,
         rootSymbol                   |-> rootSymbol.value,
         contractMonthCode            |-> contractMonthCode.value,
         expiryYear                   |-> expiryYear.value,
         expiryDay                    |-> expiryDay.value,
         callPutCode                  |-> callPutCode.value,
         strikePriceInstrument        |-> strikePriceInstrument.value,
         strikePriceFractionIndicator |-> strikePriceFractionIndicator.value,
         volume                       |-> volume.value,
         tradePrice                   |-> tradePrice.value,
         tradePriceFractionIndicator  |-> tradePriceFractionIndicator.value,
         priceIndicatorMarker         |-> priceIndicatorMarker.value,
         netChangeSign                |-> netChangeSign.value,
         netChange                    |-> netChange.value,
         netChangeFractionIndicator   |-> netChangeFractionIndicator.value,
         filler6                      |-> filler6.value,
         timestamp                    |-> timestamp.value,
         openInterest                 |-> openInterest.value,
         filler2                      |-> filler2.value,
         tradeNumber                  |-> tradeNumber.value ], tradeNumber.rest)

ZeroFutureOptionsTradeMessage ==
    [ exchangeId                   |-> [i \in 1 .. 1 |-> 0],
      rootSymbol                   |-> [i \in 1 .. 6 |-> 0],
      contractMonthCode            |-> [i \in 1 .. 1 |-> 0],
      expiryYear                   |-> [i \in 1 .. 2 |-> 0],
      expiryDay                    |-> [i \in 1 .. 2 |-> 0],
      callPutCode                  |-> [i \in 1 .. 1 |-> 0],
      strikePriceInstrument        |-> [i \in 1 .. 7 |-> 0],
      strikePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      volume                       |-> [i \in 1 .. 8 |-> 0],
      tradePrice                   |-> [i \in 1 .. 6 |-> 0],
      tradePriceFractionIndicator  |-> [i \in 1 .. 1 |-> 0],
      priceIndicatorMarker         |-> [i \in 1 .. 1 |-> 0],
      netChangeSign                |-> [i \in 1 .. 1 |-> 0],
      netChange                    |-> [i \in 1 .. 6 |-> 0],
      netChangeFractionIndicator   |-> [i \in 1 .. 1 |-> 0],
      filler6                      |-> [i \in 1 .. 6 |-> 0],
      timestamp                    |-> [i \in 1 .. 9 |-> 0],
      openInterest                 |-> [i \in 1 .. 7 |-> 0],
      filler2                      |-> [i \in 1 .. 2 |-> 0],
      tradeNumber                  |-> [i \in 1 .. 8 |-> 0] ]

(* Future Options Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedFutureOptionsTradeMessage ==
    { ZeroFutureOptionsTradeMessage }
        \cup { [ZeroFutureOptionsTradeMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsTradeMessage EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionsTradeMessage EXCEPT !.contractMonthCode = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsTradeMessage EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionsTradeMessage EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionsTradeMessage EXCEPT !.callPutCode = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsTradeMessage EXCEPT !.strikePriceInstrument = one] : one \in Sample(7) }
        \cup { [ZeroFutureOptionsTradeMessage EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsTradeMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroFutureOptionsTradeMessage EXCEPT !.tradePrice = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionsTradeMessage EXCEPT !.tradePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsTradeMessage EXCEPT !.priceIndicatorMarker = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsTradeMessage EXCEPT !.netChangeSign = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsTradeMessage EXCEPT !.netChange = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionsTradeMessage EXCEPT !.netChangeFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsTradeMessage EXCEPT !.filler6 = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionsTradeMessage EXCEPT !.timestamp = one] : one \in Sample(9) }
        \cup { [ZeroFutureOptionsTradeMessage EXCEPT !.openInterest = one] : one \in Sample(7) }
        \cup { [ZeroFutureOptionsTradeMessage EXCEPT !.filler2 = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionsTradeMessage EXCEPT !.tradeNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Futures Trade Message: 59 bytes                                         *)
(***************************************************************************)

FuturesTradeMessage ==
    [ exchangeId                  : Sample(1),
      rootSymbol                  : Sample(6),
      deliveryMonth               : Sample(1),
      deliveryYearFutures         : Sample(2),
      deliveryDay                 : Sample(2),
      volume                      : Sample(8),
      tradePrice                  : Sample(6),
      tradePriceFractionIndicator : Sample(1),
      netChangeSign               : Sample(1),
      netChange                   : Sample(6),
      netChangeFractionIndicator  : Sample(1),
      filler6                     : Sample(6),
      timestamp                   : Sample(9),
      priceIndicatorMarker        : Sample(1),
      tradeNumber                 : Sample(8) ]

EncodeFuturesTradeMessage(message) ==
    message.exchangeId
        \o message.rootSymbol
        \o message.deliveryMonth
        \o message.deliveryYearFutures
        \o message.deliveryDay
        \o message.volume
        \o message.tradePrice
        \o message.tradePriceFractionIndicator
        \o message.netChangeSign
        \o message.netChange
        \o message.netChangeFractionIndicator
        \o message.filler6
        \o message.timestamp
        \o message.priceIndicatorMarker
        \o message.tradeNumber

DecodeFuturesTradeMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET rootSymbol == ReadBytes(exchangeId.rest, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET deliveryMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~deliveryMonth.ok THEN Fail ELSE
    LET deliveryYearFutures == ReadBytes(deliveryMonth.rest, 2) IN IF ~deliveryYearFutures.ok THEN Fail ELSE
    LET deliveryDay == ReadBytes(deliveryYearFutures.rest, 2) IN IF ~deliveryDay.ok THEN Fail ELSE
    LET volume == ReadBytes(deliveryDay.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(volume.rest, 6) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradePriceFractionIndicator == ReadBytes(tradePrice.rest, 1) IN IF ~tradePriceFractionIndicator.ok THEN Fail ELSE
    LET netChangeSign == ReadBytes(tradePriceFractionIndicator.rest, 1) IN IF ~netChangeSign.ok THEN Fail ELSE
    LET netChange == ReadBytes(netChangeSign.rest, 6) IN IF ~netChange.ok THEN Fail ELSE
    LET netChangeFractionIndicator == ReadBytes(netChange.rest, 1) IN IF ~netChangeFractionIndicator.ok THEN Fail ELSE
    LET filler6 == ReadBytes(netChangeFractionIndicator.rest, 6) IN IF ~filler6.ok THEN Fail ELSE
    LET timestamp == ReadBytes(filler6.rest, 9) IN IF ~timestamp.ok THEN Fail ELSE
    LET priceIndicatorMarker == ReadBytes(timestamp.rest, 1) IN IF ~priceIndicatorMarker.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(priceIndicatorMarker.rest, 8) IN IF ~tradeNumber.ok THEN Fail ELSE
    Ok([ exchangeId                  |-> exchangeId.value,
         rootSymbol                  |-> rootSymbol.value,
         deliveryMonth               |-> deliveryMonth.value,
         deliveryYearFutures         |-> deliveryYearFutures.value,
         deliveryDay                 |-> deliveryDay.value,
         volume                      |-> volume.value,
         tradePrice                  |-> tradePrice.value,
         tradePriceFractionIndicator |-> tradePriceFractionIndicator.value,
         netChangeSign               |-> netChangeSign.value,
         netChange                   |-> netChange.value,
         netChangeFractionIndicator  |-> netChangeFractionIndicator.value,
         filler6                     |-> filler6.value,
         timestamp                   |-> timestamp.value,
         priceIndicatorMarker        |-> priceIndicatorMarker.value,
         tradeNumber                 |-> tradeNumber.value ], tradeNumber.rest)

ZeroFuturesTradeMessage ==
    [ exchangeId                  |-> [i \in 1 .. 1 |-> 0],
      rootSymbol                  |-> [i \in 1 .. 6 |-> 0],
      deliveryMonth               |-> [i \in 1 .. 1 |-> 0],
      deliveryYearFutures         |-> [i \in 1 .. 2 |-> 0],
      deliveryDay                 |-> [i \in 1 .. 2 |-> 0],
      volume                      |-> [i \in 1 .. 8 |-> 0],
      tradePrice                  |-> [i \in 1 .. 6 |-> 0],
      tradePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      netChangeSign               |-> [i \in 1 .. 1 |-> 0],
      netChange                   |-> [i \in 1 .. 6 |-> 0],
      netChangeFractionIndicator  |-> [i \in 1 .. 1 |-> 0],
      filler6                     |-> [i \in 1 .. 6 |-> 0],
      timestamp                   |-> [i \in 1 .. 9 |-> 0],
      priceIndicatorMarker        |-> [i \in 1 .. 1 |-> 0],
      tradeNumber                 |-> [i \in 1 .. 8 |-> 0] ]

(* Futures Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedFuturesTradeMessage ==
    { ZeroFuturesTradeMessage }
        \cup { [ZeroFuturesTradeMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroFuturesTradeMessage EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroFuturesTradeMessage EXCEPT !.deliveryMonth = one] : one \in Sample(1) }
        \cup { [ZeroFuturesTradeMessage EXCEPT !.deliveryYearFutures = one] : one \in Sample(2) }
        \cup { [ZeroFuturesTradeMessage EXCEPT !.deliveryDay = one] : one \in Sample(2) }
        \cup { [ZeroFuturesTradeMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroFuturesTradeMessage EXCEPT !.tradePrice = one] : one \in Sample(6) }
        \cup { [ZeroFuturesTradeMessage EXCEPT !.tradePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFuturesTradeMessage EXCEPT !.netChangeSign = one] : one \in Sample(1) }
        \cup { [ZeroFuturesTradeMessage EXCEPT !.netChange = one] : one \in Sample(6) }
        \cup { [ZeroFuturesTradeMessage EXCEPT !.netChangeFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFuturesTradeMessage EXCEPT !.filler6 = one] : one \in Sample(6) }
        \cup { [ZeroFuturesTradeMessage EXCEPT !.timestamp = one] : one \in Sample(9) }
        \cup { [ZeroFuturesTradeMessage EXCEPT !.priceIndicatorMarker = one] : one \in Sample(1) }
        \cup { [ZeroFuturesTradeMessage EXCEPT !.tradeNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Strategy Trade Message: 79 bytes                                        *)
(***************************************************************************)

StrategyTradeMessage ==
    [ exchangeId                  : Sample(1),
      symbol                      : Sample(30),
      volume                      : Sample(8),
      tradePriceSign              : Sample(1),
      tradePrice                  : Sample(6),
      tradePriceFractionIndicator : Sample(1),
      netChangeSign               : Sample(1),
      netChange                   : Sample(6),
      netChangeFractionIndicator  : Sample(1),
      filler6                     : Sample(6),
      timestamp                   : Sample(9),
      priceIndicatorMarker        : Sample(1),
      tradeNumber                 : Sample(8) ]

EncodeStrategyTradeMessage(message) ==
    message.exchangeId
        \o message.symbol
        \o message.volume
        \o message.tradePriceSign
        \o message.tradePrice
        \o message.tradePriceFractionIndicator
        \o message.netChangeSign
        \o message.netChange
        \o message.netChangeFractionIndicator
        \o message.filler6
        \o message.timestamp
        \o message.priceIndicatorMarker
        \o message.tradeNumber

DecodeStrategyTradeMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET symbol == ReadBytes(exchangeId.rest, 30) IN IF ~symbol.ok THEN Fail ELSE
    LET volume == ReadBytes(symbol.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET tradePriceSign == ReadBytes(volume.rest, 1) IN IF ~tradePriceSign.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(tradePriceSign.rest, 6) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradePriceFractionIndicator == ReadBytes(tradePrice.rest, 1) IN IF ~tradePriceFractionIndicator.ok THEN Fail ELSE
    LET netChangeSign == ReadBytes(tradePriceFractionIndicator.rest, 1) IN IF ~netChangeSign.ok THEN Fail ELSE
    LET netChange == ReadBytes(netChangeSign.rest, 6) IN IF ~netChange.ok THEN Fail ELSE
    LET netChangeFractionIndicator == ReadBytes(netChange.rest, 1) IN IF ~netChangeFractionIndicator.ok THEN Fail ELSE
    LET filler6 == ReadBytes(netChangeFractionIndicator.rest, 6) IN IF ~filler6.ok THEN Fail ELSE
    LET timestamp == ReadBytes(filler6.rest, 9) IN IF ~timestamp.ok THEN Fail ELSE
    LET priceIndicatorMarker == ReadBytes(timestamp.rest, 1) IN IF ~priceIndicatorMarker.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(priceIndicatorMarker.rest, 8) IN IF ~tradeNumber.ok THEN Fail ELSE
    Ok([ exchangeId                  |-> exchangeId.value,
         symbol                      |-> symbol.value,
         volume                      |-> volume.value,
         tradePriceSign              |-> tradePriceSign.value,
         tradePrice                  |-> tradePrice.value,
         tradePriceFractionIndicator |-> tradePriceFractionIndicator.value,
         netChangeSign               |-> netChangeSign.value,
         netChange                   |-> netChange.value,
         netChangeFractionIndicator  |-> netChangeFractionIndicator.value,
         filler6                     |-> filler6.value,
         timestamp                   |-> timestamp.value,
         priceIndicatorMarker        |-> priceIndicatorMarker.value,
         tradeNumber                 |-> tradeNumber.value ], tradeNumber.rest)

ZeroStrategyTradeMessage ==
    [ exchangeId                  |-> [i \in 1 .. 1 |-> 0],
      symbol                      |-> [i \in 1 .. 30 |-> 0],
      volume                      |-> [i \in 1 .. 8 |-> 0],
      tradePriceSign              |-> [i \in 1 .. 1 |-> 0],
      tradePrice                  |-> [i \in 1 .. 6 |-> 0],
      tradePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      netChangeSign               |-> [i \in 1 .. 1 |-> 0],
      netChange                   |-> [i \in 1 .. 6 |-> 0],
      netChangeFractionIndicator  |-> [i \in 1 .. 1 |-> 0],
      filler6                     |-> [i \in 1 .. 6 |-> 0],
      timestamp                   |-> [i \in 1 .. 9 |-> 0],
      priceIndicatorMarker        |-> [i \in 1 .. 1 |-> 0],
      tradeNumber                 |-> [i \in 1 .. 8 |-> 0] ]

(* Strategy Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedStrategyTradeMessage ==
    { ZeroStrategyTradeMessage }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.symbol = one] : one \in Sample(30) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.tradePriceSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.tradePrice = one] : one \in Sample(6) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.tradePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.netChangeSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.netChange = one] : one \in Sample(6) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.netChangeFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.filler6 = one] : one \in Sample(6) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.timestamp = one] : one \in Sample(9) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.priceIndicatorMarker = one] : one \in Sample(1) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.tradeNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Swap Future Trade Message: 61 bytes                                     *)
(***************************************************************************)

SwapFutureTradeMessage ==
    [ exchangeId                  : Sample(1),
      rootSymbol                  : Sample(6),
      expiryMonth                 : Sample(1),
      expiryYear                  : Sample(2),
      expiryDay                   : Sample(2),
      tenor                       : Sample(2),
      fixedRate                   : Sample(5),
      fixedRateFractionIndicator  : Sample(1),
      tradeVolume                 : Sample(8),
      tradePrice                  : Sample(6),
      tradePriceFractionIndicator : Sample(1),
      netChangeSign               : Sample(1),
      netChange                   : Sample(6),
      netChangeFractionIndicator  : Sample(1),
      timestamp                   : Sample(9),
      priceIndicatorMarker        : Sample(1),
      tradeNumber                 : Sample(8) ]

EncodeSwapFutureTradeMessage(message) ==
    message.exchangeId
        \o message.rootSymbol
        \o message.expiryMonth
        \o message.expiryYear
        \o message.expiryDay
        \o message.tenor
        \o message.fixedRate
        \o message.fixedRateFractionIndicator
        \o message.tradeVolume
        \o message.tradePrice
        \o message.tradePriceFractionIndicator
        \o message.netChangeSign
        \o message.netChange
        \o message.netChangeFractionIndicator
        \o message.timestamp
        \o message.priceIndicatorMarker
        \o message.tradeNumber

DecodeSwapFutureTradeMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET rootSymbol == ReadBytes(exchangeId.rest, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET expiryMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~expiryMonth.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(expiryMonth.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET tenor == ReadBytes(expiryDay.rest, 2) IN IF ~tenor.ok THEN Fail ELSE
    LET fixedRate == ReadBytes(tenor.rest, 5) IN IF ~fixedRate.ok THEN Fail ELSE
    LET fixedRateFractionIndicator == ReadBytes(fixedRate.rest, 1) IN IF ~fixedRateFractionIndicator.ok THEN Fail ELSE
    LET tradeVolume == ReadBytes(fixedRateFractionIndicator.rest, 8) IN IF ~tradeVolume.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(tradeVolume.rest, 6) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradePriceFractionIndicator == ReadBytes(tradePrice.rest, 1) IN IF ~tradePriceFractionIndicator.ok THEN Fail ELSE
    LET netChangeSign == ReadBytes(tradePriceFractionIndicator.rest, 1) IN IF ~netChangeSign.ok THEN Fail ELSE
    LET netChange == ReadBytes(netChangeSign.rest, 6) IN IF ~netChange.ok THEN Fail ELSE
    LET netChangeFractionIndicator == ReadBytes(netChange.rest, 1) IN IF ~netChangeFractionIndicator.ok THEN Fail ELSE
    LET timestamp == ReadBytes(netChangeFractionIndicator.rest, 9) IN IF ~timestamp.ok THEN Fail ELSE
    LET priceIndicatorMarker == ReadBytes(timestamp.rest, 1) IN IF ~priceIndicatorMarker.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(priceIndicatorMarker.rest, 8) IN IF ~tradeNumber.ok THEN Fail ELSE
    Ok([ exchangeId                  |-> exchangeId.value,
         rootSymbol                  |-> rootSymbol.value,
         expiryMonth                 |-> expiryMonth.value,
         expiryYear                  |-> expiryYear.value,
         expiryDay                   |-> expiryDay.value,
         tenor                       |-> tenor.value,
         fixedRate                   |-> fixedRate.value,
         fixedRateFractionIndicator  |-> fixedRateFractionIndicator.value,
         tradeVolume                 |-> tradeVolume.value,
         tradePrice                  |-> tradePrice.value,
         tradePriceFractionIndicator |-> tradePriceFractionIndicator.value,
         netChangeSign               |-> netChangeSign.value,
         netChange                   |-> netChange.value,
         netChangeFractionIndicator  |-> netChangeFractionIndicator.value,
         timestamp                   |-> timestamp.value,
         priceIndicatorMarker        |-> priceIndicatorMarker.value,
         tradeNumber                 |-> tradeNumber.value ], tradeNumber.rest)

ZeroSwapFutureTradeMessage ==
    [ exchangeId                  |-> [i \in 1 .. 1 |-> 0],
      rootSymbol                  |-> [i \in 1 .. 6 |-> 0],
      expiryMonth                 |-> [i \in 1 .. 1 |-> 0],
      expiryYear                  |-> [i \in 1 .. 2 |-> 0],
      expiryDay                   |-> [i \in 1 .. 2 |-> 0],
      tenor                       |-> [i \in 1 .. 2 |-> 0],
      fixedRate                   |-> [i \in 1 .. 5 |-> 0],
      fixedRateFractionIndicator  |-> [i \in 1 .. 1 |-> 0],
      tradeVolume                 |-> [i \in 1 .. 8 |-> 0],
      tradePrice                  |-> [i \in 1 .. 6 |-> 0],
      tradePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      netChangeSign               |-> [i \in 1 .. 1 |-> 0],
      netChange                   |-> [i \in 1 .. 6 |-> 0],
      netChangeFractionIndicator  |-> [i \in 1 .. 1 |-> 0],
      timestamp                   |-> [i \in 1 .. 9 |-> 0],
      priceIndicatorMarker        |-> [i \in 1 .. 1 |-> 0],
      tradeNumber                 |-> [i \in 1 .. 8 |-> 0] ]

(* Swap Future Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedSwapFutureTradeMessage ==
    { ZeroSwapFutureTradeMessage }
        \cup { [ZeroSwapFutureTradeMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureTradeMessage EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroSwapFutureTradeMessage EXCEPT !.expiryMonth = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureTradeMessage EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroSwapFutureTradeMessage EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroSwapFutureTradeMessage EXCEPT !.tenor = one] : one \in Sample(2) }
        \cup { [ZeroSwapFutureTradeMessage EXCEPT !.fixedRate = one] : one \in Sample(5) }
        \cup { [ZeroSwapFutureTradeMessage EXCEPT !.fixedRateFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureTradeMessage EXCEPT !.tradeVolume = one] : one \in Sample(8) }
        \cup { [ZeroSwapFutureTradeMessage EXCEPT !.tradePrice = one] : one \in Sample(6) }
        \cup { [ZeroSwapFutureTradeMessage EXCEPT !.tradePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureTradeMessage EXCEPT !.netChangeSign = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureTradeMessage EXCEPT !.netChange = one] : one \in Sample(6) }
        \cup { [ZeroSwapFutureTradeMessage EXCEPT !.netChangeFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureTradeMessage EXCEPT !.timestamp = one] : one \in Sample(9) }
        \cup { [ZeroSwapFutureTradeMessage EXCEPT !.priceIndicatorMarker = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureTradeMessage EXCEPT !.tradeNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Option Rfq Message: 30 bytes                                            *)
(***************************************************************************)

OptionRfqMessage ==
    [ exchangeId                   : Sample(1),
      rootSymbol                   : Sample(6),
      expiryMonth                  : Sample(1),
      filler1                      : Sample(1),
      strikePriceInstrument        : Sample(7),
      strikePriceFractionIndicator : Sample(1),
      expiryYear                   : Sample(2),
      expiryDay                    : Sample(2),
      requestedSize                : Sample(8),
      requestedMarketSide          : Sample(1) ]

EncodeOptionRfqMessage(message) ==
    message.exchangeId
        \o message.rootSymbol
        \o message.expiryMonth
        \o message.filler1
        \o message.strikePriceInstrument
        \o message.strikePriceFractionIndicator
        \o message.expiryYear
        \o message.expiryDay
        \o message.requestedSize
        \o message.requestedMarketSide

DecodeOptionRfqMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET rootSymbol == ReadBytes(exchangeId.rest, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET expiryMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~expiryMonth.ok THEN Fail ELSE
    LET filler1 == ReadBytes(expiryMonth.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET strikePriceInstrument == ReadBytes(filler1.rest, 7) IN IF ~strikePriceInstrument.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePriceInstrument.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(strikePriceFractionIndicator.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET requestedSize == ReadBytes(expiryDay.rest, 8) IN IF ~requestedSize.ok THEN Fail ELSE
    LET requestedMarketSide == ReadBytes(requestedSize.rest, 1) IN IF ~requestedMarketSide.ok THEN Fail ELSE
    Ok([ exchangeId                   |-> exchangeId.value,
         rootSymbol                   |-> rootSymbol.value,
         expiryMonth                  |-> expiryMonth.value,
         filler1                      |-> filler1.value,
         strikePriceInstrument        |-> strikePriceInstrument.value,
         strikePriceFractionIndicator |-> strikePriceFractionIndicator.value,
         expiryYear                   |-> expiryYear.value,
         expiryDay                    |-> expiryDay.value,
         requestedSize                |-> requestedSize.value,
         requestedMarketSide          |-> requestedMarketSide.value ], requestedMarketSide.rest)

ZeroOptionRfqMessage ==
    [ exchangeId                   |-> [i \in 1 .. 1 |-> 0],
      rootSymbol                   |-> [i \in 1 .. 6 |-> 0],
      expiryMonth                  |-> [i \in 1 .. 1 |-> 0],
      filler1                      |-> [i \in 1 .. 1 |-> 0],
      strikePriceInstrument        |-> [i \in 1 .. 7 |-> 0],
      strikePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      expiryYear                   |-> [i \in 1 .. 2 |-> 0],
      expiryDay                    |-> [i \in 1 .. 2 |-> 0],
      requestedSize                |-> [i \in 1 .. 8 |-> 0],
      requestedMarketSide          |-> [i \in 1 .. 1 |-> 0] ]

(* Option Rfq Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionRfqMessage ==
    { ZeroOptionRfqMessage }
        \cup { [ZeroOptionRfqMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroOptionRfqMessage EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroOptionRfqMessage EXCEPT !.expiryMonth = one] : one \in Sample(1) }
        \cup { [ZeroOptionRfqMessage EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroOptionRfqMessage EXCEPT !.strikePriceInstrument = one] : one \in Sample(7) }
        \cup { [ZeroOptionRfqMessage EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionRfqMessage EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroOptionRfqMessage EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroOptionRfqMessage EXCEPT !.requestedSize = one] : one \in Sample(8) }
        \cup { [ZeroOptionRfqMessage EXCEPT !.requestedMarketSide = one] : one \in Sample(1) }

(***************************************************************************)
(* Future Options Rfq Message: 30 bytes                                    *)
(***************************************************************************)

FutureOptionsRfqMessage ==
    [ exchangeId                   : Sample(1),
      rootSymbol                   : Sample(6),
      contractMonthCode            : Sample(1),
      expiryYear                   : Sample(2),
      expiryDay                    : Sample(2),
      callPutCode                  : Sample(1),
      strikePriceInstrument        : Sample(7),
      strikePriceFractionIndicator : Sample(1),
      requestedSize                : Sample(8),
      requestedMarketSide          : Sample(1) ]

EncodeFutureOptionsRfqMessage(message) ==
    message.exchangeId
        \o message.rootSymbol
        \o message.contractMonthCode
        \o message.expiryYear
        \o message.expiryDay
        \o message.callPutCode
        \o message.strikePriceInstrument
        \o message.strikePriceFractionIndicator
        \o message.requestedSize
        \o message.requestedMarketSide

DecodeFutureOptionsRfqMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET rootSymbol == ReadBytes(exchangeId.rest, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET contractMonthCode == ReadBytes(rootSymbol.rest, 1) IN IF ~contractMonthCode.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(contractMonthCode.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET callPutCode == ReadBytes(expiryDay.rest, 1) IN IF ~callPutCode.ok THEN Fail ELSE
    LET strikePriceInstrument == ReadBytes(callPutCode.rest, 7) IN IF ~strikePriceInstrument.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePriceInstrument.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    LET requestedSize == ReadBytes(strikePriceFractionIndicator.rest, 8) IN IF ~requestedSize.ok THEN Fail ELSE
    LET requestedMarketSide == ReadBytes(requestedSize.rest, 1) IN IF ~requestedMarketSide.ok THEN Fail ELSE
    Ok([ exchangeId                   |-> exchangeId.value,
         rootSymbol                   |-> rootSymbol.value,
         contractMonthCode            |-> contractMonthCode.value,
         expiryYear                   |-> expiryYear.value,
         expiryDay                    |-> expiryDay.value,
         callPutCode                  |-> callPutCode.value,
         strikePriceInstrument        |-> strikePriceInstrument.value,
         strikePriceFractionIndicator |-> strikePriceFractionIndicator.value,
         requestedSize                |-> requestedSize.value,
         requestedMarketSide          |-> requestedMarketSide.value ], requestedMarketSide.rest)

ZeroFutureOptionsRfqMessage ==
    [ exchangeId                   |-> [i \in 1 .. 1 |-> 0],
      rootSymbol                   |-> [i \in 1 .. 6 |-> 0],
      contractMonthCode            |-> [i \in 1 .. 1 |-> 0],
      expiryYear                   |-> [i \in 1 .. 2 |-> 0],
      expiryDay                    |-> [i \in 1 .. 2 |-> 0],
      callPutCode                  |-> [i \in 1 .. 1 |-> 0],
      strikePriceInstrument        |-> [i \in 1 .. 7 |-> 0],
      strikePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      requestedSize                |-> [i \in 1 .. 8 |-> 0],
      requestedMarketSide          |-> [i \in 1 .. 1 |-> 0] ]

(* Future Options Rfq Message at zero, then each field in turn at the values it is checked at *)
CheckedFutureOptionsRfqMessage ==
    { ZeroFutureOptionsRfqMessage }
        \cup { [ZeroFutureOptionsRfqMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsRfqMessage EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionsRfqMessage EXCEPT !.contractMonthCode = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsRfqMessage EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionsRfqMessage EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionsRfqMessage EXCEPT !.callPutCode = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsRfqMessage EXCEPT !.strikePriceInstrument = one] : one \in Sample(7) }
        \cup { [ZeroFutureOptionsRfqMessage EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsRfqMessage EXCEPT !.requestedSize = one] : one \in Sample(8) }
        \cup { [ZeroFutureOptionsRfqMessage EXCEPT !.requestedMarketSide = one] : one \in Sample(1) }

(***************************************************************************)
(* Futures Rfq Message: 21 bytes                                           *)
(***************************************************************************)

FuturesRfqMessage ==
    [ exchangeId          : Sample(1),
      rootSymbol          : Sample(6),
      deliveryMonth       : Sample(1),
      deliveryYearFutures : Sample(2),
      deliveryDay         : Sample(2),
      requestedSize       : Sample(8),
      requestedMarketSide : Sample(1) ]

EncodeFuturesRfqMessage(message) ==
    message.exchangeId
        \o message.rootSymbol
        \o message.deliveryMonth
        \o message.deliveryYearFutures
        \o message.deliveryDay
        \o message.requestedSize
        \o message.requestedMarketSide

DecodeFuturesRfqMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET rootSymbol == ReadBytes(exchangeId.rest, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET deliveryMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~deliveryMonth.ok THEN Fail ELSE
    LET deliveryYearFutures == ReadBytes(deliveryMonth.rest, 2) IN IF ~deliveryYearFutures.ok THEN Fail ELSE
    LET deliveryDay == ReadBytes(deliveryYearFutures.rest, 2) IN IF ~deliveryDay.ok THEN Fail ELSE
    LET requestedSize == ReadBytes(deliveryDay.rest, 8) IN IF ~requestedSize.ok THEN Fail ELSE
    LET requestedMarketSide == ReadBytes(requestedSize.rest, 1) IN IF ~requestedMarketSide.ok THEN Fail ELSE
    Ok([ exchangeId          |-> exchangeId.value,
         rootSymbol          |-> rootSymbol.value,
         deliveryMonth       |-> deliveryMonth.value,
         deliveryYearFutures |-> deliveryYearFutures.value,
         deliveryDay         |-> deliveryDay.value,
         requestedSize       |-> requestedSize.value,
         requestedMarketSide |-> requestedMarketSide.value ], requestedMarketSide.rest)

ZeroFuturesRfqMessage ==
    [ exchangeId          |-> [i \in 1 .. 1 |-> 0],
      rootSymbol          |-> [i \in 1 .. 6 |-> 0],
      deliveryMonth       |-> [i \in 1 .. 1 |-> 0],
      deliveryYearFutures |-> [i \in 1 .. 2 |-> 0],
      deliveryDay         |-> [i \in 1 .. 2 |-> 0],
      requestedSize       |-> [i \in 1 .. 8 |-> 0],
      requestedMarketSide |-> [i \in 1 .. 1 |-> 0] ]

(* Futures Rfq Message at zero, then each field in turn at the values it is checked at *)
CheckedFuturesRfqMessage ==
    { ZeroFuturesRfqMessage }
        \cup { [ZeroFuturesRfqMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroFuturesRfqMessage EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroFuturesRfqMessage EXCEPT !.deliveryMonth = one] : one \in Sample(1) }
        \cup { [ZeroFuturesRfqMessage EXCEPT !.deliveryYearFutures = one] : one \in Sample(2) }
        \cup { [ZeroFuturesRfqMessage EXCEPT !.deliveryDay = one] : one \in Sample(2) }
        \cup { [ZeroFuturesRfqMessage EXCEPT !.requestedSize = one] : one \in Sample(8) }
        \cup { [ZeroFuturesRfqMessage EXCEPT !.requestedMarketSide = one] : one \in Sample(1) }

(***************************************************************************)
(* Strategy Rfq Message: 40 bytes                                          *)
(***************************************************************************)

StrategyRfqMessage ==
    [ exchangeId          : Sample(1),
      symbol              : Sample(30),
      requestedSize       : Sample(8),
      requestedMarketSide : Sample(1) ]

EncodeStrategyRfqMessage(message) ==
    message.exchangeId
        \o message.symbol
        \o message.requestedSize
        \o message.requestedMarketSide

DecodeStrategyRfqMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET symbol == ReadBytes(exchangeId.rest, 30) IN IF ~symbol.ok THEN Fail ELSE
    LET requestedSize == ReadBytes(symbol.rest, 8) IN IF ~requestedSize.ok THEN Fail ELSE
    LET requestedMarketSide == ReadBytes(requestedSize.rest, 1) IN IF ~requestedMarketSide.ok THEN Fail ELSE
    Ok([ exchangeId          |-> exchangeId.value,
         symbol              |-> symbol.value,
         requestedSize       |-> requestedSize.value,
         requestedMarketSide |-> requestedMarketSide.value ], requestedMarketSide.rest)

ZeroStrategyRfqMessage ==
    [ exchangeId          |-> [i \in 1 .. 1 |-> 0],
      symbol              |-> [i \in 1 .. 30 |-> 0],
      requestedSize       |-> [i \in 1 .. 8 |-> 0],
      requestedMarketSide |-> [i \in 1 .. 1 |-> 0] ]

(* Strategy Rfq Message at zero, then each field in turn at the values it is checked at *)
CheckedStrategyRfqMessage ==
    { ZeroStrategyRfqMessage }
        \cup { [ZeroStrategyRfqMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroStrategyRfqMessage EXCEPT !.symbol = one] : one \in Sample(30) }
        \cup { [ZeroStrategyRfqMessage EXCEPT !.requestedSize = one] : one \in Sample(8) }
        \cup { [ZeroStrategyRfqMessage EXCEPT !.requestedMarketSide = one] : one \in Sample(1) }

(***************************************************************************)
(* Swap Future Rfq Message: 29 bytes                                       *)
(***************************************************************************)

SwapFutureRfqMessage ==
    [ exchangeId                 : Sample(1),
      rootSymbol                 : Sample(6),
      expiryMonth                : Sample(1),
      expiryYear                 : Sample(2),
      expiryDay                  : Sample(2),
      tenor                      : Sample(2),
      fixedRate                  : Sample(5),
      fixedRateFractionIndicator : Sample(1),
      requestedSize              : Sample(8),
      requestedMarketSide        : Sample(1) ]

EncodeSwapFutureRfqMessage(message) ==
    message.exchangeId
        \o message.rootSymbol
        \o message.expiryMonth
        \o message.expiryYear
        \o message.expiryDay
        \o message.tenor
        \o message.fixedRate
        \o message.fixedRateFractionIndicator
        \o message.requestedSize
        \o message.requestedMarketSide

DecodeSwapFutureRfqMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET rootSymbol == ReadBytes(exchangeId.rest, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET expiryMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~expiryMonth.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(expiryMonth.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET tenor == ReadBytes(expiryDay.rest, 2) IN IF ~tenor.ok THEN Fail ELSE
    LET fixedRate == ReadBytes(tenor.rest, 5) IN IF ~fixedRate.ok THEN Fail ELSE
    LET fixedRateFractionIndicator == ReadBytes(fixedRate.rest, 1) IN IF ~fixedRateFractionIndicator.ok THEN Fail ELSE
    LET requestedSize == ReadBytes(fixedRateFractionIndicator.rest, 8) IN IF ~requestedSize.ok THEN Fail ELSE
    LET requestedMarketSide == ReadBytes(requestedSize.rest, 1) IN IF ~requestedMarketSide.ok THEN Fail ELSE
    Ok([ exchangeId                 |-> exchangeId.value,
         rootSymbol                 |-> rootSymbol.value,
         expiryMonth                |-> expiryMonth.value,
         expiryYear                 |-> expiryYear.value,
         expiryDay                  |-> expiryDay.value,
         tenor                      |-> tenor.value,
         fixedRate                  |-> fixedRate.value,
         fixedRateFractionIndicator |-> fixedRateFractionIndicator.value,
         requestedSize              |-> requestedSize.value,
         requestedMarketSide        |-> requestedMarketSide.value ], requestedMarketSide.rest)

ZeroSwapFutureRfqMessage ==
    [ exchangeId                 |-> [i \in 1 .. 1 |-> 0],
      rootSymbol                 |-> [i \in 1 .. 6 |-> 0],
      expiryMonth                |-> [i \in 1 .. 1 |-> 0],
      expiryYear                 |-> [i \in 1 .. 2 |-> 0],
      expiryDay                  |-> [i \in 1 .. 2 |-> 0],
      tenor                      |-> [i \in 1 .. 2 |-> 0],
      fixedRate                  |-> [i \in 1 .. 5 |-> 0],
      fixedRateFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      requestedSize              |-> [i \in 1 .. 8 |-> 0],
      requestedMarketSide        |-> [i \in 1 .. 1 |-> 0] ]

(* Swap Future Rfq Message at zero, then each field in turn at the values it is checked at *)
CheckedSwapFutureRfqMessage ==
    { ZeroSwapFutureRfqMessage }
        \cup { [ZeroSwapFutureRfqMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureRfqMessage EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroSwapFutureRfqMessage EXCEPT !.expiryMonth = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureRfqMessage EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroSwapFutureRfqMessage EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroSwapFutureRfqMessage EXCEPT !.tenor = one] : one \in Sample(2) }
        \cup { [ZeroSwapFutureRfqMessage EXCEPT !.fixedRate = one] : one \in Sample(5) }
        \cup { [ZeroSwapFutureRfqMessage EXCEPT !.fixedRateFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureRfqMessage EXCEPT !.requestedSize = one] : one \in Sample(8) }
        \cup { [ZeroSwapFutureRfqMessage EXCEPT !.requestedMarketSide = one] : one \in Sample(1) }

(***************************************************************************)
(* Instrument Schedule Notice Option Message: 28 bytes                     *)
(***************************************************************************)

InstrumentScheduleNoticeOptionMessage ==
    [ exchangeId                   : Sample(1),
      rootSymbol                   : Sample(6),
      expiryMonth                  : Sample(1),
      filler1                      : Sample(1),
      strikePriceScheduleNotice    : Sample(7),
      strikePriceFractionIndicator : Sample(1),
      expiryYear                   : Sample(2),
      expiryDay                    : Sample(2),
      seriesStatus                 : Sample(1),
      scheduledStatusChangeTime    : Sample(6) ]

EncodeInstrumentScheduleNoticeOptionMessage(message) ==
    message.exchangeId
        \o message.rootSymbol
        \o message.expiryMonth
        \o message.filler1
        \o message.strikePriceScheduleNotice
        \o message.strikePriceFractionIndicator
        \o message.expiryYear
        \o message.expiryDay
        \o message.seriesStatus
        \o message.scheduledStatusChangeTime

DecodeInstrumentScheduleNoticeOptionMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET rootSymbol == ReadBytes(exchangeId.rest, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET expiryMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~expiryMonth.ok THEN Fail ELSE
    LET filler1 == ReadBytes(expiryMonth.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET strikePriceScheduleNotice == ReadBytes(filler1.rest, 7) IN IF ~strikePriceScheduleNotice.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePriceScheduleNotice.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(strikePriceFractionIndicator.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET seriesStatus == ReadBytes(expiryDay.rest, 1) IN IF ~seriesStatus.ok THEN Fail ELSE
    LET scheduledStatusChangeTime == ReadBytes(seriesStatus.rest, 6) IN IF ~scheduledStatusChangeTime.ok THEN Fail ELSE
    Ok([ exchangeId                   |-> exchangeId.value,
         rootSymbol                   |-> rootSymbol.value,
         expiryMonth                  |-> expiryMonth.value,
         filler1                      |-> filler1.value,
         strikePriceScheduleNotice    |-> strikePriceScheduleNotice.value,
         strikePriceFractionIndicator |-> strikePriceFractionIndicator.value,
         expiryYear                   |-> expiryYear.value,
         expiryDay                    |-> expiryDay.value,
         seriesStatus                 |-> seriesStatus.value,
         scheduledStatusChangeTime    |-> scheduledStatusChangeTime.value ], scheduledStatusChangeTime.rest)

ZeroInstrumentScheduleNoticeOptionMessage ==
    [ exchangeId                   |-> [i \in 1 .. 1 |-> 0],
      rootSymbol                   |-> [i \in 1 .. 6 |-> 0],
      expiryMonth                  |-> [i \in 1 .. 1 |-> 0],
      filler1                      |-> [i \in 1 .. 1 |-> 0],
      strikePriceScheduleNotice    |-> [i \in 1 .. 7 |-> 0],
      strikePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      expiryYear                   |-> [i \in 1 .. 2 |-> 0],
      expiryDay                    |-> [i \in 1 .. 2 |-> 0],
      seriesStatus                 |-> [i \in 1 .. 1 |-> 0],
      scheduledStatusChangeTime    |-> [i \in 1 .. 6 |-> 0] ]

(* Instrument Schedule Notice Option Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentScheduleNoticeOptionMessage ==
    { ZeroInstrumentScheduleNoticeOptionMessage }
        \cup { [ZeroInstrumentScheduleNoticeOptionMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentScheduleNoticeOptionMessage EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroInstrumentScheduleNoticeOptionMessage EXCEPT !.expiryMonth = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentScheduleNoticeOptionMessage EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentScheduleNoticeOptionMessage EXCEPT !.strikePriceScheduleNotice = one] : one \in Sample(7) }
        \cup { [ZeroInstrumentScheduleNoticeOptionMessage EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentScheduleNoticeOptionMessage EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentScheduleNoticeOptionMessage EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentScheduleNoticeOptionMessage EXCEPT !.seriesStatus = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentScheduleNoticeOptionMessage EXCEPT !.scheduledStatusChangeTime = one] : one \in Sample(6) }

(***************************************************************************)
(* Instrument Schedule Notice Futures Option Message: 28 bytes             *)
(***************************************************************************)

InstrumentScheduleNoticeFuturesOptionMessage ==
    [ exchangeId                   : Sample(1),
      rootSymbol                   : Sample(6),
      contractMonthCode            : Sample(1),
      expiryYear                   : Sample(2),
      expiryDay                    : Sample(2),
      callPutCode                  : Sample(1),
      strikePriceInstrument        : Sample(7),
      strikePriceFractionIndicator : Sample(1),
      seriesStatus                 : Sample(1),
      scheduledStatusChangeTime    : Sample(6) ]

EncodeInstrumentScheduleNoticeFuturesOptionMessage(message) ==
    message.exchangeId
        \o message.rootSymbol
        \o message.contractMonthCode
        \o message.expiryYear
        \o message.expiryDay
        \o message.callPutCode
        \o message.strikePriceInstrument
        \o message.strikePriceFractionIndicator
        \o message.seriesStatus
        \o message.scheduledStatusChangeTime

DecodeInstrumentScheduleNoticeFuturesOptionMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET rootSymbol == ReadBytes(exchangeId.rest, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET contractMonthCode == ReadBytes(rootSymbol.rest, 1) IN IF ~contractMonthCode.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(contractMonthCode.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET callPutCode == ReadBytes(expiryDay.rest, 1) IN IF ~callPutCode.ok THEN Fail ELSE
    LET strikePriceInstrument == ReadBytes(callPutCode.rest, 7) IN IF ~strikePriceInstrument.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePriceInstrument.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    LET seriesStatus == ReadBytes(strikePriceFractionIndicator.rest, 1) IN IF ~seriesStatus.ok THEN Fail ELSE
    LET scheduledStatusChangeTime == ReadBytes(seriesStatus.rest, 6) IN IF ~scheduledStatusChangeTime.ok THEN Fail ELSE
    Ok([ exchangeId                   |-> exchangeId.value,
         rootSymbol                   |-> rootSymbol.value,
         contractMonthCode            |-> contractMonthCode.value,
         expiryYear                   |-> expiryYear.value,
         expiryDay                    |-> expiryDay.value,
         callPutCode                  |-> callPutCode.value,
         strikePriceInstrument        |-> strikePriceInstrument.value,
         strikePriceFractionIndicator |-> strikePriceFractionIndicator.value,
         seriesStatus                 |-> seriesStatus.value,
         scheduledStatusChangeTime    |-> scheduledStatusChangeTime.value ], scheduledStatusChangeTime.rest)

ZeroInstrumentScheduleNoticeFuturesOptionMessage ==
    [ exchangeId                   |-> [i \in 1 .. 1 |-> 0],
      rootSymbol                   |-> [i \in 1 .. 6 |-> 0],
      contractMonthCode            |-> [i \in 1 .. 1 |-> 0],
      expiryYear                   |-> [i \in 1 .. 2 |-> 0],
      expiryDay                    |-> [i \in 1 .. 2 |-> 0],
      callPutCode                  |-> [i \in 1 .. 1 |-> 0],
      strikePriceInstrument        |-> [i \in 1 .. 7 |-> 0],
      strikePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      seriesStatus                 |-> [i \in 1 .. 1 |-> 0],
      scheduledStatusChangeTime    |-> [i \in 1 .. 6 |-> 0] ]

(* Instrument Schedule Notice Futures Option Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentScheduleNoticeFuturesOptionMessage ==
    { ZeroInstrumentScheduleNoticeFuturesOptionMessage }
        \cup { [ZeroInstrumentScheduleNoticeFuturesOptionMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentScheduleNoticeFuturesOptionMessage EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroInstrumentScheduleNoticeFuturesOptionMessage EXCEPT !.contractMonthCode = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentScheduleNoticeFuturesOptionMessage EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentScheduleNoticeFuturesOptionMessage EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentScheduleNoticeFuturesOptionMessage EXCEPT !.callPutCode = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentScheduleNoticeFuturesOptionMessage EXCEPT !.strikePriceInstrument = one] : one \in Sample(7) }
        \cup { [ZeroInstrumentScheduleNoticeFuturesOptionMessage EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentScheduleNoticeFuturesOptionMessage EXCEPT !.seriesStatus = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentScheduleNoticeFuturesOptionMessage EXCEPT !.scheduledStatusChangeTime = one] : one \in Sample(6) }

(***************************************************************************)
(* Instrument Schedule Notice Future Message: 19 bytes                     *)
(***************************************************************************)

InstrumentScheduleNoticeFutureMessage ==
    [ exchangeId                : Sample(1),
      rootSymbol                : Sample(6),
      deliveryMonth             : Sample(1),
      deliveryYearFutures       : Sample(2),
      deliveryDay               : Sample(2),
      seriesStatus              : Sample(1),
      scheduledStatusChangeTime : Sample(6) ]

EncodeInstrumentScheduleNoticeFutureMessage(message) ==
    message.exchangeId
        \o message.rootSymbol
        \o message.deliveryMonth
        \o message.deliveryYearFutures
        \o message.deliveryDay
        \o message.seriesStatus
        \o message.scheduledStatusChangeTime

DecodeInstrumentScheduleNoticeFutureMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET rootSymbol == ReadBytes(exchangeId.rest, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET deliveryMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~deliveryMonth.ok THEN Fail ELSE
    LET deliveryYearFutures == ReadBytes(deliveryMonth.rest, 2) IN IF ~deliveryYearFutures.ok THEN Fail ELSE
    LET deliveryDay == ReadBytes(deliveryYearFutures.rest, 2) IN IF ~deliveryDay.ok THEN Fail ELSE
    LET seriesStatus == ReadBytes(deliveryDay.rest, 1) IN IF ~seriesStatus.ok THEN Fail ELSE
    LET scheduledStatusChangeTime == ReadBytes(seriesStatus.rest, 6) IN IF ~scheduledStatusChangeTime.ok THEN Fail ELSE
    Ok([ exchangeId                |-> exchangeId.value,
         rootSymbol                |-> rootSymbol.value,
         deliveryMonth             |-> deliveryMonth.value,
         deliveryYearFutures       |-> deliveryYearFutures.value,
         deliveryDay               |-> deliveryDay.value,
         seriesStatus              |-> seriesStatus.value,
         scheduledStatusChangeTime |-> scheduledStatusChangeTime.value ], scheduledStatusChangeTime.rest)

ZeroInstrumentScheduleNoticeFutureMessage ==
    [ exchangeId                |-> [i \in 1 .. 1 |-> 0],
      rootSymbol                |-> [i \in 1 .. 6 |-> 0],
      deliveryMonth             |-> [i \in 1 .. 1 |-> 0],
      deliveryYearFutures       |-> [i \in 1 .. 2 |-> 0],
      deliveryDay               |-> [i \in 1 .. 2 |-> 0],
      seriesStatus              |-> [i \in 1 .. 1 |-> 0],
      scheduledStatusChangeTime |-> [i \in 1 .. 6 |-> 0] ]

(* Instrument Schedule Notice Future Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentScheduleNoticeFutureMessage ==
    { ZeroInstrumentScheduleNoticeFutureMessage }
        \cup { [ZeroInstrumentScheduleNoticeFutureMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentScheduleNoticeFutureMessage EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroInstrumentScheduleNoticeFutureMessage EXCEPT !.deliveryMonth = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentScheduleNoticeFutureMessage EXCEPT !.deliveryYearFutures = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentScheduleNoticeFutureMessage EXCEPT !.deliveryDay = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentScheduleNoticeFutureMessage EXCEPT !.seriesStatus = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentScheduleNoticeFutureMessage EXCEPT !.scheduledStatusChangeTime = one] : one \in Sample(6) }

(***************************************************************************)
(* Instrument Schedule Notice Strategy Message: 38 bytes                   *)
(***************************************************************************)

InstrumentScheduleNoticeStrategyMessage ==
    [ exchangeId                : Sample(1),
      strategySymbol            : Sample(30),
      seriesStatus              : Sample(1),
      scheduledStatusChangeTime : Sample(6) ]

EncodeInstrumentScheduleNoticeStrategyMessage(message) ==
    message.exchangeId
        \o message.strategySymbol
        \o message.seriesStatus
        \o message.scheduledStatusChangeTime

DecodeInstrumentScheduleNoticeStrategyMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET strategySymbol == ReadBytes(exchangeId.rest, 30) IN IF ~strategySymbol.ok THEN Fail ELSE
    LET seriesStatus == ReadBytes(strategySymbol.rest, 1) IN IF ~seriesStatus.ok THEN Fail ELSE
    LET scheduledStatusChangeTime == ReadBytes(seriesStatus.rest, 6) IN IF ~scheduledStatusChangeTime.ok THEN Fail ELSE
    Ok([ exchangeId                |-> exchangeId.value,
         strategySymbol            |-> strategySymbol.value,
         seriesStatus              |-> seriesStatus.value,
         scheduledStatusChangeTime |-> scheduledStatusChangeTime.value ], scheduledStatusChangeTime.rest)

ZeroInstrumentScheduleNoticeStrategyMessage ==
    [ exchangeId                |-> [i \in 1 .. 1 |-> 0],
      strategySymbol            |-> [i \in 1 .. 30 |-> 0],
      seriesStatus              |-> [i \in 1 .. 1 |-> 0],
      scheduledStatusChangeTime |-> [i \in 1 .. 6 |-> 0] ]

(* Instrument Schedule Notice Strategy Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentScheduleNoticeStrategyMessage ==
    { ZeroInstrumentScheduleNoticeStrategyMessage }
        \cup { [ZeroInstrumentScheduleNoticeStrategyMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentScheduleNoticeStrategyMessage EXCEPT !.strategySymbol = one] : one \in Sample(30) }
        \cup { [ZeroInstrumentScheduleNoticeStrategyMessage EXCEPT !.seriesStatus = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentScheduleNoticeStrategyMessage EXCEPT !.scheduledStatusChangeTime = one] : one \in Sample(6) }

(***************************************************************************)
(* Instrument Schedule Notice Swap Future Message: 27 bytes                *)
(***************************************************************************)

InstrumentScheduleNoticeSwapFutureMessage ==
    [ exchangeId                 : Sample(1),
      rootSymbol                 : Sample(6),
      expiryMonth                : Sample(1),
      expiryYear                 : Sample(2),
      expiryDay                  : Sample(2),
      tenor                      : Sample(2),
      fixedRate                  : Sample(5),
      fixedRateFractionIndicator : Sample(1),
      seriesStatus               : Sample(1),
      scheduledStatusChangeTime  : Sample(6) ]

EncodeInstrumentScheduleNoticeSwapFutureMessage(message) ==
    message.exchangeId
        \o message.rootSymbol
        \o message.expiryMonth
        \o message.expiryYear
        \o message.expiryDay
        \o message.tenor
        \o message.fixedRate
        \o message.fixedRateFractionIndicator
        \o message.seriesStatus
        \o message.scheduledStatusChangeTime

DecodeInstrumentScheduleNoticeSwapFutureMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET rootSymbol == ReadBytes(exchangeId.rest, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET expiryMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~expiryMonth.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(expiryMonth.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET tenor == ReadBytes(expiryDay.rest, 2) IN IF ~tenor.ok THEN Fail ELSE
    LET fixedRate == ReadBytes(tenor.rest, 5) IN IF ~fixedRate.ok THEN Fail ELSE
    LET fixedRateFractionIndicator == ReadBytes(fixedRate.rest, 1) IN IF ~fixedRateFractionIndicator.ok THEN Fail ELSE
    LET seriesStatus == ReadBytes(fixedRateFractionIndicator.rest, 1) IN IF ~seriesStatus.ok THEN Fail ELSE
    LET scheduledStatusChangeTime == ReadBytes(seriesStatus.rest, 6) IN IF ~scheduledStatusChangeTime.ok THEN Fail ELSE
    Ok([ exchangeId                 |-> exchangeId.value,
         rootSymbol                 |-> rootSymbol.value,
         expiryMonth                |-> expiryMonth.value,
         expiryYear                 |-> expiryYear.value,
         expiryDay                  |-> expiryDay.value,
         tenor                      |-> tenor.value,
         fixedRate                  |-> fixedRate.value,
         fixedRateFractionIndicator |-> fixedRateFractionIndicator.value,
         seriesStatus               |-> seriesStatus.value,
         scheduledStatusChangeTime  |-> scheduledStatusChangeTime.value ], scheduledStatusChangeTime.rest)

ZeroInstrumentScheduleNoticeSwapFutureMessage ==
    [ exchangeId                 |-> [i \in 1 .. 1 |-> 0],
      rootSymbol                 |-> [i \in 1 .. 6 |-> 0],
      expiryMonth                |-> [i \in 1 .. 1 |-> 0],
      expiryYear                 |-> [i \in 1 .. 2 |-> 0],
      expiryDay                  |-> [i \in 1 .. 2 |-> 0],
      tenor                      |-> [i \in 1 .. 2 |-> 0],
      fixedRate                  |-> [i \in 1 .. 5 |-> 0],
      fixedRateFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      seriesStatus               |-> [i \in 1 .. 1 |-> 0],
      scheduledStatusChangeTime  |-> [i \in 1 .. 6 |-> 0] ]

(* Instrument Schedule Notice Swap Future Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentScheduleNoticeSwapFutureMessage ==
    { ZeroInstrumentScheduleNoticeSwapFutureMessage }
        \cup { [ZeroInstrumentScheduleNoticeSwapFutureMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentScheduleNoticeSwapFutureMessage EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroInstrumentScheduleNoticeSwapFutureMessage EXCEPT !.expiryMonth = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentScheduleNoticeSwapFutureMessage EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentScheduleNoticeSwapFutureMessage EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentScheduleNoticeSwapFutureMessage EXCEPT !.tenor = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentScheduleNoticeSwapFutureMessage EXCEPT !.fixedRate = one] : one \in Sample(5) }
        \cup { [ZeroInstrumentScheduleNoticeSwapFutureMessage EXCEPT !.fixedRateFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentScheduleNoticeSwapFutureMessage EXCEPT !.seriesStatus = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentScheduleNoticeSwapFutureMessage EXCEPT !.scheduledStatusChangeTime = one] : one \in Sample(6) }

(***************************************************************************)
(* Option Quote Message: 47 bytes                                          *)
(***************************************************************************)

OptionQuoteMessage ==
    [ exchangeId                   : Sample(1),
      rootSymbol                   : Sample(6),
      expiryMonth                  : Sample(1),
      filler1                      : Sample(1),
      strikePriceInstrument        : Sample(7),
      strikePriceFractionIndicator : Sample(1),
      expiryYear                   : Sample(2),
      expiryDay                    : Sample(2),
      bidPriceQuote                : Sample(6),
      bidPriceFractionIndicator    : Sample(1),
      bidSize                      : Sample(5),
      askPriceQuote                : Sample(6),
      askPriceFractionIndicator    : Sample(1),
      askSize                      : Sample(5),
      secondFiller1                : Sample(1),
      instrumentStatusMarker       : Sample(1) ]

EncodeOptionQuoteMessage(message) ==
    message.exchangeId
        \o message.rootSymbol
        \o message.expiryMonth
        \o message.filler1
        \o message.strikePriceInstrument
        \o message.strikePriceFractionIndicator
        \o message.expiryYear
        \o message.expiryDay
        \o message.bidPriceQuote
        \o message.bidPriceFractionIndicator
        \o message.bidSize
        \o message.askPriceQuote
        \o message.askPriceFractionIndicator
        \o message.askSize
        \o message.secondFiller1
        \o message.instrumentStatusMarker

DecodeOptionQuoteMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET rootSymbol == ReadBytes(exchangeId.rest, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET expiryMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~expiryMonth.ok THEN Fail ELSE
    LET filler1 == ReadBytes(expiryMonth.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET strikePriceInstrument == ReadBytes(filler1.rest, 7) IN IF ~strikePriceInstrument.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePriceInstrument.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(strikePriceFractionIndicator.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET bidPriceQuote == ReadBytes(expiryDay.rest, 6) IN IF ~bidPriceQuote.ok THEN Fail ELSE
    LET bidPriceFractionIndicator == ReadBytes(bidPriceQuote.rest, 1) IN IF ~bidPriceFractionIndicator.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPriceFractionIndicator.rest, 5) IN IF ~bidSize.ok THEN Fail ELSE
    LET askPriceQuote == ReadBytes(bidSize.rest, 6) IN IF ~askPriceQuote.ok THEN Fail ELSE
    LET askPriceFractionIndicator == ReadBytes(askPriceQuote.rest, 1) IN IF ~askPriceFractionIndicator.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPriceFractionIndicator.rest, 5) IN IF ~askSize.ok THEN Fail ELSE
    LET secondFiller1 == ReadBytes(askSize.rest, 1) IN IF ~secondFiller1.ok THEN Fail ELSE
    LET instrumentStatusMarker == ReadBytes(secondFiller1.rest, 1) IN IF ~instrumentStatusMarker.ok THEN Fail ELSE
    Ok([ exchangeId                   |-> exchangeId.value,
         rootSymbol                   |-> rootSymbol.value,
         expiryMonth                  |-> expiryMonth.value,
         filler1                      |-> filler1.value,
         strikePriceInstrument        |-> strikePriceInstrument.value,
         strikePriceFractionIndicator |-> strikePriceFractionIndicator.value,
         expiryYear                   |-> expiryYear.value,
         expiryDay                    |-> expiryDay.value,
         bidPriceQuote                |-> bidPriceQuote.value,
         bidPriceFractionIndicator    |-> bidPriceFractionIndicator.value,
         bidSize                      |-> bidSize.value,
         askPriceQuote                |-> askPriceQuote.value,
         askPriceFractionIndicator    |-> askPriceFractionIndicator.value,
         askSize                      |-> askSize.value,
         secondFiller1                |-> secondFiller1.value,
         instrumentStatusMarker       |-> instrumentStatusMarker.value ], instrumentStatusMarker.rest)

ZeroOptionQuoteMessage ==
    [ exchangeId                   |-> [i \in 1 .. 1 |-> 0],
      rootSymbol                   |-> [i \in 1 .. 6 |-> 0],
      expiryMonth                  |-> [i \in 1 .. 1 |-> 0],
      filler1                      |-> [i \in 1 .. 1 |-> 0],
      strikePriceInstrument        |-> [i \in 1 .. 7 |-> 0],
      strikePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      expiryYear                   |-> [i \in 1 .. 2 |-> 0],
      expiryDay                    |-> [i \in 1 .. 2 |-> 0],
      bidPriceQuote                |-> [i \in 1 .. 6 |-> 0],
      bidPriceFractionIndicator    |-> [i \in 1 .. 1 |-> 0],
      bidSize                      |-> [i \in 1 .. 5 |-> 0],
      askPriceQuote                |-> [i \in 1 .. 6 |-> 0],
      askPriceFractionIndicator    |-> [i \in 1 .. 1 |-> 0],
      askSize                      |-> [i \in 1 .. 5 |-> 0],
      secondFiller1                |-> [i \in 1 .. 1 |-> 0],
      instrumentStatusMarker       |-> [i \in 1 .. 1 |-> 0] ]

(* Option Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionQuoteMessage ==
    { ZeroOptionQuoteMessage }
        \cup { [ZeroOptionQuoteMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroOptionQuoteMessage EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroOptionQuoteMessage EXCEPT !.expiryMonth = one] : one \in Sample(1) }
        \cup { [ZeroOptionQuoteMessage EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroOptionQuoteMessage EXCEPT !.strikePriceInstrument = one] : one \in Sample(7) }
        \cup { [ZeroOptionQuoteMessage EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionQuoteMessage EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroOptionQuoteMessage EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroOptionQuoteMessage EXCEPT !.bidPriceQuote = one] : one \in Sample(6) }
        \cup { [ZeroOptionQuoteMessage EXCEPT !.bidPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionQuoteMessage EXCEPT !.bidSize = one] : one \in Sample(5) }
        \cup { [ZeroOptionQuoteMessage EXCEPT !.askPriceQuote = one] : one \in Sample(6) }
        \cup { [ZeroOptionQuoteMessage EXCEPT !.askPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionQuoteMessage EXCEPT !.askSize = one] : one \in Sample(5) }
        \cup { [ZeroOptionQuoteMessage EXCEPT !.secondFiller1 = one] : one \in Sample(1) }
        \cup { [ZeroOptionQuoteMessage EXCEPT !.instrumentStatusMarker = one] : one \in Sample(1) }

(***************************************************************************)
(* Future Options Quote Message: 47 bytes                                  *)
(***************************************************************************)

FutureOptionsQuoteMessage ==
    [ exchangeId                   : Sample(1),
      rootSymbol                   : Sample(6),
      contractMonthCode            : Sample(1),
      expiryYear                   : Sample(2),
      expiryDay                    : Sample(2),
      callPutCode                  : Sample(1),
      strikePriceInstrument        : Sample(7),
      strikePriceFractionIndicator : Sample(1),
      bidPriceQuote                : Sample(6),
      bidPriceFractionIndicator    : Sample(1),
      bidSize                      : Sample(5),
      askPriceQuote                : Sample(6),
      askPriceFractionIndicator    : Sample(1),
      askSize                      : Sample(5),
      instrumentStatusMarker       : Sample(1),
      filler1                      : Sample(1) ]

EncodeFutureOptionsQuoteMessage(message) ==
    message.exchangeId
        \o message.rootSymbol
        \o message.contractMonthCode
        \o message.expiryYear
        \o message.expiryDay
        \o message.callPutCode
        \o message.strikePriceInstrument
        \o message.strikePriceFractionIndicator
        \o message.bidPriceQuote
        \o message.bidPriceFractionIndicator
        \o message.bidSize
        \o message.askPriceQuote
        \o message.askPriceFractionIndicator
        \o message.askSize
        \o message.instrumentStatusMarker
        \o message.filler1

DecodeFutureOptionsQuoteMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET rootSymbol == ReadBytes(exchangeId.rest, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET contractMonthCode == ReadBytes(rootSymbol.rest, 1) IN IF ~contractMonthCode.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(contractMonthCode.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET callPutCode == ReadBytes(expiryDay.rest, 1) IN IF ~callPutCode.ok THEN Fail ELSE
    LET strikePriceInstrument == ReadBytes(callPutCode.rest, 7) IN IF ~strikePriceInstrument.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePriceInstrument.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    LET bidPriceQuote == ReadBytes(strikePriceFractionIndicator.rest, 6) IN IF ~bidPriceQuote.ok THEN Fail ELSE
    LET bidPriceFractionIndicator == ReadBytes(bidPriceQuote.rest, 1) IN IF ~bidPriceFractionIndicator.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPriceFractionIndicator.rest, 5) IN IF ~bidSize.ok THEN Fail ELSE
    LET askPriceQuote == ReadBytes(bidSize.rest, 6) IN IF ~askPriceQuote.ok THEN Fail ELSE
    LET askPriceFractionIndicator == ReadBytes(askPriceQuote.rest, 1) IN IF ~askPriceFractionIndicator.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPriceFractionIndicator.rest, 5) IN IF ~askSize.ok THEN Fail ELSE
    LET instrumentStatusMarker == ReadBytes(askSize.rest, 1) IN IF ~instrumentStatusMarker.ok THEN Fail ELSE
    LET filler1 == ReadBytes(instrumentStatusMarker.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    Ok([ exchangeId                   |-> exchangeId.value,
         rootSymbol                   |-> rootSymbol.value,
         contractMonthCode            |-> contractMonthCode.value,
         expiryYear                   |-> expiryYear.value,
         expiryDay                    |-> expiryDay.value,
         callPutCode                  |-> callPutCode.value,
         strikePriceInstrument        |-> strikePriceInstrument.value,
         strikePriceFractionIndicator |-> strikePriceFractionIndicator.value,
         bidPriceQuote                |-> bidPriceQuote.value,
         bidPriceFractionIndicator    |-> bidPriceFractionIndicator.value,
         bidSize                      |-> bidSize.value,
         askPriceQuote                |-> askPriceQuote.value,
         askPriceFractionIndicator    |-> askPriceFractionIndicator.value,
         askSize                      |-> askSize.value,
         instrumentStatusMarker       |-> instrumentStatusMarker.value,
         filler1                      |-> filler1.value ], filler1.rest)

ZeroFutureOptionsQuoteMessage ==
    [ exchangeId                   |-> [i \in 1 .. 1 |-> 0],
      rootSymbol                   |-> [i \in 1 .. 6 |-> 0],
      contractMonthCode            |-> [i \in 1 .. 1 |-> 0],
      expiryYear                   |-> [i \in 1 .. 2 |-> 0],
      expiryDay                    |-> [i \in 1 .. 2 |-> 0],
      callPutCode                  |-> [i \in 1 .. 1 |-> 0],
      strikePriceInstrument        |-> [i \in 1 .. 7 |-> 0],
      strikePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      bidPriceQuote                |-> [i \in 1 .. 6 |-> 0],
      bidPriceFractionIndicator    |-> [i \in 1 .. 1 |-> 0],
      bidSize                      |-> [i \in 1 .. 5 |-> 0],
      askPriceQuote                |-> [i \in 1 .. 6 |-> 0],
      askPriceFractionIndicator    |-> [i \in 1 .. 1 |-> 0],
      askSize                      |-> [i \in 1 .. 5 |-> 0],
      instrumentStatusMarker       |-> [i \in 1 .. 1 |-> 0],
      filler1                      |-> [i \in 1 .. 1 |-> 0] ]

(* Future Options Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedFutureOptionsQuoteMessage ==
    { ZeroFutureOptionsQuoteMessage }
        \cup { [ZeroFutureOptionsQuoteMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsQuoteMessage EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionsQuoteMessage EXCEPT !.contractMonthCode = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsQuoteMessage EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionsQuoteMessage EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionsQuoteMessage EXCEPT !.callPutCode = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsQuoteMessage EXCEPT !.strikePriceInstrument = one] : one \in Sample(7) }
        \cup { [ZeroFutureOptionsQuoteMessage EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsQuoteMessage EXCEPT !.bidPriceQuote = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionsQuoteMessage EXCEPT !.bidPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsQuoteMessage EXCEPT !.bidSize = one] : one \in Sample(5) }
        \cup { [ZeroFutureOptionsQuoteMessage EXCEPT !.askPriceQuote = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionsQuoteMessage EXCEPT !.askPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsQuoteMessage EXCEPT !.askSize = one] : one \in Sample(5) }
        \cup { [ZeroFutureOptionsQuoteMessage EXCEPT !.instrumentStatusMarker = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsQuoteMessage EXCEPT !.filler1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Futures Quote Message: 37 bytes                                         *)
(***************************************************************************)

FuturesQuoteMessage ==
    [ exchangeId                : Sample(1),
      rootSymbol                : Sample(6),
      deliveryMonth             : Sample(1),
      deliveryYearFutures       : Sample(2),
      deliveryDay               : Sample(2),
      bidPriceQuote             : Sample(6),
      bidPriceFractionIndicator : Sample(1),
      bidSize                   : Sample(5),
      askPriceQuote             : Sample(6),
      askPriceFractionIndicator : Sample(1),
      askSize                   : Sample(5),
      instrumentStatusMarker    : Sample(1) ]

EncodeFuturesQuoteMessage(message) ==
    message.exchangeId
        \o message.rootSymbol
        \o message.deliveryMonth
        \o message.deliveryYearFutures
        \o message.deliveryDay
        \o message.bidPriceQuote
        \o message.bidPriceFractionIndicator
        \o message.bidSize
        \o message.askPriceQuote
        \o message.askPriceFractionIndicator
        \o message.askSize
        \o message.instrumentStatusMarker

DecodeFuturesQuoteMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET rootSymbol == ReadBytes(exchangeId.rest, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET deliveryMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~deliveryMonth.ok THEN Fail ELSE
    LET deliveryYearFutures == ReadBytes(deliveryMonth.rest, 2) IN IF ~deliveryYearFutures.ok THEN Fail ELSE
    LET deliveryDay == ReadBytes(deliveryYearFutures.rest, 2) IN IF ~deliveryDay.ok THEN Fail ELSE
    LET bidPriceQuote == ReadBytes(deliveryDay.rest, 6) IN IF ~bidPriceQuote.ok THEN Fail ELSE
    LET bidPriceFractionIndicator == ReadBytes(bidPriceQuote.rest, 1) IN IF ~bidPriceFractionIndicator.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPriceFractionIndicator.rest, 5) IN IF ~bidSize.ok THEN Fail ELSE
    LET askPriceQuote == ReadBytes(bidSize.rest, 6) IN IF ~askPriceQuote.ok THEN Fail ELSE
    LET askPriceFractionIndicator == ReadBytes(askPriceQuote.rest, 1) IN IF ~askPriceFractionIndicator.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPriceFractionIndicator.rest, 5) IN IF ~askSize.ok THEN Fail ELSE
    LET instrumentStatusMarker == ReadBytes(askSize.rest, 1) IN IF ~instrumentStatusMarker.ok THEN Fail ELSE
    Ok([ exchangeId                |-> exchangeId.value,
         rootSymbol                |-> rootSymbol.value,
         deliveryMonth             |-> deliveryMonth.value,
         deliveryYearFutures       |-> deliveryYearFutures.value,
         deliveryDay               |-> deliveryDay.value,
         bidPriceQuote             |-> bidPriceQuote.value,
         bidPriceFractionIndicator |-> bidPriceFractionIndicator.value,
         bidSize                   |-> bidSize.value,
         askPriceQuote             |-> askPriceQuote.value,
         askPriceFractionIndicator |-> askPriceFractionIndicator.value,
         askSize                   |-> askSize.value,
         instrumentStatusMarker    |-> instrumentStatusMarker.value ], instrumentStatusMarker.rest)

ZeroFuturesQuoteMessage ==
    [ exchangeId                |-> [i \in 1 .. 1 |-> 0],
      rootSymbol                |-> [i \in 1 .. 6 |-> 0],
      deliveryMonth             |-> [i \in 1 .. 1 |-> 0],
      deliveryYearFutures       |-> [i \in 1 .. 2 |-> 0],
      deliveryDay               |-> [i \in 1 .. 2 |-> 0],
      bidPriceQuote             |-> [i \in 1 .. 6 |-> 0],
      bidPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      bidSize                   |-> [i \in 1 .. 5 |-> 0],
      askPriceQuote             |-> [i \in 1 .. 6 |-> 0],
      askPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      askSize                   |-> [i \in 1 .. 5 |-> 0],
      instrumentStatusMarker    |-> [i \in 1 .. 1 |-> 0] ]

(* Futures Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedFuturesQuoteMessage ==
    { ZeroFuturesQuoteMessage }
        \cup { [ZeroFuturesQuoteMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroFuturesQuoteMessage EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroFuturesQuoteMessage EXCEPT !.deliveryMonth = one] : one \in Sample(1) }
        \cup { [ZeroFuturesQuoteMessage EXCEPT !.deliveryYearFutures = one] : one \in Sample(2) }
        \cup { [ZeroFuturesQuoteMessage EXCEPT !.deliveryDay = one] : one \in Sample(2) }
        \cup { [ZeroFuturesQuoteMessage EXCEPT !.bidPriceQuote = one] : one \in Sample(6) }
        \cup { [ZeroFuturesQuoteMessage EXCEPT !.bidPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFuturesQuoteMessage EXCEPT !.bidSize = one] : one \in Sample(5) }
        \cup { [ZeroFuturesQuoteMessage EXCEPT !.askPriceQuote = one] : one \in Sample(6) }
        \cup { [ZeroFuturesQuoteMessage EXCEPT !.askPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFuturesQuoteMessage EXCEPT !.askSize = one] : one \in Sample(5) }
        \cup { [ZeroFuturesQuoteMessage EXCEPT !.instrumentStatusMarker = one] : one \in Sample(1) }

(***************************************************************************)
(* Strategy Quote Message: 58 bytes                                        *)
(***************************************************************************)

StrategyQuoteMessage ==
    [ exchangeId                : Sample(1),
      symbol                    : Sample(30),
      bidPriceSign              : Sample(1),
      bidPriceQuote             : Sample(6),
      bidPriceFractionIndicator : Sample(1),
      bidSize                   : Sample(5),
      askPriceSign              : Sample(1),
      askPriceQuote             : Sample(6),
      askPriceFractionIndicator : Sample(1),
      askSize                   : Sample(5),
      instrumentStatusMarker    : Sample(1) ]

EncodeStrategyQuoteMessage(message) ==
    message.exchangeId
        \o message.symbol
        \o message.bidPriceSign
        \o message.bidPriceQuote
        \o message.bidPriceFractionIndicator
        \o message.bidSize
        \o message.askPriceSign
        \o message.askPriceQuote
        \o message.askPriceFractionIndicator
        \o message.askSize
        \o message.instrumentStatusMarker

DecodeStrategyQuoteMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET symbol == ReadBytes(exchangeId.rest, 30) IN IF ~symbol.ok THEN Fail ELSE
    LET bidPriceSign == ReadBytes(symbol.rest, 1) IN IF ~bidPriceSign.ok THEN Fail ELSE
    LET bidPriceQuote == ReadBytes(bidPriceSign.rest, 6) IN IF ~bidPriceQuote.ok THEN Fail ELSE
    LET bidPriceFractionIndicator == ReadBytes(bidPriceQuote.rest, 1) IN IF ~bidPriceFractionIndicator.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPriceFractionIndicator.rest, 5) IN IF ~bidSize.ok THEN Fail ELSE
    LET askPriceSign == ReadBytes(bidSize.rest, 1) IN IF ~askPriceSign.ok THEN Fail ELSE
    LET askPriceQuote == ReadBytes(askPriceSign.rest, 6) IN IF ~askPriceQuote.ok THEN Fail ELSE
    LET askPriceFractionIndicator == ReadBytes(askPriceQuote.rest, 1) IN IF ~askPriceFractionIndicator.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPriceFractionIndicator.rest, 5) IN IF ~askSize.ok THEN Fail ELSE
    LET instrumentStatusMarker == ReadBytes(askSize.rest, 1) IN IF ~instrumentStatusMarker.ok THEN Fail ELSE
    Ok([ exchangeId                |-> exchangeId.value,
         symbol                    |-> symbol.value,
         bidPriceSign              |-> bidPriceSign.value,
         bidPriceQuote             |-> bidPriceQuote.value,
         bidPriceFractionIndicator |-> bidPriceFractionIndicator.value,
         bidSize                   |-> bidSize.value,
         askPriceSign              |-> askPriceSign.value,
         askPriceQuote             |-> askPriceQuote.value,
         askPriceFractionIndicator |-> askPriceFractionIndicator.value,
         askSize                   |-> askSize.value,
         instrumentStatusMarker    |-> instrumentStatusMarker.value ], instrumentStatusMarker.rest)

ZeroStrategyQuoteMessage ==
    [ exchangeId                |-> [i \in 1 .. 1 |-> 0],
      symbol                    |-> [i \in 1 .. 30 |-> 0],
      bidPriceSign              |-> [i \in 1 .. 1 |-> 0],
      bidPriceQuote             |-> [i \in 1 .. 6 |-> 0],
      bidPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      bidSize                   |-> [i \in 1 .. 5 |-> 0],
      askPriceSign              |-> [i \in 1 .. 1 |-> 0],
      askPriceQuote             |-> [i \in 1 .. 6 |-> 0],
      askPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      askSize                   |-> [i \in 1 .. 5 |-> 0],
      instrumentStatusMarker    |-> [i \in 1 .. 1 |-> 0] ]

(* Strategy Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedStrategyQuoteMessage ==
    { ZeroStrategyQuoteMessage }
        \cup { [ZeroStrategyQuoteMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroStrategyQuoteMessage EXCEPT !.symbol = one] : one \in Sample(30) }
        \cup { [ZeroStrategyQuoteMessage EXCEPT !.bidPriceSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategyQuoteMessage EXCEPT !.bidPriceQuote = one] : one \in Sample(6) }
        \cup { [ZeroStrategyQuoteMessage EXCEPT !.bidPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStrategyQuoteMessage EXCEPT !.bidSize = one] : one \in Sample(5) }
        \cup { [ZeroStrategyQuoteMessage EXCEPT !.askPriceSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategyQuoteMessage EXCEPT !.askPriceQuote = one] : one \in Sample(6) }
        \cup { [ZeroStrategyQuoteMessage EXCEPT !.askPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStrategyQuoteMessage EXCEPT !.askSize = one] : one \in Sample(5) }
        \cup { [ZeroStrategyQuoteMessage EXCEPT !.instrumentStatusMarker = one] : one \in Sample(1) }

(***************************************************************************)
(* Swap Future Quote Message: 45 bytes                                     *)
(***************************************************************************)

SwapFutureQuoteMessage ==
    [ exchangeId                 : Sample(1),
      rootSymbol                 : Sample(6),
      expiryMonth                : Sample(1),
      expiryYear                 : Sample(2),
      expiryDay                  : Sample(2),
      tenor                      : Sample(2),
      fixedRate                  : Sample(5),
      fixedRateFractionIndicator : Sample(1),
      bidPriceQuote              : Sample(6),
      bidPriceFractionIndicator  : Sample(1),
      bidSize                    : Sample(5),
      askPriceQuote              : Sample(6),
      askPriceFractionIndicator  : Sample(1),
      askSize                    : Sample(5),
      instrumentStatusMarker     : Sample(1) ]

EncodeSwapFutureQuoteMessage(message) ==
    message.exchangeId
        \o message.rootSymbol
        \o message.expiryMonth
        \o message.expiryYear
        \o message.expiryDay
        \o message.tenor
        \o message.fixedRate
        \o message.fixedRateFractionIndicator
        \o message.bidPriceQuote
        \o message.bidPriceFractionIndicator
        \o message.bidSize
        \o message.askPriceQuote
        \o message.askPriceFractionIndicator
        \o message.askSize
        \o message.instrumentStatusMarker

DecodeSwapFutureQuoteMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET rootSymbol == ReadBytes(exchangeId.rest, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET expiryMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~expiryMonth.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(expiryMonth.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET tenor == ReadBytes(expiryDay.rest, 2) IN IF ~tenor.ok THEN Fail ELSE
    LET fixedRate == ReadBytes(tenor.rest, 5) IN IF ~fixedRate.ok THEN Fail ELSE
    LET fixedRateFractionIndicator == ReadBytes(fixedRate.rest, 1) IN IF ~fixedRateFractionIndicator.ok THEN Fail ELSE
    LET bidPriceQuote == ReadBytes(fixedRateFractionIndicator.rest, 6) IN IF ~bidPriceQuote.ok THEN Fail ELSE
    LET bidPriceFractionIndicator == ReadBytes(bidPriceQuote.rest, 1) IN IF ~bidPriceFractionIndicator.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPriceFractionIndicator.rest, 5) IN IF ~bidSize.ok THEN Fail ELSE
    LET askPriceQuote == ReadBytes(bidSize.rest, 6) IN IF ~askPriceQuote.ok THEN Fail ELSE
    LET askPriceFractionIndicator == ReadBytes(askPriceQuote.rest, 1) IN IF ~askPriceFractionIndicator.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPriceFractionIndicator.rest, 5) IN IF ~askSize.ok THEN Fail ELSE
    LET instrumentStatusMarker == ReadBytes(askSize.rest, 1) IN IF ~instrumentStatusMarker.ok THEN Fail ELSE
    Ok([ exchangeId                 |-> exchangeId.value,
         rootSymbol                 |-> rootSymbol.value,
         expiryMonth                |-> expiryMonth.value,
         expiryYear                 |-> expiryYear.value,
         expiryDay                  |-> expiryDay.value,
         tenor                      |-> tenor.value,
         fixedRate                  |-> fixedRate.value,
         fixedRateFractionIndicator |-> fixedRateFractionIndicator.value,
         bidPriceQuote              |-> bidPriceQuote.value,
         bidPriceFractionIndicator  |-> bidPriceFractionIndicator.value,
         bidSize                    |-> bidSize.value,
         askPriceQuote              |-> askPriceQuote.value,
         askPriceFractionIndicator  |-> askPriceFractionIndicator.value,
         askSize                    |-> askSize.value,
         instrumentStatusMarker     |-> instrumentStatusMarker.value ], instrumentStatusMarker.rest)

ZeroSwapFutureQuoteMessage ==
    [ exchangeId                 |-> [i \in 1 .. 1 |-> 0],
      rootSymbol                 |-> [i \in 1 .. 6 |-> 0],
      expiryMonth                |-> [i \in 1 .. 1 |-> 0],
      expiryYear                 |-> [i \in 1 .. 2 |-> 0],
      expiryDay                  |-> [i \in 1 .. 2 |-> 0],
      tenor                      |-> [i \in 1 .. 2 |-> 0],
      fixedRate                  |-> [i \in 1 .. 5 |-> 0],
      fixedRateFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      bidPriceQuote              |-> [i \in 1 .. 6 |-> 0],
      bidPriceFractionIndicator  |-> [i \in 1 .. 1 |-> 0],
      bidSize                    |-> [i \in 1 .. 5 |-> 0],
      askPriceQuote              |-> [i \in 1 .. 6 |-> 0],
      askPriceFractionIndicator  |-> [i \in 1 .. 1 |-> 0],
      askSize                    |-> [i \in 1 .. 5 |-> 0],
      instrumentStatusMarker     |-> [i \in 1 .. 1 |-> 0] ]

(* Swap Future Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedSwapFutureQuoteMessage ==
    { ZeroSwapFutureQuoteMessage }
        \cup { [ZeroSwapFutureQuoteMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureQuoteMessage EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroSwapFutureQuoteMessage EXCEPT !.expiryMonth = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureQuoteMessage EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroSwapFutureQuoteMessage EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroSwapFutureQuoteMessage EXCEPT !.tenor = one] : one \in Sample(2) }
        \cup { [ZeroSwapFutureQuoteMessage EXCEPT !.fixedRate = one] : one \in Sample(5) }
        \cup { [ZeroSwapFutureQuoteMessage EXCEPT !.fixedRateFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureQuoteMessage EXCEPT !.bidPriceQuote = one] : one \in Sample(6) }
        \cup { [ZeroSwapFutureQuoteMessage EXCEPT !.bidPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureQuoteMessage EXCEPT !.bidSize = one] : one \in Sample(5) }
        \cup { [ZeroSwapFutureQuoteMessage EXCEPT !.askPriceQuote = one] : one \in Sample(6) }
        \cup { [ZeroSwapFutureQuoteMessage EXCEPT !.askPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureQuoteMessage EXCEPT !.askSize = one] : one \in Sample(5) }
        \cup { [ZeroSwapFutureQuoteMessage EXCEPT !.instrumentStatusMarker = one] : one \in Sample(1) }

(***************************************************************************)
(* Option Market Depth Trading Instrument: 29 bytes                        *)
(***************************************************************************)

OptionMarketDepthTradingInstrument ==
    [ levelOfMarketDepth        : Sample(1),
      bidPriceQuote             : Sample(6),
      bidPriceFractionIndicator : Sample(1),
      bidSize                   : Sample(5),
      numberOfBidOrders         : Sample(2),
      askPriceQuote             : Sample(6),
      askPriceFractionIndicator : Sample(1),
      askSize                   : Sample(5),
      numberOfAskOrders         : Sample(2) ]

EncodeOptionMarketDepthTradingInstrument(message) ==
    message.levelOfMarketDepth
        \o message.bidPriceQuote
        \o message.bidPriceFractionIndicator
        \o message.bidSize
        \o message.numberOfBidOrders
        \o message.askPriceQuote
        \o message.askPriceFractionIndicator
        \o message.askSize
        \o message.numberOfAskOrders

DecodeOptionMarketDepthTradingInstrument(bytes) ==
    LET levelOfMarketDepth == ReadBytes(bytes, 1) IN IF ~levelOfMarketDepth.ok THEN Fail ELSE
    LET bidPriceQuote == ReadBytes(levelOfMarketDepth.rest, 6) IN IF ~bidPriceQuote.ok THEN Fail ELSE
    LET bidPriceFractionIndicator == ReadBytes(bidPriceQuote.rest, 1) IN IF ~bidPriceFractionIndicator.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPriceFractionIndicator.rest, 5) IN IF ~bidSize.ok THEN Fail ELSE
    LET numberOfBidOrders == ReadBytes(bidSize.rest, 2) IN IF ~numberOfBidOrders.ok THEN Fail ELSE
    LET askPriceQuote == ReadBytes(numberOfBidOrders.rest, 6) IN IF ~askPriceQuote.ok THEN Fail ELSE
    LET askPriceFractionIndicator == ReadBytes(askPriceQuote.rest, 1) IN IF ~askPriceFractionIndicator.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPriceFractionIndicator.rest, 5) IN IF ~askSize.ok THEN Fail ELSE
    LET numberOfAskOrders == ReadBytes(askSize.rest, 2) IN IF ~numberOfAskOrders.ok THEN Fail ELSE
    Ok([ levelOfMarketDepth        |-> levelOfMarketDepth.value,
         bidPriceQuote             |-> bidPriceQuote.value,
         bidPriceFractionIndicator |-> bidPriceFractionIndicator.value,
         bidSize                   |-> bidSize.value,
         numberOfBidOrders         |-> numberOfBidOrders.value,
         askPriceQuote             |-> askPriceQuote.value,
         askPriceFractionIndicator |-> askPriceFractionIndicator.value,
         askSize                   |-> askSize.value,
         numberOfAskOrders         |-> numberOfAskOrders.value ], numberOfAskOrders.rest)

ZeroOptionMarketDepthTradingInstrument ==
    [ levelOfMarketDepth        |-> [i \in 1 .. 1 |-> 0],
      bidPriceQuote             |-> [i \in 1 .. 6 |-> 0],
      bidPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      bidSize                   |-> [i \in 1 .. 5 |-> 0],
      numberOfBidOrders         |-> [i \in 1 .. 2 |-> 0],
      askPriceQuote             |-> [i \in 1 .. 6 |-> 0],
      askPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      askSize                   |-> [i \in 1 .. 5 |-> 0],
      numberOfAskOrders         |-> [i \in 1 .. 2 |-> 0] ]

(* Option Market Depth Trading Instrument at zero, then each field in turn at the values it is checked at *)
CheckedOptionMarketDepthTradingInstrument ==
    { ZeroOptionMarketDepthTradingInstrument }
        \cup { [ZeroOptionMarketDepthTradingInstrument EXCEPT !.levelOfMarketDepth = one] : one \in Sample(1) }
        \cup { [ZeroOptionMarketDepthTradingInstrument EXCEPT !.bidPriceQuote = one] : one \in Sample(6) }
        \cup { [ZeroOptionMarketDepthTradingInstrument EXCEPT !.bidPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionMarketDepthTradingInstrument EXCEPT !.bidSize = one] : one \in Sample(5) }
        \cup { [ZeroOptionMarketDepthTradingInstrument EXCEPT !.numberOfBidOrders = one] : one \in Sample(2) }
        \cup { [ZeroOptionMarketDepthTradingInstrument EXCEPT !.askPriceQuote = one] : one \in Sample(6) }
        \cup { [ZeroOptionMarketDepthTradingInstrument EXCEPT !.askPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionMarketDepthTradingInstrument EXCEPT !.askSize = one] : one \in Sample(5) }
        \cup { [ZeroOptionMarketDepthTradingInstrument EXCEPT !.numberOfAskOrders = one] : one \in Sample(2) }

(* A run of Option Market Depth Trading Instrument, written one after another *)
RECURSIVE EncodeOptionMarketDepthTradingInstrumentList(_)
EncodeOptionMarketDepthTradingInstrumentList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOptionMarketDepthTradingInstrument(Head(messages)) \o EncodeOptionMarketDepthTradingInstrumentList(Tail(messages))

(* As many Option Market Depth Trading Instrument as the field that counts them says *)
RECURSIVE ReadOptionMarketDepthTradingInstrumentList(_, _)
ReadOptionMarketDepthTradingInstrumentList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOptionMarketDepthTradingInstrument(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOptionMarketDepthTradingInstrumentList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Option Market Depth Trading Instrument of each kind, for the lists that carry them *)
OneOptionMarketDepthTradingInstrument == { ZeroOptionMarketDepthTradingInstrument }

(***************************************************************************)
(* Option Market Depth Message                                             *)
(***************************************************************************)

OptionMarketDepthMessage ==
    [ exchangeId                         : Sample(1),
      rootSymbol                         : Sample(6),
      expiryMonth                        : Sample(1),
      filler1                            : Sample(1),
      strikePriceInstrument              : Sample(7),
      strikePriceFractionIndicator       : Sample(1),
      expiryYear                         : Sample(2),
      expiryDay                          : Sample(2),
      instrumentStatusMarker             : Sample(1),
      optionMarketDepthTradingInstrument : SampleLists(OneOptionMarketDepthTradingInstrument) ]

EncodeOptionMarketDepthMessage(message) ==
    message.exchangeId
        \o message.rootSymbol
        \o message.expiryMonth
        \o message.filler1
        \o message.strikePriceInstrument
        \o message.strikePriceFractionIndicator
        \o message.expiryYear
        \o message.expiryDay
        \o message.instrumentStatusMarker
        \o EncodeDigits(Len(message.optionMarketDepthTradingInstrument), 1)
        \o EncodeOptionMarketDepthTradingInstrumentList(message.optionMarketDepthTradingInstrument)

DecodeOptionMarketDepthMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET rootSymbol == ReadBytes(exchangeId.rest, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET expiryMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~expiryMonth.ok THEN Fail ELSE
    LET filler1 == ReadBytes(expiryMonth.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET strikePriceInstrument == ReadBytes(filler1.rest, 7) IN IF ~strikePriceInstrument.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePriceInstrument.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(strikePriceFractionIndicator.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET instrumentStatusMarker == ReadBytes(expiryDay.rest, 1) IN IF ~instrumentStatusMarker.ok THEN Fail ELSE
    LET numberOfLevel == ReadDigits(instrumentStatusMarker.rest, 1) IN IF ~numberOfLevel.ok THEN Fail ELSE
    LET optionMarketDepthTradingInstrument == ReadOptionMarketDepthTradingInstrumentList(numberOfLevel.rest, numberOfLevel.value) IN IF ~optionMarketDepthTradingInstrument.ok THEN Fail ELSE
    Ok([ exchangeId                         |-> exchangeId.value,
         rootSymbol                         |-> rootSymbol.value,
         expiryMonth                        |-> expiryMonth.value,
         filler1                            |-> filler1.value,
         strikePriceInstrument              |-> strikePriceInstrument.value,
         strikePriceFractionIndicator       |-> strikePriceFractionIndicator.value,
         expiryYear                         |-> expiryYear.value,
         expiryDay                          |-> expiryDay.value,
         instrumentStatusMarker             |-> instrumentStatusMarker.value,
         optionMarketDepthTradingInstrument |-> optionMarketDepthTradingInstrument.value ], optionMarketDepthTradingInstrument.rest)

ZeroOptionMarketDepthMessage ==
    [ exchangeId                         |-> [i \in 1 .. 1 |-> 0],
      rootSymbol                         |-> [i \in 1 .. 6 |-> 0],
      expiryMonth                        |-> [i \in 1 .. 1 |-> 0],
      filler1                            |-> [i \in 1 .. 1 |-> 0],
      strikePriceInstrument              |-> [i \in 1 .. 7 |-> 0],
      strikePriceFractionIndicator       |-> [i \in 1 .. 1 |-> 0],
      expiryYear                         |-> [i \in 1 .. 2 |-> 0],
      expiryDay                          |-> [i \in 1 .. 2 |-> 0],
      instrumentStatusMarker             |-> [i \in 1 .. 1 |-> 0],
      optionMarketDepthTradingInstrument |-> << >> ]

(* Option Market Depth Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionMarketDepthMessage ==
    { ZeroOptionMarketDepthMessage }
        \cup { [ZeroOptionMarketDepthMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroOptionMarketDepthMessage EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroOptionMarketDepthMessage EXCEPT !.expiryMonth = one] : one \in Sample(1) }
        \cup { [ZeroOptionMarketDepthMessage EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroOptionMarketDepthMessage EXCEPT !.strikePriceInstrument = one] : one \in Sample(7) }
        \cup { [ZeroOptionMarketDepthMessage EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionMarketDepthMessage EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroOptionMarketDepthMessage EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroOptionMarketDepthMessage EXCEPT !.instrumentStatusMarker = one] : one \in Sample(1) }
        \cup { [ZeroOptionMarketDepthMessage EXCEPT !.optionMarketDepthTradingInstrument = one] : one \in SampleLists(OneOptionMarketDepthTradingInstrument) }

(***************************************************************************)
(* Future Options Market Depth Trading Instrument: 29 bytes                *)
(***************************************************************************)

FutureOptionsMarketDepthTradingInstrument ==
    [ levelOfMarketDepth        : Sample(1),
      bidPriceQuote             : Sample(6),
      bidPriceFractionIndicator : Sample(1),
      bidSize                   : Sample(5),
      numberOfBidOrders         : Sample(2),
      askPriceQuote             : Sample(6),
      askPriceFractionIndicator : Sample(1),
      askSize                   : Sample(5),
      numberOfAskOrders         : Sample(2) ]

EncodeFutureOptionsMarketDepthTradingInstrument(message) ==
    message.levelOfMarketDepth
        \o message.bidPriceQuote
        \o message.bidPriceFractionIndicator
        \o message.bidSize
        \o message.numberOfBidOrders
        \o message.askPriceQuote
        \o message.askPriceFractionIndicator
        \o message.askSize
        \o message.numberOfAskOrders

DecodeFutureOptionsMarketDepthTradingInstrument(bytes) ==
    LET levelOfMarketDepth == ReadBytes(bytes, 1) IN IF ~levelOfMarketDepth.ok THEN Fail ELSE
    LET bidPriceQuote == ReadBytes(levelOfMarketDepth.rest, 6) IN IF ~bidPriceQuote.ok THEN Fail ELSE
    LET bidPriceFractionIndicator == ReadBytes(bidPriceQuote.rest, 1) IN IF ~bidPriceFractionIndicator.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPriceFractionIndicator.rest, 5) IN IF ~bidSize.ok THEN Fail ELSE
    LET numberOfBidOrders == ReadBytes(bidSize.rest, 2) IN IF ~numberOfBidOrders.ok THEN Fail ELSE
    LET askPriceQuote == ReadBytes(numberOfBidOrders.rest, 6) IN IF ~askPriceQuote.ok THEN Fail ELSE
    LET askPriceFractionIndicator == ReadBytes(askPriceQuote.rest, 1) IN IF ~askPriceFractionIndicator.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPriceFractionIndicator.rest, 5) IN IF ~askSize.ok THEN Fail ELSE
    LET numberOfAskOrders == ReadBytes(askSize.rest, 2) IN IF ~numberOfAskOrders.ok THEN Fail ELSE
    Ok([ levelOfMarketDepth        |-> levelOfMarketDepth.value,
         bidPriceQuote             |-> bidPriceQuote.value,
         bidPriceFractionIndicator |-> bidPriceFractionIndicator.value,
         bidSize                   |-> bidSize.value,
         numberOfBidOrders         |-> numberOfBidOrders.value,
         askPriceQuote             |-> askPriceQuote.value,
         askPriceFractionIndicator |-> askPriceFractionIndicator.value,
         askSize                   |-> askSize.value,
         numberOfAskOrders         |-> numberOfAskOrders.value ], numberOfAskOrders.rest)

ZeroFutureOptionsMarketDepthTradingInstrument ==
    [ levelOfMarketDepth        |-> [i \in 1 .. 1 |-> 0],
      bidPriceQuote             |-> [i \in 1 .. 6 |-> 0],
      bidPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      bidSize                   |-> [i \in 1 .. 5 |-> 0],
      numberOfBidOrders         |-> [i \in 1 .. 2 |-> 0],
      askPriceQuote             |-> [i \in 1 .. 6 |-> 0],
      askPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      askSize                   |-> [i \in 1 .. 5 |-> 0],
      numberOfAskOrders         |-> [i \in 1 .. 2 |-> 0] ]

(* Future Options Market Depth Trading Instrument at zero, then each field in turn at the values it is checked at *)
CheckedFutureOptionsMarketDepthTradingInstrument ==
    { ZeroFutureOptionsMarketDepthTradingInstrument }
        \cup { [ZeroFutureOptionsMarketDepthTradingInstrument EXCEPT !.levelOfMarketDepth = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsMarketDepthTradingInstrument EXCEPT !.bidPriceQuote = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionsMarketDepthTradingInstrument EXCEPT !.bidPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsMarketDepthTradingInstrument EXCEPT !.bidSize = one] : one \in Sample(5) }
        \cup { [ZeroFutureOptionsMarketDepthTradingInstrument EXCEPT !.numberOfBidOrders = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionsMarketDepthTradingInstrument EXCEPT !.askPriceQuote = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionsMarketDepthTradingInstrument EXCEPT !.askPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsMarketDepthTradingInstrument EXCEPT !.askSize = one] : one \in Sample(5) }
        \cup { [ZeroFutureOptionsMarketDepthTradingInstrument EXCEPT !.numberOfAskOrders = one] : one \in Sample(2) }

(* A run of Future Options Market Depth Trading Instrument, written one after another *)
RECURSIVE EncodeFutureOptionsMarketDepthTradingInstrumentList(_)
EncodeFutureOptionsMarketDepthTradingInstrumentList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeFutureOptionsMarketDepthTradingInstrument(Head(messages)) \o EncodeFutureOptionsMarketDepthTradingInstrumentList(Tail(messages))

(* As many Future Options Market Depth Trading Instrument as the field that counts them says *)
RECURSIVE ReadFutureOptionsMarketDepthTradingInstrumentList(_, _)
ReadFutureOptionsMarketDepthTradingInstrumentList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeFutureOptionsMarketDepthTradingInstrument(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadFutureOptionsMarketDepthTradingInstrumentList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Future Options Market Depth Trading Instrument of each kind, for the lists that carry them *)
OneFutureOptionsMarketDepthTradingInstrument == { ZeroFutureOptionsMarketDepthTradingInstrument }

(***************************************************************************)
(* Future Options Market Depth Message                                     *)
(***************************************************************************)

FutureOptionsMarketDepthMessage ==
    [ exchangeId                                : Sample(1),
      rootSymbol                                : Sample(6),
      contractMonthCode                         : Sample(1),
      expiryYear                                : Sample(2),
      expiryDay                                 : Sample(2),
      callPutCode                               : Sample(1),
      strikePriceInstrument                     : Sample(7),
      strikePriceFractionIndicator              : Sample(1),
      instrumentStatusMarker                    : Sample(1),
      futureOptionsMarketDepthTradingInstrument : SampleLists(OneFutureOptionsMarketDepthTradingInstrument) ]

EncodeFutureOptionsMarketDepthMessage(message) ==
    message.exchangeId
        \o message.rootSymbol
        \o message.contractMonthCode
        \o message.expiryYear
        \o message.expiryDay
        \o message.callPutCode
        \o message.strikePriceInstrument
        \o message.strikePriceFractionIndicator
        \o message.instrumentStatusMarker
        \o EncodeDigits(Len(message.futureOptionsMarketDepthTradingInstrument), 1)
        \o EncodeFutureOptionsMarketDepthTradingInstrumentList(message.futureOptionsMarketDepthTradingInstrument)

DecodeFutureOptionsMarketDepthMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET rootSymbol == ReadBytes(exchangeId.rest, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET contractMonthCode == ReadBytes(rootSymbol.rest, 1) IN IF ~contractMonthCode.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(contractMonthCode.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET callPutCode == ReadBytes(expiryDay.rest, 1) IN IF ~callPutCode.ok THEN Fail ELSE
    LET strikePriceInstrument == ReadBytes(callPutCode.rest, 7) IN IF ~strikePriceInstrument.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePriceInstrument.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    LET instrumentStatusMarker == ReadBytes(strikePriceFractionIndicator.rest, 1) IN IF ~instrumentStatusMarker.ok THEN Fail ELSE
    LET numberOfLevel == ReadDigits(instrumentStatusMarker.rest, 1) IN IF ~numberOfLevel.ok THEN Fail ELSE
    LET futureOptionsMarketDepthTradingInstrument == ReadFutureOptionsMarketDepthTradingInstrumentList(numberOfLevel.rest, numberOfLevel.value) IN IF ~futureOptionsMarketDepthTradingInstrument.ok THEN Fail ELSE
    Ok([ exchangeId                                |-> exchangeId.value,
         rootSymbol                                |-> rootSymbol.value,
         contractMonthCode                         |-> contractMonthCode.value,
         expiryYear                                |-> expiryYear.value,
         expiryDay                                 |-> expiryDay.value,
         callPutCode                               |-> callPutCode.value,
         strikePriceInstrument                     |-> strikePriceInstrument.value,
         strikePriceFractionIndicator              |-> strikePriceFractionIndicator.value,
         instrumentStatusMarker                    |-> instrumentStatusMarker.value,
         futureOptionsMarketDepthTradingInstrument |-> futureOptionsMarketDepthTradingInstrument.value ], futureOptionsMarketDepthTradingInstrument.rest)

ZeroFutureOptionsMarketDepthMessage ==
    [ exchangeId                                |-> [i \in 1 .. 1 |-> 0],
      rootSymbol                                |-> [i \in 1 .. 6 |-> 0],
      contractMonthCode                         |-> [i \in 1 .. 1 |-> 0],
      expiryYear                                |-> [i \in 1 .. 2 |-> 0],
      expiryDay                                 |-> [i \in 1 .. 2 |-> 0],
      callPutCode                               |-> [i \in 1 .. 1 |-> 0],
      strikePriceInstrument                     |-> [i \in 1 .. 7 |-> 0],
      strikePriceFractionIndicator              |-> [i \in 1 .. 1 |-> 0],
      instrumentStatusMarker                    |-> [i \in 1 .. 1 |-> 0],
      futureOptionsMarketDepthTradingInstrument |-> << >> ]

(* Future Options Market Depth Message at zero, then each field in turn at the values it is checked at *)
CheckedFutureOptionsMarketDepthMessage ==
    { ZeroFutureOptionsMarketDepthMessage }
        \cup { [ZeroFutureOptionsMarketDepthMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsMarketDepthMessage EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionsMarketDepthMessage EXCEPT !.contractMonthCode = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsMarketDepthMessage EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionsMarketDepthMessage EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionsMarketDepthMessage EXCEPT !.callPutCode = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsMarketDepthMessage EXCEPT !.strikePriceInstrument = one] : one \in Sample(7) }
        \cup { [ZeroFutureOptionsMarketDepthMessage EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsMarketDepthMessage EXCEPT !.instrumentStatusMarker = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsMarketDepthMessage EXCEPT !.futureOptionsMarketDepthTradingInstrument = one] : one \in SampleLists(OneFutureOptionsMarketDepthTradingInstrument) }

(***************************************************************************)
(* Futures Market Depth Trading Instrument: 29 bytes                       *)
(***************************************************************************)

FuturesMarketDepthTradingInstrument ==
    [ levelOfMarketDepth        : Sample(1),
      bidPriceQuote             : Sample(6),
      bidPriceFractionIndicator : Sample(1),
      bidSize                   : Sample(5),
      numberOfBidOrders         : Sample(2),
      askPriceQuote             : Sample(6),
      askPriceFractionIndicator : Sample(1),
      askSize                   : Sample(5),
      numberOfAskOrders         : Sample(2) ]

EncodeFuturesMarketDepthTradingInstrument(message) ==
    message.levelOfMarketDepth
        \o message.bidPriceQuote
        \o message.bidPriceFractionIndicator
        \o message.bidSize
        \o message.numberOfBidOrders
        \o message.askPriceQuote
        \o message.askPriceFractionIndicator
        \o message.askSize
        \o message.numberOfAskOrders

DecodeFuturesMarketDepthTradingInstrument(bytes) ==
    LET levelOfMarketDepth == ReadBytes(bytes, 1) IN IF ~levelOfMarketDepth.ok THEN Fail ELSE
    LET bidPriceQuote == ReadBytes(levelOfMarketDepth.rest, 6) IN IF ~bidPriceQuote.ok THEN Fail ELSE
    LET bidPriceFractionIndicator == ReadBytes(bidPriceQuote.rest, 1) IN IF ~bidPriceFractionIndicator.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPriceFractionIndicator.rest, 5) IN IF ~bidSize.ok THEN Fail ELSE
    LET numberOfBidOrders == ReadBytes(bidSize.rest, 2) IN IF ~numberOfBidOrders.ok THEN Fail ELSE
    LET askPriceQuote == ReadBytes(numberOfBidOrders.rest, 6) IN IF ~askPriceQuote.ok THEN Fail ELSE
    LET askPriceFractionIndicator == ReadBytes(askPriceQuote.rest, 1) IN IF ~askPriceFractionIndicator.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPriceFractionIndicator.rest, 5) IN IF ~askSize.ok THEN Fail ELSE
    LET numberOfAskOrders == ReadBytes(askSize.rest, 2) IN IF ~numberOfAskOrders.ok THEN Fail ELSE
    Ok([ levelOfMarketDepth        |-> levelOfMarketDepth.value,
         bidPriceQuote             |-> bidPriceQuote.value,
         bidPriceFractionIndicator |-> bidPriceFractionIndicator.value,
         bidSize                   |-> bidSize.value,
         numberOfBidOrders         |-> numberOfBidOrders.value,
         askPriceQuote             |-> askPriceQuote.value,
         askPriceFractionIndicator |-> askPriceFractionIndicator.value,
         askSize                   |-> askSize.value,
         numberOfAskOrders         |-> numberOfAskOrders.value ], numberOfAskOrders.rest)

ZeroFuturesMarketDepthTradingInstrument ==
    [ levelOfMarketDepth        |-> [i \in 1 .. 1 |-> 0],
      bidPriceQuote             |-> [i \in 1 .. 6 |-> 0],
      bidPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      bidSize                   |-> [i \in 1 .. 5 |-> 0],
      numberOfBidOrders         |-> [i \in 1 .. 2 |-> 0],
      askPriceQuote             |-> [i \in 1 .. 6 |-> 0],
      askPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      askSize                   |-> [i \in 1 .. 5 |-> 0],
      numberOfAskOrders         |-> [i \in 1 .. 2 |-> 0] ]

(* Futures Market Depth Trading Instrument at zero, then each field in turn at the values it is checked at *)
CheckedFuturesMarketDepthTradingInstrument ==
    { ZeroFuturesMarketDepthTradingInstrument }
        \cup { [ZeroFuturesMarketDepthTradingInstrument EXCEPT !.levelOfMarketDepth = one] : one \in Sample(1) }
        \cup { [ZeroFuturesMarketDepthTradingInstrument EXCEPT !.bidPriceQuote = one] : one \in Sample(6) }
        \cup { [ZeroFuturesMarketDepthTradingInstrument EXCEPT !.bidPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFuturesMarketDepthTradingInstrument EXCEPT !.bidSize = one] : one \in Sample(5) }
        \cup { [ZeroFuturesMarketDepthTradingInstrument EXCEPT !.numberOfBidOrders = one] : one \in Sample(2) }
        \cup { [ZeroFuturesMarketDepthTradingInstrument EXCEPT !.askPriceQuote = one] : one \in Sample(6) }
        \cup { [ZeroFuturesMarketDepthTradingInstrument EXCEPT !.askPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFuturesMarketDepthTradingInstrument EXCEPT !.askSize = one] : one \in Sample(5) }
        \cup { [ZeroFuturesMarketDepthTradingInstrument EXCEPT !.numberOfAskOrders = one] : one \in Sample(2) }

(* A run of Futures Market Depth Trading Instrument, written one after another *)
RECURSIVE EncodeFuturesMarketDepthTradingInstrumentList(_)
EncodeFuturesMarketDepthTradingInstrumentList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeFuturesMarketDepthTradingInstrument(Head(messages)) \o EncodeFuturesMarketDepthTradingInstrumentList(Tail(messages))

(* As many Futures Market Depth Trading Instrument as the field that counts them says *)
RECURSIVE ReadFuturesMarketDepthTradingInstrumentList(_, _)
ReadFuturesMarketDepthTradingInstrumentList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeFuturesMarketDepthTradingInstrument(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadFuturesMarketDepthTradingInstrumentList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Futures Market Depth Trading Instrument of each kind, for the lists that carry them *)
OneFuturesMarketDepthTradingInstrument == { ZeroFuturesMarketDepthTradingInstrument }

(***************************************************************************)
(* Futures Market Depth Message                                            *)
(***************************************************************************)

FuturesMarketDepthMessage ==
    [ exchangeId                          : Sample(1),
      rootSymbol                          : Sample(6),
      deliveryMonth                       : Sample(1),
      deliveryYearFutures                 : Sample(2),
      deliveryDay                         : Sample(2),
      instrumentStatusMarker              : Sample(1),
      futuresMarketDepthTradingInstrument : SampleLists(OneFuturesMarketDepthTradingInstrument) ]

EncodeFuturesMarketDepthMessage(message) ==
    message.exchangeId
        \o message.rootSymbol
        \o message.deliveryMonth
        \o message.deliveryYearFutures
        \o message.deliveryDay
        \o message.instrumentStatusMarker
        \o EncodeDigits(Len(message.futuresMarketDepthTradingInstrument), 1)
        \o EncodeFuturesMarketDepthTradingInstrumentList(message.futuresMarketDepthTradingInstrument)

DecodeFuturesMarketDepthMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET rootSymbol == ReadBytes(exchangeId.rest, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET deliveryMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~deliveryMonth.ok THEN Fail ELSE
    LET deliveryYearFutures == ReadBytes(deliveryMonth.rest, 2) IN IF ~deliveryYearFutures.ok THEN Fail ELSE
    LET deliveryDay == ReadBytes(deliveryYearFutures.rest, 2) IN IF ~deliveryDay.ok THEN Fail ELSE
    LET instrumentStatusMarker == ReadBytes(deliveryDay.rest, 1) IN IF ~instrumentStatusMarker.ok THEN Fail ELSE
    LET numberOfLevel == ReadDigits(instrumentStatusMarker.rest, 1) IN IF ~numberOfLevel.ok THEN Fail ELSE
    LET futuresMarketDepthTradingInstrument == ReadFuturesMarketDepthTradingInstrumentList(numberOfLevel.rest, numberOfLevel.value) IN IF ~futuresMarketDepthTradingInstrument.ok THEN Fail ELSE
    Ok([ exchangeId                          |-> exchangeId.value,
         rootSymbol                          |-> rootSymbol.value,
         deliveryMonth                       |-> deliveryMonth.value,
         deliveryYearFutures                 |-> deliveryYearFutures.value,
         deliveryDay                         |-> deliveryDay.value,
         instrumentStatusMarker              |-> instrumentStatusMarker.value,
         futuresMarketDepthTradingInstrument |-> futuresMarketDepthTradingInstrument.value ], futuresMarketDepthTradingInstrument.rest)

ZeroFuturesMarketDepthMessage ==
    [ exchangeId                          |-> [i \in 1 .. 1 |-> 0],
      rootSymbol                          |-> [i \in 1 .. 6 |-> 0],
      deliveryMonth                       |-> [i \in 1 .. 1 |-> 0],
      deliveryYearFutures                 |-> [i \in 1 .. 2 |-> 0],
      deliveryDay                         |-> [i \in 1 .. 2 |-> 0],
      instrumentStatusMarker              |-> [i \in 1 .. 1 |-> 0],
      futuresMarketDepthTradingInstrument |-> << >> ]

(* Futures Market Depth Message at zero, then each field in turn at the values it is checked at *)
CheckedFuturesMarketDepthMessage ==
    { ZeroFuturesMarketDepthMessage }
        \cup { [ZeroFuturesMarketDepthMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroFuturesMarketDepthMessage EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroFuturesMarketDepthMessage EXCEPT !.deliveryMonth = one] : one \in Sample(1) }
        \cup { [ZeroFuturesMarketDepthMessage EXCEPT !.deliveryYearFutures = one] : one \in Sample(2) }
        \cup { [ZeroFuturesMarketDepthMessage EXCEPT !.deliveryDay = one] : one \in Sample(2) }
        \cup { [ZeroFuturesMarketDepthMessage EXCEPT !.instrumentStatusMarker = one] : one \in Sample(1) }
        \cup { [ZeroFuturesMarketDepthMessage EXCEPT !.futuresMarketDepthTradingInstrument = one] : one \in SampleLists(OneFuturesMarketDepthTradingInstrument) }

(***************************************************************************)
(* Strategy Market Depth Trading Instrument: 31 bytes                      *)
(***************************************************************************)

StrategyMarketDepthTradingInstrument ==
    [ levelOfMarketDepth        : Sample(1),
      bidPriceSign              : Sample(1),
      bidPriceQuote             : Sample(6),
      bidPriceFractionIndicator : Sample(1),
      bidSize                   : Sample(5),
      numberOfBidOrders         : Sample(2),
      askPriceSign              : Sample(1),
      askPriceQuote             : Sample(6),
      askPriceFractionIndicator : Sample(1),
      askSize                   : Sample(5),
      numberOfAskOrders         : Sample(2) ]

EncodeStrategyMarketDepthTradingInstrument(message) ==
    message.levelOfMarketDepth
        \o message.bidPriceSign
        \o message.bidPriceQuote
        \o message.bidPriceFractionIndicator
        \o message.bidSize
        \o message.numberOfBidOrders
        \o message.askPriceSign
        \o message.askPriceQuote
        \o message.askPriceFractionIndicator
        \o message.askSize
        \o message.numberOfAskOrders

DecodeStrategyMarketDepthTradingInstrument(bytes) ==
    LET levelOfMarketDepth == ReadBytes(bytes, 1) IN IF ~levelOfMarketDepth.ok THEN Fail ELSE
    LET bidPriceSign == ReadBytes(levelOfMarketDepth.rest, 1) IN IF ~bidPriceSign.ok THEN Fail ELSE
    LET bidPriceQuote == ReadBytes(bidPriceSign.rest, 6) IN IF ~bidPriceQuote.ok THEN Fail ELSE
    LET bidPriceFractionIndicator == ReadBytes(bidPriceQuote.rest, 1) IN IF ~bidPriceFractionIndicator.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPriceFractionIndicator.rest, 5) IN IF ~bidSize.ok THEN Fail ELSE
    LET numberOfBidOrders == ReadBytes(bidSize.rest, 2) IN IF ~numberOfBidOrders.ok THEN Fail ELSE
    LET askPriceSign == ReadBytes(numberOfBidOrders.rest, 1) IN IF ~askPriceSign.ok THEN Fail ELSE
    LET askPriceQuote == ReadBytes(askPriceSign.rest, 6) IN IF ~askPriceQuote.ok THEN Fail ELSE
    LET askPriceFractionIndicator == ReadBytes(askPriceQuote.rest, 1) IN IF ~askPriceFractionIndicator.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPriceFractionIndicator.rest, 5) IN IF ~askSize.ok THEN Fail ELSE
    LET numberOfAskOrders == ReadBytes(askSize.rest, 2) IN IF ~numberOfAskOrders.ok THEN Fail ELSE
    Ok([ levelOfMarketDepth        |-> levelOfMarketDepth.value,
         bidPriceSign              |-> bidPriceSign.value,
         bidPriceQuote             |-> bidPriceQuote.value,
         bidPriceFractionIndicator |-> bidPriceFractionIndicator.value,
         bidSize                   |-> bidSize.value,
         numberOfBidOrders         |-> numberOfBidOrders.value,
         askPriceSign              |-> askPriceSign.value,
         askPriceQuote             |-> askPriceQuote.value,
         askPriceFractionIndicator |-> askPriceFractionIndicator.value,
         askSize                   |-> askSize.value,
         numberOfAskOrders         |-> numberOfAskOrders.value ], numberOfAskOrders.rest)

ZeroStrategyMarketDepthTradingInstrument ==
    [ levelOfMarketDepth        |-> [i \in 1 .. 1 |-> 0],
      bidPriceSign              |-> [i \in 1 .. 1 |-> 0],
      bidPriceQuote             |-> [i \in 1 .. 6 |-> 0],
      bidPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      bidSize                   |-> [i \in 1 .. 5 |-> 0],
      numberOfBidOrders         |-> [i \in 1 .. 2 |-> 0],
      askPriceSign              |-> [i \in 1 .. 1 |-> 0],
      askPriceQuote             |-> [i \in 1 .. 6 |-> 0],
      askPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      askSize                   |-> [i \in 1 .. 5 |-> 0],
      numberOfAskOrders         |-> [i \in 1 .. 2 |-> 0] ]

(* Strategy Market Depth Trading Instrument at zero, then each field in turn at the values it is checked at *)
CheckedStrategyMarketDepthTradingInstrument ==
    { ZeroStrategyMarketDepthTradingInstrument }
        \cup { [ZeroStrategyMarketDepthTradingInstrument EXCEPT !.levelOfMarketDepth = one] : one \in Sample(1) }
        \cup { [ZeroStrategyMarketDepthTradingInstrument EXCEPT !.bidPriceSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategyMarketDepthTradingInstrument EXCEPT !.bidPriceQuote = one] : one \in Sample(6) }
        \cup { [ZeroStrategyMarketDepthTradingInstrument EXCEPT !.bidPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStrategyMarketDepthTradingInstrument EXCEPT !.bidSize = one] : one \in Sample(5) }
        \cup { [ZeroStrategyMarketDepthTradingInstrument EXCEPT !.numberOfBidOrders = one] : one \in Sample(2) }
        \cup { [ZeroStrategyMarketDepthTradingInstrument EXCEPT !.askPriceSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategyMarketDepthTradingInstrument EXCEPT !.askPriceQuote = one] : one \in Sample(6) }
        \cup { [ZeroStrategyMarketDepthTradingInstrument EXCEPT !.askPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStrategyMarketDepthTradingInstrument EXCEPT !.askSize = one] : one \in Sample(5) }
        \cup { [ZeroStrategyMarketDepthTradingInstrument EXCEPT !.numberOfAskOrders = one] : one \in Sample(2) }

(* A run of Strategy Market Depth Trading Instrument, written one after another *)
RECURSIVE EncodeStrategyMarketDepthTradingInstrumentList(_)
EncodeStrategyMarketDepthTradingInstrumentList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeStrategyMarketDepthTradingInstrument(Head(messages)) \o EncodeStrategyMarketDepthTradingInstrumentList(Tail(messages))

(* As many Strategy Market Depth Trading Instrument as the field that counts them says *)
RECURSIVE ReadStrategyMarketDepthTradingInstrumentList(_, _)
ReadStrategyMarketDepthTradingInstrumentList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeStrategyMarketDepthTradingInstrument(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadStrategyMarketDepthTradingInstrumentList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Strategy Market Depth Trading Instrument of each kind, for the lists that carry them *)
OneStrategyMarketDepthTradingInstrument == { ZeroStrategyMarketDepthTradingInstrument }

(***************************************************************************)
(* Strategy Market Depth Message                                           *)
(***************************************************************************)

StrategyMarketDepthMessage ==
    [ exchangeId                           : Sample(1),
      symbol                               : Sample(30),
      instrumentStatusMarker               : Sample(1),
      strategyMarketDepthTradingInstrument : SampleLists(OneStrategyMarketDepthTradingInstrument) ]

EncodeStrategyMarketDepthMessage(message) ==
    message.exchangeId
        \o message.symbol
        \o message.instrumentStatusMarker
        \o EncodeDigits(Len(message.strategyMarketDepthTradingInstrument), 1)
        \o EncodeStrategyMarketDepthTradingInstrumentList(message.strategyMarketDepthTradingInstrument)

DecodeStrategyMarketDepthMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET symbol == ReadBytes(exchangeId.rest, 30) IN IF ~symbol.ok THEN Fail ELSE
    LET instrumentStatusMarker == ReadBytes(symbol.rest, 1) IN IF ~instrumentStatusMarker.ok THEN Fail ELSE
    LET numberOfLevel == ReadDigits(instrumentStatusMarker.rest, 1) IN IF ~numberOfLevel.ok THEN Fail ELSE
    LET strategyMarketDepthTradingInstrument == ReadStrategyMarketDepthTradingInstrumentList(numberOfLevel.rest, numberOfLevel.value) IN IF ~strategyMarketDepthTradingInstrument.ok THEN Fail ELSE
    Ok([ exchangeId                           |-> exchangeId.value,
         symbol                               |-> symbol.value,
         instrumentStatusMarker               |-> instrumentStatusMarker.value,
         strategyMarketDepthTradingInstrument |-> strategyMarketDepthTradingInstrument.value ], strategyMarketDepthTradingInstrument.rest)

ZeroStrategyMarketDepthMessage ==
    [ exchangeId                           |-> [i \in 1 .. 1 |-> 0],
      symbol                               |-> [i \in 1 .. 30 |-> 0],
      instrumentStatusMarker               |-> [i \in 1 .. 1 |-> 0],
      strategyMarketDepthTradingInstrument |-> << >> ]

(* Strategy Market Depth Message at zero, then each field in turn at the values it is checked at *)
CheckedStrategyMarketDepthMessage ==
    { ZeroStrategyMarketDepthMessage }
        \cup { [ZeroStrategyMarketDepthMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroStrategyMarketDepthMessage EXCEPT !.symbol = one] : one \in Sample(30) }
        \cup { [ZeroStrategyMarketDepthMessage EXCEPT !.instrumentStatusMarker = one] : one \in Sample(1) }
        \cup { [ZeroStrategyMarketDepthMessage EXCEPT !.strategyMarketDepthTradingInstrument = one] : one \in SampleLists(OneStrategyMarketDepthTradingInstrument) }

(***************************************************************************)
(* Swap Future Market Depth Trading Instrument: 29 bytes                   *)
(***************************************************************************)

SwapFutureMarketDepthTradingInstrument ==
    [ level                     : Sample(1),
      bidPriceQuote             : Sample(6),
      bidPriceFractionIndicator : Sample(1),
      bidSize                   : Sample(5),
      numberOfBidOrders         : Sample(2),
      askPriceQuote             : Sample(6),
      askPriceFractionIndicator : Sample(1),
      askSize                   : Sample(5),
      numberOfAskOrders         : Sample(2) ]

EncodeSwapFutureMarketDepthTradingInstrument(message) ==
    message.level
        \o message.bidPriceQuote
        \o message.bidPriceFractionIndicator
        \o message.bidSize
        \o message.numberOfBidOrders
        \o message.askPriceQuote
        \o message.askPriceFractionIndicator
        \o message.askSize
        \o message.numberOfAskOrders

DecodeSwapFutureMarketDepthTradingInstrument(bytes) ==
    LET level == ReadBytes(bytes, 1) IN IF ~level.ok THEN Fail ELSE
    LET bidPriceQuote == ReadBytes(level.rest, 6) IN IF ~bidPriceQuote.ok THEN Fail ELSE
    LET bidPriceFractionIndicator == ReadBytes(bidPriceQuote.rest, 1) IN IF ~bidPriceFractionIndicator.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPriceFractionIndicator.rest, 5) IN IF ~bidSize.ok THEN Fail ELSE
    LET numberOfBidOrders == ReadBytes(bidSize.rest, 2) IN IF ~numberOfBidOrders.ok THEN Fail ELSE
    LET askPriceQuote == ReadBytes(numberOfBidOrders.rest, 6) IN IF ~askPriceQuote.ok THEN Fail ELSE
    LET askPriceFractionIndicator == ReadBytes(askPriceQuote.rest, 1) IN IF ~askPriceFractionIndicator.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPriceFractionIndicator.rest, 5) IN IF ~askSize.ok THEN Fail ELSE
    LET numberOfAskOrders == ReadBytes(askSize.rest, 2) IN IF ~numberOfAskOrders.ok THEN Fail ELSE
    Ok([ level                     |-> level.value,
         bidPriceQuote             |-> bidPriceQuote.value,
         bidPriceFractionIndicator |-> bidPriceFractionIndicator.value,
         bidSize                   |-> bidSize.value,
         numberOfBidOrders         |-> numberOfBidOrders.value,
         askPriceQuote             |-> askPriceQuote.value,
         askPriceFractionIndicator |-> askPriceFractionIndicator.value,
         askSize                   |-> askSize.value,
         numberOfAskOrders         |-> numberOfAskOrders.value ], numberOfAskOrders.rest)

ZeroSwapFutureMarketDepthTradingInstrument ==
    [ level                     |-> [i \in 1 .. 1 |-> 0],
      bidPriceQuote             |-> [i \in 1 .. 6 |-> 0],
      bidPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      bidSize                   |-> [i \in 1 .. 5 |-> 0],
      numberOfBidOrders         |-> [i \in 1 .. 2 |-> 0],
      askPriceQuote             |-> [i \in 1 .. 6 |-> 0],
      askPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      askSize                   |-> [i \in 1 .. 5 |-> 0],
      numberOfAskOrders         |-> [i \in 1 .. 2 |-> 0] ]

(* Swap Future Market Depth Trading Instrument at zero, then each field in turn at the values it is checked at *)
CheckedSwapFutureMarketDepthTradingInstrument ==
    { ZeroSwapFutureMarketDepthTradingInstrument }
        \cup { [ZeroSwapFutureMarketDepthTradingInstrument EXCEPT !.level = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureMarketDepthTradingInstrument EXCEPT !.bidPriceQuote = one] : one \in Sample(6) }
        \cup { [ZeroSwapFutureMarketDepthTradingInstrument EXCEPT !.bidPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureMarketDepthTradingInstrument EXCEPT !.bidSize = one] : one \in Sample(5) }
        \cup { [ZeroSwapFutureMarketDepthTradingInstrument EXCEPT !.numberOfBidOrders = one] : one \in Sample(2) }
        \cup { [ZeroSwapFutureMarketDepthTradingInstrument EXCEPT !.askPriceQuote = one] : one \in Sample(6) }
        \cup { [ZeroSwapFutureMarketDepthTradingInstrument EXCEPT !.askPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureMarketDepthTradingInstrument EXCEPT !.askSize = one] : one \in Sample(5) }
        \cup { [ZeroSwapFutureMarketDepthTradingInstrument EXCEPT !.numberOfAskOrders = one] : one \in Sample(2) }

(* A run of Swap Future Market Depth Trading Instrument, written one after another *)
RECURSIVE EncodeSwapFutureMarketDepthTradingInstrumentList(_)
EncodeSwapFutureMarketDepthTradingInstrumentList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSwapFutureMarketDepthTradingInstrument(Head(messages)) \o EncodeSwapFutureMarketDepthTradingInstrumentList(Tail(messages))

(* As many Swap Future Market Depth Trading Instrument as the field that counts them says *)
RECURSIVE ReadSwapFutureMarketDepthTradingInstrumentList(_, _)
ReadSwapFutureMarketDepthTradingInstrumentList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSwapFutureMarketDepthTradingInstrument(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSwapFutureMarketDepthTradingInstrumentList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Swap Future Market Depth Trading Instrument of each kind, for the lists that carry them *)
OneSwapFutureMarketDepthTradingInstrument == { ZeroSwapFutureMarketDepthTradingInstrument }

(***************************************************************************)
(* Swap Future Market Depth Message                                        *)
(***************************************************************************)

SwapFutureMarketDepthMessage ==
    [ exchangeId                             : Sample(1),
      rootSymbol                             : Sample(6),
      expiryMonth                            : Sample(1),
      expiryYear                             : Sample(2),
      expiryDay                              : Sample(2),
      tenor                                  : Sample(2),
      fixedRate                              : Sample(5),
      fixedRateFractionIndicator             : Sample(1),
      instrumentStatusMarker                 : Sample(1),
      swapFutureMarketDepthTradingInstrument : SampleLists(OneSwapFutureMarketDepthTradingInstrument) ]

EncodeSwapFutureMarketDepthMessage(message) ==
    message.exchangeId
        \o message.rootSymbol
        \o message.expiryMonth
        \o message.expiryYear
        \o message.expiryDay
        \o message.tenor
        \o message.fixedRate
        \o message.fixedRateFractionIndicator
        \o message.instrumentStatusMarker
        \o EncodeDigits(Len(message.swapFutureMarketDepthTradingInstrument), 1)
        \o EncodeSwapFutureMarketDepthTradingInstrumentList(message.swapFutureMarketDepthTradingInstrument)

DecodeSwapFutureMarketDepthMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET rootSymbol == ReadBytes(exchangeId.rest, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET expiryMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~expiryMonth.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(expiryMonth.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET tenor == ReadBytes(expiryDay.rest, 2) IN IF ~tenor.ok THEN Fail ELSE
    LET fixedRate == ReadBytes(tenor.rest, 5) IN IF ~fixedRate.ok THEN Fail ELSE
    LET fixedRateFractionIndicator == ReadBytes(fixedRate.rest, 1) IN IF ~fixedRateFractionIndicator.ok THEN Fail ELSE
    LET instrumentStatusMarker == ReadBytes(fixedRateFractionIndicator.rest, 1) IN IF ~instrumentStatusMarker.ok THEN Fail ELSE
    LET numberOfLevel == ReadDigits(instrumentStatusMarker.rest, 1) IN IF ~numberOfLevel.ok THEN Fail ELSE
    LET swapFutureMarketDepthTradingInstrument == ReadSwapFutureMarketDepthTradingInstrumentList(numberOfLevel.rest, numberOfLevel.value) IN IF ~swapFutureMarketDepthTradingInstrument.ok THEN Fail ELSE
    Ok([ exchangeId                             |-> exchangeId.value,
         rootSymbol                             |-> rootSymbol.value,
         expiryMonth                            |-> expiryMonth.value,
         expiryYear                             |-> expiryYear.value,
         expiryDay                              |-> expiryDay.value,
         tenor                                  |-> tenor.value,
         fixedRate                              |-> fixedRate.value,
         fixedRateFractionIndicator             |-> fixedRateFractionIndicator.value,
         instrumentStatusMarker                 |-> instrumentStatusMarker.value,
         swapFutureMarketDepthTradingInstrument |-> swapFutureMarketDepthTradingInstrument.value ], swapFutureMarketDepthTradingInstrument.rest)

ZeroSwapFutureMarketDepthMessage ==
    [ exchangeId                             |-> [i \in 1 .. 1 |-> 0],
      rootSymbol                             |-> [i \in 1 .. 6 |-> 0],
      expiryMonth                            |-> [i \in 1 .. 1 |-> 0],
      expiryYear                             |-> [i \in 1 .. 2 |-> 0],
      expiryDay                              |-> [i \in 1 .. 2 |-> 0],
      tenor                                  |-> [i \in 1 .. 2 |-> 0],
      fixedRate                              |-> [i \in 1 .. 5 |-> 0],
      fixedRateFractionIndicator             |-> [i \in 1 .. 1 |-> 0],
      instrumentStatusMarker                 |-> [i \in 1 .. 1 |-> 0],
      swapFutureMarketDepthTradingInstrument |-> << >> ]

(* Swap Future Market Depth Message at zero, then each field in turn at the values it is checked at *)
CheckedSwapFutureMarketDepthMessage ==
    { ZeroSwapFutureMarketDepthMessage }
        \cup { [ZeroSwapFutureMarketDepthMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureMarketDepthMessage EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroSwapFutureMarketDepthMessage EXCEPT !.expiryMonth = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureMarketDepthMessage EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroSwapFutureMarketDepthMessage EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroSwapFutureMarketDepthMessage EXCEPT !.tenor = one] : one \in Sample(2) }
        \cup { [ZeroSwapFutureMarketDepthMessage EXCEPT !.fixedRate = one] : one \in Sample(5) }
        \cup { [ZeroSwapFutureMarketDepthMessage EXCEPT !.fixedRateFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureMarketDepthMessage EXCEPT !.instrumentStatusMarker = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureMarketDepthMessage EXCEPT !.swapFutureMarketDepthTradingInstrument = one] : one \in SampleLists(OneSwapFutureMarketDepthTradingInstrument) }

(***************************************************************************)
(* Option Trade Cancellation Message: 68 bytes                             *)
(***************************************************************************)

OptionTradeCancellationMessage ==
    [ exchangeId                   : Sample(1),
      rootSymbol                   : Sample(6),
      expiryMonth                  : Sample(1),
      filler1                      : Sample(1),
      strikePriceInstrument        : Sample(7),
      strikePriceFractionIndicator : Sample(1),
      expiryYear                   : Sample(2),
      expiryDay                    : Sample(2),
      volume                       : Sample(8),
      tradePrice                   : Sample(6),
      tradePriceFractionIndicator  : Sample(1),
      filler6                      : Sample(6),
      timestamp                    : Sample(9),
      openInterest                 : Sample(7),
      secondFiller1                : Sample(1),
      priceIndicatorMarker         : Sample(1),
      tradeNumber                  : Sample(8) ]

EncodeOptionTradeCancellationMessage(message) ==
    message.exchangeId
        \o message.rootSymbol
        \o message.expiryMonth
        \o message.filler1
        \o message.strikePriceInstrument
        \o message.strikePriceFractionIndicator
        \o message.expiryYear
        \o message.expiryDay
        \o message.volume
        \o message.tradePrice
        \o message.tradePriceFractionIndicator
        \o message.filler6
        \o message.timestamp
        \o message.openInterest
        \o message.secondFiller1
        \o message.priceIndicatorMarker
        \o message.tradeNumber

DecodeOptionTradeCancellationMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET rootSymbol == ReadBytes(exchangeId.rest, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET expiryMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~expiryMonth.ok THEN Fail ELSE
    LET filler1 == ReadBytes(expiryMonth.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET strikePriceInstrument == ReadBytes(filler1.rest, 7) IN IF ~strikePriceInstrument.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePriceInstrument.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(strikePriceFractionIndicator.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET volume == ReadBytes(expiryDay.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(volume.rest, 6) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradePriceFractionIndicator == ReadBytes(tradePrice.rest, 1) IN IF ~tradePriceFractionIndicator.ok THEN Fail ELSE
    LET filler6 == ReadBytes(tradePriceFractionIndicator.rest, 6) IN IF ~filler6.ok THEN Fail ELSE
    LET timestamp == ReadBytes(filler6.rest, 9) IN IF ~timestamp.ok THEN Fail ELSE
    LET openInterest == ReadBytes(timestamp.rest, 7) IN IF ~openInterest.ok THEN Fail ELSE
    LET secondFiller1 == ReadBytes(openInterest.rest, 1) IN IF ~secondFiller1.ok THEN Fail ELSE
    LET priceIndicatorMarker == ReadBytes(secondFiller1.rest, 1) IN IF ~priceIndicatorMarker.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(priceIndicatorMarker.rest, 8) IN IF ~tradeNumber.ok THEN Fail ELSE
    Ok([ exchangeId                   |-> exchangeId.value,
         rootSymbol                   |-> rootSymbol.value,
         expiryMonth                  |-> expiryMonth.value,
         filler1                      |-> filler1.value,
         strikePriceInstrument        |-> strikePriceInstrument.value,
         strikePriceFractionIndicator |-> strikePriceFractionIndicator.value,
         expiryYear                   |-> expiryYear.value,
         expiryDay                    |-> expiryDay.value,
         volume                       |-> volume.value,
         tradePrice                   |-> tradePrice.value,
         tradePriceFractionIndicator  |-> tradePriceFractionIndicator.value,
         filler6                      |-> filler6.value,
         timestamp                    |-> timestamp.value,
         openInterest                 |-> openInterest.value,
         secondFiller1                |-> secondFiller1.value,
         priceIndicatorMarker         |-> priceIndicatorMarker.value,
         tradeNumber                  |-> tradeNumber.value ], tradeNumber.rest)

ZeroOptionTradeCancellationMessage ==
    [ exchangeId                   |-> [i \in 1 .. 1 |-> 0],
      rootSymbol                   |-> [i \in 1 .. 6 |-> 0],
      expiryMonth                  |-> [i \in 1 .. 1 |-> 0],
      filler1                      |-> [i \in 1 .. 1 |-> 0],
      strikePriceInstrument        |-> [i \in 1 .. 7 |-> 0],
      strikePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      expiryYear                   |-> [i \in 1 .. 2 |-> 0],
      expiryDay                    |-> [i \in 1 .. 2 |-> 0],
      volume                       |-> [i \in 1 .. 8 |-> 0],
      tradePrice                   |-> [i \in 1 .. 6 |-> 0],
      tradePriceFractionIndicator  |-> [i \in 1 .. 1 |-> 0],
      filler6                      |-> [i \in 1 .. 6 |-> 0],
      timestamp                    |-> [i \in 1 .. 9 |-> 0],
      openInterest                 |-> [i \in 1 .. 7 |-> 0],
      secondFiller1                |-> [i \in 1 .. 1 |-> 0],
      priceIndicatorMarker         |-> [i \in 1 .. 1 |-> 0],
      tradeNumber                  |-> [i \in 1 .. 8 |-> 0] ]

(* Option Trade Cancellation Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionTradeCancellationMessage ==
    { ZeroOptionTradeCancellationMessage }
        \cup { [ZeroOptionTradeCancellationMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeCancellationMessage EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroOptionTradeCancellationMessage EXCEPT !.expiryMonth = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeCancellationMessage EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeCancellationMessage EXCEPT !.strikePriceInstrument = one] : one \in Sample(7) }
        \cup { [ZeroOptionTradeCancellationMessage EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeCancellationMessage EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroOptionTradeCancellationMessage EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroOptionTradeCancellationMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroOptionTradeCancellationMessage EXCEPT !.tradePrice = one] : one \in Sample(6) }
        \cup { [ZeroOptionTradeCancellationMessage EXCEPT !.tradePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeCancellationMessage EXCEPT !.filler6 = one] : one \in Sample(6) }
        \cup { [ZeroOptionTradeCancellationMessage EXCEPT !.timestamp = one] : one \in Sample(9) }
        \cup { [ZeroOptionTradeCancellationMessage EXCEPT !.openInterest = one] : one \in Sample(7) }
        \cup { [ZeroOptionTradeCancellationMessage EXCEPT !.secondFiller1 = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeCancellationMessage EXCEPT !.priceIndicatorMarker = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeCancellationMessage EXCEPT !.tradeNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Future Options Trade Cancellation Message: 69 bytes                     *)
(***************************************************************************)

FutureOptionsTradeCancellationMessage ==
    [ exchangeId                   : Sample(1),
      rootSymbol                   : Sample(6),
      contractMonthCode            : Sample(1),
      expiryYear                   : Sample(2),
      expiryDay                    : Sample(2),
      callPutCode                  : Sample(1),
      strikePriceInstrument        : Sample(7),
      strikePriceFractionIndicator : Sample(1),
      volume                       : Sample(8),
      price                        : Sample(6),
      priceFractionIndicator       : Sample(1),
      priceIndicatorMarker         : Sample(1),
      filler6                      : Sample(6),
      timestamp                    : Sample(9),
      openInterest                 : Sample(7),
      filler2                      : Sample(2),
      tradeNumber                  : Sample(8) ]

EncodeFutureOptionsTradeCancellationMessage(message) ==
    message.exchangeId
        \o message.rootSymbol
        \o message.contractMonthCode
        \o message.expiryYear
        \o message.expiryDay
        \o message.callPutCode
        \o message.strikePriceInstrument
        \o message.strikePriceFractionIndicator
        \o message.volume
        \o message.price
        \o message.priceFractionIndicator
        \o message.priceIndicatorMarker
        \o message.filler6
        \o message.timestamp
        \o message.openInterest
        \o message.filler2
        \o message.tradeNumber

DecodeFutureOptionsTradeCancellationMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET rootSymbol == ReadBytes(exchangeId.rest, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET contractMonthCode == ReadBytes(rootSymbol.rest, 1) IN IF ~contractMonthCode.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(contractMonthCode.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET callPutCode == ReadBytes(expiryDay.rest, 1) IN IF ~callPutCode.ok THEN Fail ELSE
    LET strikePriceInstrument == ReadBytes(callPutCode.rest, 7) IN IF ~strikePriceInstrument.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePriceInstrument.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    LET volume == ReadBytes(strikePriceFractionIndicator.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET price == ReadBytes(volume.rest, 6) IN IF ~price.ok THEN Fail ELSE
    LET priceFractionIndicator == ReadBytes(price.rest, 1) IN IF ~priceFractionIndicator.ok THEN Fail ELSE
    LET priceIndicatorMarker == ReadBytes(priceFractionIndicator.rest, 1) IN IF ~priceIndicatorMarker.ok THEN Fail ELSE
    LET filler6 == ReadBytes(priceIndicatorMarker.rest, 6) IN IF ~filler6.ok THEN Fail ELSE
    LET timestamp == ReadBytes(filler6.rest, 9) IN IF ~timestamp.ok THEN Fail ELSE
    LET openInterest == ReadBytes(timestamp.rest, 7) IN IF ~openInterest.ok THEN Fail ELSE
    LET filler2 == ReadBytes(openInterest.rest, 2) IN IF ~filler2.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(filler2.rest, 8) IN IF ~tradeNumber.ok THEN Fail ELSE
    Ok([ exchangeId                   |-> exchangeId.value,
         rootSymbol                   |-> rootSymbol.value,
         contractMonthCode            |-> contractMonthCode.value,
         expiryYear                   |-> expiryYear.value,
         expiryDay                    |-> expiryDay.value,
         callPutCode                  |-> callPutCode.value,
         strikePriceInstrument        |-> strikePriceInstrument.value,
         strikePriceFractionIndicator |-> strikePriceFractionIndicator.value,
         volume                       |-> volume.value,
         price                        |-> price.value,
         priceFractionIndicator       |-> priceFractionIndicator.value,
         priceIndicatorMarker         |-> priceIndicatorMarker.value,
         filler6                      |-> filler6.value,
         timestamp                    |-> timestamp.value,
         openInterest                 |-> openInterest.value,
         filler2                      |-> filler2.value,
         tradeNumber                  |-> tradeNumber.value ], tradeNumber.rest)

ZeroFutureOptionsTradeCancellationMessage ==
    [ exchangeId                   |-> [i \in 1 .. 1 |-> 0],
      rootSymbol                   |-> [i \in 1 .. 6 |-> 0],
      contractMonthCode            |-> [i \in 1 .. 1 |-> 0],
      expiryYear                   |-> [i \in 1 .. 2 |-> 0],
      expiryDay                    |-> [i \in 1 .. 2 |-> 0],
      callPutCode                  |-> [i \in 1 .. 1 |-> 0],
      strikePriceInstrument        |-> [i \in 1 .. 7 |-> 0],
      strikePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      volume                       |-> [i \in 1 .. 8 |-> 0],
      price                        |-> [i \in 1 .. 6 |-> 0],
      priceFractionIndicator       |-> [i \in 1 .. 1 |-> 0],
      priceIndicatorMarker         |-> [i \in 1 .. 1 |-> 0],
      filler6                      |-> [i \in 1 .. 6 |-> 0],
      timestamp                    |-> [i \in 1 .. 9 |-> 0],
      openInterest                 |-> [i \in 1 .. 7 |-> 0],
      filler2                      |-> [i \in 1 .. 2 |-> 0],
      tradeNumber                  |-> [i \in 1 .. 8 |-> 0] ]

(* Future Options Trade Cancellation Message at zero, then each field in turn at the values it is checked at *)
CheckedFutureOptionsTradeCancellationMessage ==
    { ZeroFutureOptionsTradeCancellationMessage }
        \cup { [ZeroFutureOptionsTradeCancellationMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsTradeCancellationMessage EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionsTradeCancellationMessage EXCEPT !.contractMonthCode = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsTradeCancellationMessage EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionsTradeCancellationMessage EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionsTradeCancellationMessage EXCEPT !.callPutCode = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsTradeCancellationMessage EXCEPT !.strikePriceInstrument = one] : one \in Sample(7) }
        \cup { [ZeroFutureOptionsTradeCancellationMessage EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsTradeCancellationMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroFutureOptionsTradeCancellationMessage EXCEPT !.price = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionsTradeCancellationMessage EXCEPT !.priceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsTradeCancellationMessage EXCEPT !.priceIndicatorMarker = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsTradeCancellationMessage EXCEPT !.filler6 = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionsTradeCancellationMessage EXCEPT !.timestamp = one] : one \in Sample(9) }
        \cup { [ZeroFutureOptionsTradeCancellationMessage EXCEPT !.openInterest = one] : one \in Sample(7) }
        \cup { [ZeroFutureOptionsTradeCancellationMessage EXCEPT !.filler2 = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionsTradeCancellationMessage EXCEPT !.tradeNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Futures Trade Cancellation Message: 51 bytes                            *)
(***************************************************************************)

FuturesTradeCancellationMessage ==
    [ exchangeId                  : Sample(1),
      rootSymbol                  : Sample(6),
      deliveryMonth               : Sample(1),
      deliveryYearFutures         : Sample(2),
      deliveryDay                 : Sample(2),
      volume                      : Sample(8),
      tradePrice                  : Sample(6),
      tradePriceFractionIndicator : Sample(1),
      filler6                     : Sample(6),
      timestamp                   : Sample(9),
      priceIndicatorMarker        : Sample(1),
      tradeNumber                 : Sample(8) ]

EncodeFuturesTradeCancellationMessage(message) ==
    message.exchangeId
        \o message.rootSymbol
        \o message.deliveryMonth
        \o message.deliveryYearFutures
        \o message.deliveryDay
        \o message.volume
        \o message.tradePrice
        \o message.tradePriceFractionIndicator
        \o message.filler6
        \o message.timestamp
        \o message.priceIndicatorMarker
        \o message.tradeNumber

DecodeFuturesTradeCancellationMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET rootSymbol == ReadBytes(exchangeId.rest, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET deliveryMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~deliveryMonth.ok THEN Fail ELSE
    LET deliveryYearFutures == ReadBytes(deliveryMonth.rest, 2) IN IF ~deliveryYearFutures.ok THEN Fail ELSE
    LET deliveryDay == ReadBytes(deliveryYearFutures.rest, 2) IN IF ~deliveryDay.ok THEN Fail ELSE
    LET volume == ReadBytes(deliveryDay.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(volume.rest, 6) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradePriceFractionIndicator == ReadBytes(tradePrice.rest, 1) IN IF ~tradePriceFractionIndicator.ok THEN Fail ELSE
    LET filler6 == ReadBytes(tradePriceFractionIndicator.rest, 6) IN IF ~filler6.ok THEN Fail ELSE
    LET timestamp == ReadBytes(filler6.rest, 9) IN IF ~timestamp.ok THEN Fail ELSE
    LET priceIndicatorMarker == ReadBytes(timestamp.rest, 1) IN IF ~priceIndicatorMarker.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(priceIndicatorMarker.rest, 8) IN IF ~tradeNumber.ok THEN Fail ELSE
    Ok([ exchangeId                  |-> exchangeId.value,
         rootSymbol                  |-> rootSymbol.value,
         deliveryMonth               |-> deliveryMonth.value,
         deliveryYearFutures         |-> deliveryYearFutures.value,
         deliveryDay                 |-> deliveryDay.value,
         volume                      |-> volume.value,
         tradePrice                  |-> tradePrice.value,
         tradePriceFractionIndicator |-> tradePriceFractionIndicator.value,
         filler6                     |-> filler6.value,
         timestamp                   |-> timestamp.value,
         priceIndicatorMarker        |-> priceIndicatorMarker.value,
         tradeNumber                 |-> tradeNumber.value ], tradeNumber.rest)

ZeroFuturesTradeCancellationMessage ==
    [ exchangeId                  |-> [i \in 1 .. 1 |-> 0],
      rootSymbol                  |-> [i \in 1 .. 6 |-> 0],
      deliveryMonth               |-> [i \in 1 .. 1 |-> 0],
      deliveryYearFutures         |-> [i \in 1 .. 2 |-> 0],
      deliveryDay                 |-> [i \in 1 .. 2 |-> 0],
      volume                      |-> [i \in 1 .. 8 |-> 0],
      tradePrice                  |-> [i \in 1 .. 6 |-> 0],
      tradePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      filler6                     |-> [i \in 1 .. 6 |-> 0],
      timestamp                   |-> [i \in 1 .. 9 |-> 0],
      priceIndicatorMarker        |-> [i \in 1 .. 1 |-> 0],
      tradeNumber                 |-> [i \in 1 .. 8 |-> 0] ]

(* Futures Trade Cancellation Message at zero, then each field in turn at the values it is checked at *)
CheckedFuturesTradeCancellationMessage ==
    { ZeroFuturesTradeCancellationMessage }
        \cup { [ZeroFuturesTradeCancellationMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroFuturesTradeCancellationMessage EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroFuturesTradeCancellationMessage EXCEPT !.deliveryMonth = one] : one \in Sample(1) }
        \cup { [ZeroFuturesTradeCancellationMessage EXCEPT !.deliveryYearFutures = one] : one \in Sample(2) }
        \cup { [ZeroFuturesTradeCancellationMessage EXCEPT !.deliveryDay = one] : one \in Sample(2) }
        \cup { [ZeroFuturesTradeCancellationMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroFuturesTradeCancellationMessage EXCEPT !.tradePrice = one] : one \in Sample(6) }
        \cup { [ZeroFuturesTradeCancellationMessage EXCEPT !.tradePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFuturesTradeCancellationMessage EXCEPT !.filler6 = one] : one \in Sample(6) }
        \cup { [ZeroFuturesTradeCancellationMessage EXCEPT !.timestamp = one] : one \in Sample(9) }
        \cup { [ZeroFuturesTradeCancellationMessage EXCEPT !.priceIndicatorMarker = one] : one \in Sample(1) }
        \cup { [ZeroFuturesTradeCancellationMessage EXCEPT !.tradeNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Strategy Trade Cancellation Message: 71 bytes                           *)
(***************************************************************************)

StrategyTradeCancellationMessage ==
    [ exchangeId                  : Sample(1),
      symbol                      : Sample(30),
      volume                      : Sample(8),
      tradePriceSign              : Sample(1),
      tradePrice                  : Sample(6),
      tradePriceFractionIndicator : Sample(1),
      filler6                     : Sample(6),
      timestamp                   : Sample(9),
      filler1                     : Sample(1),
      tradeNumber                 : Sample(8) ]

EncodeStrategyTradeCancellationMessage(message) ==
    message.exchangeId
        \o message.symbol
        \o message.volume
        \o message.tradePriceSign
        \o message.tradePrice
        \o message.tradePriceFractionIndicator
        \o message.filler6
        \o message.timestamp
        \o message.filler1
        \o message.tradeNumber

DecodeStrategyTradeCancellationMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET symbol == ReadBytes(exchangeId.rest, 30) IN IF ~symbol.ok THEN Fail ELSE
    LET volume == ReadBytes(symbol.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET tradePriceSign == ReadBytes(volume.rest, 1) IN IF ~tradePriceSign.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(tradePriceSign.rest, 6) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradePriceFractionIndicator == ReadBytes(tradePrice.rest, 1) IN IF ~tradePriceFractionIndicator.ok THEN Fail ELSE
    LET filler6 == ReadBytes(tradePriceFractionIndicator.rest, 6) IN IF ~filler6.ok THEN Fail ELSE
    LET timestamp == ReadBytes(filler6.rest, 9) IN IF ~timestamp.ok THEN Fail ELSE
    LET filler1 == ReadBytes(timestamp.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(filler1.rest, 8) IN IF ~tradeNumber.ok THEN Fail ELSE
    Ok([ exchangeId                  |-> exchangeId.value,
         symbol                      |-> symbol.value,
         volume                      |-> volume.value,
         tradePriceSign              |-> tradePriceSign.value,
         tradePrice                  |-> tradePrice.value,
         tradePriceFractionIndicator |-> tradePriceFractionIndicator.value,
         filler6                     |-> filler6.value,
         timestamp                   |-> timestamp.value,
         filler1                     |-> filler1.value,
         tradeNumber                 |-> tradeNumber.value ], tradeNumber.rest)

ZeroStrategyTradeCancellationMessage ==
    [ exchangeId                  |-> [i \in 1 .. 1 |-> 0],
      symbol                      |-> [i \in 1 .. 30 |-> 0],
      volume                      |-> [i \in 1 .. 8 |-> 0],
      tradePriceSign              |-> [i \in 1 .. 1 |-> 0],
      tradePrice                  |-> [i \in 1 .. 6 |-> 0],
      tradePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      filler6                     |-> [i \in 1 .. 6 |-> 0],
      timestamp                   |-> [i \in 1 .. 9 |-> 0],
      filler1                     |-> [i \in 1 .. 1 |-> 0],
      tradeNumber                 |-> [i \in 1 .. 8 |-> 0] ]

(* Strategy Trade Cancellation Message at zero, then each field in turn at the values it is checked at *)
CheckedStrategyTradeCancellationMessage ==
    { ZeroStrategyTradeCancellationMessage }
        \cup { [ZeroStrategyTradeCancellationMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroStrategyTradeCancellationMessage EXCEPT !.symbol = one] : one \in Sample(30) }
        \cup { [ZeroStrategyTradeCancellationMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroStrategyTradeCancellationMessage EXCEPT !.tradePriceSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategyTradeCancellationMessage EXCEPT !.tradePrice = one] : one \in Sample(6) }
        \cup { [ZeroStrategyTradeCancellationMessage EXCEPT !.tradePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStrategyTradeCancellationMessage EXCEPT !.filler6 = one] : one \in Sample(6) }
        \cup { [ZeroStrategyTradeCancellationMessage EXCEPT !.timestamp = one] : one \in Sample(9) }
        \cup { [ZeroStrategyTradeCancellationMessage EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroStrategyTradeCancellationMessage EXCEPT !.tradeNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Swap Future Trade Cancellation Message: 53 bytes                        *)
(***************************************************************************)

SwapFutureTradeCancellationMessage ==
    [ exchangeId                  : Sample(1),
      rootSymbol                  : Sample(6),
      expiryMonth                 : Sample(1),
      expiryYear                  : Sample(2),
      expiryDay                   : Sample(2),
      tenor                       : Sample(2),
      fixedRate                   : Sample(5),
      fixedRateFractionIndicator  : Sample(1),
      volume                      : Sample(8),
      tradePrice                  : Sample(6),
      tradePriceFractionIndicator : Sample(1),
      timestamp                   : Sample(9),
      marketPriceIndicator        : Sample(1),
      tradeNumber                 : Sample(8) ]

EncodeSwapFutureTradeCancellationMessage(message) ==
    message.exchangeId
        \o message.rootSymbol
        \o message.expiryMonth
        \o message.expiryYear
        \o message.expiryDay
        \o message.tenor
        \o message.fixedRate
        \o message.fixedRateFractionIndicator
        \o message.volume
        \o message.tradePrice
        \o message.tradePriceFractionIndicator
        \o message.timestamp
        \o message.marketPriceIndicator
        \o message.tradeNumber

DecodeSwapFutureTradeCancellationMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET rootSymbol == ReadBytes(exchangeId.rest, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET expiryMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~expiryMonth.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(expiryMonth.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET tenor == ReadBytes(expiryDay.rest, 2) IN IF ~tenor.ok THEN Fail ELSE
    LET fixedRate == ReadBytes(tenor.rest, 5) IN IF ~fixedRate.ok THEN Fail ELSE
    LET fixedRateFractionIndicator == ReadBytes(fixedRate.rest, 1) IN IF ~fixedRateFractionIndicator.ok THEN Fail ELSE
    LET volume == ReadBytes(fixedRateFractionIndicator.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(volume.rest, 6) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradePriceFractionIndicator == ReadBytes(tradePrice.rest, 1) IN IF ~tradePriceFractionIndicator.ok THEN Fail ELSE
    LET timestamp == ReadBytes(tradePriceFractionIndicator.rest, 9) IN IF ~timestamp.ok THEN Fail ELSE
    LET marketPriceIndicator == ReadBytes(timestamp.rest, 1) IN IF ~marketPriceIndicator.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(marketPriceIndicator.rest, 8) IN IF ~tradeNumber.ok THEN Fail ELSE
    Ok([ exchangeId                  |-> exchangeId.value,
         rootSymbol                  |-> rootSymbol.value,
         expiryMonth                 |-> expiryMonth.value,
         expiryYear                  |-> expiryYear.value,
         expiryDay                   |-> expiryDay.value,
         tenor                       |-> tenor.value,
         fixedRate                   |-> fixedRate.value,
         fixedRateFractionIndicator  |-> fixedRateFractionIndicator.value,
         volume                      |-> volume.value,
         tradePrice                  |-> tradePrice.value,
         tradePriceFractionIndicator |-> tradePriceFractionIndicator.value,
         timestamp                   |-> timestamp.value,
         marketPriceIndicator        |-> marketPriceIndicator.value,
         tradeNumber                 |-> tradeNumber.value ], tradeNumber.rest)

ZeroSwapFutureTradeCancellationMessage ==
    [ exchangeId                  |-> [i \in 1 .. 1 |-> 0],
      rootSymbol                  |-> [i \in 1 .. 6 |-> 0],
      expiryMonth                 |-> [i \in 1 .. 1 |-> 0],
      expiryYear                  |-> [i \in 1 .. 2 |-> 0],
      expiryDay                   |-> [i \in 1 .. 2 |-> 0],
      tenor                       |-> [i \in 1 .. 2 |-> 0],
      fixedRate                   |-> [i \in 1 .. 5 |-> 0],
      fixedRateFractionIndicator  |-> [i \in 1 .. 1 |-> 0],
      volume                      |-> [i \in 1 .. 8 |-> 0],
      tradePrice                  |-> [i \in 1 .. 6 |-> 0],
      tradePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      timestamp                   |-> [i \in 1 .. 9 |-> 0],
      marketPriceIndicator        |-> [i \in 1 .. 1 |-> 0],
      tradeNumber                 |-> [i \in 1 .. 8 |-> 0] ]

(* Swap Future Trade Cancellation Message at zero, then each field in turn at the values it is checked at *)
CheckedSwapFutureTradeCancellationMessage ==
    { ZeroSwapFutureTradeCancellationMessage }
        \cup { [ZeroSwapFutureTradeCancellationMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureTradeCancellationMessage EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroSwapFutureTradeCancellationMessage EXCEPT !.expiryMonth = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureTradeCancellationMessage EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroSwapFutureTradeCancellationMessage EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroSwapFutureTradeCancellationMessage EXCEPT !.tenor = one] : one \in Sample(2) }
        \cup { [ZeroSwapFutureTradeCancellationMessage EXCEPT !.fixedRate = one] : one \in Sample(5) }
        \cup { [ZeroSwapFutureTradeCancellationMessage EXCEPT !.fixedRateFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureTradeCancellationMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroSwapFutureTradeCancellationMessage EXCEPT !.tradePrice = one] : one \in Sample(6) }
        \cup { [ZeroSwapFutureTradeCancellationMessage EXCEPT !.tradePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureTradeCancellationMessage EXCEPT !.timestamp = one] : one \in Sample(9) }
        \cup { [ZeroSwapFutureTradeCancellationMessage EXCEPT !.marketPriceIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureTradeCancellationMessage EXCEPT !.tradeNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Option Instrument Keys Message: 127 bytes                               *)
(***************************************************************************)

OptionInstrumentKeysMessage ==
    [ exchangeId                             : Sample(1),
      rootSymbol                             : Sample(6),
      expiryMonth                            : Sample(1),
      filler1                                : Sample(1),
      strikePriceInstrument                  : Sample(7),
      strikePriceFractionIndicator           : Sample(1),
      expiryYear                             : Sample(2),
      expiryDay                              : Sample(2),
      strikePriceCurrency                    : Sample(3),
      maximumNumberOfContractsPerOrder       : Sample(6),
      minimumNumberOfContractsPerOrder       : Sample(6),
      maximumThresholdPriceOptions           : Sample(6),
      maximumThresholdPriceFractionIndicator : Sample(1),
      minimumThresholdPriceOptions           : Sample(6),
      minimumThresholdPriceFractionIndicator : Sample(1),
      tickIncrement                          : Sample(6),
      tickIncrementFractionIndicator         : Sample(1),
      optionType                             : Sample(1),
      marketFlowIndicator                    : Sample(2),
      groupInstrument                        : Sample(2),
      instrument                             : Sample(4),
      instrumentExternalCode                 : Sample(30),
      optionMarker                           : Sample(2),
      underlyingSymbolRootOptions            : Sample(10),
      contractSize                           : Sample(8),
      tickValue                              : Sample(6),
      tickValueFractionIndicator             : Sample(1),
      currency                               : Sample(3),
      deliveryType                           : Sample(1) ]

EncodeOptionInstrumentKeysMessage(message) ==
    message.exchangeId
        \o message.rootSymbol
        \o message.expiryMonth
        \o message.filler1
        \o message.strikePriceInstrument
        \o message.strikePriceFractionIndicator
        \o message.expiryYear
        \o message.expiryDay
        \o message.strikePriceCurrency
        \o message.maximumNumberOfContractsPerOrder
        \o message.minimumNumberOfContractsPerOrder
        \o message.maximumThresholdPriceOptions
        \o message.maximumThresholdPriceFractionIndicator
        \o message.minimumThresholdPriceOptions
        \o message.minimumThresholdPriceFractionIndicator
        \o message.tickIncrement
        \o message.tickIncrementFractionIndicator
        \o message.optionType
        \o message.marketFlowIndicator
        \o message.groupInstrument
        \o message.instrument
        \o message.instrumentExternalCode
        \o message.optionMarker
        \o message.underlyingSymbolRootOptions
        \o message.contractSize
        \o message.tickValue
        \o message.tickValueFractionIndicator
        \o message.currency
        \o message.deliveryType

DecodeOptionInstrumentKeysMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET rootSymbol == ReadBytes(exchangeId.rest, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET expiryMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~expiryMonth.ok THEN Fail ELSE
    LET filler1 == ReadBytes(expiryMonth.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET strikePriceInstrument == ReadBytes(filler1.rest, 7) IN IF ~strikePriceInstrument.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePriceInstrument.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(strikePriceFractionIndicator.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET strikePriceCurrency == ReadBytes(expiryDay.rest, 3) IN IF ~strikePriceCurrency.ok THEN Fail ELSE
    LET maximumNumberOfContractsPerOrder == ReadBytes(strikePriceCurrency.rest, 6) IN IF ~maximumNumberOfContractsPerOrder.ok THEN Fail ELSE
    LET minimumNumberOfContractsPerOrder == ReadBytes(maximumNumberOfContractsPerOrder.rest, 6) IN IF ~minimumNumberOfContractsPerOrder.ok THEN Fail ELSE
    LET maximumThresholdPriceOptions == ReadBytes(minimumNumberOfContractsPerOrder.rest, 6) IN IF ~maximumThresholdPriceOptions.ok THEN Fail ELSE
    LET maximumThresholdPriceFractionIndicator == ReadBytes(maximumThresholdPriceOptions.rest, 1) IN IF ~maximumThresholdPriceFractionIndicator.ok THEN Fail ELSE
    LET minimumThresholdPriceOptions == ReadBytes(maximumThresholdPriceFractionIndicator.rest, 6) IN IF ~minimumThresholdPriceOptions.ok THEN Fail ELSE
    LET minimumThresholdPriceFractionIndicator == ReadBytes(minimumThresholdPriceOptions.rest, 1) IN IF ~minimumThresholdPriceFractionIndicator.ok THEN Fail ELSE
    LET tickIncrement == ReadBytes(minimumThresholdPriceFractionIndicator.rest, 6) IN IF ~tickIncrement.ok THEN Fail ELSE
    LET tickIncrementFractionIndicator == ReadBytes(tickIncrement.rest, 1) IN IF ~tickIncrementFractionIndicator.ok THEN Fail ELSE
    LET optionType == ReadBytes(tickIncrementFractionIndicator.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET marketFlowIndicator == ReadBytes(optionType.rest, 2) IN IF ~marketFlowIndicator.ok THEN Fail ELSE
    LET groupInstrument == ReadBytes(marketFlowIndicator.rest, 2) IN IF ~groupInstrument.ok THEN Fail ELSE
    LET instrument == ReadBytes(groupInstrument.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET instrumentExternalCode == ReadBytes(instrument.rest, 30) IN IF ~instrumentExternalCode.ok THEN Fail ELSE
    LET optionMarker == ReadBytes(instrumentExternalCode.rest, 2) IN IF ~optionMarker.ok THEN Fail ELSE
    LET underlyingSymbolRootOptions == ReadBytes(optionMarker.rest, 10) IN IF ~underlyingSymbolRootOptions.ok THEN Fail ELSE
    LET contractSize == ReadBytes(underlyingSymbolRootOptions.rest, 8) IN IF ~contractSize.ok THEN Fail ELSE
    LET tickValue == ReadBytes(contractSize.rest, 6) IN IF ~tickValue.ok THEN Fail ELSE
    LET tickValueFractionIndicator == ReadBytes(tickValue.rest, 1) IN IF ~tickValueFractionIndicator.ok THEN Fail ELSE
    LET currency == ReadBytes(tickValueFractionIndicator.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET deliveryType == ReadBytes(currency.rest, 1) IN IF ~deliveryType.ok THEN Fail ELSE
    Ok([ exchangeId                             |-> exchangeId.value,
         rootSymbol                             |-> rootSymbol.value,
         expiryMonth                            |-> expiryMonth.value,
         filler1                                |-> filler1.value,
         strikePriceInstrument                  |-> strikePriceInstrument.value,
         strikePriceFractionIndicator           |-> strikePriceFractionIndicator.value,
         expiryYear                             |-> expiryYear.value,
         expiryDay                              |-> expiryDay.value,
         strikePriceCurrency                    |-> strikePriceCurrency.value,
         maximumNumberOfContractsPerOrder       |-> maximumNumberOfContractsPerOrder.value,
         minimumNumberOfContractsPerOrder       |-> minimumNumberOfContractsPerOrder.value,
         maximumThresholdPriceOptions           |-> maximumThresholdPriceOptions.value,
         maximumThresholdPriceFractionIndicator |-> maximumThresholdPriceFractionIndicator.value,
         minimumThresholdPriceOptions           |-> minimumThresholdPriceOptions.value,
         minimumThresholdPriceFractionIndicator |-> minimumThresholdPriceFractionIndicator.value,
         tickIncrement                          |-> tickIncrement.value,
         tickIncrementFractionIndicator         |-> tickIncrementFractionIndicator.value,
         optionType                             |-> optionType.value,
         marketFlowIndicator                    |-> marketFlowIndicator.value,
         groupInstrument                        |-> groupInstrument.value,
         instrument                             |-> instrument.value,
         instrumentExternalCode                 |-> instrumentExternalCode.value,
         optionMarker                           |-> optionMarker.value,
         underlyingSymbolRootOptions            |-> underlyingSymbolRootOptions.value,
         contractSize                           |-> contractSize.value,
         tickValue                              |-> tickValue.value,
         tickValueFractionIndicator             |-> tickValueFractionIndicator.value,
         currency                               |-> currency.value,
         deliveryType                           |-> deliveryType.value ], deliveryType.rest)

ZeroOptionInstrumentKeysMessage ==
    [ exchangeId                             |-> [i \in 1 .. 1 |-> 0],
      rootSymbol                             |-> [i \in 1 .. 6 |-> 0],
      expiryMonth                            |-> [i \in 1 .. 1 |-> 0],
      filler1                                |-> [i \in 1 .. 1 |-> 0],
      strikePriceInstrument                  |-> [i \in 1 .. 7 |-> 0],
      strikePriceFractionIndicator           |-> [i \in 1 .. 1 |-> 0],
      expiryYear                             |-> [i \in 1 .. 2 |-> 0],
      expiryDay                              |-> [i \in 1 .. 2 |-> 0],
      strikePriceCurrency                    |-> [i \in 1 .. 3 |-> 0],
      maximumNumberOfContractsPerOrder       |-> [i \in 1 .. 6 |-> 0],
      minimumNumberOfContractsPerOrder       |-> [i \in 1 .. 6 |-> 0],
      maximumThresholdPriceOptions           |-> [i \in 1 .. 6 |-> 0],
      maximumThresholdPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      minimumThresholdPriceOptions           |-> [i \in 1 .. 6 |-> 0],
      minimumThresholdPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      tickIncrement                          |-> [i \in 1 .. 6 |-> 0],
      tickIncrementFractionIndicator         |-> [i \in 1 .. 1 |-> 0],
      optionType                             |-> [i \in 1 .. 1 |-> 0],
      marketFlowIndicator                    |-> [i \in 1 .. 2 |-> 0],
      groupInstrument                        |-> [i \in 1 .. 2 |-> 0],
      instrument                             |-> [i \in 1 .. 4 |-> 0],
      instrumentExternalCode                 |-> [i \in 1 .. 30 |-> 0],
      optionMarker                           |-> [i \in 1 .. 2 |-> 0],
      underlyingSymbolRootOptions            |-> [i \in 1 .. 10 |-> 0],
      contractSize                           |-> [i \in 1 .. 8 |-> 0],
      tickValue                              |-> [i \in 1 .. 6 |-> 0],
      tickValueFractionIndicator             |-> [i \in 1 .. 1 |-> 0],
      currency                               |-> [i \in 1 .. 3 |-> 0],
      deliveryType                           |-> [i \in 1 .. 1 |-> 0] ]

(* Option Instrument Keys Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionInstrumentKeysMessage ==
    { ZeroOptionInstrumentKeysMessage }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.expiryMonth = one] : one \in Sample(1) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.strikePriceInstrument = one] : one \in Sample(7) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.strikePriceCurrency = one] : one \in Sample(3) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.maximumNumberOfContractsPerOrder = one] : one \in Sample(6) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.minimumNumberOfContractsPerOrder = one] : one \in Sample(6) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.maximumThresholdPriceOptions = one] : one \in Sample(6) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.maximumThresholdPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.minimumThresholdPriceOptions = one] : one \in Sample(6) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.minimumThresholdPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.tickIncrement = one] : one \in Sample(6) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.tickIncrementFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.marketFlowIndicator = one] : one \in Sample(2) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.groupInstrument = one] : one \in Sample(2) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.instrumentExternalCode = one] : one \in Sample(30) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.optionMarker = one] : one \in Sample(2) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.underlyingSymbolRootOptions = one] : one \in Sample(10) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.contractSize = one] : one \in Sample(8) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.tickValue = one] : one \in Sample(6) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.tickValueFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.deliveryType = one] : one \in Sample(1) }

(***************************************************************************)
(* Future Options Instrument Keys Message: 114 bytes                       *)
(***************************************************************************)

FutureOptionsInstrumentKeysMessage ==
    [ exchangeId                             : Sample(1),
      rootSymbol                             : Sample(6),
      contractMonthCode                      : Sample(1),
      expiryYear                             : Sample(2),
      expiryDay                              : Sample(2),
      callPutCode                            : Sample(1),
      strikePriceInstrument                  : Sample(7),
      strikePriceFractionIndicator           : Sample(1),
      strikePriceCurrency                    : Sample(3),
      maximumNumberOfContractsPerOrder       : Sample(6),
      minimumNumberOfContractsPerOrder       : Sample(6),
      maximumThresholdPriceOptions           : Sample(6),
      maximumThresholdPriceFractionIndicator : Sample(1),
      minimumThresholdPriceOptions           : Sample(6),
      minimumThresholdPriceFractionIndicator : Sample(1),
      tickIncrement                          : Sample(6),
      tickIncrementFractionIndicator         : Sample(1),
      marketFlowIndicator                    : Sample(2),
      groupInstrument                        : Sample(2),
      instrument                             : Sample(4),
      instrumentExternalCode                 : Sample(30),
      contractSize                           : Sample(8),
      tickValue                              : Sample(6),
      tickValueFractionIndicator             : Sample(1),
      currency                               : Sample(3),
      deliveryType                           : Sample(1) ]

EncodeFutureOptionsInstrumentKeysMessage(message) ==
    message.exchangeId
        \o message.rootSymbol
        \o message.contractMonthCode
        \o message.expiryYear
        \o message.expiryDay
        \o message.callPutCode
        \o message.strikePriceInstrument
        \o message.strikePriceFractionIndicator
        \o message.strikePriceCurrency
        \o message.maximumNumberOfContractsPerOrder
        \o message.minimumNumberOfContractsPerOrder
        \o message.maximumThresholdPriceOptions
        \o message.maximumThresholdPriceFractionIndicator
        \o message.minimumThresholdPriceOptions
        \o message.minimumThresholdPriceFractionIndicator
        \o message.tickIncrement
        \o message.tickIncrementFractionIndicator
        \o message.marketFlowIndicator
        \o message.groupInstrument
        \o message.instrument
        \o message.instrumentExternalCode
        \o message.contractSize
        \o message.tickValue
        \o message.tickValueFractionIndicator
        \o message.currency
        \o message.deliveryType

DecodeFutureOptionsInstrumentKeysMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET rootSymbol == ReadBytes(exchangeId.rest, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET contractMonthCode == ReadBytes(rootSymbol.rest, 1) IN IF ~contractMonthCode.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(contractMonthCode.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET callPutCode == ReadBytes(expiryDay.rest, 1) IN IF ~callPutCode.ok THEN Fail ELSE
    LET strikePriceInstrument == ReadBytes(callPutCode.rest, 7) IN IF ~strikePriceInstrument.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePriceInstrument.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    LET strikePriceCurrency == ReadBytes(strikePriceFractionIndicator.rest, 3) IN IF ~strikePriceCurrency.ok THEN Fail ELSE
    LET maximumNumberOfContractsPerOrder == ReadBytes(strikePriceCurrency.rest, 6) IN IF ~maximumNumberOfContractsPerOrder.ok THEN Fail ELSE
    LET minimumNumberOfContractsPerOrder == ReadBytes(maximumNumberOfContractsPerOrder.rest, 6) IN IF ~minimumNumberOfContractsPerOrder.ok THEN Fail ELSE
    LET maximumThresholdPriceOptions == ReadBytes(minimumNumberOfContractsPerOrder.rest, 6) IN IF ~maximumThresholdPriceOptions.ok THEN Fail ELSE
    LET maximumThresholdPriceFractionIndicator == ReadBytes(maximumThresholdPriceOptions.rest, 1) IN IF ~maximumThresholdPriceFractionIndicator.ok THEN Fail ELSE
    LET minimumThresholdPriceOptions == ReadBytes(maximumThresholdPriceFractionIndicator.rest, 6) IN IF ~minimumThresholdPriceOptions.ok THEN Fail ELSE
    LET minimumThresholdPriceFractionIndicator == ReadBytes(minimumThresholdPriceOptions.rest, 1) IN IF ~minimumThresholdPriceFractionIndicator.ok THEN Fail ELSE
    LET tickIncrement == ReadBytes(minimumThresholdPriceFractionIndicator.rest, 6) IN IF ~tickIncrement.ok THEN Fail ELSE
    LET tickIncrementFractionIndicator == ReadBytes(tickIncrement.rest, 1) IN IF ~tickIncrementFractionIndicator.ok THEN Fail ELSE
    LET marketFlowIndicator == ReadBytes(tickIncrementFractionIndicator.rest, 2) IN IF ~marketFlowIndicator.ok THEN Fail ELSE
    LET groupInstrument == ReadBytes(marketFlowIndicator.rest, 2) IN IF ~groupInstrument.ok THEN Fail ELSE
    LET instrument == ReadBytes(groupInstrument.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET instrumentExternalCode == ReadBytes(instrument.rest, 30) IN IF ~instrumentExternalCode.ok THEN Fail ELSE
    LET contractSize == ReadBytes(instrumentExternalCode.rest, 8) IN IF ~contractSize.ok THEN Fail ELSE
    LET tickValue == ReadBytes(contractSize.rest, 6) IN IF ~tickValue.ok THEN Fail ELSE
    LET tickValueFractionIndicator == ReadBytes(tickValue.rest, 1) IN IF ~tickValueFractionIndicator.ok THEN Fail ELSE
    LET currency == ReadBytes(tickValueFractionIndicator.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET deliveryType == ReadBytes(currency.rest, 1) IN IF ~deliveryType.ok THEN Fail ELSE
    Ok([ exchangeId                             |-> exchangeId.value,
         rootSymbol                             |-> rootSymbol.value,
         contractMonthCode                      |-> contractMonthCode.value,
         expiryYear                             |-> expiryYear.value,
         expiryDay                              |-> expiryDay.value,
         callPutCode                            |-> callPutCode.value,
         strikePriceInstrument                  |-> strikePriceInstrument.value,
         strikePriceFractionIndicator           |-> strikePriceFractionIndicator.value,
         strikePriceCurrency                    |-> strikePriceCurrency.value,
         maximumNumberOfContractsPerOrder       |-> maximumNumberOfContractsPerOrder.value,
         minimumNumberOfContractsPerOrder       |-> minimumNumberOfContractsPerOrder.value,
         maximumThresholdPriceOptions           |-> maximumThresholdPriceOptions.value,
         maximumThresholdPriceFractionIndicator |-> maximumThresholdPriceFractionIndicator.value,
         minimumThresholdPriceOptions           |-> minimumThresholdPriceOptions.value,
         minimumThresholdPriceFractionIndicator |-> minimumThresholdPriceFractionIndicator.value,
         tickIncrement                          |-> tickIncrement.value,
         tickIncrementFractionIndicator         |-> tickIncrementFractionIndicator.value,
         marketFlowIndicator                    |-> marketFlowIndicator.value,
         groupInstrument                        |-> groupInstrument.value,
         instrument                             |-> instrument.value,
         instrumentExternalCode                 |-> instrumentExternalCode.value,
         contractSize                           |-> contractSize.value,
         tickValue                              |-> tickValue.value,
         tickValueFractionIndicator             |-> tickValueFractionIndicator.value,
         currency                               |-> currency.value,
         deliveryType                           |-> deliveryType.value ], deliveryType.rest)

ZeroFutureOptionsInstrumentKeysMessage ==
    [ exchangeId                             |-> [i \in 1 .. 1 |-> 0],
      rootSymbol                             |-> [i \in 1 .. 6 |-> 0],
      contractMonthCode                      |-> [i \in 1 .. 1 |-> 0],
      expiryYear                             |-> [i \in 1 .. 2 |-> 0],
      expiryDay                              |-> [i \in 1 .. 2 |-> 0],
      callPutCode                            |-> [i \in 1 .. 1 |-> 0],
      strikePriceInstrument                  |-> [i \in 1 .. 7 |-> 0],
      strikePriceFractionIndicator           |-> [i \in 1 .. 1 |-> 0],
      strikePriceCurrency                    |-> [i \in 1 .. 3 |-> 0],
      maximumNumberOfContractsPerOrder       |-> [i \in 1 .. 6 |-> 0],
      minimumNumberOfContractsPerOrder       |-> [i \in 1 .. 6 |-> 0],
      maximumThresholdPriceOptions           |-> [i \in 1 .. 6 |-> 0],
      maximumThresholdPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      minimumThresholdPriceOptions           |-> [i \in 1 .. 6 |-> 0],
      minimumThresholdPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      tickIncrement                          |-> [i \in 1 .. 6 |-> 0],
      tickIncrementFractionIndicator         |-> [i \in 1 .. 1 |-> 0],
      marketFlowIndicator                    |-> [i \in 1 .. 2 |-> 0],
      groupInstrument                        |-> [i \in 1 .. 2 |-> 0],
      instrument                             |-> [i \in 1 .. 4 |-> 0],
      instrumentExternalCode                 |-> [i \in 1 .. 30 |-> 0],
      contractSize                           |-> [i \in 1 .. 8 |-> 0],
      tickValue                              |-> [i \in 1 .. 6 |-> 0],
      tickValueFractionIndicator             |-> [i \in 1 .. 1 |-> 0],
      currency                               |-> [i \in 1 .. 3 |-> 0],
      deliveryType                           |-> [i \in 1 .. 1 |-> 0] ]

(* Future Options Instrument Keys Message at zero, then each field in turn at the values it is checked at *)
CheckedFutureOptionsInstrumentKeysMessage ==
    { ZeroFutureOptionsInstrumentKeysMessage }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.contractMonthCode = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.callPutCode = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.strikePriceInstrument = one] : one \in Sample(7) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.strikePriceCurrency = one] : one \in Sample(3) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.maximumNumberOfContractsPerOrder = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.minimumNumberOfContractsPerOrder = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.maximumThresholdPriceOptions = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.maximumThresholdPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.minimumThresholdPriceOptions = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.minimumThresholdPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.tickIncrement = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.tickIncrementFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.marketFlowIndicator = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.groupInstrument = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.instrumentExternalCode = one] : one \in Sample(30) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.contractSize = one] : one \in Sample(8) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.tickValue = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.tickValueFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.deliveryType = one] : one \in Sample(1) }

(***************************************************************************)
(* Underlying Instrument Keys Message: 37 bytes                            *)
(***************************************************************************)

UnderlyingInstrumentKeysMessage ==
    [ exchangeId             : Sample(1),
      groupInstrument        : Sample(2),
      instrument             : Sample(4),
      instrumentExternalCode : Sample(30) ]

EncodeUnderlyingInstrumentKeysMessage(message) ==
    message.exchangeId
        \o message.groupInstrument
        \o message.instrument
        \o message.instrumentExternalCode

DecodeUnderlyingInstrumentKeysMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET groupInstrument == ReadBytes(exchangeId.rest, 2) IN IF ~groupInstrument.ok THEN Fail ELSE
    LET instrument == ReadBytes(groupInstrument.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET instrumentExternalCode == ReadBytes(instrument.rest, 30) IN IF ~instrumentExternalCode.ok THEN Fail ELSE
    Ok([ exchangeId             |-> exchangeId.value,
         groupInstrument        |-> groupInstrument.value,
         instrument             |-> instrument.value,
         instrumentExternalCode |-> instrumentExternalCode.value ], instrumentExternalCode.rest)

ZeroUnderlyingInstrumentKeysMessage ==
    [ exchangeId             |-> [i \in 1 .. 1 |-> 0],
      groupInstrument        |-> [i \in 1 .. 2 |-> 0],
      instrument             |-> [i \in 1 .. 4 |-> 0],
      instrumentExternalCode |-> [i \in 1 .. 30 |-> 0] ]

(* Underlying Instrument Keys Message at zero, then each field in turn at the values it is checked at *)
CheckedUnderlyingInstrumentKeysMessage ==
    { ZeroUnderlyingInstrumentKeysMessage }
        \cup { [ZeroUnderlyingInstrumentKeysMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingInstrumentKeysMessage EXCEPT !.groupInstrument = one] : one \in Sample(2) }
        \cup { [ZeroUnderlyingInstrumentKeysMessage EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingInstrumentKeysMessage EXCEPT !.instrumentExternalCode = one] : one \in Sample(30) }

(***************************************************************************)
(* Futures Instrument Keys Message: 123 bytes                              *)
(***************************************************************************)

FuturesInstrumentKeysMessage ==
    [ exchangeId                             : Sample(1),
      rootSymbol                             : Sample(6),
      deliveryMonth                          : Sample(1),
      deliveryYearFutures                    : Sample(2),
      expiryDay                              : Sample(2),
      maximumNumberOfContractsPerOrder       : Sample(6),
      minimumNumberOfContractsPerOrder       : Sample(6),
      maximumThresholdPriceFutures           : Sample(6),
      maximumThresholdPriceFractionIndicator : Sample(1),
      minimumThresholdPriceFutures           : Sample(6),
      minimumThresholdPriceFractionIndicator : Sample(1),
      tickIncrement                          : Sample(6),
      tickIncrementFractionIndicator         : Sample(1),
      marketFlowIndicator                    : Sample(2),
      groupInstrument                        : Sample(2),
      instrument                             : Sample(4),
      instrumentExternalCode                 : Sample(30),
      contractSize                           : Sample(8),
      tickValue                              : Sample(6),
      tickValueFractionIndicator             : Sample(1),
      currency                               : Sample(3),
      underlyingSymbol                       : Sample(10),
      deliveryType                           : Sample(1),
      associatedProductRootSymbol            : Sample(6),
      associatedProductDeliveryMonth         : Sample(1),
      associatedProductDeliveryYear          : Sample(2),
      associatedProductExpiryDay             : Sample(2) ]

EncodeFuturesInstrumentKeysMessage(message) ==
    message.exchangeId
        \o message.rootSymbol
        \o message.deliveryMonth
        \o message.deliveryYearFutures
        \o message.expiryDay
        \o message.maximumNumberOfContractsPerOrder
        \o message.minimumNumberOfContractsPerOrder
        \o message.maximumThresholdPriceFutures
        \o message.maximumThresholdPriceFractionIndicator
        \o message.minimumThresholdPriceFutures
        \o message.minimumThresholdPriceFractionIndicator
        \o message.tickIncrement
        \o message.tickIncrementFractionIndicator
        \o message.marketFlowIndicator
        \o message.groupInstrument
        \o message.instrument
        \o message.instrumentExternalCode
        \o message.contractSize
        \o message.tickValue
        \o message.tickValueFractionIndicator
        \o message.currency
        \o message.underlyingSymbol
        \o message.deliveryType
        \o message.associatedProductRootSymbol
        \o message.associatedProductDeliveryMonth
        \o message.associatedProductDeliveryYear
        \o message.associatedProductExpiryDay

DecodeFuturesInstrumentKeysMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET rootSymbol == ReadBytes(exchangeId.rest, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET deliveryMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~deliveryMonth.ok THEN Fail ELSE
    LET deliveryYearFutures == ReadBytes(deliveryMonth.rest, 2) IN IF ~deliveryYearFutures.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(deliveryYearFutures.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET maximumNumberOfContractsPerOrder == ReadBytes(expiryDay.rest, 6) IN IF ~maximumNumberOfContractsPerOrder.ok THEN Fail ELSE
    LET minimumNumberOfContractsPerOrder == ReadBytes(maximumNumberOfContractsPerOrder.rest, 6) IN IF ~minimumNumberOfContractsPerOrder.ok THEN Fail ELSE
    LET maximumThresholdPriceFutures == ReadBytes(minimumNumberOfContractsPerOrder.rest, 6) IN IF ~maximumThresholdPriceFutures.ok THEN Fail ELSE
    LET maximumThresholdPriceFractionIndicator == ReadBytes(maximumThresholdPriceFutures.rest, 1) IN IF ~maximumThresholdPriceFractionIndicator.ok THEN Fail ELSE
    LET minimumThresholdPriceFutures == ReadBytes(maximumThresholdPriceFractionIndicator.rest, 6) IN IF ~minimumThresholdPriceFutures.ok THEN Fail ELSE
    LET minimumThresholdPriceFractionIndicator == ReadBytes(minimumThresholdPriceFutures.rest, 1) IN IF ~minimumThresholdPriceFractionIndicator.ok THEN Fail ELSE
    LET tickIncrement == ReadBytes(minimumThresholdPriceFractionIndicator.rest, 6) IN IF ~tickIncrement.ok THEN Fail ELSE
    LET tickIncrementFractionIndicator == ReadBytes(tickIncrement.rest, 1) IN IF ~tickIncrementFractionIndicator.ok THEN Fail ELSE
    LET marketFlowIndicator == ReadBytes(tickIncrementFractionIndicator.rest, 2) IN IF ~marketFlowIndicator.ok THEN Fail ELSE
    LET groupInstrument == ReadBytes(marketFlowIndicator.rest, 2) IN IF ~groupInstrument.ok THEN Fail ELSE
    LET instrument == ReadBytes(groupInstrument.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET instrumentExternalCode == ReadBytes(instrument.rest, 30) IN IF ~instrumentExternalCode.ok THEN Fail ELSE
    LET contractSize == ReadBytes(instrumentExternalCode.rest, 8) IN IF ~contractSize.ok THEN Fail ELSE
    LET tickValue == ReadBytes(contractSize.rest, 6) IN IF ~tickValue.ok THEN Fail ELSE
    LET tickValueFractionIndicator == ReadBytes(tickValue.rest, 1) IN IF ~tickValueFractionIndicator.ok THEN Fail ELSE
    LET currency == ReadBytes(tickValueFractionIndicator.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(currency.rest, 10) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET deliveryType == ReadBytes(underlyingSymbol.rest, 1) IN IF ~deliveryType.ok THEN Fail ELSE
    LET associatedProductRootSymbol == ReadBytes(deliveryType.rest, 6) IN IF ~associatedProductRootSymbol.ok THEN Fail ELSE
    LET associatedProductDeliveryMonth == ReadBytes(associatedProductRootSymbol.rest, 1) IN IF ~associatedProductDeliveryMonth.ok THEN Fail ELSE
    LET associatedProductDeliveryYear == ReadBytes(associatedProductDeliveryMonth.rest, 2) IN IF ~associatedProductDeliveryYear.ok THEN Fail ELSE
    LET associatedProductExpiryDay == ReadBytes(associatedProductDeliveryYear.rest, 2) IN IF ~associatedProductExpiryDay.ok THEN Fail ELSE
    Ok([ exchangeId                             |-> exchangeId.value,
         rootSymbol                             |-> rootSymbol.value,
         deliveryMonth                          |-> deliveryMonth.value,
         deliveryYearFutures                    |-> deliveryYearFutures.value,
         expiryDay                              |-> expiryDay.value,
         maximumNumberOfContractsPerOrder       |-> maximumNumberOfContractsPerOrder.value,
         minimumNumberOfContractsPerOrder       |-> minimumNumberOfContractsPerOrder.value,
         maximumThresholdPriceFutures           |-> maximumThresholdPriceFutures.value,
         maximumThresholdPriceFractionIndicator |-> maximumThresholdPriceFractionIndicator.value,
         minimumThresholdPriceFutures           |-> minimumThresholdPriceFutures.value,
         minimumThresholdPriceFractionIndicator |-> minimumThresholdPriceFractionIndicator.value,
         tickIncrement                          |-> tickIncrement.value,
         tickIncrementFractionIndicator         |-> tickIncrementFractionIndicator.value,
         marketFlowIndicator                    |-> marketFlowIndicator.value,
         groupInstrument                        |-> groupInstrument.value,
         instrument                             |-> instrument.value,
         instrumentExternalCode                 |-> instrumentExternalCode.value,
         contractSize                           |-> contractSize.value,
         tickValue                              |-> tickValue.value,
         tickValueFractionIndicator             |-> tickValueFractionIndicator.value,
         currency                               |-> currency.value,
         underlyingSymbol                       |-> underlyingSymbol.value,
         deliveryType                           |-> deliveryType.value,
         associatedProductRootSymbol            |-> associatedProductRootSymbol.value,
         associatedProductDeliveryMonth         |-> associatedProductDeliveryMonth.value,
         associatedProductDeliveryYear          |-> associatedProductDeliveryYear.value,
         associatedProductExpiryDay             |-> associatedProductExpiryDay.value ], associatedProductExpiryDay.rest)

ZeroFuturesInstrumentKeysMessage ==
    [ exchangeId                             |-> [i \in 1 .. 1 |-> 0],
      rootSymbol                             |-> [i \in 1 .. 6 |-> 0],
      deliveryMonth                          |-> [i \in 1 .. 1 |-> 0],
      deliveryYearFutures                    |-> [i \in 1 .. 2 |-> 0],
      expiryDay                              |-> [i \in 1 .. 2 |-> 0],
      maximumNumberOfContractsPerOrder       |-> [i \in 1 .. 6 |-> 0],
      minimumNumberOfContractsPerOrder       |-> [i \in 1 .. 6 |-> 0],
      maximumThresholdPriceFutures           |-> [i \in 1 .. 6 |-> 0],
      maximumThresholdPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      minimumThresholdPriceFutures           |-> [i \in 1 .. 6 |-> 0],
      minimumThresholdPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      tickIncrement                          |-> [i \in 1 .. 6 |-> 0],
      tickIncrementFractionIndicator         |-> [i \in 1 .. 1 |-> 0],
      marketFlowIndicator                    |-> [i \in 1 .. 2 |-> 0],
      groupInstrument                        |-> [i \in 1 .. 2 |-> 0],
      instrument                             |-> [i \in 1 .. 4 |-> 0],
      instrumentExternalCode                 |-> [i \in 1 .. 30 |-> 0],
      contractSize                           |-> [i \in 1 .. 8 |-> 0],
      tickValue                              |-> [i \in 1 .. 6 |-> 0],
      tickValueFractionIndicator             |-> [i \in 1 .. 1 |-> 0],
      currency                               |-> [i \in 1 .. 3 |-> 0],
      underlyingSymbol                       |-> [i \in 1 .. 10 |-> 0],
      deliveryType                           |-> [i \in 1 .. 1 |-> 0],
      associatedProductRootSymbol            |-> [i \in 1 .. 6 |-> 0],
      associatedProductDeliveryMonth         |-> [i \in 1 .. 1 |-> 0],
      associatedProductDeliveryYear          |-> [i \in 1 .. 2 |-> 0],
      associatedProductExpiryDay             |-> [i \in 1 .. 2 |-> 0] ]

(* Futures Instrument Keys Message at zero, then each field in turn at the values it is checked at *)
CheckedFuturesInstrumentKeysMessage ==
    { ZeroFuturesInstrumentKeysMessage }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.deliveryMonth = one] : one \in Sample(1) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.deliveryYearFutures = one] : one \in Sample(2) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.maximumNumberOfContractsPerOrder = one] : one \in Sample(6) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.minimumNumberOfContractsPerOrder = one] : one \in Sample(6) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.maximumThresholdPriceFutures = one] : one \in Sample(6) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.maximumThresholdPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.minimumThresholdPriceFutures = one] : one \in Sample(6) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.minimumThresholdPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.tickIncrement = one] : one \in Sample(6) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.tickIncrementFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.marketFlowIndicator = one] : one \in Sample(2) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.groupInstrument = one] : one \in Sample(2) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.instrumentExternalCode = one] : one \in Sample(30) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.contractSize = one] : one \in Sample(8) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.tickValue = one] : one \in Sample(6) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.tickValueFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(10) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.deliveryType = one] : one \in Sample(1) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.associatedProductRootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.associatedProductDeliveryMonth = one] : one \in Sample(1) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.associatedProductDeliveryYear = one] : one \in Sample(2) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.associatedProductExpiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Strategy Instrument Keys Message: 108 bytes                             *)
(***************************************************************************)

StrategyInstrumentKeysMessage ==
    [ exchangeId                             : Sample(1),
      strategySymbol                         : Sample(30),
      expiryYear                             : Sample(2),
      deliveryMonth                          : Sample(1),
      expiryDay                              : Sample(2),
      maximumNumberOfContractsPerOrder       : Sample(6),
      minimumNumberOfContractsPerOrder       : Sample(6),
      maximumThresholdPriceOptions           : Sample(6),
      maximumThresholdPriceFractionIndicator : Sample(1),
      minimumThresholdPriceOptions           : Sample(6),
      minimumThresholdPriceFractionIndicator : Sample(1),
      tickIncrement                          : Sample(6),
      tickIncrementFractionIndicator         : Sample(1),
      marketFlowIndicator                    : Sample(2),
      groupInstrument                        : Sample(2),
      instrument                             : Sample(4),
      instrumentExternalCode                 : Sample(30),
      strategyAllowImplied                   : Sample(1) ]

EncodeStrategyInstrumentKeysMessage(message) ==
    message.exchangeId
        \o message.strategySymbol
        \o message.expiryYear
        \o message.deliveryMonth
        \o message.expiryDay
        \o message.maximumNumberOfContractsPerOrder
        \o message.minimumNumberOfContractsPerOrder
        \o message.maximumThresholdPriceOptions
        \o message.maximumThresholdPriceFractionIndicator
        \o message.minimumThresholdPriceOptions
        \o message.minimumThresholdPriceFractionIndicator
        \o message.tickIncrement
        \o message.tickIncrementFractionIndicator
        \o message.marketFlowIndicator
        \o message.groupInstrument
        \o message.instrument
        \o message.instrumentExternalCode
        \o message.strategyAllowImplied

DecodeStrategyInstrumentKeysMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET strategySymbol == ReadBytes(exchangeId.rest, 30) IN IF ~strategySymbol.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(strategySymbol.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET deliveryMonth == ReadBytes(expiryYear.rest, 1) IN IF ~deliveryMonth.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(deliveryMonth.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET maximumNumberOfContractsPerOrder == ReadBytes(expiryDay.rest, 6) IN IF ~maximumNumberOfContractsPerOrder.ok THEN Fail ELSE
    LET minimumNumberOfContractsPerOrder == ReadBytes(maximumNumberOfContractsPerOrder.rest, 6) IN IF ~minimumNumberOfContractsPerOrder.ok THEN Fail ELSE
    LET maximumThresholdPriceOptions == ReadBytes(minimumNumberOfContractsPerOrder.rest, 6) IN IF ~maximumThresholdPriceOptions.ok THEN Fail ELSE
    LET maximumThresholdPriceFractionIndicator == ReadBytes(maximumThresholdPriceOptions.rest, 1) IN IF ~maximumThresholdPriceFractionIndicator.ok THEN Fail ELSE
    LET minimumThresholdPriceOptions == ReadBytes(maximumThresholdPriceFractionIndicator.rest, 6) IN IF ~minimumThresholdPriceOptions.ok THEN Fail ELSE
    LET minimumThresholdPriceFractionIndicator == ReadBytes(minimumThresholdPriceOptions.rest, 1) IN IF ~minimumThresholdPriceFractionIndicator.ok THEN Fail ELSE
    LET tickIncrement == ReadBytes(minimumThresholdPriceFractionIndicator.rest, 6) IN IF ~tickIncrement.ok THEN Fail ELSE
    LET tickIncrementFractionIndicator == ReadBytes(tickIncrement.rest, 1) IN IF ~tickIncrementFractionIndicator.ok THEN Fail ELSE
    LET marketFlowIndicator == ReadBytes(tickIncrementFractionIndicator.rest, 2) IN IF ~marketFlowIndicator.ok THEN Fail ELSE
    LET groupInstrument == ReadBytes(marketFlowIndicator.rest, 2) IN IF ~groupInstrument.ok THEN Fail ELSE
    LET instrument == ReadBytes(groupInstrument.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET instrumentExternalCode == ReadBytes(instrument.rest, 30) IN IF ~instrumentExternalCode.ok THEN Fail ELSE
    LET strategyAllowImplied == ReadBytes(instrumentExternalCode.rest, 1) IN IF ~strategyAllowImplied.ok THEN Fail ELSE
    Ok([ exchangeId                             |-> exchangeId.value,
         strategySymbol                         |-> strategySymbol.value,
         expiryYear                             |-> expiryYear.value,
         deliveryMonth                          |-> deliveryMonth.value,
         expiryDay                              |-> expiryDay.value,
         maximumNumberOfContractsPerOrder       |-> maximumNumberOfContractsPerOrder.value,
         minimumNumberOfContractsPerOrder       |-> minimumNumberOfContractsPerOrder.value,
         maximumThresholdPriceOptions           |-> maximumThresholdPriceOptions.value,
         maximumThresholdPriceFractionIndicator |-> maximumThresholdPriceFractionIndicator.value,
         minimumThresholdPriceOptions           |-> minimumThresholdPriceOptions.value,
         minimumThresholdPriceFractionIndicator |-> minimumThresholdPriceFractionIndicator.value,
         tickIncrement                          |-> tickIncrement.value,
         tickIncrementFractionIndicator         |-> tickIncrementFractionIndicator.value,
         marketFlowIndicator                    |-> marketFlowIndicator.value,
         groupInstrument                        |-> groupInstrument.value,
         instrument                             |-> instrument.value,
         instrumentExternalCode                 |-> instrumentExternalCode.value,
         strategyAllowImplied                   |-> strategyAllowImplied.value ], strategyAllowImplied.rest)

ZeroStrategyInstrumentKeysMessage ==
    [ exchangeId                             |-> [i \in 1 .. 1 |-> 0],
      strategySymbol                         |-> [i \in 1 .. 30 |-> 0],
      expiryYear                             |-> [i \in 1 .. 2 |-> 0],
      deliveryMonth                          |-> [i \in 1 .. 1 |-> 0],
      expiryDay                              |-> [i \in 1 .. 2 |-> 0],
      maximumNumberOfContractsPerOrder       |-> [i \in 1 .. 6 |-> 0],
      minimumNumberOfContractsPerOrder       |-> [i \in 1 .. 6 |-> 0],
      maximumThresholdPriceOptions           |-> [i \in 1 .. 6 |-> 0],
      maximumThresholdPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      minimumThresholdPriceOptions           |-> [i \in 1 .. 6 |-> 0],
      minimumThresholdPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      tickIncrement                          |-> [i \in 1 .. 6 |-> 0],
      tickIncrementFractionIndicator         |-> [i \in 1 .. 1 |-> 0],
      marketFlowIndicator                    |-> [i \in 1 .. 2 |-> 0],
      groupInstrument                        |-> [i \in 1 .. 2 |-> 0],
      instrument                             |-> [i \in 1 .. 4 |-> 0],
      instrumentExternalCode                 |-> [i \in 1 .. 30 |-> 0],
      strategyAllowImplied                   |-> [i \in 1 .. 1 |-> 0] ]

(* Strategy Instrument Keys Message at zero, then each field in turn at the values it is checked at *)
CheckedStrategyInstrumentKeysMessage ==
    { ZeroStrategyInstrumentKeysMessage }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.strategySymbol = one] : one \in Sample(30) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.deliveryMonth = one] : one \in Sample(1) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.maximumNumberOfContractsPerOrder = one] : one \in Sample(6) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.minimumNumberOfContractsPerOrder = one] : one \in Sample(6) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.maximumThresholdPriceOptions = one] : one \in Sample(6) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.maximumThresholdPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.minimumThresholdPriceOptions = one] : one \in Sample(6) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.minimumThresholdPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.tickIncrement = one] : one \in Sample(6) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.tickIncrementFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.marketFlowIndicator = one] : one \in Sample(2) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.groupInstrument = one] : one \in Sample(2) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.instrumentExternalCode = one] : one \in Sample(30) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.strategyAllowImplied = one] : one \in Sample(1) }

(***************************************************************************)
(* Swap Future Instrument Keys Message: 172 bytes                          *)
(***************************************************************************)

SwapFutureInstrumentKeysMessage ==
    [ exchangeId                              : Sample(1),
      rootSymbol                              : Sample(6),
      expiryMonth                             : Sample(1),
      expiryYear                              : Sample(2),
      expiryDay                               : Sample(2),
      tenor                                   : Sample(2),
      fixedRate                               : Sample(5),
      fixedRateFractionIndicator              : Sample(1),
      maximumNumberOfContractsPerOrder        : Sample(6),
      minimumNumberOfContractsPerOrder        : Sample(6),
      maximumThresholdPriceOptions            : Sample(6),
      maximumThresholdPriceFractionIndicator  : Sample(1),
      minimumThresholdPriceOptions            : Sample(6),
      minimumThresholdPriceFractionIndicator  : Sample(1),
      tickIncrement                           : Sample(6),
      tickIncrementFractionIndicator          : Sample(1),
      marketFlow                              : Sample(2),
      groupInstrument                         : Sample(2),
      instrumentId                            : Sample(4),
      externalSymbol                          : Sample(30),
      contractSize                            : Sample(8),
      tickValue                               : Sample(6),
      tickValueFractionIndicator              : Sample(1),
      currency                                : Sample(3),
      effectiveDate                           : Sample(6),
      initialEffectiveDate                    : Sample(6),
      cashFlowAlignmentDate                   : Sample(6),
      paymentFrequency                        : Sample(2),
      resetFrequency                          : Sample(2),
      notionalPrincipalAmount                 : Sample(8),
      notionalPrincipalAmountFactionIndicator : Sample(1),
      dayCountConvention                      : Sample(1),
      firstPaymentDate                        : Sample(6),
      nextPaymentDate                         : Sample(6),
      firstResetDate                          : Sample(6),
      nextResetDate                           : Sample(6),
      previousResetDate                       : Sample(6),
      deliveryType                            : Sample(1) ]

EncodeSwapFutureInstrumentKeysMessage(message) ==
    message.exchangeId
        \o message.rootSymbol
        \o message.expiryMonth
        \o message.expiryYear
        \o message.expiryDay
        \o message.tenor
        \o message.fixedRate
        \o message.fixedRateFractionIndicator
        \o message.maximumNumberOfContractsPerOrder
        \o message.minimumNumberOfContractsPerOrder
        \o message.maximumThresholdPriceOptions
        \o message.maximumThresholdPriceFractionIndicator
        \o message.minimumThresholdPriceOptions
        \o message.minimumThresholdPriceFractionIndicator
        \o message.tickIncrement
        \o message.tickIncrementFractionIndicator
        \o message.marketFlow
        \o message.groupInstrument
        \o message.instrumentId
        \o message.externalSymbol
        \o message.contractSize
        \o message.tickValue
        \o message.tickValueFractionIndicator
        \o message.currency
        \o message.effectiveDate
        \o message.initialEffectiveDate
        \o message.cashFlowAlignmentDate
        \o message.paymentFrequency
        \o message.resetFrequency
        \o message.notionalPrincipalAmount
        \o message.notionalPrincipalAmountFactionIndicator
        \o message.dayCountConvention
        \o message.firstPaymentDate
        \o message.nextPaymentDate
        \o message.firstResetDate
        \o message.nextResetDate
        \o message.previousResetDate
        \o message.deliveryType

DecodeSwapFutureInstrumentKeysMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET rootSymbol == ReadBytes(exchangeId.rest, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET expiryMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~expiryMonth.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(expiryMonth.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET tenor == ReadBytes(expiryDay.rest, 2) IN IF ~tenor.ok THEN Fail ELSE
    LET fixedRate == ReadBytes(tenor.rest, 5) IN IF ~fixedRate.ok THEN Fail ELSE
    LET fixedRateFractionIndicator == ReadBytes(fixedRate.rest, 1) IN IF ~fixedRateFractionIndicator.ok THEN Fail ELSE
    LET maximumNumberOfContractsPerOrder == ReadBytes(fixedRateFractionIndicator.rest, 6) IN IF ~maximumNumberOfContractsPerOrder.ok THEN Fail ELSE
    LET minimumNumberOfContractsPerOrder == ReadBytes(maximumNumberOfContractsPerOrder.rest, 6) IN IF ~minimumNumberOfContractsPerOrder.ok THEN Fail ELSE
    LET maximumThresholdPriceOptions == ReadBytes(minimumNumberOfContractsPerOrder.rest, 6) IN IF ~maximumThresholdPriceOptions.ok THEN Fail ELSE
    LET maximumThresholdPriceFractionIndicator == ReadBytes(maximumThresholdPriceOptions.rest, 1) IN IF ~maximumThresholdPriceFractionIndicator.ok THEN Fail ELSE
    LET minimumThresholdPriceOptions == ReadBytes(maximumThresholdPriceFractionIndicator.rest, 6) IN IF ~minimumThresholdPriceOptions.ok THEN Fail ELSE
    LET minimumThresholdPriceFractionIndicator == ReadBytes(minimumThresholdPriceOptions.rest, 1) IN IF ~minimumThresholdPriceFractionIndicator.ok THEN Fail ELSE
    LET tickIncrement == ReadBytes(minimumThresholdPriceFractionIndicator.rest, 6) IN IF ~tickIncrement.ok THEN Fail ELSE
    LET tickIncrementFractionIndicator == ReadBytes(tickIncrement.rest, 1) IN IF ~tickIncrementFractionIndicator.ok THEN Fail ELSE
    LET marketFlow == ReadBytes(tickIncrementFractionIndicator.rest, 2) IN IF ~marketFlow.ok THEN Fail ELSE
    LET groupInstrument == ReadBytes(marketFlow.rest, 2) IN IF ~groupInstrument.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(groupInstrument.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET externalSymbol == ReadBytes(instrumentId.rest, 30) IN IF ~externalSymbol.ok THEN Fail ELSE
    LET contractSize == ReadBytes(externalSymbol.rest, 8) IN IF ~contractSize.ok THEN Fail ELSE
    LET tickValue == ReadBytes(contractSize.rest, 6) IN IF ~tickValue.ok THEN Fail ELSE
    LET tickValueFractionIndicator == ReadBytes(tickValue.rest, 1) IN IF ~tickValueFractionIndicator.ok THEN Fail ELSE
    LET currency == ReadBytes(tickValueFractionIndicator.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET effectiveDate == ReadBytes(currency.rest, 6) IN IF ~effectiveDate.ok THEN Fail ELSE
    LET initialEffectiveDate == ReadBytes(effectiveDate.rest, 6) IN IF ~initialEffectiveDate.ok THEN Fail ELSE
    LET cashFlowAlignmentDate == ReadBytes(initialEffectiveDate.rest, 6) IN IF ~cashFlowAlignmentDate.ok THEN Fail ELSE
    LET paymentFrequency == ReadBytes(cashFlowAlignmentDate.rest, 2) IN IF ~paymentFrequency.ok THEN Fail ELSE
    LET resetFrequency == ReadBytes(paymentFrequency.rest, 2) IN IF ~resetFrequency.ok THEN Fail ELSE
    LET notionalPrincipalAmount == ReadBytes(resetFrequency.rest, 8) IN IF ~notionalPrincipalAmount.ok THEN Fail ELSE
    LET notionalPrincipalAmountFactionIndicator == ReadBytes(notionalPrincipalAmount.rest, 1) IN IF ~notionalPrincipalAmountFactionIndicator.ok THEN Fail ELSE
    LET dayCountConvention == ReadBytes(notionalPrincipalAmountFactionIndicator.rest, 1) IN IF ~dayCountConvention.ok THEN Fail ELSE
    LET firstPaymentDate == ReadBytes(dayCountConvention.rest, 6) IN IF ~firstPaymentDate.ok THEN Fail ELSE
    LET nextPaymentDate == ReadBytes(firstPaymentDate.rest, 6) IN IF ~nextPaymentDate.ok THEN Fail ELSE
    LET firstResetDate == ReadBytes(nextPaymentDate.rest, 6) IN IF ~firstResetDate.ok THEN Fail ELSE
    LET nextResetDate == ReadBytes(firstResetDate.rest, 6) IN IF ~nextResetDate.ok THEN Fail ELSE
    LET previousResetDate == ReadBytes(nextResetDate.rest, 6) IN IF ~previousResetDate.ok THEN Fail ELSE
    LET deliveryType == ReadBytes(previousResetDate.rest, 1) IN IF ~deliveryType.ok THEN Fail ELSE
    Ok([ exchangeId                              |-> exchangeId.value,
         rootSymbol                              |-> rootSymbol.value,
         expiryMonth                             |-> expiryMonth.value,
         expiryYear                              |-> expiryYear.value,
         expiryDay                               |-> expiryDay.value,
         tenor                                   |-> tenor.value,
         fixedRate                               |-> fixedRate.value,
         fixedRateFractionIndicator              |-> fixedRateFractionIndicator.value,
         maximumNumberOfContractsPerOrder        |-> maximumNumberOfContractsPerOrder.value,
         minimumNumberOfContractsPerOrder        |-> minimumNumberOfContractsPerOrder.value,
         maximumThresholdPriceOptions            |-> maximumThresholdPriceOptions.value,
         maximumThresholdPriceFractionIndicator  |-> maximumThresholdPriceFractionIndicator.value,
         minimumThresholdPriceOptions            |-> minimumThresholdPriceOptions.value,
         minimumThresholdPriceFractionIndicator  |-> minimumThresholdPriceFractionIndicator.value,
         tickIncrement                           |-> tickIncrement.value,
         tickIncrementFractionIndicator          |-> tickIncrementFractionIndicator.value,
         marketFlow                              |-> marketFlow.value,
         groupInstrument                         |-> groupInstrument.value,
         instrumentId                            |-> instrumentId.value,
         externalSymbol                          |-> externalSymbol.value,
         contractSize                            |-> contractSize.value,
         tickValue                               |-> tickValue.value,
         tickValueFractionIndicator              |-> tickValueFractionIndicator.value,
         currency                                |-> currency.value,
         effectiveDate                           |-> effectiveDate.value,
         initialEffectiveDate                    |-> initialEffectiveDate.value,
         cashFlowAlignmentDate                   |-> cashFlowAlignmentDate.value,
         paymentFrequency                        |-> paymentFrequency.value,
         resetFrequency                          |-> resetFrequency.value,
         notionalPrincipalAmount                 |-> notionalPrincipalAmount.value,
         notionalPrincipalAmountFactionIndicator |-> notionalPrincipalAmountFactionIndicator.value,
         dayCountConvention                      |-> dayCountConvention.value,
         firstPaymentDate                        |-> firstPaymentDate.value,
         nextPaymentDate                         |-> nextPaymentDate.value,
         firstResetDate                          |-> firstResetDate.value,
         nextResetDate                           |-> nextResetDate.value,
         previousResetDate                       |-> previousResetDate.value,
         deliveryType                            |-> deliveryType.value ], deliveryType.rest)

ZeroSwapFutureInstrumentKeysMessage ==
    [ exchangeId                              |-> [i \in 1 .. 1 |-> 0],
      rootSymbol                              |-> [i \in 1 .. 6 |-> 0],
      expiryMonth                             |-> [i \in 1 .. 1 |-> 0],
      expiryYear                              |-> [i \in 1 .. 2 |-> 0],
      expiryDay                               |-> [i \in 1 .. 2 |-> 0],
      tenor                                   |-> [i \in 1 .. 2 |-> 0],
      fixedRate                               |-> [i \in 1 .. 5 |-> 0],
      fixedRateFractionIndicator              |-> [i \in 1 .. 1 |-> 0],
      maximumNumberOfContractsPerOrder        |-> [i \in 1 .. 6 |-> 0],
      minimumNumberOfContractsPerOrder        |-> [i \in 1 .. 6 |-> 0],
      maximumThresholdPriceOptions            |-> [i \in 1 .. 6 |-> 0],
      maximumThresholdPriceFractionIndicator  |-> [i \in 1 .. 1 |-> 0],
      minimumThresholdPriceOptions            |-> [i \in 1 .. 6 |-> 0],
      minimumThresholdPriceFractionIndicator  |-> [i \in 1 .. 1 |-> 0],
      tickIncrement                           |-> [i \in 1 .. 6 |-> 0],
      tickIncrementFractionIndicator          |-> [i \in 1 .. 1 |-> 0],
      marketFlow                              |-> [i \in 1 .. 2 |-> 0],
      groupInstrument                         |-> [i \in 1 .. 2 |-> 0],
      instrumentId                            |-> [i \in 1 .. 4 |-> 0],
      externalSymbol                          |-> [i \in 1 .. 30 |-> 0],
      contractSize                            |-> [i \in 1 .. 8 |-> 0],
      tickValue                               |-> [i \in 1 .. 6 |-> 0],
      tickValueFractionIndicator              |-> [i \in 1 .. 1 |-> 0],
      currency                                |-> [i \in 1 .. 3 |-> 0],
      effectiveDate                           |-> [i \in 1 .. 6 |-> 0],
      initialEffectiveDate                    |-> [i \in 1 .. 6 |-> 0],
      cashFlowAlignmentDate                   |-> [i \in 1 .. 6 |-> 0],
      paymentFrequency                        |-> [i \in 1 .. 2 |-> 0],
      resetFrequency                          |-> [i \in 1 .. 2 |-> 0],
      notionalPrincipalAmount                 |-> [i \in 1 .. 8 |-> 0],
      notionalPrincipalAmountFactionIndicator |-> [i \in 1 .. 1 |-> 0],
      dayCountConvention                      |-> [i \in 1 .. 1 |-> 0],
      firstPaymentDate                        |-> [i \in 1 .. 6 |-> 0],
      nextPaymentDate                         |-> [i \in 1 .. 6 |-> 0],
      firstResetDate                          |-> [i \in 1 .. 6 |-> 0],
      nextResetDate                           |-> [i \in 1 .. 6 |-> 0],
      previousResetDate                       |-> [i \in 1 .. 6 |-> 0],
      deliveryType                            |-> [i \in 1 .. 1 |-> 0] ]

(* Swap Future Instrument Keys Message at zero, then each field in turn at the values it is checked at *)
CheckedSwapFutureInstrumentKeysMessage ==
    { ZeroSwapFutureInstrumentKeysMessage }
        \cup { [ZeroSwapFutureInstrumentKeysMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureInstrumentKeysMessage EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroSwapFutureInstrumentKeysMessage EXCEPT !.expiryMonth = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureInstrumentKeysMessage EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroSwapFutureInstrumentKeysMessage EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroSwapFutureInstrumentKeysMessage EXCEPT !.tenor = one] : one \in Sample(2) }
        \cup { [ZeroSwapFutureInstrumentKeysMessage EXCEPT !.fixedRate = one] : one \in Sample(5) }
        \cup { [ZeroSwapFutureInstrumentKeysMessage EXCEPT !.fixedRateFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureInstrumentKeysMessage EXCEPT !.maximumNumberOfContractsPerOrder = one] : one \in Sample(6) }
        \cup { [ZeroSwapFutureInstrumentKeysMessage EXCEPT !.minimumNumberOfContractsPerOrder = one] : one \in Sample(6) }
        \cup { [ZeroSwapFutureInstrumentKeysMessage EXCEPT !.maximumThresholdPriceOptions = one] : one \in Sample(6) }
        \cup { [ZeroSwapFutureInstrumentKeysMessage EXCEPT !.maximumThresholdPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureInstrumentKeysMessage EXCEPT !.minimumThresholdPriceOptions = one] : one \in Sample(6) }
        \cup { [ZeroSwapFutureInstrumentKeysMessage EXCEPT !.minimumThresholdPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureInstrumentKeysMessage EXCEPT !.tickIncrement = one] : one \in Sample(6) }
        \cup { [ZeroSwapFutureInstrumentKeysMessage EXCEPT !.tickIncrementFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureInstrumentKeysMessage EXCEPT !.marketFlow = one] : one \in Sample(2) }
        \cup { [ZeroSwapFutureInstrumentKeysMessage EXCEPT !.groupInstrument = one] : one \in Sample(2) }
        \cup { [ZeroSwapFutureInstrumentKeysMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroSwapFutureInstrumentKeysMessage EXCEPT !.externalSymbol = one] : one \in Sample(30) }
        \cup { [ZeroSwapFutureInstrumentKeysMessage EXCEPT !.contractSize = one] : one \in Sample(8) }
        \cup { [ZeroSwapFutureInstrumentKeysMessage EXCEPT !.tickValue = one] : one \in Sample(6) }
        \cup { [ZeroSwapFutureInstrumentKeysMessage EXCEPT !.tickValueFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureInstrumentKeysMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroSwapFutureInstrumentKeysMessage EXCEPT !.effectiveDate = one] : one \in Sample(6) }
        \cup { [ZeroSwapFutureInstrumentKeysMessage EXCEPT !.initialEffectiveDate = one] : one \in Sample(6) }
        \cup { [ZeroSwapFutureInstrumentKeysMessage EXCEPT !.cashFlowAlignmentDate = one] : one \in Sample(6) }
        \cup { [ZeroSwapFutureInstrumentKeysMessage EXCEPT !.paymentFrequency = one] : one \in Sample(2) }
        \cup { [ZeroSwapFutureInstrumentKeysMessage EXCEPT !.resetFrequency = one] : one \in Sample(2) }
        \cup { [ZeroSwapFutureInstrumentKeysMessage EXCEPT !.notionalPrincipalAmount = one] : one \in Sample(8) }
        \cup { [ZeroSwapFutureInstrumentKeysMessage EXCEPT !.notionalPrincipalAmountFactionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureInstrumentKeysMessage EXCEPT !.dayCountConvention = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureInstrumentKeysMessage EXCEPT !.firstPaymentDate = one] : one \in Sample(6) }
        \cup { [ZeroSwapFutureInstrumentKeysMessage EXCEPT !.nextPaymentDate = one] : one \in Sample(6) }
        \cup { [ZeroSwapFutureInstrumentKeysMessage EXCEPT !.firstResetDate = one] : one \in Sample(6) }
        \cup { [ZeroSwapFutureInstrumentKeysMessage EXCEPT !.nextResetDate = one] : one \in Sample(6) }
        \cup { [ZeroSwapFutureInstrumentKeysMessage EXCEPT !.previousResetDate = one] : one \in Sample(6) }
        \cup { [ZeroSwapFutureInstrumentKeysMessage EXCEPT !.deliveryType = one] : one \in Sample(1) }

(***************************************************************************)
(* Option Summary Message: 124 bytes                                       *)
(***************************************************************************)

OptionSummaryMessage ==
    [ exchangeId                               : Sample(1),
      rootSymbol                               : Sample(6),
      expiryMonth                              : Sample(1),
      filler1                                  : Sample(1),
      strikePriceInstrument                    : Sample(7),
      strikePriceFractionIndicator             : Sample(1),
      expiryYear                               : Sample(2),
      expiryDay                                : Sample(2),
      bidPriceSummary                          : Sample(6),
      bidPriceFractionIndicator                : Sample(1),
      bidSize                                  : Sample(5),
      askPriceSummary                          : Sample(6),
      askPriceFractionIndicator                : Sample(1),
      askSize                                  : Sample(5),
      lastPrice                                : Sample(6),
      lastPriceFractionIndicator               : Sample(1),
      openInterest                             : Sample(7),
      tick                                     : Sample(1),
      volume                                   : Sample(8),
      netChangeSign                            : Sample(1),
      netChange                                : Sample(6),
      netChangeFractionIndicator               : Sample(1),
      openPrice                                : Sample(6),
      openPriceFractionIndicator               : Sample(1),
      highPrice                                : Sample(6),
      highPriceFractionIndicator               : Sample(1),
      lowPrice                                 : Sample(6),
      lowPriceFractionIndicator                : Sample(1),
      optionMarker                             : Sample(2),
      underlyingSymbolRootOptions              : Sample(10),
      settlementPrice                          : Sample(6),
      settlementPriceFractionIndicator         : Sample(1),
      previousSettlementPrice                  : Sample(6),
      previousSettlementPriceFractionIndicator : Sample(1),
      reason                                   : Sample(1) ]

EncodeOptionSummaryMessage(message) ==
    message.exchangeId
        \o message.rootSymbol
        \o message.expiryMonth
        \o message.filler1
        \o message.strikePriceInstrument
        \o message.strikePriceFractionIndicator
        \o message.expiryYear
        \o message.expiryDay
        \o message.bidPriceSummary
        \o message.bidPriceFractionIndicator
        \o message.bidSize
        \o message.askPriceSummary
        \o message.askPriceFractionIndicator
        \o message.askSize
        \o message.lastPrice
        \o message.lastPriceFractionIndicator
        \o message.openInterest
        \o message.tick
        \o message.volume
        \o message.netChangeSign
        \o message.netChange
        \o message.netChangeFractionIndicator
        \o message.openPrice
        \o message.openPriceFractionIndicator
        \o message.highPrice
        \o message.highPriceFractionIndicator
        \o message.lowPrice
        \o message.lowPriceFractionIndicator
        \o message.optionMarker
        \o message.underlyingSymbolRootOptions
        \o message.settlementPrice
        \o message.settlementPriceFractionIndicator
        \o message.previousSettlementPrice
        \o message.previousSettlementPriceFractionIndicator
        \o message.reason

DecodeOptionSummaryMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET rootSymbol == ReadBytes(exchangeId.rest, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET expiryMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~expiryMonth.ok THEN Fail ELSE
    LET filler1 == ReadBytes(expiryMonth.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET strikePriceInstrument == ReadBytes(filler1.rest, 7) IN IF ~strikePriceInstrument.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePriceInstrument.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(strikePriceFractionIndicator.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET bidPriceSummary == ReadBytes(expiryDay.rest, 6) IN IF ~bidPriceSummary.ok THEN Fail ELSE
    LET bidPriceFractionIndicator == ReadBytes(bidPriceSummary.rest, 1) IN IF ~bidPriceFractionIndicator.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPriceFractionIndicator.rest, 5) IN IF ~bidSize.ok THEN Fail ELSE
    LET askPriceSummary == ReadBytes(bidSize.rest, 6) IN IF ~askPriceSummary.ok THEN Fail ELSE
    LET askPriceFractionIndicator == ReadBytes(askPriceSummary.rest, 1) IN IF ~askPriceFractionIndicator.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPriceFractionIndicator.rest, 5) IN IF ~askSize.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(askSize.rest, 6) IN IF ~lastPrice.ok THEN Fail ELSE
    LET lastPriceFractionIndicator == ReadBytes(lastPrice.rest, 1) IN IF ~lastPriceFractionIndicator.ok THEN Fail ELSE
    LET openInterest == ReadBytes(lastPriceFractionIndicator.rest, 7) IN IF ~openInterest.ok THEN Fail ELSE
    LET tick == ReadBytes(openInterest.rest, 1) IN IF ~tick.ok THEN Fail ELSE
    LET volume == ReadBytes(tick.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET netChangeSign == ReadBytes(volume.rest, 1) IN IF ~netChangeSign.ok THEN Fail ELSE
    LET netChange == ReadBytes(netChangeSign.rest, 6) IN IF ~netChange.ok THEN Fail ELSE
    LET netChangeFractionIndicator == ReadBytes(netChange.rest, 1) IN IF ~netChangeFractionIndicator.ok THEN Fail ELSE
    LET openPrice == ReadBytes(netChangeFractionIndicator.rest, 6) IN IF ~openPrice.ok THEN Fail ELSE
    LET openPriceFractionIndicator == ReadBytes(openPrice.rest, 1) IN IF ~openPriceFractionIndicator.ok THEN Fail ELSE
    LET highPrice == ReadBytes(openPriceFractionIndicator.rest, 6) IN IF ~highPrice.ok THEN Fail ELSE
    LET highPriceFractionIndicator == ReadBytes(highPrice.rest, 1) IN IF ~highPriceFractionIndicator.ok THEN Fail ELSE
    LET lowPrice == ReadBytes(highPriceFractionIndicator.rest, 6) IN IF ~lowPrice.ok THEN Fail ELSE
    LET lowPriceFractionIndicator == ReadBytes(lowPrice.rest, 1) IN IF ~lowPriceFractionIndicator.ok THEN Fail ELSE
    LET optionMarker == ReadBytes(lowPriceFractionIndicator.rest, 2) IN IF ~optionMarker.ok THEN Fail ELSE
    LET underlyingSymbolRootOptions == ReadBytes(optionMarker.rest, 10) IN IF ~underlyingSymbolRootOptions.ok THEN Fail ELSE
    LET settlementPrice == ReadBytes(underlyingSymbolRootOptions.rest, 6) IN IF ~settlementPrice.ok THEN Fail ELSE
    LET settlementPriceFractionIndicator == ReadBytes(settlementPrice.rest, 1) IN IF ~settlementPriceFractionIndicator.ok THEN Fail ELSE
    LET previousSettlementPrice == ReadBytes(settlementPriceFractionIndicator.rest, 6) IN IF ~previousSettlementPrice.ok THEN Fail ELSE
    LET previousSettlementPriceFractionIndicator == ReadBytes(previousSettlementPrice.rest, 1) IN IF ~previousSettlementPriceFractionIndicator.ok THEN Fail ELSE
    LET reason == ReadBytes(previousSettlementPriceFractionIndicator.rest, 1) IN IF ~reason.ok THEN Fail ELSE
    Ok([ exchangeId                               |-> exchangeId.value,
         rootSymbol                               |-> rootSymbol.value,
         expiryMonth                              |-> expiryMonth.value,
         filler1                                  |-> filler1.value,
         strikePriceInstrument                    |-> strikePriceInstrument.value,
         strikePriceFractionIndicator             |-> strikePriceFractionIndicator.value,
         expiryYear                               |-> expiryYear.value,
         expiryDay                                |-> expiryDay.value,
         bidPriceSummary                          |-> bidPriceSummary.value,
         bidPriceFractionIndicator                |-> bidPriceFractionIndicator.value,
         bidSize                                  |-> bidSize.value,
         askPriceSummary                          |-> askPriceSummary.value,
         askPriceFractionIndicator                |-> askPriceFractionIndicator.value,
         askSize                                  |-> askSize.value,
         lastPrice                                |-> lastPrice.value,
         lastPriceFractionIndicator               |-> lastPriceFractionIndicator.value,
         openInterest                             |-> openInterest.value,
         tick                                     |-> tick.value,
         volume                                   |-> volume.value,
         netChangeSign                            |-> netChangeSign.value,
         netChange                                |-> netChange.value,
         netChangeFractionIndicator               |-> netChangeFractionIndicator.value,
         openPrice                                |-> openPrice.value,
         openPriceFractionIndicator               |-> openPriceFractionIndicator.value,
         highPrice                                |-> highPrice.value,
         highPriceFractionIndicator               |-> highPriceFractionIndicator.value,
         lowPrice                                 |-> lowPrice.value,
         lowPriceFractionIndicator                |-> lowPriceFractionIndicator.value,
         optionMarker                             |-> optionMarker.value,
         underlyingSymbolRootOptions              |-> underlyingSymbolRootOptions.value,
         settlementPrice                          |-> settlementPrice.value,
         settlementPriceFractionIndicator         |-> settlementPriceFractionIndicator.value,
         previousSettlementPrice                  |-> previousSettlementPrice.value,
         previousSettlementPriceFractionIndicator |-> previousSettlementPriceFractionIndicator.value,
         reason                                   |-> reason.value ], reason.rest)

ZeroOptionSummaryMessage ==
    [ exchangeId                               |-> [i \in 1 .. 1 |-> 0],
      rootSymbol                               |-> [i \in 1 .. 6 |-> 0],
      expiryMonth                              |-> [i \in 1 .. 1 |-> 0],
      filler1                                  |-> [i \in 1 .. 1 |-> 0],
      strikePriceInstrument                    |-> [i \in 1 .. 7 |-> 0],
      strikePriceFractionIndicator             |-> [i \in 1 .. 1 |-> 0],
      expiryYear                               |-> [i \in 1 .. 2 |-> 0],
      expiryDay                                |-> [i \in 1 .. 2 |-> 0],
      bidPriceSummary                          |-> [i \in 1 .. 6 |-> 0],
      bidPriceFractionIndicator                |-> [i \in 1 .. 1 |-> 0],
      bidSize                                  |-> [i \in 1 .. 5 |-> 0],
      askPriceSummary                          |-> [i \in 1 .. 6 |-> 0],
      askPriceFractionIndicator                |-> [i \in 1 .. 1 |-> 0],
      askSize                                  |-> [i \in 1 .. 5 |-> 0],
      lastPrice                                |-> [i \in 1 .. 6 |-> 0],
      lastPriceFractionIndicator               |-> [i \in 1 .. 1 |-> 0],
      openInterest                             |-> [i \in 1 .. 7 |-> 0],
      tick                                     |-> [i \in 1 .. 1 |-> 0],
      volume                                   |-> [i \in 1 .. 8 |-> 0],
      netChangeSign                            |-> [i \in 1 .. 1 |-> 0],
      netChange                                |-> [i \in 1 .. 6 |-> 0],
      netChangeFractionIndicator               |-> [i \in 1 .. 1 |-> 0],
      openPrice                                |-> [i \in 1 .. 6 |-> 0],
      openPriceFractionIndicator               |-> [i \in 1 .. 1 |-> 0],
      highPrice                                |-> [i \in 1 .. 6 |-> 0],
      highPriceFractionIndicator               |-> [i \in 1 .. 1 |-> 0],
      lowPrice                                 |-> [i \in 1 .. 6 |-> 0],
      lowPriceFractionIndicator                |-> [i \in 1 .. 1 |-> 0],
      optionMarker                             |-> [i \in 1 .. 2 |-> 0],
      underlyingSymbolRootOptions              |-> [i \in 1 .. 10 |-> 0],
      settlementPrice                          |-> [i \in 1 .. 6 |-> 0],
      settlementPriceFractionIndicator         |-> [i \in 1 .. 1 |-> 0],
      previousSettlementPrice                  |-> [i \in 1 .. 6 |-> 0],
      previousSettlementPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      reason                                   |-> [i \in 1 .. 1 |-> 0] ]

(* Option Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionSummaryMessage ==
    { ZeroOptionSummaryMessage }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.expiryMonth = one] : one \in Sample(1) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.strikePriceInstrument = one] : one \in Sample(7) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.bidPriceSummary = one] : one \in Sample(6) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.bidPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.bidSize = one] : one \in Sample(5) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.askPriceSummary = one] : one \in Sample(6) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.askPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.askSize = one] : one \in Sample(5) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.lastPrice = one] : one \in Sample(6) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.lastPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.openInterest = one] : one \in Sample(7) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.tick = one] : one \in Sample(1) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.netChangeSign = one] : one \in Sample(1) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.netChange = one] : one \in Sample(6) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.netChangeFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.openPrice = one] : one \in Sample(6) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.openPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.highPrice = one] : one \in Sample(6) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.highPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.lowPrice = one] : one \in Sample(6) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.lowPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.optionMarker = one] : one \in Sample(2) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.underlyingSymbolRootOptions = one] : one \in Sample(10) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.settlementPrice = one] : one \in Sample(6) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.settlementPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.previousSettlementPrice = one] : one \in Sample(6) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.previousSettlementPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.reason = one] : one \in Sample(1) }

(***************************************************************************)
(* Future Options Summary Message: 119 bytes                               *)
(***************************************************************************)

FutureOptionsSummaryMessage ==
    [ exchangeId                               : Sample(1),
      rootSymbol                               : Sample(6),
      contractMonthCode                        : Sample(1),
      expiryYear                               : Sample(2),
      expiryDay                                : Sample(2),
      callPutCode                              : Sample(1),
      strikePriceInstrument                    : Sample(7),
      strikePriceFractionIndicator             : Sample(1),
      bidPriceSummary                          : Sample(6),
      bidPriceFractionIndicator                : Sample(1),
      bidSize                                  : Sample(5),
      askPriceSummary                          : Sample(6),
      askPriceFractionIndicator                : Sample(1),
      askSize                                  : Sample(5),
      lastPrice                                : Sample(6),
      lastPriceFractionIndicator               : Sample(1),
      openInterest                             : Sample(7),
      tick                                     : Sample(1),
      volume                                   : Sample(8),
      netChangeSign                            : Sample(1),
      netChange                                : Sample(6),
      netChangeFractionIndicator               : Sample(1),
      openingPrice                             : Sample(6),
      openingPriceFractionIndicator            : Sample(1),
      highPrice                                : Sample(6),
      highPriceFractionIndicator               : Sample(1),
      lowPrice                                 : Sample(6),
      lowPriceFractionIndicator                : Sample(1),
      filler2                                  : Sample(2),
      underlyingSymbolRootFutureOptions        : Sample(3),
      deliveryMonth                            : Sample(1),
      deliveryYearUnderlying                   : Sample(1),
      settlementPrice                          : Sample(6),
      settlementPriceFractionIndicator         : Sample(1),
      previousSettlementPrice                  : Sample(6),
      previousSettlementPriceFractionIndicator : Sample(1),
      reason                                   : Sample(1) ]

EncodeFutureOptionsSummaryMessage(message) ==
    message.exchangeId
        \o message.rootSymbol
        \o message.contractMonthCode
        \o message.expiryYear
        \o message.expiryDay
        \o message.callPutCode
        \o message.strikePriceInstrument
        \o message.strikePriceFractionIndicator
        \o message.bidPriceSummary
        \o message.bidPriceFractionIndicator
        \o message.bidSize
        \o message.askPriceSummary
        \o message.askPriceFractionIndicator
        \o message.askSize
        \o message.lastPrice
        \o message.lastPriceFractionIndicator
        \o message.openInterest
        \o message.tick
        \o message.volume
        \o message.netChangeSign
        \o message.netChange
        \o message.netChangeFractionIndicator
        \o message.openingPrice
        \o message.openingPriceFractionIndicator
        \o message.highPrice
        \o message.highPriceFractionIndicator
        \o message.lowPrice
        \o message.lowPriceFractionIndicator
        \o message.filler2
        \o message.underlyingSymbolRootFutureOptions
        \o message.deliveryMonth
        \o message.deliveryYearUnderlying
        \o message.settlementPrice
        \o message.settlementPriceFractionIndicator
        \o message.previousSettlementPrice
        \o message.previousSettlementPriceFractionIndicator
        \o message.reason

DecodeFutureOptionsSummaryMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET rootSymbol == ReadBytes(exchangeId.rest, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET contractMonthCode == ReadBytes(rootSymbol.rest, 1) IN IF ~contractMonthCode.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(contractMonthCode.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET callPutCode == ReadBytes(expiryDay.rest, 1) IN IF ~callPutCode.ok THEN Fail ELSE
    LET strikePriceInstrument == ReadBytes(callPutCode.rest, 7) IN IF ~strikePriceInstrument.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePriceInstrument.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    LET bidPriceSummary == ReadBytes(strikePriceFractionIndicator.rest, 6) IN IF ~bidPriceSummary.ok THEN Fail ELSE
    LET bidPriceFractionIndicator == ReadBytes(bidPriceSummary.rest, 1) IN IF ~bidPriceFractionIndicator.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPriceFractionIndicator.rest, 5) IN IF ~bidSize.ok THEN Fail ELSE
    LET askPriceSummary == ReadBytes(bidSize.rest, 6) IN IF ~askPriceSummary.ok THEN Fail ELSE
    LET askPriceFractionIndicator == ReadBytes(askPriceSummary.rest, 1) IN IF ~askPriceFractionIndicator.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPriceFractionIndicator.rest, 5) IN IF ~askSize.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(askSize.rest, 6) IN IF ~lastPrice.ok THEN Fail ELSE
    LET lastPriceFractionIndicator == ReadBytes(lastPrice.rest, 1) IN IF ~lastPriceFractionIndicator.ok THEN Fail ELSE
    LET openInterest == ReadBytes(lastPriceFractionIndicator.rest, 7) IN IF ~openInterest.ok THEN Fail ELSE
    LET tick == ReadBytes(openInterest.rest, 1) IN IF ~tick.ok THEN Fail ELSE
    LET volume == ReadBytes(tick.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET netChangeSign == ReadBytes(volume.rest, 1) IN IF ~netChangeSign.ok THEN Fail ELSE
    LET netChange == ReadBytes(netChangeSign.rest, 6) IN IF ~netChange.ok THEN Fail ELSE
    LET netChangeFractionIndicator == ReadBytes(netChange.rest, 1) IN IF ~netChangeFractionIndicator.ok THEN Fail ELSE
    LET openingPrice == ReadBytes(netChangeFractionIndicator.rest, 6) IN IF ~openingPrice.ok THEN Fail ELSE
    LET openingPriceFractionIndicator == ReadBytes(openingPrice.rest, 1) IN IF ~openingPriceFractionIndicator.ok THEN Fail ELSE
    LET highPrice == ReadBytes(openingPriceFractionIndicator.rest, 6) IN IF ~highPrice.ok THEN Fail ELSE
    LET highPriceFractionIndicator == ReadBytes(highPrice.rest, 1) IN IF ~highPriceFractionIndicator.ok THEN Fail ELSE
    LET lowPrice == ReadBytes(highPriceFractionIndicator.rest, 6) IN IF ~lowPrice.ok THEN Fail ELSE
    LET lowPriceFractionIndicator == ReadBytes(lowPrice.rest, 1) IN IF ~lowPriceFractionIndicator.ok THEN Fail ELSE
    LET filler2 == ReadBytes(lowPriceFractionIndicator.rest, 2) IN IF ~filler2.ok THEN Fail ELSE
    LET underlyingSymbolRootFutureOptions == ReadBytes(filler2.rest, 3) IN IF ~underlyingSymbolRootFutureOptions.ok THEN Fail ELSE
    LET deliveryMonth == ReadBytes(underlyingSymbolRootFutureOptions.rest, 1) IN IF ~deliveryMonth.ok THEN Fail ELSE
    LET deliveryYearUnderlying == ReadBytes(deliveryMonth.rest, 1) IN IF ~deliveryYearUnderlying.ok THEN Fail ELSE
    LET settlementPrice == ReadBytes(deliveryYearUnderlying.rest, 6) IN IF ~settlementPrice.ok THEN Fail ELSE
    LET settlementPriceFractionIndicator == ReadBytes(settlementPrice.rest, 1) IN IF ~settlementPriceFractionIndicator.ok THEN Fail ELSE
    LET previousSettlementPrice == ReadBytes(settlementPriceFractionIndicator.rest, 6) IN IF ~previousSettlementPrice.ok THEN Fail ELSE
    LET previousSettlementPriceFractionIndicator == ReadBytes(previousSettlementPrice.rest, 1) IN IF ~previousSettlementPriceFractionIndicator.ok THEN Fail ELSE
    LET reason == ReadBytes(previousSettlementPriceFractionIndicator.rest, 1) IN IF ~reason.ok THEN Fail ELSE
    Ok([ exchangeId                               |-> exchangeId.value,
         rootSymbol                               |-> rootSymbol.value,
         contractMonthCode                        |-> contractMonthCode.value,
         expiryYear                               |-> expiryYear.value,
         expiryDay                                |-> expiryDay.value,
         callPutCode                              |-> callPutCode.value,
         strikePriceInstrument                    |-> strikePriceInstrument.value,
         strikePriceFractionIndicator             |-> strikePriceFractionIndicator.value,
         bidPriceSummary                          |-> bidPriceSummary.value,
         bidPriceFractionIndicator                |-> bidPriceFractionIndicator.value,
         bidSize                                  |-> bidSize.value,
         askPriceSummary                          |-> askPriceSummary.value,
         askPriceFractionIndicator                |-> askPriceFractionIndicator.value,
         askSize                                  |-> askSize.value,
         lastPrice                                |-> lastPrice.value,
         lastPriceFractionIndicator               |-> lastPriceFractionIndicator.value,
         openInterest                             |-> openInterest.value,
         tick                                     |-> tick.value,
         volume                                   |-> volume.value,
         netChangeSign                            |-> netChangeSign.value,
         netChange                                |-> netChange.value,
         netChangeFractionIndicator               |-> netChangeFractionIndicator.value,
         openingPrice                             |-> openingPrice.value,
         openingPriceFractionIndicator            |-> openingPriceFractionIndicator.value,
         highPrice                                |-> highPrice.value,
         highPriceFractionIndicator               |-> highPriceFractionIndicator.value,
         lowPrice                                 |-> lowPrice.value,
         lowPriceFractionIndicator                |-> lowPriceFractionIndicator.value,
         filler2                                  |-> filler2.value,
         underlyingSymbolRootFutureOptions        |-> underlyingSymbolRootFutureOptions.value,
         deliveryMonth                            |-> deliveryMonth.value,
         deliveryYearUnderlying                   |-> deliveryYearUnderlying.value,
         settlementPrice                          |-> settlementPrice.value,
         settlementPriceFractionIndicator         |-> settlementPriceFractionIndicator.value,
         previousSettlementPrice                  |-> previousSettlementPrice.value,
         previousSettlementPriceFractionIndicator |-> previousSettlementPriceFractionIndicator.value,
         reason                                   |-> reason.value ], reason.rest)

ZeroFutureOptionsSummaryMessage ==
    [ exchangeId                               |-> [i \in 1 .. 1 |-> 0],
      rootSymbol                               |-> [i \in 1 .. 6 |-> 0],
      contractMonthCode                        |-> [i \in 1 .. 1 |-> 0],
      expiryYear                               |-> [i \in 1 .. 2 |-> 0],
      expiryDay                                |-> [i \in 1 .. 2 |-> 0],
      callPutCode                              |-> [i \in 1 .. 1 |-> 0],
      strikePriceInstrument                    |-> [i \in 1 .. 7 |-> 0],
      strikePriceFractionIndicator             |-> [i \in 1 .. 1 |-> 0],
      bidPriceSummary                          |-> [i \in 1 .. 6 |-> 0],
      bidPriceFractionIndicator                |-> [i \in 1 .. 1 |-> 0],
      bidSize                                  |-> [i \in 1 .. 5 |-> 0],
      askPriceSummary                          |-> [i \in 1 .. 6 |-> 0],
      askPriceFractionIndicator                |-> [i \in 1 .. 1 |-> 0],
      askSize                                  |-> [i \in 1 .. 5 |-> 0],
      lastPrice                                |-> [i \in 1 .. 6 |-> 0],
      lastPriceFractionIndicator               |-> [i \in 1 .. 1 |-> 0],
      openInterest                             |-> [i \in 1 .. 7 |-> 0],
      tick                                     |-> [i \in 1 .. 1 |-> 0],
      volume                                   |-> [i \in 1 .. 8 |-> 0],
      netChangeSign                            |-> [i \in 1 .. 1 |-> 0],
      netChange                                |-> [i \in 1 .. 6 |-> 0],
      netChangeFractionIndicator               |-> [i \in 1 .. 1 |-> 0],
      openingPrice                             |-> [i \in 1 .. 6 |-> 0],
      openingPriceFractionIndicator            |-> [i \in 1 .. 1 |-> 0],
      highPrice                                |-> [i \in 1 .. 6 |-> 0],
      highPriceFractionIndicator               |-> [i \in 1 .. 1 |-> 0],
      lowPrice                                 |-> [i \in 1 .. 6 |-> 0],
      lowPriceFractionIndicator                |-> [i \in 1 .. 1 |-> 0],
      filler2                                  |-> [i \in 1 .. 2 |-> 0],
      underlyingSymbolRootFutureOptions        |-> [i \in 1 .. 3 |-> 0],
      deliveryMonth                            |-> [i \in 1 .. 1 |-> 0],
      deliveryYearUnderlying                   |-> [i \in 1 .. 1 |-> 0],
      settlementPrice                          |-> [i \in 1 .. 6 |-> 0],
      settlementPriceFractionIndicator         |-> [i \in 1 .. 1 |-> 0],
      previousSettlementPrice                  |-> [i \in 1 .. 6 |-> 0],
      previousSettlementPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      reason                                   |-> [i \in 1 .. 1 |-> 0] ]

(* Future Options Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedFutureOptionsSummaryMessage ==
    { ZeroFutureOptionsSummaryMessage }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.contractMonthCode = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.callPutCode = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.strikePriceInstrument = one] : one \in Sample(7) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.bidPriceSummary = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.bidPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.bidSize = one] : one \in Sample(5) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.askPriceSummary = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.askPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.askSize = one] : one \in Sample(5) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.lastPrice = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.lastPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.openInterest = one] : one \in Sample(7) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.tick = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.netChangeSign = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.netChange = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.netChangeFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.openingPrice = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.openingPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.highPrice = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.highPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.lowPrice = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.lowPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.filler2 = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.underlyingSymbolRootFutureOptions = one] : one \in Sample(3) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.deliveryMonth = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.deliveryYearUnderlying = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.settlementPrice = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.settlementPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.previousSettlementPrice = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.previousSettlementPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.reason = one] : one \in Sample(1) }

(***************************************************************************)
(* Futures Summary Message: 109 bytes                                      *)
(***************************************************************************)

FuturesSummaryMessage ==
    [ exchangeId                          : Sample(1),
      rootSymbol                          : Sample(6),
      deliveryMonth                       : Sample(1),
      deliveryYearFutures                 : Sample(2),
      deliveryDay                         : Sample(2),
      bidPriceSummary                     : Sample(6),
      bidPriceFractionIndicator           : Sample(1),
      bidSize                             : Sample(5),
      askPriceSummary                     : Sample(6),
      askPriceFractionIndicator           : Sample(1),
      askSize                             : Sample(5),
      lastPrice                           : Sample(6),
      lastPriceFractionIndicator          : Sample(1),
      openPrice                           : Sample(6),
      openPriceFractionIndicator          : Sample(1),
      highPrice                           : Sample(6),
      highPriceFractionIndicator          : Sample(1),
      lowPrice                            : Sample(6),
      lowPriceFractionIndicator           : Sample(1),
      settlementPrice                     : Sample(6),
      settlementPriceFractionIndicator    : Sample(1),
      netChangeSign                       : Sample(1),
      netChange                           : Sample(6),
      netChangeFractionIndicator          : Sample(1),
      volume                              : Sample(8),
      previousSettlement                  : Sample(6),
      previousSettlementFractionIndicator : Sample(1),
      openInterest                        : Sample(7),
      reason                              : Sample(1),
      externalPriceAtSource               : Sample(6),
      externalPriceFractionIndicator      : Sample(1) ]

EncodeFuturesSummaryMessage(message) ==
    message.exchangeId
        \o message.rootSymbol
        \o message.deliveryMonth
        \o message.deliveryYearFutures
        \o message.deliveryDay
        \o message.bidPriceSummary
        \o message.bidPriceFractionIndicator
        \o message.bidSize
        \o message.askPriceSummary
        \o message.askPriceFractionIndicator
        \o message.askSize
        \o message.lastPrice
        \o message.lastPriceFractionIndicator
        \o message.openPrice
        \o message.openPriceFractionIndicator
        \o message.highPrice
        \o message.highPriceFractionIndicator
        \o message.lowPrice
        \o message.lowPriceFractionIndicator
        \o message.settlementPrice
        \o message.settlementPriceFractionIndicator
        \o message.netChangeSign
        \o message.netChange
        \o message.netChangeFractionIndicator
        \o message.volume
        \o message.previousSettlement
        \o message.previousSettlementFractionIndicator
        \o message.openInterest
        \o message.reason
        \o message.externalPriceAtSource
        \o message.externalPriceFractionIndicator

DecodeFuturesSummaryMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET rootSymbol == ReadBytes(exchangeId.rest, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET deliveryMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~deliveryMonth.ok THEN Fail ELSE
    LET deliveryYearFutures == ReadBytes(deliveryMonth.rest, 2) IN IF ~deliveryYearFutures.ok THEN Fail ELSE
    LET deliveryDay == ReadBytes(deliveryYearFutures.rest, 2) IN IF ~deliveryDay.ok THEN Fail ELSE
    LET bidPriceSummary == ReadBytes(deliveryDay.rest, 6) IN IF ~bidPriceSummary.ok THEN Fail ELSE
    LET bidPriceFractionIndicator == ReadBytes(bidPriceSummary.rest, 1) IN IF ~bidPriceFractionIndicator.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPriceFractionIndicator.rest, 5) IN IF ~bidSize.ok THEN Fail ELSE
    LET askPriceSummary == ReadBytes(bidSize.rest, 6) IN IF ~askPriceSummary.ok THEN Fail ELSE
    LET askPriceFractionIndicator == ReadBytes(askPriceSummary.rest, 1) IN IF ~askPriceFractionIndicator.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPriceFractionIndicator.rest, 5) IN IF ~askSize.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(askSize.rest, 6) IN IF ~lastPrice.ok THEN Fail ELSE
    LET lastPriceFractionIndicator == ReadBytes(lastPrice.rest, 1) IN IF ~lastPriceFractionIndicator.ok THEN Fail ELSE
    LET openPrice == ReadBytes(lastPriceFractionIndicator.rest, 6) IN IF ~openPrice.ok THEN Fail ELSE
    LET openPriceFractionIndicator == ReadBytes(openPrice.rest, 1) IN IF ~openPriceFractionIndicator.ok THEN Fail ELSE
    LET highPrice == ReadBytes(openPriceFractionIndicator.rest, 6) IN IF ~highPrice.ok THEN Fail ELSE
    LET highPriceFractionIndicator == ReadBytes(highPrice.rest, 1) IN IF ~highPriceFractionIndicator.ok THEN Fail ELSE
    LET lowPrice == ReadBytes(highPriceFractionIndicator.rest, 6) IN IF ~lowPrice.ok THEN Fail ELSE
    LET lowPriceFractionIndicator == ReadBytes(lowPrice.rest, 1) IN IF ~lowPriceFractionIndicator.ok THEN Fail ELSE
    LET settlementPrice == ReadBytes(lowPriceFractionIndicator.rest, 6) IN IF ~settlementPrice.ok THEN Fail ELSE
    LET settlementPriceFractionIndicator == ReadBytes(settlementPrice.rest, 1) IN IF ~settlementPriceFractionIndicator.ok THEN Fail ELSE
    LET netChangeSign == ReadBytes(settlementPriceFractionIndicator.rest, 1) IN IF ~netChangeSign.ok THEN Fail ELSE
    LET netChange == ReadBytes(netChangeSign.rest, 6) IN IF ~netChange.ok THEN Fail ELSE
    LET netChangeFractionIndicator == ReadBytes(netChange.rest, 1) IN IF ~netChangeFractionIndicator.ok THEN Fail ELSE
    LET volume == ReadBytes(netChangeFractionIndicator.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET previousSettlement == ReadBytes(volume.rest, 6) IN IF ~previousSettlement.ok THEN Fail ELSE
    LET previousSettlementFractionIndicator == ReadBytes(previousSettlement.rest, 1) IN IF ~previousSettlementFractionIndicator.ok THEN Fail ELSE
    LET openInterest == ReadBytes(previousSettlementFractionIndicator.rest, 7) IN IF ~openInterest.ok THEN Fail ELSE
    LET reason == ReadBytes(openInterest.rest, 1) IN IF ~reason.ok THEN Fail ELSE
    LET externalPriceAtSource == ReadBytes(reason.rest, 6) IN IF ~externalPriceAtSource.ok THEN Fail ELSE
    LET externalPriceFractionIndicator == ReadBytes(externalPriceAtSource.rest, 1) IN IF ~externalPriceFractionIndicator.ok THEN Fail ELSE
    Ok([ exchangeId                          |-> exchangeId.value,
         rootSymbol                          |-> rootSymbol.value,
         deliveryMonth                       |-> deliveryMonth.value,
         deliveryYearFutures                 |-> deliveryYearFutures.value,
         deliveryDay                         |-> deliveryDay.value,
         bidPriceSummary                     |-> bidPriceSummary.value,
         bidPriceFractionIndicator           |-> bidPriceFractionIndicator.value,
         bidSize                             |-> bidSize.value,
         askPriceSummary                     |-> askPriceSummary.value,
         askPriceFractionIndicator           |-> askPriceFractionIndicator.value,
         askSize                             |-> askSize.value,
         lastPrice                           |-> lastPrice.value,
         lastPriceFractionIndicator          |-> lastPriceFractionIndicator.value,
         openPrice                           |-> openPrice.value,
         openPriceFractionIndicator          |-> openPriceFractionIndicator.value,
         highPrice                           |-> highPrice.value,
         highPriceFractionIndicator          |-> highPriceFractionIndicator.value,
         lowPrice                            |-> lowPrice.value,
         lowPriceFractionIndicator           |-> lowPriceFractionIndicator.value,
         settlementPrice                     |-> settlementPrice.value,
         settlementPriceFractionIndicator    |-> settlementPriceFractionIndicator.value,
         netChangeSign                       |-> netChangeSign.value,
         netChange                           |-> netChange.value,
         netChangeFractionIndicator          |-> netChangeFractionIndicator.value,
         volume                              |-> volume.value,
         previousSettlement                  |-> previousSettlement.value,
         previousSettlementFractionIndicator |-> previousSettlementFractionIndicator.value,
         openInterest                        |-> openInterest.value,
         reason                              |-> reason.value,
         externalPriceAtSource               |-> externalPriceAtSource.value,
         externalPriceFractionIndicator      |-> externalPriceFractionIndicator.value ], externalPriceFractionIndicator.rest)

ZeroFuturesSummaryMessage ==
    [ exchangeId                          |-> [i \in 1 .. 1 |-> 0],
      rootSymbol                          |-> [i \in 1 .. 6 |-> 0],
      deliveryMonth                       |-> [i \in 1 .. 1 |-> 0],
      deliveryYearFutures                 |-> [i \in 1 .. 2 |-> 0],
      deliveryDay                         |-> [i \in 1 .. 2 |-> 0],
      bidPriceSummary                     |-> [i \in 1 .. 6 |-> 0],
      bidPriceFractionIndicator           |-> [i \in 1 .. 1 |-> 0],
      bidSize                             |-> [i \in 1 .. 5 |-> 0],
      askPriceSummary                     |-> [i \in 1 .. 6 |-> 0],
      askPriceFractionIndicator           |-> [i \in 1 .. 1 |-> 0],
      askSize                             |-> [i \in 1 .. 5 |-> 0],
      lastPrice                           |-> [i \in 1 .. 6 |-> 0],
      lastPriceFractionIndicator          |-> [i \in 1 .. 1 |-> 0],
      openPrice                           |-> [i \in 1 .. 6 |-> 0],
      openPriceFractionIndicator          |-> [i \in 1 .. 1 |-> 0],
      highPrice                           |-> [i \in 1 .. 6 |-> 0],
      highPriceFractionIndicator          |-> [i \in 1 .. 1 |-> 0],
      lowPrice                            |-> [i \in 1 .. 6 |-> 0],
      lowPriceFractionIndicator           |-> [i \in 1 .. 1 |-> 0],
      settlementPrice                     |-> [i \in 1 .. 6 |-> 0],
      settlementPriceFractionIndicator    |-> [i \in 1 .. 1 |-> 0],
      netChangeSign                       |-> [i \in 1 .. 1 |-> 0],
      netChange                           |-> [i \in 1 .. 6 |-> 0],
      netChangeFractionIndicator          |-> [i \in 1 .. 1 |-> 0],
      volume                              |-> [i \in 1 .. 8 |-> 0],
      previousSettlement                  |-> [i \in 1 .. 6 |-> 0],
      previousSettlementFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      openInterest                        |-> [i \in 1 .. 7 |-> 0],
      reason                              |-> [i \in 1 .. 1 |-> 0],
      externalPriceAtSource               |-> [i \in 1 .. 6 |-> 0],
      externalPriceFractionIndicator      |-> [i \in 1 .. 1 |-> 0] ]

(* Futures Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedFuturesSummaryMessage ==
    { ZeroFuturesSummaryMessage }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.deliveryMonth = one] : one \in Sample(1) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.deliveryYearFutures = one] : one \in Sample(2) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.deliveryDay = one] : one \in Sample(2) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.bidPriceSummary = one] : one \in Sample(6) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.bidPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.bidSize = one] : one \in Sample(5) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.askPriceSummary = one] : one \in Sample(6) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.askPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.askSize = one] : one \in Sample(5) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.lastPrice = one] : one \in Sample(6) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.lastPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.openPrice = one] : one \in Sample(6) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.openPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.highPrice = one] : one \in Sample(6) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.highPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.lowPrice = one] : one \in Sample(6) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.lowPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.settlementPrice = one] : one \in Sample(6) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.settlementPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.netChangeSign = one] : one \in Sample(1) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.netChange = one] : one \in Sample(6) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.netChangeFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.previousSettlement = one] : one \in Sample(6) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.previousSettlementFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.openInterest = one] : one \in Sample(7) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.reason = one] : one \in Sample(1) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.externalPriceAtSource = one] : one \in Sample(6) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.externalPriceFractionIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Strategy Summary Strategy Leg: 33 bytes                                 *)
(***************************************************************************)

StrategySummaryStrategyLeg ==
    [ legRatioSign : Sample(1),
      legRatio     : Sample(2),
      legSymbol    : Sample(30) ]

EncodeStrategySummaryStrategyLeg(message) ==
    message.legRatioSign
        \o message.legRatio
        \o message.legSymbol

DecodeStrategySummaryStrategyLeg(bytes) ==
    LET legRatioSign == ReadBytes(bytes, 1) IN IF ~legRatioSign.ok THEN Fail ELSE
    LET legRatio == ReadBytes(legRatioSign.rest, 2) IN IF ~legRatio.ok THEN Fail ELSE
    LET legSymbol == ReadBytes(legRatio.rest, 30) IN IF ~legSymbol.ok THEN Fail ELSE
    Ok([ legRatioSign |-> legRatioSign.value,
         legRatio     |-> legRatio.value,
         legSymbol    |-> legSymbol.value ], legSymbol.rest)

ZeroStrategySummaryStrategyLeg ==
    [ legRatioSign |-> [i \in 1 .. 1 |-> 0],
      legRatio     |-> [i \in 1 .. 2 |-> 0],
      legSymbol    |-> [i \in 1 .. 30 |-> 0] ]

(* Strategy Summary Strategy Leg at zero, then each field in turn at the values it is checked at *)
CheckedStrategySummaryStrategyLeg ==
    { ZeroStrategySummaryStrategyLeg }
        \cup { [ZeroStrategySummaryStrategyLeg EXCEPT !.legRatioSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategySummaryStrategyLeg EXCEPT !.legRatio = one] : one \in Sample(2) }
        \cup { [ZeroStrategySummaryStrategyLeg EXCEPT !.legSymbol = one] : one \in Sample(30) }

(* A run of Strategy Summary Strategy Leg, written one after another *)
RECURSIVE EncodeStrategySummaryStrategyLegList(_)
EncodeStrategySummaryStrategyLegList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeStrategySummaryStrategyLeg(Head(messages)) \o EncodeStrategySummaryStrategyLegList(Tail(messages))

(* As many Strategy Summary Strategy Leg as the field that counts them says *)
RECURSIVE ReadStrategySummaryStrategyLegList(_, _)
ReadStrategySummaryStrategyLegList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeStrategySummaryStrategyLeg(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadStrategySummaryStrategyLegList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Strategy Summary Strategy Leg of each kind, for the lists that carry them *)
OneStrategySummaryStrategyLeg == { ZeroStrategySummaryStrategyLeg }

(***************************************************************************)
(* Strategy Summary Message                                                *)
(***************************************************************************)

StrategySummaryMessage ==
    [ exchangeId                 : Sample(1),
      strategySymbol             : Sample(30),
      bidPriceSign               : Sample(1),
      bidPriceSummary            : Sample(6),
      bidPriceFractionIndicator  : Sample(1),
      bidSize                    : Sample(5),
      askPriceSign               : Sample(1),
      askPriceSummary            : Sample(6),
      askPriceFractionIndicator  : Sample(1),
      askSize                    : Sample(5),
      lastPriceSign              : Sample(1),
      lastPrice                  : Sample(6),
      lastPriceFractionIndicator : Sample(1),
      openPriceSign              : Sample(1),
      openPrice                  : Sample(6),
      openPriceFractionIndicator : Sample(1),
      highPriceSign              : Sample(1),
      highPrice                  : Sample(6),
      highPriceFractionIndicator : Sample(1),
      lowPriceSign               : Sample(1),
      lowPrice                   : Sample(6),
      lowPriceFractionIndicator  : Sample(1),
      netChangeSign              : Sample(1),
      netChange                  : Sample(6),
      netChangeFractionIndicator : Sample(1),
      volume                     : Sample(8),
      reason                     : Sample(1),
      strategySummaryStrategyLeg : SampleLists(OneStrategySummaryStrategyLeg) ]

EncodeStrategySummaryMessage(message) ==
    message.exchangeId
        \o message.strategySymbol
        \o message.bidPriceSign
        \o message.bidPriceSummary
        \o message.bidPriceFractionIndicator
        \o message.bidSize
        \o message.askPriceSign
        \o message.askPriceSummary
        \o message.askPriceFractionIndicator
        \o message.askSize
        \o message.lastPriceSign
        \o message.lastPrice
        \o message.lastPriceFractionIndicator
        \o message.openPriceSign
        \o message.openPrice
        \o message.openPriceFractionIndicator
        \o message.highPriceSign
        \o message.highPrice
        \o message.highPriceFractionIndicator
        \o message.lowPriceSign
        \o message.lowPrice
        \o message.lowPriceFractionIndicator
        \o message.netChangeSign
        \o message.netChange
        \o message.netChangeFractionIndicator
        \o message.volume
        \o message.reason
        \o EncodeDigits(Len(message.strategySummaryStrategyLeg), 2)
        \o EncodeStrategySummaryStrategyLegList(message.strategySummaryStrategyLeg)

DecodeStrategySummaryMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET strategySymbol == ReadBytes(exchangeId.rest, 30) IN IF ~strategySymbol.ok THEN Fail ELSE
    LET bidPriceSign == ReadBytes(strategySymbol.rest, 1) IN IF ~bidPriceSign.ok THEN Fail ELSE
    LET bidPriceSummary == ReadBytes(bidPriceSign.rest, 6) IN IF ~bidPriceSummary.ok THEN Fail ELSE
    LET bidPriceFractionIndicator == ReadBytes(bidPriceSummary.rest, 1) IN IF ~bidPriceFractionIndicator.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPriceFractionIndicator.rest, 5) IN IF ~bidSize.ok THEN Fail ELSE
    LET askPriceSign == ReadBytes(bidSize.rest, 1) IN IF ~askPriceSign.ok THEN Fail ELSE
    LET askPriceSummary == ReadBytes(askPriceSign.rest, 6) IN IF ~askPriceSummary.ok THEN Fail ELSE
    LET askPriceFractionIndicator == ReadBytes(askPriceSummary.rest, 1) IN IF ~askPriceFractionIndicator.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPriceFractionIndicator.rest, 5) IN IF ~askSize.ok THEN Fail ELSE
    LET lastPriceSign == ReadBytes(askSize.rest, 1) IN IF ~lastPriceSign.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(lastPriceSign.rest, 6) IN IF ~lastPrice.ok THEN Fail ELSE
    LET lastPriceFractionIndicator == ReadBytes(lastPrice.rest, 1) IN IF ~lastPriceFractionIndicator.ok THEN Fail ELSE
    LET openPriceSign == ReadBytes(lastPriceFractionIndicator.rest, 1) IN IF ~openPriceSign.ok THEN Fail ELSE
    LET openPrice == ReadBytes(openPriceSign.rest, 6) IN IF ~openPrice.ok THEN Fail ELSE
    LET openPriceFractionIndicator == ReadBytes(openPrice.rest, 1) IN IF ~openPriceFractionIndicator.ok THEN Fail ELSE
    LET highPriceSign == ReadBytes(openPriceFractionIndicator.rest, 1) IN IF ~highPriceSign.ok THEN Fail ELSE
    LET highPrice == ReadBytes(highPriceSign.rest, 6) IN IF ~highPrice.ok THEN Fail ELSE
    LET highPriceFractionIndicator == ReadBytes(highPrice.rest, 1) IN IF ~highPriceFractionIndicator.ok THEN Fail ELSE
    LET lowPriceSign == ReadBytes(highPriceFractionIndicator.rest, 1) IN IF ~lowPriceSign.ok THEN Fail ELSE
    LET lowPrice == ReadBytes(lowPriceSign.rest, 6) IN IF ~lowPrice.ok THEN Fail ELSE
    LET lowPriceFractionIndicator == ReadBytes(lowPrice.rest, 1) IN IF ~lowPriceFractionIndicator.ok THEN Fail ELSE
    LET netChangeSign == ReadBytes(lowPriceFractionIndicator.rest, 1) IN IF ~netChangeSign.ok THEN Fail ELSE
    LET netChange == ReadBytes(netChangeSign.rest, 6) IN IF ~netChange.ok THEN Fail ELSE
    LET netChangeFractionIndicator == ReadBytes(netChange.rest, 1) IN IF ~netChangeFractionIndicator.ok THEN Fail ELSE
    LET volume == ReadBytes(netChangeFractionIndicator.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET reason == ReadBytes(volume.rest, 1) IN IF ~reason.ok THEN Fail ELSE
    LET numberOfLegs == ReadDigits(reason.rest, 2) IN IF ~numberOfLegs.ok THEN Fail ELSE
    LET strategySummaryStrategyLeg == ReadStrategySummaryStrategyLegList(numberOfLegs.rest, numberOfLegs.value) IN IF ~strategySummaryStrategyLeg.ok THEN Fail ELSE
    Ok([ exchangeId                 |-> exchangeId.value,
         strategySymbol             |-> strategySymbol.value,
         bidPriceSign               |-> bidPriceSign.value,
         bidPriceSummary            |-> bidPriceSummary.value,
         bidPriceFractionIndicator  |-> bidPriceFractionIndicator.value,
         bidSize                    |-> bidSize.value,
         askPriceSign               |-> askPriceSign.value,
         askPriceSummary            |-> askPriceSummary.value,
         askPriceFractionIndicator  |-> askPriceFractionIndicator.value,
         askSize                    |-> askSize.value,
         lastPriceSign              |-> lastPriceSign.value,
         lastPrice                  |-> lastPrice.value,
         lastPriceFractionIndicator |-> lastPriceFractionIndicator.value,
         openPriceSign              |-> openPriceSign.value,
         openPrice                  |-> openPrice.value,
         openPriceFractionIndicator |-> openPriceFractionIndicator.value,
         highPriceSign              |-> highPriceSign.value,
         highPrice                  |-> highPrice.value,
         highPriceFractionIndicator |-> highPriceFractionIndicator.value,
         lowPriceSign               |-> lowPriceSign.value,
         lowPrice                   |-> lowPrice.value,
         lowPriceFractionIndicator  |-> lowPriceFractionIndicator.value,
         netChangeSign              |-> netChangeSign.value,
         netChange                  |-> netChange.value,
         netChangeFractionIndicator |-> netChangeFractionIndicator.value,
         volume                     |-> volume.value,
         reason                     |-> reason.value,
         strategySummaryStrategyLeg |-> strategySummaryStrategyLeg.value ], strategySummaryStrategyLeg.rest)

ZeroStrategySummaryMessage ==
    [ exchangeId                 |-> [i \in 1 .. 1 |-> 0],
      strategySymbol             |-> [i \in 1 .. 30 |-> 0],
      bidPriceSign               |-> [i \in 1 .. 1 |-> 0],
      bidPriceSummary            |-> [i \in 1 .. 6 |-> 0],
      bidPriceFractionIndicator  |-> [i \in 1 .. 1 |-> 0],
      bidSize                    |-> [i \in 1 .. 5 |-> 0],
      askPriceSign               |-> [i \in 1 .. 1 |-> 0],
      askPriceSummary            |-> [i \in 1 .. 6 |-> 0],
      askPriceFractionIndicator  |-> [i \in 1 .. 1 |-> 0],
      askSize                    |-> [i \in 1 .. 5 |-> 0],
      lastPriceSign              |-> [i \in 1 .. 1 |-> 0],
      lastPrice                  |-> [i \in 1 .. 6 |-> 0],
      lastPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      openPriceSign              |-> [i \in 1 .. 1 |-> 0],
      openPrice                  |-> [i \in 1 .. 6 |-> 0],
      openPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      highPriceSign              |-> [i \in 1 .. 1 |-> 0],
      highPrice                  |-> [i \in 1 .. 6 |-> 0],
      highPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      lowPriceSign               |-> [i \in 1 .. 1 |-> 0],
      lowPrice                   |-> [i \in 1 .. 6 |-> 0],
      lowPriceFractionIndicator  |-> [i \in 1 .. 1 |-> 0],
      netChangeSign              |-> [i \in 1 .. 1 |-> 0],
      netChange                  |-> [i \in 1 .. 6 |-> 0],
      netChangeFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      volume                     |-> [i \in 1 .. 8 |-> 0],
      reason                     |-> [i \in 1 .. 1 |-> 0],
      strategySummaryStrategyLeg |-> << >> ]

(* Strategy Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedStrategySummaryMessage ==
    { ZeroStrategySummaryMessage }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.strategySymbol = one] : one \in Sample(30) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.bidPriceSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.bidPriceSummary = one] : one \in Sample(6) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.bidPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.bidSize = one] : one \in Sample(5) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.askPriceSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.askPriceSummary = one] : one \in Sample(6) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.askPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.askSize = one] : one \in Sample(5) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.lastPriceSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.lastPrice = one] : one \in Sample(6) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.lastPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.openPriceSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.openPrice = one] : one \in Sample(6) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.openPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.highPriceSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.highPrice = one] : one \in Sample(6) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.highPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.lowPriceSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.lowPrice = one] : one \in Sample(6) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.lowPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.netChangeSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.netChange = one] : one \in Sample(6) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.netChangeFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.reason = one] : one \in Sample(1) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.strategySummaryStrategyLeg = one] : one \in SampleLists(OneStrategySummaryStrategyLeg) }

(***************************************************************************)
(* Swap Future Summary Message: 153 bytes                                  *)
(***************************************************************************)

SwapFutureSummaryMessage ==
    [ exchangeId                               : Sample(1),
      rootSymbol                               : Sample(6),
      expiryMonth                              : Sample(1),
      expiryYear                               : Sample(2),
      expiryDay                                : Sample(2),
      tenor                                    : Sample(2),
      fixedRate                                : Sample(5),
      fixedRateFractionIndicator               : Sample(1),
      bidPriceSummary                          : Sample(6),
      bidPriceFractionIndicator                : Sample(1),
      bidSize                                  : Sample(5),
      askPriceSummary                          : Sample(6),
      askPriceFractionIndicator                : Sample(1),
      askSize                                  : Sample(5),
      lastPrice                                : Sample(6),
      lastPriceFractionIndicator               : Sample(1),
      openPrice                                : Sample(6),
      openPriceFractionIndicator               : Sample(1),
      highPrice                                : Sample(6),
      highPriceFractionIndicator               : Sample(1),
      lowPrice                                 : Sample(6),
      lowPriceFractionIndicator                : Sample(1),
      settlementPrice                          : Sample(6),
      settlementPriceFractionIndicator         : Sample(1),
      netPresentValueA                         : Sample(11),
      netPresentValueFractionIndicator         : Sample(1),
      historicalCouponB                        : Sample(11),
      historicalCouponFractionIndicator        : Sample(1),
      priceAlignmentInterestC                  : Sample(11),
      priceAlignmentInterestFractionIndicator  : Sample(1),
      netChangeSign                            : Sample(1),
      netChange                                : Sample(6),
      netChangeFractionIndicator               : Sample(1),
      volume                                   : Sample(8),
      previousSettlementPrice                  : Sample(6),
      previousSettlementPriceFractionIndicator : Sample(1),
      previousResetRate                        : Sample(6),
      previousResetRateFractionIndicator       : Sample(1),
      openInterest                             : Sample(7),
      reason                                   : Sample(1) ]

EncodeSwapFutureSummaryMessage(message) ==
    message.exchangeId
        \o message.rootSymbol
        \o message.expiryMonth
        \o message.expiryYear
        \o message.expiryDay
        \o message.tenor
        \o message.fixedRate
        \o message.fixedRateFractionIndicator
        \o message.bidPriceSummary
        \o message.bidPriceFractionIndicator
        \o message.bidSize
        \o message.askPriceSummary
        \o message.askPriceFractionIndicator
        \o message.askSize
        \o message.lastPrice
        \o message.lastPriceFractionIndicator
        \o message.openPrice
        \o message.openPriceFractionIndicator
        \o message.highPrice
        \o message.highPriceFractionIndicator
        \o message.lowPrice
        \o message.lowPriceFractionIndicator
        \o message.settlementPrice
        \o message.settlementPriceFractionIndicator
        \o message.netPresentValueA
        \o message.netPresentValueFractionIndicator
        \o message.historicalCouponB
        \o message.historicalCouponFractionIndicator
        \o message.priceAlignmentInterestC
        \o message.priceAlignmentInterestFractionIndicator
        \o message.netChangeSign
        \o message.netChange
        \o message.netChangeFractionIndicator
        \o message.volume
        \o message.previousSettlementPrice
        \o message.previousSettlementPriceFractionIndicator
        \o message.previousResetRate
        \o message.previousResetRateFractionIndicator
        \o message.openInterest
        \o message.reason

DecodeSwapFutureSummaryMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET rootSymbol == ReadBytes(exchangeId.rest, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET expiryMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~expiryMonth.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(expiryMonth.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET tenor == ReadBytes(expiryDay.rest, 2) IN IF ~tenor.ok THEN Fail ELSE
    LET fixedRate == ReadBytes(tenor.rest, 5) IN IF ~fixedRate.ok THEN Fail ELSE
    LET fixedRateFractionIndicator == ReadBytes(fixedRate.rest, 1) IN IF ~fixedRateFractionIndicator.ok THEN Fail ELSE
    LET bidPriceSummary == ReadBytes(fixedRateFractionIndicator.rest, 6) IN IF ~bidPriceSummary.ok THEN Fail ELSE
    LET bidPriceFractionIndicator == ReadBytes(bidPriceSummary.rest, 1) IN IF ~bidPriceFractionIndicator.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPriceFractionIndicator.rest, 5) IN IF ~bidSize.ok THEN Fail ELSE
    LET askPriceSummary == ReadBytes(bidSize.rest, 6) IN IF ~askPriceSummary.ok THEN Fail ELSE
    LET askPriceFractionIndicator == ReadBytes(askPriceSummary.rest, 1) IN IF ~askPriceFractionIndicator.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPriceFractionIndicator.rest, 5) IN IF ~askSize.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(askSize.rest, 6) IN IF ~lastPrice.ok THEN Fail ELSE
    LET lastPriceFractionIndicator == ReadBytes(lastPrice.rest, 1) IN IF ~lastPriceFractionIndicator.ok THEN Fail ELSE
    LET openPrice == ReadBytes(lastPriceFractionIndicator.rest, 6) IN IF ~openPrice.ok THEN Fail ELSE
    LET openPriceFractionIndicator == ReadBytes(openPrice.rest, 1) IN IF ~openPriceFractionIndicator.ok THEN Fail ELSE
    LET highPrice == ReadBytes(openPriceFractionIndicator.rest, 6) IN IF ~highPrice.ok THEN Fail ELSE
    LET highPriceFractionIndicator == ReadBytes(highPrice.rest, 1) IN IF ~highPriceFractionIndicator.ok THEN Fail ELSE
    LET lowPrice == ReadBytes(highPriceFractionIndicator.rest, 6) IN IF ~lowPrice.ok THEN Fail ELSE
    LET lowPriceFractionIndicator == ReadBytes(lowPrice.rest, 1) IN IF ~lowPriceFractionIndicator.ok THEN Fail ELSE
    LET settlementPrice == ReadBytes(lowPriceFractionIndicator.rest, 6) IN IF ~settlementPrice.ok THEN Fail ELSE
    LET settlementPriceFractionIndicator == ReadBytes(settlementPrice.rest, 1) IN IF ~settlementPriceFractionIndicator.ok THEN Fail ELSE
    LET netPresentValueA == ReadBytes(settlementPriceFractionIndicator.rest, 11) IN IF ~netPresentValueA.ok THEN Fail ELSE
    LET netPresentValueFractionIndicator == ReadBytes(netPresentValueA.rest, 1) IN IF ~netPresentValueFractionIndicator.ok THEN Fail ELSE
    LET historicalCouponB == ReadBytes(netPresentValueFractionIndicator.rest, 11) IN IF ~historicalCouponB.ok THEN Fail ELSE
    LET historicalCouponFractionIndicator == ReadBytes(historicalCouponB.rest, 1) IN IF ~historicalCouponFractionIndicator.ok THEN Fail ELSE
    LET priceAlignmentInterestC == ReadBytes(historicalCouponFractionIndicator.rest, 11) IN IF ~priceAlignmentInterestC.ok THEN Fail ELSE
    LET priceAlignmentInterestFractionIndicator == ReadBytes(priceAlignmentInterestC.rest, 1) IN IF ~priceAlignmentInterestFractionIndicator.ok THEN Fail ELSE
    LET netChangeSign == ReadBytes(priceAlignmentInterestFractionIndicator.rest, 1) IN IF ~netChangeSign.ok THEN Fail ELSE
    LET netChange == ReadBytes(netChangeSign.rest, 6) IN IF ~netChange.ok THEN Fail ELSE
    LET netChangeFractionIndicator == ReadBytes(netChange.rest, 1) IN IF ~netChangeFractionIndicator.ok THEN Fail ELSE
    LET volume == ReadBytes(netChangeFractionIndicator.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET previousSettlementPrice == ReadBytes(volume.rest, 6) IN IF ~previousSettlementPrice.ok THEN Fail ELSE
    LET previousSettlementPriceFractionIndicator == ReadBytes(previousSettlementPrice.rest, 1) IN IF ~previousSettlementPriceFractionIndicator.ok THEN Fail ELSE
    LET previousResetRate == ReadBytes(previousSettlementPriceFractionIndicator.rest, 6) IN IF ~previousResetRate.ok THEN Fail ELSE
    LET previousResetRateFractionIndicator == ReadBytes(previousResetRate.rest, 1) IN IF ~previousResetRateFractionIndicator.ok THEN Fail ELSE
    LET openInterest == ReadBytes(previousResetRateFractionIndicator.rest, 7) IN IF ~openInterest.ok THEN Fail ELSE
    LET reason == ReadBytes(openInterest.rest, 1) IN IF ~reason.ok THEN Fail ELSE
    Ok([ exchangeId                               |-> exchangeId.value,
         rootSymbol                               |-> rootSymbol.value,
         expiryMonth                              |-> expiryMonth.value,
         expiryYear                               |-> expiryYear.value,
         expiryDay                                |-> expiryDay.value,
         tenor                                    |-> tenor.value,
         fixedRate                                |-> fixedRate.value,
         fixedRateFractionIndicator               |-> fixedRateFractionIndicator.value,
         bidPriceSummary                          |-> bidPriceSummary.value,
         bidPriceFractionIndicator                |-> bidPriceFractionIndicator.value,
         bidSize                                  |-> bidSize.value,
         askPriceSummary                          |-> askPriceSummary.value,
         askPriceFractionIndicator                |-> askPriceFractionIndicator.value,
         askSize                                  |-> askSize.value,
         lastPrice                                |-> lastPrice.value,
         lastPriceFractionIndicator               |-> lastPriceFractionIndicator.value,
         openPrice                                |-> openPrice.value,
         openPriceFractionIndicator               |-> openPriceFractionIndicator.value,
         highPrice                                |-> highPrice.value,
         highPriceFractionIndicator               |-> highPriceFractionIndicator.value,
         lowPrice                                 |-> lowPrice.value,
         lowPriceFractionIndicator                |-> lowPriceFractionIndicator.value,
         settlementPrice                          |-> settlementPrice.value,
         settlementPriceFractionIndicator         |-> settlementPriceFractionIndicator.value,
         netPresentValueA                         |-> netPresentValueA.value,
         netPresentValueFractionIndicator         |-> netPresentValueFractionIndicator.value,
         historicalCouponB                        |-> historicalCouponB.value,
         historicalCouponFractionIndicator        |-> historicalCouponFractionIndicator.value,
         priceAlignmentInterestC                  |-> priceAlignmentInterestC.value,
         priceAlignmentInterestFractionIndicator  |-> priceAlignmentInterestFractionIndicator.value,
         netChangeSign                            |-> netChangeSign.value,
         netChange                                |-> netChange.value,
         netChangeFractionIndicator               |-> netChangeFractionIndicator.value,
         volume                                   |-> volume.value,
         previousSettlementPrice                  |-> previousSettlementPrice.value,
         previousSettlementPriceFractionIndicator |-> previousSettlementPriceFractionIndicator.value,
         previousResetRate                        |-> previousResetRate.value,
         previousResetRateFractionIndicator       |-> previousResetRateFractionIndicator.value,
         openInterest                             |-> openInterest.value,
         reason                                   |-> reason.value ], reason.rest)

ZeroSwapFutureSummaryMessage ==
    [ exchangeId                               |-> [i \in 1 .. 1 |-> 0],
      rootSymbol                               |-> [i \in 1 .. 6 |-> 0],
      expiryMonth                              |-> [i \in 1 .. 1 |-> 0],
      expiryYear                               |-> [i \in 1 .. 2 |-> 0],
      expiryDay                                |-> [i \in 1 .. 2 |-> 0],
      tenor                                    |-> [i \in 1 .. 2 |-> 0],
      fixedRate                                |-> [i \in 1 .. 5 |-> 0],
      fixedRateFractionIndicator               |-> [i \in 1 .. 1 |-> 0],
      bidPriceSummary                          |-> [i \in 1 .. 6 |-> 0],
      bidPriceFractionIndicator                |-> [i \in 1 .. 1 |-> 0],
      bidSize                                  |-> [i \in 1 .. 5 |-> 0],
      askPriceSummary                          |-> [i \in 1 .. 6 |-> 0],
      askPriceFractionIndicator                |-> [i \in 1 .. 1 |-> 0],
      askSize                                  |-> [i \in 1 .. 5 |-> 0],
      lastPrice                                |-> [i \in 1 .. 6 |-> 0],
      lastPriceFractionIndicator               |-> [i \in 1 .. 1 |-> 0],
      openPrice                                |-> [i \in 1 .. 6 |-> 0],
      openPriceFractionIndicator               |-> [i \in 1 .. 1 |-> 0],
      highPrice                                |-> [i \in 1 .. 6 |-> 0],
      highPriceFractionIndicator               |-> [i \in 1 .. 1 |-> 0],
      lowPrice                                 |-> [i \in 1 .. 6 |-> 0],
      lowPriceFractionIndicator                |-> [i \in 1 .. 1 |-> 0],
      settlementPrice                          |-> [i \in 1 .. 6 |-> 0],
      settlementPriceFractionIndicator         |-> [i \in 1 .. 1 |-> 0],
      netPresentValueA                         |-> [i \in 1 .. 11 |-> 0],
      netPresentValueFractionIndicator         |-> [i \in 1 .. 1 |-> 0],
      historicalCouponB                        |-> [i \in 1 .. 11 |-> 0],
      historicalCouponFractionIndicator        |-> [i \in 1 .. 1 |-> 0],
      priceAlignmentInterestC                  |-> [i \in 1 .. 11 |-> 0],
      priceAlignmentInterestFractionIndicator  |-> [i \in 1 .. 1 |-> 0],
      netChangeSign                            |-> [i \in 1 .. 1 |-> 0],
      netChange                                |-> [i \in 1 .. 6 |-> 0],
      netChangeFractionIndicator               |-> [i \in 1 .. 1 |-> 0],
      volume                                   |-> [i \in 1 .. 8 |-> 0],
      previousSettlementPrice                  |-> [i \in 1 .. 6 |-> 0],
      previousSettlementPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      previousResetRate                        |-> [i \in 1 .. 6 |-> 0],
      previousResetRateFractionIndicator       |-> [i \in 1 .. 1 |-> 0],
      openInterest                             |-> [i \in 1 .. 7 |-> 0],
      reason                                   |-> [i \in 1 .. 1 |-> 0] ]

(* Swap Future Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedSwapFutureSummaryMessage ==
    { ZeroSwapFutureSummaryMessage }
        \cup { [ZeroSwapFutureSummaryMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureSummaryMessage EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroSwapFutureSummaryMessage EXCEPT !.expiryMonth = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureSummaryMessage EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroSwapFutureSummaryMessage EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroSwapFutureSummaryMessage EXCEPT !.tenor = one] : one \in Sample(2) }
        \cup { [ZeroSwapFutureSummaryMessage EXCEPT !.fixedRate = one] : one \in Sample(5) }
        \cup { [ZeroSwapFutureSummaryMessage EXCEPT !.fixedRateFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureSummaryMessage EXCEPT !.bidPriceSummary = one] : one \in Sample(6) }
        \cup { [ZeroSwapFutureSummaryMessage EXCEPT !.bidPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureSummaryMessage EXCEPT !.bidSize = one] : one \in Sample(5) }
        \cup { [ZeroSwapFutureSummaryMessage EXCEPT !.askPriceSummary = one] : one \in Sample(6) }
        \cup { [ZeroSwapFutureSummaryMessage EXCEPT !.askPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureSummaryMessage EXCEPT !.askSize = one] : one \in Sample(5) }
        \cup { [ZeroSwapFutureSummaryMessage EXCEPT !.lastPrice = one] : one \in Sample(6) }
        \cup { [ZeroSwapFutureSummaryMessage EXCEPT !.lastPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureSummaryMessage EXCEPT !.openPrice = one] : one \in Sample(6) }
        \cup { [ZeroSwapFutureSummaryMessage EXCEPT !.openPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureSummaryMessage EXCEPT !.highPrice = one] : one \in Sample(6) }
        \cup { [ZeroSwapFutureSummaryMessage EXCEPT !.highPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureSummaryMessage EXCEPT !.lowPrice = one] : one \in Sample(6) }
        \cup { [ZeroSwapFutureSummaryMessage EXCEPT !.lowPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureSummaryMessage EXCEPT !.settlementPrice = one] : one \in Sample(6) }
        \cup { [ZeroSwapFutureSummaryMessage EXCEPT !.settlementPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureSummaryMessage EXCEPT !.netPresentValueA = one] : one \in Sample(11) }
        \cup { [ZeroSwapFutureSummaryMessage EXCEPT !.netPresentValueFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureSummaryMessage EXCEPT !.historicalCouponB = one] : one \in Sample(11) }
        \cup { [ZeroSwapFutureSummaryMessage EXCEPT !.historicalCouponFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureSummaryMessage EXCEPT !.priceAlignmentInterestC = one] : one \in Sample(11) }
        \cup { [ZeroSwapFutureSummaryMessage EXCEPT !.priceAlignmentInterestFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureSummaryMessage EXCEPT !.netChangeSign = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureSummaryMessage EXCEPT !.netChange = one] : one \in Sample(6) }
        \cup { [ZeroSwapFutureSummaryMessage EXCEPT !.netChangeFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureSummaryMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroSwapFutureSummaryMessage EXCEPT !.previousSettlementPrice = one] : one \in Sample(6) }
        \cup { [ZeroSwapFutureSummaryMessage EXCEPT !.previousSettlementPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureSummaryMessage EXCEPT !.previousResetRate = one] : one \in Sample(6) }
        \cup { [ZeroSwapFutureSummaryMessage EXCEPT !.previousResetRateFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureSummaryMessage EXCEPT !.openInterest = one] : one \in Sample(7) }
        \cup { [ZeroSwapFutureSummaryMessage EXCEPT !.reason = one] : one \in Sample(1) }

(***************************************************************************)
(* Beginning Of Options Summary Message: 1 bytes                           *)
(***************************************************************************)

BeginningOfOptionsSummaryMessage ==
    [ exchangeId : Sample(1) ]

EncodeBeginningOfOptionsSummaryMessage(message) ==
    message.exchangeId

DecodeBeginningOfOptionsSummaryMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    Ok([ exchangeId |-> exchangeId.value ], exchangeId.rest)

ZeroBeginningOfOptionsSummaryMessage ==
    [ exchangeId |-> [i \in 1 .. 1 |-> 0] ]

(* Beginning Of Options Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedBeginningOfOptionsSummaryMessage ==
    { ZeroBeginningOfOptionsSummaryMessage }
        \cup { [ZeroBeginningOfOptionsSummaryMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }

(***************************************************************************)
(* Beginning Of Future Options Summary Message: 1 bytes                    *)
(***************************************************************************)

BeginningOfFutureOptionsSummaryMessage ==
    [ exchangeId : Sample(1) ]

EncodeBeginningOfFutureOptionsSummaryMessage(message) ==
    message.exchangeId

DecodeBeginningOfFutureOptionsSummaryMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    Ok([ exchangeId |-> exchangeId.value ], exchangeId.rest)

ZeroBeginningOfFutureOptionsSummaryMessage ==
    [ exchangeId |-> [i \in 1 .. 1 |-> 0] ]

(* Beginning Of Future Options Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedBeginningOfFutureOptionsSummaryMessage ==
    { ZeroBeginningOfFutureOptionsSummaryMessage }
        \cup { [ZeroBeginningOfFutureOptionsSummaryMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }

(***************************************************************************)
(* Beginning Of Futures Summary Message: 1 bytes                           *)
(***************************************************************************)

BeginningOfFuturesSummaryMessage ==
    [ exchangeId : Sample(1) ]

EncodeBeginningOfFuturesSummaryMessage(message) ==
    message.exchangeId

DecodeBeginningOfFuturesSummaryMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    Ok([ exchangeId |-> exchangeId.value ], exchangeId.rest)

ZeroBeginningOfFuturesSummaryMessage ==
    [ exchangeId |-> [i \in 1 .. 1 |-> 0] ]

(* Beginning Of Futures Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedBeginningOfFuturesSummaryMessage ==
    { ZeroBeginningOfFuturesSummaryMessage }
        \cup { [ZeroBeginningOfFuturesSummaryMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }

(***************************************************************************)
(* Beginning Of Strategy Summary Message: 1 bytes                          *)
(***************************************************************************)

BeginningOfStrategySummaryMessage ==
    [ exchangeId : Sample(1) ]

EncodeBeginningOfStrategySummaryMessage(message) ==
    message.exchangeId

DecodeBeginningOfStrategySummaryMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    Ok([ exchangeId |-> exchangeId.value ], exchangeId.rest)

ZeroBeginningOfStrategySummaryMessage ==
    [ exchangeId |-> [i \in 1 .. 1 |-> 0] ]

(* Beginning Of Strategy Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedBeginningOfStrategySummaryMessage ==
    { ZeroBeginningOfStrategySummaryMessage }
        \cup { [ZeroBeginningOfStrategySummaryMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }

(***************************************************************************)
(* Swap Future Beginning Of Summary Message: 1 bytes                       *)
(***************************************************************************)

SwapFutureBeginningOfSummaryMessage ==
    [ exchangeId : Sample(1) ]

EncodeSwapFutureBeginningOfSummaryMessage(message) ==
    message.exchangeId

DecodeSwapFutureBeginningOfSummaryMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    Ok([ exchangeId |-> exchangeId.value ], exchangeId.rest)

ZeroSwapFutureBeginningOfSummaryMessage ==
    [ exchangeId |-> [i \in 1 .. 1 |-> 0] ]

(* Swap Future Beginning Of Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedSwapFutureBeginningOfSummaryMessage ==
    { ZeroSwapFutureBeginningOfSummaryMessage }
        \cup { [ZeroSwapFutureBeginningOfSummaryMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }

(***************************************************************************)
(* Option Trade Correction Message: 76 bytes                               *)
(***************************************************************************)

OptionTradeCorrectionMessage ==
    [ exchangeId                   : Sample(1),
      rootSymbol                   : Sample(6),
      expiryMonth                  : Sample(1),
      filler1                      : Sample(1),
      strikePriceInstrument        : Sample(7),
      strikePriceFractionIndicator : Sample(1),
      expiryYear                   : Sample(2),
      expiryDay                    : Sample(2),
      volume                       : Sample(8),
      tradePrice                   : Sample(6),
      tradePriceFractionIndicator  : Sample(1),
      netChangeSign                : Sample(1),
      netChange                    : Sample(6),
      netChangeFractionIndicator   : Sample(1),
      filler6                      : Sample(6),
      timestamp                    : Sample(9),
      openInterest                 : Sample(7),
      secondFiller1                : Sample(1),
      priceIndicatorMarker         : Sample(1),
      tradeNumber                  : Sample(8) ]

EncodeOptionTradeCorrectionMessage(message) ==
    message.exchangeId
        \o message.rootSymbol
        \o message.expiryMonth
        \o message.filler1
        \o message.strikePriceInstrument
        \o message.strikePriceFractionIndicator
        \o message.expiryYear
        \o message.expiryDay
        \o message.volume
        \o message.tradePrice
        \o message.tradePriceFractionIndicator
        \o message.netChangeSign
        \o message.netChange
        \o message.netChangeFractionIndicator
        \o message.filler6
        \o message.timestamp
        \o message.openInterest
        \o message.secondFiller1
        \o message.priceIndicatorMarker
        \o message.tradeNumber

DecodeOptionTradeCorrectionMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET rootSymbol == ReadBytes(exchangeId.rest, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET expiryMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~expiryMonth.ok THEN Fail ELSE
    LET filler1 == ReadBytes(expiryMonth.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET strikePriceInstrument == ReadBytes(filler1.rest, 7) IN IF ~strikePriceInstrument.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePriceInstrument.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(strikePriceFractionIndicator.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET volume == ReadBytes(expiryDay.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(volume.rest, 6) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradePriceFractionIndicator == ReadBytes(tradePrice.rest, 1) IN IF ~tradePriceFractionIndicator.ok THEN Fail ELSE
    LET netChangeSign == ReadBytes(tradePriceFractionIndicator.rest, 1) IN IF ~netChangeSign.ok THEN Fail ELSE
    LET netChange == ReadBytes(netChangeSign.rest, 6) IN IF ~netChange.ok THEN Fail ELSE
    LET netChangeFractionIndicator == ReadBytes(netChange.rest, 1) IN IF ~netChangeFractionIndicator.ok THEN Fail ELSE
    LET filler6 == ReadBytes(netChangeFractionIndicator.rest, 6) IN IF ~filler6.ok THEN Fail ELSE
    LET timestamp == ReadBytes(filler6.rest, 9) IN IF ~timestamp.ok THEN Fail ELSE
    LET openInterest == ReadBytes(timestamp.rest, 7) IN IF ~openInterest.ok THEN Fail ELSE
    LET secondFiller1 == ReadBytes(openInterest.rest, 1) IN IF ~secondFiller1.ok THEN Fail ELSE
    LET priceIndicatorMarker == ReadBytes(secondFiller1.rest, 1) IN IF ~priceIndicatorMarker.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(priceIndicatorMarker.rest, 8) IN IF ~tradeNumber.ok THEN Fail ELSE
    Ok([ exchangeId                   |-> exchangeId.value,
         rootSymbol                   |-> rootSymbol.value,
         expiryMonth                  |-> expiryMonth.value,
         filler1                      |-> filler1.value,
         strikePriceInstrument        |-> strikePriceInstrument.value,
         strikePriceFractionIndicator |-> strikePriceFractionIndicator.value,
         expiryYear                   |-> expiryYear.value,
         expiryDay                    |-> expiryDay.value,
         volume                       |-> volume.value,
         tradePrice                   |-> tradePrice.value,
         tradePriceFractionIndicator  |-> tradePriceFractionIndicator.value,
         netChangeSign                |-> netChangeSign.value,
         netChange                    |-> netChange.value,
         netChangeFractionIndicator   |-> netChangeFractionIndicator.value,
         filler6                      |-> filler6.value,
         timestamp                    |-> timestamp.value,
         openInterest                 |-> openInterest.value,
         secondFiller1                |-> secondFiller1.value,
         priceIndicatorMarker         |-> priceIndicatorMarker.value,
         tradeNumber                  |-> tradeNumber.value ], tradeNumber.rest)

ZeroOptionTradeCorrectionMessage ==
    [ exchangeId                   |-> [i \in 1 .. 1 |-> 0],
      rootSymbol                   |-> [i \in 1 .. 6 |-> 0],
      expiryMonth                  |-> [i \in 1 .. 1 |-> 0],
      filler1                      |-> [i \in 1 .. 1 |-> 0],
      strikePriceInstrument        |-> [i \in 1 .. 7 |-> 0],
      strikePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      expiryYear                   |-> [i \in 1 .. 2 |-> 0],
      expiryDay                    |-> [i \in 1 .. 2 |-> 0],
      volume                       |-> [i \in 1 .. 8 |-> 0],
      tradePrice                   |-> [i \in 1 .. 6 |-> 0],
      tradePriceFractionIndicator  |-> [i \in 1 .. 1 |-> 0],
      netChangeSign                |-> [i \in 1 .. 1 |-> 0],
      netChange                    |-> [i \in 1 .. 6 |-> 0],
      netChangeFractionIndicator   |-> [i \in 1 .. 1 |-> 0],
      filler6                      |-> [i \in 1 .. 6 |-> 0],
      timestamp                    |-> [i \in 1 .. 9 |-> 0],
      openInterest                 |-> [i \in 1 .. 7 |-> 0],
      secondFiller1                |-> [i \in 1 .. 1 |-> 0],
      priceIndicatorMarker         |-> [i \in 1 .. 1 |-> 0],
      tradeNumber                  |-> [i \in 1 .. 8 |-> 0] ]

(* Option Trade Correction Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionTradeCorrectionMessage ==
    { ZeroOptionTradeCorrectionMessage }
        \cup { [ZeroOptionTradeCorrectionMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeCorrectionMessage EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroOptionTradeCorrectionMessage EXCEPT !.expiryMonth = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeCorrectionMessage EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeCorrectionMessage EXCEPT !.strikePriceInstrument = one] : one \in Sample(7) }
        \cup { [ZeroOptionTradeCorrectionMessage EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeCorrectionMessage EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroOptionTradeCorrectionMessage EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroOptionTradeCorrectionMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroOptionTradeCorrectionMessage EXCEPT !.tradePrice = one] : one \in Sample(6) }
        \cup { [ZeroOptionTradeCorrectionMessage EXCEPT !.tradePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeCorrectionMessage EXCEPT !.netChangeSign = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeCorrectionMessage EXCEPT !.netChange = one] : one \in Sample(6) }
        \cup { [ZeroOptionTradeCorrectionMessage EXCEPT !.netChangeFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeCorrectionMessage EXCEPT !.filler6 = one] : one \in Sample(6) }
        \cup { [ZeroOptionTradeCorrectionMessage EXCEPT !.timestamp = one] : one \in Sample(9) }
        \cup { [ZeroOptionTradeCorrectionMessage EXCEPT !.openInterest = one] : one \in Sample(7) }
        \cup { [ZeroOptionTradeCorrectionMessage EXCEPT !.secondFiller1 = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeCorrectionMessage EXCEPT !.priceIndicatorMarker = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeCorrectionMessage EXCEPT !.tradeNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Future Options Trade Correction Message: 77 bytes                       *)
(***************************************************************************)

FutureOptionsTradeCorrectionMessage ==
    [ exchangeId                   : Sample(1),
      rootSymbol                   : Sample(6),
      contractMonthCode            : Sample(1),
      expiryYear                   : Sample(2),
      expiryDay                    : Sample(2),
      callPutCode                  : Sample(1),
      strikePriceInstrument        : Sample(7),
      strikePriceFractionIndicator : Sample(1),
      volume                       : Sample(8),
      tradePrice                   : Sample(6),
      tradePriceFractionIndicator  : Sample(1),
      priceIndicatorMarker         : Sample(1),
      netChangeSign                : Sample(1),
      netChange                    : Sample(6),
      netChangeFractionIndicator   : Sample(1),
      filler6                      : Sample(6),
      timestamp                    : Sample(9),
      openInterest                 : Sample(7),
      filler2                      : Sample(2),
      tradeNumber                  : Sample(8) ]

EncodeFutureOptionsTradeCorrectionMessage(message) ==
    message.exchangeId
        \o message.rootSymbol
        \o message.contractMonthCode
        \o message.expiryYear
        \o message.expiryDay
        \o message.callPutCode
        \o message.strikePriceInstrument
        \o message.strikePriceFractionIndicator
        \o message.volume
        \o message.tradePrice
        \o message.tradePriceFractionIndicator
        \o message.priceIndicatorMarker
        \o message.netChangeSign
        \o message.netChange
        \o message.netChangeFractionIndicator
        \o message.filler6
        \o message.timestamp
        \o message.openInterest
        \o message.filler2
        \o message.tradeNumber

DecodeFutureOptionsTradeCorrectionMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET rootSymbol == ReadBytes(exchangeId.rest, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET contractMonthCode == ReadBytes(rootSymbol.rest, 1) IN IF ~contractMonthCode.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(contractMonthCode.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET callPutCode == ReadBytes(expiryDay.rest, 1) IN IF ~callPutCode.ok THEN Fail ELSE
    LET strikePriceInstrument == ReadBytes(callPutCode.rest, 7) IN IF ~strikePriceInstrument.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePriceInstrument.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    LET volume == ReadBytes(strikePriceFractionIndicator.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(volume.rest, 6) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradePriceFractionIndicator == ReadBytes(tradePrice.rest, 1) IN IF ~tradePriceFractionIndicator.ok THEN Fail ELSE
    LET priceIndicatorMarker == ReadBytes(tradePriceFractionIndicator.rest, 1) IN IF ~priceIndicatorMarker.ok THEN Fail ELSE
    LET netChangeSign == ReadBytes(priceIndicatorMarker.rest, 1) IN IF ~netChangeSign.ok THEN Fail ELSE
    LET netChange == ReadBytes(netChangeSign.rest, 6) IN IF ~netChange.ok THEN Fail ELSE
    LET netChangeFractionIndicator == ReadBytes(netChange.rest, 1) IN IF ~netChangeFractionIndicator.ok THEN Fail ELSE
    LET filler6 == ReadBytes(netChangeFractionIndicator.rest, 6) IN IF ~filler6.ok THEN Fail ELSE
    LET timestamp == ReadBytes(filler6.rest, 9) IN IF ~timestamp.ok THEN Fail ELSE
    LET openInterest == ReadBytes(timestamp.rest, 7) IN IF ~openInterest.ok THEN Fail ELSE
    LET filler2 == ReadBytes(openInterest.rest, 2) IN IF ~filler2.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(filler2.rest, 8) IN IF ~tradeNumber.ok THEN Fail ELSE
    Ok([ exchangeId                   |-> exchangeId.value,
         rootSymbol                   |-> rootSymbol.value,
         contractMonthCode            |-> contractMonthCode.value,
         expiryYear                   |-> expiryYear.value,
         expiryDay                    |-> expiryDay.value,
         callPutCode                  |-> callPutCode.value,
         strikePriceInstrument        |-> strikePriceInstrument.value,
         strikePriceFractionIndicator |-> strikePriceFractionIndicator.value,
         volume                       |-> volume.value,
         tradePrice                   |-> tradePrice.value,
         tradePriceFractionIndicator  |-> tradePriceFractionIndicator.value,
         priceIndicatorMarker         |-> priceIndicatorMarker.value,
         netChangeSign                |-> netChangeSign.value,
         netChange                    |-> netChange.value,
         netChangeFractionIndicator   |-> netChangeFractionIndicator.value,
         filler6                      |-> filler6.value,
         timestamp                    |-> timestamp.value,
         openInterest                 |-> openInterest.value,
         filler2                      |-> filler2.value,
         tradeNumber                  |-> tradeNumber.value ], tradeNumber.rest)

ZeroFutureOptionsTradeCorrectionMessage ==
    [ exchangeId                   |-> [i \in 1 .. 1 |-> 0],
      rootSymbol                   |-> [i \in 1 .. 6 |-> 0],
      contractMonthCode            |-> [i \in 1 .. 1 |-> 0],
      expiryYear                   |-> [i \in 1 .. 2 |-> 0],
      expiryDay                    |-> [i \in 1 .. 2 |-> 0],
      callPutCode                  |-> [i \in 1 .. 1 |-> 0],
      strikePriceInstrument        |-> [i \in 1 .. 7 |-> 0],
      strikePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      volume                       |-> [i \in 1 .. 8 |-> 0],
      tradePrice                   |-> [i \in 1 .. 6 |-> 0],
      tradePriceFractionIndicator  |-> [i \in 1 .. 1 |-> 0],
      priceIndicatorMarker         |-> [i \in 1 .. 1 |-> 0],
      netChangeSign                |-> [i \in 1 .. 1 |-> 0],
      netChange                    |-> [i \in 1 .. 6 |-> 0],
      netChangeFractionIndicator   |-> [i \in 1 .. 1 |-> 0],
      filler6                      |-> [i \in 1 .. 6 |-> 0],
      timestamp                    |-> [i \in 1 .. 9 |-> 0],
      openInterest                 |-> [i \in 1 .. 7 |-> 0],
      filler2                      |-> [i \in 1 .. 2 |-> 0],
      tradeNumber                  |-> [i \in 1 .. 8 |-> 0] ]

(* Future Options Trade Correction Message at zero, then each field in turn at the values it is checked at *)
CheckedFutureOptionsTradeCorrectionMessage ==
    { ZeroFutureOptionsTradeCorrectionMessage }
        \cup { [ZeroFutureOptionsTradeCorrectionMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsTradeCorrectionMessage EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionsTradeCorrectionMessage EXCEPT !.contractMonthCode = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsTradeCorrectionMessage EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionsTradeCorrectionMessage EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionsTradeCorrectionMessage EXCEPT !.callPutCode = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsTradeCorrectionMessage EXCEPT !.strikePriceInstrument = one] : one \in Sample(7) }
        \cup { [ZeroFutureOptionsTradeCorrectionMessage EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsTradeCorrectionMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroFutureOptionsTradeCorrectionMessage EXCEPT !.tradePrice = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionsTradeCorrectionMessage EXCEPT !.tradePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsTradeCorrectionMessage EXCEPT !.priceIndicatorMarker = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsTradeCorrectionMessage EXCEPT !.netChangeSign = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsTradeCorrectionMessage EXCEPT !.netChange = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionsTradeCorrectionMessage EXCEPT !.netChangeFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsTradeCorrectionMessage EXCEPT !.filler6 = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionsTradeCorrectionMessage EXCEPT !.timestamp = one] : one \in Sample(9) }
        \cup { [ZeroFutureOptionsTradeCorrectionMessage EXCEPT !.openInterest = one] : one \in Sample(7) }
        \cup { [ZeroFutureOptionsTradeCorrectionMessage EXCEPT !.filler2 = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionsTradeCorrectionMessage EXCEPT !.tradeNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Futures Trade Correction Message: 59 bytes                              *)
(***************************************************************************)

FuturesTradeCorrectionMessage ==
    [ exchangeId                  : Sample(1),
      rootSymbol                  : Sample(6),
      deliveryMonth               : Sample(1),
      deliveryYearFutures         : Sample(2),
      deliveryDay                 : Sample(2),
      volume                      : Sample(8),
      tradePrice                  : Sample(6),
      tradePriceFractionIndicator : Sample(1),
      netChangeSign               : Sample(1),
      netChange                   : Sample(6),
      netChangeFractionIndicator  : Sample(1),
      filler6                     : Sample(6),
      timestamp                   : Sample(9),
      priceIndicatorMarker        : Sample(1),
      tradeNumber                 : Sample(8) ]

EncodeFuturesTradeCorrectionMessage(message) ==
    message.exchangeId
        \o message.rootSymbol
        \o message.deliveryMonth
        \o message.deliveryYearFutures
        \o message.deliveryDay
        \o message.volume
        \o message.tradePrice
        \o message.tradePriceFractionIndicator
        \o message.netChangeSign
        \o message.netChange
        \o message.netChangeFractionIndicator
        \o message.filler6
        \o message.timestamp
        \o message.priceIndicatorMarker
        \o message.tradeNumber

DecodeFuturesTradeCorrectionMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET rootSymbol == ReadBytes(exchangeId.rest, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET deliveryMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~deliveryMonth.ok THEN Fail ELSE
    LET deliveryYearFutures == ReadBytes(deliveryMonth.rest, 2) IN IF ~deliveryYearFutures.ok THEN Fail ELSE
    LET deliveryDay == ReadBytes(deliveryYearFutures.rest, 2) IN IF ~deliveryDay.ok THEN Fail ELSE
    LET volume == ReadBytes(deliveryDay.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(volume.rest, 6) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradePriceFractionIndicator == ReadBytes(tradePrice.rest, 1) IN IF ~tradePriceFractionIndicator.ok THEN Fail ELSE
    LET netChangeSign == ReadBytes(tradePriceFractionIndicator.rest, 1) IN IF ~netChangeSign.ok THEN Fail ELSE
    LET netChange == ReadBytes(netChangeSign.rest, 6) IN IF ~netChange.ok THEN Fail ELSE
    LET netChangeFractionIndicator == ReadBytes(netChange.rest, 1) IN IF ~netChangeFractionIndicator.ok THEN Fail ELSE
    LET filler6 == ReadBytes(netChangeFractionIndicator.rest, 6) IN IF ~filler6.ok THEN Fail ELSE
    LET timestamp == ReadBytes(filler6.rest, 9) IN IF ~timestamp.ok THEN Fail ELSE
    LET priceIndicatorMarker == ReadBytes(timestamp.rest, 1) IN IF ~priceIndicatorMarker.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(priceIndicatorMarker.rest, 8) IN IF ~tradeNumber.ok THEN Fail ELSE
    Ok([ exchangeId                  |-> exchangeId.value,
         rootSymbol                  |-> rootSymbol.value,
         deliveryMonth               |-> deliveryMonth.value,
         deliveryYearFutures         |-> deliveryYearFutures.value,
         deliveryDay                 |-> deliveryDay.value,
         volume                      |-> volume.value,
         tradePrice                  |-> tradePrice.value,
         tradePriceFractionIndicator |-> tradePriceFractionIndicator.value,
         netChangeSign               |-> netChangeSign.value,
         netChange                   |-> netChange.value,
         netChangeFractionIndicator  |-> netChangeFractionIndicator.value,
         filler6                     |-> filler6.value,
         timestamp                   |-> timestamp.value,
         priceIndicatorMarker        |-> priceIndicatorMarker.value,
         tradeNumber                 |-> tradeNumber.value ], tradeNumber.rest)

ZeroFuturesTradeCorrectionMessage ==
    [ exchangeId                  |-> [i \in 1 .. 1 |-> 0],
      rootSymbol                  |-> [i \in 1 .. 6 |-> 0],
      deliveryMonth               |-> [i \in 1 .. 1 |-> 0],
      deliveryYearFutures         |-> [i \in 1 .. 2 |-> 0],
      deliveryDay                 |-> [i \in 1 .. 2 |-> 0],
      volume                      |-> [i \in 1 .. 8 |-> 0],
      tradePrice                  |-> [i \in 1 .. 6 |-> 0],
      tradePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      netChangeSign               |-> [i \in 1 .. 1 |-> 0],
      netChange                   |-> [i \in 1 .. 6 |-> 0],
      netChangeFractionIndicator  |-> [i \in 1 .. 1 |-> 0],
      filler6                     |-> [i \in 1 .. 6 |-> 0],
      timestamp                   |-> [i \in 1 .. 9 |-> 0],
      priceIndicatorMarker        |-> [i \in 1 .. 1 |-> 0],
      tradeNumber                 |-> [i \in 1 .. 8 |-> 0] ]

(* Futures Trade Correction Message at zero, then each field in turn at the values it is checked at *)
CheckedFuturesTradeCorrectionMessage ==
    { ZeroFuturesTradeCorrectionMessage }
        \cup { [ZeroFuturesTradeCorrectionMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroFuturesTradeCorrectionMessage EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroFuturesTradeCorrectionMessage EXCEPT !.deliveryMonth = one] : one \in Sample(1) }
        \cup { [ZeroFuturesTradeCorrectionMessage EXCEPT !.deliveryYearFutures = one] : one \in Sample(2) }
        \cup { [ZeroFuturesTradeCorrectionMessage EXCEPT !.deliveryDay = one] : one \in Sample(2) }
        \cup { [ZeroFuturesTradeCorrectionMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroFuturesTradeCorrectionMessage EXCEPT !.tradePrice = one] : one \in Sample(6) }
        \cup { [ZeroFuturesTradeCorrectionMessage EXCEPT !.tradePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFuturesTradeCorrectionMessage EXCEPT !.netChangeSign = one] : one \in Sample(1) }
        \cup { [ZeroFuturesTradeCorrectionMessage EXCEPT !.netChange = one] : one \in Sample(6) }
        \cup { [ZeroFuturesTradeCorrectionMessage EXCEPT !.netChangeFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFuturesTradeCorrectionMessage EXCEPT !.filler6 = one] : one \in Sample(6) }
        \cup { [ZeroFuturesTradeCorrectionMessage EXCEPT !.timestamp = one] : one \in Sample(9) }
        \cup { [ZeroFuturesTradeCorrectionMessage EXCEPT !.priceIndicatorMarker = one] : one \in Sample(1) }
        \cup { [ZeroFuturesTradeCorrectionMessage EXCEPT !.tradeNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Strategy Trade Correction Message: 79 bytes                             *)
(***************************************************************************)

StrategyTradeCorrectionMessage ==
    [ exchangeId                  : Sample(1),
      symbol                      : Sample(30),
      volume                      : Sample(8),
      tradePriceSign              : Sample(1),
      tradePrice                  : Sample(6),
      tradePriceFractionIndicator : Sample(1),
      netChangeSign               : Sample(1),
      netChange                   : Sample(6),
      netChangeFractionIndicator  : Sample(1),
      filler6                     : Sample(6),
      timestamp                   : Sample(9),
      priceIndicatorMarker        : Sample(1),
      tradeNumber                 : Sample(8) ]

EncodeStrategyTradeCorrectionMessage(message) ==
    message.exchangeId
        \o message.symbol
        \o message.volume
        \o message.tradePriceSign
        \o message.tradePrice
        \o message.tradePriceFractionIndicator
        \o message.netChangeSign
        \o message.netChange
        \o message.netChangeFractionIndicator
        \o message.filler6
        \o message.timestamp
        \o message.priceIndicatorMarker
        \o message.tradeNumber

DecodeStrategyTradeCorrectionMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET symbol == ReadBytes(exchangeId.rest, 30) IN IF ~symbol.ok THEN Fail ELSE
    LET volume == ReadBytes(symbol.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET tradePriceSign == ReadBytes(volume.rest, 1) IN IF ~tradePriceSign.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(tradePriceSign.rest, 6) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradePriceFractionIndicator == ReadBytes(tradePrice.rest, 1) IN IF ~tradePriceFractionIndicator.ok THEN Fail ELSE
    LET netChangeSign == ReadBytes(tradePriceFractionIndicator.rest, 1) IN IF ~netChangeSign.ok THEN Fail ELSE
    LET netChange == ReadBytes(netChangeSign.rest, 6) IN IF ~netChange.ok THEN Fail ELSE
    LET netChangeFractionIndicator == ReadBytes(netChange.rest, 1) IN IF ~netChangeFractionIndicator.ok THEN Fail ELSE
    LET filler6 == ReadBytes(netChangeFractionIndicator.rest, 6) IN IF ~filler6.ok THEN Fail ELSE
    LET timestamp == ReadBytes(filler6.rest, 9) IN IF ~timestamp.ok THEN Fail ELSE
    LET priceIndicatorMarker == ReadBytes(timestamp.rest, 1) IN IF ~priceIndicatorMarker.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(priceIndicatorMarker.rest, 8) IN IF ~tradeNumber.ok THEN Fail ELSE
    Ok([ exchangeId                  |-> exchangeId.value,
         symbol                      |-> symbol.value,
         volume                      |-> volume.value,
         tradePriceSign              |-> tradePriceSign.value,
         tradePrice                  |-> tradePrice.value,
         tradePriceFractionIndicator |-> tradePriceFractionIndicator.value,
         netChangeSign               |-> netChangeSign.value,
         netChange                   |-> netChange.value,
         netChangeFractionIndicator  |-> netChangeFractionIndicator.value,
         filler6                     |-> filler6.value,
         timestamp                   |-> timestamp.value,
         priceIndicatorMarker        |-> priceIndicatorMarker.value,
         tradeNumber                 |-> tradeNumber.value ], tradeNumber.rest)

ZeroStrategyTradeCorrectionMessage ==
    [ exchangeId                  |-> [i \in 1 .. 1 |-> 0],
      symbol                      |-> [i \in 1 .. 30 |-> 0],
      volume                      |-> [i \in 1 .. 8 |-> 0],
      tradePriceSign              |-> [i \in 1 .. 1 |-> 0],
      tradePrice                  |-> [i \in 1 .. 6 |-> 0],
      tradePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      netChangeSign               |-> [i \in 1 .. 1 |-> 0],
      netChange                   |-> [i \in 1 .. 6 |-> 0],
      netChangeFractionIndicator  |-> [i \in 1 .. 1 |-> 0],
      filler6                     |-> [i \in 1 .. 6 |-> 0],
      timestamp                   |-> [i \in 1 .. 9 |-> 0],
      priceIndicatorMarker        |-> [i \in 1 .. 1 |-> 0],
      tradeNumber                 |-> [i \in 1 .. 8 |-> 0] ]

(* Strategy Trade Correction Message at zero, then each field in turn at the values it is checked at *)
CheckedStrategyTradeCorrectionMessage ==
    { ZeroStrategyTradeCorrectionMessage }
        \cup { [ZeroStrategyTradeCorrectionMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroStrategyTradeCorrectionMessage EXCEPT !.symbol = one] : one \in Sample(30) }
        \cup { [ZeroStrategyTradeCorrectionMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroStrategyTradeCorrectionMessage EXCEPT !.tradePriceSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategyTradeCorrectionMessage EXCEPT !.tradePrice = one] : one \in Sample(6) }
        \cup { [ZeroStrategyTradeCorrectionMessage EXCEPT !.tradePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStrategyTradeCorrectionMessage EXCEPT !.netChangeSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategyTradeCorrectionMessage EXCEPT !.netChange = one] : one \in Sample(6) }
        \cup { [ZeroStrategyTradeCorrectionMessage EXCEPT !.netChangeFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStrategyTradeCorrectionMessage EXCEPT !.filler6 = one] : one \in Sample(6) }
        \cup { [ZeroStrategyTradeCorrectionMessage EXCEPT !.timestamp = one] : one \in Sample(9) }
        \cup { [ZeroStrategyTradeCorrectionMessage EXCEPT !.priceIndicatorMarker = one] : one \in Sample(1) }
        \cup { [ZeroStrategyTradeCorrectionMessage EXCEPT !.tradeNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Swap Future Trade Correction Message: 61 bytes                          *)
(***************************************************************************)

SwapFutureTradeCorrectionMessage ==
    [ exchangeId                  : Sample(1),
      rootSymbol                  : Sample(6),
      expiryMonth                 : Sample(1),
      expiryYear                  : Sample(2),
      expiryDay                   : Sample(2),
      tenor                       : Sample(2),
      fixedRate                   : Sample(5),
      fixedRateFractionIndicator  : Sample(1),
      tradeVolume                 : Sample(8),
      tradePrice                  : Sample(6),
      tradePriceFractionIndicator : Sample(1),
      netChangeSign               : Sample(1),
      netChange                   : Sample(6),
      netChangeFractionIndicator  : Sample(1),
      timestamp                   : Sample(9),
      priceIndicatorMarker        : Sample(1),
      tradeNumber                 : Sample(8) ]

EncodeSwapFutureTradeCorrectionMessage(message) ==
    message.exchangeId
        \o message.rootSymbol
        \o message.expiryMonth
        \o message.expiryYear
        \o message.expiryDay
        \o message.tenor
        \o message.fixedRate
        \o message.fixedRateFractionIndicator
        \o message.tradeVolume
        \o message.tradePrice
        \o message.tradePriceFractionIndicator
        \o message.netChangeSign
        \o message.netChange
        \o message.netChangeFractionIndicator
        \o message.timestamp
        \o message.priceIndicatorMarker
        \o message.tradeNumber

DecodeSwapFutureTradeCorrectionMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET rootSymbol == ReadBytes(exchangeId.rest, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET expiryMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~expiryMonth.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(expiryMonth.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET tenor == ReadBytes(expiryDay.rest, 2) IN IF ~tenor.ok THEN Fail ELSE
    LET fixedRate == ReadBytes(tenor.rest, 5) IN IF ~fixedRate.ok THEN Fail ELSE
    LET fixedRateFractionIndicator == ReadBytes(fixedRate.rest, 1) IN IF ~fixedRateFractionIndicator.ok THEN Fail ELSE
    LET tradeVolume == ReadBytes(fixedRateFractionIndicator.rest, 8) IN IF ~tradeVolume.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(tradeVolume.rest, 6) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradePriceFractionIndicator == ReadBytes(tradePrice.rest, 1) IN IF ~tradePriceFractionIndicator.ok THEN Fail ELSE
    LET netChangeSign == ReadBytes(tradePriceFractionIndicator.rest, 1) IN IF ~netChangeSign.ok THEN Fail ELSE
    LET netChange == ReadBytes(netChangeSign.rest, 6) IN IF ~netChange.ok THEN Fail ELSE
    LET netChangeFractionIndicator == ReadBytes(netChange.rest, 1) IN IF ~netChangeFractionIndicator.ok THEN Fail ELSE
    LET timestamp == ReadBytes(netChangeFractionIndicator.rest, 9) IN IF ~timestamp.ok THEN Fail ELSE
    LET priceIndicatorMarker == ReadBytes(timestamp.rest, 1) IN IF ~priceIndicatorMarker.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(priceIndicatorMarker.rest, 8) IN IF ~tradeNumber.ok THEN Fail ELSE
    Ok([ exchangeId                  |-> exchangeId.value,
         rootSymbol                  |-> rootSymbol.value,
         expiryMonth                 |-> expiryMonth.value,
         expiryYear                  |-> expiryYear.value,
         expiryDay                   |-> expiryDay.value,
         tenor                       |-> tenor.value,
         fixedRate                   |-> fixedRate.value,
         fixedRateFractionIndicator  |-> fixedRateFractionIndicator.value,
         tradeVolume                 |-> tradeVolume.value,
         tradePrice                  |-> tradePrice.value,
         tradePriceFractionIndicator |-> tradePriceFractionIndicator.value,
         netChangeSign               |-> netChangeSign.value,
         netChange                   |-> netChange.value,
         netChangeFractionIndicator  |-> netChangeFractionIndicator.value,
         timestamp                   |-> timestamp.value,
         priceIndicatorMarker        |-> priceIndicatorMarker.value,
         tradeNumber                 |-> tradeNumber.value ], tradeNumber.rest)

ZeroSwapFutureTradeCorrectionMessage ==
    [ exchangeId                  |-> [i \in 1 .. 1 |-> 0],
      rootSymbol                  |-> [i \in 1 .. 6 |-> 0],
      expiryMonth                 |-> [i \in 1 .. 1 |-> 0],
      expiryYear                  |-> [i \in 1 .. 2 |-> 0],
      expiryDay                   |-> [i \in 1 .. 2 |-> 0],
      tenor                       |-> [i \in 1 .. 2 |-> 0],
      fixedRate                   |-> [i \in 1 .. 5 |-> 0],
      fixedRateFractionIndicator  |-> [i \in 1 .. 1 |-> 0],
      tradeVolume                 |-> [i \in 1 .. 8 |-> 0],
      tradePrice                  |-> [i \in 1 .. 6 |-> 0],
      tradePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      netChangeSign               |-> [i \in 1 .. 1 |-> 0],
      netChange                   |-> [i \in 1 .. 6 |-> 0],
      netChangeFractionIndicator  |-> [i \in 1 .. 1 |-> 0],
      timestamp                   |-> [i \in 1 .. 9 |-> 0],
      priceIndicatorMarker        |-> [i \in 1 .. 1 |-> 0],
      tradeNumber                 |-> [i \in 1 .. 8 |-> 0] ]

(* Swap Future Trade Correction Message at zero, then each field in turn at the values it is checked at *)
CheckedSwapFutureTradeCorrectionMessage ==
    { ZeroSwapFutureTradeCorrectionMessage }
        \cup { [ZeroSwapFutureTradeCorrectionMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureTradeCorrectionMessage EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroSwapFutureTradeCorrectionMessage EXCEPT !.expiryMonth = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureTradeCorrectionMessage EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroSwapFutureTradeCorrectionMessage EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroSwapFutureTradeCorrectionMessage EXCEPT !.tenor = one] : one \in Sample(2) }
        \cup { [ZeroSwapFutureTradeCorrectionMessage EXCEPT !.fixedRate = one] : one \in Sample(5) }
        \cup { [ZeroSwapFutureTradeCorrectionMessage EXCEPT !.fixedRateFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureTradeCorrectionMessage EXCEPT !.tradeVolume = one] : one \in Sample(8) }
        \cup { [ZeroSwapFutureTradeCorrectionMessage EXCEPT !.tradePrice = one] : one \in Sample(6) }
        \cup { [ZeroSwapFutureTradeCorrectionMessage EXCEPT !.tradePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureTradeCorrectionMessage EXCEPT !.netChangeSign = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureTradeCorrectionMessage EXCEPT !.netChange = one] : one \in Sample(6) }
        \cup { [ZeroSwapFutureTradeCorrectionMessage EXCEPT !.netChangeFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureTradeCorrectionMessage EXCEPT !.timestamp = one] : one \in Sample(9) }
        \cup { [ZeroSwapFutureTradeCorrectionMessage EXCEPT !.priceIndicatorMarker = one] : one \in Sample(1) }
        \cup { [ZeroSwapFutureTradeCorrectionMessage EXCEPT !.tradeNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Group Status Message: 8 bytes                                           *)
(***************************************************************************)

GroupStatusMessage ==
    [ exchangeId  : Sample(1),
      rootSymbol  : Sample(6),
      groupStatus : Sample(1) ]

EncodeGroupStatusMessage(message) ==
    message.exchangeId
        \o message.rootSymbol
        \o message.groupStatus

DecodeGroupStatusMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET rootSymbol == ReadBytes(exchangeId.rest, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET groupStatus == ReadBytes(rootSymbol.rest, 1) IN IF ~groupStatus.ok THEN Fail ELSE
    Ok([ exchangeId  |-> exchangeId.value,
         rootSymbol  |-> rootSymbol.value,
         groupStatus |-> groupStatus.value ], groupStatus.rest)

ZeroGroupStatusMessage ==
    [ exchangeId  |-> [i \in 1 .. 1 |-> 0],
      rootSymbol  |-> [i \in 1 .. 6 |-> 0],
      groupStatus |-> [i \in 1 .. 1 |-> 0] ]

(* Group Status Message at zero, then each field in turn at the values it is checked at *)
CheckedGroupStatusMessage ==
    { ZeroGroupStatusMessage }
        \cup { [ZeroGroupStatusMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroGroupStatusMessage EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroGroupStatusMessage EXCEPT !.groupStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Strategies Message: 4 bytes                                             *)
(***************************************************************************)

StrategiesMessage ==
    [ exchangeId      : Sample(1),
      groupInstrument : Sample(2),
      groupStatus     : Sample(1) ]

EncodeStrategiesMessage(message) ==
    message.exchangeId
        \o message.groupInstrument
        \o message.groupStatus

DecodeStrategiesMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET groupInstrument == ReadBytes(exchangeId.rest, 2) IN IF ~groupInstrument.ok THEN Fail ELSE
    LET groupStatus == ReadBytes(groupInstrument.rest, 1) IN IF ~groupStatus.ok THEN Fail ELSE
    Ok([ exchangeId      |-> exchangeId.value,
         groupInstrument |-> groupInstrument.value,
         groupStatus     |-> groupStatus.value ], groupStatus.rest)

ZeroStrategiesMessage ==
    [ exchangeId      |-> [i \in 1 .. 1 |-> 0],
      groupInstrument |-> [i \in 1 .. 2 |-> 0],
      groupStatus     |-> [i \in 1 .. 1 |-> 0] ]

(* Strategies Message at zero, then each field in turn at the values it is checked at *)
CheckedStrategiesMessage ==
    { ZeroStrategiesMessage }
        \cup { [ZeroStrategiesMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroStrategiesMessage EXCEPT !.groupInstrument = one] : one \in Sample(2) }
        \cup { [ZeroStrategiesMessage EXCEPT !.groupStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Regular Text Bulletin: 80 bytes                                         *)
(***************************************************************************)

RegularTextBulletin ==
    [ regularBulletinContents : Sample(79),
      continueMarker          : Sample(1) ]

EncodeRegularTextBulletin(message) ==
    message.regularBulletinContents
        \o message.continueMarker

DecodeRegularTextBulletin(bytes) ==
    LET regularBulletinContents == ReadBytes(bytes, 79) IN IF ~regularBulletinContents.ok THEN Fail ELSE
    LET continueMarker == ReadBytes(regularBulletinContents.rest, 1) IN IF ~continueMarker.ok THEN Fail ELSE
    Ok([ regularBulletinContents |-> regularBulletinContents.value,
         continueMarker          |-> continueMarker.value ], continueMarker.rest)

ZeroRegularTextBulletin ==
    [ regularBulletinContents |-> [i \in 1 .. 79 |-> 0],
      continueMarker          |-> [i \in 1 .. 1 |-> 0] ]

(* Regular Text Bulletin at zero, then each field in turn at the values it is checked at *)
CheckedRegularTextBulletin ==
    { ZeroRegularTextBulletin }
        \cup { [ZeroRegularTextBulletin EXCEPT !.regularBulletinContents = one] : one \in Sample(79) }
        \cup { [ZeroRegularTextBulletin EXCEPT !.continueMarker = one] : one \in Sample(1) }

(***************************************************************************)
(* Special Text Bulletin: 80 bytes                                         *)
(***************************************************************************)

SpecialTextBulletin ==
    [ symbol                  : Sample(30),
      specialBulletinContents : Sample(49),
      continueMarker          : Sample(1) ]

EncodeSpecialTextBulletin(message) ==
    message.symbol
        \o message.specialBulletinContents
        \o message.continueMarker

DecodeSpecialTextBulletin(bytes) ==
    LET symbol == ReadBytes(bytes, 30) IN IF ~symbol.ok THEN Fail ELSE
    LET specialBulletinContents == ReadBytes(symbol.rest, 49) IN IF ~specialBulletinContents.ok THEN Fail ELSE
    LET continueMarker == ReadBytes(specialBulletinContents.rest, 1) IN IF ~continueMarker.ok THEN Fail ELSE
    Ok([ symbol                  |-> symbol.value,
         specialBulletinContents |-> specialBulletinContents.value,
         continueMarker          |-> continueMarker.value ], continueMarker.rest)

ZeroSpecialTextBulletin ==
    [ symbol                  |-> [i \in 1 .. 30 |-> 0],
      specialBulletinContents |-> [i \in 1 .. 49 |-> 0],
      continueMarker          |-> [i \in 1 .. 1 |-> 0] ]

(* Special Text Bulletin at zero, then each field in turn at the values it is checked at *)
CheckedSpecialTextBulletin ==
    { ZeroSpecialTextBulletin }
        \cup { [ZeroSpecialTextBulletin EXCEPT !.symbol = one] : one \in Sample(30) }
        \cup { [ZeroSpecialTextBulletin EXCEPT !.specialBulletinContents = one] : one \in Sample(49) }
        \cup { [ZeroSpecialTextBulletin EXCEPT !.continueMarker = one] : one \in Sample(1) }

(***************************************************************************)
(* Bulletin, selected by Bulletin Type                                     *)
(***************************************************************************)

RegularTextBulletinCode == 49  \* "1"
SpecialTextBulletinCode == 50  \* "2"

Bulletin ==
    [ tag : {RegularTextBulletinCode}, body : RegularTextBulletin ]
        \cup [ tag : {SpecialTextBulletinCode}, body : SpecialTextBulletin ]

EncodeBulletin(message) ==
    CASE message.tag = RegularTextBulletinCode -> EncodeRegularTextBulletin(message.body)
      [] message.tag = SpecialTextBulletinCode -> EncodeSpecialTextBulletin(message.body)

DecodeBulletin(tag, bytes) ==
    LET read ==
            CASE tag = RegularTextBulletinCode -> DecodeRegularTextBulletin(bytes)
              [] tag = SpecialTextBulletinCode -> DecodeSpecialTextBulletin(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroBulletin == [tag |-> RegularTextBulletinCode, body |-> ZeroRegularTextBulletin]

(* Each Bulletin in turn, at the values the message it names is checked at *)
CheckedBulletin ==
    { [tag |-> RegularTextBulletinCode, body |-> one] : one \in CheckedRegularTextBulletin }
        \cup { [tag |-> SpecialTextBulletinCode, body |-> one] : one \in CheckedSpecialTextBulletin }

(***************************************************************************)
(* Bulletins Message                                                       *)
(***************************************************************************)

BulletinsMessage ==
    [ reserved : Sample(1),
      bulletin : Bulletin ]

EncodeBulletinsMessage(message) ==
    message.reserved
        \o EncodeUIntBE(message.bulletin.tag, 1)
        \o EncodeBulletin(message.bulletin)

DecodeBulletinsMessage(bytes) ==
    LET reserved == ReadBytes(bytes, 1) IN IF ~reserved.ok THEN Fail ELSE
    LET bulletinType == ReadUIntBE(reserved.rest, 1) IN IF ~bulletinType.ok THEN Fail ELSE
    LET bulletin == DecodeBulletin(bulletinType.value, bulletinType.rest) IN IF ~bulletin.ok THEN Fail ELSE
    Ok([ reserved |-> reserved.value,
         bulletin |-> bulletin.value ], bulletin.rest)

ZeroBulletinsMessage ==
    [ reserved |-> [i \in 1 .. 1 |-> 0],
      bulletin |-> ZeroBulletin ]

(* Bulletins Message at zero, then each field in turn at the values it is checked at *)
CheckedBulletinsMessage ==
    { ZeroBulletinsMessage }
        \cup { [ZeroBulletinsMessage EXCEPT !.reserved = one] : one \in Sample(1) }
        \cup { [ZeroBulletinsMessage EXCEPT !.bulletin = one] : one \in CheckedBulletin }

(***************************************************************************)
(* End Of Sales Message: 7 bytes                                           *)
(***************************************************************************)

EndOfSalesMessage ==
    [ reserved : Sample(1),
      time     : Sample(6) ]

EncodeEndOfSalesMessage(message) ==
    message.reserved
        \o message.time

DecodeEndOfSalesMessage(bytes) ==
    LET reserved == ReadBytes(bytes, 1) IN IF ~reserved.ok THEN Fail ELSE
    LET time == ReadBytes(reserved.rest, 6) IN IF ~time.ok THEN Fail ELSE
    Ok([ reserved |-> reserved.value,
         time     |-> time.value ], time.rest)

ZeroEndOfSalesMessage ==
    [ reserved |-> [i \in 1 .. 1 |-> 0],
      time     |-> [i \in 1 .. 6 |-> 0] ]

(* End Of Sales Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfSalesMessage ==
    { ZeroEndOfSalesMessage }
        \cup { [ZeroEndOfSalesMessage EXCEPT !.reserved = one] : one \in Sample(1) }
        \cup { [ZeroEndOfSalesMessage EXCEPT !.time = one] : one \in Sample(6) }

(***************************************************************************)
(* Tick Entry Group: 14 bytes                                              *)
(***************************************************************************)

TickEntryGroup ==
    [ minPrice                   : Sample(6),
      minPriceFractionIndicator  : Sample(1),
      tickPrice                  : Sample(6),
      tickPriceFractionIndicator : Sample(1) ]

EncodeTickEntryGroup(message) ==
    message.minPrice
        \o message.minPriceFractionIndicator
        \o message.tickPrice
        \o message.tickPriceFractionIndicator

DecodeTickEntryGroup(bytes) ==
    LET minPrice == ReadBytes(bytes, 6) IN IF ~minPrice.ok THEN Fail ELSE
    LET minPriceFractionIndicator == ReadBytes(minPrice.rest, 1) IN IF ~minPriceFractionIndicator.ok THEN Fail ELSE
    LET tickPrice == ReadBytes(minPriceFractionIndicator.rest, 6) IN IF ~tickPrice.ok THEN Fail ELSE
    LET tickPriceFractionIndicator == ReadBytes(tickPrice.rest, 1) IN IF ~tickPriceFractionIndicator.ok THEN Fail ELSE
    Ok([ minPrice                   |-> minPrice.value,
         minPriceFractionIndicator  |-> minPriceFractionIndicator.value,
         tickPrice                  |-> tickPrice.value,
         tickPriceFractionIndicator |-> tickPriceFractionIndicator.value ], tickPriceFractionIndicator.rest)

ZeroTickEntryGroup ==
    [ minPrice                   |-> [i \in 1 .. 6 |-> 0],
      minPriceFractionIndicator  |-> [i \in 1 .. 1 |-> 0],
      tickPrice                  |-> [i \in 1 .. 6 |-> 0],
      tickPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Tick Entry Group at zero, then each field in turn at the values it is checked at *)
CheckedTickEntryGroup ==
    { ZeroTickEntryGroup }
        \cup { [ZeroTickEntryGroup EXCEPT !.minPrice = one] : one \in Sample(6) }
        \cup { [ZeroTickEntryGroup EXCEPT !.minPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTickEntryGroup EXCEPT !.tickPrice = one] : one \in Sample(6) }
        \cup { [ZeroTickEntryGroup EXCEPT !.tickPriceFractionIndicator = one] : one \in Sample(1) }

(* A run of Tick Entry Group, written one after another *)
RECURSIVE EncodeTickEntryGroupList(_)
EncodeTickEntryGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTickEntryGroup(Head(messages)) \o EncodeTickEntryGroupList(Tail(messages))

(* As many Tick Entry Group as the field that counts them says *)
RECURSIVE ReadTickEntryGroupList(_, _)
ReadTickEntryGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeTickEntryGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTickEntryGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Tick Entry Group of each kind, for the lists that carry them *)
OneTickEntryGroup == { ZeroTickEntryGroup }

(***************************************************************************)
(* Tick Table Message                                                      *)
(***************************************************************************)

TickTableMessage ==
    [ exchangeId         : Sample(1),
      tickTableName      : Sample(50),
      tickTableShortName : Sample(2),
      tickEntryGroup     : SampleLists(OneTickEntryGroup) ]

EncodeTickTableMessage(message) ==
    message.exchangeId
        \o message.tickTableName
        \o message.tickTableShortName
        \o EncodeDigits(Len(message.tickEntryGroup), 2)
        \o EncodeTickEntryGroupList(message.tickEntryGroup)

DecodeTickTableMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET tickTableName == ReadBytes(exchangeId.rest, 50) IN IF ~tickTableName.ok THEN Fail ELSE
    LET tickTableShortName == ReadBytes(tickTableName.rest, 2) IN IF ~tickTableShortName.ok THEN Fail ELSE
    LET numberOfEntries == ReadDigits(tickTableShortName.rest, 2) IN IF ~numberOfEntries.ok THEN Fail ELSE
    LET tickEntryGroup == ReadTickEntryGroupList(numberOfEntries.rest, numberOfEntries.value) IN IF ~tickEntryGroup.ok THEN Fail ELSE
    Ok([ exchangeId         |-> exchangeId.value,
         tickTableName      |-> tickTableName.value,
         tickTableShortName |-> tickTableShortName.value,
         tickEntryGroup     |-> tickEntryGroup.value ], tickEntryGroup.rest)

ZeroTickTableMessage ==
    [ exchangeId         |-> [i \in 1 .. 1 |-> 0],
      tickTableName      |-> [i \in 1 .. 50 |-> 0],
      tickTableShortName |-> [i \in 1 .. 2 |-> 0],
      tickEntryGroup     |-> << >> ]

(* Tick Table Message at zero, then each field in turn at the values it is checked at *)
CheckedTickTableMessage ==
    { ZeroTickTableMessage }
        \cup { [ZeroTickTableMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroTickTableMessage EXCEPT !.tickTableName = one] : one \in Sample(50) }
        \cup { [ZeroTickTableMessage EXCEPT !.tickTableShortName = one] : one \in Sample(2) }
        \cup { [ZeroTickTableMessage EXCEPT !.tickEntryGroup = one] : one \in SampleLists(OneTickEntryGroup) }

(***************************************************************************)
(* End Of Transmission Message: 7 bytes                                    *)
(***************************************************************************)

EndOfTransmissionMessage ==
    [ exchangeId : Sample(1),
      time       : Sample(6) ]

EncodeEndOfTransmissionMessage(message) ==
    message.exchangeId
        \o message.time

DecodeEndOfTransmissionMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET time == ReadBytes(exchangeId.rest, 6) IN IF ~time.ok THEN Fail ELSE
    Ok([ exchangeId |-> exchangeId.value,
         time       |-> time.value ], time.rest)

ZeroEndOfTransmissionMessage ==
    [ exchangeId |-> [i \in 1 .. 1 |-> 0],
      time       |-> [i \in 1 .. 6 |-> 0] ]

(* End Of Transmission Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfTransmissionMessage ==
    { ZeroEndOfTransmissionMessage }
        \cup { [ZeroEndOfTransmissionMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroEndOfTransmissionMessage EXCEPT !.time = one] : one \in Sample(6) }

(***************************************************************************)
(* Circuit Assurance Message: 6 bytes                                      *)
(***************************************************************************)

CircuitAssuranceMessage ==
    [ time : Sample(6) ]

EncodeCircuitAssuranceMessage(message) ==
    message.time

DecodeCircuitAssuranceMessage(bytes) ==
    LET time == ReadBytes(bytes, 6) IN IF ~time.ok THEN Fail ELSE
    Ok([ time |-> time.value ], time.rest)

ZeroCircuitAssuranceMessage ==
    [ time |-> [i \in 1 .. 6 |-> 0] ]

(* Circuit Assurance Message at zero, then each field in turn at the values it is checked at *)
CheckedCircuitAssuranceMessage ==
    { ZeroCircuitAssuranceMessage }
        \cup { [ZeroCircuitAssuranceMessage EXCEPT !.time = one] : one \in Sample(6) }

(***************************************************************************)
(* Message Body, selected by Message Type                                  *)
(***************************************************************************)

OptionTradeMessageCode == 17184  \* "C "
FutureOptionsTradeMessageCode == 17218  \* "CB"
FuturesTradeMessageCode == 17222  \* "CF"
StrategyTradeMessageCode == 17235  \* "CS"
SwapFutureTradeMessageCode == 17239  \* "CW"
OptionRfqMessageCode == 17440  \* "D "
FutureOptionsRfqMessageCode == 17474  \* "DB"
FuturesRfqMessageCode == 17478  \* "DF"
StrategyRfqMessageCode == 17491  \* "DS"
SwapFutureRfqMessageCode == 17495  \* "DW"
InstrumentScheduleNoticeOptionMessageCode == 17696  \* "E "
InstrumentScheduleNoticeFuturesOptionMessageCode == 17730  \* "EB"
InstrumentScheduleNoticeFutureMessageCode == 17734  \* "EF"
InstrumentScheduleNoticeStrategyMessageCode == 17747  \* "ES"
InstrumentScheduleNoticeSwapFutureMessageCode == 17751  \* "EW"
OptionQuoteMessageCode == 17952  \* "F "
FutureOptionsQuoteMessageCode == 17986  \* "FB"
FuturesQuoteMessageCode == 17990  \* "FF"
StrategyQuoteMessageCode == 18003  \* "FS"
SwapFutureQuoteMessageCode == 18007  \* "FW"
OptionMarketDepthMessageCode == 18464  \* "H "
FutureOptionsMarketDepthMessageCode == 18498  \* "HB"
FuturesMarketDepthMessageCode == 18502  \* "HF"
StrategyMarketDepthMessageCode == 18515  \* "HS"
SwapFutureMarketDepthMessageCode == 18519  \* "HW"
OptionTradeCancellationMessageCode == 18720  \* "I "
FutureOptionsTradeCancellationMessageCode == 18754  \* "IB"
FuturesTradeCancellationMessageCode == 18758  \* "IF"
StrategyTradeCancellationMessageCode == 18771  \* "IS"
SwapFutureTradeCancellationMessageCode == 18775  \* "IW"
OptionInstrumentKeysMessageCode == 18976  \* "J "
FutureOptionsInstrumentKeysMessageCode == 19010  \* "JB"
UnderlyingInstrumentKeysMessageCode == 19013  \* "JE"
FuturesInstrumentKeysMessageCode == 19014  \* "JF"
StrategyInstrumentKeysMessageCode == 19027  \* "JS"
SwapFutureInstrumentKeysMessageCode == 19031  \* "JW"
OptionSummaryMessageCode == 20000  \* "N "
FutureOptionsSummaryMessageCode == 20034  \* "NB"
FuturesSummaryMessageCode == 20038  \* "NF"
StrategySummaryMessageCode == 20051  \* "NS"
SwapFutureSummaryMessageCode == 20055  \* "NW"
BeginningOfOptionsSummaryMessageCode == 20768  \* "Q "
BeginningOfFutureOptionsSummaryMessageCode == 20802  \* "QB"
BeginningOfFuturesSummaryMessageCode == 20806  \* "QF"
BeginningOfStrategySummaryMessageCode == 20819  \* "QS"
SwapFutureBeginningOfSummaryMessageCode == 20823  \* "QW"
OptionTradeCorrectionMessageCode == 22560  \* "X "
FutureOptionsTradeCorrectionMessageCode == 22594  \* "XB"
FuturesTradeCorrectionMessageCode == 22598  \* "XF"
StrategyTradeCorrectionMessageCode == 22611  \* "XS"
SwapFutureTradeCorrectionMessageCode == 22615  \* "XW"
GroupStatusMessageCode == 18258  \* "GR"
StrategiesMessageCode == 18259  \* "GS"
BulletinsMessageCode == 19488  \* "L "
EndOfSalesMessageCode == 21280  \* "S "
TickTableMessageCode == 21588  \* "TT"
EndOfTransmissionMessageCode == 21792  \* "U "
CircuitAssuranceMessageCode == 22048  \* "V "

MessageBody ==
    [ tag : {OptionTradeMessageCode}, body : OptionTradeMessage ]
        \cup [ tag : {FutureOptionsTradeMessageCode}, body : FutureOptionsTradeMessage ]
        \cup [ tag : {FuturesTradeMessageCode}, body : FuturesTradeMessage ]
        \cup [ tag : {StrategyTradeMessageCode}, body : StrategyTradeMessage ]
        \cup [ tag : {SwapFutureTradeMessageCode}, body : SwapFutureTradeMessage ]
        \cup [ tag : {OptionRfqMessageCode}, body : OptionRfqMessage ]
        \cup [ tag : {FutureOptionsRfqMessageCode}, body : FutureOptionsRfqMessage ]
        \cup [ tag : {FuturesRfqMessageCode}, body : FuturesRfqMessage ]
        \cup [ tag : {StrategyRfqMessageCode}, body : StrategyRfqMessage ]
        \cup [ tag : {SwapFutureRfqMessageCode}, body : SwapFutureRfqMessage ]
        \cup [ tag : {InstrumentScheduleNoticeOptionMessageCode}, body : InstrumentScheduleNoticeOptionMessage ]
        \cup [ tag : {InstrumentScheduleNoticeFuturesOptionMessageCode}, body : InstrumentScheduleNoticeFuturesOptionMessage ]
        \cup [ tag : {InstrumentScheduleNoticeFutureMessageCode}, body : InstrumentScheduleNoticeFutureMessage ]
        \cup [ tag : {InstrumentScheduleNoticeStrategyMessageCode}, body : InstrumentScheduleNoticeStrategyMessage ]
        \cup [ tag : {InstrumentScheduleNoticeSwapFutureMessageCode}, body : InstrumentScheduleNoticeSwapFutureMessage ]
        \cup [ tag : {OptionQuoteMessageCode}, body : OptionQuoteMessage ]
        \cup [ tag : {FutureOptionsQuoteMessageCode}, body : FutureOptionsQuoteMessage ]
        \cup [ tag : {FuturesQuoteMessageCode}, body : FuturesQuoteMessage ]
        \cup [ tag : {StrategyQuoteMessageCode}, body : StrategyQuoteMessage ]
        \cup [ tag : {SwapFutureQuoteMessageCode}, body : SwapFutureQuoteMessage ]
        \cup [ tag : {OptionMarketDepthMessageCode}, body : OptionMarketDepthMessage ]
        \cup [ tag : {FutureOptionsMarketDepthMessageCode}, body : FutureOptionsMarketDepthMessage ]
        \cup [ tag : {FuturesMarketDepthMessageCode}, body : FuturesMarketDepthMessage ]
        \cup [ tag : {StrategyMarketDepthMessageCode}, body : StrategyMarketDepthMessage ]
        \cup [ tag : {SwapFutureMarketDepthMessageCode}, body : SwapFutureMarketDepthMessage ]
        \cup [ tag : {OptionTradeCancellationMessageCode}, body : OptionTradeCancellationMessage ]
        \cup [ tag : {FutureOptionsTradeCancellationMessageCode}, body : FutureOptionsTradeCancellationMessage ]
        \cup [ tag : {FuturesTradeCancellationMessageCode}, body : FuturesTradeCancellationMessage ]
        \cup [ tag : {StrategyTradeCancellationMessageCode}, body : StrategyTradeCancellationMessage ]
        \cup [ tag : {SwapFutureTradeCancellationMessageCode}, body : SwapFutureTradeCancellationMessage ]
        \cup [ tag : {OptionInstrumentKeysMessageCode}, body : OptionInstrumentKeysMessage ]
        \cup [ tag : {FutureOptionsInstrumentKeysMessageCode}, body : FutureOptionsInstrumentKeysMessage ]
        \cup [ tag : {UnderlyingInstrumentKeysMessageCode}, body : UnderlyingInstrumentKeysMessage ]
        \cup [ tag : {FuturesInstrumentKeysMessageCode}, body : FuturesInstrumentKeysMessage ]
        \cup [ tag : {StrategyInstrumentKeysMessageCode}, body : StrategyInstrumentKeysMessage ]
        \cup [ tag : {SwapFutureInstrumentKeysMessageCode}, body : SwapFutureInstrumentKeysMessage ]
        \cup [ tag : {OptionSummaryMessageCode}, body : OptionSummaryMessage ]
        \cup [ tag : {FutureOptionsSummaryMessageCode}, body : FutureOptionsSummaryMessage ]
        \cup [ tag : {FuturesSummaryMessageCode}, body : FuturesSummaryMessage ]
        \cup [ tag : {StrategySummaryMessageCode}, body : StrategySummaryMessage ]
        \cup [ tag : {SwapFutureSummaryMessageCode}, body : SwapFutureSummaryMessage ]
        \cup [ tag : {BeginningOfOptionsSummaryMessageCode}, body : BeginningOfOptionsSummaryMessage ]
        \cup [ tag : {BeginningOfFutureOptionsSummaryMessageCode}, body : BeginningOfFutureOptionsSummaryMessage ]
        \cup [ tag : {BeginningOfFuturesSummaryMessageCode}, body : BeginningOfFuturesSummaryMessage ]
        \cup [ tag : {BeginningOfStrategySummaryMessageCode}, body : BeginningOfStrategySummaryMessage ]
        \cup [ tag : {SwapFutureBeginningOfSummaryMessageCode}, body : SwapFutureBeginningOfSummaryMessage ]
        \cup [ tag : {OptionTradeCorrectionMessageCode}, body : OptionTradeCorrectionMessage ]
        \cup [ tag : {FutureOptionsTradeCorrectionMessageCode}, body : FutureOptionsTradeCorrectionMessage ]
        \cup [ tag : {FuturesTradeCorrectionMessageCode}, body : FuturesTradeCorrectionMessage ]
        \cup [ tag : {StrategyTradeCorrectionMessageCode}, body : StrategyTradeCorrectionMessage ]
        \cup [ tag : {SwapFutureTradeCorrectionMessageCode}, body : SwapFutureTradeCorrectionMessage ]
        \cup [ tag : {GroupStatusMessageCode}, body : GroupStatusMessage ]
        \cup [ tag : {StrategiesMessageCode}, body : StrategiesMessage ]
        \cup [ tag : {BulletinsMessageCode}, body : BulletinsMessage ]
        \cup [ tag : {EndOfSalesMessageCode}, body : EndOfSalesMessage ]
        \cup [ tag : {TickTableMessageCode}, body : TickTableMessage ]
        \cup [ tag : {EndOfTransmissionMessageCode}, body : EndOfTransmissionMessage ]
        \cup [ tag : {CircuitAssuranceMessageCode}, body : CircuitAssuranceMessage ]

EncodeMessageBody(message) ==
    CASE message.tag = OptionTradeMessageCode -> EncodeOptionTradeMessage(message.body)
      [] message.tag = FutureOptionsTradeMessageCode -> EncodeFutureOptionsTradeMessage(message.body)
      [] message.tag = FuturesTradeMessageCode -> EncodeFuturesTradeMessage(message.body)
      [] message.tag = StrategyTradeMessageCode -> EncodeStrategyTradeMessage(message.body)
      [] message.tag = SwapFutureTradeMessageCode -> EncodeSwapFutureTradeMessage(message.body)
      [] message.tag = OptionRfqMessageCode -> EncodeOptionRfqMessage(message.body)
      [] message.tag = FutureOptionsRfqMessageCode -> EncodeFutureOptionsRfqMessage(message.body)
      [] message.tag = FuturesRfqMessageCode -> EncodeFuturesRfqMessage(message.body)
      [] message.tag = StrategyRfqMessageCode -> EncodeStrategyRfqMessage(message.body)
      [] message.tag = SwapFutureRfqMessageCode -> EncodeSwapFutureRfqMessage(message.body)
      [] message.tag = InstrumentScheduleNoticeOptionMessageCode -> EncodeInstrumentScheduleNoticeOptionMessage(message.body)
      [] message.tag = InstrumentScheduleNoticeFuturesOptionMessageCode -> EncodeInstrumentScheduleNoticeFuturesOptionMessage(message.body)
      [] message.tag = InstrumentScheduleNoticeFutureMessageCode -> EncodeInstrumentScheduleNoticeFutureMessage(message.body)
      [] message.tag = InstrumentScheduleNoticeStrategyMessageCode -> EncodeInstrumentScheduleNoticeStrategyMessage(message.body)
      [] message.tag = InstrumentScheduleNoticeSwapFutureMessageCode -> EncodeInstrumentScheduleNoticeSwapFutureMessage(message.body)
      [] message.tag = OptionQuoteMessageCode -> EncodeOptionQuoteMessage(message.body)
      [] message.tag = FutureOptionsQuoteMessageCode -> EncodeFutureOptionsQuoteMessage(message.body)
      [] message.tag = FuturesQuoteMessageCode -> EncodeFuturesQuoteMessage(message.body)
      [] message.tag = StrategyQuoteMessageCode -> EncodeStrategyQuoteMessage(message.body)
      [] message.tag = SwapFutureQuoteMessageCode -> EncodeSwapFutureQuoteMessage(message.body)
      [] message.tag = OptionMarketDepthMessageCode -> EncodeOptionMarketDepthMessage(message.body)
      [] message.tag = FutureOptionsMarketDepthMessageCode -> EncodeFutureOptionsMarketDepthMessage(message.body)
      [] message.tag = FuturesMarketDepthMessageCode -> EncodeFuturesMarketDepthMessage(message.body)
      [] message.tag = StrategyMarketDepthMessageCode -> EncodeStrategyMarketDepthMessage(message.body)
      [] message.tag = SwapFutureMarketDepthMessageCode -> EncodeSwapFutureMarketDepthMessage(message.body)
      [] message.tag = OptionTradeCancellationMessageCode -> EncodeOptionTradeCancellationMessage(message.body)
      [] message.tag = FutureOptionsTradeCancellationMessageCode -> EncodeFutureOptionsTradeCancellationMessage(message.body)
      [] message.tag = FuturesTradeCancellationMessageCode -> EncodeFuturesTradeCancellationMessage(message.body)
      [] message.tag = StrategyTradeCancellationMessageCode -> EncodeStrategyTradeCancellationMessage(message.body)
      [] message.tag = SwapFutureTradeCancellationMessageCode -> EncodeSwapFutureTradeCancellationMessage(message.body)
      [] message.tag = OptionInstrumentKeysMessageCode -> EncodeOptionInstrumentKeysMessage(message.body)
      [] message.tag = FutureOptionsInstrumentKeysMessageCode -> EncodeFutureOptionsInstrumentKeysMessage(message.body)
      [] message.tag = UnderlyingInstrumentKeysMessageCode -> EncodeUnderlyingInstrumentKeysMessage(message.body)
      [] message.tag = FuturesInstrumentKeysMessageCode -> EncodeFuturesInstrumentKeysMessage(message.body)
      [] message.tag = StrategyInstrumentKeysMessageCode -> EncodeStrategyInstrumentKeysMessage(message.body)
      [] message.tag = SwapFutureInstrumentKeysMessageCode -> EncodeSwapFutureInstrumentKeysMessage(message.body)
      [] message.tag = OptionSummaryMessageCode -> EncodeOptionSummaryMessage(message.body)
      [] message.tag = FutureOptionsSummaryMessageCode -> EncodeFutureOptionsSummaryMessage(message.body)
      [] message.tag = FuturesSummaryMessageCode -> EncodeFuturesSummaryMessage(message.body)
      [] message.tag = StrategySummaryMessageCode -> EncodeStrategySummaryMessage(message.body)
      [] message.tag = SwapFutureSummaryMessageCode -> EncodeSwapFutureSummaryMessage(message.body)
      [] message.tag = BeginningOfOptionsSummaryMessageCode -> EncodeBeginningOfOptionsSummaryMessage(message.body)
      [] message.tag = BeginningOfFutureOptionsSummaryMessageCode -> EncodeBeginningOfFutureOptionsSummaryMessage(message.body)
      [] message.tag = BeginningOfFuturesSummaryMessageCode -> EncodeBeginningOfFuturesSummaryMessage(message.body)
      [] message.tag = BeginningOfStrategySummaryMessageCode -> EncodeBeginningOfStrategySummaryMessage(message.body)
      [] message.tag = SwapFutureBeginningOfSummaryMessageCode -> EncodeSwapFutureBeginningOfSummaryMessage(message.body)
      [] message.tag = OptionTradeCorrectionMessageCode -> EncodeOptionTradeCorrectionMessage(message.body)
      [] message.tag = FutureOptionsTradeCorrectionMessageCode -> EncodeFutureOptionsTradeCorrectionMessage(message.body)
      [] message.tag = FuturesTradeCorrectionMessageCode -> EncodeFuturesTradeCorrectionMessage(message.body)
      [] message.tag = StrategyTradeCorrectionMessageCode -> EncodeStrategyTradeCorrectionMessage(message.body)
      [] message.tag = SwapFutureTradeCorrectionMessageCode -> EncodeSwapFutureTradeCorrectionMessage(message.body)
      [] message.tag = GroupStatusMessageCode -> EncodeGroupStatusMessage(message.body)
      [] message.tag = StrategiesMessageCode -> EncodeStrategiesMessage(message.body)
      [] message.tag = BulletinsMessageCode -> EncodeBulletinsMessage(message.body)
      [] message.tag = EndOfSalesMessageCode -> EncodeEndOfSalesMessage(message.body)
      [] message.tag = TickTableMessageCode -> EncodeTickTableMessage(message.body)
      [] message.tag = EndOfTransmissionMessageCode -> EncodeEndOfTransmissionMessage(message.body)
      [] message.tag = CircuitAssuranceMessageCode -> EncodeCircuitAssuranceMessage(message.body)

DecodeMessageBody(tag, bytes) ==
    LET read ==
            CASE tag = OptionTradeMessageCode -> DecodeOptionTradeMessage(bytes)
              [] tag = FutureOptionsTradeMessageCode -> DecodeFutureOptionsTradeMessage(bytes)
              [] tag = FuturesTradeMessageCode -> DecodeFuturesTradeMessage(bytes)
              [] tag = StrategyTradeMessageCode -> DecodeStrategyTradeMessage(bytes)
              [] tag = SwapFutureTradeMessageCode -> DecodeSwapFutureTradeMessage(bytes)
              [] tag = OptionRfqMessageCode -> DecodeOptionRfqMessage(bytes)
              [] tag = FutureOptionsRfqMessageCode -> DecodeFutureOptionsRfqMessage(bytes)
              [] tag = FuturesRfqMessageCode -> DecodeFuturesRfqMessage(bytes)
              [] tag = StrategyRfqMessageCode -> DecodeStrategyRfqMessage(bytes)
              [] tag = SwapFutureRfqMessageCode -> DecodeSwapFutureRfqMessage(bytes)
              [] tag = InstrumentScheduleNoticeOptionMessageCode -> DecodeInstrumentScheduleNoticeOptionMessage(bytes)
              [] tag = InstrumentScheduleNoticeFuturesOptionMessageCode -> DecodeInstrumentScheduleNoticeFuturesOptionMessage(bytes)
              [] tag = InstrumentScheduleNoticeFutureMessageCode -> DecodeInstrumentScheduleNoticeFutureMessage(bytes)
              [] tag = InstrumentScheduleNoticeStrategyMessageCode -> DecodeInstrumentScheduleNoticeStrategyMessage(bytes)
              [] tag = InstrumentScheduleNoticeSwapFutureMessageCode -> DecodeInstrumentScheduleNoticeSwapFutureMessage(bytes)
              [] tag = OptionQuoteMessageCode -> DecodeOptionQuoteMessage(bytes)
              [] tag = FutureOptionsQuoteMessageCode -> DecodeFutureOptionsQuoteMessage(bytes)
              [] tag = FuturesQuoteMessageCode -> DecodeFuturesQuoteMessage(bytes)
              [] tag = StrategyQuoteMessageCode -> DecodeStrategyQuoteMessage(bytes)
              [] tag = SwapFutureQuoteMessageCode -> DecodeSwapFutureQuoteMessage(bytes)
              [] tag = OptionMarketDepthMessageCode -> DecodeOptionMarketDepthMessage(bytes)
              [] tag = FutureOptionsMarketDepthMessageCode -> DecodeFutureOptionsMarketDepthMessage(bytes)
              [] tag = FuturesMarketDepthMessageCode -> DecodeFuturesMarketDepthMessage(bytes)
              [] tag = StrategyMarketDepthMessageCode -> DecodeStrategyMarketDepthMessage(bytes)
              [] tag = SwapFutureMarketDepthMessageCode -> DecodeSwapFutureMarketDepthMessage(bytes)
              [] tag = OptionTradeCancellationMessageCode -> DecodeOptionTradeCancellationMessage(bytes)
              [] tag = FutureOptionsTradeCancellationMessageCode -> DecodeFutureOptionsTradeCancellationMessage(bytes)
              [] tag = FuturesTradeCancellationMessageCode -> DecodeFuturesTradeCancellationMessage(bytes)
              [] tag = StrategyTradeCancellationMessageCode -> DecodeStrategyTradeCancellationMessage(bytes)
              [] tag = SwapFutureTradeCancellationMessageCode -> DecodeSwapFutureTradeCancellationMessage(bytes)
              [] tag = OptionInstrumentKeysMessageCode -> DecodeOptionInstrumentKeysMessage(bytes)
              [] tag = FutureOptionsInstrumentKeysMessageCode -> DecodeFutureOptionsInstrumentKeysMessage(bytes)
              [] tag = UnderlyingInstrumentKeysMessageCode -> DecodeUnderlyingInstrumentKeysMessage(bytes)
              [] tag = FuturesInstrumentKeysMessageCode -> DecodeFuturesInstrumentKeysMessage(bytes)
              [] tag = StrategyInstrumentKeysMessageCode -> DecodeStrategyInstrumentKeysMessage(bytes)
              [] tag = SwapFutureInstrumentKeysMessageCode -> DecodeSwapFutureInstrumentKeysMessage(bytes)
              [] tag = OptionSummaryMessageCode -> DecodeOptionSummaryMessage(bytes)
              [] tag = FutureOptionsSummaryMessageCode -> DecodeFutureOptionsSummaryMessage(bytes)
              [] tag = FuturesSummaryMessageCode -> DecodeFuturesSummaryMessage(bytes)
              [] tag = StrategySummaryMessageCode -> DecodeStrategySummaryMessage(bytes)
              [] tag = SwapFutureSummaryMessageCode -> DecodeSwapFutureSummaryMessage(bytes)
              [] tag = BeginningOfOptionsSummaryMessageCode -> DecodeBeginningOfOptionsSummaryMessage(bytes)
              [] tag = BeginningOfFutureOptionsSummaryMessageCode -> DecodeBeginningOfFutureOptionsSummaryMessage(bytes)
              [] tag = BeginningOfFuturesSummaryMessageCode -> DecodeBeginningOfFuturesSummaryMessage(bytes)
              [] tag = BeginningOfStrategySummaryMessageCode -> DecodeBeginningOfStrategySummaryMessage(bytes)
              [] tag = SwapFutureBeginningOfSummaryMessageCode -> DecodeSwapFutureBeginningOfSummaryMessage(bytes)
              [] tag = OptionTradeCorrectionMessageCode -> DecodeOptionTradeCorrectionMessage(bytes)
              [] tag = FutureOptionsTradeCorrectionMessageCode -> DecodeFutureOptionsTradeCorrectionMessage(bytes)
              [] tag = FuturesTradeCorrectionMessageCode -> DecodeFuturesTradeCorrectionMessage(bytes)
              [] tag = StrategyTradeCorrectionMessageCode -> DecodeStrategyTradeCorrectionMessage(bytes)
              [] tag = SwapFutureTradeCorrectionMessageCode -> DecodeSwapFutureTradeCorrectionMessage(bytes)
              [] tag = GroupStatusMessageCode -> DecodeGroupStatusMessage(bytes)
              [] tag = StrategiesMessageCode -> DecodeStrategiesMessage(bytes)
              [] tag = BulletinsMessageCode -> DecodeBulletinsMessage(bytes)
              [] tag = EndOfSalesMessageCode -> DecodeEndOfSalesMessage(bytes)
              [] tag = TickTableMessageCode -> DecodeTickTableMessage(bytes)
              [] tag = EndOfTransmissionMessageCode -> DecodeEndOfTransmissionMessage(bytes)
              [] tag = CircuitAssuranceMessageCode -> DecodeCircuitAssuranceMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroMessageBody == [tag |-> OptionTradeMessageCode, body |-> ZeroOptionTradeMessage]

(* Each Message Body in turn, at the values the message it names is checked at *)
CheckedMessageBody ==
    { [tag |-> OptionTradeMessageCode, body |-> one] : one \in CheckedOptionTradeMessage }
        \cup { [tag |-> FutureOptionsTradeMessageCode, body |-> one] : one \in CheckedFutureOptionsTradeMessage }
        \cup { [tag |-> FuturesTradeMessageCode, body |-> one] : one \in CheckedFuturesTradeMessage }
        \cup { [tag |-> StrategyTradeMessageCode, body |-> one] : one \in CheckedStrategyTradeMessage }
        \cup { [tag |-> SwapFutureTradeMessageCode, body |-> one] : one \in CheckedSwapFutureTradeMessage }
        \cup { [tag |-> OptionRfqMessageCode, body |-> one] : one \in CheckedOptionRfqMessage }
        \cup { [tag |-> FutureOptionsRfqMessageCode, body |-> one] : one \in CheckedFutureOptionsRfqMessage }
        \cup { [tag |-> FuturesRfqMessageCode, body |-> one] : one \in CheckedFuturesRfqMessage }
        \cup { [tag |-> StrategyRfqMessageCode, body |-> one] : one \in CheckedStrategyRfqMessage }
        \cup { [tag |-> SwapFutureRfqMessageCode, body |-> one] : one \in CheckedSwapFutureRfqMessage }
        \cup { [tag |-> InstrumentScheduleNoticeOptionMessageCode, body |-> one] : one \in CheckedInstrumentScheduleNoticeOptionMessage }
        \cup { [tag |-> InstrumentScheduleNoticeFuturesOptionMessageCode, body |-> one] : one \in CheckedInstrumentScheduleNoticeFuturesOptionMessage }
        \cup { [tag |-> InstrumentScheduleNoticeFutureMessageCode, body |-> one] : one \in CheckedInstrumentScheduleNoticeFutureMessage }
        \cup { [tag |-> InstrumentScheduleNoticeStrategyMessageCode, body |-> one] : one \in CheckedInstrumentScheduleNoticeStrategyMessage }
        \cup { [tag |-> InstrumentScheduleNoticeSwapFutureMessageCode, body |-> one] : one \in CheckedInstrumentScheduleNoticeSwapFutureMessage }
        \cup { [tag |-> OptionQuoteMessageCode, body |-> one] : one \in CheckedOptionQuoteMessage }
        \cup { [tag |-> FutureOptionsQuoteMessageCode, body |-> one] : one \in CheckedFutureOptionsQuoteMessage }
        \cup { [tag |-> FuturesQuoteMessageCode, body |-> one] : one \in CheckedFuturesQuoteMessage }
        \cup { [tag |-> StrategyQuoteMessageCode, body |-> one] : one \in CheckedStrategyQuoteMessage }
        \cup { [tag |-> SwapFutureQuoteMessageCode, body |-> one] : one \in CheckedSwapFutureQuoteMessage }
        \cup { [tag |-> OptionMarketDepthMessageCode, body |-> one] : one \in CheckedOptionMarketDepthMessage }
        \cup { [tag |-> FutureOptionsMarketDepthMessageCode, body |-> one] : one \in CheckedFutureOptionsMarketDepthMessage }
        \cup { [tag |-> FuturesMarketDepthMessageCode, body |-> one] : one \in CheckedFuturesMarketDepthMessage }
        \cup { [tag |-> StrategyMarketDepthMessageCode, body |-> one] : one \in CheckedStrategyMarketDepthMessage }
        \cup { [tag |-> SwapFutureMarketDepthMessageCode, body |-> one] : one \in CheckedSwapFutureMarketDepthMessage }
        \cup { [tag |-> OptionTradeCancellationMessageCode, body |-> one] : one \in CheckedOptionTradeCancellationMessage }
        \cup { [tag |-> FutureOptionsTradeCancellationMessageCode, body |-> one] : one \in CheckedFutureOptionsTradeCancellationMessage }
        \cup { [tag |-> FuturesTradeCancellationMessageCode, body |-> one] : one \in CheckedFuturesTradeCancellationMessage }
        \cup { [tag |-> StrategyTradeCancellationMessageCode, body |-> one] : one \in CheckedStrategyTradeCancellationMessage }
        \cup { [tag |-> SwapFutureTradeCancellationMessageCode, body |-> one] : one \in CheckedSwapFutureTradeCancellationMessage }
        \cup { [tag |-> OptionInstrumentKeysMessageCode, body |-> one] : one \in CheckedOptionInstrumentKeysMessage }
        \cup { [tag |-> FutureOptionsInstrumentKeysMessageCode, body |-> one] : one \in CheckedFutureOptionsInstrumentKeysMessage }
        \cup { [tag |-> UnderlyingInstrumentKeysMessageCode, body |-> one] : one \in CheckedUnderlyingInstrumentKeysMessage }
        \cup { [tag |-> FuturesInstrumentKeysMessageCode, body |-> one] : one \in CheckedFuturesInstrumentKeysMessage }
        \cup { [tag |-> StrategyInstrumentKeysMessageCode, body |-> one] : one \in CheckedStrategyInstrumentKeysMessage }
        \cup { [tag |-> SwapFutureInstrumentKeysMessageCode, body |-> one] : one \in CheckedSwapFutureInstrumentKeysMessage }
        \cup { [tag |-> OptionSummaryMessageCode, body |-> one] : one \in CheckedOptionSummaryMessage }
        \cup { [tag |-> FutureOptionsSummaryMessageCode, body |-> one] : one \in CheckedFutureOptionsSummaryMessage }
        \cup { [tag |-> FuturesSummaryMessageCode, body |-> one] : one \in CheckedFuturesSummaryMessage }
        \cup { [tag |-> StrategySummaryMessageCode, body |-> one] : one \in CheckedStrategySummaryMessage }
        \cup { [tag |-> SwapFutureSummaryMessageCode, body |-> one] : one \in CheckedSwapFutureSummaryMessage }
        \cup { [tag |-> BeginningOfOptionsSummaryMessageCode, body |-> one] : one \in CheckedBeginningOfOptionsSummaryMessage }
        \cup { [tag |-> BeginningOfFutureOptionsSummaryMessageCode, body |-> one] : one \in CheckedBeginningOfFutureOptionsSummaryMessage }
        \cup { [tag |-> BeginningOfFuturesSummaryMessageCode, body |-> one] : one \in CheckedBeginningOfFuturesSummaryMessage }
        \cup { [tag |-> BeginningOfStrategySummaryMessageCode, body |-> one] : one \in CheckedBeginningOfStrategySummaryMessage }
        \cup { [tag |-> SwapFutureBeginningOfSummaryMessageCode, body |-> one] : one \in CheckedSwapFutureBeginningOfSummaryMessage }
        \cup { [tag |-> OptionTradeCorrectionMessageCode, body |-> one] : one \in CheckedOptionTradeCorrectionMessage }
        \cup { [tag |-> FutureOptionsTradeCorrectionMessageCode, body |-> one] : one \in CheckedFutureOptionsTradeCorrectionMessage }
        \cup { [tag |-> FuturesTradeCorrectionMessageCode, body |-> one] : one \in CheckedFuturesTradeCorrectionMessage }
        \cup { [tag |-> StrategyTradeCorrectionMessageCode, body |-> one] : one \in CheckedStrategyTradeCorrectionMessage }
        \cup { [tag |-> SwapFutureTradeCorrectionMessageCode, body |-> one] : one \in CheckedSwapFutureTradeCorrectionMessage }
        \cup { [tag |-> GroupStatusMessageCode, body |-> one] : one \in CheckedGroupStatusMessage }
        \cup { [tag |-> StrategiesMessageCode, body |-> one] : one \in CheckedStrategiesMessage }
        \cup { [tag |-> BulletinsMessageCode, body |-> one] : one \in CheckedBulletinsMessage }
        \cup { [tag |-> EndOfSalesMessageCode, body |-> one] : one \in CheckedEndOfSalesMessage }
        \cup { [tag |-> TickTableMessageCode, body |-> one] : one \in CheckedTickTableMessage }
        \cup { [tag |-> EndOfTransmissionMessageCode, body |-> one] : one \in CheckedEndOfTransmissionMessage }
        \cup { [tag |-> CircuitAssuranceMessageCode, body |-> one] : one \in CheckedCircuitAssuranceMessage }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ hsvfStx        : Sample(1),
      sequenceNumber : Sample(9),
      messageBody    : MessageBody,
      hsvfEtx        : Sample(1) ]

EncodePacket(message) ==
    message.hsvfStx
        \o message.sequenceNumber
        \o EncodeUIntBE(message.messageBody.tag, 2)
        \o EncodeMessageBody(message.messageBody)
        \o message.hsvfEtx

DecodePacket(bytes) ==
    LET hsvfStx == ReadBytes(bytes, 1) IN IF ~hsvfStx.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(hsvfStx.rest, 9) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET messageType == ReadUIntBE(sequenceNumber.rest, 2) IN IF ~messageType.ok THEN Fail ELSE
    LET messageBody == DecodeMessageBody(messageType.value, messageType.rest) IN IF ~messageBody.ok THEN Fail ELSE
    LET hsvfEtx == ReadBytes(messageBody.rest, 1) IN IF ~hsvfEtx.ok THEN Fail ELSE
    Ok([ hsvfStx        |-> hsvfStx.value,
         sequenceNumber |-> sequenceNumber.value,
         messageBody    |-> messageBody.value,
         hsvfEtx        |-> hsvfEtx.value ], hsvfEtx.rest)

ZeroPacket ==
    [ hsvfStx        |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber |-> [i \in 1 .. 9 |-> 0],
      messageBody    |-> ZeroMessageBody,
      hsvfEtx        |-> [i \in 1 .. 1 |-> 0] ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.hsvfStx = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.sequenceNumber = one] : one \in Sample(9) }
        \cup { [ZeroPacket EXCEPT !.messageBody = one] : one \in CheckedMessageBody }
        \cup { [ZeroPacket EXCEPT !.hsvfEtx = one] : one \in Sample(1) }

(* A run of Packet, written one after another *)
RECURSIVE EncodePacketList(_)
EncodePacketList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodePacket(Head(messages)) \o EncodePacketList(Tail(messages))

(* As many Packet as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadPacketAll(_)
ReadPacketAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodePacket(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadPacketAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Packet of each kind, for the lists that carry them *)
OnePacket ==
    { [ZeroPacket EXCEPT !.messageBody = [tag |-> OptionTradeMessageCode, body |-> ZeroOptionTradeMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> FutureOptionsTradeMessageCode, body |-> ZeroFutureOptionsTradeMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> FuturesTradeMessageCode, body |-> ZeroFuturesTradeMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> StrategyTradeMessageCode, body |-> ZeroStrategyTradeMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> SwapFutureTradeMessageCode, body |-> ZeroSwapFutureTradeMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> OptionRfqMessageCode, body |-> ZeroOptionRfqMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> FutureOptionsRfqMessageCode, body |-> ZeroFutureOptionsRfqMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> FuturesRfqMessageCode, body |-> ZeroFuturesRfqMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> StrategyRfqMessageCode, body |-> ZeroStrategyRfqMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> SwapFutureRfqMessageCode, body |-> ZeroSwapFutureRfqMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> InstrumentScheduleNoticeOptionMessageCode, body |-> ZeroInstrumentScheduleNoticeOptionMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> InstrumentScheduleNoticeFuturesOptionMessageCode, body |-> ZeroInstrumentScheduleNoticeFuturesOptionMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> InstrumentScheduleNoticeFutureMessageCode, body |-> ZeroInstrumentScheduleNoticeFutureMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> InstrumentScheduleNoticeStrategyMessageCode, body |-> ZeroInstrumentScheduleNoticeStrategyMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> InstrumentScheduleNoticeSwapFutureMessageCode, body |-> ZeroInstrumentScheduleNoticeSwapFutureMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> OptionQuoteMessageCode, body |-> ZeroOptionQuoteMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> FutureOptionsQuoteMessageCode, body |-> ZeroFutureOptionsQuoteMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> FuturesQuoteMessageCode, body |-> ZeroFuturesQuoteMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> StrategyQuoteMessageCode, body |-> ZeroStrategyQuoteMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> SwapFutureQuoteMessageCode, body |-> ZeroSwapFutureQuoteMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> OptionMarketDepthMessageCode, body |-> ZeroOptionMarketDepthMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> FutureOptionsMarketDepthMessageCode, body |-> ZeroFutureOptionsMarketDepthMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> FuturesMarketDepthMessageCode, body |-> ZeroFuturesMarketDepthMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> StrategyMarketDepthMessageCode, body |-> ZeroStrategyMarketDepthMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> SwapFutureMarketDepthMessageCode, body |-> ZeroSwapFutureMarketDepthMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> OptionTradeCancellationMessageCode, body |-> ZeroOptionTradeCancellationMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> FutureOptionsTradeCancellationMessageCode, body |-> ZeroFutureOptionsTradeCancellationMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> FuturesTradeCancellationMessageCode, body |-> ZeroFuturesTradeCancellationMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> StrategyTradeCancellationMessageCode, body |-> ZeroStrategyTradeCancellationMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> SwapFutureTradeCancellationMessageCode, body |-> ZeroSwapFutureTradeCancellationMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> OptionInstrumentKeysMessageCode, body |-> ZeroOptionInstrumentKeysMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> FutureOptionsInstrumentKeysMessageCode, body |-> ZeroFutureOptionsInstrumentKeysMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> UnderlyingInstrumentKeysMessageCode, body |-> ZeroUnderlyingInstrumentKeysMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> FuturesInstrumentKeysMessageCode, body |-> ZeroFuturesInstrumentKeysMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> StrategyInstrumentKeysMessageCode, body |-> ZeroStrategyInstrumentKeysMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> SwapFutureInstrumentKeysMessageCode, body |-> ZeroSwapFutureInstrumentKeysMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> OptionSummaryMessageCode, body |-> ZeroOptionSummaryMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> FutureOptionsSummaryMessageCode, body |-> ZeroFutureOptionsSummaryMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> FuturesSummaryMessageCode, body |-> ZeroFuturesSummaryMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> StrategySummaryMessageCode, body |-> ZeroStrategySummaryMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> SwapFutureSummaryMessageCode, body |-> ZeroSwapFutureSummaryMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> BeginningOfOptionsSummaryMessageCode, body |-> ZeroBeginningOfOptionsSummaryMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> BeginningOfFutureOptionsSummaryMessageCode, body |-> ZeroBeginningOfFutureOptionsSummaryMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> BeginningOfFuturesSummaryMessageCode, body |-> ZeroBeginningOfFuturesSummaryMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> BeginningOfStrategySummaryMessageCode, body |-> ZeroBeginningOfStrategySummaryMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> SwapFutureBeginningOfSummaryMessageCode, body |-> ZeroSwapFutureBeginningOfSummaryMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> OptionTradeCorrectionMessageCode, body |-> ZeroOptionTradeCorrectionMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> FutureOptionsTradeCorrectionMessageCode, body |-> ZeroFutureOptionsTradeCorrectionMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> FuturesTradeCorrectionMessageCode, body |-> ZeroFuturesTradeCorrectionMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> StrategyTradeCorrectionMessageCode, body |-> ZeroStrategyTradeCorrectionMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> SwapFutureTradeCorrectionMessageCode, body |-> ZeroSwapFutureTradeCorrectionMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> GroupStatusMessageCode, body |-> ZeroGroupStatusMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> StrategiesMessageCode, body |-> ZeroStrategiesMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> BulletinsMessageCode, body |-> ZeroBulletinsMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> EndOfSalesMessageCode, body |-> ZeroEndOfSalesMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> TickTableMessageCode, body |-> ZeroTickTableMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> EndOfTransmissionMessageCode, body |-> ZeroEndOfTransmissionMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> CircuitAssuranceMessageCode, body |-> ZeroCircuitAssuranceMessage]] }

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

(* Every Option Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionTradeMessage ==
    \A message \in CheckedOptionTradeMessage :
        LET read == DecodeOptionTradeMessage(EncodeOptionTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Options Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureOptionsTradeMessage ==
    \A message \in CheckedFutureOptionsTradeMessage :
        LET read == DecodeFutureOptionsTradeMessage(EncodeFutureOptionsTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Futures Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFuturesTradeMessage ==
    \A message \in CheckedFuturesTradeMessage :
        LET read == DecodeFuturesTradeMessage(EncodeFuturesTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyTradeMessage ==
    \A message \in CheckedStrategyTradeMessage :
        LET read == DecodeStrategyTradeMessage(EncodeStrategyTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Swap Future Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSwapFutureTradeMessage ==
    \A message \in CheckedSwapFutureTradeMessage :
        LET read == DecodeSwapFutureTradeMessage(EncodeSwapFutureTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Rfq Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionRfqMessage ==
    \A message \in CheckedOptionRfqMessage :
        LET read == DecodeOptionRfqMessage(EncodeOptionRfqMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Options Rfq Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureOptionsRfqMessage ==
    \A message \in CheckedFutureOptionsRfqMessage :
        LET read == DecodeFutureOptionsRfqMessage(EncodeFutureOptionsRfqMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Futures Rfq Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFuturesRfqMessage ==
    \A message \in CheckedFuturesRfqMessage :
        LET read == DecodeFuturesRfqMessage(EncodeFuturesRfqMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Rfq Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyRfqMessage ==
    \A message \in CheckedStrategyRfqMessage :
        LET read == DecodeStrategyRfqMessage(EncodeStrategyRfqMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Swap Future Rfq Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSwapFutureRfqMessage ==
    \A message \in CheckedSwapFutureRfqMessage :
        LET read == DecodeSwapFutureRfqMessage(EncodeSwapFutureRfqMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Schedule Notice Option Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentScheduleNoticeOptionMessage ==
    \A message \in CheckedInstrumentScheduleNoticeOptionMessage :
        LET read == DecodeInstrumentScheduleNoticeOptionMessage(EncodeInstrumentScheduleNoticeOptionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Schedule Notice Futures Option Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentScheduleNoticeFuturesOptionMessage ==
    \A message \in CheckedInstrumentScheduleNoticeFuturesOptionMessage :
        LET read == DecodeInstrumentScheduleNoticeFuturesOptionMessage(EncodeInstrumentScheduleNoticeFuturesOptionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Schedule Notice Future Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentScheduleNoticeFutureMessage ==
    \A message \in CheckedInstrumentScheduleNoticeFutureMessage :
        LET read == DecodeInstrumentScheduleNoticeFutureMessage(EncodeInstrumentScheduleNoticeFutureMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Schedule Notice Strategy Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentScheduleNoticeStrategyMessage ==
    \A message \in CheckedInstrumentScheduleNoticeStrategyMessage :
        LET read == DecodeInstrumentScheduleNoticeStrategyMessage(EncodeInstrumentScheduleNoticeStrategyMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Schedule Notice Swap Future Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentScheduleNoticeSwapFutureMessage ==
    \A message \in CheckedInstrumentScheduleNoticeSwapFutureMessage :
        LET read == DecodeInstrumentScheduleNoticeSwapFutureMessage(EncodeInstrumentScheduleNoticeSwapFutureMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionQuoteMessage ==
    \A message \in CheckedOptionQuoteMessage :
        LET read == DecodeOptionQuoteMessage(EncodeOptionQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Options Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureOptionsQuoteMessage ==
    \A message \in CheckedFutureOptionsQuoteMessage :
        LET read == DecodeFutureOptionsQuoteMessage(EncodeFutureOptionsQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Futures Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFuturesQuoteMessage ==
    \A message \in CheckedFuturesQuoteMessage :
        LET read == DecodeFuturesQuoteMessage(EncodeFuturesQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyQuoteMessage ==
    \A message \in CheckedStrategyQuoteMessage :
        LET read == DecodeStrategyQuoteMessage(EncodeStrategyQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Swap Future Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSwapFutureQuoteMessage ==
    \A message \in CheckedSwapFutureQuoteMessage :
        LET read == DecodeSwapFutureQuoteMessage(EncodeSwapFutureQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Market Depth Trading Instrument decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionMarketDepthTradingInstrument ==
    \A message \in CheckedOptionMarketDepthTradingInstrument :
        LET read == DecodeOptionMarketDepthTradingInstrument(EncodeOptionMarketDepthTradingInstrument(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Market Depth Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionMarketDepthMessage ==
    \A message \in CheckedOptionMarketDepthMessage :
        LET read == DecodeOptionMarketDepthMessage(EncodeOptionMarketDepthMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Options Market Depth Trading Instrument decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureOptionsMarketDepthTradingInstrument ==
    \A message \in CheckedFutureOptionsMarketDepthTradingInstrument :
        LET read == DecodeFutureOptionsMarketDepthTradingInstrument(EncodeFutureOptionsMarketDepthTradingInstrument(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Options Market Depth Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureOptionsMarketDepthMessage ==
    \A message \in CheckedFutureOptionsMarketDepthMessage :
        LET read == DecodeFutureOptionsMarketDepthMessage(EncodeFutureOptionsMarketDepthMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Futures Market Depth Trading Instrument decodes back to what was encoded, and leaves nothing over *)
RoundTripFuturesMarketDepthTradingInstrument ==
    \A message \in CheckedFuturesMarketDepthTradingInstrument :
        LET read == DecodeFuturesMarketDepthTradingInstrument(EncodeFuturesMarketDepthTradingInstrument(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Futures Market Depth Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFuturesMarketDepthMessage ==
    \A message \in CheckedFuturesMarketDepthMessage :
        LET read == DecodeFuturesMarketDepthMessage(EncodeFuturesMarketDepthMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Market Depth Trading Instrument decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyMarketDepthTradingInstrument ==
    \A message \in CheckedStrategyMarketDepthTradingInstrument :
        LET read == DecodeStrategyMarketDepthTradingInstrument(EncodeStrategyMarketDepthTradingInstrument(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Market Depth Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyMarketDepthMessage ==
    \A message \in CheckedStrategyMarketDepthMessage :
        LET read == DecodeStrategyMarketDepthMessage(EncodeStrategyMarketDepthMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Swap Future Market Depth Trading Instrument decodes back to what was encoded, and leaves nothing over *)
RoundTripSwapFutureMarketDepthTradingInstrument ==
    \A message \in CheckedSwapFutureMarketDepthTradingInstrument :
        LET read == DecodeSwapFutureMarketDepthTradingInstrument(EncodeSwapFutureMarketDepthTradingInstrument(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Swap Future Market Depth Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSwapFutureMarketDepthMessage ==
    \A message \in CheckedSwapFutureMarketDepthMessage :
        LET read == DecodeSwapFutureMarketDepthMessage(EncodeSwapFutureMarketDepthMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Trade Cancellation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionTradeCancellationMessage ==
    \A message \in CheckedOptionTradeCancellationMessage :
        LET read == DecodeOptionTradeCancellationMessage(EncodeOptionTradeCancellationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Options Trade Cancellation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureOptionsTradeCancellationMessage ==
    \A message \in CheckedFutureOptionsTradeCancellationMessage :
        LET read == DecodeFutureOptionsTradeCancellationMessage(EncodeFutureOptionsTradeCancellationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Futures Trade Cancellation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFuturesTradeCancellationMessage ==
    \A message \in CheckedFuturesTradeCancellationMessage :
        LET read == DecodeFuturesTradeCancellationMessage(EncodeFuturesTradeCancellationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Trade Cancellation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyTradeCancellationMessage ==
    \A message \in CheckedStrategyTradeCancellationMessage :
        LET read == DecodeStrategyTradeCancellationMessage(EncodeStrategyTradeCancellationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Swap Future Trade Cancellation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSwapFutureTradeCancellationMessage ==
    \A message \in CheckedSwapFutureTradeCancellationMessage :
        LET read == DecodeSwapFutureTradeCancellationMessage(EncodeSwapFutureTradeCancellationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Instrument Keys Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionInstrumentKeysMessage ==
    \A message \in CheckedOptionInstrumentKeysMessage :
        LET read == DecodeOptionInstrumentKeysMessage(EncodeOptionInstrumentKeysMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Options Instrument Keys Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureOptionsInstrumentKeysMessage ==
    \A message \in CheckedFutureOptionsInstrumentKeysMessage :
        LET read == DecodeFutureOptionsInstrumentKeysMessage(EncodeFutureOptionsInstrumentKeysMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Underlying Instrument Keys Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUnderlyingInstrumentKeysMessage ==
    \A message \in CheckedUnderlyingInstrumentKeysMessage :
        LET read == DecodeUnderlyingInstrumentKeysMessage(EncodeUnderlyingInstrumentKeysMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Futures Instrument Keys Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFuturesInstrumentKeysMessage ==
    \A message \in CheckedFuturesInstrumentKeysMessage :
        LET read == DecodeFuturesInstrumentKeysMessage(EncodeFuturesInstrumentKeysMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Instrument Keys Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyInstrumentKeysMessage ==
    \A message \in CheckedStrategyInstrumentKeysMessage :
        LET read == DecodeStrategyInstrumentKeysMessage(EncodeStrategyInstrumentKeysMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Swap Future Instrument Keys Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSwapFutureInstrumentKeysMessage ==
    \A message \in CheckedSwapFutureInstrumentKeysMessage :
        LET read == DecodeSwapFutureInstrumentKeysMessage(EncodeSwapFutureInstrumentKeysMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionSummaryMessage ==
    \A message \in CheckedOptionSummaryMessage :
        LET read == DecodeOptionSummaryMessage(EncodeOptionSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Options Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureOptionsSummaryMessage ==
    \A message \in CheckedFutureOptionsSummaryMessage :
        LET read == DecodeFutureOptionsSummaryMessage(EncodeFutureOptionsSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Futures Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFuturesSummaryMessage ==
    \A message \in CheckedFuturesSummaryMessage :
        LET read == DecodeFuturesSummaryMessage(EncodeFuturesSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Summary Strategy Leg decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategySummaryStrategyLeg ==
    \A message \in CheckedStrategySummaryStrategyLeg :
        LET read == DecodeStrategySummaryStrategyLeg(EncodeStrategySummaryStrategyLeg(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategySummaryMessage ==
    \A message \in CheckedStrategySummaryMessage :
        LET read == DecodeStrategySummaryMessage(EncodeStrategySummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Swap Future Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSwapFutureSummaryMessage ==
    \A message \in CheckedSwapFutureSummaryMessage :
        LET read == DecodeSwapFutureSummaryMessage(EncodeSwapFutureSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Beginning Of Options Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBeginningOfOptionsSummaryMessage ==
    \A message \in CheckedBeginningOfOptionsSummaryMessage :
        LET read == DecodeBeginningOfOptionsSummaryMessage(EncodeBeginningOfOptionsSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Beginning Of Future Options Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBeginningOfFutureOptionsSummaryMessage ==
    \A message \in CheckedBeginningOfFutureOptionsSummaryMessage :
        LET read == DecodeBeginningOfFutureOptionsSummaryMessage(EncodeBeginningOfFutureOptionsSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Beginning Of Futures Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBeginningOfFuturesSummaryMessage ==
    \A message \in CheckedBeginningOfFuturesSummaryMessage :
        LET read == DecodeBeginningOfFuturesSummaryMessage(EncodeBeginningOfFuturesSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Beginning Of Strategy Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBeginningOfStrategySummaryMessage ==
    \A message \in CheckedBeginningOfStrategySummaryMessage :
        LET read == DecodeBeginningOfStrategySummaryMessage(EncodeBeginningOfStrategySummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Swap Future Beginning Of Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSwapFutureBeginningOfSummaryMessage ==
    \A message \in CheckedSwapFutureBeginningOfSummaryMessage :
        LET read == DecodeSwapFutureBeginningOfSummaryMessage(EncodeSwapFutureBeginningOfSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Trade Correction Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionTradeCorrectionMessage ==
    \A message \in CheckedOptionTradeCorrectionMessage :
        LET read == DecodeOptionTradeCorrectionMessage(EncodeOptionTradeCorrectionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Options Trade Correction Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureOptionsTradeCorrectionMessage ==
    \A message \in CheckedFutureOptionsTradeCorrectionMessage :
        LET read == DecodeFutureOptionsTradeCorrectionMessage(EncodeFutureOptionsTradeCorrectionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Futures Trade Correction Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFuturesTradeCorrectionMessage ==
    \A message \in CheckedFuturesTradeCorrectionMessage :
        LET read == DecodeFuturesTradeCorrectionMessage(EncodeFuturesTradeCorrectionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Trade Correction Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyTradeCorrectionMessage ==
    \A message \in CheckedStrategyTradeCorrectionMessage :
        LET read == DecodeStrategyTradeCorrectionMessage(EncodeStrategyTradeCorrectionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Swap Future Trade Correction Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSwapFutureTradeCorrectionMessage ==
    \A message \in CheckedSwapFutureTradeCorrectionMessage :
        LET read == DecodeSwapFutureTradeCorrectionMessage(EncodeSwapFutureTradeCorrectionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Group Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripGroupStatusMessage ==
    \A message \in CheckedGroupStatusMessage :
        LET read == DecodeGroupStatusMessage(EncodeGroupStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategies Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategiesMessage ==
    \A message \in CheckedStrategiesMessage :
        LET read == DecodeStrategiesMessage(EncodeStrategiesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Regular Text Bulletin decodes back to what was encoded, and leaves nothing over *)
RoundTripRegularTextBulletin ==
    \A message \in CheckedRegularTextBulletin :
        LET read == DecodeRegularTextBulletin(EncodeRegularTextBulletin(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Special Text Bulletin decodes back to what was encoded, and leaves nothing over *)
RoundTripSpecialTextBulletin ==
    \A message \in CheckedSpecialTextBulletin :
        LET read == DecodeSpecialTextBulletin(EncodeSpecialTextBulletin(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulletins Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBulletinsMessage ==
    \A message \in CheckedBulletinsMessage :
        LET read == DecodeBulletinsMessage(EncodeBulletinsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Sales Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfSalesMessage ==
    \A message \in CheckedEndOfSalesMessage :
        LET read == DecodeEndOfSalesMessage(EncodeEndOfSalesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tick Entry Group decodes back to what was encoded, and leaves nothing over *)
RoundTripTickEntryGroup ==
    \A message \in CheckedTickEntryGroup :
        LET read == DecodeTickEntryGroup(EncodeTickEntryGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tick Table Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTickTableMessage ==
    \A message \in CheckedTickTableMessage :
        LET read == DecodeTickTableMessage(EncodeTickTableMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Transmission Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfTransmissionMessage ==
    \A message \in CheckedEndOfTransmissionMessage :
        LET read == DecodeEndOfTransmissionMessage(EncodeEndOfTransmissionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Circuit Assurance Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCircuitAssuranceMessage ==
    \A message \in CheckedCircuitAssuranceMessage :
        LET read == DecodeCircuitAssuranceMessage(EncodeCircuitAssuranceMessage(message))
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

(* A Bulletin is selected by the Bulletin Type it is written under *)
SelectsBulletin ==
    \A message \in CheckedBulletin :
        LET read == DecodeBulletin(message.tag, EncodeBulletin(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Message Body is selected by the Message Type it is written under *)
SelectsMessageBody ==
    \A message \in CheckedMessageBody :
        LET read == DecodeMessageBody(message.tag, EncodeMessageBody(message))
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
