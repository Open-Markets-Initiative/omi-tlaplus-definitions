-------------- MODULE Mx_SolaTcpRetransmission_v1_13_3_Client --------------
(***************************************************************************)
(* TMX Group Sola Tcp Retransmission v1.13.3                               *)
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
(* Note: Client Message Body is the rest of Client Sola Frame bar what     *)
(* follows it, so it is handed exactly those bytes and must take them all. *)
(*                                                                         *)
(* Note: Client Sola Frame is closed by Sola Message End, so its body is   *)
(* read as the bytes ahead of the first 3 and written back with that byte  *)
(* after it, which is what lets a run of them be told apart.               *)
(*                                                                         *)
(* Note: Client Sola Frame is not framed: its size rule does not read a    *)
(* length field.                                                           *)
(*                                                                         *)
(* Note: Client Sola Frame is of no one width: each is read by its own     *)
(* fields, and since every reading of it takes at least 14 bytes off the   *)
(* reader the run ends where the data does.                                *)
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
(* Login Message: 40 bytes                                                 *)
(***************************************************************************)

LoginMessage ==
    [ user           : Sample(16),
      pwd            : Sample(16),
      loginTimestamp : Sample(6),
      protocol       : Sample(2) ]

EncodeLoginMessage(message) ==
    message.user
        \o message.pwd
        \o message.loginTimestamp
        \o message.protocol

DecodeLoginMessage(bytes) ==
    LET user == ReadBytes(bytes, 16) IN IF ~user.ok THEN Fail ELSE
    LET pwd == ReadBytes(user.rest, 16) IN IF ~pwd.ok THEN Fail ELSE
    LET loginTimestamp == ReadBytes(pwd.rest, 6) IN IF ~loginTimestamp.ok THEN Fail ELSE
    LET protocol == ReadBytes(loginTimestamp.rest, 2) IN IF ~protocol.ok THEN Fail ELSE
    Ok([ user           |-> user.value,
         pwd            |-> pwd.value,
         loginTimestamp |-> loginTimestamp.value,
         protocol       |-> protocol.value ], protocol.rest)

ZeroLoginMessage ==
    [ user           |-> [i \in 1 .. 16 |-> 0],
      pwd            |-> [i \in 1 .. 16 |-> 0],
      loginTimestamp |-> [i \in 1 .. 6 |-> 0],
      protocol       |-> [i \in 1 .. 2 |-> 0] ]

(* Login Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginMessage ==
    { ZeroLoginMessage }
        \cup { [ZeroLoginMessage EXCEPT !.user = one] : one \in Sample(16) }
        \cup { [ZeroLoginMessage EXCEPT !.pwd = one] : one \in Sample(16) }
        \cup { [ZeroLoginMessage EXCEPT !.loginTimestamp = one] : one \in Sample(6) }
        \cup { [ZeroLoginMessage EXCEPT !.protocol = one] : one \in Sample(2) }

(***************************************************************************)
(* Retransmission Request Message: 22 bytes                                *)
(***************************************************************************)

RetransmissionRequestMessage ==
    [ line  : Sample(2),
      start : Sample(10),
      end   : Sample(10) ]

EncodeRetransmissionRequestMessage(message) ==
    message.line
        \o message.start
        \o message.end

DecodeRetransmissionRequestMessage(bytes) ==
    LET line == ReadBytes(bytes, 2) IN IF ~line.ok THEN Fail ELSE
    LET start == ReadBytes(line.rest, 10) IN IF ~start.ok THEN Fail ELSE
    LET end == ReadBytes(start.rest, 10) IN IF ~end.ok THEN Fail ELSE
    Ok([ line  |-> line.value,
         start |-> start.value,
         end   |-> end.value ], end.rest)

ZeroRetransmissionRequestMessage ==
    [ line  |-> [i \in 1 .. 2 |-> 0],
      start |-> [i \in 1 .. 10 |-> 0],
      end   |-> [i \in 1 .. 10 |-> 0] ]

(* Retransmission Request Message at zero, then each field in turn at the values it is checked at *)
CheckedRetransmissionRequestMessage ==
    { ZeroRetransmissionRequestMessage }
        \cup { [ZeroRetransmissionRequestMessage EXCEPT !.line = one] : one \in Sample(2) }
        \cup { [ZeroRetransmissionRequestMessage EXCEPT !.start = one] : one \in Sample(10) }
        \cup { [ZeroRetransmissionRequestMessage EXCEPT !.end = one] : one \in Sample(10) }

(***************************************************************************)
(* Client Message Body, selected by Client Message Type                    *)
(***************************************************************************)

LoginMessageCode == 19529  \* "LI"
LogoutMessageCode == 19535  \* "LO"
RetransmissionRequestMessageCode == 21076  \* "RT"

ClientMessageBody ==
    [ tag : {LoginMessageCode}, body : LoginMessage ]
        \cup [ tag : {LogoutMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {RetransmissionRequestMessageCode}, body : RetransmissionRequestMessage ]

EncodeClientMessageBody(message) ==
    CASE message.tag = LoginMessageCode -> EncodeLoginMessage(message.body)
      [] message.tag = LogoutMessageCode -> << >>
      [] message.tag = RetransmissionRequestMessageCode -> EncodeRetransmissionRequestMessage(message.body)

DecodeClientMessageBody(tag, bytes) ==
    LET read ==
            CASE tag = LoginMessageCode -> DecodeLoginMessage(bytes)
              [] tag = LogoutMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = RetransmissionRequestMessageCode -> DecodeRetransmissionRequestMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroClientMessageBody == [tag |-> LoginMessageCode, body |-> ZeroLoginMessage]

(* Each Client Message Body in turn, at the values the message it names is checked at *)
CheckedClientMessageBody ==
    { [tag |-> LoginMessageCode, body |-> one] : one \in CheckedLoginMessage }
        \cup { [tag |-> LogoutMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> RetransmissionRequestMessageCode, body |-> one] : one \in CheckedRetransmissionRequestMessage }

(***************************************************************************)
(* Client Sola Frame, closed by Sola Message End                           *)
(***************************************************************************)

ClientSolaFrame ==
    [ solaMessageStart  : Sample(1),
      sequenceNumber    : Sample(10),
      clientMessageBody : ClientMessageBody ]

EncodeClientSolaFrameBody(message) ==
    message.solaMessageStart
        \o message.sequenceNumber
        \o EncodeUIntBE(message.clientMessageBody.tag, 2)
        \o EncodeClientMessageBody(message.clientMessageBody)

(* Sola Message End closes the record, so it is written after the body it closes *)
EncodeClientSolaFrame(message) == EncodeClientSolaFrameBody(message) \o <<3>>

DecodeClientSolaFrameBody(bytes) ==
    LET solaMessageStart == ReadBytes(bytes, 1) IN IF ~solaMessageStart.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(solaMessageStart.rest, 10) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET clientMessageType == ReadUIntBE(sequenceNumber.rest, 2) IN IF ~clientMessageType.ok THEN Fail ELSE
    LET clientMessageBody == DecodeClientMessageBody(clientMessageType.value, clientMessageType.rest) IN IF ~clientMessageBody.ok THEN Fail ELSE
    Ok([ solaMessageStart  |-> solaMessageStart.value,
         sequenceNumber    |-> sequenceNumber.value,
         clientMessageBody |-> clientMessageBody.value ], clientMessageBody.rest)

(* Sola Message End closes the record, so the body is the bytes ahead of the first one *)
DecodeClientSolaFrame(bytes) ==
    LET closed == ReadClosed(bytes, 3) IN IF ~closed.ok THEN Fail ELSE
    LET body == DecodeClientSolaFrameBody(closed.value)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, closed.rest)

ZeroClientSolaFrame ==
    [ solaMessageStart  |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber    |-> [i \in 1 .. 10 |-> 0],
      clientMessageBody |-> ZeroClientMessageBody ]

(* Client Sola Frame at zero, then each field in turn at the values it is checked at *)
CheckedClientSolaFrame ==
    { ZeroClientSolaFrame }
        \cup { [ZeroClientSolaFrame EXCEPT !.solaMessageStart = one] : one \in Sample(1) }
        \cup { [ZeroClientSolaFrame EXCEPT !.sequenceNumber = one] : one \in Sample(10) }
        \cup { [ZeroClientSolaFrame EXCEPT !.clientMessageBody = one] : one \in CheckedClientMessageBody }

(* A run of Client Sola Frame, written one after another *)
RECURSIVE EncodeClientSolaFrameList(_)
EncodeClientSolaFrameList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeClientSolaFrame(Head(messages)) \o EncodeClientSolaFrameList(Tail(messages))

(* As many Client Sola Frame as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadClientSolaFrameAll(_)
ReadClientSolaFrameAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeClientSolaFrame(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadClientSolaFrameAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Client Sola Frame of each kind, for the lists that carry them *)
OneClientSolaFrame ==
    { [ZeroClientSolaFrame EXCEPT !.clientMessageBody = [tag |-> LoginMessageCode, body |-> ZeroLoginMessage]],
      [ZeroClientSolaFrame EXCEPT !.clientMessageBody = [tag |-> LogoutMessageCode, body |-> [empty |-> 0]]],
      [ZeroClientSolaFrame EXCEPT !.clientMessageBody = [tag |-> RetransmissionRequestMessageCode, body |-> ZeroRetransmissionRequestMessage]] }

(***************************************************************************)
(* Client Packet                                                           *)
(***************************************************************************)

ClientPacket ==
    [ clientSolaFrame : SampleLists(OneClientSolaFrame) ]

EncodeClientPacket(message) ==
    EncodeClientSolaFrameList(message.clientSolaFrame)

DecodeClientPacket(bytes) ==
    LET clientSolaFrame == ReadClientSolaFrameAll(bytes) IN IF ~clientSolaFrame.ok THEN Fail ELSE
    Ok([ clientSolaFrame |-> clientSolaFrame.value ], clientSolaFrame.rest)

ZeroClientPacket ==
    [ clientSolaFrame |-> << >> ]

(* Client Packet at zero, then each field in turn at the values it is checked at *)
CheckedClientPacket ==
    { ZeroClientPacket }
        \cup { [ZeroClientPacket EXCEPT !.clientSolaFrame = one] : one \in SampleLists(OneClientSolaFrame) }

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

(* Every Client Sola Frame decodes back to what was encoded, and leaves nothing over *)
RoundTripClientSolaFrame ==
    \A message \in CheckedClientSolaFrame :
        LET read == DecodeClientSolaFrame(EncodeClientSolaFrame(message))
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

(* A Client Message Body is selected by the Client Message Type it is written under *)
SelectsClientMessageBody ==
    \A message \in CheckedClientMessageBody :
        LET sent == EncodeClientMessageBody(message)
            read == DecodeClientMessageBody(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* No Client Sola Frame writes the Sola Message End that closes it inside its own body, so *)
(* the first one found is the end of the record. Checked over the messages below, which *)
(* is weaker than a proof that none could. *)
ClosesClientSolaFrame ==
    \A message \in CheckedClientSolaFrame :
        LET body == EncodeClientSolaFrameBody(message)
        IN  \A i \in 1 .. Len(body) : body[i] # 3

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
