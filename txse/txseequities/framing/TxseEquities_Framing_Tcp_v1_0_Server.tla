--------------- MODULE TxseEquities_Framing_Tcp_v1_0_Server ----------------
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
(* Note: Tcp Sequenced Message fills what is left of the frame Message     *)
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
(* Debug Message                                                           *)
(***************************************************************************)

DebugMessage ==
    [ text : SampleBytes ]

EncodeDebugMessage(message) ==
    message.text

DecodeDebugMessage(bytes) ==
    LET text == Ok(bytes, << >>) IN IF ~text.ok THEN Fail ELSE
    Ok([ text |-> text.value ], text.rest)

ZeroDebugMessage ==
    [ text |-> << >> ]

(* Debug Message at zero, then each field in turn at the values it is checked at *)
CheckedDebugMessage ==
    { ZeroDebugMessage }
        \cup { [ZeroDebugMessage EXCEPT !.text = one] : one \in SampleBytes }

(***************************************************************************)
(* Logon Response Message: 30 bytes                                        *)
(***************************************************************************)

LogonResponseMessage ==
    [ session                    : Sample(8),
      nextSequenceNumber         : Sample(8),
      highestKnownSequenceNumber : Sample(8),
      logonResponseCode          : Sample(1),
      numberStreamIds            : Sample(1),
      instance                   : Sample(4) ]

EncodeLogonResponseMessage(message) ==
    message.session
        \o message.nextSequenceNumber
        \o message.highestKnownSequenceNumber
        \o message.logonResponseCode
        \o message.numberStreamIds
        \o message.instance

DecodeLogonResponseMessage(bytes) ==
    LET session == ReadBytes(bytes, 8) IN IF ~session.ok THEN Fail ELSE
    LET nextSequenceNumber == ReadBytes(session.rest, 8) IN IF ~nextSequenceNumber.ok THEN Fail ELSE
    LET highestKnownSequenceNumber == ReadBytes(nextSequenceNumber.rest, 8) IN IF ~highestKnownSequenceNumber.ok THEN Fail ELSE
    LET logonResponseCode == ReadBytes(highestKnownSequenceNumber.rest, 1) IN IF ~logonResponseCode.ok THEN Fail ELSE
    LET numberStreamIds == ReadBytes(logonResponseCode.rest, 1) IN IF ~numberStreamIds.ok THEN Fail ELSE
    LET instance == ReadBytes(numberStreamIds.rest, 4) IN IF ~instance.ok THEN Fail ELSE
    Ok([ session                    |-> session.value,
         nextSequenceNumber         |-> nextSequenceNumber.value,
         highestKnownSequenceNumber |-> highestKnownSequenceNumber.value,
         logonResponseCode          |-> logonResponseCode.value,
         numberStreamIds            |-> numberStreamIds.value,
         instance                   |-> instance.value ], instance.rest)

ZeroLogonResponseMessage ==
    [ session                    |-> [i \in 1 .. 8 |-> 0],
      nextSequenceNumber         |-> [i \in 1 .. 8 |-> 0],
      highestKnownSequenceNumber |-> [i \in 1 .. 8 |-> 0],
      logonResponseCode          |-> [i \in 1 .. 1 |-> 0],
      numberStreamIds            |-> [i \in 1 .. 1 |-> 0],
      instance                   |-> [i \in 1 .. 4 |-> 0] ]

(* Logon Response Message at zero, then each field in turn at the values it is checked at *)
CheckedLogonResponseMessage ==
    { ZeroLogonResponseMessage }
        \cup { [ZeroLogonResponseMessage EXCEPT !.session = one] : one \in Sample(8) }
        \cup { [ZeroLogonResponseMessage EXCEPT !.nextSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroLogonResponseMessage EXCEPT !.highestKnownSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroLogonResponseMessage EXCEPT !.logonResponseCode = one] : one \in Sample(1) }
        \cup { [ZeroLogonResponseMessage EXCEPT !.numberStreamIds = one] : one \in Sample(1) }
        \cup { [ZeroLogonResponseMessage EXCEPT !.instance = one] : one \in Sample(4) }

(***************************************************************************)
(* Tcp Sequenced Message                                                   *)
(***************************************************************************)

TcpSequencedMessage ==
    [ streamId         : Sample(1),
      messageType      : Sample(1),
      sequencedMessage : SampleBytes ]

EncodeTcpSequencedMessage(message) ==
    message.streamId
        \o message.messageType
        \o message.sequencedMessage

DecodeTcpSequencedMessage(bytes) ==
    LET streamId == ReadBytes(bytes, 1) IN IF ~streamId.ok THEN Fail ELSE
    LET messageType == ReadBytes(streamId.rest, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET sequencedMessage == Ok(messageType.rest, << >>) IN IF ~sequencedMessage.ok THEN Fail ELSE
    Ok([ streamId         |-> streamId.value,
         messageType      |-> messageType.value,
         sequencedMessage |-> sequencedMessage.value ], sequencedMessage.rest)

ZeroTcpSequencedMessage ==
    [ streamId         |-> [i \in 1 .. 1 |-> 0],
      messageType      |-> [i \in 1 .. 1 |-> 0],
      sequencedMessage |-> << >> ]

(* Tcp Sequenced Message at zero, then each field in turn at the values it is checked at *)
CheckedTcpSequencedMessage ==
    { ZeroTcpSequencedMessage }
        \cup { [ZeroTcpSequencedMessage EXCEPT !.streamId = one] : one \in Sample(1) }
        \cup { [ZeroTcpSequencedMessage EXCEPT !.messageType = one] : one \in Sample(1) }
        \cup { [ZeroTcpSequencedMessage EXCEPT !.sequencedMessage = one] : one \in SampleBytes }

(***************************************************************************)
(* Server Payload, selected by Packet Type                                 *)
(***************************************************************************)

DebugMessageCode == 48  \* 0x30
EndOfSessionMessageCode == 52  \* 0x34
LogonResponseMessageCode == 49  \* 0x31
TcpSequencedMessageCode == 50  \* 0x32

ServerPayload ==
    [ tag : {DebugMessageCode}, body : DebugMessage ]
        \cup [ tag : {EndOfSessionMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {LogonResponseMessageCode}, body : LogonResponseMessage ]
        \cup [ tag : {TcpSequencedMessageCode}, body : TcpSequencedMessage ]

EncodeServerPayload(message) ==
    CASE message.tag = DebugMessageCode -> EncodeDebugMessage(message.body)
      [] message.tag = EndOfSessionMessageCode -> << >>
      [] message.tag = LogonResponseMessageCode -> EncodeLogonResponseMessage(message.body)
      [] message.tag = TcpSequencedMessageCode -> EncodeTcpSequencedMessage(message.body)

DecodeServerPayload(tag, bytes) ==
    LET read ==
            CASE tag = DebugMessageCode -> DecodeDebugMessage(bytes)
              [] tag = EndOfSessionMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = LogonResponseMessageCode -> DecodeLogonResponseMessage(bytes)
              [] tag = TcpSequencedMessageCode -> DecodeTcpSequencedMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroServerPayload == [tag |-> DebugMessageCode, body |-> ZeroDebugMessage]

(* Each Server Payload in turn, at the values the message it names is checked at *)
CheckedServerPayload ==
    { [tag |-> DebugMessageCode, body |-> one] : one \in CheckedDebugMessage }
        \cup { [tag |-> EndOfSessionMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> LogonResponseMessageCode, body |-> one] : one \in CheckedLogonResponseMessage }
        \cup { [tag |-> TcpSequencedMessageCode, body |-> one] : one \in CheckedTcpSequencedMessage }

(***************************************************************************)
(* Server Rake Tcp Message, framed by Message Length                       *)
(***************************************************************************)

ServerRakeTcpMessage ==
    [ serverPayload : ServerPayload ]

EncodeServerRakeTcpMessageBody(message) ==
    EncodeUIntLE(message.serverPayload.tag, 1)
        \o EncodeServerPayload(message.serverPayload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeServerRakeTcpMessage(message) ==
    LET body == EncodeServerRakeTcpMessageBody(message)
    IN  EncodeUIntLE(Len(body), 2) \o body

DecodeServerRakeTcpMessageBody(bytes) ==
    LET packetType == ReadUIntLE(bytes, 1) IN IF ~packetType.ok THEN Fail ELSE
    LET serverPayload == DecodeServerPayload(packetType.value, packetType.rest) IN IF ~serverPayload.ok THEN Fail ELSE
    Ok([ serverPayload |-> serverPayload.value ], serverPayload.rest)

DecodeServerRakeTcpMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeServerRakeTcpMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroServerRakeTcpMessage ==
    [ serverPayload |-> ZeroServerPayload ]

(* Server Rake Tcp Message at zero, then each field in turn at the values it is checked at *)
CheckedServerRakeTcpMessage ==
    { ZeroServerRakeTcpMessage }
        \cup { [ZeroServerRakeTcpMessage EXCEPT !.serverPayload = one] : one \in CheckedServerPayload }

(* A run of Server Rake Tcp Message, written one after another *)
RECURSIVE EncodeServerRakeTcpMessageList(_)
EncodeServerRakeTcpMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeServerRakeTcpMessage(Head(messages)) \o EncodeServerRakeTcpMessageList(Tail(messages))

(* As many Server Rake Tcp Message as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadServerRakeTcpMessageAll(_)
ReadServerRakeTcpMessageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeServerRakeTcpMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadServerRakeTcpMessageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Server Rake Tcp Message of each kind, for the lists that carry them *)
OneServerRakeTcpMessage ==
    { [ZeroServerRakeTcpMessage EXCEPT !.serverPayload = [tag |-> DebugMessageCode, body |-> ZeroDebugMessage]],
      [ZeroServerRakeTcpMessage EXCEPT !.serverPayload = [tag |-> EndOfSessionMessageCode, body |-> [empty |-> 0]]],
      [ZeroServerRakeTcpMessage EXCEPT !.serverPayload = [tag |-> LogonResponseMessageCode, body |-> ZeroLogonResponseMessage]],
      [ZeroServerRakeTcpMessage EXCEPT !.serverPayload = [tag |-> TcpSequencedMessageCode, body |-> ZeroTcpSequencedMessage]] }

(***************************************************************************)
(* Server Packet                                                           *)
(***************************************************************************)

ServerPacket ==
    [ serverRakeTcpMessage : SampleLists(OneServerRakeTcpMessage) ]

EncodeServerPacket(message) ==
    EncodeServerRakeTcpMessageList(message.serverRakeTcpMessage)

DecodeServerPacket(bytes) ==
    LET serverRakeTcpMessage == ReadServerRakeTcpMessageAll(bytes) IN IF ~serverRakeTcpMessage.ok THEN Fail ELSE
    Ok([ serverRakeTcpMessage |-> serverRakeTcpMessage.value ], serverRakeTcpMessage.rest)

ZeroServerPacket ==
    [ serverRakeTcpMessage |-> << >> ]

(* Server Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerPacket ==
    { ZeroServerPacket }
        \cup { [ZeroServerPacket EXCEPT !.serverRakeTcpMessage = one] : one \in SampleLists(OneServerRakeTcpMessage) }

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

(* Every Debug Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDebugMessage ==
    \A message \in CheckedDebugMessage :
        LET read == DecodeDebugMessage(EncodeDebugMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logon Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogonResponseMessage ==
    \A message \in CheckedLogonResponseMessage :
        LET read == DecodeLogonResponseMessage(EncodeLogonResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tcp Sequenced Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTcpSequencedMessage ==
    \A message \in CheckedTcpSequencedMessage :
        LET read == DecodeTcpSequencedMessage(EncodeTcpSequencedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Server Rake Tcp Message decodes back to what was encoded, and leaves nothing over *)
RoundTripServerRakeTcpMessage ==
    \A message \in CheckedServerRakeTcpMessage :
        LET read == DecodeServerRakeTcpMessage(EncodeServerRakeTcpMessage(message))
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

(* A Server Payload is selected by the Packet Type it is written under *)
SelectsServerPayload ==
    \A message \in CheckedServerPayload :
        LET read == DecodeServerPayload(message.tag, EncodeServerPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Message Length is written from the bytes it frames *)
FramesServerRakeTcpMessage ==
    \A message \in CheckedServerRakeTcpMessage :
        LET bytes == EncodeServerRakeTcpMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
