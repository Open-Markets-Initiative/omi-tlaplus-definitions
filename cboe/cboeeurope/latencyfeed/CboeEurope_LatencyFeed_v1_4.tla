-------------------- MODULE CboeEurope_LatencyFeed_v1_4 --------------------
(***************************************************************************)
(* Chicago Board Options Exchange Multicast Latency Feed v1.4              *)
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
(* Note: a Message Count of 0 marks Heartbeat and carries no Message.      *)
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
(* Latency Stat Message: 110 bytes                                         *)
(***************************************************************************)

LatencyStatMessage ==
    [ measurementType    : Sample(1),
      matchingUnit       : Sample(1),
      beginTime          : Sample(4),
      endTime            : Sample(4),
      count              : Sample(4),
      minimum            : Sample(8),
      maximum            : Sample(8),
      average            : Sample(8),
      standardDeviation  : Sample(8),
      mode               : Sample(8),
      percentile99Point9 : Sample(8),
      percentile99       : Sample(8),
      percentile95       : Sample(8),
      percentile90       : Sample(8),
      percentile75       : Sample(8),
      percentile50       : Sample(8),
      percentile25       : Sample(8) ]

EncodeLatencyStatMessage(message) ==
    message.measurementType
        \o message.matchingUnit
        \o message.beginTime
        \o message.endTime
        \o message.count
        \o message.minimum
        \o message.maximum
        \o message.average
        \o message.standardDeviation
        \o message.mode
        \o message.percentile99Point9
        \o message.percentile99
        \o message.percentile95
        \o message.percentile90
        \o message.percentile75
        \o message.percentile50
        \o message.percentile25

DecodeLatencyStatMessage(bytes) ==
    LET measurementType == ReadBytes(bytes, 1) IN IF ~measurementType.ok THEN Fail ELSE
    LET matchingUnit == ReadBytes(measurementType.rest, 1) IN IF ~matchingUnit.ok THEN Fail ELSE
    LET beginTime == ReadBytes(matchingUnit.rest, 4) IN IF ~beginTime.ok THEN Fail ELSE
    LET endTime == ReadBytes(beginTime.rest, 4) IN IF ~endTime.ok THEN Fail ELSE
    LET count == ReadBytes(endTime.rest, 4) IN IF ~count.ok THEN Fail ELSE
    LET minimum == ReadBytes(count.rest, 8) IN IF ~minimum.ok THEN Fail ELSE
    LET maximum == ReadBytes(minimum.rest, 8) IN IF ~maximum.ok THEN Fail ELSE
    LET average == ReadBytes(maximum.rest, 8) IN IF ~average.ok THEN Fail ELSE
    LET standardDeviation == ReadBytes(average.rest, 8) IN IF ~standardDeviation.ok THEN Fail ELSE
    LET mode == ReadBytes(standardDeviation.rest, 8) IN IF ~mode.ok THEN Fail ELSE
    LET percentile99Point9 == ReadBytes(mode.rest, 8) IN IF ~percentile99Point9.ok THEN Fail ELSE
    LET percentile99 == ReadBytes(percentile99Point9.rest, 8) IN IF ~percentile99.ok THEN Fail ELSE
    LET percentile95 == ReadBytes(percentile99.rest, 8) IN IF ~percentile95.ok THEN Fail ELSE
    LET percentile90 == ReadBytes(percentile95.rest, 8) IN IF ~percentile90.ok THEN Fail ELSE
    LET percentile75 == ReadBytes(percentile90.rest, 8) IN IF ~percentile75.ok THEN Fail ELSE
    LET percentile50 == ReadBytes(percentile75.rest, 8) IN IF ~percentile50.ok THEN Fail ELSE
    LET percentile25 == ReadBytes(percentile50.rest, 8) IN IF ~percentile25.ok THEN Fail ELSE
    Ok([ measurementType    |-> measurementType.value,
         matchingUnit       |-> matchingUnit.value,
         beginTime          |-> beginTime.value,
         endTime            |-> endTime.value,
         count              |-> count.value,
         minimum            |-> minimum.value,
         maximum            |-> maximum.value,
         average            |-> average.value,
         standardDeviation  |-> standardDeviation.value,
         mode               |-> mode.value,
         percentile99Point9 |-> percentile99Point9.value,
         percentile99       |-> percentile99.value,
         percentile95       |-> percentile95.value,
         percentile90       |-> percentile90.value,
         percentile75       |-> percentile75.value,
         percentile50       |-> percentile50.value,
         percentile25       |-> percentile25.value ], percentile25.rest)

ZeroLatencyStatMessage ==
    [ measurementType    |-> [i \in 1 .. 1 |-> 0],
      matchingUnit       |-> [i \in 1 .. 1 |-> 0],
      beginTime          |-> [i \in 1 .. 4 |-> 0],
      endTime            |-> [i \in 1 .. 4 |-> 0],
      count              |-> [i \in 1 .. 4 |-> 0],
      minimum            |-> [i \in 1 .. 8 |-> 0],
      maximum            |-> [i \in 1 .. 8 |-> 0],
      average            |-> [i \in 1 .. 8 |-> 0],
      standardDeviation  |-> [i \in 1 .. 8 |-> 0],
      mode               |-> [i \in 1 .. 8 |-> 0],
      percentile99Point9 |-> [i \in 1 .. 8 |-> 0],
      percentile99       |-> [i \in 1 .. 8 |-> 0],
      percentile95       |-> [i \in 1 .. 8 |-> 0],
      percentile90       |-> [i \in 1 .. 8 |-> 0],
      percentile75       |-> [i \in 1 .. 8 |-> 0],
      percentile50       |-> [i \in 1 .. 8 |-> 0],
      percentile25       |-> [i \in 1 .. 8 |-> 0] ]

(* Latency Stat Message at zero, then each field in turn at the values it is checked at *)
CheckedLatencyStatMessage ==
    { ZeroLatencyStatMessage }
        \cup { [ZeroLatencyStatMessage EXCEPT !.measurementType = one] : one \in Sample(1) }
        \cup { [ZeroLatencyStatMessage EXCEPT !.matchingUnit = one] : one \in Sample(1) }
        \cup { [ZeroLatencyStatMessage EXCEPT !.beginTime = one] : one \in Sample(4) }
        \cup { [ZeroLatencyStatMessage EXCEPT !.endTime = one] : one \in Sample(4) }
        \cup { [ZeroLatencyStatMessage EXCEPT !.count = one] : one \in Sample(4) }
        \cup { [ZeroLatencyStatMessage EXCEPT !.minimum = one] : one \in Sample(8) }
        \cup { [ZeroLatencyStatMessage EXCEPT !.maximum = one] : one \in Sample(8) }
        \cup { [ZeroLatencyStatMessage EXCEPT !.average = one] : one \in Sample(8) }
        \cup { [ZeroLatencyStatMessage EXCEPT !.standardDeviation = one] : one \in Sample(8) }
        \cup { [ZeroLatencyStatMessage EXCEPT !.mode = one] : one \in Sample(8) }
        \cup { [ZeroLatencyStatMessage EXCEPT !.percentile99Point9 = one] : one \in Sample(8) }
        \cup { [ZeroLatencyStatMessage EXCEPT !.percentile99 = one] : one \in Sample(8) }
        \cup { [ZeroLatencyStatMessage EXCEPT !.percentile95 = one] : one \in Sample(8) }
        \cup { [ZeroLatencyStatMessage EXCEPT !.percentile90 = one] : one \in Sample(8) }
        \cup { [ZeroLatencyStatMessage EXCEPT !.percentile75 = one] : one \in Sample(8) }
        \cup { [ZeroLatencyStatMessage EXCEPT !.percentile50 = one] : one \in Sample(8) }
        \cup { [ZeroLatencyStatMessage EXCEPT !.percentile25 = one] : one \in Sample(8) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

LatencyStatMessageCode == 144  \* 0x90

Payload ==
    [ tag : {LatencyStatMessageCode}, body : LatencyStatMessage ]

EncodePayload(message) ==
    CASE message.tag = LatencyStatMessageCode -> EncodeLatencyStatMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = LatencyStatMessageCode -> DecodeLatencyStatMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> LatencyStatMessageCode, body |-> ZeroLatencyStatMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> LatencyStatMessageCode, body |-> one] : one \in CheckedLatencyStatMessage }

(***************************************************************************)
(* Message, framed by Message Length                                       *)
(***************************************************************************)

Message ==
    [ payload : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntLE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntLE(Len(body) + 1, 1) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntLE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 1) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 1 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroMessage ==
    [ payload |-> ZeroPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.payload = one] : one \in CheckedPayload }

(* A run of Message, written one after another *)
RECURSIVE EncodeMessageList(_)
EncodeMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMessage(Head(messages)) \o EncodeMessageList(Tail(messages))

(* As many Message as the field that counts them says *)
RECURSIVE ReadMessageList(_, _)
ReadMessageList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMessageList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Message of each kind, for the lists that carry them *)
OneMessage ==
    { [ZeroMessage EXCEPT !.payload = [tag |-> LatencyStatMessageCode, body |-> ZeroLatencyStatMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ length   : Sample(2),
      unit     : Sample(1),
      sequence : Sample(4),
      message  : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.length
        \o EncodeUIntLE(Len(message.message), 1)
        \o message.unit
        \o message.sequence
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET length == ReadBytes(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET messageCount == ReadUIntLE(length.rest, 1) IN IF ~messageCount.ok THEN Fail ELSE
    LET unit == ReadBytes(messageCount.rest, 1) IN IF ~unit.ok THEN Fail ELSE
    LET sequence == ReadBytes(unit.rest, 4) IN IF ~sequence.ok THEN Fail ELSE
    LET message == ReadMessageList(sequence.rest, messageCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ length   |-> length.value,
         unit     |-> unit.value,
         sequence |-> sequence.value,
         message  |-> message.value ], message.rest)

ZeroPacket ==
    [ length   |-> [i \in 1 .. 2 |-> 0],
      unit     |-> [i \in 1 .. 1 |-> 0],
      sequence |-> [i \in 1 .. 4 |-> 0],
      message  |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.length = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.unit = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.sequence = one] : one \in Sample(4) }
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

(* Every Latency Stat Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLatencyStatMessage ==
    \A message \in CheckedLatencyStatMessage :
        LET read == DecodeLatencyStatMessage(EncodeLatencyStatMessage(message))
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

(* A Payload is selected by the Message Type it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Message Length is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 1)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
