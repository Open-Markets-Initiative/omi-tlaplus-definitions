------------------- MODULE Lseg_Millennium_Level2_v11_9 --------------------
(***************************************************************************)
(* London Stock Exchange Level 2 v11.9                                     *)
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
(* Note: Symbol Status Flags is a bit field set, checked as its 1 byte     *)
(* rather than bit by bit.                                                 *)
(*                                                                         *)
(* Note: Add Order Flags is a bit field set, checked as its 1 byte rather  *)
(* than bit by bit.                                                        *)
(*                                                                         *)
(* Note: Add Attributed Order Flags is a bit field set, checked as its 1   *)
(* byte rather than bit by bit.                                            *)
(*                                                                         *)
(* Note: Order Deleted Flags is a bit field set, checked as its 1 byte     *)
(* rather than bit by bit.                                                 *)
(*                                                                         *)
(* Note: Order Modified Flags is a bit field set, checked as its 1 byte    *)
(* rather than bit by bit.                                                 *)
(*                                                                         *)
(* Note: Order Book Clear Flags is a bit field set, checked as its 1 byte  *)
(* rather than bit by bit.                                                 *)
(*                                                                         *)
(* Note: Pt Mod Flags is a bit field set, checked as its 1 byte rather     *)
(* than bit by bit.                                                        *)
(*                                                                         *)
(* Note: Statistics Reserved is a bit field set, checked as its 1 byte     *)
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
    [ seconds : Sample(4) ]

EncodeTimeMessage(message) ==
    message.seconds

DecodeTimeMessage(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    Ok([ seconds |-> seconds.value ], seconds.rest)

ZeroTimeMessage ==
    [ seconds |-> [i \in 1 .. 4 |-> 0] ]

(* Time Message at zero, then each field in turn at the values it is checked at *)
CheckedTimeMessage ==
    { ZeroTimeMessage }
        \cup { [ZeroTimeMessage EXCEPT !.seconds = one] : one \in Sample(4) }

(***************************************************************************)
(* System Event Message: 5 bytes                                           *)
(***************************************************************************)

SystemEventMessage ==
    [ nanosecond : Sample(4),
      eventCode  : Sample(1) ]

EncodeSystemEventMessage(message) ==
    message.nanosecond
        \o message.eventCode

DecodeSystemEventMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET eventCode == ReadBytes(nanosecond.rest, 1) IN IF ~eventCode.ok THEN Fail ELSE
    Ok([ nanosecond |-> nanosecond.value,
         eventCode  |-> eventCode.value ], eventCode.rest)

ZeroSystemEventMessage ==
    [ nanosecond |-> [i \in 1 .. 4 |-> 0],
      eventCode  |-> [i \in 1 .. 1 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Symbol Directory Message: 63 bytes                                      *)
(***************************************************************************)

SymbolDirectoryMessage ==
    [ nanosecond         : Sample(4),
      instrumentId       : Sample(4),
      reservedA          : Sample(1),
      reservedB          : Sample(1),
      symbolStatus       : Sample(1),
      isin               : Sample(12),
      sedol              : Sample(12),
      segment            : Sample(6),
      underlying         : Sample(6),
      currency           : Sample(3),
      reservedByte       : Sample(1),
      reserved4          : Sample(4),
      previousClosePrice : Sample(8) ]

EncodeSymbolDirectoryMessage(message) ==
    message.nanosecond
        \o message.instrumentId
        \o message.reservedA
        \o message.reservedB
        \o message.symbolStatus
        \o message.isin
        \o message.sedol
        \o message.segment
        \o message.underlying
        \o message.currency
        \o message.reservedByte
        \o message.reserved4
        \o message.previousClosePrice

DecodeSymbolDirectoryMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(nanosecond.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET reservedA == ReadBytes(instrumentId.rest, 1) IN IF ~reservedA.ok THEN Fail ELSE
    LET reservedB == ReadBytes(reservedA.rest, 1) IN IF ~reservedB.ok THEN Fail ELSE
    LET symbolStatus == ReadBytes(reservedB.rest, 1) IN IF ~symbolStatus.ok THEN Fail ELSE
    LET isin == ReadBytes(symbolStatus.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET sedol == ReadBytes(isin.rest, 12) IN IF ~sedol.ok THEN Fail ELSE
    LET segment == ReadBytes(sedol.rest, 6) IN IF ~segment.ok THEN Fail ELSE
    LET underlying == ReadBytes(segment.rest, 6) IN IF ~underlying.ok THEN Fail ELSE
    LET currency == ReadBytes(underlying.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET reservedByte == ReadBytes(currency.rest, 1) IN IF ~reservedByte.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(reservedByte.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET previousClosePrice == ReadBytes(reserved4.rest, 8) IN IF ~previousClosePrice.ok THEN Fail ELSE
    Ok([ nanosecond         |-> nanosecond.value,
         instrumentId       |-> instrumentId.value,
         reservedA          |-> reservedA.value,
         reservedB          |-> reservedB.value,
         symbolStatus       |-> symbolStatus.value,
         isin               |-> isin.value,
         sedol              |-> sedol.value,
         segment            |-> segment.value,
         underlying         |-> underlying.value,
         currency           |-> currency.value,
         reservedByte       |-> reservedByte.value,
         reserved4          |-> reserved4.value,
         previousClosePrice |-> previousClosePrice.value ], previousClosePrice.rest)

ZeroSymbolDirectoryMessage ==
    [ nanosecond         |-> [i \in 1 .. 4 |-> 0],
      instrumentId       |-> [i \in 1 .. 4 |-> 0],
      reservedA          |-> [i \in 1 .. 1 |-> 0],
      reservedB          |-> [i \in 1 .. 1 |-> 0],
      symbolStatus       |-> [i \in 1 .. 1 |-> 0],
      isin               |-> [i \in 1 .. 12 |-> 0],
      sedol              |-> [i \in 1 .. 12 |-> 0],
      segment            |-> [i \in 1 .. 6 |-> 0],
      underlying         |-> [i \in 1 .. 6 |-> 0],
      currency           |-> [i \in 1 .. 3 |-> 0],
      reservedByte       |-> [i \in 1 .. 1 |-> 0],
      reserved4          |-> [i \in 1 .. 4 |-> 0],
      previousClosePrice |-> [i \in 1 .. 8 |-> 0] ]

(* Symbol Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedSymbolDirectoryMessage ==
    { ZeroSymbolDirectoryMessage }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.reservedA = one] : one \in Sample(1) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.reservedB = one] : one \in Sample(1) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.symbolStatus = one] : one \in Sample(1) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.sedol = one] : one \in Sample(12) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.segment = one] : one \in Sample(6) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.underlying = one] : one \in Sample(6) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.reservedByte = one] : one \in Sample(1) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.previousClosePrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Symbol Status Message: 26 bytes                                         *)
(***************************************************************************)

SymbolStatusMessage ==
    [ nanosecond          : Sample(4),
      instrumentId        : Sample(4),
      reservedA           : Sample(1),
      reservedB           : Sample(1),
      tradingStatus       : Sample(1),
      symbolStatusFlags   : Sample(1),
      reason              : Sample(4),
      sessionChangeReason : Sample(1),
      newEndTime          : Sample(8),
      bookType            : Sample(1) ]

EncodeSymbolStatusMessage(message) ==
    message.nanosecond
        \o message.instrumentId
        \o message.reservedA
        \o message.reservedB
        \o message.tradingStatus
        \o message.symbolStatusFlags
        \o message.reason
        \o message.sessionChangeReason
        \o message.newEndTime
        \o message.bookType

DecodeSymbolStatusMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(nanosecond.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET reservedA == ReadBytes(instrumentId.rest, 1) IN IF ~reservedA.ok THEN Fail ELSE
    LET reservedB == ReadBytes(reservedA.rest, 1) IN IF ~reservedB.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(reservedB.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET symbolStatusFlags == ReadBytes(tradingStatus.rest, 1) IN IF ~symbolStatusFlags.ok THEN Fail ELSE
    LET reason == ReadBytes(symbolStatusFlags.rest, 4) IN IF ~reason.ok THEN Fail ELSE
    LET sessionChangeReason == ReadBytes(reason.rest, 1) IN IF ~sessionChangeReason.ok THEN Fail ELSE
    LET newEndTime == ReadBytes(sessionChangeReason.rest, 8) IN IF ~newEndTime.ok THEN Fail ELSE
    LET bookType == ReadBytes(newEndTime.rest, 1) IN IF ~bookType.ok THEN Fail ELSE
    Ok([ nanosecond          |-> nanosecond.value,
         instrumentId        |-> instrumentId.value,
         reservedA           |-> reservedA.value,
         reservedB           |-> reservedB.value,
         tradingStatus       |-> tradingStatus.value,
         symbolStatusFlags   |-> symbolStatusFlags.value,
         reason              |-> reason.value,
         sessionChangeReason |-> sessionChangeReason.value,
         newEndTime          |-> newEndTime.value,
         bookType            |-> bookType.value ], bookType.rest)

ZeroSymbolStatusMessage ==
    [ nanosecond          |-> [i \in 1 .. 4 |-> 0],
      instrumentId        |-> [i \in 1 .. 4 |-> 0],
      reservedA           |-> [i \in 1 .. 1 |-> 0],
      reservedB           |-> [i \in 1 .. 1 |-> 0],
      tradingStatus       |-> [i \in 1 .. 1 |-> 0],
      symbolStatusFlags   |-> [i \in 1 .. 1 |-> 0],
      reason              |-> [i \in 1 .. 4 |-> 0],
      sessionChangeReason |-> [i \in 1 .. 1 |-> 0],
      newEndTime          |-> [i \in 1 .. 8 |-> 0],
      bookType            |-> [i \in 1 .. 1 |-> 0] ]

(* Symbol Status Message at zero, then each field in turn at the values it is checked at *)
CheckedSymbolStatusMessage ==
    { ZeroSymbolStatusMessage }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.reservedA = one] : one \in Sample(1) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.reservedB = one] : one \in Sample(1) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.symbolStatusFlags = one] : one \in Sample(1) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.reason = one] : one \in Sample(4) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.sessionChangeReason = one] : one \in Sample(1) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.newEndTime = one] : one \in Sample(8) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.bookType = one] : one \in Sample(1) }

(***************************************************************************)
(* Add Order Message: 42 bytes                                             *)
(***************************************************************************)

AddOrderMessage ==
    [ nanosecond    : Sample(4),
      orderId       : Sample(8),
      side          : Sample(1),
      quantity      : Sample(4),
      instrumentId  : Sample(4),
      reservedA     : Sample(1),
      reservedB     : Sample(1),
      price         : Sample(8),
      addOrderFlags : Sample(1),
      reserved10    : Sample(10) ]

EncodeAddOrderMessage(message) ==
    message.nanosecond
        \o message.orderId
        \o message.side
        \o message.quantity
        \o message.instrumentId
        \o message.reservedA
        \o message.reservedB
        \o message.price
        \o message.addOrderFlags
        \o message.reserved10

DecodeAddOrderMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET orderId == ReadBytes(nanosecond.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET side == ReadBytes(orderId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET quantity == ReadBytes(side.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(quantity.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET reservedA == ReadBytes(instrumentId.rest, 1) IN IF ~reservedA.ok THEN Fail ELSE
    LET reservedB == ReadBytes(reservedA.rest, 1) IN IF ~reservedB.ok THEN Fail ELSE
    LET price == ReadBytes(reservedB.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET addOrderFlags == ReadBytes(price.rest, 1) IN IF ~addOrderFlags.ok THEN Fail ELSE
    LET reserved10 == ReadBytes(addOrderFlags.rest, 10) IN IF ~reserved10.ok THEN Fail ELSE
    Ok([ nanosecond    |-> nanosecond.value,
         orderId       |-> orderId.value,
         side          |-> side.value,
         quantity      |-> quantity.value,
         instrumentId  |-> instrumentId.value,
         reservedA     |-> reservedA.value,
         reservedB     |-> reservedB.value,
         price         |-> price.value,
         addOrderFlags |-> addOrderFlags.value,
         reserved10    |-> reserved10.value ], reserved10.rest)

ZeroAddOrderMessage ==
    [ nanosecond    |-> [i \in 1 .. 4 |-> 0],
      orderId       |-> [i \in 1 .. 8 |-> 0],
      side          |-> [i \in 1 .. 1 |-> 0],
      quantity      |-> [i \in 1 .. 4 |-> 0],
      instrumentId  |-> [i \in 1 .. 4 |-> 0],
      reservedA     |-> [i \in 1 .. 1 |-> 0],
      reservedB     |-> [i \in 1 .. 1 |-> 0],
      price         |-> [i \in 1 .. 8 |-> 0],
      addOrderFlags |-> [i \in 1 .. 1 |-> 0],
      reserved10    |-> [i \in 1 .. 10 |-> 0] ]

(* Add Order Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderMessage ==
    { ZeroAddOrderMessage }
        \cup { [ZeroAddOrderMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.reservedA = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.reservedB = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessage EXCEPT !.addOrderFlags = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.reserved10 = one] : one \in Sample(10) }

(***************************************************************************)
(* Add Attributed Order Message: 43 bytes                                  *)
(***************************************************************************)

AddAttributedOrderMessage ==
    [ nanosecond              : Sample(4),
      orderId                 : Sample(8),
      side                    : Sample(1),
      quantity                : Sample(4),
      instrumentId            : Sample(4),
      reservedA               : Sample(1),
      reservedB               : Sample(1),
      price                   : Sample(8),
      attribution             : Sample(11),
      addAttributedOrderFlags : Sample(1) ]

EncodeAddAttributedOrderMessage(message) ==
    message.nanosecond
        \o message.orderId
        \o message.side
        \o message.quantity
        \o message.instrumentId
        \o message.reservedA
        \o message.reservedB
        \o message.price
        \o message.attribution
        \o message.addAttributedOrderFlags

DecodeAddAttributedOrderMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET orderId == ReadBytes(nanosecond.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET side == ReadBytes(orderId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET quantity == ReadBytes(side.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(quantity.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET reservedA == ReadBytes(instrumentId.rest, 1) IN IF ~reservedA.ok THEN Fail ELSE
    LET reservedB == ReadBytes(reservedA.rest, 1) IN IF ~reservedB.ok THEN Fail ELSE
    LET price == ReadBytes(reservedB.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET attribution == ReadBytes(price.rest, 11) IN IF ~attribution.ok THEN Fail ELSE
    LET addAttributedOrderFlags == ReadBytes(attribution.rest, 1) IN IF ~addAttributedOrderFlags.ok THEN Fail ELSE
    Ok([ nanosecond              |-> nanosecond.value,
         orderId                 |-> orderId.value,
         side                    |-> side.value,
         quantity                |-> quantity.value,
         instrumentId            |-> instrumentId.value,
         reservedA               |-> reservedA.value,
         reservedB               |-> reservedB.value,
         price                   |-> price.value,
         attribution             |-> attribution.value,
         addAttributedOrderFlags |-> addAttributedOrderFlags.value ], addAttributedOrderFlags.rest)

ZeroAddAttributedOrderMessage ==
    [ nanosecond              |-> [i \in 1 .. 4 |-> 0],
      orderId                 |-> [i \in 1 .. 8 |-> 0],
      side                    |-> [i \in 1 .. 1 |-> 0],
      quantity                |-> [i \in 1 .. 4 |-> 0],
      instrumentId            |-> [i \in 1 .. 4 |-> 0],
      reservedA               |-> [i \in 1 .. 1 |-> 0],
      reservedB               |-> [i \in 1 .. 1 |-> 0],
      price                   |-> [i \in 1 .. 8 |-> 0],
      attribution             |-> [i \in 1 .. 11 |-> 0],
      addAttributedOrderFlags |-> [i \in 1 .. 1 |-> 0] ]

(* Add Attributed Order Message at zero, then each field in turn at the values it is checked at *)
CheckedAddAttributedOrderMessage ==
    { ZeroAddAttributedOrderMessage }
        \cup { [ZeroAddAttributedOrderMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroAddAttributedOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddAttributedOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAddAttributedOrderMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroAddAttributedOrderMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroAddAttributedOrderMessage EXCEPT !.reservedA = one] : one \in Sample(1) }
        \cup { [ZeroAddAttributedOrderMessage EXCEPT !.reservedB = one] : one \in Sample(1) }
        \cup { [ZeroAddAttributedOrderMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAddAttributedOrderMessage EXCEPT !.attribution = one] : one \in Sample(11) }
        \cup { [ZeroAddAttributedOrderMessage EXCEPT !.addAttributedOrderFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Deleted Message: 17 bytes                                         *)
(***************************************************************************)

OrderDeletedMessage ==
    [ nanosecond        : Sample(4),
      orderId           : Sample(8),
      orderDeletedFlags : Sample(1),
      instrumentId      : Sample(4) ]

EncodeOrderDeletedMessage(message) ==
    message.nanosecond
        \o message.orderId
        \o message.orderDeletedFlags
        \o message.instrumentId

DecodeOrderDeletedMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET orderId == ReadBytes(nanosecond.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET orderDeletedFlags == ReadBytes(orderId.rest, 1) IN IF ~orderDeletedFlags.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(orderDeletedFlags.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    Ok([ nanosecond        |-> nanosecond.value,
         orderId           |-> orderId.value,
         orderDeletedFlags |-> orderDeletedFlags.value,
         instrumentId      |-> instrumentId.value ], instrumentId.rest)

ZeroOrderDeletedMessage ==
    [ nanosecond        |-> [i \in 1 .. 4 |-> 0],
      orderId           |-> [i \in 1 .. 8 |-> 0],
      orderDeletedFlags |-> [i \in 1 .. 1 |-> 0],
      instrumentId      |-> [i \in 1 .. 4 |-> 0] ]

(* Order Deleted Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderDeletedMessage ==
    { ZeroOrderDeletedMessage }
        \cup { [ZeroOrderDeletedMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroOrderDeletedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderDeletedMessage EXCEPT !.orderDeletedFlags = one] : one \in Sample(1) }
        \cup { [ZeroOrderDeletedMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Modified Message: 25 bytes                                        *)
(***************************************************************************)

OrderModifiedMessage ==
    [ nanosecond         : Sample(4),
      orderId            : Sample(8),
      newQuantity        : Sample(4),
      newPrice           : Sample(8),
      orderModifiedFlags : Sample(1) ]

EncodeOrderModifiedMessage(message) ==
    message.nanosecond
        \o message.orderId
        \o message.newQuantity
        \o message.newPrice
        \o message.orderModifiedFlags

DecodeOrderModifiedMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET orderId == ReadBytes(nanosecond.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET newQuantity == ReadBytes(orderId.rest, 4) IN IF ~newQuantity.ok THEN Fail ELSE
    LET newPrice == ReadBytes(newQuantity.rest, 8) IN IF ~newPrice.ok THEN Fail ELSE
    LET orderModifiedFlags == ReadBytes(newPrice.rest, 1) IN IF ~orderModifiedFlags.ok THEN Fail ELSE
    Ok([ nanosecond         |-> nanosecond.value,
         orderId            |-> orderId.value,
         newQuantity        |-> newQuantity.value,
         newPrice           |-> newPrice.value,
         orderModifiedFlags |-> orderModifiedFlags.value ], orderModifiedFlags.rest)

ZeroOrderModifiedMessage ==
    [ nanosecond         |-> [i \in 1 .. 4 |-> 0],
      orderId            |-> [i \in 1 .. 8 |-> 0],
      newQuantity        |-> [i \in 1 .. 4 |-> 0],
      newPrice           |-> [i \in 1 .. 8 |-> 0],
      orderModifiedFlags |-> [i \in 1 .. 1 |-> 0] ]

(* Order Modified Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderModifiedMessage ==
    { ZeroOrderModifiedMessage }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.newQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.newPrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.orderModifiedFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Book Clear Message: 11 bytes                                      *)
(***************************************************************************)

OrderBookClearMessage ==
    [ nanosecond          : Sample(4),
      instrumentId        : Sample(4),
      reservedA           : Sample(1),
      reservedB           : Sample(1),
      orderBookClearFlags : Sample(1) ]

EncodeOrderBookClearMessage(message) ==
    message.nanosecond
        \o message.instrumentId
        \o message.reservedA
        \o message.reservedB
        \o message.orderBookClearFlags

DecodeOrderBookClearMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(nanosecond.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET reservedA == ReadBytes(instrumentId.rest, 1) IN IF ~reservedA.ok THEN Fail ELSE
    LET reservedB == ReadBytes(reservedA.rest, 1) IN IF ~reservedB.ok THEN Fail ELSE
    LET orderBookClearFlags == ReadBytes(reservedB.rest, 1) IN IF ~orderBookClearFlags.ok THEN Fail ELSE
    Ok([ nanosecond          |-> nanosecond.value,
         instrumentId        |-> instrumentId.value,
         reservedA           |-> reservedA.value,
         reservedB           |-> reservedB.value,
         orderBookClearFlags |-> orderBookClearFlags.value ], orderBookClearFlags.rest)

ZeroOrderBookClearMessage ==
    [ nanosecond          |-> [i \in 1 .. 4 |-> 0],
      instrumentId        |-> [i \in 1 .. 4 |-> 0],
      reservedA           |-> [i \in 1 .. 1 |-> 0],
      reservedB           |-> [i \in 1 .. 1 |-> 0],
      orderBookClearFlags |-> [i \in 1 .. 1 |-> 0] ]

(* Order Book Clear Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderBookClearMessage ==
    { ZeroOrderBookClearMessage }
        \cup { [ZeroOrderBookClearMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookClearMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookClearMessage EXCEPT !.reservedA = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookClearMessage EXCEPT !.reservedB = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookClearMessage EXCEPT !.orderBookClearFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Executed Message: 24 bytes                                        *)
(***************************************************************************)

OrderExecutedMessage ==
    [ nanosecond       : Sample(4),
      orderId          : Sample(8),
      executedQuantity : Sample(4),
      tradeMatchId     : Sample(8) ]

EncodeOrderExecutedMessage(message) ==
    message.nanosecond
        \o message.orderId
        \o message.executedQuantity
        \o message.tradeMatchId

DecodeOrderExecutedMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET orderId == ReadBytes(nanosecond.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(orderId.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET tradeMatchId == ReadBytes(executedQuantity.rest, 8) IN IF ~tradeMatchId.ok THEN Fail ELSE
    Ok([ nanosecond       |-> nanosecond.value,
         orderId          |-> orderId.value,
         executedQuantity |-> executedQuantity.value,
         tradeMatchId     |-> tradeMatchId.value ], tradeMatchId.rest)

ZeroOrderExecutedMessage ==
    [ nanosecond       |-> [i \in 1 .. 4 |-> 0],
      orderId          |-> [i \in 1 .. 8 |-> 0],
      executedQuantity |-> [i \in 1 .. 4 |-> 0],
      tradeMatchId     |-> [i \in 1 .. 8 |-> 0] ]

(* Order Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedMessage ==
    { ZeroOrderExecutedMessage }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.tradeMatchId = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Executed With Price Size Message: 37 bytes                        *)
(***************************************************************************)

OrderExecutedWithPriceSizeMessage ==
    [ nanosecond       : Sample(4),
      orderId          : Sample(8),
      executedQuantity : Sample(4),
      displayQuantity  : Sample(4),
      tradeMatchId     : Sample(8),
      printable        : Sample(1),
      price            : Sample(8) ]

EncodeOrderExecutedWithPriceSizeMessage(message) ==
    message.nanosecond
        \o message.orderId
        \o message.executedQuantity
        \o message.displayQuantity
        \o message.tradeMatchId
        \o message.printable
        \o message.price

DecodeOrderExecutedWithPriceSizeMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET orderId == ReadBytes(nanosecond.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(orderId.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET displayQuantity == ReadBytes(executedQuantity.rest, 4) IN IF ~displayQuantity.ok THEN Fail ELSE
    LET tradeMatchId == ReadBytes(displayQuantity.rest, 8) IN IF ~tradeMatchId.ok THEN Fail ELSE
    LET printable == ReadBytes(tradeMatchId.rest, 1) IN IF ~printable.ok THEN Fail ELSE
    LET price == ReadBytes(printable.rest, 8) IN IF ~price.ok THEN Fail ELSE
    Ok([ nanosecond       |-> nanosecond.value,
         orderId          |-> orderId.value,
         executedQuantity |-> executedQuantity.value,
         displayQuantity  |-> displayQuantity.value,
         tradeMatchId     |-> tradeMatchId.value,
         printable        |-> printable.value,
         price            |-> price.value ], price.rest)

ZeroOrderExecutedWithPriceSizeMessage ==
    [ nanosecond       |-> [i \in 1 .. 4 |-> 0],
      orderId          |-> [i \in 1 .. 8 |-> 0],
      executedQuantity |-> [i \in 1 .. 4 |-> 0],
      displayQuantity  |-> [i \in 1 .. 4 |-> 0],
      tradeMatchId     |-> [i \in 1 .. 8 |-> 0],
      printable        |-> [i \in 1 .. 1 |-> 0],
      price            |-> [i \in 1 .. 8 |-> 0] ]

(* Order Executed With Price Size Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedWithPriceSizeMessage ==
    { ZeroOrderExecutedWithPriceSizeMessage }
        \cup { [ZeroOrderExecutedWithPriceSizeMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceSizeMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedWithPriceSizeMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceSizeMessage EXCEPT !.displayQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceSizeMessage EXCEPT !.tradeMatchId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedWithPriceSizeMessage EXCEPT !.printable = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutedWithPriceSizeMessage EXCEPT !.price = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Message: 33 bytes                                                 *)
(***************************************************************************)

TradeMessage ==
    [ nanosecond       : Sample(4),
      executedQuantity : Sample(4),
      instrumentId     : Sample(4),
      reservedA        : Sample(1),
      reservedB        : Sample(1),
      price            : Sample(8),
      tradeMatchId     : Sample(8),
      crossType        : Sample(1),
      subBook          : Sample(1),
      ptModFlags       : Sample(1) ]

EncodeTradeMessage(message) ==
    message.nanosecond
        \o message.executedQuantity
        \o message.instrumentId
        \o message.reservedA
        \o message.reservedB
        \o message.price
        \o message.tradeMatchId
        \o message.crossType
        \o message.subBook
        \o message.ptModFlags

DecodeTradeMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(nanosecond.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(executedQuantity.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET reservedA == ReadBytes(instrumentId.rest, 1) IN IF ~reservedA.ok THEN Fail ELSE
    LET reservedB == ReadBytes(reservedA.rest, 1) IN IF ~reservedB.ok THEN Fail ELSE
    LET price == ReadBytes(reservedB.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET tradeMatchId == ReadBytes(price.rest, 8) IN IF ~tradeMatchId.ok THEN Fail ELSE
    LET crossType == ReadBytes(tradeMatchId.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET subBook == ReadBytes(crossType.rest, 1) IN IF ~subBook.ok THEN Fail ELSE
    LET ptModFlags == ReadBytes(subBook.rest, 1) IN IF ~ptModFlags.ok THEN Fail ELSE
    Ok([ nanosecond       |-> nanosecond.value,
         executedQuantity |-> executedQuantity.value,
         instrumentId     |-> instrumentId.value,
         reservedA        |-> reservedA.value,
         reservedB        |-> reservedB.value,
         price            |-> price.value,
         tradeMatchId     |-> tradeMatchId.value,
         crossType        |-> crossType.value,
         subBook          |-> subBook.value,
         ptModFlags       |-> ptModFlags.value ], ptModFlags.rest)

ZeroTradeMessage ==
    [ nanosecond       |-> [i \in 1 .. 4 |-> 0],
      executedQuantity |-> [i \in 1 .. 4 |-> 0],
      instrumentId     |-> [i \in 1 .. 4 |-> 0],
      reservedA        |-> [i \in 1 .. 1 |-> 0],
      reservedB        |-> [i \in 1 .. 1 |-> 0],
      price            |-> [i \in 1 .. 8 |-> 0],
      tradeMatchId     |-> [i \in 1 .. 8 |-> 0],
      crossType        |-> [i \in 1 .. 1 |-> 0],
      subBook          |-> [i \in 1 .. 1 |-> 0],
      ptModFlags       |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.reservedA = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.reservedB = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeMatchId = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.subBook = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.ptModFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Auction Trade Message: 32 bytes                                         *)
(***************************************************************************)

AuctionTradeMessage ==
    [ nanosecond   : Sample(4),
      quantity     : Sample(4),
      instrumentId : Sample(4),
      reservedA    : Sample(1),
      reservedB    : Sample(1),
      price        : Sample(8),
      tradeMatchId : Sample(8),
      auctionType  : Sample(1),
      ptModFlags   : Sample(1) ]

EncodeAuctionTradeMessage(message) ==
    message.nanosecond
        \o message.quantity
        \o message.instrumentId
        \o message.reservedA
        \o message.reservedB
        \o message.price
        \o message.tradeMatchId
        \o message.auctionType
        \o message.ptModFlags

DecodeAuctionTradeMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET quantity == ReadBytes(nanosecond.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(quantity.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET reservedA == ReadBytes(instrumentId.rest, 1) IN IF ~reservedA.ok THEN Fail ELSE
    LET reservedB == ReadBytes(reservedA.rest, 1) IN IF ~reservedB.ok THEN Fail ELSE
    LET price == ReadBytes(reservedB.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET tradeMatchId == ReadBytes(price.rest, 8) IN IF ~tradeMatchId.ok THEN Fail ELSE
    LET auctionType == ReadBytes(tradeMatchId.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET ptModFlags == ReadBytes(auctionType.rest, 1) IN IF ~ptModFlags.ok THEN Fail ELSE
    Ok([ nanosecond   |-> nanosecond.value,
         quantity     |-> quantity.value,
         instrumentId |-> instrumentId.value,
         reservedA    |-> reservedA.value,
         reservedB    |-> reservedB.value,
         price        |-> price.value,
         tradeMatchId |-> tradeMatchId.value,
         auctionType  |-> auctionType.value,
         ptModFlags   |-> ptModFlags.value ], ptModFlags.rest)

ZeroAuctionTradeMessage ==
    [ nanosecond   |-> [i \in 1 .. 4 |-> 0],
      quantity     |-> [i \in 1 .. 4 |-> 0],
      instrumentId |-> [i \in 1 .. 4 |-> 0],
      reservedA    |-> [i \in 1 .. 1 |-> 0],
      reservedB    |-> [i \in 1 .. 1 |-> 0],
      price        |-> [i \in 1 .. 8 |-> 0],
      tradeMatchId |-> [i \in 1 .. 8 |-> 0],
      auctionType  |-> [i \in 1 .. 1 |-> 0],
      ptModFlags   |-> [i \in 1 .. 1 |-> 0] ]

(* Auction Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionTradeMessage ==
    { ZeroAuctionTradeMessage }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.reservedA = one] : one \in Sample(1) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.reservedB = one] : one \in Sample(1) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.tradeMatchId = one] : one \in Sample(8) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.ptModFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Auction Info Message: 28 bytes                                          *)
(***************************************************************************)

AuctionInfoMessage ==
    [ nanosecond     : Sample(4),
      pairedQuantity : Sample(4),
      reserved4      : Sample(4),
      reserved1      : Sample(1),
      instrumentId   : Sample(4),
      reservedA      : Sample(1),
      reservedB      : Sample(1),
      price          : Sample(8),
      auctionType    : Sample(1) ]

EncodeAuctionInfoMessage(message) ==
    message.nanosecond
        \o message.pairedQuantity
        \o message.reserved4
        \o message.reserved1
        \o message.instrumentId
        \o message.reservedA
        \o message.reservedB
        \o message.price
        \o message.auctionType

DecodeAuctionInfoMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET pairedQuantity == ReadBytes(nanosecond.rest, 4) IN IF ~pairedQuantity.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(pairedQuantity.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(reserved4.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(reserved1.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET reservedA == ReadBytes(instrumentId.rest, 1) IN IF ~reservedA.ok THEN Fail ELSE
    LET reservedB == ReadBytes(reservedA.rest, 1) IN IF ~reservedB.ok THEN Fail ELSE
    LET price == ReadBytes(reservedB.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET auctionType == ReadBytes(price.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    Ok([ nanosecond     |-> nanosecond.value,
         pairedQuantity |-> pairedQuantity.value,
         reserved4      |-> reserved4.value,
         reserved1      |-> reserved1.value,
         instrumentId   |-> instrumentId.value,
         reservedA      |-> reservedA.value,
         reservedB      |-> reservedB.value,
         price          |-> price.value,
         auctionType    |-> auctionType.value ], auctionType.rest)

ZeroAuctionInfoMessage ==
    [ nanosecond     |-> [i \in 1 .. 4 |-> 0],
      pairedQuantity |-> [i \in 1 .. 4 |-> 0],
      reserved4      |-> [i \in 1 .. 4 |-> 0],
      reserved1      |-> [i \in 1 .. 1 |-> 0],
      instrumentId   |-> [i \in 1 .. 4 |-> 0],
      reservedA      |-> [i \in 1 .. 1 |-> 0],
      reservedB      |-> [i \in 1 .. 1 |-> 0],
      price          |-> [i \in 1 .. 8 |-> 0],
      auctionType    |-> [i \in 1 .. 1 |-> 0] ]

(* Auction Info Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionInfoMessage ==
    { ZeroAuctionInfoMessage }
        \cup { [ZeroAuctionInfoMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroAuctionInfoMessage EXCEPT !.pairedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroAuctionInfoMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroAuctionInfoMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroAuctionInfoMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroAuctionInfoMessage EXCEPT !.reservedA = one] : one \in Sample(1) }
        \cup { [ZeroAuctionInfoMessage EXCEPT !.reservedB = one] : one \in Sample(1) }
        \cup { [ZeroAuctionInfoMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAuctionInfoMessage EXCEPT !.auctionType = one] : one \in Sample(1) }

(***************************************************************************)
(* Statistics Message: 21 bytes                                            *)
(***************************************************************************)

StatisticsMessage ==
    [ nanosecond              : Sample(4),
      instrumentId            : Sample(4),
      reservedA               : Sample(1),
      reservedB               : Sample(1),
      statisticType           : Sample(1),
      price                   : Sample(8),
      openClosePriceIndicator : Sample(1),
      statisticsReserved      : Sample(1) ]

EncodeStatisticsMessage(message) ==
    message.nanosecond
        \o message.instrumentId
        \o message.reservedA
        \o message.reservedB
        \o message.statisticType
        \o message.price
        \o message.openClosePriceIndicator
        \o message.statisticsReserved

DecodeStatisticsMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(nanosecond.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET reservedA == ReadBytes(instrumentId.rest, 1) IN IF ~reservedA.ok THEN Fail ELSE
    LET reservedB == ReadBytes(reservedA.rest, 1) IN IF ~reservedB.ok THEN Fail ELSE
    LET statisticType == ReadBytes(reservedB.rest, 1) IN IF ~statisticType.ok THEN Fail ELSE
    LET price == ReadBytes(statisticType.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET openClosePriceIndicator == ReadBytes(price.rest, 1) IN IF ~openClosePriceIndicator.ok THEN Fail ELSE
    LET statisticsReserved == ReadBytes(openClosePriceIndicator.rest, 1) IN IF ~statisticsReserved.ok THEN Fail ELSE
    Ok([ nanosecond              |-> nanosecond.value,
         instrumentId            |-> instrumentId.value,
         reservedA               |-> reservedA.value,
         reservedB               |-> reservedB.value,
         statisticType           |-> statisticType.value,
         price                   |-> price.value,
         openClosePriceIndicator |-> openClosePriceIndicator.value,
         statisticsReserved      |-> statisticsReserved.value ], statisticsReserved.rest)

ZeroStatisticsMessage ==
    [ nanosecond              |-> [i \in 1 .. 4 |-> 0],
      instrumentId            |-> [i \in 1 .. 4 |-> 0],
      reservedA               |-> [i \in 1 .. 1 |-> 0],
      reservedB               |-> [i \in 1 .. 1 |-> 0],
      statisticType           |-> [i \in 1 .. 1 |-> 0],
      price                   |-> [i \in 1 .. 8 |-> 0],
      openClosePriceIndicator |-> [i \in 1 .. 1 |-> 0],
      statisticsReserved      |-> [i \in 1 .. 1 |-> 0] ]

(* Statistics Message at zero, then each field in turn at the values it is checked at *)
CheckedStatisticsMessage ==
    { ZeroStatisticsMessage }
        \cup { [ZeroStatisticsMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroStatisticsMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroStatisticsMessage EXCEPT !.reservedA = one] : one \in Sample(1) }
        \cup { [ZeroStatisticsMessage EXCEPT !.reservedB = one] : one \in Sample(1) }
        \cup { [ZeroStatisticsMessage EXCEPT !.statisticType = one] : one \in Sample(1) }
        \cup { [ZeroStatisticsMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsMessage EXCEPT !.openClosePriceIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStatisticsMessage EXCEPT !.statisticsReserved = one] : one \in Sample(1) }

(***************************************************************************)
(* Top Of Book Message: 32 bytes                                           *)
(***************************************************************************)

TopOfBookMessage ==
    [ nanosecond     : Sample(4),
      instrumentId   : Sample(4),
      buyLimitPrice  : Sample(8),
      buyLimitSize   : Sample(4),
      sellLimitPrice : Sample(8),
      sellLimitSize  : Sample(4) ]

EncodeTopOfBookMessage(message) ==
    message.nanosecond
        \o message.instrumentId
        \o message.buyLimitPrice
        \o message.buyLimitSize
        \o message.sellLimitPrice
        \o message.sellLimitSize

DecodeTopOfBookMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(nanosecond.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET buyLimitPrice == ReadBytes(instrumentId.rest, 8) IN IF ~buyLimitPrice.ok THEN Fail ELSE
    LET buyLimitSize == ReadBytes(buyLimitPrice.rest, 4) IN IF ~buyLimitSize.ok THEN Fail ELSE
    LET sellLimitPrice == ReadBytes(buyLimitSize.rest, 8) IN IF ~sellLimitPrice.ok THEN Fail ELSE
    LET sellLimitSize == ReadBytes(sellLimitPrice.rest, 4) IN IF ~sellLimitSize.ok THEN Fail ELSE
    Ok([ nanosecond     |-> nanosecond.value,
         instrumentId   |-> instrumentId.value,
         buyLimitPrice  |-> buyLimitPrice.value,
         buyLimitSize   |-> buyLimitSize.value,
         sellLimitPrice |-> sellLimitPrice.value,
         sellLimitSize  |-> sellLimitSize.value ], sellLimitSize.rest)

ZeroTopOfBookMessage ==
    [ nanosecond     |-> [i \in 1 .. 4 |-> 0],
      instrumentId   |-> [i \in 1 .. 4 |-> 0],
      buyLimitPrice  |-> [i \in 1 .. 8 |-> 0],
      buyLimitSize   |-> [i \in 1 .. 4 |-> 0],
      sellLimitPrice |-> [i \in 1 .. 8 |-> 0],
      sellLimitSize  |-> [i \in 1 .. 4 |-> 0] ]

(* Top Of Book Message at zero, then each field in turn at the values it is checked at *)
CheckedTopOfBookMessage ==
    { ZeroTopOfBookMessage }
        \cup { [ZeroTopOfBookMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.buyLimitPrice = one] : one \in Sample(8) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.buyLimitSize = one] : one \in Sample(4) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.sellLimitPrice = one] : one \in Sample(8) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.sellLimitSize = one] : one \in Sample(4) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

TimeMessageCode == 84  \* 0x54
SystemEventMessageCode == 83  \* 0x53
SymbolDirectoryMessageCode == 82  \* 0x52
SymbolStatusMessageCode == 72  \* 0x48
AddOrderMessageCode == 65  \* 0x41
AddAttributedOrderMessageCode == 70  \* 0x46
OrderDeletedMessageCode == 68  \* 0x44
OrderModifiedMessageCode == 85  \* 0x55
OrderBookClearMessageCode == 121  \* 0x79
OrderExecutedMessageCode == 69  \* 0x45
OrderExecutedWithPriceSizeMessageCode == 67  \* 0x43
TradeMessageCode == 80  \* 0x50
AuctionTradeMessageCode == 81  \* 0x51
AuctionInfoMessageCode == 73  \* 0x49
StatisticsMessageCode == 119  \* 0x77
TopOfBookMessageCode == 113  \* 0x71

Payload ==
    [ tag : {TimeMessageCode}, body : TimeMessage ]
        \cup [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {SymbolDirectoryMessageCode}, body : SymbolDirectoryMessage ]
        \cup [ tag : {SymbolStatusMessageCode}, body : SymbolStatusMessage ]
        \cup [ tag : {AddOrderMessageCode}, body : AddOrderMessage ]
        \cup [ tag : {AddAttributedOrderMessageCode}, body : AddAttributedOrderMessage ]
        \cup [ tag : {OrderDeletedMessageCode}, body : OrderDeletedMessage ]
        \cup [ tag : {OrderModifiedMessageCode}, body : OrderModifiedMessage ]
        \cup [ tag : {OrderBookClearMessageCode}, body : OrderBookClearMessage ]
        \cup [ tag : {OrderExecutedMessageCode}, body : OrderExecutedMessage ]
        \cup [ tag : {OrderExecutedWithPriceSizeMessageCode}, body : OrderExecutedWithPriceSizeMessage ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {AuctionTradeMessageCode}, body : AuctionTradeMessage ]
        \cup [ tag : {AuctionInfoMessageCode}, body : AuctionInfoMessage ]
        \cup [ tag : {StatisticsMessageCode}, body : StatisticsMessage ]
        \cup [ tag : {TopOfBookMessageCode}, body : TopOfBookMessage ]

EncodePayload(message) ==
    CASE message.tag = TimeMessageCode -> EncodeTimeMessage(message.body)
      [] message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = SymbolDirectoryMessageCode -> EncodeSymbolDirectoryMessage(message.body)
      [] message.tag = SymbolStatusMessageCode -> EncodeSymbolStatusMessage(message.body)
      [] message.tag = AddOrderMessageCode -> EncodeAddOrderMessage(message.body)
      [] message.tag = AddAttributedOrderMessageCode -> EncodeAddAttributedOrderMessage(message.body)
      [] message.tag = OrderDeletedMessageCode -> EncodeOrderDeletedMessage(message.body)
      [] message.tag = OrderModifiedMessageCode -> EncodeOrderModifiedMessage(message.body)
      [] message.tag = OrderBookClearMessageCode -> EncodeOrderBookClearMessage(message.body)
      [] message.tag = OrderExecutedMessageCode -> EncodeOrderExecutedMessage(message.body)
      [] message.tag = OrderExecutedWithPriceSizeMessageCode -> EncodeOrderExecutedWithPriceSizeMessage(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = AuctionTradeMessageCode -> EncodeAuctionTradeMessage(message.body)
      [] message.tag = AuctionInfoMessageCode -> EncodeAuctionInfoMessage(message.body)
      [] message.tag = StatisticsMessageCode -> EncodeStatisticsMessage(message.body)
      [] message.tag = TopOfBookMessageCode -> EncodeTopOfBookMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = TimeMessageCode -> DecodeTimeMessage(bytes)
              [] tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = SymbolDirectoryMessageCode -> DecodeSymbolDirectoryMessage(bytes)
              [] tag = SymbolStatusMessageCode -> DecodeSymbolStatusMessage(bytes)
              [] tag = AddOrderMessageCode -> DecodeAddOrderMessage(bytes)
              [] tag = AddAttributedOrderMessageCode -> DecodeAddAttributedOrderMessage(bytes)
              [] tag = OrderDeletedMessageCode -> DecodeOrderDeletedMessage(bytes)
              [] tag = OrderModifiedMessageCode -> DecodeOrderModifiedMessage(bytes)
              [] tag = OrderBookClearMessageCode -> DecodeOrderBookClearMessage(bytes)
              [] tag = OrderExecutedMessageCode -> DecodeOrderExecutedMessage(bytes)
              [] tag = OrderExecutedWithPriceSizeMessageCode -> DecodeOrderExecutedWithPriceSizeMessage(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = AuctionTradeMessageCode -> DecodeAuctionTradeMessage(bytes)
              [] tag = AuctionInfoMessageCode -> DecodeAuctionInfoMessage(bytes)
              [] tag = StatisticsMessageCode -> DecodeStatisticsMessage(bytes)
              [] tag = TopOfBookMessageCode -> DecodeTopOfBookMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> TimeMessageCode, body |-> ZeroTimeMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> TimeMessageCode, body |-> one] : one \in CheckedTimeMessage }
        \cup { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> SymbolDirectoryMessageCode, body |-> one] : one \in CheckedSymbolDirectoryMessage }
        \cup { [tag |-> SymbolStatusMessageCode, body |-> one] : one \in CheckedSymbolStatusMessage }
        \cup { [tag |-> AddOrderMessageCode, body |-> one] : one \in CheckedAddOrderMessage }
        \cup { [tag |-> AddAttributedOrderMessageCode, body |-> one] : one \in CheckedAddAttributedOrderMessage }
        \cup { [tag |-> OrderDeletedMessageCode, body |-> one] : one \in CheckedOrderDeletedMessage }
        \cup { [tag |-> OrderModifiedMessageCode, body |-> one] : one \in CheckedOrderModifiedMessage }
        \cup { [tag |-> OrderBookClearMessageCode, body |-> one] : one \in CheckedOrderBookClearMessage }
        \cup { [tag |-> OrderExecutedMessageCode, body |-> one] : one \in CheckedOrderExecutedMessage }
        \cup { [tag |-> OrderExecutedWithPriceSizeMessageCode, body |-> one] : one \in CheckedOrderExecutedWithPriceSizeMessage }
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> AuctionTradeMessageCode, body |-> one] : one \in CheckedAuctionTradeMessage }
        \cup { [tag |-> AuctionInfoMessageCode, body |-> one] : one \in CheckedAuctionInfoMessage }
        \cup { [tag |-> StatisticsMessageCode, body |-> one] : one \in CheckedStatisticsMessage }
        \cup { [tag |-> TopOfBookMessageCode, body |-> one] : one \in CheckedTopOfBookMessage }

(***************************************************************************)
(* Message, framed by Message Length                                       *)
(***************************************************************************)

Message ==
    [ payload : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntBE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntLE(Len(body) + 1, 1) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
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
      [ZeroMessage EXCEPT !.payload = [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SymbolDirectoryMessageCode, body |-> ZeroSymbolDirectoryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SymbolStatusMessageCode, body |-> ZeroSymbolStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddOrderMessageCode, body |-> ZeroAddOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddAttributedOrderMessageCode, body |-> ZeroAddAttributedOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderDeletedMessageCode, body |-> ZeroOrderDeletedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderModifiedMessageCode, body |-> ZeroOrderModifiedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderBookClearMessageCode, body |-> ZeroOrderBookClearMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderExecutedMessageCode, body |-> ZeroOrderExecutedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderExecutedWithPriceSizeMessageCode, body |-> ZeroOrderExecutedWithPriceSizeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeMessageCode, body |-> ZeroTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionTradeMessageCode, body |-> ZeroAuctionTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionInfoMessageCode, body |-> ZeroAuctionInfoMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StatisticsMessageCode, body |-> ZeroStatisticsMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TopOfBookMessageCode, body |-> ZeroTopOfBookMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ length          : Sample(2),
      marketDataGroup : Sample(1),
      sequenceNumber  : Sample(4),
      message         : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.length
        \o EncodeUIntLE(Len(message.message), 1)
        \o message.marketDataGroup
        \o message.sequenceNumber
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET length == ReadBytes(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET messageCount == ReadUIntLE(length.rest, 1) IN IF ~messageCount.ok THEN Fail ELSE
    LET marketDataGroup == ReadBytes(messageCount.rest, 1) IN IF ~marketDataGroup.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(marketDataGroup.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET message == ReadMessageList(sequenceNumber.rest, messageCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ length          |-> length.value,
         marketDataGroup |-> marketDataGroup.value,
         sequenceNumber  |-> sequenceNumber.value,
         message         |-> message.value ], message.rest)

ZeroPacket ==
    [ length          |-> [i \in 1 .. 2 |-> 0],
      marketDataGroup |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber  |-> [i \in 1 .. 4 |-> 0],
      message         |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.length = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.marketDataGroup = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
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

(* Every System Event Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSystemEventMessage ==
    \A message \in CheckedSystemEventMessage :
        LET read == DecodeSystemEventMessage(EncodeSystemEventMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolDirectoryMessage ==
    \A message \in CheckedSymbolDirectoryMessage :
        LET read == DecodeSymbolDirectoryMessage(EncodeSymbolDirectoryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolStatusMessage ==
    \A message \in CheckedSymbolStatusMessage :
        LET read == DecodeSymbolStatusMessage(EncodeSymbolStatusMessage(message))
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

(* Every Add Attributed Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddAttributedOrderMessage ==
    \A message \in CheckedAddAttributedOrderMessage :
        LET read == DecodeAddAttributedOrderMessage(EncodeAddAttributedOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Deleted Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderDeletedMessage ==
    \A message \in CheckedOrderDeletedMessage :
        LET read == DecodeOrderDeletedMessage(EncodeOrderDeletedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Modified Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderModifiedMessage ==
    \A message \in CheckedOrderModifiedMessage :
        LET read == DecodeOrderModifiedMessage(EncodeOrderModifiedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Book Clear Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderBookClearMessage ==
    \A message \in CheckedOrderBookClearMessage :
        LET read == DecodeOrderBookClearMessage(EncodeOrderBookClearMessage(message))
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

(* Every Order Executed With Price Size Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutedWithPriceSizeMessage ==
    \A message \in CheckedOrderExecutedWithPriceSizeMessage :
        LET read == DecodeOrderExecutedWithPriceSizeMessage(EncodeOrderExecutedWithPriceSizeMessage(message))
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

(* Every Auction Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionTradeMessage ==
    \A message \in CheckedAuctionTradeMessage :
        LET read == DecodeAuctionTradeMessage(EncodeAuctionTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Info Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionInfoMessage ==
    \A message \in CheckedAuctionInfoMessage :
        LET read == DecodeAuctionInfoMessage(EncodeAuctionInfoMessage(message))
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

(* Every Top Of Book Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTopOfBookMessage ==
    \A message \in CheckedTopOfBookMessage :
        LET read == DecodeTopOfBookMessage(EncodeTopOfBookMessage(message))
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
