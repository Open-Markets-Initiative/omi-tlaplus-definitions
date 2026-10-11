------------- MODULE BzxOptions_MulticastDepthOfBook_v2_41_64 --------------
(***************************************************************************)
(* Chicago Board Options Exchange Multicast Depth Of Book v2.41.64         *)
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
(* Ox Time Message: 4 bytes                                                *)
(***************************************************************************)

OxTimeMessage ==
    [ time : Sample(4) ]

EncodeOxTimeMessage(message) ==
    message.time

DecodeOxTimeMessage(bytes) ==
    LET time == ReadBytes(bytes, 4) IN IF ~time.ok THEN Fail ELSE
    Ok([ time |-> time.value ], time.rest)

ZeroOxTimeMessage ==
    [ time |-> [i \in 1 .. 4 |-> 0] ]

(* Ox Time Message at zero, then each field in turn at the values it is checked at *)
CheckedOxTimeMessage ==
    { ZeroOxTimeMessage }
        \cup { [ZeroOxTimeMessage EXCEPT !.time = one] : one \in Sample(4) }

(***************************************************************************)
(* Ox Unit Clear Message: 4 bytes                                          *)
(***************************************************************************)

OxUnitClearMessage ==
    [ timeOffset : Sample(4) ]

EncodeOxUnitClearMessage(message) ==
    message.timeOffset

DecodeOxUnitClearMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    Ok([ timeOffset |-> timeOffset.value ], timeOffset.rest)

ZeroOxUnitClearMessage ==
    [ timeOffset |-> [i \in 1 .. 4 |-> 0] ]

(* Ox Unit Clear Message at zero, then each field in turn at the values it is checked at *)
CheckedOxUnitClearMessage ==
    { ZeroOxUnitClearMessage }
        \cup { [ZeroOxUnitClearMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }

(***************************************************************************)
(* Ox Transaction Begin Message: 4 bytes                                   *)
(***************************************************************************)

OxTransactionBeginMessage ==
    [ timeOffset : Sample(4) ]

EncodeOxTransactionBeginMessage(message) ==
    message.timeOffset

DecodeOxTransactionBeginMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    Ok([ timeOffset |-> timeOffset.value ], timeOffset.rest)

ZeroOxTransactionBeginMessage ==
    [ timeOffset |-> [i \in 1 .. 4 |-> 0] ]

(* Ox Transaction Begin Message at zero, then each field in turn at the values it is checked at *)
CheckedOxTransactionBeginMessage ==
    { ZeroOxTransactionBeginMessage }
        \cup { [ZeroOxTransactionBeginMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }

(***************************************************************************)
(* Ox Transaction End Message: 4 bytes                                     *)
(***************************************************************************)

OxTransactionEndMessage ==
    [ timeOffset : Sample(4) ]

EncodeOxTransactionEndMessage(message) ==
    message.timeOffset

DecodeOxTransactionEndMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    Ok([ timeOffset |-> timeOffset.value ], timeOffset.rest)

ZeroOxTransactionEndMessage ==
    [ timeOffset |-> [i \in 1 .. 4 |-> 0] ]

(* Ox Transaction End Message at zero, then each field in turn at the values it is checked at *)
CheckedOxTransactionEndMessage ==
    { ZeroOxTransactionEndMessage }
        \cup { [ZeroOxTransactionEndMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }

(***************************************************************************)
(* Ox Add Order Long Message: 32 bytes                                     *)
(***************************************************************************)

OxAddOrderLongMessage ==
    [ timeOffset    : Sample(4),
      orderId       : Sample(8),
      sideIndicator : Sample(1),
      quantityLong  : Sample(4),
      symbol        : Sample(6),
      priceLong     : Sample(8),
      addFlags      : Sample(1) ]

EncodeOxAddOrderLongMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.quantityLong
        \o message.symbol
        \o message.priceLong
        \o message.addFlags

DecodeOxAddOrderLongMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET quantityLong == ReadBytes(sideIndicator.rest, 4) IN IF ~quantityLong.ok THEN Fail ELSE
    LET symbol == ReadBytes(quantityLong.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET priceLong == ReadBytes(symbol.rest, 8) IN IF ~priceLong.ok THEN Fail ELSE
    LET addFlags == ReadBytes(priceLong.rest, 1) IN IF ~addFlags.ok THEN Fail ELSE
    Ok([ timeOffset    |-> timeOffset.value,
         orderId       |-> orderId.value,
         sideIndicator |-> sideIndicator.value,
         quantityLong  |-> quantityLong.value,
         symbol        |-> symbol.value,
         priceLong     |-> priceLong.value,
         addFlags      |-> addFlags.value ], addFlags.rest)

ZeroOxAddOrderLongMessage ==
    [ timeOffset    |-> [i \in 1 .. 4 |-> 0],
      orderId       |-> [i \in 1 .. 8 |-> 0],
      sideIndicator |-> [i \in 1 .. 1 |-> 0],
      quantityLong  |-> [i \in 1 .. 4 |-> 0],
      symbol        |-> [i \in 1 .. 6 |-> 0],
      priceLong     |-> [i \in 1 .. 8 |-> 0],
      addFlags      |-> [i \in 1 .. 1 |-> 0] ]

(* Ox Add Order Long Message at zero, then each field in turn at the values it is checked at *)
CheckedOxAddOrderLongMessage ==
    { ZeroOxAddOrderLongMessage }
        \cup { [ZeroOxAddOrderLongMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroOxAddOrderLongMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOxAddOrderLongMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOxAddOrderLongMessage EXCEPT !.quantityLong = one] : one \in Sample(4) }
        \cup { [ZeroOxAddOrderLongMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroOxAddOrderLongMessage EXCEPT !.priceLong = one] : one \in Sample(8) }
        \cup { [ZeroOxAddOrderLongMessage EXCEPT !.addFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Ox Add Order Short Message: 24 bytes                                    *)
(***************************************************************************)

OxAddOrderShortMessage ==
    [ timeOffset    : Sample(4),
      orderId       : Sample(8),
      sideIndicator : Sample(1),
      quantityShort : Sample(2),
      symbol        : Sample(6),
      priceShort    : Sample(2),
      addFlags      : Sample(1) ]

EncodeOxAddOrderShortMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.quantityShort
        \o message.symbol
        \o message.priceShort
        \o message.addFlags

DecodeOxAddOrderShortMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET quantityShort == ReadBytes(sideIndicator.rest, 2) IN IF ~quantityShort.ok THEN Fail ELSE
    LET symbol == ReadBytes(quantityShort.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET priceShort == ReadBytes(symbol.rest, 2) IN IF ~priceShort.ok THEN Fail ELSE
    LET addFlags == ReadBytes(priceShort.rest, 1) IN IF ~addFlags.ok THEN Fail ELSE
    Ok([ timeOffset    |-> timeOffset.value,
         orderId       |-> orderId.value,
         sideIndicator |-> sideIndicator.value,
         quantityShort |-> quantityShort.value,
         symbol        |-> symbol.value,
         priceShort    |-> priceShort.value,
         addFlags      |-> addFlags.value ], addFlags.rest)

ZeroOxAddOrderShortMessage ==
    [ timeOffset    |-> [i \in 1 .. 4 |-> 0],
      orderId       |-> [i \in 1 .. 8 |-> 0],
      sideIndicator |-> [i \in 1 .. 1 |-> 0],
      quantityShort |-> [i \in 1 .. 2 |-> 0],
      symbol        |-> [i \in 1 .. 6 |-> 0],
      priceShort    |-> [i \in 1 .. 2 |-> 0],
      addFlags      |-> [i \in 1 .. 1 |-> 0] ]

(* Ox Add Order Short Message at zero, then each field in turn at the values it is checked at *)
CheckedOxAddOrderShortMessage ==
    { ZeroOxAddOrderShortMessage }
        \cup { [ZeroOxAddOrderShortMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroOxAddOrderShortMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOxAddOrderShortMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOxAddOrderShortMessage EXCEPT !.quantityShort = one] : one \in Sample(2) }
        \cup { [ZeroOxAddOrderShortMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroOxAddOrderShortMessage EXCEPT !.priceShort = one] : one \in Sample(2) }
        \cup { [ZeroOxAddOrderShortMessage EXCEPT !.addFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Ox Add Order Expanded Message: 48 bytes                                 *)
(***************************************************************************)

OxAddOrderExpandedMessage ==
    [ timeOffset        : Sample(4),
      orderId           : Sample(8),
      sideIndicator     : Sample(1),
      quantityLong      : Sample(4),
      expandedSymbol    : Sample(8),
      priceLong         : Sample(8),
      addFlags          : Sample(1),
      participantId     : Sample(4),
      customerIndicator : Sample(1),
      clientId          : Sample(4),
      reserved5         : Sample(5) ]

EncodeOxAddOrderExpandedMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.quantityLong
        \o message.expandedSymbol
        \o message.priceLong
        \o message.addFlags
        \o message.participantId
        \o message.customerIndicator
        \o message.clientId
        \o message.reserved5

DecodeOxAddOrderExpandedMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET quantityLong == ReadBytes(sideIndicator.rest, 4) IN IF ~quantityLong.ok THEN Fail ELSE
    LET expandedSymbol == ReadBytes(quantityLong.rest, 8) IN IF ~expandedSymbol.ok THEN Fail ELSE
    LET priceLong == ReadBytes(expandedSymbol.rest, 8) IN IF ~priceLong.ok THEN Fail ELSE
    LET addFlags == ReadBytes(priceLong.rest, 1) IN IF ~addFlags.ok THEN Fail ELSE
    LET participantId == ReadBytes(addFlags.rest, 4) IN IF ~participantId.ok THEN Fail ELSE
    LET customerIndicator == ReadBytes(participantId.rest, 1) IN IF ~customerIndicator.ok THEN Fail ELSE
    LET clientId == ReadBytes(customerIndicator.rest, 4) IN IF ~clientId.ok THEN Fail ELSE
    LET reserved5 == ReadBytes(clientId.rest, 5) IN IF ~reserved5.ok THEN Fail ELSE
    Ok([ timeOffset        |-> timeOffset.value,
         orderId           |-> orderId.value,
         sideIndicator     |-> sideIndicator.value,
         quantityLong      |-> quantityLong.value,
         expandedSymbol    |-> expandedSymbol.value,
         priceLong         |-> priceLong.value,
         addFlags          |-> addFlags.value,
         participantId     |-> participantId.value,
         customerIndicator |-> customerIndicator.value,
         clientId          |-> clientId.value,
         reserved5         |-> reserved5.value ], reserved5.rest)

ZeroOxAddOrderExpandedMessage ==
    [ timeOffset        |-> [i \in 1 .. 4 |-> 0],
      orderId           |-> [i \in 1 .. 8 |-> 0],
      sideIndicator     |-> [i \in 1 .. 1 |-> 0],
      quantityLong      |-> [i \in 1 .. 4 |-> 0],
      expandedSymbol    |-> [i \in 1 .. 8 |-> 0],
      priceLong         |-> [i \in 1 .. 8 |-> 0],
      addFlags          |-> [i \in 1 .. 1 |-> 0],
      participantId     |-> [i \in 1 .. 4 |-> 0],
      customerIndicator |-> [i \in 1 .. 1 |-> 0],
      clientId          |-> [i \in 1 .. 4 |-> 0],
      reserved5         |-> [i \in 1 .. 5 |-> 0] ]

(* Ox Add Order Expanded Message at zero, then each field in turn at the values it is checked at *)
CheckedOxAddOrderExpandedMessage ==
    { ZeroOxAddOrderExpandedMessage }
        \cup { [ZeroOxAddOrderExpandedMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroOxAddOrderExpandedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOxAddOrderExpandedMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOxAddOrderExpandedMessage EXCEPT !.quantityLong = one] : one \in Sample(4) }
        \cup { [ZeroOxAddOrderExpandedMessage EXCEPT !.expandedSymbol = one] : one \in Sample(8) }
        \cup { [ZeroOxAddOrderExpandedMessage EXCEPT !.priceLong = one] : one \in Sample(8) }
        \cup { [ZeroOxAddOrderExpandedMessage EXCEPT !.addFlags = one] : one \in Sample(1) }
        \cup { [ZeroOxAddOrderExpandedMessage EXCEPT !.participantId = one] : one \in Sample(4) }
        \cup { [ZeroOxAddOrderExpandedMessage EXCEPT !.customerIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOxAddOrderExpandedMessage EXCEPT !.clientId = one] : one \in Sample(4) }
        \cup { [ZeroOxAddOrderExpandedMessage EXCEPT !.reserved5 = one] : one \in Sample(5) }

(***************************************************************************)
(* Ox Order Executed Message: 25 bytes                                     *)
(***************************************************************************)

OxOrderExecutedMessage ==
    [ timeOffset       : Sample(4),
      orderId          : Sample(8),
      executedQuantity : Sample(4),
      executionId      : Sample(8),
      tradeCondition   : Sample(1) ]

EncodeOxOrderExecutedMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.executedQuantity
        \o message.executionId
        \o message.tradeCondition

DecodeOxOrderExecutedMessage(bytes) ==
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

ZeroOxOrderExecutedMessage ==
    [ timeOffset       |-> [i \in 1 .. 4 |-> 0],
      orderId          |-> [i \in 1 .. 8 |-> 0],
      executedQuantity |-> [i \in 1 .. 4 |-> 0],
      executionId      |-> [i \in 1 .. 8 |-> 0],
      tradeCondition   |-> [i \in 1 .. 1 |-> 0] ]

(* Ox Order Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedOxOrderExecutedMessage ==
    { ZeroOxOrderExecutedMessage }
        \cup { [ZeroOxOrderExecutedMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroOxOrderExecutedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOxOrderExecutedMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOxOrderExecutedMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroOxOrderExecutedMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Ox Order Executed At Price Size Message: 37 bytes                       *)
(***************************************************************************)

OxOrderExecutedAtPriceSizeMessage ==
    [ timeOffset        : Sample(4),
      orderId           : Sample(8),
      executedQuantity  : Sample(4),
      remainingQuantity : Sample(4),
      executionId       : Sample(8),
      priceLong         : Sample(8),
      tradeCondition    : Sample(1) ]

EncodeOxOrderExecutedAtPriceSizeMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.executedQuantity
        \o message.remainingQuantity
        \o message.executionId
        \o message.priceLong
        \o message.tradeCondition

DecodeOxOrderExecutedAtPriceSizeMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(orderId.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET remainingQuantity == ReadBytes(executedQuantity.rest, 4) IN IF ~remainingQuantity.ok THEN Fail ELSE
    LET executionId == ReadBytes(remainingQuantity.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET priceLong == ReadBytes(executionId.rest, 8) IN IF ~priceLong.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(priceLong.rest, 1) IN IF ~tradeCondition.ok THEN Fail ELSE
    Ok([ timeOffset        |-> timeOffset.value,
         orderId           |-> orderId.value,
         executedQuantity  |-> executedQuantity.value,
         remainingQuantity |-> remainingQuantity.value,
         executionId       |-> executionId.value,
         priceLong         |-> priceLong.value,
         tradeCondition    |-> tradeCondition.value ], tradeCondition.rest)

ZeroOxOrderExecutedAtPriceSizeMessage ==
    [ timeOffset        |-> [i \in 1 .. 4 |-> 0],
      orderId           |-> [i \in 1 .. 8 |-> 0],
      executedQuantity  |-> [i \in 1 .. 4 |-> 0],
      remainingQuantity |-> [i \in 1 .. 4 |-> 0],
      executionId       |-> [i \in 1 .. 8 |-> 0],
      priceLong         |-> [i \in 1 .. 8 |-> 0],
      tradeCondition    |-> [i \in 1 .. 1 |-> 0] ]

(* Ox Order Executed At Price Size Message at zero, then each field in turn at the values it is checked at *)
CheckedOxOrderExecutedAtPriceSizeMessage ==
    { ZeroOxOrderExecutedAtPriceSizeMessage }
        \cup { [ZeroOxOrderExecutedAtPriceSizeMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroOxOrderExecutedAtPriceSizeMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOxOrderExecutedAtPriceSizeMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOxOrderExecutedAtPriceSizeMessage EXCEPT !.remainingQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOxOrderExecutedAtPriceSizeMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroOxOrderExecutedAtPriceSizeMessage EXCEPT !.priceLong = one] : one \in Sample(8) }
        \cup { [ZeroOxOrderExecutedAtPriceSizeMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Ox Reduce Size Long Message: 16 bytes                                   *)
(***************************************************************************)

OxReduceSizeLongMessage ==
    [ timeOffset           : Sample(4),
      orderId              : Sample(8),
      canceledQuantityLong : Sample(4) ]

EncodeOxReduceSizeLongMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.canceledQuantityLong

DecodeOxReduceSizeLongMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET canceledQuantityLong == ReadBytes(orderId.rest, 4) IN IF ~canceledQuantityLong.ok THEN Fail ELSE
    Ok([ timeOffset           |-> timeOffset.value,
         orderId              |-> orderId.value,
         canceledQuantityLong |-> canceledQuantityLong.value ], canceledQuantityLong.rest)

ZeroOxReduceSizeLongMessage ==
    [ timeOffset           |-> [i \in 1 .. 4 |-> 0],
      orderId              |-> [i \in 1 .. 8 |-> 0],
      canceledQuantityLong |-> [i \in 1 .. 4 |-> 0] ]

(* Ox Reduce Size Long Message at zero, then each field in turn at the values it is checked at *)
CheckedOxReduceSizeLongMessage ==
    { ZeroOxReduceSizeLongMessage }
        \cup { [ZeroOxReduceSizeLongMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroOxReduceSizeLongMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOxReduceSizeLongMessage EXCEPT !.canceledQuantityLong = one] : one \in Sample(4) }

(***************************************************************************)
(* Ox Reduce Size Short Message: 14 bytes                                  *)
(***************************************************************************)

OxReduceSizeShortMessage ==
    [ timeOffset            : Sample(4),
      orderId               : Sample(8),
      canceledQuantityShort : Sample(2) ]

EncodeOxReduceSizeShortMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.canceledQuantityShort

DecodeOxReduceSizeShortMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET canceledQuantityShort == ReadBytes(orderId.rest, 2) IN IF ~canceledQuantityShort.ok THEN Fail ELSE
    Ok([ timeOffset            |-> timeOffset.value,
         orderId               |-> orderId.value,
         canceledQuantityShort |-> canceledQuantityShort.value ], canceledQuantityShort.rest)

ZeroOxReduceSizeShortMessage ==
    [ timeOffset            |-> [i \in 1 .. 4 |-> 0],
      orderId               |-> [i \in 1 .. 8 |-> 0],
      canceledQuantityShort |-> [i \in 1 .. 2 |-> 0] ]

(* Ox Reduce Size Short Message at zero, then each field in turn at the values it is checked at *)
CheckedOxReduceSizeShortMessage ==
    { ZeroOxReduceSizeShortMessage }
        \cup { [ZeroOxReduceSizeShortMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroOxReduceSizeShortMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOxReduceSizeShortMessage EXCEPT !.canceledQuantityShort = one] : one \in Sample(2) }

(***************************************************************************)
(* Ox Modify Order Long Message: 25 bytes                                  *)
(***************************************************************************)

OxModifyOrderLongMessage ==
    [ timeOffset   : Sample(4),
      orderId      : Sample(8),
      quantityLong : Sample(4),
      priceLong    : Sample(8),
      modifyFlags  : Sample(1) ]

EncodeOxModifyOrderLongMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.quantityLong
        \o message.priceLong
        \o message.modifyFlags

DecodeOxModifyOrderLongMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET quantityLong == ReadBytes(orderId.rest, 4) IN IF ~quantityLong.ok THEN Fail ELSE
    LET priceLong == ReadBytes(quantityLong.rest, 8) IN IF ~priceLong.ok THEN Fail ELSE
    LET modifyFlags == ReadBytes(priceLong.rest, 1) IN IF ~modifyFlags.ok THEN Fail ELSE
    Ok([ timeOffset   |-> timeOffset.value,
         orderId      |-> orderId.value,
         quantityLong |-> quantityLong.value,
         priceLong    |-> priceLong.value,
         modifyFlags  |-> modifyFlags.value ], modifyFlags.rest)

ZeroOxModifyOrderLongMessage ==
    [ timeOffset   |-> [i \in 1 .. 4 |-> 0],
      orderId      |-> [i \in 1 .. 8 |-> 0],
      quantityLong |-> [i \in 1 .. 4 |-> 0],
      priceLong    |-> [i \in 1 .. 8 |-> 0],
      modifyFlags  |-> [i \in 1 .. 1 |-> 0] ]

(* Ox Modify Order Long Message at zero, then each field in turn at the values it is checked at *)
CheckedOxModifyOrderLongMessage ==
    { ZeroOxModifyOrderLongMessage }
        \cup { [ZeroOxModifyOrderLongMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroOxModifyOrderLongMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOxModifyOrderLongMessage EXCEPT !.quantityLong = one] : one \in Sample(4) }
        \cup { [ZeroOxModifyOrderLongMessage EXCEPT !.priceLong = one] : one \in Sample(8) }
        \cup { [ZeroOxModifyOrderLongMessage EXCEPT !.modifyFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Ox Modify Order Short Message: 17 bytes                                 *)
(***************************************************************************)

OxModifyOrderShortMessage ==
    [ timeOffset    : Sample(4),
      orderId       : Sample(8),
      quantityShort : Sample(2),
      priceShort    : Sample(2),
      modifyFlags   : Sample(1) ]

EncodeOxModifyOrderShortMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.quantityShort
        \o message.priceShort
        \o message.modifyFlags

DecodeOxModifyOrderShortMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET quantityShort == ReadBytes(orderId.rest, 2) IN IF ~quantityShort.ok THEN Fail ELSE
    LET priceShort == ReadBytes(quantityShort.rest, 2) IN IF ~priceShort.ok THEN Fail ELSE
    LET modifyFlags == ReadBytes(priceShort.rest, 1) IN IF ~modifyFlags.ok THEN Fail ELSE
    Ok([ timeOffset    |-> timeOffset.value,
         orderId       |-> orderId.value,
         quantityShort |-> quantityShort.value,
         priceShort    |-> priceShort.value,
         modifyFlags   |-> modifyFlags.value ], modifyFlags.rest)

ZeroOxModifyOrderShortMessage ==
    [ timeOffset    |-> [i \in 1 .. 4 |-> 0],
      orderId       |-> [i \in 1 .. 8 |-> 0],
      quantityShort |-> [i \in 1 .. 2 |-> 0],
      priceShort    |-> [i \in 1 .. 2 |-> 0],
      modifyFlags   |-> [i \in 1 .. 1 |-> 0] ]

(* Ox Modify Order Short Message at zero, then each field in turn at the values it is checked at *)
CheckedOxModifyOrderShortMessage ==
    { ZeroOxModifyOrderShortMessage }
        \cup { [ZeroOxModifyOrderShortMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroOxModifyOrderShortMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOxModifyOrderShortMessage EXCEPT !.quantityShort = one] : one \in Sample(2) }
        \cup { [ZeroOxModifyOrderShortMessage EXCEPT !.priceShort = one] : one \in Sample(2) }
        \cup { [ZeroOxModifyOrderShortMessage EXCEPT !.modifyFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Ox Delete Order Message: 12 bytes                                       *)
(***************************************************************************)

OxDeleteOrderMessage ==
    [ timeOffset : Sample(4),
      orderId    : Sample(8) ]

EncodeOxDeleteOrderMessage(message) ==
    message.timeOffset
        \o message.orderId

DecodeOxDeleteOrderMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    Ok([ timeOffset |-> timeOffset.value,
         orderId    |-> orderId.value ], orderId.rest)

ZeroOxDeleteOrderMessage ==
    [ timeOffset |-> [i \in 1 .. 4 |-> 0],
      orderId    |-> [i \in 1 .. 8 |-> 0] ]

(* Ox Delete Order Message at zero, then each field in turn at the values it is checked at *)
CheckedOxDeleteOrderMessage ==
    { ZeroOxDeleteOrderMessage }
        \cup { [ZeroOxDeleteOrderMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroOxDeleteOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }

(***************************************************************************)
(* Ox Trade Long Message: 40 bytes                                         *)
(***************************************************************************)

OxTradeLongMessage ==
    [ timeOffset     : Sample(4),
      orderId        : Sample(8),
      sideIndicator  : Sample(1),
      quantityLong   : Sample(4),
      symbol         : Sample(6),
      priceLong      : Sample(8),
      executionId    : Sample(8),
      tradeCondition : Sample(1) ]

EncodeOxTradeLongMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.quantityLong
        \o message.symbol
        \o message.priceLong
        \o message.executionId
        \o message.tradeCondition

DecodeOxTradeLongMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET quantityLong == ReadBytes(sideIndicator.rest, 4) IN IF ~quantityLong.ok THEN Fail ELSE
    LET symbol == ReadBytes(quantityLong.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET priceLong == ReadBytes(symbol.rest, 8) IN IF ~priceLong.ok THEN Fail ELSE
    LET executionId == ReadBytes(priceLong.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(executionId.rest, 1) IN IF ~tradeCondition.ok THEN Fail ELSE
    Ok([ timeOffset     |-> timeOffset.value,
         orderId        |-> orderId.value,
         sideIndicator  |-> sideIndicator.value,
         quantityLong   |-> quantityLong.value,
         symbol         |-> symbol.value,
         priceLong      |-> priceLong.value,
         executionId    |-> executionId.value,
         tradeCondition |-> tradeCondition.value ], tradeCondition.rest)

ZeroOxTradeLongMessage ==
    [ timeOffset     |-> [i \in 1 .. 4 |-> 0],
      orderId        |-> [i \in 1 .. 8 |-> 0],
      sideIndicator  |-> [i \in 1 .. 1 |-> 0],
      quantityLong   |-> [i \in 1 .. 4 |-> 0],
      symbol         |-> [i \in 1 .. 6 |-> 0],
      priceLong      |-> [i \in 1 .. 8 |-> 0],
      executionId    |-> [i \in 1 .. 8 |-> 0],
      tradeCondition |-> [i \in 1 .. 1 |-> 0] ]

(* Ox Trade Long Message at zero, then each field in turn at the values it is checked at *)
CheckedOxTradeLongMessage ==
    { ZeroOxTradeLongMessage }
        \cup { [ZeroOxTradeLongMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroOxTradeLongMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOxTradeLongMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOxTradeLongMessage EXCEPT !.quantityLong = one] : one \in Sample(4) }
        \cup { [ZeroOxTradeLongMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroOxTradeLongMessage EXCEPT !.priceLong = one] : one \in Sample(8) }
        \cup { [ZeroOxTradeLongMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroOxTradeLongMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Ox Trade Short Message: 32 bytes                                        *)
(***************************************************************************)

OxTradeShortMessage ==
    [ timeOffset     : Sample(4),
      orderId        : Sample(8),
      sideIndicator  : Sample(1),
      quantityShort  : Sample(2),
      symbol         : Sample(6),
      priceShort     : Sample(2),
      executionId    : Sample(8),
      tradeCondition : Sample(1) ]

EncodeOxTradeShortMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.quantityShort
        \o message.symbol
        \o message.priceShort
        \o message.executionId
        \o message.tradeCondition

DecodeOxTradeShortMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET quantityShort == ReadBytes(sideIndicator.rest, 2) IN IF ~quantityShort.ok THEN Fail ELSE
    LET symbol == ReadBytes(quantityShort.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET priceShort == ReadBytes(symbol.rest, 2) IN IF ~priceShort.ok THEN Fail ELSE
    LET executionId == ReadBytes(priceShort.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(executionId.rest, 1) IN IF ~tradeCondition.ok THEN Fail ELSE
    Ok([ timeOffset     |-> timeOffset.value,
         orderId        |-> orderId.value,
         sideIndicator  |-> sideIndicator.value,
         quantityShort  |-> quantityShort.value,
         symbol         |-> symbol.value,
         priceShort     |-> priceShort.value,
         executionId    |-> executionId.value,
         tradeCondition |-> tradeCondition.value ], tradeCondition.rest)

ZeroOxTradeShortMessage ==
    [ timeOffset     |-> [i \in 1 .. 4 |-> 0],
      orderId        |-> [i \in 1 .. 8 |-> 0],
      sideIndicator  |-> [i \in 1 .. 1 |-> 0],
      quantityShort  |-> [i \in 1 .. 2 |-> 0],
      symbol         |-> [i \in 1 .. 6 |-> 0],
      priceShort     |-> [i \in 1 .. 2 |-> 0],
      executionId    |-> [i \in 1 .. 8 |-> 0],
      tradeCondition |-> [i \in 1 .. 1 |-> 0] ]

(* Ox Trade Short Message at zero, then each field in turn at the values it is checked at *)
CheckedOxTradeShortMessage ==
    { ZeroOxTradeShortMessage }
        \cup { [ZeroOxTradeShortMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroOxTradeShortMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOxTradeShortMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOxTradeShortMessage EXCEPT !.quantityShort = one] : one \in Sample(2) }
        \cup { [ZeroOxTradeShortMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroOxTradeShortMessage EXCEPT !.priceShort = one] : one \in Sample(2) }
        \cup { [ZeroOxTradeShortMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroOxTradeShortMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Ox Trade Expanded Message: 42 bytes                                     *)
(***************************************************************************)

OxTradeExpandedMessage ==
    [ timeOffset     : Sample(4),
      orderId        : Sample(8),
      sideIndicator  : Sample(1),
      quantityLong   : Sample(4),
      expandedSymbol : Sample(8),
      priceLong      : Sample(8),
      executionId    : Sample(8),
      tradeCondition : Sample(1) ]

EncodeOxTradeExpandedMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.quantityLong
        \o message.expandedSymbol
        \o message.priceLong
        \o message.executionId
        \o message.tradeCondition

DecodeOxTradeExpandedMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET quantityLong == ReadBytes(sideIndicator.rest, 4) IN IF ~quantityLong.ok THEN Fail ELSE
    LET expandedSymbol == ReadBytes(quantityLong.rest, 8) IN IF ~expandedSymbol.ok THEN Fail ELSE
    LET priceLong == ReadBytes(expandedSymbol.rest, 8) IN IF ~priceLong.ok THEN Fail ELSE
    LET executionId == ReadBytes(priceLong.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(executionId.rest, 1) IN IF ~tradeCondition.ok THEN Fail ELSE
    Ok([ timeOffset     |-> timeOffset.value,
         orderId        |-> orderId.value,
         sideIndicator  |-> sideIndicator.value,
         quantityLong   |-> quantityLong.value,
         expandedSymbol |-> expandedSymbol.value,
         priceLong      |-> priceLong.value,
         executionId    |-> executionId.value,
         tradeCondition |-> tradeCondition.value ], tradeCondition.rest)

ZeroOxTradeExpandedMessage ==
    [ timeOffset     |-> [i \in 1 .. 4 |-> 0],
      orderId        |-> [i \in 1 .. 8 |-> 0],
      sideIndicator  |-> [i \in 1 .. 1 |-> 0],
      quantityLong   |-> [i \in 1 .. 4 |-> 0],
      expandedSymbol |-> [i \in 1 .. 8 |-> 0],
      priceLong      |-> [i \in 1 .. 8 |-> 0],
      executionId    |-> [i \in 1 .. 8 |-> 0],
      tradeCondition |-> [i \in 1 .. 1 |-> 0] ]

(* Ox Trade Expanded Message at zero, then each field in turn at the values it is checked at *)
CheckedOxTradeExpandedMessage ==
    { ZeroOxTradeExpandedMessage }
        \cup { [ZeroOxTradeExpandedMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroOxTradeExpandedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOxTradeExpandedMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOxTradeExpandedMessage EXCEPT !.quantityLong = one] : one \in Sample(4) }
        \cup { [ZeroOxTradeExpandedMessage EXCEPT !.expandedSymbol = one] : one \in Sample(8) }
        \cup { [ZeroOxTradeExpandedMessage EXCEPT !.priceLong = one] : one \in Sample(8) }
        \cup { [ZeroOxTradeExpandedMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroOxTradeExpandedMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Ox Trade Break Message: 12 bytes                                        *)
(***************************************************************************)

OxTradeBreakMessage ==
    [ timeOffset  : Sample(4),
      executionId : Sample(8) ]

EncodeOxTradeBreakMessage(message) ==
    message.timeOffset
        \o message.executionId

DecodeOxTradeBreakMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET executionId == ReadBytes(timeOffset.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    Ok([ timeOffset  |-> timeOffset.value,
         executionId |-> executionId.value ], executionId.rest)

ZeroOxTradeBreakMessage ==
    [ timeOffset  |-> [i \in 1 .. 4 |-> 0],
      executionId |-> [i \in 1 .. 8 |-> 0] ]

(* Ox Trade Break Message at zero, then each field in turn at the values it is checked at *)
CheckedOxTradeBreakMessage ==
    { ZeroOxTradeBreakMessage }
        \cup { [ZeroOxTradeBreakMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroOxTradeBreakMessage EXCEPT !.executionId = one] : one \in Sample(8) }

(***************************************************************************)
(* Ox End Of Session: 4 bytes                                              *)
(***************************************************************************)

OxEndOfSession ==
    [ timestamp : Sample(4) ]

EncodeOxEndOfSession(message) ==
    message.timestamp

DecodeOxEndOfSession(bytes) ==
    LET timestamp == ReadBytes(bytes, 4) IN IF ~timestamp.ok THEN Fail ELSE
    Ok([ timestamp |-> timestamp.value ], timestamp.rest)

ZeroOxEndOfSession ==
    [ timestamp |-> [i \in 1 .. 4 |-> 0] ]

(* Ox End Of Session at zero, then each field in turn at the values it is checked at *)
CheckedOxEndOfSession ==
    { ZeroOxEndOfSession }
        \cup { [ZeroOxEndOfSession EXCEPT !.timestamp = one] : one \in Sample(4) }

(***************************************************************************)
(* Ox Symbol Mapping Message: 36 bytes                                     *)
(***************************************************************************)

OxSymbolMappingMessage ==
    [ feedSymbol      : Sample(6),
      osiSymbol       : Sample(21),
      symbolCondition : Sample(1),
      underlying      : Sample(8) ]

EncodeOxSymbolMappingMessage(message) ==
    message.feedSymbol
        \o message.osiSymbol
        \o message.symbolCondition
        \o message.underlying

DecodeOxSymbolMappingMessage(bytes) ==
    LET feedSymbol == ReadBytes(bytes, 6) IN IF ~feedSymbol.ok THEN Fail ELSE
    LET osiSymbol == ReadBytes(feedSymbol.rest, 21) IN IF ~osiSymbol.ok THEN Fail ELSE
    LET symbolCondition == ReadBytes(osiSymbol.rest, 1) IN IF ~symbolCondition.ok THEN Fail ELSE
    LET underlying == ReadBytes(symbolCondition.rest, 8) IN IF ~underlying.ok THEN Fail ELSE
    Ok([ feedSymbol      |-> feedSymbol.value,
         osiSymbol       |-> osiSymbol.value,
         symbolCondition |-> symbolCondition.value,
         underlying      |-> underlying.value ], underlying.rest)

ZeroOxSymbolMappingMessage ==
    [ feedSymbol      |-> [i \in 1 .. 6 |-> 0],
      osiSymbol       |-> [i \in 1 .. 21 |-> 0],
      symbolCondition |-> [i \in 1 .. 1 |-> 0],
      underlying      |-> [i \in 1 .. 8 |-> 0] ]

(* Ox Symbol Mapping Message at zero, then each field in turn at the values it is checked at *)
CheckedOxSymbolMappingMessage ==
    { ZeroOxSymbolMappingMessage }
        \cup { [ZeroOxSymbolMappingMessage EXCEPT !.feedSymbol = one] : one \in Sample(6) }
        \cup { [ZeroOxSymbolMappingMessage EXCEPT !.osiSymbol = one] : one \in Sample(21) }
        \cup { [ZeroOxSymbolMappingMessage EXCEPT !.symbolCondition = one] : one \in Sample(1) }
        \cup { [ZeroOxSymbolMappingMessage EXCEPT !.underlying = one] : one \in Sample(8) }

(***************************************************************************)
(* Ox Trading Status Message: 16 bytes                                     *)
(***************************************************************************)

OxTradingStatusMessage ==
    [ timeOffset       : Sample(4),
      symbol           : Sample(6),
      reserved2        : Sample(2),
      tradingStatus    : Sample(1),
      reserved1        : Sample(1),
      gthTradingStatus : Sample(1),
      secondReserved1  : Sample(1) ]

EncodeOxTradingStatusMessage(message) ==
    message.timeOffset
        \o message.symbol
        \o message.reserved2
        \o message.tradingStatus
        \o message.reserved1
        \o message.gthTradingStatus
        \o message.secondReserved1

DecodeOxTradingStatusMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET symbol == ReadBytes(timeOffset.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(symbol.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(reserved2.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(tradingStatus.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET gthTradingStatus == ReadBytes(reserved1.rest, 1) IN IF ~gthTradingStatus.ok THEN Fail ELSE
    LET secondReserved1 == ReadBytes(gthTradingStatus.rest, 1) IN IF ~secondReserved1.ok THEN Fail ELSE
    Ok([ timeOffset       |-> timeOffset.value,
         symbol           |-> symbol.value,
         reserved2        |-> reserved2.value,
         tradingStatus    |-> tradingStatus.value,
         reserved1        |-> reserved1.value,
         gthTradingStatus |-> gthTradingStatus.value,
         secondReserved1  |-> secondReserved1.value ], secondReserved1.rest)

ZeroOxTradingStatusMessage ==
    [ timeOffset       |-> [i \in 1 .. 4 |-> 0],
      symbol           |-> [i \in 1 .. 6 |-> 0],
      reserved2        |-> [i \in 1 .. 2 |-> 0],
      tradingStatus    |-> [i \in 1 .. 1 |-> 0],
      reserved1        |-> [i \in 1 .. 1 |-> 0],
      gthTradingStatus |-> [i \in 1 .. 1 |-> 0],
      secondReserved1  |-> [i \in 1 .. 1 |-> 0] ]

(* Ox Trading Status Message at zero, then each field in turn at the values it is checked at *)
CheckedOxTradingStatusMessage ==
    { ZeroOxTradingStatusMessage }
        \cup { [ZeroOxTradingStatusMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroOxTradingStatusMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroOxTradingStatusMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOxTradingStatusMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroOxTradingStatusMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOxTradingStatusMessage EXCEPT !.gthTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroOxTradingStatusMessage EXCEPT !.secondReserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Ox Width Update Message: 17 bytes                                       *)
(***************************************************************************)

OxWidthUpdateMessage ==
    [ timeOffset : Sample(4),
      underlying : Sample(8),
      widthType  : Sample(1),
      multiplier : Sample(4) ]

EncodeOxWidthUpdateMessage(message) ==
    message.timeOffset
        \o message.underlying
        \o message.widthType
        \o message.multiplier

DecodeOxWidthUpdateMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET underlying == ReadBytes(timeOffset.rest, 8) IN IF ~underlying.ok THEN Fail ELSE
    LET widthType == ReadBytes(underlying.rest, 1) IN IF ~widthType.ok THEN Fail ELSE
    LET multiplier == ReadBytes(widthType.rest, 4) IN IF ~multiplier.ok THEN Fail ELSE
    Ok([ timeOffset |-> timeOffset.value,
         underlying |-> underlying.value,
         widthType  |-> widthType.value,
         multiplier |-> multiplier.value ], multiplier.rest)

ZeroOxWidthUpdateMessage ==
    [ timeOffset |-> [i \in 1 .. 4 |-> 0],
      underlying |-> [i \in 1 .. 8 |-> 0],
      widthType  |-> [i \in 1 .. 1 |-> 0],
      multiplier |-> [i \in 1 .. 4 |-> 0] ]

(* Ox Width Update Message at zero, then each field in turn at the values it is checked at *)
CheckedOxWidthUpdateMessage ==
    { ZeroOxWidthUpdateMessage }
        \cup { [ZeroOxWidthUpdateMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroOxWidthUpdateMessage EXCEPT !.underlying = one] : one \in Sample(8) }
        \cup { [ZeroOxWidthUpdateMessage EXCEPT !.widthType = one] : one \in Sample(1) }
        \cup { [ZeroOxWidthUpdateMessage EXCEPT !.multiplier = one] : one \in Sample(4) }

(***************************************************************************)
(* Ox Options Auction Update Message: 62 bytes                             *)
(***************************************************************************)

OxOptionsAuctionUpdateMessage ==
    [ timeOffset                : Sample(4),
      expandedSymbol            : Sample(8),
      auctionType               : Sample(1),
      referencePrice            : Sample(8),
      buyContracts              : Sample(4),
      sellContracts             : Sample(4),
      indicativePrice           : Sample(8),
      auctionOnlyPrice          : Sample(8),
      openingCondition          : Sample(1),
      compositeMarketBidPrice   : Sample(8),
      compositeMarketOfferPrice : Sample(8) ]

EncodeOxOptionsAuctionUpdateMessage(message) ==
    message.timeOffset
        \o message.expandedSymbol
        \o message.auctionType
        \o message.referencePrice
        \o message.buyContracts
        \o message.sellContracts
        \o message.indicativePrice
        \o message.auctionOnlyPrice
        \o message.openingCondition
        \o message.compositeMarketBidPrice
        \o message.compositeMarketOfferPrice

DecodeOxOptionsAuctionUpdateMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET expandedSymbol == ReadBytes(timeOffset.rest, 8) IN IF ~expandedSymbol.ok THEN Fail ELSE
    LET auctionType == ReadBytes(expandedSymbol.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET referencePrice == ReadBytes(auctionType.rest, 8) IN IF ~referencePrice.ok THEN Fail ELSE
    LET buyContracts == ReadBytes(referencePrice.rest, 4) IN IF ~buyContracts.ok THEN Fail ELSE
    LET sellContracts == ReadBytes(buyContracts.rest, 4) IN IF ~sellContracts.ok THEN Fail ELSE
    LET indicativePrice == ReadBytes(sellContracts.rest, 8) IN IF ~indicativePrice.ok THEN Fail ELSE
    LET auctionOnlyPrice == ReadBytes(indicativePrice.rest, 8) IN IF ~auctionOnlyPrice.ok THEN Fail ELSE
    LET openingCondition == ReadBytes(auctionOnlyPrice.rest, 1) IN IF ~openingCondition.ok THEN Fail ELSE
    LET compositeMarketBidPrice == ReadBytes(openingCondition.rest, 8) IN IF ~compositeMarketBidPrice.ok THEN Fail ELSE
    LET compositeMarketOfferPrice == ReadBytes(compositeMarketBidPrice.rest, 8) IN IF ~compositeMarketOfferPrice.ok THEN Fail ELSE
    Ok([ timeOffset                |-> timeOffset.value,
         expandedSymbol            |-> expandedSymbol.value,
         auctionType               |-> auctionType.value,
         referencePrice            |-> referencePrice.value,
         buyContracts              |-> buyContracts.value,
         sellContracts             |-> sellContracts.value,
         indicativePrice           |-> indicativePrice.value,
         auctionOnlyPrice          |-> auctionOnlyPrice.value,
         openingCondition          |-> openingCondition.value,
         compositeMarketBidPrice   |-> compositeMarketBidPrice.value,
         compositeMarketOfferPrice |-> compositeMarketOfferPrice.value ], compositeMarketOfferPrice.rest)

ZeroOxOptionsAuctionUpdateMessage ==
    [ timeOffset                |-> [i \in 1 .. 4 |-> 0],
      expandedSymbol            |-> [i \in 1 .. 8 |-> 0],
      auctionType               |-> [i \in 1 .. 1 |-> 0],
      referencePrice            |-> [i \in 1 .. 8 |-> 0],
      buyContracts              |-> [i \in 1 .. 4 |-> 0],
      sellContracts             |-> [i \in 1 .. 4 |-> 0],
      indicativePrice           |-> [i \in 1 .. 8 |-> 0],
      auctionOnlyPrice          |-> [i \in 1 .. 8 |-> 0],
      openingCondition          |-> [i \in 1 .. 1 |-> 0],
      compositeMarketBidPrice   |-> [i \in 1 .. 8 |-> 0],
      compositeMarketOfferPrice |-> [i \in 1 .. 8 |-> 0] ]

(* Ox Options Auction Update Message at zero, then each field in turn at the values it is checked at *)
CheckedOxOptionsAuctionUpdateMessage ==
    { ZeroOxOptionsAuctionUpdateMessage }
        \cup { [ZeroOxOptionsAuctionUpdateMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroOxOptionsAuctionUpdateMessage EXCEPT !.expandedSymbol = one] : one \in Sample(8) }
        \cup { [ZeroOxOptionsAuctionUpdateMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroOxOptionsAuctionUpdateMessage EXCEPT !.referencePrice = one] : one \in Sample(8) }
        \cup { [ZeroOxOptionsAuctionUpdateMessage EXCEPT !.buyContracts = one] : one \in Sample(4) }
        \cup { [ZeroOxOptionsAuctionUpdateMessage EXCEPT !.sellContracts = one] : one \in Sample(4) }
        \cup { [ZeroOxOptionsAuctionUpdateMessage EXCEPT !.indicativePrice = one] : one \in Sample(8) }
        \cup { [ZeroOxOptionsAuctionUpdateMessage EXCEPT !.auctionOnlyPrice = one] : one \in Sample(8) }
        \cup { [ZeroOxOptionsAuctionUpdateMessage EXCEPT !.openingCondition = one] : one \in Sample(1) }
        \cup { [ZeroOxOptionsAuctionUpdateMessage EXCEPT !.compositeMarketBidPrice = one] : one \in Sample(8) }
        \cup { [ZeroOxOptionsAuctionUpdateMessage EXCEPT !.compositeMarketOfferPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Ox Auction Summary Message: 25 bytes                                    *)
(***************************************************************************)

OxAuctionSummaryMessage ==
    [ timeOffset      : Sample(4),
      stockSymbol     : Sample(8),
      auctionType     : Sample(1),
      priceLong       : Sample(8),
      sharesContracts : Sample(4) ]

EncodeOxAuctionSummaryMessage(message) ==
    message.timeOffset
        \o message.stockSymbol
        \o message.auctionType
        \o message.priceLong
        \o message.sharesContracts

DecodeOxAuctionSummaryMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET stockSymbol == ReadBytes(timeOffset.rest, 8) IN IF ~stockSymbol.ok THEN Fail ELSE
    LET auctionType == ReadBytes(stockSymbol.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET priceLong == ReadBytes(auctionType.rest, 8) IN IF ~priceLong.ok THEN Fail ELSE
    LET sharesContracts == ReadBytes(priceLong.rest, 4) IN IF ~sharesContracts.ok THEN Fail ELSE
    Ok([ timeOffset      |-> timeOffset.value,
         stockSymbol     |-> stockSymbol.value,
         auctionType     |-> auctionType.value,
         priceLong       |-> priceLong.value,
         sharesContracts |-> sharesContracts.value ], sharesContracts.rest)

ZeroOxAuctionSummaryMessage ==
    [ timeOffset      |-> [i \in 1 .. 4 |-> 0],
      stockSymbol     |-> [i \in 1 .. 8 |-> 0],
      auctionType     |-> [i \in 1 .. 1 |-> 0],
      priceLong       |-> [i \in 1 .. 8 |-> 0],
      sharesContracts |-> [i \in 1 .. 4 |-> 0] ]

(* Ox Auction Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedOxAuctionSummaryMessage ==
    { ZeroOxAuctionSummaryMessage }
        \cup { [ZeroOxAuctionSummaryMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroOxAuctionSummaryMessage EXCEPT !.stockSymbol = one] : one \in Sample(8) }
        \cup { [ZeroOxAuctionSummaryMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroOxAuctionSummaryMessage EXCEPT !.priceLong = one] : one \in Sample(8) }
        \cup { [ZeroOxAuctionSummaryMessage EXCEPT !.sharesContracts = one] : one \in Sample(4) }

(***************************************************************************)
(* Ox Auction Notification Message: 45 bytes                               *)
(***************************************************************************)

OxAuctionNotificationMessage ==
    [ timeOffset        : Sample(4),
      symbol            : Sample(6),
      auctionId         : Sample(8),
      auctionType       : Sample(1),
      side              : Sample(1),
      priceLong         : Sample(8),
      contracts         : Sample(4),
      customerIndicator : Sample(1),
      participantId     : Sample(4),
      auctionEndOffset  : Sample(4),
      clientId          : Sample(4) ]

EncodeOxAuctionNotificationMessage(message) ==
    message.timeOffset
        \o message.symbol
        \o message.auctionId
        \o message.auctionType
        \o message.side
        \o message.priceLong
        \o message.contracts
        \o message.customerIndicator
        \o message.participantId
        \o message.auctionEndOffset
        \o message.clientId

DecodeOxAuctionNotificationMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET symbol == ReadBytes(timeOffset.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET auctionId == ReadBytes(symbol.rest, 8) IN IF ~auctionId.ok THEN Fail ELSE
    LET auctionType == ReadBytes(auctionId.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET side == ReadBytes(auctionType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET priceLong == ReadBytes(side.rest, 8) IN IF ~priceLong.ok THEN Fail ELSE
    LET contracts == ReadBytes(priceLong.rest, 4) IN IF ~contracts.ok THEN Fail ELSE
    LET customerIndicator == ReadBytes(contracts.rest, 1) IN IF ~customerIndicator.ok THEN Fail ELSE
    LET participantId == ReadBytes(customerIndicator.rest, 4) IN IF ~participantId.ok THEN Fail ELSE
    LET auctionEndOffset == ReadBytes(participantId.rest, 4) IN IF ~auctionEndOffset.ok THEN Fail ELSE
    LET clientId == ReadBytes(auctionEndOffset.rest, 4) IN IF ~clientId.ok THEN Fail ELSE
    Ok([ timeOffset        |-> timeOffset.value,
         symbol            |-> symbol.value,
         auctionId         |-> auctionId.value,
         auctionType       |-> auctionType.value,
         side              |-> side.value,
         priceLong         |-> priceLong.value,
         contracts         |-> contracts.value,
         customerIndicator |-> customerIndicator.value,
         participantId     |-> participantId.value,
         auctionEndOffset  |-> auctionEndOffset.value,
         clientId          |-> clientId.value ], clientId.rest)

ZeroOxAuctionNotificationMessage ==
    [ timeOffset        |-> [i \in 1 .. 4 |-> 0],
      symbol            |-> [i \in 1 .. 6 |-> 0],
      auctionId         |-> [i \in 1 .. 8 |-> 0],
      auctionType       |-> [i \in 1 .. 1 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      priceLong         |-> [i \in 1 .. 8 |-> 0],
      contracts         |-> [i \in 1 .. 4 |-> 0],
      customerIndicator |-> [i \in 1 .. 1 |-> 0],
      participantId     |-> [i \in 1 .. 4 |-> 0],
      auctionEndOffset  |-> [i \in 1 .. 4 |-> 0],
      clientId          |-> [i \in 1 .. 4 |-> 0] ]

(* Ox Auction Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedOxAuctionNotificationMessage ==
    { ZeroOxAuctionNotificationMessage }
        \cup { [ZeroOxAuctionNotificationMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroOxAuctionNotificationMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroOxAuctionNotificationMessage EXCEPT !.auctionId = one] : one \in Sample(8) }
        \cup { [ZeroOxAuctionNotificationMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroOxAuctionNotificationMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOxAuctionNotificationMessage EXCEPT !.priceLong = one] : one \in Sample(8) }
        \cup { [ZeroOxAuctionNotificationMessage EXCEPT !.contracts = one] : one \in Sample(4) }
        \cup { [ZeroOxAuctionNotificationMessage EXCEPT !.customerIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOxAuctionNotificationMessage EXCEPT !.participantId = one] : one \in Sample(4) }
        \cup { [ZeroOxAuctionNotificationMessage EXCEPT !.auctionEndOffset = one] : one \in Sample(4) }
        \cup { [ZeroOxAuctionNotificationMessage EXCEPT !.clientId = one] : one \in Sample(4) }

(***************************************************************************)
(* Ox Auction Cancel Message: 12 bytes                                     *)
(***************************************************************************)

OxAuctionCancelMessage ==
    [ timeOffset : Sample(4),
      auctionId  : Sample(8) ]

EncodeOxAuctionCancelMessage(message) ==
    message.timeOffset
        \o message.auctionId

DecodeOxAuctionCancelMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET auctionId == ReadBytes(timeOffset.rest, 8) IN IF ~auctionId.ok THEN Fail ELSE
    Ok([ timeOffset |-> timeOffset.value,
         auctionId  |-> auctionId.value ], auctionId.rest)

ZeroOxAuctionCancelMessage ==
    [ timeOffset |-> [i \in 1 .. 4 |-> 0],
      auctionId  |-> [i \in 1 .. 8 |-> 0] ]

(* Ox Auction Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedOxAuctionCancelMessage ==
    { ZeroOxAuctionCancelMessage }
        \cup { [ZeroOxAuctionCancelMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroOxAuctionCancelMessage EXCEPT !.auctionId = one] : one \in Sample(8) }

(***************************************************************************)
(* Ox Auction Trade Message: 32 bytes                                      *)
(***************************************************************************)

OxAuctionTradeMessage ==
    [ timeOffset  : Sample(4),
      auctionId   : Sample(8),
      executionId : Sample(8),
      priceLong   : Sample(8),
      contracts   : Sample(4) ]

EncodeOxAuctionTradeMessage(message) ==
    message.timeOffset
        \o message.auctionId
        \o message.executionId
        \o message.priceLong
        \o message.contracts

DecodeOxAuctionTradeMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET auctionId == ReadBytes(timeOffset.rest, 8) IN IF ~auctionId.ok THEN Fail ELSE
    LET executionId == ReadBytes(auctionId.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET priceLong == ReadBytes(executionId.rest, 8) IN IF ~priceLong.ok THEN Fail ELSE
    LET contracts == ReadBytes(priceLong.rest, 4) IN IF ~contracts.ok THEN Fail ELSE
    Ok([ timeOffset  |-> timeOffset.value,
         auctionId   |-> auctionId.value,
         executionId |-> executionId.value,
         priceLong   |-> priceLong.value,
         contracts   |-> contracts.value ], contracts.rest)

ZeroOxAuctionTradeMessage ==
    [ timeOffset  |-> [i \in 1 .. 4 |-> 0],
      auctionId   |-> [i \in 1 .. 8 |-> 0],
      executionId |-> [i \in 1 .. 8 |-> 0],
      priceLong   |-> [i \in 1 .. 8 |-> 0],
      contracts   |-> [i \in 1 .. 4 |-> 0] ]

(* Ox Auction Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedOxAuctionTradeMessage ==
    { ZeroOxAuctionTradeMessage }
        \cup { [ZeroOxAuctionTradeMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroOxAuctionTradeMessage EXCEPT !.auctionId = one] : one \in Sample(8) }
        \cup { [ZeroOxAuctionTradeMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroOxAuctionTradeMessage EXCEPT !.priceLong = one] : one \in Sample(8) }
        \cup { [ZeroOxAuctionTradeMessage EXCEPT !.contracts = one] : one \in Sample(4) }

(***************************************************************************)
(* Ox Soq Strike Range Update Message: 40 bytes                            *)
(***************************************************************************)

OxSoqStrikeRangeUpdateMessage ==
    [ timeOffset       : Sample(4),
      soqIdentifier    : Sample(20),
      lowerStrikePrice : Sample(8),
      upperStrikePrice : Sample(8) ]

EncodeOxSoqStrikeRangeUpdateMessage(message) ==
    message.timeOffset
        \o message.soqIdentifier
        \o message.lowerStrikePrice
        \o message.upperStrikePrice

DecodeOxSoqStrikeRangeUpdateMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET soqIdentifier == ReadBytes(timeOffset.rest, 20) IN IF ~soqIdentifier.ok THEN Fail ELSE
    LET lowerStrikePrice == ReadBytes(soqIdentifier.rest, 8) IN IF ~lowerStrikePrice.ok THEN Fail ELSE
    LET upperStrikePrice == ReadBytes(lowerStrikePrice.rest, 8) IN IF ~upperStrikePrice.ok THEN Fail ELSE
    Ok([ timeOffset       |-> timeOffset.value,
         soqIdentifier    |-> soqIdentifier.value,
         lowerStrikePrice |-> lowerStrikePrice.value,
         upperStrikePrice |-> upperStrikePrice.value ], upperStrikePrice.rest)

ZeroOxSoqStrikeRangeUpdateMessage ==
    [ timeOffset       |-> [i \in 1 .. 4 |-> 0],
      soqIdentifier    |-> [i \in 1 .. 20 |-> 0],
      lowerStrikePrice |-> [i \in 1 .. 8 |-> 0],
      upperStrikePrice |-> [i \in 1 .. 8 |-> 0] ]

(* Ox Soq Strike Range Update Message at zero, then each field in turn at the values it is checked at *)
CheckedOxSoqStrikeRangeUpdateMessage ==
    { ZeroOxSoqStrikeRangeUpdateMessage }
        \cup { [ZeroOxSoqStrikeRangeUpdateMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroOxSoqStrikeRangeUpdateMessage EXCEPT !.soqIdentifier = one] : one \in Sample(20) }
        \cup { [ZeroOxSoqStrikeRangeUpdateMessage EXCEPT !.lowerStrikePrice = one] : one \in Sample(8) }
        \cup { [ZeroOxSoqStrikeRangeUpdateMessage EXCEPT !.upperStrikePrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Ox Constituent Symbol Mapping Message: 56 bytes                         *)
(***************************************************************************)

OxConstituentSymbolMappingMessage ==
    [ feedSymbol      : Sample(6),
      osiSymbol       : Sample(21),
      symbolCondition : Sample(1),
      underlying      : Sample(8),
      soqIdentifier   : Sample(20) ]

EncodeOxConstituentSymbolMappingMessage(message) ==
    message.feedSymbol
        \o message.osiSymbol
        \o message.symbolCondition
        \o message.underlying
        \o message.soqIdentifier

DecodeOxConstituentSymbolMappingMessage(bytes) ==
    LET feedSymbol == ReadBytes(bytes, 6) IN IF ~feedSymbol.ok THEN Fail ELSE
    LET osiSymbol == ReadBytes(feedSymbol.rest, 21) IN IF ~osiSymbol.ok THEN Fail ELSE
    LET symbolCondition == ReadBytes(osiSymbol.rest, 1) IN IF ~symbolCondition.ok THEN Fail ELSE
    LET underlying == ReadBytes(symbolCondition.rest, 8) IN IF ~underlying.ok THEN Fail ELSE
    LET soqIdentifier == ReadBytes(underlying.rest, 20) IN IF ~soqIdentifier.ok THEN Fail ELSE
    Ok([ feedSymbol      |-> feedSymbol.value,
         osiSymbol       |-> osiSymbol.value,
         symbolCondition |-> symbolCondition.value,
         underlying      |-> underlying.value,
         soqIdentifier   |-> soqIdentifier.value ], soqIdentifier.rest)

ZeroOxConstituentSymbolMappingMessage ==
    [ feedSymbol      |-> [i \in 1 .. 6 |-> 0],
      osiSymbol       |-> [i \in 1 .. 21 |-> 0],
      symbolCondition |-> [i \in 1 .. 1 |-> 0],
      underlying      |-> [i \in 1 .. 8 |-> 0],
      soqIdentifier   |-> [i \in 1 .. 20 |-> 0] ]

(* Ox Constituent Symbol Mapping Message at zero, then each field in turn at the values it is checked at *)
CheckedOxConstituentSymbolMappingMessage ==
    { ZeroOxConstituentSymbolMappingMessage }
        \cup { [ZeroOxConstituentSymbolMappingMessage EXCEPT !.feedSymbol = one] : one \in Sample(6) }
        \cup { [ZeroOxConstituentSymbolMappingMessage EXCEPT !.osiSymbol = one] : one \in Sample(21) }
        \cup { [ZeroOxConstituentSymbolMappingMessage EXCEPT !.symbolCondition = one] : one \in Sample(1) }
        \cup { [ZeroOxConstituentSymbolMappingMessage EXCEPT !.underlying = one] : one \in Sample(8) }
        \cup { [ZeroOxConstituentSymbolMappingMessage EXCEPT !.soqIdentifier = one] : one \in Sample(20) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

OxTimeMessageCode == 32  \* 0x20
OxUnitClearMessageCode == 151  \* 0x97
OxTransactionBeginMessageCode == 188  \* 0xbc
OxTransactionEndMessageCode == 189  \* 0xbd
OxAddOrderLongMessageCode == 33  \* 0x21
OxAddOrderShortMessageCode == 34  \* 0x22
OxAddOrderExpandedMessageCode == 47  \* 0x2f
OxOrderExecutedMessageCode == 35  \* 0x23
OxOrderExecutedAtPriceSizeMessageCode == 36  \* 0x24
OxReduceSizeLongMessageCode == 37  \* 0x25
OxReduceSizeShortMessageCode == 38  \* 0x26
OxModifyOrderLongMessageCode == 39  \* 0x27
OxModifyOrderShortMessageCode == 40  \* 0x28
OxDeleteOrderMessageCode == 41  \* 0x29
OxTradeLongMessageCode == 42  \* 0x2a
OxTradeShortMessageCode == 43  \* 0x2b
OxTradeExpandedMessageCode == 48  \* 0x30
OxTradeBreakMessageCode == 44  \* 0x2c
OxEndOfSessionCode == 45  \* 0x2d
OxSymbolMappingMessageCode == 46  \* 0x2e
OxTradingStatusMessageCode == 49  \* 0x31
OxWidthUpdateMessageCode == 210  \* 0xd2
OxOptionsAuctionUpdateMessageCode == 209  \* 0xd1
OxAuctionSummaryMessageCode == 150  \* 0x96
OxAuctionNotificationMessageCode == 173  \* 0xad
OxAuctionCancelMessageCode == 174  \* 0xae
OxAuctionTradeMessageCode == 175  \* 0xaf
OxSoqStrikeRangeUpdateMessageCode == 157  \* 0x9d
OxConstituentSymbolMappingMessageCode == 158  \* 0x9e

Payload ==
    [ tag : {OxTimeMessageCode}, body : OxTimeMessage ]
        \cup [ tag : {OxUnitClearMessageCode}, body : OxUnitClearMessage ]
        \cup [ tag : {OxTransactionBeginMessageCode}, body : OxTransactionBeginMessage ]
        \cup [ tag : {OxTransactionEndMessageCode}, body : OxTransactionEndMessage ]
        \cup [ tag : {OxAddOrderLongMessageCode}, body : OxAddOrderLongMessage ]
        \cup [ tag : {OxAddOrderShortMessageCode}, body : OxAddOrderShortMessage ]
        \cup [ tag : {OxAddOrderExpandedMessageCode}, body : OxAddOrderExpandedMessage ]
        \cup [ tag : {OxOrderExecutedMessageCode}, body : OxOrderExecutedMessage ]
        \cup [ tag : {OxOrderExecutedAtPriceSizeMessageCode}, body : OxOrderExecutedAtPriceSizeMessage ]
        \cup [ tag : {OxReduceSizeLongMessageCode}, body : OxReduceSizeLongMessage ]
        \cup [ tag : {OxReduceSizeShortMessageCode}, body : OxReduceSizeShortMessage ]
        \cup [ tag : {OxModifyOrderLongMessageCode}, body : OxModifyOrderLongMessage ]
        \cup [ tag : {OxModifyOrderShortMessageCode}, body : OxModifyOrderShortMessage ]
        \cup [ tag : {OxDeleteOrderMessageCode}, body : OxDeleteOrderMessage ]
        \cup [ tag : {OxTradeLongMessageCode}, body : OxTradeLongMessage ]
        \cup [ tag : {OxTradeShortMessageCode}, body : OxTradeShortMessage ]
        \cup [ tag : {OxTradeExpandedMessageCode}, body : OxTradeExpandedMessage ]
        \cup [ tag : {OxTradeBreakMessageCode}, body : OxTradeBreakMessage ]
        \cup [ tag : {OxEndOfSessionCode}, body : OxEndOfSession ]
        \cup [ tag : {OxSymbolMappingMessageCode}, body : OxSymbolMappingMessage ]
        \cup [ tag : {OxTradingStatusMessageCode}, body : OxTradingStatusMessage ]
        \cup [ tag : {OxWidthUpdateMessageCode}, body : OxWidthUpdateMessage ]
        \cup [ tag : {OxOptionsAuctionUpdateMessageCode}, body : OxOptionsAuctionUpdateMessage ]
        \cup [ tag : {OxAuctionSummaryMessageCode}, body : OxAuctionSummaryMessage ]
        \cup [ tag : {OxAuctionNotificationMessageCode}, body : OxAuctionNotificationMessage ]
        \cup [ tag : {OxAuctionCancelMessageCode}, body : OxAuctionCancelMessage ]
        \cup [ tag : {OxAuctionTradeMessageCode}, body : OxAuctionTradeMessage ]
        \cup [ tag : {OxSoqStrikeRangeUpdateMessageCode}, body : OxSoqStrikeRangeUpdateMessage ]
        \cup [ tag : {OxConstituentSymbolMappingMessageCode}, body : OxConstituentSymbolMappingMessage ]

EncodePayload(message) ==
    CASE message.tag = OxTimeMessageCode -> EncodeOxTimeMessage(message.body)
      [] message.tag = OxUnitClearMessageCode -> EncodeOxUnitClearMessage(message.body)
      [] message.tag = OxTransactionBeginMessageCode -> EncodeOxTransactionBeginMessage(message.body)
      [] message.tag = OxTransactionEndMessageCode -> EncodeOxTransactionEndMessage(message.body)
      [] message.tag = OxAddOrderLongMessageCode -> EncodeOxAddOrderLongMessage(message.body)
      [] message.tag = OxAddOrderShortMessageCode -> EncodeOxAddOrderShortMessage(message.body)
      [] message.tag = OxAddOrderExpandedMessageCode -> EncodeOxAddOrderExpandedMessage(message.body)
      [] message.tag = OxOrderExecutedMessageCode -> EncodeOxOrderExecutedMessage(message.body)
      [] message.tag = OxOrderExecutedAtPriceSizeMessageCode -> EncodeOxOrderExecutedAtPriceSizeMessage(message.body)
      [] message.tag = OxReduceSizeLongMessageCode -> EncodeOxReduceSizeLongMessage(message.body)
      [] message.tag = OxReduceSizeShortMessageCode -> EncodeOxReduceSizeShortMessage(message.body)
      [] message.tag = OxModifyOrderLongMessageCode -> EncodeOxModifyOrderLongMessage(message.body)
      [] message.tag = OxModifyOrderShortMessageCode -> EncodeOxModifyOrderShortMessage(message.body)
      [] message.tag = OxDeleteOrderMessageCode -> EncodeOxDeleteOrderMessage(message.body)
      [] message.tag = OxTradeLongMessageCode -> EncodeOxTradeLongMessage(message.body)
      [] message.tag = OxTradeShortMessageCode -> EncodeOxTradeShortMessage(message.body)
      [] message.tag = OxTradeExpandedMessageCode -> EncodeOxTradeExpandedMessage(message.body)
      [] message.tag = OxTradeBreakMessageCode -> EncodeOxTradeBreakMessage(message.body)
      [] message.tag = OxEndOfSessionCode -> EncodeOxEndOfSession(message.body)
      [] message.tag = OxSymbolMappingMessageCode -> EncodeOxSymbolMappingMessage(message.body)
      [] message.tag = OxTradingStatusMessageCode -> EncodeOxTradingStatusMessage(message.body)
      [] message.tag = OxWidthUpdateMessageCode -> EncodeOxWidthUpdateMessage(message.body)
      [] message.tag = OxOptionsAuctionUpdateMessageCode -> EncodeOxOptionsAuctionUpdateMessage(message.body)
      [] message.tag = OxAuctionSummaryMessageCode -> EncodeOxAuctionSummaryMessage(message.body)
      [] message.tag = OxAuctionNotificationMessageCode -> EncodeOxAuctionNotificationMessage(message.body)
      [] message.tag = OxAuctionCancelMessageCode -> EncodeOxAuctionCancelMessage(message.body)
      [] message.tag = OxAuctionTradeMessageCode -> EncodeOxAuctionTradeMessage(message.body)
      [] message.tag = OxSoqStrikeRangeUpdateMessageCode -> EncodeOxSoqStrikeRangeUpdateMessage(message.body)
      [] message.tag = OxConstituentSymbolMappingMessageCode -> EncodeOxConstituentSymbolMappingMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = OxTimeMessageCode -> DecodeOxTimeMessage(bytes)
              [] tag = OxUnitClearMessageCode -> DecodeOxUnitClearMessage(bytes)
              [] tag = OxTransactionBeginMessageCode -> DecodeOxTransactionBeginMessage(bytes)
              [] tag = OxTransactionEndMessageCode -> DecodeOxTransactionEndMessage(bytes)
              [] tag = OxAddOrderLongMessageCode -> DecodeOxAddOrderLongMessage(bytes)
              [] tag = OxAddOrderShortMessageCode -> DecodeOxAddOrderShortMessage(bytes)
              [] tag = OxAddOrderExpandedMessageCode -> DecodeOxAddOrderExpandedMessage(bytes)
              [] tag = OxOrderExecutedMessageCode -> DecodeOxOrderExecutedMessage(bytes)
              [] tag = OxOrderExecutedAtPriceSizeMessageCode -> DecodeOxOrderExecutedAtPriceSizeMessage(bytes)
              [] tag = OxReduceSizeLongMessageCode -> DecodeOxReduceSizeLongMessage(bytes)
              [] tag = OxReduceSizeShortMessageCode -> DecodeOxReduceSizeShortMessage(bytes)
              [] tag = OxModifyOrderLongMessageCode -> DecodeOxModifyOrderLongMessage(bytes)
              [] tag = OxModifyOrderShortMessageCode -> DecodeOxModifyOrderShortMessage(bytes)
              [] tag = OxDeleteOrderMessageCode -> DecodeOxDeleteOrderMessage(bytes)
              [] tag = OxTradeLongMessageCode -> DecodeOxTradeLongMessage(bytes)
              [] tag = OxTradeShortMessageCode -> DecodeOxTradeShortMessage(bytes)
              [] tag = OxTradeExpandedMessageCode -> DecodeOxTradeExpandedMessage(bytes)
              [] tag = OxTradeBreakMessageCode -> DecodeOxTradeBreakMessage(bytes)
              [] tag = OxEndOfSessionCode -> DecodeOxEndOfSession(bytes)
              [] tag = OxSymbolMappingMessageCode -> DecodeOxSymbolMappingMessage(bytes)
              [] tag = OxTradingStatusMessageCode -> DecodeOxTradingStatusMessage(bytes)
              [] tag = OxWidthUpdateMessageCode -> DecodeOxWidthUpdateMessage(bytes)
              [] tag = OxOptionsAuctionUpdateMessageCode -> DecodeOxOptionsAuctionUpdateMessage(bytes)
              [] tag = OxAuctionSummaryMessageCode -> DecodeOxAuctionSummaryMessage(bytes)
              [] tag = OxAuctionNotificationMessageCode -> DecodeOxAuctionNotificationMessage(bytes)
              [] tag = OxAuctionCancelMessageCode -> DecodeOxAuctionCancelMessage(bytes)
              [] tag = OxAuctionTradeMessageCode -> DecodeOxAuctionTradeMessage(bytes)
              [] tag = OxSoqStrikeRangeUpdateMessageCode -> DecodeOxSoqStrikeRangeUpdateMessage(bytes)
              [] tag = OxConstituentSymbolMappingMessageCode -> DecodeOxConstituentSymbolMappingMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> OxTimeMessageCode, body |-> ZeroOxTimeMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> OxTimeMessageCode, body |-> one] : one \in CheckedOxTimeMessage }
        \cup { [tag |-> OxUnitClearMessageCode, body |-> one] : one \in CheckedOxUnitClearMessage }
        \cup { [tag |-> OxTransactionBeginMessageCode, body |-> one] : one \in CheckedOxTransactionBeginMessage }
        \cup { [tag |-> OxTransactionEndMessageCode, body |-> one] : one \in CheckedOxTransactionEndMessage }
        \cup { [tag |-> OxAddOrderLongMessageCode, body |-> one] : one \in CheckedOxAddOrderLongMessage }
        \cup { [tag |-> OxAddOrderShortMessageCode, body |-> one] : one \in CheckedOxAddOrderShortMessage }
        \cup { [tag |-> OxAddOrderExpandedMessageCode, body |-> one] : one \in CheckedOxAddOrderExpandedMessage }
        \cup { [tag |-> OxOrderExecutedMessageCode, body |-> one] : one \in CheckedOxOrderExecutedMessage }
        \cup { [tag |-> OxOrderExecutedAtPriceSizeMessageCode, body |-> one] : one \in CheckedOxOrderExecutedAtPriceSizeMessage }
        \cup { [tag |-> OxReduceSizeLongMessageCode, body |-> one] : one \in CheckedOxReduceSizeLongMessage }
        \cup { [tag |-> OxReduceSizeShortMessageCode, body |-> one] : one \in CheckedOxReduceSizeShortMessage }
        \cup { [tag |-> OxModifyOrderLongMessageCode, body |-> one] : one \in CheckedOxModifyOrderLongMessage }
        \cup { [tag |-> OxModifyOrderShortMessageCode, body |-> one] : one \in CheckedOxModifyOrderShortMessage }
        \cup { [tag |-> OxDeleteOrderMessageCode, body |-> one] : one \in CheckedOxDeleteOrderMessage }
        \cup { [tag |-> OxTradeLongMessageCode, body |-> one] : one \in CheckedOxTradeLongMessage }
        \cup { [tag |-> OxTradeShortMessageCode, body |-> one] : one \in CheckedOxTradeShortMessage }
        \cup { [tag |-> OxTradeExpandedMessageCode, body |-> one] : one \in CheckedOxTradeExpandedMessage }
        \cup { [tag |-> OxTradeBreakMessageCode, body |-> one] : one \in CheckedOxTradeBreakMessage }
        \cup { [tag |-> OxEndOfSessionCode, body |-> one] : one \in CheckedOxEndOfSession }
        \cup { [tag |-> OxSymbolMappingMessageCode, body |-> one] : one \in CheckedOxSymbolMappingMessage }
        \cup { [tag |-> OxTradingStatusMessageCode, body |-> one] : one \in CheckedOxTradingStatusMessage }
        \cup { [tag |-> OxWidthUpdateMessageCode, body |-> one] : one \in CheckedOxWidthUpdateMessage }
        \cup { [tag |-> OxOptionsAuctionUpdateMessageCode, body |-> one] : one \in CheckedOxOptionsAuctionUpdateMessage }
        \cup { [tag |-> OxAuctionSummaryMessageCode, body |-> one] : one \in CheckedOxAuctionSummaryMessage }
        \cup { [tag |-> OxAuctionNotificationMessageCode, body |-> one] : one \in CheckedOxAuctionNotificationMessage }
        \cup { [tag |-> OxAuctionCancelMessageCode, body |-> one] : one \in CheckedOxAuctionCancelMessage }
        \cup { [tag |-> OxAuctionTradeMessageCode, body |-> one] : one \in CheckedOxAuctionTradeMessage }
        \cup { [tag |-> OxSoqStrikeRangeUpdateMessageCode, body |-> one] : one \in CheckedOxSoqStrikeRangeUpdateMessage }
        \cup { [tag |-> OxConstituentSymbolMappingMessageCode, body |-> one] : one \in CheckedOxConstituentSymbolMappingMessage }

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
    { [ZeroMessage EXCEPT !.payload = [tag |-> OxTimeMessageCode, body |-> ZeroOxTimeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OxUnitClearMessageCode, body |-> ZeroOxUnitClearMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OxTransactionBeginMessageCode, body |-> ZeroOxTransactionBeginMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OxTransactionEndMessageCode, body |-> ZeroOxTransactionEndMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OxAddOrderLongMessageCode, body |-> ZeroOxAddOrderLongMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OxAddOrderShortMessageCode, body |-> ZeroOxAddOrderShortMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OxAddOrderExpandedMessageCode, body |-> ZeroOxAddOrderExpandedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OxOrderExecutedMessageCode, body |-> ZeroOxOrderExecutedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OxOrderExecutedAtPriceSizeMessageCode, body |-> ZeroOxOrderExecutedAtPriceSizeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OxReduceSizeLongMessageCode, body |-> ZeroOxReduceSizeLongMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OxReduceSizeShortMessageCode, body |-> ZeroOxReduceSizeShortMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OxModifyOrderLongMessageCode, body |-> ZeroOxModifyOrderLongMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OxModifyOrderShortMessageCode, body |-> ZeroOxModifyOrderShortMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OxDeleteOrderMessageCode, body |-> ZeroOxDeleteOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OxTradeLongMessageCode, body |-> ZeroOxTradeLongMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OxTradeShortMessageCode, body |-> ZeroOxTradeShortMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OxTradeExpandedMessageCode, body |-> ZeroOxTradeExpandedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OxTradeBreakMessageCode, body |-> ZeroOxTradeBreakMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OxEndOfSessionCode, body |-> ZeroOxEndOfSession]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OxSymbolMappingMessageCode, body |-> ZeroOxSymbolMappingMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OxTradingStatusMessageCode, body |-> ZeroOxTradingStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OxWidthUpdateMessageCode, body |-> ZeroOxWidthUpdateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OxOptionsAuctionUpdateMessageCode, body |-> ZeroOxOptionsAuctionUpdateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OxAuctionSummaryMessageCode, body |-> ZeroOxAuctionSummaryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OxAuctionNotificationMessageCode, body |-> ZeroOxAuctionNotificationMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OxAuctionCancelMessageCode, body |-> ZeroOxAuctionCancelMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OxAuctionTradeMessageCode, body |-> ZeroOxAuctionTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OxSoqStrikeRangeUpdateMessageCode, body |-> ZeroOxSoqStrikeRangeUpdateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OxConstituentSymbolMappingMessageCode, body |-> ZeroOxConstituentSymbolMappingMessage]] }

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

(* Every Ox Time Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOxTimeMessage ==
    \A message \in CheckedOxTimeMessage :
        LET read == DecodeOxTimeMessage(EncodeOxTimeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ox Unit Clear Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOxUnitClearMessage ==
    \A message \in CheckedOxUnitClearMessage :
        LET read == DecodeOxUnitClearMessage(EncodeOxUnitClearMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ox Transaction Begin Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOxTransactionBeginMessage ==
    \A message \in CheckedOxTransactionBeginMessage :
        LET read == DecodeOxTransactionBeginMessage(EncodeOxTransactionBeginMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ox Transaction End Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOxTransactionEndMessage ==
    \A message \in CheckedOxTransactionEndMessage :
        LET read == DecodeOxTransactionEndMessage(EncodeOxTransactionEndMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ox Add Order Long Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOxAddOrderLongMessage ==
    \A message \in CheckedOxAddOrderLongMessage :
        LET read == DecodeOxAddOrderLongMessage(EncodeOxAddOrderLongMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ox Add Order Short Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOxAddOrderShortMessage ==
    \A message \in CheckedOxAddOrderShortMessage :
        LET read == DecodeOxAddOrderShortMessage(EncodeOxAddOrderShortMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ox Add Order Expanded Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOxAddOrderExpandedMessage ==
    \A message \in CheckedOxAddOrderExpandedMessage :
        LET read == DecodeOxAddOrderExpandedMessage(EncodeOxAddOrderExpandedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ox Order Executed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOxOrderExecutedMessage ==
    \A message \in CheckedOxOrderExecutedMessage :
        LET read == DecodeOxOrderExecutedMessage(EncodeOxOrderExecutedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ox Order Executed At Price Size Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOxOrderExecutedAtPriceSizeMessage ==
    \A message \in CheckedOxOrderExecutedAtPriceSizeMessage :
        LET read == DecodeOxOrderExecutedAtPriceSizeMessage(EncodeOxOrderExecutedAtPriceSizeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ox Reduce Size Long Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOxReduceSizeLongMessage ==
    \A message \in CheckedOxReduceSizeLongMessage :
        LET read == DecodeOxReduceSizeLongMessage(EncodeOxReduceSizeLongMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ox Reduce Size Short Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOxReduceSizeShortMessage ==
    \A message \in CheckedOxReduceSizeShortMessage :
        LET read == DecodeOxReduceSizeShortMessage(EncodeOxReduceSizeShortMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ox Modify Order Long Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOxModifyOrderLongMessage ==
    \A message \in CheckedOxModifyOrderLongMessage :
        LET read == DecodeOxModifyOrderLongMessage(EncodeOxModifyOrderLongMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ox Modify Order Short Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOxModifyOrderShortMessage ==
    \A message \in CheckedOxModifyOrderShortMessage :
        LET read == DecodeOxModifyOrderShortMessage(EncodeOxModifyOrderShortMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ox Delete Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOxDeleteOrderMessage ==
    \A message \in CheckedOxDeleteOrderMessage :
        LET read == DecodeOxDeleteOrderMessage(EncodeOxDeleteOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ox Trade Long Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOxTradeLongMessage ==
    \A message \in CheckedOxTradeLongMessage :
        LET read == DecodeOxTradeLongMessage(EncodeOxTradeLongMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ox Trade Short Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOxTradeShortMessage ==
    \A message \in CheckedOxTradeShortMessage :
        LET read == DecodeOxTradeShortMessage(EncodeOxTradeShortMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ox Trade Expanded Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOxTradeExpandedMessage ==
    \A message \in CheckedOxTradeExpandedMessage :
        LET read == DecodeOxTradeExpandedMessage(EncodeOxTradeExpandedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ox Trade Break Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOxTradeBreakMessage ==
    \A message \in CheckedOxTradeBreakMessage :
        LET read == DecodeOxTradeBreakMessage(EncodeOxTradeBreakMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ox End Of Session decodes back to what was encoded, and leaves nothing over *)
RoundTripOxEndOfSession ==
    \A message \in CheckedOxEndOfSession :
        LET read == DecodeOxEndOfSession(EncodeOxEndOfSession(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ox Symbol Mapping Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOxSymbolMappingMessage ==
    \A message \in CheckedOxSymbolMappingMessage :
        LET read == DecodeOxSymbolMappingMessage(EncodeOxSymbolMappingMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ox Trading Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOxTradingStatusMessage ==
    \A message \in CheckedOxTradingStatusMessage :
        LET read == DecodeOxTradingStatusMessage(EncodeOxTradingStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ox Width Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOxWidthUpdateMessage ==
    \A message \in CheckedOxWidthUpdateMessage :
        LET read == DecodeOxWidthUpdateMessage(EncodeOxWidthUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ox Options Auction Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOxOptionsAuctionUpdateMessage ==
    \A message \in CheckedOxOptionsAuctionUpdateMessage :
        LET read == DecodeOxOptionsAuctionUpdateMessage(EncodeOxOptionsAuctionUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ox Auction Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOxAuctionSummaryMessage ==
    \A message \in CheckedOxAuctionSummaryMessage :
        LET read == DecodeOxAuctionSummaryMessage(EncodeOxAuctionSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ox Auction Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOxAuctionNotificationMessage ==
    \A message \in CheckedOxAuctionNotificationMessage :
        LET read == DecodeOxAuctionNotificationMessage(EncodeOxAuctionNotificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ox Auction Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOxAuctionCancelMessage ==
    \A message \in CheckedOxAuctionCancelMessage :
        LET read == DecodeOxAuctionCancelMessage(EncodeOxAuctionCancelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ox Auction Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOxAuctionTradeMessage ==
    \A message \in CheckedOxAuctionTradeMessage :
        LET read == DecodeOxAuctionTradeMessage(EncodeOxAuctionTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ox Soq Strike Range Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOxSoqStrikeRangeUpdateMessage ==
    \A message \in CheckedOxSoqStrikeRangeUpdateMessage :
        LET read == DecodeOxSoqStrikeRangeUpdateMessage(EncodeOxSoqStrikeRangeUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ox Constituent Symbol Mapping Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOxConstituentSymbolMappingMessage ==
    \A message \in CheckedOxConstituentSymbolMappingMessage :
        LET read == DecodeOxConstituentSymbolMappingMessage(EncodeOxConstituentSymbolMappingMessage(message))
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
