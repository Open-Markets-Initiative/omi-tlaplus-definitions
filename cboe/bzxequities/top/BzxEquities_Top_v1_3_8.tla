---------------------- MODULE BzxEquities_Top_v1_3_8 -----------------------
(***************************************************************************)
(* Chicago Board Options Exchange Top v1.3.8                               *)
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
(* License: MIT No Attribution                                             *)
(*                                                                         *)
(* Note: Frame is of no one width: each is read by its own fields, and     *)
(* since every reading of it takes at least 2 bytes off the reader the run *)
(* ends where the data does.                                               *)
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
(* Logon Message: 17 bytes                                                 *)
(***************************************************************************)

LogonMessage ==
    [ username : Sample(6),
      password : Sample(10),
      spinFlag : Sample(1) ]

EncodeLogonMessage(message) ==
    message.username
        \o message.password
        \o message.spinFlag

DecodeLogonMessage(bytes) ==
    LET username == ReadBytes(bytes, 6) IN IF ~username.ok THEN Fail ELSE
    LET password == ReadBytes(username.rest, 10) IN IF ~password.ok THEN Fail ELSE
    LET spinFlag == ReadBytes(password.rest, 1) IN IF ~spinFlag.ok THEN Fail ELSE
    Ok([ username |-> username.value,
         password |-> password.value,
         spinFlag |-> spinFlag.value ], spinFlag.rest)

ZeroLogonMessage ==
    [ username |-> [i \in 1 .. 6 |-> 0],
      password |-> [i \in 1 .. 10 |-> 0],
      spinFlag |-> [i \in 1 .. 1 |-> 0] ]

(* Logon Message at zero, then each field in turn at the values it is checked at *)
CheckedLogonMessage ==
    { ZeroLogonMessage }
        \cup { [ZeroLogonMessage EXCEPT !.username = one] : one \in Sample(6) }
        \cup { [ZeroLogonMessage EXCEPT !.password = one] : one \in Sample(10) }
        \cup { [ZeroLogonMessage EXCEPT !.spinFlag = one] : one \in Sample(1) }

(***************************************************************************)
(* Logon Rejected Message: 1 bytes                                         *)
(***************************************************************************)

LogonRejectedMessage ==
    [ rejectReason : Sample(1) ]

EncodeLogonRejectedMessage(message) ==
    message.rejectReason

DecodeLogonRejectedMessage(bytes) ==
    LET rejectReason == ReadBytes(bytes, 1) IN IF ~rejectReason.ok THEN Fail ELSE
    Ok([ rejectReason |-> rejectReason.value ], rejectReason.rest)

ZeroLogonRejectedMessage ==
    [ rejectReason |-> [i \in 1 .. 1 |-> 0] ]

(* Logon Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedLogonRejectedMessage ==
    { ZeroLogonRejectedMessage }
        \cup { [ZeroLogonRejectedMessage EXCEPT !.rejectReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Seconds Message: 5 bytes                                                *)
(***************************************************************************)

SecondsMessage ==
    [ seconds : Sample(5) ]

EncodeSecondsMessage(message) ==
    message.seconds

DecodeSecondsMessage(bytes) ==
    LET seconds == ReadBytes(bytes, 5) IN IF ~seconds.ok THEN Fail ELSE
    Ok([ seconds |-> seconds.value ], seconds.rest)

ZeroSecondsMessage ==
    [ seconds |-> [i \in 1 .. 5 |-> 0] ]

(* Seconds Message at zero, then each field in turn at the values it is checked at *)
CheckedSecondsMessage ==
    { ZeroSecondsMessage }
        \cup { [ZeroSecondsMessage EXCEPT !.seconds = one] : one \in Sample(5) }

(***************************************************************************)
(* Milliseconds Message: 3 bytes                                           *)
(***************************************************************************)

MillisecondsMessage ==
    [ milliseconds : Sample(3) ]

EncodeMillisecondsMessage(message) ==
    message.milliseconds

DecodeMillisecondsMessage(bytes) ==
    LET milliseconds == ReadBytes(bytes, 3) IN IF ~milliseconds.ok THEN Fail ELSE
    Ok([ milliseconds |-> milliseconds.value ], milliseconds.rest)

ZeroMillisecondsMessage ==
    [ milliseconds |-> [i \in 1 .. 3 |-> 0] ]

(* Milliseconds Message at zero, then each field in turn at the values it is checked at *)
CheckedMillisecondsMessage ==
    { ZeroMillisecondsMessage }
        \cup { [ZeroMillisecondsMessage EXCEPT !.milliseconds = one] : one \in Sample(3) }

(***************************************************************************)
(* Expanded Spin Message: 85 bytes                                         *)
(***************************************************************************)

ExpandedSpinMessage ==
    [ timestamp            : Sample(8),
      symbolExtended       : Sample(8),
      bidPriceLong         : Sample(10),
      bidQuantityLong      : Sample(6),
      askPriceLong         : Sample(10),
      askQuantityLong      : Sample(6),
      lastTradeTime        : Sample(8),
      lastTradePriceShort  : Sample(10),
      lastTradeSize        : Sample(6),
      cumulativeVolumeLong : Sample(9),
      haltStatus           : Sample(1),
      regShoAction         : Sample(1),
      reserved1            : Sample(1),
      reserved2            : Sample(1) ]

EncodeExpandedSpinMessage(message) ==
    message.timestamp
        \o message.symbolExtended
        \o message.bidPriceLong
        \o message.bidQuantityLong
        \o message.askPriceLong
        \o message.askQuantityLong
        \o message.lastTradeTime
        \o message.lastTradePriceShort
        \o message.lastTradeSize
        \o message.cumulativeVolumeLong
        \o message.haltStatus
        \o message.regShoAction
        \o message.reserved1
        \o message.reserved2

DecodeExpandedSpinMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbolExtended == ReadBytes(timestamp.rest, 8) IN IF ~symbolExtended.ok THEN Fail ELSE
    LET bidPriceLong == ReadBytes(symbolExtended.rest, 10) IN IF ~bidPriceLong.ok THEN Fail ELSE
    LET bidQuantityLong == ReadBytes(bidPriceLong.rest, 6) IN IF ~bidQuantityLong.ok THEN Fail ELSE
    LET askPriceLong == ReadBytes(bidQuantityLong.rest, 10) IN IF ~askPriceLong.ok THEN Fail ELSE
    LET askQuantityLong == ReadBytes(askPriceLong.rest, 6) IN IF ~askQuantityLong.ok THEN Fail ELSE
    LET lastTradeTime == ReadBytes(askQuantityLong.rest, 8) IN IF ~lastTradeTime.ok THEN Fail ELSE
    LET lastTradePriceShort == ReadBytes(lastTradeTime.rest, 10) IN IF ~lastTradePriceShort.ok THEN Fail ELSE
    LET lastTradeSize == ReadBytes(lastTradePriceShort.rest, 6) IN IF ~lastTradeSize.ok THEN Fail ELSE
    LET cumulativeVolumeLong == ReadBytes(lastTradeSize.rest, 9) IN IF ~cumulativeVolumeLong.ok THEN Fail ELSE
    LET haltStatus == ReadBytes(cumulativeVolumeLong.rest, 1) IN IF ~haltStatus.ok THEN Fail ELSE
    LET regShoAction == ReadBytes(haltStatus.rest, 1) IN IF ~regShoAction.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(regShoAction.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(reserved1.rest, 1) IN IF ~reserved2.ok THEN Fail ELSE
    Ok([ timestamp            |-> timestamp.value,
         symbolExtended       |-> symbolExtended.value,
         bidPriceLong         |-> bidPriceLong.value,
         bidQuantityLong      |-> bidQuantityLong.value,
         askPriceLong         |-> askPriceLong.value,
         askQuantityLong      |-> askQuantityLong.value,
         lastTradeTime        |-> lastTradeTime.value,
         lastTradePriceShort  |-> lastTradePriceShort.value,
         lastTradeSize        |-> lastTradeSize.value,
         cumulativeVolumeLong |-> cumulativeVolumeLong.value,
         haltStatus           |-> haltStatus.value,
         regShoAction         |-> regShoAction.value,
         reserved1            |-> reserved1.value,
         reserved2            |-> reserved2.value ], reserved2.rest)

ZeroExpandedSpinMessage ==
    [ timestamp            |-> [i \in 1 .. 8 |-> 0],
      symbolExtended       |-> [i \in 1 .. 8 |-> 0],
      bidPriceLong         |-> [i \in 1 .. 10 |-> 0],
      bidQuantityLong      |-> [i \in 1 .. 6 |-> 0],
      askPriceLong         |-> [i \in 1 .. 10 |-> 0],
      askQuantityLong      |-> [i \in 1 .. 6 |-> 0],
      lastTradeTime        |-> [i \in 1 .. 8 |-> 0],
      lastTradePriceShort  |-> [i \in 1 .. 10 |-> 0],
      lastTradeSize        |-> [i \in 1 .. 6 |-> 0],
      cumulativeVolumeLong |-> [i \in 1 .. 9 |-> 0],
      haltStatus           |-> [i \in 1 .. 1 |-> 0],
      regShoAction         |-> [i \in 1 .. 1 |-> 0],
      reserved1            |-> [i \in 1 .. 1 |-> 0],
      reserved2            |-> [i \in 1 .. 1 |-> 0] ]

(* Expanded Spin Message at zero, then each field in turn at the values it is checked at *)
CheckedExpandedSpinMessage ==
    { ZeroExpandedSpinMessage }
        \cup { [ZeroExpandedSpinMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroExpandedSpinMessage EXCEPT !.symbolExtended = one] : one \in Sample(8) }
        \cup { [ZeroExpandedSpinMessage EXCEPT !.bidPriceLong = one] : one \in Sample(10) }
        \cup { [ZeroExpandedSpinMessage EXCEPT !.bidQuantityLong = one] : one \in Sample(6) }
        \cup { [ZeroExpandedSpinMessage EXCEPT !.askPriceLong = one] : one \in Sample(10) }
        \cup { [ZeroExpandedSpinMessage EXCEPT !.askQuantityLong = one] : one \in Sample(6) }
        \cup { [ZeroExpandedSpinMessage EXCEPT !.lastTradeTime = one] : one \in Sample(8) }
        \cup { [ZeroExpandedSpinMessage EXCEPT !.lastTradePriceShort = one] : one \in Sample(10) }
        \cup { [ZeroExpandedSpinMessage EXCEPT !.lastTradeSize = one] : one \in Sample(6) }
        \cup { [ZeroExpandedSpinMessage EXCEPT !.cumulativeVolumeLong = one] : one \in Sample(9) }
        \cup { [ZeroExpandedSpinMessage EXCEPT !.haltStatus = one] : one \in Sample(1) }
        \cup { [ZeroExpandedSpinMessage EXCEPT !.regShoAction = one] : one \in Sample(1) }
        \cup { [ZeroExpandedSpinMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroExpandedSpinMessage EXCEPT !.reserved2 = one] : one \in Sample(1) }

(***************************************************************************)
(* Extended Spin Message: 97 bytes                                         *)
(***************************************************************************)

ExtendedSpinMessage ==
    [ timestamp            : Sample(8),
      symbolExtended       : Sample(8),
      bidPriceExtended     : Sample(14),
      bidQuantityLong      : Sample(6),
      askPriceExtended     : Sample(14),
      askQuantityLong      : Sample(6),
      lastTradeTime        : Sample(8),
      lastTradePriceLong   : Sample(14),
      lastTradeSize        : Sample(6),
      cumulativeVolumeLong : Sample(9),
      haltStatus           : Sample(1),
      regShoAction         : Sample(1),
      reserved1            : Sample(1),
      reserved2            : Sample(1) ]

EncodeExtendedSpinMessage(message) ==
    message.timestamp
        \o message.symbolExtended
        \o message.bidPriceExtended
        \o message.bidQuantityLong
        \o message.askPriceExtended
        \o message.askQuantityLong
        \o message.lastTradeTime
        \o message.lastTradePriceLong
        \o message.lastTradeSize
        \o message.cumulativeVolumeLong
        \o message.haltStatus
        \o message.regShoAction
        \o message.reserved1
        \o message.reserved2

DecodeExtendedSpinMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbolExtended == ReadBytes(timestamp.rest, 8) IN IF ~symbolExtended.ok THEN Fail ELSE
    LET bidPriceExtended == ReadBytes(symbolExtended.rest, 14) IN IF ~bidPriceExtended.ok THEN Fail ELSE
    LET bidQuantityLong == ReadBytes(bidPriceExtended.rest, 6) IN IF ~bidQuantityLong.ok THEN Fail ELSE
    LET askPriceExtended == ReadBytes(bidQuantityLong.rest, 14) IN IF ~askPriceExtended.ok THEN Fail ELSE
    LET askQuantityLong == ReadBytes(askPriceExtended.rest, 6) IN IF ~askQuantityLong.ok THEN Fail ELSE
    LET lastTradeTime == ReadBytes(askQuantityLong.rest, 8) IN IF ~lastTradeTime.ok THEN Fail ELSE
    LET lastTradePriceLong == ReadBytes(lastTradeTime.rest, 14) IN IF ~lastTradePriceLong.ok THEN Fail ELSE
    LET lastTradeSize == ReadBytes(lastTradePriceLong.rest, 6) IN IF ~lastTradeSize.ok THEN Fail ELSE
    LET cumulativeVolumeLong == ReadBytes(lastTradeSize.rest, 9) IN IF ~cumulativeVolumeLong.ok THEN Fail ELSE
    LET haltStatus == ReadBytes(cumulativeVolumeLong.rest, 1) IN IF ~haltStatus.ok THEN Fail ELSE
    LET regShoAction == ReadBytes(haltStatus.rest, 1) IN IF ~regShoAction.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(regShoAction.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(reserved1.rest, 1) IN IF ~reserved2.ok THEN Fail ELSE
    Ok([ timestamp            |-> timestamp.value,
         symbolExtended       |-> symbolExtended.value,
         bidPriceExtended     |-> bidPriceExtended.value,
         bidQuantityLong      |-> bidQuantityLong.value,
         askPriceExtended     |-> askPriceExtended.value,
         askQuantityLong      |-> askQuantityLong.value,
         lastTradeTime        |-> lastTradeTime.value,
         lastTradePriceLong   |-> lastTradePriceLong.value,
         lastTradeSize        |-> lastTradeSize.value,
         cumulativeVolumeLong |-> cumulativeVolumeLong.value,
         haltStatus           |-> haltStatus.value,
         regShoAction         |-> regShoAction.value,
         reserved1            |-> reserved1.value,
         reserved2            |-> reserved2.value ], reserved2.rest)

ZeroExtendedSpinMessage ==
    [ timestamp            |-> [i \in 1 .. 8 |-> 0],
      symbolExtended       |-> [i \in 1 .. 8 |-> 0],
      bidPriceExtended     |-> [i \in 1 .. 14 |-> 0],
      bidQuantityLong      |-> [i \in 1 .. 6 |-> 0],
      askPriceExtended     |-> [i \in 1 .. 14 |-> 0],
      askQuantityLong      |-> [i \in 1 .. 6 |-> 0],
      lastTradeTime        |-> [i \in 1 .. 8 |-> 0],
      lastTradePriceLong   |-> [i \in 1 .. 14 |-> 0],
      lastTradeSize        |-> [i \in 1 .. 6 |-> 0],
      cumulativeVolumeLong |-> [i \in 1 .. 9 |-> 0],
      haltStatus           |-> [i \in 1 .. 1 |-> 0],
      regShoAction         |-> [i \in 1 .. 1 |-> 0],
      reserved1            |-> [i \in 1 .. 1 |-> 0],
      reserved2            |-> [i \in 1 .. 1 |-> 0] ]

(* Extended Spin Message at zero, then each field in turn at the values it is checked at *)
CheckedExtendedSpinMessage ==
    { ZeroExtendedSpinMessage }
        \cup { [ZeroExtendedSpinMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroExtendedSpinMessage EXCEPT !.symbolExtended = one] : one \in Sample(8) }
        \cup { [ZeroExtendedSpinMessage EXCEPT !.bidPriceExtended = one] : one \in Sample(14) }
        \cup { [ZeroExtendedSpinMessage EXCEPT !.bidQuantityLong = one] : one \in Sample(6) }
        \cup { [ZeroExtendedSpinMessage EXCEPT !.askPriceExtended = one] : one \in Sample(14) }
        \cup { [ZeroExtendedSpinMessage EXCEPT !.askQuantityLong = one] : one \in Sample(6) }
        \cup { [ZeroExtendedSpinMessage EXCEPT !.lastTradeTime = one] : one \in Sample(8) }
        \cup { [ZeroExtendedSpinMessage EXCEPT !.lastTradePriceLong = one] : one \in Sample(14) }
        \cup { [ZeroExtendedSpinMessage EXCEPT !.lastTradeSize = one] : one \in Sample(6) }
        \cup { [ZeroExtendedSpinMessage EXCEPT !.cumulativeVolumeLong = one] : one \in Sample(9) }
        \cup { [ZeroExtendedSpinMessage EXCEPT !.haltStatus = one] : one \in Sample(1) }
        \cup { [ZeroExtendedSpinMessage EXCEPT !.regShoAction = one] : one \in Sample(1) }
        \cup { [ZeroExtendedSpinMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroExtendedSpinMessage EXCEPT !.reserved2 = one] : one \in Sample(1) }

(***************************************************************************)
(* Expanded Bid Update Message: 24 bytes                                   *)
(***************************************************************************)

ExpandedBidUpdateMessage ==
    [ symbolExtended  : Sample(8),
      bidPriceLong    : Sample(10),
      bidQuantityLong : Sample(6) ]

EncodeExpandedBidUpdateMessage(message) ==
    message.symbolExtended
        \o message.bidPriceLong
        \o message.bidQuantityLong

DecodeExpandedBidUpdateMessage(bytes) ==
    LET symbolExtended == ReadBytes(bytes, 8) IN IF ~symbolExtended.ok THEN Fail ELSE
    LET bidPriceLong == ReadBytes(symbolExtended.rest, 10) IN IF ~bidPriceLong.ok THEN Fail ELSE
    LET bidQuantityLong == ReadBytes(bidPriceLong.rest, 6) IN IF ~bidQuantityLong.ok THEN Fail ELSE
    Ok([ symbolExtended  |-> symbolExtended.value,
         bidPriceLong    |-> bidPriceLong.value,
         bidQuantityLong |-> bidQuantityLong.value ], bidQuantityLong.rest)

ZeroExpandedBidUpdateMessage ==
    [ symbolExtended  |-> [i \in 1 .. 8 |-> 0],
      bidPriceLong    |-> [i \in 1 .. 10 |-> 0],
      bidQuantityLong |-> [i \in 1 .. 6 |-> 0] ]

(* Expanded Bid Update Message at zero, then each field in turn at the values it is checked at *)
CheckedExpandedBidUpdateMessage ==
    { ZeroExpandedBidUpdateMessage }
        \cup { [ZeroExpandedBidUpdateMessage EXCEPT !.symbolExtended = one] : one \in Sample(8) }
        \cup { [ZeroExpandedBidUpdateMessage EXCEPT !.bidPriceLong = one] : one \in Sample(10) }
        \cup { [ZeroExpandedBidUpdateMessage EXCEPT !.bidQuantityLong = one] : one \in Sample(6) }

(***************************************************************************)
(* Long Bid Update Message: 22 bytes                                       *)
(***************************************************************************)

LongBidUpdateMessage ==
    [ symbolLong      : Sample(6),
      bidPriceLong    : Sample(10),
      bidQuantityLong : Sample(6) ]

EncodeLongBidUpdateMessage(message) ==
    message.symbolLong
        \o message.bidPriceLong
        \o message.bidQuantityLong

DecodeLongBidUpdateMessage(bytes) ==
    LET symbolLong == ReadBytes(bytes, 6) IN IF ~symbolLong.ok THEN Fail ELSE
    LET bidPriceLong == ReadBytes(symbolLong.rest, 10) IN IF ~bidPriceLong.ok THEN Fail ELSE
    LET bidQuantityLong == ReadBytes(bidPriceLong.rest, 6) IN IF ~bidQuantityLong.ok THEN Fail ELSE
    Ok([ symbolLong      |-> symbolLong.value,
         bidPriceLong    |-> bidPriceLong.value,
         bidQuantityLong |-> bidQuantityLong.value ], bidQuantityLong.rest)

ZeroLongBidUpdateMessage ==
    [ symbolLong      |-> [i \in 1 .. 6 |-> 0],
      bidPriceLong    |-> [i \in 1 .. 10 |-> 0],
      bidQuantityLong |-> [i \in 1 .. 6 |-> 0] ]

(* Long Bid Update Message at zero, then each field in turn at the values it is checked at *)
CheckedLongBidUpdateMessage ==
    { ZeroLongBidUpdateMessage }
        \cup { [ZeroLongBidUpdateMessage EXCEPT !.symbolLong = one] : one \in Sample(6) }
        \cup { [ZeroLongBidUpdateMessage EXCEPT !.bidPriceLong = one] : one \in Sample(10) }
        \cup { [ZeroLongBidUpdateMessage EXCEPT !.bidQuantityLong = one] : one \in Sample(6) }

(***************************************************************************)
(* Short Bid Update Message: 14 bytes                                      *)
(***************************************************************************)

ShortBidUpdateMessage ==
    [ symbolShort      : Sample(4),
      bidPriceShort    : Sample(5),
      bidQuantityShort : Sample(5) ]

EncodeShortBidUpdateMessage(message) ==
    message.symbolShort
        \o message.bidPriceShort
        \o message.bidQuantityShort

DecodeShortBidUpdateMessage(bytes) ==
    LET symbolShort == ReadBytes(bytes, 4) IN IF ~symbolShort.ok THEN Fail ELSE
    LET bidPriceShort == ReadBytes(symbolShort.rest, 5) IN IF ~bidPriceShort.ok THEN Fail ELSE
    LET bidQuantityShort == ReadBytes(bidPriceShort.rest, 5) IN IF ~bidQuantityShort.ok THEN Fail ELSE
    Ok([ symbolShort      |-> symbolShort.value,
         bidPriceShort    |-> bidPriceShort.value,
         bidQuantityShort |-> bidQuantityShort.value ], bidQuantityShort.rest)

ZeroShortBidUpdateMessage ==
    [ symbolShort      |-> [i \in 1 .. 4 |-> 0],
      bidPriceShort    |-> [i \in 1 .. 5 |-> 0],
      bidQuantityShort |-> [i \in 1 .. 5 |-> 0] ]

(* Short Bid Update Message at zero, then each field in turn at the values it is checked at *)
CheckedShortBidUpdateMessage ==
    { ZeroShortBidUpdateMessage }
        \cup { [ZeroShortBidUpdateMessage EXCEPT !.symbolShort = one] : one \in Sample(4) }
        \cup { [ZeroShortBidUpdateMessage EXCEPT !.bidPriceShort = one] : one \in Sample(5) }
        \cup { [ZeroShortBidUpdateMessage EXCEPT !.bidQuantityShort = one] : one \in Sample(5) }

(***************************************************************************)
(* Extended Bid Update Message: 28 bytes                                   *)
(***************************************************************************)

ExtendedBidUpdateMessage ==
    [ symbolExtended   : Sample(8),
      bidPriceExtended : Sample(14),
      bidQuantityLong  : Sample(6) ]

EncodeExtendedBidUpdateMessage(message) ==
    message.symbolExtended
        \o message.bidPriceExtended
        \o message.bidQuantityLong

DecodeExtendedBidUpdateMessage(bytes) ==
    LET symbolExtended == ReadBytes(bytes, 8) IN IF ~symbolExtended.ok THEN Fail ELSE
    LET bidPriceExtended == ReadBytes(symbolExtended.rest, 14) IN IF ~bidPriceExtended.ok THEN Fail ELSE
    LET bidQuantityLong == ReadBytes(bidPriceExtended.rest, 6) IN IF ~bidQuantityLong.ok THEN Fail ELSE
    Ok([ symbolExtended   |-> symbolExtended.value,
         bidPriceExtended |-> bidPriceExtended.value,
         bidQuantityLong  |-> bidQuantityLong.value ], bidQuantityLong.rest)

ZeroExtendedBidUpdateMessage ==
    [ symbolExtended   |-> [i \in 1 .. 8 |-> 0],
      bidPriceExtended |-> [i \in 1 .. 14 |-> 0],
      bidQuantityLong  |-> [i \in 1 .. 6 |-> 0] ]

(* Extended Bid Update Message at zero, then each field in turn at the values it is checked at *)
CheckedExtendedBidUpdateMessage ==
    { ZeroExtendedBidUpdateMessage }
        \cup { [ZeroExtendedBidUpdateMessage EXCEPT !.symbolExtended = one] : one \in Sample(8) }
        \cup { [ZeroExtendedBidUpdateMessage EXCEPT !.bidPriceExtended = one] : one \in Sample(14) }
        \cup { [ZeroExtendedBidUpdateMessage EXCEPT !.bidQuantityLong = one] : one \in Sample(6) }

(***************************************************************************)
(* Expanded Ask Update Message: 24 bytes                                   *)
(***************************************************************************)

ExpandedAskUpdateMessage ==
    [ symbolExtended  : Sample(8),
      askPriceLong    : Sample(10),
      askQuantityLong : Sample(6) ]

EncodeExpandedAskUpdateMessage(message) ==
    message.symbolExtended
        \o message.askPriceLong
        \o message.askQuantityLong

DecodeExpandedAskUpdateMessage(bytes) ==
    LET symbolExtended == ReadBytes(bytes, 8) IN IF ~symbolExtended.ok THEN Fail ELSE
    LET askPriceLong == ReadBytes(symbolExtended.rest, 10) IN IF ~askPriceLong.ok THEN Fail ELSE
    LET askQuantityLong == ReadBytes(askPriceLong.rest, 6) IN IF ~askQuantityLong.ok THEN Fail ELSE
    Ok([ symbolExtended  |-> symbolExtended.value,
         askPriceLong    |-> askPriceLong.value,
         askQuantityLong |-> askQuantityLong.value ], askQuantityLong.rest)

ZeroExpandedAskUpdateMessage ==
    [ symbolExtended  |-> [i \in 1 .. 8 |-> 0],
      askPriceLong    |-> [i \in 1 .. 10 |-> 0],
      askQuantityLong |-> [i \in 1 .. 6 |-> 0] ]

(* Expanded Ask Update Message at zero, then each field in turn at the values it is checked at *)
CheckedExpandedAskUpdateMessage ==
    { ZeroExpandedAskUpdateMessage }
        \cup { [ZeroExpandedAskUpdateMessage EXCEPT !.symbolExtended = one] : one \in Sample(8) }
        \cup { [ZeroExpandedAskUpdateMessage EXCEPT !.askPriceLong = one] : one \in Sample(10) }
        \cup { [ZeroExpandedAskUpdateMessage EXCEPT !.askQuantityLong = one] : one \in Sample(6) }

(***************************************************************************)
(* Long Ask Update Message: 22 bytes                                       *)
(***************************************************************************)

LongAskUpdateMessage ==
    [ symbolLong      : Sample(6),
      askPriceLong    : Sample(10),
      askQuantityLong : Sample(6) ]

EncodeLongAskUpdateMessage(message) ==
    message.symbolLong
        \o message.askPriceLong
        \o message.askQuantityLong

DecodeLongAskUpdateMessage(bytes) ==
    LET symbolLong == ReadBytes(bytes, 6) IN IF ~symbolLong.ok THEN Fail ELSE
    LET askPriceLong == ReadBytes(symbolLong.rest, 10) IN IF ~askPriceLong.ok THEN Fail ELSE
    LET askQuantityLong == ReadBytes(askPriceLong.rest, 6) IN IF ~askQuantityLong.ok THEN Fail ELSE
    Ok([ symbolLong      |-> symbolLong.value,
         askPriceLong    |-> askPriceLong.value,
         askQuantityLong |-> askQuantityLong.value ], askQuantityLong.rest)

ZeroLongAskUpdateMessage ==
    [ symbolLong      |-> [i \in 1 .. 6 |-> 0],
      askPriceLong    |-> [i \in 1 .. 10 |-> 0],
      askQuantityLong |-> [i \in 1 .. 6 |-> 0] ]

(* Long Ask Update Message at zero, then each field in turn at the values it is checked at *)
CheckedLongAskUpdateMessage ==
    { ZeroLongAskUpdateMessage }
        \cup { [ZeroLongAskUpdateMessage EXCEPT !.symbolLong = one] : one \in Sample(6) }
        \cup { [ZeroLongAskUpdateMessage EXCEPT !.askPriceLong = one] : one \in Sample(10) }
        \cup { [ZeroLongAskUpdateMessage EXCEPT !.askQuantityLong = one] : one \in Sample(6) }

(***************************************************************************)
(* Short Ask Update Message: 14 bytes                                      *)
(***************************************************************************)

ShortAskUpdateMessage ==
    [ symbolShort      : Sample(4),
      askPriceShort    : Sample(5),
      askQuantityShort : Sample(5) ]

EncodeShortAskUpdateMessage(message) ==
    message.symbolShort
        \o message.askPriceShort
        \o message.askQuantityShort

DecodeShortAskUpdateMessage(bytes) ==
    LET symbolShort == ReadBytes(bytes, 4) IN IF ~symbolShort.ok THEN Fail ELSE
    LET askPriceShort == ReadBytes(symbolShort.rest, 5) IN IF ~askPriceShort.ok THEN Fail ELSE
    LET askQuantityShort == ReadBytes(askPriceShort.rest, 5) IN IF ~askQuantityShort.ok THEN Fail ELSE
    Ok([ symbolShort      |-> symbolShort.value,
         askPriceShort    |-> askPriceShort.value,
         askQuantityShort |-> askQuantityShort.value ], askQuantityShort.rest)

ZeroShortAskUpdateMessage ==
    [ symbolShort      |-> [i \in 1 .. 4 |-> 0],
      askPriceShort    |-> [i \in 1 .. 5 |-> 0],
      askQuantityShort |-> [i \in 1 .. 5 |-> 0] ]

(* Short Ask Update Message at zero, then each field in turn at the values it is checked at *)
CheckedShortAskUpdateMessage ==
    { ZeroShortAskUpdateMessage }
        \cup { [ZeroShortAskUpdateMessage EXCEPT !.symbolShort = one] : one \in Sample(4) }
        \cup { [ZeroShortAskUpdateMessage EXCEPT !.askPriceShort = one] : one \in Sample(5) }
        \cup { [ZeroShortAskUpdateMessage EXCEPT !.askQuantityShort = one] : one \in Sample(5) }

(***************************************************************************)
(* Extended Ask Update Message: 28 bytes                                   *)
(***************************************************************************)

ExtendedAskUpdateMessage ==
    [ symbolExtended   : Sample(8),
      askPriceExtended : Sample(14),
      askQuantityLong  : Sample(6) ]

EncodeExtendedAskUpdateMessage(message) ==
    message.symbolExtended
        \o message.askPriceExtended
        \o message.askQuantityLong

DecodeExtendedAskUpdateMessage(bytes) ==
    LET symbolExtended == ReadBytes(bytes, 8) IN IF ~symbolExtended.ok THEN Fail ELSE
    LET askPriceExtended == ReadBytes(symbolExtended.rest, 14) IN IF ~askPriceExtended.ok THEN Fail ELSE
    LET askQuantityLong == ReadBytes(askPriceExtended.rest, 6) IN IF ~askQuantityLong.ok THEN Fail ELSE
    Ok([ symbolExtended   |-> symbolExtended.value,
         askPriceExtended |-> askPriceExtended.value,
         askQuantityLong  |-> askQuantityLong.value ], askQuantityLong.rest)

ZeroExtendedAskUpdateMessage ==
    [ symbolExtended   |-> [i \in 1 .. 8 |-> 0],
      askPriceExtended |-> [i \in 1 .. 14 |-> 0],
      askQuantityLong  |-> [i \in 1 .. 6 |-> 0] ]

(* Extended Ask Update Message at zero, then each field in turn at the values it is checked at *)
CheckedExtendedAskUpdateMessage ==
    { ZeroExtendedAskUpdateMessage }
        \cup { [ZeroExtendedAskUpdateMessage EXCEPT !.symbolExtended = one] : one \in Sample(8) }
        \cup { [ZeroExtendedAskUpdateMessage EXCEPT !.askPriceExtended = one] : one \in Sample(14) }
        \cup { [ZeroExtendedAskUpdateMessage EXCEPT !.askQuantityLong = one] : one \in Sample(6) }

(***************************************************************************)
(* Expanded Two Sided Update Message: 40 bytes                             *)
(***************************************************************************)

ExpandedTwoSidedUpdateMessage ==
    [ symbolExtended  : Sample(8),
      bidPriceLong    : Sample(10),
      bidQuantityLong : Sample(6),
      askPriceLong    : Sample(10),
      askQuantityLong : Sample(6) ]

EncodeExpandedTwoSidedUpdateMessage(message) ==
    message.symbolExtended
        \o message.bidPriceLong
        \o message.bidQuantityLong
        \o message.askPriceLong
        \o message.askQuantityLong

DecodeExpandedTwoSidedUpdateMessage(bytes) ==
    LET symbolExtended == ReadBytes(bytes, 8) IN IF ~symbolExtended.ok THEN Fail ELSE
    LET bidPriceLong == ReadBytes(symbolExtended.rest, 10) IN IF ~bidPriceLong.ok THEN Fail ELSE
    LET bidQuantityLong == ReadBytes(bidPriceLong.rest, 6) IN IF ~bidQuantityLong.ok THEN Fail ELSE
    LET askPriceLong == ReadBytes(bidQuantityLong.rest, 10) IN IF ~askPriceLong.ok THEN Fail ELSE
    LET askQuantityLong == ReadBytes(askPriceLong.rest, 6) IN IF ~askQuantityLong.ok THEN Fail ELSE
    Ok([ symbolExtended  |-> symbolExtended.value,
         bidPriceLong    |-> bidPriceLong.value,
         bidQuantityLong |-> bidQuantityLong.value,
         askPriceLong    |-> askPriceLong.value,
         askQuantityLong |-> askQuantityLong.value ], askQuantityLong.rest)

ZeroExpandedTwoSidedUpdateMessage ==
    [ symbolExtended  |-> [i \in 1 .. 8 |-> 0],
      bidPriceLong    |-> [i \in 1 .. 10 |-> 0],
      bidQuantityLong |-> [i \in 1 .. 6 |-> 0],
      askPriceLong    |-> [i \in 1 .. 10 |-> 0],
      askQuantityLong |-> [i \in 1 .. 6 |-> 0] ]

(* Expanded Two Sided Update Message at zero, then each field in turn at the values it is checked at *)
CheckedExpandedTwoSidedUpdateMessage ==
    { ZeroExpandedTwoSidedUpdateMessage }
        \cup { [ZeroExpandedTwoSidedUpdateMessage EXCEPT !.symbolExtended = one] : one \in Sample(8) }
        \cup { [ZeroExpandedTwoSidedUpdateMessage EXCEPT !.bidPriceLong = one] : one \in Sample(10) }
        \cup { [ZeroExpandedTwoSidedUpdateMessage EXCEPT !.bidQuantityLong = one] : one \in Sample(6) }
        \cup { [ZeroExpandedTwoSidedUpdateMessage EXCEPT !.askPriceLong = one] : one \in Sample(10) }
        \cup { [ZeroExpandedTwoSidedUpdateMessage EXCEPT !.askQuantityLong = one] : one \in Sample(6) }

(***************************************************************************)
(* Long Two Sided Update Message: 38 bytes                                 *)
(***************************************************************************)

LongTwoSidedUpdateMessage ==
    [ symbolLong      : Sample(6),
      bidPriceLong    : Sample(10),
      bidQuantityLong : Sample(6),
      askPriceLong    : Sample(10),
      askQuantityLong : Sample(6) ]

EncodeLongTwoSidedUpdateMessage(message) ==
    message.symbolLong
        \o message.bidPriceLong
        \o message.bidQuantityLong
        \o message.askPriceLong
        \o message.askQuantityLong

DecodeLongTwoSidedUpdateMessage(bytes) ==
    LET symbolLong == ReadBytes(bytes, 6) IN IF ~symbolLong.ok THEN Fail ELSE
    LET bidPriceLong == ReadBytes(symbolLong.rest, 10) IN IF ~bidPriceLong.ok THEN Fail ELSE
    LET bidQuantityLong == ReadBytes(bidPriceLong.rest, 6) IN IF ~bidQuantityLong.ok THEN Fail ELSE
    LET askPriceLong == ReadBytes(bidQuantityLong.rest, 10) IN IF ~askPriceLong.ok THEN Fail ELSE
    LET askQuantityLong == ReadBytes(askPriceLong.rest, 6) IN IF ~askQuantityLong.ok THEN Fail ELSE
    Ok([ symbolLong      |-> symbolLong.value,
         bidPriceLong    |-> bidPriceLong.value,
         bidQuantityLong |-> bidQuantityLong.value,
         askPriceLong    |-> askPriceLong.value,
         askQuantityLong |-> askQuantityLong.value ], askQuantityLong.rest)

ZeroLongTwoSidedUpdateMessage ==
    [ symbolLong      |-> [i \in 1 .. 6 |-> 0],
      bidPriceLong    |-> [i \in 1 .. 10 |-> 0],
      bidQuantityLong |-> [i \in 1 .. 6 |-> 0],
      askPriceLong    |-> [i \in 1 .. 10 |-> 0],
      askQuantityLong |-> [i \in 1 .. 6 |-> 0] ]

(* Long Two Sided Update Message at zero, then each field in turn at the values it is checked at *)
CheckedLongTwoSidedUpdateMessage ==
    { ZeroLongTwoSidedUpdateMessage }
        \cup { [ZeroLongTwoSidedUpdateMessage EXCEPT !.symbolLong = one] : one \in Sample(6) }
        \cup { [ZeroLongTwoSidedUpdateMessage EXCEPT !.bidPriceLong = one] : one \in Sample(10) }
        \cup { [ZeroLongTwoSidedUpdateMessage EXCEPT !.bidQuantityLong = one] : one \in Sample(6) }
        \cup { [ZeroLongTwoSidedUpdateMessage EXCEPT !.askPriceLong = one] : one \in Sample(10) }
        \cup { [ZeroLongTwoSidedUpdateMessage EXCEPT !.askQuantityLong = one] : one \in Sample(6) }

(***************************************************************************)
(* Short Two Sided Update Message: 24 bytes                                *)
(***************************************************************************)

ShortTwoSidedUpdateMessage ==
    [ symbolShort      : Sample(4),
      bidPriceShort    : Sample(5),
      bidQuantityShort : Sample(5),
      askPriceShort    : Sample(5),
      askQuantityShort : Sample(5) ]

EncodeShortTwoSidedUpdateMessage(message) ==
    message.symbolShort
        \o message.bidPriceShort
        \o message.bidQuantityShort
        \o message.askPriceShort
        \o message.askQuantityShort

DecodeShortTwoSidedUpdateMessage(bytes) ==
    LET symbolShort == ReadBytes(bytes, 4) IN IF ~symbolShort.ok THEN Fail ELSE
    LET bidPriceShort == ReadBytes(symbolShort.rest, 5) IN IF ~bidPriceShort.ok THEN Fail ELSE
    LET bidQuantityShort == ReadBytes(bidPriceShort.rest, 5) IN IF ~bidQuantityShort.ok THEN Fail ELSE
    LET askPriceShort == ReadBytes(bidQuantityShort.rest, 5) IN IF ~askPriceShort.ok THEN Fail ELSE
    LET askQuantityShort == ReadBytes(askPriceShort.rest, 5) IN IF ~askQuantityShort.ok THEN Fail ELSE
    Ok([ symbolShort      |-> symbolShort.value,
         bidPriceShort    |-> bidPriceShort.value,
         bidQuantityShort |-> bidQuantityShort.value,
         askPriceShort    |-> askPriceShort.value,
         askQuantityShort |-> askQuantityShort.value ], askQuantityShort.rest)

ZeroShortTwoSidedUpdateMessage ==
    [ symbolShort      |-> [i \in 1 .. 4 |-> 0],
      bidPriceShort    |-> [i \in 1 .. 5 |-> 0],
      bidQuantityShort |-> [i \in 1 .. 5 |-> 0],
      askPriceShort    |-> [i \in 1 .. 5 |-> 0],
      askQuantityShort |-> [i \in 1 .. 5 |-> 0] ]

(* Short Two Sided Update Message at zero, then each field in turn at the values it is checked at *)
CheckedShortTwoSidedUpdateMessage ==
    { ZeroShortTwoSidedUpdateMessage }
        \cup { [ZeroShortTwoSidedUpdateMessage EXCEPT !.symbolShort = one] : one \in Sample(4) }
        \cup { [ZeroShortTwoSidedUpdateMessage EXCEPT !.bidPriceShort = one] : one \in Sample(5) }
        \cup { [ZeroShortTwoSidedUpdateMessage EXCEPT !.bidQuantityShort = one] : one \in Sample(5) }
        \cup { [ZeroShortTwoSidedUpdateMessage EXCEPT !.askPriceShort = one] : one \in Sample(5) }
        \cup { [ZeroShortTwoSidedUpdateMessage EXCEPT !.askQuantityShort = one] : one \in Sample(5) }

(***************************************************************************)
(* Extended Two Sided Update Message: 48 bytes                             *)
(***************************************************************************)

ExtendedTwoSidedUpdateMessage ==
    [ symbolExtended   : Sample(8),
      bidPriceExtended : Sample(14),
      bidQuantityLong  : Sample(6),
      askPriceExtended : Sample(14),
      askQuantityLong  : Sample(6) ]

EncodeExtendedTwoSidedUpdateMessage(message) ==
    message.symbolExtended
        \o message.bidPriceExtended
        \o message.bidQuantityLong
        \o message.askPriceExtended
        \o message.askQuantityLong

DecodeExtendedTwoSidedUpdateMessage(bytes) ==
    LET symbolExtended == ReadBytes(bytes, 8) IN IF ~symbolExtended.ok THEN Fail ELSE
    LET bidPriceExtended == ReadBytes(symbolExtended.rest, 14) IN IF ~bidPriceExtended.ok THEN Fail ELSE
    LET bidQuantityLong == ReadBytes(bidPriceExtended.rest, 6) IN IF ~bidQuantityLong.ok THEN Fail ELSE
    LET askPriceExtended == ReadBytes(bidQuantityLong.rest, 14) IN IF ~askPriceExtended.ok THEN Fail ELSE
    LET askQuantityLong == ReadBytes(askPriceExtended.rest, 6) IN IF ~askQuantityLong.ok THEN Fail ELSE
    Ok([ symbolExtended   |-> symbolExtended.value,
         bidPriceExtended |-> bidPriceExtended.value,
         bidQuantityLong  |-> bidQuantityLong.value,
         askPriceExtended |-> askPriceExtended.value,
         askQuantityLong  |-> askQuantityLong.value ], askQuantityLong.rest)

ZeroExtendedTwoSidedUpdateMessage ==
    [ symbolExtended   |-> [i \in 1 .. 8 |-> 0],
      bidPriceExtended |-> [i \in 1 .. 14 |-> 0],
      bidQuantityLong  |-> [i \in 1 .. 6 |-> 0],
      askPriceExtended |-> [i \in 1 .. 14 |-> 0],
      askQuantityLong  |-> [i \in 1 .. 6 |-> 0] ]

(* Extended Two Sided Update Message at zero, then each field in turn at the values it is checked at *)
CheckedExtendedTwoSidedUpdateMessage ==
    { ZeroExtendedTwoSidedUpdateMessage }
        \cup { [ZeroExtendedTwoSidedUpdateMessage EXCEPT !.symbolExtended = one] : one \in Sample(8) }
        \cup { [ZeroExtendedTwoSidedUpdateMessage EXCEPT !.bidPriceExtended = one] : one \in Sample(14) }
        \cup { [ZeroExtendedTwoSidedUpdateMessage EXCEPT !.bidQuantityLong = one] : one \in Sample(6) }
        \cup { [ZeroExtendedTwoSidedUpdateMessage EXCEPT !.askPriceExtended = one] : one \in Sample(14) }
        \cup { [ZeroExtendedTwoSidedUpdateMessage EXCEPT !.askQuantityLong = one] : one \in Sample(6) }

(***************************************************************************)
(* Expanded Trade Message: 33 bytes                                        *)
(***************************************************************************)

ExpandedTradeMessage ==
    [ symbolExtended       : Sample(8),
      lastPriceLong        : Sample(10),
      lastQuantityLong     : Sample(6),
      cumulativeVolumeLong : Sample(9) ]

EncodeExpandedTradeMessage(message) ==
    message.symbolExtended
        \o message.lastPriceLong
        \o message.lastQuantityLong
        \o message.cumulativeVolumeLong

DecodeExpandedTradeMessage(bytes) ==
    LET symbolExtended == ReadBytes(bytes, 8) IN IF ~symbolExtended.ok THEN Fail ELSE
    LET lastPriceLong == ReadBytes(symbolExtended.rest, 10) IN IF ~lastPriceLong.ok THEN Fail ELSE
    LET lastQuantityLong == ReadBytes(lastPriceLong.rest, 6) IN IF ~lastQuantityLong.ok THEN Fail ELSE
    LET cumulativeVolumeLong == ReadBytes(lastQuantityLong.rest, 9) IN IF ~cumulativeVolumeLong.ok THEN Fail ELSE
    Ok([ symbolExtended       |-> symbolExtended.value,
         lastPriceLong        |-> lastPriceLong.value,
         lastQuantityLong     |-> lastQuantityLong.value,
         cumulativeVolumeLong |-> cumulativeVolumeLong.value ], cumulativeVolumeLong.rest)

ZeroExpandedTradeMessage ==
    [ symbolExtended       |-> [i \in 1 .. 8 |-> 0],
      lastPriceLong        |-> [i \in 1 .. 10 |-> 0],
      lastQuantityLong     |-> [i \in 1 .. 6 |-> 0],
      cumulativeVolumeLong |-> [i \in 1 .. 9 |-> 0] ]

(* Expanded Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedExpandedTradeMessage ==
    { ZeroExpandedTradeMessage }
        \cup { [ZeroExpandedTradeMessage EXCEPT !.symbolExtended = one] : one \in Sample(8) }
        \cup { [ZeroExpandedTradeMessage EXCEPT !.lastPriceLong = one] : one \in Sample(10) }
        \cup { [ZeroExpandedTradeMessage EXCEPT !.lastQuantityLong = one] : one \in Sample(6) }
        \cup { [ZeroExpandedTradeMessage EXCEPT !.cumulativeVolumeLong = one] : one \in Sample(9) }

(***************************************************************************)
(* Long Trade Message: 31 bytes                                            *)
(***************************************************************************)

LongTradeMessage ==
    [ symbolLong           : Sample(6),
      lastPriceLong        : Sample(10),
      lastQuantityLong     : Sample(6),
      cumulativeVolumeLong : Sample(9) ]

EncodeLongTradeMessage(message) ==
    message.symbolLong
        \o message.lastPriceLong
        \o message.lastQuantityLong
        \o message.cumulativeVolumeLong

DecodeLongTradeMessage(bytes) ==
    LET symbolLong == ReadBytes(bytes, 6) IN IF ~symbolLong.ok THEN Fail ELSE
    LET lastPriceLong == ReadBytes(symbolLong.rest, 10) IN IF ~lastPriceLong.ok THEN Fail ELSE
    LET lastQuantityLong == ReadBytes(lastPriceLong.rest, 6) IN IF ~lastQuantityLong.ok THEN Fail ELSE
    LET cumulativeVolumeLong == ReadBytes(lastQuantityLong.rest, 9) IN IF ~cumulativeVolumeLong.ok THEN Fail ELSE
    Ok([ symbolLong           |-> symbolLong.value,
         lastPriceLong        |-> lastPriceLong.value,
         lastQuantityLong     |-> lastQuantityLong.value,
         cumulativeVolumeLong |-> cumulativeVolumeLong.value ], cumulativeVolumeLong.rest)

ZeroLongTradeMessage ==
    [ symbolLong           |-> [i \in 1 .. 6 |-> 0],
      lastPriceLong        |-> [i \in 1 .. 10 |-> 0],
      lastQuantityLong     |-> [i \in 1 .. 6 |-> 0],
      cumulativeVolumeLong |-> [i \in 1 .. 9 |-> 0] ]

(* Long Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedLongTradeMessage ==
    { ZeroLongTradeMessage }
        \cup { [ZeroLongTradeMessage EXCEPT !.symbolLong = one] : one \in Sample(6) }
        \cup { [ZeroLongTradeMessage EXCEPT !.lastPriceLong = one] : one \in Sample(10) }
        \cup { [ZeroLongTradeMessage EXCEPT !.lastQuantityLong = one] : one \in Sample(6) }
        \cup { [ZeroLongTradeMessage EXCEPT !.cumulativeVolumeLong = one] : one \in Sample(9) }

(***************************************************************************)
(* Short Trade Message: 21 bytes                                           *)
(***************************************************************************)

ShortTradeMessage ==
    [ symbolShort           : Sample(4),
      lastPriceShort        : Sample(5),
      lastQuantityShort     : Sample(5),
      cumulativeVolumeShort : Sample(7) ]

EncodeShortTradeMessage(message) ==
    message.symbolShort
        \o message.lastPriceShort
        \o message.lastQuantityShort
        \o message.cumulativeVolumeShort

DecodeShortTradeMessage(bytes) ==
    LET symbolShort == ReadBytes(bytes, 4) IN IF ~symbolShort.ok THEN Fail ELSE
    LET lastPriceShort == ReadBytes(symbolShort.rest, 5) IN IF ~lastPriceShort.ok THEN Fail ELSE
    LET lastQuantityShort == ReadBytes(lastPriceShort.rest, 5) IN IF ~lastQuantityShort.ok THEN Fail ELSE
    LET cumulativeVolumeShort == ReadBytes(lastQuantityShort.rest, 7) IN IF ~cumulativeVolumeShort.ok THEN Fail ELSE
    Ok([ symbolShort           |-> symbolShort.value,
         lastPriceShort        |-> lastPriceShort.value,
         lastQuantityShort     |-> lastQuantityShort.value,
         cumulativeVolumeShort |-> cumulativeVolumeShort.value ], cumulativeVolumeShort.rest)

ZeroShortTradeMessage ==
    [ symbolShort           |-> [i \in 1 .. 4 |-> 0],
      lastPriceShort        |-> [i \in 1 .. 5 |-> 0],
      lastQuantityShort     |-> [i \in 1 .. 5 |-> 0],
      cumulativeVolumeShort |-> [i \in 1 .. 7 |-> 0] ]

(* Short Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedShortTradeMessage ==
    { ZeroShortTradeMessage }
        \cup { [ZeroShortTradeMessage EXCEPT !.symbolShort = one] : one \in Sample(4) }
        \cup { [ZeroShortTradeMessage EXCEPT !.lastPriceShort = one] : one \in Sample(5) }
        \cup { [ZeroShortTradeMessage EXCEPT !.lastQuantityShort = one] : one \in Sample(5) }
        \cup { [ZeroShortTradeMessage EXCEPT !.cumulativeVolumeShort = one] : one \in Sample(7) }

(***************************************************************************)
(* Extended Trade Message: 37 bytes                                        *)
(***************************************************************************)

ExtendedTradeMessage ==
    [ symbolExtended       : Sample(8),
      lastPriceExtended    : Sample(14),
      lastQuantityLong     : Sample(6),
      cumulativeVolumeLong : Sample(9) ]

EncodeExtendedTradeMessage(message) ==
    message.symbolExtended
        \o message.lastPriceExtended
        \o message.lastQuantityLong
        \o message.cumulativeVolumeLong

DecodeExtendedTradeMessage(bytes) ==
    LET symbolExtended == ReadBytes(bytes, 8) IN IF ~symbolExtended.ok THEN Fail ELSE
    LET lastPriceExtended == ReadBytes(symbolExtended.rest, 14) IN IF ~lastPriceExtended.ok THEN Fail ELSE
    LET lastQuantityLong == ReadBytes(lastPriceExtended.rest, 6) IN IF ~lastQuantityLong.ok THEN Fail ELSE
    LET cumulativeVolumeLong == ReadBytes(lastQuantityLong.rest, 9) IN IF ~cumulativeVolumeLong.ok THEN Fail ELSE
    Ok([ symbolExtended       |-> symbolExtended.value,
         lastPriceExtended    |-> lastPriceExtended.value,
         lastQuantityLong     |-> lastQuantityLong.value,
         cumulativeVolumeLong |-> cumulativeVolumeLong.value ], cumulativeVolumeLong.rest)

ZeroExtendedTradeMessage ==
    [ symbolExtended       |-> [i \in 1 .. 8 |-> 0],
      lastPriceExtended    |-> [i \in 1 .. 14 |-> 0],
      lastQuantityLong     |-> [i \in 1 .. 6 |-> 0],
      cumulativeVolumeLong |-> [i \in 1 .. 9 |-> 0] ]

(* Extended Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedExtendedTradeMessage ==
    { ZeroExtendedTradeMessage }
        \cup { [ZeroExtendedTradeMessage EXCEPT !.symbolExtended = one] : one \in Sample(8) }
        \cup { [ZeroExtendedTradeMessage EXCEPT !.lastPriceExtended = one] : one \in Sample(14) }
        \cup { [ZeroExtendedTradeMessage EXCEPT !.lastQuantityLong = one] : one \in Sample(6) }
        \cup { [ZeroExtendedTradeMessage EXCEPT !.cumulativeVolumeLong = one] : one \in Sample(9) }

(***************************************************************************)
(* Trading Status Message: 12 bytes                                        *)
(***************************************************************************)

TradingStatusMessage ==
    [ symbolExtended : Sample(8),
      haltStatus     : Sample(1),
      regShoAction   : Sample(1),
      reserved1      : Sample(1),
      reserved2      : Sample(1) ]

EncodeTradingStatusMessage(message) ==
    message.symbolExtended
        \o message.haltStatus
        \o message.regShoAction
        \o message.reserved1
        \o message.reserved2

DecodeTradingStatusMessage(bytes) ==
    LET symbolExtended == ReadBytes(bytes, 8) IN IF ~symbolExtended.ok THEN Fail ELSE
    LET haltStatus == ReadBytes(symbolExtended.rest, 1) IN IF ~haltStatus.ok THEN Fail ELSE
    LET regShoAction == ReadBytes(haltStatus.rest, 1) IN IF ~regShoAction.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(regShoAction.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(reserved1.rest, 1) IN IF ~reserved2.ok THEN Fail ELSE
    Ok([ symbolExtended |-> symbolExtended.value,
         haltStatus     |-> haltStatus.value,
         regShoAction   |-> regShoAction.value,
         reserved1      |-> reserved1.value,
         reserved2      |-> reserved2.value ], reserved2.rest)

ZeroTradingStatusMessage ==
    [ symbolExtended |-> [i \in 1 .. 8 |-> 0],
      haltStatus     |-> [i \in 1 .. 1 |-> 0],
      regShoAction   |-> [i \in 1 .. 1 |-> 0],
      reserved1      |-> [i \in 1 .. 1 |-> 0],
      reserved2      |-> [i \in 1 .. 1 |-> 0] ]

(* Trading Status Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingStatusMessage ==
    { ZeroTradingStatusMessage }
        \cup { [ZeroTradingStatusMessage EXCEPT !.symbolExtended = one] : one \in Sample(8) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.haltStatus = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.regShoAction = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.reserved2 = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

LogonMessageCode == 76  \* "L"
LogonRejectedMessageCode == 74  \* "J"
SecondsMessageCode == 84  \* "T"
MillisecondsMessageCode == 77  \* "M"
LogonAcceptedMessageCode == 67  \* "C"
ExpandedSpinMessageCode == 115  \* "s"
ExtendedSpinMessageCode == 83  \* "S"
SpinDoneMessageCode == 68  \* "D"
ServerHeartbeatMessageCode == 72  \* "H"
ClientHeartbeatMessageCode == 82  \* "R"
ExpandedBidUpdateMessageCode == 69  \* "E"
LongBidUpdateMessageCode == 66  \* "B"
ShortBidUpdateMessageCode == 98  \* "b"
ExtendedBidUpdateMessageCode == 78  \* "N"
ExpandedAskUpdateMessageCode == 101  \* "e"
LongAskUpdateMessageCode == 65  \* "A"
ShortAskUpdateMessageCode == 97  \* "a"
ExtendedAskUpdateMessageCode == 110  \* "n"
ExpandedTwoSidedUpdateMessageCode == 70  \* "F"
LongTwoSidedUpdateMessageCode == 85  \* "U"
ShortTwoSidedUpdateMessageCode == 117  \* "u"
ExtendedTwoSidedUpdateMessageCode == 100  \* "d"
ExpandedTradeMessageCode == 102  \* "f"
LongTradeMessageCode == 86  \* "V"
ShortTradeMessageCode == 118  \* "v"
ExtendedTradeMessageCode == 114  \* "r"
TradingStatusMessageCode == 116  \* "t"

Payload ==
    [ tag : {LogonMessageCode}, body : LogonMessage ]
        \cup [ tag : {LogonRejectedMessageCode}, body : LogonRejectedMessage ]
        \cup [ tag : {SecondsMessageCode}, body : SecondsMessage ]
        \cup [ tag : {MillisecondsMessageCode}, body : MillisecondsMessage ]
        \cup [ tag : {LogonAcceptedMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ExpandedSpinMessageCode}, body : ExpandedSpinMessage ]
        \cup [ tag : {ExtendedSpinMessageCode}, body : ExtendedSpinMessage ]
        \cup [ tag : {SpinDoneMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ServerHeartbeatMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ClientHeartbeatMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ExpandedBidUpdateMessageCode}, body : ExpandedBidUpdateMessage ]
        \cup [ tag : {LongBidUpdateMessageCode}, body : LongBidUpdateMessage ]
        \cup [ tag : {ShortBidUpdateMessageCode}, body : ShortBidUpdateMessage ]
        \cup [ tag : {ExtendedBidUpdateMessageCode}, body : ExtendedBidUpdateMessage ]
        \cup [ tag : {ExpandedAskUpdateMessageCode}, body : ExpandedAskUpdateMessage ]
        \cup [ tag : {LongAskUpdateMessageCode}, body : LongAskUpdateMessage ]
        \cup [ tag : {ShortAskUpdateMessageCode}, body : ShortAskUpdateMessage ]
        \cup [ tag : {ExtendedAskUpdateMessageCode}, body : ExtendedAskUpdateMessage ]
        \cup [ tag : {ExpandedTwoSidedUpdateMessageCode}, body : ExpandedTwoSidedUpdateMessage ]
        \cup [ tag : {LongTwoSidedUpdateMessageCode}, body : LongTwoSidedUpdateMessage ]
        \cup [ tag : {ShortTwoSidedUpdateMessageCode}, body : ShortTwoSidedUpdateMessage ]
        \cup [ tag : {ExtendedTwoSidedUpdateMessageCode}, body : ExtendedTwoSidedUpdateMessage ]
        \cup [ tag : {ExpandedTradeMessageCode}, body : ExpandedTradeMessage ]
        \cup [ tag : {LongTradeMessageCode}, body : LongTradeMessage ]
        \cup [ tag : {ShortTradeMessageCode}, body : ShortTradeMessage ]
        \cup [ tag : {ExtendedTradeMessageCode}, body : ExtendedTradeMessage ]
        \cup [ tag : {TradingStatusMessageCode}, body : TradingStatusMessage ]

EncodePayload(message) ==
    CASE message.tag = LogonMessageCode -> EncodeLogonMessage(message.body)
      [] message.tag = LogonRejectedMessageCode -> EncodeLogonRejectedMessage(message.body)
      [] message.tag = SecondsMessageCode -> EncodeSecondsMessage(message.body)
      [] message.tag = MillisecondsMessageCode -> EncodeMillisecondsMessage(message.body)
      [] message.tag = LogonAcceptedMessageCode -> << >>
      [] message.tag = ExpandedSpinMessageCode -> EncodeExpandedSpinMessage(message.body)
      [] message.tag = ExtendedSpinMessageCode -> EncodeExtendedSpinMessage(message.body)
      [] message.tag = SpinDoneMessageCode -> << >>
      [] message.tag = ServerHeartbeatMessageCode -> << >>
      [] message.tag = ClientHeartbeatMessageCode -> << >>
      [] message.tag = ExpandedBidUpdateMessageCode -> EncodeExpandedBidUpdateMessage(message.body)
      [] message.tag = LongBidUpdateMessageCode -> EncodeLongBidUpdateMessage(message.body)
      [] message.tag = ShortBidUpdateMessageCode -> EncodeShortBidUpdateMessage(message.body)
      [] message.tag = ExtendedBidUpdateMessageCode -> EncodeExtendedBidUpdateMessage(message.body)
      [] message.tag = ExpandedAskUpdateMessageCode -> EncodeExpandedAskUpdateMessage(message.body)
      [] message.tag = LongAskUpdateMessageCode -> EncodeLongAskUpdateMessage(message.body)
      [] message.tag = ShortAskUpdateMessageCode -> EncodeShortAskUpdateMessage(message.body)
      [] message.tag = ExtendedAskUpdateMessageCode -> EncodeExtendedAskUpdateMessage(message.body)
      [] message.tag = ExpandedTwoSidedUpdateMessageCode -> EncodeExpandedTwoSidedUpdateMessage(message.body)
      [] message.tag = LongTwoSidedUpdateMessageCode -> EncodeLongTwoSidedUpdateMessage(message.body)
      [] message.tag = ShortTwoSidedUpdateMessageCode -> EncodeShortTwoSidedUpdateMessage(message.body)
      [] message.tag = ExtendedTwoSidedUpdateMessageCode -> EncodeExtendedTwoSidedUpdateMessage(message.body)
      [] message.tag = ExpandedTradeMessageCode -> EncodeExpandedTradeMessage(message.body)
      [] message.tag = LongTradeMessageCode -> EncodeLongTradeMessage(message.body)
      [] message.tag = ShortTradeMessageCode -> EncodeShortTradeMessage(message.body)
      [] message.tag = ExtendedTradeMessageCode -> EncodeExtendedTradeMessage(message.body)
      [] message.tag = TradingStatusMessageCode -> EncodeTradingStatusMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = LogonMessageCode -> DecodeLogonMessage(bytes)
              [] tag = LogonRejectedMessageCode -> DecodeLogonRejectedMessage(bytes)
              [] tag = SecondsMessageCode -> DecodeSecondsMessage(bytes)
              [] tag = MillisecondsMessageCode -> DecodeMillisecondsMessage(bytes)
              [] tag = LogonAcceptedMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = ExpandedSpinMessageCode -> DecodeExpandedSpinMessage(bytes)
              [] tag = ExtendedSpinMessageCode -> DecodeExtendedSpinMessage(bytes)
              [] tag = SpinDoneMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = ServerHeartbeatMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = ClientHeartbeatMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = ExpandedBidUpdateMessageCode -> DecodeExpandedBidUpdateMessage(bytes)
              [] tag = LongBidUpdateMessageCode -> DecodeLongBidUpdateMessage(bytes)
              [] tag = ShortBidUpdateMessageCode -> DecodeShortBidUpdateMessage(bytes)
              [] tag = ExtendedBidUpdateMessageCode -> DecodeExtendedBidUpdateMessage(bytes)
              [] tag = ExpandedAskUpdateMessageCode -> DecodeExpandedAskUpdateMessage(bytes)
              [] tag = LongAskUpdateMessageCode -> DecodeLongAskUpdateMessage(bytes)
              [] tag = ShortAskUpdateMessageCode -> DecodeShortAskUpdateMessage(bytes)
              [] tag = ExtendedAskUpdateMessageCode -> DecodeExtendedAskUpdateMessage(bytes)
              [] tag = ExpandedTwoSidedUpdateMessageCode -> DecodeExpandedTwoSidedUpdateMessage(bytes)
              [] tag = LongTwoSidedUpdateMessageCode -> DecodeLongTwoSidedUpdateMessage(bytes)
              [] tag = ShortTwoSidedUpdateMessageCode -> DecodeShortTwoSidedUpdateMessage(bytes)
              [] tag = ExtendedTwoSidedUpdateMessageCode -> DecodeExtendedTwoSidedUpdateMessage(bytes)
              [] tag = ExpandedTradeMessageCode -> DecodeExpandedTradeMessage(bytes)
              [] tag = LongTradeMessageCode -> DecodeLongTradeMessage(bytes)
              [] tag = ShortTradeMessageCode -> DecodeShortTradeMessage(bytes)
              [] tag = ExtendedTradeMessageCode -> DecodeExtendedTradeMessage(bytes)
              [] tag = TradingStatusMessageCode -> DecodeTradingStatusMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> LogonMessageCode, body |-> ZeroLogonMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> LogonMessageCode, body |-> one] : one \in CheckedLogonMessage }
        \cup { [tag |-> LogonRejectedMessageCode, body |-> one] : one \in CheckedLogonRejectedMessage }
        \cup { [tag |-> SecondsMessageCode, body |-> one] : one \in CheckedSecondsMessage }
        \cup { [tag |-> MillisecondsMessageCode, body |-> one] : one \in CheckedMillisecondsMessage }
        \cup { [tag |-> LogonAcceptedMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> ExpandedSpinMessageCode, body |-> one] : one \in CheckedExpandedSpinMessage }
        \cup { [tag |-> ExtendedSpinMessageCode, body |-> one] : one \in CheckedExtendedSpinMessage }
        \cup { [tag |-> SpinDoneMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> ServerHeartbeatMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> ClientHeartbeatMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> ExpandedBidUpdateMessageCode, body |-> one] : one \in CheckedExpandedBidUpdateMessage }
        \cup { [tag |-> LongBidUpdateMessageCode, body |-> one] : one \in CheckedLongBidUpdateMessage }
        \cup { [tag |-> ShortBidUpdateMessageCode, body |-> one] : one \in CheckedShortBidUpdateMessage }
        \cup { [tag |-> ExtendedBidUpdateMessageCode, body |-> one] : one \in CheckedExtendedBidUpdateMessage }
        \cup { [tag |-> ExpandedAskUpdateMessageCode, body |-> one] : one \in CheckedExpandedAskUpdateMessage }
        \cup { [tag |-> LongAskUpdateMessageCode, body |-> one] : one \in CheckedLongAskUpdateMessage }
        \cup { [tag |-> ShortAskUpdateMessageCode, body |-> one] : one \in CheckedShortAskUpdateMessage }
        \cup { [tag |-> ExtendedAskUpdateMessageCode, body |-> one] : one \in CheckedExtendedAskUpdateMessage }
        \cup { [tag |-> ExpandedTwoSidedUpdateMessageCode, body |-> one] : one \in CheckedExpandedTwoSidedUpdateMessage }
        \cup { [tag |-> LongTwoSidedUpdateMessageCode, body |-> one] : one \in CheckedLongTwoSidedUpdateMessage }
        \cup { [tag |-> ShortTwoSidedUpdateMessageCode, body |-> one] : one \in CheckedShortTwoSidedUpdateMessage }
        \cup { [tag |-> ExtendedTwoSidedUpdateMessageCode, body |-> one] : one \in CheckedExtendedTwoSidedUpdateMessage }
        \cup { [tag |-> ExpandedTradeMessageCode, body |-> one] : one \in CheckedExpandedTradeMessage }
        \cup { [tag |-> LongTradeMessageCode, body |-> one] : one \in CheckedLongTradeMessage }
        \cup { [tag |-> ShortTradeMessageCode, body |-> one] : one \in CheckedShortTradeMessage }
        \cup { [tag |-> ExtendedTradeMessageCode, body |-> one] : one \in CheckedExtendedTradeMessage }
        \cup { [tag |-> TradingStatusMessageCode, body |-> one] : one \in CheckedTradingStatusMessage }

(***************************************************************************)
(* Frame                                                                   *)
(***************************************************************************)

Frame ==
    [ payload : Payload,
      topLf   : Sample(1) ]

EncodeFrame(message) ==
    EncodeUIntBE(message.payload.tag, 1)
        \o EncodePayload(message.payload)
        \o message.topLf

DecodeFrame(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    LET topLf == ReadBytes(payload.rest, 1) IN IF ~topLf.ok THEN Fail ELSE
    Ok([ payload |-> payload.value,
         topLf   |-> topLf.value ], topLf.rest)

ZeroFrame ==
    [ payload |-> ZeroPayload,
      topLf   |-> [i \in 1 .. 1 |-> 0] ]

(* Frame at zero, then each field in turn at the values it is checked at *)
CheckedFrame ==
    { ZeroFrame }
        \cup { [ZeroFrame EXCEPT !.payload = one] : one \in CheckedPayload }
        \cup { [ZeroFrame EXCEPT !.topLf = one] : one \in Sample(1) }

(* A run of Frame, written one after another *)
RECURSIVE EncodeFrameList(_)
EncodeFrameList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeFrame(Head(messages)) \o EncodeFrameList(Tail(messages))

(* As many Frame as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadFrameAll(_)
ReadFrameAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeFrame(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadFrameAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Frame of each kind, for the lists that carry them *)
OneFrame ==
    { [ZeroFrame EXCEPT !.payload = [tag |-> LogonMessageCode, body |-> ZeroLogonMessage]],
      [ZeroFrame EXCEPT !.payload = [tag |-> LogonRejectedMessageCode, body |-> ZeroLogonRejectedMessage]],
      [ZeroFrame EXCEPT !.payload = [tag |-> SecondsMessageCode, body |-> ZeroSecondsMessage]],
      [ZeroFrame EXCEPT !.payload = [tag |-> MillisecondsMessageCode, body |-> ZeroMillisecondsMessage]],
      [ZeroFrame EXCEPT !.payload = [tag |-> LogonAcceptedMessageCode, body |-> [empty |-> 0]]],
      [ZeroFrame EXCEPT !.payload = [tag |-> ExpandedSpinMessageCode, body |-> ZeroExpandedSpinMessage]],
      [ZeroFrame EXCEPT !.payload = [tag |-> ExtendedSpinMessageCode, body |-> ZeroExtendedSpinMessage]],
      [ZeroFrame EXCEPT !.payload = [tag |-> SpinDoneMessageCode, body |-> [empty |-> 0]]],
      [ZeroFrame EXCEPT !.payload = [tag |-> ServerHeartbeatMessageCode, body |-> [empty |-> 0]]],
      [ZeroFrame EXCEPT !.payload = [tag |-> ClientHeartbeatMessageCode, body |-> [empty |-> 0]]],
      [ZeroFrame EXCEPT !.payload = [tag |-> ExpandedBidUpdateMessageCode, body |-> ZeroExpandedBidUpdateMessage]],
      [ZeroFrame EXCEPT !.payload = [tag |-> LongBidUpdateMessageCode, body |-> ZeroLongBidUpdateMessage]],
      [ZeroFrame EXCEPT !.payload = [tag |-> ShortBidUpdateMessageCode, body |-> ZeroShortBidUpdateMessage]],
      [ZeroFrame EXCEPT !.payload = [tag |-> ExtendedBidUpdateMessageCode, body |-> ZeroExtendedBidUpdateMessage]],
      [ZeroFrame EXCEPT !.payload = [tag |-> ExpandedAskUpdateMessageCode, body |-> ZeroExpandedAskUpdateMessage]],
      [ZeroFrame EXCEPT !.payload = [tag |-> LongAskUpdateMessageCode, body |-> ZeroLongAskUpdateMessage]],
      [ZeroFrame EXCEPT !.payload = [tag |-> ShortAskUpdateMessageCode, body |-> ZeroShortAskUpdateMessage]],
      [ZeroFrame EXCEPT !.payload = [tag |-> ExtendedAskUpdateMessageCode, body |-> ZeroExtendedAskUpdateMessage]],
      [ZeroFrame EXCEPT !.payload = [tag |-> ExpandedTwoSidedUpdateMessageCode, body |-> ZeroExpandedTwoSidedUpdateMessage]],
      [ZeroFrame EXCEPT !.payload = [tag |-> LongTwoSidedUpdateMessageCode, body |-> ZeroLongTwoSidedUpdateMessage]],
      [ZeroFrame EXCEPT !.payload = [tag |-> ShortTwoSidedUpdateMessageCode, body |-> ZeroShortTwoSidedUpdateMessage]],
      [ZeroFrame EXCEPT !.payload = [tag |-> ExtendedTwoSidedUpdateMessageCode, body |-> ZeroExtendedTwoSidedUpdateMessage]],
      [ZeroFrame EXCEPT !.payload = [tag |-> ExpandedTradeMessageCode, body |-> ZeroExpandedTradeMessage]],
      [ZeroFrame EXCEPT !.payload = [tag |-> LongTradeMessageCode, body |-> ZeroLongTradeMessage]],
      [ZeroFrame EXCEPT !.payload = [tag |-> ShortTradeMessageCode, body |-> ZeroShortTradeMessage]],
      [ZeroFrame EXCEPT !.payload = [tag |-> ExtendedTradeMessageCode, body |-> ZeroExtendedTradeMessage]],
      [ZeroFrame EXCEPT !.payload = [tag |-> TradingStatusMessageCode, body |-> ZeroTradingStatusMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ frame : SampleLists(OneFrame) ]

EncodePacket(message) ==
    EncodeFrameList(message.frame)

DecodePacket(bytes) ==
    LET frame == ReadFrameAll(bytes) IN IF ~frame.ok THEN Fail ELSE
    Ok([ frame |-> frame.value ], frame.rest)

ZeroPacket ==
    [ frame |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.frame = one] : one \in SampleLists(OneFrame) }

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

(* Every Logon Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogonMessage ==
    \A message \in CheckedLogonMessage :
        LET read == DecodeLogonMessage(EncodeLogonMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logon Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogonRejectedMessage ==
    \A message \in CheckedLogonRejectedMessage :
        LET read == DecodeLogonRejectedMessage(EncodeLogonRejectedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Seconds Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecondsMessage ==
    \A message \in CheckedSecondsMessage :
        LET read == DecodeSecondsMessage(EncodeSecondsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Milliseconds Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMillisecondsMessage ==
    \A message \in CheckedMillisecondsMessage :
        LET read == DecodeMillisecondsMessage(EncodeMillisecondsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Expanded Spin Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExpandedSpinMessage ==
    \A message \in CheckedExpandedSpinMessage :
        LET read == DecodeExpandedSpinMessage(EncodeExpandedSpinMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Extended Spin Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExtendedSpinMessage ==
    \A message \in CheckedExtendedSpinMessage :
        LET read == DecodeExtendedSpinMessage(EncodeExtendedSpinMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Expanded Bid Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExpandedBidUpdateMessage ==
    \A message \in CheckedExpandedBidUpdateMessage :
        LET read == DecodeExpandedBidUpdateMessage(EncodeExpandedBidUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Bid Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLongBidUpdateMessage ==
    \A message \in CheckedLongBidUpdateMessage :
        LET read == DecodeLongBidUpdateMessage(EncodeLongBidUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Short Bid Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripShortBidUpdateMessage ==
    \A message \in CheckedShortBidUpdateMessage :
        LET read == DecodeShortBidUpdateMessage(EncodeShortBidUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Extended Bid Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExtendedBidUpdateMessage ==
    \A message \in CheckedExtendedBidUpdateMessage :
        LET read == DecodeExtendedBidUpdateMessage(EncodeExtendedBidUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Expanded Ask Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExpandedAskUpdateMessage ==
    \A message \in CheckedExpandedAskUpdateMessage :
        LET read == DecodeExpandedAskUpdateMessage(EncodeExpandedAskUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Ask Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLongAskUpdateMessage ==
    \A message \in CheckedLongAskUpdateMessage :
        LET read == DecodeLongAskUpdateMessage(EncodeLongAskUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Short Ask Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripShortAskUpdateMessage ==
    \A message \in CheckedShortAskUpdateMessage :
        LET read == DecodeShortAskUpdateMessage(EncodeShortAskUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Extended Ask Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExtendedAskUpdateMessage ==
    \A message \in CheckedExtendedAskUpdateMessage :
        LET read == DecodeExtendedAskUpdateMessage(EncodeExtendedAskUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Expanded Two Sided Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExpandedTwoSidedUpdateMessage ==
    \A message \in CheckedExpandedTwoSidedUpdateMessage :
        LET read == DecodeExpandedTwoSidedUpdateMessage(EncodeExpandedTwoSidedUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Two Sided Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLongTwoSidedUpdateMessage ==
    \A message \in CheckedLongTwoSidedUpdateMessage :
        LET read == DecodeLongTwoSidedUpdateMessage(EncodeLongTwoSidedUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Short Two Sided Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripShortTwoSidedUpdateMessage ==
    \A message \in CheckedShortTwoSidedUpdateMessage :
        LET read == DecodeShortTwoSidedUpdateMessage(EncodeShortTwoSidedUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Extended Two Sided Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExtendedTwoSidedUpdateMessage ==
    \A message \in CheckedExtendedTwoSidedUpdateMessage :
        LET read == DecodeExtendedTwoSidedUpdateMessage(EncodeExtendedTwoSidedUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Expanded Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExpandedTradeMessage ==
    \A message \in CheckedExpandedTradeMessage :
        LET read == DecodeExpandedTradeMessage(EncodeExpandedTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLongTradeMessage ==
    \A message \in CheckedLongTradeMessage :
        LET read == DecodeLongTradeMessage(EncodeLongTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Short Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripShortTradeMessage ==
    \A message \in CheckedShortTradeMessage :
        LET read == DecodeShortTradeMessage(EncodeShortTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Extended Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExtendedTradeMessage ==
    \A message \in CheckedExtendedTradeMessage :
        LET read == DecodeExtendedTradeMessage(EncodeExtendedTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trading Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingStatusMessage ==
    \A message \in CheckedTradingStatusMessage :
        LET read == DecodeTradingStatusMessage(EncodeTradingStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Frame decodes back to what was encoded, and leaves nothing over *)
RoundTripFrame ==
    \A message \in CheckedFrame :
        LET read == DecodeFrame(EncodeFrame(message))
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
        LET sent == EncodePayload(message)
            read == DecodePayload(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
