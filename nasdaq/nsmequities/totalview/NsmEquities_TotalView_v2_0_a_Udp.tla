----------------- MODULE NsmEquities_TotalView_v2_0_a_Udp ------------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) TotalView Itch v2.0.a                                          *)
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
(* Note: a Count of 0 marks Heartbeat and carries no Message.              *)
(*                                                                         *)
(* Note: a Count of 0 marks End Of Session and carries no Message.         *)
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

(* The integer a rule depends on *)
ReadUIntLE(bytes, width) ==
    IF Len(bytes) < width
    THEN Fail
    ELSE Ok(DecodeUIntLE(SubSeq(bytes, 1, width)), SubSeq(bytes, width + 1, Len(bytes)))

(***************************************************************************)
(* The values a field is checked at: zero, the spaces a text field is      *)
(* padded with, and                                                        *)
(* every bit set, which is where an encoding goes wrong if it goes wrong   *)
(***************************************************************************)

Sample(width) ==
    { [i \in 1 .. width |-> 0],
      [i \in 1 .. width |-> 32],
      [i \in 1 .. width |-> 255] }

(* The lists a record is checked over: none, one, and a run of two. What a run has *)
(* to get right is reading one entry after another, which two of a kind already say. *)
SampleLists(entries) ==
    { << >> }
        \cup { <<one>> : one \in entries }
        \cup { <<one, one>> : one \in entries }

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
(* Add Order Message: 37 bytes                                             *)
(***************************************************************************)

AddOrderMessage ==
    [ orderReferenceNumber : Sample(9),
      side                 : Sample(1),
      shares               : Sample(6),
      stock                : Sample(6),
      price                : Sample(10),
      display              : Sample(1),
      mmid                 : Sample(4) ]

EncodeAddOrderMessage(message) ==
    message.orderReferenceNumber
        \o message.side
        \o message.shares
        \o message.stock
        \o message.price
        \o message.display
        \o message.mmid

DecodeAddOrderMessage(bytes) ==
    LET orderReferenceNumber == ReadBytes(bytes, 9) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET side == ReadBytes(orderReferenceNumber.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET shares == ReadBytes(side.rest, 6) IN IF ~shares.ok THEN Fail ELSE
    LET stock == ReadBytes(shares.rest, 6) IN IF ~stock.ok THEN Fail ELSE
    LET price == ReadBytes(stock.rest, 10) IN IF ~price.ok THEN Fail ELSE
    LET display == ReadBytes(price.rest, 1) IN IF ~display.ok THEN Fail ELSE
    LET mmid == ReadBytes(display.rest, 4) IN IF ~mmid.ok THEN Fail ELSE
    Ok([ orderReferenceNumber |-> orderReferenceNumber.value,
         side                 |-> side.value,
         shares               |-> shares.value,
         stock                |-> stock.value,
         price                |-> price.value,
         display              |-> display.value,
         mmid                 |-> mmid.value ], mmid.rest)

ZeroAddOrderMessage ==
    [ orderReferenceNumber |-> [i \in 1 .. 9 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      shares               |-> [i \in 1 .. 6 |-> 0],
      stock                |-> [i \in 1 .. 6 |-> 0],
      price                |-> [i \in 1 .. 10 |-> 0],
      display              |-> [i \in 1 .. 1 |-> 0],
      mmid                 |-> [i \in 1 .. 4 |-> 0] ]

(* Add Order Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderMessage ==
    { ZeroAddOrderMessage }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(9) }
        \cup { [ZeroAddOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.shares = one] : one \in Sample(6) }
        \cup { [ZeroAddOrderMessage EXCEPT !.stock = one] : one \in Sample(6) }
        \cup { [ZeroAddOrderMessage EXCEPT !.price = one] : one \in Sample(10) }
        \cup { [ZeroAddOrderMessage EXCEPT !.display = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.mmid = one] : one \in Sample(4) }

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
(* Stock Halt Status Message: 7 bytes                                      *)
(***************************************************************************)

StockHaltStatusMessage ==
    [ stock       : Sample(6),
      stockHalted : Sample(1) ]

EncodeStockHaltStatusMessage(message) ==
    message.stock
        \o message.stockHalted

DecodeStockHaltStatusMessage(bytes) ==
    LET stock == ReadBytes(bytes, 6) IN IF ~stock.ok THEN Fail ELSE
    LET stockHalted == ReadBytes(stock.rest, 1) IN IF ~stockHalted.ok THEN Fail ELSE
    Ok([ stock       |-> stock.value,
         stockHalted |-> stockHalted.value ], stockHalted.rest)

ZeroStockHaltStatusMessage ==
    [ stock       |-> [i \in 1 .. 6 |-> 0],
      stockHalted |-> [i \in 1 .. 1 |-> 0] ]

(* Stock Halt Status Message at zero, then each field in turn at the values it is checked at *)
CheckedStockHaltStatusMessage ==
    { ZeroStockHaltStatusMessage }
        \cup { [ZeroStockHaltStatusMessage EXCEPT !.stock = one] : one \in Sample(6) }
        \cup { [ZeroStockHaltStatusMessage EXCEPT !.stockHalted = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

SystemEventMessageCode == 83  \* "S"
AddOrderMessageCode == 65  \* "A"
OrderExecutedMessageCode == 69  \* "E"
OrderCancelMessageCode == 88  \* "X"
TradeMessageCode == 80  \* "P"
BrokenTradeMessageCode == 66  \* "B"
StockHaltStatusMessageCode == 72  \* "H"

Payload ==
    [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {AddOrderMessageCode}, body : AddOrderMessage ]
        \cup [ tag : {OrderExecutedMessageCode}, body : OrderExecutedMessage ]
        \cup [ tag : {OrderCancelMessageCode}, body : OrderCancelMessage ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {BrokenTradeMessageCode}, body : BrokenTradeMessage ]
        \cup [ tag : {StockHaltStatusMessageCode}, body : StockHaltStatusMessage ]

EncodePayload(message) ==
    CASE message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = AddOrderMessageCode -> EncodeAddOrderMessage(message.body)
      [] message.tag = OrderExecutedMessageCode -> EncodeOrderExecutedMessage(message.body)
      [] message.tag = OrderCancelMessageCode -> EncodeOrderCancelMessage(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = BrokenTradeMessageCode -> EncodeBrokenTradeMessage(message.body)
      [] message.tag = StockHaltStatusMessageCode -> EncodeStockHaltStatusMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = AddOrderMessageCode -> DecodeAddOrderMessage(bytes)
              [] tag = OrderExecutedMessageCode -> DecodeOrderExecutedMessage(bytes)
              [] tag = OrderCancelMessageCode -> DecodeOrderCancelMessage(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = BrokenTradeMessageCode -> DecodeBrokenTradeMessage(bytes)
              [] tag = StockHaltStatusMessageCode -> DecodeStockHaltStatusMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> AddOrderMessageCode, body |-> one] : one \in CheckedAddOrderMessage }
        \cup { [tag |-> OrderExecutedMessageCode, body |-> one] : one \in CheckedOrderExecutedMessage }
        \cup { [tag |-> OrderCancelMessageCode, body |-> one] : one \in CheckedOrderCancelMessage }
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> BrokenTradeMessageCode, body |-> one] : one \in CheckedBrokenTradeMessage }
        \cup { [tag |-> StockHaltStatusMessageCode, body |-> one] : one \in CheckedStockHaltStatusMessage }

(***************************************************************************)
(* Message, framed by Length                                               *)
(***************************************************************************)

Message ==
    [ timestamp : Sample(8),
      payload   : Payload ]

EncodeMessageBody(message) ==
    message.timestamp
        \o EncodeUIntLE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

(* Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntLE(Len(body), 2) \o body

DecodeMessageBody(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET messageType == ReadUIntLE(timestamp.rest, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ timestamp |-> timestamp.value,
         payload   |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroMessage ==
    [ timestamp |-> [i \in 1 .. 8 |-> 0],
      payload   |-> ZeroPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddOrderMessageCode, body |-> ZeroAddOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderExecutedMessageCode, body |-> ZeroOrderExecutedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderCancelMessageCode, body |-> ZeroOrderCancelMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeMessageCode, body |-> ZeroTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> BrokenTradeMessageCode, body |-> ZeroBrokenTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StockHaltStatusMessageCode, body |-> ZeroStockHaltStatusMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ session  : Sample(10),
      sequence : Sample(4),
      message  : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.session
        \o message.sequence
        \o EncodeUIntLE(Len(message.message), 2)
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET session == ReadBytes(bytes, 10) IN IF ~session.ok THEN Fail ELSE
    LET sequence == ReadBytes(session.rest, 4) IN IF ~sequence.ok THEN Fail ELSE
    LET count == ReadUIntLE(sequence.rest, 2) IN IF ~count.ok THEN Fail ELSE
    LET message == ReadMessageList(count.rest, count.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ session  |-> session.value,
         sequence |-> sequence.value,
         message  |-> message.value ], message.rest)

ZeroPacket ==
    [ session  |-> [i \in 1 .. 10 |-> 0],
      sequence |-> [i \in 1 .. 4 |-> 0],
      message  |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.session = one] : one \in Sample(10) }
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
                /\ \A i \in 1 .. width : EncodeUIntLE(value, width)[i] \in Byte

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

(* Every Stock Halt Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStockHaltStatusMessage ==
    \A message \in CheckedStockHaltStatusMessage :
        LET read == DecodeStockHaltStatusMessage(EncodeStockHaltStatusMessage(message))
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
    \A message \in Payload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Length is written from the bytes it frames *)
FramesMessage ==
    \A message \in Message :
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
