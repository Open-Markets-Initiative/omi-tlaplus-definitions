---------------- MODULE NseEquities_MarketByOrder_v1_1_Tcp -----------------
(***************************************************************************)
(* Japan Exchange Group Market By Order v1.1                               *)
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
(* Note: Data is as wide as what is left of Message Response Message: it   *)
(* is read as the bytes left of what its record was given, which the       *)
(* records above it keep those bytes back from.                            *)
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
(* Login Request Retransmission Message: 15 bytes                          *)
(***************************************************************************)

LoginRequestRetransmissionMessage ==
    [ userId                : Sample(6),
      multicastGroupNumber  : Sample(1),
      numberOfSystemReboots : Sample(1),
      sequenceNumber        : Sample(4),
      requestedMessageCount : Sample(3) ]

EncodeLoginRequestRetransmissionMessage(message) ==
    message.userId
        \o message.multicastGroupNumber
        \o message.numberOfSystemReboots
        \o message.sequenceNumber
        \o message.requestedMessageCount

DecodeLoginRequestRetransmissionMessage(bytes) ==
    LET userId == ReadBytes(bytes, 6) IN IF ~userId.ok THEN Fail ELSE
    LET multicastGroupNumber == ReadBytes(userId.rest, 1) IN IF ~multicastGroupNumber.ok THEN Fail ELSE
    LET numberOfSystemReboots == ReadBytes(multicastGroupNumber.rest, 1) IN IF ~numberOfSystemReboots.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(numberOfSystemReboots.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET requestedMessageCount == ReadBytes(sequenceNumber.rest, 3) IN IF ~requestedMessageCount.ok THEN Fail ELSE
    Ok([ userId                |-> userId.value,
         multicastGroupNumber  |-> multicastGroupNumber.value,
         numberOfSystemReboots |-> numberOfSystemReboots.value,
         sequenceNumber        |-> sequenceNumber.value,
         requestedMessageCount |-> requestedMessageCount.value ], requestedMessageCount.rest)

ZeroLoginRequestRetransmissionMessage ==
    [ userId                |-> [i \in 1 .. 6 |-> 0],
      multicastGroupNumber  |-> [i \in 1 .. 1 |-> 0],
      numberOfSystemReboots |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber        |-> [i \in 1 .. 4 |-> 0],
      requestedMessageCount |-> [i \in 1 .. 3 |-> 0] ]

(* Login Request Retransmission Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginRequestRetransmissionMessage ==
    { ZeroLoginRequestRetransmissionMessage }
        \cup { [ZeroLoginRequestRetransmissionMessage EXCEPT !.userId = one] : one \in Sample(6) }
        \cup { [ZeroLoginRequestRetransmissionMessage EXCEPT !.multicastGroupNumber = one] : one \in Sample(1) }
        \cup { [ZeroLoginRequestRetransmissionMessage EXCEPT !.numberOfSystemReboots = one] : one \in Sample(1) }
        \cup { [ZeroLoginRequestRetransmissionMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroLoginRequestRetransmissionMessage EXCEPT !.requestedMessageCount = one] : one \in Sample(3) }

(***************************************************************************)
(* Login Request Snapshot Message: 15 bytes                                *)
(***************************************************************************)

LoginRequestSnapshotMessage ==
    [ userId                : Sample(6),
      multicastGroupNumber  : Sample(1),
      numberOfSystemReboots : Sample(1),
      sequenceNumber        : Sample(4),
      requestedMessageCount : Sample(3) ]

EncodeLoginRequestSnapshotMessage(message) ==
    message.userId
        \o message.multicastGroupNumber
        \o message.numberOfSystemReboots
        \o message.sequenceNumber
        \o message.requestedMessageCount

DecodeLoginRequestSnapshotMessage(bytes) ==
    LET userId == ReadBytes(bytes, 6) IN IF ~userId.ok THEN Fail ELSE
    LET multicastGroupNumber == ReadBytes(userId.rest, 1) IN IF ~multicastGroupNumber.ok THEN Fail ELSE
    LET numberOfSystemReboots == ReadBytes(multicastGroupNumber.rest, 1) IN IF ~numberOfSystemReboots.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(numberOfSystemReboots.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET requestedMessageCount == ReadBytes(sequenceNumber.rest, 3) IN IF ~requestedMessageCount.ok THEN Fail ELSE
    Ok([ userId                |-> userId.value,
         multicastGroupNumber  |-> multicastGroupNumber.value,
         numberOfSystemReboots |-> numberOfSystemReboots.value,
         sequenceNumber        |-> sequenceNumber.value,
         requestedMessageCount |-> requestedMessageCount.value ], requestedMessageCount.rest)

ZeroLoginRequestSnapshotMessage ==
    [ userId                |-> [i \in 1 .. 6 |-> 0],
      multicastGroupNumber  |-> [i \in 1 .. 1 |-> 0],
      numberOfSystemReboots |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber        |-> [i \in 1 .. 4 |-> 0],
      requestedMessageCount |-> [i \in 1 .. 3 |-> 0] ]

(* Login Request Snapshot Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginRequestSnapshotMessage ==
    { ZeroLoginRequestSnapshotMessage }
        \cup { [ZeroLoginRequestSnapshotMessage EXCEPT !.userId = one] : one \in Sample(6) }
        \cup { [ZeroLoginRequestSnapshotMessage EXCEPT !.multicastGroupNumber = one] : one \in Sample(1) }
        \cup { [ZeroLoginRequestSnapshotMessage EXCEPT !.numberOfSystemReboots = one] : one \in Sample(1) }
        \cup { [ZeroLoginRequestSnapshotMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroLoginRequestSnapshotMessage EXCEPT !.requestedMessageCount = one] : one \in Sample(3) }

(***************************************************************************)
(* Login Result Accepted Message: 2 bytes                                  *)
(***************************************************************************)

LoginResultAcceptedMessage ==
    [ multicastGroupNumber : Sample(1),
      resultCode           : Sample(1) ]

EncodeLoginResultAcceptedMessage(message) ==
    message.multicastGroupNumber
        \o message.resultCode

DecodeLoginResultAcceptedMessage(bytes) ==
    LET multicastGroupNumber == ReadBytes(bytes, 1) IN IF ~multicastGroupNumber.ok THEN Fail ELSE
    LET resultCode == ReadBytes(multicastGroupNumber.rest, 1) IN IF ~resultCode.ok THEN Fail ELSE
    Ok([ multicastGroupNumber |-> multicastGroupNumber.value,
         resultCode           |-> resultCode.value ], resultCode.rest)

ZeroLoginResultAcceptedMessage ==
    [ multicastGroupNumber |-> [i \in 1 .. 1 |-> 0],
      resultCode           |-> [i \in 1 .. 1 |-> 0] ]

(* Login Result Accepted Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginResultAcceptedMessage ==
    { ZeroLoginResultAcceptedMessage }
        \cup { [ZeroLoginResultAcceptedMessage EXCEPT !.multicastGroupNumber = one] : one \in Sample(1) }
        \cup { [ZeroLoginResultAcceptedMessage EXCEPT !.resultCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Login Result Rejected Message: 2 bytes                                  *)
(***************************************************************************)

LoginResultRejectedMessage ==
    [ multicastGroupNumber : Sample(1),
      resultCode           : Sample(1) ]

EncodeLoginResultRejectedMessage(message) ==
    message.multicastGroupNumber
        \o message.resultCode

DecodeLoginResultRejectedMessage(bytes) ==
    LET multicastGroupNumber == ReadBytes(bytes, 1) IN IF ~multicastGroupNumber.ok THEN Fail ELSE
    LET resultCode == ReadBytes(multicastGroupNumber.rest, 1) IN IF ~resultCode.ok THEN Fail ELSE
    Ok([ multicastGroupNumber |-> multicastGroupNumber.value,
         resultCode           |-> resultCode.value ], resultCode.rest)

ZeroLoginResultRejectedMessage ==
    [ multicastGroupNumber |-> [i \in 1 .. 1 |-> 0],
      resultCode           |-> [i \in 1 .. 1 |-> 0] ]

(* Login Result Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginResultRejectedMessage ==
    { ZeroLoginResultRejectedMessage }
        \cup { [ZeroLoginResultRejectedMessage EXCEPT !.multicastGroupNumber = one] : one \in Sample(1) }
        \cup { [ZeroLoginResultRejectedMessage EXCEPT !.resultCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Message Response Message                                                *)
(***************************************************************************)

MessageResponseMessage ==
    [ data : SampleBytes ]

EncodeMessageResponseMessage(message) ==
    message.data

DecodeMessageResponseMessage(bytes) ==
    LET data == Ok(bytes, << >>) IN IF ~data.ok THEN Fail ELSE
    Ok([ data |-> data.value ], data.rest)

ZeroMessageResponseMessage ==
    [ data |-> << >> ]

(* Message Response Message at zero, then each field in turn at the values it is checked at *)
CheckedMessageResponseMessage ==
    { ZeroMessageResponseMessage }
        \cup { [ZeroMessageResponseMessage EXCEPT !.data = one] : one \in SampleBytes }

(***************************************************************************)
(* End Of Message Message: 6 bytes                                         *)
(***************************************************************************)

EndOfMessageMessage ==
    [ multicastGroupNumber  : Sample(1),
      numberOfSystemReboots : Sample(1),
      nextSequenceNumber    : Sample(4) ]

EncodeEndOfMessageMessage(message) ==
    message.multicastGroupNumber
        \o message.numberOfSystemReboots
        \o message.nextSequenceNumber

DecodeEndOfMessageMessage(bytes) ==
    LET multicastGroupNumber == ReadBytes(bytes, 1) IN IF ~multicastGroupNumber.ok THEN Fail ELSE
    LET numberOfSystemReboots == ReadBytes(multicastGroupNumber.rest, 1) IN IF ~numberOfSystemReboots.ok THEN Fail ELSE
    LET nextSequenceNumber == ReadBytes(numberOfSystemReboots.rest, 4) IN IF ~nextSequenceNumber.ok THEN Fail ELSE
    Ok([ multicastGroupNumber  |-> multicastGroupNumber.value,
         numberOfSystemReboots |-> numberOfSystemReboots.value,
         nextSequenceNumber    |-> nextSequenceNumber.value ], nextSequenceNumber.rest)

ZeroEndOfMessageMessage ==
    [ multicastGroupNumber  |-> [i \in 1 .. 1 |-> 0],
      numberOfSystemReboots |-> [i \in 1 .. 1 |-> 0],
      nextSequenceNumber    |-> [i \in 1 .. 4 |-> 0] ]

(* End Of Message Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfMessageMessage ==
    { ZeroEndOfMessageMessage }
        \cup { [ZeroEndOfMessageMessage EXCEPT !.multicastGroupNumber = one] : one \in Sample(1) }
        \cup { [ZeroEndOfMessageMessage EXCEPT !.numberOfSystemReboots = one] : one \in Sample(1) }
        \cup { [ZeroEndOfMessageMessage EXCEPT !.nextSequenceNumber = one] : one \in Sample(4) }

(***************************************************************************)
(* Tcp Payload, selected by Packet Type                                    *)
(***************************************************************************)

LoginRequestRetransmissionMessageCode == 82  \* "R"
LoginRequestSnapshotMessageCode == 76  \* "L"
LoginResultAcceptedMessageCode == 65  \* "A"
LoginResultRejectedMessageCode == 74  \* "J"
MessageResponseMessageCode == 83  \* "S"
EndOfMessageMessageCode == 71  \* "G"

TcpPayload ==
    [ tag : {LoginRequestRetransmissionMessageCode}, body : LoginRequestRetransmissionMessage ]
        \cup [ tag : {LoginRequestSnapshotMessageCode}, body : LoginRequestSnapshotMessage ]
        \cup [ tag : {LoginResultAcceptedMessageCode}, body : LoginResultAcceptedMessage ]
        \cup [ tag : {LoginResultRejectedMessageCode}, body : LoginResultRejectedMessage ]
        \cup [ tag : {MessageResponseMessageCode}, body : MessageResponseMessage ]
        \cup [ tag : {EndOfMessageMessageCode}, body : EndOfMessageMessage ]

EncodeTcpPayload(message) ==
    CASE message.tag = LoginRequestRetransmissionMessageCode -> EncodeLoginRequestRetransmissionMessage(message.body)
      [] message.tag = LoginRequestSnapshotMessageCode -> EncodeLoginRequestSnapshotMessage(message.body)
      [] message.tag = LoginResultAcceptedMessageCode -> EncodeLoginResultAcceptedMessage(message.body)
      [] message.tag = LoginResultRejectedMessageCode -> EncodeLoginResultRejectedMessage(message.body)
      [] message.tag = MessageResponseMessageCode -> EncodeMessageResponseMessage(message.body)
      [] message.tag = EndOfMessageMessageCode -> EncodeEndOfMessageMessage(message.body)

DecodeTcpPayload(tag, bytes) ==
    LET read ==
            CASE tag = LoginRequestRetransmissionMessageCode -> DecodeLoginRequestRetransmissionMessage(bytes)
              [] tag = LoginRequestSnapshotMessageCode -> DecodeLoginRequestSnapshotMessage(bytes)
              [] tag = LoginResultAcceptedMessageCode -> DecodeLoginResultAcceptedMessage(bytes)
              [] tag = LoginResultRejectedMessageCode -> DecodeLoginResultRejectedMessage(bytes)
              [] tag = MessageResponseMessageCode -> DecodeMessageResponseMessage(bytes)
              [] tag = EndOfMessageMessageCode -> DecodeEndOfMessageMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroTcpPayload == [tag |-> LoginRequestRetransmissionMessageCode, body |-> ZeroLoginRequestRetransmissionMessage]

(* Each Tcp Payload in turn, at the values the message it names is checked at *)
CheckedTcpPayload ==
    { [tag |-> LoginRequestRetransmissionMessageCode, body |-> one] : one \in CheckedLoginRequestRetransmissionMessage }
        \cup { [tag |-> LoginRequestSnapshotMessageCode, body |-> one] : one \in CheckedLoginRequestSnapshotMessage }
        \cup { [tag |-> LoginResultAcceptedMessageCode, body |-> one] : one \in CheckedLoginResultAcceptedMessage }
        \cup { [tag |-> LoginResultRejectedMessageCode, body |-> one] : one \in CheckedLoginResultRejectedMessage }
        \cup { [tag |-> MessageResponseMessageCode, body |-> one] : one \in CheckedMessageResponseMessage }
        \cup { [tag |-> EndOfMessageMessageCode, body |-> one] : one \in CheckedEndOfMessageMessage }

(***************************************************************************)
(* Tcp Packet, framed by Packet Length                                     *)
(***************************************************************************)

TcpPacket ==
    [ tcpPayload : TcpPayload ]

EncodeTcpPacketBody(message) ==
    EncodeUIntBE(message.tcpPayload.tag, 1)
        \o EncodeTcpPayload(message.tcpPayload)

(* Packet Length counts the bytes it frames, so it is written from them *)
EncodeTcpPacket(message) ==
    LET body == EncodeTcpPacketBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeTcpPacketBody(bytes) ==
    LET packetType == ReadUIntBE(bytes, 1) IN IF ~packetType.ok THEN Fail ELSE
    LET tcpPayload == DecodeTcpPayload(packetType.value, packetType.rest) IN IF ~tcpPayload.ok THEN Fail ELSE
    Ok([ tcpPayload |-> tcpPayload.value ], tcpPayload.rest)

DecodeTcpPacket(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeTcpPacketBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroTcpPacket ==
    [ tcpPayload |-> ZeroTcpPayload ]

(* Tcp Packet at zero, then each field in turn at the values it is checked at *)
CheckedTcpPacket ==
    { ZeroTcpPacket }
        \cup { [ZeroTcpPacket EXCEPT !.tcpPayload = one] : one \in CheckedTcpPayload }

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

(* Every Login Request Retransmission Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRequestRetransmissionMessage ==
    \A message \in CheckedLoginRequestRetransmissionMessage :
        LET read == DecodeLoginRequestRetransmissionMessage(EncodeLoginRequestRetransmissionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Request Snapshot Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRequestSnapshotMessage ==
    \A message \in CheckedLoginRequestSnapshotMessage :
        LET read == DecodeLoginRequestSnapshotMessage(EncodeLoginRequestSnapshotMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Result Accepted Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginResultAcceptedMessage ==
    \A message \in CheckedLoginResultAcceptedMessage :
        LET read == DecodeLoginResultAcceptedMessage(EncodeLoginResultAcceptedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Result Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginResultRejectedMessage ==
    \A message \in CheckedLoginResultRejectedMessage :
        LET read == DecodeLoginResultRejectedMessage(EncodeLoginResultRejectedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageResponseMessage ==
    \A message \in CheckedMessageResponseMessage :
        LET read == DecodeMessageResponseMessage(EncodeMessageResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Message Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfMessageMessage ==
    \A message \in CheckedEndOfMessageMessage :
        LET read == DecodeEndOfMessageMessage(EncodeEndOfMessageMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tcp Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripTcpPacket ==
    \A message \in CheckedTcpPacket :
        LET read == DecodeTcpPacket(EncodeTcpPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Tcp Payload is selected by the Packet Type it is written under *)
SelectsTcpPayload ==
    \A message \in CheckedTcpPayload :
        LET sent == EncodeTcpPayload(message)
            read == DecodeTcpPayload(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* Packet Length is written from the bytes it frames *)
FramesTcpPacket ==
    \A message \in CheckedTcpPacket :
        LET bytes == EncodeTcpPacket(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
