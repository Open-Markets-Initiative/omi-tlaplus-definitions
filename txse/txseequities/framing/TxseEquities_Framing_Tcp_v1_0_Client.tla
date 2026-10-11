--------------- MODULE TxseEquities_Framing_Tcp_v1_0_Client ----------------
(***************************************************************************)
(* Texas Stock Exchange  v1.0                                              *)
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
(* Note: Tcp Unsequenced Message fills what is left of the frame Message   *)
(* Length states, which is what it is read from.                           *)
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
(* Logon Request Packet: 32 bytes                                          *)
(***************************************************************************)

LogonRequestPacket ==
    [ session            : Sample(8),
      senderComp         : Sample(8),
      token              : Sample(8),
      nextSequenceNumber : Sample(8) ]

EncodeLogonRequestPacket(message) ==
    message.session
        \o message.senderComp
        \o message.token
        \o message.nextSequenceNumber

DecodeLogonRequestPacket(bytes) ==
    LET session == ReadBytes(bytes, 8) IN IF ~session.ok THEN Fail ELSE
    LET senderComp == ReadBytes(session.rest, 8) IN IF ~senderComp.ok THEN Fail ELSE
    LET token == ReadBytes(senderComp.rest, 8) IN IF ~token.ok THEN Fail ELSE
    LET nextSequenceNumber == ReadBytes(token.rest, 8) IN IF ~nextSequenceNumber.ok THEN Fail ELSE
    Ok([ session            |-> session.value,
         senderComp         |-> senderComp.value,
         token              |-> token.value,
         nextSequenceNumber |-> nextSequenceNumber.value ], nextSequenceNumber.rest)

ZeroLogonRequestPacket ==
    [ session            |-> [i \in 1 .. 8 |-> 0],
      senderComp         |-> [i \in 1 .. 8 |-> 0],
      token              |-> [i \in 1 .. 8 |-> 0],
      nextSequenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Logon Request Packet at zero, then each field in turn at the values it is checked at *)
CheckedLogonRequestPacket ==
    { ZeroLogonRequestPacket }
        \cup { [ZeroLogonRequestPacket EXCEPT !.session = one] : one \in Sample(8) }
        \cup { [ZeroLogonRequestPacket EXCEPT !.senderComp = one] : one \in Sample(8) }
        \cup { [ZeroLogonRequestPacket EXCEPT !.token = one] : one \in Sample(8) }
        \cup { [ZeroLogonRequestPacket EXCEPT !.nextSequenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Tcp Unsequenced Message                                                 *)
(***************************************************************************)

TcpUnsequencedMessage ==
    [ messageType        : Sample(1),
      unsequencedMessage : SampleBytes ]

EncodeTcpUnsequencedMessage(message) ==
    message.messageType
        \o message.unsequencedMessage

DecodeTcpUnsequencedMessage(bytes) ==
    LET messageType == ReadBytes(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET unsequencedMessage == Ok(messageType.rest, << >>) IN IF ~unsequencedMessage.ok THEN Fail ELSE
    Ok([ messageType        |-> messageType.value,
         unsequencedMessage |-> unsequencedMessage.value ], unsequencedMessage.rest)

ZeroTcpUnsequencedMessage ==
    [ messageType        |-> [i \in 1 .. 1 |-> 0],
      unsequencedMessage |-> << >> ]

(* Tcp Unsequenced Message at zero, then each field in turn at the values it is checked at *)
CheckedTcpUnsequencedMessage ==
    { ZeroTcpUnsequencedMessage }
        \cup { [ZeroTcpUnsequencedMessage EXCEPT !.messageType = one] : one \in Sample(1) }
        \cup { [ZeroTcpUnsequencedMessage EXCEPT !.unsequencedMessage = one] : one \in SampleBytes }

(***************************************************************************)
(* Client Payload, selected by Packet Type                                 *)
(***************************************************************************)

LogonRequestPacketCode == 53  \* 0x35
TcpUnsequencedMessageCode == 54  \* 0x36

ClientPayload ==
    [ tag : {LogonRequestPacketCode}, body : LogonRequestPacket ]
        \cup [ tag : {TcpUnsequencedMessageCode}, body : TcpUnsequencedMessage ]

EncodeClientPayload(message) ==
    CASE message.tag = LogonRequestPacketCode -> EncodeLogonRequestPacket(message.body)
      [] message.tag = TcpUnsequencedMessageCode -> EncodeTcpUnsequencedMessage(message.body)

DecodeClientPayload(tag, bytes) ==
    LET read ==
            CASE tag = LogonRequestPacketCode -> DecodeLogonRequestPacket(bytes)
              [] tag = TcpUnsequencedMessageCode -> DecodeTcpUnsequencedMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroClientPayload == [tag |-> LogonRequestPacketCode, body |-> ZeroLogonRequestPacket]

(* Each Client Payload in turn, at the values the message it names is checked at *)
CheckedClientPayload ==
    { [tag |-> LogonRequestPacketCode, body |-> one] : one \in CheckedLogonRequestPacket }
        \cup { [tag |-> TcpUnsequencedMessageCode, body |-> one] : one \in CheckedTcpUnsequencedMessage }

(***************************************************************************)
(* Client Rake Tcp Message, framed by Message Length                       *)
(***************************************************************************)

ClientRakeTcpMessage ==
    [ clientPayload : ClientPayload ]

EncodeClientRakeTcpMessageBody(message) ==
    EncodeUIntLE(message.clientPayload.tag, 1)
        \o EncodeClientPayload(message.clientPayload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeClientRakeTcpMessage(message) ==
    LET body == EncodeClientRakeTcpMessageBody(message)
    IN  EncodeUIntLE(Len(body), 2) \o body

DecodeClientRakeTcpMessageBody(bytes) ==
    LET packetType == ReadUIntLE(bytes, 1) IN IF ~packetType.ok THEN Fail ELSE
    LET clientPayload == DecodeClientPayload(packetType.value, packetType.rest) IN IF ~clientPayload.ok THEN Fail ELSE
    Ok([ clientPayload |-> clientPayload.value ], clientPayload.rest)

DecodeClientRakeTcpMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeClientRakeTcpMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroClientRakeTcpMessage ==
    [ clientPayload |-> ZeroClientPayload ]

(* Client Rake Tcp Message at zero, then each field in turn at the values it is checked at *)
CheckedClientRakeTcpMessage ==
    { ZeroClientRakeTcpMessage }
        \cup { [ZeroClientRakeTcpMessage EXCEPT !.clientPayload = one] : one \in CheckedClientPayload }

(* A run of Client Rake Tcp Message, written one after another *)
RECURSIVE EncodeClientRakeTcpMessageList(_)
EncodeClientRakeTcpMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeClientRakeTcpMessage(Head(messages)) \o EncodeClientRakeTcpMessageList(Tail(messages))

(* As many Client Rake Tcp Message as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadClientRakeTcpMessageAll(_)
ReadClientRakeTcpMessageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeClientRakeTcpMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadClientRakeTcpMessageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Client Rake Tcp Message of each kind, for the lists that carry them *)
OneClientRakeTcpMessage ==
    { [ZeroClientRakeTcpMessage EXCEPT !.clientPayload = [tag |-> LogonRequestPacketCode, body |-> ZeroLogonRequestPacket]],
      [ZeroClientRakeTcpMessage EXCEPT !.clientPayload = [tag |-> TcpUnsequencedMessageCode, body |-> ZeroTcpUnsequencedMessage]] }

(***************************************************************************)
(* Client Packet                                                           *)
(***************************************************************************)

ClientPacket ==
    [ clientRakeTcpMessage : SampleLists(OneClientRakeTcpMessage) ]

EncodeClientPacket(message) ==
    EncodeClientRakeTcpMessageList(message.clientRakeTcpMessage)

DecodeClientPacket(bytes) ==
    LET clientRakeTcpMessage == ReadClientRakeTcpMessageAll(bytes) IN IF ~clientRakeTcpMessage.ok THEN Fail ELSE
    Ok([ clientRakeTcpMessage |-> clientRakeTcpMessage.value ], clientRakeTcpMessage.rest)

ZeroClientPacket ==
    [ clientRakeTcpMessage |-> << >> ]

(* Client Packet at zero, then each field in turn at the values it is checked at *)
CheckedClientPacket ==
    { ZeroClientPacket }
        \cup { [ZeroClientPacket EXCEPT !.clientRakeTcpMessage = one] : one \in SampleLists(OneClientRakeTcpMessage) }

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

(* Every Logon Request Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripLogonRequestPacket ==
    \A message \in CheckedLogonRequestPacket :
        LET read == DecodeLogonRequestPacket(EncodeLogonRequestPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tcp Unsequenced Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTcpUnsequencedMessage ==
    \A message \in CheckedTcpUnsequencedMessage :
        LET read == DecodeTcpUnsequencedMessage(EncodeTcpUnsequencedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client Rake Tcp Message decodes back to what was encoded, and leaves nothing over *)
RoundTripClientRakeTcpMessage ==
    \A message \in CheckedClientRakeTcpMessage :
        LET read == DecodeClientRakeTcpMessage(EncodeClientRakeTcpMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripClientPacket ==
    \A message \in CheckedClientPacket :
        LET read == DecodeClientPacket(EncodeClientPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Client Payload is selected by the Packet Type it is written under *)
SelectsClientPayload ==
    \A message \in CheckedClientPayload :
        LET read == DecodeClientPayload(message.tag, EncodeClientPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Message Length is written from the bytes it frames *)
FramesClientRakeTcpMessage ==
    \A message \in CheckedClientRakeTcpMessage :
        LET bytes == EncodeClientRakeTcpMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
