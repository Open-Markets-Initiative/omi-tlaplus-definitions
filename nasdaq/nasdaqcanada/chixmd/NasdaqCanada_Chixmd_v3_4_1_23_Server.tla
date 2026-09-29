--------------- MODULE NasdaqCanada_Chixmd_v3_4_1_23_Server ----------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) CHIXMD Market Data v3.4.1                                      *)
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
(* Login Accepted Packet: 31 bytes                                         *)
(***************************************************************************)

LoginAcceptedPacket ==
    [ session        : Sample(10),
      sequenceNumber : Sample(10),
      comma          : Sample(1),
      messagesTotal  : Sample(10) ]

EncodeLoginAcceptedPacket(message) ==
    message.session
        \o message.sequenceNumber
        \o message.comma
        \o message.messagesTotal

DecodeLoginAcceptedPacket(bytes) ==
    LET session == ReadBytes(bytes, 10) IN IF ~session.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(session.rest, 10) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET comma == ReadBytes(sequenceNumber.rest, 1) IN IF ~comma.ok THEN Fail ELSE
    LET messagesTotal == ReadBytes(comma.rest, 10) IN IF ~messagesTotal.ok THEN Fail ELSE
    Ok([ session        |-> session.value,
         sequenceNumber |-> sequenceNumber.value,
         comma          |-> comma.value,
         messagesTotal  |-> messagesTotal.value ], messagesTotal.rest)

ZeroLoginAcceptedPacket ==
    [ session        |-> [i \in 1 .. 10 |-> 0],
      sequenceNumber |-> [i \in 1 .. 10 |-> 0],
      comma          |-> [i \in 1 .. 1 |-> 0],
      messagesTotal  |-> [i \in 1 .. 10 |-> 0] ]

(* Login Accepted Packet at zero, then each field in turn at the values it is checked at *)
CheckedLoginAcceptedPacket ==
    { ZeroLoginAcceptedPacket }
        \cup { [ZeroLoginAcceptedPacket EXCEPT !.session = one] : one \in Sample(10) }
        \cup { [ZeroLoginAcceptedPacket EXCEPT !.sequenceNumber = one] : one \in Sample(10) }
        \cup { [ZeroLoginAcceptedPacket EXCEPT !.comma = one] : one \in Sample(1) }
        \cup { [ZeroLoginAcceptedPacket EXCEPT !.messagesTotal = one] : one \in Sample(10) }

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
(* Add Order Message: 39 bytes                                             *)
(***************************************************************************)

AddOrderMessage ==
    [ orderReference   : Sample(9),
      buySellIndicator : Sample(1),
      shares           : Sample(6),
      stock            : Sample(10),
      price            : Sample(10),
      broker           : Sample(3) ]

EncodeAddOrderMessage(message) ==
    message.orderReference
        \o message.buySellIndicator
        \o message.shares
        \o message.stock
        \o message.price
        \o message.broker

DecodeAddOrderMessage(bytes) ==
    LET orderReference == ReadBytes(bytes, 9) IN IF ~orderReference.ok THEN Fail ELSE
    LET buySellIndicator == ReadBytes(orderReference.rest, 1) IN IF ~buySellIndicator.ok THEN Fail ELSE
    LET shares == ReadBytes(buySellIndicator.rest, 6) IN IF ~shares.ok THEN Fail ELSE
    LET stock == ReadBytes(shares.rest, 10) IN IF ~stock.ok THEN Fail ELSE
    LET price == ReadBytes(stock.rest, 10) IN IF ~price.ok THEN Fail ELSE
    LET broker == ReadBytes(price.rest, 3) IN IF ~broker.ok THEN Fail ELSE
    Ok([ orderReference   |-> orderReference.value,
         buySellIndicator |-> buySellIndicator.value,
         shares           |-> shares.value,
         stock            |-> stock.value,
         price            |-> price.value,
         broker           |-> broker.value ], broker.rest)

ZeroAddOrderMessage ==
    [ orderReference   |-> [i \in 1 .. 9 |-> 0],
      buySellIndicator |-> [i \in 1 .. 1 |-> 0],
      shares           |-> [i \in 1 .. 6 |-> 0],
      stock            |-> [i \in 1 .. 10 |-> 0],
      price            |-> [i \in 1 .. 10 |-> 0],
      broker           |-> [i \in 1 .. 3 |-> 0] ]

(* Add Order Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderMessage ==
    { ZeroAddOrderMessage }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderReference = one] : one \in Sample(9) }
        \cup { [ZeroAddOrderMessage EXCEPT !.buySellIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.shares = one] : one \in Sample(6) }
        \cup { [ZeroAddOrderMessage EXCEPT !.stock = one] : one \in Sample(10) }
        \cup { [ZeroAddOrderMessage EXCEPT !.price = one] : one \in Sample(10) }
        \cup { [ZeroAddOrderMessage EXCEPT !.broker = one] : one \in Sample(3) }

(***************************************************************************)
(* Long Form Add Order Message: 52 bytes                                   *)
(***************************************************************************)

LongFormAddOrderMessage ==
    [ orderReference   : Sample(9),
      buySellIndicator : Sample(1),
      longShares       : Sample(10),
      stock            : Sample(10),
      longPrice        : Sample(19),
      broker           : Sample(3) ]

EncodeLongFormAddOrderMessage(message) ==
    message.orderReference
        \o message.buySellIndicator
        \o message.longShares
        \o message.stock
        \o message.longPrice
        \o message.broker

DecodeLongFormAddOrderMessage(bytes) ==
    LET orderReference == ReadBytes(bytes, 9) IN IF ~orderReference.ok THEN Fail ELSE
    LET buySellIndicator == ReadBytes(orderReference.rest, 1) IN IF ~buySellIndicator.ok THEN Fail ELSE
    LET longShares == ReadBytes(buySellIndicator.rest, 10) IN IF ~longShares.ok THEN Fail ELSE
    LET stock == ReadBytes(longShares.rest, 10) IN IF ~stock.ok THEN Fail ELSE
    LET longPrice == ReadBytes(stock.rest, 19) IN IF ~longPrice.ok THEN Fail ELSE
    LET broker == ReadBytes(longPrice.rest, 3) IN IF ~broker.ok THEN Fail ELSE
    Ok([ orderReference   |-> orderReference.value,
         buySellIndicator |-> buySellIndicator.value,
         longShares       |-> longShares.value,
         stock            |-> stock.value,
         longPrice        |-> longPrice.value,
         broker           |-> broker.value ], broker.rest)

ZeroLongFormAddOrderMessage ==
    [ orderReference   |-> [i \in 1 .. 9 |-> 0],
      buySellIndicator |-> [i \in 1 .. 1 |-> 0],
      longShares       |-> [i \in 1 .. 10 |-> 0],
      stock            |-> [i \in 1 .. 10 |-> 0],
      longPrice        |-> [i \in 1 .. 19 |-> 0],
      broker           |-> [i \in 1 .. 3 |-> 0] ]

(* Long Form Add Order Message at zero, then each field in turn at the values it is checked at *)
CheckedLongFormAddOrderMessage ==
    { ZeroLongFormAddOrderMessage }
        \cup { [ZeroLongFormAddOrderMessage EXCEPT !.orderReference = one] : one \in Sample(9) }
        \cup { [ZeroLongFormAddOrderMessage EXCEPT !.buySellIndicator = one] : one \in Sample(1) }
        \cup { [ZeroLongFormAddOrderMessage EXCEPT !.longShares = one] : one \in Sample(10) }
        \cup { [ZeroLongFormAddOrderMessage EXCEPT !.stock = one] : one \in Sample(10) }
        \cup { [ZeroLongFormAddOrderMessage EXCEPT !.longPrice = one] : one \in Sample(19) }
        \cup { [ZeroLongFormAddOrderMessage EXCEPT !.broker = one] : one \in Sample(3) }

(***************************************************************************)
(* Order Execution Message: 40 bytes                                       *)
(***************************************************************************)

OrderExecutionMessage ==
    [ orderReference       : Sample(9),
      executedShares       : Sample(6),
      tradeReference       : Sample(9),
      contraOrderReference : Sample(9),
      tradeAttribute       : Sample(1),
      broker               : Sample(3),
      contraBroker         : Sample(3) ]

EncodeOrderExecutionMessage(message) ==
    message.orderReference
        \o message.executedShares
        \o message.tradeReference
        \o message.contraOrderReference
        \o message.tradeAttribute
        \o message.broker
        \o message.contraBroker

DecodeOrderExecutionMessage(bytes) ==
    LET orderReference == ReadBytes(bytes, 9) IN IF ~orderReference.ok THEN Fail ELSE
    LET executedShares == ReadBytes(orderReference.rest, 6) IN IF ~executedShares.ok THEN Fail ELSE
    LET tradeReference == ReadBytes(executedShares.rest, 9) IN IF ~tradeReference.ok THEN Fail ELSE
    LET contraOrderReference == ReadBytes(tradeReference.rest, 9) IN IF ~contraOrderReference.ok THEN Fail ELSE
    LET tradeAttribute == ReadBytes(contraOrderReference.rest, 1) IN IF ~tradeAttribute.ok THEN Fail ELSE
    LET broker == ReadBytes(tradeAttribute.rest, 3) IN IF ~broker.ok THEN Fail ELSE
    LET contraBroker == ReadBytes(broker.rest, 3) IN IF ~contraBroker.ok THEN Fail ELSE
    Ok([ orderReference       |-> orderReference.value,
         executedShares       |-> executedShares.value,
         tradeReference       |-> tradeReference.value,
         contraOrderReference |-> contraOrderReference.value,
         tradeAttribute       |-> tradeAttribute.value,
         broker               |-> broker.value,
         contraBroker         |-> contraBroker.value ], contraBroker.rest)

ZeroOrderExecutionMessage ==
    [ orderReference       |-> [i \in 1 .. 9 |-> 0],
      executedShares       |-> [i \in 1 .. 6 |-> 0],
      tradeReference       |-> [i \in 1 .. 9 |-> 0],
      contraOrderReference |-> [i \in 1 .. 9 |-> 0],
      tradeAttribute       |-> [i \in 1 .. 1 |-> 0],
      broker               |-> [i \in 1 .. 3 |-> 0],
      contraBroker         |-> [i \in 1 .. 3 |-> 0] ]

(* Order Execution Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutionMessage ==
    { ZeroOrderExecutionMessage }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.orderReference = one] : one \in Sample(9) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.executedShares = one] : one \in Sample(6) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.tradeReference = one] : one \in Sample(9) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.contraOrderReference = one] : one \in Sample(9) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.tradeAttribute = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.broker = one] : one \in Sample(3) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.contraBroker = one] : one \in Sample(3) }

(***************************************************************************)
(* Long Form Order Execution Message: 44 bytes                             *)
(***************************************************************************)

LongFormOrderExecutionMessage ==
    [ orderReference       : Sample(9),
      longExecutedShares   : Sample(10),
      tradeReference       : Sample(9),
      contraOrderReference : Sample(9),
      tradeAttribute       : Sample(1),
      broker               : Sample(3),
      contraBroker         : Sample(3) ]

EncodeLongFormOrderExecutionMessage(message) ==
    message.orderReference
        \o message.longExecutedShares
        \o message.tradeReference
        \o message.contraOrderReference
        \o message.tradeAttribute
        \o message.broker
        \o message.contraBroker

DecodeLongFormOrderExecutionMessage(bytes) ==
    LET orderReference == ReadBytes(bytes, 9) IN IF ~orderReference.ok THEN Fail ELSE
    LET longExecutedShares == ReadBytes(orderReference.rest, 10) IN IF ~longExecutedShares.ok THEN Fail ELSE
    LET tradeReference == ReadBytes(longExecutedShares.rest, 9) IN IF ~tradeReference.ok THEN Fail ELSE
    LET contraOrderReference == ReadBytes(tradeReference.rest, 9) IN IF ~contraOrderReference.ok THEN Fail ELSE
    LET tradeAttribute == ReadBytes(contraOrderReference.rest, 1) IN IF ~tradeAttribute.ok THEN Fail ELSE
    LET broker == ReadBytes(tradeAttribute.rest, 3) IN IF ~broker.ok THEN Fail ELSE
    LET contraBroker == ReadBytes(broker.rest, 3) IN IF ~contraBroker.ok THEN Fail ELSE
    Ok([ orderReference       |-> orderReference.value,
         longExecutedShares   |-> longExecutedShares.value,
         tradeReference       |-> tradeReference.value,
         contraOrderReference |-> contraOrderReference.value,
         tradeAttribute       |-> tradeAttribute.value,
         broker               |-> broker.value,
         contraBroker         |-> contraBroker.value ], contraBroker.rest)

ZeroLongFormOrderExecutionMessage ==
    [ orderReference       |-> [i \in 1 .. 9 |-> 0],
      longExecutedShares   |-> [i \in 1 .. 10 |-> 0],
      tradeReference       |-> [i \in 1 .. 9 |-> 0],
      contraOrderReference |-> [i \in 1 .. 9 |-> 0],
      tradeAttribute       |-> [i \in 1 .. 1 |-> 0],
      broker               |-> [i \in 1 .. 3 |-> 0],
      contraBroker         |-> [i \in 1 .. 3 |-> 0] ]

(* Long Form Order Execution Message at zero, then each field in turn at the values it is checked at *)
CheckedLongFormOrderExecutionMessage ==
    { ZeroLongFormOrderExecutionMessage }
        \cup { [ZeroLongFormOrderExecutionMessage EXCEPT !.orderReference = one] : one \in Sample(9) }
        \cup { [ZeroLongFormOrderExecutionMessage EXCEPT !.longExecutedShares = one] : one \in Sample(10) }
        \cup { [ZeroLongFormOrderExecutionMessage EXCEPT !.tradeReference = one] : one \in Sample(9) }
        \cup { [ZeroLongFormOrderExecutionMessage EXCEPT !.contraOrderReference = one] : one \in Sample(9) }
        \cup { [ZeroLongFormOrderExecutionMessage EXCEPT !.tradeAttribute = one] : one \in Sample(1) }
        \cup { [ZeroLongFormOrderExecutionMessage EXCEPT !.broker = one] : one \in Sample(3) }
        \cup { [ZeroLongFormOrderExecutionMessage EXCEPT !.contraBroker = one] : one \in Sample(3) }

(***************************************************************************)
(* Order Cancel Message: 15 bytes                                          *)
(***************************************************************************)

OrderCancelMessage ==
    [ orderReference : Sample(9),
      canceledShares : Sample(6) ]

EncodeOrderCancelMessage(message) ==
    message.orderReference
        \o message.canceledShares

DecodeOrderCancelMessage(bytes) ==
    LET orderReference == ReadBytes(bytes, 9) IN IF ~orderReference.ok THEN Fail ELSE
    LET canceledShares == ReadBytes(orderReference.rest, 6) IN IF ~canceledShares.ok THEN Fail ELSE
    Ok([ orderReference |-> orderReference.value,
         canceledShares |-> canceledShares.value ], canceledShares.rest)

ZeroOrderCancelMessage ==
    [ orderReference |-> [i \in 1 .. 9 |-> 0],
      canceledShares |-> [i \in 1 .. 6 |-> 0] ]

(* Order Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelMessage ==
    { ZeroOrderCancelMessage }
        \cup { [ZeroOrderCancelMessage EXCEPT !.orderReference = one] : one \in Sample(9) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.canceledShares = one] : one \in Sample(6) }

(***************************************************************************)
(* Long Form Order Cancel Message: 19 bytes                                *)
(***************************************************************************)

LongFormOrderCancelMessage ==
    [ orderReference     : Sample(9),
      longCanceledShares : Sample(10) ]

EncodeLongFormOrderCancelMessage(message) ==
    message.orderReference
        \o message.longCanceledShares

DecodeLongFormOrderCancelMessage(bytes) ==
    LET orderReference == ReadBytes(bytes, 9) IN IF ~orderReference.ok THEN Fail ELSE
    LET longCanceledShares == ReadBytes(orderReference.rest, 10) IN IF ~longCanceledShares.ok THEN Fail ELSE
    Ok([ orderReference     |-> orderReference.value,
         longCanceledShares |-> longCanceledShares.value ], longCanceledShares.rest)

ZeroLongFormOrderCancelMessage ==
    [ orderReference     |-> [i \in 1 .. 9 |-> 0],
      longCanceledShares |-> [i \in 1 .. 10 |-> 0] ]

(* Long Form Order Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedLongFormOrderCancelMessage ==
    { ZeroLongFormOrderCancelMessage }
        \cup { [ZeroLongFormOrderCancelMessage EXCEPT !.orderReference = one] : one \in Sample(9) }
        \cup { [ZeroLongFormOrderCancelMessage EXCEPT !.longCanceledShares = one] : one \in Sample(10) }

(***************************************************************************)
(* Trade Message: 63 bytes                                                 *)
(***************************************************************************)

TradeMessage ==
    [ orderReference       : Sample(9),
      buySellIndicator     : Sample(1),
      shares               : Sample(6),
      stock                : Sample(10),
      price                : Sample(10),
      tradeReference       : Sample(9),
      contraOrderReference : Sample(9),
      broker               : Sample(3),
      contraBroker         : Sample(3),
      tradeAttribute       : Sample(1),
      crossType            : Sample(1),
      settlementTerms      : Sample(1) ]

EncodeTradeMessage(message) ==
    message.orderReference
        \o message.buySellIndicator
        \o message.shares
        \o message.stock
        \o message.price
        \o message.tradeReference
        \o message.contraOrderReference
        \o message.broker
        \o message.contraBroker
        \o message.tradeAttribute
        \o message.crossType
        \o message.settlementTerms

DecodeTradeMessage(bytes) ==
    LET orderReference == ReadBytes(bytes, 9) IN IF ~orderReference.ok THEN Fail ELSE
    LET buySellIndicator == ReadBytes(orderReference.rest, 1) IN IF ~buySellIndicator.ok THEN Fail ELSE
    LET shares == ReadBytes(buySellIndicator.rest, 6) IN IF ~shares.ok THEN Fail ELSE
    LET stock == ReadBytes(shares.rest, 10) IN IF ~stock.ok THEN Fail ELSE
    LET price == ReadBytes(stock.rest, 10) IN IF ~price.ok THEN Fail ELSE
    LET tradeReference == ReadBytes(price.rest, 9) IN IF ~tradeReference.ok THEN Fail ELSE
    LET contraOrderReference == ReadBytes(tradeReference.rest, 9) IN IF ~contraOrderReference.ok THEN Fail ELSE
    LET broker == ReadBytes(contraOrderReference.rest, 3) IN IF ~broker.ok THEN Fail ELSE
    LET contraBroker == ReadBytes(broker.rest, 3) IN IF ~contraBroker.ok THEN Fail ELSE
    LET tradeAttribute == ReadBytes(contraBroker.rest, 1) IN IF ~tradeAttribute.ok THEN Fail ELSE
    LET crossType == ReadBytes(tradeAttribute.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET settlementTerms == ReadBytes(crossType.rest, 1) IN IF ~settlementTerms.ok THEN Fail ELSE
    Ok([ orderReference       |-> orderReference.value,
         buySellIndicator     |-> buySellIndicator.value,
         shares               |-> shares.value,
         stock                |-> stock.value,
         price                |-> price.value,
         tradeReference       |-> tradeReference.value,
         contraOrderReference |-> contraOrderReference.value,
         broker               |-> broker.value,
         contraBroker         |-> contraBroker.value,
         tradeAttribute       |-> tradeAttribute.value,
         crossType            |-> crossType.value,
         settlementTerms      |-> settlementTerms.value ], settlementTerms.rest)

ZeroTradeMessage ==
    [ orderReference       |-> [i \in 1 .. 9 |-> 0],
      buySellIndicator     |-> [i \in 1 .. 1 |-> 0],
      shares               |-> [i \in 1 .. 6 |-> 0],
      stock                |-> [i \in 1 .. 10 |-> 0],
      price                |-> [i \in 1 .. 10 |-> 0],
      tradeReference       |-> [i \in 1 .. 9 |-> 0],
      contraOrderReference |-> [i \in 1 .. 9 |-> 0],
      broker               |-> [i \in 1 .. 3 |-> 0],
      contraBroker         |-> [i \in 1 .. 3 |-> 0],
      tradeAttribute       |-> [i \in 1 .. 1 |-> 0],
      crossType            |-> [i \in 1 .. 1 |-> 0],
      settlementTerms      |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.orderReference = one] : one \in Sample(9) }
        \cup { [ZeroTradeMessage EXCEPT !.buySellIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.shares = one] : one \in Sample(6) }
        \cup { [ZeroTradeMessage EXCEPT !.stock = one] : one \in Sample(10) }
        \cup { [ZeroTradeMessage EXCEPT !.price = one] : one \in Sample(10) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeReference = one] : one \in Sample(9) }
        \cup { [ZeroTradeMessage EXCEPT !.contraOrderReference = one] : one \in Sample(9) }
        \cup { [ZeroTradeMessage EXCEPT !.broker = one] : one \in Sample(3) }
        \cup { [ZeroTradeMessage EXCEPT !.contraBroker = one] : one \in Sample(3) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeAttribute = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.settlementTerms = one] : one \in Sample(1) }

(***************************************************************************)
(* Long Form Trade Message: 76 bytes                                       *)
(***************************************************************************)

LongFormTradeMessage ==
    [ orderReference       : Sample(9),
      buySellIndicator     : Sample(1),
      longShares           : Sample(10),
      stock                : Sample(10),
      longPrice            : Sample(19),
      tradeReference       : Sample(9),
      contraOrderReference : Sample(9),
      broker               : Sample(3),
      contraBroker         : Sample(3),
      tradeAttribute       : Sample(1),
      crossType            : Sample(1),
      settlementTerms      : Sample(1) ]

EncodeLongFormTradeMessage(message) ==
    message.orderReference
        \o message.buySellIndicator
        \o message.longShares
        \o message.stock
        \o message.longPrice
        \o message.tradeReference
        \o message.contraOrderReference
        \o message.broker
        \o message.contraBroker
        \o message.tradeAttribute
        \o message.crossType
        \o message.settlementTerms

DecodeLongFormTradeMessage(bytes) ==
    LET orderReference == ReadBytes(bytes, 9) IN IF ~orderReference.ok THEN Fail ELSE
    LET buySellIndicator == ReadBytes(orderReference.rest, 1) IN IF ~buySellIndicator.ok THEN Fail ELSE
    LET longShares == ReadBytes(buySellIndicator.rest, 10) IN IF ~longShares.ok THEN Fail ELSE
    LET stock == ReadBytes(longShares.rest, 10) IN IF ~stock.ok THEN Fail ELSE
    LET longPrice == ReadBytes(stock.rest, 19) IN IF ~longPrice.ok THEN Fail ELSE
    LET tradeReference == ReadBytes(longPrice.rest, 9) IN IF ~tradeReference.ok THEN Fail ELSE
    LET contraOrderReference == ReadBytes(tradeReference.rest, 9) IN IF ~contraOrderReference.ok THEN Fail ELSE
    LET broker == ReadBytes(contraOrderReference.rest, 3) IN IF ~broker.ok THEN Fail ELSE
    LET contraBroker == ReadBytes(broker.rest, 3) IN IF ~contraBroker.ok THEN Fail ELSE
    LET tradeAttribute == ReadBytes(contraBroker.rest, 1) IN IF ~tradeAttribute.ok THEN Fail ELSE
    LET crossType == ReadBytes(tradeAttribute.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET settlementTerms == ReadBytes(crossType.rest, 1) IN IF ~settlementTerms.ok THEN Fail ELSE
    Ok([ orderReference       |-> orderReference.value,
         buySellIndicator     |-> buySellIndicator.value,
         longShares           |-> longShares.value,
         stock                |-> stock.value,
         longPrice            |-> longPrice.value,
         tradeReference       |-> tradeReference.value,
         contraOrderReference |-> contraOrderReference.value,
         broker               |-> broker.value,
         contraBroker         |-> contraBroker.value,
         tradeAttribute       |-> tradeAttribute.value,
         crossType            |-> crossType.value,
         settlementTerms      |-> settlementTerms.value ], settlementTerms.rest)

ZeroLongFormTradeMessage ==
    [ orderReference       |-> [i \in 1 .. 9 |-> 0],
      buySellIndicator     |-> [i \in 1 .. 1 |-> 0],
      longShares           |-> [i \in 1 .. 10 |-> 0],
      stock                |-> [i \in 1 .. 10 |-> 0],
      longPrice            |-> [i \in 1 .. 19 |-> 0],
      tradeReference       |-> [i \in 1 .. 9 |-> 0],
      contraOrderReference |-> [i \in 1 .. 9 |-> 0],
      broker               |-> [i \in 1 .. 3 |-> 0],
      contraBroker         |-> [i \in 1 .. 3 |-> 0],
      tradeAttribute       |-> [i \in 1 .. 1 |-> 0],
      crossType            |-> [i \in 1 .. 1 |-> 0],
      settlementTerms      |-> [i \in 1 .. 1 |-> 0] ]

(* Long Form Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedLongFormTradeMessage ==
    { ZeroLongFormTradeMessage }
        \cup { [ZeroLongFormTradeMessage EXCEPT !.orderReference = one] : one \in Sample(9) }
        \cup { [ZeroLongFormTradeMessage EXCEPT !.buySellIndicator = one] : one \in Sample(1) }
        \cup { [ZeroLongFormTradeMessage EXCEPT !.longShares = one] : one \in Sample(10) }
        \cup { [ZeroLongFormTradeMessage EXCEPT !.stock = one] : one \in Sample(10) }
        \cup { [ZeroLongFormTradeMessage EXCEPT !.longPrice = one] : one \in Sample(19) }
        \cup { [ZeroLongFormTradeMessage EXCEPT !.tradeReference = one] : one \in Sample(9) }
        \cup { [ZeroLongFormTradeMessage EXCEPT !.contraOrderReference = one] : one \in Sample(9) }
        \cup { [ZeroLongFormTradeMessage EXCEPT !.broker = one] : one \in Sample(3) }
        \cup { [ZeroLongFormTradeMessage EXCEPT !.contraBroker = one] : one \in Sample(3) }
        \cup { [ZeroLongFormTradeMessage EXCEPT !.tradeAttribute = one] : one \in Sample(1) }
        \cup { [ZeroLongFormTradeMessage EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroLongFormTradeMessage EXCEPT !.settlementTerms = one] : one \in Sample(1) }

(***************************************************************************)
(* Broken Trade Message: 9 bytes                                           *)
(***************************************************************************)

BrokenTradeMessage ==
    [ tradeReference : Sample(9) ]

EncodeBrokenTradeMessage(message) ==
    message.tradeReference

DecodeBrokenTradeMessage(bytes) ==
    LET tradeReference == ReadBytes(bytes, 9) IN IF ~tradeReference.ok THEN Fail ELSE
    Ok([ tradeReference |-> tradeReference.value ], tradeReference.rest)

ZeroBrokenTradeMessage ==
    [ tradeReference |-> [i \in 1 .. 9 |-> 0] ]

(* Broken Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedBrokenTradeMessage ==
    { ZeroBrokenTradeMessage }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.tradeReference = one] : one \in Sample(9) }

(***************************************************************************)
(* System Event Message: 1 bytes                                           *)
(***************************************************************************)

SystemEventMessage ==
    [ eventCode : Sample(1) ]

EncodeSystemEventMessage(message) ==
    message.eventCode

DecodeSystemEventMessage(bytes) ==
    LET eventCode == ReadBytes(bytes, 1) IN IF ~eventCode.ok THEN Fail ELSE
    Ok([ eventCode |-> eventCode.value ], eventCode.rest)

ZeroSystemEventMessage ==
    [ eventCode |-> [i \in 1 .. 1 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Stock Status Message: 21 bytes                                          *)
(***************************************************************************)

StockStatusMessage ==
    [ stock         : Sample(10),
      tradingState  : Sample(1),
      reserved1     : Sample(1),
      listingMarket : Sample(1),
      boardLotSize  : Sample(4),
      currency      : Sample(3),
      gefEligible   : Sample(1) ]

EncodeStockStatusMessage(message) ==
    message.stock
        \o message.tradingState
        \o message.reserved1
        \o message.listingMarket
        \o message.boardLotSize
        \o message.currency
        \o message.gefEligible

DecodeStockStatusMessage(bytes) ==
    LET stock == ReadBytes(bytes, 10) IN IF ~stock.ok THEN Fail ELSE
    LET tradingState == ReadBytes(stock.rest, 1) IN IF ~tradingState.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(tradingState.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET listingMarket == ReadBytes(reserved1.rest, 1) IN IF ~listingMarket.ok THEN Fail ELSE
    LET boardLotSize == ReadBytes(listingMarket.rest, 4) IN IF ~boardLotSize.ok THEN Fail ELSE
    LET currency == ReadBytes(boardLotSize.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET gefEligible == ReadBytes(currency.rest, 1) IN IF ~gefEligible.ok THEN Fail ELSE
    Ok([ stock         |-> stock.value,
         tradingState  |-> tradingState.value,
         reserved1     |-> reserved1.value,
         listingMarket |-> listingMarket.value,
         boardLotSize  |-> boardLotSize.value,
         currency      |-> currency.value,
         gefEligible   |-> gefEligible.value ], gefEligible.rest)

ZeroStockStatusMessage ==
    [ stock         |-> [i \in 1 .. 10 |-> 0],
      tradingState  |-> [i \in 1 .. 1 |-> 0],
      reserved1     |-> [i \in 1 .. 1 |-> 0],
      listingMarket |-> [i \in 1 .. 1 |-> 0],
      boardLotSize  |-> [i \in 1 .. 4 |-> 0],
      currency      |-> [i \in 1 .. 3 |-> 0],
      gefEligible   |-> [i \in 1 .. 1 |-> 0] ]

(* Stock Status Message at zero, then each field in turn at the values it is checked at *)
CheckedStockStatusMessage ==
    { ZeroStockStatusMessage }
        \cup { [ZeroStockStatusMessage EXCEPT !.stock = one] : one \in Sample(10) }
        \cup { [ZeroStockStatusMessage EXCEPT !.tradingState = one] : one \in Sample(1) }
        \cup { [ZeroStockStatusMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroStockStatusMessage EXCEPT !.listingMarket = one] : one \in Sample(1) }
        \cup { [ZeroStockStatusMessage EXCEPT !.boardLotSize = one] : one \in Sample(4) }
        \cup { [ZeroStockStatusMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroStockStatusMessage EXCEPT !.gefEligible = one] : one \in Sample(1) }

(***************************************************************************)
(* Sequenced Message, selected by Message Type                             *)
(***************************************************************************)

AddOrderMessageCode == 65  \* "A"
LongFormAddOrderMessageCode == 97  \* "a"
OrderExecutionMessageCode == 69  \* "E"
LongFormOrderExecutionMessageCode == 101  \* "e"
OrderCancelMessageCode == 88  \* "X"
LongFormOrderCancelMessageCode == 120  \* "x"
TradeMessageCode == 80  \* "P"
LongFormTradeMessageCode == 112  \* "p"
BrokenTradeMessageCode == 66  \* "B"
SystemEventMessageCode == 83  \* "S"
StockStatusMessageCode == 72  \* "H"

SequencedMessage ==
    [ tag : {AddOrderMessageCode}, body : AddOrderMessage ]
        \cup [ tag : {LongFormAddOrderMessageCode}, body : LongFormAddOrderMessage ]
        \cup [ tag : {OrderExecutionMessageCode}, body : OrderExecutionMessage ]
        \cup [ tag : {LongFormOrderExecutionMessageCode}, body : LongFormOrderExecutionMessage ]
        \cup [ tag : {OrderCancelMessageCode}, body : OrderCancelMessage ]
        \cup [ tag : {LongFormOrderCancelMessageCode}, body : LongFormOrderCancelMessage ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {LongFormTradeMessageCode}, body : LongFormTradeMessage ]
        \cup [ tag : {BrokenTradeMessageCode}, body : BrokenTradeMessage ]
        \cup [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {StockStatusMessageCode}, body : StockStatusMessage ]

EncodeSequencedMessage(message) ==
    CASE message.tag = AddOrderMessageCode -> EncodeAddOrderMessage(message.body)
      [] message.tag = LongFormAddOrderMessageCode -> EncodeLongFormAddOrderMessage(message.body)
      [] message.tag = OrderExecutionMessageCode -> EncodeOrderExecutionMessage(message.body)
      [] message.tag = LongFormOrderExecutionMessageCode -> EncodeLongFormOrderExecutionMessage(message.body)
      [] message.tag = OrderCancelMessageCode -> EncodeOrderCancelMessage(message.body)
      [] message.tag = LongFormOrderCancelMessageCode -> EncodeLongFormOrderCancelMessage(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = LongFormTradeMessageCode -> EncodeLongFormTradeMessage(message.body)
      [] message.tag = BrokenTradeMessageCode -> EncodeBrokenTradeMessage(message.body)
      [] message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = StockStatusMessageCode -> EncodeStockStatusMessage(message.body)

DecodeSequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = AddOrderMessageCode -> DecodeAddOrderMessage(bytes)
              [] tag = LongFormAddOrderMessageCode -> DecodeLongFormAddOrderMessage(bytes)
              [] tag = OrderExecutionMessageCode -> DecodeOrderExecutionMessage(bytes)
              [] tag = LongFormOrderExecutionMessageCode -> DecodeLongFormOrderExecutionMessage(bytes)
              [] tag = OrderCancelMessageCode -> DecodeOrderCancelMessage(bytes)
              [] tag = LongFormOrderCancelMessageCode -> DecodeLongFormOrderCancelMessage(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = LongFormTradeMessageCode -> DecodeLongFormTradeMessage(bytes)
              [] tag = BrokenTradeMessageCode -> DecodeBrokenTradeMessage(bytes)
              [] tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = StockStatusMessageCode -> DecodeStockStatusMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSequencedMessage == [tag |-> AddOrderMessageCode, body |-> ZeroAddOrderMessage]

(* Each Sequenced Message in turn, at the values the message it names is checked at *)
CheckedSequencedMessage ==
    { [tag |-> AddOrderMessageCode, body |-> one] : one \in CheckedAddOrderMessage }
        \cup { [tag |-> LongFormAddOrderMessageCode, body |-> one] : one \in CheckedLongFormAddOrderMessage }
        \cup { [tag |-> OrderExecutionMessageCode, body |-> one] : one \in CheckedOrderExecutionMessage }
        \cup { [tag |-> LongFormOrderExecutionMessageCode, body |-> one] : one \in CheckedLongFormOrderExecutionMessage }
        \cup { [tag |-> OrderCancelMessageCode, body |-> one] : one \in CheckedOrderCancelMessage }
        \cup { [tag |-> LongFormOrderCancelMessageCode, body |-> one] : one \in CheckedLongFormOrderCancelMessage }
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> LongFormTradeMessageCode, body |-> one] : one \in CheckedLongFormTradeMessage }
        \cup { [tag |-> BrokenTradeMessageCode, body |-> one] : one \in CheckedBrokenTradeMessage }
        \cup { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> StockStatusMessageCode, body |-> one] : one \in CheckedStockStatusMessage }

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
    LET messageType == ReadUIntBE(timestamp.rest, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET sequencedMessage == DecodeSequencedMessage(messageType.value, messageType.rest) IN IF ~sequencedMessage.ok THEN Fail ELSE
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
(* Server Payload, selected by Server Packet Type                          *)
(***************************************************************************)

DebugPacketCode == 43  \* "+"
LoginAcceptedPacketCode == 65  \* "A"
LoginRejectedPacketCode == 74  \* "J"
SequencedDataPacketCode == 83  \* "S"

ServerPayload ==
    [ tag : {DebugPacketCode}, body : DebugPacket ]
        \cup [ tag : {LoginAcceptedPacketCode}, body : LoginAcceptedPacket ]
        \cup [ tag : {LoginRejectedPacketCode}, body : LoginRejectedPacket ]
        \cup [ tag : {SequencedDataPacketCode}, body : SequencedDataPacket ]

EncodeServerPayload(message) ==
    CASE message.tag = DebugPacketCode -> EncodeDebugPacket(message.body)
      [] message.tag = LoginAcceptedPacketCode -> EncodeLoginAcceptedPacket(message.body)
      [] message.tag = LoginRejectedPacketCode -> EncodeLoginRejectedPacket(message.body)
      [] message.tag = SequencedDataPacketCode -> EncodeSequencedDataPacket(message.body)

DecodeServerPayload(tag, bytes) ==
    LET read ==
            CASE tag = DebugPacketCode -> DecodeDebugPacket(bytes)
              [] tag = LoginAcceptedPacketCode -> DecodeLoginAcceptedPacket(bytes)
              [] tag = LoginRejectedPacketCode -> DecodeLoginRejectedPacket(bytes)
              [] tag = SequencedDataPacketCode -> DecodeSequencedDataPacket(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroServerPayload == [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]

(* Each Server Payload in turn, at the values the message it names is checked at *)
CheckedServerPayload ==
    { [tag |-> DebugPacketCode, body |-> one] : one \in CheckedDebugPacket }
        \cup { [tag |-> LoginAcceptedPacketCode, body |-> one] : one \in CheckedLoginAcceptedPacket }
        \cup { [tag |-> LoginRejectedPacketCode, body |-> one] : one \in CheckedLoginRejectedPacket }
        \cup { [tag |-> SequencedDataPacketCode, body |-> one] : one \in CheckedSequencedDataPacket }

(***************************************************************************)
(* Server Packet                                                           *)
(***************************************************************************)

ServerPacket ==
    [ serverPayload : ServerPayload,
      soupLf        : Sample(1) ]

EncodeServerPacket(message) ==
    EncodeUIntBE(message.serverPayload.tag, 1)
        \o EncodeServerPayload(message.serverPayload)
        \o message.soupLf

DecodeServerPacket(bytes) ==
    LET serverPacketType == ReadUIntBE(bytes, 1) IN IF ~serverPacketType.ok THEN Fail ELSE
    LET serverPayload == DecodeServerPayload(serverPacketType.value, serverPacketType.rest) IN IF ~serverPayload.ok THEN Fail ELSE
    LET soupLf == ReadBytes(serverPayload.rest, 1) IN IF ~soupLf.ok THEN Fail ELSE
    Ok([ serverPayload |-> serverPayload.value,
         soupLf        |-> soupLf.value ], soupLf.rest)

ZeroServerPacket ==
    [ serverPayload |-> ZeroServerPayload,
      soupLf        |-> [i \in 1 .. 1 |-> 0] ]

(* Server Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerPacket ==
    { ZeroServerPacket }
        \cup { [ZeroServerPacket EXCEPT !.serverPayload = one] : one \in CheckedServerPayload }
        \cup { [ZeroServerPacket EXCEPT !.soupLf = one] : one \in Sample(1) }

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

(* Every Add Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderMessage ==
    \A message \in CheckedAddOrderMessage :
        LET read == DecodeAddOrderMessage(EncodeAddOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Form Add Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLongFormAddOrderMessage ==
    \A message \in CheckedLongFormAddOrderMessage :
        LET read == DecodeLongFormAddOrderMessage(EncodeLongFormAddOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Execution Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutionMessage ==
    \A message \in CheckedOrderExecutionMessage :
        LET read == DecodeOrderExecutionMessage(EncodeOrderExecutionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Form Order Execution Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLongFormOrderExecutionMessage ==
    \A message \in CheckedLongFormOrderExecutionMessage :
        LET read == DecodeLongFormOrderExecutionMessage(EncodeLongFormOrderExecutionMessage(message))
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

(* Every Long Form Order Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLongFormOrderCancelMessage ==
    \A message \in CheckedLongFormOrderCancelMessage :
        LET read == DecodeLongFormOrderCancelMessage(EncodeLongFormOrderCancelMessage(message))
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

(* Every Long Form Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLongFormTradeMessage ==
    \A message \in CheckedLongFormTradeMessage :
        LET read == DecodeLongFormTradeMessage(EncodeLongFormTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Broken Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBrokenTradeMessage ==
    \A message \in CheckedBrokenTradeMessage :
        LET read == DecodeBrokenTradeMessage(EncodeBrokenTradeMessage(message))
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

(* Every Stock Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStockStatusMessage ==
    \A message \in CheckedStockStatusMessage :
        LET read == DecodeStockStatusMessage(EncodeStockStatusMessage(message))
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

(* Every Server Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripServerPacket ==
    \A message \in CheckedServerPacket :
        LET read == DecodeServerPacket(EncodeServerPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Sequenced Message is selected by the Message Type it is written under *)
SelectsSequencedMessage ==
    \A message \in CheckedSequencedMessage :
        LET read == DecodeSequencedMessage(message.tag, EncodeSequencedMessage(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Server Payload is selected by the Server Packet Type it is written under *)
SelectsServerPayload ==
    \A message \in CheckedServerPayload :
        LET read == DecodeServerPayload(message.tag, EncodeServerPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
