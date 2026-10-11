--------------- MODULE Lseg_Millennium_Level2Recovery_v11_9 ----------------
(***************************************************************************)
(* London Stock Exchange  v11.9                                            *)
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
(* Note: Snapshot Complete Flags is a bit field set, checked as its 1 byte *)
(* rather than bit by bit.                                                 *)
(*                                                                         *)
(* Note: Symbol Status Flags is a bit field set, checked as its 1 byte     *)
(* rather than bit by bit.                                                 *)
(*                                                                         *)
(* Note: Add Order Flags is a bit field set, checked as its 1 byte rather  *)
(* than bit by bit.                                                        *)
(*                                                                         *)
(* Note: Add Attributed Order Flags is a bit field set, checked as its 1   *)
(* byte rather than bit by bit.                                            *)
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
(* Login Request Message: 16 bytes                                         *)
(***************************************************************************)

LoginRequestMessage ==
    [ username : Sample(6),
      password : Sample(10) ]

EncodeLoginRequestMessage(message) ==
    message.username
        \o message.password

DecodeLoginRequestMessage(bytes) ==
    LET username == ReadBytes(bytes, 6) IN IF ~username.ok THEN Fail ELSE
    LET password == ReadBytes(username.rest, 10) IN IF ~password.ok THEN Fail ELSE
    Ok([ username |-> username.value,
         password |-> password.value ], password.rest)

ZeroLoginRequestMessage ==
    [ username |-> [i \in 1 .. 6 |-> 0],
      password |-> [i \in 1 .. 10 |-> 0] ]

(* Login Request Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginRequestMessage ==
    { ZeroLoginRequestMessage }
        \cup { [ZeroLoginRequestMessage EXCEPT !.username = one] : one \in Sample(6) }
        \cup { [ZeroLoginRequestMessage EXCEPT !.password = one] : one \in Sample(10) }

(***************************************************************************)
(* Login Response Message: 1 bytes                                         *)
(***************************************************************************)

LoginResponseMessage ==
    [ loginStatus : Sample(1) ]

EncodeLoginResponseMessage(message) ==
    message.loginStatus

DecodeLoginResponseMessage(bytes) ==
    LET loginStatus == ReadBytes(bytes, 1) IN IF ~loginStatus.ok THEN Fail ELSE
    Ok([ loginStatus |-> loginStatus.value ], loginStatus.rest)

ZeroLoginResponseMessage ==
    [ loginStatus |-> [i \in 1 .. 1 |-> 0] ]

(* Login Response Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginResponseMessage ==
    { ZeroLoginResponseMessage }
        \cup { [ZeroLoginResponseMessage EXCEPT !.loginStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Snapshot Request Message: 14 bytes                                      *)
(***************************************************************************)

SnapshotRequestMessage ==
    [ sequenceNumber : Sample(4),
      segment        : Sample(6),
      instrumentId   : Sample(4) ]

EncodeSnapshotRequestMessage(message) ==
    message.sequenceNumber
        \o message.segment
        \o message.instrumentId

DecodeSnapshotRequestMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET segment == ReadBytes(sequenceNumber.rest, 6) IN IF ~segment.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(segment.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    Ok([ sequenceNumber |-> sequenceNumber.value,
         segment        |-> segment.value,
         instrumentId   |-> instrumentId.value ], instrumentId.rest)

ZeroSnapshotRequestMessage ==
    [ sequenceNumber |-> [i \in 1 .. 4 |-> 0],
      segment        |-> [i \in 1 .. 6 |-> 0],
      instrumentId   |-> [i \in 1 .. 4 |-> 0] ]

(* Snapshot Request Message at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotRequestMessage ==
    { ZeroSnapshotRequestMessage }
        \cup { [ZeroSnapshotRequestMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotRequestMessage EXCEPT !.segment = one] : one \in Sample(6) }
        \cup { [ZeroSnapshotRequestMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }

(***************************************************************************)
(* Snapshot Response Message: 9 bytes                                      *)
(***************************************************************************)

SnapshotResponseMessage ==
    [ sequenceNumber : Sample(4),
      orderCount     : Sample(4),
      snapshotStatus : Sample(1) ]

EncodeSnapshotResponseMessage(message) ==
    message.sequenceNumber
        \o message.orderCount
        \o message.snapshotStatus

DecodeSnapshotResponseMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET orderCount == ReadBytes(sequenceNumber.rest, 4) IN IF ~orderCount.ok THEN Fail ELSE
    LET snapshotStatus == ReadBytes(orderCount.rest, 1) IN IF ~snapshotStatus.ok THEN Fail ELSE
    Ok([ sequenceNumber |-> sequenceNumber.value,
         orderCount     |-> orderCount.value,
         snapshotStatus |-> snapshotStatus.value ], snapshotStatus.rest)

ZeroSnapshotResponseMessage ==
    [ sequenceNumber |-> [i \in 1 .. 4 |-> 0],
      orderCount     |-> [i \in 1 .. 4 |-> 0],
      snapshotStatus |-> [i \in 1 .. 1 |-> 0] ]

(* Snapshot Response Message at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotResponseMessage ==
    { ZeroSnapshotResponseMessage }
        \cup { [ZeroSnapshotResponseMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotResponseMessage EXCEPT !.orderCount = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotResponseMessage EXCEPT !.snapshotStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Snapshot Complete Message: 15 bytes                                     *)
(***************************************************************************)

SnapshotCompleteMessage ==
    [ sequenceNumber        : Sample(4),
      segment               : Sample(6),
      instrumentId          : Sample(4),
      snapshotCompleteFlags : Sample(1) ]

EncodeSnapshotCompleteMessage(message) ==
    message.sequenceNumber
        \o message.segment
        \o message.instrumentId
        \o message.snapshotCompleteFlags

DecodeSnapshotCompleteMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET segment == ReadBytes(sequenceNumber.rest, 6) IN IF ~segment.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(segment.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET snapshotCompleteFlags == ReadBytes(instrumentId.rest, 1) IN IF ~snapshotCompleteFlags.ok THEN Fail ELSE
    Ok([ sequenceNumber        |-> sequenceNumber.value,
         segment               |-> segment.value,
         instrumentId          |-> instrumentId.value,
         snapshotCompleteFlags |-> snapshotCompleteFlags.value ], snapshotCompleteFlags.rest)

ZeroSnapshotCompleteMessage ==
    [ sequenceNumber        |-> [i \in 1 .. 4 |-> 0],
      segment               |-> [i \in 1 .. 6 |-> 0],
      instrumentId          |-> [i \in 1 .. 4 |-> 0],
      snapshotCompleteFlags |-> [i \in 1 .. 1 |-> 0] ]

(* Snapshot Complete Message at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotCompleteMessage ==
    { ZeroSnapshotCompleteMessage }
        \cup { [ZeroSnapshotCompleteMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotCompleteMessage EXCEPT !.segment = one] : one \in Sample(6) }
        \cup { [ZeroSnapshotCompleteMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotCompleteMessage EXCEPT !.snapshotCompleteFlags = one] : one \in Sample(1) }

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
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

LoginRequestMessageCode == 1  \* 0x01
LoginResponseMessageCode == 2  \* 0x02
SnapshotRequestMessageCode == 129  \* 0x81
SnapshotResponseMessageCode == 130  \* 0x82
SnapshotCompleteMessageCode == 131  \* 0x83
SymbolStatusMessageCode == 72  \* 0x48
AddOrderMessageCode == 65  \* 0x41
AddAttributedOrderMessageCode == 70  \* 0x46

Payload ==
    [ tag : {LoginRequestMessageCode}, body : LoginRequestMessage ]
        \cup [ tag : {LoginResponseMessageCode}, body : LoginResponseMessage ]
        \cup [ tag : {SnapshotRequestMessageCode}, body : SnapshotRequestMessage ]
        \cup [ tag : {SnapshotResponseMessageCode}, body : SnapshotResponseMessage ]
        \cup [ tag : {SnapshotCompleteMessageCode}, body : SnapshotCompleteMessage ]
        \cup [ tag : {SymbolStatusMessageCode}, body : SymbolStatusMessage ]
        \cup [ tag : {AddOrderMessageCode}, body : AddOrderMessage ]
        \cup [ tag : {AddAttributedOrderMessageCode}, body : AddAttributedOrderMessage ]

EncodePayload(message) ==
    CASE message.tag = LoginRequestMessageCode -> EncodeLoginRequestMessage(message.body)
      [] message.tag = LoginResponseMessageCode -> EncodeLoginResponseMessage(message.body)
      [] message.tag = SnapshotRequestMessageCode -> EncodeSnapshotRequestMessage(message.body)
      [] message.tag = SnapshotResponseMessageCode -> EncodeSnapshotResponseMessage(message.body)
      [] message.tag = SnapshotCompleteMessageCode -> EncodeSnapshotCompleteMessage(message.body)
      [] message.tag = SymbolStatusMessageCode -> EncodeSymbolStatusMessage(message.body)
      [] message.tag = AddOrderMessageCode -> EncodeAddOrderMessage(message.body)
      [] message.tag = AddAttributedOrderMessageCode -> EncodeAddAttributedOrderMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = LoginRequestMessageCode -> DecodeLoginRequestMessage(bytes)
              [] tag = LoginResponseMessageCode -> DecodeLoginResponseMessage(bytes)
              [] tag = SnapshotRequestMessageCode -> DecodeSnapshotRequestMessage(bytes)
              [] tag = SnapshotResponseMessageCode -> DecodeSnapshotResponseMessage(bytes)
              [] tag = SnapshotCompleteMessageCode -> DecodeSnapshotCompleteMessage(bytes)
              [] tag = SymbolStatusMessageCode -> DecodeSymbolStatusMessage(bytes)
              [] tag = AddOrderMessageCode -> DecodeAddOrderMessage(bytes)
              [] tag = AddAttributedOrderMessageCode -> DecodeAddAttributedOrderMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> LoginRequestMessageCode, body |-> ZeroLoginRequestMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> LoginRequestMessageCode, body |-> one] : one \in CheckedLoginRequestMessage }
        \cup { [tag |-> LoginResponseMessageCode, body |-> one] : one \in CheckedLoginResponseMessage }
        \cup { [tag |-> SnapshotRequestMessageCode, body |-> one] : one \in CheckedSnapshotRequestMessage }
        \cup { [tag |-> SnapshotResponseMessageCode, body |-> one] : one \in CheckedSnapshotResponseMessage }
        \cup { [tag |-> SnapshotCompleteMessageCode, body |-> one] : one \in CheckedSnapshotCompleteMessage }
        \cup { [tag |-> SymbolStatusMessageCode, body |-> one] : one \in CheckedSymbolStatusMessage }
        \cup { [tag |-> AddOrderMessageCode, body |-> one] : one \in CheckedAddOrderMessage }
        \cup { [tag |-> AddAttributedOrderMessageCode, body |-> one] : one \in CheckedAddAttributedOrderMessage }

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
    { [ZeroMessage EXCEPT !.payload = [tag |-> LoginRequestMessageCode, body |-> ZeroLoginRequestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LoginResponseMessageCode, body |-> ZeroLoginResponseMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SnapshotRequestMessageCode, body |-> ZeroSnapshotRequestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SnapshotResponseMessageCode, body |-> ZeroSnapshotResponseMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SnapshotCompleteMessageCode, body |-> ZeroSnapshotCompleteMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SymbolStatusMessageCode, body |-> ZeroSymbolStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddOrderMessageCode, body |-> ZeroAddOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddAttributedOrderMessageCode, body |-> ZeroAddAttributedOrderMessage]] }

(***************************************************************************)
(* Tcp Unit, framed by Length                                              *)
(***************************************************************************)

TcpUnit ==
    [ marketDataGroup : Sample(1),
      sequenceNumber  : Sample(4),
      message         : SampleLists(OneMessage) ]

EncodeTcpUnitBody(message) ==
    EncodeUIntLE(Len(message.message), 1)
        \o message.marketDataGroup
        \o message.sequenceNumber
        \o EncodeMessageList(message.message)

(* Length counts the bytes it frames, so it is written from them *)
EncodeTcpUnit(message) ==
    LET body == EncodeTcpUnitBody(message)
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeTcpUnitBody(bytes) ==
    LET messageCount == ReadUIntLE(bytes, 1) IN IF ~messageCount.ok THEN Fail ELSE
    LET marketDataGroup == ReadBytes(messageCount.rest, 1) IN IF ~marketDataGroup.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(marketDataGroup.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET message == ReadMessageList(sequenceNumber.rest, messageCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ marketDataGroup |-> marketDataGroup.value,
         sequenceNumber  |-> sequenceNumber.value,
         message         |-> message.value ], message.rest)

DecodeTcpUnit(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeTcpUnitBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroTcpUnit ==
    [ marketDataGroup |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber  |-> [i \in 1 .. 4 |-> 0],
      message         |-> << >> ]

(* Tcp Unit at zero, then each field in turn at the values it is checked at *)
CheckedTcpUnit ==
    { ZeroTcpUnit }
        \cup { [ZeroTcpUnit EXCEPT !.marketDataGroup = one] : one \in Sample(1) }
        \cup { [ZeroTcpUnit EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroTcpUnit EXCEPT !.message = one] : one \in SampleLists(OneMessage) }

(* A run of Tcp Unit, written one after another *)
RECURSIVE EncodeTcpUnitList(_)
EncodeTcpUnitList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTcpUnit(Head(messages)) \o EncodeTcpUnitList(Tail(messages))

(* As many Tcp Unit as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadTcpUnitAll(_)
ReadTcpUnitAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeTcpUnit(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTcpUnitAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Tcp Unit of each kind, for the lists that carry them *)
OneTcpUnit == { ZeroTcpUnit }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ tcpUnit : SampleLists(OneTcpUnit) ]

EncodePacket(message) ==
    EncodeTcpUnitList(message.tcpUnit)

DecodePacket(bytes) ==
    LET tcpUnit == ReadTcpUnitAll(bytes) IN IF ~tcpUnit.ok THEN Fail ELSE
    Ok([ tcpUnit |-> tcpUnit.value ], tcpUnit.rest)

ZeroPacket ==
    [ tcpUnit |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.tcpUnit = one] : one \in SampleLists(OneTcpUnit) }

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

(* Every Login Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRequestMessage ==
    \A message \in CheckedLoginRequestMessage :
        LET read == DecodeLoginRequestMessage(EncodeLoginRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginResponseMessage ==
    \A message \in CheckedLoginResponseMessage :
        LET read == DecodeLoginResponseMessage(EncodeLoginResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotRequestMessage ==
    \A message \in CheckedSnapshotRequestMessage :
        LET read == DecodeSnapshotRequestMessage(EncodeSnapshotRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotResponseMessage ==
    \A message \in CheckedSnapshotResponseMessage :
        LET read == DecodeSnapshotResponseMessage(EncodeSnapshotResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Complete Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotCompleteMessage ==
    \A message \in CheckedSnapshotCompleteMessage :
        LET read == DecodeSnapshotCompleteMessage(EncodeSnapshotCompleteMessage(message))
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

(* Every Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMessage ==
    \A message \in CheckedMessage :
        LET read == DecodeMessage(EncodeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tcp Unit decodes back to what was encoded, and leaves nothing over *)
RoundTripTcpUnit ==
    \A message \in CheckedTcpUnit :
        LET read == DecodeTcpUnit(EncodeTcpUnit(message))
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

(* Length is written from the bytes it frames *)
FramesTcpUnit ==
    \A message \in CheckedTcpUnit :
        LET bytes == EncodeTcpUnit(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
