----------------- MODULE NsmEquities_TotalView_v2_0_Server -----------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) TotalView Itch v2.0                                            *)
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
(* Debug Packet: 1 bytes                                                   *)
(***************************************************************************)

DebugPacket ==
    [ text : Sample(1) ]

EncodeDebugPacket(message) ==
    message.text

DecodeDebugPacket(bytes) ==
    LET text == ReadBytes(bytes, 1) IN IF ~text.ok THEN Fail ELSE
    Ok([ text |-> text.value ], text.rest)

ZeroDebugPacket ==
    [ text |-> [i \in 1 .. 1 |-> 0] ]

(* Debug Packet at zero, then each field in turn at the values it is checked at *)
CheckedDebugPacket ==
    { ZeroDebugPacket }
        \cup { [ZeroDebugPacket EXCEPT !.text = one] : one \in Sample(1) }

(***************************************************************************)
(* Login Accepted Packet: 14 bytes                                         *)
(***************************************************************************)

LoginAcceptedPacket ==
    [ session        : Sample(10),
      sequenceNumber : Sample(4) ]

EncodeLoginAcceptedPacket(message) ==
    message.session
        \o message.sequenceNumber

DecodeLoginAcceptedPacket(bytes) ==
    LET session == ReadBytes(bytes, 10) IN IF ~session.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(session.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    Ok([ session        |-> session.value,
         sequenceNumber |-> sequenceNumber.value ], sequenceNumber.rest)

ZeroLoginAcceptedPacket ==
    [ session        |-> [i \in 1 .. 10 |-> 0],
      sequenceNumber |-> [i \in 1 .. 4 |-> 0] ]

(* Login Accepted Packet at zero, then each field in turn at the values it is checked at *)
CheckedLoginAcceptedPacket ==
    { ZeroLoginAcceptedPacket }
        \cup { [ZeroLoginAcceptedPacket EXCEPT !.session = one] : one \in Sample(10) }
        \cup { [ZeroLoginAcceptedPacket EXCEPT !.sequenceNumber = one] : one \in Sample(4) }

(***************************************************************************)
(* Login Rejected Packet: 1 bytes                                          *)
(***************************************************************************)

LoginRejectedPacket ==
    [ rejectReasonCode : Sample(1) ]

EncodeLoginRejectedPacket(message) ==
    message.rejectReasonCode

DecodeLoginRejectedPacket(bytes) ==
    LET rejectReasonCode == ReadBytes(bytes, 1) IN IF ~rejectReasonCode.ok THEN Fail ELSE
    Ok([ rejectReasonCode |-> rejectReasonCode.value ], rejectReasonCode.rest)

ZeroLoginRejectedPacket ==
    [ rejectReasonCode |-> [i \in 1 .. 1 |-> 0] ]

(* Login Rejected Packet at zero, then each field in turn at the values it is checked at *)
CheckedLoginRejectedPacket ==
    { ZeroLoginRejectedPacket }
        \cup { [ZeroLoginRejectedPacket EXCEPT !.rejectReasonCode = one] : one \in Sample(1) }

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
(* Add Order Message: 33 bytes                                             *)
(***************************************************************************)

AddOrderMessage ==
    [ orderReferenceNumber : Sample(9),
      side                 : Sample(1),
      shares               : Sample(6),
      stock                : Sample(6),
      price                : Sample(10),
      display              : Sample(1) ]

EncodeAddOrderMessage(message) ==
    message.orderReferenceNumber
        \o message.side
        \o message.shares
        \o message.stock
        \o message.price
        \o message.display

DecodeAddOrderMessage(bytes) ==
    LET orderReferenceNumber == ReadBytes(bytes, 9) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET side == ReadBytes(orderReferenceNumber.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET shares == ReadBytes(side.rest, 6) IN IF ~shares.ok THEN Fail ELSE
    LET stock == ReadBytes(shares.rest, 6) IN IF ~stock.ok THEN Fail ELSE
    LET price == ReadBytes(stock.rest, 10) IN IF ~price.ok THEN Fail ELSE
    LET display == ReadBytes(price.rest, 1) IN IF ~display.ok THEN Fail ELSE
    Ok([ orderReferenceNumber |-> orderReferenceNumber.value,
         side                 |-> side.value,
         shares               |-> shares.value,
         stock                |-> stock.value,
         price                |-> price.value,
         display              |-> display.value ], display.rest)

ZeroAddOrderMessage ==
    [ orderReferenceNumber |-> [i \in 1 .. 9 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      shares               |-> [i \in 1 .. 6 |-> 0],
      stock                |-> [i \in 1 .. 6 |-> 0],
      price                |-> [i \in 1 .. 10 |-> 0],
      display              |-> [i \in 1 .. 1 |-> 0] ]

(* Add Order Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderMessage ==
    { ZeroAddOrderMessage }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(9) }
        \cup { [ZeroAddOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.shares = one] : one \in Sample(6) }
        \cup { [ZeroAddOrderMessage EXCEPT !.stock = one] : one \in Sample(6) }
        \cup { [ZeroAddOrderMessage EXCEPT !.price = one] : one \in Sample(10) }
        \cup { [ZeroAddOrderMessage EXCEPT !.display = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Executed Message: 24 bytes                                        *)
(***************************************************************************)

OrderExecutedMessage ==
    [ orderReferenceNumber : Sample(9),
      executedShares       : Sample(6),
      matchNumber          : Sample(9) ]

EncodeOrderExecutedMessage(message) ==
    message.orderReferenceNumber
        \o message.executedShares
        \o message.matchNumber

DecodeOrderExecutedMessage(bytes) ==
    LET orderReferenceNumber == ReadBytes(bytes, 9) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET executedShares == ReadBytes(orderReferenceNumber.rest, 6) IN IF ~executedShares.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(executedShares.rest, 9) IN IF ~matchNumber.ok THEN Fail ELSE
    Ok([ orderReferenceNumber |-> orderReferenceNumber.value,
         executedShares       |-> executedShares.value,
         matchNumber          |-> matchNumber.value ], matchNumber.rest)

ZeroOrderExecutedMessage ==
    [ orderReferenceNumber |-> [i \in 1 .. 9 |-> 0],
      executedShares       |-> [i \in 1 .. 6 |-> 0],
      matchNumber          |-> [i \in 1 .. 9 |-> 0] ]

(* Order Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedMessage ==
    { ZeroOrderExecutedMessage }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(9) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.executedShares = one] : one \in Sample(6) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.matchNumber = one] : one \in Sample(9) }

(***************************************************************************)
(* Order Cancel Message: 15 bytes                                          *)
(***************************************************************************)

OrderCancelMessage ==
    [ orderReferenceNumber : Sample(9),
      canceledShares       : Sample(6) ]

EncodeOrderCancelMessage(message) ==
    message.orderReferenceNumber
        \o message.canceledShares

DecodeOrderCancelMessage(bytes) ==
    LET orderReferenceNumber == ReadBytes(bytes, 9) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET canceledShares == ReadBytes(orderReferenceNumber.rest, 6) IN IF ~canceledShares.ok THEN Fail ELSE
    Ok([ orderReferenceNumber |-> orderReferenceNumber.value,
         canceledShares       |-> canceledShares.value ], canceledShares.rest)

ZeroOrderCancelMessage ==
    [ orderReferenceNumber |-> [i \in 1 .. 9 |-> 0],
      canceledShares       |-> [i \in 1 .. 6 |-> 0] ]

(* Order Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelMessage ==
    { ZeroOrderCancelMessage }
        \cup { [ZeroOrderCancelMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(9) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.canceledShares = one] : one \in Sample(6) }

(***************************************************************************)
(* Trade Message: 41 bytes                                                 *)
(***************************************************************************)

TradeMessage ==
    [ orderReferenceNumber : Sample(9),
      side                 : Sample(1),
      shares               : Sample(6),
      stock                : Sample(6),
      price                : Sample(10),
      matchNumber          : Sample(9) ]

EncodeTradeMessage(message) ==
    message.orderReferenceNumber
        \o message.side
        \o message.shares
        \o message.stock
        \o message.price
        \o message.matchNumber

DecodeTradeMessage(bytes) ==
    LET orderReferenceNumber == ReadBytes(bytes, 9) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET side == ReadBytes(orderReferenceNumber.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET shares == ReadBytes(side.rest, 6) IN IF ~shares.ok THEN Fail ELSE
    LET stock == ReadBytes(shares.rest, 6) IN IF ~stock.ok THEN Fail ELSE
    LET price == ReadBytes(stock.rest, 10) IN IF ~price.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(price.rest, 9) IN IF ~matchNumber.ok THEN Fail ELSE
    Ok([ orderReferenceNumber |-> orderReferenceNumber.value,
         side                 |-> side.value,
         shares               |-> shares.value,
         stock                |-> stock.value,
         price                |-> price.value,
         matchNumber          |-> matchNumber.value ], matchNumber.rest)

ZeroTradeMessage ==
    [ orderReferenceNumber |-> [i \in 1 .. 9 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      shares               |-> [i \in 1 .. 6 |-> 0],
      stock                |-> [i \in 1 .. 6 |-> 0],
      price                |-> [i \in 1 .. 10 |-> 0],
      matchNumber          |-> [i \in 1 .. 9 |-> 0] ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(9) }
        \cup { [ZeroTradeMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.shares = one] : one \in Sample(6) }
        \cup { [ZeroTradeMessage EXCEPT !.stock = one] : one \in Sample(6) }
        \cup { [ZeroTradeMessage EXCEPT !.price = one] : one \in Sample(10) }
        \cup { [ZeroTradeMessage EXCEPT !.matchNumber = one] : one \in Sample(9) }

(***************************************************************************)
(* Broken Trade Message: 9 bytes                                           *)
(***************************************************************************)

BrokenTradeMessage ==
    [ matchNumber : Sample(9) ]

EncodeBrokenTradeMessage(message) ==
    message.matchNumber

DecodeBrokenTradeMessage(bytes) ==
    LET matchNumber == ReadBytes(bytes, 9) IN IF ~matchNumber.ok THEN Fail ELSE
    Ok([ matchNumber |-> matchNumber.value ], matchNumber.rest)

ZeroBrokenTradeMessage ==
    [ matchNumber |-> [i \in 1 .. 9 |-> 0] ]

(* Broken Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedBrokenTradeMessage ==
    { ZeroBrokenTradeMessage }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.matchNumber = one] : one \in Sample(9) }

(***************************************************************************)
(* Sequenced Message, selected by Message Type                             *)
(***************************************************************************)

SystemEventMessageCode == 83  \* "S"
AddOrderMessageCode == 65  \* "A"
OrderExecutedMessageCode == 69  \* "E"
OrderCancelMessageCode == 88  \* "X"
TradeMessageCode == 80  \* "P"
BrokenTradeMessageCode == 66  \* "B"

SequencedMessage ==
    [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {AddOrderMessageCode}, body : AddOrderMessage ]
        \cup [ tag : {OrderExecutedMessageCode}, body : OrderExecutedMessage ]
        \cup [ tag : {OrderCancelMessageCode}, body : OrderCancelMessage ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {BrokenTradeMessageCode}, body : BrokenTradeMessage ]

EncodeSequencedMessage(message) ==
    CASE message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = AddOrderMessageCode -> EncodeAddOrderMessage(message.body)
      [] message.tag = OrderExecutedMessageCode -> EncodeOrderExecutedMessage(message.body)
      [] message.tag = OrderCancelMessageCode -> EncodeOrderCancelMessage(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = BrokenTradeMessageCode -> EncodeBrokenTradeMessage(message.body)

DecodeSequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = AddOrderMessageCode -> DecodeAddOrderMessage(bytes)
              [] tag = OrderExecutedMessageCode -> DecodeOrderExecutedMessage(bytes)
              [] tag = OrderCancelMessageCode -> DecodeOrderCancelMessage(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = BrokenTradeMessageCode -> DecodeBrokenTradeMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSequencedMessage == [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]

(* Each Sequenced Message in turn, at the values the message it names is checked at *)
CheckedSequencedMessage ==
    { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> AddOrderMessageCode, body |-> one] : one \in CheckedAddOrderMessage }
        \cup { [tag |-> OrderExecutedMessageCode, body |-> one] : one \in CheckedOrderExecutedMessage }
        \cup { [tag |-> OrderCancelMessageCode, body |-> one] : one \in CheckedOrderCancelMessage }
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> BrokenTradeMessageCode, body |-> one] : one \in CheckedBrokenTradeMessage }

(***************************************************************************)
(* Sequenced Data Packet                                                   *)
(***************************************************************************)

SequencedDataPacket ==
    [ timestamp        : Sample(8),
      sequencedMessage : SequencedMessage ]

EncodeSequencedDataPacket(message) ==
    message.timestamp
        \o EncodeUIntBE(message.sequencedMessage.tag, 1)
        \o EncodeSequencedMessage(message.sequencedMessage)

DecodeSequencedDataPacket(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET messageType == ReadUIntBE(timestamp.rest, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET sequencedMessage == DecodeSequencedMessage(messageType.value, messageType.rest) IN IF ~sequencedMessage.ok THEN Fail ELSE
    Ok([ timestamp        |-> timestamp.value,
         sequencedMessage |-> sequencedMessage.value ], sequencedMessage.rest)

ZeroSequencedDataPacket ==
    [ timestamp        |-> [i \in 1 .. 8 |-> 0],
      sequencedMessage |-> ZeroSequencedMessage ]

(* Sequenced Data Packet at zero, then each field in turn at the values it is checked at *)
CheckedSequencedDataPacket ==
    { ZeroSequencedDataPacket }
        \cup { [ZeroSequencedDataPacket EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSequencedDataPacket EXCEPT !.sequencedMessage = one] : one \in CheckedSequencedMessage }

(***************************************************************************)
(* Server Payload, selected by Server Packet Type                          *)
(***************************************************************************)

DebugPacketCode == 43  \* "+"
LoginAcceptedPacketCode == 65  \* "A"
LoginRejectedPacketCode == 74  \* "J"
SequencedDataPacketCode == 83  \* "S"

ServerPayload ==
    [ tag : {DebugPacketCode}, body : DebugPacket ]
        \cup [ tag : {LoginAcceptedPacketCode}, body : LoginAcceptedPacket ]
        \cup [ tag : {LoginRejectedPacketCode}, body : LoginRejectedPacket ]
        \cup [ tag : {SequencedDataPacketCode}, body : SequencedDataPacket ]

EncodeServerPayload(message) ==
    CASE message.tag = DebugPacketCode -> EncodeDebugPacket(message.body)
      [] message.tag = LoginAcceptedPacketCode -> EncodeLoginAcceptedPacket(message.body)
      [] message.tag = LoginRejectedPacketCode -> EncodeLoginRejectedPacket(message.body)
      [] message.tag = SequencedDataPacketCode -> EncodeSequencedDataPacket(message.body)

DecodeServerPayload(tag, bytes) ==
    LET read ==
            CASE tag = DebugPacketCode -> DecodeDebugPacket(bytes)
              [] tag = LoginAcceptedPacketCode -> DecodeLoginAcceptedPacket(bytes)
              [] tag = LoginRejectedPacketCode -> DecodeLoginRejectedPacket(bytes)
              [] tag = SequencedDataPacketCode -> DecodeSequencedDataPacket(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroServerPayload == [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]

(* Each Server Payload in turn, at the values the message it names is checked at *)
CheckedServerPayload ==
    { [tag |-> DebugPacketCode, body |-> one] : one \in CheckedDebugPacket }
        \cup { [tag |-> LoginAcceptedPacketCode, body |-> one] : one \in CheckedLoginAcceptedPacket }
        \cup { [tag |-> LoginRejectedPacketCode, body |-> one] : one \in CheckedLoginRejectedPacket }
        \cup { [tag |-> SequencedDataPacketCode, body |-> one] : one \in CheckedSequencedDataPacket }

(***************************************************************************)
(* Server Packet                                                           *)
(***************************************************************************)

ServerPacket ==
    [ serverPayload : ServerPayload,
      soupLf        : Sample(1) ]

EncodeServerPacket(message) ==
    EncodeUIntBE(message.serverPayload.tag, 1)
        \o EncodeServerPayload(message.serverPayload)
        \o message.soupLf

DecodeServerPacket(bytes) ==
    LET serverPacketType == ReadUIntBE(bytes, 1) IN IF ~serverPacketType.ok THEN Fail ELSE
    LET serverPayload == DecodeServerPayload(serverPacketType.value, serverPacketType.rest) IN IF ~serverPayload.ok THEN Fail ELSE
    LET soupLf == ReadBytes(serverPayload.rest, 1) IN IF ~soupLf.ok THEN Fail ELSE
    Ok([ serverPayload |-> serverPayload.value,
         soupLf        |-> soupLf.value ], soupLf.rest)

ZeroServerPacket ==
    [ serverPayload |-> ZeroServerPayload,
      soupLf        |-> [i \in 1 .. 1 |-> 0] ]

(* Server Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerPacket ==
    { ZeroServerPacket }
        \cup { [ZeroServerPacket EXCEPT !.serverPayload = one] : one \in CheckedServerPayload }
        \cup { [ZeroServerPacket EXCEPT !.soupLf = one] : one \in Sample(1) }

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

(* Every Debug Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripDebugPacket ==
    \A message \in CheckedDebugPacket :
        LET read == DecodeDebugPacket(EncodeDebugPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Accepted Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginAcceptedPacket ==
    \A message \in CheckedLoginAcceptedPacket :
        LET read == DecodeLoginAcceptedPacket(EncodeLoginAcceptedPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Rejected Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRejectedPacket ==
    \A message \in CheckedLoginRejectedPacket :
        LET read == DecodeLoginRejectedPacket(EncodeLoginRejectedPacket(message))
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

(* Every Add Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderMessage ==
    \A message \in CheckedAddOrderMessage :
        LET read == DecodeAddOrderMessage(EncodeAddOrderMessage(message))
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

(* Every Order Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelMessage ==
    \A message \in CheckedOrderCancelMessage :
        LET read == DecodeOrderCancelMessage(EncodeOrderCancelMessage(message))
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

(* Every Broken Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBrokenTradeMessage ==
    \A message \in CheckedBrokenTradeMessage :
        LET read == DecodeBrokenTradeMessage(EncodeBrokenTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sequenced Data Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripSequencedDataPacket ==
    \A message \in CheckedSequencedDataPacket :
        LET read == DecodeSequencedDataPacket(EncodeSequencedDataPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Server Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripServerPacket ==
    \A message \in CheckedServerPacket :
        LET read == DecodeServerPacket(EncodeServerPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Sequenced Message is selected by the Message Type it is written under *)
SelectsSequencedMessage ==
    \A message \in CheckedSequencedMessage :
        LET read == DecodeSequencedMessage(message.tag, EncodeSequencedMessage(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Server Payload is selected by the Server Packet Type it is written under *)
SelectsServerPayload ==
    \A message \in CheckedServerPayload :
        LET read == DecodeServerPayload(message.tag, EncodeServerPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
