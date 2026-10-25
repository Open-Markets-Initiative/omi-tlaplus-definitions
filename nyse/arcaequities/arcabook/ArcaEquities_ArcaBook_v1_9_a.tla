------------------- MODULE ArcaEquities_ArcaBook_v1_9_a --------------------
(***************************************************************************)
(* New York Stock Exchange ArcaBook v1.9.a                                 *)
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
(* Send Time: 8 bytes                                                      *)
(***************************************************************************)

SendTime ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeSendTime(message) ==
    message.seconds
        \o message.nanoseconds

DecodeSendTime(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroSendTime ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Send Time at zero, then each field in turn at the values it is checked at *)
CheckedSendTime ==
    { ZeroSendTime }
        \cup { [ZeroSendTime EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroSendTime EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Add Order Message: 27 bytes                                             *)
(***************************************************************************)

AddOrderMessage ==
    [ sourceTimeNs        : Sample(4),
      symbolIndex         : Sample(4),
      symbolSeqNum        : Sample(4),
      orderId             : Sample(4),
      price               : Sample(4),
      volume              : Sample(4),
      side                : Sample(1),
      orderIdgtcIndicator : Sample(1),
      tradeSession        : Sample(1) ]

EncodeAddOrderMessage(message) ==
    message.sourceTimeNs
        \o message.symbolIndex
        \o message.symbolSeqNum
        \o message.orderId
        \o message.price
        \o message.volume
        \o message.side
        \o message.orderIdgtcIndicator
        \o message.tradeSession

DecodeAddOrderMessage(bytes) ==
    LET sourceTimeNs == ReadBytes(bytes, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(sourceTimeNs.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET symbolSeqNum == ReadBytes(symbolIndex.rest, 4) IN IF ~symbolSeqNum.ok THEN Fail ELSE
    LET orderId == ReadBytes(symbolSeqNum.rest, 4) IN IF ~orderId.ok THEN Fail ELSE
    LET price == ReadBytes(orderId.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET volume == ReadBytes(price.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET side == ReadBytes(volume.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderIdgtcIndicator == ReadBytes(side.rest, 1) IN IF ~orderIdgtcIndicator.ok THEN Fail ELSE
    LET tradeSession == ReadBytes(orderIdgtcIndicator.rest, 1) IN IF ~tradeSession.ok THEN Fail ELSE
    Ok([ sourceTimeNs        |-> sourceTimeNs.value,
         symbolIndex         |-> symbolIndex.value,
         symbolSeqNum        |-> symbolSeqNum.value,
         orderId             |-> orderId.value,
         price               |-> price.value,
         volume              |-> volume.value,
         side                |-> side.value,
         orderIdgtcIndicator |-> orderIdgtcIndicator.value,
         tradeSession        |-> tradeSession.value ], tradeSession.rest)

ZeroAddOrderMessage ==
    [ sourceTimeNs        |-> [i \in 1 .. 4 |-> 0],
      symbolIndex         |-> [i \in 1 .. 4 |-> 0],
      symbolSeqNum        |-> [i \in 1 .. 4 |-> 0],
      orderId             |-> [i \in 1 .. 4 |-> 0],
      price               |-> [i \in 1 .. 4 |-> 0],
      volume              |-> [i \in 1 .. 4 |-> 0],
      side                |-> [i \in 1 .. 1 |-> 0],
      orderIdgtcIndicator |-> [i \in 1 .. 1 |-> 0],
      tradeSession        |-> [i \in 1 .. 1 |-> 0] ]

(* Add Order Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderMessage ==
    { ZeroAddOrderMessage }
        \cup { [ZeroAddOrderMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.symbolSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderId = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderIdgtcIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.tradeSession = one] : one \in Sample(1) }

(***************************************************************************)
(* Attributed Add Order Message: 32 bytes                                  *)
(***************************************************************************)

AttributedAddOrderMessage ==
    [ sourceTimeNs        : Sample(4),
      symbolIndex         : Sample(4),
      symbolSeqNum        : Sample(4),
      orderId             : Sample(4),
      price               : Sample(4),
      volume              : Sample(4),
      side                : Sample(1),
      orderIdgtcIndicator : Sample(1),
      tradeSession        : Sample(1),
      firmId              : Sample(5) ]

EncodeAttributedAddOrderMessage(message) ==
    message.sourceTimeNs
        \o message.symbolIndex
        \o message.symbolSeqNum
        \o message.orderId
        \o message.price
        \o message.volume
        \o message.side
        \o message.orderIdgtcIndicator
        \o message.tradeSession
        \o message.firmId

DecodeAttributedAddOrderMessage(bytes) ==
    LET sourceTimeNs == ReadBytes(bytes, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(sourceTimeNs.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET symbolSeqNum == ReadBytes(symbolIndex.rest, 4) IN IF ~symbolSeqNum.ok THEN Fail ELSE
    LET orderId == ReadBytes(symbolSeqNum.rest, 4) IN IF ~orderId.ok THEN Fail ELSE
    LET price == ReadBytes(orderId.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET volume == ReadBytes(price.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET side == ReadBytes(volume.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderIdgtcIndicator == ReadBytes(side.rest, 1) IN IF ~orderIdgtcIndicator.ok THEN Fail ELSE
    LET tradeSession == ReadBytes(orderIdgtcIndicator.rest, 1) IN IF ~tradeSession.ok THEN Fail ELSE
    LET firmId == ReadBytes(tradeSession.rest, 5) IN IF ~firmId.ok THEN Fail ELSE
    Ok([ sourceTimeNs        |-> sourceTimeNs.value,
         symbolIndex         |-> symbolIndex.value,
         symbolSeqNum        |-> symbolSeqNum.value,
         orderId             |-> orderId.value,
         price               |-> price.value,
         volume              |-> volume.value,
         side                |-> side.value,
         orderIdgtcIndicator |-> orderIdgtcIndicator.value,
         tradeSession        |-> tradeSession.value,
         firmId              |-> firmId.value ], firmId.rest)

ZeroAttributedAddOrderMessage ==
    [ sourceTimeNs        |-> [i \in 1 .. 4 |-> 0],
      symbolIndex         |-> [i \in 1 .. 4 |-> 0],
      symbolSeqNum        |-> [i \in 1 .. 4 |-> 0],
      orderId             |-> [i \in 1 .. 4 |-> 0],
      price               |-> [i \in 1 .. 4 |-> 0],
      volume              |-> [i \in 1 .. 4 |-> 0],
      side                |-> [i \in 1 .. 1 |-> 0],
      orderIdgtcIndicator |-> [i \in 1 .. 1 |-> 0],
      tradeSession        |-> [i \in 1 .. 1 |-> 0],
      firmId              |-> [i \in 1 .. 5 |-> 0] ]

(* Attributed Add Order Message at zero, then each field in turn at the values it is checked at *)
CheckedAttributedAddOrderMessage ==
    { ZeroAttributedAddOrderMessage }
        \cup { [ZeroAttributedAddOrderMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroAttributedAddOrderMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroAttributedAddOrderMessage EXCEPT !.symbolSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroAttributedAddOrderMessage EXCEPT !.orderId = one] : one \in Sample(4) }
        \cup { [ZeroAttributedAddOrderMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroAttributedAddOrderMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroAttributedAddOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAttributedAddOrderMessage EXCEPT !.orderIdgtcIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAttributedAddOrderMessage EXCEPT !.tradeSession = one] : one \in Sample(1) }
        \cup { [ZeroAttributedAddOrderMessage EXCEPT !.firmId = one] : one \in Sample(5) }

(***************************************************************************)
(* Modify Order Message: 27 bytes                                          *)
(***************************************************************************)

ModifyOrderMessage ==
    [ sourceTimeNs        : Sample(4),
      symbolIndex         : Sample(4),
      symbolSeqNum        : Sample(4),
      orderId             : Sample(4),
      price               : Sample(4),
      volume              : Sample(4),
      side                : Sample(1),
      orderIdgtcIndicator : Sample(1),
      reasonCode          : Sample(1) ]

EncodeModifyOrderMessage(message) ==
    message.sourceTimeNs
        \o message.symbolIndex
        \o message.symbolSeqNum
        \o message.orderId
        \o message.price
        \o message.volume
        \o message.side
        \o message.orderIdgtcIndicator
        \o message.reasonCode

DecodeModifyOrderMessage(bytes) ==
    LET sourceTimeNs == ReadBytes(bytes, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(sourceTimeNs.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET symbolSeqNum == ReadBytes(symbolIndex.rest, 4) IN IF ~symbolSeqNum.ok THEN Fail ELSE
    LET orderId == ReadBytes(symbolSeqNum.rest, 4) IN IF ~orderId.ok THEN Fail ELSE
    LET price == ReadBytes(orderId.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET volume == ReadBytes(price.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET side == ReadBytes(volume.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderIdgtcIndicator == ReadBytes(side.rest, 1) IN IF ~orderIdgtcIndicator.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(orderIdgtcIndicator.rest, 1) IN IF ~reasonCode.ok THEN Fail ELSE
    Ok([ sourceTimeNs        |-> sourceTimeNs.value,
         symbolIndex         |-> symbolIndex.value,
         symbolSeqNum        |-> symbolSeqNum.value,
         orderId             |-> orderId.value,
         price               |-> price.value,
         volume              |-> volume.value,
         side                |-> side.value,
         orderIdgtcIndicator |-> orderIdgtcIndicator.value,
         reasonCode          |-> reasonCode.value ], reasonCode.rest)

ZeroModifyOrderMessage ==
    [ sourceTimeNs        |-> [i \in 1 .. 4 |-> 0],
      symbolIndex         |-> [i \in 1 .. 4 |-> 0],
      symbolSeqNum        |-> [i \in 1 .. 4 |-> 0],
      orderId             |-> [i \in 1 .. 4 |-> 0],
      price               |-> [i \in 1 .. 4 |-> 0],
      volume              |-> [i \in 1 .. 4 |-> 0],
      side                |-> [i \in 1 .. 1 |-> 0],
      orderIdgtcIndicator |-> [i \in 1 .. 1 |-> 0],
      reasonCode          |-> [i \in 1 .. 1 |-> 0] ]

(* Modify Order Message at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderMessage ==
    { ZeroModifyOrderMessage }
        \cup { [ZeroModifyOrderMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.symbolSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.orderId = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.orderIdgtcIndicator = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.reasonCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Delete Order Message: 19 bytes                                          *)
(***************************************************************************)

DeleteOrderMessage ==
    [ sourceTimeNs        : Sample(4),
      symbolIndex         : Sample(4),
      symbolSeqNum        : Sample(4),
      orderId             : Sample(4),
      side                : Sample(1),
      orderIdgtcIndicator : Sample(1),
      reasonCode          : Sample(1) ]

EncodeDeleteOrderMessage(message) ==
    message.sourceTimeNs
        \o message.symbolIndex
        \o message.symbolSeqNum
        \o message.orderId
        \o message.side
        \o message.orderIdgtcIndicator
        \o message.reasonCode

DecodeDeleteOrderMessage(bytes) ==
    LET sourceTimeNs == ReadBytes(bytes, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(sourceTimeNs.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET symbolSeqNum == ReadBytes(symbolIndex.rest, 4) IN IF ~symbolSeqNum.ok THEN Fail ELSE
    LET orderId == ReadBytes(symbolSeqNum.rest, 4) IN IF ~orderId.ok THEN Fail ELSE
    LET side == ReadBytes(orderId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderIdgtcIndicator == ReadBytes(side.rest, 1) IN IF ~orderIdgtcIndicator.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(orderIdgtcIndicator.rest, 1) IN IF ~reasonCode.ok THEN Fail ELSE
    Ok([ sourceTimeNs        |-> sourceTimeNs.value,
         symbolIndex         |-> symbolIndex.value,
         symbolSeqNum        |-> symbolSeqNum.value,
         orderId             |-> orderId.value,
         side                |-> side.value,
         orderIdgtcIndicator |-> orderIdgtcIndicator.value,
         reasonCode          |-> reasonCode.value ], reasonCode.rest)

ZeroDeleteOrderMessage ==
    [ sourceTimeNs        |-> [i \in 1 .. 4 |-> 0],
      symbolIndex         |-> [i \in 1 .. 4 |-> 0],
      symbolSeqNum        |-> [i \in 1 .. 4 |-> 0],
      orderId             |-> [i \in 1 .. 4 |-> 0],
      side                |-> [i \in 1 .. 1 |-> 0],
      orderIdgtcIndicator |-> [i \in 1 .. 1 |-> 0],
      reasonCode          |-> [i \in 1 .. 1 |-> 0] ]

(* Delete Order Message at zero, then each field in turn at the values it is checked at *)
CheckedDeleteOrderMessage ==
    { ZeroDeleteOrderMessage }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.symbolSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.orderId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.orderIdgtcIndicator = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.reasonCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Execution Message: 30 bytes                                             *)
(***************************************************************************)

ExecutionMessage ==
    [ sourceTimeNs        : Sample(4),
      symbolIndex         : Sample(4),
      symbolSeqNum        : Sample(4),
      orderId             : Sample(4),
      price               : Sample(4),
      volume              : Sample(4),
      orderIdgtcIndicator : Sample(1),
      reasonCode          : Sample(1),
      tradeId             : Sample(4) ]

EncodeExecutionMessage(message) ==
    message.sourceTimeNs
        \o message.symbolIndex
        \o message.symbolSeqNum
        \o message.orderId
        \o message.price
        \o message.volume
        \o message.orderIdgtcIndicator
        \o message.reasonCode
        \o message.tradeId

DecodeExecutionMessage(bytes) ==
    LET sourceTimeNs == ReadBytes(bytes, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(sourceTimeNs.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET symbolSeqNum == ReadBytes(symbolIndex.rest, 4) IN IF ~symbolSeqNum.ok THEN Fail ELSE
    LET orderId == ReadBytes(symbolSeqNum.rest, 4) IN IF ~orderId.ok THEN Fail ELSE
    LET price == ReadBytes(orderId.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET volume == ReadBytes(price.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET orderIdgtcIndicator == ReadBytes(volume.rest, 1) IN IF ~orderIdgtcIndicator.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(orderIdgtcIndicator.rest, 1) IN IF ~reasonCode.ok THEN Fail ELSE
    LET tradeId == ReadBytes(reasonCode.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    Ok([ sourceTimeNs        |-> sourceTimeNs.value,
         symbolIndex         |-> symbolIndex.value,
         symbolSeqNum        |-> symbolSeqNum.value,
         orderId             |-> orderId.value,
         price               |-> price.value,
         volume              |-> volume.value,
         orderIdgtcIndicator |-> orderIdgtcIndicator.value,
         reasonCode          |-> reasonCode.value,
         tradeId             |-> tradeId.value ], tradeId.rest)

ZeroExecutionMessage ==
    [ sourceTimeNs        |-> [i \in 1 .. 4 |-> 0],
      symbolIndex         |-> [i \in 1 .. 4 |-> 0],
      symbolSeqNum        |-> [i \in 1 .. 4 |-> 0],
      orderId             |-> [i \in 1 .. 4 |-> 0],
      price               |-> [i \in 1 .. 4 |-> 0],
      volume              |-> [i \in 1 .. 4 |-> 0],
      orderIdgtcIndicator |-> [i \in 1 .. 1 |-> 0],
      reasonCode          |-> [i \in 1 .. 1 |-> 0],
      tradeId             |-> [i \in 1 .. 4 |-> 0] ]

(* Execution Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionMessage ==
    { ZeroExecutionMessage }
        \cup { [ZeroExecutionMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroExecutionMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroExecutionMessage EXCEPT !.symbolSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroExecutionMessage EXCEPT !.orderId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroExecutionMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroExecutionMessage EXCEPT !.orderIdgtcIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExecutionMessage EXCEPT !.reasonCode = one] : one \in Sample(1) }
        \cup { [ZeroExecutionMessage EXCEPT !.tradeId = one] : one \in Sample(4) }

(***************************************************************************)
(* Add Order Refresh Message: 31 bytes                                     *)
(***************************************************************************)

AddOrderRefreshMessage ==
    [ sourceTime          : Sample(4),
      sourceTimeNs        : Sample(4),
      symbolIndex         : Sample(4),
      symbolSeqNum        : Sample(4),
      orderId             : Sample(4),
      price               : Sample(4),
      volume              : Sample(4),
      side                : Sample(1),
      orderIdgtcIndicator : Sample(1),
      tradeSession        : Sample(1) ]

EncodeAddOrderRefreshMessage(message) ==
    message.sourceTime
        \o message.sourceTimeNs
        \o message.symbolIndex
        \o message.symbolSeqNum
        \o message.orderId
        \o message.price
        \o message.volume
        \o message.side
        \o message.orderIdgtcIndicator
        \o message.tradeSession

DecodeAddOrderRefreshMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceTimeNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(sourceTimeNs.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET symbolSeqNum == ReadBytes(symbolIndex.rest, 4) IN IF ~symbolSeqNum.ok THEN Fail ELSE
    LET orderId == ReadBytes(symbolSeqNum.rest, 4) IN IF ~orderId.ok THEN Fail ELSE
    LET price == ReadBytes(orderId.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET volume == ReadBytes(price.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET side == ReadBytes(volume.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderIdgtcIndicator == ReadBytes(side.rest, 1) IN IF ~orderIdgtcIndicator.ok THEN Fail ELSE
    LET tradeSession == ReadBytes(orderIdgtcIndicator.rest, 1) IN IF ~tradeSession.ok THEN Fail ELSE
    Ok([ sourceTime          |-> sourceTime.value,
         sourceTimeNs        |-> sourceTimeNs.value,
         symbolIndex         |-> symbolIndex.value,
         symbolSeqNum        |-> symbolSeqNum.value,
         orderId             |-> orderId.value,
         price               |-> price.value,
         volume              |-> volume.value,
         side                |-> side.value,
         orderIdgtcIndicator |-> orderIdgtcIndicator.value,
         tradeSession        |-> tradeSession.value ], tradeSession.rest)

ZeroAddOrderRefreshMessage ==
    [ sourceTime          |-> [i \in 1 .. 4 |-> 0],
      sourceTimeNs        |-> [i \in 1 .. 4 |-> 0],
      symbolIndex         |-> [i \in 1 .. 4 |-> 0],
      symbolSeqNum        |-> [i \in 1 .. 4 |-> 0],
      orderId             |-> [i \in 1 .. 4 |-> 0],
      price               |-> [i \in 1 .. 4 |-> 0],
      volume              |-> [i \in 1 .. 4 |-> 0],
      side                |-> [i \in 1 .. 1 |-> 0],
      orderIdgtcIndicator |-> [i \in 1 .. 1 |-> 0],
      tradeSession        |-> [i \in 1 .. 1 |-> 0] ]

(* Add Order Refresh Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderRefreshMessage ==
    { ZeroAddOrderRefreshMessage }
        \cup { [ZeroAddOrderRefreshMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderRefreshMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderRefreshMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderRefreshMessage EXCEPT !.symbolSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderRefreshMessage EXCEPT !.orderId = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderRefreshMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderRefreshMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderRefreshMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderRefreshMessage EXCEPT !.orderIdgtcIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderRefreshMessage EXCEPT !.tradeSession = one] : one \in Sample(1) }

(***************************************************************************)
(* Attributed Add Order Refresh Message: 36 bytes                          *)
(***************************************************************************)

AttributedAddOrderRefreshMessage ==
    [ sourceTime          : Sample(4),
      sourceTimeNs        : Sample(4),
      symbolIndex         : Sample(4),
      symbolSeqNum        : Sample(4),
      orderId             : Sample(4),
      price               : Sample(4),
      volume              : Sample(4),
      side                : Sample(1),
      orderIdgtcIndicator : Sample(1),
      tradeSession        : Sample(1),
      firmId              : Sample(5) ]

EncodeAttributedAddOrderRefreshMessage(message) ==
    message.sourceTime
        \o message.sourceTimeNs
        \o message.symbolIndex
        \o message.symbolSeqNum
        \o message.orderId
        \o message.price
        \o message.volume
        \o message.side
        \o message.orderIdgtcIndicator
        \o message.tradeSession
        \o message.firmId

DecodeAttributedAddOrderRefreshMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceTimeNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(sourceTimeNs.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET symbolSeqNum == ReadBytes(symbolIndex.rest, 4) IN IF ~symbolSeqNum.ok THEN Fail ELSE
    LET orderId == ReadBytes(symbolSeqNum.rest, 4) IN IF ~orderId.ok THEN Fail ELSE
    LET price == ReadBytes(orderId.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET volume == ReadBytes(price.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET side == ReadBytes(volume.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderIdgtcIndicator == ReadBytes(side.rest, 1) IN IF ~orderIdgtcIndicator.ok THEN Fail ELSE
    LET tradeSession == ReadBytes(orderIdgtcIndicator.rest, 1) IN IF ~tradeSession.ok THEN Fail ELSE
    LET firmId == ReadBytes(tradeSession.rest, 5) IN IF ~firmId.ok THEN Fail ELSE
    Ok([ sourceTime          |-> sourceTime.value,
         sourceTimeNs        |-> sourceTimeNs.value,
         symbolIndex         |-> symbolIndex.value,
         symbolSeqNum        |-> symbolSeqNum.value,
         orderId             |-> orderId.value,
         price               |-> price.value,
         volume              |-> volume.value,
         side                |-> side.value,
         orderIdgtcIndicator |-> orderIdgtcIndicator.value,
         tradeSession        |-> tradeSession.value,
         firmId              |-> firmId.value ], firmId.rest)

ZeroAttributedAddOrderRefreshMessage ==
    [ sourceTime          |-> [i \in 1 .. 4 |-> 0],
      sourceTimeNs        |-> [i \in 1 .. 4 |-> 0],
      symbolIndex         |-> [i \in 1 .. 4 |-> 0],
      symbolSeqNum        |-> [i \in 1 .. 4 |-> 0],
      orderId             |-> [i \in 1 .. 4 |-> 0],
      price               |-> [i \in 1 .. 4 |-> 0],
      volume              |-> [i \in 1 .. 4 |-> 0],
      side                |-> [i \in 1 .. 1 |-> 0],
      orderIdgtcIndicator |-> [i \in 1 .. 1 |-> 0],
      tradeSession        |-> [i \in 1 .. 1 |-> 0],
      firmId              |-> [i \in 1 .. 5 |-> 0] ]

(* Attributed Add Order Refresh Message at zero, then each field in turn at the values it is checked at *)
CheckedAttributedAddOrderRefreshMessage ==
    { ZeroAttributedAddOrderRefreshMessage }
        \cup { [ZeroAttributedAddOrderRefreshMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroAttributedAddOrderRefreshMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroAttributedAddOrderRefreshMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroAttributedAddOrderRefreshMessage EXCEPT !.symbolSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroAttributedAddOrderRefreshMessage EXCEPT !.orderId = one] : one \in Sample(4) }
        \cup { [ZeroAttributedAddOrderRefreshMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroAttributedAddOrderRefreshMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroAttributedAddOrderRefreshMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAttributedAddOrderRefreshMessage EXCEPT !.orderIdgtcIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAttributedAddOrderRefreshMessage EXCEPT !.tradeSession = one] : one \in Sample(1) }
        \cup { [ZeroAttributedAddOrderRefreshMessage EXCEPT !.firmId = one] : one \in Sample(5) }

(***************************************************************************)
(* Imbalance Message: 48 bytes                                             *)
(***************************************************************************)

ImbalanceMessage ==
    [ sourceTime                  : Sample(4),
      sourceTimeNs                : Sample(4),
      symbolIndex                 : Sample(4),
      symbolSeqNum                : Sample(4),
      referencePrice              : Sample(4),
      pairedQty                   : Sample(4),
      totalImbalanceQty           : Sample(4),
      marketImbalanceQty          : Sample(4),
      auctionTime                 : Sample(2),
      auctionType                 : Sample(1),
      imbalanceSide               : Sample(1),
      continuousBookClearingPrice : Sample(4),
      closingOnlyClearingPrice    : Sample(4),
      ssrFilingPrice              : Sample(4) ]

EncodeImbalanceMessage(message) ==
    message.sourceTime
        \o message.sourceTimeNs
        \o message.symbolIndex
        \o message.symbolSeqNum
        \o message.referencePrice
        \o message.pairedQty
        \o message.totalImbalanceQty
        \o message.marketImbalanceQty
        \o message.auctionTime
        \o message.auctionType
        \o message.imbalanceSide
        \o message.continuousBookClearingPrice
        \o message.closingOnlyClearingPrice
        \o message.ssrFilingPrice

DecodeImbalanceMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceTimeNs == ReadBytes(sourceTime.rest, 4) IN IF ~sourceTimeNs.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(sourceTimeNs.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET symbolSeqNum == ReadBytes(symbolIndex.rest, 4) IN IF ~symbolSeqNum.ok THEN Fail ELSE
    LET referencePrice == ReadBytes(symbolSeqNum.rest, 4) IN IF ~referencePrice.ok THEN Fail ELSE
    LET pairedQty == ReadBytes(referencePrice.rest, 4) IN IF ~pairedQty.ok THEN Fail ELSE
    LET totalImbalanceQty == ReadBytes(pairedQty.rest, 4) IN IF ~totalImbalanceQty.ok THEN Fail ELSE
    LET marketImbalanceQty == ReadBytes(totalImbalanceQty.rest, 4) IN IF ~marketImbalanceQty.ok THEN Fail ELSE
    LET auctionTime == ReadBytes(marketImbalanceQty.rest, 2) IN IF ~auctionTime.ok THEN Fail ELSE
    LET auctionType == ReadBytes(auctionTime.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET imbalanceSide == ReadBytes(auctionType.rest, 1) IN IF ~imbalanceSide.ok THEN Fail ELSE
    LET continuousBookClearingPrice == ReadBytes(imbalanceSide.rest, 4) IN IF ~continuousBookClearingPrice.ok THEN Fail ELSE
    LET closingOnlyClearingPrice == ReadBytes(continuousBookClearingPrice.rest, 4) IN IF ~closingOnlyClearingPrice.ok THEN Fail ELSE
    LET ssrFilingPrice == ReadBytes(closingOnlyClearingPrice.rest, 4) IN IF ~ssrFilingPrice.ok THEN Fail ELSE
    Ok([ sourceTime                  |-> sourceTime.value,
         sourceTimeNs                |-> sourceTimeNs.value,
         symbolIndex                 |-> symbolIndex.value,
         symbolSeqNum                |-> symbolSeqNum.value,
         referencePrice              |-> referencePrice.value,
         pairedQty                   |-> pairedQty.value,
         totalImbalanceQty           |-> totalImbalanceQty.value,
         marketImbalanceQty          |-> marketImbalanceQty.value,
         auctionTime                 |-> auctionTime.value,
         auctionType                 |-> auctionType.value,
         imbalanceSide               |-> imbalanceSide.value,
         continuousBookClearingPrice |-> continuousBookClearingPrice.value,
         closingOnlyClearingPrice    |-> closingOnlyClearingPrice.value,
         ssrFilingPrice              |-> ssrFilingPrice.value ], ssrFilingPrice.rest)

ZeroImbalanceMessage ==
    [ sourceTime                  |-> [i \in 1 .. 4 |-> 0],
      sourceTimeNs                |-> [i \in 1 .. 4 |-> 0],
      symbolIndex                 |-> [i \in 1 .. 4 |-> 0],
      symbolSeqNum                |-> [i \in 1 .. 4 |-> 0],
      referencePrice              |-> [i \in 1 .. 4 |-> 0],
      pairedQty                   |-> [i \in 1 .. 4 |-> 0],
      totalImbalanceQty           |-> [i \in 1 .. 4 |-> 0],
      marketImbalanceQty          |-> [i \in 1 .. 4 |-> 0],
      auctionTime                 |-> [i \in 1 .. 2 |-> 0],
      auctionType                 |-> [i \in 1 .. 1 |-> 0],
      imbalanceSide               |-> [i \in 1 .. 1 |-> 0],
      continuousBookClearingPrice |-> [i \in 1 .. 4 |-> 0],
      closingOnlyClearingPrice    |-> [i \in 1 .. 4 |-> 0],
      ssrFilingPrice              |-> [i \in 1 .. 4 |-> 0] ]

(* Imbalance Message at zero, then each field in turn at the values it is checked at *)
CheckedImbalanceMessage ==
    { ZeroImbalanceMessage }
        \cup { [ZeroImbalanceMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroImbalanceMessage EXCEPT !.sourceTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroImbalanceMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroImbalanceMessage EXCEPT !.symbolSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroImbalanceMessage EXCEPT !.referencePrice = one] : one \in Sample(4) }
        \cup { [ZeroImbalanceMessage EXCEPT !.pairedQty = one] : one \in Sample(4) }
        \cup { [ZeroImbalanceMessage EXCEPT !.totalImbalanceQty = one] : one \in Sample(4) }
        \cup { [ZeroImbalanceMessage EXCEPT !.marketImbalanceQty = one] : one \in Sample(4) }
        \cup { [ZeroImbalanceMessage EXCEPT !.auctionTime = one] : one \in Sample(2) }
        \cup { [ZeroImbalanceMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroImbalanceMessage EXCEPT !.imbalanceSide = one] : one \in Sample(1) }
        \cup { [ZeroImbalanceMessage EXCEPT !.continuousBookClearingPrice = one] : one \in Sample(4) }
        \cup { [ZeroImbalanceMessage EXCEPT !.closingOnlyClearingPrice = one] : one \in Sample(4) }
        \cup { [ZeroImbalanceMessage EXCEPT !.ssrFilingPrice = one] : one \in Sample(4) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

AddOrderMessageCode == 100  \* 0x64
AttributedAddOrderMessageCode == 107  \* 0x6b
ModifyOrderMessageCode == 101  \* 0x65
DeleteOrderMessageCode == 102  \* 0x66
ExecutionMessageCode == 103  \* 0x67
AddOrderRefreshMessageCode == 106  \* 0x6a
AttributedAddOrderRefreshMessageCode == 108  \* 0x6c
ImbalanceMessageCode == 105  \* 0x69

Payload ==
    [ tag : {AddOrderMessageCode}, body : AddOrderMessage ]
        \cup [ tag : {AttributedAddOrderMessageCode}, body : AttributedAddOrderMessage ]
        \cup [ tag : {ModifyOrderMessageCode}, body : ModifyOrderMessage ]
        \cup [ tag : {DeleteOrderMessageCode}, body : DeleteOrderMessage ]
        \cup [ tag : {ExecutionMessageCode}, body : ExecutionMessage ]
        \cup [ tag : {AddOrderRefreshMessageCode}, body : AddOrderRefreshMessage ]
        \cup [ tag : {AttributedAddOrderRefreshMessageCode}, body : AttributedAddOrderRefreshMessage ]
        \cup [ tag : {ImbalanceMessageCode}, body : ImbalanceMessage ]

EncodePayload(message) ==
    CASE message.tag = AddOrderMessageCode -> EncodeAddOrderMessage(message.body)
      [] message.tag = AttributedAddOrderMessageCode -> EncodeAttributedAddOrderMessage(message.body)
      [] message.tag = ModifyOrderMessageCode -> EncodeModifyOrderMessage(message.body)
      [] message.tag = DeleteOrderMessageCode -> EncodeDeleteOrderMessage(message.body)
      [] message.tag = ExecutionMessageCode -> EncodeExecutionMessage(message.body)
      [] message.tag = AddOrderRefreshMessageCode -> EncodeAddOrderRefreshMessage(message.body)
      [] message.tag = AttributedAddOrderRefreshMessageCode -> EncodeAttributedAddOrderRefreshMessage(message.body)
      [] message.tag = ImbalanceMessageCode -> EncodeImbalanceMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = AddOrderMessageCode -> DecodeAddOrderMessage(bytes)
              [] tag = AttributedAddOrderMessageCode -> DecodeAttributedAddOrderMessage(bytes)
              [] tag = ModifyOrderMessageCode -> DecodeModifyOrderMessage(bytes)
              [] tag = DeleteOrderMessageCode -> DecodeDeleteOrderMessage(bytes)
              [] tag = ExecutionMessageCode -> DecodeExecutionMessage(bytes)
              [] tag = AddOrderRefreshMessageCode -> DecodeAddOrderRefreshMessage(bytes)
              [] tag = AttributedAddOrderRefreshMessageCode -> DecodeAttributedAddOrderRefreshMessage(bytes)
              [] tag = ImbalanceMessageCode -> DecodeImbalanceMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> AddOrderMessageCode, body |-> ZeroAddOrderMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> AddOrderMessageCode, body |-> one] : one \in CheckedAddOrderMessage }
        \cup { [tag |-> AttributedAddOrderMessageCode, body |-> one] : one \in CheckedAttributedAddOrderMessage }
        \cup { [tag |-> ModifyOrderMessageCode, body |-> one] : one \in CheckedModifyOrderMessage }
        \cup { [tag |-> DeleteOrderMessageCode, body |-> one] : one \in CheckedDeleteOrderMessage }
        \cup { [tag |-> ExecutionMessageCode, body |-> one] : one \in CheckedExecutionMessage }
        \cup { [tag |-> AddOrderRefreshMessageCode, body |-> one] : one \in CheckedAddOrderRefreshMessage }
        \cup { [tag |-> AttributedAddOrderRefreshMessageCode, body |-> one] : one \in CheckedAttributedAddOrderRefreshMessage }
        \cup { [tag |-> ImbalanceMessageCode, body |-> one] : one \in CheckedImbalanceMessage }

(***************************************************************************)
(* Message, framed by Message Size                                         *)
(***************************************************************************)

Message ==
    [ payload : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntLE(message.payload.tag, 2)
        \o EncodePayload(message.payload)

(* Message Size counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntLE(bytes, 2) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> AddOrderMessageCode, body |-> ZeroAddOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AttributedAddOrderMessageCode, body |-> ZeroAttributedAddOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ModifyOrderMessageCode, body |-> ZeroModifyOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> DeleteOrderMessageCode, body |-> ZeroDeleteOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ExecutionMessageCode, body |-> ZeroExecutionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddOrderRefreshMessageCode, body |-> ZeroAddOrderRefreshMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AttributedAddOrderRefreshMessageCode, body |-> ZeroAttributedAddOrderRefreshMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ImbalanceMessageCode, body |-> ZeroImbalanceMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ packetSize     : Sample(2),
      deliveryFlag   : Sample(1),
      sequenceNumber : Sample(4),
      sendTime       : SendTime,
      message        : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.packetSize
        \o message.deliveryFlag
        \o EncodeUIntLE(Len(message.message), 1)
        \o message.sequenceNumber
        \o EncodeSendTime(message.sendTime)
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET packetSize == ReadBytes(bytes, 2) IN IF ~packetSize.ok THEN Fail ELSE
    LET deliveryFlag == ReadBytes(packetSize.rest, 1) IN IF ~deliveryFlag.ok THEN Fail ELSE
    LET messageCount == ReadUIntLE(deliveryFlag.rest, 1) IN IF ~messageCount.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(messageCount.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET sendTime == DecodeSendTime(sequenceNumber.rest) IN IF ~sendTime.ok THEN Fail ELSE
    LET message == ReadMessageList(sendTime.rest, messageCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ packetSize     |-> packetSize.value,
         deliveryFlag   |-> deliveryFlag.value,
         sequenceNumber |-> sequenceNumber.value,
         sendTime       |-> sendTime.value,
         message        |-> message.value ], message.rest)

ZeroPacket ==
    [ packetSize     |-> [i \in 1 .. 2 |-> 0],
      deliveryFlag   |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber |-> [i \in 1 .. 4 |-> 0],
      sendTime       |-> ZeroSendTime,
      message        |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.packetSize = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.deliveryFlag = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.sendTime = one] : one \in CheckedSendTime }
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

(* Every Send Time decodes back to what was encoded, and leaves nothing over *)
RoundTripSendTime ==
    \A message \in CheckedSendTime :
        LET read == DecodeSendTime(EncodeSendTime(message))
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

(* Every Attributed Add Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAttributedAddOrderMessage ==
    \A message \in CheckedAttributedAddOrderMessage :
        LET read == DecodeAttributedAddOrderMessage(EncodeAttributedAddOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyOrderMessage ==
    \A message \in CheckedModifyOrderMessage :
        LET read == DecodeModifyOrderMessage(EncodeModifyOrderMessage(message))
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

(* Every Execution Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionMessage ==
    \A message \in CheckedExecutionMessage :
        LET read == DecodeExecutionMessage(EncodeExecutionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Order Refresh Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderRefreshMessage ==
    \A message \in CheckedAddOrderRefreshMessage :
        LET read == DecodeAddOrderRefreshMessage(EncodeAddOrderRefreshMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Attributed Add Order Refresh Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAttributedAddOrderRefreshMessage ==
    \A message \in CheckedAttributedAddOrderRefreshMessage :
        LET read == DecodeAttributedAddOrderRefreshMessage(EncodeAttributedAddOrderRefreshMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Imbalance Message decodes back to what was encoded, and leaves nothing over *)
RoundTripImbalanceMessage ==
    \A message \in CheckedImbalanceMessage :
        LET read == DecodeImbalanceMessage(EncodeImbalanceMessage(message))
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

(* Message Size is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
