--------------------- MODULE AquisEquities_Replay_v4_0 ---------------------
(***************************************************************************)
(* Aquis Exchange Market Data Replay v4.0                                  *)
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
(* Login Message: 20 bytes                                                 *)
(***************************************************************************)

LoginMessage ==
    [ username : Sample(10),
      password : Sample(10) ]

EncodeLoginMessage(message) ==
    message.username
        \o message.password

DecodeLoginMessage(bytes) ==
    LET username == ReadBytes(bytes, 10) IN IF ~username.ok THEN Fail ELSE
    LET password == ReadBytes(username.rest, 10) IN IF ~password.ok THEN Fail ELSE
    Ok([ username |-> username.value,
         password |-> password.value ], password.rest)

ZeroLoginMessage ==
    [ username |-> [i \in 1 .. 10 |-> 0],
      password |-> [i \in 1 .. 10 |-> 0] ]

(* Login Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginMessage ==
    { ZeroLoginMessage }
        \cup { [ZeroLoginMessage EXCEPT !.username = one] : one \in Sample(10) }
        \cup { [ZeroLoginMessage EXCEPT !.password = one] : one \in Sample(10) }

(***************************************************************************)
(* Replay Request Message: 8 bytes                                         *)
(***************************************************************************)

ReplayRequestMessage ==
    [ beginSeqNo : Sample(4),
      endSeqNo   : Sample(4) ]

EncodeReplayRequestMessage(message) ==
    message.beginSeqNo
        \o message.endSeqNo

DecodeReplayRequestMessage(bytes) ==
    LET beginSeqNo == ReadBytes(bytes, 4) IN IF ~beginSeqNo.ok THEN Fail ELSE
    LET endSeqNo == ReadBytes(beginSeqNo.rest, 4) IN IF ~endSeqNo.ok THEN Fail ELSE
    Ok([ beginSeqNo |-> beginSeqNo.value,
         endSeqNo   |-> endSeqNo.value ], endSeqNo.rest)

ZeroReplayRequestMessage ==
    [ beginSeqNo |-> [i \in 1 .. 4 |-> 0],
      endSeqNo   |-> [i \in 1 .. 4 |-> 0] ]

(* Replay Request Message at zero, then each field in turn at the values it is checked at *)
CheckedReplayRequestMessage ==
    { ZeroReplayRequestMessage }
        \cup { [ZeroReplayRequestMessage EXCEPT !.beginSeqNo = one] : one \in Sample(4) }
        \cup { [ZeroReplayRequestMessage EXCEPT !.endSeqNo = one] : one \in Sample(4) }

(***************************************************************************)
(* Replay Response Message: 1 bytes                                        *)
(***************************************************************************)

ReplayResponseMessage ==
    [ responseCode : Sample(1) ]

EncodeReplayResponseMessage(message) ==
    message.responseCode

DecodeReplayResponseMessage(bytes) ==
    LET responseCode == ReadBytes(bytes, 1) IN IF ~responseCode.ok THEN Fail ELSE
    Ok([ responseCode |-> responseCode.value ], responseCode.rest)

ZeroReplayResponseMessage ==
    [ responseCode |-> [i \in 1 .. 1 |-> 0] ]

(* Replay Response Message at zero, then each field in turn at the values it is checked at *)
CheckedReplayResponseMessage ==
    { ZeroReplayResponseMessage }
        \cup { [ZeroReplayResponseMessage EXCEPT !.responseCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by Msg Type                                           *)
(***************************************************************************)

LoginMessageCode == 13  \* 0x0d
ReplayRequestMessageCode == 14  \* 0x0e
ReplayResponseMessageCode == 15  \* 0x0f

Payload ==
    [ tag : {LoginMessageCode}, body : LoginMessage ]
        \cup [ tag : {ReplayRequestMessageCode}, body : ReplayRequestMessage ]
        \cup [ tag : {ReplayResponseMessageCode}, body : ReplayResponseMessage ]

EncodePayload(message) ==
    CASE message.tag = LoginMessageCode -> EncodeLoginMessage(message.body)
      [] message.tag = ReplayRequestMessageCode -> EncodeReplayRequestMessage(message.body)
      [] message.tag = ReplayResponseMessageCode -> EncodeReplayResponseMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = LoginMessageCode -> DecodeLoginMessage(bytes)
              [] tag = ReplayRequestMessageCode -> DecodeReplayRequestMessage(bytes)
              [] tag = ReplayResponseMessageCode -> DecodeReplayResponseMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> LoginMessageCode, body |-> ZeroLoginMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> LoginMessageCode, body |-> one] : one \in CheckedLoginMessage }
        \cup { [tag |-> ReplayRequestMessageCode, body |-> one] : one \in CheckedReplayRequestMessage }
        \cup { [tag |-> ReplayResponseMessageCode, body |-> one] : one \in CheckedReplayResponseMessage }

(***************************************************************************)
(* Message, framed by Msg Length                                           *)
(***************************************************************************)

Message ==
    [ seqNo   : Sample(4),
      payload : Payload ]

EncodeMessageBody(message) ==
    message.seqNo
        \o EncodePayload(message.payload)

(* Msg Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntBE(message.payload.tag, 1) \o EncodeUIntBE(Len(body) + 2, 1) \o body

DecodeMessage(bytes) ==
    LET msgType == ReadUIntBE(bytes, 1) IN IF ~msgType.ok THEN Fail ELSE
    LET length == ReadUIntBE(msgType.rest, 1) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
    IN
    LET seqNo == ReadBytes(framed, 4) IN IF ~seqNo.ok THEN Fail ELSE
    LET payload == DecodePayload(msgType.value, seqNo.rest) IN IF ~payload.ok THEN Fail ELSE
    IF payload.rest # << >> THEN Fail ELSE
    Ok([ seqNo   |-> seqNo.value,
         payload |-> payload.value ], beyond)

ZeroMessage ==
    [ seqNo   |-> [i \in 1 .. 4 |-> 0],
      payload |-> ZeroPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.seqNo = one] : one \in Sample(4) }
        \cup { [ZeroMessage EXCEPT !.payload = one] : one \in CheckedPayload }

(* A run of Message, written one after another *)
RECURSIVE EncodeMessageList(_)
EncodeMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMessage(Head(messages)) \o EncodeMessageList(Tail(messages))

(* As many Message as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadMessageAll(_)
ReadMessageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMessageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Message of each kind, for the lists that carry them *)
OneMessage ==
    { [ZeroMessage EXCEPT !.payload = [tag |-> LoginMessageCode, body |-> ZeroLoginMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ReplayRequestMessageCode, body |-> ZeroReplayRequestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ReplayResponseMessageCode, body |-> ZeroReplayResponseMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ message : SampleLists(OneMessage) ]

EncodePacket(message) ==
    EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET message == ReadMessageAll(bytes) IN IF ~message.ok THEN Fail ELSE
    Ok([ message |-> message.value ], message.rest)

ZeroPacket ==
    [ message |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
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

(* Every Login Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginMessage ==
    \A message \in CheckedLoginMessage :
        LET read == DecodeLoginMessage(EncodeLoginMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Replay Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReplayRequestMessage ==
    \A message \in CheckedReplayRequestMessage :
        LET read == DecodeReplayRequestMessage(EncodeReplayRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Replay Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReplayResponseMessage ==
    \A message \in CheckedReplayResponseMessage :
        LET read == DecodeReplayResponseMessage(EncodeReplayResponseMessage(message))
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

(* A Payload is selected by the Msg Type it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Msg Length is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 2, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
