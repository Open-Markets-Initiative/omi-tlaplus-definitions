--------------- MODULE EdgaEquities_TcpDepthOfBook_v1_15_13 ----------------
(***************************************************************************)
(* Chicago Board Options Exchange Tcp Depth Of Book v1.15.13               *)
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
(* Note: Unsequenced Message is as wide as what is left of Unsequenced     *)
(* Data Packet, bar the 1 byte read after it: it is read as the bytes left *)
(* of what its record was given, which the records above it keep those     *)
(* bytes back from.                                                        *)
(*                                                                         *)
(* Note: Frame is closed by Soup Lf, so its body is read as the bytes      *)
(* ahead of the first 10 and written back with that byte after it, which   *)
(* is what lets a run of them be told apart.                               *)
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

(* A record closed by a terminator is the bytes ahead of the first one. Scanning for it *)
(* is how far the record reaches: the body is what lies before the byte, and what lies *)
(* after it is the next record's. A run of them with no terminator left is no record at *)
(* all, so the reader fails rather than taking the rest. *)
RECURSIVE Terminated(_, _)
Terminated(bytes, terminator) ==
    IF bytes = << >>
    THEN 0
    ELSE IF Head(bytes) = terminator
         THEN 1
         ELSE LET after == Terminated(Tail(bytes), terminator)
              IN  IF after = 0 THEN 0 ELSE after + 1

(* The body a terminator closes, and the bytes after the byte that closed it *)
ReadClosed(bytes, terminator) ==
    LET at == Terminated(bytes, terminator) IN
    IF at = 0
    THEN Fail
    ELSE Ok(SubSeq(bytes, 1, at - 1), SubSeq(bytes, at + 1, Len(bytes)))

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
(* Debug Packet: 1 bytes                                                   *)
(***************************************************************************)

DebugPacket ==
    [ text : Sample(1) ]

EncodeDebugPacket(message) ==
    message.text

DecodeDebugPacket(bytes) ==
    LET text == ReadBytes(bytes, 1) IN IF ~text.ok THEN Fail ELSE
    Ok([ text |-> text.value ], text.rest)

ZeroDebugPacket ==
    [ text |-> [i \in 1 .. 1 |-> 0] ]

(* Debug Packet at zero, then each field in turn at the values it is checked at *)
CheckedDebugPacket ==
    { ZeroDebugPacket }
        \cup { [ZeroDebugPacket EXCEPT !.text = one] : one \in Sample(1) }

(***************************************************************************)
(* Login Accepted Packet: 20 bytes                                         *)
(***************************************************************************)

LoginAcceptedPacket ==
    [ session        : Sample(10),
      sequenceNumber : Sample(10) ]

EncodeLoginAcceptedPacket(message) ==
    message.session
        \o message.sequenceNumber

DecodeLoginAcceptedPacket(bytes) ==
    LET session == ReadBytes(bytes, 10) IN IF ~session.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(session.rest, 10) IN IF ~sequenceNumber.ok THEN Fail ELSE
    Ok([ session        |-> session.value,
         sequenceNumber |-> sequenceNumber.value ], sequenceNumber.rest)

ZeroLoginAcceptedPacket ==
    [ session        |-> [i \in 1 .. 10 |-> 0],
      sequenceNumber |-> [i \in 1 .. 10 |-> 0] ]

(* Login Accepted Packet at zero, then each field in turn at the values it is checked at *)
CheckedLoginAcceptedPacket ==
    { ZeroLoginAcceptedPacket }
        \cup { [ZeroLoginAcceptedPacket EXCEPT !.session = one] : one \in Sample(10) }
        \cup { [ZeroLoginAcceptedPacket EXCEPT !.sequenceNumber = one] : one \in Sample(10) }

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
(* Symbol Clear Message: 8 bytes                                           *)
(***************************************************************************)

SymbolClearMessage ==
    [ stockSymbolLong : Sample(8) ]

EncodeSymbolClearMessage(message) ==
    message.stockSymbolLong

DecodeSymbolClearMessage(bytes) ==
    LET stockSymbolLong == ReadBytes(bytes, 8) IN IF ~stockSymbolLong.ok THEN Fail ELSE
    Ok([ stockSymbolLong |-> stockSymbolLong.value ], stockSymbolLong.rest)

ZeroSymbolClearMessage ==
    [ stockSymbolLong |-> [i \in 1 .. 8 |-> 0] ]

(* Symbol Clear Message at zero, then each field in turn at the values it is checked at *)
CheckedSymbolClearMessage ==
    { ZeroSymbolClearMessage }
        \cup { [ZeroSymbolClearMessage EXCEPT !.stockSymbolLong = one] : one \in Sample(8) }

(***************************************************************************)
(* Add Order Short Message: 36 bytes                                       *)
(***************************************************************************)

AddOrderShortMessage ==
    [ orderId          : Sample(12),
      sideIndicator    : Sample(1),
      sharesShort      : Sample(6),
      stockSymbolShort : Sample(6),
      priceShort       : Sample(10),
      reserved         : Sample(1) ]

EncodeAddOrderShortMessage(message) ==
    message.orderId
        \o message.sideIndicator
        \o message.sharesShort
        \o message.stockSymbolShort
        \o message.priceShort
        \o message.reserved

DecodeAddOrderShortMessage(bytes) ==
    LET orderId == ReadBytes(bytes, 12) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET sharesShort == ReadBytes(sideIndicator.rest, 6) IN IF ~sharesShort.ok THEN Fail ELSE
    LET stockSymbolShort == ReadBytes(sharesShort.rest, 6) IN IF ~stockSymbolShort.ok THEN Fail ELSE
    LET priceShort == ReadBytes(stockSymbolShort.rest, 10) IN IF ~priceShort.ok THEN Fail ELSE
    LET reserved == ReadBytes(priceShort.rest, 1) IN IF ~reserved.ok THEN Fail ELSE
    Ok([ orderId          |-> orderId.value,
         sideIndicator    |-> sideIndicator.value,
         sharesShort      |-> sharesShort.value,
         stockSymbolShort |-> stockSymbolShort.value,
         priceShort       |-> priceShort.value,
         reserved         |-> reserved.value ], reserved.rest)

ZeroAddOrderShortMessage ==
    [ orderId          |-> [i \in 1 .. 12 |-> 0],
      sideIndicator    |-> [i \in 1 .. 1 |-> 0],
      sharesShort      |-> [i \in 1 .. 6 |-> 0],
      stockSymbolShort |-> [i \in 1 .. 6 |-> 0],
      priceShort       |-> [i \in 1 .. 10 |-> 0],
      reserved         |-> [i \in 1 .. 1 |-> 0] ]

(* Add Order Short Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderShortMessage ==
    { ZeroAddOrderShortMessage }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.orderId = one] : one \in Sample(12) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.sharesShort = one] : one \in Sample(6) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.stockSymbolShort = one] : one \in Sample(6) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.priceShort = one] : one \in Sample(10) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.reserved = one] : one \in Sample(1) }

(***************************************************************************)
(* Add Order Long Message: 43 bytes                                        *)
(***************************************************************************)

AddOrderLongMessage ==
    [ orderId           : Sample(12),
      sideIndicator     : Sample(1),
      sharesShort       : Sample(6),
      stockSymbolLong   : Sample(8),
      priceShort        : Sample(10),
      reserved          : Sample(1),
      participantId     : Sample(4),
      customerIndicator : Sample(1) ]

EncodeAddOrderLongMessage(message) ==
    message.orderId
        \o message.sideIndicator
        \o message.sharesShort
        \o message.stockSymbolLong
        \o message.priceShort
        \o message.reserved
        \o message.participantId
        \o message.customerIndicator

DecodeAddOrderLongMessage(bytes) ==
    LET orderId == ReadBytes(bytes, 12) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET sharesShort == ReadBytes(sideIndicator.rest, 6) IN IF ~sharesShort.ok THEN Fail ELSE
    LET stockSymbolLong == ReadBytes(sharesShort.rest, 8) IN IF ~stockSymbolLong.ok THEN Fail ELSE
    LET priceShort == ReadBytes(stockSymbolLong.rest, 10) IN IF ~priceShort.ok THEN Fail ELSE
    LET reserved == ReadBytes(priceShort.rest, 1) IN IF ~reserved.ok THEN Fail ELSE
    LET participantId == ReadBytes(reserved.rest, 4) IN IF ~participantId.ok THEN Fail ELSE
    LET customerIndicator == ReadBytes(participantId.rest, 1) IN IF ~customerIndicator.ok THEN Fail ELSE
    Ok([ orderId           |-> orderId.value,
         sideIndicator     |-> sideIndicator.value,
         sharesShort       |-> sharesShort.value,
         stockSymbolLong   |-> stockSymbolLong.value,
         priceShort        |-> priceShort.value,
         reserved          |-> reserved.value,
         participantId     |-> participantId.value,
         customerIndicator |-> customerIndicator.value ], customerIndicator.rest)

ZeroAddOrderLongMessage ==
    [ orderId           |-> [i \in 1 .. 12 |-> 0],
      sideIndicator     |-> [i \in 1 .. 1 |-> 0],
      sharesShort       |-> [i \in 1 .. 6 |-> 0],
      stockSymbolLong   |-> [i \in 1 .. 8 |-> 0],
      priceShort        |-> [i \in 1 .. 10 |-> 0],
      reserved          |-> [i \in 1 .. 1 |-> 0],
      participantId     |-> [i \in 1 .. 4 |-> 0],
      customerIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Add Order Long Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderLongMessage ==
    { ZeroAddOrderLongMessage }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.orderId = one] : one \in Sample(12) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.sharesShort = one] : one \in Sample(6) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.stockSymbolLong = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.priceShort = one] : one \in Sample(10) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.reserved = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.participantId = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.customerIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Add Order Extended Message: 47 bytes                                    *)
(***************************************************************************)

AddOrderExtendedMessage ==
    [ orderId           : Sample(12),
      sideIndicator     : Sample(1),
      sharesShort       : Sample(6),
      stockSymbolLong   : Sample(8),
      priceLong         : Sample(14),
      display           : Sample(1),
      participantId     : Sample(4),
      customerIndicator : Sample(1) ]

EncodeAddOrderExtendedMessage(message) ==
    message.orderId
        \o message.sideIndicator
        \o message.sharesShort
        \o message.stockSymbolLong
        \o message.priceLong
        \o message.display
        \o message.participantId
        \o message.customerIndicator

DecodeAddOrderExtendedMessage(bytes) ==
    LET orderId == ReadBytes(bytes, 12) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET sharesShort == ReadBytes(sideIndicator.rest, 6) IN IF ~sharesShort.ok THEN Fail ELSE
    LET stockSymbolLong == ReadBytes(sharesShort.rest, 8) IN IF ~stockSymbolLong.ok THEN Fail ELSE
    LET priceLong == ReadBytes(stockSymbolLong.rest, 14) IN IF ~priceLong.ok THEN Fail ELSE
    LET display == ReadBytes(priceLong.rest, 1) IN IF ~display.ok THEN Fail ELSE
    LET participantId == ReadBytes(display.rest, 4) IN IF ~participantId.ok THEN Fail ELSE
    LET customerIndicator == ReadBytes(participantId.rest, 1) IN IF ~customerIndicator.ok THEN Fail ELSE
    Ok([ orderId           |-> orderId.value,
         sideIndicator     |-> sideIndicator.value,
         sharesShort       |-> sharesShort.value,
         stockSymbolLong   |-> stockSymbolLong.value,
         priceLong         |-> priceLong.value,
         display           |-> display.value,
         participantId     |-> participantId.value,
         customerIndicator |-> customerIndicator.value ], customerIndicator.rest)

ZeroAddOrderExtendedMessage ==
    [ orderId           |-> [i \in 1 .. 12 |-> 0],
      sideIndicator     |-> [i \in 1 .. 1 |-> 0],
      sharesShort       |-> [i \in 1 .. 6 |-> 0],
      stockSymbolLong   |-> [i \in 1 .. 8 |-> 0],
      priceLong         |-> [i \in 1 .. 14 |-> 0],
      display           |-> [i \in 1 .. 1 |-> 0],
      participantId     |-> [i \in 1 .. 4 |-> 0],
      customerIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Add Order Extended Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderExtendedMessage ==
    { ZeroAddOrderExtendedMessage }
        \cup { [ZeroAddOrderExtendedMessage EXCEPT !.orderId = one] : one \in Sample(12) }
        \cup { [ZeroAddOrderExtendedMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderExtendedMessage EXCEPT !.sharesShort = one] : one \in Sample(6) }
        \cup { [ZeroAddOrderExtendedMessage EXCEPT !.stockSymbolLong = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderExtendedMessage EXCEPT !.priceLong = one] : one \in Sample(14) }
        \cup { [ZeroAddOrderExtendedMessage EXCEPT !.display = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderExtendedMessage EXCEPT !.participantId = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderExtendedMessage EXCEPT !.customerIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Executed Message: 30 bytes                                        *)
(***************************************************************************)

OrderExecutedMessage ==
    [ orderId        : Sample(12),
      executedShares : Sample(6),
      executionId    : Sample(12) ]

EncodeOrderExecutedMessage(message) ==
    message.orderId
        \o message.executedShares
        \o message.executionId

DecodeOrderExecutedMessage(bytes) ==
    LET orderId == ReadBytes(bytes, 12) IN IF ~orderId.ok THEN Fail ELSE
    LET executedShares == ReadBytes(orderId.rest, 6) IN IF ~executedShares.ok THEN Fail ELSE
    LET executionId == ReadBytes(executedShares.rest, 12) IN IF ~executionId.ok THEN Fail ELSE
    Ok([ orderId        |-> orderId.value,
         executedShares |-> executedShares.value,
         executionId    |-> executionId.value ], executionId.rest)

ZeroOrderExecutedMessage ==
    [ orderId        |-> [i \in 1 .. 12 |-> 0],
      executedShares |-> [i \in 1 .. 6 |-> 0],
      executionId    |-> [i \in 1 .. 12 |-> 0] ]

(* Order Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedMessage ==
    { ZeroOrderExecutedMessage }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.orderId = one] : one \in Sample(12) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.executedShares = one] : one \in Sample(6) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.executionId = one] : one \in Sample(12) }

(***************************************************************************)
(* Order Cancel Message: 18 bytes                                          *)
(***************************************************************************)

OrderCancelMessage ==
    [ orderId        : Sample(12),
      canceledShares : Sample(6) ]

EncodeOrderCancelMessage(message) ==
    message.orderId
        \o message.canceledShares

DecodeOrderCancelMessage(bytes) ==
    LET orderId == ReadBytes(bytes, 12) IN IF ~orderId.ok THEN Fail ELSE
    LET canceledShares == ReadBytes(orderId.rest, 6) IN IF ~canceledShares.ok THEN Fail ELSE
    Ok([ orderId        |-> orderId.value,
         canceledShares |-> canceledShares.value ], canceledShares.rest)

ZeroOrderCancelMessage ==
    [ orderId        |-> [i \in 1 .. 12 |-> 0],
      canceledShares |-> [i \in 1 .. 6 |-> 0] ]

(* Order Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelMessage ==
    { ZeroOrderCancelMessage }
        \cup { [ZeroOrderCancelMessage EXCEPT !.orderId = one] : one \in Sample(12) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.canceledShares = one] : one \in Sample(6) }

(***************************************************************************)
(* Trade Short Message: 47 bytes                                           *)
(***************************************************************************)

TradeShortMessage ==
    [ orderId          : Sample(12),
      sideIndicator    : Sample(1),
      sharesShort      : Sample(6),
      stockSymbolShort : Sample(6),
      priceShort       : Sample(10),
      executionId      : Sample(12) ]

EncodeTradeShortMessage(message) ==
    message.orderId
        \o message.sideIndicator
        \o message.sharesShort
        \o message.stockSymbolShort
        \o message.priceShort
        \o message.executionId

DecodeTradeShortMessage(bytes) ==
    LET orderId == ReadBytes(bytes, 12) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET sharesShort == ReadBytes(sideIndicator.rest, 6) IN IF ~sharesShort.ok THEN Fail ELSE
    LET stockSymbolShort == ReadBytes(sharesShort.rest, 6) IN IF ~stockSymbolShort.ok THEN Fail ELSE
    LET priceShort == ReadBytes(stockSymbolShort.rest, 10) IN IF ~priceShort.ok THEN Fail ELSE
    LET executionId == ReadBytes(priceShort.rest, 12) IN IF ~executionId.ok THEN Fail ELSE
    Ok([ orderId          |-> orderId.value,
         sideIndicator    |-> sideIndicator.value,
         sharesShort      |-> sharesShort.value,
         stockSymbolShort |-> stockSymbolShort.value,
         priceShort       |-> priceShort.value,
         executionId      |-> executionId.value ], executionId.rest)

ZeroTradeShortMessage ==
    [ orderId          |-> [i \in 1 .. 12 |-> 0],
      sideIndicator    |-> [i \in 1 .. 1 |-> 0],
      sharesShort      |-> [i \in 1 .. 6 |-> 0],
      stockSymbolShort |-> [i \in 1 .. 6 |-> 0],
      priceShort       |-> [i \in 1 .. 10 |-> 0],
      executionId      |-> [i \in 1 .. 12 |-> 0] ]

(* Trade Short Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeShortMessage ==
    { ZeroTradeShortMessage }
        \cup { [ZeroTradeShortMessage EXCEPT !.orderId = one] : one \in Sample(12) }
        \cup { [ZeroTradeShortMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeShortMessage EXCEPT !.sharesShort = one] : one \in Sample(6) }
        \cup { [ZeroTradeShortMessage EXCEPT !.stockSymbolShort = one] : one \in Sample(6) }
        \cup { [ZeroTradeShortMessage EXCEPT !.priceShort = one] : one \in Sample(10) }
        \cup { [ZeroTradeShortMessage EXCEPT !.executionId = one] : one \in Sample(12) }

(***************************************************************************)
(* Trade Long Message: 49 bytes                                            *)
(***************************************************************************)

TradeLongMessage ==
    [ orderId         : Sample(12),
      sideIndicator   : Sample(1),
      sharesShort     : Sample(6),
      stockSymbolLong : Sample(8),
      priceShort      : Sample(10),
      executionId     : Sample(12) ]

EncodeTradeLongMessage(message) ==
    message.orderId
        \o message.sideIndicator
        \o message.sharesShort
        \o message.stockSymbolLong
        \o message.priceShort
        \o message.executionId

DecodeTradeLongMessage(bytes) ==
    LET orderId == ReadBytes(bytes, 12) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET sharesShort == ReadBytes(sideIndicator.rest, 6) IN IF ~sharesShort.ok THEN Fail ELSE
    LET stockSymbolLong == ReadBytes(sharesShort.rest, 8) IN IF ~stockSymbolLong.ok THEN Fail ELSE
    LET priceShort == ReadBytes(stockSymbolLong.rest, 10) IN IF ~priceShort.ok THEN Fail ELSE
    LET executionId == ReadBytes(priceShort.rest, 12) IN IF ~executionId.ok THEN Fail ELSE
    Ok([ orderId         |-> orderId.value,
         sideIndicator   |-> sideIndicator.value,
         sharesShort     |-> sharesShort.value,
         stockSymbolLong |-> stockSymbolLong.value,
         priceShort      |-> priceShort.value,
         executionId     |-> executionId.value ], executionId.rest)

ZeroTradeLongMessage ==
    [ orderId         |-> [i \in 1 .. 12 |-> 0],
      sideIndicator   |-> [i \in 1 .. 1 |-> 0],
      sharesShort     |-> [i \in 1 .. 6 |-> 0],
      stockSymbolLong |-> [i \in 1 .. 8 |-> 0],
      priceShort      |-> [i \in 1 .. 10 |-> 0],
      executionId     |-> [i \in 1 .. 12 |-> 0] ]

(* Trade Long Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeLongMessage ==
    { ZeroTradeLongMessage }
        \cup { [ZeroTradeLongMessage EXCEPT !.orderId = one] : one \in Sample(12) }
        \cup { [ZeroTradeLongMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeLongMessage EXCEPT !.sharesShort = one] : one \in Sample(6) }
        \cup { [ZeroTradeLongMessage EXCEPT !.stockSymbolLong = one] : one \in Sample(8) }
        \cup { [ZeroTradeLongMessage EXCEPT !.priceShort = one] : one \in Sample(10) }
        \cup { [ZeroTradeLongMessage EXCEPT !.executionId = one] : one \in Sample(12) }

(***************************************************************************)
(* Trade Extended Message: 53 bytes                                        *)
(***************************************************************************)

TradeExtendedMessage ==
    [ orderId         : Sample(12),
      sideIndicator   : Sample(1),
      sharesShort     : Sample(6),
      stockSymbolLong : Sample(8),
      priceLong       : Sample(14),
      executionId     : Sample(12) ]

EncodeTradeExtendedMessage(message) ==
    message.orderId
        \o message.sideIndicator
        \o message.sharesShort
        \o message.stockSymbolLong
        \o message.priceLong
        \o message.executionId

DecodeTradeExtendedMessage(bytes) ==
    LET orderId == ReadBytes(bytes, 12) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET sharesShort == ReadBytes(sideIndicator.rest, 6) IN IF ~sharesShort.ok THEN Fail ELSE
    LET stockSymbolLong == ReadBytes(sharesShort.rest, 8) IN IF ~stockSymbolLong.ok THEN Fail ELSE
    LET priceLong == ReadBytes(stockSymbolLong.rest, 14) IN IF ~priceLong.ok THEN Fail ELSE
    LET executionId == ReadBytes(priceLong.rest, 12) IN IF ~executionId.ok THEN Fail ELSE
    Ok([ orderId         |-> orderId.value,
         sideIndicator   |-> sideIndicator.value,
         sharesShort     |-> sharesShort.value,
         stockSymbolLong |-> stockSymbolLong.value,
         priceLong       |-> priceLong.value,
         executionId     |-> executionId.value ], executionId.rest)

ZeroTradeExtendedMessage ==
    [ orderId         |-> [i \in 1 .. 12 |-> 0],
      sideIndicator   |-> [i \in 1 .. 1 |-> 0],
      sharesShort     |-> [i \in 1 .. 6 |-> 0],
      stockSymbolLong |-> [i \in 1 .. 8 |-> 0],
      priceLong       |-> [i \in 1 .. 14 |-> 0],
      executionId     |-> [i \in 1 .. 12 |-> 0] ]

(* Trade Extended Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeExtendedMessage ==
    { ZeroTradeExtendedMessage }
        \cup { [ZeroTradeExtendedMessage EXCEPT !.orderId = one] : one \in Sample(12) }
        \cup { [ZeroTradeExtendedMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeExtendedMessage EXCEPT !.sharesShort = one] : one \in Sample(6) }
        \cup { [ZeroTradeExtendedMessage EXCEPT !.stockSymbolLong = one] : one \in Sample(8) }
        \cup { [ZeroTradeExtendedMessage EXCEPT !.priceLong = one] : one \in Sample(14) }
        \cup { [ZeroTradeExtendedMessage EXCEPT !.executionId = one] : one \in Sample(12) }

(***************************************************************************)
(* Trade Break Message: 12 bytes                                           *)
(***************************************************************************)

TradeBreakMessage ==
    [ executionId : Sample(12) ]

EncodeTradeBreakMessage(message) ==
    message.executionId

DecodeTradeBreakMessage(bytes) ==
    LET executionId == ReadBytes(bytes, 12) IN IF ~executionId.ok THEN Fail ELSE
    Ok([ executionId |-> executionId.value ], executionId.rest)

ZeroTradeBreakMessage ==
    [ executionId |-> [i \in 1 .. 12 |-> 0] ]

(* Trade Break Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeBreakMessage ==
    { ZeroTradeBreakMessage }
        \cup { [ZeroTradeBreakMessage EXCEPT !.executionId = one] : one \in Sample(12) }

(***************************************************************************)
(* Trading Status Message: 12 bytes                                        *)
(***************************************************************************)

TradingStatusMessage ==
    [ stockSymbolLong : Sample(8),
      haltStatus      : Sample(1),
      regShoAction    : Sample(1),
      reserved1       : Sample(1),
      reserved2       : Sample(1) ]

EncodeTradingStatusMessage(message) ==
    message.stockSymbolLong
        \o message.haltStatus
        \o message.regShoAction
        \o message.reserved1
        \o message.reserved2

DecodeTradingStatusMessage(bytes) ==
    LET stockSymbolLong == ReadBytes(bytes, 8) IN IF ~stockSymbolLong.ok THEN Fail ELSE
    LET haltStatus == ReadBytes(stockSymbolLong.rest, 1) IN IF ~haltStatus.ok THEN Fail ELSE
    LET regShoAction == ReadBytes(haltStatus.rest, 1) IN IF ~regShoAction.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(regShoAction.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(reserved1.rest, 1) IN IF ~reserved2.ok THEN Fail ELSE
    Ok([ stockSymbolLong |-> stockSymbolLong.value,
         haltStatus      |-> haltStatus.value,
         regShoAction    |-> regShoAction.value,
         reserved1       |-> reserved1.value,
         reserved2       |-> reserved2.value ], reserved2.rest)

ZeroTradingStatusMessage ==
    [ stockSymbolLong |-> [i \in 1 .. 8 |-> 0],
      haltStatus      |-> [i \in 1 .. 1 |-> 0],
      regShoAction    |-> [i \in 1 .. 1 |-> 0],
      reserved1       |-> [i \in 1 .. 1 |-> 0],
      reserved2       |-> [i \in 1 .. 1 |-> 0] ]

(* Trading Status Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingStatusMessage ==
    { ZeroTradingStatusMessage }
        \cup { [ZeroTradingStatusMessage EXCEPT !.stockSymbolLong = one] : one \in Sample(8) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.haltStatus = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.regShoAction = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.reserved2 = one] : one \in Sample(1) }

(***************************************************************************)
(* Auction Update Message: 59 bytes                                        *)
(***************************************************************************)

AuctionUpdateMessage ==
    [ stockSymbolLong       : Sample(8),
      auctionType           : Sample(1),
      referencePriceShort   : Sample(10),
      buyShares             : Sample(10),
      sellShares            : Sample(10),
      indicativePriceShort  : Sample(10),
      auctionOnlyPriceShort : Sample(10) ]

EncodeAuctionUpdateMessage(message) ==
    message.stockSymbolLong
        \o message.auctionType
        \o message.referencePriceShort
        \o message.buyShares
        \o message.sellShares
        \o message.indicativePriceShort
        \o message.auctionOnlyPriceShort

DecodeAuctionUpdateMessage(bytes) ==
    LET stockSymbolLong == ReadBytes(bytes, 8) IN IF ~stockSymbolLong.ok THEN Fail ELSE
    LET auctionType == ReadBytes(stockSymbolLong.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET referencePriceShort == ReadBytes(auctionType.rest, 10) IN IF ~referencePriceShort.ok THEN Fail ELSE
    LET buyShares == ReadBytes(referencePriceShort.rest, 10) IN IF ~buyShares.ok THEN Fail ELSE
    LET sellShares == ReadBytes(buyShares.rest, 10) IN IF ~sellShares.ok THEN Fail ELSE
    LET indicativePriceShort == ReadBytes(sellShares.rest, 10) IN IF ~indicativePriceShort.ok THEN Fail ELSE
    LET auctionOnlyPriceShort == ReadBytes(indicativePriceShort.rest, 10) IN IF ~auctionOnlyPriceShort.ok THEN Fail ELSE
    Ok([ stockSymbolLong       |-> stockSymbolLong.value,
         auctionType           |-> auctionType.value,
         referencePriceShort   |-> referencePriceShort.value,
         buyShares             |-> buyShares.value,
         sellShares            |-> sellShares.value,
         indicativePriceShort  |-> indicativePriceShort.value,
         auctionOnlyPriceShort |-> auctionOnlyPriceShort.value ], auctionOnlyPriceShort.rest)

ZeroAuctionUpdateMessage ==
    [ stockSymbolLong       |-> [i \in 1 .. 8 |-> 0],
      auctionType           |-> [i \in 1 .. 1 |-> 0],
      referencePriceShort   |-> [i \in 1 .. 10 |-> 0],
      buyShares             |-> [i \in 1 .. 10 |-> 0],
      sellShares            |-> [i \in 1 .. 10 |-> 0],
      indicativePriceShort  |-> [i \in 1 .. 10 |-> 0],
      auctionOnlyPriceShort |-> [i \in 1 .. 10 |-> 0] ]

(* Auction Update Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionUpdateMessage ==
    { ZeroAuctionUpdateMessage }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.stockSymbolLong = one] : one \in Sample(8) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.referencePriceShort = one] : one \in Sample(10) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.buyShares = one] : one \in Sample(10) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.sellShares = one] : one \in Sample(10) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.indicativePriceShort = one] : one \in Sample(10) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.auctionOnlyPriceShort = one] : one \in Sample(10) }

(***************************************************************************)
(* Extended Auction Update Message: 71 bytes                               *)
(***************************************************************************)

ExtendedAuctionUpdateMessage ==
    [ stockSymbolLong      : Sample(8),
      auctionType          : Sample(1),
      referencePriceLong   : Sample(14),
      buyShares            : Sample(10),
      sellShares           : Sample(10),
      indicativePriceLong  : Sample(14),
      auctionOnlyPriceLong : Sample(14) ]

EncodeExtendedAuctionUpdateMessage(message) ==
    message.stockSymbolLong
        \o message.auctionType
        \o message.referencePriceLong
        \o message.buyShares
        \o message.sellShares
        \o message.indicativePriceLong
        \o message.auctionOnlyPriceLong

DecodeExtendedAuctionUpdateMessage(bytes) ==
    LET stockSymbolLong == ReadBytes(bytes, 8) IN IF ~stockSymbolLong.ok THEN Fail ELSE
    LET auctionType == ReadBytes(stockSymbolLong.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET referencePriceLong == ReadBytes(auctionType.rest, 14) IN IF ~referencePriceLong.ok THEN Fail ELSE
    LET buyShares == ReadBytes(referencePriceLong.rest, 10) IN IF ~buyShares.ok THEN Fail ELSE
    LET sellShares == ReadBytes(buyShares.rest, 10) IN IF ~sellShares.ok THEN Fail ELSE
    LET indicativePriceLong == ReadBytes(sellShares.rest, 14) IN IF ~indicativePriceLong.ok THEN Fail ELSE
    LET auctionOnlyPriceLong == ReadBytes(indicativePriceLong.rest, 14) IN IF ~auctionOnlyPriceLong.ok THEN Fail ELSE
    Ok([ stockSymbolLong      |-> stockSymbolLong.value,
         auctionType          |-> auctionType.value,
         referencePriceLong   |-> referencePriceLong.value,
         buyShares            |-> buyShares.value,
         sellShares           |-> sellShares.value,
         indicativePriceLong  |-> indicativePriceLong.value,
         auctionOnlyPriceLong |-> auctionOnlyPriceLong.value ], auctionOnlyPriceLong.rest)

ZeroExtendedAuctionUpdateMessage ==
    [ stockSymbolLong      |-> [i \in 1 .. 8 |-> 0],
      auctionType          |-> [i \in 1 .. 1 |-> 0],
      referencePriceLong   |-> [i \in 1 .. 14 |-> 0],
      buyShares            |-> [i \in 1 .. 10 |-> 0],
      sellShares           |-> [i \in 1 .. 10 |-> 0],
      indicativePriceLong  |-> [i \in 1 .. 14 |-> 0],
      auctionOnlyPriceLong |-> [i \in 1 .. 14 |-> 0] ]

(* Extended Auction Update Message at zero, then each field in turn at the values it is checked at *)
CheckedExtendedAuctionUpdateMessage ==
    { ZeroExtendedAuctionUpdateMessage }
        \cup { [ZeroExtendedAuctionUpdateMessage EXCEPT !.stockSymbolLong = one] : one \in Sample(8) }
        \cup { [ZeroExtendedAuctionUpdateMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroExtendedAuctionUpdateMessage EXCEPT !.referencePriceLong = one] : one \in Sample(14) }
        \cup { [ZeroExtendedAuctionUpdateMessage EXCEPT !.buyShares = one] : one \in Sample(10) }
        \cup { [ZeroExtendedAuctionUpdateMessage EXCEPT !.sellShares = one] : one \in Sample(10) }
        \cup { [ZeroExtendedAuctionUpdateMessage EXCEPT !.indicativePriceLong = one] : one \in Sample(14) }
        \cup { [ZeroExtendedAuctionUpdateMessage EXCEPT !.auctionOnlyPriceLong = one] : one \in Sample(14) }

(***************************************************************************)
(* Auction Summary Message: 29 bytes                                       *)
(***************************************************************************)

AuctionSummaryMessage ==
    [ stockSymbolLong : Sample(8),
      auctionType     : Sample(1),
      priceShort      : Sample(10),
      sharesLong      : Sample(10) ]

EncodeAuctionSummaryMessage(message) ==
    message.stockSymbolLong
        \o message.auctionType
        \o message.priceShort
        \o message.sharesLong

DecodeAuctionSummaryMessage(bytes) ==
    LET stockSymbolLong == ReadBytes(bytes, 8) IN IF ~stockSymbolLong.ok THEN Fail ELSE
    LET auctionType == ReadBytes(stockSymbolLong.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET priceShort == ReadBytes(auctionType.rest, 10) IN IF ~priceShort.ok THEN Fail ELSE
    LET sharesLong == ReadBytes(priceShort.rest, 10) IN IF ~sharesLong.ok THEN Fail ELSE
    Ok([ stockSymbolLong |-> stockSymbolLong.value,
         auctionType     |-> auctionType.value,
         priceShort      |-> priceShort.value,
         sharesLong      |-> sharesLong.value ], sharesLong.rest)

ZeroAuctionSummaryMessage ==
    [ stockSymbolLong |-> [i \in 1 .. 8 |-> 0],
      auctionType     |-> [i \in 1 .. 1 |-> 0],
      priceShort      |-> [i \in 1 .. 10 |-> 0],
      sharesLong      |-> [i \in 1 .. 10 |-> 0] ]

(* Auction Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionSummaryMessage ==
    { ZeroAuctionSummaryMessage }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.stockSymbolLong = one] : one \in Sample(8) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.priceShort = one] : one \in Sample(10) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.sharesLong = one] : one \in Sample(10) }

(***************************************************************************)
(* Extended Auction Summary Message: 33 bytes                              *)
(***************************************************************************)

ExtendedAuctionSummaryMessage ==
    [ stockSymbolLong : Sample(8),
      auctionType     : Sample(1),
      priceLong       : Sample(14),
      sharesLong      : Sample(10) ]

EncodeExtendedAuctionSummaryMessage(message) ==
    message.stockSymbolLong
        \o message.auctionType
        \o message.priceLong
        \o message.sharesLong

DecodeExtendedAuctionSummaryMessage(bytes) ==
    LET stockSymbolLong == ReadBytes(bytes, 8) IN IF ~stockSymbolLong.ok THEN Fail ELSE
    LET auctionType == ReadBytes(stockSymbolLong.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET priceLong == ReadBytes(auctionType.rest, 14) IN IF ~priceLong.ok THEN Fail ELSE
    LET sharesLong == ReadBytes(priceLong.rest, 10) IN IF ~sharesLong.ok THEN Fail ELSE
    Ok([ stockSymbolLong |-> stockSymbolLong.value,
         auctionType     |-> auctionType.value,
         priceLong       |-> priceLong.value,
         sharesLong      |-> sharesLong.value ], sharesLong.rest)

ZeroExtendedAuctionSummaryMessage ==
    [ stockSymbolLong |-> [i \in 1 .. 8 |-> 0],
      auctionType     |-> [i \in 1 .. 1 |-> 0],
      priceLong       |-> [i \in 1 .. 14 |-> 0],
      sharesLong      |-> [i \in 1 .. 10 |-> 0] ]

(* Extended Auction Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedExtendedAuctionSummaryMessage ==
    { ZeroExtendedAuctionSummaryMessage }
        \cup { [ZeroExtendedAuctionSummaryMessage EXCEPT !.stockSymbolLong = one] : one \in Sample(8) }
        \cup { [ZeroExtendedAuctionSummaryMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroExtendedAuctionSummaryMessage EXCEPT !.priceLong = one] : one \in Sample(14) }
        \cup { [ZeroExtendedAuctionSummaryMessage EXCEPT !.sharesLong = one] : one \in Sample(10) }

(***************************************************************************)
(* Retail Price Improvement Message: 9 bytes                               *)
(***************************************************************************)

RetailPriceImprovementMessage ==
    [ stockSymbolLong        : Sample(8),
      retailPriceImprovement : Sample(1) ]

EncodeRetailPriceImprovementMessage(message) ==
    message.stockSymbolLong
        \o message.retailPriceImprovement

DecodeRetailPriceImprovementMessage(bytes) ==
    LET stockSymbolLong == ReadBytes(bytes, 8) IN IF ~stockSymbolLong.ok THEN Fail ELSE
    LET retailPriceImprovement == ReadBytes(stockSymbolLong.rest, 1) IN IF ~retailPriceImprovement.ok THEN Fail ELSE
    Ok([ stockSymbolLong        |-> stockSymbolLong.value,
         retailPriceImprovement |-> retailPriceImprovement.value ], retailPriceImprovement.rest)

ZeroRetailPriceImprovementMessage ==
    [ stockSymbolLong        |-> [i \in 1 .. 8 |-> 0],
      retailPriceImprovement |-> [i \in 1 .. 1 |-> 0] ]

(* Retail Price Improvement Message at zero, then each field in turn at the values it is checked at *)
CheckedRetailPriceImprovementMessage ==
    { ZeroRetailPriceImprovementMessage }
        \cup { [ZeroRetailPriceImprovementMessage EXCEPT !.stockSymbolLong = one] : one \in Sample(8) }
        \cup { [ZeroRetailPriceImprovementMessage EXCEPT !.retailPriceImprovement = one] : one \in Sample(1) }

(***************************************************************************)
(* Sequenced Message, selected by Sequenced Message Type                   *)
(***************************************************************************)

SymbolClearMessageCode == 115  \* "s"
AddOrderShortMessageCode == 65  \* "A"
AddOrderLongMessageCode == 100  \* "d"
AddOrderExtendedMessageCode == 49  \* "1"
OrderExecutedMessageCode == 69  \* "E"
OrderCancelMessageCode == 88  \* "X"
TradeShortMessageCode == 80  \* "P"
TradeLongMessageCode == 114  \* "r"
TradeExtendedMessageCode == 50  \* "2"
TradeBreakMessageCode == 66  \* "B"
TradingStatusMessageCode == 72  \* "H"
AuctionUpdateMessageCode == 73  \* "I"
ExtendedAuctionUpdateMessageCode == 51  \* "3"
AuctionSummaryMessageCode == 74  \* "J"
ExtendedAuctionSummaryMessageCode == 52  \* "4"
RetailPriceImprovementMessageCode == 82  \* "R"

SequencedMessage ==
    [ tag : {SymbolClearMessageCode}, body : SymbolClearMessage ]
        \cup [ tag : {AddOrderShortMessageCode}, body : AddOrderShortMessage ]
        \cup [ tag : {AddOrderLongMessageCode}, body : AddOrderLongMessage ]
        \cup [ tag : {AddOrderExtendedMessageCode}, body : AddOrderExtendedMessage ]
        \cup [ tag : {OrderExecutedMessageCode}, body : OrderExecutedMessage ]
        \cup [ tag : {OrderCancelMessageCode}, body : OrderCancelMessage ]
        \cup [ tag : {TradeShortMessageCode}, body : TradeShortMessage ]
        \cup [ tag : {TradeLongMessageCode}, body : TradeLongMessage ]
        \cup [ tag : {TradeExtendedMessageCode}, body : TradeExtendedMessage ]
        \cup [ tag : {TradeBreakMessageCode}, body : TradeBreakMessage ]
        \cup [ tag : {TradingStatusMessageCode}, body : TradingStatusMessage ]
        \cup [ tag : {AuctionUpdateMessageCode}, body : AuctionUpdateMessage ]
        \cup [ tag : {ExtendedAuctionUpdateMessageCode}, body : ExtendedAuctionUpdateMessage ]
        \cup [ tag : {AuctionSummaryMessageCode}, body : AuctionSummaryMessage ]
        \cup [ tag : {ExtendedAuctionSummaryMessageCode}, body : ExtendedAuctionSummaryMessage ]
        \cup [ tag : {RetailPriceImprovementMessageCode}, body : RetailPriceImprovementMessage ]

EncodeSequencedMessage(message) ==
    CASE message.tag = SymbolClearMessageCode -> EncodeSymbolClearMessage(message.body)
      [] message.tag = AddOrderShortMessageCode -> EncodeAddOrderShortMessage(message.body)
      [] message.tag = AddOrderLongMessageCode -> EncodeAddOrderLongMessage(message.body)
      [] message.tag = AddOrderExtendedMessageCode -> EncodeAddOrderExtendedMessage(message.body)
      [] message.tag = OrderExecutedMessageCode -> EncodeOrderExecutedMessage(message.body)
      [] message.tag = OrderCancelMessageCode -> EncodeOrderCancelMessage(message.body)
      [] message.tag = TradeShortMessageCode -> EncodeTradeShortMessage(message.body)
      [] message.tag = TradeLongMessageCode -> EncodeTradeLongMessage(message.body)
      [] message.tag = TradeExtendedMessageCode -> EncodeTradeExtendedMessage(message.body)
      [] message.tag = TradeBreakMessageCode -> EncodeTradeBreakMessage(message.body)
      [] message.tag = TradingStatusMessageCode -> EncodeTradingStatusMessage(message.body)
      [] message.tag = AuctionUpdateMessageCode -> EncodeAuctionUpdateMessage(message.body)
      [] message.tag = ExtendedAuctionUpdateMessageCode -> EncodeExtendedAuctionUpdateMessage(message.body)
      [] message.tag = AuctionSummaryMessageCode -> EncodeAuctionSummaryMessage(message.body)
      [] message.tag = ExtendedAuctionSummaryMessageCode -> EncodeExtendedAuctionSummaryMessage(message.body)
      [] message.tag = RetailPriceImprovementMessageCode -> EncodeRetailPriceImprovementMessage(message.body)

DecodeSequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = SymbolClearMessageCode -> DecodeSymbolClearMessage(bytes)
              [] tag = AddOrderShortMessageCode -> DecodeAddOrderShortMessage(bytes)
              [] tag = AddOrderLongMessageCode -> DecodeAddOrderLongMessage(bytes)
              [] tag = AddOrderExtendedMessageCode -> DecodeAddOrderExtendedMessage(bytes)
              [] tag = OrderExecutedMessageCode -> DecodeOrderExecutedMessage(bytes)
              [] tag = OrderCancelMessageCode -> DecodeOrderCancelMessage(bytes)
              [] tag = TradeShortMessageCode -> DecodeTradeShortMessage(bytes)
              [] tag = TradeLongMessageCode -> DecodeTradeLongMessage(bytes)
              [] tag = TradeExtendedMessageCode -> DecodeTradeExtendedMessage(bytes)
              [] tag = TradeBreakMessageCode -> DecodeTradeBreakMessage(bytes)
              [] tag = TradingStatusMessageCode -> DecodeTradingStatusMessage(bytes)
              [] tag = AuctionUpdateMessageCode -> DecodeAuctionUpdateMessage(bytes)
              [] tag = ExtendedAuctionUpdateMessageCode -> DecodeExtendedAuctionUpdateMessage(bytes)
              [] tag = AuctionSummaryMessageCode -> DecodeAuctionSummaryMessage(bytes)
              [] tag = ExtendedAuctionSummaryMessageCode -> DecodeExtendedAuctionSummaryMessage(bytes)
              [] tag = RetailPriceImprovementMessageCode -> DecodeRetailPriceImprovementMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSequencedMessage == [tag |-> SymbolClearMessageCode, body |-> ZeroSymbolClearMessage]

(* Each Sequenced Message in turn, at the values the message it names is checked at *)
CheckedSequencedMessage ==
    { [tag |-> SymbolClearMessageCode, body |-> one] : one \in CheckedSymbolClearMessage }
        \cup { [tag |-> AddOrderShortMessageCode, body |-> one] : one \in CheckedAddOrderShortMessage }
        \cup { [tag |-> AddOrderLongMessageCode, body |-> one] : one \in CheckedAddOrderLongMessage }
        \cup { [tag |-> AddOrderExtendedMessageCode, body |-> one] : one \in CheckedAddOrderExtendedMessage }
        \cup { [tag |-> OrderExecutedMessageCode, body |-> one] : one \in CheckedOrderExecutedMessage }
        \cup { [tag |-> OrderCancelMessageCode, body |-> one] : one \in CheckedOrderCancelMessage }
        \cup { [tag |-> TradeShortMessageCode, body |-> one] : one \in CheckedTradeShortMessage }
        \cup { [tag |-> TradeLongMessageCode, body |-> one] : one \in CheckedTradeLongMessage }
        \cup { [tag |-> TradeExtendedMessageCode, body |-> one] : one \in CheckedTradeExtendedMessage }
        \cup { [tag |-> TradeBreakMessageCode, body |-> one] : one \in CheckedTradeBreakMessage }
        \cup { [tag |-> TradingStatusMessageCode, body |-> one] : one \in CheckedTradingStatusMessage }
        \cup { [tag |-> AuctionUpdateMessageCode, body |-> one] : one \in CheckedAuctionUpdateMessage }
        \cup { [tag |-> ExtendedAuctionUpdateMessageCode, body |-> one] : one \in CheckedExtendedAuctionUpdateMessage }
        \cup { [tag |-> AuctionSummaryMessageCode, body |-> one] : one \in CheckedAuctionSummaryMessage }
        \cup { [tag |-> ExtendedAuctionSummaryMessageCode, body |-> one] : one \in CheckedExtendedAuctionSummaryMessage }
        \cup { [tag |-> RetailPriceImprovementMessageCode, body |-> one] : one \in CheckedRetailPriceImprovementMessage }

(***************************************************************************)
(* Sequenced Data Packet                                                   *)
(***************************************************************************)

SequencedDataPacket ==
    [ timestamp        : Sample(8),
      sequencedMessage : SequencedMessage ]

EncodeSequencedDataPacket(message) ==
    message.timestamp
        \o EncodeUIntBE(message.sequencedMessage.tag, 1)
        \o EncodeSequencedMessage(message.sequencedMessage)

DecodeSequencedDataPacket(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET sequencedMessageType == ReadUIntBE(timestamp.rest, 1) IN IF ~sequencedMessageType.ok THEN Fail ELSE
    LET sequencedMessage == DecodeSequencedMessage(sequencedMessageType.value, sequencedMessageType.rest) IN IF ~sequencedMessage.ok THEN Fail ELSE
    Ok([ timestamp        |-> timestamp.value,
         sequencedMessage |-> sequencedMessage.value ], sequencedMessage.rest)

ZeroSequencedDataPacket ==
    [ timestamp        |-> [i \in 1 .. 8 |-> 0],
      sequencedMessage |-> ZeroSequencedMessage ]

(* Sequenced Data Packet at zero, then each field in turn at the values it is checked at *)
CheckedSequencedDataPacket ==
    { ZeroSequencedDataPacket }
        \cup { [ZeroSequencedDataPacket EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSequencedDataPacket EXCEPT !.sequencedMessage = one] : one \in CheckedSequencedMessage }

(***************************************************************************)
(* Login Request Packet: 36 bytes                                          *)
(***************************************************************************)

LoginRequestPacket ==
    [ username                : Sample(6),
      password                : Sample(10),
      requestedSession        : Sample(10),
      requestedSequenceNumber : Sample(10) ]

EncodeLoginRequestPacket(message) ==
    message.username
        \o message.password
        \o message.requestedSession
        \o message.requestedSequenceNumber

DecodeLoginRequestPacket(bytes) ==
    LET username == ReadBytes(bytes, 6) IN IF ~username.ok THEN Fail ELSE
    LET password == ReadBytes(username.rest, 10) IN IF ~password.ok THEN Fail ELSE
    LET requestedSession == ReadBytes(password.rest, 10) IN IF ~requestedSession.ok THEN Fail ELSE
    LET requestedSequenceNumber == ReadBytes(requestedSession.rest, 10) IN IF ~requestedSequenceNumber.ok THEN Fail ELSE
    Ok([ username                |-> username.value,
         password                |-> password.value,
         requestedSession        |-> requestedSession.value,
         requestedSequenceNumber |-> requestedSequenceNumber.value ], requestedSequenceNumber.rest)

ZeroLoginRequestPacket ==
    [ username                |-> [i \in 1 .. 6 |-> 0],
      password                |-> [i \in 1 .. 10 |-> 0],
      requestedSession        |-> [i \in 1 .. 10 |-> 0],
      requestedSequenceNumber |-> [i \in 1 .. 10 |-> 0] ]

(* Login Request Packet at zero, then each field in turn at the values it is checked at *)
CheckedLoginRequestPacket ==
    { ZeroLoginRequestPacket }
        \cup { [ZeroLoginRequestPacket EXCEPT !.username = one] : one \in Sample(6) }
        \cup { [ZeroLoginRequestPacket EXCEPT !.password = one] : one \in Sample(10) }
        \cup { [ZeroLoginRequestPacket EXCEPT !.requestedSession = one] : one \in Sample(10) }
        \cup { [ZeroLoginRequestPacket EXCEPT !.requestedSequenceNumber = one] : one \in Sample(10) }

(***************************************************************************)
(* Unsequenced Data Packet                                                 *)
(***************************************************************************)

UnsequencedDataPacket ==
    [ unsequencedMessage : SampleBytes ]

EncodeUnsequencedDataPacket(message) ==
    message.unsequencedMessage

DecodeUnsequencedDataPacket(bytes) ==
    LET unsequencedMessage == Ok(bytes, << >>) IN IF ~unsequencedMessage.ok THEN Fail ELSE
    Ok([ unsequencedMessage |-> unsequencedMessage.value ], unsequencedMessage.rest)

ZeroUnsequencedDataPacket ==
    [ unsequencedMessage |-> << >> ]

(* Unsequenced Data Packet at zero, then each field in turn at the values it is checked at *)
CheckedUnsequencedDataPacket ==
    { ZeroUnsequencedDataPacket }
        \cup { [ZeroUnsequencedDataPacket EXCEPT !.unsequencedMessage = one] : one \in SampleBytes }

(***************************************************************************)
(* Payload, selected by Packet Type                                        *)
(***************************************************************************)

DebugPacketCode == 43  \* "+"
LoginAcceptedPacketCode == 65  \* "A"
LoginRejectedPacketCode == 74  \* "J"
SequencedDataPacketCode == 83  \* "S"
LoginRequestPacketCode == 76  \* "L"
UnsequencedDataPacketCode == 85  \* "U"

Payload ==
    [ tag : {DebugPacketCode}, body : DebugPacket ]
        \cup [ tag : {LoginAcceptedPacketCode}, body : LoginAcceptedPacket ]
        \cup [ tag : {LoginRejectedPacketCode}, body : LoginRejectedPacket ]
        \cup [ tag : {SequencedDataPacketCode}, body : SequencedDataPacket ]
        \cup [ tag : {LoginRequestPacketCode}, body : LoginRequestPacket ]
        \cup [ tag : {UnsequencedDataPacketCode}, body : UnsequencedDataPacket ]

EncodePayload(message) ==
    CASE message.tag = DebugPacketCode -> EncodeDebugPacket(message.body)
      [] message.tag = LoginAcceptedPacketCode -> EncodeLoginAcceptedPacket(message.body)
      [] message.tag = LoginRejectedPacketCode -> EncodeLoginRejectedPacket(message.body)
      [] message.tag = SequencedDataPacketCode -> EncodeSequencedDataPacket(message.body)
      [] message.tag = LoginRequestPacketCode -> EncodeLoginRequestPacket(message.body)
      [] message.tag = UnsequencedDataPacketCode -> EncodeUnsequencedDataPacket(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = DebugPacketCode -> DecodeDebugPacket(bytes)
              [] tag = LoginAcceptedPacketCode -> DecodeLoginAcceptedPacket(bytes)
              [] tag = LoginRejectedPacketCode -> DecodeLoginRejectedPacket(bytes)
              [] tag = SequencedDataPacketCode -> DecodeSequencedDataPacket(bytes)
              [] tag = LoginRequestPacketCode -> DecodeLoginRequestPacket(bytes)
              [] tag = UnsequencedDataPacketCode -> DecodeUnsequencedDataPacket(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> DebugPacketCode, body |-> one] : one \in CheckedDebugPacket }
        \cup { [tag |-> LoginAcceptedPacketCode, body |-> one] : one \in CheckedLoginAcceptedPacket }
        \cup { [tag |-> LoginRejectedPacketCode, body |-> one] : one \in CheckedLoginRejectedPacket }
        \cup { [tag |-> SequencedDataPacketCode, body |-> one] : one \in CheckedSequencedDataPacket }
        \cup { [tag |-> LoginRequestPacketCode, body |-> one] : one \in CheckedLoginRequestPacket }
        \cup { [tag |-> UnsequencedDataPacketCode, body |-> one] : one \in CheckedUnsequencedDataPacket }

(***************************************************************************)
(* Frame, closed by Soup Lf                                                *)
(***************************************************************************)

Frame ==
    [ payload : Payload ]

EncodeFrameBody(message) ==
    EncodeUIntBE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

(* Soup Lf closes the record, so it is written after the body it closes *)
EncodeFrame(message) == EncodeFrameBody(message) \o <<10>>

DecodeFrameBody(bytes) ==
    LET packetType == ReadUIntBE(bytes, 1) IN IF ~packetType.ok THEN Fail ELSE
    LET payload == DecodePayload(packetType.value, packetType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

(* Soup Lf closes the record, so the body is the bytes ahead of the first one *)
DecodeFrame(bytes) ==
    LET closed == ReadClosed(bytes, 10) IN IF ~closed.ok THEN Fail ELSE
    LET body == DecodeFrameBody(closed.value)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, closed.rest)

ZeroFrame ==
    [ payload |-> ZeroPayload ]

(* Frame at zero, then each field in turn at the values it is checked at *)
CheckedFrame ==
    { ZeroFrame }
        \cup { [ZeroFrame EXCEPT !.payload = one] : one \in CheckedPayload }

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
    { [ZeroFrame EXCEPT !.payload = [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]],
      [ZeroFrame EXCEPT !.payload = [tag |-> LoginAcceptedPacketCode, body |-> ZeroLoginAcceptedPacket]],
      [ZeroFrame EXCEPT !.payload = [tag |-> LoginRejectedPacketCode, body |-> ZeroLoginRejectedPacket]],
      [ZeroFrame EXCEPT !.payload = [tag |-> SequencedDataPacketCode, body |-> ZeroSequencedDataPacket]],
      [ZeroFrame EXCEPT !.payload = [tag |-> LoginRequestPacketCode, body |-> ZeroLoginRequestPacket]],
      [ZeroFrame EXCEPT !.payload = [tag |-> UnsequencedDataPacketCode, body |-> ZeroUnsequencedDataPacket]] }

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

(* Every Symbol Clear Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolClearMessage ==
    \A message \in CheckedSymbolClearMessage :
        LET read == DecodeSymbolClearMessage(EncodeSymbolClearMessage(message))
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

(* Every Add Order Extended Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderExtendedMessage ==
    \A message \in CheckedAddOrderExtendedMessage :
        LET read == DecodeAddOrderExtendedMessage(EncodeAddOrderExtendedMessage(message))
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

(* Every Order Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelMessage ==
    \A message \in CheckedOrderCancelMessage :
        LET read == DecodeOrderCancelMessage(EncodeOrderCancelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Short Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeShortMessage ==
    \A message \in CheckedTradeShortMessage :
        LET read == DecodeTradeShortMessage(EncodeTradeShortMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Long Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeLongMessage ==
    \A message \in CheckedTradeLongMessage :
        LET read == DecodeTradeLongMessage(EncodeTradeLongMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Extended Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeExtendedMessage ==
    \A message \in CheckedTradeExtendedMessage :
        LET read == DecodeTradeExtendedMessage(EncodeTradeExtendedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Break Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBreakMessage ==
    \A message \in CheckedTradeBreakMessage :
        LET read == DecodeTradeBreakMessage(EncodeTradeBreakMessage(message))
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

(* Every Auction Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionUpdateMessage ==
    \A message \in CheckedAuctionUpdateMessage :
        LET read == DecodeAuctionUpdateMessage(EncodeAuctionUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Extended Auction Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExtendedAuctionUpdateMessage ==
    \A message \in CheckedExtendedAuctionUpdateMessage :
        LET read == DecodeExtendedAuctionUpdateMessage(EncodeExtendedAuctionUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionSummaryMessage ==
    \A message \in CheckedAuctionSummaryMessage :
        LET read == DecodeAuctionSummaryMessage(EncodeAuctionSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Extended Auction Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExtendedAuctionSummaryMessage ==
    \A message \in CheckedExtendedAuctionSummaryMessage :
        LET read == DecodeExtendedAuctionSummaryMessage(EncodeExtendedAuctionSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Retail Price Improvement Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRetailPriceImprovementMessage ==
    \A message \in CheckedRetailPriceImprovementMessage :
        LET read == DecodeRetailPriceImprovementMessage(EncodeRetailPriceImprovementMessage(message))
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

(* Every Login Request Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRequestPacket ==
    \A message \in CheckedLoginRequestPacket :
        LET read == DecodeLoginRequestPacket(EncodeLoginRequestPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Unsequenced Data Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripUnsequencedDataPacket ==
    \A message \in CheckedUnsequencedDataPacket :
        LET read == DecodeUnsequencedDataPacket(EncodeUnsequencedDataPacket(message))
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

(* A Sequenced Message is selected by the Sequenced Message Type it is written under *)
SelectsSequencedMessage ==
    \A message \in CheckedSequencedMessage :
        LET sent == EncodeSequencedMessage(message)
            read == DecodeSequencedMessage(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Payload is selected by the Packet Type it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET sent == EncodePayload(message)
            read == DecodePayload(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* No Frame writes the Soup Lf that closes it inside its own body, so *)
(* the first one found is the end of the record. Checked over the messages below, which *)
(* is weaker than a proof that none could. *)
ClosesFrame ==
    \A message \in CheckedFrame :
        LET body == EncodeFrameBody(message)
        IN  \A i \in 1 .. Len(body) : body[i] # 10

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
