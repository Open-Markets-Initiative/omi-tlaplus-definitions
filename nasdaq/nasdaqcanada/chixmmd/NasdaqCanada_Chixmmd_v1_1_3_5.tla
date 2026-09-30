------------------- MODULE NasdaqCanada_Chixmmd_v1_1_3_5 -------------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) CHIXMMD Multicast Market Data v1.1.3                           *)
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
(* Note: a Message Count of any value but 0 is that many Message.          *)
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
(* Heartbeat: 10 bytes                                                     *)
(***************************************************************************)

Heartbeat ==
    [ session : Sample(10) ]

EncodeHeartbeat(message) ==
    message.session

DecodeHeartbeat(bytes) ==
    LET session == ReadBytes(bytes, 10) IN IF ~session.ok THEN Fail ELSE
    Ok([ session |-> session.value ], session.rest)

ZeroHeartbeat ==
    [ session |-> [i \in 1 .. 10 |-> 0] ]

(* Heartbeat at zero, then each field in turn at the values it is checked at *)
CheckedHeartbeat ==
    { ZeroHeartbeat }
        \cup { [ZeroHeartbeat EXCEPT !.session = one] : one \in Sample(10) }

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
(* Payload, selected by Message Type                                       *)
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

Payload ==
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

EncodePayload(message) ==
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

DecodePayload(tag, bytes) ==
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

ZeroPayload == [tag |-> AddOrderMessageCode, body |-> ZeroAddOrderMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
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
(* Message, framed by Length                                               *)
(***************************************************************************)

Message ==
    [ timestamp : Sample(8),
      payload   : Payload ]

EncodeMessageBody(message) ==
    message.timestamp
        \o EncodeUIntBE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

(* Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeMessageBody(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET messageType == ReadUIntBE(timestamp.rest, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ timestamp |-> timestamp.value,
         payload   |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroMessage ==
    [ timestamp |-> [i \in 1 .. 8 |-> 0],
      payload   |-> ZeroPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> AddOrderMessageCode, body |-> ZeroAddOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LongFormAddOrderMessageCode, body |-> ZeroLongFormAddOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderExecutionMessageCode, body |-> ZeroOrderExecutionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LongFormOrderExecutionMessageCode, body |-> ZeroLongFormOrderExecutionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderCancelMessageCode, body |-> ZeroOrderCancelMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LongFormOrderCancelMessageCode, body |-> ZeroLongFormOrderCancelMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeMessageCode, body |-> ZeroTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LongFormTradeMessageCode, body |-> ZeroLongFormTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> BrokenTradeMessageCode, body |-> ZeroBrokenTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StockStatusMessageCode, body |-> ZeroStockStatusMessage]] }

(***************************************************************************)
(* Messages, selected by Message Count                                     *)
(***************************************************************************)

HeartbeatCode == 0  \* 0x00

Messages ==
    [ tag : {HeartbeatCode}, body : Heartbeat ]
        \cup { [tag |-> Len(one), body |-> one] : one \in { run \in SampleLists(OneMessage) : Len(run) # HeartbeatCode } }

EncodeMessages(message) ==
    CASE message.tag = HeartbeatCode -> EncodeHeartbeat(message.body)
      [] OTHER -> EncodeMessageList(message.body)

DecodeMessages(tag, bytes) ==
    LET read ==
            CASE tag = HeartbeatCode -> DecodeHeartbeat(bytes)
              [] OTHER -> ReadMessageList(bytes, tag)
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroMessages == [tag |-> HeartbeatCode, body |-> ZeroHeartbeat]

(* Each Messages in turn, at the values the message it names is checked at *)
CheckedMessages ==
    { [tag |-> HeartbeatCode, body |-> one] : one \in CheckedHeartbeat }
        \cup { [tag |-> Len(one), body |-> one] : one \in { run \in SampleLists(OneMessage) : Len(run) # HeartbeatCode } }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ sequence : Sample(4),
      messages : Messages ]

EncodePacket(message) ==
    message.sequence
        \o EncodeUIntBE(message.messages.tag, 2)
        \o EncodeMessages(message.messages)

DecodePacket(bytes) ==
    LET sequence == ReadBytes(bytes, 4) IN IF ~sequence.ok THEN Fail ELSE
    LET messageCount == ReadUIntBE(sequence.rest, 2) IN IF ~messageCount.ok THEN Fail ELSE
    LET messages == DecodeMessages(messageCount.value, messageCount.rest) IN IF ~messages.ok THEN Fail ELSE
    Ok([ sequence |-> sequence.value,
         messages |-> messages.value ], messages.rest)

ZeroPacket ==
    [ sequence |-> [i \in 1 .. 4 |-> 0],
      messages |-> ZeroMessages ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.sequence = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.messages = one] : one \in CheckedMessages }

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

(* Every Heartbeat decodes back to what was encoded, and leaves nothing over *)
RoundTripHeartbeat ==
    \A message \in CheckedHeartbeat :
        LET read == DecodeHeartbeat(EncodeHeartbeat(message))
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

(* A Messages is selected by the Message Count it is written under *)
SelectsMessages ==
    \A message \in CheckedMessages :
        LET read == DecodeMessages(message.tag, EncodeMessages(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Length is written from the bytes it frames *)
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
