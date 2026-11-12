----------------- MODULE AixMarket_GeniumInet_v3_0_Server ------------------
(***************************************************************************)
(* Astana International Exchange Genium Inet v3.0                          *)
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
(* Order Book Directory Message: 129 bytes                                 *)
(***************************************************************************)

OrderBookDirectoryMessage ==
    [ nanoseconds                    : Sample(4),
      orderBookId                    : Sample(4),
      symbol                         : Sample(32),
      longName                       : Sample(32),
      isin                           : Sample(12),
      financialProduct               : Sample(1),
      tradingCurrency                : Sample(3),
      numberOfDecimalsInPrice        : Sample(2),
      numberOfDecimalsInNominalValue : Sample(2),
      oddLotSize                     : Sample(4),
      roundLotSize                   : Sample(4),
      blockLotSize                   : Sample(4),
      nominalValue                   : Sample(8),
      reserved1                      : Sample(1),
      underlyingOrderBookId          : Sample(4),
      strikePrice                    : Sample(4),
      expirationDate                 : Sample(4),
      numberOfDecimalsInStrikePrice  : Sample(2),
      putOrCall                      : Sample(1),
      rankingType                    : Sample(1) ]

EncodeOrderBookDirectoryMessage(message) ==
    message.nanoseconds
        \o message.orderBookId
        \o message.symbol
        \o message.longName
        \o message.isin
        \o message.financialProduct
        \o message.tradingCurrency
        \o message.numberOfDecimalsInPrice
        \o message.numberOfDecimalsInNominalValue
        \o message.oddLotSize
        \o message.roundLotSize
        \o message.blockLotSize
        \o message.nominalValue
        \o message.reserved1
        \o message.underlyingOrderBookId
        \o message.strikePrice
        \o message.expirationDate
        \o message.numberOfDecimalsInStrikePrice
        \o message.putOrCall
        \o message.rankingType

DecodeOrderBookDirectoryMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(nanoseconds.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET symbol == ReadBytes(orderBookId.rest, 32) IN IF ~symbol.ok THEN Fail ELSE
    LET longName == ReadBytes(symbol.rest, 32) IN IF ~longName.ok THEN Fail ELSE
    LET isin == ReadBytes(longName.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET financialProduct == ReadBytes(isin.rest, 1) IN IF ~financialProduct.ok THEN Fail ELSE
    LET tradingCurrency == ReadBytes(financialProduct.rest, 3) IN IF ~tradingCurrency.ok THEN Fail ELSE
    LET numberOfDecimalsInPrice == ReadBytes(tradingCurrency.rest, 2) IN IF ~numberOfDecimalsInPrice.ok THEN Fail ELSE
    LET numberOfDecimalsInNominalValue == ReadBytes(numberOfDecimalsInPrice.rest, 2) IN IF ~numberOfDecimalsInNominalValue.ok THEN Fail ELSE
    LET oddLotSize == ReadBytes(numberOfDecimalsInNominalValue.rest, 4) IN IF ~oddLotSize.ok THEN Fail ELSE
    LET roundLotSize == ReadBytes(oddLotSize.rest, 4) IN IF ~roundLotSize.ok THEN Fail ELSE
    LET blockLotSize == ReadBytes(roundLotSize.rest, 4) IN IF ~blockLotSize.ok THEN Fail ELSE
    LET nominalValue == ReadBytes(blockLotSize.rest, 8) IN IF ~nominalValue.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(nominalValue.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET underlyingOrderBookId == ReadBytes(reserved1.rest, 4) IN IF ~underlyingOrderBookId.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(underlyingOrderBookId.rest, 4) IN IF ~strikePrice.ok THEN Fail ELSE
    LET expirationDate == ReadBytes(strikePrice.rest, 4) IN IF ~expirationDate.ok THEN Fail ELSE
    LET numberOfDecimalsInStrikePrice == ReadBytes(expirationDate.rest, 2) IN IF ~numberOfDecimalsInStrikePrice.ok THEN Fail ELSE
    LET putOrCall == ReadBytes(numberOfDecimalsInStrikePrice.rest, 1) IN IF ~putOrCall.ok THEN Fail ELSE
    LET rankingType == ReadBytes(putOrCall.rest, 1) IN IF ~rankingType.ok THEN Fail ELSE
    Ok([ nanoseconds                    |-> nanoseconds.value,
         orderBookId                    |-> orderBookId.value,
         symbol                         |-> symbol.value,
         longName                       |-> longName.value,
         isin                           |-> isin.value,
         financialProduct               |-> financialProduct.value,
         tradingCurrency                |-> tradingCurrency.value,
         numberOfDecimalsInPrice        |-> numberOfDecimalsInPrice.value,
         numberOfDecimalsInNominalValue |-> numberOfDecimalsInNominalValue.value,
         oddLotSize                     |-> oddLotSize.value,
         roundLotSize                   |-> roundLotSize.value,
         blockLotSize                   |-> blockLotSize.value,
         nominalValue                   |-> nominalValue.value,
         reserved1                      |-> reserved1.value,
         underlyingOrderBookId          |-> underlyingOrderBookId.value,
         strikePrice                    |-> strikePrice.value,
         expirationDate                 |-> expirationDate.value,
         numberOfDecimalsInStrikePrice  |-> numberOfDecimalsInStrikePrice.value,
         putOrCall                      |-> putOrCall.value,
         rankingType                    |-> rankingType.value ], rankingType.rest)

ZeroOrderBookDirectoryMessage ==
    [ nanoseconds                    |-> [i \in 1 .. 4 |-> 0],
      orderBookId                    |-> [i \in 1 .. 4 |-> 0],
      symbol                         |-> [i \in 1 .. 32 |-> 0],
      longName                       |-> [i \in 1 .. 32 |-> 0],
      isin                           |-> [i \in 1 .. 12 |-> 0],
      financialProduct               |-> [i \in 1 .. 1 |-> 0],
      tradingCurrency                |-> [i \in 1 .. 3 |-> 0],
      numberOfDecimalsInPrice        |-> [i \in 1 .. 2 |-> 0],
      numberOfDecimalsInNominalValue |-> [i \in 1 .. 2 |-> 0],
      oddLotSize                     |-> [i \in 1 .. 4 |-> 0],
      roundLotSize                   |-> [i \in 1 .. 4 |-> 0],
      blockLotSize                   |-> [i \in 1 .. 4 |-> 0],
      nominalValue                   |-> [i \in 1 .. 8 |-> 0],
      reserved1                      |-> [i \in 1 .. 1 |-> 0],
      underlyingOrderBookId          |-> [i \in 1 .. 4 |-> 0],
      strikePrice                    |-> [i \in 1 .. 4 |-> 0],
      expirationDate                 |-> [i \in 1 .. 4 |-> 0],
      numberOfDecimalsInStrikePrice  |-> [i \in 1 .. 2 |-> 0],
      putOrCall                      |-> [i \in 1 .. 1 |-> 0],
      rankingType                    |-> [i \in 1 .. 1 |-> 0] ]

(* Order Book Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderBookDirectoryMessage ==
    { ZeroOrderBookDirectoryMessage }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.symbol = one] : one \in Sample(32) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.longName = one] : one \in Sample(32) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.financialProduct = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.tradingCurrency = one] : one \in Sample(3) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.numberOfDecimalsInPrice = one] : one \in Sample(2) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.numberOfDecimalsInNominalValue = one] : one \in Sample(2) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.oddLotSize = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.roundLotSize = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.blockLotSize = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.nominalValue = one] : one \in Sample(8) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.underlyingOrderBookId = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.expirationDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.numberOfDecimalsInStrikePrice = one] : one \in Sample(2) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.putOrCall = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.rankingType = one] : one \in Sample(1) }

(***************************************************************************)
(* Tick Size Table Entry Message: 24 bytes                                 *)
(***************************************************************************)

TickSizeTableEntryMessage ==
    [ nanoseconds : Sample(4),
      orderBookId : Sample(4),
      tickSize    : Sample(8),
      priceFrom   : Sample(4),
      priceTo     : Sample(4) ]

EncodeTickSizeTableEntryMessage(message) ==
    message.nanoseconds
        \o message.orderBookId
        \o message.tickSize
        \o message.priceFrom
        \o message.priceTo

DecodeTickSizeTableEntryMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(nanoseconds.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET tickSize == ReadBytes(orderBookId.rest, 8) IN IF ~tickSize.ok THEN Fail ELSE
    LET priceFrom == ReadBytes(tickSize.rest, 4) IN IF ~priceFrom.ok THEN Fail ELSE
    LET priceTo == ReadBytes(priceFrom.rest, 4) IN IF ~priceTo.ok THEN Fail ELSE
    Ok([ nanoseconds |-> nanoseconds.value,
         orderBookId |-> orderBookId.value,
         tickSize    |-> tickSize.value,
         priceFrom   |-> priceFrom.value,
         priceTo     |-> priceTo.value ], priceTo.rest)

ZeroTickSizeTableEntryMessage ==
    [ nanoseconds |-> [i \in 1 .. 4 |-> 0],
      orderBookId |-> [i \in 1 .. 4 |-> 0],
      tickSize    |-> [i \in 1 .. 8 |-> 0],
      priceFrom   |-> [i \in 1 .. 4 |-> 0],
      priceTo     |-> [i \in 1 .. 4 |-> 0] ]

(* Tick Size Table Entry Message at zero, then each field in turn at the values it is checked at *)
CheckedTickSizeTableEntryMessage ==
    { ZeroTickSizeTableEntryMessage }
        \cup { [ZeroTickSizeTableEntryMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroTickSizeTableEntryMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroTickSizeTableEntryMessage EXCEPT !.tickSize = one] : one \in Sample(8) }
        \cup { [ZeroTickSizeTableEntryMessage EXCEPT !.priceFrom = one] : one \in Sample(4) }
        \cup { [ZeroTickSizeTableEntryMessage EXCEPT !.priceTo = one] : one \in Sample(4) }

(***************************************************************************)
(* Short Sell Status Message: 9 bytes                                      *)
(***************************************************************************)

ShortSellStatusMessage ==
    [ nanoseconds          : Sample(4),
      orderBookId          : Sample(4),
      shortSaleRestriction : Sample(1) ]

EncodeShortSellStatusMessage(message) ==
    message.nanoseconds
        \o message.orderBookId
        \o message.shortSaleRestriction

DecodeShortSellStatusMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(nanoseconds.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET shortSaleRestriction == ReadBytes(orderBookId.rest, 1) IN IF ~shortSaleRestriction.ok THEN Fail ELSE
    Ok([ nanoseconds          |-> nanoseconds.value,
         orderBookId          |-> orderBookId.value,
         shortSaleRestriction |-> shortSaleRestriction.value ], shortSaleRestriction.rest)

ZeroShortSellStatusMessage ==
    [ nanoseconds          |-> [i \in 1 .. 4 |-> 0],
      orderBookId          |-> [i \in 1 .. 4 |-> 0],
      shortSaleRestriction |-> [i \in 1 .. 1 |-> 0] ]

(* Short Sell Status Message at zero, then each field in turn at the values it is checked at *)
CheckedShortSellStatusMessage ==
    { ZeroShortSellStatusMessage }
        \cup { [ZeroShortSellStatusMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroShortSellStatusMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroShortSellStatusMessage EXCEPT !.shortSaleRestriction = one] : one \in Sample(1) }

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
(* Order Book State Message: 28 bytes                                      *)
(***************************************************************************)

OrderBookStateMessage ==
    [ nanoseconds : Sample(4),
      orderBookId : Sample(4),
      stateName   : Sample(20) ]

EncodeOrderBookStateMessage(message) ==
    message.nanoseconds
        \o message.orderBookId
        \o message.stateName

DecodeOrderBookStateMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(nanoseconds.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET stateName == ReadBytes(orderBookId.rest, 20) IN IF ~stateName.ok THEN Fail ELSE
    Ok([ nanoseconds |-> nanoseconds.value,
         orderBookId |-> orderBookId.value,
         stateName   |-> stateName.value ], stateName.rest)

ZeroOrderBookStateMessage ==
    [ nanoseconds |-> [i \in 1 .. 4 |-> 0],
      orderBookId |-> [i \in 1 .. 4 |-> 0],
      stateName   |-> [i \in 1 .. 20 |-> 0] ]

(* Order Book State Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderBookStateMessage ==
    { ZeroOrderBookStateMessage }
        \cup { [ZeroOrderBookStateMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookStateMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookStateMessage EXCEPT !.stateName = one] : one \in Sample(20) }

(***************************************************************************)
(* Add Order Message: 44 bytes                                             *)
(***************************************************************************)

AddOrderMessage ==
    [ nanoseconds           : Sample(4),
      orderId               : Sample(8),
      orderBookId           : Sample(4),
      side                  : Sample(1),
      rankingSequenceNumber : Sample(4),
      quantity              : Sample(8),
      price                 : Sample(4),
      orderAttributes       : Sample(2),
      lotType               : Sample(1),
      rankingTime           : Sample(8) ]

EncodeAddOrderMessage(message) ==
    message.nanoseconds
        \o message.orderId
        \o message.orderBookId
        \o message.side
        \o message.rankingSequenceNumber
        \o message.quantity
        \o message.price
        \o message.orderAttributes
        \o message.lotType
        \o message.rankingTime

DecodeAddOrderMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderId == ReadBytes(nanoseconds.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(orderId.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET side == ReadBytes(orderBookId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET rankingSequenceNumber == ReadBytes(side.rest, 4) IN IF ~rankingSequenceNumber.ok THEN Fail ELSE
    LET quantity == ReadBytes(rankingSequenceNumber.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET orderAttributes == ReadBytes(price.rest, 2) IN IF ~orderAttributes.ok THEN Fail ELSE
    LET lotType == ReadBytes(orderAttributes.rest, 1) IN IF ~lotType.ok THEN Fail ELSE
    LET rankingTime == ReadBytes(lotType.rest, 8) IN IF ~rankingTime.ok THEN Fail ELSE
    Ok([ nanoseconds           |-> nanoseconds.value,
         orderId               |-> orderId.value,
         orderBookId           |-> orderBookId.value,
         side                  |-> side.value,
         rankingSequenceNumber |-> rankingSequenceNumber.value,
         quantity              |-> quantity.value,
         price                 |-> price.value,
         orderAttributes       |-> orderAttributes.value,
         lotType               |-> lotType.value,
         rankingTime           |-> rankingTime.value ], rankingTime.rest)

ZeroAddOrderMessage ==
    [ nanoseconds           |-> [i \in 1 .. 4 |-> 0],
      orderId               |-> [i \in 1 .. 8 |-> 0],
      orderBookId           |-> [i \in 1 .. 4 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      rankingSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      quantity              |-> [i \in 1 .. 8 |-> 0],
      price                 |-> [i \in 1 .. 4 |-> 0],
      orderAttributes       |-> [i \in 1 .. 2 |-> 0],
      lotType               |-> [i \in 1 .. 1 |-> 0],
      rankingTime           |-> [i \in 1 .. 8 |-> 0] ]

(* Add Order Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderMessage ==
    { ZeroAddOrderMessage }
        \cup { [ZeroAddOrderMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.rankingSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderAttributes = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderMessage EXCEPT !.lotType = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.rankingTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Executed Message: 51 bytes                                        *)
(***************************************************************************)

OrderExecutedMessage ==
    [ nanoseconds      : Sample(4),
      orderId          : Sample(8),
      orderBookId      : Sample(4),
      side             : Sample(1),
      executedQuantity : Sample(8),
      matchId          : Sample(8),
      reserved4        : Sample(4),
      reserved14       : Sample(14) ]

EncodeOrderExecutedMessage(message) ==
    message.nanoseconds
        \o message.orderId
        \o message.orderBookId
        \o message.side
        \o message.executedQuantity
        \o message.matchId
        \o message.reserved4
        \o message.reserved14

DecodeOrderExecutedMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderId == ReadBytes(nanoseconds.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(orderId.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET side == ReadBytes(orderBookId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(side.rest, 8) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET matchId == ReadBytes(executedQuantity.rest, 8) IN IF ~matchId.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(matchId.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET reserved14 == ReadBytes(reserved4.rest, 14) IN IF ~reserved14.ok THEN Fail ELSE
    Ok([ nanoseconds      |-> nanoseconds.value,
         orderId          |-> orderId.value,
         orderBookId      |-> orderBookId.value,
         side             |-> side.value,
         executedQuantity |-> executedQuantity.value,
         matchId          |-> matchId.value,
         reserved4        |-> reserved4.value,
         reserved14       |-> reserved14.value ], reserved14.rest)

ZeroOrderExecutedMessage ==
    [ nanoseconds      |-> [i \in 1 .. 4 |-> 0],
      orderId          |-> [i \in 1 .. 8 |-> 0],
      orderBookId      |-> [i \in 1 .. 4 |-> 0],
      side             |-> [i \in 1 .. 1 |-> 0],
      executedQuantity |-> [i \in 1 .. 8 |-> 0],
      matchId          |-> [i \in 1 .. 8 |-> 0],
      reserved4        |-> [i \in 1 .. 4 |-> 0],
      reserved14       |-> [i \in 1 .. 14 |-> 0] ]

(* Order Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedMessage ==
    { ZeroOrderExecutedMessage }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.executedQuantity = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.matchId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.reserved14 = one] : one \in Sample(14) }

(***************************************************************************)
(* Order Executed With Price Message: 57 bytes                             *)
(***************************************************************************)

OrderExecutedWithPriceMessage ==
    [ nanoseconds      : Sample(4),
      orderId          : Sample(8),
      orderBookId      : Sample(4),
      side             : Sample(1),
      executedQuantity : Sample(8),
      matchId          : Sample(8),
      reserved18       : Sample(18),
      tradePrice       : Sample(4),
      occurredAtCross  : Sample(1),
      printable        : Sample(1) ]

EncodeOrderExecutedWithPriceMessage(message) ==
    message.nanoseconds
        \o message.orderId
        \o message.orderBookId
        \o message.side
        \o message.executedQuantity
        \o message.matchId
        \o message.reserved18
        \o message.tradePrice
        \o message.occurredAtCross
        \o message.printable

DecodeOrderExecutedWithPriceMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderId == ReadBytes(nanoseconds.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(orderId.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET side == ReadBytes(orderBookId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(side.rest, 8) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET matchId == ReadBytes(executedQuantity.rest, 8) IN IF ~matchId.ok THEN Fail ELSE
    LET reserved18 == ReadBytes(matchId.rest, 18) IN IF ~reserved18.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(reserved18.rest, 4) IN IF ~tradePrice.ok THEN Fail ELSE
    LET occurredAtCross == ReadBytes(tradePrice.rest, 1) IN IF ~occurredAtCross.ok THEN Fail ELSE
    LET printable == ReadBytes(occurredAtCross.rest, 1) IN IF ~printable.ok THEN Fail ELSE
    Ok([ nanoseconds      |-> nanoseconds.value,
         orderId          |-> orderId.value,
         orderBookId      |-> orderBookId.value,
         side             |-> side.value,
         executedQuantity |-> executedQuantity.value,
         matchId          |-> matchId.value,
         reserved18       |-> reserved18.value,
         tradePrice       |-> tradePrice.value,
         occurredAtCross  |-> occurredAtCross.value,
         printable        |-> printable.value ], printable.rest)

ZeroOrderExecutedWithPriceMessage ==
    [ nanoseconds      |-> [i \in 1 .. 4 |-> 0],
      orderId          |-> [i \in 1 .. 8 |-> 0],
      orderBookId      |-> [i \in 1 .. 4 |-> 0],
      side             |-> [i \in 1 .. 1 |-> 0],
      executedQuantity |-> [i \in 1 .. 8 |-> 0],
      matchId          |-> [i \in 1 .. 8 |-> 0],
      reserved18       |-> [i \in 1 .. 18 |-> 0],
      tradePrice       |-> [i \in 1 .. 4 |-> 0],
      occurredAtCross  |-> [i \in 1 .. 1 |-> 0],
      printable        |-> [i \in 1 .. 1 |-> 0] ]

(* Order Executed With Price Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedWithPriceMessage ==
    { ZeroOrderExecutedWithPriceMessage }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.executedQuantity = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.matchId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.reserved18 = one] : one \in Sample(18) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.tradePrice = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.occurredAtCross = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.printable = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Delete Message: 17 bytes                                          *)
(***************************************************************************)

OrderDeleteMessage ==
    [ nanoseconds : Sample(4),
      orderId     : Sample(8),
      orderBookId : Sample(4),
      side        : Sample(1) ]

EncodeOrderDeleteMessage(message) ==
    message.nanoseconds
        \o message.orderId
        \o message.orderBookId
        \o message.side

DecodeOrderDeleteMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderId == ReadBytes(nanoseconds.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(orderId.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET side == ReadBytes(orderBookId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    Ok([ nanoseconds |-> nanoseconds.value,
         orderId     |-> orderId.value,
         orderBookId |-> orderBookId.value,
         side        |-> side.value ], side.rest)

ZeroOrderDeleteMessage ==
    [ nanoseconds |-> [i \in 1 .. 4 |-> 0],
      orderId     |-> [i \in 1 .. 8 |-> 0],
      orderBookId |-> [i \in 1 .. 4 |-> 0],
      side        |-> [i \in 1 .. 1 |-> 0] ]

(* Order Delete Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderDeleteMessage ==
    { ZeroOrderDeleteMessage }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.side = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Book Flush Message: 8 bytes                                       *)
(***************************************************************************)

OrderBookFlushMessage ==
    [ nanoseconds : Sample(4),
      orderBookId : Sample(4) ]

EncodeOrderBookFlushMessage(message) ==
    message.nanoseconds
        \o message.orderBookId

DecodeOrderBookFlushMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(nanoseconds.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    Ok([ nanoseconds |-> nanoseconds.value,
         orderBookId |-> orderBookId.value ], orderBookId.rest)

ZeroOrderBookFlushMessage ==
    [ nanoseconds |-> [i \in 1 .. 4 |-> 0],
      orderBookId |-> [i \in 1 .. 4 |-> 0] ]

(* Order Book Flush Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderBookFlushMessage ==
    { ZeroOrderBookFlushMessage }
        \cup { [ZeroOrderBookFlushMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookFlushMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }

(***************************************************************************)
(* Trade Message: 49 bytes                                                 *)
(***************************************************************************)

TradeMessage ==
    [ nanoseconds     : Sample(4),
      matchId         : Sample(8),
      comboGroupId    : Sample(4),
      side            : Sample(1),
      quantity        : Sample(8),
      orderBookId     : Sample(4),
      tradePrice      : Sample(4),
      tradeReport     : Sample(1),
      reserved13      : Sample(13),
      printable       : Sample(1),
      occurredAtCross : Sample(1) ]

EncodeTradeMessage(message) ==
    message.nanoseconds
        \o message.matchId
        \o message.comboGroupId
        \o message.side
        \o message.quantity
        \o message.orderBookId
        \o message.tradePrice
        \o message.tradeReport
        \o message.reserved13
        \o message.printable
        \o message.occurredAtCross

DecodeTradeMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET matchId == ReadBytes(nanoseconds.rest, 8) IN IF ~matchId.ok THEN Fail ELSE
    LET comboGroupId == ReadBytes(matchId.rest, 4) IN IF ~comboGroupId.ok THEN Fail ELSE
    LET side == ReadBytes(comboGroupId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET quantity == ReadBytes(side.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(quantity.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(orderBookId.rest, 4) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradeReport == ReadBytes(tradePrice.rest, 1) IN IF ~tradeReport.ok THEN Fail ELSE
    LET reserved13 == ReadBytes(tradeReport.rest, 13) IN IF ~reserved13.ok THEN Fail ELSE
    LET printable == ReadBytes(reserved13.rest, 1) IN IF ~printable.ok THEN Fail ELSE
    LET occurredAtCross == ReadBytes(printable.rest, 1) IN IF ~occurredAtCross.ok THEN Fail ELSE
    Ok([ nanoseconds     |-> nanoseconds.value,
         matchId         |-> matchId.value,
         comboGroupId    |-> comboGroupId.value,
         side            |-> side.value,
         quantity        |-> quantity.value,
         orderBookId     |-> orderBookId.value,
         tradePrice      |-> tradePrice.value,
         tradeReport     |-> tradeReport.value,
         reserved13      |-> reserved13.value,
         printable       |-> printable.value,
         occurredAtCross |-> occurredAtCross.value ], occurredAtCross.rest)

ZeroTradeMessage ==
    [ nanoseconds     |-> [i \in 1 .. 4 |-> 0],
      matchId         |-> [i \in 1 .. 8 |-> 0],
      comboGroupId    |-> [i \in 1 .. 4 |-> 0],
      side            |-> [i \in 1 .. 1 |-> 0],
      quantity        |-> [i \in 1 .. 8 |-> 0],
      orderBookId     |-> [i \in 1 .. 4 |-> 0],
      tradePrice      |-> [i \in 1 .. 4 |-> 0],
      tradeReport     |-> [i \in 1 .. 1 |-> 0],
      reserved13      |-> [i \in 1 .. 13 |-> 0],
      printable       |-> [i \in 1 .. 1 |-> 0],
      occurredAtCross |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.matchId = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.comboGroupId = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.tradePrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeReport = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.reserved13 = one] : one \in Sample(13) }
        \cup { [ZeroTradeMessage EXCEPT !.printable = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.occurredAtCross = one] : one \in Sample(1) }

(***************************************************************************)
(* Equilibrium Price Update Message: 52 bytes                              *)
(***************************************************************************)

EquilibriumPriceUpdateMessage ==
    [ nanoseconds                            : Sample(4),
      orderBookId                            : Sample(4),
      availableBidQuantityAtEquilibriumPrice : Sample(8),
      availableAskQuantityAtEquilibriumPrice : Sample(8),
      equilibriumPrice                       : Sample(4),
      bestBidPrice                           : Sample(4),
      bestAskPrice                           : Sample(4),
      bestBidQuantity                        : Sample(8),
      bestAskQuantity                        : Sample(8) ]

EncodeEquilibriumPriceUpdateMessage(message) ==
    message.nanoseconds
        \o message.orderBookId
        \o message.availableBidQuantityAtEquilibriumPrice
        \o message.availableAskQuantityAtEquilibriumPrice
        \o message.equilibriumPrice
        \o message.bestBidPrice
        \o message.bestAskPrice
        \o message.bestBidQuantity
        \o message.bestAskQuantity

DecodeEquilibriumPriceUpdateMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(nanoseconds.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET availableBidQuantityAtEquilibriumPrice == ReadBytes(orderBookId.rest, 8) IN IF ~availableBidQuantityAtEquilibriumPrice.ok THEN Fail ELSE
    LET availableAskQuantityAtEquilibriumPrice == ReadBytes(availableBidQuantityAtEquilibriumPrice.rest, 8) IN IF ~availableAskQuantityAtEquilibriumPrice.ok THEN Fail ELSE
    LET equilibriumPrice == ReadBytes(availableAskQuantityAtEquilibriumPrice.rest, 4) IN IF ~equilibriumPrice.ok THEN Fail ELSE
    LET bestBidPrice == ReadBytes(equilibriumPrice.rest, 4) IN IF ~bestBidPrice.ok THEN Fail ELSE
    LET bestAskPrice == ReadBytes(bestBidPrice.rest, 4) IN IF ~bestAskPrice.ok THEN Fail ELSE
    LET bestBidQuantity == ReadBytes(bestAskPrice.rest, 8) IN IF ~bestBidQuantity.ok THEN Fail ELSE
    LET bestAskQuantity == ReadBytes(bestBidQuantity.rest, 8) IN IF ~bestAskQuantity.ok THEN Fail ELSE
    Ok([ nanoseconds                            |-> nanoseconds.value,
         orderBookId                            |-> orderBookId.value,
         availableBidQuantityAtEquilibriumPrice |-> availableBidQuantityAtEquilibriumPrice.value,
         availableAskQuantityAtEquilibriumPrice |-> availableAskQuantityAtEquilibriumPrice.value,
         equilibriumPrice                       |-> equilibriumPrice.value,
         bestBidPrice                           |-> bestBidPrice.value,
         bestAskPrice                           |-> bestAskPrice.value,
         bestBidQuantity                        |-> bestBidQuantity.value,
         bestAskQuantity                        |-> bestAskQuantity.value ], bestAskQuantity.rest)

ZeroEquilibriumPriceUpdateMessage ==
    [ nanoseconds                            |-> [i \in 1 .. 4 |-> 0],
      orderBookId                            |-> [i \in 1 .. 4 |-> 0],
      availableBidQuantityAtEquilibriumPrice |-> [i \in 1 .. 8 |-> 0],
      availableAskQuantityAtEquilibriumPrice |-> [i \in 1 .. 8 |-> 0],
      equilibriumPrice                       |-> [i \in 1 .. 4 |-> 0],
      bestBidPrice                           |-> [i \in 1 .. 4 |-> 0],
      bestAskPrice                           |-> [i \in 1 .. 4 |-> 0],
      bestBidQuantity                        |-> [i \in 1 .. 8 |-> 0],
      bestAskQuantity                        |-> [i \in 1 .. 8 |-> 0] ]

(* Equilibrium Price Update Message at zero, then each field in turn at the values it is checked at *)
CheckedEquilibriumPriceUpdateMessage ==
    { ZeroEquilibriumPriceUpdateMessage }
        \cup { [ZeroEquilibriumPriceUpdateMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroEquilibriumPriceUpdateMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroEquilibriumPriceUpdateMessage EXCEPT !.availableBidQuantityAtEquilibriumPrice = one] : one \in Sample(8) }
        \cup { [ZeroEquilibriumPriceUpdateMessage EXCEPT !.availableAskQuantityAtEquilibriumPrice = one] : one \in Sample(8) }
        \cup { [ZeroEquilibriumPriceUpdateMessage EXCEPT !.equilibriumPrice = one] : one \in Sample(4) }
        \cup { [ZeroEquilibriumPriceUpdateMessage EXCEPT !.bestBidPrice = one] : one \in Sample(4) }
        \cup { [ZeroEquilibriumPriceUpdateMessage EXCEPT !.bestAskPrice = one] : one \in Sample(4) }
        \cup { [ZeroEquilibriumPriceUpdateMessage EXCEPT !.bestBidQuantity = one] : one \in Sample(8) }
        \cup { [ZeroEquilibriumPriceUpdateMessage EXCEPT !.bestAskQuantity = one] : one \in Sample(8) }

(***************************************************************************)
(* Sequenced Message, selected by Sequenced Message Type                   *)
(***************************************************************************)

SecondsMessageCode == 84  \* "T"
OrderBookDirectoryMessageCode == 82  \* "R"
TickSizeTableEntryMessageCode == 76  \* "L"
ShortSellStatusMessageCode == 86  \* "V"
SystemEventMessageCode == 83  \* "S"
OrderBookStateMessageCode == 79  \* "O"
AddOrderMessageCode == 65  \* "A"
OrderExecutedMessageCode == 69  \* "E"
OrderExecutedWithPriceMessageCode == 67  \* "C"
OrderDeleteMessageCode == 68  \* "D"
OrderBookFlushMessageCode == 89  \* "Y"
TradeMessageCode == 80  \* "P"
EquilibriumPriceUpdateMessageCode == 90  \* "Z"

SequencedMessage ==
    [ tag : {SecondsMessageCode}, body : SecondsMessage ]
        \cup [ tag : {OrderBookDirectoryMessageCode}, body : OrderBookDirectoryMessage ]
        \cup [ tag : {TickSizeTableEntryMessageCode}, body : TickSizeTableEntryMessage ]
        \cup [ tag : {ShortSellStatusMessageCode}, body : ShortSellStatusMessage ]
        \cup [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {OrderBookStateMessageCode}, body : OrderBookStateMessage ]
        \cup [ tag : {AddOrderMessageCode}, body : AddOrderMessage ]
        \cup [ tag : {OrderExecutedMessageCode}, body : OrderExecutedMessage ]
        \cup [ tag : {OrderExecutedWithPriceMessageCode}, body : OrderExecutedWithPriceMessage ]
        \cup [ tag : {OrderDeleteMessageCode}, body : OrderDeleteMessage ]
        \cup [ tag : {OrderBookFlushMessageCode}, body : OrderBookFlushMessage ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {EquilibriumPriceUpdateMessageCode}, body : EquilibriumPriceUpdateMessage ]

EncodeSequencedMessage(message) ==
    CASE message.tag = SecondsMessageCode -> EncodeSecondsMessage(message.body)
      [] message.tag = OrderBookDirectoryMessageCode -> EncodeOrderBookDirectoryMessage(message.body)
      [] message.tag = TickSizeTableEntryMessageCode -> EncodeTickSizeTableEntryMessage(message.body)
      [] message.tag = ShortSellStatusMessageCode -> EncodeShortSellStatusMessage(message.body)
      [] message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = OrderBookStateMessageCode -> EncodeOrderBookStateMessage(message.body)
      [] message.tag = AddOrderMessageCode -> EncodeAddOrderMessage(message.body)
      [] message.tag = OrderExecutedMessageCode -> EncodeOrderExecutedMessage(message.body)
      [] message.tag = OrderExecutedWithPriceMessageCode -> EncodeOrderExecutedWithPriceMessage(message.body)
      [] message.tag = OrderDeleteMessageCode -> EncodeOrderDeleteMessage(message.body)
      [] message.tag = OrderBookFlushMessageCode -> EncodeOrderBookFlushMessage(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = EquilibriumPriceUpdateMessageCode -> EncodeEquilibriumPriceUpdateMessage(message.body)

DecodeSequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = SecondsMessageCode -> DecodeSecondsMessage(bytes)
              [] tag = OrderBookDirectoryMessageCode -> DecodeOrderBookDirectoryMessage(bytes)
              [] tag = TickSizeTableEntryMessageCode -> DecodeTickSizeTableEntryMessage(bytes)
              [] tag = ShortSellStatusMessageCode -> DecodeShortSellStatusMessage(bytes)
              [] tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = OrderBookStateMessageCode -> DecodeOrderBookStateMessage(bytes)
              [] tag = AddOrderMessageCode -> DecodeAddOrderMessage(bytes)
              [] tag = OrderExecutedMessageCode -> DecodeOrderExecutedMessage(bytes)
              [] tag = OrderExecutedWithPriceMessageCode -> DecodeOrderExecutedWithPriceMessage(bytes)
              [] tag = OrderDeleteMessageCode -> DecodeOrderDeleteMessage(bytes)
              [] tag = OrderBookFlushMessageCode -> DecodeOrderBookFlushMessage(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = EquilibriumPriceUpdateMessageCode -> DecodeEquilibriumPriceUpdateMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSequencedMessage == [tag |-> SecondsMessageCode, body |-> ZeroSecondsMessage]

(* Each Sequenced Message in turn, at the values the message it names is checked at *)
CheckedSequencedMessage ==
    { [tag |-> SecondsMessageCode, body |-> one] : one \in CheckedSecondsMessage }
        \cup { [tag |-> OrderBookDirectoryMessageCode, body |-> one] : one \in CheckedOrderBookDirectoryMessage }
        \cup { [tag |-> TickSizeTableEntryMessageCode, body |-> one] : one \in CheckedTickSizeTableEntryMessage }
        \cup { [tag |-> ShortSellStatusMessageCode, body |-> one] : one \in CheckedShortSellStatusMessage }
        \cup { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> OrderBookStateMessageCode, body |-> one] : one \in CheckedOrderBookStateMessage }
        \cup { [tag |-> AddOrderMessageCode, body |-> one] : one \in CheckedAddOrderMessage }
        \cup { [tag |-> OrderExecutedMessageCode, body |-> one] : one \in CheckedOrderExecutedMessage }
        \cup { [tag |-> OrderExecutedWithPriceMessageCode, body |-> one] : one \in CheckedOrderExecutedWithPriceMessage }
        \cup { [tag |-> OrderDeleteMessageCode, body |-> one] : one \in CheckedOrderDeleteMessage }
        \cup { [tag |-> OrderBookFlushMessageCode, body |-> one] : one \in CheckedOrderBookFlushMessage }
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> EquilibriumPriceUpdateMessageCode, body |-> one] : one \in CheckedEquilibriumPriceUpdateMessage }

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

(* Every Seconds Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecondsMessage ==
    \A message \in CheckedSecondsMessage :
        LET read == DecodeSecondsMessage(EncodeSecondsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Book Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderBookDirectoryMessage ==
    \A message \in CheckedOrderBookDirectoryMessage :
        LET read == DecodeOrderBookDirectoryMessage(EncodeOrderBookDirectoryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tick Size Table Entry Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTickSizeTableEntryMessage ==
    \A message \in CheckedTickSizeTableEntryMessage :
        LET read == DecodeTickSizeTableEntryMessage(EncodeTickSizeTableEntryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Short Sell Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripShortSellStatusMessage ==
    \A message \in CheckedShortSellStatusMessage :
        LET read == DecodeShortSellStatusMessage(EncodeShortSellStatusMessage(message))
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

(* Every Order Book State Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderBookStateMessage ==
    \A message \in CheckedOrderBookStateMessage :
        LET read == DecodeOrderBookStateMessage(EncodeOrderBookStateMessage(message))
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

(* Every Order Executed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutedMessage ==
    \A message \in CheckedOrderExecutedMessage :
        LET read == DecodeOrderExecutedMessage(EncodeOrderExecutedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Executed With Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutedWithPriceMessage ==
    \A message \in CheckedOrderExecutedWithPriceMessage :
        LET read == DecodeOrderExecutedWithPriceMessage(EncodeOrderExecutedWithPriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Delete Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderDeleteMessage ==
    \A message \in CheckedOrderDeleteMessage :
        LET read == DecodeOrderDeleteMessage(EncodeOrderDeleteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Book Flush Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderBookFlushMessage ==
    \A message \in CheckedOrderBookFlushMessage :
        LET read == DecodeOrderBookFlushMessage(EncodeOrderBookFlushMessage(message))
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

(* Every Equilibrium Price Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEquilibriumPriceUpdateMessage ==
    \A message \in CheckedEquilibriumPriceUpdateMessage :
        LET read == DecodeEquilibriumPriceUpdateMessage(EncodeEquilibriumPriceUpdateMessage(message))
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
