------------- MODULE SixSwissExchange_Snapshot_v1_24_0_Server --------------
(***************************************************************************)
(* SIX Swiss Exchange SIX Swiss Exchange IMI Orderbook Snapshot Recovery   *)
(* Service v1.24.0                                                         *)
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
(* Note: Sequenced Data Packet fills what is left of the frame Packet      *)
(* Length states, which is what it is read from.                           *)
(*                                                                         *)
(* Note: a Server Soup Bin Tcp Packet that ends the session is the last of *)
(* its Server Packet: nothing may follow it.                               *)
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
(* Debug Packet                                                            *)
(***************************************************************************)

DebugPacket ==
    [ debugText : SampleBytes ]

EncodeDebugPacket(message) ==
    message.debugText

DecodeDebugPacket(bytes) ==
    LET debugText == Ok(bytes, << >>) IN IF ~debugText.ok THEN Fail ELSE
    Ok([ debugText |-> debugText.value ], debugText.rest)

ZeroDebugPacket ==
    [ debugText |-> << >> ]

(* Debug Packet at zero, then each field in turn at the values it is checked at *)
CheckedDebugPacket ==
    { ZeroDebugPacket }
        \cup { [ZeroDebugPacket EXCEPT !.debugText = one] : one \in SampleBytes }

(***************************************************************************)
(* Login Accepted Packet: 30 bytes                                         *)
(***************************************************************************)

LoginAcceptedPacket ==
    [ acceptedSession        : Sample(10),
      acceptedSequenceNumber : Sample(20) ]

EncodeLoginAcceptedPacket(message) ==
    message.acceptedSession
        \o message.acceptedSequenceNumber

DecodeLoginAcceptedPacket(bytes) ==
    LET acceptedSession == ReadBytes(bytes, 10) IN IF ~acceptedSession.ok THEN Fail ELSE
    LET acceptedSequenceNumber == ReadBytes(acceptedSession.rest, 20) IN IF ~acceptedSequenceNumber.ok THEN Fail ELSE
    Ok([ acceptedSession        |-> acceptedSession.value,
         acceptedSequenceNumber |-> acceptedSequenceNumber.value ], acceptedSequenceNumber.rest)

ZeroLoginAcceptedPacket ==
    [ acceptedSession        |-> [i \in 1 .. 10 |-> 0],
      acceptedSequenceNumber |-> [i \in 1 .. 20 |-> 0] ]

(* Login Accepted Packet at zero, then each field in turn at the values it is checked at *)
CheckedLoginAcceptedPacket ==
    { ZeroLoginAcceptedPacket }
        \cup { [ZeroLoginAcceptedPacket EXCEPT !.acceptedSession = one] : one \in Sample(10) }
        \cup { [ZeroLoginAcceptedPacket EXCEPT !.acceptedSequenceNumber = one] : one \in Sample(20) }

(***************************************************************************)
(* Login Rejected Packet: 1 bytes                                          *)
(***************************************************************************)

LoginRejectedPacket ==
    [ rejectReasonCode : Sample(1) ]

EncodeLoginRejectedPacket(message) ==
    message.rejectReasonCode

DecodeLoginRejectedPacket(bytes) ==
    LET rejectReasonCode == ReadBytes(bytes, 1) IN IF ~rejectReasonCode.ok THEN Fail ELSE
    Ok([ rejectReasonCode |-> rejectReasonCode.value ], rejectReasonCode.rest)

ZeroLoginRejectedPacket ==
    [ rejectReasonCode |-> [i \in 1 .. 1 |-> 0] ]

(* Login Rejected Packet at zero, then each field in turn at the values it is checked at *)
CheckedLoginRejectedPacket ==
    { ZeroLoginRejectedPacket }
        \cup { [ZeroLoginRejectedPacket EXCEPT !.rejectReasonCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Time Stamp Seconds Message: 4 bytes                                     *)
(***************************************************************************)

TimeStampSecondsMessage ==
    [ second : Sample(4) ]

EncodeTimeStampSecondsMessage(message) ==
    message.second

DecodeTimeStampSecondsMessage(bytes) ==
    LET second == ReadBytes(bytes, 4) IN IF ~second.ok THEN Fail ELSE
    Ok([ second |-> second.value ], second.rest)

ZeroTimeStampSecondsMessage ==
    [ second |-> [i \in 1 .. 4 |-> 0] ]

(* Time Stamp Seconds Message at zero, then each field in turn at the values it is checked at *)
CheckedTimeStampSecondsMessage ==
    { ZeroTimeStampSecondsMessage }
        \cup { [ZeroTimeStampSecondsMessage EXCEPT !.second = one] : one \in Sample(4) }

(***************************************************************************)
(* System Event Message: 17 bytes                                          *)
(***************************************************************************)

SystemEventMessage ==
    [ timestamp : Sample(4),
      group     : Sample(8),
      eventCode : Sample(1),
      orderbook : Sample(4) ]

EncodeSystemEventMessage(message) ==
    message.timestamp
        \o message.group
        \o message.eventCode
        \o message.orderbook

DecodeSystemEventMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 4) IN IF ~timestamp.ok THEN Fail ELSE
    LET group == ReadBytes(timestamp.rest, 8) IN IF ~group.ok THEN Fail ELSE
    LET eventCode == ReadBytes(group.rest, 1) IN IF ~eventCode.ok THEN Fail ELSE
    LET orderbook == ReadBytes(eventCode.rest, 4) IN IF ~orderbook.ok THEN Fail ELSE
    Ok([ timestamp |-> timestamp.value,
         group     |-> group.value,
         eventCode |-> eventCode.value,
         orderbook |-> orderbook.value ], orderbook.rest)

ZeroSystemEventMessage ==
    [ timestamp |-> [i \in 1 .. 4 |-> 0],
      group     |-> [i \in 1 .. 8 |-> 0],
      eventCode |-> [i \in 1 .. 1 |-> 0],
      orderbook |-> [i \in 1 .. 4 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.timestamp = one] : one \in Sample(4) }
        \cup { [ZeroSystemEventMessage EXCEPT !.group = one] : one \in Sample(8) }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventCode = one] : one \in Sample(1) }
        \cup { [ZeroSystemEventMessage EXCEPT !.orderbook = one] : one \in Sample(4) }

(***************************************************************************)
(* Quantity Tick Size Message: 16 bytes                                    *)
(***************************************************************************)

QuantityTickSizeMessage ==
    [ timestamp           : Sample(4),
      quantityTickTableId : Sample(4),
      quantityTickSize    : Sample(4),
      quantityStart       : Sample(4) ]

EncodeQuantityTickSizeMessage(message) ==
    message.timestamp
        \o message.quantityTickTableId
        \o message.quantityTickSize
        \o message.quantityStart

DecodeQuantityTickSizeMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 4) IN IF ~timestamp.ok THEN Fail ELSE
    LET quantityTickTableId == ReadBytes(timestamp.rest, 4) IN IF ~quantityTickTableId.ok THEN Fail ELSE
    LET quantityTickSize == ReadBytes(quantityTickTableId.rest, 4) IN IF ~quantityTickSize.ok THEN Fail ELSE
    LET quantityStart == ReadBytes(quantityTickSize.rest, 4) IN IF ~quantityStart.ok THEN Fail ELSE
    Ok([ timestamp           |-> timestamp.value,
         quantityTickTableId |-> quantityTickTableId.value,
         quantityTickSize    |-> quantityTickSize.value,
         quantityStart       |-> quantityStart.value ], quantityStart.rest)

ZeroQuantityTickSizeMessage ==
    [ timestamp           |-> [i \in 1 .. 4 |-> 0],
      quantityTickTableId |-> [i \in 1 .. 4 |-> 0],
      quantityTickSize    |-> [i \in 1 .. 4 |-> 0],
      quantityStart       |-> [i \in 1 .. 4 |-> 0] ]

(* Quantity Tick Size Message at zero, then each field in turn at the values it is checked at *)
CheckedQuantityTickSizeMessage ==
    { ZeroQuantityTickSizeMessage }
        \cup { [ZeroQuantityTickSizeMessage EXCEPT !.timestamp = one] : one \in Sample(4) }
        \cup { [ZeroQuantityTickSizeMessage EXCEPT !.quantityTickTableId = one] : one \in Sample(4) }
        \cup { [ZeroQuantityTickSizeMessage EXCEPT !.quantityTickSize = one] : one \in Sample(4) }
        \cup { [ZeroQuantityTickSizeMessage EXCEPT !.quantityStart = one] : one \in Sample(4) }

(***************************************************************************)
(* Price Tick Size Message: 16 bytes                                       *)
(***************************************************************************)

PriceTickSizeMessage ==
    [ timestamp        : Sample(4),
      priceTickTableId : Sample(4),
      priceTickSize    : Sample(4),
      priceStart       : Sample(4) ]

EncodePriceTickSizeMessage(message) ==
    message.timestamp
        \o message.priceTickTableId
        \o message.priceTickSize
        \o message.priceStart

DecodePriceTickSizeMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 4) IN IF ~timestamp.ok THEN Fail ELSE
    LET priceTickTableId == ReadBytes(timestamp.rest, 4) IN IF ~priceTickTableId.ok THEN Fail ELSE
    LET priceTickSize == ReadBytes(priceTickTableId.rest, 4) IN IF ~priceTickSize.ok THEN Fail ELSE
    LET priceStart == ReadBytes(priceTickSize.rest, 4) IN IF ~priceStart.ok THEN Fail ELSE
    Ok([ timestamp        |-> timestamp.value,
         priceTickTableId |-> priceTickTableId.value,
         priceTickSize    |-> priceTickSize.value,
         priceStart       |-> priceStart.value ], priceStart.rest)

ZeroPriceTickSizeMessage ==
    [ timestamp        |-> [i \in 1 .. 4 |-> 0],
      priceTickTableId |-> [i \in 1 .. 4 |-> 0],
      priceTickSize    |-> [i \in 1 .. 4 |-> 0],
      priceStart       |-> [i \in 1 .. 4 |-> 0] ]

(* Price Tick Size Message at zero, then each field in turn at the values it is checked at *)
CheckedPriceTickSizeMessage ==
    { ZeroPriceTickSizeMessage }
        \cup { [ZeroPriceTickSizeMessage EXCEPT !.timestamp = one] : one \in Sample(4) }
        \cup { [ZeroPriceTickSizeMessage EXCEPT !.priceTickTableId = one] : one \in Sample(4) }
        \cup { [ZeroPriceTickSizeMessage EXCEPT !.priceTickSize = one] : one \in Sample(4) }
        \cup { [ZeroPriceTickSizeMessage EXCEPT !.priceStart = one] : one \in Sample(4) }

(***************************************************************************)
(* Orderbook Directory Message: 68 bytes                                   *)
(***************************************************************************)

OrderbookDirectoryMessage ==
    [ timestamp           : Sample(4),
      orderbook           : Sample(4),
      priceType           : Sample(1),
      isin                : Sample(12),
      currency            : Sample(3),
      group               : Sample(8),
      minimumQuantity     : Sample(4),
      quantityTickTableId : Sample(4),
      priceTickTableId    : Sample(4),
      priceDecimals       : Sample(4),
      delistingDate       : Sample(4),
      delistingTime       : Sample(4),
      qodPriceDecimals    : Sample(4),
      securityExchange    : Sample(4),
      referenceExchange   : Sample(4) ]

EncodeOrderbookDirectoryMessage(message) ==
    message.timestamp
        \o message.orderbook
        \o message.priceType
        \o message.isin
        \o message.currency
        \o message.group
        \o message.minimumQuantity
        \o message.quantityTickTableId
        \o message.priceTickTableId
        \o message.priceDecimals
        \o message.delistingDate
        \o message.delistingTime
        \o message.qodPriceDecimals
        \o message.securityExchange
        \o message.referenceExchange

DecodeOrderbookDirectoryMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 4) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderbook == ReadBytes(timestamp.rest, 4) IN IF ~orderbook.ok THEN Fail ELSE
    LET priceType == ReadBytes(orderbook.rest, 1) IN IF ~priceType.ok THEN Fail ELSE
    LET isin == ReadBytes(priceType.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET currency == ReadBytes(isin.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET group == ReadBytes(currency.rest, 8) IN IF ~group.ok THEN Fail ELSE
    LET minimumQuantity == ReadBytes(group.rest, 4) IN IF ~minimumQuantity.ok THEN Fail ELSE
    LET quantityTickTableId == ReadBytes(minimumQuantity.rest, 4) IN IF ~quantityTickTableId.ok THEN Fail ELSE
    LET priceTickTableId == ReadBytes(quantityTickTableId.rest, 4) IN IF ~priceTickTableId.ok THEN Fail ELSE
    LET priceDecimals == ReadBytes(priceTickTableId.rest, 4) IN IF ~priceDecimals.ok THEN Fail ELSE
    LET delistingDate == ReadBytes(priceDecimals.rest, 4) IN IF ~delistingDate.ok THEN Fail ELSE
    LET delistingTime == ReadBytes(delistingDate.rest, 4) IN IF ~delistingTime.ok THEN Fail ELSE
    LET qodPriceDecimals == ReadBytes(delistingTime.rest, 4) IN IF ~qodPriceDecimals.ok THEN Fail ELSE
    LET securityExchange == ReadBytes(qodPriceDecimals.rest, 4) IN IF ~securityExchange.ok THEN Fail ELSE
    LET referenceExchange == ReadBytes(securityExchange.rest, 4) IN IF ~referenceExchange.ok THEN Fail ELSE
    Ok([ timestamp           |-> timestamp.value,
         orderbook           |-> orderbook.value,
         priceType           |-> priceType.value,
         isin                |-> isin.value,
         currency            |-> currency.value,
         group               |-> group.value,
         minimumQuantity     |-> minimumQuantity.value,
         quantityTickTableId |-> quantityTickTableId.value,
         priceTickTableId    |-> priceTickTableId.value,
         priceDecimals       |-> priceDecimals.value,
         delistingDate       |-> delistingDate.value,
         delistingTime       |-> delistingTime.value,
         qodPriceDecimals    |-> qodPriceDecimals.value,
         securityExchange    |-> securityExchange.value,
         referenceExchange   |-> referenceExchange.value ], referenceExchange.rest)

ZeroOrderbookDirectoryMessage ==
    [ timestamp           |-> [i \in 1 .. 4 |-> 0],
      orderbook           |-> [i \in 1 .. 4 |-> 0],
      priceType           |-> [i \in 1 .. 1 |-> 0],
      isin                |-> [i \in 1 .. 12 |-> 0],
      currency            |-> [i \in 1 .. 3 |-> 0],
      group               |-> [i \in 1 .. 8 |-> 0],
      minimumQuantity     |-> [i \in 1 .. 4 |-> 0],
      quantityTickTableId |-> [i \in 1 .. 4 |-> 0],
      priceTickTableId    |-> [i \in 1 .. 4 |-> 0],
      priceDecimals       |-> [i \in 1 .. 4 |-> 0],
      delistingDate       |-> [i \in 1 .. 4 |-> 0],
      delistingTime       |-> [i \in 1 .. 4 |-> 0],
      qodPriceDecimals    |-> [i \in 1 .. 4 |-> 0],
      securityExchange    |-> [i \in 1 .. 4 |-> 0],
      referenceExchange   |-> [i \in 1 .. 4 |-> 0] ]

(* Orderbook Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderbookDirectoryMessage ==
    { ZeroOrderbookDirectoryMessage }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.timestamp = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.orderbook = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.priceType = one] : one \in Sample(1) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.group = one] : one \in Sample(8) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.minimumQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.quantityTickTableId = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.priceTickTableId = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.priceDecimals = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.delistingDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.delistingTime = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.qodPriceDecimals = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.securityExchange = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.referenceExchange = one] : one \in Sample(4) }

(***************************************************************************)
(* Orderbook Trading Action Message: 10 bytes                              *)
(***************************************************************************)

OrderbookTradingActionMessage ==
    [ timestamp     : Sample(4),
      orderbook     : Sample(4),
      tradingState  : Sample(1),
      bookCondition : Sample(1) ]

EncodeOrderbookTradingActionMessage(message) ==
    message.timestamp
        \o message.orderbook
        \o message.tradingState
        \o message.bookCondition

DecodeOrderbookTradingActionMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 4) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderbook == ReadBytes(timestamp.rest, 4) IN IF ~orderbook.ok THEN Fail ELSE
    LET tradingState == ReadBytes(orderbook.rest, 1) IN IF ~tradingState.ok THEN Fail ELSE
    LET bookCondition == ReadBytes(tradingState.rest, 1) IN IF ~bookCondition.ok THEN Fail ELSE
    Ok([ timestamp     |-> timestamp.value,
         orderbook     |-> orderbook.value,
         tradingState  |-> tradingState.value,
         bookCondition |-> bookCondition.value ], bookCondition.rest)

ZeroOrderbookTradingActionMessage ==
    [ timestamp     |-> [i \in 1 .. 4 |-> 0],
      orderbook     |-> [i \in 1 .. 4 |-> 0],
      tradingState  |-> [i \in 1 .. 1 |-> 0],
      bookCondition |-> [i \in 1 .. 1 |-> 0] ]

(* Orderbook Trading Action Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderbookTradingActionMessage ==
    { ZeroOrderbookTradingActionMessage }
        \cup { [ZeroOrderbookTradingActionMessage EXCEPT !.timestamp = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookTradingActionMessage EXCEPT !.orderbook = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookTradingActionMessage EXCEPT !.tradingState = one] : one \in Sample(1) }
        \cup { [ZeroOrderbookTradingActionMessage EXCEPT !.bookCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Add Order Message: 25 bytes                                             *)
(***************************************************************************)

AddOrderMessage ==
    [ timestamp     : Sample(4),
      orderNumber   : Sample(8),
      orderVerb     : Sample(1),
      orderQuantity : Sample(4),
      orderbook     : Sample(4),
      orderPrice    : Sample(4) ]

EncodeAddOrderMessage(message) ==
    message.timestamp
        \o message.orderNumber
        \o message.orderVerb
        \o message.orderQuantity
        \o message.orderbook
        \o message.orderPrice

DecodeAddOrderMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 4) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(timestamp.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET orderVerb == ReadBytes(orderNumber.rest, 1) IN IF ~orderVerb.ok THEN Fail ELSE
    LET orderQuantity == ReadBytes(orderVerb.rest, 4) IN IF ~orderQuantity.ok THEN Fail ELSE
    LET orderbook == ReadBytes(orderQuantity.rest, 4) IN IF ~orderbook.ok THEN Fail ELSE
    LET orderPrice == ReadBytes(orderbook.rest, 4) IN IF ~orderPrice.ok THEN Fail ELSE
    Ok([ timestamp     |-> timestamp.value,
         orderNumber   |-> orderNumber.value,
         orderVerb     |-> orderVerb.value,
         orderQuantity |-> orderQuantity.value,
         orderbook     |-> orderbook.value,
         orderPrice    |-> orderPrice.value ], orderPrice.rest)

ZeroAddOrderMessage ==
    [ timestamp     |-> [i \in 1 .. 4 |-> 0],
      orderNumber   |-> [i \in 1 .. 8 |-> 0],
      orderVerb     |-> [i \in 1 .. 1 |-> 0],
      orderQuantity |-> [i \in 1 .. 4 |-> 0],
      orderbook     |-> [i \in 1 .. 4 |-> 0],
      orderPrice    |-> [i \in 1 .. 4 |-> 0] ]

(* Add Order Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderMessage ==
    { ZeroAddOrderMessage }
        \cup { [ZeroAddOrderMessage EXCEPT !.timestamp = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderVerb = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderQuantity = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderbook = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderPrice = one] : one \in Sample(4) }

(***************************************************************************)
(* Indicative Price Quantity Message: 29 bytes                             *)
(***************************************************************************)

IndicativePriceQuantityMessage ==
    [ timestamp                  : Sample(4),
      theoreticalOpeningQuantity : Sample(8),
      orderbook                  : Sample(4),
      bestBid                    : Sample(4),
      bestOffer                  : Sample(4),
      theoreticalOpeningPrice    : Sample(4),
      crossType                  : Sample(1) ]

EncodeIndicativePriceQuantityMessage(message) ==
    message.timestamp
        \o message.theoreticalOpeningQuantity
        \o message.orderbook
        \o message.bestBid
        \o message.bestOffer
        \o message.theoreticalOpeningPrice
        \o message.crossType

DecodeIndicativePriceQuantityMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 4) IN IF ~timestamp.ok THEN Fail ELSE
    LET theoreticalOpeningQuantity == ReadBytes(timestamp.rest, 8) IN IF ~theoreticalOpeningQuantity.ok THEN Fail ELSE
    LET orderbook == ReadBytes(theoreticalOpeningQuantity.rest, 4) IN IF ~orderbook.ok THEN Fail ELSE
    LET bestBid == ReadBytes(orderbook.rest, 4) IN IF ~bestBid.ok THEN Fail ELSE
    LET bestOffer == ReadBytes(bestBid.rest, 4) IN IF ~bestOffer.ok THEN Fail ELSE
    LET theoreticalOpeningPrice == ReadBytes(bestOffer.rest, 4) IN IF ~theoreticalOpeningPrice.ok THEN Fail ELSE
    LET crossType == ReadBytes(theoreticalOpeningPrice.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    Ok([ timestamp                  |-> timestamp.value,
         theoreticalOpeningQuantity |-> theoreticalOpeningQuantity.value,
         orderbook                  |-> orderbook.value,
         bestBid                    |-> bestBid.value,
         bestOffer                  |-> bestOffer.value,
         theoreticalOpeningPrice    |-> theoreticalOpeningPrice.value,
         crossType                  |-> crossType.value ], crossType.rest)

ZeroIndicativePriceQuantityMessage ==
    [ timestamp                  |-> [i \in 1 .. 4 |-> 0],
      theoreticalOpeningQuantity |-> [i \in 1 .. 8 |-> 0],
      orderbook                  |-> [i \in 1 .. 4 |-> 0],
      bestBid                    |-> [i \in 1 .. 4 |-> 0],
      bestOffer                  |-> [i \in 1 .. 4 |-> 0],
      theoreticalOpeningPrice    |-> [i \in 1 .. 4 |-> 0],
      crossType                  |-> [i \in 1 .. 1 |-> 0] ]

(* Indicative Price Quantity Message at zero, then each field in turn at the values it is checked at *)
CheckedIndicativePriceQuantityMessage ==
    { ZeroIndicativePriceQuantityMessage }
        \cup { [ZeroIndicativePriceQuantityMessage EXCEPT !.timestamp = one] : one \in Sample(4) }
        \cup { [ZeroIndicativePriceQuantityMessage EXCEPT !.theoreticalOpeningQuantity = one] : one \in Sample(8) }
        \cup { [ZeroIndicativePriceQuantityMessage EXCEPT !.orderbook = one] : one \in Sample(4) }
        \cup { [ZeroIndicativePriceQuantityMessage EXCEPT !.bestBid = one] : one \in Sample(4) }
        \cup { [ZeroIndicativePriceQuantityMessage EXCEPT !.bestOffer = one] : one \in Sample(4) }
        \cup { [ZeroIndicativePriceQuantityMessage EXCEPT !.theoreticalOpeningPrice = one] : one \in Sample(4) }
        \cup { [ZeroIndicativePriceQuantityMessage EXCEPT !.crossType = one] : one \in Sample(1) }

(***************************************************************************)
(* Glimpse Snapshot Message: 8 bytes                                       *)
(***************************************************************************)

GlimpseSnapshotMessage ==
    [ sequenceNumber : Sample(8) ]

EncodeGlimpseSnapshotMessage(message) ==
    message.sequenceNumber

DecodeGlimpseSnapshotMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    Ok([ sequenceNumber |-> sequenceNumber.value ], sequenceNumber.rest)

ZeroGlimpseSnapshotMessage ==
    [ sequenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Glimpse Snapshot Message at zero, then each field in turn at the values it is checked at *)
CheckedGlimpseSnapshotMessage ==
    { ZeroGlimpseSnapshotMessage }
        \cup { [ZeroGlimpseSnapshotMessage EXCEPT !.sequenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Sequenced Message, selected by Sequenced Message Type                   *)
(***************************************************************************)

TimeStampSecondsMessageCode == 84  \* "T"
SystemEventMessageCode == 83  \* "S"
QuantityTickSizeMessageCode == 77  \* "M"
PriceTickSizeMessageCode == 76  \* "L"
OrderbookDirectoryMessageCode == 82  \* "R"
OrderbookTradingActionMessageCode == 72  \* "H"
AddOrderMessageCode == 65  \* "A"
IndicativePriceQuantityMessageCode == 73  \* "I"
GlimpseSnapshotMessageCode == 71  \* "G"

SequencedMessage ==
    [ tag : {TimeStampSecondsMessageCode}, body : TimeStampSecondsMessage ]
        \cup [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {QuantityTickSizeMessageCode}, body : QuantityTickSizeMessage ]
        \cup [ tag : {PriceTickSizeMessageCode}, body : PriceTickSizeMessage ]
        \cup [ tag : {OrderbookDirectoryMessageCode}, body : OrderbookDirectoryMessage ]
        \cup [ tag : {OrderbookTradingActionMessageCode}, body : OrderbookTradingActionMessage ]
        \cup [ tag : {AddOrderMessageCode}, body : AddOrderMessage ]
        \cup [ tag : {IndicativePriceQuantityMessageCode}, body : IndicativePriceQuantityMessage ]
        \cup [ tag : {GlimpseSnapshotMessageCode}, body : GlimpseSnapshotMessage ]

EncodeSequencedMessage(message) ==
    CASE message.tag = TimeStampSecondsMessageCode -> EncodeTimeStampSecondsMessage(message.body)
      [] message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = QuantityTickSizeMessageCode -> EncodeQuantityTickSizeMessage(message.body)
      [] message.tag = PriceTickSizeMessageCode -> EncodePriceTickSizeMessage(message.body)
      [] message.tag = OrderbookDirectoryMessageCode -> EncodeOrderbookDirectoryMessage(message.body)
      [] message.tag = OrderbookTradingActionMessageCode -> EncodeOrderbookTradingActionMessage(message.body)
      [] message.tag = AddOrderMessageCode -> EncodeAddOrderMessage(message.body)
      [] message.tag = IndicativePriceQuantityMessageCode -> EncodeIndicativePriceQuantityMessage(message.body)
      [] message.tag = GlimpseSnapshotMessageCode -> EncodeGlimpseSnapshotMessage(message.body)

DecodeSequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = TimeStampSecondsMessageCode -> DecodeTimeStampSecondsMessage(bytes)
              [] tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = QuantityTickSizeMessageCode -> DecodeQuantityTickSizeMessage(bytes)
              [] tag = PriceTickSizeMessageCode -> DecodePriceTickSizeMessage(bytes)
              [] tag = OrderbookDirectoryMessageCode -> DecodeOrderbookDirectoryMessage(bytes)
              [] tag = OrderbookTradingActionMessageCode -> DecodeOrderbookTradingActionMessage(bytes)
              [] tag = AddOrderMessageCode -> DecodeAddOrderMessage(bytes)
              [] tag = IndicativePriceQuantityMessageCode -> DecodeIndicativePriceQuantityMessage(bytes)
              [] tag = GlimpseSnapshotMessageCode -> DecodeGlimpseSnapshotMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSequencedMessage == [tag |-> TimeStampSecondsMessageCode, body |-> ZeroTimeStampSecondsMessage]

(* Each Sequenced Message in turn, at the values the message it names is checked at *)
CheckedSequencedMessage ==
    { [tag |-> TimeStampSecondsMessageCode, body |-> one] : one \in CheckedTimeStampSecondsMessage }
        \cup { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> QuantityTickSizeMessageCode, body |-> one] : one \in CheckedQuantityTickSizeMessage }
        \cup { [tag |-> PriceTickSizeMessageCode, body |-> one] : one \in CheckedPriceTickSizeMessage }
        \cup { [tag |-> OrderbookDirectoryMessageCode, body |-> one] : one \in CheckedOrderbookDirectoryMessage }
        \cup { [tag |-> OrderbookTradingActionMessageCode, body |-> one] : one \in CheckedOrderbookTradingActionMessage }
        \cup { [tag |-> AddOrderMessageCode, body |-> one] : one \in CheckedAddOrderMessage }
        \cup { [tag |-> IndicativePriceQuantityMessageCode, body |-> one] : one \in CheckedIndicativePriceQuantityMessage }
        \cup { [tag |-> GlimpseSnapshotMessageCode, body |-> one] : one \in CheckedGlimpseSnapshotMessage }

(***************************************************************************)
(* Sequenced Data Packet                                                   *)
(***************************************************************************)

SequencedDataPacket ==
    [ sequencedMessage : SequencedMessage ]

EncodeSequencedDataPacket(message) ==
    EncodeUIntBE(message.sequencedMessage.tag, 1)
        \o EncodeSequencedMessage(message.sequencedMessage)

DecodeSequencedDataPacket(bytes) ==
    LET sequencedMessageType == ReadUIntBE(bytes, 1) IN IF ~sequencedMessageType.ok THEN Fail ELSE
    LET sequencedMessage == DecodeSequencedMessage(sequencedMessageType.value, sequencedMessageType.rest) IN IF ~sequencedMessage.ok THEN Fail ELSE
    Ok([ sequencedMessage |-> sequencedMessage.value ], sequencedMessage.rest)

ZeroSequencedDataPacket ==
    [ sequencedMessage |-> ZeroSequencedMessage ]

(* Sequenced Data Packet at zero, then each field in turn at the values it is checked at *)
CheckedSequencedDataPacket ==
    { ZeroSequencedDataPacket }
        \cup { [ZeroSequencedDataPacket EXCEPT !.sequencedMessage = one] : one \in CheckedSequencedMessage }

(***************************************************************************)
(* Server Payload, selected by Server Packet Type                          *)
(***************************************************************************)

DebugPacketCode == 43  \* "+"
LoginAcceptedPacketCode == 65  \* "A"
LoginRejectedPacketCode == 74  \* "J"
SequencedDataPacketCode == 83  \* "S"
ServerHeartbeatCode == 72  \* "H"
EndOfSessionCode == 90  \* "Z"

ServerPayload ==
    [ tag : {DebugPacketCode}, body : DebugPacket ]
        \cup [ tag : {LoginAcceptedPacketCode}, body : LoginAcceptedPacket ]
        \cup [ tag : {LoginRejectedPacketCode}, body : LoginRejectedPacket ]
        \cup [ tag : {SequencedDataPacketCode}, body : SequencedDataPacket ]
        \cup [ tag : {ServerHeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {EndOfSessionCode}, body : {[empty |-> 0]} ]

EncodeServerPayload(message) ==
    CASE message.tag = DebugPacketCode -> EncodeDebugPacket(message.body)
      [] message.tag = LoginAcceptedPacketCode -> EncodeLoginAcceptedPacket(message.body)
      [] message.tag = LoginRejectedPacketCode -> EncodeLoginRejectedPacket(message.body)
      [] message.tag = SequencedDataPacketCode -> EncodeSequencedDataPacket(message.body)
      [] message.tag = ServerHeartbeatCode -> << >>
      [] message.tag = EndOfSessionCode -> << >>

DecodeServerPayload(tag, bytes) ==
    LET read ==
            CASE tag = DebugPacketCode -> DecodeDebugPacket(bytes)
              [] tag = LoginAcceptedPacketCode -> DecodeLoginAcceptedPacket(bytes)
              [] tag = LoginRejectedPacketCode -> DecodeLoginRejectedPacket(bytes)
              [] tag = SequencedDataPacketCode -> DecodeSequencedDataPacket(bytes)
              [] tag = ServerHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = EndOfSessionCode -> Ok([empty |-> 0], bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroServerPayload == [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]

(* Each Server Payload in turn, at the values the message it names is checked at *)
CheckedServerPayload ==
    { [tag |-> DebugPacketCode, body |-> one] : one \in CheckedDebugPacket }
        \cup { [tag |-> LoginAcceptedPacketCode, body |-> one] : one \in CheckedLoginAcceptedPacket }
        \cup { [tag |-> LoginRejectedPacketCode, body |-> one] : one \in CheckedLoginRejectedPacket }
        \cup { [tag |-> SequencedDataPacketCode, body |-> one] : one \in CheckedSequencedDataPacket }
        \cup { [tag |-> ServerHeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> EndOfSessionCode, body |-> [empty |-> 0]] }

(***************************************************************************)
(* Server Soup Bin Tcp Packet, framed by Packet Length                     *)
(***************************************************************************)

ServerSoupBinTcpPacket ==
    [ serverPayload : ServerPayload ]

EncodeServerSoupBinTcpPacketBody(message) ==
    EncodeUIntBE(message.serverPayload.tag, 1)
        \o EncodeServerPayload(message.serverPayload)

(* Packet Length counts the bytes it frames, so it is written from them *)
EncodeServerSoupBinTcpPacket(message) ==
    LET body == EncodeServerSoupBinTcpPacketBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeServerSoupBinTcpPacketBody(bytes) ==
    LET serverPacketType == ReadUIntBE(bytes, 1) IN IF ~serverPacketType.ok THEN Fail ELSE
    LET serverPayload == DecodeServerPayload(serverPacketType.value, serverPacketType.rest) IN IF ~serverPayload.ok THEN Fail ELSE
    Ok([ serverPayload |-> serverPayload.value ], serverPayload.rest)

DecodeServerSoupBinTcpPacket(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeServerSoupBinTcpPacketBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroServerSoupBinTcpPacket ==
    [ serverPayload |-> ZeroServerPayload ]

(* Server Soup Bin Tcp Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerSoupBinTcpPacket ==
    { ZeroServerSoupBinTcpPacket }
        \cup { [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = one] : one \in CheckedServerPayload }

(* Does a Server Soup Bin Tcp Packet end the session? Nothing may follow one that does *)
EndsSessionServerSoupBinTcpPacket(message) == message.serverPayload.tag \in {EndOfSessionCode}

(* A run of Server Soup Bin Tcp Packet, written one after another *)
RECURSIVE EncodeServerSoupBinTcpPacketList(_)
EncodeServerSoupBinTcpPacketList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeServerSoupBinTcpPacket(Head(messages)) \o EncodeServerSoupBinTcpPacketList(Tail(messages))

(* As many Server Soup Bin Tcp Packet as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
(* Only the last of them may end the session, so one that does with bytes left fails *)
RECURSIVE ReadServerSoupBinTcpPacketAll(_)
ReadServerSoupBinTcpPacketAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeServerSoupBinTcpPacket(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE IF EndsSessionServerSoupBinTcpPacket(one.value) /\ one.rest # << >> THEN Fail
             ELSE LET more == ReadServerSoupBinTcpPacketAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Server Soup Bin Tcp Packet of each kind, for the lists that carry them *)
OneServerSoupBinTcpPacket ==
    { [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> LoginAcceptedPacketCode, body |-> ZeroLoginAcceptedPacket]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> LoginRejectedPacketCode, body |-> ZeroLoginRejectedPacket]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> SequencedDataPacketCode, body |-> ZeroSequencedDataPacket]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> ServerHeartbeatCode, body |-> [empty |-> 0]]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> EndOfSessionCode, body |-> [empty |-> 0]]] }

(* The runs of Server Soup Bin Tcp Packet checked: none, one, two of a kind and each kind followed by *)
(* another, keeping those in which only the last may end the session *)
SampleServerSoupBinTcpPacketLists ==
    { run \in SampleLists(OneServerSoupBinTcpPacket) \cup { <<one, other>> : one \in OneServerSoupBinTcpPacket, other \in OneServerSoupBinTcpPacket } :
          \A at \in 1 .. Len(run) - 1 : ~EndsSessionServerSoupBinTcpPacket(run[at]) }

(***************************************************************************)
(* Server Packet                                                           *)
(***************************************************************************)

ServerPacket ==
    [ serverSoupBinTcpPacket : SampleServerSoupBinTcpPacketLists ]

EncodeServerPacket(message) ==
    EncodeServerSoupBinTcpPacketList(message.serverSoupBinTcpPacket)

DecodeServerPacket(bytes) ==
    LET serverSoupBinTcpPacket == ReadServerSoupBinTcpPacketAll(bytes) IN IF ~serverSoupBinTcpPacket.ok THEN Fail ELSE
    Ok([ serverSoupBinTcpPacket |-> serverSoupBinTcpPacket.value ], serverSoupBinTcpPacket.rest)

ZeroServerPacket ==
    [ serverSoupBinTcpPacket |-> << >> ]

(* Server Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerPacket ==
    { ZeroServerPacket }
        \cup { [ZeroServerPacket EXCEPT !.serverSoupBinTcpPacket = one] : one \in SampleServerSoupBinTcpPacketLists }

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

(* Every Debug Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripDebugPacket ==
    \A message \in CheckedDebugPacket :
        LET read == DecodeDebugPacket(EncodeDebugPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Accepted Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginAcceptedPacket ==
    \A message \in CheckedLoginAcceptedPacket :
        LET read == DecodeLoginAcceptedPacket(EncodeLoginAcceptedPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Rejected Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRejectedPacket ==
    \A message \in CheckedLoginRejectedPacket :
        LET read == DecodeLoginRejectedPacket(EncodeLoginRejectedPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Time Stamp Seconds Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTimeStampSecondsMessage ==
    \A message \in CheckedTimeStampSecondsMessage :
        LET read == DecodeTimeStampSecondsMessage(EncodeTimeStampSecondsMessage(message))
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

(* Every Quantity Tick Size Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuantityTickSizeMessage ==
    \A message \in CheckedQuantityTickSizeMessage :
        LET read == DecodeQuantityTickSizeMessage(EncodeQuantityTickSizeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price Tick Size Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPriceTickSizeMessage ==
    \A message \in CheckedPriceTickSizeMessage :
        LET read == DecodePriceTickSizeMessage(EncodePriceTickSizeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Orderbook Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderbookDirectoryMessage ==
    \A message \in CheckedOrderbookDirectoryMessage :
        LET read == DecodeOrderbookDirectoryMessage(EncodeOrderbookDirectoryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Orderbook Trading Action Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderbookTradingActionMessage ==
    \A message \in CheckedOrderbookTradingActionMessage :
        LET read == DecodeOrderbookTradingActionMessage(EncodeOrderbookTradingActionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderMessage ==
    \A message \in CheckedAddOrderMessage :
        LET read == DecodeAddOrderMessage(EncodeAddOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Indicative Price Quantity Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIndicativePriceQuantityMessage ==
    \A message \in CheckedIndicativePriceQuantityMessage :
        LET read == DecodeIndicativePriceQuantityMessage(EncodeIndicativePriceQuantityMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Glimpse Snapshot Message decodes back to what was encoded, and leaves nothing over *)
RoundTripGlimpseSnapshotMessage ==
    \A message \in CheckedGlimpseSnapshotMessage :
        LET read == DecodeGlimpseSnapshotMessage(EncodeGlimpseSnapshotMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sequenced Data Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripSequencedDataPacket ==
    \A message \in CheckedSequencedDataPacket :
        LET read == DecodeSequencedDataPacket(EncodeSequencedDataPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Server Soup Bin Tcp Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripServerSoupBinTcpPacket ==
    \A message \in CheckedServerSoupBinTcpPacket :
        LET read == DecodeServerSoupBinTcpPacket(EncodeServerSoupBinTcpPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Server Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripServerPacket ==
    \A message \in CheckedServerPacket :
        LET read == DecodeServerPacket(EncodeServerPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Sequenced Message is selected by the Sequenced Message Type it is written under *)
SelectsSequencedMessage ==
    \A message \in CheckedSequencedMessage :
        LET sent == EncodeSequencedMessage(message)
            read == DecodeSequencedMessage(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Server Payload is selected by the Server Packet Type it is written under *)
SelectsServerPayload ==
    \A message \in CheckedServerPayload :
        LET sent == EncodeServerPayload(message)
            read == DecodeServerPayload(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* Packet Length is written from the bytes it frames *)
FramesServerSoupBinTcpPacket ==
    \A message \in CheckedServerSoupBinTcpPacket :
        LET bytes == EncodeServerSoupBinTcpPacket(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

(* A Server Soup Bin Tcp Packet that ends the session is the last of its Server Packet: a run with one after it does not decode *)
EndsSessionLastServerSoupBinTcpPacket ==
    \A last \in { one \in OneServerSoupBinTcpPacket : EndsSessionServerSoupBinTcpPacket(one) } :
        \A after \in OneServerSoupBinTcpPacket :
            ~ReadServerSoupBinTcpPacketAll(EncodeServerSoupBinTcpPacketList(<<last, after>>)).ok

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
