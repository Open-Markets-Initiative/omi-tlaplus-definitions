---------- MODULE Databento_MarketData_Normalized_v2_ClientStream ----------
(***************************************************************************)
(* Databento Normalized v2                                                 *)
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
(* Note: Control Fields is the bytes ahead of the first 10, which ends it  *)
(* and is written after it; a field that holds that byte could not be told *)
(* from one it ends, so it is checked at bytes that do not.                *)
(*                                                                         *)
(* Note: Control Message is of no one width: each is read by its own       *)
(* fields, and since every reading of it takes at least 1 byte off the     *)
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
(* Control Message                                                         *)
(***************************************************************************)

ControlMessage ==
    [ controlFields : { text \in SampleBytes : \A at \in DOMAIN text : text[at] # 10 } ]

EncodeControlMessage(message) ==
    message.controlFields \o <<10>>

DecodeControlMessage(bytes) ==
    LET controlFields == ReadClosed(bytes, 10) IN IF ~controlFields.ok THEN Fail ELSE
    Ok([ controlFields |-> controlFields.value ], controlFields.rest)

ZeroControlMessage ==
    [ controlFields |-> << >> ]

(* Control Message at zero, then each field in turn at the values it is checked at *)
CheckedControlMessage ==
    { ZeroControlMessage }
        \cup { [ZeroControlMessage EXCEPT !.controlFields = one] : one \in { text \in SampleBytes : \A at \in DOMAIN text : text[at] # 10 } }

(* A run of Control Message, written one after another *)
RECURSIVE EncodeControlMessageList(_)
EncodeControlMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeControlMessage(Head(messages)) \o EncodeControlMessageList(Tail(messages))

(* As many Control Message as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadControlMessageAll(_)
ReadControlMessageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeControlMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadControlMessageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Control Message of each kind, for the lists that carry them *)
OneControlMessage == { ZeroControlMessage }

(***************************************************************************)
(* Client Stream                                                           *)
(***************************************************************************)

ClientStream ==
    [ controlMessage : SampleLists(OneControlMessage) ]

EncodeClientStream(message) ==
    EncodeControlMessageList(message.controlMessage)

DecodeClientStream(bytes) ==
    LET controlMessage == ReadControlMessageAll(bytes) IN IF ~controlMessage.ok THEN Fail ELSE
    Ok([ controlMessage |-> controlMessage.value ], controlMessage.rest)

ZeroClientStream ==
    [ controlMessage |-> << >> ]

(* Client Stream at zero, then each field in turn at the values it is checked at *)
CheckedClientStream ==
    { ZeroClientStream }
        \cup { [ZeroClientStream EXCEPT !.controlMessage = one] : one \in SampleLists(OneControlMessage) }

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

(* Every Control Message decodes back to what was encoded, and leaves nothing over *)
RoundTripControlMessage ==
    \A message \in CheckedControlMessage :
        LET read == DecodeControlMessage(EncodeControlMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client Stream decodes back to what was encoded, and leaves nothing over *)
RoundTripClientStream ==
    \A message \in CheckedClientStream :
        LET read == DecodeClientStream(EncodeClientStream(message))
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
