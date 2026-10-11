------------ MODULE EdgxEquities_MulticastDepthOfBook_v2_41_64 -------------
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
(* Eq Time Message: 4 bytes                                                *)
(***************************************************************************)

EqTimeMessage ==
    [ time : Sample(4) ]

EncodeEqTimeMessage(message) ==
    message.time

DecodeEqTimeMessage(bytes) ==
    LET time == ReadBytes(bytes, 4) IN IF ~time.ok THEN Fail ELSE
    Ok([ time |-> time.value ], time.rest)

ZeroEqTimeMessage ==
    [ time |-> [i \in 1 .. 4 |-> 0] ]

(* Eq Time Message at zero, then each field in turn at the values it is checked at *)
CheckedEqTimeMessage ==
    { ZeroEqTimeMessage }
        \cup { [ZeroEqTimeMessage EXCEPT !.time = one] : one \in Sample(4) }

(***************************************************************************)
(* Eq Unit Clear Message: 4 bytes                                          *)
(***************************************************************************)

EqUnitClearMessage ==
    [ timeOffset : Sample(4) ]

EncodeEqUnitClearMessage(message) ==
    message.timeOffset

DecodeEqUnitClearMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    Ok([ timeOffset |-> timeOffset.value ], timeOffset.rest)

ZeroEqUnitClearMessage ==
    [ timeOffset |-> [i \in 1 .. 4 |-> 0] ]

(* Eq Unit Clear Message at zero, then each field in turn at the values it is checked at *)
CheckedEqUnitClearMessage ==
    { ZeroEqUnitClearMessage }
        \cup { [ZeroEqUnitClearMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }

(***************************************************************************)
(* Eq Add Order Long Message: 32 bytes                                     *)
(***************************************************************************)

EqAddOrderLongMessage ==
    [ timeOffset    : Sample(4),
      orderId       : Sample(8),
      sideIndicator : Sample(1),
      quantityLong  : Sample(4),
      symbolShort   : Sample(6),
      priceLong     : Sample(8),
      addFlags      : Sample(1) ]

EncodeEqAddOrderLongMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.quantityLong
        \o message.symbolShort
        \o message.priceLong
        \o message.addFlags

DecodeEqAddOrderLongMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET quantityLong == ReadBytes(sideIndicator.rest, 4) IN IF ~quantityLong.ok THEN Fail ELSE
    LET symbolShort == ReadBytes(quantityLong.rest, 6) IN IF ~symbolShort.ok THEN Fail ELSE
    LET priceLong == ReadBytes(symbolShort.rest, 8) IN IF ~priceLong.ok THEN Fail ELSE
    LET addFlags == ReadBytes(priceLong.rest, 1) IN IF ~addFlags.ok THEN Fail ELSE
    Ok([ timeOffset    |-> timeOffset.value,
         orderId       |-> orderId.value,
         sideIndicator |-> sideIndicator.value,
         quantityLong  |-> quantityLong.value,
         symbolShort   |-> symbolShort.value,
         priceLong     |-> priceLong.value,
         addFlags      |-> addFlags.value ], addFlags.rest)

ZeroEqAddOrderLongMessage ==
    [ timeOffset    |-> [i \in 1 .. 4 |-> 0],
      orderId       |-> [i \in 1 .. 8 |-> 0],
      sideIndicator |-> [i \in 1 .. 1 |-> 0],
      quantityLong  |-> [i \in 1 .. 4 |-> 0],
      symbolShort   |-> [i \in 1 .. 6 |-> 0],
      priceLong     |-> [i \in 1 .. 8 |-> 0],
      addFlags      |-> [i \in 1 .. 1 |-> 0] ]

(* Eq Add Order Long Message at zero, then each field in turn at the values it is checked at *)
CheckedEqAddOrderLongMessage ==
    { ZeroEqAddOrderLongMessage }
        \cup { [ZeroEqAddOrderLongMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroEqAddOrderLongMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroEqAddOrderLongMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroEqAddOrderLongMessage EXCEPT !.quantityLong = one] : one \in Sample(4) }
        \cup { [ZeroEqAddOrderLongMessage EXCEPT !.symbolShort = one] : one \in Sample(6) }
        \cup { [ZeroEqAddOrderLongMessage EXCEPT !.priceLong = one] : one \in Sample(8) }
        \cup { [ZeroEqAddOrderLongMessage EXCEPT !.addFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Eq Add Order Short Message: 24 bytes                                    *)
(***************************************************************************)

EqAddOrderShortMessage ==
    [ timeOffset    : Sample(4),
      orderId       : Sample(8),
      sideIndicator : Sample(1),
      quantityShort : Sample(2),
      symbolShort   : Sample(6),
      priceShort    : Sample(2),
      addFlags      : Sample(1) ]

EncodeEqAddOrderShortMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.quantityShort
        \o message.symbolShort
        \o message.priceShort
        \o message.addFlags

DecodeEqAddOrderShortMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET quantityShort == ReadBytes(sideIndicator.rest, 2) IN IF ~quantityShort.ok THEN Fail ELSE
    LET symbolShort == ReadBytes(quantityShort.rest, 6) IN IF ~symbolShort.ok THEN Fail ELSE
    LET priceShort == ReadBytes(symbolShort.rest, 2) IN IF ~priceShort.ok THEN Fail ELSE
    LET addFlags == ReadBytes(priceShort.rest, 1) IN IF ~addFlags.ok THEN Fail ELSE
    Ok([ timeOffset    |-> timeOffset.value,
         orderId       |-> orderId.value,
         sideIndicator |-> sideIndicator.value,
         quantityShort |-> quantityShort.value,
         symbolShort   |-> symbolShort.value,
         priceShort    |-> priceShort.value,
         addFlags      |-> addFlags.value ], addFlags.rest)

ZeroEqAddOrderShortMessage ==
    [ timeOffset    |-> [i \in 1 .. 4 |-> 0],
      orderId       |-> [i \in 1 .. 8 |-> 0],
      sideIndicator |-> [i \in 1 .. 1 |-> 0],
      quantityShort |-> [i \in 1 .. 2 |-> 0],
      symbolShort   |-> [i \in 1 .. 6 |-> 0],
      priceShort    |-> [i \in 1 .. 2 |-> 0],
      addFlags      |-> [i \in 1 .. 1 |-> 0] ]

(* Eq Add Order Short Message at zero, then each field in turn at the values it is checked at *)
CheckedEqAddOrderShortMessage ==
    { ZeroEqAddOrderShortMessage }
        \cup { [ZeroEqAddOrderShortMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroEqAddOrderShortMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroEqAddOrderShortMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroEqAddOrderShortMessage EXCEPT !.quantityShort = one] : one \in Sample(2) }
        \cup { [ZeroEqAddOrderShortMessage EXCEPT !.symbolShort = one] : one \in Sample(6) }
        \cup { [ZeroEqAddOrderShortMessage EXCEPT !.priceShort = one] : one \in Sample(2) }
        \cup { [ZeroEqAddOrderShortMessage EXCEPT !.addFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Eq Add Order Expanded Message: 39 bytes                                 *)
(***************************************************************************)

EqAddOrderExpandedMessage ==
    [ timeOffset        : Sample(4),
      orderId           : Sample(8),
      sideIndicator     : Sample(1),
      quantityLong      : Sample(4),
      symbolLong        : Sample(8),
      priceLong         : Sample(8),
      addFlags          : Sample(1),
      participantId     : Sample(4),
      customerIndicator : Sample(1) ]

EncodeEqAddOrderExpandedMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.quantityLong
        \o message.symbolLong
        \o message.priceLong
        \o message.addFlags
        \o message.participantId
        \o message.customerIndicator

DecodeEqAddOrderExpandedMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET quantityLong == ReadBytes(sideIndicator.rest, 4) IN IF ~quantityLong.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(quantityLong.rest, 8) IN IF ~symbolLong.ok THEN Fail ELSE
    LET priceLong == ReadBytes(symbolLong.rest, 8) IN IF ~priceLong.ok THEN Fail ELSE
    LET addFlags == ReadBytes(priceLong.rest, 1) IN IF ~addFlags.ok THEN Fail ELSE
    LET participantId == ReadBytes(addFlags.rest, 4) IN IF ~participantId.ok THEN Fail ELSE
    LET customerIndicator == ReadBytes(participantId.rest, 1) IN IF ~customerIndicator.ok THEN Fail ELSE
    Ok([ timeOffset        |-> timeOffset.value,
         orderId           |-> orderId.value,
         sideIndicator     |-> sideIndicator.value,
         quantityLong      |-> quantityLong.value,
         symbolLong        |-> symbolLong.value,
         priceLong         |-> priceLong.value,
         addFlags          |-> addFlags.value,
         participantId     |-> participantId.value,
         customerIndicator |-> customerIndicator.value ], customerIndicator.rest)

ZeroEqAddOrderExpandedMessage ==
    [ timeOffset        |-> [i \in 1 .. 4 |-> 0],
      orderId           |-> [i \in 1 .. 8 |-> 0],
      sideIndicator     |-> [i \in 1 .. 1 |-> 0],
      quantityLong      |-> [i \in 1 .. 4 |-> 0],
      symbolLong        |-> [i \in 1 .. 8 |-> 0],
      priceLong         |-> [i \in 1 .. 8 |-> 0],
      addFlags          |-> [i \in 1 .. 1 |-> 0],
      participantId     |-> [i \in 1 .. 4 |-> 0],
      customerIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Eq Add Order Expanded Message at zero, then each field in turn at the values it is checked at *)
CheckedEqAddOrderExpandedMessage ==
    { ZeroEqAddOrderExpandedMessage }
        \cup { [ZeroEqAddOrderExpandedMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroEqAddOrderExpandedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroEqAddOrderExpandedMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroEqAddOrderExpandedMessage EXCEPT !.quantityLong = one] : one \in Sample(4) }
        \cup { [ZeroEqAddOrderExpandedMessage EXCEPT !.symbolLong = one] : one \in Sample(8) }
        \cup { [ZeroEqAddOrderExpandedMessage EXCEPT !.priceLong = one] : one \in Sample(8) }
        \cup { [ZeroEqAddOrderExpandedMessage EXCEPT !.addFlags = one] : one \in Sample(1) }
        \cup { [ZeroEqAddOrderExpandedMessage EXCEPT !.participantId = one] : one \in Sample(4) }
        \cup { [ZeroEqAddOrderExpandedMessage EXCEPT !.customerIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Eq Order Executed Message: 24 bytes                                     *)
(***************************************************************************)

EqOrderExecutedMessage ==
    [ timeOffset       : Sample(4),
      orderId          : Sample(8),
      executedQuantity : Sample(4),
      executionId      : Sample(8) ]

EncodeEqOrderExecutedMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.executedQuantity
        \o message.executionId

DecodeEqOrderExecutedMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(orderId.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET executionId == ReadBytes(executedQuantity.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    Ok([ timeOffset       |-> timeOffset.value,
         orderId          |-> orderId.value,
         executedQuantity |-> executedQuantity.value,
         executionId      |-> executionId.value ], executionId.rest)

ZeroEqOrderExecutedMessage ==
    [ timeOffset       |-> [i \in 1 .. 4 |-> 0],
      orderId          |-> [i \in 1 .. 8 |-> 0],
      executedQuantity |-> [i \in 1 .. 4 |-> 0],
      executionId      |-> [i \in 1 .. 8 |-> 0] ]

(* Eq Order Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedEqOrderExecutedMessage ==
    { ZeroEqOrderExecutedMessage }
        \cup { [ZeroEqOrderExecutedMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroEqOrderExecutedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroEqOrderExecutedMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroEqOrderExecutedMessage EXCEPT !.executionId = one] : one \in Sample(8) }

(***************************************************************************)
(* Eq Order Executed At Price Size Message: 36 bytes                       *)
(***************************************************************************)

EqOrderExecutedAtPriceSizeMessage ==
    [ timeOffset        : Sample(4),
      orderId           : Sample(8),
      executedQuantity  : Sample(4),
      remainingQuantity : Sample(4),
      executionId       : Sample(8),
      priceLong         : Sample(8) ]

EncodeEqOrderExecutedAtPriceSizeMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.executedQuantity
        \o message.remainingQuantity
        \o message.executionId
        \o message.priceLong

DecodeEqOrderExecutedAtPriceSizeMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(orderId.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET remainingQuantity == ReadBytes(executedQuantity.rest, 4) IN IF ~remainingQuantity.ok THEN Fail ELSE
    LET executionId == ReadBytes(remainingQuantity.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET priceLong == ReadBytes(executionId.rest, 8) IN IF ~priceLong.ok THEN Fail ELSE
    Ok([ timeOffset        |-> timeOffset.value,
         orderId           |-> orderId.value,
         executedQuantity  |-> executedQuantity.value,
         remainingQuantity |-> remainingQuantity.value,
         executionId       |-> executionId.value,
         priceLong         |-> priceLong.value ], priceLong.rest)

ZeroEqOrderExecutedAtPriceSizeMessage ==
    [ timeOffset        |-> [i \in 1 .. 4 |-> 0],
      orderId           |-> [i \in 1 .. 8 |-> 0],
      executedQuantity  |-> [i \in 1 .. 4 |-> 0],
      remainingQuantity |-> [i \in 1 .. 4 |-> 0],
      executionId       |-> [i \in 1 .. 8 |-> 0],
      priceLong         |-> [i \in 1 .. 8 |-> 0] ]

(* Eq Order Executed At Price Size Message at zero, then each field in turn at the values it is checked at *)
CheckedEqOrderExecutedAtPriceSizeMessage ==
    { ZeroEqOrderExecutedAtPriceSizeMessage }
        \cup { [ZeroEqOrderExecutedAtPriceSizeMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroEqOrderExecutedAtPriceSizeMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroEqOrderExecutedAtPriceSizeMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroEqOrderExecutedAtPriceSizeMessage EXCEPT !.remainingQuantity = one] : one \in Sample(4) }
        \cup { [ZeroEqOrderExecutedAtPriceSizeMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroEqOrderExecutedAtPriceSizeMessage EXCEPT !.priceLong = one] : one \in Sample(8) }

(***************************************************************************)
(* Eq Reduce Size Long Message: 16 bytes                                   *)
(***************************************************************************)

EqReduceSizeLongMessage ==
    [ timeOffset           : Sample(4),
      orderId              : Sample(8),
      canceledQuantityLong : Sample(4) ]

EncodeEqReduceSizeLongMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.canceledQuantityLong

DecodeEqReduceSizeLongMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET canceledQuantityLong == ReadBytes(orderId.rest, 4) IN IF ~canceledQuantityLong.ok THEN Fail ELSE
    Ok([ timeOffset           |-> timeOffset.value,
         orderId              |-> orderId.value,
         canceledQuantityLong |-> canceledQuantityLong.value ], canceledQuantityLong.rest)

ZeroEqReduceSizeLongMessage ==
    [ timeOffset           |-> [i \in 1 .. 4 |-> 0],
      orderId              |-> [i \in 1 .. 8 |-> 0],
      canceledQuantityLong |-> [i \in 1 .. 4 |-> 0] ]

(* Eq Reduce Size Long Message at zero, then each field in turn at the values it is checked at *)
CheckedEqReduceSizeLongMessage ==
    { ZeroEqReduceSizeLongMessage }
        \cup { [ZeroEqReduceSizeLongMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroEqReduceSizeLongMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroEqReduceSizeLongMessage EXCEPT !.canceledQuantityLong = one] : one \in Sample(4) }

(***************************************************************************)
(* Eq Reduce Size Short Message: 14 bytes                                  *)
(***************************************************************************)

EqReduceSizeShortMessage ==
    [ timeOffset            : Sample(4),
      orderId               : Sample(8),
      canceledQuantityShort : Sample(2) ]

EncodeEqReduceSizeShortMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.canceledQuantityShort

DecodeEqReduceSizeShortMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET canceledQuantityShort == ReadBytes(orderId.rest, 2) IN IF ~canceledQuantityShort.ok THEN Fail ELSE
    Ok([ timeOffset            |-> timeOffset.value,
         orderId               |-> orderId.value,
         canceledQuantityShort |-> canceledQuantityShort.value ], canceledQuantityShort.rest)

ZeroEqReduceSizeShortMessage ==
    [ timeOffset            |-> [i \in 1 .. 4 |-> 0],
      orderId               |-> [i \in 1 .. 8 |-> 0],
      canceledQuantityShort |-> [i \in 1 .. 2 |-> 0] ]

(* Eq Reduce Size Short Message at zero, then each field in turn at the values it is checked at *)
CheckedEqReduceSizeShortMessage ==
    { ZeroEqReduceSizeShortMessage }
        \cup { [ZeroEqReduceSizeShortMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroEqReduceSizeShortMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroEqReduceSizeShortMessage EXCEPT !.canceledQuantityShort = one] : one \in Sample(2) }

(***************************************************************************)
(* Eq Modify Order Long Message: 25 bytes                                  *)
(***************************************************************************)

EqModifyOrderLongMessage ==
    [ timeOffset   : Sample(4),
      orderId      : Sample(8),
      quantityLong : Sample(4),
      priceLong    : Sample(8),
      modifyFlags  : Sample(1) ]

EncodeEqModifyOrderLongMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.quantityLong
        \o message.priceLong
        \o message.modifyFlags

DecodeEqModifyOrderLongMessage(bytes) ==
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

ZeroEqModifyOrderLongMessage ==
    [ timeOffset   |-> [i \in 1 .. 4 |-> 0],
      orderId      |-> [i \in 1 .. 8 |-> 0],
      quantityLong |-> [i \in 1 .. 4 |-> 0],
      priceLong    |-> [i \in 1 .. 8 |-> 0],
      modifyFlags  |-> [i \in 1 .. 1 |-> 0] ]

(* Eq Modify Order Long Message at zero, then each field in turn at the values it is checked at *)
CheckedEqModifyOrderLongMessage ==
    { ZeroEqModifyOrderLongMessage }
        \cup { [ZeroEqModifyOrderLongMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroEqModifyOrderLongMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroEqModifyOrderLongMessage EXCEPT !.quantityLong = one] : one \in Sample(4) }
        \cup { [ZeroEqModifyOrderLongMessage EXCEPT !.priceLong = one] : one \in Sample(8) }
        \cup { [ZeroEqModifyOrderLongMessage EXCEPT !.modifyFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Eq Modify Order Short Message: 17 bytes                                 *)
(***************************************************************************)

EqModifyOrderShortMessage ==
    [ timeOffset    : Sample(4),
      orderId       : Sample(8),
      quantityShort : Sample(2),
      priceShort    : Sample(2),
      modifyFlags   : Sample(1) ]

EncodeEqModifyOrderShortMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.quantityShort
        \o message.priceShort
        \o message.modifyFlags

DecodeEqModifyOrderShortMessage(bytes) ==
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

ZeroEqModifyOrderShortMessage ==
    [ timeOffset    |-> [i \in 1 .. 4 |-> 0],
      orderId       |-> [i \in 1 .. 8 |-> 0],
      quantityShort |-> [i \in 1 .. 2 |-> 0],
      priceShort    |-> [i \in 1 .. 2 |-> 0],
      modifyFlags   |-> [i \in 1 .. 1 |-> 0] ]

(* Eq Modify Order Short Message at zero, then each field in turn at the values it is checked at *)
CheckedEqModifyOrderShortMessage ==
    { ZeroEqModifyOrderShortMessage }
        \cup { [ZeroEqModifyOrderShortMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroEqModifyOrderShortMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroEqModifyOrderShortMessage EXCEPT !.quantityShort = one] : one \in Sample(2) }
        \cup { [ZeroEqModifyOrderShortMessage EXCEPT !.priceShort = one] : one \in Sample(2) }
        \cup { [ZeroEqModifyOrderShortMessage EXCEPT !.modifyFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Eq Delete Order Message: 12 bytes                                       *)
(***************************************************************************)

EqDeleteOrderMessage ==
    [ timeOffset : Sample(4),
      orderId    : Sample(8) ]

EncodeEqDeleteOrderMessage(message) ==
    message.timeOffset
        \o message.orderId

DecodeEqDeleteOrderMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    Ok([ timeOffset |-> timeOffset.value,
         orderId    |-> orderId.value ], orderId.rest)

ZeroEqDeleteOrderMessage ==
    [ timeOffset |-> [i \in 1 .. 4 |-> 0],
      orderId    |-> [i \in 1 .. 8 |-> 0] ]

(* Eq Delete Order Message at zero, then each field in turn at the values it is checked at *)
CheckedEqDeleteOrderMessage ==
    { ZeroEqDeleteOrderMessage }
        \cup { [ZeroEqDeleteOrderMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroEqDeleteOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }

(***************************************************************************)
(* Eq Trade Long Message: 39 bytes                                         *)
(***************************************************************************)

EqTradeLongMessage ==
    [ timeOffset    : Sample(4),
      orderId       : Sample(8),
      sideIndicator : Sample(1),
      quantityLong  : Sample(4),
      symbolShort   : Sample(6),
      priceLong     : Sample(8),
      executionId   : Sample(8) ]

EncodeEqTradeLongMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.quantityLong
        \o message.symbolShort
        \o message.priceLong
        \o message.executionId

DecodeEqTradeLongMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET quantityLong == ReadBytes(sideIndicator.rest, 4) IN IF ~quantityLong.ok THEN Fail ELSE
    LET symbolShort == ReadBytes(quantityLong.rest, 6) IN IF ~symbolShort.ok THEN Fail ELSE
    LET priceLong == ReadBytes(symbolShort.rest, 8) IN IF ~priceLong.ok THEN Fail ELSE
    LET executionId == ReadBytes(priceLong.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    Ok([ timeOffset    |-> timeOffset.value,
         orderId       |-> orderId.value,
         sideIndicator |-> sideIndicator.value,
         quantityLong  |-> quantityLong.value,
         symbolShort   |-> symbolShort.value,
         priceLong     |-> priceLong.value,
         executionId   |-> executionId.value ], executionId.rest)

ZeroEqTradeLongMessage ==
    [ timeOffset    |-> [i \in 1 .. 4 |-> 0],
      orderId       |-> [i \in 1 .. 8 |-> 0],
      sideIndicator |-> [i \in 1 .. 1 |-> 0],
      quantityLong  |-> [i \in 1 .. 4 |-> 0],
      symbolShort   |-> [i \in 1 .. 6 |-> 0],
      priceLong     |-> [i \in 1 .. 8 |-> 0],
      executionId   |-> [i \in 1 .. 8 |-> 0] ]

(* Eq Trade Long Message at zero, then each field in turn at the values it is checked at *)
CheckedEqTradeLongMessage ==
    { ZeroEqTradeLongMessage }
        \cup { [ZeroEqTradeLongMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroEqTradeLongMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroEqTradeLongMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroEqTradeLongMessage EXCEPT !.quantityLong = one] : one \in Sample(4) }
        \cup { [ZeroEqTradeLongMessage EXCEPT !.symbolShort = one] : one \in Sample(6) }
        \cup { [ZeroEqTradeLongMessage EXCEPT !.priceLong = one] : one \in Sample(8) }
        \cup { [ZeroEqTradeLongMessage EXCEPT !.executionId = one] : one \in Sample(8) }

(***************************************************************************)
(* Eq Trade Short Message: 31 bytes                                        *)
(***************************************************************************)

EqTradeShortMessage ==
    [ timeOffset    : Sample(4),
      orderId       : Sample(8),
      sideIndicator : Sample(1),
      quantityShort : Sample(2),
      symbolShort   : Sample(6),
      priceShort    : Sample(2),
      executionId   : Sample(8) ]

EncodeEqTradeShortMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.quantityShort
        \o message.symbolShort
        \o message.priceShort
        \o message.executionId

DecodeEqTradeShortMessage(bytes) ==
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

ZeroEqTradeShortMessage ==
    [ timeOffset    |-> [i \in 1 .. 4 |-> 0],
      orderId       |-> [i \in 1 .. 8 |-> 0],
      sideIndicator |-> [i \in 1 .. 1 |-> 0],
      quantityShort |-> [i \in 1 .. 2 |-> 0],
      symbolShort   |-> [i \in 1 .. 6 |-> 0],
      priceShort    |-> [i \in 1 .. 2 |-> 0],
      executionId   |-> [i \in 1 .. 8 |-> 0] ]

(* Eq Trade Short Message at zero, then each field in turn at the values it is checked at *)
CheckedEqTradeShortMessage ==
    { ZeroEqTradeShortMessage }
        \cup { [ZeroEqTradeShortMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroEqTradeShortMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroEqTradeShortMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroEqTradeShortMessage EXCEPT !.quantityShort = one] : one \in Sample(2) }
        \cup { [ZeroEqTradeShortMessage EXCEPT !.symbolShort = one] : one \in Sample(6) }
        \cup { [ZeroEqTradeShortMessage EXCEPT !.priceShort = one] : one \in Sample(2) }
        \cup { [ZeroEqTradeShortMessage EXCEPT !.executionId = one] : one \in Sample(8) }

(***************************************************************************)
(* Eq Trade Expanded Message: 41 bytes                                     *)
(***************************************************************************)

EqTradeExpandedMessage ==
    [ timeOffset    : Sample(4),
      orderId       : Sample(8),
      sideIndicator : Sample(1),
      quantityLong  : Sample(4),
      symbolLong    : Sample(8),
      priceLong     : Sample(8),
      executionId   : Sample(8) ]

EncodeEqTradeExpandedMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.quantityLong
        \o message.symbolLong
        \o message.priceLong
        \o message.executionId

DecodeEqTradeExpandedMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET quantityLong == ReadBytes(sideIndicator.rest, 4) IN IF ~quantityLong.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(quantityLong.rest, 8) IN IF ~symbolLong.ok THEN Fail ELSE
    LET priceLong == ReadBytes(symbolLong.rest, 8) IN IF ~priceLong.ok THEN Fail ELSE
    LET executionId == ReadBytes(priceLong.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    Ok([ timeOffset    |-> timeOffset.value,
         orderId       |-> orderId.value,
         sideIndicator |-> sideIndicator.value,
         quantityLong  |-> quantityLong.value,
         symbolLong    |-> symbolLong.value,
         priceLong     |-> priceLong.value,
         executionId   |-> executionId.value ], executionId.rest)

ZeroEqTradeExpandedMessage ==
    [ timeOffset    |-> [i \in 1 .. 4 |-> 0],
      orderId       |-> [i \in 1 .. 8 |-> 0],
      sideIndicator |-> [i \in 1 .. 1 |-> 0],
      quantityLong  |-> [i \in 1 .. 4 |-> 0],
      symbolLong    |-> [i \in 1 .. 8 |-> 0],
      priceLong     |-> [i \in 1 .. 8 |-> 0],
      executionId   |-> [i \in 1 .. 8 |-> 0] ]

(* Eq Trade Expanded Message at zero, then each field in turn at the values it is checked at *)
CheckedEqTradeExpandedMessage ==
    { ZeroEqTradeExpandedMessage }
        \cup { [ZeroEqTradeExpandedMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroEqTradeExpandedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroEqTradeExpandedMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroEqTradeExpandedMessage EXCEPT !.quantityLong = one] : one \in Sample(4) }
        \cup { [ZeroEqTradeExpandedMessage EXCEPT !.symbolLong = one] : one \in Sample(8) }
        \cup { [ZeroEqTradeExpandedMessage EXCEPT !.priceLong = one] : one \in Sample(8) }
        \cup { [ZeroEqTradeExpandedMessage EXCEPT !.executionId = one] : one \in Sample(8) }

(***************************************************************************)
(* Eq Trade Break Message: 12 bytes                                        *)
(***************************************************************************)

EqTradeBreakMessage ==
    [ timeOffset  : Sample(4),
      executionId : Sample(8) ]

EncodeEqTradeBreakMessage(message) ==
    message.timeOffset
        \o message.executionId

DecodeEqTradeBreakMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET executionId == ReadBytes(timeOffset.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    Ok([ timeOffset  |-> timeOffset.value,
         executionId |-> executionId.value ], executionId.rest)

ZeroEqTradeBreakMessage ==
    [ timeOffset  |-> [i \in 1 .. 4 |-> 0],
      executionId |-> [i \in 1 .. 8 |-> 0] ]

(* Eq Trade Break Message at zero, then each field in turn at the values it is checked at *)
CheckedEqTradeBreakMessage ==
    { ZeroEqTradeBreakMessage }
        \cup { [ZeroEqTradeBreakMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroEqTradeBreakMessage EXCEPT !.executionId = one] : one \in Sample(8) }

(***************************************************************************)
(* Eq End Of Session: 4 bytes                                              *)
(***************************************************************************)

EqEndOfSession ==
    [ timestamp : Sample(4) ]

EncodeEqEndOfSession(message) ==
    message.timestamp

DecodeEqEndOfSession(bytes) ==
    LET timestamp == ReadBytes(bytes, 4) IN IF ~timestamp.ok THEN Fail ELSE
    Ok([ timestamp |-> timestamp.value ], timestamp.rest)

ZeroEqEndOfSession ==
    [ timestamp |-> [i \in 1 .. 4 |-> 0] ]

(* Eq End Of Session at zero, then each field in turn at the values it is checked at *)
CheckedEqEndOfSession ==
    { ZeroEqEndOfSession }
        \cup { [ZeroEqEndOfSession EXCEPT !.timestamp = one] : one \in Sample(4) }

(***************************************************************************)
(* Eq Trading Status Message: 16 bytes                                     *)
(***************************************************************************)

EqTradingStatusMessage ==
    [ timeOffset      : Sample(4),
      symbolLong      : Sample(8),
      tradingStatus   : Sample(1),
      regShoAction    : Sample(1),
      reserved1       : Sample(1),
      secondReserved1 : Sample(1) ]

EncodeEqTradingStatusMessage(message) ==
    message.timeOffset
        \o message.symbolLong
        \o message.tradingStatus
        \o message.regShoAction
        \o message.reserved1
        \o message.secondReserved1

DecodeEqTradingStatusMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(timeOffset.rest, 8) IN IF ~symbolLong.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(symbolLong.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET regShoAction == ReadBytes(tradingStatus.rest, 1) IN IF ~regShoAction.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(regShoAction.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET secondReserved1 == ReadBytes(reserved1.rest, 1) IN IF ~secondReserved1.ok THEN Fail ELSE
    Ok([ timeOffset      |-> timeOffset.value,
         symbolLong      |-> symbolLong.value,
         tradingStatus   |-> tradingStatus.value,
         regShoAction    |-> regShoAction.value,
         reserved1       |-> reserved1.value,
         secondReserved1 |-> secondReserved1.value ], secondReserved1.rest)

ZeroEqTradingStatusMessage ==
    [ timeOffset      |-> [i \in 1 .. 4 |-> 0],
      symbolLong      |-> [i \in 1 .. 8 |-> 0],
      tradingStatus   |-> [i \in 1 .. 1 |-> 0],
      regShoAction    |-> [i \in 1 .. 1 |-> 0],
      reserved1       |-> [i \in 1 .. 1 |-> 0],
      secondReserved1 |-> [i \in 1 .. 1 |-> 0] ]

(* Eq Trading Status Message at zero, then each field in turn at the values it is checked at *)
CheckedEqTradingStatusMessage ==
    { ZeroEqTradingStatusMessage }
        \cup { [ZeroEqTradingStatusMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroEqTradingStatusMessage EXCEPT !.symbolLong = one] : one \in Sample(8) }
        \cup { [ZeroEqTradingStatusMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroEqTradingStatusMessage EXCEPT !.regShoAction = one] : one \in Sample(1) }
        \cup { [ZeroEqTradingStatusMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroEqTradingStatusMessage EXCEPT !.secondReserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Eq Auction Update Message: 45 bytes                                     *)
(***************************************************************************)

EqAuctionUpdateMessage ==
    [ timeOffset       : Sample(4),
      stockSymbol      : Sample(8),
      auctionType      : Sample(1),
      referencePrice   : Sample(8),
      buyShares        : Sample(4),
      sellShares       : Sample(4),
      indicativePrice  : Sample(8),
      auctionOnlyPrice : Sample(8) ]

EncodeEqAuctionUpdateMessage(message) ==
    message.timeOffset
        \o message.stockSymbol
        \o message.auctionType
        \o message.referencePrice
        \o message.buyShares
        \o message.sellShares
        \o message.indicativePrice
        \o message.auctionOnlyPrice

DecodeEqAuctionUpdateMessage(bytes) ==
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

ZeroEqAuctionUpdateMessage ==
    [ timeOffset       |-> [i \in 1 .. 4 |-> 0],
      stockSymbol      |-> [i \in 1 .. 8 |-> 0],
      auctionType      |-> [i \in 1 .. 1 |-> 0],
      referencePrice   |-> [i \in 1 .. 8 |-> 0],
      buyShares        |-> [i \in 1 .. 4 |-> 0],
      sellShares       |-> [i \in 1 .. 4 |-> 0],
      indicativePrice  |-> [i \in 1 .. 8 |-> 0],
      auctionOnlyPrice |-> [i \in 1 .. 8 |-> 0] ]

(* Eq Auction Update Message at zero, then each field in turn at the values it is checked at *)
CheckedEqAuctionUpdateMessage ==
    { ZeroEqAuctionUpdateMessage }
        \cup { [ZeroEqAuctionUpdateMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroEqAuctionUpdateMessage EXCEPT !.stockSymbol = one] : one \in Sample(8) }
        \cup { [ZeroEqAuctionUpdateMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroEqAuctionUpdateMessage EXCEPT !.referencePrice = one] : one \in Sample(8) }
        \cup { [ZeroEqAuctionUpdateMessage EXCEPT !.buyShares = one] : one \in Sample(4) }
        \cup { [ZeroEqAuctionUpdateMessage EXCEPT !.sellShares = one] : one \in Sample(4) }
        \cup { [ZeroEqAuctionUpdateMessage EXCEPT !.indicativePrice = one] : one \in Sample(8) }
        \cup { [ZeroEqAuctionUpdateMessage EXCEPT !.auctionOnlyPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Eq Auction Summary Message: 25 bytes                                    *)
(***************************************************************************)

EqAuctionSummaryMessage ==
    [ timeOffset      : Sample(4),
      stockSymbol     : Sample(8),
      auctionType     : Sample(1),
      priceLong       : Sample(8),
      sharesContracts : Sample(4) ]

EncodeEqAuctionSummaryMessage(message) ==
    message.timeOffset
        \o message.stockSymbol
        \o message.auctionType
        \o message.priceLong
        \o message.sharesContracts

DecodeEqAuctionSummaryMessage(bytes) ==
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

ZeroEqAuctionSummaryMessage ==
    [ timeOffset      |-> [i \in 1 .. 4 |-> 0],
      stockSymbol     |-> [i \in 1 .. 8 |-> 0],
      auctionType     |-> [i \in 1 .. 1 |-> 0],
      priceLong       |-> [i \in 1 .. 8 |-> 0],
      sharesContracts |-> [i \in 1 .. 4 |-> 0] ]

(* Eq Auction Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedEqAuctionSummaryMessage ==
    { ZeroEqAuctionSummaryMessage }
        \cup { [ZeroEqAuctionSummaryMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroEqAuctionSummaryMessage EXCEPT !.stockSymbol = one] : one \in Sample(8) }
        \cup { [ZeroEqAuctionSummaryMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroEqAuctionSummaryMessage EXCEPT !.priceLong = one] : one \in Sample(8) }
        \cup { [ZeroEqAuctionSummaryMessage EXCEPT !.sharesContracts = one] : one \in Sample(4) }

(***************************************************************************)
(* Eq Retail Price Improvement Message: 13 bytes                           *)
(***************************************************************************)

EqRetailPriceImprovementMessage ==
    [ timeOffset             : Sample(4),
      symbolLong             : Sample(8),
      retailPriceImprovement : Sample(1) ]

EncodeEqRetailPriceImprovementMessage(message) ==
    message.timeOffset
        \o message.symbolLong
        \o message.retailPriceImprovement

DecodeEqRetailPriceImprovementMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(timeOffset.rest, 8) IN IF ~symbolLong.ok THEN Fail ELSE
    LET retailPriceImprovement == ReadBytes(symbolLong.rest, 1) IN IF ~retailPriceImprovement.ok THEN Fail ELSE
    Ok([ timeOffset             |-> timeOffset.value,
         symbolLong             |-> symbolLong.value,
         retailPriceImprovement |-> retailPriceImprovement.value ], retailPriceImprovement.rest)

ZeroEqRetailPriceImprovementMessage ==
    [ timeOffset             |-> [i \in 1 .. 4 |-> 0],
      symbolLong             |-> [i \in 1 .. 8 |-> 0],
      retailPriceImprovement |-> [i \in 1 .. 1 |-> 0] ]

(* Eq Retail Price Improvement Message at zero, then each field in turn at the values it is checked at *)
CheckedEqRetailPriceImprovementMessage ==
    { ZeroEqRetailPriceImprovementMessage }
        \cup { [ZeroEqRetailPriceImprovementMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroEqRetailPriceImprovementMessage EXCEPT !.symbolLong = one] : one \in Sample(8) }
        \cup { [ZeroEqRetailPriceImprovementMessage EXCEPT !.retailPriceImprovement = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

EqTimeMessageCode == 32  \* 0x20
EqUnitClearMessageCode == 151  \* 0x97
EqAddOrderLongMessageCode == 33  \* 0x21
EqAddOrderShortMessageCode == 34  \* 0x22
EqAddOrderExpandedMessageCode == 47  \* 0x2f
EqOrderExecutedMessageCode == 35  \* 0x23
EqOrderExecutedAtPriceSizeMessageCode == 36  \* 0x24
EqReduceSizeLongMessageCode == 37  \* 0x25
EqReduceSizeShortMessageCode == 38  \* 0x26
EqModifyOrderLongMessageCode == 39  \* 0x27
EqModifyOrderShortMessageCode == 40  \* 0x28
EqDeleteOrderMessageCode == 41  \* 0x29
EqTradeLongMessageCode == 42  \* 0x2a
EqTradeShortMessageCode == 43  \* 0x2b
EqTradeExpandedMessageCode == 48  \* 0x30
EqTradeBreakMessageCode == 44  \* 0x2c
EqEndOfSessionCode == 45  \* 0x2d
EqTradingStatusMessageCode == 49  \* 0x31
EqAuctionUpdateMessageCode == 149  \* 0x95
EqAuctionSummaryMessageCode == 150  \* 0x96
EqRetailPriceImprovementMessageCode == 152  \* 0x98

Payload ==
    [ tag : {EqTimeMessageCode}, body : EqTimeMessage ]
        \cup [ tag : {EqUnitClearMessageCode}, body : EqUnitClearMessage ]
        \cup [ tag : {EqAddOrderLongMessageCode}, body : EqAddOrderLongMessage ]
        \cup [ tag : {EqAddOrderShortMessageCode}, body : EqAddOrderShortMessage ]
        \cup [ tag : {EqAddOrderExpandedMessageCode}, body : EqAddOrderExpandedMessage ]
        \cup [ tag : {EqOrderExecutedMessageCode}, body : EqOrderExecutedMessage ]
        \cup [ tag : {EqOrderExecutedAtPriceSizeMessageCode}, body : EqOrderExecutedAtPriceSizeMessage ]
        \cup [ tag : {EqReduceSizeLongMessageCode}, body : EqReduceSizeLongMessage ]
        \cup [ tag : {EqReduceSizeShortMessageCode}, body : EqReduceSizeShortMessage ]
        \cup [ tag : {EqModifyOrderLongMessageCode}, body : EqModifyOrderLongMessage ]
        \cup [ tag : {EqModifyOrderShortMessageCode}, body : EqModifyOrderShortMessage ]
        \cup [ tag : {EqDeleteOrderMessageCode}, body : EqDeleteOrderMessage ]
        \cup [ tag : {EqTradeLongMessageCode}, body : EqTradeLongMessage ]
        \cup [ tag : {EqTradeShortMessageCode}, body : EqTradeShortMessage ]
        \cup [ tag : {EqTradeExpandedMessageCode}, body : EqTradeExpandedMessage ]
        \cup [ tag : {EqTradeBreakMessageCode}, body : EqTradeBreakMessage ]
        \cup [ tag : {EqEndOfSessionCode}, body : EqEndOfSession ]
        \cup [ tag : {EqTradingStatusMessageCode}, body : EqTradingStatusMessage ]
        \cup [ tag : {EqAuctionUpdateMessageCode}, body : EqAuctionUpdateMessage ]
        \cup [ tag : {EqAuctionSummaryMessageCode}, body : EqAuctionSummaryMessage ]
        \cup [ tag : {EqRetailPriceImprovementMessageCode}, body : EqRetailPriceImprovementMessage ]

EncodePayload(message) ==
    CASE message.tag = EqTimeMessageCode -> EncodeEqTimeMessage(message.body)
      [] message.tag = EqUnitClearMessageCode -> EncodeEqUnitClearMessage(message.body)
      [] message.tag = EqAddOrderLongMessageCode -> EncodeEqAddOrderLongMessage(message.body)
      [] message.tag = EqAddOrderShortMessageCode -> EncodeEqAddOrderShortMessage(message.body)
      [] message.tag = EqAddOrderExpandedMessageCode -> EncodeEqAddOrderExpandedMessage(message.body)
      [] message.tag = EqOrderExecutedMessageCode -> EncodeEqOrderExecutedMessage(message.body)
      [] message.tag = EqOrderExecutedAtPriceSizeMessageCode -> EncodeEqOrderExecutedAtPriceSizeMessage(message.body)
      [] message.tag = EqReduceSizeLongMessageCode -> EncodeEqReduceSizeLongMessage(message.body)
      [] message.tag = EqReduceSizeShortMessageCode -> EncodeEqReduceSizeShortMessage(message.body)
      [] message.tag = EqModifyOrderLongMessageCode -> EncodeEqModifyOrderLongMessage(message.body)
      [] message.tag = EqModifyOrderShortMessageCode -> EncodeEqModifyOrderShortMessage(message.body)
      [] message.tag = EqDeleteOrderMessageCode -> EncodeEqDeleteOrderMessage(message.body)
      [] message.tag = EqTradeLongMessageCode -> EncodeEqTradeLongMessage(message.body)
      [] message.tag = EqTradeShortMessageCode -> EncodeEqTradeShortMessage(message.body)
      [] message.tag = EqTradeExpandedMessageCode -> EncodeEqTradeExpandedMessage(message.body)
      [] message.tag = EqTradeBreakMessageCode -> EncodeEqTradeBreakMessage(message.body)
      [] message.tag = EqEndOfSessionCode -> EncodeEqEndOfSession(message.body)
      [] message.tag = EqTradingStatusMessageCode -> EncodeEqTradingStatusMessage(message.body)
      [] message.tag = EqAuctionUpdateMessageCode -> EncodeEqAuctionUpdateMessage(message.body)
      [] message.tag = EqAuctionSummaryMessageCode -> EncodeEqAuctionSummaryMessage(message.body)
      [] message.tag = EqRetailPriceImprovementMessageCode -> EncodeEqRetailPriceImprovementMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = EqTimeMessageCode -> DecodeEqTimeMessage(bytes)
              [] tag = EqUnitClearMessageCode -> DecodeEqUnitClearMessage(bytes)
              [] tag = EqAddOrderLongMessageCode -> DecodeEqAddOrderLongMessage(bytes)
              [] tag = EqAddOrderShortMessageCode -> DecodeEqAddOrderShortMessage(bytes)
              [] tag = EqAddOrderExpandedMessageCode -> DecodeEqAddOrderExpandedMessage(bytes)
              [] tag = EqOrderExecutedMessageCode -> DecodeEqOrderExecutedMessage(bytes)
              [] tag = EqOrderExecutedAtPriceSizeMessageCode -> DecodeEqOrderExecutedAtPriceSizeMessage(bytes)
              [] tag = EqReduceSizeLongMessageCode -> DecodeEqReduceSizeLongMessage(bytes)
              [] tag = EqReduceSizeShortMessageCode -> DecodeEqReduceSizeShortMessage(bytes)
              [] tag = EqModifyOrderLongMessageCode -> DecodeEqModifyOrderLongMessage(bytes)
              [] tag = EqModifyOrderShortMessageCode -> DecodeEqModifyOrderShortMessage(bytes)
              [] tag = EqDeleteOrderMessageCode -> DecodeEqDeleteOrderMessage(bytes)
              [] tag = EqTradeLongMessageCode -> DecodeEqTradeLongMessage(bytes)
              [] tag = EqTradeShortMessageCode -> DecodeEqTradeShortMessage(bytes)
              [] tag = EqTradeExpandedMessageCode -> DecodeEqTradeExpandedMessage(bytes)
              [] tag = EqTradeBreakMessageCode -> DecodeEqTradeBreakMessage(bytes)
              [] tag = EqEndOfSessionCode -> DecodeEqEndOfSession(bytes)
              [] tag = EqTradingStatusMessageCode -> DecodeEqTradingStatusMessage(bytes)
              [] tag = EqAuctionUpdateMessageCode -> DecodeEqAuctionUpdateMessage(bytes)
              [] tag = EqAuctionSummaryMessageCode -> DecodeEqAuctionSummaryMessage(bytes)
              [] tag = EqRetailPriceImprovementMessageCode -> DecodeEqRetailPriceImprovementMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> EqTimeMessageCode, body |-> ZeroEqTimeMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> EqTimeMessageCode, body |-> one] : one \in CheckedEqTimeMessage }
        \cup { [tag |-> EqUnitClearMessageCode, body |-> one] : one \in CheckedEqUnitClearMessage }
        \cup { [tag |-> EqAddOrderLongMessageCode, body |-> one] : one \in CheckedEqAddOrderLongMessage }
        \cup { [tag |-> EqAddOrderShortMessageCode, body |-> one] : one \in CheckedEqAddOrderShortMessage }
        \cup { [tag |-> EqAddOrderExpandedMessageCode, body |-> one] : one \in CheckedEqAddOrderExpandedMessage }
        \cup { [tag |-> EqOrderExecutedMessageCode, body |-> one] : one \in CheckedEqOrderExecutedMessage }
        \cup { [tag |-> EqOrderExecutedAtPriceSizeMessageCode, body |-> one] : one \in CheckedEqOrderExecutedAtPriceSizeMessage }
        \cup { [tag |-> EqReduceSizeLongMessageCode, body |-> one] : one \in CheckedEqReduceSizeLongMessage }
        \cup { [tag |-> EqReduceSizeShortMessageCode, body |-> one] : one \in CheckedEqReduceSizeShortMessage }
        \cup { [tag |-> EqModifyOrderLongMessageCode, body |-> one] : one \in CheckedEqModifyOrderLongMessage }
        \cup { [tag |-> EqModifyOrderShortMessageCode, body |-> one] : one \in CheckedEqModifyOrderShortMessage }
        \cup { [tag |-> EqDeleteOrderMessageCode, body |-> one] : one \in CheckedEqDeleteOrderMessage }
        \cup { [tag |-> EqTradeLongMessageCode, body |-> one] : one \in CheckedEqTradeLongMessage }
        \cup { [tag |-> EqTradeShortMessageCode, body |-> one] : one \in CheckedEqTradeShortMessage }
        \cup { [tag |-> EqTradeExpandedMessageCode, body |-> one] : one \in CheckedEqTradeExpandedMessage }
        \cup { [tag |-> EqTradeBreakMessageCode, body |-> one] : one \in CheckedEqTradeBreakMessage }
        \cup { [tag |-> EqEndOfSessionCode, body |-> one] : one \in CheckedEqEndOfSession }
        \cup { [tag |-> EqTradingStatusMessageCode, body |-> one] : one \in CheckedEqTradingStatusMessage }
        \cup { [tag |-> EqAuctionUpdateMessageCode, body |-> one] : one \in CheckedEqAuctionUpdateMessage }
        \cup { [tag |-> EqAuctionSummaryMessageCode, body |-> one] : one \in CheckedEqAuctionSummaryMessage }
        \cup { [tag |-> EqRetailPriceImprovementMessageCode, body |-> one] : one \in CheckedEqRetailPriceImprovementMessage }

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
    { [ZeroMessage EXCEPT !.payload = [tag |-> EqTimeMessageCode, body |-> ZeroEqTimeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EqUnitClearMessageCode, body |-> ZeroEqUnitClearMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EqAddOrderLongMessageCode, body |-> ZeroEqAddOrderLongMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EqAddOrderShortMessageCode, body |-> ZeroEqAddOrderShortMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EqAddOrderExpandedMessageCode, body |-> ZeroEqAddOrderExpandedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EqOrderExecutedMessageCode, body |-> ZeroEqOrderExecutedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EqOrderExecutedAtPriceSizeMessageCode, body |-> ZeroEqOrderExecutedAtPriceSizeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EqReduceSizeLongMessageCode, body |-> ZeroEqReduceSizeLongMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EqReduceSizeShortMessageCode, body |-> ZeroEqReduceSizeShortMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EqModifyOrderLongMessageCode, body |-> ZeroEqModifyOrderLongMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EqModifyOrderShortMessageCode, body |-> ZeroEqModifyOrderShortMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EqDeleteOrderMessageCode, body |-> ZeroEqDeleteOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EqTradeLongMessageCode, body |-> ZeroEqTradeLongMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EqTradeShortMessageCode, body |-> ZeroEqTradeShortMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EqTradeExpandedMessageCode, body |-> ZeroEqTradeExpandedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EqTradeBreakMessageCode, body |-> ZeroEqTradeBreakMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EqEndOfSessionCode, body |-> ZeroEqEndOfSession]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EqTradingStatusMessageCode, body |-> ZeroEqTradingStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EqAuctionUpdateMessageCode, body |-> ZeroEqAuctionUpdateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EqAuctionSummaryMessageCode, body |-> ZeroEqAuctionSummaryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EqRetailPriceImprovementMessageCode, body |-> ZeroEqRetailPriceImprovementMessage]] }

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

(* Every Eq Time Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEqTimeMessage ==
    \A message \in CheckedEqTimeMessage :
        LET read == DecodeEqTimeMessage(EncodeEqTimeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Eq Unit Clear Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEqUnitClearMessage ==
    \A message \in CheckedEqUnitClearMessage :
        LET read == DecodeEqUnitClearMessage(EncodeEqUnitClearMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Eq Add Order Long Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEqAddOrderLongMessage ==
    \A message \in CheckedEqAddOrderLongMessage :
        LET read == DecodeEqAddOrderLongMessage(EncodeEqAddOrderLongMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Eq Add Order Short Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEqAddOrderShortMessage ==
    \A message \in CheckedEqAddOrderShortMessage :
        LET read == DecodeEqAddOrderShortMessage(EncodeEqAddOrderShortMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Eq Add Order Expanded Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEqAddOrderExpandedMessage ==
    \A message \in CheckedEqAddOrderExpandedMessage :
        LET read == DecodeEqAddOrderExpandedMessage(EncodeEqAddOrderExpandedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Eq Order Executed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEqOrderExecutedMessage ==
    \A message \in CheckedEqOrderExecutedMessage :
        LET read == DecodeEqOrderExecutedMessage(EncodeEqOrderExecutedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Eq Order Executed At Price Size Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEqOrderExecutedAtPriceSizeMessage ==
    \A message \in CheckedEqOrderExecutedAtPriceSizeMessage :
        LET read == DecodeEqOrderExecutedAtPriceSizeMessage(EncodeEqOrderExecutedAtPriceSizeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Eq Reduce Size Long Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEqReduceSizeLongMessage ==
    \A message \in CheckedEqReduceSizeLongMessage :
        LET read == DecodeEqReduceSizeLongMessage(EncodeEqReduceSizeLongMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Eq Reduce Size Short Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEqReduceSizeShortMessage ==
    \A message \in CheckedEqReduceSizeShortMessage :
        LET read == DecodeEqReduceSizeShortMessage(EncodeEqReduceSizeShortMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Eq Modify Order Long Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEqModifyOrderLongMessage ==
    \A message \in CheckedEqModifyOrderLongMessage :
        LET read == DecodeEqModifyOrderLongMessage(EncodeEqModifyOrderLongMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Eq Modify Order Short Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEqModifyOrderShortMessage ==
    \A message \in CheckedEqModifyOrderShortMessage :
        LET read == DecodeEqModifyOrderShortMessage(EncodeEqModifyOrderShortMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Eq Delete Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEqDeleteOrderMessage ==
    \A message \in CheckedEqDeleteOrderMessage :
        LET read == DecodeEqDeleteOrderMessage(EncodeEqDeleteOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Eq Trade Long Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEqTradeLongMessage ==
    \A message \in CheckedEqTradeLongMessage :
        LET read == DecodeEqTradeLongMessage(EncodeEqTradeLongMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Eq Trade Short Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEqTradeShortMessage ==
    \A message \in CheckedEqTradeShortMessage :
        LET read == DecodeEqTradeShortMessage(EncodeEqTradeShortMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Eq Trade Expanded Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEqTradeExpandedMessage ==
    \A message \in CheckedEqTradeExpandedMessage :
        LET read == DecodeEqTradeExpandedMessage(EncodeEqTradeExpandedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Eq Trade Break Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEqTradeBreakMessage ==
    \A message \in CheckedEqTradeBreakMessage :
        LET read == DecodeEqTradeBreakMessage(EncodeEqTradeBreakMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Eq End Of Session decodes back to what was encoded, and leaves nothing over *)
RoundTripEqEndOfSession ==
    \A message \in CheckedEqEndOfSession :
        LET read == DecodeEqEndOfSession(EncodeEqEndOfSession(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Eq Trading Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEqTradingStatusMessage ==
    \A message \in CheckedEqTradingStatusMessage :
        LET read == DecodeEqTradingStatusMessage(EncodeEqTradingStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Eq Auction Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEqAuctionUpdateMessage ==
    \A message \in CheckedEqAuctionUpdateMessage :
        LET read == DecodeEqAuctionUpdateMessage(EncodeEqAuctionUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Eq Auction Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEqAuctionSummaryMessage ==
    \A message \in CheckedEqAuctionSummaryMessage :
        LET read == DecodeEqAuctionSummaryMessage(EncodeEqAuctionSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Eq Retail Price Improvement Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEqRetailPriceImprovementMessage ==
    \A message \in CheckedEqRetailPriceImprovementMessage :
        LET read == DecodeEqRetailPriceImprovementMessage(EncodeEqRetailPriceImprovementMessage(message))
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
