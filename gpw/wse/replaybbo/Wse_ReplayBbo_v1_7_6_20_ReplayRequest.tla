--------------- MODULE Wse_ReplayBbo_v1_7_6_20_ReplayRequest ---------------
(***************************************************************************)
(* Giełda Papierów Wartościowych w Warszawie Warsaw Stock Exchange BBO     *)
(* Replay v1.7.6                                                           *)
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
(* Note: Replay Request Message is of no one width: each is read by its    *)
(* own fields, and since every reading of it takes at least 13 bytes off   *)
(* the reader the run ends where the data does.                            *)
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
(* Replay Request: 9 bytes                                                 *)
(***************************************************************************)

ReplayRequest ==
    [ seqNum    : Sample(4),
      endSeqNum : Sample(4),
      streamId  : Sample(1) ]

EncodeReplayRequest(message) ==
    message.seqNum
        \o message.endSeqNum
        \o message.streamId

DecodeReplayRequest(bytes) ==
    LET seqNum == ReadBytes(bytes, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET endSeqNum == ReadBytes(seqNum.rest, 4) IN IF ~endSeqNum.ok THEN Fail ELSE
    LET streamId == ReadBytes(endSeqNum.rest, 1) IN IF ~streamId.ok THEN Fail ELSE
    Ok([ seqNum    |-> seqNum.value,
         endSeqNum |-> endSeqNum.value,
         streamId  |-> streamId.value ], streamId.rest)

ZeroReplayRequest ==
    [ seqNum    |-> [i \in 1 .. 4 |-> 0],
      endSeqNum |-> [i \in 1 .. 4 |-> 0],
      streamId  |-> [i \in 1 .. 1 |-> 0] ]

(* Replay Request at zero, then each field in turn at the values it is checked at *)
CheckedReplayRequest ==
    { ZeroReplayRequest }
        \cup { [ZeroReplayRequest EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroReplayRequest EXCEPT !.endSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroReplayRequest EXCEPT !.streamId = one] : one \in Sample(1) }

(***************************************************************************)
(* Replay Request Payload, selected by Replay Message Type                 *)
(***************************************************************************)

ReplayRequestCode == 1  \* 0x01

ReplayRequestPayload ==
    [ tag : {ReplayRequestCode}, body : ReplayRequest ]

EncodeReplayRequestPayload(message) ==
    CASE message.tag = ReplayRequestCode -> EncodeReplayRequest(message.body)

DecodeReplayRequestPayload(tag, bytes) ==
    LET read ==
            CASE tag = ReplayRequestCode -> DecodeReplayRequest(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroReplayRequestPayload == [tag |-> ReplayRequestCode, body |-> ZeroReplayRequest]

(* Each Replay Request Payload in turn, at the values the message it names is checked at *)
CheckedReplayRequestPayload ==
    { [tag |-> ReplayRequestCode, body |-> one] : one \in CheckedReplayRequest }

(***************************************************************************)
(* Replay Request Message                                                  *)
(***************************************************************************)

ReplayRequestMessage ==
    [ replayMessageLength  : 0 .. 255,
      replayRequestPayload : ReplayRequestPayload ]

EncodeReplayRequestMessage(message) ==
    EncodeUIntLE(message.replayMessageLength, 2)
        \o EncodeUIntLE(message.replayRequestPayload.tag, 2)
        \o EncodeReplayRequestPayload(message.replayRequestPayload)

DecodeReplayRequestMessage(bytes) ==
    LET replayMessageLength == ReadUIntLE(bytes, 2) IN IF ~replayMessageLength.ok THEN Fail ELSE
    LET replayMessageType == ReadUIntLE(replayMessageLength.rest, 2) IN IF ~replayMessageType.ok THEN Fail ELSE
    LET replayRequestPayload == DecodeReplayRequestPayload(replayMessageType.value, replayMessageType.rest) IN IF ~replayRequestPayload.ok THEN Fail ELSE
    Ok([ replayMessageLength  |-> replayMessageLength.value,
         replayRequestPayload |-> replayRequestPayload.value ], replayRequestPayload.rest)

ZeroReplayRequestMessage ==
    [ replayMessageLength  |-> 0,
      replayRequestPayload |-> ZeroReplayRequestPayload ]

(* Replay Request Message at zero, then each field in turn at the values it is checked at *)
CheckedReplayRequestMessage ==
    { ZeroReplayRequestMessage }
        \cup { [ZeroReplayRequestMessage EXCEPT !.replayMessageLength = one] : one \in {0, 1, 255} }
        \cup { [ZeroReplayRequestMessage EXCEPT !.replayRequestPayload = one] : one \in CheckedReplayRequestPayload }

(* A run of Replay Request Message, written one after another *)
RECURSIVE EncodeReplayRequestMessageList(_)
EncodeReplayRequestMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeReplayRequestMessage(Head(messages)) \o EncodeReplayRequestMessageList(Tail(messages))

(* As many Replay Request Message as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadReplayRequestMessageAll(_)
ReadReplayRequestMessageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeReplayRequestMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadReplayRequestMessageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Replay Request Message of each kind, for the lists that carry them *)
OneReplayRequestMessage ==
    { [ZeroReplayRequestMessage EXCEPT !.replayRequestPayload = [tag |-> ReplayRequestCode, body |-> ZeroReplayRequest]] }

(***************************************************************************)
(* Replay Request Packet                                                   *)
(***************************************************************************)

ReplayRequestPacket ==
    [ replayRequestMessage : SampleLists(OneReplayRequestMessage) ]

EncodeReplayRequestPacket(message) ==
    EncodeReplayRequestMessageList(message.replayRequestMessage)

DecodeReplayRequestPacket(bytes) ==
    LET replayRequestMessage == ReadReplayRequestMessageAll(bytes) IN IF ~replayRequestMessage.ok THEN Fail ELSE
    Ok([ replayRequestMessage |-> replayRequestMessage.value ], replayRequestMessage.rest)

ZeroReplayRequestPacket ==
    [ replayRequestMessage |-> << >> ]

(* Replay Request Packet at zero, then each field in turn at the values it is checked at *)
CheckedReplayRequestPacket ==
    { ZeroReplayRequestPacket }
        \cup { [ZeroReplayRequestPacket EXCEPT !.replayRequestMessage = one] : one \in SampleLists(OneReplayRequestMessage) }

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

(* Every Replay Request decodes back to what was encoded, and leaves nothing over *)
RoundTripReplayRequest ==
    \A message \in CheckedReplayRequest :
        LET read == DecodeReplayRequest(EncodeReplayRequest(message))
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

(* Every Replay Request Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripReplayRequestPacket ==
    \A message \in CheckedReplayRequestPacket :
        LET read == DecodeReplayRequestPacket(EncodeReplayRequestPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Replay Request Payload is selected by the Replay Message Type it is written under *)
SelectsReplayRequestPayload ==
    \A message \in CheckedReplayRequestPayload :
        LET sent == EncodeReplayRequestPayload(message)
            read == DecodeReplayRequestPayload(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
