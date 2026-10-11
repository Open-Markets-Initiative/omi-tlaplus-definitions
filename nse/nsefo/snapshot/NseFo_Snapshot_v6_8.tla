------------------------ MODULE NseFo_Snapshot_v6_8 ------------------------
(***************************************************************************)
(* National Stock Exchange of India Ltd Mtbt Order Book Snapshot Recovery  *)
(* v6.8                                                                    *)
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
(* New Order Message: 29 bytes                                             *)
(***************************************************************************)

NewOrderMessage ==
    [ timestamp : Sample(8),
      orderId   : Sample(8),
      token     : Sample(4),
      orderType : Sample(1),
      price     : Sample(4),
      quantity  : Sample(4) ]

EncodeNewOrderMessage(message) ==
    message.timestamp
        \o message.orderId
        \o message.token
        \o message.orderType
        \o message.price
        \o message.quantity

DecodeNewOrderMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderId == ReadBytes(timestamp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET token == ReadBytes(orderId.rest, 4) IN IF ~token.ok THEN Fail ELSE
    LET orderType == ReadBytes(token.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET price == ReadBytes(orderType.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    Ok([ timestamp |-> timestamp.value,
         orderId   |-> orderId.value,
         token     |-> token.value,
         orderType |-> orderType.value,
         price     |-> price.value,
         quantity  |-> quantity.value ], quantity.rest)

ZeroNewOrderMessage ==
    [ timestamp |-> [i \in 1 .. 8 |-> 0],
      orderId   |-> [i \in 1 .. 8 |-> 0],
      token     |-> [i \in 1 .. 4 |-> 0],
      orderType |-> [i \in 1 .. 1 |-> 0],
      price     |-> [i \in 1 .. 4 |-> 0],
      quantity  |-> [i \in 1 .. 4 |-> 0] ]

(* New Order Message at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderMessage ==
    { ZeroNewOrderMessage }
        \cup { [ZeroNewOrderMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderMessage EXCEPT !.token = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderMessage EXCEPT !.quantity = one] : one \in Sample(4) }

(***************************************************************************)
(* New Spread Order Message: 29 bytes                                      *)
(***************************************************************************)

NewSpreadOrderMessage ==
    [ timestamp : Sample(8),
      orderId   : Sample(8),
      token     : Sample(4),
      orderType : Sample(1),
      price     : Sample(4),
      quantity  : Sample(4) ]

EncodeNewSpreadOrderMessage(message) ==
    message.timestamp
        \o message.orderId
        \o message.token
        \o message.orderType
        \o message.price
        \o message.quantity

DecodeNewSpreadOrderMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderId == ReadBytes(timestamp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET token == ReadBytes(orderId.rest, 4) IN IF ~token.ok THEN Fail ELSE
    LET orderType == ReadBytes(token.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET price == ReadBytes(orderType.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    Ok([ timestamp |-> timestamp.value,
         orderId   |-> orderId.value,
         token     |-> token.value,
         orderType |-> orderType.value,
         price     |-> price.value,
         quantity  |-> quantity.value ], quantity.rest)

ZeroNewSpreadOrderMessage ==
    [ timestamp |-> [i \in 1 .. 8 |-> 0],
      orderId   |-> [i \in 1 .. 8 |-> 0],
      token     |-> [i \in 1 .. 4 |-> 0],
      orderType |-> [i \in 1 .. 1 |-> 0],
      price     |-> [i \in 1 .. 4 |-> 0],
      quantity  |-> [i \in 1 .. 4 |-> 0] ]

(* New Spread Order Message at zero, then each field in turn at the values it is checked at *)
CheckedNewSpreadOrderMessage ==
    { ZeroNewSpreadOrderMessage }
        \cup { [ZeroNewSpreadOrderMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroNewSpreadOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroNewSpreadOrderMessage EXCEPT !.token = one] : one \in Sample(4) }
        \cup { [ZeroNewSpreadOrderMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroNewSpreadOrderMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroNewSpreadOrderMessage EXCEPT !.quantity = one] : one \in Sample(4) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

NewOrderMessageCode == 78  \* "N"
NewSpreadOrderMessageCode == 71  \* "G"

Payload ==
    [ tag : {NewOrderMessageCode}, body : NewOrderMessage ]
        \cup [ tag : {NewSpreadOrderMessageCode}, body : NewSpreadOrderMessage ]

EncodePayload(message) ==
    CASE message.tag = NewOrderMessageCode -> EncodeNewOrderMessage(message.body)
      [] message.tag = NewSpreadOrderMessageCode -> EncodeNewSpreadOrderMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = NewOrderMessageCode -> DecodeNewOrderMessage(bytes)
              [] tag = NewSpreadOrderMessageCode -> DecodeNewSpreadOrderMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> NewOrderMessageCode, body |-> ZeroNewOrderMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> NewOrderMessageCode, body |-> one] : one \in CheckedNewOrderMessage }
        \cup { [tag |-> NewSpreadOrderMessageCode, body |-> one] : one \in CheckedNewSpreadOrderMessage }

(***************************************************************************)
(* Message                                                                 *)
(***************************************************************************)

Message ==
    [ payload : Payload ]

EncodeMessage(message) ==
    EncodeUIntBE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

DecodeMessage(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

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
    { [ZeroMessage EXCEPT !.payload = [tag |-> NewOrderMessageCode, body |-> ZeroNewOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> NewSpreadOrderMessageCode, body |-> ZeroNewSpreadOrderMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ transCode          : Sample(2),
      size               : Sample(4),
      lastSequenceNumber : Sample(4),
      streamId           : Sample(2),
      message            : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.transCode
        \o message.size
        \o EncodeUIntLE(Len(message.message), 4)
        \o message.lastSequenceNumber
        \o message.streamId
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET transCode == ReadBytes(bytes, 2) IN IF ~transCode.ok THEN Fail ELSE
    LET size == ReadBytes(transCode.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET numberOfRecords == ReadUIntLE(size.rest, 4) IN IF ~numberOfRecords.ok THEN Fail ELSE
    LET lastSequenceNumber == ReadBytes(numberOfRecords.rest, 4) IN IF ~lastSequenceNumber.ok THEN Fail ELSE
    LET streamId == ReadBytes(lastSequenceNumber.rest, 2) IN IF ~streamId.ok THEN Fail ELSE
    LET message == ReadMessageList(streamId.rest, numberOfRecords.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ transCode          |-> transCode.value,
         size               |-> size.value,
         lastSequenceNumber |-> lastSequenceNumber.value,
         streamId           |-> streamId.value,
         message            |-> message.value ], message.rest)

ZeroPacket ==
    [ transCode          |-> [i \in 1 .. 2 |-> 0],
      size               |-> [i \in 1 .. 4 |-> 0],
      lastSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      streamId           |-> [i \in 1 .. 2 |-> 0],
      message            |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.transCode = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.lastSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.streamId = one] : one \in Sample(2) }
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

(* Every New Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderMessage ==
    \A message \in CheckedNewOrderMessage :
        LET read == DecodeNewOrderMessage(EncodeNewOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Spread Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewSpreadOrderMessage ==
    \A message \in CheckedNewSpreadOrderMessage :
        LET read == DecodeNewSpreadOrderMessage(EncodeNewSpreadOrderMessage(message))
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

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
