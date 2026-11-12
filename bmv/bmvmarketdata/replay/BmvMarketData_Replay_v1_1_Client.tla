----------------- MODULE BmvMarketData_Replay_v1_1_Client ------------------
(***************************************************************************)
(* Bolsa Mexicana de Valores Bmv Market Data Replay v1.1                   *)
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
(* Login Message: 17 bytes                                                 *)
(***************************************************************************)

LoginMessage ==
    [ marketDataGroup : Sample(1),
      user            : Sample(6),
      password        : Sample(10) ]

EncodeLoginMessage(message) ==
    message.marketDataGroup
        \o message.user
        \o message.password

DecodeLoginMessage(bytes) ==
    LET marketDataGroup == ReadBytes(bytes, 1) IN IF ~marketDataGroup.ok THEN Fail ELSE
    LET user == ReadBytes(marketDataGroup.rest, 6) IN IF ~user.ok THEN Fail ELSE
    LET password == ReadBytes(user.rest, 10) IN IF ~password.ok THEN Fail ELSE
    Ok([ marketDataGroup |-> marketDataGroup.value,
         user            |-> user.value,
         password        |-> password.value ], password.rest)

ZeroLoginMessage ==
    [ marketDataGroup |-> [i \in 1 .. 1 |-> 0],
      user            |-> [i \in 1 .. 6 |-> 0],
      password        |-> [i \in 1 .. 10 |-> 0] ]

(* Login Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginMessage ==
    { ZeroLoginMessage }
        \cup { [ZeroLoginMessage EXCEPT !.marketDataGroup = one] : one \in Sample(1) }
        \cup { [ZeroLoginMessage EXCEPT !.user = one] : one \in Sample(6) }
        \cup { [ZeroLoginMessage EXCEPT !.password = one] : one \in Sample(10) }

(***************************************************************************)
(* Replay Request Message: 7 bytes                                         *)
(***************************************************************************)

ReplayRequestMessage ==
    [ marketDataGroup : Sample(1),
      firstMessage    : Sample(4),
      quantity        : Sample(2) ]

EncodeReplayRequestMessage(message) ==
    message.marketDataGroup
        \o message.firstMessage
        \o message.quantity

DecodeReplayRequestMessage(bytes) ==
    LET marketDataGroup == ReadBytes(bytes, 1) IN IF ~marketDataGroup.ok THEN Fail ELSE
    LET firstMessage == ReadBytes(marketDataGroup.rest, 4) IN IF ~firstMessage.ok THEN Fail ELSE
    LET quantity == ReadBytes(firstMessage.rest, 2) IN IF ~quantity.ok THEN Fail ELSE
    Ok([ marketDataGroup |-> marketDataGroup.value,
         firstMessage    |-> firstMessage.value,
         quantity        |-> quantity.value ], quantity.rest)

ZeroReplayRequestMessage ==
    [ marketDataGroup |-> [i \in 1 .. 1 |-> 0],
      firstMessage    |-> [i \in 1 .. 4 |-> 0],
      quantity        |-> [i \in 1 .. 2 |-> 0] ]

(* Replay Request Message at zero, then each field in turn at the values it is checked at *)
CheckedReplayRequestMessage ==
    { ZeroReplayRequestMessage }
        \cup { [ZeroReplayRequestMessage EXCEPT !.marketDataGroup = one] : one \in Sample(1) }
        \cup { [ZeroReplayRequestMessage EXCEPT !.firstMessage = one] : one \in Sample(4) }
        \cup { [ZeroReplayRequestMessage EXCEPT !.quantity = one] : one \in Sample(2) }

(***************************************************************************)
(* Snapshot Request Message: 6 bytes                                       *)
(***************************************************************************)

SnapshotRequestMessage ==
    [ marketDataGroup : Sample(1),
      instrumentId    : Sample(4),
      snapshotType    : Sample(1) ]

EncodeSnapshotRequestMessage(message) ==
    message.marketDataGroup
        \o message.instrumentId
        \o message.snapshotType

DecodeSnapshotRequestMessage(bytes) ==
    LET marketDataGroup == ReadBytes(bytes, 1) IN IF ~marketDataGroup.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(marketDataGroup.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET snapshotType == ReadBytes(instrumentId.rest, 1) IN IF ~snapshotType.ok THEN Fail ELSE
    Ok([ marketDataGroup |-> marketDataGroup.value,
         instrumentId    |-> instrumentId.value,
         snapshotType    |-> snapshotType.value ], snapshotType.rest)

ZeroSnapshotRequestMessage ==
    [ marketDataGroup |-> [i \in 1 .. 1 |-> 0],
      instrumentId    |-> [i \in 1 .. 4 |-> 0],
      snapshotType    |-> [i \in 1 .. 1 |-> 0] ]

(* Snapshot Request Message at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotRequestMessage ==
    { ZeroSnapshotRequestMessage }
        \cup { [ZeroSnapshotRequestMessage EXCEPT !.marketDataGroup = one] : one \in Sample(1) }
        \cup { [ZeroSnapshotRequestMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotRequestMessage EXCEPT !.snapshotType = one] : one \in Sample(1) }

(***************************************************************************)
(* Snapshot Indices Request Message: 11 bytes                              *)
(***************************************************************************)

SnapshotIndicesRequestMessage ==
    [ marketDataGroup : Sample(1),
      component       : Sample(2),
      recoveryHour    : Sample(8) ]

EncodeSnapshotIndicesRequestMessage(message) ==
    message.marketDataGroup
        \o message.component
        \o message.recoveryHour

DecodeSnapshotIndicesRequestMessage(bytes) ==
    LET marketDataGroup == ReadBytes(bytes, 1) IN IF ~marketDataGroup.ok THEN Fail ELSE
    LET component == ReadBytes(marketDataGroup.rest, 2) IN IF ~component.ok THEN Fail ELSE
    LET recoveryHour == ReadBytes(component.rest, 8) IN IF ~recoveryHour.ok THEN Fail ELSE
    Ok([ marketDataGroup |-> marketDataGroup.value,
         component       |-> component.value,
         recoveryHour    |-> recoveryHour.value ], recoveryHour.rest)

ZeroSnapshotIndicesRequestMessage ==
    [ marketDataGroup |-> [i \in 1 .. 1 |-> 0],
      component       |-> [i \in 1 .. 2 |-> 0],
      recoveryHour    |-> [i \in 1 .. 8 |-> 0] ]

(* Snapshot Indices Request Message at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotIndicesRequestMessage ==
    { ZeroSnapshotIndicesRequestMessage }
        \cup { [ZeroSnapshotIndicesRequestMessage EXCEPT !.marketDataGroup = one] : one \in Sample(1) }
        \cup { [ZeroSnapshotIndicesRequestMessage EXCEPT !.component = one] : one \in Sample(2) }
        \cup { [ZeroSnapshotIndicesRequestMessage EXCEPT !.recoveryHour = one] : one \in Sample(8) }

(***************************************************************************)
(* Snapshot Consolidated Feed Request Message: 7 bytes                     *)
(***************************************************************************)

SnapshotConsolidatedFeedRequestMessage ==
    [ marketDataGroup : Sample(1),
      instrumentId    : Sample(4),
      snapshotType    : Sample(1),
      origin          : Sample(1) ]

EncodeSnapshotConsolidatedFeedRequestMessage(message) ==
    message.marketDataGroup
        \o message.instrumentId
        \o message.snapshotType
        \o message.origin

DecodeSnapshotConsolidatedFeedRequestMessage(bytes) ==
    LET marketDataGroup == ReadBytes(bytes, 1) IN IF ~marketDataGroup.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(marketDataGroup.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET snapshotType == ReadBytes(instrumentId.rest, 1) IN IF ~snapshotType.ok THEN Fail ELSE
    LET origin == ReadBytes(snapshotType.rest, 1) IN IF ~origin.ok THEN Fail ELSE
    Ok([ marketDataGroup |-> marketDataGroup.value,
         instrumentId    |-> instrumentId.value,
         snapshotType    |-> snapshotType.value,
         origin          |-> origin.value ], origin.rest)

ZeroSnapshotConsolidatedFeedRequestMessage ==
    [ marketDataGroup |-> [i \in 1 .. 1 |-> 0],
      instrumentId    |-> [i \in 1 .. 4 |-> 0],
      snapshotType    |-> [i \in 1 .. 1 |-> 0],
      origin          |-> [i \in 1 .. 1 |-> 0] ]

(* Snapshot Consolidated Feed Request Message at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotConsolidatedFeedRequestMessage ==
    { ZeroSnapshotConsolidatedFeedRequestMessage }
        \cup { [ZeroSnapshotConsolidatedFeedRequestMessage EXCEPT !.marketDataGroup = one] : one \in Sample(1) }
        \cup { [ZeroSnapshotConsolidatedFeedRequestMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotConsolidatedFeedRequestMessage EXCEPT !.snapshotType = one] : one \in Sample(1) }
        \cup { [ZeroSnapshotConsolidatedFeedRequestMessage EXCEPT !.origin = one] : one \in Sample(1) }

(***************************************************************************)
(* Client Payload, selected by Client Message Type                         *)
(***************************************************************************)

LoginMessageCode == 33  \* 0x21
ReplayRequestMessageCode == 35  \* 0x23
SnapshotRequestMessageCode == 36  \* 0x24
SnapshotIndicesRequestMessageCode == 45  \* 0x2d
SnapshotConsolidatedFeedRequestMessageCode == 95  \* 0x5f

ClientPayload ==
    [ tag : {LoginMessageCode}, body : LoginMessage ]
        \cup [ tag : {ReplayRequestMessageCode}, body : ReplayRequestMessage ]
        \cup [ tag : {SnapshotRequestMessageCode}, body : SnapshotRequestMessage ]
        \cup [ tag : {SnapshotIndicesRequestMessageCode}, body : SnapshotIndicesRequestMessage ]
        \cup [ tag : {SnapshotConsolidatedFeedRequestMessageCode}, body : SnapshotConsolidatedFeedRequestMessage ]

EncodeClientPayload(message) ==
    CASE message.tag = LoginMessageCode -> EncodeLoginMessage(message.body)
      [] message.tag = ReplayRequestMessageCode -> EncodeReplayRequestMessage(message.body)
      [] message.tag = SnapshotRequestMessageCode -> EncodeSnapshotRequestMessage(message.body)
      [] message.tag = SnapshotIndicesRequestMessageCode -> EncodeSnapshotIndicesRequestMessage(message.body)
      [] message.tag = SnapshotConsolidatedFeedRequestMessageCode -> EncodeSnapshotConsolidatedFeedRequestMessage(message.body)

DecodeClientPayload(tag, bytes) ==
    LET read ==
            CASE tag = LoginMessageCode -> DecodeLoginMessage(bytes)
              [] tag = ReplayRequestMessageCode -> DecodeReplayRequestMessage(bytes)
              [] tag = SnapshotRequestMessageCode -> DecodeSnapshotRequestMessage(bytes)
              [] tag = SnapshotIndicesRequestMessageCode -> DecodeSnapshotIndicesRequestMessage(bytes)
              [] tag = SnapshotConsolidatedFeedRequestMessageCode -> DecodeSnapshotConsolidatedFeedRequestMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroClientPayload == [tag |-> LoginMessageCode, body |-> ZeroLoginMessage]

(* Each Client Payload in turn, at the values the message it names is checked at *)
CheckedClientPayload ==
    { [tag |-> LoginMessageCode, body |-> one] : one \in CheckedLoginMessage }
        \cup { [tag |-> ReplayRequestMessageCode, body |-> one] : one \in CheckedReplayRequestMessage }
        \cup { [tag |-> SnapshotRequestMessageCode, body |-> one] : one \in CheckedSnapshotRequestMessage }
        \cup { [tag |-> SnapshotIndicesRequestMessageCode, body |-> one] : one \in CheckedSnapshotIndicesRequestMessage }
        \cup { [tag |-> SnapshotConsolidatedFeedRequestMessageCode, body |-> one] : one \in CheckedSnapshotConsolidatedFeedRequestMessage }

(***************************************************************************)
(* Client Message, framed by Client Length                                 *)
(***************************************************************************)

ClientMessage ==
    [ clientPayload : ClientPayload ]

EncodeClientMessageBody(message) ==
    EncodeUIntBE(message.clientPayload.tag, 1)
        \o EncodeClientPayload(message.clientPayload)

(* Client Length counts the bytes it frames, so it is written from them *)
EncodeClientMessage(message) ==
    LET body == EncodeClientMessageBody(message)
    IN  EncodeUIntBE(Len(body) + 1, 1) \o body

DecodeClientMessageBody(bytes) ==
    LET clientMessageType == ReadUIntBE(bytes, 1) IN IF ~clientMessageType.ok THEN Fail ELSE
    LET clientPayload == DecodeClientPayload(clientMessageType.value, clientMessageType.rest) IN IF ~clientPayload.ok THEN Fail ELSE
    Ok([ clientPayload |-> clientPayload.value ], clientPayload.rest)

DecodeClientMessage(bytes) ==
    LET length == ReadUIntBE(bytes, 1) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 1 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeClientMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroClientMessage ==
    [ clientPayload |-> ZeroClientPayload ]

(* Client Message at zero, then each field in turn at the values it is checked at *)
CheckedClientMessage ==
    { ZeroClientMessage }
        \cup { [ZeroClientMessage EXCEPT !.clientPayload = one] : one \in CheckedClientPayload }

(* A run of Client Message, written one after another *)
RECURSIVE EncodeClientMessageList(_)
EncodeClientMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeClientMessage(Head(messages)) \o EncodeClientMessageList(Tail(messages))

(* As many Client Message as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadClientMessageAll(_)
ReadClientMessageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeClientMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadClientMessageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Client Message of each kind, for the lists that carry them *)
OneClientMessage ==
    { [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> LoginMessageCode, body |-> ZeroLoginMessage]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> ReplayRequestMessageCode, body |-> ZeroReplayRequestMessage]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> SnapshotRequestMessageCode, body |-> ZeroSnapshotRequestMessage]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> SnapshotIndicesRequestMessageCode, body |-> ZeroSnapshotIndicesRequestMessage]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> SnapshotConsolidatedFeedRequestMessageCode, body |-> ZeroSnapshotConsolidatedFeedRequestMessage]] }

(***************************************************************************)
(* Client Packet                                                           *)
(***************************************************************************)

ClientPacket ==
    [ clientMessage : SampleLists(OneClientMessage) ]

EncodeClientPacket(message) ==
    EncodeClientMessageList(message.clientMessage)

DecodeClientPacket(bytes) ==
    LET clientMessage == ReadClientMessageAll(bytes) IN IF ~clientMessage.ok THEN Fail ELSE
    Ok([ clientMessage |-> clientMessage.value ], clientMessage.rest)

ZeroClientPacket ==
    [ clientMessage |-> << >> ]

(* Client Packet at zero, then each field in turn at the values it is checked at *)
CheckedClientPacket ==
    { ZeroClientPacket }
        \cup { [ZeroClientPacket EXCEPT !.clientMessage = one] : one \in SampleLists(OneClientMessage) }

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

(* Every Snapshot Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotRequestMessage ==
    \A message \in CheckedSnapshotRequestMessage :
        LET read == DecodeSnapshotRequestMessage(EncodeSnapshotRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Indices Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotIndicesRequestMessage ==
    \A message \in CheckedSnapshotIndicesRequestMessage :
        LET read == DecodeSnapshotIndicesRequestMessage(EncodeSnapshotIndicesRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Consolidated Feed Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotConsolidatedFeedRequestMessage ==
    \A message \in CheckedSnapshotConsolidatedFeedRequestMessage :
        LET read == DecodeSnapshotConsolidatedFeedRequestMessage(EncodeSnapshotConsolidatedFeedRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client Message decodes back to what was encoded, and leaves nothing over *)
RoundTripClientMessage ==
    \A message \in CheckedClientMessage :
        LET read == DecodeClientMessage(EncodeClientMessage(message))
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

(* A Client Payload is selected by the Client Message Type it is written under *)
SelectsClientPayload ==
    \A message \in CheckedClientPayload :
        LET sent == EncodeClientPayload(message)
            read == DecodeClientPayload(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* Client Length is written from the bytes it frames *)
FramesClientMessage ==
    \A message \in CheckedClientMessage :
        LET bytes == EncodeClientMessage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 1)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
