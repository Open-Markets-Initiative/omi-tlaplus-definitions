-------------------- MODULE PhlxOptions_Cti_v3_0_Client --------------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Clearing Trade Interface v3.0                                  *)
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
(* Note: Unsequenced Data Packet fills what is left of the frame Packet    *)
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
(* Debug Packet: 1 bytes                                                   *)
(***************************************************************************)

DebugPacket ==
    [ debugText : Sample(1) ]

EncodeDebugPacket(message) ==
    message.debugText

DecodeDebugPacket(bytes) ==
    LET debugText == ReadBytes(bytes, 1) IN IF ~debugText.ok THEN Fail ELSE
    Ok([ debugText |-> debugText.value ], debugText.rest)

ZeroDebugPacket ==
    [ debugText |-> [i \in 1 .. 1 |-> 0] ]

(* Debug Packet at zero, then each field in turn at the values it is checked at *)
CheckedDebugPacket ==
    { ZeroDebugPacket }
        \cup { [ZeroDebugPacket EXCEPT !.debugText = one] : one \in Sample(1) }

(***************************************************************************)
(* Login Request Packet: 46 bytes                                          *)
(***************************************************************************)

LoginRequestPacket ==
    [ username                : Sample(6),
      password                : Sample(10),
      requestedSession        : Sample(10),
      requestedSequenceNumber : Sample(20) ]

EncodeLoginRequestPacket(message) ==
    message.username
        \o message.password
        \o message.requestedSession
        \o message.requestedSequenceNumber

DecodeLoginRequestPacket(bytes) ==
    LET username == ReadBytes(bytes, 6) IN IF ~username.ok THEN Fail ELSE
    LET password == ReadBytes(username.rest, 10) IN IF ~password.ok THEN Fail ELSE
    LET requestedSession == ReadBytes(password.rest, 10) IN IF ~requestedSession.ok THEN Fail ELSE
    LET requestedSequenceNumber == ReadBytes(requestedSession.rest, 20) IN IF ~requestedSequenceNumber.ok THEN Fail ELSE
    Ok([ username                |-> username.value,
         password                |-> password.value,
         requestedSession        |-> requestedSession.value,
         requestedSequenceNumber |-> requestedSequenceNumber.value ], requestedSequenceNumber.rest)

ZeroLoginRequestPacket ==
    [ username                |-> [i \in 1 .. 6 |-> 0],
      password                |-> [i \in 1 .. 10 |-> 0],
      requestedSession        |-> [i \in 1 .. 10 |-> 0],
      requestedSequenceNumber |-> [i \in 1 .. 20 |-> 0] ]

(* Login Request Packet at zero, then each field in turn at the values it is checked at *)
CheckedLoginRequestPacket ==
    { ZeroLoginRequestPacket }
        \cup { [ZeroLoginRequestPacket EXCEPT !.username = one] : one \in Sample(6) }
        \cup { [ZeroLoginRequestPacket EXCEPT !.password = one] : one \in Sample(10) }
        \cup { [ZeroLoginRequestPacket EXCEPT !.requestedSession = one] : one \in Sample(10) }
        \cup { [ZeroLoginRequestPacket EXCEPT !.requestedSequenceNumber = one] : one \in Sample(20) }

(***************************************************************************)
(* Unsequenced Data Packet                                                 *)
(***************************************************************************)

UnsequencedDataPacket ==
    [ unsequencedMessageType : Sample(1),
      unsequencedMessage     : SampleBytes ]

EncodeUnsequencedDataPacket(message) ==
    message.unsequencedMessageType
        \o message.unsequencedMessage

DecodeUnsequencedDataPacket(bytes) ==
    LET unsequencedMessageType == ReadBytes(bytes, 1) IN IF ~unsequencedMessageType.ok THEN Fail ELSE
    LET unsequencedMessage == Ok(unsequencedMessageType.rest, << >>) IN IF ~unsequencedMessage.ok THEN Fail ELSE
    Ok([ unsequencedMessageType |-> unsequencedMessageType.value,
         unsequencedMessage     |-> unsequencedMessage.value ], unsequencedMessage.rest)

ZeroUnsequencedDataPacket ==
    [ unsequencedMessageType |-> [i \in 1 .. 1 |-> 0],
      unsequencedMessage     |-> << >> ]

(* Unsequenced Data Packet at zero, then each field in turn at the values it is checked at *)
CheckedUnsequencedDataPacket ==
    { ZeroUnsequencedDataPacket }
        \cup { [ZeroUnsequencedDataPacket EXCEPT !.unsequencedMessageType = one] : one \in Sample(1) }
        \cup { [ZeroUnsequencedDataPacket EXCEPT !.unsequencedMessage = one] : one \in SampleBytes }

(***************************************************************************)
(* Client Payload, selected by Client Packet Type                          *)
(***************************************************************************)

DebugPacketCode == 43  \* "+"
LoginRequestPacketCode == 76  \* "L"
UnsequencedDataPacketCode == 85  \* "U"
ClientHeartbeatCode == 82  \* "R"
LogoutRequestCode == 79  \* "O"

ClientPayload ==
    [ tag : {DebugPacketCode}, body : DebugPacket ]
        \cup [ tag : {LoginRequestPacketCode}, body : LoginRequestPacket ]
        \cup [ tag : {UnsequencedDataPacketCode}, body : UnsequencedDataPacket ]
        \cup [ tag : {ClientHeartbeatCode}, body : {0} ]
        \cup [ tag : {LogoutRequestCode}, body : {0} ]

EncodeClientPayload(message) ==
    CASE message.tag = DebugPacketCode -> EncodeDebugPacket(message.body)
      [] message.tag = LoginRequestPacketCode -> EncodeLoginRequestPacket(message.body)
      [] message.tag = UnsequencedDataPacketCode -> EncodeUnsequencedDataPacket(message.body)
      [] message.tag = ClientHeartbeatCode -> << >>
      [] message.tag = LogoutRequestCode -> << >>

DecodeClientPayload(tag, bytes) ==
    LET read ==
            CASE tag = DebugPacketCode -> DecodeDebugPacket(bytes)
              [] tag = LoginRequestPacketCode -> DecodeLoginRequestPacket(bytes)
              [] tag = UnsequencedDataPacketCode -> DecodeUnsequencedDataPacket(bytes)
              [] tag = ClientHeartbeatCode -> Ok(0, bytes)
              [] tag = LogoutRequestCode -> Ok(0, bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroClientPayload == [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]

(* Each Client Payload in turn, at the values the message it names is checked at *)
CheckedClientPayload ==
    { [tag |-> DebugPacketCode, body |-> one] : one \in CheckedDebugPacket }
        \cup { [tag |-> LoginRequestPacketCode, body |-> one] : one \in CheckedLoginRequestPacket }
        \cup { [tag |-> UnsequencedDataPacketCode, body |-> one] : one \in CheckedUnsequencedDataPacket }
        \cup { [tag |-> ClientHeartbeatCode, body |-> 0] }
        \cup { [tag |-> LogoutRequestCode, body |-> 0] }

(***************************************************************************)
(* Client Soup Bin Tcp Packet, framed by Packet Length                     *)
(***************************************************************************)

ClientSoupBinTcpPacket ==
    [ clientPayload : ClientPayload ]

EncodeClientSoupBinTcpPacketBody(message) ==
    EncodeUIntBE(message.clientPayload.tag, 1)
        \o EncodeClientPayload(message.clientPayload)

(* Packet Length counts the bytes it frames, so it is written from them *)
EncodeClientSoupBinTcpPacket(message) ==
    LET body == EncodeClientSoupBinTcpPacketBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeClientSoupBinTcpPacketBody(bytes) ==
    LET clientPacketType == ReadUIntBE(bytes, 1) IN IF ~clientPacketType.ok THEN Fail ELSE
    LET clientPayload == DecodeClientPayload(clientPacketType.value, clientPacketType.rest) IN IF ~clientPayload.ok THEN Fail ELSE
    Ok([ clientPayload |-> clientPayload.value ], clientPayload.rest)

DecodeClientSoupBinTcpPacket(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeClientSoupBinTcpPacketBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroClientSoupBinTcpPacket ==
    [ clientPayload |-> ZeroClientPayload ]

(* Client Soup Bin Tcp Packet at zero, then each field in turn at the values it is checked at *)
CheckedClientSoupBinTcpPacket ==
    { ZeroClientSoupBinTcpPacket }
        \cup { [ZeroClientSoupBinTcpPacket EXCEPT !.clientPayload = one] : one \in CheckedClientPayload }

(* A run of Client Soup Bin Tcp Packet, written one after another *)
RECURSIVE EncodeClientSoupBinTcpPacketList(_)
EncodeClientSoupBinTcpPacketList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeClientSoupBinTcpPacket(Head(messages)) \o EncodeClientSoupBinTcpPacketList(Tail(messages))

(* As many Client Soup Bin Tcp Packet as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadClientSoupBinTcpPacketAll(_)
ReadClientSoupBinTcpPacketAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeClientSoupBinTcpPacket(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadClientSoupBinTcpPacketAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Client Soup Bin Tcp Packet of each kind, for the lists that carry them *)
OneClientSoupBinTcpPacket ==
    { [ZeroClientSoupBinTcpPacket EXCEPT !.clientPayload = [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]],
      [ZeroClientSoupBinTcpPacket EXCEPT !.clientPayload = [tag |-> LoginRequestPacketCode, body |-> ZeroLoginRequestPacket]],
      [ZeroClientSoupBinTcpPacket EXCEPT !.clientPayload = [tag |-> UnsequencedDataPacketCode, body |-> ZeroUnsequencedDataPacket]],
      [ZeroClientSoupBinTcpPacket EXCEPT !.clientPayload = [tag |-> ClientHeartbeatCode, body |-> 0]],
      [ZeroClientSoupBinTcpPacket EXCEPT !.clientPayload = [tag |-> LogoutRequestCode, body |-> 0]] }

(***************************************************************************)
(* Client Packet                                                           *)
(***************************************************************************)

ClientPacket ==
    [ clientSoupBinTcpPacket : SampleLists(OneClientSoupBinTcpPacket) ]

EncodeClientPacket(message) ==
    EncodeClientSoupBinTcpPacketList(message.clientSoupBinTcpPacket)

DecodeClientPacket(bytes) ==
    LET clientSoupBinTcpPacket == ReadClientSoupBinTcpPacketAll(bytes) IN IF ~clientSoupBinTcpPacket.ok THEN Fail ELSE
    Ok([ clientSoupBinTcpPacket |-> clientSoupBinTcpPacket.value ], clientSoupBinTcpPacket.rest)

ZeroClientPacket ==
    [ clientSoupBinTcpPacket |-> << >> ]

(* Client Packet at zero, then each field in turn at the values it is checked at *)
CheckedClientPacket ==
    { ZeroClientPacket }
        \cup { [ZeroClientPacket EXCEPT !.clientSoupBinTcpPacket = one] : one \in SampleLists(OneClientSoupBinTcpPacket) }

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

(* Every Client Soup Bin Tcp Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripClientSoupBinTcpPacket ==
    \A message \in CheckedClientSoupBinTcpPacket :
        LET read == DecodeClientSoupBinTcpPacket(EncodeClientSoupBinTcpPacket(message))
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

(* A Client Payload is selected by the Client Packet Type it is written under *)
SelectsClientPayload ==
    \A message \in CheckedClientPayload :
        LET read == DecodeClientPayload(message.tag, EncodeClientPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Packet Length is written from the bytes it frames *)
FramesClientSoupBinTcpPacket ==
    \A message \in CheckedClientSoupBinTcpPacket :
        LET bytes == EncodeClientSoupBinTcpPacket(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
