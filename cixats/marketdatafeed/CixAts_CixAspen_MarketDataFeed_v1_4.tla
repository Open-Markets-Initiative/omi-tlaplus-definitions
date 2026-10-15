---------------- MODULE CixAts_CixAspen_MarketDataFeed_v1_4 ----------------
(***************************************************************************)
(* CIX Trading Inc. CIX Market Data Feed v1.4                              *)
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
(* Market Event Message: 11 bytes                                          *)
(***************************************************************************)

MarketEventMessage ==
    [ reserved2 : Sample(2),
      timestamp : Sample(8),
      event     : Sample(1) ]

EncodeMarketEventMessage(message) ==
    message.reserved2
        \o message.timestamp
        \o message.event

DecodeMarketEventMessage(bytes) ==
    LET reserved2 == ReadBytes(bytes, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET timestamp == ReadBytes(reserved2.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET event == ReadBytes(timestamp.rest, 1) IN IF ~event.ok THEN Fail ELSE
    Ok([ reserved2 |-> reserved2.value,
         timestamp |-> timestamp.value,
         event     |-> event.value ], event.rest)

ZeroMarketEventMessage ==
    [ reserved2 |-> [i \in 1 .. 2 |-> 0],
      timestamp |-> [i \in 1 .. 8 |-> 0],
      event     |-> [i \in 1 .. 1 |-> 0] ]

(* Market Event Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketEventMessage ==
    { ZeroMarketEventMessage }
        \cup { [ZeroMarketEventMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroMarketEventMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroMarketEventMessage EXCEPT !.event = one] : one \in Sample(1) }

(***************************************************************************)
(* Symbol Information Message: 26 bytes                                    *)
(***************************************************************************)

SymbolInformationMessage ==
    [ timestamp     : Sample(8),
      symbolId      : Sample(2),
      symbol        : Sample(11),
      listingMarket : Sample(1),
      boardLotSize  : Sample(4) ]

EncodeSymbolInformationMessage(message) ==
    message.timestamp
        \o message.symbolId
        \o message.symbol
        \o message.listingMarket
        \o message.boardLotSize

DecodeSymbolInformationMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbolId == ReadBytes(timestamp.rest, 2) IN IF ~symbolId.ok THEN Fail ELSE
    LET symbol == ReadBytes(symbolId.rest, 11) IN IF ~symbol.ok THEN Fail ELSE
    LET listingMarket == ReadBytes(symbol.rest, 1) IN IF ~listingMarket.ok THEN Fail ELSE
    LET boardLotSize == ReadBytes(listingMarket.rest, 4) IN IF ~boardLotSize.ok THEN Fail ELSE
    Ok([ timestamp     |-> timestamp.value,
         symbolId      |-> symbolId.value,
         symbol        |-> symbol.value,
         listingMarket |-> listingMarket.value,
         boardLotSize  |-> boardLotSize.value ], boardLotSize.rest)

ZeroSymbolInformationMessage ==
    [ timestamp     |-> [i \in 1 .. 8 |-> 0],
      symbolId      |-> [i \in 1 .. 2 |-> 0],
      symbol        |-> [i \in 1 .. 11 |-> 0],
      listingMarket |-> [i \in 1 .. 1 |-> 0],
      boardLotSize  |-> [i \in 1 .. 4 |-> 0] ]

(* Symbol Information Message at zero, then each field in turn at the values it is checked at *)
CheckedSymbolInformationMessage ==
    { ZeroSymbolInformationMessage }
        \cup { [ZeroSymbolInformationMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSymbolInformationMessage EXCEPT !.symbolId = one] : one \in Sample(2) }
        \cup { [ZeroSymbolInformationMessage EXCEPT !.symbol = one] : one \in Sample(11) }
        \cup { [ZeroSymbolInformationMessage EXCEPT !.listingMarket = one] : one \in Sample(1) }
        \cup { [ZeroSymbolInformationMessage EXCEPT !.boardLotSize = one] : one \in Sample(4) }

(***************************************************************************)
(* Symbol State Message: 27 bytes                                          *)
(***************************************************************************)

SymbolStateMessage ==
    [ timestamp : Sample(8),
      symbolId  : Sample(2),
      symbol    : Sample(11),
      state     : Sample(1),
      reserved1 : Sample(1),
      info      : Sample(4) ]

EncodeSymbolStateMessage(message) ==
    message.timestamp
        \o message.symbolId
        \o message.symbol
        \o message.state
        \o message.reserved1
        \o message.info

DecodeSymbolStateMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbolId == ReadBytes(timestamp.rest, 2) IN IF ~symbolId.ok THEN Fail ELSE
    LET symbol == ReadBytes(symbolId.rest, 11) IN IF ~symbol.ok THEN Fail ELSE
    LET state == ReadBytes(symbol.rest, 1) IN IF ~state.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(state.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET info == ReadBytes(reserved1.rest, 4) IN IF ~info.ok THEN Fail ELSE
    Ok([ timestamp |-> timestamp.value,
         symbolId  |-> symbolId.value,
         symbol    |-> symbol.value,
         state     |-> state.value,
         reserved1 |-> reserved1.value,
         info      |-> info.value ], info.rest)

ZeroSymbolStateMessage ==
    [ timestamp |-> [i \in 1 .. 8 |-> 0],
      symbolId  |-> [i \in 1 .. 2 |-> 0],
      symbol    |-> [i \in 1 .. 11 |-> 0],
      state     |-> [i \in 1 .. 1 |-> 0],
      reserved1 |-> [i \in 1 .. 1 |-> 0],
      info      |-> [i \in 1 .. 4 |-> 0] ]

(* Symbol State Message at zero, then each field in turn at the values it is checked at *)
CheckedSymbolStateMessage ==
    { ZeroSymbolStateMessage }
        \cup { [ZeroSymbolStateMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSymbolStateMessage EXCEPT !.symbolId = one] : one \in Sample(2) }
        \cup { [ZeroSymbolStateMessage EXCEPT !.symbol = one] : one \in Sample(11) }
        \cup { [ZeroSymbolStateMessage EXCEPT !.state = one] : one \in Sample(1) }
        \cup { [ZeroSymbolStateMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroSymbolStateMessage EXCEPT !.info = one] : one \in Sample(4) }

(***************************************************************************)
(* New Order Add Message: 50 bytes                                         *)
(***************************************************************************)

NewOrderAddMessage ==
    [ timestamp : Sample(8),
      symbolId  : Sample(2),
      orderId   : Sample(8),
      side      : Sample(1),
      quantity  : Sample(8),
      symbol    : Sample(11),
      price     : Sample(8),
      broker    : Sample(3),
      reserved1 : Sample(1) ]

EncodeNewOrderAddMessage(message) ==
    message.timestamp
        \o message.symbolId
        \o message.orderId
        \o message.side
        \o message.quantity
        \o message.symbol
        \o message.price
        \o message.broker
        \o message.reserved1

DecodeNewOrderAddMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbolId == ReadBytes(timestamp.rest, 2) IN IF ~symbolId.ok THEN Fail ELSE
    LET orderId == ReadBytes(symbolId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET side == ReadBytes(orderId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET quantity == ReadBytes(side.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET symbol == ReadBytes(quantity.rest, 11) IN IF ~symbol.ok THEN Fail ELSE
    LET price == ReadBytes(symbol.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET broker == ReadBytes(price.rest, 3) IN IF ~broker.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(broker.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ timestamp |-> timestamp.value,
         symbolId  |-> symbolId.value,
         orderId   |-> orderId.value,
         side      |-> side.value,
         quantity  |-> quantity.value,
         symbol    |-> symbol.value,
         price     |-> price.value,
         broker    |-> broker.value,
         reserved1 |-> reserved1.value ], reserved1.rest)

ZeroNewOrderAddMessage ==
    [ timestamp |-> [i \in 1 .. 8 |-> 0],
      symbolId  |-> [i \in 1 .. 2 |-> 0],
      orderId   |-> [i \in 1 .. 8 |-> 0],
      side      |-> [i \in 1 .. 1 |-> 0],
      quantity  |-> [i \in 1 .. 8 |-> 0],
      symbol    |-> [i \in 1 .. 11 |-> 0],
      price     |-> [i \in 1 .. 8 |-> 0],
      broker    |-> [i \in 1 .. 3 |-> 0],
      reserved1 |-> [i \in 1 .. 1 |-> 0] ]

(* New Order Add Message at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderAddMessage ==
    { ZeroNewOrderAddMessage }
        \cup { [ZeroNewOrderAddMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderAddMessage EXCEPT !.symbolId = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderAddMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderAddMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAddMessage EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderAddMessage EXCEPT !.symbol = one] : one \in Sample(11) }
        \cup { [ZeroNewOrderAddMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderAddMessage EXCEPT !.broker = one] : one \in Sample(3) }
        \cup { [ZeroNewOrderAddMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Partial Cancel Message: 24 bytes                                  *)
(***************************************************************************)

OrderPartialCancelMessage ==
    [ timestamp        : Sample(8),
      orderId          : Sample(8),
      quantityCanceled : Sample(8) ]

EncodeOrderPartialCancelMessage(message) ==
    message.timestamp
        \o message.orderId
        \o message.quantityCanceled

DecodeOrderPartialCancelMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderId == ReadBytes(timestamp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET quantityCanceled == ReadBytes(orderId.rest, 8) IN IF ~quantityCanceled.ok THEN Fail ELSE
    Ok([ timestamp        |-> timestamp.value,
         orderId          |-> orderId.value,
         quantityCanceled |-> quantityCanceled.value ], quantityCanceled.rest)

ZeroOrderPartialCancelMessage ==
    [ timestamp        |-> [i \in 1 .. 8 |-> 0],
      orderId          |-> [i \in 1 .. 8 |-> 0],
      quantityCanceled |-> [i \in 1 .. 8 |-> 0] ]

(* Order Partial Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderPartialCancelMessage ==
    { ZeroOrderPartialCancelMessage }
        \cup { [ZeroOrderPartialCancelMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderPartialCancelMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderPartialCancelMessage EXCEPT !.quantityCanceled = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Cancel All Message: 16 bytes                                      *)
(***************************************************************************)

OrderCancelAllMessage ==
    [ timestamp : Sample(8),
      orderId   : Sample(8) ]

EncodeOrderCancelAllMessage(message) ==
    message.timestamp
        \o message.orderId

DecodeOrderCancelAllMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderId == ReadBytes(timestamp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    Ok([ timestamp |-> timestamp.value,
         orderId   |-> orderId.value ], orderId.rest)

ZeroOrderCancelAllMessage ==
    [ timestamp |-> [i \in 1 .. 8 |-> 0],
      orderId   |-> [i \in 1 .. 8 |-> 0] ]

(* Order Cancel All Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelAllMessage ==
    { ZeroOrderCancelAllMessage }
        \cup { [ZeroOrderCancelAllMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelAllMessage EXCEPT !.orderId = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Executed Message: 47 bytes                                        *)
(***************************************************************************)

OrderExecutedMessage ==
    [ timestamp    : Sample(8),
      orderId      : Sample(8),
      quantity     : Sample(8),
      executionId  : Sample(8),
      side         : Sample(1),
      price        : Sample(8),
      broker       : Sample(3),
      contraBroker : Sample(3) ]

EncodeOrderExecutedMessage(message) ==
    message.timestamp
        \o message.orderId
        \o message.quantity
        \o message.executionId
        \o message.side
        \o message.price
        \o message.broker
        \o message.contraBroker

DecodeOrderExecutedMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderId == ReadBytes(timestamp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET quantity == ReadBytes(orderId.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET executionId == ReadBytes(quantity.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET side == ReadBytes(executionId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadBytes(side.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET broker == ReadBytes(price.rest, 3) IN IF ~broker.ok THEN Fail ELSE
    LET contraBroker == ReadBytes(broker.rest, 3) IN IF ~contraBroker.ok THEN Fail ELSE
    Ok([ timestamp    |-> timestamp.value,
         orderId      |-> orderId.value,
         quantity     |-> quantity.value,
         executionId  |-> executionId.value,
         side         |-> side.value,
         price        |-> price.value,
         broker       |-> broker.value,
         contraBroker |-> contraBroker.value ], contraBroker.rest)

ZeroOrderExecutedMessage ==
    [ timestamp    |-> [i \in 1 .. 8 |-> 0],
      orderId      |-> [i \in 1 .. 8 |-> 0],
      quantity     |-> [i \in 1 .. 8 |-> 0],
      executionId  |-> [i \in 1 .. 8 |-> 0],
      side         |-> [i \in 1 .. 1 |-> 0],
      price        |-> [i \in 1 .. 8 |-> 0],
      broker       |-> [i \in 1 .. 3 |-> 0],
      contraBroker |-> [i \in 1 .. 3 |-> 0] ]

(* Order Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedMessage ==
    { ZeroOrderExecutedMessage }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.broker = one] : one \in Sample(3) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.contraBroker = one] : one \in Sample(3) }

(***************************************************************************)
(* Trade Message: 60 bytes                                                 *)
(***************************************************************************)

TradeMessage ==
    [ symbolId     : Sample(2),
      timestamp    : Sample(8),
      reserved8    : Sample(8),
      side         : Sample(1),
      shares       : Sample(8),
      symbol       : Sample(11),
      price        : Sample(8),
      executionId  : Sample(8),
      broker       : Sample(3),
      contraBroker : Sample(3) ]

EncodeTradeMessage(message) ==
    message.symbolId
        \o message.timestamp
        \o message.reserved8
        \o message.side
        \o message.shares
        \o message.symbol
        \o message.price
        \o message.executionId
        \o message.broker
        \o message.contraBroker

DecodeTradeMessage(bytes) ==
    LET symbolId == ReadBytes(bytes, 2) IN IF ~symbolId.ok THEN Fail ELSE
    LET timestamp == ReadBytes(symbolId.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(timestamp.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    LET side == ReadBytes(reserved8.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET shares == ReadBytes(side.rest, 8) IN IF ~shares.ok THEN Fail ELSE
    LET symbol == ReadBytes(shares.rest, 11) IN IF ~symbol.ok THEN Fail ELSE
    LET price == ReadBytes(symbol.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET executionId == ReadBytes(price.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET broker == ReadBytes(executionId.rest, 3) IN IF ~broker.ok THEN Fail ELSE
    LET contraBroker == ReadBytes(broker.rest, 3) IN IF ~contraBroker.ok THEN Fail ELSE
    Ok([ symbolId     |-> symbolId.value,
         timestamp    |-> timestamp.value,
         reserved8    |-> reserved8.value,
         side         |-> side.value,
         shares       |-> shares.value,
         symbol       |-> symbol.value,
         price        |-> price.value,
         executionId  |-> executionId.value,
         broker       |-> broker.value,
         contraBroker |-> contraBroker.value ], contraBroker.rest)

ZeroTradeMessage ==
    [ symbolId     |-> [i \in 1 .. 2 |-> 0],
      timestamp    |-> [i \in 1 .. 8 |-> 0],
      reserved8    |-> [i \in 1 .. 8 |-> 0],
      side         |-> [i \in 1 .. 1 |-> 0],
      shares       |-> [i \in 1 .. 8 |-> 0],
      symbol       |-> [i \in 1 .. 11 |-> 0],
      price        |-> [i \in 1 .. 8 |-> 0],
      executionId  |-> [i \in 1 .. 8 |-> 0],
      broker       |-> [i \in 1 .. 3 |-> 0],
      contraBroker |-> [i \in 1 .. 3 |-> 0] ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.symbolId = one] : one \in Sample(2) }
        \cup { [ZeroTradeMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.shares = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.symbol = one] : one \in Sample(11) }
        \cup { [ZeroTradeMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.broker = one] : one \in Sample(3) }
        \cup { [ZeroTradeMessage EXCEPT !.contraBroker = one] : one \in Sample(3) }

(***************************************************************************)
(* Trade Cancel Message: 60 bytes                                          *)
(***************************************************************************)

TradeCancelMessage ==
    [ symbolId     : Sample(2),
      timestamp    : Sample(8),
      reserved8    : Sample(8),
      reserved1    : Sample(1),
      shares       : Sample(8),
      symbol       : Sample(11),
      price        : Sample(8),
      executionId  : Sample(8),
      broker       : Sample(3),
      contraBroker : Sample(3) ]

EncodeTradeCancelMessage(message) ==
    message.symbolId
        \o message.timestamp
        \o message.reserved8
        \o message.reserved1
        \o message.shares
        \o message.symbol
        \o message.price
        \o message.executionId
        \o message.broker
        \o message.contraBroker

DecodeTradeCancelMessage(bytes) ==
    LET symbolId == ReadBytes(bytes, 2) IN IF ~symbolId.ok THEN Fail ELSE
    LET timestamp == ReadBytes(symbolId.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(timestamp.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(reserved8.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET shares == ReadBytes(reserved1.rest, 8) IN IF ~shares.ok THEN Fail ELSE
    LET symbol == ReadBytes(shares.rest, 11) IN IF ~symbol.ok THEN Fail ELSE
    LET price == ReadBytes(symbol.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET executionId == ReadBytes(price.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET broker == ReadBytes(executionId.rest, 3) IN IF ~broker.ok THEN Fail ELSE
    LET contraBroker == ReadBytes(broker.rest, 3) IN IF ~contraBroker.ok THEN Fail ELSE
    Ok([ symbolId     |-> symbolId.value,
         timestamp    |-> timestamp.value,
         reserved8    |-> reserved8.value,
         reserved1    |-> reserved1.value,
         shares       |-> shares.value,
         symbol       |-> symbol.value,
         price        |-> price.value,
         executionId  |-> executionId.value,
         broker       |-> broker.value,
         contraBroker |-> contraBroker.value ], contraBroker.rest)

ZeroTradeCancelMessage ==
    [ symbolId     |-> [i \in 1 .. 2 |-> 0],
      timestamp    |-> [i \in 1 .. 8 |-> 0],
      reserved8    |-> [i \in 1 .. 8 |-> 0],
      reserved1    |-> [i \in 1 .. 1 |-> 0],
      shares       |-> [i \in 1 .. 8 |-> 0],
      symbol       |-> [i \in 1 .. 11 |-> 0],
      price        |-> [i \in 1 .. 8 |-> 0],
      executionId  |-> [i \in 1 .. 8 |-> 0],
      broker       |-> [i \in 1 .. 3 |-> 0],
      contraBroker |-> [i \in 1 .. 3 |-> 0] ]

(* Trade Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCancelMessage ==
    { ZeroTradeCancelMessage }
        \cup { [ZeroTradeCancelMessage EXCEPT !.symbolId = one] : one \in Sample(2) }
        \cup { [ZeroTradeCancelMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelMessage EXCEPT !.shares = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelMessage EXCEPT !.symbol = one] : one \in Sample(11) }
        \cup { [ZeroTradeCancelMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelMessage EXCEPT !.broker = one] : one \in Sample(3) }
        \cup { [ZeroTradeCancelMessage EXCEPT !.contraBroker = one] : one \in Sample(3) }

(***************************************************************************)
(* Trade Correct Message: 84 bytes                                         *)
(***************************************************************************)

TradeCorrectMessage ==
    [ symbolId               : Sample(2),
      timestamp              : Sample(8),
      reserved8              : Sample(8),
      reserved1              : Sample(1),
      symbol                 : Sample(11),
      executionId            : Sample(8),
      broker                 : Sample(3),
      contraBroker           : Sample(3),
      originalExecutionId    : Sample(8),
      originalTradePrice     : Sample(8),
      originalTradeQuantity  : Sample(8),
      correctedTradePrice    : Sample(8),
      correctedTradeQuantity : Sample(8) ]

EncodeTradeCorrectMessage(message) ==
    message.symbolId
        \o message.timestamp
        \o message.reserved8
        \o message.reserved1
        \o message.symbol
        \o message.executionId
        \o message.broker
        \o message.contraBroker
        \o message.originalExecutionId
        \o message.originalTradePrice
        \o message.originalTradeQuantity
        \o message.correctedTradePrice
        \o message.correctedTradeQuantity

DecodeTradeCorrectMessage(bytes) ==
    LET symbolId == ReadBytes(bytes, 2) IN IF ~symbolId.ok THEN Fail ELSE
    LET timestamp == ReadBytes(symbolId.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(timestamp.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(reserved8.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET symbol == ReadBytes(reserved1.rest, 11) IN IF ~symbol.ok THEN Fail ELSE
    LET executionId == ReadBytes(symbol.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET broker == ReadBytes(executionId.rest, 3) IN IF ~broker.ok THEN Fail ELSE
    LET contraBroker == ReadBytes(broker.rest, 3) IN IF ~contraBroker.ok THEN Fail ELSE
    LET originalExecutionId == ReadBytes(contraBroker.rest, 8) IN IF ~originalExecutionId.ok THEN Fail ELSE
    LET originalTradePrice == ReadBytes(originalExecutionId.rest, 8) IN IF ~originalTradePrice.ok THEN Fail ELSE
    LET originalTradeQuantity == ReadBytes(originalTradePrice.rest, 8) IN IF ~originalTradeQuantity.ok THEN Fail ELSE
    LET correctedTradePrice == ReadBytes(originalTradeQuantity.rest, 8) IN IF ~correctedTradePrice.ok THEN Fail ELSE
    LET correctedTradeQuantity == ReadBytes(correctedTradePrice.rest, 8) IN IF ~correctedTradeQuantity.ok THEN Fail ELSE
    Ok([ symbolId               |-> symbolId.value,
         timestamp              |-> timestamp.value,
         reserved8              |-> reserved8.value,
         reserved1              |-> reserved1.value,
         symbol                 |-> symbol.value,
         executionId            |-> executionId.value,
         broker                 |-> broker.value,
         contraBroker           |-> contraBroker.value,
         originalExecutionId    |-> originalExecutionId.value,
         originalTradePrice     |-> originalTradePrice.value,
         originalTradeQuantity  |-> originalTradeQuantity.value,
         correctedTradePrice    |-> correctedTradePrice.value,
         correctedTradeQuantity |-> correctedTradeQuantity.value ], correctedTradeQuantity.rest)

ZeroTradeCorrectMessage ==
    [ symbolId               |-> [i \in 1 .. 2 |-> 0],
      timestamp              |-> [i \in 1 .. 8 |-> 0],
      reserved8              |-> [i \in 1 .. 8 |-> 0],
      reserved1              |-> [i \in 1 .. 1 |-> 0],
      symbol                 |-> [i \in 1 .. 11 |-> 0],
      executionId            |-> [i \in 1 .. 8 |-> 0],
      broker                 |-> [i \in 1 .. 3 |-> 0],
      contraBroker           |-> [i \in 1 .. 3 |-> 0],
      originalExecutionId    |-> [i \in 1 .. 8 |-> 0],
      originalTradePrice     |-> [i \in 1 .. 8 |-> 0],
      originalTradeQuantity  |-> [i \in 1 .. 8 |-> 0],
      correctedTradePrice    |-> [i \in 1 .. 8 |-> 0],
      correctedTradeQuantity |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Correct Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCorrectMessage ==
    { ZeroTradeCorrectMessage }
        \cup { [ZeroTradeCorrectMessage EXCEPT !.symbolId = one] : one \in Sample(2) }
        \cup { [ZeroTradeCorrectMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectMessage EXCEPT !.symbol = one] : one \in Sample(11) }
        \cup { [ZeroTradeCorrectMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectMessage EXCEPT !.broker = one] : one \in Sample(3) }
        \cup { [ZeroTradeCorrectMessage EXCEPT !.contraBroker = one] : one \in Sample(3) }
        \cup { [ZeroTradeCorrectMessage EXCEPT !.originalExecutionId = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectMessage EXCEPT !.originalTradePrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectMessage EXCEPT !.originalTradeQuantity = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectMessage EXCEPT !.correctedTradePrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectMessage EXCEPT !.correctedTradeQuantity = one] : one \in Sample(8) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

MarketEventMessageCode == 65  \* "A"
SymbolInformationMessageCode == 66  \* "B"
SymbolStateMessageCode == 67  \* "C"
NewOrderAddMessageCode == 68  \* "D"
OrderPartialCancelMessageCode == 70  \* "F"
OrderCancelAllMessageCode == 71  \* "G"
OrderExecutedMessageCode == 74  \* "J"
TradeMessageCode == 75  \* "K"
TradeCancelMessageCode == 76  \* "L"
TradeCorrectMessageCode == 77  \* "M"

Payload ==
    [ tag : {MarketEventMessageCode}, body : MarketEventMessage ]
        \cup [ tag : {SymbolInformationMessageCode}, body : SymbolInformationMessage ]
        \cup [ tag : {SymbolStateMessageCode}, body : SymbolStateMessage ]
        \cup [ tag : {NewOrderAddMessageCode}, body : NewOrderAddMessage ]
        \cup [ tag : {OrderPartialCancelMessageCode}, body : OrderPartialCancelMessage ]
        \cup [ tag : {OrderCancelAllMessageCode}, body : OrderCancelAllMessage ]
        \cup [ tag : {OrderExecutedMessageCode}, body : OrderExecutedMessage ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {TradeCancelMessageCode}, body : TradeCancelMessage ]
        \cup [ tag : {TradeCorrectMessageCode}, body : TradeCorrectMessage ]

EncodePayload(message) ==
    CASE message.tag = MarketEventMessageCode -> EncodeMarketEventMessage(message.body)
      [] message.tag = SymbolInformationMessageCode -> EncodeSymbolInformationMessage(message.body)
      [] message.tag = SymbolStateMessageCode -> EncodeSymbolStateMessage(message.body)
      [] message.tag = NewOrderAddMessageCode -> EncodeNewOrderAddMessage(message.body)
      [] message.tag = OrderPartialCancelMessageCode -> EncodeOrderPartialCancelMessage(message.body)
      [] message.tag = OrderCancelAllMessageCode -> EncodeOrderCancelAllMessage(message.body)
      [] message.tag = OrderExecutedMessageCode -> EncodeOrderExecutedMessage(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = TradeCancelMessageCode -> EncodeTradeCancelMessage(message.body)
      [] message.tag = TradeCorrectMessageCode -> EncodeTradeCorrectMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = MarketEventMessageCode -> DecodeMarketEventMessage(bytes)
              [] tag = SymbolInformationMessageCode -> DecodeSymbolInformationMessage(bytes)
              [] tag = SymbolStateMessageCode -> DecodeSymbolStateMessage(bytes)
              [] tag = NewOrderAddMessageCode -> DecodeNewOrderAddMessage(bytes)
              [] tag = OrderPartialCancelMessageCode -> DecodeOrderPartialCancelMessage(bytes)
              [] tag = OrderCancelAllMessageCode -> DecodeOrderCancelAllMessage(bytes)
              [] tag = OrderExecutedMessageCode -> DecodeOrderExecutedMessage(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = TradeCancelMessageCode -> DecodeTradeCancelMessage(bytes)
              [] tag = TradeCorrectMessageCode -> DecodeTradeCorrectMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> MarketEventMessageCode, body |-> ZeroMarketEventMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> MarketEventMessageCode, body |-> one] : one \in CheckedMarketEventMessage }
        \cup { [tag |-> SymbolInformationMessageCode, body |-> one] : one \in CheckedSymbolInformationMessage }
        \cup { [tag |-> SymbolStateMessageCode, body |-> one] : one \in CheckedSymbolStateMessage }
        \cup { [tag |-> NewOrderAddMessageCode, body |-> one] : one \in CheckedNewOrderAddMessage }
        \cup { [tag |-> OrderPartialCancelMessageCode, body |-> one] : one \in CheckedOrderPartialCancelMessage }
        \cup { [tag |-> OrderCancelAllMessageCode, body |-> one] : one \in CheckedOrderCancelAllMessage }
        \cup { [tag |-> OrderExecutedMessageCode, body |-> one] : one \in CheckedOrderExecutedMessage }
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> TradeCancelMessageCode, body |-> one] : one \in CheckedTradeCancelMessage }
        \cup { [tag |-> TradeCorrectMessageCode, body |-> one] : one \in CheckedTradeCorrectMessage }

(***************************************************************************)
(* Message, framed by Length                                               *)
(***************************************************************************)

Message ==
    [ payload : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntBE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

(* Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntLE(Len(body), 2) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroMessage ==
    [ payload |-> ZeroPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> MarketEventMessageCode, body |-> ZeroMarketEventMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SymbolInformationMessageCode, body |-> ZeroSymbolInformationMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SymbolStateMessageCode, body |-> ZeroSymbolStateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> NewOrderAddMessageCode, body |-> ZeroNewOrderAddMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderPartialCancelMessageCode, body |-> ZeroOrderPartialCancelMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderCancelAllMessageCode, body |-> ZeroOrderCancelAllMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderExecutedMessageCode, body |-> ZeroOrderExecutedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeMessageCode, body |-> ZeroTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeCancelMessageCode, body |-> ZeroTradeCancelMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeCorrectMessageCode, body |-> ZeroTradeCorrectMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ marketDayIdentifier : Sample(9),
      feedIdentifier      : Sample(1),
      sequence            : Sample(8),
      message             : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.marketDayIdentifier
        \o message.feedIdentifier
        \o message.sequence
        \o EncodeUIntLE(Len(message.message), 2)
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET marketDayIdentifier == ReadBytes(bytes, 9) IN IF ~marketDayIdentifier.ok THEN Fail ELSE
    LET feedIdentifier == ReadBytes(marketDayIdentifier.rest, 1) IN IF ~feedIdentifier.ok THEN Fail ELSE
    LET sequence == ReadBytes(feedIdentifier.rest, 8) IN IF ~sequence.ok THEN Fail ELSE
    LET count == ReadUIntLE(sequence.rest, 2) IN IF ~count.ok THEN Fail ELSE
    LET message == ReadMessageList(count.rest, count.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ marketDayIdentifier |-> marketDayIdentifier.value,
         feedIdentifier      |-> feedIdentifier.value,
         sequence            |-> sequence.value,
         message             |-> message.value ], message.rest)

ZeroPacket ==
    [ marketDayIdentifier |-> [i \in 1 .. 9 |-> 0],
      feedIdentifier      |-> [i \in 1 .. 1 |-> 0],
      sequence            |-> [i \in 1 .. 8 |-> 0],
      message             |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.marketDayIdentifier = one] : one \in Sample(9) }
        \cup { [ZeroPacket EXCEPT !.feedIdentifier = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.sequence = one] : one \in Sample(8) }
        \cup { [ZeroPacket EXCEPT !.message = one] : one \in SampleLists(OneMessage) }

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

(* Every Market Event Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketEventMessage ==
    \A message \in CheckedMarketEventMessage :
        LET read == DecodeMarketEventMessage(EncodeMarketEventMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol Information Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolInformationMessage ==
    \A message \in CheckedSymbolInformationMessage :
        LET read == DecodeSymbolInformationMessage(EncodeSymbolInformationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol State Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolStateMessage ==
    \A message \in CheckedSymbolStateMessage :
        LET read == DecodeSymbolStateMessage(EncodeSymbolStateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Add Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderAddMessage ==
    \A message \in CheckedNewOrderAddMessage :
        LET read == DecodeNewOrderAddMessage(EncodeNewOrderAddMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Partial Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderPartialCancelMessage ==
    \A message \in CheckedOrderPartialCancelMessage :
        LET read == DecodeOrderPartialCancelMessage(EncodeOrderPartialCancelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancel All Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelAllMessage ==
    \A message \in CheckedOrderCancelAllMessage :
        LET read == DecodeOrderCancelAllMessage(EncodeOrderCancelAllMessage(message))
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

(* Every Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeMessage ==
    \A message \in CheckedTradeMessage :
        LET read == DecodeTradeMessage(EncodeTradeMessage(message))
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

(* Every Trade Correct Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCorrectMessage ==
    \A message \in CheckedTradeCorrectMessage :
        LET read == DecodeTradeCorrectMessage(EncodeTradeCorrectMessage(message))
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

(* Length is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
