--------------- MODULE MemxEquities_CommonHeader_v1_2_Client ---------------
(***************************************************************************)
(* The Members Exchange Common Header v1.2                                 *)
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
(* Note: Client Data is framed by Message Length: the choice is read from  *)
(* that many bytes and must take them all.                                 *)
(*                                                                         *)
(* Note: Client Sbe Message is as wide as what is left of Unsequenced      *)
(* Message: it is read as the bytes left of what its record was given,     *)
(* which the records above it keep those bytes back from.                  *)
(*                                                                         *)
(* Note: Unsequenced Message is as wide as Message Length says, which is   *)
(* the frame it is read from.                                              *)
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
(* Login Request Message: 2 bytes                                          *)
(***************************************************************************)

LoginRequestMessage ==
    [ tokenType : Sample(1),
      token     : Sample(1) ]

EncodeLoginRequestMessage(message) ==
    message.tokenType
        \o message.token

DecodeLoginRequestMessage(bytes) ==
    LET tokenType == ReadBytes(bytes, 1) IN IF ~tokenType.ok THEN Fail ELSE
    LET token == ReadBytes(tokenType.rest, 1) IN IF ~token.ok THEN Fail ELSE
    Ok([ tokenType |-> tokenType.value,
         token     |-> token.value ], token.rest)

ZeroLoginRequestMessage ==
    [ tokenType |-> [i \in 1 .. 1 |-> 0],
      token     |-> [i \in 1 .. 1 |-> 0] ]

(* Login Request Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginRequestMessage ==
    { ZeroLoginRequestMessage }
        \cup { [ZeroLoginRequestMessage EXCEPT !.tokenType = one] : one \in Sample(1) }
        \cup { [ZeroLoginRequestMessage EXCEPT !.token = one] : one \in Sample(1) }

(***************************************************************************)
(* Replay Request Message: 20 bytes                                        *)
(***************************************************************************)

ReplayRequestMessage ==
    [ sessionId          : Sample(8),
      nextSequenceNumber : Sample(8),
      count              : Sample(4) ]

EncodeReplayRequestMessage(message) ==
    message.sessionId
        \o message.nextSequenceNumber
        \o message.count

DecodeReplayRequestMessage(bytes) ==
    LET sessionId == ReadBytes(bytes, 8) IN IF ~sessionId.ok THEN Fail ELSE
    LET nextSequenceNumber == ReadBytes(sessionId.rest, 8) IN IF ~nextSequenceNumber.ok THEN Fail ELSE
    LET count == ReadBytes(nextSequenceNumber.rest, 4) IN IF ~count.ok THEN Fail ELSE
    Ok([ sessionId          |-> sessionId.value,
         nextSequenceNumber |-> nextSequenceNumber.value,
         count              |-> count.value ], count.rest)

ZeroReplayRequestMessage ==
    [ sessionId          |-> [i \in 1 .. 8 |-> 0],
      nextSequenceNumber |-> [i \in 1 .. 8 |-> 0],
      count              |-> [i \in 1 .. 4 |-> 0] ]

(* Replay Request Message at zero, then each field in turn at the values it is checked at *)
CheckedReplayRequestMessage ==
    { ZeroReplayRequestMessage }
        \cup { [ZeroReplayRequestMessage EXCEPT !.sessionId = one] : one \in Sample(8) }
        \cup { [ZeroReplayRequestMessage EXCEPT !.nextSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroReplayRequestMessage EXCEPT !.count = one] : one \in Sample(4) }

(***************************************************************************)
(* Replay All Request Message: 8 bytes                                     *)
(***************************************************************************)

ReplayAllRequestMessage ==
    [ sessionId : Sample(8) ]

EncodeReplayAllRequestMessage(message) ==
    message.sessionId

DecodeReplayAllRequestMessage(bytes) ==
    LET sessionId == ReadBytes(bytes, 8) IN IF ~sessionId.ok THEN Fail ELSE
    Ok([ sessionId |-> sessionId.value ], sessionId.rest)

ZeroReplayAllRequestMessage ==
    [ sessionId |-> [i \in 1 .. 8 |-> 0] ]

(* Replay All Request Message at zero, then each field in turn at the values it is checked at *)
CheckedReplayAllRequestMessage ==
    { ZeroReplayAllRequestMessage }
        \cup { [ZeroReplayAllRequestMessage EXCEPT !.sessionId = one] : one \in Sample(8) }

(***************************************************************************)
(* Stream Request Message: 16 bytes                                        *)
(***************************************************************************)

StreamRequestMessage ==
    [ sessionId          : Sample(8),
      nextSequenceNumber : Sample(8) ]

EncodeStreamRequestMessage(message) ==
    message.sessionId
        \o message.nextSequenceNumber

DecodeStreamRequestMessage(bytes) ==
    LET sessionId == ReadBytes(bytes, 8) IN IF ~sessionId.ok THEN Fail ELSE
    LET nextSequenceNumber == ReadBytes(sessionId.rest, 8) IN IF ~nextSequenceNumber.ok THEN Fail ELSE
    Ok([ sessionId          |-> sessionId.value,
         nextSequenceNumber |-> nextSequenceNumber.value ], nextSequenceNumber.rest)

ZeroStreamRequestMessage ==
    [ sessionId          |-> [i \in 1 .. 8 |-> 0],
      nextSequenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Stream Request Message at zero, then each field in turn at the values it is checked at *)
CheckedStreamRequestMessage ==
    { ZeroStreamRequestMessage }
        \cup { [ZeroStreamRequestMessage EXCEPT !.sessionId = one] : one \in Sample(8) }
        \cup { [ZeroStreamRequestMessage EXCEPT !.nextSequenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Unsequenced Message                                                     *)
(***************************************************************************)

UnsequencedMessage ==
    [ clientSbeMessage : SampleBytes ]

EncodeUnsequencedMessage(message) ==
    message.clientSbeMessage

DecodeUnsequencedMessage(bytes) ==
    LET clientSbeMessage == Ok(bytes, << >>) IN IF ~clientSbeMessage.ok THEN Fail ELSE
    Ok([ clientSbeMessage |-> clientSbeMessage.value ], clientSbeMessage.rest)

ZeroUnsequencedMessage ==
    [ clientSbeMessage |-> << >> ]

(* Unsequenced Message at zero, then each field in turn at the values it is checked at *)
CheckedUnsequencedMessage ==
    { ZeroUnsequencedMessage }
        \cup { [ZeroUnsequencedMessage EXCEPT !.clientSbeMessage = one] : one \in SampleBytes }

(***************************************************************************)
(* Client Data, selected by Message Type                                   *)
(***************************************************************************)

LoginRequestMessageCode == 100  \* 0x64
ReplayRequestMessageCode == 101  \* 0x65
ReplayAllRequestMessageCode == 102  \* 0x66
StreamRequestMessageCode == 103  \* 0x67
UnsequencedMessageCode == 104  \* 0x68

ClientData ==
    [ tag : {LoginRequestMessageCode}, body : LoginRequestMessage ]
        \cup [ tag : {ReplayRequestMessageCode}, body : ReplayRequestMessage ]
        \cup [ tag : {ReplayAllRequestMessageCode}, body : ReplayAllRequestMessage ]
        \cup [ tag : {StreamRequestMessageCode}, body : StreamRequestMessage ]
        \cup [ tag : {UnsequencedMessageCode}, body : UnsequencedMessage ]

EncodeClientData(message) ==
    CASE message.tag = LoginRequestMessageCode -> EncodeLoginRequestMessage(message.body)
      [] message.tag = ReplayRequestMessageCode -> EncodeReplayRequestMessage(message.body)
      [] message.tag = ReplayAllRequestMessageCode -> EncodeReplayAllRequestMessage(message.body)
      [] message.tag = StreamRequestMessageCode -> EncodeStreamRequestMessage(message.body)
      [] message.tag = UnsequencedMessageCode -> EncodeUnsequencedMessage(message.body)

DecodeClientData(tag, bytes) ==
    LET read ==
            CASE tag = LoginRequestMessageCode -> DecodeLoginRequestMessage(bytes)
              [] tag = ReplayRequestMessageCode -> DecodeReplayRequestMessage(bytes)
              [] tag = ReplayAllRequestMessageCode -> DecodeReplayAllRequestMessage(bytes)
              [] tag = StreamRequestMessageCode -> DecodeStreamRequestMessage(bytes)
              [] tag = UnsequencedMessageCode -> DecodeUnsequencedMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroClientData == [tag |-> LoginRequestMessageCode, body |-> ZeroLoginRequestMessage]

(* Each Client Data in turn, at the values the message it names is checked at *)
CheckedClientData ==
    { [tag |-> LoginRequestMessageCode, body |-> one] : one \in CheckedLoginRequestMessage }
        \cup { [tag |-> ReplayRequestMessageCode, body |-> one] : one \in CheckedReplayRequestMessage }
        \cup { [tag |-> ReplayAllRequestMessageCode, body |-> one] : one \in CheckedReplayAllRequestMessage }
        \cup { [tag |-> StreamRequestMessageCode, body |-> one] : one \in CheckedStreamRequestMessage }
        \cup { [tag |-> UnsequencedMessageCode, body |-> one] : one \in CheckedUnsequencedMessage }

(***************************************************************************)
(* Client Packet                                                           *)
(***************************************************************************)

ClientPacket ==
    [ clientData : ClientData ]

EncodeClientPacket(message) ==
    EncodeUIntBE(message.clientData.tag, 1)
        \o EncodeUIntBE(Len(EncodeClientData(message.clientData)), 2)
        \o EncodeClientData(message.clientData)

DecodeClientPacket(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET messageLength == ReadUIntBE(messageType.rest, 2) IN IF ~messageLength.ok THEN Fail ELSE
    LET clientDataSize == messageLength.value IN
    IF clientDataSize < 0 \/ Len(messageLength.rest) < clientDataSize THEN Fail ELSE
    LET clientDataFramed == SubSeq(messageLength.rest, 1, clientDataSize)
        clientDataBeyond == SubSeq(messageLength.rest, clientDataSize + 1, Len(messageLength.rest))
        clientData == DecodeClientData(messageType.value, clientDataFramed)
    IN  IF ~clientData.ok \/ clientData.rest # << >> THEN Fail ELSE
    Ok([ clientData |-> clientData.value ], clientDataBeyond)

ZeroClientPacket ==
    [ clientData |-> ZeroClientData ]

(* Client Packet at zero, then each field in turn at the values it is checked at *)
CheckedClientPacket ==
    { ZeroClientPacket }
        \cup { [ZeroClientPacket EXCEPT !.clientData = one] : one \in CheckedClientData }

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

(* Every Login Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRequestMessage ==
    \A message \in CheckedLoginRequestMessage :
        LET read == DecodeLoginRequestMessage(EncodeLoginRequestMessage(message))
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

(* Every Replay All Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReplayAllRequestMessage ==
    \A message \in CheckedReplayAllRequestMessage :
        LET read == DecodeReplayAllRequestMessage(EncodeReplayAllRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stream Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStreamRequestMessage ==
    \A message \in CheckedStreamRequestMessage :
        LET read == DecodeStreamRequestMessage(EncodeStreamRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Unsequenced Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUnsequencedMessage ==
    \A message \in CheckedUnsequencedMessage :
        LET read == DecodeUnsequencedMessage(EncodeUnsequencedMessage(message))
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

(* A Client Data is selected by the Message Type it is written under *)
SelectsClientData ==
    \A message \in CheckedClientData :
        LET sent == EncodeClientData(message)
            read == DecodeClientData(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
