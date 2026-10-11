------------- MODULE ByxEquities_MulticastDepthOfBook_v2_41_29 -------------
(***************************************************************************)
(* Chicago Board Options Exchange Multicast Depth Of Book v2.41.29         *)
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
(* Note: a Message Count of 0 marks Heartbeat and carries no Message.      *)
(*                                                                         *)
(* Note: Add Order Flags is a bit field set, checked as its 1 byte rather  *)
(* than bit by bit.                                                        *)
(*                                                                         *)
(* Note: Modify Order Flags is a bit field set, checked as its 1 byte      *)
(* rather than bit by bit.                                                 *)
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
(* Time Message: 4 bytes                                                   *)
(***************************************************************************)

TimeMessage ==
    [ time : Sample(4) ]

EncodeTimeMessage(message) ==
    message.time

DecodeTimeMessage(bytes) ==
    LET time == ReadBytes(bytes, 4) IN IF ~time.ok THEN Fail ELSE
    Ok([ time |-> time.value ], time.rest)

ZeroTimeMessage ==
    [ time |-> [i \in 1 .. 4 |-> 0] ]

(* Time Message at zero, then each field in turn at the values it is checked at *)
CheckedTimeMessage ==
    { ZeroTimeMessage }
        \cup { [ZeroTimeMessage EXCEPT !.time = one] : one \in Sample(4) }

(***************************************************************************)
(* Unit Clear Message: 4 bytes                                             *)
(***************************************************************************)

UnitClearMessage ==
    [ timeOffset : Sample(4) ]

EncodeUnitClearMessage(message) ==
    message.timeOffset

DecodeUnitClearMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    Ok([ timeOffset |-> timeOffset.value ], timeOffset.rest)

ZeroUnitClearMessage ==
    [ timeOffset |-> [i \in 1 .. 4 |-> 0] ]

(* Unit Clear Message at zero, then each field in turn at the values it is checked at *)
CheckedUnitClearMessage ==
    { ZeroUnitClearMessage }
        \cup { [ZeroUnitClearMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }

(***************************************************************************)
(* Add Order Long Message: 32 bytes                                        *)
(***************************************************************************)

AddOrderLongMessage ==
    [ timeOffset    : Sample(4),
      orderId       : Sample(8),
      sideIndicator : Sample(1),
      quantity      : Sample(4),
      symbolShort   : Sample(6),
      price         : Sample(8),
      addOrderFlags : Sample(1) ]

EncodeAddOrderLongMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.quantity
        \o message.symbolShort
        \o message.price
        \o message.addOrderFlags

DecodeAddOrderLongMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET quantity == ReadBytes(sideIndicator.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET symbolShort == ReadBytes(quantity.rest, 6) IN IF ~symbolShort.ok THEN Fail ELSE
    LET price == ReadBytes(symbolShort.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET addOrderFlags == ReadBytes(price.rest, 1) IN IF ~addOrderFlags.ok THEN Fail ELSE
    Ok([ timeOffset    |-> timeOffset.value,
         orderId       |-> orderId.value,
         sideIndicator |-> sideIndicator.value,
         quantity      |-> quantity.value,
         symbolShort   |-> symbolShort.value,
         price         |-> price.value,
         addOrderFlags |-> addOrderFlags.value ], addOrderFlags.rest)

ZeroAddOrderLongMessage ==
    [ timeOffset    |-> [i \in 1 .. 4 |-> 0],
      orderId       |-> [i \in 1 .. 8 |-> 0],
      sideIndicator |-> [i \in 1 .. 1 |-> 0],
      quantity      |-> [i \in 1 .. 4 |-> 0],
      symbolShort   |-> [i \in 1 .. 6 |-> 0],
      price         |-> [i \in 1 .. 8 |-> 0],
      addOrderFlags |-> [i \in 1 .. 1 |-> 0] ]

(* Add Order Long Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderLongMessage ==
    { ZeroAddOrderLongMessage }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.symbolShort = one] : one \in Sample(6) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.addOrderFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Add Order Short Message: 24 bytes                                       *)
(***************************************************************************)

AddOrderShortMessage ==
    [ timeOffset    : Sample(4),
      orderId       : Sample(8),
      sideIndicator : Sample(1),
      quantityShort : Sample(2),
      symbolShort   : Sample(6),
      priceShort    : Sample(2),
      addOrderFlags : Sample(1) ]

EncodeAddOrderShortMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.quantityShort
        \o message.symbolShort
        \o message.priceShort
        \o message.addOrderFlags

DecodeAddOrderShortMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET quantityShort == ReadBytes(sideIndicator.rest, 2) IN IF ~quantityShort.ok THEN Fail ELSE
    LET symbolShort == ReadBytes(quantityShort.rest, 6) IN IF ~symbolShort.ok THEN Fail ELSE
    LET priceShort == ReadBytes(symbolShort.rest, 2) IN IF ~priceShort.ok THEN Fail ELSE
    LET addOrderFlags == ReadBytes(priceShort.rest, 1) IN IF ~addOrderFlags.ok THEN Fail ELSE
    Ok([ timeOffset    |-> timeOffset.value,
         orderId       |-> orderId.value,
         sideIndicator |-> sideIndicator.value,
         quantityShort |-> quantityShort.value,
         symbolShort   |-> symbolShort.value,
         priceShort    |-> priceShort.value,
         addOrderFlags |-> addOrderFlags.value ], addOrderFlags.rest)

ZeroAddOrderShortMessage ==
    [ timeOffset    |-> [i \in 1 .. 4 |-> 0],
      orderId       |-> [i \in 1 .. 8 |-> 0],
      sideIndicator |-> [i \in 1 .. 1 |-> 0],
      quantityShort |-> [i \in 1 .. 2 |-> 0],
      symbolShort   |-> [i \in 1 .. 6 |-> 0],
      priceShort    |-> [i \in 1 .. 2 |-> 0],
      addOrderFlags |-> [i \in 1 .. 1 |-> 0] ]

(* Add Order Short Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderShortMessage ==
    { ZeroAddOrderShortMessage }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.quantityShort = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.symbolShort = one] : one \in Sample(6) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.priceShort = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.addOrderFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Add Order Expanded Message: 39 bytes                                    *)
(***************************************************************************)

AddOrderExpandedMessage ==
    [ timeOffset        : Sample(4),
      orderId           : Sample(8),
      sideIndicator     : Sample(1),
      quantity          : Sample(4),
      symbolLong        : Sample(8),
      price             : Sample(8),
      addOrderFlags     : Sample(1),
      participantId     : Sample(4),
      customerIndicator : Sample(1) ]

EncodeAddOrderExpandedMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.quantity
        \o message.symbolLong
        \o message.price
        \o message.addOrderFlags
        \o message.participantId
        \o message.customerIndicator

DecodeAddOrderExpandedMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET quantity == ReadBytes(sideIndicator.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(quantity.rest, 8) IN IF ~symbolLong.ok THEN Fail ELSE
    LET price == ReadBytes(symbolLong.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET addOrderFlags == ReadBytes(price.rest, 1) IN IF ~addOrderFlags.ok THEN Fail ELSE
    LET participantId == ReadBytes(addOrderFlags.rest, 4) IN IF ~participantId.ok THEN Fail ELSE
    LET customerIndicator == ReadBytes(participantId.rest, 1) IN IF ~customerIndicator.ok THEN Fail ELSE
    Ok([ timeOffset        |-> timeOffset.value,
         orderId           |-> orderId.value,
         sideIndicator     |-> sideIndicator.value,
         quantity          |-> quantity.value,
         symbolLong        |-> symbolLong.value,
         price             |-> price.value,
         addOrderFlags     |-> addOrderFlags.value,
         participantId     |-> participantId.value,
         customerIndicator |-> customerIndicator.value ], customerIndicator.rest)

ZeroAddOrderExpandedMessage ==
    [ timeOffset        |-> [i \in 1 .. 4 |-> 0],
      orderId           |-> [i \in 1 .. 8 |-> 0],
      sideIndicator     |-> [i \in 1 .. 1 |-> 0],
      quantity          |-> [i \in 1 .. 4 |-> 0],
      symbolLong        |-> [i \in 1 .. 8 |-> 0],
      price             |-> [i \in 1 .. 8 |-> 0],
      addOrderFlags     |-> [i \in 1 .. 1 |-> 0],
      participantId     |-> [i \in 1 .. 4 |-> 0],
      customerIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Add Order Expanded Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderExpandedMessage ==
    { ZeroAddOrderExpandedMessage }
        \cup { [ZeroAddOrderExpandedMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderExpandedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderExpandedMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderExpandedMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderExpandedMessage EXCEPT !.symbolLong = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderExpandedMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderExpandedMessage EXCEPT !.addOrderFlags = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderExpandedMessage EXCEPT !.participantId = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderExpandedMessage EXCEPT !.customerIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Executed Message: 24 bytes                                        *)
(***************************************************************************)

OrderExecutedMessage ==
    [ timeOffset       : Sample(4),
      orderId          : Sample(8),
      executedQuantity : Sample(4),
      executionId      : Sample(8) ]

EncodeOrderExecutedMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.executedQuantity
        \o message.executionId

DecodeOrderExecutedMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(orderId.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET executionId == ReadBytes(executedQuantity.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    Ok([ timeOffset       |-> timeOffset.value,
         orderId          |-> orderId.value,
         executedQuantity |-> executedQuantity.value,
         executionId      |-> executionId.value ], executionId.rest)

ZeroOrderExecutedMessage ==
    [ timeOffset       |-> [i \in 1 .. 4 |-> 0],
      orderId          |-> [i \in 1 .. 8 |-> 0],
      executedQuantity |-> [i \in 1 .. 4 |-> 0],
      executionId      |-> [i \in 1 .. 8 |-> 0] ]

(* Order Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedMessage ==
    { ZeroOrderExecutedMessage }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.executionId = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Executed At Price Size Message: 36 bytes                          *)
(***************************************************************************)

OrderExecutedAtPriceSizeMessage ==
    [ timeOffset        : Sample(4),
      orderId           : Sample(8),
      executedQuantity  : Sample(4),
      remainingQuantity : Sample(4),
      executionId       : Sample(8),
      price             : Sample(8) ]

EncodeOrderExecutedAtPriceSizeMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.executedQuantity
        \o message.remainingQuantity
        \o message.executionId
        \o message.price

DecodeOrderExecutedAtPriceSizeMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(orderId.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET remainingQuantity == ReadBytes(executedQuantity.rest, 4) IN IF ~remainingQuantity.ok THEN Fail ELSE
    LET executionId == ReadBytes(remainingQuantity.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET price == ReadBytes(executionId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    Ok([ timeOffset        |-> timeOffset.value,
         orderId           |-> orderId.value,
         executedQuantity  |-> executedQuantity.value,
         remainingQuantity |-> remainingQuantity.value,
         executionId       |-> executionId.value,
         price             |-> price.value ], price.rest)

ZeroOrderExecutedAtPriceSizeMessage ==
    [ timeOffset        |-> [i \in 1 .. 4 |-> 0],
      orderId           |-> [i \in 1 .. 8 |-> 0],
      executedQuantity  |-> [i \in 1 .. 4 |-> 0],
      remainingQuantity |-> [i \in 1 .. 4 |-> 0],
      executionId       |-> [i \in 1 .. 8 |-> 0],
      price             |-> [i \in 1 .. 8 |-> 0] ]

(* Order Executed At Price Size Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedAtPriceSizeMessage ==
    { ZeroOrderExecutedAtPriceSizeMessage }
        \cup { [ZeroOrderExecutedAtPriceSizeMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedAtPriceSizeMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedAtPriceSizeMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedAtPriceSizeMessage EXCEPT !.remainingQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedAtPriceSizeMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedAtPriceSizeMessage EXCEPT !.price = one] : one \in Sample(8) }

(***************************************************************************)
(* Reduce Size Long Message: 16 bytes                                      *)
(***************************************************************************)

ReduceSizeLongMessage ==
    [ timeOffset       : Sample(4),
      orderId          : Sample(8),
      canceledQuantity : Sample(4) ]

EncodeReduceSizeLongMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.canceledQuantity

DecodeReduceSizeLongMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET canceledQuantity == ReadBytes(orderId.rest, 4) IN IF ~canceledQuantity.ok THEN Fail ELSE
    Ok([ timeOffset       |-> timeOffset.value,
         orderId          |-> orderId.value,
         canceledQuantity |-> canceledQuantity.value ], canceledQuantity.rest)

ZeroReduceSizeLongMessage ==
    [ timeOffset       |-> [i \in 1 .. 4 |-> 0],
      orderId          |-> [i \in 1 .. 8 |-> 0],
      canceledQuantity |-> [i \in 1 .. 4 |-> 0] ]

(* Reduce Size Long Message at zero, then each field in turn at the values it is checked at *)
CheckedReduceSizeLongMessage ==
    { ZeroReduceSizeLongMessage }
        \cup { [ZeroReduceSizeLongMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroReduceSizeLongMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroReduceSizeLongMessage EXCEPT !.canceledQuantity = one] : one \in Sample(4) }

(***************************************************************************)
(* Reduce Size Short Message: 14 bytes                                     *)
(***************************************************************************)

ReduceSizeShortMessage ==
    [ timeOffset            : Sample(4),
      orderId               : Sample(8),
      canceledQuantityShort : Sample(2) ]

EncodeReduceSizeShortMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.canceledQuantityShort

DecodeReduceSizeShortMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET canceledQuantityShort == ReadBytes(orderId.rest, 2) IN IF ~canceledQuantityShort.ok THEN Fail ELSE
    Ok([ timeOffset            |-> timeOffset.value,
         orderId               |-> orderId.value,
         canceledQuantityShort |-> canceledQuantityShort.value ], canceledQuantityShort.rest)

ZeroReduceSizeShortMessage ==
    [ timeOffset            |-> [i \in 1 .. 4 |-> 0],
      orderId               |-> [i \in 1 .. 8 |-> 0],
      canceledQuantityShort |-> [i \in 1 .. 2 |-> 0] ]

(* Reduce Size Short Message at zero, then each field in turn at the values it is checked at *)
CheckedReduceSizeShortMessage ==
    { ZeroReduceSizeShortMessage }
        \cup { [ZeroReduceSizeShortMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroReduceSizeShortMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroReduceSizeShortMessage EXCEPT !.canceledQuantityShort = one] : one \in Sample(2) }

(***************************************************************************)
(* Modify Order Long Message: 25 bytes                                     *)
(***************************************************************************)

ModifyOrderLongMessage ==
    [ timeOffset       : Sample(4),
      orderId          : Sample(8),
      quantity         : Sample(4),
      price            : Sample(8),
      modifyOrderFlags : Sample(1) ]

EncodeModifyOrderLongMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.quantity
        \o message.price
        \o message.modifyOrderFlags

DecodeModifyOrderLongMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET quantity == ReadBytes(orderId.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET modifyOrderFlags == ReadBytes(price.rest, 1) IN IF ~modifyOrderFlags.ok THEN Fail ELSE
    Ok([ timeOffset       |-> timeOffset.value,
         orderId          |-> orderId.value,
         quantity         |-> quantity.value,
         price            |-> price.value,
         modifyOrderFlags |-> modifyOrderFlags.value ], modifyOrderFlags.rest)

ZeroModifyOrderLongMessage ==
    [ timeOffset       |-> [i \in 1 .. 4 |-> 0],
      orderId          |-> [i \in 1 .. 8 |-> 0],
      quantity         |-> [i \in 1 .. 4 |-> 0],
      price            |-> [i \in 1 .. 8 |-> 0],
      modifyOrderFlags |-> [i \in 1 .. 1 |-> 0] ]

(* Modify Order Long Message at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderLongMessage ==
    { ZeroModifyOrderLongMessage }
        \cup { [ZeroModifyOrderLongMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderLongMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderLongMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderLongMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderLongMessage EXCEPT !.modifyOrderFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Modify Order Short Message: 17 bytes                                    *)
(***************************************************************************)

ModifyOrderShortMessage ==
    [ timeOffset       : Sample(4),
      orderId          : Sample(8),
      quantityShort    : Sample(2),
      priceShort       : Sample(2),
      modifyOrderFlags : Sample(1) ]

EncodeModifyOrderShortMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.quantityShort
        \o message.priceShort
        \o message.modifyOrderFlags

DecodeModifyOrderShortMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET quantityShort == ReadBytes(orderId.rest, 2) IN IF ~quantityShort.ok THEN Fail ELSE
    LET priceShort == ReadBytes(quantityShort.rest, 2) IN IF ~priceShort.ok THEN Fail ELSE
    LET modifyOrderFlags == ReadBytes(priceShort.rest, 1) IN IF ~modifyOrderFlags.ok THEN Fail ELSE
    Ok([ timeOffset       |-> timeOffset.value,
         orderId          |-> orderId.value,
         quantityShort    |-> quantityShort.value,
         priceShort       |-> priceShort.value,
         modifyOrderFlags |-> modifyOrderFlags.value ], modifyOrderFlags.rest)

ZeroModifyOrderShortMessage ==
    [ timeOffset       |-> [i \in 1 .. 4 |-> 0],
      orderId          |-> [i \in 1 .. 8 |-> 0],
      quantityShort    |-> [i \in 1 .. 2 |-> 0],
      priceShort       |-> [i \in 1 .. 2 |-> 0],
      modifyOrderFlags |-> [i \in 1 .. 1 |-> 0] ]

(* Modify Order Short Message at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderShortMessage ==
    { ZeroModifyOrderShortMessage }
        \cup { [ZeroModifyOrderShortMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderShortMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderShortMessage EXCEPT !.quantityShort = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderShortMessage EXCEPT !.priceShort = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderShortMessage EXCEPT !.modifyOrderFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Delete Order Message: 12 bytes                                          *)
(***************************************************************************)

DeleteOrderMessage ==
    [ timeOffset : Sample(4),
      orderId    : Sample(8) ]

EncodeDeleteOrderMessage(message) ==
    message.timeOffset
        \o message.orderId

DecodeDeleteOrderMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    Ok([ timeOffset |-> timeOffset.value,
         orderId    |-> orderId.value ], orderId.rest)

ZeroDeleteOrderMessage ==
    [ timeOffset |-> [i \in 1 .. 4 |-> 0],
      orderId    |-> [i \in 1 .. 8 |-> 0] ]

(* Delete Order Message at zero, then each field in turn at the values it is checked at *)
CheckedDeleteOrderMessage ==
    { ZeroDeleteOrderMessage }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Long Message: 39 bytes                                            *)
(***************************************************************************)

TradeLongMessage ==
    [ timeOffset    : Sample(4),
      orderId       : Sample(8),
      sideIndicator : Sample(1),
      quantity      : Sample(4),
      symbolShort   : Sample(6),
      price         : Sample(8),
      executionId   : Sample(8) ]

EncodeTradeLongMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.quantity
        \o message.symbolShort
        \o message.price
        \o message.executionId

DecodeTradeLongMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET quantity == ReadBytes(sideIndicator.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET symbolShort == ReadBytes(quantity.rest, 6) IN IF ~symbolShort.ok THEN Fail ELSE
    LET price == ReadBytes(symbolShort.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET executionId == ReadBytes(price.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    Ok([ timeOffset    |-> timeOffset.value,
         orderId       |-> orderId.value,
         sideIndicator |-> sideIndicator.value,
         quantity      |-> quantity.value,
         symbolShort   |-> symbolShort.value,
         price         |-> price.value,
         executionId   |-> executionId.value ], executionId.rest)

ZeroTradeLongMessage ==
    [ timeOffset    |-> [i \in 1 .. 4 |-> 0],
      orderId       |-> [i \in 1 .. 8 |-> 0],
      sideIndicator |-> [i \in 1 .. 1 |-> 0],
      quantity      |-> [i \in 1 .. 4 |-> 0],
      symbolShort   |-> [i \in 1 .. 6 |-> 0],
      price         |-> [i \in 1 .. 8 |-> 0],
      executionId   |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Long Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeLongMessage ==
    { ZeroTradeLongMessage }
        \cup { [ZeroTradeLongMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroTradeLongMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroTradeLongMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeLongMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroTradeLongMessage EXCEPT !.symbolShort = one] : one \in Sample(6) }
        \cup { [ZeroTradeLongMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeLongMessage EXCEPT !.executionId = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Short Message: 31 bytes                                           *)
(***************************************************************************)

TradeShortMessage ==
    [ timeOffset    : Sample(4),
      orderId       : Sample(8),
      sideIndicator : Sample(1),
      quantityShort : Sample(2),
      symbolShort   : Sample(6),
      priceShort    : Sample(2),
      executionId   : Sample(8) ]

EncodeTradeShortMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.quantityShort
        \o message.symbolShort
        \o message.priceShort
        \o message.executionId

DecodeTradeShortMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET quantityShort == ReadBytes(sideIndicator.rest, 2) IN IF ~quantityShort.ok THEN Fail ELSE
    LET symbolShort == ReadBytes(quantityShort.rest, 6) IN IF ~symbolShort.ok THEN Fail ELSE
    LET priceShort == ReadBytes(symbolShort.rest, 2) IN IF ~priceShort.ok THEN Fail ELSE
    LET executionId == ReadBytes(priceShort.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    Ok([ timeOffset    |-> timeOffset.value,
         orderId       |-> orderId.value,
         sideIndicator |-> sideIndicator.value,
         quantityShort |-> quantityShort.value,
         symbolShort   |-> symbolShort.value,
         priceShort    |-> priceShort.value,
         executionId   |-> executionId.value ], executionId.rest)

ZeroTradeShortMessage ==
    [ timeOffset    |-> [i \in 1 .. 4 |-> 0],
      orderId       |-> [i \in 1 .. 8 |-> 0],
      sideIndicator |-> [i \in 1 .. 1 |-> 0],
      quantityShort |-> [i \in 1 .. 2 |-> 0],
      symbolShort   |-> [i \in 1 .. 6 |-> 0],
      priceShort    |-> [i \in 1 .. 2 |-> 0],
      executionId   |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Short Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeShortMessage ==
    { ZeroTradeShortMessage }
        \cup { [ZeroTradeShortMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroTradeShortMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroTradeShortMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeShortMessage EXCEPT !.quantityShort = one] : one \in Sample(2) }
        \cup { [ZeroTradeShortMessage EXCEPT !.symbolShort = one] : one \in Sample(6) }
        \cup { [ZeroTradeShortMessage EXCEPT !.priceShort = one] : one \in Sample(2) }
        \cup { [ZeroTradeShortMessage EXCEPT !.executionId = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Expanded Message: 41 bytes                                        *)
(***************************************************************************)

TradeExpandedMessage ==
    [ timeOffset    : Sample(4),
      orderId       : Sample(8),
      sideIndicator : Sample(1),
      quantity      : Sample(4),
      symbolLong    : Sample(8),
      price         : Sample(8),
      executionId   : Sample(8) ]

EncodeTradeExpandedMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.quantity
        \o message.symbolLong
        \o message.price
        \o message.executionId

DecodeTradeExpandedMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET quantity == ReadBytes(sideIndicator.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(quantity.rest, 8) IN IF ~symbolLong.ok THEN Fail ELSE
    LET price == ReadBytes(symbolLong.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET executionId == ReadBytes(price.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    Ok([ timeOffset    |-> timeOffset.value,
         orderId       |-> orderId.value,
         sideIndicator |-> sideIndicator.value,
         quantity      |-> quantity.value,
         symbolLong    |-> symbolLong.value,
         price         |-> price.value,
         executionId   |-> executionId.value ], executionId.rest)

ZeroTradeExpandedMessage ==
    [ timeOffset    |-> [i \in 1 .. 4 |-> 0],
      orderId       |-> [i \in 1 .. 8 |-> 0],
      sideIndicator |-> [i \in 1 .. 1 |-> 0],
      quantity      |-> [i \in 1 .. 4 |-> 0],
      symbolLong    |-> [i \in 1 .. 8 |-> 0],
      price         |-> [i \in 1 .. 8 |-> 0],
      executionId   |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Expanded Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeExpandedMessage ==
    { ZeroTradeExpandedMessage }
        \cup { [ZeroTradeExpandedMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroTradeExpandedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroTradeExpandedMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeExpandedMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroTradeExpandedMessage EXCEPT !.symbolLong = one] : one \in Sample(8) }
        \cup { [ZeroTradeExpandedMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeExpandedMessage EXCEPT !.executionId = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Break Message: 12 bytes                                           *)
(***************************************************************************)

TradeBreakMessage ==
    [ timeOffset  : Sample(4),
      executionId : Sample(8) ]

EncodeTradeBreakMessage(message) ==
    message.timeOffset
        \o message.executionId

DecodeTradeBreakMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET executionId == ReadBytes(timeOffset.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    Ok([ timeOffset  |-> timeOffset.value,
         executionId |-> executionId.value ], executionId.rest)

ZeroTradeBreakMessage ==
    [ timeOffset  |-> [i \in 1 .. 4 |-> 0],
      executionId |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Break Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeBreakMessage ==
    { ZeroTradeBreakMessage }
        \cup { [ZeroTradeBreakMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroTradeBreakMessage EXCEPT !.executionId = one] : one \in Sample(8) }

(***************************************************************************)
(* End Of Session: 4 bytes                                                 *)
(***************************************************************************)

EndOfSession ==
    [ lastTimestamp : Sample(4) ]

EncodeEndOfSession(message) ==
    message.lastTimestamp

DecodeEndOfSession(bytes) ==
    LET lastTimestamp == ReadBytes(bytes, 4) IN IF ~lastTimestamp.ok THEN Fail ELSE
    Ok([ lastTimestamp |-> lastTimestamp.value ], lastTimestamp.rest)

ZeroEndOfSession ==
    [ lastTimestamp |-> [i \in 1 .. 4 |-> 0] ]

(* End Of Session at zero, then each field in turn at the values it is checked at *)
CheckedEndOfSession ==
    { ZeroEndOfSession }
        \cup { [ZeroEndOfSession EXCEPT !.lastTimestamp = one] : one \in Sample(4) }

(***************************************************************************)
(* Trading Status Message: 16 bytes                                        *)
(***************************************************************************)

TradingStatusMessage ==
    [ timeOffset    : Sample(4),
      symbolLong    : Sample(8),
      tradingStatus : Sample(1),
      regShoAction  : Sample(1),
      padding       : Sample(2) ]

EncodeTradingStatusMessage(message) ==
    message.timeOffset
        \o message.symbolLong
        \o message.tradingStatus
        \o message.regShoAction
        \o message.padding

DecodeTradingStatusMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(timeOffset.rest, 8) IN IF ~symbolLong.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(symbolLong.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET regShoAction == ReadBytes(tradingStatus.rest, 1) IN IF ~regShoAction.ok THEN Fail ELSE
    LET padding == ReadBytes(regShoAction.rest, 2) IN IF ~padding.ok THEN Fail ELSE
    Ok([ timeOffset    |-> timeOffset.value,
         symbolLong    |-> symbolLong.value,
         tradingStatus |-> tradingStatus.value,
         regShoAction  |-> regShoAction.value,
         padding       |-> padding.value ], padding.rest)

ZeroTradingStatusMessage ==
    [ timeOffset    |-> [i \in 1 .. 4 |-> 0],
      symbolLong    |-> [i \in 1 .. 8 |-> 0],
      tradingStatus |-> [i \in 1 .. 1 |-> 0],
      regShoAction  |-> [i \in 1 .. 1 |-> 0],
      padding       |-> [i \in 1 .. 2 |-> 0] ]

(* Trading Status Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingStatusMessage ==
    { ZeroTradingStatusMessage }
        \cup { [ZeroTradingStatusMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.symbolLong = one] : one \in Sample(8) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.regShoAction = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.padding = one] : one \in Sample(2) }

(***************************************************************************)
(* Auction Update Message: 45 bytes                                        *)
(***************************************************************************)

AuctionUpdateMessage ==
    [ timeOffset       : Sample(4),
      symbolLong       : Sample(8),
      auctionType      : Sample(1),
      referencePrice   : Sample(8),
      buyShares        : Sample(4),
      sellShares       : Sample(4),
      indicativePrice  : Sample(8),
      auctionOnlyPrice : Sample(8) ]

EncodeAuctionUpdateMessage(message) ==
    message.timeOffset
        \o message.symbolLong
        \o message.auctionType
        \o message.referencePrice
        \o message.buyShares
        \o message.sellShares
        \o message.indicativePrice
        \o message.auctionOnlyPrice

DecodeAuctionUpdateMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(timeOffset.rest, 8) IN IF ~symbolLong.ok THEN Fail ELSE
    LET auctionType == ReadBytes(symbolLong.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET referencePrice == ReadBytes(auctionType.rest, 8) IN IF ~referencePrice.ok THEN Fail ELSE
    LET buyShares == ReadBytes(referencePrice.rest, 4) IN IF ~buyShares.ok THEN Fail ELSE
    LET sellShares == ReadBytes(buyShares.rest, 4) IN IF ~sellShares.ok THEN Fail ELSE
    LET indicativePrice == ReadBytes(sellShares.rest, 8) IN IF ~indicativePrice.ok THEN Fail ELSE
    LET auctionOnlyPrice == ReadBytes(indicativePrice.rest, 8) IN IF ~auctionOnlyPrice.ok THEN Fail ELSE
    Ok([ timeOffset       |-> timeOffset.value,
         symbolLong       |-> symbolLong.value,
         auctionType      |-> auctionType.value,
         referencePrice   |-> referencePrice.value,
         buyShares        |-> buyShares.value,
         sellShares       |-> sellShares.value,
         indicativePrice  |-> indicativePrice.value,
         auctionOnlyPrice |-> auctionOnlyPrice.value ], auctionOnlyPrice.rest)

ZeroAuctionUpdateMessage ==
    [ timeOffset       |-> [i \in 1 .. 4 |-> 0],
      symbolLong       |-> [i \in 1 .. 8 |-> 0],
      auctionType      |-> [i \in 1 .. 1 |-> 0],
      referencePrice   |-> [i \in 1 .. 8 |-> 0],
      buyShares        |-> [i \in 1 .. 4 |-> 0],
      sellShares       |-> [i \in 1 .. 4 |-> 0],
      indicativePrice  |-> [i \in 1 .. 8 |-> 0],
      auctionOnlyPrice |-> [i \in 1 .. 8 |-> 0] ]

(* Auction Update Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionUpdateMessage ==
    { ZeroAuctionUpdateMessage }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.symbolLong = one] : one \in Sample(8) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.referencePrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.buyShares = one] : one \in Sample(4) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.sellShares = one] : one \in Sample(4) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.indicativePrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.auctionOnlyPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Auction Summary Message: 25 bytes                                       *)
(***************************************************************************)

AuctionSummaryMessage ==
    [ timeOffset         : Sample(4),
      symbolLong         : Sample(8),
      auctionOpeningType : Sample(1),
      price              : Sample(8),
      sharesContracts    : Sample(4) ]

EncodeAuctionSummaryMessage(message) ==
    message.timeOffset
        \o message.symbolLong
        \o message.auctionOpeningType
        \o message.price
        \o message.sharesContracts

DecodeAuctionSummaryMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(timeOffset.rest, 8) IN IF ~symbolLong.ok THEN Fail ELSE
    LET auctionOpeningType == ReadBytes(symbolLong.rest, 1) IN IF ~auctionOpeningType.ok THEN Fail ELSE
    LET price == ReadBytes(auctionOpeningType.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET sharesContracts == ReadBytes(price.rest, 4) IN IF ~sharesContracts.ok THEN Fail ELSE
    Ok([ timeOffset         |-> timeOffset.value,
         symbolLong         |-> symbolLong.value,
         auctionOpeningType |-> auctionOpeningType.value,
         price              |-> price.value,
         sharesContracts    |-> sharesContracts.value ], sharesContracts.rest)

ZeroAuctionSummaryMessage ==
    [ timeOffset         |-> [i \in 1 .. 4 |-> 0],
      symbolLong         |-> [i \in 1 .. 8 |-> 0],
      auctionOpeningType |-> [i \in 1 .. 1 |-> 0],
      price              |-> [i \in 1 .. 8 |-> 0],
      sharesContracts    |-> [i \in 1 .. 4 |-> 0] ]

(* Auction Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionSummaryMessage ==
    { ZeroAuctionSummaryMessage }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.symbolLong = one] : one \in Sample(8) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.auctionOpeningType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.sharesContracts = one] : one \in Sample(4) }

(***************************************************************************)
(* Retail Price Improvement Message: 13 bytes                              *)
(***************************************************************************)

RetailPriceImprovementMessage ==
    [ timeOffset             : Sample(4),
      symbolLong             : Sample(8),
      retailPriceImprovement : Sample(1) ]

EncodeRetailPriceImprovementMessage(message) ==
    message.timeOffset
        \o message.symbolLong
        \o message.retailPriceImprovement

DecodeRetailPriceImprovementMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(timeOffset.rest, 8) IN IF ~symbolLong.ok THEN Fail ELSE
    LET retailPriceImprovement == ReadBytes(symbolLong.rest, 1) IN IF ~retailPriceImprovement.ok THEN Fail ELSE
    Ok([ timeOffset             |-> timeOffset.value,
         symbolLong             |-> symbolLong.value,
         retailPriceImprovement |-> retailPriceImprovement.value ], retailPriceImprovement.rest)

ZeroRetailPriceImprovementMessage ==
    [ timeOffset             |-> [i \in 1 .. 4 |-> 0],
      symbolLong             |-> [i \in 1 .. 8 |-> 0],
      retailPriceImprovement |-> [i \in 1 .. 1 |-> 0] ]

(* Retail Price Improvement Message at zero, then each field in turn at the values it is checked at *)
CheckedRetailPriceImprovementMessage ==
    { ZeroRetailPriceImprovementMessage }
        \cup { [ZeroRetailPriceImprovementMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroRetailPriceImprovementMessage EXCEPT !.symbolLong = one] : one \in Sample(8) }
        \cup { [ZeroRetailPriceImprovementMessage EXCEPT !.retailPriceImprovement = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

TimeMessageCode == 32  \* 0x20
UnitClearMessageCode == 151  \* 0x97
AddOrderLongMessageCode == 33  \* 0x21
AddOrderShortMessageCode == 34  \* 0x22
AddOrderExpandedMessageCode == 47  \* 0x2f
OrderExecutedMessageCode == 35  \* 0x23
OrderExecutedAtPriceSizeMessageCode == 36  \* 0x24
ReduceSizeLongMessageCode == 37  \* 0x25
ReduceSizeShortMessageCode == 38  \* 0x26
ModifyOrderLongMessageCode == 39  \* 0x27
ModifyOrderShortMessageCode == 40  \* 0x28
DeleteOrderMessageCode == 41  \* 0x29
TradeLongMessageCode == 42  \* 0x2a
TradeShortMessageCode == 43  \* 0x2b
TradeExpandedMessageCode == 48  \* 0x30
TradeBreakMessageCode == 44  \* 0x2c
EndOfSessionCode == 45  \* 0x2d
TradingStatusMessageCode == 49  \* 0x31
AuctionUpdateMessageCode == 149  \* 0x95
AuctionSummaryMessageCode == 150  \* 0x96
RetailPriceImprovementMessageCode == 152  \* 0x98

Payload ==
    [ tag : {TimeMessageCode}, body : TimeMessage ]
        \cup [ tag : {UnitClearMessageCode}, body : UnitClearMessage ]
        \cup [ tag : {AddOrderLongMessageCode}, body : AddOrderLongMessage ]
        \cup [ tag : {AddOrderShortMessageCode}, body : AddOrderShortMessage ]
        \cup [ tag : {AddOrderExpandedMessageCode}, body : AddOrderExpandedMessage ]
        \cup [ tag : {OrderExecutedMessageCode}, body : OrderExecutedMessage ]
        \cup [ tag : {OrderExecutedAtPriceSizeMessageCode}, body : OrderExecutedAtPriceSizeMessage ]
        \cup [ tag : {ReduceSizeLongMessageCode}, body : ReduceSizeLongMessage ]
        \cup [ tag : {ReduceSizeShortMessageCode}, body : ReduceSizeShortMessage ]
        \cup [ tag : {ModifyOrderLongMessageCode}, body : ModifyOrderLongMessage ]
        \cup [ tag : {ModifyOrderShortMessageCode}, body : ModifyOrderShortMessage ]
        \cup [ tag : {DeleteOrderMessageCode}, body : DeleteOrderMessage ]
        \cup [ tag : {TradeLongMessageCode}, body : TradeLongMessage ]
        \cup [ tag : {TradeShortMessageCode}, body : TradeShortMessage ]
        \cup [ tag : {TradeExpandedMessageCode}, body : TradeExpandedMessage ]
        \cup [ tag : {TradeBreakMessageCode}, body : TradeBreakMessage ]
        \cup [ tag : {EndOfSessionCode}, body : EndOfSession ]
        \cup [ tag : {TradingStatusMessageCode}, body : TradingStatusMessage ]
        \cup [ tag : {AuctionUpdateMessageCode}, body : AuctionUpdateMessage ]
        \cup [ tag : {AuctionSummaryMessageCode}, body : AuctionSummaryMessage ]
        \cup [ tag : {RetailPriceImprovementMessageCode}, body : RetailPriceImprovementMessage ]

EncodePayload(message) ==
    CASE message.tag = TimeMessageCode -> EncodeTimeMessage(message.body)
      [] message.tag = UnitClearMessageCode -> EncodeUnitClearMessage(message.body)
      [] message.tag = AddOrderLongMessageCode -> EncodeAddOrderLongMessage(message.body)
      [] message.tag = AddOrderShortMessageCode -> EncodeAddOrderShortMessage(message.body)
      [] message.tag = AddOrderExpandedMessageCode -> EncodeAddOrderExpandedMessage(message.body)
      [] message.tag = OrderExecutedMessageCode -> EncodeOrderExecutedMessage(message.body)
      [] message.tag = OrderExecutedAtPriceSizeMessageCode -> EncodeOrderExecutedAtPriceSizeMessage(message.body)
      [] message.tag = ReduceSizeLongMessageCode -> EncodeReduceSizeLongMessage(message.body)
      [] message.tag = ReduceSizeShortMessageCode -> EncodeReduceSizeShortMessage(message.body)
      [] message.tag = ModifyOrderLongMessageCode -> EncodeModifyOrderLongMessage(message.body)
      [] message.tag = ModifyOrderShortMessageCode -> EncodeModifyOrderShortMessage(message.body)
      [] message.tag = DeleteOrderMessageCode -> EncodeDeleteOrderMessage(message.body)
      [] message.tag = TradeLongMessageCode -> EncodeTradeLongMessage(message.body)
      [] message.tag = TradeShortMessageCode -> EncodeTradeShortMessage(message.body)
      [] message.tag = TradeExpandedMessageCode -> EncodeTradeExpandedMessage(message.body)
      [] message.tag = TradeBreakMessageCode -> EncodeTradeBreakMessage(message.body)
      [] message.tag = EndOfSessionCode -> EncodeEndOfSession(message.body)
      [] message.tag = TradingStatusMessageCode -> EncodeTradingStatusMessage(message.body)
      [] message.tag = AuctionUpdateMessageCode -> EncodeAuctionUpdateMessage(message.body)
      [] message.tag = AuctionSummaryMessageCode -> EncodeAuctionSummaryMessage(message.body)
      [] message.tag = RetailPriceImprovementMessageCode -> EncodeRetailPriceImprovementMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = TimeMessageCode -> DecodeTimeMessage(bytes)
              [] tag = UnitClearMessageCode -> DecodeUnitClearMessage(bytes)
              [] tag = AddOrderLongMessageCode -> DecodeAddOrderLongMessage(bytes)
              [] tag = AddOrderShortMessageCode -> DecodeAddOrderShortMessage(bytes)
              [] tag = AddOrderExpandedMessageCode -> DecodeAddOrderExpandedMessage(bytes)
              [] tag = OrderExecutedMessageCode -> DecodeOrderExecutedMessage(bytes)
              [] tag = OrderExecutedAtPriceSizeMessageCode -> DecodeOrderExecutedAtPriceSizeMessage(bytes)
              [] tag = ReduceSizeLongMessageCode -> DecodeReduceSizeLongMessage(bytes)
              [] tag = ReduceSizeShortMessageCode -> DecodeReduceSizeShortMessage(bytes)
              [] tag = ModifyOrderLongMessageCode -> DecodeModifyOrderLongMessage(bytes)
              [] tag = ModifyOrderShortMessageCode -> DecodeModifyOrderShortMessage(bytes)
              [] tag = DeleteOrderMessageCode -> DecodeDeleteOrderMessage(bytes)
              [] tag = TradeLongMessageCode -> DecodeTradeLongMessage(bytes)
              [] tag = TradeShortMessageCode -> DecodeTradeShortMessage(bytes)
              [] tag = TradeExpandedMessageCode -> DecodeTradeExpandedMessage(bytes)
              [] tag = TradeBreakMessageCode -> DecodeTradeBreakMessage(bytes)
              [] tag = EndOfSessionCode -> DecodeEndOfSession(bytes)
              [] tag = TradingStatusMessageCode -> DecodeTradingStatusMessage(bytes)
              [] tag = AuctionUpdateMessageCode -> DecodeAuctionUpdateMessage(bytes)
              [] tag = AuctionSummaryMessageCode -> DecodeAuctionSummaryMessage(bytes)
              [] tag = RetailPriceImprovementMessageCode -> DecodeRetailPriceImprovementMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> TimeMessageCode, body |-> ZeroTimeMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> TimeMessageCode, body |-> one] : one \in CheckedTimeMessage }
        \cup { [tag |-> UnitClearMessageCode, body |-> one] : one \in CheckedUnitClearMessage }
        \cup { [tag |-> AddOrderLongMessageCode, body |-> one] : one \in CheckedAddOrderLongMessage }
        \cup { [tag |-> AddOrderShortMessageCode, body |-> one] : one \in CheckedAddOrderShortMessage }
        \cup { [tag |-> AddOrderExpandedMessageCode, body |-> one] : one \in CheckedAddOrderExpandedMessage }
        \cup { [tag |-> OrderExecutedMessageCode, body |-> one] : one \in CheckedOrderExecutedMessage }
        \cup { [tag |-> OrderExecutedAtPriceSizeMessageCode, body |-> one] : one \in CheckedOrderExecutedAtPriceSizeMessage }
        \cup { [tag |-> ReduceSizeLongMessageCode, body |-> one] : one \in CheckedReduceSizeLongMessage }
        \cup { [tag |-> ReduceSizeShortMessageCode, body |-> one] : one \in CheckedReduceSizeShortMessage }
        \cup { [tag |-> ModifyOrderLongMessageCode, body |-> one] : one \in CheckedModifyOrderLongMessage }
        \cup { [tag |-> ModifyOrderShortMessageCode, body |-> one] : one \in CheckedModifyOrderShortMessage }
        \cup { [tag |-> DeleteOrderMessageCode, body |-> one] : one \in CheckedDeleteOrderMessage }
        \cup { [tag |-> TradeLongMessageCode, body |-> one] : one \in CheckedTradeLongMessage }
        \cup { [tag |-> TradeShortMessageCode, body |-> one] : one \in CheckedTradeShortMessage }
        \cup { [tag |-> TradeExpandedMessageCode, body |-> one] : one \in CheckedTradeExpandedMessage }
        \cup { [tag |-> TradeBreakMessageCode, body |-> one] : one \in CheckedTradeBreakMessage }
        \cup { [tag |-> EndOfSessionCode, body |-> one] : one \in CheckedEndOfSession }
        \cup { [tag |-> TradingStatusMessageCode, body |-> one] : one \in CheckedTradingStatusMessage }
        \cup { [tag |-> AuctionUpdateMessageCode, body |-> one] : one \in CheckedAuctionUpdateMessage }
        \cup { [tag |-> AuctionSummaryMessageCode, body |-> one] : one \in CheckedAuctionSummaryMessage }
        \cup { [tag |-> RetailPriceImprovementMessageCode, body |-> one] : one \in CheckedRetailPriceImprovementMessage }

(***************************************************************************)
(* Message, framed by Message Length                                       *)
(***************************************************************************)

Message ==
    [ payload : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntLE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntLE(Len(body) + 1, 1) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntLE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 1) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 1 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> TimeMessageCode, body |-> ZeroTimeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> UnitClearMessageCode, body |-> ZeroUnitClearMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddOrderLongMessageCode, body |-> ZeroAddOrderLongMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddOrderShortMessageCode, body |-> ZeroAddOrderShortMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddOrderExpandedMessageCode, body |-> ZeroAddOrderExpandedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderExecutedMessageCode, body |-> ZeroOrderExecutedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderExecutedAtPriceSizeMessageCode, body |-> ZeroOrderExecutedAtPriceSizeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ReduceSizeLongMessageCode, body |-> ZeroReduceSizeLongMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ReduceSizeShortMessageCode, body |-> ZeroReduceSizeShortMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ModifyOrderLongMessageCode, body |-> ZeroModifyOrderLongMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ModifyOrderShortMessageCode, body |-> ZeroModifyOrderShortMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> DeleteOrderMessageCode, body |-> ZeroDeleteOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeLongMessageCode, body |-> ZeroTradeLongMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeShortMessageCode, body |-> ZeroTradeShortMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeExpandedMessageCode, body |-> ZeroTradeExpandedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeBreakMessageCode, body |-> ZeroTradeBreakMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EndOfSessionCode, body |-> ZeroEndOfSession]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradingStatusMessageCode, body |-> ZeroTradingStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionUpdateMessageCode, body |-> ZeroAuctionUpdateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionSummaryMessageCode, body |-> ZeroAuctionSummaryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RetailPriceImprovementMessageCode, body |-> ZeroRetailPriceImprovementMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ length   : Sample(2),
      unit     : Sample(1),
      sequence : Sample(4),
      message  : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.length
        \o EncodeUIntLE(Len(message.message), 1)
        \o message.unit
        \o message.sequence
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET length == ReadBytes(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET messageCount == ReadUIntLE(length.rest, 1) IN IF ~messageCount.ok THEN Fail ELSE
    LET unit == ReadBytes(messageCount.rest, 1) IN IF ~unit.ok THEN Fail ELSE
    LET sequence == ReadBytes(unit.rest, 4) IN IF ~sequence.ok THEN Fail ELSE
    LET message == ReadMessageList(sequence.rest, messageCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ length   |-> length.value,
         unit     |-> unit.value,
         sequence |-> sequence.value,
         message  |-> message.value ], message.rest)

ZeroPacket ==
    [ length   |-> [i \in 1 .. 2 |-> 0],
      unit     |-> [i \in 1 .. 1 |-> 0],
      sequence |-> [i \in 1 .. 4 |-> 0],
      message  |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.length = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.unit = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.sequence = one] : one \in Sample(4) }
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

(* Every Time Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTimeMessage ==
    \A message \in CheckedTimeMessage :
        LET read == DecodeTimeMessage(EncodeTimeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Unit Clear Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUnitClearMessage ==
    \A message \in CheckedUnitClearMessage :
        LET read == DecodeUnitClearMessage(EncodeUnitClearMessage(message))
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

(* Every Add Order Short Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderShortMessage ==
    \A message \in CheckedAddOrderShortMessage :
        LET read == DecodeAddOrderShortMessage(EncodeAddOrderShortMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Order Expanded Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderExpandedMessage ==
    \A message \in CheckedAddOrderExpandedMessage :
        LET read == DecodeAddOrderExpandedMessage(EncodeAddOrderExpandedMessage(message))
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

(* Every Order Executed At Price Size Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutedAtPriceSizeMessage ==
    \A message \in CheckedOrderExecutedAtPriceSizeMessage :
        LET read == DecodeOrderExecutedAtPriceSizeMessage(EncodeOrderExecutedAtPriceSizeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reduce Size Long Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReduceSizeLongMessage ==
    \A message \in CheckedReduceSizeLongMessage :
        LET read == DecodeReduceSizeLongMessage(EncodeReduceSizeLongMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reduce Size Short Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReduceSizeShortMessage ==
    \A message \in CheckedReduceSizeShortMessage :
        LET read == DecodeReduceSizeShortMessage(EncodeReduceSizeShortMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Order Long Message decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyOrderLongMessage ==
    \A message \in CheckedModifyOrderLongMessage :
        LET read == DecodeModifyOrderLongMessage(EncodeModifyOrderLongMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Order Short Message decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyOrderShortMessage ==
    \A message \in CheckedModifyOrderShortMessage :
        LET read == DecodeModifyOrderShortMessage(EncodeModifyOrderShortMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Delete Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDeleteOrderMessage ==
    \A message \in CheckedDeleteOrderMessage :
        LET read == DecodeDeleteOrderMessage(EncodeDeleteOrderMessage(message))
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

(* Every Trade Short Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeShortMessage ==
    \A message \in CheckedTradeShortMessage :
        LET read == DecodeTradeShortMessage(EncodeTradeShortMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Expanded Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeExpandedMessage ==
    \A message \in CheckedTradeExpandedMessage :
        LET read == DecodeTradeExpandedMessage(EncodeTradeExpandedMessage(message))
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

(* Every End Of Session decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfSession ==
    \A message \in CheckedEndOfSession :
        LET read == DecodeEndOfSession(EncodeEndOfSession(message))
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

(* Every Auction Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionSummaryMessage ==
    \A message \in CheckedAuctionSummaryMessage :
        LET read == DecodeAuctionSummaryMessage(EncodeAuctionSummaryMessage(message))
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

(* Message Length is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 1)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
