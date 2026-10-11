------------------ MODULE CixAts_CixAspen_Rerequest_v1_1 -------------------
(***************************************************************************)
(* CIX Trading Inc. CIX Udp Rerequest v1.1                                 *)
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
(* Rerequest Header: 20 bytes                                              *)
(***************************************************************************)

RerequestHeader ==
    [ marketDayIdentifier : Sample(9),
      feedIdentifier      : Sample(1),
      sequence            : Sample(8),
      count               : Sample(2) ]

EncodeRerequestHeader(message) ==
    message.marketDayIdentifier
        \o message.feedIdentifier
        \o message.sequence
        \o message.count

DecodeRerequestHeader(bytes) ==
    LET marketDayIdentifier == ReadBytes(bytes, 9) IN IF ~marketDayIdentifier.ok THEN Fail ELSE
    LET feedIdentifier == ReadBytes(marketDayIdentifier.rest, 1) IN IF ~feedIdentifier.ok THEN Fail ELSE
    LET sequence == ReadBytes(feedIdentifier.rest, 8) IN IF ~sequence.ok THEN Fail ELSE
    LET count == ReadBytes(sequence.rest, 2) IN IF ~count.ok THEN Fail ELSE
    Ok([ marketDayIdentifier |-> marketDayIdentifier.value,
         feedIdentifier      |-> feedIdentifier.value,
         sequence            |-> sequence.value,
         count               |-> count.value ], count.rest)

ZeroRerequestHeader ==
    [ marketDayIdentifier |-> [i \in 1 .. 9 |-> 0],
      feedIdentifier      |-> [i \in 1 .. 1 |-> 0],
      sequence            |-> [i \in 1 .. 8 |-> 0],
      count               |-> [i \in 1 .. 2 |-> 0] ]

(* Rerequest Header at zero, then each field in turn at the values it is checked at *)
CheckedRerequestHeader ==
    { ZeroRerequestHeader }
        \cup { [ZeroRerequestHeader EXCEPT !.marketDayIdentifier = one] : one \in Sample(9) }
        \cup { [ZeroRerequestHeader EXCEPT !.feedIdentifier = one] : one \in Sample(1) }
        \cup { [ZeroRerequestHeader EXCEPT !.sequence = one] : one \in Sample(8) }
        \cup { [ZeroRerequestHeader EXCEPT !.count = one] : one \in Sample(2) }

(***************************************************************************)
(* Packet: 20 bytes                                                        *)
(***************************************************************************)

Packet ==
    [ rerequestHeader : RerequestHeader ]

EncodePacket(message) ==
    EncodeRerequestHeader(message.rerequestHeader)

DecodePacket(bytes) ==
    LET rerequestHeader == DecodeRerequestHeader(bytes) IN IF ~rerequestHeader.ok THEN Fail ELSE
    Ok([ rerequestHeader |-> rerequestHeader.value ], rerequestHeader.rest)

ZeroPacket ==
    [ rerequestHeader |-> ZeroRerequestHeader ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.rerequestHeader = one] : one \in CheckedRerequestHeader }

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

(* Every Rerequest Header decodes back to what was encoded, and leaves nothing over *)
RoundTripRerequestHeader ==
    \A message \in CheckedRerequestHeader :
        LET read == DecodeRerequestHeader(EncodeRerequestHeader(message))
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

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
