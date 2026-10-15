----------------------- MODULE Mx_SolaMulticast_v2_1 -----------------------
(***************************************************************************)
(* TMX Group Sola Multicast v2.1                                           *)
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
(* Note: Packet fills its datagram with as many messages as the bytes      *)
(* hold, so it is read as a run of them.                                   *)
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
(* Login Message: 40 bytes                                                 *)
(***************************************************************************)

LoginMessage ==
    [ user      : Sample(16),
      pwd       : Sample(16),
      timestamp : Sample(6),
      protocol  : Sample(2) ]

EncodeLoginMessage(message) ==
    message.user
        \o message.pwd
        \o message.timestamp
        \o message.protocol

DecodeLoginMessage(bytes) ==
    LET user == ReadBytes(bytes, 16) IN IF ~user.ok THEN Fail ELSE
    LET pwd == ReadBytes(user.rest, 16) IN IF ~pwd.ok THEN Fail ELSE
    LET timestamp == ReadBytes(pwd.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET protocol == ReadBytes(timestamp.rest, 2) IN IF ~protocol.ok THEN Fail ELSE
    Ok([ user      |-> user.value,
         pwd       |-> pwd.value,
         timestamp |-> timestamp.value,
         protocol  |-> protocol.value ], protocol.rest)

ZeroLoginMessage ==
    [ user      |-> [i \in 1 .. 16 |-> 0],
      pwd       |-> [i \in 1 .. 16 |-> 0],
      timestamp |-> [i \in 1 .. 6 |-> 0],
      protocol  |-> [i \in 1 .. 2 |-> 0] ]

(* Login Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginMessage ==
    { ZeroLoginMessage }
        \cup { [ZeroLoginMessage EXCEPT !.user = one] : one \in Sample(16) }
        \cup { [ZeroLoginMessage EXCEPT !.pwd = one] : one \in Sample(16) }
        \cup { [ZeroLoginMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroLoginMessage EXCEPT !.protocol = one] : one \in Sample(2) }

(***************************************************************************)
(* Retransmission Request Message: 20 bytes                                *)
(***************************************************************************)

RetransmissionRequestMessage ==
    [ line  : Sample(2),
      start : Sample(9),
      end   : Sample(9) ]

EncodeRetransmissionRequestMessage(message) ==
    message.line
        \o message.start
        \o message.end

DecodeRetransmissionRequestMessage(bytes) ==
    LET line == ReadBytes(bytes, 2) IN IF ~line.ok THEN Fail ELSE
    LET start == ReadBytes(line.rest, 9) IN IF ~start.ok THEN Fail ELSE
    LET end == ReadBytes(start.rest, 9) IN IF ~end.ok THEN Fail ELSE
    Ok([ line  |-> line.value,
         start |-> start.value,
         end   |-> end.value ], end.rest)

ZeroRetransmissionRequestMessage ==
    [ line  |-> [i \in 1 .. 2 |-> 0],
      start |-> [i \in 1 .. 9 |-> 0],
      end   |-> [i \in 1 .. 9 |-> 0] ]

(* Retransmission Request Message at zero, then each field in turn at the values it is checked at *)
CheckedRetransmissionRequestMessage ==
    { ZeroRetransmissionRequestMessage }
        \cup { [ZeroRetransmissionRequestMessage EXCEPT !.line = one] : one \in Sample(2) }
        \cup { [ZeroRetransmissionRequestMessage EXCEPT !.start = one] : one \in Sample(9) }
        \cup { [ZeroRetransmissionRequestMessage EXCEPT !.end = one] : one \in Sample(9) }

(***************************************************************************)
(* Error Message: 84 bytes                                                 *)
(***************************************************************************)

ErrorMessage ==
    [ errorCode : Sample(4),
      errorMsg  : Sample(80) ]

EncodeErrorMessage(message) ==
    message.errorCode
        \o message.errorMsg

DecodeErrorMessage(bytes) ==
    LET errorCode == ReadBytes(bytes, 4) IN IF ~errorCode.ok THEN Fail ELSE
    LET errorMsg == ReadBytes(errorCode.rest, 80) IN IF ~errorMsg.ok THEN Fail ELSE
    Ok([ errorCode |-> errorCode.value,
         errorMsg  |-> errorMsg.value ], errorMsg.rest)

ZeroErrorMessage ==
    [ errorCode |-> [i \in 1 .. 4 |-> 0],
      errorMsg  |-> [i \in 1 .. 80 |-> 0] ]

(* Error Message at zero, then each field in turn at the values it is checked at *)
CheckedErrorMessage ==
    { ZeroErrorMessage }
        \cup { [ZeroErrorMessage EXCEPT !.errorCode = one] : one \in Sample(4) }
        \cup { [ZeroErrorMessage EXCEPT !.errorMsg = one] : one \in Sample(80) }

(***************************************************************************)
(* Message Body, selected by Message Type                                  *)
(***************************************************************************)

LoginMessageCode == 19529  \* "LI"
RetransmissionRequestMessageCode == 21076  \* "RT"
ErrorMessageCode == 17746  \* "ER"

MessageBody ==
    [ tag : {LoginMessageCode}, body : LoginMessage ]
        \cup [ tag : {RetransmissionRequestMessageCode}, body : RetransmissionRequestMessage ]
        \cup [ tag : {ErrorMessageCode}, body : ErrorMessage ]

EncodeMessageBody(message) ==
    CASE message.tag = LoginMessageCode -> EncodeLoginMessage(message.body)
      [] message.tag = RetransmissionRequestMessageCode -> EncodeRetransmissionRequestMessage(message.body)
      [] message.tag = ErrorMessageCode -> EncodeErrorMessage(message.body)

DecodeMessageBody(tag, bytes) ==
    LET read ==
            CASE tag = LoginMessageCode -> DecodeLoginMessage(bytes)
              [] tag = RetransmissionRequestMessageCode -> DecodeRetransmissionRequestMessage(bytes)
              [] tag = ErrorMessageCode -> DecodeErrorMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroMessageBody == [tag |-> LoginMessageCode, body |-> ZeroLoginMessage]

(* Each Message Body in turn, at the values the message it names is checked at *)
CheckedMessageBody ==
    { [tag |-> LoginMessageCode, body |-> one] : one \in CheckedLoginMessage }
        \cup { [tag |-> RetransmissionRequestMessageCode, body |-> one] : one \in CheckedRetransmissionRequestMessage }
        \cup { [tag |-> ErrorMessageCode, body |-> one] : one \in CheckedErrorMessage }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ hsvfStx        : Sample(1),
      sequenceNumber : Sample(9),
      messageBody    : MessageBody,
      hsvfEtx        : Sample(1) ]

EncodePacket(message) ==
    message.hsvfStx
        \o message.sequenceNumber
        \o EncodeUIntBE(message.messageBody.tag, 2)
        \o EncodeMessageBody(message.messageBody)
        \o message.hsvfEtx

DecodePacket(bytes) ==
    LET hsvfStx == ReadBytes(bytes, 1) IN IF ~hsvfStx.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(hsvfStx.rest, 9) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET messageType == ReadUIntBE(sequenceNumber.rest, 2) IN IF ~messageType.ok THEN Fail ELSE
    LET messageBody == DecodeMessageBody(messageType.value, messageType.rest) IN IF ~messageBody.ok THEN Fail ELSE
    LET hsvfEtx == ReadBytes(messageBody.rest, 1) IN IF ~hsvfEtx.ok THEN Fail ELSE
    Ok([ hsvfStx        |-> hsvfStx.value,
         sequenceNumber |-> sequenceNumber.value,
         messageBody    |-> messageBody.value,
         hsvfEtx        |-> hsvfEtx.value ], hsvfEtx.rest)

ZeroPacket ==
    [ hsvfStx        |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber |-> [i \in 1 .. 9 |-> 0],
      messageBody    |-> ZeroMessageBody,
      hsvfEtx        |-> [i \in 1 .. 1 |-> 0] ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.hsvfStx = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.sequenceNumber = one] : one \in Sample(9) }
        \cup { [ZeroPacket EXCEPT !.messageBody = one] : one \in CheckedMessageBody }
        \cup { [ZeroPacket EXCEPT !.hsvfEtx = one] : one \in Sample(1) }

(* A run of Packet, written one after another *)
RECURSIVE EncodePacketList(_)
EncodePacketList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodePacket(Head(messages)) \o EncodePacketList(Tail(messages))

(* As many Packet as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadPacketAll(_)
ReadPacketAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodePacket(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadPacketAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Packet of each kind, for the lists that carry them *)
OnePacket ==
    { [ZeroPacket EXCEPT !.messageBody = [tag |-> LoginMessageCode, body |-> ZeroLoginMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> RetransmissionRequestMessageCode, body |-> ZeroRetransmissionRequestMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> ErrorMessageCode, body |-> ZeroErrorMessage]] }

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

(* Every Login Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginMessage ==
    \A message \in CheckedLoginMessage :
        LET read == DecodeLoginMessage(EncodeLoginMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Retransmission Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRetransmissionRequestMessage ==
    \A message \in CheckedRetransmissionRequestMessage :
        LET read == DecodeRetransmissionRequestMessage(EncodeRetransmissionRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Error Message decodes back to what was encoded, and leaves nothing over *)
RoundTripErrorMessage ==
    \A message \in CheckedErrorMessage :
        LET read == DecodeErrorMessage(EncodeErrorMessage(message))
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

(* A Message Body is selected by the Message Type it is written under *)
SelectsMessageBody ==
    \A message \in CheckedMessageBody :
        LET read == DecodeMessageBody(message.tag, EncodeMessageBody(message))
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
