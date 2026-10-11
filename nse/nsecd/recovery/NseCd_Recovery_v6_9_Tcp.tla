---------------------- MODULE NseCd_Recovery_v6_9_Tcp ----------------------
(***************************************************************************)
(* National Stock Exchange of India Ltd Mtbt Tick Data Recovery v6.9       *)
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
(* New Order Message: 29 bytes                                             *)
(***************************************************************************)

NewOrderMessage ==
    [ timestamp : Sample(8),
      orderId   : Sample(8),
      token     : Sample(4),
      orderType : Sample(1),
      price     : Sample(4),
      quantity  : Sample(4) ]

EncodeNewOrderMessage(message) ==
    message.timestamp
        \o message.orderId
        \o message.token
        \o message.orderType
        \o message.price
        \o message.quantity

DecodeNewOrderMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderId == ReadBytes(timestamp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET token == ReadBytes(orderId.rest, 4) IN IF ~token.ok THEN Fail ELSE
    LET orderType == ReadBytes(token.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET price == ReadBytes(orderType.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    Ok([ timestamp |-> timestamp.value,
         orderId   |-> orderId.value,
         token     |-> token.value,
         orderType |-> orderType.value,
         price     |-> price.value,
         quantity  |-> quantity.value ], quantity.rest)

ZeroNewOrderMessage ==
    [ timestamp |-> [i \in 1 .. 8 |-> 0],
      orderId   |-> [i \in 1 .. 8 |-> 0],
      token     |-> [i \in 1 .. 4 |-> 0],
      orderType |-> [i \in 1 .. 1 |-> 0],
      price     |-> [i \in 1 .. 4 |-> 0],
      quantity  |-> [i \in 1 .. 4 |-> 0] ]

(* New Order Message at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderMessage ==
    { ZeroNewOrderMessage }
        \cup { [ZeroNewOrderMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderMessage EXCEPT !.token = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderMessage EXCEPT !.quantity = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Modification Message: 29 bytes                                    *)
(***************************************************************************)

OrderModificationMessage ==
    [ timestamp : Sample(8),
      orderId   : Sample(8),
      token     : Sample(4),
      orderType : Sample(1),
      price     : Sample(4),
      quantity  : Sample(4) ]

EncodeOrderModificationMessage(message) ==
    message.timestamp
        \o message.orderId
        \o message.token
        \o message.orderType
        \o message.price
        \o message.quantity

DecodeOrderModificationMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderId == ReadBytes(timestamp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET token == ReadBytes(orderId.rest, 4) IN IF ~token.ok THEN Fail ELSE
    LET orderType == ReadBytes(token.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET price == ReadBytes(orderType.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    Ok([ timestamp |-> timestamp.value,
         orderId   |-> orderId.value,
         token     |-> token.value,
         orderType |-> orderType.value,
         price     |-> price.value,
         quantity  |-> quantity.value ], quantity.rest)

ZeroOrderModificationMessage ==
    [ timestamp |-> [i \in 1 .. 8 |-> 0],
      orderId   |-> [i \in 1 .. 8 |-> 0],
      token     |-> [i \in 1 .. 4 |-> 0],
      orderType |-> [i \in 1 .. 1 |-> 0],
      price     |-> [i \in 1 .. 4 |-> 0],
      quantity  |-> [i \in 1 .. 4 |-> 0] ]

(* Order Modification Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderModificationMessage ==
    { ZeroOrderModificationMessage }
        \cup { [ZeroOrderModificationMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderModificationMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderModificationMessage EXCEPT !.token = one] : one \in Sample(4) }
        \cup { [ZeroOrderModificationMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroOrderModificationMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderModificationMessage EXCEPT !.quantity = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Cancellation Message: 29 bytes                                    *)
(***************************************************************************)

OrderCancellationMessage ==
    [ timestamp : Sample(8),
      orderId   : Sample(8),
      token     : Sample(4),
      orderType : Sample(1),
      price     : Sample(4),
      quantity  : Sample(4) ]

EncodeOrderCancellationMessage(message) ==
    message.timestamp
        \o message.orderId
        \o message.token
        \o message.orderType
        \o message.price
        \o message.quantity

DecodeOrderCancellationMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderId == ReadBytes(timestamp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET token == ReadBytes(orderId.rest, 4) IN IF ~token.ok THEN Fail ELSE
    LET orderType == ReadBytes(token.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET price == ReadBytes(orderType.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    Ok([ timestamp |-> timestamp.value,
         orderId   |-> orderId.value,
         token     |-> token.value,
         orderType |-> orderType.value,
         price     |-> price.value,
         quantity  |-> quantity.value ], quantity.rest)

ZeroOrderCancellationMessage ==
    [ timestamp |-> [i \in 1 .. 8 |-> 0],
      orderId   |-> [i \in 1 .. 8 |-> 0],
      token     |-> [i \in 1 .. 4 |-> 0],
      orderType |-> [i \in 1 .. 1 |-> 0],
      price     |-> [i \in 1 .. 4 |-> 0],
      quantity  |-> [i \in 1 .. 4 |-> 0] ]

(* Order Cancellation Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancellationMessage ==
    { ZeroOrderCancellationMessage }
        \cup { [ZeroOrderCancellationMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancellationMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancellationMessage EXCEPT !.token = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancellationMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancellationMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancellationMessage EXCEPT !.quantity = one] : one \in Sample(4) }

(***************************************************************************)
(* Trade Message: 36 bytes                                                 *)
(***************************************************************************)

TradeMessage ==
    [ timestamp     : Sample(8),
      buyOrderId    : Sample(8),
      sellOrderId   : Sample(8),
      token         : Sample(4),
      tradePrice    : Sample(4),
      tradeQuantity : Sample(4) ]

EncodeTradeMessage(message) ==
    message.timestamp
        \o message.buyOrderId
        \o message.sellOrderId
        \o message.token
        \o message.tradePrice
        \o message.tradeQuantity

DecodeTradeMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET buyOrderId == ReadBytes(timestamp.rest, 8) IN IF ~buyOrderId.ok THEN Fail ELSE
    LET sellOrderId == ReadBytes(buyOrderId.rest, 8) IN IF ~sellOrderId.ok THEN Fail ELSE
    LET token == ReadBytes(sellOrderId.rest, 4) IN IF ~token.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(token.rest, 4) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradeQuantity == ReadBytes(tradePrice.rest, 4) IN IF ~tradeQuantity.ok THEN Fail ELSE
    Ok([ timestamp     |-> timestamp.value,
         buyOrderId    |-> buyOrderId.value,
         sellOrderId   |-> sellOrderId.value,
         token         |-> token.value,
         tradePrice    |-> tradePrice.value,
         tradeQuantity |-> tradeQuantity.value ], tradeQuantity.rest)

ZeroTradeMessage ==
    [ timestamp     |-> [i \in 1 .. 8 |-> 0],
      buyOrderId    |-> [i \in 1 .. 8 |-> 0],
      sellOrderId   |-> [i \in 1 .. 8 |-> 0],
      token         |-> [i \in 1 .. 4 |-> 0],
      tradePrice    |-> [i \in 1 .. 4 |-> 0],
      tradeQuantity |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.buyOrderId = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.sellOrderId = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.token = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.tradePrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeQuantity = one] : one \in Sample(4) }

(***************************************************************************)
(* New Spread Order Message: 29 bytes                                      *)
(***************************************************************************)

NewSpreadOrderMessage ==
    [ timestamp : Sample(8),
      orderId   : Sample(8),
      token     : Sample(4),
      orderType : Sample(1),
      price     : Sample(4),
      quantity  : Sample(4) ]

EncodeNewSpreadOrderMessage(message) ==
    message.timestamp
        \o message.orderId
        \o message.token
        \o message.orderType
        \o message.price
        \o message.quantity

DecodeNewSpreadOrderMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderId == ReadBytes(timestamp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET token == ReadBytes(orderId.rest, 4) IN IF ~token.ok THEN Fail ELSE
    LET orderType == ReadBytes(token.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET price == ReadBytes(orderType.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    Ok([ timestamp |-> timestamp.value,
         orderId   |-> orderId.value,
         token     |-> token.value,
         orderType |-> orderType.value,
         price     |-> price.value,
         quantity  |-> quantity.value ], quantity.rest)

ZeroNewSpreadOrderMessage ==
    [ timestamp |-> [i \in 1 .. 8 |-> 0],
      orderId   |-> [i \in 1 .. 8 |-> 0],
      token     |-> [i \in 1 .. 4 |-> 0],
      orderType |-> [i \in 1 .. 1 |-> 0],
      price     |-> [i \in 1 .. 4 |-> 0],
      quantity  |-> [i \in 1 .. 4 |-> 0] ]

(* New Spread Order Message at zero, then each field in turn at the values it is checked at *)
CheckedNewSpreadOrderMessage ==
    { ZeroNewSpreadOrderMessage }
        \cup { [ZeroNewSpreadOrderMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroNewSpreadOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroNewSpreadOrderMessage EXCEPT !.token = one] : one \in Sample(4) }
        \cup { [ZeroNewSpreadOrderMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroNewSpreadOrderMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroNewSpreadOrderMessage EXCEPT !.quantity = one] : one \in Sample(4) }

(***************************************************************************)
(* Spread Order Modification Message: 29 bytes                             *)
(***************************************************************************)

SpreadOrderModificationMessage ==
    [ timestamp : Sample(8),
      orderId   : Sample(8),
      token     : Sample(4),
      orderType : Sample(1),
      price     : Sample(4),
      quantity  : Sample(4) ]

EncodeSpreadOrderModificationMessage(message) ==
    message.timestamp
        \o message.orderId
        \o message.token
        \o message.orderType
        \o message.price
        \o message.quantity

DecodeSpreadOrderModificationMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderId == ReadBytes(timestamp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET token == ReadBytes(orderId.rest, 4) IN IF ~token.ok THEN Fail ELSE
    LET orderType == ReadBytes(token.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET price == ReadBytes(orderType.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    Ok([ timestamp |-> timestamp.value,
         orderId   |-> orderId.value,
         token     |-> token.value,
         orderType |-> orderType.value,
         price     |-> price.value,
         quantity  |-> quantity.value ], quantity.rest)

ZeroSpreadOrderModificationMessage ==
    [ timestamp |-> [i \in 1 .. 8 |-> 0],
      orderId   |-> [i \in 1 .. 8 |-> 0],
      token     |-> [i \in 1 .. 4 |-> 0],
      orderType |-> [i \in 1 .. 1 |-> 0],
      price     |-> [i \in 1 .. 4 |-> 0],
      quantity  |-> [i \in 1 .. 4 |-> 0] ]

(* Spread Order Modification Message at zero, then each field in turn at the values it is checked at *)
CheckedSpreadOrderModificationMessage ==
    { ZeroSpreadOrderModificationMessage }
        \cup { [ZeroSpreadOrderModificationMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSpreadOrderModificationMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroSpreadOrderModificationMessage EXCEPT !.token = one] : one \in Sample(4) }
        \cup { [ZeroSpreadOrderModificationMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroSpreadOrderModificationMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroSpreadOrderModificationMessage EXCEPT !.quantity = one] : one \in Sample(4) }

(***************************************************************************)
(* Spread Order Cancellation Message: 29 bytes                             *)
(***************************************************************************)

SpreadOrderCancellationMessage ==
    [ timestamp : Sample(8),
      orderId   : Sample(8),
      token     : Sample(4),
      orderType : Sample(1),
      price     : Sample(4),
      quantity  : Sample(4) ]

EncodeSpreadOrderCancellationMessage(message) ==
    message.timestamp
        \o message.orderId
        \o message.token
        \o message.orderType
        \o message.price
        \o message.quantity

DecodeSpreadOrderCancellationMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderId == ReadBytes(timestamp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET token == ReadBytes(orderId.rest, 4) IN IF ~token.ok THEN Fail ELSE
    LET orderType == ReadBytes(token.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET price == ReadBytes(orderType.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    Ok([ timestamp |-> timestamp.value,
         orderId   |-> orderId.value,
         token     |-> token.value,
         orderType |-> orderType.value,
         price     |-> price.value,
         quantity  |-> quantity.value ], quantity.rest)

ZeroSpreadOrderCancellationMessage ==
    [ timestamp |-> [i \in 1 .. 8 |-> 0],
      orderId   |-> [i \in 1 .. 8 |-> 0],
      token     |-> [i \in 1 .. 4 |-> 0],
      orderType |-> [i \in 1 .. 1 |-> 0],
      price     |-> [i \in 1 .. 4 |-> 0],
      quantity  |-> [i \in 1 .. 4 |-> 0] ]

(* Spread Order Cancellation Message at zero, then each field in turn at the values it is checked at *)
CheckedSpreadOrderCancellationMessage ==
    { ZeroSpreadOrderCancellationMessage }
        \cup { [ZeroSpreadOrderCancellationMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSpreadOrderCancellationMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroSpreadOrderCancellationMessage EXCEPT !.token = one] : one \in Sample(4) }
        \cup { [ZeroSpreadOrderCancellationMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroSpreadOrderCancellationMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroSpreadOrderCancellationMessage EXCEPT !.quantity = one] : one \in Sample(4) }

(***************************************************************************)
(* Spread Trade Message: 36 bytes                                          *)
(***************************************************************************)

SpreadTradeMessage ==
    [ timestamp   : Sample(8),
      buyOrderId  : Sample(8),
      sellOrderId : Sample(8),
      token       : Sample(4),
      tradePrice  : Sample(4),
      quantity    : Sample(4) ]

EncodeSpreadTradeMessage(message) ==
    message.timestamp
        \o message.buyOrderId
        \o message.sellOrderId
        \o message.token
        \o message.tradePrice
        \o message.quantity

DecodeSpreadTradeMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET buyOrderId == ReadBytes(timestamp.rest, 8) IN IF ~buyOrderId.ok THEN Fail ELSE
    LET sellOrderId == ReadBytes(buyOrderId.rest, 8) IN IF ~sellOrderId.ok THEN Fail ELSE
    LET token == ReadBytes(sellOrderId.rest, 4) IN IF ~token.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(token.rest, 4) IN IF ~tradePrice.ok THEN Fail ELSE
    LET quantity == ReadBytes(tradePrice.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    Ok([ timestamp   |-> timestamp.value,
         buyOrderId  |-> buyOrderId.value,
         sellOrderId |-> sellOrderId.value,
         token       |-> token.value,
         tradePrice  |-> tradePrice.value,
         quantity    |-> quantity.value ], quantity.rest)

ZeroSpreadTradeMessage ==
    [ timestamp   |-> [i \in 1 .. 8 |-> 0],
      buyOrderId  |-> [i \in 1 .. 8 |-> 0],
      sellOrderId |-> [i \in 1 .. 8 |-> 0],
      token       |-> [i \in 1 .. 4 |-> 0],
      tradePrice  |-> [i \in 1 .. 4 |-> 0],
      quantity    |-> [i \in 1 .. 4 |-> 0] ]

(* Spread Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedSpreadTradeMessage ==
    { ZeroSpreadTradeMessage }
        \cup { [ZeroSpreadTradeMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSpreadTradeMessage EXCEPT !.buyOrderId = one] : one \in Sample(8) }
        \cup { [ZeroSpreadTradeMessage EXCEPT !.sellOrderId = one] : one \in Sample(8) }
        \cup { [ZeroSpreadTradeMessage EXCEPT !.token = one] : one \in Sample(4) }
        \cup { [ZeroSpreadTradeMessage EXCEPT !.tradePrice = one] : one \in Sample(4) }
        \cup { [ZeroSpreadTradeMessage EXCEPT !.quantity = one] : one \in Sample(4) }

(***************************************************************************)
(* Trade Cancel Message: 36 bytes                                          *)
(***************************************************************************)

TradeCancelMessage ==
    [ timestamp     : Sample(8),
      buyOrderId    : Sample(8),
      sellOrderId   : Sample(8),
      token         : Sample(4),
      tradePrice    : Sample(4),
      tradeQuantity : Sample(4) ]

EncodeTradeCancelMessage(message) ==
    message.timestamp
        \o message.buyOrderId
        \o message.sellOrderId
        \o message.token
        \o message.tradePrice
        \o message.tradeQuantity

DecodeTradeCancelMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET buyOrderId == ReadBytes(timestamp.rest, 8) IN IF ~buyOrderId.ok THEN Fail ELSE
    LET sellOrderId == ReadBytes(buyOrderId.rest, 8) IN IF ~sellOrderId.ok THEN Fail ELSE
    LET token == ReadBytes(sellOrderId.rest, 4) IN IF ~token.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(token.rest, 4) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradeQuantity == ReadBytes(tradePrice.rest, 4) IN IF ~tradeQuantity.ok THEN Fail ELSE
    Ok([ timestamp     |-> timestamp.value,
         buyOrderId    |-> buyOrderId.value,
         sellOrderId   |-> sellOrderId.value,
         token         |-> token.value,
         tradePrice    |-> tradePrice.value,
         tradeQuantity |-> tradeQuantity.value ], tradeQuantity.rest)

ZeroTradeCancelMessage ==
    [ timestamp     |-> [i \in 1 .. 8 |-> 0],
      buyOrderId    |-> [i \in 1 .. 8 |-> 0],
      sellOrderId   |-> [i \in 1 .. 8 |-> 0],
      token         |-> [i \in 1 .. 4 |-> 0],
      tradePrice    |-> [i \in 1 .. 4 |-> 0],
      tradeQuantity |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCancelMessage ==
    { ZeroTradeCancelMessage }
        \cup { [ZeroTradeCancelMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelMessage EXCEPT !.buyOrderId = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelMessage EXCEPT !.sellOrderId = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelMessage EXCEPT !.token = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelMessage EXCEPT !.tradePrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelMessage EXCEPT !.tradeQuantity = one] : one \in Sample(4) }

(***************************************************************************)
(* Heartbeat Message: 4 bytes                                              *)
(***************************************************************************)

HeartbeatMessage ==
    [ lastSequenceNo : Sample(4) ]

EncodeHeartbeatMessage(message) ==
    message.lastSequenceNo

DecodeHeartbeatMessage(bytes) ==
    LET lastSequenceNo == ReadBytes(bytes, 4) IN IF ~lastSequenceNo.ok THEN Fail ELSE
    Ok([ lastSequenceNo |-> lastSequenceNo.value ], lastSequenceNo.rest)

ZeroHeartbeatMessage ==
    [ lastSequenceNo |-> [i \in 1 .. 4 |-> 0] ]

(* Heartbeat Message at zero, then each field in turn at the values it is checked at *)
CheckedHeartbeatMessage ==
    { ZeroHeartbeatMessage }
        \cup { [ZeroHeartbeatMessage EXCEPT !.lastSequenceNo = one] : one \in Sample(4) }

(***************************************************************************)
(* Tick Data Recovery Response Message: 1 bytes                            *)
(***************************************************************************)

TickDataRecoveryResponseMessage ==
    [ requestStatus : Sample(1) ]

EncodeTickDataRecoveryResponseMessage(message) ==
    message.requestStatus

DecodeTickDataRecoveryResponseMessage(bytes) ==
    LET requestStatus == ReadBytes(bytes, 1) IN IF ~requestStatus.ok THEN Fail ELSE
    Ok([ requestStatus |-> requestStatus.value ], requestStatus.rest)

ZeroTickDataRecoveryResponseMessage ==
    [ requestStatus |-> [i \in 1 .. 1 |-> 0] ]

(* Tick Data Recovery Response Message at zero, then each field in turn at the values it is checked at *)
CheckedTickDataRecoveryResponseMessage ==
    { ZeroTickDataRecoveryResponseMessage }
        \cup { [ZeroTickDataRecoveryResponseMessage EXCEPT !.requestStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

NewOrderMessageCode == 78  \* "N"
OrderModificationMessageCode == 77  \* "M"
OrderCancellationMessageCode == 88  \* "X"
TradeMessageCode == 84  \* "T"
NewSpreadOrderMessageCode == 71  \* "G"
SpreadOrderModificationMessageCode == 72  \* "H"
SpreadOrderCancellationMessageCode == 74  \* "J"
SpreadTradeMessageCode == 75  \* "K"
TradeCancelMessageCode == 67  \* "C"
HeartbeatMessageCode == 90  \* "Z"
TickDataRecoveryResponseMessageCode == 89  \* "Y"

Payload ==
    [ tag : {NewOrderMessageCode}, body : NewOrderMessage ]
        \cup [ tag : {OrderModificationMessageCode}, body : OrderModificationMessage ]
        \cup [ tag : {OrderCancellationMessageCode}, body : OrderCancellationMessage ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {NewSpreadOrderMessageCode}, body : NewSpreadOrderMessage ]
        \cup [ tag : {SpreadOrderModificationMessageCode}, body : SpreadOrderModificationMessage ]
        \cup [ tag : {SpreadOrderCancellationMessageCode}, body : SpreadOrderCancellationMessage ]
        \cup [ tag : {SpreadTradeMessageCode}, body : SpreadTradeMessage ]
        \cup [ tag : {TradeCancelMessageCode}, body : TradeCancelMessage ]
        \cup [ tag : {HeartbeatMessageCode}, body : HeartbeatMessage ]
        \cup [ tag : {TickDataRecoveryResponseMessageCode}, body : TickDataRecoveryResponseMessage ]

EncodePayload(message) ==
    CASE message.tag = NewOrderMessageCode -> EncodeNewOrderMessage(message.body)
      [] message.tag = OrderModificationMessageCode -> EncodeOrderModificationMessage(message.body)
      [] message.tag = OrderCancellationMessageCode -> EncodeOrderCancellationMessage(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = NewSpreadOrderMessageCode -> EncodeNewSpreadOrderMessage(message.body)
      [] message.tag = SpreadOrderModificationMessageCode -> EncodeSpreadOrderModificationMessage(message.body)
      [] message.tag = SpreadOrderCancellationMessageCode -> EncodeSpreadOrderCancellationMessage(message.body)
      [] message.tag = SpreadTradeMessageCode -> EncodeSpreadTradeMessage(message.body)
      [] message.tag = TradeCancelMessageCode -> EncodeTradeCancelMessage(message.body)
      [] message.tag = HeartbeatMessageCode -> EncodeHeartbeatMessage(message.body)
      [] message.tag = TickDataRecoveryResponseMessageCode -> EncodeTickDataRecoveryResponseMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = NewOrderMessageCode -> DecodeNewOrderMessage(bytes)
              [] tag = OrderModificationMessageCode -> DecodeOrderModificationMessage(bytes)
              [] tag = OrderCancellationMessageCode -> DecodeOrderCancellationMessage(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = NewSpreadOrderMessageCode -> DecodeNewSpreadOrderMessage(bytes)
              [] tag = SpreadOrderModificationMessageCode -> DecodeSpreadOrderModificationMessage(bytes)
              [] tag = SpreadOrderCancellationMessageCode -> DecodeSpreadOrderCancellationMessage(bytes)
              [] tag = SpreadTradeMessageCode -> DecodeSpreadTradeMessage(bytes)
              [] tag = TradeCancelMessageCode -> DecodeTradeCancelMessage(bytes)
              [] tag = HeartbeatMessageCode -> DecodeHeartbeatMessage(bytes)
              [] tag = TickDataRecoveryResponseMessageCode -> DecodeTickDataRecoveryResponseMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> NewOrderMessageCode, body |-> ZeroNewOrderMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> NewOrderMessageCode, body |-> one] : one \in CheckedNewOrderMessage }
        \cup { [tag |-> OrderModificationMessageCode, body |-> one] : one \in CheckedOrderModificationMessage }
        \cup { [tag |-> OrderCancellationMessageCode, body |-> one] : one \in CheckedOrderCancellationMessage }
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> NewSpreadOrderMessageCode, body |-> one] : one \in CheckedNewSpreadOrderMessage }
        \cup { [tag |-> SpreadOrderModificationMessageCode, body |-> one] : one \in CheckedSpreadOrderModificationMessage }
        \cup { [tag |-> SpreadOrderCancellationMessageCode, body |-> one] : one \in CheckedSpreadOrderCancellationMessage }
        \cup { [tag |-> SpreadTradeMessageCode, body |-> one] : one \in CheckedSpreadTradeMessage }
        \cup { [tag |-> TradeCancelMessageCode, body |-> one] : one \in CheckedTradeCancelMessage }
        \cup { [tag |-> HeartbeatMessageCode, body |-> one] : one \in CheckedHeartbeatMessage }
        \cup { [tag |-> TickDataRecoveryResponseMessageCode, body |-> one] : one \in CheckedTickDataRecoveryResponseMessage }

(***************************************************************************)
(* Message                                                                 *)
(***************************************************************************)

Message ==
    [ payload : Payload ]

EncodeMessage(message) ==
    EncodeUIntBE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

DecodeMessage(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

ZeroMessage ==
    [ payload |-> ZeroPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.payload = one] : one \in CheckedPayload }

(***************************************************************************)
(* Stream Packet, framed by Message Length                                 *)
(***************************************************************************)

StreamPacket ==
    [ streamId       : Sample(2),
      sequenceNumber : Sample(4),
      message        : Message ]

EncodeStreamPacketBody(message) ==
    message.streamId
        \o message.sequenceNumber
        \o EncodeMessage(message.message)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeStreamPacket(message) ==
    LET body == EncodeStreamPacketBody(message)
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeStreamPacketBody(bytes) ==
    LET streamId == ReadBytes(bytes, 2) IN IF ~streamId.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(streamId.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET message == DecodeMessage(sequenceNumber.rest) IN IF ~message.ok THEN Fail ELSE
    Ok([ streamId       |-> streamId.value,
         sequenceNumber |-> sequenceNumber.value,
         message        |-> message.value ], message.rest)

DecodeStreamPacket(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeStreamPacketBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroStreamPacket ==
    [ streamId       |-> [i \in 1 .. 2 |-> 0],
      sequenceNumber |-> [i \in 1 .. 4 |-> 0],
      message        |-> ZeroMessage ]

(* Stream Packet at zero, then each field in turn at the values it is checked at *)
CheckedStreamPacket ==
    { ZeroStreamPacket }
        \cup { [ZeroStreamPacket EXCEPT !.streamId = one] : one \in Sample(2) }
        \cup { [ZeroStreamPacket EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroStreamPacket EXCEPT !.message = one] : one \in CheckedMessage }

(* A run of Stream Packet, written one after another *)
RECURSIVE EncodeStreamPacketList(_)
EncodeStreamPacketList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeStreamPacket(Head(messages)) \o EncodeStreamPacketList(Tail(messages))

(* As many Stream Packet as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadStreamPacketAll(_)
ReadStreamPacketAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeStreamPacket(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadStreamPacketAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Stream Packet of each kind, for the lists that carry them *)
OneStreamPacket == { ZeroStreamPacket }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ streamPacket : SampleLists(OneStreamPacket) ]

EncodePacket(message) ==
    EncodeStreamPacketList(message.streamPacket)

DecodePacket(bytes) ==
    LET streamPacket == ReadStreamPacketAll(bytes) IN IF ~streamPacket.ok THEN Fail ELSE
    Ok([ streamPacket |-> streamPacket.value ], streamPacket.rest)

ZeroPacket ==
    [ streamPacket |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.streamPacket = one] : one \in SampleLists(OneStreamPacket) }

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

(* Every New Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderMessage ==
    \A message \in CheckedNewOrderMessage :
        LET read == DecodeNewOrderMessage(EncodeNewOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Modification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderModificationMessage ==
    \A message \in CheckedOrderModificationMessage :
        LET read == DecodeOrderModificationMessage(EncodeOrderModificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancellation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancellationMessage ==
    \A message \in CheckedOrderCancellationMessage :
        LET read == DecodeOrderCancellationMessage(EncodeOrderCancellationMessage(message))
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

(* Every New Spread Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewSpreadOrderMessage ==
    \A message \in CheckedNewSpreadOrderMessage :
        LET read == DecodeNewSpreadOrderMessage(EncodeNewSpreadOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Spread Order Modification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSpreadOrderModificationMessage ==
    \A message \in CheckedSpreadOrderModificationMessage :
        LET read == DecodeSpreadOrderModificationMessage(EncodeSpreadOrderModificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Spread Order Cancellation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSpreadOrderCancellationMessage ==
    \A message \in CheckedSpreadOrderCancellationMessage :
        LET read == DecodeSpreadOrderCancellationMessage(EncodeSpreadOrderCancellationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Spread Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSpreadTradeMessage ==
    \A message \in CheckedSpreadTradeMessage :
        LET read == DecodeSpreadTradeMessage(EncodeSpreadTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCancelMessage ==
    \A message \in CheckedTradeCancelMessage :
        LET read == DecodeTradeCancelMessage(EncodeTradeCancelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Heartbeat Message decodes back to what was encoded, and leaves nothing over *)
RoundTripHeartbeatMessage ==
    \A message \in CheckedHeartbeatMessage :
        LET read == DecodeHeartbeatMessage(EncodeHeartbeatMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tick Data Recovery Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTickDataRecoveryResponseMessage ==
    \A message \in CheckedTickDataRecoveryResponseMessage :
        LET read == DecodeTickDataRecoveryResponseMessage(EncodeTickDataRecoveryResponseMessage(message))
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

(* Every Stream Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripStreamPacket ==
    \A message \in CheckedStreamPacket :
        LET read == DecodeStreamPacket(EncodeStreamPacket(message))
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

(* Message Length is written from the bytes it frames *)
FramesStreamPacket ==
    \A message \in CheckedStreamPacket :
        LET bytes == EncodeStreamPacket(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
