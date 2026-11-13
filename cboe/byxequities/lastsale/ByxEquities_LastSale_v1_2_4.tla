-------------------- MODULE ByxEquities_LastSale_v1_2_4 --------------------
(***************************************************************************)
(* Chicago Board Options Exchange Last Sale v1.2.4                         *)
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
(* License: MIT No Attribution                                             *)
(*                                                                         *)
(* Note: Unsequenced Message is as wide as what is left of Unsequenced     *)
(* Data Packet, bar the 1 byte read after it: it is read as the bytes left *)
(* of what its record was given, which the records above it keep those     *)
(* bytes back from.                                                        *)
(*                                                                         *)
(* Note: Frame is closed by Soup Lf, so its body is read as the bytes      *)
(* ahead of the first 10 and written back with that byte after it, which   *)
(* is what lets a run of them be told apart.                               *)
(*                                                                         *)
(* Note: Frame is of no one width: each is read by its own fields, and     *)
(* since every reading of it takes at least 2 bytes off the reader the run *)
(* ends where the data does.                                               *)
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

(* A record closed by a terminator is the bytes ahead of the first one. Scanning for it *)
(* is how far the record reaches: the body is what lies before the byte, and what lies *)
(* after it is the next record's. A run of them with no terminator left is no record at *)
(* all, so the reader fails rather than taking the rest. *)
RECURSIVE Terminated(_, _)
Terminated(bytes, terminator) ==
    IF bytes = << >>
    THEN 0
    ELSE IF Head(bytes) = terminator
         THEN 1
         ELSE LET after == Terminated(Tail(bytes), terminator)
              IN  IF after = 0 THEN 0 ELSE after + 1

(* The body a terminator closes, and the bytes after the byte that closed it *)
ReadClosed(bytes, terminator) ==
    LET at == Terminated(bytes, terminator) IN
    IF at = 0
    THEN Fail
    ELSE Ok(SubSeq(bytes, 1, at - 1), SubSeq(bytes, at + 1, Len(bytes)))

(* The integer a rule depends on, in the byte order the field states *)
ReadUIntLE(bytes, width) ==
    IF Len(bytes) < width
    THEN Fail
    ELSE Ok(DecodeUIntLE(SubSeq(bytes, 1, width)), SubSeq(bytes, width + 1, Len(bytes)))

ReadUIntBE(bytes, width) ==
    IF Len(bytes) < width
    THEN Fail
    ELSE Ok(DecodeUIntBE(SubSeq(bytes, 1, width)), SubSeq(bytes, width + 1, Len(bytes)))

(* The integer a text protocol writes as the characters of itself: a count of one is *)
(* the character "1", which is the byte 49. Read by its digits, and written back *)
(* zero filled to the width the field states, which is how such a field is filled. *)
Digit == 48 .. 57

RECURSIVE DecodeDigits(_)
DecodeDigits(bytes) ==
    IF bytes = << >>
    THEN 0
    ELSE DecodeDigits(SubSeq(bytes, 1, Len(bytes) - 1)) * 10 + (bytes[Len(bytes)] - 48)

RECURSIVE EncodeDigits(_, _)
EncodeDigits(value, width) ==
    IF width = 0
    THEN << >>
    ELSE EncodeDigits(value \div 10, width - 1) \o <<48 + (value % 10)>>

(* A field written as digits that holds anything else is no number, so it is not read: *)
(* the value would not be what the bytes say, and would not write back as them. *)
ReadDigits(bytes, width) ==
    IF Len(bytes) < width \/ \E i \in 1 .. width : bytes[i] \notin Digit
    THEN Fail
    ELSE Ok(DecodeDigits(SubSeq(bytes, 1, width)), SubSeq(bytes, width + 1, Len(bytes)))

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
(* Login Accepted Packet: 20 bytes                                         *)
(***************************************************************************)

LoginAcceptedPacket ==
    [ session        : Sample(10),
      sequenceNumber : Sample(10) ]

EncodeLoginAcceptedPacket(message) ==
    message.session
        \o message.sequenceNumber

DecodeLoginAcceptedPacket(bytes) ==
    LET session == ReadBytes(bytes, 10) IN IF ~session.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(session.rest, 10) IN IF ~sequenceNumber.ok THEN Fail ELSE
    Ok([ session        |-> session.value,
         sequenceNumber |-> sequenceNumber.value ], sequenceNumber.rest)

ZeroLoginAcceptedPacket ==
    [ session        |-> [i \in 1 .. 10 |-> 0],
      sequenceNumber |-> [i \in 1 .. 10 |-> 0] ]

(* Login Accepted Packet at zero, then each field in turn at the values it is checked at *)
CheckedLoginAcceptedPacket ==
    { ZeroLoginAcceptedPacket }
        \cup { [ZeroLoginAcceptedPacket EXCEPT !.session = one] : one \in Sample(10) }
        \cup { [ZeroLoginAcceptedPacket EXCEPT !.sequenceNumber = one] : one \in Sample(10) }

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
(* Last Sale Message: 38 bytes                                             *)
(***************************************************************************)

LastSaleMessage ==
    [ executedShares : Sample(8),
      stockSymbol    : Sample(8),
      priceShort     : Sample(10),
      executionId    : Sample(12) ]

EncodeLastSaleMessage(message) ==
    message.executedShares
        \o message.stockSymbol
        \o message.priceShort
        \o message.executionId

DecodeLastSaleMessage(bytes) ==
    LET executedShares == ReadBytes(bytes, 8) IN IF ~executedShares.ok THEN Fail ELSE
    LET stockSymbol == ReadBytes(executedShares.rest, 8) IN IF ~stockSymbol.ok THEN Fail ELSE
    LET priceShort == ReadBytes(stockSymbol.rest, 10) IN IF ~priceShort.ok THEN Fail ELSE
    LET executionId == ReadBytes(priceShort.rest, 12) IN IF ~executionId.ok THEN Fail ELSE
    Ok([ executedShares |-> executedShares.value,
         stockSymbol    |-> stockSymbol.value,
         priceShort     |-> priceShort.value,
         executionId    |-> executionId.value ], executionId.rest)

ZeroLastSaleMessage ==
    [ executedShares |-> [i \in 1 .. 8 |-> 0],
      stockSymbol    |-> [i \in 1 .. 8 |-> 0],
      priceShort     |-> [i \in 1 .. 10 |-> 0],
      executionId    |-> [i \in 1 .. 12 |-> 0] ]

(* Last Sale Message at zero, then each field in turn at the values it is checked at *)
CheckedLastSaleMessage ==
    { ZeroLastSaleMessage }
        \cup { [ZeroLastSaleMessage EXCEPT !.executedShares = one] : one \in Sample(8) }
        \cup { [ZeroLastSaleMessage EXCEPT !.stockSymbol = one] : one \in Sample(8) }
        \cup { [ZeroLastSaleMessage EXCEPT !.priceShort = one] : one \in Sample(10) }
        \cup { [ZeroLastSaleMessage EXCEPT !.executionId = one] : one \in Sample(12) }

(***************************************************************************)
(* Last Sale Extended Message: 42 bytes                                    *)
(***************************************************************************)

LastSaleExtendedMessage ==
    [ executedShares : Sample(8),
      stockSymbol    : Sample(8),
      priceLong      : Sample(14),
      executionId    : Sample(12) ]

EncodeLastSaleExtendedMessage(message) ==
    message.executedShares
        \o message.stockSymbol
        \o message.priceLong
        \o message.executionId

DecodeLastSaleExtendedMessage(bytes) ==
    LET executedShares == ReadBytes(bytes, 8) IN IF ~executedShares.ok THEN Fail ELSE
    LET stockSymbol == ReadBytes(executedShares.rest, 8) IN IF ~stockSymbol.ok THEN Fail ELSE
    LET priceLong == ReadBytes(stockSymbol.rest, 14) IN IF ~priceLong.ok THEN Fail ELSE
    LET executionId == ReadBytes(priceLong.rest, 12) IN IF ~executionId.ok THEN Fail ELSE
    Ok([ executedShares |-> executedShares.value,
         stockSymbol    |-> stockSymbol.value,
         priceLong      |-> priceLong.value,
         executionId    |-> executionId.value ], executionId.rest)

ZeroLastSaleExtendedMessage ==
    [ executedShares |-> [i \in 1 .. 8 |-> 0],
      stockSymbol    |-> [i \in 1 .. 8 |-> 0],
      priceLong      |-> [i \in 1 .. 14 |-> 0],
      executionId    |-> [i \in 1 .. 12 |-> 0] ]

(* Last Sale Extended Message at zero, then each field in turn at the values it is checked at *)
CheckedLastSaleExtendedMessage ==
    { ZeroLastSaleExtendedMessage }
        \cup { [ZeroLastSaleExtendedMessage EXCEPT !.executedShares = one] : one \in Sample(8) }
        \cup { [ZeroLastSaleExtendedMessage EXCEPT !.stockSymbol = one] : one \in Sample(8) }
        \cup { [ZeroLastSaleExtendedMessage EXCEPT !.priceLong = one] : one \in Sample(14) }
        \cup { [ZeroLastSaleExtendedMessage EXCEPT !.executionId = one] : one \in Sample(12) }

(***************************************************************************)
(* Trade Break Message: 12 bytes                                           *)
(***************************************************************************)

TradeBreakMessage ==
    [ executionId : Sample(12) ]

EncodeTradeBreakMessage(message) ==
    message.executionId

DecodeTradeBreakMessage(bytes) ==
    LET executionId == ReadBytes(bytes, 12) IN IF ~executionId.ok THEN Fail ELSE
    Ok([ executionId |-> executionId.value ], executionId.rest)

ZeroTradeBreakMessage ==
    [ executionId |-> [i \in 1 .. 12 |-> 0] ]

(* Trade Break Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeBreakMessage ==
    { ZeroTradeBreakMessage }
        \cup { [ZeroTradeBreakMessage EXCEPT !.executionId = one] : one \in Sample(12) }

(***************************************************************************)
(* Sequenced Message, selected by Sequenced Message Type                   *)
(***************************************************************************)

LastSaleMessageCode == 76  \* "L"
LastSaleExtendedMessageCode == 53  \* "5"
TradeBreakMessageCode == 66  \* "B"

SequencedMessage ==
    [ tag : {LastSaleMessageCode}, body : LastSaleMessage ]
        \cup [ tag : {LastSaleExtendedMessageCode}, body : LastSaleExtendedMessage ]
        \cup [ tag : {TradeBreakMessageCode}, body : TradeBreakMessage ]

EncodeSequencedMessage(message) ==
    CASE message.tag = LastSaleMessageCode -> EncodeLastSaleMessage(message.body)
      [] message.tag = LastSaleExtendedMessageCode -> EncodeLastSaleExtendedMessage(message.body)
      [] message.tag = TradeBreakMessageCode -> EncodeTradeBreakMessage(message.body)

DecodeSequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = LastSaleMessageCode -> DecodeLastSaleMessage(bytes)
              [] tag = LastSaleExtendedMessageCode -> DecodeLastSaleExtendedMessage(bytes)
              [] tag = TradeBreakMessageCode -> DecodeTradeBreakMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSequencedMessage == [tag |-> LastSaleMessageCode, body |-> ZeroLastSaleMessage]

(* Each Sequenced Message in turn, at the values the message it names is checked at *)
CheckedSequencedMessage ==
    { [tag |-> LastSaleMessageCode, body |-> one] : one \in CheckedLastSaleMessage }
        \cup { [tag |-> LastSaleExtendedMessageCode, body |-> one] : one \in CheckedLastSaleExtendedMessage }
        \cup { [tag |-> TradeBreakMessageCode, body |-> one] : one \in CheckedTradeBreakMessage }

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
    LET sequencedMessageType == ReadUIntBE(timestamp.rest, 1) IN IF ~sequencedMessageType.ok THEN Fail ELSE
    LET sequencedMessage == DecodeSequencedMessage(sequencedMessageType.value, sequencedMessageType.rest) IN IF ~sequencedMessage.ok THEN Fail ELSE
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
(* Login Request Packet: 36 bytes                                          *)
(***************************************************************************)

LoginRequestPacket ==
    [ username                : Sample(6),
      password                : Sample(10),
      requestedSession        : Sample(10),
      requestedSequenceNumber : Sample(10) ]

EncodeLoginRequestPacket(message) ==
    message.username
        \o message.password
        \o message.requestedSession
        \o message.requestedSequenceNumber

DecodeLoginRequestPacket(bytes) ==
    LET username == ReadBytes(bytes, 6) IN IF ~username.ok THEN Fail ELSE
    LET password == ReadBytes(username.rest, 10) IN IF ~password.ok THEN Fail ELSE
    LET requestedSession == ReadBytes(password.rest, 10) IN IF ~requestedSession.ok THEN Fail ELSE
    LET requestedSequenceNumber == ReadBytes(requestedSession.rest, 10) IN IF ~requestedSequenceNumber.ok THEN Fail ELSE
    Ok([ username                |-> username.value,
         password                |-> password.value,
         requestedSession        |-> requestedSession.value,
         requestedSequenceNumber |-> requestedSequenceNumber.value ], requestedSequenceNumber.rest)

ZeroLoginRequestPacket ==
    [ username                |-> [i \in 1 .. 6 |-> 0],
      password                |-> [i \in 1 .. 10 |-> 0],
      requestedSession        |-> [i \in 1 .. 10 |-> 0],
      requestedSequenceNumber |-> [i \in 1 .. 10 |-> 0] ]

(* Login Request Packet at zero, then each field in turn at the values it is checked at *)
CheckedLoginRequestPacket ==
    { ZeroLoginRequestPacket }
        \cup { [ZeroLoginRequestPacket EXCEPT !.username = one] : one \in Sample(6) }
        \cup { [ZeroLoginRequestPacket EXCEPT !.password = one] : one \in Sample(10) }
        \cup { [ZeroLoginRequestPacket EXCEPT !.requestedSession = one] : one \in Sample(10) }
        \cup { [ZeroLoginRequestPacket EXCEPT !.requestedSequenceNumber = one] : one \in Sample(10) }

(***************************************************************************)
(* Unsequenced Data Packet                                                 *)
(***************************************************************************)

UnsequencedDataPacket ==
    [ unsequencedMessage : SampleBytes ]

EncodeUnsequencedDataPacket(message) ==
    message.unsequencedMessage

DecodeUnsequencedDataPacket(bytes) ==
    LET unsequencedMessage == Ok(bytes, << >>) IN IF ~unsequencedMessage.ok THEN Fail ELSE
    Ok([ unsequencedMessage |-> unsequencedMessage.value ], unsequencedMessage.rest)

ZeroUnsequencedDataPacket ==
    [ unsequencedMessage |-> << >> ]

(* Unsequenced Data Packet at zero, then each field in turn at the values it is checked at *)
CheckedUnsequencedDataPacket ==
    { ZeroUnsequencedDataPacket }
        \cup { [ZeroUnsequencedDataPacket EXCEPT !.unsequencedMessage = one] : one \in SampleBytes }

(***************************************************************************)
(* Payload, selected by Packet Type                                        *)
(***************************************************************************)

DebugPacketCode == 43  \* "+"
LoginAcceptedPacketCode == 65  \* "A"
LoginRejectedPacketCode == 74  \* "J"
SequencedDataPacketCode == 83  \* "S"
LoginRequestPacketCode == 76  \* "L"
UnsequencedDataPacketCode == 85  \* "U"

Payload ==
    [ tag : {DebugPacketCode}, body : DebugPacket ]
        \cup [ tag : {LoginAcceptedPacketCode}, body : LoginAcceptedPacket ]
        \cup [ tag : {LoginRejectedPacketCode}, body : LoginRejectedPacket ]
        \cup [ tag : {SequencedDataPacketCode}, body : SequencedDataPacket ]
        \cup [ tag : {LoginRequestPacketCode}, body : LoginRequestPacket ]
        \cup [ tag : {UnsequencedDataPacketCode}, body : UnsequencedDataPacket ]

EncodePayload(message) ==
    CASE message.tag = DebugPacketCode -> EncodeDebugPacket(message.body)
      [] message.tag = LoginAcceptedPacketCode -> EncodeLoginAcceptedPacket(message.body)
      [] message.tag = LoginRejectedPacketCode -> EncodeLoginRejectedPacket(message.body)
      [] message.tag = SequencedDataPacketCode -> EncodeSequencedDataPacket(message.body)
      [] message.tag = LoginRequestPacketCode -> EncodeLoginRequestPacket(message.body)
      [] message.tag = UnsequencedDataPacketCode -> EncodeUnsequencedDataPacket(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = DebugPacketCode -> DecodeDebugPacket(bytes)
              [] tag = LoginAcceptedPacketCode -> DecodeLoginAcceptedPacket(bytes)
              [] tag = LoginRejectedPacketCode -> DecodeLoginRejectedPacket(bytes)
              [] tag = SequencedDataPacketCode -> DecodeSequencedDataPacket(bytes)
              [] tag = LoginRequestPacketCode -> DecodeLoginRequestPacket(bytes)
              [] tag = UnsequencedDataPacketCode -> DecodeUnsequencedDataPacket(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> DebugPacketCode, body |-> one] : one \in CheckedDebugPacket }
        \cup { [tag |-> LoginAcceptedPacketCode, body |-> one] : one \in CheckedLoginAcceptedPacket }
        \cup { [tag |-> LoginRejectedPacketCode, body |-> one] : one \in CheckedLoginRejectedPacket }
        \cup { [tag |-> SequencedDataPacketCode, body |-> one] : one \in CheckedSequencedDataPacket }
        \cup { [tag |-> LoginRequestPacketCode, body |-> one] : one \in CheckedLoginRequestPacket }
        \cup { [tag |-> UnsequencedDataPacketCode, body |-> one] : one \in CheckedUnsequencedDataPacket }

(***************************************************************************)
(* Frame, closed by Soup Lf                                                *)
(***************************************************************************)

Frame ==
    [ payload : Payload ]

EncodeFrameBody(message) ==
    EncodeUIntBE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

(* Soup Lf closes the record, so it is written after the body it closes *)
EncodeFrame(message) == EncodeFrameBody(message) \o <<10>>

DecodeFrameBody(bytes) ==
    LET packetType == ReadUIntBE(bytes, 1) IN IF ~packetType.ok THEN Fail ELSE
    LET payload == DecodePayload(packetType.value, packetType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

(* Soup Lf closes the record, so the body is the bytes ahead of the first one *)
DecodeFrame(bytes) ==
    LET closed == ReadClosed(bytes, 10) IN IF ~closed.ok THEN Fail ELSE
    LET body == DecodeFrameBody(closed.value)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, closed.rest)

ZeroFrame ==
    [ payload |-> ZeroPayload ]

(* Frame at zero, then each field in turn at the values it is checked at *)
CheckedFrame ==
    { ZeroFrame }
        \cup { [ZeroFrame EXCEPT !.payload = one] : one \in CheckedPayload }

(* A run of Frame, written one after another *)
RECURSIVE EncodeFrameList(_)
EncodeFrameList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeFrame(Head(messages)) \o EncodeFrameList(Tail(messages))

(* As many Frame as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadFrameAll(_)
ReadFrameAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeFrame(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadFrameAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Frame of each kind, for the lists that carry them *)
OneFrame ==
    { [ZeroFrame EXCEPT !.payload = [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]],
      [ZeroFrame EXCEPT !.payload = [tag |-> LoginAcceptedPacketCode, body |-> ZeroLoginAcceptedPacket]],
      [ZeroFrame EXCEPT !.payload = [tag |-> LoginRejectedPacketCode, body |-> ZeroLoginRejectedPacket]],
      [ZeroFrame EXCEPT !.payload = [tag |-> SequencedDataPacketCode, body |-> ZeroSequencedDataPacket]],
      [ZeroFrame EXCEPT !.payload = [tag |-> LoginRequestPacketCode, body |-> ZeroLoginRequestPacket]],
      [ZeroFrame EXCEPT !.payload = [tag |-> UnsequencedDataPacketCode, body |-> ZeroUnsequencedDataPacket]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ frame : SampleLists(OneFrame) ]

EncodePacket(message) ==
    EncodeFrameList(message.frame)

DecodePacket(bytes) ==
    LET frame == ReadFrameAll(bytes) IN IF ~frame.ok THEN Fail ELSE
    Ok([ frame |-> frame.value ], frame.rest)

ZeroPacket ==
    [ frame |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.frame = one] : one \in SampleLists(OneFrame) }

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

(* Every Last Sale Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLastSaleMessage ==
    \A message \in CheckedLastSaleMessage :
        LET read == DecodeLastSaleMessage(EncodeLastSaleMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Last Sale Extended Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLastSaleExtendedMessage ==
    \A message \in CheckedLastSaleExtendedMessage :
        LET read == DecodeLastSaleExtendedMessage(EncodeLastSaleExtendedMessage(message))
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

(* Every Sequenced Data Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripSequencedDataPacket ==
    \A message \in CheckedSequencedDataPacket :
        LET read == DecodeSequencedDataPacket(EncodeSequencedDataPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Request Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRequestPacket ==
    \A message \in CheckedLoginRequestPacket :
        LET read == DecodeLoginRequestPacket(EncodeLoginRequestPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Unsequenced Data Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripUnsequencedDataPacket ==
    \A message \in CheckedUnsequencedDataPacket :
        LET read == DecodeUnsequencedDataPacket(EncodeUnsequencedDataPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Frame decodes back to what was encoded, and leaves nothing over *)
RoundTripFrame ==
    \A message \in CheckedFrame :
        LET read == DecodeFrame(EncodeFrame(message))
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

(* A Sequenced Message is selected by the Sequenced Message Type it is written under *)
SelectsSequencedMessage ==
    \A message \in CheckedSequencedMessage :
        LET sent == EncodeSequencedMessage(message)
            read == DecodeSequencedMessage(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Payload is selected by the Packet Type it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET sent == EncodePayload(message)
            read == DecodePayload(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* No Frame writes the Soup Lf that closes it inside its own body, so *)
(* the first one found is the end of the record. Checked over the messages below, which *)
(* is weaker than a proof that none could. *)
ClosesFrame ==
    \A message \in CheckedFrame :
        LET body == EncodeFrameBody(message)
        IN  \A i \in 1 .. Len(body) : body[i] # 10

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
