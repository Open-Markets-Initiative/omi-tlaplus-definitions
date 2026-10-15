---------------------- MODULE Mx_SolaMulticast_v1_12 -----------------------
(***************************************************************************)
(* TMX Group Sola Multicast v1.12                                          *)
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
(* Login Message: 40 bytes                                                 *)
(***************************************************************************)

LoginMessage ==
    [ user1          : Sample(16),
      pwd1           : Sample(16),
      loginTimestamp : Sample(6),
      protocol       : Sample(2) ]

EncodeLoginMessage(message) ==
    message.user1
        \o message.pwd1
        \o message.loginTimestamp
        \o message.protocol

DecodeLoginMessage(bytes) ==
    LET user1 == ReadBytes(bytes, 16) IN IF ~user1.ok THEN Fail ELSE
    LET pwd1 == ReadBytes(user1.rest, 16) IN IF ~pwd1.ok THEN Fail ELSE
    LET loginTimestamp == ReadBytes(pwd1.rest, 6) IN IF ~loginTimestamp.ok THEN Fail ELSE
    LET protocol == ReadBytes(loginTimestamp.rest, 2) IN IF ~protocol.ok THEN Fail ELSE
    Ok([ user1          |-> user1.value,
         pwd1           |-> pwd1.value,
         loginTimestamp |-> loginTimestamp.value,
         protocol       |-> protocol.value ], protocol.rest)

ZeroLoginMessage ==
    [ user1          |-> [i \in 1 .. 16 |-> 0],
      pwd1           |-> [i \in 1 .. 16 |-> 0],
      loginTimestamp |-> [i \in 1 .. 6 |-> 0],
      protocol       |-> [i \in 1 .. 2 |-> 0] ]

(* Login Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginMessage ==
    { ZeroLoginMessage }
        \cup { [ZeroLoginMessage EXCEPT !.user1 = one] : one \in Sample(16) }
        \cup { [ZeroLoginMessage EXCEPT !.pwd1 = one] : one \in Sample(16) }
        \cup { [ZeroLoginMessage EXCEPT !.loginTimestamp = one] : one \in Sample(6) }
        \cup { [ZeroLoginMessage EXCEPT !.protocol = one] : one \in Sample(2) }

(***************************************************************************)
(* Retransmission Request Message: 20 bytes                                *)
(***************************************************************************)

RetransmissionRequestMessage ==
    [ line  : Sample(2),
      start : Sample(9),
      end   : Sample(9) ]

EncodeRetransmissionRequestMessage(message) ==
    message.line
        \o message.start
        \o message.end

DecodeRetransmissionRequestMessage(bytes) ==
    LET line == ReadBytes(bytes, 2) IN IF ~line.ok THEN Fail ELSE
    LET start == ReadBytes(line.rest, 9) IN IF ~start.ok THEN Fail ELSE
    LET end == ReadBytes(start.rest, 9) IN IF ~end.ok THEN Fail ELSE
    Ok([ line  |-> line.value,
         start |-> start.value,
         end   |-> end.value ], end.rest)

ZeroRetransmissionRequestMessage ==
    [ line  |-> [i \in 1 .. 2 |-> 0],
      start |-> [i \in 1 .. 9 |-> 0],
      end   |-> [i \in 1 .. 9 |-> 0] ]

(* Retransmission Request Message at zero, then each field in turn at the values it is checked at *)
CheckedRetransmissionRequestMessage ==
    { ZeroRetransmissionRequestMessage }
        \cup { [ZeroRetransmissionRequestMessage EXCEPT !.line = one] : one \in Sample(2) }
        \cup { [ZeroRetransmissionRequestMessage EXCEPT !.start = one] : one \in Sample(9) }
        \cup { [ZeroRetransmissionRequestMessage EXCEPT !.end = one] : one \in Sample(9) }

(***************************************************************************)
(* Error Message Message: 84 bytes                                         *)
(***************************************************************************)

ErrorMessageMessage ==
    [ errorCode : Sample(4),
      errorMsg  : Sample(80) ]

EncodeErrorMessageMessage(message) ==
    message.errorCode
        \o message.errorMsg

DecodeErrorMessageMessage(bytes) ==
    LET errorCode == ReadBytes(bytes, 4) IN IF ~errorCode.ok THEN Fail ELSE
    LET errorMsg == ReadBytes(errorCode.rest, 80) IN IF ~errorMsg.ok THEN Fail ELSE
    Ok([ errorCode |-> errorCode.value,
         errorMsg  |-> errorMsg.value ], errorMsg.rest)

ZeroErrorMessageMessage ==
    [ errorCode |-> [i \in 1 .. 4 |-> 0],
      errorMsg  |-> [i \in 1 .. 80 |-> 0] ]

(* Error Message Message at zero, then each field in turn at the values it is checked at *)
CheckedErrorMessageMessage ==
    { ZeroErrorMessageMessage }
        \cup { [ZeroErrorMessageMessage EXCEPT !.errorCode = one] : one \in Sample(4) }
        \cup { [ZeroErrorMessageMessage EXCEPT !.errorMsg = one] : one \in Sample(80) }

(***************************************************************************)
(* Long Message Header: 12 bytes                                           *)
(***************************************************************************)

LongMessageHeader ==
    [ messageTimestamp : Sample(12) ]

EncodeLongMessageHeader(message) ==
    message.messageTimestamp

DecodeLongMessageHeader(bytes) ==
    LET messageTimestamp == ReadBytes(bytes, 12) IN IF ~messageTimestamp.ok THEN Fail ELSE
    Ok([ messageTimestamp |-> messageTimestamp.value ], messageTimestamp.rest)

ZeroLongMessageHeader ==
    [ messageTimestamp |-> [i \in 1 .. 12 |-> 0] ]

(* Long Message Header at zero, then each field in turn at the values it is checked at *)
CheckedLongMessageHeader ==
    { ZeroLongMessageHeader }
        \cup { [ZeroLongMessageHeader EXCEPT !.messageTimestamp = one] : one \in Sample(12) }

(***************************************************************************)
(* Option Symbol: 20 bytes                                                 *)
(***************************************************************************)

OptionSymbol ==
    [ root                         : Sample(6),
      expiryMonth                  : Sample(1),
      filler1                      : Sample(1),
      strikePrice                  : Sample(7),
      strikePriceFractionIndicator : Sample(1),
      expiryYear                   : Sample(2),
      expiryDay                    : Sample(2) ]

EncodeOptionSymbol(message) ==
    message.root
        \o message.expiryMonth
        \o message.filler1
        \o message.strikePrice
        \o message.strikePriceFractionIndicator
        \o message.expiryYear
        \o message.expiryDay

DecodeOptionSymbol(bytes) ==
    LET root == ReadBytes(bytes, 6) IN IF ~root.ok THEN Fail ELSE
    LET expiryMonth == ReadBytes(root.rest, 1) IN IF ~expiryMonth.ok THEN Fail ELSE
    LET filler1 == ReadBytes(expiryMonth.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(filler1.rest, 7) IN IF ~strikePrice.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePrice.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(strikePriceFractionIndicator.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ root                         |-> root.value,
         expiryMonth                  |-> expiryMonth.value,
         filler1                      |-> filler1.value,
         strikePrice                  |-> strikePrice.value,
         strikePriceFractionIndicator |-> strikePriceFractionIndicator.value,
         expiryYear                   |-> expiryYear.value,
         expiryDay                    |-> expiryDay.value ], expiryDay.rest)

ZeroOptionSymbol ==
    [ root                         |-> [i \in 1 .. 6 |-> 0],
      expiryMonth                  |-> [i \in 1 .. 1 |-> 0],
      filler1                      |-> [i \in 1 .. 1 |-> 0],
      strikePrice                  |-> [i \in 1 .. 7 |-> 0],
      strikePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      expiryYear                   |-> [i \in 1 .. 2 |-> 0],
      expiryDay                    |-> [i \in 1 .. 2 |-> 0] ]

(* Option Symbol at zero, then each field in turn at the values it is checked at *)
CheckedOptionSymbol ==
    { ZeroOptionSymbol }
        \cup { [ZeroOptionSymbol EXCEPT !.root = one] : one \in Sample(6) }
        \cup { [ZeroOptionSymbol EXCEPT !.expiryMonth = one] : one \in Sample(1) }
        \cup { [ZeroOptionSymbol EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroOptionSymbol EXCEPT !.strikePrice = one] : one \in Sample(7) }
        \cup { [ZeroOptionSymbol EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionSymbol EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroOptionSymbol EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Option Trade Message: 83 bytes                                          *)
(***************************************************************************)

OptionTradeMessage ==
    [ longMessageHeader           : LongMessageHeader,
      exchangeId                  : Sample(1),
      optionSymbol                : OptionSymbol,
      volume                      : Sample(8),
      tradePrice                  : Sample(7),
      tradePriceFractionIndicator : Sample(1),
      netChangeSign               : Sample(1),
      netChange                   : Sample(7),
      netChangeFractionIndicator  : Sample(1),
      filler6                     : Sample(6),
      tradeTimestamp              : Sample(9),
      filler1                     : Sample(1),
      priceIndicatorMarker        : Sample(1),
      tradeNumber                 : Sample(8) ]

EncodeOptionTradeMessage(message) ==
    EncodeLongMessageHeader(message.longMessageHeader)
        \o message.exchangeId
        \o EncodeOptionSymbol(message.optionSymbol)
        \o message.volume
        \o message.tradePrice
        \o message.tradePriceFractionIndicator
        \o message.netChangeSign
        \o message.netChange
        \o message.netChangeFractionIndicator
        \o message.filler6
        \o message.tradeTimestamp
        \o message.filler1
        \o message.priceIndicatorMarker
        \o message.tradeNumber

DecodeOptionTradeMessage(bytes) ==
    LET longMessageHeader == DecodeLongMessageHeader(bytes) IN IF ~longMessageHeader.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(longMessageHeader.rest, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET optionSymbol == DecodeOptionSymbol(exchangeId.rest) IN IF ~optionSymbol.ok THEN Fail ELSE
    LET volume == ReadBytes(optionSymbol.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(volume.rest, 7) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradePriceFractionIndicator == ReadBytes(tradePrice.rest, 1) IN IF ~tradePriceFractionIndicator.ok THEN Fail ELSE
    LET netChangeSign == ReadBytes(tradePriceFractionIndicator.rest, 1) IN IF ~netChangeSign.ok THEN Fail ELSE
    LET netChange == ReadBytes(netChangeSign.rest, 7) IN IF ~netChange.ok THEN Fail ELSE
    LET netChangeFractionIndicator == ReadBytes(netChange.rest, 1) IN IF ~netChangeFractionIndicator.ok THEN Fail ELSE
    LET filler6 == ReadBytes(netChangeFractionIndicator.rest, 6) IN IF ~filler6.ok THEN Fail ELSE
    LET tradeTimestamp == ReadBytes(filler6.rest, 9) IN IF ~tradeTimestamp.ok THEN Fail ELSE
    LET filler1 == ReadBytes(tradeTimestamp.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET priceIndicatorMarker == ReadBytes(filler1.rest, 1) IN IF ~priceIndicatorMarker.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(priceIndicatorMarker.rest, 8) IN IF ~tradeNumber.ok THEN Fail ELSE
    Ok([ longMessageHeader           |-> longMessageHeader.value,
         exchangeId                  |-> exchangeId.value,
         optionSymbol                |-> optionSymbol.value,
         volume                      |-> volume.value,
         tradePrice                  |-> tradePrice.value,
         tradePriceFractionIndicator |-> tradePriceFractionIndicator.value,
         netChangeSign               |-> netChangeSign.value,
         netChange                   |-> netChange.value,
         netChangeFractionIndicator  |-> netChangeFractionIndicator.value,
         filler6                     |-> filler6.value,
         tradeTimestamp              |-> tradeTimestamp.value,
         filler1                     |-> filler1.value,
         priceIndicatorMarker        |-> priceIndicatorMarker.value,
         tradeNumber                 |-> tradeNumber.value ], tradeNumber.rest)

ZeroOptionTradeMessage ==
    [ longMessageHeader           |-> ZeroLongMessageHeader,
      exchangeId                  |-> [i \in 1 .. 1 |-> 0],
      optionSymbol                |-> ZeroOptionSymbol,
      volume                      |-> [i \in 1 .. 8 |-> 0],
      tradePrice                  |-> [i \in 1 .. 7 |-> 0],
      tradePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      netChangeSign               |-> [i \in 1 .. 1 |-> 0],
      netChange                   |-> [i \in 1 .. 7 |-> 0],
      netChangeFractionIndicator  |-> [i \in 1 .. 1 |-> 0],
      filler6                     |-> [i \in 1 .. 6 |-> 0],
      tradeTimestamp              |-> [i \in 1 .. 9 |-> 0],
      filler1                     |-> [i \in 1 .. 1 |-> 0],
      priceIndicatorMarker        |-> [i \in 1 .. 1 |-> 0],
      tradeNumber                 |-> [i \in 1 .. 8 |-> 0] ]

(* Option Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionTradeMessage ==
    { ZeroOptionTradeMessage }
        \cup { [ZeroOptionTradeMessage EXCEPT !.longMessageHeader = one] : one \in CheckedLongMessageHeader }
        \cup { [ZeroOptionTradeMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.optionSymbol = one] : one \in CheckedOptionSymbol }
        \cup { [ZeroOptionTradeMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.tradePrice = one] : one \in Sample(7) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.tradePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.netChangeSign = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.netChange = one] : one \in Sample(7) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.netChangeFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.filler6 = one] : one \in Sample(6) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.tradeTimestamp = one] : one \in Sample(9) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.priceIndicatorMarker = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.tradeNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Long Message Header: 12 bytes                                           *)
(***************************************************************************)

LongMessageHeader2 ==
    [ messageTimestamp : Sample(12) ]

EncodeLongMessageHeader2(message) ==
    message.messageTimestamp

DecodeLongMessageHeader2(bytes) ==
    LET messageTimestamp == ReadBytes(bytes, 12) IN IF ~messageTimestamp.ok THEN Fail ELSE
    Ok([ messageTimestamp |-> messageTimestamp.value ], messageTimestamp.rest)

ZeroLongMessageHeader2 ==
    [ messageTimestamp |-> [i \in 1 .. 12 |-> 0] ]

(* Long Message Header at zero, then each field in turn at the values it is checked at *)
CheckedLongMessageHeader2 ==
    { ZeroLongMessageHeader2 }
        \cup { [ZeroLongMessageHeader2 EXCEPT !.messageTimestamp = one] : one \in Sample(12) }

(***************************************************************************)
(* Future Option Symbol: 20 bytes                                          *)
(***************************************************************************)

FutureOptionSymbol ==
    [ root                         : Sample(6),
      symbolMonth                  : Sample(1),
      symbolYear                   : Sample(2),
      expiryDay                    : Sample(2),
      callPutCode                  : Sample(1),
      strikePrice                  : Sample(7),
      strikePriceFractionIndicator : Sample(1) ]

EncodeFutureOptionSymbol(message) ==
    message.root
        \o message.symbolMonth
        \o message.symbolYear
        \o message.expiryDay
        \o message.callPutCode
        \o message.strikePrice
        \o message.strikePriceFractionIndicator

DecodeFutureOptionSymbol(bytes) ==
    LET root == ReadBytes(bytes, 6) IN IF ~root.ok THEN Fail ELSE
    LET symbolMonth == ReadBytes(root.rest, 1) IN IF ~symbolMonth.ok THEN Fail ELSE
    LET symbolYear == ReadBytes(symbolMonth.rest, 2) IN IF ~symbolYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(symbolYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET callPutCode == ReadBytes(expiryDay.rest, 1) IN IF ~callPutCode.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(callPutCode.rest, 7) IN IF ~strikePrice.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePrice.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    Ok([ root                         |-> root.value,
         symbolMonth                  |-> symbolMonth.value,
         symbolYear                   |-> symbolYear.value,
         expiryDay                    |-> expiryDay.value,
         callPutCode                  |-> callPutCode.value,
         strikePrice                  |-> strikePrice.value,
         strikePriceFractionIndicator |-> strikePriceFractionIndicator.value ], strikePriceFractionIndicator.rest)

ZeroFutureOptionSymbol ==
    [ root                         |-> [i \in 1 .. 6 |-> 0],
      symbolMonth                  |-> [i \in 1 .. 1 |-> 0],
      symbolYear                   |-> [i \in 1 .. 2 |-> 0],
      expiryDay                    |-> [i \in 1 .. 2 |-> 0],
      callPutCode                  |-> [i \in 1 .. 1 |-> 0],
      strikePrice                  |-> [i \in 1 .. 7 |-> 0],
      strikePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Future Option Symbol at zero, then each field in turn at the values it is checked at *)
CheckedFutureOptionSymbol ==
    { ZeroFutureOptionSymbol }
        \cup { [ZeroFutureOptionSymbol EXCEPT !.root = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionSymbol EXCEPT !.symbolMonth = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionSymbol EXCEPT !.symbolYear = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionSymbol EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionSymbol EXCEPT !.callPutCode = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionSymbol EXCEPT !.strikePrice = one] : one \in Sample(7) }
        \cup { [ZeroFutureOptionSymbol EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Future Options Trade Message: 84 bytes                                  *)
(***************************************************************************)

FutureOptionsTradeMessage ==
    [ longMessageHeader           : LongMessageHeader2,
      exchangeId                  : Sample(1),
      futureOptionSymbol          : FutureOptionSymbol,
      volume                      : Sample(8),
      tradePrice                  : Sample(7),
      tradePriceFractionIndicator : Sample(1),
      priceIndicatorMarker        : Sample(1),
      netChangeSign               : Sample(1),
      netChange                   : Sample(7),
      netChangeFractionIndicator  : Sample(1),
      filler6                     : Sample(6),
      tradeTimestamp              : Sample(9),
      filler2                     : Sample(2),
      tradeNumber                 : Sample(8) ]

EncodeFutureOptionsTradeMessage(message) ==
    EncodeLongMessageHeader2(message.longMessageHeader)
        \o message.exchangeId
        \o EncodeFutureOptionSymbol(message.futureOptionSymbol)
        \o message.volume
        \o message.tradePrice
        \o message.tradePriceFractionIndicator
        \o message.priceIndicatorMarker
        \o message.netChangeSign
        \o message.netChange
        \o message.netChangeFractionIndicator
        \o message.filler6
        \o message.tradeTimestamp
        \o message.filler2
        \o message.tradeNumber

DecodeFutureOptionsTradeMessage(bytes) ==
    LET longMessageHeader == DecodeLongMessageHeader2(bytes) IN IF ~longMessageHeader.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(longMessageHeader.rest, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET futureOptionSymbol == DecodeFutureOptionSymbol(exchangeId.rest) IN IF ~futureOptionSymbol.ok THEN Fail ELSE
    LET volume == ReadBytes(futureOptionSymbol.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(volume.rest, 7) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradePriceFractionIndicator == ReadBytes(tradePrice.rest, 1) IN IF ~tradePriceFractionIndicator.ok THEN Fail ELSE
    LET priceIndicatorMarker == ReadBytes(tradePriceFractionIndicator.rest, 1) IN IF ~priceIndicatorMarker.ok THEN Fail ELSE
    LET netChangeSign == ReadBytes(priceIndicatorMarker.rest, 1) IN IF ~netChangeSign.ok THEN Fail ELSE
    LET netChange == ReadBytes(netChangeSign.rest, 7) IN IF ~netChange.ok THEN Fail ELSE
    LET netChangeFractionIndicator == ReadBytes(netChange.rest, 1) IN IF ~netChangeFractionIndicator.ok THEN Fail ELSE
    LET filler6 == ReadBytes(netChangeFractionIndicator.rest, 6) IN IF ~filler6.ok THEN Fail ELSE
    LET tradeTimestamp == ReadBytes(filler6.rest, 9) IN IF ~tradeTimestamp.ok THEN Fail ELSE
    LET filler2 == ReadBytes(tradeTimestamp.rest, 2) IN IF ~filler2.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(filler2.rest, 8) IN IF ~tradeNumber.ok THEN Fail ELSE
    Ok([ longMessageHeader           |-> longMessageHeader.value,
         exchangeId                  |-> exchangeId.value,
         futureOptionSymbol          |-> futureOptionSymbol.value,
         volume                      |-> volume.value,
         tradePrice                  |-> tradePrice.value,
         tradePriceFractionIndicator |-> tradePriceFractionIndicator.value,
         priceIndicatorMarker        |-> priceIndicatorMarker.value,
         netChangeSign               |-> netChangeSign.value,
         netChange                   |-> netChange.value,
         netChangeFractionIndicator  |-> netChangeFractionIndicator.value,
         filler6                     |-> filler6.value,
         tradeTimestamp              |-> tradeTimestamp.value,
         filler2                     |-> filler2.value,
         tradeNumber                 |-> tradeNumber.value ], tradeNumber.rest)

ZeroFutureOptionsTradeMessage ==
    [ longMessageHeader           |-> ZeroLongMessageHeader2,
      exchangeId                  |-> [i \in 1 .. 1 |-> 0],
      futureOptionSymbol          |-> ZeroFutureOptionSymbol,
      volume                      |-> [i \in 1 .. 8 |-> 0],
      tradePrice                  |-> [i \in 1 .. 7 |-> 0],
      tradePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      priceIndicatorMarker        |-> [i \in 1 .. 1 |-> 0],
      netChangeSign               |-> [i \in 1 .. 1 |-> 0],
      netChange                   |-> [i \in 1 .. 7 |-> 0],
      netChangeFractionIndicator  |-> [i \in 1 .. 1 |-> 0],
      filler6                     |-> [i \in 1 .. 6 |-> 0],
      tradeTimestamp              |-> [i \in 1 .. 9 |-> 0],
      filler2                     |-> [i \in 1 .. 2 |-> 0],
      tradeNumber                 |-> [i \in 1 .. 8 |-> 0] ]

(* Future Options Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedFutureOptionsTradeMessage ==
    { ZeroFutureOptionsTradeMessage }
        \cup { [ZeroFutureOptionsTradeMessage EXCEPT !.longMessageHeader = one] : one \in CheckedLongMessageHeader2 }
        \cup { [ZeroFutureOptionsTradeMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsTradeMessage EXCEPT !.futureOptionSymbol = one] : one \in CheckedFutureOptionSymbol }
        \cup { [ZeroFutureOptionsTradeMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroFutureOptionsTradeMessage EXCEPT !.tradePrice = one] : one \in Sample(7) }
        \cup { [ZeroFutureOptionsTradeMessage EXCEPT !.tradePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsTradeMessage EXCEPT !.priceIndicatorMarker = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsTradeMessage EXCEPT !.netChangeSign = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsTradeMessage EXCEPT !.netChange = one] : one \in Sample(7) }
        \cup { [ZeroFutureOptionsTradeMessage EXCEPT !.netChangeFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsTradeMessage EXCEPT !.filler6 = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionsTradeMessage EXCEPT !.tradeTimestamp = one] : one \in Sample(9) }
        \cup { [ZeroFutureOptionsTradeMessage EXCEPT !.filler2 = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionsTradeMessage EXCEPT !.tradeNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Long Message Header: 12 bytes                                           *)
(***************************************************************************)

LongMessageHeader3 ==
    [ messageTimestamp : Sample(12) ]

EncodeLongMessageHeader3(message) ==
    message.messageTimestamp

DecodeLongMessageHeader3(bytes) ==
    LET messageTimestamp == ReadBytes(bytes, 12) IN IF ~messageTimestamp.ok THEN Fail ELSE
    Ok([ messageTimestamp |-> messageTimestamp.value ], messageTimestamp.rest)

ZeroLongMessageHeader3 ==
    [ messageTimestamp |-> [i \in 1 .. 12 |-> 0] ]

(* Long Message Header at zero, then each field in turn at the values it is checked at *)
CheckedLongMessageHeader3 ==
    { ZeroLongMessageHeader3 }
        \cup { [ZeroLongMessageHeader3 EXCEPT !.messageTimestamp = one] : one \in Sample(12) }

(***************************************************************************)
(* Future Product: 11 bytes                                                *)
(***************************************************************************)

FutureProduct ==
    [ root        : Sample(6),
      symbolMonth : Sample(1),
      symbolYear  : Sample(2),
      expiryDay   : Sample(2) ]

EncodeFutureProduct(message) ==
    message.root
        \o message.symbolMonth
        \o message.symbolYear
        \o message.expiryDay

DecodeFutureProduct(bytes) ==
    LET root == ReadBytes(bytes, 6) IN IF ~root.ok THEN Fail ELSE
    LET symbolMonth == ReadBytes(root.rest, 1) IN IF ~symbolMonth.ok THEN Fail ELSE
    LET symbolYear == ReadBytes(symbolMonth.rest, 2) IN IF ~symbolYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(symbolYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ root        |-> root.value,
         symbolMonth |-> symbolMonth.value,
         symbolYear  |-> symbolYear.value,
         expiryDay   |-> expiryDay.value ], expiryDay.rest)

ZeroFutureProduct ==
    [ root        |-> [i \in 1 .. 6 |-> 0],
      symbolMonth |-> [i \in 1 .. 1 |-> 0],
      symbolYear  |-> [i \in 1 .. 2 |-> 0],
      expiryDay   |-> [i \in 1 .. 2 |-> 0] ]

(* Future Product at zero, then each field in turn at the values it is checked at *)
CheckedFutureProduct ==
    { ZeroFutureProduct }
        \cup { [ZeroFutureProduct EXCEPT !.root = one] : one \in Sample(6) }
        \cup { [ZeroFutureProduct EXCEPT !.symbolMonth = one] : one \in Sample(1) }
        \cup { [ZeroFutureProduct EXCEPT !.symbolYear = one] : one \in Sample(2) }
        \cup { [ZeroFutureProduct EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Futures Trade Message: 73 bytes                                         *)
(***************************************************************************)

FuturesTradeMessage ==
    [ longMessageHeader           : LongMessageHeader3,
      exchangeId                  : Sample(1),
      futureProduct               : FutureProduct,
      volume                      : Sample(8),
      tradePrice                  : Sample(7),
      tradePriceFractionIndicator : Sample(1),
      netChangeSign               : Sample(1),
      netChange                   : Sample(7),
      netChangeFractionIndicator  : Sample(1),
      filler6                     : Sample(6),
      tradeTimestamp              : Sample(9),
      priceIndicatorMarker        : Sample(1),
      tradeNumber                 : Sample(8) ]

EncodeFuturesTradeMessage(message) ==
    EncodeLongMessageHeader3(message.longMessageHeader)
        \o message.exchangeId
        \o EncodeFutureProduct(message.futureProduct)
        \o message.volume
        \o message.tradePrice
        \o message.tradePriceFractionIndicator
        \o message.netChangeSign
        \o message.netChange
        \o message.netChangeFractionIndicator
        \o message.filler6
        \o message.tradeTimestamp
        \o message.priceIndicatorMarker
        \o message.tradeNumber

DecodeFuturesTradeMessage(bytes) ==
    LET longMessageHeader == DecodeLongMessageHeader3(bytes) IN IF ~longMessageHeader.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(longMessageHeader.rest, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET futureProduct == DecodeFutureProduct(exchangeId.rest) IN IF ~futureProduct.ok THEN Fail ELSE
    LET volume == ReadBytes(futureProduct.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(volume.rest, 7) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradePriceFractionIndicator == ReadBytes(tradePrice.rest, 1) IN IF ~tradePriceFractionIndicator.ok THEN Fail ELSE
    LET netChangeSign == ReadBytes(tradePriceFractionIndicator.rest, 1) IN IF ~netChangeSign.ok THEN Fail ELSE
    LET netChange == ReadBytes(netChangeSign.rest, 7) IN IF ~netChange.ok THEN Fail ELSE
    LET netChangeFractionIndicator == ReadBytes(netChange.rest, 1) IN IF ~netChangeFractionIndicator.ok THEN Fail ELSE
    LET filler6 == ReadBytes(netChangeFractionIndicator.rest, 6) IN IF ~filler6.ok THEN Fail ELSE
    LET tradeTimestamp == ReadBytes(filler6.rest, 9) IN IF ~tradeTimestamp.ok THEN Fail ELSE
    LET priceIndicatorMarker == ReadBytes(tradeTimestamp.rest, 1) IN IF ~priceIndicatorMarker.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(priceIndicatorMarker.rest, 8) IN IF ~tradeNumber.ok THEN Fail ELSE
    Ok([ longMessageHeader           |-> longMessageHeader.value,
         exchangeId                  |-> exchangeId.value,
         futureProduct               |-> futureProduct.value,
         volume                      |-> volume.value,
         tradePrice                  |-> tradePrice.value,
         tradePriceFractionIndicator |-> tradePriceFractionIndicator.value,
         netChangeSign               |-> netChangeSign.value,
         netChange                   |-> netChange.value,
         netChangeFractionIndicator  |-> netChangeFractionIndicator.value,
         filler6                     |-> filler6.value,
         tradeTimestamp              |-> tradeTimestamp.value,
         priceIndicatorMarker        |-> priceIndicatorMarker.value,
         tradeNumber                 |-> tradeNumber.value ], tradeNumber.rest)

ZeroFuturesTradeMessage ==
    [ longMessageHeader           |-> ZeroLongMessageHeader3,
      exchangeId                  |-> [i \in 1 .. 1 |-> 0],
      futureProduct               |-> ZeroFutureProduct,
      volume                      |-> [i \in 1 .. 8 |-> 0],
      tradePrice                  |-> [i \in 1 .. 7 |-> 0],
      tradePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      netChangeSign               |-> [i \in 1 .. 1 |-> 0],
      netChange                   |-> [i \in 1 .. 7 |-> 0],
      netChangeFractionIndicator  |-> [i \in 1 .. 1 |-> 0],
      filler6                     |-> [i \in 1 .. 6 |-> 0],
      tradeTimestamp              |-> [i \in 1 .. 9 |-> 0],
      priceIndicatorMarker        |-> [i \in 1 .. 1 |-> 0],
      tradeNumber                 |-> [i \in 1 .. 8 |-> 0] ]

(* Futures Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedFuturesTradeMessage ==
    { ZeroFuturesTradeMessage }
        \cup { [ZeroFuturesTradeMessage EXCEPT !.longMessageHeader = one] : one \in CheckedLongMessageHeader3 }
        \cup { [ZeroFuturesTradeMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroFuturesTradeMessage EXCEPT !.futureProduct = one] : one \in CheckedFutureProduct }
        \cup { [ZeroFuturesTradeMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroFuturesTradeMessage EXCEPT !.tradePrice = one] : one \in Sample(7) }
        \cup { [ZeroFuturesTradeMessage EXCEPT !.tradePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFuturesTradeMessage EXCEPT !.netChangeSign = one] : one \in Sample(1) }
        \cup { [ZeroFuturesTradeMessage EXCEPT !.netChange = one] : one \in Sample(7) }
        \cup { [ZeroFuturesTradeMessage EXCEPT !.netChangeFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFuturesTradeMessage EXCEPT !.filler6 = one] : one \in Sample(6) }
        \cup { [ZeroFuturesTradeMessage EXCEPT !.tradeTimestamp = one] : one \in Sample(9) }
        \cup { [ZeroFuturesTradeMessage EXCEPT !.priceIndicatorMarker = one] : one \in Sample(1) }
        \cup { [ZeroFuturesTradeMessage EXCEPT !.tradeNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Long Message Header: 12 bytes                                           *)
(***************************************************************************)

LongMessageHeader4 ==
    [ messageTimestamp : Sample(12) ]

EncodeLongMessageHeader4(message) ==
    message.messageTimestamp

DecodeLongMessageHeader4(bytes) ==
    LET messageTimestamp == ReadBytes(bytes, 12) IN IF ~messageTimestamp.ok THEN Fail ELSE
    Ok([ messageTimestamp |-> messageTimestamp.value ], messageTimestamp.rest)

ZeroLongMessageHeader4 ==
    [ messageTimestamp |-> [i \in 1 .. 12 |-> 0] ]

(* Long Message Header at zero, then each field in turn at the values it is checked at *)
CheckedLongMessageHeader4 ==
    { ZeroLongMessageHeader4 }
        \cup { [ZeroLongMessageHeader4 EXCEPT !.messageTimestamp = one] : one \in Sample(12) }

(***************************************************************************)
(* Strategy Trade Message: 93 bytes                                        *)
(***************************************************************************)

StrategyTradeMessage ==
    [ longMessageHeader           : LongMessageHeader4,
      exchangeId                  : Sample(1),
      symbol                      : Sample(30),
      volume                      : Sample(8),
      tradePriceSign              : Sample(1),
      tradePrice                  : Sample(7),
      tradePriceFractionIndicator : Sample(1),
      netChangeSign               : Sample(1),
      netChange                   : Sample(7),
      netChangeFractionIndicator  : Sample(1),
      filler6                     : Sample(6),
      tradeTimestamp              : Sample(9),
      priceIndicatorMarker        : Sample(1),
      tradeNumber                 : Sample(8) ]

EncodeStrategyTradeMessage(message) ==
    EncodeLongMessageHeader4(message.longMessageHeader)
        \o message.exchangeId
        \o message.symbol
        \o message.volume
        \o message.tradePriceSign
        \o message.tradePrice
        \o message.tradePriceFractionIndicator
        \o message.netChangeSign
        \o message.netChange
        \o message.netChangeFractionIndicator
        \o message.filler6
        \o message.tradeTimestamp
        \o message.priceIndicatorMarker
        \o message.tradeNumber

DecodeStrategyTradeMessage(bytes) ==
    LET longMessageHeader == DecodeLongMessageHeader4(bytes) IN IF ~longMessageHeader.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(longMessageHeader.rest, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET symbol == ReadBytes(exchangeId.rest, 30) IN IF ~symbol.ok THEN Fail ELSE
    LET volume == ReadBytes(symbol.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET tradePriceSign == ReadBytes(volume.rest, 1) IN IF ~tradePriceSign.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(tradePriceSign.rest, 7) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradePriceFractionIndicator == ReadBytes(tradePrice.rest, 1) IN IF ~tradePriceFractionIndicator.ok THEN Fail ELSE
    LET netChangeSign == ReadBytes(tradePriceFractionIndicator.rest, 1) IN IF ~netChangeSign.ok THEN Fail ELSE
    LET netChange == ReadBytes(netChangeSign.rest, 7) IN IF ~netChange.ok THEN Fail ELSE
    LET netChangeFractionIndicator == ReadBytes(netChange.rest, 1) IN IF ~netChangeFractionIndicator.ok THEN Fail ELSE
    LET filler6 == ReadBytes(netChangeFractionIndicator.rest, 6) IN IF ~filler6.ok THEN Fail ELSE
    LET tradeTimestamp == ReadBytes(filler6.rest, 9) IN IF ~tradeTimestamp.ok THEN Fail ELSE
    LET priceIndicatorMarker == ReadBytes(tradeTimestamp.rest, 1) IN IF ~priceIndicatorMarker.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(priceIndicatorMarker.rest, 8) IN IF ~tradeNumber.ok THEN Fail ELSE
    Ok([ longMessageHeader           |-> longMessageHeader.value,
         exchangeId                  |-> exchangeId.value,
         symbol                      |-> symbol.value,
         volume                      |-> volume.value,
         tradePriceSign              |-> tradePriceSign.value,
         tradePrice                  |-> tradePrice.value,
         tradePriceFractionIndicator |-> tradePriceFractionIndicator.value,
         netChangeSign               |-> netChangeSign.value,
         netChange                   |-> netChange.value,
         netChangeFractionIndicator  |-> netChangeFractionIndicator.value,
         filler6                     |-> filler6.value,
         tradeTimestamp              |-> tradeTimestamp.value,
         priceIndicatorMarker        |-> priceIndicatorMarker.value,
         tradeNumber                 |-> tradeNumber.value ], tradeNumber.rest)

ZeroStrategyTradeMessage ==
    [ longMessageHeader           |-> ZeroLongMessageHeader4,
      exchangeId                  |-> [i \in 1 .. 1 |-> 0],
      symbol                      |-> [i \in 1 .. 30 |-> 0],
      volume                      |-> [i \in 1 .. 8 |-> 0],
      tradePriceSign              |-> [i \in 1 .. 1 |-> 0],
      tradePrice                  |-> [i \in 1 .. 7 |-> 0],
      tradePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      netChangeSign               |-> [i \in 1 .. 1 |-> 0],
      netChange                   |-> [i \in 1 .. 7 |-> 0],
      netChangeFractionIndicator  |-> [i \in 1 .. 1 |-> 0],
      filler6                     |-> [i \in 1 .. 6 |-> 0],
      tradeTimestamp              |-> [i \in 1 .. 9 |-> 0],
      priceIndicatorMarker        |-> [i \in 1 .. 1 |-> 0],
      tradeNumber                 |-> [i \in 1 .. 8 |-> 0] ]

(* Strategy Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedStrategyTradeMessage ==
    { ZeroStrategyTradeMessage }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.longMessageHeader = one] : one \in CheckedLongMessageHeader4 }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.symbol = one] : one \in Sample(30) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.tradePriceSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.tradePrice = one] : one \in Sample(7) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.tradePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.netChangeSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.netChange = one] : one \in Sample(7) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.netChangeFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.filler6 = one] : one \in Sample(6) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.tradeTimestamp = one] : one \in Sample(9) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.priceIndicatorMarker = one] : one \in Sample(1) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.tradeNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Long Message Header: 12 bytes                                           *)
(***************************************************************************)

LongMessageHeader5 ==
    [ messageTimestamp : Sample(12) ]

EncodeLongMessageHeader5(message) ==
    message.messageTimestamp

DecodeLongMessageHeader5(bytes) ==
    LET messageTimestamp == ReadBytes(bytes, 12) IN IF ~messageTimestamp.ok THEN Fail ELSE
    Ok([ messageTimestamp |-> messageTimestamp.value ], messageTimestamp.rest)

ZeroLongMessageHeader5 ==
    [ messageTimestamp |-> [i \in 1 .. 12 |-> 0] ]

(* Long Message Header at zero, then each field in turn at the values it is checked at *)
CheckedLongMessageHeader5 ==
    { ZeroLongMessageHeader5 }
        \cup { [ZeroLongMessageHeader5 EXCEPT !.messageTimestamp = one] : one \in Sample(12) }

(***************************************************************************)
(* Option Symbol: 20 bytes                                                 *)
(***************************************************************************)

OptionSymbol2 ==
    [ root                         : Sample(6),
      expiryMonth                  : Sample(1),
      filler1                      : Sample(1),
      strikePrice                  : Sample(7),
      strikePriceFractionIndicator : Sample(1),
      expiryYear                   : Sample(2),
      expiryDay                    : Sample(2) ]

EncodeOptionSymbol2(message) ==
    message.root
        \o message.expiryMonth
        \o message.filler1
        \o message.strikePrice
        \o message.strikePriceFractionIndicator
        \o message.expiryYear
        \o message.expiryDay

DecodeOptionSymbol2(bytes) ==
    LET root == ReadBytes(bytes, 6) IN IF ~root.ok THEN Fail ELSE
    LET expiryMonth == ReadBytes(root.rest, 1) IN IF ~expiryMonth.ok THEN Fail ELSE
    LET filler1 == ReadBytes(expiryMonth.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(filler1.rest, 7) IN IF ~strikePrice.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePrice.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(strikePriceFractionIndicator.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ root                         |-> root.value,
         expiryMonth                  |-> expiryMonth.value,
         filler1                      |-> filler1.value,
         strikePrice                  |-> strikePrice.value,
         strikePriceFractionIndicator |-> strikePriceFractionIndicator.value,
         expiryYear                   |-> expiryYear.value,
         expiryDay                    |-> expiryDay.value ], expiryDay.rest)

ZeroOptionSymbol2 ==
    [ root                         |-> [i \in 1 .. 6 |-> 0],
      expiryMonth                  |-> [i \in 1 .. 1 |-> 0],
      filler1                      |-> [i \in 1 .. 1 |-> 0],
      strikePrice                  |-> [i \in 1 .. 7 |-> 0],
      strikePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      expiryYear                   |-> [i \in 1 .. 2 |-> 0],
      expiryDay                    |-> [i \in 1 .. 2 |-> 0] ]

(* Option Symbol at zero, then each field in turn at the values it is checked at *)
CheckedOptionSymbol2 ==
    { ZeroOptionSymbol2 }
        \cup { [ZeroOptionSymbol2 EXCEPT !.root = one] : one \in Sample(6) }
        \cup { [ZeroOptionSymbol2 EXCEPT !.expiryMonth = one] : one \in Sample(1) }
        \cup { [ZeroOptionSymbol2 EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroOptionSymbol2 EXCEPT !.strikePrice = one] : one \in Sample(7) }
        \cup { [ZeroOptionSymbol2 EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionSymbol2 EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroOptionSymbol2 EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Option Request For Quote Rfq Message: 42 bytes                          *)
(***************************************************************************)

OptionRequestForQuoteRfqMessage ==
    [ longMessageHeader   : LongMessageHeader5,
      exchangeId          : Sample(1),
      optionSymbol        : OptionSymbol2,
      requestedSize       : Sample(8),
      requestedMarketSide : Sample(1) ]

EncodeOptionRequestForQuoteRfqMessage(message) ==
    EncodeLongMessageHeader5(message.longMessageHeader)
        \o message.exchangeId
        \o EncodeOptionSymbol2(message.optionSymbol)
        \o message.requestedSize
        \o message.requestedMarketSide

DecodeOptionRequestForQuoteRfqMessage(bytes) ==
    LET longMessageHeader == DecodeLongMessageHeader5(bytes) IN IF ~longMessageHeader.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(longMessageHeader.rest, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET optionSymbol == DecodeOptionSymbol2(exchangeId.rest) IN IF ~optionSymbol.ok THEN Fail ELSE
    LET requestedSize == ReadBytes(optionSymbol.rest, 8) IN IF ~requestedSize.ok THEN Fail ELSE
    LET requestedMarketSide == ReadBytes(requestedSize.rest, 1) IN IF ~requestedMarketSide.ok THEN Fail ELSE
    Ok([ longMessageHeader   |-> longMessageHeader.value,
         exchangeId          |-> exchangeId.value,
         optionSymbol        |-> optionSymbol.value,
         requestedSize       |-> requestedSize.value,
         requestedMarketSide |-> requestedMarketSide.value ], requestedMarketSide.rest)

ZeroOptionRequestForQuoteRfqMessage ==
    [ longMessageHeader   |-> ZeroLongMessageHeader5,
      exchangeId          |-> [i \in 1 .. 1 |-> 0],
      optionSymbol        |-> ZeroOptionSymbol2,
      requestedSize       |-> [i \in 1 .. 8 |-> 0],
      requestedMarketSide |-> [i \in 1 .. 1 |-> 0] ]

(* Option Request For Quote Rfq Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionRequestForQuoteRfqMessage ==
    { ZeroOptionRequestForQuoteRfqMessage }
        \cup { [ZeroOptionRequestForQuoteRfqMessage EXCEPT !.longMessageHeader = one] : one \in CheckedLongMessageHeader5 }
        \cup { [ZeroOptionRequestForQuoteRfqMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroOptionRequestForQuoteRfqMessage EXCEPT !.optionSymbol = one] : one \in CheckedOptionSymbol2 }
        \cup { [ZeroOptionRequestForQuoteRfqMessage EXCEPT !.requestedSize = one] : one \in Sample(8) }
        \cup { [ZeroOptionRequestForQuoteRfqMessage EXCEPT !.requestedMarketSide = one] : one \in Sample(1) }

(***************************************************************************)
(* Long Message Header: 12 bytes                                           *)
(***************************************************************************)

LongMessageHeader6 ==
    [ messageTimestamp : Sample(12) ]

EncodeLongMessageHeader6(message) ==
    message.messageTimestamp

DecodeLongMessageHeader6(bytes) ==
    LET messageTimestamp == ReadBytes(bytes, 12) IN IF ~messageTimestamp.ok THEN Fail ELSE
    Ok([ messageTimestamp |-> messageTimestamp.value ], messageTimestamp.rest)

ZeroLongMessageHeader6 ==
    [ messageTimestamp |-> [i \in 1 .. 12 |-> 0] ]

(* Long Message Header at zero, then each field in turn at the values it is checked at *)
CheckedLongMessageHeader6 ==
    { ZeroLongMessageHeader6 }
        \cup { [ZeroLongMessageHeader6 EXCEPT !.messageTimestamp = one] : one \in Sample(12) }

(***************************************************************************)
(* Future Option Symbol: 20 bytes                                          *)
(***************************************************************************)

FutureOptionSymbol2 ==
    [ root                         : Sample(6),
      symbolMonth                  : Sample(1),
      symbolYear                   : Sample(2),
      expiryDay                    : Sample(2),
      callPutCode                  : Sample(1),
      strikePrice                  : Sample(7),
      strikePriceFractionIndicator : Sample(1) ]

EncodeFutureOptionSymbol2(message) ==
    message.root
        \o message.symbolMonth
        \o message.symbolYear
        \o message.expiryDay
        \o message.callPutCode
        \o message.strikePrice
        \o message.strikePriceFractionIndicator

DecodeFutureOptionSymbol2(bytes) ==
    LET root == ReadBytes(bytes, 6) IN IF ~root.ok THEN Fail ELSE
    LET symbolMonth == ReadBytes(root.rest, 1) IN IF ~symbolMonth.ok THEN Fail ELSE
    LET symbolYear == ReadBytes(symbolMonth.rest, 2) IN IF ~symbolYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(symbolYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET callPutCode == ReadBytes(expiryDay.rest, 1) IN IF ~callPutCode.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(callPutCode.rest, 7) IN IF ~strikePrice.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePrice.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    Ok([ root                         |-> root.value,
         symbolMonth                  |-> symbolMonth.value,
         symbolYear                   |-> symbolYear.value,
         expiryDay                    |-> expiryDay.value,
         callPutCode                  |-> callPutCode.value,
         strikePrice                  |-> strikePrice.value,
         strikePriceFractionIndicator |-> strikePriceFractionIndicator.value ], strikePriceFractionIndicator.rest)

ZeroFutureOptionSymbol2 ==
    [ root                         |-> [i \in 1 .. 6 |-> 0],
      symbolMonth                  |-> [i \in 1 .. 1 |-> 0],
      symbolYear                   |-> [i \in 1 .. 2 |-> 0],
      expiryDay                    |-> [i \in 1 .. 2 |-> 0],
      callPutCode                  |-> [i \in 1 .. 1 |-> 0],
      strikePrice                  |-> [i \in 1 .. 7 |-> 0],
      strikePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Future Option Symbol at zero, then each field in turn at the values it is checked at *)
CheckedFutureOptionSymbol2 ==
    { ZeroFutureOptionSymbol2 }
        \cup { [ZeroFutureOptionSymbol2 EXCEPT !.root = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionSymbol2 EXCEPT !.symbolMonth = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionSymbol2 EXCEPT !.symbolYear = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionSymbol2 EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionSymbol2 EXCEPT !.callPutCode = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionSymbol2 EXCEPT !.strikePrice = one] : one \in Sample(7) }
        \cup { [ZeroFutureOptionSymbol2 EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Future Options Request For Quote Rfq Message: 42 bytes                  *)
(***************************************************************************)

FutureOptionsRequestForQuoteRfqMessage ==
    [ longMessageHeader   : LongMessageHeader6,
      exchangeId          : Sample(1),
      futureOptionSymbol  : FutureOptionSymbol2,
      requestedSize       : Sample(8),
      requestedMarketSide : Sample(1) ]

EncodeFutureOptionsRequestForQuoteRfqMessage(message) ==
    EncodeLongMessageHeader6(message.longMessageHeader)
        \o message.exchangeId
        \o EncodeFutureOptionSymbol2(message.futureOptionSymbol)
        \o message.requestedSize
        \o message.requestedMarketSide

DecodeFutureOptionsRequestForQuoteRfqMessage(bytes) ==
    LET longMessageHeader == DecodeLongMessageHeader6(bytes) IN IF ~longMessageHeader.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(longMessageHeader.rest, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET futureOptionSymbol == DecodeFutureOptionSymbol2(exchangeId.rest) IN IF ~futureOptionSymbol.ok THEN Fail ELSE
    LET requestedSize == ReadBytes(futureOptionSymbol.rest, 8) IN IF ~requestedSize.ok THEN Fail ELSE
    LET requestedMarketSide == ReadBytes(requestedSize.rest, 1) IN IF ~requestedMarketSide.ok THEN Fail ELSE
    Ok([ longMessageHeader   |-> longMessageHeader.value,
         exchangeId          |-> exchangeId.value,
         futureOptionSymbol  |-> futureOptionSymbol.value,
         requestedSize       |-> requestedSize.value,
         requestedMarketSide |-> requestedMarketSide.value ], requestedMarketSide.rest)

ZeroFutureOptionsRequestForQuoteRfqMessage ==
    [ longMessageHeader   |-> ZeroLongMessageHeader6,
      exchangeId          |-> [i \in 1 .. 1 |-> 0],
      futureOptionSymbol  |-> ZeroFutureOptionSymbol2,
      requestedSize       |-> [i \in 1 .. 8 |-> 0],
      requestedMarketSide |-> [i \in 1 .. 1 |-> 0] ]

(* Future Options Request For Quote Rfq Message at zero, then each field in turn at the values it is checked at *)
CheckedFutureOptionsRequestForQuoteRfqMessage ==
    { ZeroFutureOptionsRequestForQuoteRfqMessage }
        \cup { [ZeroFutureOptionsRequestForQuoteRfqMessage EXCEPT !.longMessageHeader = one] : one \in CheckedLongMessageHeader6 }
        \cup { [ZeroFutureOptionsRequestForQuoteRfqMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsRequestForQuoteRfqMessage EXCEPT !.futureOptionSymbol = one] : one \in CheckedFutureOptionSymbol2 }
        \cup { [ZeroFutureOptionsRequestForQuoteRfqMessage EXCEPT !.requestedSize = one] : one \in Sample(8) }
        \cup { [ZeroFutureOptionsRequestForQuoteRfqMessage EXCEPT !.requestedMarketSide = one] : one \in Sample(1) }

(***************************************************************************)
(* Long Message Header: 12 bytes                                           *)
(***************************************************************************)

LongMessageHeader7 ==
    [ messageTimestamp : Sample(12) ]

EncodeLongMessageHeader7(message) ==
    message.messageTimestamp

DecodeLongMessageHeader7(bytes) ==
    LET messageTimestamp == ReadBytes(bytes, 12) IN IF ~messageTimestamp.ok THEN Fail ELSE
    Ok([ messageTimestamp |-> messageTimestamp.value ], messageTimestamp.rest)

ZeroLongMessageHeader7 ==
    [ messageTimestamp |-> [i \in 1 .. 12 |-> 0] ]

(* Long Message Header at zero, then each field in turn at the values it is checked at *)
CheckedLongMessageHeader7 ==
    { ZeroLongMessageHeader7 }
        \cup { [ZeroLongMessageHeader7 EXCEPT !.messageTimestamp = one] : one \in Sample(12) }

(***************************************************************************)
(* Future Product: 11 bytes                                                *)
(***************************************************************************)

FutureProduct2 ==
    [ root        : Sample(6),
      symbolMonth : Sample(1),
      symbolYear  : Sample(2),
      expiryDay   : Sample(2) ]

EncodeFutureProduct2(message) ==
    message.root
        \o message.symbolMonth
        \o message.symbolYear
        \o message.expiryDay

DecodeFutureProduct2(bytes) ==
    LET root == ReadBytes(bytes, 6) IN IF ~root.ok THEN Fail ELSE
    LET symbolMonth == ReadBytes(root.rest, 1) IN IF ~symbolMonth.ok THEN Fail ELSE
    LET symbolYear == ReadBytes(symbolMonth.rest, 2) IN IF ~symbolYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(symbolYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ root        |-> root.value,
         symbolMonth |-> symbolMonth.value,
         symbolYear  |-> symbolYear.value,
         expiryDay   |-> expiryDay.value ], expiryDay.rest)

ZeroFutureProduct2 ==
    [ root        |-> [i \in 1 .. 6 |-> 0],
      symbolMonth |-> [i \in 1 .. 1 |-> 0],
      symbolYear  |-> [i \in 1 .. 2 |-> 0],
      expiryDay   |-> [i \in 1 .. 2 |-> 0] ]

(* Future Product at zero, then each field in turn at the values it is checked at *)
CheckedFutureProduct2 ==
    { ZeroFutureProduct2 }
        \cup { [ZeroFutureProduct2 EXCEPT !.root = one] : one \in Sample(6) }
        \cup { [ZeroFutureProduct2 EXCEPT !.symbolMonth = one] : one \in Sample(1) }
        \cup { [ZeroFutureProduct2 EXCEPT !.symbolYear = one] : one \in Sample(2) }
        \cup { [ZeroFutureProduct2 EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Futures Request For Quote Rfq Message: 33 bytes                         *)
(***************************************************************************)

FuturesRequestForQuoteRfqMessage ==
    [ longMessageHeader   : LongMessageHeader7,
      exchangeId          : Sample(1),
      futureProduct       : FutureProduct2,
      requestedSize       : Sample(8),
      requestedMarketSide : Sample(1) ]

EncodeFuturesRequestForQuoteRfqMessage(message) ==
    EncodeLongMessageHeader7(message.longMessageHeader)
        \o message.exchangeId
        \o EncodeFutureProduct2(message.futureProduct)
        \o message.requestedSize
        \o message.requestedMarketSide

DecodeFuturesRequestForQuoteRfqMessage(bytes) ==
    LET longMessageHeader == DecodeLongMessageHeader7(bytes) IN IF ~longMessageHeader.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(longMessageHeader.rest, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET futureProduct == DecodeFutureProduct2(exchangeId.rest) IN IF ~futureProduct.ok THEN Fail ELSE
    LET requestedSize == ReadBytes(futureProduct.rest, 8) IN IF ~requestedSize.ok THEN Fail ELSE
    LET requestedMarketSide == ReadBytes(requestedSize.rest, 1) IN IF ~requestedMarketSide.ok THEN Fail ELSE
    Ok([ longMessageHeader   |-> longMessageHeader.value,
         exchangeId          |-> exchangeId.value,
         futureProduct       |-> futureProduct.value,
         requestedSize       |-> requestedSize.value,
         requestedMarketSide |-> requestedMarketSide.value ], requestedMarketSide.rest)

ZeroFuturesRequestForQuoteRfqMessage ==
    [ longMessageHeader   |-> ZeroLongMessageHeader7,
      exchangeId          |-> [i \in 1 .. 1 |-> 0],
      futureProduct       |-> ZeroFutureProduct2,
      requestedSize       |-> [i \in 1 .. 8 |-> 0],
      requestedMarketSide |-> [i \in 1 .. 1 |-> 0] ]

(* Futures Request For Quote Rfq Message at zero, then each field in turn at the values it is checked at *)
CheckedFuturesRequestForQuoteRfqMessage ==
    { ZeroFuturesRequestForQuoteRfqMessage }
        \cup { [ZeroFuturesRequestForQuoteRfqMessage EXCEPT !.longMessageHeader = one] : one \in CheckedLongMessageHeader7 }
        \cup { [ZeroFuturesRequestForQuoteRfqMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroFuturesRequestForQuoteRfqMessage EXCEPT !.futureProduct = one] : one \in CheckedFutureProduct2 }
        \cup { [ZeroFuturesRequestForQuoteRfqMessage EXCEPT !.requestedSize = one] : one \in Sample(8) }
        \cup { [ZeroFuturesRequestForQuoteRfqMessage EXCEPT !.requestedMarketSide = one] : one \in Sample(1) }

(***************************************************************************)
(* Long Message Header: 12 bytes                                           *)
(***************************************************************************)

LongMessageHeader8 ==
    [ messageTimestamp : Sample(12) ]

EncodeLongMessageHeader8(message) ==
    message.messageTimestamp

DecodeLongMessageHeader8(bytes) ==
    LET messageTimestamp == ReadBytes(bytes, 12) IN IF ~messageTimestamp.ok THEN Fail ELSE
    Ok([ messageTimestamp |-> messageTimestamp.value ], messageTimestamp.rest)

ZeroLongMessageHeader8 ==
    [ messageTimestamp |-> [i \in 1 .. 12 |-> 0] ]

(* Long Message Header at zero, then each field in turn at the values it is checked at *)
CheckedLongMessageHeader8 ==
    { ZeroLongMessageHeader8 }
        \cup { [ZeroLongMessageHeader8 EXCEPT !.messageTimestamp = one] : one \in Sample(12) }

(***************************************************************************)
(* Strategy Request For Quote Rfq Message: 52 bytes                        *)
(***************************************************************************)

StrategyRequestForQuoteRfqMessage ==
    [ longMessageHeader   : LongMessageHeader8,
      exchangeId          : Sample(1),
      symbol              : Sample(30),
      requestedSize       : Sample(8),
      requestedMarketSide : Sample(1) ]

EncodeStrategyRequestForQuoteRfqMessage(message) ==
    EncodeLongMessageHeader8(message.longMessageHeader)
        \o message.exchangeId
        \o message.symbol
        \o message.requestedSize
        \o message.requestedMarketSide

DecodeStrategyRequestForQuoteRfqMessage(bytes) ==
    LET longMessageHeader == DecodeLongMessageHeader8(bytes) IN IF ~longMessageHeader.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(longMessageHeader.rest, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET symbol == ReadBytes(exchangeId.rest, 30) IN IF ~symbol.ok THEN Fail ELSE
    LET requestedSize == ReadBytes(symbol.rest, 8) IN IF ~requestedSize.ok THEN Fail ELSE
    LET requestedMarketSide == ReadBytes(requestedSize.rest, 1) IN IF ~requestedMarketSide.ok THEN Fail ELSE
    Ok([ longMessageHeader   |-> longMessageHeader.value,
         exchangeId          |-> exchangeId.value,
         symbol              |-> symbol.value,
         requestedSize       |-> requestedSize.value,
         requestedMarketSide |-> requestedMarketSide.value ], requestedMarketSide.rest)

ZeroStrategyRequestForQuoteRfqMessage ==
    [ longMessageHeader   |-> ZeroLongMessageHeader8,
      exchangeId          |-> [i \in 1 .. 1 |-> 0],
      symbol              |-> [i \in 1 .. 30 |-> 0],
      requestedSize       |-> [i \in 1 .. 8 |-> 0],
      requestedMarketSide |-> [i \in 1 .. 1 |-> 0] ]

(* Strategy Request For Quote Rfq Message at zero, then each field in turn at the values it is checked at *)
CheckedStrategyRequestForQuoteRfqMessage ==
    { ZeroStrategyRequestForQuoteRfqMessage }
        \cup { [ZeroStrategyRequestForQuoteRfqMessage EXCEPT !.longMessageHeader = one] : one \in CheckedLongMessageHeader8 }
        \cup { [ZeroStrategyRequestForQuoteRfqMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroStrategyRequestForQuoteRfqMessage EXCEPT !.symbol = one] : one \in Sample(30) }
        \cup { [ZeroStrategyRequestForQuoteRfqMessage EXCEPT !.requestedSize = one] : one \in Sample(8) }
        \cup { [ZeroStrategyRequestForQuoteRfqMessage EXCEPT !.requestedMarketSide = one] : one \in Sample(1) }

(***************************************************************************)
(* Long Message Header: 12 bytes                                           *)
(***************************************************************************)

LongMessageHeader9 ==
    [ messageTimestamp : Sample(12) ]

EncodeLongMessageHeader9(message) ==
    message.messageTimestamp

DecodeLongMessageHeader9(bytes) ==
    LET messageTimestamp == ReadBytes(bytes, 12) IN IF ~messageTimestamp.ok THEN Fail ELSE
    Ok([ messageTimestamp |-> messageTimestamp.value ], messageTimestamp.rest)

ZeroLongMessageHeader9 ==
    [ messageTimestamp |-> [i \in 1 .. 12 |-> 0] ]

(* Long Message Header at zero, then each field in turn at the values it is checked at *)
CheckedLongMessageHeader9 ==
    { ZeroLongMessageHeader9 }
        \cup { [ZeroLongMessageHeader9 EXCEPT !.messageTimestamp = one] : one \in Sample(12) }

(***************************************************************************)
(* Option Symbol: 20 bytes                                                 *)
(***************************************************************************)

OptionSymbol3 ==
    [ root                         : Sample(6),
      expiryMonth                  : Sample(1),
      filler1                      : Sample(1),
      strikePrice                  : Sample(7),
      strikePriceFractionIndicator : Sample(1),
      expiryYear                   : Sample(2),
      expiryDay                    : Sample(2) ]

EncodeOptionSymbol3(message) ==
    message.root
        \o message.expiryMonth
        \o message.filler1
        \o message.strikePrice
        \o message.strikePriceFractionIndicator
        \o message.expiryYear
        \o message.expiryDay

DecodeOptionSymbol3(bytes) ==
    LET root == ReadBytes(bytes, 6) IN IF ~root.ok THEN Fail ELSE
    LET expiryMonth == ReadBytes(root.rest, 1) IN IF ~expiryMonth.ok THEN Fail ELSE
    LET filler1 == ReadBytes(expiryMonth.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(filler1.rest, 7) IN IF ~strikePrice.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePrice.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(strikePriceFractionIndicator.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ root                         |-> root.value,
         expiryMonth                  |-> expiryMonth.value,
         filler1                      |-> filler1.value,
         strikePrice                  |-> strikePrice.value,
         strikePriceFractionIndicator |-> strikePriceFractionIndicator.value,
         expiryYear                   |-> expiryYear.value,
         expiryDay                    |-> expiryDay.value ], expiryDay.rest)

ZeroOptionSymbol3 ==
    [ root                         |-> [i \in 1 .. 6 |-> 0],
      expiryMonth                  |-> [i \in 1 .. 1 |-> 0],
      filler1                      |-> [i \in 1 .. 1 |-> 0],
      strikePrice                  |-> [i \in 1 .. 7 |-> 0],
      strikePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      expiryYear                   |-> [i \in 1 .. 2 |-> 0],
      expiryDay                    |-> [i \in 1 .. 2 |-> 0] ]

(* Option Symbol at zero, then each field in turn at the values it is checked at *)
CheckedOptionSymbol3 ==
    { ZeroOptionSymbol3 }
        \cup { [ZeroOptionSymbol3 EXCEPT !.root = one] : one \in Sample(6) }
        \cup { [ZeroOptionSymbol3 EXCEPT !.expiryMonth = one] : one \in Sample(1) }
        \cup { [ZeroOptionSymbol3 EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroOptionSymbol3 EXCEPT !.strikePrice = one] : one \in Sample(7) }
        \cup { [ZeroOptionSymbol3 EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionSymbol3 EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroOptionSymbol3 EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Instrument Schedule Notice Option Message: 40 bytes                     *)
(***************************************************************************)

InstrumentScheduleNoticeOptionMessage ==
    [ longMessageHeader         : LongMessageHeader9,
      exchangeId                : Sample(1),
      optionSymbol              : OptionSymbol3,
      seriesStatus              : Sample(1),
      scheduledStatusChangeTime : Sample(6) ]

EncodeInstrumentScheduleNoticeOptionMessage(message) ==
    EncodeLongMessageHeader9(message.longMessageHeader)
        \o message.exchangeId
        \o EncodeOptionSymbol3(message.optionSymbol)
        \o message.seriesStatus
        \o message.scheduledStatusChangeTime

DecodeInstrumentScheduleNoticeOptionMessage(bytes) ==
    LET longMessageHeader == DecodeLongMessageHeader9(bytes) IN IF ~longMessageHeader.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(longMessageHeader.rest, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET optionSymbol == DecodeOptionSymbol3(exchangeId.rest) IN IF ~optionSymbol.ok THEN Fail ELSE
    LET seriesStatus == ReadBytes(optionSymbol.rest, 1) IN IF ~seriesStatus.ok THEN Fail ELSE
    LET scheduledStatusChangeTime == ReadBytes(seriesStatus.rest, 6) IN IF ~scheduledStatusChangeTime.ok THEN Fail ELSE
    Ok([ longMessageHeader         |-> longMessageHeader.value,
         exchangeId                |-> exchangeId.value,
         optionSymbol              |-> optionSymbol.value,
         seriesStatus              |-> seriesStatus.value,
         scheduledStatusChangeTime |-> scheduledStatusChangeTime.value ], scheduledStatusChangeTime.rest)

ZeroInstrumentScheduleNoticeOptionMessage ==
    [ longMessageHeader         |-> ZeroLongMessageHeader9,
      exchangeId                |-> [i \in 1 .. 1 |-> 0],
      optionSymbol              |-> ZeroOptionSymbol3,
      seriesStatus              |-> [i \in 1 .. 1 |-> 0],
      scheduledStatusChangeTime |-> [i \in 1 .. 6 |-> 0] ]

(* Instrument Schedule Notice Option Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentScheduleNoticeOptionMessage ==
    { ZeroInstrumentScheduleNoticeOptionMessage }
        \cup { [ZeroInstrumentScheduleNoticeOptionMessage EXCEPT !.longMessageHeader = one] : one \in CheckedLongMessageHeader9 }
        \cup { [ZeroInstrumentScheduleNoticeOptionMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentScheduleNoticeOptionMessage EXCEPT !.optionSymbol = one] : one \in CheckedOptionSymbol3 }
        \cup { [ZeroInstrumentScheduleNoticeOptionMessage EXCEPT !.seriesStatus = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentScheduleNoticeOptionMessage EXCEPT !.scheduledStatusChangeTime = one] : one \in Sample(6) }

(***************************************************************************)
(* Long Message Header: 12 bytes                                           *)
(***************************************************************************)

LongMessageHeader10 ==
    [ messageTimestamp : Sample(12) ]

EncodeLongMessageHeader10(message) ==
    message.messageTimestamp

DecodeLongMessageHeader10(bytes) ==
    LET messageTimestamp == ReadBytes(bytes, 12) IN IF ~messageTimestamp.ok THEN Fail ELSE
    Ok([ messageTimestamp |-> messageTimestamp.value ], messageTimestamp.rest)

ZeroLongMessageHeader10 ==
    [ messageTimestamp |-> [i \in 1 .. 12 |-> 0] ]

(* Long Message Header at zero, then each field in turn at the values it is checked at *)
CheckedLongMessageHeader10 ==
    { ZeroLongMessageHeader10 }
        \cup { [ZeroLongMessageHeader10 EXCEPT !.messageTimestamp = one] : one \in Sample(12) }

(***************************************************************************)
(* Future Option Symbol: 20 bytes                                          *)
(***************************************************************************)

FutureOptionSymbol3 ==
    [ root                         : Sample(6),
      symbolMonth                  : Sample(1),
      symbolYear                   : Sample(2),
      expiryDay                    : Sample(2),
      callPutCode                  : Sample(1),
      strikePrice                  : Sample(7),
      strikePriceFractionIndicator : Sample(1) ]

EncodeFutureOptionSymbol3(message) ==
    message.root
        \o message.symbolMonth
        \o message.symbolYear
        \o message.expiryDay
        \o message.callPutCode
        \o message.strikePrice
        \o message.strikePriceFractionIndicator

DecodeFutureOptionSymbol3(bytes) ==
    LET root == ReadBytes(bytes, 6) IN IF ~root.ok THEN Fail ELSE
    LET symbolMonth == ReadBytes(root.rest, 1) IN IF ~symbolMonth.ok THEN Fail ELSE
    LET symbolYear == ReadBytes(symbolMonth.rest, 2) IN IF ~symbolYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(symbolYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET callPutCode == ReadBytes(expiryDay.rest, 1) IN IF ~callPutCode.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(callPutCode.rest, 7) IN IF ~strikePrice.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePrice.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    Ok([ root                         |-> root.value,
         symbolMonth                  |-> symbolMonth.value,
         symbolYear                   |-> symbolYear.value,
         expiryDay                    |-> expiryDay.value,
         callPutCode                  |-> callPutCode.value,
         strikePrice                  |-> strikePrice.value,
         strikePriceFractionIndicator |-> strikePriceFractionIndicator.value ], strikePriceFractionIndicator.rest)

ZeroFutureOptionSymbol3 ==
    [ root                         |-> [i \in 1 .. 6 |-> 0],
      symbolMonth                  |-> [i \in 1 .. 1 |-> 0],
      symbolYear                   |-> [i \in 1 .. 2 |-> 0],
      expiryDay                    |-> [i \in 1 .. 2 |-> 0],
      callPutCode                  |-> [i \in 1 .. 1 |-> 0],
      strikePrice                  |-> [i \in 1 .. 7 |-> 0],
      strikePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Future Option Symbol at zero, then each field in turn at the values it is checked at *)
CheckedFutureOptionSymbol3 ==
    { ZeroFutureOptionSymbol3 }
        \cup { [ZeroFutureOptionSymbol3 EXCEPT !.root = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionSymbol3 EXCEPT !.symbolMonth = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionSymbol3 EXCEPT !.symbolYear = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionSymbol3 EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionSymbol3 EXCEPT !.callPutCode = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionSymbol3 EXCEPT !.strikePrice = one] : one \in Sample(7) }
        \cup { [ZeroFutureOptionSymbol3 EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Instrument Schedule Notice Futures Option Message: 40 bytes             *)
(***************************************************************************)

InstrumentScheduleNoticeFuturesOptionMessage ==
    [ longMessageHeader         : LongMessageHeader10,
      exchangeId                : Sample(1),
      futureOptionSymbol        : FutureOptionSymbol3,
      seriesStatus              : Sample(1),
      scheduledStatusChangeTime : Sample(6) ]

EncodeInstrumentScheduleNoticeFuturesOptionMessage(message) ==
    EncodeLongMessageHeader10(message.longMessageHeader)
        \o message.exchangeId
        \o EncodeFutureOptionSymbol3(message.futureOptionSymbol)
        \o message.seriesStatus
        \o message.scheduledStatusChangeTime

DecodeInstrumentScheduleNoticeFuturesOptionMessage(bytes) ==
    LET longMessageHeader == DecodeLongMessageHeader10(bytes) IN IF ~longMessageHeader.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(longMessageHeader.rest, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET futureOptionSymbol == DecodeFutureOptionSymbol3(exchangeId.rest) IN IF ~futureOptionSymbol.ok THEN Fail ELSE
    LET seriesStatus == ReadBytes(futureOptionSymbol.rest, 1) IN IF ~seriesStatus.ok THEN Fail ELSE
    LET scheduledStatusChangeTime == ReadBytes(seriesStatus.rest, 6) IN IF ~scheduledStatusChangeTime.ok THEN Fail ELSE
    Ok([ longMessageHeader         |-> longMessageHeader.value,
         exchangeId                |-> exchangeId.value,
         futureOptionSymbol        |-> futureOptionSymbol.value,
         seriesStatus              |-> seriesStatus.value,
         scheduledStatusChangeTime |-> scheduledStatusChangeTime.value ], scheduledStatusChangeTime.rest)

ZeroInstrumentScheduleNoticeFuturesOptionMessage ==
    [ longMessageHeader         |-> ZeroLongMessageHeader10,
      exchangeId                |-> [i \in 1 .. 1 |-> 0],
      futureOptionSymbol        |-> ZeroFutureOptionSymbol3,
      seriesStatus              |-> [i \in 1 .. 1 |-> 0],
      scheduledStatusChangeTime |-> [i \in 1 .. 6 |-> 0] ]

(* Instrument Schedule Notice Futures Option Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentScheduleNoticeFuturesOptionMessage ==
    { ZeroInstrumentScheduleNoticeFuturesOptionMessage }
        \cup { [ZeroInstrumentScheduleNoticeFuturesOptionMessage EXCEPT !.longMessageHeader = one] : one \in CheckedLongMessageHeader10 }
        \cup { [ZeroInstrumentScheduleNoticeFuturesOptionMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentScheduleNoticeFuturesOptionMessage EXCEPT !.futureOptionSymbol = one] : one \in CheckedFutureOptionSymbol3 }
        \cup { [ZeroInstrumentScheduleNoticeFuturesOptionMessage EXCEPT !.seriesStatus = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentScheduleNoticeFuturesOptionMessage EXCEPT !.scheduledStatusChangeTime = one] : one \in Sample(6) }

(***************************************************************************)
(* Long Message Header: 12 bytes                                           *)
(***************************************************************************)

LongMessageHeader11 ==
    [ messageTimestamp : Sample(12) ]

EncodeLongMessageHeader11(message) ==
    message.messageTimestamp

DecodeLongMessageHeader11(bytes) ==
    LET messageTimestamp == ReadBytes(bytes, 12) IN IF ~messageTimestamp.ok THEN Fail ELSE
    Ok([ messageTimestamp |-> messageTimestamp.value ], messageTimestamp.rest)

ZeroLongMessageHeader11 ==
    [ messageTimestamp |-> [i \in 1 .. 12 |-> 0] ]

(* Long Message Header at zero, then each field in turn at the values it is checked at *)
CheckedLongMessageHeader11 ==
    { ZeroLongMessageHeader11 }
        \cup { [ZeroLongMessageHeader11 EXCEPT !.messageTimestamp = one] : one \in Sample(12) }

(***************************************************************************)
(* Future Product: 11 bytes                                                *)
(***************************************************************************)

FutureProduct3 ==
    [ root        : Sample(6),
      symbolMonth : Sample(1),
      symbolYear  : Sample(2),
      expiryDay   : Sample(2) ]

EncodeFutureProduct3(message) ==
    message.root
        \o message.symbolMonth
        \o message.symbolYear
        \o message.expiryDay

DecodeFutureProduct3(bytes) ==
    LET root == ReadBytes(bytes, 6) IN IF ~root.ok THEN Fail ELSE
    LET symbolMonth == ReadBytes(root.rest, 1) IN IF ~symbolMonth.ok THEN Fail ELSE
    LET symbolYear == ReadBytes(symbolMonth.rest, 2) IN IF ~symbolYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(symbolYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ root        |-> root.value,
         symbolMonth |-> symbolMonth.value,
         symbolYear  |-> symbolYear.value,
         expiryDay   |-> expiryDay.value ], expiryDay.rest)

ZeroFutureProduct3 ==
    [ root        |-> [i \in 1 .. 6 |-> 0],
      symbolMonth |-> [i \in 1 .. 1 |-> 0],
      symbolYear  |-> [i \in 1 .. 2 |-> 0],
      expiryDay   |-> [i \in 1 .. 2 |-> 0] ]

(* Future Product at zero, then each field in turn at the values it is checked at *)
CheckedFutureProduct3 ==
    { ZeroFutureProduct3 }
        \cup { [ZeroFutureProduct3 EXCEPT !.root = one] : one \in Sample(6) }
        \cup { [ZeroFutureProduct3 EXCEPT !.symbolMonth = one] : one \in Sample(1) }
        \cup { [ZeroFutureProduct3 EXCEPT !.symbolYear = one] : one \in Sample(2) }
        \cup { [ZeroFutureProduct3 EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Instrument Schedule Notice Future Message: 31 bytes                     *)
(***************************************************************************)

InstrumentScheduleNoticeFutureMessage ==
    [ longMessageHeader         : LongMessageHeader11,
      exchangeId                : Sample(1),
      futureProduct             : FutureProduct3,
      seriesStatus              : Sample(1),
      scheduledStatusChangeTime : Sample(6) ]

EncodeInstrumentScheduleNoticeFutureMessage(message) ==
    EncodeLongMessageHeader11(message.longMessageHeader)
        \o message.exchangeId
        \o EncodeFutureProduct3(message.futureProduct)
        \o message.seriesStatus
        \o message.scheduledStatusChangeTime

DecodeInstrumentScheduleNoticeFutureMessage(bytes) ==
    LET longMessageHeader == DecodeLongMessageHeader11(bytes) IN IF ~longMessageHeader.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(longMessageHeader.rest, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET futureProduct == DecodeFutureProduct3(exchangeId.rest) IN IF ~futureProduct.ok THEN Fail ELSE
    LET seriesStatus == ReadBytes(futureProduct.rest, 1) IN IF ~seriesStatus.ok THEN Fail ELSE
    LET scheduledStatusChangeTime == ReadBytes(seriesStatus.rest, 6) IN IF ~scheduledStatusChangeTime.ok THEN Fail ELSE
    Ok([ longMessageHeader         |-> longMessageHeader.value,
         exchangeId                |-> exchangeId.value,
         futureProduct             |-> futureProduct.value,
         seriesStatus              |-> seriesStatus.value,
         scheduledStatusChangeTime |-> scheduledStatusChangeTime.value ], scheduledStatusChangeTime.rest)

ZeroInstrumentScheduleNoticeFutureMessage ==
    [ longMessageHeader         |-> ZeroLongMessageHeader11,
      exchangeId                |-> [i \in 1 .. 1 |-> 0],
      futureProduct             |-> ZeroFutureProduct3,
      seriesStatus              |-> [i \in 1 .. 1 |-> 0],
      scheduledStatusChangeTime |-> [i \in 1 .. 6 |-> 0] ]

(* Instrument Schedule Notice Future Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentScheduleNoticeFutureMessage ==
    { ZeroInstrumentScheduleNoticeFutureMessage }
        \cup { [ZeroInstrumentScheduleNoticeFutureMessage EXCEPT !.longMessageHeader = one] : one \in CheckedLongMessageHeader11 }
        \cup { [ZeroInstrumentScheduleNoticeFutureMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentScheduleNoticeFutureMessage EXCEPT !.futureProduct = one] : one \in CheckedFutureProduct3 }
        \cup { [ZeroInstrumentScheduleNoticeFutureMessage EXCEPT !.seriesStatus = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentScheduleNoticeFutureMessage EXCEPT !.scheduledStatusChangeTime = one] : one \in Sample(6) }

(***************************************************************************)
(* Long Message Header: 12 bytes                                           *)
(***************************************************************************)

LongMessageHeader12 ==
    [ messageTimestamp : Sample(12) ]

EncodeLongMessageHeader12(message) ==
    message.messageTimestamp

DecodeLongMessageHeader12(bytes) ==
    LET messageTimestamp == ReadBytes(bytes, 12) IN IF ~messageTimestamp.ok THEN Fail ELSE
    Ok([ messageTimestamp |-> messageTimestamp.value ], messageTimestamp.rest)

ZeroLongMessageHeader12 ==
    [ messageTimestamp |-> [i \in 1 .. 12 |-> 0] ]

(* Long Message Header at zero, then each field in turn at the values it is checked at *)
CheckedLongMessageHeader12 ==
    { ZeroLongMessageHeader12 }
        \cup { [ZeroLongMessageHeader12 EXCEPT !.messageTimestamp = one] : one \in Sample(12) }

(***************************************************************************)
(* Instrument Schedule Notice Strategy Message: 50 bytes                   *)
(***************************************************************************)

InstrumentScheduleNoticeStrategyMessage ==
    [ longMessageHeader         : LongMessageHeader12,
      exchangeId                : Sample(1),
      strategySymbol            : Sample(30),
      seriesStatus              : Sample(1),
      scheduledStatusChangeTime : Sample(6) ]

EncodeInstrumentScheduleNoticeStrategyMessage(message) ==
    EncodeLongMessageHeader12(message.longMessageHeader)
        \o message.exchangeId
        \o message.strategySymbol
        \o message.seriesStatus
        \o message.scheduledStatusChangeTime

DecodeInstrumentScheduleNoticeStrategyMessage(bytes) ==
    LET longMessageHeader == DecodeLongMessageHeader12(bytes) IN IF ~longMessageHeader.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(longMessageHeader.rest, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET strategySymbol == ReadBytes(exchangeId.rest, 30) IN IF ~strategySymbol.ok THEN Fail ELSE
    LET seriesStatus == ReadBytes(strategySymbol.rest, 1) IN IF ~seriesStatus.ok THEN Fail ELSE
    LET scheduledStatusChangeTime == ReadBytes(seriesStatus.rest, 6) IN IF ~scheduledStatusChangeTime.ok THEN Fail ELSE
    Ok([ longMessageHeader         |-> longMessageHeader.value,
         exchangeId                |-> exchangeId.value,
         strategySymbol            |-> strategySymbol.value,
         seriesStatus              |-> seriesStatus.value,
         scheduledStatusChangeTime |-> scheduledStatusChangeTime.value ], scheduledStatusChangeTime.rest)

ZeroInstrumentScheduleNoticeStrategyMessage ==
    [ longMessageHeader         |-> ZeroLongMessageHeader12,
      exchangeId                |-> [i \in 1 .. 1 |-> 0],
      strategySymbol            |-> [i \in 1 .. 30 |-> 0],
      seriesStatus              |-> [i \in 1 .. 1 |-> 0],
      scheduledStatusChangeTime |-> [i \in 1 .. 6 |-> 0] ]

(* Instrument Schedule Notice Strategy Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentScheduleNoticeStrategyMessage ==
    { ZeroInstrumentScheduleNoticeStrategyMessage }
        \cup { [ZeroInstrumentScheduleNoticeStrategyMessage EXCEPT !.longMessageHeader = one] : one \in CheckedLongMessageHeader12 }
        \cup { [ZeroInstrumentScheduleNoticeStrategyMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentScheduleNoticeStrategyMessage EXCEPT !.strategySymbol = one] : one \in Sample(30) }
        \cup { [ZeroInstrumentScheduleNoticeStrategyMessage EXCEPT !.seriesStatus = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentScheduleNoticeStrategyMessage EXCEPT !.scheduledStatusChangeTime = one] : one \in Sample(6) }

(***************************************************************************)
(* Long Message Header: 12 bytes                                           *)
(***************************************************************************)

LongMessageHeader13 ==
    [ messageTimestamp : Sample(12) ]

EncodeLongMessageHeader13(message) ==
    message.messageTimestamp

DecodeLongMessageHeader13(bytes) ==
    LET messageTimestamp == ReadBytes(bytes, 12) IN IF ~messageTimestamp.ok THEN Fail ELSE
    Ok([ messageTimestamp |-> messageTimestamp.value ], messageTimestamp.rest)

ZeroLongMessageHeader13 ==
    [ messageTimestamp |-> [i \in 1 .. 12 |-> 0] ]

(* Long Message Header at zero, then each field in turn at the values it is checked at *)
CheckedLongMessageHeader13 ==
    { ZeroLongMessageHeader13 }
        \cup { [ZeroLongMessageHeader13 EXCEPT !.messageTimestamp = one] : one \in Sample(12) }

(***************************************************************************)
(* Option Symbol: 20 bytes                                                 *)
(***************************************************************************)

OptionSymbol4 ==
    [ root                         : Sample(6),
      expiryMonth                  : Sample(1),
      filler1                      : Sample(1),
      strikePrice                  : Sample(7),
      strikePriceFractionIndicator : Sample(1),
      expiryYear                   : Sample(2),
      expiryDay                    : Sample(2) ]

EncodeOptionSymbol4(message) ==
    message.root
        \o message.expiryMonth
        \o message.filler1
        \o message.strikePrice
        \o message.strikePriceFractionIndicator
        \o message.expiryYear
        \o message.expiryDay

DecodeOptionSymbol4(bytes) ==
    LET root == ReadBytes(bytes, 6) IN IF ~root.ok THEN Fail ELSE
    LET expiryMonth == ReadBytes(root.rest, 1) IN IF ~expiryMonth.ok THEN Fail ELSE
    LET filler1 == ReadBytes(expiryMonth.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(filler1.rest, 7) IN IF ~strikePrice.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePrice.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(strikePriceFractionIndicator.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ root                         |-> root.value,
         expiryMonth                  |-> expiryMonth.value,
         filler1                      |-> filler1.value,
         strikePrice                  |-> strikePrice.value,
         strikePriceFractionIndicator |-> strikePriceFractionIndicator.value,
         expiryYear                   |-> expiryYear.value,
         expiryDay                    |-> expiryDay.value ], expiryDay.rest)

ZeroOptionSymbol4 ==
    [ root                         |-> [i \in 1 .. 6 |-> 0],
      expiryMonth                  |-> [i \in 1 .. 1 |-> 0],
      filler1                      |-> [i \in 1 .. 1 |-> 0],
      strikePrice                  |-> [i \in 1 .. 7 |-> 0],
      strikePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      expiryYear                   |-> [i \in 1 .. 2 |-> 0],
      expiryDay                    |-> [i \in 1 .. 2 |-> 0] ]

(* Option Symbol at zero, then each field in turn at the values it is checked at *)
CheckedOptionSymbol4 ==
    { ZeroOptionSymbol4 }
        \cup { [ZeroOptionSymbol4 EXCEPT !.root = one] : one \in Sample(6) }
        \cup { [ZeroOptionSymbol4 EXCEPT !.expiryMonth = one] : one \in Sample(1) }
        \cup { [ZeroOptionSymbol4 EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroOptionSymbol4 EXCEPT !.strikePrice = one] : one \in Sample(7) }
        \cup { [ZeroOptionSymbol4 EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionSymbol4 EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroOptionSymbol4 EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Option Quote Message: 61 bytes                                          *)
(***************************************************************************)

OptionQuoteMessage ==
    [ longMessageHeader         : LongMessageHeader13,
      exchangeId                : Sample(1),
      optionSymbol              : OptionSymbol4,
      bidPriceQuote             : Sample(7),
      bidPriceFractionIndicator : Sample(1),
      bidSize                   : Sample(5),
      askPriceQuote             : Sample(7),
      askPriceFractionIndicator : Sample(1),
      askSize                   : Sample(5),
      filler1                   : Sample(1),
      instrumentStatusMarker    : Sample(1) ]

EncodeOptionQuoteMessage(message) ==
    EncodeLongMessageHeader13(message.longMessageHeader)
        \o message.exchangeId
        \o EncodeOptionSymbol4(message.optionSymbol)
        \o message.bidPriceQuote
        \o message.bidPriceFractionIndicator
        \o message.bidSize
        \o message.askPriceQuote
        \o message.askPriceFractionIndicator
        \o message.askSize
        \o message.filler1
        \o message.instrumentStatusMarker

DecodeOptionQuoteMessage(bytes) ==
    LET longMessageHeader == DecodeLongMessageHeader13(bytes) IN IF ~longMessageHeader.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(longMessageHeader.rest, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET optionSymbol == DecodeOptionSymbol4(exchangeId.rest) IN IF ~optionSymbol.ok THEN Fail ELSE
    LET bidPriceQuote == ReadBytes(optionSymbol.rest, 7) IN IF ~bidPriceQuote.ok THEN Fail ELSE
    LET bidPriceFractionIndicator == ReadBytes(bidPriceQuote.rest, 1) IN IF ~bidPriceFractionIndicator.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPriceFractionIndicator.rest, 5) IN IF ~bidSize.ok THEN Fail ELSE
    LET askPriceQuote == ReadBytes(bidSize.rest, 7) IN IF ~askPriceQuote.ok THEN Fail ELSE
    LET askPriceFractionIndicator == ReadBytes(askPriceQuote.rest, 1) IN IF ~askPriceFractionIndicator.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPriceFractionIndicator.rest, 5) IN IF ~askSize.ok THEN Fail ELSE
    LET filler1 == ReadBytes(askSize.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET instrumentStatusMarker == ReadBytes(filler1.rest, 1) IN IF ~instrumentStatusMarker.ok THEN Fail ELSE
    Ok([ longMessageHeader         |-> longMessageHeader.value,
         exchangeId                |-> exchangeId.value,
         optionSymbol              |-> optionSymbol.value,
         bidPriceQuote             |-> bidPriceQuote.value,
         bidPriceFractionIndicator |-> bidPriceFractionIndicator.value,
         bidSize                   |-> bidSize.value,
         askPriceQuote             |-> askPriceQuote.value,
         askPriceFractionIndicator |-> askPriceFractionIndicator.value,
         askSize                   |-> askSize.value,
         filler1                   |-> filler1.value,
         instrumentStatusMarker    |-> instrumentStatusMarker.value ], instrumentStatusMarker.rest)

ZeroOptionQuoteMessage ==
    [ longMessageHeader         |-> ZeroLongMessageHeader13,
      exchangeId                |-> [i \in 1 .. 1 |-> 0],
      optionSymbol              |-> ZeroOptionSymbol4,
      bidPriceQuote             |-> [i \in 1 .. 7 |-> 0],
      bidPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      bidSize                   |-> [i \in 1 .. 5 |-> 0],
      askPriceQuote             |-> [i \in 1 .. 7 |-> 0],
      askPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      askSize                   |-> [i \in 1 .. 5 |-> 0],
      filler1                   |-> [i \in 1 .. 1 |-> 0],
      instrumentStatusMarker    |-> [i \in 1 .. 1 |-> 0] ]

(* Option Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionQuoteMessage ==
    { ZeroOptionQuoteMessage }
        \cup { [ZeroOptionQuoteMessage EXCEPT !.longMessageHeader = one] : one \in CheckedLongMessageHeader13 }
        \cup { [ZeroOptionQuoteMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroOptionQuoteMessage EXCEPT !.optionSymbol = one] : one \in CheckedOptionSymbol4 }
        \cup { [ZeroOptionQuoteMessage EXCEPT !.bidPriceQuote = one] : one \in Sample(7) }
        \cup { [ZeroOptionQuoteMessage EXCEPT !.bidPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionQuoteMessage EXCEPT !.bidSize = one] : one \in Sample(5) }
        \cup { [ZeroOptionQuoteMessage EXCEPT !.askPriceQuote = one] : one \in Sample(7) }
        \cup { [ZeroOptionQuoteMessage EXCEPT !.askPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionQuoteMessage EXCEPT !.askSize = one] : one \in Sample(5) }
        \cup { [ZeroOptionQuoteMessage EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroOptionQuoteMessage EXCEPT !.instrumentStatusMarker = one] : one \in Sample(1) }

(***************************************************************************)
(* Long Message Header: 12 bytes                                           *)
(***************************************************************************)

LongMessageHeader14 ==
    [ messageTimestamp : Sample(12) ]

EncodeLongMessageHeader14(message) ==
    message.messageTimestamp

DecodeLongMessageHeader14(bytes) ==
    LET messageTimestamp == ReadBytes(bytes, 12) IN IF ~messageTimestamp.ok THEN Fail ELSE
    Ok([ messageTimestamp |-> messageTimestamp.value ], messageTimestamp.rest)

ZeroLongMessageHeader14 ==
    [ messageTimestamp |-> [i \in 1 .. 12 |-> 0] ]

(* Long Message Header at zero, then each field in turn at the values it is checked at *)
CheckedLongMessageHeader14 ==
    { ZeroLongMessageHeader14 }
        \cup { [ZeroLongMessageHeader14 EXCEPT !.messageTimestamp = one] : one \in Sample(12) }

(***************************************************************************)
(* Future Option Symbol: 20 bytes                                          *)
(***************************************************************************)

FutureOptionSymbol4 ==
    [ root                         : Sample(6),
      symbolMonth                  : Sample(1),
      symbolYear                   : Sample(2),
      expiryDay                    : Sample(2),
      callPutCode                  : Sample(1),
      strikePrice                  : Sample(7),
      strikePriceFractionIndicator : Sample(1) ]

EncodeFutureOptionSymbol4(message) ==
    message.root
        \o message.symbolMonth
        \o message.symbolYear
        \o message.expiryDay
        \o message.callPutCode
        \o message.strikePrice
        \o message.strikePriceFractionIndicator

DecodeFutureOptionSymbol4(bytes) ==
    LET root == ReadBytes(bytes, 6) IN IF ~root.ok THEN Fail ELSE
    LET symbolMonth == ReadBytes(root.rest, 1) IN IF ~symbolMonth.ok THEN Fail ELSE
    LET symbolYear == ReadBytes(symbolMonth.rest, 2) IN IF ~symbolYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(symbolYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET callPutCode == ReadBytes(expiryDay.rest, 1) IN IF ~callPutCode.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(callPutCode.rest, 7) IN IF ~strikePrice.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePrice.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    Ok([ root                         |-> root.value,
         symbolMonth                  |-> symbolMonth.value,
         symbolYear                   |-> symbolYear.value,
         expiryDay                    |-> expiryDay.value,
         callPutCode                  |-> callPutCode.value,
         strikePrice                  |-> strikePrice.value,
         strikePriceFractionIndicator |-> strikePriceFractionIndicator.value ], strikePriceFractionIndicator.rest)

ZeroFutureOptionSymbol4 ==
    [ root                         |-> [i \in 1 .. 6 |-> 0],
      symbolMonth                  |-> [i \in 1 .. 1 |-> 0],
      symbolYear                   |-> [i \in 1 .. 2 |-> 0],
      expiryDay                    |-> [i \in 1 .. 2 |-> 0],
      callPutCode                  |-> [i \in 1 .. 1 |-> 0],
      strikePrice                  |-> [i \in 1 .. 7 |-> 0],
      strikePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Future Option Symbol at zero, then each field in turn at the values it is checked at *)
CheckedFutureOptionSymbol4 ==
    { ZeroFutureOptionSymbol4 }
        \cup { [ZeroFutureOptionSymbol4 EXCEPT !.root = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionSymbol4 EXCEPT !.symbolMonth = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionSymbol4 EXCEPT !.symbolYear = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionSymbol4 EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionSymbol4 EXCEPT !.callPutCode = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionSymbol4 EXCEPT !.strikePrice = one] : one \in Sample(7) }
        \cup { [ZeroFutureOptionSymbol4 EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Future Options Quote Message: 61 bytes                                  *)
(***************************************************************************)

FutureOptionsQuoteMessage ==
    [ longMessageHeader         : LongMessageHeader14,
      exchangeId                : Sample(1),
      futureOptionSymbol        : FutureOptionSymbol4,
      bidPriceQuote             : Sample(7),
      bidPriceFractionIndicator : Sample(1),
      bidSize                   : Sample(5),
      askPriceQuote             : Sample(7),
      askPriceFractionIndicator : Sample(1),
      askSize                   : Sample(5),
      instrumentStatusMarker    : Sample(1),
      filler1                   : Sample(1) ]

EncodeFutureOptionsQuoteMessage(message) ==
    EncodeLongMessageHeader14(message.longMessageHeader)
        \o message.exchangeId
        \o EncodeFutureOptionSymbol4(message.futureOptionSymbol)
        \o message.bidPriceQuote
        \o message.bidPriceFractionIndicator
        \o message.bidSize
        \o message.askPriceQuote
        \o message.askPriceFractionIndicator
        \o message.askSize
        \o message.instrumentStatusMarker
        \o message.filler1

DecodeFutureOptionsQuoteMessage(bytes) ==
    LET longMessageHeader == DecodeLongMessageHeader14(bytes) IN IF ~longMessageHeader.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(longMessageHeader.rest, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET futureOptionSymbol == DecodeFutureOptionSymbol4(exchangeId.rest) IN IF ~futureOptionSymbol.ok THEN Fail ELSE
    LET bidPriceQuote == ReadBytes(futureOptionSymbol.rest, 7) IN IF ~bidPriceQuote.ok THEN Fail ELSE
    LET bidPriceFractionIndicator == ReadBytes(bidPriceQuote.rest, 1) IN IF ~bidPriceFractionIndicator.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPriceFractionIndicator.rest, 5) IN IF ~bidSize.ok THEN Fail ELSE
    LET askPriceQuote == ReadBytes(bidSize.rest, 7) IN IF ~askPriceQuote.ok THEN Fail ELSE
    LET askPriceFractionIndicator == ReadBytes(askPriceQuote.rest, 1) IN IF ~askPriceFractionIndicator.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPriceFractionIndicator.rest, 5) IN IF ~askSize.ok THEN Fail ELSE
    LET instrumentStatusMarker == ReadBytes(askSize.rest, 1) IN IF ~instrumentStatusMarker.ok THEN Fail ELSE
    LET filler1 == ReadBytes(instrumentStatusMarker.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    Ok([ longMessageHeader         |-> longMessageHeader.value,
         exchangeId                |-> exchangeId.value,
         futureOptionSymbol        |-> futureOptionSymbol.value,
         bidPriceQuote             |-> bidPriceQuote.value,
         bidPriceFractionIndicator |-> bidPriceFractionIndicator.value,
         bidSize                   |-> bidSize.value,
         askPriceQuote             |-> askPriceQuote.value,
         askPriceFractionIndicator |-> askPriceFractionIndicator.value,
         askSize                   |-> askSize.value,
         instrumentStatusMarker    |-> instrumentStatusMarker.value,
         filler1                   |-> filler1.value ], filler1.rest)

ZeroFutureOptionsQuoteMessage ==
    [ longMessageHeader         |-> ZeroLongMessageHeader14,
      exchangeId                |-> [i \in 1 .. 1 |-> 0],
      futureOptionSymbol        |-> ZeroFutureOptionSymbol4,
      bidPriceQuote             |-> [i \in 1 .. 7 |-> 0],
      bidPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      bidSize                   |-> [i \in 1 .. 5 |-> 0],
      askPriceQuote             |-> [i \in 1 .. 7 |-> 0],
      askPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      askSize                   |-> [i \in 1 .. 5 |-> 0],
      instrumentStatusMarker    |-> [i \in 1 .. 1 |-> 0],
      filler1                   |-> [i \in 1 .. 1 |-> 0] ]

(* Future Options Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedFutureOptionsQuoteMessage ==
    { ZeroFutureOptionsQuoteMessage }
        \cup { [ZeroFutureOptionsQuoteMessage EXCEPT !.longMessageHeader = one] : one \in CheckedLongMessageHeader14 }
        \cup { [ZeroFutureOptionsQuoteMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsQuoteMessage EXCEPT !.futureOptionSymbol = one] : one \in CheckedFutureOptionSymbol4 }
        \cup { [ZeroFutureOptionsQuoteMessage EXCEPT !.bidPriceQuote = one] : one \in Sample(7) }
        \cup { [ZeroFutureOptionsQuoteMessage EXCEPT !.bidPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsQuoteMessage EXCEPT !.bidSize = one] : one \in Sample(5) }
        \cup { [ZeroFutureOptionsQuoteMessage EXCEPT !.askPriceQuote = one] : one \in Sample(7) }
        \cup { [ZeroFutureOptionsQuoteMessage EXCEPT !.askPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsQuoteMessage EXCEPT !.askSize = one] : one \in Sample(5) }
        \cup { [ZeroFutureOptionsQuoteMessage EXCEPT !.instrumentStatusMarker = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsQuoteMessage EXCEPT !.filler1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Long Message Header: 12 bytes                                           *)
(***************************************************************************)

LongMessageHeader15 ==
    [ messageTimestamp : Sample(12) ]

EncodeLongMessageHeader15(message) ==
    message.messageTimestamp

DecodeLongMessageHeader15(bytes) ==
    LET messageTimestamp == ReadBytes(bytes, 12) IN IF ~messageTimestamp.ok THEN Fail ELSE
    Ok([ messageTimestamp |-> messageTimestamp.value ], messageTimestamp.rest)

ZeroLongMessageHeader15 ==
    [ messageTimestamp |-> [i \in 1 .. 12 |-> 0] ]

(* Long Message Header at zero, then each field in turn at the values it is checked at *)
CheckedLongMessageHeader15 ==
    { ZeroLongMessageHeader15 }
        \cup { [ZeroLongMessageHeader15 EXCEPT !.messageTimestamp = one] : one \in Sample(12) }

(***************************************************************************)
(* Future Product: 11 bytes                                                *)
(***************************************************************************)

FutureProduct4 ==
    [ root        : Sample(6),
      symbolMonth : Sample(1),
      symbolYear  : Sample(2),
      expiryDay   : Sample(2) ]

EncodeFutureProduct4(message) ==
    message.root
        \o message.symbolMonth
        \o message.symbolYear
        \o message.expiryDay

DecodeFutureProduct4(bytes) ==
    LET root == ReadBytes(bytes, 6) IN IF ~root.ok THEN Fail ELSE
    LET symbolMonth == ReadBytes(root.rest, 1) IN IF ~symbolMonth.ok THEN Fail ELSE
    LET symbolYear == ReadBytes(symbolMonth.rest, 2) IN IF ~symbolYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(symbolYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ root        |-> root.value,
         symbolMonth |-> symbolMonth.value,
         symbolYear  |-> symbolYear.value,
         expiryDay   |-> expiryDay.value ], expiryDay.rest)

ZeroFutureProduct4 ==
    [ root        |-> [i \in 1 .. 6 |-> 0],
      symbolMonth |-> [i \in 1 .. 1 |-> 0],
      symbolYear  |-> [i \in 1 .. 2 |-> 0],
      expiryDay   |-> [i \in 1 .. 2 |-> 0] ]

(* Future Product at zero, then each field in turn at the values it is checked at *)
CheckedFutureProduct4 ==
    { ZeroFutureProduct4 }
        \cup { [ZeroFutureProduct4 EXCEPT !.root = one] : one \in Sample(6) }
        \cup { [ZeroFutureProduct4 EXCEPT !.symbolMonth = one] : one \in Sample(1) }
        \cup { [ZeroFutureProduct4 EXCEPT !.symbolYear = one] : one \in Sample(2) }
        \cup { [ZeroFutureProduct4 EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Futures Quote Message: 51 bytes                                         *)
(***************************************************************************)

FuturesQuoteMessage ==
    [ longMessageHeader         : LongMessageHeader15,
      exchangeId                : Sample(1),
      futureProduct             : FutureProduct4,
      bidPriceQuote             : Sample(7),
      bidPriceFractionIndicator : Sample(1),
      bidSize                   : Sample(5),
      askPriceQuote             : Sample(7),
      askPriceFractionIndicator : Sample(1),
      askSize                   : Sample(5),
      instrumentStatusMarker    : Sample(1) ]

EncodeFuturesQuoteMessage(message) ==
    EncodeLongMessageHeader15(message.longMessageHeader)
        \o message.exchangeId
        \o EncodeFutureProduct4(message.futureProduct)
        \o message.bidPriceQuote
        \o message.bidPriceFractionIndicator
        \o message.bidSize
        \o message.askPriceQuote
        \o message.askPriceFractionIndicator
        \o message.askSize
        \o message.instrumentStatusMarker

DecodeFuturesQuoteMessage(bytes) ==
    LET longMessageHeader == DecodeLongMessageHeader15(bytes) IN IF ~longMessageHeader.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(longMessageHeader.rest, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET futureProduct == DecodeFutureProduct4(exchangeId.rest) IN IF ~futureProduct.ok THEN Fail ELSE
    LET bidPriceQuote == ReadBytes(futureProduct.rest, 7) IN IF ~bidPriceQuote.ok THEN Fail ELSE
    LET bidPriceFractionIndicator == ReadBytes(bidPriceQuote.rest, 1) IN IF ~bidPriceFractionIndicator.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPriceFractionIndicator.rest, 5) IN IF ~bidSize.ok THEN Fail ELSE
    LET askPriceQuote == ReadBytes(bidSize.rest, 7) IN IF ~askPriceQuote.ok THEN Fail ELSE
    LET askPriceFractionIndicator == ReadBytes(askPriceQuote.rest, 1) IN IF ~askPriceFractionIndicator.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPriceFractionIndicator.rest, 5) IN IF ~askSize.ok THEN Fail ELSE
    LET instrumentStatusMarker == ReadBytes(askSize.rest, 1) IN IF ~instrumentStatusMarker.ok THEN Fail ELSE
    Ok([ longMessageHeader         |-> longMessageHeader.value,
         exchangeId                |-> exchangeId.value,
         futureProduct             |-> futureProduct.value,
         bidPriceQuote             |-> bidPriceQuote.value,
         bidPriceFractionIndicator |-> bidPriceFractionIndicator.value,
         bidSize                   |-> bidSize.value,
         askPriceQuote             |-> askPriceQuote.value,
         askPriceFractionIndicator |-> askPriceFractionIndicator.value,
         askSize                   |-> askSize.value,
         instrumentStatusMarker    |-> instrumentStatusMarker.value ], instrumentStatusMarker.rest)

ZeroFuturesQuoteMessage ==
    [ longMessageHeader         |-> ZeroLongMessageHeader15,
      exchangeId                |-> [i \in 1 .. 1 |-> 0],
      futureProduct             |-> ZeroFutureProduct4,
      bidPriceQuote             |-> [i \in 1 .. 7 |-> 0],
      bidPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      bidSize                   |-> [i \in 1 .. 5 |-> 0],
      askPriceQuote             |-> [i \in 1 .. 7 |-> 0],
      askPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      askSize                   |-> [i \in 1 .. 5 |-> 0],
      instrumentStatusMarker    |-> [i \in 1 .. 1 |-> 0] ]

(* Futures Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedFuturesQuoteMessage ==
    { ZeroFuturesQuoteMessage }
        \cup { [ZeroFuturesQuoteMessage EXCEPT !.longMessageHeader = one] : one \in CheckedLongMessageHeader15 }
        \cup { [ZeroFuturesQuoteMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroFuturesQuoteMessage EXCEPT !.futureProduct = one] : one \in CheckedFutureProduct4 }
        \cup { [ZeroFuturesQuoteMessage EXCEPT !.bidPriceQuote = one] : one \in Sample(7) }
        \cup { [ZeroFuturesQuoteMessage EXCEPT !.bidPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFuturesQuoteMessage EXCEPT !.bidSize = one] : one \in Sample(5) }
        \cup { [ZeroFuturesQuoteMessage EXCEPT !.askPriceQuote = one] : one \in Sample(7) }
        \cup { [ZeroFuturesQuoteMessage EXCEPT !.askPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFuturesQuoteMessage EXCEPT !.askSize = one] : one \in Sample(5) }
        \cup { [ZeroFuturesQuoteMessage EXCEPT !.instrumentStatusMarker = one] : one \in Sample(1) }

(***************************************************************************)
(* Long Message Header: 12 bytes                                           *)
(***************************************************************************)

LongMessageHeader16 ==
    [ messageTimestamp : Sample(12) ]

EncodeLongMessageHeader16(message) ==
    message.messageTimestamp

DecodeLongMessageHeader16(bytes) ==
    LET messageTimestamp == ReadBytes(bytes, 12) IN IF ~messageTimestamp.ok THEN Fail ELSE
    Ok([ messageTimestamp |-> messageTimestamp.value ], messageTimestamp.rest)

ZeroLongMessageHeader16 ==
    [ messageTimestamp |-> [i \in 1 .. 12 |-> 0] ]

(* Long Message Header at zero, then each field in turn at the values it is checked at *)
CheckedLongMessageHeader16 ==
    { ZeroLongMessageHeader16 }
        \cup { [ZeroLongMessageHeader16 EXCEPT !.messageTimestamp = one] : one \in Sample(12) }

(***************************************************************************)
(* Strategy Quote Message: 72 bytes                                        *)
(***************************************************************************)

StrategyQuoteMessage ==
    [ longMessageHeader         : LongMessageHeader16,
      exchangeId                : Sample(1),
      symbol                    : Sample(30),
      bidPriceSign              : Sample(1),
      bidPriceQuote             : Sample(7),
      bidPriceFractionIndicator : Sample(1),
      bidSize                   : Sample(5),
      askPriceSign              : Sample(1),
      askPriceQuote             : Sample(7),
      askPriceFractionIndicator : Sample(1),
      askSize                   : Sample(5),
      instrumentStatusMarker    : Sample(1) ]

EncodeStrategyQuoteMessage(message) ==
    EncodeLongMessageHeader16(message.longMessageHeader)
        \o message.exchangeId
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
    LET longMessageHeader == DecodeLongMessageHeader16(bytes) IN IF ~longMessageHeader.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(longMessageHeader.rest, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET symbol == ReadBytes(exchangeId.rest, 30) IN IF ~symbol.ok THEN Fail ELSE
    LET bidPriceSign == ReadBytes(symbol.rest, 1) IN IF ~bidPriceSign.ok THEN Fail ELSE
    LET bidPriceQuote == ReadBytes(bidPriceSign.rest, 7) IN IF ~bidPriceQuote.ok THEN Fail ELSE
    LET bidPriceFractionIndicator == ReadBytes(bidPriceQuote.rest, 1) IN IF ~bidPriceFractionIndicator.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPriceFractionIndicator.rest, 5) IN IF ~bidSize.ok THEN Fail ELSE
    LET askPriceSign == ReadBytes(bidSize.rest, 1) IN IF ~askPriceSign.ok THEN Fail ELSE
    LET askPriceQuote == ReadBytes(askPriceSign.rest, 7) IN IF ~askPriceQuote.ok THEN Fail ELSE
    LET askPriceFractionIndicator == ReadBytes(askPriceQuote.rest, 1) IN IF ~askPriceFractionIndicator.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPriceFractionIndicator.rest, 5) IN IF ~askSize.ok THEN Fail ELSE
    LET instrumentStatusMarker == ReadBytes(askSize.rest, 1) IN IF ~instrumentStatusMarker.ok THEN Fail ELSE
    Ok([ longMessageHeader         |-> longMessageHeader.value,
         exchangeId                |-> exchangeId.value,
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
    [ longMessageHeader         |-> ZeroLongMessageHeader16,
      exchangeId                |-> [i \in 1 .. 1 |-> 0],
      symbol                    |-> [i \in 1 .. 30 |-> 0],
      bidPriceSign              |-> [i \in 1 .. 1 |-> 0],
      bidPriceQuote             |-> [i \in 1 .. 7 |-> 0],
      bidPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      bidSize                   |-> [i \in 1 .. 5 |-> 0],
      askPriceSign              |-> [i \in 1 .. 1 |-> 0],
      askPriceQuote             |-> [i \in 1 .. 7 |-> 0],
      askPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      askSize                   |-> [i \in 1 .. 5 |-> 0],
      instrumentStatusMarker    |-> [i \in 1 .. 1 |-> 0] ]

(* Strategy Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedStrategyQuoteMessage ==
    { ZeroStrategyQuoteMessage }
        \cup { [ZeroStrategyQuoteMessage EXCEPT !.longMessageHeader = one] : one \in CheckedLongMessageHeader16 }
        \cup { [ZeroStrategyQuoteMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroStrategyQuoteMessage EXCEPT !.symbol = one] : one \in Sample(30) }
        \cup { [ZeroStrategyQuoteMessage EXCEPT !.bidPriceSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategyQuoteMessage EXCEPT !.bidPriceQuote = one] : one \in Sample(7) }
        \cup { [ZeroStrategyQuoteMessage EXCEPT !.bidPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStrategyQuoteMessage EXCEPT !.bidSize = one] : one \in Sample(5) }
        \cup { [ZeroStrategyQuoteMessage EXCEPT !.askPriceSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategyQuoteMessage EXCEPT !.askPriceQuote = one] : one \in Sample(7) }
        \cup { [ZeroStrategyQuoteMessage EXCEPT !.askPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStrategyQuoteMessage EXCEPT !.askSize = one] : one \in Sample(5) }
        \cup { [ZeroStrategyQuoteMessage EXCEPT !.instrumentStatusMarker = one] : one \in Sample(1) }

(***************************************************************************)
(* Long Message Header: 12 bytes                                           *)
(***************************************************************************)

LongMessageHeader17 ==
    [ messageTimestamp : Sample(12) ]

EncodeLongMessageHeader17(message) ==
    message.messageTimestamp

DecodeLongMessageHeader17(bytes) ==
    LET messageTimestamp == ReadBytes(bytes, 12) IN IF ~messageTimestamp.ok THEN Fail ELSE
    Ok([ messageTimestamp |-> messageTimestamp.value ], messageTimestamp.rest)

ZeroLongMessageHeader17 ==
    [ messageTimestamp |-> [i \in 1 .. 12 |-> 0] ]

(* Long Message Header at zero, then each field in turn at the values it is checked at *)
CheckedLongMessageHeader17 ==
    { ZeroLongMessageHeader17 }
        \cup { [ZeroLongMessageHeader17 EXCEPT !.messageTimestamp = one] : one \in Sample(12) }

(***************************************************************************)
(* Option Symbol: 20 bytes                                                 *)
(***************************************************************************)

OptionSymbol5 ==
    [ root                         : Sample(6),
      expiryMonth                  : Sample(1),
      filler1                      : Sample(1),
      strikePrice                  : Sample(7),
      strikePriceFractionIndicator : Sample(1),
      expiryYear                   : Sample(2),
      expiryDay                    : Sample(2) ]

EncodeOptionSymbol5(message) ==
    message.root
        \o message.expiryMonth
        \o message.filler1
        \o message.strikePrice
        \o message.strikePriceFractionIndicator
        \o message.expiryYear
        \o message.expiryDay

DecodeOptionSymbol5(bytes) ==
    LET root == ReadBytes(bytes, 6) IN IF ~root.ok THEN Fail ELSE
    LET expiryMonth == ReadBytes(root.rest, 1) IN IF ~expiryMonth.ok THEN Fail ELSE
    LET filler1 == ReadBytes(expiryMonth.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(filler1.rest, 7) IN IF ~strikePrice.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePrice.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(strikePriceFractionIndicator.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ root                         |-> root.value,
         expiryMonth                  |-> expiryMonth.value,
         filler1                      |-> filler1.value,
         strikePrice                  |-> strikePrice.value,
         strikePriceFractionIndicator |-> strikePriceFractionIndicator.value,
         expiryYear                   |-> expiryYear.value,
         expiryDay                    |-> expiryDay.value ], expiryDay.rest)

ZeroOptionSymbol5 ==
    [ root                         |-> [i \in 1 .. 6 |-> 0],
      expiryMonth                  |-> [i \in 1 .. 1 |-> 0],
      filler1                      |-> [i \in 1 .. 1 |-> 0],
      strikePrice                  |-> [i \in 1 .. 7 |-> 0],
      strikePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      expiryYear                   |-> [i \in 1 .. 2 |-> 0],
      expiryDay                    |-> [i \in 1 .. 2 |-> 0] ]

(* Option Symbol at zero, then each field in turn at the values it is checked at *)
CheckedOptionSymbol5 ==
    { ZeroOptionSymbol5 }
        \cup { [ZeroOptionSymbol5 EXCEPT !.root = one] : one \in Sample(6) }
        \cup { [ZeroOptionSymbol5 EXCEPT !.expiryMonth = one] : one \in Sample(1) }
        \cup { [ZeroOptionSymbol5 EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroOptionSymbol5 EXCEPT !.strikePrice = one] : one \in Sample(7) }
        \cup { [ZeroOptionSymbol5 EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionSymbol5 EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroOptionSymbol5 EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Market Depth Level: 31 bytes                                            *)
(***************************************************************************)

MarketDepthLevel ==
    [ levelOfMarketDepth        : Sample(1),
      bidPriceQuote             : Sample(7),
      bidPriceFractionIndicator : Sample(1),
      bidSize                   : Sample(5),
      numberOfBidOrders         : Sample(2),
      askPriceQuote             : Sample(7),
      askPriceFractionIndicator : Sample(1),
      askSize                   : Sample(5),
      numberOfAskOrders         : Sample(2) ]

EncodeMarketDepthLevel(message) ==
    message.levelOfMarketDepth
        \o message.bidPriceQuote
        \o message.bidPriceFractionIndicator
        \o message.bidSize
        \o message.numberOfBidOrders
        \o message.askPriceQuote
        \o message.askPriceFractionIndicator
        \o message.askSize
        \o message.numberOfAskOrders

DecodeMarketDepthLevel(bytes) ==
    LET levelOfMarketDepth == ReadBytes(bytes, 1) IN IF ~levelOfMarketDepth.ok THEN Fail ELSE
    LET bidPriceQuote == ReadBytes(levelOfMarketDepth.rest, 7) IN IF ~bidPriceQuote.ok THEN Fail ELSE
    LET bidPriceFractionIndicator == ReadBytes(bidPriceQuote.rest, 1) IN IF ~bidPriceFractionIndicator.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPriceFractionIndicator.rest, 5) IN IF ~bidSize.ok THEN Fail ELSE
    LET numberOfBidOrders == ReadBytes(bidSize.rest, 2) IN IF ~numberOfBidOrders.ok THEN Fail ELSE
    LET askPriceQuote == ReadBytes(numberOfBidOrders.rest, 7) IN IF ~askPriceQuote.ok THEN Fail ELSE
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

ZeroMarketDepthLevel ==
    [ levelOfMarketDepth        |-> [i \in 1 .. 1 |-> 0],
      bidPriceQuote             |-> [i \in 1 .. 7 |-> 0],
      bidPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      bidSize                   |-> [i \in 1 .. 5 |-> 0],
      numberOfBidOrders         |-> [i \in 1 .. 2 |-> 0],
      askPriceQuote             |-> [i \in 1 .. 7 |-> 0],
      askPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      askSize                   |-> [i \in 1 .. 5 |-> 0],
      numberOfAskOrders         |-> [i \in 1 .. 2 |-> 0] ]

(* Market Depth Level at zero, then each field in turn at the values it is checked at *)
CheckedMarketDepthLevel ==
    { ZeroMarketDepthLevel }
        \cup { [ZeroMarketDepthLevel EXCEPT !.levelOfMarketDepth = one] : one \in Sample(1) }
        \cup { [ZeroMarketDepthLevel EXCEPT !.bidPriceQuote = one] : one \in Sample(7) }
        \cup { [ZeroMarketDepthLevel EXCEPT !.bidPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMarketDepthLevel EXCEPT !.bidSize = one] : one \in Sample(5) }
        \cup { [ZeroMarketDepthLevel EXCEPT !.numberOfBidOrders = one] : one \in Sample(2) }
        \cup { [ZeroMarketDepthLevel EXCEPT !.askPriceQuote = one] : one \in Sample(7) }
        \cup { [ZeroMarketDepthLevel EXCEPT !.askPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMarketDepthLevel EXCEPT !.askSize = one] : one \in Sample(5) }
        \cup { [ZeroMarketDepthLevel EXCEPT !.numberOfAskOrders = one] : one \in Sample(2) }

(* A run of Market Depth Level, written one after another *)
RECURSIVE EncodeMarketDepthLevelList(_)
EncodeMarketDepthLevelList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMarketDepthLevel(Head(messages)) \o EncodeMarketDepthLevelList(Tail(messages))

(* As many Market Depth Level as the field that counts them says *)
RECURSIVE ReadMarketDepthLevelList(_, _)
ReadMarketDepthLevelList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMarketDepthLevel(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMarketDepthLevelList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Market Depth Level of each kind, for the lists that carry them *)
OneMarketDepthLevel == { ZeroMarketDepthLevel }

(***************************************************************************)
(* Option Market Depth Message                                             *)
(***************************************************************************)

OptionMarketDepthMessage ==
    [ longMessageHeader      : LongMessageHeader17,
      exchangeId             : Sample(1),
      optionSymbol           : OptionSymbol5,
      instrumentStatusMarker : Sample(1),
      marketDepthLevel       : SampleLists(OneMarketDepthLevel) ]

EncodeOptionMarketDepthMessage(message) ==
    EncodeLongMessageHeader17(message.longMessageHeader)
        \o message.exchangeId
        \o EncodeOptionSymbol5(message.optionSymbol)
        \o message.instrumentStatusMarker
        \o EncodeDigits(Len(message.marketDepthLevel), 1)
        \o EncodeMarketDepthLevelList(message.marketDepthLevel)

DecodeOptionMarketDepthMessage(bytes) ==
    LET longMessageHeader == DecodeLongMessageHeader17(bytes) IN IF ~longMessageHeader.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(longMessageHeader.rest, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET optionSymbol == DecodeOptionSymbol5(exchangeId.rest) IN IF ~optionSymbol.ok THEN Fail ELSE
    LET instrumentStatusMarker == ReadBytes(optionSymbol.rest, 1) IN IF ~instrumentStatusMarker.ok THEN Fail ELSE
    LET numberOfLevel == ReadDigits(instrumentStatusMarker.rest, 1) IN IF ~numberOfLevel.ok THEN Fail ELSE
    LET marketDepthLevel == ReadMarketDepthLevelList(numberOfLevel.rest, numberOfLevel.value) IN IF ~marketDepthLevel.ok THEN Fail ELSE
    Ok([ longMessageHeader      |-> longMessageHeader.value,
         exchangeId             |-> exchangeId.value,
         optionSymbol           |-> optionSymbol.value,
         instrumentStatusMarker |-> instrumentStatusMarker.value,
         marketDepthLevel       |-> marketDepthLevel.value ], marketDepthLevel.rest)

ZeroOptionMarketDepthMessage ==
    [ longMessageHeader      |-> ZeroLongMessageHeader17,
      exchangeId             |-> [i \in 1 .. 1 |-> 0],
      optionSymbol           |-> ZeroOptionSymbol5,
      instrumentStatusMarker |-> [i \in 1 .. 1 |-> 0],
      marketDepthLevel       |-> << >> ]

(* Option Market Depth Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionMarketDepthMessage ==
    { ZeroOptionMarketDepthMessage }
        \cup { [ZeroOptionMarketDepthMessage EXCEPT !.longMessageHeader = one] : one \in CheckedLongMessageHeader17 }
        \cup { [ZeroOptionMarketDepthMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroOptionMarketDepthMessage EXCEPT !.optionSymbol = one] : one \in CheckedOptionSymbol5 }
        \cup { [ZeroOptionMarketDepthMessage EXCEPT !.instrumentStatusMarker = one] : one \in Sample(1) }
        \cup { [ZeroOptionMarketDepthMessage EXCEPT !.marketDepthLevel = one] : one \in SampleLists(OneMarketDepthLevel) }

(***************************************************************************)
(* Long Message Header: 12 bytes                                           *)
(***************************************************************************)

LongMessageHeader18 ==
    [ messageTimestamp : Sample(12) ]

EncodeLongMessageHeader18(message) ==
    message.messageTimestamp

DecodeLongMessageHeader18(bytes) ==
    LET messageTimestamp == ReadBytes(bytes, 12) IN IF ~messageTimestamp.ok THEN Fail ELSE
    Ok([ messageTimestamp |-> messageTimestamp.value ], messageTimestamp.rest)

ZeroLongMessageHeader18 ==
    [ messageTimestamp |-> [i \in 1 .. 12 |-> 0] ]

(* Long Message Header at zero, then each field in turn at the values it is checked at *)
CheckedLongMessageHeader18 ==
    { ZeroLongMessageHeader18 }
        \cup { [ZeroLongMessageHeader18 EXCEPT !.messageTimestamp = one] : one \in Sample(12) }

(***************************************************************************)
(* Future Option Symbol: 20 bytes                                          *)
(***************************************************************************)

FutureOptionSymbol5 ==
    [ root                         : Sample(6),
      symbolMonth                  : Sample(1),
      symbolYear                   : Sample(2),
      expiryDay                    : Sample(2),
      callPutCode                  : Sample(1),
      strikePrice                  : Sample(7),
      strikePriceFractionIndicator : Sample(1) ]

EncodeFutureOptionSymbol5(message) ==
    message.root
        \o message.symbolMonth
        \o message.symbolYear
        \o message.expiryDay
        \o message.callPutCode
        \o message.strikePrice
        \o message.strikePriceFractionIndicator

DecodeFutureOptionSymbol5(bytes) ==
    LET root == ReadBytes(bytes, 6) IN IF ~root.ok THEN Fail ELSE
    LET symbolMonth == ReadBytes(root.rest, 1) IN IF ~symbolMonth.ok THEN Fail ELSE
    LET symbolYear == ReadBytes(symbolMonth.rest, 2) IN IF ~symbolYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(symbolYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET callPutCode == ReadBytes(expiryDay.rest, 1) IN IF ~callPutCode.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(callPutCode.rest, 7) IN IF ~strikePrice.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePrice.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    Ok([ root                         |-> root.value,
         symbolMonth                  |-> symbolMonth.value,
         symbolYear                   |-> symbolYear.value,
         expiryDay                    |-> expiryDay.value,
         callPutCode                  |-> callPutCode.value,
         strikePrice                  |-> strikePrice.value,
         strikePriceFractionIndicator |-> strikePriceFractionIndicator.value ], strikePriceFractionIndicator.rest)

ZeroFutureOptionSymbol5 ==
    [ root                         |-> [i \in 1 .. 6 |-> 0],
      symbolMonth                  |-> [i \in 1 .. 1 |-> 0],
      symbolYear                   |-> [i \in 1 .. 2 |-> 0],
      expiryDay                    |-> [i \in 1 .. 2 |-> 0],
      callPutCode                  |-> [i \in 1 .. 1 |-> 0],
      strikePrice                  |-> [i \in 1 .. 7 |-> 0],
      strikePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Future Option Symbol at zero, then each field in turn at the values it is checked at *)
CheckedFutureOptionSymbol5 ==
    { ZeroFutureOptionSymbol5 }
        \cup { [ZeroFutureOptionSymbol5 EXCEPT !.root = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionSymbol5 EXCEPT !.symbolMonth = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionSymbol5 EXCEPT !.symbolYear = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionSymbol5 EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionSymbol5 EXCEPT !.callPutCode = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionSymbol5 EXCEPT !.strikePrice = one] : one \in Sample(7) }
        \cup { [ZeroFutureOptionSymbol5 EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Market Depth Level: 31 bytes                                            *)
(***************************************************************************)

MarketDepthLevel2 ==
    [ levelOfMarketDepth        : Sample(1),
      bidPriceQuote             : Sample(7),
      bidPriceFractionIndicator : Sample(1),
      bidSize                   : Sample(5),
      numberOfBidOrders         : Sample(2),
      askPriceQuote             : Sample(7),
      askPriceFractionIndicator : Sample(1),
      askSize                   : Sample(5),
      numberOfAskOrders         : Sample(2) ]

EncodeMarketDepthLevel2(message) ==
    message.levelOfMarketDepth
        \o message.bidPriceQuote
        \o message.bidPriceFractionIndicator
        \o message.bidSize
        \o message.numberOfBidOrders
        \o message.askPriceQuote
        \o message.askPriceFractionIndicator
        \o message.askSize
        \o message.numberOfAskOrders

DecodeMarketDepthLevel2(bytes) ==
    LET levelOfMarketDepth == ReadBytes(bytes, 1) IN IF ~levelOfMarketDepth.ok THEN Fail ELSE
    LET bidPriceQuote == ReadBytes(levelOfMarketDepth.rest, 7) IN IF ~bidPriceQuote.ok THEN Fail ELSE
    LET bidPriceFractionIndicator == ReadBytes(bidPriceQuote.rest, 1) IN IF ~bidPriceFractionIndicator.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPriceFractionIndicator.rest, 5) IN IF ~bidSize.ok THEN Fail ELSE
    LET numberOfBidOrders == ReadBytes(bidSize.rest, 2) IN IF ~numberOfBidOrders.ok THEN Fail ELSE
    LET askPriceQuote == ReadBytes(numberOfBidOrders.rest, 7) IN IF ~askPriceQuote.ok THEN Fail ELSE
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

ZeroMarketDepthLevel2 ==
    [ levelOfMarketDepth        |-> [i \in 1 .. 1 |-> 0],
      bidPriceQuote             |-> [i \in 1 .. 7 |-> 0],
      bidPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      bidSize                   |-> [i \in 1 .. 5 |-> 0],
      numberOfBidOrders         |-> [i \in 1 .. 2 |-> 0],
      askPriceQuote             |-> [i \in 1 .. 7 |-> 0],
      askPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      askSize                   |-> [i \in 1 .. 5 |-> 0],
      numberOfAskOrders         |-> [i \in 1 .. 2 |-> 0] ]

(* Market Depth Level at zero, then each field in turn at the values it is checked at *)
CheckedMarketDepthLevel2 ==
    { ZeroMarketDepthLevel2 }
        \cup { [ZeroMarketDepthLevel2 EXCEPT !.levelOfMarketDepth = one] : one \in Sample(1) }
        \cup { [ZeroMarketDepthLevel2 EXCEPT !.bidPriceQuote = one] : one \in Sample(7) }
        \cup { [ZeroMarketDepthLevel2 EXCEPT !.bidPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMarketDepthLevel2 EXCEPT !.bidSize = one] : one \in Sample(5) }
        \cup { [ZeroMarketDepthLevel2 EXCEPT !.numberOfBidOrders = one] : one \in Sample(2) }
        \cup { [ZeroMarketDepthLevel2 EXCEPT !.askPriceQuote = one] : one \in Sample(7) }
        \cup { [ZeroMarketDepthLevel2 EXCEPT !.askPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMarketDepthLevel2 EXCEPT !.askSize = one] : one \in Sample(5) }
        \cup { [ZeroMarketDepthLevel2 EXCEPT !.numberOfAskOrders = one] : one \in Sample(2) }

(* A run of Market Depth Level, written one after another *)
RECURSIVE EncodeMarketDepthLevel2List(_)
EncodeMarketDepthLevel2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMarketDepthLevel2(Head(messages)) \o EncodeMarketDepthLevel2List(Tail(messages))

(* As many Market Depth Level as the field that counts them says *)
RECURSIVE ReadMarketDepthLevel2List(_, _)
ReadMarketDepthLevel2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMarketDepthLevel2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMarketDepthLevel2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Market Depth Level of each kind, for the lists that carry them *)
OneMarketDepthLevel2 == { ZeroMarketDepthLevel2 }

(***************************************************************************)
(* Future Options Market Depth Message                                     *)
(***************************************************************************)

FutureOptionsMarketDepthMessage ==
    [ longMessageHeader      : LongMessageHeader18,
      exchangeId             : Sample(1),
      futureOptionSymbol     : FutureOptionSymbol5,
      instrumentStatusMarker : Sample(1),
      marketDepthLevel       : SampleLists(OneMarketDepthLevel2) ]

EncodeFutureOptionsMarketDepthMessage(message) ==
    EncodeLongMessageHeader18(message.longMessageHeader)
        \o message.exchangeId
        \o EncodeFutureOptionSymbol5(message.futureOptionSymbol)
        \o message.instrumentStatusMarker
        \o EncodeDigits(Len(message.marketDepthLevel), 1)
        \o EncodeMarketDepthLevel2List(message.marketDepthLevel)

DecodeFutureOptionsMarketDepthMessage(bytes) ==
    LET longMessageHeader == DecodeLongMessageHeader18(bytes) IN IF ~longMessageHeader.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(longMessageHeader.rest, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET futureOptionSymbol == DecodeFutureOptionSymbol5(exchangeId.rest) IN IF ~futureOptionSymbol.ok THEN Fail ELSE
    LET instrumentStatusMarker == ReadBytes(futureOptionSymbol.rest, 1) IN IF ~instrumentStatusMarker.ok THEN Fail ELSE
    LET numberOfLevel == ReadDigits(instrumentStatusMarker.rest, 1) IN IF ~numberOfLevel.ok THEN Fail ELSE
    LET marketDepthLevel == ReadMarketDepthLevel2List(numberOfLevel.rest, numberOfLevel.value) IN IF ~marketDepthLevel.ok THEN Fail ELSE
    Ok([ longMessageHeader      |-> longMessageHeader.value,
         exchangeId             |-> exchangeId.value,
         futureOptionSymbol     |-> futureOptionSymbol.value,
         instrumentStatusMarker |-> instrumentStatusMarker.value,
         marketDepthLevel       |-> marketDepthLevel.value ], marketDepthLevel.rest)

ZeroFutureOptionsMarketDepthMessage ==
    [ longMessageHeader      |-> ZeroLongMessageHeader18,
      exchangeId             |-> [i \in 1 .. 1 |-> 0],
      futureOptionSymbol     |-> ZeroFutureOptionSymbol5,
      instrumentStatusMarker |-> [i \in 1 .. 1 |-> 0],
      marketDepthLevel       |-> << >> ]

(* Future Options Market Depth Message at zero, then each field in turn at the values it is checked at *)
CheckedFutureOptionsMarketDepthMessage ==
    { ZeroFutureOptionsMarketDepthMessage }
        \cup { [ZeroFutureOptionsMarketDepthMessage EXCEPT !.longMessageHeader = one] : one \in CheckedLongMessageHeader18 }
        \cup { [ZeroFutureOptionsMarketDepthMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsMarketDepthMessage EXCEPT !.futureOptionSymbol = one] : one \in CheckedFutureOptionSymbol5 }
        \cup { [ZeroFutureOptionsMarketDepthMessage EXCEPT !.instrumentStatusMarker = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsMarketDepthMessage EXCEPT !.marketDepthLevel = one] : one \in SampleLists(OneMarketDepthLevel2) }

(***************************************************************************)
(* Long Message Header: 12 bytes                                           *)
(***************************************************************************)

LongMessageHeader19 ==
    [ messageTimestamp : Sample(12) ]

EncodeLongMessageHeader19(message) ==
    message.messageTimestamp

DecodeLongMessageHeader19(bytes) ==
    LET messageTimestamp == ReadBytes(bytes, 12) IN IF ~messageTimestamp.ok THEN Fail ELSE
    Ok([ messageTimestamp |-> messageTimestamp.value ], messageTimestamp.rest)

ZeroLongMessageHeader19 ==
    [ messageTimestamp |-> [i \in 1 .. 12 |-> 0] ]

(* Long Message Header at zero, then each field in turn at the values it is checked at *)
CheckedLongMessageHeader19 ==
    { ZeroLongMessageHeader19 }
        \cup { [ZeroLongMessageHeader19 EXCEPT !.messageTimestamp = one] : one \in Sample(12) }

(***************************************************************************)
(* Future Product: 11 bytes                                                *)
(***************************************************************************)

FutureProduct5 ==
    [ root        : Sample(6),
      symbolMonth : Sample(1),
      symbolYear  : Sample(2),
      expiryDay   : Sample(2) ]

EncodeFutureProduct5(message) ==
    message.root
        \o message.symbolMonth
        \o message.symbolYear
        \o message.expiryDay

DecodeFutureProduct5(bytes) ==
    LET root == ReadBytes(bytes, 6) IN IF ~root.ok THEN Fail ELSE
    LET symbolMonth == ReadBytes(root.rest, 1) IN IF ~symbolMonth.ok THEN Fail ELSE
    LET symbolYear == ReadBytes(symbolMonth.rest, 2) IN IF ~symbolYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(symbolYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ root        |-> root.value,
         symbolMonth |-> symbolMonth.value,
         symbolYear  |-> symbolYear.value,
         expiryDay   |-> expiryDay.value ], expiryDay.rest)

ZeroFutureProduct5 ==
    [ root        |-> [i \in 1 .. 6 |-> 0],
      symbolMonth |-> [i \in 1 .. 1 |-> 0],
      symbolYear  |-> [i \in 1 .. 2 |-> 0],
      expiryDay   |-> [i \in 1 .. 2 |-> 0] ]

(* Future Product at zero, then each field in turn at the values it is checked at *)
CheckedFutureProduct5 ==
    { ZeroFutureProduct5 }
        \cup { [ZeroFutureProduct5 EXCEPT !.root = one] : one \in Sample(6) }
        \cup { [ZeroFutureProduct5 EXCEPT !.symbolMonth = one] : one \in Sample(1) }
        \cup { [ZeroFutureProduct5 EXCEPT !.symbolYear = one] : one \in Sample(2) }
        \cup { [ZeroFutureProduct5 EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Market Depth Level: 31 bytes                                            *)
(***************************************************************************)

MarketDepthLevel3 ==
    [ levelOfMarketDepth        : Sample(1),
      bidPriceQuote             : Sample(7),
      bidPriceFractionIndicator : Sample(1),
      bidSize                   : Sample(5),
      numberOfBidOrders         : Sample(2),
      askPriceQuote             : Sample(7),
      askPriceFractionIndicator : Sample(1),
      askSize                   : Sample(5),
      numberOfAskOrders         : Sample(2) ]

EncodeMarketDepthLevel3(message) ==
    message.levelOfMarketDepth
        \o message.bidPriceQuote
        \o message.bidPriceFractionIndicator
        \o message.bidSize
        \o message.numberOfBidOrders
        \o message.askPriceQuote
        \o message.askPriceFractionIndicator
        \o message.askSize
        \o message.numberOfAskOrders

DecodeMarketDepthLevel3(bytes) ==
    LET levelOfMarketDepth == ReadBytes(bytes, 1) IN IF ~levelOfMarketDepth.ok THEN Fail ELSE
    LET bidPriceQuote == ReadBytes(levelOfMarketDepth.rest, 7) IN IF ~bidPriceQuote.ok THEN Fail ELSE
    LET bidPriceFractionIndicator == ReadBytes(bidPriceQuote.rest, 1) IN IF ~bidPriceFractionIndicator.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPriceFractionIndicator.rest, 5) IN IF ~bidSize.ok THEN Fail ELSE
    LET numberOfBidOrders == ReadBytes(bidSize.rest, 2) IN IF ~numberOfBidOrders.ok THEN Fail ELSE
    LET askPriceQuote == ReadBytes(numberOfBidOrders.rest, 7) IN IF ~askPriceQuote.ok THEN Fail ELSE
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

ZeroMarketDepthLevel3 ==
    [ levelOfMarketDepth        |-> [i \in 1 .. 1 |-> 0],
      bidPriceQuote             |-> [i \in 1 .. 7 |-> 0],
      bidPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      bidSize                   |-> [i \in 1 .. 5 |-> 0],
      numberOfBidOrders         |-> [i \in 1 .. 2 |-> 0],
      askPriceQuote             |-> [i \in 1 .. 7 |-> 0],
      askPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      askSize                   |-> [i \in 1 .. 5 |-> 0],
      numberOfAskOrders         |-> [i \in 1 .. 2 |-> 0] ]

(* Market Depth Level at zero, then each field in turn at the values it is checked at *)
CheckedMarketDepthLevel3 ==
    { ZeroMarketDepthLevel3 }
        \cup { [ZeroMarketDepthLevel3 EXCEPT !.levelOfMarketDepth = one] : one \in Sample(1) }
        \cup { [ZeroMarketDepthLevel3 EXCEPT !.bidPriceQuote = one] : one \in Sample(7) }
        \cup { [ZeroMarketDepthLevel3 EXCEPT !.bidPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMarketDepthLevel3 EXCEPT !.bidSize = one] : one \in Sample(5) }
        \cup { [ZeroMarketDepthLevel3 EXCEPT !.numberOfBidOrders = one] : one \in Sample(2) }
        \cup { [ZeroMarketDepthLevel3 EXCEPT !.askPriceQuote = one] : one \in Sample(7) }
        \cup { [ZeroMarketDepthLevel3 EXCEPT !.askPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMarketDepthLevel3 EXCEPT !.askSize = one] : one \in Sample(5) }
        \cup { [ZeroMarketDepthLevel3 EXCEPT !.numberOfAskOrders = one] : one \in Sample(2) }

(* A run of Market Depth Level, written one after another *)
RECURSIVE EncodeMarketDepthLevel3List(_)
EncodeMarketDepthLevel3List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMarketDepthLevel3(Head(messages)) \o EncodeMarketDepthLevel3List(Tail(messages))

(* As many Market Depth Level as the field that counts them says *)
RECURSIVE ReadMarketDepthLevel3List(_, _)
ReadMarketDepthLevel3List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMarketDepthLevel3(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMarketDepthLevel3List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Market Depth Level of each kind, for the lists that carry them *)
OneMarketDepthLevel3 == { ZeroMarketDepthLevel3 }

(***************************************************************************)
(* Futures Market Depth Message                                            *)
(***************************************************************************)

FuturesMarketDepthMessage ==
    [ longMessageHeader      : LongMessageHeader19,
      exchangeId             : Sample(1),
      futureProduct          : FutureProduct5,
      instrumentStatusMarker : Sample(1),
      marketDepthLevel       : SampleLists(OneMarketDepthLevel3) ]

EncodeFuturesMarketDepthMessage(message) ==
    EncodeLongMessageHeader19(message.longMessageHeader)
        \o message.exchangeId
        \o EncodeFutureProduct5(message.futureProduct)
        \o message.instrumentStatusMarker
        \o EncodeDigits(Len(message.marketDepthLevel), 1)
        \o EncodeMarketDepthLevel3List(message.marketDepthLevel)

DecodeFuturesMarketDepthMessage(bytes) ==
    LET longMessageHeader == DecodeLongMessageHeader19(bytes) IN IF ~longMessageHeader.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(longMessageHeader.rest, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET futureProduct == DecodeFutureProduct5(exchangeId.rest) IN IF ~futureProduct.ok THEN Fail ELSE
    LET instrumentStatusMarker == ReadBytes(futureProduct.rest, 1) IN IF ~instrumentStatusMarker.ok THEN Fail ELSE
    LET numberOfLevel == ReadDigits(instrumentStatusMarker.rest, 1) IN IF ~numberOfLevel.ok THEN Fail ELSE
    LET marketDepthLevel == ReadMarketDepthLevel3List(numberOfLevel.rest, numberOfLevel.value) IN IF ~marketDepthLevel.ok THEN Fail ELSE
    Ok([ longMessageHeader      |-> longMessageHeader.value,
         exchangeId             |-> exchangeId.value,
         futureProduct          |-> futureProduct.value,
         instrumentStatusMarker |-> instrumentStatusMarker.value,
         marketDepthLevel       |-> marketDepthLevel.value ], marketDepthLevel.rest)

ZeroFuturesMarketDepthMessage ==
    [ longMessageHeader      |-> ZeroLongMessageHeader19,
      exchangeId             |-> [i \in 1 .. 1 |-> 0],
      futureProduct          |-> ZeroFutureProduct5,
      instrumentStatusMarker |-> [i \in 1 .. 1 |-> 0],
      marketDepthLevel       |-> << >> ]

(* Futures Market Depth Message at zero, then each field in turn at the values it is checked at *)
CheckedFuturesMarketDepthMessage ==
    { ZeroFuturesMarketDepthMessage }
        \cup { [ZeroFuturesMarketDepthMessage EXCEPT !.longMessageHeader = one] : one \in CheckedLongMessageHeader19 }
        \cup { [ZeroFuturesMarketDepthMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroFuturesMarketDepthMessage EXCEPT !.futureProduct = one] : one \in CheckedFutureProduct5 }
        \cup { [ZeroFuturesMarketDepthMessage EXCEPT !.instrumentStatusMarker = one] : one \in Sample(1) }
        \cup { [ZeroFuturesMarketDepthMessage EXCEPT !.marketDepthLevel = one] : one \in SampleLists(OneMarketDepthLevel3) }

(***************************************************************************)
(* Long Message Header: 12 bytes                                           *)
(***************************************************************************)

LongMessageHeader20 ==
    [ messageTimestamp : Sample(12) ]

EncodeLongMessageHeader20(message) ==
    message.messageTimestamp

DecodeLongMessageHeader20(bytes) ==
    LET messageTimestamp == ReadBytes(bytes, 12) IN IF ~messageTimestamp.ok THEN Fail ELSE
    Ok([ messageTimestamp |-> messageTimestamp.value ], messageTimestamp.rest)

ZeroLongMessageHeader20 ==
    [ messageTimestamp |-> [i \in 1 .. 12 |-> 0] ]

(* Long Message Header at zero, then each field in turn at the values it is checked at *)
CheckedLongMessageHeader20 ==
    { ZeroLongMessageHeader20 }
        \cup { [ZeroLongMessageHeader20 EXCEPT !.messageTimestamp = one] : one \in Sample(12) }

(***************************************************************************)
(* Strategy Market Depth Level: 33 bytes                                   *)
(***************************************************************************)

StrategyMarketDepthLevel ==
    [ levelOfMarketDepth        : Sample(1),
      bidPriceSign              : Sample(1),
      bidPriceQuote             : Sample(7),
      bidPriceFractionIndicator : Sample(1),
      bidSize                   : Sample(5),
      numberOfBidOrders         : Sample(2),
      askPriceSign              : Sample(1),
      askPriceQuote             : Sample(7),
      askPriceFractionIndicator : Sample(1),
      askSize                   : Sample(5),
      numberOfAskOrders         : Sample(2) ]

EncodeStrategyMarketDepthLevel(message) ==
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

DecodeStrategyMarketDepthLevel(bytes) ==
    LET levelOfMarketDepth == ReadBytes(bytes, 1) IN IF ~levelOfMarketDepth.ok THEN Fail ELSE
    LET bidPriceSign == ReadBytes(levelOfMarketDepth.rest, 1) IN IF ~bidPriceSign.ok THEN Fail ELSE
    LET bidPriceQuote == ReadBytes(bidPriceSign.rest, 7) IN IF ~bidPriceQuote.ok THEN Fail ELSE
    LET bidPriceFractionIndicator == ReadBytes(bidPriceQuote.rest, 1) IN IF ~bidPriceFractionIndicator.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPriceFractionIndicator.rest, 5) IN IF ~bidSize.ok THEN Fail ELSE
    LET numberOfBidOrders == ReadBytes(bidSize.rest, 2) IN IF ~numberOfBidOrders.ok THEN Fail ELSE
    LET askPriceSign == ReadBytes(numberOfBidOrders.rest, 1) IN IF ~askPriceSign.ok THEN Fail ELSE
    LET askPriceQuote == ReadBytes(askPriceSign.rest, 7) IN IF ~askPriceQuote.ok THEN Fail ELSE
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

ZeroStrategyMarketDepthLevel ==
    [ levelOfMarketDepth        |-> [i \in 1 .. 1 |-> 0],
      bidPriceSign              |-> [i \in 1 .. 1 |-> 0],
      bidPriceQuote             |-> [i \in 1 .. 7 |-> 0],
      bidPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      bidSize                   |-> [i \in 1 .. 5 |-> 0],
      numberOfBidOrders         |-> [i \in 1 .. 2 |-> 0],
      askPriceSign              |-> [i \in 1 .. 1 |-> 0],
      askPriceQuote             |-> [i \in 1 .. 7 |-> 0],
      askPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      askSize                   |-> [i \in 1 .. 5 |-> 0],
      numberOfAskOrders         |-> [i \in 1 .. 2 |-> 0] ]

(* Strategy Market Depth Level at zero, then each field in turn at the values it is checked at *)
CheckedStrategyMarketDepthLevel ==
    { ZeroStrategyMarketDepthLevel }
        \cup { [ZeroStrategyMarketDepthLevel EXCEPT !.levelOfMarketDepth = one] : one \in Sample(1) }
        \cup { [ZeroStrategyMarketDepthLevel EXCEPT !.bidPriceSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategyMarketDepthLevel EXCEPT !.bidPriceQuote = one] : one \in Sample(7) }
        \cup { [ZeroStrategyMarketDepthLevel EXCEPT !.bidPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStrategyMarketDepthLevel EXCEPT !.bidSize = one] : one \in Sample(5) }
        \cup { [ZeroStrategyMarketDepthLevel EXCEPT !.numberOfBidOrders = one] : one \in Sample(2) }
        \cup { [ZeroStrategyMarketDepthLevel EXCEPT !.askPriceSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategyMarketDepthLevel EXCEPT !.askPriceQuote = one] : one \in Sample(7) }
        \cup { [ZeroStrategyMarketDepthLevel EXCEPT !.askPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStrategyMarketDepthLevel EXCEPT !.askSize = one] : one \in Sample(5) }
        \cup { [ZeroStrategyMarketDepthLevel EXCEPT !.numberOfAskOrders = one] : one \in Sample(2) }

(* A run of Strategy Market Depth Level, written one after another *)
RECURSIVE EncodeStrategyMarketDepthLevelList(_)
EncodeStrategyMarketDepthLevelList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeStrategyMarketDepthLevel(Head(messages)) \o EncodeStrategyMarketDepthLevelList(Tail(messages))

(* As many Strategy Market Depth Level as the field that counts them says *)
RECURSIVE ReadStrategyMarketDepthLevelList(_, _)
ReadStrategyMarketDepthLevelList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeStrategyMarketDepthLevel(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadStrategyMarketDepthLevelList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Strategy Market Depth Level of each kind, for the lists that carry them *)
OneStrategyMarketDepthLevel == { ZeroStrategyMarketDepthLevel }

(***************************************************************************)
(* Strategy Market Depth Message                                           *)
(***************************************************************************)

StrategyMarketDepthMessage ==
    [ longMessageHeader        : LongMessageHeader20,
      exchangeId               : Sample(1),
      symbol                   : Sample(30),
      instrumentStatusMarker   : Sample(1),
      strategyMarketDepthLevel : SampleLists(OneStrategyMarketDepthLevel) ]

EncodeStrategyMarketDepthMessage(message) ==
    EncodeLongMessageHeader20(message.longMessageHeader)
        \o message.exchangeId
        \o message.symbol
        \o message.instrumentStatusMarker
        \o EncodeDigits(Len(message.strategyMarketDepthLevel), 1)
        \o EncodeStrategyMarketDepthLevelList(message.strategyMarketDepthLevel)

DecodeStrategyMarketDepthMessage(bytes) ==
    LET longMessageHeader == DecodeLongMessageHeader20(bytes) IN IF ~longMessageHeader.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(longMessageHeader.rest, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET symbol == ReadBytes(exchangeId.rest, 30) IN IF ~symbol.ok THEN Fail ELSE
    LET instrumentStatusMarker == ReadBytes(symbol.rest, 1) IN IF ~instrumentStatusMarker.ok THEN Fail ELSE
    LET numberOfLevel == ReadDigits(instrumentStatusMarker.rest, 1) IN IF ~numberOfLevel.ok THEN Fail ELSE
    LET strategyMarketDepthLevel == ReadStrategyMarketDepthLevelList(numberOfLevel.rest, numberOfLevel.value) IN IF ~strategyMarketDepthLevel.ok THEN Fail ELSE
    Ok([ longMessageHeader        |-> longMessageHeader.value,
         exchangeId               |-> exchangeId.value,
         symbol                   |-> symbol.value,
         instrumentStatusMarker   |-> instrumentStatusMarker.value,
         strategyMarketDepthLevel |-> strategyMarketDepthLevel.value ], strategyMarketDepthLevel.rest)

ZeroStrategyMarketDepthMessage ==
    [ longMessageHeader        |-> ZeroLongMessageHeader20,
      exchangeId               |-> [i \in 1 .. 1 |-> 0],
      symbol                   |-> [i \in 1 .. 30 |-> 0],
      instrumentStatusMarker   |-> [i \in 1 .. 1 |-> 0],
      strategyMarketDepthLevel |-> << >> ]

(* Strategy Market Depth Message at zero, then each field in turn at the values it is checked at *)
CheckedStrategyMarketDepthMessage ==
    { ZeroStrategyMarketDepthMessage }
        \cup { [ZeroStrategyMarketDepthMessage EXCEPT !.longMessageHeader = one] : one \in CheckedLongMessageHeader20 }
        \cup { [ZeroStrategyMarketDepthMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroStrategyMarketDepthMessage EXCEPT !.symbol = one] : one \in Sample(30) }
        \cup { [ZeroStrategyMarketDepthMessage EXCEPT !.instrumentStatusMarker = one] : one \in Sample(1) }
        \cup { [ZeroStrategyMarketDepthMessage EXCEPT !.strategyMarketDepthLevel = one] : one \in SampleLists(OneStrategyMarketDepthLevel) }

(***************************************************************************)
(* Long Message Header: 12 bytes                                           *)
(***************************************************************************)

LongMessageHeader21 ==
    [ messageTimestamp : Sample(12) ]

EncodeLongMessageHeader21(message) ==
    message.messageTimestamp

DecodeLongMessageHeader21(bytes) ==
    LET messageTimestamp == ReadBytes(bytes, 12) IN IF ~messageTimestamp.ok THEN Fail ELSE
    Ok([ messageTimestamp |-> messageTimestamp.value ], messageTimestamp.rest)

ZeroLongMessageHeader21 ==
    [ messageTimestamp |-> [i \in 1 .. 12 |-> 0] ]

(* Long Message Header at zero, then each field in turn at the values it is checked at *)
CheckedLongMessageHeader21 ==
    { ZeroLongMessageHeader21 }
        \cup { [ZeroLongMessageHeader21 EXCEPT !.messageTimestamp = one] : one \in Sample(12) }

(***************************************************************************)
(* Option Symbol: 20 bytes                                                 *)
(***************************************************************************)

OptionSymbol6 ==
    [ root                         : Sample(6),
      expiryMonth                  : Sample(1),
      filler1                      : Sample(1),
      strikePrice                  : Sample(7),
      strikePriceFractionIndicator : Sample(1),
      expiryYear                   : Sample(2),
      expiryDay                    : Sample(2) ]

EncodeOptionSymbol6(message) ==
    message.root
        \o message.expiryMonth
        \o message.filler1
        \o message.strikePrice
        \o message.strikePriceFractionIndicator
        \o message.expiryYear
        \o message.expiryDay

DecodeOptionSymbol6(bytes) ==
    LET root == ReadBytes(bytes, 6) IN IF ~root.ok THEN Fail ELSE
    LET expiryMonth == ReadBytes(root.rest, 1) IN IF ~expiryMonth.ok THEN Fail ELSE
    LET filler1 == ReadBytes(expiryMonth.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(filler1.rest, 7) IN IF ~strikePrice.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePrice.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(strikePriceFractionIndicator.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ root                         |-> root.value,
         expiryMonth                  |-> expiryMonth.value,
         filler1                      |-> filler1.value,
         strikePrice                  |-> strikePrice.value,
         strikePriceFractionIndicator |-> strikePriceFractionIndicator.value,
         expiryYear                   |-> expiryYear.value,
         expiryDay                    |-> expiryDay.value ], expiryDay.rest)

ZeroOptionSymbol6 ==
    [ root                         |-> [i \in 1 .. 6 |-> 0],
      expiryMonth                  |-> [i \in 1 .. 1 |-> 0],
      filler1                      |-> [i \in 1 .. 1 |-> 0],
      strikePrice                  |-> [i \in 1 .. 7 |-> 0],
      strikePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      expiryYear                   |-> [i \in 1 .. 2 |-> 0],
      expiryDay                    |-> [i \in 1 .. 2 |-> 0] ]

(* Option Symbol at zero, then each field in turn at the values it is checked at *)
CheckedOptionSymbol6 ==
    { ZeroOptionSymbol6 }
        \cup { [ZeroOptionSymbol6 EXCEPT !.root = one] : one \in Sample(6) }
        \cup { [ZeroOptionSymbol6 EXCEPT !.expiryMonth = one] : one \in Sample(1) }
        \cup { [ZeroOptionSymbol6 EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroOptionSymbol6 EXCEPT !.strikePrice = one] : one \in Sample(7) }
        \cup { [ZeroOptionSymbol6 EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionSymbol6 EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroOptionSymbol6 EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Option Trade Cancellation Message: 74 bytes                             *)
(***************************************************************************)

OptionTradeCancellationMessage ==
    [ longMessageHeader           : LongMessageHeader21,
      exchangeId                  : Sample(1),
      optionSymbol                : OptionSymbol6,
      volume                      : Sample(8),
      tradePrice                  : Sample(7),
      tradePriceFractionIndicator : Sample(1),
      filler6                     : Sample(6),
      tradeTimestamp              : Sample(9),
      filler1                     : Sample(1),
      priceIndicatorMarker        : Sample(1),
      tradeNumber                 : Sample(8) ]

EncodeOptionTradeCancellationMessage(message) ==
    EncodeLongMessageHeader21(message.longMessageHeader)
        \o message.exchangeId
        \o EncodeOptionSymbol6(message.optionSymbol)
        \o message.volume
        \o message.tradePrice
        \o message.tradePriceFractionIndicator
        \o message.filler6
        \o message.tradeTimestamp
        \o message.filler1
        \o message.priceIndicatorMarker
        \o message.tradeNumber

DecodeOptionTradeCancellationMessage(bytes) ==
    LET longMessageHeader == DecodeLongMessageHeader21(bytes) IN IF ~longMessageHeader.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(longMessageHeader.rest, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET optionSymbol == DecodeOptionSymbol6(exchangeId.rest) IN IF ~optionSymbol.ok THEN Fail ELSE
    LET volume == ReadBytes(optionSymbol.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(volume.rest, 7) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradePriceFractionIndicator == ReadBytes(tradePrice.rest, 1) IN IF ~tradePriceFractionIndicator.ok THEN Fail ELSE
    LET filler6 == ReadBytes(tradePriceFractionIndicator.rest, 6) IN IF ~filler6.ok THEN Fail ELSE
    LET tradeTimestamp == ReadBytes(filler6.rest, 9) IN IF ~tradeTimestamp.ok THEN Fail ELSE
    LET filler1 == ReadBytes(tradeTimestamp.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET priceIndicatorMarker == ReadBytes(filler1.rest, 1) IN IF ~priceIndicatorMarker.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(priceIndicatorMarker.rest, 8) IN IF ~tradeNumber.ok THEN Fail ELSE
    Ok([ longMessageHeader           |-> longMessageHeader.value,
         exchangeId                  |-> exchangeId.value,
         optionSymbol                |-> optionSymbol.value,
         volume                      |-> volume.value,
         tradePrice                  |-> tradePrice.value,
         tradePriceFractionIndicator |-> tradePriceFractionIndicator.value,
         filler6                     |-> filler6.value,
         tradeTimestamp              |-> tradeTimestamp.value,
         filler1                     |-> filler1.value,
         priceIndicatorMarker        |-> priceIndicatorMarker.value,
         tradeNumber                 |-> tradeNumber.value ], tradeNumber.rest)

ZeroOptionTradeCancellationMessage ==
    [ longMessageHeader           |-> ZeroLongMessageHeader21,
      exchangeId                  |-> [i \in 1 .. 1 |-> 0],
      optionSymbol                |-> ZeroOptionSymbol6,
      volume                      |-> [i \in 1 .. 8 |-> 0],
      tradePrice                  |-> [i \in 1 .. 7 |-> 0],
      tradePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      filler6                     |-> [i \in 1 .. 6 |-> 0],
      tradeTimestamp              |-> [i \in 1 .. 9 |-> 0],
      filler1                     |-> [i \in 1 .. 1 |-> 0],
      priceIndicatorMarker        |-> [i \in 1 .. 1 |-> 0],
      tradeNumber                 |-> [i \in 1 .. 8 |-> 0] ]

(* Option Trade Cancellation Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionTradeCancellationMessage ==
    { ZeroOptionTradeCancellationMessage }
        \cup { [ZeroOptionTradeCancellationMessage EXCEPT !.longMessageHeader = one] : one \in CheckedLongMessageHeader21 }
        \cup { [ZeroOptionTradeCancellationMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeCancellationMessage EXCEPT !.optionSymbol = one] : one \in CheckedOptionSymbol6 }
        \cup { [ZeroOptionTradeCancellationMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroOptionTradeCancellationMessage EXCEPT !.tradePrice = one] : one \in Sample(7) }
        \cup { [ZeroOptionTradeCancellationMessage EXCEPT !.tradePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeCancellationMessage EXCEPT !.filler6 = one] : one \in Sample(6) }
        \cup { [ZeroOptionTradeCancellationMessage EXCEPT !.tradeTimestamp = one] : one \in Sample(9) }
        \cup { [ZeroOptionTradeCancellationMessage EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeCancellationMessage EXCEPT !.priceIndicatorMarker = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeCancellationMessage EXCEPT !.tradeNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Long Message Header: 12 bytes                                           *)
(***************************************************************************)

LongMessageHeader22 ==
    [ messageTimestamp : Sample(12) ]

EncodeLongMessageHeader22(message) ==
    message.messageTimestamp

DecodeLongMessageHeader22(bytes) ==
    LET messageTimestamp == ReadBytes(bytes, 12) IN IF ~messageTimestamp.ok THEN Fail ELSE
    Ok([ messageTimestamp |-> messageTimestamp.value ], messageTimestamp.rest)

ZeroLongMessageHeader22 ==
    [ messageTimestamp |-> [i \in 1 .. 12 |-> 0] ]

(* Long Message Header at zero, then each field in turn at the values it is checked at *)
CheckedLongMessageHeader22 ==
    { ZeroLongMessageHeader22 }
        \cup { [ZeroLongMessageHeader22 EXCEPT !.messageTimestamp = one] : one \in Sample(12) }

(***************************************************************************)
(* Future Option Symbol: 20 bytes                                          *)
(***************************************************************************)

FutureOptionSymbol6 ==
    [ root                         : Sample(6),
      symbolMonth                  : Sample(1),
      symbolYear                   : Sample(2),
      expiryDay                    : Sample(2),
      callPutCode                  : Sample(1),
      strikePrice                  : Sample(7),
      strikePriceFractionIndicator : Sample(1) ]

EncodeFutureOptionSymbol6(message) ==
    message.root
        \o message.symbolMonth
        \o message.symbolYear
        \o message.expiryDay
        \o message.callPutCode
        \o message.strikePrice
        \o message.strikePriceFractionIndicator

DecodeFutureOptionSymbol6(bytes) ==
    LET root == ReadBytes(bytes, 6) IN IF ~root.ok THEN Fail ELSE
    LET symbolMonth == ReadBytes(root.rest, 1) IN IF ~symbolMonth.ok THEN Fail ELSE
    LET symbolYear == ReadBytes(symbolMonth.rest, 2) IN IF ~symbolYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(symbolYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET callPutCode == ReadBytes(expiryDay.rest, 1) IN IF ~callPutCode.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(callPutCode.rest, 7) IN IF ~strikePrice.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePrice.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    Ok([ root                         |-> root.value,
         symbolMonth                  |-> symbolMonth.value,
         symbolYear                   |-> symbolYear.value,
         expiryDay                    |-> expiryDay.value,
         callPutCode                  |-> callPutCode.value,
         strikePrice                  |-> strikePrice.value,
         strikePriceFractionIndicator |-> strikePriceFractionIndicator.value ], strikePriceFractionIndicator.rest)

ZeroFutureOptionSymbol6 ==
    [ root                         |-> [i \in 1 .. 6 |-> 0],
      symbolMonth                  |-> [i \in 1 .. 1 |-> 0],
      symbolYear                   |-> [i \in 1 .. 2 |-> 0],
      expiryDay                    |-> [i \in 1 .. 2 |-> 0],
      callPutCode                  |-> [i \in 1 .. 1 |-> 0],
      strikePrice                  |-> [i \in 1 .. 7 |-> 0],
      strikePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Future Option Symbol at zero, then each field in turn at the values it is checked at *)
CheckedFutureOptionSymbol6 ==
    { ZeroFutureOptionSymbol6 }
        \cup { [ZeroFutureOptionSymbol6 EXCEPT !.root = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionSymbol6 EXCEPT !.symbolMonth = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionSymbol6 EXCEPT !.symbolYear = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionSymbol6 EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionSymbol6 EXCEPT !.callPutCode = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionSymbol6 EXCEPT !.strikePrice = one] : one \in Sample(7) }
        \cup { [ZeroFutureOptionSymbol6 EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Future Options Trade Cancellation Message: 75 bytes                     *)
(***************************************************************************)

FutureOptionsTradeCancellationMessage ==
    [ longMessageHeader      : LongMessageHeader22,
      exchangeId             : Sample(1),
      futureOptionSymbol     : FutureOptionSymbol6,
      volume                 : Sample(8),
      price                  : Sample(7),
      priceFractionIndicator : Sample(1),
      priceIndicatorMarker   : Sample(1),
      filler6                : Sample(6),
      tradeTimestamp         : Sample(9),
      filler2                : Sample(2),
      tradeNumber            : Sample(8) ]

EncodeFutureOptionsTradeCancellationMessage(message) ==
    EncodeLongMessageHeader22(message.longMessageHeader)
        \o message.exchangeId
        \o EncodeFutureOptionSymbol6(message.futureOptionSymbol)
        \o message.volume
        \o message.price
        \o message.priceFractionIndicator
        \o message.priceIndicatorMarker
        \o message.filler6
        \o message.tradeTimestamp
        \o message.filler2
        \o message.tradeNumber

DecodeFutureOptionsTradeCancellationMessage(bytes) ==
    LET longMessageHeader == DecodeLongMessageHeader22(bytes) IN IF ~longMessageHeader.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(longMessageHeader.rest, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET futureOptionSymbol == DecodeFutureOptionSymbol6(exchangeId.rest) IN IF ~futureOptionSymbol.ok THEN Fail ELSE
    LET volume == ReadBytes(futureOptionSymbol.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET price == ReadBytes(volume.rest, 7) IN IF ~price.ok THEN Fail ELSE
    LET priceFractionIndicator == ReadBytes(price.rest, 1) IN IF ~priceFractionIndicator.ok THEN Fail ELSE
    LET priceIndicatorMarker == ReadBytes(priceFractionIndicator.rest, 1) IN IF ~priceIndicatorMarker.ok THEN Fail ELSE
    LET filler6 == ReadBytes(priceIndicatorMarker.rest, 6) IN IF ~filler6.ok THEN Fail ELSE
    LET tradeTimestamp == ReadBytes(filler6.rest, 9) IN IF ~tradeTimestamp.ok THEN Fail ELSE
    LET filler2 == ReadBytes(tradeTimestamp.rest, 2) IN IF ~filler2.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(filler2.rest, 8) IN IF ~tradeNumber.ok THEN Fail ELSE
    Ok([ longMessageHeader      |-> longMessageHeader.value,
         exchangeId             |-> exchangeId.value,
         futureOptionSymbol     |-> futureOptionSymbol.value,
         volume                 |-> volume.value,
         price                  |-> price.value,
         priceFractionIndicator |-> priceFractionIndicator.value,
         priceIndicatorMarker   |-> priceIndicatorMarker.value,
         filler6                |-> filler6.value,
         tradeTimestamp         |-> tradeTimestamp.value,
         filler2                |-> filler2.value,
         tradeNumber            |-> tradeNumber.value ], tradeNumber.rest)

ZeroFutureOptionsTradeCancellationMessage ==
    [ longMessageHeader      |-> ZeroLongMessageHeader22,
      exchangeId             |-> [i \in 1 .. 1 |-> 0],
      futureOptionSymbol     |-> ZeroFutureOptionSymbol6,
      volume                 |-> [i \in 1 .. 8 |-> 0],
      price                  |-> [i \in 1 .. 7 |-> 0],
      priceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      priceIndicatorMarker   |-> [i \in 1 .. 1 |-> 0],
      filler6                |-> [i \in 1 .. 6 |-> 0],
      tradeTimestamp         |-> [i \in 1 .. 9 |-> 0],
      filler2                |-> [i \in 1 .. 2 |-> 0],
      tradeNumber            |-> [i \in 1 .. 8 |-> 0] ]

(* Future Options Trade Cancellation Message at zero, then each field in turn at the values it is checked at *)
CheckedFutureOptionsTradeCancellationMessage ==
    { ZeroFutureOptionsTradeCancellationMessage }
        \cup { [ZeroFutureOptionsTradeCancellationMessage EXCEPT !.longMessageHeader = one] : one \in CheckedLongMessageHeader22 }
        \cup { [ZeroFutureOptionsTradeCancellationMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsTradeCancellationMessage EXCEPT !.futureOptionSymbol = one] : one \in CheckedFutureOptionSymbol6 }
        \cup { [ZeroFutureOptionsTradeCancellationMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroFutureOptionsTradeCancellationMessage EXCEPT !.price = one] : one \in Sample(7) }
        \cup { [ZeroFutureOptionsTradeCancellationMessage EXCEPT !.priceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsTradeCancellationMessage EXCEPT !.priceIndicatorMarker = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsTradeCancellationMessage EXCEPT !.filler6 = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionsTradeCancellationMessage EXCEPT !.tradeTimestamp = one] : one \in Sample(9) }
        \cup { [ZeroFutureOptionsTradeCancellationMessage EXCEPT !.filler2 = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionsTradeCancellationMessage EXCEPT !.tradeNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Long Message Header: 12 bytes                                           *)
(***************************************************************************)

LongMessageHeader23 ==
    [ messageTimestamp : Sample(12) ]

EncodeLongMessageHeader23(message) ==
    message.messageTimestamp

DecodeLongMessageHeader23(bytes) ==
    LET messageTimestamp == ReadBytes(bytes, 12) IN IF ~messageTimestamp.ok THEN Fail ELSE
    Ok([ messageTimestamp |-> messageTimestamp.value ], messageTimestamp.rest)

ZeroLongMessageHeader23 ==
    [ messageTimestamp |-> [i \in 1 .. 12 |-> 0] ]

(* Long Message Header at zero, then each field in turn at the values it is checked at *)
CheckedLongMessageHeader23 ==
    { ZeroLongMessageHeader23 }
        \cup { [ZeroLongMessageHeader23 EXCEPT !.messageTimestamp = one] : one \in Sample(12) }

(***************************************************************************)
(* Future Product: 11 bytes                                                *)
(***************************************************************************)

FutureProduct6 ==
    [ root        : Sample(6),
      symbolMonth : Sample(1),
      symbolYear  : Sample(2),
      expiryDay   : Sample(2) ]

EncodeFutureProduct6(message) ==
    message.root
        \o message.symbolMonth
        \o message.symbolYear
        \o message.expiryDay

DecodeFutureProduct6(bytes) ==
    LET root == ReadBytes(bytes, 6) IN IF ~root.ok THEN Fail ELSE
    LET symbolMonth == ReadBytes(root.rest, 1) IN IF ~symbolMonth.ok THEN Fail ELSE
    LET symbolYear == ReadBytes(symbolMonth.rest, 2) IN IF ~symbolYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(symbolYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ root        |-> root.value,
         symbolMonth |-> symbolMonth.value,
         symbolYear  |-> symbolYear.value,
         expiryDay   |-> expiryDay.value ], expiryDay.rest)

ZeroFutureProduct6 ==
    [ root        |-> [i \in 1 .. 6 |-> 0],
      symbolMonth |-> [i \in 1 .. 1 |-> 0],
      symbolYear  |-> [i \in 1 .. 2 |-> 0],
      expiryDay   |-> [i \in 1 .. 2 |-> 0] ]

(* Future Product at zero, then each field in turn at the values it is checked at *)
CheckedFutureProduct6 ==
    { ZeroFutureProduct6 }
        \cup { [ZeroFutureProduct6 EXCEPT !.root = one] : one \in Sample(6) }
        \cup { [ZeroFutureProduct6 EXCEPT !.symbolMonth = one] : one \in Sample(1) }
        \cup { [ZeroFutureProduct6 EXCEPT !.symbolYear = one] : one \in Sample(2) }
        \cup { [ZeroFutureProduct6 EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Futures Trade Cancellation Message: 64 bytes                            *)
(***************************************************************************)

FuturesTradeCancellationMessage ==
    [ longMessageHeader           : LongMessageHeader23,
      exchangeId                  : Sample(1),
      futureProduct               : FutureProduct6,
      volume                      : Sample(8),
      tradePrice                  : Sample(7),
      tradePriceFractionIndicator : Sample(1),
      filler6                     : Sample(6),
      tradeTimestamp              : Sample(9),
      priceIndicatorMarker        : Sample(1),
      tradeNumber                 : Sample(8) ]

EncodeFuturesTradeCancellationMessage(message) ==
    EncodeLongMessageHeader23(message.longMessageHeader)
        \o message.exchangeId
        \o EncodeFutureProduct6(message.futureProduct)
        \o message.volume
        \o message.tradePrice
        \o message.tradePriceFractionIndicator
        \o message.filler6
        \o message.tradeTimestamp
        \o message.priceIndicatorMarker
        \o message.tradeNumber

DecodeFuturesTradeCancellationMessage(bytes) ==
    LET longMessageHeader == DecodeLongMessageHeader23(bytes) IN IF ~longMessageHeader.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(longMessageHeader.rest, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET futureProduct == DecodeFutureProduct6(exchangeId.rest) IN IF ~futureProduct.ok THEN Fail ELSE
    LET volume == ReadBytes(futureProduct.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(volume.rest, 7) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradePriceFractionIndicator == ReadBytes(tradePrice.rest, 1) IN IF ~tradePriceFractionIndicator.ok THEN Fail ELSE
    LET filler6 == ReadBytes(tradePriceFractionIndicator.rest, 6) IN IF ~filler6.ok THEN Fail ELSE
    LET tradeTimestamp == ReadBytes(filler6.rest, 9) IN IF ~tradeTimestamp.ok THEN Fail ELSE
    LET priceIndicatorMarker == ReadBytes(tradeTimestamp.rest, 1) IN IF ~priceIndicatorMarker.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(priceIndicatorMarker.rest, 8) IN IF ~tradeNumber.ok THEN Fail ELSE
    Ok([ longMessageHeader           |-> longMessageHeader.value,
         exchangeId                  |-> exchangeId.value,
         futureProduct               |-> futureProduct.value,
         volume                      |-> volume.value,
         tradePrice                  |-> tradePrice.value,
         tradePriceFractionIndicator |-> tradePriceFractionIndicator.value,
         filler6                     |-> filler6.value,
         tradeTimestamp              |-> tradeTimestamp.value,
         priceIndicatorMarker        |-> priceIndicatorMarker.value,
         tradeNumber                 |-> tradeNumber.value ], tradeNumber.rest)

ZeroFuturesTradeCancellationMessage ==
    [ longMessageHeader           |-> ZeroLongMessageHeader23,
      exchangeId                  |-> [i \in 1 .. 1 |-> 0],
      futureProduct               |-> ZeroFutureProduct6,
      volume                      |-> [i \in 1 .. 8 |-> 0],
      tradePrice                  |-> [i \in 1 .. 7 |-> 0],
      tradePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      filler6                     |-> [i \in 1 .. 6 |-> 0],
      tradeTimestamp              |-> [i \in 1 .. 9 |-> 0],
      priceIndicatorMarker        |-> [i \in 1 .. 1 |-> 0],
      tradeNumber                 |-> [i \in 1 .. 8 |-> 0] ]

(* Futures Trade Cancellation Message at zero, then each field in turn at the values it is checked at *)
CheckedFuturesTradeCancellationMessage ==
    { ZeroFuturesTradeCancellationMessage }
        \cup { [ZeroFuturesTradeCancellationMessage EXCEPT !.longMessageHeader = one] : one \in CheckedLongMessageHeader23 }
        \cup { [ZeroFuturesTradeCancellationMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroFuturesTradeCancellationMessage EXCEPT !.futureProduct = one] : one \in CheckedFutureProduct6 }
        \cup { [ZeroFuturesTradeCancellationMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroFuturesTradeCancellationMessage EXCEPT !.tradePrice = one] : one \in Sample(7) }
        \cup { [ZeroFuturesTradeCancellationMessage EXCEPT !.tradePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFuturesTradeCancellationMessage EXCEPT !.filler6 = one] : one \in Sample(6) }
        \cup { [ZeroFuturesTradeCancellationMessage EXCEPT !.tradeTimestamp = one] : one \in Sample(9) }
        \cup { [ZeroFuturesTradeCancellationMessage EXCEPT !.priceIndicatorMarker = one] : one \in Sample(1) }
        \cup { [ZeroFuturesTradeCancellationMessage EXCEPT !.tradeNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Long Message Header: 12 bytes                                           *)
(***************************************************************************)

LongMessageHeader24 ==
    [ messageTimestamp : Sample(12) ]

EncodeLongMessageHeader24(message) ==
    message.messageTimestamp

DecodeLongMessageHeader24(bytes) ==
    LET messageTimestamp == ReadBytes(bytes, 12) IN IF ~messageTimestamp.ok THEN Fail ELSE
    Ok([ messageTimestamp |-> messageTimestamp.value ], messageTimestamp.rest)

ZeroLongMessageHeader24 ==
    [ messageTimestamp |-> [i \in 1 .. 12 |-> 0] ]

(* Long Message Header at zero, then each field in turn at the values it is checked at *)
CheckedLongMessageHeader24 ==
    { ZeroLongMessageHeader24 }
        \cup { [ZeroLongMessageHeader24 EXCEPT !.messageTimestamp = one] : one \in Sample(12) }

(***************************************************************************)
(* Strategy Trade Cancellation Message: 84 bytes                           *)
(***************************************************************************)

StrategyTradeCancellationMessage ==
    [ longMessageHeader           : LongMessageHeader24,
      exchangeId                  : Sample(1),
      symbol                      : Sample(30),
      volume                      : Sample(8),
      tradePriceSign              : Sample(1),
      tradePrice                  : Sample(7),
      tradePriceFractionIndicator : Sample(1),
      filler6                     : Sample(6),
      tradeTimestamp              : Sample(9),
      filler1                     : Sample(1),
      tradeNumber                 : Sample(8) ]

EncodeStrategyTradeCancellationMessage(message) ==
    EncodeLongMessageHeader24(message.longMessageHeader)
        \o message.exchangeId
        \o message.symbol
        \o message.volume
        \o message.tradePriceSign
        \o message.tradePrice
        \o message.tradePriceFractionIndicator
        \o message.filler6
        \o message.tradeTimestamp
        \o message.filler1
        \o message.tradeNumber

DecodeStrategyTradeCancellationMessage(bytes) ==
    LET longMessageHeader == DecodeLongMessageHeader24(bytes) IN IF ~longMessageHeader.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(longMessageHeader.rest, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET symbol == ReadBytes(exchangeId.rest, 30) IN IF ~symbol.ok THEN Fail ELSE
    LET volume == ReadBytes(symbol.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET tradePriceSign == ReadBytes(volume.rest, 1) IN IF ~tradePriceSign.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(tradePriceSign.rest, 7) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradePriceFractionIndicator == ReadBytes(tradePrice.rest, 1) IN IF ~tradePriceFractionIndicator.ok THEN Fail ELSE
    LET filler6 == ReadBytes(tradePriceFractionIndicator.rest, 6) IN IF ~filler6.ok THEN Fail ELSE
    LET tradeTimestamp == ReadBytes(filler6.rest, 9) IN IF ~tradeTimestamp.ok THEN Fail ELSE
    LET filler1 == ReadBytes(tradeTimestamp.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(filler1.rest, 8) IN IF ~tradeNumber.ok THEN Fail ELSE
    Ok([ longMessageHeader           |-> longMessageHeader.value,
         exchangeId                  |-> exchangeId.value,
         symbol                      |-> symbol.value,
         volume                      |-> volume.value,
         tradePriceSign              |-> tradePriceSign.value,
         tradePrice                  |-> tradePrice.value,
         tradePriceFractionIndicator |-> tradePriceFractionIndicator.value,
         filler6                     |-> filler6.value,
         tradeTimestamp              |-> tradeTimestamp.value,
         filler1                     |-> filler1.value,
         tradeNumber                 |-> tradeNumber.value ], tradeNumber.rest)

ZeroStrategyTradeCancellationMessage ==
    [ longMessageHeader           |-> ZeroLongMessageHeader24,
      exchangeId                  |-> [i \in 1 .. 1 |-> 0],
      symbol                      |-> [i \in 1 .. 30 |-> 0],
      volume                      |-> [i \in 1 .. 8 |-> 0],
      tradePriceSign              |-> [i \in 1 .. 1 |-> 0],
      tradePrice                  |-> [i \in 1 .. 7 |-> 0],
      tradePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      filler6                     |-> [i \in 1 .. 6 |-> 0],
      tradeTimestamp              |-> [i \in 1 .. 9 |-> 0],
      filler1                     |-> [i \in 1 .. 1 |-> 0],
      tradeNumber                 |-> [i \in 1 .. 8 |-> 0] ]

(* Strategy Trade Cancellation Message at zero, then each field in turn at the values it is checked at *)
CheckedStrategyTradeCancellationMessage ==
    { ZeroStrategyTradeCancellationMessage }
        \cup { [ZeroStrategyTradeCancellationMessage EXCEPT !.longMessageHeader = one] : one \in CheckedLongMessageHeader24 }
        \cup { [ZeroStrategyTradeCancellationMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroStrategyTradeCancellationMessage EXCEPT !.symbol = one] : one \in Sample(30) }
        \cup { [ZeroStrategyTradeCancellationMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroStrategyTradeCancellationMessage EXCEPT !.tradePriceSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategyTradeCancellationMessage EXCEPT !.tradePrice = one] : one \in Sample(7) }
        \cup { [ZeroStrategyTradeCancellationMessage EXCEPT !.tradePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStrategyTradeCancellationMessage EXCEPT !.filler6 = one] : one \in Sample(6) }
        \cup { [ZeroStrategyTradeCancellationMessage EXCEPT !.tradeTimestamp = one] : one \in Sample(9) }
        \cup { [ZeroStrategyTradeCancellationMessage EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroStrategyTradeCancellationMessage EXCEPT !.tradeNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Long Message Header: 12 bytes                                           *)
(***************************************************************************)

LongMessageHeader25 ==
    [ messageTimestamp : Sample(12) ]

EncodeLongMessageHeader25(message) ==
    message.messageTimestamp

DecodeLongMessageHeader25(bytes) ==
    LET messageTimestamp == ReadBytes(bytes, 12) IN IF ~messageTimestamp.ok THEN Fail ELSE
    Ok([ messageTimestamp |-> messageTimestamp.value ], messageTimestamp.rest)

ZeroLongMessageHeader25 ==
    [ messageTimestamp |-> [i \in 1 .. 12 |-> 0] ]

(* Long Message Header at zero, then each field in turn at the values it is checked at *)
CheckedLongMessageHeader25 ==
    { ZeroLongMessageHeader25 }
        \cup { [ZeroLongMessageHeader25 EXCEPT !.messageTimestamp = one] : one \in Sample(12) }

(***************************************************************************)
(* Option Symbol: 20 bytes                                                 *)
(***************************************************************************)

OptionSymbol7 ==
    [ root                         : Sample(6),
      expiryMonth                  : Sample(1),
      filler1                      : Sample(1),
      strikePrice                  : Sample(7),
      strikePriceFractionIndicator : Sample(1),
      expiryYear                   : Sample(2),
      expiryDay                    : Sample(2) ]

EncodeOptionSymbol7(message) ==
    message.root
        \o message.expiryMonth
        \o message.filler1
        \o message.strikePrice
        \o message.strikePriceFractionIndicator
        \o message.expiryYear
        \o message.expiryDay

DecodeOptionSymbol7(bytes) ==
    LET root == ReadBytes(bytes, 6) IN IF ~root.ok THEN Fail ELSE
    LET expiryMonth == ReadBytes(root.rest, 1) IN IF ~expiryMonth.ok THEN Fail ELSE
    LET filler1 == ReadBytes(expiryMonth.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(filler1.rest, 7) IN IF ~strikePrice.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePrice.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(strikePriceFractionIndicator.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ root                         |-> root.value,
         expiryMonth                  |-> expiryMonth.value,
         filler1                      |-> filler1.value,
         strikePrice                  |-> strikePrice.value,
         strikePriceFractionIndicator |-> strikePriceFractionIndicator.value,
         expiryYear                   |-> expiryYear.value,
         expiryDay                    |-> expiryDay.value ], expiryDay.rest)

ZeroOptionSymbol7 ==
    [ root                         |-> [i \in 1 .. 6 |-> 0],
      expiryMonth                  |-> [i \in 1 .. 1 |-> 0],
      filler1                      |-> [i \in 1 .. 1 |-> 0],
      strikePrice                  |-> [i \in 1 .. 7 |-> 0],
      strikePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      expiryYear                   |-> [i \in 1 .. 2 |-> 0],
      expiryDay                    |-> [i \in 1 .. 2 |-> 0] ]

(* Option Symbol at zero, then each field in turn at the values it is checked at *)
CheckedOptionSymbol7 ==
    { ZeroOptionSymbol7 }
        \cup { [ZeroOptionSymbol7 EXCEPT !.root = one] : one \in Sample(6) }
        \cup { [ZeroOptionSymbol7 EXCEPT !.expiryMonth = one] : one \in Sample(1) }
        \cup { [ZeroOptionSymbol7 EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroOptionSymbol7 EXCEPT !.strikePrice = one] : one \in Sample(7) }
        \cup { [ZeroOptionSymbol7 EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionSymbol7 EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroOptionSymbol7 EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Option Instrument Keys Message: 145 bytes                               *)
(***************************************************************************)

OptionInstrumentKeysMessage ==
    [ longMessageHeader                      : LongMessageHeader25,
      exchangeId                             : Sample(1),
      optionSymbol                           : OptionSymbol7,
      strikePriceCurrency                    : Sample(3),
      maximumNumberOfContractsPerOrder       : Sample(6),
      minimumNumberOfContractsPerOrder       : Sample(6),
      maximumThresholdPrice                  : Sample(7),
      maximumThresholdPriceFractionIndicator : Sample(1),
      minimumThresholdPrice                  : Sample(7),
      minimumThresholdPriceFractionIndicator : Sample(1),
      tickIncrement                          : Sample(7),
      tickIncrementFractionIndicator         : Sample(1),
      optionType                             : Sample(1),
      marketFlowIndicator                    : Sample(2),
      groupInstrument                        : Sample(2),
      instrument                             : Sample(4),
      instrumentExternalCode                 : Sample(30),
      optionMarker                           : Sample(2),
      underlyingSymbolRoot                   : Sample(12),
      contractSize                           : Sample(8),
      tickValue                              : Sample(7),
      tickValueFractionIndicator             : Sample(1),
      currency                               : Sample(3),
      deliveryType                           : Sample(1) ]

EncodeOptionInstrumentKeysMessage(message) ==
    EncodeLongMessageHeader25(message.longMessageHeader)
        \o message.exchangeId
        \o EncodeOptionSymbol7(message.optionSymbol)
        \o message.strikePriceCurrency
        \o message.maximumNumberOfContractsPerOrder
        \o message.minimumNumberOfContractsPerOrder
        \o message.maximumThresholdPrice
        \o message.maximumThresholdPriceFractionIndicator
        \o message.minimumThresholdPrice
        \o message.minimumThresholdPriceFractionIndicator
        \o message.tickIncrement
        \o message.tickIncrementFractionIndicator
        \o message.optionType
        \o message.marketFlowIndicator
        \o message.groupInstrument
        \o message.instrument
        \o message.instrumentExternalCode
        \o message.optionMarker
        \o message.underlyingSymbolRoot
        \o message.contractSize
        \o message.tickValue
        \o message.tickValueFractionIndicator
        \o message.currency
        \o message.deliveryType

DecodeOptionInstrumentKeysMessage(bytes) ==
    LET longMessageHeader == DecodeLongMessageHeader25(bytes) IN IF ~longMessageHeader.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(longMessageHeader.rest, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET optionSymbol == DecodeOptionSymbol7(exchangeId.rest) IN IF ~optionSymbol.ok THEN Fail ELSE
    LET strikePriceCurrency == ReadBytes(optionSymbol.rest, 3) IN IF ~strikePriceCurrency.ok THEN Fail ELSE
    LET maximumNumberOfContractsPerOrder == ReadBytes(strikePriceCurrency.rest, 6) IN IF ~maximumNumberOfContractsPerOrder.ok THEN Fail ELSE
    LET minimumNumberOfContractsPerOrder == ReadBytes(maximumNumberOfContractsPerOrder.rest, 6) IN IF ~minimumNumberOfContractsPerOrder.ok THEN Fail ELSE
    LET maximumThresholdPrice == ReadBytes(minimumNumberOfContractsPerOrder.rest, 7) IN IF ~maximumThresholdPrice.ok THEN Fail ELSE
    LET maximumThresholdPriceFractionIndicator == ReadBytes(maximumThresholdPrice.rest, 1) IN IF ~maximumThresholdPriceFractionIndicator.ok THEN Fail ELSE
    LET minimumThresholdPrice == ReadBytes(maximumThresholdPriceFractionIndicator.rest, 7) IN IF ~minimumThresholdPrice.ok THEN Fail ELSE
    LET minimumThresholdPriceFractionIndicator == ReadBytes(minimumThresholdPrice.rest, 1) IN IF ~minimumThresholdPriceFractionIndicator.ok THEN Fail ELSE
    LET tickIncrement == ReadBytes(minimumThresholdPriceFractionIndicator.rest, 7) IN IF ~tickIncrement.ok THEN Fail ELSE
    LET tickIncrementFractionIndicator == ReadBytes(tickIncrement.rest, 1) IN IF ~tickIncrementFractionIndicator.ok THEN Fail ELSE
    LET optionType == ReadBytes(tickIncrementFractionIndicator.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET marketFlowIndicator == ReadBytes(optionType.rest, 2) IN IF ~marketFlowIndicator.ok THEN Fail ELSE
    LET groupInstrument == ReadBytes(marketFlowIndicator.rest, 2) IN IF ~groupInstrument.ok THEN Fail ELSE
    LET instrument == ReadBytes(groupInstrument.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET instrumentExternalCode == ReadBytes(instrument.rest, 30) IN IF ~instrumentExternalCode.ok THEN Fail ELSE
    LET optionMarker == ReadBytes(instrumentExternalCode.rest, 2) IN IF ~optionMarker.ok THEN Fail ELSE
    LET underlyingSymbolRoot == ReadBytes(optionMarker.rest, 12) IN IF ~underlyingSymbolRoot.ok THEN Fail ELSE
    LET contractSize == ReadBytes(underlyingSymbolRoot.rest, 8) IN IF ~contractSize.ok THEN Fail ELSE
    LET tickValue == ReadBytes(contractSize.rest, 7) IN IF ~tickValue.ok THEN Fail ELSE
    LET tickValueFractionIndicator == ReadBytes(tickValue.rest, 1) IN IF ~tickValueFractionIndicator.ok THEN Fail ELSE
    LET currency == ReadBytes(tickValueFractionIndicator.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET deliveryType == ReadBytes(currency.rest, 1) IN IF ~deliveryType.ok THEN Fail ELSE
    Ok([ longMessageHeader                      |-> longMessageHeader.value,
         exchangeId                             |-> exchangeId.value,
         optionSymbol                           |-> optionSymbol.value,
         strikePriceCurrency                    |-> strikePriceCurrency.value,
         maximumNumberOfContractsPerOrder       |-> maximumNumberOfContractsPerOrder.value,
         minimumNumberOfContractsPerOrder       |-> minimumNumberOfContractsPerOrder.value,
         maximumThresholdPrice                  |-> maximumThresholdPrice.value,
         maximumThresholdPriceFractionIndicator |-> maximumThresholdPriceFractionIndicator.value,
         minimumThresholdPrice                  |-> minimumThresholdPrice.value,
         minimumThresholdPriceFractionIndicator |-> minimumThresholdPriceFractionIndicator.value,
         tickIncrement                          |-> tickIncrement.value,
         tickIncrementFractionIndicator         |-> tickIncrementFractionIndicator.value,
         optionType                             |-> optionType.value,
         marketFlowIndicator                    |-> marketFlowIndicator.value,
         groupInstrument                        |-> groupInstrument.value,
         instrument                             |-> instrument.value,
         instrumentExternalCode                 |-> instrumentExternalCode.value,
         optionMarker                           |-> optionMarker.value,
         underlyingSymbolRoot                   |-> underlyingSymbolRoot.value,
         contractSize                           |-> contractSize.value,
         tickValue                              |-> tickValue.value,
         tickValueFractionIndicator             |-> tickValueFractionIndicator.value,
         currency                               |-> currency.value,
         deliveryType                           |-> deliveryType.value ], deliveryType.rest)

ZeroOptionInstrumentKeysMessage ==
    [ longMessageHeader                      |-> ZeroLongMessageHeader25,
      exchangeId                             |-> [i \in 1 .. 1 |-> 0],
      optionSymbol                           |-> ZeroOptionSymbol7,
      strikePriceCurrency                    |-> [i \in 1 .. 3 |-> 0],
      maximumNumberOfContractsPerOrder       |-> [i \in 1 .. 6 |-> 0],
      minimumNumberOfContractsPerOrder       |-> [i \in 1 .. 6 |-> 0],
      maximumThresholdPrice                  |-> [i \in 1 .. 7 |-> 0],
      maximumThresholdPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      minimumThresholdPrice                  |-> [i \in 1 .. 7 |-> 0],
      minimumThresholdPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      tickIncrement                          |-> [i \in 1 .. 7 |-> 0],
      tickIncrementFractionIndicator         |-> [i \in 1 .. 1 |-> 0],
      optionType                             |-> [i \in 1 .. 1 |-> 0],
      marketFlowIndicator                    |-> [i \in 1 .. 2 |-> 0],
      groupInstrument                        |-> [i \in 1 .. 2 |-> 0],
      instrument                             |-> [i \in 1 .. 4 |-> 0],
      instrumentExternalCode                 |-> [i \in 1 .. 30 |-> 0],
      optionMarker                           |-> [i \in 1 .. 2 |-> 0],
      underlyingSymbolRoot                   |-> [i \in 1 .. 12 |-> 0],
      contractSize                           |-> [i \in 1 .. 8 |-> 0],
      tickValue                              |-> [i \in 1 .. 7 |-> 0],
      tickValueFractionIndicator             |-> [i \in 1 .. 1 |-> 0],
      currency                               |-> [i \in 1 .. 3 |-> 0],
      deliveryType                           |-> [i \in 1 .. 1 |-> 0] ]

(* Option Instrument Keys Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionInstrumentKeysMessage ==
    { ZeroOptionInstrumentKeysMessage }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.longMessageHeader = one] : one \in CheckedLongMessageHeader25 }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.optionSymbol = one] : one \in CheckedOptionSymbol7 }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.strikePriceCurrency = one] : one \in Sample(3) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.maximumNumberOfContractsPerOrder = one] : one \in Sample(6) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.minimumNumberOfContractsPerOrder = one] : one \in Sample(6) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.maximumThresholdPrice = one] : one \in Sample(7) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.maximumThresholdPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.minimumThresholdPrice = one] : one \in Sample(7) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.minimumThresholdPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.tickIncrement = one] : one \in Sample(7) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.tickIncrementFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.marketFlowIndicator = one] : one \in Sample(2) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.groupInstrument = one] : one \in Sample(2) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.instrumentExternalCode = one] : one \in Sample(30) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.optionMarker = one] : one \in Sample(2) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.underlyingSymbolRoot = one] : one \in Sample(12) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.contractSize = one] : one \in Sample(8) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.tickValue = one] : one \in Sample(7) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.tickValueFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.deliveryType = one] : one \in Sample(1) }

(***************************************************************************)
(* Long Message Header: 12 bytes                                           *)
(***************************************************************************)

LongMessageHeader26 ==
    [ messageTimestamp : Sample(12) ]

EncodeLongMessageHeader26(message) ==
    message.messageTimestamp

DecodeLongMessageHeader26(bytes) ==
    LET messageTimestamp == ReadBytes(bytes, 12) IN IF ~messageTimestamp.ok THEN Fail ELSE
    Ok([ messageTimestamp |-> messageTimestamp.value ], messageTimestamp.rest)

ZeroLongMessageHeader26 ==
    [ messageTimestamp |-> [i \in 1 .. 12 |-> 0] ]

(* Long Message Header at zero, then each field in turn at the values it is checked at *)
CheckedLongMessageHeader26 ==
    { ZeroLongMessageHeader26 }
        \cup { [ZeroLongMessageHeader26 EXCEPT !.messageTimestamp = one] : one \in Sample(12) }

(***************************************************************************)
(* Future Option Symbol: 20 bytes                                          *)
(***************************************************************************)

FutureOptionSymbol7 ==
    [ root                         : Sample(6),
      symbolMonth                  : Sample(1),
      symbolYear                   : Sample(2),
      expiryDay                    : Sample(2),
      callPutCode                  : Sample(1),
      strikePrice                  : Sample(7),
      strikePriceFractionIndicator : Sample(1) ]

EncodeFutureOptionSymbol7(message) ==
    message.root
        \o message.symbolMonth
        \o message.symbolYear
        \o message.expiryDay
        \o message.callPutCode
        \o message.strikePrice
        \o message.strikePriceFractionIndicator

DecodeFutureOptionSymbol7(bytes) ==
    LET root == ReadBytes(bytes, 6) IN IF ~root.ok THEN Fail ELSE
    LET symbolMonth == ReadBytes(root.rest, 1) IN IF ~symbolMonth.ok THEN Fail ELSE
    LET symbolYear == ReadBytes(symbolMonth.rest, 2) IN IF ~symbolYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(symbolYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET callPutCode == ReadBytes(expiryDay.rest, 1) IN IF ~callPutCode.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(callPutCode.rest, 7) IN IF ~strikePrice.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePrice.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    Ok([ root                         |-> root.value,
         symbolMonth                  |-> symbolMonth.value,
         symbolYear                   |-> symbolYear.value,
         expiryDay                    |-> expiryDay.value,
         callPutCode                  |-> callPutCode.value,
         strikePrice                  |-> strikePrice.value,
         strikePriceFractionIndicator |-> strikePriceFractionIndicator.value ], strikePriceFractionIndicator.rest)

ZeroFutureOptionSymbol7 ==
    [ root                         |-> [i \in 1 .. 6 |-> 0],
      symbolMonth                  |-> [i \in 1 .. 1 |-> 0],
      symbolYear                   |-> [i \in 1 .. 2 |-> 0],
      expiryDay                    |-> [i \in 1 .. 2 |-> 0],
      callPutCode                  |-> [i \in 1 .. 1 |-> 0],
      strikePrice                  |-> [i \in 1 .. 7 |-> 0],
      strikePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Future Option Symbol at zero, then each field in turn at the values it is checked at *)
CheckedFutureOptionSymbol7 ==
    { ZeroFutureOptionSymbol7 }
        \cup { [ZeroFutureOptionSymbol7 EXCEPT !.root = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionSymbol7 EXCEPT !.symbolMonth = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionSymbol7 EXCEPT !.symbolYear = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionSymbol7 EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionSymbol7 EXCEPT !.callPutCode = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionSymbol7 EXCEPT !.strikePrice = one] : one \in Sample(7) }
        \cup { [ZeroFutureOptionSymbol7 EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Future Options Instrument Keys Message: 145 bytes                       *)
(***************************************************************************)

FutureOptionsInstrumentKeysMessage ==
    [ longMessageHeader                      : LongMessageHeader26,
      exchangeId                             : Sample(1),
      futureOptionSymbol                     : FutureOptionSymbol7,
      expiryDate                             : Sample(6),
      strikePriceCurrency                    : Sample(3),
      maximumNumberOfContractsPerOrder       : Sample(6),
      minimumNumberOfContractsPerOrder       : Sample(6),
      maximumThresholdPrice                  : Sample(7),
      maximumThresholdPriceFractionIndicator : Sample(1),
      minimumThresholdPrice                  : Sample(7),
      minimumThresholdPriceFractionIndicator : Sample(1),
      tickIncrement                          : Sample(7),
      tickIncrementFractionIndicator         : Sample(1),
      marketFlowIndicator                    : Sample(2),
      groupInstrument                        : Sample(2),
      instrument                             : Sample(4),
      instrumentExternalCode                 : Sample(30),
      contractSize                           : Sample(8),
      tickValue                              : Sample(7),
      tickValueFractionIndicator             : Sample(1),
      currency                               : Sample(3),
      deliveryType                           : Sample(1),
      underlyingRootSymbol                   : Sample(6),
      underlyingSymbolMonth                  : Sample(1),
      underlyingSymbolYear                   : Sample(2) ]

EncodeFutureOptionsInstrumentKeysMessage(message) ==
    EncodeLongMessageHeader26(message.longMessageHeader)
        \o message.exchangeId
        \o EncodeFutureOptionSymbol7(message.futureOptionSymbol)
        \o message.expiryDate
        \o message.strikePriceCurrency
        \o message.maximumNumberOfContractsPerOrder
        \o message.minimumNumberOfContractsPerOrder
        \o message.maximumThresholdPrice
        \o message.maximumThresholdPriceFractionIndicator
        \o message.minimumThresholdPrice
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
        \o message.underlyingRootSymbol
        \o message.underlyingSymbolMonth
        \o message.underlyingSymbolYear

DecodeFutureOptionsInstrumentKeysMessage(bytes) ==
    LET longMessageHeader == DecodeLongMessageHeader26(bytes) IN IF ~longMessageHeader.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(longMessageHeader.rest, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET futureOptionSymbol == DecodeFutureOptionSymbol7(exchangeId.rest) IN IF ~futureOptionSymbol.ok THEN Fail ELSE
    LET expiryDate == ReadBytes(futureOptionSymbol.rest, 6) IN IF ~expiryDate.ok THEN Fail ELSE
    LET strikePriceCurrency == ReadBytes(expiryDate.rest, 3) IN IF ~strikePriceCurrency.ok THEN Fail ELSE
    LET maximumNumberOfContractsPerOrder == ReadBytes(strikePriceCurrency.rest, 6) IN IF ~maximumNumberOfContractsPerOrder.ok THEN Fail ELSE
    LET minimumNumberOfContractsPerOrder == ReadBytes(maximumNumberOfContractsPerOrder.rest, 6) IN IF ~minimumNumberOfContractsPerOrder.ok THEN Fail ELSE
    LET maximumThresholdPrice == ReadBytes(minimumNumberOfContractsPerOrder.rest, 7) IN IF ~maximumThresholdPrice.ok THEN Fail ELSE
    LET maximumThresholdPriceFractionIndicator == ReadBytes(maximumThresholdPrice.rest, 1) IN IF ~maximumThresholdPriceFractionIndicator.ok THEN Fail ELSE
    LET minimumThresholdPrice == ReadBytes(maximumThresholdPriceFractionIndicator.rest, 7) IN IF ~minimumThresholdPrice.ok THEN Fail ELSE
    LET minimumThresholdPriceFractionIndicator == ReadBytes(minimumThresholdPrice.rest, 1) IN IF ~minimumThresholdPriceFractionIndicator.ok THEN Fail ELSE
    LET tickIncrement == ReadBytes(minimumThresholdPriceFractionIndicator.rest, 7) IN IF ~tickIncrement.ok THEN Fail ELSE
    LET tickIncrementFractionIndicator == ReadBytes(tickIncrement.rest, 1) IN IF ~tickIncrementFractionIndicator.ok THEN Fail ELSE
    LET marketFlowIndicator == ReadBytes(tickIncrementFractionIndicator.rest, 2) IN IF ~marketFlowIndicator.ok THEN Fail ELSE
    LET groupInstrument == ReadBytes(marketFlowIndicator.rest, 2) IN IF ~groupInstrument.ok THEN Fail ELSE
    LET instrument == ReadBytes(groupInstrument.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET instrumentExternalCode == ReadBytes(instrument.rest, 30) IN IF ~instrumentExternalCode.ok THEN Fail ELSE
    LET contractSize == ReadBytes(instrumentExternalCode.rest, 8) IN IF ~contractSize.ok THEN Fail ELSE
    LET tickValue == ReadBytes(contractSize.rest, 7) IN IF ~tickValue.ok THEN Fail ELSE
    LET tickValueFractionIndicator == ReadBytes(tickValue.rest, 1) IN IF ~tickValueFractionIndicator.ok THEN Fail ELSE
    LET currency == ReadBytes(tickValueFractionIndicator.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET deliveryType == ReadBytes(currency.rest, 1) IN IF ~deliveryType.ok THEN Fail ELSE
    LET underlyingRootSymbol == ReadBytes(deliveryType.rest, 6) IN IF ~underlyingRootSymbol.ok THEN Fail ELSE
    LET underlyingSymbolMonth == ReadBytes(underlyingRootSymbol.rest, 1) IN IF ~underlyingSymbolMonth.ok THEN Fail ELSE
    LET underlyingSymbolYear == ReadBytes(underlyingSymbolMonth.rest, 2) IN IF ~underlyingSymbolYear.ok THEN Fail ELSE
    Ok([ longMessageHeader                      |-> longMessageHeader.value,
         exchangeId                             |-> exchangeId.value,
         futureOptionSymbol                     |-> futureOptionSymbol.value,
         expiryDate                             |-> expiryDate.value,
         strikePriceCurrency                    |-> strikePriceCurrency.value,
         maximumNumberOfContractsPerOrder       |-> maximumNumberOfContractsPerOrder.value,
         minimumNumberOfContractsPerOrder       |-> minimumNumberOfContractsPerOrder.value,
         maximumThresholdPrice                  |-> maximumThresholdPrice.value,
         maximumThresholdPriceFractionIndicator |-> maximumThresholdPriceFractionIndicator.value,
         minimumThresholdPrice                  |-> minimumThresholdPrice.value,
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
         deliveryType                           |-> deliveryType.value,
         underlyingRootSymbol                   |-> underlyingRootSymbol.value,
         underlyingSymbolMonth                  |-> underlyingSymbolMonth.value,
         underlyingSymbolYear                   |-> underlyingSymbolYear.value ], underlyingSymbolYear.rest)

ZeroFutureOptionsInstrumentKeysMessage ==
    [ longMessageHeader                      |-> ZeroLongMessageHeader26,
      exchangeId                             |-> [i \in 1 .. 1 |-> 0],
      futureOptionSymbol                     |-> ZeroFutureOptionSymbol7,
      expiryDate                             |-> [i \in 1 .. 6 |-> 0],
      strikePriceCurrency                    |-> [i \in 1 .. 3 |-> 0],
      maximumNumberOfContractsPerOrder       |-> [i \in 1 .. 6 |-> 0],
      minimumNumberOfContractsPerOrder       |-> [i \in 1 .. 6 |-> 0],
      maximumThresholdPrice                  |-> [i \in 1 .. 7 |-> 0],
      maximumThresholdPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      minimumThresholdPrice                  |-> [i \in 1 .. 7 |-> 0],
      minimumThresholdPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      tickIncrement                          |-> [i \in 1 .. 7 |-> 0],
      tickIncrementFractionIndicator         |-> [i \in 1 .. 1 |-> 0],
      marketFlowIndicator                    |-> [i \in 1 .. 2 |-> 0],
      groupInstrument                        |-> [i \in 1 .. 2 |-> 0],
      instrument                             |-> [i \in 1 .. 4 |-> 0],
      instrumentExternalCode                 |-> [i \in 1 .. 30 |-> 0],
      contractSize                           |-> [i \in 1 .. 8 |-> 0],
      tickValue                              |-> [i \in 1 .. 7 |-> 0],
      tickValueFractionIndicator             |-> [i \in 1 .. 1 |-> 0],
      currency                               |-> [i \in 1 .. 3 |-> 0],
      deliveryType                           |-> [i \in 1 .. 1 |-> 0],
      underlyingRootSymbol                   |-> [i \in 1 .. 6 |-> 0],
      underlyingSymbolMonth                  |-> [i \in 1 .. 1 |-> 0],
      underlyingSymbolYear                   |-> [i \in 1 .. 2 |-> 0] ]

(* Future Options Instrument Keys Message at zero, then each field in turn at the values it is checked at *)
CheckedFutureOptionsInstrumentKeysMessage ==
    { ZeroFutureOptionsInstrumentKeysMessage }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.longMessageHeader = one] : one \in CheckedLongMessageHeader26 }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.futureOptionSymbol = one] : one \in CheckedFutureOptionSymbol7 }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.expiryDate = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.strikePriceCurrency = one] : one \in Sample(3) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.maximumNumberOfContractsPerOrder = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.minimumNumberOfContractsPerOrder = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.maximumThresholdPrice = one] : one \in Sample(7) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.maximumThresholdPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.minimumThresholdPrice = one] : one \in Sample(7) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.minimumThresholdPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.tickIncrement = one] : one \in Sample(7) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.tickIncrementFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.marketFlowIndicator = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.groupInstrument = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.instrumentExternalCode = one] : one \in Sample(30) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.contractSize = one] : one \in Sample(8) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.tickValue = one] : one \in Sample(7) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.tickValueFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.deliveryType = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.underlyingRootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.underlyingSymbolMonth = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.underlyingSymbolYear = one] : one \in Sample(2) }

(***************************************************************************)
(* Long Message Header: 12 bytes                                           *)
(***************************************************************************)

LongMessageHeader27 ==
    [ messageTimestamp : Sample(12) ]

EncodeLongMessageHeader27(message) ==
    message.messageTimestamp

DecodeLongMessageHeader27(bytes) ==
    LET messageTimestamp == ReadBytes(bytes, 12) IN IF ~messageTimestamp.ok THEN Fail ELSE
    Ok([ messageTimestamp |-> messageTimestamp.value ], messageTimestamp.rest)

ZeroLongMessageHeader27 ==
    [ messageTimestamp |-> [i \in 1 .. 12 |-> 0] ]

(* Long Message Header at zero, then each field in turn at the values it is checked at *)
CheckedLongMessageHeader27 ==
    { ZeroLongMessageHeader27 }
        \cup { [ZeroLongMessageHeader27 EXCEPT !.messageTimestamp = one] : one \in Sample(12) }

(***************************************************************************)
(* Underlying Instrument Keys Message: 49 bytes                            *)
(***************************************************************************)

UnderlyingInstrumentKeysMessage ==
    [ longMessageHeader      : LongMessageHeader27,
      exchangeId             : Sample(1),
      groupInstrument        : Sample(2),
      instrument             : Sample(4),
      instrumentExternalCode : Sample(30) ]

EncodeUnderlyingInstrumentKeysMessage(message) ==
    EncodeLongMessageHeader27(message.longMessageHeader)
        \o message.exchangeId
        \o message.groupInstrument
        \o message.instrument
        \o message.instrumentExternalCode

DecodeUnderlyingInstrumentKeysMessage(bytes) ==
    LET longMessageHeader == DecodeLongMessageHeader27(bytes) IN IF ~longMessageHeader.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(longMessageHeader.rest, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET groupInstrument == ReadBytes(exchangeId.rest, 2) IN IF ~groupInstrument.ok THEN Fail ELSE
    LET instrument == ReadBytes(groupInstrument.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET instrumentExternalCode == ReadBytes(instrument.rest, 30) IN IF ~instrumentExternalCode.ok THEN Fail ELSE
    Ok([ longMessageHeader      |-> longMessageHeader.value,
         exchangeId             |-> exchangeId.value,
         groupInstrument        |-> groupInstrument.value,
         instrument             |-> instrument.value,
         instrumentExternalCode |-> instrumentExternalCode.value ], instrumentExternalCode.rest)

ZeroUnderlyingInstrumentKeysMessage ==
    [ longMessageHeader      |-> ZeroLongMessageHeader27,
      exchangeId             |-> [i \in 1 .. 1 |-> 0],
      groupInstrument        |-> [i \in 1 .. 2 |-> 0],
      instrument             |-> [i \in 1 .. 4 |-> 0],
      instrumentExternalCode |-> [i \in 1 .. 30 |-> 0] ]

(* Underlying Instrument Keys Message at zero, then each field in turn at the values it is checked at *)
CheckedUnderlyingInstrumentKeysMessage ==
    { ZeroUnderlyingInstrumentKeysMessage }
        \cup { [ZeroUnderlyingInstrumentKeysMessage EXCEPT !.longMessageHeader = one] : one \in CheckedLongMessageHeader27 }
        \cup { [ZeroUnderlyingInstrumentKeysMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingInstrumentKeysMessage EXCEPT !.groupInstrument = one] : one \in Sample(2) }
        \cup { [ZeroUnderlyingInstrumentKeysMessage EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingInstrumentKeysMessage EXCEPT !.instrumentExternalCode = one] : one \in Sample(30) }

(***************************************************************************)
(* Long Message Header: 12 bytes                                           *)
(***************************************************************************)

LongMessageHeader28 ==
    [ messageTimestamp : Sample(12) ]

EncodeLongMessageHeader28(message) ==
    message.messageTimestamp

DecodeLongMessageHeader28(bytes) ==
    LET messageTimestamp == ReadBytes(bytes, 12) IN IF ~messageTimestamp.ok THEN Fail ELSE
    Ok([ messageTimestamp |-> messageTimestamp.value ], messageTimestamp.rest)

ZeroLongMessageHeader28 ==
    [ messageTimestamp |-> [i \in 1 .. 12 |-> 0] ]

(* Long Message Header at zero, then each field in turn at the values it is checked at *)
CheckedLongMessageHeader28 ==
    { ZeroLongMessageHeader28 }
        \cup { [ZeroLongMessageHeader28 EXCEPT !.messageTimestamp = one] : one \in Sample(12) }

(***************************************************************************)
(* Future Product: 11 bytes                                                *)
(***************************************************************************)

FutureProduct7 ==
    [ root        : Sample(6),
      symbolMonth : Sample(1),
      symbolYear  : Sample(2),
      expiryDay   : Sample(2) ]

EncodeFutureProduct7(message) ==
    message.root
        \o message.symbolMonth
        \o message.symbolYear
        \o message.expiryDay

DecodeFutureProduct7(bytes) ==
    LET root == ReadBytes(bytes, 6) IN IF ~root.ok THEN Fail ELSE
    LET symbolMonth == ReadBytes(root.rest, 1) IN IF ~symbolMonth.ok THEN Fail ELSE
    LET symbolYear == ReadBytes(symbolMonth.rest, 2) IN IF ~symbolYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(symbolYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ root        |-> root.value,
         symbolMonth |-> symbolMonth.value,
         symbolYear  |-> symbolYear.value,
         expiryDay   |-> expiryDay.value ], expiryDay.rest)

ZeroFutureProduct7 ==
    [ root        |-> [i \in 1 .. 6 |-> 0],
      symbolMonth |-> [i \in 1 .. 1 |-> 0],
      symbolYear  |-> [i \in 1 .. 2 |-> 0],
      expiryDay   |-> [i \in 1 .. 2 |-> 0] ]

(* Future Product at zero, then each field in turn at the values it is checked at *)
CheckedFutureProduct7 ==
    { ZeroFutureProduct7 }
        \cup { [ZeroFutureProduct7 EXCEPT !.root = one] : one \in Sample(6) }
        \cup { [ZeroFutureProduct7 EXCEPT !.symbolMonth = one] : one \in Sample(1) }
        \cup { [ZeroFutureProduct7 EXCEPT !.symbolYear = one] : one \in Sample(2) }
        \cup { [ZeroFutureProduct7 EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Associated Product: 11 bytes                                            *)
(***************************************************************************)

AssociatedProduct ==
    [ rootSymbol  : Sample(6),
      symbolMonth : Sample(1),
      symbolYear  : Sample(2),
      expiryDay   : Sample(2) ]

EncodeAssociatedProduct(message) ==
    message.rootSymbol
        \o message.symbolMonth
        \o message.symbolYear
        \o message.expiryDay

DecodeAssociatedProduct(bytes) ==
    LET rootSymbol == ReadBytes(bytes, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET symbolMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~symbolMonth.ok THEN Fail ELSE
    LET symbolYear == ReadBytes(symbolMonth.rest, 2) IN IF ~symbolYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(symbolYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ rootSymbol  |-> rootSymbol.value,
         symbolMonth |-> symbolMonth.value,
         symbolYear  |-> symbolYear.value,
         expiryDay   |-> expiryDay.value ], expiryDay.rest)

ZeroAssociatedProduct ==
    [ rootSymbol  |-> [i \in 1 .. 6 |-> 0],
      symbolMonth |-> [i \in 1 .. 1 |-> 0],
      symbolYear  |-> [i \in 1 .. 2 |-> 0],
      expiryDay   |-> [i \in 1 .. 2 |-> 0] ]

(* Associated Product at zero, then each field in turn at the values it is checked at *)
CheckedAssociatedProduct ==
    { ZeroAssociatedProduct }
        \cup { [ZeroAssociatedProduct EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroAssociatedProduct EXCEPT !.symbolMonth = one] : one \in Sample(1) }
        \cup { [ZeroAssociatedProduct EXCEPT !.symbolYear = one] : one \in Sample(2) }
        \cup { [ZeroAssociatedProduct EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Futures Instrument Keys Message: 147 bytes                              *)
(***************************************************************************)

FuturesInstrumentKeysMessage ==
    [ longMessageHeader                      : LongMessageHeader28,
      exchangeId                             : Sample(1),
      futureProduct                          : FutureProduct7,
      expiryDate                             : Sample(6),
      maximumNumberOfContractsPerOrder       : Sample(6),
      minimumNumberOfContractsPerOrder       : Sample(6),
      maximumThresholdPrice                  : Sample(7),
      maximumThresholdPriceFractionIndicator : Sample(1),
      minimumThresholdPrice                  : Sample(7),
      minimumThresholdPriceFractionIndicator : Sample(1),
      tickIncrement                          : Sample(7),
      tickIncrementFractionIndicator         : Sample(1),
      marketFlowIndicator                    : Sample(2),
      groupInstrument                        : Sample(2),
      instrument                             : Sample(4),
      instrumentExternalCode                 : Sample(30),
      contractSize                           : Sample(8),
      tickValue                              : Sample(7),
      tickValueFractionIndicator             : Sample(1),
      currency                               : Sample(3),
      underlyingSymbol                       : Sample(12),
      deliveryType                           : Sample(1),
      associatedProduct                      : AssociatedProduct ]

EncodeFuturesInstrumentKeysMessage(message) ==
    EncodeLongMessageHeader28(message.longMessageHeader)
        \o message.exchangeId
        \o EncodeFutureProduct7(message.futureProduct)
        \o message.expiryDate
        \o message.maximumNumberOfContractsPerOrder
        \o message.minimumNumberOfContractsPerOrder
        \o message.maximumThresholdPrice
        \o message.maximumThresholdPriceFractionIndicator
        \o message.minimumThresholdPrice
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
        \o EncodeAssociatedProduct(message.associatedProduct)

DecodeFuturesInstrumentKeysMessage(bytes) ==
    LET longMessageHeader == DecodeLongMessageHeader28(bytes) IN IF ~longMessageHeader.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(longMessageHeader.rest, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET futureProduct == DecodeFutureProduct7(exchangeId.rest) IN IF ~futureProduct.ok THEN Fail ELSE
    LET expiryDate == ReadBytes(futureProduct.rest, 6) IN IF ~expiryDate.ok THEN Fail ELSE
    LET maximumNumberOfContractsPerOrder == ReadBytes(expiryDate.rest, 6) IN IF ~maximumNumberOfContractsPerOrder.ok THEN Fail ELSE
    LET minimumNumberOfContractsPerOrder == ReadBytes(maximumNumberOfContractsPerOrder.rest, 6) IN IF ~minimumNumberOfContractsPerOrder.ok THEN Fail ELSE
    LET maximumThresholdPrice == ReadBytes(minimumNumberOfContractsPerOrder.rest, 7) IN IF ~maximumThresholdPrice.ok THEN Fail ELSE
    LET maximumThresholdPriceFractionIndicator == ReadBytes(maximumThresholdPrice.rest, 1) IN IF ~maximumThresholdPriceFractionIndicator.ok THEN Fail ELSE
    LET minimumThresholdPrice == ReadBytes(maximumThresholdPriceFractionIndicator.rest, 7) IN IF ~minimumThresholdPrice.ok THEN Fail ELSE
    LET minimumThresholdPriceFractionIndicator == ReadBytes(minimumThresholdPrice.rest, 1) IN IF ~minimumThresholdPriceFractionIndicator.ok THEN Fail ELSE
    LET tickIncrement == ReadBytes(minimumThresholdPriceFractionIndicator.rest, 7) IN IF ~tickIncrement.ok THEN Fail ELSE
    LET tickIncrementFractionIndicator == ReadBytes(tickIncrement.rest, 1) IN IF ~tickIncrementFractionIndicator.ok THEN Fail ELSE
    LET marketFlowIndicator == ReadBytes(tickIncrementFractionIndicator.rest, 2) IN IF ~marketFlowIndicator.ok THEN Fail ELSE
    LET groupInstrument == ReadBytes(marketFlowIndicator.rest, 2) IN IF ~groupInstrument.ok THEN Fail ELSE
    LET instrument == ReadBytes(groupInstrument.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET instrumentExternalCode == ReadBytes(instrument.rest, 30) IN IF ~instrumentExternalCode.ok THEN Fail ELSE
    LET contractSize == ReadBytes(instrumentExternalCode.rest, 8) IN IF ~contractSize.ok THEN Fail ELSE
    LET tickValue == ReadBytes(contractSize.rest, 7) IN IF ~tickValue.ok THEN Fail ELSE
    LET tickValueFractionIndicator == ReadBytes(tickValue.rest, 1) IN IF ~tickValueFractionIndicator.ok THEN Fail ELSE
    LET currency == ReadBytes(tickValueFractionIndicator.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(currency.rest, 12) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET deliveryType == ReadBytes(underlyingSymbol.rest, 1) IN IF ~deliveryType.ok THEN Fail ELSE
    LET associatedProduct == DecodeAssociatedProduct(deliveryType.rest) IN IF ~associatedProduct.ok THEN Fail ELSE
    Ok([ longMessageHeader                      |-> longMessageHeader.value,
         exchangeId                             |-> exchangeId.value,
         futureProduct                          |-> futureProduct.value,
         expiryDate                             |-> expiryDate.value,
         maximumNumberOfContractsPerOrder       |-> maximumNumberOfContractsPerOrder.value,
         minimumNumberOfContractsPerOrder       |-> minimumNumberOfContractsPerOrder.value,
         maximumThresholdPrice                  |-> maximumThresholdPrice.value,
         maximumThresholdPriceFractionIndicator |-> maximumThresholdPriceFractionIndicator.value,
         minimumThresholdPrice                  |-> minimumThresholdPrice.value,
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
         associatedProduct                      |-> associatedProduct.value ], associatedProduct.rest)

ZeroFuturesInstrumentKeysMessage ==
    [ longMessageHeader                      |-> ZeroLongMessageHeader28,
      exchangeId                             |-> [i \in 1 .. 1 |-> 0],
      futureProduct                          |-> ZeroFutureProduct7,
      expiryDate                             |-> [i \in 1 .. 6 |-> 0],
      maximumNumberOfContractsPerOrder       |-> [i \in 1 .. 6 |-> 0],
      minimumNumberOfContractsPerOrder       |-> [i \in 1 .. 6 |-> 0],
      maximumThresholdPrice                  |-> [i \in 1 .. 7 |-> 0],
      maximumThresholdPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      minimumThresholdPrice                  |-> [i \in 1 .. 7 |-> 0],
      minimumThresholdPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      tickIncrement                          |-> [i \in 1 .. 7 |-> 0],
      tickIncrementFractionIndicator         |-> [i \in 1 .. 1 |-> 0],
      marketFlowIndicator                    |-> [i \in 1 .. 2 |-> 0],
      groupInstrument                        |-> [i \in 1 .. 2 |-> 0],
      instrument                             |-> [i \in 1 .. 4 |-> 0],
      instrumentExternalCode                 |-> [i \in 1 .. 30 |-> 0],
      contractSize                           |-> [i \in 1 .. 8 |-> 0],
      tickValue                              |-> [i \in 1 .. 7 |-> 0],
      tickValueFractionIndicator             |-> [i \in 1 .. 1 |-> 0],
      currency                               |-> [i \in 1 .. 3 |-> 0],
      underlyingSymbol                       |-> [i \in 1 .. 12 |-> 0],
      deliveryType                           |-> [i \in 1 .. 1 |-> 0],
      associatedProduct                      |-> ZeroAssociatedProduct ]

(* Futures Instrument Keys Message at zero, then each field in turn at the values it is checked at *)
CheckedFuturesInstrumentKeysMessage ==
    { ZeroFuturesInstrumentKeysMessage }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.longMessageHeader = one] : one \in CheckedLongMessageHeader28 }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.futureProduct = one] : one \in CheckedFutureProduct7 }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.expiryDate = one] : one \in Sample(6) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.maximumNumberOfContractsPerOrder = one] : one \in Sample(6) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.minimumNumberOfContractsPerOrder = one] : one \in Sample(6) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.maximumThresholdPrice = one] : one \in Sample(7) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.maximumThresholdPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.minimumThresholdPrice = one] : one \in Sample(7) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.minimumThresholdPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.tickIncrement = one] : one \in Sample(7) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.tickIncrementFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.marketFlowIndicator = one] : one \in Sample(2) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.groupInstrument = one] : one \in Sample(2) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.instrumentExternalCode = one] : one \in Sample(30) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.contractSize = one] : one \in Sample(8) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.tickValue = one] : one \in Sample(7) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.tickValueFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(12) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.deliveryType = one] : one \in Sample(1) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.associatedProduct = one] : one \in CheckedAssociatedProduct }

(***************************************************************************)
(* Long Message Header: 12 bytes                                           *)
(***************************************************************************)

LongMessageHeader29 ==
    [ messageTimestamp : Sample(12) ]

EncodeLongMessageHeader29(message) ==
    message.messageTimestamp

DecodeLongMessageHeader29(bytes) ==
    LET messageTimestamp == ReadBytes(bytes, 12) IN IF ~messageTimestamp.ok THEN Fail ELSE
    Ok([ messageTimestamp |-> messageTimestamp.value ], messageTimestamp.rest)

ZeroLongMessageHeader29 ==
    [ messageTimestamp |-> [i \in 1 .. 12 |-> 0] ]

(* Long Message Header at zero, then each field in turn at the values it is checked at *)
CheckedLongMessageHeader29 ==
    { ZeroLongMessageHeader29 }
        \cup { [ZeroLongMessageHeader29 EXCEPT !.messageTimestamp = one] : one \in Sample(12) }

(***************************************************************************)
(* Strategy Instrument Leg: 35 bytes                                       *)
(***************************************************************************)

StrategyInstrumentLeg ==
    [ legRatioSign : Sample(1),
      legRatio     : Sample(4),
      legSymbol    : Sample(30) ]

EncodeStrategyInstrumentLeg(message) ==
    message.legRatioSign
        \o message.legRatio
        \o message.legSymbol

DecodeStrategyInstrumentLeg(bytes) ==
    LET legRatioSign == ReadBytes(bytes, 1) IN IF ~legRatioSign.ok THEN Fail ELSE
    LET legRatio == ReadBytes(legRatioSign.rest, 4) IN IF ~legRatio.ok THEN Fail ELSE
    LET legSymbol == ReadBytes(legRatio.rest, 30) IN IF ~legSymbol.ok THEN Fail ELSE
    Ok([ legRatioSign |-> legRatioSign.value,
         legRatio     |-> legRatio.value,
         legSymbol    |-> legSymbol.value ], legSymbol.rest)

ZeroStrategyInstrumentLeg ==
    [ legRatioSign |-> [i \in 1 .. 1 |-> 0],
      legRatio     |-> [i \in 1 .. 4 |-> 0],
      legSymbol    |-> [i \in 1 .. 30 |-> 0] ]

(* Strategy Instrument Leg at zero, then each field in turn at the values it is checked at *)
CheckedStrategyInstrumentLeg ==
    { ZeroStrategyInstrumentLeg }
        \cup { [ZeroStrategyInstrumentLeg EXCEPT !.legRatioSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategyInstrumentLeg EXCEPT !.legRatio = one] : one \in Sample(4) }
        \cup { [ZeroStrategyInstrumentLeg EXCEPT !.legSymbol = one] : one \in Sample(30) }

(* A run of Strategy Instrument Leg, written one after another *)
RECURSIVE EncodeStrategyInstrumentLegList(_)
EncodeStrategyInstrumentLegList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeStrategyInstrumentLeg(Head(messages)) \o EncodeStrategyInstrumentLegList(Tail(messages))

(* As many Strategy Instrument Leg as the field that counts them says *)
RECURSIVE ReadStrategyInstrumentLegList(_, _)
ReadStrategyInstrumentLegList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeStrategyInstrumentLeg(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadStrategyInstrumentLegList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Strategy Instrument Leg of each kind, for the lists that carry them *)
OneStrategyInstrumentLeg == { ZeroStrategyInstrumentLeg }

(***************************************************************************)
(* Strategy Instrument Keys Message                                        *)
(***************************************************************************)

StrategyInstrumentKeysMessage ==
    [ longMessageHeader                      : LongMessageHeader29,
      exchangeId                             : Sample(1),
      strategySymbol                         : Sample(30),
      expiryYear                             : Sample(2),
      expiryMonth                            : Sample(1),
      expiryDay                              : Sample(2),
      maximumNumberOfContractsPerOrder       : Sample(6),
      minimumNumberOfContractsPerOrder       : Sample(6),
      maximumThresholdPrice                  : Sample(7),
      maximumThresholdPriceFractionIndicator : Sample(1),
      minimumThresholdPrice                  : Sample(7),
      minimumThresholdPriceFractionIndicator : Sample(1),
      tickIncrement                          : Sample(7),
      tickIncrementFractionIndicator         : Sample(1),
      marketFlowIndicator                    : Sample(2),
      groupInstrument                        : Sample(2),
      instrument                             : Sample(4),
      instrumentExternalCode                 : Sample(30),
      strategyAllowImplied                   : Sample(1),
      strategyCode                           : Sample(2),
      strategyInstrumentLeg                  : SampleLists(OneStrategyInstrumentLeg) ]

EncodeStrategyInstrumentKeysMessage(message) ==
    EncodeLongMessageHeader29(message.longMessageHeader)
        \o message.exchangeId
        \o message.strategySymbol
        \o message.expiryYear
        \o message.expiryMonth
        \o message.expiryDay
        \o message.maximumNumberOfContractsPerOrder
        \o message.minimumNumberOfContractsPerOrder
        \o message.maximumThresholdPrice
        \o message.maximumThresholdPriceFractionIndicator
        \o message.minimumThresholdPrice
        \o message.minimumThresholdPriceFractionIndicator
        \o message.tickIncrement
        \o message.tickIncrementFractionIndicator
        \o message.marketFlowIndicator
        \o message.groupInstrument
        \o message.instrument
        \o message.instrumentExternalCode
        \o message.strategyAllowImplied
        \o message.strategyCode
        \o EncodeDigits(Len(message.strategyInstrumentLeg), 2)
        \o EncodeStrategyInstrumentLegList(message.strategyInstrumentLeg)

DecodeStrategyInstrumentKeysMessage(bytes) ==
    LET longMessageHeader == DecodeLongMessageHeader29(bytes) IN IF ~longMessageHeader.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(longMessageHeader.rest, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET strategySymbol == ReadBytes(exchangeId.rest, 30) IN IF ~strategySymbol.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(strategySymbol.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryMonth == ReadBytes(expiryYear.rest, 1) IN IF ~expiryMonth.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryMonth.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET maximumNumberOfContractsPerOrder == ReadBytes(expiryDay.rest, 6) IN IF ~maximumNumberOfContractsPerOrder.ok THEN Fail ELSE
    LET minimumNumberOfContractsPerOrder == ReadBytes(maximumNumberOfContractsPerOrder.rest, 6) IN IF ~minimumNumberOfContractsPerOrder.ok THEN Fail ELSE
    LET maximumThresholdPrice == ReadBytes(minimumNumberOfContractsPerOrder.rest, 7) IN IF ~maximumThresholdPrice.ok THEN Fail ELSE
    LET maximumThresholdPriceFractionIndicator == ReadBytes(maximumThresholdPrice.rest, 1) IN IF ~maximumThresholdPriceFractionIndicator.ok THEN Fail ELSE
    LET minimumThresholdPrice == ReadBytes(maximumThresholdPriceFractionIndicator.rest, 7) IN IF ~minimumThresholdPrice.ok THEN Fail ELSE
    LET minimumThresholdPriceFractionIndicator == ReadBytes(minimumThresholdPrice.rest, 1) IN IF ~minimumThresholdPriceFractionIndicator.ok THEN Fail ELSE
    LET tickIncrement == ReadBytes(minimumThresholdPriceFractionIndicator.rest, 7) IN IF ~tickIncrement.ok THEN Fail ELSE
    LET tickIncrementFractionIndicator == ReadBytes(tickIncrement.rest, 1) IN IF ~tickIncrementFractionIndicator.ok THEN Fail ELSE
    LET marketFlowIndicator == ReadBytes(tickIncrementFractionIndicator.rest, 2) IN IF ~marketFlowIndicator.ok THEN Fail ELSE
    LET groupInstrument == ReadBytes(marketFlowIndicator.rest, 2) IN IF ~groupInstrument.ok THEN Fail ELSE
    LET instrument == ReadBytes(groupInstrument.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET instrumentExternalCode == ReadBytes(instrument.rest, 30) IN IF ~instrumentExternalCode.ok THEN Fail ELSE
    LET strategyAllowImplied == ReadBytes(instrumentExternalCode.rest, 1) IN IF ~strategyAllowImplied.ok THEN Fail ELSE
    LET strategyCode == ReadBytes(strategyAllowImplied.rest, 2) IN IF ~strategyCode.ok THEN Fail ELSE
    LET numberOfLegs == ReadDigits(strategyCode.rest, 2) IN IF ~numberOfLegs.ok THEN Fail ELSE
    LET strategyInstrumentLeg == ReadStrategyInstrumentLegList(numberOfLegs.rest, numberOfLegs.value) IN IF ~strategyInstrumentLeg.ok THEN Fail ELSE
    Ok([ longMessageHeader                      |-> longMessageHeader.value,
         exchangeId                             |-> exchangeId.value,
         strategySymbol                         |-> strategySymbol.value,
         expiryYear                             |-> expiryYear.value,
         expiryMonth                            |-> expiryMonth.value,
         expiryDay                              |-> expiryDay.value,
         maximumNumberOfContractsPerOrder       |-> maximumNumberOfContractsPerOrder.value,
         minimumNumberOfContractsPerOrder       |-> minimumNumberOfContractsPerOrder.value,
         maximumThresholdPrice                  |-> maximumThresholdPrice.value,
         maximumThresholdPriceFractionIndicator |-> maximumThresholdPriceFractionIndicator.value,
         minimumThresholdPrice                  |-> minimumThresholdPrice.value,
         minimumThresholdPriceFractionIndicator |-> minimumThresholdPriceFractionIndicator.value,
         tickIncrement                          |-> tickIncrement.value,
         tickIncrementFractionIndicator         |-> tickIncrementFractionIndicator.value,
         marketFlowIndicator                    |-> marketFlowIndicator.value,
         groupInstrument                        |-> groupInstrument.value,
         instrument                             |-> instrument.value,
         instrumentExternalCode                 |-> instrumentExternalCode.value,
         strategyAllowImplied                   |-> strategyAllowImplied.value,
         strategyCode                           |-> strategyCode.value,
         strategyInstrumentLeg                  |-> strategyInstrumentLeg.value ], strategyInstrumentLeg.rest)

ZeroStrategyInstrumentKeysMessage ==
    [ longMessageHeader                      |-> ZeroLongMessageHeader29,
      exchangeId                             |-> [i \in 1 .. 1 |-> 0],
      strategySymbol                         |-> [i \in 1 .. 30 |-> 0],
      expiryYear                             |-> [i \in 1 .. 2 |-> 0],
      expiryMonth                            |-> [i \in 1 .. 1 |-> 0],
      expiryDay                              |-> [i \in 1 .. 2 |-> 0],
      maximumNumberOfContractsPerOrder       |-> [i \in 1 .. 6 |-> 0],
      minimumNumberOfContractsPerOrder       |-> [i \in 1 .. 6 |-> 0],
      maximumThresholdPrice                  |-> [i \in 1 .. 7 |-> 0],
      maximumThresholdPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      minimumThresholdPrice                  |-> [i \in 1 .. 7 |-> 0],
      minimumThresholdPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      tickIncrement                          |-> [i \in 1 .. 7 |-> 0],
      tickIncrementFractionIndicator         |-> [i \in 1 .. 1 |-> 0],
      marketFlowIndicator                    |-> [i \in 1 .. 2 |-> 0],
      groupInstrument                        |-> [i \in 1 .. 2 |-> 0],
      instrument                             |-> [i \in 1 .. 4 |-> 0],
      instrumentExternalCode                 |-> [i \in 1 .. 30 |-> 0],
      strategyAllowImplied                   |-> [i \in 1 .. 1 |-> 0],
      strategyCode                           |-> [i \in 1 .. 2 |-> 0],
      strategyInstrumentLeg                  |-> << >> ]

(* Strategy Instrument Keys Message at zero, then each field in turn at the values it is checked at *)
CheckedStrategyInstrumentKeysMessage ==
    { ZeroStrategyInstrumentKeysMessage }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.longMessageHeader = one] : one \in CheckedLongMessageHeader29 }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.strategySymbol = one] : one \in Sample(30) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.expiryMonth = one] : one \in Sample(1) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.maximumNumberOfContractsPerOrder = one] : one \in Sample(6) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.minimumNumberOfContractsPerOrder = one] : one \in Sample(6) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.maximumThresholdPrice = one] : one \in Sample(7) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.maximumThresholdPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.minimumThresholdPrice = one] : one \in Sample(7) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.minimumThresholdPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.tickIncrement = one] : one \in Sample(7) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.tickIncrementFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.marketFlowIndicator = one] : one \in Sample(2) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.groupInstrument = one] : one \in Sample(2) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.instrumentExternalCode = one] : one \in Sample(30) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.strategyAllowImplied = one] : one \in Sample(1) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.strategyCode = one] : one \in Sample(2) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.strategyInstrumentLeg = one] : one \in SampleLists(OneStrategyInstrumentLeg) }

(***************************************************************************)
(* Long Message Header: 12 bytes                                           *)
(***************************************************************************)

LongMessageHeader30 ==
    [ messageTimestamp : Sample(12) ]

EncodeLongMessageHeader30(message) ==
    message.messageTimestamp

DecodeLongMessageHeader30(bytes) ==
    LET messageTimestamp == ReadBytes(bytes, 12) IN IF ~messageTimestamp.ok THEN Fail ELSE
    Ok([ messageTimestamp |-> messageTimestamp.value ], messageTimestamp.rest)

ZeroLongMessageHeader30 ==
    [ messageTimestamp |-> [i \in 1 .. 12 |-> 0] ]

(* Long Message Header at zero, then each field in turn at the values it is checked at *)
CheckedLongMessageHeader30 ==
    { ZeroLongMessageHeader30 }
        \cup { [ZeroLongMessageHeader30 EXCEPT !.messageTimestamp = one] : one \in Sample(12) }

(***************************************************************************)
(* Option Symbol: 20 bytes                                                 *)
(***************************************************************************)

OptionSymbol8 ==
    [ root                         : Sample(6),
      expiryMonth                  : Sample(1),
      filler1                      : Sample(1),
      strikePrice                  : Sample(7),
      strikePriceFractionIndicator : Sample(1),
      expiryYear                   : Sample(2),
      expiryDay                    : Sample(2) ]

EncodeOptionSymbol8(message) ==
    message.root
        \o message.expiryMonth
        \o message.filler1
        \o message.strikePrice
        \o message.strikePriceFractionIndicator
        \o message.expiryYear
        \o message.expiryDay

DecodeOptionSymbol8(bytes) ==
    LET root == ReadBytes(bytes, 6) IN IF ~root.ok THEN Fail ELSE
    LET expiryMonth == ReadBytes(root.rest, 1) IN IF ~expiryMonth.ok THEN Fail ELSE
    LET filler1 == ReadBytes(expiryMonth.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(filler1.rest, 7) IN IF ~strikePrice.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePrice.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(strikePriceFractionIndicator.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ root                         |-> root.value,
         expiryMonth                  |-> expiryMonth.value,
         filler1                      |-> filler1.value,
         strikePrice                  |-> strikePrice.value,
         strikePriceFractionIndicator |-> strikePriceFractionIndicator.value,
         expiryYear                   |-> expiryYear.value,
         expiryDay                    |-> expiryDay.value ], expiryDay.rest)

ZeroOptionSymbol8 ==
    [ root                         |-> [i \in 1 .. 6 |-> 0],
      expiryMonth                  |-> [i \in 1 .. 1 |-> 0],
      filler1                      |-> [i \in 1 .. 1 |-> 0],
      strikePrice                  |-> [i \in 1 .. 7 |-> 0],
      strikePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      expiryYear                   |-> [i \in 1 .. 2 |-> 0],
      expiryDay                    |-> [i \in 1 .. 2 |-> 0] ]

(* Option Symbol at zero, then each field in turn at the values it is checked at *)
CheckedOptionSymbol8 ==
    { ZeroOptionSymbol8 }
        \cup { [ZeroOptionSymbol8 EXCEPT !.root = one] : one \in Sample(6) }
        \cup { [ZeroOptionSymbol8 EXCEPT !.expiryMonth = one] : one \in Sample(1) }
        \cup { [ZeroOptionSymbol8 EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroOptionSymbol8 EXCEPT !.strikePrice = one] : one \in Sample(7) }
        \cup { [ZeroOptionSymbol8 EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionSymbol8 EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroOptionSymbol8 EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Option Summary Message: 141 bytes                                       *)
(***************************************************************************)

OptionSummaryMessage ==
    [ longMessageHeader                        : LongMessageHeader30,
      exchangeId                               : Sample(1),
      optionSymbol                             : OptionSymbol8,
      bidPriceSummary                          : Sample(7),
      bidPriceFractionIndicator                : Sample(1),
      bidSize                                  : Sample(5),
      askPriceSummary                          : Sample(7),
      askPriceFractionIndicator                : Sample(1),
      askSize                                  : Sample(5),
      lastPrice                                : Sample(7),
      lastPriceFractionIndicator               : Sample(1),
      openInterest                             : Sample(7),
      openInterestDate                         : Sample(6),
      tick                                     : Sample(1),
      volume                                   : Sample(8),
      netChangeSign                            : Sample(1),
      netChange                                : Sample(7),
      netChangeFractionIndicator               : Sample(1),
      openPrice                                : Sample(7),
      openPriceFractionIndicator               : Sample(1),
      highPrice                                : Sample(7),
      highPriceFractionIndicator               : Sample(1),
      lowPrice                                 : Sample(7),
      lowPriceFractionIndicator                : Sample(1),
      optionMarker                             : Sample(2),
      settlementPrice                          : Sample(7),
      settlementPriceFractionIndicator         : Sample(1),
      previousSettlementPrice                  : Sample(7),
      previousSettlementPriceFractionIndicator : Sample(1),
      reason                                   : Sample(1) ]

EncodeOptionSummaryMessage(message) ==
    EncodeLongMessageHeader30(message.longMessageHeader)
        \o message.exchangeId
        \o EncodeOptionSymbol8(message.optionSymbol)
        \o message.bidPriceSummary
        \o message.bidPriceFractionIndicator
        \o message.bidSize
        \o message.askPriceSummary
        \o message.askPriceFractionIndicator
        \o message.askSize
        \o message.lastPrice
        \o message.lastPriceFractionIndicator
        \o message.openInterest
        \o message.openInterestDate
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
        \o message.settlementPrice
        \o message.settlementPriceFractionIndicator
        \o message.previousSettlementPrice
        \o message.previousSettlementPriceFractionIndicator
        \o message.reason

DecodeOptionSummaryMessage(bytes) ==
    LET longMessageHeader == DecodeLongMessageHeader30(bytes) IN IF ~longMessageHeader.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(longMessageHeader.rest, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET optionSymbol == DecodeOptionSymbol8(exchangeId.rest) IN IF ~optionSymbol.ok THEN Fail ELSE
    LET bidPriceSummary == ReadBytes(optionSymbol.rest, 7) IN IF ~bidPriceSummary.ok THEN Fail ELSE
    LET bidPriceFractionIndicator == ReadBytes(bidPriceSummary.rest, 1) IN IF ~bidPriceFractionIndicator.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPriceFractionIndicator.rest, 5) IN IF ~bidSize.ok THEN Fail ELSE
    LET askPriceSummary == ReadBytes(bidSize.rest, 7) IN IF ~askPriceSummary.ok THEN Fail ELSE
    LET askPriceFractionIndicator == ReadBytes(askPriceSummary.rest, 1) IN IF ~askPriceFractionIndicator.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPriceFractionIndicator.rest, 5) IN IF ~askSize.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(askSize.rest, 7) IN IF ~lastPrice.ok THEN Fail ELSE
    LET lastPriceFractionIndicator == ReadBytes(lastPrice.rest, 1) IN IF ~lastPriceFractionIndicator.ok THEN Fail ELSE
    LET openInterest == ReadBytes(lastPriceFractionIndicator.rest, 7) IN IF ~openInterest.ok THEN Fail ELSE
    LET openInterestDate == ReadBytes(openInterest.rest, 6) IN IF ~openInterestDate.ok THEN Fail ELSE
    LET tick == ReadBytes(openInterestDate.rest, 1) IN IF ~tick.ok THEN Fail ELSE
    LET volume == ReadBytes(tick.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET netChangeSign == ReadBytes(volume.rest, 1) IN IF ~netChangeSign.ok THEN Fail ELSE
    LET netChange == ReadBytes(netChangeSign.rest, 7) IN IF ~netChange.ok THEN Fail ELSE
    LET netChangeFractionIndicator == ReadBytes(netChange.rest, 1) IN IF ~netChangeFractionIndicator.ok THEN Fail ELSE
    LET openPrice == ReadBytes(netChangeFractionIndicator.rest, 7) IN IF ~openPrice.ok THEN Fail ELSE
    LET openPriceFractionIndicator == ReadBytes(openPrice.rest, 1) IN IF ~openPriceFractionIndicator.ok THEN Fail ELSE
    LET highPrice == ReadBytes(openPriceFractionIndicator.rest, 7) IN IF ~highPrice.ok THEN Fail ELSE
    LET highPriceFractionIndicator == ReadBytes(highPrice.rest, 1) IN IF ~highPriceFractionIndicator.ok THEN Fail ELSE
    LET lowPrice == ReadBytes(highPriceFractionIndicator.rest, 7) IN IF ~lowPrice.ok THEN Fail ELSE
    LET lowPriceFractionIndicator == ReadBytes(lowPrice.rest, 1) IN IF ~lowPriceFractionIndicator.ok THEN Fail ELSE
    LET optionMarker == ReadBytes(lowPriceFractionIndicator.rest, 2) IN IF ~optionMarker.ok THEN Fail ELSE
    LET settlementPrice == ReadBytes(optionMarker.rest, 7) IN IF ~settlementPrice.ok THEN Fail ELSE
    LET settlementPriceFractionIndicator == ReadBytes(settlementPrice.rest, 1) IN IF ~settlementPriceFractionIndicator.ok THEN Fail ELSE
    LET previousSettlementPrice == ReadBytes(settlementPriceFractionIndicator.rest, 7) IN IF ~previousSettlementPrice.ok THEN Fail ELSE
    LET previousSettlementPriceFractionIndicator == ReadBytes(previousSettlementPrice.rest, 1) IN IF ~previousSettlementPriceFractionIndicator.ok THEN Fail ELSE
    LET reason == ReadBytes(previousSettlementPriceFractionIndicator.rest, 1) IN IF ~reason.ok THEN Fail ELSE
    Ok([ longMessageHeader                        |-> longMessageHeader.value,
         exchangeId                               |-> exchangeId.value,
         optionSymbol                             |-> optionSymbol.value,
         bidPriceSummary                          |-> bidPriceSummary.value,
         bidPriceFractionIndicator                |-> bidPriceFractionIndicator.value,
         bidSize                                  |-> bidSize.value,
         askPriceSummary                          |-> askPriceSummary.value,
         askPriceFractionIndicator                |-> askPriceFractionIndicator.value,
         askSize                                  |-> askSize.value,
         lastPrice                                |-> lastPrice.value,
         lastPriceFractionIndicator               |-> lastPriceFractionIndicator.value,
         openInterest                             |-> openInterest.value,
         openInterestDate                         |-> openInterestDate.value,
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
         settlementPrice                          |-> settlementPrice.value,
         settlementPriceFractionIndicator         |-> settlementPriceFractionIndicator.value,
         previousSettlementPrice                  |-> previousSettlementPrice.value,
         previousSettlementPriceFractionIndicator |-> previousSettlementPriceFractionIndicator.value,
         reason                                   |-> reason.value ], reason.rest)

ZeroOptionSummaryMessage ==
    [ longMessageHeader                        |-> ZeroLongMessageHeader30,
      exchangeId                               |-> [i \in 1 .. 1 |-> 0],
      optionSymbol                             |-> ZeroOptionSymbol8,
      bidPriceSummary                          |-> [i \in 1 .. 7 |-> 0],
      bidPriceFractionIndicator                |-> [i \in 1 .. 1 |-> 0],
      bidSize                                  |-> [i \in 1 .. 5 |-> 0],
      askPriceSummary                          |-> [i \in 1 .. 7 |-> 0],
      askPriceFractionIndicator                |-> [i \in 1 .. 1 |-> 0],
      askSize                                  |-> [i \in 1 .. 5 |-> 0],
      lastPrice                                |-> [i \in 1 .. 7 |-> 0],
      lastPriceFractionIndicator               |-> [i \in 1 .. 1 |-> 0],
      openInterest                             |-> [i \in 1 .. 7 |-> 0],
      openInterestDate                         |-> [i \in 1 .. 6 |-> 0],
      tick                                     |-> [i \in 1 .. 1 |-> 0],
      volume                                   |-> [i \in 1 .. 8 |-> 0],
      netChangeSign                            |-> [i \in 1 .. 1 |-> 0],
      netChange                                |-> [i \in 1 .. 7 |-> 0],
      netChangeFractionIndicator               |-> [i \in 1 .. 1 |-> 0],
      openPrice                                |-> [i \in 1 .. 7 |-> 0],
      openPriceFractionIndicator               |-> [i \in 1 .. 1 |-> 0],
      highPrice                                |-> [i \in 1 .. 7 |-> 0],
      highPriceFractionIndicator               |-> [i \in 1 .. 1 |-> 0],
      lowPrice                                 |-> [i \in 1 .. 7 |-> 0],
      lowPriceFractionIndicator                |-> [i \in 1 .. 1 |-> 0],
      optionMarker                             |-> [i \in 1 .. 2 |-> 0],
      settlementPrice                          |-> [i \in 1 .. 7 |-> 0],
      settlementPriceFractionIndicator         |-> [i \in 1 .. 1 |-> 0],
      previousSettlementPrice                  |-> [i \in 1 .. 7 |-> 0],
      previousSettlementPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      reason                                   |-> [i \in 1 .. 1 |-> 0] ]

(* Option Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionSummaryMessage ==
    { ZeroOptionSummaryMessage }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.longMessageHeader = one] : one \in CheckedLongMessageHeader30 }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.optionSymbol = one] : one \in CheckedOptionSymbol8 }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.bidPriceSummary = one] : one \in Sample(7) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.bidPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.bidSize = one] : one \in Sample(5) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.askPriceSummary = one] : one \in Sample(7) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.askPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.askSize = one] : one \in Sample(5) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.lastPrice = one] : one \in Sample(7) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.lastPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.openInterest = one] : one \in Sample(7) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.openInterestDate = one] : one \in Sample(6) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.tick = one] : one \in Sample(1) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.netChangeSign = one] : one \in Sample(1) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.netChange = one] : one \in Sample(7) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.netChangeFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.openPrice = one] : one \in Sample(7) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.openPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.highPrice = one] : one \in Sample(7) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.highPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.lowPrice = one] : one \in Sample(7) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.lowPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.optionMarker = one] : one \in Sample(2) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.settlementPrice = one] : one \in Sample(7) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.settlementPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.previousSettlementPrice = one] : one \in Sample(7) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.previousSettlementPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.reason = one] : one \in Sample(1) }

(***************************************************************************)
(* Long Message Header: 12 bytes                                           *)
(***************************************************************************)

LongMessageHeader31 ==
    [ messageTimestamp : Sample(12) ]

EncodeLongMessageHeader31(message) ==
    message.messageTimestamp

DecodeLongMessageHeader31(bytes) ==
    LET messageTimestamp == ReadBytes(bytes, 12) IN IF ~messageTimestamp.ok THEN Fail ELSE
    Ok([ messageTimestamp |-> messageTimestamp.value ], messageTimestamp.rest)

ZeroLongMessageHeader31 ==
    [ messageTimestamp |-> [i \in 1 .. 12 |-> 0] ]

(* Long Message Header at zero, then each field in turn at the values it is checked at *)
CheckedLongMessageHeader31 ==
    { ZeroLongMessageHeader31 }
        \cup { [ZeroLongMessageHeader31 EXCEPT !.messageTimestamp = one] : one \in Sample(12) }

(***************************************************************************)
(* Future Option Symbol: 20 bytes                                          *)
(***************************************************************************)

FutureOptionSymbol8 ==
    [ root                         : Sample(6),
      symbolMonth                  : Sample(1),
      symbolYear                   : Sample(2),
      expiryDay                    : Sample(2),
      callPutCode                  : Sample(1),
      strikePrice                  : Sample(7),
      strikePriceFractionIndicator : Sample(1) ]

EncodeFutureOptionSymbol8(message) ==
    message.root
        \o message.symbolMonth
        \o message.symbolYear
        \o message.expiryDay
        \o message.callPutCode
        \o message.strikePrice
        \o message.strikePriceFractionIndicator

DecodeFutureOptionSymbol8(bytes) ==
    LET root == ReadBytes(bytes, 6) IN IF ~root.ok THEN Fail ELSE
    LET symbolMonth == ReadBytes(root.rest, 1) IN IF ~symbolMonth.ok THEN Fail ELSE
    LET symbolYear == ReadBytes(symbolMonth.rest, 2) IN IF ~symbolYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(symbolYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET callPutCode == ReadBytes(expiryDay.rest, 1) IN IF ~callPutCode.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(callPutCode.rest, 7) IN IF ~strikePrice.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePrice.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    Ok([ root                         |-> root.value,
         symbolMonth                  |-> symbolMonth.value,
         symbolYear                   |-> symbolYear.value,
         expiryDay                    |-> expiryDay.value,
         callPutCode                  |-> callPutCode.value,
         strikePrice                  |-> strikePrice.value,
         strikePriceFractionIndicator |-> strikePriceFractionIndicator.value ], strikePriceFractionIndicator.rest)

ZeroFutureOptionSymbol8 ==
    [ root                         |-> [i \in 1 .. 6 |-> 0],
      symbolMonth                  |-> [i \in 1 .. 1 |-> 0],
      symbolYear                   |-> [i \in 1 .. 2 |-> 0],
      expiryDay                    |-> [i \in 1 .. 2 |-> 0],
      callPutCode                  |-> [i \in 1 .. 1 |-> 0],
      strikePrice                  |-> [i \in 1 .. 7 |-> 0],
      strikePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Future Option Symbol at zero, then each field in turn at the values it is checked at *)
CheckedFutureOptionSymbol8 ==
    { ZeroFutureOptionSymbol8 }
        \cup { [ZeroFutureOptionSymbol8 EXCEPT !.root = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionSymbol8 EXCEPT !.symbolMonth = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionSymbol8 EXCEPT !.symbolYear = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionSymbol8 EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionSymbol8 EXCEPT !.callPutCode = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionSymbol8 EXCEPT !.strikePrice = one] : one \in Sample(7) }
        \cup { [ZeroFutureOptionSymbol8 EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Future Options Summary Message: 141 bytes                               *)
(***************************************************************************)

FutureOptionsSummaryMessage ==
    [ longMessageHeader                        : LongMessageHeader31,
      exchangeId                               : Sample(1),
      futureOptionSymbol                       : FutureOptionSymbol8,
      bidPriceSummary                          : Sample(7),
      bidPriceFractionIndicator                : Sample(1),
      bidSize                                  : Sample(5),
      askPriceSummary                          : Sample(7),
      askPriceFractionIndicator                : Sample(1),
      askSize                                  : Sample(5),
      lastPrice                                : Sample(7),
      lastPriceFractionIndicator               : Sample(1),
      openInterest                             : Sample(7),
      openInterestDate                         : Sample(6),
      tick                                     : Sample(1),
      volume                                   : Sample(8),
      netChangeSign                            : Sample(1),
      netChange                                : Sample(7),
      netChangeFractionIndicator               : Sample(1),
      openingPrice                             : Sample(7),
      openingPriceFractionIndicator            : Sample(1),
      highPrice                                : Sample(7),
      highPriceFractionIndicator               : Sample(1),
      lowPrice                                 : Sample(7),
      lowPriceFractionIndicator                : Sample(1),
      filler2                                  : Sample(2),
      settlementPrice                          : Sample(7),
      settlementPriceFractionIndicator         : Sample(1),
      previousSettlementPrice                  : Sample(7),
      previousSettlementPriceFractionIndicator : Sample(1),
      reason                                   : Sample(1) ]

EncodeFutureOptionsSummaryMessage(message) ==
    EncodeLongMessageHeader31(message.longMessageHeader)
        \o message.exchangeId
        \o EncodeFutureOptionSymbol8(message.futureOptionSymbol)
        \o message.bidPriceSummary
        \o message.bidPriceFractionIndicator
        \o message.bidSize
        \o message.askPriceSummary
        \o message.askPriceFractionIndicator
        \o message.askSize
        \o message.lastPrice
        \o message.lastPriceFractionIndicator
        \o message.openInterest
        \o message.openInterestDate
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
        \o message.settlementPrice
        \o message.settlementPriceFractionIndicator
        \o message.previousSettlementPrice
        \o message.previousSettlementPriceFractionIndicator
        \o message.reason

DecodeFutureOptionsSummaryMessage(bytes) ==
    LET longMessageHeader == DecodeLongMessageHeader31(bytes) IN IF ~longMessageHeader.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(longMessageHeader.rest, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET futureOptionSymbol == DecodeFutureOptionSymbol8(exchangeId.rest) IN IF ~futureOptionSymbol.ok THEN Fail ELSE
    LET bidPriceSummary == ReadBytes(futureOptionSymbol.rest, 7) IN IF ~bidPriceSummary.ok THEN Fail ELSE
    LET bidPriceFractionIndicator == ReadBytes(bidPriceSummary.rest, 1) IN IF ~bidPriceFractionIndicator.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPriceFractionIndicator.rest, 5) IN IF ~bidSize.ok THEN Fail ELSE
    LET askPriceSummary == ReadBytes(bidSize.rest, 7) IN IF ~askPriceSummary.ok THEN Fail ELSE
    LET askPriceFractionIndicator == ReadBytes(askPriceSummary.rest, 1) IN IF ~askPriceFractionIndicator.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPriceFractionIndicator.rest, 5) IN IF ~askSize.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(askSize.rest, 7) IN IF ~lastPrice.ok THEN Fail ELSE
    LET lastPriceFractionIndicator == ReadBytes(lastPrice.rest, 1) IN IF ~lastPriceFractionIndicator.ok THEN Fail ELSE
    LET openInterest == ReadBytes(lastPriceFractionIndicator.rest, 7) IN IF ~openInterest.ok THEN Fail ELSE
    LET openInterestDate == ReadBytes(openInterest.rest, 6) IN IF ~openInterestDate.ok THEN Fail ELSE
    LET tick == ReadBytes(openInterestDate.rest, 1) IN IF ~tick.ok THEN Fail ELSE
    LET volume == ReadBytes(tick.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET netChangeSign == ReadBytes(volume.rest, 1) IN IF ~netChangeSign.ok THEN Fail ELSE
    LET netChange == ReadBytes(netChangeSign.rest, 7) IN IF ~netChange.ok THEN Fail ELSE
    LET netChangeFractionIndicator == ReadBytes(netChange.rest, 1) IN IF ~netChangeFractionIndicator.ok THEN Fail ELSE
    LET openingPrice == ReadBytes(netChangeFractionIndicator.rest, 7) IN IF ~openingPrice.ok THEN Fail ELSE
    LET openingPriceFractionIndicator == ReadBytes(openingPrice.rest, 1) IN IF ~openingPriceFractionIndicator.ok THEN Fail ELSE
    LET highPrice == ReadBytes(openingPriceFractionIndicator.rest, 7) IN IF ~highPrice.ok THEN Fail ELSE
    LET highPriceFractionIndicator == ReadBytes(highPrice.rest, 1) IN IF ~highPriceFractionIndicator.ok THEN Fail ELSE
    LET lowPrice == ReadBytes(highPriceFractionIndicator.rest, 7) IN IF ~lowPrice.ok THEN Fail ELSE
    LET lowPriceFractionIndicator == ReadBytes(lowPrice.rest, 1) IN IF ~lowPriceFractionIndicator.ok THEN Fail ELSE
    LET filler2 == ReadBytes(lowPriceFractionIndicator.rest, 2) IN IF ~filler2.ok THEN Fail ELSE
    LET settlementPrice == ReadBytes(filler2.rest, 7) IN IF ~settlementPrice.ok THEN Fail ELSE
    LET settlementPriceFractionIndicator == ReadBytes(settlementPrice.rest, 1) IN IF ~settlementPriceFractionIndicator.ok THEN Fail ELSE
    LET previousSettlementPrice == ReadBytes(settlementPriceFractionIndicator.rest, 7) IN IF ~previousSettlementPrice.ok THEN Fail ELSE
    LET previousSettlementPriceFractionIndicator == ReadBytes(previousSettlementPrice.rest, 1) IN IF ~previousSettlementPriceFractionIndicator.ok THEN Fail ELSE
    LET reason == ReadBytes(previousSettlementPriceFractionIndicator.rest, 1) IN IF ~reason.ok THEN Fail ELSE
    Ok([ longMessageHeader                        |-> longMessageHeader.value,
         exchangeId                               |-> exchangeId.value,
         futureOptionSymbol                       |-> futureOptionSymbol.value,
         bidPriceSummary                          |-> bidPriceSummary.value,
         bidPriceFractionIndicator                |-> bidPriceFractionIndicator.value,
         bidSize                                  |-> bidSize.value,
         askPriceSummary                          |-> askPriceSummary.value,
         askPriceFractionIndicator                |-> askPriceFractionIndicator.value,
         askSize                                  |-> askSize.value,
         lastPrice                                |-> lastPrice.value,
         lastPriceFractionIndicator               |-> lastPriceFractionIndicator.value,
         openInterest                             |-> openInterest.value,
         openInterestDate                         |-> openInterestDate.value,
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
         settlementPrice                          |-> settlementPrice.value,
         settlementPriceFractionIndicator         |-> settlementPriceFractionIndicator.value,
         previousSettlementPrice                  |-> previousSettlementPrice.value,
         previousSettlementPriceFractionIndicator |-> previousSettlementPriceFractionIndicator.value,
         reason                                   |-> reason.value ], reason.rest)

ZeroFutureOptionsSummaryMessage ==
    [ longMessageHeader                        |-> ZeroLongMessageHeader31,
      exchangeId                               |-> [i \in 1 .. 1 |-> 0],
      futureOptionSymbol                       |-> ZeroFutureOptionSymbol8,
      bidPriceSummary                          |-> [i \in 1 .. 7 |-> 0],
      bidPriceFractionIndicator                |-> [i \in 1 .. 1 |-> 0],
      bidSize                                  |-> [i \in 1 .. 5 |-> 0],
      askPriceSummary                          |-> [i \in 1 .. 7 |-> 0],
      askPriceFractionIndicator                |-> [i \in 1 .. 1 |-> 0],
      askSize                                  |-> [i \in 1 .. 5 |-> 0],
      lastPrice                                |-> [i \in 1 .. 7 |-> 0],
      lastPriceFractionIndicator               |-> [i \in 1 .. 1 |-> 0],
      openInterest                             |-> [i \in 1 .. 7 |-> 0],
      openInterestDate                         |-> [i \in 1 .. 6 |-> 0],
      tick                                     |-> [i \in 1 .. 1 |-> 0],
      volume                                   |-> [i \in 1 .. 8 |-> 0],
      netChangeSign                            |-> [i \in 1 .. 1 |-> 0],
      netChange                                |-> [i \in 1 .. 7 |-> 0],
      netChangeFractionIndicator               |-> [i \in 1 .. 1 |-> 0],
      openingPrice                             |-> [i \in 1 .. 7 |-> 0],
      openingPriceFractionIndicator            |-> [i \in 1 .. 1 |-> 0],
      highPrice                                |-> [i \in 1 .. 7 |-> 0],
      highPriceFractionIndicator               |-> [i \in 1 .. 1 |-> 0],
      lowPrice                                 |-> [i \in 1 .. 7 |-> 0],
      lowPriceFractionIndicator                |-> [i \in 1 .. 1 |-> 0],
      filler2                                  |-> [i \in 1 .. 2 |-> 0],
      settlementPrice                          |-> [i \in 1 .. 7 |-> 0],
      settlementPriceFractionIndicator         |-> [i \in 1 .. 1 |-> 0],
      previousSettlementPrice                  |-> [i \in 1 .. 7 |-> 0],
      previousSettlementPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      reason                                   |-> [i \in 1 .. 1 |-> 0] ]

(* Future Options Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedFutureOptionsSummaryMessage ==
    { ZeroFutureOptionsSummaryMessage }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.longMessageHeader = one] : one \in CheckedLongMessageHeader31 }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.futureOptionSymbol = one] : one \in CheckedFutureOptionSymbol8 }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.bidPriceSummary = one] : one \in Sample(7) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.bidPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.bidSize = one] : one \in Sample(5) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.askPriceSummary = one] : one \in Sample(7) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.askPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.askSize = one] : one \in Sample(5) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.lastPrice = one] : one \in Sample(7) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.lastPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.openInterest = one] : one \in Sample(7) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.openInterestDate = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.tick = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.netChangeSign = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.netChange = one] : one \in Sample(7) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.netChangeFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.openingPrice = one] : one \in Sample(7) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.openingPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.highPrice = one] : one \in Sample(7) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.highPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.lowPrice = one] : one \in Sample(7) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.lowPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.filler2 = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.settlementPrice = one] : one \in Sample(7) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.settlementPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.previousSettlementPrice = one] : one \in Sample(7) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.previousSettlementPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.reason = one] : one \in Sample(1) }

(***************************************************************************)
(* Long Message Header: 12 bytes                                           *)
(***************************************************************************)

LongMessageHeader32 ==
    [ messageTimestamp : Sample(12) ]

EncodeLongMessageHeader32(message) ==
    message.messageTimestamp

DecodeLongMessageHeader32(bytes) ==
    LET messageTimestamp == ReadBytes(bytes, 12) IN IF ~messageTimestamp.ok THEN Fail ELSE
    Ok([ messageTimestamp |-> messageTimestamp.value ], messageTimestamp.rest)

ZeroLongMessageHeader32 ==
    [ messageTimestamp |-> [i \in 1 .. 12 |-> 0] ]

(* Long Message Header at zero, then each field in turn at the values it is checked at *)
CheckedLongMessageHeader32 ==
    { ZeroLongMessageHeader32 }
        \cup { [ZeroLongMessageHeader32 EXCEPT !.messageTimestamp = one] : one \in Sample(12) }

(***************************************************************************)
(* Future Product: 11 bytes                                                *)
(***************************************************************************)

FutureProduct8 ==
    [ root        : Sample(6),
      symbolMonth : Sample(1),
      symbolYear  : Sample(2),
      expiryDay   : Sample(2) ]

EncodeFutureProduct8(message) ==
    message.root
        \o message.symbolMonth
        \o message.symbolYear
        \o message.expiryDay

DecodeFutureProduct8(bytes) ==
    LET root == ReadBytes(bytes, 6) IN IF ~root.ok THEN Fail ELSE
    LET symbolMonth == ReadBytes(root.rest, 1) IN IF ~symbolMonth.ok THEN Fail ELSE
    LET symbolYear == ReadBytes(symbolMonth.rest, 2) IN IF ~symbolYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(symbolYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ root        |-> root.value,
         symbolMonth |-> symbolMonth.value,
         symbolYear  |-> symbolYear.value,
         expiryDay   |-> expiryDay.value ], expiryDay.rest)

ZeroFutureProduct8 ==
    [ root        |-> [i \in 1 .. 6 |-> 0],
      symbolMonth |-> [i \in 1 .. 1 |-> 0],
      symbolYear  |-> [i \in 1 .. 2 |-> 0],
      expiryDay   |-> [i \in 1 .. 2 |-> 0] ]

(* Future Product at zero, then each field in turn at the values it is checked at *)
CheckedFutureProduct8 ==
    { ZeroFutureProduct8 }
        \cup { [ZeroFutureProduct8 EXCEPT !.root = one] : one \in Sample(6) }
        \cup { [ZeroFutureProduct8 EXCEPT !.symbolMonth = one] : one \in Sample(1) }
        \cup { [ZeroFutureProduct8 EXCEPT !.symbolYear = one] : one \in Sample(2) }
        \cup { [ZeroFutureProduct8 EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Futures Summary Message: 137 bytes                                      *)
(***************************************************************************)

FuturesSummaryMessage ==
    [ longMessageHeader                   : LongMessageHeader32,
      exchangeId                          : Sample(1),
      futureProduct                       : FutureProduct8,
      bidPriceSummary                     : Sample(7),
      bidPriceFractionIndicator           : Sample(1),
      bidSize                             : Sample(5),
      askPriceSummary                     : Sample(7),
      askPriceFractionIndicator           : Sample(1),
      askSize                             : Sample(5),
      lastPrice                           : Sample(7),
      lastPriceFractionIndicator          : Sample(1),
      openPrice                           : Sample(7),
      openPriceFractionIndicator          : Sample(1),
      highPrice                           : Sample(7),
      highPriceFractionIndicator          : Sample(1),
      lowPrice                            : Sample(7),
      lowPriceFractionIndicator           : Sample(1),
      settlementPrice                     : Sample(7),
      settlementPriceFractionIndicator    : Sample(1),
      netChangeSign                       : Sample(1),
      netChange                           : Sample(7),
      netChangeFractionIndicator          : Sample(1),
      volume                              : Sample(8),
      previousSettlement                  : Sample(7),
      previousSettlementFractionIndicator : Sample(1),
      openInterest                        : Sample(7),
      openInterestDate                    : Sample(6),
      reason                              : Sample(1),
      externalPriceAtSource               : Sample(7),
      externalPriceFractionIndicator      : Sample(1) ]

EncodeFuturesSummaryMessage(message) ==
    EncodeLongMessageHeader32(message.longMessageHeader)
        \o message.exchangeId
        \o EncodeFutureProduct8(message.futureProduct)
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
        \o message.openInterestDate
        \o message.reason
        \o message.externalPriceAtSource
        \o message.externalPriceFractionIndicator

DecodeFuturesSummaryMessage(bytes) ==
    LET longMessageHeader == DecodeLongMessageHeader32(bytes) IN IF ~longMessageHeader.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(longMessageHeader.rest, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET futureProduct == DecodeFutureProduct8(exchangeId.rest) IN IF ~futureProduct.ok THEN Fail ELSE
    LET bidPriceSummary == ReadBytes(futureProduct.rest, 7) IN IF ~bidPriceSummary.ok THEN Fail ELSE
    LET bidPriceFractionIndicator == ReadBytes(bidPriceSummary.rest, 1) IN IF ~bidPriceFractionIndicator.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPriceFractionIndicator.rest, 5) IN IF ~bidSize.ok THEN Fail ELSE
    LET askPriceSummary == ReadBytes(bidSize.rest, 7) IN IF ~askPriceSummary.ok THEN Fail ELSE
    LET askPriceFractionIndicator == ReadBytes(askPriceSummary.rest, 1) IN IF ~askPriceFractionIndicator.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPriceFractionIndicator.rest, 5) IN IF ~askSize.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(askSize.rest, 7) IN IF ~lastPrice.ok THEN Fail ELSE
    LET lastPriceFractionIndicator == ReadBytes(lastPrice.rest, 1) IN IF ~lastPriceFractionIndicator.ok THEN Fail ELSE
    LET openPrice == ReadBytes(lastPriceFractionIndicator.rest, 7) IN IF ~openPrice.ok THEN Fail ELSE
    LET openPriceFractionIndicator == ReadBytes(openPrice.rest, 1) IN IF ~openPriceFractionIndicator.ok THEN Fail ELSE
    LET highPrice == ReadBytes(openPriceFractionIndicator.rest, 7) IN IF ~highPrice.ok THEN Fail ELSE
    LET highPriceFractionIndicator == ReadBytes(highPrice.rest, 1) IN IF ~highPriceFractionIndicator.ok THEN Fail ELSE
    LET lowPrice == ReadBytes(highPriceFractionIndicator.rest, 7) IN IF ~lowPrice.ok THEN Fail ELSE
    LET lowPriceFractionIndicator == ReadBytes(lowPrice.rest, 1) IN IF ~lowPriceFractionIndicator.ok THEN Fail ELSE
    LET settlementPrice == ReadBytes(lowPriceFractionIndicator.rest, 7) IN IF ~settlementPrice.ok THEN Fail ELSE
    LET settlementPriceFractionIndicator == ReadBytes(settlementPrice.rest, 1) IN IF ~settlementPriceFractionIndicator.ok THEN Fail ELSE
    LET netChangeSign == ReadBytes(settlementPriceFractionIndicator.rest, 1) IN IF ~netChangeSign.ok THEN Fail ELSE
    LET netChange == ReadBytes(netChangeSign.rest, 7) IN IF ~netChange.ok THEN Fail ELSE
    LET netChangeFractionIndicator == ReadBytes(netChange.rest, 1) IN IF ~netChangeFractionIndicator.ok THEN Fail ELSE
    LET volume == ReadBytes(netChangeFractionIndicator.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET previousSettlement == ReadBytes(volume.rest, 7) IN IF ~previousSettlement.ok THEN Fail ELSE
    LET previousSettlementFractionIndicator == ReadBytes(previousSettlement.rest, 1) IN IF ~previousSettlementFractionIndicator.ok THEN Fail ELSE
    LET openInterest == ReadBytes(previousSettlementFractionIndicator.rest, 7) IN IF ~openInterest.ok THEN Fail ELSE
    LET openInterestDate == ReadBytes(openInterest.rest, 6) IN IF ~openInterestDate.ok THEN Fail ELSE
    LET reason == ReadBytes(openInterestDate.rest, 1) IN IF ~reason.ok THEN Fail ELSE
    LET externalPriceAtSource == ReadBytes(reason.rest, 7) IN IF ~externalPriceAtSource.ok THEN Fail ELSE
    LET externalPriceFractionIndicator == ReadBytes(externalPriceAtSource.rest, 1) IN IF ~externalPriceFractionIndicator.ok THEN Fail ELSE
    Ok([ longMessageHeader                   |-> longMessageHeader.value,
         exchangeId                          |-> exchangeId.value,
         futureProduct                       |-> futureProduct.value,
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
         openInterestDate                    |-> openInterestDate.value,
         reason                              |-> reason.value,
         externalPriceAtSource               |-> externalPriceAtSource.value,
         externalPriceFractionIndicator      |-> externalPriceFractionIndicator.value ], externalPriceFractionIndicator.rest)

ZeroFuturesSummaryMessage ==
    [ longMessageHeader                   |-> ZeroLongMessageHeader32,
      exchangeId                          |-> [i \in 1 .. 1 |-> 0],
      futureProduct                       |-> ZeroFutureProduct8,
      bidPriceSummary                     |-> [i \in 1 .. 7 |-> 0],
      bidPriceFractionIndicator           |-> [i \in 1 .. 1 |-> 0],
      bidSize                             |-> [i \in 1 .. 5 |-> 0],
      askPriceSummary                     |-> [i \in 1 .. 7 |-> 0],
      askPriceFractionIndicator           |-> [i \in 1 .. 1 |-> 0],
      askSize                             |-> [i \in 1 .. 5 |-> 0],
      lastPrice                           |-> [i \in 1 .. 7 |-> 0],
      lastPriceFractionIndicator          |-> [i \in 1 .. 1 |-> 0],
      openPrice                           |-> [i \in 1 .. 7 |-> 0],
      openPriceFractionIndicator          |-> [i \in 1 .. 1 |-> 0],
      highPrice                           |-> [i \in 1 .. 7 |-> 0],
      highPriceFractionIndicator          |-> [i \in 1 .. 1 |-> 0],
      lowPrice                            |-> [i \in 1 .. 7 |-> 0],
      lowPriceFractionIndicator           |-> [i \in 1 .. 1 |-> 0],
      settlementPrice                     |-> [i \in 1 .. 7 |-> 0],
      settlementPriceFractionIndicator    |-> [i \in 1 .. 1 |-> 0],
      netChangeSign                       |-> [i \in 1 .. 1 |-> 0],
      netChange                           |-> [i \in 1 .. 7 |-> 0],
      netChangeFractionIndicator          |-> [i \in 1 .. 1 |-> 0],
      volume                              |-> [i \in 1 .. 8 |-> 0],
      previousSettlement                  |-> [i \in 1 .. 7 |-> 0],
      previousSettlementFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      openInterest                        |-> [i \in 1 .. 7 |-> 0],
      openInterestDate                    |-> [i \in 1 .. 6 |-> 0],
      reason                              |-> [i \in 1 .. 1 |-> 0],
      externalPriceAtSource               |-> [i \in 1 .. 7 |-> 0],
      externalPriceFractionIndicator      |-> [i \in 1 .. 1 |-> 0] ]

(* Futures Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedFuturesSummaryMessage ==
    { ZeroFuturesSummaryMessage }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.longMessageHeader = one] : one \in CheckedLongMessageHeader32 }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.futureProduct = one] : one \in CheckedFutureProduct8 }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.bidPriceSummary = one] : one \in Sample(7) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.bidPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.bidSize = one] : one \in Sample(5) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.askPriceSummary = one] : one \in Sample(7) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.askPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.askSize = one] : one \in Sample(5) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.lastPrice = one] : one \in Sample(7) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.lastPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.openPrice = one] : one \in Sample(7) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.openPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.highPrice = one] : one \in Sample(7) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.highPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.lowPrice = one] : one \in Sample(7) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.lowPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.settlementPrice = one] : one \in Sample(7) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.settlementPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.netChangeSign = one] : one \in Sample(1) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.netChange = one] : one \in Sample(7) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.netChangeFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.previousSettlement = one] : one \in Sample(7) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.previousSettlementFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.openInterest = one] : one \in Sample(7) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.openInterestDate = one] : one \in Sample(6) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.reason = one] : one \in Sample(1) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.externalPriceAtSource = one] : one \in Sample(7) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.externalPriceFractionIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Long Message Header: 12 bytes                                           *)
(***************************************************************************)

LongMessageHeader33 ==
    [ messageTimestamp : Sample(12) ]

EncodeLongMessageHeader33(message) ==
    message.messageTimestamp

DecodeLongMessageHeader33(bytes) ==
    LET messageTimestamp == ReadBytes(bytes, 12) IN IF ~messageTimestamp.ok THEN Fail ELSE
    Ok([ messageTimestamp |-> messageTimestamp.value ], messageTimestamp.rest)

ZeroLongMessageHeader33 ==
    [ messageTimestamp |-> [i \in 1 .. 12 |-> 0] ]

(* Long Message Header at zero, then each field in turn at the values it is checked at *)
CheckedLongMessageHeader33 ==
    { ZeroLongMessageHeader33 }
        \cup { [ZeroLongMessageHeader33 EXCEPT !.messageTimestamp = one] : one \in Sample(12) }

(***************************************************************************)
(* Strategy Summary Message: 125 bytes                                     *)
(***************************************************************************)

StrategySummaryMessage ==
    [ longMessageHeader          : LongMessageHeader33,
      exchangeId                 : Sample(1),
      strategySymbol             : Sample(30),
      bidPriceSign               : Sample(1),
      bidPriceSummary            : Sample(7),
      bidPriceFractionIndicator  : Sample(1),
      bidSize                    : Sample(5),
      askPriceSign               : Sample(1),
      askPriceSummary            : Sample(7),
      askPriceFractionIndicator  : Sample(1),
      askSize                    : Sample(5),
      lastPriceSign              : Sample(1),
      lastPrice                  : Sample(7),
      lastPriceFractionIndicator : Sample(1),
      openPriceSign              : Sample(1),
      openPrice                  : Sample(7),
      openPriceFractionIndicator : Sample(1),
      highPriceSign              : Sample(1),
      highPrice                  : Sample(7),
      highPriceFractionIndicator : Sample(1),
      lowPriceSign               : Sample(1),
      lowPrice                   : Sample(7),
      lowPriceFractionIndicator  : Sample(1),
      netChangeSign              : Sample(1),
      netChange                  : Sample(7),
      netChangeFractionIndicator : Sample(1),
      volume                     : Sample(8),
      reason                     : Sample(1) ]

EncodeStrategySummaryMessage(message) ==
    EncodeLongMessageHeader33(message.longMessageHeader)
        \o message.exchangeId
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

DecodeStrategySummaryMessage(bytes) ==
    LET longMessageHeader == DecodeLongMessageHeader33(bytes) IN IF ~longMessageHeader.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(longMessageHeader.rest, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET strategySymbol == ReadBytes(exchangeId.rest, 30) IN IF ~strategySymbol.ok THEN Fail ELSE
    LET bidPriceSign == ReadBytes(strategySymbol.rest, 1) IN IF ~bidPriceSign.ok THEN Fail ELSE
    LET bidPriceSummary == ReadBytes(bidPriceSign.rest, 7) IN IF ~bidPriceSummary.ok THEN Fail ELSE
    LET bidPriceFractionIndicator == ReadBytes(bidPriceSummary.rest, 1) IN IF ~bidPriceFractionIndicator.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPriceFractionIndicator.rest, 5) IN IF ~bidSize.ok THEN Fail ELSE
    LET askPriceSign == ReadBytes(bidSize.rest, 1) IN IF ~askPriceSign.ok THEN Fail ELSE
    LET askPriceSummary == ReadBytes(askPriceSign.rest, 7) IN IF ~askPriceSummary.ok THEN Fail ELSE
    LET askPriceFractionIndicator == ReadBytes(askPriceSummary.rest, 1) IN IF ~askPriceFractionIndicator.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPriceFractionIndicator.rest, 5) IN IF ~askSize.ok THEN Fail ELSE
    LET lastPriceSign == ReadBytes(askSize.rest, 1) IN IF ~lastPriceSign.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(lastPriceSign.rest, 7) IN IF ~lastPrice.ok THEN Fail ELSE
    LET lastPriceFractionIndicator == ReadBytes(lastPrice.rest, 1) IN IF ~lastPriceFractionIndicator.ok THEN Fail ELSE
    LET openPriceSign == ReadBytes(lastPriceFractionIndicator.rest, 1) IN IF ~openPriceSign.ok THEN Fail ELSE
    LET openPrice == ReadBytes(openPriceSign.rest, 7) IN IF ~openPrice.ok THEN Fail ELSE
    LET openPriceFractionIndicator == ReadBytes(openPrice.rest, 1) IN IF ~openPriceFractionIndicator.ok THEN Fail ELSE
    LET highPriceSign == ReadBytes(openPriceFractionIndicator.rest, 1) IN IF ~highPriceSign.ok THEN Fail ELSE
    LET highPrice == ReadBytes(highPriceSign.rest, 7) IN IF ~highPrice.ok THEN Fail ELSE
    LET highPriceFractionIndicator == ReadBytes(highPrice.rest, 1) IN IF ~highPriceFractionIndicator.ok THEN Fail ELSE
    LET lowPriceSign == ReadBytes(highPriceFractionIndicator.rest, 1) IN IF ~lowPriceSign.ok THEN Fail ELSE
    LET lowPrice == ReadBytes(lowPriceSign.rest, 7) IN IF ~lowPrice.ok THEN Fail ELSE
    LET lowPriceFractionIndicator == ReadBytes(lowPrice.rest, 1) IN IF ~lowPriceFractionIndicator.ok THEN Fail ELSE
    LET netChangeSign == ReadBytes(lowPriceFractionIndicator.rest, 1) IN IF ~netChangeSign.ok THEN Fail ELSE
    LET netChange == ReadBytes(netChangeSign.rest, 7) IN IF ~netChange.ok THEN Fail ELSE
    LET netChangeFractionIndicator == ReadBytes(netChange.rest, 1) IN IF ~netChangeFractionIndicator.ok THEN Fail ELSE
    LET volume == ReadBytes(netChangeFractionIndicator.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET reason == ReadBytes(volume.rest, 1) IN IF ~reason.ok THEN Fail ELSE
    Ok([ longMessageHeader          |-> longMessageHeader.value,
         exchangeId                 |-> exchangeId.value,
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
         reason                     |-> reason.value ], reason.rest)

ZeroStrategySummaryMessage ==
    [ longMessageHeader          |-> ZeroLongMessageHeader33,
      exchangeId                 |-> [i \in 1 .. 1 |-> 0],
      strategySymbol             |-> [i \in 1 .. 30 |-> 0],
      bidPriceSign               |-> [i \in 1 .. 1 |-> 0],
      bidPriceSummary            |-> [i \in 1 .. 7 |-> 0],
      bidPriceFractionIndicator  |-> [i \in 1 .. 1 |-> 0],
      bidSize                    |-> [i \in 1 .. 5 |-> 0],
      askPriceSign               |-> [i \in 1 .. 1 |-> 0],
      askPriceSummary            |-> [i \in 1 .. 7 |-> 0],
      askPriceFractionIndicator  |-> [i \in 1 .. 1 |-> 0],
      askSize                    |-> [i \in 1 .. 5 |-> 0],
      lastPriceSign              |-> [i \in 1 .. 1 |-> 0],
      lastPrice                  |-> [i \in 1 .. 7 |-> 0],
      lastPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      openPriceSign              |-> [i \in 1 .. 1 |-> 0],
      openPrice                  |-> [i \in 1 .. 7 |-> 0],
      openPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      highPriceSign              |-> [i \in 1 .. 1 |-> 0],
      highPrice                  |-> [i \in 1 .. 7 |-> 0],
      highPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      lowPriceSign               |-> [i \in 1 .. 1 |-> 0],
      lowPrice                   |-> [i \in 1 .. 7 |-> 0],
      lowPriceFractionIndicator  |-> [i \in 1 .. 1 |-> 0],
      netChangeSign              |-> [i \in 1 .. 1 |-> 0],
      netChange                  |-> [i \in 1 .. 7 |-> 0],
      netChangeFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      volume                     |-> [i \in 1 .. 8 |-> 0],
      reason                     |-> [i \in 1 .. 1 |-> 0] ]

(* Strategy Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedStrategySummaryMessage ==
    { ZeroStrategySummaryMessage }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.longMessageHeader = one] : one \in CheckedLongMessageHeader33 }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.strategySymbol = one] : one \in Sample(30) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.bidPriceSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.bidPriceSummary = one] : one \in Sample(7) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.bidPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.bidSize = one] : one \in Sample(5) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.askPriceSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.askPriceSummary = one] : one \in Sample(7) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.askPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.askSize = one] : one \in Sample(5) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.lastPriceSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.lastPrice = one] : one \in Sample(7) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.lastPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.openPriceSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.openPrice = one] : one \in Sample(7) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.openPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.highPriceSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.highPrice = one] : one \in Sample(7) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.highPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.lowPriceSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.lowPrice = one] : one \in Sample(7) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.lowPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.netChangeSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.netChange = one] : one \in Sample(7) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.netChangeFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.reason = one] : one \in Sample(1) }

(***************************************************************************)
(* Long Message Header: 12 bytes                                           *)
(***************************************************************************)

LongMessageHeader34 ==
    [ messageTimestamp : Sample(12) ]

EncodeLongMessageHeader34(message) ==
    message.messageTimestamp

DecodeLongMessageHeader34(bytes) ==
    LET messageTimestamp == ReadBytes(bytes, 12) IN IF ~messageTimestamp.ok THEN Fail ELSE
    Ok([ messageTimestamp |-> messageTimestamp.value ], messageTimestamp.rest)

ZeroLongMessageHeader34 ==
    [ messageTimestamp |-> [i \in 1 .. 12 |-> 0] ]

(* Long Message Header at zero, then each field in turn at the values it is checked at *)
CheckedLongMessageHeader34 ==
    { ZeroLongMessageHeader34 }
        \cup { [ZeroLongMessageHeader34 EXCEPT !.messageTimestamp = one] : one \in Sample(12) }

(***************************************************************************)
(* Beginning Of Options Summary Message: 13 bytes                          *)
(***************************************************************************)

BeginningOfOptionsSummaryMessage ==
    [ longMessageHeader : LongMessageHeader34,
      exchangeId        : Sample(1) ]

EncodeBeginningOfOptionsSummaryMessage(message) ==
    EncodeLongMessageHeader34(message.longMessageHeader)
        \o message.exchangeId

DecodeBeginningOfOptionsSummaryMessage(bytes) ==
    LET longMessageHeader == DecodeLongMessageHeader34(bytes) IN IF ~longMessageHeader.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(longMessageHeader.rest, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    Ok([ longMessageHeader |-> longMessageHeader.value,
         exchangeId        |-> exchangeId.value ], exchangeId.rest)

ZeroBeginningOfOptionsSummaryMessage ==
    [ longMessageHeader |-> ZeroLongMessageHeader34,
      exchangeId        |-> [i \in 1 .. 1 |-> 0] ]

(* Beginning Of Options Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedBeginningOfOptionsSummaryMessage ==
    { ZeroBeginningOfOptionsSummaryMessage }
        \cup { [ZeroBeginningOfOptionsSummaryMessage EXCEPT !.longMessageHeader = one] : one \in CheckedLongMessageHeader34 }
        \cup { [ZeroBeginningOfOptionsSummaryMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }

(***************************************************************************)
(* Long Message Header: 12 bytes                                           *)
(***************************************************************************)

LongMessageHeader35 ==
    [ messageTimestamp : Sample(12) ]

EncodeLongMessageHeader35(message) ==
    message.messageTimestamp

DecodeLongMessageHeader35(bytes) ==
    LET messageTimestamp == ReadBytes(bytes, 12) IN IF ~messageTimestamp.ok THEN Fail ELSE
    Ok([ messageTimestamp |-> messageTimestamp.value ], messageTimestamp.rest)

ZeroLongMessageHeader35 ==
    [ messageTimestamp |-> [i \in 1 .. 12 |-> 0] ]

(* Long Message Header at zero, then each field in turn at the values it is checked at *)
CheckedLongMessageHeader35 ==
    { ZeroLongMessageHeader35 }
        \cup { [ZeroLongMessageHeader35 EXCEPT !.messageTimestamp = one] : one \in Sample(12) }

(***************************************************************************)
(* Beginning Of Future Options Summary Message: 13 bytes                   *)
(***************************************************************************)

BeginningOfFutureOptionsSummaryMessage ==
    [ longMessageHeader : LongMessageHeader35,
      exchangeId        : Sample(1) ]

EncodeBeginningOfFutureOptionsSummaryMessage(message) ==
    EncodeLongMessageHeader35(message.longMessageHeader)
        \o message.exchangeId

DecodeBeginningOfFutureOptionsSummaryMessage(bytes) ==
    LET longMessageHeader == DecodeLongMessageHeader35(bytes) IN IF ~longMessageHeader.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(longMessageHeader.rest, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    Ok([ longMessageHeader |-> longMessageHeader.value,
         exchangeId        |-> exchangeId.value ], exchangeId.rest)

ZeroBeginningOfFutureOptionsSummaryMessage ==
    [ longMessageHeader |-> ZeroLongMessageHeader35,
      exchangeId        |-> [i \in 1 .. 1 |-> 0] ]

(* Beginning Of Future Options Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedBeginningOfFutureOptionsSummaryMessage ==
    { ZeroBeginningOfFutureOptionsSummaryMessage }
        \cup { [ZeroBeginningOfFutureOptionsSummaryMessage EXCEPT !.longMessageHeader = one] : one \in CheckedLongMessageHeader35 }
        \cup { [ZeroBeginningOfFutureOptionsSummaryMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }

(***************************************************************************)
(* Long Message Header: 12 bytes                                           *)
(***************************************************************************)

LongMessageHeader36 ==
    [ messageTimestamp : Sample(12) ]

EncodeLongMessageHeader36(message) ==
    message.messageTimestamp

DecodeLongMessageHeader36(bytes) ==
    LET messageTimestamp == ReadBytes(bytes, 12) IN IF ~messageTimestamp.ok THEN Fail ELSE
    Ok([ messageTimestamp |-> messageTimestamp.value ], messageTimestamp.rest)

ZeroLongMessageHeader36 ==
    [ messageTimestamp |-> [i \in 1 .. 12 |-> 0] ]

(* Long Message Header at zero, then each field in turn at the values it is checked at *)
CheckedLongMessageHeader36 ==
    { ZeroLongMessageHeader36 }
        \cup { [ZeroLongMessageHeader36 EXCEPT !.messageTimestamp = one] : one \in Sample(12) }

(***************************************************************************)
(* Beginning Of Futures Summary Message: 13 bytes                          *)
(***************************************************************************)

BeginningOfFuturesSummaryMessage ==
    [ longMessageHeader : LongMessageHeader36,
      exchangeId        : Sample(1) ]

EncodeBeginningOfFuturesSummaryMessage(message) ==
    EncodeLongMessageHeader36(message.longMessageHeader)
        \o message.exchangeId

DecodeBeginningOfFuturesSummaryMessage(bytes) ==
    LET longMessageHeader == DecodeLongMessageHeader36(bytes) IN IF ~longMessageHeader.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(longMessageHeader.rest, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    Ok([ longMessageHeader |-> longMessageHeader.value,
         exchangeId        |-> exchangeId.value ], exchangeId.rest)

ZeroBeginningOfFuturesSummaryMessage ==
    [ longMessageHeader |-> ZeroLongMessageHeader36,
      exchangeId        |-> [i \in 1 .. 1 |-> 0] ]

(* Beginning Of Futures Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedBeginningOfFuturesSummaryMessage ==
    { ZeroBeginningOfFuturesSummaryMessage }
        \cup { [ZeroBeginningOfFuturesSummaryMessage EXCEPT !.longMessageHeader = one] : one \in CheckedLongMessageHeader36 }
        \cup { [ZeroBeginningOfFuturesSummaryMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }

(***************************************************************************)
(* Long Message Header: 12 bytes                                           *)
(***************************************************************************)

LongMessageHeader37 ==
    [ messageTimestamp : Sample(12) ]

EncodeLongMessageHeader37(message) ==
    message.messageTimestamp

DecodeLongMessageHeader37(bytes) ==
    LET messageTimestamp == ReadBytes(bytes, 12) IN IF ~messageTimestamp.ok THEN Fail ELSE
    Ok([ messageTimestamp |-> messageTimestamp.value ], messageTimestamp.rest)

ZeroLongMessageHeader37 ==
    [ messageTimestamp |-> [i \in 1 .. 12 |-> 0] ]

(* Long Message Header at zero, then each field in turn at the values it is checked at *)
CheckedLongMessageHeader37 ==
    { ZeroLongMessageHeader37 }
        \cup { [ZeroLongMessageHeader37 EXCEPT !.messageTimestamp = one] : one \in Sample(12) }

(***************************************************************************)
(* Beginning Of Strategy Summary Message: 13 bytes                         *)
(***************************************************************************)

BeginningOfStrategySummaryMessage ==
    [ longMessageHeader : LongMessageHeader37,
      exchangeId        : Sample(1) ]

EncodeBeginningOfStrategySummaryMessage(message) ==
    EncodeLongMessageHeader37(message.longMessageHeader)
        \o message.exchangeId

DecodeBeginningOfStrategySummaryMessage(bytes) ==
    LET longMessageHeader == DecodeLongMessageHeader37(bytes) IN IF ~longMessageHeader.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(longMessageHeader.rest, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    Ok([ longMessageHeader |-> longMessageHeader.value,
         exchangeId        |-> exchangeId.value ], exchangeId.rest)

ZeroBeginningOfStrategySummaryMessage ==
    [ longMessageHeader |-> ZeroLongMessageHeader37,
      exchangeId        |-> [i \in 1 .. 1 |-> 0] ]

(* Beginning Of Strategy Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedBeginningOfStrategySummaryMessage ==
    { ZeroBeginningOfStrategySummaryMessage }
        \cup { [ZeroBeginningOfStrategySummaryMessage EXCEPT !.longMessageHeader = one] : one \in CheckedLongMessageHeader37 }
        \cup { [ZeroBeginningOfStrategySummaryMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }

(***************************************************************************)
(* Long Message Header: 12 bytes                                           *)
(***************************************************************************)

LongMessageHeader38 ==
    [ messageTimestamp : Sample(12) ]

EncodeLongMessageHeader38(message) ==
    message.messageTimestamp

DecodeLongMessageHeader38(bytes) ==
    LET messageTimestamp == ReadBytes(bytes, 12) IN IF ~messageTimestamp.ok THEN Fail ELSE
    Ok([ messageTimestamp |-> messageTimestamp.value ], messageTimestamp.rest)

ZeroLongMessageHeader38 ==
    [ messageTimestamp |-> [i \in 1 .. 12 |-> 0] ]

(* Long Message Header at zero, then each field in turn at the values it is checked at *)
CheckedLongMessageHeader38 ==
    { ZeroLongMessageHeader38 }
        \cup { [ZeroLongMessageHeader38 EXCEPT !.messageTimestamp = one] : one \in Sample(12) }

(***************************************************************************)
(* Future Product: 11 bytes                                                *)
(***************************************************************************)

FutureProduct9 ==
    [ root        : Sample(6),
      symbolMonth : Sample(1),
      symbolYear  : Sample(2),
      expiryDay   : Sample(2) ]

EncodeFutureProduct9(message) ==
    message.root
        \o message.symbolMonth
        \o message.symbolYear
        \o message.expiryDay

DecodeFutureProduct9(bytes) ==
    LET root == ReadBytes(bytes, 6) IN IF ~root.ok THEN Fail ELSE
    LET symbolMonth == ReadBytes(root.rest, 1) IN IF ~symbolMonth.ok THEN Fail ELSE
    LET symbolYear == ReadBytes(symbolMonth.rest, 2) IN IF ~symbolYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(symbolYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ root        |-> root.value,
         symbolMonth |-> symbolMonth.value,
         symbolYear  |-> symbolYear.value,
         expiryDay   |-> expiryDay.value ], expiryDay.rest)

ZeroFutureProduct9 ==
    [ root        |-> [i \in 1 .. 6 |-> 0],
      symbolMonth |-> [i \in 1 .. 1 |-> 0],
      symbolYear  |-> [i \in 1 .. 2 |-> 0],
      expiryDay   |-> [i \in 1 .. 2 |-> 0] ]

(* Future Product at zero, then each field in turn at the values it is checked at *)
CheckedFutureProduct9 ==
    { ZeroFutureProduct9 }
        \cup { [ZeroFutureProduct9 EXCEPT !.root = one] : one \in Sample(6) }
        \cup { [ZeroFutureProduct9 EXCEPT !.symbolMonth = one] : one \in Sample(1) }
        \cup { [ZeroFutureProduct9 EXCEPT !.symbolYear = one] : one \in Sample(2) }
        \cup { [ZeroFutureProduct9 EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Futures Trade Correction Message: 73 bytes                              *)
(***************************************************************************)

FuturesTradeCorrectionMessage ==
    [ longMessageHeader           : LongMessageHeader38,
      exchangeId                  : Sample(1),
      futureProduct               : FutureProduct9,
      volume                      : Sample(8),
      tradePrice                  : Sample(7),
      tradePriceFractionIndicator : Sample(1),
      netChangeSign               : Sample(1),
      netChange                   : Sample(7),
      netChangeFractionIndicator  : Sample(1),
      filler6                     : Sample(6),
      tradeTimestamp              : Sample(9),
      priceIndicatorMarker        : Sample(1),
      tradeNumber                 : Sample(8) ]

EncodeFuturesTradeCorrectionMessage(message) ==
    EncodeLongMessageHeader38(message.longMessageHeader)
        \o message.exchangeId
        \o EncodeFutureProduct9(message.futureProduct)
        \o message.volume
        \o message.tradePrice
        \o message.tradePriceFractionIndicator
        \o message.netChangeSign
        \o message.netChange
        \o message.netChangeFractionIndicator
        \o message.filler6
        \o message.tradeTimestamp
        \o message.priceIndicatorMarker
        \o message.tradeNumber

DecodeFuturesTradeCorrectionMessage(bytes) ==
    LET longMessageHeader == DecodeLongMessageHeader38(bytes) IN IF ~longMessageHeader.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(longMessageHeader.rest, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET futureProduct == DecodeFutureProduct9(exchangeId.rest) IN IF ~futureProduct.ok THEN Fail ELSE
    LET volume == ReadBytes(futureProduct.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(volume.rest, 7) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradePriceFractionIndicator == ReadBytes(tradePrice.rest, 1) IN IF ~tradePriceFractionIndicator.ok THEN Fail ELSE
    LET netChangeSign == ReadBytes(tradePriceFractionIndicator.rest, 1) IN IF ~netChangeSign.ok THEN Fail ELSE
    LET netChange == ReadBytes(netChangeSign.rest, 7) IN IF ~netChange.ok THEN Fail ELSE
    LET netChangeFractionIndicator == ReadBytes(netChange.rest, 1) IN IF ~netChangeFractionIndicator.ok THEN Fail ELSE
    LET filler6 == ReadBytes(netChangeFractionIndicator.rest, 6) IN IF ~filler6.ok THEN Fail ELSE
    LET tradeTimestamp == ReadBytes(filler6.rest, 9) IN IF ~tradeTimestamp.ok THEN Fail ELSE
    LET priceIndicatorMarker == ReadBytes(tradeTimestamp.rest, 1) IN IF ~priceIndicatorMarker.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(priceIndicatorMarker.rest, 8) IN IF ~tradeNumber.ok THEN Fail ELSE
    Ok([ longMessageHeader           |-> longMessageHeader.value,
         exchangeId                  |-> exchangeId.value,
         futureProduct               |-> futureProduct.value,
         volume                      |-> volume.value,
         tradePrice                  |-> tradePrice.value,
         tradePriceFractionIndicator |-> tradePriceFractionIndicator.value,
         netChangeSign               |-> netChangeSign.value,
         netChange                   |-> netChange.value,
         netChangeFractionIndicator  |-> netChangeFractionIndicator.value,
         filler6                     |-> filler6.value,
         tradeTimestamp              |-> tradeTimestamp.value,
         priceIndicatorMarker        |-> priceIndicatorMarker.value,
         tradeNumber                 |-> tradeNumber.value ], tradeNumber.rest)

ZeroFuturesTradeCorrectionMessage ==
    [ longMessageHeader           |-> ZeroLongMessageHeader38,
      exchangeId                  |-> [i \in 1 .. 1 |-> 0],
      futureProduct               |-> ZeroFutureProduct9,
      volume                      |-> [i \in 1 .. 8 |-> 0],
      tradePrice                  |-> [i \in 1 .. 7 |-> 0],
      tradePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      netChangeSign               |-> [i \in 1 .. 1 |-> 0],
      netChange                   |-> [i \in 1 .. 7 |-> 0],
      netChangeFractionIndicator  |-> [i \in 1 .. 1 |-> 0],
      filler6                     |-> [i \in 1 .. 6 |-> 0],
      tradeTimestamp              |-> [i \in 1 .. 9 |-> 0],
      priceIndicatorMarker        |-> [i \in 1 .. 1 |-> 0],
      tradeNumber                 |-> [i \in 1 .. 8 |-> 0] ]

(* Futures Trade Correction Message at zero, then each field in turn at the values it is checked at *)
CheckedFuturesTradeCorrectionMessage ==
    { ZeroFuturesTradeCorrectionMessage }
        \cup { [ZeroFuturesTradeCorrectionMessage EXCEPT !.longMessageHeader = one] : one \in CheckedLongMessageHeader38 }
        \cup { [ZeroFuturesTradeCorrectionMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroFuturesTradeCorrectionMessage EXCEPT !.futureProduct = one] : one \in CheckedFutureProduct9 }
        \cup { [ZeroFuturesTradeCorrectionMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroFuturesTradeCorrectionMessage EXCEPT !.tradePrice = one] : one \in Sample(7) }
        \cup { [ZeroFuturesTradeCorrectionMessage EXCEPT !.tradePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFuturesTradeCorrectionMessage EXCEPT !.netChangeSign = one] : one \in Sample(1) }
        \cup { [ZeroFuturesTradeCorrectionMessage EXCEPT !.netChange = one] : one \in Sample(7) }
        \cup { [ZeroFuturesTradeCorrectionMessage EXCEPT !.netChangeFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFuturesTradeCorrectionMessage EXCEPT !.filler6 = one] : one \in Sample(6) }
        \cup { [ZeroFuturesTradeCorrectionMessage EXCEPT !.tradeTimestamp = one] : one \in Sample(9) }
        \cup { [ZeroFuturesTradeCorrectionMessage EXCEPT !.priceIndicatorMarker = one] : one \in Sample(1) }
        \cup { [ZeroFuturesTradeCorrectionMessage EXCEPT !.tradeNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Long Message Header: 12 bytes                                           *)
(***************************************************************************)

LongMessageHeader39 ==
    [ messageTimestamp : Sample(12) ]

EncodeLongMessageHeader39(message) ==
    message.messageTimestamp

DecodeLongMessageHeader39(bytes) ==
    LET messageTimestamp == ReadBytes(bytes, 12) IN IF ~messageTimestamp.ok THEN Fail ELSE
    Ok([ messageTimestamp |-> messageTimestamp.value ], messageTimestamp.rest)

ZeroLongMessageHeader39 ==
    [ messageTimestamp |-> [i \in 1 .. 12 |-> 0] ]

(* Long Message Header at zero, then each field in turn at the values it is checked at *)
CheckedLongMessageHeader39 ==
    { ZeroLongMessageHeader39 }
        \cup { [ZeroLongMessageHeader39 EXCEPT !.messageTimestamp = one] : one \in Sample(12) }

(***************************************************************************)
(* Group Status Message: 20 bytes                                          *)
(***************************************************************************)

GroupStatusMessage ==
    [ longMessageHeader : LongMessageHeader39,
      exchangeId        : Sample(1),
      rootSymbol        : Sample(6),
      groupStatus       : Sample(1) ]

EncodeGroupStatusMessage(message) ==
    EncodeLongMessageHeader39(message.longMessageHeader)
        \o message.exchangeId
        \o message.rootSymbol
        \o message.groupStatus

DecodeGroupStatusMessage(bytes) ==
    LET longMessageHeader == DecodeLongMessageHeader39(bytes) IN IF ~longMessageHeader.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(longMessageHeader.rest, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET rootSymbol == ReadBytes(exchangeId.rest, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET groupStatus == ReadBytes(rootSymbol.rest, 1) IN IF ~groupStatus.ok THEN Fail ELSE
    Ok([ longMessageHeader |-> longMessageHeader.value,
         exchangeId        |-> exchangeId.value,
         rootSymbol        |-> rootSymbol.value,
         groupStatus       |-> groupStatus.value ], groupStatus.rest)

ZeroGroupStatusMessage ==
    [ longMessageHeader |-> ZeroLongMessageHeader39,
      exchangeId        |-> [i \in 1 .. 1 |-> 0],
      rootSymbol        |-> [i \in 1 .. 6 |-> 0],
      groupStatus       |-> [i \in 1 .. 1 |-> 0] ]

(* Group Status Message at zero, then each field in turn at the values it is checked at *)
CheckedGroupStatusMessage ==
    { ZeroGroupStatusMessage }
        \cup { [ZeroGroupStatusMessage EXCEPT !.longMessageHeader = one] : one \in CheckedLongMessageHeader39 }
        \cup { [ZeroGroupStatusMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroGroupStatusMessage EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroGroupStatusMessage EXCEPT !.groupStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Long Message Header: 12 bytes                                           *)
(***************************************************************************)

LongMessageHeader40 ==
    [ messageTimestamp : Sample(12) ]

EncodeLongMessageHeader40(message) ==
    message.messageTimestamp

DecodeLongMessageHeader40(bytes) ==
    LET messageTimestamp == ReadBytes(bytes, 12) IN IF ~messageTimestamp.ok THEN Fail ELSE
    Ok([ messageTimestamp |-> messageTimestamp.value ], messageTimestamp.rest)

ZeroLongMessageHeader40 ==
    [ messageTimestamp |-> [i \in 1 .. 12 |-> 0] ]

(* Long Message Header at zero, then each field in turn at the values it is checked at *)
CheckedLongMessageHeader40 ==
    { ZeroLongMessageHeader40 }
        \cup { [ZeroLongMessageHeader40 EXCEPT !.messageTimestamp = one] : one \in Sample(12) }

(***************************************************************************)
(* Group Status Strategies Message: 16 bytes                               *)
(***************************************************************************)

GroupStatusStrategiesMessage ==
    [ longMessageHeader : LongMessageHeader40,
      exchangeId        : Sample(1),
      groupInstrument   : Sample(2),
      groupStatus       : Sample(1) ]

EncodeGroupStatusStrategiesMessage(message) ==
    EncodeLongMessageHeader40(message.longMessageHeader)
        \o message.exchangeId
        \o message.groupInstrument
        \o message.groupStatus

DecodeGroupStatusStrategiesMessage(bytes) ==
    LET longMessageHeader == DecodeLongMessageHeader40(bytes) IN IF ~longMessageHeader.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(longMessageHeader.rest, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET groupInstrument == ReadBytes(exchangeId.rest, 2) IN IF ~groupInstrument.ok THEN Fail ELSE
    LET groupStatus == ReadBytes(groupInstrument.rest, 1) IN IF ~groupStatus.ok THEN Fail ELSE
    Ok([ longMessageHeader |-> longMessageHeader.value,
         exchangeId        |-> exchangeId.value,
         groupInstrument   |-> groupInstrument.value,
         groupStatus       |-> groupStatus.value ], groupStatus.rest)

ZeroGroupStatusStrategiesMessage ==
    [ longMessageHeader |-> ZeroLongMessageHeader40,
      exchangeId        |-> [i \in 1 .. 1 |-> 0],
      groupInstrument   |-> [i \in 1 .. 2 |-> 0],
      groupStatus       |-> [i \in 1 .. 1 |-> 0] ]

(* Group Status Strategies Message at zero, then each field in turn at the values it is checked at *)
CheckedGroupStatusStrategiesMessage ==
    { ZeroGroupStatusStrategiesMessage }
        \cup { [ZeroGroupStatusStrategiesMessage EXCEPT !.longMessageHeader = one] : one \in CheckedLongMessageHeader40 }
        \cup { [ZeroGroupStatusStrategiesMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroGroupStatusStrategiesMessage EXCEPT !.groupInstrument = one] : one \in Sample(2) }
        \cup { [ZeroGroupStatusStrategiesMessage EXCEPT !.groupStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Long Message Header: 12 bytes                                           *)
(***************************************************************************)

LongMessageHeader41 ==
    [ messageTimestamp : Sample(12) ]

EncodeLongMessageHeader41(message) ==
    message.messageTimestamp

DecodeLongMessageHeader41(bytes) ==
    LET messageTimestamp == ReadBytes(bytes, 12) IN IF ~messageTimestamp.ok THEN Fail ELSE
    Ok([ messageTimestamp |-> messageTimestamp.value ], messageTimestamp.rest)

ZeroLongMessageHeader41 ==
    [ messageTimestamp |-> [i \in 1 .. 12 |-> 0] ]

(* Long Message Header at zero, then each field in turn at the values it is checked at *)
CheckedLongMessageHeader41 ==
    { ZeroLongMessageHeader41 }
        \cup { [ZeroLongMessageHeader41 EXCEPT !.messageTimestamp = one] : one \in Sample(12) }

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
    [ longMessageHeader : LongMessageHeader41,
      reserved          : Sample(1),
      bulletin          : Bulletin ]

EncodeBulletinsMessage(message) ==
    EncodeLongMessageHeader41(message.longMessageHeader)
        \o message.reserved
        \o EncodeUIntBE(message.bulletin.tag, 1)
        \o EncodeBulletin(message.bulletin)

DecodeBulletinsMessage(bytes) ==
    LET longMessageHeader == DecodeLongMessageHeader41(bytes) IN IF ~longMessageHeader.ok THEN Fail ELSE
    LET reserved == ReadBytes(longMessageHeader.rest, 1) IN IF ~reserved.ok THEN Fail ELSE
    LET bulletinType == ReadUIntBE(reserved.rest, 1) IN IF ~bulletinType.ok THEN Fail ELSE
    LET bulletin == DecodeBulletin(bulletinType.value, bulletinType.rest) IN IF ~bulletin.ok THEN Fail ELSE
    Ok([ longMessageHeader |-> longMessageHeader.value,
         reserved          |-> reserved.value,
         bulletin          |-> bulletin.value ], bulletin.rest)

ZeroBulletinsMessage ==
    [ longMessageHeader |-> ZeroLongMessageHeader41,
      reserved          |-> [i \in 1 .. 1 |-> 0],
      bulletin          |-> ZeroBulletin ]

(* Bulletins Message at zero, then each field in turn at the values it is checked at *)
CheckedBulletinsMessage ==
    { ZeroBulletinsMessage }
        \cup { [ZeroBulletinsMessage EXCEPT !.longMessageHeader = one] : one \in CheckedLongMessageHeader41 }
        \cup { [ZeroBulletinsMessage EXCEPT !.reserved = one] : one \in Sample(1) }
        \cup { [ZeroBulletinsMessage EXCEPT !.bulletin = one] : one \in CheckedBulletin }

(***************************************************************************)
(* Long Message Header: 12 bytes                                           *)
(***************************************************************************)

LongMessageHeader42 ==
    [ messageTimestamp : Sample(12) ]

EncodeLongMessageHeader42(message) ==
    message.messageTimestamp

DecodeLongMessageHeader42(bytes) ==
    LET messageTimestamp == ReadBytes(bytes, 12) IN IF ~messageTimestamp.ok THEN Fail ELSE
    Ok([ messageTimestamp |-> messageTimestamp.value ], messageTimestamp.rest)

ZeroLongMessageHeader42 ==
    [ messageTimestamp |-> [i \in 1 .. 12 |-> 0] ]

(* Long Message Header at zero, then each field in turn at the values it is checked at *)
CheckedLongMessageHeader42 ==
    { ZeroLongMessageHeader42 }
        \cup { [ZeroLongMessageHeader42 EXCEPT !.messageTimestamp = one] : one \in Sample(12) }

(***************************************************************************)
(* End Of Sales Message: 19 bytes                                          *)
(***************************************************************************)

EndOfSalesMessage ==
    [ longMessageHeader : LongMessageHeader42,
      reserved          : Sample(1),
      time              : Sample(6) ]

EncodeEndOfSalesMessage(message) ==
    EncodeLongMessageHeader42(message.longMessageHeader)
        \o message.reserved
        \o message.time

DecodeEndOfSalesMessage(bytes) ==
    LET longMessageHeader == DecodeLongMessageHeader42(bytes) IN IF ~longMessageHeader.ok THEN Fail ELSE
    LET reserved == ReadBytes(longMessageHeader.rest, 1) IN IF ~reserved.ok THEN Fail ELSE
    LET time == ReadBytes(reserved.rest, 6) IN IF ~time.ok THEN Fail ELSE
    Ok([ longMessageHeader |-> longMessageHeader.value,
         reserved          |-> reserved.value,
         time              |-> time.value ], time.rest)

ZeroEndOfSalesMessage ==
    [ longMessageHeader |-> ZeroLongMessageHeader42,
      reserved          |-> [i \in 1 .. 1 |-> 0],
      time              |-> [i \in 1 .. 6 |-> 0] ]

(* End Of Sales Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfSalesMessage ==
    { ZeroEndOfSalesMessage }
        \cup { [ZeroEndOfSalesMessage EXCEPT !.longMessageHeader = one] : one \in CheckedLongMessageHeader42 }
        \cup { [ZeroEndOfSalesMessage EXCEPT !.reserved = one] : one \in Sample(1) }
        \cup { [ZeroEndOfSalesMessage EXCEPT !.time = one] : one \in Sample(6) }

(***************************************************************************)
(* Long Message Header: 12 bytes                                           *)
(***************************************************************************)

LongMessageHeader43 ==
    [ messageTimestamp : Sample(12) ]

EncodeLongMessageHeader43(message) ==
    message.messageTimestamp

DecodeLongMessageHeader43(bytes) ==
    LET messageTimestamp == ReadBytes(bytes, 12) IN IF ~messageTimestamp.ok THEN Fail ELSE
    Ok([ messageTimestamp |-> messageTimestamp.value ], messageTimestamp.rest)

ZeroLongMessageHeader43 ==
    [ messageTimestamp |-> [i \in 1 .. 12 |-> 0] ]

(* Long Message Header at zero, then each field in turn at the values it is checked at *)
CheckedLongMessageHeader43 ==
    { ZeroLongMessageHeader43 }
        \cup { [ZeroLongMessageHeader43 EXCEPT !.messageTimestamp = one] : one \in Sample(12) }

(***************************************************************************)
(* Tick Entry: 16 bytes                                                    *)
(***************************************************************************)

TickEntry ==
    [ minPrice                   : Sample(7),
      minPriceFractionIndicator  : Sample(1),
      tickPrice                  : Sample(7),
      tickPriceFractionIndicator : Sample(1) ]

EncodeTickEntry(message) ==
    message.minPrice
        \o message.minPriceFractionIndicator
        \o message.tickPrice
        \o message.tickPriceFractionIndicator

DecodeTickEntry(bytes) ==
    LET minPrice == ReadBytes(bytes, 7) IN IF ~minPrice.ok THEN Fail ELSE
    LET minPriceFractionIndicator == ReadBytes(minPrice.rest, 1) IN IF ~minPriceFractionIndicator.ok THEN Fail ELSE
    LET tickPrice == ReadBytes(minPriceFractionIndicator.rest, 7) IN IF ~tickPrice.ok THEN Fail ELSE
    LET tickPriceFractionIndicator == ReadBytes(tickPrice.rest, 1) IN IF ~tickPriceFractionIndicator.ok THEN Fail ELSE
    Ok([ minPrice                   |-> minPrice.value,
         minPriceFractionIndicator  |-> minPriceFractionIndicator.value,
         tickPrice                  |-> tickPrice.value,
         tickPriceFractionIndicator |-> tickPriceFractionIndicator.value ], tickPriceFractionIndicator.rest)

ZeroTickEntry ==
    [ minPrice                   |-> [i \in 1 .. 7 |-> 0],
      minPriceFractionIndicator  |-> [i \in 1 .. 1 |-> 0],
      tickPrice                  |-> [i \in 1 .. 7 |-> 0],
      tickPriceFractionIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Tick Entry at zero, then each field in turn at the values it is checked at *)
CheckedTickEntry ==
    { ZeroTickEntry }
        \cup { [ZeroTickEntry EXCEPT !.minPrice = one] : one \in Sample(7) }
        \cup { [ZeroTickEntry EXCEPT !.minPriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTickEntry EXCEPT !.tickPrice = one] : one \in Sample(7) }
        \cup { [ZeroTickEntry EXCEPT !.tickPriceFractionIndicator = one] : one \in Sample(1) }

(* A run of Tick Entry, written one after another *)
RECURSIVE EncodeTickEntryList(_)
EncodeTickEntryList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTickEntry(Head(messages)) \o EncodeTickEntryList(Tail(messages))

(* As many Tick Entry as the field that counts them says *)
RECURSIVE ReadTickEntryList(_, _)
ReadTickEntryList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeTickEntry(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTickEntryList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Tick Entry of each kind, for the lists that carry them *)
OneTickEntry == { ZeroTickEntry }

(***************************************************************************)
(* Tick Table Message                                                      *)
(***************************************************************************)

TickTableMessage ==
    [ longMessageHeader  : LongMessageHeader43,
      exchangeId         : Sample(1),
      tickTableName      : Sample(50),
      tickTableShortName : Sample(2),
      tickEntry          : SampleLists(OneTickEntry) ]

EncodeTickTableMessage(message) ==
    EncodeLongMessageHeader43(message.longMessageHeader)
        \o message.exchangeId
        \o message.tickTableName
        \o message.tickTableShortName
        \o EncodeDigits(Len(message.tickEntry), 2)
        \o EncodeTickEntryList(message.tickEntry)

DecodeTickTableMessage(bytes) ==
    LET longMessageHeader == DecodeLongMessageHeader43(bytes) IN IF ~longMessageHeader.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(longMessageHeader.rest, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET tickTableName == ReadBytes(exchangeId.rest, 50) IN IF ~tickTableName.ok THEN Fail ELSE
    LET tickTableShortName == ReadBytes(tickTableName.rest, 2) IN IF ~tickTableShortName.ok THEN Fail ELSE
    LET nbEntries == ReadDigits(tickTableShortName.rest, 2) IN IF ~nbEntries.ok THEN Fail ELSE
    LET tickEntry == ReadTickEntryList(nbEntries.rest, nbEntries.value) IN IF ~tickEntry.ok THEN Fail ELSE
    Ok([ longMessageHeader  |-> longMessageHeader.value,
         exchangeId         |-> exchangeId.value,
         tickTableName      |-> tickTableName.value,
         tickTableShortName |-> tickTableShortName.value,
         tickEntry          |-> tickEntry.value ], tickEntry.rest)

ZeroTickTableMessage ==
    [ longMessageHeader  |-> ZeroLongMessageHeader43,
      exchangeId         |-> [i \in 1 .. 1 |-> 0],
      tickTableName      |-> [i \in 1 .. 50 |-> 0],
      tickTableShortName |-> [i \in 1 .. 2 |-> 0],
      tickEntry          |-> << >> ]

(* Tick Table Message at zero, then each field in turn at the values it is checked at *)
CheckedTickTableMessage ==
    { ZeroTickTableMessage }
        \cup { [ZeroTickTableMessage EXCEPT !.longMessageHeader = one] : one \in CheckedLongMessageHeader43 }
        \cup { [ZeroTickTableMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroTickTableMessage EXCEPT !.tickTableName = one] : one \in Sample(50) }
        \cup { [ZeroTickTableMessage EXCEPT !.tickTableShortName = one] : one \in Sample(2) }
        \cup { [ZeroTickTableMessage EXCEPT !.tickEntry = one] : one \in SampleLists(OneTickEntry) }

(***************************************************************************)
(* Long Message Header: 12 bytes                                           *)
(***************************************************************************)

LongMessageHeader44 ==
    [ messageTimestamp : Sample(12) ]

EncodeLongMessageHeader44(message) ==
    message.messageTimestamp

DecodeLongMessageHeader44(bytes) ==
    LET messageTimestamp == ReadBytes(bytes, 12) IN IF ~messageTimestamp.ok THEN Fail ELSE
    Ok([ messageTimestamp |-> messageTimestamp.value ], messageTimestamp.rest)

ZeroLongMessageHeader44 ==
    [ messageTimestamp |-> [i \in 1 .. 12 |-> 0] ]

(* Long Message Header at zero, then each field in turn at the values it is checked at *)
CheckedLongMessageHeader44 ==
    { ZeroLongMessageHeader44 }
        \cup { [ZeroLongMessageHeader44 EXCEPT !.messageTimestamp = one] : one \in Sample(12) }

(***************************************************************************)
(* End Of Transmission Message: 19 bytes                                   *)
(***************************************************************************)

EndOfTransmissionMessage ==
    [ longMessageHeader : LongMessageHeader44,
      exchangeId        : Sample(1),
      time              : Sample(6) ]

EncodeEndOfTransmissionMessage(message) ==
    EncodeLongMessageHeader44(message.longMessageHeader)
        \o message.exchangeId
        \o message.time

DecodeEndOfTransmissionMessage(bytes) ==
    LET longMessageHeader == DecodeLongMessageHeader44(bytes) IN IF ~longMessageHeader.ok THEN Fail ELSE
    LET exchangeId == ReadBytes(longMessageHeader.rest, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET time == ReadBytes(exchangeId.rest, 6) IN IF ~time.ok THEN Fail ELSE
    Ok([ longMessageHeader |-> longMessageHeader.value,
         exchangeId        |-> exchangeId.value,
         time              |-> time.value ], time.rest)

ZeroEndOfTransmissionMessage ==
    [ longMessageHeader |-> ZeroLongMessageHeader44,
      exchangeId        |-> [i \in 1 .. 1 |-> 0],
      time              |-> [i \in 1 .. 6 |-> 0] ]

(* End Of Transmission Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfTransmissionMessage ==
    { ZeroEndOfTransmissionMessage }
        \cup { [ZeroEndOfTransmissionMessage EXCEPT !.longMessageHeader = one] : one \in CheckedLongMessageHeader44 }
        \cup { [ZeroEndOfTransmissionMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroEndOfTransmissionMessage EXCEPT !.time = one] : one \in Sample(6) }

(***************************************************************************)
(* Long Message Header: 12 bytes                                           *)
(***************************************************************************)

LongMessageHeader45 ==
    [ messageTimestamp : Sample(12) ]

EncodeLongMessageHeader45(message) ==
    message.messageTimestamp

DecodeLongMessageHeader45(bytes) ==
    LET messageTimestamp == ReadBytes(bytes, 12) IN IF ~messageTimestamp.ok THEN Fail ELSE
    Ok([ messageTimestamp |-> messageTimestamp.value ], messageTimestamp.rest)

ZeroLongMessageHeader45 ==
    [ messageTimestamp |-> [i \in 1 .. 12 |-> 0] ]

(* Long Message Header at zero, then each field in turn at the values it is checked at *)
CheckedLongMessageHeader45 ==
    { ZeroLongMessageHeader45 }
        \cup { [ZeroLongMessageHeader45 EXCEPT !.messageTimestamp = one] : one \in Sample(12) }

(***************************************************************************)
(* Circuit Assurance Message: 18 bytes                                     *)
(***************************************************************************)

CircuitAssuranceMessage ==
    [ longMessageHeader : LongMessageHeader45,
      time              : Sample(6) ]

EncodeCircuitAssuranceMessage(message) ==
    EncodeLongMessageHeader45(message.longMessageHeader)
        \o message.time

DecodeCircuitAssuranceMessage(bytes) ==
    LET longMessageHeader == DecodeLongMessageHeader45(bytes) IN IF ~longMessageHeader.ok THEN Fail ELSE
    LET time == ReadBytes(longMessageHeader.rest, 6) IN IF ~time.ok THEN Fail ELSE
    Ok([ longMessageHeader |-> longMessageHeader.value,
         time              |-> time.value ], time.rest)

ZeroCircuitAssuranceMessage ==
    [ longMessageHeader |-> ZeroLongMessageHeader45,
      time              |-> [i \in 1 .. 6 |-> 0] ]

(* Circuit Assurance Message at zero, then each field in turn at the values it is checked at *)
CheckedCircuitAssuranceMessage ==
    { ZeroCircuitAssuranceMessage }
        \cup { [ZeroCircuitAssuranceMessage EXCEPT !.longMessageHeader = one] : one \in CheckedLongMessageHeader45 }
        \cup { [ZeroCircuitAssuranceMessage EXCEPT !.time = one] : one \in Sample(6) }

(***************************************************************************)
(* Message Body, selected by Message Type                                  *)
(***************************************************************************)

LoginMessageCode == 19529  \* "LI"
LogoutMessageCode == 19535  \* "LO"
LoginAcknowledgementMessageCode == 19273  \* "KI"
LogoutAcknowledgementMessageCode == 19279  \* "KO"
RetransmissionRequestMessageCode == 21076  \* "RT"
RetransmissionBeginMessageCode == 21058  \* "RB"
RetransmissionEndMessageCode == 21061  \* "RE"
ErrorMessageMessageCode == 17746  \* "ER"
OptionTradeMessageCode == 17184  \* "C "
FutureOptionsTradeMessageCode == 17218  \* "CB"
FuturesTradeMessageCode == 17222  \* "CF"
StrategyTradeMessageCode == 17235  \* "CS"
OptionRequestForQuoteRfqMessageCode == 17440  \* "D "
FutureOptionsRequestForQuoteRfqMessageCode == 17474  \* "DB"
FuturesRequestForQuoteRfqMessageCode == 17478  \* "DF"
StrategyRequestForQuoteRfqMessageCode == 17491  \* "DS"
InstrumentScheduleNoticeOptionMessageCode == 17696  \* "E "
InstrumentScheduleNoticeFuturesOptionMessageCode == 17730  \* "EB"
InstrumentScheduleNoticeFutureMessageCode == 17734  \* "EF"
InstrumentScheduleNoticeStrategyMessageCode == 17747  \* "ES"
OptionQuoteMessageCode == 17952  \* "F "
FutureOptionsQuoteMessageCode == 17986  \* "FB"
FuturesQuoteMessageCode == 17990  \* "FF"
StrategyQuoteMessageCode == 18003  \* "FS"
OptionMarketDepthMessageCode == 18464  \* "H "
FutureOptionsMarketDepthMessageCode == 18498  \* "HB"
FuturesMarketDepthMessageCode == 18502  \* "HF"
StrategyMarketDepthMessageCode == 18515  \* "HS"
OptionTradeCancellationMessageCode == 18720  \* "I "
FutureOptionsTradeCancellationMessageCode == 18754  \* "IB"
FuturesTradeCancellationMessageCode == 18758  \* "IF"
StrategyTradeCancellationMessageCode == 18771  \* "IS"
OptionInstrumentKeysMessageCode == 18976  \* "J "
FutureOptionsInstrumentKeysMessageCode == 19010  \* "JB"
UnderlyingInstrumentKeysMessageCode == 19013  \* "JE"
FuturesInstrumentKeysMessageCode == 19014  \* "JF"
StrategyInstrumentKeysMessageCode == 19027  \* "JS"
OptionSummaryMessageCode == 20000  \* "N "
FutureOptionsSummaryMessageCode == 20034  \* "NB"
FuturesSummaryMessageCode == 20038  \* "NF"
StrategySummaryMessageCode == 20051  \* "NS"
BeginningOfOptionsSummaryMessageCode == 20768  \* "Q "
BeginningOfFutureOptionsSummaryMessageCode == 20802  \* "QB"
BeginningOfFuturesSummaryMessageCode == 20806  \* "QF"
BeginningOfStrategySummaryMessageCode == 20819  \* "QS"
FuturesTradeCorrectionMessageCode == 22598  \* "XF"
GroupStatusMessageCode == 18258  \* "GR"
GroupStatusStrategiesMessageCode == 18259  \* "GS"
BulletinsMessageCode == 19488  \* "L "
EndOfSalesMessageCode == 21280  \* "S "
TickTableMessageCode == 21588  \* "TT"
EndOfTransmissionMessageCode == 21792  \* "U "
CircuitAssuranceMessageCode == 22048  \* "V "

MessageBody ==
    [ tag : {LoginMessageCode}, body : LoginMessage ]
        \cup [ tag : {LogoutMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {LoginAcknowledgementMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {LogoutAcknowledgementMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {RetransmissionRequestMessageCode}, body : RetransmissionRequestMessage ]
        \cup [ tag : {RetransmissionBeginMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {RetransmissionEndMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ErrorMessageMessageCode}, body : ErrorMessageMessage ]
        \cup [ tag : {OptionTradeMessageCode}, body : OptionTradeMessage ]
        \cup [ tag : {FutureOptionsTradeMessageCode}, body : FutureOptionsTradeMessage ]
        \cup [ tag : {FuturesTradeMessageCode}, body : FuturesTradeMessage ]
        \cup [ tag : {StrategyTradeMessageCode}, body : StrategyTradeMessage ]
        \cup [ tag : {OptionRequestForQuoteRfqMessageCode}, body : OptionRequestForQuoteRfqMessage ]
        \cup [ tag : {FutureOptionsRequestForQuoteRfqMessageCode}, body : FutureOptionsRequestForQuoteRfqMessage ]
        \cup [ tag : {FuturesRequestForQuoteRfqMessageCode}, body : FuturesRequestForQuoteRfqMessage ]
        \cup [ tag : {StrategyRequestForQuoteRfqMessageCode}, body : StrategyRequestForQuoteRfqMessage ]
        \cup [ tag : {InstrumentScheduleNoticeOptionMessageCode}, body : InstrumentScheduleNoticeOptionMessage ]
        \cup [ tag : {InstrumentScheduleNoticeFuturesOptionMessageCode}, body : InstrumentScheduleNoticeFuturesOptionMessage ]
        \cup [ tag : {InstrumentScheduleNoticeFutureMessageCode}, body : InstrumentScheduleNoticeFutureMessage ]
        \cup [ tag : {InstrumentScheduleNoticeStrategyMessageCode}, body : InstrumentScheduleNoticeStrategyMessage ]
        \cup [ tag : {OptionQuoteMessageCode}, body : OptionQuoteMessage ]
        \cup [ tag : {FutureOptionsQuoteMessageCode}, body : FutureOptionsQuoteMessage ]
        \cup [ tag : {FuturesQuoteMessageCode}, body : FuturesQuoteMessage ]
        \cup [ tag : {StrategyQuoteMessageCode}, body : StrategyQuoteMessage ]
        \cup [ tag : {OptionMarketDepthMessageCode}, body : OptionMarketDepthMessage ]
        \cup [ tag : {FutureOptionsMarketDepthMessageCode}, body : FutureOptionsMarketDepthMessage ]
        \cup [ tag : {FuturesMarketDepthMessageCode}, body : FuturesMarketDepthMessage ]
        \cup [ tag : {StrategyMarketDepthMessageCode}, body : StrategyMarketDepthMessage ]
        \cup [ tag : {OptionTradeCancellationMessageCode}, body : OptionTradeCancellationMessage ]
        \cup [ tag : {FutureOptionsTradeCancellationMessageCode}, body : FutureOptionsTradeCancellationMessage ]
        \cup [ tag : {FuturesTradeCancellationMessageCode}, body : FuturesTradeCancellationMessage ]
        \cup [ tag : {StrategyTradeCancellationMessageCode}, body : StrategyTradeCancellationMessage ]
        \cup [ tag : {OptionInstrumentKeysMessageCode}, body : OptionInstrumentKeysMessage ]
        \cup [ tag : {FutureOptionsInstrumentKeysMessageCode}, body : FutureOptionsInstrumentKeysMessage ]
        \cup [ tag : {UnderlyingInstrumentKeysMessageCode}, body : UnderlyingInstrumentKeysMessage ]
        \cup [ tag : {FuturesInstrumentKeysMessageCode}, body : FuturesInstrumentKeysMessage ]
        \cup [ tag : {StrategyInstrumentKeysMessageCode}, body : StrategyInstrumentKeysMessage ]
        \cup [ tag : {OptionSummaryMessageCode}, body : OptionSummaryMessage ]
        \cup [ tag : {FutureOptionsSummaryMessageCode}, body : FutureOptionsSummaryMessage ]
        \cup [ tag : {FuturesSummaryMessageCode}, body : FuturesSummaryMessage ]
        \cup [ tag : {StrategySummaryMessageCode}, body : StrategySummaryMessage ]
        \cup [ tag : {BeginningOfOptionsSummaryMessageCode}, body : BeginningOfOptionsSummaryMessage ]
        \cup [ tag : {BeginningOfFutureOptionsSummaryMessageCode}, body : BeginningOfFutureOptionsSummaryMessage ]
        \cup [ tag : {BeginningOfFuturesSummaryMessageCode}, body : BeginningOfFuturesSummaryMessage ]
        \cup [ tag : {BeginningOfStrategySummaryMessageCode}, body : BeginningOfStrategySummaryMessage ]
        \cup [ tag : {FuturesTradeCorrectionMessageCode}, body : FuturesTradeCorrectionMessage ]
        \cup [ tag : {GroupStatusMessageCode}, body : GroupStatusMessage ]
        \cup [ tag : {GroupStatusStrategiesMessageCode}, body : GroupStatusStrategiesMessage ]
        \cup [ tag : {BulletinsMessageCode}, body : BulletinsMessage ]
        \cup [ tag : {EndOfSalesMessageCode}, body : EndOfSalesMessage ]
        \cup [ tag : {TickTableMessageCode}, body : TickTableMessage ]
        \cup [ tag : {EndOfTransmissionMessageCode}, body : EndOfTransmissionMessage ]
        \cup [ tag : {CircuitAssuranceMessageCode}, body : CircuitAssuranceMessage ]

EncodeMessageBody(message) ==
    CASE message.tag = LoginMessageCode -> EncodeLoginMessage(message.body)
      [] message.tag = LogoutMessageCode -> << >>
      [] message.tag = LoginAcknowledgementMessageCode -> << >>
      [] message.tag = LogoutAcknowledgementMessageCode -> << >>
      [] message.tag = RetransmissionRequestMessageCode -> EncodeRetransmissionRequestMessage(message.body)
      [] message.tag = RetransmissionBeginMessageCode -> << >>
      [] message.tag = RetransmissionEndMessageCode -> << >>
      [] message.tag = ErrorMessageMessageCode -> EncodeErrorMessageMessage(message.body)
      [] message.tag = OptionTradeMessageCode -> EncodeOptionTradeMessage(message.body)
      [] message.tag = FutureOptionsTradeMessageCode -> EncodeFutureOptionsTradeMessage(message.body)
      [] message.tag = FuturesTradeMessageCode -> EncodeFuturesTradeMessage(message.body)
      [] message.tag = StrategyTradeMessageCode -> EncodeStrategyTradeMessage(message.body)
      [] message.tag = OptionRequestForQuoteRfqMessageCode -> EncodeOptionRequestForQuoteRfqMessage(message.body)
      [] message.tag = FutureOptionsRequestForQuoteRfqMessageCode -> EncodeFutureOptionsRequestForQuoteRfqMessage(message.body)
      [] message.tag = FuturesRequestForQuoteRfqMessageCode -> EncodeFuturesRequestForQuoteRfqMessage(message.body)
      [] message.tag = StrategyRequestForQuoteRfqMessageCode -> EncodeStrategyRequestForQuoteRfqMessage(message.body)
      [] message.tag = InstrumentScheduleNoticeOptionMessageCode -> EncodeInstrumentScheduleNoticeOptionMessage(message.body)
      [] message.tag = InstrumentScheduleNoticeFuturesOptionMessageCode -> EncodeInstrumentScheduleNoticeFuturesOptionMessage(message.body)
      [] message.tag = InstrumentScheduleNoticeFutureMessageCode -> EncodeInstrumentScheduleNoticeFutureMessage(message.body)
      [] message.tag = InstrumentScheduleNoticeStrategyMessageCode -> EncodeInstrumentScheduleNoticeStrategyMessage(message.body)
      [] message.tag = OptionQuoteMessageCode -> EncodeOptionQuoteMessage(message.body)
      [] message.tag = FutureOptionsQuoteMessageCode -> EncodeFutureOptionsQuoteMessage(message.body)
      [] message.tag = FuturesQuoteMessageCode -> EncodeFuturesQuoteMessage(message.body)
      [] message.tag = StrategyQuoteMessageCode -> EncodeStrategyQuoteMessage(message.body)
      [] message.tag = OptionMarketDepthMessageCode -> EncodeOptionMarketDepthMessage(message.body)
      [] message.tag = FutureOptionsMarketDepthMessageCode -> EncodeFutureOptionsMarketDepthMessage(message.body)
      [] message.tag = FuturesMarketDepthMessageCode -> EncodeFuturesMarketDepthMessage(message.body)
      [] message.tag = StrategyMarketDepthMessageCode -> EncodeStrategyMarketDepthMessage(message.body)
      [] message.tag = OptionTradeCancellationMessageCode -> EncodeOptionTradeCancellationMessage(message.body)
      [] message.tag = FutureOptionsTradeCancellationMessageCode -> EncodeFutureOptionsTradeCancellationMessage(message.body)
      [] message.tag = FuturesTradeCancellationMessageCode -> EncodeFuturesTradeCancellationMessage(message.body)
      [] message.tag = StrategyTradeCancellationMessageCode -> EncodeStrategyTradeCancellationMessage(message.body)
      [] message.tag = OptionInstrumentKeysMessageCode -> EncodeOptionInstrumentKeysMessage(message.body)
      [] message.tag = FutureOptionsInstrumentKeysMessageCode -> EncodeFutureOptionsInstrumentKeysMessage(message.body)
      [] message.tag = UnderlyingInstrumentKeysMessageCode -> EncodeUnderlyingInstrumentKeysMessage(message.body)
      [] message.tag = FuturesInstrumentKeysMessageCode -> EncodeFuturesInstrumentKeysMessage(message.body)
      [] message.tag = StrategyInstrumentKeysMessageCode -> EncodeStrategyInstrumentKeysMessage(message.body)
      [] message.tag = OptionSummaryMessageCode -> EncodeOptionSummaryMessage(message.body)
      [] message.tag = FutureOptionsSummaryMessageCode -> EncodeFutureOptionsSummaryMessage(message.body)
      [] message.tag = FuturesSummaryMessageCode -> EncodeFuturesSummaryMessage(message.body)
      [] message.tag = StrategySummaryMessageCode -> EncodeStrategySummaryMessage(message.body)
      [] message.tag = BeginningOfOptionsSummaryMessageCode -> EncodeBeginningOfOptionsSummaryMessage(message.body)
      [] message.tag = BeginningOfFutureOptionsSummaryMessageCode -> EncodeBeginningOfFutureOptionsSummaryMessage(message.body)
      [] message.tag = BeginningOfFuturesSummaryMessageCode -> EncodeBeginningOfFuturesSummaryMessage(message.body)
      [] message.tag = BeginningOfStrategySummaryMessageCode -> EncodeBeginningOfStrategySummaryMessage(message.body)
      [] message.tag = FuturesTradeCorrectionMessageCode -> EncodeFuturesTradeCorrectionMessage(message.body)
      [] message.tag = GroupStatusMessageCode -> EncodeGroupStatusMessage(message.body)
      [] message.tag = GroupStatusStrategiesMessageCode -> EncodeGroupStatusStrategiesMessage(message.body)
      [] message.tag = BulletinsMessageCode -> EncodeBulletinsMessage(message.body)
      [] message.tag = EndOfSalesMessageCode -> EncodeEndOfSalesMessage(message.body)
      [] message.tag = TickTableMessageCode -> EncodeTickTableMessage(message.body)
      [] message.tag = EndOfTransmissionMessageCode -> EncodeEndOfTransmissionMessage(message.body)
      [] message.tag = CircuitAssuranceMessageCode -> EncodeCircuitAssuranceMessage(message.body)

DecodeMessageBody(tag, bytes) ==
    LET read ==
            CASE tag = LoginMessageCode -> DecodeLoginMessage(bytes)
              [] tag = LogoutMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = LoginAcknowledgementMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = LogoutAcknowledgementMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = RetransmissionRequestMessageCode -> DecodeRetransmissionRequestMessage(bytes)
              [] tag = RetransmissionBeginMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = RetransmissionEndMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = ErrorMessageMessageCode -> DecodeErrorMessageMessage(bytes)
              [] tag = OptionTradeMessageCode -> DecodeOptionTradeMessage(bytes)
              [] tag = FutureOptionsTradeMessageCode -> DecodeFutureOptionsTradeMessage(bytes)
              [] tag = FuturesTradeMessageCode -> DecodeFuturesTradeMessage(bytes)
              [] tag = StrategyTradeMessageCode -> DecodeStrategyTradeMessage(bytes)
              [] tag = OptionRequestForQuoteRfqMessageCode -> DecodeOptionRequestForQuoteRfqMessage(bytes)
              [] tag = FutureOptionsRequestForQuoteRfqMessageCode -> DecodeFutureOptionsRequestForQuoteRfqMessage(bytes)
              [] tag = FuturesRequestForQuoteRfqMessageCode -> DecodeFuturesRequestForQuoteRfqMessage(bytes)
              [] tag = StrategyRequestForQuoteRfqMessageCode -> DecodeStrategyRequestForQuoteRfqMessage(bytes)
              [] tag = InstrumentScheduleNoticeOptionMessageCode -> DecodeInstrumentScheduleNoticeOptionMessage(bytes)
              [] tag = InstrumentScheduleNoticeFuturesOptionMessageCode -> DecodeInstrumentScheduleNoticeFuturesOptionMessage(bytes)
              [] tag = InstrumentScheduleNoticeFutureMessageCode -> DecodeInstrumentScheduleNoticeFutureMessage(bytes)
              [] tag = InstrumentScheduleNoticeStrategyMessageCode -> DecodeInstrumentScheduleNoticeStrategyMessage(bytes)
              [] tag = OptionQuoteMessageCode -> DecodeOptionQuoteMessage(bytes)
              [] tag = FutureOptionsQuoteMessageCode -> DecodeFutureOptionsQuoteMessage(bytes)
              [] tag = FuturesQuoteMessageCode -> DecodeFuturesQuoteMessage(bytes)
              [] tag = StrategyQuoteMessageCode -> DecodeStrategyQuoteMessage(bytes)
              [] tag = OptionMarketDepthMessageCode -> DecodeOptionMarketDepthMessage(bytes)
              [] tag = FutureOptionsMarketDepthMessageCode -> DecodeFutureOptionsMarketDepthMessage(bytes)
              [] tag = FuturesMarketDepthMessageCode -> DecodeFuturesMarketDepthMessage(bytes)
              [] tag = StrategyMarketDepthMessageCode -> DecodeStrategyMarketDepthMessage(bytes)
              [] tag = OptionTradeCancellationMessageCode -> DecodeOptionTradeCancellationMessage(bytes)
              [] tag = FutureOptionsTradeCancellationMessageCode -> DecodeFutureOptionsTradeCancellationMessage(bytes)
              [] tag = FuturesTradeCancellationMessageCode -> DecodeFuturesTradeCancellationMessage(bytes)
              [] tag = StrategyTradeCancellationMessageCode -> DecodeStrategyTradeCancellationMessage(bytes)
              [] tag = OptionInstrumentKeysMessageCode -> DecodeOptionInstrumentKeysMessage(bytes)
              [] tag = FutureOptionsInstrumentKeysMessageCode -> DecodeFutureOptionsInstrumentKeysMessage(bytes)
              [] tag = UnderlyingInstrumentKeysMessageCode -> DecodeUnderlyingInstrumentKeysMessage(bytes)
              [] tag = FuturesInstrumentKeysMessageCode -> DecodeFuturesInstrumentKeysMessage(bytes)
              [] tag = StrategyInstrumentKeysMessageCode -> DecodeStrategyInstrumentKeysMessage(bytes)
              [] tag = OptionSummaryMessageCode -> DecodeOptionSummaryMessage(bytes)
              [] tag = FutureOptionsSummaryMessageCode -> DecodeFutureOptionsSummaryMessage(bytes)
              [] tag = FuturesSummaryMessageCode -> DecodeFuturesSummaryMessage(bytes)
              [] tag = StrategySummaryMessageCode -> DecodeStrategySummaryMessage(bytes)
              [] tag = BeginningOfOptionsSummaryMessageCode -> DecodeBeginningOfOptionsSummaryMessage(bytes)
              [] tag = BeginningOfFutureOptionsSummaryMessageCode -> DecodeBeginningOfFutureOptionsSummaryMessage(bytes)
              [] tag = BeginningOfFuturesSummaryMessageCode -> DecodeBeginningOfFuturesSummaryMessage(bytes)
              [] tag = BeginningOfStrategySummaryMessageCode -> DecodeBeginningOfStrategySummaryMessage(bytes)
              [] tag = FuturesTradeCorrectionMessageCode -> DecodeFuturesTradeCorrectionMessage(bytes)
              [] tag = GroupStatusMessageCode -> DecodeGroupStatusMessage(bytes)
              [] tag = GroupStatusStrategiesMessageCode -> DecodeGroupStatusStrategiesMessage(bytes)
              [] tag = BulletinsMessageCode -> DecodeBulletinsMessage(bytes)
              [] tag = EndOfSalesMessageCode -> DecodeEndOfSalesMessage(bytes)
              [] tag = TickTableMessageCode -> DecodeTickTableMessage(bytes)
              [] tag = EndOfTransmissionMessageCode -> DecodeEndOfTransmissionMessage(bytes)
              [] tag = CircuitAssuranceMessageCode -> DecodeCircuitAssuranceMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroMessageBody == [tag |-> LoginMessageCode, body |-> ZeroLoginMessage]

(* Each Message Body in turn, at the values the message it names is checked at *)
CheckedMessageBody ==
    { [tag |-> LoginMessageCode, body |-> one] : one \in CheckedLoginMessage }
        \cup { [tag |-> LogoutMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> LoginAcknowledgementMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> LogoutAcknowledgementMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> RetransmissionRequestMessageCode, body |-> one] : one \in CheckedRetransmissionRequestMessage }
        \cup { [tag |-> RetransmissionBeginMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> RetransmissionEndMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> ErrorMessageMessageCode, body |-> one] : one \in CheckedErrorMessageMessage }
        \cup { [tag |-> OptionTradeMessageCode, body |-> one] : one \in CheckedOptionTradeMessage }
        \cup { [tag |-> FutureOptionsTradeMessageCode, body |-> one] : one \in CheckedFutureOptionsTradeMessage }
        \cup { [tag |-> FuturesTradeMessageCode, body |-> one] : one \in CheckedFuturesTradeMessage }
        \cup { [tag |-> StrategyTradeMessageCode, body |-> one] : one \in CheckedStrategyTradeMessage }
        \cup { [tag |-> OptionRequestForQuoteRfqMessageCode, body |-> one] : one \in CheckedOptionRequestForQuoteRfqMessage }
        \cup { [tag |-> FutureOptionsRequestForQuoteRfqMessageCode, body |-> one] : one \in CheckedFutureOptionsRequestForQuoteRfqMessage }
        \cup { [tag |-> FuturesRequestForQuoteRfqMessageCode, body |-> one] : one \in CheckedFuturesRequestForQuoteRfqMessage }
        \cup { [tag |-> StrategyRequestForQuoteRfqMessageCode, body |-> one] : one \in CheckedStrategyRequestForQuoteRfqMessage }
        \cup { [tag |-> InstrumentScheduleNoticeOptionMessageCode, body |-> one] : one \in CheckedInstrumentScheduleNoticeOptionMessage }
        \cup { [tag |-> InstrumentScheduleNoticeFuturesOptionMessageCode, body |-> one] : one \in CheckedInstrumentScheduleNoticeFuturesOptionMessage }
        \cup { [tag |-> InstrumentScheduleNoticeFutureMessageCode, body |-> one] : one \in CheckedInstrumentScheduleNoticeFutureMessage }
        \cup { [tag |-> InstrumentScheduleNoticeStrategyMessageCode, body |-> one] : one \in CheckedInstrumentScheduleNoticeStrategyMessage }
        \cup { [tag |-> OptionQuoteMessageCode, body |-> one] : one \in CheckedOptionQuoteMessage }
        \cup { [tag |-> FutureOptionsQuoteMessageCode, body |-> one] : one \in CheckedFutureOptionsQuoteMessage }
        \cup { [tag |-> FuturesQuoteMessageCode, body |-> one] : one \in CheckedFuturesQuoteMessage }
        \cup { [tag |-> StrategyQuoteMessageCode, body |-> one] : one \in CheckedStrategyQuoteMessage }
        \cup { [tag |-> OptionMarketDepthMessageCode, body |-> one] : one \in CheckedOptionMarketDepthMessage }
        \cup { [tag |-> FutureOptionsMarketDepthMessageCode, body |-> one] : one \in CheckedFutureOptionsMarketDepthMessage }
        \cup { [tag |-> FuturesMarketDepthMessageCode, body |-> one] : one \in CheckedFuturesMarketDepthMessage }
        \cup { [tag |-> StrategyMarketDepthMessageCode, body |-> one] : one \in CheckedStrategyMarketDepthMessage }
        \cup { [tag |-> OptionTradeCancellationMessageCode, body |-> one] : one \in CheckedOptionTradeCancellationMessage }
        \cup { [tag |-> FutureOptionsTradeCancellationMessageCode, body |-> one] : one \in CheckedFutureOptionsTradeCancellationMessage }
        \cup { [tag |-> FuturesTradeCancellationMessageCode, body |-> one] : one \in CheckedFuturesTradeCancellationMessage }
        \cup { [tag |-> StrategyTradeCancellationMessageCode, body |-> one] : one \in CheckedStrategyTradeCancellationMessage }
        \cup { [tag |-> OptionInstrumentKeysMessageCode, body |-> one] : one \in CheckedOptionInstrumentKeysMessage }
        \cup { [tag |-> FutureOptionsInstrumentKeysMessageCode, body |-> one] : one \in CheckedFutureOptionsInstrumentKeysMessage }
        \cup { [tag |-> UnderlyingInstrumentKeysMessageCode, body |-> one] : one \in CheckedUnderlyingInstrumentKeysMessage }
        \cup { [tag |-> FuturesInstrumentKeysMessageCode, body |-> one] : one \in CheckedFuturesInstrumentKeysMessage }
        \cup { [tag |-> StrategyInstrumentKeysMessageCode, body |-> one] : one \in CheckedStrategyInstrumentKeysMessage }
        \cup { [tag |-> OptionSummaryMessageCode, body |-> one] : one \in CheckedOptionSummaryMessage }
        \cup { [tag |-> FutureOptionsSummaryMessageCode, body |-> one] : one \in CheckedFutureOptionsSummaryMessage }
        \cup { [tag |-> FuturesSummaryMessageCode, body |-> one] : one \in CheckedFuturesSummaryMessage }
        \cup { [tag |-> StrategySummaryMessageCode, body |-> one] : one \in CheckedStrategySummaryMessage }
        \cup { [tag |-> BeginningOfOptionsSummaryMessageCode, body |-> one] : one \in CheckedBeginningOfOptionsSummaryMessage }
        \cup { [tag |-> BeginningOfFutureOptionsSummaryMessageCode, body |-> one] : one \in CheckedBeginningOfFutureOptionsSummaryMessage }
        \cup { [tag |-> BeginningOfFuturesSummaryMessageCode, body |-> one] : one \in CheckedBeginningOfFuturesSummaryMessage }
        \cup { [tag |-> BeginningOfStrategySummaryMessageCode, body |-> one] : one \in CheckedBeginningOfStrategySummaryMessage }
        \cup { [tag |-> FuturesTradeCorrectionMessageCode, body |-> one] : one \in CheckedFuturesTradeCorrectionMessage }
        \cup { [tag |-> GroupStatusMessageCode, body |-> one] : one \in CheckedGroupStatusMessage }
        \cup { [tag |-> GroupStatusStrategiesMessageCode, body |-> one] : one \in CheckedGroupStatusStrategiesMessage }
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
    { [ZeroPacket EXCEPT !.messageBody = [tag |-> LoginMessageCode, body |-> ZeroLoginMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> LogoutMessageCode, body |-> [empty |-> 0]]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> LoginAcknowledgementMessageCode, body |-> [empty |-> 0]]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> LogoutAcknowledgementMessageCode, body |-> [empty |-> 0]]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> RetransmissionRequestMessageCode, body |-> ZeroRetransmissionRequestMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> RetransmissionBeginMessageCode, body |-> [empty |-> 0]]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> RetransmissionEndMessageCode, body |-> [empty |-> 0]]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> ErrorMessageMessageCode, body |-> ZeroErrorMessageMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> OptionTradeMessageCode, body |-> ZeroOptionTradeMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> FutureOptionsTradeMessageCode, body |-> ZeroFutureOptionsTradeMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> FuturesTradeMessageCode, body |-> ZeroFuturesTradeMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> StrategyTradeMessageCode, body |-> ZeroStrategyTradeMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> OptionRequestForQuoteRfqMessageCode, body |-> ZeroOptionRequestForQuoteRfqMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> FutureOptionsRequestForQuoteRfqMessageCode, body |-> ZeroFutureOptionsRequestForQuoteRfqMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> FuturesRequestForQuoteRfqMessageCode, body |-> ZeroFuturesRequestForQuoteRfqMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> StrategyRequestForQuoteRfqMessageCode, body |-> ZeroStrategyRequestForQuoteRfqMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> InstrumentScheduleNoticeOptionMessageCode, body |-> ZeroInstrumentScheduleNoticeOptionMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> InstrumentScheduleNoticeFuturesOptionMessageCode, body |-> ZeroInstrumentScheduleNoticeFuturesOptionMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> InstrumentScheduleNoticeFutureMessageCode, body |-> ZeroInstrumentScheduleNoticeFutureMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> InstrumentScheduleNoticeStrategyMessageCode, body |-> ZeroInstrumentScheduleNoticeStrategyMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> OptionQuoteMessageCode, body |-> ZeroOptionQuoteMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> FutureOptionsQuoteMessageCode, body |-> ZeroFutureOptionsQuoteMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> FuturesQuoteMessageCode, body |-> ZeroFuturesQuoteMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> StrategyQuoteMessageCode, body |-> ZeroStrategyQuoteMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> OptionMarketDepthMessageCode, body |-> ZeroOptionMarketDepthMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> FutureOptionsMarketDepthMessageCode, body |-> ZeroFutureOptionsMarketDepthMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> FuturesMarketDepthMessageCode, body |-> ZeroFuturesMarketDepthMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> StrategyMarketDepthMessageCode, body |-> ZeroStrategyMarketDepthMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> OptionTradeCancellationMessageCode, body |-> ZeroOptionTradeCancellationMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> FutureOptionsTradeCancellationMessageCode, body |-> ZeroFutureOptionsTradeCancellationMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> FuturesTradeCancellationMessageCode, body |-> ZeroFuturesTradeCancellationMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> StrategyTradeCancellationMessageCode, body |-> ZeroStrategyTradeCancellationMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> OptionInstrumentKeysMessageCode, body |-> ZeroOptionInstrumentKeysMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> FutureOptionsInstrumentKeysMessageCode, body |-> ZeroFutureOptionsInstrumentKeysMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> UnderlyingInstrumentKeysMessageCode, body |-> ZeroUnderlyingInstrumentKeysMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> FuturesInstrumentKeysMessageCode, body |-> ZeroFuturesInstrumentKeysMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> StrategyInstrumentKeysMessageCode, body |-> ZeroStrategyInstrumentKeysMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> OptionSummaryMessageCode, body |-> ZeroOptionSummaryMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> FutureOptionsSummaryMessageCode, body |-> ZeroFutureOptionsSummaryMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> FuturesSummaryMessageCode, body |-> ZeroFuturesSummaryMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> StrategySummaryMessageCode, body |-> ZeroStrategySummaryMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> BeginningOfOptionsSummaryMessageCode, body |-> ZeroBeginningOfOptionsSummaryMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> BeginningOfFutureOptionsSummaryMessageCode, body |-> ZeroBeginningOfFutureOptionsSummaryMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> BeginningOfFuturesSummaryMessageCode, body |-> ZeroBeginningOfFuturesSummaryMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> BeginningOfStrategySummaryMessageCode, body |-> ZeroBeginningOfStrategySummaryMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> FuturesTradeCorrectionMessageCode, body |-> ZeroFuturesTradeCorrectionMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> GroupStatusMessageCode, body |-> ZeroGroupStatusMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> GroupStatusStrategiesMessageCode, body |-> ZeroGroupStatusStrategiesMessage]],
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

(* Every Login Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginMessage ==
    \A message \in CheckedLoginMessage :
        LET read == DecodeLoginMessage(EncodeLoginMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Retransmission Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRetransmissionRequestMessage ==
    \A message \in CheckedRetransmissionRequestMessage :
        LET read == DecodeRetransmissionRequestMessage(EncodeRetransmissionRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Error Message Message decodes back to what was encoded, and leaves nothing over *)
RoundTripErrorMessageMessage ==
    \A message \in CheckedErrorMessageMessage :
        LET read == DecodeErrorMessageMessage(EncodeErrorMessageMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripLongMessageHeader ==
    \A message \in CheckedLongMessageHeader :
        LET read == DecodeLongMessageHeader(EncodeLongMessageHeader(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Symbol decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionSymbol ==
    \A message \in CheckedOptionSymbol :
        LET read == DecodeOptionSymbol(EncodeOptionSymbol(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionTradeMessage ==
    \A message \in CheckedOptionTradeMessage :
        LET read == DecodeOptionTradeMessage(EncodeOptionTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripLongMessageHeader2 ==
    \A message \in CheckedLongMessageHeader2 :
        LET read == DecodeLongMessageHeader2(EncodeLongMessageHeader2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Option Symbol decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureOptionSymbol ==
    \A message \in CheckedFutureOptionSymbol :
        LET read == DecodeFutureOptionSymbol(EncodeFutureOptionSymbol(message))
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

(* Every Long Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripLongMessageHeader3 ==
    \A message \in CheckedLongMessageHeader3 :
        LET read == DecodeLongMessageHeader3(EncodeLongMessageHeader3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Product decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureProduct ==
    \A message \in CheckedFutureProduct :
        LET read == DecodeFutureProduct(EncodeFutureProduct(message))
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

(* Every Long Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripLongMessageHeader4 ==
    \A message \in CheckedLongMessageHeader4 :
        LET read == DecodeLongMessageHeader4(EncodeLongMessageHeader4(message))
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

(* Every Long Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripLongMessageHeader5 ==
    \A message \in CheckedLongMessageHeader5 :
        LET read == DecodeLongMessageHeader5(EncodeLongMessageHeader5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Symbol decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionSymbol2 ==
    \A message \in CheckedOptionSymbol2 :
        LET read == DecodeOptionSymbol2(EncodeOptionSymbol2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Request For Quote Rfq Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionRequestForQuoteRfqMessage ==
    \A message \in CheckedOptionRequestForQuoteRfqMessage :
        LET read == DecodeOptionRequestForQuoteRfqMessage(EncodeOptionRequestForQuoteRfqMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripLongMessageHeader6 ==
    \A message \in CheckedLongMessageHeader6 :
        LET read == DecodeLongMessageHeader6(EncodeLongMessageHeader6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Option Symbol decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureOptionSymbol2 ==
    \A message \in CheckedFutureOptionSymbol2 :
        LET read == DecodeFutureOptionSymbol2(EncodeFutureOptionSymbol2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Options Request For Quote Rfq Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureOptionsRequestForQuoteRfqMessage ==
    \A message \in CheckedFutureOptionsRequestForQuoteRfqMessage :
        LET read == DecodeFutureOptionsRequestForQuoteRfqMessage(EncodeFutureOptionsRequestForQuoteRfqMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripLongMessageHeader7 ==
    \A message \in CheckedLongMessageHeader7 :
        LET read == DecodeLongMessageHeader7(EncodeLongMessageHeader7(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Product decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureProduct2 ==
    \A message \in CheckedFutureProduct2 :
        LET read == DecodeFutureProduct2(EncodeFutureProduct2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Futures Request For Quote Rfq Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFuturesRequestForQuoteRfqMessage ==
    \A message \in CheckedFuturesRequestForQuoteRfqMessage :
        LET read == DecodeFuturesRequestForQuoteRfqMessage(EncodeFuturesRequestForQuoteRfqMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripLongMessageHeader8 ==
    \A message \in CheckedLongMessageHeader8 :
        LET read == DecodeLongMessageHeader8(EncodeLongMessageHeader8(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Request For Quote Rfq Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyRequestForQuoteRfqMessage ==
    \A message \in CheckedStrategyRequestForQuoteRfqMessage :
        LET read == DecodeStrategyRequestForQuoteRfqMessage(EncodeStrategyRequestForQuoteRfqMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripLongMessageHeader9 ==
    \A message \in CheckedLongMessageHeader9 :
        LET read == DecodeLongMessageHeader9(EncodeLongMessageHeader9(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Symbol decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionSymbol3 ==
    \A message \in CheckedOptionSymbol3 :
        LET read == DecodeOptionSymbol3(EncodeOptionSymbol3(message))
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

(* Every Long Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripLongMessageHeader10 ==
    \A message \in CheckedLongMessageHeader10 :
        LET read == DecodeLongMessageHeader10(EncodeLongMessageHeader10(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Option Symbol decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureOptionSymbol3 ==
    \A message \in CheckedFutureOptionSymbol3 :
        LET read == DecodeFutureOptionSymbol3(EncodeFutureOptionSymbol3(message))
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

(* Every Long Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripLongMessageHeader11 ==
    \A message \in CheckedLongMessageHeader11 :
        LET read == DecodeLongMessageHeader11(EncodeLongMessageHeader11(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Product decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureProduct3 ==
    \A message \in CheckedFutureProduct3 :
        LET read == DecodeFutureProduct3(EncodeFutureProduct3(message))
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

(* Every Long Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripLongMessageHeader12 ==
    \A message \in CheckedLongMessageHeader12 :
        LET read == DecodeLongMessageHeader12(EncodeLongMessageHeader12(message))
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

(* Every Long Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripLongMessageHeader13 ==
    \A message \in CheckedLongMessageHeader13 :
        LET read == DecodeLongMessageHeader13(EncodeLongMessageHeader13(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Symbol decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionSymbol4 ==
    \A message \in CheckedOptionSymbol4 :
        LET read == DecodeOptionSymbol4(EncodeOptionSymbol4(message))
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

(* Every Long Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripLongMessageHeader14 ==
    \A message \in CheckedLongMessageHeader14 :
        LET read == DecodeLongMessageHeader14(EncodeLongMessageHeader14(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Option Symbol decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureOptionSymbol4 ==
    \A message \in CheckedFutureOptionSymbol4 :
        LET read == DecodeFutureOptionSymbol4(EncodeFutureOptionSymbol4(message))
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

(* Every Long Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripLongMessageHeader15 ==
    \A message \in CheckedLongMessageHeader15 :
        LET read == DecodeLongMessageHeader15(EncodeLongMessageHeader15(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Product decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureProduct4 ==
    \A message \in CheckedFutureProduct4 :
        LET read == DecodeFutureProduct4(EncodeFutureProduct4(message))
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

(* Every Long Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripLongMessageHeader16 ==
    \A message \in CheckedLongMessageHeader16 :
        LET read == DecodeLongMessageHeader16(EncodeLongMessageHeader16(message))
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

(* Every Long Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripLongMessageHeader17 ==
    \A message \in CheckedLongMessageHeader17 :
        LET read == DecodeLongMessageHeader17(EncodeLongMessageHeader17(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Symbol decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionSymbol5 ==
    \A message \in CheckedOptionSymbol5 :
        LET read == DecodeOptionSymbol5(EncodeOptionSymbol5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Depth Level decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketDepthLevel ==
    \A message \in CheckedMarketDepthLevel :
        LET read == DecodeMarketDepthLevel(EncodeMarketDepthLevel(message))
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

(* Every Long Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripLongMessageHeader18 ==
    \A message \in CheckedLongMessageHeader18 :
        LET read == DecodeLongMessageHeader18(EncodeLongMessageHeader18(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Option Symbol decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureOptionSymbol5 ==
    \A message \in CheckedFutureOptionSymbol5 :
        LET read == DecodeFutureOptionSymbol5(EncodeFutureOptionSymbol5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Depth Level decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketDepthLevel2 ==
    \A message \in CheckedMarketDepthLevel2 :
        LET read == DecodeMarketDepthLevel2(EncodeMarketDepthLevel2(message))
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

(* Every Long Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripLongMessageHeader19 ==
    \A message \in CheckedLongMessageHeader19 :
        LET read == DecodeLongMessageHeader19(EncodeLongMessageHeader19(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Product decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureProduct5 ==
    \A message \in CheckedFutureProduct5 :
        LET read == DecodeFutureProduct5(EncodeFutureProduct5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Depth Level decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketDepthLevel3 ==
    \A message \in CheckedMarketDepthLevel3 :
        LET read == DecodeMarketDepthLevel3(EncodeMarketDepthLevel3(message))
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

(* Every Long Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripLongMessageHeader20 ==
    \A message \in CheckedLongMessageHeader20 :
        LET read == DecodeLongMessageHeader20(EncodeLongMessageHeader20(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Market Depth Level decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyMarketDepthLevel ==
    \A message \in CheckedStrategyMarketDepthLevel :
        LET read == DecodeStrategyMarketDepthLevel(EncodeStrategyMarketDepthLevel(message))
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

(* Every Long Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripLongMessageHeader21 ==
    \A message \in CheckedLongMessageHeader21 :
        LET read == DecodeLongMessageHeader21(EncodeLongMessageHeader21(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Symbol decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionSymbol6 ==
    \A message \in CheckedOptionSymbol6 :
        LET read == DecodeOptionSymbol6(EncodeOptionSymbol6(message))
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

(* Every Long Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripLongMessageHeader22 ==
    \A message \in CheckedLongMessageHeader22 :
        LET read == DecodeLongMessageHeader22(EncodeLongMessageHeader22(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Option Symbol decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureOptionSymbol6 ==
    \A message \in CheckedFutureOptionSymbol6 :
        LET read == DecodeFutureOptionSymbol6(EncodeFutureOptionSymbol6(message))
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

(* Every Long Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripLongMessageHeader23 ==
    \A message \in CheckedLongMessageHeader23 :
        LET read == DecodeLongMessageHeader23(EncodeLongMessageHeader23(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Product decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureProduct6 ==
    \A message \in CheckedFutureProduct6 :
        LET read == DecodeFutureProduct6(EncodeFutureProduct6(message))
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

(* Every Long Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripLongMessageHeader24 ==
    \A message \in CheckedLongMessageHeader24 :
        LET read == DecodeLongMessageHeader24(EncodeLongMessageHeader24(message))
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

(* Every Long Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripLongMessageHeader25 ==
    \A message \in CheckedLongMessageHeader25 :
        LET read == DecodeLongMessageHeader25(EncodeLongMessageHeader25(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Symbol decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionSymbol7 ==
    \A message \in CheckedOptionSymbol7 :
        LET read == DecodeOptionSymbol7(EncodeOptionSymbol7(message))
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

(* Every Long Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripLongMessageHeader26 ==
    \A message \in CheckedLongMessageHeader26 :
        LET read == DecodeLongMessageHeader26(EncodeLongMessageHeader26(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Option Symbol decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureOptionSymbol7 ==
    \A message \in CheckedFutureOptionSymbol7 :
        LET read == DecodeFutureOptionSymbol7(EncodeFutureOptionSymbol7(message))
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

(* Every Long Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripLongMessageHeader27 ==
    \A message \in CheckedLongMessageHeader27 :
        LET read == DecodeLongMessageHeader27(EncodeLongMessageHeader27(message))
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

(* Every Long Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripLongMessageHeader28 ==
    \A message \in CheckedLongMessageHeader28 :
        LET read == DecodeLongMessageHeader28(EncodeLongMessageHeader28(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Product decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureProduct7 ==
    \A message \in CheckedFutureProduct7 :
        LET read == DecodeFutureProduct7(EncodeFutureProduct7(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Associated Product decodes back to what was encoded, and leaves nothing over *)
RoundTripAssociatedProduct ==
    \A message \in CheckedAssociatedProduct :
        LET read == DecodeAssociatedProduct(EncodeAssociatedProduct(message))
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

(* Every Long Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripLongMessageHeader29 ==
    \A message \in CheckedLongMessageHeader29 :
        LET read == DecodeLongMessageHeader29(EncodeLongMessageHeader29(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Instrument Leg decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyInstrumentLeg ==
    \A message \in CheckedStrategyInstrumentLeg :
        LET read == DecodeStrategyInstrumentLeg(EncodeStrategyInstrumentLeg(message))
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

(* Every Long Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripLongMessageHeader30 ==
    \A message \in CheckedLongMessageHeader30 :
        LET read == DecodeLongMessageHeader30(EncodeLongMessageHeader30(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Symbol decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionSymbol8 ==
    \A message \in CheckedOptionSymbol8 :
        LET read == DecodeOptionSymbol8(EncodeOptionSymbol8(message))
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

(* Every Long Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripLongMessageHeader31 ==
    \A message \in CheckedLongMessageHeader31 :
        LET read == DecodeLongMessageHeader31(EncodeLongMessageHeader31(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Option Symbol decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureOptionSymbol8 ==
    \A message \in CheckedFutureOptionSymbol8 :
        LET read == DecodeFutureOptionSymbol8(EncodeFutureOptionSymbol8(message))
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

(* Every Long Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripLongMessageHeader32 ==
    \A message \in CheckedLongMessageHeader32 :
        LET read == DecodeLongMessageHeader32(EncodeLongMessageHeader32(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Product decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureProduct8 ==
    \A message \in CheckedFutureProduct8 :
        LET read == DecodeFutureProduct8(EncodeFutureProduct8(message))
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

(* Every Long Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripLongMessageHeader33 ==
    \A message \in CheckedLongMessageHeader33 :
        LET read == DecodeLongMessageHeader33(EncodeLongMessageHeader33(message))
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

(* Every Long Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripLongMessageHeader34 ==
    \A message \in CheckedLongMessageHeader34 :
        LET read == DecodeLongMessageHeader34(EncodeLongMessageHeader34(message))
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

(* Every Long Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripLongMessageHeader35 ==
    \A message \in CheckedLongMessageHeader35 :
        LET read == DecodeLongMessageHeader35(EncodeLongMessageHeader35(message))
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

(* Every Long Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripLongMessageHeader36 ==
    \A message \in CheckedLongMessageHeader36 :
        LET read == DecodeLongMessageHeader36(EncodeLongMessageHeader36(message))
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

(* Every Long Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripLongMessageHeader37 ==
    \A message \in CheckedLongMessageHeader37 :
        LET read == DecodeLongMessageHeader37(EncodeLongMessageHeader37(message))
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

(* Every Long Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripLongMessageHeader38 ==
    \A message \in CheckedLongMessageHeader38 :
        LET read == DecodeLongMessageHeader38(EncodeLongMessageHeader38(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Product decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureProduct9 ==
    \A message \in CheckedFutureProduct9 :
        LET read == DecodeFutureProduct9(EncodeFutureProduct9(message))
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

(* Every Long Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripLongMessageHeader39 ==
    \A message \in CheckedLongMessageHeader39 :
        LET read == DecodeLongMessageHeader39(EncodeLongMessageHeader39(message))
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

(* Every Long Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripLongMessageHeader40 ==
    \A message \in CheckedLongMessageHeader40 :
        LET read == DecodeLongMessageHeader40(EncodeLongMessageHeader40(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Group Status Strategies Message decodes back to what was encoded, and leaves nothing over *)
RoundTripGroupStatusStrategiesMessage ==
    \A message \in CheckedGroupStatusStrategiesMessage :
        LET read == DecodeGroupStatusStrategiesMessage(EncodeGroupStatusStrategiesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripLongMessageHeader41 ==
    \A message \in CheckedLongMessageHeader41 :
        LET read == DecodeLongMessageHeader41(EncodeLongMessageHeader41(message))
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

(* Every Long Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripLongMessageHeader42 ==
    \A message \in CheckedLongMessageHeader42 :
        LET read == DecodeLongMessageHeader42(EncodeLongMessageHeader42(message))
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

(* Every Long Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripLongMessageHeader43 ==
    \A message \in CheckedLongMessageHeader43 :
        LET read == DecodeLongMessageHeader43(EncodeLongMessageHeader43(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tick Entry decodes back to what was encoded, and leaves nothing over *)
RoundTripTickEntry ==
    \A message \in CheckedTickEntry :
        LET read == DecodeTickEntry(EncodeTickEntry(message))
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

(* Every Long Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripLongMessageHeader44 ==
    \A message \in CheckedLongMessageHeader44 :
        LET read == DecodeLongMessageHeader44(EncodeLongMessageHeader44(message))
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

(* Every Long Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripLongMessageHeader45 ==
    \A message \in CheckedLongMessageHeader45 :
        LET read == DecodeLongMessageHeader45(EncodeLongMessageHeader45(message))
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
