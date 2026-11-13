----------------- MODULE CxeEquities_TcpDepthOfBook_v4_16 ------------------
(***************************************************************************)
(* Chicago Board Options Exchange Tcp Depth Of Book v4.16                  *)
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
    [ symbolLong : Sample(8) ]

EncodeSymbolClearMessage(message) ==
    message.symbolLong

DecodeSymbolClearMessage(bytes) ==
    LET symbolLong == ReadBytes(bytes, 8) IN IF ~symbolLong.ok THEN Fail ELSE
    Ok([ symbolLong |-> symbolLong.value ], symbolLong.rest)

ZeroSymbolClearMessage ==
    [ symbolLong |-> [i \in 1 .. 8 |-> 0] ]

(* Symbol Clear Message at zero, then each field in turn at the values it is checked at *)
CheckedSymbolClearMessage ==
    { ZeroSymbolClearMessage }
        \cup { [ZeroSymbolClearMessage EXCEPT !.symbolLong = one] : one \in Sample(8) }

(***************************************************************************)
(* Add Order Message: 36 bytes                                             *)
(***************************************************************************)

AddOrderMessage ==
    [ orderId       : Sample(12),
      sideIndicator : Sample(1),
      sharesShort   : Sample(6),
      symbolShort   : Sample(6),
      priceShort    : Sample(10),
      display       : Sample(1) ]

EncodeAddOrderMessage(message) ==
    message.orderId
        \o message.sideIndicator
        \o message.sharesShort
        \o message.symbolShort
        \o message.priceShort
        \o message.display

DecodeAddOrderMessage(bytes) ==
    LET orderId == ReadBytes(bytes, 12) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET sharesShort == ReadBytes(sideIndicator.rest, 6) IN IF ~sharesShort.ok THEN Fail ELSE
    LET symbolShort == ReadBytes(sharesShort.rest, 6) IN IF ~symbolShort.ok THEN Fail ELSE
    LET priceShort == ReadBytes(symbolShort.rest, 10) IN IF ~priceShort.ok THEN Fail ELSE
    LET display == ReadBytes(priceShort.rest, 1) IN IF ~display.ok THEN Fail ELSE
    Ok([ orderId       |-> orderId.value,
         sideIndicator |-> sideIndicator.value,
         sharesShort   |-> sharesShort.value,
         symbolShort   |-> symbolShort.value,
         priceShort    |-> priceShort.value,
         display       |-> display.value ], display.rest)

ZeroAddOrderMessage ==
    [ orderId       |-> [i \in 1 .. 12 |-> 0],
      sideIndicator |-> [i \in 1 .. 1 |-> 0],
      sharesShort   |-> [i \in 1 .. 6 |-> 0],
      symbolShort   |-> [i \in 1 .. 6 |-> 0],
      priceShort    |-> [i \in 1 .. 10 |-> 0],
      display       |-> [i \in 1 .. 1 |-> 0] ]

(* Add Order Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderMessage ==
    { ZeroAddOrderMessage }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderId = one] : one \in Sample(12) }
        \cup { [ZeroAddOrderMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.sharesShort = one] : one \in Sample(6) }
        \cup { [ZeroAddOrderMessage EXCEPT !.symbolShort = one] : one \in Sample(6) }
        \cup { [ZeroAddOrderMessage EXCEPT !.priceShort = one] : one \in Sample(10) }
        \cup { [ZeroAddOrderMessage EXCEPT !.display = one] : one \in Sample(1) }

(***************************************************************************)
(* Add Order Message Long Form: 51 bytes                                   *)
(***************************************************************************)

AddOrderMessageLongForm ==
    [ orderId       : Sample(12),
      sideIndicator : Sample(1),
      sharesLong    : Sample(10),
      symbolLong    : Sample(8),
      priceLong     : Sample(19),
      display       : Sample(1) ]

EncodeAddOrderMessageLongForm(message) ==
    message.orderId
        \o message.sideIndicator
        \o message.sharesLong
        \o message.symbolLong
        \o message.priceLong
        \o message.display

DecodeAddOrderMessageLongForm(bytes) ==
    LET orderId == ReadBytes(bytes, 12) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET sharesLong == ReadBytes(sideIndicator.rest, 10) IN IF ~sharesLong.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(sharesLong.rest, 8) IN IF ~symbolLong.ok THEN Fail ELSE
    LET priceLong == ReadBytes(symbolLong.rest, 19) IN IF ~priceLong.ok THEN Fail ELSE
    LET display == ReadBytes(priceLong.rest, 1) IN IF ~display.ok THEN Fail ELSE
    Ok([ orderId       |-> orderId.value,
         sideIndicator |-> sideIndicator.value,
         sharesLong    |-> sharesLong.value,
         symbolLong    |-> symbolLong.value,
         priceLong     |-> priceLong.value,
         display       |-> display.value ], display.rest)

ZeroAddOrderMessageLongForm ==
    [ orderId       |-> [i \in 1 .. 12 |-> 0],
      sideIndicator |-> [i \in 1 .. 1 |-> 0],
      sharesLong    |-> [i \in 1 .. 10 |-> 0],
      symbolLong    |-> [i \in 1 .. 8 |-> 0],
      priceLong     |-> [i \in 1 .. 19 |-> 0],
      display       |-> [i \in 1 .. 1 |-> 0] ]

(* Add Order Message Long Form at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderMessageLongForm ==
    { ZeroAddOrderMessageLongForm }
        \cup { [ZeroAddOrderMessageLongForm EXCEPT !.orderId = one] : one \in Sample(12) }
        \cup { [ZeroAddOrderMessageLongForm EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessageLongForm EXCEPT !.sharesLong = one] : one \in Sample(10) }
        \cup { [ZeroAddOrderMessageLongForm EXCEPT !.symbolLong = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessageLongForm EXCEPT !.priceLong = one] : one \in Sample(19) }
        \cup { [ZeroAddOrderMessageLongForm EXCEPT !.display = one] : one \in Sample(1) }

(***************************************************************************)
(* Add Order Expanded: 55 bytes                                            *)
(***************************************************************************)

AddOrderExpanded ==
    [ orderId       : Sample(12),
      sideIndicator : Sample(1),
      quantity      : Sample(10),
      symbolLong    : Sample(8),
      priceLong     : Sample(19),
      type          : Sample(1),
      participantId : Sample(4) ]

EncodeAddOrderExpanded(message) ==
    message.orderId
        \o message.sideIndicator
        \o message.quantity
        \o message.symbolLong
        \o message.priceLong
        \o message.type
        \o message.participantId

DecodeAddOrderExpanded(bytes) ==
    LET orderId == ReadBytes(bytes, 12) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET quantity == ReadBytes(sideIndicator.rest, 10) IN IF ~quantity.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(quantity.rest, 8) IN IF ~symbolLong.ok THEN Fail ELSE
    LET priceLong == ReadBytes(symbolLong.rest, 19) IN IF ~priceLong.ok THEN Fail ELSE
    LET type == ReadBytes(priceLong.rest, 1) IN IF ~type.ok THEN Fail ELSE
    LET participantId == ReadBytes(type.rest, 4) IN IF ~participantId.ok THEN Fail ELSE
    Ok([ orderId       |-> orderId.value,
         sideIndicator |-> sideIndicator.value,
         quantity      |-> quantity.value,
         symbolLong    |-> symbolLong.value,
         priceLong     |-> priceLong.value,
         type          |-> type.value,
         participantId |-> participantId.value ], participantId.rest)

ZeroAddOrderExpanded ==
    [ orderId       |-> [i \in 1 .. 12 |-> 0],
      sideIndicator |-> [i \in 1 .. 1 |-> 0],
      quantity      |-> [i \in 1 .. 10 |-> 0],
      symbolLong    |-> [i \in 1 .. 8 |-> 0],
      priceLong     |-> [i \in 1 .. 19 |-> 0],
      type          |-> [i \in 1 .. 1 |-> 0],
      participantId |-> [i \in 1 .. 4 |-> 0] ]

(* Add Order Expanded at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderExpanded ==
    { ZeroAddOrderExpanded }
        \cup { [ZeroAddOrderExpanded EXCEPT !.orderId = one] : one \in Sample(12) }
        \cup { [ZeroAddOrderExpanded EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderExpanded EXCEPT !.quantity = one] : one \in Sample(10) }
        \cup { [ZeroAddOrderExpanded EXCEPT !.symbolLong = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderExpanded EXCEPT !.priceLong = one] : one \in Sample(19) }
        \cup { [ZeroAddOrderExpanded EXCEPT !.type = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderExpanded EXCEPT !.participantId = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Executed Message: 34 bytes                                        *)
(***************************************************************************)

OrderExecutedMessage ==
    [ orderId             : Sample(12),
      executedSharesShort : Sample(6),
      executionId         : Sample(12),
      executionFlags      : Sample(4) ]

EncodeOrderExecutedMessage(message) ==
    message.orderId
        \o message.executedSharesShort
        \o message.executionId
        \o message.executionFlags

DecodeOrderExecutedMessage(bytes) ==
    LET orderId == ReadBytes(bytes, 12) IN IF ~orderId.ok THEN Fail ELSE
    LET executedSharesShort == ReadBytes(orderId.rest, 6) IN IF ~executedSharesShort.ok THEN Fail ELSE
    LET executionId == ReadBytes(executedSharesShort.rest, 12) IN IF ~executionId.ok THEN Fail ELSE
    LET executionFlags == ReadBytes(executionId.rest, 4) IN IF ~executionFlags.ok THEN Fail ELSE
    Ok([ orderId             |-> orderId.value,
         executedSharesShort |-> executedSharesShort.value,
         executionId         |-> executionId.value,
         executionFlags      |-> executionFlags.value ], executionFlags.rest)

ZeroOrderExecutedMessage ==
    [ orderId             |-> [i \in 1 .. 12 |-> 0],
      executedSharesShort |-> [i \in 1 .. 6 |-> 0],
      executionId         |-> [i \in 1 .. 12 |-> 0],
      executionFlags      |-> [i \in 1 .. 4 |-> 0] ]

(* Order Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedMessage ==
    { ZeroOrderExecutedMessage }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.orderId = one] : one \in Sample(12) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.executedSharesShort = one] : one \in Sample(6) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.executionId = one] : one \in Sample(12) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.executionFlags = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Executed Message Long Form: 38 bytes                              *)
(***************************************************************************)

OrderExecutedMessageLongForm ==
    [ orderId            : Sample(12),
      executedSharesLong : Sample(10),
      executionId        : Sample(12),
      executionFlags     : Sample(4) ]

EncodeOrderExecutedMessageLongForm(message) ==
    message.orderId
        \o message.executedSharesLong
        \o message.executionId
        \o message.executionFlags

DecodeOrderExecutedMessageLongForm(bytes) ==
    LET orderId == ReadBytes(bytes, 12) IN IF ~orderId.ok THEN Fail ELSE
    LET executedSharesLong == ReadBytes(orderId.rest, 10) IN IF ~executedSharesLong.ok THEN Fail ELSE
    LET executionId == ReadBytes(executedSharesLong.rest, 12) IN IF ~executionId.ok THEN Fail ELSE
    LET executionFlags == ReadBytes(executionId.rest, 4) IN IF ~executionFlags.ok THEN Fail ELSE
    Ok([ orderId            |-> orderId.value,
         executedSharesLong |-> executedSharesLong.value,
         executionId        |-> executionId.value,
         executionFlags     |-> executionFlags.value ], executionFlags.rest)

ZeroOrderExecutedMessageLongForm ==
    [ orderId            |-> [i \in 1 .. 12 |-> 0],
      executedSharesLong |-> [i \in 1 .. 10 |-> 0],
      executionId        |-> [i \in 1 .. 12 |-> 0],
      executionFlags     |-> [i \in 1 .. 4 |-> 0] ]

(* Order Executed Message Long Form at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedMessageLongForm ==
    { ZeroOrderExecutedMessageLongForm }
        \cup { [ZeroOrderExecutedMessageLongForm EXCEPT !.orderId = one] : one \in Sample(12) }
        \cup { [ZeroOrderExecutedMessageLongForm EXCEPT !.executedSharesLong = one] : one \in Sample(10) }
        \cup { [ZeroOrderExecutedMessageLongForm EXCEPT !.executionId = one] : one \in Sample(12) }
        \cup { [ZeroOrderExecutedMessageLongForm EXCEPT !.executionFlags = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Cancel Message: 18 bytes                                          *)
(***************************************************************************)

OrderCancelMessage ==
    [ orderId              : Sample(12),
      cancelledSharesShort : Sample(6) ]

EncodeOrderCancelMessage(message) ==
    message.orderId
        \o message.cancelledSharesShort

DecodeOrderCancelMessage(bytes) ==
    LET orderId == ReadBytes(bytes, 12) IN IF ~orderId.ok THEN Fail ELSE
    LET cancelledSharesShort == ReadBytes(orderId.rest, 6) IN IF ~cancelledSharesShort.ok THEN Fail ELSE
    Ok([ orderId              |-> orderId.value,
         cancelledSharesShort |-> cancelledSharesShort.value ], cancelledSharesShort.rest)

ZeroOrderCancelMessage ==
    [ orderId              |-> [i \in 1 .. 12 |-> 0],
      cancelledSharesShort |-> [i \in 1 .. 6 |-> 0] ]

(* Order Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelMessage ==
    { ZeroOrderCancelMessage }
        \cup { [ZeroOrderCancelMessage EXCEPT !.orderId = one] : one \in Sample(12) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.cancelledSharesShort = one] : one \in Sample(6) }

(***************************************************************************)
(* Order Cancel Message Long Form: 22 bytes                                *)
(***************************************************************************)

OrderCancelMessageLongForm ==
    [ orderId             : Sample(12),
      cancelledSharesLong : Sample(10) ]

EncodeOrderCancelMessageLongForm(message) ==
    message.orderId
        \o message.cancelledSharesLong

DecodeOrderCancelMessageLongForm(bytes) ==
    LET orderId == ReadBytes(bytes, 12) IN IF ~orderId.ok THEN Fail ELSE
    LET cancelledSharesLong == ReadBytes(orderId.rest, 10) IN IF ~cancelledSharesLong.ok THEN Fail ELSE
    Ok([ orderId             |-> orderId.value,
         cancelledSharesLong |-> cancelledSharesLong.value ], cancelledSharesLong.rest)

ZeroOrderCancelMessageLongForm ==
    [ orderId             |-> [i \in 1 .. 12 |-> 0],
      cancelledSharesLong |-> [i \in 1 .. 10 |-> 0] ]

(* Order Cancel Message Long Form at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelMessageLongForm ==
    { ZeroOrderCancelMessageLongForm }
        \cup { [ZeroOrderCancelMessageLongForm EXCEPT !.orderId = one] : one \in Sample(12) }
        \cup { [ZeroOrderCancelMessageLongForm EXCEPT !.cancelledSharesLong = one] : one \in Sample(10) }

(***************************************************************************)
(* Trade Message: 52 bytes                                                 *)
(***************************************************************************)

TradeMessage ==
    [ orderId       : Sample(12),
      sideIndicator : Sample(1),
      sharesShort   : Sample(6),
      symbolShort   : Sample(6),
      priceShort    : Sample(10),
      executionId   : Sample(12),
      tradeFlags    : Sample(5) ]

EncodeTradeMessage(message) ==
    message.orderId
        \o message.sideIndicator
        \o message.sharesShort
        \o message.symbolShort
        \o message.priceShort
        \o message.executionId
        \o message.tradeFlags

DecodeTradeMessage(bytes) ==
    LET orderId == ReadBytes(bytes, 12) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET sharesShort == ReadBytes(sideIndicator.rest, 6) IN IF ~sharesShort.ok THEN Fail ELSE
    LET symbolShort == ReadBytes(sharesShort.rest, 6) IN IF ~symbolShort.ok THEN Fail ELSE
    LET priceShort == ReadBytes(symbolShort.rest, 10) IN IF ~priceShort.ok THEN Fail ELSE
    LET executionId == ReadBytes(priceShort.rest, 12) IN IF ~executionId.ok THEN Fail ELSE
    LET tradeFlags == ReadBytes(executionId.rest, 5) IN IF ~tradeFlags.ok THEN Fail ELSE
    Ok([ orderId       |-> orderId.value,
         sideIndicator |-> sideIndicator.value,
         sharesShort   |-> sharesShort.value,
         symbolShort   |-> symbolShort.value,
         priceShort    |-> priceShort.value,
         executionId   |-> executionId.value,
         tradeFlags    |-> tradeFlags.value ], tradeFlags.rest)

ZeroTradeMessage ==
    [ orderId       |-> [i \in 1 .. 12 |-> 0],
      sideIndicator |-> [i \in 1 .. 1 |-> 0],
      sharesShort   |-> [i \in 1 .. 6 |-> 0],
      symbolShort   |-> [i \in 1 .. 6 |-> 0],
      priceShort    |-> [i \in 1 .. 10 |-> 0],
      executionId   |-> [i \in 1 .. 12 |-> 0],
      tradeFlags    |-> [i \in 1 .. 5 |-> 0] ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.orderId = one] : one \in Sample(12) }
        \cup { [ZeroTradeMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.sharesShort = one] : one \in Sample(6) }
        \cup { [ZeroTradeMessage EXCEPT !.symbolShort = one] : one \in Sample(6) }
        \cup { [ZeroTradeMessage EXCEPT !.priceShort = one] : one \in Sample(10) }
        \cup { [ZeroTradeMessage EXCEPT !.executionId = one] : one \in Sample(12) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeFlags = one] : one \in Sample(5) }

(***************************************************************************)
(* Trade Message Long Form: 67 bytes                                       *)
(***************************************************************************)

TradeMessageLongForm ==
    [ orderId       : Sample(12),
      sideIndicator : Sample(1),
      sharesLong    : Sample(10),
      symbolLong    : Sample(8),
      priceLong     : Sample(19),
      executionId   : Sample(12),
      tradeFlags    : Sample(5) ]

EncodeTradeMessageLongForm(message) ==
    message.orderId
        \o message.sideIndicator
        \o message.sharesLong
        \o message.symbolLong
        \o message.priceLong
        \o message.executionId
        \o message.tradeFlags

DecodeTradeMessageLongForm(bytes) ==
    LET orderId == ReadBytes(bytes, 12) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET sharesLong == ReadBytes(sideIndicator.rest, 10) IN IF ~sharesLong.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(sharesLong.rest, 8) IN IF ~symbolLong.ok THEN Fail ELSE
    LET priceLong == ReadBytes(symbolLong.rest, 19) IN IF ~priceLong.ok THEN Fail ELSE
    LET executionId == ReadBytes(priceLong.rest, 12) IN IF ~executionId.ok THEN Fail ELSE
    LET tradeFlags == ReadBytes(executionId.rest, 5) IN IF ~tradeFlags.ok THEN Fail ELSE
    Ok([ orderId       |-> orderId.value,
         sideIndicator |-> sideIndicator.value,
         sharesLong    |-> sharesLong.value,
         symbolLong    |-> symbolLong.value,
         priceLong     |-> priceLong.value,
         executionId   |-> executionId.value,
         tradeFlags    |-> tradeFlags.value ], tradeFlags.rest)

ZeroTradeMessageLongForm ==
    [ orderId       |-> [i \in 1 .. 12 |-> 0],
      sideIndicator |-> [i \in 1 .. 1 |-> 0],
      sharesLong    |-> [i \in 1 .. 10 |-> 0],
      symbolLong    |-> [i \in 1 .. 8 |-> 0],
      priceLong     |-> [i \in 1 .. 19 |-> 0],
      executionId   |-> [i \in 1 .. 12 |-> 0],
      tradeFlags    |-> [i \in 1 .. 5 |-> 0] ]

(* Trade Message Long Form at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessageLongForm ==
    { ZeroTradeMessageLongForm }
        \cup { [ZeroTradeMessageLongForm EXCEPT !.orderId = one] : one \in Sample(12) }
        \cup { [ZeroTradeMessageLongForm EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessageLongForm EXCEPT !.sharesLong = one] : one \in Sample(10) }
        \cup { [ZeroTradeMessageLongForm EXCEPT !.symbolLong = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessageLongForm EXCEPT !.priceLong = one] : one \in Sample(19) }
        \cup { [ZeroTradeMessageLongForm EXCEPT !.executionId = one] : one \in Sample(12) }
        \cup { [ZeroTradeMessageLongForm EXCEPT !.tradeFlags = one] : one \in Sample(5) }

(***************************************************************************)
(* Trade Message Extended Form: 89 bytes                                   *)
(***************************************************************************)

TradeMessageExtendedForm ==
    [ sharesExtended           : Sample(12),
      symbolLong               : Sample(8),
      priceLong                : Sample(19),
      tradeId                  : Sample(12),
      tradeDate                : Sample(8),
      tradeTime                : Sample(8),
      executionVenue           : Sample(4),
      currency                 : Sample(3),
      cboeTradeTimingIndicator : Sample(1),
      extendedTradeFlags       : Sample(14) ]

EncodeTradeMessageExtendedForm(message) ==
    message.sharesExtended
        \o message.symbolLong
        \o message.priceLong
        \o message.tradeId
        \o message.tradeDate
        \o message.tradeTime
        \o message.executionVenue
        \o message.currency
        \o message.cboeTradeTimingIndicator
        \o message.extendedTradeFlags

DecodeTradeMessageExtendedForm(bytes) ==
    LET sharesExtended == ReadBytes(bytes, 12) IN IF ~sharesExtended.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(sharesExtended.rest, 8) IN IF ~symbolLong.ok THEN Fail ELSE
    LET priceLong == ReadBytes(symbolLong.rest, 19) IN IF ~priceLong.ok THEN Fail ELSE
    LET tradeId == ReadBytes(priceLong.rest, 12) IN IF ~tradeId.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(tradeId.rest, 8) IN IF ~tradeDate.ok THEN Fail ELSE
    LET tradeTime == ReadBytes(tradeDate.rest, 8) IN IF ~tradeTime.ok THEN Fail ELSE
    LET executionVenue == ReadBytes(tradeTime.rest, 4) IN IF ~executionVenue.ok THEN Fail ELSE
    LET currency == ReadBytes(executionVenue.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET cboeTradeTimingIndicator == ReadBytes(currency.rest, 1) IN IF ~cboeTradeTimingIndicator.ok THEN Fail ELSE
    LET extendedTradeFlags == ReadBytes(cboeTradeTimingIndicator.rest, 14) IN IF ~extendedTradeFlags.ok THEN Fail ELSE
    Ok([ sharesExtended           |-> sharesExtended.value,
         symbolLong               |-> symbolLong.value,
         priceLong                |-> priceLong.value,
         tradeId                  |-> tradeId.value,
         tradeDate                |-> tradeDate.value,
         tradeTime                |-> tradeTime.value,
         executionVenue           |-> executionVenue.value,
         currency                 |-> currency.value,
         cboeTradeTimingIndicator |-> cboeTradeTimingIndicator.value,
         extendedTradeFlags       |-> extendedTradeFlags.value ], extendedTradeFlags.rest)

ZeroTradeMessageExtendedForm ==
    [ sharesExtended           |-> [i \in 1 .. 12 |-> 0],
      symbolLong               |-> [i \in 1 .. 8 |-> 0],
      priceLong                |-> [i \in 1 .. 19 |-> 0],
      tradeId                  |-> [i \in 1 .. 12 |-> 0],
      tradeDate                |-> [i \in 1 .. 8 |-> 0],
      tradeTime                |-> [i \in 1 .. 8 |-> 0],
      executionVenue           |-> [i \in 1 .. 4 |-> 0],
      currency                 |-> [i \in 1 .. 3 |-> 0],
      cboeTradeTimingIndicator |-> [i \in 1 .. 1 |-> 0],
      extendedTradeFlags       |-> [i \in 1 .. 14 |-> 0] ]

(* Trade Message Extended Form at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessageExtendedForm ==
    { ZeroTradeMessageExtendedForm }
        \cup { [ZeroTradeMessageExtendedForm EXCEPT !.sharesExtended = one] : one \in Sample(12) }
        \cup { [ZeroTradeMessageExtendedForm EXCEPT !.symbolLong = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessageExtendedForm EXCEPT !.priceLong = one] : one \in Sample(19) }
        \cup { [ZeroTradeMessageExtendedForm EXCEPT !.tradeId = one] : one \in Sample(12) }
        \cup { [ZeroTradeMessageExtendedForm EXCEPT !.tradeDate = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessageExtendedForm EXCEPT !.tradeTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessageExtendedForm EXCEPT !.executionVenue = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessageExtendedForm EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroTradeMessageExtendedForm EXCEPT !.cboeTradeTimingIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessageExtendedForm EXCEPT !.extendedTradeFlags = one] : one \in Sample(14) }

(***************************************************************************)
(* Trade Message Unknown Symbol: 93 bytes                                  *)
(***************************************************************************)

TradeMessageUnknownSymbol ==
    [ sharesExtended           : Sample(12),
      symbolExtended           : Sample(12),
      priceLong                : Sample(19),
      tradeId                  : Sample(12),
      tradeDate                : Sample(8),
      tradeTime                : Sample(8),
      executionVenue           : Sample(4),
      currency                 : Sample(3),
      cboeTradeTimingIndicator : Sample(1),
      extendedTradeFlags       : Sample(14) ]

EncodeTradeMessageUnknownSymbol(message) ==
    message.sharesExtended
        \o message.symbolExtended
        \o message.priceLong
        \o message.tradeId
        \o message.tradeDate
        \o message.tradeTime
        \o message.executionVenue
        \o message.currency
        \o message.cboeTradeTimingIndicator
        \o message.extendedTradeFlags

DecodeTradeMessageUnknownSymbol(bytes) ==
    LET sharesExtended == ReadBytes(bytes, 12) IN IF ~sharesExtended.ok THEN Fail ELSE
    LET symbolExtended == ReadBytes(sharesExtended.rest, 12) IN IF ~symbolExtended.ok THEN Fail ELSE
    LET priceLong == ReadBytes(symbolExtended.rest, 19) IN IF ~priceLong.ok THEN Fail ELSE
    LET tradeId == ReadBytes(priceLong.rest, 12) IN IF ~tradeId.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(tradeId.rest, 8) IN IF ~tradeDate.ok THEN Fail ELSE
    LET tradeTime == ReadBytes(tradeDate.rest, 8) IN IF ~tradeTime.ok THEN Fail ELSE
    LET executionVenue == ReadBytes(tradeTime.rest, 4) IN IF ~executionVenue.ok THEN Fail ELSE
    LET currency == ReadBytes(executionVenue.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET cboeTradeTimingIndicator == ReadBytes(currency.rest, 1) IN IF ~cboeTradeTimingIndicator.ok THEN Fail ELSE
    LET extendedTradeFlags == ReadBytes(cboeTradeTimingIndicator.rest, 14) IN IF ~extendedTradeFlags.ok THEN Fail ELSE
    Ok([ sharesExtended           |-> sharesExtended.value,
         symbolExtended           |-> symbolExtended.value,
         priceLong                |-> priceLong.value,
         tradeId                  |-> tradeId.value,
         tradeDate                |-> tradeDate.value,
         tradeTime                |-> tradeTime.value,
         executionVenue           |-> executionVenue.value,
         currency                 |-> currency.value,
         cboeTradeTimingIndicator |-> cboeTradeTimingIndicator.value,
         extendedTradeFlags       |-> extendedTradeFlags.value ], extendedTradeFlags.rest)

ZeroTradeMessageUnknownSymbol ==
    [ sharesExtended           |-> [i \in 1 .. 12 |-> 0],
      symbolExtended           |-> [i \in 1 .. 12 |-> 0],
      priceLong                |-> [i \in 1 .. 19 |-> 0],
      tradeId                  |-> [i \in 1 .. 12 |-> 0],
      tradeDate                |-> [i \in 1 .. 8 |-> 0],
      tradeTime                |-> [i \in 1 .. 8 |-> 0],
      executionVenue           |-> [i \in 1 .. 4 |-> 0],
      currency                 |-> [i \in 1 .. 3 |-> 0],
      cboeTradeTimingIndicator |-> [i \in 1 .. 1 |-> 0],
      extendedTradeFlags       |-> [i \in 1 .. 14 |-> 0] ]

(* Trade Message Unknown Symbol at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessageUnknownSymbol ==
    { ZeroTradeMessageUnknownSymbol }
        \cup { [ZeroTradeMessageUnknownSymbol EXCEPT !.sharesExtended = one] : one \in Sample(12) }
        \cup { [ZeroTradeMessageUnknownSymbol EXCEPT !.symbolExtended = one] : one \in Sample(12) }
        \cup { [ZeroTradeMessageUnknownSymbol EXCEPT !.priceLong = one] : one \in Sample(19) }
        \cup { [ZeroTradeMessageUnknownSymbol EXCEPT !.tradeId = one] : one \in Sample(12) }
        \cup { [ZeroTradeMessageUnknownSymbol EXCEPT !.tradeDate = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessageUnknownSymbol EXCEPT !.tradeTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessageUnknownSymbol EXCEPT !.executionVenue = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessageUnknownSymbol EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroTradeMessageUnknownSymbol EXCEPT !.cboeTradeTimingIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessageUnknownSymbol EXCEPT !.extendedTradeFlags = one] : one \in Sample(14) }

(***************************************************************************)
(* Trading Status Message: 12 bytes                                        *)
(***************************************************************************)

TradingStatusMessage ==
    [ symbolLong : Sample(8),
      status     : Sample(1),
      reserved   : Sample(3) ]

EncodeTradingStatusMessage(message) ==
    message.symbolLong
        \o message.status
        \o message.reserved

DecodeTradingStatusMessage(bytes) ==
    LET symbolLong == ReadBytes(bytes, 8) IN IF ~symbolLong.ok THEN Fail ELSE
    LET status == ReadBytes(symbolLong.rest, 1) IN IF ~status.ok THEN Fail ELSE
    LET reserved == ReadBytes(status.rest, 3) IN IF ~reserved.ok THEN Fail ELSE
    Ok([ symbolLong |-> symbolLong.value,
         status     |-> status.value,
         reserved   |-> reserved.value ], reserved.rest)

ZeroTradingStatusMessage ==
    [ symbolLong |-> [i \in 1 .. 8 |-> 0],
      status     |-> [i \in 1 .. 1 |-> 0],
      reserved   |-> [i \in 1 .. 3 |-> 0] ]

(* Trading Status Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingStatusMessage ==
    { ZeroTradingStatusMessage }
        \cup { [ZeroTradingStatusMessage EXCEPT !.symbolLong = one] : one \in Sample(8) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.status = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.reserved = one] : one \in Sample(3) }

(***************************************************************************)
(* Statistics Message: 29 bytes                                            *)
(***************************************************************************)

StatisticsMessage ==
    [ symbolLong         : Sample(8),
      priceLong          : Sample(19),
      statisticType      : Sample(1),
      priceDetermination : Sample(1) ]

EncodeStatisticsMessage(message) ==
    message.symbolLong
        \o message.priceLong
        \o message.statisticType
        \o message.priceDetermination

DecodeStatisticsMessage(bytes) ==
    LET symbolLong == ReadBytes(bytes, 8) IN IF ~symbolLong.ok THEN Fail ELSE
    LET priceLong == ReadBytes(symbolLong.rest, 19) IN IF ~priceLong.ok THEN Fail ELSE
    LET statisticType == ReadBytes(priceLong.rest, 1) IN IF ~statisticType.ok THEN Fail ELSE
    LET priceDetermination == ReadBytes(statisticType.rest, 1) IN IF ~priceDetermination.ok THEN Fail ELSE
    Ok([ symbolLong         |-> symbolLong.value,
         priceLong          |-> priceLong.value,
         statisticType      |-> statisticType.value,
         priceDetermination |-> priceDetermination.value ], priceDetermination.rest)

ZeroStatisticsMessage ==
    [ symbolLong         |-> [i \in 1 .. 8 |-> 0],
      priceLong          |-> [i \in 1 .. 19 |-> 0],
      statisticType      |-> [i \in 1 .. 1 |-> 0],
      priceDetermination |-> [i \in 1 .. 1 |-> 0] ]

(* Statistics Message at zero, then each field in turn at the values it is checked at *)
CheckedStatisticsMessage ==
    { ZeroStatisticsMessage }
        \cup { [ZeroStatisticsMessage EXCEPT !.symbolLong = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsMessage EXCEPT !.priceLong = one] : one \in Sample(19) }
        \cup { [ZeroStatisticsMessage EXCEPT !.statisticType = one] : one \in Sample(1) }
        \cup { [ZeroStatisticsMessage EXCEPT !.priceDetermination = one] : one \in Sample(1) }

(***************************************************************************)
(* Auction Update Message: 59 bytes                                        *)
(***************************************************************************)

AuctionUpdateMessage ==
    [ symbolLong       : Sample(8),
      auctionType      : Sample(1),
      referencePrice   : Sample(19),
      indicativePrice  : Sample(19),
      indicativeShares : Sample(10),
      outsideTolerance : Sample(1),
      includesPrimary  : Sample(1) ]

EncodeAuctionUpdateMessage(message) ==
    message.symbolLong
        \o message.auctionType
        \o message.referencePrice
        \o message.indicativePrice
        \o message.indicativeShares
        \o message.outsideTolerance
        \o message.includesPrimary

DecodeAuctionUpdateMessage(bytes) ==
    LET symbolLong == ReadBytes(bytes, 8) IN IF ~symbolLong.ok THEN Fail ELSE
    LET auctionType == ReadBytes(symbolLong.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET referencePrice == ReadBytes(auctionType.rest, 19) IN IF ~referencePrice.ok THEN Fail ELSE
    LET indicativePrice == ReadBytes(referencePrice.rest, 19) IN IF ~indicativePrice.ok THEN Fail ELSE
    LET indicativeShares == ReadBytes(indicativePrice.rest, 10) IN IF ~indicativeShares.ok THEN Fail ELSE
    LET outsideTolerance == ReadBytes(indicativeShares.rest, 1) IN IF ~outsideTolerance.ok THEN Fail ELSE
    LET includesPrimary == ReadBytes(outsideTolerance.rest, 1) IN IF ~includesPrimary.ok THEN Fail ELSE
    Ok([ symbolLong       |-> symbolLong.value,
         auctionType      |-> auctionType.value,
         referencePrice   |-> referencePrice.value,
         indicativePrice  |-> indicativePrice.value,
         indicativeShares |-> indicativeShares.value,
         outsideTolerance |-> outsideTolerance.value,
         includesPrimary  |-> includesPrimary.value ], includesPrimary.rest)

ZeroAuctionUpdateMessage ==
    [ symbolLong       |-> [i \in 1 .. 8 |-> 0],
      auctionType      |-> [i \in 1 .. 1 |-> 0],
      referencePrice   |-> [i \in 1 .. 19 |-> 0],
      indicativePrice  |-> [i \in 1 .. 19 |-> 0],
      indicativeShares |-> [i \in 1 .. 10 |-> 0],
      outsideTolerance |-> [i \in 1 .. 1 |-> 0],
      includesPrimary  |-> [i \in 1 .. 1 |-> 0] ]

(* Auction Update Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionUpdateMessage ==
    { ZeroAuctionUpdateMessage }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.symbolLong = one] : one \in Sample(8) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.referencePrice = one] : one \in Sample(19) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.indicativePrice = one] : one \in Sample(19) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.indicativeShares = one] : one \in Sample(10) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.outsideTolerance = one] : one \in Sample(1) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.includesPrimary = one] : one \in Sample(1) }

(***************************************************************************)
(* Auction Summary Message: 38 bytes                                       *)
(***************************************************************************)

AuctionSummaryMessage ==
    [ symbolLong  : Sample(8),
      auctionType : Sample(1),
      priceLong   : Sample(19),
      sharesLong  : Sample(10) ]

EncodeAuctionSummaryMessage(message) ==
    message.symbolLong
        \o message.auctionType
        \o message.priceLong
        \o message.sharesLong

DecodeAuctionSummaryMessage(bytes) ==
    LET symbolLong == ReadBytes(bytes, 8) IN IF ~symbolLong.ok THEN Fail ELSE
    LET auctionType == ReadBytes(symbolLong.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET priceLong == ReadBytes(auctionType.rest, 19) IN IF ~priceLong.ok THEN Fail ELSE
    LET sharesLong == ReadBytes(priceLong.rest, 10) IN IF ~sharesLong.ok THEN Fail ELSE
    Ok([ symbolLong  |-> symbolLong.value,
         auctionType |-> auctionType.value,
         priceLong   |-> priceLong.value,
         sharesLong  |-> sharesLong.value ], sharesLong.rest)

ZeroAuctionSummaryMessage ==
    [ symbolLong  |-> [i \in 1 .. 8 |-> 0],
      auctionType |-> [i \in 1 .. 1 |-> 0],
      priceLong   |-> [i \in 1 .. 19 |-> 0],
      sharesLong  |-> [i \in 1 .. 10 |-> 0] ]

(* Auction Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionSummaryMessage ==
    { ZeroAuctionSummaryMessage }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.symbolLong = one] : one \in Sample(8) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.priceLong = one] : one \in Sample(19) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.sharesLong = one] : one \in Sample(10) }

(***************************************************************************)
(* Sequenced Message, selected by Sequenced Message Type                   *)
(***************************************************************************)

SymbolClearMessageCode == 115  \* "s"
AddOrderMessageCode == 65  \* "A"
AddOrderMessageLongFormCode == 99  \* "c"
AddOrderExpandedCode == 116  \* "t"
OrderExecutedMessageCode == 69  \* "E"
OrderExecutedMessageLongFormCode == 101  \* "e"
OrderCancelMessageCode == 88  \* "X"
OrderCancelMessageLongFormCode == 120  \* "x"
TradeMessageCode == 80  \* "P"
TradeMessageLongFormCode == 113  \* "q"
TradeMessageExtendedFormCode == 79  \* "O"
TradeMessageUnknownSymbolCode == 107  \* "k"
TradingStatusMessageCode == 72  \* "H"
StatisticsMessageCode == 90  \* "Z"
AuctionUpdateMessageCode == 108  \* "l"
AuctionSummaryMessageCode == 106  \* "j"

SequencedMessage ==
    [ tag : {SymbolClearMessageCode}, body : SymbolClearMessage ]
        \cup [ tag : {AddOrderMessageCode}, body : AddOrderMessage ]
        \cup [ tag : {AddOrderMessageLongFormCode}, body : AddOrderMessageLongForm ]
        \cup [ tag : {AddOrderExpandedCode}, body : AddOrderExpanded ]
        \cup [ tag : {OrderExecutedMessageCode}, body : OrderExecutedMessage ]
        \cup [ tag : {OrderExecutedMessageLongFormCode}, body : OrderExecutedMessageLongForm ]
        \cup [ tag : {OrderCancelMessageCode}, body : OrderCancelMessage ]
        \cup [ tag : {OrderCancelMessageLongFormCode}, body : OrderCancelMessageLongForm ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {TradeMessageLongFormCode}, body : TradeMessageLongForm ]
        \cup [ tag : {TradeMessageExtendedFormCode}, body : TradeMessageExtendedForm ]
        \cup [ tag : {TradeMessageUnknownSymbolCode}, body : TradeMessageUnknownSymbol ]
        \cup [ tag : {TradingStatusMessageCode}, body : TradingStatusMessage ]
        \cup [ tag : {StatisticsMessageCode}, body : StatisticsMessage ]
        \cup [ tag : {AuctionUpdateMessageCode}, body : AuctionUpdateMessage ]
        \cup [ tag : {AuctionSummaryMessageCode}, body : AuctionSummaryMessage ]

EncodeSequencedMessage(message) ==
    CASE message.tag = SymbolClearMessageCode -> EncodeSymbolClearMessage(message.body)
      [] message.tag = AddOrderMessageCode -> EncodeAddOrderMessage(message.body)
      [] message.tag = AddOrderMessageLongFormCode -> EncodeAddOrderMessageLongForm(message.body)
      [] message.tag = AddOrderExpandedCode -> EncodeAddOrderExpanded(message.body)
      [] message.tag = OrderExecutedMessageCode -> EncodeOrderExecutedMessage(message.body)
      [] message.tag = OrderExecutedMessageLongFormCode -> EncodeOrderExecutedMessageLongForm(message.body)
      [] message.tag = OrderCancelMessageCode -> EncodeOrderCancelMessage(message.body)
      [] message.tag = OrderCancelMessageLongFormCode -> EncodeOrderCancelMessageLongForm(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = TradeMessageLongFormCode -> EncodeTradeMessageLongForm(message.body)
      [] message.tag = TradeMessageExtendedFormCode -> EncodeTradeMessageExtendedForm(message.body)
      [] message.tag = TradeMessageUnknownSymbolCode -> EncodeTradeMessageUnknownSymbol(message.body)
      [] message.tag = TradingStatusMessageCode -> EncodeTradingStatusMessage(message.body)
      [] message.tag = StatisticsMessageCode -> EncodeStatisticsMessage(message.body)
      [] message.tag = AuctionUpdateMessageCode -> EncodeAuctionUpdateMessage(message.body)
      [] message.tag = AuctionSummaryMessageCode -> EncodeAuctionSummaryMessage(message.body)

DecodeSequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = SymbolClearMessageCode -> DecodeSymbolClearMessage(bytes)
              [] tag = AddOrderMessageCode -> DecodeAddOrderMessage(bytes)
              [] tag = AddOrderMessageLongFormCode -> DecodeAddOrderMessageLongForm(bytes)
              [] tag = AddOrderExpandedCode -> DecodeAddOrderExpanded(bytes)
              [] tag = OrderExecutedMessageCode -> DecodeOrderExecutedMessage(bytes)
              [] tag = OrderExecutedMessageLongFormCode -> DecodeOrderExecutedMessageLongForm(bytes)
              [] tag = OrderCancelMessageCode -> DecodeOrderCancelMessage(bytes)
              [] tag = OrderCancelMessageLongFormCode -> DecodeOrderCancelMessageLongForm(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = TradeMessageLongFormCode -> DecodeTradeMessageLongForm(bytes)
              [] tag = TradeMessageExtendedFormCode -> DecodeTradeMessageExtendedForm(bytes)
              [] tag = TradeMessageUnknownSymbolCode -> DecodeTradeMessageUnknownSymbol(bytes)
              [] tag = TradingStatusMessageCode -> DecodeTradingStatusMessage(bytes)
              [] tag = StatisticsMessageCode -> DecodeStatisticsMessage(bytes)
              [] tag = AuctionUpdateMessageCode -> DecodeAuctionUpdateMessage(bytes)
              [] tag = AuctionSummaryMessageCode -> DecodeAuctionSummaryMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSequencedMessage == [tag |-> SymbolClearMessageCode, body |-> ZeroSymbolClearMessage]

(* Each Sequenced Message in turn, at the values the message it names is checked at *)
CheckedSequencedMessage ==
    { [tag |-> SymbolClearMessageCode, body |-> one] : one \in CheckedSymbolClearMessage }
        \cup { [tag |-> AddOrderMessageCode, body |-> one] : one \in CheckedAddOrderMessage }
        \cup { [tag |-> AddOrderMessageLongFormCode, body |-> one] : one \in CheckedAddOrderMessageLongForm }
        \cup { [tag |-> AddOrderExpandedCode, body |-> one] : one \in CheckedAddOrderExpanded }
        \cup { [tag |-> OrderExecutedMessageCode, body |-> one] : one \in CheckedOrderExecutedMessage }
        \cup { [tag |-> OrderExecutedMessageLongFormCode, body |-> one] : one \in CheckedOrderExecutedMessageLongForm }
        \cup { [tag |-> OrderCancelMessageCode, body |-> one] : one \in CheckedOrderCancelMessage }
        \cup { [tag |-> OrderCancelMessageLongFormCode, body |-> one] : one \in CheckedOrderCancelMessageLongForm }
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> TradeMessageLongFormCode, body |-> one] : one \in CheckedTradeMessageLongForm }
        \cup { [tag |-> TradeMessageExtendedFormCode, body |-> one] : one \in CheckedTradeMessageExtendedForm }
        \cup { [tag |-> TradeMessageUnknownSymbolCode, body |-> one] : one \in CheckedTradeMessageUnknownSymbol }
        \cup { [tag |-> TradingStatusMessageCode, body |-> one] : one \in CheckedTradingStatusMessage }
        \cup { [tag |-> StatisticsMessageCode, body |-> one] : one \in CheckedStatisticsMessage }
        \cup { [tag |-> AuctionUpdateMessageCode, body |-> one] : one \in CheckedAuctionUpdateMessage }
        \cup { [tag |-> AuctionSummaryMessageCode, body |-> one] : one \in CheckedAuctionSummaryMessage }

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

(* Every Add Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderMessage ==
    \A message \in CheckedAddOrderMessage :
        LET read == DecodeAddOrderMessage(EncodeAddOrderMessage(message))
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

(* Every Add Order Expanded decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderExpanded ==
    \A message \in CheckedAddOrderExpanded :
        LET read == DecodeAddOrderExpanded(EncodeAddOrderExpanded(message))
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

(* Every Order Executed Message Long Form decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutedMessageLongForm ==
    \A message \in CheckedOrderExecutedMessageLongForm :
        LET read == DecodeOrderExecutedMessageLongForm(EncodeOrderExecutedMessageLongForm(message))
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

(* Every Order Cancel Message Long Form decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelMessageLongForm ==
    \A message \in CheckedOrderCancelMessageLongForm :
        LET read == DecodeOrderCancelMessageLongForm(EncodeOrderCancelMessageLongForm(message))
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

(* Every Trade Message Long Form decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeMessageLongForm ==
    \A message \in CheckedTradeMessageLongForm :
        LET read == DecodeTradeMessageLongForm(EncodeTradeMessageLongForm(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Message Extended Form decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeMessageExtendedForm ==
    \A message \in CheckedTradeMessageExtendedForm :
        LET read == DecodeTradeMessageExtendedForm(EncodeTradeMessageExtendedForm(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Message Unknown Symbol decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeMessageUnknownSymbol ==
    \A message \in CheckedTradeMessageUnknownSymbol :
        LET read == DecodeTradeMessageUnknownSymbol(EncodeTradeMessageUnknownSymbol(message))
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

(* Every Statistics Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStatisticsMessage ==
    \A message \in CheckedStatisticsMessage :
        LET read == DecodeStatisticsMessage(EncodeStatisticsMessage(message))
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

(* Every Auction Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionSummaryMessage ==
    \A message \in CheckedAuctionSummaryMessage :
        LET read == DecodeAuctionSummaryMessage(EncodeAuctionSummaryMessage(message))
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
