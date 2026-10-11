-------------- MODULE C1Options_MulticastDepthOfBook_v2_39_4 ---------------
(***************************************************************************)
(* Chicago Board Options Exchange Multicast Depth Of Book v2.39.4          *)
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
(* Note: Add Flags is a bit field set, checked as its 1 byte rather than   *)
(* bit by bit.                                                             *)
(*                                                                         *)
(* Note: Modify Flags is a bit field set, checked as its 1 byte rather     *)
(* than bit by bit.                                                        *)
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
      longQuantity  : Sample(4),
      symbol        : Sample(6),
      longPrice     : Sample(8),
      addFlags      : Sample(1) ]

EncodeAddOrderLongMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.longQuantity
        \o message.symbol
        \o message.longPrice
        \o message.addFlags

DecodeAddOrderLongMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET longQuantity == ReadBytes(sideIndicator.rest, 4) IN IF ~longQuantity.ok THEN Fail ELSE
    LET symbol == ReadBytes(longQuantity.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET longPrice == ReadBytes(symbol.rest, 8) IN IF ~longPrice.ok THEN Fail ELSE
    LET addFlags == ReadBytes(longPrice.rest, 1) IN IF ~addFlags.ok THEN Fail ELSE
    Ok([ timeOffset    |-> timeOffset.value,
         orderId       |-> orderId.value,
         sideIndicator |-> sideIndicator.value,
         longQuantity  |-> longQuantity.value,
         symbol        |-> symbol.value,
         longPrice     |-> longPrice.value,
         addFlags      |-> addFlags.value ], addFlags.rest)

ZeroAddOrderLongMessage ==
    [ timeOffset    |-> [i \in 1 .. 4 |-> 0],
      orderId       |-> [i \in 1 .. 8 |-> 0],
      sideIndicator |-> [i \in 1 .. 1 |-> 0],
      longQuantity  |-> [i \in 1 .. 4 |-> 0],
      symbol        |-> [i \in 1 .. 6 |-> 0],
      longPrice     |-> [i \in 1 .. 8 |-> 0],
      addFlags      |-> [i \in 1 .. 1 |-> 0] ]

(* Add Order Long Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderLongMessage ==
    { ZeroAddOrderLongMessage }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.longQuantity = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.longPrice = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.addFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Add Order Short Message: 24 bytes                                       *)
(***************************************************************************)

AddOrderShortMessage ==
    [ timeOffset    : Sample(4),
      orderId       : Sample(8),
      sideIndicator : Sample(1),
      shortQuantity : Sample(2),
      symbol        : Sample(6),
      shortPrice    : Sample(2),
      addFlags      : Sample(1) ]

EncodeAddOrderShortMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.shortQuantity
        \o message.symbol
        \o message.shortPrice
        \o message.addFlags

DecodeAddOrderShortMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET shortQuantity == ReadBytes(sideIndicator.rest, 2) IN IF ~shortQuantity.ok THEN Fail ELSE
    LET symbol == ReadBytes(shortQuantity.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET shortPrice == ReadBytes(symbol.rest, 2) IN IF ~shortPrice.ok THEN Fail ELSE
    LET addFlags == ReadBytes(shortPrice.rest, 1) IN IF ~addFlags.ok THEN Fail ELSE
    Ok([ timeOffset    |-> timeOffset.value,
         orderId       |-> orderId.value,
         sideIndicator |-> sideIndicator.value,
         shortQuantity |-> shortQuantity.value,
         symbol        |-> symbol.value,
         shortPrice    |-> shortPrice.value,
         addFlags      |-> addFlags.value ], addFlags.rest)

ZeroAddOrderShortMessage ==
    [ timeOffset    |-> [i \in 1 .. 4 |-> 0],
      orderId       |-> [i \in 1 .. 8 |-> 0],
      sideIndicator |-> [i \in 1 .. 1 |-> 0],
      shortQuantity |-> [i \in 1 .. 2 |-> 0],
      symbol        |-> [i \in 1 .. 6 |-> 0],
      shortPrice    |-> [i \in 1 .. 2 |-> 0],
      addFlags      |-> [i \in 1 .. 1 |-> 0] ]

(* Add Order Short Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderShortMessage ==
    { ZeroAddOrderShortMessage }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.shortQuantity = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.shortPrice = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.addFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Add Order Expanded Message: 39 bytes                                    *)
(***************************************************************************)

AddOrderExpandedMessage ==
    [ timeOffset        : Sample(4),
      orderId           : Sample(8),
      sideIndicator     : Sample(1),
      longQuantity      : Sample(4),
      expandedSymbol    : Sample(8),
      longPrice         : Sample(8),
      addFlags          : Sample(1),
      participantId     : Sample(4),
      customerIndicator : Sample(1) ]

EncodeAddOrderExpandedMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.longQuantity
        \o message.expandedSymbol
        \o message.longPrice
        \o message.addFlags
        \o message.participantId
        \o message.customerIndicator

DecodeAddOrderExpandedMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET longQuantity == ReadBytes(sideIndicator.rest, 4) IN IF ~longQuantity.ok THEN Fail ELSE
    LET expandedSymbol == ReadBytes(longQuantity.rest, 8) IN IF ~expandedSymbol.ok THEN Fail ELSE
    LET longPrice == ReadBytes(expandedSymbol.rest, 8) IN IF ~longPrice.ok THEN Fail ELSE
    LET addFlags == ReadBytes(longPrice.rest, 1) IN IF ~addFlags.ok THEN Fail ELSE
    LET participantId == ReadBytes(addFlags.rest, 4) IN IF ~participantId.ok THEN Fail ELSE
    LET customerIndicator == ReadBytes(participantId.rest, 1) IN IF ~customerIndicator.ok THEN Fail ELSE
    Ok([ timeOffset        |-> timeOffset.value,
         orderId           |-> orderId.value,
         sideIndicator     |-> sideIndicator.value,
         longQuantity      |-> longQuantity.value,
         expandedSymbol    |-> expandedSymbol.value,
         longPrice         |-> longPrice.value,
         addFlags          |-> addFlags.value,
         participantId     |-> participantId.value,
         customerIndicator |-> customerIndicator.value ], customerIndicator.rest)

ZeroAddOrderExpandedMessage ==
    [ timeOffset        |-> [i \in 1 .. 4 |-> 0],
      orderId           |-> [i \in 1 .. 8 |-> 0],
      sideIndicator     |-> [i \in 1 .. 1 |-> 0],
      longQuantity      |-> [i \in 1 .. 4 |-> 0],
      expandedSymbol    |-> [i \in 1 .. 8 |-> 0],
      longPrice         |-> [i \in 1 .. 8 |-> 0],
      addFlags          |-> [i \in 1 .. 1 |-> 0],
      participantId     |-> [i \in 1 .. 4 |-> 0],
      customerIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Add Order Expanded Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderExpandedMessage ==
    { ZeroAddOrderExpandedMessage }
        \cup { [ZeroAddOrderExpandedMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderExpandedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderExpandedMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderExpandedMessage EXCEPT !.longQuantity = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderExpandedMessage EXCEPT !.expandedSymbol = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderExpandedMessage EXCEPT !.longPrice = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderExpandedMessage EXCEPT !.addFlags = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderExpandedMessage EXCEPT !.participantId = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderExpandedMessage EXCEPT !.customerIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Executed Message: 25 bytes                                        *)
(***************************************************************************)

OrderExecutedMessage ==
    [ timeOffset       : Sample(4),
      orderId          : Sample(8),
      executedQuantity : Sample(4),
      executionId      : Sample(8),
      tradeCondition   : Sample(1) ]

EncodeOrderExecutedMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.executedQuantity
        \o message.executionId
        \o message.tradeCondition

DecodeOrderExecutedMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(orderId.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET executionId == ReadBytes(executedQuantity.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(executionId.rest, 1) IN IF ~tradeCondition.ok THEN Fail ELSE
    Ok([ timeOffset       |-> timeOffset.value,
         orderId          |-> orderId.value,
         executedQuantity |-> executedQuantity.value,
         executionId      |-> executionId.value,
         tradeCondition   |-> tradeCondition.value ], tradeCondition.rest)

ZeroOrderExecutedMessage ==
    [ timeOffset       |-> [i \in 1 .. 4 |-> 0],
      orderId          |-> [i \in 1 .. 8 |-> 0],
      executedQuantity |-> [i \in 1 .. 4 |-> 0],
      executionId      |-> [i \in 1 .. 8 |-> 0],
      tradeCondition   |-> [i \in 1 .. 1 |-> 0] ]

(* Order Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedMessage ==
    { ZeroOrderExecutedMessage }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Executed At Price Size Message: 37 bytes                          *)
(***************************************************************************)

OrderExecutedAtPriceSizeMessage ==
    [ timeOffset        : Sample(4),
      orderId           : Sample(8),
      executedQuantity  : Sample(4),
      remainingQuantity : Sample(4),
      executionId       : Sample(8),
      longPrice         : Sample(8),
      tradeCondition    : Sample(1) ]

EncodeOrderExecutedAtPriceSizeMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.executedQuantity
        \o message.remainingQuantity
        \o message.executionId
        \o message.longPrice
        \o message.tradeCondition

DecodeOrderExecutedAtPriceSizeMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(orderId.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET remainingQuantity == ReadBytes(executedQuantity.rest, 4) IN IF ~remainingQuantity.ok THEN Fail ELSE
    LET executionId == ReadBytes(remainingQuantity.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET longPrice == ReadBytes(executionId.rest, 8) IN IF ~longPrice.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(longPrice.rest, 1) IN IF ~tradeCondition.ok THEN Fail ELSE
    Ok([ timeOffset        |-> timeOffset.value,
         orderId           |-> orderId.value,
         executedQuantity  |-> executedQuantity.value,
         remainingQuantity |-> remainingQuantity.value,
         executionId       |-> executionId.value,
         longPrice         |-> longPrice.value,
         tradeCondition    |-> tradeCondition.value ], tradeCondition.rest)

ZeroOrderExecutedAtPriceSizeMessage ==
    [ timeOffset        |-> [i \in 1 .. 4 |-> 0],
      orderId           |-> [i \in 1 .. 8 |-> 0],
      executedQuantity  |-> [i \in 1 .. 4 |-> 0],
      remainingQuantity |-> [i \in 1 .. 4 |-> 0],
      executionId       |-> [i \in 1 .. 8 |-> 0],
      longPrice         |-> [i \in 1 .. 8 |-> 0],
      tradeCondition    |-> [i \in 1 .. 1 |-> 0] ]

(* Order Executed At Price Size Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedAtPriceSizeMessage ==
    { ZeroOrderExecutedAtPriceSizeMessage }
        \cup { [ZeroOrderExecutedAtPriceSizeMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedAtPriceSizeMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedAtPriceSizeMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedAtPriceSizeMessage EXCEPT !.remainingQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedAtPriceSizeMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedAtPriceSizeMessage EXCEPT !.longPrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedAtPriceSizeMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Reduce Size Long Message: 16 bytes                                      *)
(***************************************************************************)

ReduceSizeLongMessage ==
    [ timeOffset           : Sample(4),
      orderId              : Sample(8),
      canceledLongQuantity : Sample(4) ]

EncodeReduceSizeLongMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.canceledLongQuantity

DecodeReduceSizeLongMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET canceledLongQuantity == ReadBytes(orderId.rest, 4) IN IF ~canceledLongQuantity.ok THEN Fail ELSE
    Ok([ timeOffset           |-> timeOffset.value,
         orderId              |-> orderId.value,
         canceledLongQuantity |-> canceledLongQuantity.value ], canceledLongQuantity.rest)

ZeroReduceSizeLongMessage ==
    [ timeOffset           |-> [i \in 1 .. 4 |-> 0],
      orderId              |-> [i \in 1 .. 8 |-> 0],
      canceledLongQuantity |-> [i \in 1 .. 4 |-> 0] ]

(* Reduce Size Long Message at zero, then each field in turn at the values it is checked at *)
CheckedReduceSizeLongMessage ==
    { ZeroReduceSizeLongMessage }
        \cup { [ZeroReduceSizeLongMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroReduceSizeLongMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroReduceSizeLongMessage EXCEPT !.canceledLongQuantity = one] : one \in Sample(4) }

(***************************************************************************)
(* Reduce Size Short Message: 14 bytes                                     *)
(***************************************************************************)

ReduceSizeShortMessage ==
    [ timeOffset            : Sample(4),
      orderId               : Sample(8),
      canceledShortQuantity : Sample(2) ]

EncodeReduceSizeShortMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.canceledShortQuantity

DecodeReduceSizeShortMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET canceledShortQuantity == ReadBytes(orderId.rest, 2) IN IF ~canceledShortQuantity.ok THEN Fail ELSE
    Ok([ timeOffset            |-> timeOffset.value,
         orderId               |-> orderId.value,
         canceledShortQuantity |-> canceledShortQuantity.value ], canceledShortQuantity.rest)

ZeroReduceSizeShortMessage ==
    [ timeOffset            |-> [i \in 1 .. 4 |-> 0],
      orderId               |-> [i \in 1 .. 8 |-> 0],
      canceledShortQuantity |-> [i \in 1 .. 2 |-> 0] ]

(* Reduce Size Short Message at zero, then each field in turn at the values it is checked at *)
CheckedReduceSizeShortMessage ==
    { ZeroReduceSizeShortMessage }
        \cup { [ZeroReduceSizeShortMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroReduceSizeShortMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroReduceSizeShortMessage EXCEPT !.canceledShortQuantity = one] : one \in Sample(2) }

(***************************************************************************)
(* Modify Order Long Message: 25 bytes                                     *)
(***************************************************************************)

ModifyOrderLongMessage ==
    [ timeOffset   : Sample(4),
      orderId      : Sample(8),
      longQuantity : Sample(4),
      longPrice    : Sample(8),
      modifyFlags  : Sample(1) ]

EncodeModifyOrderLongMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.longQuantity
        \o message.longPrice
        \o message.modifyFlags

DecodeModifyOrderLongMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET longQuantity == ReadBytes(orderId.rest, 4) IN IF ~longQuantity.ok THEN Fail ELSE
    LET longPrice == ReadBytes(longQuantity.rest, 8) IN IF ~longPrice.ok THEN Fail ELSE
    LET modifyFlags == ReadBytes(longPrice.rest, 1) IN IF ~modifyFlags.ok THEN Fail ELSE
    Ok([ timeOffset   |-> timeOffset.value,
         orderId      |-> orderId.value,
         longQuantity |-> longQuantity.value,
         longPrice    |-> longPrice.value,
         modifyFlags  |-> modifyFlags.value ], modifyFlags.rest)

ZeroModifyOrderLongMessage ==
    [ timeOffset   |-> [i \in 1 .. 4 |-> 0],
      orderId      |-> [i \in 1 .. 8 |-> 0],
      longQuantity |-> [i \in 1 .. 4 |-> 0],
      longPrice    |-> [i \in 1 .. 8 |-> 0],
      modifyFlags  |-> [i \in 1 .. 1 |-> 0] ]

(* Modify Order Long Message at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderLongMessage ==
    { ZeroModifyOrderLongMessage }
        \cup { [ZeroModifyOrderLongMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderLongMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderLongMessage EXCEPT !.longQuantity = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderLongMessage EXCEPT !.longPrice = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderLongMessage EXCEPT !.modifyFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Modify Order Short Message: 17 bytes                                    *)
(***************************************************************************)

ModifyOrderShortMessage ==
    [ timeOffset    : Sample(4),
      orderId       : Sample(8),
      shortQuantity : Sample(2),
      shortPrice    : Sample(2),
      modifyFlags   : Sample(1) ]

EncodeModifyOrderShortMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.shortQuantity
        \o message.shortPrice
        \o message.modifyFlags

DecodeModifyOrderShortMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET shortQuantity == ReadBytes(orderId.rest, 2) IN IF ~shortQuantity.ok THEN Fail ELSE
    LET shortPrice == ReadBytes(shortQuantity.rest, 2) IN IF ~shortPrice.ok THEN Fail ELSE
    LET modifyFlags == ReadBytes(shortPrice.rest, 1) IN IF ~modifyFlags.ok THEN Fail ELSE
    Ok([ timeOffset    |-> timeOffset.value,
         orderId       |-> orderId.value,
         shortQuantity |-> shortQuantity.value,
         shortPrice    |-> shortPrice.value,
         modifyFlags   |-> modifyFlags.value ], modifyFlags.rest)

ZeroModifyOrderShortMessage ==
    [ timeOffset    |-> [i \in 1 .. 4 |-> 0],
      orderId       |-> [i \in 1 .. 8 |-> 0],
      shortQuantity |-> [i \in 1 .. 2 |-> 0],
      shortPrice    |-> [i \in 1 .. 2 |-> 0],
      modifyFlags   |-> [i \in 1 .. 1 |-> 0] ]

(* Modify Order Short Message at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderShortMessage ==
    { ZeroModifyOrderShortMessage }
        \cup { [ZeroModifyOrderShortMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderShortMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderShortMessage EXCEPT !.shortQuantity = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderShortMessage EXCEPT !.shortPrice = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderShortMessage EXCEPT !.modifyFlags = one] : one \in Sample(1) }

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
(* Trade Long Message: 40 bytes                                            *)
(***************************************************************************)

TradeLongMessage ==
    [ timeOffset     : Sample(4),
      orderId        : Sample(8),
      sideIndicator  : Sample(1),
      longQuantity   : Sample(4),
      symbol         : Sample(6),
      longPrice      : Sample(8),
      executionId    : Sample(8),
      tradeCondition : Sample(1) ]

EncodeTradeLongMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.longQuantity
        \o message.symbol
        \o message.longPrice
        \o message.executionId
        \o message.tradeCondition

DecodeTradeLongMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET longQuantity == ReadBytes(sideIndicator.rest, 4) IN IF ~longQuantity.ok THEN Fail ELSE
    LET symbol == ReadBytes(longQuantity.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET longPrice == ReadBytes(symbol.rest, 8) IN IF ~longPrice.ok THEN Fail ELSE
    LET executionId == ReadBytes(longPrice.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(executionId.rest, 1) IN IF ~tradeCondition.ok THEN Fail ELSE
    Ok([ timeOffset     |-> timeOffset.value,
         orderId        |-> orderId.value,
         sideIndicator  |-> sideIndicator.value,
         longQuantity   |-> longQuantity.value,
         symbol         |-> symbol.value,
         longPrice      |-> longPrice.value,
         executionId    |-> executionId.value,
         tradeCondition |-> tradeCondition.value ], tradeCondition.rest)

ZeroTradeLongMessage ==
    [ timeOffset     |-> [i \in 1 .. 4 |-> 0],
      orderId        |-> [i \in 1 .. 8 |-> 0],
      sideIndicator  |-> [i \in 1 .. 1 |-> 0],
      longQuantity   |-> [i \in 1 .. 4 |-> 0],
      symbol         |-> [i \in 1 .. 6 |-> 0],
      longPrice      |-> [i \in 1 .. 8 |-> 0],
      executionId    |-> [i \in 1 .. 8 |-> 0],
      tradeCondition |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Long Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeLongMessage ==
    { ZeroTradeLongMessage }
        \cup { [ZeroTradeLongMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroTradeLongMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroTradeLongMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeLongMessage EXCEPT !.longQuantity = one] : one \in Sample(4) }
        \cup { [ZeroTradeLongMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroTradeLongMessage EXCEPT !.longPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeLongMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroTradeLongMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Short Message: 32 bytes                                           *)
(***************************************************************************)

TradeShortMessage ==
    [ timeOffset     : Sample(4),
      orderId        : Sample(8),
      sideIndicator  : Sample(1),
      shortQuantity  : Sample(2),
      symbol         : Sample(6),
      shortPrice     : Sample(2),
      executionId    : Sample(8),
      tradeCondition : Sample(1) ]

EncodeTradeShortMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.shortQuantity
        \o message.symbol
        \o message.shortPrice
        \o message.executionId
        \o message.tradeCondition

DecodeTradeShortMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET shortQuantity == ReadBytes(sideIndicator.rest, 2) IN IF ~shortQuantity.ok THEN Fail ELSE
    LET symbol == ReadBytes(shortQuantity.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET shortPrice == ReadBytes(symbol.rest, 2) IN IF ~shortPrice.ok THEN Fail ELSE
    LET executionId == ReadBytes(shortPrice.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(executionId.rest, 1) IN IF ~tradeCondition.ok THEN Fail ELSE
    Ok([ timeOffset     |-> timeOffset.value,
         orderId        |-> orderId.value,
         sideIndicator  |-> sideIndicator.value,
         shortQuantity  |-> shortQuantity.value,
         symbol         |-> symbol.value,
         shortPrice     |-> shortPrice.value,
         executionId    |-> executionId.value,
         tradeCondition |-> tradeCondition.value ], tradeCondition.rest)

ZeroTradeShortMessage ==
    [ timeOffset     |-> [i \in 1 .. 4 |-> 0],
      orderId        |-> [i \in 1 .. 8 |-> 0],
      sideIndicator  |-> [i \in 1 .. 1 |-> 0],
      shortQuantity  |-> [i \in 1 .. 2 |-> 0],
      symbol         |-> [i \in 1 .. 6 |-> 0],
      shortPrice     |-> [i \in 1 .. 2 |-> 0],
      executionId    |-> [i \in 1 .. 8 |-> 0],
      tradeCondition |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Short Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeShortMessage ==
    { ZeroTradeShortMessage }
        \cup { [ZeroTradeShortMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroTradeShortMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroTradeShortMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeShortMessage EXCEPT !.shortQuantity = one] : one \in Sample(2) }
        \cup { [ZeroTradeShortMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroTradeShortMessage EXCEPT !.shortPrice = one] : one \in Sample(2) }
        \cup { [ZeroTradeShortMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroTradeShortMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Expanded Message: 42 bytes                                        *)
(***************************************************************************)

TradeExpandedMessage ==
    [ timeOffset     : Sample(4),
      orderId        : Sample(8),
      sideIndicator  : Sample(1),
      longQuantity   : Sample(4),
      expandedSymbol : Sample(8),
      longPrice      : Sample(8),
      executionId    : Sample(8),
      tradeCondition : Sample(1) ]

EncodeTradeExpandedMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.longQuantity
        \o message.expandedSymbol
        \o message.longPrice
        \o message.executionId
        \o message.tradeCondition

DecodeTradeExpandedMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET longQuantity == ReadBytes(sideIndicator.rest, 4) IN IF ~longQuantity.ok THEN Fail ELSE
    LET expandedSymbol == ReadBytes(longQuantity.rest, 8) IN IF ~expandedSymbol.ok THEN Fail ELSE
    LET longPrice == ReadBytes(expandedSymbol.rest, 8) IN IF ~longPrice.ok THEN Fail ELSE
    LET executionId == ReadBytes(longPrice.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(executionId.rest, 1) IN IF ~tradeCondition.ok THEN Fail ELSE
    Ok([ timeOffset     |-> timeOffset.value,
         orderId        |-> orderId.value,
         sideIndicator  |-> sideIndicator.value,
         longQuantity   |-> longQuantity.value,
         expandedSymbol |-> expandedSymbol.value,
         longPrice      |-> longPrice.value,
         executionId    |-> executionId.value,
         tradeCondition |-> tradeCondition.value ], tradeCondition.rest)

ZeroTradeExpandedMessage ==
    [ timeOffset     |-> [i \in 1 .. 4 |-> 0],
      orderId        |-> [i \in 1 .. 8 |-> 0],
      sideIndicator  |-> [i \in 1 .. 1 |-> 0],
      longQuantity   |-> [i \in 1 .. 4 |-> 0],
      expandedSymbol |-> [i \in 1 .. 8 |-> 0],
      longPrice      |-> [i \in 1 .. 8 |-> 0],
      executionId    |-> [i \in 1 .. 8 |-> 0],
      tradeCondition |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Expanded Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeExpandedMessage ==
    { ZeroTradeExpandedMessage }
        \cup { [ZeroTradeExpandedMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroTradeExpandedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroTradeExpandedMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeExpandedMessage EXCEPT !.longQuantity = one] : one \in Sample(4) }
        \cup { [ZeroTradeExpandedMessage EXCEPT !.expandedSymbol = one] : one \in Sample(8) }
        \cup { [ZeroTradeExpandedMessage EXCEPT !.longPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeExpandedMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroTradeExpandedMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }

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
(* End Of Session Message: 4 bytes                                         *)
(***************************************************************************)

EndOfSessionMessage ==
    [ timeOffset : Sample(4) ]

EncodeEndOfSessionMessage(message) ==
    message.timeOffset

DecodeEndOfSessionMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    Ok([ timeOffset |-> timeOffset.value ], timeOffset.rest)

ZeroEndOfSessionMessage ==
    [ timeOffset |-> [i \in 1 .. 4 |-> 0] ]

(* End Of Session Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfSessionMessage ==
    { ZeroEndOfSessionMessage }
        \cup { [ZeroEndOfSessionMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }

(***************************************************************************)
(* Symbol Mapping Message: 28 bytes                                        *)
(***************************************************************************)

SymbolMappingMessage ==
    [ feedSymbol      : Sample(6),
      osiSymbol       : Sample(21),
      symbolCondition : Sample(1) ]

EncodeSymbolMappingMessage(message) ==
    message.feedSymbol
        \o message.osiSymbol
        \o message.symbolCondition

DecodeSymbolMappingMessage(bytes) ==
    LET feedSymbol == ReadBytes(bytes, 6) IN IF ~feedSymbol.ok THEN Fail ELSE
    LET osiSymbol == ReadBytes(feedSymbol.rest, 21) IN IF ~osiSymbol.ok THEN Fail ELSE
    LET symbolCondition == ReadBytes(osiSymbol.rest, 1) IN IF ~symbolCondition.ok THEN Fail ELSE
    Ok([ feedSymbol      |-> feedSymbol.value,
         osiSymbol       |-> osiSymbol.value,
         symbolCondition |-> symbolCondition.value ], symbolCondition.rest)

ZeroSymbolMappingMessage ==
    [ feedSymbol      |-> [i \in 1 .. 6 |-> 0],
      osiSymbol       |-> [i \in 1 .. 21 |-> 0],
      symbolCondition |-> [i \in 1 .. 1 |-> 0] ]

(* Symbol Mapping Message at zero, then each field in turn at the values it is checked at *)
CheckedSymbolMappingMessage ==
    { ZeroSymbolMappingMessage }
        \cup { [ZeroSymbolMappingMessage EXCEPT !.feedSymbol = one] : one \in Sample(6) }
        \cup { [ZeroSymbolMappingMessage EXCEPT !.osiSymbol = one] : one \in Sample(21) }
        \cup { [ZeroSymbolMappingMessage EXCEPT !.symbolCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Trading Status Message: 16 bytes                                        *)
(***************************************************************************)

TradingStatusMessage ==
    [ timeOffset      : Sample(4),
      expandedSymbol  : Sample(8),
      tradingStatus   : Sample(1),
      regShoAction    : Sample(1),
      reserved1       : Sample(1),
      secondReserved1 : Sample(1) ]

EncodeTradingStatusMessage(message) ==
    message.timeOffset
        \o message.expandedSymbol
        \o message.tradingStatus
        \o message.regShoAction
        \o message.reserved1
        \o message.secondReserved1

DecodeTradingStatusMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET expandedSymbol == ReadBytes(timeOffset.rest, 8) IN IF ~expandedSymbol.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(expandedSymbol.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET regShoAction == ReadBytes(tradingStatus.rest, 1) IN IF ~regShoAction.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(regShoAction.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET secondReserved1 == ReadBytes(reserved1.rest, 1) IN IF ~secondReserved1.ok THEN Fail ELSE
    Ok([ timeOffset      |-> timeOffset.value,
         expandedSymbol  |-> expandedSymbol.value,
         tradingStatus   |-> tradingStatus.value,
         regShoAction    |-> regShoAction.value,
         reserved1       |-> reserved1.value,
         secondReserved1 |-> secondReserved1.value ], secondReserved1.rest)

ZeroTradingStatusMessage ==
    [ timeOffset      |-> [i \in 1 .. 4 |-> 0],
      expandedSymbol  |-> [i \in 1 .. 8 |-> 0],
      tradingStatus   |-> [i \in 1 .. 1 |-> 0],
      regShoAction    |-> [i \in 1 .. 1 |-> 0],
      reserved1       |-> [i \in 1 .. 1 |-> 0],
      secondReserved1 |-> [i \in 1 .. 1 |-> 0] ]

(* Trading Status Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingStatusMessage ==
    { ZeroTradingStatusMessage }
        \cup { [ZeroTradingStatusMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.expandedSymbol = one] : one \in Sample(8) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.regShoAction = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.secondReserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Auction Update Message: 45 bytes                                        *)
(***************************************************************************)

AuctionUpdateMessage ==
    [ timeOffset       : Sample(4),
      stockSymbol      : Sample(8),
      auctionType      : Sample(1),
      referencePrice   : Sample(8),
      buyShares        : Sample(4),
      sellShares       : Sample(4),
      indicativePrice  : Sample(8),
      auctionOnlyPrice : Sample(8) ]

EncodeAuctionUpdateMessage(message) ==
    message.timeOffset
        \o message.stockSymbol
        \o message.auctionType
        \o message.referencePrice
        \o message.buyShares
        \o message.sellShares
        \o message.indicativePrice
        \o message.auctionOnlyPrice

DecodeAuctionUpdateMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET stockSymbol == ReadBytes(timeOffset.rest, 8) IN IF ~stockSymbol.ok THEN Fail ELSE
    LET auctionType == ReadBytes(stockSymbol.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET referencePrice == ReadBytes(auctionType.rest, 8) IN IF ~referencePrice.ok THEN Fail ELSE
    LET buyShares == ReadBytes(referencePrice.rest, 4) IN IF ~buyShares.ok THEN Fail ELSE
    LET sellShares == ReadBytes(buyShares.rest, 4) IN IF ~sellShares.ok THEN Fail ELSE
    LET indicativePrice == ReadBytes(sellShares.rest, 8) IN IF ~indicativePrice.ok THEN Fail ELSE
    LET auctionOnlyPrice == ReadBytes(indicativePrice.rest, 8) IN IF ~auctionOnlyPrice.ok THEN Fail ELSE
    Ok([ timeOffset       |-> timeOffset.value,
         stockSymbol      |-> stockSymbol.value,
         auctionType      |-> auctionType.value,
         referencePrice   |-> referencePrice.value,
         buyShares        |-> buyShares.value,
         sellShares       |-> sellShares.value,
         indicativePrice  |-> indicativePrice.value,
         auctionOnlyPrice |-> auctionOnlyPrice.value ], auctionOnlyPrice.rest)

ZeroAuctionUpdateMessage ==
    [ timeOffset       |-> [i \in 1 .. 4 |-> 0],
      stockSymbol      |-> [i \in 1 .. 8 |-> 0],
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
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.stockSymbol = one] : one \in Sample(8) }
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
    [ timeOffset  : Sample(4),
      stockSymbol : Sample(8),
      auctionType : Sample(1),
      longPrice   : Sample(8),
      shares      : Sample(4) ]

EncodeAuctionSummaryMessage(message) ==
    message.timeOffset
        \o message.stockSymbol
        \o message.auctionType
        \o message.longPrice
        \o message.shares

DecodeAuctionSummaryMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET stockSymbol == ReadBytes(timeOffset.rest, 8) IN IF ~stockSymbol.ok THEN Fail ELSE
    LET auctionType == ReadBytes(stockSymbol.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET longPrice == ReadBytes(auctionType.rest, 8) IN IF ~longPrice.ok THEN Fail ELSE
    LET shares == ReadBytes(longPrice.rest, 4) IN IF ~shares.ok THEN Fail ELSE
    Ok([ timeOffset  |-> timeOffset.value,
         stockSymbol |-> stockSymbol.value,
         auctionType |-> auctionType.value,
         longPrice   |-> longPrice.value,
         shares      |-> shares.value ], shares.rest)

ZeroAuctionSummaryMessage ==
    [ timeOffset  |-> [i \in 1 .. 4 |-> 0],
      stockSymbol |-> [i \in 1 .. 8 |-> 0],
      auctionType |-> [i \in 1 .. 1 |-> 0],
      longPrice   |-> [i \in 1 .. 8 |-> 0],
      shares      |-> [i \in 1 .. 4 |-> 0] ]

(* Auction Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionSummaryMessage ==
    { ZeroAuctionSummaryMessage }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.stockSymbol = one] : one \in Sample(8) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.longPrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.shares = one] : one \in Sample(4) }

(***************************************************************************)
(* Auction Notification Message: 41 bytes                                  *)
(***************************************************************************)

AuctionNotificationMessage ==
    [ timeOffset        : Sample(4),
      symbol            : Sample(6),
      auctionId         : Sample(8),
      auctionType       : Sample(1),
      sideIndicator     : Sample(1),
      longPrice         : Sample(8),
      contracts         : Sample(4),
      customerIndicator : Sample(1),
      participantId     : Sample(4),
      auctionEndOffset  : Sample(4) ]

EncodeAuctionNotificationMessage(message) ==
    message.timeOffset
        \o message.symbol
        \o message.auctionId
        \o message.auctionType
        \o message.sideIndicator
        \o message.longPrice
        \o message.contracts
        \o message.customerIndicator
        \o message.participantId
        \o message.auctionEndOffset

DecodeAuctionNotificationMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET symbol == ReadBytes(timeOffset.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET auctionId == ReadBytes(symbol.rest, 8) IN IF ~auctionId.ok THEN Fail ELSE
    LET auctionType == ReadBytes(auctionId.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(auctionType.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET longPrice == ReadBytes(sideIndicator.rest, 8) IN IF ~longPrice.ok THEN Fail ELSE
    LET contracts == ReadBytes(longPrice.rest, 4) IN IF ~contracts.ok THEN Fail ELSE
    LET customerIndicator == ReadBytes(contracts.rest, 1) IN IF ~customerIndicator.ok THEN Fail ELSE
    LET participantId == ReadBytes(customerIndicator.rest, 4) IN IF ~participantId.ok THEN Fail ELSE
    LET auctionEndOffset == ReadBytes(participantId.rest, 4) IN IF ~auctionEndOffset.ok THEN Fail ELSE
    Ok([ timeOffset        |-> timeOffset.value,
         symbol            |-> symbol.value,
         auctionId         |-> auctionId.value,
         auctionType       |-> auctionType.value,
         sideIndicator     |-> sideIndicator.value,
         longPrice         |-> longPrice.value,
         contracts         |-> contracts.value,
         customerIndicator |-> customerIndicator.value,
         participantId     |-> participantId.value,
         auctionEndOffset  |-> auctionEndOffset.value ], auctionEndOffset.rest)

ZeroAuctionNotificationMessage ==
    [ timeOffset        |-> [i \in 1 .. 4 |-> 0],
      symbol            |-> [i \in 1 .. 6 |-> 0],
      auctionId         |-> [i \in 1 .. 8 |-> 0],
      auctionType       |-> [i \in 1 .. 1 |-> 0],
      sideIndicator     |-> [i \in 1 .. 1 |-> 0],
      longPrice         |-> [i \in 1 .. 8 |-> 0],
      contracts         |-> [i \in 1 .. 4 |-> 0],
      customerIndicator |-> [i \in 1 .. 1 |-> 0],
      participantId     |-> [i \in 1 .. 4 |-> 0],
      auctionEndOffset  |-> [i \in 1 .. 4 |-> 0] ]

(* Auction Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionNotificationMessage ==
    { ZeroAuctionNotificationMessage }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.auctionId = one] : one \in Sample(8) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.longPrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.contracts = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.customerIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.participantId = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.auctionEndOffset = one] : one \in Sample(4) }

(***************************************************************************)
(* Auction Cancel Message: 12 bytes                                        *)
(***************************************************************************)

AuctionCancelMessage ==
    [ timeOffset : Sample(4),
      auctionId  : Sample(8) ]

EncodeAuctionCancelMessage(message) ==
    message.timeOffset
        \o message.auctionId

DecodeAuctionCancelMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET auctionId == ReadBytes(timeOffset.rest, 8) IN IF ~auctionId.ok THEN Fail ELSE
    Ok([ timeOffset |-> timeOffset.value,
         auctionId  |-> auctionId.value ], auctionId.rest)

ZeroAuctionCancelMessage ==
    [ timeOffset |-> [i \in 1 .. 4 |-> 0],
      auctionId  |-> [i \in 1 .. 8 |-> 0] ]

(* Auction Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionCancelMessage ==
    { ZeroAuctionCancelMessage }
        \cup { [ZeroAuctionCancelMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAuctionCancelMessage EXCEPT !.auctionId = one] : one \in Sample(8) }

(***************************************************************************)
(* Auction Trade Message: 32 bytes                                         *)
(***************************************************************************)

AuctionTradeMessage ==
    [ timeOffset  : Sample(4),
      auctionId   : Sample(8),
      executionId : Sample(8),
      longPrice   : Sample(8),
      contracts   : Sample(4) ]

EncodeAuctionTradeMessage(message) ==
    message.timeOffset
        \o message.auctionId
        \o message.executionId
        \o message.longPrice
        \o message.contracts

DecodeAuctionTradeMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET auctionId == ReadBytes(timeOffset.rest, 8) IN IF ~auctionId.ok THEN Fail ELSE
    LET executionId == ReadBytes(auctionId.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET longPrice == ReadBytes(executionId.rest, 8) IN IF ~longPrice.ok THEN Fail ELSE
    LET contracts == ReadBytes(longPrice.rest, 4) IN IF ~contracts.ok THEN Fail ELSE
    Ok([ timeOffset  |-> timeOffset.value,
         auctionId   |-> auctionId.value,
         executionId |-> executionId.value,
         longPrice   |-> longPrice.value,
         contracts   |-> contracts.value ], contracts.rest)

ZeroAuctionTradeMessage ==
    [ timeOffset  |-> [i \in 1 .. 4 |-> 0],
      auctionId   |-> [i \in 1 .. 8 |-> 0],
      executionId |-> [i \in 1 .. 8 |-> 0],
      longPrice   |-> [i \in 1 .. 8 |-> 0],
      contracts   |-> [i \in 1 .. 4 |-> 0] ]

(* Auction Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionTradeMessage ==
    { ZeroAuctionTradeMessage }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.auctionId = one] : one \in Sample(8) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.longPrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.contracts = one] : one \in Sample(4) }

(***************************************************************************)
(* Retail Price Improvement Message: 13 bytes                              *)
(***************************************************************************)

RetailPriceImprovementMessage ==
    [ timeOffset             : Sample(4),
      expandedSymbol         : Sample(8),
      retailPriceImprovement : Sample(1) ]

EncodeRetailPriceImprovementMessage(message) ==
    message.timeOffset
        \o message.expandedSymbol
        \o message.retailPriceImprovement

DecodeRetailPriceImprovementMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET expandedSymbol == ReadBytes(timeOffset.rest, 8) IN IF ~expandedSymbol.ok THEN Fail ELSE
    LET retailPriceImprovement == ReadBytes(expandedSymbol.rest, 1) IN IF ~retailPriceImprovement.ok THEN Fail ELSE
    Ok([ timeOffset             |-> timeOffset.value,
         expandedSymbol         |-> expandedSymbol.value,
         retailPriceImprovement |-> retailPriceImprovement.value ], retailPriceImprovement.rest)

ZeroRetailPriceImprovementMessage ==
    [ timeOffset             |-> [i \in 1 .. 4 |-> 0],
      expandedSymbol         |-> [i \in 1 .. 8 |-> 0],
      retailPriceImprovement |-> [i \in 1 .. 1 |-> 0] ]

(* Retail Price Improvement Message at zero, then each field in turn at the values it is checked at *)
CheckedRetailPriceImprovementMessage ==
    { ZeroRetailPriceImprovementMessage }
        \cup { [ZeroRetailPriceImprovementMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroRetailPriceImprovementMessage EXCEPT !.expandedSymbol = one] : one \in Sample(8) }
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
EndOfSessionMessageCode == 45  \* 0x2d
SymbolMappingMessageCode == 46  \* 0x2e
TradingStatusMessageCode == 49  \* 0x31
AuctionUpdateMessageCode == 149  \* 0x95
AuctionSummaryMessageCode == 150  \* 0x96
AuctionNotificationMessageCode == 173  \* 0xad
AuctionCancelMessageCode == 174  \* 0xae
AuctionTradeMessageCode == 175  \* 0xaf
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
        \cup [ tag : {EndOfSessionMessageCode}, body : EndOfSessionMessage ]
        \cup [ tag : {SymbolMappingMessageCode}, body : SymbolMappingMessage ]
        \cup [ tag : {TradingStatusMessageCode}, body : TradingStatusMessage ]
        \cup [ tag : {AuctionUpdateMessageCode}, body : AuctionUpdateMessage ]
        \cup [ tag : {AuctionSummaryMessageCode}, body : AuctionSummaryMessage ]
        \cup [ tag : {AuctionNotificationMessageCode}, body : AuctionNotificationMessage ]
        \cup [ tag : {AuctionCancelMessageCode}, body : AuctionCancelMessage ]
        \cup [ tag : {AuctionTradeMessageCode}, body : AuctionTradeMessage ]
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
      [] message.tag = EndOfSessionMessageCode -> EncodeEndOfSessionMessage(message.body)
      [] message.tag = SymbolMappingMessageCode -> EncodeSymbolMappingMessage(message.body)
      [] message.tag = TradingStatusMessageCode -> EncodeTradingStatusMessage(message.body)
      [] message.tag = AuctionUpdateMessageCode -> EncodeAuctionUpdateMessage(message.body)
      [] message.tag = AuctionSummaryMessageCode -> EncodeAuctionSummaryMessage(message.body)
      [] message.tag = AuctionNotificationMessageCode -> EncodeAuctionNotificationMessage(message.body)
      [] message.tag = AuctionCancelMessageCode -> EncodeAuctionCancelMessage(message.body)
      [] message.tag = AuctionTradeMessageCode -> EncodeAuctionTradeMessage(message.body)
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
              [] tag = EndOfSessionMessageCode -> DecodeEndOfSessionMessage(bytes)
              [] tag = SymbolMappingMessageCode -> DecodeSymbolMappingMessage(bytes)
              [] tag = TradingStatusMessageCode -> DecodeTradingStatusMessage(bytes)
              [] tag = AuctionUpdateMessageCode -> DecodeAuctionUpdateMessage(bytes)
              [] tag = AuctionSummaryMessageCode -> DecodeAuctionSummaryMessage(bytes)
              [] tag = AuctionNotificationMessageCode -> DecodeAuctionNotificationMessage(bytes)
              [] tag = AuctionCancelMessageCode -> DecodeAuctionCancelMessage(bytes)
              [] tag = AuctionTradeMessageCode -> DecodeAuctionTradeMessage(bytes)
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
        \cup { [tag |-> EndOfSessionMessageCode, body |-> one] : one \in CheckedEndOfSessionMessage }
        \cup { [tag |-> SymbolMappingMessageCode, body |-> one] : one \in CheckedSymbolMappingMessage }
        \cup { [tag |-> TradingStatusMessageCode, body |-> one] : one \in CheckedTradingStatusMessage }
        \cup { [tag |-> AuctionUpdateMessageCode, body |-> one] : one \in CheckedAuctionUpdateMessage }
        \cup { [tag |-> AuctionSummaryMessageCode, body |-> one] : one \in CheckedAuctionSummaryMessage }
        \cup { [tag |-> AuctionNotificationMessageCode, body |-> one] : one \in CheckedAuctionNotificationMessage }
        \cup { [tag |-> AuctionCancelMessageCode, body |-> one] : one \in CheckedAuctionCancelMessage }
        \cup { [tag |-> AuctionTradeMessageCode, body |-> one] : one \in CheckedAuctionTradeMessage }
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
      [ZeroMessage EXCEPT !.payload = [tag |-> EndOfSessionMessageCode, body |-> ZeroEndOfSessionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SymbolMappingMessageCode, body |-> ZeroSymbolMappingMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradingStatusMessageCode, body |-> ZeroTradingStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionUpdateMessageCode, body |-> ZeroAuctionUpdateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionSummaryMessageCode, body |-> ZeroAuctionSummaryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionNotificationMessageCode, body |-> ZeroAuctionNotificationMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionCancelMessageCode, body |-> ZeroAuctionCancelMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionTradeMessageCode, body |-> ZeroAuctionTradeMessage]],
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

(* Every End Of Session Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfSessionMessage ==
    \A message \in CheckedEndOfSessionMessage :
        LET read == DecodeEndOfSessionMessage(EncodeEndOfSessionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol Mapping Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolMappingMessage ==
    \A message \in CheckedSymbolMappingMessage :
        LET read == DecodeSymbolMappingMessage(EncodeSymbolMappingMessage(message))
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

(* Every Auction Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionNotificationMessage ==
    \A message \in CheckedAuctionNotificationMessage :
        LET read == DecodeAuctionNotificationMessage(EncodeAuctionNotificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionCancelMessage ==
    \A message \in CheckedAuctionCancelMessage :
        LET read == DecodeAuctionCancelMessage(EncodeAuctionCancelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionTradeMessage ==
    \A message \in CheckedAuctionTradeMessage :
        LET read == DecodeAuctionTradeMessage(EncodeAuctionTradeMessage(message))
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
